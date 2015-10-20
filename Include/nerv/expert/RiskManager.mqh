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
  Function: computeBuyDetails
  
  Method used to compute what should be the margin/equity value after
  a given buy deal is entered. Note that we do not enter the deal just yet
  here.
  */
  void computeBuyDetails(string symbol, double lot, double& margin, double& equity)
  {
    nvPriceManager* pm = getManager().getPriceManager();

    string baseCur = nvGetBaseCurrency(symbol);
    string quoteCur = nvGetQuoteCurrency(symbol);
    string accCur = nvGetAccountCurrency();
    double leverage = (double)AccountInfoInteger(ACCOUNT_LEVERAGE);

    // Check what quantity of the base currency we are considering here:
    double baseVal = nvGetContractValue(symbol,lot);

    // Compute how much of the quote currency we need to buy this quantity of the base:
    double quoteVal = pm.convertPriceInv(baseVal,quoteCur,baseCur);

    // check the previous computation:
    double inv = pm.convertPrice(quoteVal,quoteCur,baseCur);
    CHECK(MathAbs(inv-baseVal)<1e-6,"Mismatch in computed values: "<<baseVal<<"!="<<inv);

    // Compute what quantity of the account currency we need to buy the previous quoteVal:
    // Don't forget to take the leverage into account:
    margin = pm.convertPriceInv(quoteVal,accCur,quoteCur)/leverage;

    // Now compute the immediate equity value of this position once opened:
    // we have baseVal, that we should convert back to quote currency:
    double quoteVal2 = pm.convertPrice(baseVal,baseCur,quoteCur);

    // From this value, we should refund what initially borrowed to place the deal:
    // but note that this profit value is still expressed in te quote currency.
    double profit = quoteVal2 - quoteVal;

    // So finaly, we need to convert this into our account currency...
    // If the profit is positive, then we convert back normally:
    if(profit>0.0) {
      equity = pm.convertPrice(profit,quoteCur,accCur);
    }
    else {
      // If the profit is negative then this rather means that we should convert from our account
      // currency to the quote currency to complete the refund:
      // We need to get "profit" in quote, by buying it from acc.
      // |profit| = pm.convertPrice(|equity|,accCur,quoteCur)
      equity = - pm.convertPriceInv(-profit,accCur,quoteCur);
    }
  }
  
  /*
  Function: computeSellDetails
  
  Method used to compute what should be the margin/equity value after
  a given sell deal is entered. Note that we do not enter the deal just yet
  here.
  */
  void computeSellDetails(string symbol, double lot, double& margin, double& equity)
  {
    nvPriceManager* pm = getManager().getPriceManager();

    string baseCur = nvGetBaseCurrency(symbol);
    string quoteCur = nvGetQuoteCurrency(symbol);
    string accCur = nvGetAccountCurrency();
    double leverage = (double)AccountInfoInteger(ACCOUNT_LEVERAGE);

    // Check what quantity of the base currency we are considering here:
    double baseVal = nvGetContractValue(symbol,lot);

    // Compute how much of the quote currency we get when selling this quantity of the base:
    double quoteVal = pm.convertPrice(baseVal,baseCur,quoteCur);

    // Compute what quantity of the account currency we need to buy the previous baseVal:
    // Don't forget to take the leverage into account:
    margin = pm.convertPriceInv(baseVal,accCur,baseCur)/leverage;

    // Now compute the immediate equity value of this position once opened:
    // we have quoteVal, that we should convert back to base currency:
    double baseVal2 = pm.convertPrice(quoteVal,quoteCur,baseCur);

    // From this value, we should refund what initially borrowed to place the deal:
    // but note that this profit value is still expressed in the base currency.
    double profit = baseVal2 - baseVal;

    // So finaly, we need to convert this into our account currency...
    // If the profit is positive, then we convert back normally:
    if(profit>0.0) {
      equity = pm.convertPrice(profit,baseCur,accCur);
    }
    else {
      // If the profit is negative then this rather means that we should convert from our account
      // currency to the quote currency to complete the refund:
      // We need to get "profit" in base, by buying it from acc.
      // |profit| = pm.convertPrice(|equity|,accCur,baseCur)
      equity = - pm.convertPriceInv(-profit,accCur,baseCur);
    }
  }

  /*
  Function: computeMaxLotSize
  
  Compute the max lot size, to enter a given deal on a given symbol
  considering the current margin and equity values and the broker margin call 
  level.
  */
  double computeMaxLotSize(string symbol, double confidence)
  {
    // Now we need to check if this deal will not trigger a margin call error:
    int mode = (int)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
    CHECK_RET(mode==(int)ACCOUNT_STOPOUT_MODE_PERCENT,0.0,"Invalid margin mode: "<<mode);
    
    // Now check what would be the margin call value:
    double marginCall = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)/100.0;
    // double marginStopOut = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
    // double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
  
    // Get the current equity level (in account currency!)
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
  
    // Compute the modification on the margin and equity we would get from this deal when applied:
    double dealMargin = 0.0;
    double dealEquity = 0.0;
    if(confidence>0.0) {
      computeBuyDetails(symbol,1.0,dealMargin,dealEquity);
    }
    else {
      computeSellDetails(symbol,1.0,dealMargin,dealEquity);
    }    
    
    // We can now solve for the lot value with:
    // marginCall = (equity + dealEquity * lot)/(margin + dealMargin * lot)
    double v1 = marginCall*margin - equity;
    double v2 = dealEquity - marginCall*dealMargin;
    double maxlot = v1/v2;
    return maxlot;
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

    // logDEBUG("Margin call level: "<<marginCall<<", margin stop out: "<<marginStopOut);

    double maxlot = computeMaxLotSize(symbol,confidence);


    // We should not allow the trader to enter a deal with too big lot size,
    // otherwise, we could soon not be able to trade anymore.
    // So we should also apply the risk level trader weight and confidence level on this max lot size:
    lotsize = MathMin(lotsize, maxlot*_riskLevel*traderWeight*MathAbs(confidence));

    // Compute the new margin level:
    // double marginLevel = lotsize>0.0 ? 100.0*(equity+dealEquity)/(currentMargin+dealMargin) : 0.0;

    // if(lotsize>maxlot) { //0 && marginLevel<=marginCall
    //   logDEBUG("Detected margin call conditions: "<<lotsize<<">="<<maxlot);
    // }

    // finally we should normalize the lot size:
    lotsize = nvNormalizeLotSize(lotsize,symbol);

    return lotsize;
  }
  
};
