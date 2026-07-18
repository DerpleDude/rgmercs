-- Pull Module: target scanning, pull-ability selection, and the pull state machine.
local mq        = require('mq')
local Icons     = require('mq.ICONS')
local Set       = require("mq.Set")
local Base      = require("modules.base")
local Casting   = require("utils.casting")
local Combat    = require("utils.combat")
local Comms     = require("utils.comms")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Entries   = require("utils.entries")
local Events    = require("utils.events")
local Globals   = require('utils.globals')
local Logger    = require("utils.logger")
local Math      = require('utils.math')
local Modules   = require("utils.modules")
local Movement  = require("utils.movement")
local Strings   = require("utils.strings")
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")

local Module    = { _version = '2.0', _name = "Pull", _author = 'Derple, Algar', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                                = {}

-- Module State
Module.TempSettings                       = {}

-- Pulls & Timers
Module.TempSettings.LastPullOrCombatEnded = Globals.GetTimeSeconds()
Module.TempSettings.PausePulls            = false
Module.TempSettings.PullerMercPending     = nil
Module.TempSettings.LastPullAbilityCheck  = 0
Module.TempSettings.LastMoveAbilityCheck  = 0
Module.TempSettings.LastPullerMercCheck   = 0
Module.TempSettings.LastFoundGroupCorpse  = 0
Module.TempSettings.LastTooFarAnnounce    = 0

-- Targets & Scanning
Module.TempSettings.TargetSpawnID         = 0
Module.TempSettings.PullTargets           = {}
Module.TempSettings.PullIgnoreTargets     = {}
Module.TempSettings.PullListUpdated       = false
Module.TempSettings.PullAllowSet          = {}
Module.TempSettings.PullDenySet           = {}
Module.TempSettings.HavePullAllowEntries  = false
Module.TempSettings.HavePullDenyEntries   = false

-- Attempts & Travel
Module.TempSettings.Attempt               = nil
Module.TempSettings.Travel                = nil
Module.TempSettings.UnreachableSince      = 0
Module.TempSettings.TravelFailSince       = 0

-- Objectives
Module.TempSettings.FightTo               = nil
Module.TempSettings.HuntOrigin            = nil
Module.TempSettings.HuntAnchor            = nil

-- Circuit Waypoints
Module.TempSettings.CurrentWPName         = nil
Module.TempSettings.CurrentWPIndex        = 1
Module.TempSettings.ReachedWP             = false

-- Camp Travel & Escort
Module.TempSettings.CampTravelLoc         = nil
Module.TempSettings.EscortScopeWord       = nil
Module.TempSettings.EscortPeers           = nil
Module.TempSettings.CampArrivalWaitStart  = nil

-- Death Resume
Module.TempSettings.DeathResumeFreePass   = nil
Module.TempSettings.DeathSpot             = nil

-- Pull & Move Abilities
Module.TempSettings.ValidPullAbilities    = {}
Module.TempSettings.PullAbilityIDToName   = {}
Module.TempSettings.PullMoveAbilities     = nil

-- Location Entry & Edits
Module.TempSettings.LocEntryY             = ""
Module.TempSettings.LocEntryX             = ""
Module.TempSettings.LocEntryZ             = ""
Module.TempSettings.LocEntryMode          = nil
Module.TempSettings.LocationsToDelete     = {}
Module.TempSettings.LocationNameEdits     = {}

-- MyPaths Import Picker
Module.TempSettings.MyPathsData           = nil
Module.TempSettings.MyPathsZones          = {}
Module.TempSettings.MyPathsZoneIndex      = 1
Module.TempSettings.MyPathsPathNames      = {}
Module.TempSettings.MyPathsPathIndex      = 1
Module.TempSettings.MyPathsPoints         = {}
Module.TempSettings.MyPathsChecked        = {}

-- Mercs Peer Import Picker
Module.TempSettings.DbImportSources       = nil
Module.TempSettings.DbImportSourceLabels  = {}
Module.TempSettings.DbImportSourceIndex   = 1
Module.TempSettings.DbImportZones         = {}
Module.TempSettings.DbImportZoneIndex     = 1
Module.TempSettings.DbImportPoints        = {}
Module.TempSettings.DbImportChecked       = {}

-- Constants
Module.Constants                          = {}
Module.Constants.PullStates               = {
    ['PULL_IDLE']               = 1,
    ['PULL_WAITING_SHOULDPULL'] = 2,
    ['PULL_GROUPWATCH_WAIT']    = 3,
    ['PULL_PEERWATCH_WAIT']     = 4,
    ['PULL_SCAN']               = 5,
    ['PULL_MOVING_TO_WP']       = 6,
    ['PULL_NAV_INTERRUPT']      = 7,
    ['PULL_NAV_TO_TARGET']      = 8,
    ['PULL_PULLING']            = 9,
    ['PULL_RETURN_TO_CAMP']     = 10,
    ['PULL_WAITING_ON_MOB']     = 11,
}

Module.Constants.PullStateDisplayStrings  = {
    ['MERCS_PAUSED']            = { Display = Icons.MD_REPORT_PROBLEM, Text = "RGMercs Main Paused", Color = 'Red', },
    ['PULL_IDLE']               = { Display = Icons.FA_CLOCK_O, Text = "Idle", Color = 'Green', },
    ['PULL_GROUPWATCH_WAIT']    = { Display = Icons.MD_GROUP, Text = "Waiting on Group / Raid", Color = 'Yellow', },
    ['PULL_PEERWATCH_WAIT']     = { Display = Icons.MD_PEOPLE, Text = "Waiting on Zone Peers", Color = 'Yellow', },
    ['PULL_NAV_INTERRUPT']      = { Display = Icons.MD_PAUSE_CIRCLE_OUTLINE, Text = "Navigation Interrupted", Color = 'Red', },
    ['PULL_SCAN']               = { Display = Icons.FA_EYE, Text = "Scanning for Targets", Color = 'Green', },
    ['PULL_PULLING']            = { Display = Icons.FA_BULLSEYE, Text = "Pulling", Color = 'Red', },
    ['PULL_MOVING_TO_WP']       = { Display = Icons.MD_DIRECTIONS_RUN, Text = "Moving to Point", Color = 'Yellow', },
    ['PULL_NAV_TO_TARGET']      = { Display = Icons.MD_DIRECTIONS_RUN, Text = "Naving to Target", Color = 'Yellow', },
    ['PULL_RETURN_TO_CAMP']     = { Display = Icons.FA_FREE_CODE_CAMP, Text = "Returning to Camp", Color = 'Green', },
    ['PULL_WAITING_ON_MOB']     = { Display = Icons.FA_CLOCK_O, Text = "Waiting on Mob", Color = 'Yellow', },
    ['PULL_WAITING_SHOULDPULL'] = { Display = Icons.FA_CLOCK_O, Text = "Waiting for Should Pull", Color = 'Red', },
}

Module.Constants.PullStatesIDToName       = {}
for k, v in pairs(Module.Constants.PullStates) do Module.Constants.PullStatesIDToName[v] = k end

Module.Constants.PullModes          = {
    "PullToCamp",
    "ChainToCamp",
    "AreaHunt",
    "RoamingHunt",
    "CircuitHunt",
    "FightTo",
}

Module.Constants.PullModeDisplays   = {
    "Pull to Camp",
    "Chain to Camp",
    "Area Hunt",
    "Roaming Hunt",
    "Circuit Hunt",
    "Fight To",
}

Module.Constants.PullModePolicies   = {
    ['PullToCamp']  = { family = 'camp', runsDuringCombat = false, successCheck = 'any', rescanToCloser = true, scanCenter = 'self', radiusSetting = 'PullRadius', },
    ['ChainToCamp'] = { family = 'camp', runsDuringCombat = true, successCheck = 'chainCount', rescanToCloser = true, scanCenter = 'self', radiusSetting = 'PullRadius', },
    ['AreaHunt']    = { family = 'hunt', runsDuringCombat = false, successCheck = 'any', rescanToCloser = true, scanCenter = 'anchor', radiusSetting = 'PullRadiusHunt', },
    ['RoamingHunt'] = { family = 'hunt', runsDuringCombat = false, successCheck = 'any', rescanToCloser = true, scanCenter = 'self', radiusSetting = 'PullRadiusHunt', },
    ['CircuitHunt'] = { family = 'hunt', runsDuringCombat = false, successCheck = 'any', rescanToCloser = true, scanCenter = 'waypoint', radiusSetting = 'PullRadiusHunt', },
    ['FightTo']     = { family = 'directive', runsDuringCombat = false, successCheck = 'any', rescanToCloser = false, scanCenter = 'self', radiusSetting = 'PullRadius', },
}

Module.Constants.RangedTypes        = Set.new({ "archery", "bow", "throwingv1", "throwing", "throwingv2", "ammo", })
Module.Constants.PullAbilities      = {
    {
        id = "PetPull",
        Type = "Special",
        AbilityRange = 175,
        DisplayName = "Pet Pull",
        LOS = false,
        cond = function(self)
            return (Globals.Constants.RGPetClass:contains(Globals.CurLoadedClass) or (mq.TLO.Me.Pet.ID() > 0 and mq.TLO.Pet.Name():lower():find("familiar") == nil)) and
                Config:GetSetting('DoPetCommands')
        end,
    },
    {
        id = "Throw Stone",
        Type = "Disc",
        DisplayName = "Throw Stone",
        AbilityName = "Throw Stone",
        AbilityRange = function()
            local stoneSpell = mq.TLO.Spell("Throw Stone")
            return stoneSpell and stoneSpell.MyRange() or 70 -- actually 200 on laz, let the spell file do the work.
        end,
        cond = function(self)
            return mq.TLO.Me.CombatAbility("Throw Stone")()
        end,
    },
    {
        id = "Taunt",
        Type = "Ability",
        DisplayName = "Taunt",
        AbilityName = "Taunt",
        AbilityRange = 10,
        cond = function(self)
            return mq.TLO.Me.Skill("Taunt")() > 0
        end,
    },
    {
        id = "AutoAttack",
        Type = "Special",
        DisplayName = "Auto Attack",
        AbilityRange = function()
            if Targeting.GetTargetID() == 0 then return 6 end

            return Targeting.GetTargetMaxRangeTo() * .9
        end,
        cond = function(self)
            return true
        end,
    },
    {
        id = "Ranged",
        Type = "Special",
        DisplayName = "Ranged",
        AbilityRange = function()
            local range = mq.TLO.Me.Inventory("ranged").Range() or 0
            if mq.TLO.Me.Inventory("ranged").Type() == 'Archery' or mq.TLO.Me.Inventory("ranged").Type() == 'Bow' then
                range = range + (mq.TLO.Me.Inventory("ammo").Range() or 0)
            end
            return range
        end,
        cond = function(self)
            local rangedType = (mq.TLO.Me.Inventory("ranged").Type() or ""):lower()
            return Module.Constants.RangedTypes:contains(rangedType)
        end,
    },
    {
        id = "Kick",
        Type = "Ability",
        DisplayName = "Kick",
        AbilityName = "Kick",
        AbilityRange = 10,
        cond = function(self)
            return mq.TLO.Me.Skill("Kick")() > 0
        end,
    },
    {
        id = "Face",
        Type = "Special",
        AbilityRange = 5,
        DisplayName = "Face Pull",
        cond = function(self)
            return true
        end,
    },
    {
        id = "Staff of Viral Flux",
        Type = "Item",
        AbilityRange = 200,
        DisplayName = "Staff of Viral Flux",
        ItemName = "Staff of Viral Flux",
        cond = function(self)
            return mq.TLO.FindItemCount("Staff of Viral Flux")() > 0
        end,
    },
}

Module.Constants.AbortLogMessages   = {
    paused = "\ar ALERT: Aborting pull - paused at user's request \ax",
    listUpdated = "\ar ALERT: Aborting pull due to change in pull allow or deny list. \ax",
    disabled = "\ar ALERT: Pulling Disabled at user request. \ax",
    spawnGone = "PULL:\ar ALERT: Aborting mob died or despawned \ax",
    stranger = "PULL:\ar ALERT: Aborting mob is fighting a stranger and safe targeting is enabled! \ax",
    unreachable = "PULL:\ar ALERT: Aborting Fight To target has been unreachable for too long \ax",
    tooFar = "PULL:\ar ALERT: Aborting mob moved out of spawn distance \ax",
    noPath = "PULL:\ar ALERT: Aborting mob no longer reachable on mesh \ax",
    timeout = "\ar ALERT: Aborting due to timeout, adding mob to Pull Ignore List! \ax",
    manualTimeout = "PULL:\ar ALERT: Aborting manual pull - target could not be pulled in time \ax",
    objectiveTimeout = "PULL:\ar ALERT: Aborting Fight To - target could not be engaged in time \ax",
}

Module.Constants.EngageDescriptors  = {
    PetPull = {
        approach = 'none',
        stuckCheck = false,
        postSuccess = true,
        verbose = "Waiting on pet pull to finish...",
        action = function(self, attempt)
            Combat.PetAttack(attempt.targetId, false)
        end,
    },
    Face = {
        approach = 'abilityRange',
        forceLOS = true,
        stuckCheck = true,
        chainBreakLog = true,
        verbose = "Waiting on face pull to finish...",
    },
    Ranged = {
        approach = 'halfRange',
        stuckCheck = true,
        verbose = "Waiting on ranged pull to finish... %s",
        verboseShowsSuccess = true,
        action = function(self, attempt)
            Core.DoCmd("/ranged %d", attempt.targetId)
        end,
    },
    AutoAttack = {
        approach = 'halfRange',
        fireBeforeApproach = true,
        stuckCheck = true,
        verbose = "Waiting on autoattack pull to finish... %s",
        verboseShowsSuccess = true,
        action = function(self, attempt)
            Core.DoCmd("/attack")
        end,
    },
    Generic = {
        approach = 'halfRange',
        feetWetRenav = true,
        retarget = true,
        stuckCheck = true,
        startGraceMs = 500,
        verbose = "Waiting on ability pull to finish...%s",
        verboseShowsSuccess = true,
        action = function(self, attempt)
            local pullAbility = attempt.ability
            if pullAbility.Type:lower() == "ability" then
                if mq.TLO.Me.AbilityReady(pullAbility.id)() then
                    local abilityName = pullAbility.AbilityName
                    if type(abilityName) == 'function' then abilityName = abilityName() end
                    Casting.UseAbility(abilityName)
                end
            elseif pullAbility.Type:lower() == "spell" then
                local abilityName = pullAbility.AbilityName
                if type(abilityName) == 'function' then abilityName = abilityName() end
                Casting.UseSpell(abilityName, attempt.targetId, false, false, 0)
            elseif pullAbility.Type:lower() == "disc" then
                local abilityName = pullAbility.AbilityName
                if type(abilityName) == 'function' then abilityName = abilityName() end
                Casting.UseDisc(mq.TLO.Spell(abilityName), attempt.targetId)
            elseif pullAbility.Type:lower() == "aa" then
                local aaName = pullAbility.AbilityName
                if type(aaName) == 'function' then aaName = aaName() end
                Casting.UseAA(aaName, attempt.targetId, false, 0)
            elseif pullAbility.Type:lower() == "item" then
                local itemName = pullAbility.ItemName
                if type(itemName) == 'function' then itemName = itemName() end
                Logger.log_debug("Attempting to pull with Item: %s", itemName)
                Casting.UseItem(itemName, attempt.targetId)
            else
                Logger.log_error("\arInvalid PullAbilityType: %s :: %s", pullAbility.Type, pullAbility.id)
            end
        end,
    },
}

local PullStates                    = Module.Constants.PullStates -- hot-path alias for the per-tick state compares

Module.TempSettings.PullState       = PullStates.PULL_IDLE
Module.TempSettings.PullStateReason = ""

Module.Constants.PullStateHandlers  = {
    [PullStates.PULL_IDLE]               = 'PreAttemptTick',
    [PullStates.PULL_WAITING_SHOULDPULL] = 'PreAttemptTick',
    [PullStates.PULL_GROUPWATCH_WAIT]    = 'PreAttemptTick',
    [PullStates.PULL_PEERWATCH_WAIT]     = 'PreAttemptTick',
    [PullStates.PULL_SCAN]               = 'PreAttemptTick',
    [PullStates.PULL_MOVING_TO_WP]       = 'PreAttemptTick',
    [PullStates.PULL_NAV_INTERRUPT]      = 'PreAttemptTick',
    [PullStates.PULL_NAV_TO_TARGET]      = 'NavToTargetTick',
    [PullStates.PULL_PULLING]            = 'PullingTick',
    [PullStates.PULL_RETURN_TO_CAMP]     = 'ReturnToCampTick',
    [PullStates.PULL_WAITING_ON_MOB]     = 'WaitingOnMobTick',
}

-- Default Config
Module.DefaultConfig                = {
    -- custom: noshow in options
    ['DoPull']                                 = {
        DisplayName = "Enable Pulling",
        Tooltip = "Enable pulling",
        Default = false,
        Type = "Custom",
        OnChange = function(self)
            Movement.UpdateMapRadii()
        end,
    },
    ['PullAbility']                            = {
        DisplayName = "Pull Ability",
        Tooltip = "What should we pull with?",
        Default = 1,
        Type = "Custom",
        FAQ = "I don't see an ability that I want to use in the Pull Ability list. How can I add it?",
        Answer = "New default pull abilities can be requested via feedback, or you can add one by customizing a class config.",
    },
    ['PullMode']                               = {
        DisplayName = "Pull Mode",
        Type = "Custom",
        Default = "PullToCamp",
        ValidValues = Module.Constants.PullModes,
        OnChange = function() Modules:ExecModule("Pull", "OnPullModeChanged") end,
        FAQ = "What are the different Pull modes and how do they work?",
        Answer = "You can adjust Pull Modes on the Pull module tab.\n\n" ..
            "Pull to Camp: Attempt to pull single mobs back to a static camp location. Starting pulls camps you where you stand, or at a staged travel destination, unless a camp is already set.\n\n" ..
            "Chain to Camp: Continuously pull single mobs back to a static camp location until the chain count has been reached. The camp is set the same way as Pull to Camp.\n\n" ..
            "Area Hunt: Move from target to target within a defined circular area, fighting as you go. Optionally, set a hunt origin to travel to and hunt from.\n\n" ..
            "Roaming Hunt: Hunt around your current position, drifting as you fight.\n\n" ..
            "Circuit Hunt: Move between your enabled Pull Locations, hunting mobs in a defined radius from each.\n\n" ..
            "Fight To: Travel to a chosen target or location, fighting anything that aggros along the way.",
    },
    ['FarmWayPoints']                          = {
        DisplayName = "Farming Waypoints",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
    },
    ['PullLocations']                          = {
        DisplayName = "Pull Locations",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        FAQ = "How do I use Circuit Hunt mode for pulling?",
        Answer =
        "Circuit Hunt mode needs Pull Locations (waypoints) added to move between. You can add locations in the Pull module tab; the enabled locations, in order, form the circuit.",
    },
    ['PullAllowList']                          = {
        DisplayName = "Allow List",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        OnChange = function() Modules:ExecModule("Pull", "FlagPullListUpdated") end,
        FAQ = "I only want to attack a specific set of mobs in my pull mode, how do I set this up?",
        Answer = "In the Pull Allow List (found on your Pull module tab), you will find a button to add your target to that list.\n\n" ..
            "Alternatively, you can use /rgl pullallow <mobname> or /rgl pullallowrm <mobname> or <List#> to adjust this list from the command line.\n\n" ..
            "We will still engage mobs that aggro us, regardless of their absence from this list.",
    },
    ['PullDenyList']                           = {
        DisplayName = "Deny List",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        OnChange = function() Modules:ExecModule("Pull", "FlagPullListUpdated") end,
        FAQ = "I want to avoid pulling a specific mob (or mobs) in my pull mode, can I do that?",
        Answer = "In the Pull Deny List (found on your Pull module tab), you will find a button to add your target to that list.\n\n" ..
            "Alternatively, you can use /rgl pulldeny <mobname> or /rgl pulldenyrm <mobname> or <List#> to adjust this list from the command line.\n\n" ..
            "We will still engage mobs that aggro us, regardless of their presence on this list.",
    },
    ['PullAllowListShared']                    = {
        DisplayName = "Shared Allow List",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        Scope = "server",
        OnChange = function() Modules:ExecModule("Pull", "FlagPullListUpdated") end,
    },
    ['PullDenyListShared']                     = {
        DisplayName = "Shared Deny List",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        Scope = "server",
        OnChange = function() Modules:ExecModule("Pull", "FlagPullListUpdated") end,
    },
    ['UseSharedPullLists']                     = {
        DisplayName = "Use Shared Pull Lists",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = false,
        OnChange = function() Modules:ExecModule("Pull", "FlagPullListUpdated") end,
    },
    ['PullSafeZones']                          = {
        DisplayName = "SafeZones",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = { "poknowledge", "neighborhood", "guildhall", "guildlobby", "bazaar", },
        FAQ = "How do I make it so my puller doesn't pull in certain zones?",
        Answer = "Add the zone to the Pull Safe Zones list with /rgl pullsafezone (no argument adds your current zone; remove with /rgl pullsafezonerm).\n" ..
            "Pulling will not run in a safe zone.",
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },

    -- Rules
    ['PullDelay']                              = {
        DisplayName = "Pull Delay",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 1,
        Tooltip = "Delay X seconds between pulls to allow for buffs, looting, etc.",
        Default = 5,
        Min = 1,
        Max = 300,
    },
    ['WaypointDelay']                          = {
        DisplayName = "Waypoint Delay",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 2,
        Tooltip = "Circuit Hunt mode: Wait this many seconds at each Pull Location before moving to the next (pulls made there restart the timer).",
        Default = 0,
        Min = 0,
        Max = 3000,
    },
    ['AutoSetRoles']                           = {
        DisplayName = "Auto Set Group Roles",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 3,
        Tooltip = "As the group leader, automatically update the group's Puller and Main Assist roles when pulling is toggled.",
        Default = true,
    },
    ['PullDebuffed']                           = {
        DisplayName = "Pull While Debuffed",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 4,
        Tooltip = "Pull in spite of being debuffed (Rez Sickness and Root always hold pulls).",
        Default = false,
    },
    ['PullMobsInWater']                        = {
        DisplayName = "Pull Mobs In Water",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 5,
        Tooltip = "Allow pulling mobs that are in water.",
        Default = false,
    },
    ['PullBackwards']                          = {
        DisplayName = "Pull Facing Backwards",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 6,
        Tooltip = "When moving back to camp, back up and continually face your target.",
        Default = true,
    },
    ['ChainCount']                             = {
        DisplayName = "Chain Count",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 7,
        Tooltip = "Chain to Camp mode: The number of haters on xtarget before we stop pulling.",
        Default = 3,
        FAQ = "How do I pull using the Chain to Camp mode? What is the Chain Count?",
        Answer = "Chain to Camp mode is intended for a non-tank, non-assist puller to pull a stream of mobs back to a camp, one at a time.\n\n" ..
            "The puller will keep leaving camp to pull, even during combat, until the number of haters on xtarget matches or exceeds the Chain Count.",
        Min = 1,
        Max = Globals.XTargetSlots,
    },
    ['PullIgnoreTime']                         = {
        DisplayName = "Ignore Timer",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 8,
        Tooltip = "How long we will attempt to pull a target before adding it to an ignore list.",
        Default = 15,
        Min = 5,
        Max = 60,
        ConfigType = "Advanced",
        FAQ = "I keep trying to pull an invalid target, can I fix this?",
        Answer =
            "You should likely add that target to the Pull Deny List, which persists across sessions. However, RGMercs will auto-detect a repeatedly failed pull and will ignore that mob for the remainder of the pulling session.\n\n" ..
            "The Ignore Timer can adjust how long it takes before we do so.",
    },
    ['StopPullAfterDeath']                     = {
        DisplayName = "Stop Pulling After Death",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 9,
        Tooltip = "Disable pulling when you die; if unchecked, pulls resume when you return near your camp or the spot you died.",
        Default = true,
        ConfigType = "Advanced",
        FAQ = "Can pulling resume automatically after I die?",
        Answer = "Uncheck Stop Pulling After Death. Your camp is kept dormant while you are dead, and pulls resume when you return near your camp or the spot you died.\n\n" ..
            "Returning anywhere else, or visiting another zone first, drops the camp and pulls stay off.",
    },
    ['DoPullMoveAbilities']                    = {
        DisplayName = "Use Movement Buffs",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 12,
        Tooltip = "Use the pull movement buffs provided by your class config while pulling.",
        Default = true,
    },
    -- Distance
    ['PullRadius']                             = {
        DisplayName = "Camp Pull Radius",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 1,
        Tooltip = "Camp Modes: The distance to scan from your camp for valid pull targets.",
        Default = 350,
        Min = 1,
        Max = 10000,
        OnChange = function(self) Movement.UpdateMapRadii() end,
    },
    ['PullRadiusHunt']                         = {
        DisplayName = "Hunt Radius",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 2,
        Tooltip = "The distance to scan for valid pull targets in the Area, Roaming, and Circuit Hunt modes.",
        Default = 500,
        Min = 1,
        Max = 10000,
    },
    ['PullZRadius']                            = {
        DisplayName = "Pull Z Radius",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 4,
        Tooltip = "All Modes: The z-axis (up and down) distance to scan for valid pull targets.",
        Default = 90,
        Min = 1,
        Max = 350,
    },
    ['MaxPathRange']                           = {
        DisplayName = "Max Path Range",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 5,
        Tooltip = "All Modes: The maximum travel distance allowed when scanning for valid pull targets. Checks the actual path, rather than straight-line distance.",
        Default = 1000,
        Min = 1,
        Max = 10000,
    },
    ['MaxMoveTime']                            = {
        DisplayName = "Max Move Time",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 6,
        Tooltip = "The max number of seconds we will navigate to our intended pull target before we rescan for valid pull targets.",
        Default = 5,
        Min = 1,
        Max = 60,
        ConfigType = "Advanced",
        FAQ = "Why does my puller stop every so often before running again to the same target, or change targets while pulling?",
        Answer = "The puller will periodically reassess targets if navigation has been active for a while to improve efficiency.\n" ..
            "The time period can be adjusted with the Max Move Time setting in the Pulling Distance category.",
    },
    -- Puller Vitals
    ['PullHPPct']                              = {
        DisplayName = "Puller HP %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Puller Vitals",
        Index = 1,
        Tooltip = "The minimum health for a puller to continue to pull.",
        Default = 60,
        Min = 1,
        Max = 100,
    },
    ['PullManaPct']                            = {
        DisplayName = "Puller Mana %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Puller Vitals",
        Index = 2,
        Tooltip = "The minimum mana for a puller to continue to pull.",
        Default = 60,
        Min = 0,
        Max = 100,
    },
    ['PullEndPct']                             = {
        DisplayName = "Puller End %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Puller Vitals",
        Index = 3,
        Tooltip = "The minimum endurance for a puller to continue to pull.",
        Default = 30,
        Min = 0,
        Max = 100,
    },
    ['PullRespectMedState']                    = {
        DisplayName = "Respect Med State",
        Group = "Movement",
        Header = "Pulling",
        Category = "Puller Vitals",
        Index = 4,
        Tooltip = "Hold pulls if you are currently meditating.",
        Default = false,
    },
    ['PullBuffCount']                          = {
        DisplayName = "Min Buff Count",
        Group = "Movement",
        Header = "Pulling",
        Category = "Puller Vitals",
        Index = 5,
        Tooltip = "The minimum number of buffs in the buff window for a puller to continue to pull (0 disables).",
        Default = 0,
        Min = 0,
        Max = 40,
    },
    --Targets
    ['PullMinCon']                             = {
        DisplayName = "Pull Min Con",
        Group = "Movement",
        Header = "Pulling",
        Category = "Targets",
        Index = 1,
        Tooltip = "The minimum con color to be considered a valid pull target.",
        Default = 2,
        Min = 1,
        Max = #Globals.Constants.ConColors,
        Type = "Combo",
        ComboOptions = Globals.Constants.ConColors,
    },
    ['PullMaxCon']                             = {
        DisplayName = "Pull Max Con",
        Group = "Movement",
        Header = "Pulling",
        Category = "Targets",
        Index = 2,
        Tooltip = "The maximum con color to be considered a valid pull target.",
        Default = 5,
        Min = 1,
        Max = #Globals.Constants.ConColors,
        Type = "Combo",
        ComboOptions = Globals.Constants.ConColors,
    },
    ['MaxLevelDiff']                           = {
        DisplayName = "Max Red Con Level Diff",
        Group = "Movement",
        Header = "Pulling",
        Category = "Targets",
        Index = 3,
        Tooltip = "The maximum level gap allowed between the puller and pull target if Con Colors are being used.",
        Default = 6,
        Min = 4,
        Max = 125,
        ConfigType = "Advanced",
    },
    ['UsePullLevels']                          = {
        DisplayName = "Use Level-Based Pulling",
        Group = "Movement",
        Header = "Pulling",
        Category = "Targets",
        Index = 4,
        Tooltip = "Use direct level comparisons to find pull targets, instead of Con Colors.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['PullMinLevel']                           = {
        DisplayName = "Pull Min Level",
        Group = "Movement",
        Header = "Pulling",
        Category = "Targets",
        Index = 5,
        Tooltip = "The minimum level to be considered a valid pull target (if Level-Based Pulling is enabled).",
        Default = math.max(mq.TLO.Me.Level() - 3, 1),
        Min = 1,
        Max = 150,
        ConfigType = "Advanced",
    },
    ['PullMaxLevel']                           = {
        DisplayName = "Pull Max Level",
        Group = "Movement",
        Header = "Pulling",
        Category = "Targets",
        Index = 6,
        Tooltip = "The maximum level to be considered a valid pull target (if Level-Based Pulling is enabled).",
        Default = mq.TLO.Me.Level() + 3,
        Min = 1,
        Max = 150,
        ConfigType = "Advanced",
    },
    --Group Vitals
    ['WatchScope']                             = {
        DisplayName = "Vitals Watch",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 1,
        Tooltip = "Whose vitals hold pulls: Group / Raid watches your group and raid (including non-RGMercs group members); Zone Peers watches every RGMercs box in your zone.",
        Type = "Combo",
        ComboOptions = { "Off", "Group / Raid", "Zone Peers", },
        Default = 2,
        Min = 1,
        Max = 3,
        FAQ = "Can I hold pulls while my group or peers recover their vitals?",
        Answer = "Set Vitals Watch: Off disables the check, Group / Raid watches your group and raid (including non-RGMercs group members), " ..
            "and Zone Peers watches every RGMercs box in your zone.\n\n" ..
            "Pulls hold when a watched member falls below the Pulling Pause % and resume once everyone is above the Pulling Resume %.",
    },
    ['WatchEnd']                               = {
        DisplayName = "Watch Endurance",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 3,
        Tooltip = "Check endurance when monitoring group member or peer vitals.",
        Default = false,
    },
    ['WatchStopPct']                           = {
        DisplayName = "Pulling Pause %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 4,
        Tooltip = "Pause pulls when a watched member's vitals fall under this percent.",
        Default = 40,
        Min = 1,
        Max = 100,
    },
    ['WatchStartPct']                          = {
        DisplayName = "Pulling Resume %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 5,
        Tooltip = "Resume pulls when a watched member's vitals climb above this percent.",
        Default = 80,
        Min = 1,
        Max = 100,
    },
    ['WatchClasses']                           = {
        DisplayName = "Watched Classes",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 6,
        Type = "Custom",
        Tooltip = "Select which classes the Vitals Watch monitors.",
        Default = {},
    },
    ['PullWaitCorpse']                         = {
        DisplayName = "Hold for Corpses",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 10,
        Tooltip = "Hold pulls while we detect any groupmember's corpse in the vicinity.",
        Default = Globals.ServerEnv:lower() == "live",
    },
    ['WaitAfterRez']                           = {
        DisplayName = "Delay After Rez",
        Group = "Movement",
        Header = "Pulling",
        Category = "Peer and Group Vitals",
        Index = 11,
        Tooltip = "After a corpse detected by Hold for Corpses is rezzed, allow this many seconds for rebuffing before pulls resume.",
        Default = 30,
        Min = 0,
        Max = 90,
    },
}

-- Command Handlers
Module.CommandHandlers              = {
    pulltarget = {
        usage = "/rgl pulltarget",
        about = "Pulls your current target using the currently selected Pull Ability.",
        handler = function(self, ...)
            self:SetPullTarget()
            return true
        end,
    },
    pullmode = {
        usage = "/rgl pullmode <camp|chain|area|roam|circuit|fightto>",
        about = "Sets the Pull Mode. The full mode names (PullToCamp, AreaHunt, etc) are also accepted.",
        handler = function(self, mode)
            local friendlyNames = { camp = "PullToCamp", chain = "ChainToCamp", area = "AreaHunt", roam = "RoamingHunt", circuit = "CircuitHunt", fightto = "FightTo", }
            local modeArg = tostring(mode or ""):lower()
            local newMode = friendlyNames[modeArg]
            if not newMode then
                for _, modeName in ipairs(self.Constants.PullModes) do
                    if modeName:lower() == modeArg then newMode = modeName end
                end
            end
            if not newMode then
                Logger.log_error("/rgl pullmode - '%s' is not a pull mode (use camp, chain, area, roam, circuit or fightto).", tostring(mode))
                return true
            end
            self:SetPullMode(newMode)
            Logger.log_info("Pull mode set to %s.", self.Constants.PullModeDisplays[Module.PullModeIndex(newMode)])
            return true
        end,
    },
    pullobj = {
        usage = "/rgl pullobj [target | id <spawnID> | wp <n|name> | me | <y> <x> [z] | <xy|yx|xyz|yxz> <coords>]",
        about =
        "Stages the objective for the current Pull Mode (Fight To target or destination, hunt origin, or camp travel destination) while pulls are stopped. Start pulls with /rgl pullstart.",
        handler = function(self, ...)
            if Config:GetSetting('DoPull') then
                Logger.log_error("Stop pulls before changing the objective.")
                return true
            end
            local pullModeName = Config:GetSetting('PullMode')
            if pullModeName == "RoamingHunt" or pullModeName == "CircuitHunt" then
                Logger.log_error("Roaming and Circuit Hunt take no objective - set the circuit position with /rgl pullwp.")
                return true
            end

            local args = { ..., }
            local first = tostring(args[1] or "target"):lower()

            if first == "me" and pullModeName == "FightTo" then
                Logger.log_error("Fight To - cannot use your own position as the destination!")
                return true
            end

            if pullModeName == "FightTo" and (first == "target" or first == "id") then
                local spawnID = first == "id" and (tonumber(args[2]) or 0) or (mq.TLO.Target.ID() or 0)
                if not self:SetFightToSpawn(spawnID) then return true end
            else
                local loc
                if first == "wp" then
                    local entry = self:ResolveLocationEntry(table.concat(args, " ", 2))
                    if not entry then return true end
                    loc = { y = entry.y, x = entry.x, z = entry.z, name = entry.name, }
                elseif first == "me" then
                    loc = { y = mq.TLO.Me.Y(), x = mq.TLO.Me.X(), z = mq.TLO.Me.Z(), }
                elseif first == "target" then
                    if not mq.TLO.Target() then
                        Logger.log_error("/rgl pullobj - no location given and no valid target exists!")
                        return true
                    end
                    loc = { y = mq.TLO.Target.Y(), x = mq.TLO.Target.X(), z = mq.TLO.Target.Z(), }
                elseif first == "id" then
                    local spawn = mq.TLO.Spawn("id " .. (tonumber(args[2]) or 0))
                    if not spawn() then
                        Logger.log_error("/rgl pullobj - no spawn with ID %s exists!", tostring(args[2]))
                        return true
                    end
                    loc = { y = spawn.Y(), x = spawn.X(), z = spawn.Z(), }
                else
                    local err
                    loc, err = Module.ParseLocArgs(...)
                    if not loc then
                        Logger.log_error("/rgl pullobj - %s", err)
                        return true
                    end
                end
                if pullModeName == "FightTo" then
                    if not self:SetFightToLoc(loc) then return true end
                elseif pullModeName == "AreaHunt" then
                    if not self:SetHuntOrigin(loc) then return true end
                else
                    self:FillLocEntry(loc)
                end
            end
            self.TempSettings.LocEntryMode = pullModeName
            return true
        end,
    },
    pullstart = {
        usage = "/rgl pullstart",
        about = "Enables pulling in the currently selected Pull Mode. Stage any needed objective first with /rgl pullobj.",
        handler = function(self, ...)
            self:StartPuller()
            return true
        end,
    },
    pullstop = {
        usage = "/rgl pullstop",
        about = "Disables pulling.",
        handler = function(self, ...)
            self:ClearObjective()
            self:StopPuller()
            return true
        end,
    },
    pullpause = {
        usage = "/rgl pullpause",
        about = "Toggles pausing pulls. Pull settings (camp, locs, etc) are kept, but no pulls are attempted until unpaused.",
        handler = function(self, ...)
            self.TempSettings.PausePulls = not self.TempSettings.PausePulls
            Logger.log_info(self.TempSettings.PausePulls and "Pulls paused." or "Pulls unpaused.")
            return true
        end,
    },
    pulldeny = {
        usage = "/rgl pulldeny \"<name>\"",
        about = "Adds <name> to the Pull Deny List. If no name is entered, your target's name is used. Ensure quotes are used on multi-word mob names!",
        handler = function(self, name)
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl pulldeny - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl pulldeny - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            self:AddMobToList("PullDenyList", name)
            return true
        end,
    },
    pullallow = {
        usage = "/rgl pullallow \"<name>\"",
        about = "Adds <name> to the Pull Allow List. If no name is entered, your target's name is used. Ensure quotes are used on multi-word mob names!",
        handler = function(self, name)
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl pullallow - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl pullallow - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            self:AddMobToList("PullAllowList", name)
            return true
        end,
    },
    pullignoreclear = {
        usage = "/rgl pullignoreclear",
        about = "Clears the Pull Ignore List.",
        handler = function(self, name)
            self:ClearIgnoreList()
            return true
        end,
    },
    pulldenyrm = {
        usage = "/rgl pulldenyrm \"<name>\" or /rgl pulldenyrm <List#>",
        about = "Removes <name> or <List#> from the Pull Deny List. If no name is entered, your target's name is used. Ensure quotes are used on multi-word mob names!",
        handler = function(self, arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl pulldenyrm - no argument given and no valid target exists!")
                return
            end
            self:DeleteMobFromList("PullDenyList", arg1)
            return true
        end,
    },
    pullallowrm = {
        usage = "/rgl pullallowrm \"<name>\" or /rgl pullallowrm <List#>",
        about = "Removes <name> or <List#> from the Pull Allow List. If no name is entered, your target's name is used. Ensure quotes are used on multi-word mob names!",
        handler = function(self, arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl pullallowrm - no argument given and no valid target exists!")
                return
            end
            self:DeleteMobFromList("PullAllowList", arg1)
            return true
        end,
    },
    pullsafezone = {
        usage = "/rgl pullsafezone [zone shortname]",
        about = "Adds the zone (no argument = your current zone) to the Pull Safe Zones list.",
        handler = function(self, zone)
            local zoneName = tostring(zone or mq.TLO.Zone.ShortName() or ""):lower()
            local safeZones = {}
            for _, existing in ipairs(Config:GetSetting('PullSafeZones')) do
                if existing:lower() == zoneName then
                    Logger.log_info("%s is already in the Pull Safe Zones list.", zoneName)
                    return true
                end
                table.insert(safeZones, existing)
            end
            table.insert(safeZones, zoneName)
            Config:SetSetting('PullSafeZones', safeZones)
            Logger.log_info("Added %s to the Pull Safe Zones list - pulling will not run there.", zoneName)
            return true
        end,
    },
    pullsafezonerm = {
        usage = "/rgl pullsafezonerm <zone shortname or List#>",
        about = "Removes <zone shortname> or <List#> from the Pull Safe Zones list.",
        handler = function(self, arg1)
            local currentZones = Config:GetSetting('PullSafeZones')
            local removeIndex = tonumber(arg1)
            if removeIndex and not currentZones[removeIndex] then removeIndex = nil end
            if not removeIndex then
                local zoneName = tostring(arg1 or ""):lower()
                for index, existing in ipairs(currentZones) do
                    if existing:lower() == zoneName then
                        removeIndex = index
                        break
                    end
                end
            end
            if not removeIndex then
                Logger.log_error("/rgl pullsafezonerm - '%s' does not match a safe zone - use a zone shortname or an index between 1 and %d.", tostring(arg1), #currentZones)
                return true
            end
            local safeZones = {}
            for index, existing in ipairs(currentZones) do
                if index ~= removeIndex then table.insert(safeZones, existing) end
            end
            Config:SetSetting('PullSafeZones', safeZones)
            Logger.log_info("Removed %s from the Pull Safe Zones list.", currentZones[removeIndex])
            return true
        end,
    },
    pullwp = {
        usage = "/rgl pullwp <n|name>",
        about = "Sets the circuit's current waypoint to the given pull location; a numeric index counts enabled locations only.",
        handler = function(self, ...)
            if #self:GetEnabledLocations() == 0 then
                Logger.log_error("No enabled pull locations in this zone.")
                return true
            end
            local entry = self:ResolveLocationEntry(table.concat({ ..., }, " "))
            if not entry then return true end
            for index, enabledEntry in ipairs(self:GetEnabledLocations()) do
                if enabledEntry == entry then
                    self.TempSettings.CurrentWPName = entry.name
                    self.TempSettings.CurrentWPIndex = index
                    Logger.log_info("Current pull location set to %s (%d)", entry.name, index)
                    return true
                end
            end
            Logger.log_error("Pull location %s is disabled - enable it before setting the circuit position to it.", entry.name)
            return true
        end,
    },
    pulllocadd = {
        usage = "/rgl pulllocadd [<name>]",
        about = "Adds your current position to this zone's pull locations, optionally renaming it to <name>.",
        handler = function(self, ...)
            self:AddLocationHere()
            local name = table.concat({ ..., }, " ")
            if name ~= "" then
                self:RenameLocation(#self:GetZoneLocations(), name)
            end
            return true
        end,
    },
    pulllocrm = {
        usage = "/rgl pulllocrm <name|idx>",
        about = "Deletes the given pull location from this zone's list.",
        handler = function(self, ...)
            local idx = self:ResolveZoneLocationIndex(table.concat({ ..., }, " "))
            if not idx then return true end
            self:DeleteLocation(idx)
            return true
        end,
    },
    enablepullloc = {
        usage = "/rgl enablepullloc <name|idx>",
        about = "Enables the given pull location.",
        handler = function(self, ...)
            local idx = self:ResolveZoneLocationIndex(table.concat({ ..., }, " "))
            if not idx then return true end
            local entry = self:GetZoneLocations()[idx]
            if entry.enabled then
                Logger.log_info("Pull location %s is already enabled.", entry.name)
                return true
            end
            self:ToggleLocation(idx)
            Logger.log_info("Pull location %s enabled.", entry.name)
            return true
        end,
    },
    disablepullloc = {
        usage = "/rgl disablepullloc <name|idx>",
        about = "Disables the given pull location.",
        handler = function(self, ...)
            local idx = self:ResolveZoneLocationIndex(table.concat({ ..., }, " "))
            if not idx then return true end
            local entry = self:GetZoneLocations()[idx]
            if not entry.enabled then
                Logger.log_info("Pull location %s is already disabled.", entry.name)
                return true
            end
            self:ToggleLocation(idx)
            Logger.log_info("Pull location %s disabled.", entry.name)
            return true
        end,
    },
}

-- Setup & Lifecycle
function Module:New()
    return Base.New(self)
end

function Module:LoadSettings()
    Base.LoadSettings(self)

    -- turn off at startup for safety
    Config:SetSetting('DoPull', false)

    local farmWayPoints = Config:GetSetting('FarmWayPoints') or {}
    if next(farmWayPoints) ~= nil then
        local pullLocations = Config:GetSetting('PullLocations') or {}
        for zoneKey, wayPoints in pairs(farmWayPoints) do
            if #(pullLocations[zoneKey:lower()] or {}) == 0 then
                local zoneLocations = {}
                for index, wayPoint in ipairs(wayPoints) do
                    if type(wayPoint.y) == "number" and type(wayPoint.x) == "number" and type(wayPoint.z) == "number" then
                        table.insert(zoneLocations, { name = string.format("Location %d", #zoneLocations + 1), y = wayPoint.y, x = wayPoint.x, z = wayPoint.z, enabled = true, })
                    else
                        Logger.log_info("Skipping farm waypoint %d in %s - invalid coordinates.", index, zoneKey)
                    end
                end
                pullLocations[zoneKey:lower()] = zoneLocations
            end
        end
        Config:SetSetting('PullLocations', pullLocations)
        Config:SetSetting('FarmWayPoints', {})
    end
end

-- Pull Abilities
---@param id number
---@return string
function Module:GetPullAbilityDisplayName(id)
    local entry = self.TempSettings.ValidPullAbilities[id]
    if not entry then return "Error" end
    local displayName = entry.DisplayName

    if type(displayName) == 'function' then displayName = displayName() end

    return displayName or "Error"
end

function Module:SetValidPullAbilities()
    if Globals.GetTimeSeconds() - self.TempSettings.LastPullAbilityCheck < 10 then return end

    self.TempSettings.LastPullAbilityCheck = Globals.GetTimeSeconds()
    local tmpValidPullAbilities = {}
    local tmpPullAbilityIDToName = {}

    for _, v in ipairs(Module.Constants.PullAbilities) do
        if Core.SafeCallFunc("Checking Pull Ability Condition", v.cond, self) then
            table.insert(tmpValidPullAbilities, v)
        end
    end

    -- pull in class specific configs.
    for _, v in ipairs(Modules:ExecModule("Class", "GetPullAbilities")) do
        if Core.SafeCallFunc("Checking Pull Ability Condition", v.cond, self) then
            table.insert(tmpValidPullAbilities, v)
        end
    end

    for k, v in ipairs(tmpValidPullAbilities) do
        tmpPullAbilityIDToName[v.id] = k
    end

    self.TempSettings.ValidPullAbilities = tmpValidPullAbilities
    self.TempSettings.PullAbilityIDToName = tmpPullAbilityIDToName
end

function Module:GetPullAbilityRange()
    if not self.ModuleLoaded then return 0 end
    local pullAbility = self.TempSettings.ValidPullAbilities[Config:GetSetting('PullAbility')]
    if not pullAbility then return 0 end

    local ret = pullAbility.AbilityRange
    if type(ret) == 'function' then ret = ret() end
    return ret
end

function Module:OnCombatModeChanged()
    self:SetValidPullAbilities()
    self:RebuildMoveAbilities()
end

-- Pull Move Abilities
function Module:RebuildMoveAbilities()
    local moveAbilities = {}
    for _, entry in ipairs(Entries.FilterLoaded(Modules:ExecModule("Class", "GetPullMoveAbilities"), self)) do
        local entryType = (entry.type or ""):lower()
        if type(entry.name) == "string" and (entryType == "aa" or entryType == "item" or entryType == "song") then
            table.insert(moveAbilities, entry)
        else
            Logger.log_error("\arInvalid PullMoveAbility entry: %s :: %s", tostring(entry.type), tostring(entry.name))
        end
    end
    self.TempSettings.PullMoveAbilities = moveAbilities
end

function Module:GetMoveAbilities()
    if not self.TempSettings.PullMoveAbilities then self:RebuildMoveAbilities() end
    return self.TempSettings.PullMoveAbilities
end

--- Fires the class config's movement buffs while pulling; we only ever start things - not ready means skip and catch a later pass.
function Module:CheckMoveAbilities(force)
    if not Config:GetSetting('DoPullMoveAbilities') then return end
    if not force and Globals.GetTimeSeconds() - self.TempSettings.LastMoveAbilityCheck < 5 then return end

    self.TempSettings.LastMoveAbilityCheck = Globals.GetTimeSeconds()
    for _, entry in ipairs(self:GetMoveAbilities()) do
        local entryType = (entry.type or ""):lower()
        local resolved = Core.GetResolvedActionMapItem(entry.name) or entry.name
        local abilityName = type(resolved) == "string" and resolved or entry.name
        if entryType == "song" and type(resolved) == "string" then resolved = mq.TLO.Spell(resolved) end
        local ready
        if entryType == "aa" then
            ready = Casting.AAReady(abilityName)
        elseif entryType == "item" then
            ready = Casting.ItemReady(abilityName)
        else
            ready = Casting.SongReady(resolved)
        end
        if ready and (not entry.cond or Core.SafeCallFunc("Checking Pull Move Ability Condition", entry.cond, self, resolved)) then
            if entryType == "aa" then
                Core.DoCmd("/alt act %d", mq.TLO.Me.AltAbility(abilityName).ID())
            elseif entryType == "item" then
                Core.DoCmd('/useitem "%s"', abilityName)
            else
                Core.DoCmd('/cast "=%s"', resolved.RankName())
            end
        end
    end
end

-- Mode Policy
function Module.PullModeIndex(name)
    for index, modeName in ipairs(Module.Constants.PullModes) do
        if modeName == name then return index end
    end
    return 1
end

function Module:GetModePolicy()
    return Module.Constants.PullModePolicies[Config:GetSetting('PullMode')]
end

function Module:SetPullMode(newMode)
    Config:SetSetting('PullMode', newMode)
end

---@param mode string
---@return boolean
function Module:IsPullMode(mode)
    return Config:GetSetting('PullMode') == mode
end

function Module:OnPullModeChanged()
    if self:GetModePolicy().family ~= 'camp' and (self.TempSettings.EscortScopeWord or self.TempSettings.CampTravelLoc) then
        self:ClearEscortState()
        self.TempSettings.CampTravelLoc = nil
        self.TempSettings.Travel = nil
        if mq.TLO.Navigation.Active() then Movement:DoNav(false, "stop log=off") end
    end
end

-- Pure Decision Helpers (unit-tested)
function Module.PullSuccessCheck(successCheck, xtHaterCount, chainCount)
    if successCheck == 'chainCount' then return xtHaterCount >= chainCount end
    return xtHaterCount > 0
end

function Module.DecideUserAbort(abortCtx, source)
    if abortCtx.pausePulls then return 'paused' end
    if abortCtx.pullListUpdated then return 'listUpdated' end
    if (not abortCtx.doPull and source ~= 'manual') or abortCtx.pauseMain then return 'disabled' end
    return nil
end

function Module.DecideAbort(attempt, abortCtx)
    local userReason = Module.DecideUserAbort(abortCtx, attempt.source)
    if userReason then return userReason end
    if abortCtx.spawnGone then return 'spawnGone' end

    if attempt.source == 'objective' then
        if abortCtx.safeTargeting and abortCtx.fightingStranger then return 'stranger' end
        if abortCtx.graceExpired then return 'unreachable' end
        if not abortCtx.navigating and abortCtx.timedOut then return 'objectiveTimeout' end
    elseif attempt.source == 'scan' then
        if abortCtx.distance > abortCtx.maxPathRange then return 'tooFar' end
        if not abortCtx.pathExists then return 'noPath' end
        if abortCtx.safeTargeting and abortCtx.fightingStranger then return 'stranger' end
        if not abortCtx.navigating and abortCtx.timedOut then return 'timeout' end
    elseif attempt.source == 'manual' then
        if not abortCtx.navigating and abortCtx.timedOut then return 'manualTimeout' end
    end

    return nil
end

function Module.BuildIntentSentence(params)
    local scope = params.scope or 1
    local canStart = true
    local gapReason = nil
    local text = nil

    local scopeWord = params.scopeWord or (scope == 2 and "in-zone" or "group / raid")
    local pre = params.breakCamp and "I'll break my camp, " or "I'll "
    if params.manageMovement then
        pre = pre .. string.format("set my %s peers to chase me, ", scopeWord)
    end
    local joiner = (params.breakCamp or params.manageMovement) and "then " or ""

    if params.mode == "PullToCamp" or params.mode == "ChainToCamp" then
        local action = params.mode == "ChainToCamp" and "chain-pull to camp" or "pull to camp"
        if params.locationSet then
            if params.manageMovement then
                text = pre .. string.format("travel to %s, set camp for everyone on arrival, then %s.", Module.FormatLoc(params.loc), action)
            else
                text = pre .. string.format("travel to %s, set camp for myself, then %s.", Module.FormatLoc(params.loc), action)
            end
        else
            if params.existingCamp then
                text = string.format("I'll %s to my existing camp.", params.mode == "ChainToCamp" and "chain-pull" or "pull")
            elseif params.manageMovement then
                text = string.format("I'll set camp for myself and my %s peers here, then %s.", scopeWord, action)
            else
                text = string.format("I'll set camp for myself here, then %s.", action)
            end
        end
    elseif params.mode == "AreaHunt" then
        if params.locationSet then
            text = pre .. string.format("travel to %s, then hunt the area.", Module.FormatLoc(params.loc))
        else
            text = pre .. joiner .. "hunt the area from my present position."
        end
    elseif params.mode == "RoamingHunt" then
        text = pre .. joiner .. "roam and hunt from my present position."
    elseif params.mode == "CircuitHunt" then
        if params.hasWaypoints then
            local count = params.waypointCount or 0
            text = pre .. joiner .. string.format("run a circuit of the %d enabled Pull %s below.", count, count == 1 and "Location" or "Locations")
        else
            canStart = false
            gapReason = "Add an enabled pull location to run a circuit."
            text = gapReason
        end
    elseif params.mode == "FightTo" then
        if params.fightToKind == "spawn" then
            text = pre .. joiner .. string.format("fight my way to %s and engage it.", params.fightToName or "")
        elseif params.fightToKind == "loc" then
            text = pre .. joiner .. string.format("fight my way to %s.", Module.FormatLoc(params.loc))
        else
            canStart = false
            gapReason = "Set a Fight To target first."
            text = gapReason
        end
    end

    text = (text or ""):gsub("^%l", string.upper)
    if text:sub(-1) ~= "." then text = text .. "." end

    return { text = text, canStart = canStart, gapReason = gapReason, }
end

function Module.ParseLocArgs(...)
    local args = { ..., }
    if #args == 0 then return nil, "no coordinates given" end
    for i = 1, #args do args[i] = (tostring(args[i]):gsub(",", "")) end

    local order = "yx"
    local coordStart = 1
    if not tonumber(args[1]) then
        order = tostring(args[1]):lower():gsub("^loc", "")
        coordStart = 2
        if not ({ xy = true, yx = true, xyz = true, yxz = true, })[order] then
            return nil, string.format("'%s' is not a valid coordinate order (use xy, yx, xyz or yxz)", tostring(args[1]))
        end
    elseif #args >= 3 then
        order = "yxz"
    end

    local coords = {}
    for i = coordStart, #args do
        local value = tonumber(args[i])
        if not value then return nil, string.format("'%s' is not a number", tostring(args[i])) end
        table.insert(coords, value)
    end
    if #coords ~= #order then
        return nil, string.format("expected %d coordinates for '%s', got %d", #order, order, #coords)
    end

    local loc = {}
    for i = 1, #order do
        loc[order:sub(i, i)] = coords[i]
    end
    return loc
end

-- Pull State Accessors
---@param state number
---@param reason string
function Module:SetPullState(state, reason)
    self.TempSettings.PullState = state
    self.TempSettings.PullStateReason = reason
end

---@param state string
---@return boolean
function Module:IsPullState(state)
    return self.TempSettings.PullState == PullStates[state]
end

---@return boolean
function Module:IsActivelyPulling()
    local pullState = self.TempSettings.PullState
    return pullState ~= PullStates.PULL_IDLE and pullState ~= PullStates.PULL_GROUPWATCH_WAIT and pullState ~= PullStates.PULL_PEERWATCH_WAIT
end

---True while the puller is committed to a pull attempt or a travel leg (not just idle/waiting/scanning).
---@return boolean
function Module:IsBusyPulling()
    local pullState = self.TempSettings.PullState
    return pullState == PullStates.PULL_MOVING_TO_WP
        or pullState == PullStates.PULL_NAV_INTERRUPT
        or pullState == PullStates.PULL_NAV_TO_TARGET
        or pullState == PullStates.PULL_PULLING
        or pullState == PullStates.PULL_RETURN_TO_CAMP
        or pullState == PullStates.PULL_WAITING_ON_MOB
end

function Module:GetPullStateTargetInfo()
    return string.format("%s(%d) Dist(%d)", Targeting.GetTargetCleanName(), Targeting.GetTargetID(), Targeting.GetTargetDistance())
end

-- Render / UI
function Module:RenderMobList(displayName, settingName)
    if ImGui.CollapsingHeader(string.format("Pull %s", displayName)) then
        local invalidTarget = not (mq.TLO.Target() and Targeting.TargetIsType("NPC"))
        ImGui.BeginDisabled(invalidTarget)
        ImGui.PushID("##_small_btn_allow_target_" .. settingName)
        if ImGui.SmallButton(invalidTarget and "Select an NPC to Add" or string.format("Add Target To %s", displayName)) then
            self:AddMobToList(settingName, mq.TLO.Target.CleanName())
        end
        ImGui.PopID()
        ImGui.EndDisabled()

        if ImGui.BeginTable("settingName", 4, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 40.0)
            ImGui.TableSetupColumn('Count', (ImGuiTableColumnFlags.WidthFixed), 40.0)
            ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 150.0)
            ImGui.TableSetupColumn('Controls', (ImGuiTableColumnFlags.WidthFixed), 80.0)
            ImGui.TableHeadersRow()

            for idx, mobName in ipairs(Config:GetZoneList(self:ActivePullList(settingName))) do
                ImGui.TableNextColumn()
                Ui.RenderText(tostring(idx))
                ImGui.TableNextColumn()
                Ui.RenderText(tostring(mq.TLO.SpawnCount(string.format("NPC %s", mobName))))
                ImGui.TableNextColumn()
                Ui.RenderText(mobName)
                ImGui.TableNextColumn()
                ImGui.PushID("##_small_btn_delete_mob_" .. settingName .. tostring(idx))
                if ImGui.SmallButton(Icons.FA_TRASH) then
                    self:DeleteMobFromList(settingName, idx)
                end
                ImGui.PopID()
            end

            ImGui.EndTable()
        end
    end
end

function Module:RenderTargetTable(tableId, targets)
    if ImGui.BeginTable(tableId, 5, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Index', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 250.0)
        ImGui.TableSetupColumn('Level', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Distance', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthFixed), 160.0)
        ImGui.TableHeadersRow()

        for idx, spawn in ipairs(targets) do
            if (spawn.ID() or 0) > 0 then
                ImGui.TableNextColumn()
                Ui.RenderText("%d", idx)
                ImGui.TableNextColumn()
                ImGui.PushStyleColor(ImGuiCol.Text, Ui.GetConColorBySpawn(spawn))
                ImGui.PushID(string.format("##select_pull_npc_%d", idx))
                local _, clicked = ImGui.Selectable(spawn.CleanName() or "Unknown")
                if clicked then
                    Logger.log_debug("Targeting: %d", spawn.ID() or 0)
                    spawn.DoTarget()
                end
                ImGui.PopID()
                ImGui.TableNextColumn()
                Ui.RenderText("%d", spawn.Level() or 0)
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                Ui.RenderText("%0.2f", spawn.Distance() or 0)
                ImGui.TableNextColumn()
                Ui.NavEnabledLoc(spawn.LocYXZ() or "0,0,0")
            end
        end

        ImGui.EndTable()
    end
end

function Module:RenderPullTargets()
    self:RenderTargetTable("PullTargets", self.TempSettings.PullTargets)
end

function Module:RenderIgnoreTargets()
    ImGui.PushID("##_small_btn_clear_ignore_list")
    if ImGui.SmallButton("Clear Pull Ignore List") then
        self:ClearIgnoreList()
    end
    ImGui.PopID()
    self:RenderTargetTable("PullIgnoreTargets", self.TempSettings.PullIgnoreTargets)
end

function Module:RenderObjectiveRow(pullModeName)
    if self.TempSettings.LocEntryMode ~= pullModeName then
        local previousMode = self.TempSettings.LocEntryMode
        self.TempSettings.LocEntryMode = pullModeName
        local withinCampFamily = previousMode and Module.Constants.PullModePolicies[previousMode] and Module.Constants.PullModePolicies[previousMode].family == 'camp' and
            Module.Constants.PullModePolicies[pullModeName].family == 'camp'
        if not withinCampFamily then
            local storedLoc = nil
            if pullModeName == "AreaHunt" then
                storedLoc = self.TempSettings.HuntOrigin
            elseif pullModeName == "FightTo" and self.TempSettings.FightTo and not self.TempSettings.FightTo.id then
                storedLoc = self.TempSettings.FightTo
            end
            if storedLoc then
                self:FillLocEntry(storedLoc)
            else
                self.TempSettings.LocEntryY, self.TempSettings.LocEntryX, self.TempSettings.LocEntryZ = "", "", ""
            end
        end
    end

    local locked = Config:GetSetting('DoPull')
    local objectiveWord = "camp travel destination"
    if pullModeName == "AreaHunt" then
        objectiveWord = "hunt origin"
    elseif pullModeName == "FightTo" then
        objectiveWord = "Fight To destination"
    end
    ImGui.BeginDisabled(locked)
    if pullModeName == "FightTo" then
        ImGui.BeginDisabled(not (mq.TLO.Target() and Targeting.TargetIsType("NPC")))
        ImGui.PushID("##_small_btn_myloc_" .. pullModeName)
        if ImGui.Button("Use My Target") then
            self:SetFightToSpawn(mq.TLO.Target.ID() or 0)
        end
        Ui.Tooltip("Fight to your current target and engage it.")
        ImGui.PopID()
        ImGui.EndDisabled()
    else
        ImGui.PushID("##_small_btn_myloc_" .. pullModeName)
        if ImGui.Button("Use My Loc") then
            local loc = { y = mq.TLO.Me.Y(), x = mq.TLO.Me.X(), z = mq.TLO.Me.Z(), }
            if pullModeName == "AreaHunt" then
                self:SetHuntOrigin(loc)
            else
                self:FillLocEntry(loc)
            end
        end
        Ui.Tooltip(string.format("Use your current position as the %s.", objectiveWord))
        ImGui.PopID()
    end
    ImGui.SameLine()
    ImGui.BeginDisabled(not mq.TLO.Target())
    ImGui.PushID("##_small_btn_targetloc_" .. pullModeName)
    if ImGui.Button("Use Target's Loc") then
        local loc = { y = mq.TLO.Target.Y(), x = mq.TLO.Target.X(), z = mq.TLO.Target.Z(), }
        if pullModeName == "FightTo" then
            self:SetFightToLoc(loc)
        elseif pullModeName == "AreaHunt" then
            self:SetHuntOrigin(loc)
        else
            self:FillLocEntry(loc)
        end
    end
    Ui.Tooltip(string.format("Use your target's position as the %s.", objectiveWord))
    ImGui.PopID()
    ImGui.EndDisabled()
    ImGui.SameLine()
    ImGui.AlignTextToFramePadding()
    Ui.RenderText("Y")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(60)
    self.TempSettings.LocEntryY = ImGui.InputText("##PullLocEntryY", self.TempSettings.LocEntryY)
    ImGui.SameLine()
    ImGui.AlignTextToFramePadding()
    Ui.RenderText("X")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(60)
    self.TempSettings.LocEntryX = ImGui.InputText("##PullLocEntryX", self.TempSettings.LocEntryX)
    ImGui.SameLine()
    ImGui.AlignTextToFramePadding()
    Ui.RenderText("Z")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(60)
    self.TempSettings.LocEntryZ = ImGui.InputText("##PullLocEntryZ", self.TempSettings.LocEntryZ)
    Ui.Tooltip("Z is optional but should be provided in multi-level zones.")
    ImGui.SameLine()
    ImGui.PushID("##_small_btn_setloc_" .. pullModeName)
    if ImGui.Button("Use This Loc") then
        self:CommitLocEntry()
    end
    Ui.Tooltip(string.format("Use the typed coordinates as the %s.", objectiveWord))
    ImGui.PopID()
    ImGui.EndDisabled()
end

function Module:RenderLoc(loc)
    if loc.z then
        Ui.NavEnabledLoc(Module.FormatLoc(loc))
    else
        Ui.RenderText(Module.FormatLoc(loc))
    end
end

function Module:RenderNamedLoc(loc)
    if not loc.name then return self:RenderLoc(loc) end
    local coords = Module.FormatLoc(loc)
    if loc.z then
        Ui.NavEnabledLoc(string.format("%s (%s)", loc.name, coords), coords)
    else
        Ui.RenderText(string.format("%s (%s)", loc.name, coords))
    end
end

function Module:RenderWatchCombo()
    local watchScope = Config:GetSetting('WatchScope')
    if watchScope == 1 then return end

    local watchedClasses = Config:GetSetting('WatchClasses') or {}
    local watchSet       = Set.new(watchedClasses)
    local label          = next(watchedClasses) and table.concat(watchedClasses, ", ") or "None"

    ImGui.Text("Watched Classes:")
    if ImGui.BeginCombo("##WatchClasses", label) then
        for _, class in ipairs(Globals.Constants.AllClasses) do
            local selected    = watchSet:contains(class)
            local newSelected = ImGui.Checkbox(class, selected)
            if newSelected ~= selected then
                if newSelected then watchSet:add(class) else watchSet:remove(class) end
                Config:SetSetting('WatchClasses', watchSet:toList())
            end
        end
        ImGui.EndCombo()
    end

    if not next(watchedClasses) then return end

    ImGui.Spacing()
    local items = {}
    if watchScope == 3 then
        for _, peer in ipairs(Comms.GetZonePeers(false)) do
            local data = peer.data
            if watchSet:contains(data.Class) then
                local name        = data.Name or "?"
                local hp          = data.HPs and string.format("%d%%", data.HPs) or "?"
                local mana        = data.Mana and string.format("%d%%", data.Mana) or "-"
                local endu        = data.Endurance and string.format("%d%%", data.Endurance) or "-"
                items[#items + 1] = string.format("[%s] %s  HP:%s  Mana:%s  End:%s", data.Class, name, hp, mana, endu)
            end
        end
        if #items == 0 then items[1] = "No matching peers online" end
    else
        local scopedPeers = self:GroupOrRaidPeers(false)
        local peerNames   = {}
        for _, peer in ipairs(scopedPeers) do
            peerNames[peer.name] = true
            local data = peer.data
            if watchSet:contains(data.Class) then
                local name        = data.Name or "?"
                local hp          = data.HPs and string.format("%d%%", data.HPs) or "?"
                local mana        = data.Mana and string.format("%d%%", data.Mana) or "-"
                local endu        = data.Endurance and string.format("%d%%", data.Endurance) or "-"
                items[#items + 1] = string.format("[%s] %s  HP:%s  Mana:%s  End:%s", data.Class, name, hp, mana, endu)
            end
        end
        local groupCount = mq.TLO.Group.Members() or 0
        for i = 1, groupCount do
            local member = mq.TLO.Group.Member(i)
            if member() and member.ID() > 0 and not peerNames[member.Name() or ""] and watchSet:contains(member.Class.ShortName() or "") then
                local name        = member.CleanName() or "?"
                local hp          = string.format("%d%%", member.PctHPs() or 0)
                local mana        = member.Class.CanCast() and string.format("%d%%", member.PctMana() or 0) or "-"
                local endu        = string.format("%d%%", member.PctEndurance() or 0)
                items[#items + 1] = string.format("[%s] %s  HP:%s  Mana:%s  End:%s", member.Class.ShortName(), name, hp, mana, endu)
            end
        end
        if #items == 0 then items[1] = "No matching group / raid members" end
    end
    local selected = 0
    ImGui.ListBox("##WatchList", selected, items, #items, math.max(2, #items))
end

function Module:Render()
    local controlPadding = Base.Render(self)

    local pressed

    -- dead... whoops
    if mq.TLO.Me.Hovering() then return end

    if self.ModuleLoaded and Globals.SubmodulesLoaded then
        local intent = self:CurrentIntent()
        if ImGui.BeginTable("PullControls", 3, bit32.bor(ImGuiTableFlags.NoBordersInBody), ImVec2(ImGui.GetWindowWidth() - (controlPadding + 20), 0)) then
            if mq.TLO.Navigation.MeshLoaded() then
                ImGui.TableNextColumn()
                if Config:GetSetting('DoPull') then
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionFailColor)
                else
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionPassColor)
                end
                local startGated = not Config:GetSetting('DoPull') and not intent.canStart
                ImGui.BeginDisabled(startGated)
                if ImGui.Button(Config:GetSetting('DoPull') and "Stop Pulls" or "Start Pulls", -1, 25) then
                    if Config:GetSetting('DoPull') then
                        self:ClearObjective()
                        self:StopPuller()
                    else
                        self:StartPuller()
                    end
                end
                ImGui.EndDisabled()
                if startGated and ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                    ImGui.SetTooltip(intent.gapReason or "No objective set - set a target or location below.")
                end
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                if Module.TempSettings.PausePulls then
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionFailColor)
                else
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionPassColor)
                end
                if ImGui.Button(Module.TempSettings.PausePulls and "Unpause Pulls" or "Pause Pulls", -1, 25) then
                    Module.TempSettings.PausePulls = not Module.TempSettings.PausePulls
                end
                ImGui.PopStyleColor()
                Ui.Tooltip("Pausing pulls will keep the pull settings (camp, locs, etc), but it will not attempt to pull any targets until unpaused.")
                ImGui.TableNextColumn()
                if mq.TLO.Target() and Targeting.TargetIsType("NPC") then
                    if ImGui.Button("Pull Target " .. Icons.FA_BULLSEYE, -1, 25) then
                        self:SetPullTarget()
                    end
                end
            else
                ImGui.TableNextColumn()
                ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionFailColor)
                ImGui.Button("No Nav Mesh Loaded!", ImGui.GetWindowWidth() * .3, 25)
                ImGui.PopStyleColor()
                ImGui.TableNextRow()
            end

            ImGui.EndTable()
        end

        local pullModeName = Config:GetSetting('PullMode')
        local isCampMode = pullModeName == "PullToCamp" or pullModeName == "ChainToCamp"

        if #self.TempSettings.ValidPullAbilities > 0 then
            local pullAbility = Config:GetSetting('PullAbility')
            if not self.TempSettings.ValidPullAbilities[pullAbility] then pullAbility = 1 end
            ImGui.SetNextItemWidth(ImGui.GetWindowWidth() * 0.5)
            pullAbility, pressed = ImGui.Combo("Pull Ability", pullAbility, function(id) return self:GetPullAbilityDisplayName(id) end,
                #self.TempSettings.ValidPullAbilities) --, self.TempSettings.ValidPullAbilities, #self.TempSettings.ValidPullAbilities)
            if pressed then
                Config:SetSetting('PullAbility', pullAbility)
            end
        end

        local pullMode = Module.PullModeIndex(Config:GetSetting('PullMode'))
        ImGui.SetNextItemWidth(ImGui.GetWindowWidth() * 0.5)
        pullMode, pressed = ImGui.Combo("Pull Mode", pullMode, self.Constants.PullModeDisplays, #self.Constants.PullModeDisplays)
        if pressed then
            self:SetPullMode(self.Constants.PullModes[pullMode])
        end
        if ImGui.IsItemHovered() then
            Ui.Tooltip("Please refer to the in-game FAQ for a description of Pull Modes.")
        end

        ImGui.Spacing()
        if intent.canStart then
            Ui.RenderText(intent.text)
        else
            Ui.RenderColoredText(Globals.Constants.Colors.ConditionMidColor, intent.text)
        end
        ImGui.Separator()

        if ImGui.CollapsingHeader("Objective Setup", ImGuiTreeNodeFlags.DefaultOpen) then
            if isCampMode or pullModeName == "AreaHunt" or pullModeName == "FightTo" then
                self:RenderObjectiveRow(pullModeName)
            end

            local manageMovement = Config:GetSetting('ManagePeerMovement')
            local newManage = ImGui.Checkbox("Manage movement for my", manageMovement)
            if newManage ~= manageMovement then
                Config:SetSetting('ManagePeerMovement', newManage)
            end
            Ui.Tooltip(Config:GetSettingDefaults('ManagePeerMovement').Tooltip)
            ImGui.SameLine()
            ImGui.BeginDisabled(not manageMovement)
            local scopeOptions = Config:GetSettingDefaults('PeerMovementScope').ComboOptions
            local scopeWidth = 0
            for _, option in ipairs(scopeOptions) do
                local optionWidth = ImGui.CalcTextSize(option)
                scopeWidth = math.max(scopeWidth, optionWidth)
            end
            ImGui.SetNextItemWidth(scopeWidth + ImGui.GetStyle().FramePadding.x * 2 + ImGui.GetFrameHeight())
            local newScope, scopePressed = ImGui.Combo("##PeerMovementScope", Config:GetSetting('PeerMovementScope'), scopeOptions, #scopeOptions)
            if scopePressed then
                Config:SetSetting('PeerMovementScope', newScope)
            end
            Ui.Tooltip(Config:GetSettingDefaults('PeerMovementScope').Tooltip)
            ImGui.EndDisabled()
            ImGui.SameLine()
            ImGui.AlignTextToFramePadding()
            Ui.RenderText("Peers.")
        end

        if ImGui.CollapsingHeader("Pull Locations") then
            self:ProcessDeleteLocations()
            local locked = Config:GetSetting('DoPull')
            ImGui.PushID("##_small_btn_add_loc_here")
            if ImGui.SmallButton("Add Current Loc") then
                self:AddLocationHere()
            end
            ImGui.PopID()
            ImGui.SameLine()
            ImGui.BeginDisabled(not mq.TLO.Target())
            ImGui.PushID("##_small_btn_add_loc_target")
            if ImGui.SmallButton("Add Target's Loc") then
                self:AddLocationFromTarget()
            end
            ImGui.PopID()
            ImGui.EndDisabled()
            ImGui.SameLine()
            ImGui.PushID("##_small_btn_load_db")
            if ImGui.SmallButton("Import from Mercs Peer") then
                self:LoadDbImportSources()
            end
            ImGui.PopID()
            Ui.Tooltip("Pick pull locations saved by your other characters.")
            ImGui.SameLine()
            ImGui.PushID("##_small_btn_load_mypaths")
            if ImGui.SmallButton("Import from MyPaths") then
                self:LoadMyPathsFile()
            end
            ImGui.PopID()
            Ui.Tooltip("Pick pull locations from points recorded in MyPaths.")

            if self.TempSettings.MyPathsData then
                ImGui.AlignTextToFramePadding()
                Ui.RenderText("Import points from")
                ImGui.SameLine()
                local zoneWidth = 0
                for _, zoneName in ipairs(self.TempSettings.MyPathsZones) do
                    local nameWidth = ImGui.CalcTextSize(zoneName)
                    zoneWidth = math.max(zoneWidth, nameWidth)
                end
                ImGui.SetNextItemWidth(zoneWidth + ImGui.GetStyle().FramePadding.x * 2 + ImGui.GetFrameHeight())
                local newZone, zonePressed = ImGui.Combo("##MyPathsZone", self.TempSettings.MyPathsZoneIndex, self.TempSettings.MyPathsZones, #self.TempSettings.MyPathsZones)
                if zonePressed and newZone ~= self.TempSettings.MyPathsZoneIndex then
                    self:SelectMyPathsZone(newZone)
                end
                ImGui.SameLine()
                if #self.TempSettings.MyPathsPathNames == 0 then
                    ImGui.AlignTextToFramePadding()
                    Ui.RenderText("(no paths in this zone)")
                else
                    local pathWidth = 0
                    for _, pathName in ipairs(self.TempSettings.MyPathsPathNames) do
                        local nameWidth = ImGui.CalcTextSize(pathName)
                        pathWidth = math.max(pathWidth, nameWidth)
                    end
                    ImGui.SetNextItemWidth(pathWidth + ImGui.GetStyle().FramePadding.x * 2 + ImGui.GetFrameHeight())
                    local newPath, pathPressed = ImGui.Combo("##MyPathsPath", self.TempSettings.MyPathsPathIndex, self.TempSettings.MyPathsPathNames,
                        #self.TempSettings.MyPathsPathNames)
                    if pathPressed and newPath ~= self.TempSettings.MyPathsPathIndex then
                        self:SelectMyPathsPath(newPath)
                    end
                end
                ImGui.SameLine()
                ImGui.PushID("##_small_btn_mypaths_close")
                if ImGui.SmallButton(Icons.MD_CLOSE) then
                    self:ClearMyPathsPicker()
                end
                ImGui.PopID()
                Ui.Tooltip("Close the MyPaths import picker.")

                if #self.TempSettings.MyPathsPoints > 0 then
                    ImGui.PushID("##_small_btn_mypaths_all")
                    if ImGui.SmallButton("Select All") then
                        for index = 1, #self.TempSettings.MyPathsPoints do
                            self.TempSettings.MyPathsChecked[index] = true
                        end
                    end
                    ImGui.PopID()
                    ImGui.SameLine()
                    ImGui.PushID("##_small_btn_mypaths_none")
                    if ImGui.SmallButton("Select None") then
                        self.TempSettings.MyPathsChecked = {}
                    end
                    ImGui.PopID()
                    local pointsHeight = ImGui.GetFrameHeightWithSpacing() * math.min(#self.TempSettings.MyPathsPoints, 10) + ImGui.GetStyle().ItemSpacing.y
                    if ImGui.BeginChild("MyPathsPoints", ImVec2(0, pointsHeight), ImGuiChildFlags.None, ImGuiWindowFlags.None) then
                        local showDistance = (self.TempSettings.MyPathsZones[self.TempSettings.MyPathsZoneIndex] or ""):lower() == (mq.TLO.Zone.ShortName() or ""):lower()
                        local myX, myY = mq.TLO.Me.X(), mq.TLO.Me.Y()
                        for index, point in ipairs(self.TempSettings.MyPathsPoints) do
                            ImGui.PushID("##_mypaths_point_" .. tostring(index))
                            self.TempSettings.MyPathsChecked[index] = ImGui.Checkbox(Module.FormatLoc(point),
                                self.TempSettings.MyPathsChecked[index] or false) or nil
                            if showDistance then
                                ImGui.SameLine()
                                Ui.RenderText(string.format("(%.0f away)", Math.GetDistance(myX, myY, point.x, point.y)))
                            end
                            ImGui.PopID()
                        end
                    end
                    ImGui.EndChild()
                    ImGui.PushID("##_small_btn_mypaths_add")
                    if ImGui.SmallButton("Add Selected") then
                        self:ImportMyPathsSelection()
                    end
                    ImGui.PopID()
                    Ui.Tooltip("Add the checked points to this path's zone as pull locations.")
                end
            end

            if self.TempSettings.DbImportSources then
                ImGui.AlignTextToFramePadding()
                Ui.RenderText("Import locations from")
                ImGui.SameLine()
                local sourceWidth = 0
                for _, label in ipairs(self.TempSettings.DbImportSourceLabels) do
                    sourceWidth = math.max(sourceWidth, ImGui.CalcTextSize(label))
                end
                ImGui.SetNextItemWidth(sourceWidth + ImGui.GetStyle().FramePadding.x * 2 + ImGui.GetFrameHeight())
                local newSource, sourcePressed = ImGui.Combo("##DbImportSource", self.TempSettings.DbImportSourceIndex, self.TempSettings.DbImportSourceLabels,
                    #self.TempSettings.DbImportSourceLabels)
                if sourcePressed and newSource ~= self.TempSettings.DbImportSourceIndex then
                    self:SelectDbImportSource(newSource)
                end
                ImGui.SameLine()
                local zoneWidth = 0
                for _, zoneName in ipairs(self.TempSettings.DbImportZones) do
                    zoneWidth = math.max(zoneWidth, ImGui.CalcTextSize(zoneName))
                end
                ImGui.SetNextItemWidth(zoneWidth + ImGui.GetStyle().FramePadding.x * 2 + ImGui.GetFrameHeight())
                local newZone, zonePressed = ImGui.Combo("##DbImportZone", self.TempSettings.DbImportZoneIndex, self.TempSettings.DbImportZones,
                    #self.TempSettings.DbImportZones)
                if zonePressed and newZone ~= self.TempSettings.DbImportZoneIndex then
                    self:SelectDbImportZone(newZone)
                end
                ImGui.SameLine()
                ImGui.PushID("##_small_btn_db_import_close")
                if ImGui.SmallButton(Icons.MD_CLOSE) then
                    self:ClearDbImportPicker()
                end
                ImGui.PopID()
                Ui.Tooltip("Close the database import picker.")

                if #self.TempSettings.DbImportPoints > 0 then
                    ImGui.PushID("##_small_btn_db_import_all")
                    if ImGui.SmallButton("Select All") then
                        for index = 1, #self.TempSettings.DbImportPoints do
                            self.TempSettings.DbImportChecked[index] = true
                        end
                    end
                    ImGui.PopID()
                    ImGui.SameLine()
                    ImGui.PushID("##_small_btn_db_import_none")
                    if ImGui.SmallButton("Select None") then
                        self.TempSettings.DbImportChecked = {}
                    end
                    ImGui.PopID()
                    local pointsHeight = ImGui.GetFrameHeightWithSpacing() * math.min(#self.TempSettings.DbImportPoints, 10) + ImGui.GetStyle().ItemSpacing.y
                    if ImGui.BeginChild("DbImportPoints", ImVec2(0, pointsHeight), ImGuiChildFlags.None, ImGuiWindowFlags.None) then
                        local showDistance = (self.TempSettings.DbImportZones[self.TempSettings.DbImportZoneIndex] or "") == Module.ZoneKeyLower()
                        local myX, myY = mq.TLO.Me.X(), mq.TLO.Me.Y()
                        for index, point in ipairs(self.TempSettings.DbImportPoints) do
                            ImGui.PushID("##_db_import_point_" .. tostring(index))
                            self.TempSettings.DbImportChecked[index] = ImGui.Checkbox(string.format("%s (%s)", point.name, Module.FormatLoc(point)),
                                self.TempSettings.DbImportChecked[index] or false) or nil
                            if showDistance then
                                ImGui.SameLine()
                                Ui.RenderText(string.format("(%.0f away)", Math.GetDistance(myX, myY, point.x, point.y)))
                            end
                            ImGui.PopID()
                        end
                    end
                    ImGui.EndChild()
                    ImGui.PushID("##_small_btn_db_import_add")
                    if ImGui.SmallButton("Add Selected") then
                        self:ImportDbSelection()
                    end
                    ImGui.PopID()
                    Ui.Tooltip("Add the checked locations to that zone's pull location list.")
                end
            end

            local zoneLocations = self:GetZoneLocations()
            local style = ImGui.GetStyle()
            local setAsLabels = { Icons.FA_FREE_CODE_CAMP, Icons.FA_BINOCULARS, Icons.MD_FORWARD, }
            local setAsWidth = style.ItemSpacing.x * (#setAsLabels - 1) + style.CellPadding.x * 2
            for _, label in ipairs(setAsLabels) do
                setAsWidth = setAsWidth + ImGui.CalcTextSize(label) + style.FramePadding.x * 2
            end
            local circuitLabels = { Icons.FA_FLAG_CHECKERED, Icons.FA_CHEVRON_UP, Icons.FA_CHEVRON_DOWN, }
            local circuitWidth = 26.0 + style.ItemSpacing.x * #circuitLabels + style.CellPadding.x * 2
            for _, label in ipairs(circuitLabels) do
                circuitWidth = circuitWidth + ImGui.CalcTextSize(label) + style.FramePadding.x * 2
            end
            circuitWidth = math.max(circuitWidth, ImGui.CalcTextSize('Circuit Controls') + style.CellPadding.x * 2)
            setAsWidth = math.max(setAsWidth, ImGui.CalcTextSize('Set Objective') + style.CellPadding.x * 2)
            local trashWidth = ImGui.CalcTextSize(Icons.FA_TRASH) + style.FramePadding.x * 2 + style.CellPadding.x * 2
            local childHeight = ImGui.GetTextLineHeightWithSpacing() + ImGui.GetFrameHeightWithSpacing() * math.min(#zoneLocations, 10) + style.ItemSpacing.y
            if ImGui.BeginChild("PullLocationsChild", ImVec2(0, childHeight), ImGuiChildFlags.None, ImGuiWindowFlags.None) then
                if ImGui.BeginTable("PullLocations", 5, bit32.bor(ImGuiTableFlags.Borders)) then
                    ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 150.0)
                    ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthFixed), 160.0)
                    ImGui.TableSetupColumn('Set Objective', (ImGuiTableColumnFlags.WidthFixed), setAsWidth)
                    ImGui.TableSetupColumn('Circuit Controls', (ImGuiTableColumnFlags.WidthFixed), circuitWidth)
                    ImGui.TableSetupColumn('', (ImGuiTableColumnFlags.WidthFixed), trashWidth)
                    ImGui.TableHeadersRow()

                    local currentWpId = self:IsPullMode("CircuitHunt") and self:GetCurrentWpId() or 0
                    local enabledIndex = 0
                    for idx, entry in ipairs(zoneLocations) do
                        if entry.enabled then enabledIndex = enabledIndex + 1 end
                        ImGui.PushID("##_pull_loc_row_" .. tostring(idx))
                        ImGui.TableNextColumn()
                        ImGui.BeginDisabled(locked)
                        ImGui.SetNextItemWidth(-1)
                        local editedName = ImGui.InputText("##_input_loc_name", self.TempSettings.LocationNameEdits[idx] or entry.name)
                        if ImGui.IsItemDeactivatedAfterEdit() then
                            self.TempSettings.LocationNameEdits[idx] = nil
                            if editedName ~= entry.name and editedName ~= "" then
                                self:RenameLocation(idx, editedName)
                            end
                        elseif ImGui.IsItemActive() then
                            self.TempSettings.LocationNameEdits[idx] = editedName
                        else
                            self.TempSettings.LocationNameEdits[idx] = nil
                        end
                        ImGui.EndDisabled()
                        ImGui.TableNextColumn()
                        self:RenderLoc(entry)
                        ImGui.TableNextColumn()
                        ImGui.BeginDisabled(locked)
                        if ImGui.SmallButton(Icons.FA_FREE_CODE_CAMP) then
                            local campMode = Module.Constants.PullModePolicies[Config:GetSetting('PullMode')].family == 'camp' and Config:GetSetting('PullMode') or "PullToCamp"
                            self:SetPullMode(campMode)
                            self:FillLocEntry({ y = entry.y, x = entry.x, z = entry.z, })
                            self.TempSettings.LocEntryMode = campMode
                        end
                        Ui.Tooltip("Switch to a camp mode with this location as the travel destination.")
                        ImGui.SameLine()
                        if ImGui.SmallButton(Icons.FA_BINOCULARS) then
                            self:SetPullMode("AreaHunt")
                            self:SetHuntOrigin({ y = entry.y, x = entry.x, z = entry.z, name = entry.name, })
                        end
                        Ui.Tooltip("Switch to Area Hunt with this location as the hunt origin.")
                        ImGui.SameLine()
                        if ImGui.SmallButton(Icons.MD_FORWARD) then
                            self:SetPullMode("FightTo")
                            self:SetFightToLoc({ y = entry.y, x = entry.x, z = entry.z, name = entry.name, })
                        end
                        Ui.Tooltip("Switch to Fight To with this location as the destination.")
                        ImGui.EndDisabled()
                        ImGui.TableNextColumn()
                        local _, toggled = Ui.RenderOptionToggle("pull_loc_tggl_" .. tostring(idx), "", entry.enabled)
                        if toggled then
                            self:ToggleLocation(idx)
                        end
                        ImGui.SameLine()
                        ImGui.BeginDisabled(not entry.enabled)
                        local isCurrentStop = entry.enabled and enabledIndex == currentWpId
                        if isCurrentStop then ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Green) end
                        if ImGui.SmallButton(Icons.FA_FLAG_CHECKERED) then
                            Core.DoCmd(string.format("/rgl pullwp %d", enabledIndex))
                        end
                        if isCurrentStop then ImGui.PopStyleColor() end
                        Ui.Tooltip(isCurrentStop and "The circuit's current waypoint." or "Set as the current waypoint for the circuit.")
                        ImGui.EndDisabled()
                        ImGui.SameLine()
                        if idx == 1 then
                            ImGui.InvisibleButton(Icons.FA_CHEVRON_UP, ImVec2(ImGui.CalcTextSize(Icons.FA_CHEVRON_UP) + style.FramePadding.x * 2, 1))
                        else
                            if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then
                                self:MoveLocationUp(idx)
                            end
                        end
                        ImGui.SameLine()
                        if idx == #zoneLocations then
                            ImGui.InvisibleButton(Icons.FA_CHEVRON_DOWN, ImVec2(ImGui.CalcTextSize(Icons.FA_CHEVRON_DOWN) + style.FramePadding.x * 2, 1))
                        else
                            if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then
                                self:MoveLocationDown(idx)
                            end
                        end
                        ImGui.TableNextColumn()
                        if ImGui.SmallButton(Icons.FA_TRASH) then
                            self:DeleteLocation(idx)
                        end
                        Ui.Tooltip("Delete Location")
                        ImGui.PopID()
                    end

                    ImGui.EndTable()
                end
            end
            ImGui.EndChild()
        end

        local nextPull = Config:GetSetting('PullDelay') - (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded)
        if nextPull < 0 then nextPull = 0 end
        if ImGui.BeginTable("PullState", 2, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableNextColumn()
            Ui.RenderText("Pull State")
            ImGui.TableNextColumn()
            local stateData = Globals.PauseMain and Module.Constants.PullStateDisplayStrings['MERCS_PAUSED'] or
                Module.Constants.PullStateDisplayStrings[Module.Constants.PullStatesIDToName[self.TempSettings.PullState]]
            local stateColor = stateData and Globals.Constants.Colors[stateData.Color] or ImGui.GetColorU32(1.0, 1.0, 1.0, 1.0)
            ImGui.PushStyleColor(ImGuiCol.Text, stateColor)
            if not stateData then
                Ui.RenderText("Invalid State Data... This should auto resolve.")
            else
                Ui.RenderText(stateData.Display .. " " .. stateData.Text)
            end
            ImGui.PopStyleColor()
            ImGui.TableNextColumn()
            Ui.RenderText("Pull State Reason")
            ImGui.TableNextColumn()
            ImGui.PushStyleColor(ImGuiCol.Text, stateColor)
            Ui.RenderText(self.TempSettings.PullStateReason:len() > 0 and self.TempSettings.PullStateReason or "N/A")
            ImGui.PopStyleColor()
            ImGui.TableNextColumn()
            Ui.RenderText("Pull Delay")
            ImGui.TableNextColumn()
            Ui.RenderText(Strings.FormatTime(Config:GetSetting('PullDelay')))
            ImGui.TableNextColumn()
            Ui.RenderText("Last Pull Attempt")
            ImGui.TableNextColumn()
            Ui.RenderText(Strings.FormatTime((Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded)))
            ImGui.TableNextColumn()
            Ui.RenderText("Next Pull Attempt")
            ImGui.TableNextColumn()
            Ui.RenderText(Strings.FormatTime(nextPull))
            ImGui.TableNextColumn()
            Ui.RenderText("Pull Ability Range")
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(self:GetPullAbilityRange()))
            if self.TempSettings.Attempt and (self.TempSettings.Attempt.targetId or 0) > 0 then
                ImGui.TableNextColumn()
                Ui.RenderText("Pull ID")
                ImGui.TableNextColumn()
                Ui.RenderText(tostring(self.TempSettings.Attempt.targetId))
            end
            if #self.TempSettings.PullTargets > 0 then
                ImGui.TableNextColumn()
                Ui.RenderText("Pull Target Count")
                ImGui.TableNextColumn()
                Ui.RenderText(tostring(#self.TempSettings.PullTargets))
            end
            if not self:IsPullMode("RoamingHunt") then
                ImGui.TableNextColumn()
                Ui.RenderText("Objective")
                ImGui.TableNextColumn()
                if self:IsPullMode("AreaHunt") then
                    local origin = self.TempSettings.HuntOrigin
                    if origin then
                        Ui.RenderText("Traveling to:")
                        ImGui.SameLine()
                        self:RenderNamedLoc(origin)
                    else
                        local anchor = self.TempSettings.HuntAnchor
                        if anchor then
                            self:RenderNamedLoc(anchor)
                        else
                            Ui.RenderText("-")
                        end
                    end
                elseif self:IsPullMode("FightTo") then
                    local objective = self.TempSettings.FightTo
                    if not objective then
                        Ui.RenderText("None")
                    elseif objective.id then
                        local objectiveSpawn = mq.TLO.Spawn(objective.id)
                        Ui.RenderText(string.format("%s (%d)", objectiveSpawn.CleanName() or objective.name or "Unknown", objective.id))
                        ImGui.SameLine()
                        Ui.NavEnabledLoc(objectiveSpawn.LocYXZ() or "0,0,0")
                    else
                        self:RenderNamedLoc(objective)
                    end
                elseif self:IsPullMode("CircuitHunt") then
                    local wpId = self:GetCurrentWpId()
                    if wpId == 0 then
                        Ui.RenderText("<None>")
                    else
                        local wpData = self:GetWPById(wpId)
                        local display = string.format("%s (%d of %d)", wpData.name, wpId, #self:GetEnabledLocations())
                        if wpData.z then
                            Ui.NavEnabledLoc(display, Module.FormatLoc(wpData))
                        else
                            Ui.RenderText(display)
                        end
                    end
                else
                    local campData = Modules:ExecModule("Movement", "GetCampData")
                    if campData.returnToCamp then
                        self:RenderLoc({ y = campData.campSettings.AutoCampY, x = campData.campSettings.AutoCampX, z = campData.campSettings.AutoCampZ, })
                    elseif self.TempSettings.CampTravelLoc then
                        Ui.RenderText("Traveling to:")
                        ImGui.SameLine()
                        self:RenderNamedLoc(self.TempSettings.CampTravelLoc)
                    else
                        Ui.RenderText("-")
                    end
                end
            end
            if self:IsPullMode("ChainToCamp") then
                ImGui.TableNextColumn()
                Ui.RenderText("Chain Progress")
                ImGui.TableNextColumn()
                Ui.RenderText(string.format("%d / %d", Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount')))
            end
            if Config:GetSetting('PullBuffCount') > 0 then
                ImGui.TableNextColumn()
                Ui.RenderText("Buff Count")
                ImGui.TableNextColumn()
                local hbData = Comms.GetPeerHeartbeat(Comms.GetPeerName()).Data
                Ui.RenderText("%s", hbData and hbData.BuffCount or 0)
            end
            self:RenderMoveAbilities()
            ImGui.EndTable()
        end

        ImGui.NewLine()
        ImGui.Separator()
        local useShared = Config:GetSetting('UseSharedPullLists')
        local newUseShared = ImGui.Checkbox("Use Shared Pull Lists", useShared)
        Ui.Tooltip("On: shares pull lists with all RGMercs peers on this machine.\nOff: this character uses its own lists.")
        if newUseShared ~= useShared then
            Config:SetSetting('UseSharedPullLists', newUseShared)
        end
        self:RenderMobList("Allow List", "PullAllowList")
        self:RenderMobList("Deny List", "PullDenyList")
        Ui.RenderText("Note: Allow List will supersede Deny List")
        ImGui.NewLine()
        ImGui.Separator()

        if Config:GetSetting('DoPull') then
            if ImGui.CollapsingHeader("Pull Targets") then
                self:RenderPullTargets()
            end
            if ImGui.CollapsingHeader("Ignored Targets") then
                self:RenderIgnoreTargets()
            end
        end
    end
end

function Module:RenderMoveAbilities()
    for _, entry in ipairs(self:GetMoveAbilities()) do
        ImGui.TableNextColumn()
        Ui.RenderText("Move Buff")
        ImGui.TableNextColumn()
        local entryType = (entry.type or ""):lower()
        local resolved = Core.GetResolvedActionMapItem(entry.name) or entry.name
        if entryType == "aa" then
            local aaName = type(resolved) == "string" and resolved or entry.name
            if mq.TLO.Me.AltAbility(aaName)() ~= nil then
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
        elseif entryType == "item" then
            local itemName = type(resolved) == "string" and resolved or entry.name
            local item = mq.TLO.FindItem("=" .. itemName)
            if item() and item.Clicky() then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.LightOrange)
                ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Globals.Constants.Colors.NearBlack)
                local _, clicked = ImGui.Selectable(itemName)
                local clickySpell = item.Clicky.Spell
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
        else
            local songSpell = type(resolved) == "string" and mq.TLO.Spell(resolved) or resolved
            if songSpell and songSpell() then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Purple)
                ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Globals.Constants.Colors.NearBlack)
                local rankSpell = songSpell.RankName
                local _, clicked = ImGui.Selectable(rankSpell() or "Unknown")
                if clicked then
                    rankSpell.Inspect()
                end
                ImGui.PopStyleColor(2)
                Ui.Tooltip(string.format("Song: %s (click to inspect)", rankSpell() or "Unknown"))
            else
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Red)
                Ui.RenderText("No Song Detected")
                ImGui.PopStyleColor()
            end
        end
    end
end

-- Mob Lists
---@param baseName string # "PullAllowList" or "PullDenyList"
---@return string
function Module:ActivePullList(baseName)
    return Config:GetSetting('UseSharedPullLists') and (baseName .. "Shared") or baseName
end

---@param list string
---@param mobName string
function Module:AddMobToList(list, mobName)
    Config:ZoneListAdd(mobName, self:ActivePullList(list))
end

---@param list string
---@param arg1 string|number
function Module:DeleteMobFromList(list, arg1)
    Config:ZoneListDelete(arg1, self:ActivePullList(list))
end

function Module:FlagPullListUpdated()
    if Config:GetSetting('DoPull') then
        -- only flag a rescan while actively pulling
        self.TempSettings.PullListUpdated = true
    end
end

function Module.CompilePullListSet(personal, shared, useShared)
    local set = {}
    local hasEntries = false
    for _, name in ipairs(useShared and shared or personal) do
        set[Strings.TrimSpaces(name):lower()] = true
        hasEntries = true
    end
    return set, hasEntries
end

function Module:RefreshPullListSets()
    local useShared = Config:GetSetting('UseSharedPullLists')
    self.TempSettings.PullAllowSet, self.TempSettings.HavePullAllowEntries = Module.CompilePullListSet(
        Config:GetZoneList('PullAllowList'), Config:GetZoneList('PullAllowListShared'), useShared)
    self.TempSettings.PullDenySet, self.TempSettings.HavePullDenyEntries = Module.CompilePullListSet(
        Config:GetZoneList('PullDenyList'), Config:GetZoneList('PullDenyListShared'), useShared)
end

function Module:GetPullListSets()
    self:RefreshPullListSets()
    return self.TempSettings.PullAllowSet, self.TempSettings.PullDenySet
end

function Module:ClearIgnoreList()
    self.TempSettings.PullIgnoreTargets = {}
end

function Module:ValidateIgnoreList()
    for i = #self.TempSettings.PullIgnoreTargets, 1, -1 do
        local spawn = self.TempSettings.PullIgnoreTargets[i]
        if spawn.ID() == 0 or spawn.Dead() then
            Logger.log_debug("PULL: Cleaning up ignore list, it seems %s is no longer present.", spawn)
            table.remove(self.TempSettings.PullIgnoreTargets, i)
        end
    end
end

-- Locations Library
function Module.ZoneKeyLower()
    return (mq.TLO.Zone.ShortName() or ""):lower()
end

function Module.LocationNameExists(zoneLocations, name)
    for _, entry in ipairs(zoneLocations) do
        if entry.name == name then return true end
    end
    return false
end

function Module.SynthesizeLocationName(zoneLocations, baseName)
    baseName = baseName or string.format("Location %d", #zoneLocations + 1)
    local name = baseName
    local suffix = 2
    while Module.LocationNameExists(zoneLocations, name) do
        name = string.format("%s (%d)", baseName, suffix)
        suffix = suffix + 1
    end
    return name
end

function Module.AppendLocation(zoneLocations, loc, baseName)
    local entry = { name = Module.SynthesizeLocationName(zoneLocations, baseName), y = loc.y, x = loc.x, z = loc.z, enabled = true, }
    table.insert(zoneLocations, entry)
    return entry
end

function Module:GetZoneLocations()
    return (Config:GetSetting('PullLocations') or {})[Module.ZoneKeyLower()] or {}
end

function Module:GetEnabledLocations()
    local enabledLocations = {}
    for _, entry in ipairs(self:GetZoneLocations()) do
        if entry.enabled then table.insert(enabledLocations, entry) end
    end
    return enabledLocations
end

function Module:AddLocationAt(loc)
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneKey = Module.ZoneKeyLower()
    pullLocations[zoneKey] = pullLocations[zoneKey] or {}
    local entry = Module.AppendLocation(pullLocations[zoneKey], loc)
    Config:SetSetting('PullLocations', pullLocations)
    Logger.log_info("\axNew pull location \at%s\ax created at \ag%0.2f, %0.2f, %0.2f", entry.name, entry.y, entry.x, entry.z)
end

function Module:AddLocationHere()
    self:AddLocationAt({ y = mq.TLO.Me.Y(), x = mq.TLO.Me.X(), z = mq.TLO.Me.Z(), })
end

function Module:AddLocationFromTarget()
    if not mq.TLO.Target() then
        Logger.log_error("Cannot add a pull location - no valid target exists!")
        return
    end
    self:AddLocationAt({ y = mq.TLO.Target.Y(), x = mq.TLO.Target.X(), z = mq.TLO.Target.Z(), })
end

function Module:RenameLocation(idx, name)
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneLocations = pullLocations[Module.ZoneKeyLower()] or {}
    local entry = zoneLocations[idx]
    if not entry or entry.name == name then return end
    if Module.LocationNameExists(zoneLocations, name) then
        Logger.log_error("\arA pull location named \at%s\ar already exists in this zone!", name)
        return
    end
    entry.name = name
    Config:SetSetting('PullLocations', pullLocations)
end

function Module:ToggleLocation(idx)
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local entry = (pullLocations[Module.ZoneKeyLower()] or {})[idx]
    if not entry then return end
    entry.enabled = not entry.enabled
    Config:SetSetting('PullLocations', pullLocations)
end

function Module:MoveLocationUp(idx)
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneLocations = pullLocations[Module.ZoneKeyLower()] or {}
    if idx < 2 or idx > #zoneLocations then return end
    zoneLocations[idx - 1], zoneLocations[idx] = zoneLocations[idx], zoneLocations[idx - 1]
    Config:SetSetting('PullLocations', pullLocations)
end

function Module:MoveLocationDown(idx)
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneLocations = pullLocations[Module.ZoneKeyLower()] or {}
    if idx < 1 or idx + 1 > #zoneLocations then return end
    zoneLocations[idx + 1], zoneLocations[idx] = zoneLocations[idx], zoneLocations[idx + 1]
    Config:SetSetting('PullLocations', pullLocations)
end

function Module:DeleteLocation(idx)
    local entry = self:GetZoneLocations()[idx]
    if entry then self.TempSettings.LocationsToDelete[entry] = true end
end

function Module:ProcessDeleteLocations()
    if next(self.TempSettings.LocationsToDelete) == nil then return end
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneLocations = pullLocations[Module.ZoneKeyLower()] or {}
    for idx = #zoneLocations, 1, -1 do
        if self.TempSettings.LocationsToDelete[zoneLocations[idx]] then
            Logger.log_info("\axPull location \at%s\ax - \arDeleted!\ax", zoneLocations[idx].name)
            table.remove(zoneLocations, idx)
        end
    end
    Config:SetSetting('PullLocations', pullLocations)
    self.TempSettings.LocationsToDelete = {}
end

function Module:ResolveLocationEntry(argText)
    local enabledLocations = self:GetEnabledLocations()
    if argText:match("^%d+$") then
        local index = tonumber(argText)
        if index >= 1 and index <= #enabledLocations then return enabledLocations[index] end
    end
    for _, entry in ipairs(self:GetZoneLocations()) do
        if entry.name:lower() == argText:lower() then return entry end
    end
    Logger.log_error("'%s' does not match a pull location - use a name or an index between 1 and %d (enabled locations).", argText, #enabledLocations)
    return nil
end

function Module:ResolveZoneLocationIndex(argText)
    local zoneLocations = self:GetZoneLocations()
    if argText:match("^%d+$") then
        local index = tonumber(argText)
        if index >= 1 and index <= #zoneLocations then return index end
    end
    for index, entry in ipairs(zoneLocations) do
        if entry.name:lower() == argText:lower() then return index end
    end
    Logger.log_error("'%s' does not match a pull location - use a name or an index between 1 and %d.", argText, #zoneLocations)
    return nil
end

-- Circuit Waypoints
---@return integer
function Module:GetCurrentWpId()
    local enabledLocations = self:GetEnabledLocations()
    if #enabledLocations == 0 then return 0 end
    for index, entry in ipairs(enabledLocations) do
        if entry.name == self.TempSettings.CurrentWPName then
            self.TempSettings.CurrentWPIndex = index
            return index
        end
    end
    local index = math.min(self.TempSettings.CurrentWPIndex, #enabledLocations)
    self.TempSettings.CurrentWPName = enabledLocations[index].name
    self.TempSettings.CurrentWPIndex = index
    return index
end

---@param id number
---@return table
function Module:GetWPById(id)
    return self:GetEnabledLocations()[id] or { x = 0, y = 0, z = 0, }
end

function Module:IncrementWpId()
    local enabledLocations = self:GetEnabledLocations()
    if #enabledLocations == 0 then return end

    local index = self:GetCurrentWpId() + 1
    if index > #enabledLocations then index = 1 end
    self.TempSettings.CurrentWPName = enabledLocations[index].name
    self.TempSettings.CurrentWPIndex = index
    Logger.log_verbose("Pull: Advancing circuit to %s (%d of %d)", enabledLocations[index].name, index, #enabledLocations)
end

-- MyPaths Import
function Module:ClearMyPathsPicker()
    self.TempSettings.MyPathsData = nil
    self.TempSettings.MyPathsZones = {}
    self.TempSettings.MyPathsZoneIndex = 1
    self.TempSettings.MyPathsPathNames = {}
    self.TempSettings.MyPathsPathIndex = 1
    self.TempSettings.MyPathsPoints = {}
    self.TempSettings.MyPathsChecked = {}
end

function Module:LoadMyPathsFile()
    self:ClearMyPathsPicker()
    local pathsLoader = loadfile(mq.configDir .. '/MyUI/MyPaths/MyPaths_Paths.lua')
    if not pathsLoader then
        Logger.log_info("No MyPaths file found to import from.")
        return
    end
    local ok, paths = pcall(pathsLoader)
    if not ok or type(paths) ~= 'table' then
        Logger.log_info("The MyPaths file could not be read.")
        return
    end
    local zones = {}
    for zoneName, zonePaths in pairs(paths) do
        if type(zoneName) == 'string' and type(zonePaths) == 'table' then
            table.insert(zones, zoneName)
        end
    end
    table.sort(zones)
    if #zones == 0 then
        Logger.log_info("The MyPaths file does not contain any paths.")
        return
    end
    self.TempSettings.MyPathsData = paths
    self.TempSettings.MyPathsZones = zones
    local zoneIndex = 1
    for index, zoneName in ipairs(zones) do
        if zoneName:lower() == Module.ZoneKeyLower() then
            zoneIndex = index
            break
        end
    end
    self:SelectMyPathsZone(zoneIndex)
end

function Module:SelectMyPathsZone(index)
    self.TempSettings.MyPathsZoneIndex = index
    self.TempSettings.MyPathsPathNames = {}
    for pathName, steps in pairs(self.TempSettings.MyPathsData[self.TempSettings.MyPathsZones[index]] or {}) do
        if type(pathName) == 'string' and type(steps) == 'table' then
            table.insert(self.TempSettings.MyPathsPathNames, pathName)
        end
    end
    table.sort(self.TempSettings.MyPathsPathNames)
    self:SelectMyPathsPath(1)
end

function Module:SelectMyPathsPath(index)
    self.TempSettings.MyPathsPathIndex = index
    self.TempSettings.MyPathsPoints = {}
    self.TempSettings.MyPathsChecked = {}
    local pathName = self.TempSettings.MyPathsPathNames[index]
    if not pathName then return end
    for stepIndex, stepData in ipairs(self.TempSettings.MyPathsData[self.TempSettings.MyPathsZones[self.TempSettings.MyPathsZoneIndex]][pathName]) do
        local locText = type(stepData) == 'table' and tostring(stepData.loc or "") or ""
        local yText, xText, zText = locText:match("^([^,]*),([^,]*),([^,]*)$")
        local y, x, z = tonumber(yText), tonumber(xText), tonumber(zText)
        if y and x and z then
            table.insert(self.TempSettings.MyPathsPoints, { y = y, x = x, z = z, })
        else
            Logger.log_info("Skipping MyPaths point %d in %s - could not parse its loc (%s).", stepIndex, pathName, locText)
        end
    end
end

function Module:ImportMyPathsSelection()
    local pathName = self.TempSettings.MyPathsPathNames[self.TempSettings.MyPathsPathIndex]
    if not pathName then return end
    if not next(self.TempSettings.MyPathsChecked) then
        Logger.log_info("No MyPaths points are checked - nothing to import.")
        return
    end
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneKey = (self.TempSettings.MyPathsZones[self.TempSettings.MyPathsZoneIndex] or ""):lower()
    pullLocations[zoneKey] = pullLocations[zoneKey] or {}
    local added = 0
    for index, point in ipairs(self.TempSettings.MyPathsPoints) do
        if self.TempSettings.MyPathsChecked[index] then
            added = added + 1
            Module.AppendLocation(pullLocations[zoneKey], point, string.format("MyPaths %s %d", pathName, added))
        end
    end
    Config:SetSetting('PullLocations', pullLocations)
    self.TempSettings.MyPathsChecked = {}
    Logger.log_info("\axImported \at%d\ax MyPaths point%s into the \at%s\ax pull location list.", added, added == 1 and "" or "s", zoneKey)
end

-- Database Import
function Module:ClearDbImportPicker()
    self.TempSettings.DbImportSources = nil
    self.TempSettings.DbImportSourceLabels = {}
    self.TempSettings.DbImportSourceIndex = 1
    self.TempSettings.DbImportZones = {}
    self.TempSettings.DbImportZoneIndex = 1
    self.TempSettings.DbImportPoints = {}
    self.TempSettings.DbImportChecked = {}
end

function Module:LoadDbImportSources()
    self:ClearDbImportPicker()
    local sources = {}
    local sourceLabels = {}
    local myServer = mq.TLO.EverQuest.Server() or ""
    for _, character in ipairs(Config.Db:getCharacters()) do
        for _, class in ipairs(Config.Db:getClassesForCharacter(character.server_name, character.name)) do
            if not Comms.IsLocalCurrent(character.name, character.server_name, class) then
                local locations = (Config.Db:getAll(character.server_name, character.name, class, "Pull") or {})['PullLocations']
                local zones = {}
                for zoneKey, zoneLocations in pairs(locations or {}) do
                    if #zoneLocations > 0 then table.insert(zones, zoneKey) end
                end
                if #zones > 0 then
                    table.sort(zones)
                    local label = character.server_name == myServer and string.format("%s (%s)", character.name, class)
                        or string.format("%s (%s, %s)", character.name, character.server_name, class)
                    table.insert(sources, { label = label, locations = locations, zones = zones, })
                    table.insert(sourceLabels, label)
                end
            end
        end
    end
    if #sources == 0 then
        Logger.log_info("No other characters with pull locations were found in the database.")
        return
    end
    self.TempSettings.DbImportSources = sources
    self.TempSettings.DbImportSourceLabels = sourceLabels
    self:SelectDbImportSource(1)
end

function Module:SelectDbImportSource(index)
    self.TempSettings.DbImportSourceIndex = index
    local source = self.TempSettings.DbImportSources[index]
    self.TempSettings.DbImportZones = source and source.zones or {}
    local zoneIndex = 1
    for idx, zoneKey in ipairs(self.TempSettings.DbImportZones) do
        if zoneKey == Module.ZoneKeyLower() then zoneIndex = idx end
    end
    self:SelectDbImportZone(zoneIndex)
end

function Module:SelectDbImportZone(index)
    self.TempSettings.DbImportZoneIndex = index
    self.TempSettings.DbImportChecked = {}
    local source = self.TempSettings.DbImportSources[self.TempSettings.DbImportSourceIndex]
    local zoneKey = self.TempSettings.DbImportZones[index]
    self.TempSettings.DbImportPoints = source and zoneKey and source.locations[zoneKey] or {}
end

function Module:ImportDbSelection()
    if not next(self.TempSettings.DbImportChecked) then
        Logger.log_info("No database locations are checked - nothing to import.")
        return
    end
    local pullLocations = Config:GetSetting('PullLocations') or {}
    local zoneKey = self.TempSettings.DbImportZones[self.TempSettings.DbImportZoneIndex]
    if not zoneKey then return end
    pullLocations[zoneKey] = pullLocations[zoneKey] or {}
    local added = 0
    for index, point in ipairs(self.TempSettings.DbImportPoints) do
        if self.TempSettings.DbImportChecked[index] then
            added = added + 1
            Module.AppendLocation(pullLocations[zoneKey], point, point.name)
        end
    end
    Config:SetSetting('PullLocations', pullLocations)
    self.TempSettings.DbImportChecked = {}
    Logger.log_info("\axImported \at%d\ax database location%s into the \at%s\ax pull location list.", added, added == 1 and "" or "s", zoneKey)
end

-- Objective Staging
function Module:FillLocEntry(loc)
    self.TempSettings.LocEntryY = string.format("%.0f", loc.y)
    self.TempSettings.LocEntryX = string.format("%.0f", loc.x)
    self.TempSettings.LocEntryZ = loc.z and string.format("%.0f", loc.z) or ""
end

function Module:SetFightToSpawn(spawnID)
    local spawn = mq.TLO.Spawn(spawnID)
    if (spawnID or 0) == 0 or not spawn() then
        Logger.log_error("Fight To - no valid target or spawn ID given!")
        return false
    end
    if spawn.Type() ~= "NPC" and spawn.Type() ~= "NPCPET" then
        Logger.log_error("Fight To - %s is not an NPC!", spawn.CleanName() or "target")
        return false
    end
    if not spawn.Targetable() then
        Logger.log_error("Fight To - %s is not targetable!", spawn.CleanName() or "target")
        return false
    end
    if not mq.TLO.Navigation.PathExists("id " .. spawnID)() then
        Logger.log_error("Fight To - no nav path exists to %s!", spawn.CleanName() or "target")
        return false
    end
    self.TempSettings.FightTo = { id = spawnID, name = spawn.CleanName(), }
    self.TempSettings.UnreachableSince = 0
    self.TempSettings.TravelFailSince = 0
    self.TempSettings.LocEntryY, self.TempSettings.LocEntryX, self.TempSettings.LocEntryZ = "", "", ""
    return true
end

function Module:SetFightToLoc(loc)
    if loc.z and not mq.TLO.Navigation.PathExists(Module.NavDestString(loc))() then
        Logger.log_error("Fight To - no nav path exists to the given location! (%s)", Module.NavDestString(loc))
        return false
    end
    self.TempSettings.FightTo = loc
    self.TempSettings.UnreachableSince = 0
    self.TempSettings.TravelFailSince = 0
    self:FillLocEntry(loc)
    return true
end

function Module:SetHuntOrigin(loc)
    if loc.z and not mq.TLO.Navigation.PathExists(Module.NavDestString(loc))() then
        Logger.log_error("Hunt - no nav path exists to the given location! (%s)", Module.NavDestString(loc))
        return false
    end
    self.TempSettings.HuntOrigin = loc
    self.TempSettings.HuntAnchor = nil
    Movement.UpdateMapRadii()
    self.TempSettings.UnreachableSince = 0
    self.TempSettings.TravelFailSince = 0
    self:FillLocEntry(loc)
    return true
end

function Module:HasRemoteHuntOrigin()
    return self.TempSettings.HuntOrigin ~= nil
end

function Module:CommitLocEntry()
    if self.TempSettings.LocEntryY == "" and self.TempSettings.LocEntryX == "" then
        self.TempSettings.CampTravelLoc = nil
        return true
    end
    local y, x = tonumber(self.TempSettings.LocEntryY), tonumber(self.TempSettings.LocEntryX)
    local z = tonumber(self.TempSettings.LocEntryZ)
    if not y or not x or (self.TempSettings.LocEntryZ ~= "" and not z) then
        Logger.log_error("Invalid location - Y and X must be numbers (Z optional).")
        return false
    end
    local loc = { y = y, x = x, z = z, }
    local staged = self:IsPullMode("AreaHunt") and self.TempSettings.HuntOrigin or (self:IsPullMode("FightTo") and self.TempSettings.FightTo or nil)
    if staged and staged.name and staged.y and
        self.TempSettings.LocEntryY == string.format("%.0f", staged.y) and self.TempSettings.LocEntryX == string.format("%.0f", staged.x) and
        self.TempSettings.LocEntryZ == (staged.z and string.format("%.0f", staged.z) or "") then
        loc.name = staged.name
    end
    if self:GetModePolicy().family == 'camp' then
        if loc.z and not mq.TLO.Navigation.PathExists(Module.NavDestString(loc))() then
            Logger.log_error("Camp - no nav path exists to the given location! (%s)", Module.NavDestString(loc))
            return false
        end
        local campData = Modules:ExecModule("Movement", "GetCampData")
        if campData.returnToCamp and Math.GetDistanceSquared(loc.x, loc.y, campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) <= 100 then
            self.TempSettings.CampTravelLoc = nil
            return true
        end
        self.TempSettings.CampTravelLoc = loc
        self.TempSettings.UnreachableSince = 0
        self.TempSettings.TravelFailSince = 0
        self:FillLocEntry(loc)
        return true
    end
    if self:IsPullMode("AreaHunt") then return self:SetHuntOrigin(loc) end
    if self:IsPullMode("FightTo") then return self:SetFightToLoc(loc) end
    return true
end

function Module:CurrentIntent()
    local pullModeName = Config:GetSetting('PullMode')
    local y, x, z = tonumber(self.TempSettings.LocEntryY), tonumber(self.TempSettings.LocEntryX), tonumber(self.TempSettings.LocEntryZ)
    local loc = (y ~= nil and x ~= nil) and { y = y, x = x, z = z, } or nil
    local fightToKind, fightToName = "none", nil
    local fightTo = self.TempSettings.FightTo
    if fightTo then
        if fightTo.id then
            fightToKind, fightToName = "spawn", fightTo.name
        elseif fightTo.y then
            fightToKind = "loc"
            if pullModeName == "FightTo" then loc = loc or fightTo end
        end
    end
    if pullModeName == "FightTo" and fightToKind == "none" and loc then fightToKind = "loc" end
    if pullModeName == "AreaHunt" then loc = loc or self.TempSettings.HuntOrigin end
    local campData = Modules:ExecModule("Movement", "GetCampData")
    local breakCamp = false
    if campData.returnToCamp then
        if Module.Constants.PullModePolicies[pullModeName].family ~= 'camp' then
            breakCamp = true
        elseif loc then
            if Math.GetDistanceSquared(loc.x, loc.y, campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) <= 100 then
                loc = nil
            else
                breakCamp = true
            end
        end
    end
    local existingCamp = campData.returnToCamp and Module.Constants.PullModePolicies[pullModeName].family == 'camp' and loc == nil
    return Module.BuildIntentSentence({
        mode = pullModeName,
        scope = Config:GetSetting('PeerMovementScope'),
        scopeWord = Config:GetSetting('PeerMovementScope') == 2 and "in-zone" or ((mq.TLO.Raid.Members() or 0) > 0 and "raid" or "group"),
        manageMovement = Config:GetSetting('ManagePeerMovement'),
        breakCamp = breakCamp,
        existingCamp = existingCamp,
        locationSet = loc ~= nil,
        loc = loc,
        fightToKind = fightToKind,
        fightToName = fightToName,
        hasWaypoints = #self:GetEnabledLocations() > 0,
        waypointCount = #self:GetEnabledLocations(),
    })
end

-- Travel & Escort
function Module.NavDestString(loc)
    if loc.z then return string.format("locyxz %0.2f %0.2f %0.2f", loc.y, loc.x, loc.z) end
    return string.format("locxy %0.2f %0.2f", loc.x, loc.y)
end

function Module.FormatLoc(loc)
    if loc.z then return string.format("%.0f, %.0f, %.0f", loc.y, loc.x, loc.z) end
    return string.format("%.0f, %.0f", loc.y, loc.x)
end

function Module:CheckReachable(destStr)
    -- PathExists can't resolve a Z for locxy destinations (always false); the nav command can, so let the travel attempt decide
    if destStr:find("^locxy") then
        return true, false
    end
    if mq.TLO.Navigation.PathExists(destStr)() then
        self.TempSettings.UnreachableSince = 0
        return true, false
    end
    if self.TempSettings.UnreachableSince == 0 then
        self.TempSettings.UnreachableSince = Globals.GetTimeSeconds()
    end
    return false, (Globals.GetTimeSeconds() - self.TempSettings.UnreachableSince) >= Config:GetSetting('PullIgnoreTime')
end

function Module:TravelTick(ctx, loc, reason, circuitWpId)
    if Math.GetDistanceSquared(mq.TLO.Me.X(), mq.TLO.Me.Y(), loc.x, loc.y) <= 2500 then
        self.TempSettings.Travel = nil
        return 'arrived'
    end

    if mq.TLO.Me.Sitting() then
        Globals.InMedState = false
    end
    mq.TLO.Me.Stand()

    self:SetPullState(PullStates.PULL_MOVING_TO_WP, reason)

    if circuitWpId then
        if self.TempSettings.LocationsToDelete[self:GetWPById(circuitWpId)] then
            Logger.log_debug("PULL:\arNOTICE:\ax Deleting pull location %d while naving to it.", circuitWpId)
            Movement:DoNav(false, "stop log=off")
            self.TempSettings.Travel = nil
            return 'wpdeleted'
        end
    end

    if Targeting.GetXTHaterCount() > 0 then
        if mq.TLO.Navigation.Active() then
            Movement:DoNav(false, "stop log=off")
        end
        self:SetPullState(PullStates.PULL_NAV_INTERRUPT, "")
        self.TempSettings.Travel = nil
        return 'aggro'
    end

    if self.TempSettings.PausePulls or not Config:GetSetting('DoPull') or Globals.PauseMain then
        Movement:DoNav(false, "stop log=off")
        self.TempSettings.Travel = nil
        return 'aborted'
    end

    local travel = self.TempSettings.Travel

    if not mq.TLO.Navigation.Active() then
        if not travel then
            Movement:DoNav(false, "%s log=off", Module.NavDestString(loc))
            self.TempSettings.Travel = { navIssuedAt = ctx.now, }
            return 'moving'
        end
        if ctx.now - travel.navIssuedAt < 1000 then return 'moving' end
        self.TempSettings.Travel = nil
        if circuitWpId then
            Logger.log_verbose("PULL:TravelTick Waypoint: Something went wrong. Current distance to WP: %d. (Possible manual interruption or conflicting nav command.)",
                mq.TLO.Math.Distance(string.format("%0.2f, %0.2f, %0.2f", loc.y, loc.x, loc.z))())
            return 'fail', false
        end
        if self.TempSettings.TravelFailSince == 0 then
            self.TempSettings.TravelFailSince = Globals.GetTimeSeconds()
        end
        return 'fail', (Globals.GetTimeSeconds() - self.TempSettings.TravelFailSince) >= Config:GetSetting('PullIgnoreTime')
    end

    if not travel then
        self.TempSettings.Travel = { navIssuedAt = ctx.now, }
    elseif not circuitWpId then
        self.TempSettings.TravelFailSince = 0
    end

    if circuitWpId then
        Logger.log_verbose("PULL:TravelTick Waypoint: %d Aggro Count: %d", circuitWpId, Targeting.GetXTHaterCount())
    end

    Modules:ExecModule("Movement", "CheckStuck")
    self:CheckMoveAbilities()

    if mq.TLO.Navigation.Paused() then
        Movement:DoNav(false, "pause log=off")
    end

    return 'moving'
end

function Module:AllEscortsArrived()
    if not self.TempSettings.EscortPeers then return false end
    local stopDist = Config:GetSetting('ChaseStopDistance') + 10
    for _, peer in ipairs(self.TempSettings.EscortPeers) do
        local hb = Comms.GetPeerHeartbeat(peer.key)
        if not hb.LastHeartbeat or (Globals.GetTimeSeconds() - hb.LastHeartbeat) > 2 then return false end
        local d = hb.Data
        if d.ZoneId ~= mq.TLO.Zone.ID() or d.InstanceId ~= mq.TLO.Me.Instance() then return false end
        if not (d.X and d.Y and d.Z) then return false end
        if mq.TLO.Math.Distance(string.format("%d, %d, %d", d.Y, d.X, d.Z))() > stopDist then return false end
    end
    return true
end

function Module:ClearEscortState()
    self.TempSettings.EscortPeers = nil
    self.TempSettings.EscortScopeWord = nil
    self.TempSettings.CampArrivalWaitStart = nil
end

function Module:GroupOrRaidPeers(includeSelf)
    return (mq.TLO.Raid.Members() or 0) > 0 and Comms.GetRaidPeers(includeSelf) or Comms.GetGroupPeers(includeSelf)
end

-- Pull Gating & Vitals Watch
---@param campData table
---@return boolean, string
function Module:ShouldPull(campData)
    local me = mq.TLO.Me
    local policy = self:GetModePolicy()

    if self.TempSettings.PausePulls then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax Pulls are Paused.")
        return false, "Pulls Paused"
    end

    if me.PctHPs() < Config:GetSetting('PullHPPct') then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax PctHPs < %d", Config:GetSetting('PullHPPct'))
        return false, string.format("PctHPs < %d", Config:GetSetting('PullHPPct'))
    end

    if me.Casting() then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am Casting!")
        return false, string.format("Casting")
    end

    if me.PctEndurance() < Config:GetSetting('PullEndPct') then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax PctEnd < %d", Config:GetSetting('PullEndPct'))
        return false, string.format("PctEnd < %d", Config:GetSetting('PullEndPct'))
    end

    if me.MaxMana() > 0 and me.PctMana() < Config:GetSetting('PullManaPct') then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax PctMana < %d", Config:GetSetting('PullManaPct'))
        return false, string.format("PctMana < %d", Config:GetSetting('PullManaPct'))
    end

    if Config:GetSetting('PullRespectMedState') and Globals.InMedState then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax Meditating.")
        return false, string.format("Meditating")
    end

    if mq.TLO.Me.Buff("=Resurrection Sickness")() then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax Rez Sickness for %d seconds.",
            mq.TLO.Me.Buff("Resurrection Sickness")() and mq.TLO.Me.Buff("Resurrection Sickness").Duration.TotalSeconds() or 0)
        return false, string.format("Resurrection Sickness")
    end

    if Config:GetSetting('PullWaitCorpse') then
        if mq.TLO.SpawnCount("pccorpse group radius 100 zradius 50")() > 0 then
            self.TempSettings.LastFoundGroupCorpse = Globals.GetTimeSeconds()
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax %d group corpses in-range.", mq.TLO.SpawnCount("pccorpse group radius 100 zradius 50")())
            return false, string.format("Group Corpse Detected")
        elseif Globals.GetTimeSeconds() - self.TempSettings.LastFoundGroupCorpse < Config:GetSetting('WaitAfterRez') then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax Giving time for rebuffs after a groupmember was rezzed.")
            return false, string.format("Groupmember Recently Rezzed")
        end
    end

    if (me.Rooted.ID() or 0) > 0 then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am rooted!")
        return false, string.format("Rooted")
    end

    if not Config:GetSetting('PullDebuffed') then
        if (me.Snared.ID() or 0) > 0 then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am snared!")
            return false, string.format("Snared")
        end

        if mq.TLO.Me.Song("=Restless Ice")() then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I Have Restless Ice!")
            return false, string.format("Restless Ice")
        end

        if mq.TLO.Me.Song("=Restless Ice Infection")() then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I Have Restless Ice Infection!")
            return false, string.format("Ice Infection")
        end

        if (me.Poisoned.ID() or 0) > 0 and not ((me.Tashed.ID() or 0) > 0) then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am poisoned!")
            return false, string.format("Poisoned")
        end

        if (me.Diseased.ID() or 0) > 0 then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am diseased!")
            return false, string.format("Diseased")
        end

        if (me.Cursed.ID() or 0) > 0 then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am cursed!")
            return false, string.format("Cursed")
        end

        -- Laz Marr's and GM Buffs are Corruption effects.
        if not Core.OnLaz() and (me.Corrupted.ID() or 0) > 0 then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am corrupted!")
            return false, string.format("Corrupted")
        end
    end

    if Config:GetSetting('PullBuffCount') > 0 then
        local hbData = Comms.GetPeerHeartbeat(Comms.GetPeerName()).Data
        if (hbData and hbData.BuffCount or 99) < Config:GetSetting('PullBuffCount') then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax Waiting for Buffs! BuffCount < %d", Config:GetSetting('PullBuffCount'))
            return false, string.format("BuffCount < %d", Config:GetSetting('PullBuffCount'))
        end
    end

    if policy.successCheck == 'chainCount' and Targeting.GetXTHaterCount() >= Config:GetSetting('ChainCount') then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax XTargetCount(%d) >= ChainCount(%d)", Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount'))
        return false, string.format("XTargetCount(%d) > ChainCount(%d)", Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount'))
    end

    if policy.successCheck ~= 'chainCount' and Targeting.GetXTHaterCount() > 0 then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax XTargetCount(%d) > 0", Targeting.GetXTHaterCount())
        return false, string.format("XTargetCount(%d) > 0", Targeting.GetXTHaterCount())
    end

    if Config:GetSetting('DoPull') and policy.family == 'camp' and not campData.returnToCamp
        and not self.TempSettings.CampTravelLoc and not self.TempSettings.Travel then
        Logger.log_warn("\ar ALERT: No camp set for camp-style pull mode - Disabling Pulling. \ax")
        self:Announce("None", "No camp set - Disabling pulls. Use /rgl campon and re-enable pulls.")
        self:StopPuller()
        return false, "No camp set"
    end

    if Config:GetSetting('DoPull') and policy.family ~= 'camp' and campData.returnToCamp then
        local pullModeName = self.Constants.PullModeDisplays[Module.PullModeIndex(Config:GetSetting('PullMode'))]
        Logger.log_warn("\ar ALERT: A camp is set, but %s mode is incompatible with camps - Disabling Pulling. \ax", pullModeName)
        self:Announce("None", string.format("Camp set - %s mode is incompatible with camps. Disabling pulls. Use /rgl campoff and re-enable pulls.", pullModeName))
        self:StopPuller()
        return false, "Camp set"
    end

    if campData.returnToCamp and Math.GetDistanceSquared(me.X(), me.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > math.max(Config:GetSetting('AutoCampRadius') ^ 2, 200 ^ 2) then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am too far away from camp!")
        local now = Globals.GetTimeSeconds()
        if (now - self.TempSettings.LastTooFarAnnounce) > 30 then
            self.TempSettings.LastTooFarAnnounce = now
            self:Announce("None", "I am too far away from camp - Holding pulls!")
        end
        return false,
            string.format("I am Too Far (%d) (%d,%d) (%d,%d)", Math.GetDistanceSquared(me.X(), me.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY),
                me.X(), me.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY)
    end


    return true, ""
end

---@param resourceResumePct number -- Resume pulls at this pct
---@param resourcePausePct number -- Hold pulls at this pct
---@param campData table
---@return boolean, string
function Module:CheckGroupForPull(resourceResumePct, resourcePausePct, campData, skipNames, isHolding)
    local groupCount = mq.TLO.Group.Members()

    if not groupCount or groupCount == 0 then return true, "" end
    local maxDist = math.max(Config:GetSetting('AutoCampRadius') ^ 2, 200 ^ 2)

    local watchedClasses = Config:GetSetting('WatchClasses') or {}
    if not next(watchedClasses) then return true, "" end
    local watchSet = Set.new(watchedClasses)

    for i = 1, groupCount do
        local member = mq.TLO.Group.Member(i)
        if member() and (member.ID() or 0) > 0 and not (skipNames and skipNames[member.Name() or ""]) and watchSet:contains(member.Class.ShortName() or "") then
            if member.OtherZone() then
                self:Announce(member.CleanName(), "Not in Zone - Holding pulls!")
                return false, string.format("%s Out of Zone", member.CleanName())
            end

            local resourcePct = isHolding and resourceResumePct or resourcePausePct
            if member.PctHPs() < resourcePct then
                self:Announce(member.CleanName(), "Low on hp - Holding pulls!")
                Logger.log_verbose("\arMember is low on Health - \ayHolding pulls!\ax\ag ResourcePCT:\ax \at%d \aoStopPct: \at%d \ayStartPct: \at%d \aoPullState: \at%d",
                    resourcePct, resourcePausePct, resourceResumePct, self.TempSettings.PullState)
                return false, string.format("%s Low HP", member.CleanName())
            end
            if member.Class.CanCast() and member.Class.ShortName() ~= "BRD" and member.PctMana() < resourcePct then
                self:Announce(member.CleanName(), "Low on mana - Holding pulls!")
                Logger.log_verbose("\arMember is low on Mana - \ayHolding pulls!\ax\ag ResourcePCT:\ax \at%d \aoStopPct: \at%d \ayStartPct: \at%d \aoPullState: \at%d",
                    resourcePct, resourcePausePct, resourceResumePct, self.TempSettings.PullState)
                return false, string.format("%s Low Mana", member.CleanName())
            end
            if Config:GetSetting('WatchEnd') and member.Class.ShortName() ~= "BRD" and member.PctEndurance() < resourcePct then
                self:Announce(member.CleanName(), "Low on endurance - Holding pulls!")
                Logger.log_verbose(
                    "\arMember is low on Endurance - \ayHolding pulls!\ax\ag ResourcePCT:\ax \at%d \aoStopPct: \at%d \ayStartPct: \at%d \aoPullState: \at%d", resourcePct,
                    resourcePausePct, resourceResumePct, self.TempSettings.PullState)
                return false, string.format("%s Low End", member.CleanName())
            end

            if member.Hovering() then
                self:Announce(member.CleanName(), "Dead - Holding pulls!")
                return false, string.format("%s Dead", member.CleanName())
            end

            if campData.returnToCamp then
                if Math.GetDistanceSquared(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > maxDist then
                    self:Announce(member.CleanName(), "Too far away - Holding pulls!")
                    return false,
                        string.format("%s Too Far (%d) (%d,%d) (%d,%d)", member.CleanName(),
                            Math.GetDistance(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY), member.X(), member.Y(),
                            campData.campSettings.AutoCampX, campData.campSettings.AutoCampY)
                end
            else
                if (member.Distance() or 0) > math.max(Config:GetSetting('AutoCampRadius'), 200) then
                    self:Announce(member.CleanName(), "Too far away - Holding pulls!")
                    return false,
                        string.format("%s Too Far (%d) (%d,%d) (%d,%d)", member.CleanName(),
                            member.Distance() or 0, member.X(), member.Y(),
                            mq.TLO.Me.X(),
                            mq.TLO.Me.Y())
                end
            end

            if Config:GetSetting('PullMode') == "ChainToCamp" then
                if member.ID() == Core.GetMainAssistId() then
                    if campData.returnToCamp and Math.GetDistanceSquared(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > maxDist then
                        self:Announce(member.CleanName(), string.format("Assist Target is beyond AutoCampRadius from %d, %d, %d : %d. Holding pulls.",
                            campData.campSettings.AutoCampY, campData.campSettings.AutoCampX, campData.campSettings.AutoCampZ, Config:GetSetting('AutoCampRadius')))
                        return false, string.format("%s Beyond AutoCampRadius", member.CleanName())
                    end
                else
                    if Math.GetDistanceSquared(member.X(), member.Y(), mq.TLO.Me.X(), mq.TLO.Me.Y()) > maxDist then
                        self:Announce(member.CleanName(),
                            string.format("Assist Target is beyond AutoCampRadius from me : %d. Holding pulls.", Config:GetSetting('AutoCampRadius')))
                        return false, string.format("%s Beyond AutoCampRadius", member.CleanName())
                    end
                end
            end
        end
    end

    return true, ""
end

---@param resourceResumePct number
---@param resourcePausePct  number
---@param campData table
---@return boolean, string
function Module:CheckPeersForPull(resourceResumePct, resourcePausePct, campData, peerList, isHolding)
    local watchedClasses = Config:GetSetting('WatchClasses') or {}
    if not next(watchedClasses) then return true, "" end

    local watchSet = Set.new(watchedClasses)
    local maxDist  = math.max(Config:GetSetting('AutoCampRadius') ^ 2, 200 ^ 2)

    for _, peer in ipairs(peerList) do
        local data = peer.data
        if watchSet:contains(data.Class) then
            local resourcePct = isHolding and resourceResumePct or resourcePausePct
            local name        = data.Name or data.From or "Unknown"

            if (data.HPs or 100) == 0 then
                self:Announce(name, "Dead - Holding pulls!")
                return false, string.format("%s Dead", name)
            end

            if (data.HPs or 100) < resourcePct then
                self:Announce(name, "Low on hp - Holding pulls!")
                return false, string.format("%s Low HP", name)
            end

            local useMana = Globals.Constants.RGCasters:contains(data.Class)
            if useMana and data.Class ~= "BRD" and data.Mana and data.Mana < resourcePct then
                self:Announce(name, "Low on mana - Holding pulls!")
                return false, string.format("%s Low Mana", name)
            end

            if Config:GetSetting('WatchEnd') and data.Class ~= "BRD" and data.Endurance and data.Endurance < resourcePct then
                self:Announce(name, "Low on endurance - Holding pulls!")
                return false, string.format("%s Low End", name)
            end

            if data.X and data.Y then
                if campData.returnToCamp then
                    if Math.GetDistanceSquared(data.X, data.Y, campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > maxDist then
                        self:Announce(name, "Too far away - Holding pulls!")
                        return false, string.format("%s Too Far (%d)", name,
                            Math.GetDistance(data.X, data.Y, campData.campSettings.AutoCampX, campData.campSettings.AutoCampY))
                    end
                else
                    if Math.GetDistanceSquared(data.X, data.Y, mq.TLO.Me.X(), mq.TLO.Me.Y()) > maxDist then
                        self:Announce(name, "Too far away - Holding pulls!")
                        return false, string.format("%s Too Far (%d)", name,
                            Math.GetDistance(data.X, data.Y, mq.TLO.Me.X(), mq.TLO.Me.Y()))
                    end
                end

                if Config:GetSetting('PullMode') == "ChainToCamp" and data.X and data.Y then
                    if name == Globals.MainAssist then
                        if campData.returnToCamp and Math.GetDistanceSquared(data.X, data.Y, campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > maxDist then
                            self:Announce(name, string.format("Assist Target is beyond AutoCampRadius from %d, %d, %d : %d. Holding pulls.",
                                campData.campSettings.AutoCampY, campData.campSettings.AutoCampX, campData.campSettings.AutoCampZ, Config:GetSetting('AutoCampRadius')))
                            return false, string.format("%s Beyond AutoCampRadius", name)
                        end
                    else
                        if Math.GetDistanceSquared(data.X, data.Y, mq.TLO.Me.X(), mq.TLO.Me.Y()) > maxDist then
                            self:Announce(name, string.format("Assist Target is beyond AutoCampRadius from me : %d. Holding pulls.", Config:GetSetting('AutoCampRadius')))
                            return false, string.format("%s Beyond AutoCampRadius", name)
                        end
                    end
                end
            end
        end
    end

    return true, ""
end

-- True when we're standing idle during a pull hold and below our med-stop level on a stat our class uses.
---@return boolean
function Module:ShouldSitToMed()
    local me = mq.TLO.Me
    if not me.Standing() or me.Moving() then return false end

    local needHP = me.PctHPs() < Config:GetSetting('HPMedPctStop')
    local needMana = me.MaxMana() > 0 and me.PctMana() < Config:GetSetting('ManaMedPctStop')
    local needEndurance = not Globals.Constants.RGCasters:contains(me.Class.ShortName()) and me.PctEndurance() < Config:GetSetting('EndMedPctStop')

    return needHP or needMana or needEndurance
end

-- Target Scanning
function Module:GetPullableSpawns()
    self:RefreshPullListSets()
    local maxPathRange = Config:GetSetting('MaxPathRange')
    local policy = self:GetModePolicy()

    local metaDataCache = {}

    local pullRadius = Config:GetSetting(policy.radiusSetting)

    local pullRadiusSqr = pullRadius * pullRadius

    local checkX, checkY, checkZ = mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()

    if policy.scanCenter == 'waypoint' then
        local wpData = self:GetWPById(self:GetCurrentWpId())
        checkX, checkY, checkZ = wpData.x, wpData.y, wpData.z
    elseif policy.scanCenter == 'anchor' and self.TempSettings.HuntAnchor then
        checkX, checkY, checkZ = self.TempSettings.HuntAnchor.x, self.TempSettings.HuntAnchor.y, self.TempSettings.HuntAnchor.z
    end

    local logSpawnNames = Logger.get_log_level() >= 5

    local spawnFilter = function(spawn)
        if not spawn() or spawn.ID() == 0 then return false end
        if not spawn.Targetable() then return false end

        local spawnName = logSpawnNames and spawn.CleanName() or ""

        -- do distance checks.
        if math.abs(spawn.Z() - checkZ) > Config:GetSetting('PullZRadius') then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoZDistance too far - %d > %d", spawnName, spawn.ID(),
                math.abs(spawn.Z() - checkZ),
                Config:GetSetting('PullZRadius'))
            return false
        end

        local distSqr = Math.GetDistanceSquared(spawn.X(), spawn.Y(), checkX, checkY)

        if distSqr > pullRadiusSqr then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoDistance too far - distSq(%d) > pullRadiusSq(%d)",
                spawnName, spawn.ID(), distSqr,
                pullRadiusSqr)
            return false
        end

        if spawn.Type() ~= "NPC" and spawn.Type() ~= "NPCPET" then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aois type %s not an NPC or NPCPET -- Skipping", spawnName, spawn.ID(),
                spawn.Type())
            return false
        end

        if spawn.Master.Type() == 'PC' then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aois Charmed Pet -- Skipping", spawnName, spawn.ID())
            return false
        end

        if Targeting.IsTempPet(spawn) then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aois Temp or Swarm Pet -- Skipping", spawnName, spawn.ID())
            return false
        end

        if policy.successCheck == 'chainCount' then
            if Targeting.IsSpawnXTHater(spawn.ID()) then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoAlready on XTarget -- Skipping", spawnName, spawn.ID())
                return false
            end
        end

        if self.TempSettings.HavePullAllowEntries then
            if not self.TempSettings.PullAllowSet[Strings.TrimSpaces(spawn.CleanName() or ""):lower()] then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar -> Not Found in Allow List!", spawnName, spawn.ID())
                return false
            end
        elseif self.TempSettings.HavePullDenyEntries then
            if self.TempSettings.PullDenySet[Strings.TrimSpaces(spawn.CleanName() or ""):lower()] then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar -> Found in Deny List!", spawnName, spawn.ID())
                return false
            end
        end

        for _, ignoredMob in ipairs(self.TempSettings.PullIgnoreTargets) do
            if spawn.ID() == ignoredMob.ID() then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar -> Found in Ignore List!", spawnName, spawn.ID())
                return false
            end
        end

        if spawn.FeetWet() and not Config:GetSetting('PullMobsInWater') then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \agIgnoring mob in water", spawnName, spawn.ID())
            return false
        end

        -- Level Checks
        if Config:GetSetting('UsePullLevels') then
            if spawn.Level() < Config:GetSetting('PullMinLevel') then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoLevel too low - %d", spawnName, spawn.ID(),
                    spawn.Level())
                return false
            end
            if spawn.Level() > Config:GetSetting('PullMaxLevel') then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoLevel too high - %d", spawnName, spawn.ID(),
                    spawn.Level())
                return false
            end
        else
            -- check cons.
            local conLevel = Globals.Constants.ConColorsNameToId[spawn.ConColor() or "GREY"] or 0
            if conLevel > Config:GetSetting('PullMaxCon') or conLevel < Config:GetSetting('PullMinCon') then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw)  - Ignoring mob due to con color. Min = %d, Max = %d, Mob = %d (%s)",
                    spawnName, spawn.ID(),
                    Config:GetSetting('PullMinCon'),
                    Config:GetSetting('PullMaxCon'), conLevel, spawn.ConColor())
                return false
            end
            -- check max level difference
            local maxLvl = mq.TLO.Me.Level() + Config:GetSetting('MaxLevelDiff')
            if spawn.Level() > maxLvl then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw)  - Ignoring mob due to max level difference. Max Level = %d, Mob = %d",
                    spawnName, spawn.ID(), maxLvl, spawn.Level())
                return false
            end
        end

        local navDist = 0
        local canPath = true

        if maxPathRange > 0 then
            navDist = mq.TLO.Navigation.PathLength("id " .. spawn.ID())()
            canPath = navDist > 0
        else
            canPath = mq.TLO.Navigation.PathExists("id " .. spawn.ID())()
        end

        if not canPath or navDist > maxPathRange then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoPath check failed - dist(%d) canPath(%s)", spawnName,
                spawn.ID(), navDist, Strings.BoolToColorString(canPath))
            return false
        end

        if Config:GetSetting('SafeTargeting') and Targeting.IsSpawnFightingStranger(spawn, 500) then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar mob is fighting a stranger and safe targeting is enabled!",
                spawnName, spawn.ID())
            return false
        end

        Logger.log_debug("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \agPotential Pull Added to List", spawn.CleanName(), spawn.ID())

        metaDataCache[spawn.ID()] = { distance = navDist, }

        return true
    end

    local pullTargets = mq.getFilteredSpawns(spawnFilter)

    table.sort(pullTargets, function(a, b)
        -- spawn could be invalid by now so double check
        if a.ID() == 0 or a.Dead() then return false end
        if b.ID() == 0 or b.Dead() then return true end

        return metaDataCache[a.ID()].distance < metaDataCache[b.ID()].distance
    end)

    return pullTargets, metaDataCache
end

function Module:FindTarget()
    local pullTargets, metaData = self:GetPullableSpawns()

    self.TempSettings.PullTargets = pullTargets

    if #pullTargets > 0 then
        local pullTarget = pullTargets[1]
        local pullID = pullTarget.ID()
        local meta = metaData[pullID]
        Logger.log_info("\atPULL::FindPullTarget \agPulling %s [%d] with Distance: %d", pullTarget.CleanName(), pullID, meta and meta.distance or -1)
        return pullID
    end

    return 0
end

-- Attempt Abort Checks
---@param attempt table
---@param bNavigating boolean?
---@return boolean
function Module:CheckAttemptAbort(attempt, bNavigating)
    Logger.log_verbose("PULL:Checking for abort on spawn id: %d", attempt.targetId)
    local spawn = mq.TLO.Spawn(attempt.targetId)

    local abortCtx = {
        pausePulls = self.TempSettings.PausePulls,
        pullListUpdated = self.TempSettings.PullListUpdated,
        doPull = Config:GetSetting('DoPull'),
        pauseMain = Globals.PauseMain,
        spawnGone = not spawn or spawn.Dead() or not spawn.ID() or spawn.ID() == 0,
        navigating = bNavigating or false,
    }

    if attempt.source == 'objective' then
        abortCtx.safeTargeting = Config:GetSetting('SafeTargeting')
        abortCtx.fightingStranger = Targeting.IsSpawnFightingStranger(spawn, 500)
        local _, graceExpired = self:CheckReachable("id " .. attempt.targetId)
        abortCtx.graceExpired = graceExpired
        abortCtx.timedOut = attempt.engageStartedAt ~= nil and (Globals.GetTimeSeconds() - attempt.engageStartedAt) >= Config:GetSetting('PullIgnoreTime')
    elseif attempt.source == 'scan' then
        abortCtx.distance = spawn.Distance() or 0
        abortCtx.maxPathRange = Config:GetSetting("MaxPathRange")
        abortCtx.pathExists = mq.TLO.Navigation.PathExists("id " .. attempt.targetId)()
        abortCtx.safeTargeting = Config:GetSetting('SafeTargeting')
        abortCtx.fightingStranger = Targeting.IsSpawnFightingStranger(spawn, 500)
        abortCtx.timedOut = attempt.engageStartedAt ~= nil and (Globals.GetTimeSeconds() - attempt.engageStartedAt) >= Config:GetSetting('PullIgnoreTime')
    elseif attempt.source == 'manual' then
        abortCtx.timedOut = attempt.engageStartedAt ~= nil and (Globals.GetTimeSeconds() - attempt.engageStartedAt) >= Config:GetSetting('PullIgnoreTime')
    end

    local reason = Module.DecideAbort(attempt, abortCtx)
    if not reason then return false end

    Logger.log_debug(Module.Constants.AbortLogMessages[reason])
    if reason == 'listUpdated' then
        self.TempSettings.PullListUpdated = false
    elseif reason == 'timeout' then
        table.insert(self.TempSettings.PullIgnoreTargets, mq.TLO.Spawn(attempt.targetId))
    elseif reason == 'objectiveTimeout' then
        self:AnnounceStop("Fight To target could not be engaged - pulls disabled.", false)
    end
    return true
end

---Honors user overrides only; target-relative aborts don't apply while the mob is following home.
---@param attempt table
---@return boolean
function Module:CheckReturnAbort(attempt)
    local reason = Module.DecideUserAbort({
        pausePulls = self.TempSettings.PausePulls,
        pullListUpdated = self.TempSettings.PullListUpdated,
        doPull = Config:GetSetting('DoPull'),
        pauseMain = Globals.PauseMain,
    }, attempt.source)
    if not reason then return false end

    Logger.log_debug(Module.Constants.AbortLogMessages[reason])
    if reason == 'listUpdated' then
        self.TempSettings.PullListUpdated = false
    end
    return true
end

-- State Machine Ticks
function Module:BuildPullContext()
    return {
        combatState = Combat.GetCachedCombatState(),
        campData = Modules:ExecModule("Movement", "GetCampData"),
        policy = self.TempSettings.Attempt and self.TempSettings.Attempt.policy or Module.Constants.PullModePolicies[Config:GetSetting('PullMode')],
        now = Globals.GetTimeMS(),
        nowSec = Globals.GetTimeSeconds(),
    }
end

function Module:RunEntryGates(ctx)
    self:ProcessDeleteLocations()

    if ctx.combatState ~= "Downtime" and not ctx.policy.runsDuringCombat then
        Logger.log_verbose("PULL:GiveTime() we are in %s, not ready for pulling.", ctx.combatState)
        return false
    end
    if (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded) < Config:GetSetting('PullDelay') then
        Logger.log_verbose("PULL:GiveTime() waiting for Pull Delay, next attempt in %d seconds.",
            Config:GetSetting('PullDelay') - (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded))
        return false
    end

    -- Hold pulls if using SmartLoot and we have opted to wait for peers to finish looting
    if Globals.SLPeerLooting and Config:GetSetting("PullsYieldForLooting", true) then
        Logger.log_verbose("PULL:GiveTime() Holding pulls to finish processing looting.")
        return false
    end

    Logger.log_verbose("PULL:GiveTime() - Enter")
    self:SetValidPullAbilities()
    self:FixPullerMerc()
    if Config:GetSetting('DoPull') then
        for _, v in pairs(Config:GetSetting('PullSafeZones')) do
            if v == mq.TLO.Zone.ShortName() then
                local safeZone = mq.TLO.Zone.ShortName()
                Logger.log_debug("\ar ALERT: In a safe zone \at%s \ax-\ar Disabling Pulling. \ax", safeZone)
                self:StopPuller()
                break
            end
        end
    end

    if not Config:GetSetting('DoPull') then
        if self.TempSettings.HuntAnchor then
            self.TempSettings.HuntAnchor = nil
            Core.DoCmd("/mapfilter pullradius off")
        end
        if #self.TempSettings.PullIgnoreTargets > 0 then
            self:ClearIgnoreList()
        end
    end

    Logger.log_verbose("PULL:GiveTime() - DoPull: %s", Strings.BoolToColorString(Config:GetSetting('DoPull')))
    if not Config:GetSetting('DoPull') and self.TempSettings.TargetSpawnID == 0 then return false end

    if Config:GetSetting('DoPull') then
        if ctx.policy.scanCenter == 'anchor' and not self.TempSettings.HuntOrigin and not self.TempSettings.HuntAnchor then
            self.TempSettings.HuntAnchor = { y = mq.TLO.Me.Y(), x = mq.TLO.Me.X(), z = mq.TLO.Me.Z(), }
            Movement.UpdateMapRadii()
        end
        if #self.TempSettings.PullIgnoreTargets > 0 then
            self:ValidateIgnoreList()
        end
    end

    if not mq.TLO.Navigation.MeshLoaded() then
        Logger.log_error("\ar ERROR: There's no mesh for this zone. Can't pull. \ax")
        Logger.log_error("\ar Disabling Pulling. \ax")
        self:StopPuller()
        return false
    end

    if Config:GetSetting('PullAbility') == self.TempSettings.PullAbilityIDToName.PetPull and (mq.TLO.Me.Pet.ID() or 0) == 0 then
        self:Announce(mq.TLO.Me.CleanName(), "Need to create a new pet to throw as mob fodder.")
        return false
    end

    local shouldPull, reason = self:ShouldPull(ctx.campData)

    Logger.log_verbose("PULL:GiveTime() - ShouldPull: %s", Strings.BoolToColorString(shouldPull))

    if not shouldPull then
        if self.TempSettings.PausePulls and self.TempSettings.Travel and mq.TLO.Navigation.Active() then
            Movement:DoNav(false, "stop log=off")
            self.TempSettings.Travel = nil
        end
        if not mq.TLO.Navigation.Active() and ctx.combatState == "Downtime" then
            -- go back to camp.
            self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, reason)
            if ctx.campData.returnToCamp then
                local distanceToCampSq = Math.GetDistanceSquared(mq.TLO.Me.Y(), mq.TLO.Me.X(), ctx.campData.campSettings.AutoCampY, ctx.campData.campSettings.AutoCampX)
                if distanceToCampSq > (Config:GetSetting('AutoCampRadius') ^ 2) then
                    Logger.log_debug("PULL: Distance to camp is %d and radius is %d - going closer.", math.sqrt(distanceToCampSq), Config:GetSetting('AutoCampRadius'))
                    Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f log=off", ctx.campData.campSettings.AutoCampY, ctx.campData.campSettings.AutoCampX,
                        ctx.campData.campSettings.AutoCampZ)
                end
            end
        end
        return false
    end

    local watchScope = Config:GetSetting('WatchScope')
    if watchScope == 2 then
        local isHolding = self.TempSettings.PullState == PullStates.PULL_GROUPWATCH_WAIT
        local scopedPeers = self:GroupOrRaidPeers(false)
        local vitalsReady, vitalsReason = self:CheckPeersForPull(Config:GetSetting('WatchStartPct'), Config:GetSetting('WatchStopPct'), ctx.campData, scopedPeers, isHolding)
        if vitalsReady then
            local peerNames = {}
            for _, peer in ipairs(scopedPeers) do peerNames[peer.name] = true end
            vitalsReady, vitalsReason = self:CheckGroupForPull(Config:GetSetting('WatchStartPct'), Config:GetSetting('WatchStopPct'), ctx.campData, peerNames, isHolding)
        end
        if not vitalsReady then
            Logger.log_verbose("PULL:GiveTime() - Group / Raid Vitals Failed")
            self:SetPullState(PullStates.PULL_GROUPWATCH_WAIT, vitalsReason)
            if self:ShouldSitToMed() then
                Logger.log_verbose(
                    "PULL:GiveTime() - We are waiting on Group / Raid vitals and we are below med stop levels, lets sit down ourselves! Note: Does not interface with medstate.")
                mq.TLO.Me.Sit()
            end
            return false
        end
    elseif watchScope == 3 then
        local isHolding = self.TempSettings.PullState == PullStates.PULL_PEERWATCH_WAIT
        local vitalsReady, vitalsReason = self:CheckPeersForPull(Config:GetSetting('WatchStartPct'), Config:GetSetting('WatchStopPct'), ctx.campData,
            Comms.GetZonePeers(false), isHolding)
        if not vitalsReady then
            Logger.log_verbose("PULL:GiveTime() - Zone Peers Vitals Failed")
            self:SetPullState(PullStates.PULL_PEERWATCH_WAIT, vitalsReason)
            if self:ShouldSitToMed() then
                Logger.log_verbose(
                    "PULL:GiveTime() - We are waiting on Zone Peers vitals and we are below med stop levels, lets sit down ourselves! Note: Does not interface with medstate.")
                mq.TLO.Me.Sit()
            end
            return false
        end
    end

    -- GROUPWATCH and NAVINTERRUPT are the two states we can't reset. In the future it may be best to
    -- limit this to only the states we know should be transitionable to the IDLE state.
    if self.TempSettings.PullState ~= PullStates.PULL_GROUPWATCH_WAIT and self.TempSettings.PullState ~= PullStates.PULL_PEERWATCH_WAIT and self.TempSettings.PullState ~= PullStates.PULL_NAV_INTERRUPT then
        self:SetPullState(PullStates.PULL_IDLE, "")
    end

    return true
end

function Module:PreAttemptTick(ctx)
    -- We're ready to pull, but first, check if we're in Circuit Hunt mode and if we were interrupted
    if ctx.policy.scanCenter == 'waypoint' then
        local currentWpId = self:GetCurrentWpId()
        if currentWpId == 0 then
            Logger.log_error("\arYou do not have any enabled pull locations for this zone(%s::%s) - Aborting!", mq.TLO.Zone.Name(), mq.TLO.Zone.ShortName())
            self:SetPullState(PullStates.PULL_IDLE, "")
            self:StopPuller()
            return
        end

        if self.TempSettings.PullState == PullStates.PULL_NAV_INTERRUPT or self.TempSettings.Travel then
            -- if we still have haters let combat handle it first.
            if Targeting.GetXTHaterCount() > 0 then
                return
            end

            -- We're not ready to pull yet as we haven't made it to our waypoint.
            local advanceLeg = self.TempSettings.Travel and self.TempSettings.Travel.circuitAdvance
            local wpData = self:GetWPById(currentWpId)
            local result = self:TravelTick(ctx, wpData, string.format("WP Id: %d", currentWpId), currentWpId)
            self:HandleCircuitTravelResult(result, currentWpId)
            if result ~= 'arrived' then return end
            if advanceLeg then return end
        end
    end

    if ctx.policy.scanCenter == 'anchor' and self.TempSettings.HuntOrigin and self.TempSettings.TargetSpawnID == 0 then
        local origin = self.TempSettings.HuntOrigin
        local travelResult, travelGraceExpired = self:TravelTick(ctx, origin, "Loc: " .. Module.FormatLoc(origin))
        if travelResult == 'arrived' then
            self.TempSettings.HuntOrigin = nil
            self.TempSettings.HuntAnchor = { y = mq.TLO.Me.Y(), x = mq.TLO.Me.X(), z = mq.TLO.Me.Z(), name = origin.name, }
            Movement.UpdateMapRadii()
        elseif travelResult == 'fail' then
            if travelGraceExpired then
                self:AnnounceStop("Hunt location is unreachable - pulls disabled.", false)
            else
                self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "Hunt travel interrupted - retrying")
            end
        end
        return
    end

    if ctx.policy.family == 'camp' and not ctx.campData.returnToCamp and self.TempSettings.CampTravelLoc then
        local dest = self.TempSettings.CampTravelLoc
        local travelResult, travelGraceExpired = self:TravelTick(ctx, dest, "Loc: " .. Module.FormatLoc(dest))
        if travelResult == 'arrived' then
            local scopeWord = self.TempSettings.EscortScopeWord
            if scopeWord then
                self.TempSettings.CampArrivalWaitStart = self.TempSettings.CampArrivalWaitStart or ctx.now
                local timedOut = (ctx.now - self.TempSettings.CampArrivalWaitStart) >= 60000
                if not timedOut and not self:AllEscortsArrived() then
                    self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, string.format("Waiting on %s to arrive", scopeWord))
                    return
                end
                if timedOut then
                    self:Announce("None", string.format("%s didn't arrive in time - camping anyway.", scopeWord:gsub("^%l", string.upper)))
                end
                Core.DoCmd("/rgl campon")
                for _, peer in ipairs(self.TempSettings.EscortPeers or {}) do
                    local hb = Comms.GetPeerHeartbeat(peer.key)
                    if hb.Data and hb.Data.ZoneId == mq.TLO.Zone.ID() and hb.Data.InstanceId == mq.TLO.Me.Instance() then
                        Comms.SendPeerDoCmd(peer.key, "/rgl campon")
                    end
                end
                self:ClearEscortState()
                self.TempSettings.CampTravelLoc = nil
                self:SetLastPullOrCombatEndedTimer()
            else
                Core.DoCmd("/rgl campon")
                self.TempSettings.CampTravelLoc = nil
                self:SetLastPullOrCombatEndedTimer()
            end
        elseif travelResult == 'fail' then
            if travelGraceExpired then
                self:ClearEscortState()
                self.TempSettings.CampTravelLoc = nil
                self:AnnounceStop("Camp location is unreachable - pulls disabled.", false)
            else
                self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "Camp travel interrupted - retrying")
            end
        end
        return
    end

    self:SetPullState(PullStates.PULL_SCAN, "")

    local pullID
    local source = 'scan'

    if self.TempSettings.TargetSpawnID > 0 then
        local targetSpawn = mq.TLO.Spawn(self.TempSettings.TargetSpawnID)
        if not targetSpawn() or targetSpawn.Dead() then
            Logger.log_debug("PULL: \arDropping Manual target id %d - it is dead.", self.TempSettings.TargetSpawnID)
            self.TempSettings.TargetSpawnID = 0
        end
    end

    if self.TempSettings.TargetSpawnID > 0 then
        pullID = self.TempSettings.TargetSpawnID
        source = 'manual'
    elseif ctx.policy.family == 'directive' then
        local objective = self.TempSettings.FightTo
        if not objective then
            self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "No objective set")
            return
        end

        if objective.id then
            local objectiveSpawn = mq.TLO.Spawn(objective.id)
            local objectiveDead = (objectiveSpawn() and objectiveSpawn.Dead()) or false
            if objectiveDead or not objectiveSpawn() or (objectiveSpawn.ID() or 0) == 0 then
                local target = mq.TLO.Target
                if (target.ID() or 0) == objective.id or
                    ((target.Type() or "") == "Corpse" and objective.name and (target.CleanName() or ""):find(objective.name, 1, true) ~= nil) then
                    Core.DoCmd("/squelch /target clear")
                end
                self:AnnounceStop(objectiveDead and "Fight To target has died - pulls disabled." or "Fight To target despawned - pulls disabled.", true)
                return
            end

            local reachable, graceExpired = self:CheckReachable("id " .. objective.id)
            if not reachable then
                if graceExpired then
                    self:AnnounceStop("Fight To target is unreachable - pulls disabled.", false)
                else
                    self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "No nav path to target - retrying")
                end
                return
            end

            pullID = objective.id
            source = 'objective'
        else
            local reachable, graceExpired = self:CheckReachable(Module.NavDestString(objective))
            if not reachable then
                if graceExpired then
                    self:AnnounceStop("Fight To destination is unreachable - pulls disabled.", false)
                else
                    self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "No nav path to destination - retrying")
                end
                return
            end

            local travelResult, travelGraceExpired = self:TravelTick(ctx, objective, "Loc: " .. Module.FormatLoc(objective))
            if travelResult == 'arrived' then
                self:AnnounceStop("Arrived at the Fight To destination - pulls disabled.", true)
            elseif travelResult == 'fail' then
                if travelGraceExpired then
                    self:AnnounceStop("Fight To destination is unreachable - pulls disabled.", false)
                else
                    self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "Fight To travel interrupted - retrying")
                end
            end
            return
        end
    else
        Logger.log_debug("PULL:Finding Pull Target")
        pullID = self:FindTarget()
    end

    if pullID == 0 and ctx.policy.scanCenter == 'waypoint' then
        self:CircuitAdvanceTick(ctx)
        return
    end

    if pullID == 0 then
        self:SetPullState(PullStates.PULL_IDLE, string.format("No pullable targets within %d units", Config:GetSetting(ctx.policy.radiusSetting)))
        Logger.log_debug("\ayNothing to pull - better luck next time")
        return
    end

    self:SetPullState(PullStates.PULL_IDLE, "")
    self:OpenAttempt(ctx, pullID, source)
end

function Module:HandleCircuitTravelResult(result, wpId)
    if result == 'arrived' then
        Logger.log_verbose("Pull: Reached Pull Location %d.", wpId)
        self.TempSettings.ReachedWP = true
        self:SetLastPullOrCombatEndedTimer()
        self:SetPullState(PullStates.PULL_IDLE, "")
    elseif result == 'aggro' or result == 'fail' or result == 'wpdeleted' then
        self:SetPullState(PullStates.PULL_NAV_INTERRUPT, "")
        self.TempSettings.ReachedWP = false
    end
end

function Module:CircuitAdvanceTick(ctx)
    -- move to next WP
    if self.TempSettings.ReachedWP then
        -- wait a bit if we have a waypoint delay set
        if (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded) < Config:GetSetting('WaypointDelay') then
            Logger.log_verbose("PULL: Waiting for pull location delay, next attempt in %d seconds.",
                Config:GetSetting('WaypointDelay') - (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded))
            return
        end
        self:IncrementWpId()
        self.TempSettings.ReachedWP = false
    end
    -- Here we want to nav to our current waypoint. If we engage an enemy while
    -- we are currently traveling to our waypoint, we need to set our state to
    -- PULL_NAVINTERRUPT so that when Pulling re-engages after combat, we continue
    -- to travel to our next waypoint.

    local currentWP = self:GetCurrentWpId()
    local wpData = self:GetWPById(currentWP)

    local result = self:TravelTick(ctx, wpData, string.format("%0.2f, %0.2f, %0.2f", wpData.y, wpData.x, wpData.z), currentWP)
    self:HandleCircuitTravelResult(result, currentWP)
    if result == 'moving' and self.TempSettings.Travel then
        self.TempSettings.Travel.circuitAdvance = true
    end
end

function Module:OpenAttempt(ctx, pullID, source)
    self.TempSettings.Travel = nil

    local start_x = mq.TLO.Me.X()
    local start_y = mq.TLO.Me.Y()
    local start_z = mq.TLO.Me.Z()

    if ctx.campData.returnToCamp then
        Logger.log_debug("PULL:\ayRTB: Storing Camp info to return to")
        start_x = ctx.campData.campSettings.AutoCampX
        start_y = ctx.campData.campSettings.AutoCampY
        start_z = ctx.campData.campSettings.AutoCampZ
    end

    Logger.log_debug("PULL:\ayRTB Location: %d %d %d", start_y, start_x, start_z)

    -- if DoMed is set it will take care of standing us up
    if mq.TLO.Me.Sitting() then
        Globals.InMedState = false
    end

    mq.TLO.Me.Stand()

    self:CheckMoveAbilities(true)

    self:SetPullState(PullStates.PULL_NAV_TO_TARGET, string.format("Id: %d", pullID))
    Logger.log_debug("PULL:\ayFound Target: %d - Attempting to Nav", pullID)

    local pullAbility = self.TempSettings.ValidPullAbilities[Config:GetSetting('PullAbility')]
    local startingXTargs = Targeting.GetXTHaterIDs()
    local requireLOS = "on"

    if pullAbility and pullAbility.LOS == false then
        requireLOS = "off"
    end

    Core.DoCmd("/squelch /attack off")

    Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", pullID, self:GetPullAbilityRange(), requireLOS)

    self.TempSettings.Attempt = {
        targetId = pullID,
        source = source,
        policy = ctx.policy,
        ability = pullAbility,
        requireLOS = requireLOS,
        startingXTargs = startingXTargs,
        returnLoc = { y = start_y, x = start_x, z = start_z, },
        startedAt = ctx.nowSec,
        navIssuedAt = ctx.now,
        moveDeadline = ctx.now + Config:GetSetting('MaxMoveTime') * 1000,
    }
end

function Module:NavToTargetTick(ctx)
    local attempt = self.TempSettings.Attempt

    if mq.TLO.Navigation.Active() then
        Logger.log_super_verbose("Pathing to pull id...")
        if ctx.policy.successCheck == 'chainCount' then
            if Targeting.GetXTHaterCount() >= Config:GetSetting('ChainCount') then
                Logger.log_debug("\awNOTICE:\ax Gained aggro -- aborting chain pull!")
                self:AbortNavToTarget(ctx)
                return
            end
            if Targeting.DiffXTHaterIDs(attempt.startingXTargs) then
                Logger.log_debug("\awNOTICE:\ax XTarget List Changed -- aborting chain pull!")
                self:AbortNavToTarget(ctx)
                return
            end
        else
            if Targeting.GetXTHaterCount() > 0 then
                Logger.log_debug("\awNOTICE:\ax Gained aggro -- aborting pull!")
                self:AbortNavToTarget(ctx)
                return
            end
        end

        if self:CheckAttemptAbort(attempt, true) then
            self:AbortNavToTarget(ctx)
            return
        end

        Modules:ExecModule("Movement", "CheckStuck")
        self:CheckMoveAbilities()

        if ctx.now >= attempt.moveDeadline then
            Logger.log_debug("\arNOTICE:\ax Pull Time Exceeded! Rescanning for a closer target.")
            -- On a long pull, periodically rescan so we can switch to a closer target if one popped.
            if attempt.source == 'scan' and ctx.policy.rescanToCloser and (ctx.policy.scanCenter ~= 'waypoint' or self:GetCurrentWpId() > 0) then
                local closerID = self:FindTarget()
                if closerID > 0 and closerID ~= attempt.targetId then
                    Logger.log_debug("PULL:\ayCloser target popped - switching pull to %d.", closerID)
                    attempt.targetId = closerID
                    Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", closerID, self:GetPullAbilityRange(), attempt.requireLOS)
                    attempt.navIssuedAt = ctx.now
                end
            end
            attempt.moveDeadline = ctx.now + Config:GetSetting('MaxMoveTime') * 1000
        end
        return
    end

    if ctx.now - attempt.navIssuedAt < 1000 then return end

    mq.delay("2s", function() return not mq.TLO.Me.Moving() end)

    Targeting.SetTarget(attempt.targetId, true)

    local abortPull = false

    if mq.TLO.Target.Master.Type() == 'PC' then
        Logger.log_debug("\atPULL::PullTarget \awPullTarget :: Spawn \am%s\aw (\at%d\aw) is Charmed Pet -- Skipping", mq.TLO.Target.CleanName(), mq.TLO.Target.ID())
        abortPull = true
    end

    if Config:GetSetting('SafeTargeting') then
        -- Hard coding 500 units as our radius as it's probably twice our effective spell range.
        if Targeting.IsSpawnFightingStranger(mq.TLO.Spawn(attempt.targetId), 500) then
            abortPull = true
        end
    end

    local target = mq.TLO.Target
    self:SetPullState(PullStates.PULL_PULLING, self:GetPullStateTargetInfo())

    if target and target.ID() > 0 and not abortPull then
        Logger.log_info("\agPulling %s [%d]", target.CleanName(), target.ID())
        self:BeginEngage(ctx)
    else
        self:TransitionAfterEngage(ctx)
    end
end

function Module:AbortNavToTarget(ctx)
    Logger.log_debug("\arNOTICE:\ax Pull Aborted!")
    Movement:DoNav(false, "stop log=off")
    mq.delay("2s", function() return not mq.TLO.Navigation.Active() end)
    self:TransitionAfterEngage(ctx)
end

function Module:BeginEngage(ctx)
    local attempt = self.TempSettings.Attempt
    local abilityId = Config:GetSetting('PullAbility')
    local engageKey
    if abilityId == self.TempSettings.PullAbilityIDToName.PetPull then
        engageKey = 'PetPull'
    elseif abilityId == self.TempSettings.PullAbilityIDToName.Face then
        engageKey = 'Face'
    elseif abilityId == self.TempSettings.PullAbilityIDToName.Ranged then
        engageKey = 'Ranged'
    elseif abilityId == self.TempSettings.PullAbilityIDToName.AutoAttack then
        engageKey = 'AutoAttack'
    elseif attempt.ability then
        engageKey = 'Generic'
    end

    if not engageKey then
        Logger.log_error("\arInvalid PullAbility: \at%d\ar - Please Select a valid Pull Ability\ax", abilityId)
        self:TransitionAfterEngage(ctx)
        return
    end

    attempt.engageKey = engageKey

    if engageKey == 'PetPull' then
        Combat.PetAttack(attempt.targetId, false)
        attempt.engageStartedAt = ctx.nowSec
    elseif engageKey == 'Generic' then
        attempt.engageStartedAt = ctx.nowSec
    else
        -- Make sure we're looking straight ahead at our mob and delay
        -- until we're facing them.
        Core.DoCmd("/look 0")
        attempt.faceDeadline = ctx.now + 3000
    end
end

function Module:PullingTick(ctx)
    local attempt = self.TempSettings.Attempt
    local descriptor = Module.Constants.EngageDescriptors[attempt.engageKey]

    if attempt.faceDeadline then
        if mq.TLO.Me.Heading.ShortName() == mq.TLO.Target.HeadingTo.ShortName() or ctx.now >= attempt.faceDeadline then
            attempt.faceDeadline = nil
            attempt.engageStartedAt = ctx.nowSec
        else
            return
        end
    end

    if Module.PullSuccessCheck(ctx.policy.successCheck, Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount')) then
        self:EndEngage(ctx)
        return
    end

    if descriptor.verboseShowsSuccess then
        Logger.log_super_verbose(descriptor.verbose,
            Strings.BoolToColorString(Module.PullSuccessCheck(ctx.policy.successCheck, Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount'))))
    else
        Logger.log_super_verbose(descriptor.verbose)
    end

    local approachDone = false
    if attempt.engageNavDeadline then
        local waitingOnStart = descriptor.startGraceMs and (ctx.now - attempt.engageNavIssuedAt) < descriptor.startGraceMs
        if ctx.now < attempt.engageNavDeadline and (mq.TLO.Navigation.Active() or waitingOnStart) then
            Modules:ExecModule("Movement", "CheckStuck")
            return
        end
        attempt.engageNavDeadline = nil
        approachDone = true
    end

    if descriptor.fireBeforeApproach and descriptor.action then
        descriptor.action(self, attempt)
    end

    if descriptor.retarget then
        Targeting.SetTarget(attempt.targetId, true)
    end

    if descriptor.feetWetRenav and mq.TLO.Target.FeetWet() ~= mq.TLO.Me.FeetWet() then
        Logger.log_debug("\ar ALERT: Feet wet mismatch - Moving around\ax")
        Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", attempt.targetId, Targeting.GetTargetDistance() * 0.9, attempt.requireLOS)
    end

    if descriptor.approach == 'abilityRange' then
        Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", attempt.targetId, self:GetPullAbilityRange(), descriptor.forceLOS and "on" or attempt.requireLOS)
    elseif descriptor.approach == 'halfRange' and not approachDone then
        if Targeting.GetTargetDistance() > self:GetPullAbilityRange() then
            Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", attempt.targetId, self:GetPullAbilityRange() / 2, attempt.requireLOS)
            attempt.engageNavIssuedAt = ctx.now
            attempt.engageNavDeadline = ctx.now + Config:GetSetting('MaxMoveTime') * 1000
            if not descriptor.fireBeforeApproach then
                return
            end
        end
    end

    if not descriptor.fireBeforeApproach and descriptor.action then
        descriptor.action(self, attempt)
    end

    if ctx.policy.successCheck == 'chainCount' and Targeting.DiffXTHaterIDs(attempt.startingXTargs) then
        if descriptor.chainBreakLog then
            Logger.log_debug("PULL:\arXtargs changed heading back to camp!")
        end
        self:EndEngage(ctx)
        return
    end

    if self:CheckAttemptAbort(attempt) then
        self:EndEngage(ctx)
        return
    end

    if descriptor.stuckCheck then
        Modules:ExecModule("Movement", "CheckStuck")
    end
end

function Module:EndEngage(ctx)
    local attempt = self.TempSettings.Attempt

    if attempt.engageKey == 'PetPull' then
        Core.SetPetHold()
        Core.DoCmd("/squelch /pet back off")
        mq.delay("1s", function() return (mq.TLO.Pet.PlayerState() or 0) == 0 end)
        Core.DoCmd("/squelch /pet follow")
    end

    if Module.PullSuccessCheck(ctx.policy.successCheck, Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount')) then
        Globals.LastPulledID = attempt.targetId
    end

    self:TransitionAfterEngage(ctx)
end

function Module:TransitionAfterEngage(ctx)
    local attempt = self.TempSettings.Attempt

    if ctx.policy.family == 'camp' then
        -- Nav back to camp.
        local returnLoc = attempt.returnLoc
        self:SetPullState(PullStates.PULL_RETURN_TO_CAMP, string.format("Camp Loc: %0.2f %0.2f %0.2f", returnLoc.y, returnLoc.x, returnLoc.z))
        Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f log=off %s", returnLoc.y, returnLoc.x, returnLoc.z, Config:GetSetting('PullBackwards') and "facing=backward" or "")
        attempt.returnNavIssuedAt = ctx.now
    else
        self:CloseAttempt(ctx)
    end
end

function Module:ReturnToCampTick(ctx)
    local attempt = self.TempSettings.Attempt
    local returnLoc = attempt.returnLoc

    if self:CheckReturnAbort(attempt) then
        Movement:DoNav(false, "stop log=off")
        mq.delay("2s", function() return not mq.TLO.Navigation.Active() end)
        self:CloseAttempt(ctx)
        return
    end

    if mq.TLO.Navigation.Active() then
        Logger.log_super_verbose("Pathing to camp...")
        if (mq.TLO.Me.State() or ""):lower() == "feign" or mq.TLO.Me.Sitting() then
            Logger.log_debug("PULL:Standing up to Engage Target")
            mq.TLO.Me.Stand()
            Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f log=off %s", returnLoc.y, returnLoc.x, returnLoc.z,
                Config:GetSetting('PullBackwards') and "facing=backward" or "")
            attempt.returnNavIssuedAt = ctx.now
        end

        if mq.TLO.Navigation.Paused() then
            Movement:DoNav(false, "pause")
        end

        Modules:ExecModule("Movement", "CheckStuck")
        self:CheckMoveAbilities()

        if ctx.now - attempt.returnNavIssuedAt < 1000 * 120 then return end

        Logger.log_warn("PULL: Return to camp exceeded 120s - stopping nav to force wait resolution")
        Movement:DoNav(false, "stop log=off")
        mq.delay("2s", function() return not mq.TLO.Navigation.Active() end)
    end

    if ctx.now - attempt.returnNavIssuedAt < 5000 then return end

    if Math.GetDistanceSquared(mq.TLO.Me.X(), mq.TLO.Me.Y(), returnLoc.x, returnLoc.y) > Config:GetSetting('AutoCampRadius') ^ 2 then
        Logger.log_warn("PULL: Failed to reach camp (dist %.0f) - puller is stuck in the field",
            math.sqrt(Math.GetDistanceSquared(mq.TLO.Me.X(), mq.TLO.Me.Y(), returnLoc.x, returnLoc.y)))
        self:Announce("None", "Failed to return to camp - manual intervention may be needed!")
    end

    Core.DoCmd("/face id %d", attempt.targetId)

    self:SetPullState(PullStates.PULL_WAITING_ON_MOB, self:GetPullStateTargetInfo())

    -- give the mob 2 mins to get to us.
    attempt.waitDeadline = ctx.now + 1000 * 120
end

function Module:WaitingOnMobTick(ctx)
    local attempt = self.TempSettings.Attempt

    -- wait for the mob to reach us.
    if mq.TLO.Target.ID() ~= attempt.targetId or Targeting.GetTargetDistance() <= Config:GetSetting('AutoCampRadius') or ctx.now >= attempt.waitDeadline then
        self:CloseAttempt(ctx)
        return
    end

    self:SetPullState(PullStates.PULL_WAITING_ON_MOB, self:GetPullStateTargetInfo())

    if mq.TLO.Me.Pet.Combat() then
        Core.DoCmd("/squelch /pet back off")
        mq.delay("1s", function() return (mq.TLO.Pet.PlayerState() or 0) == 0 end)
        Core.DoCmd("/squelch /pet follow")
    end

    if self:CheckAttemptAbort(attempt) then
        self:CloseAttempt(ctx)
        return
    end

    -- they ain't coming!
    if not Targeting.IsSpawnXTHater(attempt.targetId) then
        self:CloseAttempt(ctx)
        return
    end
end

function Module:CloseAttempt(ctx)
    self.TempSettings.TargetSpawnID = 0
    self.TempSettings.Attempt = nil

    local campRadiusSq = math.max(Config:GetSetting('AutoCampRadius') ^ 2, 200 ^ 2)
    if ctx.policy.family == 'camp' and ctx.campData.returnToCamp and
        Math.GetDistanceSquared(mq.TLO.Me.X(), mq.TLO.Me.Y(), ctx.campData.campSettings.AutoCampX, ctx.campData.campSettings.AutoCampY) > campRadiusSq then
        self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, "Awaiting return to camp")
    else
        self:SetPullState(PullStates.PULL_IDLE, "")
    end
end

-- Tick Dispatch
function Module:PullTick()
    if not Config:GetSetting('DoPull') and (self.TempSettings.EscortScopeWord or self.TempSettings.CampTravelLoc or self.TempSettings.Travel) then
        self:ClearEscortState()
        self.TempSettings.CampTravelLoc = nil
        self.TempSettings.Travel = nil
        if mq.TLO.Navigation.Active() then Movement:DoNav(false, "stop log=off") end
    end

    local ctx = self:BuildPullContext()

    if not self.TempSettings.Attempt then
        if not self:RunEntryGates(ctx) then return end
    end

    local handlerName = Module.Constants.PullStateHandlers[self.TempSettings.PullState]
    if handlerName then self[handlerName](self, ctx) end
end

function Module:GiveTime()
    -- death-resume for a rez that never zoned us (took it while hovering): if we are back near camp or where we died, start pulling again
    if self.TempSettings.DeathResumeFreePass and not mq.TLO.Me.Hovering() and mq.TLO.Zone.ID() == Globals.CurZoneId and mq.TLO.Me.Instance() == Globals.CurInstanceId then
        self.TempSettings.DeathResumeFreePass = nil
        local campData = Modules:ExecModule("Movement", "GetCampData")
        if campData.deathCampHold and self:NearDeathReturnPoint(campData) then
            Modules:ExecModule("Movement", "ClearDeathCampHold")
            Config:SetSetting('DoPull', true)
        end
    end

    self:PullTick()

    -- Hold the frame while a pull attempt is in flight so no other module acts on a half-finished pull.
    local holdZone = mq.TLO.Zone.ID()
    while self:IsAttemptActive() and not mq.TLO.Me.Hovering() and mq.TLO.Zone.ID() == holdZone do
        mq.doevents()
        Events.DoEvents()
        mq.delay(10)
        self:PullTick()
    end
end

function Module:IsAttemptActive()
    return self.TempSettings.Attempt ~= nil
end

-- Start / Stop & Roles
function Module:SetPullTarget()
    if self:IsBusyPulling() then
        Logger.log_info("PULL: Puller is busy - ignoring manual pull request.")
        return
    end
    local targetId = mq.TLO.Target.ID()
    if (targetId or 0) == 0 then return end
    self.TempSettings.TargetSpawnID = targetId
    table.insert(self.TempSettings.PullTargets, mq.TLO.Spawn("id " .. targetId))
end

function Module:StartPuller()
    if Config:GetSetting('DoPull') == true then return end
    self.TempSettings.DeathResumeFreePass = nil
    Modules:ExecModule("Movement", "ClearDeathCampHold")
    self.TempSettings.PausePulls = false
    -- starting: the entry boxes are authoritative, commit them first
    if not self:CommitLocEntry() then return end
    local intent = self:CurrentIntent()
    if not intent.canStart then
        Logger.log_error("%s", intent.gapReason or intent.text)
        return
    end
    if Modules:ExecModule("Movement", "GetCampData").returnToCamp and (self:GetModePolicy().family ~= 'camp' or self.TempSettings.CampTravelLoc) then
        Modules:ExecModule("Movement", "CampOff")
    end
    if Config:GetSetting('ManagePeerMovement') then
        local zoneScope = Config:GetSetting('PeerMovementScope') == 2
        if self:GetModePolicy().family ~= 'camp' then
            Comms.SendPeersDoCmd(zoneScope and Comms.GetZonePeers(false) or self:GroupOrRaidPeers(false), "/rgl chaseon " .. mq.TLO.Me.CleanName())
        elseif not Modules:ExecModule("Movement", "GetCampData").returnToCamp then
            if not self.TempSettings.CampTravelLoc then
                Comms.SendPeersDoCmd(zoneScope and Comms.GetZonePeers(true) or self:GroupOrRaidPeers(true), "/rgl campon")
                self:SetLastPullOrCombatEndedTimer()
            else
                local escortPeers = zoneScope and Comms.GetZonePeers(false) or self:GroupOrRaidPeers(false)
                Comms.SendPeersDoCmd(escortPeers, "/rgl chaseon " .. mq.TLO.Me.CleanName())
                if #escortPeers > 0 then
                    self.TempSettings.EscortScopeWord = zoneScope and "in-zone peers" or ((mq.TLO.Raid.Members() or 0) > 0 and "raid" or "group")
                    self.TempSettings.EscortPeers = escortPeers
                end
            end
        end
    elseif self:GetModePolicy().family == 'camp' and not self.TempSettings.CampTravelLoc
        and not Modules:ExecModule("Movement", "GetCampData").returnToCamp then
        Core.DoCmd("/rgl campon")
        self:SetLastPullOrCombatEndedTimer()
    end
    -- we are on the render thread, so just prime the timer; the first pull tick fires move abilities right away
    self.TempSettings.LastMoveAbilityCheck = 0
    Config:SetSetting('DoPull', true)
    self:SetRoles()
end

function Module:ClearObjective()
    self.TempSettings.FightTo = nil
    self.TempSettings.HuntOrigin = nil
    self.TempSettings.HuntAnchor = nil
    self.TempSettings.LocEntryY, self.TempSettings.LocEntryX, self.TempSettings.LocEntryZ = "", "", ""
end

function Module:StopPuller()
    if Config:GetSetting('DoPull') == false then return end
    self.TempSettings.PausePulls = false
    self:ClearEscortState()
    if (self.TempSettings.CampTravelLoc or self.TempSettings.Travel) and mq.TLO.Navigation.Active() then
        Movement:DoNav(false, "stop log=off")
    end
    self.TempSettings.CampTravelLoc = nil
    self.TempSettings.Travel = nil
    Config:SetSetting('DoPull', false)
    self:SetRoles()
    self:SetPullState(PullStates.PULL_IDLE, "")
end

function Module:Announce(who, message)
    Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", who, message), Config:GetSetting('PullAnnounceGroup'), Config:GetSetting('PullAnnounce'),
        Config:GetSetting('AnnounceToRaidIfInRaid'))
end

function Module:AnnounceStop(message, clearObjective)
    Logger.log_info("\ay%s\ax", message)
    self:Announce("None", message)
    if clearObjective then self:ClearObjective() end
    self:StopPuller()
    self:SetPullState(PullStates.PULL_IDLE, "")
end

function Module:SetRoles()
    if Config:GetSetting('AutoSetRoles') and mq.TLO.Group.Leader() == mq.TLO.Me.DisplayName() then
        -- in non-camp modes we follow around.
        local policy = self:GetModePolicy()
        if policy.family == 'camp' then
            Core.DoCmd("/grouproles %s %s 3", Config:GetSetting('DoPull') and "set" or "unset", mq.TLO.Me.DisplayName()) -- set puller
        end
        Core.DoCmd("/grouproles set %s 2", Globals.MainAssist)                                                           -- set MA
    end
end

function Module:FixPullerMerc()
    local pending = self.TempSettings.PullerMercPending
    if pending then
        local merc = mq.TLO.Spawn(pending.mercId)
        if not merc() or (merc.Distance() or 0) < Config:GetSetting('AutoCampRadius') or Globals.GetTimeSeconds() >= pending.deadline then
            Core.DoCmd("/grouproles set %s 3", pending.owner)
            self.TempSettings.PullerMercPending = nil
        end
        return
    end

    if Globals.GetTimeSeconds() - self.TempSettings.LastPullerMercCheck < 15 then return end
    self.TempSettings.LastPullerMercCheck = Globals.GetTimeSeconds()

    if mq.TLO.Group.Leader() ~= mq.TLO.Me.DisplayName() then return end

    local groupCount = mq.TLO.Group.Members()

    for i = 1, groupCount do
        local merc = mq.TLO.Group.Member(i)

        if merc and merc() and Targeting.TargetIsType("Mercenary", merc) and merc.Owner.DisplayName() == mq.TLO.Group.Puller() then
            if (merc.Distance() or 0) > Config:GetSetting('AutoCampRadius') and (merc.Owner.Distance() or 0) < Config:GetSetting('AutoCampRadius') then
                Core.DoCmd("/grouproles unset %s 3", merc.Owner.DisplayName())
                self.TempSettings.PullerMercPending = { mercId = merc.ID(), owner = merc.Owner.DisplayName(), deadline = Globals.GetTimeSeconds() + 10, }
                return
            end
        end
    end
end

function Module:ResetPullMachine()
    if self.TempSettings.Attempt or self.TempSettings.Travel or self.TempSettings.CampTravelLoc then
        if mq.TLO.Navigation.Active() then
            Movement:DoNav(false, "stop log=off")
        end
    end
    self:ClearEscortState()
    self.TempSettings.Attempt = nil
    self.TempSettings.Travel = nil
    self.TempSettings.CampTravelLoc = nil
    self.TempSettings.TargetSpawnID = 0
    self.TempSettings.UnreachableSince = 0
    self.TempSettings.TravelFailSince = 0
    self:SetPullState(PullStates.PULL_IDLE, "")
end

-- Lifecycle Handlers
--- True when we are back in the camp zone and close enough to the camp or the spot we died to resume pulling.
function Module:NearDeathReturnPoint(campData)
    if not Modules:ExecModule("Movement", "InCampZone") then return false end
    local radius = Config:GetSetting('CampExceedRadius')
    local spot = self.TempSettings.DeathSpot
    if spot and Math.GetDistance(mq.TLO.Me.Y(), mq.TLO.Me.X(), spot.y, spot.x) <= radius then return true end
    return Math.GetDistance(mq.TLO.Me.Y(), mq.TLO.Me.X(), campData.campSettings.AutoCampY, campData.campSettings.AutoCampX) <= radius
end

function Module:OnDeath()
    -- Death Handler
    self:ResetPullMachine()
    if Config:GetSetting('StopPullAfterDeath') then
        Config:SetSetting('DoPull', false)
    elseif Config:GetSetting('DoPull') then
        -- pause pulls but set up to resume: keep the camp through the death, expect the zone-out to bind, and remember where we died
        Config:SetSetting('DoPull', false)
        Modules:ExecModule("Movement", "ArmDeathCampHold")
        self.TempSettings.DeathResumeFreePass = true
        self.TempSettings.DeathSpot = { y = mq.TLO.Me.Y(), x = mq.TLO.Me.X(), z = mq.TLO.Me.Z(), }
    end
end

function Module:OnZone()
    -- Zone Handler
    self:ResetPullMachine()
    local campData = Modules:ExecModule("Movement", "GetCampData")
    if Config:GetSetting('StopPullAfterDeath') then
        Config:SetSetting('DoPull', false)
    elseif campData.deathCampHold then
        -- we died with pulls on: the first zone (to our bind) is expected, do nothing yet
        if self.TempSettings.DeathResumeFreePass then
            self.TempSettings.DeathResumeFreePass = nil
            Config:SetSetting('DoPull', false)
        else
            -- any zone after that: resume if it put us near the camp or where we died, otherwise drop the camp
            if self:NearDeathReturnPoint(campData) then
                Modules:ExecModule("Movement", "ClearDeathCampHold")
                Config:SetSetting('DoPull', true)
            else
                Modules:ExecModule("Movement", "CampOff")
                Config:SetSetting('DoPull', false)
            end
        end
    else
        Config:SetSetting('DoPull', false)
    end
    self:ClearObjective()
    self.TempSettings.LocationNameEdits = {}
    self.TempSettings.LocationsToDelete = {}
    self:ClearIgnoreList()
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    return Module.Constants.PullStatesIDToName[self.TempSettings.PullState]
end

function Module:SetLastPullOrCombatEndedTimer()
    self.TempSettings.LastPullOrCombatEnded = Globals.GetTimeSeconds()
    Logger.log_verbose("Last Pull or Combat Ended: %s", Globals.GetTimeSeconds())
end

return Module
