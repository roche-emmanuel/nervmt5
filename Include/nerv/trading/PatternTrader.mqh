#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/trading/SecurityTrader.mqh>

// Helper pattern class:
class Pattern {
public:
  double features[];
  double maxPred;
  double minPred;
  double meanPred;
  double norm;
  datetime time;
  double refPrice;
  int index;
};

/*
Class: nvPatternTrader

Base class representing a trader 
*/
class nvPatternTrader : public nvSecurityTrader {
protected:
  bool _useTicks;
  int _inputPeriod;
  int _tickCount;
  datetime _lastTime;
  int _dur;
  int _patternCount;


  int _rawInputSize;
  int _patternLength;
  int _predictionOffset;
  int _predictionLength;

  double _rawInputs[];

  double _varLevel;

  int _minPatternCount;
  int _maxPatternCount;
  Pattern* _patterns[];

  double _accuracy[];
  double _deals[];

  double _tmp[];

  // Pattern distance weights:
  double _pw[];
  double _pwSum;

  // current profit:
  double _profit;

  // Mean spread value:
  double _meanSpread;

  double _gainTarget;

public:
  /*
    Class constructor.
  */
  nvPatternTrader(string symbol, bool useTicks, int inputPeriod)
    : nvSecurityTrader(symbol), _useTicks(useTicks), _inputPeriod(inputPeriod)
  {
    logDEBUG("Creating PatternTrader")
    _tickCount = -1;
    _lastTime = 0;
    _rawInputSize = -1;
    _profit = 0.0;
    _patternCount = 0;

    setPatternLength(30);
    setPredictionOffset(20);
    setPredictionLength(10);
    setMaxPatternCount(5000);
    setMinPatternCount(5000);
    setVariationLevel(30.0);
    setMeanSpread(0.0001);

    // Required estimation gain in number of points:
    setGainTarget(0.0002);

    // Assume that the input period is given in number of minutes:
    _dur = inputPeriod*60;
  }

  /*
    Class destructor.
  */
  ~nvPatternTrader()
  {
    logDEBUG("Deleting PatternTrader")
    logDEBUG("Final tick count: "<<_tickCount);
    logDEBUG("Final pattern count: "<<ArraySize( _patterns ));

    logDEBUG("Writing accuracy with "<<ArraySize(_accuracy)<<" samples.");
    nvWriteVector(_accuracy,"accuracy.csv");

    logDEBUG("Writing deals with "<<ArraySize(_deals)<<" samples.");
    nvWriteVector(_deals,"deals.csv");

    reset();
  }
  
  // Set the mean spread value:
  void setMeanSpread(double spread)
  {
    _meanSpread = spread;
  }

  // Specify the gain target
  void setGainTarget(double thres)
  {
    _gainTarget = thres;
  }

  // Reset the pattern lists.
  void reset()
  {
    int len = ArraySize( _patterns );
    for(int i=0;i<len;++i)
    {
      RELEASE_PTR(_patterns[i]);
    }

    ArrayResize( _patterns, 0 );

    _rawInputSize = _patternLength + 1 + _predictionOffset + _predictionLength;
    ArrayResize( _accuracy, 0 );
    ArrayResize( _deals, 0 );
  }

  double computeNorm(Pattern *pat, double p = 2.0)
  {
    double result = 0.0;
    for(int i=0;i<_patternLength;++i)
    {
      result += MathPow(MathAbs(pat.features[i]),p)*_pw[i];
    }

    result /= _pwSum;

    return MathPow(result,1.0/p);
  }

  double computeDeltaNorm(Pattern *pat1, Pattern *pat2, double p = 2.0)
  {
    double result = 0.0;
    for(int i=0;i<_patternLength;++i)
    {
      result += MathPow(MathAbs(pat1.features[i] - pat2.features[i]),p)*_pw[i];
    }

    result /= _pwSum;

    return MathPow(result,1.0/p);
  }

  void setMinPatternCount(int npat)
  {
    _minPatternCount = npat;
  }

