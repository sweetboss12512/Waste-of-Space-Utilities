# SearchPorts

A simple thing that searches port ids for the desired part. Nice for portability?

```lua
local Screen = SearchPorts("Screen", true) -- true to error if part isn't found
```

For type checking, you can add your own type to it.
```lua
local Screen: PilotLuaScreen = SearchPorts("Screen", true)
```

If you want to search ports for multiple of the same part, look at `SearchPortsMultiple`.
