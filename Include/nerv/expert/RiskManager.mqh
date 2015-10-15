#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/expert/PortfolioElement.mqh>
#include <nerv/expert/Market.mqh>

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
  double evaluateLotSize(nvMarket* market, string symbol, double numLostPoints, double traderWeight, double confidence)
  {
    CHECK_RET(0.0<=traderWeight && traderWeight <= 1.0,0.0,"Invalid trader weight: "<<traderWeight);

    // First we need to convert the current balance value in the desired profit currency:
    string quoteCurrency = nvGetQuoteCurrency(symbol);
    double balance = market.getBalance(quoteCurrency);

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

    // Now we need to check if this deal will not trigger a margin call error:
    int mode = (int)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
    CHECK_RET(mode==(int)ACCOUNT_STOPOUT_MODE_PERCENT,0.0,"Invalid margin mode: "<<mode);
    
    // Now check what would be the margin call value:
    double marginCall = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
    double marginStopOut = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double leverage = (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
    double currentMargin = AccountInfoDouble(ACCOUNT_MARGIN);

    // logDEBUG("Margin call level: "<<marginCall<<", margin stop out: "<<marginStopOut);

    // Get the current equity level (in account currency!)
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);

    // Check what quantity of the base currency we are considering here:
    double dealMargin = nvGetContractValue(symbol,lotsize);

    nvPriceManager* pm = getManager().getPriceManager();

    // Now we need to compute how much margin this deal would take us:
    // This will depend of the order type we plan to use:
    if(confidence>0.0) {
      // We are buying the base currency of the symbol by selling the quote currency
      // so we must have the quote currency value of what we buy.
      // The quote currency value is simply the dealValue multiplied by the current ask price:
      dealMargin *= pm.getAskPrice(symbol);

      // So dealValue is now the margin for this deal but expressed in the quote currency.
      // We should convert that into our account currency:
      dealMargin = pm.convertPrice(dealMargin,nvGetQuoteCurrency(symbol),nvGetAccountCurrency());
    }
    else {
      // We are selling the base currency of the symbol to buy the quote
      // So dealValue is what we are going to pay, so the margin for this deal, but still expressed in base currency
      // We need to convert this in our account currency:
      dealMargin = pm.convertPrice(dealMargin,nvGetBaseCurrency(symbol),nvGetAccountCurrency());
    }

    // apply the leverage on the margin:
    dealMargin /= leverage;



    // finally we should normalize the lot size:
    return nvNormalizeLotSize(lotsize,symbol);
  }
  
};
