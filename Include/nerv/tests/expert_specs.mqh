
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/Security.mqh>

BEGIN_TEST_PACKAGE(expert_specs)

BEGIN_TEST_SUITE("Security class")

BEGIN_TEST_CASE("should be able to create Security instance")
	nvSecurity sec("EURUSD",5,1e-5);
	REQUIRE_EQUAL(sec.getSymbol(),"EURUSD");
	REQUIRE_EQUAL(sec.getDigits(),5);
	REQUIRE_EQUAL(sec.getPoint(),1e-5);
END_TEST_CASE()

BEGIN_TEST_CASE("should support security copy construction")
	nvSecurity sec("EURUSD",5,1e-5);

	nvSecurity sec2(sec);
	REQUIRE_EQUAL(sec2.getSymbol(),"EURUSD");
	REQUIRE_EQUAL(sec2.getDigits(),5);
	REQUIRE_EQUAL(sec2.getPoint(),1e-5);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
