//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include "Object.mqh"

struct nvObjectMapNode
{
  string key;
  nvObject *value;
  bool toDelete;
};

// Base class for all NervTech elements.
class nvObjectMap : public nvObject
{
protected:
  nvObjectMapNode _nodes[];
  int _len;

public:
  nvObjectMap() : _len(0) {};
  virtual ~nvObjectMap() {
    clear();
  };

  virtual string toString() const
  {
    return "[nvObjectMap]";
  }

  // Method used to set a key value.
  void set(string key, nvObject *value, bool toDelete = true)
  {
    // Check if we already have this value in the list:
    for (int i = 0; i < _len; ++i)
    {
      if (_nodes[i].key == key) {
        if (_nodes[i].value && _nodes[i].toDelete)
        {
          // Delete the previous value if required.
          delete _nodes[i].value;
        }

        _nodes[i].value = value;
        _nodes[i].toDelete = toDelete;
        return;
      }
    }

    // otherwise the key was not found so we should add it here:
    _len++;
    CHECK(ArrayResize(_nodes, _len) == _len, "Invalid result for resize.");
    _nodes[_len - 1].key = key;
    _nodes[_len - 1].value = value;
    _nodes[_len - 1].toDelete = toDelete;
  }

  // unset a key if available:
  bool unset(string key)
  {
    // Check if we already have this value in the list:
    for (int i = 0; i < _len; ++i)
    {
      if (_nodes[i].key == key) {

        if (_nodes[i].toDelete) {
          delete _nodes[i].value;
        }

        // need to move the following elements if this is not the last one.
        if (i < _len - 1) {
        	int total = _len - i - 1;
          for(int j=1;j<=total;j++)
          {
            _nodes[i+j-1].key = _nodes[i+j].key;
            _nodes[i+j-1].value = _nodes[i+j].value;
            _nodes[i+j-1].toDelete = _nodes[i+j].toDelete;
          }
        }

        // Now need to resize the array:
        _len--;
        CHECK(ArrayResize(_nodes, _len) == _len, "Invalid result for resize.");
        return true;
      }
    }

    return false;
  }

  // Method to get an object from the map:
  nvObject *get(string key)
  {
    // Check if we already have this value in the list:
    for (int i = 0; i < _len; ++i)
    {
      if (_nodes[i].key == key) {
        return _nodes[i].value;
      }
    }

    return NULL;
  }

  // Get an object with default value:
  nvObject *get(string key, nvObject *def)
  {
    // Check if we already have this value in the list:
    for (int i = 0; i < _len; ++i)
    {
      if (_nodes[i].key == key) {
        return _nodes[i].value;
      }
    }

    return def;
  }

  // Retrieve the size of this map
  int size() const
  {
    return _len;
  }

  bool empty() const
  {
    return _len == 0;
  }

  string getKey(int index) const
  {
    CHECK(index >= 0 && index < _len, "Out of range index " << index);
    return _nodes[index].key;
  }

  nvObject *getValue(int index) const
  {
    CHECK(index >= 0 && index < _len, "Out of range index " << index);
    return _nodes[index].value;
  }

  // clear this map content:
  void clear() {
    for (int i = 0; i < _len; ++i)
    {
      if (_nodes[i].toDelete) {
        delete _nodes[i].value;
      }
    }
    
    _len = 0;
    CHECK(ArrayResize(_nodes, _len) == _len, "Invalid result for resize.");
  }
};