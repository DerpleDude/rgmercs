-- Sample Pull Class Module
local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Math      = require('utils.math')
local Combat    = require("utils.combat")
local Casting   = require("utils.casting")
local Core      = require("utils.core")
local Movement  = require("utils.movement")
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")
local Comms     = require("utils.comms")
local Tables    = require("utils.tables")
local Modules   = require("utils.modules")
local Strings   = require("utils.strings")
local Files     = require("utils.files")
local Logger    = require("utils.logger")
local Events    = require("utils.events")
local Set       = require("mq.Set")
local Base      = require("modules.base")
local Icons     = require('mq.ICONS')

local Module    = { _version = '0.1a', _name = "Pull", _author = 'Derple', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                                = {}

Module.TempSettings                       = {}
Module.TempSettings.BuffCount             = 0
Module.TempSettings.LastPullOrCombatEnded = Globals.GetTimeSeconds()
Module.TempSettings.TargetSpawnID         = 0
Module.TempSettings.CurrentWP             = 1
Module.TempSettings.ReachedWP             = false
Module.TempSettings.PullTargets           = {}
Module.TempSettings.PullTargetsMetaData   = {}
Module.TempSettings.PullIgnoreTargets     = {}
Module.TempSettings.AbortPull             = false
Module.TempSettings.PullListUpdated       = false
Module.TempSettings.PullID                = 0
Module.TempSettings.LastPullAbilityCheck  = 0
Module.TempSettings.LastPullerMercCheck   = 0
Module.TempSettings.LastFoundGroupCorpse  = 0
Module.TempSettings.HuntX                 = 0
Module.TempSettings.HuntY                 = 0
Module.TempSettings.HuntZ                 = 0
Module.TempSettings.MyPaths               = {}
Module.TempSettings.LastGroupUpdateTime   = Globals.GetTimeSeconds()
Module.TempSettings.SelectedPath          = "None"
Module.TempSettings.PullAttemptStarted    = 0
Module.TempSettings.PullRadius            = 0
Module.TempSettings.WayPointsToDelete     = Set.new({})
Module.TempSettings.PausePulls            = false

local PullStates                          = {
    ['PULL_IDLE']               = 1,
    ['PULL_GROUPWATCH_WAIT']    = 2,
    ['PULL_NAV_INTERRUPT']      = 3,
    ['PULL_SCAN']               = 4,
    ['PULL_PULLING']            = 5,
    ['PULL_MOVING_TO_WP']       = 6,
    ['PULL_NAV_TO_TARGET']      = 7,
    ['PULL_RETURN_TO_CAMP']     = 8,
    ['PULL_WAITING_ON_MOB']     = 9,
    ['PULL_WAITING_SHOULDPULL'] = 10,
    ['PULL_MOVING_CHECKS']      = 11,
}

local PullStateDisplayStrings             = {
    ['MERCS_PAUSED']            = { Display = Icons.MD_REPORT_PROBLEM, Text = "RGMercs Main Paused", Color = 'Red', },
    ['PULL_IDLE']               = { Display = Icons.FA_CLOCK_O, Text = "Idle", Color = 'Green', },
    ['PULL_GROUPWATCH_WAIT']    = { Display = Icons.MD_GROUP, Text = "Waiting on GroupWatch", Color = 'Yellow', },
    ['PULL_NAV_INTERRUPT']      = { Display = Icons.MD_PAUSE_CIRCLE_OUTLINE, Text = "Navigation Interrupted", Color = 'Red', },
    ['PULL_SCAN']               = { Display = Icons.FA_EYE, Text = "Scanning for Targets", Color = 'Green', },
    ['PULL_PULLING']            = { Display = Icons.FA_BULLSEYE, Text = "Pulling", Color = 'Red', },
    ['PULL_MOVING_TO_WP']       = { Display = Icons.MD_DIRECTIONS_RUN, Text = "Moving to Next WP", Color = 'Yellow', },
    ['PULL_NAV_TO_TARGET']      = { Display = Icons.MD_DIRECTIONS_RUN, Text = "Naving to Target", Color = 'Yellow', },
    ['PULL_RETURN_TO_CAMP']     = { Display = Icons.FA_FREE_CODE_CAMP, Text = "Returning to Camp", Color = 'Green', },
    ['PULL_WAITING_ON_MOB']     = { Display = Icons.FA_CLOCK_O, Text = "Waiting on Mob", Color = 'Yellow', },
    ['PULL_WAITING_SHOULDPULL'] = { Display = Icons.FA_CLOCK_O, Text = "Waiting for Should Pull", Color = 'Red', },
    ['PULL_MOVING_CHECKS']      = { Display = Icons.FA_EYE, Text = "Rechecking Actions", Color = 'Yellow', },
}

local PullStatesIDToName                  = {}
for k, v in pairs(PullStates) do PullStatesIDToName[v] = k end

Module.TempSettings.PullState          = PullStates.PULL_IDLE
Module.TempSettings.PullStateReason    = ""

Module.Constants                       = {}
Module.Constants.PullModes             = {
    "Normal",
    "Chain",
    "Hunt",
    "Farm",
}

Module.Constants.PullAbilities         = {
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
            local rangedTypes = Set.new({ "archery", "bow", "throwingv1", "throwing", "throwingv2", "ammo", })
            return rangedTypes:contains(rangedType)
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

local PullAbilityIDToName              = {}

Module.TempSettings.ValidPullAbilities = {}

Module.DefaultConfig                   = {
    -- custom: noshow in options
    ['DoPull']                                 = {
        DisplayName = "Enable Pulling",
        Tooltip = "Enable pulling",
        Default = false,
        Type = "Custom",
        OnChange = function(self) Movement.UpdateMapRadii() end,
    },
    ['PullAbility']                            = {
        DisplayName = "Pull Ability",
        Tooltip = "What should we pull with?",
        Default = 1,
        Type = "Custom",
        FAQ = "I don't see an ability that I want to use in the Pull Ability list. How can I add it?",
        Answer = "Default pull abilities can generally be added by feedback. Alternatively, they can be added via customization of a class config.",
    },
    ['PullMode']                               = {
        DisplayName = "Pull Mode",
        Type = "Custom",
        Default = 1,
        Min = 1,
        Max = 4,
        FAQ = "What are the different Pull modes and how do they work?",
        Answer = "You can adjust Pull Modes on the Pull module tab.\n\n" ..
            "Normal: Attempt to pull single mobs back to a static camp location.\n\n" ..
            "Chain: Continuously pull single mobs back to a static camp location until the chain count has been reached.\n\n" ..
            "Hunt: Move from target to target within a defined circular area, fighting as you go.\n\n" ..
            "Farm: Move from waypoint to waypoint, hunting mobs in a defined radius from each.",
    },
    ['FarmWayPoints']                          = {
        DisplayName = "Farming Waypoints",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        FAQ = "How do I use Farm mode for pulling?",
        Answer = "Farm mode needs to have valid farming waypoints added to move between. You can add points in the Pull module tab.",
    },
    ['PullAllowList']                          = {
        DisplayName = "Allow List",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        FAQ = "I only want to attack a specific set of mobs in my pull mode, how do I set this up?",
        Answer = "In the Pull Allow List (found on your Pull module tab), you will find a button to add your target to that list.\n\n" ..
            "Alternatively, you can use /rgl pullallow <mobname> or /rgl pullallowrm <mobname> to adjust this list from the command line.\n\n" ..
            "We will still engage mobs that aggro us, regardless of their abscence from this list.",
    },
    ['PullDenyList']                           = {
        DisplayName = "Deny List",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = {},
        FAQ = "I want to avoid pulling a specific mob (or mobs) in my pull mode, can I do that?",
        Answer = "In the Pull Deny List (found on your Pull module tab), you will find a button to add your target to that list.\n\n" ..
            "Alternatively, you can use /rgl pulldeny <mobname> or /rgl pulldenyrm <mobname> to adjust this list from the command line.\n\n" ..
            "We will still engage mobs that aggro us, regardless of their presence on this list.",
    },
    ['PullSafeZones']                          = {
        DisplayName = "SafeZones",
        Category = "",
        Tooltip = "",
        Type = "Custom",
        Default = { "poknowledge", "neighborhood", "guildhall", "guildlobby", "bazaar", },
        FAQ = "How do I make it so my puller doesn't pull in certain zones?",
        Answer = "You can add a zone to the [PullSafeZones] and it will not pull in that zone.\n" ..
            "This list is found in /config/rgmercs/PCConfigs/Pull_<Server>_<Character>.lua",
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
        Tooltip = "Farm mode: Wait for x seconds before moving to the next WP. Timer resets if a pull target is found at the current WP.",
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
        Tooltip =
        "As the group leader, automatically update MA and Puller group roles when pulling is enabled. We will set ourselves as puller, and attempt to set the assigned RGMercs MA as the group MA.",
        Default = true,
    },
    ['PullDebuffed']                           = {
        DisplayName = "Pull While Debuffed",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 4,
        Tooltip = "Pull in spite of being debuffed (Not ignored: Rez Sickness, Root.)",
        Default = false,
        ConfigType = "Advanced",
    },
    ['PullMobsInWater']                        = {
        DisplayName = "Pull Mobs In Water",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 5,
        Tooltip = "Allow pulling mobs that are in water. Check your EB effects if enabled!.",
        Default = false,
    },
    ['PullBackwards']                          = {
        DisplayName = "Pull Facing Backwards",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 6,
        Tooltip = "When moving back to camp, back up and continually face your target. (Prevents stuns, etc.)",
        Default = true,
    },
    ['ChainCount']                             = {
        DisplayName = "Chain Count",
        Group = "Movement",
        Header = "Pulling",
        Category = "Pull Rules",
        Index = 7,
        Tooltip = "Number of mobs in chain pull mode on xtarg before we stop pulling",
        Default = 3,
        FAQ = "How do I pull using the Chain mode? What is the Chain Count?",
        Answer = "Chain mode is intended for a non-tank, non-assist puller to pull a stream of mobs back to a camp, one at a time.\n\n" ..
            "   Once the puller no longer has aggro, it should leave the camp to pull again, until the number of haters on xtarget count matches or exceeds the Chain Count.",
        Min = 1,
        Max = 100,
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
        Tooltip = "Disable Pulling once you have died (even if you are rezzed).",
        Default = true,
    },
    -- Distance
    ['PullRadius']                             = {
        DisplayName = "Pull Radius (Camp)",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 1,
        Tooltip = "Camp Mode: The distance to scan from your camp for valid pull targets.",
        Default = 350,
        Min = 1,
        Max = 10000,
        OnChange = function(self) Movement.UpdateMapRadii() end,
    },
    ['PullRadiusHunt']                         = {
        DisplayName = "Pull Radius (Hunt)",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 2,
        Tooltip = "Hunt Mode: The distance to scan from your starting hunt position for valid pull targets.",
        Default = 500,
        Min = 1,
        Max = 10000,
    },
    ['PullRadiusFarm']                         = {
        DisplayName = "Pull Radius (Farm)",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 3,
        Tooltip = "Farm Mode: The distance to scan from your current farm waypoint for valid pull targets.",
        Default = 90,
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
        FAQ = "Why does my puller stop every so often before running again to the same target, or change targets while pulling?",
        Answer = "The puller will periodically reassess targets if navigation has been active for a while to improve efficiency.\n" ..
            "The time period can be adjusted with the Max Move Time setting in the Pulling Distance category.",
    },
    ['HuntFromPlayer']                         = {
        DisplayName = "Hunt from Player",
        Group = "Movement",
        Header = "Pulling",
        Category = "Distance",
        Index = 7,
        Tooltip = "Hunt Mode: Reset the starting location to your current location after every pull. In most cases, this will allow zone-wide roaming.",
        Default = false,
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
        CatGroup = "Movement",
        Header = "Pulling",
        Category = "Puller Vitals",
        egory = "Puller",
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
        Default = mq.TLO.Me.Level() - 3,
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
    ['GroupWatch']                             = {
        DisplayName = "Enable Group Watch",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 1,
        Tooltip = "Watch the mana and/or endurance of the groupmembers selected below.",
        Default = true,
    },
    ['GroupWatchF2']                           = {
        DisplayName = mq.TLO.Group.Member(1)() and string.format("Watch %s", mq.TLO.Group.Member(1).CleanName()) or "No GroupMember",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 2,
        Tooltip = "Watch the mana and/or endurance of the selected groupmember (if present).",
        Default = false,
    },
    ['GroupWatchF3']                           = {
        DisplayName = mq.TLO.Group.Member(2)() and string.format("Watch %s", mq.TLO.Group.Member(2).CleanName()) or "No GroupMember",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 3,
        Tooltip = "Watch the mana and/or endurance of the selected groupmember (if present).",
        Default = false,
    },
    ['GroupWatchF4']                           = {
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 4,
        Tooltip = "Watch the mana and/or endurance of the selected groupmember (if present).",
        Default = false,
    },
    ['GroupWatchF5']                           = {
        DisplayName = mq.TLO.Group.Member(4)() and string.format("Watch %s", mq.TLO.Group.Member(4).CleanName()) or "No GroupMember",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 5,
        Tooltip = "Watch the mana and/or endurance of the selected groupmember (if present).",
        Default = false,
    },
    ['GroupWatchF6']                           = {
        DisplayName = mq.TLO.Group.Member(5)() and string.format("Watch %s", mq.TLO.Group.Member(5).CleanName()) or "No GroupMember",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 6,
        Tooltip = "Watch the mana and/or endurance of the selected groupmember (if present).",
        Default = false,
    },
    ['GroupWatchEnd']                          = {
        DisplayName = "Watch Group Endurance",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 9,
        Tooltip = "Check for endurance when checking selected group members' vitals.",
        Default = false,
    },
    ['GroupWatchStopPct']                      = {
        DisplayName = "Pulling Pause %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 7,
        Tooltip = "Stop pulls when a selected groupmembers' vitals fall under this percent.",
        Default = 40,
        Min = 1,
        Max = 100,
    },
    ['GroupWatchStartPct']                     = {
        DisplayName = "Pulling Resume %",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 8,
        Tooltip = "Resume pulls when a selected groupmembers' vitals climb above this percent.",
        Default = 80,
        Min = 1,
        Max = 100,
    },
    ['PullWaitCorpse']                         = {
        DisplayName = "Hold for Corpses",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 10,
        Tooltip = "Hold pulls while we detect any groupmember's corpse in the vicinity.",
        Default = true,
    },
    ['WaitAfterRez']                           = {
        DisplayName = "Delay After Rez",
        Group = "Movement",
        Header = "Pulling",
        Category = "Group Vitals",
        Index = 11,
        Tooltip = "If the puller detected a group corpse and held pulls, allow x seconds for the group to rebuff after the corpse is rezzed.\n" ..
            "**Only respected when \"Hold for Corpses\" is enabled and a corpse was detected by that process!**",
        Default = 0,
        Min = 0,
        Max = 90,
    },
}

Module.CommandHandlers                 = {
    pulltarget = {
        usage = "/rgl pulltarget",
        about = "Pulls your current target using the currently selected Pull Ability.",
        handler = function(self, ...)
            self:SetPullTarget()
            return true
        end,
    },
    pullstart = {
        usage = "/rgl pullstart",
        about = "Enables pulling in the currently selected Pull Mode.",
        handler = function(self, ...)
            self:StartPuller()
            return true
        end,
    },
    pullstop = {
        usage = "/rgl pullstop",
        about = "Disables the active Pull Mode.",
        handler = function(self, ...)
            self:StopPuller()
            return true
        end,
    },
    pulldeny = {
        usage = "/rgl pulldeny \"<name>\"",
        about = "Adds <name> to the Pull Deny List. Ensure quotes are used on multi-word mob names!",
        handler = function(self, name)
            if not self:IsMobInList("PullDenyList", name) then
                self:AddMobToList("PullDenyList", name)
            end
            return true
        end,
    },
    pullallow = {
        usage = "/rgl pullallow \"<name>\"",
        about = "Adds <name> to the Pull Allow List. Ensure quotes are used on multi-word mob names!",
        handler = function(self, name)
            if not self:IsMobInList("PullAllowList", name) then
                self:AddMobToList("PullAllowList", name)
            end
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
        usage = "/rgl pulldenyrm \"<name>\"",
        about = "Removes \"<name>\" from the Pull Deny List. Ensure quotes are used on multi-word mob names!",
        handler = function(self, name)
            local zoneAllowList = Config:GetSetting('PullDenyList')[mq.TLO.Zone.ShortName()]
            if name and zoneAllowList then
                for idx, mobName in ipairs(zoneAllowList) do
                    if mobName:lower() == name:lower() then
                        self:DeleteMobFromList("PullDenyList", idx)
                        break
                    end
                end
            else
                Logger.log_error("Pull Deny Remove: Please supply a valid name to remove!")
            end
            return true
        end,
    },
    pullallowrm = {
        usage = "/rgl pullallowrm \"<name>\"",
        about = "Removes \"<name>\" from the Pull Allow List. Ensure quotes are used on multi-word mob names!",
        handler = function(self, name)
            local zoneAllowList = Config:GetSetting('PullAllowList')[mq.TLO.Zone.ShortName()]
            if name and zoneAllowList then
                for idx, mobName in ipairs(zoneAllowList) do
                    if mobName:lower() == name:lower() then
                        self:DeleteMobFromList("PullAllowList", idx)
                        break
                    end
                end
            else
                Logger.log_error("Pull Allow Remove: Please supply a valid name to remove!")
            end
            return true
        end,
    },
    setwpid = {
        usage = "/rgl setwpid <id>",
        about = "Set the current waypoint to <id>.",
        handler = function(self, id)
            local wpID = tonumber(id) or 0

            local farmWPs = Config:GetSetting('FarmWayPoints')
            local zoneWPs = farmWPs[mq.TLO.Zone.ShortName()] or {}

            if wpID > 0 and wpID <= #zoneWPs then
                self.TempSettings.CurrentWP = wpID
                Logger.log_info("Current farm waypoint set to %d", wpID)
            else
                Logger.log_error("Invalid waypoint ID! Please provide a number between 1 and %d", #zoneWPs)
            end
            return true
        end,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:LoadSettings()
    Base.LoadSettings(self)

    -- turn off at startup for safety
    Config:SetSetting('DoPull', false)
end

---@param id number
---@return string
function Module:getPullAbilityDisplayName(id)
    local displayName = self.TempSettings.ValidPullAbilities[id].DisplayName

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
    PullAbilityIDToName = tmpPullAbilityIDToName
end

function Module:OnCombatModeChanged()
    self:SetValidPullAbilities()
end

function Module:RenderMobList(displayName, settingName)
    if ImGui.CollapsingHeader(string.format("Pull %s", displayName)) then
        if mq.TLO.Target() and Targeting.TargetIsType("NPC") then
            ImGui.PushID("##_small_btn_allow_target_" .. settingName)
            if ImGui.SmallButton(string.format("Add Target To %s", displayName)) then
                local targetName = mq.TLO.Target.CleanName()
                if not self:IsMobInList(settingName, targetName, false) then
                    self:AddMobToList(settingName, targetName)
                end
            end
            ImGui.PopID()
        end

        if ImGui.BeginTable("settingName", 4, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 40.0)
            ImGui.TableSetupColumn('Count', (ImGuiTableColumnFlags.WidthFixed), 40.0)
            ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 150.0)
            ImGui.TableSetupColumn('Controls', (ImGuiTableColumnFlags.WidthFixed), 80.0)
            ImGui.TableHeadersRow()

            for idx, mobName in ipairs(Config:GetSetting(settingName)[mq.TLO.Zone.ShortName()] or {}) do
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

function Module:RenderPullTargets()
    if ImGui.BeginTable("PullTargets", 5, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Index', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthFixed), 250.0)
        ImGui.TableSetupColumn('Level', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Distance', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthFixed), 160.0)
        ImGui.TableHeadersRow()

        for idx, spawn in ipairs(self.TempSettings.PullTargets) do
            if spawn.ID() > 0 then
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

function Module:RenderIgnoreTargets()
    ImGui.PushID("##_small_btn_clear_ignore_list")
    if ImGui.SmallButton("Clear Pull Ignore List") then
        self:ClearIgnoreList()
    end
    ImGui.PopID()
    if ImGui.BeginTable("PullIgnoreTargets", 5, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Index', (ImGuiTableColumnFlags.WidthFixed), 20.0)
        ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.None), 250.0)
        ImGui.TableSetupColumn('Level', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Distance', (ImGuiTableColumnFlags.WidthFixed), 60.0)
        ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthFixed), 160.0)
        ImGui.TableHeadersRow()

        for idx, spawn in ipairs(self.TempSettings.PullIgnoreTargets) do
            if spawn.ID() > 0 then
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

function Module:ShouldRender()
    return true
end

function Module:Render()
    local controlPadding = Base.Render(self)

    local pressed

    -- dead... whoops
    if mq.TLO.Me.Hovering() then return end

    if self.ModuleLoaded and Globals.SubmodulesLoaded then
        if ImGui.BeginTable("PullControls", 3, bit32.bor(ImGuiTableFlags.NoBordersInBody), ImVec2(ImGui.GetWindowWidth() - (controlPadding + 20), 0)) then
            if mq.TLO.Navigation.MeshLoaded() then
                ImGui.TableNextColumn()
                if Config:GetSetting('DoPull') then
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionFailColor)
                else
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionPassColor)
                end
                if ImGui.Button(Config:GetSetting('DoPull') and "Stop Pulls" or "Start Pulls", -1, 25) then
                    Config:SetSetting('DoPull', not Config:GetSetting('DoPull'))
                    Module:SetRoles()
                    self:SaveSettings(false)
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

            local campData = Modules:ExecModule("Movement", "GetCampData")

            --            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImGui.GetStyle().FramePadding.x, 0)
            ImGui.TableNextColumn()
            if campData.returnToCamp then
                if ImGui.Button("Break Group Camp", -1, 18) then
                    Core.DoGroupOrRaidCmd("/rgl campoff")
                end
            else
                if ImGui.Button("Set Group Camp Here", -1, 18) then
                    Core.DoGroupOrRaidCmd("/rgl campon")
                end
            end
            ImGui.TableNextColumn()
            if campData.returnToCamp then
                if ImGui.Button("Break My Camp", -1, 18) then
                    Core.DoCmd("/rgl campoff")
                end
            else
                if ImGui.Button("Set My Camp Here", -1, 18) then
                    Core.DoCmd("/rgl campon")
                end
            end
            --ImGui.PopStyleVar(1)
            ImGui.EndTable()
        end

        local pullMode = Config:GetSetting('PullMode')
        pullMode, pressed = ImGui.Combo("Pull Mode", pullMode, self.Constants.PullModes, #self.Constants.PullModes)
        if pressed then
            Config:SetSetting('PullMode', pullMode)
        end
        if ImGui.IsItemHovered() then
            Ui.Tooltip("Please refer to the in-game FAQ for a description of Pull Modes.")
        end
        if #self.TempSettings.ValidPullAbilities > 0 then
            local pullAbility = Config:GetSetting('PullAbility')
            pullAbility, pressed = ImGui.Combo("Pull Ability", pullAbility, function(id) return self:getPullAbilityDisplayName(id) end,
                #self.TempSettings.ValidPullAbilities) --, self.TempSettings.ValidPullAbilities, #self.TempSettings.ValidPullAbilities)
            if pressed then
                Config:SetSetting('PullAbility', pullAbility)
            end
        end

        local nextPull = Config:GetSetting('PullDelay') - (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded)
        if nextPull < 0 then nextPull = 0 end
        if ImGui.BeginTable("PullState", 2, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableNextColumn()
            Ui.RenderText("Pull State")
            ImGui.TableNextColumn()
            local stateData = Globals.PauseMain and PullStateDisplayStrings['MERCS_PAUSED'] or PullStateDisplayStrings[PullStatesIDToName[self.TempSettings.PullState]]
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
            ImGui.TableNextColumn()
            Ui.RenderText("Pull ID")
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(self.TempSettings.PullID))
            ImGui.TableNextColumn()
            Ui.RenderText("Pull Target Count")
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(#self.TempSettings.PullTargets))
            ImGui.TableNextColumn()
            Ui.RenderText("Hunt X,Y,Z")
            ImGui.TableNextColumn()
            Ui.RenderText("%d, %d, %d", self.TempSettings.HuntX, self.TempSettings.HuntY, self.TempSettings.HuntZ)
            ImGui.TableNextColumn()
            Ui.RenderText("Current WP")
            ImGui.TableNextColumn()
            local wpId = self:GetCurrentWpId()
            local wpData = self:GetWPById(wpId)
            Ui.RenderText(wpId == 0 and "<None>" or string.format("%d [y: %0.2f, x: %0.2f, z: %0.2f]", wpId, wpData.y, wpData.x, wpData.z))
            ImGui.TableNextColumn()
            Ui.RenderText("Buff Count")
            ImGui.TableNextColumn()
            Ui.RenderText("%s", self.TempSettings.BuffCount)
            ImGui.EndTable()
        end

        ImGui.NewLine()
        ImGui.Separator()
        Ui.RenderText("Note: Allow List will supersede Deny List")
        self:RenderMobList("Allow List", "PullAllowList")
        self:RenderMobList("Deny List", "PullDenyList")
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

        if ImGui.CollapsingHeader("Farm Waypoints") then
            ImGui.PushID("##_small_btn_create_wp")
            if ImGui.SmallButton("Create Waypoint Here") then
                self:CreateWayPointHere()
            end
            ImGui.PopID()
            if self.TempSettings.MyPaths[mq.TLO.Zone.ShortName()] then
                ImGui.SameLine()
                if ImGui.SmallButton('Reload Paths##ReloadPaths') then
                    self.TempSettings.MyPaths = dofile(string.format('%s/MyUI/MyPaths/MyPaths_Paths.lua', mq.configDir))
                end
                ImGui.SetNextItemWidth(120)
                if ImGui.BeginCombo("MyPaths Path Avail##SelectPath", self.TempSettings.SelectedPath) then
                    for name, data in pairs(self.TempSettings.MyPaths[mq.TLO.Zone.ShortName()]) do
                        local isSelected = name == self.TempSettings.SelectedPath
                        if ImGui.Selectable(name, isSelected) then
                            self.TempSettings.SelectedPath = name
                        end
                    end
                    ImGui.EndCombo()
                end
                if self.TempSettings.SelectedPath ~= "None" then
                    local farmWayPoints = Config:GetSetting('FarmWayPoints')
                    farmWayPoints[mq.TLO.Zone.ShortName()] = {}
                    for step, data in pairs(self.TempSettings.MyPaths[mq.TLO.Zone.ShortName()][self.TempSettings.SelectedPath]) do
                        local mpy, mpx, mpz = data.loc:match("([^,]+),%s*([^,]+),%s*([^,]+)")
                        farmWayPoints[mq.TLO.Zone.ShortName()][step] = { x = tonumber(mpx), y = tonumber(mpy), z = tonumber(mpz), }
                    end
                    self.TempSettings.SelectedPath = "None"
                end
            else
                Module.TempSettings.MyPaths = 'None'
            end

            if ImGui.BeginTable("Waypoints", 3, bit32.bor(ImGuiTableFlags.Borders)) then
                ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 40.0)
                ImGui.TableSetupColumn('Loc', (ImGuiTableColumnFlags.WidthStretch), 150.0)
                ImGui.TableSetupColumn('Controls', (ImGuiTableColumnFlags.WidthFixed), 80.0)
                ImGui.TableHeadersRow()

                local waypointList = Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] or {}

                for idx, wpData in ipairs(waypointList) do
                    ImGui.TableNextColumn()
                    Ui.RenderText(tostring(idx))
                    ImGui.TableNextColumn()
                    Ui.NavEnabledLoc(string.format("y: %0.2f, x: %0.2f, z: %0.2f]", wpData.y, wpData.x, wpData.z),
                        string.format("%0.2f, %0.2f, %0.2f", wpData.y, wpData.x, wpData.z))
                    ImGui.TableNextColumn()
                    ImGui.PushID("##_small_btn_set_wp_" .. tostring(idx))
                    if ImGui.SmallButton(Icons.FA_FLAG_CHECKERED) then
                        Core.DoCmd(string.format("/rgl setwpid %d", idx))
                    end
                    Ui.Tooltip("Set Current WP")
                    ImGui.PopID()
                    ImGui.SameLine()
                    ImGui.PushID("##_small_btn_delete_wp_" .. tostring(idx))
                    if ImGui.SmallButton(Icons.FA_TRASH) then
                        self:AddWPToDeleteList(idx)
                    end
                    Ui.Tooltip("Delete Waypoint")
                    ImGui.PopID()
                    ImGui.SameLine()
                    ImGui.PushID("##_small_btn_up_wp_" .. tostring(idx))
                    if idx == 1 then
                        ImGui.InvisibleButton(Icons.FA_CHEVRON_UP, ImVec2(22, 1))
                    else
                        if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then
                            self:MoveWayPointUp(idx)
                        end
                    end
                    ImGui.PopID()
                    ImGui.SameLine()
                    ImGui.PushID("##_small_btn_dn_wp_" .. tostring(idx))
                    if idx == #waypointList then
                        ImGui.InvisibleButton(Icons.FA_CHEVRON_DOWN, ImVec2(22, 1))
                    else
                        if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then
                            self:MoveWayPointDown(idx)
                        end
                    end
                    ImGui.PopID()
                end

                ImGui.EndTable()
            end
        end
    end
end

---@return integer
function Module:GetCurrentWpId()
    if not Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] then return 0 end
    return (self.TempSettings.CurrentWP <= #Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()]) and self.TempSettings.CurrentWP or 0
end

---comment
---@param id number
---@return table
function Module:GetWPById(id)
    return (Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] and
            (id <= #Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()])) and
        Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()][id] or { x = 0, y = 0, z = 0, }
end

---@param listName string
---@return boolean
function Module:HaveList(listName)
    return Config:GetSetting(listName)[mq.TLO.Zone.ShortName()] and #Config:GetSetting(listName)[mq.TLO.Zone.ShortName()] > 0
end

---@param listName string
---@param mobName string
---@param defaultNoList boolean # Default to return if there is no list.
---@return boolean
function Module:IsMobInList(listName, mobName, defaultNoList)
    -- no list so everything is allowed.
    if not self:HaveList(listName) then return defaultNoList end

    for _, v in pairs(Config:GetSetting(listName)[mq.TLO.Zone.ShortName()]) do
        if v == mobName then return true end
    end

    return false
end

---@param list string
---@param mobName string
function Module:AddMobToList(list, mobName)
    Logger.log_debug("Adding \ag%s\ax to Pull %s for zone \ay%s\ax.", mobName, list == "PullAllowList" and "Allow List" or "Deny List",
        mq.TLO.Zone.ShortName())

    local listConfig = Config:GetSetting(list)
    listConfig[mq.TLO.Zone.ShortName()] = listConfig[mq.TLO.Zone.ShortName()] or {}
    table.insert(listConfig[mq.TLO.Zone.ShortName()], mobName)
    Config:SetSetting(list, listConfig)

    -- if we are pulling start over.
    if Config:GetSetting('DoPull') then
        self.TempSettings.PullListUpdated = true
    end
end

---@param list string
---@param idx number
function Module:DeleteMobFromList(list, idx)
    local listConfig = Config:GetSetting(list)
    listConfig[mq.TLO.Zone.ShortName()] = listConfig[mq.TLO.Zone.ShortName()] or {}
    table.remove(listConfig[mq.TLO.Zone.ShortName()], idx)
    Config:SetSetting(list, listConfig)

    -- if we are pulling start over.
    if Config:GetSetting('DoPull') then
        self.TempSettings.PullListUpdated = true
    end
end

function Module:ClearIgnoreList()
    self.TempSettings.PullIgnoreTargets = {}
end

function Module:ValidateIgnoreList()
    for entry, spawn in ipairs(self.TempSettings.PullIgnoreTargets) do
        if spawn.ID() == 0 or spawn.Dead() then
            Logger.log_debug("PULL: Cleaning up ignore list, it seems %s is no longer present.", spawn)
            table.remove(self.TempSettings.PullIgnoreTargets, entry)
        end
    end
end

function Module:IncrementWpId()
    if not Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] then return end

    if (self.TempSettings.CurrentWP + 1) <= #Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] then
        self.TempSettings.CurrentWP = self.TempSettings.CurrentWP + 1
    else
        self.TempSettings.CurrentWP = 1
    end
    Logger.log_verbose("Pull: Incrementing farm waypoint to %d", self.TempSettings.CurrentWP)
end

---@param id number
function Module:MoveWayPointUp(id)
    local newId = id - 1

    if newId < 1 then return end
    if id > #Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] then return end

    local farmWayPoints = Config:GetSetting('FarmWayPoints')
    farmWayPoints[mq.TLO.Zone.ShortName()][newId], farmWayPoints[mq.TLO.Zone.ShortName()][id] =
        farmWayPoints[mq.TLO.Zone.ShortName()][id], farmWayPoints[mq.TLO.Zone.ShortName()][newId]
    Config:SetSetting('FarmWayPoints', farmWayPoints)
end

---@param id number
function Module:MoveWayPointDown(id)
    local newId = id + 1

    if id < 1 then return end
    if newId > #Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()] then return end

    local farmWayPoints = Config:GetSetting('FarmWayPoints')
    farmWayPoints[mq.TLO.Zone.ShortName()][newId], farmWayPoints[mq.TLO.Zone.ShortName()][id] =
        farmWayPoints[mq.TLO.Zone.ShortName()][id], farmWayPoints[mq.TLO.Zone.ShortName()][newId]
    Config:SetSetting('FarmWayPoints', farmWayPoints)
end

function Module:CreateWayPointHere()
    local farmWayPoints = Config:GetSetting('FarmWayPoints')

    farmWayPoints[mq.TLO.Zone.ShortName()] = farmWayPoints[mq.TLO.Zone.ShortName()] or {}
    table.insert(farmWayPoints[mq.TLO.Zone.ShortName()], { x = mq.TLO.Me.X(), y = mq.TLO.Me.Y(), z = mq.TLO.Me.Z(), })
    Config:SetSetting('FarmWayPoints', farmWayPoints)
    Logger.log_info("\axNew waypoint \at%d\ax created at location \ag%02.f, %02.f, %02.f", #farmWayPoints[mq.TLO.Zone.ShortName()],
        mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z())
end

function Module:AddWPToDeleteList(idx)
    self.TempSettings.WayPointsToDelete:add(idx)
end

function Module:ProcessDeleteWPs()
    local wpToDelete = self.TempSettings.WayPointsToDelete:toList()
    while #wpToDelete > 0 do
        local wpId = table.remove(wpToDelete, 1)
        self:DeleteWayPoint(wpId)
    end

    self.TempSettings.WayPointsToDelete = Set.new({})
end

function Module:DeleteWayPoint(idx)
    local farmWayPoints = Tables.DeepCopy(Config:GetSetting('FarmWayPoints'))

    if idx <= #farmWayPoints[mq.TLO.Zone.ShortName()] then
        Logger.log_info("\axWaypoint \at%d\ax at location \ag%s\ax - \arDeleted!\ax", idx, farmWayPoints[mq.TLO.Zone.ShortName()][idx].Loc)
        table.remove(farmWayPoints[mq.TLO.Zone.ShortName()], idx)
        Config:SetSetting('FarmWayPoints', farmWayPoints)
    else
        Logger.log_error("\ar%d is not a valid waypoint ID!", idx)
    end

    local wpCount = #Config:GetSetting('FarmWayPoints')[mq.TLO.Zone.ShortName()]

    if self.TempSettings.CurrentWP > wpCount then
        self.TempSettings.CurrentWP = ((wpCount > 0) and wpCount or 1)
    end
end

-- because mq.TLO.Me.BuffCount() fails to update when gaining buffs without targeting yourself.
-- it does update when you lose buffs though.
---@return number -- # of buffs you have currently
function Module:CountBuffs()
    local count = 0
    for i = 1, mq.TLO.Me.MaxBuffSlots() do
        local buff = mq.TLO.Me.Buff(i)()
        if buff ~= nil then
            count = count + 1
        end
    end
    self.TempSettings.BuffCount = count
    return count
end

---@param campData table
---@return boolean, string
function Module:ShouldPull(campData)
    local me = mq.TLO.Me

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

    if (me.Rooted.ID() or 0 > 0) then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am rooted!")
        return false, string.format("Rooted")
    end

    if not Config:GetSetting('PullDebuffed') then
        if (me.Snared.ID() or 0 > 0) then
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

        if (me.Poisoned.ID() or 0 > 0) and not (me.Tashed.ID()) or 0 > 0 then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am poisoned!")
            return false, string.format("Poisoned")
        end

        if (me.Diseased.ID() or 0 > 0) then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am diseased!")
            return false, string.format("Diseased")
        end

        if (me.Cursed.ID() or 0 > 0) then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am cursed!")
            return false, string.format("Cursed")
        end

        -- Laz Marr's and GM Buffs are Corruption effects.
        if not Core.OnLaz() and (me.Corrupted.ID() or 0 > 0) then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am corrupted!")
            return false, string.format("Corrupted")
        end
    end

    if Config:GetSetting('PullBuffCount') > 0 then
        if self:CountBuffs() < Config:GetSetting('PullBuffCount') then
            Logger.log_verbose("\ay::PULL:: \arAborted!\ax Waiting for Buffs! BuffCount < %d", Config:GetSetting('PullBuffCount'))
            return false, string.format("BuffCount < %d", Config:GetSetting('PullBuffCount'))
        end
    end

    if self:IsPullMode("Chain") and Targeting.GetXTHaterCount() >= Config:GetSetting('ChainCount') then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax XTargetCount(%d) >= ChainCount(%d)", Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount'))
        return false, string.format("XTargetCount(%d) > ChainCount(%d)", Targeting.GetXTHaterCount(), Config:GetSetting('ChainCount'))
    end

    if not self:IsPullMode("Chain") and Targeting.GetXTHaterCount() > 0 then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax XTargetCount(%d) > 0", Targeting.GetXTHaterCount())
        return false, string.format("XTargetCount(%d) > 0", Targeting.GetXTHaterCount())
    end

    --[[ Why do we do this at all?
    if campData.returnToCamp and Math.GetDistanceSquared(me.X(), me.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > math.max(Config:GetSetting('AutoCampRadius') ^ 2, 200 ^ 2) then
        Logger.log_verbose("\ay::PULL:: \arAborted!\ax I am too far away from camp!")
        Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", "None", "I am too far away from camp - Holding pulls!"), Config:GetSetting('PullAnnounceGroup'),
            Config:GetSetting('PullAnnounce'),
            Config:GetSetting('AnnounceToRaidIfInRaid'))
        return false,
            string.format("I am Too Far (%d) (%d,%d) (%d,%d)", Math.GetDistanceSquared(me.X(), me.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY),
                me.X(), me.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY)
    end
    ]] --


    return true, ""
end

function Module:FarmFullInvActions()
    -- Bags are full. We now try and do the following...
    -- 1. Call a specifical sub defined in rgcustom.inc if it exists
    -- 2. Call origin if we have it and its ready so we can go home and sell
    -- 3. Stop farming
    --/if (${SubDefined[Farm_${Zone.ShortName}_FullInventory]}) {
    --    -/call Farm_${Zone.ShortName}_FullInventory
    -- } else /if (${RG_AAReady[Origin]}) {
    --    /call AANow ${Me.AltAbility[Origin].ID} ${Me.ID}
    -- } else {
    --    /echo Bags are full, can't origin back home. Stopping and beeping.
    --    /rg DoPull 0
    --    /beep
    -- }

    Logger.log_error("\arStopping Pulls - Bags are full!")
    Config:SetSetting('DoPull', false)
    Core.DoCmd("/beep")
end

function Module:RefreshGroupNames()
    -- Update the display names for the group watch members

    if Globals.GetTimeSeconds() - self.TempSettings.LastGroupUpdateTime < 10 then return end
    self.TempSettings.LastGroupUpdateTime = Globals.GetTimeSeconds()

    local groupWatch = {
        'GroupWatchF2',
        'GroupWatchF3',
        'GroupWatchF4',
        'GroupWatchF5',
        'GroupWatchF6',
    }

    for i, id in ipairs(groupWatch) do
        local member = mq.TLO.Group.Member(i)
        self.DefaultConfig[id].DisplayName = member() and string.format("Watch %s", member.CleanName()) or "No GroupMember"
    end
end

---comment
---@param resourceResumePct number -- Resume pulls at this pct
---@param resourcePausePct number -- Hold pulls at this pct
---@param campData table
---@return boolean, string
function Module:CheckGroupForPull(resourceResumePct, resourcePausePct, campData)
    local groupCount = mq.TLO.Group.Members()

    if not groupCount or groupCount == 0 then return true, "" end
    local maxDist = math.max(Config:GetSetting('AutoCampRadius') ^ 2, 200 ^ 2)

    local groupWatch = {
        Config:GetSetting('GroupWatchF2'),
        Config:GetSetting('GroupWatchF3'),
        Config:GetSetting('GroupWatchF4'),
        Config:GetSetting('GroupWatchF5'),
        Config:GetSetting('GroupWatchF6'),
    }

    for i, _ in ipairs(groupWatch) do
        local member = mq.TLO.Group.Member(i)
        if groupWatch[i] and member() and member.ID() > 0 then
            local resourcePct = self.TempSettings.PullState == PullStates.PULL_GROUPWATCH_WAIT and resourceResumePct or resourcePausePct
            if member.PctHPs() < resourcePct then
                Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Low on hp - Holding pulls!"),
                    Config:GetSetting('PullAnnounceGroup'), Config:GetSetting('PullAnnounce'),
                    Config:GetSetting('AnnounceToRaidIfInRaid'))
                Logger.log_verbose("\arMember is low on Health - \ayHolding pulls!\ax\ag ResourcePCT:\ax \at%d \aoStopPct: \at%d \ayStartPct: \at%d \aoPullState: \at%d",
                    resourcePct, resourcePausePct, resourceResumePct, self.TempSettings.PullState)
                return false, string.format("%s Low HP", member.CleanName())
            end
            if member.Class.CanCast() and member.Class.ShortName() ~= "BRD" and member.PctMana() < resourcePct then
                Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Low on mana - Holding pulls!"),
                    Config:GetSetting('PullAnnounceGroup'),
                    Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                Logger.log_verbose("\arMember is low on Mana - \ayHolding pulls!\ax\ag ResourcePCT:\ax \at%d \aoStopPct: \at%d \ayStartPct: \at%d \aoPullState: \at%d",
                    resourcePct, resourcePausePct, resourceResumePct, self.TempSettings.PullState)
                return false, string.format("%s Low Mana", member.CleanName())
            end
            if Config:GetSetting('GroupWatchEnd') and member.Class.ShortName() ~= "BRD" and member.PctEndurance() < resourcePct then
                Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Low on endurance - Holding pulls!"),
                    Config:GetSetting('PullAnnounceGroup'),
                    Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                Logger.log_verbose(
                    "\arMember is low on Endurance - \ayHolding pulls!\ax\ag ResourcePCT:\ax \at%d \aoStopPct: \at%d \ayStartPct: \at%d \aoPullState: \at%d", resourcePct,
                    resourcePausePct, resourceResumePct, self.TempSettings.PullState)
                return false, string.format("%s Low End", member.CleanName())
            end

            if member.Hovering() then
                Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Dead - Holding pulls!"), Config:GetSetting('PullAnnounceGroup'),
                    Config:GetSetting('PullAnnounce'),
                    Config:GetSetting('AnnounceToRaidIfInRaid'))
                return false, string.format("%s Dead", member.CleanName())
            end

            if member.OtherZone() then
                Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Not in Zone - Holding pulls!"),
                    Config:GetSetting('PullAnnounceGroup'),
                    Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                return false, string.format("%s Out of Zone", member.CleanName())
            end

            if campData.returnToCamp then
                if Math.GetDistanceSquared(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > maxDist then
                    Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Too far away - Holding pulls!"),
                        Config:GetSetting('PullAnnounceGroup'),
                        Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                    return false,
                        string.format("%s Too Far (%d) (%d,%d) (%d,%d)", member.CleanName(),
                            Math.GetDistance(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY), member.X(), member.Y(),
                            campData.campSettings.AutoCampX, campData.campSettings.AutoCampY)
                end
            else
                if (member.Distance() or 0) > math.max(Config:GetSetting('AutoCampRadius'), 200) then
                    Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", member.CleanName(), "Too far away - Holding pulls!"),
                        Config:GetSetting('PullAnnounceGroup'),
                        Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                    return false,
                        string.format("%s Too Far (%d) (%d,%d) (%d,%d)", member.CleanName(),
                            Math.GetDistance(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY), member.X(), member.Y(),
                            mq.TLO.Me.X(),
                            mq.TLO.Me.Y())
                end
            end

            if self.Constants.PullModes[Config:GetSetting('PullMode')] == "Chain" then
                if member.ID() == Core.GetMainAssistId() then
                    if campData.returnToCamp and Math.GetDistanceSquared(member.X(), member.Y(), campData.campSettings.AutoCampX, campData.campSettings.AutoCampY) > maxDist then
                        Comms.HandleAnnounce(
                            Comms.FormatChatEvent("Pull", member.CleanName(), string.format("Assist Target is beyond AutoCampRadius from %d, %d, %d : %d. Holding pulls.",
                                campData.campSettings.AutoCampY,
                                campData.campSettings.AutoCampX, campData.campSettings.AutoCampZ, Config:GetSetting('AutoCampRadius'))), Config:GetSetting('PullAnnounceGroup'),
                            Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                        return false, string.format("%s Beyond AutoCampRadius", member.CleanName())
                    end
                else
                    if Math.GetDistanceSquared(member.X(), member.Y(), mq.TLO.Me.X(), mq.TLO.Me.Y()) > maxDist then
                        Comms.HandleAnnounce(
                            Comms.FormatChatEvent("Pull", member.CleanName(),
                                string.format("Assist Target is beyond AutoCampRadius from me : %d. Holding pulls.", Config:GetSetting('AutoCampRadius'))),
                            Config:GetSetting('PullAnnounceGroup'),
                            Config:GetSetting('PullAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                        return false, string.format("%s Beyond AutoCampRadius", member.CleanName())
                    end
                end
            end
        end
    end

    return true, ""
end

function Module:FixPullerMerc()
    if Globals.GetTimeSeconds() - self.TempSettings.LastPullerMercCheck < 15 then return end
    self.TempSettings.LastPullerMercCheck = Globals.GetTimeSeconds()

    if mq.TLO.Group.Leader() ~= mq.TLO.Me.DisplayName() then return end

    local groupCount = mq.TLO.Group.Members()

    for i = 1, groupCount do
        local merc = mq.TLO.Group.Member(i)

        if merc and merc() and Targeting.TargetIsType("Mercenary", merc) and merc.Owner.DisplayName() == mq.TLO.Group.Puller() then
            if (merc.Distance() or 0) > Config:GetSetting('AutoCampRadius') and (merc.Owner.Distance() or 0) < Config:GetSetting('AutoCampRadius') then
                Core.DoCmd("/grouproles unset %s 3", merc.Owner.DisplayName())
                mq.delay("10s", function() return (merc.Distance() or 0) < Config:GetSetting('AutoCampRadius') end)
                Core.DoCmd("/grouproles set %s 3", merc.Owner.DisplayName())
            end
        end
    end
end

function Module:GetPullableSpawns()
    local maxPathRange = Config:GetSetting('MaxPathRange')

    local metaDataCache = {}

    if self:IsPullMode("Farm") then
        self.TempSettings.PullRadius = Config:GetSetting('PullRadiusFarm')
    elseif self:IsPullMode("Hunt") then
        self.TempSettings.PullRadius = Config:GetSetting('PullRadiusHunt')
    else
        self.TempSettings.PullRadius = Config:GetSetting('PullRadius')
    end

    local pullRadiusSqr = self.TempSettings.PullRadius * self.TempSettings.PullRadius

    local spawnFilter = function(spawn)
        if not spawn() or spawn.ID() == 0 then return false end
        if not spawn.Targetable() then return false end
        if spawn.Type() ~= "NPC" and spawn.Type() ~= "NPCPET" then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aois type %s not an NPC or NPCPET -- Skipping", spawn.CleanName(), spawn.ID(),
                spawn.Type())
            return false
        end

        if spawn.Master.Type() == 'PC' then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aois Charmed Pet -- Skipping", spawn.CleanName(), spawn.ID())
            return false
        end

        if Targeting.IsTempPet(spawn) then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aois Temp or Swarm Pet -- Skipping", spawn.CleanName(), spawn.ID())
            return false
        end

        if self:IsPullMode("Chain") then
            if Targeting.IsSpawnXTHater(spawn.ID()) then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoAlready on XTarget -- Skipping", spawn.CleanName(), spawn.ID())
                return false
            end
        end

        if self:HaveList("PullAllowList") then
            if self:IsMobInList("PullAllowList", spawn.CleanName(), true) == false then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar -> Not Found in Allow List!", spawn.CleanName(), spawn.ID())
                return false
            end
        elseif self:HaveList("PullDenyList") then
            if self:IsMobInList("PullDenyList", spawn.CleanName(), false) == true then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar -> Found in Deny List!", spawn.CleanName(), spawn.ID())
                return false
            end
        end

        for _, ignoredMob in ipairs(self.TempSettings.PullIgnoreTargets) do
            if spawn.ID() == ignoredMob.ID() then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar -> Found in Ignore List!", spawn.CleanName(), spawn.ID())
                return false
            end
        end

        if spawn.FeetWet() and not Config:GetSetting('PullMobsInWater') then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \agIgnoring mob in water", spawn.CleanName(), spawn.ID())
            return false
        end

        -- Level Checks
        if Config:GetSetting('UsePullLevels') then
            if spawn.Level() < Config:GetSetting('PullMinLevel') then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoLevel too low - %d", spawn.CleanName(), spawn.ID(),
                    spawn.Level())
                return false
            end
            if spawn.Level() > Config:GetSetting('PullMaxLevel') then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoLevel too high - %d", spawn.CleanName(), spawn.ID(),
                    spawn.Level())
                return false
            end
        else
            -- check cons.
            local conLevel = Globals.Constants.ConColorsNameToId[spawn.ConColor()]
            if conLevel > Config:GetSetting('PullMaxCon') or conLevel < Config:GetSetting('PullMinCon') then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw)  - Ignoring mob due to con color. Min = %d, Max = %d, Mob = %d (%s)",
                    spawn.CleanName(), spawn.ID(),
                    Config:GetSetting('PullMinCon'),
                    Config:GetSetting('PullMaxCon'), conLevel, spawn.ConColor())
                return false
            end
            -- check max level difference
            local maxLvl = mq.TLO.Me.Level() + Config:GetSetting('MaxLevelDiff')
            if spawn.Level() > maxLvl then
                Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw)  - Ignoring mob due to max level difference. Max Level = %d, Mob = %d",
                    spawn.CleanName(), spawn.ID(), maxLvl, spawn.Level())
                return false
            end
        end

        local checkX, checkY, checkZ = mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()

        if self:IsPullMode("Farm") then
            local wpId = self:GetCurrentWpId()
            local wpData = self:GetWPById(wpId)
            checkX, checkY, checkZ = wpData.x, wpData.y, wpData.z
        elseif self:IsPullMode("Hunt") then
            checkX, checkY, checkZ = self.TempSettings.HuntX, self.TempSettings.HuntY, self.TempSettings.HuntZ
        end

        -- do distance checks.
        if math.abs(spawn.Z() - checkZ) > Config:GetSetting('PullZRadius') then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoZDistance too far - %d > %d", spawn.CleanName(), spawn.ID(),
                math.abs(spawn.Z() - checkZ),
                Config:GetSetting('PullZRadius'))
            return false
        end

        local distSqr = Math.GetDistanceSquared(spawn.X(), spawn.Y(), checkX, checkY)

        if distSqr > pullRadiusSqr then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoDistance too far - distSq(%d) > pullRadiusSq(%d)",
                spawn.CleanName(), spawn.ID(), distSqr,
                pullRadiusSqr)
            return false
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
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \aoPath check failed - dist(%d) canPath(%s)", spawn.CleanName(),
                spawn.ID(), navDist, Strings.BoolToColorString(canPath))
            return false
        end

        if Config:GetSetting('SafeTargeting') and Targeting.IsSpawnFightingStranger(spawn, 500) then
            Logger.log_verbose("\atPULL::FindPullTarget \awSpawn \am%s\aw (\at%d\aw) \ar mob is fighting a stranger and safe targeting is enabled!",
                spawn.CleanName(), spawn.ID())
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
    self.TempSettings.PullTargetsMetaData = metaData

    if #pullTargets > 0 then
        local pullTarget = pullTargets[1]
        Logger.log_info("\atPULL::FindPullTarget \agPulling %s [%d] with Distance: %d", pullTarget.CleanName(), pullTarget.ID(), metaData[pullTarget.ID()].distance)
        return pullTarget.ID()
    end

    return 0
