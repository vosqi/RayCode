local Console = {}
Console.__index = Console

local plugin = script:FindFirstAncestorWhichIsA("Plugin")

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Functions = require(script.Parent.Functions)
local DropdownModule = require(script.Parent.Dropdown)
local GuiCollisionService = require(script.Parent.GuiCollisionService)
local Highlighter = require(script.Parent.SyntaxHighlighter)
local Language = require(script.Parent.Language)
local Autocomplete = require(script.Parent.Autocomplete)
local Runner = require(script.Parent.Runner)
local Sandbox = require(script.Parent.Sandbox)

local Gui = script.Parent.MainGui
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local UPDATETHRESHOLD = 30  

task.spawn(function()
	while task.wait(UPDATETHRESHOLD) do
		pcall(function()
			GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
		end)
	end
end)

function Console.new(Widget)
	local self = setmetatable({
		_Int = 1,
		_DInt = 2,
		_UserId = StudioService:GetUserId(),
		_Logs = {},
		_Gui = Gui:Clone(),
		_AbsoluteSizes = {
			HideOffset = 500,
			MainGuiAbsoluteSizeX = 0,
			DropdownAbsoluteSizeX = 198,
			DropdownAbsoluteSizeY = 0,
			DropdownButtonAbsoluteSizeY = 20,
			RightAbsoluteSizeX = 60,
			TopBarAbsoluteSizeY = 20,
			SidePaneAbsoluteSizeX = 198,
			LineBarAbsoluteSizeX = 30,
			ProjectBarAbsoluteSizeY = 20,
			ProjectButtonFrameAbsoluteSizeX = 100,
			ProjectButtonAbsoluteSizeX = 82,
			ProjectCloseButtonAbsoluteSizeX = 18,
			TopBarButtonAbsoluteSizeX = 66,
			TopBarButtonAbsoluteSizeY = 20,
			TopBarRightButtonAbsoluteSizeX = 19,
			TopBarRightButtonAbsoluteSizeY = 20,
		},
		_TextHistory = {},
		_Once = false,
		_Explorer = true,
		_Output = true,
		_ProjectBar = true,
		_SidePane = true,
		_TextBox = nil,
		_Widget = Widget,
		_GuiTime = 0.5,
		_GuiEasingStyle = Enum.EasingStyle.Quint,
		_GuiEasingDirection = Enum.EasingDirection.Out,
		_GuiTweenInfo = nil,
		_ScrollIndex = 1,
		_Dropdown = nil,
		_DropdownFunctions = nil,
		_SelectedDropdown = nil,
		_DropdownFocused = false,
		_TextBoxFocused = false,
		_Settings = nil,
		_CurrentSide = 'Server',
		_SavedScripts = setmetatable({},{
			__index = function(self, index)
				for i,v in next, self do
					if v.Name == index then
						return v.Value
					end
				end
			end,
			__newindex = function(self, index, value)
				for i,v in self do
					if v.Name == index then
						v.Value = value
						return
					end
				end

				local t = {Name = index, Value = value}
				table.insert(self, t)
			end
		}),
		_OpenedScripts = {},
		_CurrentScript = nil,
		_RenamingScript = false,
		_MouseX = 0,
		_MouseY = 0,
		_Colors = require(script.Parent.Colors),
		_delete = false,
		_message = false,
		_dataLoaded = false,
		_Language = Language,
		_Autocomplete = Autocomplete,
		_AutocompleteFrame = nil,
		_AutocompleteButton = nil,
		_Connections = {},
	}, Console)

	self._GuiTweenInfo = TweenInfo.new(self._GuiTime,self._GuiEasingStyle,self._GuiEasingDirection)
	self._DropdownFunctions = require(script.Parent.DropdownFunctions)(self)
	self._Settings = require(script.Parent.Settings)(self)
	require(script.Parent.Save)(self)

	----------------------------------------------

	local Widget = self._Widget
	local MainGui = self._Gui
	local Dropdown = MainGui.Dropdown
	local DropdownButton = Dropdown.DropdownButton

	local EditorPane = MainGui.EditorPane
	local ProjectBar = EditorPane.ProjectBar
	local ProjectButtonFrame = ProjectBar.ProjectButtonFrame
	local ProjectButton = ProjectButtonFrame.ProjectButton
	local ProjectCloseButton = ProjectButtonFrame.CloseButton
	local ScrollingFrame = EditorPane.ScrollingFrame
	local Settings = EditorPane.Settings
	local LineBar = ScrollingFrame.LineBar
	local TextBox = ScrollingFrame.TextBox
	local AutocompleteFrame = MainGui.AutocompleteFrame

	local SidePane = MainGui.SidePane
	local Explorer = SidePane.Explorer
	local ExplorerMessageTemplate = Explorer.TemplateMessage
	local ScriptButton = Explorer.ScriptButton
	local Output = SidePane.Output
	local LogTemplate = Output.LogTemplate
	local OutputMessageTemplate = Output.TemplateMessage

	local TopBar = MainGui.TopBar
	local TopBarLeft = TopBar.Left
	local TopBarRight = TopBar.Right
	local ProjectTitle = TopBarLeft.ProjectTitle

	local WidgetAbsoluteSizeX = 501
	local HideOffset = self._AbsoluteSizes.HideOffset
	local MainGuiAbsoluteSizeX = self._AbsoluteSizes.MainGuiAbsoluteSizeX
	local DropdownAbsoluteSizeX = self._AbsoluteSizes.DropdownAbsoluteSizeX
	local DropdownAbsoluteSizeY = self._AbsoluteSizes.DropdownAbsoluteSizeY
	local DropdownButtonAbsoluteSizeY = self._AbsoluteSizes.DropdownButtonAbsoluteSizeY
	local RightAbsoluteSizeX = self._AbsoluteSizes.RightAbsoluteSizeX
	local TopBarAbsoluteSizeY = self._AbsoluteSizes.TopBarAbsoluteSizeY
	local SidePaneAbsoluteSizeX = self._AbsoluteSizes.SidePaneAbsoluteSizeX
	local LineBarAbsoluteSizeX = self._AbsoluteSizes.LineBarAbsoluteSizeX
	local ProjectBarAbsoluteSizeY = self._AbsoluteSizes.ProjectBarAbsoluteSizeY
	local ProjectButtonFrameAbsoluteSizeX = self._AbsoluteSizes.ProjectButtonFrameAbsoluteSizeX
	local ProjectButtonAbsoluteSizeX = self._AbsoluteSizes.ProjectButtonAbsoluteSizeX
	local ProjectCloseButtonAbsoluteSizeX = self._AbsoluteSizes.ProjectCloseButtonAbsoluteSizeX
	local TopBarButtonAbsoluteSizeX = self._AbsoluteSizes.TopBarButtonAbsoluteSizeX
	local TopBarButtonAbsoluteSizeY = self._AbsoluteSizes.TopBarButtonAbsoluteSizeY
	local TopBarRightButtonAbsoluteSizeX = self._AbsoluteSizes.TopBarRightButtonAbsoluteSizeX
	local TopBarRightButtonAbsoluteSizeY = self._AbsoluteSizes.TopBarButtonAbsoluteSizeY

	local TextSize = self._Settings.Editor.FontSize
	local Font = self._Settings.Editor.Font
	local ScrollDistance = TextSize*5
	local TextPadding = self._Settings.Editor.TextPadding
	local OutputDefaultChildrenSize = #Output:GetChildren()
	local ExplorerDefaultChildrenSize = #Explorer:GetChildren()

	----------------------------------------------

	local function SetSetting(idx,val,SubTitle,layoutOrder,hsvDisp)
		val[3] = typeof(val[3]) == 'Instance' and val[3].Name or val[3]

		local Setting = Settings[val[2]..'Template']:Clone()
		Setting.Name = val[1]
		Setting.Visible = true
		Setting.LayoutOrder = layoutOrder
		Setting.TextLabel.UIPadding.PaddingLeft = UDim.new(0,SubTitle.UIPadding.PaddingLeft.Offset + 10)

		local h,s,v = SubTitle.BackgroundColor3:ToHSV()

		Setting.BackgroundColor3 = Color3.fromHSV(h,s,(v*255-hsvDisp)/255)

		Setting.Parent = Settings

		Setting.TextLabel.Text = val[1]

		if val[2]..'Template' == 'TextTemplate' then
			Setting.TextBox.PlaceholderText = plugin:GetSetting(val[1]) or val[3]
			Setting.TextBox.FocusLost:Connect(function(EnterPressed)
				if EnterPressed then
					local succ = val[4](Setting.TextBox.Text)

					succ = typeof(succ) == 'Instance' and succ.Name or succ

					if succ then
						plugin:SetSetting(val[1], succ)
						Setting.TextBox.PlaceholderText = succ
					end
				end
				Setting.TextBox.Text = ''
			end)
		else
			for i,v in Setting.Toggle:GetChildren() do
				if v:IsA('TextButton') then
					v.BackgroundColor3 = Color3.fromRGB(22, 25, 30)
					v.TextColor3 = Color3.fromRGB(73, 84, 100)
					v.MouseButton1Click:Connect(function()
						for i,v in Setting.Toggle:GetChildren() do
							if v:IsA('TextButton') then
								v.BackgroundColor3 = Color3.fromRGB(22, 25, 30)
								v.TextColor3 = Color3.fromRGB(73, 84, 100)
							end
						end

						v.BackgroundColor3 = Color3.fromRGB(30, 34, 40)
						v.TextColor3 = Color3.fromRGB(255, 255, 255)

						plugin:SetSetting(val[1], val[4](v.Text == 'On' and true or false))
					end)
				end
			end

			local Selected = plugin:GetSetting(val[1]) ~= nil and (plugin:GetSetting(val[1]) == true and 'On' or plugin:GetSetting(val[1]) == false and 'Off') or val[3] == true and 'On' or val[3] == false and 'Off'

			Setting.Toggle[Selected].TextColor3 = Color3.fromRGB(255, 255, 255)
			Setting.Toggle[Selected].BackgroundColor3 = Color3.fromRGB(30, 34, 40)
		end
	end

	----------------------------------------------

	for i,v in next, TopBarLeft:GetChildren() do
		if v:IsA("TextButton") then
			v.Size = UDim2.new(0,TopBarButtonAbsoluteSizeX,0,TopBarButtonAbsoluteSizeY)
		end
	end

	for i,v in next, TopBarRight:GetChildren() do
		if v:IsA("GuiObject") then
			v.Size = UDim2.new(0,TopBarRightButtonAbsoluteSizeX,0,TopBarRightButtonAbsoluteSizeY)
		end
	end

	for i,v in ipairs(self._Settings) do
		v[3] = typeof(v[3]) == 'Instance' and v[3].Name or v[3]

		local SubTitle = Settings.SubTitle:Clone()
		SubTitle.Text = v[1]
		SubTitle.Visible = true
		SubTitle.LayoutOrder = i
		SubTitle.Name = v[1]
		SubTitle.Parent = Settings

		local function YesDefault(v)
			local Setting = nil

			for i,k in Settings:GetChildren() do
				if k.Name == v[1] and k.ClassName == 'Frame' then
					Setting = k
					break
				end
			end 

			if Setting:FindFirstChild('Toggle') then
				for i,v in Setting.Toggle:GetChildren() do
					if v:IsA('TextButton') then
						v.BackgroundColor3 = Color3.fromRGB(22, 25, 30)
						v.TextColor3 = Color3.fromRGB(73, 84, 100)
					end
				end

				Setting.Toggle[v[3] == true and 'On' or v[3] == false and 'Off'].TextColor3 = Color3.fromRGB(255, 255, 255)
				Setting.Toggle[v[3] == true and 'On' or v[3] == false and 'Off'].BackgroundColor3 = Color3.fromRGB(30, 34, 40)
			elseif Settings[v[1]]:FindFirstChild('TextBox') then
				Settings[v[1]].TextBox.PlaceholderText = v[3]
				Settings[v[1]].TextBox.Text = ''
			end
		end

		for i,v in v[2] do
			if type(v[2]) ~= 'table' then
				SubTitle.ResetDefault.Visible = true
				break
			end
		end

		SubTitle.ResetDefault.MouseButton1Click:Connect(function()
			SubTitle.ResetDefault.Yes.Visible = true
			SubTitle.ResetDefault.No.Visible = true

			SubTitle.ResetDefault.Yes.MouseButton1Click:Connect(function()
				for i3,v3 in ipairs(v[2]) do
					plugin:SetSetting(v3[1],v3[3])
					v3[4](v3[3])
				end
				for i,v in v[2] do
					YesDefault(v)
				end

				SubTitle.ResetDefault.Yes.Visible = false
				SubTitle.ResetDefault.No.Visible = false
			end)

			SubTitle.ResetDefault.No.MouseButton1Click:Connect(function()
				SubTitle.ResetDefault.Yes.Visible = false
				SubTitle.ResetDefault.No.Visible = false
			end)
		end)

		for i2,v2 in ipairs(v[2]) do
			if type(v2[2]) == 'table' then
				local SubTitle = Settings.SubTitle:Clone()
				SubTitle.Text = v2[1]
				SubTitle.Visible = true
				SubTitle.LayoutOrder = i
				SubTitle.Name = v2[1]
				SubTitle.UIPadding.PaddingLeft = UDim.new(0,20)

				for i,v in v2[2] do
					if type(v[2]) ~= 'table' then
						SubTitle.ResetDefault.Visible = true
						break
					end
				end

				local h,s,v = SubTitle.BackgroundColor3:ToHSV()

				SubTitle.BackgroundColor3 = Color3.fromHSV(h,s,(v*255-12.5)/255)
				SubTitle.Parent = Settings

				SubTitle.ResetDefault.MouseButton1Click:Connect(function()
					SubTitle.ResetDefault.Yes.Visible = true
					SubTitle.ResetDefault.No.Visible = true

					SubTitle.ResetDefault.Yes.MouseButton1Click:Connect(function()
						for i3,v3 in ipairs(v2[2]) do
							plugin:SetSetting(v3[1],v3[3])
							v3[4](v3[3])
						end
						for i,v in v2[2] do
							YesDefault(v)
						end

						SubTitle.ResetDefault.Yes.Visible = false
						SubTitle.ResetDefault.No.Visible = false
					end)

					SubTitle.ResetDefault.No.MouseButton1Click:Connect(function()
						SubTitle.ResetDefault.Yes.Visible = false
						SubTitle.ResetDefault.No.Visible = false
					end)
				end)

				for i3,v3 in ipairs(v2[2]) do
					SetSetting(i3,v3,SubTitle,i,6)
				end
			else
				SetSetting(i2,v2,SubTitle,i,15)
			end
		end
	end

	TopBar.Size = UDim2.new(1,0,0,TopBarAbsoluteSizeY)
	LineBar.Size = UDim2.new(0, LineBarAbsoluteSizeX, 1, 0)
	ProjectTitle.Text = GameName
	ProjectTitle.LayoutOrder = #TopBarLeft:GetChildren()-1

	Dropdown.Size = UDim2.new(0,DropdownAbsoluteSizeX,0,DropdownAbsoluteSizeY)
	DropdownButton.Size = UDim2.new(1,0,0,DropdownButtonAbsoluteSizeY)
	EditorPane.Size = UDim2.new(1, -SidePaneAbsoluteSizeX, 1, -TopBarAbsoluteSizeY)
	TextBox.Size = UDim2.new(1,-LineBar.AbsoluteSize.X,1,0)
	TextBox.UIPadding.PaddingLeft = UDim.new(0, TextPadding)
	ProjectBar.Size = UDim2.new(1,0,0,ProjectBarAbsoluteSizeY)
	ProjectButtonFrame.Size = UDim2.new(0,ProjectButtonFrameAbsoluteSizeX,1,0)
	ProjectButton.Size = UDim2.new(0,ProjectButtonAbsoluteSizeX,1,0)
	ProjectCloseButton.Size = UDim2.new(0,ProjectCloseButtonAbsoluteSizeX,1,0)
	ScrollingFrame.Size = UDim2.new(1,0,1,-ProjectBarAbsoluteSizeY)

	SidePane.Size = UDim2.new(0,SidePaneAbsoluteSizeX,1,-TopBarAbsoluteSizeY)
	LogTemplate.Size = UDim2.new(1,0,0,0)

	MainGui.Visible = true
	MainGui.Parent = Widget

	TextBox.Text = ''
	TextBox.TextSize = plugin:GetSetting('FontSize') or TextSize
	TextBox.Font = plugin:GetSetting('Font') ~= nil and Enum.Font[plugin:GetSetting('Font')] or Font

	ScriptButton.Visible = false
	LogTemplate.Visible = false

	self._AutocompleteFrame = AutocompleteFrame
	self._AutocompleteButton = AutocompleteFrame.AutocompleteButton
	self._TextBox = TextBox
	self._Autocomplete = Autocomplete.new(self)

	if RunService:IsEdit() then
		TopBarRight.Side.ImageColor3 = Color3.fromRGB(72, 83, 99)
		TopBarRight.Stop.TextColor3 = Color3.fromRGB(72, 83, 99)
		TopBarRight.Side.AutoButtonColor = false
		TopBarRight.Side.AutoButtonColor = false
	else
		TopBarRight.Side.ImageColor3 = Color3.fromRGB(177, 216, 255)
		TopBarRight.Stop.TextColor3 = Color3.fromRGB(188, 79, 81)
		TopBarRight.Side.AutoButtonColor = true
		TopBarRight.Side.AutoButtonColor = true
	end

	for i,v in self._TextBox:GetChildren() do
		if v.Name:sub(-1,-1) == '_' then
			v.TextColor3 = plugin:GetSetting(v.Name:sub(-1,-2)) and Color3.fromRGB(unpack(plugin:GetSetting(v.Name:sub(-1,-2)):split(','))) or v.TextColor3
		end
	end

	------------------ Run --------------------------

	TopBarRight.Run.MouseButton1Click:Connect(function()
		self:Run()
	end)

	------------------ Init -------------------------

	Highlighter(TextBox)

	----------------- Data ---------------------------

	if not Functions.getData(self._UserId..'RayCode Scripts') then
		Functions.setData(self._UserId..'RayCode Scripts', {})
	else
		for i,v in Functions.getData(self._UserId..'RayCode Scripts') do
			if v.Value == nil then continue end

			self._DropdownFunctions.File.New[2](v.Name)

			self:NewScript(v.Name, v.Value)
			self:GetScript(v.Name)
			task.wait()
		end

		self._dataLoaded = true
	end

	------------------ RunService -------------------

	local IsUnderSize = false
	local IsUnderSize2 = false

	task.spawn(function()
		while RunService.RenderStepped:Wait() do
			WidgetAbsoluteSizeX = Widget.AbsoluteSize.X
		end
	end)

	RunService.RenderStepped:Connect(function()
		if self._RenamingScript and self._Once == false then 
			self._Once = true

			SidePane.Visible = true
			EditorPane:TweenSize(UDim2.new(1, -SidePaneAbsoluteSizeX, 1, -TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
			SidePane:TweenSize(UDim2.new(0, SidePaneAbsoluteSizeX, 1, -TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)

			if self._Explorer == false and self._Output == false then
				self._Explorer = true
				Explorer.Size = UDim2.new(1, 0, 1, 0)
				MainGui.SidePane.Explorer.Visible = true
				MainGui.SidePane.Output.Visible = false
			elseif self._Output and self._Explorer == false then
				self._Explorer = true
				Explorer.Size = UDim2.new(1, 0, 0.5, 0)
				MainGui.SidePane.Explorer.Visible = true
			end
		end

		if WidgetAbsoluteSizeX < HideOffset then
			MainGui.SideBar.Visible = true

			if self._RenamingScript == false and self._Once then
				self._Once = false
				if WidgetAbsoluteSizeX < HideOffset then
					IsUnderSize = true
					EditorPane:TweenSize(UDim2.new(1, 0, 1,-TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
					SidePane:TweenSize(UDim2.new(0, 0, 1, -TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
					SidePane.Visible = false
				end 
			end

			if self._Explorer or self._Output then
				task.spawn(function()
					if self._MouseX <= MainGui.SideBar.Size.X.Offset then
						if IsUnderSize2 then return end
						IsUnderSize2 = true
						MainGui.SidePane.Visible = true
						MainGui.SidePane:TweenSize(UDim2.new(0, self._AbsoluteSizes.SidePaneAbsoluteSizeX, 1, -self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
						MainGui.EditorPane:TweenSize(UDim2.new(1, -self._AbsoluteSizes.SidePaneAbsoluteSizeX, 1,-self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
					else
						IsUnderSize2 = false
					end
				end)

				if self._RenamingScript then return end
				if IsUnderSize then return end
				IsUnderSize = true
				EditorPane:TweenSize(UDim2.new(1, 0, 1,-TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
				SidePane:TweenSize(UDim2.new(0, 0, 1, -TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
				SidePane.Visible = false
			end
		else
			MainGui.SideBar.Visible = false

			if IsUnderSize == false then return end
			IsUnderSize = false
			SidePane.Visible = true
			EditorPane:TweenSize(UDim2.new(1, -SidePaneAbsoluteSizeX, 1, -TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
			SidePane:TweenSize(UDim2.new(0, SidePaneAbsoluteSizeX, 1, -TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
		end
	end)

	------------------ Mouse ----------------------

	MainGui.MouseMoved:Connect(function(x,y)
		self._MouseX = x
		self._MouseY = y
	end)

	MainGui.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self._SelectedDropdown then
				self._SelectedDropdown.Visible = false
				self._SelectedDropdown = nil
				self._DropdownFocused = false
			end
		end
	end)

	------------------ SidePane -------------------

	MainGui.SidePane.MouseLeave:Connect(function()
		if self._Widget.AbsoluteSize.X > self._AbsoluteSizes.HideOffset then return end
		if not (self._Output or self._Explorer) then return end
		if not self._DropdownFocused then
			if IsUnderSize2 then return end
			task.wait()
			MainGui.SidePane:TweenSize(UDim2.new(0, 0, 1, -self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
			MainGui.EditorPane:TweenSize(UDim2.new(1, 0, 1,-self._AbsoluteSizes.TopBarAbsoluteSizeY), self._GuiEasingDirection, self._GuiEasingStyle, self._GuiTime, true)
		end
	end)

	LineBar.MouseEnter:Connect(function()
		if self._Widget.AbsoluteSize.X > self._AbsoluteSizes.HideOffset then return end
		local tween = TweenService:Create(MainGui.SideBar, self._GuiTweenInfo, {BackgroundColor3 = Color3.fromRGB(73, 84, 100)})
		tween:Play()
	end)

	LineBar.MouseLeave:Connect(function()
		local tween = TweenService:Create(MainGui.SideBar, self._GuiTweenInfo, {BackgroundColor3 = Color3.fromRGB(22,25,30)})
		tween:Play()
	end)

	------------------ TopBar ---------------------

	local tbl = TopBarLeft:GetChildren()
	local tblcopy = {}
	for i,v in next, tbl do
		if v:IsA('UIListLayout') or v.Name == 'ProjectTitle' then
			table.remove(tbl, i)
		end
	end

	for i,v in next, tbl do
		tblcopy[v.LayoutOrder] = v
	end

	TopBar.MouseWheelForward:Connect(function()
		if tblcopy[self._ScrollIndex-1] then
			tblcopy[self._ScrollIndex-1].Visible = true
		end

		self._ScrollIndex = math.clamp(self._ScrollIndex - 1, 1, #TopBarLeft:GetChildren())

	end)

	TopBar.MouseWheelBackward:Connect(function()
		for i=1,self._ScrollIndex do
			if tblcopy[i] then
				tblcopy[i].Visible = false
			end
		end

		self._ScrollIndex = math.clamp(self._ScrollIndex + 1, 1, #TopBarLeft:GetChildren())
	end)

	------------------ TextBox --------------------

	TextBox:GetPropertyChangedSignal('Text'):Connect(function()
		if #TextBox.Text > 0 then
			TextBox.TextLabel.Visible = false
		else
			TextBox.TextLabel.Visible = true
		end

		local lines = string.split(TextBox.Text, '\n')

		for i,v in ipairs(lines) do
			lines[i] = tostring(i)
		end

		LineBar.TextButton.Text = table.concat(lines, '\n')

		TextBox.Size = UDim2.new(1,-LineBar.AbsoluteSize.X,1,0)

		if self._delete == false then
			if self._CurrentScript then
				self._SavedScripts[self._CurrentScript] = TextBox.Text
			end
		end
	end)

	TextBox.MouseWheelForward:Connect(function()
		if not TextBox:IsFocused() then return end
		ScrollingFrame.CanvasPosition = ScrollingFrame.CanvasPosition - Vector2.new(0, ScrollDistance) 
	end)

	TextBox.MouseWheelBackward:Connect(function()
		if not TextBox:IsFocused() then return end
		ScrollingFrame.CanvasPosition = ScrollingFrame.CanvasPosition + Vector2.new(0, ScrollDistance)
	end)

	TextBox.Focused:Connect(function()
		self._TextBoxFocused = true

		if self._RenamingScript then
			self._RenamingScript = false
			MainGui.SidePane.Explorer.ScriptButtonTextBoxCurrent:Destroy()
		end
	end)

	TextBox.FocusLost:Connect(function()
		self._TextBoxFocused = false
	end)

	TextBox:GetPropertyChangedSignal('CursorPosition'):Connect(function()
		if self._RenamingScript then return end
		if self._TextBoxFocused then
			self._Autocomplete:_Hide()
		end
	end)

	------------------ ServerButton ----------------

	TopBarRight.Side.MouseButton1Click:Connect(function()
		if RunService:IsEdit() then return end
		if self._CurrentSide == 'Server' then
			self._CurrentSide = 'Client'
			TopBarRight.Side.Image = TopBarRight.Side.client.Image
		else
			self._CurrentSide = 'Server'
			TopBarRight.Side.Image = TopBarRight.Side.server.Image
		end
	end)

	------------------ ScrollingFrame --------------

	ScrollingFrame:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		LineBar.Position = UDim2.new(0, ScrollingFrame.CanvasPosition.X, 0, 0)
	end)

	------------------ ProjectBar ------------------

	ProjectButtonFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		ProjectButton.Size = UDim2.new(0, ProjectButtonFrame.AbsoluteSize.X - ProjectCloseButtonAbsoluteSizeX, 1, 0)
	end)

	ProjectButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		ProjectCloseButton.Position = UDim2.new(1,0,0,0)
	end)

	------------------ Dropdown --------------------

	task.wait()
	for i,v in next, TopBarLeft:GetChildren() do
		if v:IsA("TextButton") then
			local Dropdown = DropdownModule.new(self, Dropdown, self._DropdownFunctions[v.Name])
			Dropdown.Name = v.Name
			Dropdown.Position = UDim2.new(0, v.AbsolutePosition.X, 0, v.AbsoluteSize.Y)

			v:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				Dropdown.Position = UDim2.new(0, v.AbsolutePosition.X, 0, v.AbsoluteSize.Y)
			end)

			Dropdown.Parent = MainGui

			v.MouseButton1Click:Connect(function()
				if self._SelectedDropdown == Dropdown then
					self._SelectedDropdown.Visible = false
					self._DropdownFocused = false
					self._SelectedDropdown = nil
					return
				end
				self._SelectedDropdown = Dropdown
				self._SelectedDropdown.Visible = true
				self._DropdownFocused = true
			end)

			v.MouseEnter:Connect(function()
				if self._SelectedDropdown == Dropdown then return end
				if self._SelectedDropdown then
					self._SelectedDropdown.Visible = false
					self._SelectedDropdown = Dropdown
					self._SelectedDropdown.Visible = true
				end
			end)

			Widget.WindowFocusReleased:Connect(function()
				if self._SelectedDropdown then
					self._SelectedDropdown.Visible = false
					self._SelectedDropdown = nil
					self._DropdownFocused = false
				end
			end)
		end
	end

	MainGui.View.Explorer.Text = 'Explorer ✓'
	MainGui.View.Output.Text = 'Output ✓'
	MainGui.View['Project Bar'].Text = 'Project Bar ✓'

	return self
end

function Console:NewScript(name, content)
	if self._SavedScripts[name] then return true end

	self._SavedScripts[name] = content
	return true
end

function Console:GetScript(name)
	self._delete = true

	local TopBar = self._Gui.TopBar
	local ProjectBar = self._Gui.EditorPane.ProjectBar
	local Explorer = self._Gui.SidePane.Explorer

	local function EnsureVisuals(ProjectButtonFrame)
		for i,v in next, ProjectBar:GetChildren() do
			if v:IsA("Frame") then
				v.ProjectButton.BackgroundColor3 = Color3.fromRGB(36, 42, 50)
				v.ProjectButton.TextColor3 = self._Colors.BaseTextColor
				v.Highlight.Visible = false
			end
		end
		for i,v in Explorer:GetChildren() do
			if v:IsA("TextButton") then
				v.BackgroundColor3 = Color3.fromRGB(36, 42, 50)
				v.TextColor3 = self._Colors.BaseTextColor
			end
		end

		Explorer[name].BackgroundColor3 = Color3.fromRGB(51, 59, 70)
		Explorer[name].TextColor3 = self._Colors.HighlightTextColor

		ProjectButtonFrame.ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
		ProjectButtonFrame.ProjectButton.TextColor3 = self._Colors.HighlightTextColor
		ProjectButtonFrame.Highlight.Visible = true

		self._Gui.EditorPane.Settings.Visible = false

		if self._TextBox ~= '' then
			self._TextBox.TextLabel.Visible = false
		end
	end

	if table.find(self._OpenedScripts, name) then
		self._CurrentScript = name

		self._Gui.EditorPane.ScrollingFrame.Visible = true
		self._TextBox.Text = self._SavedScripts[name]

		EnsureVisuals(ProjectBar[name])

		TopBar.Left.ProjectTitle.Text = `{GameName} - {name}`
		self._delete = false
		return true 
	end

	if self._SavedScripts[name] then
		local ProjectButtonFrame = ProjectBar.ProjectButtonFrame:Clone()

		ProjectButtonFrame.Name = name
		ProjectButtonFrame.ProjectButton.Text = name
		ProjectButtonFrame.Visible = self._ProjectBar
		ProjectButtonFrame.Parent = ProjectBar

		self._Gui.EditorPane.ScrollingFrame.Visible = true
		self._TextBox.Text = self._SavedScripts[name]

		EnsureVisuals(ProjectButtonFrame)

		ProjectButtonFrame.ProjectButton.MouseButton1Click:Connect(function()
			self._delete = true
			self._CurrentScript = name

			self._Gui.EditorPane.ScrollingFrame.Visible = true
			self._TextBox.Text = self._SavedScripts[name]

			EnsureVisuals(ProjectButtonFrame)

			TopBar.Left.ProjectTitle.Text = `{GameName} - {name}`
			self._delete = false
		end)

		ProjectButtonFrame.CloseButton.MouseButton1Click:Connect(function()
			self._delete = true

			ProjectButtonFrame:Destroy()
			self._CurrentScript = nil

			table.remove(self._OpenedScripts, table.find(self._OpenedScripts, name))

			if #self._OpenedScripts > 0 then
				self._CurrentScript = self._OpenedScripts[#self._OpenedScripts]
				self._TextBox.Text = self._SavedScripts[self._CurrentScript]

				ProjectBar[self._CurrentScript].ProjectButton.BackgroundColor3 = Color3.fromRGB(51, 59, 70)
				ProjectBar[self._CurrentScript].ProjectButton.TextColor3 = self._Colors.HighlightTextColor
				ProjectBar[self._CurrentScript].Highlight.Visible = true

				task.spawn(function()
					TopBar.Left.ProjectTitle.Text = `{GameName} - {self._CurrentScript}`
				end)

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
				TopBar.Left.ProjectTitle.Text = GameName
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
			end

			self._delete = false
		end)

		if self._ProjectBar == true then
			ProjectBar.Visible = true
		end

		TopBar.Left.ProjectTitle.Text = `{GameName} - {name}`

		table.insert(self._OpenedScripts, name)
		self._CurrentScript = name
		self._delete = false

		return true
	end
end

function Console:Log(msg, args : {})
	msg = tostring(msg)

	local ScrollingFrame = self._Gui.SidePane.Output

	if self._Logs[self._Int-1] then
		if self._Logs[self._Int-1][1] == msg and self._Logs[self._Int-1][2].Type == args.Type then
			ScrollingFrame[self._Int-1].Text = msg..' (x'..(self._DInt)..')'

			self._DInt += 1
			return
		end
	end

	local LogTemplate = ScrollingFrame.LogTemplate:Clone()

	LogTemplate.Text = msg
	LogTemplate.Name = self._Int
	LogTemplate.Visible = true
	LogTemplate.LayoutOrder = self._Int
	LogTemplate.TextColor3 = self._Colors[args.Type or 'normal']
	LogTemplate.RichText = true
	LogTemplate.Parent = ScrollingFrame

	ScrollingFrame.CanvasSize = UDim2.new(0,0,0,ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)
	ScrollingFrame.CanvasPosition = Vector2.new(0,ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)

	table.insert(self._Logs, {msg,args})

	self._Int += 1
	self._DInt = 2
end

function Console:Message(msg, args)
	args = args or {}

	self._message = true

	local Message = self._Gui.BottomBar.Left.MessageLabel

	Message.Text = Functions.color(Functions.time(),Color3.fromRGB(50, 61, 72))..'  '..msg
	Message.Visible = true

	if args.Color ~= nil then
		Message.TextColor3 = args.Color
	else
		Message.TextColor3 = Color3.new(1,1,1)
	end

	if args.Timeout == nil then
		return
	end

	task.spawn(function()
		while task.wait() do
			if self._message == false then
				return
			end
		end
	end)

	task.wait(args.Timeout)

	Message.Text = ''
	Message.Size = UDim2.new(0,0,1,0)
	Message.Visible = false

	self._message = false
end

function Console:Run()
	local err = Runner(self,Sandbox,self._TextBox.Text)

	if err then
		self:Log(err, {Type = 'error'})
	end
end

return Console
