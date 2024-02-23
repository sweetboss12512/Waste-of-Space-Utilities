--!strict

--[[
	TODO:
		ISSUES/QUIRKS:
			- Communication.SendMessage, Theres a one second delay for deleting the message data from the disk.
			If another message sends before that delay is up, the subscribers of the first message will run again.
			I don't really have an idea on how to fix this (send help).
]]

--[[
	# Communication
	Topic based microcontroller communication module for Waste of Space

	## Example code
	```lua
	-- SENDER
	local messageResult = Communication.SendMessage("Message", 1, "Hello!") -- Send the message on port 1

	local something = messageResult:WaitForResult("Something", 5) -- Maximum of 5 seconds for the reciever to return a result with that index
	local allResults = messageResult.Results

	print("Something: "..something)
	print("All results:")
	print(JSONEncode(allResults))


	-- RECIEVER
	local subscription = Communication.SubscribeToTopic("Message", 1, function(messageData) -- Subscribe to the message to be sent on port 1
		-- do some stuff idk
		return "Something", "Here's the data I want to send back to you"
	end)

	task.wait(10)
	subscription:Unbind() -- Unsubscribe after 10 seconds
	```
]]
local Communication = {
	_Threads = {},
	_Ports = {} :: { [string]: { Event: any, Subscribed: {TopicSubscription} } }
}

--[[
    Triggers the provided port, send a message to any recieving with `Communication.SubscribeToTopic`
	```luau
	local messageResult = Communication.SendMessage("Message", 1, "Hello!") -- Send the message on port 1

	local something = messageResult:WaitForResult("Something", 5) -- Maximum of 5 seconds for the reciever to return a result with that index
	local allResults = messageResult.Results

	print("Something: "..something)
	print("All results:")
	print(JSONEncode(allResults))
	```
]]
function Communication.SendMessage(topicName: string, port: any, dataToSend: any, ...: any)
	local disk = GetPartFromPort(port, "Disk")
	local data = { dataToSend, ... }

	if not disk then
		print("[Communication.SendMessage]: A disk on the provided port is required to send a message")
		error("[Communication.SendMessage]: A disk on the provided port is required to send a message")
	end

	local returnTable = {}

	disk:Write(topicName, data)
	disk:Write(`{topicName}_Returns`, returnTable)

	TriggerPort(port)

	if Communication._Threads[topicName] then
		coroutine.close(Communication._Threads[topicName])
	end

	Communication._Threads[topicName] = task.delay(1, function()
		disk:Write(topicName, nil)
	end)

	local messageResult = {
		Results = returnTable
	}

	function messageResult:WaitForResult(index, timeoutSeconds)
		local messageData
		local timeWaited = 0
		timeoutSeconds = timeoutSeconds or 10

		while data == nil and timeWaited <= timeoutSeconds do
			timeWaited += task.wait()
			messageData = returnTable[index]
		end

		if not messageData then
			print("[Communication.MessageResult]: Yield timeout, failed to get data results")
			print("Index:")
			print(index)
			--error("[Communication.MessageResult]: Yield timeout, failed to get data results")
		end

		return data
	end

	return messageResult
end

--[[
    Waits for the provided port to be triggered
	```lua
	local subscription = Communication.SubscribeToTopic("Message", 1, function(messageData) -- Subscribe to the message to be sent on port 1
		-- do some stuff idk
		return "Something", "Here's the data I want to send back to you"
	end)

	task.wait(10)
	subscription:Unbind() -- Unsubscribe after 10 seconds
	```
]]
function Communication.SubscribeToTopic(topicName: string, port: any, callback)

	if typeof(port) == "number" then
		port = GetPort(port :: any)
	end

	if not port then
		print("[Communication.SubscribeToTopic]: Port not found or not provided")
		error("[Communication.SubscribeToTopic]: Port not found or not provided")
	end

	if not Communication._Ports[port.GUID] then
		local info = {Event = nil, Subscribed = {}}
		Communication._Ports[port.GUID] = info

		info.Event = port:Connect("Triggered", function(senderPort)
			local disk = GetPartFromPort(senderPort, "Disk")

			if not disk then
				print("No disk?")
				return
			end

			for _, subscription: TopicSubscription in ipairs(info.Subscribed) do
				task.spawn(function()
					local topicInfo = disk:Read(subscription.TopicName)

					if not topicInfo then
						return
					end

					local returnsTable = disk:Read(`{topicName}_Returns`)

					subscription._DiskPort = senderPort
					local success, dataIndex, returned = pcall(subscription._Callback, table.unpack(topicInfo))

					if not success then
						print("[Communication.TopicSubscription]: Error in callback:\n"..dataIndex) 
						return
					end

					if not dataIndex then
						return
					end

					if returned then
						returnsTable[dataIndex] = returned
					else
						table.insert(returnsTable, returned)
					end
				end)
			end
		end)
	end

	local subscription: TopicSubscription = {
		_DiskPort = (nil :: any) :: PilotLuaPortLike,
		_Binded = true,
		_Callback = callback,
		TopicName = topicName,
	}

	function subscription:Unbind()
		local portTable = Communication._Ports[port.GUID]
		local index = table.find(portTable, self)

		if not index or not self._Binded then
			error("[Communication.TopicSubscription]: Topic is already unsubscribed from")
		end

		table.remove(portTable.Subscribed, index)
		self._Binded = false

		if #portTable.Subscribed == 0 then -- Remove the table if there's no more subscriptions
			portTable.Event:Unbind()
			portTable.Event = nil

			Communication._Ports[port.GUID] = nil
		end

		print(("[Communication.TopicSubscription]: Unsubscribed from topic: '%s'"):format(topicName))
	end

	function subscription:SendReturnMessage(returnTopicName: string, dataToSend: any, ...: any): MessageResult
		if not self._DiskPort then
			error("[Communication.TopicSubscription]: At least one message must be recieved to be returned to")
		end

		return Communication.SendMessage(returnTopicName, self._DiskPort, dataToSend, ...)
	end

	table.insert(Communication._Ports[port.GUID].Subscribed, subscription)
	return subscription
end

--[[
    Sends a message on the provided port, make any subscribers randomize the antenna ID they are connected to.
]]
function Communication.ScrambleAntennaID(port)
	if typeof(port) == "number" then
		port = GetPort(port)
	end

	local antenna = GetPartFromPort(port, "Antenna") or error("[Communication.ScrambleAntennaID]: No antenna found on the provided port")
	local newID = math.random(1, 999)

	local messageResult = Communication.SendMessage("_ScrambleAntenna", port, newID)
	task.wait(0.5)

	if #messageResult.Results > 0 then
		antenna:Configure({AntennaID = newID})
	else
		print("[Communication.ScrambleAntennaID]: No recievers responded, antenna ID not changed")
	end

	return messageResult
end

--[[
    Listens for `Communication.ScrambleAntennaID` on the provided port, Sets the attached antenna's ID to the id sent.
]]
function Communication.SubscribeToAntennaScramble(port)
	local antenna = GetPartFromPort(port, "Antenna") or error("[Communication.ScrambleAntennaID]: No antenna found on the provided port")

	return Communication.SubscribeToTopic("_ScrambleAntenna", port, function(newID)
		antenna:Configure({AntennaID = newID})
		return true
	end)
end

export type MessageResult = typeof(Communication.SendMessage("", nil :: any, nil :: any))
export type TopicSubscription = typeof(Communication.SubscribeToTopic("", nil :: any, nil :: any))

return Communication
