local Class = createClass{name="ImageManager",bases={"base.Object"}};

--[[
Class: gui.ImageManager

Singleton object used to handle all the images resources.

This class inherits from <base.Object>.
]]

--[=[
--[[
Constructor: ImageManager

Create a new instance of the class.

Parameters:
	 No parameter
]]
function ImageManager(options)
]=]
function Class:initialize(options)
	self._images = {};
	self._concatSeparator = "@"
	self._defaultSize = 16;
	self._defaultExt = "png"
	self._defaultPath = root_path .."/assets/images/"	
end

function Class:createImage(options)
	local ext = options.ext or self._defaultExt
	local path = options.path or self._defaultPath
	local name = options.name or options[1]

	local filename = path .. name .. "."..ext
	local image, err = im.FileImageLoad(filename);

	self:check(err == im.ERR_NONE or not err,"Error while loading image from file ",filename,": ",im.ErrorStr(err))    

	local ww=options.width or options.size or self._defaultSize
	local hh=options.height or options.size or self._defaultSize
  local count, new_image = im.ProcessResizeNew(image, ww, hh, 3)

  return iup.ImageFromImImage(new_image)
end

-- Method used to retrieve an image by its name
-- or to create it if not found yet.
function Class:getImage(options)
	options = type(options)=="string" and {name=options} or options
	self:check(options and (options.name or options[1]),"Invalid image name.")
	
	local ww=options.width or options.size or self._defaultSize
	local hh=options.height or options.size or self._defaultSize

	local fname=options.name.."_"..ww.."x"..hh

	local img = self._images[fname]
	if not img then
		img = self:createImage(options)
		self._images[fname] = img
	end
	
	return img	
end

-- return singleton
return Class()