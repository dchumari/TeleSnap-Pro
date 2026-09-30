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
   TRIGGER_BUTTON_ONLY,     // Manual HUD Button & Hotkey (F12) Only
   TRIGGER_AUTO_ON_ENTRY,   // Auto-Snap on Trade Open + Button/Hotkey
   TRIGGER_AUTO_ALL_EVENTS  // Auto-Snap on Open, SL, and TP + Button/Hotkey
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
   STYLE_MARKETING          // Viral: Full stats + VIP Join Link & Disclaimers
};

//--- Trade snapshot data structure
struct TradeSignalInfo
{
   string            symbol;
   ENUM_TIMEFRAMES   timeframe;
   string            orderType;       // BUY, SELL, BUY LIMIT, etc.
   double            entryPrice;
   double            stopLoss;
   double            takeProfit;
   double            slPips;
   double            tpPips;
   double            riskRewardRatio;
   datetime          signalTime;
   ulong             ticket;
   string            customComment;
};
