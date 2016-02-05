#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvPatternTrader

Base class representing a trader 
*/
class nvPatternTrader : public nvSecurityTrader {
protected:
  bool _useTicks;
  int _inputSize;
  
public:
  /*
    Class constructor.
  */
  nvPatternTrader(string symbol, bool useTicks, int inputSize)
    : nvSecurityTrader(symbol), _useTicks(useTicks), _inputSize(inputSize)
  {
    logDEBUG("Creating PatternTrader")
  }

  /*
    Class destructor.
  */
  ~nvPatternTrader()
  {
    logDEBUG("Deleting PatternTrader")
  }
  
  virtual void onTick()
  {
    logDEBUG(TimeCurrent() << ": In PatternTrader:onTick()")
  }
};
