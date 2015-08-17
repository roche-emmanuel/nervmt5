
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

// Metohd used to retrieve the profit currency from a given symbol:
string nvGetQuoteCurrency(string symbol)
{
	CHECK_RET(StringLen(symbol)==6,"","Invalid symbol length.");
	return StringSubstr(symbol,3);
}

// Metohd used to retrieve the base currency from a given symbol:
string nvGetBaseCurrency(string symbol)
{
	CHECK_RET(StringLen(symbol)==6,"","Invalid symbol length.");
	return StringSubstr(symbol,0,3);
}

// Method called to compute the value of 1 point in a symbol trading given a fixed lot size:
// Note that the point value is given in the quote currency.
double nvGetPointValue(string symbol, double lot = 1.0)
{
	// We need to check what is the contract size for this symbol:
	double csize = SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE);
	double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
	return lot*csize*point;
}

// Method called to normalize a lot size given its symbol.
double nvNormalizeLotSize(double lot, string symbol)
{
	double maxlot = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
	double step = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
	lot = MathFloor( lot/step ) * step;
	return MathMin(maxlot,lot);
}
