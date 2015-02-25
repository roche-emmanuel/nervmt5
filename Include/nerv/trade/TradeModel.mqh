#include <nerv/trades.mqh>

/* Base class used to represent an RRL trading model. */
class nvTradeModel : public nvObject
{
private:
  nvTradeModelTraits *_traits;

protected:
  /* A model can keep an history of relevant data.
  The history will be written to different files
  prefixed with the id provided for this model upon deletion. */
  nvHistoryMap _history;

public:
  /* Default constructor. Will assign the model traits if provided. */
  nvTradeModel(nvTradeModelTraits *traits = NULL);

  /* destructor, will release the traits if applicable. */
  ~nvTradeModel();

  /* Retrieve the history map in this object. */
  nvHistoryMap* getHistoryMap();

  /* Assign the model traits. */
  virtual void setTraits(nvTradeModelTraits *traits);

  /* Reset the state of this model so that the next digest cycle will
    restart from scratches. Default implementation does nothing. */
  virtual void reset();

  /* Public method used to provide a new input to the model,
    And retrieve a new prediction. This method will return true if the
    prediction is valid, and false otherwise. */
  virtual bool digest(const nvDigestTraits &dt, nvTradePrediction &pred);
};


///////////////////////////////// implementation part ///////////////////////////////


nvTradeModel::nvTradeModel(nvTradeModelTraits *traits)
  : _traits(NULL)
{
  if (traits != NULL) {
    // Assign the traits:
    setTraits(traits);
  }
}

nvTradeModel::~nvTradeModel()
{
  RELEASE_PTR(_traits);
}

nvHistoryMap* nvTradeModel::getHistoryMap()
{
  return GetPointer(_history);
}

void nvTradeModel::setTraits(nvTradeModelTraits *traits)
{
  CHECK_PTR(traits, "Invalid traits.");

  // release the previous traits is any:
  RELEASE_PTR(_traits);

  _traits = traits;

  _history.setPrefix(_traits.id() == "" ? "" : (_traits.id() + "_"));
  _history.setAutoWrite(_traits.autoWriteHistory());
  
  if (_traits.historyLength() != _history.getSize())
  {
    // Need to reset the history:
    _history.setSize(_traits.historyLength());
    _history.clear();
  }
}

void nvTradeModel::reset()
{
  // Doing nothing by default.
}

bool nvTradeModel::digest(const nvDigestTraits &dt, nvTradePrediction &pred) {
  return false;
}
