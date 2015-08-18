#include <nerv/core.mqh>
#include <nerv/expert/DecisionComposer.mqh>

/*
Class: nvDecisionComposerFactory

Factory class used to generated DecisionComposer instances.
*/
class nvDecisionComposerFactory : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvDecisionComposerFactory()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvDecisionComposerFactory(const nvDecisionComposerFactory& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvDecisionComposerFactory& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvDecisionComposerFactory()
  {
    // No op.
  }

  /*
  Function: getEntryTypeCount
  
  Retrieve the number of entry decision composer types that can be generated.
  */
  int getEntryTypeCount()
  {
    return 1;
  }
  
  /*
  Function: getExitTypeCount
  
  Retrieve the number of exit decision composer types that can be generated.
  */
  int getExitTypeCount()
  {
    return 1;
  }
  
  /*
  Function: createEntryComposer
  
  Method used to created an Entry decision composer for a given currency trader
  */
  nvDecisionComposer* createEntryComposer(nvCurrencyTrader* ct, int index = -1)
  {
    int count = getEntryTypeCount();
    if(count==0)
    {
      logWARN("No entry decision composer registered.");
      return NULL;
    }


    // If the index is -1 then we should select a decision composer randomly from the list of possibilities:
    if(index<0)
    {
      SimpleRNG* rng = nvPortfolioManager::instance().getRandomGenerator();
      index = rng.GetInt(0,count-1);
    }

    logDEBUG("Generating entry decision composer with index "<<index)
    nvDecisionComposer* result = NULL;

    switch(index)
    {
    case 0:
      result = new nvRandomDecisionComposer(); break;
    default:
      break; 
    }

    if(result)
    {
      result.setCurrencyTrader(ct);
    }
    else 
    {
      THROW("Out of range index for entry decision composer: "<<index);
    }

    return result;
  }
  
  /*
  Function: createExitComposer
  
  Method used to create en exit decision composer for a given currency trader.
  */
  nvDecisionComposer* createExitComposer(nvCurrencyTrader* ct, int index = -1)
  {
    int count = getExitTypeCount();
    if(count==0)
    {
      logWARN("No exit decision composer registered.");
      return NULL;
    }

    // If the index is -1 then we should select a decision composer randomly from the list of possibilities:
    if(index<0)
    {
      SimpleRNG* rng = nvPortfolioManager::instance().getRandomGenerator();
      index = rng.GetInt(0,count-1);
    }

    logDEBUG("Generating exit decision composer with index "<<index)
    nvDecisionComposer* result = NULL;
    switch(index)
    {
    case 0:
      result = new nvRandomDecisionComposer(); break;
    default:
      break;
    }

    if(result)
    {
      result.setCurrencyTrader(ct);
    }
    else 
    {
      THROW("Out of range index for entry decision composer: "<<index);
    }
    
    return result;
  }
  
};
