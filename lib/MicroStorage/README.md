# Micro Storage
Library for using microcontrollers as data storage

## Example Code
```lua
local micro = GetPartFromPort(1, "Microcontroller")
local disk = GetPartFromPort(1, "Disk")

local accessKey = "Hello" -- Some string that gets written to the disk so data micro writes to the disk

local object = MicroStorage.new(disk, micro, accessKey)
object:Write("Hello", "World")
object:Write("json", {
    Health = 12,
    Value = 15
})

print(`json: {object:Read("json")}`)
print(`Hello: {object:Read("Hello")}`)
```

### Writing tables that update on changes
```lua
local object = MicroStorage.new(GetPartFromPort(1, "Disk"), GetPartFromPort(1, "Microcontroller"), "KEY")
local data = object:MakeSyncTable(object:Read("Test") or {
    Health = 15,
    Nested = {
        Value = 15
    }
})

data:Save("Test") -- Write data to key 'Test'

data:Set("Health", math.random(1, 300))
data:Set("Nested.Value", math.random(1, 300))
data:Set({"Nested", "Value"}, math.random(1, 300))

local someValue, ee = data.Data.Health, data.Data.Nested.Value
```
