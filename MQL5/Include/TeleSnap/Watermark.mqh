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
//| Watermarking, Caption Formatting & Risk Analytics Engine         |
//+------------------------------------------------------------------+
class CWatermarkEngine
{
private:
   string            m_channelTag;
   string            m_vipInviteLink;
   string            m_disclaimer;
   string            m_watermarkObjName;

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
                        m_watermarkObjName("TeleSnap_Watermark_Overlay")
   {}

   ~CWatermarkEngine()
   {
      RemoveOnChartWatermark(0);
   }

   void SetBranding(const string channelTag, const string inviteLink = "", const string disclaimer = "")
   {
      m_channelTag = channelTag;
      m_vipInviteLink = inviteLink;
      if(StringLen(disclaimer) > 0) m_disclaimer = disclaimer;
   }

   //--- Render on-chart watermark label before screenshot
   void DrawOnChartWatermark(const long chartId, const ENUM_WATERMARK_POSITION position, const color textColor = clrDimGray)
   {
      ObjectDelete(chartId, m_watermarkObjName);

      if(!ObjectCreate(chartId, m_watermarkObjName, OBJ_LABEL, 0, 0, 0))
         return;

      ObjectSetString(chartId, m_watermarkObjName, OBJPROP_TEXT, m_channelTag);
      ObjectSetString(chartId, m_watermarkObjName, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_FONTSIZE, 14);
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_COLOR, textColor);
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_HIDDEN, true);

      switch(position)
      {
         case POS_TOP_LEFT:
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 30);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 40);
            break;
         case POS_TOP_RIGHT:
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 180);
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
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_XDISTANCE, 200);
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 40);
            break;
      }
      ChartRedraw(chartId);
   }

   //--- Remove watermark label after screenshot if temporary
   void RemoveOnChartWatermark(const long chartId)
   {
      ObjectDelete(chartId, m_watermarkObjName);
      ChartRedraw(chartId);
   }

   //--- Build rich HTML formatted caption for Telegram
   string BuildSignalCaption(const TradeSignalInfo &info, const ENUM_CAPTION_STYLE style)
   {
      string directionEmoji = (StringFind(info.orderType, "BUY") >= 0) ? "🟢" : "🔴";
      string tfStr = StringSubstr(EnumToString(info.timeframe), 11); // e.g. "PERIOD_M15" -> "M15"
      int digits = (int)SymbolInfoInteger(info.symbol, SYMBOL_DIGITS);

      string caption = "";

      // Header
      caption += directionEmoji + " <b>NEW SIGNAL: " + info.symbol + " (" + tfStr + ")</b>\n";
      caption += "━━━━━━━━━━━━━━━━━━━━\n";
      caption += "<b>Type:</b> " + info.orderType + "\n";
      caption += "<b>Entry:</b> " + DoubleToString(info.entryPrice, digits) + "\n";

      if(info.stopLoss > 0)
      {
         double pipSize = GetPipSize(info.symbol);
         double slPips = (pipSize > 0) ? MathAbs(info.entryPrice - info.stopLoss) / pipSize : 0;
         caption += "<b>Stop Loss:</b> " + DoubleToString(info.stopLoss, digits) + 
                    " (" + DoubleToString(slPips, 1) + " pips)\n";
      }

      if(info.takeProfit > 0)
      {
         double pipSize = GetPipSize(info.symbol);
         double tpPips = (pipSize > 0) ? MathAbs(info.takeProfit - info.entryPrice) / pipSize : 0;
         caption += "<b>Take Profit:</b> " + DoubleToString(info.takeProfit, digits) + 
                    " (" + DoubleToString(tpPips, 1) + " pips)\n";

         if(info.stopLoss > 0 && MathAbs(info.entryPrice - info.stopLoss) > 0)
         {
            double rr = MathAbs(info.takeProfit - info.entryPrice) / MathAbs(info.entryPrice - info.stopLoss);
            caption += "<b>Risk : Reward:</b> 1 : " + DoubleToString(rr, 2) + "\n";
         }
      }

      if(StringLen(info.customComment) > 0)
      {
         caption += "<b>Note:</b> " + info.customComment + "\n";
      }

      caption += "━━━━━━━━━━━━━━━━━━━━\n";
      caption += "📢 <b>Channel:</b> " + m_channelTag + "\n";

      if(StringLen(m_vipInviteLink) > 0)
      {
         caption += "🔗 <a href=\"" + m_vipInviteLink + "\">Join VIP Community</a>\n";
      }

      if(style == STYLE_MARKETING)
      {
         caption += "\n<i>" + m_disclaimer + "</i>\n";
      }

      caption += "⚡ <i>Powered by TeleSnap Pro</i>";
      return caption;
   }
};
