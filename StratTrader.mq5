//+------------------------------------------------------------------+
//|                                           Strat_312_Bot_v1.0.mq5 |
//|                                                             Mani |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "lib_cisnewbar.mqh"
#include "lib_stratUtilities.mqh"

#property copyright "Mani"
#property link      "https://www.mql5.com"
#property version   "1.00"
//--- input parameters
// NOTE: THESE ARE DEFAULT VALUES, CHANGE THESE IN THE INPUTS WINDOW OF THE STRATEGY TESTER
input double Lot = 1; // Lot to trade
input int EA_Magic = 09876; // Expert Advisor Magic Number
input double targetRiskRewardRatio = 1; // Risk Reward ratio is defined as (1 : riskRewardRatio)
input double takeProfitPercent = 1; // 0-1 take profit level.
input bool use312 = false;
input bool use212 = false;
input bool useRevstratLong = false;
input bool useRevstratShort = false;
input int StartHour = 15;       // Time to start trading ( hours of 24 hr clock ) 0 for both disables
input int StopHour = 21;        // Time to stop trading ( hours of 24 hr clock ) 0 for both disables
input bool useRiskForTakeProfit = false; 
input bool moveStopLoss = false;
input bool includeContinuations = true;
input bool includeReversals = true;

input bool useDynamicLots = false; //
input double maxDynamicLotRisk = 300; // Should be 1% of initial deposit
input double buyingPower = 3000; // 10% of initial deposit, or all.

input bool useTimeFrameContinuity = false;
input ENUM_TIMEFRAMES FTFC1 = PERIOD_M30; // Full time fra  me continuity
input ENUM_TIMEFRAMES FTFC2 = PERIOD_H1; // Full time frame continuity
input ENUM_TIMEFRAMES FTFC3 = PERIOD_H2; // Full time frame continuity
input ENUM_TIMEFRAMES FTFC4 = PERIOD_H4; // Full time frame continuity

