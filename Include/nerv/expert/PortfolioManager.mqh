#include <nerv/core.mqh>
#include <nerv/utils.mqh>

// Forward declaration of the currency trader class:
class nvCurrencyTrader;

/*
Class: nvPortfolioManager

This class represents the Portfolio manager of our expert implementation.
It is used as a singleton.
*/
class nvPortfolioManager : public nvObject
{
protected:
  // List of currency traders:
  nvCurrencyTrader* _traders[];

protected:
  // Following methods are protected to respect the singleton pattern

  /*
    Class constructor.
  */
  nvPortfolioManager()
  {
    // By default there should be no currency trader available:
    ArrayResize( _traders, 0 );
  }

  /*
    Copy constructor
  */
  nvPortfolioManager(const nvPortfolioManager& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvPortfolioManager& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvPortfolioManager()
  {
    // No op.
  }

public:
  // Retrieve the instance of this class:
  static nvPortfolioManager *instance()
  {
    static nvPortfolioManager singleton;
    return GetPointer(singleton);
  }

  /*
  Function: isSymbolValid
  
  Method used to check if a given symbol is valid.
  This will be used when a request to create a new CurrencyTrader is made.
  */
  bool isSymbolValid(string symbol)
  {
    int num = SymbolsTotal(false);
    for(int i=0;i<num;++i)
    {
      if(symbol==SymbolName(i,false))
      {
        return true;
      }
    }

    return false;
  }
  
  /*
  Function: getCurrencyTrader
  
  Iterate on the currency trader list to retrieve
  a specific trader by symbol:
  */
  nvCurrencyTrader* getCurrencyTrader(string symbol)
  {
    // Retrieve the current size of the list:
    int num = ArraySize( _traders );
    for(int i=0;i<num;++i)
    {
      if(_traders[i].getSymbol() == symbol)
      {
        return _traders[i];
      }
    }

    return NULL;
  }

  /*
  Function: addCurrencyTrader
  
  Method called to add a new currency trader with the given symbol.
  This call will return the newly created currency trader if successfull,
  and return NULL otherwise.
  */
  nvCurrencyTrader* addCurrencyTrader(string symbol)
  {
    // First we check if we already have a trader with the symbol:
    if(getCurrencyTrader(symbol))
    {
      logERROR("Trying to add already existing Currency Trader for symbol "<<symbol);
      return NULL;
    }

    // Check if the given symbol is valid:
    CHECK_RET(isSymbolValid(symbol),NULL,"Invalid symbol.")
    
    // Create a new trader:
    nvCurrencyTrader* trader = new nvCurrencyTrader(symbol);
    int num = ArraySize( _traders );
    ArrayResize( _traders, num+1 );
    _traders[num] = trader;
    return trader;
  }

  /*
  Function: removeCurrencyTrader
  
  Remove a currency trader by symbol
  */
  bool removeCurrencyTrader(string symbol)
  {
    int num = ArraySize( _traders );
    bool found = false;
    int i;
    for(i=0;i<num;++i)
    {
      if(_traders[i].getSymbol() == symbol)
      {
        // We should remove that trader from the list:
        RELEASE_PTR(_traders[i]);
        nvRemoveArrayItem(_traders,i);
        return true;
      }
    }

    return false;
  }
  
  /*
  Function: getNumCurrencyTraders
  
  Retrieve the number of currency traders available in this portfolio.
  */
  int getNumCurrencyTraders()
  {
    return ArraySize( _traders );
  }
  
  /*
  Function: removeAllCurrencyTraders
  
  Remove all the currency traders available in this portfolio.
  */
  void removeAllCurrencyTraders()
  {
    int num = ArraySize( _traders );
    for(int i=0;i<num;++i)
    {
      // We should remove that trader from the list:
      RELEASE_PTR(_traders[i]);
    }

    // Reset the content of the traders array:
    ArrayResize( _traders, 0 );    
  }
  
  /*
  Function: update
  
  Method called to update the complete state of this Portfolio Manager
  */
  void update()
  {
    logDEBUG(TimeLocal()<<": Updating Portfolio Manager.")
  }
  
};
