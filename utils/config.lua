local mq                                                 = require('mq')
local Modules                                            = require("utils.modules")
local Tables                                             = require("utils.tables")
local Strings                                            = require("utils.strings")
local Logger                                             = require("utils.logger")
local Comms                                              = require("utils.comms")
local Set                                                = require("mq.Set")
local Files                                              = require("utils.files")
local Globals                                            = require("utils.globals")
local Db                                                 = require("utils.db").new(mq.configDir .. '/rgmercs/rgmercs_config.db')

local Config                                             = {
    _version = '2.1.0',
    _subVersion = "Shattering of Ro",
    _name = "Config",
    _AppName = "RGMercs Lua Edition",
    _author = 'Lead Devs: Derple, Algar',
}
Config.__index                                           = Config
Config.moduleSettings                                    = {}
Config.moduleDefaultSettings                             = {}
Config.moduleTempSettings                                = {}
Config.moduleSettingCategories                           = {}
Config.currentPeer                                       = ""
Config.peerModuleSettings                                = {}
Config.peerModuleDefaultSettings                         = {}
Config.peerModuleSettingCategories                       = {}
Config.FAQ                                               = {}
Config.SettingsLoadComplete                              = false
Config.DbConsistencyCheckPass                            = true

Config.TempSettings                                      = {}
Config.TempSettings.lastModuleRegisteredTime             = 0
Config.TempSettings.lastHighlightTime                    = Globals.GetTimeSeconds()
Config.TempSettings.SettingToModuleCache                 = {}
Config.TempSettings.SettingsLowerToNameCache             = {}
Config.TempSettings.SettingsCategoryToSettingMapping     = {}
Config.TempSettings.PeerModuleSettingsLowerToNameCache   = {}
Config.TempSettings.PeerSettingToModuleCache             = {}
Config.TempSettings.PeerSettingsCategoryToSettingMapping = {}
Config.TempSettings.LastPeerConfigReceivedTime           = 0
Config.TempSettings.ResetOptionsUIPosition               = false

Config.TempSettings.HighlightedModules                   = Set.new({})

-- Legacy Support
Config.Globals                                           = Globals

-- Constants
Config.Constants                                         = Globals.Constants

