//+------------------------------------------------------------------+
//|                                                 TeleSnap_Pro.mq5 |
//|                                Copyright 2026, Derrick Chumari.  |
//|                         https://github.com/dchumari/TeleSnap-Pro |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Derrick Chumari."
#property link        "https://github.com/dchumari/TeleSnap-Pro"
#property version     "1.20"
#property description "⚡ TeleSnap Pro: Ultra-Fast Chart Snapper & Telegram Signal Dispatcher"
#property description "Snap high-resolution watermarked charts and send formatted signals to Telegram in under 300ms."
#property strict

//--- Include core modules
#include <TeleSnap/Config.mqh>
#include <TeleSnap/Storage.mqh>
#include <TeleSnap/Telegram.mqh>
#include <TeleSnap/ChartCapture.mqh>
#include <TeleSnap/Watermark.mqh>
#include <TeleSnap/UI.mqh>
#include <TeleSnap/TradeMonitor.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== 🤖 Telegram Bot Configuration ==="
input string                 InpBotToken       = "";                      // Bot API Token (from @BotFather)
input string                 InpChatId         = "";                      // Channel/Group Chat ID (e.g. @MyChannel or -100xxx)
input bool                   InpSaveCredentials = false;                  // Save IDs to local disk (Keep FALSE for pure memory privacy)
input bool                   InpSetDefaultTpl  = false;                   // Save as MT5 Default Template (Auto-opens on all charts)
input int                    InpTimeoutMs      = 8000;                    // Network Timeout (milliseconds)

input group "=== 🏷️ Branding & Watermark (Pro Edition) ==="
input string                 InpChannelTag     = "@MyVIPSignals";         // Telegram Channel Handle Watermark
input string                 InpInviteLink     = "https://t.me/";         // VIP Invite Link (Shown in Caption)
input ENUM_WATERMARK_POSITION InpWatermarkPos  = POS_BOTTOM_RIGHT;        // On-Chart Watermark Position
input color                  InpWatermarkColor = clrDimGray;              // Watermark Text Color

input group "=== 📸 Capture & Image Settings ==="
input ENUM_IMAGE_RESOLUTION  InpResolution     = RES_HD_1280x720;         // Image Resolution Preset
input ENUM_CAPTION_STYLE     InpCaptionStyle   = STYLE_INSTITUTIONAL;     // Signal Caption Layout Style
input ENUM_CAPTURE_TRIGGER   InpTriggerMode    = TRIGGER_AUTO_ALL_EVENTS; // Capture Trigger Mode
input int                    InpHotkeyKey      = 123;                     // Keyboard Hotkey (123 = F12)

input group "=== 🖥️ Floating HUD Settings ==="
input int                    InpHudX           = 30;                      // HUD Button X Offset (Pixels)
input int                    InpHudY           = 50;                      // HUD Button Y Offset (Pixels)

//--- Global Module Instances
CTeleSnapStorage  g_storage;
CTelegramClient   g_telegram;
CChartCapture     g_capture;
CWatermarkEngine  g_watermark;
CTeleSnapUI       g_ui;
CTradeMonitor     g_monitor;

//--- Active state & credentials (Kept purely in memory by default)
string            g_activeBotToken = "";
string            g_activeChatId   = "";
string            g_activeChannel  = "";
string            g_activeInvite   = "";
datetime          g_lastResetTime  = 0;
bool              g_needsReset     = false;

