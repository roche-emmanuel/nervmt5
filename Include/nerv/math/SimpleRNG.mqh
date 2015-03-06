
#define PI 3.14159265358979323846

class SimpleRNG
{
private:
    uint m_w;
    uint m_z;

  // This is the heart of the generator.
  // It uses George Marsaglia's MWC algorithm to produce an unsigned integer.
  // See http://www.bobwheeler.com/statistics/Password/MarsagliaPost.txt
  uint GetUint()
  {
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    return (m_z << 16) + m_w;
  }

public:
  SimpleRNG()
  {
    // These values are not magical, just the default values Marsaglia used.
    // Any pair of unsigned integers should be fine.
    m_w = 521288629;
    m_z = 362436069;
  }

  // The random generator seed can be set three ways:
  // 1) specifying two non-zero unsigned integers
  // 2) specifying one non-zero unsigned integer and taking a default value for the second
  // 3) setting the seed from the system time

  void SetSeed(uint u, uint v)
  {
    if (u != 0) m_w = u;
    if (v != 0) m_z = v;
  }

  void SetSeed(uint u)
  {
    m_w = u;
  }

  void SetSeedFromSystemTime()
  {
    ulong x = TimeLocal();
    SetSeed((uint)(x >> 16), (uint)(x % 4294967296));
  }

  // Produce a uniform random sample from the open interval (0, 1).
  // The method will not return either end point.
  double GetUniform()
  {
    // 0 <= u < 2^32
    uint u = GetUint();
    // The magic number below is 1/(2^32 + 2).
    // The result is strictly between 0 and 1.
    return (u + 1.0) * 2.328306435454494e-10;
  }

  // Get normal (Gaussian) random sample with mean 0 and standard deviation 1
  double GetNormal()
  {
    // Use Box-Muller algorithm
    double u1 = GetUniform();
    double u2 = GetUniform();
    double r = MathSqrt( -2.0 * MathLog(u1) );
    double theta = 2.0 * PI * u2;
    return r * MathSin(theta);
  }

  // Get normal (Gaussian) random sample with specified mean and standard deviation
  double GetNormal(double mean, double standardDeviation)
  {
    CHECK(standardDeviation>0,"Shape must be positive. Received "<<standardDeviation);
    return mean + standardDeviation * GetNormal();
  }

  // Get exponential random sample with mean 1
  double GetExponential()
  {
    return -MathLog( GetUniform() );
  }

  // Get exponential random sample with specified mean
  double GetExponential(double mean)
  {
    CHECK(mean>0,"Mean must be positive. Received "<< mean);

    return mean * GetExponential();
  }

  double GetGamma(double shape, double scale)
  {
    // Implementation based on "A Simple Method for Generating Gamma Variables"
    // by George Marsaglia and Wai Wan Tsang.  ACM Transactions on Mathematical Software
    // Vol 26, No 3, September 2000, pages 363-372.

    double d, c, x, xsquared, v, u;

    if (shape >= 1.0)
    {
      d = shape - 1.0 / 3.0;
      c = 1.0 / MathSqrt(9.0 * d);
      for (;;)
      {
        do
        {
          x = GetNormal();
          v = 1.0 + c * x;
        }
        while (v <= 0.0);
        v = v * v * v;
        u = GetUniform();
        xsquared = x * x;
        if (u < 1.0 - .0331 * xsquared * xsquared || MathLog(u) < 0.5 * xsquared + d * (1.0 - v + MathLog(v)))
          return scale * d * v;
      }
    }
    else if (shape <= 0.0)
    {
      THROW("Shape must be positive. Received "<< shape);
    }
    else
    {
      double g = GetGamma(shape + 1.0, 1.0);
      double w = GetUniform();
      return scale * g * MathPow(w, 1.0 / shape);
    }
    
    return 0.0;
  }

  double GetChiSquare(double degreesOfFreedom)
  {
    // A chi squared distribution with n degrees of freedom
    // is a gamma distribution with shape n/2 and scale 2.
    return GetGamma(0.5 * degreesOfFreedom, 2.0);
  }

  double GetInverseGamma(double shape, double scale)
  {
    // If X is gamma(shape, scale) then
    // 1/Y is inverse gamma(shape, 1/scale)
    return 1.0 / GetGamma(shape, 1.0 / scale);
  }

  double GetWeibull(double shape, double scale)
  {
    if (shape <= 0.0 || scale <= 0.0)
    {
      THROW("Shape and scale parameters must be positive. Recieved shape "<<shape<<" and scale "<<scale);
    }
    return scale * MathPow(-MathLog(GetUniform()), 1.0 / shape);
  }

  double GetCauchy(double median, double scale)
  {
    CHECK(scale>0,"Scale must be positive. Received "<< scale);

    double p = GetUniform();

    // Apply inverse of the Cauchy distribution function to a uniform
    return median + scale * MathTan(PI * (p - 0.5));
  }

  double GetStudentT(double degreesOfFreedom)
  {
    CHECK(degreesOfFreedom>0,"Degrees of freedom must be positive. Received "<< degreesOfFreedom)

    // See Seminumerical Algorithms by Knuth
    double y1 = GetNormal();
    double y2 = GetChiSquare(degreesOfFreedom);
    return y1 / MathSqrt(y2 / degreesOfFreedom);
  }

  // The Laplace distribution is also known as the double exponential distribution.
  double GetLaplace(double mean, double scale)
  {
    double u = GetUniform();
    return (u < 0.5) ?
           mean + scale * MathLog(2.0 * u) :
           mean - scale * MathLog(2 * (1 - u));
  }

  double GetLogNormal(double mu, double sigma)
  {
    return MathExp(GetNormal(mu, sigma));
  }

  double GetBeta(double a, double b)
  {
    if (a <= 0.0 || b <= 0.0)
    {
      THROW("Beta parameters must be positive. Received "<<a<<" and "<<b);
    }

    // There are more efficient methods for generating beta samples.
    // However such methods are a little more efficient and much more complicated.
    // For an explanation of why the following method works, see
    // http://www.johndcook.com/distribution_chart.html#gamma_beta

    double u = GetGamma(a, 1.0);
    double v = GetGamma(b, 1.0);
    return u / (u + v);
  }
};

