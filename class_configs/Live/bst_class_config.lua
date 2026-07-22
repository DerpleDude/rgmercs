local mq        = require('mq')
local Casting   = require("utils.casting")
local Combat    = require('utils.combat')
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Targeting = require("utils.targeting")

return {
    _version              = "1.4 - Live",
    _author               = "Derple, Algar",
    ['Modes']             = {
        'DPS',
    },
    ['ModeChecks']        = {
        IsHealing = function() return Config:GetSetting('DoHealSpell') end,
        IsCuring = function() return Config:GetSetting('DoCures') end,
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Nature's Salve", selfOnly = true, },
        },
    },
    ['PetPosition']       = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function()
            local cdAA = mq.TLO.Me.AltAbility("Companion's Discipline")
            return (cdAA and cdAA.Rank() or 0) >= 4 and "Companion's Discipline"
        end,
    },
    ['Themes']            = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.20, g = 0.11, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.20, g = 0.11, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.50, g = 0.28, b = 0.03, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.33, g = 0.18, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.50, g = 0.28, b = 0.03, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.20, g = 0.11, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.90, g = 0.45, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.90, g = 0.45, b = 0.05, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {                  --TODO: Add Omens Chest
        ['Epic'] = {
            "Savage Lord's Totem",             -- Epic    -- Epic 1.5
            "Spiritcaller Totem of the Feral", -- Epic    -- Epic 2.0
        },
        ['OoW_Chest'] = {
            "Beast Tamer's Jerkin",
            "Savagesoul Jerkin of the Wilds",
        },
        ['Coating'] = {
            "Spirit Drinker's Coating",
            "Blood Drinker's Coating",
        },
    },
    ['AbilitySets']       = {       --TODO/Under Consideration: Add AoE Roar line, add rotation entry (tie it to Do AoE setting), swap in instead of lance 2, especially since the last lance2 is level 112
        ['SwarmPet'] = {
            "Bark at the Moon XII", -- Level 130
            "Shriek at the Moon",   -- Level 125
            "Bellow at the Moon",   -- Level 120
            "Bay at the Moon",      -- Level 115
            "Roar at the Moon",     -- Level 110
            "Cry at the Moon",      -- Level 105
            "Yell at the Moon",     -- Level 100
            "Scream at the Moon",   -- Level 95
            "Shout at the Moon",    -- Level 90
            "Yowl at the Moon",     -- Level 85
            "Howl at the Moon",     -- Level 80
            "Bark at the Moon",     -- Level 75
            "Bestial Empathy",      -- Level 68
        },
        ['Feralgia'] = {
            -- Swarm Pet and Growl combination
            "Grimclaw's Feralgia",   -- Level 130
            "SingleMalt's Feralgia", -- Level 125
            "Ander's Feralgia",      -- Level 120
            "Griklor's Feralgia",    -- Level 115
            "Akalit's Feralgia",     -- Level 110
            "Krenk's Feralgia",      -- Level 105
            "Kesar's Feralgia",      -- Level 100
            "Yahnoa's Feralgia",     -- Level 95
            "Tuzil's Feralgia",      -- Level 90
            "Haergen's Feralgia",    -- Level 85
        },
        ['FrozenPoi'] = {
            -- Cold/Poison Nuke Fast Cast
            "Frozen Venom X",    -- Level 128
            "Frozen Creep",      -- Level 123
            "Frozen Blight",     -- Level 118
            "Frozen Malignance", -- Level 113
            "Frozen Toxin",      -- Level 108
            "Frozen Miasma",     -- Level 103
            "Frozen Carbomate",  -- Level 99
            "Frozen Cyanin",     -- Level 94
            "Frozen Venin",      -- Level 89
            "Frozen Venom",      -- Level 84
        },
        ['Maelstrom'] = {
            -- Cold/Poison/Disease Nuke Fast Cast
            "Tallongast's Maelstrom", -- Level 130
            "Rimeclaw's Maelstrom",   -- Level 125
            "Va Xakra's Maelstrom",   -- Level 120
            "Vkjen's Maelstrom",      -- Level 115
            "Beramos' Maelstrom",     -- Level 110
            "Visoracius' Maelstrom",  -- Level 105
            "Nak's Maelstrom",        -- Level 100
            "Bale's Maelstrom",       -- Level 95
            "Kron's Maelstrom",       -- Level 90
        },
        ['PoiBite'] = {
            -- Poison Nuke Fast Cast
            "Khrosik's Bite",       -- Level 129
            "Mortimus' Bite",       -- Level 123
            "Zelniak's Bite",       -- Level 118
            "Bloodmaw's Bite",      -- Level 113
            "Mawmun's Bite",        -- Level 108
            "Kreig's Bite",         -- Level 103
            "Poantaar's Bite",      -- Level 98
            "Rotsil's Bite",        -- Level 93
            "Sarsez' Bite",         -- Level 88
            "Bite of the Vitrik",   -- Level 83
            "Bite of the Borrower", -- Level 78
            "Bite of the Empress",  -- Level 73
        },
        ['Icelance1'] = {
            -- Lance 1 Timer 7 Ice Nuke Fast Cast
            "Frigid Lance XII",      -- Level 128, - Timer 7
            "Crystalline Lance",     -- Level 117, - Timer 7
            "Frostbite Lance",       -- Level 107, - Timer 7
            "Kromrif Lance",         -- Level 99, - Timer 7
            "Glacial Lance",         -- Level 89, - Timer 7
            "Jagged Torrent",        -- Level 79, - Timer 7
            "Ancient: Savage Ice",   -- Level 70, - Timer 7
            "Ancient: Frozen Chaos", -- Level 65, - Timer 7
            "Frost Spear",           -- Level 63, - Timer 7
            "Blizzard Blast",        -- Level 59, - Timer ???
            "Frost Shard",           -- Level 47, - Timer 7
            "Blast of Frost",        -- Level 12, - Timer 7
        },
        ['Icelance2'] = {
            -- Lance 2 Timer 11 Ice Nuke Fast Cast
            "Ankexfen Lance",  -- Level 122, - Timer 11
            "Restless Lance",  -- Level 112, - Timer 11
            "Kromtus Lance",   -- Level 102, - Timer 11
            "Frostrift Lance", -- Level 94, - Timer 11
            "Frigid Lance",    -- Level 84, - Timer 11
            "Spiked Sleet",    -- Level 74, - Timer 11
            "Glacier Spear",   -- Level 69, - Timer 11
            "Trushar's Frost", -- Level 65, - Timer 11
            "Ice Shard",       -- Level 54, - Timer 11
            "Ice Spear",       -- Level 33, - Timer 11
        },
        ['AERoar'] = {
            -- PBAE Roar Timer 11 Ice Nuke Fast Cast
            "Glacial Roar IX", -- Level 129
            "Hoarfrost Roar",  -- Level 124, - Timer 11
            "Polar Roar",      -- Level 119, - Timer 11
            "Restless Roar",   -- Level 114, - Timer 11
            "Frostbite Roar",  -- Level 109, - Timer 11
            "Kromtus Roar",    -- Level 104, - Timer 11
            "Kromrif Roar",    -- Level 99, - Timer 11
            "Frostrift Roar",  -- Level 94, - Timer 11
            "Glacial Roar",    -- Level 89, - Timer 11
        },
        ['EndemicDot'] = {
            "Tsetsian Endemic XII",  -- Level 127
            "Fevered Endemic",       -- Level 122
            "Vampyric Endemic",      -- Level 117
            "Neemzaq's Endemic",     -- Level 112
            "Elkikatar's Endemic",   -- Level 107
            "Hemocoraxius' Endemic", -- Level 102
            "Natigo's Endemic",      -- Level 97
            "Silbar's Endemic",      -- Level 92
            "Shiverback Endemic",    -- Level 87
            "Tsetsian Endemic",      -- Level 82
            "Fever Surge",           -- Level 77
            "Fever Spike",           -- Level 72
            "Festering Malady",      -- Level 70
            "Plague",                -- Level 65
            "Malaria",               -- Level 40
            "Sicken",                -- Level 14
        },
        ['BloodDot'] = {
            "Spiter Blood",        -- Level 127
            "Forgebound Blood",    -- Level 121
            "Akhevan Blood",       -- Level 116
            "Ikatiar's Blood",     -- Level 111
            "Polybiad Blood",      -- Level 106
            "Glistenwing Blood",   -- Level 101
            "Asp Blood",           -- Level 96
            "Binaesa Blood",       -- Level 91
            "Spinechiller Blood",  -- Level 86
            "Ikaav Blood",         -- Level 81
            "Falrazim's Gnashing", -- Level 76
            "Diregriffon's Bite",  -- Level 71
            "Chimera Blood",       -- Level 66
            "Turepta Blood",       -- Level 65
            "Scorpion Venom",      -- Level 61
            "Venom of the Snake",  -- Level 52
            "Envenomed Breath",    -- Level 35
            "Tainted Breath",      -- Level 19
        },
        ['ColdDot'] = {
            "Shar`Drahn's Chill", -- Level 130
            "Lazam's Chill",      -- Level 124
            "Sylra Fris' Chill",  -- Level 119
            "Endaroky's Chill",   -- Level 114
            "Ekron's Chill",      -- Level 109
            "Kirchen's Chill",    -- Level 104
            "Edoth's Chill",      -- Level 99
        },
        ['SlowSpell'] = {
            -- Slow Spell
            "Sha's Reprisal",  -- Level 87
            "Sha's Legacy",    -- Level 70
            "Sha's Revenge",   -- Level 65
            "Sha's Advantage", -- Level 60
            "Sha's Lethargy",  -- Level 50
            "Drowsy",          -- Level 20
        },
        ['DichoSpell'] = {
            -- Dicho Spell
            "Reciprocal Fury", -- Level 121
            "Ecliptic Fury",   -- Level 116
            "Composite Fury",  -- Level 111
            "Dissident Fury",  -- Level 106
            "Dichotomic Fury", -- Level 101
        },
        ['HealSpell'] = {
            "Lydora's Mending",    -- Level 127
            "Thornhost's Mending", -- Level 122
            "Korah's Mending",     -- Level 117
            "Bethun's Mending",    -- Level 112
            "Deltro's Mending",    -- Level 107
            "Sabhattin's Mending", -- Level 102
            "Jaerol's Mending",    -- Level 97
            "Mending of the Izon", -- Level 92
            "Jorra's Mending",     -- Level 87
            "Cadmael's Mending",   -- Level 82
            "Daria's Mending",     -- Level 77
            "Minohten Mending",    -- Level 72
            "Muada's Mending",     -- Level 67
            "Trushar's Mending",   -- Level 65
            "Chloroblast",         -- Level 59
            "Spirit Salve",        -- Level 48
            "Greater Healing",     -- Level 38
            "Healing",             -- Level 28
            "Light Healing",       -- Level 18
            "Minor Healing",       -- Level 6
            "Salve",               -- Level 1
        },
        ['PetHealSpell'] = {
            "Salve of Lydora",         -- Level 126
            "Salve of Homer",          -- Level 121
            "Salve of Jaegir",         -- Level 116
            "Salve of Tobart",         -- Level 111
            "Salve of Artikla",        -- Level 106
            "Salve of Clorith",        -- Level 101
            "Salve of Blezon",         -- Level 96
            "Salve of Yubai",          -- Level 91
            "Salve of Sevna",          -- Level 86
            "Salve of Reshan",         -- Level 81
            "Salve of Feldan",         -- Level 76
            "Healing of Uluanes",      -- Level 71
            "Healing of Mikkily",      -- Level 66
            "Healing of Sorsha",       -- Level 61
            "Sha's Restoration",       -- Level 55
            "Aid of Khurenz",          -- Level 52
            "Vigor of Zehkes",         -- Level 49
            "Yekan's Recovery",        -- Level 36
            "Herikol's Soothing",      -- Level 27
            "Keshuval's Rejuvenation", -- Level 15
            "Sharik's Replenishing",   -- Level 9
        },
        ['PetSpell'] = {
            "Spirit of Orvain",     -- Level 128
            "Spirit of Shae",       -- Level 123
            "Spirit of Panthea",    -- Level 118
            "Spirit of Blizzent",   -- Level 113
            "Spirit of Akalit",     -- Level 108
            "Spirit of Avalit",     -- Level 103
            "Spirit of Lachemit",   -- Level 98
            "Spirit of Kolos",      -- Level 93
            "Spirit of Averc",      -- Level 88
            "Spirit of Hoshkar",    -- Level 83
            "Spirit of Silverwing", -- Level 78
            "Spirit of Uluanes",    -- Level 73
            "Spirit of Rashara",    -- Level 70
            "Spirit of Alladnu",    -- Level 68
            "Spirit of Sorsha",     -- Level 64
            "Spirit of Arag",       -- Level 62
            "Spirit of Khati Sha",  -- Level 60
            "Spirit of Khurenz",    -- Level 58
            "Spirit of Zehkes",     -- Level 56
            "Spirit of Omakin",     -- Level 54
            "Spirit of Kashek",     -- Level 46
            "Spirit of Yekan",      -- Level 39
            "Spirit of Herikol",    -- Level 30
            "Spirit of Keshuval",   -- Level 21
            "Spirit of Khaliz",     -- Level 15
            "Spirit of Sharik",     -- Level 8
        },
        ['PetGroupEndRegenProc'] = {
            --Pet Group End Regen Proc*
            "Fatiguing Bite VI", -- Level 128
            "Sapping Bite",      -- Level 123
            "Wearying Bite",     -- Level 117
            "Depleting Bite",    -- Level 112
            "Exhausting Bite",   -- Level 107
            "Fatiguing Bite",    -- Level 97
        },
        ['PetSpellGuard'] = {
            "Spellbreaker's Guard XI", -- Level 130
            "Spellbreaker's Synergy",  -- Level 125
            "Spellbreaker's Fortress", -- Level 120
            "Spellbreaker's Citadel",  -- Level 115
            "Spellbreaker's Keep",     -- Level 110
            "Spellbreaker's Palisade", -- Level 105
            "Spellbreaker's Ward",     -- Level 100
            "Spellbreaker's Armor",    -- Level 95
            "Spellbreaker's Rampart",  -- Level 90
            "Spellbreaker's Aegis",    -- Level 85
            "Spellbreaker's Bulwark",  -- Level 80
            "Spellbreaker's Guard",    -- Level 75
        },
        ['PetSlowProc'] = {
            --Pet Slow Proc*
            "Deadlock Jaws",  -- Level 90
            "Fellgrip Jaws",  -- Level 85
            "Lockfang Jaws",  -- Level 80
            "Steeltrap Jaws", -- Level 75
        },
        ['PetOffenseBuff'] = {
            "Pack Leader's Aggression", -- Level 126
            "Magna's Aggression",       -- Level 121
            "Panthea's Aggression",     -- Level 116
            "Horasug's Aggression",     -- Level 111
            "Virzak's Aggression",      -- Level 106
            "Sekmoset's Aggression",    -- Level 101
            "Plakt's Aggression",       -- Level 96
            "Mea's Aggression",         -- Level 91
            "Neivr's Aggression",       -- Level 86
        },
        ['PetDefenseBuff'] = {
            "Pack Leader's Protection", -- Level 126
            "Magna's Protection",       -- Level 121
            "Panthea's Protection",     -- Level 116
            "Horasug's Protection",     -- Level 111
            "Virzak's Protection",      -- Level 106
            "Sekmoset's Protection",    -- Level 101
            "Plakt's Protection",       -- Level 96
            "Mea's Protection",         -- Level 91
            "Neivr's Protection",       -- Level 86
        },
        ['PetHaste'] = {
            --Pet Haste*
            "Warder's Unity VI",      -- Level 129, combines haste and damage proc
            "Insatiable Voracity",    -- Level 123
            "Unsurpassed Velocity",   -- Level 118
            "Astounding Velocity",    -- Level 113
            "Tremendous Velocity",    -- Level 108
            "Extraordinary Velocity", -- Level 98
            "Exceptional Velocity",   -- Level 93
            "Incomparable Velocity",  -- Level 88
            "Unrivaled Rapidity",     -- Level 83
            "Peerless Penchant",      -- Level 78
            "Unparalleled Voracity",  -- Level 73
            "Growl of the Beast",     -- Level 68
            "Arag's Celerity",        -- Level 63
            "Sha's Ferocity",         -- Level 59
            "Omakin's Alacrity",      -- Level 55
            "Bond of The Wild",       -- Level 52
            "Yekan's Quickening",     -- Level 37
        },
        ['PetGrowl'] = {
            "Growl of the Panther XIV",     -- Level 129
            "Growl of the Clouded Leopard", -- Level 119
            "Growl of the Lioness",         -- Level 114
            "Growl of the Sabretooth",      -- Level 109
            "Growl of the Snow Leopard",    -- Level 99
            "Growl of the Lion",            -- Level 94
            "Growl of the Tiger",           -- Level 89
            "Growl of the Jaguar",          -- Level 84
            "Growl of the Puma",            -- Level 79
            "Growl of the Panther",         -- Level 69
            "Growl of the Leopard",         -- Level 61
        },
        ['PetHealProc'] = {
            --Pet Heal proc buff*
            "Protective Warder",   -- Level 118
            "Sympathetic Warder",  -- Level 113
            "Convivial Warder",    -- Level 108
            "Mending Warder",      -- Level 103
            "Invigorating Warder", -- Level 98
            "Empowering Warder",   -- Level 93
            "Bolstering Warder",   -- Level 88
            "Friendly Pet",        -- Level 83
        },
        ['PetDamageProc'] = {
            "Spirit of Irdrath",      -- Level 129
            "Spirit of Shoru",        -- Level 124
            "Spirit of Siver",        -- Level 119
            "Comrade's Unity",        -- Level 119
            "Spirit of Mandrikai",    -- Level 114
            "Ally's Unity",           -- Level 114
            "Spirit of Beramos",      -- Level 109
            "Spirit of Visoracius",   -- Level 104
            "Spirit of Nak",          -- Level 99
            "Spirit of Bale",         -- Level 94
            "Spirit of Kron",         -- Level 89
            "Spirit of Vaxztn",       -- Level 84
            "Spirit of Jeswin",       -- Level 79
            "Spirit of Lairn",        -- Level 74
            "Spirit of Oroshar",      -- Level 70
            "Spirit of Irionu",       -- Level 68
            "Spirit of Rellic",       -- Level 63
            "Spirit of Flame",        -- Level 56
            "Spirit of Snow",         -- Level 54
            "Spirit of the Storm",    -- Level 53
            "Spirit of Wind",         -- Level 51
            "Spirit of Vermin",       -- Level 46
            "Spirit of the Scorpion", -- Level 38
            "Spirit of Inferno",      -- Level 28
            "Spirit of the Blizzard", -- Level 18
            "Spirit of Lightning",    -- Level 13
        },
        ['UnityBuff'] = {
            -- --Combined ManaRegenBuff and AtkHPBuff
            "Feralist's Unity VII", -- Level 130
            "Wildfang's Unity",     -- Level 125
            "Chieftain's Unity",    -- Level 120
            "Reclaimer's Unity",    -- Level 115
            "Feralist's Unity",     -- Level 110
            "Stormblood's Unity",   -- Level 105
            "Spiritual Unity",      -- Level 100
        },
        ['KillShotBuff'] = {
            --Pet Dmg Absorb + HoT buff*
            "Warder's Alliance",     -- Level 121
            "Symbiotic Alliance",    -- Level 116
            "Natural Alliance",      -- Level 111
            "Natural Affiliation",   -- Level 101
            "Natural Cooperation",   -- Level 96
            "Natural Cooperation",   -- Level 96
            "Natural Collaboration", -- Level 91
        },
        ['RunSpeedBuff'] = {
            "Spirit of Tala'Tak", -- Level 79
            -- "Pack Shrew",          -- Level 44, ].
            -- Spirit of the Shrew Is Only 30% Speed Flat So Removed it from the List as its too slow
            -- "Spirit of the Shrew", -- Level 39, ],
            "Spirit of wolf", -- Level 24
        },
        ['ManaRegenBuff'] = {
            "Spiritual Enlightenment XVII", -- Level 128
            "Spiritual Enduement",          -- Level 123
            "Spiritual Erudition",          -- Level 118
            "Spiritual Insight",            -- Level 113
            "Spiritual Empowerment",        -- Level 108
            "Spiritual Elaboration",        -- Level 103
            "Spiritual Evolution",          -- Level 99
            "Spiritual Enrichment",         -- Level 94
            "Spiritual Enhancement",        -- Level 89
            "Spiritual Enhancement",        -- Level 89
            "Spiritual Edification",        -- Level 84
            "Spiritual Epiphany",           -- Level 79
            "Spiritual Enlightenment",      -- Level 74
            "Spiritual Ascendance",         -- Level 69
            "Spiritual Dominion",           -- Level 64
            "Spiritual Purity",             -- Level 59
            "Spiritual Radiance",           -- Level 52
            "Spiritual Light",              -- Level 41
        },
        ['AllianceDot'] = {
            -- Alliance Spell for Beastlords 100+
            "Venomous Covariance",  -- Level 123
            "Venomous Conjunction", -- Level 118
            "Venomous Coalition",   -- Level 113
            "Venomous Covenant",    -- Level 108
            "Venomous Alliance",    -- Level 101
        },
        ['PetBlockSpell'] = {
            "Aegis of Valorforged",  -- Level 124
            "Aegis of Rumblecrush",  -- Level 119
            "Aegis of Orfur",        -- Level 114
            "Aegis of Zeklor",       -- Level 109
            "Aegis of Japac",        -- Level 104
            "Aegis of Nefori",       -- Level 99
            "Beastwood Rampart",     -- Level 93
            "Spectral Rampart",      -- Level 88
            "Bulwark of Tri'Qaras",  -- Level 77
            "Dragonscale Guard",     -- Level 76
            "Mammoth-Hide Guard",    -- Level 71
            "Feral Guard",           -- Level 69
            "Protection of Calliav", -- Level 64
            "Guard of Calliav",      -- Level 58
            "Ward of Calliav",       -- Level 49
        },
        ['PetBlockAuspice'] = {
            -- Pet Block Auspice - Timer 16
            "Auspice of Usira",      -- Level 122
            "Auspice of Valia",      -- Level 117
            "Auspice of Kildrukaun", -- Level 112
            "Auspice of Esianti",    -- Level 107
            "Auspice of Eternity",   -- Level 102
            "Auspice of Shadows",    -- Level 96
        },
        ['PetHotSpell'] = {
            "Lydora's Melioration",  -- Level 127
            "Cissela's Melioration", -- Level 117
            "Kallis' Melioration",   -- Level 112
            "Virzak's Melioration",  -- Level 107
            "Tirik's Melioration",   -- Level 102
            "Huaene's Melioration",  -- Level 97
            "Yurv's Mending",        -- Level 92
            "Wilap's Mending",       -- Level 87
            "Minax's Mending",       -- Level 82
        },
        ['PetPromisedSpell'] = {
            "Promised Mending XII",    -- Level 128
            "Promised Reconstitution", -- Level 123
            "Promised Relief",         -- Level 118
            "Promised Healing",        -- Level 113
            "Promised Alleviation",    -- Level 108
            "Promised Invigoration",   -- Level 103
            "Promised Amelioration",   -- Level 98
            "Promised Amendment",      -- Level 93
            "Promised Wardmending",    -- Level 88
            "Promised Rejuvenation",   -- Level 83
            "Promised Recovery",       -- Level 78
            "Promised Mending",        -- Level 73
        },
        ['AvatarSpell'] = {
            -- Str Stam Dex Buff
            "Infusion of Spirit", -- Level 61
        },
        ['PetCrippleBite'] = {
            "Dire Bite", -- Level 117
        },
        ['FocusSpell'] = {
            "Focus of Aramna",        -- Level 126
            "Focus of Skull Crusher", -- Level 121
            "Focus of Jaegir",        -- Level 116
            "Focus of Tobart",        -- Level 111
            "Focus of Artikla",       -- Level 106
            "Focus of Okasi",         -- Level 101
            "Focus of Sanera",        -- Level 96
            "Focus of Klar",          -- Level 91
            "Focus of Emiq",          -- Level 86
            "Focus of Yemall",        -- Level 81
            "Focus of Zott",          -- Level 76
            -- Group Focus Spells
            "Focus of Amilan",        -- Level 71
            "Focus of Alladnu",       -- Level 67
            "Talisman of Kragg",      -- Level 62
            "Talisman of Altuna",     -- Level 58
            "Talisman of Tnarg",      -- Level 53
            "Inner Fire",             -- Level 7
        },
        ['AtkHPBuff'] = {
            "Spiritual Vigor XV",     -- Level 127
            "Spiritual Valiancy",     -- Level 122
            "Spiritual Vehemence",    -- Level 112
            "Spiritual Vibrancy",     -- Level 107
            "Spiritual Vivification", -- Level 102
            "Spiritual Vindication",  -- Level 97
            "Spiritual Valiance",     -- Level 92
            "Spiritual Valor",        -- Level 87
            "Spiritual Verve",        -- Level 82
            "Spiritual Vivacity",     -- Level 77
            "Spiritual Vim",          -- Level 72
            "Spiritual Vitality",     -- Level 67
            "Spiritual Vigor",        -- Level 62
            "Spiritual Vigor",        -- Level 62
            "Spiritual Strength",     -- Level 60
            --Single Target Atk+HP Buff* - Does Not Stack with Pally brells or Ranger Buff - is Middle ground Buff has HP & Atk
            "Spiritual Brawn",        -- Level 42
        },
        ['AtkBuff'] = {
            -- - Single Ferocity
            "Shared Merciless Ferocity", -- Level 100
            -- Group Ferocity
            "Shared Brutal Ferocity",    -- Level 95
            "Brutal Ferocity",           -- Level 92
            "Callous Ferocity",          -- Level 90
            "Savage Ferocity",           -- Level 85
            "Vicious Ferocity",          -- Level 80
            "Ruthless Ferocity",         -- Level 75
            "Ferocity of Irionu",        -- Level 70
            "Ferocity",                  -- Level 65
            "Savagery",                  -- Level 60
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
        ['Maul'] = {
            -- Maul Disc - This is Used with Beastlord Synergy Buffs
            "Harrow XII", -- Level 129
            "Wallop",     -- Level 124
            "Clobber",    -- Level 119
            "Batter",     -- Level 114
            "Mangle",     -- Level 109
            "Maul",       -- Level 104
            "Pummel",     -- Level 100
            "Barrage",    -- Level 95
            "Rush",       -- Level 90
            "Foray",      -- Level 85
            "Harrow",     -- Level 80
            "Rake",       -- Level 70
        },
        ['SingleClaws'] = {
            --Single target claws*
            "Focused Clamor of Claws", -- Level 98
        },
        ['BestialBuffDisc'] = {
            "Bestial Vivisection VI", -- Level 126
            "Bestial Fierceness",     -- Level 116
            "Bestial Savagery",       -- Level 106
            "Bestial Evulsing",       -- Level 96
            "Bestial Rending",        -- Level 91
            "Bestial Vivisection",    -- Level 86
        },
        ['AEClaws'] = {
            "Flurry of Claws IX", -- Level 127
            "Barrage of Claws",   -- Level 122
            "Eruption of Claws",  -- Level 117
            "Maelstrom of Claws", -- Level 112
            "Storm of Claws",     -- Level 107
            "Tempest of Claws",   -- Level 102
            "Clamor of Claws",    -- Level 97
            "Tumult of Claws",    -- Level 92
            "Flurry of Claws",    -- Level 87
        },
        ['FuryDisc'] = {
            --HHE Burn Disc* - Dicho/Dissident Replace this @ 101 outside of burns
            "Ruaabri's Fury", -- Level 98
            "Kolos' Fury",    -- Level 93
            "Nature's Fury",  -- Level 88
        },
        ['DmgModDisc'] = {
            --All Skills Damage Modifier*
            "Savage Rancor",           -- Level 104
            "Savage Rage",             -- Level 99
            "Savage Fury",             -- Level 94
            "Empathic Fury",           -- Level 69
            "Bestial Fury Discipline", -- Level 60
        },
        ['EndRegenProcDisc'] = {
            "Reflexive Slashing",  -- Level 124
            "Reflexive Riving",    -- Level 114
            "Reflexive Sundering", -- Level 105
            "Reflexive Rending",   -- Level 100
        },
        ['VinDisc'] = {
            -- Vindication Disc
            "Xanathan's Vindication", -- Level 125
            "Kejaan's Vindication",   -- Level 120
            "Ikatiar's Vindication",  -- Level 115
            "Ikatiar's Vindication",  -- Level 115
            "Venon's Vindication",    -- Level 110
            "Al`ele's Vindication",   -- Level 102
        },
    },
    ['HealRotationOrder'] = {
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Config:GetSetting('DoHealSpell') end,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['MainHealPoint'] = {
            {
                name = "HealSpell",
                type = "Spell",
            },
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
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and Casting.AmIBuffable()
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
        {
            name = 'Emergency',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99))
            end,
        },
        {
            name = 'PetHealing',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, target) return (mq.TLO.Me.Pet.PctHPs() or 100) < Config:GetSetting('PetHealPct') end,
        },
        {
            name = 'FocusedParagon',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoParagon') and Casting.CanUseAA("Focused Paragon of Spirits") end,
            targetId = function(self) return { Combat.FindWorstHurtMana(Config:GetSetting('FParaPct')), } end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Config:GetSetting('DowntimeFP') and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and not Casting.IHaveBuff(mq.TLO.Me.AltAbility('Paragon of Spirit').Spell) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Slow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSlow') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            reorderable = false,
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
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Helpers']           = {
        FlurryActive = function(self)
            local fury = self.ResolvedActionMap['FuryDisc']
            local dicho = self.ResolvedActionMap['DichoSpell']
            return (dicho and dicho() and Casting.IHaveBuff(dicho.Name()))
                or (fury and fury() and Casting.IHaveBuff(fury.Name()))
        end,
        DmgModActive = function(self) --Song active by name will check both Bestial Alignments (Self and Group)
            local disc = self.ResolvedActionMap['DmgModDisc']
            return Casting.IHaveBuff("Bestial Alignment") or (disc and disc() and Casting.IHaveBuff(disc.Name()))
                or Casting.IHaveBuff("Ferociousness")
        end,
        UsingFeralgia = function()
            return Config:GetSetting('DoFeralgia') and Core.GetResolvedActionMapItem('Feralgia')
        end,
    },
    ['Rotations']         = {
        ['Burn'] = {
            {
                name = "Group Bestial Alignment",
                type = "AA",
                cond = function(self, aaName)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Attack of the Warder",
                type = "AA",
            },
            {
                name = "Frenzy of Spirit",
                type = "AA",
            },
            {
                name = "Bloodlust",
                type = "AA",
            },
            {
                name = "VinDisc",
                type = "Disc",
            },
            {
                name = "Spire of the Savage Lord",
                type = "AA",
            },
            {
                name = "Companion's Fury",
                type = "AA",
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoChestClick') end,
                cond = function(self, itemName, target)
                    if not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Frenzied Swipes",
                type = "AA",
            },
            {
                name = "BloodDot",
                type = "Spell",
                cond = function(self, spell, target)
                    local vinDisc = self.ResolvedActionMap['VinDisc']
                    if not vinDisc then return false end
                    return Casting.IHaveBuff(vinDisc)
                end,
            },
            {
                name = "FuryDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return not self.Helpers.FlurryActive(self)
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
                load_cond = function(self) return Core.GetResolvedActionMapItem('DichoSpell') end,
                cond = function(self, aaName)
                    local dichoSpell = Core.GetResolvedActionMapItem('DichoSpell')
                    return not self.Helpers.FlurryActive(self) and (mq.TLO.Me.GemTimer(dichoSpell.RankName())() or -1) > 15
                end,
            },
            {
                name = "DmgModDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Ferociousness",
                type = "AA",
                cond = function(self, aaName, target)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Bestial Alignment",
                type = "AA",
                cond = function(self, aaName)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Slow'] = {
            {
                name = "Sha's Reprisal",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Sha's Reprisal") end,
                cond = function(self, aaName, target)
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and (aaSpell.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSpell",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Sha's Reprisal") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (spell.RankName.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Falsified Death",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('AggroFeign') then return false end
                    return (mq.TLO.Me.PctHPs() <= 40 and Targeting.IHaveAggro(100)) or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99) and not Core.IsTanking()
                end,
            },
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 35
                end,
            },
            {
                name = "Warder's Gift",
                type = "AA",
                cond = function(self, aaName)
                    return (mq.TLO.Me.Pet.PctHPs() or 0) > 50
                end,
            },
            {
                name = "Protection of the Warder",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
        ['FocusedParagon'] = {
            {
                name = "Focused Paragon of Spirits",
                type = "AA",
            },
        },
        ['PetHealing'] = {
            {
                name = "Mend Companion",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name = "Companion's Fortification",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name = "PetHealSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPetHealSpell') end,
            },
        },
        ['DPS'] = {
            {
                name = "PetSpell",
                type = "Spell",
                cond = function(self, spell)
                    return mq.TLO.Me.Pet.ID() == 0
                end,
            },
            {
                name = "Paragon of Spirit",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoParagon') end,
                cond = function(self, aaName)
                    return (mq.TLO.Group.LowMana(Config:GetSetting('ParaPct'))() or -1) > 0
                end,
            },
            {
                name = "DichoSpell",
                type = "Spell",
                cond = function(self, spell)
                    return not self.Helpers.FlurryActive(self)
                end,
            },
            {
                name = "Feralgia",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UsingFeralgia() end,
                cond = function(self, spell, target)
                    --This checks to see if the Growl portion is up on the pet (or about to expire) before using this, those who prefer the swarm pets can use the actual swarm pet spell in conjunction with this for mana savings.
                    --There are some instances where the Growl isn't needed, but that is a giant TODO and of minor benefit.
                    ---@diagnostic disable-next-line: undefined-field -- total seconds not recognized for buffduration
                    return (mq.TLO.Pet.BuffDuration(spell.RankName.Trigger(2)).TotalSeconds() or 0) < 10
                end,
            },
            {
                name = "BloodDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "ColdDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "EndemicDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Maelstrom",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FrozenPoi",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "PoiBite",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Icelance1",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Icelance2",
                type = "Spell",
                load_cond = function(self) return not Config:GetSetting('DoAERoar') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "AERoar",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAERoar') end,
                cond = function(self, spell, target)
                    if not Config:GetSetting("DoAEDamage") then return false end
                    return Casting.OkayToNuke() and Combat.AETargetCheck(true)
                end,
            },
            {
                name = "SwarmPet",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSwarmPet') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke()
                end,
            },
        },
        ['Weaves'] = {
            {
                name = "Round Kick",
                type = "Ability",
                load_cond = function(self) return Casting.CanUseAA("Feral Swipe") end,
            },
            {
                name = "Kick",
                type = "Ability",
                load_cond = function(self) return not Casting.CanUseAA("Feral Swipe") end,
            },
            {
                name = "Tiger Claw",
                type = "Ability",
            },
            {
                name = "Enduring Frenzy",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.GetTargetPctHPs() > 90
                end,
            },
            {
                name = "EndRegenProcDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return mq.TLO.Me.PctEndurance() < Config:GetSetting('ParaPct')
                end,
            },
            {
                name = "Chameleon Strike",
                type = "AA",
            },
            {
                name = "SingleClaws",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return not Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "AEClaws",
                type = "Disc",
                cond = function(self, discSpell, target)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "Maul",
                type = "Disc",
            },
            {
                name = "BestialBuffDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Consumption of Spirit",
                type = "AA",
                cond = function(self, aaName)
                    return (mq.TLO.Me.PctHPs() > 90 and mq.TLO.Me.PctMana() < 60)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "AvatarSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAvatar') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "AtkBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    -- Make sure this is gemmed due to long refresh, and only use the single target versions on classes that need it.
                    if ((spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target)) or not Casting.CastReady(spell) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "UnityBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    local atkHPBuff = self:GetResolvedActionMapItem('AtkHPBuff')
                    local manaRegenBuff = self:GetResolvedActionMapItem('ManaRegenBuff')
                    local triggerone = atkHPBuff and atkHPBuff.Level() or 999
                    local triggertwo = manaRegenBuff and manaRegenBuff.Level() or 999
                    if (spell.Level() or 0) < (triggerone or triggertwo) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ManaRegenBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "AtkHPBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    -- Only use the single target versions on classes that need it
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "FocusSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    -- Only use the single target versions on classes that need it
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                cond = function(self, spell)
                    return mq.TLO.Me.Pet.ID() == 0
                end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "Consumption of Spirit",
                type = "AA",
                cond = function(self, aaName)
                    return (mq.TLO.Me.PctHPs() > 70 and mq.TLO.Me.PctMana() < 80)
                end,
            },
            {
                name = "Feralist's Unity",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "KillShotBuff",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Feralist's Unity") end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Pact of The Wurine",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "Epic",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoEpic') end,
                cond = function(self, itemName)
                    return not mq.TLO.Me.PetBuff("Savage Wildcaller's Blessing")() and not mq.TLO.Me.PetBuff("Might of the Wild Spirits")()
                end,
            },
            {
                name = "Hobble of Spirits",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('PetProcChoice') == 2 end,
                cond = function(self, aaName, target)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "AvatarSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAvatar') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetOffenseBuff",
                type = "Spell",
                load_cond = function(self) return not Config:GetSetting('DoTankPet') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetDefenseBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTankPet') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetSlowProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('PetProcChoice') == 1 end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetHaste",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell, nil, true)
                end,
            },
            {
                name = "PetDamageProc",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetHealProc",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetSpellGuard",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSpellGuard') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetGrowl",
                type = "Spell",
                load_cond = function(self) return not self.Helpers.UsingFeralgia() end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Companion's Aegis",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Default Mode",
            spells = {
                { name = "Icelance1", },
                { name = "AERoar",       cond = function() return Config:GetSetting('DoAERoar') end, },
                { name = "Icelance2",    cond = function() return not Config:GetSetting('DoAERoar') end, },
                { name = "BloodDot", },
                { name = "ColdDot", },
                { name = "EndemicDot", },
                { name = "AtkBuff", },
                { name = "SlowSpell",    cond = function() return Config:GetSetting('DoSlow') and not Casting.CanUseAA("Sha's Reprisal") end, },
                { name = "DichoSpell", },
                { name = "Feralgia",     cond = function(self) return self.Helpers.UsingFeralgia() end, },
                { name = "PetGrowl",     cond = function(self) return not self.Helpers.UsingFeralgia() end, },
                { name = "PoiBite", },
                { name = "Maelstrom", },
                { name = "FrozenPoi", },
                { name = "HealSpell",    cond = function() return Config:GetSetting('DoHealSpell') end, },
                { name = "PetHealSpell", cond = function() return Config:GetSetting('DoPetHealSpell') end, },
                { name = "PetHealProc", },
                { name = "SwarmPet",     cond = function() return Config:GetSetting('DoSwarmPet') end, },
                { name = "RunSpeedBuff", cond = function() return Config:GetSetting('DoRunSpeed') end, },
            },
        },
    },
    ['PullAbilities']     = {
        {
            id = 'SlowAA',
            Type = "AA",
            DisplayName = "Sha's Reprisal",
            AbilityName = "Sha's Reprisal",
            AbilityRange = 150,
            cond = function(self)
                return Casting.CanUseAA("Sha's Reprisal")
            end,
        },
        {
            id = 'SlowSpell',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('SlowSpell')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('SlowSpell')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('SlowSpell')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']     = { --TODO: Condense pet proc options into a combo box and update entry conditions appropriately
        ['Mode']           = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Beastlords currently only have one Mode.",
        },
        --Other Recovery
        ['DoParagon']      = {
            DisplayName = "Use Paragon",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Use Group or Focused Paragon AAs.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['ParaPct']        = {
            DisplayName = "Paragon %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "Minimum mana % before we use Paragon of Spirit.",
            Default = 80,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
        },
        ['FParaPct']       = {
            DisplayName = "F.Paragon %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            Tooltip = "Minimum mana % before we use Focused Paragon.",
            Default = 90,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
        },
        ['DowntimeFP']     = {
            DisplayName = "Downtime F.Paragon",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip = "Use Focused Paragon outside of Combat.",
            Default = false,
            ConfigType = "Advanced",
        },
        --Pet Buffs
        ['DoTankPet']      = {
            DisplayName = "Do Tank Pet Buffs",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Buffs",
            Index = 101,
            Tooltip = "Use abilities designed for your pet to tank.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['PetProcChoice']  = {
            DisplayName = "Pet Proc Choice:",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Buffs",
            Index = 102,
            Tooltip = "Select your preferred pet proc buff type.",
            Type = "Combo",
            ComboOptions = { 'Slow', 'Snare', },
            Default = 1,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['DoSpellGuard']   = {
            DisplayName = "Do Spellguard",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Buffs",
            Index = 103,
            Tooltip = "Do Pet Spell Guard. (Warning! Long refresh time.)",
            Default = false,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['DoFeralgia']     = {
            DisplayName = "Do Feralgia",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Buffs",
            Index = 105,
            Tooltip = "Use Feralgia for the Growl Effect on your Pet instead of the Growl Spell.",
            Default = true,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        -- Swarm Pets
        ['DoSwarmPet']     = {
            DisplayName = "Do Swarm Pet",
            Group = "Abilities",
            Header = "Pet",
            Category = "Swarm Pets",
            Index = 101,
            Tooltip = "Use your Swarm Pet spell in addition to Feralgia",
            Default = false,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            FAQ = "Why am I only using swarm pets every couple of minutes?",
            Answer = "By default, our only source of swarm pet is the Feralgia line. In many situations, using swarm pets outside of this can be a DPS loss.\n" ..
                "For those situations where swarm pet DPS is greatly boosted (BRD SHM and MAG in group comes to mind), you can enable Do Swarm Pet to summon them outside of Feralgia.",
        },
        -- General Healing
        ['DoHealSpell']    = {
            DisplayName = "Do Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Mending spell.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoPetHealSpell'] = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Mem and cast your Pet Heal spell. AA Pet Heals are always used in emergencies.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        -- Healing Thresholds
        ['PetHealPct']     = {
            DisplayName = "Pet Heal Spell HP%",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Tooltip = "Use your pet heal spell when your pet is at or below this HP percentage.",
            Default = 80,
            Min = 1,
            Max = 99,
        },

        --Abilities
        ['DoSlow']         = {
            DisplayName = "Do Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = "Use your slow spell or AA.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoRunSpeed']     = {
            DisplayName = "Do Run Speed",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Do Run or Move Speed Spells/AAs",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why are my buffers in a run speed buff war?",
            Answer = "Many run speed spells freely stack and overwrite each other, you will need to disable Run Speed Buffs on some of the buffers.",
        },
        ['DoAvatar']       = {
            DisplayName = "Do Avatar",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Buff Group/Pet with Infusion of Spirit",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoVetAA']        = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        --Combat
        ['DoAERoar']       = {
            DisplayName = "Use AE Roar",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "Use your AE Roar (Timer 11) spell line.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['EmergencyStart'] = {
            DisplayName = "Emergency HP%",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Your HP % before we begin to use emergency mitigation abilities.",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['AggroFeign']     = {
            DisplayName = "Emergency Feign",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Use your Feign AA when you have aggro at low health or aggro on a mob detected as a 'named' by RGMercs (see Named tab)..",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoCoating']      = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 103,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoChestClick']   = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your chest item during burns.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['DoEpic']         = {
            DisplayName = "Do Epic",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your Epic Weapon.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['HealPriority']   = {
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
                "  This config should perform well from from start to endgame, but a TLP or emu player may find it to be lacking exact customization for a specific era.\n\n" ..
                "  Additionally, those wishing more fine-tune control for specific encounters or raids should customize this config to their preference. \n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}
