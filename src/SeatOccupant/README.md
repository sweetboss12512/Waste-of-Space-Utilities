# Seat Occupant
Some utility for dealing with seat occupants until theres a better way to do so (like `Seat:GetOccupant()`)

**NOTE: (Current stable only)** Something like [MultiConnection](https://github.com/sweetboss12512/Waste-of-Space-Libraries/tree/main/src/MultiConnection) should be used if you want to use `Keyboard.KeyPressed`
for other things. If it's not used, watching for a seat occupant or connecting to it after the watch is set will cause the seat occupant to no longer update.

**ANOTHER NOTE:** The seat occupant will only update when the occupant presses a key. The keyboard also has to be connected to the seat.

## Example code
```lua
local Seat = GetPartFromPort(1, "Seat")
local Keyboard = GetPartFromPort(1, "Keyboard")

Module.WatchForOccupant(Seat, Keyboard)

while true do
    task.wait(1)
    print(Module.GetSeatOccupant(Seat)) -- Username
end
```
