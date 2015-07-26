
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/Security.mqh>
#include <nerv/expert/Trader.mqh>
#include <nerv/expert/PeriodTrader.mqh>

BEGIN_TEST_PACKAGE(expert_specs)

BEGIN_TEST_SUITE("Security class")

BEGIN_TEST_CASE("should be able to create Security instance")
	nvSecurity sec("EURUSD");
	REQUIRE_EQUAL(sec.getSymbol(),"EURUSD");
	REQUIRE_EQUAL(sec.getDigits(),5);
	REQUIRE_EQUAL(sec.getPoint(),1e-5);
END_TEST_CASE()

BEGIN_TEST_CASE("should support security copy construction")
	nvSecurity sec("EURUSD");

	nvSecurity sec2(sec);
	REQUIRE_EQUAL(sec2.getSymbol(),"EURUSD");
	REQUIRE_EQUAL(sec2.getDigits(),5);
	REQUIRE_EQUAL(sec2.getPoint(),1e-5);
END_TEST_CASE()

// THe following test will produce an error and thus is disabled.
XBEGIN_TEST_CASE("should trigger an error for invalid security name")
	nvSecurity sec("XYZUSD");
END_TEST_CASE()

END_TEST_SUITE()


XBEGIN_TEST_SUITE("Trader class")

BEGIN_TEST_CASE("should be able to create a trader instance")
	nvSecurity sec("EURUSD");

	nvTrader trader(sec);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to check current position")
	nvSecurity sec("EURUSD");

	nvTrader trader(sec);
	trader.closePosition();

	REQUIRE_EQUAL(trader.hasPosition(),false);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to open/close a position")
	nvSecurity sec("EURUSD");

	nvTrader trader(sec);
	trader.closePosition();

	// Open a position:
	REQUIRE_EQUAL(trader.hasPosition(),false);
	trader.sendDealOrder(ORDER_TYPE_BUY,0.01);
	REQUIRE_EQUAL(trader.hasPosition(),true);
	trader.closePosition();
	REQUIRE_EQUAL(trader.hasPosition(),false);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to update a stoploss on a position")
	nvSecurity sec("EURUSD");

	nvTrader trader(sec);
	trader.closePosition();

	// Open a position:
	REQUIRE_EQUAL(trader.hasPosition(),false);
	trader.sendDealOrder(ORDER_TYPE_BUY,0.01,0.0,0.00030);
	REQUIRE_EQUAL(trader.hasPosition(),true);
	// Check the current position price and stoploss:
	double price = PositionGetDouble(POSITION_PRICE_OPEN);
	double ask = SymbolInfoDouble("EURUSD",SYMBOL_ASK);
	double bid = SymbolInfoDouble("EURUSD",SYMBOL_BID);
	REQUIRE_EQUAL(price,ask);

	double sl = PositionGetDouble(POSITION_SL);
	REQUIRE(MathAbs(sl-(bid-0.00030))<1e-6);

	// Now try updating the stop loss:
	trader.updateSLTP(bid-0.00040);

	trader.selectPosition(); // Don't forget to update the position details.
	sl = PositionGetDouble(POSITION_SL);
	REQUIRE(MathAbs(sl-(bid-0.00040))<1e-6);

	trader.closePosition();
	REQUIRE_EQUAL(trader.hasPosition(),false);
END_TEST_CASE()


END_TEST_SUITE()

BEGIN_TEST_SUITE("PeriodTrader class")

BEGIN_TEST_CASE("Default implementation should throw on handleBar()")
	nvSecurity sec("EURUSD");

	class MyData {
	public:
		bool state;
	};

	MyData data;
	data.state = false;

	class MyTrader : public nvPeriodTrader
	{
	protected:
		MyData* _data;

	public:
		MyTrader(const nvSecurity& sec, MyData* data) : nvPeriodTrader(sec,PERIOD_H1) {
			_data = data;
		};

		void handleBar()
		{
			_data.state = true;
		}
	};

	MyTrader trader(sec,GetPointer(data));

	// Ensure that handleBar is called when we call onTick:
	trader.onTick();
	REQUIRE(data.state);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
