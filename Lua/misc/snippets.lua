-- Simple initial test:
test_btn.action = function()
	self:debug("Should print this line.")
	self:debug("Timetag: ", os.time())
end