//+------------------------------------------------------------------+
//|                                                 TeleSnap_Pro.mq5 |
//|                                Copyright 2026, Derrick Chumari.  |
//|                         https://github.com/dchumari/TeleSnap-Pro |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Derrick Chumari."
#property link        "https://github.com/dchumari/TeleSnap-Pro"
#property version     "2.00"
#property description "⚡ TeleSnap Pro: Multi-Chart Command Center & Signal Dispatcher"
#property description "Centralized hub: Injects remote [SNAP] buttons onto linked charts & auto-dispatches signals in under 300ms."
#property strict

//--- Include core modules
#include <TeleSnap/Config.mqh>
#include <TeleSnap/Storage.mqh>
#include <TeleSnap/Telegram.mqh>
#include <TeleSnap/ChartCapture.mqh>
#include <TeleSnap/Watermark.mqh>
#include <TeleSnap/UI.mqh>
#include <TeleSnap/TradeMonitor.mqh>
#include <TeleSnap/HubManager.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== ⚡ Multi-Chart Command Center Hub ==="
input bool                   InpEnableCommandCenter = true;             // Enable Command Center Dashboard Mode
input bool                   InpAutoLinkOpenCharts  = true;             // Auto-Link Open Trading Charts in Terminal

input group "=== 🤖 Telegram Bot Configuration ==="
input string                 InpBotToken       = "";                      // Bot API Token (Leave blank to auto-load saved ID)
input string                 InpChatId         = "";                      // Channel/Group Chat ID (Leave blank to auto-load saved ID)
input bool                   InpResetSavedIds  = false;                   // Set to TRUE to wipe saved IDs from this computer
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
input ulong                  InpMagicFilter    = 0;                       // Filter by EA Magic Number (0 = All Trades & EAs)
input int                    InpHotkeyKey      = 123;                     // Keyboard Hotkey (123 = F12)

input group "=== 🖥️ Floating HUD Settings (Single Chart Mode) ==="
input int                    InpHudX           = 30;                      // HUD Button X Offset (Pixels)
input int                    InpHudY           = 50;                      // HUD Button Y Offset (Pixels)

//--- Global Module Instances
CTeleSnapStorage  g_storage;
CTelegramClient   g_telegram;
CChartCapture     g_capture;
CWatermarkEngine  g_watermark;
CTeleSnapUI       g_ui;
CTradeMonitor     g_monitor;
CHubManager       g_hub;

//--- Active state & credentials
string            g_activeBotToken     = "";
string            g_activeChatId       = "";
string            g_activeChannel      = "";
string            g_activeInvite       = "";
long              g_lastTriggeredChart = 0;
datetime          g_lastResetTime      = 0;
bool              g_needsReset         = false;

