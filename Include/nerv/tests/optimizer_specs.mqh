
#include <nerv/unit/Testing.mqh>
#include <nerv/math/Optimizer.mqh>

// Example taken from: http://www.alglib.net/translator/man/manual.cpp.html#example_mincg_d_1
class MyFunc1 : public nvOptimizer
{
public:
	virtual double compute(double &x[], double &grad[])
  {
    //
    // this callback calculates f(x0,x1) = 100*(x0+3)^4 + (x1-3)^4
    // and its derivatives df/d0 and df/dx1
    //
    double func = 100*pow(x[0]+3,4) + pow(x[1]-3,4);
    grad[0] = 400*pow(x[0]+3,3);
    grad[1] = 4*pow(x[1]-3,3);
    return func;
  }  
};

// Example taken from: http://www.alglib.net/translator/man/manual.cpp.html#example_mincg_ftrim
class MyFunc2 : public nvOptimizer
{
public:
	double compute(double &x[], double &grad[])
  {
    //
    // this callback calculates f(x) = (1+x)^(-0.2) + (1-x)^(-0.3) + 1000*x and its gradient.
    //
    // function is trimmed when we calculate it near the singular points or outside of the [-1,+1].
    // Note that we do NOT calculate gradient in this case.
    //
    if( (x[0]<=-0.999999999999) || (x[0]>=+0.999999999999) )
    {
      return 1.0E+300;
    }

    grad[0] = -0.2*pow(1+x[0],-1.2) +0.3*pow(1-x[0],-1.3) + 1000;
    return pow(1+x[0],-0.2) + pow(1-x[0],-0.3) + 1000*x[0];
  }
};

// Generalized RosenBrock function optimization 
class MyFunc3 : public nvOptimizer
{
public:
	void computeGradient(double &x[], double &grad[])
  {
    //
    // this callback calculates f(x) = 
    // and its derivatives df/d0 and df/dx1
    //
    int num = ArraySize( x );
    for(int i=0;i<num;++i)
    {

    	grad[i]=0.0;
    	if(i<num-1)
    	{
    		grad[i]+=2*(x[i]-1)-400.0*x[i]*(x[i+1] - x[i]*x[i]);
    	}
    	if(i>0)
    	{
    		grad[i]+=200.0*(x[i] - x[i-1]*x[i-1]);
    	}
    }
  }

  double computeCost(double &x[])
  {
    int num = ArraySize( x );
    double val = 0;
    double v1, v2;
    for(int i=0;i<num;++i)
    {
    	if(i<num-1)
    	{
	  		v1 = (x[i]-1);
	  		v2 = (x[i+1] - x[i]*x[i]);
	  		val += v1*v1 + 100.0 * v2*v2;
	  	}
		}

    return val;
  }
};

// Simple quadradic function
class MyFunc4 : public nvOptimizer
{
public:
	void computeGradient(double &x[], double &grad[])
  {
		grad[0] = 2*x[0] + 3*x[1];
		grad[1] = 3*x[0];
  }

  double computeCost(double &x[])
  {
  	return x[0]*x[0] + 3*x[0]*x[1];
  }
};

BEGIN_TEST_PACKAGE(optimizer_specs)

BEGIN_TEST_SUITE("Optimizer class")

BEGIN_TEST_CASE("should be able to create an Optimizer instance")
	nvOptimizer opt;
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with CG test 1")
	MyFunc1 opt;
	double x[] = {0,0};
	opt.setStopConditions(1e-10,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_cg(x,cost);
	ASSERT_EQUAL(res,4);
	ASSERT_CLOSEDIFF(x[0],-3.0,1e-4);
	ASSERT_CLOSEDIFF(x[1],3.0,1e-4);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with CG test 2")
	MyFunc2 opt;
	double x[] = {0};
	opt.setStopConditions(1e-6,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_cg(x,cost);
	ASSERT_EQUAL(res,4);
	ASSERT_CLOSEDIFF(x[0],-0.99917305,1e-7);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with LBFGS test 1")
	MyFunc1 opt;
	double x[] = {0,0};
	opt.setStopConditions(1e-12,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_lbfgs(x,cost,1);
	ASSERT_EQUAL(res,4);
	ASSERT_CLOSEDIFF(x[0],-3.0,1e-4);
	ASSERT_CLOSEDIFF(x[1],3.0,1e-4);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with LBFGS test 2")
	MyFunc2 opt;
	double x[] = {0};
	opt.setStopConditions(1e-8,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_lbfgs(x,cost,1);
	ASSERT_EQUAL(res,1);
	ASSERT_CLOSEDIFF(x[0],-0.99917305,1e-7);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with CG test 3")
	MyFunc3 opt;
	int dim = 30;

	double x[];
	ArrayResize( x, dim );
	for(int i=0;i<dim;++i)
	{
		x[i] = -1.0;
	}
	opt.setStopConditions(1e-12,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_cg(x,cost);
	ASSERT_EQUAL(res,4);
	for(int i=0;i<dim;++i)
	{
		ASSERT_CLOSEDIFF(x[i],1.0,1e-12);
	}
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with LBFGS test 3")
	MyFunc3 opt;
	int dim = 30;

	double x[];
	ArrayResize( x, dim );
	for(int i=0;i<dim;++i)
	{
		x[i] = -1.0;
	}
	opt.setStopConditions(1e-12,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_lbfgs(x,cost);
	ASSERT_EQUAL(res,4);
	for(int i=0;i<dim;++i)
	{
		ASSERT_CLOSEDIFF(x[i],1.0,1e-12);
	}
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to check gradients")
  MyFunc4 opt;
  double x[] = {4, 10};
  double diff = opt.checkGradient(x,0.0001);
  ASSERT_CLOSEDIFF(diff,2.1452e-12,1e-16)
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
