//+------------------------------------------------------------------+
//|                                           Open_TeleSnap_Hub.mq5  |
//|                                Copyright 2026, Derrick Chumari.  |
//|                         https://github.com/dchumari/TeleSnap-Pro |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Derrick Chumari."
#property link        "https://github.com/dchumari/TeleSnap-Pro"
#property version     "2.00"
#property description "⚡ 1-Click Launcher for TeleSnap Pro Command Center Hub"
#property description "Instantly opens or switches to the dedicated TeleSnap Hub window without manual chart setup."
#property script_show_inputs false

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("⚡ [TeleSnap Launcher] Checking for active TeleSnap Hub window...");

   // 1. Scan if TeleSnap Hub is already open on any chart tab
   long chart = ChartFirst();
   while(chart >= 0)
   {
      string expName = ChartGetString(chart, CHART_EXPERT_NAME);
      if(StringFind(expName, "TeleSnap") >= 0)
      {
         ChartSetInteger(chart, CHART_BRING_TO_TOP, true);
         ChartRedraw(chart);
         PrintFormat("✅ [TeleSnap Launcher] TeleSnap Hub is already active (Chart ID: %d). Brought window to front!", chart);
         return;
      }
      chart = ChartNext(chart);
   }

   // 2. Determine an available symbol in Market Watch to host the Hub
   string hubSymbol = "EURUSD";
   if(!SymbolInfoInteger(hubSymbol, SYMBOL_VISIBLE))
   {
      if(SymbolInfoInteger(_Symbol, SYMBOL_VISIBLE))
         hubSymbol = _Symbol;
      else
         hubSymbol = SymbolName(0, true);
   }

   PrintFormat("⚡ [TeleSnap Launcher] Opening new dedicated Hub chart for %s...", hubSymbol);

   // 3. Open a dedicated new chart tab (Daily timeframe for stable background)
   long newChart = ChartOpen(hubSymbol, PERIOD_D1);
   if(newChart > 0)
   {
      // 4. Apply pre-styled TeleSnap_Hub.tpl template (launches TeleSnap with 0 lines, dark canvas)
      if(!ChartApplyTemplate(newChart, "TeleSnap_Hub.tpl"))
      {
         Print("⚠️ [TeleSnap Launcher] Note: TeleSnap_Hub.tpl not found in templates yet. Opened clean chart.");
      }

      ChartSetInteger(newChart, CHART_BRING_TO_TOP, true);
      ChartRedraw(newChart);
      PrintFormat("✅ [TeleSnap Launcher] Dedicated TeleSnap Hub launched successfully! (Chart ID: %d)", newChart);
   }
   else
   {
      PrintFormat("❌ [TeleSnap Launcher] Could not open chart window. Error: %d", GetLastError());
   }
}
//+------------------------------------------------------------------+
