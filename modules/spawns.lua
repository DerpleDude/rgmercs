-- Sample Spawns Class Module
local mq        = require('mq')
local Icons     = require('mq.ICONS')
local Base      = require("modules.base")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Modules   = require("utils.modules")
local Strings   = require("utils.strings")
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")

local Module    = { _version = '1.1', _name = "Spawns", _author = 'Derple, Algar, Grimmier', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })

Module.CachedNamedList = {}
Module.ShowDownNamed   = false
Module.CommandHandlers = {}

Module.NamedList       = {}
Module.LastNamedCheck  = 0
Module.LastRenderTime  = 0

Module.DefSpawnList    = Core.OnMight() and require('spawnlist.eqmight') or Core.OnLaz() and require('spawnlist.lazarus') or require('spawnlist.live')

Module.FlagOrder       = {
    { kind = "named", value = true,   label = "Named",       section = "Targeting", },
    { kind = "named", value = false,  label = "Not Named",   section = "Targeting", },
    { kind = "deny",  label = "Deny", section = "Targeting", },
}
for _, e in ipairs(Globals.Constants.ResistTypes) do table.insert(Module.FlagOrder, { kind = "elementalImmunities", key = e, label = e, section = "Elemental Immunity", }) end
for _, e in ipairs(Globals.Constants.ImmunityEffects) do table.insert(Module.FlagOrder, { kind = "statusImmunities", key = e, label = e, section = "Status Immunity", }) end

function Module:FlagSummary(entry)
    local parts = {}
    if entry.named == false then
        table.insert(parts, "Not Named")
    elseif entry.named then
        table.insert(parts, "Named")
    end
    if entry.deny then
        table.insert(parts, "Deny")
    end
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
    ['SpawnList'] = {
        DisplayName = "Zone Spawn List",
        Type = "Custom",
        Default = {},
        Scope = "server",
        OnChange = function() Modules:ExecModule("Spawns", "InvalidateSpawnList") end,
        FAQ = "Can I add my own named NPCs, immunity flags, or denied targets to RGMercs?",
        Answer = "Open the Spawns module tab and add your current target via the Zone Spawn List editor. " ..
            "Each row's Flags combo toggles Named/Not Named, Deny (never auto-target this mob), elemental immunity flags (Fire/Cold/Magic/Poison/Disease), and status immunity flags (Slow/Snare/Stun). " ..
            "CLI alternatives: /rgl spawnadd, /rgl spawndeny, /rgl namedadd, /rgl nameddeny, and /rgl immuneadd; remove with /rgl spawndelete, /rgl spawndenydelete, /rgl nameddelete, and /rgl immunedelete.\n\n" ..
            "This per-server, per-zone list is shared in real-time with all RGMercs peers on this machine.",
    },
}

Module.FAQ           = {
    {
        Question = "Why am I not taking any special actions on a Named, boss, or mission mob?",
        Answer =
            "  RGMercs default class configs fully support burning, using defenses, or other special actions on Named mobs, " ..
            "however, your target must be identified as such. There are several ways to make this happen:\n\n" ..
            "  1) Add the mob to the Zone Spawn List on the Spawns module tab and set the Named flag, or use /rgl namedadd.\n\n" ..
            "  2) The built-in Spawn List: RGMercs ships a list of known nameds per zone for your server. If a mob is on the list, RGMercs treats it as a Named automatically.\n\n" ..
            "  3) SpawnMaster (optional): If 'Check SM For Named' is enabled and MQ2SpawnMaster is loaded, RGMercs queries it via TLO. Useful if you already maintain SpawnMaster watch lists.\n\n" ..
            "  4) Alert Master (optional): If 'Check AM For Named' is enabled and the Alert Master script is loaded, RGMercs queries it via TLO. Useful if you already maintain Alert Master alert lists.\n\n" ..
            "  Specific feedback on missing, incorrect, or otherwise erroneous entries on the built-in RGMercs Spawn List is always welcome!\n\n",
        Settings_Used = "",
    },
    {
        Question = "How does the Spawn List handle resists and immunities?",
        Answer =
            "  The Spawn List is a per-zone, per-mob registry. Each entry can carry any combination of:\n\n" ..
            "  * Named flag - treat the mob as a named (enables burns and other named-specific actions).\n" ..
            "  * Elemental immunity flags - Fire, Cold, Magic, Poison, Disease. Rotation entries whose spell uses a flagged resist type are skipped on this mob.\n" ..
            "  * Status immunity flags - Slow, Snare, Stun. Rotation entries that gate on the corresponding immunity will respect the flag.\n\n" ..
            "  These checks only apply to your combat auto-target - buffs, heals, and group abilities are not affected.\n\n" ..
            "  Add or edit flags from the Spawns module tab (Flags combo on each row), or via /rgl immuneadd and /rgl immunedelete (which accept both elemental and status keywords).\n\n" ..
            "  RGMercs ships built-in immunity data for some mobs (see the 'Use Immune Data' setting). " ..
            "Specific feedback on missing or erroneous entries is always welcome!",
        Settings_Used = "UseImmuneData, SkipFireSpells, SkipColdSpells, SkipMagicSpells, SkipPoisonSpells, SkipDiseaseSpells",
    },
    {
        Question = "Can I have RGMercs never auto-target certain mobs in a zone (e.g. boss adds)?",
        Answer =
            "  Yes. Open the Spawns module tab, target the mob, click \"Add Target To List\", then check the Deny flag in the row's Flags combo. " ..
            "CLI: /rgl spawndeny and /rgl spawndenydelete operate on your current target or a supplied name.\n\n" ..
            "  Deny is per-zone and per-server, and shared in real-time with all RGMercs peers on this machine. " ..
            "Force-target overrides deny - to engage a denied mob, force-target it via the Force Target window or /rgl forcetarget.\n\n" ..
            "  For a temporary, this-session-only version, use the IT column in the Force Target window or /rgl ignoretarget instead.",
        Settings_Used = "",
    },
}

