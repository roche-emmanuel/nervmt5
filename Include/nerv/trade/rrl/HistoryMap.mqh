
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/* Base class used to represent an RRL trading model. */
class nvHistoryMap : public nvObjectMap
{
protected:
  int _size;

public:
  /* Constructor. Used to specify the desired size of the history vectors.*/
  nvHistoryMap(int size = 0);

  /* Destructor, on destruction, the write method will be called. */
  ~nvHistoryMap();

  /* Add an entry on a given channel. If the channel doesn't exist yet, it will be created. */
  void add(string channel, double value); 

  /* Write all the channels to the disk. */
  void writeToDisk() const;
};

nvHistoryMap::nvHistoryMap(int size)
  : _size(size)
{

}

nvHistoryMap::~nvHistoryMap()
{
  writeToDisk();
}

void nvHistoryMap::add(string channel, double value)
{
  nvVecd* stack = (nvVecd*)get(channel);
  if(stack==NULL) {
    stack = new nvVecd(_size);
    set(channel,stack,true); // The should delete this object when done.
  }

  stack.push_back(value);
}

void nvHistoryMap::writeToDisk() const
{
  int num = size();
  for(int i=0;i<num;++i) {
    string fname = getKey(i);
    nvVecd* stack = (nvVecd*)getValue(i);
    stack.writeTo(fname+".txt");
  }
}
