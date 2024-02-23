## Screen+

This just adds some methods to screens

```lua
local ScreenPlus = require(script.Parent)
local Screen = ScreenPlus(GetPartFromPort(1, "Screen"))

Screen:ClearElements()

local frame = Screen:CreateElement("Frame", {
    Size = UDim2.fromScale(1, 1)
})

Screen:CreateElement("TextLabel", {
    Name = "thingy",
    Size = UDim2.fromScale(1, 1),
    Text = "thingy",
    TextScaled = true
})

local someLabel = Screen:GetElement({ Name = "thingy" }) -- Get the text label thats named 'thingy'
local clone = someLabel:Clone() -- Clones the screen element with it's properties (current stable doesn't have this I think?)

clone.Parent = frame -- .Parent works

for i = 1, 10 do
    local label = Screen:CreateElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        Text = math.random(1, 100000),
        TextScaled = true
    })
    
    frame:AddChild(label)
end

local frameChildren = Screen:GetElementMany({ Parent = frame })
local allElements = Screen:GetElementMany() -- get every element on the screen
```
