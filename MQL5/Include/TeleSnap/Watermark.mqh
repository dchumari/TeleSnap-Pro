//+------------------------------------------------------------------+
//|                                                    Watermark.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Watermarking, Multi-Target Calculations & Rich Signal Generator  |
//+------------------------------------------------------------------+
class CWatermarkEngine
{
private:
   string            m_channelTag;
   string            m_vipInviteLink;
   string            m_disclaimer;
   string            m_watermarkObjName;
   bool              m_isLiteMode;

   //--- Calculate pip size for symbol
   double GetPipSize(const string symbol)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      if(digits == 3 || digits == 5)
         return point * 10.0;
      return point;
   }

public:
   CWatermarkEngine() : m_channelTag("@TeleSnapPro"), 
                        m_vipInviteLink(""), 
                        m_disclaimer("⚠️ Risk Warning: Trading Forex/Crypto carries high risk."),
                        m_watermarkObjName("TeleSnap_Watermark_Overlay"),
                        m_isLiteMode(false)
   {}

   ~CWatermarkEngine()
   {
      RemoveOnChartWatermark(0);
   }

   void SetLiteMode(const bool isLite)
   {
      m_isLiteMode = isLite;
      if(m_isLiteMode)
      {
         m_channelTag = "Powered by TeleSnap Pro - Get on MQL5";
         m_vipInviteLink = "https://www.mql5.com";
      }
   }

   bool IsLiteMode() const { return m_isLiteMode; }

   void SetBranding(const string channelTag, const string inviteLink = "", const string disclaimer = "")
   {
      if(m_isLiteMode)
      {
         m_channelTag = "Powered by TeleSnap Pro - Get on MQL5";
         m_vipInviteLink = "https://www.mql5.com";
      }
      else
      {
         if(StringLen(channelTag) > 0)
            m_channelTag = channelTag;
         m_vipInviteLink = inviteLink;
      }

      if(StringLen(disclaimer) > 0)
         m_disclaimer = disclaimer;
   }

   string GetChannelTag() const { return m_channelTag; }

   //--- Render on-chart watermark label before screenshot
   void DrawOnChartWatermark(const long chartId, const ENUM_WATERMARK_POSITION position, const color textColor = clrDimGray)
   {
      ObjectDelete(chartId, m_watermarkObjName);

      if(!ObjectCreate(chartId, m_watermarkObjName, OBJ_LABEL, 0, 0, 0))
         return;

      string displayTag = m_channelTag;
      if(m_isLiteMode)
         displayTag = "⚡ Powered by TeleSnap Pro (Free MQL5 Edition)";

      ObjectSetString(chartId, m_watermarkObjName, OBJPROP_TEXT, displayTag);
      ObjectSetString(chartId, m_watermarkObjName, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_FONTSIZE, 13);
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_COLOR, m_isLiteMode ? clrDodgerBlue : textColor);
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_HIDDEN, true);

      switch(position)
      {
         case POS_TOP_LEFT:
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 30);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 120);
            break;
         case POS_TOP_RIGHT:
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 240);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 40);
            break;
         case POS_BOTTOM_LEFT:
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 30);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 40);
            break;
         case POS_BOTTOM_RIGHT:
         default:
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_CORNER, CORNER_RIGHT_LOWER);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 260);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 40);
            break;
      }
      ChartRedraw(chartId);
   }

   void RemoveOnChartWatermark(const long chartId)
   {
      ObjectDelete(chartId, m_watermarkObjName);
      ChartRedraw(chartId);
   }

   //--- Build rich, ultra-informative HTML signal post
   string BuildSignalCaption(const TradeSignalInfo &info, const ENUM_CAPTION_STYLE style)
   {
      string directionEmoji = (StringFind(info.orderType, "BUY") >= 0) ? "🟢" : "🔴";
      string tfStr = StringSubstr(EnumToString(info.timeframe), 11);
      int digits = (int)SymbolInfoInteger(info.symbol, SYMBOL_DIGITS);
      double pipSize = GetPipSize(info.symbol);

      string caption = "";

      // 1. Header Banner
      caption += "📊 <b>" + info.symbol + " • " + tfStr + " ANALYSIS & SIGNAL</b>\n";
      caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";

      // 2. Status & Order Information
      string statusText = "🟢 IN TRADE (RUNNING)";
      if(info.status == "NEW_SETUP") statusText = "⚡ NEW EXECUTION";
      else if(info.status == "TAKE_PROFIT") statusText = "🎯 TAKE PROFIT REACHED";
      else if(info.status == "STOP_LOSS") statusText = "🛑 STOP LOSS HIT";
      else if(info.status == "WATCHLIST") statusText = "👀 MARKET SETUP / WATCHLIST";

      caption += "📍 <b>Status:</b> " + statusText + "\n";
      caption += directionEmoji + " <b>Action:</b> <b>" + info.orderType + "</b> @ <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";

      if(info.volume > 0)
      {
         caption += "📦 <b>Volume:</b> " + DoubleToString(info.volume, 2) + " Lots";
         if(info.ticket > 0)
            caption += " (Ticket #" + IntegerToString(info.ticket) + ")";
         caption += "\n";
      }

      // 3. In-Trade Live PnL & Current Price
      if(info.status == "IN_TRADE" || info.floatingPnL != 0)
      {
         string pnlPrefix = (info.floatingPnL >= 0) ? "+$" : "-$";
         string pipsPrefix = (info.floatingPips >= 0) ? "+" : "";
         caption += "💰 <b>Floating PnL:</b> " + pnlPrefix + DoubleToString(MathAbs(info.floatingPnL), 2) + 
                    " (" + pipsPrefix + DoubleToString(info.floatingPips, 1) + " pips)\n";
         caption += "🏷️ <b>Current Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
      }

      caption += "─────────────────────────\n";

      // 4. Stop Loss
      if(info.stopLoss > 0)
      {
         caption += "🛡️ <b>Stop Loss:</b> <code>" + DoubleToString(info.stopLoss, digits) + "</code>";
         if(info.slPips > 0)
            caption += " (-" + DoubleToString(info.slPips, 1) + " pips)";
         caption += "\n";
      }
      else
      {
         caption += "🛡️ <b>Stop Loss:</b> <i>Not Set (Open Risk)</i>\n";
      }

      // 5. Multi-Tier Take Profit Targets
      if(info.takeProfit > 0)
      {
         // If user has a final TP, calculate TP1 and TP2 milestones
         if(info.tp1Price > 0 && info.tp1Price != info.takeProfit)
         {
            double tp1Pips = (pipSize > 0) ? MathAbs(info.tp1Price - info.entryPrice) / pipSize : 0;
            caption += "🎯 <b>Take Profit 1 (1:1):</b> <code>" + DoubleToString(info.tp1Price, digits) + 
                       "</code> (+" + DoubleToString(tp1Pips, 1) + " pips)\n";
         }

         if(info.tp2Price > 0 && info.tp2Price < info.takeProfit && (info.orderType == "BUY" ? info.tp2Price < info.takeProfit : info.tp2Price > info.takeProfit))
         {
            double tp2Pips = (pipSize > 0) ? MathAbs(info.tp2Price - info.entryPrice) / pipSize : 0;
            caption += "🎯 <b>Take Profit 2 (1:2):</b> <code>" + DoubleToString(info.tp2Price, digits) + 
                       "</code> (+" + DoubleToString(tp2Pips, 1) + " pips)\n";
         }

         caption += "🎯 <b>Take Profit (Final):</b> <code>" + DoubleToString(info.takeProfit, digits) + "</code>";
         if(info.tpPips > 0)
            caption += " (+" + DoubleToString(info.tpPips, 1) + " pips)";
         caption += "\n";

         if(info.riskRewardRatio > 0)
         {
            caption += "⚖️ <b>Risk : Reward:</b> <b>1 : " + DoubleToString(info.riskRewardRatio, 2) + "</b>\n";
         }
      }

      // 6. Market Context (Spread & Server Time)
      if(info.spreadPips > 0)
      {
         caption += "📏 <b>Spread:</b> " + DoubleToString(info.spreadPips, 1) + " pips\n";
      }
      caption += "🕒 <b>Server Time:</b> " + TimeToString(info.signalTime, TIME_DATE|TIME_MINUTES) + "\n";

      // 7. Custom Trader Commentary (From on-chart note box)
      if(StringLen(info.customComment) > 0 && info.customComment != "Type trade note / commentary here..." && info.customComment != "Manual Signal Snapshot")
      {
         caption += "─────────────────────────\n";
         caption += "💬 <b>Trader's Commentary:</b>\n";
         caption += "<i>\"" + info.customComment + "\"</i>\n";
      }

      caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";

      // 8. Branding & Attribution
      if(m_isLiteMode)
      {
         caption += "📢 <b>Powered by TeleSnap Pro</b>\n";
         caption += "⚡ <i>Get TeleSnap on MQL5 Market: <a href=\"https://www.mql5.com\">mql5.com</a></i>";
      }
      else
      {
         caption += "📢 <b>Channel:</b> " + m_channelTag + "\n";
         if(StringLen(m_vipInviteLink) > 0)
         {
            caption += "🔗 <a href=\"" + m_vipInviteLink + "\">Join VIP Community</a>\n";
         }
         caption += "⚡ <i>Powered by TeleSnap Pro</i>";
      }

      return caption;
   }
};
