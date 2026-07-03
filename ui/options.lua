local mq                        = require('mq')
local Icons                     = require('mq.ICONS')
local Set                       = require("mq.Set")
local ImAnim                    = require('ImAnim')
local ImGui                     = require('ImGui')
local Comms                     = require('utils.comms')
local Config                    = require('utils.config')
local DBManagement              = require('utils.db_management')
local Globals                   = require("utils.globals")
local Logger                    = require('utils.logger')
local Modules                   = require('utils.modules')
local Tables                    = require('utils.tables')
local Ui                        = require('utils.ui')

local OptionsUI                 = { _version = '1.0', _name = "OptionsUI", _author = 'Derple', 'Algar', }
OptionsUI.__index               = OptionsUI
OptionsUI.selectedGroup         = "General"
OptionsUI.HighlightedCategories = Set.new({})
OptionsUI.HighlightedSettings   = Set.new({})
OptionsUI.configFilter          = ""
OptionsUI.lastSortTime          = 0
OptionsUI.lastHighlightTime     = 0
OptionsUI.selectedCharacter     = ""
OptionsUI.lastPeerUpdate        = 0
OptionsUI.bgImg                 = mq.CreateTexture(mq.TLO.Lua.Dir() .. "/rgmercs/extras/options_bg.png")
OptionsUI.ToastStates           = {}

function OptionsUI.LoadIcon(icon)
    return mq.CreateTexture(mq.TLO.Lua.Dir() .. "/rgmercs/extras/" .. icon .. ".png")
end

OptionsUI.Groups                = { --- Add a default of the same name for any key that has nothing in its table once these are finished
    {
        Name = "General",
        Description = "General and Misc Settings",
        Icon = Icons.FA_COGS,
        IconImage = OptionsUI.LoadIcon("settingsicon"),
        Headers = {
            { Name = 'Announcements',   Categories = { "Announcements", }, }, -- group announce stuff-- ui stuff
            { Name = 'Loot(Emu)',       Categories = { "Looting Script", "LNS", "SmartLoot", }, },
            { Name = 'Mercs Internals', Categories = { "Internals", }, },
            { Name = 'Misc',            Categories = { "Misc", }, },                                                -- ??? profit
            { Name = 'Uncategorized',   Categories = { "Uncategorized", },                      CatchAll = true, }, -- settings from custom configs that don't have proper group/header
        },
    },
    {
        Name = "Movement",
        Description = "Following, Medding, Pulling",
        Icon = Icons.MD_DIRECTIONS_RUN,
        IconImage = OptionsUI.LoadIcon("followicon"),
        Headers = {
            { Name = 'Following',  Categories = { "Chase", "Camp", }, },
            { Name = 'Meditation', Categories = { "Med Rules", "Med Thresholds", }, },
            { Name = 'Drag',       Categories = { "Drag", }, },
            {
                Name = 'Pulling',
                Categories = { "Pull Rules", "Distance", "Targets", "Puller Vitals", "Peer and Group Vitals", },
                RenderCategories = {
                    {
                        Render = function()
                            Modules:ExecModule("Pull", "RenderWatchCombo")
                        end,
                        Search = function(searchFilter)
                            return string.match("pull watch group", searchFilter:lower()) ~= nil
                        end,
                    },
                },
            },
        },
    },
    {
        Name = "Combat",
        Description = "Assisting, Positioning",
        Icon = Icons.FA_HEART,
        IconImage = OptionsUI.LoadIcon("swordicon"),
        Headers = {
            { Name = 'Targeting',   Categories = { "Targeting Behavior", "MA Target Selection", "Tank Target Selection", }, }, -- Auto engage, med break, stay on target, etc
            { Name = 'Assisting',   Categories = { "Assisting", }, },                                                          -- this will include pet and merc percentages/commands
            { Name = 'Positioning', Categories = { "General Positioning", "Tank Positioning", "Archery", }, },                 -- stick, face, etc
            { Name = 'Burning',     Categories = { "Burning", }, },
            { Name = 'Tanking',     Categories = { "Tanking", }, },
        },
    },
    {
        Name = "Abilities",
        Description = "Spells, Songs, Discs, AA",
        Icon = Icons.FA_HEART,
        IconImage = OptionsUI.LoadIcon("stafficon"),
        Headers = {
            { Name = 'Common',   Categories = { "Common Rules", "Spell Management", "Under the Hood", }, },
            { Name = 'Pet',      Categories = { "Pet Summoning", "Pet Buffs", "Swarm Pets", }, },
            { Name = 'Buffs',    Categories = { "Buff Rules", "Self", "Group", }, },
            { Name = 'Debuffs',  Categories = { "Debuff Rules", "Slow", "Stun", "Resist", "Snare", "Dispel", "Misc Debuffs", }, }, -- Resist i.e, Malo, Tash, druid
            { Name = 'Recovery', Categories = { "General Healing", "Healing Thresholds", "Other Recovery", "Curing", "Rezzing", }, },
            { Name = 'Damage',   Categories = { "Direct", "AE", "Over Time", "Taps", }, },
            { Name = 'Tanking',  Categories = { "Hate Tools", "Defenses", }, },
            { Name = 'Utility',  Categories = { "Hate Reduction", "Emergency", }, },
            { Name = 'Mez',      Categories = { "Mez General", "Mez Targets", }, },
            { Name = 'Charm',    Categories = { "Charm General", "Charm Targets", }, },
        },
    },
    {
        Name = "Items",
        Description = "Clickies, Bandolier Swaps",
        Icon = Icons.MD_RESTAURANT_MENU,
        IconImage = OptionsUI.LoadIcon("itemicon"),
        Headers = {
            { Name = 'Item Summoning', Categories = { "Item Summoning", }, },
            { Name = 'Bandolier',      Categories = { "Bandolier", }, },
            { Name = 'Instruments',    Categories = { "Instruments", }, },
            {
                Name = 'Clickies',
                Categories = { "General Clickies", "Class Config Clickies", "User Clickies", },
                RenderCategories = {
                    {
                        Header = "Manage Clickies",

                        Render = function(searchFilter)
                            return Modules:ExecModule("Clickies", "RenderConfig", searchFilter)
                        end,
                        Search = function(searchFilter)
                            return Modules:ExecModule("Clickies", "HaveSearchMatches", searchFilter)
                        end,
                    },
                },
            },
        },
    },
    {
        Name = "Interface",
        Description = "Clickies, Bandolier Swaps",
        Icon = Icons.MD_RESTAURANT_MENU,
        IconImage = OptionsUI.LoadIcon("themeicon"),
        Headers = {
            { Name = 'Interface', Categories = { "Interface", "Main Panel", "ForceTarget Window", "Mercs Status Window", "Mercs Target Window", "Default Colors", }, },
            { Name = 'Map',       Categories = { "Map", }, },
            {
                Name = 'User Theme',
                RenderCategories = {
                    {
                        Header = "User Theme",

                        Render = function(searchFilter)
                            return Ui.RenderThemeConfig(searchFilter)
                        end,
                        Search = function(searchFilter)
                            return Ui.ThemeConfigMatchesFilter(searchFilter)
                        end,
                    },
                },
            },
        },
    },
    {
        Name = "Commands/FAQ",
        Description = "Command List and Frequently Asked Questions",
        Icon = Icons.MD_RESTAURANT_MENU,
        IconImage = OptionsUI.LoadIcon("faqicon"),
        Headers = {
        },
        HiddenOnSearch = function(self)
            return not Modules:ExecModule("FAQ", "SearchMatches", self.configFilter:lower())
        end,

        HeaderRender = function(self)
            return Modules:ExecModule("FAQ", "RenderConfig", self.configFilter:lower())
        end,
    },
    {
        Name = "DB Management",
        Description = "Copy settings between characters",
        Icon = Icons.MD_STORAGE,
        IconImage = OptionsUI.LoadIcon("databaseicon"),
        HiddenOnSearch = function(self) return true end,
        Headers = {
        },
        HeaderRender = function(self)
            return OptionsUI:RenderDBManagement()
        end,
    },
    {
        Name = "Contributors",
        Description = "Credits to those who helped",
        Icon = Icons.MD_RESTAURANT_MENU,
        IconImage = OptionsUI.LoadIcon("contribicon"),
        HiddenOnSearch = function(self) return false end,
        Headers = {
        },
        HeaderRender = function(self)
            return Modules:ExecModule("Contributors", "RenderConfig")
        end,
    },
}

