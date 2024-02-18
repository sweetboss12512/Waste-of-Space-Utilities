# Create Element
Some weird function i made to have [fusion-like](https://github.com/dphfox/Fusion) screen element creation

## Example Code
```lua
local Screen = GetPartFromPort(1, "Screen")
local CreateElement = require("@Modules/CreateElement")(Screen)

local Frame = CreateElement "TextLabel" {
    Size = UDim2.new(1, 0, 1, 0),
    Text = "Hello!"
}
```