function Module:New()
    return Base.New(self)
end

-- ===== DEPRECATED MIGRATION (sunset 1/1/27 - one-shot 'Named' -> 'Spawns' settings copy; delete this whole block) =====
function Module:MergeZoneRegistries(oldList, newList)
    local merged = {}
    for zoneKey, zoneTbl in pairs(oldList or {}) do
        merged[zoneKey] = {}
        for mobName, entry in pairs(zoneTbl) do
            merged[zoneKey][mobName] = entry
        end
    end
    for zoneKey, zoneTbl in pairs(newList or {}) do
        merged[zoneKey] = merged[zoneKey] or {}
        for mobName, entry in pairs(zoneTbl) do
            merged[zoneKey][mobName] = entry
        end
    end
    return merged
end

function Module:LoadSettings()
    Base.LoadSettings(self, function()
        local oldList = Config.Db:getServerValue(Globals.ServerEnv, 'Named', 'CustomNamedList')
        if oldList ~= nil then
            for zoneKey, zoneTbl in pairs(oldList) do
                if type(zoneTbl) == "table" and #zoneTbl > 0 and type(zoneTbl[1]) == "string" then
                    local converted = {}
                    for _, mobName in ipairs(zoneTbl) do
                        converted[mobName] = { named = true, }
                    end
                    oldList[zoneKey] = converted
                end
            end
            for _, zoneTbl in pairs(oldList) do
                if type(zoneTbl) == "table" then
                    local renames = {}
                    for mobName in pairs(zoneTbl) do
                        if type(mobName) == "string" then
                            local trimmed = Strings.TrimSpaces(mobName)
                            if trimmed ~= mobName and trimmed and trimmed ~= "" then
                                renames[mobName] = trimmed
                            end
                        end
                    end
                    for mobName, trimmed in pairs(renames) do
                        zoneTbl[trimmed] = zoneTbl[trimmed] or zoneTbl[mobName]
                        zoneTbl[mobName] = nil
                    end
                end
            end
            local newList = Config.Db:getServerValue(Globals.ServerEnv, 'Spawns', 'SpawnList')
            local merged = newList and self:MergeZoneRegistries(oldList, newList) or oldList
            Config.Db:migrateServerModule(Globals.ServerEnv, 'Named', 'Spawns', 'SpawnList', merged)
        end
        Config.Db:deleteModule(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, 'Named')
    end)
end

-- ===== END DEPRECATED MIGRATION (sunset 1/1/27) =====

function Module:Render()
    Base.Render(self)
    ImGui.NewLine()
    self:RenderZoneNamed()
    self:RenderZoneSpawnList()
end

function Module:OnZone()
    self.LastZoneID = -1
    Globals.ZoneDenyNames = {}
    Globals.ZoneHasDeny = false
end

