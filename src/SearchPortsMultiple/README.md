Searches port ids from `1` to `maxPortNumber` for provided `partName`

- Automatically filters repeat parts

## Example Code

```lua
-- By default, searches ports from 1 to 10 for bins
local Bins = SearchPortsMultiple("Bin", true) -- true to error if no parts are found
```
