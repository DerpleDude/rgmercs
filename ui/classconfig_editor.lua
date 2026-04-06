local mq          = require('mq')
local ImGui       = require('ImGui')
local Config      = require('utils.config')
local Globals     = require('utils.globals')
local Ui          = require('utils.ui')
local ClassLoader = require('utils.classloader')
local Modules     = require('utils.modules')
local Icons       = require('mq.ICONS')
local Zep         = require('Zep')

local EditorUI           = { _version = '1.0', _name = "ClassConfigEditor", _author = 'Derple', }
EditorUI.__index         = EditorUI

EditorUI.classConfig     = nil
EditorUI.configFilePath  = nil
EditorUI.selectedSection = "AbilitySets"
EditorUI.selectedKey     = nil   -- rotation name or ability set key
EditorUI.selectedEntry   = nil   -- 1-based index into rotation entries
EditorUI.selectedFunc    = nil   -- which function field is loaded in the editor
EditorUI.filterText      = ""
EditorUI.saveStatus      = nil
EditorUI.saveStatusTime  = 0
EditorUI.saveIsError     = false
EditorUI.luaEditor       = nil
EditorUI.luaBuffer       = nil
EditorUI.initialized     = false

-- Positions of the currently-loaded function body within the raw file (1-based, inclusive)
EditorUI.funcStart       = nil
EditorUI.funcEnd         = nil
EditorUI.funcIndent      = nil  -- common leading whitespace stripped on load, restored on save

-- Cached raw entry text for the currently selected entry (invalidated on selection change / save)
EditorUI.cachedEntryText    = nil
EditorUI.cachedEntryKey     = nil  -- "section|key|entry" string used as cache key

local sectionOrder = {
    "AbilitySets", "ItemSets", "Rotations", "RotationOrder",
    "ModeChecks", "Cures", "DefaultConfig", "Themes", "HelperFunctions",
}

local sectionLabels = {
    AbilitySets     = "Ability Sets",
    ItemSets        = "Item Sets",
    Rotations       = "Rotations",
    RotationOrder   = "Rotation Order",
    ModeChecks      = "Mode Checks",
    Cures           = "Cures",
    DefaultConfig   = "Settings",
    Themes          = "Themes",
    HelperFunctions = "Helper Functions",
}

local rawFileSections = {
    ModeChecks      = true,
    Cures           = true,
    HelperFunctions = true,
}

local splitSections = {
    Rotations     = true,
    RotationOrder = true,
}

local tableOnlySections = {
    DefaultConfig = true,
    Themes        = true,
}

local arrayStringSections = {
    AbilitySets = true,
    ItemSets    = true,
}

local entryFuncFields    = { "cond", "active_cond", "load_cond", "name_func", "custom_func", "pre_activate", "post_activate" }
local rotOrderFuncFields = { "cond", "load_cond", "targetId" }

local typeOptions = { "AA", "Ability", "ClickyItem", "CustomFunc", "Disc", "Item", "Song", "Spell" }

-- ============================================================
-- Source extraction helpers
-- ============================================================

