
// To be defined if we are building a release version.
//#define RELEASE_BUILD

#include <Object.mqh>
#include <Arrays/List.mqh>

#include <nerv/core/Object.mqh>
#include <nerv/core/StringStream.mqh>
#include <nerv/core/Log.mqh>

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

