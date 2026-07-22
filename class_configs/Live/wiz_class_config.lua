-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

local mq        = require('mq')
local Casting   = require("utils.casting")
local Combat    = require("utils.combat")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Modules   = require("utils.modules")
local Targeting = require("utils.targeting")

return {
    _version          = "2.1 - Live",
    _author           = "Derple, Algar",
    ['Modes']         = {
        'DPS',
    },
    ['OnModeChange']  = function(self, mode)
    end,
    ['Themes']        = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.02, g = 0.12, b = 0.24, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.02, g = 0.12, b = 0.24, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.05, g = 0.30, b = 0.60, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.03, g = 0.19, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.05, g = 0.30, b = 0.60, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.02, g = 0.12, b = 0.24, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.65, g = 0.92, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.65, g = 0.92, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Staff of Phenomenal Power",
            "Staff of Prismatic Power",
        },
    },
    ['AbilitySets']   = {
        ['AllianceSpell'] = {
            "Frostbound Covariance",  -- Level 122
            "Frostbound Conjunction", -- Level 117
            "Frostbound Coalition",   -- Level 112
            "Frostbound Covenant",    -- Level 107
            "Frostbound Alliance",    -- Level 102
        },
        -- ['DichoSpell'] = {
        --     "Reciprocal Fire", -- Level 121
        --     "Ecliptic Fire",   -- Level 116
        --     "Composite Fire",  -- Level 111
        --     "Dissident Fire",  -- Level 106
        --     "Dichotomic Fire", -- Level 101
        -- },
        ['IceClaw'] = {
            "Claw of Tsikut",        -- Level 130
            "Claw of Ankexfen",      -- Level 125
            "Claw of the Void",      -- Level 120
            "Claw of Gozzrem",       -- Level 115
            "Claw of Travenro",      -- Level 110
            "Claw of the Oceanlord", -- Level 105
            "Claw of the Icewing",   -- Level 100
            "Claw of the Abyss",     -- Level 95
            "Glacial Claw",          -- Level 90
            "Claw of Selig",         -- Level 80
            "Claw of Selay",         -- Level 75
            "Claw of Vox",           -- Level 69
            "Claw of Frost",         -- Level 61
        },
        ['FireClaw'] = {
            "Claw of Ashenback",       -- Level 128
            "Claw of Ingot",           -- Level 123
            "Claw of the Duskflame",   -- Level 118
            "Claw of Sontalak",        -- Level 113
            "Claw of Qunard",          -- Level 108
            "Claw of the Flameweaver", -- Level 103
            "Claw of the Flamewing",   -- Level 98
            "Villification of Havoc",  -- Level 94, 54s recast but same timer and purpose.
            "Denunciation of Havoc",   -- Level 89
            "Malediction of Havoc",    -- Level 84
        },
        ['MagicClaw'] = {
            "Claw of Windshear",        -- Level 126
            "Claw of the Battleforged", -- Level 121
            "Claw of Itzal",            -- Level 116
            "Claw of Feshlak",          -- Level 111
            "Claw of Ellarr",           -- Level 106
            "Claw of the Indagatori",   -- Level 101
            "Claw of the Ashwing",      -- Level 96
        },
        ['CloudburstNuke'] = {
            "Cloudburst Strike XII",      -- Level 127
            "Cloudburst Lightningstrike", -- Level 122
            "Cloudburst Joltstrike",      -- Level 117
            "Cloudburst Stormbolt",       -- Level 112
            "56794",                      -- Level 107, Cloudburst Thunderbolt - deconflicts duplicate at Level 97
            "Cloudburst Stormstrike",     -- Level 102
            "35876",                      -- Level 97, Cloudburst Thunderbolt - deconflicts duplicate at Level 107
            "Cloudburst Tempest",         -- Level 92
            "Cloudburst Storm",           -- Level 87
            "Cloudburst Levin",           -- Level 82
            "Cloudburst Bolts",           -- Level 77
            "Cloudburst Strike",          -- Level 72
        },
        ['FuseNuke'] = {
            "Ethereal Weave VII",  -- Level 130
            "Ethereal Plait",      -- Level 125
            "Ethereal Twist",      -- Level 120
            "Ethereal Confluence", -- Level 115
            "Ethereal Braid",      -- Level 110
            "Ethereal Fuse",       -- Level 105
            "Ethereal Weave",      -- Level 100
        },
        ['FireEtherealNuke'] = {
            "Ethereal Fire XIII",     -- Level 130
            "Ethereal Immolation",    -- Level 125
            "Ethereal Ignition",      -- Level 120
            "Ethereal Brand",         -- Level 115
            "Ethereal Skyfire",       -- Level 110
            "Ethereal Skyblaze",      -- Level 105
            "Ethereal Incandescence", -- Level 100
            "Ethereal Blaze",         -- Level 95
            "Ethereal Inferno",       -- Level 90
            "Ethereal Combustion",    -- Level 85
            "Ethereal Incineration",  -- Level 80
            "Ethereal Conflagration", -- Level 75
            "Ether Flame",            -- Level 70
        },
        ['IceEtherealNuke'] = {
            "Ethereal Ice XI",     -- Level 129
            "Ethereal Freeze",     -- Level 124
            "Lunar Ice Comet",     -- Level 119
            "Restless Ice Comet",  -- Level 114
            "Ethereal Icefloe",    -- Level 109
            "Ethereal Rimeblast",  -- Level 104
            "Ethereal Hoarfrost",  -- Level 99
            "Ethereal Frost",      -- Level 94
            "Ethereal Glaciation", -- Level 89
            "Ethereal Iceblight",  -- Level 84
            "Ethereal Rime",       -- Level 79
        },
        ['MagicEtherealNuke'] = {
            "Ethereal Barrage VIII", -- Level 127
            "Ethereal Blitz",        -- Level 122
            "Ethereal Mortar",       -- Level 117
            "Ethereal Blast",        -- Level 112
            "Ethereal Volley",       -- Level 107
            "Ethereal Flash",        -- Level 102
            "Ethereal Salvo",        -- Level 97
            "Ethereal Barrage",      -- Level 92
        },
        ['ChaosNuke'] = {
            "Chaos Flame XIII",    -- Level 128
            "Chaos Inferno",       -- Level 113
            "Chaos Burn",          -- Level 108
            "Chaos Scintillation", -- Level 103
            "Chaos Incandescence", -- Level 99
            "Chaos Blaze",         -- Level 94
            "Chaos Char",          -- Level 89
            "Chaos Combustion",    -- Level 84
            "Chaos Conflagration", -- Level 79
            "Chaos Immolation",    -- Level 74
            "Chaos Flame",         -- Level 70
        },
        ['VortexNuke'] = {
            -- NOTE: ${Spell[${VortexNuke}].ResistType} can be used to determine which resist type is getting debuffed
            "Chromospheric Vortex", -- Level 123
            "Shadebright Vortex",   -- Level 118
            "Thaumaturgic Vortex",  -- Level 113
            "Stormjolt Vortex",     -- Level 108
            "Shocking Vortex",      -- Level 103
            -- Hoarfrost Vortex has a Fire Debuff
            -- "Hoarfrost Vortex",     -- Level 100
            -- Ether Vortex has a Cold Debuff
            -- "Ether Vortex",         -- Level 98
            -- Incandescent Vortex has a Magic Debuff
            -- "Incandescent Vortex",  -- Level 96
            -- Frost Vortex has a Fire Debuff
            -- "Frost Vortex",         -- Level 95
            -- Power Vortex has a Cold Debuff
            -- "Power Vortex",         -- Level 93
            -- Flame Vortex has a Magic Debuff
            -- "Flame Vortex",         -- Level 91
            -- Ice Vortex has a Fire Debuff
            -- "Ice Vortex",           -- Level 90
            -- Mana Vortex has a Cold Debuff
            -- "Mana Vortex",          -- Level 88
            -- Fire Vortex has a Magic Debuff
            -- "Fire Vortex",          -- Level 86
        },
        ['WildNuke'] = {
            "Wildmagic Strike XII", -- Level 126
            "Wildspell Strike",     -- Level 121
            "Wildflame Strike",     -- Level 116
            "Wildscorch Strike",    -- Level 111
            "Wildflash Strike",     -- Level 106
            "Wildflash Barrage",    -- Level 101
            "Wildether Barrage",    -- Level 96
            "Wildspark Barrage",    -- Level 91
            "Wildmana Barrage",     -- Level 86
            "Wildmagic Blast",      -- Level 81
            "Wildmagic Burst",      -- Level 76
            "Wildmagic Strike",     -- Level 71
        },
        ['WildNuke2'] = {
            "Wildmagic Strike XII", -- Level 126
            "Wildspell Strike",     -- Level 121
            "Wildflame Strike",     -- Level 116
            "Wildscorch Strike",    -- Level 111
            "Wildflash Strike",     -- Level 106
            "Wildflash Barrage",    -- Level 101
            "Wildether Barrage",    -- Level 96
            "Wildspark Barrage",    -- Level 91
            "Wildmana Barrage",     -- Level 86
            "Wildmagic Blast",      -- Level 81
            "Wildmagic Burst",      -- Level 76
            "Wildmagic Strike",     -- Level 71
        },
        ['FireNuke'] = {
            "Teknaz's Fire",                 -- Level 130
            "Kindleheart's Fire",            -- Level 125
            "The Diabo's Fire",              -- Level 120
            "Dagarn's Fire",                 -- Level 115
            "Dragoflux's Fire",              -- Level 110
            "Narendi's Fire",                -- Level 105
            "Gosik's Fire",                  -- Level 100
            "Daevan's Fire",                 -- Level 95
            "Lithara's Fire",                -- Level 90
            "Klixcxyk's Fire",               -- Level 85
            "Inizen's Fire",                 -- Level 80
            "Sothgar's Flame",               -- Level 75
            --Not used above this
            "Spark of Fire",                 -- Level 66
            "Draught of Ro",                 -- Level 62
            "Draught of Fire",               -- Level 51
            "Conflagration",                 -- Level 43
            "Inferno Shock",                 -- Level 26
            "Flame Shock",                   -- Level 15
            "Fire Bolt",                     -- Level 5
            "Shock of Fire",                 -- Level 4
        },
        ['BigFireNuke'] = {                  -- Level 51-70, Long Cast, Heavy Damage
            "Ancient: Core Fire",            -- Level 70
            "Corona Flare",                  -- Level 70
            "Ancient: Strike of Chaos",      -- Level 65
            "White Fire",                    -- Level 65
            "Strike of Solusek",             -- Level 65
            "Garrison's Superior Sundering", -- Level 60
            "Sunstrike",                     -- Level 60
        },
        ['IceNuke'] = {
            "Glacial Cascade XII",         -- Level 129
            "Glacial Ice Cascade",         -- Level 124
            "Tundra Ice Cascade",          -- Level 119
            "Restless Ice Cascade",        -- Level 114
            "Icefloe Cascade",             -- Level 109
            "Rimeblast Cascade",           -- Level 104
            "Hoarfrost Cascade",           -- Level 99
            "Rime Cascade",                -- Level 94
            "Glacial Cascade",             -- Level 89
            "Icesheet Cascade",            -- Level 84
            "Glacial Collapse",            -- Level 79
            "Icefall Avalanche",           -- Level 74
            "Spark of Ice",                -- Level 69
            "Black Ice",                   -- Level 65
            "Draught of E`ci",             -- Level 64
            "Draught of Ice",              -- Level 57
            "Ice Comet",                   -- Level 49
            "Ice Shock",                   -- Level 34
            "Frost Shock",                 -- Level 24
            "Shock of Ice",                -- Level 8
            "Blast of Cold",               -- Level 1
        },
        ['BigIceNuke'] = {                 -- Level 60-70, Timed with great Ratio or High Cast Time/Damage
            "Gelidin Comet",               -- Level 69
            "Ice Meteor",                  -- Level 64
            "Ancient: Destruction of Ice", -- Level 60, 13s T1
            "Ice Spear of Solist",         -- Level 60, 13s T2
        },
        ['MagicNuke'] = {
            "Lightning Helix XII",           -- Level 128
            "Lightning Cyclone",             -- Level 123
            "Lightning Maelstrom",           -- Level 118
            "Lightning Roar",                -- Level 113
            "Lightning Tempest",             -- Level 108
            "44623",                         -- Level 103, Lightning Storm - deconflicts duplicate at Level 23
            "Lightning Squall",              -- Level 98
            "Lightning Swarm",               -- Level 93
            "Lightning Helix",               -- Level 88
            "Ribbon Lightning",              -- Level 83
            "Rolling Lightning",             -- Level 78
            "Ball Lightning",                -- Level 73
            "Spark of Lightning",            -- Level 68
            "Draught of Lightning",          -- Level 63
            "Voltaic Draught",               -- Level 54
            "Rend",                          -- Level 47
            "Lightning Shock",               -- Level 37
            "Garrison's Mighty Mana Shock",  -- Level 18
            "Shock of Lightning",            -- Level 10
        },
        ['BigMagicNuke'] = {                 -- Level 60-68, High Cast Time/Damage
            "Thundaka",                      -- Level 68
            "Shock of Magic",                -- Level 65
            "Agnarr's Thunder",              -- Level 63
            "Elnerick's Electrical Rending", -- Level 60
        },
        ['StunSpell'] = {
            "Telaka XIX",       -- Level 130
            "Teladaka",         -- Level 125
            "Teladaja",         -- Level 120
            "Telajaga",         -- Level 115
            "Telanata",         -- Level 110
            "Telanara",         -- Level 105
            "Telanaga",         -- Level 100
            "Telanama",         -- Level 95
            "Telakama",         -- Level 90
            "Telajara",         -- Level 85
            "Telajasz",         -- Level 80
            "Telakisz",         -- Level 75
            "Telekara",         -- Level 70
            "Telaka",           -- Level 65
            "Telekin",          -- Level 64
            "Markar's Discord", -- Level 56
            "Markar's Clash",   -- Level 47
            "Tishan's Clash",   -- Level 19
        },
        ['SelfHPBuff'] = {
            "Shielding XXIII",            -- Level 126
            "Shield of Memories",         -- Level 121
            "Shield of Shadow",           -- Level 116
            "Shield of Restless Ice",     -- Level 111
            "Shield of Scales",           -- Level 106
            "Shield of the Pellarus",     -- Level 101
            "Shield of the Dauntless",    -- Level 96
            "Shield of Bronze",           -- Level 91
            "Shield of Dreams",           -- Level 86
            "Shield of the Void",         -- Level 81
            "Bulwark of the Crystalwing", -- Level 76
            "Shield of the Crystalwing",  -- Level 71
            "Ether Shield",               -- Level 66
            "Shield of Maelin",           -- Level 64
            "Shield of the Arcane",       -- Level 61
            "Shield of the Magi",         -- Level 54
            "Arch Shielding",             -- Level 44
            "Greater Shielding",          -- Level 33
            "Major Shielding",            -- Level 23
            "Shielding",                  -- Level 15
            "Lesser Shielding",           -- Level 6
            "Minor Shielding",            -- Level 1
        },
        ['SelfSpellShield1'] = {
            "Shield of Fate VII",       -- Level 127
            "Shield of Inescapability", -- Level 122
            "Shield of Inevitability",  -- Level 117
            "Shield of Destiny",        -- Level 112
            "Shield of Order",          -- Level 107
            "Shield of Consequence",    -- Level 102
            "Shield of Fate",           -- Level 97
        },
        ['FamiliarBuff'] = {
            "Greater Familiar", -- Level 60
            "Familiar",         -- Level 54
            "Lesser Familiar",  -- Level 45
            "Minor Familiar",   -- Level 25
        },
        ['SelfRune1'] = {
            "Aegis of Feish",             -- Level 126
            "Aegis of Remembrance",       -- Level 121
            "63576",                      -- Level 118, Scales of the Crystalwing - deconflicts duplicate at Level 73
            "Aegis of the Umbra",         -- Level 116
            "Aegis of the Crystalwing",   -- Level 113
            "Armor of Wirn",              -- Level 108
            "Armor of the Codex",         -- Level 103
            "Armor of the Stonescale",    -- Level 98
            "Armor of the Crystalwing",   -- Level 93
            "Dermis of the Crystalwing",  -- Level 88
            "Squamae of the Crystalwing", -- Level 83
            "Laminae of the Crystalwing", -- Level 78
            "10810",                      -- Level 73, Scales of the Crystalwing - deconflicts duplicate at Level 118
            "Ether Skin",                 -- Level 68
            "Force Shield",               -- Level 63
        },
        ['Dispel'] = {
            "Annul Magic",   -- Level 53
            "Nullify Magic", -- Level 34
            "Cancel Magic",  -- Level 11
        },
        ['TwincastSpell'] = {
            "Twincast", -- Level 85
        },
        ['GambitSpell'] = {
            "Contemplative Gambit", -- Level 125
            "Anodyne Gambit",       -- Level 120
            "Idyllic Gambit",       -- Level 115
            "Musing Gambit",        -- Level 110
            "Quiescent Gambit",     -- Level 104
            "Bucolic Gambit",       -- Level 99
        },
        ['PetSpell'] = {
            "Kindleheart's Pyroblade",  -- Level 124
            "Diabo Xi Fer's Pyroblade", -- Level 119
            "Ricartine's Pyroblade",    -- Level 114
            "Virnax's Pyroblade",       -- Level 109
            "Yulin's Pyroblade",        -- Level 104
            "Mul's Pyroblade",          -- Level 99
            "Burnmaster's Pyroblade",   -- Level 94
            "Lithara's Pyroblade",      -- Level 89
            "Daveron's Pyroblade",      -- Level 84
            "Euthanos' Flameblade",     -- Level 79
            "Ethantis's Burning Blade", -- Level 74
            "Solist's Frozen Sword",    -- Level 69
            "Flaming Sword of Xuzl",    -- Level 59
        },
        ['RootSpell'] = {
            "Greater Fetter",   -- Level 61
            "Fetter",           -- Level 58
            "Paralyzing Earth", -- Level 48
            "Immobilize",       -- Level 39
            "Instill",          -- Level 17
            "Root",             -- Level 3
        },
        ['SnareSpell'] = {
            "Atol's Concussive Shackles", -- Level 93
            "Atol's Spectral Shackles",   -- Level 51
            "Bonds of Force",             -- Level 27
        },
        ['EvacSpell'] = {
            "Evacuate",        -- Level 57
            "Lesser Evacuate", -- Level 18
        },
        ['HarvestSpell'] = {
            "Harvest XIII",          -- Level 127
            "Contemplative Harvest", -- Level 122
            "Shadow Harvest",        -- Level 117
            "Quiet Harvest",         -- Level 112
            "Musing Harvest",        -- Level 107
            "Quiescent Harvest",     -- Level 102
            "Bucolic Harvest",       -- Level 97
            "Placid Harvest",        -- Level 92
            "Soothing Harvest",      -- Level 87
            "Serene Harvest",        -- Level 82
            "Tranquil Harvest",      -- Level 77
            "Patient Harvest",       -- Level 72
            "Harvest",               -- Level 32
        },
        ['JoltSpell'] = {
            "Mindfreeze X",                -- Level 127
            "Spinalfreeze",                -- Level 122
            "67443",                       -- Level 121, Concussive Blast - deconflicts duplicate at Level 71
            "Cerebrumfreeze",              -- Level 117
            "Neurofreeze",                 -- Level 112
            "Cortexfreeze",                -- Level 107
            "Synapsefreeze",               -- Level 102
            "Skullfreeze",                 -- Level 97
            "Thoughtfreeze",               -- Level 92
            "Brainfreeze",                 -- Level 87
            "26523",                       -- Level 86, Concussive Burst - deconflicts duplicate at Level 76
            "Mindfreeze",                  -- Level 82
            "Concussive Flash",            -- Level 81
            "15393",                       -- Level 76, Concussive Burst - deconflicts duplicate at Level 86
            "10782",                       -- Level 71, Concussive Blast - deconflicts duplicate at Level 121
            "Ancient: Greater Concussion", -- Level 60
            "Concussion",                  -- Level 37
        },
        -- Lure Spells
        ['IceLureNuke'] = {
            "Lure of Winter Memories", -- Level 121
            "Lure of the Cold Moon",   -- Level 116
            "Lure of Restless Ice",    -- Level 111
            "Lure of Travenro",        -- Level 106
            "Lure of the Depths",      -- Level 101
            "Lure of the Wastes",      -- Level 96
            "Frigid Lure",             -- Level 91
            "Glacial Lure",            -- Level 86
            "Voidfrost Lure",          -- Level 81
            "Lure of Isaz",            -- Level 76
            "Rimelure",                -- Level 71
            "Icebane",                 -- Level 66
            "Lure of Ice",             -- Level 60
            "Lure of Frost",           -- Level 52
        },
        ['FireLureNuke'] = {
            "Lure of the Arcanaforged", -- Level 123
            "Lure of Fyrthek",          -- Level 118
            "Lure of Sontalak",         -- Level 113
            "Lure of Qunard",           -- Level 108
            "PlasmaLure",               -- Level 103
            "MagmaLure",                -- Level 98
            "Blazelure",                -- Level 93
            "Flamelure",                -- Level 88
            "Flarelure",                -- Level 83
            "Pyrolure",                 -- Level 78
            "Lavalure",                 -- Level 73
            "Firebane",                 -- Level 68
            "Lure of Ro",               -- Level 62
            "Lure of Flame",            -- Level 55
            "Enticement of Flame",      -- Level 44
        },
        ['MagicLureNuke'] = {
            "Permeating Ether",  -- Level 97
            "Lightningbane",     -- Level 67
            "Lure of Thunder",   -- Level 61
            "Lure of Lightning", -- Level 58
        },
        ['StunMagicNuke'] = {
            "Leap of Lightning XIV",  -- Level 129
            "Leap of Levinsparks",    -- Level 117
            "Leap of Stormjolts",     -- Level 107
            "Leap of Stormbolts",     -- Level 102
            "Leap of Static Sparks",  -- Level 97
            "Leap of Plasma",         -- Level 92
            "Leap of Corposantum",    -- Level 87
            "Leap of Static Jolts",   -- Level 82
            "Leap of Static Bolts",   -- Level 77
            "Leap of Shocking Bolts", -- Level 73
            "Leap of Sparks",         -- Level 72
            "Spark of Thunder",       -- Level 68
            "Draught of Thunder",     -- Level 63
            "Draught of Jiva",        -- Level 55
            "Force Strike",           -- Level 41
            "Thunder Strike",         -- Level 28
            "Force Snap",             -- Level 17
            "Lightning Bolt",         -- Level 16
        },
        -- Rain Spells Listed here are used Primarily for TLP Mode.
        -- Magic Rain - Only have 3 of them so Not Sustainable.
        ['IceRain'] = {
            "Frost Storm XVII",    -- Level 130
            "Rimeclaw Torrent",    -- Level 125
            "Hypothermic Torrent", -- Level 120
            "Coldburst Torrent",   -- Level 115
            "Frostbite Torrent",   -- Level 110
            "Darkwater Torrent",   -- Level 105
            "Tamagrist Torrent",   -- Level 100
            "Frost Torrent",       -- Level 95
            "Hail Torrent",        -- Level 90
            "Icicle Torrent",      -- Level 85
            "Icicle Storm",        -- Level 80
            "Icicle Deluge",       -- Level 75
            "Gelid Rains",         -- Level 70
            "Tears of Marr",       -- Level 65
            "Tears of Prexus",     -- Level 58
            "Frost Storm",         -- Level 41
            "Icestrike",           -- Level 6
        },
        ['FireRain'] = {
            "Tears of Ashbark",      -- Level 130
            "Tears of the Rescued",  -- Level 125
            "Tears of Night Fire",   -- Level 116
            "Tears of Wildfire",     -- Level 111
            "Tears of Dragoflux",    -- Level 106
            "Tears of Narendi",      -- Level 101
            "Tears of Gosik",        -- Level 96
            "Tears of Daevan",       -- Level 91
            "Tears of Flame",        -- Level 86
            "Tears of the Pyrilen",  -- Level 81
            "Tears of the Forsaken", -- Level 76
            "Tears of the Betrayed", -- Level 71
            "Tears of the Sun",      -- Level 66
            "Tears of Ro",           -- Level 61
            "Tears of Solusek",      -- Level 55
            "Lava Storm",            -- Level 32
            "Firestorm",             -- Level 12
        },
        ['FireLureRain'] = {
            "Volcanic Eruption XIV", -- Level 129
            "Volcanic Burst",        -- Level 124
            "Volcanic Barrage",      -- Level 119
            "Volcanic Downpour",     -- Level 114
            "Magmatic Explosion",    -- Level 109
            "Magmatic Burst",        -- Level 104
            "Magmatic Vent",         -- Level 99
            "Magmatic Outburst",     -- Level 94
            "Magmatic Downpour",     -- Level 89
            "Magmatic Eruption",     -- Level 84
            "Pyroclastic Eruption",  -- Level 79
            "Volcanic Eruption",     -- Level 74
            "Meteor Storm",          -- Level 69
            "Tears of Arlyxir",      -- Level 64
        },
        ['SnapNuke'] = {             -- T2 Ice ~8.5s recast (shared with Cloudburst)
            "Cold Snap XII",         -- Level 128
            "Frostblast",            -- Level 123
            "Chillblast",            -- Level 118
            "Coldburst",             -- Level 113
            "Flashfrost",            -- Level 108
            "Flashrime",             -- Level 103
            "Flashfreeze",           -- Level 98
            "Frost Snap",            -- Level 93
            "Freezing Snap",         -- Level 88
            "Gelid Snap",            -- Level 83
            "Rime Snap",             -- Level 78
            "Cold Snap",             -- Level 73
        },
        ['AEBeam'] = {               -- T2 Frontal Fire AE
            "Corona Beam X",         -- Level 126
            "Cremating Beam",        -- Level 121
            "Vaporizing Beam",       -- Level 116
            "Scorching Beam",        -- Level 111
            "Burning Beam",          -- Level 106
            "Combusting Beam",       -- Level 101
            "Incinerating Beam",     -- Level 96
            "Blazing Beam",          -- Level 91
            "Corona Beam",           -- Level 86
            "Beam of Solteris",      -- Level 72
        },
        ['PBFlame'] = {              -- T4 PB Fire AE
            "Ring of Fire XI",       -- Level 127
            "Gyre of Flame",         -- Level 122
            "Coil of Flame",         -- Level 117
            "Loop of Flame",         -- Level 112
            "Wheel of Flame",        -- Level 107
            "Corona of Flame",       -- Level 102
            "Circle of Flame",       -- Level 97
            "Ring of Flame",         -- Level 92
            "Ring of Fire",          -- Level 87
            "Talendor's Presence",   -- Level 82
            "Vsorug's Presence",     -- Level 77
            "Magmaraug's Presence",  -- Level 72
            -- "Circle of Fire",    -- Level 67, Used in PBAE Mode, wouldn't be used in Modern PBAE
        },
        ['PBTimer4'] = {
            "Circle of Thunder", -- Level 70, Magic
            "Circle of Fire",    -- Level 67, Fire
            "Winds of Gelid",    -- Level 60, Ice
            "Supernova",         -- Level 45, Fire
            "Thunderclap",       -- Level 30, Magic
        },
        ['FireJyll'] = {
            "Jyll's Wave of Heat", -- Level 59
        },
        ['IceJyll'] = {
            "Jyll's Zephyr of Ice", -- Level 56
        },
        ['MagicJyll'] = {
            "Jyll's Static Pulse", -- Level 53
        },
    },
    ['Helpers']       = {

        RainCheck = function(target) -- I made a funny
            if not (Config:GetSetting('DoRain') and Config:GetSetting('DoAEDamage')) then return false end
            return Targeting.GetTargetDistance() >= Config:GetSetting('RainDistance') and Targeting.MobNotLowHP(target)
        end,
        ShouldUseFuseRotation = function()
            return Core.GetResolvedActionMapItem('FuseNuke')
        end,
        ShouldUseWildRotation = function()
            return not Core.GetResolvedActionMapItem('FuseNuke') and Core.GetResolvedActionMapItem('ChaosNuke') and Core.GetResolvedActionMapItem('WildNuke')
        end,
        ShouldUseLowLevelRotation = function()
            return not Core.GetResolvedActionMapItem('FuseNuke') and not (Core.GetResolvedActionMapItem('ChaosNuke') and Core.GetResolvedActionMapItem('WildNuke'))
        end,
        HasLowLevelPBAE = function()
            return Config:GetSetting('DoPBAE') and not Core.GetResolvedActionMapItem('PBFlame')
        end,
        ShouldUseLowLevelPBAE = function()
            return Config:GetSetting('DoPBAE') and not Core.GetResolvedActionMapItem('PBFlame') and Config:GetSetting('DoAEDamage') and Combat.AETargetCheck(true)
        end,
    },
    ['Charm']         = {
        ['Assist'] = {
            {
                name = "StunSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoStun') end,
                cond = function(self, spell, target)
                    return Targeting.TargetNotStunned() and not Casting.StunImmuneTarget(target)
                end,
            },
        },
    },
    ['RotationOrder'] = {
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
            name = 'Aggro Management',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctAggro() > (Config:GetSetting('JoltAggro') or 90)
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        { --Keep things from doing
            name = 'Stun',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoStun') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'DPS(100+)',
            state = 1,
            steps = 1,
            load_cond = function(self) return self.Helpers.ShouldUseFuseRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not self.Helpers.ShouldUseLowLevelPBAE()
            end,
        },
        {
            name = 'DPS(71-99)',
            state = 1,
            steps = 1,
            load_cond = function(self) return self.Helpers.ShouldUseWildRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not self.Helpers.ShouldUseLowLevelPBAE()
            end,
        },
        {
            name = 'FireDPS(1-70)',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('ElementChoice') == 1 and self.Helpers.ShouldUseLowLevelRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not self.Helpers.ShouldUseLowLevelPBAE()
            end,
        },
        {
            name = 'IceDPS(1-70)',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('ElementChoice') == 2 and self.Helpers.ShouldUseLowLevelRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not self.Helpers.ShouldUseLowLevelPBAE()
            end,
        },
        {
            name = 'MagicDPS(1-70)',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('ElementChoice') == 3 and self.Helpers.ShouldUseLowLevelRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not self.Helpers.ShouldUseLowLevelPBAE()
            end,
        },
        {
            name = 'DPS(PBAELowLevel)',
            state = 1,
            steps = 1,
            load_cond = function(self) return self.Helpers.HasLowLevelPBAE() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and self.Helpers.ShouldUseLowLevelPBAE()
            end,
        },
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay()
            end,
        },
        {
            name = 'CombatBuff',
            state = 1,
            steps = 1,
            timer = 10,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
    },
    ['Rotations']     = {
        ['Burn'] = {
            {
                name = "Focus of Arcanum",
                type = "AA",
            },
            {
                name = "Arcane Fury",
                type = "AA",
            },
            {
                name = "Fury of the Gods",
                type = "AA",
            },
            {
                name = "Spire of Arcanum",
                type = "AA",
            },
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Arcane Destruction",
                type = "AA",
                cond = function(self)
                    return not Casting.IHaveBuff("Spire of Arcanum")
                end,
            },
            {
                name = "Frenzied Devastation",
                type = "AA",
                cond = function(self)
                    return not Casting.IHaveBuff("Spire of Arcanum")
                end,
            },
            {
                name = "Silent Casting",
                type = "AA",
            },
            {
                name = "Mana Burn",
                type = "AA",
                cond = function(self)
                    if not Config:GetSetting('DoManaBurn') then return false end
                    return not Casting.TargetHasBuff("Mana Burn") and Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Call of Xuzl",
                type = "AA",
            },
            { -- do not use on emu, can lead to serious xtarg issues
                name = "Ward of Destruction",
                type = "AA",
                load_cond = function() return not Core.OnEMU() end,
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoAEDamage')
                end,
            },
        },
        ['Aggro Management'] =
        {
            {
                name = "Mind Crash",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 90
                end,
            },
            {
                name = "Arcane Whisper",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 90
                end,
            },
            {
                name = "A Hole in Space",
                type = "AA",
                cond = function(self)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Concussion",
                type = "AA",
                cond = function(self)
                    return mq.TLO.Me.PctAggro() > Config:GetSetting('JoltAggro')
                end,
            },
            {
                name = "JoltSpell",
                type = "Spell",
                cond = function(self)
                    return mq.TLO.Me.PctAggro() > Config:GetSetting('JoltAggro')
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Atol's Shackles",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Stun'] = {
            {
                name = "StunSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.HaveManaToDebuff() and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed and not Casting.StunImmuneTarget(target)
                end,
            },
        },
        ['CombatBuff'] =
        {
            {
                name = "TwincastSpell",
                type = "Spell",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "GambitSpell",
                type = "Spell",
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('GambitManaPct')
                end,
            },
            {
                name = "Harvest of Druzzil",
                type = "AA",
                allowDead = true,
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('CombatHarvestManaPct')
                end,
            },
            {
                name = "HarvestSpell",
                type = "Spell",
                allowDead = true,
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('CombatHarvestManaPct')
                end,
            },
        },
        ['Weaves'] = {
            {
                name = "Lower Element",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Force of Ice",
                type = "AA",
            },
            {
                name = "Force of Will",
                type = "AA",
            },
            {
                name = "Force of Flame",
                type = "AA",
            },
        },
        ['DPS(100+)'] = {
            {
                name = "VortexNuke",
                type = "Spell",
                cond = function(self, spell) --using DotSpellCheck to leverage MobLowHP settings to ensure we aren't casting just before trash dies (default: stop at 25% on named, 50% on trash)
                    return Casting.GambitCheck() or Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "CloudburstNuke",
                type = "Spell",
                cond = function(self)
                    return Casting.GambitCheck() or Casting.IHaveBuff("Evoker's Synergy")
                end,
            },
            {
                name = "SnapNuke",
                type = "Spell",
                load_cond = function() return not Core.GetResolvedActionMapItem('VortexNuke') end,
            },
            {
                name = "FuseNuke",
                type = "Spell",
            },
            {
                name = "AEBeam",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoAEBeam') end,
                cond = function(self)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true, Config:GetSetting('BeamTargetCnt'))
                end,
            },
            {
                name = "FireClaw",
                type = "Spell",
                cond = function(self)
                    return not Casting.IHaveBuff("Improved Twincast")
                end,
            },
            {
                name = "PBFlame",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAE') end,
                cond = function(self)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "FireEtherealNuke",
                type = "Spell",
            },
            {
                name = "WildNuke",
                type = "Spell",
                cond = function(self)
                    return Casting.GambitCheck()
                end,
            },
            {
                name = "IceEtherealNuke",
                type = "Spell",
                cond = function(self)
                    return mq.TLO.Me.Level() > 110 or Casting.IHaveBuff("Improved Twincast")
                end,
            },
        },
        ['DPS(71-99)'] = {
            {
                name = "FireClaw",
                type = "Spell",
                cond = function(self)
                    return not Casting.IHaveBuff("Improved Twincast")
                end,
            },
            {
                name = "SnapNuke",
                type = "Spell",
            },
            { --use if GOM procs or if we have extra mana while burning
                name = "FireEtherealNuke",
                type = "Spell",
                cond = function(self)
                    return Casting.GOMCheck() or (Casting.BurnCheck() and Casting.HaveManaToNuke())
                end,
            },
            { --use if GOM procs or if we have extra mana while burning
                name = "IceEtherealNuke",
                type = "Spell",
                cond = function(self)
                    return Casting.GOMCheck() or (Casting.BurnCheck() and Casting.HaveManaToNuke())
                end,
            },
            {
                name = "AEBeam",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoAEBeam') end,
                cond = function(self)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true, Config:GetSetting('BeamTargetCnt'))
                end,
            },
            {
                name = "PBFlame",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAE') end,
                cond = function(self)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "WildNuke",
                type = "Spell",
            },
            {
                name = "WildNuke2",
                type = "Spell",
            },
            {
                name = "ChaosNuke",
                type = "Spell",
                cond = function(self)
                    return not Core.GetResolvedActionMapItem("WildNuke2")
                end,
            },
        },
        ['FireDPS(1-70)'] = {
            {
                name = "FireRain",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.RainCheck(target)
                end,
            },
            {
                name = "FireEtherealNuke",
                type = "Spell",
                load_cond = function() return Core.GetResolvedActionMapItem('FireEtherealNuke') end,
            },
            {
                name = "BigFireNuke",
                type = "Spell",
                load_cond = function() return not Core.GetResolvedActionMapItem('FireEtherealNuke') end,
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
            },
        },
        ['IceDPS(1-70)'] = {
            {
                name = "IceRain",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.RainCheck(target)
                end,
            },
            {
                name = "BigIceNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
            },
        },
        ['MagicDPS(1-70)'] = {
            {
                name = "BigMagicNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
            },
        },
        ['DPS(PBAELowLevel)'] = {
            {
                name = "PBTimer4",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "FireJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "IceJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "MagicJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return (spell.Level() or 0) > (mq.TLO.Me.AltAbility("Etherealist's Unity").Spell.Trigger(1).Level() or 0) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Etherealist's Unity",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID()) end,
                cond = function(self, aaName)
                    local selfHPBuff = Modules:ExecModule("Class", "GetResolvedActionMapItem", "SelfHPBuff")
                    local selfHPBuffLevel = selfHPBuff and selfHPBuff() and selfHPBuff.Level() or 0
                    return (mq.TLO.Me.AltAbility("Etherealist's Unity").Spell.Trigger(1).Level() or 0) >= selfHPBuffLevel and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "SelfSpellShield1",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfRune1",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "FamiliarBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return (spell.Level() or 0) > (mq.TLO.Me.AltAbility("Improved Familiar").Spell.Level() or 0) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Improved Familiar",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.ID()) end,
                cond = function(self, aaName)
                    local familiarBuff = Modules:ExecModule("Class", "GetResolvedActionMapItem", "FamiliarBuff")
                    local familiarBuffLevel = familiarBuff and familiarBuff() and familiarBuff.Level() or 0
                    return (mq.TLO.Me.AltAbility(aaName).Spell.Level() or 0) >= familiarBuffLevel and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Harvest of Druzzil",
                type = "AA",
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('HarvestManaPct')
                end,
            },
            {
                name = "HarvestSpell",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.CastReady(spell) and mq.TLO.Me.PctMana() < Config:GetSetting('HarvestManaPct')
                end,
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoChestClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('HarvestManaPct') and Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
    },
    ['SpellList']     = {
        {
            name = "Default Mode",
            cond = function(self) return not self.Helpers.ShouldUseLowLevelRotation() end,
            spells = {
                { name = "VortexNuke",       cond = function(self) return self.Helpers.ShouldUseFuseRotation() end, },
                { name = "SnapNuke",         cond = function(self) return self.Helpers.ShouldUseWildRotation() or not Core.GetResolvedActionMapItem('VortexNuke') end, },
                { name = "FireEtherealNuke", },
                { name = "IceEtherealNuke", },
                { name = "FuseNuke", },
                { name = "FireClaw", },
                { name = "WildNuke", },
                { name = "CloudburstNuke",   cond = function(self) return self.Helpers.ShouldUseFuseRotation() end, },
                { name = "WildNuke2",        cond = function(self) return self.Helpers.ShouldUseWildRotation() end, },
                { name = "ChaosNuke",        cond = function(self) return self.Helpers.ShouldUseWildRotation() and not Core.GetResolvedActionMapItem('WildNuke2') end, },
                { name = "GambitSpell", },
                { name = "TwincastSpell", },
                { name = "AEBeam",           cond = function() return Config:GetSetting('DoAEBeam') end, },
                { name = "PBFlame",          cond = function() return Config:GetSetting('DoPBAE') end, },
                { name = "PBTimer4",         cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "FireJyll",         cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "IceJyll",          cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "MagicJyll",        cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "SnareSpell",       cond = function() return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Atol's Shackles") end, },
                { name = "StunSpell",        cond = function() return Config:GetSetting('DoStun') end, },
                { name = "EvacSpell",        cond = function() return not Casting.CanUseAA("Exodus") end, },
                { name = "SelfRune1", },
                { name = "SelfSpellShield1", },
                { name = "HarvestSpell", },
                { name = "JoltSpell", },
                { name = "SelfHPBuff", },
            },
        },
        {
            name = "Low Level",
            spells = {
                { name = "FireNuke",         cond = function() return Config:GetSetting('ElementChoice') == 1 end, },
                { name = "IceNuke",          cond = function() return Config:GetSetting('ElementChoice') == 2 end, },
                { name = "MagicNuke",        cond = function() return Config:GetSetting('ElementChoice') == 3 end, },
                { name = "FireEtherealNuke", cond = function() return Config:GetSetting('ElementChoice') == 1 end, },
                { name = "BigFireNuke",      cond = function() return Config:GetSetting('ElementChoice') == 1 and not Core.GetResolvedActionMapItem('FireEtherealNuke') end, },
                { name = "BigIceNuke",       cond = function() return Config:GetSetting('ElementChoice') == 2 end, },
                { name = "BigMagicNuke",     cond = function() return Config:GetSetting('ElementChoice') == 3 end, },
                { name = "PBTimer4",         cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "FireJyll",         cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "IceJyll",          cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "MagicJyll",        cond = function(self) return self.Helpers.HasLowLevelPBAE() end, },
                { name = "FireRain",         cond = function() return Config:GetSetting('DoRain') and Config:GetSetting('ElementChoice') == 1 end, },
                { name = "IceRain",          cond = function() return Config:GetSetting('DoRain') and Config:GetSetting('ElementChoice') == 2 end, },
                { name = "SnareSpell",       cond = function() return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Atol's Shackles") end, },
                { name = "StunSpell",        cond = function() return Config:GetSetting('DoStun') end, },
                { name = "EvacSpell",        cond = function() return not Casting.CanUseAA("Exodus") end, },
                { name = "SelfRune1", },
                { name = "HarvestSpell", },
                { name = "JoltSpell", },
                { name = "SelfHPBuff", },
            },
        },
    },
    ['DefaultConfig'] = {
        ['Mode']                 = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different Modes Do?",
            Answer = "Wizard only has a single DPS Mode, but spells or spell elements will change based on level.",
        },

        -- Low Level
        ['ElementChoice']        = {
            DisplayName = "Element Choice:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Choose an element to focus on under level 71.",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Ice', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoRain']               = {
            DisplayName = "Do Rain",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            Tooltip = "**WILL BREAK MEZ** Use your selected element's Rain Spell as a single-target nuke. **WILL BREAK MEZ***",
            Default = false,
            FAQ = "Why is Rain being used a single target nuke?",
            Answer = "In some situations, using a Rain can be an efficient single target nuke at low levels.\n" ..
                "Note that PBAE spells tend to be superior for AE dps at those levels.",
        },
        ['RainDistance']         = {
            DisplayName = "Min Rain Distance",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            ConfigType = "Advanced",
            Tooltip = "The minimum distance a target must be to use a Rain (Rain AE Range: 25').",
            Default = 30,
            Min = 0,
            Max = 100,
            FAQ = "Why does minimum rain distance matter?",
            Answer = "Rain spells, if cast close enough, can damage the caster. The AE range of a Rain is 25'.",
        },
        ['DoStun']               = {
            DisplayName = "Do Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Use your Stun Nukes (Stun with DD, not mana efficient).",
            RequiresLoadoutChange = true,
            Default = false,
        },

        --AE Damage
        ['DoAEBeam']             = {
            DisplayName = "Use Beam Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip = "**WILL BREAK MEZ** Use your Frontal AE Spells (Beam Line). **WILL BREAK MEZ**",
            Default = false,
        },
        ['BeamTargetCnt']        = {
            DisplayName = "Beam Tgt Cnt",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 103,
            Tooltip = "Minimum number of valid targets before using AE Spells like Beams.",
            Default = 2,
            Min = 1,
            Max = 10,
            FAQ = "Why am I using AE abilities on only a couple of targets?",
            Answer =
            "You can adjust the AE Target Count to control when you will use actions with AE damage attached.",
        },
        ['DoPBAE']               = {
            DisplayName = "Use PBAE Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 104,
            RequiresLoadoutChange = true,
            Tooltip = "**WILL BREAK MEZ** Use your PB AE Spells. **WILL BREAK MEZ**",
            Default = false,
            FAQ = "Why am I using AE damage when there are mezzed mobs around?",
            Answer = "It is not currently possible to properly determine Mez status without direct Targeting. If you are mezzing, consider turning this option off.",
        },

        -- Spells and Abilities
        ['JoltAggro']            = {
            DisplayName = "Jolt Aggro %",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 101,
            Tooltip = "Aggro at which to use Jolt",
            Default = 90,
            Min = 1,
            Max = 100,
        },
        ['DoManaBurn']           = {
            DisplayName = "Use Mana Burn AA",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Enable usage of Mana Burn",
            Default = true,
        },
        ['DoSnare']              = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare Spells.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']           = {
            DisplayName = "Snare Max Mob Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 102,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro. Helpful for AoE groups.",
            Default = 3,
            Min = 1,
            Max = 99,
        },
        ['DoChestClick']         = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your chest item",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['GambitManaPct']        = {
            DisplayName = "Gambit Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            ConfigType = "Advanced",
            Tooltip = "What Mana % to hit before using your Gambit line.",
            Default = 80,
            Min = 1,
            Max = 99,
        },
        ['HarvestManaPct']       = {
            DisplayName = "Harvest Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            ConfigType = "Advanced",
            Tooltip = "What Mana % to hit before using a harvest spell or aa.",
            Default = 85,
            Min = 1,
            Max = 99,
        },
        ['CombatHarvestManaPct'] = {
            DisplayName = "Combat Harvest %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            ConfigType = "Advanced",
            Tooltip = "What Mana % to hit before using a harvest spell or aa in Combat.",
            Default = 60,
            Min = 1,
            Max = 99,
        },
    },
    ['ClassFAQ']      = {
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
