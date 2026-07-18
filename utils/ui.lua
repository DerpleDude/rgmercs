local mq                           = require('mq')
local Icons                        = require('mq.ICONS')
local Set                          = require('mq.set')
local ImAnim                       = require('ImAnim')
local ImGui                        = require('ImGui')
local ClassLoader                  = require('utils.classloader')
local Comms                        = require("utils.comms")
local Config                       = require('utils.config')
local Core                         = require("utils.core")
local Globals                      = require('utils.globals')
local Logger                       = require("utils.logger")
local Math                         = require('utils.math')
local Modules                      = require("utils.modules")
local Movement                     = require("utils.movement")
local Strings                      = require("utils.strings")
local Tables                       = require("utils.tables")
local Targeting                    = require("utils.targeting")

local animspellIcons               = mq.FindTextureAnimation('A_SpellIcons')
local yellowspellBg                = mq.FindTextureAnimation("YellowIconBackground")
local redspellBg                   = mq.FindTextureAnimation("RedIconBackground")
local bluespellBg                  = mq.FindTextureAnimation("BlueIconBackground")

local ICON_SIZE                    = 20

local Ui                           = { _version = '1.0', _name = "Ui", _author = 'Derple', }

Ui.__index                         = Ui
Ui.ConfigFilter                    = ""

Ui.TempSettings                    = {
    SortedXT              = {},
    SortedXTIDToSlot      = {},
    SortedXTIDs           = Set.new({}),
    ProgBarTrendState     = {},
    ProgBarAnimState      = {},
    TogglePulseState      = {},
    SmoothPctId           = ImHashStr("smooth_pct"),
    ThumbId               = ImHashStr("thumb"),
    BgId                  = ImHashStr("bg"),
    IconBlinkId           = ImHashStr("blink_ch"),
    LastAnimCleanupTime   = Globals.GetTimeSeconds(),
    TooltipAnimationState = {
        was_hovered = -1,
        tooltip_time = 0.0,
    },
    BuffBlinkState        = {

    },
    MarqueeScrollX        = {},
    ToastNextId           = 0,
}

Ui.ModalText                       = ""
Ui.ModalTitle                      = "##UI Modal"
Ui.ModalPrompt                     = ""
Ui.ModalCallbackFn                 = nil
Ui.ComboFilterText                 = {}

-- Themze support.
Ui.Themez                          = nil
Ui.ThemezNames                     = {}
Ui.SelectedThemezImport            = 1

local CLIP_DL_RING                 = 0x3000
local CLIP_DL_CH_RADIUS            = 0x3102
local CLIP_DL_CH_ALPHA             = 0x3103

local s_drawlist_clips_initialized = false

--- Multiplies the alpha channel of an IM_COL32 packed color by factor.
---@param col number IM_COL32 packed ABGR color value.
---@param factor number Multiplier in [0,1] applied to the alpha byte.
---@return number The color with the reduced alpha channel.
function Ui.ReduceAlpha(col, factor)
    local a = bit.band(bit.rshift(col, 24), 0xFF)
    a = math.floor(a * factor)

    return bit.bor(bit.band(col, 0x00FFFFFF), bit.lshift(a, 24))
end

--- Initializes IamClip draw-list animations (pulsing rings) on first call.
function Ui.InitDrawListClips()
    if s_drawlist_clips_initialized then return end
    s_drawlist_clips_initialized = true
    local pulse_time = 2.0
    -- Pulsing ring - expand and fade
    IamClip.Begin(CLIP_DL_RING)
        :KeyFloat(CLIP_DL_CH_RADIUS, 0.0, 8.0, IamEaseType.OutCubic)
        :KeyFloat(CLIP_DL_CH_RADIUS, pulse_time, 15.0, IamEaseType.OutCubic)
        :KeyFloat(CLIP_DL_CH_ALPHA, 0.0, 1.0, IamEaseType.Linear)
        :KeyFloat(CLIP_DL_CH_ALPHA, pulse_time, 0.0, IamEaseType.Linear)
        :SetStagger(4, pulse_time / 4, 0.0) -- 4 rings, 0.15s apart
        :SetLoop(true, IamDirection.Normal, -1)
        :End()
end

Ui.LoadThemez = function()
    local themez, err = loadfile(mq.configDir .. '/MyThemez.lua')
    if err or not themez then
        Logger.log_debug("\ayNo Themez Lua found.")
    else
        Ui.Themez = themez()

        local ThemezNames = {}

        for _, theme in ipairs(Ui.Themez.Theme or {}) do
            table.insert(ThemezNames, theme.Name or "Unnamed Theme")
        end

        Ui.ThemezNames = ThemezNames
    end
end

Ui.LoadThemez()

--- Converts a Themez theme (by index) to an RGMercs userTheme table.
---@param themeName number Index into Ui.Themez.Theme for the theme to import.
---@return table New userTheme table with color and style entries.
function Ui.ConvertFromThemez(themeName)
    local newUserTheme = {}
    local themeToImport = Ui.Themez.Theme[themeName]
    if themeToImport then
        for _, color in pairs(themeToImport.Color or {}) do
            table.insert(newUserTheme, {
                element = color.PropertyName,
                color = {
                    x = color.Color[1],
                    y = color.Color[2],
                    z = color.Color[3],
                    w = color.Color[4],
                },
            })
        end
        for _, style in pairs(themeToImport.Style or {}) do
            table.insert(newUserTheme, {
                element = style.PropertyName,
                value = style.Size and style.Size or
                    {
                        x = style.X,
                        y = style.Y,
                    },
            })
        end
    end

    return newUserTheme
end

--- Converts an RGMercs userTheme table to a Themez-compatible export table.
---@param userTheme table The RGMercs theme settings table to convert.
---@return table Themez-format table with Name, Color, and Style fields.
function Ui.ConvertToThemez(userTheme)
    local newThemezTheme = { Name = string.format("RGMercs Export - %s", os.date("%Y-%m-%d %H:%M:%S")), Color = {}, Style = {}, }

    for _, setting in pairs(userTheme or {}) do
        if setting.color then
            newThemezTheme.Color[setting.element] = {
                PropertyName = Ui.ImGuiColorVarNames[setting.element],
                Color = {
                    setting.color.x or 0,
                    setting.color.y or 0,
                    setting.color.z or 0,
                    setting.color.w or 0,
                },
            }
        elseif setting.value then
            if type(setting.value) == 'table' then
                newThemezTheme.Style[setting.element] = {
                    PropertyName = Ui.ImGuiStyleVarNames[setting.element],
                    X = setting.value.x or 0,
                    Y = setting.value.y or 0,
                }
            else
                newThemezTheme.Style[setting.element] = {
                    PropertyName = Ui.ImGuiStyleVarNames[setting.element],
                    Size = setting.value,
                }
            end
        end
    end

    return newThemezTheme
end

-- Now make a way to save / reload our themes
Ui.MercThemes              = {}
Ui.MercThemeNames          = {}
Ui.SelectedMercThemeImport = 1

Ui.LoadMercThemes          = function()
    local themes, err = loadfile(mq.configDir .. '/rgmercs/themes.lua')
    if err or not themes then
        Logger.log_debug("\ayNo themes.lua file found in your rgmercs config directory.")
    else
        Ui.MercThemes = themes()

        local mercThemeNames = {}

        for name, _ in pairs(Ui.MercThemes or {}) do
            table.insert(mercThemeNames, name or "Unnamed Theme")
        end

        Ui.MercThemeNames = mercThemeNames
    end
end

Ui.LoadMercThemes()

--- Serializes Ui.MercThemes to the rgmercs/themes.lua config file.
function Ui.SaveThemes()
    mq.pickle(mq.configDir .. '/rgmercs/themes.lua', Ui.MercThemes)
end

-- The built-in ImGui color and style variable names and Ids seem to be out of sync so pulling these directly from C++ and caching them
Ui.ImGuiColorVars     = {}
Ui.ImGuiColorVarNames = {}
Ui.ImGuiColorVarIds   = {}
Ui.ImGuiStyleVars     = {}
Ui.ImGuiStyleVarNames = {}
Ui.ImGuiStyleVarIds   = {}

local preSortedColors = {}
local ImGuiColCount   = 57
for i = 0, ImGuiColCount do
    table.insert(preSortedColors, { Name = ImGui.GetStyleColorName(i), Value = i, })
end

table.sort(preSortedColors, function(a, b) return a.Value < b.Value end)

for _, v in ipairs(preSortedColors) do
    while #Ui.ImGuiColorVars < v.Value do
        table.insert(Ui.ImGuiColorVars, "<Unused>")
    end
    table.insert(Ui.ImGuiColorVars, v.Name)
    Ui.ImGuiColorVarNames[v.Value] = v.Name
    Ui.ImGuiColorVarIds[v.Name] = v.Value
end

local preSortedStyles = {}
for k, v in pairs(getmetatable(ImGuiStyleVar).__index) do
    if k ~= "COUNT" and k ~= 'Alpha' and k ~= 'DisabledAlpha' then
        table.insert(preSortedStyles, { Name = k, Value = v, })
    end
end

table.sort(preSortedStyles, function(a, b) return a.Value < b.Value end)

for _, v in ipairs(preSortedStyles) do
    while #Ui.ImGuiStyleVars < v.Value do
        table.insert(Ui.ImGuiStyleVars, "<Unused>")
    end
    table.insert(Ui.ImGuiStyleVars, v.Name)
    Ui.ImGuiStyleVarNames[v.Value] = v.Name
    Ui.ImGuiStyleVarIds[v.Name] = v.Value
end

--- Resolves an ImGui color ID from a name string or numeric value.
---@param e string|number Color name or ImGuiCol numeric constant.
---@return number The numeric ImGuiCol ID.
function Ui.GetImGuiColorId(e)
    -- check c++ first then the ImGui Lua object
    ---@diagnostic disable-next-line: return-type-mismatch
    return type(e) == 'string' and (Ui.ImGuiColorVarIds[e] or ImGuiCol[e] or 0) or e
end

--- Resolves an ImGui style variable ID from a name string or numeric value.
---@param e string|number Style variable name or ImGuiStyleVar numeric constant.
---@return number The numeric ImGuiStyleVar ID.
function Ui.GetImGuiStyleId(e)
    ---@diagnostic disable-next-line: return-type-mismatch
    return type(e) == 'string' and (Ui.ImGuiStyleVarIds[e] or ImGuiStyleVar[e] or 0) or e
end

--- Renders the indicated list.
---@param listName string The list to render.
function Ui.RenderList(listName, ordered)
    if not listName then return end

    local useKey = "Use" .. listName
    local displayName = listName:gsub("List", " List")
    local listData = Config:GetSetting(listName) or {}

    if Config:GetSetting(useKey) then
        ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionPassColor)
    else
        ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionFailColor)
    end
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(20, 3))

    if ImGui.SmallButton(Config:GetSetting(useKey) and ("Use " .. displayName .. ": Enabled") or ("Use " .. displayName .. ": Disabled")) then
        Config:SetSetting(useKey, not Config:GetSetting(useKey))
    end
    ImGui.PopStyleVar()
    ImGui.PopStyleColor()
    if mq.TLO.Target.ID() > 0 then
        ImGui.SameLine()
        ImGui.PushID("##_small_btn_create_" .. listName)
        if ImGui.SmallButton("Add Target to " .. displayName) then
            Config:ListAdd(mq.TLO.Target.DisplayName(), listName)
        end
        ImGui.PopID()
    end
    local tableId = listName .. " Names"
    if ImGui.BeginTable(tableId, 5, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg)) then
        ImGui.TableSetupColumn('ID', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthFixed), 140.0)
        ImGui.TableSetupColumn('Distance', (ImGuiTableColumnFlags.WidthFixed), 40.0)
        ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthStretch), 150.0)
        ImGui.TableSetupColumn('Controls', (ImGuiTableColumnFlags.WidthFixed), 80.0)
        ImGui.TableHeadersRow()

        for idx, name in ipairs(listData) do
            local spawn = mq.TLO.Spawn(string.format("PC =%s", name))
            ImGui.TableNextColumn()
            if listName == "AssistList" and name == Globals.MainAssist then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(255, 255, 0, 64))
            end
            Ui.RenderText(tostring(idx))
            ImGui.TableNextColumn()
            local _, clicked = ImGui.Selectable(name, false)
            if clicked then
                if spawn and spawn() then
                    mq.TLO.Spawn(spawn.ID()).DoTarget()
                end
            end
            ImGui.TableNextColumn()
            if spawn() and spawn.ID() > 0 then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                Ui.RenderText(tostring(math.ceil(spawn.Distance())))
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                Ui.NavEnabledLoc(spawn.LocYXZ() or "0,0,0")
            else
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                Ui.RenderText("0")
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                Ui.RenderText("0")
            end
            ImGui.TableNextColumn()
            local deleteId = "##_small_btn_delete_" .. listName .. "_" .. tostring(idx)
            ImGui.PushID(deleteId)
            if ImGui.SmallButton(Icons.FA_TRASH) then
                Config:ListDelete(idx, listName)
            end
            ImGui.PopID()
            if ordered then
                ImGui.SameLine()
                local upId = "##_small_btn_up_" .. listName .. "_" .. tostring(idx)
                ImGui.PushID(upId)
                if idx == 1 then
                    ImGui.InvisibleButton(Icons.FA_CHEVRON_UP, ImVec2(22, 1))
                else
                    if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then
                        Config:ListMoveUp(idx, listName)
                    end
                end
                ImGui.PopID()
                ImGui.SameLine()
                local downId = "##_small_btn_dn_" .. listName .. "_" .. tostring(idx)
                ImGui.PushID(downId)
                if idx == #listData then
                    ImGui.InvisibleButton(Icons.FA_CHEVRON_DOWN, ImVec2(22, 1))
                else
                    if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then
                        Config:ListMoveDown(idx, listName)
                    end
                end
                ImGui.PopID()
            end
        end

        ImGui.EndTable()
    end
end

--- Returns the 1-based index of name in Globals.ClassConfigDirs, or 1 if absent.
---@param name string Config directory name to look up.
---@return number 1-based index in ClassConfigDirs.
function Ui.GetClassConfigIDFromName(name)
    for idx, curName in ipairs(Globals.ClassConfigDirs or {}) do
        if curName == name then return idx end
    end

    return 1
end

--- Renders a combo box for selecting the active class config directory.
function Ui.RenderConfigSelector()
    if Globals.ClassConfigDirs ~= nil then
        Ui.RenderText("Active Config:")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(200)
        local newConfigDir, changed = ImGui.Combo("##config_type", Ui.GetClassConfigIDFromName(Config:GetSetting('ClassConfigDir')), Globals.ClassConfigDirs,
            #Globals.ClassConfigDirs)
        if changed then
            Config:SetSetting('ClassConfigDir', Globals.ClassConfigDirs[newConfigDir])
            ClassLoader.reloadConfig()
        end
        Ui.Tooltip(
            "Select your current server/environment.\nLive: Official EQ Servers (Live, Test, TLP).\nProject Lazarus, EQ Might: EMU servers we provide default configs for (RGMercs runs on other servers too; pick the closest as a base).\nAlpha, Beta: Configs in testing. Often preferred, with some caveats (see forum sticky).\nCustom: Copies of the above configs that you have edited yourself.")

        ImGui.SameLine()
        if ImGui.SmallButton(Icons.FA_REFRESH .. " Refresh List") then
            Core.ScanConfigDirs()
        end
        Ui.Tooltip("Refreshes the class config directory list.")
    end
end

--- Renders a floating AA overlay window aligned to the in-game AA window.
function Ui.RenderAAOverlay()
    if not Config:GetSetting('EnableAAOverlay') then return end

    local aaWnd = mq.TLO.Window("AAwindow")
    if aaWnd.Open() then
        -- get the aa list
        local aaSubWindows = aaWnd.Child("AAW_SubWindows")
        local selectedTab = aaSubWindows.CurrentTab
        local tabText = selectedTab.Text()
        local aaSelection = selectedTab.FirstChild
        local aaList = selectedTab.FirstChild.List
        local aaCount = selectedTab.FirstChild.Items()

        if aaSubWindows() == "TRUE" and selectedTab() == "TRUE" and aaSelection() == "TRUE" then
            ImGui.SetNextWindowPos(aaWnd.X() + aaWnd.Width(), aaWnd.Y())

            ImGui.SetNextWindowSize(450, aaWnd.Height())

            local _, shouldDrawGUI = ImGui.Begin(Ui.GetWindowTitle('MercsAAOverlay'), true, bit32.bor(ImGuiWindowFlags.NoDecoration, ImGuiWindowFlags.NoCollapse))

            if shouldDrawGUI then
                if ImGui.BeginChild("##aa_list_child", ImVec2(0, 0), bit32.bor(ImGuiChildFlags.None), bit32.bor(ImGuiWindowFlags.HorizontalScrollbar)) then
                    Ui.RenderText("%s AAs Used by RGMercs:", tabText)

                    ImGui.Separator()

                    local tableColumns = {
                        {
                            name = '#',
                            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultSort),
                            width = 20.0,
                            sort = function(a, b)
                                return a.TableIndex, b.TableIndex
                            end,
                            render = function(entry)
                                Ui.RenderText(entry.TableIndex)
                            end,
                        },
                        {
                            name = 'Inspect',
                            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.NoSort),
                            width = 15,
                            sort = function(a, b)
                                return 0, 0
                            end,
                            render = function(entry)
                                if entry.AA.Spell.Name() then
                                    Ui.DrawInspectableSpellIcon(entry.AA.Spell)
                                else
                                    Ui.RenderText(" " .. Icons.MD_DO_NOT_DISTURB)
                                end
                            end,
                        },
                        {
                            name = 'Name',
                            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
                            width = 100.0,
                            sort = function(a, b)
                                return a.Name or "", b.Name or ""
                            end,
                            render = function(entry)
                                -- can buy it
                                local color = Globals.Constants.Colors.ConditionPassColor

                                -- cant buy
                                if not entry.AA.CanTrain() then
                                    -- options:
                                    -- 1. not high enough level = we have the points but still cannot buy it => Red
                                    -- 2. not enough points => yellow
                                    -- 3. no more ranks => Green
                                    -- Note: This isn't perfect apparently MQ has no way for us to acutally calcualate the next AA Spells min level.

                                    if entry.CostNum <= mq.TLO.Me.AAPoints() then    -- too low level?
                                        color = Globals.Constants.Colors.ConditionFailColor
                                    elseif entry.CostNum > mq.TLO.Me.AAPoints() then -- more ranks?
                                        color = Globals.Constants.Colors.ConditionMidColor
                                    else
                                        color = Globals.Constants.Colors.ConditionPassColor
                                    end
                                end

                                local highlightColor = Globals.Constants.Colors.LightBlue

                                Ui.RenderHyperText(
                                    entry.AA.Spell.RankName.Name() or entry.Name,
                                    color,
                                    highlightColor, function()
                                        aaSelection.Select(entry.TableIndex)
                                    end)
                            end,
                        },
                        {
                            name = 'Cost',
                            flags = bit32.bor(ImGuiTableColumnFlags.WidthStretch),
                            width = 40.0,
                            sort = function(a, b)
                                return a.CostNum, b.CostNum
                            end,
                            render = function(entry)
                                local color = Globals.Constants.Colors.ConditionPassColor

                                if entry.CostNum == 999 then
                                    color = Globals.Constants.Colors.ConditionPassColor
                                elseif entry.CostNum > mq.TLO.Me.AAPoints() then
                                    color = Globals.Constants.Colors.ConditionFailColor
                                else
                                    color = Globals.Constants.Colors.ConditionPassColor
                                end

                                ImGui.TextColored(color, entry.CostNum == 999 and Icons.MD_CHECK or entry.Cost)
                            end,
                        },
                        {
                            name = 'Index',
                            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
                            width = 20.0,
                            sort = function(a, b)
                                return a.AA.Index() or 0, b.AA.Index() or 0
                            end,
                            render = function(entry)
                                Ui.RenderText(tostring(entry.AA.Index() or 0))
                            end,
                        },
                        {
                            name = 'ID',
                            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
                            width = 40.0,
                            sort = function(a, b)
                                return a.AA.ID() or 0, b.AA.ID() or 0
                            end,
                            render = function(entry)
                                Ui.RenderText(tostring(entry.AA.ID() or 0))
                            end,
                        },
                    }
                    Ui.RenderTableData("AAOverylayTable", tableColumns,
                        bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Sortable, ImGuiTableFlags.Hideable,
                            ImGuiTableFlags.Reorderable),
                        function(sort_specs)
                            if aaCount > 0 then
                                Ui.TempSettings.LastCombatModeChangeTime = Ui.TempSettings.LastCombatModeChangeTime or 0
                                Ui.TempSettings.SortedAAOverlayTab = Ui.TempSettings.SortedAAOverlayTab or aaSubWindows.CurrentTabIndex()
                                local tabChanged = Ui.TempSettings.SortedAAOverlayTab ~= aaSubWindows.CurrentTabIndex()
                                local combatModeChange = Ui.TempSettings.LastCombatModeChangeTime < Core.GetLastCombatModeChangeTime()

                                Ui.TempSettings.SortedAAOverlay = Ui.TempSettings.SortedAAOverlay or {}

                                if Ui.TempSettings.SortedAAOverlayCount ~= aaCount or combatModeChange or tabChanged then
                                    Ui.TempSettings.SortedAAOverlay = {}
                                    for i = 1, aaCount do
                                        local aaName = aaList(i)()
                                        local cost = aaList(i, 3)()
                                        local costNum = tonumber(cost) or 999
                                        local aa = mq.TLO.Me.AltAbility(aaName).Spell() and mq.TLO.Me.AltAbility(aaName) or mq.TLO.AltAbility(aaName)

                                        if Core.AAUsedInRotation(aaName) then
                                            table.insert(Ui.TempSettings.SortedAAOverlay, { Name = aaName, TableIndex = i, Cost = cost, CostNum = costNum, AA = aa, })
                                        end

                                        if sort_specs then
                                            sort_specs.SpecsDirty = true
                                        end
                                    end

                                    Ui.TempSettings.LastCombatModeChangeTime = Core.GetLastCombatModeChangeTime()
                                    Ui.TempSettings.SortedAAOverlayTab       = aaSubWindows.CurrentTabIndex()
                                end

                                if sort_specs and sort_specs.SpecsDirty then
                                    table.sort(Ui.TempSettings.SortedAAOverlay, function(a, b)
                                        local spec = sort_specs:Specs(1) -- single-column sort

                                        local av, bv = tableColumns[spec.ColumnIndex + 1].sort(a, b)

                                        if spec.SortDirection == ImGuiSortDirection.Ascending then
                                            return (av or 0) < (bv or 0)
                                        else
                                            return (av or 0) > (bv or 0)
                                        end
                                    end)

                                    sort_specs.SpecsDirty = false
                                end
                            end
                        end,
                        function()
                            for _, entry in ipairs(Ui.TempSettings.SortedAAOverlay or {}) do
                                ImGui.PushID(string.format("##aa_overlay_table_entry_%s", entry.TableIndex))
                                for _, colData in ipairs(tableColumns) do
                                    ImGui.TableNextColumn()
                                    colData.render(entry)
                                end
                                ImGui.PopID()
                            end
                        end)
                end
                ImGui.EndChild()
            end

            ImGui.End()
        end
    end