  void setMaxPatternCount(int count)
  {
    _maxPatternCount = count;
    reset();
  }

  void setPatternLength(int len)
  {
    _patternLength = len;
    reset();
    ArrayResize( _tmp, _patternLength );
    ArrayResize( _pw, _patternLength );
    _pwSum = 0.0;
    for(int i = 0; i<_patternLength;++i)
    {
      _pw[i] = 1.0/MathLog(1.0 + _patternLength - i);
      // _pw[i] = 0.5 + 0.5 * ((double)i)/((double)(_patternLength-1));
      _pwSum += _pw[i];
    }
  }

  void setPredictionOffset(int offset)
  {
    _predictionOffset = offset;
    reset();
  }

  void setPredictionLength(int len)
  {
    _predictionLength = len;
    reset();
  }

  void setVariationLevel(double level)
  {
    _varLevel = level;
    // reset();
  }

  double percentChange(double startVal, double currentVal)
  {
    if(startVal==0.0)
    {
      return 0.0;
    }
    return 100.0*(currentVal-startVal)/MathAbs(startVal);
  }

  Pattern* generatePattern(datetime ctime)
  {
    int len = ArraySize( _rawInputs );
    if(len<_rawInputSize)
      return NULL;

    // We can generate a new pattern object:
    Pattern* pat = new Pattern();

    ArrayResize( pat.features, _patternLength );
    double ref = _rawInputs[_patternLength];

    int i;

    for(i=0;i<_patternLength;++i)
    {
      pat.features[i] = percentChange(ref,_rawInputs[i]);
    }

    // Now compute the relative values for the predictions:
    int offset = _patternLength+1+_predictionOffset;
    double maxi = percentChange(ref,_rawInputs[offset]);
    double mini = percentChange(ref,_rawInputs[offset]);
    double mean = percentChange(ref,_rawInputs[offset]);
    double val;

    for(i=1;i<_predictionLength;++i)
    {
      val = percentChange(ref,_rawInputs[offset+i]);
      maxi = MathMax(maxi,val);
      maxi = MathMax(mini,val);
      mean += val;
    }

    mean /= (double)_predictionLength;
    pat.maxPred = maxi;
    pat.minPred = mini;
    pat.meanPred = mean;

    // pat.norm = pnorm(pat.features,2.0);
    pat.norm = computeNorm(pat,2.0);
    
    // Assign the current time to this pattern:
    pat.time = ctime;
    pat.refPrice = ref;
    pat.index = _patternCount++;

    return pat;
  }

  void addInput(double value, datetime ctime)
  {
    // This is where we store the data to prepare for pattern generation:
    // For now we store simply the value in a window array:
    // If the pattern length is 30 for instance, we need 31 values
    // to compute the pattern coordinates.
    // then we have the prediction offset which tell us where to start
    // considering the prediction value, and the prediction range
    // which tell us how many prediction values to consider,
    // so in total we need:
    // total = patternLength + 1 + predOffset + predRange
    nvAppendArrayElement(_rawInputs, value, _rawInputSize);

    // Now if we have enough raw inputs, we can generate a new pattern:
    Pattern* pat = generatePattern(ctime);
    if(pat==NULL)
      return; // nothing to do.

    // If we have a new pattern then we can try to recognize it in
    // the history:
    int npat = ArraySize( _patterns );
    if(npat >= _minPatternCount )
    {
      recognizePattern(pat);  
    }
    

    // Then we can append this new pattern.
    nvAppendArrayObject(_patterns,pat,_maxPatternCount);
  }

  double getVariation(Pattern* cur, Pattern* ref, double p = 2.0)
  {
    CHECK_RET(cur && ref,0.0,"Invalid patterns");

    double dnorm = computeDeltaNorm(cur,ref,p);
    return 100.0*dnorm/cur.norm;
    
    // double result = 0.0;
    // for(int i=0;i<_patternLength;++i)
    // {
    //   result += MathPow(MathAbs(cur.features[i] - ref.features[i]),p);
    // }

    // return 100.0*MathPow(result,1.0/p)/cur.norm;
  }

