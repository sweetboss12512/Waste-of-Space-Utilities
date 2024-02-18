-- thingy that adds a few methods to screens

-- Tables
local SpecialProperties = { -- properties that don't arent readable / don't work / don't really exist
	"Parent",
	"Visible"
}

local function WrapElement(element, screen: Screen): ScreenElement
	local wrap = {}
	local valueTable = {}
	local mt = {}

	wrap.ClassName = "ScreenElement" -- This may cause some issues
	wrap.ElementClass = element.ClassName :: string
	wrap._Element = element
	wrap._Screen = screen

	function wrap:AddChild(child: ScreenElement?)
		if child.ClassName ~= "ScreenElement" then -- Temporary fix for the radar code
			--error("[ScreenPlus.Element:AddChild]: Provided child is not a ScreenPlus element.")
			wrap._Element:AddChild(child)
			return
		end
		
		child.Parent = wrap
	end
	
	function wrap:Clone(): ScreenElement
		local properties = table.clone(valueTable)
		local clone = wrap._Screen:CreateElement(wrap._Element.ClassName, properties)
		
		for _, v in ipairs(wrap._Screen:GetElementMany({ Parent = wrap })) do -- Deep copy
			v:Clone().Parent = clone
		end
		
		if wrap.Parent then
			clone.Parent = wrap.Parent
		end
		
		return clone
	end
	
	function wrap:ClearAllChildren()
		for _, v in wrap._Screen:GetElementMany({Parent = wrap}) do
			v:Destroy()
		end
	end

	function wrap:Destroy()
		wrap:ClearAllChildren()
		element:Destroy()

		local index = table.find(wrap._Screen._Elements, wrap)
		table.remove(screen._Elements, index)
		
		setmetatable(wrap, nil)
		table.clear(wrap)
		table.clear(valueTable)
	end

	mt.__newindex = function(_, index, newValue) -- TODO find a way to clean this up a bit
		valueTable[index] = newValue
		
		if index == "Parent" and typeof(newValue) == "table" then
			newValue._Element:AddChild(element)
		end

		if index == "Size" and not valueTable.Visible then
			return
		end
		
		if index == "Visible" then
			if newValue then
				element.Size = valueTable.Size
			else
				element.Size = UDim2.fromScale(0, 0)
			end
		end
		
		assert(newValue ~= valueTable, "bro what???")

		if element[index] ~= nil and not table.find(SpecialProperties, index) then
			element[index] = newValue
		end
	end

	mt.__index = function(_, index)
		assert(index ~= valueTable, "what the heck??? __index")
		
		if valueTable[index] ~= nil then
			return valueTable[index]
		else
			return element[index]
		end
	end

	setmetatable(wrap, mt)
	return wrap
end

local function ScreenPlus(object): Screen
	if not object then
		error("[ScreenPlus]: Provided value is not a screen")
	end
	
	local screen = setmetatable({}, { __index = object })
	
	screen.ClassName = "ScreenPlus"
	screen._Object = object
	screen._Elements = {}
	
	function screen:CreateElement(className: string, properties: { Parent: ScreenElement, Visible: boolean, [string]: any }): ScreenElement
		local removedProperties = {
			Visible = true
		}
		
		for index, value in properties do -- Remove special properties so the actual element doesnt error since they are invalid
			if table.find(SpecialProperties, index) then
				removedProperties[index] = value
				properties[index] = nil -- So there aren't any errors
			end
		end
		
		local element = screen._Object:CreateElement(className, properties)
		local wrapped = WrapElement(element, screen)
		
		for index, value in properties do
			wrapped[index] = value
		end
		
		for index, value in removedProperties do
			wrapped[index] = value
		end

		table.insert(screen._Elements, wrapped)
		return wrapped
	end

	function screen:GetElement(filter: {}): ScreenElement?
		if typeof(filter) ~= "table" then
			error("[Screen:GetElement]: A filter dict as an argument is required")
		end

		for _, element in ipairs(screen._Elements) do
			local isMatch = true

			for k, v in filter do

				if element[k] ~= v then
					isMatch = false
				end
			end
			
			if isMatch then
				return element
			end
		end
	end

	function screen:GetElementMany(filter: {} | nil): { ScreenElement }
		local elements = {}

		for _, element in ipairs(screen._Elements) do
			local isMatch = true

			if filter then
				for k, v in filter do

					if element[k] ~= v then
						isMatch = false
						break
					end
				end
			end

			if not isMatch then
				continue
			end

			table.insert(elements, element)
		end

		return elements
	end

	function screen:ClearElements()

		for _, element in screen._Elements do -- So they can be removed from the elements table.
			element:Destroy()
		end

		screen._Object:ClearElements()
	end

	return screen
end

export type Screen = typeof(ScreenPlus())
export type ScreenElement =  {
	ClassName: "ScreenElement",
	Parent: ScreenElement,
	Visible: boolean

} & typeof(WrapElement())

return ScreenPlus
