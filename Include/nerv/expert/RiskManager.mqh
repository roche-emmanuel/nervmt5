#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/expert/PortfolioElement.mqh>

/*
Class: nvRiskManager

Component used to control the risk in the traders performed by all currency traders.
There is one copy of this element in the PortfolioManager
*/
class nvRiskManager : public nvPortfolioElement
{
protected:
  // Level of risk that we can accept for a given trade:
  double _riskLevel;

  // The currency in which the balance is specified:
  string _accountCurrency;

public:
  /*
    Class constructor.
  */
  nvRiskManager()
  {
    // Default value for the risk level:
    _riskLevel = 0.0;

    // Initialize the balance currency since this will not change:
    _accountCurrency = nvGetAccountCurrency();
  }

  /*
    Copy constructor
  */
  nvRiskManager(const nvRiskManager& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRiskManager& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRiskManager()
  {
    // No op.
  }

  /*
  Function: setRiskLevel
  
  Assign the value of the risk level
  */
  void setRiskLevel(double level)
  {
    CHECK(level>0.0 && level<1.0,"Invalid value for the risk level: "<<level);
    _riskLevel = level;
  }
  
  /*
  Function: getRiskLevel
  
  Retrieve the current value of the risk level
  */
  double getRiskLevel()
  {
    return _riskLevel;
  }
  
  /*
  Function: getAccountCurrency
  
  Retrieve the name of the account currency in use.
  */
  string getAccountCurrency()
  {
    return _accountCurrency;
  }
  
  /*
  Function: getBalanceValue
  
  Retrieve the value of the current balance in the requested currency:
  */
  double getBalanceValue(string currencyName)
  {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // convert from account currency to the given currency:
    balance = getManager().getPriceManager().convertPrice(balance,_accountCurrency,currencyName);
    return balance;
  }
  
  /*
  Function: evaluateLotSize
  
  Main method of this class used to evaluate the lot size that should be used for a potential trade.
  */
  double evaluateLotSize(string symbol, double numLostPoints, double traderWeight, double confidence)
  {
    CHECK_RET(0.0<=traderWeight && traderWeight <= 1.0,0.0,"Invalid trader weight: "<<traderWeight);

    // First we need to convert the current balance value in the desired profit currency:
    string quoteCurrency = nvGetQuoteCurrency(symbol);
    double balance = getBalanceValue(quoteCurrency);

    // Now we determine what fraction of this balance we can risk:
    double VaR = balance * _riskLevel * traderWeight * MathAbs(confidence); // This is given in the quote currency.

    // Now we can compute the final lot size:
    // The worst lost we will achieve in the quote currency is:
    // VaR = lost = lotsize*contract_size*num_point
    // thus we need lotsize = VaR/(contract_size*numPoints) = VaR / (point_value * numPoints)
    double lotsize = VaR/(nvGetPointValue(symbol)*numLostPoints);
    
    // finally we should normalize the lot size:
    return nvNormalizeLotSize(lotsize,symbol);
  }
  
};
