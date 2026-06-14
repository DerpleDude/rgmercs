-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

-- [ NOTE ON ORDERING ] --
-- Order matters! Lua will implicitly iterate everything in an array
-- in order by default so always put the first thing you want checked
-- towards the top of the list.

local mq        = require('mq')
local Casting   = require("utils.casting")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Modules   = require("utils.modules")
local Movement  = require("utils.movement")
local Strings   = require("utils.strings")
local Targeting = require("utils.targeting")

local Tooltips  = {
    ArrowOpener         = "Spell Line: Archery Attack with High Crit Chance when not in Combat. Consumes a 50 range CLASS 3 Wood Silver Tip Arrow when cast.",
    PullOpener          = "Spell Line: Archery Attack when not in Combat. Consumes a 50 range CLASS 3 Wood Silver Tip Arrow when cast.",
    CalledShotsArrow    = "Spell Line: Quad Archery Attack + Increase Archery Dmg Against Target",
    FocusedArrows       = "Spell Line: Quad Archery Attack",
    DichoSpell          = "Spell Line: Cast best Summer's Cyclone + Double Massive Archery Attack + Lower Hatred",
    SummerNuke          = "Spell Line: Fire Nuke + Cold Nuke + Increase Hatred",
    SwarmDot            = "Spell Line: Magic DoT",
    ShortSwarmDot       = "Spell Line: Prismatic DoT + ToT Damage Shield",
    UnityBuff           = "AA: Casts Highest Level of Scribed Buffs (ParryProcBuff, Hunt, Protectionbuff, Eyes)",
    Protectionbuff      = "Spell Line: Increase AC + Self Damage Shield",
    ShoutBuff           = "Spell Line: Increase Attack and Double Attack Chance",
    AggroBuff           = "Spell Line: Harms Target HP and Hatred Increase",
    AggroReducerBuff    = "Spell Line: Hatred Decrease Proc",
    AggroKick           = "Spell Line: Two Kicks w/ Increased Accuracy that Increase Hatred",
    ParryProcBuff       = "Spell Line: Magic Nuke w/ Parry Chance Proc",
    Eyes                = "Spell Line: Increase Chance to Hit with Archery",
    GroupStrengthBuff   = "Spell Line: Increase Group's Attack",
    GroupPredatorBuff   = "Spell Line: Increase Group's Attack",
    GroupEnrichmentBuff = "Spell Line: Increase Group's Base Damage",
    Rathe               = "Spell Line: Increase AC + Damage Shield",
    BowDisc             = "Discipline: Increase Archery Skill Check and Damage Modifier",
    MeleeDisc           = "Discipline: Add Melee Damage DoT Proc",
    DefenseDisc         = "Discpline: Parry Chance 100%",
    Fireboon            = "Spell Line: Fire Nuke + Additional Damage w/ Fire Spells",
    Firenuke            = "Spell Line: Fire Nuke",
    Iceboon             = "Spell Line: Cold Nuke + Additional Damage w/ Cold Spells",
    Icenuke             = "Spell Line: Cold Nuke",
    Heartshot           = "Spell Line: Archery Attack. Consumes a 50 range CLASS 3 Wood Silver Tip Arrow when cast.",
    EndRegenDisc        = "Discipline: Endurance Regen + Self Slow",
    Coat                = "Spell Line: Increase AC + Self Damage Shield",
    Mask                = "Spell Line: Increase Magnification + Mana Regen + See Invis",
    Hunt                = "Spell Line: Add Crit Chance and Accuracy Buff Proc on Killshot",
    Heal                = "Spell Line: Heal",
    Fastheal            = "Spell Line: Fast Cast Heal",
    Totheal             = "Spell Line: Heals Target of Target if Used on an Enemy",
    RegenSpells         = "Spell Line: Increase Regeneration",
    SnareSpells         = "Spell Line: Decrease Enemy Movement Speed",
    FireFist            = "Spell Line: Self Increase Attack",
    DsBuff              = "Spell Line: Damage Shield",
    SkinLike            = "Spell Line: Increase AC + Increase Max HP",
    MoveSpells          = "Spell Line: Increase Movement Speed",
    Alliance            = "Spell Line: Alliance (Requires Multiple of Same Class). Adds Fire Damage to other Ranger Spells and triggers a massive Fire and Cold Nuke",
    Cloak               = "Spell Line: Melee Absorb Proc + ATK/AC/Fire Resist Debuff",
    Veil                = "Spell Line: Add Parry Proc",
    JoltingKicks        = "Spell Line: Two Kicks w/ Increased Accuracy that Decrease Hatred",
    AEBlades            = "Spell Line: Quad Attack against up to 8 targets in Front of You",
    FocusedBlades       = "Spell Line: Quad Attack w/ Increased Accuracy",
    ReflexSlashHeal     = "Spell Line: Quad Attack w/ Increase Accuracy + Group HoT",
    AEArrows            = "Spell Line: Quad Archery Attack w/ Increased Accuracy against up to 8 targets in Front of You",
    Entrap              = "AA: Snare",
    Kick                = "Use Kick Ability",
    Taunt               = "Use Taunt Ability",
    Epic                = 'Item: Casts Epic Weapon Ability',
    GotF                = "AA: Wolf Form + v3 Haste + Regen + Attack + Increase Skill Damage",
    GGotF               = "AA: Group Wolf Form + v3 Haste + Regen + Attack + Increase Skill Damage",
    OA                  = "AA: Increase Melee Damage + Accuracy + Attack + Crit Chance + Minimum Damage + Minimum Base Damage",
    EA                  = "AA: Increase Fire and Cold Spell Damage against Target",
    AotH                = "AA: Increase Skill, Spell, and Heal Crit Chance + Accuracy + Attack",
    OE                  = "AA: Decrease Melee Damage + Increase Chance to Avoid Melee + Increase Movement Speed",
    PackHunt            = "AA: Summons a pack of wolves",
    PoisonArrow         = "AA: Adds Archery proc that consumes mana to deal high damage",
    FlamingArrow        = "AA: Adds Archery proc that consumes mana to deal high damage",
    PotSW               = "AA: Mitigate Melee and Spell Damage + Increase Magic Resistance",
    CG                  = "AA: Decrease Hatred and Hatred Generation when HP drops below 50%",
    SS                  = "AA: Reduce Hatred Generation",
    IF                  = "AA: Melee Proc Chance 100% + Decrease Hatred Generation",
    BotB                = "AA: Decrease Hatred + Decrease Hatred Proc when hit in Melee + 100% Parry Chance when below 50% HP",
    EB                  = "AA: Increase 1H Attack Damage + Increase 2H Minimum Attack Damage",
    SCF                 = "AA: Group Buff that drains Mana or Endurance and Twin Casts Spells or Abilities Depending on Class",
    SotP                = "AA: Increase Max HP and Dex Cap + Decreased Hatred Generation + Increased Melee Proc Chance + Increased Melee Minimum Damage",
    EoN                 = "AA: High Chance to Dispel Your Target",
    RangedMode          = "Skill: Use /autofire instead of using Melee",
}

-- helper function for advanced logic to see if we want to use Windstalker's Unity
local function castWSU()
    local unityAction = Modules:ExecModule("Class", "GetResolvedActionMapItem", "Protectionbuff")
    if not unityAction then return false end

    local res = unityAction.Level() <=
        (mq.TLO.Me.AltAbility("Wildstalker's Unity (Azia)").Spell.Level() or 0) and
        mq.TLO.Me.AltAbility("Wildstalker's Unity (Azia)").MinLevel() <= mq.TLO.Me.Level() and
        mq.TLO.Me.AltAbility("Wildstalker's Unity (Azia)").Rank() > 0

    return res
