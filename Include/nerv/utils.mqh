
#include <nerv/core.mqh>

// Simple generic method to remove an object from an array:
template<typename T>
void nvRemoveArrayItem(T &array[], int index)
{
  int num = ArraySize( array );
  CHECK(0<index && index<num,"Out of range index value: "<<index);
  int count = ArrayCopy( array, array, index, index-1, num - 1 - index);
  CHECK(count == num - 1 - index, "Invalid array copy count: " << count);
}
