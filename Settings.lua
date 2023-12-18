local function updateValueInTables(tables, key, value)
    for _, t in ipairs(tables) do
        if t[key] ~= nil then
            t[key] = value
        end
        for _, v in ipairs(t) do
            if type(v) == "table" then
                updateValueInTables({v}, key, value)
            end
        end
    end
end

local function checkIfColor(value)
    if value then
        local split = value:split(',')
        if #split == 3 then
            for i,v in split do
                if not tonumber(v) then
                    return
                end
            end
            return value
        end
    end
end

local function UpdateText(TextBox)
    local oldtext = TextBox.Text
    
    TextBox.Text = ''
    TextBox.Text = oldtext
end

return function(self)
    local settings = setmetatable({
        {'Editor',{
            {'Font', 'Text', 'RobotoMono', function(value)
                for i,v in Enum.Font:GetEnumItems() do
                    if v.Name == value then
                        return value
                    end
                end
            end},
            {'FontSize', 'Text', 15, function(value)
                if tonumber(value) then
                    self._TextBox.TextSize = value
                    self._TextBox.Parent.LineBar.TextButton.TextSize = value

                    for i,v in self._TextBox:GetChildren() do
                        if v:IsA('TextLabel') then
                            v.TextSize = value
                        end
                    end

                    return value
                end
            end},
            {'TextPadding', 'Text', '4', function(value)
                if tonumber(value) then
                    return value
                end
            end},
            {'Highlight Variables', 'Switch', false, function(value)
                return value
            end},
            {'Syntax Highlight', 'Switch', true, function(value)
                return value
            end}
        }},
        {'Color',{
            {'Editor', {
                {'Background', 'Text', '22, 25, 30', function(value)
                    return checkIfColor(value)
                end},
                {'Text Color', 'Text', '255, 255, 255', function(value)
                    return checkIfColor(value)
                end},
            }},
            {'Syntax Highlight', {
                {'Comments', 'Text', '103, 110, 149'},
                {'Globals', 'Text', '97, 175, 239'},
                {'Keywords', 'Text', '247, 164, 254'},
                {'Numbers', 'Text', '255, 109, 50'},
                {'Strings', 'Text', '142, 218, 141'},
                {'Tokens', 'Text', '86, 214, 214'},
                {'Variables', 'Text', '247, 164, 254'},
            }},
        }},
        {'Output',{
            {'Font', 'Text', 'RobotoMono', function(value)
                for i,v in Enum.Font:GetEnumItems() do
                    if v.Name == value then
                        return value
                    end
                end
            end},
            {'FontSize', 'Text', 15, function(value)
                if tonumber(value) then
                    return value
                end
            end},
            {'Log Delay', 'Text', 0.01, function(value)
                if tonumber(value) then
                    return value
                end
            end}
        }},
        {'Save',{
            {'Auto Save',{
                {'Auto Save', 'Switch', true, function(value)
                    return value
                end},
                {'Auto Save Delay', 'Text', 60, function(value)
                    if tonumber(value) then
                        return value
                    end
                end},
                {'Max Previous Saves', 'Text', 5, function(value)
                    if tonumber(value) then
                        return math.clamp(value, 1, 10)
                    end
                end},
                {'Save On Close', 'Switch', true, function(value)
                    return value
                end},
                {'Save On Edit', 'Switch', false, function(value)
                    return value
                end},
                {'Save On Exit', 'Switch', true, function(value)
                    return value
                end},
                {'Save On Focus Lost', 'Switch', false, function(value)
                    return value
                end},
                {'Save On Run', 'Switch', true, function(value)
                    return value
                end},
            }},
        }}
    },{
        __index = function(self, index)
            for _,v in self do
                if v[1] == index then
                    return v[2]
                end
            end
        end,
        __newindex = function(self, index, value)
            updateValueInTables(self, index, value)
        end
    })

    for i,v in settings do
        if type(v[2]) == 'table' then
            setmetatable(v[2],{
                __index = function(self, index)
                    for _,v in self do
                        if v[1] == index then
                            if type(v[2]) == 'table' then
                                return v[2]
                            else
                                return v[3]
                            end
                        end
                    end
                end
            })
        else
            setmetatable(v,{
                __index = function(self, index)
                    for _,v in self do
                        if v[1] == index then
                            return v[3]
                        end
                    end
                end
            })
        end
    end

    for i,v in settings.Color['Syntax Highlight'] do
        table.insert(v, function(value)
            if checkIfColor(value) then

                if v[1] == 'Variables' then
                    v[1] = 'Vars'
                end
                
                self._TextBox[v[1]..'_'].TextColor3 = Color3.fromRGB(unpack(value:split(',')))
                return value
            end
        end)
    end

    return settings
end