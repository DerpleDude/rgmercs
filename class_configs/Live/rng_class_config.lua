local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require("utils.combat")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require('utils.globals')
local Logger       = require("utils.logger")
local Movement     = require("utils.movement")
local Strings      = require("utils.strings")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "2.0 - Live",
    _author               = "Algar",
    ['ModeChecks']        = {
        IsHealing = function()
            return Config:GetSetting('DoHealSpell') or Config:GetSetting('DoBurstHeal') or Casting.CanUseAA("Convergence of Spirits")
        end,
        IsCuring  = function() return Config:GetSetting('DoCures') end,
    },
    ['Modes']             = {
        'DPS',
    },
    ['Cure']              = {
        ['Poison'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'Balm', 'CurePoison', }) end, },
        },
        ['Disease'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'Balm', 'CureDisease', }) end, },
        },
        ['Curse'] = {
            { type = "Spell", name = "Balm", },
        },
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
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Aurora, the Heartwood Blade",
            "Heartwood Blade",
        },
    },
    ['AbilitySets']       = {
        ['CalledShotsArrow'] = {
            "Called Shots IX",             -- Level 126
            "Inevitable Shots",            -- Level 121
            "Claimed Shots",               -- Level 116
            "Marked Shots",                -- Level 111
            "Foreseen Shots",              -- Level 106
            "Anticipated Shots",           -- Level 101
            "Forecasted Shots",            -- Level 96
            "Announced Shots",             -- Level 91
            "Called Shots",                -- Level 86
        },
        ['FocusedArrows'] = {              -- Timer 5, single target
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
        ['AEArrowsSplash'] = {             -- Timer 5, targeted AE
            "Arrowflight",                 -- Level 122
            "Arrowswarm",                  -- Level 117
            "Arrowstorm",                  -- Level 112
            "Arrowgale",                   -- Level 110
            "Arrowrain",                   -- Level 105
            "Rain of Arrows",              -- Level 100
            "Arrow Swarm",                 -- Level 95
            "Tempest of Arrows",           -- Level 90
            "Storm of Arrows",             -- Level 85
        },
        ['AEArrowsCone'] = {               -- Timer 5, frontal cone
            "Hail of Arrows XII",          -- Level 129
            "Frenzy of Arrows",            -- Level 124
            "Whirlwind of Arrows",         -- Level 119
            "Blizzard of Arrows",          -- Level 114
            "Gale of Arrows",              -- Level 109
            "Cyclone of Arrows",           -- Level 104
            "Squall of Arrows",            -- Level 99
            "Swarm of Arrows",             -- Level 94
            "Fusillade of Arrows",         -- Level 89
            "Barrage of Arrows",           -- Level 84
            "Arc of Arrows",               -- Level 79
            "Hail of Arrows",              -- Level 68
        },
        ['DichoSpell'] = {
            "Reciprocal Fusillade", -- Level 121
            "Ecliptic Fusillade",   -- Level 116
            "Composite Fusillade",  -- Level 111
            "Dissident Fusillade",  -- Level 106
            "Dichotomic Fusillade", -- Level 101
        },
        ['Alliance'] = {
            "Fernstalker's Covariance",       -- Level 123
            "Dusksage Stalker's Conjunction", -- Level 118
            "Arbor Stalker's Coalition",      -- Level 113
            "Wildstalker's Covenant",         -- Level 108
            "Bosquestalker's Alliance",       -- Level 103
        },
        ['Heartshot'] = {
            "Heartbreak",     -- Level 125
            "Heartruin",      -- Level 120
            "Heartsunder",    -- Level 115
            "Heartcleave",    -- Level 110
            "Heartsplit",     -- Level 105
            "Heartcarve",     -- Level 100
            "Heartslash",     -- Level 95
            "Heartslice",     -- Level 90
            "Heartshear",     -- Level 85
            "Heartsting",     -- Level 80
            "Heartshot",      -- Level 75
        },
        ['Opener'] = {        -- Timer 8 from 103+. Requires Class 3 Wood Silver Tip Arrow
            "Concealed Shot", -- Level 125
            "Stealthy Shot",  -- Level 111
            "Silent Shot",    -- Level 103
            "Heartspike",     -- Level 98
            "Heartrip",       -- Level 93
            "Heartrend",      -- Level 88
            "Heartpierce",    -- Level 83
            "Deadfall",       -- Level 78
        },
        -- ['AggroShot'] = {       Timer 8. Requires Class 3 Wood Silver Tip Arrow/ReagantCheck
        --     "Angering Shot",    -- Level 100
        --     "Provoking Shot",   -- Level 95
        --     "Infuriating Shot", -- Level 90
        --     "Enraging Shot",    -- Level 85
        -- },
        ['FireNukeT1'] = {
            "Laurion Ash",     -- Level 123
            "Pyroclastic Ash", -- Level 113
            "Wildfire Ash",    -- Level 103
            "Beastwood Ash",   -- Level 93
            "Cataclysm Ash",   -- Level 83
            "Volcanic Ash",    -- Level 73
            "Hearth Embers",   -- Level 69
            "Sylvan Burn",     -- Level 65
            "Call of Flame",   -- Level 49
            "Flaming Arrow",   -- Level 29
        },
        ['FireNukeT4'] = {
            "Volcanic Ash XVIII",     -- Level 128
            "Lunarflare Ash",         -- Level 118
            "Skyfire Ash",            -- Level 108
            "Vileoak Ash",            -- Level 98
            "Burning Ash",            -- Level 88
            "Galvanic Ash",           -- Level 78
            "Scorched Earth",         -- Level 70
            "Ancient: Burning Chaos", -- Level 65
            "Brushfire",              -- Level 64
            "Burning Arrow",          -- Level 39
        },
        ['ColdNukeT2'] = {
            "Gelid Wind",      -- Level 122
            "Restless Wind",   -- Level 112
            "Frozen Wind",     -- Level 102, name is shared with a Level 63 timer 3 spell
            "Rime-Laced Wind", -- Level 92
            "Windwhip Bite",   -- Level 82
            "Icefall Chill",   -- Level 72
            "Frost Wind",      -- Level 68
            "Icewind",         -- Level 52
        },
        ['ColdNukeT3'] = {
            "Frozen Wind XVIII",   -- Level 127
            "Coagulated Wind",     -- Level 117
            "Frigid Wind",         -- Level 107
            "Bitter Wind",         -- Level 97
            "Biting Wind",         -- Level 87
            "Rimefall Bite",       -- Level 77
            "Ancient: North Wind", -- Level 70
            "Frozen Wind",         -- Level 63, name is shared with a Level 102 timer 2 spell
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
            "Summer's Dew",      -- Level 74
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
            "Swarm of Spitemidges",          -- Level 128
            "Swarm of Fernflies",            -- Level 123
            "Swarm of Bloodflies",           -- Level 118
            "Swarm of Hyperboreads",         -- Level 113
            "Swarm of Polybiads",            -- Level 108
            "Swarm of Glistenwings",         -- Level 103
            "Swarm of Vespines",             -- Level 98
            "Swarm of Sand Wasps",           -- Level 93
            "Swarm of Hornets",              -- Level 88
            "Swarm of Bees",                 -- Level 83
        },
        ['ArcheryDisc'] = {                  -- Timer 2
            "Pureshot Discipline",           -- Level 100
            "Bullseye Discipline",           -- Level 90
            "Sureshot Discipline",           -- Level 85
            "Aimshot Discipline",            -- Level 80
            "Trueshot Discipline",           -- Level 55
        },
        ['MeleeDisc'] = {                    -- Timer 2
            "Grovestalker's Discipline",     -- Level 130
            "Fernstalker's Discipline",      -- Level 125
            "Dusksage Stalker's Discipline", -- Level 120
            "Arbor Stalker's Discipline",    -- Level 115
            "Wildstalker's Discipline",      -- Level 110
            "Copsestalker's Discipline",     -- Level 105
            "Bosquestalker's Discipline",    -- Level 100
            "Warder's Wrath",                -- Level 69
        },
        ['FocusedBlades'] = {                -- Timer 6
            "Focused Maelstrom of Blades",   -- Level 124
            "Focused Tempest of Blades",     -- Level 119
            "Focused Blizzard of Blades",    -- Level 114
            "Focused Gale of Blades",        -- Level 109
            "Focused Squall of Blades",      -- Level 103
            "Focused Storm of Blades",       -- Level 98
        },
        ['AEBlades'] = {                     -- Timer 6
            "Storm of Blades VII",           -- Level 126
            "Maelstrom of Blades",           -- Level 121
            "Tempest of Blades",             -- Level 116
            "Blizzard of Blades",            -- Level 111
            "Gale of Blades",                -- Level 106
            "Squall of Blades",              -- Level 101
            "Storm of Blades",               -- Level 96
        },
        ['ReflexStrike'] = {
            "Reflexive Needlespikes",   -- Level 121
            "Reflexive Rimespurs",      -- Level 111
            "Reflexive Nettlespears",   -- Level 105
            "Reflexive Bladespurs",     -- Level 100
        },
        ['JoltingKicks'] = {            -- Timer 9
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
            "Jolting Snapkicks",        -- Level 77
            "Jolting Kicks",            -- Level 72
        },
        -- ['EnragingKicks'] = {              -- Timer 9
        --     "Enraging Kicks XII",          -- Level 127
        --     "Enraging Drop Kicks",         -- Level 122
        --     "Enraging Roundhouse Kicks",   -- Level 117
        --     "Enraging Axe Kicks",          -- Level 112
        --     "Enraging Wheel Kicks",        -- Level 107
        --     "Enraging Cut Kicks",          -- Level 102
        --     "Enraging Heel Kicks",         -- Level 97
        --     "Enraging Crescent Kicks",     -- Level 92
        -- },
        ['WeaponShield'] = {
            "Weapon Shield Discipline", -- Level 60
        },
        ['EndRegen'] = {
            --Timer 13, can't be used in combat
            "Breather", -- Level 101
            "Rest",     -- Level 96
            "Reprieve", -- Level 91
            "Respite",  -- Level 86
        },
        ['CombatEndRegen'] = {
            --Timer 13, can be used in combat.
            "Hiatus V",        -- Level 126
            "Convalesce",      -- Level 121
            "Night's Calming", -- Level 116
            "Relax",           -- Level 111
            "Hiatus",          -- Level 106
        },
        ['BurstHeal'] = {
            "Desperate Deluge IX", -- Level 129
            "Desperate Quenching", -- Level 124
            "Desperate Geyser",    -- Level 119
            "Desperate Meltwater", -- Level 114
            "Desperate Dewcloud",  -- Level 109
            "Desperate Dousing",   -- Level 104
            "Desperate Drenching", -- Level 99
            "Desperate Downpour",  -- Level 94
            "Desperate Deluge",    -- Level 89
        },
        ['HealSpell'] = {
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
        ['Balm'] = {
            "Mastery: Therapeutic Balm", -- Level 128
            "Therapeutic Balm",          -- Level 123
            "Lunar Balm",                -- Level 118
            "Wakening Balm",             -- Level 113
            "Fereth Balm",               -- Level 108
            "Kromtus Balm",              -- Level 103
            "Herbal Balm",               -- Level 98
            "Wild Balm",                 -- Level 93
            "Lucid Balm",                -- Level 88
            "Burynai Balm",              -- Level 83
            "Potamide Balm",             -- Level 78
            "Potamide Salve",            -- Level 73
        },
        ['ProtectionBuff'] = {
            "Protection of the Grove",         -- Level 130
            "Protection of Pal'Lomen",         -- Level 125
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
            "Ward of the Hunter",              -- Level 70
            "Protection of the Wild",          -- Level 65
            "Warder's Protection",             -- Level 60
            "Greater Wolf Form",               -- Level 56
            "Wolf Form",                       -- Level 48
            "Nature's Precision",              -- Level 37
            "Firefist",                        -- Level 17
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
        ['CoatDS'] = {
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
        ['HateProcBuff'] = {
            "Devastating Blades XII", -- Level 129
            "Devastating Spate",      -- Level 124
            "Devastating Barrage",    -- Level 119
            "Devastating Velium",     -- Level 114
            "Devastating Steel",      -- Level 109
            "Devastating Swords",     -- Level 104
            "Devastating Impact",     -- Level 99
            "Devastating Slashes",    -- Level 94
            "Devastating Edges",      -- Level 89
            "Devastating Blades",     -- Level 84
        },
        ['MeleeProcBuff'] = {
            "Sparking Blades",   -- Level 130
            "Arcing Blades",     -- Level 125
            "Vociferous Blades", -- Level 120
            "Howling Blades",    -- Level 115
            "Roaring Blades",    -- Level 110
            "Roaring Weapons",   -- Level 105
            "Deafening Weapons", -- Level 100
            "Deafening Edges",   -- Level 95
            "Crackling Edges",   -- Level 90
            "Crackling Blades",  -- Level 85
            "Deafening Blades",  -- Level 80
            "Thundering Blades", -- Level 75
            "Call of Lightning", -- Level 70
            "Cry of Thunder",    -- Level 65
            "Call of Ice",       -- Level 58
            "Call of Fire",      -- Level 55
            "Call of Sky",       -- Level 36
        },
        -- ['SummonedProc'] = {      Procs only fire on Summoned targets
        --     "Nature's Denial",  -- Level 69
        --     "Nature's Rebuke",  -- Level 64
        -- },
        ['SnareProcBuff'] = {
            "Grasping Nettlecoat", -- Level 91
        },
        ['JoltProcBuff'] = {
            "Jolting Emberquartz", -- Level 122
            "Jolting Luclinite",   -- Level 117
            "Jolting Velium",      -- Level 112
            "Jolting Steel",       -- Level 107
            "Jolting Swords",      -- Level 102
            "Jolting Shock",       -- Level 97
            "Jolting Impact",      -- Level 92
            "Jolting Edges",       -- Level 87
            "Jolting Swings",      -- Level 82
            "Jolting Strikes",     -- Level 77
            "Jolting Blades",      -- Level 54
        },
        ['BurningCloak'] = {
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
        ['Mask'] = {
            "Mask of the Stalker", -- Level 65
        },
        ['ShoutBuff'] = {
            "Shout of the Grovestalker",     -- Level 129
            "Shout of the Fernstalker",      -- Level 124
            "Shout of the Dusksage Stalker", -- Level 119
            "Shout of the Arbor Stalker",    -- Level 114
            "Shout of the Wildstalker",      -- Level 109
            "Shout of the Copsestalker",     -- Level 104
            "Shout of the Bosquestalker",    -- Level 100
        },
        ['StrengthBuff'] = {
            "Strength of the Grovestalker",     -- Level 127
            "Strength of the Fernstalker",      -- Level 122
            "Strength of the Dusksage Stalker", -- Level 117
            "Strength of the Arbor Stalker",    -- Level 112
            "Strength of the Wildstalker",      -- Level 107
            "Strength of the Copsestalker",     -- Level 102
            "Strength of the Bosquestalker",    -- Level 97
            "Strength of the Gladetender",      -- Level 92
            "Strength of the Thicket Stalker",  -- Level 87
            "Strength of the Tracker",          -- Level 82
            "Strength of the Gladewalker",      -- Level 77
            "Strength of the Forest Stalker",   -- Level 72
            "Strength of the Hunter",           -- Level 67
            "Strength of Tunare",               -- Level 62
            "Strength of Nature",               -- Level 51
        },
        ['PredatorBuff'] = {
            "Call of the Predator XVI",  -- Level 127
            "Shriek of the Predator",    -- Level 122
            "Bay of the Predator",       -- Level 117
            "Frostroar of the Predator", -- Level 112
            "Wail of the Predator",      -- Level 107
            "Bellow of the Predator",    -- Level 102
            "Shout of the Predator",     -- Level 98
            "Cry of the Predator",       -- Level 93
            "Roar of the Predator",      -- Level 88
            "Yowl of the Predator",      -- Level 83
            "Gnarl of the Predator",     -- Level 78
            "Snarl of the Predator",     -- Level 73
            "Howl of the Predator",      -- Level 69
            "Spirit of the Predator",    -- Level 64
            "Call of the Predator",      -- Level 60
            "Mark of the Predator",      -- Level 56
        },
        ['SingleCloakDS'] = {
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
        ['GroupCloakDS'] = {
            "Shared Cloak of Rimespurs",   -- Level 114
            "Shared Cloak of Needlebarbs", -- Level 109
            "Shared Cloak of Spurs",       -- Level 99
            "Shared Cloak of Burrs",       -- Level 94
        },
        ['GroupEnrichmentBuff'] = {
            "Fernstalker's Enrichment",   -- Level 125
            "Arbor Stalker's Enrichment", -- Level 115
            "Wildstalker's Enrichment",   -- Level 110
            "Copsestalker's Enrichment",  -- Level 105
        },
        ['HPTypeOne'] = {
            "Grovewood Coat",    -- Level 129
            "Glitterine Coat",   -- Level 124
            "Dusksage Coat",     -- Level 119
            "Obsidian Coat",     -- Level 114
            "Blackscale",        -- Level 109
            "Ravencoat",         -- Level 104
            "Shadowscale",       -- Level 99
            "Shadowcoat",        -- Level 94
            "Mottlecoat",        -- Level 89
            "Mottlescale",       -- Level 84
            "Ravenscale",        -- Level 79
            "Obsidian Skin",     -- Level 74
            "Onyx Skin",         -- Level 70
            "Natureskin",        -- Level 65
            "Skin like Nature",  -- Level 59
            "Skin like Diamond", -- Level 54
            "Skin like Steel",   -- Level 38
            "Skin like Rock",    -- Level 21
            "Skin like Wood",    -- Level 7
        },
        ['ShieldDS'] = {
            "Shield of Underbrush",    -- Level 126
            "Shield of Needlespikes",  -- Level 121
            "Shield of Shadethorns",   -- Level 116
            "Shield of Rimespurs",     -- Level 111
            "Shield of Needlebarbs",   -- Level 106
            "Shield of Nettlespears",  -- Level 101
            "Shield of Nettlespines",  -- Level 96
            "Shield of Bramblespikes", -- Level 91
            "Shield of Nettlespikes",  -- Level 86
            "Shield of Dryspines",     -- Level 81
            "Shield of Spurs",         -- Level 76
            "Shield of Needles",       -- Level 71
            "Shield of Briar",         -- Level 66
            "Shield of Thorns",        -- Level 62
            "Shield of Spikes",        -- Level 58
            "Shield of Brambles",      -- Level 43
            "Shield of Thistles",      -- Level 24
        },
        ['RegenBuff'] = {
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
        ['RunSpeedBuff'] = {
            "Spirit of Falcons",   -- Level 85
            "Spirit of Eagle",     -- Level 65
            "Pack Shrew",          -- Level 49
            "Spirit of the Shrew", -- Level 41
            "Spirit of Wolf",      -- Level 28
        },
        ['SnareSpell'] = {
            "Earthen Shackles", -- Level 69
            "Earthen Embrace",  -- Level 61
            "Ensnare",          -- Level 51
            "Snare",            -- Level 6
            "Tangling Weeds",   -- Level 5
        },
        ['JoltSpell'] = {
            "Cinder Jolt", -- Level 55
            "Jolt",        -- Level 50
        },
        ['CurePoison'] = {
            "Eradicate Poison",  -- Level 76
            "Counteract Poison", -- Level 61
            "Cure Poison",       -- Level 13
        },
        ['CureDisease'] = {
            "Eradicate Disease",  -- Level 76
            "Counteract Disease", -- Level 61
            "Cure Disease",       -- Level 22
        },
        ['Dispel'] = {
            "Nature's Entropy", -- Level 71
            "Nature's Balance", -- Level 69
            "Annul Magic",      -- Level 61
            "Nullify Magic",    -- Level 58
            "Cancel Magic",     -- Level 30
        },
    },
    ['Helpers']           = {
        DmgModActive = function(self)
            for _, aaName in ipairs({ "Guardian of the Forest", "Outrider's Accuracy", "Group Guardian of the Forest", }) do
                local aaSpell = Casting.GetAASpell(aaName)
                if aaSpell and aaSpell() and Casting.IHaveBuff(aaSpell.ID()) then return true end
            end
            for _, buffName in ipairs({ "Group Bestial Alignment", "Hunter's Fury", "Intensity of the Resolute", }) do
                if Casting.IHaveBuff(buffName) then return true end
            end
            return false
        end,
        -- Choose between combined summernuke or individual nukes once they are better
        UseIndividualNukes = function(self)
            local summer = Core.GetResolvedActionMapItem('SummerNuke')
            if not summer then return true end
            if (summer.Level() or 0) < 99 then return true end
            local fireNuke = Core.GetResolvedActionMapItem('FireNukeT4')
            return (fireNuke and fireNuke.Level() or 0) >= 128
        end,
        SingleBuffCheck = function(self)
            if Casting.CanUseAA("Wildstalker's Unity (Azia)") and not Config:GetSetting('OverwriteUnityBuffs') then return false end
            return true
        end,
        rangedNav = function(reason)
            if Config:GetSetting('DoMelee') then return false end
            if (Globals.AutoTargetID or 0) == 0 then return false end

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
                return true
            end

            if Config:GetSetting('UseRangedStick') then -- Use Ranged Stick: hold bow range with a stick.
                if reason == "toofar" or Targeting.GetTargetDistance() > bowRange + 10 then
                    if not mq.TLO.Navigation.Active() then
                        Movement:DoNav(true, "id %d distance=%d lineofsight=on", Globals.AutoTargetID, bowRange)
                        Core.DoCmd('/squelch /face fast')
                    end
                elseif (mq.TLO.Stick.StickTarget() or 0) ~= Globals.AutoTargetID or (mq.TLO.Stick.Status() or "off"):lower() == "off" then
                    Core.DoCmd('/squelch /face fast')
                    local stickDist = Config:GetSetting('StickDistance') or ""
                    if stickDist == "" then stickDist = tostring(bowRange) end
                    local stickArgs = Config:GetSetting('StickArgs') or ""
                    if stickArgs == "" then stickArgs = "moveback uw" end
                    Movement:DoStickCmd("%s id %d %s", stickDist, Globals.AutoTargetID, stickArgs)
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
            return true
        end,
        PreEngage = function(target)
            if not target or not target() then return end
            local openerAbility = Core.GetResolvedActionMapItem('Opener')

            if not Config:GetSetting('DoOpener') or not openerAbility then return end

            if not Casting.ReagentCheck(openerAbility) then return end

            Logger.log_debug("\ayPreEngage(): Testing Opener ability = %s", openerAbility or "None")

            if openerAbility() and mq.TLO.Me.PctMana() >= Config:GetSetting('ManaToNuke') and Casting.SpellReady(openerAbility) then
                Core.DoCmd("/squelch /face fast")
                Casting.UseSpell(openerAbility.RankName.Name(), target.ID(), false)
                Logger.log_debug("\agPreEngage(): Using Opener ability = %s", openerAbility or "None")
            else
                Logger.log_debug("\arPreEngage(): NOT using Opener ability = %s, Mana = %d, ManaToNuke = %d, Spell Ready = %s", openerAbility or "None",
                    mq.TLO.Me.PctMana() or 0, Config:GetSetting('ManaToNuke'), Strings.BoolToColorString(Casting.SpellReady(openerAbility)))
            end
        end,
        UnwantedAggroCheck = function(self)
            if Targeting.GetXTHaterCount() == 0 or Core.IsTanking() or mq.TLO.Group.Puller.ID() == mq.TLO.Me.ID() then return false end
            return Targeting.IHaveAggro(100)
        end,
        DefensesActive = function(self)
            return not Casting.IHaveBuff("Outrider's Evasion") and (mq.TLO.Me.ActiveDisc() or "Weapon Shield Discipline") ~= "Weapon Shield Discipline" and
                not Casting.IHaveBuff("Armor of Experience")
        end,
    },
    ['HealRotationOrder'] = {
        { -- Backup healer only; we do not compete with a real healer at the main heal point.
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function(self)
                return Config:GetSetting('DoHealSpell') or Config:GetSetting('DoBurstHeal') or Casting.CanUseAA("Convergence of Spirits")
            end,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['BigHealPoint'] = {
            {
                name = "BurstHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoBurstHeal') end,
            },
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "HealSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealSpell') end,
            },
        },
    },
    ['RotationOrder']     = {
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
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
            name = 'Emergency',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99))
            end,
        },
        {
            name = 'Aggro Management',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctAggro() > Config:GetSetting('JoltAggro')
            end,
        },
        {
            name = 'Debuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and not Globals.AutoTargetIsNamed and
                    Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        {
            name = 'Dispel',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoDispel') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        { -- Combat abilities used to fill the global cooldown while spells are casting.
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Ranged Positioning',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Config:GetSetting('DoMelee')
            end,
        },
    },
    ['Rotations']         = {
        ['Downtime'] = {
            {
                name = "EndRegen",
                type = "Disc",
                load_cond = function(self) return not Core.GetResolvedActionMapItem("CombatEndRegen") end,
                active_cond = function(self, discSpell) return Casting.IHaveBuff(discSpell) end,
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "CombatEndRegen",
                type = "Disc",
                active_cond = function(self, discSpell) return Casting.IHaveBuff(discSpell) end,
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Wildstalker's Unity (Beza)",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UnityProcChoice') == 1 end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID() or 0) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Wildstalker's Unity (Azia)",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UnityProcChoice') == 2 end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID() or 0) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "ProtectionBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck(self) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Eyes",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck(self) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Hunt",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck(self) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "CoatDS",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck(self) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "MeleeProcBuff",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('UnityProcChoice') == 1 or not Core.GetResolvedActionMapItem('HateProcBuff')
                end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck(self) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "HateProcBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('UnityProcChoice') == 2 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck(self) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Mask",
                type = "Spell",
                load_cond = function(self)
                    local eyes = Core.GetResolvedActionMapItem('Eyes')
                    return (eyes and eyes.Level() or 0) < 74
                end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "BurningCloak",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Veil",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "ShieldDS",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "JoltProcBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoJoltProc') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return not Core.IsTanking() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SnareProcBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSnareProc') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Poison Arrows",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(Casting.GetAASpell(aaName)) end,
                cond = function(self, aaName)
                    if Config:GetSetting('ArrowProcChoice') ~= 1 then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Flaming Arrows",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(Casting.GetAASpell(aaName)) end,
                cond = function(self, aaName)
                    local choice = Config:GetSetting('ArrowProcChoice')
                    if choice == 3 or (choice == 1 and Casting.CanUseAA("Poison Arrows")) then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Chameleon's Gift",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(Casting.GetAASpell(aaName)) end,
                cond = function(self, aaName) return not Core.IsTanking() and Casting.SelfBuffAACheck(aaName) end,
            },
        },
        ['GroupBuff'] = {
            { -- From Level 100 this delivers SingleCloakDS, PredatorBuff and StrengthBuff to the whole group.
                name = "ShoutBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell.Trigger(1)) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "PredatorBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('ShoutBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "StrengthBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('ShoutBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupCloakDS",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('ShoutBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleCloakDS",
                type = "Spell",
                load_cond = function(self)
                    return not Core.GetResolvedActionMapItem('ShoutBuff') and not Core.GetResolvedActionMapItem('GroupCloakDS')
                end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupEnrichmentBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HPTypeOne",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHPBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "RegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegen') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Spirit of Eagles",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(Casting.GetAASpell(aaName)) end,
                cond = function(self, aaName, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') and not Casting.CanUseAA("Spirit of Eagles") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Cover Tracks",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoCoverTracks') and Casting.CanUseAA("Cover Tracks") end,
                cond = function(self, aaName)
                    return self.Helpers.UnwantedAggroCheck(self)
                end,
            },
            {
                name = "Protection of the Spirit Wolf",
                type = "AA",
            },
            {
                name = "Bulwark of the Brownies",
                type = "AA",
            },
            {
                name = "Outrider's Evasion",
                type = "AA",
                cond = function(self, aaName, target)
                    return not self.Helpers.DefensesActive()
                end,
            },
            {
                name = "WeaponShield",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return not self.Helpers.DefensesActive() and Casting.NoDiscActive()
                end,
            },
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 35 and not self.Helpers.DefensesActive()
                end,
            },
        },
        ['Aggro Management'] = {
            {
                name = "Silent Strikes",
                type = "AA",
            },
            {
                name = "JoltSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoJoltSpell') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
        ['Debuff'] = {
            {
                name = "Elemental Arrow",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Dispel'] = {
            {
                name = "Entropy of Nature",
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
            {
                name = "Dispel",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Entropy of Nature") end,
                cond = function(self, spell, target)
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Auspice of the Hunter",
                type = "AA",
                pre_activate = function(self)
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
                end,
            },
            {
                name = "ArcheryDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Config:GetSetting('DoMelee') and Casting.NoDiscActive()
                end,
            },
            {
                name = "MeleeDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Config:GetSetting('DoMelee') and Casting.NoDiscActive()
                end,
            },
            {
                name = "Scarlet Cheetah's Fang",
                type = "AA",
            },
            {
                name = "Outrider's Accuracy",
                type = "AA",
                mustWait = true,
                cond = function(self, aaName, target)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Spire of the Pathfinders",
                type = "AA",
            },
            {
                name = "Imbued Ferocity",
                type = "AA",
            },
            {
                name = "Guardian of the Forest",
                type = "AA",
                mustWait = true,
                cond = function(self, aaName, target)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Group Guardian of the Forest",
                type = "AA",
                mustWait = true,
                cond = function(self, aaName, target)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Empowered Blades",
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "Pack Hunt",
                type = "AA",
            },
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    return Config:GetSetting('DoEpic') and Config:GetSetting('DoMelee')
                end,
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoChestClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['DPS'] = {
            {
                name = "CalledShotsArrow",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "AEArrowsSplash",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('AEArrowChoice') == 2 and Core.GetResolvedActionMapItem('AEArrowsSplash')
                end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Casting.OkayToNuke() and Combat.AETargetCheck(true)
                end,
            },
            {
                name = "AEArrowsCone",
                type = "Spell",
                load_cond = function(self)
                    if Config:GetSetting('AEArrowChoice') == 1 then return false end
                    return Config:GetSetting('AEArrowChoice') == 3 or not Core.GetResolvedActionMapItem('AEArrowsSplash')
                end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Casting.OkayToNuke() and Combat.AETargetCheck(true)
                end,
            },
            {
                name = "FocusedArrows",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "DichoSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FireNukeT4",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UseIndividualNukes(self) end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FireNukeT1",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UseIndividualNukes(self) end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ColdNukeT3",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UseIndividualNukes(self) end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ColdNukeT2",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UseIndividualNukes(self) end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "SwarmDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSwarmDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell, target) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "ShortSwarmDot",
                type = "Spell",
                load_cond = function(self)
                    local dsDot = Core.GetResolvedActionMapItem('ShortSwarmDot')
                    return Config:GetSetting('DoSwarmDot') and dsDot and (dsDot.Level() or 0) >= 128
                end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell, target) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "SummerNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Heartshot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHeartshot') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke() and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "Alliance",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAlliance') end,
                cond = function(self, spell, target)
                    return Casting.CanAlliance() and not Casting.TargetHasBuff(spell, target)
                end,
            },
        },
        ['Weaves'] = {
            {
                name = "ReflexStrike",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Targeting.GroupHealsNeeded() and Targeting.InSpellRange(discSpell, target)
                end,
            },
            {
                name = "CombatEndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "AEBlades",
                type = "Disc",
                cond = function(self, discSpell, target)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Targeting.InSpellRange(discSpell, target) and Combat.AETargetCheck(true)
                end,
            },
            {
                name = "FocusedBlades",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Targeting.InSpellRange(discSpell, target)
                end,
            },
            {
                name = "JoltingKicks",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Targeting.InSpellRange(discSpell, target)
                end,
            },
            {
                name = "Kick",
                type = "Ability",
            },
        },
        ['Ranged Positioning'] = {
            {
                name = "Ranged Nav",
                type = "CustomFunc",
                custom_func = function(self)
                    return Core.SafeCallFunc("Ranger Ranged Nav", self.Helpers.rangedNav)
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Default",
            spells = {
                -- Heals
                { name = "BurstHeal",        cond = function(self) return Config:GetSetting('DoBurstHeal') end, },
                { name = "HealSpell",        cond = function(self) return Config:GetSetting('DoHealSpell') end, },
                -- Cures
                { name = "Balm",             cond = function(self) return Config:GetSetting('MemBalm') end, },
                { name = "CurePoison",       cond = function(self) return Config:GetSetting('MemPoisonCure') and not Core.GetResolvedActionMapItem('Balm') end, },
                { name = "CureDisease",      cond = function(self) return Config:GetSetting('MemDiseaseCure') and not Core.GetResolvedActionMapItem('Balm') end, },
                -- Debuffs
                { name = "SnareSpell",       cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Entrap") end, },
                { name = "Dispel",           cond = function(self) return Config:GetSetting('DoDispel') and not Casting.CanUseAA("Entropy of Nature") end, },
                { name = "JoltSpell",        cond = function(self) return Config:GetSetting('DoJoltSpell') end, },
                -- Damage
                { name = "CalledShotsArrow", },
                { name = "FocusedArrows", },
                { name = "DichoSpell", },
                { name = "FireNukeT4",       cond = function(self) return self.Helpers.UseIndividualNukes(self) end, },
                { name = "FireNukeT1",       cond = function(self) return self.Helpers.UseIndividualNukes(self) end, },
                { name = "ColdNukeT3",       cond = function(self) return self.Helpers.UseIndividualNukes(self) end, },
                { name = "ColdNukeT2",       cond = function(self) return self.Helpers.UseIndividualNukes(self) end, },
                { name = "SwarmDot",         cond = function(self) return Config:GetSetting('DoSwarmDot') end, },
                {
                    name = "ShortSwarmDot",
                    cond = function(self)
                        local shortDot = Core.GetResolvedActionMapItem('ShortSwarmDot')
                        return Config:GetSetting('DoSwarmDot') and shortDot and (shortDot.Level() or 0) >= 128
                    end,
                },
                { name = "SummerNuke", },
                {
                    name = "AEArrowsSplash",
                    cond = function(self)
                        return Config:GetSetting('AEArrowChoice') == 2 and Core.GetResolvedActionMapItem('AEArrowsSplash')
                    end,
                },
                {
                    name = "AEArrowsCone",
                    cond = function(self)
                        if Config:GetSetting('AEArrowChoice') == 1 then return false end
                        return Config:GetSetting('AEArrowChoice') == 3 or not Core.GetResolvedActionMapItem('AEArrowsSplash')
                    end,
                },
                { name = "Opener",        cond = function(self) return Config:GetSetting('DoOpener') end, },
                { name = "Heartshot",     cond = function(self) return Config:GetSetting('DoHeartshot') end, },
                { name = "Alliance",      cond = function(self) return Config:GetSetting('DoAlliance') end, },
                -- Filler
                { name = "BurningCloak", },
                { name = "Veil", },
                { name = "JoltProcBuff",  cond = function(self) return Config:GetSetting('DoJoltProc') end, },
                { name = "SnareProcBuff", cond = function(self) return Config:GetSetting('DoSnareProc') end, },
            },
        },
    },
    ['PullAbilities']     = {
        {
            id = 'Opener',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Opener').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Opener').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                if not Config:GetSetting('DoOpener') then return false end
                local resolvedSpell = Core.GetResolvedActionMapItem('Opener')
                if not resolvedSpell then return false end
                if not Casting.ReagentCheck(resolvedSpell) then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'SnareSpell',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('SnareSpell').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('SnareSpell').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('SnareSpell')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Entrap',
            Type = "AA",
            DisplayName = function() return "Entrap" end,
            AbilityName = function() return "Entrap" end,
            AbilityRange = 200,
            cond = function(self) return Casting.CanUseAA("Entrap") end,
        },
    },
    ['DefaultConfig']     = {
        ['Mode']                = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Rangers currently only have one Mode. Melee and archery are governed by the Enable Melee Combat setting.",
        },

        --Archery / Positioning
        ['BowRange']            = {
            DisplayName = "Bow Range",
            Group = "Combat",
            Header = "Positioning",
            Category = "Archery",
            Index = 101,
            Tooltip = "The preferred distance to reposition to if we are too close/far or have no LoS (also the default range for ranged stick).",
            Default = 40,
            Min = 31,
            Max = 300,
        },
        ['UseRangedStick']      = {
            DisplayName = "Use Ranged Stick",
            Group = "Combat",
            Header = "Positioning",
            Category = "Archery",
            Index = 102,
            Tooltip = "Disabled - autofire from present position, moving only if needed (too close/far, no LoS).\n" ..
                "Enabled - use stick while autofiring.",
            Default = false,
            Warning = function()
                if not Config:GetSetting('UseRangedStick') then return false, "" end
                local bowRange = Config:GetSetting('BowRange')
                if Config:GetSetting('ChaseOn') then
                    if Config:GetSetting('ChaseDistance') < bowRange then
                        return true, "Warning: Chase Distance is below Bow Range - chase may fight the ranged stick hold."
                    end
                elseif Config:GetSetting('ReturnToCamp') and Config:GetSetting('CampLeashCombat') and Config:GetSetting('AutoCampRadius') < bowRange then
                    return true, "Warning: Camp Radius is below Bow Range - Leash to Camp (Combat) may fight the ranged stick hold."
                end
                return false, ""
            end,
        },

        --Damage
        ['DoSwarmDot']          = {
            DisplayName = "Use Swarm Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Swarm line of DoTs.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DotNamedOnly']        = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
        },
        ['AEArrowChoice']       = {
            DisplayName = "AE Arrow Type:",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "Choose which AE 'of Arrows' spell line is used when we have enough valid AE Targets.",
            Type = "Combo",
            ComboOptions = { 'Disabled', 'Targeted AE (Splash)', 'Frontal Cone', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoOpener']            = {
            DisplayName = "Use Openers",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your out-of-combat opening shot. Consumes a CLASS 3 Wood Silver Tip Arrow (item 8658) per cast.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoHeartshot']         = {
            DisplayName = "Use Heart Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your Heart line of arrow nukes. Consumes a CLASS 3 Wood Silver Tip Arrow (item 8658) per cast.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoEpic']              = {
            DisplayName = "Do Epic",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your epic during burns.",
            Default = true,
        },
        ['DoChestClick']        = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your chest item during burns.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },

        --Buffs
        ['UnityProcChoice']     = {
            DisplayName = "Unity/Proc Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Wildstalker's Unity casts the same buffs either way apart from the weapon proc.\n" ..
                "Beza grants Sparking Blades. Azia grants Devastating Blades, which also increases hate.",
            Type = "Combo",
            ComboOptions = { 'Beza: Sparking Blades', 'Azia: Devastating Blades (adds hate)', },
            Default = 1,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
        },
        ['OverwriteUnityBuffs'] = {
            DisplayName = "Overwrite Unity Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Cast the individual buffs even when Wildstalker's Unity already covers them.",
            Default = false,
            ConfigType = "Advanced",
        },
        ['ArrowProcChoice']     = {
            DisplayName = "Arrow Proc:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 103,
            Tooltip = "Poison and Flaming Arrows share an AA timer, so only one can be active.",
            Type = "Combo",
            ComboOptions = { 'Poison Arrows', 'Flaming Arrows', 'Disabled', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoJoltProc']          = {
            DisplayName = "Cast Hate Reduction Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 104,
            Tooltip = "Use your Jolting line of hate reduction proc buffs.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoSnareProc']         = {
            DisplayName = "Cast Snare Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 105,
            Tooltip = "Keep Grasping Nettlecoat up to snare anything that melees you.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoVetAA']             = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 106,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoHPBuff']            = {
            DisplayName = "Cast HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Use your Skin/Coat HP buff line.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoRegen']             = {
            DisplayName = "Cast Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Use your Vigor regeneration line.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoRunSpeed']          = {
            DisplayName = "Cast Run Speed Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your movement speed spells and AA.",
            Default = true,
            RequiresLoadoutChange = true,
        },

        --Recovery
        ['DoBurstHeal']         = {
            DisplayName = "Do Burst Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your instant burst heal at the big heal point.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoHealSpell']         = {
            DisplayName = "Do Standard Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Mem and cast your standard heal at the big heal point.",
            Default = mq.TLO.Me.Level() < 89,
            RequiresLoadoutChange = true,
        },
        ['MemBalm']             = {
            DisplayName = "Mem Balm",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Keep your Balm cure gemmed so it can be used in combat.\n" ..
                "With this off, Balm is still used during downtime if Do Cures is enabled.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['MemPoisonCure']       = {
            DisplayName = "Mem Poison Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Keep a single poison cure gemmed. Ignored once Balm is available, as Balm cures poison itself.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['MemDiseaseCure']      = {
            DisplayName = "Mem Disease Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 103,
            Tooltip = "Keep a single disease cure gemmed. Ignored once Balm is available, as Balm cures disease itself.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['HealPriority']        = {
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

        --Utility
        ['DoSnare']             = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare (the spell is used until the Entrap AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']          = {
            DisplayName = "Snare Max Mob Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 102,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro.",
            Default = 3,
            Min = 1,
            Max = 99,
        },
        ['DoDispel']            = {
            DisplayName = "Use Dispel",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Dispel",
            Index = 101,
            Tooltip = "Strip beneficial effects from your target. The spell line is used until the Entropy of Nature AA is available.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['EmergencyStart']      = {
            DisplayName = "Emergency HP%",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Your HP % before we begin to use emergency mitigation abilities.",
            Default = 50,
            Min = 1,
            Max = 100,
        },
        ['JoltAggro']           = {
            DisplayName = "Aggro Shed %",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 101,
            Tooltip = "Begin using hate reduction abilities above this aggro percentage.",
            Default = 70,
            Min = 1,
            Max = 100,
        },
        ['DoJoltSpell']         = {
            DisplayName = "Use Jolt Spell",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 102,
            Tooltip = "Cast your Jolt line to shed a flat amount of hate. The amount does not scale, so it is mainly useful at lower levels.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoCoverTracks']       = {
            DisplayName = "Use Cover Tracks",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use Cover Tracks to escape combat in an emergency.",
            Default = false,
            RequiresLoadoutChange = true,
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release aimed at official servers.\n\n" ..
                "  This config should perform well from from start to endgame, but a TLP or emu player may find it to be lacking exact customization for a specific era.\n\n" ..
                "  Additionally, those wishing more fine-tune control for specific encounters or raids should customize this config to their preference. \n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
