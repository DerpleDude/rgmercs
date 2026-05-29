-- Sample Named Class Module
local mq           = require('mq')
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Logger       = require("utils.logger")
local Modules      = require("utils.modules")
local Strings      = require("utils.strings")
local Targeting    = require("utils.targeting")
local Ui           = require("utils.ui")
local Icons        = require('mq.ICONS')
local NamedDefault = require("namedlist.named_default")
local NamedEQMight = require("namedlist.named_eqmight")
local Base         = require("modules.base")

local Module       = { _version = '1.1', _name = "Named", _author = 'Derple, Algar, Grimmier', }
Module.__index     = Module
setmetatable(Module, { __index = Base, })

Module.CachedNamedList = {}
Module.CommandHandlers = {}

Module.NamedList       = {}
Module.LastNamedCheck  = 0

Module.DefNamed        = {}

if Core.OnMight() then
    Module.DefNamed = NamedEQMight or {}
else
    Module.DefNamed = NamedDefault or {}
end

Module.FlagOrder = { { kind = "named", key = nil, label = "Named", }, }
for _, e in ipairs(Globals.Constants.ResistTypes)     do table.insert(Module.FlagOrder, { kind = "elementalImmunities", key = e, label = e, }) end
for _, e in ipairs(Globals.Constants.ImmunityEffects) do table.insert(Module.FlagOrder, { kind = "statusImmunities",    key = e, label = e, }) end

function Module:FlagSummary(entry)
    local parts = {}
    if entry.named then table.insert(parts, "Named") end
    for _, key in ipairs(Globals.Constants.ResistTypes) do
        if entry.elementalImmunities and entry.elementalImmunities[key] then table.insert(parts, key) end
    end
    for _, key in ipairs(Globals.Constants.ImmunityEffects) do
        if entry.statusImmunities and entry.statusImmunities[key] then table.insert(parts, key) end
    end
    return #parts > 0 and table.concat(parts, ", ") or "None"
end

--- Returns a comma-joined summary of just the immunity flags (no "Named"),
--- for views where named status is already implicit (e.g. the spawned named list).
function Module:ImmunitySummary(entry)
    if not entry then return "" end
    local parts = {}
    for _, key in ipairs(Globals.Constants.ResistTypes) do
        if entry.elementalImmunities and entry.elementalImmunities[key] then table.insert(parts, key) end
    end
    for _, key in ipairs(Globals.Constants.ImmunityEffects) do
        if entry.statusImmunities and entry.statusImmunities[key] then table.insert(parts, key) end
    end
    return table.concat(parts, ", ")
end

Module.DefaultConfig = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['CustomNamedList'] = {
        DisplayName = "Custom Named List",
        Type = "Custom",
        Default = {},
        Scope = "server",
        OnChange = function() Modules:ExecModule("Named", "InvalidateNamedList") end,
        FAQ = "Can I add my own named NPCs and immunity flags to RGMercs?",
        Answer = "Open the Named module tab and add your current target via the Custom Named List editor. " ..
            "Each row's Flags combo toggles Named, elemental immunity flags (Fire/Cold/Magic/Poison/Disease), and status immunity flags (Slow/Snare/Stun). " ..
            "CLI alternatives: /rgl namedadd and /rgl immuneadd (plus matching delete commands).\n\n" ..
            "This per-server, per-zone list is shared in real-time with all RGMercs peers on this machine.",
    },
}

