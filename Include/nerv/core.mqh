
// To be defined if we are building a release version.
//#define RELEASE_BUILD

#define IS_DYN_POINTER(obj) (CheckPointer(GetPointer(obj))==POINTER_DYNAMIC)
#define IS_AUTO_POINTER(obj) (CheckPointer(GetPointer(obj))==POINTER_AUTOMATIC)
#define IS_VALID_POINTER(obj) (CheckPointer(GetPointer(obj))!=POINTER_INVALID)

#define RELEASE_PTR(ptr)  if (ptr != NULL && IS_DYN_POINTER(ptr)) { delete ptr; ptr = NULL; }
#define THIS GetPointer(this)

#define __WITH_POINTER_EXCEPTION__

#ifdef __WITH_POINTER_EXCEPTION__
#define THROW(msg) { nvStringStream __ss__; \
    __ss__ << msg; \
    Print(__ss__.str()); \
    CObject* obj = NULL; \
    obj.Next(); \
  }
#else
#define THROW(msg) { nvStringStream __ss__; \
    __ss__ << msg; \
    Print(__ss__.str()); \
    ExpertRemove(); \
    return; \
  }
#endif

#define CHECK(val,msg) if(!(val)) THROW(__FILE__ << "(" << __LINE__ <<") :" << msg)
#define CHECK_PTR(ptr, msg) CHECK(IS_VALID_POINTER(ptr),msg)

#include <Object.mqh>
#include <Arrays/List.mqh>

#include <nerv/core/Object.mqh>
#include <nerv/core/StringStream.mqh>
#include <nerv/core/Log.mqh>
#include <nerv/core/ObjectMap.mqh>



string nvReadFile(string filename, int flags = FILE_ANSI)
{
  int handle = FileOpen(filename, FILE_READ | flags);

  CHECK(handle != INVALID_HANDLE, "Could not open file " << filename << " for reading.");

  string content = "";

  //--- read data from the file
  while (!FileIsEnding(handle))
  {
    //--- read the string
    content += FileReadString(handle) + "\n";
  }
  //--- close the file
  FileClose(handle);

  return content;
}
