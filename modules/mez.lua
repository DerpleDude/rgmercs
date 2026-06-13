-- Sample Basic Class Module
local mq        = require('mq')
local Base      = require("modules.base")
local Casting   = require("utils.casting")
local Combat    = require("utils.combat")
local Comms     = require("utils.comms")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require('utils.globals')
local Logger    = require("utils.logger")
local Modules   = require("utils.modules")
local Strings   = require("utils.strings")
local Tables    = require("utils.tables")
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")
require('utils.datatypes')

local Module   = { _version = '2.0', _name = "Mez", _author = 'Derple', 'Algar', }
Module.__index = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                              = {}
Module.CommandHandlers                  = {
    enablemezentry = {
        usage = "/rgl enablemezentry \"<Name>\"",
        about = "Enables a mez ability entry by name.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledMezEntries') or {}
            enabled[name] = true
            Config:SetSetting('EnabledMezEntries', enabled)
            return true
        end,
    },
    disablemezentry = {
        usage = "/rgl disablemezentry \"<Name>\"",
        about = "Disables a mez ability entry by name.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledMezEntries') or {}
            enabled[name] = false
            Config:SetSetting('EnabledMezEntries', enabled)
            return true
        end,
    },
}

Module.CombatState                      = "None"

Module.Constants                        = {}
Module.Constants.MezSpawnFilter         = "targetable playerstate 4"

Module.TempSettings                     = {}
Module.TempSettings.MezImmune           = {}
Module.TempSettings.MezTracker          = {}
Module.TempSettings.MezAttemptId        = 0
Module.TempSettings.LastAEMezTime       = 0

-- NeedToMez gate cache: the spawn scan is throttled to this window so a busy DPS rotation doesn't re-run it every pump
Module.TempSettings.LastNeedToMezTime   = 0
Module.TempSettings.LastNeedToMezResult = false

