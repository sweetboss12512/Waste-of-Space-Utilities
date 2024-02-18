local MAX_PORT_NUMBER = 10

--[[
	Searches port ids from `1` to `maxPortNumber` for provided `partName`
	Automatically filters repeat parts
	```luau
	local ScreenParts = SearchPortsMultiple("Screen", true) -- true to error if no parts are found
	```
]]
return function(partName: PilotLuaPartList | string, errorIfNotFound: boolean?, maxPortNumber: number?): { PilotLuaPart & any }
	local parts = {}
	local guids = {}

	for i = 1, maxPortNumber or MAX_PORT_NUMBER do
		local partsOnPort = GetPartsFromPort(i, partName)

		for _, part in partsOnPort do
			if not guids[part.GUID] then
				table.insert(parts, part)
			end
		end
	end

	if errorIfNotFound and #parts == 0 then
		print(`[SearchPortsMultiple]: Failed to find any parts '{partName}. Searched ports 1-{maxPortNumber}`)
		error(`[SearchPortsMultiple]: Failed to find parts '{partName}. Searched ports 1-{maxPortNumber}`)
	end

	return parts
end