end

---@param pullID number
---@return boolean
function Module:CheckForAbort(pullID, bNavigating)
    if self.TempSettings.PausePulls then
        Logger.log_debug("\ar ALERT: Aborting pull - paused at user's request \ax")
        return true
    end

    if self.TempSettings.PullListUpdated then
        Logger.log_debug("\ar ALERT: Aborting pull due to change in pull allow or deny list. \ax")
        self.TempSettings.PullListUpdated = false
        return true
    end

    if self.TempSettings.AbortPull then
        Logger.log_debug("\ar ALERT: Aborting pull on user request. \ax")
        self.TempSettings.AbortPull = false
        return true
    end

    if (not Config:GetSetting('DoPull') and self.TempSettings.TargetSpawnID == 0) or Globals.PauseMain then
        Logger.log_debug("\ar ALERT: Pulling Disabled at user request. \ax")
        return true
    end

    if pullID == 0 then return true end

    Logger.log_verbose("PULL:Checking for abort on spawn id: %d", pullID)
    local spawn = mq.TLO.Spawn(pullID)

    if not spawn or spawn.Dead() or not spawn.ID() or spawn.ID() == 0 then
        Logger.log_debug("PULL:\ar ALERT: Aborting mob died or despawned \ax")
        return true
    end

    -- ignore distance and time if this is a manually requested pull
    if pullID ~= self.TempSettings.TargetSpawnID then
        if spawn.Distance() > Config:GetSetting("MaxPathRange") then
            Logger.log_debug("PULL:\ar ALERT: Aborting mob moved out of spawn distance \ax")
            return true
        end

        if not mq.TLO.Navigation.PathExists("id " .. pullID)() then
            Logger.log_debug("PULL:\ar ALERT: Aborting mob no longer reachable on mesh \ax")
            return true
        end

        if Config:GetSetting('SafeTargeting') and Targeting.IsSpawnFightingStranger(spawn, 500) then
            Logger.log_debug("PULL:\ar ALERT: Aborting mob is fighting a stranger and safe targeting is enabled! \ax")
            return true
        end

        if not bNavigating and Globals.GetTimeSeconds() - self.TempSettings.PullAttemptStarted >= Config:GetSetting('PullIgnoreTime') then
            Logger.log_debug("\ar ALERT: Aborting due to timeout, adding mob to Pull Ignore List! \ax")
            table.insert(self.TempSettings.PullIgnoreTargets, mq.TLO.Spawn(pullID))
            return true
        end
    end
    return false