end

--- Renders text with an animated color-wave gradient; falls back to a
--- colored Selectable if the coverage-mask draw API is unavailable.
---@param text string The text to display.
---@param conColor ImVec4 Base color for the wave gradient.
---@param clickedAction function? Callback invoked when the item is clicked.
---@param dontUseWave boolean? If true, skips the wave and uses plain colored text.
function Ui.RenderColorWaveText(text, conColor, clickedAction, dontUseWave)
    local draw_list = ImGui.GetWindowDrawList()
    ---@diagnostic disable-next-line: undefined-field
    if draw_list.CreateCoverageMaskLayer and not dontUseWave then
        local textPos = ImGui.GetCursorScreenPosVec()
        local textW, textH = ImGui.CalcTextSize(text)
        local time = ImGui.GetTime() * 2.5
        local function flowColor(phase)
            local wave = 0.5 + 0.5 * math.sin(time + phase)
            local lo, hi = 0.6, 1.0
            local t = lo + (hi - lo) * wave
            return IM_COL32(
                math.floor(conColor.x * 255 * t),
                math.floor(conColor.y * 255 * t),
                math.floor(conColor.z * 255 * t),
                255)
        end
        local gradStart = flowColor(0)
        local gradEnd   = flowColor(math.pi)
        ---@diagnostic disable-next-line: undefined-field
        draw_list:CreateCoverageMaskLayer(textPos, ImVec2(textPos.x + textW, textPos.y + textH))
        draw_list:AddText(nil, ImGui.GetFontSize(), textPos, IM_COL32(255, 255, 255, 255), text)
        ---@diagnostic disable-next-line: undefined-field
        draw_list:BeginCoverageMaskedDraw()
        draw_list:AddRectFilledMultiColor(
            textPos,
            ImVec2(textPos.x + textW, textPos.y + textH),
            gradStart,
            gradEnd,
            gradEnd,
            gradStart
        )
        ---@diagnostic disable-next-line: undefined-field
        draw_list:EndCoverageMaskedDraw()
        -- Click detection: invisible button over the text area
        ImGui.SetCursorScreenPos(textPos)
        ImGui.InvisibleButton(text .. "##wave_click", ImVec2(textW, textH))
        if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Left) and clickedAction then
            clickedAction()
        end
    else
        ImGui.PushStyleColor(ImGuiCol.Text, conColor)
        local _, clicked = ImGui.Selectable(text, false)
        if clicked and clickedAction then
            clickedAction()
        end
        ImGui.PopStyleColor(1)
    end
end

--- Dispatches a left/right-click action on a peer in the Mercs Status panel.
---@param peer string DanNet peer name.
---@param action number 1 = target spawn, 2 = /foreground, 3 = no-op.
function Ui.HandleStatusClickAction(peer, action)
    local name = Comms.GetNameFromPeer(peer)
    if name then
        local peerSpawn = mq.TLO.Spawn("=" .. name)

        if action == 1 then
            if peerSpawn.ID() > 0 then
                peerSpawn.DoTarget()
            end
        elseif action == 2 then
            Comms.SendPeerDoCmd(peer, "/foreground")
        elseif action == 3 then
            -- nothing
        end
    end
end

--- Returns a short string indicating the group/raid slot of peerName.
--- Returns "F1"–"F6" for group, "Gn" for raid, "X" for ungrouped.
---@param peerName string Character name to look up.
---@return string Short status label (e.g. "F2", "G3", "X").
function Ui.GetGroupstatusText(peerName)
    if peerName == Globals.CurLoadedChar then
        return "F1"
    end

    if mq.TLO.Group.Members() > 0 then
        local groupMember = mq.TLO.Group.Member(peerName)
        if groupMember() then
            return "F" .. ((groupMember.Index() or 0) + 1)
        end
    end

    if mq.TLO.Raid.Members() > 0 then
        local raidMember = mq.TLO.Raid.Member(peerName)
        if raidMember() then
            return "G" .. (raidMember.Group() or 0)
        end
    end

    return "X"
end

--- Renders the Mercs Status panel with HP/mana/state columns for each peer.
---@param showPopout boolean? If true, renders a pop-out button at the top.
function Ui.RenderMercsStatus(showPopout)
    if showPopout then
        if ImGui.SmallButton(Icons.MD_OPEN_IN_NEW) then
            Config:SetSetting('PopOutMercsStatus', true)
        end
        Ui.Tooltip("Pop the Mercs Status Panel out into its own window.")
        ImGui.NewLine()
    end

    local Colors = Globals.Constants.Colors
    local ConColorsNameToVec4 = Globals.Constants.ConColorsNameToVec4
    local assistRange = Config:GetSetting('AssistRange')

    if not Ui.TempSettings.SortedMercs then
        Ui.TempSettings.SortedMercs = {}
    end

    local tableColumns = {
        {
            name = string.format('Name (%d)', #Ui.TempSettings.SortedMercs),
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultSort),
            width = 60.0,
            sort = function(_, a, b)
                return a or "", b or ""
            end,
            render = function(peer, data)
                if data.Data.ZoneId ~= Globals.CurZoneId or data.Data.InstanceId ~= Globals.CurInstanceId then
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionDisabledColor)
                end

                local name = Comms.GetNameFromPeer(peer)
                if name then
                    local displayName = data.Data.Invis and "(" .. name .. ")" or name
                    ImGui.SmallButton(displayName)
                    if name then
                        if ImGui.IsItemClicked(ImGuiMouseButton.Left) then
                            if (mq.TLO.Cursor.ID() or 0) > 0 and Config:GetSetting('StatusLeftClickCursorClickAction') == 1 then
                                local peerSpawn = mq.TLO.Spawn("=" .. name)
                                if peerSpawn.ID() > 0 then
                                    if peerSpawn.Distance() <= 15 then
                                        peerSpawn.DoTarget()
                                        Core.DoCmd("/timed 1 /click left target")
                                        Core.DoCmd('/timed 10 /lua parse mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()')
                                        Comms.SendPeerDoCmd(peer, '/timed 10 /lua parse mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()')
                                    end
                                end
                            else
                                Ui.HandleStatusClickAction(peer, Config:GetSetting('StatusLeftClickAction'))
                            end
                        elseif ImGui.IsItemClicked(ImGuiMouseButton.Right) then
                            Ui.HandleStatusClickAction(peer, Config:GetSetting('StatusRightClickAction'))
                        end
                    end
                    if data.Data.ZoneId ~= Globals.CurZoneId or data.Data.InstanceId ~= Globals.CurInstanceId then
                        ImGui.PopStyleColor()
                    end
                end
            end,
        },
        {
            name = string.format('Server'),
            flags = bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.DefaultHide),
            width = 150.0,
            sort = function(_, a, b)
                return a.Data.Server or "", b.Data.Server or ""
            end,
            render = function(peer, data)
                if data.Data.Server ~= mq.TLO.EverQuest.Server() then
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionDisabledColor)
                end

                Ui.RenderText(data.Data.Server or "Unknown")

                if data.Data.Server ~= mq.TLO.EverQuest.Server() then
                    ImGui.PopStyleColor()
                end
            end,
        },
        {
            name = 'Zone',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 80.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Zone or "", data_b.Data.Zone or ""
            end,
            render = function(peer, data)
                if data.Data.ZoneShortName == mq.TLO.Zone.ShortName() then
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionPassColor)
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionFailColor)
                end

                Ui.RenderText("%s", data.Data.Zone or "None")

                ImGui.PopStyleColor()
            end,
        },
        {
            name = 'Zone Short Name',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 80.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.ZoneShortName or "", data_b.Data.ZoneShortName or ""
            end,
            render = function(peer, data)
                if data.Data.ZoneShortName == mq.TLO.Zone.ShortName() then
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionPassColor)
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionFailColor)
                end

                Ui.RenderText("%s", data.Data.ZoneShortName or "None")

                ImGui.PopStyleColor()
            end,
        },
        {
            name = 'State',
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 15.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.State or "", data_b.Data.State or ""
            end,
            render = function(peer, data)
                local stateColor =
                    (data.Data.Burning and (Globals.GetAlternatingColor(Colors.BurnFlashColorOne, Colors.BurnFlashColorTwo))) or
                    (data.Data.State == "Paused" and Colors.MainButtonPausedColor) or
                    (data.Data.State == "Combat" and Colors.MainCombatColor) or
                    Colors.MainDowntimeColor

                local stateIcon = (data.Data.Burning and Icons.FA_FIRE) or
                    (data.Data.State == "Paused" and Icons.FA_PAUSE) or
                    (data.Data.State == "Combat" and Icons.MD_GAMEPAD) or Icons.FA_PLAY

                ImGui.PushStyleColor(ImGuiCol.Text, stateColor)
                local _, clicked = ImGui.Selectable(stateIcon, false)
                ImGui.PopStyleColor()
                if clicked then
                    Comms.SendPeerDoCmd(peer, "/rgl %s", data.Data.State == "Paused" and "unpause" or "pause")
                end

                Ui.MultilineTooltipWithColors({
                    { text = "State: ",                                       color = Colors.White,       padAfter = 4, },
                    {
                        text = data.Data.State or "None",
                        color = data.Data.State == "Paused" and Colors.MainButtonPausedColor or
                            data.Data.State == "Combat" and Colors.MainCombatColor or
                            Colors.MainDowntimeColor,
                        sameLine = true,
                    },
                    { text = "AutoTarget: ",                                  color = Colors.White,       padAfter = 4, },
                    { text = data.Data.AutoTarget or "None",                  color = Colors.LightRed,    sameLine = true, },
                    { text = "Assist: ",                                      color = Colors.White,       padAfter = 4, },
                    { text = data.Data.Assist or "None",                      color = Colors.Cyan,        sameLine = true, },
                    { text = "Chase: ",                                       color = Colors.White,       padAfter = 4, },
                    { text = data.Data.Chase or "None",                       color = Colors.Cyan,        sameLine = true, },
                    { text = "Level: ",                                       color = Colors.White,       padAfter = 4, },
                    { text = tostring(data.Data.Level) or "0",                color = Colors.Yellow,      sameLine = true, },
                    { text = "Exp: ",                                         color = Colors.White,       padAfter = 4, },
                    { text = string.format("%0.2f%%", data.Data.PctExp or 0), color = Colors.LightYellow, sameLine = true, },
                    { text = "Unspent AA: ",                                  color = Colors.White,       padAfter = 4, },
                    { text = data.Data.UnSpentAA or "None",                   color = Colors.Orange,      sameLine = true, },
                    { text = "Spent AA: ",                                    color = Colors.White,       padAfter = 4, },
                    { text = data.Data.SpentAA or "None",                     color = Colors.Orange,      sameLine = true, },
                    { text = "Total AA: ",                                    color = Colors.White,       padAfter = 4, },
                    { text = data.Data.TotalAA or "None",                     color = Colors.Orange,      sameLine = true, },
                })
            end,

        },

        {
            name = "Level",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 20.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Level or 0, data_b.Data.Level or 0
            end,
            render = function(peer, data)
                Ui.RenderText("%d", data.Data.Level or 0)
            end,
        },
        {
            name = 'Unspent AA',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.UnSpentAA or 0, data_b.Data.UnSpentAA or 0
            end,
            render = function(peer, data)
                Ui.RenderText("%d", data.Data.UnSpentAA or 0)
            end,
        },
        {
            name = 'Spent AA',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.SpentAA or 0, data_b.Data.SpentAA or 0
            end,
            render = function(peer, data)
                Ui.RenderText("%d", data.Data.SpentAA or 0)
            end,
        },
        {
            name = 'Total AA',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.TotalAA or 0, data_b.Data.TotalAA or 0
            end,
            render = function(peer, data)
                Ui.RenderText("%d", data.Data.TotalAA or 0)
            end,
        },
        {
            name = 'Pct Exp',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PctExp or 0, data_b.Data.PctExp or 0
            end,
            render = function(peer, data)
                local pctExp = math.ceil(data.Data.PctExp or 0)
                if Config:GetSetting('StatusUseBars') then
                    Ui.RenderAnimatedPercentage("MercsStatusExpBar" .. peer, pctExp, ImGui.GetTextLineHeight(), 0, Colors.Yellow,
                        Colors.Yellow, nil, 0, 4)
                else
                    Ui.RenderColoredText(
                        Ui.GetPercentageColor(pctExp, { Colors.LightYellow, Colors.Yellow, Colors.Orange, }), "%6.2f%%", pctExp)
                end
            end,
        },
        {
            name = 'HP %',
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 20.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.HPs or 0, data_b.Data.HPs or 0
            end,
            render = function(peer, data)
                local pctHp = math.ceil(data.Data.HPs or 0)
                if Config:GetSetting('StatusUseBars') then
                    Ui.RenderFancyHPBar("MercsStatusHPBar" .. peer, pctHp, ImGui.GetTextLineHeight(), nil, 0, 4)
                else
                    Ui.RenderColoredText(
                        Ui.GetPercentageColor(pctHp, { Colors.BrightGreen, Colors.Yellow, Colors.Red, }), "%d%%", pctHp)
                end
            end,
        },
        {
            name = 'Mana %',
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 20.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Mana or 0, data_b.Data.Mana or 0
            end,
            render = function(peer, data)
                if Globals.Constants.RGCasters:contains(data.Data.Class) then
                    local pctMana = data.Data.Mana and math.ceil(data.Data.Mana or 0) or nil
                    if Config:GetSetting('StatusUseBars') then
                        Ui.RenderFancyManaBar("MercsStatusManaBar" .. peer, pctMana, ImGui.GetTextLineHeight(), 0, 4)
                    else
                        Ui.RenderColoredText(
                            Ui.GetPercentageColor(pctMana, { Colors.Cyan, Colors.LightBlue, Colors.Red, }), pctMana and "%d%%" or "", pctMana or "")
                    end
                end
            end,
        },
        {
            name = 'End %',
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 20.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Endurance or 0, data_b.Data.Endurance or 0
            end,
            render = function(peer, data)
                if data.Data.Endurance == nil then return end
                local pctEnd = math.ceil(data.Data.Endurance or 0)
                if Config:GetSetting('StatusUseBars') then
                    Ui.RenderAnimatedPercentage("MercsStatusEnduranceBar" .. peer, pctEnd, ImGui.GetTextLineHeight(), 0, Colors.LightRed,
                        Colors.Yellow, nil, 0, 4)
                else
                    Ui.RenderColoredText(
                        Ui.GetPercentageColor(pctEnd, { Colors.Yellow, Colors.Grey, Colors.Red, }), "%d%%", pctEnd)
                end
            end,
        },
        {
            name = "Distance",
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = (Globals.CurZoneId == mercs[a].Data.ZoneId and Globals.CurInstanceId == mercs[a].Data.InstanceId and (mq.TLO.Spawn(mercs[a].Data.ID).Distance() or 999) or 999)
                local data_b = (Globals.CurZoneId == mercs[b].Data.ZoneId and Globals.CurInstanceId == mercs[b].Data.InstanceId and (mq.TLO.Spawn(mercs[b].Data.ID).Distance() or 999) or 999)

                if data_a == data_b then
                    return a, b
                end

                return data_a, data_b
            end,
            render = function(peer, data)
                local distance = (Globals.CurZoneId == data.Data.ZoneId and Globals.CurInstanceId == data.Data.InstanceId) and mq.TLO.Spawn(data.Data.ID).Distance() or 999
                local distString = distance == 999 and "" or string.format("%d", distance)
                ImGui.PushStyleColor(ImGuiCol.Text,
                    distance == 999 and Colors.ConditionDisabledColor or
                    distance > assistRange and Colors.ConditionFailColor or
                    distance > assistRange / 2 and Colors.ConditionMidColor or
                    Colors.ConditionPassColor

                )
                Ui.RenderText(distString)
                ImGui.PopStyleColor()
            end,
        },
        {
            name = 'Chase',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 60.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Chase or "", data_b.Data.Chase or ""
            end,
            render = function(peer, data)
                Ui.RenderText("%s", data.Data.Chase or "None")
            end,
        },
        {
            name = 'Assist',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 60.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Assist or "", data_b.Data.Assist or ""
            end,
            render = function(peer, data)
                Ui.RenderText("%s", data.Data.Assist or "None")
            end,
        },
        {
            name = 'AutoTarget',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 120.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.AutoTarget or "", data_b.Data.AutoTarget or ""
            end,
            render = function(peer, data)
                Ui.RenderText("%s", data.Data.AutoTarget or "None")
            end,
        },
        {
            name = 'Target',
            flags = ImGuiTableColumnFlags.WidthStretch,
            width = 120.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Target or "", data_b.Data.Target or ""
            end,
            render = function(peer, data)
                if data.Data.Target ~= "None" then
                    Ui.RenderText("%s", data.Data.Target)
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionDisabledColor)
                    ImGui.TextDisabled("None")
                    ImGui.PopStyleColor()
                end
            end,

        },
        {
            name = 'Casting',
            flags = ImGuiTableColumnFlags.WidthStretch,
            width = 120.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.Casting or "", data_b.Data.Casting or ""
            end,
            render = function(peer, data)
                if data.Data.Casting ~= "None" then
                    Ui.RenderText("%s", data.Data.Casting)
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionDisabledColor)
                    ImGui.TextDisabled("None")
                    ImGui.PopStyleColor()
                end
            end,

        },
        {
            name = 'LOS',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.DefaultHide, ImGuiTableColumnFlags.NoSort),
            width = 20.0,
            sort = function(mercs, a, b)
                return a, b
            end,
            render = function(peer, data)
                local los = mq.TLO.Spawn(data.Data.ID).LineOfSight()
                ImGui.TextColored(los and Colors.ConditionPassColor or Colors.ConditionFailColor, "%s", los and Icons.FA_EYE or Icons.FA_EYE_SLASH)
            end,

        },
        {
            name = 'Pet',
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 80.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PetID or 0, data_b.Data.PetID or 0
            end,
            render = function(peer, data)
                if data.Data.PetID > 0 then
                    ImGui.PushStyleColor(ImGuiCol.Text, (ConColorsNameToVec4[data.Data.PetConColor] or Colors.White))

                    Ui.InvisibleWithButtonText("##pet_btn_" .. tostring(peer), Icons.MD_PETS, ImVec2(ICON_SIZE, ImGui.GetTextLineHeight()),
                        function() Core.DoCmd("/mqtarget id %d", data.Data.PetID) end)

                    ImGui.PopStyleColor()

                    Ui.MultilineTooltipWithColors(
                        {
                            { text = "Name: ",                      color = Colors.White,      padAfter = 4, },
                            { text = data.Data.PetName or "None",   color = Colors.LightGreen, sameLine = true, },
                            { text = "Level: ",                     color = Colors.White,      padAfter = 4, },
                            { text = data.Data.PetLevel or "None",  color = Colors.LightBlue,  sameLine = true, },
                            { text = "HPs: ",                       color = Colors.White,      padAfter = 4, },
                            { text = data.Data.PetHPs or "None",    color = Colors.Cyan,       sameLine = true, },
                            { text = "Target: ",                    color = Colors.White,      padAfter = 4, },
                            { text = data.Data.PetTarget or "None", color = Colors.LightRed,   sameLine = true, },
                        })
                end
            end,

        },
        {
            name = 'Pet ID',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PetID or 0, data_b.Data.PetID or 0
            end,
            render = function(peer, data)
                Ui.RenderText(data.Data.PetID > 0 and string.format("%d", data.Data.PetID) or "")
            end,
        },
        {
            name = "Pet HPs",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PetHPs or 0, data_b.Data.PetHPs or 0
            end,
            render = function(peer, data)
                if data.Data.PetID > 0 then
                    if Config:GetSetting('StatusUseBars') then
                        Ui.RenderFancyHPBar("MercsStatusPetHPBar" .. peer, math.ceil(data.Data.PetHPs or 0), ImGui.GetTextLineHeight(), false, nil, 4)
                    else
                        Ui.RenderColoredText(
                            Ui.GetPercentageColor(data.Data.PetHPs or 0, { Colors.BrightGreen, Colors.Yellow, Colors.Red, }),
                            data.Data.PetHPs and "%d%%" or "", math.ceil(data.Data.PetHPs or 0) or "")
                    end
                end
            end,
        },
        {
            name = "Pet Level",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 15.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PetLevel or 0, data_b.Data.PetLevel or 0
            end,
            render = function(peer, data)
                Ui.RenderText(data.Data.PetID > 0 and string.format("%d", data.Data.PetLevel) or "")
            end,
        },
        {
            name = "Pet Name",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.DefaultHide),
            width = 80.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PetName or "", data_b.Data.PetName or ""
            end,
            render = function(peer, data)
                Ui.RenderText(data.Data.PetID > 0 and string.format("%s", data.Data.PetName) or "None")
            end,
        },
        {
            name = "Pet Target",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthStretch, ImGuiTableColumnFlags.DefaultHide),
            width = 120.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.PetTarget or "", data_b.Data.PetTarget or ""
            end,
            render = function(peer, data)
                Ui.RenderText(data.Data.PetID > 0 and string.format("%s", data.Data.PetTarget or "None") or "")
            end,
        },
        {
            name = 'Last Update',
            flags = ImGuiTableColumnFlags.WidthFixed,
            width = 15.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.LastUpdate or 0, data_b.Data.LastUpdate or 0
            end,
            render = function(peer, data)
                Ui.RenderText("%ds", Globals.GetTimeSeconds() - (data.LastHeartbeat or 0))
            end,

        },
        {
            name = 'Free Inv',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 15.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.FreeInventory or 0, data_b.Data.FreeInventory or 0
            end,
            render = function(peer, data)
                ImGui.PushStyleColor(ImGuiCol.Text,
                    data.Data.FreeInventory >= 20 and Colors.ConditionPassColor or
                    data.Data.FreeInventory >= 5 and Colors.ConditionMidColor or
                    Colors.ConditionFailColor)
                Ui.RenderText("%d", data.Data.FreeInventory or 0)
                ImGui.PopStyleColor()
            end,

        },
        {
            name = 'Group Status',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 15.0,
            sort = function(_, a, b)
                local name_a = Comms.GetNameFromPeer(a) or ""
                local name_b = Comms.GetNameFromPeer(b) or ""
                return Ui.GetGroupstatusText(name_a), Ui.GetGroupstatusText(name_b)
            end,
            render = function(peer, _)
                local name = Comms.GetNameFromPeer(peer) or ""
                ImGui.TextColored(Colors.Lavender, Ui.GetGroupstatusText(name))
            end,
        },
        {
            name = "Class",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultSort),
            width = 20.0,
            sort = function(_, a, b)
                return a or "", b or ""
            end,
            render = function(peer, data)
                if data.Data.ZoneId ~= Globals.CurZoneId or data.Data.InstanceId ~= Globals.CurInstanceId then
                    ImGui.PushStyleColor(ImGuiCol.Text, Colors.ConditionDisabledColor)
                end

                local class = data.Data.Class
                if class then
                    local displayName = data.Data.Invis and "(" .. class .. ")" or class
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.BasicColors.Mint)
                    Ui.RenderText(displayName)
                    ImGui.PopStyleColor()
                    if class then
                        if ImGui.IsItemClicked(ImGuiMouseButton.Left) then
                            if (mq.TLO.Cursor.ID() or 0) > 0 and Config:GetSetting('StatusLeftClickCursorClickAction') == 1 then
                                local peerSpawn = mq.TLO.Spawn("=" .. Comms.GetNameFromPeer(peer))
                                if peerSpawn.ID() > 0 then
                                    if peerSpawn.Distance() <= 15 then
                                        peerSpawn.DoTarget()
                                        Core.DoCmd("/timed 1 /click left target")
                                        Core.DoCmd('/timed 10 /lua parse mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()')
                                        Comms.SendPeerDoCmd(peer, '/timed 10 /lua parse mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()')
                                    end
                                end
                            else
                                Ui.HandleStatusClickAction(peer, Config:GetSetting('StatusLeftClickAction'))
                            end
                        elseif ImGui.IsItemClicked(ImGuiMouseButton.Right) then
                            Ui.HandleStatusClickAction(peer, Config:GetSetting('StatusRightClickAction'))
                        end
                        if ImGui.IsItemHovered() then
                            ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, IM_COL32(255, 255, 255, 30))
                        end
                    end
                    if data.Data.ZoneId ~= Globals.CurZoneId or data.Data.InstanceId ~= Globals.CurInstanceId then
                        ImGui.PopStyleColor()
                    end
                end
            end,
        },
        {
            name = 'Buff Slots',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 15.0,
            sort = function(mercs, a, b)
                local data_a = mercs[a]
                local data_b = mercs[b]
                return data_a.Data.OpenBuffSlots or 0, data_b.Data.OpenBuffSlots or 0
            end,
            render = function(peer, data)
                ImGui.PushStyleColor(ImGuiCol.Text,
                    data.Data.OpenBuffSlots >= math.floor(data.Data.MaxBuffSlots * .6) and Colors.ConditionPassColor or
                    data.Data.OpenBuffSlots >= math.floor(data.Data.MaxBuffSlots * .3) and Colors.ConditionMidColor or
                    Colors.ConditionFailColor)
                Ui.RenderText("%d", data.Data.OpenBuffSlots or 0)
                ImGui.PopStyleColor()
            end,
        },
        {
            name = 'Buffs',
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide, ImGuiTableColumnFlags.NoSort),
            width = 150.0,
            render = function(peer, data)
                for _, buffId in ipairs(data.Data.Buffs or {}) do
                    local buff = mq.TLO.Spell(buffId)
                    if buff and buff() then
                        Ui.DrawInspectableSpellIcon(buff, ImGui.GetTextLineHeight(), false)
                        if ImGui.IsItemHovered() then
                            Ui.MultilineTooltipWithColors(
                                {
                                    { text = "Name: ",                                          color = Colors.White,     padAfter = 4, },
                                    { text = buff.RankName.Name(),                              color = Colors.LightBlue, sameLine = true, },
                                    { text = "Description: ",                                   color = Colors.White,     padAfter = 4, },
                                    { text = buff.Description() or "No description available.", color = Colors.LightBlue, },
                                })
                        end
                    end
                    ImGui.SameLine()
                end
            end,
        },
    }

    Ui.RenderTableData("MercStatusTable", tableColumns,
        bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Sortable, ImGuiTableFlags.Hideable, ImGuiTableFlags.Reorderable),
        function(sort_specs)
            local mercs = Comms.GetAllPeerHeartbeats(true)

            if #Ui.TempSettings.SortedMercs ~= Tables.GetTableSize(mercs) then
                Ui.TempSettings.SortedMercs = {}
                for peer, _ in pairs(mercs) do table.insert(Ui.TempSettings.SortedMercs, peer) end
                if sort_specs then sort_specs.SpecsDirty = true end
            end

            local sortingByDistance = tableColumns[(sort_specs and sort_specs:Specs(1).ColumnIndex or 0) + 1].name == "Distance"
            if sort_specs and sort_specs.SpecsDirty or sortingByDistance then
                table.sort(Ui.TempSettings.SortedMercs, function(a, b)
                    local spec = sort_specs:Specs(1) -- single-column sort

                    local av, bv = tableColumns[spec.ColumnIndex + 1].sort(mercs, a, b)

                    if spec.SortDirection == ImGuiSortDirection.Ascending then
                        return (av or 0) < (bv or 0)
                    else
                        return (av or 0) > (bv or 0)
                    end
                end)

                sort_specs.SpecsDirty = false
            end
        end,
        function()
            local mercs = Comms.GetAllPeerHeartbeats(true)
            for _, peer in ipairs(Ui.TempSettings.SortedMercs) do
                local data = mercs[peer]
                if data and data.Data then
                    ImGui.PushID(string.format("##table_entry_%s", peer))
                    for idx, colData in ipairs(tableColumns) do
                        ImGui.TableNextColumn()
                        if ImGui.TableSetColumnIndex(idx - 1) then
                            colData.render(peer, data)
                        end
                    end
                    ImGui.PopID()
                end
            end
        end)
