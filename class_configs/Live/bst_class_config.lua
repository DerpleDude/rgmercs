local mq        = require('mq')
local Combat    = require('utils.combat')
local Config    = require('utils.config')
local Globals   = require("utils.globals")
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Logger    = require("utils.logger")

return {
    _version              = "1.4 - Live",
    _author               = "Derple, Algar",
    ['Modes']             = {
        'DPS',
    },
    ['ModeChecks']        = {
        IsHealing = function() return true end,
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
            "Bestial Empathy",      -- Level 68
            "Bark at the Moon",     -- Level 75
            "Howl at the Moon",     -- Level 80
            "Yowl at the Moon",     -- Level 85
            "Shout at the Moon",    -- Level 90
            "Scream at the Moon",   -- Level 95
            "Yell at the Moon",     -- Level 100
            "Cry at the Moon",      -- Level 105
            "Roar at the Moon",     -- Level 110
            "Bay at the Moon",      -- Level 115
            "Bellow at the Moon",   -- Level 120
            "Shriek at the Moon",   -- Level 125
        },
        ['Feralgia'] = {
            -- Swarm Pet and Growl combination
            "Grimclaw's Feralgia",   -- Level 130
            "Haergen's Feralgia",    -- Level 85
            "Tuzil's Feralgia",      -- Level 90
            "Yahnoa's Feralgia",     -- Level 95
            "Kesar's Feralgia",      -- Level 100
            "Krenk's Feralgia",      -- Level 105
            "Akalit's Feralgia",     -- Level 110
            "Griklor's Feralgia",    -- Level 115
            "Ander's Feralgia",      -- Level 120
            "SingleMalt's Feralgia", -- Level 125
        },
        ['FrozenPoi'] = {
            -- Cold/Poison Nuke Fast Cast
            "Frozen Venom X",    -- Level 128
            "Frozen Venom",      -- Level 84
            "Frozen Venin",      -- Level 89
            "Frozen Cyanin",     -- Level 94
            "Frozen Carbomate",  -- Level 99
            "Frozen Miasma",     -- Level 103
            "Frozen Toxin",      -- Level 108
            "Frozen Malignance", -- Level 113
            "Frozen Blight",     -- Level 118
            "Frozen Creep",      -- Level 123
        },
        ['Maelstrom'] = {
            -- Cold/Poison/Disease Nuke Fast Cast
            "Tallongast's Maelstrom", -- Level 130
            "Kron's Maelstrom",       -- Level 90
            "Bale's Maelstrom",       -- Level 95
            "Nak's Maelstrom",        -- Level 100
            "Visoracius' Maelstrom",  -- Level 105
            "Beramos' Maelstrom",     -- Level 110
            "Vkjen's Maelstrom",      -- Level 115
            "Va Xakra's Maelstrom",   -- Level 120
            "Rimeclaw's Maelstrom",   -- Level 125
        },
        ['PoiBite'] = {
            -- Poison Nuke Fast Cast
            "Khrosik's Bite",       -- Level 129
            "Bite of the Empress",  -- Level 73
            "Bite of the Borrower", -- Level 78
            "Bite of the Vitrik",   -- Level 83
            "Sarsez' Bite",         -- Level 88
            "Rotsil's Bite",        -- Level 93
            "Poantaar's Bite",      -- Level 98
            "Kreig's Bite",         -- Level 103
            "Mawmun's Bite",        -- Level 108
            "Bloodmaw's Bite",      -- Level 113
            "Zelniak's Bite",       -- Level 118
            "Mortimus' Bite",       -- Level 123
        },
        ['Icelance1'] = {
            -- Lance 1 Timer 7 Ice Nuke Fast Cast
            "Frigid Lance XII",      -- Level 128 - Timer 7
            "Blast of Frost",        -- Level 12 - Timer 7
            "Frost Shard",           -- Level 47 - Timer 7
            "Blizzard Blast",        -- Level 59 - Timer ???
            "Frost Spear",           -- Level 63 - Timer 7
            "Ancient: Frozen Chaos", -- Level 65 - Timer 7
            "Ancient: Savage Ice",   -- Level 70 - Timer 7
            "Jagged Torrent",        -- Level 79 - Timer 7
            "Glacial Lance",         -- Level 89 - Timer 7
            "Kromrif Lance",         -- Level 99 - Timer 7
            "Frostbite Lance",       -- Level 107 - Timer 7
            "Crystalline Lance",     -- Level 117 - Timer 7
        },
        ['Icelance2'] = {
            -- Lance 2 Timer 11 Ice Nuke Fast Cast
            "Ice Spear",       -- Level 33 - Timer 11
            "Ice Shard",       -- Level 54 - Timer 11
            "Trushar's Frost", -- Level 65 - Timer 11
            "Glacier Spear",   -- Level 69 - Timer 11
            "Spiked Sleet",    -- Level 74 - Timer 11
            "Frigid Lance",    -- Level 84 - Timer 11
            "Frostrift Lance", -- Level 94 - Timer 11
            "Kromtus Lance",   -- Level 102 - Timer 11
            "Restless Lance",  -- Level 112 - Timer 11
            "Ankexfen Lance",  -- Level 122 - Timer 11
        },
        ['AERoar'] = {
            -- PBAE Roar Timer 11 Ice Nuke Fast Cast
            "Glacial Roar IX", -- Level 129
            "Glacial Roar",    -- Level 89 - Timer 11
            "Frostrift Roar",  -- Level 94 - Timer 11
            "Kromrif Roar",    -- Level 99 - Timer 11
            "Kromtus Roar",    -- Level 104 - Timer 11
            "Frostbite Roar",  -- Level 109 - Timer 11
            "Restless Roar",   -- Level 114 - Timer 11
            "Polar Roar",      -- Level 119 - Timer 11
            "Hoarfrost Roar",  -- Level 124 - Timer 11
        },
        ['EndemicDot'] = {
            "Tsetsian Endemic XII",  -- Level 127
            "Sicken",                -- Level 14
            "Malaria",               -- Level 40
            "Plague",                -- Level 65
            "Festering Malady",      -- Level 70
            "Fever Spike",           -- Level 72
            "Fever Surge",           -- Level 77
            "Tsetsian Endemic",      -- Level 82
            "Shiverback Endemic",    -- Level 87
            "Silbar's Endemic",      -- Level 92
            "Natigo's Endemic",      -- Level 97
            "Hemocoraxius' Endemic", -- Level 102
            "Elkikatar's Endemic",   -- Level 107
            "Neemzaq's Endemic",     -- Level 112
            "Vampyric Endemic",      -- Level 117
            "Fevered Endemic",       -- Level 122
        },
        ['BloodDot'] = {
            "Spiter Blood",        -- Level 127
            "Tainted Breath",      -- Level 19
            "Envenomed Breath",    -- Level 35
            "Venom of the Snake",  -- Level 52
            "Scorpion Venom",      -- Level 61
            "Turepta Blood",       -- Level 65
            "Chimera Blood",       -- Level 66
            "Diregriffon's Bite",  -- Level 71
            "Falrazim's Gnashing", -- Level 76
            "Ikaav Blood",         -- Level 81
            "Spinechiller Blood",  -- Level 90
            "Binaesa Blood",       -- Level 91
            "Asp Blood",           -- Level 96
            "Glistenwing Blood",   -- Level 101
            "Polybiad Blood",      -- Level 106
            "Ikatiar's Blood",     -- Level 111
            "Akhevan Blood",       -- Level 116
            "Forgebound Blood",    -- Level 121
        },
        ['ColdDot'] = {
            "Shar`Drahn's Chill", -- Level 130
            "Edoth's Chill",      -- Level 99
            "Kirchen's Chill",    -- Level 104
            "Ekron's Chill",      -- Level 109
            "Endaroky's Chill",   -- Level 114
            "Sylra Fris' Chill",  -- Level 119
            "Lazam's Chill",      -- Level 124

        },
        ['SlowSpell'] = {
            -- Slow Spell
            "Drowsy",          -- Level 20
            "Sha's Lethargy",  -- Level 50
            "Sha's Advantage", -- Level 60
            "Sha's Revenge",   -- Level 65
            "Sha's Legacy",    -- Level 70
            "Sha's Reprisal",  -- Level 87
        },
        ['DichoSpell'] = {
            -- Dicho Spell
            "Dichotomic Fury", -- Level 101
            "Dissident Fury",  -- Level 106
            "Composite Fury",  -- Level 111
            "Ecliptic Fury",   -- Level 116
            "Reciprocal Fury", -- Level 121
        },
        ['HealSpell'] = {
            "Lydora's Mending",    -- Level 127
            "Salve",               -- Level 1
            "Minor Healing",       -- Level 6
            "Light Healing",       -- Level 18
            "Healing",             -- Level 28
            "Greater Healing",     -- Level 38
            "Spirit Salve",        -- Level 48
            "Chloroblast",         -- Level 59
            "Trushar's Mending",   -- Level 65
            "Muada's Mending",     -- Level 67
            "Minohten Mending",    -- Level 72
            "Daria's Mending",     -- Level 77
            "Cadmael's Mending",   -- Level 82
            "Jorra's Mending",     -- Level 87
            "Mending of the Izon", -- Level 92
            "Jaerol's Mending",    -- Level 97
            "Sabhattin's Mending", -- Level 102
            "Deltro's Mending",    -- Level 107
            "Bethun's Mending",    -- Level 112
            "Korah's Mending",     -- Level 117
            "Thornhost's Mending", -- Level 122
        },
        ['PetHealSpell'] = {
            "Salve of Lydora",         -- Level 126
            "Sharik's Replenishing",   -- Level 9
            "Keshuval's Rejuvenation", -- Level 15
            "Herikol's Soothing",      -- Level 27
            "Yekan's Recovery",        -- Level 36
            "Vigor of Zehkes",         -- Level 49
            "Aid of Khurenz",          -- Level 52
            "Sha's Restoration",       -- Level 55
            "Healing of Sorsha",       -- Level 61
            "Healing of Mikkily",      -- Level 66
            "Healing of Uluanes",      -- Level 71
            "Salve of Feldan",         -- Level 76
            "Salve of Reshan",         -- Level 81
            "Salve of Sevna",          -- Level 86
            "Salve of Yubai",          -- Level 91
            "Salve of Blezon",         -- Level 96
            "Salve of Clorith",        -- Level 101
            "Salve of Artikla",        -- Level 106
            "Salve of Tobart",         -- Level 111
            "Salve of Jaegir",         -- Level 116
            "Salve of Homer",          -- Level 121
        },
        ['PetSpell'] = {
            "Spirit of Orvain",     -- Level 128
            "Spirit of Sharik",     -- Level 8
            "Spirit of Khaliz",     -- Level 15
            "Spirit of Keshuval",   -- Level 21
            "Spirit of Herikol",    -- Level 30
            "Spirit of Yekan",      -- Level 39
            "Spirit of Kashek",     -- Level 46
            "Spirit of Omakin",     -- Level 54
            "Spirit of Zehkes",     -- Level 56
            "Spirit of Khurenz",    -- Level 58
            "Spirit of Khati Sha",  -- Level 60
            "Spirit of Arag",       -- Level 62
            "Spirit of Sorsha",     -- Level 64
            "Spirit of Alladnu",    -- Level 68
            "Spirit of Rashara",    -- Level 70
            "Spirit of Uluanes",    -- Level 73
            "Spirit of Silverwing", -- Level 78
            "Spirit of Hoshkar",    -- Level 83
            "Spirit of Averc",      -- Level 88
            "Spirit of Kolos",      -- Level 93
            "Spirit of Lachemit",   -- Level 98
            "Spirit of Avalit",     -- Level 103
            "Spirit of Akalit",     -- Level 108
            "Spirit of Blizzent",   -- Level 113
            "Spirit of Panthea",    -- Level 118
            "Spirit of Shae",       -- Level 123
        },
        ['PetGroupEndRegenProc'] = {
            --Pet Group End Regen Proc*
            "Fatiguing Bite VI", -- Level 128
            "Fatiguing Bite",
            "Exhausting Bite",
            "Depleting Bite",
            "Wearying Bite",
            "Sapping Bite",
        },
        ['PetSpellGuard'] = {
            "Spellbreaker's Guard XI", -- Level 130
            "Spellbreaker's Guard",
            "Spellbreaker's Bulwark",
            "Spellbreaker's Aegis",
            "Spellbreaker's Rampart",
            "Spellbreaker's Armor",
            "Spellbreaker's Ward",
            "Spellbreaker's Palisade",
            "Spellbreaker's Keep",
            "Spellbreaker's Citadel",
            "Spellbreaker's Fortress",
            "Spellbreaker's Synergy",
        },
        ['PetSlowProc'] = {
            --Pet Slow Proc*
            "Steeltrap Jaws",
            "Lockfang Jaws",
            "Fellgrip Jaws",
            "Deadlock Jaws",
        },
        ['PetOffenseBuff'] = {
            "Pack Leader's Aggression", -- Level 126
            "Neivr's Aggression",
            "Mea's Aggression",
            "Plakt's Aggression",
            "Sekmoset's Aggression",
            "Virzak's Aggression",
            "Horasug's Aggression",
            "Panthea's Aggression",
            "Magna's Aggression",
        },
        ['PetDefenseBuff'] = {
            "Pack Leader's Protection", -- Level 126
            "Neivr's Protection",
            "Mea's Protection",
            "Plakt's Protection",
            "Sekmoset's Protection",
            "Virzak's Protection",
            "Horasug's Protection",
            "Panthea's Protection",
            "Magna's Protection",
        },
        ['PetHaste'] = {
            --Pet Haste*
            "Warder's Unity VI", -- Level 129, combines haste and damage proc
            "Yekan's Quickening",
            "Bond of The Wild",
            "Omakin's Alacrity",
            "Sha's Ferocity",
            "Arag's Celerity",
            "Growl of the Beast",
            "Unparalleled Voracity",
            "Peerless Penchant",
            "Unrivaled Rapidity",
            "Incomparable Velocity",
            "Exceptional Velocity",
            "Extraordinary Velocity",
            "Tremendous Velocity",
            "Astounding Velocity",
            "Unsurpassed Velocity",
            "Insatiable Voracity",
        },
        ['PetGrowl'] = {
            "Growl of the Panther XIV", -- Level 129
            "Growl of the Panther",
            "Growl of the Puma",
            "Growl of the Jaguar",
            "Growl of the Tiger",
            "Growl of the Lion",
            "Growl of the Snow Leopard",
            "Growl of the Leopard",
            "Growl of the Sabretooth",
            "Growl of the Lioness",
            "Growl of the Clouded Leopard",
        },
        ['PetHealProc'] = {
            --Pet Heal proc buff*
            "Protective Warder",
            "Sympathetic Warder",
            "Convivial Warder",
            "Mending Warder",
            "Invigorating Warder",
            "Empowering Warder",
            "Bolstering Warder",
            "Friendly Pet",
        },
        ['PetDamageProc'] = {
            "Spirit of Irdrath", -- Level 129
            "Spirit of Shoru",
            "Spirit of Lightning",
            "Spirit of the Blizzard",
            "Spirit of Inferno",
            "Spirit of the Scorpion",
            "Spirit of Vermin",
            "Spirit of Wind",
            "Spirit of the Storm",
            "Spirit of Snow",
            "Spirit of Flame",
            "Spirit of Rellic",
            "Spirit of Irionu",
            "Spirit of Oroshar",
            "Spirit of Lairn",
            "Spirit of Jeswin",
            "Spirit of Vaxztn",
            "Spirit of Kron",
            "Spirit of Bale",
            "Spirit of Nak",
            "Spirit of Visoracius",
            "Spirit of Beramos",
            "Spirit of Mandrikai",
            "Spirit of Siver",
            "Ally's Unity",
            "Comrade's Unity",
        },
        ['UnityBuff'] = {
            -- --Combined ManaRegenBuff and AtkHPBuff
            "Feralist's Unity VII", -- Level 130
            "Spiritual Unity",
            "Stormblood's Unity",
            "Feralist's Unity",
            "Reclaimer's Unity",
            "Chieftain's Unity",
            "Wildfang's Unity",
        },
        ['KillShotBuff'] = {
            --Pet Dmg Absorb + HoT buff*
            "Natural Collaboration",
            "Natural Cooperation",
            "Natural Affiliation",
            "Natural Cooperation",
            "Natural Alliance",
            "Symbiotic Alliance",
            "Warder's Alliance",
        },
        ['RunSpeedBuff'] = {
            "Spirit of wolf",
            -- Spirit of the Shrew Is Only 30% Speed Flat So Removed it from the List as its too slow
            --   [] = "Spirit of the Shrew"],
            --   [] = "Pack Shrew"].
            "Spirit of Tala'Tak",
        },
        ['ManaRegenBuff'] = {
            "Spiritual Enlightenment XVII", -- Level 128
            "Spiritual Light",
            "Spiritual Radiance",
            "Spiritual Purity",
            "Spiritual Dominion",
            "Spiritual Ascendance",
            "Spiritual Enlightenment",
            "Spiritual Epiphany",
            "Spiritual Edification",
            "Spiritual Enhancement",
            "Spiritual Enrichment",
            "Spiritual Evolution",
            "Spiritual Elaboration",
            "Spiritual Empowerment",
            "Spiritual Enhancement",
            "Spiritual Insight",
            "Spiritual Erudition",
            "Spiritual Enduement",
        },
        ['AllianceDot'] = {
            -- Alliance Spell for Beastlords 100+
            "Venomous Alliance",    -- Level 101
            "Venomous Covenant",    -- Level 108
            "Venomous Coalition",   -- Level 113
            "Venomous Conjunction", -- Level 118
            "Venomous Covariance",  -- Level 123
        },
        ['PetBlockSpell'] = {
            "Ward of Calliav",       -- Level 49
            "Guard of Calliav",      -- Level 58
            "Protection of Calliav", -- Level 64
            "Feral Guard",           -- Level 69
            "Mammoth-Hide Guard",    -- Level 71
            "Dragonscale Guard",     -- Level 76
            "Bulwark of Tri'Qaras",  -- Level 77
            "Spectral Rampart",      -- Level 88
            "Beastwood Rampart",     -- Level 93
            "Aegis of Nefori",       -- Level 99
            "Aegis of Japac",        -- Level 104
            "Aegis of Zeklor",       -- Level 109
            "Aegis of Orfur",        -- Level 114
            "Aegis of Rumblecrush",  -- Level 119
            "Aegis of Valorforged",  -- Level 124
        },
        ['PetBlockAuspice'] = {

            -- Pet Block Auspice - Timer 16
            "Auspice of Shadows",    -- Level 96
            "Auspice of Eternity",   -- Level 102
            "Auspice of Esianti",    -- Level 107
            "Auspice of Kildrukaun", -- Level 112
            "Auspice of Valia",      -- Level 117
            "Auspice of Usira",      -- Level 122
        },
        ['PetHotSpell'] = {
            "Lydora's Melioration",  -- Level 127
            "Minax's Mending",       -- Level 82
            "Wilap's Mending",       -- Level 87
            "Yurv's Mending",        -- Level 92
            "Huaene's Melioration",  -- Level 97
            "Tirik's Melioration",   -- Level 102
            "Virzak's Melioration",  -- Level 107
            "Kallis' Melioration",   -- Level 112
            "Cissela's Melioration", -- Level 117
        },
        ['PetPromisedSpell'] = {
            "Promised Mending XII",    -- Level 128
            "Promised Mending",        -- Level 73
            "Promised Recovery",       -- Level 78
            "Promised Rejuvenation",   -- Level 83
            "Promised Wardmending",    -- Level 88
            "Promised Amendment",      -- Level 93
            "Promised Amelioration",   -- Level 98
            "Promised Invigoration",   -- Level 103
            "Promised Alleviation",    -- Level 108
            "Promised Healing",        -- Level 113
            "Promised Relief",         -- Level 118
            "Promised Reconstitution", -- Level 123
        },
        ['AvatarSpell'] = {
            -- Str Stam Dex Buff
            "Infusion of Spirit", -- Level 61
        },
        ['PetCrippleBite'] = {
            "Dire Bite",
        },
        ['FocusSpell'] = {
            "Focus of Aramna", -- Level 126
            "Inner Fire",
            "Talisman of Tnarg",
            "Talisman of Altuna",
            "Talisman of Kragg",
            "Focus of Alladnu",
            -- Group Focus Spells
            "Focus of Amilan",
            "Focus of Zott",
            "Focus of Yemall",
            "Focus of Emiq",
            "Focus of Klar",
            "Focus of Sanera",
            "Focus of Okasi",
            "Focus of Artikla",
            "Focus of Tobart",
            "Focus of Jaegir",
            "Focus of Skull Crusher",
        },
        ['AtkHPBuff'] = {
            "Spiritual Vigor XV", -- Level 127
            "Spiritual Vigor",
            "Spiritual Vitality",
            "Spiritual Vim",
            "Spiritual Vivacity",
            "Spiritual Verve",
            "Spiritual Valor",
            "Spiritual Valiance",
            "Spiritual Vindication",
            "Spiritual Vivification",
            "Spiritual Vibrancy",
            "Spiritual Vehemence",
            "Spiritual Vigor",
            "Spiritual Valiancy",
            --Single Target Atk+HP Buff* - Does Not Stack with Pally brells or Ranger Buff - is Middle ground Buff has HP & Atk
            "Spiritual Brawn",
            "Spiritual Strength",
        },
        ['AtkBuff'] = {
            -- - Single Ferocity
            "Savagery",                  -- Level 60
            "Ferocity",                  -- Level 65
            "Ferocity of Irionu",        -- Level 70
            "Ruthless Ferocity",         -- Level 75
            "Vicious Ferocity",          -- Level 80
            "Savage Ferocity",           -- Level 85
            "Callous Ferocity",          -- Level 90
            "Brutal Ferocity",           -- Level 92
            -- Group Ferocity
            "Shared Brutal Ferocity",    -- Level 95
            "Shared Merciless Ferocity", -- Level 100
        },
        ['EndRegenDisc'] = {
            "Hiatus V", -- Level 126
            "Respite",
            "Reprieve",
            "Rest",
            "Breather",
            "Hiatus",
            "Relax",
            "Night's Calming",
            "Convalesce",
        },
        ['Maul'] = {
            -- Maul Disc - This is Used with Beastlord Synergy Buffs
            "Harrow XII", -- Level 129
            "Rake",
            "Harrow",
            "Foray",
            "Rush",
            "Barrage",
            "Pummel",
            "Maul",
            "Mangle",
            "Batter",
            "Clobber",
            "Wallop",
        },
        ['SingleClaws'] = {
            --Single target claws*
            "Focused Clamor of Claws",
        },
        ['BestialBuffDisc'] = {
            "Bestial Vivisection VI", -- Level 126
            "Bestial Vivisection",
            "Bestial Rending",
            "Bestial Evulsing",
            "Bestial Savagery",
            "Bestial Fierceness",
        },
        ['AEClaws'] = {
            "Flurry of Claws IX", -- Level 127
            "Flurry of Claws",
            "Tumult of Claws",
            "Clamor of Claws",
            "Tempest of Claws",
            "Storm of Claws",
            "Maelstrom of Claws",
            "Eruption of Claws",
            "Barrage of Claws",
        },
        ['FuryDisc'] = {
            --HHE Burn Disc* - Dicho/Dissident Replace this @ 101 outside of burns
            "Nature's Fury",
            "Kolos' Fury",
            "Ruaabri's Fury",
        },
        ['DmgModDisc'] = {
            --All Skills Damage Modifier*
            "Bestial Fury Discipline",
            "Empathic Fury",
            "Savage Fury",
            "Savage Rage",
            "Savage Rancor",
        },
        ['EndRegenProcDisc'] = {
            "Reflexive Rending",
            "Reflexive Sundering",
            "Reflexive Riving",
            "Reflexive Slashing", -- Level 124
        },
        ['VinDisc'] = {
            -- Vindication Disc
            "Al`ele's Vindication",
            "Venon's Vindication",
            "Ikatiar's Vindication",
            "Kejaan's Vindication",
            "Ikatiar's Vindication",
            "Xanathan's Vindication", -- Level 125
        },
    },
    ['HealRotationOrder'] = {
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoHeals') end,
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        { --Summon pet even when buffs are off on emu
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and Casting.AmIBuffable()
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
            name = 'PetHealing',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, target) return (mq.TLO.Me.Pet.PctHPs() or 100) < Config:GetSetting('PetHealPct') end,
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
            name = 'FocusedParagon',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoParagon') and Casting.CanUseAA("Focused Paragon of Spirits") end,
            targetId = function(self) return { Combat.FindWorstHurtMana(Config:GetSetting('FParaPct')), } end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Config:GetSetting('DowntimeFP') and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and not Casting.IHaveBuff(mq.TLO.Me.AltAbility('Paragon of Spirit').Spell)
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
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
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
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
    },
    ['HelperFunctions']   = {
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
        --function to make sure we don't have non-hostiles in range before we use AE damage or non-taunt AE hate abilities

    },
    ['Rotations']         = {
        ['Burn'] = {
            {
                name = "Group Bestial Alignment",
                type = "AA",
                cond = function(self, aaName)
                    return not self.ClassConfig.HelperFunctions.DmgModActive(self)
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
                    return not self.ClassConfig.HelperFunctions.FlurryActive(self)
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
                load_cond = function(self) return Core.GetResolvedActionMapItem('DichoSpell') end,
                cond = function(self, aaName)
                    local dichoSpell = Core.GetResolvedActionMapItem('DichoSpell')
                    return not self.ClassConfig.HelperFunctions.FlurryActive(self) and (mq.TLO.Me.GemTimer(dichoSpell.RankName())() or -1) > 15
                end,
            },
            {
                name = "DmgModDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not self.ClassConfig.HelperFunctions.DmgModActive(self)
                end,
            },
            {
                name = "Ferociousness",
                type = "AA",
                cond = function(self, aaName, target)
                    return not self.ClassConfig.HelperFunctions.DmgModActive(self)
                end,
            },
            {
                name = "Bestial Alignment",
                type = "AA",
                cond = function(self, aaName)
                    return not self.ClassConfig.HelperFunctions.DmgModActive(self)
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName)
                    return not self.ClassConfig.HelperFunctions.DmgModActive(self)
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
                    return (mq.TLO.Me.PctHPs() <= 40 and Targeting.IHaveAggro(100)) or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99) and not Core.IAmMA()
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
                    return (mq.TLO.Me.Pet.PctHPs() and mq.TLO.Me.Pet.PctHPs() > 50)
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
        ['PetHealAA'] = {
            {
                name = "Mend Companion",
                type = "AA",
            },
        },
        ['PetHealSpell'] = {
            {
                name = "PetHealSpell",
                type = "Spell",
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
                    return not self.ClassConfig.HelperFunctions.FlurryActive(self)
                end,
            },
            {
                name = "Feralgia",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoFeralgia') end,
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
                    if not Config:GetSetting('DoDot') then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "ColdDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoDot') then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "EndemicDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoDot') then return false end
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
                    --We will let Feralgia apply swarm pets if our pet currently doesn't have its Growl Effect.
                    local feralgia = self.ResolvedActionMap['Feralgia']
                    return (feralgia and feralgia() and mq.TLO.Me.PetBuff(mq.TLO.Spell(feralgia).RankName.Trigger(2).ID())) and Casting.HaveManaToNuke()
                end,
            },
        },
        ['Weaves'] = {
            {
                name = "Summon Companion",
                type = "AA",
                cond = function(self, aaName, target)
                    if mq.TLO.Me.Pet.ID() == 0 then return false end
                    local pet = mq.TLO.Me.Pet
                    return not pet.Combat() and (pet.Distance3D() or 0) > 200
                end,
            },
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
            {
                name = "Nature's Salve",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.TotalCounters() > 0
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
                    return Casting.PetBuffCheck(spell)
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
                load_cond = function(self) return not Config:GetSetting('DoFeralgia') end,
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
    ['Spells']            = {
        {
            gem = 1,
            spells = {
                { name = "HealSpell",    cond = function(self) return Config:GetSetting('DoHeals') end, },
                { name = "PetHealSpell", cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "Icelance1", },

            },
        },
        {
            gem = 2,
            spells = {
                { name = "PetHealSpell", cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "Icelance1", },
                { name = "AERoar",       cond = function(self) return Config:GetSetting('DoAERoar') end, },
                { name = "Icelance2", },
            },
        },
        {
            gem = 3,
            spells = {
                { name = "Icelance1", },
                { name = "AERoar",    cond = function(self) return Config:GetSetting('DoAERoar') end, },
                { name = "Icelance2", },
                { name = "BloodDot", },
            },
        },
        {
            gem = 4,
            spells = {
                { name = "AERoar",    cond = function(self) return Config:GetSetting('DoAERoar') end, },
                { name = "Icelance2", },
                { name = "BloodDot", },
                { name = "ColdDot",   cond = function(self) return Config:GetSetting('DoDot') end, },
            },
        },
        {
            gem = 5,
            spells = {
                { name = "BloodDot", },
                { name = "ColdDot",    cond = function(self) return Config:GetSetting('DoDot') end, },
                { name = "EndemicDot", cond = function(self) return Config:GetSetting('DoDot') end, },
            },
        },
        {
            gem = 6,
            spells = {
                { name = "AtkBuff", },
                { name = "RunSpeedBuff", },
            },
        },
        {
            gem = 7,
            spells = {
                { name = "SlowSpell",  cond = function(self) return Config:GetSetting('DoSlow') and not Casting.CanUseAA("Sha's Reprisal") end, },
                { name = "DichoSpell", },
                { name = "EndemicDot", cond = function(self) return Config:GetSetting('DoDot') end, },
            },
        },
        {
            gem = 8,
            spells = {
                { name = "Feralgia",   cond = function(self) return Config:GetSetting('DoFeralgia') end, },
                { name = "PetGrowl", },
                { name = "EndemicDot", cond = function(self) return Config:GetSetting('DoDot') end, },
            },
        },
        {
            gem = 9,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "PoiBite", },
            },
        },
        {
            gem = 10,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Maelstrom", },
            },
        },
        {
            gem = 11,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "FrozenPoi", },
            },
        },
        {
            gem = 12,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "ColdDot",     cond = function(self) return Config:GetSetting('DoDot') end, },
                { name = "PetHealProc", },

            },
        },
        {
            gem = 13,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "PetHealProc", },
                { name = "EndemicDot",  cond = function(self) return Config:GetSetting('DoDot') end, },
                { name = "SwarmPet",    cond = function(self) return Config:GetSetting('DoSwarmPet') end, },
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
                return mq.TLO.Me.AltAbility("Sha's Reprisal")
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
        ['DoHeals']        = {
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
            Tooltip = "Mem and cast your Pet Heal (Salve) spell. AA Pet Heals are always used in emergencies.",
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
        ['DoDot']          = {
            DisplayName = "Cast DOTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Enable casting Damage Over Time spells.",
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