//--- Forward declarations
void ExecuteSnapAndSend(const long targetChartId, const string triggerSource, const string userNote, const TradeSignalInfo &preloadedSignal);
void ExecuteSnapAndSend(const long targetChartId, const string triggerSource, const string userNote = "");
void ExecuteSnapAndSend(const string triggerSource, const string userNote = "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=================================================");
   Print("⚡ Initializing TeleSnap Pro v2.00 (Command Center Hub)");
   Print("=================================================");

   // 1. Pro edition: Custom watermarking enabled
   g_watermark.SetLiteMode(false);

   // 2. Wipe credentials if user requested
   if(InpResetSavedIds)
   {
      g_storage.WipeCredentials();
      Print("[TeleSnap Pro] 🔒 Wiped all saved IDs from this computer.");
   }

   // 3. Resolve Credentials (Input vs Auto-Loaded Local Storage)
   g_activeBotToken = InpBotToken;
   g_activeChatId   = InpChatId;
   g_activeChannel  = InpChannelTag;
   g_activeInvite   = InpInviteLink;

   StringTrimLeft(g_activeBotToken);
   StringTrimRight(g_activeBotToken);
   StringTrimLeft(g_activeChatId);
   StringTrimRight(g_activeChatId);

   // If user provided IDs in inputs dialog, save locally for all other charts
   if(StringLen(g_activeBotToken) > 0 && StringLen(g_activeChatId) > 0)
   {
      g_storage.SaveCredentials(g_activeBotToken, g_activeChatId, g_activeChannel, g_activeInvite);
      Print("[TeleSnap Pro] 💾 Saved Bot Token and Chat ID locally. All other charts will auto-load them!");
   }
   else
   {
      string savedToken = "", savedChat = "", savedTag = "", savedLink = "";
      if(g_storage.LoadCredentials(savedToken, savedChat, savedTag, savedLink))
      {
         g_activeBotToken = savedToken;
         g_activeChatId   = savedChat;
         if(StringLen(savedTag) > 0 && (StringLen(InpChannelTag) == 0 || InpChannelTag == "@MyVIPSignals"))
            g_activeChannel = savedTag;
         if(StringLen(savedLink) > 0 && (StringLen(InpInviteLink) == 0 || InpInviteLink == "https://t.me/"))
            g_activeInvite = savedLink;

         PrintFormat("[TeleSnap Pro] ✅ Auto-loaded credentials from local storage! Target: %s", g_activeChatId);
      }
   }

   // 4. Initialize Telegram Client & Branding
   g_telegram.Init(g_activeBotToken, g_activeChatId, InpTimeoutMs);
   g_watermark.SetBranding(g_activeChannel, g_activeInvite);

   // 5. Preflight Connection Diagnostic Test
   string botUsername = "", chatTitle = "", errorDetails = "";
   bool connected = g_telegram.TestConnection(botUsername, chatTitle, errorDetails);

   // 6. Initialize Command Center Hub or Single Chart Mode
   if(InpEnableCommandCenter)
   {
      string connTarget = (StringLen(chatTitle) > 0) ? chatTitle : g_telegram.GetChatId();
      g_hub.Init(ChartID(), botUsername, connTarget, connected);
      Print("[TeleSnap Pro] ⚡ Command Center & Multi-Chart Hub Activated!");
   }
   else
   {
      if(!g_ui.Create(0, InpHudX, InpHudY, InpHotkeyKey))
      {
         Print("[TeleSnap Pro] Warning: Could not create on-chart HUD controls.");
      }

      if(connected)
      {
         string connTarget = (StringLen(chatTitle) > 0) ? chatTitle : g_telegram.GetChatId();
         g_ui.ResetState(connTarget);
      }
      else
      {
         g_ui.SetStateFailed("Not Connected");
      }
   }

   // 7. Initialize Trade Monitor (Multi-symbol in Command Center mode)
   g_monitor.Init(_Symbol, (ENUM_TIMEFRAMES)_Period, InpMagicFilter, InpEnableCommandCenter);

   if(connected)
   {
      PrintFormat("[TeleSnap Pro] ✅ TELEGRAM CONNECTED! Bot: @%s | Target Chat: %s", botUsername, chatTitle);
      Comment("");
   }
   else
   {
      PrintFormat("[TeleSnap Pro] ⚠️ TELEGRAM SETUP REQUIRED:\n%s", errorDetails);
      Comment("⚠️ TeleSnap Setup: " + errorDetails);
   }

   if(InpSetDefaultTpl)
   {
      ChartSaveTemplate(0, "default.tpl");
      Print("[TeleSnap Pro] 💾 Saved current chart as MT5 'default.tpl'.");
   }

   // High-frequency 80ms timer for instant button clicks on remote linked charts
   EventSetMillisecondTimer(80);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   if(InpEnableCommandCenter)
      g_hub.Destroy();
   g_ui.Destroy();
   g_watermark.RemoveOnChartWatermark(0);
   Comment("");
   Print("[TeleSnap Pro] Deinitialized cleanly.");
}

//+------------------------------------------------------------------+
//| Chart Event handler (Dashboard Clicks, Hotkeys & Remote Toggles) |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(InpEnableCommandCenter)
   {
      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         if(g_hub.HandleDashboardClick(sparam))
            return;
      }
      else if(id == CHARTEVENT_CHART_CHANGE)
      {
         g_hub.OnChartResize();
      }
   }

   // Local trigger check (if single-chart HUD or hotkey pressed on host chart)
   int trigger = g_ui.CheckTrigger(id, lparam, dparam, sparam);

   if(trigger == 1) // Quick Snap [F12]
   {
      string userNote = g_ui.GetUserNote();
      ExecuteSnapAndSend(ChartID(), "MANUAL_SNAP", userNote);
   }
   else if(trigger == 2) // Send With Note
   {
      string userNote = g_ui.GetUserNote();
      if(StringLen(userNote) == 0)
      {
         g_ui.HighlightNoteRequired();
         Print("[TeleSnap Pro] ⚠️ 'SEND + NOTE' clicked without a note. Highlighted note box.");
         return;
      }

      ExecuteSnapAndSend(ChartID(), "MANUAL_NOTE_SNAP", userNote);
      g_ui.ResetNoteBox(true);
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
      if(InpTriggerMode == TRIGGER_AUTO_ON_ENTRY && (eventReason != "TRADE_OPEN" && eventReason != "ORDER_PLACED"))
         return;

      // Smart Cross-Chart Targeting: Find the linked chart for this symbol (e.g. Algo Chart with boxes!)
      long targetChartId = 0;
      if(InpEnableCommandCenter)
      {
         targetChartId = g_hub.FindLinkedChartForSymbol(signal.symbol);
      }

      // Ensure signal timeframe matches the actual targeted chart
      if(targetChartId > 0)
         signal.timeframe = ChartPeriod(targetChartId);

      ExecuteSnapAndSend(targetChartId, eventReason, "", signal);
   }
}

