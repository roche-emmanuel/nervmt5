#include <nerv/core.mqh>

/*
Class: nvRiskManager

Component used to control the risk in the traders performed by all currency traders.
There is one copy of this element in the PortfolioManager
*/
class nvRiskManager : public nvObject
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
    _accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
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
    nvPortfolioManager* man = nvPortfolioManager::instance();

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(currencyName!=_accountCurrency)
    {
      // If the requested currency is not the account currency then we have to do the convertion:
      string symbol1 = _accountCurrency+currencyName;
      string symbol2 = currencyName+_accountCurrency;

      if(man.isSymbolValid(symbol1))
      {
        // Then we retrieve the current symbol1 value:
        MqlTick latest_price;
        CHECK_RET(SymbolInfoTick(symbol1,latest_price),0.0,"Cannot retrieve latest price.");

        // To convert into the desired currency we have to multiply the value in that case:
        balance *= latest_price.bid; // bid is smaller than ask, so we get the smallest value of the balance here.
      }
      else if(man.isSymbolValid(symbol2))
      {
        // Then we retrieve the current symbol2 value:
        MqlTick latest_price;
        CHECK_RET(SymbolInfoTick(symbol2,latest_price),0.0,"Cannot retrieve latest price.");

        // To convert into the desired currency we have to multiply the value in that case:
        balance /= latest_price.ask; // ask is bigger than bid, so we get the smallest value of the balance here.
      }
      else {
        CHECK_RET(false,0.0,"Unsupported currency name: "<<currencyName)
      }
    }

    return balance;
  }
  
  /*
  Function: evaluateLotSize
  
  Main method of this class used to evaluate the lot size that should be used for a potential trade.
  */
  double evaluateLotSize(string profitCurrency, int numLostPoints, double traderWeight)
  {
    // First we need to convert the current balance value in the desired profit currency:
    double balance = getBalanceValue(profitCurrency);
    return balance;
  }
  
};