end

--- Renders the Force Target / Ignored Target list panel.
---@param showPopout boolean? If true, renders a pop-out button at the top.
function Ui.RenderForceTargetList(showPopout)
    if showPopout then
        if ImGui.SmallButton(Icons.MD_OPEN_IN_NEW) then
            Config:SetSetting('PopOutForceTarget', true)
        end
        Ui.Tooltip("Pop the Force Target list out into its own window.")
        ImGui.NewLine()
    end

    if Config:GetSetting('ShowFTControls') then
        local btnWidth = (ImGui.GetContentRegionAvailVec().x - ImGui.GetStyle().ItemSpacing.x * 2) / 3
        if ImGui.Button("Clear Forced Target", btnWidth, 18) then
            Globals.SetForcedTargetId(0)
        end
        ImGui.SameLine()

        if ImGui.Button("Clear Ignored Targets", btnWidth, 18) then
            Globals.IgnoredTargetIDs = Set.new({})
        end
        ImGui.SameLine()

        if ImGui.Button("Clear NoHate Targets", btnWidth, 18) then
            Globals.NoHateTargetIDs = Set.new({})
        end
    end

    -- flashy highlights
    local Colors     = Globals.Constants.BasicColors
    local hlColorOne = Globals.Constants.Colors.FTHighlight
    local hlColorTwo = ImVec4(hlColorOne.x * .8, hlColorOne.y * .8, hlColorOne.z * .8, hlColorOne.w)

    local denyListed = {}
    local function isDenyListed(xtarg)
        if not Globals.ZoneHasDeny then return false end
        local cached = denyListed[xtarg]
        if cached == nil then
            cached = Globals.ZoneDenyNames[Strings.TrimSpaces(xtarg.CleanName() or ""):lower()] ~= nil
            denyListed[xtarg] = cached
        end
        return cached
    end

    local tableColumns = {
        {
            name = "FT",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
            width = 16.0,
            sort = function(a, b)
                return
                    (Globals.ForceTargetID > 0 and (Globals.ForceTargetID == a.ID() and 1 or 0) or 0),
                    (Globals.ForceTargetID > 0 and (Globals.ForceTargetID == b.ID() and 1 or 0) or 0)
            end,
            render = function(xtarg, i)
                local checked = Globals.ForceTargetID > 0 and Globals.ForceTargetID == xtarg.ID()

                if not Config:GetSetting('FTHPOverlay') and (Targeting.GetAutoTarget().ID() or 0) == xtarg.ID() then
                    ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, Ui.GetConHighlightBySpawn(xtarg))
                end

                ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))

                if not checked then
                    ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(52, 52, 52, 0))
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.GetAlternatingColor())
                end

                Ui.InvisibleWithButtonText("##ft_btn_" .. tostring(i), Icons.FA_ARROW_RIGHT, ImVec2(ICON_SIZE, ImGui.GetTextLineHeight()),
                    function() if checked then Globals.SetForcedTargetId(0) else Globals.SetForcedTargetId(xtarg.ID()) end end)

                ImGui.PopStyleColor(1)

                local min = ImGui.GetItemRectMinVec()
                local max = ImGui.GetItemRectMaxVec()
                local draw = ImGui.GetWindowDrawList()
                draw:AddRect(min, max, IM_COL32(180, 180, 180, 180), 0.5)
                ImGui.PopStyleVar(1)
            end,
        },
        {
            name = "IT",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
            width = 16.0,
            sort = function(a, b)
                return (Globals.IgnoredTargetIDs:contains(a.ID()) or isDenyListed(a)) and 1 or 0, (Globals.IgnoredTargetIDs:contains(b.ID()) or isDenyListed(b)) and 1 or 0
            end,
            render = function(xtarg, i)
                local sessionHit = Globals.IgnoredTargetIDs:contains(xtarg.ID())
                local denyHit = isDenyListed(xtarg)
                ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))

                if not sessionHit then
                    if denyHit then
                        ImGui.PushStyleColor(ImGuiCol.Text, Colors.Grey)
                    else
                        ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(52, 52, 52, 0))
                    end
                end

                local clickFn = nil
                if sessionHit then
                    clickFn = function() Globals.IgnoredTargetIDs:remove(xtarg.ID()) end
                elseif not denyHit then
                    clickFn = function() Globals.IgnoredTargetIDs:add(xtarg.ID()) end
                end

                Ui.InvisibleWithButtonText("##ig_btn_" .. tostring(i), Icons.MD_CLOSE, ImVec2(ICON_SIZE, ImGui.GetTextLineHeight()), clickFn)

                if not sessionHit then
                    ImGui.PopStyleColor()
                end

                local min = ImGui.GetItemRectMinVec()
                local max = ImGui.GetItemRectMaxVec()
                local draw = ImGui.GetWindowDrawList()
                draw:AddRect(min, max, IM_COL32(180, 180, 180, 180), 0.5)
                ImGui.PopStyleVar(1)

                if denyHit and not sessionHit and xtarg.ID() ~= Globals.ForceTargetID and xtarg.ID() ~= Globals.ForceCombatID then
                    Ui.Tooltip("This target is denied on the Spawns tab. Force-targeting will engage it anyway.")
                end
            end,
        },
        {
            name = "NH",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
            width = 16.0,
            sort = function(a, b)
                return Globals.NoHateTargetIDs:contains(a.ID()) and 1 or 0, Globals.NoHateTargetIDs:contains(b.ID()) and 1 or 0
            end,
            render = function(xtarg, i)
                local checked = Globals.NoHateTargetIDs:contains(xtarg.ID())
                ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))

                if not checked then
                    ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(52, 52, 52, 0))
                end

                Ui.InvisibleWithButtonText("##nh_btn_" .. tostring(i), Icons.FA_BAN, ImVec2(ICON_SIZE, ImGui.GetTextLineHeight()),
                    function()
                        if checked then
                            Globals.NoHateTargetIDs:remove(xtarg.ID())
                        else
                            Globals.NoHateTargetIDs:add(xtarg.ID())
                        end
                    end)

                if not checked then
                    ImGui.PopStyleColor()
                end

                local min = ImGui.GetItemRectMinVec()
                local max = ImGui.GetItemRectMaxVec()
                local draw = ImGui.GetWindowDrawList()
                draw:AddRect(min, max, IM_COL32(180, 180, 180, 180), 0.5)
                ImGui.PopStyleVar(1)
            end,
        },
        {
            name = "XT",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 16.0,
            sort = function(a, b)
                return a.Name() and (Ui.TempSettings.SortedXTIDToSlot[a.ID()].Slot or 0) or 0, b.Name() and (Ui.TempSettings.SortedXTIDToSlot[b.ID()].Slot or 0) or 0
            end,
            render = function(xtarg, i)
                Ui.RenderText(xtarg.Name() and (Ui.TempSettings.SortedXTIDToSlot[xtarg.ID()].Slot or "") or "")
            end,
        },
        {
            name = "Name",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultSort),
            width = ImGui.GetWindowWidth() - 300,
            sort = function(a, b)
                return a.CleanName() or "None", b.CleanName() or "None"
            end,
            render = function(xtarg, i)
                local conColor = ImVec4(Ui.GetConColorBySpawn(xtarg))
                local name = xtarg.CleanName() or "None"
                ImGui.PushID(string.format("##select_forcetarget_%d", i))
                Ui.RenderColorWaveText(name, conColor, function()
                    local newId = Globals.ForceTargetID == xtarg.ID() and 0 or xtarg.ID()
                    Globals.SetForcedTargetId(newId)
                    Logger.log_debug("Forcing Target to: %s %d", newId == 0 and "None" or xtarg.CleanName(), newId)
                end, (not Config:GetSetting('FTRollTargetName') or xtarg.ID() ~= mq.TLO.Target.ID()))
                ImGui.PopID()
            end,
        },
        {
            name = "HP %",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
            width = 80.0,
            sort = function(a, b)
                return math.ceil(a.PctHPs() or 0), math.ceil(b.PctHPs() or 0)
            end,
            render = function(xtarg, _)
                local hpPct = math.ceil(xtarg.PctHPs() or 0)
                if Config:GetSetting('FTUseBars') then
                    Ui.RenderFancyHPBar("FTHPBar" .. tostring(xtarg.ID()), hpPct, ImGui.GetTextLineHeight(), nil, 0, 4)
                else
                    Ui.RenderColoredText(Ui.GetPercentageColor(hpPct, { Colors.LightYellow, Colors.Yellow, Colors.Orange, }), tostring(hpPct) and "%d%%" or "", tostring(hpPct))
                end
            end,
        },
        {
            name = "Aggro %",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
            width = 80.0,
            sort = function(a, b)
                return math.ceil(a.PctAggro() or 0), math.ceil(b.PctAggro() or 0)
            end,
            render = function(xtarg, _)
                local aggroPct = math.ceil(xtarg.PctAggro() or 0)
                local IAmMA = Core.IAmMA()
                if Config:GetSetting('FTUseBars') then
                    Ui.RenderAnimatedPercentage("FTAggroBar" .. tostring(xtarg.ID()), aggroPct, ImGui.GetTextLineHeight(), 0, IAmMA and Colors.Orange or Colors.LightGreen,
                        IAmMA and Colors.LightGreen or Colors.Orange, string.format("%d%%", aggroPct), 0, 4)
                else
                    Ui.RenderColoredText(
                        Ui.GetPercentageColor(aggroPct, IAmMA and { Colors.LightGreen, Colors.Yellow, Colors.Orange, } or { Colors.Orange, Colors.Yellow, Colors.LightGreen, }),
                        aggroPct and "%d" or "", aggroPct)
                end
            end,
        },
        {
            name = "Distance",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed),
            width = 80.0,
            sort = function(a, b)
                return math.ceil(a.Distance() or 0), math.ceil(b.Distance() or 0)
            end,
            render = function(xtarg, _)
                Ui.RenderText(tostring(math.ceil(xtarg.Distance() or 0)))
            end,
        },
        {
            name = "SpawnID",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 80.0,
            sort = function(a, b)
                return a.ID(), b.ID()
            end,
            render = function(xtarg, _)
                Ui.RenderText(tostring(math.ceil(xtarg.ID() or 0)))
            end,

        },
        {
            name = "Level",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(a, b)
                return a.Level() or 0, b.Level() or 0
            end,
            render = function(xtarg, _)
                Ui.RenderText(tostring(math.ceil(xtarg.Level() or 0)))
            end,

        },
        {
            name = "Class",
            flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultHide),
            width = 40.0,
            sort = function(a, b)
                return a.Class.ShortName() or "", b.Class.ShortName() or ""
            end,
            render = function(xtarg, _)
                local shortName = xtarg.Class.ShortName()
                if Globals.Constants.AllClassesSet:contains(shortName) then
                    Ui.RenderText(shortName)
                else
                    Ui.RenderColoredText(Colors.Grey, "-")
                end
            end,
        },
    }

    Ui.RenderTableData("ForceTarget", tableColumns,
        bit32.bor(ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Sortable, ImGuiTableFlags
            .Hideable,
            ImGuiTableFlags.Reorderable),
        function(sort_specs)
            if Targeting.CrossDiffXTHaterIDs(Ui.TempSettings.SortedXTIDs:toList(), false) or true then
                Ui.TempSettings.SortedXT = {}
                Ui.TempSettings.SortedXTIDToSlot = {}
                Ui.TempSettings.SortedXTIDs = Targeting.GetXTHaterIDsSet(true)
                local xtCount = mq.TLO.Me.XTarget() or 0
                for i = 1, xtCount do
                    local xtarg = mq.TLO.Me.XTarget(i)
                    if xtarg and xtarg.ID() > 0 and (xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater" or xtarg.ID() == Globals.ForceTargetID) and
                        Ui.TempSettings.SortedXTIDToSlot[xtarg.ID()] == nil and not xtarg.Dead() then
                        table.insert(Ui.TempSettings.SortedXT, xtarg)
                        Ui.TempSettings.SortedXTIDToSlot[xtarg.ID()] = { Name = xtarg.CleanName() or "None", Slot = i, ID = xtarg.ID(), }
                    end
                end
                if sort_specs then sort_specs.SpecsDirty = true end
            end

            if sort_specs and sort_specs.SpecsDirty then
                table.sort(Ui.TempSettings.SortedXT, function(a, b)
                    local spec = sort_specs:Specs(1) -- single-column sort

                    local col = spec.ColumnIndex

                    local av, bv = tableColumns[col + 1].sort(a, b)

                    if spec.SortDirection == ImGuiSortDirection.Ascending then
                        return (av or 0) < (bv or 0)
                    else
                        return (av or 0) > (bv or 0)
                    end
                end)
            end

            sort_specs.SpecsDirty = false
        end,
        function()
            local cellPadding = ImGui.GetStyle().CellPadding
            local windowPadding = ImGui.GetStyle().WindowPadding
            if ImGui.TableSetColumnIndex(0) then
                ImGui.SameLine()
                Ui.RenderText("     ")
                Ui.Tooltip("Click here to set forced target.")
            end

            if ImGui.TableSetColumnIndex(1) then
                ImGui.SameLine()
                Ui.RenderText("     ")
                Ui.Tooltip("Click here to ignore this target this session; a gray X marks a persistent deny, managed on the Spawns tab.")
            end

            if ImGui.TableSetColumnIndex(2) then
                ImGui.SameLine()
                Ui.RenderText("     ")
                Ui.Tooltip("Click here to prevent using hate abilities on this target.")
                ImGui.TableNextRow()
            end

            local style = ImGui.GetStyle()
            local scrollbarW = style.ScrollbarSize + style.ItemSpacing.x
            local win_pos = ImGui.GetWindowPosVec()
            local win_min = win_pos
            local win_max = win_pos + ImGui.GetWindowSizeVec()
            local hasScrollbar = ImGui.GetScrollMaxY() > 0
            local effectiveWidth = win_max.x - (hasScrollbar and scrollbarW or 0)

            for i, xtarg in ipairs(Ui.TempSettings.SortedXT) do
                ImGui.PushID(string.format("##xtarg_%d", i))
                if xtarg.ID() > 0 then
                    local checked = Globals.ForceTargetID > 0 and Globals.ForceTargetID == xtarg.ID()
                    ImGui.TableNextRow()

                    local rowStartX, rowStartY
                    for colIdx, colData in ipairs(tableColumns) do
                        ImGui.TableNextColumn()
                        if colIdx == 1 then
                            local screenPosVec = ImGui.GetCursorScreenPosVec()
                            rowStartX = screenPosVec.x
                            rowStartY = screenPosVec.y - cellPadding.y
                        end

                        colData.render(xtarg, i)
                    end

                    if checked and rowStartX then
                        local draw_list = ImGui.GetForegroundDrawList()

                        local min = ImVec2(rowStartX, rowStartY)
                        local max = ImVec2(
                            rowStartX + (ImGui.GetWindowWidth() - ((windowPadding.x * 2))),
                            rowStartY + ImGui.GetTextLineHeight() + (cellPadding.y * 2)
                        )

                        win_max.x = effectiveWidth
                        draw_list:PushClipRect(win_min, win_max, true)
                        draw_list:AddRect(min, max, Globals.GetAlternatingColor(hlColorOne, hlColorTwo), 0.0, 0, 1.5)
                        draw_list:PopClipRect()
                    end

                    -- hp overlay
                    if Config:GetSetting('FTHPOverlay') then
                        local draw_list = ImGui.GetForegroundDrawList()

                        local min = ImVec2(rowStartX, rowStartY)
                        local max = ImVec2(
                            rowStartX + ((ImGui.GetWindowWidth() - ((windowPadding.x * 2)))) * (Targeting.GetTargetPctHPs(xtarg) / 100),
                            rowStartY + ImGui.GetTextLineHeight() + (cellPadding.y * 2)
                        )

                        win_max.x = effectiveWidth
                        draw_list:PushClipRect(win_min, win_max, true)
                        local r, g, b, a = Ui.GetConHighlightBySpawn(xtarg)

                        draw_list:AddRectFilled(
                            min,
                            max,
                            IM_COL32((math.floor(r) or 1) * 255, (math.floor(g) or 1) * 255, (math.floor(b) or 1) * 255,
                                (math.floor(a) or 1) * ((Targeting.GetAutoTarget().ID() or 0) == xtarg.ID() and 255 or math.floor(255 * Config:GetSetting('FTHPOverlayAlpha') / 100)))

                        )
                        draw_list:PopClipRect()
                    end
                end
                ImGui.PopID()
            end
        end)
end

--- Generic sortable table helper: sets up columns, calls sortFn with sort
--- specs, then calls rowFn to emit rows.
---@param tableName string ImGui table identifier.
---@param tableColumns table Array of column descriptors with name/flags/width fields.
---@param tableFlags number ImGuiTableFlags bitmask.
---@param sortFn function Called with current sort_specs; should sort data.
---@param rowFn function Called with no args; should emit ImGui table rows.
function Ui.RenderTableData(tableName, tableColumns, tableFlags, sortFn, rowFn)
    if ImGui.BeginTable(tableName, #tableColumns, tableFlags) then
        for id, data in ipairs(tableColumns) do
            ImGui.TableSetupColumn(data.name, data.flags, data.width, id - 1)
        end

        ImGui.TableHeadersRow()

        local sort_specs = ImGui.TableGetSortSpecs()

        sortFn(sort_specs)

        rowFn()

        ImGui.EndTable()
    end
end

--- Returns the texture animation to use as background for spell icon.
---@param spell MQSpell? Spell object to check type.
---@return any Texture animation (red, yellow, or blue spell background).
function Ui.GetBGForSpell(spell)
    if spell and spell() then
        if spell.SpellType() == "Detrimental" then
            if spell.PreventsRegen and not spell.PreventsRegen() then
                return yellowspellBg
            end
            return redspellBg
        elseif spell.SpellType() == "Beneficial" then
            return bluespellBg
        end
    end
    return bluespellBg
end

--- Draws an inspectable spell icon that opens the spell inspector on click.
---@param spell MQSpell Spell object providing type/name for background and inspect.
---@param iconSize number? Icon width/height in pixels; defaults to ICON_SIZE.
---@param doBlink boolean? If true, enables blink animation when the spell is active.
---@param borderCol number? IM_COL32 color for an optional border around the icon.
function Ui.DrawInspectableSpellIcon(spell, iconSize, doBlink, borderCol)
    if not iconSize then iconSize = ICON_SIZE end

    local iconID = spell.SpellIcon()
    local alpha = 1.0
    if doBlink then
        local animId = ImHashStr(tostring(iconID) .. (spell.Name() or "?") .. "_blink")
        local dt = Ui.GetDeltaTime()
        alpha = 0.5 - ImAnim.Oscillate(animId, 0.5, 1.0, IamWaveType.Sawtooth, 0.0, dt)
    end

    local sp = ImGui.GetCursorScreenPosVec()
    local dl = ImGui.GetWindowDrawList()

    animspellIcons:SetTextureCell(iconID or 0)

    dl:AddTextureAnimation(Ui.GetBGForSpell(spell), sp, ImVec2(iconSize, iconSize))
    dl:AddTextureAnimation(animspellIcons, ImVec2(sp.x + 2, sp.y + 2), ImVec2(iconSize - 4, iconSize - 4))

    if borderCol then
        dl:AddRect(sp, sp + ImVec2(iconSize, iconSize), borderCol, 0, ImDrawFlags.None, 0.5)
    end

    if doBlink then
        dl:AddRectFilled(sp, ImVec2(sp.x + iconSize, sp.y + iconSize),
            IM_COL32(0, 0, 0, math.floor((1.0 - alpha) * 255)))
    end

    ImGui.PushID(tostring(iconID) .. (spell.Name() or "?") .. "_invis_btn")
    ImGui.InvisibleButton(spell.Name() or "?", ImVec2(iconSize, iconSize),
        bit32.bor(ImGuiButtonFlags.MouseButtonLeft))
    if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then
        spell.RankName.Inspect()
    end
    ImGui.PopID()
end

--- Renders the spell loadout table (gem, icon, var name, level, rank name).
---@param loadoutTable table Map of gem slot → { spell, selectedSpellData } entries.
function Ui.RenderLoadoutTable(loadoutTable)
    if ImGui.BeginTable("Spells", 5, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Icon', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Gem', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Var Name', (ImGuiTableColumnFlags.WidthFixed), 150.0)
        ImGui.TableSetupColumn('Level', ImGuiTableColumnFlags.None)
        ImGui.TableSetupColumn('Rank Name', ImGuiTableColumnFlags.None)
        ImGui.TableHeadersRow()

        for gem, loadoutData in pairs(loadoutTable) do
            ImGui.TableNextColumn()
            Ui.DrawInspectableSpellIcon(loadoutData.spell)
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(gem))
            ImGui.TableNextColumn()
            Ui.RenderText(loadoutData.selectedSpellData.name or "")
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(loadoutData.spell.Level()))
            ImGui.TableNextColumn()
            local _, clicked = ImGui.Selectable(loadoutData.spell.RankName())
            if clicked then
                loadoutData.spell.RankName.Inspect()
            end
        end

        ImGui.EndTable()
    end
end

--- Renders a legend table explaining the icons used in the rotation table.
function Ui.RenderRotationTableKey()
    Ui.RenderText("On the previous check, the...")
    if ImGui.BeginTable("Rotation_table_key", 2, ImGuiTableFlags.Borders) then
        ImGui.TableNextColumn()
        Ui.RenderText(Icons.MD_CHECK .. ": Rotation Processed (Conditions Met)")

        ImGui.TableNextColumn()
        Ui.RenderText(Icons.MD_CLOSE .. ": Rotation was Skipped (Conditions Not Met)")

        ImGui.TableNextColumn()
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
        Ui.RenderText(Icons.FA_SMILE_O .. ": Entry Effect was Active")

        ImGui.PopStyleColor()
        ImGui.TableNextColumn()

        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
        Ui.RenderText(Icons.MD_CHECK .. ": Entry Conditions Passed")

        ImGui.PopStyleColor()
        ImGui.TableNextColumn()

        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
        Ui.RenderText(Icons.FA_EXCLAMATION .. ": Entry Conditions Failed")

        ImGui.PopStyleColor()
        ImGui.TableNextColumn()

        Ui.RenderText(Icons.MD_INFO_OUTLINE .. " Special Note on Conditions " .. Icons.MD_INFO_OUTLINE)
        Ui.Tooltip("The icons above are only updated when the checks are made, and will display the previous results until they are checked again.\n" ..
            "Note that in addition to special entry conditions, some other checks occur that could prevent an action from being used, such as movement, control effects, mana costs, etc.")

        ImGui.EndTable()
    end
end

--- Renders the rotation table for the named rotation section.
---@param name string Rotation section name (used as table ID).
---@param rotationTable table Array of rotation entry descriptors.
---@param resolvedActionMap table Map of entry name → resolved spell/AA/item.
---@param rotationState number? Current step index (>0 shows a "Cur" column).
---@param enabledRotationEntries table Map of entry name → bool (false = skip).
---@param hideRotationCols boolean? If true, hides the "Cur" and "Condition Met" columns.
---@param reorderable boolean? If true, allows the user to reorder entries in this table.
---@return table enabledRotationEntries Updated enablement map.
---@return boolean changed True if any enablement setting was toggled this frame.
---@return boolean reordered True if an entry was reordered this frame.
---@return boolean resetRequested True if the user reset this list to default order this frame.
function Ui.RenderRotationTable(name, rotationTable, resolvedActionMap, rotationState, enabledRotationEntries, hideRotationCols, reorderable)
    local enabledRotationEntriesChanged = false
    local showDebugTiming = Config:GetSetting('ShowDebugTiming')
    local pendingSwap = nil
    local pendingDrag = nil
    local resetRequested = false
    local function persistRotationOrder()
        local order = Config:GetSetting('RotationEntryOrder') or {}
        local names = {}
        for _, e in ipairs(rotationTable or {}) do names[#names + 1] = e.name end
        order[name] = names
        Config:SetSetting('RotationEntryOrder', order)
    end

    -- non-rotation callers (mez/charm) drive their own resolvers, so the rotation-only Cur ("-") and always-red "Condition Met" columns are noise - let them hide both
    local numCols = (hideRotationCols and 4 or 6) + (showDebugTiming and 1 or 0) + (reorderable and 1 or 0)
    local resolvedColIdx = hideRotationCols and 3 or 5

    if ImGui.BeginTable("Rotation_" .. name, numCols, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('ID', ImGuiTableColumnFlags.WidthFixed, 20.0)
        if not hideRotationCols then
            ImGui.TableSetupColumn(rotationState > 0 and 'Cur' or '-', ImGuiTableColumnFlags.WidthFixed, 20.0)
        end
        ImGui.TableSetupColumn('Enable', ImGuiTableColumnFlags.WidthFixed, 30.0)
        if not hideRotationCols then
            ImGui.TableSetupColumn('Condition Met', ImGuiTableColumnFlags.WidthFixed, 20.0)
        end
        ImGui.TableSetupColumn('Action', ImGuiTableColumnFlags.WidthStretch, 250.0)
        --- Resolved Action column: header drawn manually below
        ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthStretch, 250.0);

        if showDebugTiming then
            ImGui.TableSetupColumn('Timing', ImGuiTableColumnFlags.WidthStretch, 250.0)
        end
        if reorderable then
            ImGui.TableSetupColumn("##reorder", ImGuiTableColumnFlags.WidthFixed, 55.0)
        end

        ImGui.TableHeadersRow()

        -- Manually draw header cell content for Resolved Action Column
        if ImGui.TableSetColumnIndex(resolvedColIdx) then
            ImGui.SameLine()
            Ui.RenderText("Resolved Action ")
            ImGui.SameLine()
            Ui.RenderText(Icons.MD_INFO_OUTLINE)
            Ui.Tooltip("Click a resolved action to inspect the spell/item/AA effect.")
        end

        if reorderable and ImGui.TableSetColumnIndex(numCols - 1) then
            Ui.RenderText(Icons.MD_INFO_OUTLINE)
            Ui.Tooltip(
                "WARNING: In some cases rotations are carefully crafted and reordering entries may result in suboptimal conditions (or even broken entries).\nPlease tread carefully.")
            if (Config:GetSetting('RotationEntryOrder') or {})[name] then
                ImGui.SameLine()
                if ImGui.SmallButton(Icons.MD_REFRESH .. "##reset_" .. name) then
                    local order = Config:GetSetting('RotationEntryOrder') or {}
                    order[name] = nil
                    Config:SetSetting('RotationEntryOrder', order)
                    resetRequested = true
                end
                Ui.Tooltip("Reset this list to its default order.")
            end
        end

        for idx, entry in ipairs(rotationTable or {}) do
            ImGui.TableNextRow()
            local mappedAction = resolvedActionMap[entry.name]
            local typeLower = entry.type:lower()
            local resolvedItem = nil
            local isResolved = true
            if typeLower == "spell" or typeLower == "song" or typeLower == "disc" then
                isResolved = mappedAction ~= nil
            elseif typeLower == "aa" then
                isResolved = mq.TLO.Me.AltAbility((type(mappedAction) == "string") and mappedAction or entry.name)() ~= nil
            elseif typeLower == "item" then
                resolvedItem = mq.TLO.FindItem("=" .. ((type(mappedAction) == "string") and mappedAction or entry.name))
                isResolved = (resolvedItem() and resolvedItem.Clicky()) and true or false
            elseif typeLower == "ability" then
                isResolved = mq.TLO.Me.Ability(entry.name)() and true or false
            end
            if not isResolved then ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 0.5) end
            ImGui.TableNextColumn()
            if reorderable then
                ImGui.Selectable(string.format("%d##rotdrag_%s_%d", idx, name, idx), false,
                    bit32.bor(ImGuiSelectableFlags.SpanAllColumns, ImGuiSelectableFlags.AllowOverlap))
                if ImGui.BeginDragDropSource() then
                    ImGui.SetDragDropPayload("ROT_REORDER_" .. name, idx)
                    ImGui.Text(entry.name)
                    ImGui.EndDragDropSource()
                end
                if ImGui.BeginDragDropTarget() then
                    local payload = ImGui.AcceptDragDropPayload("ROT_REORDER_" .. name)
                    if payload then pendingDrag = { payload.Data, idx, } end
                    ImGui.EndDragDropTarget()
                end
            else
                Ui.RenderText(tostring(idx))
            end
            if not hideRotationCols then
                if rotationState > 0 then
                    ImGui.TableNextColumn()
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                    if idx == rotationState then
                        Ui.RenderText(Icons.FA_DOT_CIRCLE_O)
                    end
                    ImGui.PopStyleColor()
                else
                    ImGui.TableNextColumn()
                end
            end
            ImGui.TableNextColumn()
            if isResolved then
                local changed = false
                enabledRotationEntries[entry.name], changed = Ui.RenderOptionToggle(string.format("rot_%s_tggl_%d", name, idx), "",
                    enabledRotationEntries[entry.name] == nil and true or enabledRotationEntries[entry.name])
                if changed then enabledRotationEntriesChanged = true end
            else
                if enabledRotationEntries[entry.name] == false then
                    enabledRotationEntries[entry.name] = true
                    enabledRotationEntriesChanged = true
                end
                ImGui.BeginDisabled(true)
                local dimGreen = Globals.Constants.Colors.Green
                Ui.RenderFancyToggle(string.format("rot_%s_tggl_%d", name, idx), "", true, ImVec2(26, 14),
                    ImVec4(dimGreen.x, dimGreen.y, dimGreen.z, 0.35), Globals.Constants.Colors.Red, Globals.Constants.Colors.Grey, true, false, true, nil)
                ImGui.EndDisabled()
            end
            if not hideRotationCols then
                ImGui.TableNextColumn()
                local pass, active = false, false

                if entry.lastRun then
                    pass, active = entry.lastRun.pass, entry.lastRun.active
                end

                if active == true then
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                    Ui.RenderText(Icons.FA_SMILE_O)
                elseif pass == true then
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                    Ui.RenderText(Icons.MD_CHECK)
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                    Ui.RenderText(Icons.FA_EXCLAMATION)
                end
                ImGui.PopStyleColor()
                if entry.tooltip then
                    Ui.Tooltip(entry.tooltip)
                end
            end

            ImGui.TableNextColumn()
            if enabledRotationEntries[entry.name] == false then Ui.StrikeThroughText(entry.name) else Ui.RenderText(entry.name) end
            ImGui.TableNextColumn()
            if typeLower == "spell" or typeLower == "song" or typeLower == "disc" then
                if isResolved then
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Purple)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Globals.Constants.Colors.NearBlack)
                    local rankSpell = mappedAction.RankName
                    local _, clicked = ImGui.Selectable(rankSpell())
                    if clicked then
                        rankSpell.Inspect()
                    end
                    ImGui.PopStyleColor(2)
                    Ui.Tooltip(string.format("%s: %s (click to inspect)", entry.type, rankSpell() or "Unknown"))
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Red)
                    Ui.RenderText("No %s Detected", entry.type)
                    ImGui.PopStyleColor()
                end
            elseif typeLower == "aa" then
                local aaName = (type(mappedAction) == "string") and mappedAction or entry.name
                if isResolved then
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.LightBlue)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Globals.Constants.Colors.NearBlack)
                    local _, clicked = ImGui.Selectable(aaName)
                    local aaSpell = mq.TLO.Me.AltAbility(aaName).Spell
                    if aaSpell() and clicked then
                        aaSpell.Inspect()
                    end
                    ImGui.PopStyleColor(2)
                    Ui.Tooltip(string.format("AA Spell: %s (click to inspect)", aaSpell.Name() or "Unknown"))
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Red)
                    Ui.RenderText("No AA Detected")
                    ImGui.PopStyleColor()
                end
            elseif typeLower == "item" then
                local itemName = (type(mappedAction) == "string") and mappedAction or entry.name
                if isResolved then
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.LightOrange)
                    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Globals.Constants.Colors.NearBlack)
                    local _, clicked = ImGui.Selectable(itemName)
                    local clickySpell = resolvedItem.Clicky.Spell
                    if clickySpell() and clicked then
                        clickySpell.Inspect()
                    end
                    ImGui.PopStyleColor(2)
                    Ui.Tooltip(string.format("Clicky Spell: %s (click to inspect)", clickySpell.Name() or "Unknown"))
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Red)
                    Ui.RenderText("No Item Detected")
                    ImGui.PopStyleColor()
                end
            elseif typeLower == "ability" then
                if isResolved then
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.LightRed)
                    Ui.RenderText(entry.name)
                    ImGui.PopStyleColor()
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Red)
                    Ui.RenderText("No Ability Detected")
                    ImGui.PopStyleColor()
                end
            elseif typeLower == "customfunc" then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Yellow)
                Ui.RenderText(entry.desc or "Custom Function")
                ImGui.PopStyleColor()
            else
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Grey)
                if mappedAction and type(mappedAction) ~= "string" and mappedAction.Name then
                    Ui.RenderText(mappedAction.Name() or entry.name)
                else
                    Ui.RenderText(entry.name)
                end
                ImGui.PopStyleColor()
            end

            if Config:GetSetting('ShowDebugTiming') then
                ImGui.TableNextColumn()

                Ui.RenderText("C: %s RC: %s E: %s PF: %s T: %s",
                    Strings.FormatTimeMS((entry.lastCondTimeSpent or 0) * 1000),
                    Strings.FormatTimeMS((entry.lastRotationCondTimeSpent or 0) * 1000),
                    Strings.FormatTimeMS((entry.lastExecTimeSpent or 0) * 1000),
                    Strings.FormatTimeMS((entry.lastFollowTimeSpent or 0) * 1000),
                    Strings.FormatTimeMS((entry.lastTotalTimeSpent or 0) * 1000))
            end

            if not isResolved then ImGui.PopStyleVar() end
            if reorderable then
                ImGui.TableNextColumn()
                if idx > 1 then
                    ImGui.PushID(string.format("rot_%s_up_%d", name, idx))
                    if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then pendingSwap = { idx, idx - 1, } end
                    ImGui.PopID()
                else
                    ImGui.InvisibleButton("##rot_upspace_" .. idx, ImVec2(22, 1))
                end
                ImGui.SameLine()
                if idx < #rotationTable then
                    ImGui.PushID(string.format("rot_%s_dn_%d", name, idx))
                    if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then pendingSwap = { idx, idx + 1, } end
                    ImGui.PopID()
                else
                    ImGui.InvisibleButton("##rot_dnspace_" .. idx, ImVec2(22, 1))
                end
            end
        end

        ImGui.EndTable()
    end

    local reordered = false
    if pendingSwap and rotationTable then
        rotationTable[pendingSwap[1]], rotationTable[pendingSwap[2]] = rotationTable[pendingSwap[2]], rotationTable[pendingSwap[1]]
        persistRotationOrder()
        reordered = true
    end
    if pendingDrag and rotationTable and pendingDrag[1] ~= pendingDrag[2] then
        table.insert(rotationTable, pendingDrag[2], table.remove(rotationTable, pendingDrag[1]))
        persistRotationOrder()
        reordered = true
    end

    return enabledRotationEntries, enabledRotationEntriesChanged, reordered, resetRequested
