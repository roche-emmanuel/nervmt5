
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/core/LogRecord.mqh>

BEGIN_TEST_PACKAGE(core_specs)

BEGIN_TEST_SUITE("Log system")

BEGIN_TEST_CASE("should have a valid log manager pointer")
  nvLogManager* lm = nvLogManager::instance();
  REQUIRE(lm!=NULL);
END_TEST_CASE()

BEGIN_TEST_CASE("should support creating a LogRecord")
  int level = nvLogSeverity::LOGSEV_DEBUG0;
  nvLogRecord rec(level,"myfile",1);
  rec.getStream() << "Hello world.";
END_TEST_CASE()

BEGIN_TEST_CASE("should support logging messages")

  // Then retrieve the log file and ensure we find the entry we just wrote.
  nvLogManager* lm = nvLogManager::instance();
  string fname = "test.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  //int level = nvLogSeverity::LOGSEV_DEBUG0;
  //if(level <= nvLogManager::instance().getNotifyLevel()) {
  //  nvLogRecord rec(level,__FILE__,__LINE__,"");
  //  rec.getStream() << "This is a message" ;
  //}

  logDEBUG("This is a debug message.");
  
  logger.close();

  // Read the content of the file:
  string content = nvReadFile(fname);

  string pred = "[DEBUG]   This is a debug message.\n";
  //MESSAGE("Content: '"<<content<<"'");
  //MESSAGE("Pred: '"<<pred<<"'");

  REQUIRE_EQUAL(content,pred);
END_TEST_CASE()

END_TEST_SUITE()


BEGIN_TEST_SUITE("Object class")

BEGIN_TEST_CASE("should allow creation of sample object")
  nvObject* obj = new nvObject();
  REQUIRE(obj!=NULL);
  delete obj;
  nvObject obj2;
  REQUIRE_EQUAL(obj2.toString(),"[nvObject]");
END_TEST_CASE()

END_TEST_SUITE()


BEGIN_TEST_SUITE("StringStream class")

BEGIN_TEST_CASE("should accept object as input")
  nvStringStream ss;
  nvObject obj;
  ss << "The object is: " << obj;
  
  REQUIRE_EQUAL(ss.str(),"The object is: [nvObject]");
END_TEST_CASE()

BEGIN_TEST_CASE("should accept object pointer as input")
  nvStringStream ss;
  nvObject* obj = new nvObject();
  ss << "The object is: " << obj;
  delete obj;
  REQUIRE_EQUAL(ss.str(),"The object is: [nvObject]");
END_TEST_CASE()

BEGIN_TEST_CASE("should support common types")
  {
    nvStringStream ss;
    ss << "bool: " << true;
    REQUIRE_EQUAL(ss.str(),"bool: true");
  }
  {
    nvStringStream ss;
    ss << "int: " << 12;
    REQUIRE_EQUAL(ss.str(),"int: 12");
  }
  {
    nvStringStream ss;
    ss << "uint: " << (uint)13;
    REQUIRE_EQUAL(ss.str(),"uint: 13");
  }
  {
    nvStringStream ss;
    ss << "double: " << 13.3;
    REQUIRE_EQUAL(ss.str(),"double: 13.3");
  }
  {
    nvStringStream ss;
    double arr[] = {1,2.2,3,4.1};
    ss << "arr: " << arr;
    REQUIRE_EQUAL(ss.str(),"arr: [1, 2.2, 3, 4.1]");
  }
END_TEST_CASE()

END_TEST_SUITE()


END_TEST_PACKAGE()
