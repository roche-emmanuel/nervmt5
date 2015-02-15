//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/trade/Strategy.mqh>

class nvRRLStrategy : public nvStrategy
{
protected:
  uint _numInputs;
  nvVecd *_price_returns;
  nvVecd *_theta;
  nvVecd *_params; // parameter vectors containing the price returns, the last position F and the intercept term.

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
  }

  ~nvRRLStrategy()
  {
    logDEBUG("Deleting nvRRLStrategy()");
    delete _price_returns;
    delete _theta;
    delete _params;
    delete _dF;
  }

  virtual void handleNewBar(const MqlRates &rates)
  {
    // A new bar is received, so we use the previous price to compute the new return value:
    double rt = rates.close - _last_price;

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
    double Ft = nv_sign(_theta * _params);

    // Compute Rt:
    double Rt = _F * rt - _delta * MathAbs(Ft - _F);

    // Only perform the gradient descent if applicable:
    if (MathAbs(_B - _A * _A) > 1e-12)
    {
      // Coefficient used for the gradient descent:
      double coeff = _rho * (_B - _A * Rt) / MathPow(_B - _A * _A, 1.5);

      // Compute the derivative dF/dtheta with the recursive formula:
      nvVecd newdF = _params + _dF * _theta[1];

      // Compute the delta theta value:
      double dsign = _delta * nv_sign(Ft - _F);

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
      Ft = nv_sign(_theta * _params);

      // And thus also recompute Rt:
      Rt = _F * rt - _delta * MathAbs(Ft - _F);
    }

    // Assign the value of _F:
    if (Ft != _F)
    {
      logDEBUG("New value for F=" << Ft);
    }
    _F = Ft;


    // Compute the new value for A and B:
    _A = _A + _eta * (Rt - _A);
    _B = _B + _eta * (Rt * Rt - _B);
    logDEBUG("Sharpe ratio: " << (_B != 0.0 ? _A / MathSqrt(_B) : 0.0));

    //logDEBUG("New values for A="<<_A<<", B="<<_B);

    int pos = _F == 1 ? POSITION_LONG : _F == -1 ? POSITION_SHORT : POSITION_NONE;

    enterPosition(pos);
  }

};
