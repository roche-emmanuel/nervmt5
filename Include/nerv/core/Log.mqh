#include "LogManager.mqh"
#include "FileLogger.mqh"
#include "LogRecord.mqh"

#define LOG(level,msg) \
  if(level <= nvLogManager::instance().getNotifyLevel()) { \
    nvLogRecord rec(level,__FILE__,__LINE__,""); \
    rec.getStream() << msg ; \
  }

#define TRACE(level,trace,msg) \
  if(level <= nvLogManager::instance().getNotifyLevel()) { \
    nvLogRecord rec(level,__FILE__,__LINE__,trace); \
    rec.getStream() << msg ; \
  }

#define LOG_V(level,msg) \
  if(nvLogManager::instance().getVerbose() && level <= nvLogManager::instance().getNotifyLevel()) { \
    nvLogRecord rec(level,__FILE__,__LINE__,""); \
    rec.getStream() << msg ; \
  }

#define TRACE_V(level,trace,msg) \
  if(nvLogManager::instance().getVerbose() && level <= nvLogManager::instance().getNotifyLevel()) { \
    nvLogRecord rec(level,__FILE__,__LINE__,trace); \
    rec.getStream() << msg ; \
  }

#ifdef RELEASE_BUILD
// Do not define the debug log targets:
#define LOG_D(level,msg)
#define LOG_V_D(level,msg)
#define TRACE_D(level,trace,msg)
#define TRACE_V_D(level,trace,msg)
#else
#define LOG_D(level,msg) LOG(level,msg)
#define LOG_V_D(level,msg) LOG_V(level,msg)
#define TRACE_D(level,trace,msg) TRACE(level,trace,msg)
#define TRACE_V_D(level,trace,msg) TRACE_V(level,trace,msg)
#endif


#define logFATAL(msg) LOG(LOGSEV_FATAL,msg)
#define logERROR(msg) LOG(LOGSEV_ERROR,msg)
#define logWARN(msg) LOG(LOGSEV_WARNING,msg)
#define logINFO(msg) LOG(LOGSEV_INFO,msg)
#define logNOTICE(msg) LOG(LOGSEV_NOTICE,msg)
#define logDEBUG(msg) LOG_D(LOGSEV_DEBUG0,msg)
#define logDEBUG0(msg) LOG_D(LOGSEV_DEBUG0,msg)
#define logDEBUG1(msg) LOG_D(LOGSEV_DEBUG1,msg)
#define logDEBUG2(msg) LOG_D(LOGSEV_DEBUG2,msg)
#define logDEBUG3(msg) LOG_D(LOGSEV_DEBUG3,msg)
#define logDEBUG4(msg) LOG_D(LOGSEV_DEBUG4,msg)
#define logDEBUG5(msg) LOG_D(LOGSEV_DEBUG5,msg)

#define logWARN_V(msg) LOG_V(LOGSEV_WARNING,msg)
#define logINFO_V(msg) LOG_V(LOGSEV_INFO,msg)
#define logNOTICE_V(msg) LOG_V(LOGSEV_NOTICE,msg)
#define logDEBUG_V(msg) LOG_V_D(LOGSEV_DEBUG0,msg)
#define logDEBUG0_V(msg) LOG_V_D(LOGSEV_DEBUG0,msg)
#define logDEBUG1_V(msg) LOG_V_D(LOGSEV_DEBUG1,msg)
#define logDEBUG2_V(msg) LOG_V_D(LOGSEV_DEBUG2,msg)
#define logDEBUG3_V(msg) LOG_V_D(LOGSEV_DEBUG3,msg)
#define logDEBUG4_V(msg) LOG_V_D(LOGSEV_DEBUG4,msg)
#define logDEBUG5_V(msg) LOG_V(LOGSEV_DEBUG5,msg)

#define trFATAL(trace,msg) TRACE(LOGSEV_FATAL,trace,msg)
#define trERROR(trace,msg) TRACE(LOGSEV_ERROR,trace,msg)
#define trWARN(trace,msg) TRACE(LOGSEV_WARNING,trace,msg)
#define trINFO(trace,msg) TRACE(LOGSEV_INFO,trace,msg)
#define trNOTICE(trace,msg) TRACE(LOGSEV_NOTICE,trace,msg)
#define trDEBUG(trace,msg) TRACE_D(LOGSEV_DEBUG0,trace,msg)
#define trDEBUG0(trace,msg) TRACE_D(LOGSEV_DEBUG0,trace,msg)
#define trDEBUG1(trace,msg) TRACE_D(LOGSEV_DEBUG1,trace,msg)
#define trDEBUG2(trace,msg) TRACE_D(LOGSEV_DEBUG2,trace,msg)
#define trDEBUG3(trace,msg) TRACE_D(LOGSEV_DEBUG3,trace,msg)
#define trDEBUG4(trace,msg) TRACE_D(LOGSEV_DEBUG4,trace,msg)
#define trDEBUG5(trace,msg) TRACE_D(LOGSEV_DEBUG5,trace,msg)

#define trWARN_V(trace,msg) TRACE_V(LOGSEV_WARNING,trace,msg)
#define trINFO_V(trace,msg) TRACE_V(LOGSEV_INFO,trace,msg)
#define trNOTICE_V(trace,msg) TRACE_V(LOGSEV_NOTICE,trace,msg)
#define trDEBUG_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG0,trace,msg)
#define trDEBUG0_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG0,trace,msg)
#define trDEBUG1_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG1,trace,msg)
#define trDEBUG2_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG2,trace,msg)
#define trDEBUG3_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG3,trace,msg)
#define trDEBUG4_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG4,trace,msg)
#define trDEBUG5_V(trace,msg) TRACE_V_D(LOGSEV_DEBUG5,trace,msg)