Module.FAQ           = {
    {
        Question = "Why am I not taking any special actions on a Named, boss, or mission mob?",
        Answer =
            "  RGMercs default class configs fully support burning, using defenses, or other special actions on Named mobs, " ..
            "however, your target must be identified as such. There are several ways to make this happen:\n\n" ..
            "  1) Add Named NPCs using the UI on the Named module tab, or using the CLI (search the command list for \"named\").\n\n" ..
            "  2) The built-in Named List: RGMercs has a list of known nameds per zone. If a mob is on the list, RGMercs treats it as a Named automatically.\n\n" ..
            "  3) SpawnMaster (optional): If 'Check SM For Named' is enabled and MQ2SpawnMaster is loaded, RGMercs queries it via TLO. Useful if you already maintain SpawnMaster watch lists.\n\n" ..
            "  4) Alert Master (optional): If 'Check AM For Named' is enabled and the Alert Master script is loaded, RGMercs queries it via TLO. Useful if you already maintain Alert Master alert lists.\n\n" ..
            "  Specific feedback on missing, incorrect, or otherwise erroneous entries on the built-in RGMercs Named List is always welcome!\n\n",
        Settings_Used = "",
    },
    {
        Question = "How does the Named List handle resists and immunities?",
        Answer =
            "  The Named List is a per-zone, per-mob registry. Each entry can carry any combination of:\n\n" ..
            "  * Named flag - treat the mob as a named (enables burns and other named-specific actions).\n" ..
            "  * Elemental immunity flags - Fire, Cold, Magic, Poison, Disease. Rotation entries whose spell uses a flagged resist type are skipped on this mob.\n" ..
            "  * Status immunity flags - Slow, Snare, Stun. Rotation entries that gate on the corresponding immunity will respect the flag.\n\n" ..
            "  These checks only apply to your combat auto-target - buffs, heals, and group abilities are not affected.\n\n" ..
            "  Add or edit flags from the Named module tab (Flags combo on each row), or via /rgl immuneadd and /rgl immunedelete (which accept both elemental and status keywords).\n\n" ..
            "  RGMercs ships built-in immunity data for some mobs (see the 'Use Immune Data' setting). " ..
            "Specific feedback on missing or erroneous entries is always welcome!",
        Settings_Used = "UseImmuneData, SkipFireSpells, SkipColdSpells, SkipMagicSpells, SkipPoisonSpells, SkipDiseaseSpells",
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Render()
    Base.Render(self)
    Ui.RenderZoneNamed()
    ImGui.NewLine()
    self:RenderCustomNamedList()
end

function Module:GiveTime()
    -- Main Module logic goes here.
    if Globals.GetTimeSeconds() - self.LastNamedCheck > 1 then
        self.LastNamedCheck = Globals.GetTimeSeconds()
        self:CheckZoneNamed()
    end
end

--- Migrates legacy CustomNamedList array shape to the registry shape.
--- Legacy: { [zone] = { "Mob1", "Mob2", ... } }
--- New:    { [zone] = { ["Mob1"] = { named = true }, ... } }
function Module:MigrateCustomNamedListShape()
    local raw = Config:GetSetting('CustomNamedList') or {}
    local dirty = false
    for zoneKey, zoneTbl in pairs(raw) do
        if type(zoneTbl) == "table" and #zoneTbl > 0 and type(zoneTbl[1]) == "string" then
            local converted = {}
            for _, mobName in ipairs(zoneTbl) do
                converted[mobName] = { named = true, }
            end
            raw[zoneKey] = converted
            dirty = true
        end
    end
    -- Normalize keys: trim leading/trailing whitespace on existing entries (older entries may
    -- have been written with spaces from CleanName() before the write-side strip was added).
    for zoneKey, zoneTbl in pairs(raw) do
        if type(zoneTbl) == "table" then
            for mobName, entry in pairs(zoneTbl) do
                if type(mobName) == "string" then
                    local trimmed = Strings.TrimSpaces(mobName)
                    if trimmed ~= mobName and trimmed and trimmed ~= "" then
                        zoneTbl[trimmed] = zoneTbl[trimmed] or entry
                        zoneTbl[mobName] = nil
                        dirty = true
                    end
                end
            end
        end
    end
    if dirty then
        Config:SetSetting('CustomNamedList', raw)
        Logger.log_info("\ayCustomNamedList normalized (legacy shape and/or whitespace keys).")
    end
end

function Module:IngestDefEntry(item, mergeImmunities)
    if type(item) == "string" then
        self.NamedList[item] = self.NamedList[item] or {}
        self.NamedList[item].named = true
    elseif type(item) == "table" and item.name then
        local e = self.NamedList[item.name] or {}
        if item.named ~= false then e.named = true end
        if mergeImmunities then
            if item.elementalImmunities then e.elementalImmunities = item.elementalImmunities end
            if item.statusImmunities    then e.statusImmunities    = item.statusImmunities    end
        end
        self.NamedList[item.name] = e
    end
end

--- Caches the named list in the zone
function Module:RefreshNamedCache()
    local curZone = mq.TLO.Zone.ID()
    -- LastUserList identity catches cross-instance edits; local edits invalidate via OnChange.
    local userList = Config:GetSetting('CustomNamedList') or {}
    if self.LastZoneID ~= curZone or self.LastUserList ~= userList then
        self:MigrateCustomNamedListShape()
        userList = Config:GetSetting('CustomNamedList') or {}

        self.LastZoneID = curZone
        self.LastUserList = userList
        self.NamedList = {}

        local mergeImmunities = Config:GetSetting('UseImmuneData')
        local zoneFull = (mq.TLO.Zone.Name() or ""):lower()
        local zoneShort = (mq.TLO.Zone.ShortName() or ""):lower()

        for _, item in ipairs(self.DefNamed[zoneFull] or {}) do
            self:IngestDefEntry(item, mergeImmunities)
        end

        for _, item in ipairs(self.DefNamed[zoneShort] or {}) do
            self:IngestDefEntry(item, mergeImmunities)
        end

        for mobName, userEntry in pairs(userList[zoneShort] or {}) do
            if type(userEntry) == "table" then
                local e = self.NamedList[mobName] or {}
                if userEntry.named then e.named = true end
                if userEntry.elementalImmunities then
                    e.elementalImmunities = e.elementalImmunities or {}
                    for k, v in pairs(userEntry.elementalImmunities) do e.elementalImmunities[k] = v end
                end
                if userEntry.statusImmunities then
                    e.statusImmunities = e.statusImmunities or {}
                    for k, v in pairs(userEntry.statusImmunities) do e.statusImmunities[k] = v end
                end
                self.NamedList[mobName] = e
            end
        end
    end
end

function Module:CheckZoneNamed()
    self:RefreshNamedCache()
    local upNameds = {}
    local tmpTbl = {}

    local namedSpawns = mq.getFilteredSpawns(function(spawn)
        return self:IsNamed(spawn) and spawn.Type() == "NPC"
    end)

    for _, spawn in ipairs(namedSpawns) do
        local name = spawn.CleanName()
        table.insert(tmpTbl, {
            Name      = name,
            Spawn     = spawn,
            Distance  = spawn and spawn.Distance() or 9999,
            Loc       = spawn and spawn.LocYXZ() or "0,0,0",
            Immunities = self:ImmunitySummary(self.NamedList[name]),
        })
        upNameds[name] = true
    end

    for name, entry in pairs(self.NamedList) do
        if entry.named and not upNameds[name] then
            table.insert(tmpTbl, {
                Name       = name,
                Spawn      = nil,
                Distance   = 9999,
                Loc        = "0,0,0",
                Immunities = self:ImmunitySummary(entry),
            })
        end
    end

    table.sort(tmpTbl, function(a, b)
        return a.Distance < b.Distance
    end)

    self.CachedNamedList = tmpTbl
end

function Module:GetNamedList()
    return self.CachedNamedList
end

--- Checks if the given spawn is a named entity.
--- @param spawn MQSpawn The spawn object to check.
--- @return boolean True if the spawn is named, false otherwise.
function Module:IsNamed(spawn)
    if not spawn or not spawn() then return false end

    if Targeting.ForceNamed then return true end

    self:RefreshNamedCache()

    local cleanNameFixed = spawn.CleanName()
    if cleanNameFixed then
        -- if first or last character is a space then remove it.
        while cleanNameFixed:sub(1, 1) == " " do
            cleanNameFixed = cleanNameFixed:sub(2)
        end
        while cleanNameFixed:sub(-1) == " " do
            cleanNameFixed = cleanNameFixed:sub(1, -2)
        end
    end

    local entry = self.NamedList[spawn.Name()] or self.NamedList[spawn.CleanName()] or self.NamedList[cleanNameFixed]
    if entry and entry.named then return true end

    ---@diagnostic disable-next-line: undefined-field
    if Config:GetSetting('CheckSMForNamed') and mq.TLO.Plugin("MQ2SpawnMaster").IsLoaded() and mq.TLO.SpawnMaster.HasSpawn ~= nil and mq.TLO.SpawnMaster.HasSpawn(spawn.ID())() then return true end

    ---@diagnostic disable-next-line: undefined-field
    if Config:GetSetting('CheckAMForNamed') and mq.TLO.AlertMaster ~= nil and mq.TLO.AlertMaster.IsNamed(spawn.DisplayName())() then return true end

    return false
end

function Module:AddNamedToCustomList(npcName)
    Config:ZoneRegistrySetFlag(npcName, 'CustomNamedList', 'named', true)
end

function Module:DeleteNamedFromCustomList(arg1)
    Config:ZoneRegistryClearFlag(arg1, 'CustomNamedList', 'named')
end

--- Removes a mob entry entirely from CustomNamedList (regardless of which flags are set).
--- Used by the UI trash button to match the original delete UX.
function Module:DeleteEntryFromCustomList(mobName, zoneKey)
    zoneKey = zoneKey or (mq.TLO.Zone.ShortName() or ""):lower()
    local list = Config:GetSetting('CustomNamedList') or {}
    if list[zoneKey] and list[zoneKey][mobName] then
        list[zoneKey][mobName] = nil
        Config:SetSetting('CustomNamedList', list)
    end
end

function Module:GetRegistryEntry(mobName)
    self:RefreshNamedCache()
    mobName = Strings.TrimSpaces(mobName)
    if not mobName then return nil end
    return self.NamedList[mobName] or nil
end

function Module:HasElementalImmunity(mobName, element)
    local e = self:GetRegistryEntry(mobName)
    return e and e.elementalImmunities and e.elementalImmunities[element] == true or false
end

function Module:HasStatusImmunity(mobName, effect)
    local e = self:GetRegistryEntry(mobName)
    return e and e.statusImmunities and e.statusImmunities[effect] == true or false
end

--- Returns (elementalImmunities, statusImmunities) sub-tables for a mob by clean name in the current zone.
--- Used by Combat.FindAutoTarget to populate Globals.AutoTargetElementalImmunities / AutoTargetStatusImmunities
--- at target acquisition. Returns fresh tables (not aliased to the cached entry) so callers
--- can mutate them without affecting the registry.
function Module:GetImmuneFlags(cleanName)
    local elementalImmunities, statusImmunities = {}, {}
    if not cleanName or cleanName == "" then return elementalImmunities, statusImmunities end
    self:RefreshNamedCache()
    for _, element in ipairs(Globals.Constants.ResistTypes) do
        if self:HasElementalImmunity(cleanName, element) then elementalImmunities[element] = true end
    end
    for _, effect in ipairs(Globals.Constants.ImmunityEffects) do
        if self:HasStatusImmunity(cleanName, effect) then statusImmunities[effect] = true end
    end
    return elementalImmunities, statusImmunities
end

--- Invalidates the cached named list (forcing a rebuild next access) and refreshes the
--- auto-target immunity profile immediately. Called from OnChange when the list or UseImmuneData changes.
function Module:InvalidateNamedList()
    self.LastZoneID = -1
    self:RefreshAutoTargetProfile()
end

--- Refreshes Globals.AutoTargetElementalImmunities / AutoTargetStatusImmunities against the current auto-target.
--- Called from OnChange callbacks when registry contents or UseImmuneData change mid-combat,
--- so the immunity gate reflects the new flags without requiring a target re-acquisition.
function Module:RefreshAutoTargetProfile()
    if not Globals.AutoTargetID or Globals.AutoTargetID == 0 then return end
    local cleanName = mq.TLO.Spawn(Globals.AutoTargetID).CleanName() or ""
    Globals.AutoTargetElementalImmunities, Globals.AutoTargetStatusImmunities = self:GetImmuneFlags(cleanName)
end

function Module:RenderCustomNamedList()
    if ImGui.CollapsingHeader("Custom Named List") then
        if mq.TLO.Target() and Targeting.TargetIsType("NPC") then
            ImGui.PushID("##_small_btn_add_target_custom_named")
            if ImGui.SmallButton("Add Target To List") then
                self:AddNamedToCustomList(mq.TLO.Target.CleanName())
            end
            ImGui.PopID()
        end

        if ImGui.BeginTable("CustomNamedList", 3, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable)) then
            ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, 130.0)
            ImGui.TableSetupColumn('Flags', ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn('Del', ImGuiTableColumnFlags.WidthFixed, 30.0)
            ImGui.TableHeadersRow()

            local zoneKey = (mq.TLO.Zone.ShortName() or ""):lower()
            local zoneList = (Config:GetSetting('CustomNamedList') or {})[zoneKey] or {}

            local names = {}
            for k, _ in pairs(zoneList) do table.insert(names, k) end
            table.sort(names)

            for idx, mobName in ipairs(names) do
                local entry = zoneList[mobName] or {}
                ImGui.TableNextColumn()
                Ui.RenderText(mobName)
                ImGui.TableNextColumn()
                ImGui.PushID("##_combo_flags_custom_named_" .. tostring(idx))
                local summary = self:FlagSummary(entry)
                local availW = ImGui.GetContentRegionAvail()
                local textW = ImGui.CalcTextSize(summary)
                local previewW = availW - ImGui.GetFrameHeight() - ImGui.GetStyle().FramePadding.x * 2
                local overflowing = textW > previewW
                ImGui.SetNextItemWidth(-1)
                local opened = ImGui.BeginCombo("##flags", summary)
                if overflowing and summary ~= "None" and ImGui.IsItemHovered() then
                    ImGui.SetTooltip(summary)
                end
                if opened then
                    local prevKind
                    for _, f in ipairs(self.FlagOrder) do
                        if f.kind ~= prevKind then
                            if f.kind == "elementalImmunities" then
                                ImGui.SeparatorText("Elemental Immunity")
                            elseif f.kind == "statusImmunities" then
                                ImGui.SeparatorText("Status Immunity")
                            end
                            prevKind = f.kind
                        end
                        local current
                        if f.kind == "named" then
                            current = entry.named == true
                        else
                            current = entry[f.kind] and entry[f.kind][f.key] == true
                        end
                        local newValue = ImGui.Checkbox(f.label, current)
                        if newValue ~= current then
                            if f.kind == "named" then
                                Config:ZoneRegistrySetFlag(mobName, "CustomNamedList", "named", newValue, zoneKey)
                            else
                                Config:ZoneRegistrySetSubFlag(mobName, "CustomNamedList", f.kind, f.key, newValue, zoneKey)
                            end
                        end
                    end
                    ImGui.EndCombo()
                end
                ImGui.PopID()
                ImGui.TableNextColumn()
                ImGui.PushID("##_small_btn_delete_custom_named_" .. tostring(idx))
                if ImGui.SmallButton(Icons.FA_TRASH) then
                    self:DeleteEntryFromCustomList(mobName, zoneKey)
                end
                ImGui.PopID()
            end

            ImGui.EndTable()
        end

        ImGui.Spacing()
        Ui.RenderText("Note: This list is shared in real-time with all RGMercs peers on this machine.")
    end
end

return Module
