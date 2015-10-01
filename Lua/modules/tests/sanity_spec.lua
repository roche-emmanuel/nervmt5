describe("Testing Framework behavior", function()

  it("Should support simple asserts", function()
  	assert_true(true)
    assert_false(false)
  end)

  it("Should not convert wide char to char that easily", function()
    -- Currently converting from 2bytes to 1byte string is done using a call on string.char
    -- we check here that this is only valid for small number:

    assert_truthy(string.char(123))

    assert_error(function()
	    local res = string.char(1234)
	  end)
  end)
  
end)
