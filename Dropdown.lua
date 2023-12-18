local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(Console, DropdownGui, Elements)
    local self = setmetatable({
        _DropdownGui = nil,
        _Elements = Elements,
    }, Dropdown)

    local DropdownGui : Instance = DropdownGui:Clone()
    local Element = DropdownGui.DropdownButton or DropdownGui:FindFirstChildOfClass("TextButton")

    for i,v in ipairs(self._Elements) do
        local Element = Element:Clone()
        Element.Visible = true
        Element.Name = v[1]
        Element.Text = v[1]
        Element.Parent = DropdownGui

        Element.MouseButton1Click:Connect(function()
            v[2]()
            
            if Console._SelectedDropdown then
                Console._DropdownFocused = false
                Console._SelectedDropdown.Visible = false
                Console._SelectedDropdown = nil
            end
        end)
    end

    self._DropdownGui = DropdownGui

    return self._DropdownGui
end

return Dropdown