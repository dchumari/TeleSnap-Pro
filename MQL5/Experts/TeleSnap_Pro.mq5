//+------------------------------------------------------------------+
//|                                                 TeleSnap_Pro.mq5 |
//|                                Copyright 2026, Derrick Chumari.  |
//|                         https://github.com/dchumari/TeleSnap-Pro |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Derrick Chumari."
#property link        "https://github.com/dchumari/TeleSnap-Pro"
#property version     "1.00"
#property description "⚡ TeleSnap Pro: Ultra-Fast Chart Snapper & Telegram Signal Dispatcher"
#property description "Snap high-resolution watermarked charts and send formatted signals to Telegram in under 300ms."
#property strict

//--- Include core modules
#include <TeleSnap/Config.mqh>
#include <TeleSnap/Telegram.mqh>
#include <TeleSnap/ChartCapture.mqh>
#include <TeleSnap/Watermark.mqh>
#include <TeleSnap/UI.mqh>
#include <TeleSnap/TradeMonitor.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== 🤖 Telegram Bot Configuration ==="
input string                 InpBotToken       = "";                   // Bot API Token (from @BotFather)
input string                 InpChatId         = "";                   // Channel/Group Chat ID (e.g. -100xxxxxxxxxx or @Channel)
input int                    InpTimeoutMs      = 8000;                 // Network Timeout (milliseconds)

input group "=== 🏷️ Branding & Watermark ==="
input string                 InpChannelTag     = "@MyVIPSignals";      // Telegram Channel Handle Watermark
input string                 InpInviteLink     = "https://t.me/";      // VIP Invite Link (Shown in Caption)
input ENUM_WATERMARK_POSITION InpWatermarkPos  = POS_BOTTOM_RIGHT;     // On-Chart Watermark Position
input color                  InpWatermarkColor = clrDimGray;           // Watermark Text Color

input group "=== 📸 Capture & Image Settings ==="
input ENUM_IMAGE_RESOLUTION  InpResolution     = RES_HD_1280x720;      // Image Resolution Preset
input ENUM_CAPTION_STYLE     InpCaptionStyle   = STYLE_DETAILED;       // Signal Caption Layout Style
input ENUM_CAPTURE_TRIGGER   InpTriggerMode    = TRIGGER_AUTO_ALL_EVENTS; // Capture Trigger Mode
input int                    InpHotkeyKey      = 123;                  // Keyboard Hotkey (123 = F12)

input group "=== 🖥️ Floating HUD Settings ==="
input int                    InpHudX           = 30;                   // HUD Button X Offset (Pixels)
input int                    InpHudY           = 50;                   // HUD Button Y Offset (Pixels)

//--- Global Module Instances
CTelegramClient   g_telegram;
CChartCapture     g_capture;
CWatermarkEngine  g_watermark;
CTeleSnapUI       g_ui;
CTradeMonitor     g_monitor;

//--- State tracking
datetime          g_lastResetTime = 0;
bool              g_needsReset = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=================================================");
   Print("⚡ Initializing TeleSnap Pro v1.00");
   Print("=================================================");

   // 1. Initialize Telegram Client
   g_telegram.Init(InpBotToken, InpChatId, InpTimeoutMs);

   // 2. Initialize Branding Engine
   g_watermark.SetBranding(InpChannelTag, InpInviteLink);

   // 3. Initialize Floating HUD Button
   if(!g_ui.Create(0, InpHudX, InpHudY, InpHotkeyKey))
   {
      Print("[TeleSnap Pro] Warning: Could not create on-chart HUD button.");
   }

   // 4. Initialize Trade Monitor
   g_monitor.Init(_Symbol, (ENUM_TIMEFRAMES)_Period);

   // 5. Verification notice
   if(StringLen(InpBotToken) == 0 || StringLen(InpChatId) == 0)
   {
      Print("⚠️ [TeleSnap Pro] NOTICE: Bot Token or Chat ID is empty! Please configure them in EA inputs.");
   }

   // Enable 1-second timer for HUD UI reset animation
   EventSetTimer(1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   g_ui.Destroy();
   g_watermark.RemoveOnChartWatermark(0);
   Print("[TeleSnap Pro] Deinitialized cleanly.");
}

