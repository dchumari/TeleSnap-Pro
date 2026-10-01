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
//| Stop Loss Tracking Cache Entry                                   |
//+------------------------------------------------------------------+
struct SlTrackingEntry
{
   ulong    posTicket;
   double   lastSl;
   datetime lastAlertTime;
};

//+------------------------------------------------------------------+
//| Profit Milestone Tracking Cache Entry                            |
//+------------------------------------------------------------------+
struct MilestoneTrackingEntry
{
   ulong    posTicket;
   int      lastMilestonePips;
   datetime lastAlertTime;
};

//+------------------------------------------------------------------+
//| Trade Execution, Position Analytics & SL/TP Event Listener       |
//+------------------------------------------------------------------+
class CTradeMonitor
{
private:
   string                 m_symbol;
   ENUM_TIMEFRAMES        m_timeframe;
   ulong                  m_magicFilter;
   bool                   m_allSymbols;
   SlTrackingEntry        m_slCache[];
   MilestoneTrackingEntry m_milestoneCache[];

   //--- Calculate pip size for symbol
   double GetPipSize(const string symbol)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      if(digits == 3 || digits == 5)
         return point * 10.0;
      return point;
   }

   //--- Remove position from SL cache when closed
   void CleanSlCache(const ulong posId)
   {
      for(int i = 0; i < ArraySize(m_slCache); i++)
      {
         if(m_slCache[i].posTicket == posId)
         {
            for(int j = i; j < ArraySize(m_slCache) - 1; j++)
               m_slCache[j] = m_slCache[j + 1];
            ArrayResize(m_slCache, ArraySize(m_slCache) - 1);
            break;
         }
      }
   }

   //--- Remove position from Milestone cache when closed
   void CleanMilestoneCache(const ulong posId)
   {
      for(int i = 0; i < ArraySize(m_milestoneCache); i++)
      {
         if(m_milestoneCache[i].posTicket == posId)
         {
            for(int j = i; j < ArraySize(m_milestoneCache) - 1; j++)
               m_milestoneCache[j] = m_milestoneCache[j + 1];
            ArrayResize(m_milestoneCache, ArraySize(m_milestoneCache) - 1);
            break;
         }
      }
   }

