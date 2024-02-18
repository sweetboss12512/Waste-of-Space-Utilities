--!strict

-- local Debugger = require("../Modules/Debugger")({ Name = "REMOVE THIS", BeepOnPrint = false })
local MicroStorage = {}
MicroStorage.__index = MicroStorage

local SyncTable = {}
SyncTable.__index = SyncTable

export type MicroStorage = typeof(setmetatable({}, MicroStorage)) & {
	_Disk: PilotLuaDisk,
	_Micro: PilotLuaMicrocontroller,
	_AccessKey: string,
}

export type SyncTable<T> = typeof(setmetatable({}, SyncTable)) & {
	Data: T,
	_MicroStorage: MicroStorage
}

type GetMicroData = (string, { [string]: any }?) -> ({ [string]: any }, {[string]: any})

local function RunMicrocontroller(micro: PilotLuaMicrocontroller)
	local poly = GetPartFromPort(micro, "Polysilicon")
		or error("[RunMicrocontroller]: No polysilicon found on microcontroller")
	local port = GetPartFromPort(poly, "Port") or error("[RunMicrocontroller]: No port found on polysilicon")

	poly:Configure({ PolysiliconMode = 0 })
	TriggerPort(port)
end

--- Turns the provided value into a string that can be ran by a micro
local function SerializeValue(value: any): string
	local valueType = type(value)

	if valueType == "string" then
		return ("%q"):format(value)
	elseif valueType == "boolean" or valueType == "number" then
		return tostring(value)
	elseif valueType == "table" then
		return ("%q"):format(JSONEncode(value))
	end

	error(`[SerializeValue]: Type {valueType} is not serializable`)
end

function MicroStorage.new(disk: PilotLuaDisk, dataMicro: PilotLuaMicrocontroller, accessKey: string): MicroStorage
	local self = setmetatable({}, MicroStorage) :: MicroStorage

	self._Disk = disk
	self._Micro = dataMicro
	self._AccessKey = accessKey
	return self
end

--- ### NOTE: Tables will automatically be JSON encoded if passed
function MicroStorage.Write(self: MicroStorage, key: string, value: any)
	local MicroData

	local GetMicroData: GetMicroData = self._Disk:Read("_GetMicroData")
	local GetMicroDataLoaded: boolean

	if GetMicroData then
		MicroData = GetMicroData(self._AccessKey, { [key] = value })
		GetMicroDataLoaded = true
	else
		-- Assume the data micro is off
		MicroData = {}
		GetMicroDataLoaded = false
	end

	if typeof(MicroData) ~= "table" then
		print(`[MicroStorage.Write]: Data microcontroller failed to load keys, access key may be incorrect`)
		error(`[MicroStorage.Write]: Data microcontroller failed to load keys, access key may be incorrect`)
	end

	MicroData[key] = value
	local snippet: { string } = {}

	table.insert(snippet, "--test")
	table.insert(snippet, "local Disk")

	table.insert(
		snippet,
		[[
for i = 1, 10 do
    Disk = GetPartFromPort(i, "Disk")
    if Disk then break end
end]]
	)

	table.insert(snippet, "local KeyCache = {}") -- Table for caching newly added keys
	table.insert(snippet, 'Disk:Write("_GetMicroData", function(accessKey, newKeys)')
	table.insert(snippet, `\tif accessKey ~= "{self._AccessKey}" then return "Invalid Key" end`)
	table.insert(snippet, "\tlocal Data = {}")

	for k, v in pairs(MicroData) do
		table.insert(snippet, ("\tData[%q] = %s"):format(k, SerializeValue(v)))
	end

	table.insert(
		snippet,
		[[
    if newKeys then
        for k, v in pairs(newKeys) do
            KeyCache[k] = v
			Data[k] = v
        end
    end
    
    for k, v in pairs(KeyCache) do
        Data[k] = v
    end

	return Data, KeyCache]]
	)
	table.insert(snippet, "end)")

	local code = table.concat(snippet, "\n")
	print(code)
	self._Micro:Configure({ Code = code })
	
	-- Annoying issue where if a table is saved before the micro is turned on, a new table is created
	-- This manages to fix it by running the function again
	-- Idk how the function is being written fast enough... it just works. Do NOT add a wait here.
	if not GetMicroDataLoaded then
		RunMicrocontroller(self._Micro)
		GetMicroData = self._Disk:Read("_GetMicroData")

		if not GetMicroData then
			error("[MicroStorage.Write]: Data micro may have failed to turn on")
		end

		GetMicroData(self._AccessKey, { [key] = value })
	end
