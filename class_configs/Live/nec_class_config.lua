-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

-- [ NOTE ON ORDERING ] --
-- Order matters! Lua will implicitly iterate everything in an array
-- in order by default so always put the first thing you want checked
-- towards the top of the list.

local mq           = require('mq')
local Casting      = require("utils.casting")
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version            = "1.1 - Live",
    _author             = "Derple, Grimmier, Algar",
    ['Modes']           = {
        'DPS',
    },
    ['ModeChecks']      = {
        IsCuring = function() return Config:GetSetting('DoCures') end,
        -- necro can AA Rez
        IsRezing = function() return Casting.CanUseAA("Convergence") and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
        CanCharm = function() return true end,
    },
    ['Rez']             = {
        ['Combat'] = {
            {
                type = "AA",
                name = "Convergence",
                cond = function(self, spell, target)
                    return Casting.ReagentCheck(mq.TLO.Me.AltAbility("Convergence").Spell)
                end,
            },
        },
        ['Downtime'] = {
            {
                type = "AA",
                name = "Convergence",
                cond = function(self, spell, target)
                    return Casting.ReagentCheck(mq.TLO.Me.AltAbility("Convergence").Spell)
                end,
            },
        },
    },
    ['Cure']            = {
        ['DetDispel'] = {
            { type = "AA", name = "Embrace The Decay", selfOnly = true, },
        },
    },
    ['PetPosition']     = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function()
            local cdAA = mq.TLO.Me.AltAbility("Companion's Discipline")
            return (cdAA and cdAA.Rank() or 0) >= 7 and "Companion's Discipline"
        end,
    },
    ['Themes']          = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.5, g = 0.05, b = 1.0, a = .8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.4, g = 0.05, b = 0.8, a = .8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.2, g = 0.05, b = 0.6, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.1, g = 0.05, b = 0.5, a = .1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.5, g = 0.05, b = 1.0, a = .8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.5, g = 0.05, b = 1.0, a = .9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
        },
    },
    ['CommandHandlers'] = {
        startlich = {
            usage = "/rgl startlich",
            about = "Start your Lich Spell [Note: This will enabled DoLich if it is not already].",
            handler =
                function(self)
                    Config:SetSetting('DoLich', true)
                    Core.SafeCallFunc("Start Necro Lich", self.Helpers.StartLich, self)

                    return true
                end,
        },
        stoplich = {
            usage = "/rgl stoplich",
            about = "Stop your Lich Spell [Note: This will NOT disable DoLich].",
            handler =
                function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.Helpers.CancelLich, self)

                    return true
                end,
        },
    },
    ['ItemSets']        = {
        ['Epic'] = {
            "Deathwhisper",
            "Soulwhisper",
        },
        ['OoW_Chest'] = {
            "Blightbringer's Tunic of the Grave",
            "Deathcaller's Robe",
        },
    },
    ['AbilitySets']     = {
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
            "Shield of Maelin",        -- Level 64
            "Shield of the Arcane",    -- Level 61
            "Shield of the Magi",      -- Level 54
            "Arch Shielding",          -- Level 41
            "Greater Shielding",       -- Level 33
            "Major Shielding",         -- Level 24
            "Shielding",               -- Level 16
            "Lesser Shielding",        -- Level 8
            "Minor Shielding",         -- Level 1
        },
        ['Levitate'] = {
            "Dead Men Floating", -- Level 45
        },
        ['SelfRune1'] = {
            "Wraithskin XIII", -- Level 128
            "Golemskin",       -- Level 123
            "Carrion Skin",    -- Level 118
            "Frozen Skin",     -- Level 113
            "Ashen Skin",      -- Level 108
            "Deadskin",        -- Level 103
            "Zombieskin",      -- Level 98
            "Ghoulskin",       -- Level 93
            "Grimskin",        -- Level 88
            "Corpseskin",      -- Level 83
            "Shadowskin",      -- Level 78
            "Wraithskin",      -- Level 73
            "Dull Pain",       -- Level 69
            "Force Shield",    -- Level 63
            "Manaskin",        -- Level 52
            "Diamondskin",     -- Level 43
            "Steelskin",       -- Level 32
            "Leatherskin",     -- Level 22
            "Shieldskin",      -- Level 14
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
        ['FDSpell'] = {
            -- Fd Spell
            "Death Peace", -- Level 60
        },
        ['CharmSpell'] = {
            -- Charm Spells >= 20
            "Enslave Death",   -- Level 60
            "Thrall of Bones", -- Level 54
            "Cajole Undead",   -- Level 47
            "Beguile Undead",  -- Level 31
            "Dominate Undead", -- Level 18
        },
        ---DPS
        ['AllianceSpell'] = {
            -- Alliance Spells
            "Malevolent Covariance",  -- Level 122
            "Malevolent Conjunction", -- Level 117
            "Malevolent Coalition",   -- Level 114
            "Malevolent Covenant",    -- Level 107
            "Malevolent Alliance",    -- Level 102
        },
        ['DichoDot'] = {
            ---DichoSpell >= LVL101
            "Reciprocal Paroxysm", -- Level 121
            "Ecliptic Paroxysm",   -- Level 116
            "Composite Paroxysm",  -- Level 111
            "Dissident Paroxysm",  -- Level 106
            "Dichotomic Paroxysm", -- Level 101
        },
        ['SwarmPet'] = {
            ---SwarmPet >= LVL85
            "Call Raging Skeleton X",    -- Level 130
            "Call Ravening Skeleton",    -- Level 125
            "Call Roiling Skeleton",     -- Level 120
            "Call Riotous Skeleton",     -- Level 115
            "Call Reckless Skeleton",    -- Level 110
            "Call Remorseless Skeleton", -- Level 105
            "Call Relentless Skeleton",  -- Level 100
            "Call Ruthless Skeleton",    -- Level 95
            "Call Ruinous Skeleton",     -- Level 90
            "Call Rumbling Skeleton",    -- Level 85
        },
        ['Lifetap'] = {
            ---HealthTaps >= LVL1
            "Soulrip VII",         -- Level 128
            "Drain Essence XXIII", -- Level 126
            "Soullash",            -- Level 123
            "Extort Essence",      -- Level 121
            "Soulflay",            -- Level 118
            "Maraud Essence",      -- Level 116
            "Soulgouge",           -- Level 113
            "Draw Essence",        -- Level 111
            "Soulsiphon",          -- Level 108
            "Consume Essence",     -- Level 106
            "Soulrend",            -- Level 103
            "Hemorrhage Essence",  -- Level 101
            "Plunder Essence",     -- Level 96
            "Bleed Essence",       -- Level 91
            "Divert Essence",      -- Level 86
            "Drain Essence",       -- Level 81
            "Siphon Essence",      -- Level 76
            "Drain Life",          -- Level 71
            -- "Ancient: Touch of Orshilak", -- Level 70
            "Soulspike",           -- Level 67
            "Touch of Mujaki",     -- Level 61
            "Touch of Night",      -- Level 59
            "Deflux",              -- Level 54
            "Drain Soul",          -- Level 48
            "Drain Spirit",        -- Level 39
            "Spirit Tap",          -- Level 26
            "Siphon Life",         -- Level 20
            "Lifedraw",            -- Level 12
            "Lifespike",           -- Level 3
            "Lifetap",             -- Level 1
        },
        ['DurationTap'] = {
            ---DurationTap >= LVL9
            "Sharosh's Grasp",       -- Level 127
            "Helmsbane's Grasp",     -- Level 122
            "The Protector's Grasp", -- Level 117
            "Tserrina's Grasp",      -- Level 112
            "Bomoda's Grasp",        -- Level 107
            "Plexipharia's Grasp",   -- Level 102
            "Halstor's Grasp",       -- Level 97
            "Ivrikdal's Grasp",      -- Level 92
            "Arachne's Grasp",       -- Level 87
            "Fellid's Grasp",        -- Level 82
            "Visziaj's Grasp",       -- Level 77
            "Dyn`leth's Grasp",      -- Level 72
            "Fang of Death",         -- Level 68
            "Night's Beckon",        -- Level 65
            "Saryrn's Kiss",         -- Level 62
            "Vexing Mordinia",       -- Level 57
            "Bond of Death",         -- Level 49
            "Auspice",               -- Level 45
            "Vampiric Curse",        -- Level 29
            "Leech",                 -- Level 9
        },
        ['GroupLeech'] = {
            ---GroupLeech >= LVL60
            "Dark Leech VIII",          -- Level 126
            "Ghastly Leech",            -- Level 121
            "Twilight Leech",           -- Level 120
            "Frozen Leech",             -- Level 115
            "Ashen Leech",              -- Level 110
            "Dark Leech",               -- Level 100
            "Night Stalker",            -- Level 65
            "Zevfeer's Theft of Vitae", -- Level 60
        },
        ['ManaDrain'] = {
            --Mana Drain with Group Mana Recourse
            "Mind Wrack XIV",     -- Level 129
            "Mind Disintegrate",  -- Level 124
            "Mind Atrophy",       -- Level 119
            "Mind Erosion",       -- Level 114
            "Mind Excoriation",   -- Level 109
            "Mind Extraction",    -- Level 104
            "Mind Strip",         -- Level 99
            "Mind Abrasion",      -- Level 94
            "Thought Flay",       -- Level 89
            "Mind Decomposition", -- Level 84
            "Mental Vivisection", -- Level 79
            "Mind Dissection",    -- Level 74
            "Mind Flay",          -- Level 70
            "Mind Wrack",         -- Level 58
        },
        ['PoisonNuke1'] = {
            ---PoisonNuke >=LVL21
            "Schisming Venin",      -- Level 126
            "Necrotizing Venin",    -- Level 121
            "Embalming Venin",      -- Level 116
            "Searing Venin",        -- Level 111
            "Effluvial Venin",      -- Level 106
            "Liquefying Venin",     -- Level 101
            "Dissolving Venin",     -- Level 96
            "Blighted Venin",       -- Level 86
            "Withering Venin",      -- Level 81
            "Ruinous Venin",        -- Level 76
            "Venin",                -- Level 71
            "Acikin",               -- Level 66
            "Neurotoxin",           -- Level 61
            "Torbas' Venom Blast",  -- Level 54
            "Torbas' Poison Blast", -- Level 49
            "Torbas' Acid Blast",   -- Level 32
            "Shock of Poison",      -- Level 21
        },
        ['PoisonNuke2'] = {
            ---PoisonNuke2  >=LVL 75 (DD Increase chance)
            "Call for Blood XIII",    -- Level 130
            "Decree for Blood",       -- Level 125
            "Proclamation for Blood", -- Level 120
            "Assert for Blood",       -- Level 115
            "Refute for Blood",       -- Level 110
            "Impose for Blood",       -- Level 105
            "Impel for Blood",        -- Level 100
            -- "Provocation for Blood", -- Level 95
            "Compel for Blood",       -- Level 90
            "Exigency for Blood",     -- Level 85
            "Supplication of Blood",  -- Level 80
            "Demand for Blood",       -- Level 75
            "Call for Blood",         -- Level 68
        },
        ['FireNuke'] = {
            ---Fire Nuke, undead conversion and short stun, 90+
            "Ignite Bones XIII", -- Level 130
            "Immolate Bones",    -- Level 125
            "Cremate Bones",     -- Level 120
            "Char Bones",        -- Level 115
            "Burn Bones",        -- Level 110
            "Combust Bones",     -- Level 105
            "Scintillate Bones", -- Level 100
            "Coruscate Bones",   -- Level 95
            "Scorch Bones",      -- Level 90
        },
        ['SearingDot'] = {
            ---FireDot1 >= LVL80
            "Searing Shadow XI",  -- Level 130
            "Raging Shadow",      -- Level 125
            "Scalding Shadow",    -- Level 120
            "Broiling Shadow",    -- Level 115
            "Burning Shadow",     -- Level 110
            "Smouldering Shadow", -- Level 105
            "Coruscating Shadow", -- Level 100
            "Blazing Shadow",     -- Level 95
            "Blistering Shadow",  -- Level 90
            "Scorching Shadow",   -- Level 85
            "Searing Shadow",     -- Level 80
        },
        ['DreadDot'] = {
            ---FireDot2 >= LVL10
            "Dread Pyre XIII",         -- Level 129
            "Pyre of Illandrin",       -- Level 124
            "Pyre of Va Xakra",        -- Level 119
            "Pyre of Klraggek",        -- Level 114
            "Pyre of the Shadewarden", -- Level 109
            "Pyre of Jorobb",          -- Level 104
            "Pyre of Marnek",          -- Level 99
            "Pyre of Hazarak",         -- Level 94
            "Pyre of Nos",             -- Level 89
            "Soul Reaper's Pyre",      -- Level 84
            "Reaver's Pyre",           -- Level 79
            "Ashengate Pyre",          -- Level 74
            "Dread Pyre",              -- Level 70
            "Night Fire",              -- Level 65
            "Funeral Pyre of Kelador", -- Level 60
            "Pyrocruor",               -- Level 58
            "Ignite Blood",            -- Level 47
            "Boil Blood",              -- Level 28
            "Heat Blood",              -- Level 10
        },
        ['DreadDot2'] = {
            ---FireDot2 >= LVL10
            "Dread Pyre XIII",         -- Level 129
            "Pyre of Illandrin",       -- Level 124
            "Pyre of Va Xakra",        -- Level 119
            "Pyre of Klraggek",        -- Level 114
            "Pyre of the Shadewarden", -- Level 109
            "Pyre of Jorobb",          -- Level 104
            "Pyre of Marnek",          -- Level 99
            "Pyre of Hazarak",         -- Level 94
            "Pyre of Nos",             -- Level 89
            "Soul Reaper's Pyre",      -- Level 84
            "Reaver's Pyre",           -- Level 79
            "Ashengate Pyre",          -- Level 74
            "Dread Pyre",              -- Level 70
            "Night Fire",              -- Level 65
            "Funeral Pyre of Kelador", -- Level 60
            "Pyrocruor",               -- Level 58
            "Ignite Blood",            -- Level 47
            "Boil Blood",              -- Level 28
            "Heat Blood",              -- Level 10
        },
        ['FlashDot'] = {
            ---FireDot3 >= LVL88 (QuickDOT)
            "Marith's Flashblaze",         -- Level 128
            "Arcanaforged's Flashblaze",   -- Level 123
            "Thall Va Kelun's Flashblaze", -- Level 118
            "Otatomik's Flashblaze",       -- Level 113
            "Azeron's Flashblaze",         -- Level 108
            "Mazub's Flashblaze",          -- Level 103
            "Osalur's Flashblaze",         -- Level 98
            "Brimtav's Flashblaze",        -- Level 93
            "Tenak's Flashblaze",          -- Level 88
        },
        ['MoriDot'] = {
            ---FireDot4 >= LVL73 DOT
            "Pyre of Mori XIX",      -- Level 128
            "Pyre of the Abandoned", -- Level 123
            "Pyre of the Neglected", -- Level 118
            "Pyre of the Wretched",  -- Level 113
            "Pyre of the Fereth",    -- Level 108
            "Pyre of the Lost",      -- Level 103
            "Pyre of the Forsaken",  -- Level 98
            "Pyre of the Piq'a",     -- Level 93
            "Pyre of the Bereft",    -- Level 88
            "Pyre of the Forgotten", -- Level 83
            "Pyre of the Lifeless",  -- Level 78
            "Pyre of the Fallen",    -- Level 73
        },
        ['WoundDot'] = {
            ---Magic1 >= LVL51 SlowDot
            "Necrotizing Wounds VIII", -- Level 130
            "Putrefying Wounds",       -- Level 125
            "Infected Wounds",         -- Level 120
            "Septic Wounds",           -- Level 115
            "Cytotoxic Wounds",        -- Level 110
            "Mortiferous Wounds",      -- Level 105
            "Pernicious Wounds",       -- Level 100
            "Necrotizing Wounds",      -- Level 95
            "Splirt",                  -- Level 90
            "Splart",                  -- Level 85
            "Splort",                  -- Level 80
            "Splurt",                  -- Level 51
        },
        ['HorrorDot'] = {
            ---Magic2 >=LVL67 DOT
            "Horror XV",              -- Level 127
            "Extermination",          -- Level 122
            "Extinction",             -- Level 117
            "Oblivion",               -- Level 112
            "Inevitable End",         -- Level 107
            "Annihilation",           -- Level 102
            "Termination",            -- Level 97
            "Doom",                   -- Level 92
            "Demise",                 -- Level 87
            "Mortal Coil",            -- Level 82
            "Anathema of Life",       -- Level 77
            "Curse of Mortality",     -- Level 72
            "Ancient: Curse of Mori", -- Level 70
            "Dark Nightmare",         -- Level 67
            "Horror",                 -- Level 63
        },
        ['HorrorDot2'] = {
            ---Magic2 >=LVL67 DOT
            "Horror XV",              -- Level 127
            "Extermination",          -- Level 122
            "Extinction",             -- Level 117
            "Oblivion",               -- Level 112
            "Inevitable End",         -- Level 107
            "Annihilation",           -- Level 102
            "Termination",            -- Level 97
            "Doom",                   -- Level 92
            "Demise",                 -- Level 87
            "Mortal Coil",            -- Level 82
            "Anathema of Life",       -- Level 77
            "Curse of Mortality",     -- Level 72
            "Ancient: Curse of Mori", -- Level 70
            "Dark Nightmare",         -- Level 67
            "Horror",                 -- Level 63
        },
        ['DeconDot'] = {
            ---Magic3 >=LVL87 QuickDot
            "Xirrim's Swift Deconstruction",   -- Level 127
            "Blevak's Swift Deconstruction",   -- Level 122
            "Xetheg's Swift Deconstruction",   -- Level 117
            "Lexelan's Swift Deconstruction",  -- Level 112
            "Adalora's Swift Deconstruction",  -- Level 107
            "Marmat's Swift Deconstruction",   -- Level 102
            "Itkari's Swift Deconstruction",   -- Level 97
            "Hral's Swift Deconstruction",     -- Level 92
            "Ninavero's Swift Deconstruction", -- Level 87
        },
        ['ScourgeDot'] = {
            ---Magic4 >=LVL 97 DOT
            "Scourge of Eternity",      -- Level 123, TOB
            "Scourge of Destiny",       -- Level 108
            "Scourge of Fates",         -- Level 97
        },
        ['ComboDot'] = {                ---Combines GripDot and DecayDot
            "Goremand's Grip of Decay", -- Level 125
            "Fleshrot's Grip of Decay", -- Level 120
            "Danvid's Grip of Decay",   -- Level 115
            "Mourgis' Grip of Decay",   -- Level 110
            "Livianus' Grip of Decay",  -- Level 104
        },
        ['DecayDot'] = {
            ---Decay Line of Disease Spells >=LVL56 Slow DOT
            "Pustim's Decay",   -- Level 126
            "Goremand's Decay", -- Level 121
            "Fleshrot's Decay", -- Level 116
            "Danvid's Decay",   -- Level 111
            "Mourgis' Decay",   -- Level 106
            "Livianus' Decay",  -- Level 101
            "Wuran's Decay",    -- Level 96
            "Ulork's Decay",    -- Level 91
            "Folasar's Decay",  -- Level 86
            "Megrima's Decay",  -- Level 81
            "Eranon's Decay",   -- Level 76
            "Severan's Rot",    -- Level 71
            "Chaos Plague",     -- Level 66
            "Dark Plague",      -- Level 61
            "Cessation of Cor", -- Level 56
        },
        ['GripDot'] = {
            ---Grip Line of Disease Spells =LVL1 HAS DEBUFF
            "Grip of Pustim",  -- Level 126
            "Grip of Quietus", -- Level 116
            "Grip of Zorglim", -- Level 111
            "Grip of Kraz",    -- Level 106
            "Grip of Jabaum",  -- Level 101
            "Grip of Zalikor", -- Level 96
            "Grip of Zargo",   -- Level 91
            "Grip of Mori",    -- Level 67
            "Plague",          -- Level 52
            "Asystole",        -- Level 40
            "Scourge",         -- Level 35
            -- "Infectious Cloud", -- Level 15
            "Heart Flutter",   -- Level 13
            "Disease Cloud",   -- Level 1
        },
        ['SwiftDiseaseDot'] = {
            ---Sickness Life of Disease Spells >=LVL89 QuickDOT
            "Wremm's Swift Sickness",        -- Level 129
            "Ogna's Swift Sickness",         -- Level 124
            "Diabo Tatrua's Swift Sickness", -- Level 119
            "Lairsaf's Swift Sickness",      -- Level 114
            "Hoshkar's Swift Sickness",      -- Level 109
            "Ilsaria's Swift Sickness",      -- Level 104
            "Bora's Swift Sickness",         -- Level 99
            "Prox's Swift Sickness",         -- Level 94
            "Rilfed's Swift Sickness",       -- Level 89
        },
        ['SwiftPoisonDot'] = {
            ---Poison1 >= LVL86 (QuickDOT)
            "Lherre's Swift Venom",    -- Level 126
            "Dotal's Swift Venom",     -- Level 121
            "Xenacious' Swift Venom",  -- Level 116
            "Vilefang's Swift Venom",  -- Level 111
            "Nexona's Swift Venom",    -- Level 106
            "Serisaria's Swift Venom", -- Level 101
            "Slaunk's Swift Venom",    -- Level 96
            "Hyboram's Swift Venom",   -- Level 91
            "Burlabis' Swift Venom",   -- Level 86
        },
        ['VenomDot'] = {
            ---Poison2 >=LVL1 (DOT)
            "Silkwhisper Venom",       -- Level 130
            "Luggald Venom",           -- Level 125
            "Hemorrhagic Venom",       -- Level 120
            "Crystal Crawler Venom",   -- Level 115
            "Polybiad Venom",          -- Level 110
            "Glistenwing Venom",       -- Level 105
            "Binaesa Venom",           -- Level 100
            "Naeya Venom",             -- Level 95
            "Argendev's Venom",        -- Level 90
            "Slitheren Venom",         -- Level 85
            "Venonscale Venom",        -- Level 80
            "Vakk`dra's Sickly Mists", -- Level 74
            "Blood of Thule",          -- Level 65
            "Envenomed Bolt",          -- Level 50
            "Chilling Embrace",        -- Level 36
            "Venom of the Snake",      -- Level 34
            "Poison Bolt",             -- Level 4
        },
        ['VenomDot2'] = {
            ---Poison2 >=LVL1 (DOT)
            "Silkwhisper Venom",       -- Level 130
            "Luggald Venom",           -- Level 125
            "Hemorrhagic Venom",       -- Level 120
            "Crystal Crawler Venom",   -- Level 115
            "Polybiad Venom",          -- Level 110
            "Glistenwing Venom",       -- Level 105
            "Binaesa Venom",           -- Level 100
            "Naeya Venom",             -- Level 95
            "Argendev's Venom",        -- Level 90
            "Slitheren Venom",         -- Level 85
            "Venonscale Venom",        -- Level 80
            "Vakk`dra's Sickly Mists", -- Level 74
            "Blood of Thule",          -- Level 65
            "Envenomed Bolt",          -- Level 50
            "Chilling Embrace",        -- Level 36
            "Venom of the Snake",      -- Level 34
            "Poison Bolt",             -- Level 4
        },
        ['HazeDot'] = {
            ---Poison3 >= LVL79 DOT
            "Khrosik's Pallid Haze",     -- Level 129
            "Uncia's Pallid Haze",       -- Level 124
            "Zelnithak's Pallid Haze",   -- Level 119
            "Dracnia's Pallid Haze",     -- Level 114
            "Bomoda's Pallid Haze",      -- Level 109
            "Plexipharia's Pallid Haze", -- Level 104
            "Halstor's Pallid Haze",     -- Level 99
            "Ivrikdal's Pallid Haze",    -- Level 94
            "Arachne's Pallid Haze",     -- Level 89
            "Fellid's Pallid Haze",      -- Level 84
            "Visziaj's Pallid Haze",     -- Level 79
            "Chaos Venom",               -- Level 70
        },
        ['PutrefactionDot'] = {
            ---Corruption1 >= LVL77
            "Putrefaction XI", -- Level 127
            "Deterioration",   -- Level 122
            "Decomposition",   -- Level 117
            "Miasma",          -- Level 112
            "Effluvium",       -- Level 107
            "Liquefaction",    -- Level 102
            "Dissolution",     -- Level 97
            "Mortification",   -- Level 92
            "Fetidity",        -- Level 87
            "Putrescence",     -- Level 82
            "Putrefaction",    -- Level 77
        },
        ['CripplingTap'] = {
            -- >= LVL56 Crippling Claudication
            "Crippling Paraplegia",   -- Level 106
            "Crippling Incapacity",   -- Level 96
            "Crippling Claudication", -- Level 56
        },
        ['ChaoticDebuff'] = {
            -- >= LVL93
            -- Chaotic Contgion
            "Chaotic Fetor",        -- Level 123
            "Chaotic Acridness",    -- Level 118
            "Chaotic Miasma",       -- Level 113
            "Chaotic Effluvium",    -- Level 108
            "Chaotic Liquefaction", -- Level 103
            "Chaotic Corruption",   -- Level 98
            "Chaotic Contagion",    -- Level 93
        },
        ['SnareDot'] = {
            -- LVL4 -> <= LVL70
            "Clinging Darkness XIX", -- Level 129
            "Afflicted Darkness",    -- Level 124
            "Harrowing Darkness",    -- Level 119
            "Tormenting Darkness",   -- Level 114
            "Gnawing Darkness",      -- Level 109
            "Grasping Darkness",     -- Level 104
            "Clutching Darkness",    -- Level 99
            "Viscous Darkness",      -- Level 94
            "Tenuous Darkness",      -- Level 89
            "Clawing Darkness",      -- Level 84
            "Auroral Darkness",      -- Level 79
            "Coruscating Darkness",  -- Level 74
            "Desecrating Darkness",  -- Level 68
            "Embracing Darkness",    -- Level 63
            "Devouring Darkness",    -- Level 59
            "Cascading Darkness",    -- Level 47
            "Scent of Darkness",     -- Level 37
            "Dooming Darkness",      -- Level 27
            "Engulfing Darkness",    -- Level 11
            "Clinging Darkness",     -- Level 4
        },
        ['ScentDebuff'] = {
            -- line needed till >= LVL10 <= LVL85
            "Scent of Dusk XIII",  -- Level 127
            "Scent of The Realm",  -- Level 122
            "Scent of The Grave",  -- Level 117
            "Scent of Mortality",  -- Level 112
            "Scent of Extinction", -- Level 107
            "Scent of Dread",      -- Level 97
            "Scent of Nightfall",  -- Level 92
            "Scent of Doom",       -- Level 87
            "Scent of Gloom",      -- Level 82
            "Scent of Afterlight", -- Level 77
            "Scent of Twilight",   -- Level 72
            "Scent of Midnight",   -- Level 68
            "Scent of Terris",     -- Level 52
            "Scent of Darkness",   -- Level 37
            "Scent of Shadow",     -- Level 21
            "Scent of Dusk",       -- Level 10
        },
        ['LichSpell'] = {
            -- LichForm Spell
            "Otherside XX",        -- Level 129
            "Realmside",           -- Level 124
            "Lunaside",            -- Level 119
            "Gloomside",           -- Level 114
            "Contraside",          -- Level 109
            "Forgottenside",       -- Level 104
            "Forsakenside",        -- Level 99
            "Shadowside",          -- Level 94
            "Darkside",            -- Level 89
            "Netherside",          -- Level 84
            "Spectralside",        -- Level 79
            "Otherside",           -- Level 74
            "Dark Possession",     -- Level 70
            "Grave Pact",          -- Level 70
            "Seduction of Saryrn", -- Level 64
            "Arch Lich",           -- Level 60
            "Demi Lich",           -- Level 56
            "Lich",                -- Level 48
            "Call of Bones",       -- Level 31
            "Allure of Death",     -- Level 18
            "Dark Pact",           -- Level 6
        },
        ['BestowBuff'] = {
            "Bestow Undeath X", -- Level 128
            "Bestow Ruin",      -- Level 123
            "Bestow Rot",       -- Level 118
            "Bestow Dread",     -- Level 113
            "Bestow Relife",    -- Level 108
            "Bestow Doom",      -- Level 103
            "Bestow Mortality", -- Level 98
            "Bestow Decay",     -- Level 93
            "Bestow Unlife",    -- Level 88
            "Bestow Undeath",   -- Level 83
        },
        ['RogPetSpell'] = {
            "Dark Assassin XVI",    -- Level 130
            "Merciless Assassin",   -- Level 125
            "Unrelenting Assassin", -- Level 120
            "Restless Assassin",    -- Level 115
            "Restless Assassin",    -- Level 115
            "Reliving Assassin",    -- Level 110
            "Revived Assassin",     -- Level 105
            "Unearthed Assassin",   -- Level 100
            "Reborn Assassin",      -- Level 95
            "Raised Assassin",      -- Level 90
            "Unliving Murderer",    -- Level 85
            "Noxious Servant",      -- Level 80
            "Putrescent Servant",   -- Level 75
            "Dark Assassin",        -- Level 70
            "Saryrn's Companion",   -- Level 63
            "Minion of Shadows",    -- Level 53
        },
        ['WarPetSpell'] = {
            "Rasvimun's Shade",      -- Level 127
            "Margator's Shade",      -- Level 122
            "Luclin's Conqueror",    -- Level 117
            "Tserrina's Shade",      -- Level 112
            "Adalora's Shade",       -- Level 107
            "Miktokla's Shade",      -- Level 102
            "Zalifur's Shade",       -- Level 97
            "Vak`Ridel's Shade",     -- Level 92
            "Aziad's Shade",         -- Level 87
            "Bloodreaper's Shade",   -- Level 82
            "Relamar's Shade",       -- Level 77
            "Riza`farr's Shadow",    -- Level 72
            "Lost Soul",             -- Level 67
            "Child of Bertoxxulous", -- Level 65
            "Emissary of Thule",     -- Level 59
            "Servant of Bones",      -- Level 56
            "Invoke Death",          -- Level 48
            "Cackling Bones",        -- Level 44
            "Malignant Dead",        -- Level 39
            "Invoke Shadow",         -- Level 33
            "Summon Dead",           -- Level 29
            "Haunting Corpse",       -- Level 24
            "Animate Dead",          -- Level 20
            "Restless Bones",        -- Level 16
            "Convoke Shadow",        -- Level 12
            "Bone Walk",             -- Level 8
            "Leering Corpse",        -- Level 4
            "Cavorting Bones",       -- Level 1
        },
        ['PetBuff'] = {
            "Necrotize Ally X", -- Level 130
            "Instill Ally",     -- Level 125
            "Inspire Ally",     -- Level 120
            "Incite Ally",      -- Level 115
            "Infuse Ally",      -- Level 110
            "Imbue Ally",       -- Level 105
            --The below spells deal PBAE damage on fade and should not be casually used (later spells drop this effect)
            -- "Sanction Ally",  -- Level 100
            -- "Empower Ally",   -- Level 95
            -- "Energize Ally",  -- Level 90
            -- "Necrotize Ally", -- Level 85
        },
        ['PetHaste'] = {
            "Sigil of Death XV",          -- Level 127
            "Sigil of Putrefaction",      -- Level 122
            "Sigil of Undeath",           -- Level 117
            "Sigil of Decay",             -- Level 112
            "Sigil of the Arcron",        -- Level 107
            "Sigil of the Doomscale",     -- Level 102
            "Sigil of the Sundered",      -- Level 97
            "Sigil of the Preternatural", -- Level 92
            "Sigil of the Moribund",      -- Level 87
            "Sigil of the Aberrant",      -- Level 77
            "Sigil of the Unnatural",     -- Level 72
            "Glyph of Darkness",          -- Level 67
            "Rune of Death",              -- Level 62
            "Augmentation of Death",      -- Level 55
            "Augment Death",              -- Level 35
            "Intensify Death",            -- Level 23
            "Focus Death",                -- Level 11
        },
        ['PetHealSpell'] = {
            "Chilling Renewal XVI", -- Level 128
            "Bracing Revival",      -- Level 123
            "Frigid Salubrity",     -- Level 118
            "Icy Revival",          -- Level 113
            "Algid Renewal",        -- Level 108
            "Icy Mending",          -- Level 103
            "Algid Mending",        -- Level 98
            "Chilled Mending",      -- Level 93
            "Gelid Mending",        -- Level 88
            "Icy Stitches",         -- Level 83
            "Wintry Revival",       -- Level 78
            "Chilling Renewal",     -- Level 73
            "Dark Salve",           -- Level 69
            "Touch of Death",       -- Level 64
            "Renew Bones",          -- Level 26
            "Mend Bones",           -- Level 7
        },
        ['FleshBuff'] = {
            "Flesh to Toxin",  -- Level 119
            "Flesh to Venom",  -- Level 109
            "Flesh to Poison", -- Level 99
        },
    },
    ['Charm']           = {
        ['Abilities'] = {
            { name = "Dire Charm", type = "AA", },
            { name = "CharmSpell", type = "Spell", },
        },
    },
    ['RotationOrder']   = {
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
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and Casting.AmIBuffable() and not Core.IsCharming()
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
            name = 'Lich Management',
            timer = 10,
            state = 1,
            steps = 1,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return true
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
            name = 'Scent',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoScentDebuff') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount') and
                    not Casting.IAmFeigning() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and not Casting.IAmFeigning() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(MobHighHP)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Targeting.MobNotLowHP(Targeting.GetAutoTarget()) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(MobLowHP)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Targeting.MobHasLowHP(Targeting.GetAutoTarget()) and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']       = {
        ['Lich Management'] = {
            {
                name = "LichSpell",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Config:GetSetting('DoLich') and Casting.SelfBuffCheck(spell, nil, true) and
                        (not Config:GetSetting('DoUnity') or not Casting.AAReady("Mortifier's Unity")) and
                        mq.TLO.Me.PctHPs() > Config:GetSetting('StopLichHP') and mq.TLO.Me.PctMana() <= Config:GetSetting('StartLichMana')
                end,
            },
            {
                name = "LichControl",
                type = "CustomFunc",
                cond = function(self, _)
                    local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

                    return not (Config:GetSetting('DoUnity') and Casting.CanUseAA("Mortifier's Unity")) and lichSpell and lichSpell() and Casting.IHaveBuff(lichSpell) and
                        (mq.TLO.Me.PctHPs() <= Config:GetSetting('StopLichHP') or mq.TLO.Me.PctMana() >= Config:GetSetting('StopLichMana'))
                end,
                custom_func = function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.Helpers.CancelLich, self)
                    return true
                end,
            },
            {
                name = "FleshControl",
                type = "CustomFunc",
                cond = function(self, _)
                    local fleshSpell = self:GetResolvedActionMapItem('FleshBuff')

                    return fleshSpell and fleshSpell() and Casting.IHaveBuff(fleshSpell) and mq.TLO.Me.PctHPs() <= Config:GetSetting('StopLichHP')
                end,
                custom_func = function(self)
                    Core.SafeCallFunc("Stop Flesh Buff", self.Helpers.CancelFlesh, self)
                    return true
                end,
            },
        },
        ['Emergency']       = {
            {
                name = "Death's Effigy",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('AggroFeign') then return false end
                    if Config:GetSetting('CharmOn') and mq.TLO.Me.Pet.ID() > 0 then return false end
                    return (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99) or (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Targeting.IHaveAggro(100))
                end,
            },
            {
                name = "Death Peace",
                type = "AA",
                cond = function(self, aaName)
                    if not Config:GetSetting('AggroFeign') then return false end
                    return (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99) or (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Targeting.IHaveAggro(100))
                end,
            },
            {
                name = "Dying Grasp",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Embalmer's Carapace",
                type = "AA",
            },
            {
                name = "Lifetap",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLifetap') end,
            },
        },
        ['Scent']           = {
            {
                name = "Scent of Thule",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "ScentDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['DPS(MobHighHP)']  = {
            {
                name = "DurationTap",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDurationTap') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "DreadDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDreadDot') > 1 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "ManaDrain",
                type = "Spell",
                cond = function(self, spell, target)
                    if not spell or not spell() then return false end
                    return Casting.IHaveBuff(spell.Name() .. " Recourse") and (mq.TLO.Target.PctMana() or -1) > 0 and mq.TLO.Group.LowMana(40)() > 2
                end,
            },
            {
                name = "VenomDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVenomDot') > 1 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "ComboDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoComboDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "HorrorDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHorrorDot') > 1 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "GroupLeech",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoGroupLeech') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target) and
                        self.Helpers.GroupMemberBelowHP(self, Config:GetSetting('LightHealPoint'))
                end,
            },
            {
                name = "DichoDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDichoDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "SearingDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSearingDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "MoriDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoMoriDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "WoundDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWoundDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "DecayDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDecayDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "GripDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoGripDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "HazeDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHazeDot') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "DreadDot2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDreadDot') > 2 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "VenomDot2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVenomDot') > 2 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "HorrorDot2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHorrorDot') > 2 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "SwarmPet",
                type = "Spell",
                cond = function(self, spell, target)
                    return Globals.AutoTargetIsNamed and Casting.OkayToNuke()
                end,
            },
            {
                name = "PoisonNuke2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "PoisonNuke1",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('PoisonNuke2') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['DPS(MobLowHP)']   = {
            {
                name = "Lifetap",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLifetap') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke() and Targeting.LightHealsNeeded(mq.TLO.Me)
                end,
            },
            {
                name = "SwarmPet",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "PoisonNuke2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "PoisonNuke1",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('PoisonNuke2') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['Snare']           = {
            {
                name = "Encroaching Darkness",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Encroaching Darkness") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareDot",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Encroaching Darkness") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Burn']            = { -- TODO: Needs optimization. For now its all just kinda thrown in. --Algar
            {
                name = "Scent of Thule",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold')
                end,
            },
            {
                name = "Funeral Pyre",
                type = "AA",
            },
            {
                name = "Hand of Death",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold')
                end,
            },
            {
                name = "Mercurial Torment",
                type = "AA",
            },
            {
                name = "Heretic's Twincast",
                type = "AA",
            },
            {
                name = "Gathering Dusk",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold') and mq.TLO.Me.PctAggro() <= 25
                end,
            },
            {
                name = "Swarm of Decay",
                type = "AA",
            },
            {
                name = "Wake the Dead",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.SpawnCount("corpse radius 100 los")() >= Config:GetSetting('WakeDeadCorpseCnt')
                end,
            },
            {
                name = "Companion's Fury",
                type = "AA",
            },
            {
                name = "Rise of Bones",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
            {
                name = "Spire of Necromancy",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold')
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
                name = "BestowBuff",
                type = "Spell",
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Silent Casting",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 60
                end,
            },
            {
                name = "Dying Grasp",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() <= 50
                end,
            },
        },
        ['PetHealing']      = {
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
        ['Downtime']        = {
            {
                name = "Mortifier's Unity",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoUnity') and mq.TLO.Me.PctHPs() > Config:GetSetting('StopLichHP') and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Dead Man Floating",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoLevitate') and Casting.CanUseAA("Dead Man Floating") end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName) return Casting.SelfBuffAACheck(aaName) end,
            },
            {
                name = "Levitate",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLevitate') and not Casting.CanUseAA("Dead Man Floating") end,
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
                name = "SelfSpellShield1",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Death Bloom",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName) return mq.TLO.Me.PctMana() < Config:GetSetting('DeathBloomPercent') end,
            },
            {
                name = "BestowBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "FleshBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return mq.TLO.Me.PctHPs() > Config:GetSetting('EmergencyStart') and Casting.SelfBuffCheck(spell)
                end,
            },
        },
        ['PetSummon']       = { --TODO: Double check these lists to ensure someone leveling doesn't have to change options to keep pets current at lower levels
            {
                name_func = function(self)
                    return string.format("%sPetSpell", self.ClassConfig.DefaultConfig.PetType.ComboOptions[Config:GetSetting('PetType')])
                end,
                type = "Spell",
                active_cond = function(self) return mq.TLO.Me.Pet.ID() > 0 end,
                cond = function(self, spell)
                    return Casting.ReagentCheck(spell)
                end,
                post_activate = function(self, spell, success)
                    local pet = mq.TLO.Me.Pet
                    if success and pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff']         = {
            {
                name = "PetHaste",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "PetBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
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
    ['Helpers']         = {
        -- Check if any group member (excluding self) is at or below a given HP%. This is used to make sure someone needs to heal before we use the group leech.
        -- The intent is to only use the mana heavy group leech as a quasi-heal when someone actually needs the health.
        GroupMemberBelowHP = function(self, pct)
            local count = mq.TLO.Group.Members() or 0
            for i = 1, count do
                local member = mq.TLO.Group.Member(i)
                if member and member() and (member.PctHPs() or 100) <= pct then
                    return true
                end
            end
            return false
        end,

        CancelLich = function(self)
            -- detspa means detremental spell affect
            -- spa is positive spell affect
            local lichName = mq.TLO.Me.FindBuff("detspa hp and spa mana")()
            Core.DoCmd("/removebuff %s", lichName)
        end,

        CancelFlesh = function(self)
            local fleshName = self:GetResolvedActionMapItem('FleshBuff')
            Core.DoCmd("/removebuff %s", fleshName)
        end,

        StartLich = function(self)
            local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

            if lichSpell and lichSpell() then
                Casting.UseSpell(lichSpell.RankName.Name(), mq.TLO.Me.ID(), false)
            end
        end,
    },
    ['SpellList']       = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "PetHealSpell", cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "PoisonNuke1",  cond = function(self) return not Core.GetResolvedActionMapItem('PoisonNuke2') end, },
                { name = "PoisonNuke2", },
                { name = "FireNuke", },
                { name = "Lifetap",      cond = function(self) return Config:GetSetting('DoLifetap') end, },
                { name = "CharmSpell",   cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "SnareDot",     cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Enchroaching Darkness") end, },
                { name = "ScentDebuff",  cond = function(self) return Config:GetSetting('DoScentDebuff') and not Casting.CanUseAA("Scent of Thule") end, },
                { name = "LichSpell",    cond = function(self) return not Config:GetSetting('DoUnity') end, },
                { name = "SwarmPet", },
                { name = "DurationTap",  cond = function(self) return Config:GetSetting('DoDurationTap') end, },
                { name = "DreadDot",     cond = function(self) return Config:GetSetting('DoDreadDot') > 1 end, },
                { name = "VenomDot",     cond = function(self) return Config:GetSetting('DoVenomDot') > 1 end, },
                { name = "HorrorDot",    cond = function(self) return Config:GetSetting('DoHorrorDot') > 1 end, },
                { name = "ComboDot",     cond = function(self) return Config:GetSetting('DoComboDot') end, },
                { name = "GroupLeech",   cond = function(self) return Config:GetSetting('DoGroupLeech') end, },
                { name = "DichoDot",     cond = function(self) return Config:GetSetting('DoDichoDot') end, },
                { name = "SearingDot",   cond = function(self) return Config:GetSetting('DoSearingDot') end, },
                { name = "MoriDot",      cond = function(self) return Config:GetSetting('DoMoriDot') end, },
                { name = "WoundDot",     cond = function(self) return Config:GetSetting('DoWoundDot') end, },
                { name = "DecayDot",     cond = function(self) return Config:GetSetting('DoDecayDot') end, },
                { name = "GripDot",      cond = function(self) return Config:GetSetting('DoGripDot') end, },
                { name = "HazeDot",      cond = function(self) return Config:GetSetting('DoHazeDot') end, },
                { name = "DreadDot2",    cond = function(self) return Config:GetSetting('DoDreadDot') > 2 end, },
                { name = "VenomDot2",    cond = function(self) return Config:GetSetting('DoVenomDot') > 2 end, },
                { name = "HorrorDot2",   cond = function(self) return Config:GetSetting('DoHorrorDot') > 2 end, },
                { name = "ManaDrain", },
                { name = "FleshBuff",    cond = function(self) return not Config:GetSetting('DoUnity') or not Casting.CanUseAA("Mortifier's Unity") end, },
                { name = "BestowBuff", },
                { name = "PetBuff", },
            },
        },
    },
    ['DefaultConfig']   = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different Modes Do?",
            Answer = "Currently Necros only have one mode, which is DPS. This mode will focus on DPS and some utility.",
        },
        ['PetType']           = {
            DisplayName = "Pet Class",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Tooltip = "1 = War, 2 = Rog",
            Type = "Combo",
            ComboOptions = { 'War', 'Rog', },
            Default = function() return Core.GetResolvedActionMapItem('RogPetSpell') and 2 or 1 end,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
        },
        ['DoPetHealSpell']    = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Pet Heal spell. AA Pet Heals are always used in emergencies.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['PetHealPct']        = {
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
        ['DoLifeBurn']        = {
            DisplayName = "Use Life Burn",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Life Burn AA if your aggro is below 25%.",
            Default = true,
        },
        ['DoUnity']           = {
            DisplayName = "Cast Unity",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Enable casting Mortifiers Unity.",
            Default = true,
            Index = 101,
        },
        ['DeathBloomPercent'] = {
            DisplayName = "Death Bloom %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Tooltip = "Mana % at which to cast Death Bloom",
            Default = 40,
            Min = 1,
            Max = 100,
        },
        ['DoSnare']           = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
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
        ['WakeDeadCorpseCnt'] = {
            DisplayName = "WtD Corpse Count",
            Group = "Abilities",
            Header = "Pet",
            Category = "Swarm Pets",
            Tooltip = "Number of Corpses before we cast Wake the Dead",
            Default = 5,
            Min = 1,
            Max = 20,
        },
        ['DoLich']            = {
            DisplayName = "Cast Lich",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Enable casting Lich spells.",
            RequiresLoadoutChange = true,
            Default = true,
            Index = 102,
        },
        ['StopLichHP']        = {
            DisplayName = "Stop Lich HP",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Cancel Lich at HP Pct [x]",
            RequiresLoadoutChange = false,
            Default = 25,
            Min = 1,
            Max = 99,
            Index = 103,
        },
        ['StopLichMana']      = {
            DisplayName = "Stop Lich Mana",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Cancel your Lich spell when your mana has increased to this percentage. (Selecting 101 will disable canceling lich based on mana percent.)",
            RequiresLoadoutChange = false,
            Default = 100,
            Min = 1,
            Max = 101,
            Index = 104,
        },
        ['StartLichMana']     = {
            DisplayName = "Start Lich Mana",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Start Lich at Mana Pct [x]",
            RequiresLoadoutChange = false,
            Default = 70,
            Min = 1,
            Max = 100,
            Index = 105,
        },
        ['DoLevitate']        = {
            DisplayName = "Do Levitate",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Enable self-casting your Dead Man Floating spell.",
            RequiresLoadoutChange = true,
            Default = true,
            Index = 106,
        },
        ['DoScentDebuff']     = {
            DisplayName = "Use Scent Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Tooltip = "Use your Scent debuff spells or AA.",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = false,
        },
        ['DoLifetap']         = {
            DisplayName = "Do Lifetap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Taps",
            Index = 101,
            Tooltip = "Use the your ST Lifetap nuke line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['EmergencyStart']    = {
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
        ['AggroFeign']        = {
            DisplayName = "Emergency Feign",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use your Feign AA when you have aggro at low health or aggro on a mob detected as a 'named' by RGMercs (see Spawns tab)..",
            Default = true,
        },
        ['DoDurationTap']     = {
            DisplayName = "Do Duration Tap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your duration tap line of dots.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoDreadDot']        = {
            DisplayName = "Do Dread Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Select the number of Dread (Fire) dots to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { "Disabled", "Current Tier", "Current + Last Tier", },
            Default = 2,
            Min = 1,
            Max = 3,
        },
        ['DoVenomDot']        = {
            DisplayName = "Do Venom Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Select the number of Venom (Poison) dots to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { "Disabled", "Current Tier", "Current + Last Tier", },
            Default = 2,
            Min = 1,
            Max = 3,
        },
        ['DoHorrorDot']       = {
            DisplayName = "Do Horror Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Select the number of Horror (Magic) dots to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { "Disabled", "Current Tier", "Current + Last Tier", },
            Default = 2,
            Min = 1,
            Max = 3,
        },
        ['DoComboDot']        = {
            DisplayName = "Do Combo Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 105,
            Tooltip = "Use your Disease combination (Grip+Decay) line of dots.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoGroupLeech']      = {
            DisplayName = "Do Group Leech",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 106,
            Tooltip = "Use your Group Leech dot line. Only fires when a watched party member is below the light heal threshold.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoDichoDot']        = {
            DisplayName = "Do Dicho Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 107,
            Tooltip = "Use your Dichotomic Paroxysm dot line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoSearingDot']      = {
            DisplayName = "Do Searing Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 108,
            Tooltip = "Use your Searing (Fire) dot line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoMoriDot']         = {
            DisplayName = "Do Mori Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 109,
            Tooltip = "Use your Mori (Fire) dot line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoWoundDot']        = {
            DisplayName = "Do Wound Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 110,
            Tooltip = "Use your Wound (Magic) dot line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoDecayDot']        = {
            DisplayName = "Do Decay Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 111,
            Tooltip = "Use your Decay (Disease) dot line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoGripDot']         = {
            DisplayName = "Do Grip Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 112,
            Tooltip = "Use your Grip (Disease) dot line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoHazeDot']         = {
            DisplayName = "Do Haze Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 113,
            Tooltip = "Use your Haze (Poison) dot line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoChestClick']      = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['BurnHPThreshold']   = {
            DisplayName = "Burn HP Threshold",
            Group = "Combat",
            Header = "Burning",
            Category = "Burning",
            Index = 101,
            Tooltip =
            "Burn abilities that are best used once dots have been applied will be held until a named has reached this HP value. (Affected abilities: Spire, Hand of Death, Gathering Dusk, OoW Robe)",
            Default = 70,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']        = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release aimed at official servers.\n\n" ..
                "  This config is largely a port from older code, and has seen only minor adjustments. It has been flagged for revamp when we have the chance!\n\n" ..
                " Some revamps have occured to provide more spell/dot options, but it's still rough around the edges!\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
