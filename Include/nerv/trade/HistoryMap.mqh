
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/* Base class used to represent an RRL trading model. */
class nvHistoryMap : public nvObjectMap
{
protected:
  int _size;
  string _prefix;
  bool _autoWrite;

public:
  /* Constructor. Used to specify the desired size of the history vectors.*/
  nvHistoryMap(int size = 0);

  /* Destructor, on destruction, the write method will be called. */
  ~nvHistoryMap();

  /* Add an entry on a given channel. If the channel doesn't exist yet, it will be created. */
  void add(string channel, double value);

  /* Write all the channels to the disk. */
  void writeToDisk() const;

  /* Retrieve the vector size. */
  int getSize() const {
    return _size;
  }

  /* assign the vector size. */
  void setSize(int size) {
    _size = size;
  }

  /* Assign a prefix that will be prepended to the file names
   when writing the channels to the disk. */
  void setPrefix(string prefix);

  /* Specify if the history data should automaticaly be written to 
  disk when this history object is destroyed. Default value is true. */
  void setAutoWrite(bool enable);
};

nvHistoryMap::nvHistoryMap(int size)
  : _size(size),
    _autoWrite(true)
{
  _prefix = "";
}

nvHistoryMap::~nvHistoryMap()
{
  if (_autoWrite) {
    writeToDisk();
  }
}

void nvHistoryMap::add(string channel, double value)
{
  nvVecd *stack = (nvVecd *)get(channel);
  if (stack == NULL) {
    stack = new nvVecd(_size);
    set(channel, stack, true); // The should delete this object when done.
  }

  stack.push_back(value);
}

void nvHistoryMap::writeToDisk() const
{
  int num = size();
  for (int i = 0; i < num; ++i) {
    string fname = getKey(i);
    nvVecd *stack = (nvVecd *)getValue(i);
    stack.writeTo(_prefix + fname + ".txt");
  }
}

void nvHistoryMap::setPrefix(string prefix)
{
  _prefix = prefix;
}

void nvHistoryMap::setAutoWrite(bool enable)
{
  _autoWrite = enable;
}
