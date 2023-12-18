-----------------------VARIABLES--------------
local Functions = require(script.Parent.Functions)

local Gui = script.Parent.MainGui
local TopBarLeft = Gui.TopBar.Left
local TopBarRight = Gui.TopBar.Right

local Toolbar = plugin:CreateToolbar("RayCode")
local Button = Toolbar:CreateButton("RayCode", 'Run code straight from RayCode', "rbxassetid://12825519112")
local Widget = plugin:CreateDockWidgetPluginGui(
    'RayCode',
    DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Bottom,
        false,
        false,
        0,
        0,
        Gui.TopBar.Left.File.AbsoluteSize.X*3 + Gui.TopBar.Right.AbsoluteSize.X,
        200
    )
)
local MainGui = require(script.Parent.GuiHandler).new(Widget)
local DroptownFunctions = require(script.Parent.DropdownFunctions)(MainGui)
for i,v in next, DroptownFunctions do
    for _,v in next, v do
        local PluginAction = plugin:CreatePluginAction(`{i}_{v[1]}`, `RAYCODE {v[1]}`, v[1])
        PluginAction.Triggered:Connect(v[2])
    end
end

-----------------------PROPERTIES-------------

Widget.Name = 'RayCode'
Widget.Title = "RayCode"
MainGui.Parent = Widget

-----------------------EVENTS-----------------

Button.Click:Connect(function()
    Widget.Enabled = not Widget.Enabled
end)