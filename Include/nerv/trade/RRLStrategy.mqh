//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/trade/Strategy.mqh>
#include <Arrays/ArrayDouble.mqh>

class nvRRLStrategy : public nvStrategy
{
protected:
  uint _numInputs;
  nvVecd *_price_returns;
  nvVecd *_theta;
  nvVecd *_params; // parameter vectors containing the price returns, the last position F and the intercept term.
  nvVecd *_predF;

  double _last_price;
  double _F; // current function evaluation value.
  nvVecd *_dF; // current function derivative.

  // Differential Sharpe ratio elements:
  double _A;
  double _B;
  double _eta; // Differential Sharpe ratio adaptation factor.

  double _rho; // backpropagation learning rate.

  double _delta; // transacion cost.

  double _mu; // investment scale.
  double _maxNorm;

  CArrayDouble _returns;
  CArrayDouble _spreads;

public:
  nvRRLStrategy(uint num, double rhoval, double etaval, double deltaval, double maxNormval,
                string symbol, ENUM_TIMEFRAMES period = PERIOD_M1) : nvStrategy(symbol, period)
  {
    _numInputs = num;
    _maxNorm = maxNormval;

    // We need at least numInputs+1 bars:
    int count = (int)_numInputs + 1;
    CHECK(Bars(_symbol, _period) >= count, "Not enough bars to build RRL strategy.");

    // Initialize the price return vector:
    double arr[];

    count = CopyClose(_symbol, _period, 0, (int)_numInputs, arr);
    CHECK(count == _numInputs, "Invalid count for CopyClose");

    nvVecd cur_prices(arr);

    //logDEBUG("Current price vector is: "<<cur_prices);

    count = CopyClose(_symbol, _period, 1, (int)_numInputs, arr);
    CHECK(count == _numInputs, "Invalid count for CopyClose");

    nvVecd prev_prices(arr);

    //logDEBUG("Previous price vector is: "<<prev_prices);

    // Prepare the vectors that will be used for the model computation:
    // Note that for the vectors used here the most recent value is at the back of the vector.
    // whereas the oldest value is at the front.
    _price_returns = new nvVecd(_numInputs);
    _price_returns = cur_prices - prev_prices;

    // Also keep a reference on the current close price:
    _last_price = cur_prices.back();

    // Prepare the vector containing the theta values:
    // We need 2 additional coeffs for the u and w coeffs
    _theta = new nvVecd(_numInputs + 2);

    // generate initial random coefficients:
    _theta.randomize(-1.0, 1.0);

    // Ensure the theta values are not initialy too big:
    _theta.normalize(0.8);

    _params = new nvVecd(_numInputs + 2);

    // Initialize the function derivative to a zero vector:
    _dF = new nvVecd(_numInputs + 2);

    // Initialize the other algorithm elements:
    _F = 0.0;
    _A = 0.0;
    _B = 0.0;

    _eta = etaval;
    _rho = rhoval;
    _delta = deltaval;
    _mu = 1.0; // this is not used for the moment.

    _params.set(0, 1.0); // This is the intercept term.
    _params.set(1, _F); // This is the previous value of F.

    _predF = new nvVecd(3); // Compute the mean on the previous 3 frames.
  }

  ~nvRRLStrategy()
  {
    logDEBUG("Deleting nvRRLStrategy()");
    delete _price_returns;
    delete _theta;
    delete _params;
    delete _dF;
    delete _predF;

#ifdef __NOTHING__
    // Compute the mean and deviation of the returns:
    double mean = 0;
    uint num = _returns.Total();
    logDEBUG("Handling " << num << " frames.");
    for (uint i = 0; i < num; ++i)
    {
      mean += _returns.At(i);
    }
    mean /= num;

    double dev = 0;
    for (uint i = 0; i < num; ++i)
    {
      dev += pow(_returns.At(i) - mean,2);
    }
    dev /= num;
    dev = MathSqrt(dev);

    logDEBUG("Found return mean="<<mean<<" and dev="<<dev);
#endif

//#ifdef __NOTHING__
    // Compute the mean and deviation of the returns:
    double mean = 0;
    uint num = _spreads.Total();
    logDEBUG("Handling " << num << " frames.");
    if(num>0) {
    for (uint i = 0; i < num; ++i)
    {
      mean += _spreads.At(i);
    }
    mean /= num;

    double dev = 0;
    for (uint i = 0; i < num; ++i)
    {
      dev += pow(_spreads.At(i) - mean,2);
    }
    dev /= num;
    dev = MathSqrt(dev);

    logDEBUG("Found spread mean="<<mean<<" and dev="<<dev);
    }
//#endif


  }

