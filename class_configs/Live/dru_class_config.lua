local mq           = require('mq')
local Casting      = require("utils.casting")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require('utils.globals')
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "2.0 - Live",
    _author               = "Algar, Derple",
    ['ModeChecks']        = {
        CanCharm = function() return true end,
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCures') end,
        IsRezing = function()
            return (Core.GetResolvedActionMapItem('RezSpell') and Targeting.GetXTHaterCount() == 0) or
                (Casting.CanUseAA("Call of the Wild") and Config:GetSetting('DoBattleRez'))
        end,
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
                        and not Casting.CanUseAA('Rejuvenation of Spirit')
                end,
            },
        },
    },
    ['Modes']             = {
        'Heal',
        'Hybrid',
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
            { type = "AA", name = "Purified Spirits", selfOnly = true, },
        },
        ['Poison'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'CurePoison', }) end, },
            { type = "Spell", name = "SingleCure", },
        },
        ['Disease'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'CureDisease', }) end, },
            { type = "Spell", name = "SingleCure", },
        },
        ['Curse'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'CureCurse', }) end, },
            { type = "Spell", name = "SingleCure", },
        },
        ['Corruption'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'SingleCure', 'CureCorrupt', }) end, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Staff of Living Brambles",
            "Staff of Everliving Brambles",
        },
    },
    ['AbilitySets']       = {
        --[[ ['Alliance'] = {
            "Ferntender's Covariance",  -- Level 125
            "Arboreal Atonement",       -- Level 120
            "Arbor Tender's Coalition", -- Level 115
            "Bosquetender's Alliance,", -- Level 102
        }, ]]
        --[[ ['FireAura'] = {
            "Wildspark Aura", -- Level 97
            "Wildblaze Aura", -- Level 92
            "Wildfire Aura",  -- Level 87
        }, ]]
        ['IceAura'] = {
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
            "Aura of Life",      -- Level 70
            "Aura of the Grove", -- Level 55
        },
        ['SingleCure'] = {
            "Mastery: Sanctified Blood", -- Level 128
            "Sanctified Blood",          -- Level 118
            "Expurgated Blood",          -- Level 108
            "Unblemished Blood",         -- Level 103
            "Cleansed Blood",            -- Level 99
            "Perfected Blood",           -- Level 94
            -- "Purged Blood",              -- Level 89
            -- "Purified Blood",            -- Level 84
            -- "Pure Blood",                -- Level 52
        },
        ['CurePoison'] = {
            "Eradicate Poison",  -- Level 58
            "Counteract Poison", -- Level 28
            "Cure Poison",       -- Level 5
        },
        ['CureDisease'] = {
            "Eradicate Disease",  -- Level 58
            "Counteract Disease", -- Level 28
            "Cure Disease",       -- Level 4
        },
        ['CureCurse'] = {
            "Eradicate Curse",      -- Level 54
            "Remove Greater Curse", -- Level 54
            "Remove Curse",         -- Level 38
            "Remove Lesser Curse",  -- Level 23
            "Remove Minor Curse",   -- Level 8
        },
        ['GroupCure'] = {
            "Mastery: Nightwhisper's Breeze", -- Level 126
            "Nightwhisper's Breeze",          -- Level 116
            "Wildtender's Breeze",            -- Level 106
            "Copsetender's Breeze",           -- Level 101
            "Bosquetender's Breeze",          -- Level 96
            "Fawnwalker's Breeze",            -- Level 91
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
        ['QuickHealSurge'] = {
            "Adrenaline Surge XII", -- Level 129
            "Adrenaline Fury",      -- Level 124
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
            "Rejuvilation IX", -- Level 130
            "Resuscitation",   -- Level 125
            "Sootheseance",    -- Level 120
            "Rejuvenescence",  -- Level 115
            "Revitalization",  -- Level 110
            "Resurgence",      -- Level 105
            "Vivification",    -- Level 100
            "Invigoration",    -- Level 95
            "Rejuvilation",    -- Level 90
        },
        ['HealSpell'] = {
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
            "Survival of the Fittest XI",    -- Level 128
            "Survival of the Heroic",        -- Level 123
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
            "Lunamend",        -- Level 130
            "Lunacea",         -- Level 125
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
        ['RezSpell'] = {
            "Incarnate Anew", -- Level 59
        },
        ['FrostDebuff'] = {
            -- Frost Debuff Series -- >=74LVL -- On Bar
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
            "Grasp of Ro IX",              -- Level 126
            "Clench of Ro",                -- Level 121
            "Cinch of Ro",                 -- Level 116
            "Clasp of Ro",                 -- Level 111
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
        --[[ ['RoDebuffAE'] = {
            "Pillar of Ro VII", -- Level 127
            "Visage of Ro",     -- Level 122
            "Scrutiny of Ro",   -- Level 117
            "Glare of Ro",      -- Level 112
            "Gaze of Ro",       -- Level 107
            "Column of Ro",     -- Level 102
            "Pillar of Ro",     -- Level 97
        }, ]]
        ['BreathDebuff'] = {
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
        --[[ ['SkinDebuff'] = {
            "Skin to Lichen",    -- Level 118
            "Skin to Sumac",     -- Level 108
            "Skin to Seedlings", -- Level 98
            "Skin to Foliage",   -- Level 93
            "Skin to Leaves",    -- Level 88
            "Skin to Flora",     -- Level 83
            "Skin to Mulch",     -- Level 78
            "Skin to Vines",     -- Level 73
        }, ]]
        ['ReptileBuff'] = {
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
        ['WrathDot'] = {
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
            "Sunscorch XII",         -- Level 129
            "Sunscald",              -- Level 124
            "Sunpyre",               -- Level 119
            "Sunshock",              -- Level 114
            "Sunflame",              -- Level 109
            "Sunflash",              -- Level 104
            "Sunblaze",              -- Level 99
            "28948",                 -- Level 94, Sunscorch - deconflicts duplicate at Level 74
            "Sunbrand",              -- Level 89
            "Sunsinge",              -- Level 84
            "Sunsear",               -- Level 79
            "9902",                  -- Level 74, Sunscorch - deconflicts duplicate at Level 94
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
        ['RemoteColdNuke'] = {
            "Remote Moonfire VII", -- Level 129
            "Remote Moonshiver",   -- Level 124
            "Remote Moonchill",    -- Level 119
            "Remote Moonrake",     -- Level 114
            "Remote Moonflash",    -- Level 109
            "Remote Moonflame",    -- Level 104
            "Remote Moonfire",     -- Level 99
        },
        ['RemoteFireNuke'] = {
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
        ['SummonedNuke'] = {
            "Expunge the Unnatural",     -- Level 127
            "Dismantle the Unnatural",   -- Level 122
            "Unmend the Unnatural",      -- Level 118
            "Obliterate the Unnatural",  -- Level 113
            "Repudiate the Unnatural",   -- Level 108
            "Eradicate the Unnatural",   -- Level 103
            "Exterminate the Unnatural", -- Level 98
            "Abolish the Divergent",     -- Level 93
            "Annihilate the Divergent",  -- Level 88
            "Annihilate the Anomalous",  -- Level 83
            "Annihilate the Aberrant",   -- Level 78
            "Annihilate the Unnatural",  -- Level 73
        },
        ['StunNuke'] = {
            "Katabatic Roar VIII",      -- Level 128
            "Tempest Roar",             -- Level 123
            "Bloody Roar",              -- Level 118
            "Typhonic Roar",            -- Level 113
            "Cyclonic Roar",            -- Level 108
            "Anabatic Roar",            -- Level 103
            "Katabatic Roar",           -- Level 98
            "Roar of Kolos",            -- Level 93 -- transition to roar nukes
            "Cyclone of the Stormborn", -- Level 91 -- use the fast, lower DD stuns as filler before roar is available
            "Shear of the Stormborn",   -- Level 86
            "Squall of the Stormborn",  -- Level 81
            "Tempest of the Stormborn", -- Level 76
            "Gale of the Stormborn",    -- Level 71
            "Stormwatch",               -- Level 66
            "Storm's Fury",             -- Level 61
            -- "Dustdevil",                 -- Level 43, Does not Stun
            "Fury of Air",              -- Level 30
        },
        ['DichoSpell'] = {
            "Reciprocal Winds", -- Level 121
            "Ecliptic Winds",   -- Level 116
            "Composite Winds",  -- Level 111
            "Dissident Winds",  -- Level 106
            "Dichotomic Winds", -- Level 101
        },
        ['FireNuke'] = {
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
            "Chill of the Grovetender",     -- Level 130
            "Chill of the Ferntender",      -- Level 125
            "Chill of the Dusksage Tender", -- Level 120
            "Chill of the Arbor Tender",    -- Level 115
            "Chill of the Wildtender",      -- Level 110
            "Chill of the Copsetender",     -- Level 105
            "Chill of the Visionary",       -- Level 100
            "Chill of the Natureward",      -- Level 95
        },
        --[[ ['RootSpells'] = {
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
        }, ]]
        ['SnareSpell'] = {
            "Thornmaw Vines",  -- Level 97
            "Hungry Vines",    -- Level 70
            "Serpent Vines",   -- Level 69
            "Entangle",        -- Level 61
            "Mire Thorns",     -- Level 61
            "Bonds of Tunare", -- Level 57
            "Ensnare",         -- Level 26
            "Snare",           -- Level 1
            "Tangling Weeds",  -- Level 1
        },
        ['TwincastSpell'] = {
            "Twincast", -- Level 85
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
        ['ColdNuke'] = {
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
        --[[ ['ColdRainNuke'] = {
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
        }, ]]
        --[[ ['ShroomPet'] = {
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
        }, ]]
        ['SelfShield'] = {
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
            "Protection of the Glades",   -- Level 60, Group (All above, also group)
            "Natureskin",                 -- Level 57, Single
            "Protection of Nature",       -- Level 49, Group
            "Skin like Nature",           -- Level 46, Single
            "Protection of Diamond",      -- Level 39, Group
            "Skin like Diamond",          -- Level 36, Single
            "Protection of Steel",        -- Level 27, Group
            "Skin like Steel",            -- Level 24, Single
            "Protection of Rock",         -- Level 19, Group
            "Skin like Rock",             -- Level 14, Single
            "Protection of Wood",         -- Level 9, Group
            "Skin like Wood",             -- Level 1, Single
        },
        ['TempHPBuff'] = {
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
            "Mammoth's Force",    -- Level 86
            "Mammoth's Strength", -- Level 71
            "Lion's Strength",    -- Level 67
            "Nature's Might",     -- Level 62
            "Girdle of Karana",   -- Level 55
            "Storm Strength",     -- Level 44
            "Strength of Stone",  -- Level 34
            "Strength of Earth",  -- Level 7
        },
        ['DamageShield'] = {
            "Legacy of Brackenbriars", -- Level 127
            "Legacy of Bramblespikes", -- Level 125
            "Legacy of Bloodspikes",   -- Level 120
            "Legacy of Icebriars",     -- Level 115
            "Icebriar Bulwark",        -- Level 112
            "Legacy of Daggerspikes",  -- Level 110
            "Daggerspike Bulwark",     -- Level 107
            "Legacy of Daggerspurs",   -- Level 105
            "Daggerspur Bulwark",      -- Level 102
            "Legacy of Spikethistles", -- Level 100
            "Spikethistle Bulwark",    -- Level 97
            "Legacy of Spineburrs",    -- Level 95
            "Spineburr Bulwark",       -- Level 92
            "Legacy of Bonebriar",     -- Level 90
            "Bonebriar Bulwark",       -- Level 87
            "Legacy of Brierbloom",    -- Level 85
            "Brierbloom Bulwark",      -- Level 82
            "Legacy of Viridithorns",  -- Level 80
            "Viridifloral Bulwark",    -- Level 77
            "Legacy of Viridiflora",   -- Level 75
            "Viridifloral Shield",     -- Level 72
            "Legacy of Nettles",       -- Level 70
            "Legacy of Bracken",       -- Level 65
            "Shield of Bracken",       -- Level 63
            "Legacy of Thorn",         -- Level 59
            "Shield of Blades",        -- Level 58
            "Legacy of Spike",         -- Level 49
            "Shield of Thorns",        -- Level 47
            "Shield of Spikes",        -- Level 37
            "Shield of Brambles",      -- Level 27
            "Shield of Barbs",         -- Level 17
            "Shield of Thistles",      -- Level 7
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
            "Emboldened Growth", -- Level 121
            "Bolstered Growth",  -- Level 116
            "Sustaining Growth", -- Level 111
            "Nourishing Growth", -- Level 106
            "Nurturing Growth",  -- Level 96
        },
        ['CharmSpell'] = {
            "Beast's Beckoning XVIII", -- Level 126
            "Beast's Bestowing",       -- Level 121
            "Beast's Bellowing",       -- Level 116
            "59263",                   -- Level 111, Beast's Beckoning - deconflicts duplicate at Level 71
            "Beast's Beseeching",      -- Level 106
            "Beast's Bidding",         -- Level 101
            "Beast's Bespelling",      -- Level 96
            "Beast's Behest",          -- Level 91
            "Beast's Beguiling",       -- Level 86
            "Beast's Befriending",     -- Level 81
            "Beast's Bewitching",      -- Level 76
            "9923",                    -- Level 71, Beast's Beckoning - deconflicts duplicate at Level 111
            "Nature's Beckon",         -- Level 70
            "Command of Tunare",       -- Level 63
            "Tunare's Request",        -- Level 55
            "Call of Karana",          -- Level 52
            "Allure of the Wild",      -- Level 43
            "Beguile Animals",         -- Level 33
            "Charm Animals",           -- Level 23
            "Befriend Animal",         -- Level 13
        },
        ['Barkspur'] = {
            "Barkspur XIII", -- Level 126
            "Frondbarb",     -- Level 121
            "Duskthorn",     -- Level 116
            "Vinespike",     -- Level 111
            "Thornspike",    -- Level 106
            "Daggerthorn",   -- Level 101
            "Stemfang",      -- Level 96
            "Vinespur",      -- Level 91
            "Thornspur",     -- Level 86
            "Frondspur",     -- Level 81
            "Fernspike",     -- Level 76
            "Fernspur",      -- Level 71
            "Barkspur",      -- Level 70
        },
    },
    ['HealRotationOrder'] = {
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
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
        ['BigHealPoint'] = {
            {
                name = "QuickHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('QuickHealUse') == 1 end,
            },
            {
                name = "QuickHealSurge",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('QuickHealSurgeUse') == 1 end,
            },
            {
                name = "QuickGroupHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Wildtender's Survival",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "Spirit of the Bear",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Blessing of Tunare",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['MainHealPoint'] = {
            {
                name = "QuickHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('QuickHealUse') == 2 end,
            },
            {
                name = "QuickHealSurge",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('QuickHealSurgeUse') == 2 end,
            },
            {
                name = "HealSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealSpell') end,
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
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff()
            end,
        },
        {
            name = 'RoDebuff',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoRoDebuff') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'SeasonsWrath',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'FrostDebuff',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoFrostDebuff') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'BreathDebuff',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoBreathDebuff') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Casting.OkayToDebuff()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and not Globals.AutoTargetIsNamed and
                    Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
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
            name = 'TwinHeal',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoTwinHeal') and self:GetResolvedActionMapItem('TwinHealNuke') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'ToTHealNukes',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function(self)
                return (Config:GetSetting('RemoteNukeElement') == 1 and self:GetResolvedActionMapItem('RemoteFireNuke')) or
                    (Config:GetSetting('RemoteNukeElement') == 2 and self:GetResolvedActionMapItem('RemoteColdNuke'))
            end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
            end,
        },
        {
            name = 'Barkspur',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoBarkspur') and self:GetResolvedActionMapItem('Barkspur') end,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
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
        {
            name = 'InstantRunBuff',
            state = 1,
            steps = 1,
            targetId = function(self)
                local autoTarget = Targeting.CheckForAutoTargetID()
                if #autoTarget > 0 then return autoTarget end
                return Casting.GetBuffableIDs()
            end,
            load_cond = function(self) return Config:GetSetting('DoMoveBuffs') and Casting.CanUseAA("Communion of the Cheetah") end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and not mq.TLO.Me.Invis()
                local combat = combat_state == "Combat"
                return (downtime or combat) and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']         = {
        ['ToTHealNukes'] = {
            {
                name = "DichoSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDicho') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke() and Targeting.MainHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
            {
                name = "RemoteFireNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('RemoteNukeElement') == 1 end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke() and Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
            {
                name = "RemoteColdNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('RemoteNukeElement') == 2 end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke() and Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "WrathDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWrathDot') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "SunDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSunDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target) and
                        (not Config:GetSetting('DotNamedOnly') or Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "HordeDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHordeDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target) and
                        (not Config:GetSetting('DotNamedOnly') or Globals.AutoTargetIsNamed or Casting.GOMCheck())
                end,
            },
            {
                name = "SunrayDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('SunMoonDotChoice') == 2 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target) and
                        (not Config:GetSetting('DotNamedOnly') or Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "MoonbeamDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('SunMoonDotChoice') == 3 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target) and
                        (not Config:GetSetting('DotNamedOnly') or Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "ChillDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoChillDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target) and
                        (not Config:GetSetting('DotNamedOnly') or Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "SummonedNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSummonedNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true) and Targeting.IsSummoned(target)
                end,
            },
            {
                name = "StunNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoStunNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoFireNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "ColdNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoColdNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Frost",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Fire",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Bolt",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke(true)
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
                name = "Distant Conflagration",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Nature's Blessing",
                type = "AA",
            },
            {
                name = "Group Spirit of the Great Wolf",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
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
                name = "Spirit of the Wood",
                type = "AA",
            },
            {
                name = "Nature's Boon",
                type = "AA",
            },
            {
                name = "Nature's Guardian",
                type = "AA",
            },
            {
                name = "Spirit of Nature",
                type = "AA",
            },
            {
                name = "Spire of Nature",
                type = "AA",
            },
            {
                name = "TwincastSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTwincast') end,
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Silent Casting",
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
                    return Casting.UseSpell(twinHeal.RankName(), Core.GetMainAssistId(), false, false, 0)
                end,
            },
        },
        ['RoDebuff'] = {
            { -- AE Ro on packs
                name = "Vortex of Ro",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Vortex of Ro") end,
                cond = function(self, aaName, target)
                    if Targeting.GetXTHaterCount() < Config:GetSetting('AERoCount') then return false end
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and Casting.ReagentCheck(aaSpell and aaSpell.Trigger(1) or aaName)
                end,
            },
            { -- Single-target Ro on few mobs (or whenever the AE version isn't available)
                name = "Blessing of Ro",
                type = "AA",
                cond = function(self, aaName, target)
                    if Casting.CanUseAA("Vortex of Ro") and Targeting.GetXTHaterCount() >= Config:GetSetting('AERoCount') then return false end
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and Casting.ReagentCheck(aaSpell and aaSpell.Trigger(1) or aaName)
                end,
            },
            {
                name = "RoDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if Casting.CanUseAA("Blessing of Ro") then return false end
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
        ['SeasonsWrath'] = {
            {
                name = "Season's Wrath",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
        },
        ['FrostDebuff'] = {
            {
                name = "FrostDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
        ['BreathDebuff'] = {
            {
                name = "BreathDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Swarm of Fireflies",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsTanking(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "DamageShield",
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
                    if Config.TempSettings.NoLevZone then return false end
                    if not Config:GetSetting('DoMoveBuffs') or (bookSpell and bookSpell.Level() or 999) > (aaSpell.Level() or 0) then return false end

                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "MoveSpells",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    local aaSpellLvl = mq.TLO.Me.AltAbility("Spirit of Eagles").Spell.Trigger(1).Level() or 0
                    if not Config:GetSetting("DoMoveBuffs") or aaSpellLvl >= (spell.Level() or 0) then return false end
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
                load_cond = function(self) return Config:GetSetting('DoTempHP') end,
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs("WAR", target) and Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
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
                name = "ReptileBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoReptile') end,
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
                cond = function(self, aaName, target)
                    return Targeting.TargetIsTanking(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
        },
        ['Downtime'] = {
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
                    return Casting.SelfBuffAACheck(aaName) and mq.TLO.Me.AltAbility(aaName).Spell.RankName.Stacks()
                end,
            },
            {
                name = "Wildtender's Unity",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Wildtender's Unity") end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "SelfShield",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Wildtender's Unity") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfManaRegen",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Wildtender's Unity") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
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
        ['Barkspur'] = {
            {
                name = "Barkspur",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) or not Casting.CastReady(spell) then return false end
                    return Casting.GroupBuffCheck(spell, target, false, true)
                end,
            },
        },
        ['InstantRunBuff'] = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                cond = function(self, aaName, target)
                    local aaBuff = Casting.GetAASpell(aaName).Name() or ""
                    return (self.CombatState == "Combat" and (mq.TLO.Me.Buff(aaBuff).Duration.TotalSeconds() or 0) < 15) or
                        (self.CombatState == "Downtime" and Casting.GroupBuffAACheck(aaName, target))
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Heal Mode",
            cond = function(self) return Core.IsModeActive("Heal") end,
            spells = {
                -- Heals
                { name = "HealSpell",      cond = function(self) return Config:GetSetting('DoHealSpell') end, },
                { name = "QuickHeal", },
                { name = "QuickHealSurge", },
                { name = "LongGroupHeal", },
                { name = "QuickGroupHeal", },
                { name = "PromHeal",       cond = function(self) return Config:GetSetting('MemPromHeal') end, },
                -- Cures
                { name = "GroupCure",      cond = function(self) return self.Helpers.MemGroupCure(self) end, },
                { name = "CurePoison",     cond = function(self) return Config:GetSetting('MemPoisonCure') and not Core.GetResolvedActionMapItem('GroupCure') end, },
                { name = "CureDisease",    cond = function(self) return Config:GetSetting('MemDiseaseCure') and not Core.GetResolvedActionMapItem('GroupCure') end, },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('MemCurseCure') and not Core.GetResolvedActionMapItem('GroupCure') end, },
                { name = "SingleCure",     cond = function(self) return Config:GetSetting('MemCorruptCure') and Core.GetResolvedActionMapItem('SingleCure') end, },
                { name = "CureCorrupt",    cond = function(self) return Config:GetSetting('MemCorruptCure') and not Core.GetResolvedActionMapItem('SingleCure') end, },
                -- Debuffs
                { name = "SnareSpell",     cond = function(self) return Config:GetSetting("DoSnare") and not Casting.CanUseAA("Entrap") end, },
                { name = "RoDebuff",       cond = function(self) return not Casting.CanUseAA("Blessing of Ro") end, },
                { name = "FrostDebuff",    cond = function(self) return Config:GetSetting("DoFrostDebuff") end, },
                { name = "BreathDebuff",   cond = function(self) return Config:GetSetting("DoBreathDebuff") end, },
                -- Tank Utility
                { name = "ReptileBuff",    cond = function(self) return Config:GetSetting('DoReptile') end, },
                { name = "TempHPBuff",     cond = function(self) return Config:GetSetting('DoTempHP') end, },
                -- DPS
                { name = "RemoteFireNuke", cond = function(self) return Config:GetSetting('RemoteNukeElement') == 1 end, },
                { name = "RemoteColdNuke", cond = function(self) return Config:GetSetting('RemoteNukeElement') == 2 end, },
                { name = "DichoSpell",     cond = function(self) return Config:GetSetting('DoDicho') end, },
                { name = "TwinHealNuke",   cond = function(self) return Config:GetSetting("DoTwinHeal") end, },
                { name = "WrathDot",       cond = function(self) return Config:GetSetting("DoWrathDot") end, },
                { name = "SunDot",         cond = function(self) return Config:GetSetting("DoSunDot") end, },
                { name = "HordeDot",       cond = function(self) return Config:GetSetting("DoHordeDot") end, },
                { name = "SummonedNuke",   cond = function(self) return Config:GetSetting('DoSummonedNuke') end, },
                { name = "Barkspur",       cond = function(self) return Config:GetSetting('DoBarkspur') end, },
                { name = "TwincastSpell",  cond = function(self) return Config:GetSetting("DoTwincast") end, },
                { name = "StunNuke",       cond = function(self) return Config:GetSetting("DoStunNuke") end, },
                { name = "FireNuke",       cond = function(self) return Config:GetSetting("DoFireNuke") end, },
                { name = "ColdNuke",       cond = function(self) return Config:GetSetting("DoColdNuke") end, },
                { name = "SunrayDot",      cond = function(self) return Config:GetSetting("SunMoonDotChoice") == 2 end, },
                { name = "MoonbeamDot",    cond = function(self) return Config:GetSetting("SunMoonDotChoice") == 3 end, },
                { name = "ChillDot",       cond = function(self) return Config:GetSetting("DoChillDot") end, },
            },
        },
        {
            name = "Hybrid Mode",
            cond = function(self) return Core.IsModeActive("Hybrid") end,
            spells = {
                -- Heals
                { name = "HealSpell",      cond = function(self) return Config:GetSetting('DoHealSpell') end, },
                { name = "QuickHeal", },
                { name = "QuickHealSurge", },
                { name = "LongGroupHeal", },
                { name = "QuickGroupHeal", },
                { name = "PromHeal",       cond = function(self) return Config:GetSetting('MemPromHeal') end, },
                -- Debuffs
                { name = "SnareSpell",     cond = function(self) return Config:GetSetting("DoSnare") and not Casting.CanUseAA("Entrap") end, },
                { name = "RoDebuff",       cond = function(self) return not Casting.CanUseAA("Blessing of Ro") end, },
                { name = "FrostDebuff",    cond = function(self) return Config:GetSetting("DoFrostDebuff") end, },
                { name = "BreathDebuff",   cond = function(self) return Config:GetSetting("DoBreathDebuff") end, },
                -- Tank Util
                { name = "ReptileBuff",    cond = function(self) return Config:GetSetting('DoReptile') end, },
                { name = "TempHPBuff",     cond = function(self) return Config:GetSetting('DoTempHP') end, },
                -- DPS
                { name = "WrathDot",       cond = function(self) return Config:GetSetting("DoWrathDot") end, },
                { name = "SunDot",         cond = function(self) return Config:GetSetting("DoSunDot") end, },
                { name = "HordeDot",       cond = function(self) return Config:GetSetting("DoHordeDot") end, },
                { name = "TwincastSpell",  cond = function(self) return Config:GetSetting("DoTwincast") end, },
                { name = "SummonedNuke",   cond = function(self) return Config:GetSetting('DoSummonedNuke') end, },
                { name = "FireNuke",       cond = function(self) return Config:GetSetting("DoFireNuke") end, },
                { name = "StunNuke",       cond = function(self) return Config:GetSetting("DoStunNuke") end, },
                -- DPS(Second Tier)
                { name = "SunrayDot",      cond = function(self) return Config:GetSetting("SunMoonDotChoice") == 2 end, },
                { name = "MoonbeamDot",    cond = function(self) return Config:GetSetting("SunMoonDotChoice") == 3 end, },
                { name = "ChillDot",       cond = function(self) return Config:GetSetting("DoChillDot") end, },
                { name = "RemoteFireNuke", cond = function(self) return Config:GetSetting('RemoteNukeElement') == 1 end, },
                { name = "RemoteColdNuke", cond = function(self) return Config:GetSetting('RemoteNukeElement') == 2 end, },
                { name = "ColdNuke",       cond = function(self) return Config:GetSetting("DoColdNuke") end, },
                { name = "Barkspur",       cond = function(self) return Config:GetSetting('DoBarkspur') end, },
                { name = "DichoSpell",     cond = function(self) return Config:GetSetting('DoDicho') end, },
                { name = "TwinHealNuke",   cond = function(self) return Config:GetSetting("DoTwinHeal") end, },
                -- Cures
                { name = "GroupCure",      cond = function(self) return self.Helpers.MemGroupCure(self) end, },
                { name = "CurePoison",     cond = function(self) return Config:GetSetting('MemPoisonCure') and not Core.GetResolvedActionMapItem('GroupCure') end, },
                { name = "CureDisease",    cond = function(self) return Config:GetSetting('MemDiseaseCure') and not Core.GetResolvedActionMapItem('GroupCure') end, },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('MemCurseCure') and not Core.GetResolvedActionMapItem('GroupCure') end, },
                { name = "SingleCure",     cond = function(self) return Config:GetSetting('MemCorruptCure') and Core.GetResolvedActionMapItem('SingleCure') end, },
                { name = "CureCorrupt",    cond = function(self) return Config:GetSetting('MemCorruptCure') and not Core.GetResolvedActionMapItem('SingleCure') end, },
            },
        },
    },
    ['Helpers']           = {
        MemGroupCure = function(self)
            if Config:GetSetting('MemCorruptCure') and self:GetResolvedActionMapItem('SingleCure') then return false end
            if not self:GetResolvedActionMapItem('GroupCure') then return false end
            return Config:GetSetting('MemPoisonCure') or Config:GetSetting('MemDiseaseCure') or Config:GetSetting('MemCurseCure')
        end,
    },
    ['DefaultConfig']     = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Index = 101,
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes do?",
            Answer = "Heal Mode prioritizes healing, cures and utility, using leftover gems for damage.\n" ..
                "Hybrid Mode keeps the same healing core but promotes DoTs and nukes for more damage.",
        },
        ['DoMoveBuffs']       = {
            DisplayName = "Do Movement Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Cast Movement Spells/AA.",
            Default = false,
            FAQ = "Why am I spamming movement buffs?",
            Answer = "Some move spells freely overwrite those of other classes, so if multiple movebuffs are being used, a buff loop may occur.\n" ..
                "Simply turn off movement buffs for the undesired class in their class options.",
        },
        ['DoChestClick']      = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your chest item",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoTwinHeal']        = {
            DisplayName = "Cast Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your Twin Heal nuke line (nuke that also heals).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoFireNuke']        = {
            DisplayName = "Fire/Combo Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your fire nuke line, later transitioning to the fire/nuke combo (Winter's Fire).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoColdNuke']        = {
            DisplayName = "Cold Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your cold nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoStunNuke']        = {
            DisplayName = "Stun Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Use your stun nuke, transitioning from the Stormborn stun line to the Roar damage nukes at level 93.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['RemoteNukeElement'] = {
            DisplayName = "Remote Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 105,
            Tooltip = "Pick which remote nuke to load: Fire (Remote Sun) or Cold (Remote Moon), which share a recast timer.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Fire (Remote Sun)', 'Cold (Remote Moon)', },
            Default = 1,
            Min = 1,
            Max = 2,
        },
        ['DoDicho']           = {
            DisplayName = "Dicho Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 106,
            Tooltip = "Use your Dicho nuke.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSummonedNuke']    = {
            DisplayName = "Do Summoned Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 107,
            Tooltip = "Use your anti-summoned nuke line ('x the Unnatural').",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoWrathDot']        = {
            DisplayName = "Wrath Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Nature's Wrath line Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSunDot']          = {
            DisplayName = "Sun Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your Sun line Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoHordeDot']        = {
            DisplayName = "Horde Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use your Horde line Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['SunMoonDotChoice']  = {
            DisplayName = "Sun/Moon Dot Choice",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Use your Sunray (fire) or Moonbeam (cold) Dot (they share a timer).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'None', 'Fire (Sunray)', 'Cold (Moonbeam)', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoChillDot']        = {
            DisplayName = "Chill Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 105,
            Tooltip = "Use the Chill (cold) Dot.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DotNamedOnly']      = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 106,
            Tooltip = "Only apply DoTs to named mobs.",
            Default = true,
        },
        ['DoHPBuff']          = {
            DisplayName = "Group HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Use your group HP Buff. Disable as desired to prevent conflicts with CLR or PAL buffs.",
            Default = true,
            FAQ = "Why am I in a buff war with my Paladin or Druid? We are constantly overwriting each other's buffs.",
            Answer = "Disable [DoHPBuff] to prevent issues with Aego/Symbol lines overwriting. Alternatively, you can adjust the settings for the other class instead.",
        },
        ['DoTempHP']          = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Use Temp HP Buff (Only for WAR, other tanks have their own)",
            RequiresLoadoutChange = true,
            Default = false,
            FAQ = "Why isn't my Temp HP Buff being used?",
            Answer = "You either have [DoTempHP] disabled, or you don't have a Warrior in your group (Other tanks have their own Temp HP Buff).",
        },
        ['DoReptile']         = {
            DisplayName = "Reptile Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Keep your Reptile buff on warrior and shadowknight tanks.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoGroupRegen']      = {
            DisplayName = "Group Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Group Regen buff.",
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoTwincast']        = {
            DisplayName = "Use Twincast Spell",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use your Twincast spell during burns.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoSnare']           = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare (Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']        = {
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
        ['DoRoDebuff']        = {
            DisplayName = "Use Ro Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use the Ro debuff (lowers fire resist, AC, and attack); single-target or AE is chosen automatically by mob count.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['AERoCount']         = {
            DisplayName = "AE Ro Min Mobs",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "Use the AE Ro debuff (Vortex of Ro) instead of single-target once this many mobs are on aggro.",
            Default = 2,
            Min = 1,
            Max = 99,
        },
        ['DoFrostDebuff']     = {
            DisplayName = "Frost Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 103,
            Tooltip = "Use your Frost debuff line (lowers attack and AC).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoBreathDebuff']    = {
            DisplayName = "Breath Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 104,
            Tooltip = "Use your Breath debuff line (lowers AC, raises cold damage taken).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoBarkspur']        = {
            DisplayName = "Use Barkspur",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your short duration damage shield (Barkspur line) on tanks during combat.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoHealSpell']       = {
            DisplayName = "Use Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use your standard single-target heal spell.",
            RequiresLoadoutChange = true,
            Default = mq.TLO.Me.Level() < 110,
        },
        ['QuickHealUse']      = {
            DisplayName = "Quick Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use the fast single-target heal (Rejuvilation line) as an emergency (Big) or standard (Main) heal.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Emergency Use(BigHeal)', 'Standard Use(MainHeal)', },
            Default = 2,
            Min = 1,
            Max = 2,
        },
        ['QuickHealSurgeUse'] = {
            DisplayName = "Quick Surge Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 103,
            Tooltip = "Use the burst single-target heal (Adrenaline line) as an emergency (Big) or standard (Main) heal.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Emergency Use(BigHeal)', 'Standard Use(MainHeal)', },
            Default = 2,
            Min = 1,
            Max = 2,
        },
        ['MemPromHeal']       = {
            DisplayName = "Mem Promised Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip = "Memorize the Promised (delayed) heal. Please note this ability use is not automated; this memorization option is for manual use (e.g, pre-pull, etc).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['MemPoisonCure']     = {
            DisplayName = "Mem Poison Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Memorize a poison cure for combat use (individual cure early, group cure once learned). We will already use this spell in downtime as needed.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['MemDiseaseCure']    = {
            DisplayName = "Mem Disease Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Memorize a disease cure for combat use (individual cure early, group cure once learned). We will already use this spell in downtime as needed.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['MemCurseCure']      = {
            DisplayName = "Mem Curse Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 103,
            Tooltip = "Memorize a curse cure for combat use (individual cure early, group cure once learned). We will already use this spell in downtime as needed.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['MemCorruptCure']    = {
            DisplayName = "Mem Corrupt Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 104,
            Tooltip = "Memorize a corruption cure for combat use (chant cure early, single-target cure once learned). We will already use this spell in downtime as needed.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['HealPriority']      = {
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
}
return _ClassConfig
