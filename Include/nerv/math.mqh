
#include <nerv/core.mqh>
#include <nerv/math/Vecd.mqh>

double nv_random_real(double mini=0.0, double maxi=1.0)
{
  return mini + (maxi-mini)*(double)MathRand()/32767.0;
}

int nv_random_int(int mini=0, int maxi=100)
{
  return mini + (int)((maxi-mini)*(double)MathRand()/32767.0);
}

double nv_sign(double val)
{
  return val > 0.0 ? 1.0 : val < 0.0 ? -1.0 : 0.0;
}

double nv_sign_threshold(double val, double thres)
{
  return val > thres ? 1.0 : val < -thres ? -1.0 : 0.0;
}

double nv_tanh(double x)
{
  double z = exp(-2.0*x);
  return (1.0 - z)/(1.0 + z);
}