//--- Forward declarations
void ExecuteSnapAndSend(const string triggerSource, const string userNote, const TradeSignalInfo &preloadedSignal);
void ExecuteSnapAndSend(const string triggerSource, const string userNote = "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=================================================");
   Print("⚡ Initializing TeleSnap Pro v1.20");
   Print("=================================================");

   // 1. Pro edition: Custom watermarking enabled
   g_watermark.SetLiteMode(false);

   // 2. Resolve Credentials (In-memory by default)
   g_activeBotToken = InpBotToken;
   g_activeChatId   = InpChatId;
   g_activeChannel  = InpChannelTag;
   g_activeInvite   = InpInviteLink;

   StringTrimLeft(g_activeBotToken);
   StringTrimRight(g_activeBotToken);
   StringTrimLeft(g_activeChatId);
   StringTrimRight(g_activeChatId);

   // Privacy handling: Only load or save if user explicitly opted in
   if(InpSaveCredentials)
   {
      if(StringLen(g_activeBotToken) == 0 || StringLen(g_activeChatId) == 0)
      {
         string loadedToken = "", loadedChat = "", loadedTag = "", loadedLink = "";
         int loadedTrig = 0, loadedRes = 0, loadedStyle = 0;
         if(g_storage.LoadSettings(loadedToken, loadedChat, loadedTag, loadedLink, loadedTrig, loadedRes, loadedStyle))
         {
            g_activeBotToken = loadedToken;
            g_activeChatId = loadedChat;
            if(StringLen(loadedTag) > 0) g_activeChannel = loadedTag;
            if(StringLen(loadedLink) > 0) g_activeInvite = loadedLink;
            PrintFormat("[TeleSnap Pro] Auto-loaded credentials from disk. Target: %s", g_activeChatId);
         }
      }
      else
      {
         g_storage.SaveSettings(g_activeBotToken, g_activeChatId, g_activeChannel, g_activeInvite,
                                (int)InpTriggerMode, (int)InpResolution, (int)InpCaptionStyle);
      }
   }

   // 3. Initialize Telegram Client & Branding
   g_telegram.Init(g_activeBotToken, g_activeChatId, InpTimeoutMs);
   g_watermark.SetBranding(g_activeChannel, g_activeInvite);

   // 4. Initialize Floating Control Panel & Note Box
   if(!g_ui.Create(0, InpHudX, InpHudY, InpHotkeyKey))
   {
      Print("[TeleSnap Pro] Warning: Could not create on-chart HUD controls.");
   }

   // 5. Initialize Trade Monitor
   g_monitor.Init(_Symbol, (ENUM_TIMEFRAMES)_Period);

   // 6. Preflight Connection Diagnostic
   string botUsername = "", chatTitle = "", errorDetails = "";
   bool connected = g_telegram.TestConnection(botUsername, chatTitle, errorDetails);

   if(connected)
   {
      string connTarget = (StringLen(chatTitle) > 0) ? chatTitle : g_telegram.GetChatId();
      g_ui.ResetState(connTarget);
      PrintFormat("[TeleSnap Pro] ✅ TELEGRAM CONNECTED! Bot: @%s | Target Chat: %s", botUsername, connTarget);
      Comment("");
   }
   else
   {
      g_ui.SetStateFailed("Not Connected");
      PrintFormat("[TeleSnap Pro] ⚠️ TELEGRAM SETUP REQUIRED:\n%s", errorDetails);
      Comment("⚠️ TeleSnap Setup: " + errorDetails);
   }

   if(InpSetDefaultTpl)
   {
      ChartSaveTemplate(0, "default.tpl");
      Print("[TeleSnap Pro] 💾 Saved current chart as MT5 'default.tpl'.");
   }

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
   Comment("");
   Print("[TeleSnap Pro] Deinitialized cleanly.");
}

//+------------------------------------------------------------------+
//| Chart Event handler (Clicks, Hotkeys & On-Chart Note Input)      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   int trigger = g_ui.CheckTrigger(id, lparam, dparam, sparam);

   if(trigger == 1) // Quick Snap [F12]
   {
      string userNote = g_ui.GetUserNote();
      ExecuteSnapAndSend("MANUAL_SNAP", userNote);
   }
   else if(trigger == 2) // Send With Note
   {
      string userNote = g_ui.GetUserNote();
      ExecuteSnapAndSend("MANUAL_NOTE_SNAP", userNote);
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
      if(InpTriggerMode == TRIGGER_AUTO_ON_ENTRY && eventReason != "TRADE_OPEN")
         return;

      ExecuteSnapAndSend(eventReason, "", signal);
   }
}

