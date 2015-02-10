
#include <nerv/unit/Testing.mqh>
#include <nerv/core/LogManager.mqh>

BEGIN_TEST_PACKAGE(core_specs)

BEGIN_TEST_SUITE("Log system")

BEGIN_TEST_CASE("should have a valid log manager pointer")
  nvLogManager* lm = nvLogManager::instance();
  ASSERT(lm==NULL);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
