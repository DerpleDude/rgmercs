local mq           = require('mq')
local Casting      = require("utils.casting")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "1.1 - Live",
    _author               = "Derple, Grimmier",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring  = function() return Config:GetSetting('DoCures') end,
        IsRezing  = function()
            return (Core.GetResolvedActionMapItem('RezSpell') and Targeting.GetXTHaterCount() == 0) or
                (Casting.CanUseAA("Call of the Wild") and Config:GetSetting('DoBattleRez'))
        end,
        CanCharm  = function() return true end,
    },
    ['Rez']               = {
        ['Combat'] = {
            { type = "Item", name = "Staff of Forbidden Rites", },
            {
                type = "AA",
                name = "Call of the Wild",
                cond = function(self, spell, target, ownerName)
                    return not mq.TLO.Spawn(string.format("PC =%s", ownerName or ""))()
                end,
            },
        },
        ['Downtime'] = {
            { type = "AA", name = "Rejuvenation of Spirit", },
            {
                type = "Spell",
                name = "RezSpell",
                cond = function(self, spell, target)
                    return Casting.DowntimeRezOkay()
                end,
            },
        },
    },
    ['Modes']             = {
        'Heal',
        'Mana',
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
        },
        ['Poison'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'SingleTgtCure', }) end, },
        },
        ['Disease'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'SingleTgtCure', }) end, },
        },
        ['Curse'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'SingleTgtCure', }) end, },
        },
        ['Corruption'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'CureCorrupt', 'SingleTgtCure', }) end, },
        },
    },
    ['Themes']            = {
        ['Heal'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.08, g = 0.40, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.08, g = 0.40, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.03, g = 0.16, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.08, g = 0.40, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.08, g = 0.40, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.03, g = 0.16, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.08, g = 0.40, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.08, g = 0.40, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.08, g = 0.40, b = 0.08, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.05, g = 0.26, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.08, g = 0.40, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.08, g = 0.40, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.08, g = 0.40, b = 0.08, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.03, g = 0.16, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.40, g = 0.90, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.40, g = 0.90, b = 0.20, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.08, g = 0.40, b = 0.08, a = 1.0, }, },
        },
        ['Mana'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.20, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.20, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.08, g = 0.14, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.20, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.20, g = 0.35, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.08, g = 0.14, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.20, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.20, g = 0.35, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.20, g = 0.35, b = 0.05, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.13, g = 0.22, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.20, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.20, g = 0.35, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.20, g = 0.35, b = 0.05, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.08, g = 0.14, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.55, g = 0.80, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.55, g = 0.80, b = 0.15, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.20, g = 0.35, b = 0.05, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Staff of Living Brambles",
            "Staff of Everliving Brambles",
        },
    },
    ['AbilitySets']       = {
        ['Alliance'] = {
            --, Buff >= LVL102
            "Ferntender's Covariance",  -- Level 125
            "Arboreal Atonement",       -- Level 120
            "Arbor Tender's Coalition", -- Level 115
            "Bosquetender's Alliance",  -- Level 102
        },
        ['FireAura'] = {
            -- Spell Series >= 87LVL Minimum
            "Wildspark Aura", -- Level 97
            "Wildblaze Aura", -- Level 92
            "Wildfire Aura",  -- Level 87
        },
        ['IceAura'] = {
            -- Spell Series >= 88LVL Minimum -- Only Heroic Aura that will be used
            "Frostfell Aura IX", -- Level 128
            "Coldburst Aura",    -- Level 123
            "Nightchill Aura",   -- Level 118
            "Icerend Aura",      -- Level 113
            "Frostreave Aura",   -- Level 108
            "Frostweave Aura",   -- Level 103
            "Frostone Aura",     -- Level 98
            "Frostcloak Aura",   -- Level 93
            "Frostfell Aura",    -- Level 88
        },
        ['HealingAura'] = {
            -- Healing Aura >= 55
            "Aura of Life",      -- Level 70
            "Aura of the Grove", -- Level 55
        },
        ['SingleTgtCure'] = {
            -- Single Target Multi-Cure >= 84
            "Mastery: Sanctified Blood", -- Level 128
            "Sanctified Blood",          -- Level 118
            "Expurgated Blood",          -- Level 108
            "Unblemished Blood",         -- Level 103
            "Cleansed Blood",            -- Level 99
            "Perfected Blood",           -- Level 94
            "Purged Blood",              -- Level 89
            "Purified Blood",            -- Level 84
        },
        ['CureCorrupt'] = {
            "Mastery: Chant of the Zelniak", -- Level 127
            "Chant of the Zelniak",          -- Level 117
            "Chant of the Wulthan",          -- Level 107
            "Chant of the Kromtus",          -- Level 102
            "Chant of Jaerol",               -- Level 99
            "Chant of the Izon",             -- Level 94
            "Chant of the Tae Ew",           -- Level 89
            "Chant of the Burynai",          -- Level 84
            "Chant of the Darkvine",         -- Level 79
            "Chant of the Napaea",           -- Level 64
            "Cure Corruption",               -- Level 61
        },
        ['GroupCure'] = {
            -- Group Multi-Cure >=91
            "Mastery: Nightwhisper's Breeze", -- Level 126
            "Nightwhisper's Breeze",          -- Level 116
            "Wildtender's Breeze",            -- Level 106
            "Copsetender's Breeze",           -- Level 101
            "Bosquetender's Breeze",          -- Level 96
            "Fawnwalker's Breeze",            -- Level 91
        },
        ['CharmSpell'] = {
            -- Charm Spells >= 14
            "Beast's Beckoning XVIII", -- Level 126
            "Beast's Bestowing",       -- Level 121
            "Beast's Bellowing",       -- Level 116
            "Beast's Beseeching",      -- Level 106
            "Beast's Bidding",         -- Level 101
            "Beast's Bespelling",      -- Level 96
            "Beast's Behest",          -- Level 91
            "Beast's Beguiling",       -- Level 86
            "Beast's Befriending",     -- Level 81
            "Beast's Bewitching",      -- Level 76
            "Beast's Beckoning",       -- Level 71
            "Beast's Beckoning",       -- Level 71
            "Nature's Beckon",         -- Level 70
            "Command of Tunare",       -- Level 63
            "Tunare's Request",        -- Level 55
            "Call of Karana",          -- Level 52
            "Allure of the Wild",      -- Level 43
            "Beguile Animals",         -- Level 33
            "Charm Animals",           -- Level 23
            "Befriend Animal",         -- Level 13
        },
        ['QuickHealSurge'] = {
            -- Main Quick heal >=75
            "Adrenaline Surge XII", -- Level 129
            "Adrenaline Fury",      -- Level 124
            "Adrenaline Spate",     -- Level 119
            "Adrenaline Spate",     -- Level 119
            "Adrenaline Deluge",    -- Level 114
            "Adrenaline Barrage",   -- Level 109
            "Adrenaline Torrent",   -- Level 104
            "Adrenaline Rush",      -- Level 100
            "Adrenaline Flood",     -- Level 95
            "Adrenaline Blast",     -- Level 90
            "Adrenaline Burst",     -- Level 85
            "Adrenaline Swell",     -- Level 80
            "Adrenaline Surge",     -- Level 75
        },
        ['QuickHeal'] = {
            -- Backup Quick heal >= LVL90
            "Rejuvilation IX", -- Level 130
            "Resuscitation",   -- Level 125
            "Sootheseance",    -- Level 120
            "Sootheseance",    -- Level 120
            "Rejuvenescence",  -- Level 115
            "Revitalization",  -- Level 110
            "Resurgence",      -- Level 105
            "Vivification",    -- Level 100
            "Invigoration",    -- Level 95
            "Rejuvilation",    -- Level 90
        },
        ['LongHeal'] = {
            -- Long Heal >= 1 -- skipped 10s cast heals.
            "Puravida XI",       -- Level 127
            "Vivavida",          -- Level 122
            "Clotavida",         -- Level 117
            "Viridavida",        -- Level 112
            "Curavida",          -- Level 107
            "Panavida",          -- Level 102
            "Sterivida",         -- Level 97
            "Sanavida",          -- Level 92
            "Benevida",          -- Level 87
            "Granvida",          -- Level 82
            "Puravida",          -- Level 77
            "Pure Life",         -- Level 72
            "Chlorotrope",       -- Level 68
            "Sylvan Infusion",   -- Level 65
            "Nature's Infusion", -- Level 63
            "Nature's Touch",    -- Level 60
            "Chloroblast",       -- Level 55
            "Forest's Renewal",  -- Level 49
            "Superior Healing",  -- Level 44
            "Nature's Renewal",  -- Level 39
            "Healing Water",     -- Level 34
            "Greater Healing",   -- Level 29
            "Healing",           -- Level 19
            "Light Healing",     -- Level 9
            "Minor Healing",     -- Level 1
        },
        ['QuickGroupHeal'] = {
            -- Quick Group heal >= LVL78
            "Survival of the Fittest XI",    -- Level 128
            "Survival of the Heroic",        -- Level 123
            "Survival of the Unrelenting",   -- Level 118
            "Survival of the Unrelenting",   -- Level 118
            "Survival of the Favored",       -- Level 113
            "Survival of the Auspicious",    -- Level 108
            "Survival of the Serendipitous", -- Level 103
            "Survival of the Fortuitous",    -- Level 98
            "Survival of the Prosperous",    -- Level 93
            "Survival of the Propitious",    -- Level 88
            "Survival of the Felicitous",    -- Level 83
            "Survival of the Fittest",       -- Level 78
        },
        ['LongGroupHeal'] = {
            -- Long Group heal >= LVL 70
            "Lunamend",        -- Level 130
            "Lunacea",         -- Level 125
            "Lunarush",        -- Level 120
            "Lunarush",        -- Level 120
            "Lunalesce",       -- Level 115
            "Lunasalve",       -- Level 110
            "Lunasoothe",      -- Level 105
            "Lunassuage",      -- Level 100
            "Lunalleviation",  -- Level 95
            "Lunamelioration", -- Level 90
            "Lunulation",      -- Level 85
            "Crescentbloom",   -- Level 80
            "Lunarlight",      -- Level 75
            "Moonshadow",      -- Level 70
        },
        ['PromHeal'] = {
            -- Promised Heals Line Druid
            "Promised Reknit X",       -- Level 127
            "Promised Regrowth",       -- Level 122
            "Promised Revivification", -- Level 117
            "Promised Refreshment",    -- Level 112
            "Promised Rebirth",        -- Level 107
            "Promised Regeneration",   -- Level 102
            "Promised Recovery",       -- Level 97
            "Promised Revitalization", -- Level 92
            "Promised Replenishment",  -- Level 87
            "Promised Reknit",         -- Level 82
        },
        ['FrostDebuff'] = {
            -- Frost Debuff Series -- >= 74LVL -- On Bar
            "Gelid Frost XI",   -- Level 129
            "Mythic Frost",     -- Level 124
            "Primal Frost",     -- Level 119
            "Restless Frost",   -- Level 114
            "Glistening Frost", -- Level 109
            "Moonbright Frost", -- Level 104
            "Lustrous Frost",   -- Level 99
            "Silver Frost",     -- Level 94
            "Argent Frost",     -- Level 89
            "Blanched Frost",   -- Level 84
            "Gelid Frost",      -- Level 79
            "Hoar Frost",       -- Level 74
        },
        ['RoDebuff'] = {
            -- Ro Debuff Series -- >= 37LVL -- AA Starts at LVL (Single Target) -- On Bar Until AA
            "Grasp of Ro IX",              -- Level 126
            "Clench of Ro",                -- Level 121
            "Cinch of Ro",                 -- Level 116
            "Clasp of Ro",                 -- Level 111
            "Cowl of Ro",                  -- Level 106
            "Cowl of Ro",                  -- Level 106
            "Crush of Ro",                 -- Level 101
            "Clutch of Ro",                -- Level 96
            "Grip of Ro",                  -- Level 91
            "Grasp of Ro",                 -- Level 86
            "Sun's Corona",                -- Level 67
            "Ro's Illumination",           -- Level 62
            "Ro's Smoldering Disjunction", -- Level 56
            "Fixation of Ro",              -- Level 42
            "Ro's Fiery Sundering",        -- Level 37
        },
        ['RoDebuffAE'] = {
            -- Ro AE Debuff Series -- >= 97LVL -- AA Starts at LVL
            "Pillar of Ro VII", -- Level 127
            "Visage of Ro",     -- Level 122
            "Scrutiny of Ro",   -- Level 117
            "Glare of Ro",      -- Level 112
            "Gaze of Ro",       -- Level 107
            "Column of Ro",     -- Level 102
            "Pillar of Ro",     -- Level 97
        },
        ['IceBreathDebuff'] = {
            -- Ice Breath Series >= 63LVL -- On Bar
            "Glacier Breath XIV",   -- Level 127
            "Algid Breath",         -- Level 122
            "Twilight Breath",      -- Level 117
            "Icerend Breath",       -- Level 112
            "Frostreave Breath",    -- Level 107
            "Blizzard Breath",      -- Level 102
            "Frosthowl Breath",     -- Level 97
            "Encompassing Breath",  -- Level 92
            "Bracing Breath",       -- Level 87
            "Coldwhisper Breath",   -- Level 82
            "Chillvapor Breath",    -- Level 77
            "Icefall Breath",       -- Level 72
            "Glacier Breath",       -- Level 67
            "E`ci's Frosty Breath", -- Level 63
        },
        ['SkinDebuff'] = {
            -- Skin Debuff Series >= 73LVL -- On Bar
            "Skin to Lichen",    -- Level 118
            "Skin to Sumac",     -- Level 108
            "Skin to Seedlings", -- Level 98
            "Skin to Foliage",   -- Level 93
            "Skin to Leaves",    -- Level 88
            "Skin to Flora",     -- Level 83
            "Skin to Mulch",     -- Level 78
            "Skin to Vines",     -- Level 73
        },
        ['ReptileCombatInnate'] = {
            -- Reptile Combat Innate >= 68LVL -- On Bar
            "Skin of the Reptile XII", -- Level 129
            "Chitin of the Reptile",   -- Level 124
            "Bulwark of the Reptile",  -- Level 119
            "Defense of the Reptile",  -- Level 114
            "Guard of the Reptile",    -- Level 109
            "Pellicle of the Reptile", -- Level 104
            "Husk of the Reptile",     -- Level 99
            "Hide of the Reptile",     -- Level 94
            "Shell of the Reptile",    -- Level 89
            "Carapace of the Reptile", -- Level 84
            "Scales of the Reptile",   -- Level 79
            "Skin of the Reptile",     -- Level 68
        },
        ['NaturesWrathDot'] = {
            -- Natures Wrath DOT Line >= 75LVL -- On Bar
            "Nature's Blazing Wrath XII",  -- Level 130
            "Nature's Boiling Wrath",      -- Level 125
            "Nature's Sweltering Wrath",   -- Level 120
            "Nature's Fervid Wrath",       -- Level 115
            "Nature's Blistering Wrath",   -- Level 110
            "Nature's Fiery Wrath",        -- Level 105
            "Nature's Withering Wrath",    -- Level 100
            "Nature's Scorching Wrath",    -- Level 95
            "Nature's Incinerating Wrath", -- Level 90
            "Nature's Searing Wrath",      -- Level 85
            "Nature's Burning Wrath",      -- Level 80
            "Nature's Blazing Wrath",      -- Level 75
        },
        ['HordeDot'] = {
            "Horde of Spitewasps",   -- Level 128
            "Horde of Hotaria",      -- Level 123
            "Horde of Duskwigs",     -- Level 118
            "Horde of Hyperboreads", -- Level 113
            "Horde of Polybiads",    -- Level 108
            "Horde of Aculeids",     -- Level 103
            "Horde of Mutillids",    -- Level 98
            "Horde of Vespids",      -- Level 93
            "Horde of Scoriae",      -- Level 88
            "Horde of the Hive",     -- Level 83
            "Horde of Fireants",     -- Level 78
            "Swarm of Fireants",     -- Level 73
            "Wasp Swarm",            -- Level 68
            "Swarming Death",        -- Level 63
            "Winged Death",          -- Level 53
            "Drifting Death",        -- Level 40
            "Drones of Doom",        -- Level 32
            "Creeping Crud",         -- Level 24
            "Stinging Swarm",        -- Level 10
        },
        ['SunDot'] = {
            -- SUN Dot Line >= 49LVL -- On Bar
            "Sunscorch XII",         -- Level 129
            "Sunscald",              -- Level 124
            "Sunpyre",               -- Level 119
            "Sunshock",              -- Level 114
            "Sunflame",              -- Level 109
            "Sunflash",              -- Level 104
            "Sunblaze",              -- Level 99
            "Sunbrand",              -- Level 89
            "Sunsinge",              -- Level 84
            "Sunsear",               -- Level 79
            "Sunscorch",             -- Level 74
            "Sunscorch",             -- Level 74
            "Vengeance of the Sun",  -- Level 69
            "Vengeance of Tunare",   -- Level 64
            "Vengeance of Nature",   -- Level 55
            "Vengeance of the Wild", -- Level 49
        },
        ['MoonbeamDot'] = {
            "Gelid Moonbeam IX",    -- Level 129
            "Mythical Moonbeam",    -- Level 124
            "Onyx Moonbeam",        -- Level 119
            "Opaline Moonbeam",     -- Level 114
            "Pearlescent Moonbeam", -- Level 109
            "Argent Moonbeam",      -- Level 104
            "Frigid Moonbeam",      -- Level 99
            "Algid Moonbeam",       -- Level 94
            "Gelid Moonbeam",       -- Level 89
        },
        ['SunrayDot'] = {
            "Blistering Sunray XII", -- Level 126
            "Searing Sunray",        -- Level 121
            "Tenebrous Sunray",      -- Level 116
            "Erupting Sunray",       -- Level 111
            "Overwhelming Sunray",   -- Level 106
            "Consuming Sunray",      -- Level 101
            "Incinerating Sunray",   -- Level 96
            "Blazing Sunray",        -- Level 91
            "Scorching Sunray",      -- Level 86
            "Withering Sunray",      -- Level 81
            "Torrid Sunray",         -- Level 76
            "Blistering Sunray",     -- Level 71
            "Immolation of the Sun", -- Level 67
            "Sylvan Embers",         -- Level 65
            "Immolation of Ro",      -- Level 62
            "Breath of Ro",          -- Level 52
            "Immolate",              -- Level 25
            "Flame Lick",            -- Level 1
        },
        ['RemoteMoonDD'] = {
            -- Remote Moon DD >= 99LVL
            "Remote Moonfire VII", -- Level 129
            "Remote Moonshiver",   -- Level 124
            "Remote Moonchill",    -- Level 119
            "Remote Moonrake",     -- Level 114
            "Remote Moonflash",    -- Level 109
            "Remote Moonflame",    -- Level 104
            "Remote Moonfire",     -- Level 99
        },
        ['RemoteSunDD'] = {
            -- Remote Sun DD >= 83LVL
            "Remote Sunflare X", -- Level 130
            "Remote Sunscorch",  -- Level 123
            "Remote Sunbolt",    -- Level 118
            "Remote Sunshock",   -- Level 113
            "Remote Sunblaze",   -- Level 108
            "Remote Sunflash",   -- Level 103
            "Remote Sunfire",    -- Level 98
            "Remote Sunburst",   -- Level 93
            "Remote Sunflare",   -- Level 88
            "Remote Manaflux",   -- Level 83
        },
        ['RoarDD'] = {
            -- Roar DD >= 93LVL
            "Katabatic Roar VIII", -- Level 128
            "Tempest Roar",        -- Level 123
            "Bloody Roar",         -- Level 118
            "Typhonic Roar",       -- Level 113
            "Cyclonic Roar",       -- Level 108
            "Anabatic Roar",       -- Level 103
            "Katabatic Roar",      -- Level 98
            "Roar of Kolos",       -- Level 93
        },
        ['QuickRoarDD'] = {
            -- Quick Cast Roar Series -- will be replaced by roar at lvl 93
            "Shattering of the Stormborn",  -- Level 126
            "Revelry of the Stormborn",     -- Level 121
            "Bedlam of the Stormborn",      -- Level 116
            "Maelstrom of the Stormborn",   -- Level 111
            "Thunderbolt of the Stormborn", -- Level 106
            "Typhoon of the Stormborn",     -- Level 101
            "Whirlwind of the Stormborn",   -- Level 96
            "Cyclone of the Stormborn",     -- Level 91
            "Shear of the Stormborn",       -- Level 86
            "Squall of the Stormborn",      -- Level 81
            "Tempest of the Stormborn",     -- Level 76
            "Gale of the Stormborn",        -- Level 71
            "Stormwatch",                   -- Level 66
            "Storm's Fury",                 -- Level 61
            "Dustdevil",                    -- Level 43
            "Fury of Air",                  -- Level 30
        },
        ['DichoSpell'] = {
            -- Dicho Spell >= 101LVL
            "Reciprocal Winds", -- Level 121
            "Ecliptic Winds",   -- Level 116
            "Composite Winds",  -- Level 111
            "Dissident Winds",  -- Level 106
            "Dichotomic Winds", -- Level 101
        },
        ['WinterFireDD'] = {
            -- Winters Fire DD Line >= 73LVL -- Using for Low level Fire DD as well
            "Winter's Wildflame XII", -- Level 128
            "Winter's Wildgale",      -- Level 123
            "Winter's Wildbrume",     -- Level 118
            "Winter's Wildshock",     -- Level 113
            "Winter's Wildblaze",     -- Level 108
            "Winter's Wildflame",     -- Level 103
            "Winter's Wildfire",      -- Level 98
            "Winter's Sear",          -- Level 93
            "Winter's Pyre",          -- Level 88
            "Winter's Flare",         -- Level 83
            "Winter's Blaze",         -- Level 78
            "Winter's Flame",         -- Level 73
            "Solstice Strike",        -- Level 69
            "Sylvan Fire",            -- Level 65
            "Summer's Flame",         -- Level 64
            "Wildfire",               -- Level 59
            "Scoriae",                -- Level 54
            "Starfire",               -- Level 48
            "Firestrike",             -- Level 38
            "Combust",                -- Level 28
            "Ignite",                 -- Level 8
            "Burst of Fire",          -- Level 3
            "Burst of Flame",         -- Level 1
        },
        ['ChillDot'] = {
            -- Chill DOT Line -- >= 95LVL -- Used for Burns
            "Chill of the Grovetender",     -- Level 130
            "Chill of the Ferntender",      -- Level 125
            "Chill of the Dusksage Tender", -- Level 120
            "Chill of the Arbor Tender",    -- Level 115
            "Chill of the Wildtender",      -- Level 110
            "Chill of the Copsetender",     -- Level 105
            "Chill of the Visionary",       -- Level 100
            "Chill of the Natureward",      -- Level 95
        },
        ['RootSpells'] = {
            -- Root Spells
            "Vinelash Assault", -- Level 97
            "Vinelash Cascade", -- Level 72
            "Spore Spiral",     -- Level 69
            "Savage Roots",     -- Level 64
            "Earthen Roots",    -- Level 61
            "Entrapping Roots", -- Level 60
            "Engorging Roots",  -- Level 56
            "Engulfing Roots",  -- Level 45
            "Enveloping Roots", -- Level 36
            "Ensnaring Roots",  -- Level 21
            "Grasping Roots",   -- Level 2
        },
        ['SnareSpell'] = {
            -- Snare Spells
            "Thornmaw Vines",  -- Level 97
            "Serpent Vines",   -- Level 69
            "Entangle",        -- Level 61
            "Mire Thorns",     -- Level 61
            "Bonds of Tunare", -- Level 57
            "Ensnare",         -- Level 26
            "Snare",           -- Level 1
            "Tangling Weeds",  -- Level 1
        },
        ['TwinHealNuke'] = {
            "Sundew Blessing X",  -- Level 128
            "Sunbliss Blessing",  -- Level 123
            "Sunwarmth Blessing", -- Level 119
            "Sunrake Blessing",   -- Level 114
            "Sunflash Blessing",  -- Level 109
            "Sunfire Blessing",   -- Level 104
            "Sunbeam Blessing",   -- Level 99
            "Sunbreeze Blessing", -- Level 94
            "Sunrise Blessing",   -- Level 89
            "Sundew Blessing",    -- Level 84
        },
        ['IceNuke'] = {
            "Rime Crystals XII",      -- Level 130
            "Coldbite Crystals",      -- Level 125
            "Moonwhisper Crystals",   -- Level 120
            "Icerend Crystals",       -- Level 115
            "Frostreave Crystals",    -- Level 110
            "Frostweave Crystals",    -- Level 105
            "Gelid Crystals",         -- Level 100
            "Sterlingfrost Crystals", -- Level 95
            "Argent Crystals",        -- Level 90
            "Glaciating Crystals",    -- Level 85
            "Hoar Crystals",          -- Level 80
            "Rime Crystals",          -- Level 75
            "Glitterfrost",           -- Level 70
            "Winter's Frost",         -- Level 65
            "Moonfire",               -- Level 60
            "Frost",                  -- Level 55
            "Ice",                    -- Level 47
        },
        ['IceRainNuke'] = {
            "Cascade of Hail XVIII", -- Level 127
            "Unrelenting Hail",      -- Level 121
            "Howling Hail",          -- Level 116
            "Tempestuous Hail",      -- Level 111
            "Plunging Hail",         -- Level 106
            "Plummeting Hail",       -- Level 101
            "Hailstorm",             -- Level 96
            "Crashing Hail",         -- Level 91
            "Cyclonic Hail",         -- Level 86
            "Cascading Hail",        -- Level 81
            "Torrential Hail",       -- Level 76
            "Cloudburst Hail",       -- Level 71
            "Tempest Wind",          -- Level 66
            "Winter's Storm",        -- Level 61
            "Blizzard",              -- Level 54
            "Avalanche",             -- Level 37
            "Pogonip",               -- Level 22
            "Cascade of Hail",       -- Level 12
        },
        ['ShroomPet'] = {
            --Druid Mushroom DOT Pet Line >= 84LVL --used for mana savings
            "Mycelid Assault",      -- Level 124
            "Saprophyte Assault",   -- Level 119
            "Chytrid Assault",      -- Level 114
            "Fungusoid Assault",    -- Level 109
            "Sporali Storm",        -- Level 104
            "Sporali Assault",      -- Level 99
            "Myconid Assault",      -- Level 94
            "Polyporous Assault",   -- Level 89
            "Blast of Hypergrowth", -- Level 84
        },
        ['IceDD'] = {
            -- Ice Nuke DD --Gap Filler
            "Moonfire", -- Level 60
            "Frost",    -- Level 55
        },
        ['SelfShield'] = {
            -- Self Shield Buff
            "Brackenbriar Coat", -- Level 128
            "Bramblespike Coat", -- Level 123
            "Shadespine Coat",   -- Level 118
            "Icebriar Coat",     -- Level 113
            "Daggerspike Coat",  -- Level 108
            "Daggerspur Coat",   -- Level 103
            "Spikethistle Coat", -- Level 98
            "Spineburr Coat",    -- Level 93
            "Bonebriar Coat",    -- Level 88
            "Brierbloom Coat",   -- Level 83
            "Viridithorn Coat",  -- Level 78
            "Viridicoat",        -- Level 73
            "Nettlecoat",        -- Level 68
            "Brackencoat",       -- Level 64
            "Bladecoat",         -- Level 56
            "Thorncoat",         -- Level 47
            "Spikecoat",         -- Level 37
            "Bramblecoat",       -- Level 27
            "Barbcoat",          -- Level 17
            "Thistlecoat",       -- Level 7
        },
        ['SelfManaRegen'] = {
            -- Self mana Regen Buff
            "Mask of the Grovetender",     -- Level 130
            "Mask of the Ferntender",      -- Level 125
            "Mask of the Dusksage Tender", -- Level 120
            "Mask of the Arbor Tender",    -- Level 115
            "Mask of the Wildtender",      -- Level 110
            "Mask of the Copsetender",     -- Level 105
            "Mask of the Bosquetender",    -- Level 100
            "Mask of the Thicket Dweller", -- Level 95
            "Mask of the Arboreal",        -- Level 90
            "Mask of the Raptor",          -- Level 85
            "Mask of the Shadowcat",       -- Level 80
            "Mask of the Wild",            -- Level 70
            "Mask of the Forest",          -- Level 65
            "Mask of the Stalker",         -- Level 60
            "Mask of the Hunter",          -- Level 60
        },
        ['HPTypeOne'] = {
            "Grovewood Blessing",         -- Level 127
            "Emberquartz Blessing",       -- Level 125
            "Luclinite Blessing",         -- Level 120
            "Opaline Blessing",           -- Level 115
            "Arcronite Blessing",         -- Level 110
            "Shieldstone Blessing",       -- Level 105
            "Granitebark Blessing",       -- Level 100
            "Stonebark Blessing",         -- Level 95
            "Blessing of the Timbercore", -- Level 90
            "Blessing of the Heartwood",  -- Level 85
            "Blessing of the Ironwood",   -- Level 80
            "Blessing of the Direwild",   -- Level 75
            "Blessing of Steeloak",       -- Level 70
            "Blessing of the Nine",       -- Level 65
            "Protection of the Glades",   -- Level 60 Group (All above, also group)
            "Natureskin",                 -- Level 57 Single
            "Protection of Nature",       -- Level 49 Group
            "Skin like Nature",           -- Level 46 Single
            "Protection of Diamond",      -- Level 39 Group
            "Skin like Diamond",          -- Level 36 Single
            "Protection of Steel",        -- Level 27 Group
            "Skin like Steel",            -- Level 24 Single
            "Protection of Rock",         -- Level 19 Group
            "Skin like Rock",             -- Level 14 Single
            "Protection of Wood",         -- Level 9 Group
            "Skin like Wood",             -- Level 1 Single
        },
        ['TempHPBuff'] = {
            -- Temp Health -- Focus on Tank
            "Wild Growth X",       -- Level 127
            "Overwhelming Growth", -- Level 122
            "Fervent Growth",      -- Level 117
            "Frenzied Growth",     -- Level 112
            "Savage Growth",       -- Level 107
            "Ferocious Growth",    -- Level 102
            "Rampant Growth",      -- Level 97
            "Unfettered Growth",   -- Level 92
            "Untamed Growth",      -- Level 87
            "Wild Growth",         -- Level 82
        },
        ['GroupRegenBuff'] = {
            -- Group Regen BuffAll Have Long Duration HP Regen Buffs. Not Short term Heal.
            "Talisman of Perseverance XV",   -- Level 126
            "Talisman of the Unforgettable", -- Level 124
            "Talisman of the Tenacious",     -- Level 119
            "Talisman of the Enduring",      -- Level 114
            "Talisman of the Unwavering",    -- Level 109
            "Talisman of the Faithful",      -- Level 104
            "Talisman of the Steadfast",     -- Level 99
            "Talisman of the Indomitable",   -- Level 94
            "Talisman of the Relentless",    -- Level 89
            "Talisman of the Resolute",      -- Level 84
            "Talisman of the Stalwart",      -- Level 79
            "Blessing of Oak",               -- Level 69
            "Blessing of Replenishment",     -- Level 63
            "Regrowth of the Grove",         -- Level 58
            "Pack Chloroplast",              -- Level 45
            "Pack Regeneration",             -- Level 39
        },
        ['AtkBuff'] = {
            -- Single Target Attack Buff for MeleeGuard
            "Mammoth's Force",    -- Level 86
            "Mammoth's Strength", -- Level 71
            "Lion's Strength",    -- Level 67
            "Nature's Might",     -- Level 62
            "Girdle of Karana",   -- Level 55
            "Storm Strength",     -- Level 44
            "Strength of Stone",  -- Level 34
            "Strength of Earth",  -- Level 7
        },
        ['GroupDmgShield'] = {
            -- Group Damage Shield -- Focus on the tank
            "Legacy of Brackenbriars", -- Level 127
            "Legacy of Bramblespikes", -- Level 125
            "Legacy of Bloodspikes",   -- Level 120
            "Legacy of Icebriars",     -- Level 115
            "Legacy of Daggerspikes",  -- Level 110
            "Legacy of Daggerspurs",   -- Level 105
            "Legacy of Spikethistles", -- Level 100
            "Legacy of Spineburrs",    -- Level 95
            "Legacy of Bonebriar",     -- Level 90
            "Legacy of Brierbloom",    -- Level 85
            "Legacy of Viridithorns",  -- Level 80
            "Legacy of Viridiflora",   -- Level 75
            "Legacy of Nettles",       -- Level 70
            "Legacy of Bracken",       -- Level 65
            "Legacy of Thorn",         -- Level 59
            "Legacy of Spike",         -- Level 49
        },
        ['MoveSpells'] = {
            "Flight of Falcons", -- Level 91
            "Spirit of Falcons", -- Level 74
            "Flight of Eagles",  -- Level 62
            "Spirit of Eagle",   -- Level 54
            "Pack Spirit",       -- Level 35
            "Spirit of Wolf",    -- Level 10
        },
        ['ManaBear'] = {
            --Druid Mana Bear Growth Line
            "Emboldened Growth", -- Level 121
            "Bolstered Growth",  -- Level 116
            "Sustaining Growth", -- Level 111
            "Nourishing Growth", -- Level 106
            "Nurturing Growth",  -- Level 96
        },
        ['PetSpell'] = {
            "Nature Walker's Behest", -- Level 55
        },
        ['RezSpell'] = {
            "Incarnate Anew", -- Level 59
        },
        -- ['SingleDS'] = {
        --     -- Updated to 125
        --     --Single Target Damage Shield
        --     "Bramblespike Bulwark", -- Level 122
        --     "Nightspire Bulwark",   -- Level 117
        --     "Icebriar Bulwark",     -- Level 112
        --     "Daggerspike Bulwark",  -- Level 107
        --     "Daggerspur Bulwark",   -- Level 102
        --     "Spikethistle Bulwark", -- Level 97
        --     "Spineburr Bulwark",    -- Level 92
        --     "Bonebriar Bulwark",    -- Level 87
        --     "Brierbloom Bulwark",   -- Level 82
        --     "Viridifloral Bulwark", -- Level 77
        --     "Viridifloral Shield",  -- Level 72
        --     "Nettle Shield",        -- Level 67
        --     "Shield of Bracken",    -- Level 63
        --     "Shield of Blades",     -- Level 58
        --     "Shield of Thorns",     -- Level 47
        --     "Shield of Spikes",     -- Level 37
        --     "Shield of Brambles",   -- Level 27
        --     "Shield of Barbs",      -- Level 17
        --     "Shield of Thistles",   -- Level 7
        -- },
    },
    ['HealRotationOrder'] = {
        {
            name  = 'BigHealPoint',
            state = 1,
            steps = 1,
            cond  = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['BigHealPoint'] = {
            {
                name = "QuickHealSurge",
                type = "Spell",
            },
            {
                name = "QuickGroupHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Blessing of Tunare",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Wildtender's Survival",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Swarm of Fireflies",
                type = "AA",
            },
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['GroupHealPoint'] = {
            {
                name = "Blessing of Tunare",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "QuickGroupHeal",
                type = "Spell",
            },
            {
                name = "Wildtender's Survival",
                type = "AA",
            },
            {
                name = "LongGroupHeal",
                type = "Spell",
            },

        },
        ['MainHealPoint'] = {
            {
                name = "QuickHeal",
                type = "Spell",
            },
            {
                name = "LongHeal",
                type = "Spell",
            },
        },
    },
    ['Charm']             = {
        ['Abilities'] = {
            { name = "Dire Charm", type = "AA", },
            { name = "CharmSpell", type = "Spell", },
        },
    },
    ['RotationOrder']     = {
        -- Downtime doesn't have state because we run the whole rotation at once.
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
            load_cond = function(self) return Core.OnEMU() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoPet') or mq.TLO.Me.Pet.ID() ~= 0 then return false end
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToPetBuff() and Casting.AmIBuffable()
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
            name = 'Debuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'TwinHeal',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoTwinHeal') and self:GetResolvedActionMapItem('TwinHealNuke') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Config:GetSetting('DoTwinHeal') and Core.IsHealing() and
                    Targeting.GetTargetPctHPs() <= Config:GetSetting('AutoAssistAt')
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },

    },
    ['Rotations']         = {
        ['DPS'] = {
            {
                name = "SunrayDot",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Heal") and Config:GetSetting('DoFire') and Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot') and
                        Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "ChillDot",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Heal") and not Config:GetSetting('DoFire') and Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot')
                end,
            },
            {
                name = "Silent Casting",
                type = "AA",
            },
            {
                name = "Season's Wrath",
                type = "AA",
                cond = function(self, aaName)
                    return Core.IsModeActive("Mana") and Casting.DetAACheck(aaName) and Targeting.GetTargetPctHPs() > 75
                end,
            },
            {
                name = "SunDot",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Mana") or
                        (Core.IsModeActive("Heal") and Config:GetSetting('DoFire')) and Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot')
                end,
            },
            {
                name = "HordeDot",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot')
                end,
            },
            {
                name = "DichoSpell",
                type = "Spell",
                cond = function(self, spell)
                    return (Core.IsModeActive("Mana") or Config:GetSetting('DoNuke')) and Casting.DetSpellCheck(spell) and Targeting.GetTargetPctHPs() > 60 and
                        mq.TLO.Me.PctMana() > 50
                end,
            },
            {
                name = "RemoteSunDD",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoFire') and Casting.DetSpellCheck(spell) and Config:GetSetting('DoNuke') and
                        Targeting.GetTargetPctHPs() < Config:GetSetting('NukePct')
                end,
            },
            {
                name = "RemoteMoonDD",
                type = "Spell",
                cond = function(self, spell)
                    return not Config:GetSetting('DoFire') and Casting.DetSpellCheck(spell) and Config:GetSetting('DoNuke') and
                        Targeting.GetTargetPctHPs() < Config:GetSetting('NukePct')
                end,
            },
            {
                name = "MoonbeamDot",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Mana") and Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot') and
                        Targeting.GetTargetLevel() >= mq.TLO.Me.Level()
                end,
            },
            {
                name = "NaturesWrathDot",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Mana") and Casting.DotSpellCheck(spell) and Config:GetSetting('DoDot')
                end,
            },
            {
                name = "ShroomPet",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Mana")
                        and Casting.DetSpellCheck(spell) and mq.TLO.Me.PctMana() < 60
                end,
            },
            {
                name = "WinterFireDD",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell) and Config:GetSetting('DoFire') and Casting.OkayToNuke()
                end,
            },
            {
                name = "IceRainNuke",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Mana") and Casting.DetSpellCheck(spell) and not Config:GetSetting('DoFire') and Config:GetSetting('DoRain') and
                        Casting.OkayToNuke()
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
                cond = function(self, spell)
                    return Core.IsModeActive("Mana") and Casting.DetSpellCheck(spell) and not Config:GetSetting('DoFire') and
                        Casting.OkayToNuke()
                end,
            },
            {
                name = "Nature's Frost",
                type = "AA",
                cond = function(self, aaName)
                    return Core.IsModeActive("Mana") and mq.TLO.Me.PctMana() > 50 and
                        (not Core.IsModeActive("Heal") or (Core.IsModeActive("Heal") and not Config:GetSetting('DoFire') and Casting.OkayToNuke()))
                end,
            },
            {
                name = "Nature's Fire",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() > 50 and Config:GetSetting('DoNuke') and
                        (not Core.IsModeActive("Heal") or (Core.IsModeActive("Heal") and Config:GetSetting('DoFire') and Casting.OkayToNuke()))
                end,
            },
            {
                name = "Nature's Bolt",
                type = "AA",
                cond = function(self, aaName)
                    return Core.IsModeActive("Mana") and mq.TLO.Me.PctMana() > 50
                end,
            },
        },
        ['Burn'] = {
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoChestClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Nature's Boon",
                type = "AA",
            },
            {
                name = "Spirit of the Wood",
                type = "AA",
            },
            {
                name = "Swarm of the Fireflies",
                type = "AA",
            },
            {
                name = "Distant Conflagration",
                type = "AA",
            },
            {
                name = "Nature's Guardian",
                type = "AA",
            },
            {
                name = "Spirits of Nature",
                type = "AA",
            },
            {
                name = "Destructive Vortex",
                type = "AA",
            },
            {
                name = "Nature's Fury",
                type = "AA",
            },
            {
                name = "Spire of Nature",
                type = "AA",
            },
        },
        ['TwinHeal'] = {
            {
                name = "TwinHealNuke",
                type = "CustomFunc",
                cond = function(self, spell, target)
                    if Casting.IHaveBuff("Healing Twincast") then return false end
                    local twinHeal = Core.GetResolvedActionMapItem("TwinHealNuke")
                    return Casting.CastReady(twinHeal)
                end,
                custom_func = function(self)
                    local twinHeal = Core.GetResolvedActionMapItem("TwinHealNuke")
                    Casting.UseSpell(twinHeal.RankName(), Core.GetMainAssistId(), false, false, 0)
                end,
            },
        },
        ['Debuff'] = {
            {
                name = "RoDebuff",
                type = "Spell",
                cond = function(self, spell) return Casting.DetSpellCheck(spell) end,
            },
            {
                name = "Blessing of Ro",
                type = "AA",
                cond = function(self, aaName, target)
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and Casting.ReagentCheck(aaSpell and aaSpell.Trigger(1) or aaName)
                end,
            },
            {
                name = "SkinDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and not Targeting.TargetBodyIs(target, "Undead") and
                        not Targeting.IsSummoned(target)
                end,
            },
            {
                name = "IceBreathDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return not Config:GetSetting('DoFire') and Casting.DetSpellCheck(spell) and Targeting.GetAutoTargetPctHPs() < Config:GetSetting('NukePct') and
                        Config:GetSetting('DoNuke')
                end,
            },
            {
                name = "FrostDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return not Config:GetSetting('DoFire') and Casting.DetSpellCheck(spell) and Targeting.GetAutoTargetPctHPs() < Config:GetSetting('NukePct') and
                        Config:GetSetting('DoNuke')
                end,
            },
            {
                name = "Entrap",
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoSnare') and Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if Casting.CanUseAA("Entrap") then return false end
                    return Config:GetSetting('DoSnare') and Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "Season's Wrath",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Swarm of Fireflies",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "GroupDmgShield",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Spirit of Eagles",
                type = "AA",
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName, target)
                    local bookSpell = self:GetResolvedActionMapItem('MoveSpells')
                    local aaSpell = Casting.GetAASpell(aaName)
                    if not Config:GetSetting('DoRunSpeed') or (bookSpell and bookSpell.Level() or 999) > (aaSpell.Level() or 0) then return false end

                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "MoveSpells",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    local aaSpellLvl = mq.TLO.Me.AltAbility("Spirit of Eagles").Spell.Trigger(1).Level() or 0
                    if not Config:GetSetting("DoRunSpeed") or aaSpellLvl >= (spell.Level() or 0) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "AtkBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "TempHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return true end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoTempHP') then return false end
                    return Targeting.TargetClassIs("WAR", target) and Casting.GroupBuffCheck(spell, target) --PAL/SHD have their own temp hp buff
                end,
            },
            {
                name = "HPTypeOne",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoHPBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ReptileCombatInnate",
                type = "Spell",
                active_cond = function(self, spell) return true end,
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs({ "WAR", "SHD", }, target) and Casting.GroupBuffCheck(spell, target) --does not stack with PAL innate buff
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupRegen') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Wrath of the Wild",
                type = "AA",
                active_cond = function(self, aaName) return true end,
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "SelfShield",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfManaRegen",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) and not (spell.Name() == "Mask of the Hunter" and mq.TLO.Zone.Indoor()) end,
            },
            {
                name = "IceAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell) return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName())) end,
            },
            {
                name = "HealingAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    if self:GetResolvedActionMapItem('IceAura') then return false end
                    return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName()))
                end,
            },
            {
                name = "ManaBear",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return (spell and spell() and spell.MyCastTime() or 999999) < 30000 end,
            },
            {
                name = "Group Spirit of the Great Wolf",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Spirit of the Great Wolf",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Preincarnation",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function() return mq.TLO.Me.Pet.ID() ~= 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
    },
    ['Spells']            = {
        {
            gem = 1,
            spells = {
                {
                    name = "DichoSpell",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 101 and
                            Core.IsModeActive("Mana")
                    end,
                },
                { name = "LongHeal", },
            },
        },
        {
            gem = 2,
            spells = {
                -- [ MANA MODE ] --
                {
                    name = "QuickHeal",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 75 and
                            Core.IsModeActive("Mana")
                    end,
                },
                {
                    name = "SnareSpell",
                    cond = function(self)
                        return Config:GetSetting('DoSnare')
                            and Core.IsModeActive("Mana")
                    end,
                },
                -- [ HEAL MODE ] --
                { name = "QuickHealSurge", cond = function(self) return mq.TLO.Me.Level() >= 75 end, },
                { name = "LongHeal",       cond = function(self) return true end, },
                -- [ Fall Back ]--
                { name = "WinterFireDD",   cond = function(self) return Config:GetSetting("DoFire") end, },
                { name = "IceNuke",        cond = function(self) return true end, },

            },
        },
        {
            gem = 3,
            spells = {
                -- [ MANA MODE ] --
                { name = "WinterFireDD",   cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "QuickGroupHeal", cond = function(self) return mq.TLO.Me.Level() >= 90 end, },
                { name = "CharmSpell",     cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "QuickRoarDD",    cond = function(self) return true end, },
                -- [ Fall Back ]--
                { name = "IceRainNuke",    cond = function(self) return true end, },
            },
        },
        {
            gem = 4,
            spells = {
                -- [ BOTH MODES ] --
                { name = "QuickHeal",       cond = function(self) return mq.TLO.Me.Level() >= 90 end, },
                -- [ MANA MODE ] --
                { name = "QuickRoarDD",     cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "HordeDot",        cond = function(self) return true end, },
                -- [ Fall Back ]--
                { name = "RoDebuff",        cond = function(self) return Config:GetSetting("DoFire") end, },
                { name = "IceBreathDebuff", cond = function(self) return true end, },
            },
        },
        {
            gem = 5,
            spells = {
                -- [ MANA MODE ] --
                { name = "HordeDot",      cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "LongGroupHeal", cond = function(self) return mq.TLO.Me.Level() >= 70 end, },
                { name = "SunDot",        cond = function(self) return true end, },
                { name = "SunrayDot",     cond = function(self) return true end, },
                -- [ Fall Back ]--
                { name = "SunrayDot",     cond = function(self) return true end, },
            },
        },
        {
            gem = 6,
            spells = {
                -- [ BOTH MODES ] --
                {
                    name = "RemoteSunDD",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 83 and Config:GetSetting('DoFire')
                    end,
                },
                {
                    name = "RemoteMoonDD",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 83 and not Config:GetSetting('DoFire')
                    end,
                },
                -- [ MANA MODE ] --
                { name = "RoDebuff",            cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "SunrayDot",           cond = function(self) return mq.TLO.Me.Level() >= 73 end, },
                { name = "ReptileCombatInnate", cond = function(self) return true end, },
                { name = "SnareSpell",          cond = function(self) return Config:GetSetting('DoSnare') end, },
                -- [ Fall Back ]--
                { name = "HordeDot",            cond = function(self) return true end, },
            },
        },
        {
            gem = 7,
            spells = {
                -- [ MANA MODE ] --
                { name = "MoonbeamDot",         cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "FrostDebuff",         cond = function(self) return mq.TLO.Me.Level() >= 74 and not Config:GetSetting('DoFire') end, },
                { name = "ReptileCombatInnate", cond = function(self) return Casting.CanUseAA("Blessing of Ro") end, },
                { name = "RoDebuff",            cond = function(self) return true end, },
                -- [ Fall Back ]--
                { name = "HordeDot",            cond = function(self) return true end, },
                { name = "SnareSpell",          cond = function(self) return Config:GetSetting('DoSnare') end, },
            },
        },
        {
            gem = 8,
            spells = {
                -- [ MANA MODE ] --
                {
                    name = "SunDot",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 49 and
                            Core.IsModeActive("Mana")
                    end,
                },
                { name = "RootSpells",   cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "TwinHealNuke", cond = function(self) return Config:GetSetting("DoTwinHeal") end, },
                { name = "GroupCure",    cond = function(self) return true end, },
            },
        },
        {
            gem = 9,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                -- [ MANA MODE ] --
                {
                    name = "IceBreathDebuff",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 63 and
                            Core.IsModeActive("Mana")
                    end,
                },
                { name = "IceDD",           cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "SunDot",          cond = function(self) return Config:GetSetting("DoFire") end, },
                { name = "IceBreathDebuff", cond = function(self) return true end, },
            },
        },
        {
            gem = 10,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                -- [ MANA MODE ] --
                { name = "NaturesWrathDot", cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "TempHPBuff",      cond = function(self) return true end, },
            },
        },
        {
            gem = 11,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                -- [ MANA MODE ] --
                { name = "TempHPBuff",          cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "DichoSpell",          cond = function(self) return mq.TLO.Me.Level() >= 101 end, },
                { name = "GroupCure",           cond = function(self) return true end, },
                { name = "ReptileCombatInnate", cond = function(self) return true end, },
            },
        },
        {
            gem = 12,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                -- [ MANA MODE ] --
                {
                    name = "LongHeal",
                    cond = function(self)
                        return mq.TLO.Me.Level() >= 99 and
                            Core.IsModeActive("Mana")
                    end,
                },
                { name = "ChillDot",            cond = function(self) return Core.IsModeActive("Mana") end, },
                -- [ HEAL MODE ] --
                { name = "GroupCure",           cond = function(self) return true end, },
                { name = "ReptileCombatInnate", cond = function(self) return true end, },
            },
        },
        {
            gem = 13,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Alliance", cond = function(self) return Config:GetSetting("DoAlliance") end, },
            },
        },
    },
    ['Helpers']           = {
    },
    --TODO: These are nearly all in need of Display and Tooltip updates.
    ['DefaultConfig']     = {
        ['Mode']         = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 3,
            FAQ = "What do the different Modes Do?",
            Answer = "Heal Mode will focus on healing and buffing.\nMana Mode will focus on DPS and Mana Management.",
        },
        --TODO: This is confusing because it is actually a choice between fire and ice and should be rewritten (need time to update conditions above)
        ['DoFire']       = {
            DisplayName = "Cast Fire Spells",
            Group = "Abilities",
            Header = "Common",
            Category = "Common Rules",
            Tooltip = "if Enabled Use Fire Spells, Disabled Use Ice Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoRain']       = {
            DisplayName = "Cast Rain Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Tooltip = "Use Rain Spells",
            Default = true,
        },
        ['DoRunSpeed']   = {
            DisplayName = "Use Movement Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use Run/Lev buffs.",
            Default = true,
            FAQ = "Sometimes I group with a bard and don't need to worry about Run Speed, can I disable it?",
            Answer = "Yes, you can disable [DoRunSpeed] to prevent casting Run Speed spells.",
        },
        ['DoNuke']       = {
            DisplayName = "Cast Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Spells",
            Default = true,
        },
        ['NukePct']      = {
            DisplayName = "Nuke Pct",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Spells",
            Default = 90,
            Min = 1,
            Max = 100,
        },
        ['DoSnare']      = {
            DisplayName = "Cast Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Tooltip = "Enable casting Snare spells.",
            Default = true,
        },
        ['DoChestClick'] = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Click your chest item",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoDot']        = {
            DisplayName = "Cast DOTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Tooltip = "Enable casting Damage Over Time spells.",
            Default = true,
        },
        ['DoTwinHeal']   = {
            DisplayName = "Cast Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoHPBuff']     = {
            DisplayName = "Group HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your group HP Buff. Disable as desired to prevent conflicts with CLR or PAL buffs.",
            Default = true,
            FAQ = "Why am I in a buff war with my Paladin or Druid? We are constantly overwriting each other's buffs.",
            Answer = "Disable [DoHPBuff] to prevent issues with Aego/Symbol lines overwriting. Alternatively, you can adjust the settings for the other class instead.",
        },
        ['DoTempHP']     = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use Temp HP Buff (Only for WAR, other tanks have their own)",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "Why isn't my Temp HP Buff being used?",
            Answer = "You either have the Temp HP Buff disabled, or you don't have a Warrior in your group (Other tanks have their own Temp HP Buff).",
        },
        ['DoGroupRegen'] = {
            DisplayName = "Group Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your Group Regen buff.",
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['HealPriority'] = {
            DisplayName = "Healing Priority",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Type = "Combo",
            ComboOptions = { 'Ignore', 'Big Heal Point', 'Main Heal Point', },
            Default = 3,
            Min = 1,
            Max = 3,
            Tooltip = "When to yield offensive rotations for healing:\n1 - Ignore (never)\n2 - Big Heal Point\n3 - Main Heal Point",
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
