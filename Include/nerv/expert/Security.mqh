#include <nerv/core.mqh>

/* Class used to describe a security. */
class nvSecurity : public nvObject
{
protected:
  string _symbol;
  int _digits;
  double _point;

public:
  /*
  Function: Security
  
  Class cosntructor
  */
  nvSecurity(string symbol)
  {

    // First we should ensure that this symbol exits on the market, 
    // we throw an error otherwise:
    CHECK(symbol!="","Empty symbol string.")

    _symbol = "";
    int num = SymbolsTotal(false);
    string sname = "";
    for(int i=0;i<num;++i)
    {
      sname = SymbolName(i,false);
      if(symbol==sname)
      {
        // We found a valid symbol, so we can keep a reference on it:
        _symbol = symbol;
        SymbolSelect(_symbol,true);
        _point = SymbolInfoDouble(_symbol,SYMBOL_POINT);
        _digits = (int)SymbolInfoInteger(_symbol,SYMBOL_DIGITS);
      }
    }

    CHECK(_symbol!="","Could not find symbol "<<symbol)
  }

  /*
    Copy constructor
  */
  nvSecurity(const nvSecurity& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvSecurity& rhs)
  {
    _symbol = rhs._symbol;
    _digits = rhs._digits;
    _point = rhs._point;
  }

  /*
  Function: getSymbol
  
  Retrieve the symbol corresponding to this security.
  */
  string getSymbol() const
  {
    return _symbol;
  }
  
  /*
  Function: getDigits
  
  Retrieve the number of digits corresponding to this security.
  */
  int getDigits() const
  {
    return _digits;
  }
  
  /*
  Function: getPoint
  
  Retrieve the size of the smallest point increment for this security.
  */
  double getPoint() const
  {
    return _point;
  }
  
};