//+------------------------------------------------------------------+
//| Timer function: Polls remote buttons & scans open charts         |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(InpEnableCommandCenter)
   {
      // 1. High-speed check for remote button clicks across all linked charts
      long targetChartId = 0;
      string remoteNote = "";
      int trigger = g_hub.CheckRemoteTriggers(targetChartId, remoteNote);

      if(trigger == 1) // Quick Snap clicked on a remote linked chart
      {
         ExecuteSnapAndSend(targetChartId, "REMOTE_SNAP", remoteNote);
      }
      else if(trigger == 2) // Send with Note clicked on a remote linked chart
      {
         ExecuteSnapAndSend(targetChartId, "REMOTE_NOTE_SNAP", remoteNote);
      }

      // 2. Periodic rescan of terminal charts (every 2.5 seconds)
      static uint s_lastScanTick = 0;
      if(GetTickCount() - s_lastScanTick >= 2500)
      {
         g_hub.RefreshCharts(InpAutoLinkOpenCharts);
         s_lastScanTick = GetTickCount();
      }
   }

   // 3. Reset button states after 3 seconds
   if(g_needsReset && TimeCurrent() - g_lastResetTime >= 3)
   {
      if(InpEnableCommandCenter)
      {
         if(g_lastTriggeredChart > 0)
            g_hub.ResetRemoteState(g_lastTriggeredChart);
      }
      else
      {
         g_ui.ResetState(g_telegram.GetChatId());
      }
      g_needsReset = false;
   }
}

//+------------------------------------------------------------------+
//| Overloads for manual trigger                                     |
//+------------------------------------------------------------------+
void ExecuteSnapAndSend(const string triggerSource, const string userNote)
{
   TradeSignalInfo emptySignal;
   ZeroMemory(emptySignal);
   ExecuteSnapAndSend(ChartID(), triggerSource, userNote, emptySignal);
}

void ExecuteSnapAndSend(const long targetChartId, const string triggerSource, const string userNote)
{
   TradeSignalInfo emptySignal;
   ZeroMemory(emptySignal);
   ExecuteSnapAndSend(targetChartId, triggerSource, userNote, emptySignal);
}

