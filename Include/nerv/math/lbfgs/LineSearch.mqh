
class LBFGSLineSearch
{
public:
  virtual int process(
    int n,
    double &x[],
    double &f,
    double &g[],
    double &s[],
    double &stp,
    const double &xp[],
    const double &gp[],
    double &wa[],
    callback_data_t &cd,
    const LBFGSParameters *param)
  {
    return 0;
  }
};
