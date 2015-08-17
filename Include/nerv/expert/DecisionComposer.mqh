#include <nerv/core.mqh>
#include <nerv/expert/CurrencyTrader.mqh>

/*
Class: nvDecisionComposer

Base class used to encapsulate a decision composition process.
*/
class nvDecisionComposer : public nvObject
{
protected:
  // Reference on the parent current trader:
  nvCurrencyTrader* _trader;

public:
  /*
    Class constructor.
  */
  nvDecisionComposer(nvCurrencyTrader* trader)
  {
    CHECK(trader,"Invalid currency trader parent.")
    _trader = trader;
  }

  /*
    Copy constructor
  */
  nvDecisionComposer(const nvDecisionComposer& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvDecisionComposer& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvDecisionComposer()
  {
    // No op.
  }
};