//--- Other Globals
// double p_close; // Variable to store the close value of a bar
// int STP, TKP;   // To be used for Stop Loss & Take Profit values
CTrade g_Trade;
CPositionInfo g_PositionInfo;
CisNewBar current_chart;
ENUM_TIMEFRAMES FTFCToCheck[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsWithinFTFC(bool forLong, double orderPrice)
  {
   bool isWithin = true;
   for(int i = 0; i < ArraySize(FTFCToCheck); ++i)
     {
      MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
      ArraySetAsSeries(mrate, true);
      if(CopyRates(_Symbol,FTFCToCheck[i],0,1,mrate)<0)
        {
         Alert("Error copying rates/history data - error:",GetLastError(),"!!");
        }

      // Ensure open price is appropriate
      isWithin &= forLong ? mrate[0].open <= orderPrice : mrate[0].open >= orderPrice;
      // Redundant
      // isWithin &= forLong ? IsGreenBar(mrate[0].open, mrate[0].close) : !IsGreenBar(mrate[0].open, mrate[0].close);
     }

   return isWithin;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
  {
   MqlDateTime mdt;
   TimeCurrent(mdt);

   return mdt.hour>=StartHour && mdt.hour<StopHour;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TryNormalLong(MqlRates& mrate[])
  {
// Long order
   double risk = mrate[1].high - mrate[1].low;
   double reward = mrate[2].high - mrate[1].high;

   if(risk == 0)
   {
      Print("Risk is 0");
      return false;
   }
   
// The calculated Risk reward ratio has to be >= our targetRiskRewardRatio
   if(reward / risk >= targetRiskRewardRatio)
     {
      // Print("Risk reward buy: ", reward / risk);
      double takeProfit = useRiskForTakeProfit ? mrate[1].high + risk : mrate[1].high + (reward * takeProfitPercent);
      double stopLoss = mrate[1].low; // + (risk /2);
      double orderPrice = NormalizeDouble(mrate[1].high, _Digits);
      double lots = useDynamicLots ? MathRound(maxDynamicLotRisk / risk) : Lot;
      if(lots * orderPrice > buyingPower)
        {
         lots = buyingPower / orderPrice;
        }
      // Print("Risk: ", risk);
      // Print("Lots calculated: ", lots);

      if(!IsWithinFTFC(true, orderPrice))
         return false;
      g_Trade.BuyStop(NormalizeDouble(lots, 0), orderPrice, NULL, NormalizeDouble(stopLoss,_Digits), NormalizeDouble(takeProfit,_Digits));
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TryNormalShort(MqlRates& mrate[])
  {
// Short order
   double risk = mrate[1].high - mrate[1].low;
   double reward = mrate[1].low - mrate[2].low;

   if(risk == 0)
   {
      Print("Risk is 0");
      return false;
   }
   
// The calculated Risk reward ratio has to be >= our targetRiskRewardRatio
   if(reward / risk >= targetRiskRewardRatio)
     {
      // Print("Risk reward sell: ", reward / risk);
      double takeProfit = useRiskForTakeProfit ? mrate[1].low - risk : mrate[1].low - (reward * takeProfitPercent);
      double stopLoss = mrate[1].high; // + (risk / 2);
      double orderPrice = NormalizeDouble(mrate[1].low, _Digits);
      double lots = useDynamicLots ? MathRound(maxDynamicLotRisk / risk) : Lot;
      if(lots * orderPrice > buyingPower)
        {
         lots = buyingPower / orderPrice;
        }

      if(!IsWithinFTFC(false, orderPrice))
         return false;
      g_Trade.SellStop(NormalizeDouble(lots, 0), orderPrice, NULL, NormalizeDouble(stopLoss,_Digits), NormalizeDouble(takeProfit,_Digits));
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TryRevStratLong(MqlRates& mrate[])
  {
// Long order
   double risk = mrate[1].high - mrate[2].low;
   double reward = (risk * targetRiskRewardRatio);

   // Print("Risk reward buy: ", reward / risk);
   double takeProfit = reward + mrate[1].high;
   double stopLoss = mrate[2].low; // + (risk /2);
   double orderPrice = NormalizeDouble(mrate[1].high, _Digits);
   double lots = useDynamicLots ? MathRound(maxDynamicLotRisk / risk) : Lot;
   if(lots * orderPrice > buyingPower)
     {
      lots = buyingPower / orderPrice;
     }

   if(!IsWithinFTFC(true, orderPrice))
      return false;
   g_Trade.BuyStop(NormalizeDouble(lots, 0), orderPrice, NULL, NormalizeDouble(stopLoss,_Digits), NormalizeDouble(takeProfit,_Digits));
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TryRevStratShort(MqlRates& mrate[])
  {
// Short order
   double risk = mrate[1].high - mrate[1].low;
   double reward = (risk * targetRiskRewardRatio);

// The calculated Risk reward ratio has to be >= our targetRiskRewardRatio
   // Print("Risk reward sell: ", reward / risk);
   double takeProfit = mrate[1].low - reward;
   double stopLoss = mrate[1].low; // + (risk / 2);
   double orderPrice = NormalizeDouble(mrate[1].low, _Digits);
   double lots = useDynamicLots ? MathRound(maxDynamicLotRisk / risk) : Lot;
   if(lots * orderPrice > buyingPower)
     {
      lots = buyingPower / orderPrice;
     }

   if(!IsWithinFTFC(false, orderPrice))
      return false;
   g_Trade.SellStop(NormalizeDouble(lots, 0), orderPrice, NULL, NormalizeDouble(stopLoss,_Digits), NormalizeDouble(takeProfit,_Digits));
   return true;
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(useTimeFrameContinuity)
     {
      ArrayResize(FTFCToCheck, 1);
      FTFCToCheck[0] = FTFC1;
      // FTFCToCheck[1] = FTFC2;
      // FTFCToCheck[2] = FTFC3;
      // FTFCToCheck[3] = FTFC4;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!IsWithinTradingHours())
      return;

   int period_seconds=PeriodSeconds(_Period);                     // Number of seconds in current chart period
   datetime new_time=TimeCurrent()/period_seconds*period_seconds; // Time of bar opening on current chart
   bool IsNewBar = current_chart.isNewBar(new_time);

   if(PositionsTotal() > 0)
     {
      if(OrdersTotal() > 0)
        {
         g_Trade.OrderDelete(OrderGetTicket(0));
        }
      // If price has reached 50% toward take profit, move stop loss up to entry. 
      if(moveStopLoss && g_PositionInfo.SelectByTicket(PositionGetTicket(0)))
      {
         double currentTakeProfit = g_PositionInfo.TakeProfit();
         double entry = g_PositionInfo.PriceOpen();
         
         if(g_PositionInfo.Type() == POSITION_TYPE_BUY)
         {
            if(entry == g_PositionInfo.StopLoss() && g_PositionInfo.PriceCurrent() >= ((currentTakeProfit - entry) / 2.0f) + entry)
            {
               g_Trade.PositionModify(PositionGetTicket(0), entry, currentTakeProfit);
            }
         }
         else if(g_PositionInfo.Type() == POSITION_TYPE_SELL)
         {
            if(entry == g_PositionInfo.StopLoss() && g_PositionInfo.PriceCurrent() <= ((entry - currentTakeProfit) / 2.0f) + entry)
            {
               g_Trade.PositionModify(PositionGetTicket(0), entry, currentTakeProfit);
            }
         }
      }

      return;
     }

   if(!IsNewBar)
     {
      return;
     }

// DELETE BOTH ORDERS
// If new bar and order is placed but not triggered
   if(OrderGetTicket(1) != 0)
     {
      g_Trade.OrderDelete(OrderGetTicket(1));
     }
// If new bar and order is placed but not triggered
   if(OrderGetTicket(0) != 0)
     {
      g_Trade.OrderDelete(OrderGetTicket(0));
     }

   MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
   ArraySetAsSeries(mrate, true);

//--- Get the details of the latest 5 bars
   if(CopyRates(_Symbol,_Period,0,4,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
     }

// Check last 2 bars and ensure we have a 3-1 pattern
   if(use312 && Is312(mrate))
     {
      // To be used for getting recent/latest price quotes
      MqlTick Latest_Price; // Structure to get the latest prices
      SymbolInfoTick(Symbol(),Latest_Price);  // Assign current prices to structure
      // Print("Ask Price: ", Latest_Price.ask, "Bid Price: ", Latest_Price.bid);

      if(Latest_Price.ask >= mrate[1].high || Latest_Price.bid <= mrate[1].low)
         return;
      
      TryNormalLong(mrate);
      TryNormalShort(mrate);
     }
   else if(use212)
   {
      if(Latest_Price.ask >= mrate[1].high || Latest_Price.bid <= mrate[1].low)
         return;

      if(includeContinuations)
      {
         if(Is212BullCont(mrate))
         {
            TryNormalLong(mrate);
         }
         else if(Is212BearCont(mrate))
         {
            TryNormalShort(mrate);
         }
      }
      
      if(includeReversals)
      {
         if(Is212BullRev(mrate))
         {
            TryNormalLong(mrate);
         }
         else if(Is212BearRev(mrate))
         {
            TryNormalShort(mrate);
         }
      }
   }
   else
      if(useRevstratLong && Is122RevStratLong(mrate))
        {
         // To be used for getting recent/latest price quotes
         MqlTick Latest_Price; // Structure to get the latest prices
         SymbolInfoTick(Symbol(),Latest_Price);  // Assign current prices to structure
         // Print("Ask Price: ", Latest_Price.ask, "Bid Price: ", Latest_Price.bid);

         if(Latest_Price.ask >= mrate[1].high || Latest_Price.bid <= mrate[1].low)
            return;
         TryRevStratLong(mrate);
        }
      else
         if(useRevstratShort && Is122RevStratShort(mrate))
           {
            // To be used for getting recent/latest price quotes
            MqlTick Latest_Price; // Structure to get the latest prices
            SymbolInfoTick(Symbol(),Latest_Price);  // Assign current prices to structure
            // Print("Ask Price: ", Latest_Price.ask, "Bid Price: ", Latest_Price.bid);

            if(Latest_Price.ask >= mrate[1].high || Latest_Price.bid <= mrate[1].low)
               return;

            TryRevStratShort(mrate);
           }

  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