OptionsUI.FilteredGroups        = OptionsUI.Groups
OptionsUI.FilteredSettingsByCat = {}

OptionsUI.GroupsNameToIDs       = {}

for id, group in ipairs(OptionsUI.Groups) do
    OptionsUI.GroupsNameToIDs[group.Name] = id
end

OptionsUI.settings       = {}
OptionsUI.SettingNames   = {}
OptionsUI.DefaultConfigs = {}
OptionsUI.FirstRender    = true

OptionsUI.dbChars        = nil
OptionsUI.dbFromIdx      = 1
OptionsUI.dbToIdx        = 1
OptionsUI.dbModuleIdx    = 1
OptionsUI.dbFromClasses  = nil -- cached class list for current from-char
OptionsUI.dbFromClassIdx = 1
OptionsUI.dbToClassIdx   = 1

local function shallow_copy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

function OptionsUI:OpenAndHighlightModule(module)
    Config:OpenOptionsUIAndHighlightModule(module)
end

--- Short description: <Describe what this function/module does>
---@param filterText string The text to filter on
---@param selectGroup string? The group to select after applying the filter
function OptionsUI:OpenAndSetSearchFilter(filterText, selectGroup)
    Config:SetSetting('EnableOptionsUI', true)
    self:SetSearchFilter(filterText)
    self:SetSelectedGroup(selectGroup)
end

function OptionsUI:SetSearchFilter(filterText)
    self.configFilter = filterText or ""
    self:ApplySearchFilter()
end

function OptionsUI:SetSelectedGroup(group)
    self.selectedGroup = group or self.selectedGroup
end

