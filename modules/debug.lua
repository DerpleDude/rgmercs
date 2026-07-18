local mq            = require('mq')
local Icons         = require('mq.ICONS')
local Base          = require("modules.base")
local Config        = require('utils.config')
local Core          = require("utils.core")
local Globals       = require("utils.globals")
local Logger        = require("utils.logger")
local Signatures    = require('utils.signatures')
local Ui            = require("utils.ui")
local Zep           = require('Zep')
local CHANNEL_COLOR = IM_COL32(215, 154, 66)

local Module        = { _version = '0.1a', _name = "Debug", _author = 'Derple', }
Module.__index      = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                       = {}
Module.CommandHandlers           = {}
Module.DefaultConfig             = {
    ['script'] = {
        Default = "",
        DisplayName = "Script",
        Category = "Custom",
        Type = "Custom",
    },
    ['ShowTimestamps'] = {
        Default = true,
        DisplayName = "Show Time Stamps",
        Category = "Custom",
        Type = "Custom",
    },
    ['EnableAutoCompletion'] = {
        Default = true,
        DisplayName = "Enable Auto Completion",
        Category = "Custom",
        Type = "Custom",
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
}
Module.luaConsole                = Zep.Console.new("##RGDebugConsole")
Module.luaConsole.maxBufferLines = 1000
Module.luaConsole.autoScroll     = true

Module.luaEditor                 = Zep.Editor.new('##RGDebugLuaEditor')
Module.luaBuffer                 = Module.luaEditor:CreateBuffer("[DebugConsole]")
Module.luaBuffer.syntax          = 'lua'
Module.execRequested             = false
Module.execCoroutine             = nil
Module.status                    = "Idle..."
Module.autoRun                   = false
Module.completionItems           = {}
Module.completionIdx             = 1
Module.completionOpen            = false
Module.completionSuppressed      = false
Module.completionLastToken       = ''
Module.completionFrameAge        = 0
Module.editorScreenPos           = ImVec2(0, 0)
Module.hintBarScreenPos          = ImVec2(0, 0)

function Module:New()
    return Base.New(self)
end

function Module:LoadSettings()
    Base.LoadSettings(self)

    self.luaBuffer:SetText(Config:GetSetting('script') or "")
    Signatures.Load()
end

function Module:LogTimestamp()
    if Config:GetSetting('ShowTimestamps') then
        local now = os.date('%H:%M:%S')
        self.luaConsole:AppendTextUnformatted(string.format('\aw[\at%s\aw] ', now))
    end
end

function Module:LogToConsole(...)
    self:LogTimestamp()
    self.luaConsole:AppendText(CHANNEL_COLOR, ...)
end

function Module:Exec(scriptText)
    local locals        = setmetatable({}, { __index = _G, })
    locals.mq           = setmetatable({}, { __index = mq, })
    locals.Config       = setmetatable({}, { __index = Config, })
    locals.Core         = setmetatable({}, { __index = Core, })
    locals.Globals      = setmetatable({}, { __index = Globals, })
    locals.ImGui        = setmetatable({}, { __index = ImGui, })
    locals.Targeting    = setmetatable({}, { __index = require('utils.targeting'), })
    locals.Casting      = setmetatable({}, { __index = require('utils.casting'), })
    locals.Combat       = setmetatable({}, { __index = require('utils.combat'), })
    locals.Comms        = setmetatable({}, { __index = require('utils.comms'), })
    locals.ItemManager  = setmetatable({}, { __index = require('utils.item_manager'), })
    locals.Logger       = setmetatable({}, { __index = require('utils.logger'), })
    locals.Math         = setmetatable({}, { __index = require('utils.math'), })
    locals.Modules      = setmetatable({}, { __index = require('utils.modules'), })
    locals.Movement     = setmetatable({}, { __index = require('utils.movement'), })
    locals.Ui           = setmetatable({}, { __index = require('utils.ui'), })
    locals.DefSpawnList = setmetatable({}, { __index = require('modules.spawns').DefSpawnList, })
    locals.Rotation     = setmetatable({}, { __index = require('utils.rotation'), })
    locals.Strings      = setmetatable({}, { __index = require('utils.strings'), })
    locals.Tables       = setmetatable({}, { __index = require('utils.tables'), })
    locals.ConfigShare  = setmetatable({}, { __index = require('utils.rg_config_share'), })
    locals.Set          = setmetatable({}, { __index = require('mq.set'), })
    locals.DanNet       = setmetatable({}, { __index = require('lib.dannet.helpers'), })

    locals.print        = function(...)
        self:LogTimestamp()
        self.luaConsole:PushStyleColor(Zep.ConsoleCol.Text, CHANNEL_COLOR)
        for _, arg in ipairs({ ..., }) do
            self.luaConsole:AppendTextUnformatted(tostring(arg))
        end
        self.luaConsole:AppendTextUnformatted('\n')
        self.luaConsole:PopStyleColor()
    end

    locals.printf       = function(text, ...)
        self:LogTimestamp()
        self.luaConsole:AppendText(CHANNEL_COLOR, text, ...)
    end

    locals.mq.exit      = function()
        self.execCoroutine = nil
    end

    local func, err     = load(scriptText, "LuaConsoleScript", "t", locals)
    if not func then
        return false, err
    end

    local success, msg = pcall(func)
    return success, msg or ""
end

function Module:ExecCoroutine()
    local scriptText = self.luaBuffer:GetText()

    return coroutine.create(function()
        local success, msg = self:Exec(scriptText)
        if not success then
            self:LogToConsole("\ar" .. msg)
        end
    end)
end

function Module:RenderConsole()
    local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
    self.luaConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
end

function Module:RenderEditor()
    local yPos = ImGui.GetCursorPosY()
    local footerHeight = 35
    local editHeight = (ImGui.GetWindowHeight() * .5) - yPos - footerHeight

    self.editorScreenPos = ImGui.GetCursorScreenPosVec()
    self.luaEditor:Render(ImVec2(ImGui.GetWindowWidth() * 0.98, editHeight))
end

local function RenderTooltip(text)
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip(text)
    end
end

local HINT_ACTIVE = ImVec4(0.5, 1.0, 0.5, 1.0)
local HINT_DIM    = ImVec4(0.6, 0.6, 0.6, 1.0)
local HINT_TYPE   = ImVec4(0.8, 0.4, 1.0, 1.0)
local HINT_DESC   = ImVec4(0.3, 0.5, 0.8, 1.0)

local function wrapText(text, maxWidth)
    local lines = {}
    local words = {}
    for word in text:gmatch('%S+') do words[#words + 1] = word end
    local line = ''
    for _, word in ipairs(words) do
        local candidate = line == '' and word or (line .. ' ' .. word)
        if ImGui.CalcTextSize(candidate) > maxWidth and line ~= '' then
            lines[#lines + 1] = line
            line = word
        else
            line = candidate
        end
    end
    if line ~= '' then lines[#lines + 1] = line end
    return lines
end

function Module:RenderHintBar()
    self.hintBarScreenPos         = ImGui.GetCursorScreenPosVec()
    local text                    = self.luaBuffer:GetText()
    local cursor                  = self.luaEditor.cursor
    local cursorIdx               = cursor and cursor.index or #text

    local candidates              = Signatures.ResolveAll(text, cursorIdx)
    local funcName, paramIdx, sig = nil, nil, nil
    for _, c in ipairs(candidates) do
        local s = Signatures.Get()[c.name]
        if s then
            funcName, paramIdx, sig = c.name, c.paramIdx, s
            break
        end
    end

    if not sig then
        ImGui.TextDisabled(' ')
        return
    end

    ImGui.TextColored(HINT_DIM, funcName .. '(')
    for i, param in ipairs(sig.params) do
        ImGui.SameLine(0, 0)
        local color = (i == paramIdx) and HINT_ACTIVE or HINT_DIM
        ImGui.TextColored(color, param.name)
        ImGui.SameLine(0, 0)
        ImGui.TextColored(HINT_TYPE, ':' .. param.type)
        if i < #sig.params then
            ImGui.SameLine(0, 0)
            ImGui.TextColored(HINT_DIM, ',  ')
        end
    end
    ImGui.SameLine(0, 0)
    ImGui.TextColored(HINT_DIM, ')')
    ImGui.SameLine(0, 4)
    ImGui.TextColored(HINT_DIM, '-> ')
    ImGui.SameLine(0, 0)
    ImGui.TextColored(HINT_TYPE, sig.ret or 'nil')
    if sig.desc then
        ImGui.SameLine(0, 4)
        local availW = ImGui.GetContentRegionAvail() - 4
        local lines  = wrapText(': ' .. sig.desc, availW)
        ImGui.TextColored(HINT_DESC, lines[1] or '')
        for i = 2, #lines do
            ImGui.TextColored(HINT_DESC, lines[i])
        end
    end
end

local COMPLETE_ACTIVE = ImVec4(0.5, 1.0, 0.5, 1.0)
local COMPLETE_NAME   = ImVec4(0.35, 0.7, 0.35, 1.0)
local COMPLETE_DIM    = ImVec4(0.6, 0.6, 0.6, 1.0)
local COMPLETE_TYPE   = ImVec4(0.8, 0.4, 1.0, 1.0)
local COMPLETE_DESC   = ImVec4(0.3, 0.5, 0.8, 1.0)
local COMPLETE_MAX    = 15

function Module:RenderCompletion()
    if not Config:GetSetting('EnableAutoCompletion') then return end
    local text            = self.luaBuffer:GetText()
    local cursor          = self.luaEditor.cursor
    local cursorIdx       = cursor and cursor.index or #text

    local prefix, partial = Signatures.ResolveCompletion(text, cursorIdx)
    if not prefix then
        self.completionOpen       = false
        self.completionItems      = {}
        self.completionSuppressed = false
        self.completionLastToken  = ''
        self.completionFrameAge   = 0
        return
    end

    local currentToken = prefix .. '.' .. partial
    if currentToken ~= self.completionLastToken then
        self.completionSuppressed = false
        self.completionLastToken  = currentToken
    end

    if self.completionSuppressed then return end

    local items = Signatures.Complete(prefix, partial)
    if #items == 0 then
        self.completionOpen  = false
        self.completionItems = {}
        return
    end

    local wasOpen = self.completionOpen
    if #items ~= #self.completionItems then
        self.completionIdx = 1
    end
    self.completionItems = items
    self.completionOpen  = true

    if not wasOpen then
        self.completionFrameAge = 0
    else
        self.completionFrameAge = self.completionFrameAge + 1
    end
    local dropReady = self.completionFrameAge >= 2

    if dropReady and ImGui.IsKeyReleased(ImGuiKey.Escape) then
        self.completionOpen       = false
        self.completionItems      = {}
        self.completionSuppressed = true
        return
    end

    local function insertCompletion(item)
        local insertLen    = #prefix + 1 + #partial
        local before       = text:sub(1, cursorIdx - insertLen)
        local after        = text:sub(cursorIdx + 1)
        local inserted     = item.full .. '('
        local newText      = before .. inserted .. after
        local newCursorIdx = #before + #inserted
        self.luaBuffer:SetText(newText)
        self.luaEditor.cursor     = self.luaEditor.beginPos + newCursorIdx
        self.completionOpen       = false
        self.completionItems      = {}
        self.completionSuppressed = true
    end

    local lineHeight = ImGui.GetTextLineHeightWithSpacing()
    local dropX      = self.hintBarScreenPos.x
    local dropY      = self.hintBarScreenPos.y
    local dropW      = ImGui.GetWindowWidth() * 0.98
    local scrollbarW = ImGui.GetStyle().ScrollbarSize
    -- when more items than COMPLETE_MAX, a scrollbar will appear inside the child
    local willScroll = #items > COMPLETE_MAX
    -- desc goes on its own indented line, so available width is nearly the full dropW
    local indent     = ImGui.GetStyle().IndentSpacing
    local descAvailW = dropW - indent - 4 - (willScroll and scrollbarW or 0)

    -- precompute wrapped lines per item so childH is tall enough
    local itemLines  = {}
    local visCount   = math.min(#items, COMPLETE_MAX)
    local totalLines = 0
    for i = 1, #items do
        local item = items[i]
        local n = 0
        if item.sig and item.sig.desc then
            n = #wrapText(item.sig.desc, descAvailW)
        end
        itemLines[i] = n
        if i <= visCount then totalLines = totalLines + 1 + n end
    end

    local childH      = totalLines * lineHeight + 8
    local mousePos    = ImGui.GetMousePosVec()
    local mouseInDrop = mousePos.x >= dropX and mousePos.x <= dropX + dropW
        and mousePos.y >= dropY and mousePos.y <= dropY + childH

    local winPos      = ImGui.GetWindowPosVec()
    local savedCursor = ImGui.GetCursorPosVec()
    ImGui.SetCursorPos(ImVec2(dropX - winPos.x, dropY - winPos.y))
    local scrollFlag = #items > COMPLETE_MAX and 0 or ImGuiWindowFlags.NoScrollbar
    ImGui.PushStyleColor(ImGuiCol.ChildBg, IM_COL32(30, 30, 40, 245))
    if ImGui.BeginChild('##sig_complete', ImVec2(dropW, childH), 0, bit32.bor(
            ImGuiWindowFlags.NoNav,
            ImGuiWindowFlags.NoFocusOnAppearing,
            scrollFlag
        )) then
        for i, item in ipairs(items) do
            local selected = (i == self.completionIdx)
            local clicked = ImGui.Selectable('##sc_' .. i, false, ImGuiSelectableFlags.None)
            if ImGui.IsItemHovered() then self.completionIdx = i end
            if dropReady and clicked and ImGui.IsMouseReleased(0) then
                insertCompletion(item)
            end
            ImGui.SameLine(0, 4)
            ImGui.TextColored(selected and COMPLETE_ACTIVE or COMPLETE_NAME, item.name)
            ImGui.SameLine(0, 4)
            ImGui.TextColored(COMPLETE_DIM, '-> ')
            ImGui.SameLine(0, 0)
            ImGui.TextColored(COMPLETE_TYPE, (item.sig and item.sig.ret) or 'nil')
            if item.sig and item.sig.desc then
                ImGui.Indent(indent)
                local lines = wrapText(item.sig.desc, descAvailW)
                for _, ln in ipairs(lines) do
                    ImGui.TextColored(COMPLETE_DESC, ln)
                end
                ImGui.Unindent(indent)
            end
        end

        -- scroll to keep selected item visible, accounting for variable row heights
        local targetY = 0
        for i = 1, self.completionIdx - 1 do
            targetY = targetY + (1 + (itemLines[i] or 0)) * lineHeight
        end
        local itemH   = (1 + (itemLines[self.completionIdx] or 0)) * lineHeight
        local scrollY = ImGui.GetScrollY()
        if targetY < scrollY then
            ImGui.SetScrollY(targetY)
        elseif targetY + itemH > scrollY + childH - 4 then
            ImGui.SetScrollY(targetY + itemH - childH + 4)
        end
    end
    ImGui.EndChild()
    ImGui.PopStyleColor()
    ImGui.SetCursorPos(savedCursor)

    if dropReady and not mouseInDrop and ImGui.IsMouseClicked(0) then
        self.completionOpen       = false
        self.completionItems      = {}
        self.completionSuppressed = true
    end
end

function Module:CenteredButton(label)
    local style = ImGui.GetStyle()

    local framePaddingX = style.FramePadding.x * 2
    local framePaddingY = style.FramePadding.y * 2

    local availableWidth = ImGui.GetContentRegionAvailVec().x
    local availableHeight = 30

    local textSizeVec = ImGui.CalcTextSizeVec(label)
    local textWidth = textSizeVec.x
    local textHeight = textSizeVec.y

    local paddingX = (availableWidth - textWidth - framePaddingX) / 2
    local paddingY = (availableHeight - textHeight - framePaddingY) / 2

    if paddingX > 0 then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + paddingX)
    end
    if paddingY > 0 then
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + paddingY)
    end
    return ImGui.SmallButton(string.format("%s", label))
end

function Module:RenderToolbar()
    if ImGui.BeginTable("##LuaConsoleToolbar", 7, ImGuiTableFlags.Borders) then
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol1", ImGuiTableColumnFlags.WidthFixed, 30)
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol2", ImGuiTableColumnFlags.WidthFixed, 30)
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol3", ImGuiTableColumnFlags.WidthFixed, 30)
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol4", ImGuiTableColumnFlags.WidthFixed, 30)
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol5", ImGuiTableColumnFlags.WidthFixed, 180)
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol6", ImGuiTableColumnFlags.WidthFixed, 180)
        ImGui.TableSetupColumn("##LuaConsoleToolbarCol7", ImGuiTableColumnFlags.WidthStretch, 200)
        ImGui.TableNextColumn()

        if self.execCoroutine and coroutine.status(self.execCoroutine) ~= 'dead' then
            if self:CenteredButton(Icons.MD_STOP) then
                self.execCoroutine = nil
            end
            RenderTooltip("Stop Script")
        else
            if self:CenteredButton(Icons.MD_PLAY_ARROW) then
                self.execRequested = true
            end
            RenderTooltip("Execute Script (Ctrl+Enter)")
        end

        ImGui.TableNextColumn()

        if not self.autoRun then
            if self:CenteredButton(Icons.MD_FAST_FORWARD) then
                self.autoRun = true
            end
            RenderTooltip("Run on Loop")
        else
            if self:CenteredButton(Icons.MD_STOP) then
                self.autoRun = false
            end
            RenderTooltip("Stop Running")
        end

        ImGui.TableNextColumn()
        if self:CenteredButton(Icons.MD_CLEAR) then
            self.luaBuffer:Clear()
        end
        RenderTooltip("Clear Script")

        ImGui.TableNextColumn()
        if self:CenteredButton(Icons.MD_PHONELINK_ERASE) then
            self.luaConsole:Clear()
        end
        RenderTooltip("Clear Console")

        ImGui.TableNextColumn()
        local showTimestamps, pressed = ImGui.Checkbox("Print Time Stamps", Config:GetSetting('ShowTimestamps'))
        if pressed then
            Config:SetSetting('ShowTimestamps', showTimestamps)
        end

        ImGui.TableNextColumn()
        local enableAutoComplete, pressed = ImGui.Checkbox("Auto Completion",
            Config:GetSetting('EnableAutoCompletion'))
        if pressed then
            Config:SetSetting('EnableAutoCompletion', enableAutoComplete)
        end
        ImGui.TableNextColumn()
        Ui.RenderText("Status: " .. self.status)
        ImGui.EndTable()
    end
end

function Module:ShouldRender()
    return Config:GetSetting('EnableDebugging')
end

function Module:Render()
    Base.Render(self)
    ImGui.NewLine()
    if self.ModuleLoaded then
        self:RenderEditor()
        self:RenderHintBar()
        self:RenderToolbar()
        self:RenderConsole()
        self:RenderCompletion()
    end
end

function Module:DoEvents()
    -- Process Events if needed
    if self.execRequested or (self.autoRun and self.execCoroutine == nil) then
        self.execRequested = false
        self.execCoroutine = self:ExecCoroutine()
        coroutine.resume(self.execCoroutine)
        self.status = "Running..."
    end

    if self.execCoroutine and coroutine.status(self.execCoroutine) ~= 'dead' then
        coroutine.resume(self.execCoroutine)
    else
        self.execCoroutine = nil
        self.status = "Idle..."
    end
end

function Module:GiveTime()
    self:DoEvents()

    if self.luaBuffer:HasFlag(Zep.BufferFlags.Dirty) then
        Config:SetSetting('script', self.luaBuffer:GetText())
        self.luaBuffer:ClearFlags(Zep.BufferFlags.Dirty)
    end
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    return self.status
end

return Module
