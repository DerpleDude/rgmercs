local mq              = require('mq')
local Casting         = require("utils.casting")
local Comms           = require("utils.comms")
local Config          = require('utils.config')
local Core            = require("utils.core")
local Globals         = require("utils.globals")
local ItemManager     = require("utils.item_manager")
local Logger          = require("utils.logger")
local Modules         = require("utils.modules")
local Targeting       = require("utils.targeting")

-- Provide a valid aura name to check as they are named differently then the spells
-- -- Only use the first word(s) of the aura name, they are all unique (enough)
local auraSpellToName = {
    ["Mana Recursion Aura XI"] = "Mana Recursion",
    ["Mana Ripple Aura"] = "Mana Ripple",
    ["Mana Radix Aura"] = "Mana Radix",                 -- "Mana Radix Aura"
    ["Mana Replication Aura"] = "Mana Replication",     -- "Mana Replication Aura"
    ["Mana Repetition Aura"] = "Mana Repetition",       -- "Mana Repetition Aura"
    ["Mana Reciprocation Aura"] = "Mana Reciprocation", -- "Mana Reciprocation Aura"
    ["Mana Reverberation Aura"] = "Mana Rev",           -- "Mana Rev. Aura"
    ["Mana Repercussion Aura"] = "Mana Rep",            -- "Mana Rep. Aura"
    ["Mana Reiteration Aura"] = "Mana Recursion",       -- "Mana Recursion Aura"
    ["Mana Reiterate Aura"] = "Mana Reiterate",         -- "Mana Reiterate Aura"
    ["Mana Resurgence Aura"] = "Mana Resurgence",       -- "Mana Resurgence Aura"
    ["Mystifier's Aura"] = "Mystifier",                 -- "Mystifier's Aura"
    ["Entrancer's Aura"] = "Entrancer",                 -- "Entrancer's Aura"
    ["Illusionist's Aura"] = "Illusionist",             -- "Illusionist's Aura"
    ["Beguiler's Aura"] = "Beguiler",                   -- "Beguiler's Aura"
}