end

--- Renders an animated fancy toggle switch with optional label and color options.
---@param id string Widget ID and label text.
---@param label string? Label text (separate from id when using right_label).
---@param value boolean Current toggle state.
---@param size ImVec2|number? Toggle size as ImVec2, or height (width = height*2).
---@param on_color ImVec4? Color when ON; defaults to FrameBgActive.
---@param off_color ImVec4? Color when OFF; defaults to FrameBg.
---@param knob_color ImVec4? Knob color; defaults to BrightWhite.
---@param right_label boolean? If true, renders label to the right of the toggle.
---@param pulse_on_hover boolean? If true, knob pulses when hovered.
---@param knob_border boolean? If true, draws a black border around the knob.
---@param center_vertically boolean? If true, centers the toggle in its row.
---@return boolean value
---@return boolean clicked
function Ui.RenderFancyToggle(id, label, value, size, on_color, off_color, knob_color, right_label, pulse_on_hover, knob_border, center_vertically)
    local dt = Ui.GetDeltaTime()
    local draw_list = ImGui.GetWindowDrawList()
    local pos = ImGui.GetCursorScreenPosVec()
    local row_pos = ImVec2(pos.x, pos.y)
    if not id or value == nil then return false, false end
    -- setup any defaults for mising params
    size = type(size) == 'number' and ImVec2(size * 2, size) or size or ImVec2(32, 16)
    local height = size.y or 16
    local width = size.x or height * 2
    local row_height = height
    on_color = on_color or ImGui.GetStyleColorVec4(ImGuiCol.FrameBgActive)
    off_color = off_color or ImGui.GetStyleColorVec4(ImGuiCol.FrameBg)
    knob_color = knob_color or Globals.Constants.Colors.BrightWhite -- default white
    label = label or ""
    local label_length = ImGui.CalcTextSize(label) + ImGui.GetStyle().ItemSpacing.x

    local clicked = false

    if not right_label and label and label:len() > 0 then
        local label_pos = ImVec2(pos.x, row_pos.y + (row_height - ImGui.GetTextLineHeight()) * 0.5)
        draw_list:AddText(label_pos, IM_COL32(200, 200, 210, 255), label)

        local text_len, _ = ImGui.CalcTextSize(label)
        pos.x = pos.x + text_len + ImGui.GetStyle().ItemSpacing.x
    end

    -- center it in the frame
    if center_vertically then
        pos.y = pos.y + (ImGui.GetFrameHeight() * 0.5) - (height * 0.5)
    end

    -- Switch position (on the left)
    local switch_pos = ImVec2(pos.x, row_pos.y + (((ImGui.GetStyle().ItemSpacing.y * 2))) * 0.5)

    -- Click handler
    ImGui.SetCursorScreenPos(switch_pos)

    local btn_id = "##toggle_" .. id
    if ImGui.InvisibleButton(btn_id, ImVec2(width, height)) then
        clicked = true
        value = not value
    end

    local hovered      = ImGui.IsItemHovered()

    -- Animate thumb position
    local target_thumb = value and 1.0 or 0.0
    local thumb_pos    = ImAnim.TweenFloat(ImHashStr(id), Ui.TempSettings.ThumbId, target_thumb, 0.45, ImAnim.EasePreset(IamEaseType.OutBack), IamPolicy.Crossfade, dt)

    -- Animate background color
    local bg_color     = ImAnim.TweenColor(ImHashStr(id), Ui.TempSettings.BgId, value and on_color or off_color, 0.2, ImAnim.EasePreset(IamEaseType.OutCubic), IamPolicy.Crossfade,
        IamColorSpace.OKLAB, dt)

    -- Draw track
    local track_radius = height * 0.5
    draw_list:AddRectFilled(switch_pos, ImVec2(switch_pos.x + width, switch_pos.y + height),
        ImGui.ColorConvertFloat4ToU32(bg_color), track_radius)

    -- Draw thumb
    local thumb_radius = height * 0.5 - 2.0
    local thumb_x = switch_pos.x + track_radius + thumb_pos * (width - height)
    local thumb_y = switch_pos.y + height * 0.5

    -- Thumb shadow
    draw_list:AddCircleFilled(ImVec2(thumb_x + 1, thumb_y + 2), thumb_radius, IM_COL32(0, 0, 0, 30))

    local final_knob_col = ImGui.GetColorU32(knob_color)

    local NUM_RINGS = 4

    if pulse_on_hover and hovered then
        Ui.InitDrawListClips()
        if not Ui.TempSettings.TogglePulseState[id] then
            Ui.TempSettings.TogglePulseState[id] = {
                ring_inst_ids = {
                    ImHashStr(id .. '_dl_ring_0'),
                    ImHashStr(id .. '_dl_ring_1'),
                    ImHashStr(id .. '_dl_ring_2'),
                    ImHashStr(id .. '_dl_ring_3'),
                },
                started = false,
            }
            for i = 1, NUM_RINGS do
                ImAnim.PlayStagger(CLIP_DL_RING, Ui.TempSettings.TogglePulseState[id].ring_inst_ids[i], i - 1)
            end
            Ui.TempSettings.TogglePulseState[id].started = true
        end
    end

    local thumb_center = ImVec2(thumb_x, thumb_y)

    if Config:GetSetting('DisableToggleButtonPulse') then
        pulse_on_hover = false
    end

    -- Pulse
    if pulse_on_hover and hovered and Ui.TempSettings.TogglePulseState[id] then
        for i = 1, NUM_RINGS do
            local radius, alpha = 10.0, 0.0
            local inst = ImAnim.GetInstance(Ui.TempSettings.TogglePulseState[id].ring_inst_ids[i])
            if inst:Valid() then
                radius = inst:GetFloat(CLIP_DL_CH_RADIUS)
                alpha = inst:GetFloat(CLIP_DL_CH_ALPHA)
            end

            if alpha > 0.01 then
                local pulse_col = Globals.Constants.Colors.TogglePulseColor
                local a = math.floor(alpha * 200)
                draw_list:AddCircle(thumb_center, radius, Ui.ImVec4ToColor(pulse_col))
            end
        end
    end

    -- Thumb
    draw_list:AddCircleFilled(thumb_center, thumb_radius, final_knob_col)

    -- Draw outline
    if knob_border then
        draw_list:AddCircle(thumb_center, thumb_radius, ImGui.GetColorU32(0, 0, 0, 1), 32, .5)
    end

    -- Label (on the right of the toggle)
    if right_label and label and label:len() > 0 then
        local label_pos = ImVec2(pos.x + width + 16, row_pos.y + (row_height - ImGui.GetTextLineHeight()) * 0.5)
        draw_list:AddText(label_pos, IM_COL32(200, 200, 210, 255), label)
    end

    ImGui.SetCursorScreenPos(ImVec2(pos.x + width + label_length, pos.y))
    ImGui.Dummy(ImVec2(0, 0))

    if label ~= "" then
        ImGui.NewLine()
    end

    return value, clicked
