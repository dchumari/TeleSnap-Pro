//+------------------------------------------------------------------+
//|                                                    Watermark.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"
#include "Telegram.mqh"

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
            ObjectSetInteger(chartId, m_watermarkObjName, OBJPROP_YDISTANCE, 135);
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

   string FormatTimeframe(const ENUM_TIMEFRAMES tf)
   {
      string s = EnumToString(tf);
      if(StringFind(s, "PERIOD_") == 0)
         return StringSubstr(s, 7);
      if(StringLen(s) == 0 || s == "0" || s == "PERIOD_CURRENT")
         return "M1";
      return s;
   }

   //--- Build rich, ultra-informative HTML signal post
   string BuildSignalCaption(const TradeSignalInfo &info, const ENUM_CAPTION_STYLE style)
   {
      string tfStr = FormatTimeframe(info.timeframe);
      int digits = (int)SymbolInfoInteger(info.symbol, SYMBOL_DIGITS);
      double pipSize = GetPipSize(info.symbol);
      string ccy = (StringLen(info.currency) > 0) ? info.currency : "USD";

      string caption = "";

      // 1. Header Banner & Status Classification
      if(info.status == "PARTIAL_CLOSE")
      {
         caption += "✂️ <b>PARTIAL PROFIT TAKEN: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Action:</b> Secured Partial Profits\n";
         caption += "💰 <b>Realized Gain:</b> +$" + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy;
         if(info.floatingPips > 0) caption += " (+" + DoubleToString(info.floatingPips, 1) + " pips)";
         caption += "\n";
         caption += "📦 <b>Closed Volume:</b> " + DoubleToString(info.closedVolume, 2) + " Lots\n";
         caption += "🏃 <b>Still Running:</b> " + DoubleToString(info.remainingVolume, 2) + " Lots\n";
         caption += "🏁 <b>Exit Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.entryPrice > 0) caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
         caption += "💡 <i>Suggestion: Move Stop Loss to Breakeven to secure a risk-free trade!</i>\n";
      }
      else if(info.status == "TAKE_PROFIT")
      {
         caption += "🎯 <b>TAKE PROFIT HIT: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> 🎯 TARGET FULLY REACHED ✅\n";
         caption += "💰 <b>Total Profit:</b> +$" + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy;
         if(info.tpPips > 0) caption += " (+" + DoubleToString(info.tpPips, 1) + " pips)";
         caption += "\n";
         caption += "🏁 <b>Exit Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.entryPrice > 0) caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
      }
      else if(info.status == "STOP_LOSS")
      {
         caption += "🛑 <b>STOP LOSS HIT: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> 🛑 STOPPED OUT (Risk Protected)\n";
         caption += "💸 <b>Realized PnL:</b> -$" + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy;
         if(info.slPips > 0) caption += " (-" + DoubleToString(info.slPips, 1) + " pips)";
         caption += "\n";
         caption += "🏁 <b>Exit Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.entryPrice > 0) caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
      }
      else if(info.status == "MANUAL_PROFIT")
      {
         caption += "💰 <b>MANUAL CASHOUT: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> 🟢 Closed Early in Profit\n";
         caption += "💰 <b>Realized Profit:</b> +$" + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy;
         if(info.floatingPips > 0) caption += " (+" + DoubleToString(info.floatingPips, 1) + " pips)";
         caption += "\n";
         caption += "🏁 <b>Exit Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.entryPrice > 0) caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
      }
      else if(info.status == "MANUAL_LOSS")
      {
         caption += "⚠️ <b>MANUAL CLOSE: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> ⚠️ Trader Cut Position Early\n";
         caption += "💸 <b>Loss Managed:</b> -$" + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy;
         if(info.floatingPips < 0) caption += " (-" + DoubleToString(MathAbs(info.floatingPips), 1) + " pips)";
         caption += "\n";
         caption += "🏁 <b>Exit Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.entryPrice > 0) caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
      }
      else if(info.status == "BREAKEVEN")
      {
         caption += "⚖️ <b>CLOSED AT BREAKEVEN: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> ⚖️ Breakeven Exit\n";
         if(info.floatingPnL != 0)
         {
            string pnlSign = (info.floatingPnL >= 0) ? "+$" : "-$";
            caption += "💸 <b>Net Realized:</b> " + pnlSign + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy;
            if(info.floatingPips != 0)
            {
               string pipSign = (info.floatingPips >= 0) ? "+" : "";
               caption += " (" + pipSign + DoubleToString(info.floatingPips, 1) + " pips)";
            }
            caption += "\n";
         }
         caption += "🏁 <b>Exit Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.entryPrice > 0) caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
      }
      else if(info.status == "SL_BREAKEVEN")
      {
         caption += "🛡️ <b>RISK-FREE TRADE: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Action:</b> 🛡️ Stop Loss Moved to Breakeven\n";
         caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
         caption += "🛡️ <b>New Stop Loss:</b> <code>" + DoubleToString(info.stopLoss, digits) + "</code> ($0.00 Risk)\n";
         if(info.currentPrice > 0)
            caption += "🏁 <b>Current Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.volume > 0)
            caption += "📦 <b>Volume:</b> " + DoubleToString(info.volume, 2) + " Lots\n";
         caption += "💡 <i>Position is fully protected against downside risk!</i>\n";
      }
      else if(info.status == "SL_TRAILED")
      {
         caption += "📈 <b>PROFIT LOCKED: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Action:</b> 📈 Stop Loss Trailed\n";
         caption += "🚪 <b>Entry Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
         caption += "🛡️ <b>Locked Stop Loss:</b> <code>" + DoubleToString(info.stopLoss, digits) + "</code>\n";
         if(info.currentPrice > 0)
            caption += "🏁 <b>Current Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         if(info.volume > 0)
            caption += "📦 <b>Volume:</b> " + DoubleToString(info.volume, 2) + " Lots\n";
         caption += "💡 <i>Trailing Stop active: guaranteed profit secured!</i>\n";
      }
      else if(info.status == "ORDER_CANCELED")
      {
         caption += "❌ <b>ORDER CANCELED: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> ❌ " + info.orderType + "\n";
         caption += "🏷️ <b>Price:</b> <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
         if(info.volume > 0)
            caption += "📦 <b>Volume:</b> " + DoubleToString(info.volume, 2) + " Lots\n";
         caption += "💡 <i>Setup invalidated or canceled by trader.</i>\n";
      }
      else if(info.status == "PENDING_SETUP")
      {
         caption += "⏳ <b>PENDING ORDER SETUP: " + info.symbol + " (" + tfStr + ")</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Order Type:</b> <b>" + info.orderType + "</b> @ <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";
         if(info.volume > 0)
            caption += "📦 <b>Order Volume:</b> " + DoubleToString(info.volume, 2) + " Lots\n";
         caption += "🏷️ <b>Market Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
      }
      else
      {
         // Active running trade or live setup
         string directionEmoji = (StringFind(info.orderType, "BUY") >= 0) ? "🟢" : "🔴";
         string statusText = (info.status == "IN_TRADE") ? "🟢 IN TRADE (RUNNING)" : (info.status == "NEW_SETUP" ? "🚀 LIVE EXECUTION" : "👀 MARKET SETUP");

         caption += "📊 <b>" + info.symbol + " • " + tfStr + " ANALYSIS & SIGNAL</b>\n";
         caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
         caption += "📍 <b>Status:</b> " + statusText + "\n";
         caption += directionEmoji + " <b>Action:</b> <b>" + info.orderType + "</b> @ <code>" + DoubleToString(info.entryPrice, digits) + "</code>\n";

         if(info.volume > 0)
         {
            caption += "📦 <b>Volume:</b> " + DoubleToString(info.volume, 2) + " Lots";
            if(info.posCount > 1)
               caption += " (" + IntegerToString(info.posCount) + " Positions Basket)";
            else if(info.ticket > 0)
               caption += " (Ticket #" + IntegerToString(info.ticket) + ")";
            caption += "\n";
         }

         if(info.status == "IN_TRADE" || info.floatingPnL != 0)
         {
            string pnlPrefix = (info.floatingPnL >= 0) ? "+$" : "-$";
            string pipsPrefix = (info.floatingPips >= 0) ? "+" : "";
            caption += "💰 <b>Floating PnL:</b> " + pnlPrefix + DoubleToString(MathAbs(info.floatingPnL), 2) + " " + ccy + 
                       " (" + pipsPrefix + DoubleToString(info.floatingPips, 1) + " pips)\n";
            caption += "🏷️ <b>Current Price:</b> <code>" + DoubleToString(info.currentPrice, digits) + "</code>\n";
         }
      }

      caption += "─────────────────────────\n";

      // 2. Risk & Target Levels (only for active or pending setups)
      if(info.status == "IN_TRADE" || info.status == "NEW_SETUP" || info.status == "PENDING_SETUP" || info.status == "WATCHLIST")
      {
         if(info.stopLoss > 0)
         {
            caption += "🛡️ <b>Stop Loss:</b> <code>" + DoubleToString(info.stopLoss, digits) + "</code>";
            if(info.slPips > 0)
               caption += " (-" + DoubleToString(info.slPips, 1) + " pips)";
            caption += "\n";
         }

         if(info.takeProfit > 0)
         {
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
      }

      // 3. Market Context
      if(info.spreadPips > 0)
      {
         caption += "📏 <b>Spread:</b> " + DoubleToString(info.spreadPips, 1) + " pips\n";
      }
      caption += "🕒 <b>Time:</b> " + TimeToString(info.signalTime, TIME_DATE|TIME_MINUTES) + "\n";

      // 4. Custom Trader Commentary (With HTML Entity Escaping!)
      if(StringLen(info.customComment) > 0 && 
         info.customComment != "Type trade note / commentary here..." && 
         info.customComment != "Manual Signal Snapshot" &&
         StringFind(info.customComment, "⚠️") < 0)
      {
         caption += "─────────────────────────\n";
         caption += "💬 <b>Trader's Commentary:</b>\n";
         // Strictly escape <, >, & so user commentary never causes Telegram 400 Bad Request
         caption += "<i>\"" + CTelegramClient::EscapeHtml(info.customComment) + "\"</i>\n";
      }

      caption += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";

      // 5. Attribution & Branding
      if(m_isLiteMode)
      {
         caption += "📢 <b>Powered by TeleSnap Pro</b>\n";
         caption += "💎 <b>Help & Inquiries:</b> @telesnap_pro_bot\n";
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
