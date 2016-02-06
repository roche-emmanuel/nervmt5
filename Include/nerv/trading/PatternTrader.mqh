#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>

// Helper pattern class:
class Pattern {
public:
  double features[];
  double maxPred;
  double minPred;
  double meanPred;
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

  int _rawInputSize;
  int _patternLength;
  int _predictionOffset;
  int _predictionLength;

  double _rawInputs[];

  double _similarityLevel;

  int _maxPatternCount;
  Pattern* _patterns[];

  double _accuracy[];
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

    setPatternLength(30);
    setPredictionOffset(20);
    setPredictionLength(10);
    setMaxPatternCount(5000);
    setSimilarityLevel(70.0);

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
    reset();
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

  void setSimilarityLevel(double level)
  {
    _similarityLevel = level;
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

  Pattern* generatePattern()
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

    return pat;
  }

  void addInput(double value)
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
    Pattern* pat = generatePattern();
    if(pat==NULL)
      return; // nothing to do.

    // If we have a new pattern then we can try to recognize it in
    // the history:
    recognizePattern(pat);

    // Then we can append this new pattern.
    nvAppendArrayElement(_patterns,pat,_maxPatternCount);
  }

  double getSimilarity(Pattern* cur, Pattern* ref)
  {
    CHECK_RET(cur && ref,0.0,"Invalid patterns");
    double sims[];
    ArrayResize( sims, _patternLength );

    for(int i=0;i<_patternLength;++i)
    {
      sims[i] = 100.0 - MathAbs(percentChange(ref.features[i],cur.features[i]));      
    }

    return nvGetMeanEstimate(sims);
  }

  void recognizePattern(Pattern* pat)
  {
    CHECK(pat!=NULL,"Invalid pattern.")

    // Iterate on the existing pattern list, and compare each pattern:
    int len = ArraySize( _patterns );
    // logDEBUG("Pattern count: "<<len);

    double sim;

    double maxPreds[];
    double minPreds[];
    double meanPreds[];

    for(int i=0;i<len;++i)
    {
      sim = getSimilarity(pat,_patterns[i]);
      if(sim>_similarityLevel)
      {
        // We should consider this history pattern.
        nvAppendArrayElement(maxPreds,_patterns[i].maxPred);
        nvAppendArrayElement(minPreds,_patterns[i].minPred);
        nvAppendArrayElement(meanPreds,_patterns[i].meanPred);
      }
    }

    // Check if we have some patterns:
    len = ArraySize(maxPreds);
    if(len>0)
    {
      // Compute the mean of the prediction means!
      double mean = nvGetMeanEstimate(meanPreds);
      logDEBUG("Computed mean prediction: "<<mean<<", from "<<len<<" similar patterns");

      // Now we can compare that with the actual prediction we have:
      double good = mean*pat.meanPred>0.0 ? 1.0 : 0.0;
      nvAppendArrayElement(_accuracy,good);
      double acc = nvGetMeanEstimate(_accuracy);
      int nsamples = ArraySize( _accuracy );

      logDEBUG("Current accuracy: "<< StringFormat("%.2f%%",acc*100.0) << " with "<<nsamples << " samples.")
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
        addInput(value);
      }
    }
    else
    {
      if((ctime-_lastTime)>=_dur)
      {
        _lastTime = ctime;
        logDEBUG("Adding input bar at time "<<_lastTime)
        addInput(value);
      }
    }
  }
};