  virtual void handleNewBar(const MqlRates &rates)
  {
    // A new bar is received, so we use the previous price to compute the new return value:
    double rt = rates.close - _last_price;

    double rmean = -8.484268847701325e-007;
    double rdev = 0.0001640438970237092;

    // spread mean and deviation (in number of pips)
    double smean = 9.62285;
    double sdev = 2.550849;

    double deltan = 0.00001*smean/rdev;

    // Re normalize the price returns:
    rt = (rt-rmean)/rdev;
    //double rtn = (rt-rmean)/rdev;

    _returns.Add(rt);

    _spreads.Add(rates.spread);

    // Update the value of the last price:
    _last_price = rates.close;

    // Push the new price return on the vector:
    _price_returns.push_back(rt);

    // Update the param vector:
    _params.set(1, _F);
    _params.set(2, _price_returns);
    //logDEBUG("Current param vector is: "<<_params);

    logDEBUG("Theta norm: " << _theta.norm());

    // Compute the new position F:
    //double Ft = nv_sign(_theta * _params);
    double Ft = _theta * _params;

    // Compute Rt:
    double Rt = _F * rt - deltan * MathAbs(Ft - _F);

    // Only perform the gradient descent if applicable:
    if (MathAbs(_B - _A * _A) > 1e-12)
    {
      // Coefficient used for the gradient descent:
      double coeff = _rho * (_B - _A * Rt) / MathPow(_B - _A * _A, 1.5);

      // Compute the derivative dF/dtheta with the recursive formula:
      nvVecd newdF = _params + _dF * _theta[1];

      // Compute the delta theta value:
      double dsign = deltan * nv_sign(Ft - _F);

      nvVecd dtheta = (_dF * (rt + dsign) - newdF * dsign) * coeff;

      logDEBUG("Performing training with dtheta norm=" << dtheta.norm());

      // Finally, we update the theta coefficients:
      _theta += dtheta;

      // Prevent theta from becoming too big:
      //if(_theta.norm()>1.0) {
      //  _theta.normalize(0.8);
      //}

      //if(MathMax(MathAbs(_theta.max()),MathAbs(_theta.min())) > 5.0) {
      //  _theta *= 0.95;
      //}

      _theta *= MathExp(MathMin(-_theta.norm() / _maxNorm + 1, 0.0));

      // Update the value of _dF:
      _dF = newdF;

      // Here we could recompute the value of Ft.
      //Ft = nv_sign(_theta * _params);
      Ft = _theta * _params;

      // And thus also recompute Rt:
      Rt = _F * rt - deltan * MathAbs(Ft - _F);
    }

    // Save the value of Ft:
    _F = Ft;

    // Compute the new desired position:
    _predF.push_back(_F);
    double fmean = _predF.mean();

    int pid = (int)nv_sign_threshold(fmean,0.3);
    int npos = pid==1 ? POSITION_LONG : pid==-1 ? POSITION_SHORT : POSITION_NONE;
    int cpos = getCurrentPosition();

    if (npos != cpos)
    {
      logDEBUG("Selecting new position " << npos);
    }


    // Compute the new value for A and B:
    _A = _A + _eta * (Rt - _A);
    _B = _B + _eta * (Rt * Rt - _B);
    logDEBUG("Sharpe ratio: " << (_B != 0.0 ? _A / MathSqrt(_B) : 0.0));

    //logDEBUG("New values for A="<<_A<<", B="<<_B);

    int pos = _F == 1 ? POSITION_LONG : _F == -1 ? POSITION_SHORT : POSITION_NONE;

    if (isReady()) {
      requestPosition(npos);
      // we might not enter the position so we need to check that here:
      //pos = getCurrentPosition();
      //_F = pos==POSITION_LONG ? 1 : pos==POSITION_SHORT ? -1 : 0;
    }
    else {
      logDEBUG("Not ready for trading at frame "<<_frameCount);
    }


  }

};
