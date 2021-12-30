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

BarType GetBarType(MqlRates& mrates[], int barIndex)
  {
   if(mrates[barIndex].low >= mrates[barIndex + 1].low)
     {
      if(mrates[barIndex].high <= mrates[barIndex + 1].high)
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
      if(mrates[barIndex].high <= mrates[barIndex + 1].high)
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
   if(open < close)
     {
      return close - open >= magnitude;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is312(MqlRates& mrate[])
  {
   return GetBarType(mrate, 2) == OutsideBar && GetBarType(mrate, 1) == InsideBar;
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is212BullCont(MqlRates& mrate[])
  {
   return (GetBarType(mrate, 2) == TwoUpBar || GetBarType(mrate, 2) == TwoDownBar) 
            && GetBarType(mrate, 1) == InsideBar
            && IsGreenBar(mrate[2].open, mrate[2].close);
  }

bool Is212BearCont(MqlRates& mrate[])
  {
   return (GetBarType(mrate, 2) == TwoUpBar || GetBarType(mrate, 2) == TwoDownBar) 
            && GetBarType(mrate, 1) == InsideBar
            && !IsGreenBar(mrate[2].open, mrate[2].close);           
  }

bool Is212BullRev(MqlRates& mrate[])
  {
   return (GetBarType(mrate, 2) == TwoUpBar || GetBarType(mrate, 2) == TwoDownBar) 
            && GetBarType(mrate, 1) == InsideBar
            && !IsGreenBar(mrate[2].open, mrate[2].close);           
  }
  
bool Is212BearRev(MqlRates& mrate[])
  {
   return (GetBarType(mrate, 2) == TwoUpBar || GetBarType(mrate, 2) == TwoDownBar) 
            && GetBarType(mrate, 1) == InsideBar
            && IsGreenBar(mrate[2].open, mrate[2].close);           
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is122RevStratShort(MqlRates& mrate[])
  {
   return GetBarType(mrate, 2) == InsideBar
          && GetBarType(mrate, 1) == TwoUpBar;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Is122RevStratLong(MqlRates& mrate[])
  {
   return GetBarType(mrate, 2) == InsideBar
          && GetBarType(mrate, 1) == TwoDownBar;
  }
//+------------------------------------------------------------------+
