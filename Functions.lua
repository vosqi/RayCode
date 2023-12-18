local module = {}

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("RayCode")

local escapes = require(script.Parent.Escapes)
local colors = require(script.Parent.Colors)

local rand = Random.new(tick())

function module.getData(key)
	local success, result = pcall(function()
		return DataStore:GetAsync(key)
	end)
	if success then
		return result
	end
end

function module.setData(key,value)
	local success, result = pcall(function()
		return DataStore:SetAsync(key,value)
	end)
	if success then
		return result
	else
		return false
	end
end

function module.selectonly(idx, ...)
	return ({...})[idx]
end

function module.richescape(text)
	return module.selectonly(1, tostring(text):gsub(".", escapes))
end

function module.color(msg,color)
	local colorpack = color or colors.white
	local r,g,b

	if typeof(color) ~= 'Color3' then
		colorpack = colors[color] or colors.white
	end		
		
	r,g,b = colorpack.R*255,colorpack.G*255,colorpack.B*255
	return string.format('<font color="rgb(%d,%d,%d)">%s</font>',r,g,b,module.richescape(msg))
end

function module.time()
	return `{os.date('%H')}:{os.date('%M')}:{os.date('%S')}`
end

function module.randstr(len,chars)
	local mask = ""
	if chars:match("a") then
		mask ..= "abcdefghijklmnopqrstuvwxyz"
	end
	if chars:match("A") then
		mask ..= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	end
	if chars:match("#") then
		mask ..= "0123456789"
	end
	if chars:match("!") then
		mask ..= "~`!@#$%^&*()_+-={}[]:\";'<>?,./|\\"
	end
	local res = ""
	for i = 1, len do
		local idx = rand:NextInteger(1, #mask)
		res ..= string.sub(mask, idx, idx)
	end
	return res
end

function module.todictionary(tbl)
	local res = {}
	for i,v in next, tbl do
		res[i] = v
	end
	return res
end

return module