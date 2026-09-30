//+------------------------------------------------------------------+
//|                                                 TradeMonitor.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Trade Execution, Position Analytics & SL/TP Event Listener       |
//+------------------------------------------------------------------+
class CTradeMonitor
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   ulong             m_magicFilter;

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
   CTradeMonitor() : m_magicFilter(0) {}
   ~CTradeMonitor() {}

   void Init(const string symbol, const ENUM_TIMEFRAMES timeframe, const ulong magicFilter = 0)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_magicFilter = magicFilter;
   }

   //--- Build complete trade analytics from active open position on chart
   bool GetActivePositionSignal(TradeSignalInfo &outSignal)
   {
      if(!PositionSelect(m_symbol))
         return false;

      if(m_magicFilter > 0 && (ulong)PositionGetInteger(POSITION_MAGIC) != m_magicFilter)
         return false;

      double pipSize = GetPipSize(m_symbol);
      ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      bool isBuy = (pType == POSITION_TYPE_BUY);

      outSignal.symbol = m_symbol;
      outSignal.timeframe = m_timeframe;
      outSignal.status = "IN_TRADE";
      outSignal.orderType = isBuy ? "BUY" : "SELL";
      outSignal.ticket = PositionGetInteger(POSITION_TICKET);
      outSignal.volume = PositionGetDouble(POSITION_VOLUME);
      outSignal.closedVolume = 0;
      outSignal.remainingVolume = outSignal.volume;
      outSignal.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      outSignal.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      outSignal.stopLoss = PositionGetDouble(POSITION_SL);
      outSignal.takeProfit = PositionGetDouble(POSITION_TP);
      outSignal.floatingPnL = PositionGetDouble(POSITION_PROFIT);
      outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
      outSignal.signalTime = (datetime)PositionGetInteger(POSITION_TIME);

      // Pips calculation
      if(pipSize > 0)
      {
         outSignal.floatingPips = isBuy ? (outSignal.currentPrice - outSignal.entryPrice) / pipSize
                                        : (outSignal.entryPrice - outSignal.currentPrice) / pipSize;

         if(outSignal.stopLoss > 0)
            outSignal.slPips = MathAbs(outSignal.entryPrice - outSignal.stopLoss) / pipSize;
         else
            outSignal.slPips = 0;

         if(outSignal.takeProfit > 0)
            outSignal.tpPips = MathAbs(outSignal.takeProfit - outSignal.entryPrice) / pipSize;
         else
            outSignal.tpPips = 0;

         if(outSignal.slPips > 0 && outSignal.tpPips > 0)
            outSignal.riskRewardRatio = outSignal.tpPips / outSignal.slPips;
         else
            outSignal.riskRewardRatio = 0;

         if(outSignal.slPips > 0)
         {
            outSignal.tp1Price = outSignal.entryPrice + (isBuy ? 1.0 : -1.0) * (outSignal.slPips * pipSize);
            outSignal.tp2Price = outSignal.entryPrice + (isBuy ? 1.0 : -1.0) * (outSignal.slPips * pipSize * 2.0);
         }
      }

      // Spread
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      long spreadPoints = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      outSignal.spreadPips = (pipSize > 0) ? (spreadPoints * point) / pipSize : 0;

      return true;
   }

   //--- Check for active pending orders (BUY LIMIT, SELL LIMIT, etc.)
   bool GetPendingOrderSignal(TradeSignalInfo &outSignal)
   {
      int totalOrders = OrdersTotal();
      for(int i = 0; i < totalOrders; i++)
      {
         ulong orderTicket = OrderGetTicket(i);
         if(orderTicket > 0)
         {
            if(m_magicFilter > 0 && (ulong)OrderGetInteger(ORDER_MAGIC) != m_magicFilter)
               continue;

            string ordSymbol = OrderGetString(ORDER_SYMBOL);
            if(StringCompare(ordSymbol, m_symbol, false) == 0)
            {
               ENUM_ORDER_TYPE oType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
               string typeStr = "";
               bool isBuy = false;

               switch(oType)
               {
                  case ORDER_TYPE_BUY_LIMIT:  typeStr = "BUY LIMIT";  isBuy = true;  break;
                  case ORDER_TYPE_SELL_LIMIT: typeStr = "SELL LIMIT"; isBuy = false; break;
                  case ORDER_TYPE_BUY_STOP:   typeStr = "BUY STOP";   isBuy = true;  break;
                  case ORDER_TYPE_SELL_STOP:  typeStr = "SELL STOP";  isBuy = false; break;
                  default: continue;
               }

               double pipSize = GetPipSize(m_symbol);
               outSignal.symbol = m_symbol;
               outSignal.timeframe = m_timeframe;
               outSignal.status = "PENDING_SETUP";
               outSignal.orderType = typeStr;
               outSignal.ticket = orderTicket;
               outSignal.volume = OrderGetDouble(ORDER_VOLUME_INITIAL);
               outSignal.entryPrice = OrderGetDouble(ORDER_PRICE_OPEN);
               outSignal.currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
               outSignal.stopLoss = OrderGetDouble(ORDER_SL);
               outSignal.takeProfit = OrderGetDouble(ORDER_TP);
               outSignal.floatingPnL = 0;
               outSignal.floatingPips = 0;
               outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
               outSignal.signalTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);

               if(pipSize > 0)
               {
                  if(outSignal.stopLoss > 0)
                     outSignal.slPips = MathAbs(outSignal.entryPrice - outSignal.stopLoss) / pipSize;
                  if(outSignal.takeProfit > 0)
                     outSignal.tpPips = MathAbs(outSignal.takeProfit - outSignal.entryPrice) / pipSize;
                  if(outSignal.slPips > 0 && outSignal.tpPips > 0)
                     outSignal.riskRewardRatio = outSignal.tpPips / outSignal.slPips;

                  if(outSignal.slPips > 0)
                  {
                     outSignal.tp1Price = outSignal.entryPrice + (isBuy ? 1.0 : -1.0) * (outSignal.slPips * pipSize);
                     outSignal.tp2Price = outSignal.entryPrice + (isBuy ? 1.0 : -1.0) * (outSignal.slPips * pipSize * 2.0);
                  }
               }

               double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
               long spreadPoints = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
               outSignal.spreadPips = (pipSize > 0) ? (spreadPoints * point) / pipSize : 0;
               return true;
            }
         }
      }
      return false;
   }

   //--- Inspect Trade Transaction event (Auto-Snapping on Open, TP, SL, Partials & Manual Close)
   bool ProcessTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest &request,
                           const MqlTradeResult &result,
                           TradeSignalInfo &outSignal,
                           string &outEventReason)
   {
      // 0. Check for Pending Order Cancellation / Expiry
      if(trans.type == TRADE_TRANSACTION_ORDER_DELETE)
      {
         ulong ordTicket = trans.order;
         if(ordTicket > 0 && HistoryOrderSelect(ordTicket))
         {
            if(m_magicFilter > 0 && (ulong)HistoryOrderGetInteger(ordTicket, ORDER_MAGIC) != m_magicFilter)
               return false;

            string ordSymbol = HistoryOrderGetString(ordTicket, ORDER_SYMBOL);
            if(StringCompare(ordSymbol, m_symbol, false) == 0)
            {
               ENUM_ORDER_TYPE oType = (ENUM_ORDER_TYPE)HistoryOrderGetInteger(ordTicket, ORDER_TYPE);
               ENUM_ORDER_STATE oState = (ENUM_ORDER_STATE)HistoryOrderGetInteger(ordTicket, ORDER_STATE);

               if(oType >= ORDER_TYPE_BUY_LIMIT && oType <= ORDER_TYPE_SELL_STOP_LIMIT && 
                 (oState == ORDER_STATE_CANCELED || oState == ORDER_STATE_EXPIRED))
               {
                  string typeStr = (oType == ORDER_TYPE_BUY_LIMIT)  ? "BUY LIMIT"  :
                                   (oType == ORDER_TYPE_SELL_LIMIT) ? "SELL LIMIT" :
                                   (oType == ORDER_TYPE_BUY_STOP)   ? "BUY STOP"   :
                                   (oType == ORDER_TYPE_SELL_STOP)  ? "SELL STOP"  : "PENDING ORDER";

                  outSignal.symbol = m_symbol;
                  outSignal.timeframe = m_timeframe;
                  outSignal.status = "ORDER_CANCELED";
                  outSignal.orderType = (oState == ORDER_STATE_EXPIRED) ? (typeStr + " (EXPIRED)") : (typeStr + " (CANCELED)");
                  outSignal.ticket = ordTicket;
                  outSignal.volume = HistoryOrderGetDouble(ordTicket, ORDER_VOLUME_INITIAL);
                  outSignal.entryPrice = HistoryOrderGetDouble(ordTicket, ORDER_PRICE_OPEN);
                  outSignal.currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
                  outSignal.stopLoss = HistoryOrderGetDouble(ordTicket, ORDER_SL);
                  outSignal.takeProfit = HistoryOrderGetDouble(ordTicket, ORDER_TP);
                  outSignal.floatingPnL = 0;
                  outSignal.floatingPips = 0;
                  outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
                  outSignal.signalTime = TimeCurrent();
                  outSignal.customComment = (oState == ORDER_STATE_EXPIRED) ? 
                                            "⌛ Pending setup expired without triggering." : 
                                            "❌ Setup invalidated: Trader canceled pending order.";

                  outEventReason = "ORDER_CANCELED";
                  return true;
               }
            }
         }
         return false;
      }

      if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
         return false;

      ulong dealTicket = trans.deal;
      if(!HistoryDealSelect(dealTicket))
         return false;

      if(m_magicFilter > 0 && (ulong)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != m_magicFilter)
         return false;

      string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      // Case-insensitive comparison so xauusd matches XAUUSD cleanly
      if(StringCompare(dealSymbol, m_symbol, false) != 0)
         return false;

      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);

      if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
         return false;

      double pipSize = GetPipSize(m_symbol);
      outSignal.symbol = m_symbol;
      outSignal.timeframe = m_timeframe;
      outSignal.ticket = dealTicket;
      outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
      outSignal.signalTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);

      // Spread
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      long spreadPoints = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      outSignal.spreadPips = (pipSize > 0) ? (spreadPoints * point) / pipSize : 0;

      // 1. New Position Opened
      if(dealEntry == DEAL_ENTRY_IN)
      {
         bool isBuy = (dealType == DEAL_TYPE_BUY);
         outSignal.orderType = isBuy ? "BUY" : "SELL";
         outSignal.status = "NEW_SETUP";
         outSignal.entryPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         outSignal.currentPrice = outSignal.entryPrice;
         outSignal.volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         outSignal.closedVolume = 0;
         outSignal.remainingVolume = outSignal.volume;
         
         ulong posId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         if(PositionSelectByTicket(posId))
         {
            outSignal.stopLoss = PositionGetDouble(POSITION_SL);
            outSignal.takeProfit = PositionGetDouble(POSITION_TP);
         }
         else
         {
            outSignal.stopLoss = trans.price_sl;
            outSignal.takeProfit = trans.price_tp;
         }

         if(pipSize > 0)
         {
            if(outSignal.stopLoss > 0)
               outSignal.slPips = MathAbs(outSignal.entryPrice - outSignal.stopLoss) / pipSize;
            if(outSignal.takeProfit > 0)
               outSignal.tpPips = MathAbs(outSignal.takeProfit - outSignal.entryPrice) / pipSize;
            if(outSignal.slPips > 0 && outSignal.tpPips > 0)
               outSignal.riskRewardRatio = outSignal.tpPips / outSignal.slPips;

            if(outSignal.slPips > 0)
            {
               outSignal.tp1Price = outSignal.entryPrice + (isBuy ? 1.0 : -1.0) * (outSignal.slPips * pipSize);
               outSignal.tp2Price = outSignal.entryPrice + (isBuy ? 1.0 : -1.0) * (outSignal.slPips * pipSize * 2.0);
            }
         }

         outSignal.customComment = "🚀 Live Order Execution";
         outEventReason = "TRADE_OPEN";
         return true;
      }

      // 2. Position Closed (Check Partial vs Full, and TP/SL/Manual Reason)
      if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY || dealEntry == DEAL_ENTRY_INOUT)
      {
         ulong posId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
         ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON)HistoryDealGetInteger(dealTicket, DEAL_REASON);
         double closedVol = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         double exitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);

         outSignal.closedVolume = closedVol;
         outSignal.floatingPnL = profit;
         outSignal.currentPrice = exitPrice;

         // Check if position is still open (PARTIAL CLOSE)
         bool isStillOpen = (posId > 0 && PositionSelectByTicket(posId));
         double remainingVol = isStillOpen ? PositionGetDouble(POSITION_VOLUME) : 0.0;
         outSignal.remainingVolume = remainingVol;

         // Inspect position history to extract original entry price and SL/TP
         double openPrice = 0.0;
         double origSl = 0.0;
         double origTp = 0.0;
         bool posWasBuy = (dealType == DEAL_TYPE_SELL); // Closing a BUY deal creates a SELL deal

         if(posId > 0 && HistorySelectByPosition(posId))
         {
            int dealsTotal = HistoryDealsTotal();
            for(int d = 0; d < dealsTotal; d++)
            {
               ulong dTicket = HistoryDealGetTicket(d);
               if(HistoryDealGetInteger(dTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
               {
                  openPrice = HistoryDealGetDouble(dTicket, DEAL_PRICE);
                  ENUM_DEAL_TYPE inDealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dTicket, DEAL_TYPE);
                  posWasBuy = (inDealType == DEAL_TYPE_BUY);
                  break;
               }
            }

            int ordersTotal = HistoryOrdersTotal();
            for(int o = 0; o < ordersTotal; o++)
            {
               ulong oTicket = HistoryOrderGetTicket(o);
               if(HistoryOrderGetInteger(oTicket, ORDER_TYPE) == (posWasBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL))
               {
                  origSl = HistoryOrderGetDouble(oTicket, ORDER_SL);
                  origTp = HistoryOrderGetDouble(oTicket, ORDER_TP);
                  if(origSl > 0 || origTp > 0)
                     break;
               }
            }

            // Restore selection of the current deal
            HistoryDealSelect(dealTicket);
         }

         outSignal.entryPrice = (openPrice > 0) ? openPrice : exitPrice;
         outSignal.stopLoss = origSl;
         outSignal.takeProfit = origTp;

         double pipsDiff = 0.0;
         if(pipSize > 0 && openPrice > 0)
         {
            pipsDiff = posWasBuy ? (exitPrice - openPrice) / pipSize : (openPrice - exitPrice) / pipSize;
         }
         outSignal.floatingPips = pipsDiff;

         // A. PARTIAL CLOSE
         if(isStillOpen && remainingVol > 0.0001)
         {
            outSignal.status = "PARTIAL_CLOSE";
            outSignal.orderType = posWasBuy ? "BUY (PARTIAL)" : "SELL (PARTIAL)";
            string pipsText = (pipsDiff != 0) ? (" (" + (pipsDiff > 0 ? "+" : "") + DoubleToString(pipsDiff, 1) + " pips)") : "";
            string profitText = (profit >= 0) ? ("+$" + DoubleToString(profit, 2)) : ("-$" + DoubleToString(MathAbs(profit), 2));
            outSignal.customComment = "✂️ Partial Profit Secured! " + DoubleToString(closedVol, 2) + " Lots Closed [" + profitText + pipsText + "], " + 
                                      DoubleToString(remainingVol, 2) + " Lots Still Running.";
            outEventReason = "PARTIAL_PROFIT";
            return true;
         }

         // B. FULL CLOSE: Check TP, SL, or Manual
         bool isTp = (dealReason == DEAL_REASON_TP || 
                      StringFind(dealComment, "tp") >= 0 || 
                      StringFind(dealComment, "TP") >= 0 || 
                      StringFind(dealComment, "Take Profit") >= 0 ||
                      (origTp > 0 && MathAbs(exitPrice - origTp) <= 10.0 * point));

         bool isSl = (dealReason == DEAL_REASON_SL || 
                      dealReason == DEAL_REASON_SO ||
                      StringFind(dealComment, "sl") >= 0 || 
                      StringFind(dealComment, "SL") >= 0 || 
                      StringFind(dealComment, "Stop Loss") >= 0 ||
                      (origSl > 0 && MathAbs(exitPrice - origSl) <= 10.0 * point));

         if(isTp)
         {
            outSignal.orderType = posWasBuy ? "BUY (TP HIT)" : "SELL (TP HIT)";
            outSignal.status = "TAKE_PROFIT";
            outSignal.tpPips = MathAbs(pipsDiff);
            string profitText = (profit >= 0) ? ("+$" + DoubleToString(profit, 2)) : ("-$" + DoubleToString(MathAbs(profit), 2));
            outSignal.customComment = "🎯 Target Fully Reached! Realized Profit: " + profitText + " " + outSignal.currency + " (+" + DoubleToString(outSignal.tpPips, 1) + " pips)";
            outEventReason = "TAKE_PROFIT";
            return true;
         }
         else if(isSl)
         {
            outSignal.orderType = posWasBuy ? "BUY (SL HIT)" : "SELL (SL HIT)";
            outSignal.status = "STOP_LOSS";
            outSignal.slPips = MathAbs(pipsDiff);
            string lossText = "-$" + DoubleToString(MathAbs(profit), 2);
            outSignal.customComment = "🛑 Stop Loss Hit: Realized PnL " + lossText + " " + outSignal.currency + " (-" + DoubleToString(outSignal.slPips, 1) + " pips)";
            outEventReason = "STOP_LOSS";
            return true;
         }
         else
         {
            // C. MANUAL CLOSE / EARLY CASHOUT
            if(profit > 0.5)
            {
               outSignal.orderType = posWasBuy ? "BUY (MANUAL CASHOUT)" : "SELL (MANUAL CASHOUT)";
               outSignal.status = "MANUAL_PROFIT";
               outSignal.customComment = "💰 Trader manually secured early profit: +$" + DoubleToString(profit, 2) + " " + outSignal.currency + 
                                         (pipsDiff > 0 ? (" (+" + DoubleToString(pipsDiff, 1) + " pips)") : "");
               outEventReason = "MANUAL_PROFIT";
               return true;
            }
            else if(profit < -0.5)
            {
               outSignal.orderType = posWasBuy ? "BUY (MANUAL CUT)" : "SELL (MANUAL CUT)";
               outSignal.status = "MANUAL_LOSS";
               outSignal.customComment = "⚠️ Trader manually closed early to minimize loss: -$" + DoubleToString(MathAbs(profit), 2) + " " + outSignal.currency +
                                         (pipsDiff < 0 ? (" (-" + DoubleToString(MathAbs(pipsDiff), 1) + " pips)") : "");
               outEventReason = "MANUAL_LOSS";
               return true;
            }
            else
            {
               outSignal.orderType = posWasBuy ? "BUY (BREAKEVEN)" : "SELL (BREAKEVEN)";
               outSignal.status = "BREAKEVEN";
               outSignal.customComment = "⚖️ Position closed at breakeven ($0.00 Risk).";
               outEventReason = "BREAKEVEN";
               return true;
            }
         }
      }

      return false;
   }
};
