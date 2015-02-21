#include <nerv/core.mqh>
#include <nerv/math.mqh>

class nvVectorWriter : public nvObject
{
protected:
  nvVecd _values; // parameter vectors containing the price returns, the last position F and the intercept term.
	string _filename;
	
public:
  nvVectorWriter(string filename) :
    _filename(filename)
  {
  }

  ~nvVectorWriter()
  {
    //logDEBUG("Writting "<<_values.size()<<" elements to file "<<_filename<<"...");
    nv_write_vecd(GetPointer(_values),_filename);
    //logDEBUG("Done writting data to file "<<_filename<<".");
  }

  virtual void add(double val)
  {
    _values.push_back(val);
  }
};
