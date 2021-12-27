//+------------------------------------------------------------------+
//|                                           Strat_312_Bot_v1.0.mq5 |
//|                                                             Mani |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include "lib_cisnewbar.mqh"
#include "lib_stratUtilities.mqh"

#property copyright "Mani"
#property link      "https://www.mql5.com"
#property version   "1.00"
//--- input parameters
// NOTE: THESE ARE DEFAULT VALUES, CHANGE THESE IN THE INPUTS WINDOW OF THE STRATEGY TESTER
input double Lot = 1; // Lot to trade
input ENUM_TIMEFRAMES TimeFrameToTrade = PERIOD_M15; // TimeFrame to trade
input int EA_Magic = 09876; // Expert Advisor Magic Number
input double targetRiskRewardRatio = 1; // Risk Reward ratio is defined as (1 : riskRewardRatio)
input double takeProfitPercent = 1; // 0-1 take profit level. 
input bool use312 = false;
input bool use212 = false;
input bool useRevstratLong = false;
input bool useRevstratShort = false;   
input int StartHour = 15;       // Time to start trading ( hours of 24 hr clock ) 0 for both disables
input int StopHour = 21;        // Time to stop trading ( hours of 24 hr clock ) 0 for both disables

input bool useTimeFrameContinuity = false;
input ENUM_TIMEFRAMES FTFC1 = PERIOD_M30; // Full time fra  me continuity
input ENUM_TIMEFRAMES FTFC2 = PERIOD_H1; // Full time frame continuity
input ENUM_TIMEFRAMES FTFC3 = PERIOD_H2; // Full time frame continuity
input ENUM_TIMEFRAMES FTFC4 = PERIOD_H4; // Full time frame continuity

//--- Other Globals
// double p_close; // Variable to store the close value of a bar
// int STP, TKP;   // To be used for Stop Loss & Take Profit values
CTrade g_Trade;
CisNewBar current_chart;
ENUM_TIMEFRAMES FTFCToCheck[];

// 1 bar test vars
int greenBarContinuationBull = 0;
int redBarContinuationBull = 0; 
int greenBarContinuationBear = 0;
int redBarContinuationBear = 0;
int greenBarReversalBull = 0;
int redBarReversalBull = 0; 
int greenBarReversalBear = 0;
int redBarReversalBear = 0;
int allTrades = 0;

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
   // add up the results for the 1 bar checks
   Print("greenBarContinuationBull: ", greenBarContinuationBull, "(", (greenBarContinuationBull / allTrades) , ")");
   Print("redBarContinuationBull: ", redBarContinuationBull, "(", redBarContinuationBull / allTrades , ")");
   Print("greenBarContinuationBear: ", greenBarContinuationBear, "(", greenBarContinuationBear / allTrades , ")");
   Print("redBarContinuationBear: ", redBarContinuationBear, "(", redBarContinuationBear / allTrades , ")");
   Print("greenBarReversalBull: ", greenBarReversalBull, "(", greenBarReversalBull / allTrades , ")");
   Print("redBarReversalBull: ", redBarReversalBull, "(", redBarReversalBull / allTrades , ")");
   Print("greenBarReversalBear: ", greenBarReversalBear, "(", greenBarReversalBear / allTrades , ")");
   Print("redBarReversalBear: ", redBarReversalBear, "(", redBarReversalBear / allTrades , ")");
   
   Print("Total Trades: ", allTrades);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!IsWithinTradingHours())
      return;

// On bar after 312 212, we just check the 1 bar and increment appropriately. 



   int period_seconds=PeriodSeconds(_Period);                     // Number of seconds in current chart period
   datetime new_time=TimeCurrent()/period_seconds*period_seconds; // Time of bar opening on current chart
   bool IsNewBar = current_chart.isNewBar(new_time);

   if(!IsNewBar)
     {
      return;
     }

   MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
   ArraySetAsSeries(mrate, true);

//--- Get the details of the latest 5 bars
   if(CopyRates(_Symbol,TimeFrameToTrade,0,5,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
     }

   if(GetBarType(mrate[3].low, mrate[3].high, mrate[4].low, mrate[4].high) == TwoUpBar 
      && GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == InsideBar
      && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == TwoUpBar)
      {
         if(IsGreenBar(mrate[2].open, mrate[2].close))
         {
            greenBarContinuationBull++;
            allTrades++;
         }
         else 
         {
            redBarContinuationBull++;
            allTrades++;
         }
      }
   else if(GetBarType(mrate[3].low, mrate[3].high, mrate[4].low, mrate[4].high) == TwoUpBar 
      && GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == InsideBar
      && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == TwoDownBar)
      {
         if(IsGreenBar(mrate[2].open, mrate[2].close))
         {
            greenBarReversalBear++;
            allTrades++;
         }
         else 
         {
            redBarReversalBear++;
            allTrades++;
         }         
      }
   else if(GetBarType(mrate[3].low, mrate[3].high, mrate[4].low, mrate[4].high) == TwoDownBar 
      && GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == InsideBar
      && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == TwoDownBar)
      {
         if(IsGreenBar(mrate[2].open, mrate[2].close))
         {
            greenBarContinuationBear++;
            allTrades++;
         }
         else 
         {
            redBarContinuationBear++;
            allTrades++;
         }         
      }
   else if(GetBarType(mrate[3].low, mrate[3].high, mrate[4].low, mrate[4].high) == TwoDownBar 
      && GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == InsideBar
      && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == TwoUpBar)
      {
         if(IsGreenBar(mrate[2].open, mrate[2].close))
         {
            greenBarReversalBull++;
            allTrades++;
         }
         else 
         {
            redBarReversalBull++;
            allTrades++;
         }         
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
