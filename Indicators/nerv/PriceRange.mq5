//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2015, nervtech.org"
#property link        "http://www.nervtech.org"
#property description "PriceRange"
#include <MovingAverages.mqh>
#include <nerv/math.mqh>

//---
#property indicator_chart_window
// #property indicator_separate_window

#property indicator_buffers 7
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed

#property indicator_label1  "High prices"
#property indicator_label2  "Low prices"

//--- input parametrs
input int     NumSamples=20;      // Number of samples
input int     BaseMAPeriod=4;           // Period of base MA
input ENUM_APPLIED_PRICE AppliedPrice=PRICE_CLOSE; // Applied price

int           PlotBegin=0;

//---- indicator buffer
double        highBufferMean[];
double        highBufferDev[];
double        lowBufferMean[];
double        lowBufferDev[];
double        highLineBuffer[];
double        lowLineBuffer[];
double        MABuffer[];

nvVecd highRanges;
nvVecd lowRanges;
int MAHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
  //--- define buffers
  SetIndexBuffer(0,highLineBuffer);
  SetIndexBuffer(1,lowLineBuffer);
  
  SetIndexBuffer(2,highBufferMean,INDICATOR_CALCULATIONS);
  SetIndexBuffer(3,highBufferDev,INDICATOR_CALCULATIONS);
  SetIndexBuffer(4,lowBufferMean,INDICATOR_CALCULATIONS);
  SetIndexBuffer(5,lowBufferDev,INDICATOR_CALCULATIONS);
  SetIndexBuffer(6,MABuffer,INDICATOR_CALCULATIONS);

  //--- set index labels
  PlotIndexSetString(0,PLOT_LABEL,"Price range");
  
  //--- indicator name
  IndicatorSetString(INDICATOR_SHORTNAME,"Price range");

  //--- indexes draw begin settings
  PlotBegin=NumSamples-1;
  PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,NumSamples);

  //--- indexes shift settings
  PlotIndexSetInteger(0,PLOT_SHIFT,0);

  //--- number of digits of indicator value
  IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);

  highRanges.resize(NumSamples);
  lowRanges.resize(NumSamples);

  // Init moving average:
  MAHandle=iMA(NULL,0,BaseMAPeriod,0,MODE_EMA,AppliedPrice);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // size of input time series
                 const int prev_calculated,  // bars handled in previous call
                 const datetime& time[],     // Time
                 const double& open[],       // Open
                 const double& high[],       // High
                 const double& low[],        // Low
                 const double& close[],      // Close
                 const long& tick_volume[],  // Tick Volume
                 const long& volume[],       // Real Volume
                 const int& spread[]         // Spread
   )
{
  //--- variables
  int pos;
  
  CHECK(BarsCalculated(MAHandle)>=rates_total,"Invalid num bars in MA");

  //--- check for bars count
  if(rates_total<PlotBegin)
    return(0);

  //--- we can copy not all data
  int to_copy;
  if(prev_calculated>rates_total || prev_calculated<0) 
  {
    to_copy=rates_total;
  }
  else
  {
    to_copy=rates_total-prev_calculated;
    if(prev_calculated>0) 
      to_copy++;
  }

  CHECK(CopyBuffer(MAHandle,0,0,to_copy,MABuffer)==to_copy,"Cannot copy MA buffer 0")

  //--- starting calculation
  if(prev_calculated>1) 
    pos=prev_calculated-1;
  else 
    pos=0;
  
  //--- main cycle
  // note that we only consider the completed bars in the computation:
  for(int i=pos;i<(rates_total-1) && !IsStopped();i++)
  {
    //logDEBUG("Performing indicator calculation at pos: "<<i)
    highRanges.push_back(high[i]-MABuffer[i-pos]);
    lowRanges.push_back(low[i]-MABuffer[i-pos]);

    highBufferMean[i] = MABuffer[i-pos] + highRanges.mean();
    highBufferDev[i] = highRanges.deviation();
    highLineBuffer[i] = highBufferMean[i] + highBufferDev[i];

    lowBufferMean[i] = MABuffer[i-pos] + lowRanges.mean();
    lowBufferDev[i] = lowRanges.deviation();
    lowLineBuffer[i] = lowBufferMean[i] - lowBufferDev[i];
  }

  //---- OnCalculate done. Return new prev_calculated.
  return(rates_total);
}
