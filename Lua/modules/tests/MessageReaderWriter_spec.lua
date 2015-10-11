describe("MessageReaderWriter behavior", function()

  it("Should support writing/reading balance_value messages", function()
    local handler = require "network.MessageReaderWriter" ()
    local enums = require "mt5.Enums"
    local utils = require "mt5.utils"

    local tt = {
      mtype = enums.MSGTYPE_BALANCE_UPDATED,
      marketType = enums.MARKET_REAL,
      time = { year=2015, month=3, day=19, hour=12, min=1, sec=2, msec=345},
      value = 3000.23,
    }

    -- Try writing this message to stream:
    local data = handler:writeMessage(tt)

    -- check the length of that message:
    local len = 2+1+9+8
    assert_equal(#data,len)

    -- Now read the data back:

    local tt2 = handler:readMessage(data)

    assert_true(utils.compare(tt,tt2))
  end)  
end)