function OptionsUI:ApplySearchFilter()
    self.FilteredGroups        = self.Groups
    self.FilteredSettingsByCat = {}

    self.HighlightedSettings   = Set.new({})
    self.HighlightedCategories = Set.new({})
    local knownCategories      = Set.new({})

    local filter               = self.configFilter:lower()
    local filtered             = {}
    local catchAllHeader       = nil

    -- precalc all known categories so we can add ones that as missing.
    for _, group in ipairs(self.Groups) do
        for _, header in ipairs(group.Headers) do
            for _, category in ipairs(header.Categories or {}) do
                knownCategories:add(category)
                if header.CatchAll then
                    catchAllHeader = header
                end
            end
        end
    end

    local allModuleCategories = Set.new({})
    local allCategories = Config:PeerGetAllModuleSettingCategories(self.selectedCharacter)

    for _, categories in pairs(allCategories or {}) do -- module to categories
        local categoryList = categories:toList() or {}
        for _, category in ipairs(categoryList) do     -- all categories in module
            allModuleCategories:add(category)
        end
    end

    local allModuleCategoriesTable = allModuleCategories:toList()
    for _, category in ipairs(allModuleCategoriesTable) do
        if not knownCategories:contains(category) and catchAllHeader ~= nil then
            Logger.log_warn("\ayOptionsUI: \awAdding missing category '\at%s\aw' to catch-all header.", category)
            table.insert(catchAllHeader.Categories, category)
            knownCategories:add(category)
        end
    end

    for _, group in ipairs(self.Groups) do
        local newGroup = shallow_copy(group)
        newGroup.Headers = {} -- clear headers for rebuilding
        newGroup.Highlighted = false

        for _, header in ipairs(group.Headers) do
            local headerLower = header.Name:lower()
            local headerMatches = headerLower:find(filter, 1, true) ~= nil
            local highlightHeader = false
            local newCategories = {}
            local newRenderCategories = {}

            for _, category in ipairs(header.Categories or {}) do
                local categoryLower = category:lower()

                local categoryMatches = categoryLower:find(filter, 1, true) ~= nil

                local settingsForCategory = Config:PeerGetAllSettingsForCategory(self.selectedCharacter, category)

                for _, settingName in ipairs(settingsForCategory or {}) do
                    local settingDefaults         = Config:PeerGetSettingDefaults(self.selectedCharacter, settingName)
                    local settingDisplayNameLower = (settingDefaults.DisplayName or ""):lower()
                    local settingTooltipLower     = (type(settingDefaults.Tooltip) == 'function' and settingDefaults.Tooltip() or (settingDefaults.Tooltip or "")):lower()
                    local customSetting           = (settingDefaults.Type == "Custom")
                    local showAdv                 = Config:GetSetting('ShowAdvancedOpts') or (settingDefaults.ConfigType == nil or settingDefaults.ConfigType:lower() == "normal")

                    if showAdv and not customSetting and (headerMatches or categoryMatches or settingName:lower():find(filter, 1, true) ~= nil or settingDisplayNameLower:find(filter, 1, true) ~= nil or
                            settingTooltipLower:find(filter, 1, true) ~= nil) then
                        self.FilteredSettingsByCat[category] = self.FilteredSettingsByCat[category] or {}
                        table.insert(self.FilteredSettingsByCat[category], settingName)

                        -- set highlighting
                        if Config:IsModuleHighlighted(Config:PeerGetModuleForSetting(self.selectedCharacter, settingName)) then
                            newGroup.Highlighted = true
                            self.HighlightedSettings:add(settingName)
                            self.HighlightedCategories:add(category)
                            highlightHeader = true
                        end
                    end
                end

                table.sort(self.FilteredSettingsByCat[category] or {}, function(k1, k2)
                    local k1Defaults = Config:PeerGetSettingDefaults(self.selectedCharacter, k1)
                    local k2Defaults = Config:PeerGetSettingDefaults(self.selectedCharacter, k2)
                    if (k1Defaults.Index ~= nil or k2Defaults.Index ~= nil) and (k1Defaults.Index ~= k2Defaults.Index) then
                        return (k1Defaults.Index or 999) < (k2Defaults.Index or 999)
                    end

                    if k1Defaults.Category == k2Defaults.Category then
                        return (k1Defaults.DisplayName or "") < (k2Defaults.DisplayName or "")
                    end

                    return (k1Defaults.Category or "") < (k2Defaults.Category or "")
                end)

                if #(self.FilteredSettingsByCat[category] or {}) > 0 then
                    table.insert(newCategories, category)
                end
            end

            for _, renderCategory in ipairs(header.RenderCategories or {}) do
                local categoryMatches = true
                if renderCategory.Search then
                    categoryMatches = renderCategory.Search(filter)
                end

                if categoryMatches then
                    table.insert(newRenderCategories, renderCategory)
                end
            end

            if #newCategories > 0 or #newRenderCategories > 0 then
                table.insert(newGroup.Headers, { Name = header.Name, Categories = newCategories, RenderCategories = newRenderCategories, highlighted = highlightHeader, })
            end
        end

        if #(newGroup.Headers or {}) > 0 or (newGroup.HeaderRender and (filter:len() == 0 or not (newGroup.HiddenOnSearch and newGroup.HiddenOnSearch(self) or false))) then
            table.insert(filtered, newGroup)
        end
    end

    self.FilteredGroups = filtered

    OptionsUI.GroupsNameToIDs = {}

    for id, group in ipairs(OptionsUI.FilteredGroups) do
        OptionsUI.GroupsNameToIDs[group.Name] = id
    end

    self.lastSortTime = Globals.GetTimeSeconds()
    self.lastHighlightTime = Globals.GetTimeSeconds()
end

function OptionsUI:RenderGroupPanel(groupLabel, groupName)
    if ImGui.Selectable(" ##" .. groupLabel, self.selectedGroup == groupName) then
        self:SetSelectedGroup(groupName)
    end
    ImGui.SameLine()
    Ui.RenderText(groupLabel)
end

function OptionsUI:RenderGroupPanelWithImage(group)
    local selectableHeight = 40
    local iconSize         = 30
    local cursorScreenPos  = ImGui.GetCursorScreenPosVec()
    local textColStyle     = ImGui.GetStyleColorVec4(ImGuiCol.Text)
    local currentStyle     = ImGui.GetStyle()

    local _, pressed       = ImGui.Selectable("##" .. group.Name, self.selectedGroup == group.Name, ImGuiSelectableFlags.None, ImVec2(0, selectableHeight))

    if group.Description and group.Description:len() > 0 then
        Ui.Tooltip(group.Description or "")
    end

    if pressed then
        self:SetSelectedGroup(group.Name)
    end

    local draw_list = ImGui.GetWindowDrawList()

    local _, label_y = ImGui.CalcTextSize(group.Name)
    local midLabelY = math.floor((selectableHeight - label_y) / 2) or 0
    local midIconY = math.floor((selectableHeight - iconSize) / 2) or 0

    -- set the text color from the theme
    local labelCol = group.Highlighted
        and IM_COL32(255, 128, 0, 255)

        or IM_COL32(math.floor(textColStyle.x * 255), math.floor(textColStyle.y * 255), math.floor(textColStyle.z * 255), math.floor(textColStyle.w * 255))

    local currentXPos = cursorScreenPos.x + currentStyle.ItemSpacing.x
    -- draw the icon png
    draw_list:AddImage(group.IconImage:GetTextureID(),
        ImVec2(currentXPos, cursorScreenPos.y + midIconY),
        ImVec2(currentXPos + iconSize, cursorScreenPos.y + midIconY + iconSize),
        ImVec2(0, 0), ImVec2(1, 1),
        IM_COL32(255, 255, 255, 255))

    -- move the cursor to the right of the icon
    currentXPos = currentXPos + iconSize + currentStyle.ItemSpacing.x

    -- render the label text
    draw_list:AddText(ImVec2(currentXPos, cursorScreenPos.y + midLabelY), labelCol, group.Name)
end

function OptionsUI:RenderCategorySeperator(category)
    ImGui.PushStyleVar(ImGuiStyleVar.SeparatorTextPadding, ImVec2(15, 15))
    ImGui.PushStyleVar(ImGuiStyleVar.SeparatorTextAlign, ImVec2(0.05, 0.5))

    if self.HighlightedCategories:contains(category) then
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.SearchHighlightColor)
    end

    ImGui.SeparatorText(category)

    if self.HighlightedCategories:contains(category) then
        ImGui.PopStyleColor(1)
    end

    ImGui.PopStyleVar(2)
end