  void recognizePattern(Pattern* pat)
  {
    CHECK(pat!=NULL,"Invalid pattern.")

    // Iterate on the existing pattern list, and compare each pattern:
    int len = ArraySize( _patterns );
    // logDEBUG("Pattern count: "<<len);

    // Important note:
    // When recognizing a pattern we cannot use the patterns that 
    // were generated just before it...
    // To generate a pattern, we need
    // patternLength+1+predOffset+predRange values.
    // This pattern is then only available in real condition when on the final
    // pattern, thus the offset is predOffset+predRange
    // for security, we will consider the pattern as usable only when we are strictly under this offset value.
    int offset = _predictionOffset+_predictionLength+2;

    double var;

    double maxPreds[];
    double minPreds[];
    double meanPreds[];
    double weights[];
    double w;
    double delta;
    int maxIdx = pat.index-offset;

    for(int i=0;i<len;++i)
    {
      if(_patterns[i].index<maxIdx)
      {
        var = getVariation(pat,_patterns[i]);
        if(var<_varLevel)
        {
          // We should consider this history pattern.
          nvAppendArrayElement(maxPreds,_patterns[i].maxPred);
          nvAppendArrayElement(minPreds,_patterns[i].minPred);
          nvAppendArrayElement(meanPreds,_patterns[i].meanPred);
          w = 1.0/MathMax(1.0,var);
          delta = 1.0; //1.0/MathMax(1.0,MathAbs((double)(int)(pat.time - _patterns[i].time)));

          // w = w*w*w*delta;
          w = w*delta;
          nvAppendArrayElement(weights,w);
        }        
      }
    }    

    // Check if we have some patterns:
    len = ArraySize(maxPreds);
    if(len>0)
    {
      // Compute the mean of the prediction means!
      // double mean = nvGetMeanEstimate(meanPreds);
      double mean = nvGetWeightedMean(meanPreds,weights);

      // We would like to target a gain of _gainTarget
      // So we need to convert that in percent:
      double target = 100.0*_gainTarget/pat.refPrice;

      if(MathAbs(mean) < target)
      {
        // We do not enter a position here.
        return;
      }

      // logDEBUG("Computed mean prediction: "<<mean<<", from "<<len<<" similar patterns");

      // Now we can compare that with the actual prediction we have:
      double good = mean*pat.meanPred>0.0 ? 1.0 : 0.0;
      nvAppendArrayElement(_accuracy,good);
      double acc = nvGetMeanEstimate(_accuracy);
      int nsamples = ArraySize( _accuracy );

      // Compute the profit that we can observe:
      double p = 0.0;
      if(mean>0.0)
      {
        // We enter a long position:
        p = pat.refPrice*pat.meanPred/100.0;
      }
      else 
      {
        p = -pat.refPrice*pat.meanPred/100.0; 
      }

      p = ((double)(int)(p*100000))/100000.0;

      _profit += (p - _meanSpread);
      nvAppendArrayElement(_deals,p);

      double meanp = _profit/nsamples;

      logDEBUG("Current accuracy: "<< StringFormat("%.2f%%",acc*100.0) << " with "<<nsamples 
        << " samples. Estimated profit: "<<StringFormat("%.5f",_profit)<<" points ("
        << "mean profit: "<<StringFormat("%.8f",meanp)<<")");
    }
  }

  virtual void onTick(datetime ctime, double value)
  {
    _tickCount++;

    if(_useTicks)
    {
      // If we use the tick, then we have to consider the tick
      // value every inputPeriod ticks:
      if(_tickCount%_inputPeriod==0)
      {
        // logDEBUG("Adding input tick at tick count = "<<_tickCount)
        addInput(value,ctime);
      }
    }
    else
    {
      if((ctime-_lastTime)>=_dur)
      {
        _lastTime = ctime;
        logDEBUG("Adding input bar at time "<<_lastTime)
        addInput(value,ctime);
      }
    }
  }
};
