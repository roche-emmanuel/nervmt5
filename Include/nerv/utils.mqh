
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

// Retrieve a period duration in number of Seconds
int nvGetPeriodDuration(ENUM_TIMEFRAMES period)
{
  switch (period)
  {
  case PERIOD_M1: return 60;
  case PERIOD_M2: return 60 * 2;
  case PERIOD_M3: return 60 * 3;
  case PERIOD_M4: return 60 * 4;
  case PERIOD_M5: return 60 * 5;
  case PERIOD_M6: return 60 * 6;
  case PERIOD_M10: return 60 * 10;
  case PERIOD_M12: return 60 * 12;
  case PERIOD_M15: return 60 * 15;
  case PERIOD_M20: return 60 * 20;
  case PERIOD_M30: return 60 * 30;
  case PERIOD_H1: return 3600;
  case PERIOD_H2: return 3600 * 2;
  case PERIOD_H3: return 3600 * 3;
  case PERIOD_H4: return 3600 * 4;
  case PERIOD_H6: return 3600 * 6;
  case PERIOD_H8: return 3600 * 8;
  case PERIOD_H12: return 3600 * 12;
  case PERIOD_D1: return 3600 * 24;
  case PERIOD_W1: return 3600 * 24 * 7; 
  }
 
  THROW("Unsupported period value " << EnumToString(period));
  return 0;
}

// Method used to clamp a value between a min and max value:
template<typename T>
T nvClamp(T val, T mini, T maxi)
{
	if(val < mini)
		return mini;
	if(val > maxi)
		return maxi;
	return val;
}

// Method used to retrieve a period by index:
ENUM_TIMEFRAMES nvGetPeriodByIndex(int index)
{
  switch (index)
  {
  case 0: return PERIOD_M1;
  case 1: return PERIOD_M2;
  case 2: return PERIOD_M3;
  case 3: return PERIOD_M4;
  case 4: return PERIOD_M5;
  case 5: return PERIOD_M6;
  case 6: return PERIOD_M10;
  case 7: return PERIOD_M12;
  case 8: return PERIOD_M15;
  case 9: return PERIOD_M20;
  case 10: return PERIOD_M30;
  case 11: return PERIOD_H1;
  case 12: return PERIOD_H2;
  case 13: return PERIOD_H3;
  case 14: return PERIOD_H4;
  case 15: return PERIOD_H6;
  case 16: return PERIOD_H8;
  case 17: return PERIOD_H12;
  case 18: return PERIOD_D1;
  case 19: return PERIOD_W1; 
  case 20: return PERIOD_MN1; 
  }

  THROW("Invalid period index " << index);
  return PERIOD_CURRENT;
}

// Retrieve the index corresponding to a Period
int nvGetPeriodIndex(ENUM_TIMEFRAMES period)
{
  switch (period)
  {
  case PERIOD_M1: return 0;
  case PERIOD_M2: return 1;
  case PERIOD_M3: return 2;
  case PERIOD_M4: return 3;
  case PERIOD_M5: return 4;
  case PERIOD_M6: return 5;
  case PERIOD_M10: return 6;
  case PERIOD_M12: return 7;
  case PERIOD_M15: return 8;
  case PERIOD_M20: return 9;
  case PERIOD_M30: return 10;
  case PERIOD_H1: return 11;
  case PERIOD_H2: return 12;
  case PERIOD_H3: return 13;
  case PERIOD_H4: return 14;
  case PERIOD_H6: return 15;
  case PERIOD_H8: return 16;
  case PERIOD_H12: return 17;
  case PERIOD_D1: return 18;
  case PERIOD_W1: return 19; 
  case PERIOD_MN1: return 20; 
  }
 
  THROW("Unsupported period value " << EnumToString(period));
  return 0;
}

// Compute the mean of a sample array
double nvGetMeanEstimate(double &x[])
{
  int num = ArraySize( x );
  CHECK_RET(num>0,0.0,"Invalid sample size.");

  double mean = 0.0;
  for(int i=0;i<num;++i)
  {
    mean += x[i];
  }

  mean /= num;
  return mean;
}

// Compute the estimated standard deviation of a sample array
// when its mean is provided:
double nvGetStdDevEstimate(double &x[], double mean)
{
  int num = ArraySize( x );
  CHECK_RET(num>1,0.0,"Invalid sample size.");

  double sig = 0.0;
  for(int i=0;i<num;++i)
  {
    sig += (x[i] - mean)*(x[i] - mean);
  }

  sig /= (num-1);

  return MathSqrt(sig);
}

// Compute the estimated standard deviation of a sample array:
double nvGetStdDevEstimate(double &x[])
{
  return nvGetStdDevEstimate(x,nvGetMeanEstimate(x));
}