end

--[[
    * RenderFancyToggle
    * A toggle button that can be used to switch between two states (on/off) (true/false).
    * It can also display a star or moon shape as the knob.
    * The function takes various parameters to customize its appearance and behavior.
    * The function returns the updated value of the toggle and whether it was clicked.
    * some Flags you can pass in are ImGuiToggleFlags.StarKnob, ImGuiToggleFlags.RightLabel, ImGuiToggleFlags.AnimateKnob
    * The function also supports custom colors for the toggle button and knob.
    * The function can also animate the knob (roatating stars or a rocking moon).
    * The function can also display a label on the right side of the toggle button.
    * The function can also set the size of the toggle button (width, height) or just height and width will be defaulted to height * 2.0
    * The function can also set the number of points for the star knob (default 5).
    ]]
--- Renders the legacy (non-animated) fancy toggle switch.
---@param id string Widget ID and label text.
---@param label string? Label text (separate from id when using right_label).
---@param value boolean Current toggle state.
---@param size ImVec2|number? Toggle size as ImVec2, or height (width = height*2).
---@param on_color ImVec4? Color when ON; defaults to FrameBgActive.
---@param off_color ImVec4? Color when OFF; defaults to FrameBg.
---@param knob_color ImVec4? Knob color; defaults to BrightWhite.
---@param right_label boolean? If true, renders label to the right of the toggle.
---@param pulse_on_hover boolean? If true, knob pulses when hovered.
---@param knob_border boolean? If true, draws a black border around the knob.
---@param center_vertically boolean? If true, centers the toggle in its row.
---@return boolean value Updated toggle state.
---@return boolean changed True if the state changed this frame.
function Ui.RenderFancyToggleOld(id, label, value, size, on_color, off_color, knob_color, right_label, pulse_on_hover, knob_border, center_vertically)
    if not id or value == nil then return false, false end
    -- setup any defaults for mising params
    size = type(size) == 'number' and ImVec2(size * 2, size) or size or ImVec2(32, 16)
    local height = size.y or 16
    local width = size.x or height * 2
    local clicked = false
    local draw_list = ImGui.GetWindowDrawList()
    local pos = ImGui.GetCursorScreenPosVec()

    -- center it in the frame
    if center_vertically then
        pos.y = pos.y + (ImGui.GetFrameHeight() * 0.5) - (height * 0.5)
    end

    on_color = on_color or ImGui.GetStyleColorVec4(ImGuiCol.FrameBgActive)
    off_color = off_color or ImGui.GetStyleColorVec4(ImGuiCol.FrameBg)
    knob_color = knob_color or Globals.Constants.Colors.White -- default white

    if not right_label and label and label:len() > 0 then
        Ui.RenderText(label)
        if ImGui.IsItemClicked() then
            value = not value
            clicked = true
        end
        ImGui.SameLine()
        local text_len, _ = ImGui.CalcTextSize(label)
        pos.x = pos.x + text_len + ImGui.GetStyle().ItemSpacing.x
    end

    local radius = height * 0.5

    -- clickable area
    ImGui.InvisibleButton(id, width, height)
    if ImGui.IsItemClicked() then
        value = not value
        clicked = true
    end

    -- detect hovering for applying hover effects
    local is_hovered = ImGui.IsItemHovered()
    local final_knob_col = ImGui.GetColorU32(knob_color)

    if pulse_on_hover and is_hovered then
        local pulse_strength = 0.5 + 0.5 * math.sin(Globals.GetTimeSeconds() * 4)
        if knob_color.x == 1 and knob_color.y == 1 and knob_color.z == 1 then
            -- Special case: white glows warm yellow
            local new_color = ImVec4(
                1,
                math.min(1, 1 - 0.2 * pulse_strength),
                math.min(1, 1 - 0.4 * pulse_strength),
                knob_color.w
            )
            final_knob_col = ImGui.GetColorU32(new_color)
        else
            local new_color = ImVec4(
                math.min(1, knob_color.x + pulse_strength * 0.4),
                math.min(1, knob_color.y + pulse_strength * 0.4),
                math.min(1, knob_color.z + pulse_strength * 0.4),
                knob_color.w
            )
            final_knob_col = ImGui.GetColorU32(new_color)
        end
    end

    local t = value and 1.0 or 0.0
    local knob_x = pos.x + radius + t * (width - height)
    local center = ImVec2(knob_x, pos.y + radius)
    local fill_radius = radius * 0.8

    -- Background
    draw_list:AddRectFilled(
        ImVec2(pos.x, pos.y),
        ImVec2(pos.x + width, pos.y + height),
        ImGui.GetColorU32(value and on_color or off_color),
        height * 0.5
    )

    draw_list:AddCircleFilled(
        center,
        fill_radius,
        final_knob_col,
        0
    )
    -- Draw outline
    if knob_border then
        draw_list:AddCircle(center, fill_radius, ImGui.GetColorU32(0, 0, 0, 1), 32, 2)
    end

    -- Label on the right side of the toggle
    if right_label and label and label ~= "" then
        ImGui.SameLine()
        Ui.RenderText(label)
        if ImGui.IsItemClicked() then
            value = not value
            clicked = true
        end
    end

    return value, clicked
end

--- Renders a toggle option in the UI.
---@param id string: The unique identifier for the toggle option.
---@param text string: The display text for the toggle option.
---@param on boolean: The current state of the toggle option (true for on, false for off).
---@param center_vertically boolean?: If true, centers the toggle vertically within its frame.
---@return boolean: state
---@return boolean: changed
function Ui.RenderOptionToggle(id, text, on, center_vertically)
    return Ui.RenderFancyToggle(id, text, on, ImVec2(26, 14), Globals.Constants.Colors.Green, Globals.Constants.Colors.Red, nil, true, true, true, center_vertically)
end

--- Renders a progress bar.
---@param pct number The percentage to fill the progress bar (0-100).
---@param width number The width of the progress bar.
---@param height number The height of the progress bar.
function Ui.RenderProgressBar(pct, width, height)
    local style = ImGui.GetStyle()
    local start_x, start_y = ImGui.GetCursorPos()
    local text = string.format("%d%%", pct * 100)
    local label_x, _ = ImGui.CalcTextSize(text)
    ImGui.ProgressBar(pct, width, height, "")
    local end_x, end_y = ImGui.GetCursorPos()
    ImGui.SetCursorPos(start_x + ((ImGui.GetWindowWidth() / 2) - (style.ItemSpacing.x + math.floor(label_x / 2))),
        start_y + style.ItemSpacing.y)
    Ui.RenderText(text)
    ImGui.SetCursorPos(end_x, end_y)
end

--- Returns a clamped per-frame delta time from ImGui (0.001–0.1 seconds).
---@return number Delta time in seconds.
function Ui.GetDeltaTime()
    local dt = ImGui.GetIO().DeltaTime
    if dt <= 0 then dt = 1.0 / 60.0 end
    if dt > 0.1 then dt = 0.1 end
    return dt
end

--- Renders an animated fill bar that smoothly tweens toward barPct.
---@param id string Unique widget ID used for animation state.
---@param barPct number Current fill percentage (0–100).
---@param height number Bar height in pixels.
---@param width number Bar width in pixels; 0 = fill available width.
---@param colLow ImVec4 Gradient color at the low/left end.
---@param colHigh ImVec4 Gradient color at the high/right end.
---@param label string? Optional text label rendered over the bar.
---@param borderThickness number? Border width in pixels (default 1).
---@param milestoneTicks number? Number of tick marks to draw (default 10).
---@return boolean True if the bar was clicked this frame.
function Ui.RenderAnimatedPercentage(id, barPct, height, width, colLow, colHigh, label, borderThickness, milestoneTicks)
    local targetPct = Math.Clamp(tonumber(barPct) or 0, 0, 100) / 100.0
    local dt = Ui.GetDeltaTime()
    local drawList = ImGui.GetWindowDrawList()
    borderThickness = borderThickness or 1.0
    milestoneTicks = milestoneTicks or 10

    if width == 0 then width = ImGui.GetContentRegionAvailVec().x end
    height = height or 16

    local animState = Ui.TempSettings.ProgBarAnimState[id]

    if not animState then
        -- First render: initialize with current target
        animState = { hashId = ImHashStr(id), lastTarget = targetPct, smoothPct = targetPct - 0.01, } -- needs to be slighly different so that the tween is initialized
        Ui.TempSettings.ProgBarAnimState[id] = animState
    end

    animState.lastRenderTime = Globals.GetTimeSeconds()

    if Globals.GetTimeSeconds() - Ui.TempSettings.LastAnimCleanupTime > 10 then
        for key, state in pairs(Ui.TempSettings.ProgBarAnimState) do
            if Globals.GetTimeSeconds() - (state.lastRenderTime or 0) > 30 then
                Ui.TempSettings.ProgBarAnimState[key] = nil
            end
        end
        Ui.TempSettings.LastAnimCleanupTime = Globals.GetTimeSeconds()
    end

    animState.smoothPct = ImAnim.TweenFloat(
        animState.hashId,
        Ui.TempSettings.SmoothPctId,
        targetPct,
        .5,
        ImAnim.EasePreset(IamEaseType.Linear),
        IamPolicy.Crossfade,
        dt,
        animState.smoothPct
    )

    ImGui.InvisibleButton(id, width, height)
    local min = ImGui.GetItemRectMinVec()
    local max = ImGui.GetItemRectMaxVec()
    local fillWidth = width * animState.smoothPct
    local fillMaxX = min.x + fillWidth
    local fillWidthTarget = width * targetPct
    local fillMaxTargetX = min.x + fillWidthTarget

    local innerMin = min + ImVec2(1, 1)
    local innerMax = max - ImVec2(1, 1)
    local fillMax = ImVec2(fillMaxX, max.y)
    local fillMaxTarget = ImVec2(fillMaxTargetX, max.y)
    local innerFillMax = fillMax - ImVec2(1, 1)
    local innerFillMaxTarget = fillMaxTarget - ImVec2(1, 1)

    -- Background shell
    local bgTop = IM_COL32(28, 30, 41, 247)
    local bgBottom = IM_COL32(10, 13, 20, 247)

    -- Dark background
    drawList:AddRectFilledMultiColor(
        innerMin, innerMax,
        bgTop, bgTop, bgBottom, bgBottom
    )

    drawList:AddRectFilled(
        innerMin,
        ImVec2(max.x - 1, min.y + math.max(2, height * 0.35)),
        IM_COL32(255, 255, 255, 14),
        3.0
    )

    if fillWidth > 0 then
        local colMid = ImAnim.GetBlendedColor(colLow, colHigh, animState.smoothPct, IamColorSpace.OKLAB)
        local edge = ImAnim.GetBlendedColor(colLow, colMid, animState.smoothPct / 0.5, IamColorSpace.OKLAB)

        if animState.smoothPct >= 0.5 then
            edge = ImAnim.GetBlendedColor(colMid, colHigh, (animState.smoothPct - 0.5) / 0.5, IamColorSpace.OKLAB)
        end

        local topLeft = ImGui.GetColorU32(colLow)
        local topRight = edge:ToImU32()
        local bottomLeft = topLeft
        local bottomRight = topRight

        local fillRounding = math.min(2.0, height * 0.5, fillWidth * 0.5)

        if fillMax.x > innerMin.x and fillMax.y > innerMin.y then
            local reduceAlphaPrimary = 0.7
            local reduceAlphaSecondary = 0.5
            if animState.smoothPct < targetPct then
                -- Growing: fill to current, then overlay the growing portion with a darker shade
                drawList:AddRectFilledMultiColor(
                    innerMin,
                    innerFillMax,
                    Ui.ReduceAlpha(topLeft, reduceAlphaPrimary), Ui.ReduceAlpha(topRight, reduceAlphaPrimary), Ui.ReduceAlpha(bottomRight, reduceAlphaPrimary),
                    Ui.ReduceAlpha(bottomLeft, reduceAlphaPrimary)
                )
                drawList:AddRectFilledMultiColor(
                    innerMin, innerFillMaxTarget, Ui.ReduceAlpha(topLeft, reduceAlphaSecondary), Ui.ReduceAlpha(topRight, reduceAlphaSecondary),
                    Ui.ReduceAlpha(bottomRight, reduceAlphaSecondary), Ui.ReduceAlpha(bottomLeft, reduceAlphaSecondary)
                )
            else
                -- Shrinking: fill to target, then overlay the shrinking portion with a darker shade
                drawList:AddRectFilledMultiColor(
                    innerMin, innerFillMaxTarget, Ui.ReduceAlpha(topLeft, reduceAlphaPrimary), Ui.ReduceAlpha(topRight, reduceAlphaPrimary),
                    Ui.ReduceAlpha(bottomRight, reduceAlphaPrimary),
                    Ui.ReduceAlpha(bottomLeft, reduceAlphaPrimary))
                drawList:AddRectFilledMultiColor(
                    innerMin, innerFillMax, Ui.ReduceAlpha(topLeft, reduceAlphaSecondary), Ui.ReduceAlpha(topRight, reduceAlphaSecondary),
                    Ui.ReduceAlpha(bottomRight, reduceAlphaSecondary), Ui.ReduceAlpha(bottomLeft, reduceAlphaSecondary))
            end

            local glossMaxY = math.min(innerMax.y, min.y + math.max(2, height * 0.45))

            drawList:AddRectFilledMultiColor(
                innerMin,
                ImVec2(innerFillMax.x, glossMaxY),
                IM_COL32(255, 255, 255, 14), IM_COL32(255, 255, 255, 8),
                IM_COL32(255, 255, 255, 2), IM_COL32(255, 255, 255, 8)
            )
        else
            drawList:AddRectFilled(
                min, fillMax,
                ImGui.GetColorU32(colLow),
                fillRounding)
        end
    end

    -- Segment ticks (10% each).
    for i = 1, milestoneTicks - 1 do
        local tx = min.x + (width * (i / milestoneTicks))
        local reached = tx <= (min.x + fillWidth)

        drawList:AddLine(
            ImVec2(tx - 1, min.y + 1),
            ImVec2(tx - 1, max.y - 1),
            IM_COL32(0, 0, 0, (reached and 0.3 or 0.15) * 255),
            1.0
        )
        drawList:AddLine(
            ImVec2(tx, min.y + 1),
            ImVec2(tx, max.y - 1),
            IM_COL32(255, 255, 255, (reached and 0.3 or 0.15) * 255),
            1.0
        )
    end

    if borderThickness > 0 then
        drawList:AddRect(
            min, max,
            IM_COL32(255, 255, 255, 255), 3.0, 0, borderThickness
        )
    end

    local text = label or string.format('%d%%', math.floor((targetPct * 100.0) + 0.5))
    local textW = ImGui.CalcTextSize(text)
    local textX = min.x + ((max.x - min.x - textW) * 0.5)
    local textY = min.y + ((height - ImGui.GetTextLineHeight()) * 0.5)
    drawList:AddText(ImVec2(textX + 1, textY + 1), IM_COL32(0, 0, 0, 230), text)
    drawList:AddText(ImVec2(textX, textY), IM_COL32(255, 255, 255, 255), text)

    return ImGui.IsItemClicked()
end

--- Renders an animated HP bar; adds a pulsing red glow when burning is true.
---@param id string Unique widget ID.
---@param hpPct number HP percentage (0–100).
---@param height number Bar height in pixels.
---@param burning boolean? If true, draws a red pulsing border around the bar.
---@param borderThickness number? Border width in pixels.
---@param milestoneTicks number? Number of milestone tick marks.
---@param hpLowOverride ImVec4? Override the low-end gradient color.
---@param hpHighOverride ImVec4? Override the high-end gradient color.
---@return boolean True if the bar was clicked this frame.
function Ui.RenderFancyHPBar(id, hpPct, height, burning, borderThickness, milestoneTicks, hpLowOverride, hpHighOverride)
    local now = Globals.GetTimeSeconds()
    local drawList = ImGui.GetWindowDrawList()

    local hpLow = hpLowOverride or Globals.Constants.Colors.HPLowColor
    local hpHigh = hpHighOverride or Globals.Constants.Colors.HPHighColor

    local clicked = Ui.RenderAnimatedPercentage(id, hpPct, height, 0, hpLow, hpHigh, nil, borderThickness, milestoneTicks)

    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()

    -- burn pulse
    if burning == true then
        local pulse = 0.5 + 0.5 * math.sin(now * 10.0)
        local glowA = (0.14 + (0.22 * pulse))
        drawList:AddRect(
            ImVec2(minX - 1, minY - 1),
            ImVec2(maxX + 1, maxY + 1),
            IM_COL32(255, 51, 51, glowA * 255),
            3.0,
            0,
            2.2
        )
    end

    return clicked
end

--- Renders an animated mana bar using the global mana low/high colors.
---@param id string Unique widget ID.
---@param hpPct number Mana percentage (0–100).
---@param height number Bar height in pixels.
---@param borderThickness number? Border width in pixels.
---@param milestoneTicks number? Number of milestone tick marks.
---@return boolean True if the bar was clicked this frame.
function Ui.RenderFancyManaBar(id, hpPct, height, borderThickness, milestoneTicks)
    return Ui.RenderAnimatedPercentage(id, hpPct, height, 0, Globals.Constants.Colors.ManaLowColor, Globals.Constants.Colors.ManaHighColor, nil, borderThickness, milestoneTicks)
end

--- Renders an animated progress bar with orange→green gradient and a label.
---@param id string Unique widget ID.
---@param pctComplete number Completion percentage (0–100).
---@param height number Bar height in pixels.
---@param label string? Optional text label rendered over the bar.
---@return boolean True if the bar was clicked this frame.
function Ui.RenderFancyProgressBar(id, pctComplete, height, label)
    return Ui.RenderAnimatedPercentage(id, pctComplete, height, 0, Globals.Constants.Colors.LightOrange, Globals.Constants.Colors.Green, label)
end

