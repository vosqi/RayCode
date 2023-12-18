--[[
    -[Autocomplete]------------------------------------
        This module provides autocomplete functionality for a code editor.

        Credits: vxsqi#5798

        Public Methods:
        - Autocomplete.new(Console)
            Constructs a new Autocomplete object and associates it with a code editor.

        Private Methods:
        - Autocomplete:OnTextChanged()
            Event handler for the TextChanged event of the code editor's TextBox.

        - Autocomplete:GetCursorPosition()
            Returns the position of the cursor in the TextBox.

        - Autocomplete:Check()
            Checks for matching keywords based on the current input.

        - Autocomplete:Complete()
            Completes the current word with the first matching keyword.

        - Autocomplete:Hide()
            Hides the autocomplete suggestions.

        - Autocomplete:Show()
            Displays the autocomplete suggestions.
--]]

local Autocomplete = {}
Autocomplete.__index = Autocomplete

export type KeywordTypes = {
    [string] : string,
}

export type LibraryTypes = {
    [string] : {
        KeywordTypes
    },
}

export type LanguageTypes = {
    keyword: KeywordTypes,
    builtin: KeywordTypes,
    libraries: LibraryTypes,
}

export type EditorTypes = {
    _TextBox: TextBox,
    _AutocompleteFrame: Frame,
    _AutocompleteButton: TextButton,
    _Language: {},
}

-- Services

local StudioService = game:GetService('StudioService')
local TextService = game:GetService('TextService')

-- Local Functions

local function DisplayClassIcon(image, className)
    local succ, res = pcall(function()
        return StudioService:GetClassIcon(className)
    end)

    if not succ then
        return
    end

	for k, v in pairs(res) do
		image[k] = v
	end
end

-- Public Methods

function Autocomplete.new(Editor : EditorTypes)
    --[[ Creates a new Autocomplete object.
        Parameters:
        - Editor : {}

        Returns:
        - self : {}
    --]]

    local self = setmetatable({
        MatchingKeywords = {},
        OldMatchingKeywords = {},
        StartOfWord = nil,
        OldText = nil,
        OldCursorPosition = nil,
    }, Autocomplete)

    self.TextBox = Editor._TextBox
    self.AutocompleteFrame = Editor._AutocompleteFrame
    self.AutocompleteButton = Editor._AutocompleteButton
    self.Language = Editor._Language

    self.TextBox:GetPropertyChangedSignal('Text'):Connect(function()
        self:_OnTextChanged()
    end)

    self.TextBox:GetPropertyChangedSignal('CursorPosition'):Connect(function()
        if (self.TextBox.CursorPosition - self.OldCursorPosition) < -1 then
            self:_Hide()
        end
    end)

    return self
end

-- Private Methods

function Autocomplete:_OnTextChanged()
    local MatchingWords = self:_Check()

    if self.TextBox.Text:sub(self.TextBox.CursorPosition-1, self.TextBox.CursorPosition-1) == '\t' then
        if #self.OldMatchingKeywords == 0 then
            self.TextBox.Text = self.TextBox.Text:gsub("\t","    ")
            self.TextBox.CursorPosition = self.TextBox.CursorPosition + 3
        else
            self.TextBox.Text = self.TextBox.Text:gsub("\t","")
            self:_Complete()
        end
    end

    self.OldText = self.TextBox.Text
    self.OldCursorPosition = self.TextBox.CursorPosition
    self.OldMatchingKeywords = MatchingWords
end

