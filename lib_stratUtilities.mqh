// Contains utility functions used by strat


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


// Determines and returns true if bar ended on high or false if low
bool IsGreenBar(double open, double close, double magnitude = 0)
  {
   if(open >= close)
     {
      return open - close >= magnitude;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is312(MqlRates& mrate[])
  {
   return GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == OutsideBar && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == InsideBar;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is212(MqlRates& mrate[])
  {
   return (GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == TwoUpBar || GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == TwoDownBar) && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == InsideBar;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is122RevStratShort(MqlRates& mrate[])
  {
   return GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == InsideBar
          && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == TwoUpBar;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is122RevStratLong(MqlRates& mrate[])
  {
   return GetBarType(mrate[2].low, mrate[2].high, mrate[3].low, mrate[3].high) == InsideBar
          && GetBarType(mrate[1].low, mrate[1].high, mrate[2].low, mrate[2].high) == TwoDownBar;
  }
//+------------------------------------------------------------------+
