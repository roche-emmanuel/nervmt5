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
  Security(string symbol, int digits, double point)
  {
    _symbol = symbol;
    _digits = digits;
    _point = point;
  }

  /*
  Function: getSymbol
  
  Retrieve the symbol corresponding to this security.
  */
  string getSymbol()
  {
    return _symbol;
  }
  
  /*
  Function: getDigits
  
  Retrieve the number of digits corresponding to this security.
  */
  int getDigits()
  {
    return _digits;
  }
  
  /*
  Function: getPoint
  
  Retrieve the size of the smallest point increment for this security.
  */
  double getPoint()
  {
    return _point;
  }
  
};