function OptionsUI:RenderOptionsPanel(groupName)
    if self.FilteredGroups[self.GroupsNameToIDs[groupName]] then
        for _, header in ipairs(self.FilteredGroups[self.GroupsNameToIDs[groupName]].Headers or {}) do
            if header.highlighted then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.SearchHighlightColor)
            end

            if ImGui.CollapsingHeader(header.Name) then
                if header.highlighted then
                    ImGui.PopStyleColor(1)
                end
                for _, category in ipairs(header.Categories or {}) do
                    if #Config:PeerGetAllSettingsForCategory(self.selectedCharacter, category) > 0 then
                        -- only draw the seperator if the category name is different from the heading
                        if header.Name ~= category then
                            self:RenderCategorySeperator(category)
                        end
                        -- Render options for this category
                        self:RenderCategorySettings(category)
                    end
                end

                -- only draw these for the local character for now.
                if self.selectedCharacter == Comms.GetPeerName() then
                    for _, RenderCategory in ipairs(header.RenderCategories or {}) do
                        if RenderCategory.Header then
                            self:RenderCategorySeperator(RenderCategory.Header)
                        end

                        if RenderCategory.Render then
                            RenderCategory.Render(self.configFilter)
                        end
                    end
                end
            else
                if header.highlighted then
                    ImGui.PopStyleColor(1)
                end
            end
        end

        if self.FilteredGroups[self.GroupsNameToIDs[groupName]].HeaderRender then
            self.FilteredGroups[self.GroupsNameToIDs[groupName]].HeaderRender(self)
        end
    end
end

function OptionsUI:RenderCategorySettings(category)
    local any_pressed         = false
    local new_loadout         = false
    local pressed             = false
    local loadout_change      = false
    local renderWidth         = 325
    local windowWidth         = ImGui.GetWindowWidth()
    local numCols             = math.max(1, math.floor(windowWidth / renderWidth))
    local settingsForCategory = self.FilteredSettingsByCat[category] or {}

    if ImGui.BeginChild("catchild_" .. category, ImVec2(0, 0), bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.AutoResizeY), ImGuiWindowFlags.None) then
        if ImGui.BeginTable("Options_" .. (category), 2 * numCols, ImGuiTableFlags.Borders) then
            for _ = 1, numCols do
                ImGui.TableSetupColumn('Option', (ImGuiTableColumnFlags.WidthFixed), 180.0)
                ImGui.TableSetupColumn('Set', (ImGuiTableColumnFlags.WidthFixed), 130.0)
            end

            --ImGui.TableNextRow(ImGuiTableRowFlags.None, 40.0)
            for idx, settingName in ipairs(settingsForCategory or {}) do
                local settingDefaults = Config:PeerGetSettingDefaults(self.selectedCharacter, settingName)

                -- defaults can go away when a different class config is loaded in.
                if settingDefaults then
                    local setting        = Config:PeerGetSetting(self.selectedCharacter, settingName)
                    local id             = settingName -- important! the color configs use this to look up defaults.
                    local settingTooltip = (type(settingDefaults.Tooltip) == 'function' and settingDefaults.Tooltip() or settingDefaults.Tooltip) or ""

                    if settingDefaults.Type ~= "Custom" then
                        --
                        local hasWarning, warningText = false, ""

                        if settingDefaults.Warning then
                            hasWarning, warningText = settingDefaults.Warning()
                        end

                        if idx % numCols == 1 then
                            ImGui.TableNextRow(ImGuiTableRowFlags.None, ImGui.GetFrameHeightWithSpacing())
                        end

                        ImGui.TableNextColumn()
                        if self.HighlightedSettings:contains(settingName) then
                            ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.SearchHighlightColor)
                        end

                        local text_height = ImGui.GetTextLineHeightWithSpacing()
                        local row_height  = ImGui.GetFrameHeightWithSpacing()

                        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + ((row_height - text_height) / 2))

                        local columnWidth = ImGui.GetColumnWidth()
                        local iconWidth = hasWarning and ImGui.CalcTextSize(Icons.MD_WARNING) or 0
                        local selectableWidth = columnWidth - iconWidth - (hasWarning and ImGui.GetStyle().ItemSpacing.x or 0)
                        ImGui.PushStyleColor(ImGuiCol.HeaderHovered, IM_COL32(0, 0, 0, 0))
                        ImGui.PushStyleColor(ImGuiCol.HeaderActive, Ui.ChangeColorAlpoha(Globals.Constants.Colors.Green, 0.1))
                        if ImGui.Selectable(string.format("%s", settingDefaults.DisplayName or (string.format("None %d", idx))), false, ImGuiSelectableFlags.None, ImVec2(selectableWidth, 0)) then
                            ImGui.SetClipboardText(settingName)
                            table.insert(self.ToastStates, {
                                active = true,
                                timer = 0,
                                message = string.format("Setting name '%s' copied to clipboard", settingName),
                                receivedTime = os.time(),
                                color = Ui.ImVec4ToColor(Globals.Constants.Colors.Green),
                            })
                        end
                        ImGui.PopStyleColor(2)

                        if self.HighlightedSettings:contains(settingName) then
                            ImGui.PopStyleColor(1)
                        end
                        local defaultValue = tostring(settingDefaults.Default)
                        if settingDefaults.Type == "Combo" then
                            defaultValue = string.format("%s - %s", settingDefaults.Default, settingDefaults.ComboOptions[settingDefaults.Default])
                        end
                        if settingDefaults.Type == "Color" then
                            defaultValue = string.format("R:%g, G:%g, B:%g, A:%g",
                                math.floor(settingDefaults.Default.x * 255),
                                math.floor(settingDefaults.Default.y * 255),
                                math.floor(settingDefaults.Default.z * 255),
                                math.floor((settingDefaults.Default.w or 1.0) * 255))
                        end
                        local tooltipColor = Globals.Constants.Colors.TooltipTextColor
                        Ui.MultilineTooltipWithColors(
                            {
                                { text = settingTooltip, color = tooltipColor, },
                                { text = "",             color = tooltipColor, },
                                { text = "Variable: ",   color = Globals.Constants.Colors.LightBlue, padAfter = 4, },
                                { text = settingName,    color = Globals.Constants.Colors.Orange,    sameLine = true, },
                                { text = "Default: ",    color = Globals.Constants.Colors.LightBlue, },
                                {
                                    text = tostring(defaultValue),
                                    render = settingDefaults.Type == "Color" and
                                        function(draw_list, pos)
                                            local size = ImGui.GetTextLineHeight()
                                            -- if no draw_list then just return our size
                                            if draw_list then
                                                draw_list:AddRectFilled(pos, ImVec2(pos.x + size, pos.y + size), Ui.ImVec4ToColor(settingDefaults.Default), 4)
                                            end

                                            return size + 4, size
                                        end or nil,
                                    color = Globals.Constants.Colors.Orange,
                                    sameLine = true,
                                    padAfter = 4,
                                },

                                settingDefaults.Max and
                                {
                                    text = " [" .. string.format("%d", settingDefaults.Min) .. " - " .. string.format("%d", settingDefaults.Max) .. "]",
                                    color = Globals.Constants
                                        .Colors.LightGreen,
                                    sameLine = true,
                                } or nil,
                            })

                        if hasWarning then
                            ImGui.SameLine()
                            ImGui.TextColored(Globals.Constants.Colors.ConditionFailColor, Icons.MD_WARNING)
                            Ui.Tooltip(warningText)
                        end

                        ImGui.TableNextColumn()
                        local typeOfSetting = type(settingDefaults.Type) == 'string' and settingDefaults.Type or type(setting)
                        if (settingDefaults.Type or ""):find("Array") then
                            typeOfSetting = settingDefaults.Type:sub(7)
                        end

                        if settingDefaults ~= nil then
                            setting, loadout_change, pressed = Ui.RenderOption(
                                typeOfSetting,
                                setting,
                                id,
                                settingDefaults.RequiresLoadoutChange or false,
                                settingDefaults.ComboOptions or settingDefaults.Min or (type(settingDefaults.Hint) == "function" and settingDefaults.Hint() or settingDefaults.Hint),
                                settingDefaults.Max, settingDefaults.Step or 1)
                            new_loadout = new_loadout or loadout_change
                            any_pressed = any_pressed or pressed

                            --  need to update setting here and notify module
                            if pressed then
                                Config:PeerSetSetting(self.selectedCharacter, settingName, setting)

                                if new_loadout and self.selectedCharacter == Comms.GetPeerName() then
                                    Modules:ExecModule("Class", "RescanLoadout")
                                    new_loadout = false
                                end
                            end
                        else
                            ImGui.TextColored(1.0, 0.0, 0.0, 1.0, "Error: Setting not found - " .. settingName)
                        end
                    end
                else
                    ImGui.TableNextColumn()
                    ImGui.Text("\arError: Setting not found - %s\ax", settingName)
                    ImGui.TableNextColumn()
                    ImGui.Text("\arError: Setting not found - %s\ax", settingName)
                end
            end
            ImGui.EndTable()
        end
    end
    ImGui.EndChild()
