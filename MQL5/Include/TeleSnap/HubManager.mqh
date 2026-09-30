//+------------------------------------------------------------------+
//|                                                   HubManager.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"
#include "Telegram.mqh"
#include "Watermark.mqh"

//+------------------------------------------------------------------+
//| Linked Chart Metadata Structure                                  |
//+------------------------------------------------------------------+
struct LinkedChartInfo
{
   long              chartId;
   string            symbol;
   ENUM_TIMEFRAMES   timeframe;
   string            eaName;
   bool              isLinked;
   datetime          lastSnapTime;
   string            statusText;
};

//+------------------------------------------------------------------+
//| Activity Feed Entry Structure                                    |
//+------------------------------------------------------------------+
struct HubLogEntry
{
   datetime          time;
   string            symbol;
   string            eventText;
   uint              latencyMs;
   bool              success;
};

//+------------------------------------------------------------------+
//| Master Multi-Chart Command Center & Remote HUD Injection Engine  |
//+------------------------------------------------------------------+
class CHubManager
{
private:
   long              m_hubChartId;
   LinkedChartInfo   m_charts[];
   HubLogEntry       m_activityLog[];
   string            m_botUsername;
   string            m_chatTarget;
   bool              m_isConnected;
   datetime          m_lastChartScan;
   int               m_maxLogEntries;
   int               m_lastChartWidth;
   ENUM_BASE_CORNER  m_remoteCorner;
   int               m_remoteX;
   int               m_remoteY;

   //--- Prefix constants for objects
   string            PrefixDash() const   { return "TeleSnap_Dash_"; }
   string            PrefixRemote() const { return "TeleSnap_Remote_"; }

public:
   CHubManager() : m_hubChartId(0),
                   m_botUsername(""),
                   m_chatTarget(""),
                   m_isConnected(false),
                   m_lastChartScan(0),
                   m_maxLogEntries(8),
                   m_lastChartWidth(0),
                   m_remoteCorner(CORNER_LEFT_UPPER),
                   m_remoteX(25),
                   m_remoteY(45)
   {
      ArrayResize(m_charts, 0);
      ArrayResize(m_activityLog, 0);
   }

   ~CHubManager()
   {
      Destroy();
   }

   //--- Initialize Command Center on host chart
   void Init(const long hubChartId, const string botUser, const string chatTarget, const bool connected,
             const ENUM_BASE_CORNER remoteCorner = CORNER_LEFT_UPPER, const int remoteX = 25, const int remoteY = 45)
   {
      m_hubChartId = hubChartId;
      m_botUsername = botUser;
      m_chatTarget = chatTarget;
      m_isConnected = connected;
      m_remoteCorner = remoteCorner;
      m_remoteX = remoteX;
      m_remoteY = remoteY;

      // Style host chart as sleek full-screen Command Center Dashboard
      SetupDashboardChart();

      // Scan and auto-link open charts
      RefreshCharts(true);

      // Render full visual dashboard
      RenderDashboard();
   }

   //--- Style host chart window into clean SaaS dashboard
   void SetupDashboardChart()
   {
      ChartSetInteger(m_hubChartId, CHART_SHOW_PRICE_SCALE, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_DATE_SCALE, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_GRID, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_PERIOD_SEP, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_VOLUMES, CHART_VOLUME_HIDE);
      ChartSetInteger(m_hubChartId, CHART_SHOW_OHLC, false);
      ChartSetInteger(m_hubChartId, CHART_MODE, CHART_LINE);
      ChartSetInteger(m_hubChartId, CHART_COLOR_BACKGROUND, C'16,21,30'); // Premium dark slate
      ChartSetInteger(m_hubChartId, CHART_COLOR_FOREGROUND, C'16,21,30');
      ChartSetInteger(m_hubChartId, CHART_COLOR_CHART_LINE, C'16,21,30'); // Blend chart line into background
      ChartSetInteger(m_hubChartId, CHART_COLOR_CANDLE_BULL, C'16,21,30');
      ChartSetInteger(m_hubChartId, CHART_COLOR_CANDLE_BEAR, C'16,21,30');
      ChartSetInteger(m_hubChartId, CHART_COLOR_CHART_UP, C'16,21,30');
      ChartSetInteger(m_hubChartId, CHART_COLOR_CHART_DOWN, C'16,21,30');
      ChartSetInteger(m_hubChartId, CHART_COLOR_VOLUME, C'16,21,30');
      ChartSetInteger(m_hubChartId, CHART_EVENT_MOUSE_MOVE, true);

      // Completely wipe all trade history arrows, order levels, and market lines
      ChartSetInteger(m_hubChartId, CHART_SHOW_TRADE_LEVELS, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_TRADE_HISTORY, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_BID_LINE, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_ASK_LINE, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_LAST_LINE, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_ONE_CLICK, false);
      ChartSetInteger(m_hubChartId, CHART_SHOW_OBJECT_DESCR, false);

      ChartRedraw(m_hubChartId);
   }

