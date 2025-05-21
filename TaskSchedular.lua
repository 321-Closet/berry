-- Compiled with roblox-ts v3.0.0
-- @author: 321_Closet
--[[
	
	   @description: a multi-use schedular class to create task objects and schedule execution of threads and functions
	   in translation units
	
]]
local HttpService = game:GetService("HttpService")
local ScheduleParams
do
	ScheduleParams = setmetatable({}, {
		__tostring = function()
			return "ScheduleParams"
		end,
	})
	ScheduleParams.__index = ScheduleParams
	function ScheduleParams.new(...)
		local self = setmetatable({}, ScheduleParams)
		return self:constructor(...) or self
	end
	function ScheduleParams:constructor(recurse, wait)
		self.PARAMS = {}
		local _recurse = recurse
		assert(_recurse ~= 0 and _recurse == _recurse and _recurse, "Attempt to create object schedule params with argument 1 missing or null")
		local _wait = wait
		assert(_wait ~= 0 and _wait == _wait and _wait, "Attempt to create object schedule params with argument 2 missing or null")
		local _pARAMS = self.PARAMS
		local _recurse_1 = recurse
		table.insert(_pARAMS, 1, _recurse_1)
		local _pARAMS_1 = self.PARAMS
		local _wait_1 = wait
		table.insert(_pARAMS_1, 2, _wait_1)
	end
end
local c_TaskSchedular
do
	c_TaskSchedular = setmetatable({}, {
		__tostring = function()
			return "c_TaskSchedular"
		end,
	})
	c_TaskSchedular.__index = c_TaskSchedular
	function c_TaskSchedular.new(...)
		local self = setmetatable({}, c_TaskSchedular)
		return self:constructor(...) or self
	end
	function c_TaskSchedular:constructor()
		self.schedule = {}
		self.ThreadCache = {}
		local object = self
		return self
	end
	function c_TaskSchedular:ScheduleThread(params, ScheduleParams, co)
		local _scheduleParams = ScheduleParams
		assert(_scheduleParams, "Attempt to call function ScheduleFunction with missing argument #2")
		local _co = co
		assert(_co, "Attempt to call function ScheduleFunction with missing argument #3")
		local recurse = ScheduleParams.PARAMS[1]
		if recurse > 0 then
			local elapse = ScheduleParams.PARAMS[2]
			do
				local i = 0
				local _shouldIncrement = false
				while true do
					if _shouldIncrement then
						i += 1
					else
						_shouldIncrement = true
					end
					if not (i <= recurse) then
						break
					end
					task.wait(elapse)
					coroutine.resume(co, params)
				end
			end
		end
	end
	function c_TaskSchedular:ScheduleFunction(params, ScheduleParams, fn)
		local _scheduleParams = ScheduleParams
		assert(_scheduleParams, "Attempt to call function ScheduleFunction with missing argument #2")
		local _fn = fn
		assert(_fn, "Attempt to call function ScheduleFunction with missing argument #3")
		local recurse = ScheduleParams.PARAMS[1]
		if recurse > 0 then
			local elapse = ScheduleParams.PARAMS[2]
			local co = coroutine.wrap(function()
				local results = {}
				local offset = 0
				do
					local i = 0
					local _shouldIncrement = false
					while true do
						if _shouldIncrement then
							i += 1
						else
							_shouldIncrement = true
						end
						if not (i <= recurse) then
							break
						end
						task.wait(elapse)
						local result = fn(params)
						local _results = results
						local _offset = offset
						table.insert(_results, _offset + 1, result)
						offset += 1
					end
				end
				return results
			end)
			return co()
		end
	end
	function c_TaskSchedular:Spawn(f)
		task.spawn(f)
	end
	function c_TaskSchedular:SpawnAfter(wait, f)
		task.delay(wait, function()
			task.spawn(f)
		end)
	end
	function c_TaskSchedular:CreateThread(callback)
		local threadId = HttpService:GenerateGUID(false)
		local co = coroutine.create(callback)
		self.ThreadCache[threadId] = co
		return threadId
	end
	function c_TaskSchedular:ResumeThread(threadId, args)
		local _threadId = threadId
		assert(_threadId ~= "" and _threadId, "Attempt to resume thread with argument #1 missing or nil")
		local co = self.ThreadCache[threadId]
		local _co = co
		assert(_co ~= 0 and _co == _co and _co ~= "" and _co, "Unable to find thread from id")
		coroutine.resume(co, args)
		self.schedule[threadId] = nil
	end
	function c_TaskSchedular:CancelThread(threadId)
		local _arg0 = self.ThreadCache[threadId]
		assert(_arg0 ~= 0 and _arg0 == _arg0 and _arg0 ~= "" and _arg0, "Attempt to cancel non-existant thread")
		local co = self.ThreadCache[threadId]
		coroutine.yield(co)
		coroutine.close(co)
	end
	function c_TaskSchedular:PauseThread(x, threadId)
		local co = self.ThreadCache[threadId]
		local _co = co
		assert(_co, "Attempt to pause non-existant thread")
		coroutine.yield(co)
		task.delay(x, function()
			coroutine.resume(co)
		end)
	end
end
return {
	ScheduleParams = ScheduleParams,
	c_TaskSchedular = c_TaskSchedular,
}
