
#include <nerv/core.mqh>

// Simple generic method to remove an object from an array:
template<typename T>
void nvRemoveArrayItem(T &array[], int index)
{
  int num = ArraySize( array );
  CHECK(0<=index && index<num,"Out of range index value: "<<index);
  int count = ArrayCopy( array, array, index, index+1, num - 1 - index);
  CHECK(count == num - 1 - index, "Invalid array copy count: " << count);
  // Resize the array:
  ArrayResize( array, num-1 );
}

// Generic method to append a content to an array:
template<typename T>
void nvAppendArrayElement(T &array[], T& val)
{
	int num = ArraySize( array );
	ArrayResize( array, num+1 );
	array[num] = val;
}

// Generic method to remove an element from an array
template<typename T>
void nvRemoveArrayElement(T &array[], T& val)
{
	int num = ArraySize( array );
	for(int i=0;i<num;++i)
	{
		if(array[i]==val)
		{
			nvRemoveArrayItem(array,i);
			return;
		}
	}
}
