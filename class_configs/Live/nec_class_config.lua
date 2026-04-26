-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

-- [ NOTE ON ORDERING ] --
-- Order matters! Lua will implicitly iterate everything in an array
-- in order by default so always put the first thing you want checked
-- towards the top of the list.

local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Comms        = require("utils.comms")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")

local _ClassConfig = {
    _version            = "1.1 - Live",
    _author             = "Derple, Grimmier, Algar",
    ['Modes']           = {
        'DPS',
    },
    ['ModeChecks']      = {
        -- necro can AA Rez
        IsRezing   = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
        CanCharm   = function() return true end,
        IsCharming = function() return (Config:GetSetting('CharmOn') and mq.TLO.Pet.ID() == 0) end,
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
            "Shielding XXIII",
            "Shield of Memories",
            "Shield of Shadow",
            "Shield of Restless Ice",
            "Shield of Scales",
            "Shield of the Pellarus",
            "Shield of the Dauntless",
            "Shield of Bronze",
            "Shield of Dreams",
            "Shield of the Void",
            "Bulwark of the Crystalwing",
            "Shield of the Crystalwing",
            "Ether Shield",
            "Shield of Maelin",
            "Shield of the Arcane",
            "Shield of the Magi",
            "Arch Shielding",
            "Greater Shielding",
            "Major Shielding",
            "Shielding",
            "Lesser Shielding",
        },
        ['SelfRune1'] = {
            "Wraithskin XIII",
            "Golemskin",
            "Carrion Skin",
            "Frozen Skin",
            "Ashen Skin",
            "Deadskin",
            "Zombieskin",
            "Ghoulskin",
            "Grimskin",
            "Corpseskin",
            "Shadowskin",
            "Wraithskin",
        },
        ['SelfSpellShield1'] = {
            "Shield of Fate VII",
            "Shield of Inescapability",
            "Shield of Inevitability",
            "Shield of Destiny",
            "Shield of Order",
            "Shield of Consequence",
            "Shield of Fate",
        },
        ['FDSpell'] = {
            -- Fd Spell
            "Death Peace",
        },
        ['CharmSpell'] = {
            -- Charm Spells >= 20
            "Enslave Death",
            "Thrall of Bones",
            "Cajole Undead",
            "Beguile Undead",
            "Dominate Undead",
        },
        ---DPS
        ['AllianceSpell'] = {
            -- Alliance Spells
            "Malevolent Covariance",
            "Malevolent Conjunction",
            "Malevolent Coalition",
            "Malevolent Covenant",
            "Malevolent Alliance",
        },
        ['DichoDot'] = {
            ---DichoSpell >= LVL101
            "Ecliptic Paroxysm",
            "Composite Paroxysm",
            "Dissident Paroxysm",
            "Dichotomic Paroxysm",
            "Reciprocal Paroxysm",
        },
        ['SwarmPet'] = {
            ---SwarmPet >= LVL85
            "Call Raging Skeleton X",
            "Call Ravening Skeleton",
            "Call Roiling Skeleton",
            "Call Riotous Skeleton",
            "Call Reckless Skeleton",
            "Call Remorseless Skeleton",
            "Call Relentless Skeleton",
            "Call Ruthless Skeleton",
            "Call Ruinous Skeleton",
            "Call Rumbling Skeleton",
            "Call Skeleton Thrall",
            "Call Skeleton Mass",
            "Call Skeleton Horde",
            "Call Skeleton Army",
            "Call Skeleton Mob",
            "Call Skeleton Throng",
            "Call Skeleton Host",
            "Call Skeleton Crush",
            "Call Skeleton Swarm",
        },
        ['Lifetap'] = {
            ---HealthTaps >= LVL1
            "Soulrip VII",
            "Drain Essence XXIII",
            "Soullash",
            "Extort Essence",
            "Soulflay",
            "Maraud Essence",
            "Soulgouge",
            "Draw Essence",
            "Soulsiphon",
            "Consume Essence",
            "Soulrend",
            "Hemorrhage Essence",
            "Plunder Essence",
            "Bleed Essence",
            "Divert Essence",
            "Drain Essence",
            "Siphon Essence",
            "Drain Life",
            -- [] =["Ancient: Touch of Orshilak",
            "Soulspike",
            "Touch of Mujaki",
            "Touch of Night",
            "Deflux",
            "Drain Soul",
            "Drain Spirit",
            "Spirit Tap",
            "Siphon Life",
            "Lifedraw",
            "Lifespike",
            "Lifetap",
        },
        ['DurationTap'] = {
            ---DurationTap >= LVL29
            "Sharosh's Grasp",
            "Helmsbane's Grasp",
            "The Protector's Grasp",
            "Tserrina's Grasp",
            "Bomoda's Grasp",
            "Plexipharia's Grasp",
            "Halstor's Grasp",
            "Ivrikdal's Grasp",
            "Arachne's Grasp",
            "Fellid's Grasp",
            "Visziaj's Grasp",
            "Dyn`leth's Grasp",
            "Fang of Death",
            "Night's Beckon",
            "Saryrn's Kiss",
            "Vexing Mordinia",
            "Bond of Death",
            "Vampiric Curse",
        },
        ['GroupLeech'] = {
            ---GroupLeech >= LVL9
            "Dark Leech VIII",
            "Ghastly Leech",
            "Twilight Leech",
            "Frozen Leech",
            "Ashen Leech",
            "Dark Leech",
            "Leech",
        },
        ['ManaDrain'] = {
            --Mana Drain with Group Mana Recourse
            "Mind Wrack XIV",
            "Mind Disintegrate",
            "Mind Atrophy",
            "Mind Erosion",
            "Mind Exorciation",
            "Mind Extraction",
            "Mind Strip",
            "Mind Abrasion",
            "Thought Flay",
            "Mind Decomposition",
            "Mental Vivisection",
            "Mind Dissection",
            "Mind Flay",
            "Mind Wrack",
        },
        ['PoisonNuke1'] = {
            ---PoisonNuke >=LVL21
            "Schisming Venin",
            "Necrotizing Venin",
            "Embalming Venin",
            "Searing Venin",
            "Effluvial Venin",
            "Liquefying Venin",
            "Dissolving Venin",
            "Blighted Venin",
            "Withering Venin",
            "Ruinous Venin",
            "Venin",
            "Acikin",
            "Neurotoxin",
            "Torbas' Venom Blast",
            "Torbas' Poison Blast",
            "Torbas' Acid Blast",
            "Shock of Poison",
        },
        ['PoisonNuke2'] = {
            ---PoisonNuke2  >=LVL 75 (DD Increase chance)
            "Call for Blood XIII",
            "Decree for Blood",
            "Proclamation for Blood",
            "Assert for Blood",
            "Refute for Blood",
            "Impose for Blood",
            "Impel for Blood",
            --"Provocation for Blood",
            "Compel for Blood",
            "Exigency for Blood",
            "Supplication of Blood",
            "Demand for Blood",
            "Call for Blood",
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
            "Searing Shadow XI",
            "Raging Shadow",
            "Scalding Shadow",
            "Broiling Shadow",
            "Burning Shadow",
            "Smouldering Shadow",
            "Coruscating Shadow",
            "Blazing Shadow",
            "Blistering Shadow",
            "Scorching Shadow",
            "Searing Shadow",
        },
        ['DreadDot'] = {
            ---FireDot2 >= LVL10
            "Dread Pyre XIII",
            "Pyre of Illandrin",
            "Pyre of Va Xakra",
            "Pyre of Klraggek",
            "Pyre of the Shadewarden",
            "Pyre of Jorobb",
            "Pyre of Marnek",
            "Pyre of Hazarak",
            "Pyre of Nos",
            "Soul Reaper's Pyre",
            "Reaver's Pyre",
            "Ashengate Pyre",
            "Dread Pyre",
            "Night Fire",
            "Funeral Pyre of Kelador",
            "Pyrocruor",
            "Ignite Blood",
            "Boil Blood",
            "Heat Blood",
        },
        ['DreadDot2'] = {
            ---FireDot2 >= LVL10
            "Dread Pyre XIII",
            "Pyre of Illandrin",
            "Pyre of Va Xakra",
            "Pyre of Klraggek",
            "Pyre of the Shadewarden",
            "Pyre of Jorobb",
            "Pyre of Marnek",
            "Pyre of Hazarak",
            "Pyre of Nos",
            "Soul Reaper's Pyre",
            "Reaver's Pyre",
            "Ashengate Pyre",
            "Dread Pyre",
            "Night Fire",
            "Funeral Pyre of Kelador",
            "Pyrocruor",
            "Ignite Blood",
            "Boil Blood",
            "Heat Blood",
        },
        ['FlashDot'] = {
            ---FireDot3 >= LVL88 (QuickDOT)
            "Marith's Flashblaze",
            "Arcanaforged's Flashblaze",
            "Thall Va Kelun's Flashblaze",
            "Otatomik's Flashblaze",
            "Azeron's Flashblaze",
            "Mazub's Flashblaze",
            "Osalur's Flashblaze",
            "Brimtav's Flashblaze",
            "Tenak's Flashblaze",
        },
        ['MoriDot'] = {
            ---FireDot4 >= LVL73 DOT
            "Pyre of Mori XIX",
            "Pyre of the Abandoned",
            "Pyre of the Neglected",
            "Pyre of the Wretched",
            "Pyre of the Fereth",
            "Pyre of the Lost",
            "Pyre of the Forsaken",
            "Pyre of the Piq'a",
            "Pyre of the Bereft",
            "Pyre of the Forgotten",
            "Pyre of the Lifeless",
            "Pyre of the Fallen",
        },
        ['WoundDot'] = {
            ---Magic1 >= LVL51 SlowDot
            "Necrotizing Wounds VIII",
            "Putrefying Wounds",
            "Infected Wounds",
            "Septic Wounds",
            "Cytotoxic Wounds",
            "Mortiferous Wounds",
            "Pernicious Wounds",
            "Necrotizing Wounds",
            "Splirt",
            "Splart",
            "Splort",
            "Splurt",
        },
        ['HorrorDot'] = {
            ---Magic2 >=LVL67 DOT
            "Horror XV",
            "Extermination",
            "Extinction",
            "Oblivion",
            "Inevitable End",
            "Annihilation",
            "Termination",
            "Doom",
            "Demise",
            "Mortal Coil",
            "Anathema of Life",
            "Curse of Mortality",
            "Ancient: Curse of Mori",
            "Dark Nightmare",
            "Horror",
        },
        ['HorrorDot2'] = {
            ---Magic2 >=LVL67 DOT
            "Horror XV",
            "Extermination",
            "Extinction",
            "Oblivion",
            "Inevitable End",
            "Annihilation",
            "Termination",
            "Doom",
            "Demise",
            "Mortal Coil",
            "Anathema of Life",
            "Curse of Mortality",
            "Ancient: Curse of Mori",
            "Dark Nightmare",
            "Horror",
        },
        ['DeconDot'] = {
            ---Magic3 >=LVL87 QuickDot
            "Xirrim's Swift Deconstruction",
            "Blevak's Swift Deconstruction",
            "Xetheg's Swift Deconstruction",
            "Lexelan's Swift Deconstruction",
            "Adalora's Swift Deconstruction",
            "Marmat's Swift Deconstruction",
            "Itkari's Swift Deconstruction",
            "Hral's Swift Deconstruction",
            "Ninavero's Swift Deconstruction",
        },
        ['ScourgeDot'] = {
            ---Magic4 >=LVL 97 DOT
            "Scourge of Eternity", -- Level 123 TOB
            "Scourge of Destiny",
            "Scourge of Fates",
        },
        ['ComboDot'] = { ---Combines GripDot and DecayDot
            "Goremand's Grip of Decay",
            "Fleshrot's Grip of Decay",
            "Danvid's Grip of Decay",
            "Mourgis' Grip of Decay",
            "Livianus' Grip of Decay",
        },
        ['DecayDot'] = {
            ---Decay Line of Disease Spells >=LVL56 Slow DOT
            "Pustim's Decay",
            "Goremand's Decay",
            "Fleshrot's Decay",
            "Danvid's Decay",
            "Mourgis' Decay",
            "Livianus' Decay",
            "Wuran's Decay",
            "Ulork's Decay",
            "Folasar's Decay",
            "Megrima's Decay",
            "Eranon's Decay",
            "Severan's Rot",
            "Chaos Plague",
            "Dark Plague",
            "Cessation of Cor",
        },
        ['GripDot'] = {
            ---Grip Line of Disease Spells =LVL1 HAS DEBUFF
            "Grip of Pustim",
            "Grip of Quietus",
            "Grip of Zorglim",
            "Grip of Kraz",
            "Grip of Jabaum",
            "Grip of Zalikor",
            "Grip of Zargo",
            "Grip of Mori",
            "Plague",
            "Asystole",
            "Scourge",
            -- "Infectious Cloud",
            "Heart Flutter",
            "Disease Cloud",
        },
        ['SwiftDiseaseDot'] = {
            ---Sickness Life of Disease Spells >=LVL89 QuickDOT
            "Wremms's Swift Sickness",
            "Ogna's Swift Sickness",
            "Diabo Tatrua's Swift Sickness",
            "Lairsaf's Swift Sickness",
            "Hoshkar's Swift Sickness",
            "Ilsaria's Swift Sickness",
            "Bora's Swift Sickness",
            "Prox's Swift Sickness",
            "Rilfed's Swift Sickness",
        },
        ['SwiftPoisonDot'] = {
            ---Poison1 >= LVL86 (QuickDOT)
            "Lherre's Swift Venom",
            "Dotal's Swift Venom",
            "Xenacious' Swift Venom",
            "Vilefang's Swift Venom",
            "Nexona's Swift Venom",
            "Serisaria's Swift Venom",
            "Slaunk's Swift Venom",
            "Hyboram's Swift Venom",
            "Burlabis' Swift Venom",
        },
        ['VenomDot'] = {
            ---Poison2 >=LVL1 (DOT)
            "Silkwhisper Venom",
            "Luggald Venom",
            "Hemorrhagic Venom",
            "Crystal Crawler Venom",
            "Polybiad Venom",
            "Glistenwing Venom",
            "Binaesa Venom",
            "Naeya Venom",
            "Argendev's Venom",
            "Slitheren Venom",
            "Venonscale Venom",
            "Vakk`dra's Sickly Mists",
            "Blood of Thule",
            "Envenomed Bolt",
            "Chilling Embrace",
            "Venom of the Snake",
            "Poison Bolt",
        },
        ['VenomDot2'] = {
            ---Poison2 >=LVL1 (DOT)
            "Silkwhisper Venom",
            "Luggald Venom",
            "Hemorrhagic Venom",
            "Crystal Crawler Venom",
            "Polybiad Venom",
            "Glistenwing Venom",
            "Binaesa Venom",
            "Naeya Venom",
            "Argendev's Venom",
            "Slitheren Venom",
            "Venonscale Venom",
            "Vakk`dra's Sickly Mists",
            "Blood of Thule",
            "Envenomed Bolt",
            "Chilling Embrace",
            "Venom of the Snake",
            "Poison Bolt",
        },
        ['HazeDot'] = {
            ---Poison3 >= LVL79 DOT
            "Khrosik's Pallid Haze",
            "Uncia's Pallid Haze",
            "Zelnithak's Pallid Haze",
            "Dracnia's Pallid Haze",
            "Bomoda's Pallid Haze",
            "Plexipharia's Pallid Haze",
            "Halstor's Pallid Haze",
            "Ivrikdal's Pallid Haze",
            "Arachne's Pallid Haze",
            "Fellid's Pallid Haze",
            "Visziaj's Pallid Haze",
            "Chaos Venom",
        },
        ['PutrefactionDot'] = {
            ---Corruption1 >= LVL77
            "Putrefaction XI",
            "Deterioration",
            "Decomposition",
            "Miasma",
            "Effluvium",
            "Liquefaction",
            "Dissolution",
            "Mortification",
            "Fetidity",
            "Putrescence",
            "Putrefaction",
        },
        ['CripplingTap'] = {
            -- >= LVL56 Crippling Claudication
            "Crippling Paraplegia",
            "Crippling Incapacity",
            "Crippling Claudication",
        },
        ['ChaoticDebuff'] = {
            -- >= LVL93
            -- Chaotic Contgion
            "Chaotic Fetor",
            "Chaotic Acridness",
            "Chaotic Miasma",
            "Chaotic Effluvium",
            "Chaotic Liquefaction",
            "Chaotic Corruption",
            "Chaotic Contagion",
        },
        ['SnareDot'] = {
            -- LVL4 -> <= LVL70
            "Clinging Darkness XIX",
            "Afflicted Darkness",
            "Harrowing Darkness",
            "Tormenting Darkness",
            "Gnawing Darkness",
            "Grasping Darkness",
            "Clutching Darkness",
            "Viscous Darkness",
            "Tenuous Darkness",
            "Clawing Darkness",
            "Auroral Darkness",
            "Coruscating Darkness",
            "Desecrating Darkness",
            "Embracing Darkness",
            "Devouring Darkness",
            "Cascading Darkness",
            "Scent of Darkness",
            "Dooming Darkness",
            "Engulfing Darkness",
            "Clinging Darkness",
        },
        ['ScentDebuff'] = {
            -- line needed till >= LVL10 <= LVL85
            "Scent of Dusk XIII",
            "Scent of The Realm",
            "Scent of The Grave",
            "Scent of Mortality",
            "Scent of Extinction",
            "Scent of Dread",
            "Scent of Nightfall",
            "Scent of Doom",
            "Scent of Gloom",
            "Scent of Afterlight",
            "Scent of Twilight",
            "Scent of Midnight",
            "Scent of Terris",
            "Scent of Darkness",
            "Scent of Shadow",
            "Scent of Dusk",
        },
        ['LichSpell'] = {
            -- LichForm Spell
            "Otherside XX",
            "Realmside",
            "Lunaside",
            "Gloomside",
            "Contraside",
            "Forgottenside",
            "Forsakenside",
            "Shadowside",
            "Darkside",
            "Netherside",
            "Spectralside",
            "Otherside",
            "Dark Possession",
            "Grave Pact",
            "Seduction of Saryrn",
            "Arch Lich",
            "Demi Lich",
            "Lich",
            "Call of Bones",
            "Allure of Death",
            "Dark Pact",
        },
        ['BestowBuff'] = {
            "Bestow Undeath X",
            "Bestow Ruin",
            "Bestow Rot",
            "Bestow Dread",
            "Bestow Relife",
            "Bestow Doom",
            "Bestow Mortality",
            "Bestow Decay",
            "Bestow Unlife",
            "Bestow Undeath",
        },
        ['RogPetSpell'] = {
            "Dark Assassin XVI",
            "Merciless Assassin",
            "Unrelenting Assassin",
            "Restless Assassin",
            "Reliving Assassin",
            "Restless Assassin",
            "Revived Assassin",
            "Unearthed Assassin",
            "Reborn Assassin",
            "Raised Assassin",
            "Unliving Murderer",
            "Noxious Servant",
            "Putrescent Servant",
            "Dark Assassin",
            "Child of Bertoxxulous",
            "Saryrn's Companion",
            "Minion of Shadows",
        },
        ['WarPetSpell'] = {
            "Rasivimun's Shade",
            "Margator's Shade",
            "Luclin's Conqueror",
            "Tserrina's Shade",
            "Adalora's Shade",
            "Miktokla's Shade",
            "Zalifur's Shade",
            "Vak`Ridel's Shade",
            "Aziad's Shade",
            "Bloodreaper's Shade",
            "Relamar's Shade",
            "Riza`farr's Shadow",
            "Lost Soul",
            "Emissary of Thule",
            "Servant of Bones",
            "Invoke Death",
            "Cackling Bones",
            "Malignant Dead",
            "Invoke Shadow",
            "Summon Dead",
            "Haunting Corpse",
            "Animate Dead",
            "Restless Bones",
            "Convoke Shadow",
            "Bone Walk",
            "Leering Corpse",
            "Cavorting Bones",
        },
        ['PetBuff'] = {
            "Necrotize Ally X",
            "Instill Ally",
            "Inspire Ally",
            "Incite Ally",
            "Infuse Ally",
            "Imbue Ally",
            --The below spells deal PBAE damage on fade and should not be casually used (later spells drop this effect)
            --"Sanction Ally",
            --"Empower Ally",
            --"Energize Ally",
            --"Necrotize Ally",
        },
        ['PetHaste'] = {
            "Sigil of Death XV",
            "Sigil of Putrefaction",
            "Sigil of Undeath",
            "Sigil of Decay",
            "Sigil of the Arcron",
            "Sigil of the Doomscale",
            "Sigil of the Sundered",
            "Sigil of the Preternatural",
            "Sigil of the Moribund",
            "Sigil of the Aberrant",
            "Sigil of the Unnatural",
            "Glyph of Darkness",
            "Rune of Death",
            "Augmentation of Death",
            "Augment Death",
            "Intensify Death",
            "Focus Death",
        },
        ['FleshBuff'] = {
            "Flesh to Toxin",  -- Level 119
            "Flesh to Venom",  -- Level 109
            "Flesh to Poison", -- Level 99
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
        { --Summon pet even when buffs are off on emu
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
            name = 'Scent',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoScentDebuff') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Casting.OkayToDebuff()
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
                    not Casting.IAmFeigning()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and not Casting.IAmFeigning()
            end,
        },
        {
            name = 'DPS(MobHighHP)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Targeting.MobNotLowHP(Targeting.GetAutoTarget())
            end,
        },
        {
            name = 'DPS(MobLowHP)',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Targeting.MobHasLowHP(Targeting.GetAutoTarget())
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
                    return Config:GetSetting('DoLich') and Casting.SelfBuffCheck(spell) and
                        (not Config:GetSetting('DoUnity') or not Casting.AAReady("Mortifier's Unity")) and
                        mq.TLO.Me.PctHPs() > Config:GetSetting('StopLichHP') and mq.TLO.Me.PctMana() < Config:GetSetting('StartLichMana')
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
                end,
            },
        },
        ['Emergency']       = {
            {
                name = "Death's Effigy",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('AggroFeign') then return false end
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
                name = "Summon Companion",
                type = "AA",
                cond = function(self, aaName, target)
                    if mq.TLO.Me.Pet.ID() == 0 then return false end
                    local pet = mq.TLO.Me.Pet
                    return not pet.Combat() and (pet.Distance3D() or 0) > 200
                end,
            },
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
                    return not Casting.IHaveBuff(spell.Name() .. " Recourse") and
                        (mq.TLO.Target.PctMana() or -1) > 0 and mq.TLO.Group.LowMana(40)() > 2
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
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell, target)
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
            },
            {
                name = "Funeral Pyre",
                type = "AA",
            },
            {
                name = "Hand of Death",
                type = "AA",
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
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Swarm of Decay",
                type = "AA",
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

        DoRez = function(self, corpseId)
            if Config:GetSetting('DoBattleRez') or mq.TLO.Me.CombatState():lower() ~= "combat" then
                if Casting.AAReady("Convergence") and Casting.ReagentCheck(mq.TLO.Me.AltAbility("Convergence").Spell) then
                    return Casting.OkayToRez(corpseId) and Casting.UseAA("Convergence", corpseId, true, 1)
                end
            end
        end,
    },
    ['SpellList']       = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "PoisonNuke1", cond = function(self) return not Core.GetResolvedActionMapItem('PoisonNuke2') end, },
                { name = "PoisonNuke2", },
                { name = "FireNuke", },
                { name = "Lifetap",     cond = function(self) return Config:GetSetting('DoLifetap') end, },
                { name = "CharmSpell",  cond = function(self) return Config:GetSetting('CharmOn') end, },
                { name = "SnareDot",    cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Enchroaching Darkness") end, },
                { name = "ScentDebuff", cond = function(self) return Config:GetSetting('DoScentDebuff') and not Casting.CanUseAA("Scent of Thule") end, },
                { name = "LichSpell",   cond = function(self) return not Config:GetSetting('DoUnity') end, },
                { name = "SwarmPet", },
                { name = "DurationTap", cond = function(self) return Config:GetSetting('DoDurationTap') end, },
                { name = "DreadDot",    cond = function(self) return Config:GetSetting('DoDreadDot') > 1 end, },
                { name = "VenomDot",    cond = function(self) return Config:GetSetting('DoVenomDot') > 1 end, },
                { name = "HorrorDot",   cond = function(self) return Config:GetSetting('DoHorrorDot') > 1 end, },
                { name = "ComboDot",    cond = function(self) return Config:GetSetting('DoComboDot') end, },
                { name = "GroupLeech",  cond = function(self) return Config:GetSetting('DoGroupLeech') end, },
                { name = "DichoDot",    cond = function(self) return Config:GetSetting('DoDichoDot') end, },
                { name = "SearingDot",  cond = function(self) return Config:GetSetting('DoSearingDot') end, },
                { name = "MoriDot",     cond = function(self) return Config:GetSetting('DoMoriDot') end, },
                { name = "WoundDot",    cond = function(self) return Config:GetSetting('DoWoundDot') end, },
                { name = "DecayDot",    cond = function(self) return Config:GetSetting('DoDecayDot') end, },
                { name = "GripDot",     cond = function(self) return Config:GetSetting('DoGripDot') end, },
                { name = "HazeDot",     cond = function(self) return Config:GetSetting('DoHazeDot') end, },
                { name = "DreadDot2",   cond = function(self) return Config:GetSetting('DoDreadDot') > 2 end, },
                { name = "VenomDot2",   cond = function(self) return Config:GetSetting('DoVenomDot') > 2 end, },
                { name = "HorrorDot2",  cond = function(self) return Config:GetSetting('DoHorrorDot') > 2 end, },
                { name = "ManaDrain", },
                { name = "FleshBuff",   cond = function(self) return not Config:GetSetting('DoUnity') or not Casting.CanUseAA("Mortifier's Unity") end, },
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
            Default = 2,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
        },
        ['BattleRez']         = {
            DisplayName = "Battle Rez",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Rez",
            Tooltip = "Do Rezes during combat.",
            RequiresLoadoutChange = true,
            Default = true,
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
            Tooltip = "Use your Feign AA when you have aggro at low health or aggro on a mob detected as a 'named' by RGMercs (see Named tab)..",
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
            Tooltip = "Use your Group Leech dot line.",
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