end

--- ### NOTE: Tables will automatically be JSON decoded if saved
function MicroStorage.Read(self: MicroStorage, key: string): any
	local MicroData, KeyCache
	local GetMicroData: GetMicroData = self._Disk:Read("_GetMicroData")

	if GetMicroData then
		MicroData, KeyCache = GetMicroData(self._AccessKey)
	else
		MicroData = {}
		KeyCache = {}
	end

	if typeof(MicroData) ~= "table" then
		error(`[MicroStorage.Read]: Data microcontroller failed to load keys`)
	end

	local data = MicroData[key]
	pcall(function()
		data = JSONDecode(data)
		KeyCache[key] = data
	end)

	return data
end

--- ### NOTE: Tables will automatically be JSON decoded if saved
function MicroStorage.ReadEntire(self: MicroStorage): { [string]: any }
	local MicroData, KeyCache
	local GetMicroData: GetMicroData = self._Disk:Read("_GetMicroData")

	if GetMicroData then
		MicroData, KeyCache = GetMicroData(self._AccessKey)
	else
		MicroData = {}
		KeyCache = {}
	end

	if typeof(MicroData) ~= "table" then
		error(`[MicroStorage.ReadEntire]: Data microcontroller failed to load keys '{tostring(MicroData)}'`)
	end

	local outputData = {}

	for k, v in pairs(MicroData) do
		pcall(function()
			v = JSONDecode(v)
			KeyCache[k] = v
		end)
		outputData[k] = v
	end

	return outputData
end

--- WARNING: This **WILL** erase all data kept in the data micro
--- Only use this if you want to 
-- function MicroStorage.ResetAccessKey(self: MicroStorage): ()
-- 	self._Micro:Configure({Code = ""})
-- end

-- Sync Table
function MicroStorage.MakeSyncTable<T>(self: MicroStorage, data: T)
	local syncTable = setmetatable({}, SyncTable) :: SyncTable<T>
	syncTable.Data = data
	syncTable._MicroStorage = self

	return syncTable
end

--- Automatically calls `SyncTable:Save()` when the value is set
function SyncTable.Set<T>(self: SyncTable<T>, keyPath: string | {string}, value: any): ()
	local pathArray: {string}

	if typeof(keyPath) == "string" then
		pathArray = keyPath:split(".")
	else
		pathArray = keyPath
	end

	local pointer: any = self.Data

	for i = 1, #pathArray - 1 do
		pointer = pointer[pathArray[i]]

		if not pointer then
			print(`SyncTable.Data.{table.concat(pathArray, ".")} is not a valid path`)
			error(`SyncTable.Data.{table.concat(pathArray, ".")} is not a valid path`)
		end
	end

	pointer[pathArray[#pathArray]] = value
	self:Save()
end

--- Writes `self.Data` to the data micro
--- @param key -- Will save `self.Data` to this key if provided
function SyncTable.Save<T>(self: SyncTable<T>, key: string?)
	local allData = self._MicroStorage:ReadEntire()

	if key then
		self._MicroStorage:Write(key, self.Data)
	end

	for k, v in pairs(allData) do
		if v == self.Data then
			self._MicroStorage:Write(k, self.Data)
		end
	end
end

return MicroStorage