function Module:GiveTime()
    self:RefreshSpawnCache()
    if Globals.GetTimeSeconds() - self.LastRenderTime >= 2 then return end
    if Globals.GetTimeSeconds() - self.LastNamedCheck > 1 then
        self.LastNamedCheck = Globals.GetTimeSeconds()
        self:CheckZoneNamed()
    end
end

function Module:IngestDefEntry(namedList, item, mergeImmunities)
    if type(item) == "string" then
        local key = item:lower()
        local e = namedList[key] or {}
        e.named = true
        e.displayName = e.displayName or item
        namedList[key] = e
    elseif type(item) == "table" and item.name then
        local key = item.name:lower()
        local e = namedList[key] or {}
        e.displayName = e.displayName or item.name
        if item.named ~= false then e.named = true end
        if mergeImmunities then
            if item.elementalImmunities then e.elementalImmunities = item.elementalImmunities end
            if item.statusImmunities then e.statusImmunities = item.statusImmunities end
        end
        namedList[key] = e
    end
end

function Module:CompileSpawnList(shipped, user, zoneFull, zoneShort, mergeImmunities)
    local namedList = {}
    local shippedSection = shipped[zoneFull]
    if not (shippedSection and next(shippedSection) ~= nil) then shippedSection = shipped[zoneShort] end
    for _, item in ipairs(shippedSection or {}) do
        self:IngestDefEntry(namedList, item, mergeImmunities)
    end

    local denyNames, hasDeny = {}, false
    local userSection = user[zoneFull]
    if not (userSection and next(userSection) ~= nil) then userSection = user[zoneShort] end
    for mobName, userEntry in pairs(userSection or {}) do
        if type(userEntry) == "table" then
            local key = mobName:lower()
            local e = namedList[key] or {}
            e.displayName = e.displayName or mobName
            if userEntry.named == false then
                e.named = false
            elseif userEntry.named then
                e.named = true
            end
            if userEntry.elementalImmunities then
                e.elementalImmunities = e.elementalImmunities or {}
                for k, v in pairs(userEntry.elementalImmunities) do e.elementalImmunities[k] = v end
            end
            if userEntry.statusImmunities then
                e.statusImmunities = e.statusImmunities or {}
                for k, v in pairs(userEntry.statusImmunities) do e.statusImmunities[k] = v end
            end
            if userEntry.deny then
                denyNames[Strings.TrimSpaces(mobName):lower()] = true
                hasDeny = true
            end
            namedList[key] = e
        end
    end
    return namedList, denyNames, hasDeny
end

--- Compiles and publishes the zone spawn list (registry plus deny products) when the zone or user list changes.
function Module:RefreshSpawnCache()
    if self.LastZoneID == Globals.CurZoneId and Globals.GetTimeSeconds() - (self.LastCacheRefresh or 0) < 1 then return end
    self.LastCacheRefresh = Globals.GetTimeSeconds()
    -- LastUserList identity catches cross-instance edits; local edits invalidate via OnChange.
    local userList = Config:GetSetting('SpawnList') or {}
    if self.LastZoneID ~= Globals.CurZoneId or self.LastUserList ~= userList then
        self.LastZoneID = Globals.CurZoneId
        self.LastUserList = userList
        self.NamedList, Globals.ZoneDenyNames, Globals.ZoneHasDeny = self:CompileSpawnList(self.DefSpawnList, userList,
            (mq.TLO.Zone.Name() or ""):lower(), (mq.TLO.Zone.ShortName() or ""):lower(),
            Config:GetSetting('UseImmuneData'))
    end
end

