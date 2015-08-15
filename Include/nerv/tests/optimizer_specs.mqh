
#include <nerv/unit/Testing.mqh>
#include <nerv/math/Optimizer.mqh>

BEGIN_TEST_PACKAGE(optimizer_specs)

BEGIN_TEST_SUITE("Optimizer class")

BEGIN_TEST_CASE("should be able to create an Optimizer instance")
	nvOptimizer opt;
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with CG test 1")
	// Example taken from: http://www.alglib.net/translator/man/manual.cpp.html#example_mincg_d_1
	class MyFunc : public nvOptimizer
	{
	public:
		double computeCost(double &x[], double &grad[])
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

	MyFunc opt;
	double x[] = {0,0};
	opt.setStopConditions(1e-10,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_cg(x,cost);
	ASSERT_EQUAL(res,4);
	ASSERT_CLOSEDIFF(x[0],-3.0,1e-4);
	ASSERT_CLOSEDIFF(x[1],3.0,1e-4);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with CG test 2")
	// Example taken from: http://www.alglib.net/translator/man/manual.cpp.html#example_mincg_ftrim
	class MyFunc : public nvOptimizer
	{
	public:
		double computeCost(double &x[], double &grad[])
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

	MyFunc opt;
	double x[] = {0};
	opt.setStopConditions(1e-6,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_cg(x,cost);
	ASSERT_EQUAL(res,4);
	ASSERT_CLOSEDIFF(x[0],-0.99917305,1e-7);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with LBFGS test 1")
	// Example taken from: http://www.alglib.net/translator/man/manual.cpp.html#example_mincg_d_1
	class MyFunc : public nvOptimizer
	{
	public:
		double computeCost(double &x[], double &grad[])
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

	MyFunc opt;
	double x[] = {0,0};
	opt.setStopConditions(1e-12,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_lbfgs(x,cost,1);
	ASSERT_EQUAL(res,4);
	ASSERT_CLOSEDIFF(x[0],-3.0,1e-4);
	ASSERT_CLOSEDIFF(x[1],3.0,1e-4);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with LBFGS test 2")
	// Example taken from: http://www.alglib.net/translator/man/manual.cpp.html#example_mincg_ftrim
	class MyFunc : public nvOptimizer
	{
	public:
		double computeCost(double &x[], double &grad[])
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

	MyFunc opt;
	double x[] = {0};
	opt.setStopConditions(1e-8,0.0,0.0,0);

	double cost = 0.0;
	int res = opt.optimize_lbfgs(x,cost,1);
	ASSERT_EQUAL(res,1);
	ASSERT_CLOSEDIFF(x[0],-0.99917305,1e-7);
END_TEST_CASE()

BEGIN_TEST_CASE("Should optimize properly with CG test 3")
	// Generalized RosenBrock function optimization 
	class MyFunc : public nvOptimizer
	{
	public:
		double computeCost(double &x[], double &grad[])
	  {
      //
	    // this callback calculates f(x) = 
	    // and its derivatives df/d0 and df/dx1
	    //
	    int num = ArraySize( x );
	    double val = 0;
	    double v1, v2;
	    for(int i=0;i<num;++i)
	    {

	    	grad[i]=0.0;
	    	if(i<num-1)
	    	{
	    		v1 = (x[i]-1);
	    		v2 = (x[i+1] - x[i]*x[i]);
	    		val += v1*v1 + 100.0 * v2*v2;
	    		grad[i]+=2*(x[i]-1)-400.0*x[i]*(x[i+1] - x[i]*x[i]);
	    	}
	    	if(i>0)
	    	{
	    		grad[i]+=200.0*(x[i] - x[i-1]*x[i-1]);
	    	}
	    }

	    return val;
	  }
	};

	MyFunc opt;
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
	// Generalized RosenBrock function optimization 
	class MyFunc : public nvOptimizer
	{
	public:
		double computeCost(double &x[], double &grad[])
	  {
      //
	    // this callback calculates f(x) = 
	    // and its derivatives df/d0 and df/dx1
	    //
	    int num = ArraySize( x );
	    double val = 0;
	    double v1, v2;
	    for(int i=0;i<num;++i)
	    {

	    	grad[i]=0.0;
	    	if(i<num-1)
	    	{
	    		v1 = (x[i]-1);
	    		v2 = (x[i+1] - x[i]*x[i]);
	    		val += v1*v1 + 100.0 * v2*v2;
	    		grad[i]+=2*(x[i]-1)-400.0*x[i]*(x[i+1] - x[i]*x[i]);
	    	}
	    	if(i>0)
	    	{
	    		grad[i]+=200.0*(x[i] - x[i-1]*x[i-1]);
	    	}
	    }

	    return val;
	  }
	};

	MyFunc opt;
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

END_TEST_SUITE()

END_TEST_PACKAGE()
