local MAX_PORT_NUMBER = 10

--[[
	Searches port ids from `1` to `maxPortNumber` for provided `partName`
	@param errorIfNotFound - Raise an error if the part is not found, use this if your code will break without the part
	```luau
	local Screen = SearchPorts("Screen", true) -- true to error if part isn't found
	```
]]
local function SearchPorts(partName: PilotLuaPartList | string, errorIfNotFound: boolean?, maxPortNumber: number?): PilotLuaPart & any	
	local part
	
	for i = 1, maxPortNumber or MAX_PORT_NUMBER do
		part = GetPartFromPort(i, partName)
		
		if part then
			return part
		end
	end

	
	if errorIfNotFound then
		print(`[SearchPorts]: Failed to find part '{partName}. Searched ports 1-{maxPortNumber}`)
		error(`[SearchPorts]: Failed to find part '{partName}. Searched ports 1-{maxPortNumber}`)
	end

	return part
end

return SearchPorts