Module.DefaultConfig                    = {
    -- per-entry on/off for the Mez ability list (flat name->bool, like EnabledRotationEntries); absent = on
    ['EnabledMezEntries']                      = {
        DisplayName = "EnabledMezEntries",
        Type = "Custom",
        Default = {},
    },
    --General
    ['MezOn']                                  = {
        DisplayName = "Enable Mezzing",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 1,
        Default = true,
        Tooltip = "Enables mezzing all forms of mezzing as a quick toggle, select particular actions to use below.",
    },
    ['PriorityMez']                            = {
        DisplayName = "Prioritize Mez",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 2,
        Default = true,
        Tooltip = "Hold Burn/DPS/debuff rotations while a needed mez is not yet landed.",
        ConfigType = "Advanced",
    },
    ['DoSTMez']                                = {
        DisplayName = "ST Mez Song/Spells",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 3,
        Default = true,
        Tooltip = "Enable the memorization and use of ST mez spells/songs.",
        RequiresLoadoutChange = true,
    },
    ['DoAEMez']                                = {
        DisplayName = "AE Mez Song/Spells",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 4,
        Default = true,
        Tooltip = "Enable the memorization and use of AE mez spells/songs.",
        RequiresLoadoutChange = true,
    },
    ['DoAAMez']                                = {
        DisplayName = "Use Mez AA",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 5,
        Default = true,
        Tooltip = "Use your class's mez AA abilities when available.",
    },
    ['MezStartCount']                          = {
        DisplayName = "Mez Start Count",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 6,
        Default = 2,
        Min = 1,
        Max = 20,
        Tooltip = "Start mezzing once at least this many mobs are engaged.",
    },
    ['MezAECount']                             = {
        DisplayName = "Mez AE Count",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 7,
        Tooltip = "Use AE mez instead of single-target once at least this many mobs are engaged.",
        Default = 3,
        Min = 1,
        Max = 20,
    },
    ['MaxMezCount']                            = {
        DisplayName = "Max Mez Count",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 8,
        Default = 13,
        Min = 1,
        Max = 30,
        Tooltip = "The maximum number of mobs we will track for mezzing.",
        ConfigType = "Advanced",
    },
    ['MezRadius']                              = {
        DisplayName = "Mez Radius",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 9,
        Default = 100,
        Min = 1,
        Max = 200,
        Tooltip = "The maximum distance away a potential mez target can be from the PC.",
        ConfigType = "Advanced",
    },
    ['MezZRadius']                             = {
        DisplayName = "Mez ZRadius",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 10,
        Default = 25,
        Min = 1,
        Max = 200,
        Tooltip = "The maximum height difference between the potential mez target and the PC.",
        ConfigType = "Advanced",
    },
    ['SafeAEMez']                              = {
        DisplayName = "AE Mez Safety Check",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez General",
        Index = 11,
        Tooltip = "Skip AE mez if a non-engaged NPC is in the blast we could aggro.",
        Default = false,
        ConfigType = "Advanced",
        FAQ = "Can you better explain the AE Mez Safety Check?",
        Answer = "If the option is enabled, the script will use various checks to determine if a non-hostile or not-aggroed NPC is present and avoid use of the mez.\n" ..
            "Unfortunately, the script currently cannot always discern whether an NPC is (un)attackable, so at times this may lead to the mez not being used when it is safe to do so.",
    },
    -- Targets
    ['MezStopHPs']                             = {
        DisplayName = "Mez Stop HPs",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez Targets",
        Index = 1,
        Default = 80,
        Min = 1,
        Max = 100,
        Tooltip = "Don't single-target mez a mob below this HP%.",
        ConfigType = "Advanced",
    },
    ['AutoLevelRange']                         = {
        DisplayName = "Auto Level Range",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez Targets",
        Index = 2,
        Default = true,
        Tooltip = "Use automatic mez max-level detection based on the current mez spell.",
        ConfigType = "Advanced",
    },
    ['MezMinLevel']                            = {
        DisplayName = "Mez Min Level",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez Targets",
        Index = 3,
        Default = 1,
        Min = 1,
        Max = 200,
        Tooltip = "If Auto Level Range is disabled, the minimum level of a potential mez target for mez spells.",
        ConfigType = "Advanced",
    },
    ['MezMaxLevel']                            = {
        DisplayName = "Mez Max Level",
        Group = "Abilities",
        Header = "Mez",
        Category = "Mez Targets",
        Index = 4,
        Default = 200,
        Min = 1,
        Max = 200,
        Tooltip = "If Auto Level Range is disabled, the maximum level of a potential mez target for mez spells.",
        ConfigType = "Advanced",
    },

    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:ShouldRender()
    return Modules:ExecModule("Class", "CanMez")
end

function Module:Render()
    Base.Render(self)

    ImGui.NewLine()

    if self.ModuleLoaded then
        -- status snapshot (display only; populated each DoMez tick)
        local status = self.TempSettings.Status
        local crowd = status and status.crowd or 0
        local unmezzed = status and status.unmezzed or 0
        local crowdColor = crowd >= Config:GetSetting('MezStartCount') and Globals.Constants.Colors.ConditionMidColor or Globals.Constants.Colors.ConditionPassColor
        local unmezzedColor = unmezzed == 0 and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionFailColor
        if ImGui.BeginTable("MezStatus", 2, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableNextColumn(); Ui.RenderText("Proximity Count")
            ImGui.TableNextColumn(); Ui.RenderColoredText(crowdColor, "%d", crowd)
            ImGui.TableNextColumn(); Ui.RenderText("Unmezzed")
            ImGui.TableNextColumn(); Ui.RenderColoredText(unmezzedColor, "%d", unmezzed)
            ImGui.TableNextColumn(); Ui.RenderText("ST Mez")
            ImGui.TableNextColumn(); self:RenderMezReady(Config:GetSetting('DoSTMez'), status and status.stReady)
            ImGui.TableNextColumn(); Ui.RenderText("AE Mez")
            ImGui.TableNextColumn(); self:RenderMezReady(Config:GetSetting('DoAEMez'), status and status.aeReady)
            ImGui.EndTable()
        end
        ImGui.Separator()

        -- per-entry enable/disable for the class's mez list (load_cond-filtered); rotation-only columns hidden
        if ImGui.CollapsingHeader("Mez Abilities") then
            ImGui.Indent()
            local list = self:GetMezAbilities()
            if list and #list > 0 then
                local enabled = Config:GetSetting('EnabledMezEntries') or {}
                local resolvedMap = {}
                for _, entry in ipairs(list) do
                    resolvedMap[entry.name] = Modules:ExecModule("Class", "GetResolvedActionMapItem", entry.name)
                end
                local _, newEnabled, changed = Ui.RenderRotationTable("MezAbilities", list, resolvedMap, 0, false, enabled, true)
                if changed then Config:SetSetting('EnabledMezEntries', newEnabled) end
            end
            ImGui.Unindent()
        end

        ImGui.Separator()
        -- CCEd targets
        if ImGui.CollapsingHeader("CC Target List") then
            ImGui.Indent()
            if ImGui.BeginTable("MezzedList", 4, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
                ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 70.0)
                ImGui.TableSetupColumn('Duration', (ImGuiTableColumnFlags.WidthFixed), 150.0)
                ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthFixed), 250.0)
                ImGui.TableSetupColumn('Spell', (ImGuiTableColumnFlags.WidthStretch), 150.0)
                ImGui.TableHeadersRow()
                for id, data in pairs(self.TempSettings.MezTracker) do
                    ImGui.TableNextColumn()
                    ImGui.Text(tostring(id))
                    ImGui.TableNextColumn()
                    if data.duration > 30000 then
                        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                    elseif data.duration > 15000 then
                        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionMidColor)
                    else
                        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                    end
                    ImGui.Text(tostring(Strings.FormatTime(math.max(0, data.duration / 1000))))
                    ImGui.PopStyleColor()
                    ImGui.TableNextColumn()
                    ImGui.Text(data.name)
                    ImGui.TableNextColumn()
                    ImGui.Text(data.mez_spell)
                end
                ImGui.EndTable()
            end
            ImGui.Unindent()
        end

        ImGui.Separator()
        -- Immune targets
        if ImGui.CollapsingHeader("Immune Target List") then
            ImGui.Indent()
            if ImGui.BeginTable("Immune", 2, bit32.bor(ImGuiTableFlags.None, ImGuiTableFlags.Borders)) then
                ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 70.0)
                ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 250.0)
                ImGui.TableHeadersRow()
                for id, data in pairs(self.TempSettings.MezImmune) do
                    ImGui.TableNextColumn()
                    ImGui.Text(tostring(id))
                    ImGui.TableNextColumn()
                    ImGui.Text(data.name)
                end
                ImGui.EndTable()
            end
            ImGui.Unindent()
        end
    end
