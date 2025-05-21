-- Compiled with roblox-ts v3.0.0
-- @author: 321_Closet
--[[
	 
	    @description: a multi-use library written in typescript
	    indented for use inside the berry game framework for ROBLOX
	
]]
local MAX_LIST_LENGTH = 10
local c_EnumList
do
	c_EnumList = setmetatable({}, {
		__tostring = function()
			return "c_EnumList"
		end,
	})
	c_EnumList.__index = c_EnumList
	function c_EnumList.new(...)
		local self = setmetatable({}, c_EnumList)
		return self:constructor(...) or self
	end
	function c_EnumList:constructor(name, array)
		self.l_name = name
		local _arg0 = array.length > MAX_LIST_LENGTH
		assert(_arg0, "Enum Lists may not exceed threshold of 10 strings")
		self.list = array
		table.freeze(self.list)
	end
	function c_EnumList:BelongsTo(obj)
		local i = 0
		do
			i = 0
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i <= self.list.length) then
					break
				end
				if self.list[i + 1] == obj then
					return true
				else
					return false
				end
			end
		end
	end
	function c_EnumList:GetEnumItems()
		return self.list
	end
	function c_EnumList:GetName()
		return self.l_name
	end
end
return {
	c_EnumList = c_EnumList,
}
