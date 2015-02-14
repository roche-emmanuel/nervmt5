
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