end

function OptionsUI:RenderDBManagement()
    -- lazy-load character list from DB
    if not self.dbChars then
        local raw = Config.Db:getCharacters()
        self.dbChars = {}
        local curLabel = string.format("%s (%s)", Globals.CurLoadedChar, Globals.CurServer)
        for _, c in ipairs(raw) do
            self.dbChars[#self.dbChars + 1] = string.format("%s (%s)", c.name, c.server_name)
        end
        if #self.dbChars == 0 then
            self.dbChars = { "(no characters in DB)", }
        end
        self.dbFromIdx = 1
        for i, label in ipairs(self.dbChars) do
            if label == curLabel then
                self.dbFromIdx = i; break
            end
        end
        if self.dbToIdx > #self.dbChars then self.dbToIdx = 1 end
    end

    -- build module list: "All Modules" + registered module names
    local moduleNames = { "All Modules", }
    for modName in pairs(Config.moduleDefaultSettings) do
        moduleNames[#moduleNames + 1] = modName
    end
    table.sort(moduleNames, function(a, b)
        if a == "All Modules" then return true end
        if b == "All Modules" then return false end
        return a < b
    end)

    local charCount = #self.dbChars

    -- initial load of from-classes
    if not self.dbFromClasses then
        local fromName, fromServer = self.dbChars[self.dbFromIdx]:match('^(.+) %((.+)%)$')
        self.dbFromClasses = (fromName and Config.Db:getClassesForCharacter(fromServer, fromName)) or {}
        if #self.dbFromClasses == 0 then self.dbFromClasses = { Globals.CurLoadedClass, } end
        self.dbFromClassIdx = 1
        for i, c in ipairs(self.dbFromClasses) do
            if c == Globals.CurLoadedClass then
                self.dbFromClassIdx = i; break
            end
        end
    end

    ImGui.PushStyleVar(ImGuiStyleVar.SeparatorTextPadding, ImVec2(15, 15))
    ImGui.PushStyleVar(ImGuiStyleVar.SeparatorTextAlign, ImVec2(0.05, 0.5))
    ImGui.SeparatorText("DB Management")
    ImGui.PopStyleVar(2)

    ImGui.Spacing()

    local fromClass  = self.dbFromClasses[self.dbFromClassIdx]
    local moduleName = moduleNames[self.dbModuleIdx]
    local noChars    = charCount == 0 or self.dbChars[self.dbFromIdx] == "(no characters in DB)"
    local sameChar   = self.dbFromIdx == self.dbToIdx
    local sameClass  = sameChar and fromClass == Globals.Constants.AllClasses[self.dbToClassIdx]
    local canCopy    = not noChars and not (sameChar and sameClass)

    local fromName, fromServer
    if not noChars then
        fromName, fromServer = self.dbChars[self.dbFromIdx]:match('^(.+) %((.+)%)$')
    end
    local fromIsRunning = fromName and Comms.IsCharRunning(fromName, fromServer, fromClass) or false
    local canDelete     = not noChars and not fromIsRunning

    if ImGui.BeginTable("##dbmgmt", 4, ImGuiTableFlags.SizingFixedFit) then
        ImGui.TableSetupColumn("label", ImGuiTableColumnFlags.WidthFixed, 80)
        ImGui.TableSetupColumn("char", ImGuiTableColumnFlags.WidthFixed, 230)
        ImGui.TableSetupColumn("class", ImGuiTableColumnFlags.WidthFixed, 110)
        ImGui.TableSetupColumn("action", ImGuiTableColumnFlags.WidthStretch)

        -- Module row
        ImGui.TableNextRow()
        ImGui.TableNextColumn()
        ImGui.AlignTextToFramePadding()
        ImGui.Text("Module:")
        ImGui.TableNextColumn()
        ImGui.SetNextItemWidth(-1)
        local newModIdx, modChanged = Ui.SearchableCombo("dbmod", self.dbModuleIdx, moduleNames)
        if modChanged then
            self.dbModuleIdx = newModIdx
            moduleName = moduleNames[self.dbModuleIdx]
        end

        -- Selected character row (Copy source / Reset target)
        ImGui.TableNextRow()
        ImGui.TableNextColumn()
        ImGui.AlignTextToFramePadding()
        ImGui.Text("Character:")
        ImGui.TableNextColumn()
        ImGui.SetNextItemWidth(-1)
        local newFrom, fromChanged = Ui.SearchableCombo("dbfrom", self.dbFromIdx, self.dbChars)
        if fromChanged then
            self.dbFromIdx = newFrom
            fromName, fromServer = self.dbChars[newFrom]:match('^(.+) %((.+)%)$')
            self.dbFromClasses = (fromName and Config.Db:getClassesForCharacter(fromServer, fromName)) or {}
            if #self.dbFromClasses == 0 then self.dbFromClasses = { Globals.CurLoadedClass, } end
            self.dbFromClassIdx = 1
            fromClass = self.dbFromClasses[self.dbFromClassIdx]
        end
        ImGui.TableNextColumn()
        ImGui.SetNextItemWidth(-1)
        local newFromClass, fromClassChanged = Ui.SearchableCombo("dbfromclass", self.dbFromClassIdx, self.dbFromClasses)
        if fromClassChanged then
            self.dbFromClassIdx = newFromClass
            fromClass = self.dbFromClasses[self.dbFromClassIdx]
        end
        ImGui.TableNextColumn()
        if noChars then ImGui.BeginDisabled() end
        if ImGui.Button(Icons.MD_RESTORE .. " Reset to Defaults##dbreset") then
            self.dbOpenResetPopup = true
        end
        if noChars then ImGui.EndDisabled() end
        ImGui.SameLine()
        if not canDelete then ImGui.BeginDisabled() end
        if ImGui.Button(Icons.FA_TRASH .. " Delete from Database##dbdelete") then
            self.dbOpenDeletePopup = true
        end
        if not canDelete then ImGui.EndDisabled() end
        if fromIsRunning and not noChars then
            if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                ImGui.SetTooltip("Cannot delete: target character is currently running RGMercs.")
            end
        end

        ImGui.TableNextRow()
        ImGui.TableNextColumn()
        ImGui.TableNextColumn()
        ImGui.BeginDisabled(not canCopy)
        if ImGui.Button(Icons.FA_ARROW_DOWN .. " Copy Selected Settings##dbcopy") then
            self.dbOpenCopyPopup = true
        end
        if sameChar and sameClass then
            if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                ImGui.SetTooltip("Cannot copy: source and destination are the same character and class.")
            end
        end
        ImGui.EndDisabled()

        -- Copy destination row
        ImGui.TableNextRow()
        ImGui.TableNextColumn()
        ImGui.AlignTextToFramePadding()
        ImGui.Text("Copy To:")
        ImGui.TableNextColumn()
        ImGui.SetNextItemWidth(-1)
        local newTo, toChanged = Ui.SearchableCombo("dbto", self.dbToIdx, self.dbChars)
        if toChanged then self.dbToIdx = newTo end
        ImGui.TableNextColumn()
        ImGui.SetNextItemWidth(-1)
        local newToClass, toClassChanged = Ui.SearchableCombo("dbtoclass", self.dbToClassIdx, Globals.Constants.AllClasses)
        if toClassChanged then self.dbToClassIdx = newToClass end

        ImGui.EndTable()
    end

    if self.dbOpenResetPopup then
        ImGui.OpenPopup("DBResetConfirm##DBMgmt"); self.dbOpenResetPopup = false
    end
    if self.dbOpenDeletePopup then
        ImGui.OpenPopup("DBDeleteConfirm##DBMgmt"); self.dbOpenDeletePopup = false
    end
    if self.dbOpenCopyPopup then
        ImGui.OpenPopup("DBCopyConfirm##DBMgmt"); self.dbOpenCopyPopup = false
    end

    ImGui.SetNextWindowSize(ImVec2(460, 0), ImGuiCond.Appearing)
    if ImGui.BeginPopup("DBResetConfirm##DBMgmt") then
        ImGui.PushTextWrapPos(440)
        ImGui.TextWrapped("Reset the following settings to defaults?")
        ImGui.Spacing()
        ImGui.Text("Target: ")
        ImGui.SameLine()
        ImGui.TextColored(Globals.Constants.BasicColors.Yellow, "%s [%s]", self.dbChars[self.dbFromIdx], fromClass)
        ImGui.Text("Module: ")
        ImGui.SameLine()
        ImGui.TextColored(Globals.Constants.BasicColors.Yellow, "%s", moduleName)
        ImGui.PopTextWrapPos()
        ImGui.Spacing()
        if ImGui.Button("Reset##dbresetconfirm") then
            self:ResetSettings(self.dbChars, self.dbFromIdx, fromClass, moduleName)
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        if ImGui.Button("Cancel##dbresetcancel") then
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end

    ImGui.SetNextWindowSize(ImVec2(460, 0), ImGuiCond.Appearing)
    if ImGui.BeginPopup("DBCopyConfirm##DBMgmt") then
        local toClass = Globals.Constants.AllClasses[self.dbToClassIdx]
        ImGui.PushTextWrapPos(440)
        ImGui.TextWrapped("Copy the following settings?")
        ImGui.Spacing()
        ImGui.Text("Source: ")
        ImGui.SameLine()
        ImGui.TextColored(Globals.Constants.BasicColors.Yellow, "%s [%s]", self.dbChars[self.dbFromIdx], fromClass)
        ImGui.Text("Destination: ")
        ImGui.SameLine()
        ImGui.TextColored(Globals.Constants.BasicColors.Yellow, "%s [%s]", self.dbChars[self.dbToIdx], toClass)
        ImGui.Text("Module: ")
        ImGui.SameLine()
        ImGui.TextColored(Globals.Constants.BasicColors.Yellow, "%s", moduleName)
        ImGui.PopTextWrapPos()
        ImGui.Spacing()
        if ImGui.Button("Copy##dbcopyconfirm") then
            self:CopySettings(self.dbChars, self.dbFromIdx, fromClass,
                self.dbToIdx, toClass, moduleName)
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        if ImGui.Button("Cancel##dbcopycancel") then
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end

    ImGui.SetNextWindowSize(ImVec2(460, 0), ImGuiCond.Appearing)
    if ImGui.BeginPopup("DBDeleteConfirm##DBMgmt") then
        ImGui.PushTextWrapPos(440)
        ImGui.TextWrapped("Delete the following from the database?")
        ImGui.Spacing()
        ImGui.Text("Target: ")
        ImGui.SameLine()
        ImGui.TextColored(Globals.Constants.BasicColors.Yellow, "%s [%s]", self.dbChars[self.dbFromIdx], fromClass)
        ImGui.PopTextWrapPos()
        ImGui.Spacing()
        if ImGui.Button("Delete##dbdeleteconfirm") then
            self:DeleteSettings(self.dbChars, self.dbFromIdx, fromClass)
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        if ImGui.Button("Cancel##dbdeletecancel") then
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end

    ImGui.Spacing()
    if ImGui.Button(Icons.MD_REFRESH .. " Refresh Character List##dbrefresh") then
        self.dbChars       = nil
        self.dbFromClasses = nil
    end

    ImGui.Spacing()
    ImGui.PushStyleVar(ImGuiStyleVar.SeparatorTextPadding, ImVec2(15, 15))
    ImGui.PushStyleVar(ImGuiStyleVar.SeparatorTextAlign, ImVec2(0.05, 0.5))
    ImGui.SeparatorText("DB Metrics")
    ImGui.PopStyleVar(2)
    ImGui.Spacing()
    Config.Db:renderTelemetry()
    ImGui.Spacing()
    Config.Db:renderTelemetryGraph()
end

function OptionsUI:CopySettings(charLabels, fromIdx, fromClass, toIdx, toClass, moduleName)
    local fromName, fromServer = charLabels[fromIdx]:match('^(.+) %((.+)%)$')
    local toName, toServer     = charLabels[toIdx]:match('^(.+) %((.+)%)$')
    local result               = DBManagement.CopySettings(fromName, fromServer, fromClass, toName, toServer, toClass, moduleName)
    if not result.ok then return end

    -- copying to the same char on a new class means its class list is stale
    if result.sameChar then self.dbFromClasses = nil end

    table.insert(self.ToastStates, {
        active       = true,
        timer        = 0,
        message      = result.toastMessage,
        receivedTime = os.time(),
        color        = Ui.ImVec4ToColor(Globals.Constants.Colors.Green),
    })
end

function OptionsUI:ResetSettings(charLabels, fromIdx, fromClass, moduleName)
    local fromName, fromServer = charLabels[fromIdx]:match('^(.+) %((.+)%)$')
    local result = DBManagement.ResetSettings(fromName, fromServer, fromClass, moduleName)
    if not result.ok then return end

    table.insert(self.ToastStates, {
        active       = true,
        timer        = 0,
        message      = result.toastMessage,
        receivedTime = os.time(),
        color        = Ui.ImVec4ToColor(Globals.Constants.Colors.Green),
    })
end

function OptionsUI:DeleteSettings(charLabels, fromIdx, fromClass)
    local fromName, fromServer = charLabels[fromIdx]:match('^(.+) %((.+)%)$')
    local result = DBManagement.DeleteSettings(fromName, fromServer, fromClass)
    if not result.ok then return end

    -- invalidate cached pickers so the deleted char/class disappears from the list
    self.dbChars       = nil
    self.dbFromClasses = nil

    table.insert(self.ToastStates, {
        active       = true,
        timer        = 0,
        message      = result.toastMessage,
        receivedTime = os.time(),
        color        = Ui.ImVec4ToColor(Globals.Constants.Colors.Green),
    })
end

function OptionsUI:RenderCurrentTab()
    self:RenderOptionsPanel(self.selectedGroup)
end

function OptionsUI:ValidateSelectedPeer()
    if self.selectedCharacter == Comms.GetPeerName() then
        return
    end

    if self.selectedCharacter == nil or self.selectedCharacter == "" then
        Logger.log_error("\ayOptionsUI: \awSelected peer is invalid. Defaulting back to local character.")
        self.selectedCharacter = Comms.GetPeerName()
        return
    end

    if not next(Comms.GetPeerHeartbeat(self.selectedCharacter)) then
        Logger.log_error("\ayOptionsUI: \awSelected peer '%s' is not valid. Defaulting back to local character.", self.selectedCharacter)
        self.selectedCharacter = Comms.GetPeerName()
    end
end

function OptionsUI:RenderMainWindow(_, openGUI, flags)
    local shouldDrawGUI = true

    if self.FirstRender or self.lastSortTime < Config:GetLastModuleRegisteredTime() or self.lastHighlightTime < Config:GetLastHighlightChangeTime() then
        self.selectedCharacter = Comms.GetPeerName()
        self:ApplySearchFilter()
        Logger.log_debug("\ayOptionsUI: \awSettings re-sorted due to new module settings being registered.")
        self.FirstRender = false
    end

    self:ValidateSelectedPeer()

    if Config.TempSettings.ResetOptionsUIPosition then
        ImGui.SetNextWindowPos(ImVec2(100, 100), ImGuiCond.Always)
        Config.TempSettings.ResetOptionsUIPosition = false
    end

    ImGui.SetNextWindowSize(ImVec2(700, 500), ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSizeConstraints(ImVec2(400, 300), ImVec2(2000, 2000))

    openGUI, shouldDrawGUI = ImGui.Begin(Ui.GetWindowTitle(("RGMercs Options%s"):format(Globals.PauseMain and " [Paused]" or ""), 'rgmercsOptionsUI'), openGUI, flags)

    if shouldDrawGUI then
        ImGui.PushID("##RGMercsUI_" .. Globals.CurLoadedChar)
        local _, y = ImGui.GetContentRegionAvail()

        if ImGui.BeginChild("left##RGmercsOptions", math.min(ImGui.GetWindowContentRegionWidth() * .3, 205), y - 1, ImGuiChildFlags.Borders) then
            local flags = bit32.bor(ImGuiTableFlags.RowBg, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.ScrollY)
            local textChanged = false
            local inputBoxPosX = ImGui.GetCursorPosX()
            local style = ImGui.GetStyle()
            local searchBarUsableWidth = ImGui.GetWindowContentRegionWidth() - (ImGui.GetFontSize() + style.FramePadding.y + style.WindowPadding.x * 2)

            ImGui.SetNextItemWidth(ImGui.GetWindowContentRegionWidth())
            -- character selecter
            local peerList = Comms.GetPeers(false)
            table.insert(peerList, 1, Comms.GetPeerName())
            local peerListIdx = 1
            for idx, name in ipairs(peerList) do
                if name == self.selectedCharacter then
                    peerListIdx = idx
                    break
                end
            end
            local newPeerIdx, peerChanged = ImGui.Combo("##OptionsUICharSelect", peerListIdx, peerList, #peerList)
            if peerChanged and newPeerIdx >= 1 and newPeerIdx <= #peerList then
                self.selectedCharacter = peerList[newPeerIdx]
                Config:SetRemotePeer(self.selectedCharacter)
                self.lastPeerUpdate = 0
            end

            if Config:GetPeerLastConfigReceivedTime(self.selectedCharacter) > 0 and self.lastPeerUpdate < Config:GetPeerLastConfigReceivedTime(self.selectedCharacter) then
                self:ApplySearchFilter()
                self.lastPeerUpdate = Config:GetPeerLastConfigReceivedTime(self.selectedCharacter)
            end

            ImGui.SetNextItemWidth(searchBarUsableWidth)
            self.configFilter, textChanged = ImGui.InputText("###OptionsUISearchText", self.configFilter)
            if textChanged then
                self:ApplySearchFilter()
            end

            if not ImGui.IsItemActive() and self.configFilter:len() == 0 then
                ImGui.SameLine()
                local curPosX = ImGui.GetCursorPosX()
                ImGui.SetCursorPosX(inputBoxPosX + (style.WindowPadding.x / 2))
                ImGui.TextColored(0.8, 0.8, 0.8, 0.75, "Search All...")
                ImGui.SameLine()
                ImGui.SetCursorPosX(curPosX)
            else
                ImGui.SameLine()
            end

            if ImGui.SmallButton(Icons.MD_CLEAR) then
                self.configFilter = ""
                self:ApplySearchFilter()
            end
            Ui.Tooltip("Clear Search Text")
            local ShowAdvancedOpts = Config:GetSetting('ShowAdvancedOpts')
            local changed = false
            ShowAdvancedOpts, changed = Ui.RenderOptionToggle("show_adv_tog###OptionsUI", "Show Advanced Options", ShowAdvancedOpts)
            if changed then
                Config:SetSetting('ShowAdvancedOpts', ShowAdvancedOpts)
                self:ApplySearchFilter()
            end

            if ImGui.BeginTable('configmenu##RGmercsOptions', 1, flags, 0, 0, 0.0) then
                ImGui.TableNextColumn()
                local selectedGroupVisible = false
                for _, group in ipairs(self.FilteredGroups) do
                    if group.Name == self.selectedGroup then
                        selectedGroupVisible = true
                        break
                    end
                end
                if not selectedGroupVisible and #self.FilteredGroups > 0 then
                    self:SetSelectedGroup(self.FilteredGroups[1].Name)
                end

                for _, group in ipairs(self.FilteredGroups) do
                    if group.IconImage then
                        self:RenderGroupPanelWithImage(group)
                    else
                        self:RenderGroupPanel(string.format("%s %s", group.Icon, group.Name), group.Name)
                    end
                    ImGui.TableNextColumn()
                end
                ImGui.EndTable()
            end
        end
        ImGui.EndChild()
        ImGui.SameLine()

        local x, _ = ImGui.GetContentRegionAvail()

        local right_start = ImGui.GetCursorPosVec()
        if ImGui.BeginChild("right##RGmercsOptionsBG", x, y - 1, ImGuiChildFlags.Borders) then
            local cr_min       = ImGui.GetWindowContentRegionMinVec()
            local cr_max       = ImGui.GetWindowContentRegionMaxVec()
            local wp           = ImGui.GetCursorScreenPosVec()
            local top_left     = ImVec2(wp.x + cr_min.x, wp.y + cr_min.y)
            local bottom_right = ImVec2(wp.x + cr_max.x, (wp.y + cr_max.y) * 1.25)

            top_left.x         = top_left.x + ImGui.GetScrollX()
            bottom_right.x     = bottom_right.x + ImGui.GetScrollX()
            top_left.y         = top_left.y + ImGui.GetScrollY()
            bottom_right.y     = bottom_right.y + ImGui.GetScrollY()

            local draw_list    = ImGui.GetWindowDrawList()
            if self.bgImg then
                draw_list:PushClipRect(top_left, bottom_right, true)

                draw_list:AddImage(self.bgImg:GetTextureID(),
                    top_left,
                    bottom_right,
                    ImVec2(0, 0), ImVec2(1, 1),
                    IM_COL32(255, 255, 255, 30))
                draw_list:PopClipRect()
            end
        end
        ImGui.EndChild()

        ImGui.SetCursorPos(right_start)
        if ImGui.BeginChild("right##RGmercsOptions", x, y - 1, ImGuiChildFlags.Borders) then
            flags = bit32.bor(ImGuiTableFlags.None, ImGuiTableFlags.None)
            if self.selectedCharacter ~= Comms.GetPeerName() and Config:GetPeerLastConfigReceivedTime(self.selectedCharacter) == 0 then
                ImGui.TextColored(0.2, 0.2, 0.8, 1.0, "Waiting for configuration from %s...", self.selectedCharacter)
            else
                if ImGui.BeginTable('rightpanelTable##RGmercsOptions', 1, flags, 0, 0, 0.0) then
                    ImGui.TableNextColumn()
                    self:RenderCurrentTab()
                    ImGui.Dummy(ImVec2(0, 0))
                    ImGui.EndTable()
                end
            end
        end
        ImGui.EndChild()
        ImGui.PopID()
    end
    Ui.RenderToastNotifications(self.ToastStates)
    ImGui.End()

    return openGUI
end

return OptionsUI