   //--- Handle window resize dynamically
   void OnChartResize()
   {
      int currentW = (int)ChartGetInteger(m_hubChartId, CHART_WIDTH_IN_PIXELS);
      if(MathAbs(currentW - m_lastChartWidth) > 30)
      {
         m_lastChartWidth = currentW;
         RenderDashboard();
      }
   }

   //--- Refresh open charts list across the MT5 terminal
   void RefreshCharts(const bool autoLinkNew = true)
   {
      // 1. Collect all open charts in terminal
      long currentChart = ChartFirst();
      long openIds[];
      ArrayResize(openIds, 0);

      while(currentChart >= 0)
      {
         if(currentChart != m_hubChartId)
         {
            int sz = ArraySize(openIds);
            ArrayResize(openIds, sz + 1);
            openIds[sz] = currentChart;
         }
         currentChart = ChartNext(currentChart);
      }

      // 2. Remove charts that were closed
      for(int i = ArraySize(m_charts) - 1; i >= 0; i--)
      {
         bool stillOpen = false;
         for(int j = 0; j < ArraySize(openIds); j++)
         {
            if(m_charts[i].chartId == openIds[j])
            {
               stillOpen = true;
               break;
            }
         }

         if(!stillOpen)
         {
            // Remove HUD from closed chart
            RemoveRemoteHUD(m_charts[i].chartId);
            // Remove from array
            for(int k = i; k < ArraySize(m_charts) - 1; k++)
               m_charts[k] = m_charts[k + 1];
            ArrayResize(m_charts, ArraySize(m_charts) - 1);
         }
      }

      // 3. Add newly opened charts
      for(int j = 0; j < ArraySize(openIds); j++)
      {
         long id = openIds[j];
         bool exists = false;
         for(int i = 0; i < ArraySize(m_charts); i++)
         {
            if(m_charts[i].chartId == id)
            {
               exists = true;
               // Update live metadata
               m_charts[i].symbol = ChartSymbol(id);
               m_charts[i].timeframe = ChartPeriod(id);
               m_charts[i].eaName = ChartGetString(id, CHART_EXPERT_NAME);
               break;
            }
         }

         if(!exists)
         {
            int newIdx = ArraySize(m_charts);
            ArrayResize(m_charts, newIdx + 1);
            m_charts[newIdx].chartId = id;
            m_charts[newIdx].symbol = ChartSymbol(id);
            m_charts[newIdx].timeframe = ChartPeriod(id);
            m_charts[newIdx].eaName = ChartGetString(id, CHART_EXPERT_NAME);
            m_charts[newIdx].isLinked = autoLinkNew; // Auto-link new trading charts by default!
            m_charts[newIdx].lastSnapTime = 0;
            m_charts[newIdx].statusText = "Ready";

            if(m_charts[newIdx].isLinked)
               InjectRemoteHUD(id);
         }
      }

      m_lastChartScan = TimeCurrent();
   }

