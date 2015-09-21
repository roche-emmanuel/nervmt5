--[[
 * ClassBuilder: a Minimal wrapper around the LOOP library to simplify class generation in lua
 * Copyright (c) 2011-2013 Emmanuel ROCHE
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

 * Authors: Emmanuel ROCHE.
]]
 
local className = "ClassBuilder"

print("Generating class ",className)

local oo = require "loop.cached"
local Object = require "base.ObjectBase" -- provided externally.

local Class = oo.class({},Object)
Class.CLASS_NAME = className

function Class:__init(options,instance)
	local obj = Object:__init(instance or {})
	obj = oo.rawnew(self,obj)
	obj._TRACE_ = className
	return obj
end

-- main function to create a new class
function Class:__call(options)
	self:check(options,"Invalid options to build class.")
	
	options.bases = type(options.bases)=="string" and {options.bases} or options.bases or {}	
	self:check(type(options.name)=="string" and options.name ~= "","Invalid options.name field.")
	
	-- actual bases tables:
	local bases = {}
	local bases_inv = {} -- we need to invert the base classes order in order to override the fields properly.
	
	for _,base in ipairs(options.bases) do
		table.insert(bases, type(base)=="string" and require(base) or base)
	end
	for _,base in ipairs(bases) do
		table.insert(bases_inv, 1, base)
	end
	
	if self.debug_v then
		self:debug_v("Generating class ",options.name)
	end
	
	local result = oo.class({},unpack(bases_inv))
	result._CLASSNAME_ = options.name
	result._LIBRARYNAME_ = options.library or "vbs"
	result._TRACE_ = options.name 
	result.super = bases[1]
	result.supers = bases
	
	function result:__init(opt,instance)
		local obj = instance or {}
		
		for _,base in ipairs(bases) do
			obj = base:__init(opt,obj)
		end
		
		obj =  oo.rawnew(self,obj)
		
		-- obj:new(opt)
		
		if not instance then
			obj:doInitialize(opt)
		end
		
		return obj 
	end

	-- function result:new(options)
		-- do nothing by default. can be overriden.
	-- end
	
	function result:doInitialize(opt,class,done)
		done = done or {}
		class = class or oo.classof(self)
		
		if class.new and not done[class.new] then
			done[class.new]=true
			class.new(self,opt)
		end
		
		-- We have to invert the order of the super classes
		-- to respect the initialization order:
		local bases = {}
		for _,base in oo.supers(class) do
			table.insert(bases, 1, base)
		end
		
		for _,base in ipairs(bases) do
			if base.doInitialize then
				base.doInitialize(self,opt,base,done)
			end
		end
		
		if class.initialize and not done[class.initialize] then
			done[class.initialize] = true -- this is needed to ensure we don't execute parent initialize func multiple times
			-- when the child initialize func is not defined.
			class.initialize(self,opt)
		end
	end
	
	function result:delete()
		self:debug2_v("Deleting ",self._CLASSNAME_," object.")
	end

	-- return the resulting class:
	return result;
end

-- Function alias for class creation:
Class.create = Class.__call

return Class
