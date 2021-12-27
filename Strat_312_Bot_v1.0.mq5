//+------------------------------------------------------------------+
//|                                           Strat_312_Bot_v1.0.mq5 |
//|                                                             Mani |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "lib_cisnewbar.mqh"
#property copyright "Mani"
#property link      "https://www.mql5.com"
#property version   "1.00"
//--- input parameters
input double Lot = 0.1; // Lot to trade
input ENUM_TIMEFRAMES RSI_TF = PERIOD_M5; // TimeFrame to trade
input int EA_Magic = 09876; // Expert Advisor Magic Number
input double targetRiskRewardRatio = 1; // Risk Reward ratio is defined as (1 : riskRewardRatio)

//--- Other Globals
double p_close; // Variable to store the close value of a bar
int STP, TKP;   // To be used for Stop Loss & Take Profit values
CisNewBar current_chart;


enum BarType
  {
   InsideBar,
   TwoUpBar,
   TwoDownBar,
   OutsideBar
  };


// Determines what type of strat bar this one is.
BarType GetBarType(double barLow, double barHigh, double oldLow, double oldHigh)
  {
   if(barLow >= oldLow)
     {
      if(barHigh <= oldHigh)
        {
         return InsideBar;
        }
      else
        {
         return TwoUpBar;
        }

     }
   else
     {
      if(barHigh <= oldHigh)
        {
         return TwoDownBar;
        }
      else
        {
         return OutsideBar;
        }
     }
  }


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

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

   int period_seconds=PeriodSeconds(_Period);                     // Number of seconds in current chart period
   datetime new_time=TimeCurrent()/period_seconds*period_seconds; // Time of bar opening on current chart
   if(current_chart.isNewBar(new_time))
      Print("New bar spotted");               // When new bar appears - launch the NewBar event handler

   bool IsNewBar = false;

// 1) If not in trade && not in the same bar as previous trade a), if in trade b)
   if(!PositionSelect(_Symbol) && IsNewBar)
     {
      MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
      // the rates arrays
      ArraySetAsSeries(mrate, true);

      //--- Get the details of the latest 5 bars
      if(CopyRates(_Symbol,_Period,0,4,mrate)<0)
        {
         Alert("Error copying rates/history data - error:",GetLastError(),"!!");
         return;
        }

      // a) REFACTOR: Logic area for other bar patterns.
      //              + If we have already seen a pattern, put in state so we do not constantly check for pattern each tick.
      // Check last 2 bars and ensure we have a 3-1 pattern
      if(GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == OutsideBar && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == InsideBar)
        {
         //--- Define some MQL5 Structures we will use for our trade
         MqlTradeRequest mrequest;  // To be used for sending our trade requests
         MqlTradeResult mresult;    // To be used to get our trade results
         ZeroMemory(mrequest);     // Initialization of mrequest structure

         double risk = mrate[1].high - mrate[1].low;
         double reward = mrate[2].high - mrate[1].high;

         // The calculated Risk reward ratio has to be >= our targetRiskRewardRatio
         if(reward / risk < targetRiskRewardRatio)
           {
            return;
           }

         double takeProfit = mrate[2].high;

         mrequest.action = TRADE_ACTION_PENDING;                                // immediate order execution
         mrequest.price = NormalizeDouble(mrate[1].high+0.01, _Digits);          // 
         mrequest.sl = NormalizeDouble(mrate[1].low-0.01,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(takeProfit,_Digits); // Take Profit
         mrequest.symbol = _Symbol;                                         // currency pair
         mrequest.volume = Lot;                                            // number of lots to trade
         mrequest.magic = EA_Magic;                                        // Order Magic Number
         mrequest.type = ORDER_TYPE_BUY_STOP;                                     // Buy Order
         mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
         mrequest.deviation=100;                                            // Deviation from current price // TODO: Not sure about this... may vary between symbol

         

         OrderSend(mrequest, mresult);

         // get the result code
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
           {
            Alert("Price",mresult.price,"!!");
            Alert("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
           }
         else
           {
            Alert("The Buy order request could not be completed -error:",GetLastError());
            ResetLastError();
            return;
           }
        }
     }

// b)
// NOTE: Not using currently, as just keeping to stop loss and take profit values to exit a trade.
// Find out which previous bar is a 3, i.e. could be 3-1-1-1.
// Close if current bar's price hit high or low of the 3 bar



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
