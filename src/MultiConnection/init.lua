type AnyFunction = (...any) -> ...any

export type MultiConnectionHandler = {
	Connect: (self: MultiConnectionHandler, eventName: string, callback: AnyFunction, ...any) -> MultiConnection,
}

type MultiConnection = {
	Unbind: (self: MultiConnection) -> (),
}

local function MultiConnection(callbackTable: { AnyFunction }, callback: AnyFunction): MultiConnection
	local connection = {} :: MultiConnection

	function connection:Unbind()
		local index = table.find(callbackTable, callback)

		if index then
			table.remove(callbackTable, index)
		end
	end

	return connection
end

--[[
    # Multi Event Handler
    Simple class for allowing multiple connections to the same event

    Currently in WOS stable, parts only allow a single event callback per event.
	This solves that.

    ## Example code
    ```luau
    local Keyboard = GetPartFromPort(1, "Keyboard")
    local KeyboardEventHandler = MultiConnectionHandler(Keyboard)

    for i = 1, 3 do
        local connection
        
        connection = KeyboardEventHandler:Connect("TextInputted", function(...)
            print(#{...})
            print(`Connection #{i} fired!`)
            print("All args: "..table.concat({...}, ", "))
            task.wait(2)
            connection:Unbind()
            print(`Unbinded connection #{i}`)
        end)
    end
    ```
]]
local function MultiConnectionHandler(part: PilotLuaPart)
	local handler = {} :: MultiConnectionHandler
	local handlerEvents: { [string]: { AnyFunction } } = {}

	--[[
		4/22/24 sweetboss151 here. This is just a quick way to future proof this class for unstable.
		Unstable allows multiple connections to the same event now. This class is unecessary.
	]]

	local eventConnections: { [string]: PilotLuaEventConnection } = {}

	function handler:Connect(eventName, callback: AnyFunction)
		local callbackTable = handlerEvents[eventName]

		if not callbackTable then
			callbackTable = {}

			if not eventConnections[eventName] then
				-- Only connect this ONCE
				local event = part:Connect(eventName, function(...)
					local allArgs = { ... }

					for _, func in ipairs(callbackTable :: any) do
						task.spawn(function()
							local success, errormsg = pcall(func, table.unpack(allArgs))

							if not success then
								print(`[MultiConnectionHandler]: Error in event callback '{eventName}' {errormsg}`)
							end
						end)
					end
				end)

				eventConnections[eventName] = event
			end

			handlerEvents[eventName] = callbackTable
		end

		local connection = MultiConnection(callbackTable, callback)
		table.insert(callbackTable, callback)
		return connection
	end
	return handler
end

return MultiConnectionHandler
