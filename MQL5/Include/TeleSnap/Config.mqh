//+------------------------------------------------------------------+
//|                                                       Config.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

//--- Capture triggers enum
enum ENUM_CAPTURE_TRIGGER
{
   TRIGGER_BUTTON_ONLY,     // Manual HUD Buttons & Hotkey (F12) Only
   TRIGGER_AUTO_ON_ENTRY,   // Auto-Snap on Trade Open + Manual Buttons
   TRIGGER_AUTO_ALL_EVENTS  // Auto-Snap on Open, TP, SL, Partials & Manual Closes
};

//--- Image resolution presets
enum ENUM_IMAGE_RESOLUTION
{
   RES_CURRENT_CHART,       // Match Active Chart Size
   RES_HD_1280x720,         // HD Ready (1280 x 720) - 16:9
   RES_FHD_1920x1080        // Full HD (1920 x 1080) - 16:9 Crisp
};

//--- Watermark position presets
enum ENUM_WATERMARK_POSITION
{
   POS_TOP_LEFT,            // Top Left Corner
   POS_TOP_RIGHT,           // Top Right Corner
   POS_BOTTOM_LEFT,         // Bottom Left Corner
   POS_BOTTOM_RIGHT,        // Bottom Right Corner
   POS_CENTER               // Center Chart Overlay
};

//--- Signal format styles
enum ENUM_CAPTION_STYLE
{
   STYLE_MINIMAL,           // Clean: Symbol, Direction, Entry, SL, TP
   STYLE_DETAILED,          // Detailed: Risk:Reward, Pips, Account Risk %, Time
   STYLE_INSTITUTIONAL      // Institutional: In-Trade stats, multi-TP targets, spread, floating PnL & Note
};

//--- Trade snapshot data structure (Extended with partials and close reasons)
struct TradeSignalInfo
{
   string            symbol;
   ENUM_TIMEFRAMES   timeframe;
   string            status;          // "IN_TRADE", "NEW_SETUP", "TAKE_PROFIT", "STOP_LOSS", "PARTIAL_CLOSE", "MANUAL_PROFIT", "MANUAL_LOSS", "BREAKEVEN", "PENDING_SETUP", "WATCHLIST"
   string            orderType;       // BUY, SELL, BUY LIMIT, SELL LIMIT, etc.
   double            entryPrice;
   double            currentPrice;
   double            stopLoss;
   double            takeProfit;
   double            tp1Price;        // 1:1 R:R target
   double            tp2Price;        // 1:2 R:R target
   double            volume;          // Lot size (e.g. 0.24)
   double            closedVolume;    // Volume closed on partial/full
   double            remainingVolume; // Volume still open on partial
   double            floatingPnL;     // Profit or realized PnL in account currency
   double            floatingPips;    // Current profit or outcome in pips
   double            slPips;
   double            tpPips;
   double            riskRewardRatio;
   double            spreadPips;
   string            currency;        // USD, EUR, GBP, KES, etc.
   datetime          signalTime;
   ulong             ticket;
   string            customComment;   // Custom message from on-chart edit box
};
