//+------------------------------------------------------------------+
//|                                          Support and Resistance  |
//|                                 Copyright © 2004  Barry Stander  |
//|                          http://myweb.absa.co.za/stander/4meta/  |
//+------------------------------------------------------------------+
#property copyright "Click here: Barry Stander"
#property link      "http://myweb.absa.co.za/stander/4meta/"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Blue
//---- buffers
double v1[];
double v2[];
double val1;
double val2;
int i;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  
int init()
  {
//---- drawing settings
   SetIndexArrow(0, 119);
   SetIndexArrow(1, 119);
//----  
   SetIndexStyle(0, DRAW_ARROW, STYLE_DOT, 1);
   SetIndexDrawBegin(0, i-1);
   SetIndexBuffer(0, v1);
   SetIndexLabel(0,"Resistance");
//----    
   SetIndexStyle(1,DRAW_ARROW,STYLE_DOT,1);
   SetIndexDrawBegin(1,i-1);
   SetIndexBuffer(1, v2);
   SetIndexLabel(1,"Support");
//---- 
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  { 
   i = Bars;
   while(i >= 0)
     {   
       val1 = iFractals(NULL, 0, MODE_UPPER, i);
       //----
       if(val1 > 0) 
           v1[i] = High[i];
       else
           v1[i] = v1[i+1];
       val2 = iFractals(NULL, 0, MODE_LOWER, i);
       //----
       if(val2 > 0) 
           v2[i] = Low[i];
       else
           v2[i] = v2[i+1];
       i--;
     }   
   return(0);
  }
//+------------------------------------------------------------------+