end

---@param mode string
---@return boolean
function Module:IsPullMode(mode)
    return self.Constants.PullModes[Config:GetSetting('PullMode')] == mode
end

---@return integer
function Module:GetPullState()
    return self.TempSettings.PullState
end

---@param state string
---@return boolean
function Module:IsPullState(state)
    return self.TempSettings.PullState == PullStates[state]
end

---@param state number
---@param reason string
function Module:SetPullState(state, reason)
    self.TempSettings.PullState = state
    self.TempSettings.PullStateReason = reason
end

function Module:NavToWaypoint(loc, ignoreAggro)
    -- if DoMed is set it will take care of standing us up
    if mq.TLO.Me.Sitting() then
        Globals.InMedState = false
    end

    mq.TLO.Me.Stand()

    Movement:DoNav(false, "locyxz %s, log=off", loc)
    mq.delay(1000, function() return mq.TLO.Navigation.Active() end)

    local maxMove = Config:GetSetting('MaxMoveTime') * 1000
    while mq.TLO.Navigation.Active() do
        Logger.log_verbose("PULL:NavToWaypoint Waypoint: %d Aggro Count: %d", self.GetCurrentWpId(self), Targeting.GetXTHaterCount())

        if self.TempSettings.WayPointsToDelete:contains(self:GetCurrentWpId()) then
            Logger.log_debug("PULL:\arNOTICE:\ax Deleting waypoint %d while naving to it.", self:GetCurrentWpId())
            Movement:DoNav(false, "stop log=off")
            return false
        end

        if Targeting.GetXTHaterCount() > 0 and not ignoreAggro then
            if mq.TLO.Navigation.Active() then
                Movement:DoNav(false, "stop log=off")
            end
            return false
        end

        Modules:ExecModule("Movement", "CheckStuck")

        if mq.TLO.Navigation.Paused() then
            Movement:DoNav(false, "pause log=off")
        end

        mq.delay(100)
        mq.doevents()
        Events.DoEvents()
        maxMove = maxMove - 100

        if maxMove <= 0 then
            Logger.log_debug("\arNOTICE:\ax Pull Time Exceeded! Rescan for targets.")
            self:SetPullState(PullStates.PULL_MOVING_CHECKS, "")
            -- simply return, if nav needs to be stopped, whatever needs to do it will stop it.
            -- in this way, nav will continue towards the original target while we rescan
            return false
        end
    end

    local distanceToWP = mq.TLO.Math.Distance(loc)()
    if distanceToWP > 50 then
        Logger.log_verbose("PULL:NavToWaypoint Waypoint: Something went wrong. Current distance to WP: %d. (Possible manual interruption or conflicting nav command.)", distanceToWP)
        return false
    end

    return true
