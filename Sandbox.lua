return function(Console, env)
	-- We need to declare all globals as variables in the sandbox to prevent sandbox from breaking from someting like setfenv(1, {})
	local error = error
	local getfenv = getfenv
	local getmetatable = getmetatable
	local loadstring = loadstring
	local newproxy = newproxy
	local pcall = pcall
	local rawset = rawset
	local setfenv = setfenv
	local setmetatable = setmetatable
	local string = string
	local table = table
	local task = task
	local tostring = tostring
	local type = type
	local typeof = typeof
	local unpack = unpack

	local env, newEnv = env, {}

	-- wrapObject() is a function that takes in one argument, and returns a sandboxed version of it. unwrapObject() should take in the sandboxed object and return the unsandboxed one by using a lookup table with the sandboxed object.
	-- I also made 2 helper functions wrapObjects() and unwrapObjects() which can take in multiple objects, you could implement these directly in the normal wrapper functions but it's just some small optimizations.

	local wrapped, unwrapped = {}, {} -- The lookup tables, wrapped contains sandboxed objects, and unwrapped contains the unsandboxed versions.
	local unwrapObject, unwrapObjects
	local wrapObject, wrapObjects

	local unsandboxedTypes = { -- We don't want to sandbox types that cant refer to roblox instances. This is why RaycastParams is not in this list.
		Axes = true,
		BrickColor = true,
		CFrame = true,
		CatalogSearchParams = true,
		Color3 = true,
		ColorSequence = true,
		ColorSequenceKeypoint = true,
		DateTime = true,
		DockWidgetPluginGuiInfo = true,
		Enum = true,
		EnumItem = true,
		Enums = true,
		Faces = true,
		NumberRange = true,
		NumberSequence = true,
		NumberSequenceKeypoint = true,
		PathWaypoint = true,
		PhysicalProperties = true,
		Random = true,
		Ray = true,
		Rect = true,
		Region3 = true,
		Region3int16 = true,
		UDim = true,
		UDim2 = true,
		Vector2 = true,
		Vector2int16 = true,
		Vector3 = true,
		Vector3int16 = true,
		boolean = true,
		["nil"] = true,
		number = true,
		string = true,
	}

	unwrapObject = function(object)
		if object == nil then
			return
		end

		if typeof(object) == "table" then
			if getmetatable(object) ~= nil then -- Checks for metamethods
				local succeed, newObject = pcall(function()
					local newObject = table.clone(object) -- I think I did this to keep metamethods of a table, but there is probably a better way to do this.
					table.clear(newObject)

					for Key, Value in object do
						newObject[unwrapObject(Key)] = unwrapObject(Value)
					end

					return newObject
				end)

				if succeed then
					return newObject
				end
			else
				local newObject = {}

				for Key, Value in object do
					newObject[unwrapObject(Key)] = unwrapObject(Value)
				end

				return newObject
			end
		end

		return unwrapped[object] or object
	end

	unwrapObjects = function(...)
		local Objects = {...}
		for Index = 1, #Objects do
			Objects[Index] = unwrapObject(Objects[Index])
		end

		return unpack(Objects)
	end

	wrapObject = function(object)
		if object == nil then
			return
		end

		if wrapped[object] then
			return wrapped[object]
		end

		if unwrapped[object] then
			return object
		end
		
		local ObjectType = typeof(object)
		if unsandboxedTypes[ObjectType] then
			return object
		end
		
		local newObject
		if ObjectType == "table" then
			newObject = {}
			
			for Key, Value in object do
				newObject[wrapObject(Key)] = wrapObject(Value)
			end
		elseif ObjectType == "function" then
			newObject = function(...)
				return wrapObjects(object(unwrapObjects(...)))
			end
		elseif ObjectType == "Instance" then
			local class, fullName
			local robloxLocked = not pcall(function()
				class, fullName = object.ClassName, object:GetFullName()
			end)

			if robloxLocked then
				class, fullName = "RobloxLocked", "RobloxLocked"
			end
			
			newObject = newproxy(true)
			local metatable = getmetatable(newObject)
			metatable.__metatable = "The metatable is locked"
			
			if robloxLocked then -- You can't do stuff with roblox locked instances anyway.
				function metatable:__index(index)
					if type(index) ~= "string" then
						return error("invalid argument #2 (string expected, got " .. typeof(index) .. ")", 2)
					end

					return error(index .. " is a blocked member of " .. class .. " \"" .. fullName .. "\"", 2)
				end
				
				function metatable:__newindex(index)
					if type(index) ~= "string" then
						return error("invalid argument #2 (string expected, got " .. typeof(index) .. ")", 2)
					end

					return error(index .. " is a set set blocked member of " .. class .. " \"" .. fullName .. "\"", 2)
				end
			else
				function metatable:__index(index)
					if type(index) ~= "string" then
						return error("invalid argument #2 (string expected, got " .. typeof(index) .. ")", 2)
					end

					index = string.gsub(index, "\0", "")
					-- Add code here to perform checks
					
					return wrapObject(object[index])
				end
				
				function metatable:__newindex(index, value)
					if type(index) ~= "string" then
						return error("invalid argument #2 (string expected, got " .. typeof(index) .. ")", 2)
					end
					
					index = string.gsub(index, "\0", "")
					-- Add code here to perform checks
					
					local unwrappedValue = unwrapObject(value)
					if type(unwrappedValue) == "function" then
						object[index] = wrapObject(unwrappedValue)

						return
					end
					
					object[index] = unwrappedValue
				end
			end
			
			function metatable:__tostring()
				return tostring(object)
			end
		else -- For sandboxing any other type
			newObject = newproxy(true)
			local metatable = getmetatable(newObject)
			metatable.__metatable = "The metatable is locked"

			function metatable:__index(index)
				return wrapObject(object[unwrapObject(index)])
			end

			function metatable:__newindex(index, value)
				object[unwrapObject(index)] = unwrapObject(value)
			end

			function metatable:__call(...)
				return wrapObjects(object(unwrapObjects(...)))
			end

			function metatable:__concat(value)
				return wrapObject(object .. unwrapObject(value))
			end

			function metatable:__unm()
				return wrapObject(-object)
			end

			function metatable:__add(value)
				return wrapObject(object + unwrapObject(value))
			end

			function metatable:__sub(value)
				return wrapObject(object - unwrapObject(value))
			end

			function metatable:__mul(value)
				return wrapObject(object * unwrapObject(value))
			end

			function metatable:__div(value)
				return wrapObject(object / unwrapObject(value))
			end

			function metatable:__mod(value)
				return wrapObject(object % unwrapObject(value))
			end

			function metatable:__pow(value)
				return wrapObject(object ^ unwrapObject(value))
			end

			function metatable:__tostring()
				return wrapObject(tostring(object))
			end

			function metatable:__eq(to)
				return wrapObject(object == unwrapObject(to))
			end

			function metatable:__lt(than)
				return wrapObject(object < unwrapObject(than))
			end

			function metatable:__le(than)
				return wrapObject(object <= unwrapObject(than))
			end

			function metatable:__len()
				return wrapObject(#object)
			end
		end
		
		if newObject then
			unwrapped[newObject] = object
			wrapped[object] = newObject
		end

		return newObject
	end

	wrapObjects = function(...)
		local objects = {...}
		for Index = 1, #objects do
			local Object = objects[Index]

			local NewObject = wrapObject(Object)
			if NewObject then
				objects[Index] = NewObject
			end
		end

		return unpack(objects)
	end

	local setEnvGlobals = {} -- Probably a better way to do this.
	local sandboxedEnv = setmetatable({
		script = nil,
		print = function(...)
			Console:Log(..., {
				Type = 'print'
			})
		end,
		warn = function(...)
			Console:Log(..., {
				Type = 'warn'
			})
		end,
	}, {
		__index = function(self, index)
			local value = env[index]
			if setEnvGlobals[value] then -- We do not want to wrap user made globals, as I said there probably exists a better way to do this.
				return value
			end

			local customGlobal = newEnv[index]
			if customGlobal then -- Small optimization by storing the indexed value in a variable, instead of indexing newEnv twice.
				return customGlobal
			end

			return wrapObject(value)
		end,
		__newindex = function(self, index, value)
			if value ~= nil then
				setEnvGlobals[value] = true
			end

			env[index] = value
			rawset(self, index, value)
		end
	})

	env.script = nil

	setfenv(0, sandboxedEnv) 

	return sandboxedEnv
end