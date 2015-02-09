//+------------------------------------------------------------------+
//|                                                   TickReader.mq5 |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

int fileHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  Print("I'm in OnInit() callback.");

  string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);
  Print("Terminal data path is: ", terminal_data_path);

  // Now we open the desired file for writing:
  string fname = "EURUSD_ticks.txt";

  fileHandle = FileOpen(fname, FILE_WRITE | FILE_CSV, ",");
  if (fileHandle == INVALID_HANDLE)
  {
    Print("Could not open file for writing: ", GetLastError());
  }
  else
  {
    Print("File open sucessfully.");
  }

  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  if (fileHandle != INVALID_HANDLE)
  {
    Print("Closing file handle.");
    FileClose(fileHandle);
  }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  // Print("I'm in OnTick() callback.");

  MqlTick last_tick;
  if (SymbolInfoTick(Symbol(), last_tick))
  {
    Print(last_tick.time, ": Bid = ", last_tick.bid,
          " Ask = ", last_tick.ask, "  Volume = ", last_tick.volume,
          " Last = ", last_tick.last);
  }
  else
  {
    Print("SymbolInfoTick() failed, error = ", GetLastError());
  }

  // Now write the tick data to the file:
  if(fileHandle!=INVALID_HANDLE) {
    FileWrite(fileHandle,last_tick.time,last_tick.bid,last_tick.ask);
  }
}
//+------------------------------------------------------------------+