//+------------------------------------------------------------------+
//| Timer function for resetting HUD state                           |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(g_needsReset && TimeCurrent() - g_lastResetTime >= 3)
   {
      g_ui.ResetState(g_telegram.GetChatId());
      g_needsReset = false;
   }
}

//+------------------------------------------------------------------+
//| Overload for manual trigger without preloaded signal             |
//+------------------------------------------------------------------+
void ExecuteSnapAndSend(const string triggerSource, const string userNote)
{
   TradeSignalInfo emptySignal;
   ZeroMemory(emptySignal);
   ExecuteSnapAndSend(triggerSource, userNote, emptySignal);
}

//+------------------------------------------------------------------+
//| Core Action: Snap Chart, Overlay Watermark & Dispatch            |
//+------------------------------------------------------------------+
void ExecuteSnapAndSend(const string triggerSource, const string userNote, const TradeSignalInfo &preloadedSignal)
{
   uint startTime = GetTickCount();
   g_ui.SetStateProcessing();

   TradeSignalInfo signal;

   // 1. Gather rich trade details
   if(StringLen(preloadedSignal.symbol) > 0)
   {
      signal = preloadedSignal;
   }
   else
   {
      // Check if an active open position exists on this chart
      if(!g_monitor.GetActivePositionSignal(signal))
      {
         // No open position: Build market setup / watchlist card
         signal.symbol = _Symbol;
         signal.timeframe = (ENUM_TIMEFRAMES)_Period;
         signal.status = "WATCHLIST";
         signal.orderType = "MARKET SETUP";
         signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         signal.currentPrice = signal.entryPrice;
         signal.stopLoss = 0;
         signal.takeProfit = 0;
         signal.volume = 0;
         signal.ticket = 0;
         signal.floatingPnL = 0;
         signal.floatingPips = 0;
         signal.signalTime = TimeCurrent();

         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         double pipSize = (digits == 3 || digits == 5) ? point * 10.0 : point;
         long spreadPts = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
         signal.spreadPips = (pipSize > 0) ? (spreadPts * point) / pipSize : 0;
      }
   }

   // Attach custom trader commentary if provided
   if(StringLen(userNote) > 0)
   {
      signal.customComment = userNote;
   }

   // 2. Draw temporary on-chart watermark
   g_watermark.DrawOnChartWatermark(0, InpWatermarkPos, InpWatermarkColor);

   // 3. Capture high-resolution screenshot into memory buffer
   uchar photoBytes[];
   bool captured = g_capture.CaptureChartToBuffer(0, InpResolution, photoBytes);

   // Clean up temporary watermark
   g_watermark.RemoveOnChartWatermark(0);

   if(!captured)
   {
      Print("[TeleSnap Pro] Capture failed. Aborting send.");
      g_ui.SetStateFailed("Capture Failed");
      g_lastResetTime = TimeCurrent();
      g_needsReset = true;
      return;
   }

   // 4. Construct rich informative caption
   string caption = g_watermark.BuildSignalCaption(signal, InpCaptionStyle);

   // 5. Dispatch via native HTTPS WebRequest
   string errorMsg = "";
   bool success = g_telegram.SendPhoto(photoBytes, caption, errorMsg);
   uint elapsedMs = GetTickCount() - startTime;

   if(success)
   {
      PrintFormat("[TeleSnap Pro] ✅ Dispatched in %u ms to %s! [Trigger: %s]", elapsedMs, g_telegram.GetChatId(), triggerSource);
      g_ui.SetStateSuccess(elapsedMs, g_telegram.GetChatId());
      Comment("");
   }
   else
   {
      PrintFormat("[TeleSnap Pro] ❌ Dispatch failed: %s", errorMsg);
      g_ui.SetStateFailed("Send Failed");
      Comment("⚠️ TeleSnap Error: " + errorMsg);
   }

   g_lastResetTime = TimeCurrent();
   g_needsReset = true;
}
//+------------------------------------------------------------------+