end

local _ClassConfig = {
    _version              = "1.0 - Live",
    _author               = "MrInfernal",
    ['CommandHandlers']   = {
        makeammo = {
            usage = "/rgl makeammo ##",
            about = "Make ## number of Class 3 Wood Silver Tip Arrows. Minimum of 5",
            handler =
                function(self, amount)
                    local packSlots = {
                        { slot = 23, name = 'pack1', }, { slot = 24, name = 'pack2', }, { slot = 25, name = 'pack3', }, { slot = 26, name = 'pack4', },
                        { slot = 27, name = 'pack5', }, { slot = 28, name = 'pack6', }, { slot = 29, name = 'pack7', }, { slot = 30, name = 'pack8', },
                    }
                    local delay = 5
                    local matTable = { 'Several Shield Cut Fletchings', 'Small Groove Nocks', 'Bundled Wooden Arrow Shafts', 'Silver Tipped Arrowheads', }
                    local kitSlot = ''

                    -- How many bundles to make. Dividing as each combine makes 5 arrows
                    if amount == nil then
                        amount = 5
                    end
                    local toMake = tonumber(amount) / 5

                    --Check for and open fletching kit in inventory
                    local kitsToFind = { 'Fletching Kit', 'Planar Fletching Kit', 'Collapsible Fletching Kit', 'Surefall Fletching Kit', }
                    local fletchKit = ''

                    -- Iterates through top level inventory
                    -- If a bag matches a medicine bag, it's set to medBag
                    -- Also stores the inventory slot in bagSlot
                    for packIndex = 23, 32 do
                        local packNum = mq.TLO.Me.Inventory(packIndex).Name()

                        -- Check if packNum's name is in the list of bags to find
                        if table.concat(kitsToFind, ","):find(packNum) then
                            for _, packInfo in ipairs(packSlots) do
                                if packInfo.slot == packIndex then
                                    fletchKit = packNum
                                    kitSlot = packInfo.name
                                    break
                                end
                            end
                        end
                    end

                    -- Ensure a kit was found then open it and enter Experimentation mode
                    -- To Do: Find a way to see if container is open
                    if fletchKit ~= '' then
                        Core.DoCmd('/timed %d /itemnotify "%s" rightmouseup', delay, fletchKit)
                        delay = delay + 5
                        Core.DoCmd('/timed %d /notify TradeskillWnd COMBW_ExperimentButton leftmouseup', delay)
                        delay = delay + 5
                    end

                    -- j is how many bundles to make (toMake)
                    -- Iterates through matTable to place one of each item in the fletching kit
                    -- When all are added, hits Combine and autoinventories the item
                    for j = 1, toMake do
                        for i = 1, toMake do
                            local matName = matTable[i]

                            Core.DoCmd('/timed %d /nomodkey /ctrl /itemnotify "%s" leftmouseup', delay, matName)
                            delay = delay + 5
                            Core.DoCmd('/timed %d /itemnotify in %s %d leftmouseup', delay, kitSlot, i)
                            delay = delay + 5
                            if i == #matTable then
                                Core.DoCmd('/timed %d /combine %s', delay, kitSlot)
                                delay = delay + 7
                                Core.DoCmd('/timed %d /autoinventory', delay)
                                delay = delay + 5
                                Core.DoCmd('/timed %d /echo Combine #%d', delay, j)
                                delay = delay + 13
                            end
                        end
                    end

                    return true
                end,
        },
    },
    ['ModeChecks']        = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
        IsHealing = function() return Core.IsModeActive("Healer") or Core.IsModeActive("Hybrid") end,
    },
    ['Modes']             = {
        'DPS',
        'Tank',
        'Healer',
        'Hybrid',
    },
    ['Themes']            = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.05, g = 0.13, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.05, g = 0.13, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.12, g = 0.32, b = 0.08, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.08, g = 0.21, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.12, g = 0.32, b = 0.08, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.05, g = 0.13, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.70, g = 0.48, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.70, g = 0.48, b = 0.12, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
        },
        ['Tank'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.18, g = 0.28, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.18, g = 0.28, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.07, g = 0.11, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.18, g = 0.28, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.18, g = 0.28, b = 0.12, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.07, g = 0.11, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.18, g = 0.28, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.18, g = 0.28, b = 0.12, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.18, g = 0.28, b = 0.12, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.12, g = 0.18, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.18, g = 0.28, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.18, g = 0.28, b = 0.12, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.18, g = 0.28, b = 0.12, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.07, g = 0.11, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.55, g = 0.65, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.55, g = 0.65, b = 0.35, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.18, g = 0.28, b = 0.12, a = 1.0, }, },
        },
        ['Healer'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.10, g = 0.38, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.10, g = 0.38, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.04, g = 0.15, b = 0.06, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.10, g = 0.38, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.10, g = 0.38, b = 0.15, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.04, g = 0.15, b = 0.06, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.10, g = 0.38, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.10, g = 0.38, b = 0.15, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.10, g = 0.38, b = 0.15, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.07, g = 0.25, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.10, g = 0.38, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.10, g = 0.38, b = 0.15, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.10, g = 0.38, b = 0.15, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.04, g = 0.15, b = 0.06, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.35, g = 0.85, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.35, g = 0.85, b = 0.35, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.10, g = 0.38, b = 0.15, a = 1.0, }, },
        },
        ['Hybrid'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.15, g = 0.30, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.15, g = 0.30, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.06, g = 0.12, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.15, g = 0.30, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.15, g = 0.30, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.06, g = 0.12, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.15, g = 0.30, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.15, g = 0.30, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.15, g = 0.30, b = 0.10, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.10, g = 0.20, b = 0.07, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.15, g = 0.30, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.15, g = 0.30, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.15, g = 0.30, b = 0.10, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.06, g = 0.12, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.60, g = 0.75, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.60, g = 0.75, b = 0.20, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.15, g = 0.30, b = 0.10, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Heartwood Blade",
            "Aurora, the Heartwood Blade",
        },
    },
    ['AbilitySets']       = {
        ['ArrowOpener'] = {
            "Concealed Shot", -- Level 125
            "Stealthy Shot",  -- Level 111
            "Silent Shot",    -- Level 103
        },
        ['PullOpener'] = {
            "Heartspike",  -- Level 98
            "Heartrip",    -- Level 93
            "Heartrend",   -- Level 88
            "Heartpierce", -- Level 83
            "Deadfall",    -- Level 78
        },
        ['CalledShotsArrow'] = {
            "Called Shots IX",   -- Level 126
            "Inevitable Shots",  -- Level 121
            "Claimed Shots",     -- Level 116
            "Marked Shots",      -- Level 111
            "Foreseen Shots",    -- Level 106
            "Anticipated Shots", -- Level 101
            "Forecasted Shots",  -- Level 96
            "Announced Shots",   -- Level 91
            "Called Shots",      -- Level 86
        },
        ['FocusedArrows'] = {
            "Focused Hail of Arrows XII",  -- Level 130
            "Focused Frenzy of Arrows",    -- Level 125
            "Focused Whirlwind of Arrows", -- Level 120
            "Focused Blizzard of Arrows",  -- Level 115
            "Focused Arrowgale",           -- Level 110
            "Focused Arrowrain",           -- Level 105
            "Focused Rain of Arrows",      -- Level 100
            "Focused Arrow Swarm",         -- Level 95
            "Focused Tempest of Arrows",   -- Level 90
            "Focused Storm of Arrows",     -- Level 85
        },
        ['DichoSpell'] = {
            "Reciprocal Fusillade", -- Level 121
            "Ecliptic Fusillade",   -- Level 116
            "Composite Fusillade",  -- Level 111
            "Dissident Fusillade",  -- Level 106
            "Dichotomic Fusillade", -- Level 101
        },
        ['SummerNuke'] = {
            "Summer's Dew XII",  -- Level 129
            "Summer's Deluge",   -- Level 124
            "Summer's Torrent",  -- Level 119
            "Summer's Sleet",    -- Level 114
            "Summer's Tempest",  -- Level 109
            "Summer's Cyclone",  -- Level 104
            "Summer's Gale",     -- Level 99
            "Summer's Squall",   -- Level 94
            "Summer's Storm",    -- Level 89
            "Summer's Mist",     -- Level 84
            "Summer's Viridity", -- Level 79
        },
        ['SwarmDot'] = {
            "Spitestinger Swarm",  -- Level 126
            "Hotaria Swarm",       -- Level 121
            "Bloodbeetle Swarm",   -- Level 116
            "Ice Burrower Swarm",  -- Level 111
            "Bonecrawler Swarm",   -- Level 106
            "Blisterbeetle Swarm", -- Level 101
            "Dreadbeetle Swarm",   -- Level 96
            "Vespid Swarm",        -- Level 91
            "Scarab Swarm",        -- Level 86
            "Beetle Swarm",        -- Level 81
            "Hornet Swarm",        -- Level 76
            "Wasp Swarm",          -- Level 71
            "Locust Swarm",        -- Level 67
            "Drifting Death",      -- Level 62
            "Fire Swarm",          -- Level 55
            "Drones of Doom",      -- Level 54
            "Swarm of Pain",       -- Level 40
            "Stinging Swarm",      -- Level 25
        },
        ['ShortSwarmDot'] = {
            "Swarm of Spitemidges",  -- Level 128
            "Swarm of Fernflies",    -- Level 123
            "Swarm of Bloodflies",   -- Level 118
            "Swarm of Hyperboreads", -- Level 113
            "Swarm of Glistenwings", -- Level 103
            "Swarm of Vespines",     -- Level 98
            "Swarm of Sand Wasps",   -- Level 93
            "Swarm of Hornets",      -- Level 88
            "Swarm of Bees",         -- Level 83
        },
        ['UnityBuff'] = {
            "Wildstalker's Unity",  -- Level 110
            "Copsestalker's Unity", -- Level 105
            "Bosquetender's Unity", -- Level 100
        },
        ['Protectionbuff'] = {
            "Protection of the Grove",         -- Level 130
            "Protection of the Valley",        -- Level 120
            "Protection of the Wakening Land", -- Level 115
            "Protection of the Woodlands",     -- Level 110
            "Protection of the Forest",        -- Level 105
            "Protection of the Bosque",        -- Level 100
            "Protection of the Copse",         -- Level 95
            "Protection of the Vale",          -- Level 90
            "Protection of the Paw",           -- Level 85
            "Protection of the Kirkoten",      -- Level 80
            "Protection of the Minohten",      -- Level 75
            "Protection of the Wild",          -- Level 65
            "Warder's Protection",             -- Level 60
            "Force of Nature",                 -- Level 48
        },
        ['ShoutBuff'] = {
            "Shout of the Grovestalker",     -- Level 129
            "Shout of the Fernstalker",      -- Level 124
            "Shout of the Dusksage Stalker", -- Level 119
            "Shout of the Arbor Stalker",    -- Level 114
            "Shout of the Wildstalker",      -- Level 109
            "Shout of the Copsestalker",     -- Level 104
            "Shout of the Bosquestalker",    -- Level 100
            "Shout of the Predator",         -- Level 98
        },
        ['AggroBuff'] = {
            "Devastating Blades XII", -- Level 129
            "Devastating Barrage",    -- Level 119
            "Devastating Velium",     -- Level 114
            "Devastating Steel",      -- Level 109
            "Devastating Swords",     -- Level 104
            "Devastating Impact",     -- Level 99
            "Devastating Slashes",    -- Level 94
            "Devastating Edges",      -- Level 89
            "Devastating Blades",     -- Level 84
        },
        ['AggroReducerBuff'] = {
            "Jolting Luclinite", -- Level 117
            "Jolting Velium",    -- Level 112
            "Jolting Steel",     -- Level 107
            "Jolting Swords",    -- Level 102
            "Jolting Shock",     -- Level 97
            "Jolting Impact",    -- Level 92
            "Jolting Edges",     -- Level 87
            "Jolting Swings",    -- Level 82
            "Jolting Strikes",   -- Level 77
            "Jolting Blades",    -- Level 54
        },
        ['AggroKick'] = {
            "Enraging Kicks XII",        -- Level 127
            "Enraging Roundhouse Kicks", -- Level 117
            "Enraging Axe Kicks",        -- Level 112
            "Enraging Wheel Kicks",      -- Level 107
            "Enraging Cut Kicks",        -- Level 102
            "Enraging Heel Kicks",       -- Level 97
            "Enraging Crescent Kicks",   -- Level 92
        },
        ['ParryProcBuff'] = {
            "Vociferous Blades", -- Level 120
            "Howling Blades",    -- Level 115
            "Roaring Blades",    -- Level 110
            "Roaring Weapons",   -- Level 105
            "Deafening Weapons", -- Level 100
            "Deafening Edges",   -- Level 95
            "Crackling Edges",   -- Level 90
            "Crackling Blades",  -- Level 85
            "Thundering Blades", -- Level 75
        },
        ['Eyes'] = {
            "Eyes of the Grove",      -- Level 130
            "Eyes of the Phoenix",    -- Level 124
            "Eyes of the Senshali",   -- Level 119
            "Eyes of the Visionary",  -- Level 114
            "Eyes of the Sabertooth", -- Level 109
            "Eyes of the Harrier",    -- Level 104
            "Eyes of the Howler",     -- Level 99
            "Eyes of the Raptor",     -- Level 94
            "Eyes of the Wolf",       -- Level 89
            "Eyes of the Nocturnal",  -- Level 84
            "Eyes of the Peregrine",  -- Level 79
            "Eyes of the Owl",        -- Level 74
            "Eagle Eye",              -- Level 58
            "Falcon Eye",             -- Level 52
            "Hawk Eye",               -- Level 11
        },
        ['GroupStrengthBuff'] = {
            "Strength of the Grovestalker",    -- Level 127
            "Strength of the Arbor Stalker",   -- Level 112
            "Strength of the Wildstalker",     -- Level 107
            "Strength of the Copsestalker",    -- Level 102
            "Strength of the Bosquestalker",   -- Level 97
            "Strength of the Gladetender",     -- Level 92
            "Strength of the Thicket Stalker", -- Level 87
            "Strength of the Tracker",         -- Level 82
            "Strength of the Gladewalker",     -- Level 77
            "Strength of the Forest Stalker",  -- Level 72
            "Strength of the Hunter",          -- Level 67
            "Strength of Tunare",              -- Level 62
            "Strength of Nature",              -- Level 51
            "Nature's Precision",              -- Level 37
        },
        ['GroupPredatorBuff'] = {
            "Call of the Predator XVI",      -- Level 127
            "Shout of the Fernstalker",      -- Level 124
            "Shout of the Dusksage Stalker", -- Level 119
            "Frostroar of the Predator",     -- Level 112
            "Wail of the Predator",          -- Level 107
            "Bellow of the Predator",        -- Level 102
            "Shout of the Bosquestalker",    -- Level 100
            "Shout of the Predator",         -- Level 98
            "Cry of the Predator",           -- Level 93
            "Roar of the Predator",          -- Level 88
            "Yowl of the Predator",          -- Level 83
            "Gnarl of the Predator",         -- Level 78
            "Snarl of the Predator",         -- Level 73
            "Howl of the Predator",          -- Level 69
            "Spirit of the Predator",        -- Level 64
            "Call of the Predator",          -- Level 60
            "Mark of the Predator",          -- Level 56
        },
        ['GroupEnrichmentBuff'] = {
            "Fernstalker's Enrichment",   -- Level 125
            "Arbor Stalker's Enrichment", -- Level 115
            "Wildstalker's Enrichment",   -- Level 110
            "Copsestalker's Enrichment",  -- Level 105
        },
        ['Rathe'] = {
            "Cloak of Underbrush",   -- Level 127
            "Cloak of Needlespikes", -- Level 122
            "Cloak of Bloodbarbs",   -- Level 117
            "Cloak of Rimespurs",    -- Level 112
            "Cloak of Needlebarbs",  -- Level 107
            "Cloak of Nettlespears", -- Level 102
            "Cloak of Spurs",        -- Level 97
            "Cloak of Burrs",        -- Level 92
            "Cloak of Quills",       -- Level 87
            "Cloak of Feathers",     -- Level 82
            "Cloak of Scales",       -- Level 77
            "Guard of the Earth",    -- Level 67
            "Call of the Rathe",     -- Level 62
            "Call of Earth",         -- Level 50
            "Riftwind's Protection", -- Level 29
        },
        ['BowDisc'] = {
            "Pureshot Discipline", -- Level 100
            "Sureshot Discipline", -- Level 85
            "Aimshot Discipline",  -- Level 80
            "Trueshot Discipline", -- Level 55
        },
        ['MeleeDisc'] = {
            "Grovestalker's Discipline",     -- Level 130
            "Fernstalker's Discipline",      -- Level 125
            "Dusksage Stalker's Discipline", -- Level 120
            "Arbor Stalker's Discipline",    -- Level 115
            "Wildstalker's Discipline",      -- Level 110
            "Copsestalker's Discipline",     -- Level 105
            "Bosquestalker's Discipline",    -- Level 100
        },
        ['DefenseDisc'] = {
            "Weapon Shield Discipline", -- Level 60
        },
        ['Fireboon'] = {
            "Fernflash Boon",   -- Level 123
            "Lunarflare Boon",  -- Level 118
            "Pyroclastic Boon", -- Level 113
            "Skyfire Boon",     -- Level 108
            "Wildfire Boon",    -- Level 103
            "Ashcloud Boon",    -- Level 98
        },
        ['Firenuke'] = {
            "Volcanic Ash XVIII",     -- Level 128
            "Lunarflare Ash",         -- Level 118
            "Pyroclastic Ash",        -- Level 113
            "Skyfire Ash",            -- Level 108
            "Wildfire Ash",           -- Level 103
            "Vileoak Ash",            -- Level 98
            "Beastwood Ash",          -- Level 93
            "Burning Ash",            -- Level 88
            "Cataclysm Ash",          -- Level 83
            "Galvanic Ash",           -- Level 78
            "Volcanic Ash",           -- Level 73
            "Scorched Earth",         -- Level 70
            "Hearth Embers",          -- Level 69
            "Sylvan Burn",            -- Level 65
            "Ancient: Burning Chaos", -- Level 65
            "Brushfire",              -- Level 64
            "FireStrike",             -- Level 52
            "Call of Flame",          -- Level 49
            "Burning Arrow",          -- Level 39
            "Flaming Arrow",          -- Level 29
            "Ignite",                 -- Level 19
            "Burst of Fire",          -- Level 14
            "Flame Lick",             -- Level 3
        },
        ['Iceboon'] = {
            "Frostsquall Boon", -- Level 122
            "Nocturnal Boon",   -- Level 117
            "Mistral Boon",     -- Level 112
            "Windshear Boon",   -- Level 107
            "Windgale Boon",    -- Level 102
            "Windblast Boon",   -- Level 97
        },
        ['Icenuke'] = {
            "Frozen Wind XVIII",   -- Level 127
            "Gelid Wind",          -- Level 122
            "Coagulated Wind",     -- Level 117
            "Restless Wind",       -- Level 112
            "Frigid Wind",         -- Level 107
            "Bitter Wind",         -- Level 97
            "Biting Wind",         -- Level 87
            "Windwhip Bite",       -- Level 82
            "Rimefall Bite",       -- Level 77
            "Icefall Chill",       -- Level 72
            "Ancient: North Wind", -- Level 70
            "Frost Wind",          -- Level 68
            "Frozen Wind",         -- Level 63, lvl 102. Spell ID: 43478
            "Frozen Wind",         -- Level 63, lvl 63. Spell ID: 3418
            "Icewind",             -- Level 52
        },
        ['Heartshot'] = {
            "Heartruin",   -- Level 120
            "Heartsunder", -- Level 115
            "Heartcleave", -- Level 110
            "Heartsplit",  -- Level 105
            "Heartslash",  -- Level 95
            "Heartslice",  -- Level 90
            "Heartsting",  -- Level 80
            "Heartsting",  -- Level 80
            "Heartshot",   -- Level 75
        },
        ['EndRegenDisc'] = {
            "Hiatus V",        -- Level 126
            "Convalesce",      -- Level 121
            "Night's Calming", -- Level 116
            "Relax",           -- Level 111
            "Hiatus",          -- Level 106
            "Breather",        -- Level 101
            "Rest",            -- Level 96
            "Reprieve",        -- Level 91
            "Respite",         -- Level 86
        },
        ['Coat'] = {
            "Underbrush Coat",  -- Level 128
            "Needlespike Coat", -- Level 123
            "Moonthorn Coat",   -- Level 118
            "Rimespur Coat",    -- Level 113
            "Needlebarb Coat",  -- Level 108
            "Nettlespear Coat", -- Level 103
            "Spurcoat",         -- Level 98
            "Burrcoat",         -- Level 93
            "Quillcoat",        -- Level 88
            "Spinecoat",        -- Level 83
            "Briarcoat",        -- Level 68
            "Bladecoat",        -- Level 63
            "Thorncoat",        -- Level 60
            "Spikecoat",        -- Level 42
            "Bramblecoat",      -- Level 34
            "Barbcoat",         -- Level 30
            "Thistlecoat",      -- Level 13
        },
        ['Mask'] = {
            "Mask of the Stalker", -- Level 65
        },
        ['Hunt'] = {
            "Consumed by the Hunt X",  -- Level 130
            "Engulfed by the Hunt",    -- Level 125
            "Steeled by the Hunt",     -- Level 120
            "Provoked by the Hunt",    -- Level 115
            "Spurred by the Hunt",     -- Level 110
            "Energized by the Hunt",   -- Level 105
            "Inspired by the Hunt",    -- Level 100
            "Galvanized by the Hunt",  -- Level 95
            "Invigorated by the Hunt", -- Level 90
            "Consumed by the Hunt",    -- Level 75
        },
        ['Heal'] = {
            "Lifespring",            -- Level 126
            "Elizerain Spring",      -- Level 121
            "Darkflow Spring",       -- Level 116
            "Meltwater Spring",      -- Level 111
            "Wellspring",            -- Level 106
            "Cloudfont",             -- Level 101
            "Cloudburst",            -- Level 96
            "Purespring",            -- Level 91
            "Purefont",              -- Level 86
            "Oceangreen Aquifer",    -- Level 81
            "Dragonscale Aquifer",   -- Level 76
            "Sunderock Springwater", -- Level 71
            "Sylvan Water",          -- Level 67
            "Sylvan Light",          -- Level 65
            "Chloroblast",           -- Level 62
            "Greater Healing",       -- Level 44
            "Healing",               -- Level 32
            "Light Healing",         -- Level 20
            "Minor Healing",         -- Level 8
            "Salve",                 -- Level 1
        },
        ['Fastheal'] = {             -- 30s recast. ToT
            "Desperate Deluge IX",   -- Level 129
            "Desperate Quenching",   -- Level 124
            "Desperate Geyser",      -- Level 119
            "Desperate Meltwater",   -- Level 114
            "Desperate Dewcloud",    -- Level 109
            "Desperate Dousing",     -- Level 104
            "Desperate Drenching",   -- Level 99
            "Desperate Downpour",    -- Level 94
            "Desperate Deluge",      -- Level 89, lvl 89
        },
        ['Totheal'] = {
            "Lifespring",       -- Level 126
            "Elizerain Spring", -- Level 121
            "Darkflow Spring",  -- Level 116
            "Meltwater Spring", -- Level 111, lvl 111
            "Wellspring",       -- Level 106
            "Cloudfont",        -- Level 101
            "Cloudburst",       -- Level 96
        },
        ['RegenSpells'] = {
            "Grovestalker's Vigor",     -- Level 128
            "Fernstalker's Vigor",      -- Level 123
            "Dusksage Stalker's Vigor", -- Level 118
            "Arbor Stalker's Vigor",    -- Level 113
            "Wildstalker's Vigor",      -- Level 108
            "Copsestalker's Vigor",     -- Level 103
            "Bosquestalker's Vigor",    -- Level 98
            "Gladewalker's Vigor",      -- Level 93
            "Stalker's Vigor",          -- Level 88
            "Hunter's Vigor",           -- Level 68
            "Regrowth",                 -- Level 64
            "Chloroplast",              -- Level 55
        },
        ['SnareSpells'] = {
            "Earthen Shackles", -- Level 69
            "Earthen Embrace",  -- Level 61
            "Ensnare",          -- Level 51
            "Snare",            -- Level 6
            "Tangling Weeds",   -- Level 5
        },
        ['FireFist'] = {
            "Feral Form",         -- Level 64
            "Greater Wolf Form",  -- Level 56
            "Wolf Form",          -- Level 48
            "Nature's Precision", -- Level 37
            "Firefist",           -- Level 17
        },
        ['DsBuff'] = {
            "Shield of Underbrush",    -- Level 126
            "Shield of Needlespikes",  -- Level 121
            "Shield of Shadethorns",   -- Level 116
            "Shield of Rimespurs",     -- Level 111
            "Shield of Needlebarbs",   -- Level 106
            "Shield of Nettlespears",  -- Level 101
            "Shield of Nettlespines",  -- Level 96
            "Shield of Bramblespikes", -- Level 91
            "Shield of Nettlespikes",  -- Level 86
            "Shield of DrySpines",     -- Level 81
            "Shield of Spurs",         -- Level 76
            "Shield of Needles",       -- Level 71
            "Shield of Briar",         -- Level 66
            "Shield of Thorns",        -- Level 62
            "Shield of Spikes",        -- Level 58
            "Shield of Brambles",      -- Level 43
            "Shield of Thistles",      -- Level 24
        },
        ['SkinLike'] = {
            "Natureskin",        -- Level 65
            "Skin Like Nature",  -- Level 59
            "Skin Like Diamond", -- Level 54
            "Skin Like Steel",   -- Level 38
            "Skin Like Rock",    -- Level 21
            "Skin Like Wood",    -- Level 7
        },
        ['MoveSpells'] = {
            "Spirit of Falcons",   -- Level 85
            "Spirit of Eagle",     -- Level 65
            "Pack Shrew",          -- Level 49
            "Spirit of the Shrew", -- Level 41
            "Spirit of Wolf",      -- Level 28
        },
        ['Alliance'] = {
            "Fernstalker's Covariance",       -- Level 123
            "Dusksage Stalker's Conjunction", -- Level 118
            "Arbor Stalker's Coalition",      -- Level 113
            "Wildstalker's Covenant",         -- Level 108
            "Bosquestalker's Alliance",       -- Level 103
        },
        ['Cloak'] = {
            "Ro's Burning Cloak VI",         -- Level 128
            "Shalowain's Crucible Cloak",    -- Level 123
            "Luclin's Darkfire Cloak",       -- Level 117
            "Outrider's Ever-Burning Cloak", -- Level 112
            "Lavastorm Cloak",               -- Level 107
            "Ro's Burning Cloak",            -- Level 97
        },
        ['Veil'] = {
            "Shadowveil",      -- Level 125
            "Duskveil",        -- Level 116
            "Frostveil",       -- Level 111
            "Vaporous Veil",   -- Level 106
            "Shimmering Veil", -- Level 101
            "Arbor Veil",      -- Level 96
            "Veil of Alaris",  -- Level 91
            "Nature Veil",     -- Level 66
        },
        ['JoltingKicks'] = {
            "Jolting Kicks XII",        -- Level 127
            "Jolting Drop Kicks",       -- Level 122
            "Jolting Roundhouse Kicks", -- Level 117
            "Jolting Axe Kicks",        -- Level 112
            "Jolting Wheel Kicks",      -- Level 107
            "Jolting Cut Kicks",        -- Level 102
            "Jolting Heel Kicks",       -- Level 97
            "Jolting Crescent Kicks",   -- Level 92
            "Jolting Hook Kicks",       -- Level 87
            "Jolting Frontkicks",       -- Level 82
            "Jolting Kicks",            -- Level 72
        },
        ['AEBlades'] = {
            "Storm of Blades VII", -- Level 126
            "Maelstrom of Blades", -- Level 121
            "Tempest of Blades",   -- Level 116
            "Blizzard of Blades",  -- Level 111
            "Gale of Blades",      -- Level 106
            "Squall Of Blades",    -- Level 101
            "Storm of Blades",     -- Level 96
        },
        ['FocusedBlades'] = {
            "Focused Maelstrom of Blades", -- Level 124
            "Focused Tempest of Blades",   -- Level 119
            "Focused Blizzard of Blades",  -- Level 114
            "Focused Gale of Blades",      -- Level 109
            "Focused Squall of Blades",    -- Level 103
            "Focused Storm of Blades",     -- Level 98
        },
        ['ReflexSlashHeal'] = {
            "Reflexive Needlespikes", -- Level 121
            "Reflexive Rimespurs",    -- Level 111
            "Reflexive Nettlespears", -- Level 105
            "Reflexive Bladespurs",   -- Level 100
        },
        ['AEArrows'] = {
            "Frenzy of Arrows",    -- Level 124
            "Whirlwind of Arrows", -- Level 119
            "Blizzard of Arrows",  -- Level 114
            "Gale of Arrows",      -- Level 109
            "Cyclone of Arrows",   -- Level 104
            "Rain of Arrows",      -- Level 100
            "Squall of Arrows",    -- Level 99
            "Arrow Swarm",         -- Level 95
            "Swarm of Arrows",     -- Level 94
            "Tempest of Arrows",   -- Level 90
            "Fusillade of Arrows", -- Level 89
            "Storm of Arrows",     -- Level 85
            "Barrage of Arrows",   -- Level 84
            "Arc of Arrows",       -- Level 79
            "Hail of Arrows",      -- Level 68
        },
    },
    -- These are handled differently from normal rotations in that we try to make some intelligent decisions about which spells to use instead
    -- of just slamming through the base ordered list.
    -- These will run in order and exit after the first valid spell to cast
    ['HealRotationOrder'] = {
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['MainHealPoint'] = {
            {
                name = "Fastheal",
                type = "Spell",
                cond = function(self, _, target)
                    return Config:GetSetting('DoHeals')
                end,
            },
            {
                name = "Heal",
                type = "Spell",
                cond = function(self, _, target)
                    return Config:GetSetting('DoHeals')
                end,
            },
        },
    },
    ['Charm']             = {
        ['Assist'] = {
            { name = "Taunt", type = "Ability", },
        },
    },
    ['RotationOrder']     = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Ranged Positioning',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Config:GetSetting('DoMelee') and not Core.IsModeActive("Healer")
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS Buffs',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Defense',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'Tank',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            load_cond = function(self, spell) return Core.IsTanking() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
    },
    ['Rotations']         = {
        ['Downtime'] = {
            {
                name = "Wildstalker's Unity (Azia)",
                type = "AA",
                tooltip = Tooltips.UnityBuff,
                active_cond = function(self, aaName) return Casting.TargetHasBuff(mq.TLO.Me.AltAbility(aaName).Spell, mq.TLO.Me) end,
                cond = function(self, aaName)
                    return castWSU() and not Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Protectionbuff",
                type = "Spell",
                tooltip = Tooltips.Protectionbuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return not castWSU() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "ParryProcBuff",
                type = "Spell",
                tooltip = Tooltips.ParryProcBuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return not castWSU() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Hunt",
                type = "Spell",
                tooltip = Tooltips.Hunt,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return not castWSU() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Eyes",
                type = "Spell",
                tooltip = Tooltips.Eyes,
                load_cond = function(self) return not Config:GetSetting('DoMask') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return not castWSU() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Coat",
                type = "Spell",
                tooltip = Tooltips.Coat,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Mask",
                type = "Spell",
                tooltip = Tooltips.Mask,
                load_cond = function(self) return Config:GetSetting('DoMask') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "FireFist",
                type = "Spell",
                tooltip = Tooltips.FireFist,
                load_cond = function(self) return Config:GetSetting('DoFireFist') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "DsBuff",
                type = "Spell",
                tooltip = Tooltips.DsBuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SkinLike",
                type = "Spell",
                tooltip = Tooltips.SkinLike,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Cloak",
                type = "Spell",
                tooltip = Tooltips.Cloak,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Veil",
                type = "Spell",
                tooltip = Tooltips.Veil,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "AggroReducerBuff",
                type = "Spell",
                tooltip = Tooltips.AggroReducerBuff,
                load_cond = function(self, spell) return not Core.IsTanking() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Config:GetSetting('DoAggroReducerBuff') and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "AggroBuff",
                type = "Spell",
                tooltip = Tooltips.AggroBuff,
                load_cond = function(self, spell) return Core.IsTanking() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return not Config:GetSetting('DoAggroReducerBuff') and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Poison Arrows",
                type = "AA",
                tooltip = Tooltips.PoisonArrow,
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName) and Config:GetSetting('DoPoisonArrow')
                end,
            },
            {
                name = "Flaming Arrows",
                type = "AA",
                tooltip = Tooltips.FlamingArrow,
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName) and (mq.TLO.Me.Level() < 86 or not Config:GetSetting('DoPoisonArrow'))
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Rathe",
                type = "Spell",
                tooltip = Tooltips.Rathe,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupStrengthBuff",
                type = "Spell",
                tooltip = Tooltips.GroupStrengthBuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupPredatorBuff",
                type = "Spell",
                tooltip = Tooltips.GroupPredatorBuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ShoutBuff",
                type = "Spell",
                tooltip = Tooltips.ShoutBuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupEnrichmentBuff",
                type = "Spell",
                tooltip = Tooltips.GroupEnrichmentBuff,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "MoveSpells",
                type = "Spell",
                tooltip = Tooltips.MoveSpells,
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "RegenSpells",
                type = "Spell",
                tooltip = Tooltips.RegenSpells,
                load_cond = function(self) return Config:GetSetting('DoRegen') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Pack Hunt",
                type = "AA",
                tooltip = Tooltips.PackHunt,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Entropy of Nature",
                type = "AA",
                tooltip = Tooltips.EoN,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Spire of the Pathfinders",
                type = "AA",
                tooltip = Tooltips.SotP,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Scarlet Cheetah's Fang",
                type = "AA",
                tooltip = Tooltips.SCF,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Empowered Blades",
                type = "AA",
                tooltip = Tooltips.EB,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Auspice of the Hunter",
                type = "AA",
                tooltip = Tooltips.AotH,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "BowDisc",
                type = "Disc",
                tooltip = Tooltips.BowDisc,
                cond = function(self)
                    return Casting.NoDiscActive() and not Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "MeleeDisc",
                type = "Disc",
                tooltip = Tooltips.MeleeDisc,
                cond = function(self)
                    return Casting.NoDiscActive() and Config:GetSetting('DoMelee')
                end,
            },
        },
        ['Tank'] = {
            {
                name = "Taunt",
                type = "Ability",
                tooltip = Tooltips.Taunt,
                cond = function(self, abilityName, target)
                    return mq.TLO.Me.TargetOfTarget.ID() ~= mq.TLO.Me.ID() and target.ID() > 0 and Targeting.GetTargetDistance(target) < 30
                end,
            },
            {
                name = "AggroKick",
                type = "Disc",
                tooltip = Tooltips.AggroKick,
                cond = function(self)
                    return Targeting.GetTargetDistance() <= 50 and mq.TLO.Me.PctAggro() > 50
                end,
            },
            {
                name = "SummerNuke",
                type = "Spell",
                tooltip = Tooltips.SummerNuke,
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell) and (mq.TLO.Me.PctAggro() < 100 or mq.TLO.Me.SecondaryPctAggro() > 50)
                end,
            },
        },
        ['Ranged Positioning'] = {
            {
                name = "Ranged Nav",
                type = "CustomFunc",
                custom_func = function(self)
                    Core.SafeCallFunc("Ranger Ranged Nav", self.Helpers.rangedNav)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "ArrowOpener",
                type = "Spell",
                tooltip = Tooltips.ArrowOpener,
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell) and Config:GetSetting('DoOpener') and Config:GetSetting('DoReagentArrow')
                end,
            },
            {
                name = "PullOpener",
                type = "Spell",
                tooltip = Tooltips.PullOpener,
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell) and Config:GetSetting('DoReagentArrow')
                end,
            },
            {
                name = "CalledShotsArrow",
                type = "Spell",
                tooltip = Tooltips.CalledShotsArrow,
                cond = function(self, spell)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FocusedArrows",
                type = "Spell",
                tooltip = Tooltips.FocusedArrows,
                cond = function(self, spell)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "DichoSpell",
                type = "Spell",
                tooltip = Tooltips.DichoSpell,
                cond = function(self, spell)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Heartshot",
                type = "Spell",
                tooltip = Tooltips.Heartshot,
                cond = function(self, spell)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Fireboon",
                type = "Spell",
                tooltip = Tooltips.Fireboon,
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell) and not Casting.SelfBuffCheck(spell) --hardcode later, we need trigger
                end,
            },
            {
                name = "Iceboon",
                type = "Spell",
                tooltip = Tooltips.Iceboon,
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell) and not Casting.SelfBuffCheck(spell) --hardcode later, we need trigger
                end,
            },
            {
                name = "Entrap",
                tooltip = Tooltips.Entrap,
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoSnare') and Casting.DetAACheck(aaName) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpells",
                type = "Spell",
                tooltip = Tooltips.SnareSpells,
                cond = function(self, spell, target)
                    return Config:GetSetting('DoSnare') and Casting.DetSpellCheck(spell) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "AEArrows",
                type = "Spell",
                tooltip = Tooltips.AEArrows,
                cond = function(self, spell)
                    return Casting.OkayToNuke() and Config:GetSetting('DoAoE')
                end,
            },
            {
                name = "SwarmDot",
                type = "Spell",
                tooltip = Tooltips.SwarmDot,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot')
                end,
            },
            {
                name = "ShortSwarmDot",
                type = "Spell",
                tooltip = Tooltips.ShortSwarmDot,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot')
                end,
            },
            {
                name = "Firenuke",
                type = "Spell",
                tooltip = Tooltips.Firenuke,
                cond = function(self, spell)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Icenuke",
                type = "Spell",
                tooltip = Tooltips.Icenuke,
                cond = function(self, spell)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Elemental Arrow",
                tooltip = Tooltips.EA,
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "AEBlades",
                type = "Disc",
                tooltip = Tooltips.AEBlades,
                cond = function(self)
                    return Config:GetSetting('DoAoE') and Targeting.GetTargetDistance() < 50 and Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "FocusedBlades",
                type = "Disc",
                tooltip = Tooltips.FocusedBlades,
                cond = function(self)
                    return Targeting.GetTargetDistance() < 50 and Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "ReflexSlashHeal",
                type = "Disc",
                tooltip = Tooltips.ReflexSlashHeal,
                cond = function(self)
                    return Targeting.GetTargetDistance() < 50 and Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "EndRegenDisc",
                type = "Disc",
                tooltip = Tooltips.EndRegenDisc,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive() and not Casting.IHaveBuff(discSpell.RankName.Name() or "") and mq.TLO.Me.PctEndurance() < 30
                end,
            },
        },
        ['DPS Buffs'] = {
            {
                name = "Guardian of the Forest",
                type = "AA",
                tooltip = Tooltips.GotF,
                cond = function(self, spell)
                    return not Casting.IHaveBuff("Group Guardian of the Forest") and not Casting.IHaveBuff("Outrider's Accuracy")
                end,
            },
            {
                name = "Outrider's Accuracy",
                type = "AA",
                tooltip = Tooltips.OA,
                cond = function(self, spell)
                    return not Casting.IHaveBuff("Group Guardian of the Forest") and not Casting.IHaveBuff("Guardian of the Forest")
                end,
            },
            {
                name = "Group Guardian of the Forest",
                type = "AA",
                tooltip = Tooltips.GGotF,
                cond = function(self, spell)
                    return not Casting.IHaveBuff("Guardian of the Forest") and not Casting.IHaveBuff("Outrider's Accuracy")
                end,
            },
            {
                name = "Epic",
                type = "Item",
                tooltip = Tooltips.Epic,
                cond = function(self, itemName)
                    return Casting.NoDiscActive()
                end,
            },
        },
        ['Defense'] = {
            {
                name = "DefenseDisc",
                type = "Disc",
                tooltip = Tooltips.DefenseDisc,
                cond = function(self)
                    return mq.TLO.Me.PctHPs() < 20 and Casting.NoDiscActive()
                end,
            },
            {
                name = "Outrider's Evasion",
                tooltip = Tooltips.OE,
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctHPs() < 30
                end,
            },
            {
                name = "Protection of the Spirit Wolf",
                tooltip = Tooltips.PotSW,
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctHPs() < 40
                end,
            },
            {
                name = "Bulwark of the Brownies",
                tooltip = Tooltips.BotB,
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctHPs() < 50
                end,
            },
            {
                name = "JoltingKicks",
                type = "Disc",
                tooltip = Tooltips.JoltingKicks,
                cond = function(self)
                    return Targeting.GetTargetDistance() <= 50
                end,
            },
            {
                name = "Imbued Ferocity",
                type = "AA",
                tooltip = Tooltips.IF,
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctAggro() > 45
                end,
            },
            {
                name = "Silent Strikes",
                type = "AA",
                tooltip = Tooltips.SS,
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctAggro() > 60
                end,
            },
            {
                name = "Chameleon's Gift",
                type = "AA",
                tooltip = Tooltips.CG,
                cond = function(self, spell)
                    return mq.TLO.Me.PctAggro() > 70 and mq.TLO.Me.PctHPs() < 50
                end,
            },
            {
                name = "SummerNuke",
                type = "Spell",
                tooltip = Tooltips.SummerNuke,
                cond = function(self, spell)
                    return mq.TLO.Me.PctAggro() < 60
                end,
            },
        },
    },
    ['Spells']            = {
        {
            gem = 1,
            spells = {
                { name = "Fastheal", },
                { name = "Heal", },
            },
        },
        { -- SpellGem2 - Is Our Standard Fire Nuke 3-115
            gem = 2,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Firenuke", },
            },
        },
        { -- SpellGem 3 - This is Our Swarm Dot From 25 to 115
            gem = 3,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "SwarmDot", },
            },
        },
        { -- Use ArrowOpener if enabled or Snare if no AASnare
            gem = 4,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "ArrowOpener", cond = function(self) return Config:GetSetting('DoOpener') end, },
                { name = "SnareSpells", cond = function(self) return not Casting.DetAACheck(mq.TLO.Me.AltAbility(219).Name()) and Config:GetSetting('DoSnare') end, },
            },
        },
        {
            gem = 5,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "DichoSpell", cond = function(self) return mq.TLO.Me.Level() >= 101 end, },
                { name = "Icenuke", },
            },
        },
        {
            gem = 6,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "CalledShotsArrow", },
            },
        },
        {
            gem = 7,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "FocusedArrows", },
            },
        },
        {
            gem = 8,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Heartshot", },
            },
        },
        {
            gem = 9,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "SummerNuke", },
                { name = "AEArrows",   cond = function(self) return Config:GetSetting('DoAoE') end, },
                { name = "Veil", },
            },
        },
        {
            gem = 10,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "ShortSwarmDot", },
            },
        },
        {
            gem = 11,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Iceboon", },
            },
        },
        {
            gem = 12,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Fireboon", },
                { name = "Icenuke", },
            },
        },
        {
            gem = 13,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Alliance", },
            },
        },
    },
    ['Helpers']           = {
        rangedNav = function(reason)
            if Config:GetSetting('DoMelee') then return end
            if (Globals.AutoTargetID or 0) == 0 then return end

            local bowRange = Config:GetSetting('BowRange')

            if reason then
                Logger.log_verbose("rangedNav: reason=%s dist=%d bowRange=%d stick=%s LoS=%s", reason,
                    Targeting.GetTargetDistance(), bowRange, Config:GetSetting('UseRangedStick'), mq.TLO.Target.LineOfSight())
            end

            if not mq.TLO.Me.Moving() then
                Core.DoCmd('/squelch /face fast')
            end

            if not mq.TLO.Me.AutoFire() then
                Core.DoCmd('/autofire on')
            end

            -- No line of sight: sweep laterally around the target for a spot with a real (game) clear shot.
            if reason == "cantsee" then
                if not Movement:NavAroundCircle(mq.TLO.Target, bowRange) then
                    -- Nav can't path (off the mesh): stick toward the target to walk back onto it.
                    Logger.log_warn("Ranged nav: no navigable line-of-sight spot (off mesh?), falling back to a stick.")
                    Movement:DoStickCmd("%d id %d moveback uw", bowRange, Globals.AutoTargetID)
                    if not Config:GetSetting('UseRangedStick') then
                        -- Loose holds nothing: run the stick only until we regain line of sight, then drop it.
                        mq.delay(100, function() return mq.TLO.Stick.Active() end)
                        mq.delay(3000, function() return mq.TLO.Target.ID() == 0 or mq.TLO.Target.LineOfSight() end)
                        Movement:DoStickCmd("off")
                        Movement:ClearLastStickTimer()
                    end
                end
                return
            end

            if Config:GetSetting('UseRangedStick') then -- Use Ranged Stick: hold bow range with a stick.
                if reason == "toofar" or Targeting.GetTargetDistance() > bowRange + 10 then
                    if not mq.TLO.Navigation.Active() then
                        Movement:DoNav(true, "id %d distance=%d lineofsight=on", Globals.AutoTargetID, bowRange)
                        Core.DoCmd('/squelch /face fast')
                    end
                elseif (mq.TLO.Stick.StickTarget() or 0) ~= Globals.AutoTargetID or (mq.TLO.Stick.Status() or "off"):lower() == "off" then
                    Core.DoCmd('/squelch /face fast')
                    local stickHow = Config:GetSetting('StickHow') or ""
                    if #stickHow > 0 then
                        Movement:DoStickCmd("%s", stickHow)
                    else
                        Movement:DoStickCmd("%d id %d moveback uw", bowRange, Globals.AutoTargetID)
                    end
                end
            else -- Loose: react to the game's own range messages, one-shot, no held position.
                if reason == "toofar" then
                    Movement:DoNav(true, "id %d distance=%d lineofsight=on", Globals.AutoTargetID, bowRange)
                    Core.DoCmd('/squelch /face fast')
                elseif reason == "tooclose" then
                    Core.DoCmd('/squelch /face fast')
                    Movement:DoStickCmd("%d moveback uw", bowRange)
                    mq.delay(100, function() return mq.TLO.Stick.Active() end)
                    mq.delay(500, function() return not mq.TLO.Me.Moving() end)
                    Movement:DoStickCmd("off")
                    Movement:ClearLastStickTimer()
                end
            end
        end,

        PreEngage = function(target)
            if not target or not target() then return end
            local openerAbility = Core.GetResolvedActionMapItem('ArrowOpener')

            if not Config:GetSetting("DoOpener") or not openerAbility then return end

            Logger.log_debug("\ayPreEngage(): Testing Opener ability = %s", openerAbility.RankName.Name() or "None")

            if openerAbility and openerAbility() and mq.TLO.Me.PctMana() >= Config:GetSetting("ManaToNuke") and Casting.SpellReady(openerAbility) then
                Core.DoCmd("/squelch /face fast")
                Casting.UseSpell(openerAbility.RankName.Name(), target.ID(), false)
                Logger.log_debug("\agPreEngage(): Using Opener ability = %s", openerAbility.RankName.Name() or "None")
            else
                Logger.log_debug("\arPreEngage(): NOT using Opener ability = %s, DoOpener = %sd", openerAbility.RankName.Name() or "None",
                    Strings.BoolToColorString(Config:GetSetting("DoOpener")))
            end
        end,
    },
    ['PullAbilities']     = {
        {
            id = 'Snare',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('SnareSpells')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('SnareSpells')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('SnareSpells')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']     = {
        ['Mode']               = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 4,
            FAQ = "What do the different Modes Do?",
            Help = "Modes are used to change the behavior of the Mercenary based on the current situation. The modes are as follows:\n\n" ..
                "1. DPS - This mode is used for general DPS and is the default mode.\n" ..
                "2. Tank - This mode is used when you are tanking.\n" ..
                "3. Healer - This mode is used when you are healing.\n" ..
                "4. Hybrid - This mode is a combination of the other 3 and will attempt to be a jack of all trades.",
        },
        --Archery
        ['BowRange']           = {
            DisplayName = "Bow Range",
            Group = "Combat",
            Header = "Positioning",
            Category = "Archery",
            Index = 101,
            Tooltip = "The preferred distance to reposition to if we are too close/far or have no LoS (also the default range for ranged stick).",
            Default = 40,
            Min = 31,
            Max = 300,
            FAQ = "Why is my ranger rubber-banding, charging back and forth or changing heading constantly?",
            Answer = "Some terrain blocks LoS while MQ reports that the ranger has LoS.\n" ..
                "While we will attempt to solve this issue, manual intervention or setting adjustment may be required (Bow Range, Ranged Stick, etc).",
        },
        ['UseRangedStick']     = {
            DisplayName = "Use Ranged Stick",
            Group = "Combat",
            Header = "Positioning",
            Category = "Archery",
            Index = 102,
            Tooltip = "Disabled - autofire from present position, moving only if needed (too close/far, no LoS).\n" ..
                "Enabled - use stick while autofiring. Uses Stick How setting if set, otherwise uses '<bowrangesetting> moveback uw'",
            Default = false,
            Warning = function()
                if not Config:GetSetting('UseRangedStick') then return false, "" end
                local bowRange = Config:GetSetting('BowRange')
                if Config:GetSetting('ChaseOn') then
                    if Config:GetSetting('ChaseDistance') < bowRange then
                        return true, "Warning: Chase Distance is below Bow Range - chase may fight the ranged stick hold."
                    end
                elseif Config:GetSetting('ReturnToCamp') then
                    if Config:GetSetting('CampHard') then
                        return true, "Warning: Camp Hard pulls you to camp center - the ranged stick may not hold its bow range."
                    elseif Config:GetSetting('AutoCampRadius') < bowRange then
                        return true, "Warning: Camp Radius is below Bow Range - camp return may fight the ranged stick hold."
                    end
                end
                return false, ""
            end,
            FAQ = "Why is my ranger rubber-banding, charging back and forth or changing heading constantly?",
            Answer = "Turn off Use Ranged Stick (the default), so the ranger only repositions when a shot is actually refused instead of holding position.",
        },
        ['DoSnare']            = {
            DisplayName = "Cast Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Tooltip = "Enable casting Snare spells.",
            Default = true,
        },
        ['DoDot']              = {
            DisplayName = "Cast DOTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Tooltip = "Enable casting Damage Over Time spells.",
            Default = true,
        },
        ['DoHeals']            = {
            DisplayName = "Cast Heals",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Tooltip = "Enable casting of Healing spells.",
            Default = true,
        },
        ['DoRegen']            = {
            DisplayName = "Cast Regen Spells",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Enable casting of Regen spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoRunSpeed']         = {
            DisplayName = "Cast Run Speed Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use Ranger Run Speed Buffs.",
            Default = true,
        },
        ['DoMask']             = {
            DisplayName = "Cast Mask Spell",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Use Ranger Mask Spell",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoFireFist']         = {
            DisplayName = "Cast FireFist",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Use Ranger FireFist Line of Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAoE']              = {
            DisplayName = "Use AoEs",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Tooltip = "Enable AoE abilities and spells.",
            Default = false,
        },
        ['DoOpener']           = {
            DisplayName = "Use Openers",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Opening Arrow Shot Silent Shot Line.",
            Default = true,
        },
        ['DoPoisonArrow']      = {
            DisplayName = "Use Poison Arrow",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Enable use of Poison Arrow.",
            Default = true,
        },
        ['DoReagentArrow']     = {
            DisplayName = "Use Reagent Arrow",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Toggle usage of Spells and Openers that require Reagent arrows.",
            Default = false,
        },
        ['DoAggroReducerBuff'] = {
            DisplayName = "Cast Aggro Reducer Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Use Aggro Reduction Buffs.",
            Default = true,
        },
        ['HealPriority']       = {
            DisplayName = "Healing Priority",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Type = "Combo",
            ComboOptions = { 'Ignore', 'Big Heal Point', },
            Default = 2,
            Min = 1,
            Max = 2,
            Tooltip = "When to yield offensive rotations for healing:\n1 - Ignore (never)\n2 - Big Heal Point",
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release aimed at official servers.\n\n" ..
                "  This config is largely a port from older code, and has seen only minor adjustments. It has been flagged for revamp when we have the chance!\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },

}

return _ClassConfig