Config.FAQ                                               = {
    {
        Question = "What do Announcements do?",
        Answer = "  Announcments are used to broadcast the selected options to the DanNet channel. The Group Announce optios will output the announcement to /gsay.",
        Settings_Used = "",
    },
    {
        Question = "I want to manually control my driver and choose my own targets. What do I need to adjust?",
        Answer = "The following settings may require adjustment to drive yourself:\n\n" ..
            "Targeting:\nAuto Target (controls scanning for and autotargeting combat targets).\n\n" ..
            "Assisting:\nAuto Engage (controls moving to a target, automatically initiating combat, and taking offensive actions).\n\n" ..
            "Positioning:\nFace Target In Combat (Mercs will still assume you are facing properly for abilities that require it!)\n\n" ..
            "Positioning:\nAuto Navigation (controls /nav commands used in combat to close with the target)\n\n" ..
            "Positioning:\nAuto Stick (controls /stick commands used in combat to stay near the target)\n\n" ..
            "Mercs will still manage the action, and we should return to the target you had if needed after a heal, buff, item use, etc. You can pause mercs to take full control." ..
            "These settings and interactions have been recently adjusted, and feedback is requested if you see something not quite right!",
        Settings_Used = "",
    },
    {
        Question = "How do I force auto combat on a target that isn't aggressive or isn't hostile, like a target dummy, object, or special NPC?",
        Answer = "This is accomplished with the /rgl forcetarget <id?> command:\n\n" ..
            "The command accepts a target ID, and will fall back to your current target's ID if one is not supplied.\n\n" ..
            "When commanded, the PC will add the target to the first XT slot and immediately force target.\n\n" ..
            "The force target state can be issued to any PC, but if issued by the MA, it will be broadcasted to peers via actors, and will allow the target to check as valid even when the 'Target Non-Aggressives' setting is disabled." ..
            "Only one Force Target can be directed at a time, and the state will be cleared automatically. It can be cleared manually with the /rgl forcetargetclear command.",
        Settings_Used = "",
    },
    {
        Question = "How do I get help or support with a question, concern or issue, or, how do I provide feedback?",
        Answer = "Please make a basic attempt to search for the answer using the (searchable!) in-game FAQs, settings and command lists." ..
            "Still need help? No problem! You can find us in a few spots:\n\n" ..
            "    The #rg-mercs discord channel on the RedGuides discord...\n\n" ..
            "    The RGMercs general forum (for questions/feedback) or the RGMercs support forum (for issues) on the RedGuides forums at redguides.com..." ..
            "    Any 'MQ' style discord channel for a server we have a default config for (i.e, EQ Might, Project Lazarus).\n\n" ..
            "Please do NOT DM, PM or otherwise privately contact RGMercs devs without personal invitation.",
        Settings_Used = "",
    },
}
-- Defaults
Config.DefaultConfig                                     = {

    -- Custom: These use custom UI elements and do not display in normal settings windows.
    ['ClassConfigDir']             = {
        DisplayName = "Class Config Dir",
        Type = "Custom",
        Default = (Globals.BuildType:lower() == "emu" and Globals.Constants.SupportedEmuServers:contains(Globals.CurServer)) and Globals.CurServer or "Live",
    },
    ['UseAssistList']              = {
        DisplayName = "Assist Outside of Group",
        Type = "Custom",
        Default = false,
    },
    ['AssistList']                 = {
        DisplayName = "List of User-Defined Assists",
        Type = "Custom",
        Default = {},
    },
    ['UseHealList']                = {
        DisplayName = "Heal Outside of Group",
        Type = "Custom",
        Default = false,
    },
    ['HealList']                   = {
        DisplayName = "List of User-Defined Heal Targets",
        Type = "Custom",
        Default = {},
    },
    ['ShowAdvancedOpts']           = {
        DisplayName = "Show Advanced Options",
        Type = "Custom",
        Default = false,
    },
    ['PopOutForceTarget']          = {
        DisplayName = "Pop Out Force Target",
        Type = "Custom",
        Default = false,
    },
    ['PopOutMercsStatus']          = {
        DisplayName = "Pop Out Mercs Status",
        Type = "Custom",
        Default = false,
    },
    ['PopOutConsole']              = {
        DisplayName = "Pop Out Console",
        Type = "Custom",
        Default = false,
    },
    ['MainWindowLocked']           = {
        DisplayName = "Main Window Locked",
        Default = false,
        Type = "Custom",
    },

    -- Announcements
    ['AnnounceToRaidIfInRaid']     = {
        DisplayName = "Announce to Raid if In Raid",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 0,
        Tooltip = "If in a raid, announcements will go to raid instead of group.",
        Default = false,
        ConfigType = "Advanced",
    },

    ['AnnounceTarget']             = {
        DisplayName = "Announce Target",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 1,
        Tooltip = "Announces the current combat target. Uses KissAssist format.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['AnnounceTargetGroup']        = {
        DisplayName = "Announce Target to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 2,
        Tooltip = "Announces Target over /gsay.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['MezAnnounce']                = {
        DisplayName = "Mez Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 3,
        Default = false,
        Tooltip = "Announces mez use.",
        ConfigType = "Advanced",
    },
    ['MezAnnounceGroup']           = {
        DisplayName = "Mez Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 4,
        Default = false,
        Tooltip = "Announces mez use to /gsay.",
        ConfigType = "Advanced",
    },
    ['CharmAnnounce']              = {
        DisplayName = "Charm Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 5,
        Default = false,
        Tooltip = "Announces charm use.",
        ConfigType = "Advanced",
    },
    ['CharmAnnounceGroup']         = {
        DisplayName = "Charm Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 6,
        Default = false,
        Tooltip = "Announces charm use to /gsay.",
        ConfigType = "Advanced",
    },
    ['HealAnnounce']               = {
        DisplayName = "Heal Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 7,
        Default = false,
        Tooltip = "Announces heal spell use.",
        ConfigType = "Advanced",
    },
    ['HealAnnounceGroup']          = {
        DisplayName = "Heal Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 8,
        Default = false,
        Tooltip = "Announces heal spell use to /gsay.",
        ConfigType = "Advanced",
    },
    ['CureAnnounce']               = {
        DisplayName = "Cure Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 9,
        Default = false,
        Tooltip = "Announces cure use.",
        ConfigType = "Advanced",
    },
    ['CureAnnounceGroup']          = {
        DisplayName = "Cure Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 10,
        Default = false,
        Tooltip = "Announces cure use to /gsay.",
        ConfigType = "Advanced",
    },
    ['ReagentAnnounce']            = {
        DisplayName = "Reagent Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 11,
        Default = false,
        Tooltip = "Announces an aborted cast due to missing spell reagent.",
        ConfigType = "Advanced",
    },
    ['ReagentAnnounceGroup']       = {
        DisplayName = "Reagent Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 12,
        Default = false,
        Tooltip = "Announces an aborted cast due to missing spell reagent to /gsay. (Warning: Often spammy.)",
        ConfigType = "Advanced",
    },
    ['PullAnnounce']               = {
        DisplayName = "Pull Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 13,
        Default = false,
        Tooltip = "Announce pull-related messages.",
        ConfigType = "Advanced",
    },
    ['PullAnnounceGroup']          = {
        DisplayName = "Pull Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 14,
        Default = false,
        Tooltip = "Announce pull-related messages in /gsay. (Warning: Often spammy.)",
        ConfigType = "Advanced",
    },
    ['BurnAnnounce']               = {
        DisplayName = "Burn Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 15,
        Default = false,
        Tooltip = "Announce burn-related messages.",
        ConfigType = "Advanced",
    },
    ['BurnAnnounceGroup']          = {
        DisplayName = "Burn Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 16,
        Default = false,
        Tooltip = "Announce burn-related messages in /gsay. (Warning: Often spammy.)",
        ConfigType = "Advanced",
    },
    ['CharacterFlagAnnounce']      = {
        DisplayName = "Character Flag Announce",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 17,
        Default = false,
        Tooltip = "Announces when a character flag is received.",
        ConfigType = "Advanced",
    },
    ['CharacterFlagAnnounceGroup'] = {
        DisplayName = "Character Flag Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Index = 17,
        Default = false,
        Tooltip = "Announces when a character flag is received.",
        ConfigType = "Advanced",
    },
    ['HeartbeatAnnounceGroup']     = {
        DisplayName = "Heartbeat Announce to Group",
        Group = "General",
        Header = "Announcements",
        Category = "Announcements",
        Type = "Custom",
        Index = 18,
        Default = false,
        Tooltip = "Announces received heartbeats in /gsay. (Warning: spammy.)",
        ConfigType = "Advanced",
    },

    --Misc
    ['InstantRelease']             = { --Algarnote: Wondering who uses this? I can't imagine a usecase that doesn't involve scripts or afk and this could be handled in those scripts
        DisplayName = "Instant Release",
        Group = "General",
        Header = "Misc",
        Category = "Misc",
        Index = 1,
        Tooltip = "Instantly release to spawn point when you die.",
        Default = false,
        ConfigType = "Advanced",
    },

    -- Meditation/Med Rules
    ['DoMed']                      = {
        DisplayName = "Do Meditate",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Rules",
        Index = 1,
        Tooltip = "Choose if/when to meditate.\nMay interfere with bard songs (refer to FAQ for 'Bard Meditation').",
        Type = "Combo",
        ComboOptions = { 'Off', 'Out of Combat', 'In and Out of Combat', },
        Default = Globals.CurLoadedClass == "BRD" and 1 or 2,
        Min = 1,
        Max = 3,
        ConfigType = "Normal",
    },
    ['StandWhenDone']              = {
        DisplayName = "Stand When Done Medding",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Rules",
        Index = 2,
        Tooltip = "Force a stand to end meditation when thresholds are reached.",
        Default = Globals.CurLoadedClass == "BRD",
    },
    ['AfterCombatMedDelay']        = {
        DisplayName = "After Combat Med Delay",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Rules",
        Index = 3,
        Tooltip = "How may seconds to delay after combat before sitting to meditate.",
        Default = 6,
        Min = 0,
        Max = 60,
        ConfigType = "Advanced",
    },
    ['MedAggroCheck']              = {
        DisplayName = "Med Aggro Check",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Rules",
        Index = 4,
        Tooltip = "Force a stand when we have aggro higher than the Med Aggro Percent setting from an xtarget.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['MedAggroPct']                = {
        DisplayName = "Med Aggro Percent",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Rules",
        Index = 5,
        Tooltip = "Aggro percent value for the Med Aggro Check.",
        Default = 65,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },

    -- Meditation/Med Thresholds
    ['HPMedPct']                   = {
        DisplayName = "Med Start HP%",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Thresholds",
        Index = 1,
        Tooltip = "Attempt to meditate when at or under this HP percentage.",
        Default = 60,
        Min = 1,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['HPMedPctStop']               = {
        DisplayName = "Med Stop HP%",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Thresholds",
        Index = 2,
        Tooltip = "When meditating, allow meditation to end when at or over this HP percentage.",
        Default = 90,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['ManaMedPct']                 = {
        DisplayName = "Med Start Mana%",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Thresholds",
        Index = 3,
        Tooltip = "Attempt to meditate when at or under this Mana percentage.",
        Default = 60,
        Min = 1,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['ManaMedPctStop']             = {
        DisplayName = "Med Stop Mana%",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Thresholds",
        Index = 4,
        Tooltip = "When meditating, allow meditation to end when at or over this Mana percentage.",
        Default = 90,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['EndMedPct']                  = {
        DisplayName = "Med Start End%",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Thresholds",
        Index = 5,
        Tooltip = "Attempt to meditate when at or under this Endurance percentage.",
        Default = 60,
        Min = 1,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['EndMedPctStop']              = {
        DisplayName = "Med Stop End%",
        Group = "Movement",
        Header = "Meditation",
        Category = "Med Thresholds",
        Index = 6,
        Tooltip = "When meditating, allow meditation to end when at or over this Endurance percentage.",
        Default = 90,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },

    -- Clickies(Pre-Configured)
    ['ModRodUse']                  = {
        DisplayName = "Mod Rod Use:",
        Group = "Items",
        Header = "Clickies",
        Category = "General Clickies",
        Index = 1,
        Tooltip = "Use available Mod Rods or Azure Crystals when we have less that the Mod Rod Mana % setting.",
        Type = "Combo",
        ComboOptions = Globals.Constants.ModRodUse,
        Default = 2,
        Min = 1,
        Max = 3,
    },
    ['ModRodManaPct']              = {
        DisplayName = "Mod Rod Mana %",
        Group = "Items",
        Header = "Clickies",
        Category = "General Clickies",
        Index = 2,
        Tooltip = "Use the first available Mod Rod when at or under this mana percentage, as long as it won't kill us.",
        Default = 60,
        Min = 1,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['DoMount']                    = {
        DisplayName = "Summon Mount:",
        Group = "Items",
        Header = "Clickies",
        Category = "General Clickies",
        Index = 3,
        Tooltip = "Choose how/when to use mounts.",
        Type = "Combo",
        ComboOptions = { 'Never', 'For use as mount', 'For buff only', },
        Default = 2,
        Min = 1,
        Max = 3,
        ConfigType = "Normal",
    },
    ['MountItem']                  = {
        DisplayName = "Mount Item",
        Group = "Items",
        Header = "Clickies",
        Category = "General Clickies",
        Index = 4,
        Tooltip = "Mount Clicky item to use.",
        Type = "ClickyItem",
        Default = "",
        ConfigType = "Normal",
    },
    ['DoShrink']                   = {
        DisplayName = "Do Shrink",
        Group = "Items",
        Header = "Clickies",
        Category = "General Clickies",
        Index = 5,
        Tooltip = "Use Shrink items.",
        Default = false,
        ConfigType = "Normal",
    },
    ['ShrinkItem']                 = {
        DisplayName = "Shrink Item",
        Group = "Items",
        Header = "Clickies",
        Category = "General Clickies",
        Index = 6,
        Tooltip = "Item to use to Shrink yourself.",
        Type = "ClickyItem",
        Default = "",
        ConfigType = "Normal",
    },

    -- Pet/Pet Summoning
    ['DoPet']                      = {
        DisplayName = "Summon Pet",
        Group = "Abilities",
        Header = "Pet",
        Category = "Pet Summoning",
        Index = 1,
        Tooltip = "Enable the summoning and buffing of pets.",
        Default = true,
        ConfigType = "Normal",
    },

    -- Pet/Pet Buffs
    ['DoShrinkPet']                = {
        DisplayName = "Do Pet Shrink",
        Group = "Abilities",
        Header = "Pet",
        Category = "Pet Buffs",
        Index = 1,
        Tooltip = "Use a Shrink Clicky on your pet.",
        Default = false,
        ConfigType = "Normal",
    },
    ['ShrinkPetItem']              = {
        DisplayName = "Shrink Pet Item",
        Group = "Abilities",
        Header = "Pet",
        Category = "Pet Buffs",
        Index = 2,
        Tooltip = "Item to use to shrink your pet.",
        Type = "ClickyItem",
        Default = "",
        ConfigType = "Normal",
    },

    -- Behavior
    ['AggressivelyMemorizeSpells'] = {
        DisplayName = "Aggressively Mem Spells",
        Group = "Abilities",
        Header = "Behavior",
        Category = "Spell Management",
        Index = 1,
        Tooltip = "If you have a very latent connection, and spell memorization gets stuck, this will attempt to fix it by resending the memspell command every x seconds.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['AggressivelyMemorizeTimer']  = {
        DisplayName = "Aggressively Mem Timer",
        Group = "Abilities",
        Header = "Behavior",
        Category = "Spell Management",
        Index = 2,
        Tooltip = "How many seconds to wait before resending memspell commands when Aggressively Memorize Spells is enabled.",
        Default = 1,
        ConfigType = "Advanced",
    },

    -- Targeting
    ['DoAutoTarget']               = {
        DisplayName = "Auto Target",
        Group = "Combat",
        Header = "Targeting",
        Category = "Targeting Behavior",
        Index = 1,
        Tooltip =
        "MA: Allow RGMercs to scan for and assign targets in combat.\nNon-MA: Allow RGMercs to adjust your target to the MA-provided autotarget.\nTarget changes to use spells/songs/AA/items will occur, but you will return to your original target after doing so.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['StayOnTarget']               = {
        DisplayName = "Stay On Target",
        Group = "Combat",
        Header = "Targeting",
        Category = "Targeting Behavior",
        Index = 2,
        Tooltip = "Once an autotarget is assigned, do not change that target.\n(Note: This will greatly interfere with MA Target Scan capability.)",
        Default = false,
        ConfigType = "Advanced",
    },
    ['SafeTargeting']              = {
        DisplayName = "Use Safe Targeting",
        Group = "Combat",
        Header = "Targeting",
        Category = "Targeting Behavior",
        Index = 3,
        Tooltip = "Do not target mobs that are fighting others (except if those others pass safety checks, such as if they are DanNet peers.).",
        Default = true,
        ConfigType = "Advanced",
    },
    ['TargetNonAggressives']       = {
        DisplayName = "Target Non-Aggressives",
        Group = "Combat",
        Header = "Targeting",
        Category = "Targeting Behavior",
        Index = 4,
        Tooltip =
        "Allow targeting of NPCs that are not aggressive (hostile) if they are targeted by our MA.\nNote: If combat has been forced on the target (via a forcetarget command by this PC or the MA), the target will also be allowed.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['StopAttackForPCs']           = {
        DisplayName = "Stop Attack for PCs",
        Group = "Combat",
        Header = "Targeting",
        Category = "Targeting Behavior",
        Index = 5,
        Tooltip = "Ensure that auto attack is turned off before targeting a PC to use a spell, song, AA, or item. May be required if PvP is enabled by flag, zone, or server.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['AutoAttackSafetyCheck']      = {
        DisplayName = "Auto Attack Safety Check",
        Group = "Combat",
        Header = "Targeting",
        Category = "Targeting Behavior",
        Index = 6,
        Tooltip = "Turn off auto-attack if we are not in combat and not cleared to engage the current target.",
        Default = false,
    },

    ['ScanNamedPriority']          = {
        DisplayName = "Scan Priority:",
        Group = "Combat",
        Header = "Targeting",
        Category = "MA Target Selection",
        Index = 1,
        Tooltip = "Choose whether this PC will prioritize Named or Non-Named mobs if set as MA.",
        Type = "Combo",
        ComboOptions = Globals.Constants.ScanNamedPriority,
        Default = 1,
        Min = 1,
        Max = #Globals.Constants.ScanNamedPriority,
        ConfigType = "Advanced",
    },
    ['ScanHPPriority']             = {
        DisplayName = "Scan HP% Priority:",
        Group = "Combat",
        Header = "Targeting",
        Category = "MA Target Selection",
        Index = 2,
        Tooltip = "Choose whether this PC will prioritize low or high HP% mobs if set as MA.\n" ..
            "If no preference is selected, we will simply choose the lowest mob ID.",
        Type = "Combo",
        ComboOptions = Globals.Constants.ScanHPPriority,
        Default = 1,
        Min = 1,
        Max = #Globals.Constants.ScanHPPriority,
        ConfigType = "Advanced",
    },
    ['AreaScanFallback']           = {
        DisplayName = "Area Scan Fallback",
        Group = "Combat",
        Header = "Targeting",
        Category = "MA Target Selection",
        Index = 3,
        Tooltip = "Scan for targets via spawnsearch in the abscence of XTargets. Use with caution, can aggro mobs unintentionally.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['MAScanZRange']               = {
        DisplayName = "Main Assist Scan ZRange",
        Group = "Combat",
        Header = "Targeting",
        Category = "MA Target Selection",
        Index = 4,
        Tooltip = "Allowable height difference between mobs and the MA when scanning for targets.",
        Default = 45,
        Min = 15,
        Max = 200,
        ConfigType = "Advanced",
    },
    ['MAAggroScan']                = {
        DisplayName = "MA Aggro Scan",
        Group = "Combat",
        Header = "Targeting",
        Category = "MA Target Selection",
        Index = 5,
        Tooltip =
        "Scan hate levels of XT haters and set the AutoTarget to those who aren't aggroed on this PC. This may be necessary for MAs in Tank Mode who lack snap aggro abilities, but can also lead to further aggro issues on other targets. Use with caution.",
        Default = false,
        ConfigType = "Advanced",
        Warning = function()
            if Config:GetSetting('MAAggroScan') and Config:GetSetting('TankAggroScan') then
                return true,
                    "Warning: MA Aggro Scan and Tank Aggro Scan are both enabled, this may be inefficient (it is possible for them to both find the same target Id)."
            end
            return false, ""
        end,
    },
    --Remove the word "Beta" and change the default to true when the beta period is finished.
    ['TankAggroScan']              = {
        DisplayName = "Tank Aggro Scan",
        Group = "Combat",
        Header = "Targeting",
        Category = "Tank Target Selection",
        Index = 1,
        Tooltip =
            "Allow a PC in Tank Mode to independently select an xtarget to attempt to reclaim aggro, without affecting or changing the AutoTarget, even if they are also the MA.\n" ..
            "The tank will continue to engage the AutoTarget, but will periodically change to the Aggro Target to use abilities found in the HateTools(AggroTarget) rotation.\n" ..
            "If this tank is the MA, they will continue to broadcast the AutoTarget to any assisting RGMercs peer.",
        Default = true,
        ConfigType = "Advanced",
        Warning = function()
            if Config:GetSetting('MAAggroScan') and Config:GetSetting('TankAggroScan') then
                return true,
                    "Warning: MA Aggro Scan and Tank Aggro Scan are both enabled, this may be inefficient (it is possible for them to both find the same target Id)."
            end
            return false, ""
        end,
    },
    ['AggroScanRespectFT']         = {
        DisplayName = "Respect Forced Target",
        Group = "Combat",
        Header = "Targeting",
        Category = "Tank Target Selection",
        Index = 2,
        Tooltip = "If the Tank Aggro Scan is enabled and the current Auto Target is forced, stay on that target without switching to an Aggro Target.",
        Default = true,
    },

    -- Assisting
    ['DoAutoEngage']               = {
        DisplayName = "Auto Engage",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 1,
        Tooltip = "Automatically engage targets.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['AutoAssistAt']               = {
        DisplayName = "Auto Assist Percent",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 2,
        Tooltip = "Begin combat actions against the auto target when its reaches this health percentage.",
        Default = 98,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['AssistRange']                = {
        DisplayName = "Assist Range",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 3,
        Tooltip = "Engage the combat target when it is within this distance.",
        Default = 100,
        Min = 0,
        Max = 300,
        ConfigType = "Advanced",
        Warning = function()
            if Config:GetSetting('AssistRange') > Config:GetSetting('AutoCampRadius') then
                return true, "Warning: AssistRange exceeds AutoCampRadius - this might cause your characters to run out of camp to assist."
            end
            return false, ""
        end,
    },
    ['DoMelee']                    = {
        DisplayName = "Enable Melee Combat",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 4,
        Tooltip = "Auto attack the combat target.",
        Default = Globals.CurLoadedClass ~= "RNG" and Globals.Constants.RGMelee:contains(Globals.CurLoadedClass),
        ConfigType = "Normal",
    },
    ['AllowMezBreak']              = {
        DisplayName = "Allow Mez Break",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 5,
        Tooltip = "Allow combat actions if the target is mezzed.",
        Default = (Globals.Constants.RGTank:contains(mq.TLO.Me.Class.ShortName())),
        ConfigType = "Advanced",
    },
    ['DoPetCommands']              = {
        DisplayName = "Pet Control",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 6,
        Tooltip = "Allow RGMercs to issue pet commands.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['PetEngagePct']               = {
        DisplayName = "Pet Assist Percent",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 7,
        Tooltip = "Send pets to attack the combat target when it reaches this health percentage.",
        Default = 96,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['DoMercenary']                = {
        DisplayName = "Merc Control",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 8,
        Tooltip = "Allow RGMercs to issue mercenary commands. We plan to add selectable stances in a future update.",
        Default = (Globals.BuildType ~= 'Emu'),
        ConfigType = "Normal",
    },
    ['MercStance']                 = {
        DisplayName = "Merc Stance",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 9,
        Tooltip =
        "The stance to use for your merc. Since mercs have different stances, find the one for your current mercenary type.\nNote: an invalid stance selection will default to the first listed.",
        Type = "Combo",
        ComboOptions = { 'Aggressive or Balanced', 'Assist or Reactive or Burn', 'Efficient or BurnAE', },
        Default = 2,
        Min = 1,
        Max = 3,
        ConfigType = "Normal",
    },
    ['FollowMarkTarget']           = {
        DisplayName = "Follow Mark Target",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 10,
        Tooltip = "Prioritize the Marked target as the combat target.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['RaidAssistTarget']           = {
        DisplayName = "Raid Assist Target",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 11,
        Tooltip = "Which Raid Assist target to follow. Please note that we will not fallback if this is not set properly.",
        Type = "Combo",
        ComboOptions = { 'First', 'Second', 'Third', },
        Default = 1,
        Min = 1,
        Max = 3,
        ConfigType = "Normal",
    },
    ['SelfAssistFallback']         = {
        DisplayName = "Self-Assist Fallback",
        Group = "Combat",
        Header = "Assisting",
        Category = "Assisting",
        Index = 12,
        Tooltip = "If no other valid MA is found, fallback to ourselves.\nPlease note that when solo (and not using the Assist List), we are always our own MA.",
        Type = "Combo",
        ComboOptions = { 'Never', 'Only in Groups', 'Only in Raids', 'Always', },
        Default = 4,
        Min = 1,
        Max = 4,
        ConfigType = "Normal",
    },

    -- Positioning/General
    ['FaceTarget']                 = {
        DisplayName = "Face Target in Combat",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 1,
        Tooltip = "Periodically /face your target while in combat.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['StickHow']                   = {
        DisplayName = "Stick How",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 2,
        Tooltip = "Custom arguments for /stick command. Leave blank for default (varies on class).",
        Default = "",
        ConfigType = "Advanced",
        FAQ = "What are the default stick settings?",
        Answer = "   If the Stick How entry is left blank, we will use default stick settings as follows:\n" ..
            "If MA: < 10 moveback* uw >\n" ..
            "Others: < 10** behindonce moveback uw >\n\n" ..
            "* - Optional moveback flag (if 'Moveback As Tank' is enabled).\n" ..
            "** - On larger targets this value becomes 20.",
    },
    ['BellyCastStick']             = {
        DisplayName = "Stick for Belly Cast",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 3,
        Tooltip = "If Melee Combat is disabled, pin at 40 units on named with a dragon bodytype in case of possible bellycaster.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['AutoStandFD']                = {
        DisplayName = "Stand from FD in Combat",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 4,
        Tooltip = "Stand up if feigning at the start of combat.",
        Default = true,
        ConfigType = "Normal",
    },
    ['HandleCantSeeTarget']        = {
        DisplayName = "Handle Cannot See Target",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 5,
        Tooltip = "Attempt to adjust positioning if you receive a 'cannot see your target' message.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['HandleTooClose']             = {
        DisplayName = "Handle Too Close",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 6,
        Tooltip = "Attempt to adjust positioning if you receive a 'too close to use a ranged weapon' message.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['HandleTooFar']               = {
        DisplayName = "Handle Too Far",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 7,
        Tooltip = "Attempt to adjust positioning if you receive a 'too far away' or 'cant hit them from here' message.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['DoAutoNav']                  = {
        DisplayName = "Enable Auto Navigation",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 8,
        Tooltip = "Enables RGMercs to issue Navigation Commands in Combat. Disable if you wish to manually control movement.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['DoAutoStick']                = {
        DisplayName = "Enable Auto Stick",
        Group = "Combat",
        Header = "Positioning",
        Category = "General Positioning",
        Index = 8,
        Tooltip = "Enables RGMercs to issue Stick Commands in Combat. Disable if you wish to manually control movement.",
        Default = true,
        ConfigType = "Advanced",
    },

    -- Positioning/Tank
    ['MovebackWhenTank']           = {
        DisplayName = "Moveback as Tank",
        Group = "Combat",
        Header = "Positioning",
        Category = "Tank Positioning",
        Index = 1,
        Tooltip = "Adds 'moveback' to the default stick command when tanking. Helpful to keep mobs from getting behind you.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['MovebackWhenBehind']         = {
        DisplayName = "Moveback if Mob Behind",
        Group = "Combat",
        Header = "Positioning",
        Category = "Tank Positioning",
        Index = 2,
        Tooltip = "Initiates a stick moveback if we detect an XTarget is behind you when tanking.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['MovebackDistance']           = {
        DisplayName = "Units to Moveback",
        Group = "Combat",
        Header = "Positioning",
        Category = "Tank Positioning",
        Index = 3,
        Tooltip = "Distance from mob to moveback to. May require adjustment for larger targets or due to overshooting from high move speed.",
        Default = 20,
        Min = 1,
        Max = 40,
        ConfigType = "Advanced",
    },

    --Common/Rules
    ['MobLowHP']                   = {
        DisplayName = "Mob Low HP%",
        Group = "Abilities",
        Header = "Common",
        Category = "Common Rules",
        Index = 1,
        Tooltip = "A mob is considered to be low HP (for the sake of snares, dots and other abilities) under x HP%.",
        Default = 50,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['NamedLowHP']                 = {
        DisplayName = "Named Low HP%",
        Group = "Abilities",
        Header = "Common",
        Category = "Common Rules",
        Index = 2,
        Tooltip = "A named mob is considered to be low HP (for the sake of snares, dots and other abilities) under x HP%.",
        Default = 25,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['AggroThrottling']            = {
        DisplayName = "Use Aggro Throttling",
        Group = "Abilities",
        Header = "Common",
        Category = "Common Rules",
        Index = 3,
        Tooltip = "(Non-Tank Modes): Don't use nukes and similar spells when your aggro percent is above the Aggro To Cast value below.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['MobMaxAggro']                = {
        DisplayName = "Start Aggro Throttle:",
        Group = "Abilities",
        Header = "Common",
        Category = "Common Rules",
        Index = 4,
        Tooltip = "(Non-Tank Modes) Maximum % Aggro for most offensive actions if Aggro Throttling is enabled.",
        Default = 90,
        Min = 1,
        Max = 999,
        ConfigType = "Advanced",
    },
    ['LastGemRemem']               = {
        DisplayName = "Remem After Buff:",
        Group = "Abilities",
        Header = "Common",
        Category = "Common Rules",
        Index = 5,
        Tooltip = "Choose what do with the last gem slot after we use it to buff:\n" ..
            "Do Nothing: Use the slot as needed for buffs, but don't rememorize anything.\n" ..
            "Remem Previous Spell: Rememorize the spell that was in the slot before buffing, if there was one.\n" ..
            "Remem Loadout Spell: Rememorize the spell from the current loadout, if there is one.",
        Default = 3,
        Min = 1,
        Max = #Globals.Constants.LastGemRemem,
        Type = "Combo",
        ComboOptions = Globals.Constants.LastGemRemem,
        ConfigType = "Advanced",
    },
    ['IgnoreLevelCheck']           = {
        DisplayName = "Ignore Spell Level Checks",
        Group = "Abilities",
        Header = "Common",
        Category = "Common Rules",
        Index = 6,
        Tooltip = "Ignore checks for minimum level on spells. Used on servers that allow heals, buffs and other spells to land on PCs regardless of level.",
        Default = false,
        ConfigType = "Advanced",
    },
    -- Common/Under the Hood
    ['UseExactSpellNames']         = {
        DisplayName = "Use Exact Spell Names",
        Group = "Abilities",
        Header = "Common",
        Category = "Under the Hood",
        Index = 1,
        Tooltip = "This will cause RGMercs to use '/cast =<Spell>' which , must be supported by your MQ version but will avoid things like 'Bane' casting 'Bane of Nife' instead.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['CastReadyDelayFact']         = {
        DisplayName = "Cast Ready Delay Factor",
        Group = "Abilities",
        Header = "Common",
        Category = "Under the Hood",
        Index = 2,
        Tooltip = "Wait Ping * [n] ms before saying we are ready to cast.",
        Default = 0,
        Min = 0,
        Max = 10,
        ConfigType = "Advanced",
    },
    ['SongClipDelayFact']          = {
        DisplayName = "Song Clip Delay Factor",
        Group = "Abilities",
        Header = "Common",
        Category = "Under the Hood",
        Index = 3,
        Tooltip =
        "Wait Ping * [n] ms to allow songs to take effect before singing the next. If this is set too low, the server may not register the song completion before we /stopsong.\nSetting this lower will not increase performance, as we will stop delaying as soon as the song buff is detected. This is strictly to solve for song clipping for those with high latency!",
        Default = 2,
        Min = 1,
        Max = 10,
        ConfigType = "Advanced",
    },

    -- Damage/Direct
    ['ManaToNuke']                 = {
        DisplayName = "Mana to Nuke",
        Group = "Abilities",
        Header = "Damage",
        Category = "Direct",
        Index = 1,
        Tooltip =
        "Minimum % Mana in order to continue to cast nukes.\n\nThis setting is largely aimed at hybrids or healers maintaining a mana reserve. Some default configs (MAG, WIZ) may not always respect this setting.",
        Default = 30,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    --Damage/Over Time
    ['ManaToDot']                  = {
        DisplayName = "Mana to Dot",
        Group = "Abilities",
        Header = "Damage",
        Category = "Over Time",
        Index = 1,
        Tooltip =
        "Minimum % Mana in order to continue to cast dots.\n\nThis setting is largely aimed at hybrids or healers maintaining a mana reserve. Some default configs (NEC) may not always respect this setting.",
        Default = 30,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    -- Damage/AE
    ['DoAEDamage']                 = {
        DisplayName = "Do AE Damage",
        Group = "Abilities",
        Header = "Damage",
        Category = "AE",
        Index = 1,
        Tooltip = "**WILL BREAK MEZ** Use AE damage Spells and AA. **WILL BREAK MEZ**\n" ..
            "This is a top-level setting that governs all AE damage, and can be used as a quick-toggle to enable/disable abilities without reloading spells.",
        Default = false,
    },
    ['AETargetCnt']                = {
        DisplayName = "AE Target Count",
        Group = "Abilities",
        Header = "Damage",
        Category = "AE",
        Index = 2,
        Tooltip = "Minimum number of valid targets before using AE Disciplines or AA.",
        Default = 2,
        Min = 1,
        Max = 10,
    },
    ['MaxAETargetCnt']             = {
        DisplayName = "Max AE Targets",
        Group = "Abilities",
        Header = "Damage",
        Category = "AE",
        Index = 3,
        Tooltip =
        "Maximum number of valid targets before using AE Spells, Disciplines or AA.\nUseful for setting up AE Mez at a higher threshold on another character in case you are overwhelmed.",
        Default = 5,
        Min = 2,
        Max = 30,
        FAQ = "How do I take advantage of the Max AE Targets setting?",
        Answer =
        "By limiting your max AE targets, you can set an AE Mez count that is slightly higher, to allow for the possiblity of mezzing if you are being overwhelmed.",
    },
    ['SafeAEDamage']               = {
        DisplayName = "AE Proximity Check",
        Group = "Abilities",
        Header = "Damage",
        Category = "AE",
        Index = 4,
        Tooltip = "Check to ensure there aren't neutral mobs in range we could aggro if AE damage is used. May result in non-use due to false positives.",
        Default = false,
        FAQ = "Can you better explain the AE Proximity Check?",
        Answer = "If the option is enabled, the script will use various checks to determine if a non-hostile or not-aggroed NPC is present and avoid use of the AE action.\n" ..
            "Unfortunately, the script currently does not discern whether an NPC is (un)attackable, so at times this may lead to the action not being used when it is safe to do so.\n" ..
            "PLEASE NOTE THAT THIS OPTION HAS NOTHING TO DO WITH MEZ!",
    },

    -- Debuffs
    ['ManaToDebuff']               = {
        DisplayName = "Mana to Debuff",
        Group = "Abilities",
        Header = "Debuffs",
        Category = "Debuff Rules",
        Index = 1,
        Tooltip = "Minimum % Mana in order to continue to cast debuffs.",
        Default = 10,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['DebuffMinCon']               = {
        DisplayName = "Debuff Min Con",
        Group = "Abilities",
        Header = "Debuffs",
        Category = "Debuff Rules",
        Index = 2,
        Tooltip = "Min Con to use debuffs on when con-color debuffing is enabled for enemies.",
        Default = 4,
        Min = 1,
        Max = #Globals.Constants.ConColors,
        Type = "Combo",
        ComboOptions = Globals.Constants.ConColors,
        ConfigType = "Advanced",
    },
    ['MobDebuff']                  = {
        DisplayName = "Mob Debuffing:",
        Group = "Abilities",
        Header = "Debuffs",
        Category = "Debuff Rules",
        Index = 3,
        Tooltip = "The circumstances in which we will debuff a (non-named) mob.",
        Default = 2,
        Min = 1,
        Max = #Globals.Constants.DebuffChoice,
        Type = "Combo",
        ComboOptions = Globals.Constants.DebuffChoice,
        ConfigType = "Advanced",
    },
    ['NamedDebuff']                = {
        DisplayName = "Named Debuffing:",
        Group = "Abilities",
        Header = "Debuffs",
        Category = "Debuff Rules",
        Index = 4,
        Tooltip = "The circumstances in which we will debuff a (named) mob.",
        Default = 2,
        Min = 1,
        Max = #Globals.Constants.DebuffChoice,
        Type = "Combo",
        ComboOptions = Globals.Constants.DebuffChoice,
        ConfigType = "Advanced",
    },

    -- Emergency
    ['StandFailedFD']              = {
        DisplayName = "Stand on Failed FD",
        Group = "Abilities",
        Header = "Utility",
        Category = "Emergency",
        Index = 1,
        Tooltip = "Stand up if a failed feign is detected ('fall to the ground').",
        Default = true,
        ConfigType = "Advanced",
    },

    -- Buffs/Rules
    ['DoBuffs']                    = {
        DisplayName = "Do Downtime/Group Buffs",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 1,
        Tooltip = "Process Downtime and Group Buff Rotations (see your rotations on the class tab).",
        Default = true,
        ConfigType = "Advanced",
    },
    ['BuffWaitMoveTimer']          = {
        DisplayName = "After-Move Buff Delay",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 2,
        Tooltip = "Seconds to wait after stoping movement before doing buffs.",
        Default = 5,
        Min = 0,
        Max = 60,
        ConfigType = "Advanced",
    },
    ['BuffRezables']               = {
        DisplayName = "Buff Rezables",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 3,
        Tooltip =
        "If a PC has a corpse near us, buff them even though they are likely to get rezed. (Note: If disabled, they may still be receiving group buffs aimed at those without corpses.)",
        Default = false,
        ConfigType = "Advanced",
    },
    ['UseCounterActions']          = {
        DisplayName = "Use Aureate's Bane", --this can be freely changed later if another system is added. Avoiding confusion for now.
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 4,
        Tooltip =
        "Automatically use counter actions (such as the Aureate's Bane AA to counter Curse of Subjugation in TOB zones.",
        Default = (mq.TLO.MacroQuest.BuildName() or ""):lower() ~= "emu",
    },
    ['BreakInvisForSay']           = {
        DisplayName = "Break Invis for Say Commands",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 5,
        Tooltip = "Break Invis as part of /rgl say, qsay or rsay commands.",
        Default = false,
    },
    ['ActorBuffScope']             = {
        DisplayName = "Actor Buff Scope",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 6,
        Tooltip =
        "Choose who to use group buffs on. Please note that we will only buff raid/in-zone if they are actor peers (other PCs running RGMercs on the local computer/network).",
        Default = 1,
        Min = 1,
        Max = 3,
        Type = "Combo",
        ComboOptions = { 'Group', 'Raid', 'Any In-Zone', },
        ConfigType = "Advanced",
    },
    ['BuffAssistList']             = {
        DisplayName = "Buff Assist List",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 8,
        Tooltip = "Process group buff rotations on members of the Asist List.",
        Default = true,
    },
    ['DoActorPetBuffs']            = {
        DisplayName = "Buff Pets as PCs",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Buff Rules",
        Index = 6,
        Tooltip =
        "Allow group pets to be targeted in PC group buff rotations.\nNote that only the pets buffs of PCs who have this setting enabled are discoverable.\nFurther note this incurs a minor performance penalty and is not advised in most situations.",
        Default = false,
        OnChange = function(oldValue, newValue)
            if newValue == false then
                Globals.CurrentPetBuffs = nil
                Globals.CurrentPetBlocked = nil
            end
        end,
    },

    -- Buffs/Self
    ['DoAlliance']                 = {
        DisplayName = "Do Alliance",
        Group = "Abilities",
        Header = "Buffs",
        Category = "Self",
        Index = 99,
        Tooltip = "Enable the use of Alliance spells.",
        Default = false,
        ConfigType = "Advanced",
    },

    --Recovery/General
    ['DoPetHeals']                 = {
        DisplayName = "Heal Pets as PCs",
        Group = "Abilities",
        Header = "Recovery",
        Category = "General Healing",
        Index = 1,
        Tooltip = "Allow pets of your groupmates to be targeted in PC healing rotations.\n" ..
            "Note that CLR/DRU/PAL/SHM will reserve \"Big Heal\" rotations for PCs.\n" ..
            "Further note that many abilities that heal the PC's own pet do not check this setting and are handled seperately.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['BreakInvisForHealing']       = {
        DisplayName = "Break Invis",
        Group = "Abilities",
        Header = "Recovery",
        Category = "General Healing",
        Index = 2,
        Tooltip = "Break invis to heal, cure and rez when out of combat (Does not affect combat actions).",
        Default = false,
        ConfigType = "Advanced",
    },
    -- Recovery/Thresholds
    ['MaxHealPoint']               = {
        DisplayName = "Healing Threshold",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 1,
        Tooltip = "Minimum PctHPs of any valid target to process healing rotations.",
        Default = 90,
        Min = 1,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['LightHealPoint']             = {
        DisplayName = "Light Heal Point",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 2,
        Tooltip = "Minimum PctHPs to use the Light Heal Rotation or actions that check whether Light Heals are needed.",
        Default = mq.TLO.Me.Class.ShortName() == "CLR" and 95 or 90,
        Min = 1,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['MainHealPoint']              = {
        DisplayName = "Main Heal Point",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 3,
        Tooltip = "Minimum PctHPs to use the Main Heal Rotation or actions that check whether Main Heals are needed.",
        Default = 80,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['BigHealPoint']               = {
        DisplayName = "Big Heal Point",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 4,
        Tooltip = "Minimum PctHPs to use the Big Heal Rotation or actions that check whether BigHeals are needed.",
        Default = 50,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['GroupHealPoint']             = {
        DisplayName = "Group Heal Point",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 5,
        Tooltip = "Minimum PctHPs to use the Group Heal Rotation or actions that check whether Group Heals are needed.",
        Default = 75,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    ['GroupInjureCnt']             = {
        DisplayName = "Group Injured Count",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 6,
        Tooltip = "Number of group members that must be under the Group Heal Point percentage threshold.",
        Default = 3,
        Min = 1,
        Max = 5,
        ConfigType = "Advanced",
    },
    ['PetHealPoint']               = {
        DisplayName = "Pet Heal Point",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Healing Thresholds",
        Index = 7,
        Tooltip = "Minimum PctHPs to process standard PC Healing Rotations on pets (if enabled). See 'Heal Pets as PCs' setting.",
        Default = 50,
        Min = 1,
        Max = 100,
        ConfigType = "Advanced",
    },
    --Recovery/Curing
    ['DoCureSpells']               = {
        DisplayName = "Do Cure Spells",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Curing",
        Index = 1,
        Tooltip = "Use Cure spells to clear detrimental effects from your group or yourself.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['DoCureAA']                   = {
        DisplayName = "Do Cure AA",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Curing",
        Index = 2,
        Tooltip = "Use Cure AA to clear detrimental effects from your group or yourself.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['CureInterval']               = {
        DisplayName = "Downtime Cure Check Interval",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Curing",
        Index = 3,
        Tooltip = "The delay in seconds between making cure checks during downtime (to prevent unnecessary queries).",
        Default = 5,
        Min = 1,
        Max = 30,
        ConfigType = "Advanced",
    },
    ['StaggerGroupAACures']        = {
        DisplayName = "Stagger Group AA Cures",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Curing",
        Index = 4,
        Tooltip = "If you detect an actor peer already casting Radiant Cure or Group Purify Soul on a groupmate, do not check if cures are needed until they are finished.\n" ..
            "This is a 'best-effort' setting that tries to avoid multiple healers using group AA cures at once on the same effect. It does not check for other spells. It is not foolproof.",
        Default = true,
        ConfigType = "Advanced",
    },

    --Recovery/Rezzing
    ['DoRez']                      = {
        DisplayName = "Do Rez",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Rezzing",
        Index = 1,
        Tooltip = "Use Rezes. If disabled, no rez spells will be used at any time.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['DoBattleRez']                = {
        DisplayName = "Do Battle Rez",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Rezzing",
        Index = 2,
        Tooltip = "Enable rezzing while in combat",
        Default = mq.TLO.Me.Class.ShortName():lower() == "clr",
        ConfigType = "Advanced",
    },
    ['RezOutside']                 = {
        DisplayName = "Rez Outside",
        Group = "Abilities",
        Header = "Recovery",
        Category = "General Healing",
        Index = 3,
        Tooltip = "Rez dannet peers, raid/guildmates, and anyone in the Assist List (and not simply your own group).",
        Default = true,
        ConfigType = "Advanced",
    },
    ['RetryRezDelay']              = {
        DisplayName = "Retry Rez Delay",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Rezzing",
        Index = 4,
        Tooltip = "Delay in seconds between rez attempts.",
        Default = 6,
        Min = 1,
        Max = 60,
        ConfigType = "Advanced",
    },
    ['RezInZonePC']                = {
        DisplayName = "Rez In-Zone PCs",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Rezzing",
        Index = 5,
        Tooltip = "Rez corpses of live PCs in the zone (If disabled, we will only rez corpses of PCs not in our current zone).Note that we will not rez in-zone PCs during combat.",
        Default = true,
        ConfigType = "Advanced",
        FAQ = "Why would I want (or not want) to rez corpses of PCs that are in-zone with us already?",
        Answer = "Emu servers have various rules, such as no xp loss on death, or not dropping items to your corpse\n" ..
            "Depending in the server, various combinations of rez settings may be required for the best play experience.",
    },
    ['ConCorpseForRez']            = {
        DisplayName = "Check for Previous Rez",
        Group = "Abilities",
        Header = "Recovery",
        Category = "Rezzing",
        Index = 6,
        Tooltip = "If this setting is enabled, we will attempt to con a corpse and rez only if that corpse has not yet taken one.",
        Default = (mq.TLO.MacroQuest.BuildName() or ""):lower() == "emu",
        ConfigType = "Advanced",
        FAQ = "Why am I conning corpses? I play on a server with no exp penalty, or where we don't need to loot corpses.",
        Answer = "The Check for Previous Rez setting is enabled by default on emu, this can be adjusted on the Heal/Rez options tab.",
    },

    -- Burning
    ['BurnAuto']                   = {
        DisplayName = "Use Auto Burn",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 1,
        Tooltip = "Use Burn rotations when the conditions below are met.",
        Default = true,
        ConfigType = "Normal",
    },
    ['BurnAlways']                 = {
        DisplayName = "Auto Burn: Always",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 2,
        Tooltip = "Automatically use Burn rotations on any/every target.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['BurnMobCount']               = {
        DisplayName = "Auto Burn: Mob Threshold",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 4,
        Tooltip = "Automatically use Burn rotations when we are fighting x number of haters.",
        Default = 3,
        Min = 1,
        Max = 10,
        ConfigType = "Advanced",
    },
    ['BurnNamed']                  = {
        DisplayName = "Auto Burn: Named",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 5,
        Tooltip = "Automatically use Burn rotations when we are fighting a named mob(must be present in RGMerc Named List or detected with SpawnMaster or Alert Master).",
        Default = true,
        ConfigType = "Advanced",
    },
    ['NamedMinLevel']              = {
        DisplayName = "Named Min Level",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 6,
        Tooltip = "The minimum level we will treat a Named as a threat (if below this level, we will treat them as trash mobs).",
        Default = 1,
        Min = 1,
        Max = 150,
        ConfigType = "Advanced",
    },
    ['CheckSMForNamed']            = {
        DisplayName = "Check SM For Named",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 7,
        Tooltip = "Treat your target as 'named' if present on your MQ2SpawnMaster list (uses the SpawnMaster TLO).",
        Default = true,
        ConfigType = "Advanced",
    },
    ['CheckAMForNamed']            = {
        DisplayName = "Check AM For Named",
        Group = "Combat",
        Header = "Burning",
        Category = "Burning",
        Index = 8,
        Tooltip = "Treat your target as 'named' if present on your Alert Master list (uses the Alert Master TLO).",
        Default = true,
        ConfigType = "Advanced",
    },


    -- [ UI ] --
    ['DisplayManualTarget']              = {
        DisplayName = "Display Manual Target",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Index = 1,
        Tooltip = "If you have no auto target, enabling this will show information about your current manual target in the UI.",
        Default = false,
    },
    ['HPBarStyle']                       = {
        DisplayName = "Target HP Bar Style",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Index = 2,
        Tooltip = "The method for coloring the HP display of your manual target (if enabled).",
        Default = 2,
        Min = 1,
        Max = #Globals.Constants.HPBarStyles,
        Type = "Combo",
        ComboOptions = Globals.Constants.HPBarStyles,
    },
    ['OverrideHP']                       = {
        DisplayName = "Override HP Display",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Type = "Custom",
        Index = 0,
        Tooltip = "If you have no auto target, enabling this will show information about your current manual target in the UI.",
        Default = 0,
        Min = 0,
        Max = 100,
    },
    ['AlwaysShowMiniButton']             = {
        DisplayName = "Always Show Mini Button",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Index = 3,
        Tooltip = "Always show the RGMercs Mini Mode button, even when the main window is displayed.",
        Default = false,
        ConfigType = "Normal",
    },
    ['EscapeMinimizes']                  = {
        DisplayName = "Escape Closes Main Window",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Index = 4,
        Tooltip = "In always-show mini button mode, closes the main window with escape if enabled.",
        Default = false,
        ConfigType = "Normal",
    },
    ['ShowDebugTiming']                  = {
        DisplayName = "Show Rotation Debug Timing",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Index = 5,
        ConfigType = "Advanced",
        Tooltip = "Enable displaying the timing of each rotation step.",
        Default = false,
    },
    ['BgOpacity']                        = {
        DisplayName = "Background Opacity",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 6,
        Tooltip = "Opacity for the RGMercs UI",
        Default = 100,
        Min = 20,
        Max = 100,
    },
    ['SavePositionPerCharacter']         = {
        DisplayName = "Save Window Position per Char",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 6,
        Tooltip = "Save window positions separately for each character.",
        Default = false,
    },
    ['FrameEdgeRounding']                = {
        DisplayName = "Frame Edge Rounding",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 7,
        Tooltip = "Frame Edge Rounding for the RGMercs UI",
        Default = 6,
        Min = 0,
        Max = 50,
    },
    ['ScrollBarRounding']                = {
        DisplayName = "Scroll Bar Rounding",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 8,
        Tooltip = "Frame Edge Rounding for the RGMercs UI",
        Default = 10,
        Min = 0,
        Max = 50,
    },
    ['WarnCombatPaused']                 = {
        DisplayName = "Warn on Combat While Paused",
        Group = "General",
        Header = "Interface",
        Category = "Main Panel",
        Index = 9,
        Tooltip = "If we gain aggro while paused, display a warning in the chat window.",
        Default = true,
    },
    ['ShowFTControls']                   = {
        DisplayName = "Show ForceTarget Controls",
        Group = "General",
        Header = "Interface",
        Category = "ForceTarget Window",
        Index = 10,
        Tooltip = "Show ForceTarget controls to clear/set forced targets.",
        Default = false, -- defaulted to false just to annoy Algar
    },
    ['FTHPOverlay']                      = {
        DisplayName = "HP % Overlay for ForceTarget Window",
        Group = "General",
        Header = "Interface",
        Category = "ForceTarget Window",
        Index = 11,
        Tooltip = "Show a HP bar overlay on your forced target (if enabled)",
        Default = false,
    },
    ['FTHPOverlayAlpha']                 = {
        DisplayName = "Not Targeted HP % Overlay Alpha",
        Group = "General",
        Header = "Interface",
        Category = "ForceTarget Window",
        Index = 12,
        Tooltip = "Opacity for the HP bar overlay on your forced target (if enabled) for non-targeted mobs",
        Default = 30,
        Min = 0,
        Max = 100,
    },
    ['StatusUseBars']                    = {
        DisplayName = "Progress Bars in MercsStatus Window",
        Group = "General",
        Header = "Interface",
        Category = "Mercs Status Window",
        Index = 13,
        Tooltip = "Use bars to display HP and other info in the Mercs Status Window instead of text.",
        Default = false,
    },
    ['StatusLeftClickAction']            = {
        DisplayName = "Mercs Status Left-Click Action",
        Group = "General",
        Header = "Interface",
        Category = "Mercs Status Window",
        Index = 14,
        Tooltip = "Action to perform when left-clicking a name in the Mercs Status Window",
        Type = "Combo",
        ComboOptions = { 'Target', 'Switch To', 'Do Nothing', },
        Default = 1,
        Min = 1,
        Max = 3,
        ConfigType = "Advaced",
    },
    ['StatusLeftClickCursorClickAction'] = {
        DisplayName = "Mercs Status Cursor+Left-Click Action",
        Group = "General",
        Header = "Interface",
        Category = "Mercs Status Window",
        Index = 15,
        Tooltip = "Action to perform when left-clicking a name in the Mercs Status Window while having an item on your cursor.",
        Type = "Combo",
        ComboOptions = { 'Trade', 'Ignore Cursor Item', },
        Default = 1,
        Min = 1,
        Max = 2,
        ConfigType = "Advaced",
    },
    ['StatusRightClickAction']           = {
        DisplayName = "Mercs Status Right-Click Action",
        Group = "General",
        Header = "Interface",
        Category = "Mercs Status Window",
        Index = 16,
        Tooltip = "Action to perform when right-clicking a name in the Mercs Status Window",
        Type = "Combo",
        ComboOptions = { 'Target', 'Switch To', 'Do Nothing', },
        Default = 2,
        Min = 1,
        Max = 3,
        ConfigType = "Advaced",
    },
    ['ActorPeerTimeout']                 = {
        DisplayName = "Actor Peer Timeout",
        Group = "General",
        Header = "Interface",
        Category = "Mercs Status Window",
        Index = 17,
        Tooltip = "Time in seconds to wait before considering a peer disconnected.",
        Default = 45,
        Min = 10,
        Max = 120,
    },
    ['PopoutWindowsLockWithMain']        = {
        DisplayName = "Lock Popout Windows with Main",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 18,
        Tooltip = "Popout windows will lock/unlock when the main window is locked/unlocked.",
        Default = true,
    },
    ['EnableAAOverlay']                  = {
        DisplayName = "Enable AA Overlay",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 19,
        Tooltip = "Show an overlay on the AA window that tells you which AAs are used by RGMercs rotations.",
        Default = true,
    },
    ['DisableToggleButtonPulse']         = {
        DisplayName = "Disable Toggle Button Pulse",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 20,
        Tooltip = "Disable the pulsing effect toggle buttons.",
        Default = false,
    },
    ['EnableAnimatedTooltips']           = {
        DisplayName = "Enable Animated Tooltips",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 21,
        Tooltip = "Enable animated tooltips (fade in/out). Disabling this will make tooltips appear/disappear instantly.",
        Default = true,
    },
    ['FontScale']                        = {
        DisplayName = "Font Scale %",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Index = 22,
        Tooltip = "Scale for all fonts used in the UI.",
        Default = 0,
        Min = 0,
        Max = 100,
    },

    -- [ UI Colors ] --
    ['MainButtonUnpausedColor']          = {
        DisplayName = "Main Button Unpaused",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 11,
        Tooltip = "Color used for the main button when RGMercs is unpaused.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.MainButtonUnpausedColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['MainButtonPausedColor']            = {
        DisplayName = "Main Button Paused",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 12,
        Tooltip = "Color used for the main button when RGMercs is paused.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.MainButtonPausedColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['HPHighColor']                      = {
        DisplayName = "HP High",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 13,
        Tooltip = "Color used to display high HP values.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.HPHighColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['HPLowColor']                       = {
        DisplayName = "HP Low",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 15,
        Tooltip = "Color used to display low HP values.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.HPLowColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['ManaHighColor']                    = {
        DisplayName = "Mana High",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 16,
        Tooltip = "Color used to display high Mana values.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.ManaHighColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['ManaLowColor']                     = {
        DisplayName = "Mana Low",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 18,
        Tooltip = "Color used to display low Mana values.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.ManaLowColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['ConditionPassColor']               = {
        DisplayName = "Condition Pass",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 19,
        Tooltip = "Color used to display a passing condition",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.ConditionPassColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['ConditionMidColor']                = {
        DisplayName = "Condition Mid (between pass/fail)",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 20,
        Tooltip = "Color used to display an unevaluated condition",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.ConditionMidColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['ConditionFailColor']               = {
        DisplayName = "Condition Fail",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 21,
        Tooltip = "Color used to display a failing condition",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.ConditionFailColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['ConditionDisabledColor']           = {
        DisplayName = "Condition Disabled",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 22,
        Tooltip = "Color used to display a disabled condition",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.ConditionDisabledColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['MainCombatColor']                  = {
        DisplayName = "Combat",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 23,
        Tooltip = "Color used for the UI elements when in combat.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.MainCombatColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['MainDowntimeColor']                = {
        DisplayName = "Downtime",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 24,
        Tooltip = "Color used for the main window border when out of combat.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.MainDowntimeColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },

    ['SearchHighlightColor']             = {
        DisplayName = "Search Highlight",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 19,
        Tooltip = "Color used to highlight search terms in various windows.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.SearchHighlightColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['AssistSpawnFarColor']              = {
        DisplayName = "Assist Spawn Text If Far",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 21,
        Tooltip = "Color used to display an assist spawn that is far from us.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.AssistSpawnFarColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['BurnFlashColorOne']                = {
        DisplayName = "Burn Burn Flash Color One",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 22,
        Tooltip = "First of two colors to use when flashing burn status message.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.BurnFlashColorOne),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['BurnFlashColorTwo']                = {
        DisplayName = "Burn Burn Flash Color Two",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 23,
        Tooltip = "Second of two colors to use when flashing burn status message.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.BurnFlashColorTwo),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['FTHighlight']                      = {
        DisplayName = "ForceTarget Highlight",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 24,
        Tooltip = "Force Target Highlight border in the Force Target Window.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.FTHighlight),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['CharmReasonColor']                 = {
        DisplayName = "Charm Immune Reason Text",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 25,
        Tooltip = "Color used to display the reason we cannot charm a target.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.CharmReasonColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['FAQCmdQuestionColor']              = {
        DisplayName = "FAQ Command / Question Text",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 26,
        Tooltip = "Color used to display commands in the FAQ section of the Help Window.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.FAQCmdQuestionColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['FAQUsageAnswerColor']              = {
        DisplayName = "FAQ Usage / Answer Text",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 27,
        Tooltip = "Color used to display usage and answer text in the FAQ section of the Help Window.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.FAQUsageAnswerColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['FAQDescColor']                     = {
        DisplayName = "FAQ Description Text",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 28,
        Tooltip = "Color used to display description text in the FAQ section of the Help Window.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.FAQDescColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['FAQLinkColor']                     = {
        DisplayName = "FAQ Link Text",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 29,
        Tooltip = "Color used to display link text in the FAQ section of the Help Window.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.FAQLinkColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['TogglePulseColor']                 = {
        DisplayName = "Toggle Button Pulse",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 30,
        Tooltip = "Color used for the pulsing effect on toggle buttons (if enabled).",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.TogglePulseColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },
    ['TooltipTextColor']                 = {
        DisplayName = "Tooltip Text Color",
        Group = "General",
        Header = "Interface",
        Category = "Default Colors",
        Index = 31,
        Tooltip = "Color used for text in tooltips.",
        Default = Tables.ImVec4ToTable(Globals.Constants.DefaultColors.TooltipTextColor),
        Type = "Color",
        OnChange = function(_, _)
            Config.CacheCustomColors()
        end,
    },

    ['UserThemeOverrideClassTheme']      = {
        DisplayName = "Override Class Theme",
        Group = "General",
        Header = "Interface",
        Category = "User Theme",
        Index = 40,
        Tooltip = "User the user theme even if a class theme is defined.",
        Default = true,
        Type = "Custom",
    },
    ['UserTheme']                        = {
        DisplayName = "User Theme",
        Group = "General",
        Header = "Interface",
        Category = "User Theme",
        Index = 41,
        Tooltip = "Override any ImGui style settings with a custom theme.",
        Default = {},
        Type = "Custom",
    },

    -- [Internals] --
    ['LogLevel']                         = {
        DisplayName = "Log Level",
        Category = "Internals",
        Type = "Combo",
        ComboOptions = Globals.Constants.LogLevels,
        Default = 3,
        Min = 1,
        Max = #Globals.Constants.LogLevels,
    },
    ['LogFilter']                        = {
        DisplayName = "Log Filter",
        Category = "Internals",
        Default = "",
        OnChange = function(_, newValue)
            if newValue:len() == 0 then
                Logger.clear_log_filter()
            else
                Logger.set_log_filter(newValue)
            end
        end,
    },
    ['EnableLogTracer']                  = {
        DisplayName = "Enable Debug Tracer",
        Category = "Internals",
        Default = true,
        Tooltip = "Enables the debug tracer to show file/function/line information for each log entry",
        OnChange = function(_, newValue)
            Logger.set_debug_tracer_enabled(newValue)
        end,
    },
    ['LogToFile']                        = {
        DisplayName = "Log To File",
        Category = "Internals",
        --Type = "Custom",
        Default = false,
    },
    ['LogTimeStampsToConsole']           = {
        DisplayName = "Log Timestamps To RGMercs Console",
        Category = "Internals",
        --Type = "Custom",
        Default = false,
        OnChange = function(_, newValue)
            Logger.set_log_timestamps_to_console(newValue)
        end,
    },
    ['EnableDebugging']                  = {
        DisplayName = "Enable Debugging",
        Category = "Internals",
        Index = 0,
        Tooltip = "Enable the Debug Panel",
        Default = false,
        ConfigType = "Advanced",
    },

    ['DrawTooltipDebugBox']              = {
        DisplayName = "Draw Tooltip Debug Box",
        Category = "Internals",
        Index = 2,
        Tooltip = "Draw a box around the tooltip to help identify its boundaries for debugging purposes.",
        Default = false,
        ConfigType = "Advanced",
    },

    ['LootModuleType']                   = {
        DisplayName = "Loot Module Type",
        Group = "General",
        Header = "Loot(Emu)",
        Category = "Looting Script",
        Index = 10,
        Tooltip = "Choose which loot module to use.",
        Default = 1,
        Min = 1,
        Max = #Globals.Constants.LootModuleTypes,
        Type = "Combo",
        ComboOptions = Globals.Constants.LootModuleTypes,
        OnChange = function(oldValue, newValue)
            if Globals.BuildType:lower() ~= "emu" and newValue > 1 then
                Logger.log_error("\ayLoot Modules are not used on offical servers.")
                Config:SetSetting("LootModuleType", 1, false)
                return
            end
            local oldLootModule = Globals.Constants.LootModuleTypes[oldValue]
            local newLootModule = Globals.Constants.LootModuleTypes[newValue]
            Logger.log_info("\ayLoot Module changed from %s to: \ag%s", oldLootModule or "Unknown", newLootModule or "Unknown")
            Modules:unloadModule(oldLootModule)
            Config:ClearModuleSettings(oldLootModule)
            if newValue > 1 then
                local path = string.format("modules." .. newLootModule:lower())
                Logger.log_info("\ayLoot Module: \ag%s", newLootModule:lower() or "Unknown")
                Modules:loadModule(newLootModule, path)
                Config:UpdateCommandHandlers()
            end
        end,
    },

    ['HasConvertedToDB']                 = {
        DisplayName = "Has Converted To DB",
        Category = "Internals",
        Type = "Custom",
        Default = false,
    },

    --Tanking
    ['AETauntCnt']                       = {
        DisplayName = "AE Taunt Count",
        Group = "Abilities",
        Header = "Tanking",
        Category = "Hate Tools",
        Index = 111,
        Tooltip = "Minimum number of haters before using AE Taunt Spells or AA when we have less than 100% aggro on one or more of them in range.",
        Default = 2,
        Min = 1,
        Max = 30,
    },
    ['SafeAETaunt']                      = {
        DisplayName = "AE Taunt Safety Check",
        Group = "Abilities",
        Header = "Tanking",
        Category = "Hate Tools",
        Index = 112,
        Tooltip = "Check to ensure there aren't neutral mobs in range we could aggro if AE taunts are used. May result in non-use due to false positives.",
        Default = false,
        FAQ = "Can you better explain the AE Taunt Safety Check?",
        Answer = "If the option is enabled, the script will use various checks to determine if a non-hostile or not-aggroed NPC is present and avoid use of the taunt.\n" ..
            "Unfortunately, the script currently does not discern whether an NPC is (un)attackable, so at times this may lead to the taunt not being used when it is safe to do so.",
    },

    --Deprecated/Need Adjusted to Custom/Etc
    ['FullUI']                           = {
        DisplayName = "Use Full UI",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Tooltip = "Toggle between Full UI and a Simple UI [Experimental]",
        Default = true,
    },
    ['EnableOptionsUI']                  = {
        DisplayName = "Enable Options UI",
        Type = "Custom",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Tooltip = "Show the experimental Options UI window",
        Default = false,
    },
    ['EnableAFUI']                       = {
        DisplayName = "Enable Very Fun UI",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Tooltip = "???",
        Default = false,
    },
    ['ForceAFUIOff']                     = {
        DisplayName = "Force Very Fun UI Off",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Tooltip = "???",
        Type = "Custom",
        Default = false,
    },
    ['123EyesOnMe']                      = {
        DisplayName = "1,2,3 Eyes On Me",
        Group = "General",
        Header = "Interface",
        Category = "Interface",
        Tooltip = "Derple Dog Watches You While You Sleep",
        Default = false,
    },
}

Config.CommandHandlers                                   = {}

Config.CachedConfigFileNames                             = {}

function Config.GetConfigFileName(moduleName, returnExisting)
    if Config.CachedConfigFileNames[moduleName] then
        return Config.CachedConfigFileNames[moduleName]
    end

    local schemas = {
        mq.configDir .. '/rgmercs/PCConfigs/' ..
        moduleName .. "_" .. Globals.CurServer .. "_" .. Globals.CurLoadedChar .. '.lua',
        mq.configDir .. '/rgmercs/PCConfigs/' ..
        moduleName .. "_" .. Globals.CurServerNormalized .. "_" .. Globals.CurLoadedChar .. '.lua',
        mq.configDir .. '/rgmercs/PCConfigs/' ..
        moduleName .. "_" .. Globals.CurServerNormalized .. "_" .. Globals.CurLoadedChar .. "_" .. Globals.CurLoadedClass:lower() .. '.lua',
        string.format("%s/rgmercs/PCConfigs/%s/%s/%s/%s.lua", mq.configDir, Globals.CurServerNormalized, Globals.CurLoadedChar, Globals.CurLoadedClass:lower(),
            moduleName),
    }

    local latestSchema = #schemas
    local latest = schemas[latestSchema]
    Config.CachedConfigFileNames[moduleName] = latest

    -- If latest exists, delete all older schemas
    if Files.file_exists(latest) then
        for i = 1, latestSchema - 1 do
            if Files.file_exists(schemas[i]) then
                Logger.log_info("Removing old v%d config for %s module.", i, moduleName)
                Files.delete_file(schemas[i])
            end
        end
        return latest
    end

    -- Otherwise find newest existing older schema (from newest to oldest)
    for i = latestSchema - 1, 1, -1 do
        if Files.file_exists(schemas[i]) then
            Logger.log_info("Upgrading config from v%d to v%d for %s module.", i, latestSchema, moduleName)

            if returnExisting == true then
                return schemas[i]
            end

            Files.copy_file(schemas[i], latest)
            return latest
        end
    end

    -- Nothing exists, return latest path
    return latest
end

function Config:SaveSettings()
    local configFile = Config.GetConfigFileName("RGMercs")
    mq.pickle(configFile, self:GetModuleSettings("Core"))
    Logger.log_debug("\agRGMercs settings saved to %s", configFile)
    Logger.set_log_level(Config:GetSetting('LogLevel'))
    Logger.set_log_to_file(Config:GetSetting('LogToFile'))
end

function Config:LoadSettings()
    Db:setUpdateHook(Config.OnConfigValueChanged)
    local configFile = Config.GetConfigFileName("RGMercs")

    if not Files.file_exists(configFile) then
        local oldConfigFile = Config.GetConfigFileName("RGMerc", true)
        Logger.log_info("\ayOld config file found for RGMercs, upgrading to new config file name.")
        Files.copy_file(oldConfigFile, configFile)
        Files.delete_file(oldConfigFile)
    end

    Globals.CurLoadedChar       = mq.TLO.Me.DisplayName()
    Globals.CurLoadedClass      = mq.TLO.Me.Class.ShortName()
    Globals.CurServer           = mq.TLO.EverQuest.Server()
    Globals.CurServerNormalized = mq.TLO.EverQuest.Server():gsub(" ", "")
    Logger.log_info(
        "\ayLoading Main Settings for %s!",
        Globals.CurLoadedChar)

    local settings = {}
    local firstSaveRequired = false

    local config, err = loadfile(configFile)
    if err or not config then
        Logger.log_error("\ayUnable to load global settings file(%s), creating a new one!",
            configFile)
        firstSaveRequired = true
    else
        settings = config()
    end

    Config:RegisterModuleSettings("Core", settings, Config.DefaultConfig, Config.FAQ, firstSaveRequired)

    -- setup our script path for later usage since getting it kind of sucks, but only on the first run (personas)
    if Globals.ScriptDir == "" then
        local info = debug.getinfo(2, "S")
        local scriptDir = info.short_src:sub(info.short_src:find("lua") + 4):sub(0, -10)
        Globals.ScriptDir = string.format("%s/%s", mq.TLO.Lua.Dir(), scriptDir)
    end

    Config.CacheCustomColors()

    self.SettingsLoadComplete = true

    return true
end

function Config:UpdateCommandHandlers()
    self.CommandHandlers = {}
    local startTime = Globals.GetTimeSeconds()
    local submoduleDefaults = self:GetAllModuleDefaultSettings()

    for moduleName, moduleSettings in pairs(Config.moduleSettings) do
        local modstartTime = Globals.GetTimeSeconds()
        for setting, _ in pairs(moduleSettings or {}) do
            local setstartTime = Globals.GetTimeSeconds()
            local handled, usageString = self:GetUsageText(setting or "", true, submoduleDefaults[moduleName] or {})
            local setendTime = Globals.GetTimeSeconds()
            Logger.log_super_verbose("\ag[Config] \ayGetUsageText() took %.3f seconds for %s.%s", (setendTime - setstartTime) / 1000, moduleName, setting)

            if handled then
                self.CommandHandlers[setting:lower()] = {
                    name = setting,
                    usage = usageString,
                    subModule = moduleName,
                    category = submoduleDefaults[moduleName][setting].Category,
                    about = type(submoduleDefaults[moduleName][setting].Tooltip) == "function" and submoduleDefaults[moduleName][setting].Tooltip() or
                        submoduleDefaults[moduleName][setting].Tooltip,
                }
            end
        end
        local modendTime = Globals.GetTimeSeconds()
        Logger.log_debug("\ag[Config] \ayGeting all Settings took %.3f seconds to process module %s.", (modendTime - modstartTime) / 1000, moduleName)
    end

    local endTime = Globals.GetTimeSeconds()

    Logger.log_debug("\ag[Config] \ayUpdateCommandHandlers() took %.3f seconds to execute for %d modules.", (endTime - startTime) / 1000, #Config.moduleSettings)
end

---@param config string
---@param showUsageText boolean
---@param defaults table
---@return boolean
---@return string
function Config:GetUsageText(config, showUsageText, defaults, valueOnly)
    local handledType = false
    local usageString = showUsageText and string.format("/rgl set %s | ", Strings.PadString(config, 30, false)) or ""
    local configData = defaults[config]

    local rangeText = ""
    local defaultText = ""
    local currentText = ""

    if configData.Type == 'Color' then
        rangeText = string.format("\aw[%s\ax]", Strings.PadString(string.format("\a-y<0.0-1.0>\aw, \a-y<0.0-1.0>\aw, \a-y<0.0-1.0>, \a-y<0.0-1.0>"), 15, false))
        defaultText = string.format("[\a-tDefault: %s\ax]",
            Strings.PadString(string.format("\ar%g\aw, \ag%g\aw, \at%g, \aw%g", configData.Default.x, configData.Default.y, configData.Default.z, configData.Default.w), 8, false))
        currentText = string.format("\ar%g\aw, \ag%g\aw, \at%g, \aw%g", Config:GetSetting(config).x, Config:GetSetting(config).y, Config:GetSetting(config).z,
            Config:GetSetting(config).w)
        handledType = true
    elseif type(configData.Default) == 'number' then
        rangeText = string.format("\aw[%s\ax]", Strings.PadString(string.format("\a-yRange: \a-y%d\aw-\a-y%d", configData.Min or 0, configData.Max or 999), 15, false))
        defaultText = string.format("[\a-tDefault: %s\ax]", Strings.PadString(tostring(configData.Default), 8, false))
        currentText = string.format("%d", Config:GetSetting(config))
        handledType = true
    elseif type(configData.Default) == 'boolean' then
        rangeText = string.format("\aw[%s\ax]", Strings.PadString(string.format("\a-yType : \a-yon\aw|\a-yoff"), 15, false))
        defaultText = string.format("[\a-tDefault: %s\ax]", Strings.PadString(Strings.BoolToString(configData.Default), 8, false))
        currentText = (string.format("%s", Strings.BoolToString(Config:GetSetting(config))))
        handledType = true
    elseif type(configData.Default) == 'string' then
        rangeText = string.format("\aw[%s\ax]", Strings.PadString(string.format("\a-y<\"str\">"), 15, false))
        defaultText = string.format("[\a-tDefault: %s\ax]", Strings.PadString("\"" .. configData.Default .. "\"", 8, false))
        currentText = string.format("%s", Config:GetSetting(config))
        handledType = true
    elseif type(configData.Default) == 'table' then
        rangeText = string.format("\aw[%s\ax]", Strings.PadString(string.format("\a-y<\"table\">"), 15, false))
        defaultText = string.format("[\a-tDefault: %s\ax]", Strings.PadString(Strings.TableToString(configData.Default), 8, false))
        currentText = string.format("%s", Strings.TableToString(Config:GetSetting(config)))
        if #currentText > 120 then
            currentText = currentText:sub(1, 120) .. "..."
        end

        handledType = true
    end

    if valueOnly then
        usageString = usageString ..
            string.format("%s",
                Strings.PadString(currentText, 5, false)
            )
    else
        usageString = usageString ..
            string.format("  %s | %s | %s", Strings.PadString(currentText, 25, false), Strings.PadString(rangeText, 15, false), Strings.PadString(defaultText, 5, false)
            )
    end

    return handledType, usageString
end

function Config:GetModuleSettings(module)
    return self.moduleTempSettings[module] or {}
end

function Config:PeerGetModuleSettings(peer, module)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetModuleSettings(module)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetModuleSettings called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return self.peerModuleSettings[module] or {}
end

function Config:GetModuleDefaultSettings(module)
    return self.moduleDefaultSettings[module] or {}
end

function Config:PeerGetModuleDefaultSettings(peer, module)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetModuleDefaultSettings(module)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetModuleDefaultSettings called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return self.peerModuleDefaultSettings[module] or {}
end

function Config:GetModuleSettingCategories(module)
    return self.moduleSettingCategories[module] or {}
end

function Config:PeerGetModuleSettingCategories(peer, module)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetModuleSettingCategories(module)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetModuleSettingCategories called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return self.peerModuleSettingCategories[module] or {}
end

function Config:GetAllModuleSettings()
    return self.moduleTempSettings or {}
end

function Config:GetAllModuleDefaultSettings()
    return self.moduleDefaultSettings or {}
end

function Config:PeerGetAllModuleDefaultSettings(peer)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetAllModuleDefaultSettings()
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetAllModuleDefaultSettings called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return self.peerModuleDefaultSettings or {}
end

function Config:GetAllModuleSettingCategories()
    return self.moduleSettingCategories or {}
end

function Config:PeerGetAllModuleSettingCategories(peer)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetAllModuleSettingCategories()
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetAllModuleSettingCategories called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return self.peerModuleSettingCategories or {}
end

function Config:GetAllSettingsForCategory(category)
    return Config.TempSettings.SettingsCategoryToSettingMapping[category] or {}
end

function Config:PeerGetAllSettingsForCategory(peer, category)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetAllSettingsForCategory(category)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetAllSettingsForCategory called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return Config.TempSettings.PeerSettingsCategoryToSettingMapping[category] or {}
end

function Config:GetModuleForSetting(setting)
    return Config.TempSettings.SettingToModuleCache[setting] or "None"
end

function Config:PeerGetModuleForSetting(peer, setting)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetModuleForSetting(setting)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetModuleForSetting called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return {}
    end

    return Config.TempSettings.PeerSettingToModuleCache[setting] or "None"
end

function Config:SettingsLoaded()
    return self.SettingsLoadComplete
end

--- Retrieves if a specified setting exists.
--- @param setting string The name of the setting to retrieve.
--- @return boolean true if this setting exists.
function Config:HaveSetting(setting)
    return Config.TempSettings.SettingToModuleCache[setting] ~= nil
end

--- Retrieves a specified setting.
--- @param peer string The name of the peer to retrieve the setting for.
--- @param setting string The name of the setting to retrieve.
--- @param failOk boolean? If true, the function will not raise an error if the setting is not found.
--- @return any The value of the setting, or nil if the setting is not found and failOk is true.
function Config:PeerGetSetting(peer, setting, failOk)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetSetting(setting, failOk)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetSetting called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return nil
    end

    if not Config.TempSettings.PeerSettingToModuleCache[setting] then
        if not failOk then
            Logger.log_error("Setting %s was not found in the module cache for: %s!", setting, peer)
        end
        return nil
    end

    return self:PeerGetModuleSettings(peer, Config.TempSettings.PeerSettingToModuleCache[setting])[setting]
end

--- Retrieves a specified setting.
--- @param setting string The name of the setting to retrieve.
--- @param failOk boolean? If true, the function will not raise an error if the setting is not found.
--- @return any The value of the setting, or nil if the setting is not found and failOk is true.
function Config:GetSetting(setting, failOk)
    if not Config.TempSettings.SettingToModuleCache[setting] then
        if not failOk then
            Logger.log_error("Setting %s was not found in the module cache!", setting)
        end
        return nil
    end
    local value = self:GetModuleSettings(Config.TempSettings.SettingToModuleCache[setting])[setting]
    local dbValue = Db:getValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, Config.TempSettings.SettingToModuleCache[setting], setting)

    if type(dbValue) == "table" and type(value) == "table" then
        if not Tables.AreTablesEqual(dbValue, value) then
            Logger.log_error("\arInconsistency found for %s \aw- \atDB Value\aw: \ag%s\aw, \atIn-Memory Value: \ag%s\aw",
                setting, Strings.TableToString(dbValue), Strings.TableToString(value))
            Config.DbConsistencyCheckPass = false
        end
    elseif dbValue ~= value then
        Logger.log_error("\arInconsistency found for %s \aw- \atDB Value\aw: \ag%s\aw, \atIn-Memory Value: \ag%s\aw",
            setting, tostring(dbValue), tostring(value))
        Config.DbConsistencyCheckPass = false
    end

    return value
end

--- Retrieves a specified setting default info.
--- @param setting string The name of the setting to retrieve.
--- @return any The value of the setting, or nil if the setting is not found and failOk is true.
function Config:GetSettingDefaults(setting)
    if not Config.TempSettings.SettingToModuleCache[setting] then
        Logger.log_error("Setting %s was not found in the module cache!", setting)
        return nil
    end
    return self:GetModuleDefaultSettings(Config.TempSettings.SettingToModuleCache[setting])[setting]
end

--- Retrieves a specified setting default info for a peer.
--- @param peer string The name of the peer to retrieve the setting for.
--- @param setting string The name of the setting to retrieve.
--- @return any The value of the setting, or nil if the setting is not found and failOk is true.
function Config:PeerGetSettingDefaults(peer, setting)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:GetSettingDefaults(setting)
    end

    if self.currentPeer ~= peer then
        Logger.log_error("PeerGetSettingDefaults called for %s but current peer is %s", peer, self.currentPeer or "nil")
        return nil
    end

    if not Config.TempSettings.PeerSettingToModuleCache[setting] then
        Logger.log_error("Setting %s was not found in the module cache!", setting)
        return nil
    end

    return self:PeerGetModuleDefaultSettings(peer, Config.TempSettings.PeerSettingToModuleCache[setting])[setting]
end

--- Validates and sets a configuration setting for a specified module.
--- @param module string: The name of the module for which the setting is being configured.
--- @param setting string: The name of the setting to be validated and set.
--- @param value any: The value to be assigned to the setting.
--- @return boolean|string|number|nil: Returns a valid value for the setting.
function Config:MakeValidSetting(module, setting, value)
    local defaultConfig = self:GetModuleDefaultSettings(module)

    if defaultConfig[setting].Type == "Color" then
        return value
    elseif type(defaultConfig[setting].Default) == 'number' then
        value = tonumber(value)
        if not value or value > (defaultConfig[setting].Max or 999) or value < (defaultConfig[setting].Min or 0) then
            Logger.log_info("\ayError: Invalid or out-of-range value supplied for %s, falling back to previous value.", setting)
            local _, update = Config:GetUsageText(setting, true, defaultConfig)
            Logger.log_info(update)
            return nil
        end

        return value
    elseif type(defaultConfig[setting].Default) == 'boolean' then
        local boolValue = false
        if value == true or value == "true" or value == "on" or (tonumber(value) or 0) >= 1 then
            boolValue = true
        end

        return boolValue
    elseif type(defaultConfig[setting].Default) == 'string' then
        return value
    elseif type(defaultConfig[setting].Default) == 'table' then
        return value
    end

    Logger.log_error("Setting %s could not be validated! (%s)", setting, Strings.TableToString(defaultConfig[setting], 512))
    return nil
end

--- Converts a given setting name into a valid format and module name
--- This function ensures that the setting name adheres to the required format for further processing.
--- @param setting string The original setting name that needs to be validated and formatted.
--- @return string, string The module of the setting and The validated and formatted setting name.
function Config:MakeValidSettingName(setting)
    local validSetting = self.TempSettings.SettingsLowerToNameCache[setting:lower()] or "None"

    return Config.TempSettings.SettingToModuleCache[validSetting] or "None", validSetting
end

---Sets a setting from either in global or a module setting table.
--- @param peer string: The name of the peer to set the setting for.
--- @param setting string: The name of the setting to be updated.
--- @param value any: The new value to assign to the setting.
--- @param tempOnly boolean?: The new value to assign to the setting.
function Config:PeerSetSetting(peer, setting, value, tempOnly)
    if peer == nil or peer == Comms.GetPeerName() then
        return self:SetSetting(setting, value, tempOnly)
    end

    Logger.log_info("\aw[\ar%s\aw] Sending => \ag%s = \a-y%s", peer, setting, tostring(value))
    Comms.SendMessage(peer, self._name, "RemoteSetSetting", { Setting = setting, Value = value, })
end

function Config:RemoteSetSetting(data)
    if data and data.Setting and data.Value ~= nil then
        Logger.log_debug("Received SetSetting for module \awSetSetting :: \at%s \awto \ag%s", data.Setting, tostring(data.Value))
        self:HandleBind(data.Setting, data.Value)
    end
end

---Sets a setting from either in global or a module setting table.
--- @param setting string: The name of the setting to be updated.
--- @param value any: The new value to assign to the setting.
--- @param tempOnly boolean?: The new value to assign to the setting.
function Config:SetSetting(setting, value, tempOnly)
    local settingModuleName = "Core"
    local beforeUpdate = ""

    settingModuleName, setting = self:MakeValidSettingName(setting)

    if settingModuleName == "None" then
        Logger.log_error("Setting %s was not found!", setting)
        return
    end

    local oldValue = Config:GetSetting(setting)
    local defaultConfig = self:GetModuleDefaultSettings(settingModuleName)

    local cleanValue = self:MakeValidSetting(settingModuleName, setting, value)
    _, beforeUpdate = Config:GetUsageText(setting, false, defaultConfig, true)
    if cleanValue ~= nil then
        if tempOnly then
            self.moduleTempSettings[settingModuleName][setting] = cleanValue
        else
            self.moduleSettings[settingModuleName][setting] = Tables.DeepCopy(cleanValue)
            self.moduleTempSettings[settingModuleName][setting] = cleanValue
            self:SaveModuleSettings(settingModuleName, self.moduleSettings[settingModuleName])
            Db:setValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, settingModuleName, setting, cleanValue)
        end
    else
        Logger.log_info("\ayFailed to update setting %s, invalid value supplied.", setting)
    end

    if defaultConfig[setting].RequiresLoadoutChange then
        Modules:ExecModule("Class", "RescanLoadout")
    end

    local _, afterUpdate = Config:GetUsageText(setting, false, defaultConfig)
    Logger.log_debug("(%s) \ag%s\aw is now:\ax %-5s \ay[Previous:\ax %s\ay]", settingModuleName, setting, afterUpdate, beforeUpdate)

    if defaultConfig[setting].OnChange and oldValue ~= cleanValue then
        defaultConfig[setting].OnChange(oldValue, cleanValue)
    end
end

--- Temporarily sets a setting
--- @param setting string: The name of the setting to be updated.
--- @param value any: The new value to assign to the setting.
function Config:SetTempSetting(setting, value)
    self:SetSetting(setting, value, true)
end

--- Clears a Temporarily sets a setting
--- @param setting string: The name of the setting to be updated.
function Config:ClearTempSetting(setting)
    local settingModuleName = "Core"

    settingModuleName, setting = self:MakeValidSettingName(setting)

    if settingModuleName == "None" then
        Logger.log_error("Setting %s was not found!", setting)
        return
    end

    self:SetSetting(setting, self.moduleSettings[settingModuleName][setting], true)
end

--- Clears Temporarily set settings
function Config:ClearAllTempSettings()
    self.moduleTempSettings = Tables.DeepCopy(self.moduleSettings) -- make sure nothing is a reference.
end

--- Resolves the default values for a given settings table.
--- This function takes a table of default values and a table of settings,
--- and ensures that any missing settings are filled in with the default values.
---
--- @param defaults table The table containing default values.
--- @param settings table The table containing user-defined settings.
--- @return table, boolean The settings table with defaults applied where necessary. A bool if the table changed and requires saving.
function Config.ResolveDefaults(defaults, settings)
    -- Setup Defaults
    local changed = false
    if settings == nil then
        settings = {}
        changed = true
        Logger.log_error("\arSettings file was empty or corrupt -- creating a new one with default values.")
    end

    for k, v in pairs(defaults) do
        if settings[k] == nil then settings[k] = v.Default end

        if type(settings[k]) ~= type(v.Default) then
            Logger.log_warn("\ayData type of setting [\am%s\ay] has been deprecated -- resetting to default.", k)
            settings[k] = v.Default
            changed = true
        elseif v.Type == "Combo" and settings[k] > #v.ComboOptions then
            Logger.log_warn("\aySetting value out of bounds [\am%s\ay] -- resetting to default.", k)
            settings[k] = v.Default
            changed = true
        elseif type(settings[k]) == "number" and (settings[k] < (v.Min or -1) or settings[k] > (v.Max or 99999)) then
            Logger.log_warn("\aySetting value out of bounds [\am%s\ay] -- resetting to default.", k)
            settings[k] = v.Default
            changed = true
        end
    end

    -- Remove Deprecated options
    for k, _ in pairs(settings) do
        if not defaults[k] then
            settings[k] = nil
            Logger.log_info("\aySetting [\am%s\ay] has been deprecated -- removing from your config.", k)
            changed = true
        end
    end

    return settings, changed
end

function Config:UnRegisterCategoryToSettingMapping(setting)
    local category = Config:GetSettingDefaults(setting).Category
    if self.TempSettings.SettingsCategoryToSettingMapping[category] then
        for i, v in ipairs(self.TempSettings.SettingsCategoryToSettingMapping[category]) do
            if v == setting then
                table.remove(self.TempSettings.SettingsCategoryToSettingMapping[category], i)
                break
            end
        end
    end
end

function Config:RegisterCategoryToSettingMapping(setting)
    local category = Config:GetSettingDefaults(setting).Category
    self.TempSettings.SettingsCategoryToSettingMapping[category] = self.TempSettings.SettingsCategoryToSettingMapping[category] or {}
    table.insert(self.TempSettings.SettingsCategoryToSettingMapping[category], setting)
end

function Config:PeerRegisterCategoryToSettingMapping(peer, setting)
    local category = Config:PeerGetSettingDefaults(peer, setting).Category
    self.TempSettings.PeerSettingsCategoryToSettingMapping[category] = self.TempSettings.PeerSettingsCategoryToSettingMapping[category] or {}
    table.insert(self.TempSettings.PeerSettingsCategoryToSettingMapping[category], setting)
end

function Config:RegisterModuleSettings(module, settings, defaultSettings, faq, firstSaveRequired)
    if self.moduleSettings[module] then
        Logger.log_error("\arModule %s has already registered settings!", module)
        return
    end

    local settingsChanged = false

    --Centralize category creation and setup the FAQs
    local settingCategories = Set.new({})
    for k, v in pairs(defaultSettings or {}) do
        if v.Type ~= "Custom" then
            settingCategories:add(v.Category)
        end
        faq[k] = { Question = v.FAQ, Answer = v.Answer, Settings_Used = k, }
    end

    -- Setup Defaults
    settings, settingsChanged = Config.ResolveDefaults(defaultSettings, settings)
    self.moduleSettings[module] = Tables.DeepCopy(settings) -- make sure nothing is a reference.
    self.moduleTempSettings[module] = settings
    self.moduleDefaultSettings[module] = defaultSettings
    self.moduleSettingCategories[module] = settingCategories

    for setting, _ in pairs(settings) do
        if not self.moduleDefaultSettings[module][setting].Category or self.moduleDefaultSettings[module][setting].Category:len() == 0 then
            self.moduleDefaultSettings[module][setting].Category = "Uncategorized"
            self.moduleSettingCategories[module]:add("Uncategorized")
        end

        if Config.TempSettings.SettingToModuleCache[setting] ~= nil then
            Logger.log_error(
                "\ay[Setting] \arError: Key %s exists in multiple settings tables: \aw%s \arand \aw%s! Keeping first but this should be fixed!",
                setting,
                Config.TempSettings.SettingToModuleCache[setting], module)
            self:RegisterCategoryToSettingMapping(setting)
        else
            Config.TempSettings.SettingToModuleCache[setting] = module
            Config.TempSettings.SettingsLowerToNameCache[setting:lower()] = setting
            self:RegisterCategoryToSettingMapping(setting)
        end
    end

    if firstSaveRequired or settingsChanged then
        self:SaveModuleSettings(module, settings)
    end

    self.TempSettings.lastModuleRegisteredTime = Globals.GetTimeSeconds()

    Logger.log_debug("\agModule %s - registered settings!", module)
end

function Config:ClearModuleSettings(module)
    if not self.moduleSettings[module] then
        Logger.log_error("\arModule %s is not registered!", module)
        return
    end

    local settings = self.moduleSettings[module]
    for setting, _ in pairs(settings) do
        self:UnRegisterCategoryToSettingMapping(setting)
        Config.TempSettings.SettingsLowerToNameCache[setting:lower()] = nil
        Config.TempSettings.SettingToModuleCache[setting] = nil
    end

    self.moduleSettings[module] = nil
    self.moduleTempSettings[module] = nil
    self.moduleDefaultSettings[module] = nil
    self.moduleSettingCategories[module] = nil

    Logger.log_debug("\agModule %s - removed all settings!", module)
end

function Config:RequestPeerConfigs(peer)
    Comms.SendMessage(peer, self._name, "SendConfigs", { from = Comms.GetPeerName(), })
end

function Config:PackageConfig(module)
    return {
        peer = Comms.GetPeerName(),
        module = module,
        settings = Config:GetAllModuleSettings()[module],
        settingCategories = Config:GetAllModuleSettingCategories()[module],
        defaultSettings = Config:GetAllModuleDefaultSettings()[module],
    }
end

function Config:SendConfigs(data)
    Logger.log_debug("Received SendConfigs from %s - sending our configs.", data.from)
    local modules = { "Core", }

    for _, name in ipairs(Modules:GetModuleOrderedNames()) do
        table.insert(modules, name)
    end

    for _, name in ipairs(modules) do
        if Config.moduleSettings[name] ~= nil then
            Comms.SendMessage(data.from, self._name, "UpdatePeerSettings", self:PackageConfig(name))
        end
    end
end

function Config:BroadcastConfigs()
    local modules = { "Core", }

    for _, name in ipairs(Modules:GetModuleOrderedNames()) do
        table.insert(modules, name)
    end

    for _, name in ipairs(modules) do
        if Config.moduleSettings[name] ~= nil then
            Comms.BroadcastMessage(self._name, "UpdatePeerSettings", self:PackageConfig(name))
        end
    end
end

function Config:GetCurrentPeer()
    return self.currentPeer
end

function Config:GetLastModuleRegisteredTime()
    return self.TempSettings.lastModuleRegisteredTime
end

function Config:ClearAllModuleSettings()
    self.moduleSettings = {}
    self.moduleTempSettings = {}
    self.moduleDefaultSettings = {}
    self.moduleSettingCategories = {}
    self.TempSettings.SettingToModuleCache = {}
    self.TempSettings.SettingsLowerToNameCache = {}
    self.TempSettings.SettingsCategoryToSettingMapping = {}
    self.SettingsLoadComplete = false
end

function Config:SaveModuleSettings(module, settings)
    self.moduleSettings[module] = settings
    local defaultSettings = self:GetModuleDefaultSettings(module)
    local settingsCategories = self:GetModuleSettingCategories(module):toList() or {}

    if module == "Core" then
        self:SaveSettings()
    else
        Modules:ExecModule(module, "SaveSettings", false)
    end
    Logger.log_debug("\agModule %s - save settings requested!", module)

    -- broadcast the change to any listeners.
    Comms.BroadcastMessage(self._name, "UpdatePeerSettings",
        { peer = Comms.GetPeerName(), module = module, settings = settings, settingCategories = settingsCategories, defaultSettings = defaultSettings, })
end

function Config:ValidatePeers()
    Comms.ValidatePeers(Config:GetSetting("ActorPeerTimeout"))

    if not Comms.IsValidPeer(self.currentPeer) then
        self.peerModuleSettings                                = {}
        self.peerModuleDefaultSettings                         = {}
        self.peerModuleSettingCategories                       = {}
        self.TempSettings.PeerModuleSettingsLowerToNameCache   = {}
        self.TempSettings.PeerSettingToModuleCache             = {}
        self.TempSettings.PeerSettingsCategoryToSettingMapping = {}
        self.currentPeer                                       = nil
    end
end

function Config:SetRemotePeer(peer)
    if self.currentPeer ~= peer then
        self.peerModuleSettings                                = {}
        self.peerModuleDefaultSettings                         = {}
        self.peerModuleSettingCategories                       = {}
        self.TempSettings.PeerModuleSettingsLowerToNameCache   = {}
        self.TempSettings.PeerSettingToModuleCache             = {}
        self.TempSettings.PeerSettingsCategoryToSettingMapping = {}
        self.currentPeer                                       = peer
        self.TempSettings.LastPeerConfigReceivedTime           = 0

        self:RequestPeerConfigs(peer)
    end
end

function Config:UpdatePeerSettings(data)
    local peer   = data.peer
    local module = data.module

    if self.currentPeer ~= peer then
        return
    end

    local settings, settingsCategories, defaultSettings = data.settings or {}, data.settingsCategories or {}, data.defaultSettings or {}

    self.peerModuleDefaultSettings[module] = defaultSettings

    -- remove old settings from caches
    for setting, _ in pairs(self.peerModuleSettings[module] or {}) do
        if self.TempSettings.PeerSettingsCategoryToSettingMapping and Config:PeerGetSettingDefaults(peer, setting) then
            local categoryListLen = #self.TempSettings.PeerSettingsCategoryToSettingMapping[Config:PeerGetSettingDefaults(peer, setting).Category] or 0
            for i = categoryListLen, 1, -1 do
                if self.TempSettings.PeerSettingsCategoryToSettingMapping[Config:PeerGetSettingDefaults(peer, setting).Category][i] == setting then
                    table.remove(self.TempSettings.PeerSettingsCategoryToSettingMapping[Config:PeerGetSettingDefaults(peer, setting).Category], i)
                    break
                end
            end
        end
        self.TempSettings.PeerSettingToModuleCache[setting] = nil
        self.TempSettings.PeerModuleSettingsLowerToNameCache[setting:lower()] = nil
    end

    self.peerModuleSettings[module] = Tables.DeepCopy(settings or {})
    self.peerModuleSettingCategories[module] = Set.new(settingsCategories or {})

    for setting, _ in pairs(settings) do
        self.TempSettings.PeerSettingToModuleCache[setting] = module
        self.TempSettings.PeerModuleSettingsLowerToNameCache[setting:lower()] = setting
        self:PeerRegisterCategoryToSettingMapping(peer, setting)
    end

    self.TempSettings.LastPeerConfigReceivedTime = Globals.GetTimeSeconds()
end

function Config:GetPeerLastConfigReceivedTime(peer)
    if peer ~= self.currentPeer then
        return 0
    end

    return self.TempSettings.LastPeerConfigReceivedTime or 0
end

--- Adds the given name to the Assist List.
--- @param name string: The name of the PC to be added.
--- @param listName string: The list of PCs to add to.
function Config:ListAdd(name, listName)
    local addList = Config:GetSetting(listName)

    for _, cur_name in ipairs(addList or {}) do
        if cur_name == name then
            return
        end
    end

    table.insert(addList, name)
    self:SetSetting(listName, addList)
    Logger.log_info("\ax%s: \ag%s\ax has been\ag added\ax to the list at position \at%d\ax!", listName, name,
        #self:GetSetting(listName))
end

function Config:ListDelete(arg1, listName)
    if not arg1 then
        Logger.log_error("\ar%s Delete: this command requires a valid argument!", listName or "")
        return
    end

    local list = self:GetSetting(listName)

    if type(arg1) == 'string' then
        arg1 = self:ConvertListNameToID(arg1, listName)
    end

    if type(arg1) == 'number' and arg1 > 0 then
        if arg1 <= #list then
            Logger.log_info("\ax%s: \ag%s\ax has been \ardeleted\ax from the list!", listName, list[arg1])
            table.remove(list, arg1)
            self:SetSetting(listName, list)
        else
            Logger.log_error("\ar%s Delete: %d is not a valid assist list ID!", listName, arg1)
        end
        return
    end
    Logger.log_error("\ar%s Delete: %s was not on the list or is not a valid argument!", listName, arg1)
end

function Config:ListClear(listName)
    Logger.log_info("%s: \ayThe list has been cleared!", listName)
    Config:SetSetting(listName, {})
end

--- Moves the PC at the given index up.
--- @param id number The index of the PC to move.
--- @param listName string: The list to adjust.
function Config:ListMoveUp(id, listName)
    if type(id) == 'string' then
        id = self:ConvertListNameToID(id, listName)
    end

    local newId = id - 1

    if newId < 1 then return end
    local list = self:GetSetting(listName)

    if id > #list then return end

    list[newId], list[id] = list[id], list[newId]
    Logger.log_info("\ax%s: \ag%s\ax has been\ag moved up\ax to position \at%d", listName, self:GetSetting(listName)[newId], newId)
    self:SetSetting(listName, list)
end

--- Moves the PC at the given index down.
--- @param id number The index of the PC to move.
--- @param listName string: The list to adjust.
function Config:AssistMoveDown(id, listName)
    if not id then
        Logger.log_error("\ar%s Move Down: this command requires a valid argument!", listName)
        return
    end

    if type(id) == 'string' then
        id = self:ConvertListNameToID(id, listName)
    end

    if id < 1 then return end
    local newId = id + 1
    local list = self:GetSetting(listName)

    if newId > #list then return end

    list[newId], list[id] = list[id], list[newId]

    Logger.log_info("\ax%s: \ag%s\ax has been\ar moved down\ax to position \at%d", listName, self:GetSetting(listName)[newId], newId)

    self:SetSetting(listName, list)
end

function Config:ConvertListNameToID(arg1, listName)
    if arg1:match("^%d$") then
        arg1 = tonumber(arg1)
        return arg1
    else
        for idx, cur_name in ipairs(Config:GetSetting(listName) or {}) do
            if cur_name:lower() == arg1:lower() then
                arg1 = tonumber(idx)
                return arg1
            end
        end
    end
    return 0
end

function Config:GetCommandHandlers()
    return { module = "Config", CommandHandlers = self.CommandHandlers or {}, }
end

function Config:GetFAQ()
    return self.FAQ or {}
end

function Config:GetLastHighlightChangeTime()
    return self.lastHighlightTime or 0
end

function Config:IsModuleHighlighted(module)
    self.TempSettings.HighlightedModules = self.TempSettings.HighlightedModules or Set.new({})
    return self.TempSettings.HighlightedModules:contains(module)
end

function Config:ClearAllHighlightedModules()
    self.TempSettings.HighlightedModules = Set.new({})
    self.lastHighlightTime = Globals.GetTimeSeconds()
end

function Config:OpenOptionsUIAndHighlightModule(module)
    self:SetSetting("EnableOptionsUI", true)
    self:HighlightModule(module)
end

function Config:HighlightModule(module)
    -- only allow for 1 at a time for now but later we might enhance this.
    self.TempSettings.HighlightedModules = Set.new({})
    self.TempSettings.HighlightedModules:add(module)
    self.lastHighlightTime = Globals.GetTimeSeconds()
end

function Config:UnhighlightModule(module)
    self.TempSettings.HighlightedModules = self.TempSettings.HighlightedModules or Set.new({})
    self.TempSettings.HighlightedModules:remove(module)
    self.lastHighlightTime = Globals.GetTimeSeconds()
end

---@param config string
---@param value any
---@return boolean
function Config:HandleBind(config, value)
    local handled = false

    if not config or config:lower() == "show" or config:len() == 0 then
        self:UpdateCommandHandlers()

        local allModules = {}
        local submoduleSettings = self.moduleSettings or {}

        for name, _ in pairs(submoduleSettings) do
            if name ~= "Core" then
                table.insert(allModules, name)
            end
        end
        table.sort(allModules)
        table.insert(allModules, 1, "Core")

        local sortedKeys = {}
        for c, _ in pairs(self.CommandHandlers or {}) do
            table.insert(sortedKeys, c)
        end
        table.sort(sortedKeys)

        local sortedCategories = {}
        for c, d in pairs(self.CommandHandlers or {}) do
            sortedCategories[d.subModule] = sortedCategories[d.subModule] or {}
            if not Tables.TableContains(sortedCategories[d.subModule], d.category) then
                table.insert(sortedCategories[d.subModule], d.category)
            end
        end
        for _, subModuleTable in pairs(sortedCategories) do
            table.sort(subModuleTable)
        end

        for _, subModuleName in ipairs(allModules) do
            local printHeader = true
            for _, c in ipairs(sortedCategories[subModuleName] or {}) do
                local printCategory = true
                for _, k in ipairs(sortedKeys) do
                    local d = self.CommandHandlers[k]
                    if d.subModule == subModuleName and d.category == c then
                        if printHeader then
                            printf("\n\ag%s\aw Settings\n------------", subModuleName)
                            printHeader = false
                        end
                        if printCategory then
                            printf("\n\aoCategory: %s\aw", c)
                            printCategory = false
                        end
                        if (value or ""):len() > 0 and
                            d.name:lower():find(value:lower()) == nil and
                            (d.usage or ""):lower():find(value:lower()) == nil and
                            (d.about or ""):lower():find(value:lower()) == nil then
                            -- skip
                        else
                            printf("\am%-20s\aw - \atUsage: \ay%s\aw | %s", d.name,
                                Strings.PadString(d.usage, 100, false), d.about)
                        end
                    end
                end
            end
        end
        return true
    end

    if self.CommandHandlers[config:lower()] ~= nil then
        Config:SetSetting(config, value)
        handled = true
    else
        Logger.log_error("\at%s\aw - \arNot a valid config setting!\ax", config)
    end

    return handled
end

---@param config string
---@param value any
---@return boolean
function Config:HandleTempSet(config, value)
    local handled = false

    if not config or config:lower() == "show" or config:len() == 0 then
        self:HandleBind("show", value)
        return true
    end

    if self.CommandHandlers[config:lower()] ~= nil then
        Config:SetTempSetting(config, value)
        handled = true
    else
        Logger.log_error("\at%s\aw - \arNot a valid config setting!\ax", config)
    end

    return handled
end

---@return number
function Config:GetMainOpacity()
    return tonumber((self:GetSetting('BgOpacity') or 100) / 100) or 1.0
end

--- Determines if the character should mount.
--- @return boolean True if the character should mount, false otherwise.
function Config.ShouldMount()
    if Config:GetSetting('DoMount') == 1 then return false end

    local passBasicChecks = Config:GetSetting('MountItem'):len() > 0 and mq.TLO.Me.CanMount()

    local passCheckMountOne = (not Config:GetSetting('DoMelee') and (Config:GetSetting('DoMount') == 2 and (mq.TLO.Me.Mount.ID() or 0) == 0))
    local passCheckMountTwo = ((Config:GetSetting('DoMount') == 3 and (mq.TLO.Me.Buff("Mount Blessing").ID() or 0) == 0))
    local passMountItemGivesBlessing = false

    if passCheckMountTwo then
        local mountItem = mq.TLO.FindItem(Config:GetSetting('MountItem'))
        if mountItem and mountItem() then
            passMountItemGivesBlessing = mountItem.Blessing() ~= nil
        end
    end

    return passBasicChecks and (passCheckMountOne or (passCheckMountTwo and passMountItemGivesBlessing))
end

--- Determines whether the character should dismount.
--- This function checks certain conditions to decide if the character should dismount.
--- @return boolean True if the character should dismount, false otherwise.
function Config.ShouldDismount()
    -- if mount item is empty and we are on a mount then the user probably wants mount on.
    return (Config:GetSetting('MountItem') or ""):len() > 0 and Config:GetSetting('DoMount') ~= 2 and ((mq.TLO.Me.Mount.ID() or 0) > 0)
end

--- Determines if the priority follow condition is met.
--- @return boolean True if the priority follow condition is met, false otherwise.
function Config.ShouldPriorityFollow()
    local chaseTarget = Config:GetSetting('ChaseTarget', true) or "NoOne"

    if chaseTarget == mq.TLO.Me.CleanName() then return false end

    if Config:GetSetting('PriorityFollow') and Config:GetSetting('ChaseOn') then
        local chaseSpawn = mq.TLO.Spawn("pc =" .. chaseTarget)

        if (mq.TLO.Me.Moving() or (chaseSpawn() and (chaseSpawn.Distance() or 0) > Config:GetSetting('ChaseDistance'))) then
            return true
        end
    end

    return false
end

function Config.CacheCustomColors()
    for k, v in pairs(Globals.Constants.DefaultColors) do
        Globals.Constants.Colors[k] = Tables.TableToImVec4(Config:GetSetting(k)) or v
    end

    -- Add here for completeness even though it is a duplicate of BasicColors
    for c, v in pairs(Globals.Constants.BasicColors) do
        Globals.Constants.Colors[c] = v
    end

    for i, v in ipairs(Globals.Constants.ConColors) do
        Globals.Constants.ConColorsNameToVec4[v:upper()] = Globals.Constants.Colors[Globals.Constants.ConColors[i]:gsub(" ", "")] or Globals.Constants.Colors.White
    end
end

function Config.OnConfigValueChanged(operation, dbName, tableName, rowId)
    Logger.log_verbose(
        "\ayOnConfigValueChanged(): \amConfig detected a change in the database. \ayOperation\aw: \ag%s\aw, \ayDB\aw: \ag%s\aw, \ayTable\aw: \ag%s\aw, \ayRowId\aw: \ag%s\aw",
        Db.opName(operation), tostring(dbName) or "?", tostring(tableName) or "?", tostring(rowId) or "?")
end

function Config:ConvertToDb()
    -- iterate all settings and resave them with their current value.
    local settingCount = 0
    local moduleCount = 0
    for module, settings in pairs(self.moduleSettings) do
        moduleCount = moduleCount + 1
        for setting, value in pairs(settings) do
            Db:setValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, module, setting, value)
            settingCount = settingCount + 1
        end
    end
    Logger.log_info("\agConverted \ay%d \agsettings across \ay%d \agmodules to the new database format.", settingCount, moduleCount)
end

function Config:DbConsistencyCheck()
    local settingCount = 0
    local moduleCount = 0
    Config.DbConsistencyCheckPass = true

    for module, settings in pairs(self.moduleSettings) do
        moduleCount = moduleCount + 1
        for setting, value in pairs(settings) do
            local dbValue = Db:getValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, module, setting)
            if type(dbValue) == "table" and type(value) == "table" then
                if not Tables.AreTablesEqual(dbValue, value) then
                    Logger.log_error("\arInconsistency found for %s \aw- \atDB Value\aw: \ag%s\aw, \atIn-Memory Value: \ag%s\aw",
                        setting, Strings.TableToString(dbValue), Strings.TableToString(value))
                    Config.DbConsistencyCheckPass = false
                end
            elseif dbValue ~= value then
                Logger.log_error("\arInconsistency found for %s \aw- \atDB Value\aw: \ag%s\aw, \atIn-Memory Value: \ag%s\aw",
                    setting, tostring(dbValue), tostring(value))
                Config.DbConsistencyCheckPass = false
            end
            settingCount = settingCount + 1
        end
    end
    Logger.log_info("\agDatabase consistency check complete. Found \ay%d \agsettings in the database for this character.", settingCount)

    return Config.DbConsistencyCheckPass
end

function Config:DbWritesPending()
    return Db:pendingWrites() > 0
end

function Config:FlushDB()
    Db:flushQueue()
end

function Config.Shutdown()
    Db:close()
end

return Config
