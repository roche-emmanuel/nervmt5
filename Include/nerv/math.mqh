
#include <nerv/core.mqh>
#include <nerv/math/Vecd.mqh>
#include <nerv/math/lbfgs_utils.mqh>
#include <nerv/math/lbfgs.mqh>

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
  if(x>30.0) {
    return 1.0;
  }
  else if(x<-30.0) {
    return -1.0;
  }

  double z = exp(-2.0*x);
  return (1.0 - z)/(1.0 + z);
}

nvVecd nv_read_vecd(string filename)
{
  int handle = FileOpen(filename, FILE_READ | FILE_CSV | FILE_ANSI);

  CHECK(handle!=INVALID_HANDLE,"Could not open file "<<filename<<" for reading.");

  // Prepare a dynamic vector:
  nvVecd result;

  //--- read data from the file
  while (!FileIsEnding(handle))
  {
    //--- read the string
    //content = FileReadString(handle);
    //double val = StringToDouble(content);
    double val = FileReadNumber(handle);
    //logDEBUG("Read value: "<<val); //<<" from string '"<<content<<"'");
    result.push_back(val);
  }
  //--- close the file
  FileClose(handle);

  return result;
}

