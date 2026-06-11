local mq        = require('mq')
local Icons     = require('mq.ICONS')
local Set       = require('mq.set')
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
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")

require('utils.datatypes')

local Module   = { _version = '2.0', _name = "Charm", _author = 'Grimmier, Algar', }
Module.__index = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                                = {
    {
        Question = "How do I charm one specific mob?",
        Answer =
        "Target it and click 'Charm This Target' in the Charm panel (or use /rgl forcecharm <id>); it holds until the mob is in range, then charms it. /rgl forcecharmclear cancels.",
        Settings_Used = "",
    },
    {
        Question = "Charm stopped working after I added a mob to the Allow list?",
        Answer = "Once your Allow list has any entries, only those mobs are charmed. Clear the list to charm anything valid again.",
        Settings_Used = "",
    },
}
Module.CommandHandlers                    = {}

Module.CombatState                        = "None"
Module.TempSettings                       = {}
Module.TempSettings.CharmImmune           = {}
Module.TempSettings.CharmTracker          = {}
Module.TempSettings.CharmAttemptId        = 0
Module.TempSettings.ValidCharmAbilities   = {}
Module.TempSettings.LastCharmAbilityCheck = 0

-- gate caches: the NeedToCharm spawn scan and the assist scan are throttled so a busy rotation doesn't re-run them every pump
Module.TempSettings.LastNeedToCharmTime   = 0
Module.TempSettings.LastNeedToCharmResult = false
Module.TempSettings.LastCharmAssistTime   = 0
Module.TempSettings.LastCharmAssistResult = false