public:
   CTradeMonitor() : m_magicFilter(0), m_allSymbols(false)
   {
      ArrayResize(m_slCache, 0);
      ArrayResize(m_milestoneCache, 0);
   }

   ~CTradeMonitor() {}

   void Init(const string symbol, const ENUM_TIMEFRAMES timeframe, const ulong magicFilter = 0, const bool allSymbols = false)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_magicFilter = magicFilter;
      m_allSymbols = allSymbols;
      ArrayResize(m_slCache, 0);
   }

   //--- Build complete trade analytics from active open position on chart (aggregates basket if multiple positions)
   bool GetActivePositionSignal(TradeSignalInfo &outSignal)
   {
      int posCount = 0;
      double totalVol = 0.0;
      double netProfit = 0.0;
      double totalWeightedPrice = 0.0;
      ulong firstTicket = 0;
      ENUM_POSITION_TYPE pType = POSITION_TYPE_BUY;
      datetime earliestTime = 0;
      double sl = 0.0, tp = 0.0;

      int totalPos = PositionsTotal();
      for(int i = 0; i < totalPos; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == m_symbol)
         {
            if(m_magicFilter > 0 && (ulong)PositionGetInteger(POSITION_MAGIC) != m_magicFilter)
               continue;

            posCount++;
            double vol = PositionGetDouble(POSITION_VOLUME);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            datetime pTime = (datetime)PositionGetInteger(POSITION_TIME);

            totalVol += vol;
            netProfit += profit;
            totalWeightedPrice += (openPrice * vol);

            if(posCount == 1)
            {
               firstTicket = ticket;
               pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               earliestTime = pTime;
               sl = PositionGetDouble(POSITION_SL);
               tp = PositionGetDouble(POSITION_TP);
            }
            else
            {
               if(pTime < earliestTime) earliestTime = pTime;
            }
         }
      }

      if(posCount == 0)
         return false;

      double pipSize = GetPipSize(m_symbol);
      bool isBuy = (pType == POSITION_TYPE_BUY);

      outSignal.symbol = m_symbol;
      outSignal.timeframe = m_timeframe;
      outSignal.status = "IN_TRADE";
      outSignal.orderType = isBuy ? "BUY" : "SELL";
      outSignal.ticket = firstTicket;
      outSignal.volume = totalVol;
      outSignal.closedVolume = 0;
      outSignal.remainingVolume = totalVol;
      outSignal.entryPrice = (totalVol > 0) ? (totalWeightedPrice / totalVol) : PositionGetDouble(POSITION_PRICE_OPEN);
      outSignal.currentPrice = SymbolInfoDouble(m_symbol, isBuy ? SYMBOL_BID : SYMBOL_ASK);
      outSignal.stopLoss = sl;
      outSignal.takeProfit = tp;
      outSignal.floatingPnL = netProfit;
      outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
      outSignal.signalTime = (earliestTime > 0) ? earliestTime : TimeCurrent();
      outSignal.posCount = posCount;

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

      if(posCount > 1)
      {
         outSignal.customComment = "🧺 Multi-Position Basket: " + IntegerToString(posCount) + " Positions | Combined Vol: " + DoubleToString(totalVol, 2) + " Lots";
      }

      return true;
   }

   bool GetActivePositionSignal(const string symbol, const ENUM_TIMEFRAMES tf, TradeSignalInfo &outSignal)
   {
      string prevSym = m_symbol;
      ENUM_TIMEFRAMES prevTf = m_timeframe;
      m_symbol = symbol;
      m_timeframe = tf;
      bool res = GetActivePositionSignal(outSignal);
      m_symbol = prevSym;
      m_timeframe = prevTf;
      return res;
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

   bool GetPendingOrderSignal(const string symbol, const ENUM_TIMEFRAMES tf, TradeSignalInfo &outSignal)
   {
      string prevSym = m_symbol;
      ENUM_TIMEFRAMES prevTf = m_timeframe;
      m_symbol = symbol;
      m_timeframe = tf;
      bool res = GetPendingOrderSignal(outSignal);
      m_symbol = prevSym;
      m_timeframe = prevTf;
      return res;
   }

   //--- Inspect Trade Transaction event (Auto-Snapping on Open, Pending Orders, TP, SL, Partials & Manual Close)
   bool ProcessTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest &request,
                           const MqlTradeResult &result,
                           TradeSignalInfo &outSignal,
                           string &outEventReason)
   {
      // 1. Pending Order Placed
      if(trans.type == TRADE_TRANSACTION_ORDER_ADD)
      {
         if(trans.order_type >= ORDER_TYPE_BUY_LIMIT && trans.order_type <= ORDER_TYPE_SELL_STOP_LIMIT)
         {
            ulong ordTicket = trans.order;
            string ordSymbol = trans.symbol;
            double ordPrice = trans.price;
            double ordVol = trans.volume;
            double ordSl = trans.price_sl;
            double ordTp = trans.price_tp;

            if(ordTicket > 0 && OrderSelect(ordTicket))
            {
               if(m_magicFilter > 0 && (ulong)OrderGetInteger(ORDER_MAGIC) != m_magicFilter)
                  return false;

               ordSymbol = OrderGetString(ORDER_SYMBOL);
               ordPrice = OrderGetDouble(ORDER_PRICE_OPEN);
               ordVol = OrderGetDouble(ORDER_VOLUME_INITIAL);
               ordSl = OrderGetDouble(ORDER_SL);
               ordTp = OrderGetDouble(ORDER_TP);
            }

            if(StringLen(ordSymbol) == 0) ordSymbol = m_symbol;
            if(!m_allSymbols && StringCompare(ordSymbol, m_symbol, false) != 0)
               return false;

            string typeStr = (trans.order_type == ORDER_TYPE_BUY_LIMIT)  ? "BUY LIMIT"  :
                             (trans.order_type == ORDER_TYPE_SELL_LIMIT) ? "SELL LIMIT" :
                             (trans.order_type == ORDER_TYPE_BUY_STOP)   ? "BUY STOP"   :
                             (trans.order_type == ORDER_TYPE_SELL_STOP)  ? "SELL STOP"  : "PENDING ORDER";

            bool isBuy = (trans.order_type == ORDER_TYPE_BUY_LIMIT || trans.order_type == ORDER_TYPE_BUY_STOP);
            double pipSize = GetPipSize(ordSymbol);

            outSignal.symbol = ordSymbol;
            outSignal.timeframe = m_timeframe;
            outSignal.status = "PENDING_SETUP";
            outSignal.orderType = typeStr;
            outSignal.ticket = ordTicket;
            outSignal.volume = ordVol;
            outSignal.entryPrice = ordPrice;
            outSignal.currentPrice = SymbolInfoDouble(ordSymbol, isBuy ? SYMBOL_ASK : SYMBOL_BID);
            outSignal.stopLoss = ordSl;
            outSignal.takeProfit = ordTp;
            outSignal.floatingPnL = 0;
            outSignal.floatingPips = 0;
            outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
            outSignal.signalTime = TimeCurrent();

            if(pipSize > 0)
            {
               if(outSignal.stopLoss > 0)
                  outSignal.slPips = MathAbs(outSignal.entryPrice - outSignal.stopLoss) / pipSize;
               if(outSignal.takeProfit > 0)
                  outSignal.tpPips = MathAbs(outSignal.takeProfit - outSignal.entryPrice) / pipSize;
               if(outSignal.slPips > 0 && outSignal.tpPips > 0)
                  outSignal.riskRewardRatio = outSignal.tpPips / outSignal.slPips;
            }

            double point = SymbolInfoDouble(ordSymbol, SYMBOL_POINT);
            long spreadPoints = SymbolInfoInteger(ordSymbol, SYMBOL_SPREAD);
            outSignal.spreadPips = (pipSize > 0) ? (spreadPoints * point) / pipSize : 0;
            outSignal.customComment = "⏳ New Pending Order Placed";
            outEventReason = "ORDER_PLACED";
            return true;
         }
      }

      // 2. Pending Order Canceled or Expired
      if(trans.type == TRADE_TRANSACTION_ORDER_DELETE)
      {
         if(trans.order_type >= ORDER_TYPE_BUY_LIMIT && trans.order_type <= ORDER_TYPE_SELL_STOP_LIMIT)
         {
            // If filled, the DEAL_ADD transaction handles the actual position open!
            if(trans.order_state == ORDER_STATE_FILLED || trans.order_state == ORDER_STATE_PARTIAL)
               return false;

            ulong ordTicket = trans.order;
            string ordSymbol = trans.symbol;
            double ordPrice = trans.price;
            double ordVol = trans.volume;
            double ordSl = trans.price_sl;
            double ordTp = trans.price_tp;

            HistorySelect(TimeCurrent() - 86400, TimeCurrent() + 60);
            if(ordTicket > 0 && HistoryOrderSelect(ordTicket))
            {
               if(m_magicFilter > 0 && (ulong)HistoryOrderGetInteger(ordTicket, ORDER_MAGIC) != m_magicFilter)
                  return false;

               ordSymbol = HistoryOrderGetString(ordTicket, ORDER_SYMBOL);
               ordPrice = HistoryOrderGetDouble(ordTicket, ORDER_PRICE_OPEN);
               ordVol = HistoryOrderGetDouble(ordTicket, ORDER_VOLUME_INITIAL);
               ordSl = HistoryOrderGetDouble(ordTicket, ORDER_SL);
               ordTp = HistoryOrderGetDouble(ordTicket, ORDER_TP);
               ENUM_ORDER_STATE hState = (ENUM_ORDER_STATE)HistoryOrderGetInteger(ordTicket, ORDER_STATE);
               if(hState == ORDER_STATE_FILLED)
                  return false;
            }

            if(StringLen(ordSymbol) == 0) ordSymbol = m_symbol;
            if(!m_allSymbols && StringCompare(ordSymbol, m_symbol, false) != 0)
               return false;

            bool isExpired = (trans.order_state == ORDER_STATE_EXPIRED);
            string typeStr = (trans.order_type == ORDER_TYPE_BUY_LIMIT)  ? "BUY LIMIT"  :
                             (trans.order_type == ORDER_TYPE_SELL_LIMIT) ? "SELL LIMIT" :
                             (trans.order_type == ORDER_TYPE_BUY_STOP)   ? "BUY STOP"   :
                             (trans.order_type == ORDER_TYPE_SELL_STOP)  ? "SELL STOP"  : "PENDING ORDER";

            outSignal.symbol = ordSymbol;
            outSignal.timeframe = m_timeframe;
            outSignal.status = "ORDER_CANCELED";
            outSignal.orderType = isExpired ? (typeStr + " (EXPIRED)") : (typeStr + " (CANCELED)");
            outSignal.ticket = ordTicket;
            outSignal.volume = ordVol;
            outSignal.entryPrice = ordPrice;
            outSignal.currentPrice = SymbolInfoDouble(ordSymbol, SYMBOL_BID);
            outSignal.stopLoss = ordSl;
            outSignal.takeProfit = ordTp;
            outSignal.floatingPnL = 0;
            outSignal.floatingPips = 0;
            outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
            outSignal.signalTime = TimeCurrent();
            outSignal.customComment = isExpired ? "⌛ Pending setup expired without triggering." : 
                                                  "❌ Setup invalidated: Trader canceled pending order.";

            outEventReason = isExpired ? "ORDER_EXPIRED" : "ORDER_CANCELED";
            return true;
         }
         return false;
      }

      // 3. Position Modification (Stop Loss moved to Breakeven or Trailed into Profit)
      if(trans.type == TRADE_TRANSACTION_POSITION)
      {
         ulong posTicket = trans.position;
         if(posTicket > 0 && PositionSelectByTicket(posTicket))
         {
            if(m_magicFilter > 0 && (ulong)PositionGetInteger(POSITION_MAGIC) != m_magicFilter)
               return false;

            string posSymbol = PositionGetString(POSITION_SYMBOL);
            if(StringLen(posSymbol) == 0) posSymbol = trans.symbol;
            if(!m_allSymbols && StringCompare(posSymbol, m_symbol, false) != 0)
               return false;

            double newSl = trans.price_sl;
            if(newSl <= 0)
               return false; // Removing SL or no SL set

            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            bool isBuy = (pType == POSITION_TYPE_BUY);
            double pipSize = GetPipSize(posSymbol);
            if(pipSize <= 0) return false;

            // Check SL cache to avoid duplicate spam for the same SL modification
            int cacheIdx = -1;
            for(int k = 0; k < ArraySize(m_slCache); k++)
            {
               if(m_slCache[k].posTicket == posTicket)
               {
                  cacheIdx = k;
                  break;
               }
            }

            if(cacheIdx >= 0)
            {
               // If SL hasn't changed significantly or modified within last 3 seconds, ignore
               if(MathAbs(m_slCache[cacheIdx].lastSl - newSl) < (0.5 * pipSize) || 
                  (TimeCurrent() - m_slCache[cacheIdx].lastAlertTime < 3))
               {
                  return false;
               }
            }
            else
            {
               cacheIdx = ArraySize(m_slCache);
               ArrayResize(m_slCache, cacheIdx + 1);
               m_slCache[cacheIdx].posTicket = posTicket;
            }

            double slDiffPips = isBuy ? (newSl - openPrice) / pipSize : (openPrice - newSl) / pipSize;

            // Only alert if SL is moved to Breakeven (flat/slight profit) or Trailed into profit!
            // If moved to deeper loss (slDiffPips < -0.5), update cache and do not alert
            if(slDiffPips < -0.5)
            {
               m_slCache[cacheIdx].lastSl = newSl;
               m_slCache[cacheIdx].lastAlertTime = TimeCurrent();
               return false;
            }

            outSignal.symbol = posSymbol;
            outSignal.timeframe = m_timeframe;
            outSignal.ticket = posTicket;
            outSignal.volume = PositionGetDouble(POSITION_VOLUME);
            outSignal.closedVolume = 0;
            outSignal.remainingVolume = outSignal.volume;
            outSignal.entryPrice = openPrice;
            outSignal.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            outSignal.stopLoss = newSl;
            outSignal.takeProfit = PositionGetDouble(POSITION_TP);
            outSignal.floatingPnL = PositionGetDouble(POSITION_PROFIT);
            outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
            outSignal.signalTime = TimeCurrent();

            double point = SymbolInfoDouble(posSymbol, SYMBOL_POINT);
            long spreadPts = SymbolInfoInteger(posSymbol, SYMBOL_SPREAD);
            outSignal.spreadPips = (pipSize > 0) ? (spreadPts * point) / pipSize : 0;
            outSignal.floatingPips = isBuy ? (outSignal.currentPrice - openPrice) / pipSize : (openPrice - outSignal.currentPrice) / pipSize;

            if(slDiffPips >= -0.5 && slDiffPips <= 2.5)
            {
               outSignal.status = "SL_BREAKEVEN";
               outSignal.orderType = isBuy ? "BUY (SL ➔ BREAKEVEN)" : "SELL (SL ➔ BREAKEVEN)";
               outSignal.customComment = "🛡️ Stop Loss moved to Breakeven! Trade is now 100% Risk-Free ($0.00 Risk).";
               outEventReason = "SL_BREAKEVEN";
            }
            else
            {
               outSignal.status = "SL_TRAILED";
               outSignal.orderType = isBuy ? "BUY (SL TRAILED)" : "SELL (SL TRAILED)";
               outSignal.customComment = "📈 Stop Loss Trailed! Secured +" + DoubleToString(slDiffPips, 1) + " pips in guaranteed profit.";
               outEventReason = "SL_TRAILED";
            }

            m_slCache[cacheIdx].lastSl = newSl;
            m_slCache[cacheIdx].lastAlertTime = TimeCurrent();
            return true;
         }
         return false;
      }

      // 4. Trade Deal Added (Position Open, Close, Partial, TP, SL, Breakeven, Manual Close)
      if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
         return false;

      ulong dealTicket = trans.deal;
      if(!HistoryDealSelect(dealTicket))
         return false;

      if(m_magicFilter > 0 && (ulong)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != m_magicFilter)
         return false;

      string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      if(!m_allSymbols && StringCompare(dealSymbol, m_symbol, false) != 0)
         return false;

      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);

      if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
         return false;

      double pipSize = GetPipSize(dealSymbol);
      outSignal.symbol = dealSymbol;
      outSignal.timeframe = m_timeframe;
      outSignal.ticket = dealTicket;
      outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
      outSignal.signalTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);

      // Spread
      double point = SymbolInfoDouble(dealSymbol, SYMBOL_POINT);
      long spreadPoints = SymbolInfoInteger(dealSymbol, SYMBOL_SPREAD);
      outSignal.spreadPips = (pipSize > 0) ? (spreadPoints * point) / pipSize : 0;

      // 3A. New Position Opened
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

      // 3B. Position Closed (Check Partial vs Full, and TP/SL/Manual/Breakeven)
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

         if(!isStillOpen && posId > 0)
         {
            CleanSlCache(posId);
            CleanMilestoneCache(posId);
         }

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

            // Restore selection of current deal
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

         // I. PARTIAL CLOSE
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

         // II. FULL CLOSE: Check TP, SL, or Manual
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
            // III. MANUAL CLOSE / EARLY CASHOUT
            // Accurate classification for any lot size (0.01 micro-lots to 100.0 standard lots)
            if(profit > 0.05 && pipsDiff > 0.5)
            {
               outSignal.orderType = posWasBuy ? "BUY (MANUAL CASHOUT)" : "SELL (MANUAL CASHOUT)";
               outSignal.status = "MANUAL_PROFIT";
               outSignal.customComment = "💰 Trader manually secured early profit: +$" + DoubleToString(profit, 2) + " " + outSignal.currency + 
                                         (pipsDiff > 0 ? (" (+" + DoubleToString(pipsDiff, 1) + " pips)") : "");
               outEventReason = "MANUAL_PROFIT";
               return true;
            }
            else if(profit < -0.05 && pipsDiff < -0.5)
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
               // Truly flat close (within +/- 0.5 pips of entry)
               outSignal.orderType = posWasBuy ? "BUY (BREAKEVEN)" : "SELL (BREAKEVEN)";
               outSignal.status = "BREAKEVEN";
               string pnlStr = (profit >= 0) ? ("+$" + DoubleToString(profit, 2)) : ("-$" + DoubleToString(MathAbs(profit), 2));
               outSignal.customComment = "⚖️ Position closed flat near breakeven (" + pnlStr + " " + outSignal.currency + ").";
               outEventReason = "BREAKEVEN";
               return true;
            }
         }
      }

      return false;
   }

   //--- Check for Floating Profit Milestones (e.g. +50, +100, +150, +200 pips)
   bool CheckProfitMilestones(const int stepPips, TradeSignalInfo &outSignal, string &outEventReason)
   {
      if(stepPips <= 0) return false;

      int totalPos = PositionsTotal();
      for(int i = 0; i < totalPos; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;

         string posSymbol = PositionGetString(POSITION_SYMBOL);
         if(!m_allSymbols && StringCompare(posSymbol, m_symbol, false) != 0)
            continue;

         if(m_magicFilter > 0 && (ulong)PositionGetInteger(POSITION_MAGIC) != m_magicFilter)
            continue;

         ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double pipSize = GetPipSize(posSymbol);
         if(pipSize <= 0) continue;

         bool isBuy = (pType == POSITION_TYPE_BUY);
         double curPrice = SymbolInfoDouble(posSymbol, isBuy ? SYMBOL_BID : SYMBOL_ASK);
         double floatingPips = isBuy ? (curPrice - openPrice) / pipSize : (openPrice - curPrice) / pipSize;

         if(floatingPips < (double)stepPips) continue;

         int currentMilestone = (int)(floatingPips / stepPips) * stepPips;
         if(currentMilestone < stepPips) continue;

         // Find in cache
         int cacheIdx = -1;
         for(int c = 0; c < ArraySize(m_milestoneCache); c++)
         {
            if(m_milestoneCache[c].posTicket == ticket)
            {
               cacheIdx = c;
               break;
            }
         }

         if(cacheIdx < 0)
         {
            int sz = ArraySize(m_milestoneCache);
            ArrayResize(m_milestoneCache, sz + 1);
            m_milestoneCache[sz].posTicket = ticket;
            m_milestoneCache[sz].lastMilestonePips = 0;
            m_milestoneCache[sz].lastAlertTime = 0;
            cacheIdx = sz;
         }

         // Only trigger if this milestone level has NOT yet been alerted for this ticket
         if(currentMilestone > m_milestoneCache[cacheIdx].lastMilestonePips)
         {
            if(TimeCurrent() - m_milestoneCache[cacheIdx].lastAlertTime < 30)
               continue;

            outSignal.symbol = posSymbol;
            outSignal.timeframe = m_timeframe;
            outSignal.status = "PROFIT_MILESTONE";
            outSignal.orderType = isBuy ? "BUY (MILESTONE)" : "SELL (MILESTONE)";
            outSignal.ticket = ticket;
            outSignal.volume = PositionGetDouble(POSITION_VOLUME);
            outSignal.closedVolume = 0;
            outSignal.remainingVolume = outSignal.volume;
            outSignal.entryPrice = openPrice;
            outSignal.currentPrice = curPrice;
            outSignal.stopLoss = PositionGetDouble(POSITION_SL);
            outSignal.takeProfit = PositionGetDouble(POSITION_TP);
            outSignal.floatingPnL = PositionGetDouble(POSITION_PROFIT);
            outSignal.floatingPips = floatingPips;
            outSignal.currency = AccountInfoString(ACCOUNT_CURRENCY);
            outSignal.signalTime = TimeCurrent();
            outSignal.posCount = 1;

            double point = SymbolInfoDouble(posSymbol, SYMBOL_POINT);
            long spreadPts = SymbolInfoInteger(posSymbol, SYMBOL_SPREAD);
            outSignal.spreadPips = (pipSize > 0) ? (spreadPts * point) / pipSize : 0;

            string pnlText = (outSignal.floatingPnL >= 0) ? ("+$" + DoubleToString(outSignal.floatingPnL, 2)) : ("-$" + DoubleToString(MathAbs(outSignal.floatingPnL), 2));
            outSignal.customComment = "🎯 Profit Milestone Reached! Trade secured +" + IntegerToString(currentMilestone) + 
                                      " Pips (" + pnlText + " " + outSignal.currency + ")!";
            outEventReason = "PROFIT_MILESTONE";

            m_milestoneCache[cacheIdx].lastMilestonePips = currentMilestone;
            m_milestoneCache[cacheIdx].lastAlertTime = TimeCurrent();
            return true;
         }
      }

      return false;
   }

   //--- Generate Performance Recap for a time window (e.g. Daily / Weekly)
   bool GeneratePerformanceRecap(const datetime startTime, const datetime endTime, DailyPerformanceSummary &outSummary)
   {
      ZeroMemory(outSummary);
      outSummary.date = startTime;
      outSummary.currency = AccountInfoString(ACCOUNT_CURRENCY);

      if(!HistorySelect(startTime, endTime))
         return false;

      int dealsTotal = HistoryDealsTotal();
      double grossProfit = 0.0;
      double grossLoss = 0.0;
      double totalPipsSum = 0.0;

      for(int i = 0; i < dealsTotal; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0) continue;

         if(m_magicFilter > 0 && (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != m_magicFilter)
            continue;

         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY && entry != DEAL_ENTRY_INOUT)
            continue;

         string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double closePrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
         ulong posId = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         ENUM_DEAL_TYPE dType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         bool posWasBuy = (dType == DEAL_TYPE_SELL);

         double pipSize = GetPipSize(symbol);
         double openPrice = 0.0;

         if(posId > 0 && HistorySelectByPosition(posId))
         {
            int pDeals = HistoryDealsTotal();
            for(int p = 0; p < pDeals; p++)
            {
               ulong pTicket = HistoryDealGetTicket(p);
               if(HistoryDealGetInteger(pTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
               {
                  openPrice = HistoryDealGetDouble(pTicket, DEAL_PRICE);
                  break;
               }
            }
            HistorySelect(startTime, endTime);
         }

         double pips = 0.0;
         if(pipSize > 0 && openPrice > 0)
         {
            pips = posWasBuy ? (closePrice - openPrice) / pipSize : (openPrice - closePrice) / pipSize;
         }

         outSummary.totalTrades++;
         outSummary.netProfit += profit;
         totalPipsSum += pips;

         if(profit > 0.05)
         {
            outSummary.wins++;
            grossProfit += profit;
         }
         else if(profit < -0.05)
         {
            outSummary.losses++;
            grossLoss += MathAbs(profit);
         }
         else
         {
            outSummary.breakevens++;
         }
      }

      outSummary.totalPips = totalPipsSum;
      outSummary.winRate = (outSummary.totalTrades > 0) ? ((double)outSummary.wins * 100.0 / (double)outSummary.totalTrades) : 0.0;
      outSummary.profitFactor = (grossLoss > 0.001) ? (grossProfit / grossLoss) : (grossProfit > 0 ? 99.9 : 0.0);

      return (outSummary.totalTrades > 0);
   }

   //--- Format Performance Recap as an institutional HTML Telegram message
   static string FormatPerformanceRecapHtml(const DailyPerformanceSummary &summary, const string botUser, const string supportBot)
   {
      string dateStr = TimeToString(summary.date, TIME_DATE);
      string pnlSign = (summary.netProfit >= 0) ? "+" : "-";
      string pnlColor = (summary.netProfit >= 0) ? "🟢" : "🔴";
      string pipsSign = (summary.totalPips >= 0) ? "+" : "";

      string text = "";
      text += "📊 <b>DAILY PERFORMANCE RECAP</b>\n";
      text += "📅 Date: <b>" + dateStr + "</b>\n";
      text += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
      text += "🎯 Total Trades Closed: <b>" + IntegerToString(summary.totalTrades) + "</b>\n";
      text += "✅ Wins: <b>" + IntegerToString(summary.wins) + "</b> | ";
      text += "❌ Losses: <b>" + IntegerToString(summary.losses) + "</b> | ";
      text += "⚖️ Breakeven: <b>" + IntegerToString(summary.breakevens) + "</b>\n";
      text += "🏆 Win Rate: <b>" + DoubleToString(summary.winRate, 1) + "%</b>\n";
      text += "📈 Profit Factor: <b>" + DoubleToString(summary.profitFactor, 2) + "</b>\n";
      text += "─────────────────────────\n";
      text += pnlColor + " Net Realized PnL: <b>" + pnlSign + "$" + DoubleToString(MathAbs(summary.netProfit), 2) + " " + summary.currency + "</b>\n";
      text += "📏 Total Pips Secured: <b>" + pipsSign + DoubleToString(summary.totalPips, 1) + " pips</b>\n";
      text += "─────────────────────────\n";
      text += "💬 <i>Automated institutional trade summary generated by TeleSnap Hub.</i>\n";
      text += "━━━━━━━━━━━━━━━━━━━━━━━━━\n";
      text += "📢 <b>Powered by TeleSnap Pro</b>\n";
      if(StringLen(supportBot) > 0)
         text += "⚡️ Customer Support: @" + supportBot + "\n";
      text += "🌐 Get TeleSnap on MQL5 Market: <a href=\"https://www.mql5.com/\">mql5.com</a>\n";

      return text;
   }
};
