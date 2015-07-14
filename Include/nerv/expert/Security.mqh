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
  nvSecurity(string symbol, int digits, double point)
  {
    _symbol = symbol;
    _digits = digits;
    _point = point;
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
