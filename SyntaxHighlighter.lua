local plugin = script:FindFirstAncestorWhichIsA("Plugin")
local defaults = require(script.Parent.Settings)()

return function(TextBox)
	local settings = {
		Highlight = (plugin:GetSetting('Syntax Highlight') == nil and defaults.Editor['Syntax Highlight']) or plugin:GetSetting('Syntax Highlight');
		HighlightVariables = (plugin:GetSetting('Highlight Variables') == nil and defaults.Editor['Highlight Variables']) or plugin:GetSetting('Highlight Variables');
		SplitScanLines = false;
		WaitIfRendered = true;
		AutomaticSettingChange = true;
		LoadLexer = true;
	}

	local RunService = game:GetService("RunService")
	local Fps=0
	local TimeFunction = RunService:IsRunning() and time or os.clock

	local LastIteration, Start
	local FrameUpdateTable = {}

	local HighlightDidRun = false
	local HighlightVariablesDidRun = false

	local function HeartbeatUpdate()
		LastIteration = TimeFunction()
		for Index = #FrameUpdateTable, 1, -1 do
			FrameUpdateTable[Index + 1] = FrameUpdateTable[Index] >= LastIteration - 1 and FrameUpdateTable[Index] or nil
		end

		FrameUpdateTable[1] = LastIteration
		Fps = tonumber(math.floor(TimeFunction() - Start >= 1 and #FrameUpdateTable or #FrameUpdateTable / (TimeFunction() - Start)))

		settings.Highlight = (plugin:GetSetting('Syntax Highlight') == nil and defaults.Editor['Syntax Highlight']) or plugin:GetSetting('Syntax Highlight')
		settings.HighlightVariables = (plugin:GetSetting('Highlight Variables') == nil and defaults.Editor['Highlight Variables']) or plugin:GetSetting('Highlight Variables')

		if settings.Highlight then
			if HighlightDidRun == false then
				HighlightDidRun = true

				TextBox.Text ..= ' '
				TextBox.Text = TextBox.Text:sub(1,-2)
			end
		end

		if settings.HighlightVariables then
			if HighlightVariablesDidRun == false then
				HighlightVariablesDidRun = true

				TextBox.Text ..= ' '
				TextBox.Text = TextBox.Text:sub(1,-2)
			end
		end

		if settings.Highlight == false then
			HighlightDidRun = false

			for i,v in TextBox:GetChildren() do
				if v:IsA("TextLabel") and v.Name:sub(-1,-1) == '_' then
					v.Text = ''
				end
			end
		end

		if settings.HighlightVariables == false then
			HighlightVariablesDidRun = false

			TextBox.Vars_.Text = ''
		end
	end

	Start = TimeFunction()
	RunService.Heartbeat:Connect(HeartbeatUpdate)

	local function parse(tokens)
		local localvarables = {}
		local whitespacecharactersfound=0
		local readabletokens = {}
		local tokennumbers = {}
		for i,v in pairs(tokens) do
			if v.Source == " " then
				whitespacecharactersfound+=1
				continue
			end
			if v.Type=="space" then
				whitespacecharactersfound+=1
				continue
			end

			table.insert(readabletokens,v)
			table.insert(tokennumbers,{i})
		end

		for i,v in pairs(readabletokens) do
			pcall(function()
				if v.Source == "local" then
					local _,name =pcall(function()return readabletokens[i+1].Source;end)
					if _==false then
						error("Syntax Error: Expected more code")
					end
					if name == "function" then
						_,name =pcall(function()return readabletokens[i+2].Source;end)
						if _==false then
							error("Syntax Error: Expected more code")
						end
						if readabletokens[i+2].Type~="iden" then
							error("Syntax Error: Name isnt an idient")
						end
						table.insert(localvarables,{Name = name,Type="Local",Source = "function",number = tokennumbers[i][1]+4})
					else
						table.insert(localvarables,{Name = name,Type="Local",Source = readabletokens[i+3].Source,number = tokennumbers[i]
							[1]+1})
					end
				elseif v.Type == "iden"  then

					if readabletokens[i-1] then
						if readabletokens[i-1].Type ~= "keyword" and readabletokens[i-1].Type ~= "symbol"  then
							local source = readabletokens[i+2].Source
							table.insert(localvarables,{Name = v.Source,Type="Global",Source = source;number = tokennumbers[i]
								[1]})  
						elseif readabletokens[i-1].Source=="function" then
							local source = "function"
							table.insert(localvarables,{Name = v.Source,Type="Global",Source = source;number = tokennumbers[i]
								[1]})  

						end
					else
						local source = readabletokens[i+2].Source
						table.insert(localvarables,{Name = v.Source,Type="Global",Source = source,number = tokennumbers[i][1]})  
					end
				end
			end)
		end

		return (localvarables)
	end
	local function lexerscan(text)
		local lexer = coroutine.wrap(function()

			local lexer = {}

			local yield, wrap  = coroutine.yield, coroutine.wrap
			local strfind      = string.find
			local strsub       = string.sub
			local append       = table.insert
			local type         = type

			local NUMBER1	= "^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+"
			local NUMBER2	= "^[%+%-]?%d+%.?%d*"
			local NUMBER3	= "^0x[%da-fA-F]+"
			local NUMBER4	= "^%d+%.?%d*[eE][%+%-]?%d+"
			local NUMBER5	= "^%d+%.?%d*"
			local IDEN		= "^[%a_][%w_]*"
			local WSPACE	= "^%s+"
			local STRING1	= "^(['\"])%1"							
			local STRING2	= [[^(['"])(\*)%2%1]]
			local STRING3	= [[^(['"]).-[^\](\*)%2%1]]
			local STRING4	= "^(['\"]).-.*"						
			local STRING5	= "^%[(=*)%[.-%]%1%]"					
			local STRING6	= "^%[%[.-.*"							
			local CHAR1		= "^''"
			local CHAR2		= [[^'(\*)%1']]
			local CHAR3		= [[^'.-[^\](\*)%1']]
			local PREPRO	= "^#.-[^\\]\n"
			local MCOMMENT1	= "^%-%-%[(=*)%[.-%]%1%]"				
			local MCOMMENT2	= "^%-%-%[%[.-.*"						
			local SCOMMENT1	= "^%-%-.-\n"							
			local SCOMMENT2	= "^%-%-.-.*"							

			local lua_keyword = {
				["and"] = true,  ["break"] = true,  ["do"] = true,      ["else"] = true,      ["elseif"] = true,
				["end"] = true,  ["false"] = true,  ["for"] = true,     ["function"] = true,  ["if"] = true,
				["in"] = true,   ["local"] = true,  ["nil"] = true,     ["not"] = true,       ["while"] = true,
				["or"] = true,   ["repeat"] = true, ["return"] = true,  ["then"] = true,      ["true"] = true,
				["self"] = true, ["until"] = true
			}

			local lua_builtin = {
				["assert"] = true;["collectgarbage"] = true;["error"] = true;["_G"] = true;
				["gcinfo"] = true;["getfenv"] = true;["getmetatable"] = true;["ipairs"] = true;
				["loadstring"] = true;["newproxy"] = true;["next"] = true;["pairs"] = true;
				["pcall"] = true;["print"] = true;["rawequal"] = true;["rawget"] = true;["rawset"] = true;
				["select"] = true;["setfenv"] = true;["setmetatable"] = true;["tonumber"] = true;
				["tostring"] = true;["type"] = true; ['export'] = true; ["unpack"] = true;["_VERSION"] = true;["xpcall"] = true;
				["delay"] = true;["elapsedTime"] = true;["require"] = true;["spawn"] = true;["tick"] = true;
				["time"] = true;["typeof"] = true;["UserSettings"] = true;["wait"] = true;["warn"] = true;
				["game"] = true;["Enum"] = true;["script"] = true;["shared"] = true;["workspace"] = true;
				["Axes"] = true;["BrickColor"] = true;["CFrame"] = true;["Color3"] = true;["ColorSequence"] = true;
				["ColorSequenceKeypoint"] = true;["Faces"] = true;["Instance"] = true;["NumberRange"] = true;
				["NumberSequence"] = true;["NumberSequenceKeypoint"] = true;["PhysicalProperties"] = true;
				["Random"] = true;["Ray"] = true;["Rect"] = true;["Region3"] = true;["Region3int16"] = true;
				["TweenInfo"] = true;["UDim"] = true;["UDim2"] = true;["Vector2"] = true;["Vector3"] = true;
				["Vector3int16"] = true; ['task'] = true;
				["os"] = true;
				["os.time"] = true;["os.date"] = true;["os.difftime"] = true;
				["debug"] = true;
				["debug.traceback"] = true;["debug.profilebegin"] = true;["debug.profileend"] = true;
				["math"] = true;
				["math.abs"] = true;["math.acos"] = true;["math.asin"] = true;["math.atan"] = true;["math.atan2"] = true;["math.ceil"] = true;["math.clamp"] = true;["math.cos"] = true;["math.cosh"] = true;["math.deg"] = true;["math.exp"] = true;["math.floor"] = true;["math.fmod"] = true;["math.frexp"] = true;["math.ldexp"] = true;["math.log"] = true;["math.log10"] = true;["math.max"] = true;["math.min"] = true;["math.modf"] = true;["math.noise"] = true;["math.pow"] = true;["math.rad"] = true;["math.random"] = true;["math.randomseed"] = true;["math.sign"] = true;["math.sin"] = true;["math.sinh"] = true;["math.sqrt"] = true;["math.tan"] = true;["math.tanh"] = true;
				["coroutine"] = true;
				["coroutine.create"] = true;["coroutine.resume"] = true;["coroutine.running"] = true;["coroutine.status"] = true;["coroutine.wrap"] = true;["coroutine.yield"] = true;
				["string"] = true;
				["string.byte"] = true;["string.char"] = true;["string.dump"] = true;["string.find"] = true;["string.format"] = true;["string.len"] = true;["string.lower"] = true;["string.match"] = true;["string.rep"] = true;["string.reverse"] = true;["string.sub"] = true;["string.upper"] = true;["string.gmatch"] = true;["string.gsub"] = true;
				["table"] = true;
				["table.concat"] = true;["table.insert"] = true;["table.remove"] = true;["table.sort"] = true;
			}

			local function tdump(tok)
				return yield(tok, tok)
			end

			local function ndump(tok)
				return yield("number", tok)
			end

			local function sdump(tok)
				return yield("string", tok)
			end

			local function cdump(tok)
				return yield("comment", tok)
			end

			local function wsdump(tok)
				return yield("space", tok)
			end

			local function lua_vdump(tok)
				if (lua_keyword[tok]) then
					return yield("keyword", tok)
				elseif (lua_builtin[tok]) then
					return yield("builtin", tok)
				else
					return yield("iden", tok)
				end
			end

			local lua_matches = {
				{IDEN,      lua_vdump},        -- Indentifiers
				{WSPACE,    wsdump},           -- Whitespace
				{NUMBER3,   ndump},            -- Numbers
				{NUMBER4,   ndump},
				{NUMBER5,   ndump},
				{STRING1,   sdump},            -- Strings
				{STRING2,   sdump},
				{STRING3,   sdump},
				{STRING4,   sdump},
				{STRING5,   sdump},            -- Multiline-Strings
				{STRING6,   sdump},            -- Multiline-Strings

				{MCOMMENT1, cdump},            -- Multiline-Comments
				{MCOMMENT2, cdump},			
				{SCOMMENT1, cdump},            -- Singleline-Comments
				{SCOMMENT2, cdump},

				{"^==",     tdump},            -- Operators
				{"^~=",     tdump},
				{"^<=",     tdump},
				{"^>=",     tdump},
				{"^%.%.%.", tdump},
				{"^%.%.",   tdump},
				{"^.",      tdump}
			}

			local num_lua_matches = #lua_matches


			--- Create a plain token iterator from a string.
			-- @tparam string s a string.
			function lexer.scan(s)

				local function lex(first_arg)

					local line_nr = 0
					local sz = #s
					local idx = 1

					-- res is the value used to resume the coroutine.
					local function handle_requests(res)
						while (res) do
							local tp = type(res)
							-- Insert a token list:
							if (tp == "table") then
								res = yield("", "")
								for i = 1,#res do
									local t = res[i]
									res = yield(t[1], t[2])
								end
							elseif (tp == "string") then -- Or search up to some special pattern:
								local i1, i2 = strfind(s, res, idx)
								if (i1) then
									local tok = strsub(s, i1, i2)
									idx = (i2 + 1)
									res = yield("", tok)
								else
									res = yield("", "")
									idx = (sz + 1)
								end
							else
								res = yield(line_nr, idx)
							end
						end
					end

					handle_requests(first_arg)
					line_nr = 1

					while (true) do

						if (idx > sz) then
							while (true) do
								handle_requests(yield())
							end
						end

						for i = 1,num_lua_matches do
							local m = lua_matches[i]
							local pat = m[1]
							local fun = m[2]
							local findres = {strfind(s, pat, idx)}
							local i1, i2 = findres[1], findres[2]
							if (i1) then
								local tok = strsub(s, i1, i2)
								idx = (i2 + 1)
								lexer.finished = (idx > sz)
								local res = fun(tok, findres)
								if (tok:find("\n")) then
									-- Update line number:
									local _,newlines = tok:gsub("\n", {})
									line_nr = (line_nr + newlines)
								end
								handle_requests(res)
								break
							end
						end

					end

				end

				return wrap(lex)

			end

			return lexer
		end)()
		local function doesvalueexist(value,tab)
			for i,v in pairs(tab) do
				if v == value then
					return true
				end
			end
			return false or nil
		end
		local symbols = {
			";";
			"^";
			"(";
			")";
			"%";
			"/";
			":";
			"#";
			"-";
			"=";
			"+";
			"{";
			"}";
			"~";
			"<";
			">";
			"*";
			",";
			".";
			"\""}
		local t={}
		local split=text:split("\n")
		if settings.SplitScanLines==true then
			for _, splitv in pairs(text:split("\n")) do 
				for i,v in (lexer.scan(splitv)) do
					local type= i
					if doesvalueexist(type,symbols)  then-- makes the type "symbol" if it is a symbol
						type="symbol"
					end
					table.insert(t,{Type=type,Source=v})
				end
				table.insert(t,{Type="space",Source="\n"})--dont remove this unless you know what you're doing
				if settings.WaitIfRendered then
					game:GetService("RunService").RenderStepped:Wait()
				end
			end
		else

			for i,v in (lexer.scan(text)) do
				local type= i
				if doesvalueexist(type,symbols)  then-- makes the type "symbol" if it is a symbol
					type="symbol"
				end
				table.insert(t,{Type=type,Source=v})
				if settings.WaitIfRendered then
					game:GetService("RunService").RenderStepped:Wait()
				end
			end



		end
		return(t)
	end
	local GetTypeToMakeSyntax=function(s,t)
		if type(s)=="string" then
			if t=="var" then
				local tokens=lexerscan(s)
				local r=""
				local variables=parse(tokens)
				local s={}
				for i,v in ipairs(variables) do
					s[v.Name]=v
				end
				for i,v in ipairs(tokens) do
					if s[v.Source] then
						if tokens[i-1] then
							if tokens[i-1].Source~="." then
								r=r..v.Source
							else
								continue
							end
						else
							r=r..v.Source
						end
					else
						local s=string.gsub(v.Source,"%d",function(c)return string.rep(" ",#c)end)
						local p=string.gsub(s,"%p",function(c)return string.rep(" ",#c)end)
						local a=string.gsub(p,"%a",function(c)return string.rep(" ",#c)end)
						r=r..a
					end
				end

				return(r)
			else
				local tokens=lexerscan(s)
				local r=""
				for i,v in ipairs(tokens) do
					if v.Type==t then
						r=r..v.Source
					else
						local s=string.gsub(v.Source,"%d",function(c)return string.rep(" ",#c)end)
						local p=string.gsub(s,"%p",function(c)return string.rep(" ",#c)end)
						local a=string.gsub(p,"%a",function(c)return string.rep(" ",#c)end)
						r=r..a
					end
				end

				return(r)
			end
		elseif type(s)=="table" then
			if t=="var" then
				local tokens=s
				local r=""
				local variables=parse(tokens)
				local s={}
				for i,v in ipairs(variables) do
					s[v.Name]=v
				end
				for i,v in ipairs(tokens) do
					if s[v.Source] then
						if tokens[i-1] then
							if tokens[i-1].Source~="." then
								r=r..v.Source
							else
								continue
							end
						else
							r=r..v.Source
						end
					else
						local s=string.gsub(v.Source,"%d",function(c)return string.rep(" ",#c)end)
						local p=string.gsub(s,"%p",function(c)return string.rep(" ",#c)end)
						local a=string.gsub(p,"%a",function(c)return string.rep(" ",#c)end)
						r=r..a
					end
				end

				return(r)
			else
				local tokens=s
				local r=""
				for i,v in ipairs(tokens) do
					if v.Type==t then
						r=r..v.Source
					else
						local s=string.gsub(v.Source,"%d",function(c)return string.rep(" ",#c)end)
						local p=string.gsub(s,"%p",function(c)return string.rep(" ",#c)end)
						local a=string.gsub(p,"%a",function(c)return string.rep(" ",#c)end)
						r=r..a
					end
				end

				return(r)
			end
		end
	end

	local L_1_ = TextBox
	local L_2_ = Vector2.new(0, 0)  
	local L_3_Org = {      "getrawmetatable",       "game",       "workspace",       "script",       "math",       "string",       "table",       "print",       "wait",       "BrickColor",       "Color3",       "next",       "pairs",       "ipairs",       "select",       "unpack",       "Instance",       "Vector2",       "Vector3",       "CFrame",       "Ray",       "UDim2",       "Enum",       "assert",       "error",       "warn",       "tick",       "loadstring",       "_G",       "shared",       "getfenv",       "setfenv",       "newproxy",       "setmetatable",       "getmetatable",       "os",       "debug",       "pcall",       "ypcall",       "xpcall",       "rawequal",       "rawset",       "rawget",       "tonumber",       "tostring",       "type",       "typeof",       "_VERSION",       "coroutine",       "delay",       "require",       "spawn",       "LoadLibrary",       "settings",       "stats",       "time",       "UserSettings",       "version",       "Axes",       "ColorSequence",       "Faces",       "ColorSequenceKeypoint",       "NumberRange",       "NumberSequence",       "NumberSequenceKeypoint",       "gcinfo",       "elapsedTime",       "collectgarbage",       "PhysicalProperties",       "Rect",       "Region3",       "Region3int16",       "UDim",       "Vector2int16",       "Vector3int16" } 
	local L_3_ = {      "getrawmetatable",       "game",       "workspace",       "script",       "math",       "string",       "table",       "print",       "wait",       "BrickColor",       "Color3",       "next",       "pairs",       "ipairs",       "select",       "unpack",       "Instance",       "Vector2",       "Vector3",       "CFrame",       "Ray",       "UDim2",       "Enum",       "assert",       "error",       "warn",       "tick",       "loadstring",       "_G",       "shared",       "getfenv",       "setfenv",       "newproxy",       "setmetatable",       "getmetatable",       "os",       "debug",       "pcall",       "ypcall",       "xpcall",       "rawequal",       "rawset",       "rawget",       "tonumber",       "tostring",       "type",       "typeof",       "_VERSION",       "coroutine",       "delay",       "require",       "spawn",       "LoadLibrary",       "settings",       "stats",       "time",       "UserSettings",       "version",       "Axes",       "ColorSequence",       "Faces",       "ColorSequenceKeypoint",       "NumberRange",       "NumberSequence",       "NumberSequenceKeypoint",       "gcinfo",       "elapsedTime",       "collectgarbage",       "PhysicalProperties",       "Rect",       "Region3",       "Region3int16",       "UDim",       "Vector2int16",       "Vector3int16" } 
	local L_4_ = {       "and",       "break",       "do",       "else",       "elseif",       "end",       "false",       "for",       "function",       "goto",       "if",       "in",       "local",       "nil",       "not",       "or",       "repeat",       "return",       "then",       "true",       "until",       "while" } 

	local function L_5_func(L_49_arg1)       
		local L_50_, L_51_ = L_49_arg1.CanvasSize.Y.Offset, L_49_arg1.AbsoluteWindowSize.Y       
		local L_52_ = L_50_ - L_51_       
		if L_52_ < 0 then             
			L_52_ = 0
		end       
		local L_53_ = Vector2.new(L_49_arg1.CanvasPosition.X, L_52_)       
		return L_53_ 
	end 
	local function ofodguisgfhjjksfghkgh(L_49_arg1)       
		local L_50_, L_51_ = L_49_arg1.CanvasSize.X.Offset, L_49_arg1.AbsoluteWindowSize.X       
		local L_52_ = L_50_ - L_51_       
		if L_52_ < 0 then             
			L_52_ = 0
		end       
		local L_53_ = Vector2.new(L_52_,L_49_arg1.CanvasPosition.Y)       
		return L_53_ 
	end 
	local function GetLineSelected(s)
		local text =  s.Text
		local p = s.CursorPosition
		local text2 = ""
		for i = p,1,-1 do
			local c = text:sub(i,i)
			if c == "\n" then
				break
			else
				text2 = text2 .. c
			end
		end

		return (text2:reverse())
	end

	local L_6_ = 20 
	L_1_:GetPropertyChangedSignal("Text"):Connect(function()
		if settings.Highlight then
			local L_54_ = L_1_.Comments_       
			local L_56_ = L_1_.Tokens_       
			local L_57_ = L_1_.Numbers_       
			local L_58_ = L_1_.Strings_             
			local L_61_ = L_1_.Keywords_       
			local L_62_ = L_1_.Globals_  
			local L_90_ = L_1_.Vars_  
			local L_91_ = L_1_.Iden_
			if settings.LoadLexer then
				local tokens= lexerscan(L_1_.Text) 
				L_54_.Text=GetTypeToMakeSyntax(tokens,"comment")

				L_58_.Text=GetTypeToMakeSyntax(tokens,"string")

				L_57_.Text=GetTypeToMakeSyntax(tokens,"number")

				L_62_.Text=GetTypeToMakeSyntax(tokens,"builtin")

				L_56_.Text=GetTypeToMakeSyntax(tokens,"symbol")

				L_61_.Text=GetTypeToMakeSyntax(tokens,"keyword")

				if settings.HighlightVariables then
					L_90_.Text=GetTypeToMakeSyntax(tokens,"var")
				end

			else
				spawn(function()
					L_54_.Text=GetTypeToMakeSyntax(L_1_.Text,"comment")
				end)
				spawn(function()
					L_58_.Text=GetTypeToMakeSyntax(L_1_.Text,"string")
				end)
				spawn(function()
					L_57_.Text=GetTypeToMakeSyntax(L_1_.Text,"number")
				end)
				spawn(function()
					L_62_.Text=GetTypeToMakeSyntax(L_1_.Text,"builtin")
				end)
				spawn(function()
					L_56_.Text=GetTypeToMakeSyntax(L_1_.Text,"symbol")
				end)
				spawn(function()
					L_61_.Text=GetTypeToMakeSyntax(L_1_.Text,"keyword")
				end)
				spawn(function()
					if settings.HighlightVariables then
						L_90_.Text=GetTypeToMakeSyntax(L_1_.Text,"var")
					end
				end)

			end
		end
		local L_63_ = 1    
	end) 

	if settings.AutomaticSettingChange== true then
		
		spawn(function()
			pcall(function()
				while task.wait(10) do
					settings.Highlight=true
					if Fps>50 then
						settings.SplitScanLines=false
						settings.LoadLexer=false
						settings.WaitIfRendered=false
						
					elseif Fps<60 and Fps>40 then
						settings.SplitScanLines=false
						settings.LoadLexer=true
						settings.WaitIfRendered=true
						settings.HighlightVariables=false
						
					elseif Fps<35 then
						settings.SplitScanLines=true
						settings.LoadLexer=true
						settings.WaitIfRendered=true
						settings.HighlightVariables=false
						
					elseif Fps>10 then
						settings.Highlight=false
					end
				end
			end)
		end)
	end
end