//+------------------------------------------------------------------+
//|                                              NERVExpertBasic.mq5 |
//|                                         Copyright 2015, NervTech |
//|                                 http://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "http://wiki.singularityworld.net"
#property version   "1.00"

int      EA_Magic=11220;   // EA Magic Number
double   ref_price;
double   stop_lost;
double num_lots = 0.01;
int mean_spread = 8;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   
   // We will use the static Old_Time variable to serve the bar time.
   // At each OnTick execution we will check the current bar time with the saved one.
   // If the bar time isn't equal to the saved time, it indicates that we have a new tick.
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;
  
// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
   {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
      {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         //if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
      }
   }
   else
   {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
   }

   //--- EA should only check for new trade if we have a new bar
   if(IsNewBar==false)
   {
      return;
   }  
     
   //Print("Handling new bar at ", Old_Time);

   //--- Define some MQL5 Structures we will use for our trade
   MqlTick latest_price;      // To be used for getting recent/latest price quotes
   MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar   
   MqlTradeRequest mrequest;  // To be used for sending our trade requests
   MqlTradeResult mresult;    // To be used to get our trade results

   
   //--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
   {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
   }
   
   //Print("Latest bid price: ",latest_price.bid," at time ",latest_price.time);

   // Retrieve the latest bar:
   //--- Get the details of the latest 3 bars
   if(CopyRates(_Symbol,_Period,0,1,mrate)<0)
   {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      ResetLastError();
      return;
   }
   
   // Check the close price of the latest bar:
   //Print("Latest close price: ",mrate[0].close," at time ",mrate[0].time," for symbol ",Symbol());
   
   // Now we check if we are already in a position:
   if(PositionSelect(_Symbol))
   {
      // Check if we have a buy or sell position:
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
      {
         // Here we should check if we should update the stop lost value for the buy position.
         double cur_price = latest_price.bid;
         if(cur_price > ref_price) 
         {
            double new_stop = cur_price - 0.5 * MathMin(cur_price - ref_price, mean_spread);
            
            if(new_stop>stop_lost) {
               stop_lost = new_stop;
               Print("Updating stop lost to ", stop_lost);
               
               // Now send the update request:
               ZeroMemory(mrequest);
               mrequest.action = TRADE_ACTION_SLTP;                                  // immediate order execution
               mrequest.sl = stop_lost;                                              // Stop Loss
               mrequest.tp = cur_price*10.0; // Take Profit
               mrequest.symbol = _Symbol;                                            // currency pair
               
               //--- send order
               if(!OrderSend(mrequest,mresult)) {
                  Alert("Could not Update stop lost -error:",GetLastError());
                  ResetLastError();           
                  return;         
               };            
            }            
         }
            
      }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
      {
         // Here we should check if we should update the stop lost value for the sell position.
      }
   }
   else
   {  
      // We don't have any position yet so we should open one.
      ZeroMemory(mrequest);
      stop_lost = NormalizeDouble(latest_price.bid - mean_spread*_Point,_Digits);

      mrequest.action = TRADE_ACTION_DEAL;                                  // immediate order execution
      mrequest.price = NormalizeDouble(latest_price.ask,_Digits);           // latest ask price
      mrequest.sl = stop_lost;                                              // Stop Loss
      //mrequest.tp = NormalizeDouble(latest_price.ask + TKP*_Point,_Digits); // Take Profit
      mrequest.tp = 0.0; // Take Profit
      mrequest.symbol = _Symbol;                                            // currency pair
      mrequest.volume = num_lots;                                                 // number of lots to trade
      mrequest.magic = EA_Magic;                                             // Order Magic Number
      mrequest.type = ORDER_TYPE_BUY;                                        // Buy Order
      mrequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
      mrequest.deviation=100;                                                // Deviation from current price
      
      //--- send order
      if(!OrderSend(mrequest,mresult)) {
         Alert("Could not execute OrderSend -error:",GetLastError());
         ResetLastError();           
         return;         
      };
      
      // get the result code
      if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
      {
         // Alert("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
         Print("A Buy order has been successfully placed. Requested price ",latest_price.ask," got price ",mrequest.price," at time ",latest_price.time);
         // save the buy price:
         ref_price = mresult.price;
      }
      else
      {
         Alert("The Buy order request could not be completed -error:",GetLastError());
         ResetLastError();           
         return;
      }         
   }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
