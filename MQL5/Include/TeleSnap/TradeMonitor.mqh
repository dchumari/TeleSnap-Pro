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
//| Trade Execution & SL/TP Event Listener                           |
//+------------------------------------------------------------------+
class CTradeMonitor
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

public:
   CTradeMonitor() {}
   ~CTradeMonitor() {}

   void Init(const string symbol, const ENUM_TIMEFRAMES timeframe)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
   }

   //--- Inspect Trade Transaction event
   bool ProcessTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest &request,
                           const MqlTradeResult &result,
                           TradeSignalInfo &outSignal,
                           string &outEventReason)
   {
      // Only process completed deal additions
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

      // Only handle Buy and Sell deals
      if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
         return false;

      outSignal.symbol = m_symbol;
      outSignal.timeframe = m_timeframe;
      outSignal.entryPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      outSignal.ticket = dealTicket;
      outSignal.signalTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);

      // 1. New Position Opened
      if(dealEntry == DEAL_ENTRY_IN)
      {
         outSignal.orderType = (dealType == DEAL_TYPE_BUY) ? "BUY" : "SELL";
         
         // Fetch SL/TP from the newly active position
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

         outSignal.customComment = "🚀 Automated Trade Execution Entry";
         outEventReason = "TRADE_OPEN";
         return true;
      }

      // 2. Position Closed (Check if SL or TP hit)
      if(dealEntry == DEAL_ENTRY_OUT)
      {
         string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);

         outSignal.orderType = (dealType == DEAL_TYPE_BUY) ? "SELL_CLOSE" : "BUY_CLOSE";
         outSignal.stopLoss = 0;
         outSignal.takeProfit = 0;

         if(StringFind(dealComment, "sl") >= 0 || StringFind(dealComment, "Stop Loss") >= 0)
         {
            outSignal.customComment = "🛑 Stop Loss Hit: Closed at " + DoubleToString(outSignal.entryPrice, _Digits);
            outEventReason = "STOP_LOSS";
            return true;
         }
         else if(StringFind(dealComment, "tp") >= 0 || StringFind(dealComment, "Take Profit") >= 0 || profit > 0)
         {
            outSignal.customComment = "🎯 Take Profit Hit! Profit: $" + DoubleToString(profit, 2);
            outEventReason = "TAKE_PROFIT";
            return true;
         }
         else
         {
            outSignal.customComment = "ℹ️ Manual Position Close: PnL $" + DoubleToString(profit, 2);
            outEventReason = "MANUAL_CLOSE";
            return true;
         }
      }

      return false;
   }
};
