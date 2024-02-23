# Multi Event Handler
Simple class for allowing multiple connections to the same event

Currently in WOS stable, parts only allow a single event callback per event.
This solves that.

## Example code
```lua
local Keyboard = GetPartFromPort(1, "Keyboard")
local KeyboardEventHandler = MultiConnectionHandler(Keyboard)

for i = 1, 3 do
    local connection
    
    connection = KeyboardEventHandler:Connect("TextInputted", function(...)
        print(#{...})
        print(`Connection #{i} fired!`)
        print("All args: "..table.concat({...}, ", "))
        task.wait(2)
        connection:Unbind()
        print(`Unbinded connection #{i}`)
    end)
end
```
