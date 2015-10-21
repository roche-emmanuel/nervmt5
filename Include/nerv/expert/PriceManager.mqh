#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/expert/PortfolioElement.mqh>

/*
Class: nvPriceManager

Component used to retrieve the currency prices as precisely as we can.
It will handle generating tick data for history prices if necessary.
*/
class nvPriceManager : public nvPortfolioElement
{
public:
  /*
    Class constructor.
  */
  nvPriceManager()
  {
  }

  /*
    Copy constructor
  */
  nvPriceManager(const nvPriceManager& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvPriceManager& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvPriceManager()
  {
    // No op.
  }

  /*
  Function: getBidPrice
  
  Retrieve the bid price at any given time
  */
  double getBidPrice(string symbol, datetime time = 0)
  {
    // Retrieve the target time from the manager if needed:
    if(time==0) {
      time = getManager().getCurrentTime();
    }

    // If the target time happens to be the server time, then this means we can use the latest tick available
    if(time == TimeCurrent())
    {
      // Use the latest tick data:
      MqlTick last_tick;
      // Note that the following code may fail if we are on the week end,
      // And connected to a server, and we didn't receive anything yet:
      if(SymbolInfoTick(symbol,last_tick)) {
        return last_tick.bid;
      }
      else {
        logWARN("Cannot retrieve the latest tick from server")
      }
    }

    // Fallback implementation:
    // Use the bar history:
    MqlRates rates[];
    CHECK_RET(CopyRates(symbol,PERIOD_M1,time,1,rates)==1,false,"Cannot copy the rates at time: "<<time);

    // For now we just return the typical price during that minute:
    // Prices definition found on: https://www.mql5.com/en/docs/constants/indicatorconstants/prices
    // double price = (rates[0].high + rates[0].low + rates[0].close)/3.0;

    double price = (time - rates[0].time) < 30 ? rates[0].open : rates[0].close;
    return price;      
  }
  
  /*
  Function: getAskPrice
  
  Retrieve the ask price at any given time
  */
  double getAskPrice(string symbol, datetime time = 0)
  {
    // Retrieve the target time from the manager if needed:
    if(time==0) {
      time = getManager().getCurrentTime();
    }

    // If the target time happens to be the server time, then this means we can use the latest tick available
    if(time == TimeCurrent())
    {
      // Use the latest tick data:
      MqlTick last_tick;
      // Note that the following code may fail if we are on the week end,
      // And connected to a server, and we didn't receive anything yet:
      if(SymbolInfoTick(symbol,last_tick)) {
        return last_tick.ask;
      }
      else {
        logWARN("Cannot retrieve the latest tick from server")
      }
    }

    // Fallback implementation:
    // Use the bar history:
    MqlRates rates[];
    CHECK_RET(CopyRates(symbol,PERIOD_M1,time,1,rates)==1,false,"Cannot copy the rates at time: "<<time);

    // For now we just return the typical price during that minute:
    // Prices definition found on: https://www.mql5.com/en/docs/constants/indicatorconstants/prices
    // double price = (rates[0].high + rates[0].low + rates[0].close)/3.0;

    // Instead of returning a typical price we can return the open price if we are close enough to the opening of the bar:
    // This is a valid approximation as long as we keep working with a resolution of 1 minute:
    double price = (time - rates[0].time) < 30 ? rates[0].open : rates[0].close;
    return price+rates[0].spread*nvGetPointSize(symbol);      
  }
  
  /*
  Function: convertPriceFlat
  
  Perform a flat price conversion using only the bid price.
  */
  double convertPriceFlat(double price, string srcCurrency, string destCurrency, datetime time = 0)
  {
    int srcDigits = 2;
    if(srcCurrency=="JPY") {
      srcDigits = 0;
    }

    // Convert the input price given the number of digit precision:
    price = NormalizeDouble( price, srcDigits );

    if(srcCurrency==destCurrency)
      return price;
    
    if(time==0) {
      time = getManager().getCurrentTime();
    }

    int destDigits = 2;
    if(destCurrency=="JPY") {
      destDigits = 0;
    }

    string symbol1 = srcCurrency+destCurrency;
    string symbol2 = destCurrency+srcCurrency;

    if(nvIsSymbolValid(symbol1))
    {
      // Then we retrieve the current symbol1 value:
      return NormalizeDouble(price*getBidPrice(symbol1,time),destDigits);
    }
    else if(nvIsSymbolValid(symbol2))
    {
      // Then we retrieve the current symbol2 value:
      return NormalizeDouble(price/getBidPrice(symbol2,time),destDigits);
    }
    
    THROW("Unsupported currency names: "<<srcCurrency<<", "<<destCurrency);
    return 0.0;     
  }
  
  /*
  Function: convertPrice
  
  Method called to convert prices between currencies
  */
  double convertPrice(double price, string srcCurrency, string destCurrency, datetime time=0)
  {
    int srcDigits = 2;
    if(srcCurrency=="JPY") {
      srcDigits = 0;
    }

    // Convert the input price given the number of digit precision:
    price = NormalizeDouble( price, srcDigits );

    if(srcCurrency==destCurrency)
      return price;

    if(time==0) {
      time = getManager().getCurrentTime();
    }

    int destDigits = 2;
    if(destCurrency=="JPY") {
      destDigits = 0;
    }

    // If the currencies are not the same, we have to do the convertion:
    string symbol1 = srcCurrency+destCurrency;
    string symbol2 = destCurrency+srcCurrency;

    if(nvIsSymbolValid(symbol1))
    {
      // Then we retrieve the current symbol1 value:
      double bid = getBidPrice(symbol1,time);

      // we want to convert into the "quote" currency here, so we should get the smallest value out of it,
      // And thus ise the bid price:
      return NormalizeDouble(price * bid, destDigits);
    }
    else if(nvIsSymbolValid(symbol2))
    {
      // Then we retrieve the current symbol2 value:
      double ask = getAskPrice(symbol2,time);

      // we want to buy the "base" currency here so we have to divide by the ask price in that case:
      return NormalizeDouble(price / ask, destDigits); // ask is bigger than bid, so we get the smallest value out of it.
    }
    
    THROW("Unsupported currency names: "<<srcCurrency<<", "<<destCurrency);
    return 0.0;  
  }
  
  /*
  Function: convertPriceInv
  
  Inverse method for price convertion. This method will tell us how many unit of the 
  source currency we should sell to get the specified quantity in the dest currency. 
  */
  double convertPriceInv(double price, string srcCurrency, string destCurrency, datetime time = 0)
  {

    int srcDigits = 2;
    if(srcCurrency=="JPY") {
      srcDigits = 0;
    }

    // Convert the input price given the number of digit precision:
    price = NormalizeDouble( price, srcDigits );

    if(srcCurrency==destCurrency)
      return price;

    if(time==0) {
      time = getManager().getCurrentTime();
    }

    int destDigits = 2;
    if(destCurrency=="JPY") {
      destDigits = 0;
    }

    // If the currencies are not the same, we have to do the convertion:
    string symbol1 = srcCurrency+destCurrency;
    string symbol2 = destCurrency+srcCurrency;

    if(nvIsSymbolValid(symbol1))
    {
      // Then we retrieve the current symbol1 value:
      double bid = getBidPrice(symbol1,time);

      // we want to convert into the "quote" currency here, so we should get the smallest value out of it,
      // And thus ise the bid price:
      return  NormalizeDouble(price / bid,destDigits);
    }
    else if(nvIsSymbolValid(symbol2))
    {
      // Then we retrieve the current symbol2 value:
      double ask = getAskPrice(symbol2,time);

      // we want to buy the "base" currency here so we have to divide by the ask price in that case:
      return NormalizeDouble(price * ask,destDigits); // ask is bigger than bid, so we get the smallest value out of it.
    }

    THROW("Unsupported currency names: "<<srcCurrency<<", "<<destCurrency);
    return 0.0;      
  }
  
};