function Module:CheckZoneNamed()
    self:RefreshSpawnCache()
    local upNameds = {}
    local tmpTbl = {}

    local namedSpawns = mq.getFilteredSpawns(function(spawn)
        return spawn.Type() == "NPC" and self:IsNamed(spawn)
    end)

    for _, spawn in ipairs(namedSpawns) do
        local name = spawn.CleanName()
        if name then
            local key = name:lower()
            table.insert(tmpTbl, {
                Name       = name,
                Spawn      = spawn,
                Distance   = spawn and spawn.Distance() or 9999,
                Loc        = spawn and spawn.LocYXZ() or "0,0,0",
                Immunities = self:ImmunitySummary(self.NamedList[key]),
            })
            upNameds[key] = true
        end
    end

    for key, entry in pairs(self.NamedList) do
        if entry.named and not upNameds[key] then
            table.insert(tmpTbl, {
                Name       = entry.displayName or key,
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

--- Checks if the given spawn is a named entity.
--- @param spawn MQSpawn The spawn object to check.
--- @return boolean True if the spawn is named, false otherwise.
function Module:IsNamed(spawn)
    if not spawn or not spawn() then return false end

    if Targeting.ForceNamed then return true end

    self:RefreshSpawnCache()

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

    local entry = self.NamedList[(spawn.Name() or ""):lower()]
        or self.NamedList[(spawn.CleanName() or ""):lower()]
        or self.NamedList[(cleanNameFixed or ""):lower()]
    if entry and entry.named then return true end

    ---@diagnostic disable-next-line: undefined-field
    if Config:GetSetting('CheckSMForNamed') and mq.TLO.Plugin("MQ2SpawnMaster").IsLoaded() and mq.TLO.SpawnMaster.HasSpawn ~= nil and mq.TLO.SpawnMaster.HasSpawn(spawn.ID())() then return true end

    ---@diagnostic disable-next-line: undefined-field
    if Config:GetSetting('CheckAMForNamed') and mq.TLO.AlertMaster ~= nil and mq.TLO.AlertMaster.IsNamed(spawn.DisplayName())() then return true end

    return false
end

--- Sets the Named flag on a mob in the current zone's Spawn List.
function Module:AddNamedToCustomList(npcName)
    Config:ZoneRegistrySetFlag(npcName, 'SpawnList', 'named', true)
end

--- Clears the Named or Not Named flag on a mob in the current zone's Spawn List.
function Module:DeleteNamedFromCustomList(arg1)
    Config:ZoneRegistryClearFlag(arg1, 'SpawnList', 'named')
end

--- Sets the Not Named flag on a mob, overriding any shipped named entry.
function Module:AddNotNamedToCustomList(npcName)
    Config:ZoneRegistrySetFlag(npcName, 'SpawnList', 'named', false)
end

--- Adds a bare flagless row for a mob to the current zone's Spawn List.
function Module:AddSpawnToList(name)
    Config:ZoneRegistryAddEntry(name, 'SpawnList')
end

--- Sets the Deny flag on a mob so it is never auto-targeted.
function Module:AddDenyToCustomList(npcName)
    Config:ZoneRegistrySetFlag(npcName, 'SpawnList', 'deny', true)
end

--- Clears the Deny flag on a mob in the current zone's Spawn List.
function Module:DeleteDenyFromCustomList(arg1)
    Config:ZoneRegistryClearFlag(arg1, 'SpawnList', 'deny')
end

--- Removes a mob entry entirely from SpawnList (regardless of which flags are set).
function Module:DeleteEntryFromCustomList(mobName, zoneKey)
    mobName = Strings.TrimSpaces(mobName)
    local list = Config:GetSetting('SpawnList') or {}
    zoneKey = zoneKey or Config:ZoneRegistryDefaultZoneKey(list)
    if list[zoneKey] and list[zoneKey][mobName] then
        list[zoneKey][mobName] = nil
        Config:SetSetting('SpawnList', list)
    end
end

function Module:GetRegistryEntry(mobName)
    self:RefreshSpawnCache()
    mobName = Strings.TrimSpaces(mobName)
    if not mobName then return nil end
    return self.NamedList[mobName:lower()] or nil
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
    self:RefreshSpawnCache()
    for _, element in ipairs(Globals.Constants.ResistTypes) do
        if self:HasElementalImmunity(cleanName, element) then elementalImmunities[element] = true end
    end
    for _, effect in ipairs(Globals.Constants.ImmunityEffects) do
        if self:HasStatusImmunity(cleanName, effect) then statusImmunities[effect] = true end
    end
    return elementalImmunities, statusImmunities
end

--- Invalidates the cached spawn list, recompiles and republishes it immediately, and refreshes the
--- auto-target immunity profile. Called from OnChange when the list or UseImmuneData changes.
function Module:InvalidateSpawnList()
    self.LastZoneID = -1
    self:RefreshSpawnCache()
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

function Module:RenderZoneNamed()
    if not ImGui.CollapsingHeader("Zone Named") then return end
    self.LastRenderTime = Globals.GetTimeSeconds()
    self.ShowDownNamed, _ = Ui.RenderOptionToggle("ShowDown", "Show Downed Named", self.ShowDownNamed)

    if ImGui.BeginTable("Zone Named", 5, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable)) then
        ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthFixed), 250.0)
        ImGui.TableSetupColumn('Up', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Distance', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthFixed), 160.0)
        ImGui.TableSetupColumn('Immunities', (ImGuiTableColumnFlags.WidthStretch), 1.0)
        ImGui.TableHeadersRow()

        for _, named in ipairs(self.CachedNamedList) do
            local namedSpawn = named.Spawn
            local spawnExists = namedSpawn and namedSpawn()

            if spawnExists and namedSpawn.PctHPs() > 0 then
                ImGui.TableNextColumn()
                local _, clicked = ImGui.Selectable(string.format("%s##%d", named.Name, namedSpawn.ID()), false)
                if clicked then
                    namedSpawn.DoTarget()
                end
                ImGui.TableNextColumn()
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                Ui.RenderText(Icons.FA_SMILE_O)
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                Ui.RenderText(tostring(math.ceil(named.Distance)))
                ImGui.TableNextColumn()
                Ui.NavEnabledLoc(named.Loc)
                ImGui.TableNextColumn()
                if named.Immunities and named.Immunities ~= "" then
                    local availW = ImGui.GetContentRegionAvail()
                    local textW = ImGui.CalcTextSize(named.Immunities)
                    Ui.RenderText(named.Immunities)
                    if textW > availW and ImGui.IsItemHovered() then
                        ImGui.SetTooltip(named.Immunities)
                    end
                end
            elseif spawnExists or self.ShowDownNamed then
                ImGui.TableNextColumn()
                Ui.RenderText(named.Name)
                ImGui.TableNextColumn()
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                Ui.RenderText(Icons.FA_FROWN_O)
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                ImGui.TableNextColumn()
                ImGui.TableNextColumn()
                if named.Immunities and named.Immunities ~= "" then
                    local availW = ImGui.GetContentRegionAvail()
                    local textW = ImGui.CalcTextSize(named.Immunities)
                    Ui.RenderText(named.Immunities)
                    if textW > availW and ImGui.IsItemHovered() then
                        ImGui.SetTooltip(named.Immunities)
                    end
                end
            end
        end

        ImGui.EndTable()
    end
end

function Module:RenderZoneSpawnList()
    if ImGui.CollapsingHeader("Zone Spawn List") then
        local invalidTarget = not (mq.TLO.Target() and Targeting.TargetIsType("NPC"))
        ImGui.BeginDisabled(invalidTarget)
        ImGui.PushID("##_small_btn_add_target_custom_named")
        if ImGui.SmallButton(invalidTarget and "Select an NPC to Add" or "Add Target To List") then
            self:AddSpawnToList(mq.TLO.Target.CleanName())
        end
        ImGui.PopID()
        ImGui.EndDisabled()

        if ImGui.BeginTable("SpawnList", 3, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable)) then
            ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, 250.0)
            ImGui.TableSetupColumn('Flags', ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn('Del', ImGuiTableColumnFlags.WidthFixed, 30.0)
            ImGui.TableHeadersRow()

            local spawnList = Config:GetSetting('SpawnList') or {}
            local zoneKey = Config:ZoneRegistryDefaultZoneKey(spawnList)
            local zoneList = spawnList[zoneKey] or {}

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
                    local prevSection
                    for _, f in ipairs(self.FlagOrder) do
                        if f.section ~= prevSection then
                            ImGui.SeparatorText(f.section)
                            prevSection = f.section
                        end
                        local current
                        if f.kind == "named" then
                            current = entry.named == f.value
                        elseif f.kind == "deny" then
                            current = entry.deny == true
                        else
                            current = (entry[f.kind] and entry[f.kind][f.key]) == true
                        end
                        local newValue = ImGui.Checkbox(f.label, current)
                        if newValue ~= current then
                            if f.kind == "named" then
                                if newValue then
                                    Config:ZoneRegistrySetFlag(mobName, "SpawnList", "named", f.value, zoneKey)
                                else
                                    Config:ZoneRegistryClearFlag(mobName, "SpawnList", "named", nil, zoneKey)
                                end
                            elseif f.kind == "deny" then
                                if newValue then
                                    Config:ZoneRegistrySetFlag(mobName, "SpawnList", "deny", true, zoneKey)
                                else
                                    Config:ZoneRegistryClearFlag(mobName, "SpawnList", "deny", nil, zoneKey)
                                end
                            else
                                Config:ZoneRegistrySetSubFlag(mobName, "SpawnList", f.kind, f.key, newValue, zoneKey)
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
