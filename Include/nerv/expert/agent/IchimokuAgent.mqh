#include <nerv/core.mqh>
#include <nerv/expert/TradingAgent.mqh>

/*
Class: nvIchimokuAgent

Class used as a base class to represent a trading agent in a given
currency trader.
*/
class nvIchimokuAgent : public nvTradingAgent
{

protected:
  int _ichiHandle;
  double _tenkanVal[];
  double _kijunVal[];
  double _senkouAVal[];
  double _senkouBVal[];
  double _chinkouVal[];
  MqlRates _rates[];

public:
  /*
    Class constructor.
  */
  nvIchimokuAgent(nvCurrencyTrader* trader) : nvTradingAgent(trader)
  {
    _agentType = TRADE_AGENT_ICHIMOKU;
    _agentCapabilities = TRADE_AGENT_ENTRY_EXIT;
    _ichiHandle = 0;
    // randomize();
  }

  /*
    Copy constructor
  */
  nvIchimokuAgent(const nvIchimokuAgent& rhs) : nvTradingAgent(rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvIchimokuAgent& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvIchimokuAgent()
  {
    if(_ichiHandle>0) {
      IndicatorRelease(_ichiHandle);
    }
  }
 
  /*
  Function: randomize
  
  Method called to randomize the values of the parameters for this agent.
  */
  virtual void randomize()
  {
    randomizeLag(AGENT_MAX_LAG);
    randomizePeriod(PERIOD_H1,PERIOD_D1);
  }
  
  /*
  Function: clone
  
  Method called to clone this agent
  */
  virtual nvTradingAgent* clone()
  {
    // We should not be able to clone this base class by default:
    nvTradingAgent* agent = new nvIchimokuAgent(_trader);
    return agent;
  }
  
  /*
  Function: initialize
  
  Method called to initialize this trader on due time
  */
  virtual void initialize()
  {
    // At this point we can initialize the agent ressources:
    _ichiHandle=iIchimoku(_symbol,_period,9,26,52);
    CHECK(_ichiHandle>0,"Invalid Ichimoku handle");

    ArraySetAsSeries(_tenkanVal,true);
    ArraySetAsSeries(_kijunVal,true);
    ArraySetAsSeries(_senkouAVal,true);
    ArraySetAsSeries(_senkouBVal,true);
    ArraySetAsSeries(_chinkouVal,true);
    ArraySetAsSeries(_rates,true);

  }

  /*
  Function: checkBuyConditions
  
  Helper method to check for buy conditions for ichimoku
  */
  bool checkBuyConditions()
  {
    // We can only buy when the close price is above the cloud:
    if(_rates[0].close < _senkouAVal[0] || _rates[0].close < _senkouBVal[0])
    {
      return false;
    }

    // We should also ensure that the kijun itself is above the cloud:
    if(_kijunVal[0] <= _senkouAVal[0] || _kijunVal[0] <= _senkouBVal[0])
    {
      return false;
    }

    // We must also ensure that tenkan sen line is above the kijun sen line at that time:
    if(_tenkanVal[0] <= _kijunVal[0])
    {
      return false;
    }

    // Do not buy if the price is not above this limit (?)
    if(_rates[0].close <= _tenkanVal[0])
    {
      return false;
    }

    return true;
    // TODO: we could also add a signal from the chinkou line here    
  }
  
  /*
  Function: checkSellConditions
  
  Helper method used to check for sell conditions
  */
  bool checkSellConditions()
  {
    // We can only sell when the close price is above the cloud:
    if(_rates[0].close > _senkouAVal[0] || _rates[0].close > _senkouBVal[0])
    {
      return false;
    }

    // We should also ensure that the kijun itself is under the cloud:
    if(_kijunVal[0] >= _senkouAVal[0] || _kijunVal[0] >= _senkouBVal[0])
    {
      return false;
    }

    // We must also ensure that tenkan sen line is above the kijun sen line at that time:
    if(_tenkanVal[0] >= _kijunVal[0])
    {
      return false;
    }

    // Do not sell if the price is not under this limit (?)
    if(_rates[0].close >= _tenkanVal[0])
    {
      return false;
    }

    return true;
    // TODO: we could also add a signal from the chinkou line here    
  }

  /*
  Function: doUpdate
  
  Method used to handle the receiption of an update request
  */
  virtual void doUpdate()
  {
    int num = 1;

    CHECK(CopyRates(_symbol,_period,_currentTime,num,_rates)==num,"Cannot copy the latest rates");
    // logDEBUG(_currentTime<<": "<<_symbol<<" Retrieving ichimoku data from handle: "<<_ichiHandle);

    CHECK(CopyBuffer(_ichiHandle,0,_currentTime,num,_tenkanVal)==num,"Cannot copy Ichimoku buffer 0");
    CHECK(CopyBuffer(_ichiHandle,1,_currentTime,num,_kijunVal)==num,"Cannot copy Ichimoku buffer 1");
    CHECK(CopyBuffer(_ichiHandle,2,_currentTime,4,_senkouAVal)==4,"Cannot copy Ichimoku buffer 2");
    CHECK(CopyBuffer(_ichiHandle,3,_currentTime,4,_senkouBVal)==4,"Cannot copy Ichimoku buffer 3");
    CHECK(CopyBuffer(_ichiHandle,4,_currentTime,30,_chinkouVal)==30,"Cannot copy Ichimoku buffer 4");
    
    // logDEBUG(_currentTime << ": tenkanVal[0]="<<_tenkanVal[0]<<", tenkanVal[1]="<<_tenkanVal[1]);
  }
  
  /*
  Function: computeEntryDecision
  
  Method called to compute the entry decision taking into account the lag of this agent.
  This method should be reimplemented by derived classes that can provide entry decision.
  */
  virtual double computeEntryDecision()
  {
    if(Bars(_symbol,_period)<60)
    {
      return 0.0; // do not compute anything.
    }

    // Entry is only called when we are not in a position, so we should have no position
    // here:
    CHECK_RET(_trader.hasOpenPosition()==false,0.0,"Should not have an open position here");

    if(checkBuyConditions()) {
      logDEBUG("producing buy signal with: "
        << " close="<<_rates[0].close 
        << ", tenkan="<<_tenkanVal[0]
        << ", kijun="<<_kijunVal[0]
        << ", spanA="<<_senkouAVal[0]
        << ", spanB="<<_senkouBVal[0]
        )
      return 1.0; // produce a buy signal.
    }

    if(checkSellConditions()) {
      logDEBUG("producing sell signal with: "
        << " close="<<_rates[0].close 
        << ", tenkan="<<_tenkanVal[0]
        << ", kijun="<<_kijunVal[0]
        << ", spanA="<<_senkouAVal[0]
        << ", spanB="<<_senkouBVal[0]
        )
      return -1.0; // produce a sell signal
    }

    // Produce no signal at all:
    return 0.0;
  }
  
  /*
  Function: computeExitDecision
  
  Method called to compute the exit decision taking into account the lag of this agent.
  This method should be reimplemented by derived classes that can provide exit decision. 
  */
  virtual double computeExitDecision()
  {
    if(Bars(_symbol,_period)<60)
    {
      return 0.0; // do not compute anything.
    }
    
    PositionType pos = _trader.getPositionType();

    if( (pos==POS_LONG && _tenkanVal[0]<_kijunVal[0]) || (pos==POS_SHORT && _tenkanVal[0]>_kijunVal[0]) )
    {
      logDEBUG(_currentTime<<": Suggesting position close due to tenkan <-> kijun cross.");
      logDEBUG("Closing with: "
      << " close="<<_rates[0].close 
      << ", tenkan="<<_tenkanVal[0]
      << ", kijun="<<_kijunVal[0]
      << ", spanA="<<_senkouAVal[0]
      << ", spanB="<<_senkouBVal[0]
      )
      return pos==POS_LONG ? -1.0 : 1.0;
    }
    else if ( (pos==POS_LONG && _rates[0].close<_kijunVal[0]) || (pos==POS_SHORT && _rates[0].close>_kijunVal[0]) )  //(_rates[0].close - _kijunVal[0]) * (_rates[1].close - _kijunVal[1]) < 0.0)
    {
      logDEBUG(_currentTime<<": Suggesting position close due to price <-> kijun cross.")
      logDEBUG("Closing with: "
      << " close="<<_rates[0].close 
      << ", tenkan="<<_tenkanVal[0]
      << ", kijun="<<_kijunVal[0]
      << ", spanA="<<_senkouAVal[0]
      << ", spanB="<<_senkouBVal[0]
      )
      return pos==POS_LONG ? -1.0 : 1.0;
    }
   
    return 0.0;
  }
};
