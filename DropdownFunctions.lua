local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Dropdown = require(script.Parent.Dropdown)
local Functions = require(script.Parent.Functions)

local Connections = {}

return function(self)
    local MainGui = self._Gui
    local Explorer = MainGui.SidePane.Explorer

    local function view(Obj)
        local visible = self[`_{Obj}`] and true or false
        self[`_{Obj}`] = not self[`_{Obj}`]

        MainGui.SidePane.Visible = true

        for i,v in next, MainGui.SidePane:GetChildren() do
            if v:IsA('ScrollingFrame') or v:IsA('Frame') then
                v.Visible = self[`_{v.Name}`]
            end
        end

        return visible
    end

    local function EnsureVisuals()
        for i,v in self._Gui.EditorPane:GetChildren() do
            if v:IsA("ScrollingFrame") and v ~= self._Gui.EditorPane.ProjectBar then
                v.Visible = false
            end
        end

        for i,v in self._Gui.EditorPane.ProjectBar:GetChildren() do
            if v:IsA("Frame") then
                v.ProjectButton.BackgroundColor3 = Color3.fromRGB(36, 42, 50)
                v.ProjectButton.TextColor3 = self._Colors.BaseTextColor
                v.Highlight.Visible = false
            end
        end

        for i,v in self._Gui.SidePane.Explorer:GetChildren() do
            if v:IsA("TextButton") then
                v.BackgroundColor3 = Color3.fromRGB(36, 42, 50)
                v.TextColor3 = self._Colors.BaseTextColor
            end
        end

        if self._ProjectBar then
            self._Gui.EditorPane.ProjectBar.Visible = true
        end
    end

    local DropdownFunctions = {
        File = {
            {"New", function() end},
            {"Save", function() end},
            {"Preferences", function() end},
        },
        Edit = {
            {"Undo", function() end},
            {"Redo", function() end},
            {"Cut", function() end},
            {"Copy", function() end},
            {"Paste", function() end},
            {"Delete", function() end},
            {"Format", function() end},
            {"Select All", function() end},
        },
        View = {
            {"Explorer", function() end},
            {"Output", function() end},
            {"Project Bar", function() end}
        },
        Navigate = {
            {"Back", function() end},
            {"Forward", function() end},
            {"Go To", function() end},
            {"Find", function() end},
            {"Find Next", function() end},
            {"Find Previous", function() end},
        },
        Refactor = {
            {"Rename", function() end},
            {'Move', function() end},
            {'Copy', function() end},
            {'Paste', function() end},
            {'Delete', function() end},
        },
    }

    for i,v in next, DropdownFunctions do
        setmetatable(v, {
            __index = function(self, index)
                for i,v in next, self do
                    if v[1] == index then
                        return v
                    end
                end
            end
        })
    end
    
    DropdownFunctions.File.New[2] = function(name)
        if not name then
            if self._RenamingScript then return end
            self._delete = true
            self._RenamingScript = true
            self._Once = false
            
            local ScriptButtonTextBox = MainGui.SidePane.Explorer.ScriptButtonTextBox:Clone()
            ScriptButtonTextBox.Text = "ScriptButtonTextBoxCurrent"
            ScriptButtonTextBox.Visible = true
            ScriptButtonTextBox.LayoutOrder = 0
            ScriptButtonTextBox.Parent = MainGui.SidePane.Explorer
    
            ScriptButtonTextBox:CaptureFocus()
            ScriptButtonTextBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    if self._SavedScripts[ScriptButtonTextBox.Text] then
                        ScriptButtonTextBox:Destroy()
                        self._RenamingScript = false
                        self._delete = false
                        return true
                    end
    
                    if ScriptButtonTextBox.Text == "" or ScriptButtonTextBox.Text == 'ProjectButtonFrame' then
                        ScriptButtonTextBox:Destroy()
                        self._RenamingScript = false
                        self._delete = false
                        return true
                    end
    
                    assert(tostring(ScriptButtonTextBox.Text), function()
                        ScriptButtonTextBox:Destroy()
                        self._RenamingScript = false
                        self._delete = false
                        return true
                    end)
    
                    local ScriptButton = MainGui.SidePane.Explorer.ScriptButton:Clone()
                    ScriptButton.Visible = true
                    ScriptButton.Text = ScriptButtonTextBox.Text
                    ScriptButton.Name = ScriptButtonTextBox.Text
                    ScriptButton.LayoutOrder = #MainGui.SidePane.Explorer:GetChildren() + 1
                    ScriptButton.Parent = MainGui.SidePane.Explorer
                    ScriptButtonTextBox:Destroy()
    
                    ScriptButton.MouseButton1Click:Connect(function()
                        self:GetScript(ScriptButton.Text)
                    end)
    
                    ScriptButton.MouseButton2Click:Connect(function()
                        local old = self._CurrentScript
                        self._CurrentScript = ScriptButton.Text

                        if MainGui.Dropdown:FindFirstChild('Context '..ScriptButton.Text) then
                            MainGui.Dropdown:FindFirstChild('Context '..ScriptButton.Text):Destroy()
                        end

                        local Dropdown = Dropdown.new(self, MainGui.Dropdown, DropdownFunctions.Refactor)
                        Dropdown.Position = UDim2.new(0, ScriptButton.AbsolutePosition.X, 0, ScriptButton.AbsolutePosition.Y + ScriptButton.AbsoluteSize.Y)
                        Dropdown.Name = 'Context '..ScriptButton.Text
                        Dropdown.Parent = MainGui

                        Dropdown:GetPropertyChangedSignal('Visible'):Connect(function()
                            if Dropdown.Visible == false then
                                self._CurrentScript = old
                            end
                        end)
    
                        if self._SelectedDropdown then
                            self._SelectedDropdown.Visible = false
                            self._SelectedDropdown = Dropdown
                            self._SelectedDropdown.Visible = true
                            self._delete = false
                            return
                        end
                        
                        self._SelectedDropdown = Dropdown
                        self._SelectedDropdown.Visible = true
                        self._DropdownFocused = true
                        self._delete = false
                    end)
                    
                    self:NewScript(ScriptButtonTextBox.Text, '')
                    self:GetScript(ScriptButtonTextBox.Text)
                    self._RenamingScript = false
                    self._delete = false
    
                    game:GetService("RunService").RenderStepped:Wait()
                    self._TextBox:CaptureFocus()
                else
                    ScriptButtonTextBox:Destroy()
                    self._RenamingScript = false
                    self._delete = false
                end
            end)
        else
            local ScriptButton = MainGui.SidePane.Explorer.ScriptButton:Clone()
            ScriptButton.Visible = true
            ScriptButton.Text = name
            ScriptButton.Name = name
            ScriptButton.Parent = MainGui.SidePane.Explorer

            ScriptButton.MouseButton1Click:Connect(function()
                self._delete = true

                self:GetScript(ScriptButton.Text)

                self._delete = false
            end)

            ScriptButton.MouseButton2Click:Connect(function()     
                local old = self._CurrentScript
                self._CurrentScript = ScriptButton.Text

                if MainGui.Dropdown:FindFirstChild('Context '..ScriptButton.Text) then
                    MainGui.Dropdown:FindFirstChild('Context '..ScriptButton.Text):Destroy()
                end

                local Dropdown = Dropdown.new(self, MainGui.Dropdown, DropdownFunctions.Refactor)
                Dropdown.Position = UDim2.new(0, ScriptButton.AbsolutePosition.X, 0, ScriptButton.AbsolutePosition.Y + ScriptButton.AbsoluteSize.Y)
                Dropdown.Name = 'Context '..ScriptButton.Text
                Dropdown.Parent = MainGui

                Dropdown:GetPropertyChangedSignal('Visible'):Connect(function()
                    if Dropdown.Visible == false then
                        self._CurrentScript = old
                    end
                end)

                if self._SelectedDropdown then
                    self._SelectedDropdown.Visible = false
                    self._SelectedDropdown = Dropdown
                    self._SelectedDropdown.Visible = true
                    return
                end
                
                self._SelectedDropdown = Dropdown
                self._SelectedDropdown.Visible = true
                self._DropdownFocused = true
            end)
        end
    end

    DropdownFunctions.File.Save[2] = function()
        local Script = self._CurrentScript
        local Text = self._TextBox.Text
        local Icon = self._Gui.SidePane.Explorer[Script].Icon

        if not Script then return end

        self._SavedScripts[Script] = Text

        task.spawn(function()
            Icon.Image = Icon.Loading.Image
            Icon.ImageColor3 = Icon.Loading.ImageColor3

            Connections[Script] = RunService.RenderStepped:Connect(function()
                Icon.Rotation = Icon.Rotation + 5
            end)

            local succ = Functions.setData('RayCode Scripts', self._SavedScripts)

            if succ then
                if Connections[Script] then
                    Connections[Script]:Disconnect()
                    Connections[Script] = nil
                end

                Icon.Image = Icon.Tick.Image
                Icon.ImageColor3 = Icon.Tick.ImageColor3
                Icon.Rotation = 0
                task.wait(5)

                Icon.Image = '0'
            else
                if Connections[Script] then
                    Connections[Script]:Disconnect()
                    Connections[Script] = nil
                end

                Icon.Image = Icon.Fail.Image
                Icon.ImageColor3 = Icon.Fail.ImageColor3
                Icon.Rotation = 0
                task.wait(5)

                Icon.Image = '0'
            end
        end)
    end

    DropdownFunctions.File.Preferences[2] = function()
        local Settings = self._Gui.EditorPane.Settings
        local ProjectBar = self._Gui.EditorPane.ProjectBar
        local ProjectButtonFrame = self._Gui.EditorPane.ProjectBar.ProjectButtonFrame:Clone()
        local TopBar = self._Gui.TopBar

        EnsureVisuals()

        for i,v in ProjectBar:GetChildren() do
            if v.Name == 'Settings' and v:GetAttribute("Settings") then
                ProjectButtonFrame = v
                ProjectButtonFrame.ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
                ProjectButtonFrame.ProjectButton.TextColor3 = self._Colors.HighlightTextColor
                ProjectButtonFrame.Highlight.Visible = true

                Settings.Visible = true

                return
            end
        end

        Settings.Visible = true

        ProjectButtonFrame.Visible = true
        ProjectButtonFrame.ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
        ProjectButtonFrame.ProjectButton.TextColor3 = self._Colors.HighlightTextColor
        ProjectButtonFrame.ProjectButton.Text = "Settings"
        ProjectButtonFrame.Highlight.Visible = true
        ProjectButtonFrame.Name = "Settings"
        ProjectButtonFrame:SetAttribute("Window", true)
        ProjectButtonFrame.Parent = ProjectBar

        ProjectButtonFrame.ProjectButton.MouseButton1Click:Connect(function()
            EnsureVisuals()

            ProjectButtonFrame.ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
            ProjectButtonFrame.ProjectButton.TextColor3 = self._Colors.HighlightTextColor
            ProjectButtonFrame.Highlight.Visible = true

            Settings.Visible = true
        end)

        ProjectButtonFrame.CloseButton.MouseButton1Click:Connect(function()
            ProjectButtonFrame:Destroy()
            Settings.Visible = false

            ProjectButtonFrame:Destroy()
            self._CurrentScript = nil
            
            if #self._OpenedScripts > 0 then
                self._CurrentScript = self._OpenedScripts[#self._OpenedScripts]
                self._TextBox.Text = self._SavedScripts[self._CurrentScript]
                
                ProjectBar[self._CurrentScript].ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
                ProjectBar[self._CurrentScript].ProjectButton.TextColor3 = self._Colors.HighlightTextColor
                ProjectBar[self._CurrentScript].Highlight.Visible = true

                task.spawn(function()
                    TopBar.Left.ProjectTitle.Text = `{MarketplaceService:GetProductInfo(game.PlaceId).Name} - {self._CurrentScript}`
                end)

                self._Gui.EditorPane.ScrollingFrame.Visible = true

                for i,v in Explorer:GetChildren() do
                    if v:IsA("TextButton") then
                        v.BackgroundColor3 = Color3.fromRGB(36, 42, 50)
                        v.TextColor3 = self._Colors.BaseTextColor
                    end
                end

                Explorer[self._CurrentScript].BackgroundColor3 = Color3.fromRGB(51, 59, 70)
                Explorer[self._CurrentScript].TextColor3 = self._Colors.HighlightTextColor
            else
                self._Gui.EditorPane.ScrollingFrame.Visible = false

                for i,v in self._Gui.EditorPane.ProjectBar:GetChildren() do
                    if v:GetAttribute('Window') then
                        self._Gui.EditorPane[v.Name].Visible = true
                        v.ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
                        v.ProjectButton.TextColor3 = self._Colors.HighlightTextColor
                        v.Highlight.Visible = true
                        return
                    end
                end

                self._Gui.EditorPane.ProjectBar.Visible = false
                
                task.spawn(function()
                    TopBar.Left.ProjectTitle.Text = MarketplaceService:GetProductInfo(game.PlaceId).Name
                end)
            end
        end)
    end

    DropdownFunctions.Refactor.Delete[2] = function()
        local Explorer = self._Gui.SidePane.Explorer
        local Script = self._CurrentScript

        if Script then
            self._SavedScripts[Script] = nil
            self._CurrentScript = nil
            self._delete = true

            pcall(function()
                self._Gui.SidePane.Explorer[Script]:Destroy()
                self._Gui.EditorPane.ProjectBar[Script]:Destroy()
            end)

            table.remove(self._OpenedScripts, table.find(self._OpenedScripts, Script))

            task.spawn(function()
                self._Gui.TopBar.Left.ProjectTitle.Text = MarketplaceService:GetProductInfo(game.PlaceId).Name
                Functions.setData('RayCode Scripts', self._SavedScripts)
            end)

            if #self._OpenedScripts > 0 then
                self._CurrentScript = self._OpenedScripts[#self._OpenedScripts]

                if self._SavedScripts[self._CurrentScript] then
                    self._TextBox.Text = self._SavedScripts[self._CurrentScript]
                end

                self._Gui.EditorPane.ScrollingFrame.Visible = true
            else
                self._Gui.EditorPane.ScrollingFrame.Visible = false

                for i,v in self._Gui.EditorPane.ProjectBar:GetChildren() do
                    if v:GetAttribute('Window') then
                        self._Gui.EditorPane[v.Name].Visible = true
                        v.ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
                        v.ProjectButton.TextColor3 = self._Colors.HighlightTextColor
                        v.Highlight.Visible = true
                        return
                    end
                end

                self._Gui.EditorPane.ProjectBar.Visible = false
            end

            for i,v in Explorer:GetChildren() do
                if v:IsA("TextButton") then
                    v.BackgroundColor3 = Color3.fromRGB(36, 42, 50)
                    v.TextColor3 = self._Colors.BaseTextColor
                end
            end

            if self._CurrentScript then
                Explorer[self._CurrentScript].BackgroundColor3 = Color3.fromRGB(51, 59, 70)
                Explorer[self._CurrentScript].TextColor3 = self._Colors.HighlightTextColor

                task.spawn(function()
                    self._Gui.TopBar.Left.ProjectTitle.Text = MarketplaceService:GetProductInfo(game.PlaceId).Name .. ' - ' .. self._CurrentScript
                end)
            end

            self._delete = false
        end
    end

    DropdownFunctions.Edit.Format[2] = function()
        self._TextBox.Text = self._TextBox.Text:gsub('\t', '    ')
    end

    DropdownFunctions.View.Explorer[2] = function()
        local visible = view('Explorer')
        
        if self._Explorer == false and self._Output == false then
            MainGui.SidePane:TweenSize(UDim2.new(0, 0, 1, -self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane:TweenSize(UDim2.new(1, 0, 1,-self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.SidePane.Visible = false
        else
            MainGui.SidePane.Visible = true
            if self._Widget.AbsoluteSize.X > self._AbsoluteSizes.HideOffset then
                MainGui.EditorPane:TweenSize(UDim2.new(1, -self._AbsoluteSizes.SidePaneAbsoluteSizeX, 1,-self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            end

            MainGui.SidePane:TweenSize(UDim2.new(0, self._AbsoluteSizes.SidePaneAbsoluteSizeX, 1, -self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
        end

        if visible then
            MainGui.SidePane.Output.Size = UDim2.new(1, 0, 1, 0)
            MainGui.View.Explorer.Text = "Explorer"
        else
            if self._Output == false then
                MainGui.SidePane.Output.Visible = false
                MainGui.SidePane.Explorer.Size = UDim2.new(1, 0, 1, 0)
            else
                MainGui.SidePane.Output.Size = UDim2.new(1, 0, 0.5, 0)
                MainGui.SidePane.Explorer.Size = UDim2.new(1, 0, 0.5, 0)
            end
            MainGui.View.Explorer.Text = "Explorer ✓"
        end

        MainGui.SidePane.Explorer:GetPropertyChangedSignal('Visible'):Connect(function()
            if MainGui.SidePane.Explorer.Visible == false then
                MainGui.View.Explorer.Text = "Explorer"
            else
                MainGui.View.Explorer.Text = "Explorer ✓"
            end
        end)
    end

    DropdownFunctions.View.Output[2] = function()
        local visible = view('Output')

        if self._Explorer == false and self._Output == false then
            MainGui.SidePane:TweenSize(UDim2.new(0, 0, 1, -self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane:TweenSize(UDim2.new(1, 0, 1,-self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.SidePane.Visible = false
        else
            MainGui.SidePane.Visible = true
            if self._Widget.AbsoluteSize.X > self._AbsoluteSizes.HideOffset then
                MainGui.EditorPane:TweenSize(UDim2.new(1, -self._AbsoluteSizes.SidePaneAbsoluteSizeX, 1,-self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            end
            MainGui.SidePane:TweenSize(UDim2.new(0, self._AbsoluteSizes.SidePaneAbsoluteSizeX, 1, -self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
        end

        if visible then
            MainGui.SidePane.Explorer.Size = UDim2.new(1, 0, 1, 0)
            MainGui.View.Output.Text = "Output"
        else
            if self._Explorer == false then
                MainGui.SidePane.Explorer.Visible = false
                MainGui.SidePane.Output.Size = UDim2.new(1, 0, 1, 0)
            else
                MainGui.SidePane.Explorer.Size = UDim2.new(1, 0, 0.5, 0)
                MainGui.SidePane.Output.Size = UDim2.new(1, 0, 0.5, 0)
            end
            MainGui.View.Output.Text = "Output ✓"
        end

        MainGui.SidePane.Output:GetPropertyChangedSignal('Visible'):Connect(function()
            if MainGui.SidePane.Output.Visible == false then
                MainGui.View.Output.Text = "Output"
            else
                MainGui.View.Output.Text = "Output ✓"
            end
        end)
    end

    DropdownFunctions.View['Project Bar'][2] = function()
        local visible = self._ProjectBar and true or false
        self._ProjectBar = not self._ProjectBar

        if visible then
            for i,v in next, MainGui.EditorPane.ProjectBar:GetChildren() do
                if v:IsA('Frame') then
                    v.Visible = false
                end
            end
            MainGui.EditorPane.ScrollingFrame:TweenSize(UDim2.new(1, 0, 1, 0), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane.Settings:TweenSize(UDim2.new(1, 0, 1, 0), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane.ProjectBar:TweenSize(UDim2.new(1, 0, 0, 0), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane.ProjectBar.Visible = false
            MainGui.View['Project Bar'].Text = "Project Bar"
        else
            for i,v in next, MainGui.EditorPane.ProjectBar:GetChildren() do
                if v:IsA('Frame') and v.Name ~= 'ProjectButtonFrame' then
                    v.Visible = true
                end
            end
            MainGui.EditorPane.ScrollingFrame:TweenSize(UDim2.new(1, 0, 1, -self._AbsoluteSizes.ProjectBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane.Settings:TweenSize(UDim2.new(1, 0, 1, -self._AbsoluteSizes.ProjectBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane.ProjectBar:TweenSize(UDim2.new(1, 0, 0, self._AbsoluteSizes.ProjectBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
            MainGui.EditorPane.ProjectBar.Visible = true
            MainGui.View['Project Bar'].Text = "Project Bar ✓"
        end
    end

    return DropdownFunctions
end