#include <nerv/core.mqh>

#include <nerv/rnn/PredictionSignalFile.mqh>
#include <nerv/rnn/MultiTrader.mqh>

/*
Class: nvSecurityTrader

Base class representing a trader 
*/
class nvSecurityTrader : public nvMultiTrader
{
protected:
  // Last update time value, used to keep track
  // of the last time this trader was updated, to avoid double updates.
  datetime _lastUpdateTime;

  // Prediction signal:
  nvPredictionSignalFile* _predSignal;

  nvSecurity _security;

  // Threshold used to check if the signal we received is good enough
  // for an entry:
  double _entryThreshold;

  // Current value of the entry signal:
  double _lastEntrySignal;

  // Level of risk:
  double _riskLevel;
public:
  /*
    Class constructor.
  */
  nvSecurityTrader(string symbol)
    : _security(symbol)
  {
    logDEBUG("Creating Security Trader for "<<symbol)

    // Initialize the last update time:
    _lastUpdateTime = 0;

    // Load the prediction signal:
    _predSignal = new nvPredictionSignalFile("eval_results_v36.csv");

    // We enter only when the signal abs value is higher than:
    _entryThreshold = 0.6;

    // Last value of the entry signal:
    _lastEntrySignal = 0.0;

    // 1% of risk:
    _riskLevel = 0.01;
  }

  /*
    Copy constructor
  */
  nvSecurityTrader(const nvSecurityTrader& rhs) : _security("")
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvSecurityTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvSecurityTrader()
  {
    logDEBUG("Deleting SecurityTrader")
    RELEASE_PTR(_predSignal);
  }

  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once per minute
  */
  void update(datetime ctime)
  {
    if(_lastUpdateTime>=ctime)
      return; // Nothing to process.

    _lastUpdateTime = ctime;
    // logDEBUG("Update cycle at: " << ctime << " = " << (int)ctime)

    // Close the previous position if any:
    closePosition(_security);

    // Retrieve the prediction signal at that time:
    double pred = _predSignal.getPrediction(ctime);
    if(pred!=0.0) {

      if(hasPosition(_security))
      {
        // For now, do nothing if we are in an opened position.
      }
      else {
        openPosition(pred);
      }
    }
  }

  /*
  Function: openPosition
  
  Method used to open a position given a signal value
  */
  void openPosition(double signal)
  {
    // we are not currently in a trade so we check if we should enter one:
    if(MathAbs(signal)<=_entryThreshold)
      return; // Should not enter anything.

    logDEBUG("Using prediction signal " << signal)

    // the prediction is good enough, so we place a trade:
    _lastEntrySignal = signal;
    
    string symbol = _security.getSymbol();

    // Get the current spread to define the number of lost points:
    double spread = nvGetSpread(symbol);

    // double lot = evaluateLotSize(spread*2.0,1.0,signal);
    double lot = evaluateLotSize(100,1.0,signal);

    double sl = 0.0; //spread*nvGetPointSize(symbol);
    double tp = 0.0; //spread*nvGetPointSize(symbol);

    // Send the order:
    int otype = signal>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    sendDealOrder(_security, otype, lot, 0.0, sl, tp);
  }
  
  /*
  Function: evaluateLotSize
  
  Main method of this class used to evaluate the lot size that should be used for a potential trade.
  */
  double evaluateLotSize(double numLostPoints, double traderWeight, double confidence)
  {
    CHECK_RET(0.0<=traderWeight && traderWeight <= 1.0,0.0,"Invalid trader weight: "<<traderWeight);

    string symbol = _security.getSymbol();

    // First we need to convert the current balance value in the desired profit currency:
    string quoteCurrency = nvGetQuoteCurrency(symbol);
    double balance = nvGetBalance(quoteCurrency);

    // Now we determine what fraction of this balance we can risk:
    double VaR = balance * _riskLevel * traderWeight * MathAbs(confidence); // This is given in the quote currency.

    // Now we can compute the final lot size:
    // The worst lost we will achieve in the quote currency is:
    // VaR = lost = lotsize*contract_size*num_point
    // thus we need lotsize = VaR/(contract_size*numPoints) = VaR / (point_value * numPoints)
    // Also: we should prevent the lost point value to go too low !!
    double lotsize = VaR/(nvGetPointValue(symbol)*MathMax(numLostPoints,1.0));
    
    logDEBUG("Normalizing lotsize="<<lotsize<<", with lostPoints="<<numLostPoints<<", VaR="<<VaR
      <<", balance="<<balance<<", quoteCurrency="<<quoteCurrency<<", confidence="<<confidence
      <<", weight="<<traderWeight<<", riskLevel="<<_riskLevel);

    // logDEBUG("Margin call level: "<<marginCall<<", margin stop out: "<<marginStopOut);

    // We should not allow the trader to enter a deal with too big lot size,
    // otherwise, we could soon not be able to trade anymore.
    // So we should also apply the risk level trader weight and confidence level on this max lot size:
    if (lotsize>5.0)
    {
      logDEBUG("Clamping lot size to 5.0")
      lotsize = 5.0;
    }

    // Compute the new margin level:
    // double marginLevel = lotsize>0.0 ? 100.0*(equity+dealEquity)/(currentMargin+dealMargin) : 0.0;

    // if(lotsize>maxlot) { //0 && marginLevel<=marginCall
    //   logDEBUG("Detected margin call conditions: "<<lotsize<<">="<<maxlot);
    // }

    // finally we should normalize the lot size:
    lotsize = nvNormalizeLotSize(lotsize,symbol);

    return lotsize;
  }

  void onTick()
  {
    // Should handle onTick  here.
  }
};
