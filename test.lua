local ins = game:GetService('InsertService')
local rs = game:GetService('RunService')

local conns = {}

local function give(plr,msg)
	if msg:split(' ')[1] == '/give' then
		local id = tonumber(msg:split(' ')[2]) or 16726030
		local gear

		local succ, err = pcall(function()
			gear = ins:LoadAsset(id):FindFirstChildWhichIsA('Tool')
		end)

		if not succ then return end
		if not gear then return end

		gear.Parent = plr.Backpack
	end
end

for i,v in game.Players:GetPlayers() do	
	conns[v.UserId] = v.Chatted:Connect(function(msg)
		give(v,msg)
	end)
end

game.Players.PlayerAdded:Connect(function(plr)
	if conns[plr.UserId] then return end
	conns[plr.UserId] = plr.Chatted:Connect(function(msg)
		give(plr,msg)
	end)
end)

game.Players.PlayerRemoving:Connect(function(plr)
	conns[plr.UserId]:Disconnect()
	conns[plr.UserId] = nil
end)