local _ClassConfig    = {
    _version          = "1.5 - Live",
    _author           = "Derple, Grimmier, Algar",
    ['ModeChecks']    = {
        CanMez    = function() return true end,
        CanCharm  = function() return true end,
        IsMezzing = function() return Config:GetSetting('MezOn') end,
    },
    ['Modes']         = {
        'Default',
        'ModernEra', --Different DPS rotation, meant for ~90+ (and may not come fully online until 105ish)
    },
    ['PetPosition']   = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function()
            local cdAA = mq.TLO.Me.AltAbility("Companion's Discipline")
            return (cdAA and cdAA.Rank() or 0) >= 5 and "Companion's Discipline"
        end,
    },
    ['Themes']        = {
        ['Default'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.02, g = 0.17, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.02, g = 0.17, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.05, g = 0.45, b = 0.50, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.03, g = 0.28, b = 0.32, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.05, g = 0.45, b = 0.50, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.02, g = 0.17, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.10, g = 0.90, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.10, g = 0.90, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
        },
        ['ModernEra'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.05, g = 0.30, b = 0.45, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.05, g = 0.30, b = 0.45, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.02, g = 0.11, b = 0.18, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.05, g = 0.30, b = 0.45, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.05, g = 0.30, b = 0.45, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.02, g = 0.11, b = 0.18, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.05, g = 0.30, b = 0.45, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.05, g = 0.30, b = 0.45, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.05, g = 0.30, b = 0.45, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.03, g = 0.19, b = 0.29, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.05, g = 0.30, b = 0.45, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.05, g = 0.30, b = 0.45, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.05, g = 0.30, b = 0.45, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.02, g = 0.11, b = 0.18, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.10, g = 0.90, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.10, g = 0.90, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.05, g = 0.30, b = 0.45, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Staff of Eternal Eloquence",
            "Oculus of Persuasion",
        },
    },
    ['AbilitySets']   = {
        ['TwincastAura'] = {
            "Twincast Aura", -- Level 84
        },
        ['SpellProcAura'] = {
            "Mana Recursion Aura XI",  -- Level 130
            "Mana Ripple Aura",        -- Level 125
            "Mana Radix Aura",         -- Level 120
            "Mana Replication Aura",   -- Level 115
            "Mana Repetition Aura",    -- Level 110
            "Mana Reciprocation Aura", -- Level 105
            "Mana Reverberation Aura", -- Level 100
            "Mana Repercussion Aura",  -- Level 95
            "Mana Reiteration Aura",   -- Level 90
            "Mana Reiterate Aura",     -- Level 85
            "Mana Resurgence Aura",    -- Level 80
            -- Use mana regen aura until spell proc is available
            "Mystifier's Aura",        -- Level 77
            "Entrancer's Aura",        -- Level 72
            "Illusionist's Aura",      -- Level 70
            "Beguiler's Aura",         -- Level 55
        },
        ['LearnersAura'] = {
            "Learner's Aura", -- Level 76
        },
        ['HasteBuff'] = {
            "Hastening of Elluria",  -- Level 126
            "Hastening of Margator", -- Level 124
            "Hastening of Jharin",   -- Level 119
            "Hastening of Cekenar",  -- Level 114
            "Speed of Cekenar",      -- Level 111
            "Hastening of Milyex",   -- Level 109
            "Speed of Milyex",       -- Level 106
            "Hastening of Prokev",   -- Level 104
            "Speed of Prokev",       -- Level 101
            "Hastening of Sviir",    -- Level 100
            "Speed of Sviir",        -- Level 96
            "Hastening of Aransir",  -- Level 95
            "Speed of Aransir",      -- Level 91
            "Hastening of Novak",    -- Level 90
            "Speed of Novak",        -- Level 86
            "Hastening of Erradien", -- Level 80
            "Speed of Erradien",     -- Level 77
            "Hastening of Ellowind", -- Level 75
            "Speed of Ellowind",     -- Level 72
            "Hastening of Salik",    -- Level 70
            "Speed of Salik",        -- Level 67
            "Vallon's Quickening",   -- Level 65
            "Speed of Vallon",       -- Level 62
            "Speed of the Brood",    -- Level 60
            "Visions of Grandeur",   -- Level 60
            "Wondrous Rapidity",     -- Level 58
            "Aanya's Quickening",    -- Level 53
            "Swift Like the Wind",   -- Level 47
            "Celerity",              -- Level 39
            "Augmentation",          -- Level 28
            "Alacrity",              -- Level 21
            "Quickness",             -- Level 15
        },
        ['ManaRegen'] = {
            "Voice of Clairvoyance XVIII", -- Level 128
            "Voice of Preordination",      -- Level 125
            "Voice of Perception",         -- Level 120
            "Voice of Sagacity",           -- Level 115
            "Sagacity",                    -- Level 113
            "Voice of Perspicacity",       -- Level 110
            "Perspicacity",                -- Level 108
            "Voice of Precognition",       -- Level 105
            "Precognition",                -- Level 103
            "Voice of Foresight",          -- Level 100
            "Foresight",                   -- Level 98
            "Voice of Premeditation",      -- Level 95
            "Premeditation",               -- Level 93
            "Voice of Forethought",        -- Level 90
            "Forethought",                 -- Level 88
            "Voice of Prescience",         -- Level 85
            "Prescience",                  -- Level 83
            "Voice of Cognizance",         -- Level 80
            "Seer's Cognizance",           -- Level 78
            "Voice of Intuition",          -- Level 75
            "Seer's Intuition",            -- Level 73
            "Voice of Clairvoyance",       -- Level 70
            "Clairvoyance",                -- Level 68
            "Voice of Quellious",          -- Level 65
            "Tranquility",                 -- Level 63
            -- "Gift of Brilliance",       -- Level 60, Removed because the Map Defaults to it Instead of Koadics
            "Koadic's Endless Intellect",  -- Level 60
            "Gift of Pure Thought",        -- Level 56
            "Gift of Insight",             -- Level 55
            "Clarity II",                  -- Level 52
            "Clarity",                     -- Level 26
            "Breeze",                      -- Level 14
        },
        ['MezBuff'] = {
            "Ward of Bedazzlement XII", -- Level 130
            "Ward of the Stupefier",    -- Level 125
            "Ward of the Beguiler",     -- Level 120
            "Ward of the Deviser",      -- Level 115
            "Ward of the Transfixer",   -- Level 110
            "Ward of the Enticer",      -- Level 105
            "Ward of the Mastermind",   -- Level 100
            "Ward of Arctending",       -- Level 95
            "Ward of Bafflement",       -- Level 90
            "Ward of Befuddlement",     -- Level 85
            "Ward of Mystifying",       -- Level 80
            "Ward of Bewilderment",     -- Level 75
            "Ward of Bedazzlement",     -- Level 70
        },
        ['NdtBuff'] = {
            "Night's Eternal Terror",   -- Level 125
            "Night's Perpetual Terror", -- Level 115
            "Night's Endless Terror",   -- Level 103
            "Night's Dark Terror",      -- Level 63
            "Boon of the Garou",        -- Level 40
        },
        ['SelfHPBuff'] = {
            "Shielding XXIII",         -- Level 126
            "Shield of Memories",      -- Level 121
            "Shield of Shadow",        -- Level 116
            "Shield of Restless Ice",  -- Level 111
            "Shield of Scales",        -- Level 106
            "Shield of the Pellarus",  -- Level 101
            "Shield of the Dauntless", -- Level 96
            "Shield of Bronze",        -- Level 91
            "Shield of Dreams",        -- Level 86
            "Shield of the Void",      -- Level 81
            "Spellbound Shield",       -- Level 76
            "Sorcerous Shield",        -- Level 71
            "Mystic Shield",           -- Level 66
            "Shield of Maelin",        -- Level 64
            "Shield of the Arcane",    -- Level 61
            "Shield of the Magi",      -- Level 54
            "Arch Shielding",          -- Level 40
            "Greater Shielding",       -- Level 31
            "Major Shielding",         -- Level 23
            "Shielding",               -- Level 16
            "Lesser Shielding",        -- Level 6
            "Minor Shielding",         -- Level 1
        },
        ['SelfRune1'] = {
            "Arcane Rune XIII",  -- Level 126
            "Esoteric Rune",     -- Level 121
            "Marvel's Rune",     -- Level 116
            "Deviser's Rune",    -- Level 111
            "Transfixer's Rune", -- Level 106
            "Enticer's Rune",    -- Level 101
            "Mastermind's Rune", -- Level 96
            "Arcanaward's Rune", -- Level 91
            "Spectral Rune",     -- Level 86
            "Pearlescent Rune",  -- Level 81
            "Opalescent Rune",   -- Level 76
            "Draconic Rune",     -- Level 71
            "Ethereal Rune",     -- Level 66
            "Arcane Rune",       -- Level 61
        },
        ['SelfRune2'] = {
            "Polychromatic Rune XII", -- Level 130
            "Polyradiant Rune",       -- Level 125
            "Polyluminous Rune",      -- Level 120
            "Polycascading Rune",     -- Level 115
            "Polyfluorescent Rune",   -- Level 110
            "Polyrefractive Rune",    -- Level 105
            "Polyiridescent Rune",    -- Level 100
            "Polyarcanic Rune",       -- Level 95
            "Polyspectral Rune",      -- Level 90
            "Polychaotic Rune",       -- Level 85
            "Multichromatic Rune",    -- Level 80
            "Polychromatic Rune",     -- Level 75
        },
        ['UnityRune'] = {
            "Enticer's Unity IX", -- Level 130
            "Esoteric Unity",     -- Level 125
            "Marvel's Unity",     -- Level 120
            "Deviser's Unity",    -- Level 115
        },
        ['SingleRune'] = {
            "Rune XIX",           -- Level 126
            "Rune of Zoraxmen",   -- Level 121
            "Rune of Tearc",      -- Level 116
            "Rune of Kildrukaun", -- Level 111
            "Rune of Skrizix",    -- Level 106
            "Rune of Lucem",      -- Level 101
            "Rune of Xolok",      -- Level 96
            "Rune of Tonmek",     -- Level 91
            "Rune of Novak",      -- Level 86
            "Rune of Yozan",      -- Level 81
            "Rune of Erradien",   -- Level 76
            "Rune of Ellowind",   -- Level 71
            "Rune of Salik",      -- Level 67
            "Rune of Zebuxoruk",  -- Level 61
            "Rune V",             -- Level 52
            "Rune IV",            -- Level 40
            "Rune III",           -- Level 33
            "Rune II",            -- Level 22
            "Rune I",             -- Level 13
        },
        ['GroupRune'] = {
            "Rune of the Vortex", -- Level 129
            "Gloaming Rune",      -- Level 124
            "Eclipsed Rune",      -- Level 119
            "Crepuscular Rune",   -- Level 114
            "Tenebrous Rune",     -- Level 109
            "Darkened Rune",      -- Level 104
            "Umbral Rune",        -- Level 99
            "Shadowed Rune",      -- Level 94
            "Twilight Rune",      -- Level 89
            "Rune of the Void",   -- Level 84
            "Rune of the Deep",   -- Level 79
            "Rune of the Kedge",  -- Level 74
            "Rune of Rikkukin",   -- Level 69
            "Rune of the Scale",  -- Level 61
        },
        ['AggroRune'] = {
            "Horrifying Rune VIII", -- Level 129
            "Disquieting Rune",     -- Level 123
            "Ghastly Rune",         -- Level 118
            "Horrendous Rune",      -- Level 113
            "Dreadful Rune",        -- Level 108
            "Frightening Rune",     -- Level 103
            "Terrifying Rune",      -- Level 98
            "Horrifying Rune",      -- Level 93
        },
        ['AggroBuff'] = {
            "Horrifying Visage", -- Level 56
            "Haunting Visage",   -- Level 26
        },
        ['SingleSpellShield'] = {
            "Aegis of Elmara",       -- Level 123
            "Aegis of Sefra",        -- Level 118
            "Aegis of Omica",        -- Level 113
            "Aegis of Nureya",       -- Level 108
            "Aegis of Gordianus",    -- Level 103
            "Aegis of Xorbb",        -- Level 98
            "Aegis of Soliadal",     -- Level 93
            "Aegis of Zykean",       -- Level 88
            "Aegis of Xadrith",      -- Level 83
            "Aegis of Qandieal",     -- Level 78
            "Aegis of Alendar",      -- Level 73
            "Wall of Alendar",       -- Level 68
            "Bulwark of Alendar",    -- Level 63
            "Protection of Alendar", -- Level 55
            "Guard of Alendar",      -- Level 44
            "Ward of Alendar",       -- Level 29
        },
        ['GroupSpellShield'] = {
            "Legion of Feish",      -- Level 128
            "Legion of Boberstler", -- Level 126
            "Legion of Ogna",       -- Level 124
            "Legion of Liako",      -- Level 119
            "Legion of Kildrukaun", -- Level 114
            "Legion of Skrizix",    -- Level 109
            "Legion of Lucem",      -- Level 104
            "Legion of Xolok",      -- Level 99
            "Legion of Tonmek",     -- Level 94
            "Legion of Zykean",     -- Level 89
            "Legion of Xadrith",    -- Level 84
            "Legion of Qandieal",   -- Level 79
            "Legion of Alendar",    -- Level 74
            "Circle of Alendar",    -- Level 70
        },
        ['SingleDotShield'] = {
            "Aegis of Xetheg",        -- Level 116
            "Aegis of Cekenar",       -- Level 111
            "Aegis of Milyex",        -- Level 106
            "Aegis of the Indagator", -- Level 101
            "Aegis of the Keeper",    -- Level 98
        },
        ['GroupDotShield'] = {
            "Legion of Dhakka",        -- Level 121
            "Legion of Xetheg",        -- Level 117
            "Legion of Cekenar",       -- Level 112
            "Legion of Milyex",        -- Level 107
            "Legion of the Indagator", -- Level 102
            "Legion of the Keeper",    -- Level 100
        },
        ['SingleMeleeShield'] = {
            "Umbral Auspice VII",  -- Level 129
            "Gloaming Auspice",    -- Level 124
            "Eclipsed Auspice",    -- Level 119
            "Crepuscular Auspice", -- Level 114
            "Tenebrous Auspice",   -- Level 109
            "Darkened Auspice",    -- Level 104
            "Umbral Auspice",      -- Level 99
        },
        ['SelfGuardShield'] = {
            "Shield of Fate VII",       -- Level 127
            "Shield of Inescapability", -- Level 122
            "Shield of Inevitability",  -- Level 117
            "Shield of Destiny",        -- Level 112
            "Shield of Order",          -- Level 107
            "Shield of Consequence",    -- Level 102
            "Shield of Fate",           -- Level 97
        },
        ['GroupAuspiceBuff'] = {
            "Stupefier's Auspice",  -- Level 122
            "Marvel's Auspice",     -- Level 117
            "Deviser's Auspice",    -- Level 112
            "Transfixer's Auspice", -- Level 107
            "Enticer's Auspice",    -- Level 102
        },
        ['SpellProcBuff'] = {
            "Mana Recursion XI",  -- Level 128
            "Mana Reproduction",  -- Level 123
            "Mana Rebirth",       -- Level 118
            "Mana Replication",   -- Level 113
            "Mana Repetition",    -- Level 108
            "Mana Reciprocation", -- Level 103
            "Mana Reverberation", -- Level 98
            "Mana Repercussion",  -- Level 93
            "Mana Reiteration",   -- Level 88
            "Mana Reiterate",     -- Level 83
            "Mana Resurgence",    -- Level 78
            "Mana Recursion",     -- Level 73
            "Mana Flare",         -- Level 70
        },
        ['AllianceSpell'] = {
            "Chromatic Covariance",  -- Level 123
            "Chromatic Conjunction", -- Level 118
            "Chromatic Coalition",   -- Level 113
            "Chromatic Covenant",    -- Level 108
            "Chromatic Alliance",    -- Level 101
        },
        ['TwinCastMez'] = {
            "Chaotic Enticement X", -- Level 128
            "Chaotic Conundrum",    -- Level 123
            "Chaotic Puzzlement",   -- Level 118
            "Chaotic Deception",    -- Level 113
            "Chaotic Delusion",     -- Level 108
            "Chaotic Bewildering",  -- Level 103
            "Chaotic Confounding",  -- Level 98
            "Chaotic Confusion",    -- Level 93
            "Chaotic Baffling",     -- Level 88
            "Chaotic Befuddling",   -- Level 83
        },
        ['PBAEStunSpell'] = {
            "Color Flux XVIII",    -- Level 129
            "Color Calibration",   -- Level 124
            "Color Conflagration", -- Level 119
            "Color Cascade",       -- Level 114
            "Color Congruence",    -- Level 109
            "Color Concourse",     -- Level 104
            "Color Confluence",    -- Level 99
            "Color Convergence",   -- Level 94
            "Color Clash",         -- Level 89
            "Color Conflux",       -- Level 84
            "Color Cataclysm",     -- Level 79
            "Color Collapse",      -- Level 74
            "Color Snap",          -- Level 69
            "Color Cloud",         -- Level 63
            "Color Slant",         -- Level 52
            "Color Skew",          -- Level 43
            "Color Shift",         -- Level 20
            "Color Flux",          -- Level 3
        },
        ['TargetAEStun'] = {
            "Remote Color Flux XVIII",    -- Level 127
            "Remote Color Calibration",   -- Level 122
            "Remote Color Conflagration", -- Level 117
            "Remote Color Cascade",       -- Level 112
            "Remote Color Congruence",    -- Level 107
            "Remote Color Concourse",     -- Level 102
            "Remote Color Confluence",    -- Level 97
            "Remote Color Convergence",   -- Level 92
        },
        ['SingleStunSpell1'] = {
            "Dizzying Helix XII",       -- Level 129
            "Dizzying Spindle",         -- Level 124
            "Dizzying Vortex",          -- Level 119
            "Dizzying Coil",            -- Level 114
            "Dizzying Wheel",           -- Level 109
            "Dizzying Storm",           -- Level 104
            "Dizzying Squall",          -- Level 99
            "Dizzying Gyre",            -- Level 94
            "Dizzying Helix",           -- Level 89
            "The Downward Spiral",      -- Level 84
            "Whirling into the Hollow", -- Level 79
            "Spinning into the Void",   -- Level 74
            "Largarn's Lamentation",    -- Level 55
            "Dyn's Dizzying Draught",   -- Level 28
            "Whirl till you hurl",      -- Level 9
        },
        ['CharmSpell'] = {
            "Charm XVII",           -- Level 127
            "Inveigle",             -- Level 117
            "Spellbinding",         -- Level 107
            "Captivation",          -- Level 102
            "Temptation",           -- Level 97
            "Compelling Edict",     -- Level 92
            "Deception",            -- Level 87
            "Dominate",             -- Level 85
            "Seduction",            -- Level 82
            "Haunting Whispers",    -- Level 80
            "Cajole",               -- Level 77
            "Dyn`leth's Whispers",  -- Level 75
            "Coax",                 -- Level 72
            "True Name",            -- Level 70
            "Compel",               -- Level 68
            "Command of Druzzil",   -- Level 64
            "Beckon",               -- Level 62
            "Boltran's Agacerie",   -- Level 53
            "Allure",               -- Level 46
            "Cajoling Whispers",    -- Level 37
            "Beguile",              -- Level 23
            "Charm",                -- Level 11
        },
        ['CharmCommand'] = {        -- chance to stun on break, later spells carry a pet buff
            "Enticer's Command XV", -- Level 130
            "Esoteric Command",     -- Level 125
            "Marvel's Command",     -- Level 120
            "Deviser's Command",    -- Level 115
            "Transfixer's Command", -- Level 110
            "Enticer's Command",    -- Level 105
            "Impose",               -- Level 100
            "Enforce",              -- Level 95
            "Subjugate",            -- Level 90
        },
        ['CharmDemand'] = {         -- chance to memblur on break, later spells carry a pet buff
            "Stupefier's Demand",   -- Level 124
            "Marvel's Demand",      -- Level 119
            "Deviser's Demand",     -- Level 114
            "Enticer's Demand",     -- Level 104
        },
        ['CrippleSpell'] = {
            "Splintered Consciousness", -- Level 86
            "Fragmented Consciousness", -- Level 81
            "Shattered Consciousness",  -- Level 76
            "Fractured Consciousness",  -- Level 71
            "Synapsis Spasm",           -- Level 66
            "Cripple",                  -- Level 53
            "Incapacitate",             -- Level 40
            "Listless Power",           -- Level 25
            "Disempower",               -- Level 16
            "Enfeeblement",             -- Level 4
        },
        ['SlowSpell'] = {
            -- Slow - lvl88 and above this is also cripple spell Starting @ Level 88  Combines With Cripple.
            "Desolate Deeds",  -- Level 69
            "Dreary Deeds",    -- Level 65
            "Forlorn Deeds",   -- Level 57
            "Shiftless Deeds", -- Level 41
            "Tepid Deeds",     -- Level 23
            "Languid Pace",    -- Level 9
        },
        ['Dispel'] = {
            "Recant Magic",        -- Level 53
            "Pillage Enchantment", -- Level 42
            "Nullify Magic",       -- Level 28
            "Strip Enchantment",   -- Level 22
            "Cancel Magic",        -- Level 7
            "Taper Enchantment",   -- Level 1
        },
        ['TashSpell'] = {
            "Tashan XVII",            -- Level 127
            "Roar of Tashan",         -- Level 122
            "Edict of Tashan",        -- Level 117
            "Proclamation of Tashan", -- Level 112
            "Order of Tashan",        -- Level 107
            "Decree of Tashan",       -- Level 102
            "Enunciation of Tashan",  -- Level 97
            "Declaration of Tashan",  -- Level 92
            "Clamor of Tashan",       -- Level 87
            "Bark of Tashan",         -- Level 82
            "Din of Tashan",          -- Level 77
            "Echo of Tashan",         -- Level 72
            "Howl of Tashan",         -- Level 61
            "Tashanian",              -- Level 57
            "Tashania",               -- Level 41
            "Tashani",                -- Level 18
            "Tashina",                -- Level 2
        },
        ['ManaDrainNuke'] = {
            "Tears of Kasha",     -- Level 121
            "Tears of Xenacious", -- Level 116
            "Tears of Aaryonar",  -- Level 111
            "Tears of Skrizix",   -- Level 106
            "Tears of Visius",    -- Level 101
            "Tears of Syrkl",     -- Level 100
            "Tears of Wreliard",  -- Level 95
            "Tears of Zykean",    -- Level 90
            "Tears of Xadrith",   -- Level 85
            "Tears of Qandieal",  -- Level 80
            "Torment of Scio",    -- Level 63
            "Torment of Argli",   -- Level 56
            "Scryer's Trespass",  -- Level 52
            "Wandering Mind",     -- Level 38
            "Mana Sieve",         -- Level 30
        },
        ['DichoSpell'] = {
            "Reciprocal Reinforcement", -- Level 121
            "Ecliptic Reinforcement",   -- Level 116
            "Composite Reinforcement",  -- Level 111
            "Dissident Reinforcement",  -- Level 106
            "Dichotomic Reinforcement", -- Level 101
        },
        ['StrangleDot'] = {
            ---DoT 1 -- >=LVL1
            "Strangle XVII",      -- Level 128
            "Asphyxiating Grasp", -- Level 123
            "Throttling Grip",    -- Level 118
            "Pulmonary Grip",     -- Level 113
            "Strangulate",        -- Level 108
            "Drown",              -- Level 103
            "Stifle",             -- Level 98
            "Suffocation",        -- Level 93
            "Constrict",          -- Level 88
            "Smother",            -- Level 83
            "Strangling Air",     -- Level 78
            "Thin Air",           -- Level 73
            "Arcane Noose",       -- Level 69
            "Strangle",           -- Level 62
            "Asphyxiate",         -- Level 59
            "Gasping Embrace",    -- Level 47
            "Suffocate",          -- Level 26
            "Choke",              -- Level 11
            "Suffocating Sphere", -- Level 4
            "Shallow Breath",     -- Level 1
        },
        ['MindDot'] = {
            -- DoT 2 --  >= LVL70
            "Mind Shatter XV", -- Level 130
            "Mind Whirl",      -- Level 125
            "Mind Vortex",     -- Level 120
            "Mind Coil",       -- Level 115
            "Mind Tempest",    -- Level 110
            "Mind Storm",      -- Level 105
            "Mind Squall",     -- Level 100
            "Mind Spiral",     -- Level 95
            "Mind Helix",      -- Level 90
            "Mind Twist",      -- Level 85
            "Mind Oscillate",  -- Level 80
            "Mind Phobiate",   -- Level 75
            "Mind Shatter",    -- Level 70
        },
        ['ConstrictionDot'] = {
            ---DoT 3 -- >= LVL89
            "Dismaying Constriction",   -- Level 124
            "Perplexing Constriction",  -- Level 119
            "Deceiving Constriction",   -- Level 114
            "Deluding Constriction",    -- Level 109
            "Bewildering Constriction", -- Level 104
            "Confounding Constriction", -- Level 99
            "Confusing Constriction",   -- Level 94
            "Baffling Constriction",    -- Level 89
        },
        ['MagicNuke'] = {
            --- Nuke 1 -- >= LVL7
            "Mindblade IX",             -- Level 130
            "Mindrend",                 -- Level 125
            "Mindreap",                 -- Level 120
            "Mindrift",                 -- Level 115
            "Mindslash",                -- Level 110
            "Mindsunder",               -- Level 105
            "Mindcleave",               -- Level 100
            "Mindscythe",               -- Level 95
            "Mindblade",                -- Level 90
            "Spectral Assault",         -- Level 88
            "Chromarcana",              -- Level 87
            "Polychaotic Assault",      -- Level 83
            "Multichromatic Assault",   -- Level 78
            "Polychromatic Assault",    -- Level 73
            "Ancient: Neurosis",        -- Level 70
            "Colored Chaos",            -- Level 69
            "Psychosis",                -- Level 68
            "Madness of Ikkibi",        -- Level 65
            "Ancient: Chaos Madness",   -- Level 65
            "Insanity",                 -- Level 64
            "Ancient: Chaotic Visions", -- Level 60
            "Dementing Visions",        -- Level 58
            "Dementia",                 -- Level 54
            "Discordant Mind",          -- Level 43
            "Anarchy",                  -- Level 32
            "Chaos Flux",               -- Level 21
            "Sanity Warp",              -- Level 16
            "Chaotic Feedback",         -- Level 7
        },
        ['RuneNuke'] = {
            --- RUNE - Nuke Fast >=LVL86
            "Chromatic Jab IX",     -- Level 126
            "Chromatic Spike",      -- Level 121
            "Chromatic Flare",      -- Level 116
            "Chromatic Stab",       -- Level 111
            "Chromatic Flicker",    -- Level 106
            "Chromatic Blink",      -- Level 101
            "Chromatic Percussion", -- Level 96
            "Chromatic Flash",      -- Level 91
            "Chromatic Jab",        -- Level 86
        },
        ['ManaTapNuke'] = {
            --- Mana Drain Nuke - Fast -- >=LVL96
            "Mental Appropriation VII",    -- Level 126
            "Cognitive Appropriation",     -- Level 121
            "Psychological Appropriation", -- Level 116
            "Ideological Appropriation",   -- Level 111
            "Psychic Appropriation",       -- Level 106
            "Intellectual Appropriation",  -- Level 101
            "Mental Appropriation",        -- Level 96
        },
        --Unused table, temporarily removed - was causing conflicts while resolving MagicNuke action maps (will revisit nukes later)
        -- ['ChromaNuke'] = {
        --- Chromatic Lowest Nuke - Normal -- >=LVL73
        --     "Polycascading Assault",   -- Level 113
        --     "Polyfluorescent Assault", -- Level 108
        --     "Polyrefractive Assault",  -- Level 103
        --     "Phantasmal Assault",      -- Level 98
        --     "Arcane Assault",          -- Level 93
        --     "Spectral Assault",        -- Level 88
        --     "Polychaotic Assault",     -- Level 83
        --     "Multichromatic Assault",  -- Level 78
        --     "Polychromatic Assault",   -- Level 73
        -- },
        ['CripSlowSpell'] = {
            --- Slow Cripple Combo Spell - Beginning @ Level 88
            "Inhibiting Helix",   -- Level 123
            "Constraining Coil",  -- Level 113
            "Constraining Helix", -- Level 108
            "Undermining Helix",  -- Level 103
            "Diminishing Helix",  -- Level 98
            "Attenuating Helix",  -- Level 93
            "Curtailing Helix",   -- Level 88
        },
        ['PetSpell'] = {
            "Arkahn's Animation",    -- Level 126
            "Flariton's Animation",  -- Level 121
            "Constance's Animation", -- Level 116
            "Omica's Animation",     -- Level 111
            "Nureya's Animation",    -- Level 106
            "Gordianus' Animation",  -- Level 101
            "Xorlex's Animation",    -- Level 96
            "Seronvall's Animation", -- Level 91
            "Novak's Animation",     -- Level 86
            "Yozan's Animation",     -- Level 81
            "Erradien's Animation",  -- Level 76
            "Ellowind's Animation",  -- Level 71
            "Salik's Animation",     -- Level 66
            "Aeldorb's Animation",   -- Level 62
            "Zumaik's Animation",    -- Level 55
            "Kintaz's Animation",    -- Level 48
            "Yegoreff's Animation",  -- Level 41
            "Aanya's Animation",     -- Level 37
            "Boltran's Animation",   -- Level 31
            "Uleen's Animation",     -- Level 29
            "Sagar's Animation",     -- Level 22
            "Sisna's Animation",     -- Level 17
            "Shalee's Animation",    -- Level 14
            "Kilan's Animation",     -- Level 9
            "Mircyl's Animation",    -- Level 7
            "Juli's Animation",      -- Level 2
            "Pendril's Animation",   -- Level 1
        },
        ['PetBuffSpell'] = {
            "Empowered Minion IV", -- Level 128
            "Invigorated Minion",  -- Level 117
            "Infused Minion",      -- Level 107
            "Empowered Minion",    -- Level 97
        },
        ['MezAESpell'] = {
            "Mesmerizing Wave XV", -- Level 129
            "Stupefying Wave",     -- Level 124
            "Bewildering Wave",    -- Level 119
            "Neutralizing Wave",   -- Level 114
            "Perplexing Wave",     -- Level 109
            "Deadening Wave",      -- Level 104
            "Slackening Wave",     -- Level 99
            "Peaceful Wave",       -- Level 94
            "Serene Wave",         -- Level 89
            "Ensorcelling Wave",   -- Level 84
            "Quelling Wave",       -- Level 79
            "Wake of Subdual",     -- Level 74
            "Wake of Felicity",    -- Level 69
            "Bliss of the Nihil",  -- Level 65
            "Fascination",         -- Level 52
            "Mesmerization",       -- Level 16
        },
        ['MezAESpellFast'] = {
            "Vexing Glance",       -- Level 124
            "Confounding Glance",  -- Level 119
            "Neutralizing Glance", -- Level 114
            "Perplexing Glance",   -- Level 109
            "Slackening Glance",   -- Level 99
        },
        ['MezPBAESpell'] = {
            "Docility XII",        -- Level 128
            "Wonderment",          -- Level 123
            "63916",               -- Level 118, Bewilderment - deconflicts duplicate at Level 72
            "Neutralize",          -- Level 113
            "Perplex",             -- Level 108
            "Bafflement",          -- Level 103
            "Disorientation",      -- Level 98
            "Confusion",           -- Level 93
            "Serenity",            -- Level 88
            "Docility",            -- Level 83
            "Visions of Kirathas", -- Level 78
            "Dreams of Veldyn",    -- Level 73
            "Circle of Dreams",    -- Level 68
            "Word of Morell",      -- Level 62
            "Entrancing Lights",   -- Level 30
        },
        ['MezSpell'] = {
            "Mesmerize XX",             -- Level 126
            "Flummox",                  -- Level 121
            "Addle",                    -- Level 116
            "Deceive",                  -- Level 111
            "Delude",                   -- Level 106
            "Bewilder",                 -- Level 101
            "Confound",                 -- Level 96
            "Mislead",                  -- Level 92
            "Baffle",                   -- Level 87
            "Befuddle",                 -- Level 82
            "Mystify",                  -- Level 77
            "10647",                    -- Level 72, Bewilderment - deconflicts duplicate at Level 118
            "Euphoria",                 -- Level 69
            "Felicity",                 -- Level 67
            "Bliss",                    -- Level 64
            "Sleep",                    -- Level 63
            "Apathy",                   -- Level 61
            "Ancient: Eternal Rapture", -- Level 60
            "Rapture",                  -- Level 59
            "Glamour of Kintaz",        -- Level 54
            "Enthrall",                 -- Level 13
            "Mesmerize",                -- Level 2
        },
        ['MezSpellFast'] = {
            "Flummoxing Flash",  -- Level 122
            "Addling Flash",     -- Level 117
            "Deceiving Flash",   -- Level 112
            "Deluding Flash",    -- Level 107
            "Bewildering Flash", -- Level 102
            "Confounding Flash", -- Level 97
            "Misleading Flash",  -- Level 91
            "Baffling Flash",    -- Level 86
            "Befuddling Flash",  -- Level 81
            "Mystifying Flash",  -- Level 76
            "Perplexing Flash",  -- Level 71
        },
        ['BlurSpell'] = {
            "Memory Flux",         -- Level 55
            "Reoccurring Amnesia", -- Level 45
            "Memory Blur",         -- Level 10
        },
        ['AEBlurSpell'] = {
            "Blanket of Forgetfulness", -- Level 46
            "Mind Wipe",                -- Level 36
        },
        ['CalmSpell'] = {
            ---Calm Spell -- >= LVL1
            "Quiet Mind XIII", -- Level 127
            "Docile Mind",     -- Level 122
            "Still Mind",      -- Level 117
            "Serene Mind",     -- Level 112
            "Mollified Mind",  -- Level 107
            "Pacified Mind",   -- Level 102
            "Quiescent Mind",  -- Level 97
            "Halcyon Mind",    -- Level 92
            "Bucolic Mind",    -- Level 87
            "Hushed Mind",     -- Level 82
            "Silent Mind",     -- Level 77
            "Quiet Mind",      -- Level 72
            "Placate",         -- Level 67
            "Pacification",    -- Level 62
            "Pacify",          -- Level 35
            "Calm",            -- Level 18
            "Soothe",          -- Level 6
            "Lull",            -- Level 1
        },
        ['FearSpell'] = {
            ---Fear Spell * Var Name:, string outer >= LVL3
            "Anxiety Attack", -- Level 67
            "Jitterskin",     -- Level 62
            "Phobia",         -- Level 57
            "Trepidation",    -- Level 56
            "Invoke Fear",    -- Level 35
            "Chase the Moon", -- Level 16
            "Fear",           -- Level 3
        },
        ['RootSpell'] = {
            "Greater Fetter",   -- Level 61
            "Fetter",           -- Level 58
            "Paralyzing Earth", -- Level 45
            "Immobilize",       -- Level 39
            "Instill",          -- Level 25
            "Root",             -- Level 6
        },
    },
    ['Mez']           = {
        { type = "Spell", name = "TwinCastMez",     cond = function() return Config:GetSetting('TwincastMez') > 1 end, },
        { type = "Spell", name = "MezSpell",        cond = function() return Config:GetSetting('TwincastMez') == 1 end, },
        { type = "Spell", name = "MezAESpell", },
        { type = "AA",    name = "Beam of Slumber", cond = function() return Config:GetSetting('DoAAMez') end, },
    },
    ['Charm']         = {
        ['Abilities'] = {
            { type = "AA",    name = "Dire Charm", },
            { type = "Spell", name = "CharmSpell", },
            { type = "Spell", name = "CharmDemand", },
            { type = "Spell", name = "CharmCommand", },
        },
        ['PreCharm']  = {
            {
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTash') end,
                cond = function(self, spell, target) return not target.Tashed() end,
            },
        },
        ['Assist']    = {
            {
                name = "PBAEStunSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAEStun') > 1 end,
                cond = function(self, spell, target) return Targeting.TargetNotStunned() and Targeting.InSpellRange(spell, target) end,
            },
            {
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTash') end,
                cond = function(self, spell, target) return Casting.DetSpellCheck(spell, target) end,
            },
        },
    },
    ['RotationOrder'] = {
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and not Core.IsCharming() and Casting.AmIBuffable()
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
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
            end,
        },
        { --Slow and Tash separated so we use both before we start DPS
            name = 'Tash',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoTash') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        { --Slow and Tash separated so we use both before we start DPS
            name = 'CripSlow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSlow') or Config:GetSetting('DoCripple') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Dispel',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoDispel') end,
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
        { --AA Stuns, Runes, etc, moved from previous home in DPS
            name = 'CombatSupport',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'DPS(Default)',
            state = 1,
            steps = 1,
            load_cond = function() return Core.IsModeActive("Default") end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(ModernEra)',
            state = 1,
            steps = 1,
            load_cond = function() return Core.IsModeActive("ModernEra") end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Helpers']       = { --used to autoinventory our azure crystal after summon
        StashCrystal = function()
            mq.delay("2s", function() return mq.TLO.Cursor.ID() == mq.TLO.Me.AltAbility("Azure Mind Crystal").Spell.Base(1)() end)

            if not mq.TLO.Cursor() then
                Logger.log_debug("No valid item found on cursor, item handling aborted.")
                return false
            end

            Logger.log_debug("Sending the %s to our bags.", mq.TLO.Cursor())
            ItemManager.QueueAutoInv(mq.TLO.Cursor.ID())
        end,
        AuraCheck = function() -- remove undesired auras to stop spam conditions... this will only be triggered if we have already identified we are missing a desired aura
            if Casting.CanUseAA("Auroria Mastery") then
                -- If we can use two auras we will keep twincast and get rid of the other (including old versions of the spellproc aura line)
                -- Make sure we don't get rid of the first aura if the second aura is already free for whatever reason (fallback)
                ---@diagnostic disable-next-line: undefined-field
                if (mq.TLO.Me.Aura(1).Name() or "Twincast Aura") ~= "Twincast Aura" and mq.TLO.Me.Aura(2)() then mq.TLO.Me.Aura(1).Remove() end
                ---@diagnostic disable-next-line: undefined-field
                if (mq.TLO.Me.Aura(2).Name() or "Twincast Aura") ~= "Twincast Aura" then mq.TLO.Me.Aura(2).Remove() end
            else --if we can only use one aura, we will get rid of the current one since we are missing the one we want.
                ---@diagnostic disable-next-line: undefined-field
                mq.TLO.Me.Aura(1).Remove()
            end
        end,
    },
    ['Rotations']     = {
        ['Downtime'] = {
            {
                name = "Orator's Unity",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName) return Casting.SelfBuffAACheck(aaName) end,
            },
            {
                name = "SelfGuardShield",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfRune1",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "MezBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfRune2",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Eldritch Rune",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Veil of Mindshadow",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName) return Casting.SelfBuffAACheck(aaName) end,
            },

            {
                name = "Azure Mind Crystal",
                type = "AA",
                active_cond = function(self, aaName) return mq.TLO.FindItem(aaName)() ~= nil end,
                cond = function(self, aaName) return mq.TLO.Me.PctMana() > 90 and not mq.TLO.FindItem(aaName)() end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.StashCrystal)
                    end
                end,
            },
            {
                name = "Gather Mana",
                type = "AA",
                cond = function(self, aaName) return mq.TLO.Me.PctMana() < 60 end,
            },
            {
                name = "LearnersAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.Name()) end,
                pre_activate = function(self) self.Helpers.AuraCheck() end,
                cond = function(self, spell)
                    return Config:GetSetting('DoLearners') and not Casting.AuraActiveByName(spell.Name())
                end,
            },
            {
                name = "TwincastAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.Name()) end,
                pre_activate = function(self) self.Helpers.AuraCheck() end,
                cond = function(self, spell)
                    -- don't use this if we selected learners and don't have two auras
                    if Config:GetSetting('DoLearners') and not Casting.CanUseAA('Auroria Mastery') then return false end
                    return not Casting.AuraActiveByName(spell.Name())
                end,
            },
            {
                name = "SpellProcAura",
                type = "Spell",
                active_cond = function(self, spell)
                    local aura = spell and auraSpellToName[spell.Name()] or "None"
                    return Casting.AuraActiveByName(aura)
                end,
                pre_activate = function(self) self.Helpers.AuraCheck() end,
                cond = function(self, spell)
                    -- don't use this if we have learner's selected, whether one aura or two
                    local useLearnersInstead = Config:GetSetting('DoLearners') and Core.GetResolvedActionMapItem('LearnersAura')
                    -- don't use this if we don't have Twincast Aura up unless we don't have Twincast Aura or can use two auras
                    local useTwinCastInstead = Core.GetResolvedActionMapItem('TwincastAura') and not Casting.CanUseAA('Auroria Mastery')

                    if not spell or not spell() or useLearnersInstead or useTwinCastInstead then return false end
                    -- get the proper aura name. Don't use rankname, the table doesn't support it. We are only searching the first word of the aura name.
                    local aura = auraSpellToName[spell.Name()]
                    return not Casting.AuraActiveByName(aura)
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                cond = function(self, spell) return Casting.ReagentCheck(spell) end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "PetBuffSpell",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.ID()).ID() end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('PetBuffSpell') end,
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.ID()).ID() end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },

        },
        ['GroupBuff'] = {
            {
                name = "ManaRegen",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupSpellShield",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupSpellShield') then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "GroupDotShield",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupDotShield') then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "GroupAuspiceBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupAuspice') then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "NdtBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    --Single target versions of the spell will only be used on Melee, group versions will be cast if they are missing from any groupmember
                    if not Config:GetSetting('DoNDTBuff') or ((spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target)) then return false end

                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SpellProcBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoProcBuff') or not Targeting.TargetIsACaster(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRune",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if Config:GetSetting('RuneChoice') ~= 2 or ((spell.Level() or 0) > 73 and Targeting.TargetIsTanking(target)) then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "AggroRune",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAggroRune') or not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleRune",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if Config:GetSetting('RuneChoice') ~= 1 then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
        },
        ['Dispel'] = {
            {
                name = "Eradicate Magic",
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
            {
                name = "Dispel",
                type = "Spell",
                cond = function(self, spell, target)
                    if Casting.CanUseAA("Eradicate Magic") then return false end
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['CombatSupport'] = {
            {
                name = "Glyph Spray",
                type = "AA",
                cond = function(self, aaName, target)
                    return ((Globals.AutoTargetIsNamed and target.Level() > mq.TLO.Me.Level()) or Core.GetMainAssistPctHPs() <= Config:GetSetting('EmergencyStart'))
                end,
            },
            {
                name = "Reactive Rune",
                type = "AA",
                cond = function(self, aaName, target)
                    return ((Globals.AutoTargetIsNamed and target.Level() > mq.TLO.Me.Level()) or Core.GetMainAssistPctHPs() <= Config:GetSetting('EmergencyStart'))
                end,
            },
            {
                name = "PBAEStunSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if (Config:GetSetting('DoAEStun') == 2 and Core.GetMainAssistPctHPs() > Config:GetSetting('EmergencyStart')) or Config:GetSetting('DoAEStun') == 1 then return false end
                    return Casting.DetSpellCheck(spell) and Targeting.GetXTHaterCount() >= Config:GetSetting('AECount')
                end,
            },

            {
                name = "Self Stasis",
                type = "AA",
                cond = function(self, aaName)
                    if Config:GetSetting('CharmOn') and mq.TLO.Me.Pet.ID() > 0 then return false end
                    return mq.TLO.Me.TargetOfTarget.ID() == mq.TLO.Me.ID() and mq.TLO.Target.ID() == Globals.AutoTargetID
                end,
                post_activate = function(self, aaName, success)
                    if not success then return end
                    mq.delay(1000, function() return mq.TLO.Me.Buff("Self Stasis")() ~= nil end)
                    if mq.TLO.Me.Buff("Self Stasis")() then
                        Comms.PrintGroupMessage("We're out of combat, removing the Self Stasis buff so we can act again.")
                        Core.DoCmd('/removebuff =Self Stasis')
                    end
                end,
            },
            -- { --This can interrupt spellcasting which can just make something worse. Let us trust healers and tanks.
            --     name = "Dimensional Instability",
            --     type = "AA",
            --     cond = function(self, aaName)
            --         return mq.TLO.Me.TargetOfTarget.ID() == mq.TLO.Me.ID() and mq.TLO.Target.ID() == Globals.AutoTargetID and mq.TLO.Me.PctHPs() <= 30
            --     end,
            -- },
            {
                name = "Beguiler's Directed Banishment",
                type = "AA",
                cond = function(self, aaName, target)
                    if target.ID() == Globals.AutoTargetID then return false end
                    return mq.TLO.Me.PctAggro() > 99 and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,

            },
            {
                name = "Beguiler's Banishment",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100) and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and mq.TLO.SpawnCount("npc radius 20")() > 2
                end,

            },
            {
                name = "Doppelganger",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100) and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            -- { --This can interrupt spellcasting which can just make something worse. Let us trust healers and tanks.
            --     name = "Dimensional Shield",
            --     type = "AA",
            --     cond = function(self, aaName)
            --         return mq.TLO.Me.TargetOfTarget.ID() == mq.TLO.Me.ID() and mq.TLO.Target.ID() == Globals.AutoTargetID and mq.TLO.Me.PctHPs() <= 80            --     end,

            -- },
            {
                name = "Arcane Whisper",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() >= 90
                end,

            },
            {
                name = "Silent Casting",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() >= 60
                end,

            },
        },
        ['DPS(Default)'] = {
            {
                name = "MindDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoMindDot') then return false end
                    return Casting.DotSpellCheck(spell) and (Globals.AutoTargetIsNamed or not Casting.IHaveBuff(spell and spell.Trigger()))
                end,
            },
            {
                name = "StrangleDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoStrangleDot') then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoNuke') then return false end
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ManaDrainNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoManaDrain') then return false end
                    return (target.CurrentMana() or 0) > 10 and Casting.OkayToNuke()
                end,
            },
            {
                name = "TwinCastMez",
                type = "Spell",
                cond = function(self, spell, target)
                    if Config:GetSetting('TwincastMez') ~= 3 or Modules:ExecModule("Mez", "IsMezImmune", target.ID()) then return false end
                    return not Casting.IHaveBuff(spell) and not mq.TLO.Me.Buff("Twincast")()
                end,
            },
        },
        ['DPS(ModernEra)'] = {
            {
                name = "DichoSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Casting.OkayToNuke()
                end,
            },
            {
                name = "MindDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            { --Mana check used instead of dot mana check because this is spammed like a nuke
                name = "StrangleDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            { --this is not an error, we want the spell twice in a row as part of the rotation.
                name = "StrangleDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            { --used when the chanter or group members are low mana
                name = "ManaTapNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return (mq.TLO.Group.LowMana(80)() or -1) > 1 or not Casting.HaveManaToNuke()
                end,
            },
            {
                name = "TwinCastMez",
                type = "Spell",
                cond = function(self, spell, target)
                    if Config:GetSetting('TwincastMez') ~= 3 or Modules:ExecModule("Mez", "IsMezImmune", target.ID()) then return false end
                    return not Casting.IHaveBuff(spell) and not mq.TLO.Me.Buff("Improved Twincast")()
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Illusions of Grandeur",
                type = "AA",
            },
            {
                name = "Improved Twincast",
                type = "AA",
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
            {
                name = "Calculated Insanity",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
            },
            {
                name = "Mental Contortion",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Chromatic Haze",
                type = "AA",
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
                name = "Spire of Enchantment",
                type = "AA",
                cond = function(self, aaName) return not Casting.IHaveBuff("Illusions of Grandeur") end,
            },
            {
                name = "Phantasmal Opponent",
                type = "AA",
            },
        },
        ['Tash'] = {
            {
                name = "Bite of Tashani",
                type = "AA",
                cond = function(self, aaName)
                    if Targeting.GetXTHaterCount() < Config:GetSetting('AECount') then return false end
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "TashSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (not Casting.TargetHasBuff("Bite of Tashani") or Globals.AutoTargetIsNamed)
                end,
            },
        },
        ['CripSlow'] = {
            {
                name = "Enveloping Helix",
                type = "AA",
                cond = function(self, aaName, target)
                    if Targeting.GetXTHaterCount() < Config:GetSetting('AECount') then return false end
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Slowing Helix",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSlow') then return false end
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and (aaSpell.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "CripSlowSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSlow') or not Casting.CanUseAA("Slowing Helix") then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "SlowSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSlow') or Casting.CanUseAA("Slowing Helix") or Core.GetResolvedActionMapItem('CripSlowSpell') then return false end
                    return Casting.DetSpellCheck(spell) and (spell.RankName.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "CrippleSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoCripple') or Casting.CanUseAA("Slowing Helix") or Core.GetResolvedActionMapItem('CripSlowSpell') then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
    },
    ['SpellList']     = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "TwinCastMez",      cond = function(self) return Config:GetSetting('DoSTMez') and Config:GetSetting('TwincastMez') > 1 end, },
                { name = "MezSpell",         cond = function(self) return Config:GetSetting('DoSTMez') and Config:GetSetting('TwincastMez') == 1 end, },
                { name = "MezAESpell",       cond = function(self) return Config:GetSetting('DoAEMez') end, },
                { name = "CharmDemand",      cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "CharmCommand",     cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "CharmSpell",       cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "TashSpell",        cond = function(self) return Config:GetSetting('DoTash') end, },
                { name = "CripSlowSpell",    cond = function(self) return (Config:GetSetting('DoSlow') or Config:GetSetting('DoCripple')) and not Casting.CanUseAA("Slowing Helix") end, },
                { name = "SlowSpell",        cond = function(self) return Config:GetSetting('DoSlow') and not Core.GetResolvedActionMapItem('CripSlowSpell') end, },
                { name = "CrippleSpell",     cond = function(self) return Config:GetSetting('DoCripple') and not Core.GetResolvedActionMapItem('CripSlowSpell') end, },
                { name = "PBAEStunSpell",    cond = function(self) return Config:GetSetting('DoAEStun') > 1 end, },
                { name = "NdtBuff",          cond = function(self) return Config:GetSetting('DoNDTBuff') end, },
                { name = "SpellProcBuff",    cond = function(self) return Config:GetSetting('DoProcBuff') end, },
                { name = "Dispel",           cond = function(self) return Config:GetSetting('DoDispel') and not Casting.CanUseAA("Eradicate Magic") end, },
                { name = "DichoSpell",       cond = function(self) return Core.IsModeActive("ModernEra") end, },
                { name = "MagicNuke",        cond = function(self) return Config:GetSetting('DoNuke') or Core.IsModeActive("ModernEra") end, },
                { name = "StrangleDot",      cond = function(self) return Config:GetSetting('DoStrangleDot') or Core.IsModeActive("ModernEra") end, },
                { name = "MindDot",          cond = function(self) return Config:GetSetting('DoMindDot') or Core.IsModeActive("ModernEra") end, },
                { name = "ManaTapNuke",      cond = function(self) return Core.IsModeActive("ModernEra") end, },
                { name = "ManaDrainNuke",    cond = function(self) return Config:GetSetting('DoManaDrain') and Core.IsModeActive("Default") end, },
                { name = "SingleRune",       cond = function(self) return Config:GetSetting('RuneChoice') == 1 end, },
                { name = "GroupRune",        cond = function(self) return Config:GetSetting('RuneChoice') == 2 end, },
                { name = "GroupAuspiceBuff", cond = function(self) return Config:GetSetting('DoGroupAuspice') end, },
                { name = "GroupSpellShield", cond = function(self) return Config:GetSetting('DoGroupSpellShield') end, },
                { name = "GroupDotShield",   cond = function(self) return Config:GetSetting('DoGroupDotShield') end, },
                { name = "AllianceSpell",    cond = function(self) return Config:GetSetting('DoAlliance') end, },
            },
        },
    },
    ['PullAbilities'] = {
        {
            id = 'TashSpell',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('TashSpell').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('TashSpell').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('TashSpell')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Dispel',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Dispel').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Dispel').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('Dispel')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig'] = {
        ['Mode']               = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this PC. Default: The original RGMercs Config. ModernEra: DPS rotation and spellset aimed at modern live play (~90+)",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What are the different Modes about?",
            Answer = "The Default Mode is the original RGMercs configuration designed for levels 1 - 90.\n" ..
                "ModernEra Mode is a DPS rotation and spellset aimed at modern live play (~90+).\n" ..
                "The ModernEra Mode is designed to be used with the ModernEra DPS rotation and spellset.\n" ..
                "It should function well starting around level 90, but may not fully come into its own for a few levels after.",
        },

        --Buffs
        ['DoLearners']         = {
            DisplayName = "Do Learners",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Set to use the Learner's Aura instead of the Mana Regen Aura.",
            Default = false,
            FAQ = "How do I use my Learner's Aura?",
        },
        ['RuneChoice']         = {
            DisplayName = "Rune Selection:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Select which line of Rune spells you prefer to use.\nPlease note that after level 73, the group rune has a built-in hate reduction when struck.",
            Type = "Combo",
            ComboOptions = { 'Single Target', 'Group', 'Off', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
            FAQ = "Why am I putting an aggro-reducing buff on the tank?",
            Answer =
            "You can configure your rune selections to use a single-target hate increasing rune on the tank, while using group (hate reducing) or single target runes on others.",
        },
        ['DoAggroRune']        = {
            DisplayName = "Do Aggro Rune",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Enable casting the Tank Aggro Rune",
            Default = true,
        },
        ['DoGroupSpellShield'] = {
            DisplayName = "Do Group Spellshield",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Enable casting the Group Spell Shield Line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoGroupDotShield']   = {
            DisplayName = "Do Group DoT Shield",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Enable casting the Group DoT Shield Line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoGroupAuspice']     = {
            DisplayName = "Do Group Auspice",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Enable casting the Group Auspice Buff Line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoProcBuff']         = {
            DisplayName = "Do Spellproc Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Enable casting the spell proc (Mana ... ) line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoNDTBuff']          = {
            DisplayName = "Cast NDT",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Enable casting use Melee Proc Buff (Night's Dark Terror Line).",
            RequiresLoadoutChange = true,
            Default = true,
        },

        --Debuffs
        ['DoTash']             = {
            DisplayName = "Do Tash",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Tooltip = "Cast Tash Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSlow']             = {
            DisplayName = "Cast Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Tooltip = "Enable casting Slow spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoCripple']          = {
            DisplayName = "Cast Cripple",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Tooltip = "Enable casting Cripple spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoDispel']           = {
            DisplayName = "Do Dispel",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Dispel",
            Tooltip = "Enable removing beneficial enemy effects.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        --Combat
        ['AECount']            = {
            DisplayName = "AE Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Debuff Rules",
            Index = 101,
            Tooltip = "Number of XT Haters before we will use AE Slow, Tash, or Stun.",
            Min = 1,
            Default = 3,
            Max = 15,
        },
        ['DoAEStun']           = {
            DisplayName = "PBAE Stun use:",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "When to use your PBAE Stun Line.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'At low MA health', 'Whenever Possible', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['TwincastMez']        = {
            DisplayName = "TwinCast Mez Usage:",
            Group = "Abilities",
            Header = "Mez",
            Category = "Mez General",
            Index = 101,
            Tooltip = "If selected, will replace the standard ST Mez with an option that gives a DD twincast effect.",
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Disabled', 'As ST Mez', 'As Mez and to Trigger Twincast', },
            Default = 1,
            Min = 1,
            Max = 3,
            FAQ = "Can you explain TwinCast Mez usage in more detail?",
            Answer =
                "Disabled: We will use our standard ST Mez in Gem 1.\n" ..
                "As ST Mez: We will use the Twincast Mez as our ST Mez in Gem 1.\n" ..
                "As Mez and to Trigger Twincast: As above and we will also use this spell in combat to trigger the twincast effect.",
        },
        ['EmergencyStart']     = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "The HP % emergency abilities will be used (Abilities used depend on whose health is low, the ENC or the MA).",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoChestClick']       = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your equipped chest item during burns.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },

        --DPS Low Level
        ['DoNuke']             = {
            DisplayName = "Magic Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your magic nuke in the Default early/midgame DPS rotation.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoManaDrain']        = {
            DisplayName = "Mana Drain Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your mana drain nuke in the Default early/midgame DPS rotation.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoStrangleDot']      = {
            DisplayName = "Strangle Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your magic damage (Strangle Line) Dot in the Default early/midgame DPS rotation.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoMindDot']          = {
            DisplayName = "Mind Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your mana drain/magic damage (Mind Line) Dot on Named in the Default early/midgame DPS rotation.",
            RequiresLoadoutChange = true,
            Default = true,
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

return _ClassConfig
