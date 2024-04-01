--!strict

--[[
    # Seat Occupant
    Some library for dealing with seat occupants until theres a better way to do so (like `Seat:GetOccupant()`)
    
    ## Example code
    ```lua
    local Seat = GetPartFromPort(1, "Seat")
    local Keyboard = GetPartFromPort(1, "Keyboard")

    Module.WatchForOccupant(Seat, Keyboard)

    while true do
        task.wait(1)
        print(Module.GetSeatOccupant(Seat))
    end
    ```
]]
local Module = {}
local SeatOccupants: { [string]: string } = {}
type SeatLike = PilotLuaSeat | PilotLuaVehicleSeat

--[[
    Type so modules like [MultiConnection](https://github.com/sweetboss12512/Waste-of-Space-Libraries/tree/main/lib/MultiConnection)
    can work. Probably remove when unstable comes out (in 3 egg days)
]]
type KeyboardLike = {
	Connect: (self: KeyboardLike, eventName: string, callback: (...any) -> ...any) -> any,
}

function Module.WatchForOccupant(seat: SeatLike, keyboard: KeyboardLike)
	keyboard:Connect("KeyPressed", function(_, _, _, playerName: string)
		SeatOccupants[seat.GUID] = playerName
	end)
end

function Module.GetSeatOccupant(seat: SeatLike): string?
	return SeatOccupants[seat.GUID]
end

return Module
