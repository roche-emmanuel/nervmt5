//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2015, nervtech.org"
#property link        "http://www.nervtech.org"
#property description "BarVariation"
#include <MovingAverages.mqh>
#include <nerv/math.mqh>

//---
// #property indicator_chart_window
#property indicator_separate_window

#property indicator_buffers 2
#property indicator_minimum -3
#property indicator_maximum 3
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_level1 1.0
#property indicator_level2 -1.0
// #property indicator_level3 3.0
// #property indicator_level4 4.0

#property indicator_label1  "Bar Size"

//--- input parametrs
input int     NumSamples=20;       // Number of samples
input int     NumBars=3;           // Number of bars to consider

int           PlotBegin=0;

//---- indicator buffer
double        innerSizeBuffer[];
double        outerSizeBuffer[];

nvVecd innerRanges;
nvVecd outerRanges;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{

  //--- define buffers
  SetIndexBuffer(0,innerSizeBuffer);
  SetIndexBuffer(1,outerSizeBuffer);

  //--- set index labels
  PlotIndexSetString(0,PLOT_LABEL,"Bar Size");
  
  //--- indicator name
  IndicatorSetString(INDICATOR_SHORTNAME,"Bar variation");

  //--- indexes draw begin settings
  PlotBegin=NumBars-1+NumSamples-1;
  PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,PlotBegin+1);

  //--- indexes shift settings
  PlotIndexSetInteger(0,PLOT_SHIFT,0);

  //--- number of digits of indicator value
  IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

  innerRanges.resize(NumSamples);
  outerRanges.resize(NumSamples);
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
  
  //--- indexes draw begin settings, when we've recieved previous begin
  // if(PlotBegin!=NumSamples+begin)
  // {
  //   PlotBegin=NumSamples+begin;
  //   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,PlotBegin);
  // }

  //--- check for bars count
  if(rates_total<PlotBegin)
    return(0);

  //--- starting calculation
  if(prev_calculated>1) 
    pos=prev_calculated-1;
  else 
    pos=0;
  
  pos+=NumBars-1;

  //--- main cycle
  for(int i=pos;i<rates_total && !IsStopped();i++)
  {
    //logDEBUG("Performing indicator calculation at pos: "<<i)

    double var = close[i]-open[i-NumBars+1];
    innerRanges.push_back(var);
    outerRanges.push_back(high[i]-low[i-NumBars+1]);

    double dev = innerRanges.deviation();
    innerSizeBuffer[i] = dev>0.0 ? (var-innerRanges.mean())/dev : 0.0;
    dev = outerRanges.deviation();
    outerSizeBuffer[i] = dev>0.0 ? outerRanges.mean()/dev : 0.0;
  }

  //---- OnCalculate done. Return new prev_calculated.
  return(rates_total);
}
