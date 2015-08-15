#include <nerv/core.mqh>

#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Class: nvOptimizer

Base class used to implement an optimizer based on cost function optimization.
*/
class nvOptimizer : public CNDimensional_Grad
{
public:
  /*
    Class constructor.
  */
  nvOptimizer()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvOptimizer(const nvOptimizer& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvOptimizer& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvOptimizer()
  {
    // No op.
  }
};