--- Renders a numerical option with a specified range and step.
---@param id string: The identifier for the option.
---@param text string: The display text for the option.
---@param cur number: The current value of the option.
---@param min number: The minimum value of the option.
---@param max number: The maximum value of the option.
---@param step number?: The step value for incrementing/decrementing the option.
---@return number   # input
---@return boolean  # changed
function Ui.RenderOptionNumber(id, text, cur, min, max, step)
    ImGui.PushID("##num_spin_" .. id)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, Globals.Constants.Colors.LightGrey)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, Globals.Constants.Colors.Grey)
    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.Grey)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, Globals.Constants.Colors.Black)
    ImGui.SetNextItemWidth(ImGui.GetContentRegionAvailVec().x)
    local input, changed = ImGui.InputInt(text, cur, step, 1, ImGuiInputTextFlags.None)
    ImGui.PopStyleColor(4)
    ImGui.PopID()

    min = min or 0
    max = max or 100

    input = tonumber(input) or 0
    if input > max then input = max end
    if input < min then input = min end

    changed = cur ~= input
    return input, changed
end

--- Renders a combo box with an inline search/filter input.
---@param id string Unique widget ID suffix.
---@param curIdx number Currently selected 1-based index.
---@param options string[] Array of option strings.
---@param hideText string? Items containing this substring are hidden.
---@return number Updated selected index.
---@return boolean True if the selection changed this frame.
function Ui.SearchableCombo(id, curIdx, options, hideText)
    local pressed = false

    if ImGui.BeginCombo("##combo_box" .. id, curIdx .. " : " .. (options[curIdx] or "None")) then
        -- Search box
        if ImGui.IsWindowAppearing() then
            ImGui.SetKeyboardFocusHere()
        end

        Ui.ComboFilterText[id] = ImGui.InputTextWithHint("##combo_search", "Search...", Ui.ComboFilterText[id])

        ImGui.Separator()

        -- List
        for i, item in ipairs(options) do
            local filterMatch = (Ui.ComboFilterText[id] == "" or (item:lower():find(Ui.ComboFilterText[id]:lower(), 1, true)) ~= nil)
            if (hideText == nil or (item:find(hideText) == nil)) and filterMatch then
                if ImGui.Selectable(i .. ": " .. item, i == curIdx) then
                    if curIdx ~= i then
                        curIdx = i
                        pressed = true
                        Ui.ComboFilterText[id] = ""
                        ImGui.CloseCurrentPopup()
                    end
                end
            end
        end
        ImGui.EndCombo()
    end

    return curIdx, pressed
end

--- Renders an invisible button with horizontally scrolling marquee text.
---@param text string Text to scroll inside the button.
---@param height number Button height in pixels.
---@param width number Button width in pixels.
---@return boolean True if the button was clicked this frame.
function Ui.MarqueeButton(text, height, width)
    -- Delta time and font scale
    local dt = Ui.GetDeltaTime() -- replace with your delta time function
    ---@diagnostic disable-next-line: undefined-field
    local scale = ImGui.GetIO().FontGlobalScale

    local draw_list = ImGui.GetWindowDrawList()
    local id = ImHashStr("##marquee_btn_" .. text)

    -- Persistent scroll value
    Ui.TempSettings.MarqueeScrollX[id] = Ui.TempSettings.MarqueeScrollX[id] or 0
    local scroll_x = Ui.TempSettings.MarqueeScrollX[id]

    scroll_x = scroll_x - dt * 25.0 * scale -- adjust speed by scale
    Ui.TempSettings.MarqueeScrollX[id] = scroll_x

    local text_size = ImGui.CalcTextSizeVec(text)

    -- Reset scroll when text goes off screen
    if scroll_x < -text_size.x then
        scroll_x = width
        Ui.TempSettings.MarqueeScrollX[id] = scroll_x
    end

    -- Get top-left position
    local pos = ImGui.GetCursorScreenPosVec()

    pos.y = pos.y + (ImGui.GetFrameHeight() * 0.5) - (height * 0.5)

    ImGui.InvisibleButton("##marquee_btn", ImVec2(width, height))
    local afterPos = ImGui.GetCursorScreenPosVec()
    -- Draw container background
    draw_list:AddRectFilled(
        pos,
        ImVec2(pos.x + width, pos.y + height),
        IM_COL32(40, 45, 55, 255),
        4 * scale
    )

    -- Clip text to container
    ImGui.PushClipRect(pos, ImVec2(pos.x + width, pos.y + height), true)
    draw_list:AddText(
        ImVec2(pos.x + scroll_x, pos.y + (height - ImGui.GetFontSize() * scale) * 0.5),
        IM_COL32(255, 255, 255, 255),
        text
    )
    ImGui.PopClipRect()

    -- Move cursor below container
    ImGui.SetCursorScreenPos(afterPos)

    return ImGui.IsItemClicked()
end

--- Draws grayed hint text over the last drawn (empty) input, scrolling it when too wide to fit.
---@param id string Unique key for the scroll state.
---@param text string Hint text to display.
function Ui.MarqueeHint(id, text)
    ---@diagnostic disable-next-line: undefined-field
    local scale = ImGui.GetIO().FontGlobalScale
    local draw_list = ImGui.GetWindowDrawList()
    local rectMin = ImGui.GetItemRectMinVec()
    local rectMax = ImGui.GetItemRectMaxVec()
    local pad = ImGui.GetStyle().FramePadding.x
    local width = rectMax.x - rectMin.x - pad * 2
    local textSize = ImGui.CalcTextSizeVec(text)
    local textY = rectMin.y + ((rectMax.y - rectMin.y) - ImGui.GetFontSize() * scale) * 0.5

    local scrollX = 0
    if textSize.x > width then
        scrollX = (Ui.TempSettings.MarqueeScrollX["hint_" .. id] or 0) - Ui.GetDeltaTime() * 25.0 * scale
        if scrollX < -textSize.x then scrollX = width end
        Ui.TempSettings.MarqueeScrollX["hint_" .. id] = scrollX
    end

    ImGui.PushClipRect(ImVec2(rectMin.x + pad, rectMin.y), ImVec2(rectMax.x - pad, rectMax.y), true)
    draw_list:AddText(ImVec2(rectMin.x + pad + scrollX, textY), IM_COL32(150, 150, 150, 255), text)
    ImGui.PopClipRect()
end

--- Renders a typed config option widget (Combo, Toggle, Color, number, etc.).
---@param type string Widget type: "Combo", "Toggle", "Color", "number", "string",
---   "ClickyItem", "ClickyItemWithConditions", "Custom", "SpellSlot", "ImVec2".
---@param setting any Current setting value.
---@param id string Unique widget ID.
---@param requiresLoadoutChange boolean? If true, a change triggers a loadout reload.
---@param ... any Extra args depending on type (e.g. options table for Combo).
---@return any Updated setting value.
---@return boolean True if the change requires a loadout reload.
---@return boolean True if any widget was interacted with this frame.
function Ui.RenderOption(type, setting, id, requiresLoadoutChange, ...)
    local args = { ..., }
    local new_loadout, any_pressed, pressed = false, false, false
    if type == "Combo" then
        -- build a combo box.
        ImGui.PushID("##combo_setting_" .. id)
        ---@type string[]
        local comboOptions = args[1]
        local hideText = args[2]
        ImGui.SetNextItemWidth(-1)
        --setting, pressed = ImGui.Combo("", setting, comboOptions)
        setting, pressed = Ui.SearchableCombo(id, setting, comboOptions, hideText)
        ImGui.PopID()
        new_loadout = ((pressed or false) and (requiresLoadoutChange or false))
        any_pressed = any_pressed or (pressed or false)
    elseif type == "ClickyItem" or type == "ClickyItemWithConditions" then
        -- make a drag and drop target
        ImGui.PushFont(ImGui.ConsoleFont)
        local itemName = type == "ClickyItemWithConditions" and setting.itemName or setting
        local nameLen = itemName:len()

        ImGui.PushID(id .. "__btn")
        local width = ImGui.GetContentRegionAvailVec().x - 30
        if Ui.MarqueeButton(nameLen > 0 and itemName or "[Drop Here]", 15, width) then
            if mq.TLO.Cursor() then
                if type == "ClickyItemWithConditions" then
                    setting.itemName = mq.TLO.Cursor.Name()
                else
                    setting = mq.TLO.Cursor.Name()
                end

                pressed = true
            end
        end
        ImGui.PopID()

        ImGui.PopFont()
        if nameLen > 0 then
            Ui.Tooltip(itemName)
        end

        ImGui.SameLine()
        ImGui.PushID(id .. "__clear_btn")
        if ImGui.SmallButton(Icons.MD_CLEAR) then
            if type == "ClickyItemWithConditions" then
                setting.itemName = ""
            else
                setting = ""
            end
            pressed = true
        end
        ImGui.PopID()
        Ui.Tooltip(string.format("Drop a new item here to replace\n%s", itemName))

        new_loadout = new_loadout or
            ((pressed or false) and (requiresLoadoutChange or false))
        any_pressed = any_pressed or (pressed or false)
    elseif type == 'Color' then
        local skipDefaultButton = args[1] or false
        ImGui.PushID("##color_setting_" .. id)
        ImGui.SetNextItemWidth(-1)
        local newSetting
        newSetting, pressed = ImGui.ColorEdit4("", Tables.TableToImVec4(setting) or ImVec4(0, 0, 0, 0), ImGuiColorEditFlags.NoInputs + ImGuiColorEditFlags.NoLabel)
        setting = newSetting and Tables.ImVec4ToTable(newSetting) or setting
        if not skipDefaultButton then
            ImGui.SameLine()
            if ImGui.SmallButton("Default##reset_color_" .. id) then
                setting = Tables.ImVec4ToTable(Globals.Constants.DefaultColors[id])
                pressed = true
            end
        else

        end
        ImGui.PopID()
        new_loadout = new_loadout or ((pressed or false) and (requiresLoadoutChange or false))
        any_pressed = any_pressed or (pressed or false)
    elseif type == 'ImVec2' then
        ImGui.PushID("##vec2_setting_" .. id)
        local intArray = { setting.x or 0, setting.y or 0, }
        local newSetting
        newSetting, pressed = ImGui.InputInt2("", intArray)
        setting = newSetting and { x = newSetting[1], y = newSetting[2], } or setting
        ImGui.PopID()
        new_loadout = new_loadout or ((pressed or false) and (requiresLoadoutChange or false))
        any_pressed = any_pressed or (pressed or false)
    elseif type == 'boolean' then
        setting, pressed = Ui.RenderOptionToggle(id, "", setting, true)
        new_loadout = new_loadout or ((pressed or false) and (requiresLoadoutChange or false))
        any_pressed = any_pressed or (pressed or false)
    elseif type == 'number' then
        setting, pressed = Ui.RenderOptionNumber(id, "", setting, args[1], args[2], args[3])
        new_loadout = new_loadout or ((pressed or false) and (requiresLoadoutChange or false))
        any_pressed = any_pressed or (pressed or false)
    elseif type == 'string' then -- display only
        ImGui.SetNextItemWidth(-1)
        setting, pressed = ImGui.InputText("##" .. id, setting)
        if (setting or "") == "" and (args[1] or "") ~= "" and not ImGui.IsItemActive() then
            Ui.MarqueeHint(id, args[1])
        end
        any_pressed = any_pressed or (pressed or false)
        if (setting or "") ~= "" then
            Ui.Tooltip(setting)
        end
    end

    return setting, new_loadout, any_pressed
end

--- Renders a small settings gear button that opens the options UI for moduleName.
---@param moduleName string The module whose settings tab should be highlighted.
function Ui.RenderSettingsButton(moduleName)
    if ImGui.SmallButton(Icons.MD_SETTINGS) then
        Config:OpenOptionsUIAndHighlightModule(moduleName)
    end
    Ui.Tooltip(string.format("Open the RGMercs Options with %s settings highlighted.", moduleName))
end

--- Renders aligned pop-out and settings buttons in the top-right of the window.
---@param moduleName string Module name used for pop-out/settings config keys.
---@return number Pixel padding consumed on the right side for button layout.
function Ui.RenderPopAndSettings(moduleName)
    -- The size wont change so I don't want to use CalcTextSize every frame
    local style = ImGui.GetStyle()
    local scrollBarVis = ImGui.GetScrollMaxY() > 0

    local paddingNeeded = 35 + style.FramePadding.x + (scrollBarVis and style.ScrollbarSize or 0)

    local cursorPos = ImGui.GetCursorPosVec()
    if Config:HaveSetting(moduleName .. "_Popped") then
        if not Config:GetSetting(moduleName .. "_Popped") then
            paddingNeeded = paddingNeeded + style.ItemSpacing.x + 35
            ImGui.SetCursorPos(ImVec2(cursorPos.x + (ImGui.GetWindowWidth() - paddingNeeded), cursorPos.y))
            Ui.RenderSettingsButton(moduleName)
            ImGui.SameLine()
            if ImGui.SmallButton(Icons.MD_OPEN_IN_NEW) then
                Config:SetSetting(moduleName .. "_Popped", not Config:GetSetting(moduleName .. "_Popped"))
                Config:GetSetting('EnableOptionsUI')
            end
            Ui.Tooltip(string.format("Pop the %s tab out into its own window.", moduleName))
            ImGui.NewLine()
        else
            ImGui.SetCursorPos(ImVec2(cursorPos.x + (ImGui.GetWindowWidth() - paddingNeeded), cursorPos.y))
            Ui.RenderSettingsButton(moduleName)
        end
        ImGui.SetCursorPos(cursorPos)
    else
        ImGui.SetCursorPos(ImVec2(cursorPos.x + (ImGui.GetWindowWidth() - paddingNeeded), cursorPos.y))
        Ui.RenderSettingsButton(moduleName)
    end

    return paddingNeeded
end

--- Renders a single theme config row (color var + color picker or style var + value).
---@param id number 1-based index in the UserTheme table.
---@param themeElement table Entry with { element, color } or { element, value }.
---@return boolean True if the element was modified this frame.
---@return boolean True if the delete button was pressed (element removed).
function Ui.RenderThemeConfigElement(id, themeElement)
    local setting = themeElement.element
    local any_pressed, delete_pressed = false, false

    if themeElement.color ~= nil then
        local settingNum, _, pressed = Ui.RenderOption("Combo", Ui.GetImGuiColorId(setting) + 1, tostring(id), false, Ui.ImGuiColorVars, "<Unused>")
        any_pressed = any_pressed or (pressed or false)

        ImGui.TableNextColumn()

        local settingColor, _, pressed = Ui.RenderOption("Color", themeElement.color, tostring(id) .. "_color", false, true)
        any_pressed = any_pressed or (pressed or false)

        if any_pressed then
            local userConfig = Config:GetSetting('UserTheme')
            userConfig[id].element = ImGui.GetStyleColorName((tonumber(settingNum) or 1) - 1)
            userConfig[id].color = settingColor
            Config:SetSetting('UserTheme', userConfig)
        end
    else
        local settingNum, _, pressed = Ui.RenderOption("Combo", Ui.GetImGuiStyleId(setting) + 1, tostring(id), false, Ui.ImGuiStyleVars, "<Unused>")
        any_pressed = any_pressed or (pressed or false)

        ImGui.TableNextColumn()

        -- if we changed the style var, we need to reset the value to default
        if pressed then
            local currentValue = ImGui.GetStyle()[Ui.ImGuiStyleVarNames[(tonumber(settingNum) or 1) - 1]]
            themeElement.value = type(currentValue) == 'number' and currentValue or Tables.ImVec2ToTable(currentValue)
        end

        local elementType = type(themeElement.value)
        if elementType ~= 'number' and elementType ~= 'table' then
            Ui.RenderText("Unsupported Type: %s", elementType)
            Logger.log_error("Unsupported theme element type '%s' for element '%s' %s", elementType, id, ImGui.GetStyle())
            return any_pressed, delete_pressed
        end

        local settingStyle, _, pressed = Ui.RenderOption(elementType == 'number' and 'number' or 'ImVec2', themeElement.value, id .. "_style")
        any_pressed = any_pressed or (pressed or false)
        if any_pressed then
            local userConfig = Config:GetSetting('UserTheme')
            userConfig[id].element = Ui.ImGuiStyleVarNames[(tonumber(settingNum) or 1) - 1]
            userConfig[id].value = settingStyle
            Config:SetSetting('UserTheme', userConfig)
        end
    end

    ImGui.SameLine()
    if ImGui.SmallButton(Icons.MD_DELETE .. "##delete_" .. id) then
        local userConfig = Config:GetSetting('UserTheme')
        table.remove(userConfig, id)
        Config:SetSetting('UserTheme', userConfig)
    end

    return any_pressed, delete_pressed
end

--- Renders the Themez import child window (combo + Import button + refresh).
function Ui.RenderImportThemez()
    if Ui.Themez == nil then
        return
    end

    ImGui.BeginChild("##themez_importer_child", ImVec2(0, 0), bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.AutoResizeY, ImGuiChildFlags.Borders),
        ImGuiWindowFlags.None)
    Ui.RenderText("Import from Themez: ")
    ImGui.SameLine()
    Ui.SelectedThemezImport, _ = Ui.SearchableCombo("import_themez", Ui.SelectedThemezImport, Ui.ThemezNames)
    ImGui.SameLine()
    if ImGui.SmallButton("Import") then
        local newUserTheme = Ui.ConvertFromThemez(Ui.SelectedThemezImport or "Default")

        Config:SetSetting('UserTheme', newUserTheme)
    end

    ImGui.SameLine()
    if ImGui.SmallButton(Icons.FA_REFRESH) then
        Ui.LoadThemez()
    end
    Ui.Tooltip("Reload MyThemeZ.lua")

    ImGui.EndChild()
end

--- Opens the modal text-input popup and registers a callback for the result.
---@param title string Popup window title (doubles as ImGui popup ID).
---@param prompt string? Text displayed above the input field.
---@param initText string? Initial value pre-filled in the input field.
---@param callbackFn function? Called with the entered text when Ok is pressed.
function Ui.OpenModal(title, prompt, initText, callbackFn)
    Ui.ModalCallbackFn = callbackFn
    Ui.ModalText       = initText
    Ui.ModalPrompt     = prompt or ""
    Ui.ModalTitle      = title or Ui.ModalTitle
    ImGui.OpenPopup(Ui.ModalTitle)
end

--- Renders the modal popup set by OpenModal; must be called every frame.
function Ui.RenderPopupModal()
    ImGui.SetNextWindowSize(320, 0, ImGuiCond.Appearing)
    if ImGui.BeginPopupModal(Ui.ModalTitle, nil, bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoDecoration, ImGuiWindowFlags.AlwaysAutoResize)) then
        Ui.RenderText("Theme Name:")
        ImGui.Spacing()

        -- Auto-focus input on open
        if ImGui.IsWindowAppearing() then
            ImGui.SetKeyboardFocusHere()
        end

        -- Input field
        local pressed = false
        Ui.ModalText, pressed = ImGui.InputText("##UiPopupModalInput", Ui.ModalText, bit32.bor(ImGuiInputTextFlags.EnterReturnsTrue))

        ImGui.Separator()

        -- Buttons
        if ImGui.Button("Ok") or pressed then
            if Ui.ModalCallbackFn then
                Ui.ModalCallbackFn(Ui.ModalText)
            end
            Ui.ModalCallbackFn = nil
            ImGui.CloseCurrentPopup()
        end

        ImGui.SameLine()

        if ImGui.Button("Cancel") then
            ImGui.CloseCurrentPopup()
            Ui.ModalCallbackFn = nil
            Ui.ModalText = ""
        end

        ImGui.EndPopup()
    end
end

--- Renders the RGMercs theme importer child window (load, save, refresh).
function Ui.RenderImportMercThemes()
    ImGui.BeginChild("##mercs_themes_importer_child", ImVec2(0, 0), bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.AutoResizeY, ImGuiChildFlags.Borders),
        ImGuiWindowFlags.None)
    Ui.RenderText("Import from File: ")
    ImGui.SameLine()
    Ui.SelectedMercThemeImport, _ = Ui.SearchableCombo("import_merc_themes", Ui.SelectedMercThemeImport, Ui.MercThemeNames)
    ImGui.SameLine()
    if ImGui.SmallButton("Load") then
        local newUserTheme = Ui.MercThemes[Ui.MercThemeNames[Ui.SelectedMercThemeImport] or "Default"]

        Config:SetSetting('UserTheme', newUserTheme)
    end

    ImGui.SameLine()
    if ImGui.SmallButton("Save") then
        Ui.OpenModal("Save Theme", "Theme Name:", string.format("Exported Theme: %s", os.date("%Y-%m-%d %H:%M:%S")), function(themeName)
            local userTheme = Config:GetSetting('UserTheme')
            if userTheme then
                --local themeName = string.format("Saved %s", os.date("%Y-%m-%d %H:%M:%S"))
                Ui.MercThemes[themeName] = userTheme
                Logger.log_debug("Saved current UserTheme to Themez as '%s'", themeName)
                Ui.SaveThemes()
                Ui.LoadMercThemes()
            else
                Logger.log_error("Failed to save current UserTheme to Themez.")
            end
        end)
    end
    Ui.Tooltip("Save current theme")

    Ui.RenderPopupModal()

    ImGui.SameLine()
    if ImGui.SmallButton(Icons.FA_REFRESH) then
        Ui.LoadMercThemes()
    end
    Ui.Tooltip("Reload themes file")

    ImGui.EndChild()
end

