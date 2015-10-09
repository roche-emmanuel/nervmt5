local enums = require "mt5.Enums"

describe("MT5Control behavior", function()
  local testMessageParsing
  before(function()
    testMessageParsing = function(tt,len)
      local evtman = require "base.EventManager"
      local rw = require "network.MessageReaderWriter" ()
      local handler = require "base.EventHandler" ()

      local utils = require "mt5.utils"
      local zmq = require "zmq"

      -- Try writing this message to stream:
      local data = rw:writeMessage(tt)
      assert_equal(#data,len)
      
      local msg = nil
      handler:on("msg_".. tt.mtype,function(data)
        msg = data;
      end)

      -- send the message on the socket:
      local client = zmq.socket(zmq.PUSH);
      client:connect("tcp://localhost:22223");

      client:send(data)
      sleep(0.1)

      handler:removeAllListeners()
      client:close()

      -- expect the message to be received:
      assert_truthy(msg)
      assert_true(utils.compare(tt,msg))
    end
  end)

  it("Should support receiving balance_value messages", function()
    local tt = {
      mtype = enums.MSGTYPE_BALANCE_UPDATED,
      marketType = enums.MARKET_REAL,
      time = { year=2015, month=3, day=19, hours=12, mins=1, secs=2, msecs=345},
      value = 3000.23,
    }

    -- check the length of that message:
    local len = 2+1+9+8

    testMessageParsing(tt,len);
  end)

  it("Should support receiving trader weight updated messages", function()

    local tt = {
      mtype = enums.MSGTYPE_TRADER_WEIGHT_UPDATED,
      symbol = "EURUSD",
      time = { year=2015, month=3, day=19, hours=12, mins=1, secs=2, msecs=345},
      value = 0.123,
    }

    -- check the length of that message:
    local len = 2+10+8

    testMessageParsing(tt,len);
  end)  
end)
