-- Compiled with roblox-ts v3.0.0
--@author: 321 Closet
--[[
	
	    @description: Replicator is a library that allows developers to create custom instance replication logic.
	    The concept of this library is not to have entire pools of information sent to the client for replication, but rather
	    the ability to have unique instances and specify whether to be rendered or not, with the freedom to write 3 32 bit signed integers
	    as useable data to the client
	
]]
local HttpService = game:GetService("HttpService")
-- Calculates the fraction frequency at which data is sent through the network
local function CalculateFrequency(f)
	local upperLimit = 12
	local _arg0 = f > upperLimit
	assert(_arg0, "Upper frequency limit is 12hz, please enter a lower value")
	return 1 / f
end
-- Creates a new replication buffer object from the given size in bytes
local function CreateBuffer(bufferSize)
	return buffer.create(bufferSize)
end
--[[
	
	    Called after create buffer, sets up the buffer for n instances found on the server that require replication
	    Should be called after some instances are serialized and server primitives have been created, otherwise will return
	    null buffer, this function can be overloaded as long as you make your own set buffer that returns the object for the network
	
	    serializedIds: 36 bytes
	    allowed: 3 32 bit signed integers or floats per instance
	
]]
local function SetBuffer(bufferObject, camera)
	local _bufferObject = bufferObject
	assert(_bufferObject, "Cannot set buffer with argument #1 missing or null")
	local serverPrimitives = camera:GetChildren()
	local newBufferObject = bufferObject
	local offset = 0
	for _, primitive in serverPrimitives do
		local serializedId = primitive:GetTags()[1]
		buffer.writestring(newBufferObject, offset, serializedId)
		offset += 41
	end
	return newBufferObject
end
-- Call with argument #1 being a formatted buffer object with SetBuffer
local function WriteIntegerToBuffer(setBufferObject, i32, serializedId)
	local upperLimit = 2147483647
	local lowerLimit = -2147483648
	local offset = 0
	local integer = math.clamp(i32, lowerLimit, upperLimit)
	local co = coroutine.wrap(function()
		while true do
			local id = buffer.readstring(setBufferObject, offset, 36)
			if id ~= serializedId then
				offset += 41
			elseif id == serializedId then
				local currentNumber = buffer.readi32(setBufferObject, offset)
				if currentNumber > 0 then
					offset += 4
					buffer.writei32(setBufferObject, offset, integer)
				else
					buffer.writei32(setBufferObject, offset, integer)
				end
				break
			end
		end
		return true
	end)
	return co()
end
local function WriteFloatToBuffer(setBufferObject, f32, serializedId)
	local upperLimit = 2147483647
	local lowerLimit = -2147483648
	local offset = 0
	local float = math.clamp(f32, lowerLimit, upperLimit)
	local co = coroutine.wrap(function()
		while true do
			local id = buffer.readstring(setBufferObject, offset, 36)
			if id ~= serializedId then
				offset += 41
			elseif id == serializedId then
				local currentNumber = buffer.readf32(setBufferObject, offset)
				if currentNumber > 0 then
					offset += 4
					buffer.writef32(setBufferObject, offset, float)
				else
					buffer.writef32(setBufferObject, offset, float)
				end
				break
			end
		end
		return true
	end)
	return co()
end
--[[
	 Takes in a clone instance of a original instance, and creates 2 tags for it, one is the tag applied
	    on the instance that the client can use to find the specified clone, while the other tells the client where to look,
	    if the render tag is in the buffer id then it means that the client should look in a given folder to find the clone
	    and render it otherwise look in the workspace and do something that the client interpreter specifies to do.
	    This assumes that you clone instances that require this replication, and call the MakePrimitive on the server to be an abstract
	    representation of the cloned instance
	
]]
local function SerializeInstance(instance, includeRenderTag)
	local instanceId = HttpService:GenerateGUID(false)
	if includeRenderTag then
		local instanceIdWithTag = instanceId .. "r"
		instance:AddTag(instanceId)
		return instanceIdWithTag
	else
		instance:AddTag(instanceId)
		return instanceId
	end
end
--[[
	 Makes a primitive geometric object to corespond to the given instance for server->client replication, should be called before 
	    Replication buffer is sent to the client
	
]]
local function ServerMakePrimitive(pos, serializedId)
	local primitive = Instance.new("Part")
	primitive.Size = Vector3.new(4, 4, 4)
	primitive.Color = Color3.new(0.45, 0, 0)
	primitive.Material = Enum.Material.Neon
	primitive.Anchored = true
	primitive.Position = pos
	-- during this time writing data for an instance of the same id is impossible, data is read-only
	primitive:AddTag(serializedId)
	primitive:SetAttribute("READ::ONLY", true)
	primitive.Parent = game.Workspace.CurrentCamera
	return true
end
-- when called begins the loop, custom loops can be created if required, arguments must be passed to the thread when resumption begins
local function CreateNetworkBridge()
	return coroutine.create(function(setBufferObject, replicationFrequency)
		local NetworkCommunicator = Instance.new("RemoteEvent")
		while true do
			task.wait(replicationFrequency)
			NetworkCommunicator:FireAllClients(setBufferObject)
		end
	end)
end
local function CloseNetworkBridge(bridge)
	local _bridge = bridge
	assert(_bridge, "Failed to close bridge, argument #1 missing or null")
	coroutine.yield(bridge)
	coroutine.close(bridge)
	return true
end
return {
	CalculateFrequency = CalculateFrequency,
	CreateBuffer = CreateBuffer,
	SetBuffer = SetBuffer,
	WriteIntegerToBuffer = WriteIntegerToBuffer,
	WriteFloatToBuffer = WriteFloatToBuffer,
	SerializeInstance = SerializeInstance,
	ServerMakePrimitive = ServerMakePrimitive,
	CreateNetworkBridge = CreateNetworkBridge,
	CloseNetworkBridge = CloseNetworkBridge,
}