end

-- status-cell for a mez direction: red Disabled if the toggle's off, else green Ready / red Not Ready
function Module:RenderMezReady(enabled, ready)
    if not enabled then
        Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, "Disabled")
    else
        Ui.RenderColoredText(ready and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionFailColor, ready and "Ready" or "Not Ready")
    end
end

function Module:HandleMezBroke(mobName, breakerName)
    Logger.log_debug("%s broke mez on ==> %s", breakerName, mobName)
    -- the break event gives only a name, so re-flag every same-named mob; the mez poll picks the real one
    for _, data in pairs(self.TempSettings.MezTracker) do
        if data.name == mobName then data.duration = 0 end
    end
    Comms.HandleAnnounce(
        Comms.FormatChatEvent("Mez Broken", mobName, breakerName), Config:GetSetting('MezAnnounceGroup'),
        Config:GetSetting('MezAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
end

function Module:AddImmuneTarget(mobId, mobData)
    if self.TempSettings.MezImmune[mobId] ~= nil then return end

    self.TempSettings.MezImmune[mobId] = mobData
end

function Module:IsMezImmune(mobId)
    return self.TempSettings.MezImmune[mobId] ~= nil
end

-- the mob our most recent mez landed on; the ImmuneMez event credits immunity here, since the live
-- Target may already be restored to something else by the time the (async) immune message arrives
function Module:GetMezAttemptId()
    return self.TempSettings.MezAttemptId or 0
end

function Module:ResetMezStates()
    self.TempSettings.MezImmune = {}
    self.TempSettings.MezTracker = {}
    self.TempSettings.MezAttemptId = 0
    self.TempSettings.LastNeedToMezTime = 0
    self.TempSettings.LastNeedToMezResult = false
end

-- Mez ability resolution (config-driven via ClassConfig.Mez, falls back to hardcoded class logic)

-- resolve a mez entry's identifier to its MQSpell (for TargetType / cast-time / range reads)
function Module:EntrySpell(entry)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then return Casting.GetAASpell(entry.name) end
    if entryType == "item" then return Casting.GetClickySpell(entry.name) end
    return Modules:ExecModule("Class", "GetResolvedActionMapItem", entry.name)
end

-- classify a mez spell by its TargetType; "single" means single-target, anything else is an AE
function Module:MezDelivery(spell)
    if not spell or not spell() then return "single" end
    local targetType = (spell.TargetType() or ""):lower()
    if targetType == "single" then return "single" end
    if targetType == "beam" or targetType == "directional ae" then return "directional" end
    if targetType:find("pb ae") or targetType:find("caster pb") then return "pbae" end
    if targetType:find("ae") then return "targeted" end
    Logger.log_warn("\arMez: unmapped TargetType '%s' for %s - treating as single-target.", spell.TargetType() or "?", spell.RankName() or "?")
    return "single"
end

-- only spell/song are gemmed abilities we ever WAIT on; AA/item run off reuse timers
function Module:EntryIsGemmed(entry)
    local entryType = (entry.type or ""):lower()
    return entryType == "spell" or entryType == "song"
end

-- type-dispatched readiness, mirroring Rotation.ExecEntry
function Module:EntryReady(entry, spell)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then return Casting.AAReady(entry.name) end
    if entryType == "item" then return Casting.ItemReady(entry.name) end
    if entryType == "song" then return Casting.SongReady(spell) end
    if entryType == "disc" then return Casting.DiscReady(spell) end
    return Casting.SpellReady(spell)
end

-- type-dispatched cast (AE spells allow a dead target, matching the old MezNow behavior)
function Module:EntryCast(entry, spell, mezId, useAE)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then
        Casting.UseAA(entry.name, mezId, useAE)
    elseif entryType == "item" then
        Casting.UseItem(entry.name, mezId, useAE)
    elseif entryType == "song" then
        Casting.UseSong(spell.RankName(), mezId, false, 2)
    elseif entryType == "disc" then
        Casting.UseDisc(spell, mezId)
    else
        Casting.UseSpell(spell.RankName(), mezId, false, useAE, 2)
    end
end

-- per-entry user toggle (defaults on; flat name->bool map)
function Module:EntryEnabled(entry)
    return (Config:GetSetting('EnabledMezEntries') or {})[entry.name] ~= false
end

-- centralizes the scattered `not entry.cond or entry.cond()` checks + the per-entry enable gate (mez cond is zero-arg)
function Module:EntryActive(entry)
    return self:EntryEnabled(entry) and (not entry.cond or entry.cond())
end

-- keep only entries whose load_cond passes (reuses the Class module's scan-time evaluator)
function Module:FilterLoaded(list)
    local out = {}
    for _, entry in ipairs(list or {}) do
        if Modules:ExecModule("Class", "LoadConditionPass", entry) then table.insert(out, entry) end
    end
    return out
end

-- rebuild the load_cond-filtered mez list on rescan, so a load-gated entry drops from both the cast logic and the UI
function Module:RebuildMezAbilities()
    local classConfig = Modules:ExecModule("Class", "GetClassConfig")
    local list = (classConfig and classConfig.Mez) or self:FallbackMezAbilities()
    self.TempSettings.MezAbilities = self:FilterLoaded(list)
end

-- the active mez ability list: the class config's load_cond-filtered ['Mez'] table, or the deprecated fallback
function Module:GetMezAbilities()
    if not self.TempSettings.MezAbilities then self:RebuildMezAbilities() end -- lazy build covers first-load ordering
    return self.TempSettings.MezAbilities
end

-- the Class module fires this on every rescan/mode change (ExecAll); rebuild our filtered list in lockstep with rotations
function Module:OnCombatModeChanged()
    self:RebuildMezAbilities()
end

-- ===== DEPRECATED FALLBACK (delete once every mez class config ships a ['Mez'] table) =====
-- Synthesizes the {type,name} list from today's hardcoded class logic so un-migrated configs keep working.
function Module:FallbackMezAbilities()
    if Core.MyClassIs("BRD") then
        return {
            { type = "AA",   name = "Dirge of the Sleepwalker", cond = function() return Config:GetSetting('DoAAMez') end, },
            { type = "Song", name = "MezSong", },
            { type = "Song", name = "MezAESong", },
        }
    end
    if Core.MyClassIs("ENC") then
        return {
            { type = "Spell", name = "TwinCastMez",     cond = function() return (Config:GetSetting('TwincastMez', true) or 0) > 1 end, },
            { type = "Spell", name = "MezSpell",        cond = function() return (Config:GetSetting('TwincastMez', true) or 0) == 1 end, },
            { type = "Spell", name = "MezAESpell", },
            { type = "AA",    name = "Beam of Slumber", cond = function() return Config:GetSetting('DoAAMez') end, },
        }
    end
    return {
        { type = "Spell", name = "MezSpell", },
        { type = "Spell", name = "MezAESpell", },
    }
end

-- ===== END DEPRECATED FALLBACK =====

-- first cond-passing entry of the wanted direction (false = ST, true = AE), preferring a gemmed
-- spell/song (whose cast time + max level we read for the refresh threshold and candidate scan)
function Module:ResolveMezSpell(wantAE)
    local list = self:GetMezAbilities()
    for pass = 1, 2 do
        for _, entry in ipairs(list) do
            if self:EntryActive(entry) and (pass == 2 or self:EntryIsGemmed(entry)) then
                local spell = self:EntrySpell(entry)
                if spell and spell() and ((self:MezDelivery(spell) ~= "single") == wantAE) then return spell end
            end
        end
    end
    return nil
end

function Module:GetMezSpell()
    return self:ResolveMezSpell(false)
end

function Module:GetAEMezSpell()
    return self:ResolveMezSpell(true)
end

-- Build the attempt announce ("Mez <target>" or "Mez AoE Around <target>") with the ability name
function Module:AnnounceMez(useAE, mezId, entry, spell)
    local target = mq.TLO.Spawn(mezId).CleanName() or "Unknown"
    local targetLabel = useAE and ("AoE Around " .. target) or target
    local entryType = (entry.type or ""):lower()
    local ability
    if entryType == "aa" then
        ability = "AA: " .. entry.name
    elseif entryType == "item" then
        ability = "Item: " .. entry.name
    else
        ability = spell.RankName()
    end
    Comms.HandleAnnounce(Comms.FormatChatEvent("Mez", targetLabel, ability), Config:GetSetting('MezAnnounceGroup'),
        Config:GetSetting('MezAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
end

-- Cast the first ready, in-priority ability of the requested direction on the current target.
-- Returns true only when a gemmed ability is off cooldown but momentarily busy (caller should hold the tick).
function Module:MezAttempt(mezId, useAE)
    local waitForGem = false
    -- first ready ability in order wins; we only wait if none are ready. A per-entry `fallbackOnly`
    -- flag could be added later if a ready lower AA (e.g. Beam) shouldn't preempt waiting for a busy spell.
    for _, entry in ipairs(self:GetMezAbilities()) do
        if self:EntryActive(entry) then
            local spell = self:EntrySpell(entry)
            if spell and spell() then
                local delivery = self:MezDelivery(spell)
                if (delivery ~= "single") == useAE then
                    if self:EntryReady(entry, spell) then
                        -- clear an in-progress cast/song so a cast-time mez can start; an instant mez (e.g. Dirge) fires mid-song, so leave the twist alone
                        if (spell.MyCastTime() or 0) > 0 then self:StopCast() end
                        if delivery == "directional" then
                            Core.DoCmd("/face fast")
                            mq.delay(5)
                        end
                        self:AnnounceMez(useAE, mezId, entry, spell)
                        self.TempSettings.MezAttemptId = mezId
                        Logger.log_verbose("Mez: %s on %s [%s]", entry.name, mq.TLO.Spawn(mezId).CleanName() or "?", delivery)
                        self:EntryCast(entry, spell, mezId, useAE)
                        mq.doevents('ImmuneMez')
                        return false
                    elseif self:EntryIsGemmed(entry) and Casting.GemReady(spell) then
                        waitForGem = true
                    end
                end
            end
        end
    end
    return waitForGem
end

-- Bail a mez wait if we should stop, are backing off, or (mid-ST-wait) the crowd grew enough to want AE
function Module:ShouldAbortMezWait(useAE)
    if not Core.IsMezzing() or Globals.BackOffFlag then return true end
    if not useAE and self:CountCrowd() >= Config:GetSetting('MezAECount') and self:CountUnmezzed() > 0 and self:MezReady(true) then
        return true
    end
    return false
end

-- Mez the target: attempt now, and if the chosen ability is busy, hold the tick for it (bounded, abortable).
function Module:CastMez(mezId, useAE)
    Core.DoCmd("/attack off")
    local currentTargetID = mq.TLO.Target.ID()
    Targeting.SetTarget(mezId, true)

    if self:MezAttempt(mezId, useAE) then
        local maxWaitToMez = 1500 + (mq.TLO.Window("CastingWindow").Open() and (mq.TLO.Me.Casting.MyCastTime() or 3000) or 0)
        Casting.WaitForReady(
            function() return not self:MezAttempt(mezId, useAE) end,
            maxWaitToMez,
            function() return self:ShouldAbortMezWait(useAE) end)
    end

    Targeting.SetTarget(currentTargetID, true)
end

-- Is any cond-passing, enabled mez ability ready now (or gemmed and just momentarily busy)? wantAE filters delivery: true=AE, false=ST, nil=either.
function Module:MezReady(wantAE)
    for _, entry in ipairs(self:GetMezAbilities()) do
        if self:EntryActive(entry) then
            local spell = self:EntrySpell(entry)
            if spell and spell() then
                local isAE = self:MezDelivery(spell) ~= "single"
                local enabled = (isAE and Config:GetSetting('DoAEMez')) or (not isAE and Config:GetSetting('DoSTMez'))
                if enabled and (wantAE == nil or isAE == wantAE) then
                    if self:EntryReady(entry, spell) then return true end
                    if self:EntryIsGemmed(entry) and Casting.GemReady(spell) then return true end
                end
            end
        end
    end
    return false
end

function Module:AEMezCheck()
    if not Config:GetSetting('DoAEMez') then return end
    if Globals.BackOffFlag then return end
    if not self:MezReady(true) then
        Logger.log_verbose("AEMezCheck - no AE mez ready, skipping")
        return
    end

    local aeMezSpell = self:GetAEMezSpell()
    if not aeMezSpell or not aeMezSpell() then return end

    if not aeMezSpell.AERange() or aeMezSpell.AERange() == 0 then
        Logger.log_warn("\arWarning AE Mez Spell: %s has no AERange!", aeMezSpell.RankName())
    end

    -- target the main assist's mob; the AE lands here
    Combat.FindBestAutoTarget()
    if Globals.AutoTargetID == 0 then
        Logger.log_verbose("AEMezCheck - no autotarget for the AE, skipping")
        return
    end

    -- bail if an idle (non-engaged) NPC sits in the blast we'd aggro
    if Config:GetSetting('SafeAEMez') then
        local total, engaged
        if self:MezDelivery(aeMezSpell) == "pbae" then
            -- point-blank AE lands on us; range isn't reliably exposed, so check MezRadius around self
            local radius = Config:GetSetting('MezRadius')
            total = mq.TLO.SpawnCount(string.format("npc radius %d targetable", radius))()
            engaged = mq.TLO.SpawnCount(string.format("npc radius %d %s", radius, self.Constants.MezSpawnFilter))()
        else
            -- targeted / directional AE lands on the autotarget
            local center = mq.TLO.Spawn(Globals.AutoTargetID)
            if not center or not center() then return end
            local aeRange = aeMezSpell.AERange() or 0
            total = mq.TLO.SpawnCount(string.format("npc loc %0.2f, %0.2f radius %d targetable", center.X(), center.Y(), aeRange))()
            engaged = mq.TLO.SpawnCount(string.format("npc loc %0.2f, %0.2f radius %d %s", center.X(), center.Y(), aeRange, self.Constants.MezSpawnFilter))()
        end
        if total > engaged then
            Logger.log_debug("\ayAEMezCheck() :: SafeAEMez bail - %d in blast > %d engaged", total, engaged)
            return
        end
    end

    Logger.log_debug("\awNOTICE:\ax AE mez on our main assist's mob.")
    self:CastMez(Globals.AutoTargetID, true)
    self.TempSettings.LastAEMezTime = Globals.GetTimeMS()

    mq.doevents('ImmuneMez')
end

function Module:RemoveCCTarget(mobId)
    if mobId == 0 then return end
    self.TempSettings.MezTracker[mobId] = nil
end

function Module:AddCCTarget(mobId)
    if mobId == 0 then return end

    if Tables.GetTableSize(self.TempSettings.MezTracker) >= Config:GetSetting('MaxMezCount') and self.TempSettings.MezTracker[mobId] == nil then
        Logger.log_debug("\awNOTICE:\ax Unable to mez %d - mez list is full", mobId)
        return false
    end

    if self:IsMezImmune(mobId) then
        Logger.log_debug("\awNOTICE:\ax Unable to mez %d - it is immune", mobId)
        return false
    end

    self:StopAttack()

    Targeting.SetTarget(mobId)

    self.TempSettings.MezTracker[mobId] = {
        name = mq.TLO.Target.CleanName(),
        duration = (mq.TLO.Target.Mezzed.Duration.TotalSeconds() or 0) * 1000,
        last_check = Globals.GetTimeMS(),
        mez_spell = mq.TLO
            .Target.Mezzed() or "None",
    }
end

-- a player's pet we never count or mez: our swarm pets (IsTempPet) or anything a PC owns/charms
function Module:IsPlayerPet(spawn)
    return Targeting.IsTempPet(spawn) or spawn.Master.Type() == "PC"
end

function Module:IsValidMezTarget(mobId)
    local spawn = mq.TLO.Spawn(mobId)

    if self:IsPlayerPet(spawn) then
        Logger.log_super_verbose("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d as it is a player's pet.",
            spawn.ID(), spawn.CleanName(), spawn.Level() or 0)
        return false
    end

    -- a charm pet in recovery (broken, being re-charmed) is protected; don't mez it out from under the charmer
    if Globals.CharmedPetIDs:contains(mobId) then
        Logger.log_super_verbose("\ayUpdateMezList: Skipping Mob ID: %d - charm pet in recovery.", mobId)
        return false
    end

    -- Is the mob ID in our mez immune list? If so, skip.
    if self:IsMezImmune(mobId) then
        Logger.log_super_verbose("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d as it is in our immune list.",
            spawn.ID(), spawn.CleanName(), spawn.Level() or 0)
        return false
    end
    -- future: body-gated mez (e.g. necro undead-only) - give ['Mez'] entries a bodyType and reject a mob no enabled entry can target (the giant rule below is the same body-check shape)
    if Targeting.TargetBodyIs(spawn, "giant") then
        Logger.log_debug(
            "\ayUpdateMezList: Adding ID: %d Name: %s Level: %d to our immune list as it is a giant.", spawn.ID(),
            spawn.CleanName(),
            spawn.Level())
        self:AddImmuneTarget(spawn.ID(), { id = spawn.ID(), name = spawn.CleanName(), })
        return false
    end

    if spawn and not spawn.LineOfSight() then
        Logger.log_super_verbose("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d - No LOS.", spawn.ID(),
            spawn.CleanName(), spawn.Level() or 0)
        return false
    end

    if (spawn.PctHPs() or 0) < Config:GetSetting('MezStopHPs') then
        Logger.log_super_verbose("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d - HPs too low.", spawn.ID(),
            spawn.CleanName(), spawn.Level() or 0)
        return false
    end

    if (spawn.Distance() or 999) > Config:GetSetting('MezRadius') then
        Logger.log_super_verbose("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d - Out of Mez Radius",
            spawn.ID(), spawn.CleanName(), spawn.Level() or 0)
        return false
    end

    return true
end

function Module:UpdateMezList()
    local searchTypes = { "npc", "npcpet", }

    -- the scan only needs a spell for its level range; fall back to AE so disabling the ST entry doesn't stop AE mez
    local mezSpell = self:GetMezSpell() or self:GetAEMezSpell()

    if not mezSpell or not mezSpell() then
        Logger.log_verbose("\ayayUpdateMezList: No mez spell - bailing!")
        return
    end

    -- AddCCTarget tabs the target onto each mob it adds; remember the entry target so we don't leave combat/FaceTarget on a mez mob
    local restoreTargetID = mq.TLO.Target.ID()
    local scanned, added = 0, 0

    for _, searchType in ipairs(searchTypes) do
        local minLevel = Config:GetSetting('MezMinLevel')
        local maxLevel = Config:GetSetting('MezMaxLevel')

        if Config:GetSetting('AutoLevelRange') and mezSpell and mezSpell() then
            minLevel = 0
            ---@diagnostic disable-next-line: undefined-field
            maxLevel = mezSpell.MaxLevel()
        end
        local searchString = string.format("%s radius %d zradius %d range %d %d %s", searchType,
            Config:GetSetting('MezRadius'), Config:GetSetting('MezZRadius'), minLevel, maxLevel, self.Constants.MezSpawnFilter)

        local mobCount = mq.TLO.SpawnCount(searchString)()
        Logger.log_super_verbose("\ayUpdateMezList: Search String: '\at%s\ay' -- Count :: \am%d", searchString, mobCount)
        for i = 1, mobCount do
            local spawn = mq.TLO.NearestSpawn(i, searchString)

            if spawn and spawn() and spawn.ID() > 0 then
                scanned = scanned + 1
                Logger.log_super_verbose(
                    "\ayUpdateMezList: Processing MobCount %d -- ID: %d Name: %s Level: %d BodyType: %s", i, spawn.ID(),
                    spawn.CleanName(), spawn.Level(),
                    spawn.Body.Name())

                if self:IsValidMezTarget(spawn.ID()) then
                    added = added + 1
                    Logger.log_super_verbose("\agAdding to CC List: %d -- ID: %d Name: %s Level: %d BodyType: %s", i,
                        spawn.ID(), spawn.CleanName(), spawn.Level(), spawn.Body.Name())
                    self:AddCCTarget(spawn.ID())
                end
            end
        end
    end
    Logger.log_debug("\ayUpdateMezList: scanned %d, added %d to CC list", scanned, added)

    Targeting.SetTarget(restoreTargetID, true)
    mq.doevents()
end

function Module:ProcessMezList()
    -- Assume by default we never need to block for mez. We'll set this if-and-only-if
    -- we need to mez but our ability is on cooldown.
    Core.DoCmd("/attack off")
    -- we tab the target through each mez mob below; remember the entry target so combat/FaceTarget
    -- isn't left pointed at a mez mob instead of the kill target when we're done
    local restoreTargetID = mq.TLO.Target.ID()
    Logger.log_debug("\ayProcessMezList() :: Loop")
    local mezSpell = self:GetMezSpell()

    if not mezSpell or not mezSpell() then return end

    if not Config:GetSetting('DoSTMez') and self:CountCrowd() < Config:GetSetting('MezAECount') then
        Logger.log_debug("\ayProcessMezList() :: ST mez off and under AE count, returning.")
        return
    end

    local castTime = self:MezRefreshThreshold()
    local removeList = {}
    for id, data in pairs(self.TempSettings.MezTracker) do
        local spawn = mq.TLO.Spawn(id)
        Logger.log_debug("\ayProcessMezList(%d) :: Checking...", id)

        if not spawn or not spawn() or spawn.Dead() or Targeting.TargetIsType("corpse", spawn) or (spawn.ID() or 0) == Globals.AutoTargetID then
            table.insert(removeList, id)
            Logger.log_debug("\ayProcessMezList(%d) :: Can't find mob removing...", id)
        else
            if self:IsMezImmune(id) then
                -- somehow added an immune mod to our tracker...
                Logger.log_debug("\ayProcessMezList(%d) :: Mob id is in immune list - removing...", id)
                table.insert(removeList, id)
            else
                -- skip if still solidly mezzed, out of range, or no LOS (duration and cast time are ms)
                if data.duration > castTime or spawn.Distance() > Config:GetSetting('MezRadius') or not spawn.LineOfSight() then
                    Logger.log_debug("\ayProcessMezList(%d) :: Timer(%s > %s) Distance(%d) LOS(%s)", id,
                        Strings.FormatTime(data.duration / 1000),
                        Strings.FormatTime(castTime / 1000), spawn.Distance() or 0,
                        Strings.BoolToColorString(spawn.LineOfSight()))
                else
                    Logger.log_debug("\ayProcessMezList(%d) :: Mob needs mezzing.", id)

                    self:StopAttack()

                    -- let dying mobs go: ST respects MezStopHPs (AE still blankets them)
                    if (spawn.PctHPs() or 0) < Config:GetSetting('MezStopHPs') then
                        Logger.log_debug("\ayProcessMezList(%d) :: HP below MezStopHPs, ST skipping.", id)
                    else
                        -- re-verify mez state directly, then single-target if still needed
                        Targeting.SetTarget(id)
                        -- right after an AE, a freshly-blasted mob's mez buff can lag the read; poll (ping-scaled) for it before trusting "unmezzed"
                        if Globals.GetTimeMS() - self.TempSettings.LastAEMezTime < 1000 then
                            mq.delay((mq.TLO.EverQuest.Ping() * 2) + 250, function() return mq.TLO.Target.Mezzed.ID() ~= nil end)
                        end
                        if Config:GetSetting('DoSTMez') and not mq.TLO.Target.Mezzed() then
                            Logger.log_debug("\ayProcessMezList(%d) :: Single target mez needed.", id)
                            self:CastMez(id, false)
                        end

                        if mq.TLO.Target.Mezzed.ID() then
                            self:AddCCTarget(id)
                        end
                    end
                end
            end
        end
    end

    for _, id in ipairs(removeList) do
        self:RemoveCCTarget(id)
    end

    Targeting.SetTarget(restoreTargetID, true)
    mq.doevents()
end

function Module:DoMez()
    local mezSpell = self:GetMezSpell()
    local aeMezSpell = self:GetAEMezSpell()

    -- drop dead/gone mobs first so nothing stale gets counted
    self:PruneStale()
    self:UpdateTimings()

    local crowd = self:CountCrowd()
    -- snapshot for the status panel (display only); piggybacks on the crowd scan above, no extra scan
    self.TempSettings.Status = {
        crowd = crowd,
        unmezzed = self:CountUnmezzed(),
        stReady = self:MezReady(false),
        aeReady = self:MezReady(true),
    }

    -- nothing to do below the start threshold; let any leftover mezzes wear off
    if crowd < Config:GetSetting('MezStartCount') then return end

    self:UpdateMezList()

    -- AE when the crowd is big enough AND something actually needs locking
    local unmezzed = self:CountUnmezzed()
    if aeMezSpell and aeMezSpell() and crowd >= Config:GetSetting('MezAECount') and unmezzed > 0 then
        Logger.log_debug("\ayDoMez() :: AE mez: crowd \am%d\ay >= AECount \am%d\ay, \am%d\ay unmezzed", crowd, Config:GetSetting('MezAECount'), unmezzed)
        self:AEMezCheck()
    end

    -- single-target whatever still needs it
    local tableSize = Tables.GetTableSize(self.TempSettings.MezTracker)
    if mezSpell and mezSpell() and tableSize >= 1 then
        self:ProcessMezList()
    else
        Logger.log_verbose("DoMez() : Skipping Mez list processing: Spell(%s) Ready(%s) TableSize(%d)", mezSpell and mezSpell() or "None",
            mezSpell and mezSpell() and Strings.BoolToColorString(mq.TLO.Me.SpellReady(mezSpell.RankName())()) or "NoSpell",
            tableSize)
    end

    -- refresh after the mezzing work so the panel reflects this tick's tracker, not the pre-work snapshot
    self.TempSettings.Status.unmezzed = self:CountUnmezzed()
end

-- ms a tracked mez must still have left to count as solidly locked (cast time + refresh lead)
function Module:MezRefreshThreshold()
    local mezSpell = self:GetMezSpell()
    return ((mezSpell and mezSpell() and mezSpell.MyCastTime()) or 3000) + 3000 -- add 3 seconds of extra time so it doesn't get loose
end

-- count tracked mobs still needing mez (unmezzed or about to expire), excluding the kill target
function Module:CountUnmezzed()
    local castTime = self:MezRefreshThreshold()
    local count = 0
    for id, data in pairs(self.TempSettings.MezTracker) do
        if id ~= Globals.AutoTargetID and data.duration <= castTime then
            count = count + 1
        end
    end
    return count
end

-- count engaged enemy NPCs/pets in range, skipping our own swarm/charmed pets; the "is there a crowd worth scanning" gate
function Module:CountCrowd()
    local radius = Config:GetSetting('MezRadius')
    local zradius = Config:GetSetting('MezZRadius')
    local count = 0
    for _, searchType in ipairs({ "npc", "npcpet", }) do
        local search = string.format("%s radius %d zradius %d %s", searchType, radius, zradius, self.Constants.MezSpawnFilter)
        local matches = mq.TLO.SpawnCount(search)()
        for i = 1, matches do
            local spawn = mq.TLO.NearestSpawn(i, search)
            if spawn and spawn() and not self:IsPlayerPet(spawn) then count = count + 1 end
        end
    end
    return count
end

-- True when an engaged, mezzable mob in range isn't solidly locked yet (scans live, so fresh adds count); gate DPS/Burn rotations on Core.OkayToNotMez().
function Module:NeedToMez()
    -- throttled to every 250ms to avoid excessive checks each rotation
    if Globals.GetTimeMS() - self.TempSettings.LastNeedToMezTime < 250 then
        return self.TempSettings.LastNeedToMezResult
    end
    self.TempSettings.LastNeedToMezTime = Globals.GetTimeMS()

    local ready = self:MezReady()
    local crowd, anyUnmezzed = 0, false
    if ready then -- nothing castable now (disabled or on cooldown) skips the scan, so DPS isn't held
        local castTime = self:MezRefreshThreshold()
        local radius = Config:GetSetting('MezRadius')
        local zradius = Config:GetSetting('MezZRadius')
        for _, searchType in ipairs({ "npc", "npcpet", }) do
            local search = string.format("%s radius %d zradius %d %s", searchType, radius, zradius, self.Constants.MezSpawnFilter)
            local matches = mq.TLO.SpawnCount(search)()
            for i = 1, matches do
                local spawn = mq.TLO.NearestSpawn(i, search)
                if spawn and spawn() and not self:IsPlayerPet(spawn) then
                    crowd = crowd + 1
                    local id = spawn.ID() or 0
                    if id ~= Globals.AutoTargetID and not self:IsMezImmune(id) then
                        local tracked = self.TempSettings.MezTracker[id]
                        if not (tracked and tracked.duration > castTime) then anyUnmezzed = true end
                    end
                end
            end
        end
    end
    local crowdOk = crowd >= Config:GetSetting('MezStartCount')
    local result = ready and crowdOk and anyUnmezzed

    Logger.log_verbose("NeedToMez - MezReady(%s) CrowdOk(%s [%d/%d]) Unmezzed(%s) => %s",
        Strings.BoolToColorString(ready), Strings.BoolToColorString(crowdOk), crowd, Config:GetSetting('MezStartCount'),
        Strings.BoolToColorString(anyUnmezzed), Strings.BoolToColorString(result))

    self.TempSettings.LastNeedToMezResult = result
    return result
end

-- drop tracked/immune entries whose spawn is dead or gone, so they never pollute the count or lists
function Module:PruneStale()
    for id, _ in pairs(self.TempSettings.MezTracker) do
        local spawn = mq.TLO.Spawn(id)
        if not spawn() or spawn.Dead() then
            self.TempSettings.MezTracker[id] = nil
        end
    end
    for id, _ in pairs(self.TempSettings.MezImmune) do
        local spawn = mq.TLO.Spawn(id)
        if not spawn() or spawn.Dead() then
            self.TempSettings.MezImmune[id] = nil
        end
    end
end

function Module:UpdateTimings()
    for _, data in pairs(self.TempSettings.MezTracker) do
        local timeDelta = (Globals.GetTimeMS()) - data.last_check

        data.duration = data.duration - timeDelta

        data.last_check = Globals.GetTimeMS()
    end
end

function Module:GiveTime()
    local combat_state = Combat.GetCachedCombatState()

    if not Core.IsMezzing() then return end

    if mq.TLO.Navigation.Active() or mq.TLO.MoveTo.Moving() then return end

    -- dead... whoops
    if mq.TLO.Me.Hovering() then return end

    if self.CombatState ~= combat_state and combat_state == "Downtime" then
        self:ResetMezStates()
    end

    self.CombatState = combat_state

    self:DoMez()
end

function Module:OnZone()
    self:ResetMezStates()
end

function Module:StopAttack()
    if mq.TLO.Me.Combat() then
        Logger.log_debug("\awMEZ:\ax Stopping attack to avoid breaking mez.")
        Core.DoCmd("/attack off")
        mq.delay(500, function() return mq.TLO.Me.Combat() == false end)
    end
end

function Module:StopCast()
    if mq.TLO.Me.Casting() then
        Logger.log_debug("\awMEZ:\ax Stopping cast or song so I can mez.")
        mq.TLO.Me.StopCast()
        mq.delay("3s", function() return mq.TLO.Window("CastingWindow").Open() == false end)
    end
end

return Module
