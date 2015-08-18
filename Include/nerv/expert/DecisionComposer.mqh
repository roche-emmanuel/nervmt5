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
  nvDecisionComposer()
  {
    _trader = NULL;
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

  /*
  Function: setCurrencyTrader
  
  Assign the currency trader owning this decision composer.
  */
  void setCurrencyTrader(nvCurrencyTrader* trader)
  {
    CHECK(trader,"Invalid currency trader parent.")
    _trader = trader;
  }
  
  /*
  Function: evaluate
  
  Main method used in the Decision composer to build a final decision by evaluating the
  input advices.
  This method should be Reimplemented in derived classes.
  */
  virtual double evaluate(double &inputs[])
  {
    // Throw error by default.
    THROW("No implementation");
    return 0.0;
  }
  
};

// First version of a Decision composer:
class nvRandomDecisionComposer : public nvDecisionComposer
{
protected:
  double _signal;
  double _adapt;

public:
  nvRandomDecisionComposer() : _signal(0.0), _adapt(0.01) {}

  /*
  Function: evaluate
  
  This version of the decision composer will simply return random decisions
  based on an adaptation process.
  */
  virtual double evaluate(double &inputs[])
  {
    SimpleRNG* rng = nvPortfolioManager::instance().getRandomGenerator();

    double val = (rng.GetUniform()-0.5)*2.0;
    _signal = _signal + _adapt * (val - _signal);
    return _signal;
  }
};