//+------------------------------------------------------------------+
//| Core Action: Snap Target Chart, Overlay Watermark & Dispatch     |
//+------------------------------------------------------------------+
void ExecuteSnapAndSend(const long targetChartId, const string triggerSource, const string userNote, const TradeSignalInfo &preloadedSignal)
{
   uint startTime = GetTickCount();
   bool isAutoEvent = (triggerSource != "MANUAL_SNAP" && triggerSource != "MANUAL_NOTE_SNAP" && 
                       triggerSource != "REMOTE_SNAP" && triggerSource != "REMOTE_NOTE_SNAP");

   bool hasDedicatedChart = (targetChartId > 0 && (!InpEnableCommandCenter || targetChartId != ChartID()));
   long activeTarget = hasDedicatedChart ? targetChartId : ChartID();
   string targetSymbol = ChartSymbol(activeTarget);
   if(StringLen(targetSymbol) == 0) targetSymbol = _Symbol;
   ENUM_TIMEFRAMES targetTf = ChartPeriod(activeTarget);
   if(targetTf == 0) targetTf = (ENUM_TIMEFRAMES)_Period;

   if(InpEnableCommandCenter && hasDedicatedChart)
      g_hub.SetRemoteStateProcessing(activeTarget);
   else if(!InpEnableCommandCenter)
      g_ui.SetStateProcessing();

   TradeSignalInfo signal;

   // 1. Gather rich trade details
   if(StringLen(preloadedSignal.symbol) > 0)
   {
      signal = preloadedSignal;
   }
   else
   {
      if(!g_monitor.GetActivePositionSignal(targetSymbol, targetTf, signal))
      {
         if(!g_monitor.GetPendingOrderSignal(targetSymbol, targetTf, signal))
         {
            signal.symbol = targetSymbol;
            signal.timeframe = targetTf;
            signal.status = "WATCHLIST";
            signal.orderType = "MARKET SETUP";
            signal.entryPrice = SymbolInfoDouble(targetSymbol, SYMBOL_BID);
            signal.currentPrice = signal.entryPrice;
            signal.stopLoss = 0;
            signal.takeProfit = 0;
            signal.volume = 0;
            signal.ticket = 0;
            signal.floatingPnL = 0;
            signal.floatingPips = 0;
            signal.signalTime = TimeCurrent();

            double point = SymbolInfoDouble(targetSymbol, SYMBOL_POINT);
            int digits = (int)SymbolInfoInteger(targetSymbol, SYMBOL_DIGITS);
            double pipSize = (digits == 3 || digits == 5) ? point * 10.0 : point;
            long spreadPts = SymbolInfoInteger(targetSymbol, SYMBOL_SPREAD);
            signal.spreadPips = (pipSize > 0) ? (spreadPts * point) / pipSize : 0;
         }
      }
   }

   if(StringLen(userNote) > 0)
   {
      signal.customComment = userNote;
   }

   // 2. Build rich signal caption
   string caption = g_watermark.BuildSignalCaption(signal, InpCaptionStyle);

   // 3. Fallback: If no dedicated chart exists for this symbol (e.g. order deleted from trade list), dispatch as pure HTML text!
   if(!hasDedicatedChart && isAutoEvent)
   {
      string errorMsg = "";
      bool sent = g_telegram.SendMessage(caption, errorMsg);
      uint elapsedMs = GetTickCount() - startTime;

      if(sent)
      {
         PrintFormat("[TeleSnap Pro] ℹ️ Dispatched text signal for %s (no dedicated chart open) in %u ms to %s", 
                     signal.symbol, elapsedMs, g_telegram.GetChatId());
         if(InpEnableCommandCenter)
            g_hub.AddLog(signal.symbol, signal.orderType + " (Text)", elapsedMs, true);
      }
      else
      {
         PrintFormat("[TeleSnap Pro] ❌ SendMessage failed for %s: %s", signal.symbol, errorMsg);
         if(InpEnableCommandCenter)
            g_hub.AddLog(signal.symbol, "Text Dispatch Failed", elapsedMs, false);
      }
      return;
   }

   // 4. Dedicated chart exists: Draw temporary on-chart watermark on the EXACT target chart
   g_watermark.DrawOnChartWatermark(activeTarget, InpWatermarkPos, InpWatermarkColor);

   // 5. Capture high-resolution screenshot into memory buffer
   uchar photoBytes[];
   bool captured = g_capture.CaptureChartToBuffer(activeTarget, InpResolution, photoBytes);

   // Clean up temporary watermark immediately
   g_watermark.RemoveOnChartWatermark(activeTarget);

   if(!captured)
   {
      PrintFormat("[TeleSnap Pro] Capture failed for Chart ID %I64d. Aborting send.", activeTarget);
      if(InpEnableCommandCenter)
      {
         g_hub.SetRemoteStateFailed(activeTarget, "Capture Failed");
         g_hub.AddLog(signal.symbol, "Capture Failed", 0, false);
      }
      else
      {
         g_ui.SetStateFailed("Capture Failed");
      }

      g_lastResetTime = TimeCurrent();
      g_lastTriggeredChart = activeTarget;
      g_needsReset = true;
      return;
   }

   // 6. Dispatch via native HTTPS WebRequest
   string errorMsg = "";
   bool success = g_telegram.SendPhoto(photoBytes, caption, errorMsg);
   uint elapsedMs = GetTickCount() - startTime;

   if(success)
   {
      PrintFormat("[TeleSnap Pro] ✅ Dispatched in %u ms to %s! [Trigger: %s | Target Chart: %I64d]", elapsedMs, g_telegram.GetChatId(), triggerSource, activeTarget);
      if(InpEnableCommandCenter)
      {
         g_hub.SetRemoteStateSuccess(activeTarget, elapsedMs, g_telegram.GetChatId());
         g_hub.AddLog(signal.symbol, signal.orderType, elapsedMs, true);
      }
      else
      {
         g_ui.SetStateSuccess(elapsedMs, g_telegram.GetChatId());
      }
      Comment("");
   }
   else
   {
      PrintFormat("[TeleSnap Pro] ❌ Dispatch failed: %s", errorMsg);
      if(InpEnableCommandCenter)
      {
         g_hub.SetRemoteStateFailed(activeTarget, "Send Failed");
         g_hub.AddLog(signal.symbol, "Send Failed: " + errorMsg, elapsedMs, false);
      }
      else
      {
         g_ui.SetStateFailed("Send Failed");
      }
      Comment("⚠️ TeleSnap Error: " + errorMsg);
   }

   g_lastResetTime = TimeCurrent();
   g_lastTriggeredChart = activeTarget;
   g_needsReset = true;
}
//+------------------------------------------------------------------+