--- Renders the full Theme Config panel (importers + per-element color/style rows).
---@param searchFilter string? If non-empty, hides the panel unless it matches.
function Ui.RenderThemeConfig(searchFilter)
    local renderWidth = 325
    local windowWidth = ImGui.GetWindowWidth()
    local numCols     = math.max(1, math.floor(windowWidth / renderWidth))
    local category    = "UserTheme"

    if not Ui.ThemeConfigMatchesFilter(searchFilter) then
        return
    end

    local overrideClass, changed = Ui.RenderOptionToggle("OverrideClassTheme", "Override Class Theme Colors", Config:GetSetting('UserThemeOverrideClassTheme'), true)
    if changed then
        Config:SetSetting('UserThemeOverrideClassTheme', overrideClass)
    end

    local disableClass, changed = Ui.RenderOptionToggle("DisableClassTheme", "Disable Class Theme Colors", Config:GetSetting('DisableClassTheme'), true)
    if changed then
        Config:SetSetting('DisableClassTheme', disableClass)
    end

    ImGui.NewLine()

    ImGui.SeparatorText("Importers & Generators")

    if ImGui.SmallButton("Reset Theme to Default") then
        Config:SetSetting('UserTheme', {})
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Import Current Class Theme") then
        local userTheme = Tables.DeepCopy(Modules:ExecModule("Class", "GetTheme") or {})
        for _, element in ipairs(userTheme) do
            if element.element ~= nil then
                local newElementName = element.color ~= nil and Ui.GetImGuiColorId(element.element) or Ui.GetImGuiStyleId(element.element)
                if newElementName ~= nil then
                    element.element = newElementName
                end
                if element.color and element.color.r ~= nil then
                    element.color = Tables.TableRGBAToXYZW(element.color)
                end
            end
        end
        Config:SetSetting('UserTheme', userTheme)
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Randomize Theme") then
        local randomTheme = {}
        for _, v in ipairs(Ui.ImGuiColorVars) do
            if v:len() > 0 then
                table.insert(randomTheme, { element = v, color = { x = math.random(), y = math.random(), z = math.random(), w = 1.0, }, })
            end
        end
        Logger.log_debug("Generated a random theme with %d colors", #randomTheme)
        Config:SetSetting('UserTheme', randomTheme)
    end
    Ui.Tooltip("Randomizes all colors in the theme. Warning: May be hard to read!")

    ImGui.NewLine()

    Ui.RenderImportMercThemes()

    ImGui.NewLine()

    Ui.RenderImportThemez()

    ImGui.NewLine()

    ImGui.SeparatorText("Theme Customization")

    if ImGui.SmallButton("Add New Color") then
        local userTheme = Config:GetSetting('UserTheme') or {}
        table.insert(userTheme, {
            element = "Text",
            color = { x = 1, y = 1, z = 1, w = 1, },
        })
        Config:SetSetting('UserTheme', userTheme)
    end

    ImGui.SameLine()

    if ImGui.SmallButton("Add New Style") then
        local userTheme = Config:GetSetting('UserTheme') or {}
        table.insert(userTheme, {
            element = 'WindowPadding',
            value = Tables.ImVec2ToTable(ImGui.GetStyle().WindowPadding),
        })
        Config:SetSetting('UserTheme', userTheme)
    end

    local userTheme = Tables.DeepCopy(Config:GetSetting('UserTheme') or {})

    ImGui.SeparatorText("Colors")
    if ImGui.BeginChild("themechild_colors_" .. category, ImVec2(0, 0), bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.AutoResizeY), ImGuiWindowFlags.None) then
        if ImGui.BeginTable("themelements_" .. (category), 2 * numCols, ImGuiTableFlags.Borders) then
            for _ = 1, numCols do
                ImGui.TableSetupColumn('Option', (ImGuiTableColumnFlags.WidthFixed), 180.0)
                ImGui.TableSetupColumn('Set', (ImGuiTableColumnFlags.WidthFixed), 130.0)
            end

            for idx, themeElement in ipairs(userTheme) do
                if themeElement.color ~= nil then
                    ImGui.TableNextColumn()
                    Ui.RenderThemeConfigElement(idx, themeElement)
                end
            end

            ImGui.EndTable()
        end
    end
    ImGui.EndChild()

    ImGui.SeparatorText("Styles")
    if ImGui.BeginChild("themechild_styles_" .. category, ImVec2(0, 0), bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.AutoResizeY), ImGuiWindowFlags.None) then
        if ImGui.BeginTable("themelements_" .. (category), 2 * numCols, ImGuiTableFlags.Borders) then
            for _ = 1, numCols do
                ImGui.TableSetupColumn('Option', (ImGuiTableColumnFlags.WidthFixed), 180.0)
                ImGui.TableSetupColumn('Set', (ImGuiTableColumnFlags.WidthFixed), 130.0)
            end

            for idx, themeElement in ipairs(userTheme) do
                if themeElement.color == nil then
                    ImGui.TableNextColumn()
                    Ui.RenderThemeConfigElement(idx, themeElement)
                end
            end

            ImGui.EndTable()
        end
    end
    ImGui.EndChild()
end

--- Returns true if searchFilter is empty or matches the "theme" category.
---@param searchFilter string? Filter string from the options search box.
---@return boolean True if the Theme Config panel should be displayed.
function Ui.ThemeConfigMatchesFilter(searchFilter)
    return (searchFilter or ""):len() == 0 or string.find("theme", searchFilter or "", 1, true) ~= nil
end

--- Renders the RGMercs logo quad, with a wobble/track animation when hovered.
---@param textureId any MQ texture handle to draw.
function Ui.RenderLogo(textureId)
    local afConfig = Config:GetSetting('EnableAFUI')
    local draw = ImGui.GetWindowDrawList()

    local mx, my = ImGui.GetMousePos()
    local cx, cy = ImGui.GetCursorScreenPos()
    local w, h = 60, 60

    local x1, y1 = 0, 0
    local x2, y2 = w, 0
    local x3, y3 = w, h
    local x4, y4 = 0, h

    ImGui.Dummy(ImVec2(60, 60))

    if afConfig or Config:GetSetting('123EyesOnMe') then
        local t = Ui.TempSettings.LogoMOTime and (Globals.GetTimeSeconds() / 100 - Ui.TempSettings.LogoMOTime) or 0
        t = t % 120
        local delta
        if t <= 59 then
            delta = -t
        else
            delta = -(119 - t)
        end
        cx, cy = cx + w * 0.5, cy + h * 0.5
        ---@diagnostic disable-next-line: deprecated --LuaJIT is based off of 5.1
        local angle = math.atan2(my - cy, mx - cx)

        w, h = math.max(1, w + delta), math.max(1, h + delta)
        local hw, hh = w * 0.5, h * 0.5

        x1, y1 = Math.Rotate(angle, -hw, -hh)
        x2, y2 = Math.Rotate(angle, hw, -hh)
        x3, y3 = Math.Rotate(angle, hw, hh)
        x4, y4 = Math.Rotate(angle, -hw, hh)

        if ImGui.IsItemHovered() then
            if not Ui.TempSettings.LogoMOTime then
                Ui.TempSettings.LogoMOTime = Globals.GetTimeSeconds() / 100
            end
        else
            Ui.TempSettings.LogoMOTime = nil
        end
    end

    draw:AddImageQuad(
        textureId,
        ImVec2(cx + x1, cy + y1),
        ImVec2(cx + x2, cy + y2),
        ImVec2(cx + x3, cy + y3),
        ImVec2(cx + x4, cy + y4),
        ImVec2(0, 0),
        ImVec2(1, 0),
        ImVec2(1, 1),
        ImVec2(0, 1)
    )
end

--- Renders formatted text via ImGui.Text, reversing it in April Fools mode.
---@param text string Format string (or plain text if no extra args).
---@param ... any Format arguments passed to string.format.
function Ui.RenderText(text, ...)
    -- only format if we have args
    local formattedText = tostring(text)
    if select('#', ...) > 0 then
        formattedText = string.format(text, ...)
    end
    local afConfig = Config:GetSetting('EnableAFUI')
    if afConfig then
        local startPos = ImGui.GetCursorScreenPosVec()
        local textSize = ImGui.CalcTextSizeVec(formattedText)
        local mousePos = ImGui.GetMousePosVec()
        if not (mousePos.x >= startPos.x and mousePos.x <= startPos.x + textSize.x and mousePos.y >= startPos.y and mousePos.y <= startPos.y + textSize.y) then
            formattedText = formattedText:reverse()
        end
    end
    ImGui.Text(formattedText or "")
end

--- Renders formatted colored text via ImGui.TextColored.
---@param color ImVec4|number Text color (ImVec4 or IM_COL32).
---@param text string Format string.
---@param ... any Format arguments passed to string.format.
function Ui.RenderColoredText(color, text, ...)
    local formattedText = tostring(text)
    if select('#', ...) > 0 then
        formattedText = string.format(text, ...)
    end
    local afConfig = Config:GetSetting('EnableAFUI')
    if afConfig then
        local startPos = ImGui.GetCursorScreenPosVec()
        local textSize = ImGui.CalcTextSizeVec(formattedText)
        local mousePos = ImGui.GetMousePosVec()
        if not (mousePos.x >= startPos.x and mousePos.x <= startPos.x + textSize.x and mousePos.y >= startPos.y and mousePos.y <= startPos.y + textSize.y) then
            formattedText = formattedText:reverse()
        end
    end
    ImGui.TextColored(color or IM_COL32(255, 255, 255, 255), formattedText or "")
end

--- Renders clickable hyperlink-style text that changes color on hover.
---@param text string The text to display.
---@param normalColor ImVec4|ImU32 Text color when not hovered.
---@param highlightColor ImVec4|ImU32 Text color when hovered.
---@param callback function? Called when the item is clicked.
function Ui.RenderHyperText(text, normalColor, highlightColor, callback)
    local version = Modules:ExecModule("Class", "GetVersionString")
    local startingPos = ImGui.GetCursorPosVec()
    if ImGui.InvisibleButton("###" .. text .. "__invisbutton", ImGui.CalcTextSize(version), ImGui.GetTextLineHeight()) then
        if callback then
            callback()
        end
    end
    ImGui.SameLine()
    local afConfig = Config:GetSetting('EnableAFUI')
    if afConfig then
        local startPos = ImGui.GetCursorPosVec()
        local textSize = ImGui.CalcTextSizeVec(text)
        local mousePos = ImGui.GetMousePosVec()
        if not (mousePos.x >= startPos.x and mousePos.x <= startPos.x + textSize.x and mousePos.y >= startPos.y and mousePos.y <= startPos.y + textSize.y) then
            text = text:reverse()
        end
    end
    ImGui.SetCursorPos(startingPos)
    ImGui.TextColored((ImGui.IsItemHovered() and highlightColor or normalColor) or IM_COL32(40, 40, 245, 255), text or "")
end

--- Generates a dynamic tooltip for a given spell action.
---@param action string The action identifier for the spell.
---@return string The generated tooltip for the spell.
function Ui.GetDynamicTooltipForSpell(action)
    local resolvedItem = Modules:ExecModule("Class", "GetResolvedActionMapItem", action)

    if not resolvedItem or not resolvedItem() then
        return string.format("Use %s Spell : %s\n\nThis Spell:\n%s", action, "None", "None")
    end

    return string.format("Use %s Spell : %s\n\nThis Spell:\n%s", action, resolvedItem() or "None",
        resolvedItem.Description() or "None")
end

--- Generates a dynamic tooltip for a given action.
---@param action string The action for which the tooltip is generated.
---@return string The generated tooltip for the specified action.
function Ui.GetDynamicTooltipForAA(action)
    local resolvedItem = mq.TLO.Spell(action)

    return string.format("Use %s Spell : %s\n\nThis Spell:\n%s", action, resolvedItem() or "None",
        resolvedItem.Description() or "None")
end

--- Interpolates across a color scale based on pct (100 = scale[1], 0 = scale[n]).
---@param pct number Percentage value (0–100).
---@param scale ImVec4[] Array of colors to interpolate across.
---@return ImVec4 The interpolated color for the given percentage.
function Ui.GetPercentageColor(pct, scale)
    local t = 1 - math.max(0, math.min(1, pct / 100.0))
    local n = #scale
    if n == 1 then return scale[1] end

    local scaled = t * (n - 1)
    local i = math.floor(scaled) + 1
    local f = scaled - (i - 1)

    local c1 = scale[i]
    local c2 = scale[math.min(i + 1, n)]

    return ImVec4(
        c1.x + (c2.x - c1.x) * f,
        c1.y + (c2.y - c1.y) * f,
        c1.z + (c2.z - c1.z) * f,
        1.0)
end

--- Get the con color based on the provided color value.
---@param color string The color value to determine the con color.
---@return number, number, number, number The corresponding con color in RGBA format
function Ui.GetConColor(color)
    if color then
        if color:lower() == "dead" then
            return 0.4, 0.4, 0.4, 0.8
        end

        if color:lower() == "grey" then
            return 0.6, 0.6, 0.6, 0.8
        end

        if color:lower() == "green" then
            return 0.02, 0.8, 0.2, 0.8
        end

        if color:lower() == "light blue" then
            return 0.02, 0.8, 1.0, 0.8
        end

        if color:lower() == "blue" then
            return 0.02, 0.4, 1.0, 1.0
        end

        if color:lower() == "yellow" then
            return 0.8, 0.8, 0.02, 0.8
        end

        if color:lower() == "red" then
            return 0.8, 0.2, 0.2, 0.8
        end
    end

    return 1.0, 1.0, 1.0, 1.0
end

--- Returns the EQ con color RGBA components for spawn, or "Dead" color if gone.
---@param spawn MQSpawn The spawn object for which to determine the con color.
---@return number, number, number, number The con color associated with the spawn.
function Ui.GetConColorBySpawn(spawn)
    if not spawn or not spawn or spawn.Dead() then return Ui.GetConColor("Dead") end

    return Ui.GetConColor(spawn.ConColor())
end

--- Returns the row-highlight RGBA components for spawn based on its con color.
---@param spawn MQSpawn The spawn object for which to determine the highlight color.
---@return number, number, number, number The highlight color associated with the spawn.
function Ui.GetConHighlightBySpawn(spawn)
    if not spawn or not spawn or spawn.Dead() then return Ui.GetConColor("Dead") end

    return Ui.GetConHighlight(spawn.ConColor())
end

--- Get the con color based on the provided color value.
---@param color string The color value to determine the con color.
---@return number, number, number, number The corresponding con color in RGBA format
function Ui.GetConHighlight(color)
    if color then
        if color:lower() == "dead" then
            return 0.4, 0.4, 0.4, 0.1
        end

        if color:lower() == "grey" then
            return 0.6, 0.6, 0.6, 0.3
        end

        if color:lower() == "green" then
            return 0.02, 0.8, 0.2, 0.3
        end

        if color:lower() == "light blue" then
            return 0.02, 0.8, 1.0, 0.3
        end

        if color:lower() == "blue" then
            return 0.02, 0.4, 1.0, 0.3
        end

        if color:lower() == "yellow" then
            return 0.8, 0.8, 0.02, 0.3
        end

        if color:lower() == "red" then
            return 0.8, 0.2, 0.2, 0.3
        end
    end

    return 1.0, 1.0, 1.0, 0.3
end

--- Checks if navigation is enabled for a given location.
---@param loc string The location to check, represented as a string with coordinates.
---@param navLocOverride string? Nav YXZ string to use for /nav if the loc text is not compatible with the nav command
function Ui.NavEnabledLoc(loc, navLocOverride)
    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Yellow)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Ui.ChangeColorAlpoha(Globals.Constants.Colors.Grey, 0.1))
    ImGui.PushStyleColor(ImGuiCol.HeaderActive, Ui.ChangeColorAlpoha(Globals.Constants.Colors.Green, 0.1))
    local navLoc = ImGui.Selectable(loc, false, ImGuiSelectableFlags.AllowDoubleClick)
    ImGui.PopStyleColor(3)
    if loc ~= "0,0,0" then
        if navLoc and ImGui.IsMouseDoubleClicked(0) then
            Movement:DoNav(false, "locYXZ %s", navLocOverride or loc)
        end

        Ui.Tooltip("Double click to Nav")
    end
end

--- Shows a tooltip when the previous item is hovered; supports animated mode.
---@param desc string|function Tooltip text, or a function returning the text.
---@param idoverride string? Override the animation ID used for the tooltip.
function Ui.Tooltip(desc, idoverride)
    if ImGui.IsItemHovered() then
        if type(desc) == "function" then
            desc = desc()
        end

        if Config:GetSetting('EnableAnimatedTooltips') then
            return Ui.AnimatedTooltip(idoverride or desc, desc)
        end

        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 25.0)
        Ui.RenderText(desc)
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