Module.DefaultConfig                      = {
    -- per-entry on/off, scoped per list so shared names toggle independently: { Abilities = {name->bool}, PreCharm = {...}, Assist = {...} }; absent = on
    ['EnabledCharmEntries']                    = {
        DisplayName = "EnabledCharmEntries",
        Type        = "Custom",
        Default     = {},
    },
    -- General
    ['CharmOn']                                = {
        DisplayName           = "Charm On",
        Group                 = "Abilities",
        Header                = "Charm",
        Category              = "Charm General",
        Index                 = 1,
        Default               = false,
        Tooltip               = "Charm a valid nearby mob to fight for you.",
        RequiresLoadoutChange = true,
        FAQ                   = "Charm is on but nothing happens, why?",
        Answer                = "Charm needs a valid mob nearby - it skips Named, immune, wrong-bodytype, and out-of-level-range mobs.",
    },
    ['CharmAbility']                           = {
        DisplayName           = "Charm Ability",
        Tooltip               = "Which ability to charm with (chosen in the Charm panel).",
        Type                  = "Custom",
        Default               = 1,
        RequiresLoadoutChange = true,
    },
    ['PersistCharm']                           = {
        DisplayName = "Persistent Charm",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm General",
        Index       = 2,
        Default     = true,
        Tooltip     = "Automatically re-charm the same mob if your charm breaks.",
    },
    ['UseSharedCharmLists']                    = {
        DisplayName = "Use Shared Charm Lists",
        Type        = "Custom",
        Default     = false,
    },
    ['DoCharmAssist']                          = {
        DisplayName = "Charm Assist",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm General",
        Index       = 3,
        Default     = true,
        Tooltip     = "Help lock a groupmate's loose charm with a configured ability (if your class has one).",
        ConfigType  = "Advanced",
    },
    -- Targets
    ['AutoLevelRangeCharm']                    = {
        DisplayName = "Auto Level Range",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm Targets",
        Index       = 3,
        Default     = true,
        Tooltip     = "Use automatic charm max-level detection based on the current charm spell.",
        ConfigType  = "Advanced",
    },
    ['CharmRadius']                            = {
        DisplayName = "Charm Radius",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm Targets",
        Index       = 1,
        Default     = 100,
        Min         = 1,
        Max         = 200,
        Tooltip     = "The maximum distance away a potential charm target can be from the PC.",
    },
    ['CharmZRadius']                           = {
        DisplayName = "Charm ZRadius",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm Targets",
        Index       = 2,
        Default     = 15,
        Min         = 1,
        Max         = 200,
        Tooltip     = "The maximum height difference between the potential charm target and the PC.",
    },
    ['CharmMinLevel']                          = {
        DisplayName = "Charm Min Level",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm Targets",
        Index       = 4,
        Default     = 1,
        Min         = 1,
        Max         = 200,
        Tooltip     = "If Auto Level Range is disabled, the minimum level of a potential charm target.",
        ConfigType  = "Advanced",
    },
    ['CharmMaxLevel']                          = {
        DisplayName = "Charm Max Level",
        Group       = "Abilities",
        Header      = "Charm",
        Category    = "Charm Targets",
        Index       = 5,
        Default     = 200,
        Min         = 1,
        Max         = 200,
        Tooltip     = "If Auto Level Range is disabled, the maximum level of a potential charm target.",
        ConfigType  = "Advanced",
        Warning     = function()
            local charmSpell = Core.GetResolvedActionMapItem('CharmSpell')
            local spellMax = charmSpell and charmSpell() and charmSpell.MaxLevel() or 0
            if spellMax > 0 and Config:GetSetting('CharmMaxLevel') > spellMax then
                return true, string.format("Warning: Charm Max Level (%d) is above your charm spell's max (%d) - mobs over %d can't be charmed.",
                    Config:GetSetting('CharmMaxLevel'), spellMax, spellMax)
            end
            return false, ""
        end,
    },
    ['CharmAllowList']                         = {
        DisplayName = "Allow List",
        Type        = "Custom",
        Default     = {},
    },
    ['CharmDenyList']                          = {
        DisplayName = "Deny List",
        Type        = "Custom",
        Default     = {},
    },
    ['CharmAllowListShared']                   = {
        DisplayName = "Shared Allow List",
        Type        = "Custom",
        Default     = {},
        Scope       = "server",
    },
    ['CharmDenyListShared']                    = {
        DisplayName = "Shared Deny List",
        Type        = "Custom",
        Default     = {},
        Scope       = "server",
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type        = "Custom",
        Default     = false,
    },
    -- spawn id of the charm we currently hold, persisted so a script restart can re-identify the pet as our charm (ids are stable within a zone session)
    ['LastCharmPetID']                         = {
        DisplayName = "Last Charm Pet ID",
        Type        = "Custom",
        Default     = 0,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Init()
    Base.Init(self)
end

-- Command Handlers

Module.CommandHandlers = {
    forcecharm = {
        usage = "/rgl forcecharm <id?>",
        about = "Force-charm your target or <id>; held until in range. /rgl forcecharmclear to cancel.",
        handler = function(self, arg)
            local charmId = arg and tonumber(arg)
            local s = charmId and mq.TLO.Spawn(charmId) or mq.TLO.Target
            if not (s and s() and (s.ID() or 0) > 0) then
                Logger.log_error("/rgl forcecharm - no valid target or id.")
                return true
            end
            if not (Targeting.TargetIsType("npc", s) or Targeting.TargetIsType("npcpet", s)) then
                Logger.log_error("/rgl forcecharm - target must be an npc.")
                return true
            end
            if (mq.TLO.Me.Pet.ID() or 0) > 0 then
                Logger.log_error("/rgl forcecharm - you already have a pet; drop it first (e.g. invis) to switch charms.")
                return true
            end
            self:SetForceCharmId(s.ID())
            Logger.log_info("\awForce Charm: %s", s.CleanName() or "None")
            return true
        end,
    },
    forcecharmclear = {
        usage = "/rgl forcecharmclear",
        about = "Clears the current force-charm directive.",
        handler = function(self, arg)
            self:SetForceCharmId(0)
            Logger.log_info("\awForce charm cleared.")
            return true
        end,
    },
    charmdeny = {
        usage = "/rgl charmdeny \"<name>\"",
        about = "Adds <name> (or your target) to the Charm Deny List.",
        handler = function(self, name)
            if not name then
                if not (mq.TLO.Target() and Targeting.TargetIsType("NPC")) then
                    Logger.log_error("/rgl charmdeny - no name and no valid npc target.")
                    return true
                end
                name = mq.TLO.Target.CleanName()
            end
            self:AddMobToList("CharmDenyList", name)
            return true
        end,
    },
    charmallow = {
        usage = "/rgl charmallow \"<name>\"",
        about = "Adds <name> (or your target) to the Charm Allow List.",
        handler = function(self, name)
            if not name then
                if not (mq.TLO.Target() and Targeting.TargetIsType("NPC")) then
                    Logger.log_error("/rgl charmallow - no name and no valid npc target.")
                    return true
                end
                name = mq.TLO.Target.CleanName()
            end
            self:AddMobToList("CharmAllowList", name)
            return true
        end,
    },
    charmdenyrm = {
        usage = "/rgl charmdenyrm \"<name>\" or <List#>",
        about = "Removes <name> or <List#> (or your target) from the Charm Deny List.",
        handler = function(self, arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl charmdenyrm - no argument and no valid target.")
                return true
            end
            self:DeleteMobFromList("CharmDenyList", arg1)
            return true
        end,
    },
    charmallowrm = {
        usage = "/rgl charmallowrm \"<name>\" or <List#>",
        about = "Removes <name> or <List#> (or your target) from the Charm Allow List.",
        handler = function(self, arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl charmallowrm - no argument and no valid target.")
                return true
            end
            self:DeleteMobFromList("CharmAllowList", arg1)
            return true
        end,
    },
    charmclear = {
        usage = "/rgl charmclear",
        about = "Clears the current-zone Charm Allow and Deny list entries.",
        handler = function(self, arg)
            local zone = (mq.TLO.Zone.ShortName() or ""):lower()
            for _, list in ipairs({ "CharmAllowList", "CharmDenyList", }) do
                local active = Config:GetSetting(self:ActiveCharmList(list)) or {}
                active[zone] = nil
                Config:SetSetting(self:ActiveCharmList(list), active)
            end
            Logger.log_info("\awCleared charm lists for this zone.")
            return true
        end,
    },
    enablecharmentry = {
        usage = "/rgl enablecharmentry \"<Name>\"",
        about = "Enables a charm entry (charm spell, pre-charm step, or assist) by name, in every list it appears in.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledCharmEntries') or {}
            for _, listName in ipairs({ "Abilities", "PreCharm", "Assist", }) do
                enabled[listName] = enabled[listName] or {}
                enabled[listName][name] = true
            end
            Config:SetSetting('EnabledCharmEntries', enabled)
            return true
        end,
    },
    disablecharmentry = {
        usage = "/rgl disablecharmentry \"<Name>\"",
        about = "Disables a charm entry (charm spell, pre-charm step, or assist) by name, in every list it appears in.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledCharmEntries') or {}
            for _, listName in ipairs({ "Abilities", "PreCharm", "Assist", }) do
                enabled[listName] = enabled[listName] or {}
                enabled[listName][name] = false
            end
            Config:SetSetting('EnabledCharmEntries', enabled)
            return true
        end,
    },
}

-- List Helpers (mirror pull)

---@param base string
---@return string the active list setting name (shared or character)
function Module:ActiveCharmList(base)
    return Config:GetSetting('UseSharedCharmLists') and (base .. "Shared") or base
end

function Module:AddMobToList(list, name)
    Config:ZoneListAdd(name, self:ActiveCharmList(list))
end

function Module:DeleteMobFromList(list, arg1)
    Config:ZoneListDelete(arg1, self:ActiveCharmList(list))
end

---@param list string
---@return boolean true if the active list has entries for the current zone
function Module:HaveList(list)
    local zoneList = Config:GetSetting(self:ActiveCharmList(list))[(mq.TLO.Zone.ShortName() or ""):lower()]
    return zoneList ~= nil and #zoneList > 0
end

---@param list string
---@param name string
---@param defaultNoList boolean returned when no list exists for the zone
---@return boolean
function Module:IsMobInList(list, name, defaultNoList)
    if not self:HaveList(list) then return defaultNoList end
    for _, v in pairs(Config:GetSetting(self:ActiveCharmList(list))[(mq.TLO.Zone.ShortName() or ""):lower()]) do
        if v == name then return true end
    end
    return false
end

-- Immunity

function Module:GetCharmAttemptId()
    return self.TempSettings.CharmAttemptId or 0
end

-- flag a mob immune for this session (in-memory only); permanent skips are the user's job via the Deny List
function Module:AddImmuneTarget(mobId, mobData)
    if self.TempSettings.CharmImmune[mobId] ~= nil then return end
    self.TempSettings.CharmImmune[mobId] = mobData
    Logger.log_debug("\ayCharm: %s (%d) flagged immune this session (%s)", mobData.name or "Unknown", mobId, mobData.reason or "?")
    self:RemoveCCTarget(mobId)
end

---@param mobId number
---@return boolean true if the mob cannot be charmed (immune, too high, or Named)
function Module:IsCharmImmune(mobId)
    if self.TempSettings.CharmImmune[mobId] ~= nil then return true end

    local spawn = mq.TLO.Spawn(mobId)
    if Targeting.IsNamed(spawn) then
        self:AddImmuneTarget(mobId, { id = spawn.ID(), name = spawn.CleanName() or "Unknown", lvl = spawn.Level() or 0, body = spawn.Body() or "Unknown", reason = "Named", })
        return true
    end
    return false
end

-- drop tracked/immune entries whose spawn is dead or gone
function Module:PruneStale()
    for id, _ in pairs(self.TempSettings.CharmTracker) do
        local spawn = mq.TLO.Spawn(id)
        if not spawn() or spawn.Dead() then self.TempSettings.CharmTracker[id] = nil end
    end
    for id, _ in pairs(self.TempSettings.CharmImmune) do
        local spawn = mq.TLO.Spawn(id)
        if not spawn() or spawn.Dead() then self.TempSettings.CharmImmune[id] = nil end
    end
end

-- clear the temp immune list only (re-test immunity); the tracker survives so charm pets persist across downtime
function Module:ResetCharmImmune()
    self.TempSettings.CharmImmune = {}
end

-- full reset (zone only): charm genuinely breaks on zone, so drop the tracker too
function Module:ResetCharmStates()
    self:ResetCharmImmune()
    self.TempSettings.CharmTracker = {}
    Config:SetSetting('LastCharmPetID', 0)
end

-- Charm ability resolution (config-driven via ClassConfig.Charm.Abilities, falls back to hardcoded logic)

-- resolve an entry's identifier to its MQSpell (for TargetType / cast-time / range reads)
function Module:EntrySpell(entry)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then return Casting.GetAASpell(entry.name) end
    if entryType == "item" then return Casting.GetClickySpell(entry.name) end
    if entryType == "ability" then return entry.name end
    return Modules:ExecModule("Class", "GetResolvedActionMapItem", entry.name)
end

-- did the entry resolve to a usable action? abilities resolve by name (no spell object); all others need a live spell TLO
function Module:EntryResolves(entry, spell)
    if (entry.type or ""):lower() == "ability" then return spell ~= nil end
    return spell ~= nil and spell() ~= nil
end

-- only spell/song are gemmed abilities we ever WAIT on; AA runs off a reuse timer
function Module:EntryIsGemmed(entry)
    local entryType = (entry.type or ""):lower()
    return entryType == "spell" or entryType == "song"
end

function Module:EntryReady(entry, spell)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then return Casting.AAReady(entry.name) end
    if entryType == "item" then return Casting.ItemReady(entry.name) end
    if entryType == "ability" then return Casting.AbilityReady(entry.name) end
    if entryType == "song" then return Casting.SongReady(spell) end
    if entryType == "disc" then return Casting.DiscReady(spell) end
    return Casting.SpellReady(spell)
end

function Module:EntryCast(entry, spell, charmId)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then
        Casting.UseAA(entry.name, charmId, false)
    elseif entryType == "item" then
        Casting.UseItem(entry.name, charmId, false)
    elseif entryType == "ability" then
        Casting.UseAbility(entry.name)
    elseif entryType == "song" then
        Casting.UseSong(spell.RankName(), charmId, false, 5)
    elseif entryType == "disc" then
        Casting.UseDisc(spell, charmId)
    else
        Casting.UseSpell(spell.RankName(), charmId, false, false)
    end
end

-- per-list enable state (defaults on); scoping by listName lets a shared name toggle independently in each list
function Module:EntryEnabled(entry, listName)
    local lists = Config:GetSetting('EnabledCharmEntries') or {}
    return ((lists[listName] or {})[entry.name]) ~= false
end

-- the active charm ability list: the class config's load_cond-filtered ['Charm']['Abilities'], or the deprecated fallback
function Module:GetCharmAbilities()
    local classConfig = Modules:ExecModule("Class", "GetClassConfig")
    if classConfig and classConfig.Charm and classConfig.Charm.Abilities then return self:GetCharmLists().Abilities end
    return self:FallbackCharmAbilities()
end

-- ===== DEPRECATED FALLBACK (delete once every charm config ships a ['Charm'] table) =====
function Module:FallbackCharmAbilities()
    if Core.MyClassIs("BRD") then
        return { { type = "Song", name = "CharmSong", }, }
    end
    return {
        { type = "AA",    name = "Dire Charm", },
        { type = "Spell", name = "CharmSpell", },
    }
end

-- ===== END DEPRECATED FALLBACK =====

-- keep only entries whose load_cond passes (reuses the Class module's scan-time evaluator)
function Module:FilterLoaded(list)
    local out = {}
    for _, entry in ipairs(list or {}) do
        if Modules:ExecModule("Class", "LoadConditionPass", entry) then table.insert(out, entry) end
    end
    return out
end

-- rebuild the load_cond-filtered charm lists on rescan, so a load-gated entry drops out of both the cast logic and the UI
function Module:RebuildCharmLists()
    local classConfig = Modules:ExecModule("Class", "GetClassConfig")
    local charm = classConfig and classConfig.Charm
    self.TempSettings.CharmLists = {
        Abilities = self:FilterLoaded(charm and charm.Abilities),
        PreCharm  = self:FilterLoaded(charm and charm.PreCharm),
        Assist    = self:FilterLoaded(charm and charm.Assist),
    }
end

function Module:GetCharmLists()
    if not self.TempSettings.CharmLists then self:RebuildCharmLists() end
    return self.TempSettings.CharmLists
end

-- the Class module fires this on every rescan/mode change (ExecAll); rebuild our filtered lists in lockstep with rotations
function Module:OnCombatModeChanged()
    self:RebuildCharmLists()
end

-- the validity-filtered selectable charm abilities (Charm.Abilities you can actually use); throttled, mirrors pull's SetValidPullAbilities
function Module:SetValidCharmAbilities()
    if Globals.GetTimeMS() - self.TempSettings.LastCharmAbilityCheck < 10000 then return end
    self.TempSettings.LastCharmAbilityCheck = Globals.GetTimeMS()
    local valid = {}
    for _, entry in ipairs(self:GetCharmAbilities()) do
        local usable
        if (entry.type or ""):lower() == "aa" then
            usable = Casting.CanUseAA(entry.name)
        else
            usable = self:EntryResolves(entry, self:EntrySpell(entry))
        end
        if usable then table.insert(valid, entry) end
    end
    self.TempSettings.ValidCharmAbilities = valid
end

-- combo label for a valid-ability index: the resolved rank name for spells/songs, else the entry name (e.g. Dire Charm)
function Module:GetCharmAbilityDisplayName(id)
    local entry = self.TempSettings.ValidCharmAbilities[id]
    if not entry then return "Error" end
    local entryType = (entry.type or ""):lower()
    if entryType == "spell" or entryType == "song" or entryType == "disc" then
        local spell = self:EntrySpell(entry)
        return (spell and spell() and spell.RankName()) or entry.name
    end
    return entry.name
end

-- the single charm ability the user picked in the panel (falls back to the first valid if the selection is stale)
function Module:GetSelectedCharmAbility()
    self:SetValidCharmAbilities()
    local valid = self.TempSettings.ValidCharmAbilities
    return valid[Config:GetSetting('CharmAbility')] or valid[1]
end

-- true if spell is the selected charm ability's spell (lets a SpellList cond gate the mem off the resolved spell it already gets)
function Module:IsSelectedCharmSpell(spell)
    local entry = self:GetSelectedCharmAbility()
    if not entry then return false end
    local selSpell = self:EntrySpell(entry)
    if type(selSpell) == "string" or not (selSpell and selSpell()) then return false end
    return spell ~= nil and spell() ~= nil and selSpell.ID() == spell.ID()
end

-- the selected charm ability's spell (drives the scan's level range)
function Module:ResolveCharmSpell()
    local entry = self:GetSelectedCharmAbility()
    if not entry then return nil end
    local spell = self:EntrySpell(entry)
    if self:EntryResolves(entry, spell) then return spell end
    return nil
end

-- is the selected charm ability ready now (or gemmed and just momentarily busy)?
function Module:CharmReady()
    local entry = self:GetSelectedCharmAbility()
    if not entry then return false end
    local spell = self:EntrySpell(entry)
    if not self:EntryResolves(entry, spell) then return false end
    ---@cast spell MQSpell
    if self:EntryReady(entry, spell) then return true end
    if self:EntryIsGemmed(entry) and (mq.TLO.Me.GemTimer(spell.RankName() or "")() or -1) == 0 then return true end
    return false
end

function Module:AnnounceCharm(charmId, entry, spell)
    local target = mq.TLO.Spawn(charmId).CleanName() or "Unknown"
    local ability = (entry.type or ""):lower() == "aa" and ("AA: " .. entry.name) or spell.RankName()
    Comms.HandleAnnounce(Comms.FormatChatEvent("Charm", target, ability), Config:GetSetting('CharmAnnounceGroup'),
        Config:GetSetting('CharmAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
end

-- cast the selected charm ability on the target. Returns true only when it's gemmed, off cooldown, but momentarily busy (caller holds the tick).
function Module:CharmAttempt(charmId)
    -- the target can die during the blocking pre-charm sequence / gem wait; never announce or cast charm on a corpse
    local spawn = mq.TLO.Spawn(charmId)
    if not spawn() or spawn.Dead() or Targeting.TargetIsType("corpse", spawn) then return false end
    local entry = self:GetSelectedCharmAbility()
    if not entry then return false end
    local spell = self:EntrySpell(entry)
    if not self:EntryResolves(entry, spell) then return false end
    ---@cast spell MQSpell
    -- the selected ability can't charm above its own MaxLevel (e.g. Dire Charm = 78)
    ---@diagnostic disable-next-line: undefined-field
    local cap = (type(spell) ~= "string" and (spell.MaxLevel() or 0)) or 0
    if cap > 0 and (spawn.Level() or 0) > cap then return false end
    if self:EntryReady(entry, spell) then
        if (spell.MyCastTime() or 0) > 0 then self:StopCast() end
        self:AnnounceCharm(charmId, entry, spell)
        self.TempSettings.CharmAttemptId = charmId
        self.TempSettings.LastCharmBuff = ((entry.type or ""):lower() == "aa") and entry.name or spell.RankName()
        Logger.log_debug("Charm: %s on %d", entry.name, charmId)
        self:EntryCast(entry, spell, charmId)
        mq.doevents('ImmuneCharm')
        mq.doevents('ImmuneCharm2')
        mq.doevents('LvlHighCharm')
        return false
    elseif self:EntryIsGemmed(entry) and (mq.TLO.Me.GemTimer(spell.RankName() or "")() or -1) == 0 then
        return true
    end
    return false
end

function Module:ShouldAbortCharmWait()
    if not Core.IsCharming() or Globals.BackOffFlag then return true end
    if (mq.TLO.Me.Pet.ID() or 0) > 0 then return true end
    return false
end

-- cast every cond-passing pre-charm entry as one sequence, holding for a gemmed entry merely clipped by the prior cast's global
function Module:RunPreCharm(charmId)
    local target = mq.TLO.Target
    for _, entry in ipairs(self:GetPreCharmAbilities()) do
        if self:ShouldAbortCharmWait() then
            Logger.log_debug("\ayRunPreCharm :: aborting - charming=%s pet=%d backoff=%s", tostring(Core.IsCharming()), mq.TLO.Me.Pet.ID() or 0, tostring(Globals.BackOffFlag))
            return
        end
        local spell = self:EntrySpell(entry)
        local enabled = self:EntryEnabled(entry, "PreCharm")
        local resolves = self:EntryResolves(entry, spell)
        local condPass = resolves and Core.SafeCallFunc("Charm PreCharm cond", entry.cond, self, spell, target)
        Logger.log_super_verbose("\ayRunPreCharm :: %s en=%s res=%s cond=%s", entry.name or "?", tostring(enabled), tostring(resolves), tostring(condPass))
        if enabled and condPass then
            ---@cast spell MQSpell
            if not self:EntryReady(entry, spell) and self:EntryIsGemmed(entry) and (mq.TLO.Me.GemTimer(spell.RankName() or "")() or -1) == 0 then
                Logger.log_debug("\ayRunPreCharm :: %s waiting for gem", entry.name or "?")
                Casting.WaitForReady(function() return self:EntryReady(entry, spell) end, 1500, function() return self:ShouldAbortCharmWait() end)
            end
            if self:EntryReady(entry, spell) then
                if (entry.type or ""):lower() ~= "ability" and (spell.MyCastTime() or 0) > 0 then self:StopCast() end
                Logger.log_verbose("Charm pre-step: casting %s", entry.name or "?")
                self:EntryCast(entry, spell, charmId)
            end
        end
    end
end

function Module:GetPreCharmAbilities()
    return self:GetCharmLists().PreCharm
end

-- Charm the target: pre-steps (resist-debuff, mez-lock) then charm, all blocking; restore target on every path.
function Module:CastCharm(charmId)
    Core.DoCmd("/attack off")
    local restoreTargetID = mq.TLO.Target.ID()
    Targeting.SetTarget(charmId, true)

    -- never cast on a mob that became a pet (ours or a peer's) since we picked it
    local spawn = mq.TLO.Spawn(charmId)
    if (spawn.Master.Type() or "") == "PC" or (Globals.CharmedPetIDs:contains(charmId) and not self:IsOwnKeptCharm(charmId)) then
        Targeting.SetTarget(restoreTargetID, true)
        return
    end

    -- pre-charm sequence: run the class's PreCharm list (resist debuffs, mez lock, ...), each cond-gated
    self:RunPreCharm(charmId)

    if self:CharmAttempt(charmId) then
        local maxWait = 1500 + (mq.TLO.Window("CastingWindow").Open() and (mq.TLO.Me.Casting.MyCastTime() or 3000) or 0)
        Casting.WaitForReady(function() return not self:CharmAttempt(charmId) end, maxWait, function() return self:ShouldAbortCharmWait() end)
    end

    Targeting.SetTarget(restoreTargetID, true)
end

-- Tracker

function Module:RemoveCCTarget(mobId)
    if mobId == 0 then return end
    self.TempSettings.CharmTracker[mobId] = nil
    Config:SetSetting('LastCharmPetID', next(self.TempSettings.CharmTracker) or 0)
end

-- re-seed the tracker on a script restart: if we still hold the pet we last charmed (same spawn id), record it again; otherwise the saved id is stale
function Module:RestoreCharmOnLoad()
    local savedId = Config:GetSetting('LastCharmPetID') or 0
    Logger.log_debug("\ayRestoreCharmOnLoad :: saved=%d pet=%d", savedId, mq.TLO.Me.Pet.ID() or 0)
    if savedId > 0 and (mq.TLO.Me.Pet.ID() or 0) == savedId then
        self:AddCCTarget(savedId)
    elseif savedId ~= 0 then
        Config:SetSetting('LastCharmPetID', 0)
    end
end

-- record a successfully-charmed mob so the tracker, expiry warning, and peer broadcast know it's ours
function Module:AddCCTarget(mobId)
    if mobId == 0 then return end
    local spawn = mq.TLO.Spawn(mobId)
    self.TempSettings.CharmTracker[mobId] = {
        name  = spawn.CleanName(),
        level = spawn.Level() or 0,
        body  = spawn.Body() or "Unknown",
        loose = false,
    }
    self.TempSettings.CharmZoneId = mq.TLO.Zone.ID() or 0
    Config:SetSetting('LastCharmPetID', mobId)
end

-- live charm-buff timer on our pet (a BuffDuration timestamp); nil if no pet, no charm, or the buff has no duration (e.g. Dire Charm)
function Module:GetCharmDuration()
    if (mq.TLO.Me.Pet.ID() or 0) == 0 then return nil end
    local buffName = self.TempSettings.LastCharmBuff
    if not buffName then
        local entry = self:GetSelectedCharmAbility()
        local spell = entry and self:EntrySpell(entry)
        buffName = (spell and type(spell) ~= "string" and spell()) and spell.RankName() or nil
    end
    if not buffName then return nil end
    local dur = mq.TLO.Me.Pet.BuffDuration(buffName)
    ---@diagnostic disable-next-line: undefined-field
    return (dur.TotalSeconds() or 0) > 0 and dur or nil
end

-- warn at 30s then 10s out (each once) as our held charm nears expiry so the group can get ready
function Module:UpdateTimings()
    local petId = mq.TLO.Me.Pet.ID() or 0
    local data = petId > 0 and self.TempSettings.CharmTracker[petId]
    if not data or data.loose then return end
    local dur = self:GetCharmDuration()
    if not dur then return end
    local secs = dur.TotalSeconds() or 0
    for _, threshold in ipairs({ 30, 10, }) do
        if secs <= threshold and (data.warned or 999) > threshold then
            data.warned = threshold
            Comms.HandleAnnounce(Comms.FormatChatEvent(string.format("Charm Expiring in %ds", threshold), data.name or "?", mq.TLO.Me.DisplayName()),
                Config:GetSetting('CharmAnnounceGroup'), Config:GetSetting('CharmAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
            break
        end
    end
end

-- Kept set / peer broadcast

---@param id number
---@return boolean true if id is one we intend to keep (persist pet or forcecharm)
function Module:IsOwnKeptCharm(id)
    if id == 0 then return false end
    if Globals.ForceCharmID == id then return true end
    if Config:GetSetting('PersistCharm') and (mq.TLO.Me.Pet.ID() or 0) == id then return true end
    if Config:GetSetting('PersistCharm') and self.TempSettings.CharmTracker[id] ~= nil then return true end
    return false
end

-- the single mob id we want peers to leave alone: forcecharm target, else our charmed pet (or the broken one we're re-grabbing)
function Module:GetKeptCharmID()
    if Globals.ForceCharmID > 0 then return Globals.ForceCharmID end
    if not Core.IsCharming() then return 0 end
    -- always protect the charm we currently hold, from the moment we charm it - so peers never engage it, including the instant it breaks
    local petId = mq.TLO.Me.Pet.ID() or 0
    if petId > 0 and self.TempSettings.CharmTracker[petId] then return petId end
    -- pet slot empty but a charm is still tracked (just broke / mid re-grab): keep protecting it before DetectBreaks sets loose, or a peer's MA grabs it
    if Config:GetSetting('PersistCharm') then
        return next(self.TempSettings.CharmTracker) or 0
    end
    return 0
end

-- our broken-but-tracked charm we're trying to re-grab (0 if none)
function Module:GetLooseCharmID()
    for id, data in pairs(self.TempSettings.CharmTracker) do
        if data.loose then return id end
    end
    return 0
end

-- rebuild the peer-aggregated globals each tick (group/raid + same zone/instance/server only)
function Module:RebuildPeerCharmData()
    local myKept = self:GetKeptCharmID()
    local kept = Set.new(myKept > 0 and { myKept, } or {})
    local loose = {}
    -- our own loose charm is handled by us (recharm), not broadcast back to ourselves for assist
    local myName = Globals.CurLoadedChar
    local myServer = mq.TLO.EverQuest.Server() or ""
    local myZone = mq.TLO.Zone.ID() or 0
    local myInst = mq.TLO.Me.Instance() or 0

    for _, hb in pairs(Comms.PeersHeartbeats or {}) do
        local d = hb.Data
        if d and d.Server == myServer and d.ZoneId == myZone and d.InstanceId == myInst
            and (mq.TLO.Group.Member(d.Name)() ~= nil or mq.TLO.Raid.Member(d.Name)() ~= nil) then
            if (d.CharmedPetID or 0) > 0 then kept:add(d.CharmedPetID) end
            if d.Name ~= myName and (d.LooseCharmID or 0) > 0 then loose[d.LooseCharmID] = d.Name end
        end
    end

    Globals.CharmedPetIDs = kept
    Globals.LooseCharms = loose
    Globals.MyCharmedPetID = myKept
    Globals.MyLooseCharmID = self:GetLooseCharmID()
end

-- Targeting / validation

---@param mobId number
---@return boolean true if this mob is a valid charm candidate
function Module:IsValidCharmTarget(mobId)
    local spawn = mq.TLO.Spawn(mobId)
    local name = spawn.CleanName() or "Unknown"

    if not spawn() or spawn.Dead() or Targeting.TargetIsType("corpse", spawn) then return false end   -- dead/corpse
    if (spawn.Master.Type() or "") == "PC" then return false end                                      -- already a pet
    if Globals.CharmedPetIDs:contains(mobId) and not self:IsOwnKeptCharm(mobId) then return false end -- a peer's charm
    if self:IsCharmImmune(mobId) then return false end
    if self:IsMobInList("CharmDenyList", name, false) then return false end
    if self:HaveList("CharmAllowList") and not self:IsMobInList("CharmAllowList", name, false) then return false end
    -- class body gating
    if Core.MyClassIs('DRU') and spawn.Body.Name() ~= "Animal" then return false end
    if Core.MyClassIs('NEC') and spawn.Body.Name() ~= "Undead" then return false end
    if not spawn.LineOfSight() then return false end
    if (spawn.Distance() or 999) > Config:GetSetting('CharmRadius') then return false end
    return true
end

-- scan nearby npcs for the best charm candidate; returns an id or 0
function Module:FindCharmCandidate()
    local charmSpell = self:ResolveCharmSpell()
    local minLevel = Config:GetSetting('CharmMinLevel')
    local maxLevel = Config:GetSetting('CharmMaxLevel')
    if Config:GetSetting('AutoLevelRangeCharm') and charmSpell and charmSpell() then
        minLevel = 0
        ---@diagnostic disable-next-line: undefined-field
        maxLevel = charmSpell.MaxLevel() or maxLevel
    end

    local npcType = ''
    if Core.MyClassIs("DRU") then
        npcType = ' body Animal'
    elseif Core.MyClassIs("NEC") then
        npcType = ' body Undead'
    end
    local searchString = string.format("npc radius %d zradius %d range %d %d targetable playerstate 4%s",
        Config:GetSetting('CharmRadius'), Config:GetSetting('CharmZRadius'), minLevel, maxLevel, npcType)

    -- prefer any valid candidate over the group's kill target; only charm the auto-target if it's the lone option
    local autoId = Globals.AutoTargetID or 0
    local firstValid = 0
    local count = mq.TLO.SpawnCount(searchString)()
    for i = 1, count do
        local spawn = mq.TLO.NearestSpawn(i, searchString)
        local id = (spawn and spawn() and spawn.ID()) or 0
        if id > 0 and self:IsValidCharmTarget(id) then
            if firstValid == 0 then firstValid = id end
            if id ~= autoId then return id end
        end
    end
    return firstValid
end

-- True while a charm is being ACQUIRED (a valid target exists and we don't yet hold our intended pet),
-- so DPS rotations yield. False once a charm is stably held.
function Module:NeedToCharm()
    -- throttled to 250ms; the no-pet branch runs a spawn scan we don't want re-running every rotation cond
    if Globals.GetTimeMS() - self.TempSettings.LastNeedToCharmTime < 250 then
        return self.TempSettings.LastNeedToCharmResult
    end
    self.TempSettings.LastNeedToCharmTime = Globals.GetTimeMS()

    -- CharmReady gates on a usable ability; HavePet means nothing to acquire (a loose charm can't be re-charmed while the pet slot
    -- is full), so we only suppress DPS while actually acquiring - the break is handled the moment the pet slot frees up
    local charmOn = Config:GetSetting('CharmOn')
    local ready = charmOn and self:CharmReady()
    local havePet = (mq.TLO.Me.Pet.ID() or 0) > 0
    local result = ready and not havePet and self:CurrentCharmTarget() > 0

    Logger.log_verbose("NeedToCharm - CharmOn(%s) CharmReady(%s) HavePet(%s) => %s",
        Strings.BoolToColorString(charmOn), Strings.BoolToColorString(ready), Strings.BoolToColorString(havePet), Strings.BoolToColorString(result))

    self.TempSettings.LastNeedToCharmResult = result
    return result
end

-- True (opt-in) when we should pause our rotation to lock a groupmate's loose charm; shared by the gate and reaction.
function Module:CharmAssistNeeded()
    -- throttled to 250ms; FindLooseCharmToAssist scans peers + abilities, don't re-run it every rotation cond
    if Globals.GetTimeMS() - self.TempSettings.LastCharmAssistTime < 250 then
        return self.TempSettings.LastCharmAssistResult
    end
    self.TempSettings.LastCharmAssistTime = Globals.GetTimeMS()

    local assistOn = Config:GetSetting('DoCharmAssist')
    local healClear = Core.OkayToNotHeal(Config:GetSetting('PriorityHealing'))
    local mezClear = Core.OkayToNotMez(Config:GetSetting('PriorityMez'))
    local hpOk = (mq.TLO.Me.PctHPs() or 100) > (Config:GetSetting('HPCritical', true) or Config:GetSetting('EmergencyStart', true) or 0)
    -- only scan for a loose charm once the cheaper gates pass
    local result = assistOn and healClear and mezClear and hpOk and self:FindLooseCharmToAssist() > 0

    Logger.log_verbose("CharmAssistNeeded - DoCharmAssist(%s) HealClear(%s) MezClear(%s) HpOk(%s) => %s",
        Strings.BoolToColorString(assistOn), Strings.BoolToColorString(healClear), Strings.BoolToColorString(mezClear),
        Strings.BoolToColorString(hpOk), Strings.BoolToColorString(result))

    self.TempSettings.LastCharmAssistResult = result
    return result
end

function Module:GetAssistAbilities()
    return self:GetCharmLists().Assist
end

-- first loose charm (from a groupmate) we can act on with a ready Charm.Assist ability; returns id or 0
function Module:FindLooseCharmToAssist()
    local abilities = self:GetAssistAbilities()
    if #abilities == 0 then return 0 end
    if next(Globals.LooseCharms) == nil then return 0 end -- nothing loose to assist; skip the readiness scan
    -- only an enabled+ready check here (no cond - we have no target yet); the per-entry cond is evaluated at cast time
    local haveReady = false
    for _, entry in ipairs(abilities) do
        if self:EntryEnabled(entry, "Assist") then
            local spell = self:EntrySpell(entry)
            if self:EntryResolves(entry, spell) and self:EntryReady(entry, spell) then
                haveReady = true
                break
            end
        end
    end
    if not haveReady then
        if next(Globals.LooseCharms) ~= nil then Logger.log_super_verbose("\ayFindLooseCharmToAssist :: loose charm present but no assist ability ready") end
        return 0
    end

    for id, src in pairs(Globals.LooseCharms) do
        if not self:IsOwnKeptCharm(id) and id ~= (mq.TLO.Me.Pet.ID() or 0) then
            local spawn = mq.TLO.Spawn(id)
            local alive = spawn() and not spawn.Dead()
            local los = spawn() and spawn.LineOfSight()
            local dist = spawn.Distance() or 999
            Logger.log_super_verbose("\ayFindLooseCharmToAssist :: loose %d (%s) from %s alive=%s los=%s dist=%d/%d", id, spawn.CleanName() or "?", tostring(src),
                tostring(alive), tostring(los), dist, Config:GetSetting('CharmRadius'))
            if alive and los and dist <= Config:GetSetting('CharmRadius') then
                return id
            end
        end
    end
    return 0
end

-- stun/lock a groupmate's loose charm once; stop on first success
function Module:PerformCharmAssist(id)
    id = id or self:FindLooseCharmToAssist()
    if id == 0 then return end
    local restoreTargetID = mq.TLO.Target.ID()
    Targeting.SetTarget(id, true)
    local target = mq.TLO.Target
    for _, entry in ipairs(self:GetAssistAbilities()) do
        local spell = self:EntrySpell(entry)
        local enabled = self:EntryEnabled(entry, "Assist")
        local resolves = self:EntryResolves(entry, spell)
        local ready = resolves and self:EntryReady(entry, spell)
        local condOk = ready and Core.SafeCallFunc("Charm Assist cond", entry.cond, self, spell, target)
        Logger.log_super_verbose("\ayPerformCharmAssist :: %s en=%s res=%s ready=%s cond=%s", entry.name or "?",
            tostring(enabled), tostring(resolves), tostring(ready), tostring(condOk))
        if enabled and resolves and ready and condOk then
            Logger.log_verbose("Charm assist: casting %s on %d (%s)", entry.name or "?", id, mq.TLO.Spawn(id).CleanName() or "?")
            self:EntryCast(entry, spell, id)
            break
        end
    end
    Targeting.SetTarget(restoreTargetID, true)
end

-- Charm orchestration

-- the mob we should be charming right now: forcecharm > persisted-loose > scan candidate
function Module:CurrentCharmTarget()
    if Globals.ForceCharmID > 0 then
        local s = mq.TLO.Spawn(Globals.ForceCharmID)
        if not (s() and not s.Dead()) then
            self:SetForceCharmId(0)
        elseif self:IsCharmImmune(Globals.ForceCharmID) then
            Comms.HandleAnnounce(Comms.FormatChatEvent("Charm Failed", s.CleanName() or "?", "immune"),
                Config:GetSetting('CharmAnnounceGroup'), Config:GetSetting('CharmAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
            self:SetForceCharmId(0)
        else
            return Globals.ForceCharmID
        end
    end
    if Config:GetSetting('PersistCharm') then
        for id, data in pairs(self.TempSettings.CharmTracker) do
            if data.loose and not self:IsCharmImmune(id) then return id end
        end
    end
    if Config:GetSetting('CharmOn') then return self:FindCharmCandidate() end
    return 0
end

-- poll the broken pet: announce + mark loose (broadcast) or clear if it died
function Module:DetectBreaks()
    local petId = mq.TLO.Me.Pet.ID() or 0
    for id, data in pairs(self.TempSettings.CharmTracker) do
        if id ~= petId and not data.loose then
            local spawn = mq.TLO.Spawn(id)
            if spawn() and not spawn.Dead() and (spawn.Master.Type() or "") ~= "PC" then
                data.loose = true
                Logger.log_debug("\ayDetectBreaks :: charm broke on \at%s\ay (%d) - marking loose", spawn.CleanName() or "?", id)
                Comms.HandleAnnounce(Comms.FormatChatEvent("Charm Broken", spawn.CleanName() or "?", mq.TLO.Me.DisplayName()),
                    Config:GetSetting('CharmAnnounceGroup'), Config:GetSetting('CharmAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
            else
                Logger.log_debug("\ayDetectBreaks :: tracked charm %d gone or dead - dropping", id)
                self:RemoveCCTarget(id)
            end
        end
    end
end

function Module:DoCharm()
    self:PruneStale()
    self:UpdateTimings()
    self:DetectBreaks()

    -- a charm can't be broken on demand (only going invis drops it), so a forcecharm directive is moot while we hold a pet - clear it and bail
    if (mq.TLO.Me.Pet.ID() or 0) > 0 then
        if Globals.ForceCharmID > 0 then self:SetForceCharmId(0) end
        return
    end

    if not self:CharmReady() then return end

    local target = self:CurrentCharmTarget()
    if target == 0 then return end

    -- hold until reachable: forcecharm waits to be walked into range instead of spamming failed casts + target swaps each tick (scan picks are already filtered)
    local spawn = mq.TLO.Spawn(target)
    if not spawn.LineOfSight() or (spawn.Distance() or 999) > Config:GetSetting('CharmRadius') then return end

    self:StopAttack()
    self:CastCharm(target)

    -- the charmed mob takes a moment to register as our pet after the spell lands; wait before recording (else tracking/protection/persist all miss it)
    mq.delay(1000, function() return (mq.TLO.Me.Pet.ID() or 0) == target end)

    Logger.log_debug("\ayDoCharm :: cast on %d - pet now %d", target, mq.TLO.Me.Pet.ID() or 0)
    if (mq.TLO.Me.Pet.ID() or 0) == target then
        self:AddCCTarget(target)
        if Globals.ForceCharmID == target then self:SetForceCharmId(0) end
    end
end

function Module:StopAttack()
    if mq.TLO.Me.Combat() then
        Core.DoCmd("/attack off")
        mq.delay(500, function() return mq.TLO.Me.Combat() == false end)
    end
end

function Module:StopCast()
    if mq.TLO.Me.Casting() then
        mq.TLO.Me.StopCast()
        mq.delay("3s", function() return mq.TLO.Window("CastingWindow").Open() == false end)
    end
end

function Module:GiveTime()
    local combatState = Combat.GetCachedCombatState()

    -- one-time on load: re-identify a charm we still hold across a script restart (the tracker is in-memory, so it's empty here)
    if Core.CanCharm() and not self.TempSettings.CharmRestored then
        self.TempSettings.CharmRestored = true
        self:RestoreCharmOnLoad()
    end

    if Core.CanCharm() then self:SetValidCharmAbilities() end

    -- charm doesn't survive a zone (and zone-local ids get reused), so drop a tracker left from the prior zone before anything reads it
    local zoneId = mq.TLO.Zone.ID() or 0
    if zoneId > 0 and next(self.TempSettings.CharmTracker) ~= nil and self.TempSettings.CharmZoneId ~= zoneId then
        self:ResetCharmStates()
    end

    -- runs for ALL classes: keep the peer charm data fresh and offer assists, before the IsCharming gate
    self:RebuildPeerCharmData()
    if self:CharmAssistNeeded() then self:PerformCharmAssist() end

    -- charm management runs only for a charmer with charm on - charm off means charm off, forcecharm included
    if not Core.IsCharming() then return end

    if mq.TLO.Navigation.Active() or mq.TLO.MoveTo.Moving() then return end
    if mq.TLO.Me.Hovering() then return end

    -- on entering downtime, re-test immunity (level/spell may have changed); KEEP the tracker - charm pets persist across downtime
    if self.CombatState ~= combatState and combatState == "Downtime" then
        self:ResetCharmImmune()
    end
    self.CombatState = combatState

    self:DoCharm()
end

-- set or clear the force-charm directive; charm polls Globals.ForceCharmID in DoCharm, so no event/broadcast is needed
function Module:SetForceCharmId(charmId)
    charmId = charmId or 0
    if charmId == Globals.ForceCharmID then return end
    if charmId > 0 then
        Logger.log_debug("\ayCharm: force charm set to %d", charmId)
    else
        Logger.log_debug("\ayCharm: force charm cleared from %d", Globals.ForceCharmID)
    end
    Globals.ForceCharmID = charmId
end

function Module:OnZone()
    self:ResetCharmStates()
end

function Module:ShouldRender()
    if Modules:ExecModule("Class", "CanCharm") then return true end
    -- assisters (a class with loaded Charm.Assist abilities) need the panel too, even though they can't charm
    local assist = self:GetCharmLists().Assist
    return assist ~= nil and #assist > 0
end

-- allow/deny zone-list editor (mirrors pull's RenderMobList): add the current target, list current-zone entries with a remove button
function Module:RenderMobList(displayName, settingName)
    if ImGui.CollapsingHeader(string.format("Charm %s", displayName)) then
        local invalidTarget = not (mq.TLO.Target() and Targeting.TargetIsType("NPC"))
        ImGui.BeginDisabled(invalidTarget)
        ImGui.PushID("##_small_btn_charm_" .. settingName)
        if ImGui.SmallButton(invalidTarget and "Select an NPC to Add" or string.format("Add Target To %s", displayName)) then
            self:AddMobToList(settingName, mq.TLO.Target.CleanName())
        end
        ImGui.PopID()
        ImGui.EndDisabled()

        if ImGui.BeginTable(settingName, 4, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableSetupColumn('Id', ImGuiTableColumnFlags.WidthFixed, 40.0)
            ImGui.TableSetupColumn('Count', ImGuiTableColumnFlags.WidthFixed, 40.0)
            ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 150.0)
            ImGui.TableSetupColumn('Controls', ImGuiTableColumnFlags.WidthFixed, 80.0)
            ImGui.TableHeadersRow()

            for idx, mobName in ipairs(Config:GetSetting(self:ActiveCharmList(settingName))[(mq.TLO.Zone.ShortName() or ""):lower()] or {}) do
                ImGui.TableNextColumn(); ImGui.Text(tostring(idx))
                ImGui.TableNextColumn(); ImGui.Text(tostring(mq.TLO.SpawnCount(string.format("NPC %s", mobName))))
                ImGui.TableNextColumn(); ImGui.Text(mobName)
                ImGui.TableNextColumn()
                ImGui.PushID("##_small_btn_delete_charm_" .. settingName .. tostring(idx))
                if ImGui.SmallButton(Icons.FA_TRASH) then
                    self:DeleteMobFromList(settingName, idx)
                end
                ImGui.PopID()
            end

            ImGui.EndTable()
        end
    end
end

-- charmer-only: mobs charm flagged uncharmable this session; add any to the Deny List to skip it for good
function Module:RenderInvalidCharmTargets()
    if ImGui.CollapsingHeader("Invalid Charm Targets") then
        ImGui.Indent()
        if ImGui.BeginTable("Immune", 6, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable, ImGuiTableFlags.Hideable)) then
            ImGui.TableSetupColumn('Id', ImGuiTableColumnFlags.WidthFixed, 70.0)
            ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 200.0)
            ImGui.TableSetupColumn('Lvl', ImGuiTableColumnFlags.WidthFixed, 50.0)
            ImGui.TableSetupColumn('Body', ImGuiTableColumnFlags.WidthFixed, 80.0)
            ImGui.TableSetupColumn('Reason', ImGuiTableColumnFlags.WidthFixed, 80.0)
            ImGui.TableSetupColumn('Controls', ImGuiTableColumnFlags.WidthFixed, 120.0)
            ImGui.TableHeadersRow()
            for id, data in pairs(self.TempSettings.CharmImmune) do
                ImGui.TableNextColumn(); ImGui.Text(tostring(id))
                ImGui.TableNextColumn(); ImGui.Text(data.name or "")
                ImGui.TableNextColumn(); ImGui.Text(tostring(data.lvl or 0))
                ImGui.TableNextColumn(); ImGui.Text(data.body or "")
                ImGui.TableNextColumn(); ImGui.Text(data.reason or "")
                ImGui.TableNextColumn()
                ImGui.PushID("##_charm_deny_" .. tostring(id))
                if ImGui.SmallButton("Add to Deny List") and data.name then
                    self:AddMobToList("CharmDenyList", data.name)
                end
                ImGui.PopID()
            end
            ImGui.EndTable()
        end
        ImGui.Unindent()
    end
end

function Module:Render()
    Base.Render(self)
    ImGui.NewLine()
    if not self.ModuleLoaded then return end

    -- force-charm controls/status plus the allow/deny lists, tracker, and immune table are charmer-only; assisters skip them
    if Core.CanCharm() then
        if #self.TempSettings.ValidCharmAbilities > 0 then
            local curIdx = Config:GetSetting('CharmAbility')
            if not self.TempSettings.ValidCharmAbilities[curIdx] then curIdx = 1 end
            local sel, pressed = ImGui.Combo("Charm Ability", curIdx,
                function(id) return self:GetCharmAbilityDisplayName(id) end, #self.TempSettings.ValidCharmAbilities)
            if pressed then Config:SetSetting('CharmAbility', sel) end
        end

        local petId = mq.TLO.Me.Pet.ID() or 0
        local charmState = "None"
        if petId > 0 and self.TempSettings.CharmTracker[petId] then
            local dur = self:GetCharmDuration()
            if dur and (dur() or 0) < 0 then -- permanent charm (e.g. Dire Charm) reports a negative/sentinel duration
                charmState = "Charmed (Permanent)"
            else
                charmState = dur and string.format("Charmed (%s)", dur.TimeHMS()) or "Charmed"
            end
        else
            for _, data in pairs(self.TempSettings.CharmTracker) do
                if data.loose then charmState = "Loose" end
            end
        end
        if ImGui.BeginTable("CharmStatus", 2, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableNextColumn(); Ui.RenderText("Pet")
            ImGui.TableNextColumn(); Ui.RenderText("%s", petId > 0 and (mq.TLO.Me.Pet.DisplayName() or "None") or "None")
            ImGui.TableNextColumn(); Ui.RenderText("Charm State")
            ImGui.TableNextColumn(); Ui.RenderText("%s", charmState)
            ImGui.TableNextColumn(); Ui.RenderText("Force Charm ID")
            ImGui.TableNextColumn(); Ui.RenderText("%s", Globals.ForceCharmID > 0 and string.format("%d (%s)", Globals.ForceCharmID, mq.TLO.Spawn(Globals.ForceCharmID).CleanName() or "?") or "None")
            ImGui.EndTable()
        end

        local tgt = mq.TLO.Target
        local validTarget = tgt() and (tgt.ID() or 0) > 0 and (Targeting.TargetIsType("npc", tgt) or Targeting.TargetIsType("npcpet", tgt))
        local buttonWidth = ImGui.GetWindowWidth() * 0.45
        local charmButtonText = petId > 0 and "Drop Pet to Charm" or (validTarget and "Charm This Target" or "Target an NPC to Charm")
        ImGui.BeginDisabled(not validTarget or petId > 0)
        if ImGui.Button(charmButtonText, buttonWidth, 28) and validTarget and petId == 0 then
            self:SetForceCharmId(tgt.ID())
        end
        ImGui.EndDisabled()
        ImGui.SameLine()
        ImGui.BeginDisabled(Globals.ForceCharmID == 0)
        if ImGui.Button("Clear Force Charm", buttonWidth, 28) then self:SetForceCharmId(0) end
        ImGui.EndDisabled()

        ImGui.Separator()
    end

    if ImGui.CollapsingHeader("Pre-Charm & Assist") then
        ImGui.Indent()
        local charmLists = self:GetCharmLists()
        if charmLists then
            local enabled = Config:GetSetting('EnabledCharmEntries') or {}
            local changed = false
            for _, listName in ipairs({ "PreCharm", "Assist", }) do
                local list = charmLists[listName]
                if list and #list > 0 then
                    ImGui.Text(listName)
                    local resolvedMap = {}
                    for _, entry in ipairs(list) do
                        resolvedMap[entry.name] = Modules:ExecModule("Class", "GetResolvedActionMapItem", entry.name)
                    end
                    enabled[listName] = enabled[listName] or {}
                    local _, newEnabled, entriesChanged = Ui.RenderRotationTable("Charm" .. listName, list, resolvedMap, 0, false, enabled[listName])
                    enabled[listName] = newEnabled
                    if entriesChanged then changed = true end
                end
            end
            if changed then Config:SetSetting('EnabledCharmEntries', enabled) end
        end
        ImGui.Unindent()
    end

    -- allow/deny list editors + personal/shared toggle (charmer-only; mirrors pull)
    if Core.CanCharm() then
        ImGui.NewLine()
        ImGui.Separator()
        local useShared = Config:GetSetting('UseSharedCharmLists')
        local newUseShared = ImGui.Checkbox("Use Shared Charm Lists", useShared)
        Ui.Tooltip("On: shares charm lists with all RGMercs peers on this machine.\nOff: this character uses its own lists.")
        if newUseShared ~= useShared then
            Config:SetSetting('UseSharedCharmLists', newUseShared)
        end
        self:RenderMobList("Allow List", "CharmAllowList")
        self:RenderMobList("Deny List", "CharmDenyList")
        self:RenderInvalidCharmTargets()
    end
end

return Module