end

function Module:GetPullAbilityRange()
    if not self.ModuleLoaded then return 0 end
    local pullAbility = self.TempSettings.ValidPullAbilities[Config:GetSetting('PullAbility')]
    if not pullAbility then return 0 end

    local ret = pullAbility.AbilityRange
    if type(ret) == 'function' then ret = ret() end
    return ret
end

function Module:GetPullStateTargetInfo()
    return string.format("%s(%d) Dist(%d)", Targeting.GetTargetCleanName(), Targeting.GetTargetID(), Targeting.GetTargetDistance())
end

function Module:GiveTime()
    local combat_state = Combat.GetCachedCombatState()

    self:RefreshGroupNames()

    self:ProcessDeleteWPs()

    if combat_state ~= "Downtime" and not self:IsPullMode("Chain") then
        Logger.log_verbose("PULL:GiveTime() we are in %s, not ready for pulling.", combat_state)
        return
    end
    if (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded) < Config:GetSetting('PullDelay') then
        Logger.log_verbose("PULL:GiveTime() waiting for Pull Delay, next attempt in %d seconds.",
            Config:GetSetting('PullDelay') - (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded))
        return
    end

    -- Hold pulls if using SmartLoot and we have opted to wait for peers to finish looting
    if Globals.SLPeerLooting and Config:GetSetting("PullsYieldForLooting", true) then
        Logger.log_verbose("PULL:GiveTime() Holding pulls to finish processing looting.")
        return
    end

    Logger.log_verbose("PULL:GiveTime() - Enter")
    self:SetValidPullAbilities()
    self:FixPullerMerc()
    if Config:GetSetting('DoPull') then
        for _, v in pairs({}) do --Config:GetSetting('PullSafeZones')) do
            if v == mq.TLO.Zone.ShortName() then
                local safeZone = mq.TLO.Zone.ShortName()
                Logger.log_debug("\ar ALERT: In a safe zone \at%s \ax-\ar Disabling Pulling. \ax", safeZone)
                Config:SetSetting('DoPull', false)
                break
            end
        end
    end

    if not Config:GetSetting('DoPull') then
        if self.TempSettings.HuntX ~= 0 or self.TempSettings.HuntY ~= 0 or self.TempSettings.HuntZ ~= 0 then
            self.TempSettings.HuntX = 0
            self.TempSettings.HuntY = 0
            self.TempSettings.HuntZ = 0
            Core.DoCmd("/mapfilter pullradius off")
        end
        if #self.TempSettings.PullIgnoreTargets > 0 then
            self:ClearIgnoreList()
        end
    end

    Logger.log_verbose("PULL:GiveTime() - DoPull: %s", Strings.BoolToColorString(Config:GetSetting('DoPull')))
    if not Config:GetSetting('DoPull') and self.TempSettings.TargetSpawnID == 0 then return end

    if Config:GetSetting('DoPull') then
        if self:IsPullMode("Hunt") and ((self.TempSettings.HuntX == 0 or self.TempSettings.HuntY == 0 or self.TempSettings.HuntZ == 0) or Config:GetSetting('HuntFromPlayer')) then
            self.TempSettings.HuntX = mq.TLO.Me.X()
            self.TempSettings.HuntY = mq.TLO.Me.Y()
            self.TempSettings.HuntZ = mq.TLO.Me.Z()
            Movement.UpdateMapRadii()
        end
        if #self.TempSettings.PullIgnoreTargets > 0 then
            self:ValidateIgnoreList()
        end
    end

    if not mq.TLO.Navigation.MeshLoaded() then
        Logger.log_error("\ar ERROR: There's no mesh for this zone. Can't pull. \ax")
        Logger.log_error("\ar Disabling Pulling. \ax")
        Config:SetSetting('DoPull', false)
        return
    end

    local campData = Modules:ExecModule("Movement", "GetCampData")

    if Config:GetSetting('PullAbility') == PullAbilityIDToName.PetPull and (mq.TLO.Me.Pet.ID() or 0) == 0 then
        Comms.HandleAnnounce(Comms.FormatChatEvent("Pull", mq.TLO.Me.CleanName(), "Need to create a new pet to throw as mob fodder."), Config:GetSetting('PullAnnounceGroup'),
            Config:GetSetting('PullAnnounce'),
            Config:GetSetting('AnnounceToRaidIfInRaid'))
        return
    end

    local shouldPull, reason = self:ShouldPull(campData)

    Logger.log_verbose("PULL:GiveTime() - ShouldPull: %s", Strings.BoolToColorString(shouldPull))

    if not shouldPull then
        Module:StopNavAfterFailedMovingCheck()
        if not mq.TLO.Navigation.Active() and combat_state == "Downtime" then
            -- go back to camp.
            self:SetPullState(PullStates.PULL_WAITING_SHOULDPULL, reason)
            if campData.returnToCamp then
                local distanceToCampSq = Math.GetDistanceSquared(mq.TLO.Me.Y(), mq.TLO.Me.X(), campData.campSettings.AutoCampY, campData.campSettings.AutoCampX)
                if distanceToCampSq > (Config:GetSetting('AutoCampRadius') ^ 2) then
                    Logger.log_debug("PULL: Distance to camp is %d and radius is %d - going closer.", math.sqrt(distanceToCampSq), Config:GetSetting('AutoCampRadius'))
                    Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f log=off", campData.campSettings.AutoCampY, campData.campSettings.AutoCampX, campData.campSettings.AutoCampZ)
                end
            end
        end
        return
    end

    if Config:GetSetting('GroupWatch') then
        local groupReady, groupReason = self:CheckGroupForPull(Config:GetSetting('GroupWatchStartPct'), Config:GetSetting('GroupWatchStopPct'), campData)
        if not groupReady then
            Logger.log_verbose("PULL:GiveTime() - GroupWatch Failed")
            Module:StopNavAfterFailedMovingCheck()
            self:SetPullState(PullStates.PULL_GROUPWATCH_WAIT, groupReason)
            local me = mq.TLO.Me
            if me.Standing() and not me.Moving() and (me.PctHPs() < Config:GetSetting('HPMedPctStop') or me.PctMana() < Config:GetSetting('ManaMedPctStop') or me.PctEndurance() < Config:GetSetting('EndMedPctStop')) then
                Logger.log_verbose(
                    "PULL:GiveTime() - We are waiting for GroupWatch and we are below med stop levels, lets sit down ourselves! Note: Does not interface with medstate.")
                me.Sit()
            end
            return
        end
    end

    -- GROUPWATCH and NAVINTERRUPT are the two states we can't reset. In the future it may be best to
    -- limit this to only the states we know should be transitionable to the IDLE state.
    if self.TempSettings.PullState ~= PullStates.PULL_GROUPWATCH_WAIT and self.TempSettings.PullState ~= PullStates.PULL_NAV_INTERRUPT then
        self:SetPullState(PullStates.PULL_IDLE, "")
    end

    -- We're ready to pull, but first, check if we're in farm mode and if we were interrupted
    if self:IsPullMode("Farm") then
        local currentWpId = self:GetCurrentWpId()
        if currentWpId == 0 then
            Logger.log_error("\arYou do not have a valid WP ID(%d) for this zone(%s::%s) - Aborting!", self.TempSettings.CurrentWP, mq.TLO.Zone.Name(),
                mq.TLO.Zone.ShortName())
            self:SetPullState(PullStates.PULL_IDLE, "")
            Config:SetSetting('DoPull', false)
            return
        end

        if self.TempSettings.PullState == PullStates.PULL_NAV_INTERRUPT then
            -- if we still have haters let combat handle it first.
            if Targeting.GetXTHaterCount() > 0 then
                return
            end

            -- We're not ready to pull yet as we haven't made it to our waypoint. Keep navigating if we don't have a full inventory
            if mq.TLO.Me.FreeInventory() == 0 then self:FarmFullInvActions() end

            self:SetPullState(PullStates.PULL_MOVING_TO_WP, string.format("WP Id: %d", currentWpId))
            local wpData = self:GetWPById(currentWpId)
            if not self:NavToWaypoint(string.format("%0.2f, %0.2f, %0.2f", wpData.y, wpData.x, wpData.z)) then
                self:SetPullState(PullStates.PULL_NAV_INTERRUPT, "")
                self.TempSettings.ReachedWP = false
                return
            else
                Logger.log_verbose("Pull: Reached Farm Waypoint %d.", currentWpId)
                self.TempSettings.ReachedWP = true
                self:SetLastPullOrCombatEndedTimer()
                self:SetPullState(PullStates.PULL_IDLE, "")
            end
            self:SetPullState(PullStates.PULL_IDLE, "")
        end

        -- We're not in an interrupted state if we make it this far -- so
        -- now make sure we have free inventory or not.
        if mq.TLO.Me.FreeInventory() == 0 then self:FarmFullInvActions() end
    end

    self:SetPullState(PullStates.PULL_SCAN, "")

    self.TempSettings.PullID = 0

    if self.TempSettings.TargetSpawnID > 0 then
        local targetSpawn = mq.TLO.Spawn(self.TempSettings.TargetSpawnID)
        if not targetSpawn() or targetSpawn.Dead() then
            Logger.log_debug("PULL: \arDropping Manual target id %d - it is dead.", self.TempSettings.TargetSpawnID)
            self.TempSettings.TargetSpawnID = 0
        end
    end

    if self.TempSettings.TargetSpawnID > 0 then
        self.TempSettings.PullID = self.TempSettings.TargetSpawnID
    else
        Logger.log_debug("PULL:Finding Pull Target")
        self.TempSettings.PullID = self:FindTarget()
    end

    if self.TempSettings.PullID == 0 and self:IsPullMode("Farm") then
        -- if we are idle, wait a bit if we have a waypoint delay set (interrupt: bypass this, we aren't at the WP)
        if self.TempSettings.PullState == PullStates.PULL_IDLE and (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded) < Config:GetSetting('WaypointDelay') then
            Logger.log_verbose("PULL: Waiting for farm waypoint delay, next attempt in %d seconds.",
                Config:GetSetting('WaypointDelay') - (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded))
            return
        end

        -- move to next WP
        if self.TempSettings.ReachedWP then
            -- if we are idle, wait a bit if we have a waypoint delay set (interrupt: bypass this, we aren't at the WP)
            if (Globals.GetTimeSeconds() - self.TempSettings.LastPullOrCombatEnded) < Config:GetSetting('WaypointDelay') then
                Logger.log_verbose("PULL: Waiting for farm waypoint delay, next attempt in %d seconds.",
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

        self:SetPullState(PullStates.PULL_MOVING_TO_WP, string.format("%0.2f, %0.2f, %0.2f", wpData.y, wpData.x, wpData.z))
        if not self:NavToWaypoint(string.format("%0.2f, %0.2f, %0.2f", wpData.y, wpData.x, wpData.z)) then
            self:SetPullState(PullStates.PULL_NAV_INTERRUPT, "")
            self.TempSettings.ReachedWP = false
            return
        else
            Logger.log_verbose("Pull: Reached Farm Waypoint %d.", currentWP)
            self.TempSettings.ReachedWP = true
            self:SetLastPullOrCombatEndedTimer()
        end

        self:SetPullState(PullStates.PULL_IDLE, "")
        return
    end

    self:SetPullState(PullStates.PULL_IDLE, "")

    if self.TempSettings.PullID == 0 then
        Logger.log_debug("\ayNothing to pull - better luck next time")
        return
    end

    local start_x = mq.TLO.Me.X()
    local start_y = mq.TLO.Me.Y()
    local start_z = mq.TLO.Me.Z()

    if campData.returnToCamp then
        Logger.log_debug("PULL:\ayRTB: Storing Camp info to return to")
        start_x = campData.campSettings.AutoCampX
        start_y = campData.campSettings.AutoCampY
        start_z = campData.campSettings.AutoCampZ
    end

    Logger.log_debug("PULL:\ayRTB Location: %d %d %d", start_y, start_x, start_z)

    -- if DoMed is set it will take care of standing us up
    if mq.TLO.Me.Sitting() then
        Globals.InMedState = false
    end

    mq.TLO.Me.Stand()

    self:SetPullState(PullStates.PULL_NAV_TO_TARGET, string.format("Id: %d", self.TempSettings.PullID))
    Logger.log_debug("PULL:\ayFound Target: %d - Attempting to Nav", self.TempSettings.PullID)

    local pullAbility = self.TempSettings.ValidPullAbilities[Config:GetSetting('PullAbility')]
    local startingXTargs = Targeting.GetXTHaterIDs()
    local requireLOS = "on"

    if pullAbility and pullAbility.LOS == false then
        requireLOS = "off"
    end

    Core.DoCmd("/squelch /attack off")

    Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", self.TempSettings.PullID, self:GetPullAbilityRange(), requireLOS)

    mq.delay(1000, function() return mq.TLO.Navigation.Active() end)

    local abortPull = false
    local maxMove = Config:GetSetting('MaxMoveTime') * 1000

    while mq.TLO.Navigation.Active() do
        Logger.log_super_verbose("Pathing to pull id...")
        if self:IsPullMode("Chain") then
            if Targeting.GetXTHaterCount() >= Config:GetSetting('ChainCount') then
                Logger.log_info("\awNOTICE:\ax Gained aggro -- aborting chain pull!")
                abortPull = true
                break
            end
            if Targeting.DiffXTHaterIDs(startingXTargs) then
                Logger.log_info("\awNOTICE:\ax XTarget List Changed -- aborting chain pull!")
                abortPull = true
                break
            end
        else
            if Targeting.GetXTHaterCount() > 0 then
                Logger.log_info("\awNOTICE:\ax Gained aggro -- aborting pull!")
                abortPull = true
                break
            end
        end

        if self:CheckForAbort(self.TempSettings.PullID, true) then
            abortPull = true
            break
        end

        Modules:ExecModule("Movement", "CheckStuck")

        mq.delay(100)
        mq.doevents()
        Events.DoEvents()

        maxMove = maxMove - 100

        if maxMove <= 0 then
            Logger.log_debug("\arNOTICE:\ax Pull Time Exceeded! Rescan for targets.")
            self:SetPullState(PullStates.PULL_MOVING_CHECKS, "")
            -- simply return, if nav needs to be stopped, whatever needs to do it will stop it.
            -- in this way, nav will continue towards the original target while we rescan
            return
        end
    end

    if not abortPull then
        mq.delay("2s", function() return not mq.TLO.Me.Moving() end)

        Targeting.SetTarget(self.TempSettings.PullID)

        if mq.TLO.Target.Master.Type() == 'PC' then
            Logger.log_debug("\atPULL::PullTarget \awPullTarget :: Spawn \am%s\aw (\at%d\aw) is Charmed Pet -- Skipping", mq.TLO.Target.CleanName(), mq.TLO.Target.ID())
            abortPull = true
        end

        if Config:GetSetting('SafeTargeting') then
            -- Hard coding 500 units as our radius as it's probably twice our effective spell range.
            if Targeting.IsSpawnFightingStranger(mq.TLO.Spawn(self.TempSettings.PullID), 500) then
                abortPull = true
            end
        end

        local target = mq.TLO.Target
        self:SetPullState(PullStates.PULL_PULLING, self:GetPullStateTargetInfo())

        if target and target.ID() > 0 then
            Logger.log_info("\agPulling %s [%d]", target.CleanName(), target.ID())

            local successFn = function() return Targeting.GetXTHaterCount() > 0 end

            if self:IsPullMode("Chain") then
                successFn = function() return Targeting.GetXTHaterCount() >= Config:GetSetting('ChainCount') end
            end

            if Config:GetSetting('PullAbility') == PullAbilityIDToName.PetPull then -- PetPull
                Combat.PetAttack(self.TempSettings.PullID, false)
                self.TempSettings.PullAttemptStarted = Globals.GetTimeSeconds()
                while not successFn() do
                    Logger.log_super_verbose("Waiting on pet pull to finish...")
                    Combat.PetAttack(self.TempSettings.PullID, false)
                    if self:IsPullMode("Chain") and Targeting.DiffXTHaterIDs(startingXTargs) then
                        break
                    end

                    if self:CheckForAbort(self.TempSettings.PullID) then
                        break
                    end
                    mq.delay(10)
                    mq.doevents()
                    Events.DoEvents()
                end

                Core.SetPetHold()
                Core.DoCmd("/squelch /pet back off")
                mq.delay("1s", function() return (mq.TLO.Pet.PlayerState() or 0) == 0 end)
                Core.DoCmd("/squelch /pet follow")
            elseif Config:GetSetting('PullAbility') == PullAbilityIDToName.Face then -- Face pull
                -- Make sure we're looking straight ahead at our mob and delay
                -- until we're facing them.
                Core.DoCmd("/look 0")

                mq.delay("3s", function() return mq.TLO.Me.Heading.ShortName() == target.HeadingTo.ShortName() end)
                self.TempSettings.PullAttemptStarted = Globals.GetTimeSeconds()

                -- We will continue to fire arrows until we aggro our target
                while not successFn() do
                    Logger.log_super_verbose("Waiting on face pull to finish...")

                    Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", self.TempSettings.PullID, self:GetPullAbilityRange(), "on")

                    if self:IsPullMode("Chain") and Targeting.DiffXTHaterIDs(startingXTargs) then
                        Logger.log_debug("PULL:\arXtargs changed heading back to camp!")
                        break
                    end

                    if self:CheckForAbort(self.TempSettings.PullID) then
                        break
                    end

                    Modules:ExecModule("Movement", "CheckStuck")
                    mq.delay(10)
                    mq.doevents()
                    Events.DoEvents()
                end
            elseif Config:GetSetting('PullAbility') == PullAbilityIDToName.Ranged then -- Ranged pull
                -- Make sure we're looking straight ahead at our mob and delay
                -- until we're facing them.
                Core.DoCmd("/look 0")

                mq.delay("3s", function() return mq.TLO.Me.Heading.ShortName() == target.HeadingTo.ShortName() end)
                self.TempSettings.PullAttemptStarted = Globals.GetTimeSeconds()

                -- We will continue to fire arrows until we aggro our target
                while not successFn() do
                    Logger.log_super_verbose("Waiting on ranged pull to finish... %s", Strings.BoolToColorString(successFn()))

                    if Targeting.GetTargetDistance() > self:GetPullAbilityRange() then
                        Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", self.TempSettings.PullID, self:GetPullAbilityRange() / 2, requireLOS)
                        mq.delay(maxMove, function()
                            Modules:ExecModule("Movement", "CheckStuck")
                            return not mq.TLO.Navigation.Active()
                        end)
                    end

                    Core.DoCmd("/ranged %d", self.TempSettings.PullID)
                    if self:IsPullMode("Chain") and Targeting.DiffXTHaterIDs(startingXTargs) then
                        break
                    end

                    if self:CheckForAbort(self.TempSettings.PullID) then
                        break
                    end

                    Modules:ExecModule("Movement", "CheckStuck")
                    mq.delay(10)
                    mq.doevents()
                    Events.DoEvents()
                end
            elseif Config:GetSetting('PullAbility') == PullAbilityIDToName.AutoAttack then -- Auto Attack pull
                -- Make sure we're looking straight ahead at our mob and delay
                -- until we're facing them.
                Core.DoCmd("/look 0")

                mq.delay("3s", function() return mq.TLO.Me.Heading.ShortName() == target.HeadingTo.ShortName() end)
                self.TempSettings.PullAttemptStarted = Globals.GetTimeSeconds()

                -- We will continue to fire arrows until we aggro our target
                while not successFn() do
                    Logger.log_super_verbose("Waiting on autoattack pull to finish... %s", Strings.BoolToColorString(successFn()))
                    Core.DoCmd("/attack")

                    if Targeting.GetTargetDistance() > self:GetPullAbilityRange() then
                        Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", self.TempSettings.PullID, self:GetPullAbilityRange() / 2, requireLOS)
                        mq.delay(maxMove, function()
                            Modules:ExecModule("Movement", "CheckStuck")
                            return not mq.TLO.Navigation.Active()
                        end)
                    end

                    if self:IsPullMode("Chain") and Targeting.DiffXTHaterIDs(startingXTargs) then
                        break
                    end

                    if self:CheckForAbort(self.TempSettings.PullID) then
                        break
                    end

                    mq.delay(10)
                    mq.doevents()
                    Events.DoEvents()
                end
            elseif pullAbility then -- AA/Spell/Ability pull
                self.TempSettings.PullAttemptStarted = Globals.GetTimeSeconds()
                while not successFn() do
                    Logger.log_super_verbose("Waiting on ability pull to finish...%s", Strings.BoolToColorString(successFn()))
                    Targeting.SetTarget(self.TempSettings.PullID, true)

                    if mq.TLO.Target.FeetWet() ~= mq.TLO.Me.FeetWet() then
                        Logger.log_debug("\ar ALERT: Feet wet mismatch - Moving around\ax")
                        Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", self.TempSettings.PullID, Targeting.GetTargetDistance() * 0.9, requireLOS)
                    end

                    if Targeting.GetTargetDistance() > self:GetPullAbilityRange() then
                        Movement:DoNav(false, "id %d distance=%d lineofsight=%s log=off", self.TempSettings.PullID, self:GetPullAbilityRange() / 2, requireLOS)
                        mq.delay(500, function() return mq.TLO.Navigation.Active() end)
                        mq.delay(maxMove, function()
                            Modules:ExecModule("Movement", "CheckStuck")
                            return not mq.TLO.Navigation.Active()
                        end)
                    end

                    if pullAbility.Type:lower() == "ability" then
                        if mq.TLO.Me.AbilityReady(pullAbility.id)() then
                            local abilityName = pullAbility.AbilityName
                            if type(abilityName) == 'function' then abilityName = abilityName() end
                            Casting.UseAbility(abilityName)
                        end
                    elseif pullAbility.Type:lower() == "spell" then
                        local abilityName = pullAbility.AbilityName
                        if type(abilityName) == 'function' then abilityName = abilityName() end
                        Casting.UseSpell(abilityName, self.TempSettings.PullID, false, false, 0)
                    elseif pullAbility.Type:lower() == "aa" then
                        local aaName = pullAbility.AbilityName
                        if type(aaName) == 'function' then aaName = aaName() end
                        Casting.UseAA(aaName, self.TempSettings.PullID, false, 0)
                    elseif pullAbility.Type:lower() == "item" then
                        local itemName = pullAbility.ItemName
                        if type(itemName) == 'function' then itemName = itemName() end
                        Logger.log_debug("Attempting to pull with Item: %s", itemName)
                        Casting.UseItem(itemName, self.TempSettings.PullID)
                    else
                        Logger.log_error("\arInvalid PullAbilityType: %s :: %s", pullAbility.Type, pullAbility.id)
                    end

                    if successFn() then Globals.LastPulledID = self.TempSettings.PullID end

                    if self:IsPullMode("Chain") and Targeting.DiffXTHaterIDs(startingXTargs) then
                        break
                    end

                    if self:CheckForAbort(self.TempSettings.PullID) then
                        break
                    end

                    Modules:ExecModule("Movement", "CheckStuck")
                    mq.delay(10)
                    mq.doevents()
                    Events.DoEvents()
                end
            else
                Logger.log_error("\arInvalid PullAbility: \at%d\ar - Please Select a valid Pull Ability\ax", Config:GetSetting('PullAbility'))
            end
        end
    else
        Logger.log_debug("\arNOTICE:\ax Pull Aborted!")
        Movement:DoNav(false, "stop log=off")
        mq.delay("2s", function() return not mq.TLO.Navigation.Active() end)
    end

    if self:IsPullMode("Normal") or self:IsPullMode("Chain") then
        -- Nav back to camp.
        self:SetPullState(PullStates.PULL_RETURN_TO_CAMP, string.format("Camp Loc: %0.2f %0.2f %0.2f", start_y, start_x, start_z))

        Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f log=off %s", start_y, start_x, start_z, Config:GetSetting('PullBackwards') and "facing=backward" or "")
        mq.delay("5s", function() return mq.TLO.Navigation.Active() end)

        while mq.TLO.Navigation.Active() and (combat_state == "Downtime" or Targeting.GetXTHaterCount() > 0) do
            Logger.log_super_verbose("Pathing to camp...")
            if mq.TLO.Me.State():lower() == "feign" or mq.TLO.Me.Sitting() then
                Logger.log_debug("PULL:Standing up to Engage Target")
                mq.TLO.Me.Stand()
                Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f log=off %s", start_y, start_x, start_z, Config:GetSetting('PullBackwards') and "facing=backward" or "")
                mq.delay("5s", function() return mq.TLO.Navigation.Active() end)
            end

            if mq.TLO.Navigation.Paused() then
                Movement:DoNav(false, "pause")
            end

            Modules:ExecModule("Movement", "CheckStuck")
            mq.doevents()
            Events.DoEvents()
            mq.delay(10)
        end

        Core.DoCmd("/face id %d", self.TempSettings.PullID)

        self:SetPullState(PullStates.PULL_WAITING_ON_MOB, self:GetPullStateTargetInfo())

        -- give the mob 2 mins to get to us.
        local maxPullWait = 1000 * 120 -- 2 mins
        -- wait for the mob to reach us.
        while mq.TLO.Target.ID() == self.TempSettings.PullID and Targeting.GetTargetDistance() > Config:GetSetting('AutoCampRadius') and maxPullWait > 0 do
            self:SetPullState(PullStates.PULL_WAITING_ON_MOB, self:GetPullStateTargetInfo())
            mq.delay(100)
            if mq.TLO.Me.Pet.Combat() then
                Core.DoCmd("/squelch /pet back off")
                mq.delay("1s", function() return (mq.TLO.Pet.PlayerState() or 0) == 0 end)
                Core.DoCmd("/squelch /pet follow")
            end
            maxPullWait = maxPullWait - 100

            if self:CheckForAbort(self.TempSettings.PullID) then
                break
            end

            -- they ain't coming!
            if not Targeting.IsSpawnXTHater(self.TempSettings.PullID) then
                break
            end
            mq.doevents()
            Events.DoEvents()
        end
    end

    self:SetLastPullOrCombatEndedTimer()
    self.TempSettings.TargetSpawnID = 0
    self:SetPullState(PullStates.PULL_IDLE, "")
end

function Module:SetPullTarget()
    self.TempSettings.TargetSpawnID = mq.TLO.Target.ID()
    table.insert(self.TempSettings.PullTargets, mq.TLO.Target)
    self.TempSettings.PullTargetsMetaData[mq.TLO.Target.ID()] = { distance = mq.TLO.Navigation.PathLength("id " .. mq.TLO.Target.ID())(), }
end

function Module:StartPuller()
    if Config:GetSetting('DoPull') == true then return end
    Config:SetSetting('DoPull', true)
    Module:SetRoles()
    self:SaveSettings(false)
end

function Module:StopPuller()
    if Config:GetSetting('DoPull') == false then return end
    Config:SetSetting('DoPull', false)
    Module:SetRoles()
    self:SaveSettings(false)
end

function Module:SetRoles()
    if Config:GetSetting('AutoSetRoles') and mq.TLO.Group.Leader() == mq.TLO.Me.DisplayName() then
        -- in hunt mode we follow around.

        if self.Constants.PullModes[Config:GetSetting('PullMode')] ~= "Hunt" then
            Core.DoCmd("/grouproles %s %s 3", Config:GetSetting('DoPull') and "set" or "unset", mq.TLO.Me.DisplayName()) -- set puller
        end
        Core.DoCmd("/grouproles set %s 2", Globals.MainAssist)                                                           -- set MA
    end
end

function Module:OnDeath()
    -- Death Handler
    if Config:GetSetting('StopPullAfterDeath') then
        Config:SetSetting('DoPull', false)
    end
end

function Module:OnZone()
    -- Zone Handler
    if Config:GetSetting('StopPullAfterDeath') then
        Config:SetSetting('DoPull', false)
    else
        local campData = Modules:ExecModule("Movement", "GetCampData")
        Config:SetSetting('DoPull', campData.returnToCamp and campData.campSettings.CampZoneId == mq.TLO.Zone.ID())
    end
    self:ClearIgnoreList()
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    return PullStatesIDToName[self.TempSettings.PullState]
end

function Module:SetLastPullOrCombatEndedTimer()
    self.TempSettings.LastPullOrCombatEnded = Globals.GetTimeSeconds()
    Logger.log_verbose("Last Pull or Combat Ended: %s", Globals.GetTimeSeconds())
end

function Module:StopNavAfterFailedMovingCheck()
    --if we were navigating during a rescan, cancel it.
    if self.TempSettings.PullState == PullStates.PULL_MOVING_CHECKS and mq.TLO.Navigation.Active() then
        Logger.log_debug("PULL\arNOTICE:\ax Moving Checks failed! Aborting nav.")
        Movement:DoNav(false, "stop log=off")
        mq.delay("2s", function() return not mq.TLO.Navigation.Active() end)
    end
end

return Module