--- Renders an animated tooltip with fade-in and line-wrap, anchored to the item.
---@param id string|number Unique animation ID for this tooltip.
---@param desc string|table Tooltip text, or array of { text, color? } line entries.
function Ui.AnimatedTooltip(id, desc)
    local state = Ui.TempSettings.TooltipAnimationState
    local item_size = ImGui.GetItemRectSizeVec()
    local item_hovered = ImGui.IsItemHovered()

    local dt = Ui.GetDeltaTime()

    local draw_list = ImGui.GetForegroundDrawList()

    local min = ImGui.GetItemRectMinVec()
    local max = ImGui.GetItemRectMaxVec()

    if not id or id == "" then
        -- generate a reaonsable Id
        id = ImHashStr(string.format("tooltip_%d_%d", math.floor(min.x), math.floor(min.y)))
    else
        id = ImHashStr(tostring(id))
    end

    if Config:GetSetting('DrawTooltipDebugBox') then
        draw_list:AddRect(min, max, IM_COL32(40, 255, 40, 255), 0, ImDrawFlags.RoundCornersAll, 2.0)
    end

    local pos = min

    local item_center = ImVec2(pos.x + item_size.x * 0.5, pos.y + item_size.y * 0.1)
    local content_avail = ImGui.GetContentRegionAvailVec()
    local canvas_size = ImVec2(content_avail.x, 0)

    -- Draw tooltip
    if item_hovered then
        if state.was_hovered == id then
            state.tooltip_time = (state.tooltip_time or 0) + dt
        else
            state.tooltip_time = 0.0
            state.was_hovered = id
        end

        local hover_radius = 9.0
        local rounding     = ImGui.GetStyle().FrameRounding

        -- Animate with delay - smooth fade without bouncing/flickering (accessibility)
        local delay        = 0.15

        local anim_t       = math.max(0.0, math.min((state.tooltip_time - delay) / 0.2, 1.0))
        local ease_t       = ImAnim.EvalPreset(IamEaseType.OutCubic, anim_t) -- Smooth ease without overshoot

        if state.tooltip_time > delay then
            local anchor = ImVec2(item_center.x, item_center.y - hover_radius)
            local padding = ImVec2(12, 8)
            local text_size = ImVec2(0, 0)

            local MAX_TOOLTIP_WIDTH = ImGui.GetFontSize() * 20.0
            local wrappedLines = {}

            local function wrapText(text)
                local lh = ImGui.GetTextLineHeight()
                local lines = {}
                for rawLine in (text .. "\n"):gmatch("([^\n]*)\n") do
                    local line = ""
                    for word in rawLine:gmatch("%S+") do
                        local candidate = line == "" and word or (line .. " " .. word)
                        if ImGui.CalcTextSize(candidate) > MAX_TOOLTIP_WIDTH and line ~= "" then
                            lines[#lines + 1] = line
                            line = word
                        else
                            line = candidate
                        end
                    end
                    lines[#lines + 1] = line
                end
                local maxW = 0
                for _, l in ipairs(lines) do maxW = math.max(maxW, ImGui.CalcTextSize(l)) end
                return lines, maxW, #lines * lh
            end

            if type(desc) == "table" then
                local numLines = #desc
                for i, line in ipairs(desc) do
                    local render_width, render_height = 0, 0
                    if line.render then
                        render_width, render_height = line.render(nil, ImVec2(0, 0))
                    end
                    local txt = tostring(line.text or "")
                    local _, wrapW, wrapH = wrapText(txt)
                    local size = ImVec2(wrapW + render_width, math.max(ImGui.CalcTextSizeVec(txt).y, wrapH) + render_height)
                    local xLen = line.sameLine and (text_size.x + size.x) or size.x
                    xLen = xLen + (line.padAfter or 0)
                    text_size.x = math.max(text_size.x, xLen)
                    text_size.y = text_size.y + (line.sameLine and 0 or (size.y + (i == numLines and 0 or padding.y / 2)))
                end
                text_size.x = math.min(text_size.x, MAX_TOOLTIP_WIDTH)
            else
                local lineHeight = ImGui.GetTextLineHeight()
                for rawLine in (desc .. "\n"):gmatch("([^\n]*)\n") do
                    local line = ""
                    for word in rawLine:gmatch("%S+") do
                        local candidate = line == "" and word or (line .. " " .. word)
                        if ImGui.CalcTextSize(candidate) > MAX_TOOLTIP_WIDTH and line ~= "" then
                            table.insert(wrappedLines, line)
                            line = word
                        else
                            line = candidate
                        end
                    end
                    table.insert(wrappedLines, line)
                end
                local maxW = 0
                for _, l in ipairs(wrappedLines) do
                    maxW = math.max(maxW, ImGui.CalcTextSize(l))
                end
                text_size = ImVec2(maxW, #wrappedLines * lineHeight)
            end

            local tip_size = ImVec2(text_size.x + padding.x * 2, text_size.y + padding.y * 2)

            -- Position above with animation
            local y_offset = -tip_size.y - 10 + (1.0 - ease_t) * 10.0
            local tip_pos = ImVec2(anchor.x - tip_size.x * 0.5, math.floor(anchor.y + y_offset))

            -- Clamp to object
            if tip_pos.x < pos.x then
                tip_pos = ImVec2(pos.x, tip_pos.y)
            end

            if tip_pos.x + tip_size.x > pos.x + canvas_size.x then
                tip_pos = ImVec2(pos.x + canvas_size.x - tip_size.x, tip_pos.y)
            end

            -- Get display bounds
            local display_size = ImGui.GetWindowViewport().Size
            local margin = 4.0

            -- Clamp X to screen
            if tip_pos.x < margin then
                tip_pos = ImVec2(margin, tip_pos.y)
            end
            if tip_pos.x + tip_size.x > display_size.x - margin then
                tip_pos = ImVec2(display_size.x - tip_size.x - margin, tip_pos.y)
            end

            -- Clamp Y to screen (flip below item if tooltip would go off top)
            if tip_pos.y < margin then
                -- Not enough space above, render below instead
                local y_offset_below = hover_radius + 10 + (1.0 - ease_t) * 10.0
                tip_pos = ImVec2(tip_pos.x, anchor.y + y_offset_below)
            end
            if tip_pos.y + tip_size.y > display_size.y - margin then
                tip_pos = ImVec2(tip_pos.x, display_size.y - tip_size.y - margin)
            end


            local alpha = math.floor(255 * ease_t)
            local bgColor = IM_COL32(50, 54, 65, alpha)
            local borderColor = IM_COL32(250, 250, 250, alpha)

            -- Shadow
            draw_list:AddRectFilled(ImVec2(tip_pos.x + 2, tip_pos.y + 3),
                ImVec2(tip_pos.x + tip_size.x + 2, tip_pos.y + tip_size.y + 3),
                IM_COL32(0, 0, 0, math.floor(alpha / 4)), rounding)

            -- Background
            draw_list:AddRectFilled(tip_pos, ImVec2(tip_pos.x + tip_size.x, tip_pos.y + tip_size.y),
                bgColor, 6.0)

            draw_list:AddRect(tip_pos, ImVec2(tip_pos.x + tip_size.x, tip_pos.y + tip_size.y),
                borderColor, 6.0)

            -- Arrow
            local arrow_half       = 6

            -- Clamp arrow anchor X so it never gets close to rounded corners
            local clamped_anchor_x = math.max(tip_pos.x + rounding + arrow_half + 4,
                math.min(anchor.x, tip_pos.x + tip_size.x - rounding - arrow_half - 4))

            local flipped          = tip_pos.y > anchor.y
            local arrow_tip        = flipped and ImVec2(clamped_anchor_x, tip_pos.y - arrow_half) or ImVec2(clamped_anchor_x, tip_pos.y + tip_size.y + arrow_half)
            local arrow_left       = flipped and ImVec2(clamped_anchor_x - arrow_half, tip_pos.y) or ImVec2(clamped_anchor_x - arrow_half, tip_pos.y + tip_size.y)
            local arrow_right      = flipped and ImVec2(clamped_anchor_x + arrow_half, tip_pos.y) or ImVec2(clamped_anchor_x + arrow_half, tip_pos.y + tip_size.y)

            draw_list:AddTriangleFilled(arrow_left, arrow_right, arrow_tip, bgColor)
            draw_list:AddTriangle(arrow_left, arrow_right, arrow_tip, borderColor, 1)
            -- erase border line where arrow overlaps
            draw_list:AddTriangleFilled(ImVec2(arrow_left.x - 1, arrow_left.y - 1), ImVec2(arrow_right.x + 1, arrow_right.y - 1), ImVec2(arrow_tip.x, arrow_tip.y - 1), bgColor)

            -- Text
            if type(desc) == "table" then
                local lineHeight = padding.y
                local nextXOffset = padding.x
                for i, line in ipairs(desc) do
                    if line.render then
                        local width, height = line.render(draw_list, ImVec2(
                            tip_pos.x + nextXOffset,
                            tip_pos.y + lineHeight
                        ))
                        nextXOffset = nextXOffset + width + (line.padAfter or 0)
                        if i + 1 <= #desc and desc[i + 1].sameLine ~= true then
                            lineHeight = lineHeight + height + padding.y / 2
                            nextXOffset = padding.x
                        end
                    end

                    if line.text then
                        local col = line.color and Ui.ImVec4ToColor(line.color) or IM_COL32(220, 220, 230, alpha)
                        local txtLines, txtW, txtH = wrapText(tostring(line.text))
                        local ty = tip_pos.y + lineHeight
                        for _, tl in ipairs(txtLines) do
                            draw_list:AddText(ImVec2(tip_pos.x + nextXOffset, ty), col, tl)
                            ty = ty + ImGui.GetTextLineHeight()
                        end
                        nextXOffset = nextXOffset + txtW + (line.padAfter or 0)
                        if i + 1 <= #desc and desc[i + 1].sameLine ~= true then
                            lineHeight = lineHeight + txtH + padding.y / 2
                            nextXOffset = padding.x
                        end
                    end
                end
            else
                local lineHeight = ImGui.GetTextLineHeight()
                local ty = tip_pos.y + padding.y
                for _, l in ipairs(wrappedLines) do
                    draw_list:AddText(ImVec2(tip_pos.x + padding.x, ty), IM_COL32(220, 220, 230, alpha), l)
                    ty = ty + lineHeight
                end
            end
        end
    else
        if state.was_hovered == id then
            state.was_hovered = -1
            state.tooltip_time = 0.0
        end
    end
end

--- Shows a tooltip with multiple colored text segments when the item is hovered.
---@param lines table Array of { text=string, color=ImVec4?, sameLine=bool? } entries.
function Ui.MultilineTooltipWithColors(lines)
    if ImGui.IsItemHovered() then
        if Config:GetSetting('EnableAnimatedTooltips') then
            return Ui.AnimatedTooltip(lines[1].text, lines)
        end

        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 25.0)
        for _, line in ipairs(lines) do
            if line.sameLine then
                ImGui.SameLine()
            end
            if line.color then
                ImGui.PushStyleColor(ImGuiCol.Text, line.color)
            end

            if line.render then
                local width, height = line.render(ImGui.GetForegroundDrawList(), ImGui.GetCursorScreenPosVec())
                ImGui.Dummy(ImVec2(width, height))
                ImGui.SameLine()
            end

            Ui.RenderText(line.text)
            if line.color then
                ImGui.PopStyleColor()
            end
        end

        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

--- Renders a button composed of multiple colored text segments side-by-side.
---@param lines table Array of { text=string, color=ImVec4? } segments.
---@param addSpaces boolean? If true, inserts a space between each segment.
---@return boolean True if the button was clicked this frame.
function Ui.MultiColorSmallButton(lines, addSpaces)
    local fullText = ""
    for _, line in ipairs(lines) do fullText = fullText .. line.text .. (addSpaces and " " or "") end
    local size = ImGui.CalcTextSizeVec(fullText)
    local style = ImGui.GetStyle()
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(style.FramePadding.x, 0))
    ImGui.InvisibleButton(fullText, size)

    local hovered = ImGui.IsItemHovered()
    local active  = ImGui.IsItemActive()

    local buttonCol
    if active then
        buttonCol = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
    elseif hovered then
        buttonCol = ImGui.GetStyleColorVec4(ImGuiCol.ButtonHovered)
    else
        buttonCol = ImGui.GetStyleColorVec4(ImGuiCol.Button)
    end

    local min_x, min_y = ImGui.GetItemRectMin()
    local max_x, max_y = ImGui.GetItemRectMax()
    local draw_list    = ImGui.GetWindowDrawList()

    local defaultColor = ImGui.GetStyleColorVec4(ImGuiCol.Text)

    -- Background
    draw_list:AddRectFilled(
        ImVec2(min_x, min_y),
        ImVec2(max_x, max_y),
        buttonCol:ToImU32(),
        style.FrameRounding
    )

    fullText = ""
    for _, line in ipairs(lines) do
        if not line.color then line.color = defaultColor end
        local offset = ImGui.CalcTextSizeVec(fullText)

        draw_list:AddText(ImVec2(style.FramePadding.x + min_x + offset.x, min_y), Ui.ImVec4ToColor(line.color), line.text)
        fullText = fullText .. line.text .. (addSpaces and " " or "")
    end

    ImGui.PopStyleVar(1)

    return ImGui.IsItemClicked()
end

--- Renders a non-collapsible TreeNode styled as a CollapsingHeader.
---@param label string Header label text.
---@return boolean Always true (header is always expanded).
function Ui.NonCollapsingHeader(label)
    ImGui.TreeNodeEx(label, bit32.bor(ImGuiTreeNodeFlags.DefaultOpen,
        ImGuiTreeNodeFlags.Framed,
        ImGuiTreeNodeFlags.SpanAvailWidth,
        ImGuiTreeNodeFlags.NoTreePushOnOpen,
        ImGuiTreeNodeFlags.Leaf,
        ImGuiTreeNodeFlags.NoTreePushOnOpen))

    return true
end

--- Renders text as strikethrough
---@param text string The text to be displayed with strikethrough.
function Ui.StrikeThroughText(text)
    local textSizeVec = ImGui.CalcTextSizeVec(text)
    local cursorScreenPos = ImGui.GetCursorScreenPosVec()
    ImGui.PushStyleColor(ImGuiCol.Text, 0.6, 0.6, 0.6, 0.9)
    cursorScreenPos.y = cursorScreenPos.y + ((ImGui.GetTextLineHeightWithSpacing() - (ImGui.GetStyle().FramePadding.y)) / 2)
    ImGui.GetWindowDrawList():AddLine(cursorScreenPos, ImVec2(cursorScreenPos.x + textSizeVec.x, cursorScreenPos.y), IM_COL32(255, 255, 255, 255), 1.0)
    Ui.RenderText(text)
    ImGui.PopStyleColor()
end

--- Checks group/raid MA setup and writes a warning string to Config.TempSettings.
function Ui.GetAssistWarningString()
    local warningString
    if not Config:GetSetting('UseAssistList') then
        if mq.TLO.Raid.Members() == 0 and mq.TLO.Group() then
            if not mq.TLO.Group.MainAssist() then
                warningString = "Warning: NO GROUP MA ASSIGNED - PLEASE SET ONE!"
            elseif mq.TLO.Group.MainAssist.ID() == 0 then
                warningString = "Warning: GROUP MA NOT IN ZONE!"
            end
        elseif mq.TLO.Raid.Members() > 0 then
            if not mq.TLO.Raid.MainAssist(Config:GetSetting('RaidAssistTarget'))() then
                warningString = "Warning: NO RAID MA ASSIGNED - PLEASE SET ONE!"
            elseif mq.TLO.Raid.MainAssist(Config:GetSetting('RaidAssistTarget')).ID() == 0 then
                warningString = "Warning: SELECTED RAID MA NOT IN ZONE!"
            end
        end
    elseif #Config:GetSetting('AssistList') == 0 then
        warningString = "Warning: THE ASSIST LIST IS ENABLED, BUT THE LIST IS EMPTY!"
    end

    Config.TempSettings.AssistWarning = warningString
end

--- Renders an animated button that scales and color-tweens on hover/press.
---@param id string Unique animation ID for this button.
---@param text string Label text displayed centered on the button.
---@param size ImVec2 Button dimensions in pixels.
---@param callbackFn function? Called immediately when the button is pressed.
---@return boolean True if the button was pressed this frame.
function Ui.AnimatedButton(id, text, size, callbackFn)
    local dt = Ui.GetDeltaTime()
    local draw_list = ImGui.GetWindowDrawList()

    -- Button states
    local hovered = false
    local pressed = false

    local cursor = ImGui.GetCursorScreenPosVec()

    -- Primary Button (Scale + Color)
    local btn_pos = cursor

    ImGui.SetCursorScreenPos(btn_pos)
    ImGui.InvisibleButton('##btn_primary', size)
    hovered = ImGui.IsItemHovered()
    pressed = ImGui.IsItemClicked()
    local rounding = ImGui.GetStyle().FrameRounding

    if pressed and callbackFn then
        callbackFn()
    end

    -- Determine target scale
    local target_scale = 1.0
    if pressed then
        target_scale = 0.95
    elseif hovered then
        target_scale = 1.05
    end

    -- Animate scale
    local scale = ImAnim.TweenFloat(ImHashStr(id), ImHashStr(id .. "scale"), target_scale, 0.15, ImAnim.EasePreset(IamEaseType.OutBack), IamPolicy.Crossfade, dt)

    -- Animate color
    ImGui.GetStyleColorVec4(ImGuiCol.Button)
    local base_color = ImGui.GetStyleColorVec4(ImGuiCol.Button)
    local hover_color = ImGui.GetStyleColorVec4(ImGuiCol.ButtonHovered)
    local press_color = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
    local target_color = pressed and press_color or (hovered and hover_color or base_color)
    local color = ImAnim.TweenColor(ImHashStr(id), ImHashStr(id .. "color_id"), target_color, 0.2, ImAnim.EasePreset(IamEaseType.OutCubic), IamPolicy.Crossfade, IamColorSpace.OKLAB,
        dt)

    -- Draw scaled button
    local center = ImVec2(btn_pos.x + size.x * 0.5, btn_pos.y + size.y * 0.5)
    local half_size = ImVec2(size.x * 0.5 * scale, size.y * 0.5 * scale)
    draw_list:AddRectFilled(
        ImVec2(center.x - half_size.x, center.y - half_size.y),
        ImVec2(center.x + half_size.x, center.y + half_size.y),
        ImGui.ColorConvertFloat4ToU32(color), rounding)

    -- Text
    local text_x, text_y = ImGui.CalcTextSize(text)
    draw_list:AddText(ImVec2(center.x - text_x * 0.5, center.y - text_y * 0.5),
        IM_COL32(255, 255, 255, 255), text)

    ImGui.SetCursorScreenPos(ImGui.GetCursorScreenPosVec().x, cursor.y + 60)

    return pressed
end

--- Renders an invisible button then overlays text at the same cursor position.
---@param id string ImGui button ID.
---@param text string Text to draw over the invisible button area.
---@param size ImVec2? Button dimensions; defaults to ImVec2(1,1).
---@param callbackFn function? Called when the button is clicked.
function Ui.InvisibleWithButtonText(id, text, size, callbackFn)
    local buttonPos = ImGui.GetCursorPosVec()
    if ImGui.InvisibleButton(id, size or ImVec2(1, 1)) then
        if callbackFn then
            callbackFn()
        end
    end

    ImGui.SetCursorPos(buttonPos)

    Ui.RenderText(text)
end

--- Iterates all modules and renders any that are popped out into their own windows.
---@param flags number ImGuiWindowFlags bitmask applied to each popped window.
function Ui.RenderModulesPopped(flags)
    if not Config:SettingsLoaded() then return end

    for _, name in ipairs(Modules:GetModuleOrderedNames()) do
        if Config:GetSetting(name .. "_Popped", true) then
            if Modules:ExecModule(name, "ShouldRender") then
                if Config:GetSetting('PopoutWindowsLockWithMain') and Config:GetSetting('MainWindowLocked') then
                    flags = bit32.bor(flags, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize)
                end

                local open, show = ImGui.Begin(Ui.GetWindowTitle(name), true, flags)
                if show then
                    Modules:ExecModule(name, "Render")
                    ImGui.Dummy(ImVec2(0, 0))
                end
                ImGui.End()

                if not open then
                    Config:SetSetting(name .. "_Popped", false)
                end
            end
        end
    end
end

--- Returns an ImGui window title string with a per-character ID suffix if needed.
---@param title string Display title for the window.
---@param idOverride string? Override the ###id portion of the title.
---@return string Formatted window title string.
function Ui.GetWindowTitle(title, idOverride)
    if Config:GetSetting('SavePositionPerCharacter') then
        return string.format("%s###%s__%s_%s", title, idOverride or title, Globals.CurServer, Globals.CurLoadedChar)
    end

    return string.format("%s%s", title, idOverride and ('###' .. idOverride) or "")
end

--- Converts an ImVec4 (0–1 float components) to an IM_COL32 packed color.
---@param vec ImVec4 Color with x, y, z, w components in [0,1].
---@return number IM_COL32 packed ABGR integer.
function Ui.ImVec4ToColor(vec)
    return IM_COL32(math.floor(vec.x * 255), math.floor(vec.y * 255), math.floor(vec.z * 255), math.floor(vec.w * 255))
end

--- Returns a copy of color with the alpha channel replaced by newAlpha.
---@param color ImVec4 Source color.
---@param newAlpha number New alpha value in [0,1].
---@return ImVec4 New ImVec4 with the updated alpha.
function Ui.ChangeColorAlpoha(color, newAlpha)
    return ImVec4(color.x, color.y, color.z, newAlpha)
end

-- split text on \n then word-wrap any line wider than maxAllowedW
local function toastLines(message, maxAllowedW)
    local lines, maxW = {}, 0
    for segment in (message .. "\n"):gmatch("([^\n]*)\n") do
        local words = {}
        for w in segment:gmatch("%S+") do words[#words + 1] = w end
        if #words == 0 then
            lines[#lines + 1] = { text = "", w = 0, }
        else
            local current = words[1]
            for wi = 2, #words do
                local candidate = current .. " " .. words[wi]
                if ImGui.CalcTextSizeVec(candidate).x > maxAllowedW then
                    local lw = ImGui.CalcTextSizeVec(current).x
                    lines[#lines + 1] = { text = current, w = lw, }
                    if lw > maxW then maxW = lw end
                    current = words[wi]
                else
                    current = candidate
                end
            end
            local lw = ImGui.CalcTextSizeVec(current).x
            lines[#lines + 1] = { text = current, w = lw, }
            if lw > maxW then maxW = lw end
        end
    end
    return lines, maxW
end

--- Renders active toast notifications as floating cards; auto-dismisses stale ones.
---@param states table Array of active toast state objects (modified in-place).
---@param lingerTime number? Total display duration in seconds (min 2.5).
function Ui.RenderToastNotifications(states, lingerTime)
    local dt            = math.max(Ui.GetDeltaTime(), 0.01)
    local holdEnd       = 2.3
    lingerTime          = (lingerTime and lingerTime >= 2.5) and lingerTime or 2.5
    local fadeDur       = lingerTime - holdEnd

    local canvas_pos    = ImGui.GetCursorScreenPosVec()
    local content_avail = ImGui.GetContentRegionAvailVec()
    local canvas_size   = ImVec2(content_avail.x, 180)
    local draw_list     = ImGui.GetForegroundDrawList()
    local max_toast_w   = math.max(100, canvas_size.x - 32.0)

    for i = #states, 1, -1 do
        if not states[i].active then
            table.remove(states, i)
        elseif (os.time() - states[i].receivedTime) > (lingerTime * 10) then
            Logger.log_debug("Auto-dismissing toast from %s after %.1f seconds. Msg: %s", states[i].from or "Self", os.time() - states[i].receivedTime, states[i].message)
            table.remove(states, i)
        end
    end

    if #states == 0 then return end

    local line_h        = ImGui.GetFontSize() + 4.0
    local toast_spacing = 8.0
    local toast_pad_x   = 20.0
    local toast_pad_y   = 8.0
    local numToasts     = math.min(#states, 3)

    local text_max_w    = max_toast_w - toast_pad_x * 2

    local sep_h         = 1.0
    local sep_gap       = 4.0
    local from_extra_h  = line_h + sep_h + sep_gap * 2
    local fromLabel     = string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S", (states[1].receivedTime or 0)), states[1].from or "")

    -- pre-compute heights so we can stack from the bottom
    local heights       = {}
    for i = 1, numToasts do
        local s = states[i]
        local lines = s._lines
        if not lines then
            local lns, maxW = toastLines(s.message, text_max_w)
            s._lines        = lns
            local fromW     = ImGui.CalcTextSize(fromLabel)
            s._toast_w      = math.max(maxW, fromW) + toast_pad_x * 2
            lines           = lns
        end
        local fromH = from_extra_h
        heights[i] = #lines * line_h + toast_pad_y * 2 + fromH
    end

    -- total stack height, position base_y for the bottom toast
    local total_h = toast_pad_y
    for i = 1, numToasts do total_h = total_h + heights[i] + toast_spacing end
    local stack_base_y = canvas_pos.y - total_h

    local cursor_y = stack_base_y
    for i, state in ipairs(states) do
        if i > 3 then break end
        if state.active then
            if not state.animId then
                Ui.TempSettings.ToastNextId = Ui.TempSettings.ToastNextId + 1
                local tid                   = Ui.TempSettings.ToastNextId
                state.animId                = ImHashStr("toast_" .. tid)
                state.chSlide               = ImHashStr("toast_slide_" .. tid)
                state.chAlpha               = ImHashStr("toast_alpha_" .. tid)
            end

            -- only start sliding once the previous toast has fully slid in
            local prevDone = i == 1 or (states[i - 1].slide or 0) >= 0.99
            if not prevDone then
                break
            end

            local slideTarget = prevDone and 1.0 or 0.0
            local slide = ImAnim.TweenFloat(state.animId, state.chSlide, slideTarget, 0.6,
                ImAnim.EasePreset(IamEaseType.OutBack), IamPolicy.Crossfade, dt, 0.0)
            state.slide = slide

            -- only tick the linger timer once this toast has fully slid in
            if slide >= 0.99 then
                state.timer = state.timer + dt
            end

            local alphaTarget = state.timer >= holdEnd and 0.0 or 1.0
            local alpha = ImAnim.TweenFloat(state.animId, state.chAlpha, alphaTarget, fadeDur,
                ImAnim.EasePreset(IamEaseType.InQuad), IamPolicy.Crossfade, dt, 1.0)

            if state.timer >= lingerTime and alpha < 0.01 then
                state.active = false
            end

            if state.active then
                local toast_w = state._toast_w
                local toast_h = heights[i]
                local base_x  = canvas_pos.x + canvas_size.x - toast_w - 16.0
                local base_y  = cursor_y
                local x       = base_x + (1.0 - slide) * (toast_w + 32.0)
                local iAlpha  = math.floor(alpha * 255)

                -- click detection for toasts with a from field
                if state.from and ImGui.IsMouseClicked(0) then
                    local mx, my = ImGui.GetMousePos()
                    if mx >= x and mx <= x + toast_w and my >= base_y and my <= base_y + toast_h then
                        state.clicked = true
                        state.active  = false
                    end
                end

                -- background (brighten on hover if clickable)
                local bgAlpha = math.floor(alpha * 230)
                draw_list:AddRectFilled(ImVec2(x, base_y), ImVec2(x + toast_w, base_y + toast_h),
                    IM_COL32(40, 40, 50, bgAlpha), 6.0)

                -- accent bar — fade with alpha
                local accentCol = state.color or Ui.ImVec4ToColor(Globals.Constants.Colors.White)
                draw_list:AddRectFilled(ImVec2(x, base_y), ImVec2(x + 4.0, base_y + toast_h),
                    Ui.ReduceAlpha(accentCol, alpha), 6.0, ImDrawFlags.RoundCornersLeft)

                -- from header + separator
                local text_col = IM_COL32(255, 255, 255, iAlpha)
                local text_y   = base_y + toast_pad_y
                local from_col = IM_COL32(220, 180, 100, iAlpha)
                draw_list:AddText(ImVec2(x + toast_pad_x, text_y), from_col, fromLabel)
                text_y = text_y + line_h + sep_gap
                local sep_col = IM_COL32(180, 180, 180, math.floor(alpha * 80))
                draw_list:AddLine(ImVec2(x + toast_pad_x, text_y),
                    ImVec2(x + toast_w - toast_pad_x, text_y), sep_col, sep_h)
                text_y = text_y + sep_h + sep_gap

                local mx, my = ImGui.GetMousePos()
                if mx >= x and mx <= x + toast_w and my >= base_y and my <= base_y + toast_h then
                    if ImGui.IsMouseClicked(0) then
                        Comms.SendPeerDoCmd(state.peer, "/foreground")
                    end
                end

                -- text lines
                for li, line in ipairs(state._lines) do
                    draw_list:AddText(ImVec2(x + toast_pad_x, text_y + (li - 1) * line_h), text_col, line.text)
                end
            end

            cursor_y = cursor_y + heights[i] + toast_spacing
        end
    end
end

return Ui