-- ── Lua-aware scanner ────────────────────────────────────────────────────────
-- advance(content, pos) returns the position AFTER whatever lexical item starts
-- at pos (string literal, long string, line comment, long comment, or single char).
local function advance(content, pos)
    local ch  = content:sub(pos, pos)
    local len = #content
    -- line comment
    if ch == "-" and content:sub(pos, pos + 1) == "--" then
        if content:sub(pos, pos + 3) == "--[[" then
            local e = content:find("%]%]", pos + 4, false)
            return e and e + 2 or len + 1
        end
        local nl = content:find("\n", pos + 2, true)
        return nl and nl + 1 or len + 1
    end
    -- long string / long comment already handled above for comments;
    -- handle long strings as values: [[ or [=..=[
    if ch == "[" then
        local eq = content:match("^%[(=*)%[", pos)
        if eq then
            local close = content:find("%]" .. eq .. "%]", pos + #eq + 2, true)
            return close and close + #eq + 2 or len + 1
        end
    end
    -- short string
    if ch == '"' or ch == "'" then
        local q = ch
        local i = pos + 1
        while i <= len do
            local sc = content:sub(i, i)
            if sc == "\\" then i = i + 2
            elseif sc == q then return i + 1
            else i = i + 1 end
        end
        return len + 1
    end
    return pos + 1
end

-- atWord: true if keyword kw starts at pos with word boundaries.
local function atWord(content, pos, kw)
    if content:sub(pos, pos + #kw - 1) ~= kw then return false end
    local before = pos > 1 and content:sub(pos - 1, pos - 1) or " "
    local after  = content:sub(pos + #kw, pos + #kw)
    return before:match("[%w_]") == nil and after:match("[%w_]") == nil
end

-- scanTo: walk content from startPos, maintaining braceDepth (only {}) and
-- fnDepth (function/do/then/repeat vs end).  Returns pos of target } when
-- braceDepth == 0 (used to find the matching } for an opening {).
-- startPos is the position AFTER the opening '{' (depth starts at 1).
local function findMatchingBrace(content, openPos)
    local braceDepth = 1
    local fnDepth    = 0
    local pos        = openPos + 1
    local len        = #content
    while pos <= len do
        local ch = content:sub(pos, pos)
        -- skip lexically opaque tokens (strings, comments)
        if (ch == '"' or ch == "'")
           or (ch == "-" and content:sub(pos, pos + 1) == "--")
           or (ch == "[" and content:match("^%[(=*)%[", pos)) then
            pos = advance(content, pos)
        elseif atWord(content, pos, "function") then
            fnDepth = fnDepth + 1
            pos = pos + 8
        elseif atWord(content, pos, "if") then
            fnDepth = fnDepth + 1
            pos = pos + 2
        elseif atWord(content, pos, "repeat") then
            fnDepth = fnDepth + 1
            pos = pos + 6
        elseif atWord(content, pos, "do") then
            fnDepth = fnDepth + 1
            pos = pos + 2
        elseif atWord(content, pos, "end") then
            if fnDepth > 0 then
                fnDepth = fnDepth - 1
            end
            pos = pos + 3
        elseif fnDepth == 0 and ch == "{" then
            braceDepth = braceDepth + 1
            pos = pos + 1
        elseif fnDepth == 0 and ch == "}" then
            braceDepth = braceDepth - 1
            if braceDepth == 0 then return pos end
            pos = pos + 1
        else
            pos = pos + 1
        end
    end
    return nil
end

-- Find matching 'end' for the 'function' keyword at startPos.
-- Returns position of the last char of 'end'.
local function findMatchingEnd(content, startPos)
    local depth = 1
    local pos   = startPos + 8  -- skip past 'function'
    local len   = #content
    while pos <= len do
        local ch = content:sub(pos, pos)
        if (ch == '"' or ch == "'")
           or (ch == "-" and content:sub(pos, pos + 1) == "--")
           or (ch == "[" and content:match("^%[(=*)%[", pos)) then
            pos = advance(content, pos)
        elseif atWord(content, pos, "function") or atWord(content, pos, "if")
            or atWord(content, pos, "do")       or atWord(content, pos, "repeat") then
            depth = depth + 1
            pos   = advance(content, pos)
        elseif atWord(content, pos, "end") then
            depth = depth - 1
            if depth == 0 then return pos + 2 end  -- last char of 'end'
            pos = pos + 3
        else
            pos = pos + 1
        end
    end
    return nil
end

-- Find the Nth top-level { } block in content starting from searchFrom.
-- Skips strings/comments properly using advance().
local function findNthBlock(content, searchFrom, n)
    local pos   = searchFrom
    local count = 0
    local len   = #content
    while pos <= len do
        local ch = content:sub(pos, pos)
        -- skip opaque tokens so we only find real { characters
        if (ch == '"' or ch == "'")
           or (ch == "-" and content:sub(pos, pos + 1) == "--")
           or (ch == "[" and content:match("^%[(=*)%[", pos)) then
            pos = advance(content, pos)
        elseif ch == "{" then
            local closePos = findMatchingBrace(content, pos)
            if not closePos then return nil, nil end
            count = count + 1
            if count == n then return pos, closePos end
            pos = closePos + 1
        else
            pos = pos + 1
        end
    end
    return nil, nil
end

-- Find the byte range of ['RotName'] = { ... } value block in content.
local function findRotationBlock(content, rotName)
    local escaped    = rotName:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
    local pattern    = "%[[\"\']" .. escaped .. "[\"\']%]%s*=%s*{"
    local headerEnd  = content:find(pattern)
    if not headerEnd then return nil, nil end
    local blockStart = content:find("{", headerEnd, true)
    if not blockStart then return nil, nil end
    return blockStart, findMatchingBrace(content, blockStart)
end

-- Extract the Nth entry block from a rotation. Returns text, absStart, absEnd.
local function extractEntryBlock(content, rotName, entryIndex)
    local blockStart, blockEnd = findRotationBlock(content, rotName)
    if not blockStart then return nil, nil, nil end
    local inner      = content:sub(blockStart + 1, blockEnd - 1)
    local relS, relE = findNthBlock(inner, 1, entryIndex)
    if not relS then return nil, nil, nil end
    local absS = blockStart + relS
    local absE = blockStart + relE
    return content:sub(absS, absE), absS, absE
end

-- Extract the Nth RotationOrder entry block.
local function extractRotationOrderEntry(content, entryIndex)
    local headerPos  = content:find("RotationOrder%]?%s*=%s*{")
    if not headerPos then return nil, nil, nil end
    local blockStart = content:find("{", headerPos, true)
    if not blockStart then return nil, nil, nil end
    local relS, relE = findNthBlock(content:sub(blockStart + 1), 1, entryIndex)
    if not relS then return nil, nil, nil end
    local absS = blockStart + relS
    local absE = blockStart + relE
    return content:sub(absS, absE), absS, absE
end

-- Find 'fieldName = function' within entryText and extract the function body.
-- Returns funcText, relStart, relEnd (positions within entryText, 1-based).
local function extractFunctionField(entryText, fieldName)
    local escaped  = fieldName:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
    -- Require a non-word character before the field name to avoid matching
    -- substrings (e.g. "cond" must not match inside "load_cond").
    local pattern  = "[^%w_]" .. escaped .. "%s*=%s*function"
    local patStart = entryText:find(pattern)
    if not patStart then
        -- Allow match at the very start of the string (no preceding char)
        patStart = entryText:find("^%s*" .. escaped .. "%s*=%s*function")
    end
    if not patStart then return nil, nil, nil end
    local funcStart = entryText:find("function", patStart, true)
    if not funcStart then return nil, nil, nil end
    local funcEnd = findMatchingEnd(entryText, funcStart)
    if not funcEnd then return nil, nil, nil end
    return entryText:sub(funcStart, funcEnd), funcStart, funcEnd
end

-- ============================================================
-- EditorUI core
-- ============================================================

function EditorUI:Init()
    self.luaEditor              = Zep.Editor.new('##ClassConfigEditorZep')
    self.luaBuffer              = self.luaEditor:CreateBuffer("[ClassConfig]")
    self.luaBuffer.syntax       = 'lua'
    self.luaEditor.activeBuffer = self.luaBuffer
    self:ReloadConfig()
    self.initialized = true
end

function EditorUI:ReloadConfig()
    local classModule = Modules:GetModule("Class")
    local liveConfig  = classModule and rawget(classModule, "ClassConfig")
    if liveConfig then
        self.classConfig = liveConfig
    else
        self.classConfig = ClassLoader.load(Globals.CurLoadedClass)
    end
    self.configFilePath = ClassLoader.getClassConfigFileName(Globals.CurLoadedClass)
    self.selectedKey    = nil
    self.selectedEntry  = nil
    self.selectedFunc   = nil
    self.funcStart      = nil
    self.funcEnd        = nil
    self:ClearEditor("Select an entry to edit")
end

function EditorUI:ReadRawFile()
    if not self.configFilePath then return nil end
    local f = io.open(self.configFilePath, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

function EditorUI:ClearEditor(msg)
    if not self.luaBuffer then return end
    self.luaBuffer:SetText(msg or "")
    self.luaBuffer:ClearFlags(Zep.BufferFlags.Dirty)
    self.funcStart    = nil
    self.funcEnd      = nil
    self.funcIndent   = nil
    self.selectedFunc = nil
end

-- Strip common leading whitespace from lines 2+ of text (line 1 is 'function(...)').
-- Returns dedented text and the indent string removed.
local function dedent(text)
    local first, rest = text:match("^([^\n]*\n?)(.*)")
    if not rest or rest == "" then return text, "" end
    local indent = nil
    for line in (rest .. "\n"):gmatch("([^\n]*)\n") do
        if line:match("%S") then
            local ws = line:match("^(%s*)")
            if indent == nil or #ws < #indent then indent = ws end
        end
    end
    indent = indent or ""
    if #indent == 0 then return text, "" end
    local lines = {}
    for line in (rest .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line:match("%S") and line:sub(#indent + 1) or line:match("^%s*$") and "" or line
    end
    if lines[#lines] == "" then lines[#lines] = nil end
    return first .. table.concat(lines, "\n"), indent
end

-- Re-add indent to lines 2+ of text.
local function reindent(text, indent)
    if not indent or #indent == 0 then return text end
    local first, rest = text:match("^([^\n]*\n?)(.*)")
    if not rest or rest == "" then return text end
    local lines = {}
    for line in (rest .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line:match("%S") and (indent .. line) or line
    end
    if lines[#lines] == "" then lines[#lines] = nil end
    return first .. table.concat(lines, "\n")
end

-- Load a specific function field from the selected entry into the Zep editor.
function EditorUI:LoadFuncField(fieldName)
    local content = self:ReadRawFile()
    if not content then self:ClearEditor("-- Could not read file"); return end

    local entryText, entryAbsStart
    if self.selectedSection == "RotationOrder" then
        entryText, entryAbsStart = extractRotationOrderEntry(content, self.selectedEntry)
    else
        entryText, entryAbsStart = extractEntryBlock(content, self.selectedKey, self.selectedEntry)
    end

    if not entryText then
        self:ClearEditor("-- Could not locate entry in file")
        self:SetStatus("ERROR: Entry not found in file", true)
        return
    end

    local funcText, relS, relE = extractFunctionField(entryText, fieldName)
    if not funcText then
        self:ClearEditor("-- Could not locate " .. fieldName .. " in entry")
        self:SetStatus("ERROR: " .. fieldName .. " not found in entry", true)
        return
    end

    self.selectedFunc = fieldName
    self.funcStart    = entryAbsStart + relS - 1
    self.funcEnd      = entryAbsStart + relE - 1

    local dedented, indent = dedent(funcText)
    self.funcIndent = indent
    self.luaBuffer:SetText(dedented)
    self.luaBuffer:ClearFlags(Zep.BufferFlags.Dirty)
end

-- Correct argument lists for each function field, based on how they are called in rotation.lua / class.lua
local funcFieldArgs = {
    -- Rotation entry fields
    cond          = "self, condArg, condTarg",
    active_cond   = "self, condArg",
    load_cond     = "self",
    name_func     = "self",
    custom_func   = "self, targetId",
    post_activate = "self, condArg, ret",
    pre_activate  = "self, condArg",
    -- RotationOrder fields
    targetId      = "self",
}

function EditorUI:AddFuncField(fieldName)
    local content = self:ReadRawFile()
    if not content then self:SetStatus("ERROR: Could not read file", true); return end

    local entryText, absStart, absEnd
    if self.selectedSection == "RotationOrder" then
        entryText, absStart, absEnd = extractRotationOrderEntry(content, self.selectedEntry)
    else
        entryText, absStart, absEnd = extractEntryBlock(content, self.selectedKey, self.selectedEntry)
    end

    if not entryText then
        self:SetStatus("ERROR: Entry not found in file", true)
        return
    end

    local args     = funcFieldArgs[fieldName] or ""
    -- Find the closing } of the entry and insert before it
    local insertPos = absEnd  -- absEnd points at the closing '}'
    local stub      = string.format(",\n        %s = function(%s)\n        end", fieldName, args)
    local newContent = content:sub(1, insertPos - 1) .. stub .. content:sub(insertPos)

    local fw = io.open(self.configFilePath, "w")
    if not fw then self:SetStatus("ERROR: Could not write file", true); return end
    fw:write(newContent)
    fw:close()
    self.cachedEntryKey  = nil
    self.cachedEntryText = nil  -- invalidate so button state refreshes

    -- Reload config so the live entry reflects the new function field,
    -- but preserve selection so LoadFuncField can find the entry
    local savedSection = self.selectedSection
    local savedKey     = self.selectedKey
    local savedEntry   = self.selectedEntry
    self:ReloadConfig()
    self.selectedSection = savedSection
    self.selectedKey     = savedKey
    self.selectedEntry   = savedEntry
    self:SetStatus(fieldName .. " added")

    -- Now load the newly added stub into the editor
    self:LoadFuncField(fieldName)
end

function EditorUI:RemoveFuncField(fieldName)
    local content = self:ReadRawFile()
    if not content then self:SetStatus("ERROR: Could not read file", true); return end

    local entryText, absStart, absEnd
    if self.selectedSection == "RotationOrder" then
        entryText, absStart, absEnd = extractRotationOrderEntry(content, self.selectedEntry)
    else
        entryText, absStart, absEnd = extractEntryBlock(content, self.selectedKey, self.selectedEntry)
    end

    if not entryText then self:SetStatus("ERROR: Entry not found in file", true); return end

    local _, relFuncS, relFuncE = extractFunctionField(entryText, fieldName)
    if not relFuncS then self:SetStatus("ERROR: " .. fieldName .. " not found in entry", true); return end

    -- Find the start of the full assignment "fieldName = function" in entryText.
    -- Walk backwards from relFuncS to find "fieldName%s*=%s*" preceding "function".
    local escaped = fieldName:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
    local assignPat = escaped .. "%s*=%s*$"
    -- Search for "fieldName = " ending just before relFuncS in entryText
    local preFunc = entryText:sub(1, relFuncS - 1)
    local assignS = preFunc:find(escaped .. "%s*=%s*$")
    -- Also walk back over any leading whitespace/newline to the start of the line
    if assignS then
        local lineStart = preFunc:find("[^\n]*$", 1)  -- last newline before assignS
        -- find the actual line start (after the last \n before assignS)
        local ls = preFunc:sub(1, assignS - 1):find("\n[%s]*$")
        if ls then
            assignS = ls + 1  -- position after the \n
        end
    end
    if not assignS then self:SetStatus("ERROR: could not find assignment for " .. fieldName, true); return end

    -- Full removal range in entryText: from assignS to relFuncE
    local removeS = absStart + assignS - 1
    local removeE = absStart + relFuncE - 1

    -- After 'end': eat optional whitespace then exactly one comma, then whitespace+newline
    local rest = content:sub(removeE + 1)
    local trailingMatch = rest:match("^(%s*,[ \t]*\n?)")  -- comma after end
    if trailingMatch then
        removeE = removeE + #trailingMatch
    else
        -- No trailing comma — eat the leading comma instead (field was last in block)
        local before = content:sub(1, removeS - 1)
        local leadMatch = before:match("(,%s*)$")
        if leadMatch then removeS = removeS - #leadMatch end
    end

    local newContent = content:sub(1, removeS - 1) .. content:sub(removeE + 1)

    local fw = io.open(self.configFilePath, "w")
    if not fw then self:SetStatus("ERROR: Could not write file", true); return end
    fw:write(newContent)
    fw:close()
    self.cachedEntryKey  = nil
    self.cachedEntryText = nil

    if self.selectedFunc == fieldName then
        self:ClearEditor("Select a function field above to edit")
    end
    self:SetStatus(fieldName .. " removed")
end

-- Load full raw file for whole-file-editable sections (ModeChecks, Cures, etc.)
function EditorUI:LoadFullFile()
    local content = self:ReadRawFile()
    self.luaBuffer:SetText(content or "-- Could not read file")
    self.luaBuffer:ClearFlags(Zep.BufferFlags.Dirty)
    self.funcStart = 1
    self.funcEnd   = content and #content or nil
    self.selectedFunc = "_file_"
end

function EditorUI:SaveEditorContent()
    if not self.configFilePath or not self.luaBuffer then return end
    if not self.funcStart or not self.funcEnd then
        self:SetStatus("ERROR: No function selected to save", true)
        return
    end

    local newText = reindent(self.luaBuffer:GetText(), self.funcIndent)
    local content = self:ReadRawFile()
    if not content then self:SetStatus("ERROR: Could not read file", true); return end

    local newContent = content:sub(1, self.funcStart - 1) .. newText .. content:sub(self.funcEnd + 1)

    local fw = io.open(self.configFilePath, "w")
    if not fw then self:SetStatus("ERROR: Could not write file", true); return end
    fw:write(newContent)
    fw:close()

    self.luaBuffer:ClearFlags(Zep.BufferFlags.Dirty)
    self.funcEnd         = self.funcStart + #newText - 1
    self.cachedEntryKey  = nil
    self.cachedEntryText = nil
    self:SetStatus("Saved! (Reload config to apply)")
end

function EditorUI:SetStatus(msg, isError)
    self.saveStatus     = (isError and (Icons.MD_ERROR .. " ") or (Icons.MD_CHECK .. " ")) .. msg
    self.saveStatusTime = Globals.GetTimeSeconds()
    self.saveIsError    = isError or false
end

function EditorUI:GetFilteredKeys(section)
    local keys   = {}
    local filter = self.filterText:lower()
    for k in pairs(section) do
        if type(k) == "string" and (filter == "" or k:lower():find(filter, 1, true)) then
            table.insert(keys, k)
        end
    end
    table.sort(keys)
    return keys
end

-- ============================================================
-- Entry form rendering
-- ============================================================

-- Returns the index of val in list, or 1 if not found.
local function comboIndex(list, val)
    if val then
        local vl = val:lower()
        for i, v in ipairs(list) do
            if v:lower() == vl then return i end
        end
    end
    return 1
end

-- Render the form for a single rotation entry (non-function fields as widgets,
-- function fields as buttons that load into the Zep editor).
function EditorUI:RenderEntryForm(entry, funcFields)
    if not entry then return end

    local abilityKeys = {}
    for k in pairs(self.classConfig.AbilitySets or {}) do table.insert(abilityKeys, k) end
    for k in pairs(self.classConfig.ItemSets    or {}) do table.insert(abilityKeys, k) end
    local abilitySet = {}
    for _, k in ipairs(abilityKeys) do abilitySet[k] = true end

    ImGui.Separator()

    -- name
    local nm = entry.name or ""
    ImGui.Text("name:")
    ImGui.SameLine()
    if abilitySet[nm] then
        -- hyperlink style button
        ImGui.PushStyleColor(ImGuiCol.Text,        ImVec4(0.4, 0.7, 1.0, 1.0))
        ImGui.PushStyleColor(ImGuiCol.Button,       ImVec4(0, 0, 0, 0))
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered,ImVec4(0.1, 0.1, 0.2, 0.5))
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, ImVec4(0.2, 0.2, 0.4, 0.5))
        if ImGui.SmallButton(nm .. "##nm_link") then
            self.selectedSection = "AbilitySets"
            -- if it's an ItemSet key instead
            if not (self.classConfig.AbilitySets or {})[nm] then
                self.selectedSection = "ItemSets"
            end
            self.selectedKey   = nm
            self.selectedEntry = nil
            self:ClearEditor("Select an entry to edit")
        end
        ImGui.PopStyleColor(4)
        if ImGui.IsItemHovered() then ImGui.SetTooltip("Go to ability set: " .. nm) end
    else
        Ui.RenderText(nm)
    end

    -- type combo
    if entry.type ~= nil then
        ImGui.Text("type:")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(120)
        local curIdx   = comboIndex(typeOptions, entry.type)
        local newIdx, changed = ImGui.Combo("##entry_type", curIdx, typeOptions, #typeOptions)
        if changed == true and newIdx ~= curIdx then
            local newType = typeOptions[newIdx]
            if newType then
                -- Write only the type field in the file, don't reload config
                local content = self:ReadRawFile()
                if content then
                    local entryText, absS, absE
                    if self.selectedSection == "RotationOrder" then
                        entryText, absS, absE = extractRotationOrderEntry(content, self.selectedEntry)
                    else
                        entryText, absS, absE = extractEntryBlock(content, self.selectedKey, self.selectedEntry)
                    end
                    if entryText then
                        local newEntry = entryText:gsub('type%s*=%s*"[^"]+"', 'type = "' .. newType .. '"', 1)
                        if newEntry == entryText then
                            newEntry = entryText:gsub("type%s*=%s*'[^']+'", "type = '" .. newType .. "'", 1)
                        end
                        local newContent = content:sub(1, absS - 1) .. newEntry .. content:sub(absE + 1)
                        local fw = io.open(self.configFilePath, "w")
                        if fw then fw:write(newContent); fw:close(); self:SetStatus("type updated") end
                        -- Update live entry so combo stays correct without full reload
                        entry.type = newType
                    end
                end
            end
        end
    end

    -- tooltip (plain string if present)
    if entry.tooltip and type(entry.tooltip) == "string" then
        ImGui.Text("tooltip:")
        ImGui.SameLine()
        Ui.RenderText(entry.tooltip)
    end

    ImGui.Separator()
    ImGui.Text("Functions:")

    -- Function field buttons
    -- Use raw file as the source of truth for which fields exist — the live classConfig
    -- can lag behind after edits (the class module only reloads on /reload).
    local cacheKey = (self.selectedSection or "") .. "|" .. (self.selectedKey or "") .. "|" .. tostring(self.selectedEntry)
    if self.cachedEntryKey ~= cacheKey then
        self.cachedEntryKey  = cacheKey
        local rawContent = self:ReadRawFile()
        if rawContent then
            if self.selectedSection == "RotationOrder" then
                self.cachedEntryText = (extractRotationOrderEntry(rawContent, self.selectedEntry))
            else
                self.cachedEntryText = (extractEntryBlock(rawContent, self.selectedKey, self.selectedEntry))
            end
        else
            self.cachedEntryText = nil
        end
    end
    local entryText = self.cachedEntryText
    for _, field in ipairs(funcFields) do
        local hasFunc = entryText ~= nil and extractFunctionField(entryText, field) ~= nil
        local isActive = self.selectedFunc == field
        if isActive then
            ImGui.PushStyleColor(ImGuiCol.Button, ImVec4(0.2, 0.5, 0.2, 1.0))
        elseif not hasFunc then
            ImGui.PushStyleColor(ImGuiCol.Button,        ImVec4(0.15, 0.15, 0.15, 1.0))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, ImVec4(0.25, 0.35, 0.25, 1.0))
            ImGui.PushStyleColor(ImGuiCol.Text,          ImVec4(0.5,  0.5,  0.5,  1.0))
        end
        if ImGui.Button((hasFunc and "" or Icons.MD_ADD_CIRCLE_OUTLINE .. " ") .. field .. "##fn_" .. field) then
            if hasFunc then
                self:LoadFuncField(field)
            else
                self:AddFuncField(field)
            end
        end
        if isActive then
            ImGui.PopStyleColor()
        elseif not hasFunc then
            ImGui.PopStyleColor(3)
        end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip(hasFunc and ("Edit " .. field) or ("Add " .. field .. " function"))
        end
        if hasFunc then
            ImGui.SameLine(0, 2)
            ImGui.PushStyleColor(ImGuiCol.Button,        ImVec4(0.4, 0.1, 0.1, 1.0))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, ImVec4(0.6, 0.1, 0.1, 1.0))
            if ImGui.SmallButton(Icons.MD_CLOSE .. "##rm_" .. field) then
                self:RemoveFuncField(field)
            end
            ImGui.PopStyleColor(2)
            if ImGui.IsItemHovered() then ImGui.SetTooltip("Remove " .. field) end
        end
        ImGui.SameLine()
    end
    ImGui.NewLine()
end

-- ============================================================
-- Section renderers
-- ============================================================

function EditorUI:RenderSectionList()
    for _, sec in ipairs(sectionOrder) do
        local data = self.classConfig and self.classConfig[sec]
        if data ~= nil then
            if ImGui.Selectable(sectionLabels[sec] .. "##sec_" .. sec, self.selectedSection == sec) then
                if self.selectedSection ~= sec then
                    self.selectedSection = sec
                    self.selectedKey     = nil
                    self.selectedEntry   = nil
                    self:ClearEditor("Select an entry to edit")
                end
            end
        end
    end
end

function EditorUI:RenderKeyList()
    local section = self.classConfig and self.classConfig[self.selectedSection]
    if not section then Ui.RenderText("(empty)"); return end
    for _, k in ipairs(self:GetFilteredKeys(section)) do
        local v    = section[k]
        local icon = type(v) == "function" and Icons.MD_CODE
            or (type(v) == "table" and Icons.MD_LIST)
            or Icons.MD_SETTINGS
        if ImGui.Selectable(icon .. " " .. k .. "##key_" .. k, self.selectedKey == k) then
            self.selectedKey   = k
            self.selectedEntry = nil
            self:ClearEditor("Select an entry to edit")
        end
    end
end

function EditorUI:RenderEditorToolbar(canSave)
    if ImGui.SmallButton(Icons.MD_SAVE .. " Save") then
        if canSave then self:SaveEditorContent() end
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip(canSave and "Save to config file" or "Nothing selected to save")
    end
    ImGui.SameLine()
    if ImGui.SmallButton(Icons.MD_UNDO .. " Discard") then
        if self.selectedFunc and self.selectedFunc ~= "_file_" then
            self:LoadFuncField(self.selectedFunc)
        elseif rawFileSections[self.selectedSection] then
            self:LoadFullFile()
        else
            self:ClearEditor("Select an entry to edit")
        end
    end
    if ImGui.IsItemHovered() then ImGui.SetTooltip("Discard unsaved changes") end
    ImGui.SameLine()
    if ImGui.SmallButton(Icons.MD_REFRESH .. " Reload") then
        self:ReloadConfig()
    end
    if ImGui.IsItemHovered() then ImGui.SetTooltip("Reload config from disk") end

    if self.saveStatus and (Globals.GetTimeSeconds() - self.saveStatusTime) < 5 then
        ImGui.SameLine()
        ImGui.PushStyleColor(ImGuiCol.Text,
            self.saveIsError and ImVec4(1, 0.3, 0.3, 1) or ImVec4(0.3, 1, 0.3, 1))
        Ui.RenderText(self.saveStatus)
        ImGui.PopStyleColor()
    end
end

function EditorUI:RenderDefaultConfig()
    local section = self.classConfig and self.classConfig.DefaultConfig
    if not section then Ui.RenderText("No DefaultConfig."); return end
    local filter   = self.filterText:lower()
    local catMap, catOrder = {}, {}
    for k, def in pairs(section) do
        local cat = def.Category or "Uncategorized"
        if not catMap[cat] then catMap[cat] = {}; table.insert(catOrder, cat) end
        if filter == "" or k:lower():find(filter, 1, true)
            or (def.DisplayName or ""):lower():find(filter, 1, true) then
            table.insert(catMap[cat], k)
        end
    end
    table.sort(catOrder)
    for _, cat in ipairs(catOrder) do
        local keys = catMap[cat]
        if #keys > 0 and ImGui.CollapsingHeader(cat) then
            table.sort(keys, function(a, b)
                local ia, ib = section[a].Index or 0, section[b].Index or 0
                return ia < ib or (ia == ib and a < b)
            end)
            if ImGui.BeginTable("##dc_" .. cat, 4,
                bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.SizingFixedFit)) then
                ImGui.TableSetupColumn("Key",     ImGuiTableColumnFlags.WidthFixed, 150)
                ImGui.TableSetupColumn("Display", ImGuiTableColumnFlags.WidthFixed, 150)
                ImGui.TableSetupColumn("Type",    ImGuiTableColumnFlags.WidthFixed,  70)
                ImGui.TableSetupColumn("Default", ImGuiTableColumnFlags.WidthStretch)
                ImGui.TableHeadersRow()
                for _, k in ipairs(keys) do
                    local def = section[k]
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0); Ui.RenderText(k)
                    ImGui.TableSetColumnIndex(1); Ui.RenderText(def.DisplayName or "")
                    ImGui.TableSetColumnIndex(2); Ui.RenderText(def.Type or "Default")
                    ImGui.TableSetColumnIndex(3)
                    local dv = def.Default
                    Ui.RenderText(type(dv) == "function" and "[fn]" or tostring(dv or ""))
                    if def.Tooltip and ImGui.IsItemHovered() then
                        local tip = type(def.Tooltip) == "function" and def.Tooltip() or def.Tooltip
                        ImGui.SetTooltip(tip)
                    end
                end
                ImGui.EndTable()
            end
        end
    end
end

-- Render the rotation entry list and the entry form+editor below
function EditorUI:RenderSplitPane(availW, availH)
    local rotData    = self.selectedSection == "Rotations"
        and (self.classConfig and self.classConfig.Rotations)
        or  (self.classConfig and self.classConfig.RotationOrder)

    if not rotData then Ui.RenderText("No data."); return end

    local filter     = self.filterText:lower()
    local funcFields = self.selectedSection == "RotationOrder" and rotOrderFuncFields or entryFuncFields

    -- ── left sub-panel: entry tree ──────────────────────────────
    local listW  = 240
    local rightW = availW - listW - 8

    ImGui.BeginChild("##cce_entrylist", ImVec2(listW, availH), ImGuiChildFlags.Borders)
    do
        if self.selectedSection == "Rotations" then
            local keys = {}
            for k in pairs(rotData) do table.insert(keys, k) end
            table.sort(keys)
            for _, rotName in ipairs(keys) do
                if filter == "" or rotName:lower():find(filter, 1, true) then
                    local entries = rotData[rotName]
                    if ImGui.CollapsingHeader(string.format("%s (%d)##rh_%s", rotName, #entries, rotName)) then
                        for j, entry in ipairs(entries) do
                            local nm = entry.name
                                or (type(entry.name_func) == "function" and "[dynamic]")
                                or (entry.type == "CustomFunc" and "[custom_func]")
                                or "?"
                            local hasFn = false
                            for _, f in ipairs(entryFuncFields) do
                                if entry[f] and type(entry[f]) == "function" then hasFn = true; break end
                            end
                            local icon     = hasFn and (Icons.MD_CODE .. " ") or "  "
                            local sel      = self.selectedKey == rotName and self.selectedEntry == j
                            if ImGui.Selectable(icon .. nm .. "##re_" .. rotName .. j, sel) then
                                if self.selectedKey ~= rotName or self.selectedEntry ~= j then
                                    self.selectedKey   = rotName
                                    self.selectedEntry = j
                                    self.selectedFunc  = nil
                                    self:ClearEditor("Select a function field above to edit")
                                end
                            end
                        end
                    end
                end
            end
        else
            -- RotationOrder: flat list
            for i, rot in ipairs(rotData) do
                local hasFn = false
                for _, f in ipairs(rotOrderFuncFields) do
                    if rot[f] then hasFn = true; break end
                end
                local icon = hasFn and (Icons.MD_CODE .. " ") or "  "
                local sel  = self.selectedEntry == i
                if ImGui.Selectable(icon .. (rot.name or "(unnamed)") .. "##ro_" .. i, sel) then
                    if self.selectedEntry ~= i then
                        self.selectedEntry = i
                        self.selectedKey   = nil
                        self.selectedFunc  = nil
                        self:ClearEditor("Select a function field above to edit")
                    end
                end
            end
        end
    end
    ImGui.EndChild()
    ImGui.SameLine()

    -- ── right sub-panel: form + editor ─────────────────────────
    ImGui.BeginChild("##cce_rightpane", ImVec2(rightW, availH), ImGuiChildFlags.Borders)
    do
        -- Find the live entry object for the form
        local entry = nil
        if self.selectedSection == "Rotations" and self.selectedKey and self.selectedEntry then
            local rot = rotData[self.selectedKey]
            entry = rot and rot[self.selectedEntry]
        elseif self.selectedSection == "RotationOrder" and self.selectedEntry then
            entry = rotData[self.selectedEntry]
        end

        if entry then
            -- Form (non-function fields + function selector buttons)
            local formH = 110
            ImGui.BeginChild("##cce_form", ImVec2(rightW - 8, formH), ImGuiChildFlags.None)
            self:RenderEntryForm(entry, funcFields)
            ImGui.EndChild()

            ImGui.Separator()

            -- Editor toolbar + Zep
            local editorH  = availH - formH - 50
            local canSave  = self.funcStart ~= nil
            self:RenderEditorToolbar(canSave)
            ImGui.Separator()
            if self.luaEditor then
                self.luaEditor:Render(ImVec2(rightW - 8, math.max(60, editorH)))
            end
        else
            Ui.RenderText("Select an entry from the list.")
        end
    end
    ImGui.EndChild()
end

function EditorUI:RenderEditorPane(availW, availH)
    if tableOnlySections[self.selectedSection] then
        if self.selectedSection == "DefaultConfig" then self:RenderDefaultConfig() end
        return
    end

    if splitSections[self.selectedSection] then
        self:RenderSplitPane(availW, availH)
        return
    end

    if rawFileSections[self.selectedSection] then
        -- Load full file on first visit to this section
        if not self.funcStart then self:LoadFullFile() end
        self:RenderEditorToolbar(true)
        ImGui.Separator()
        if self.luaEditor then
            self.luaEditor:Render(ImVec2(availW - 4, math.max(80, availH - 36)))
        end
        return
    end

    -- AbilitySets / ItemSets: key list + array editor
    if arrayStringSections[self.selectedSection] then
        if not self.selectedKey then
            Ui.RenderText("Select a key from the list.")
            return
        end
        -- Load array text on key selection (handled in RenderKeyList via ClearEditor)
        -- If funcStart is nil, load it now
        if not self.funcStart then
            local content = self:ReadRawFile()
            if content then
                local escaped = self.selectedKey:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
                local pattern = "%[[\"\']" .. escaped .. "[\"\']%]%s*=%s*{"
                local pos     = content:find(pattern)
                if pos then
                    local s = content:find("{", pos, true)
                    local e = s and findMatchingBrace(content, s)
                    if s and e then
                        self.funcStart = s
                        self.funcEnd   = e
                        self.luaBuffer:SetText(content:sub(s, e))
                        self.luaBuffer:ClearFlags(Zep.BufferFlags.Dirty)
                    end
                end
            end
        end
        local canSave = self.funcStart ~= nil
        self:RenderEditorToolbar(canSave)
        ImGui.Separator()
        if self.luaEditor then
            self.luaEditor:Render(ImVec2(availW - 4, math.max(80, availH - 36)))
        end
    end
end

-- ============================================================
-- Main render
-- ============================================================

function EditorUI:Render()
    if not self.initialized then self:Init() end

    local availW, availH = ImGui.GetContentRegionAvail()

    Ui.RenderText(Icons.MD_INSERT_DRIVE_FILE .. "  " .. (self.configFilePath or "No config loaded"))
    ImGui.SameLine()
    ImGui.SetNextItemWidth(200)
    self.filterText = ImGui.InputText("##cceFilter", self.filterText or "")
    if ImGui.IsItemHovered() then ImGui.SetTooltip("Filter keys") end

    ImGui.Separator()

    local contentH = availH - 32
    local sectionW = 130
    local showKeys = arrayStringSections[self.selectedSection]
    local keyW     = showKeys and 180 or 0
    local mainW    = availW - sectionW - keyW - (showKeys and 12 or 8)

    ImGui.BeginChild("##cce_sections", ImVec2(sectionW, contentH), ImGuiChildFlags.Borders)
    self:RenderSectionList()
    ImGui.EndChild()
    ImGui.SameLine()

    if showKeys then
        ImGui.BeginChild("##cce_keys", ImVec2(keyW, contentH), ImGuiChildFlags.Borders)
        self:RenderKeyList()
        ImGui.EndChild()
        ImGui.SameLine()
    end

    ImGui.BeginChild("##cce_main", ImVec2(mainW, contentH), ImGuiChildFlags.Borders)
    self:RenderEditorPane(mainW, contentH)
    ImGui.EndChild()
end

return EditorUI