//+------------------------------------------------------------------+
//| Chart Event handler (Clicks & Hotkeys)                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(g_ui.IsTriggered(id, lparam, dparam, sparam))
   {
      ExecuteSnapAndSend("MANUAL_CLICK");
   }
}

//+------------------------------------------------------------------+
//| Trade Transaction Event handler (Auto-Snapping)                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(InpTriggerMode == TRIGGER_BUTTON_ONLY)
      return;

   TradeSignalInfo signal;
   string eventReason = "";

   if(g_monitor.ProcessTransaction(trans, request, result, signal, eventReason))
   {
      // Check filters
      if(InpTriggerMode == TRIGGER_AUTO_ON_ENTRY && eventReason != "TRADE_OPEN")
         return;

      ExecuteSnapAndSend(eventReason, signal);
   }
}

//+------------------------------------------------------------------+
//| Timer function for resetting HUD state                           |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(g_needsReset && TimeCurrent() - g_lastResetTime >= 3)
   {
      g_ui.ResetState();
      g_needsReset = false;
   }
}

//+------------------------------------------------------------------+
//| Core Action: Snap Chart, Overlay Watermark & Dispatch            |
//+------------------------------------------------------------------+
void ExecuteSnapAndSend(const string triggerSource, const TradeSignalInfo &preloadedSignal = NULL)
{
   uint startTime = GetTickCount();
   g_ui.SetStateProcessing();

   TradeSignalInfo signal;

   // 1. Gather trade details
   if(StringLen(preloadedSignal.symbol) > 0)
   {
      signal = preloadedSignal;
   }
   else
   {
      // Build from active chart state / positions
      signal.symbol = _Symbol;
      signal.timeframe = (ENUM_TIMEFRAMES)_Period;
      signal.signalTime = TimeCurrent();
      signal.customComment = "Manual Signal Snapshot";

      // If an open position exists on this symbol, extract its levels
      if(PositionSelect(_Symbol))
      {
         ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         signal.orderType = (pType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         signal.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         signal.stopLoss = PositionGetDouble(POSITION_SL);
         signal.takeProfit = PositionGetDouble(POSITION_TP);
         signal.ticket = PositionGetInteger(POSITION_TICKET);
      }
      else
      {
         // Default to current Bid price
         signal.orderType = "MARKET SETUP";
         signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         signal.stopLoss = 0;
         signal.takeProfit = 0;
         signal.ticket = 0;
      }
   }

   // 2. Draw temporary on-chart watermark
   g_watermark.DrawOnChartWatermark(0, InpWatermarkPos, InpWatermarkColor);

   // 3. Capture high-resolution screenshot into memory buffer
   uchar photoBytes[];
   bool captured = g_capture.CaptureChartToBuffer(0, InpResolution, photoBytes);

   // Clean up temporary watermark immediately
   g_watermark.RemoveOnChartWatermark(0);

   if(!captured)
   {
      Print("[TeleSnap Pro] Capture failed. Aborting send.");
      g_ui.SetStateFailed();
      g_lastResetTime = TimeCurrent();
      g_needsReset = true;
      return;
   }

   // 4. Construct rich formatted caption
   string caption = g_watermark.BuildSignalCaption(signal, InpCaptionStyle);

   // 5. Dispatch via native HTTPS WebRequest
   bool success = g_telegram.SendPhoto(photoBytes, caption);
   uint elapsedMs = GetTickCount() - startTime;

   if(success)
   {
      PrintFormat("[TeleSnap Pro] ✅ Dispatched in %u ms! [Trigger: %s]", elapsedMs, triggerSource);
      g_ui.SetStateSuccess(elapsedMs);
   }
   else
   {
      PrintFormat("[TeleSnap Pro] ❌ Failed to dispatch [Trigger: %s]. Check Experts tab logs.", triggerSource);
      g_ui.SetStateFailed();
   }

   g_lastResetTime = TimeCurrent();
   g_needsReset = true;
}
//+------------------------------------------------------------------+