   //--- Inject Remote Floating HUD onto a Linked Trading Chart
   void InjectRemoteHUD(const long targetChartId, const int x = -1, const int y = -1, const ENUM_BASE_CORNER corner = (ENUM_BASE_CORNER)-1)
   {
      RemoveRemoteHUD(targetChartId);

      int posX = (x >= 0) ? x : m_remoteX;
      int posY = (y >= 0) ? y : m_remoteY;
      ENUM_BASE_CORNER posCorner = (corner != (ENUM_BASE_CORNER)-1) ? corner : m_remoteCorner;

      int btnHeight = 28;
      int editHeight = 22;
      int btn1Width = 115;
      int btn2Width = 125;
      int totalWidth = btn1Width + btn2Width + 5;

      int b1X = posX;
      int b2X = posX + btn1Width + 5;
      int editX = posX;
      int promptX = posX + 2;
      int statX = posX + 2;

      int bY = posY;
      int promptY = posY + btnHeight + 4;
      int editY = posY + btnHeight + 18;
      int statY = posY + btnHeight + 18 + editHeight + 4;

      if(posCorner == CORNER_LEFT_LOWER || posCorner == CORNER_RIGHT_LOWER)
      {
         statY = posY;
         editY = posY + 18;
         promptY = posY + 18 + editHeight + 2;
         bY = posY + 18 + editHeight + 18;
      }

      // 1. Button: Quick Snap [F12]
      string btnSnap = PrefixRemote() + "Snap";
      ObjectCreate(targetChartId, btnSnap, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_CORNER, posCorner);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_XDISTANCE, b1X);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_YDISTANCE, bY);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_XSIZE, btn1Width);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_YSIZE, btnHeight);
      ObjectSetString(targetChartId, btnSnap, OBJPROP_TEXT, "📸 SNAP [F12]");
      ObjectSetString(targetChartId, btnSnap, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_BORDER_COLOR, clrDodgerBlue);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_STATE, false);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_HIDDEN, true);

      // 2. Button: Send With Note
      string btnNoteSnap = PrefixRemote() + "NoteSnap";
      ObjectCreate(targetChartId, btnNoteSnap, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_CORNER, posCorner);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_XDISTANCE, b2X);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_YDISTANCE, bY);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_XSIZE, btn2Width);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_YSIZE, btnHeight);
      ObjectSetString(targetChartId, btnNoteSnap, OBJPROP_TEXT, "💬 SEND + NOTE");
      ObjectSetString(targetChartId, btnNoteSnap, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_BGCOLOR, C'35,50,75');
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_BORDER_COLOR, clrSteelBlue);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_STATE, false);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_HIDDEN, true);

      // 3. Prompt Label
      string lblPrompt = PrefixRemote() + "Prompt";
      ObjectCreate(targetChartId, lblPrompt, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_CORNER, posCorner);
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_XDISTANCE, promptX);
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_YDISTANCE, promptY);
      ObjectSetString(targetChartId, lblPrompt, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_COLOR, clrSilver);
      ObjectSetString(targetChartId, lblPrompt, OBJPROP_TEXT, "📝 Note (click box below to type):");
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(targetChartId, lblPrompt, OBJPROP_HIDDEN, true);

      // 4. On-Chart Editable Note Box
      string editNote = PrefixRemote() + "Note";
      ObjectCreate(targetChartId, editNote, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_CORNER, posCorner);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_XDISTANCE, editX);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_YDISTANCE, editY);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_XSIZE, totalWidth);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_YSIZE, editHeight);
      ObjectSetString(targetChartId, editNote, OBJPROP_TEXT, "");
      ObjectSetString(targetChartId, editNote, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(targetChartId, editNote, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_ALIGN, ALIGN_LEFT);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_BGCOLOR, C'20,26,38');
      ObjectSetInteger(targetChartId, editNote, OBJPROP_BORDER_COLOR, C'50,70,100');
      ObjectSetInteger(targetChartId, editNote, OBJPROP_READONLY, false);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_SELECTED, false);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_HIDDEN, true);

      // 5. Status Subtitle Label
      string statusLbl = PrefixRemote() + "Status";
      ObjectCreate(targetChartId, statusLbl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_CORNER, posCorner);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_XDISTANCE, statX);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_YDISTANCE, statY);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_COLOR, clrMediumSeaGreen);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_TEXT, "● TeleSnap Hub Linked");
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_HIDDEN, true);

      ChartRedraw(targetChartId);
   }

   //--- Remove Remote Floating HUD from a Chart
   void RemoveRemoteHUD(const long targetChartId)
   {
      ObjectDelete(targetChartId, PrefixRemote() + "Snap");
      ObjectDelete(targetChartId, PrefixRemote() + "NoteSnap");
      ObjectDelete(targetChartId, PrefixRemote() + "Prompt");
      ObjectDelete(targetChartId, PrefixRemote() + "Note");
      ObjectDelete(targetChartId, PrefixRemote() + "Status");
      ChartRedraw(targetChartId);
   }

   //--- Highlight Note Box on Remote Chart when clicked empty
   void HighlightRemoteNoteRequired(const long targetChartId)
   {
      string editNote = PrefixRemote() + "Note";
      string statusLbl = PrefixRemote() + "Status";
      ObjectSetString(targetChartId, editNote, OBJPROP_TEXT, "⚠️ Please type your note here first!");
      ObjectSetInteger(targetChartId, editNote, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_BGCOLOR, C'60,20,25');
      ObjectSetInteger(targetChartId, editNote, OBJPROP_BORDER_COLOR, clrOrangeRed);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_TEXT, "⚠️ Note required! Type in box above, or use [SNAP]");
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_COLOR, clrTomato);
      ChartRedraw(targetChartId);
   }

   //--- Reset Remote Note Box on Remote Chart
   void ResetRemoteNoteBox(const long targetChartId, const bool clearText = true)
   {
      string editNote = PrefixRemote() + "Note";
      if(clearText)
         ObjectSetString(targetChartId, editNote, OBJPROP_TEXT, "");

      ObjectSetInteger(targetChartId, editNote, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(targetChartId, editNote, OBJPROP_BGCOLOR, C'20,26,38');
      ObjectSetInteger(targetChartId, editNote, OBJPROP_BORDER_COLOR, C'50,70,100');
      ChartRedraw(targetChartId);
   }

   //--- Remote Button State Setters
   void SetRemoteStateProcessing(const long targetChartId)
   {
      string btnSnap = PrefixRemote() + "Snap";
      string statusLbl = PrefixRemote() + "Status";
      ObjectSetString(targetChartId, btnSnap, OBJPROP_TEXT, "⏳ DISPATCHING");
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_BGCOLOR, clrDarkOrange);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_TEXT, "● Uploading snapshot to Telegram...");
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_COLOR, clrGold);
      ChartRedraw(targetChartId);
   }

   void SetRemoteStateSuccess(const long targetChartId, const uint elapsedMs, const string channel)
   {
      string btnSnap = PrefixRemote() + "Snap";
      string statusLbl = PrefixRemote() + "Status";
      ObjectSetString(targetChartId, btnSnap, OBJPROP_TEXT, "✅ SENT! (" + IntegerToString(elapsedMs) + "ms)");
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_BGCOLOR, clrSeaGreen);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_TEXT, "● Sent to " + channel);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_COLOR, clrLimeGreen);
      ChartRedraw(targetChartId);
   }

   void SetRemoteStateFailed(const long targetChartId, const string errShort)
   {
      string btnSnap = PrefixRemote() + "Snap";
      string statusLbl = PrefixRemote() + "Status";
      ObjectSetString(targetChartId, btnSnap, OBJPROP_TEXT, "❌ SEND FAILED");
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_BGCOLOR, clrCrimson);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_TEXT, "⚠️ " + errShort);
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_COLOR, clrTomato);
      ChartRedraw(targetChartId);
   }

   void ResetRemoteState(const long targetChartId)
   {
      string btnSnap = PrefixRemote() + "Snap";
      string btnNoteSnap = PrefixRemote() + "NoteSnap";
      string statusLbl = PrefixRemote() + "Status";
      ObjectSetString(targetChartId, btnSnap, OBJPROP_TEXT, "📸 SNAP [F12]");
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(targetChartId, btnSnap, OBJPROP_STATE, false);
      ObjectSetInteger(targetChartId, btnNoteSnap, OBJPROP_STATE, false);
      ObjectSetString(targetChartId, statusLbl, OBJPROP_TEXT, "● TeleSnap Hub Linked");
      ObjectSetInteger(targetChartId, statusLbl, OBJPROP_COLOR, clrMediumSeaGreen);
      ChartRedraw(targetChartId);
   }

   //--- Poll Remote Buttons across all Linked Charts (Called in 80ms Timer)
   // Returns: 0 = none, 1 = Quick Snap, 2 = Send With Note
   int CheckRemoteTriggers(long &outTargetChartId, string &outUserNote)
   {
      for(int i = 0; i < ArraySize(m_charts); i++)
      {
         if(!m_charts[i].isLinked)
            continue;

         long cId = m_charts[i].chartId;

         // Check Quick Snap Button
         string snapBtn = PrefixRemote() + "Snap";
         if(ObjectGetInteger(cId, snapBtn, OBJPROP_STATE) == true)
         {
            ObjectSetInteger(cId, snapBtn, OBJPROP_STATE, false);
            outTargetChartId = cId;
            outUserNote = ObjectGetString(cId, PrefixRemote() + "Note", OBJPROP_TEXT);
            StringTrimLeft(outUserNote);
            StringTrimRight(outUserNote);
            if(StringFind(outUserNote, "⚠️") >= 0) outUserNote = "";
            return 1;
         }

         // Check Send With Note Button
         string noteBtn = PrefixRemote() + "NoteSnap";
         if(ObjectGetInteger(cId, noteBtn, OBJPROP_STATE) == true)
         {
            ObjectSetInteger(cId, noteBtn, OBJPROP_STATE, false);
            string typedNote = ObjectGetString(cId, PrefixRemote() + "Note", OBJPROP_TEXT);
            StringTrimLeft(typedNote);
            StringTrimRight(typedNote);

            if(StringLen(typedNote) == 0 || StringFind(typedNote, "⚠️") >= 0)
            {
               HighlightRemoteNoteRequired(cId);
               return 0; // Block send!
            }

            outTargetChartId = cId;
            outUserNote = typedNote;
            ResetRemoteNoteBox(cId, true);
            return 2;
         }
      }

      return 0;
   }

   //--- Find Linked Chart matching a Symbol for Auto-Trade Dispatching
   long FindLinkedChartForSymbol(const string symbol)
   {
      // First pass: Match linked chart that has an EA attached
      for(int i = 0; i < ArraySize(m_charts); i++)
      {
         if(m_charts[i].isLinked && StringCompare(m_charts[i].symbol, symbol, false) == 0)
         {
            if(StringLen(m_charts[i].eaName) > 0)
               return m_charts[i].chartId;
         }
      }

      // Second pass: Any linked chart for that symbol
      for(int i = 0; i < ArraySize(m_charts); i++)
      {
         if(m_charts[i].isLinked && StringCompare(m_charts[i].symbol, symbol, false) == 0)
         {
            return m_charts[i].chartId;
         }
      }

      // Third pass: Any open chart in the terminal for that symbol (even if unlinked)
      for(int i = 0; i < ArraySize(m_charts); i++)
      {
         if(StringCompare(m_charts[i].symbol, symbol, false) == 0)
         {
            return m_charts[i].chartId;
         }
      }

      return 0; // Truly no open chart in MT5 for this symbol
   }

   //--- Log Activity to Command Center Feed
   void AddLog(const string symbol, const string eventText, const uint latencyMs, const bool success)
   {
      int cur = ArraySize(m_activityLog);
      ArrayResize(m_activityLog, cur + 1);
      // Shift down if max reached
      if(cur >= m_maxLogEntries)
      {
         for(int i = 0; i < m_maxLogEntries - 1; i++)
            m_activityLog[i] = m_activityLog[i + 1];
         cur = m_maxLogEntries - 1;
         ArrayResize(m_activityLog, m_maxLogEntries);
      }

      m_activityLog[cur].time = TimeCurrent();
      m_activityLog[cur].symbol = symbol;
      m_activityLog[cur].eventText = eventText;
      m_activityLog[cur].latencyMs = latencyMs;
      m_activityLog[cur].success = success;

      RenderDashboard();
   }

   //--- Toggle Chart Link State from Dashboard Button Click
   bool HandleDashboardClick(const string objName)
   {
      if(StringFind(objName, PrefixDash() + "LinkBtn_") == 0)
      {
         string idStr = StringSubstr(objName, StringLen(PrefixDash() + "LinkBtn_"));
         long targetId = StringToInteger(idStr);

         for(int i = 0; i < ArraySize(m_charts); i++)
         {
            if(m_charts[i].chartId == targetId)
            {
               m_charts[i].isLinked = !m_charts[i].isLinked;
               if(m_charts[i].isLinked)
                  InjectRemoteHUD(targetId);
               else
                  RemoveRemoteHUD(targetId);

               RenderDashboard();
               return true;
            }
         }
      }
      else if(objName == PrefixDash() + "Btn_Refresh")
      {
         ObjectSetInteger(m_hubChartId, objName, OBJPROP_STATE, false);
         RefreshCharts(true);
         RenderDashboard();
         return true;
      }

      return false;
   }

   //--- Render full SaaS visual Command Center on host chart
   void RenderDashboard()
   {
      // Clean previous dashboard objects on host chart
      ObjectsDeleteAll(m_hubChartId, PrefixDash());

      int chartW = (int)ChartGetInteger(m_hubChartId, CHART_WIDTH_IN_PIXELS);
      m_lastChartWidth = chartW;

      int startX = 30;
      int startY = 30;
      int cardWidth = 720;
      if(chartW > 780)
      {
         cardWidth = chartW - 60;
         if(cardWidth > 1250) cardWidth = 1250;
      }

      // 1. Header Banner Card
      DrawHeaderCard(startX, startY, cardWidth);

      // 2. Chart Linker Matrix Card
      int matrixY = startY + 115;
      int matrixHeight = DrawLinkerMatrix(startX, matrixY, cardWidth);

      // 3. Live Dispatch Activity Log Card
      int logY = matrixY + matrixHeight + 20;
      DrawActivityLog(startX, logY, cardWidth);

      ChartRedraw(m_hubChartId);
   }

   //--- Header Card Renderer
   void DrawHeaderCard(const int x, const int y, const int width)
   {
      int height = 95;

      // Background panel
      string panelName = PrefixDash() + "Head_Panel";
      ObjectCreate(m_hubChartId, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_XSIZE, width);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_YSIZE, height);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_BGCOLOR, C'23,30,44');
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_BORDER_COLOR, C'45,60,85');
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_SELECTABLE, false);

      // Title
      string title = PrefixDash() + "Head_Title";
      ObjectCreate(m_hubChartId, title, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_XDISTANCE, x + 20);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_YDISTANCE, y + 15);
      ObjectSetString(m_hubChartId, title, OBJPROP_TEXT, "⚡ TELESNAP PRO — COMMAND CENTER & SIGNAL HUB");
      ObjectSetString(m_hubChartId, title, OBJPROP_FONT, "Segoe UI Black");
      ObjectSetInteger(m_hubChartId, title, OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_SELECTABLE, false);

      // Subtitle
      string sub = PrefixDash() + "Head_Sub";
      ObjectCreate(m_hubChartId, sub, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, sub, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, sub, OBJPROP_XDISTANCE, x + 20);
      ObjectSetInteger(m_hubChartId, sub, OBJPROP_YDISTANCE, y + 40);
      ObjectSetString(m_hubChartId, sub, OBJPROP_TEXT, "Master Console • Centralized Multi-Chart Snapping • Remote HUD Injection");
      ObjectSetString(m_hubChartId, sub, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(m_hubChartId, sub, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_hubChartId, sub, OBJPROP_COLOR, clrSilver);
      ObjectSetInteger(m_hubChartId, sub, OBJPROP_SELECTABLE, false);

      // Connection Status Badge
      string badge = PrefixDash() + "Head_Badge";
      ObjectCreate(m_hubChartId, badge, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, badge, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, badge, OBJPROP_XDISTANCE, x + 20);
      ObjectSetInteger(m_hubChartId, badge, OBJPROP_YDISTANCE, y + 65);

      if(m_isConnected)
      {
         ObjectSetString(m_hubChartId, badge, OBJPROP_TEXT, "● TELEGRAM CONNECTED: @" + m_botUsername + " ➔ " + m_chatTarget);
         ObjectSetInteger(m_hubChartId, badge, OBJPROP_COLOR, clrMediumSeaGreen);
      }
      else
      {
         ObjectSetString(m_hubChartId, badge, OBJPROP_TEXT, "⚠️ TELEGRAM SETUP REQUIRED (Enter Bot Token in Inputs)");
         ObjectSetInteger(m_hubChartId, badge, OBJPROP_COLOR, clrTomato);
      }
      ObjectSetString(m_hubChartId, badge, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_hubChartId, badge, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_hubChartId, badge, OBJPROP_SELECTABLE, false);

      // Refresh Button
      string btnRef = PrefixDash() + "Btn_Refresh";
      ObjectCreate(m_hubChartId, btnRef, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_XDISTANCE, x + width - 140);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_YDISTANCE, y + 25);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_XSIZE, 120);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_YSIZE, 35);
      ObjectSetString(m_hubChartId, btnRef, OBJPROP_TEXT, "🔄 REFRESH");
      ObjectSetString(m_hubChartId, btnRef, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_BGCOLOR, C'40,55,80');
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_BORDER_COLOR, clrDodgerBlue);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_hubChartId, btnRef, OBJPROP_STATE, false);
   }

   //--- Chart Linker Matrix Card Renderer
   int DrawLinkerMatrix(const int x, const int y, const int width)
   {
      int rowHeight = 38;
      int totalCharts = ArraySize(m_charts);
      int displayRows = MathMax(1, totalCharts);
      int totalHeight = 45 + (displayRows * rowHeight) + 15;

      // Panel Background
      string panelName = PrefixDash() + "Matrix_Panel";
      ObjectCreate(m_hubChartId, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_XSIZE, width);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_YSIZE, totalHeight);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_BGCOLOR, C'23,30,44');
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_BORDER_COLOR, C'45,60,85');
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_SELECTABLE, false);

      // Section Title
      string secTitle = PrefixDash() + "Matrix_Title";
      ObjectCreate(m_hubChartId, secTitle, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, secTitle, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, secTitle, OBJPROP_XDISTANCE, x + 20);
      ObjectSetInteger(m_hubChartId, secTitle, OBJPROP_YDISTANCE, y + 14);
      ObjectSetString(m_hubChartId, secTitle, OBJPROP_TEXT, "📊 CHART LINKER MANAGER (" + IntegerToString(totalCharts) + " Open Terminal Charts)");
      ObjectSetString(m_hubChartId, secTitle, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_hubChartId, secTitle, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(m_hubChartId, secTitle, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(m_hubChartId, secTitle, OBJPROP_SELECTABLE, false);

      if(totalCharts == 0)
      {
         string emptyLbl = PrefixDash() + "Matrix_Empty";
         ObjectCreate(m_hubChartId, emptyLbl, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_XDISTANCE, x + 25);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_YDISTANCE, y + 48);
         ObjectSetString(m_hubChartId, emptyLbl, OBJPROP_TEXT, "👉 No other trading charts open! Open a chart (e.g. XAUUSD) and click [REFRESH].");
         ObjectSetString(m_hubChartId, emptyLbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_COLOR, clrSilver);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_SELECTABLE, false);
         return totalHeight;
      }

      // Draw Chart Rows
      for(int i = 0; i < totalCharts; i++)
      {
         int rowY = y + 42 + (i * rowHeight);

         // Alternating row background
         string rowBg = PrefixDash() + "RowBg_" + IntegerToString(i);
         ObjectCreate(m_hubChartId, rowBg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_XDISTANCE, x + 15);
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_YDISTANCE, rowY);
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_XSIZE, width - 30);
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_YSIZE, 32);
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_BGCOLOR, (i % 2 == 0) ? C'28,36,52' : C'20,26,38');
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_BORDER_COLOR, C'38,48,68');
         ObjectSetInteger(m_hubChartId, rowBg, OBJPROP_SELECTABLE, false);

         // Symbol & Timeframe
         string tfStr = StringSubstr(EnumToString(m_charts[i].timeframe), 7);
         string symLbl = PrefixDash() + "Sym_" + IntegerToString(i);
         ObjectCreate(m_hubChartId, symLbl, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, symLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, symLbl, OBJPROP_XDISTANCE, x + 25);
         ObjectSetInteger(m_hubChartId, symLbl, OBJPROP_YDISTANCE, rowY + 7);
         ObjectSetString(m_hubChartId, symLbl, OBJPROP_TEXT, m_charts[i].symbol + " (" + tfStr + ")");
         ObjectSetString(m_hubChartId, symLbl, OBJPROP_FONT, "Segoe UI Semibold");
         ObjectSetInteger(m_hubChartId, symLbl, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(m_hubChartId, symLbl, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(m_hubChartId, symLbl, OBJPROP_SELECTABLE, false);

         // Attached EA or Manual tag
         string eaText = (StringLen(m_charts[i].eaName) > 0) ? ("🤖 " + m_charts[i].eaName) : "👤 Manual Trading";
         string eaLbl = PrefixDash() + "EA_" + IntegerToString(i);
         ObjectCreate(m_hubChartId, eaLbl, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, eaLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, eaLbl, OBJPROP_XDISTANCE, x + 190);
         ObjectSetInteger(m_hubChartId, eaLbl, OBJPROP_YDISTANCE, rowY + 8);
         ObjectSetString(m_hubChartId, eaLbl, OBJPROP_TEXT, eaText);
         ObjectSetString(m_hubChartId, eaLbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(m_hubChartId, eaLbl, OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(m_hubChartId, eaLbl, OBJPROP_COLOR, (StringLen(m_charts[i].eaName) > 0) ? clrGold : clrSilver);
         ObjectSetInteger(m_hubChartId, eaLbl, OBJPROP_SELECTABLE, false);

         // Status Indicator
         string statLbl = PrefixDash() + "Stat_" + IntegerToString(i);
         ObjectCreate(m_hubChartId, statLbl, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, statLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, statLbl, OBJPROP_XDISTANCE, x + 440);
         ObjectSetInteger(m_hubChartId, statLbl, OBJPROP_YDISTANCE, rowY + 8);
         ObjectSetString(m_hubChartId, statLbl, OBJPROP_TEXT, m_charts[i].isLinked ? "● Remote Buttons Active" : "○ Unlinked");
         ObjectSetString(m_hubChartId, statLbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(m_hubChartId, statLbl, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(m_hubChartId, statLbl, OBJPROP_COLOR, m_charts[i].isLinked ? clrMediumSeaGreen : clrDimGray);
         ObjectSetInteger(m_hubChartId, statLbl, OBJPROP_SELECTABLE, false);

         // Toggle Link Button
         string btnLink = PrefixDash() + "LinkBtn_" + IntegerToString(m_charts[i].chartId);
         ObjectCreate(m_hubChartId, btnLink, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_XDISTANCE, x + width - 150);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_YDISTANCE, rowY + 3);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_XSIZE, 125);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_YSIZE, 26);
         ObjectSetString(m_hubChartId, btnLink, OBJPROP_TEXT, m_charts[i].isLinked ? "🔗 LINKED" : "➕ LINK CHART");
         ObjectSetString(m_hubChartId, btnLink, OBJPROP_FONT, "Segoe UI Semibold");
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_BGCOLOR, m_charts[i].isLinked ? clrSeaGreen : C'45,55,75');
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_BORDER_COLOR, m_charts[i].isLinked ? clrMediumSeaGreen : C'70,85,110');
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_hubChartId, btnLink, OBJPROP_STATE, false);
      }

      return totalHeight;
   }

   //--- Live Activity Feed Renderer
   void DrawActivityLog(const int x, const int y, const int width)
   {
      int totalLogs = ArraySize(m_activityLog);
      int displayLogs = MathMin(m_maxLogEntries, MathMax(1, totalLogs));
      int totalHeight = 45 + (displayLogs * 24) + 15;

      // Panel Background
      string panelName = PrefixDash() + "Log_Panel";
      ObjectCreate(m_hubChartId, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_XSIZE, width);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_YSIZE, totalHeight);
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_BGCOLOR, C'23,30,44');
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_BORDER_COLOR, C'45,60,85');
      ObjectSetInteger(m_hubChartId, panelName, OBJPROP_SELECTABLE, false);

      // Title
      string title = PrefixDash() + "Log_Title";
      ObjectCreate(m_hubChartId, title, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_XDISTANCE, x + 20);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_YDISTANCE, y + 14);
      ObjectSetString(m_hubChartId, title, OBJPROP_TEXT, "📡 LIVE DISPATCH FEED & AUDIT LOG");
      ObjectSetString(m_hubChartId, title, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_hubChartId, title, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_COLOR, clrMediumSeaGreen);
      ObjectSetInteger(m_hubChartId, title, OBJPROP_SELECTABLE, false);

      if(totalLogs == 0)
      {
         string emptyLbl = PrefixDash() + "Log_Empty";
         ObjectCreate(m_hubChartId, emptyLbl, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_XDISTANCE, x + 25);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_YDISTANCE, y + 45);
         ObjectSetString(m_hubChartId, emptyLbl, OBJPROP_TEXT, "● Waiting for trade events or manual snaps... Click [SNAP] on any linked chart!");
         ObjectSetString(m_hubChartId, emptyLbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_COLOR, clrSilver);
         ObjectSetInteger(m_hubChartId, emptyLbl, OBJPROP_SELECTABLE, false);
         return;
      }

      // Render logs in reverse chronological order
      int startIdx = totalLogs - 1;
      int rendered = 0;
      for(int i = startIdx; i >= 0 && rendered < m_maxLogEntries; i--)
      {
         int itemY = y + 42 + (rendered * 24);
         string timeStr = TimeToString(m_activityLog[i].time, TIME_MINUTES|TIME_SECONDS);
         string latStr = "(" + IntegerToString(m_activityLog[i].latencyMs) + "ms)";
         string statusIcon = m_activityLog[i].success ? "✅" : "❌";

         string logLine = statusIcon + " [" + timeStr + "] " + m_activityLog[i].symbol + " • " + 
                          m_activityLog[i].eventText + " " + latStr;

         string lblLog = PrefixDash() + "LogItem_" + IntegerToString(rendered);
         ObjectCreate(m_hubChartId, lblLog, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_hubChartId, lblLog, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_hubChartId, lblLog, OBJPROP_XDISTANCE, x + 25);
         ObjectSetInteger(m_hubChartId, lblLog, OBJPROP_YDISTANCE, itemY);
         ObjectSetString(m_hubChartId, lblLog, OBJPROP_TEXT, logLine);
         ObjectSetString(m_hubChartId, lblLog, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(m_hubChartId, lblLog, OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(m_hubChartId, lblLog, OBJPROP_COLOR, m_activityLog[i].success ? clrWhite : clrTomato);
         ObjectSetInteger(m_hubChartId, lblLog, OBJPROP_SELECTABLE, false);

         rendered++;
      }
   }

   //--- Clean up all dashboard objects on host chart and remote charts
   void Destroy()
   {
      // Clean host dashboard
      ObjectsDeleteAll(m_hubChartId, PrefixDash());

      // Clean remote HUD from all linked charts
      for(int i = 0; i < ArraySize(m_charts); i++)
      {
         RemoveRemoteHUD(m_charts[i].chartId);
      }
      ArrayResize(m_charts, 0);

      // Restore regular chart styling on host chart
      ChartSetInteger(m_hubChartId, CHART_SHOW_PRICE_SCALE, true);
      ChartSetInteger(m_hubChartId, CHART_SHOW_DATE_SCALE, true);
      ChartSetInteger(m_hubChartId, CHART_SHOW_GRID, true);
      ChartRedraw(m_hubChartId);
   }
};
