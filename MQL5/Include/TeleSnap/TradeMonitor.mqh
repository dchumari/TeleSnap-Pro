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
   CTradeMonitor() {}
   ~CTradeMonitor() {}

   void Init(const string symbol, const ENUM_TIMEFRAMES timeframe)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
   }

   //--- Build complete trade analytics from active open position on chart
   bool GetActivePositionSignal(TradeSignalInfo &outSignal)
   {
      if(!PositionSelect(m_symbol))
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
      outSignal.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      outSignal.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      outSignal.stopLoss = PositionGetDouble(POSITION_SL);
      outSignal.takeProfit = PositionGetDouble(POSITION_TP);
      outSignal.floatingPnL = PositionGetDouble(POSITION_PROFIT);
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

         // Risk to Reward ratio
         if(outSignal.slPips > 0 && outSignal.tpPips > 0)
            outSignal.riskRewardRatio = outSignal.tpPips / outSignal.slPips;
         else
            outSignal.riskRewardRatio = 0;

         // Calculate 1:1 and 1:2 TP milestones
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

   //--- Inspect Trade Transaction event (Auto-Snapping)
   bool ProcessTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest &request,
                           const MqlTradeResult &result,
                           TradeSignalInfo &outSignal,
                           string &outEventReason)
   {
      if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
         return false;

      ulong dealTicket = trans.deal;
      if(!HistoryDealSelect(dealTicket))
         return false;

      string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      if(dealSymbol != m_symbol)
         return false;

      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);

      if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
         return false;

      double pipSize = GetPipSize(m_symbol);
      outSignal.symbol = m_symbol;
      outSignal.timeframe = m_timeframe;
      outSignal.entryPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      outSignal.currentPrice = outSignal.entryPrice;
      outSignal.volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      outSignal.ticket = dealTicket;
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

         outSignal.customComment = "🚀 Automated Trade Execution Entry";
         outEventReason = "TRADE_OPEN";
         return true;
      }

      // 2. Position Closed (Check SL / TP hit)
      if(dealEntry == DEAL_ENTRY_OUT)
      {
         string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         outSignal.floatingPnL = profit;

         if(StringFind(dealComment, "sl") >= 0 || StringFind(dealComment, "Stop Loss") >= 0)
         {
            outSignal.orderType = "STOP LOSS";
            outSignal.status = "STOP_LOSS";
            outSignal.customComment = "🛑 Stop Loss Hit: PnL -$" + DoubleToString(MathAbs(profit), 2);
            outEventReason = "STOP_LOSS";
            return true;
         }
         else if(StringFind(dealComment, "tp") >= 0 || StringFind(dealComment, "Take Profit") >= 0 || profit > 0)
         {
            outSignal.orderType = "TAKE PROFIT";
            outSignal.status = "TAKE_PROFIT";
            outSignal.customComment = "🎯 Target Reached! Profit: +$" + DoubleToString(profit, 2);
            outEventReason = "TAKE_PROFIT";
            return true;
         }
         else
         {
            outSignal.orderType = "MANUAL CLOSE";
            outSignal.status = "IN_TRADE";
            outSignal.customComment = "ℹ️ Position Closed: PnL $" + DoubleToString(profit, 2);
            outEventReason = "MANUAL_CLOSE";
            return true;
         }
      }

      return false;
   }
};
