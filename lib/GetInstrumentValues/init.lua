--!strict

type InstrumentValues = {
    Velocity: Vector3,
    RotationalVelocity: Vector3,
    TemperatureFahrenheit: number,
    TemperatureCelsius: number,
    --- Example: `12:30:12`
    RegionTime: string,
    --- This property CAN be incorrect if multiple wires are touching the same PowerCell
    AvailablePower: number,
    AttachedPartSize: Vector3,
    Position: Vector3,
    Orientation: Vector3,

    --- This is automatically calculated from `Position` and `Orientation` for convenience
    CFrame: CFrame,
}

local function GetInstrumentValues(instrument: PilotLuaInstrument): InstrumentValues
    local values = {} :: InstrumentValues

    values.Velocity = instrument:GetReading(0)
    values.RotationalVelocity = instrument:GetReading(1)
    values.TemperatureFahrenheit = instrument:GetReading(2)
    values.RegionTime = instrument:GetReading(3)
    values.AvailablePower = instrument:GetReading(4)
    values.AttachedPartSize = instrument:GetReading(5)
    values.Position = instrument:GetReading(6)
    values.TemperatureCelsius = instrument:GetReading(7)
    values.Orientation = instrument:GetReading(8)

    local rot = values.Orientation
    local pos = values.Position
    values.CFrame = CFrame.new(pos) * CFrame.fromEulerAnglesXYZ(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))

    return values
end

return GetInstrumentValues
