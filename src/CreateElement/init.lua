type New<T, V> = (className: T) -> (properties: {[string]: any}) -> PilotLuaScreenObject & V
type CreateElement<ClassName, Class> = (className: ClassName, properties: {[string]: any}) -> PilotLuaScreenObject & Class

type NewOverload = New<"Frame", Frame>
& New<"TextLabel", TextLabel>
& New<"ScrollingFrame", ScrollingFrame>
& New<"ImageLabel", ImageLabel>
& New<"TextButton", TextButton>
& New<"TextLabel", TextLabel>
& New<ScreenObjectList | string, GuiObject>

return function (screen: PilotLuaScreen): NewOverload
    local New = function(className)
        return function(props)
            return screen:CreateElement(className, props)
        end
    end

    return New :: any
end