function Autocomplete:_GetCursorPosition() : UDim2
    --[[
        Returns:
        - CursorPosition : UDim2
    --]]

    local TextBox = self.TextBox
    local CursorPosition = TextBox.CursorPosition
    local Font = TextBox.Font
    local FontSize = TextBox.TextSize
    local Text = TextBox.Text
    local CurrentLine = Text:sub(1, CursorPosition):split("\n")[#Text:sub(1, CursorPosition):split("\n")]
    local UIPadding = TextBox.UIPadding

    local XOffset = UIPadding.PaddingLeft.Offset + TextBox.AbsolutePosition.X
    local YOffset = UIPadding.PaddingTop.Offset + TextBox.AbsolutePosition.Y - FontSize

    local CursorXOffset = TextService:GetTextSize(CurrentLine, FontSize, Font, Vector2.new(10000, 10000)).X
    local CursorYOffset = TextService:GetTextSize(Text:sub(1, CursorPosition), FontSize, Font, Vector2.new(10000, 10000)).Y

    return UDim2.new(0, CursorXOffset + XOffset, 0, CursorYOffset + YOffset) + UDim2.fromOffset(0, FontSize)
end

function Autocomplete:_Check() : {}
    --[[
        Returns:
        - MatchingKeywords : {}
    --]]
    if not self.TextBox:IsFocused() then
        self:_Hide()
        return {}
    end

    local Text = self.TextBox.Text
    local CursorPosition = self.TextBox.CursorPosition

    local Pattern = "[%w_.]+$"
    local StartOfWord = Text:sub(1, CursorPosition):find(Pattern)
    local CurrentWord = StartOfWord and Text:sub(StartOfWord, CursorPosition)

    local MatchingKeywords = {}

    if CurrentWord == nil then
        self:_Hide()
        return {}
    end

    local LibraryPattern = "([%w_]+)%.([%w_]*)"
    local LibraryName, AfterPeriod = CurrentWord:match(LibraryPattern)

    if LibraryName then
        local LibraryKeywords = self.Language.libraries[LibraryName]

        if LibraryKeywords then
            for Keyword, Type in LibraryKeywords do
                if AfterPeriod == "" or Keyword:sub(1, #AfterPeriod) == AfterPeriod then
                    table.insert(MatchingKeywords, {Keyword = Keyword, Type = Type})
                end
            end
        end
    else
        local LocalPattern = "local%s+([%w_]+)%s*="

        for LocalVar in Text:gmatch(LocalPattern) do
            if LocalVar:sub(1, #CurrentWord) == CurrentWord then
                table.insert(MatchingKeywords, {Keyword = LocalVar, Type = "local"})
            end
        end

        for _, v in self.Language do
            for Keyword, Type in v do
                if Keyword:sub(1, #CurrentWord) == CurrentWord then
                    table.insert(MatchingKeywords, {Keyword = Keyword, Type = Type})
                end
            end
        end
    end

    self.MatchingKeywords = MatchingKeywords
    self.StartOfWord = StartOfWord
    self:_Hide()
    self:_Show()

    self.AutocompleteFrame:TweenPosition(self:_GetCursorPosition(), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.1, true)

    return MatchingKeywords
end

function Autocomplete:_Complete()
    if not self.MatchingKeywords[1] then return end

    local CurrentWord = self.TextBox.Text:sub(self.StartOfWord, self.TextBox.CursorPosition - 1)

    local LibraryPattern = "([%w_]+)%.([%w_]*)"
    local LibraryName = CurrentWord:match(LibraryPattern)

    local NewText = ""
    local NewCursorPosition = self.TextBox.CursorPosition

    if LibraryName then
        NewText = self.TextBox.Text:sub(1, self.StartOfWord - 1) .. LibraryName .. "." .. self.MatchingKeywords[1].Keyword .. self.TextBox.Text:sub(self.TextBox.CursorPosition + 1)
        NewCursorPosition = self.StartOfWord + #LibraryName + 1 + #self.MatchingKeywords[1].Keyword
    else
        NewText = self.TextBox.Text:sub(1, self.StartOfWord - 1) .. self.MatchingKeywords[1].Keyword .. self.TextBox.Text:sub(self.TextBox.CursorPosition + 1)
        NewCursorPosition = self.StartOfWord + #self.MatchingKeywords[1].Keyword
    end

    if self.MatchingKeywords[1].Type == "function" then
        NewText = NewText .. "()"
        NewCursorPosition = NewCursorPosition + 1
    end

    self.TextBox.Text = NewText
    self.TextBox.CursorPosition = NewCursorPosition
    self:_Hide()
end

function Autocomplete:_Hide()
    self.AutocompleteFrame.Visible = false

    for _, v in ipairs(self.AutocompleteFrame:GetChildren()) do
        if v.Name == "AutocompleteButton" and v.Visible then
            v:Destroy()
        end
    end
end

function Autocomplete:_Show()
    local MatchingKeywords = self.MatchingKeywords

    if #MatchingKeywords == 0 then
        self:_Hide()
        return {}
    end

    self.AutocompleteFrame.Visible = true

    for _, v in ipairs(MatchingKeywords) do
        local Button = self.AutocompleteButton:Clone()
        Button.Text = v.Keyword

        DisplayClassIcon(Button.ImageLabel, v.Type)

        Button.Visible = true
        Button.Parent = self.AutocompleteFrame

        Button.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.TextBox.Text = self.TextBox.Text:sub(1, self.StartOfWord - 1) .. v.Keyword .. self.TextBox.Text:sub(self.TextBox.CursorPosition + 1)
                self.TextBox.CursorPosition = self.StartOfWord + #v.Keyword
                self:_Hide()
            end
        end)
    end
end

return Autocomplete