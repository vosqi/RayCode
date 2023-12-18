local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local RunService = game:GetService('RunService')

return function(self)
    task.spawn(function()
        local Functions = require(script.Parent.Functions)
    
        repeat task.wait() until self._dataLoaded
    
        while true do
            if plugin:GetSetting('Auto Save') then
                self:Message('Saving...')
    
                local succ = Functions.setData('RayCode Scripts', self._SavedScripts)
    
                if succ then
                    self:Message('Auto Saved', {
                    })
                else
                    self:Message('Failed to Auto Save', {
                        Color = Color3.new(1, 0, 0),
                    })
                end
    
                task.wait(plugin:GetSetting('Auto Save Delay'))
            end
        end
    end)
end