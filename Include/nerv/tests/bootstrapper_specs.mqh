
#include <nerv/unit/Testing.mqh>
#include <nerv/math/Bootstrapper.mqh>
#include <nerv/utils.mqh>

BEGIN_TEST_PACKAGE(bootstrapper_specs)

BEGIN_TEST_SUITE("Bootstrapper class")

BEGIN_TEST_CASE("should be able to create a Bootstrapper instance")
	nvBootstrapper boot;
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to evaluate the mean of a distribution")
  SimpleRNG rng;

  rng.SetSeedFromSystemTime();

  int size = 300;
  double mean = 1.23456;
  double dev = 1.65432;

  logDEBUG("Real mean value: "<<mean);
  logDEBUG("Real stddev value: "<<dev);

  double x[];
  ArrayResize( x, size );
  for(int i=0;i<size;++i)
  {
  	x[i] = rng.GetNormal(mean,dev);
  }

  // Compute the estimated mean and dev:
  double emean = nvGetMeanEstimate(x);
  double edev = nvGetStdDevEstimate(x);

  logDEBUG("Estimated mean value: "<<emean);
  logDEBUG("Estimated stddev value: "<<edev);

  // ASSERT_CLOSEDIFF(mean,emean,1e-8);
  // ASSERT_CLOSEDIFF(dev,edev,1e-8);
  
  // Now use a bootstrap to compute the mean:
  nvMeanBootstrap meanBoot;
  double bmean = meanBoot.evaluate(x);
  double bdev = meanBoot.getStandardError();

  // The following tests should success in 95% of the times:
  ASSERT(bmean-2*bdev <= mean);
  ASSERT(bmean+2*bdev >= mean);
  logDEBUG("Bootstram mean value: "<<bmean<<", SE: "<<bdev);

  // Now try to estimate the standard deviation:
  nvStdDevBootstrap devBoot;
  double bsd = devBoot.evaluate(x);
  double bsd_se = devBoot.getStandardError();

  // The following tests should success in 95% of the times:
  ASSERT(bsd-2*bsd_se <= dev);
  ASSERT(bsd+2*bsd_se >= dev);
  logDEBUG("Bootstram stddev value: "<<bsd<<", SE: "<<bsd_se);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to provide min/max confidence values")
  SimpleRNG rng;

  rng.SetSeedFromSystemTime();

  int size = 300;
  double mean = 1.23456;
  double dev = 1.65432;

  double x[];
  ArrayResize( x, size );
  for(int i=0;i<size;++i)
  {
    x[i] = rng.GetNormal(mean,dev);
  }

  // Now use a bootstrap to compute the mean:
  nvMeanBootstrap meanBoot;
  double bmean = meanBoot.evaluate(x);
  double bdev = meanBoot.getStandardError();

  // use the bootstrap statistics to determine the max value of the
  // 95% confidence interval:
  double mean_max = meanBoot.getMaxValue(0.95);

  double bsamples[];
  meanBoot.getBootSamples(bsamples);
  ArraySort( bsamples );

  // The max value should be achieved when we reach 97.5% of the samples, 
  // so when we select the 97.5% of _B
  int index = (int)MathFloor(999*0.975 + 0.5);
  ASSERT_EQUAL(mean_max,bsamples[index]);

  // Same for the min value:
  double mean_min = meanBoot.getMinValue(0.95);
  index = (int)MathFloor(999*0.025 + 0.5);
  ASSERT_EQUAL(mean_min,bsamples[index]);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
