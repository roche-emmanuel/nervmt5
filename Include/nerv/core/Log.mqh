
#include <Object.mqh>
#include "LogManager.mqh"

#define __WITH_POINTER_EXCEPTION__

#ifdef __WITH_POINTER_EXCEPTION__
#define THROW(msg) { Print(msg); \
    CObject* obj = NULL; \
    obj.Next(); \
  }
#else
#define THROW(msg) { Print(msg); \
    ExpertRemove(); \
    return; \
  }
#endif

#define STR(x) ((string)x)
#define CHECK(val,msg) if(!(val)) THROW(__FILE__ + "(" + STR(__LINE__) +") :" + msg)
