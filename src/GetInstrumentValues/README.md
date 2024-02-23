# Get Instrument Values
A quick thing to get all the readings of an instrument

## Example Code
```lua
local GetInstrumentValues = require("@Modules/GetInsturmentValues")

local Instrument = GetPartFromPort(1, "Instrument")
local Readings = GetInstrumentValues(Instrument)

for k, v in pairs(Readings) do
    -- Current WOS stable doesn't allow multiple values to print :/
    print(k)
    print(v)
end