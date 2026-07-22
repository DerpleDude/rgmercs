local mq           = require('mq')
local Set          = require('mq.set')
local Casting      = require("utils.casting")
local Combat       = require("utils.combat")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require('utils.globals')
local ItemManager  = require("utils.item_manager")
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")
local Ui           = require("utils.ui")

local _ClassConfig = {
    _version              = "2.0 - Live",
    _author               = "Algar",
    ['ModeChecks']        = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
        IsHealing = function() return true end,
        IsCuring  = function() return Config:GetSetting('DoCures') end,
        IsRezing  = function()
            return (Core.GetResolvedActionMapItem('RezSpell') and Targeting.GetXTHaterCount() == 0) or
                (Casting.CanUseAA("Gift of Resurrection") and Config:GetSetting('DoBattleRez'))
        end,
    },
    ['Rez']               = {
        ['Combat'] = {
            { type = "AA", name = "Gift of Resurrection", },
        },
        ['Downtime'] = {
            { type = "AA", name = "Gift of Resurrection", },
            {
                type = "Spell",
                name = "RezSpell",
                cond = function(self, spell, target)
                    return Casting.DowntimeRezOkay()
                        and not Casting.CanUseAA('Gift of Resurrection')
                end,
            },
        },
    },
    ['Modes']             = {
        'Tank',
        'DPS',
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
            { type = "AA", name = "Purification", selfOnly = true, },
        },
        ['Poison'] = {
            { type = "Spell", name = "SplashHeal", load_cond = function(self) return self.Helpers.UseSplashHealCure(self) end, },
            { type = "Spell", name = "PurityCure", },
        },
        ['Disease'] = {
            { type = "Spell", name = "SplashHeal", load_cond = function(self) return self.Helpers.UseSplashHealCure(self) end, },
            { type = "Spell", name = "PurityCure", },
        },
        ['Curse'] = {
            { type = "Spell", name = "SplashHeal", load_cond = function(self) return self.Helpers.UseSplashHealCure(self) end, },
            { type = "Spell", name = "PurityCure", },
        },
        ['Corruption'] = {
            { type = "Spell", name = "SplashHeal",  load_cond = function(self) return self.Helpers.UseSplashHealCure(self) end, },
            { type = "Spell", name = "CureCorrupt", },
        },
    },
    ['Themes']            = {
        ['Tank'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.15, g = 0.02, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.15, g = 0.02, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.40, g = 0.05, b = 0.50, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.25, g = 0.03, b = 0.32, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.40, g = 0.05, b = 0.50, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.15, g = 0.02, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.75, g = 0.20, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.75, g = 0.20, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
        },
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.12, g = 0.02, b = 0.16, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.12, g = 0.02, b = 0.16, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.30, g = 0.05, b = 0.40, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.20, g = 0.03, b = 0.26, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.30, g = 0.05, b = 0.40, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.12, g = 0.02, b = 0.16, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.75, g = 0.20, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.75, g = 0.20, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Nightbane, Sword of the Valiant",
            "Redemption",
        },
    },
    ['AbilitySets']       = {
        ['CrushTimer6'] = {
            "Crush of Eminence",     -- Level 129
            "Crush of the Heroic",   -- Level 124
            "Crush of the Umbra",    -- Level 120
            "Crush of Restless Ice", -- Level 115
            "Crush of E'Ci",         -- Level 110
            "Crush of Povar",        -- Level 105
            "Crush of Tarew",        -- Level 100
            "Crush of Tides",        -- Level 95
            "Crush of Repentance",   -- Level 90
            "Crush of Compunction",  -- Level 85
        },
        ['CrushTimer5'] = {
            "Crush of the Crying Seas X", -- Level 127
            "Crush of the Wayunder",      -- Level 122
            "Crush of the Twilight Sea",  -- Level 117
            "Crush of the Grotto",        -- Level 112
            "Crush of the Timorous Deep", -- Level 107
            "Crush of the Darkened Sea",  -- Level 102
            "Crush of the Iceclad",       -- Level 97
            "Crush of Oseka",             -- Level 92
            "Crush of Marr",              -- Level 87
            "Crush of the Crying Seas",   -- Level 82
        },
        ['TwinHealNuke'] = {
            "Brilliant Expurgation",  -- Level 130
            "Brilliant Denouncement", -- Level 125
            "Brilliant Acquittal",    -- Level 120
            "Brilliant Exculpation",  -- Level 115
            "Brilliant Exoneration",  -- Level 110
            "Brilliant Vindication",  -- Level 105
            "Glorious Expurgation",   -- Level 100
            "Glorious Exculpation",   -- Level 95
            "Glorious Exoneration",   -- Level 90
            "Glorious Vindication",   -- Level 85
        },
        ['TempHP'] = {
            "Unyielding Stance", -- Level 129
            "Unwavering Stance", -- Level 124
            "Adamant Stance",    -- Level 119
            "Stormwall Stance",  -- Level 114
            "Defiant Stance",    -- Level 109
            "Staunch Stance",    -- Level 104
            "Steadfast Stance",  -- Level 99
            "Stoic Stance",      -- Level 94
            "Stubborn Stance",   -- Level 89
            "Steely Stance",     -- Level 84
        },
        ['Preservation'] = {
            "Preservation of Quellious",    -- Level 130
            "Preservation of the Fern",     -- Level 125
            "Preservation of the Basilica", -- Level 120
            "Preservation of the Grotto",   -- Level 115
            "Preservation of Rodcet",       -- Level 110
            "Preservation of the Iceclad",  -- Level 100
            "Preservation of Oseka",        -- Level 95
            "Preservation of Marr",         -- Level 90
            "Preservation of Tunare",       -- Level 85
            "Sustenance of Tunare",         -- Level 80
            "Ward of Tunare",               -- Level 70
        },
        ['HealNuke'] = {
            "Denouncement IX", -- Level 127
            "Chastise",        -- Level 122
            "Upbraid",         -- Level 117
            "Remonstrate",     -- Level 112
            "Censure",         -- Level 107
            "Admonish",        -- Level 102
            "Ostracize",       -- Level 97
            "Reprimand",       -- Level 92
            "Denouncement",    -- Level 87
        },
        ['BlessingProc'] = {
            "Paradoxical Blessing", -- Level 123
            "Penumbral Blessing",   -- Level 118
            "Confluent Blessing",   -- Level 113
            "Concordant Blessing",  -- Level 108
            "Harmonious Blessing",  -- Level 103
        },
        ['DebuffNuke'] = {
            "Committal",              -- Level 126
            "Revelation",             -- Level 121
            "Hymnal",                 -- Level 116
            "Requiem",                -- Level 111
            "Remembrance",            -- Level 106
            "Consecration",           -- Level 101
            "Laudation",              -- Level 96
            "Paean",                  -- Level 91
            "Elegy",                  -- Level 86
            "Eulogy",                 -- Level 81
            "Benediction",            -- Level 76
            "Burial Rites",           -- Level 71, - Timer 7
            "Last Rites",             -- Level 68, - Timer 7
        },
        ['SteelProc'] = {             --Proc Heal ToT
            "Rejuvenating Steel VII", -- Level 129
            "Restoring Steel",        -- Level 124
            "Regenerating Steel",     -- Level 119
            "Renewing Steel",         -- Level 114
            "Revitalizating Steel",   -- Level 109
            "Reinvigorating Steel",   -- Level 99
            "Rejuvenating Steel",     -- Level 94
        },
        ['FuryProc'] = {
            "Eminent Fury",   -- Level 130
            "Avowed Fury",    -- Level 125
            "Wrathful Fury",  -- Level 120
            "Sincere Fury",   -- Level 115
            "Merciful Fury",  -- Level 110
            "Ardent Fury",    -- Level 105
            "Reverent Fury",  -- Level 100
            "Zealous Fury",   -- Level 95
            "Earnest Fury",   -- Level 90
            "Devout Fury",    -- Level 85
            "Righteous Fury", -- Level 80, 268pt --For simplicity of coding and conflict prevention, once fury is rolled into DPU at 80, we will no longer use the undead proc.
            "Pious Fury",     -- Level 68, 190pt
            "Holy Order",     -- Level 65, 180pt
            "Pious Might",    -- Level 63, 150pt
            "Divine Might",   -- Level 45, 65pt
        },
        ['UndeadProc'] = {
            --- Undead Proc Strike : does not stack with Fury Proc, will be used until Fury is available even if setting not enabled.
            "Silvered Fury",      -- Level 67, 390pt
            "Ward of Nife",       -- Level 62, 300pt
            "Instrument of Nife", -- Level 26, 243pt
        },
        ['Aurora'] = {
            "Aurora of Sunlight XI",  -- Level 130
            "Aurora of Realizing",    -- Level 125
            "Aurora of Dawning",      -- Level 120
            "Aurora of Wakening",     -- Level 115
            "Aurora of Morninglight", -- Level 110
            "Aurora of Dayspring",    -- Level 105
            "Aurora of Sunrise",      -- Level 100
            "Aurora of Splendor",     -- Level 95
            "Aurora of Daybreak",     -- Level 90
            "Aurora of Dawnlight",    -- Level 85
        },
        ['StunTimer5'] = {
            "Force of Akera XV",          -- Level 130
            "Force of the Wayunder",      -- Level 125
            "Force of the Umbra",         -- Level 120
            "Force of the Grotto",        -- Level 115
            "Force of the Timorous Deep", -- Level 110
            "Force of the Darkened Sea",  -- Level 105
            "Force of the Iceclad",       -- Level 100
            "Force of Oseka",             -- Level 95
            "Force of Marr",              -- Level 90
            "Force of the Crying Seas",   -- Level 85
            "Force of Timorous",          -- Level 80
            "Force of Prexus",            -- Level 75
            "Ancient: Force of Jeron",    -- Level 70
            "Ancient: Force of Chaos",    -- Level 65
            "Force of Akera",             -- Level 53
            "Stun",                       -- Level 28
            "Desist",                     -- Level 13, - Not Timer 5, use for TLP Low Level Stun
        },
        ['StunTimer4'] = {
            "Eminent Force",   -- Level 126
            "Avowed Force",    -- Level 121
            "Pious Force",     -- Level 116
            "Sincere Force",   -- Level 111
            "Merciful Force",  -- Level 106
            "Ardent Force",    -- Level 101
            "Reverent Force",  -- Level 96
            "Zealous Force",   -- Level 91
            "Earnest Force",   -- Level 86
            "Devout Force",    -- Level 81
            "Solemn Force",    -- Level 76
            "Sacred Force",    -- Level 71
            "Force of Piety",  -- Level 66
            "Force of Akilae", -- Level 62
            "Cease",           -- Level 7, - Not Timer 4, use for TLP Low Level Stun
        },
        ['HealStun'] = {
            "Force of Eminence",       -- Level 129
            "Force of the Avowed",     -- Level 124
            "Force of Generosity",     -- Level 119
            "Force of Sincerity",      -- Level 114
            "Force of Mercy",          -- Level 109
            "Force of Ardency",        -- Level 104
            "Force of Reverence",      -- Level 99
        },
        ['HealWard'] = {               -- Heal ToT, Ward on Self
            "Protective Confession X", -- Level 130
            "Protective Acceptance",   -- Level 125
            "Protective Revelation",   -- Level 120
            "Protective Consecration", -- Level 115
            "55488",                   -- Level 110, Protective Devotion - deconflicts duplicate at Level 90
            "Protective Proclamation", -- Level 105
            "Protective Allegiance",   -- Level 100
            "Protective Dedication",   -- Level 95
            "25390",                   -- Level 90, Protective Devotion - deconflicts duplicate at Level 110
            "Protective Confession",   -- Level 85
        },
        ['Aego'] = {
            "Hand of Austerity XVII",        -- Level 127, - Group
            "Hand of the Fernshade Keeper",  -- Level 125, - Group
            "Fernshade Keeper",              -- Level 122
            "Hand of the Dreaming Keeper",   -- Level 120, - Group
            "Shadewell Keeper",              -- Level 117
            "Hand of the Stormwall Keeper",  -- Level 115, - Group
            "Stormwall Keeper",              -- Level 112
            "Hand of the Ashbound Keeper",   -- Level 110, - Group
            "Ashbound Keeper",               -- Level 107
            "Hand of the Stormbound Keeper", -- Level 105, - Group
            "Stormbound Keeper",             -- Level 102
            "Hand of the Pledged Keeper",    -- Level 100, - Group
            "Pledged Keeper",                -- Level 97
            "Hand of the Avowed Keeper",     -- Level 95, - Group
            "Avowed Keeper",                 -- Level 92
            "Oathbound Keeper",              -- Level 90
            "Sworn Keeper",                  -- Level 85
            "Oathbound Protector",           -- Level 80
            "Sworn Protector",               -- Level 75
            "Affirmation",                   -- Level 70
            "Guidance",                      -- Level 65
            "Blessing of Austerity",         -- Level 58, - Group
            "Austerity",                     -- Level 55
        },
        ['Brells'] = {
            "Brell's Mountainous Barrier XVI", -- Level 129
            "Brell's Unbreakable Palisade",    -- Level 124
            "Brell's Tenacious Barrier",       -- Level 119
            "Brell's Blessed Barrier",         -- Level 114
            "Brell's Blessed Bastion",         -- Level 109
            "Brell's Stalwart Bulwark",        -- Level 104
            "Brell's Steadfast Bulwark",       -- Level 99
            "Brell's Adamantine Armor",        -- Level 94
            "Brell's Tellurian Rampart",       -- Level 89
            "Brell's Loamy Ward",              -- Level 84
            "Brell's Earthen Aegis",           -- Level 79
            "Brell's Stony Guard",             -- Level 74
            "Brell's Brawny Bulwark",          -- Level 70
            "Brell's Stalwart Shield",         -- Level 65
            "Brell's Mountainous Barrier",     -- Level 60
            "Brell's Steadfast Aegis",         -- Level 49
        },
        ['SplashHeal'] = {
            "Splash of Eminence",       -- Level 128
            "Splash of Heroism",        -- Level 123
            "Splash of Repentance",     -- Level 118
            "Splash of Exaltation",     -- Level 113
            "Splash of Depuration",     -- Level 108
            "Splash of Atonement",      -- Level 103
            "Splash of Cleansing",      -- Level 98
            "Splash of Purification",   -- Level 93
            "Splash of Sanctification", -- Level 83
        },
        ['HealTaunt'] = {
            "Valiant Defiance",          -- Level 124
            "Valiant Disruption",        -- Level 119
            "Valiant Deterrence",        -- Level 115
            "Valiant Diversion",         -- Level 110
            "Valiant Defense",           -- Level 105
            "Valiant Deflection",        -- Level 98
        },
        ['Affirmation'] = {              --- Improved Super Taunt - Gets you Aggro for X seconds and reduces other Haters generation.
            "Unquestioned Affirmation",  -- Level 129
            "Unconditional Affirmation", -- Level 124
            "Unrelenting Affirmation",   -- Level 119
            "Unending Affirmation",      -- Level 114
            "Unyielding Affirmation",    -- Level 109
            "Unflinching Affirmation",   -- Level 104
            "Unbroken Affirmation",      -- Level 99
            "Undivided Affirmation",     -- Level 94
        },
        ['WaveHeal'] = {                 -- Group Heal
            "Wave of Inspiration",       -- Level 129
            "Wave of Regret",            -- Level 124
            "Wave of Bereavement",       -- Level 119
            "Wave of Propitiation",      -- Level 114
            "Wave of Expiation",         -- Level 109
            "Wave of Grief",             -- Level 104
            "Wave of Sorrow",            -- Level 99
            "Wave of Contrition",        -- Level 94
            "Wave of Penitence",         -- Level 89
            "Wave of Remitment",         -- Level 84
            "Wave of Absolution",        -- Level 79
            "Wave of Forgiveness",       -- Level 74
            "Wave of Piety",             -- Level 70
            "Wave of Marr",              -- Level 65
            "Wave of Trushar",           -- Level 65
            "Healing Wave of Prexus",    -- Level 58
            "Wave of Healing",           -- Level 55
            "Wave of Life",              -- Level 39
        },
        ['SelfHeal'] = {
            "Penitence IX", -- Level 129
            "Angst",        -- Level 124
            "Culpability",  -- Level 119
            "Propitiation", -- Level 114
            "Grief",        -- Level 104
            "Sorrow",       -- Level 99
            "Contrition",   -- Level 94
            "Penitence",    -- Level 89
        },
        ['ReverseDS'] = {
            "Mark of Sharosh",             -- Level 126
            "Mark of the Forgotten Hero",  -- Level 122
            "Mark of the Eclipsed Cohort", -- Level 119
            "Mark of the Jade Cohort",     -- Level 114
            "Mark of the Commander",       -- Level 104
            "Mark of the Exemplar",        -- Level 99
            "Mark of the Reverent",        -- Level 94
            "Mark of the Defender",        -- Level 89
            "Mark of the Pure",            -- Level 86
            "Mark of the Pious",           -- Level 84
            "Mark of the Crusader",        -- Level 81
            "Mark of the Saint",           -- Level 79
        },
        -- ['Cleansing'] = {           -- ST HoT
        --     "Avowed Cleansing",     -- Level 123
        --     "Forthright Cleansing", -- Level 118
        --     "Sincere Cleansing",    -- Level 113
        --     "Merciful Cleansing",   -- Level 108
        --     "Ardent Cleansing",     -- Level 103
        --     "Reverent Cleansing",   -- Level 98
        --     "Zealous Cleansing",    -- Level 93
        --     "Earnest Cleansing",    -- Level 88
        --     "Devout Cleansing",     -- Level 83
        --     "Solemn Cleansing",     -- Level 78
        --     "Sacred Cleansing",     -- Level 73
        --     "Pious Cleansing",      -- Level 69
        --     "Supernal Cleansing",   -- Level 64
        --     "Celestial Cleansing",  -- Level 59
        --     "Ethereal Cleansing",   -- Level 44
        -- },
        ['BurstHeal'] = {            -- Smart Heal, Target or ToT
            "Burst of Sunlight XII", -- Level 128
            "Burst of Sunspring",    -- Level 123
            "Burst of Dawnbreak",    -- Level 118
            "Burst of Wakening",     -- Level 113
            "Burst of Morninglight", -- Level 108
            "Burst of Dayspring",    -- Level 103
            "Burst of Sunrise",      -- Level 98
            "Burst of Splendor",     -- Level 93
            "Burst of Daybreak",     -- Level 88
            "Burst of Dawnlight",    -- Level 83
            "Burst of Morrow",       -- Level 78
            "Burst of Sunlight",     -- Level 73
        },
        ['ArmorSelfBuff'] = {
            "Armor of Unyielding Faith",  -- Level 128
            "Armor of Heroic Faith",      -- Level 123
            "Armor of Unyielding Grace",  -- Level 118
            "Armor of Steadfast Grace",   -- Level 113
            "Armor of Steadfast Faith",   -- Level 108
            "Armor of Formidable Spirit", -- Level 103
            "Armor of Formidable Grace",  -- Level 98
            "Armor of Formidable Faith",  -- Level 93
            "Armor of Implacable Faith",  -- Level 88
            "Armor of Unwavering Faith",  -- Level 83
            "Armor of Inexorable Faith",  -- Level 78
            "Armor of Unrelenting Faith", -- Level 73
            "Armor of the Champion",      -- Level 69
            "Aura of the Crusader",       -- Level 64
        },
        ['RighteousStrike'] = {
            "Righteous Indignation VIII", -- Level 126
            "Righteous Disdain",          -- Level 121
            "Righteous Censure",          -- Level 118
            "Righteous Antipathy",        -- Level 113
            "Righteous Antipathy",        -- Level 113
            "Righteous Condemnation",     -- Level 108
            "Righteous Umbrage",          -- Level 98
            "Righteous Vexation",         -- Level 93
            "Righteous Indignation",      -- Level 88
            "Righteous Fury",             -- Level 80
        },
        ['Symbol'] = {
            "Symbol of Thormir",              -- Level 122
            "Symbol of Liako",                -- Level 117
            "Symbol of Sevalak",              -- Level 112
            "Symbol of Sevalak",              -- Level 112
            "Symbol of Teralov",              -- Level 107
            "Symbol of Niparson",             -- Level 102
            "Symbol of Burim",                -- Level 97
            "Symbol of Erillion",             -- Level 92
            "Symbol of Jyleel",               -- Level 87
            "Symbol of Jeneca",               -- Level 82
            "Symbol of Bthur",                -- Level 77
            "Symbol of Jeron",                -- Level 67
            "Symbol of Marzin",               -- Level 63
            "Symbol of Naltron",              -- Level 58
            "Symbol of Pinzarn",              -- Level 46
            "Symbol of Ryltan",               -- Level 33
            "Symbol of Transal",              -- Level 24
        },
        ['StunTimer6'] = {                    -- Timer 6, less damage than timer 6 crush, but inlcudes stun. Has Push.
            "Lesson of Penitence XV",         -- Level 127
            "Lesson of Remembrance",          -- Level 122
            "Lesson of Guilt",                -- Level 117
            "Lesson of Propitiation",         -- Level 112
            "Lesson of Expiation",            -- Level 107
            "Lesson of Grief",                -- Level 102
            "Lesson of Sorrow",               -- Level 97
            "Lesson of Remorse",              -- Level 92
            "Lesson of Repentance",           -- Level 87
            "Lesson of Compunction",          -- Level 82
            "Lesson of Contrition",           -- Level 77
            "Lesson of Penitence",            -- Level 72
            "Serene Command",                 -- Level 68
            "Quellious' Word of Serenity",    -- Level 64
            "Quellious' Word of Tranquility", -- Level 54
        },
        ['Audacity'] = {                      -- Magic Resist debuff, Hate over time
            "Impassioned Audacity",           -- Level 127
            "Fanatical Audacity",             -- Level 122
            "Ardent Audacity",                -- Level 117
            "Fervent Audacity",               -- Level 112
            "Sanctimonious Audacity",         -- Level 107
            "Devout Audacity",                -- Level 97
            "Righteous Audacity",             -- Level 92
        },
        ['LightHeal'] = {                     --ToT Heal
            "Eminent Light",                  -- Level 127
            "Avowed Light",                   -- Level 122
            "Raptured Light",                 -- Level 117
            "Sincere Light",                  -- Level 112
            "Merciful Light",                 -- Level 107
            "Blessed Light",                  -- Level 102
            "Dazzling Light",                 -- Level 97
            "Brilliant Light",                -- Level 92
            "Joyous Light",                   -- Level 87
            "Shining Light",                  -- Level 82
            "Radiant Light",                  -- Level 77
            "Gleaming Light",                 -- Level 72
            "Light of Piety",                 -- Level 68
            "Light of Order",                 -- Level 65
            "Light of Nife",                  -- Level 63
            "Light of Life",                  -- Level 52
        },
        -- ['Pacify'] = {
        --     "Assuring Words",  -- Level 121
        --     "Tranquil Words",  -- Level 116
        --     "Placating Words", -- Level 111
        --     "55347",           -- Level 106, Soothe - deconflicts duplicate at Level 25
        --     "Dulcify",         -- Level 101
        --     "Reconcile",       -- Level 96
        --     "Mollify",         -- Level 91
        --     "Propitiate",      -- Level 86
        --     "Pacify",          -- Level 49
        --     "Calm",            -- Level 43
        --     "501",             -- Level 25, Soothe - deconflicts duplicate at Level 106
        --     "Lull",            -- Level 10
        -- },
        ['TouchHeal'] = {
            "Eminent Touch",    -- Level 126
            "Avowed Touch",     -- Level 121
            "Soothing Touch",   -- Level 116
            "Sincere Touch",    -- Level 111
            "Merciful Touch",   -- Level 106
            "Ardent Touch",     -- Level 101
            "Reverent Touch",   -- Level 96
            "Zealous Touch",    -- Level 91
            "Earnest Touch",    -- Level 86
            "Devout Touch",     -- Level 81
            "Solemn Touch",     -- Level 76
            "Sacred Touch",     -- Level 71
            "Touch of Piety",   -- Level 66
            "Touch of Nife",    -- Level 61
            "Superior Healing", -- Level 48
            "Healing",          -- Level 27
            "Light Healing",    -- Level 12
            "Minor Healing",    -- Level 6
            "Salve",            -- Level 1
        },
        ['Dicho'] = {
            --- Dissident Stun
            "Reciprocal Force",         -- Level 121
            "Ecliptic Force",           -- Level 116
            "Composite Force",          -- Level 111
            "Dissident Force",          -- Level 106
            "Dichotomic Force",         -- Level 101
        },
        ['PurityCure'] = {              --- Purity Cure Poison/Diease Cure Half Power to curse
            "Mastery: Balanced Purity", -- Level 126
            "Balanced Purity",          -- Level 116
            "Merciful Purity",          -- Level 106
            "Ardent Purity",            -- Level 101
            "Reverent Purity",          -- Level 96
            "Zealous Purity",           -- Level 91
            "Earnest Purity",           -- Level 86
            "Devoted Purity",           -- Level 81
        },
        -- ['CureCurse'] = {
        --     "Remove Greater Curse", -- Level 60
        --     "Eradicate Curse",      -- Level 60
        --     "Remove Curse",         -- Level 45
        --     "Remove Lesser Curse",  -- Level 34
        --     "Remove Minor Curse",   -- Level 19
        -- },
        ['CureCorrupt'] = {
            "Mastery: Consecrate",      -- Level 126
            "Consecrate",               -- Level 116
            "Sanctify",                 -- Level 106
            "Depurate",                 -- Level 101
            "Expurgate",                -- Level 96
            "Purify",                   -- Level 91
            "Cleanse",                  -- Level 86
            "Cure Corruption",          -- Level 65
        },
        ['ForHonor'] = {                --- Challenge Taunt Over time Debuff
            "Duel for Honor",           -- Level 127
            "Petition for Honor",       -- Level 122
            "Parlay for Honor",         -- Level 117
            "Protest for Honor",        -- Level 112
            "Refute for Honor",         -- Level 107
            "Impose for Honor",         -- Level 102
            "Demand for Honor",         -- Level 97
            "Provocation for Honor",    -- Level 92
            "Confrontation for Honor",  -- Level 87
            "Charge for Honor",         -- Level 82
            "Trial For Honor",          -- Level 77
            "Challenge for Honor",      -- Level 72
        },
        ['Piety'] = {                   -- Spell Resist Buff
            "Silent Piety",             -- Level 69
        },
        ['Remorse'] = {                 -- Killshot buff
            "Penitence for the Fallen", -- Level 120
            "Remorse for the Fallen",   -- Level 75
        },
        ['HealAura'] = {
            "Blessed Aura", -- Level 70
            "Holy Aura",    -- Level 55
        },
        ['UndeadNuke'] = {
            "Doctrine of Revocation",  -- Level 128
            "Doctrine of Repudiation", -- Level 121
            "Doctrine of Annulment",   -- Level 116
            "Doctrine of Abolishment", -- Level 111
            "Doctrine of Exculpation", -- Level 106
            "Doctrine of Rescission",  -- Level 101
            "Doctrine of Abrogation",  -- Level 96
            "Abrogate the Undead",     -- Level 96, - Res Debuff / Extra Damage
            "Abolish the Undead",      -- Level 91, - Res Debuff / Extra Damage
            "Annihilate the Undead",   -- Level 86, - Res Debuff / Extra Damage
            -- "Wraithguard's Vengeance", -- Level 75, - Unobtainable?
            "Spurn Undead",            -- Level 67, - Timer 7
            "Deny Undead",             -- Level 62, - Timer 7
            "Expel Undead",            -- Level 54
            "Dismiss Undead",          -- Level 46
            "Expulse Undead",          -- Level 30
            "Ward Undead",             -- Level 14
        },
        ['AllianceNuke'] = {
            "Aureate Covariance",  -- Level 125
            "Stormwall Coalition", -- Level 114
            "Holy Alliance",       -- Level 104
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
        ['MeleeMit'] = {
            "Impede",    -- Level 128
            "Gird",      -- Level 123
            "Repudiate", -- Level 118
            "Thwart",    -- Level 113
            "Spurn",     -- Level 108
            "Repel",     -- Level 103
            "Reprove",   -- Level 98
            "Renounce",  -- Level 93
            "Defy",      -- Level 88
            -- "Withstand", -- Level 83
        },
        ['ArmorDisc'] = {
            --- Armor Timer 11
            "Armor of Eminence",       -- Level 128
            "Armor of Avowal",         -- Level 123
            "Armor of the Forthright", -- Level 118
            "Armor of Sincerity",      -- Level 113
            "Armor of Mercy",          -- Level 108
            "Armor of Ardency",        -- Level 103
            "Armor of Reverence",      -- Level 98
            "Armor of Zeal",           -- Level 93
            "Armor of Courage",        -- Level 88
        },
        ['Undeadburn'] = {
            "Holyforge Discipline", -- Level 55
        },
        ['Pureforge'] = {
            "Pureforge Discipline", -- Level 90
        },
        ['Penitent'] = {
            -- Penitent Armor Discipline Timer 11
            "Avowed Penitence",   -- Level 122
            "Fervent Penitence",  -- Level 117
            "Sincere Penitence",  -- Level 112
            "Merciful Penitence", -- Level 107
            "Devout Penitence",   -- Level 102
            "Reverent Penitence", -- Level 97
        },
        ['Mantle'] = {
            "Mantle of Eminence",            -- Level 128
            "Supernal Mantle",               -- Level 118
            "Mantle of the Sapphire Cohort", -- Level 113
            "Kar`Zok Mantle",                -- Level 108
            "Skalber Mantle",                -- Level 103
            "Brightwing Mantle",             -- Level 98
            "Prominent Mantle",              -- Level 93
            "Exalted Mantle",                -- Level 88
            "Honorific Mantle",              -- Level 83
            "Armor of Decorum",              -- Level 78
            "Armor of Righteousness",        -- Level 73
            "Guard of Righteousness",        -- Level 69
            "Guard of Humility",             -- Level 61
            "Guard of Piety",                -- Level 56
        },
        ['Guardian'] = {
            "Holy Guardian Discipline IV", -- Level 127
            "Revered Guardian Discipline", -- Level 117
            "Blessed Guardian Discipline", -- Level 107
            "Holy Guardian Discipline",    -- Level 97
        },
        ['Spellblock'] = {
            "Sanctification Discipline", -- Level 60
        },
        ['Deflection'] = {
            "Deflection Discipline", -- Level 59
        },
        ['ReflexStrike'] = {
            --- Reflexive Strike Heal
            "Reflexive Resolution",    -- Level 121
            "Reflexive Redemption",    -- Level 111
            "Reflexive Reverence",     -- Level 105
            "Reflexive Righteousness", -- Level 100
        },
        ['RezSpell'] = {
            "Resurrection",   -- Level 59
            "Restoration",    -- Level 55
            "Renewal",        -- Level 49
            "Revive",         -- Level 39
            "Reparation",     -- Level 31
            "Reconstitution", -- Level 30
            "Reanimation",    -- Level 22
        },
    },
    ['AASets']            = {
        ['Disruption'] = {
            "Force of Disruption",
            "Divine Stun",
        },
    },
    ['Helpers']           = {
        UseSplashHealCure = function(self)
            return Config:GetSetting('SplashHealAsCure') and Core.GetResolvedActionMapItem('SplashHeal')
        end,
        --determine whether we should overwrite DPU buffs with better single buffs
        SingleBuffCheck = function(self)
            if Casting.CanUseAA("Divine Protector's Unity") and not Config:GetSetting('OverwriteDPUBuffs') then return false end
            return true
        end,
        --function to determine if we have enough mobs in range to use a defensive disc
        DefensiveDiscCheck = function(printDebug)
            local xtCount = mq.TLO.Me.XTarget() or 0
            if xtCount < Config:GetSetting('DiscCount') then return false end
            local haters = Set.new({})
            for i = 1, xtCount do
                local xtarg = mq.TLO.Me.XTarget(i)
                if xtarg and xtarg.ID() > 0 and ((xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater")) and (xtarg.Distance() or 999) <= 30 then
                    if printDebug then
                        Logger.log_verbose("DefensiveDiscCheck(): XT(%d) Counting %s(%d) as a hater in range.", i, xtarg.CleanName() or "None", xtarg.ID())
                    end
                    haters:add(xtarg.ID())
                end
                if #haters:toList() >= Config:GetSetting('DiscCount') then return true end -- no need to keep counting once this threshold has been reached
            end
            return false
        end,
        shieldNeeded = function()
            -- check for exactly 100% to help ensure the mob is targeting us, over 100% can indicate another is still targeted
            return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or mq.TLO.Me.ActiveDisc.Name() == "Deflection Discipline" or
                (mq.TLO.Me.AltAbilityTimer("Shield Flash")() or 0) >= 234000 or
                (Config:GetSetting('NamedShieldLock') and ((Globals.AutoTargetIsNamed and Targeting.GetAutoTargetAggroPct() == 100) or Targeting.TankingXTNamed()))
        end,
    },
    ['HealRotationOrder'] = {
        {
            name = 'GroupHeal',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHeal',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target)
                return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target)
            end,
        },
        {
            name = 'MainHeal',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
    },
    ['HealRotations']     = {
        ['GroupHeal'] = {
            {
                name = "Hand of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "Gift of Life",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "SplashHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('KeepSplashMemmed') end,
            },
            {
                name = "WaveHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') end,
            },
        },
        ['BigHeal'] = {
            {
                name = "Lay on Hands",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.GetTargetPctHPs() < Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "SelfHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSelfHeal') end,
                cond = function(self, spell, target)
                    return self.CombatState == "Combat" and Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Marr's Gift",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Hand of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and (Targeting.TargetIsMyself(target) or Targeting.GetTargetPctHPs(target) < Config:GetSetting('HPCritical'))
                end,
            },
            {
                name = "Gift of Life",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and (Targeting.TargetIsMyself(target) or Targeting.GetTargetPctHPs(target) < Config:GetSetting('HPCritical'))
                end,
            },
            {
                name = "TouchHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoTouchHeal") == 1 end,
            },
        },
        ['MainHeal'] = {
            {
                name = "BurstHeal",
                type = "Spell",
            },
            {
                name = "TouchHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoTouchHeal") == 2 end,
            },
        },
    },
    ['Charm']             = {
        ['Assist'] = {
            { name = "HealTaunt",   type = "Spell", },
            { name = "Audacity",    type = "Spell",   cond = function(self, spell, target) return Casting.DetSpellCheck(spell, target) end, },
            { name = "Disruption",  type = "AA", },
            { name = "Taunt",       type = "Ability", },
            { name = "CrushTimer5", type = "Spell",   load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end, },
            { name = "CrushTimer6", type = "Spell",   load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end, },
            {
                name = "StunTimer5",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5')
                end,
            },
            { name = "StunTimer4", type = "Spell", load_cond = function(self) return Config:GetSetting('Timer4Choice') end, },
            { name = "StunTimer6", type = "Spell", load_cond = function(self) return Config:GetSetting('Timer6Choice') == 2 end, },
        },
    },
    ['RotationOrder']     = {
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Core.CombatActionsCheck() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Core.CombatActionsCheck()
            end,
        },
        { --Actions to lock down xtarg haters
            name = 'HateTools(AggroTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('TankAggroScan') end,
            targetId = function(self) return Targeting.CheckForAggroTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat"
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'HateTools(AutoTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Targeting.HateToolsNeeded()
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'AEHateTools',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('AETauntAA') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Combat.AETauntCheck(true)
            end,
        },
        { --Dynamic weapon swapping if UseBandolier is toggled
            name = 'Weapon Management',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('UseBandolier') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        { --Defensive actions triggered by low HP
            name = 'EmergencyDefenses',
            state = 1,
            steps = 2, -- help ensure that we cancel visage when needed
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
            end,
        },
        { --Prioritized in their own rotation to help keep HP topped to the desired level, includes emergency abilities
            name = 'ToTHeals',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
            end,
        },
        { --Defensive actions used proactively to prevent emergencies
            name = 'Defenses',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.IHaveAggro(100) and
                    -- we are under our defense start HP
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('DefenseStart') or
                        -- we have met our defense count threshold
                        self.Helpers.DefensiveDiscCheck(true) or
                        -- we are fighting a named and we are tanking it
                        Targeting.TankingXTNamed())
            end,
        },
        {
            name = 'Debuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        { --Non-spell actions that can be used during/between casts
            name = 'CombatWeave',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        { --DPS Spells, includes recourse/gift maintenance
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']         = {
        ['Downtime'] = {
            {
                name = "EndRegen",
                type = "Disc",
                load_cond = function(self) return not Core.GetResolvedActionMapItem("CombatEndRegen") end,
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
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
                name = "HealAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName()))
                end,
            },
            {
                name = "Divine Protector's Unity",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID() or 0) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "ArmorSelfBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "FuryProc",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "UndeadProc",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) --use this always until we have a Fury proc, and optionally after that, up until the point that Fury is rolled into DPU
                    if (mq.TLO.Me.AltAbility("Divine Protector's Unity").Rank() or 0) > 1 or (Core.GetResolvedActionMapItem("FuryProc") and not Config:GetSetting('DoUndeadProc')) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Remorse",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Piety",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.Helpers.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            --You'll notice my use of TotalSeconds, this is to keep as close to 100% uptime as possible on these buffs, rebuffing early to decrease the chance of them falling off in combat
            --I considered creating a function (helper or utils) to govern this as I use it on multiple classes but the difference between buff window/song window/aa/spell etc makes it unwieldy
            -- if using duration checks, dont use SelfBuffCheck() (as it could return false when the effect is still on)
            {
                name = "Preservation",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell) and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 30
                end,
            },
            {
                name = "TempHP",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTempHP') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 45
                end,
            },
            {
                name = "BlessingProc",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 15
                end,
            },
            {
                name = "HealWard",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 15
                end,
            },
            { --Charm Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Charm").Name() or "CharmClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCharmClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "SteelProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSteelProc') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 45
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Brells",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoBrells') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Aego",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AegoSymbol') == 1 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Symbol",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AegoSymbol') == 2 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Marr's Salvation",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSalvation') end,
                cond = function(self, aaName, target)
                    if Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
                post_activate = function(self, aaName, success)
                    -- mq.delay(200, function() return mq.TLO.Me.Buff("Marr's Salvation")() ~= nil end)
                    if success and Core.IsTanking() and mq.TLO.Me.Buff("Marr's Salvation")() then
                        Core.DoCmd("/removebuff \"Marr's Salvation\"")
                    end
                end,
            },
        },
        ['EmergencyDefenses'] = {
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < Config:GetSetting('HPCritical')
                end,
            },
            --Note that on named we may already have a mantle/carapace running already, could make this remove other discs, but meh, Shield Flash still a thing.
            {
                name = "Deflection",
                type = "Disc",
                pre_activate = function(self)
                    if Config:GetSetting('UseBandolier') then
                        Core.SafeCallFunc("Equip Shield", ItemManager.BandolierSwap, "Shield")
                    end
                end,
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') and Casting.NoDiscActive() and
                        (mq.TLO.Me.AltAbilityTimer("Shield Flash")() or 0) < 234000
                end,
            },
            {
                name = "Shield Flash",
                type = "AA",
                pre_activate = function(self)
                    if Config:GetSetting('UseBandolier') then
                        Core.SafeCallFunc("Equip Shield", ItemManager.BandolierSwap, "Shield")
                    end
                end,
                cond = function(self, aaName)
                    return mq.TLO.Me.ActiveDisc.Name() ~= "Deflection Discipline"
                end,
            },
            --Penitent vs Armor is something I will need to do more homework on
            {
                name = "Penitent",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Group Armor of The Inquisitor",
                type = "AA",
                cond = function(self, aaName)
                    return not Casting.IHaveBuff("Armor of the Inquisitor")
                end,
            },
            {
                name = "Armor of the Inquisitor",
                type = "AA",
                cond = function(self, aaName)
                    return not Casting.IHaveBuff("Armor of the Inquisitor")
                end,
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoChestClick') end,
                cond = function(self, itemName, target)
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Mantle",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['HateTools(AggroTarget)'] = {
            {
                name = "HealTaunt",
                type = "Spell",
            },
            {
                name = "Audacity",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "ForHonor",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "Disruption",
                type = "AA",
            },
            {
                name = "Taunt",
                type = "Ability",
            },
            {
                name = "CrushTimer5",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end,
            },
            {
                name = "CrushTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end,
            },
            {
                name = "StunTimer5",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5')
                end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer4Choice') end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 2 end,
            },
        },
        ['HateTools(AutoTarget)'] = {
            {
                name = "Disruption",
                type = "AA",
            },
            {
                name = "HealTaunt",
                type = "Spell",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro()
                end,
            },
            --used when we've lost hatred after it is initially established
            {
                name = "Ageless Enmity",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() < 90 and Targeting.LostAutoTargetAggro()
                end,
            },
            --used to jumpstart hatred on named from the outset and prevent early rips from burns
            {
                name = "Affirmation",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Projection of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and (mq.TLO.Target.SecondaryPctAggro() or 0) > 80
                end,
            },
            {
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro()
                end,
            },
            {
                name = "Audacity",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "ForHonor",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "CrushTimer5",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 60
                end,
            },
            {
                name = "CrushTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 60
                end,
            },
        },
        ['AEHateTools'] = {
            {
                name = "Heroic Leap",
                type = "AA",
                cond = function(self, aaName, target)
                    return not mq.TLO.Me.HeadWet()
                end,
            },
            {
                name = "Beacon of the Righteous",
                type = "AA",
            },
            {
                name = "Hallowed Lodestar",
                type = "AA",
            },
        },
        ['Debuff'] = {
            {
                name = "Audacity",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "ReverseDS",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoReverseDS') < 3 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DoReverseDS') == 2 and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Valorous Rage",
                type = "AA",
            },
            {
                name = "RighteousStrike",
                type = "Disc",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "Spire of Chivalry",
                type = "AA",
            },
            {
                name = "Thunder of Karana",
                type = "AA",
            },
            {
                name = "Hand of Tunare",
                type = "AA",
            },
            {
                name = "Undeadburn",
                type = "Disc",
                load_cond = function(self) return not Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive() and Targeting.TargetBodyIs(target, "Undead")
                end,
            },
            {
                name = "Pureforge",
                type = "Disc",
                load_cond = function(self) return not Core.IsTanking() end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Inquisitor's Judgment",
                type = "AA",
            },
            {
                name = "Preservation",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "BlessingProc",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SteelProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSteelProc') end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Marr's Gift",
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
        },
        ['Defenses'] = {
            {
                name = "MeleeMit",
                type = "Disc",
                cond = function(self, discSpell)
                    return not ((discSpell.Level() or 0) < 108 and not Casting.NoDiscActive())
                end,
            },
            {
                name = "ArmorDisc",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Mantle",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Guardian",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
        },
        ['ToTHeals'] = {
            {
                name = "Dicho",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDicho') end,
                cond = function(self, spell, target)
                    return Targeting.GroupHealsNeeded() or Targeting.BigHealsNeeded(mq.TLO.Me)
                end,
            },
            {
                name = "BurstHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MainHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
            {
                name = "HealTaunt",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
            },
            {
                name = "HealNuke",
                type = "Spell",
            },
            {
                name = "LightHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoLightHeal") end,
            },
        },
        ['CombatWeave'] = {
            { --Used if the group could benefit from the heal
                name = "ReflexStrike",
                type = "Disc",
                cond = function(self, discSpell)
                    return Targeting.GroupHealsNeeded()
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
                name = "Vanquish the Fallen",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead")
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Core.ShieldEquipped() or Casting.CanUseAA("Improved Bash")
                end,
            },
            {
                name = "Slam",
                type = "Ability",
            },
        },
        ['Combat'] = {
            {
                name = "ForHonor",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "HealStun",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MainHealsNeeded(mq.TLO.Me) or
                        (Core.IsTanking() and spell.RankName.Stacks() and (mq.TLO.Me.Song(spell.Trigger(1).Name).Duration.TotalSeconds() or 0) < 12)
                end,
            },
            {
                name = "HealWard",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTwinHealNuke') end,
            },
            {
                name = "Disruptive Persecution",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.HaveManaToNuke()
                end,
            },
            {
                name = "CrushTimer5",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end,
            },
            {
                name = "CrushTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end,
            },
            {
                name = "StunTimer5",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5')
                end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer4Choice') end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 2 end,
            },
            {
                name = "Disruption",
                type = "AA",
                load_cond = function(self) return Core.IsTanking() end,
            },
        },
        ['Weapon Management'] = {
            {
                name = "Equip Shield",
                type = "CustomFunc",
                cond = function(self)
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return self.Helpers.shieldNeeded()
                end,
                custom_func = function(self)
                    ItemManager.BandolierSwap("Shield")
                    return true
                end,
            },
            {
                name = "Equip 2Hand",
                type = "CustomFunc",
                cond = function(self)
                    if mq.TLO.Me.Bandolier("2Hand").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('Equip2Hand') and not self.Helpers.shieldNeeded()
                end,
                custom_func = function(self)
                    ItemManager.BandolierSwap("2Hand")
                    return true
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "TouchHeal",   cond = function(self) return Config:GetSetting('DoTouchHeal') < 3 end, },
                { name = "LightHeal",   cond = function(self) return Config:GetSetting('DoLightHeal') end, },
                { name = "BurstHeal", },
                { name = "SelfHeal",    cond = function(self) return Config:GetSetting('DoSelfHeal') end, },
                { name = "SplashHeal",  cond = function(self) return Config:GetSetting('KeepSplashMemmed') end, },
                { name = "WaveHeal",    cond = function(self) return Config:GetSetting('DoWaveHeal') end, },
                { name = "HealTaunt",   cond = function(self) return Core.IsTanking() end, },
                { name = "Audacity",    cond = function(self) return Core.IsTanking() end, },
                { name = "ForHonor",    cond = function(self) return Core.IsTanking() end, },
                { name = "StunTimer4",  cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer4Choice') end, },
                { name = "CrushTimer5", cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer5Choice') == 1 end, },
                {
                    name = "StunTimer5",
                    cond = function(self)
                        return Core.IsTanking() and
                            (Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5'))
                    end,
                },
                { name = "CrushTimer6",  cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer6Choice') == 1 end, },
                { name = "StunTimer6",   cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer6Choice') == 2 end, },
                { name = "Preservation", cond = function(self) return Core.IsTanking() end, },
                { name = "TempHP",       cond = function(self) return Config:GetSetting('DoTempHP') end, },
                { name = "SteelProc",    cond = function(self) return Config:GetSetting('DoSteelProc') end, },
                { name = "HealStun", },
                { name = "HealNuke", },
                { name = "Dicho",        cond = function(self) return Config:GetSetting('DoDicho') end, },
                { name = "TwinHealNuke", cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "ReverseDS",    cond = function(self) return Config:GetSetting('DoReverseDS') < 3 end, },
                { name = "HealWard",     cond = function(self) return Core.IsTanking() end, },
                { name = "PurityCure",   cond = function(self) return Config:GetSetting('KeepPurityMemmed') end, },
                { name = "CureCorrupt",  cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
                { name = "BlessingProc", },
            },
        },
    },
    ['PullAbilities']     = {
        {
            id = 'StunTimer4',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('StunTimer4')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('StunTimer4')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('StunTimer4')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Audacity',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Audacity').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Audacity').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('Audacity')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'ForHonor',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('ForHonor').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('ForHonor').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('ForHonor')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']     = {
        --Mode
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Mode",
            Tooltip = "Select the active Combat Mode for this PC.",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes do?",
            Answer = "Tank Mode will focus on tanking and aggro, while DPS mode will focus on DPS. Both have a secondary focus of healing.",
        },

        --Buffs and Debuffs
        ['DoTempHP']          = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 3,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("TempHP") end,
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why do we have the Temp HP Buff always memorized?",
            Answer = "Temp HP buffs have a very long refresh time after scribing, making them infeasible to use if not gemmed.",
        },
        ['OverwriteDPUBuffs'] = {
            DisplayName = "Overwrite DPU Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 5,
            Tooltip = "Overwrite DPU with single buffs when they are better than the DPU effect.",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoVetAA']           = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 8,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoUndeadProc']      = {
            DisplayName = "Use Undead Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Use Undead proc over Fury proc until Fury is rolled into Divine Protector's Unity (Level 80).",
            Default = false,
        },
        ['DoSteelProc']       = {
            DisplayName = "Use Steel Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 3,
            Tooltip = "Use your Steel Proc line.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoBrells']          = {
            DisplayName = "Do Brells",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Enable Casting Brells",
            Default = true,
        },
        ['AegoSymbol']        = {
            DisplayName = "Aego/Symbol Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Choose whether to use the Aegolism or Symbol Line of HP Buffs.",
            Type = "Combo",
            ComboOptions = { 'Aegolism Line (Keeper)', 'Symbol Line', 'None', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoSalvation']       = {
            DisplayName = "Marr's Salvation",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your group hatred reduction buff AA (The Paladin will cancel it on themself if in Tank Mode).",
            Default = true,
            RequiresLoadoutChange = true,
        },

        --Hate Tools
        ['Timer4Choice']      = {
            DisplayName = "Use Timer 4 Stun",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use your Timer 4 'Force' line of stuns.",
            Default = mq.TLO.Me.Level() < 92 and true or false,
            RequiresLoadoutChange = true,
        },
        ['Timer5Choice']      = {
            DisplayName = "Timer 5 Choice:",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip =
            "Choose which Timer 5 spell line to use (For the best experience for leveling, the standard stun will be used until others are available.\nIt is recommended to switch this line out for the Timer 3 'Healstun' once it is available.).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Crush', 'Standard Stun', 'Disabled', },
            Default = mq.TLO.Me.Level() < 99 and 1 or 3,
            Min = 1,
            Max = 4,
            ConfigType = "Advanced",
        },
        ['Timer6Choice']      = {
            DisplayName = "Timer 6 Choice:",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 102,
            Tooltip = "Choose which Timer 6 spell line to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Crush', '"Lesson" Stun', 'Disabled', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoDicho']           = {
            DisplayName = "Cast Dicho",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 104,
            Tooltip = "Use your Dichotomic Hate/Stun/GroupHeal spell.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['AETauntAA']         = {
            DisplayName = "Use AE Taunt AA",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use AE Taunt AA.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },

        --Defenses
        ['DiscCount']         = {
            DisplayName = "Def. Disc. Count",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 101,
            Tooltip = "Number of mobs around you before you use preemptively use Defensive Discs.",
            Default = 4,
            Min = 1,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['DefenseStart']      = {
            DisplayName = "Defense HP",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 102,
            Tooltip = "The HP % where we will use defensive actions like discs, epics, etc.\nNote that fighting a named will also trigger these actions.",
            Default = 60,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['EmergencyStart']    = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 103,
            Tooltip = "The HP % before all but essential rotations are cut in favor of emergency or defensive abilities.",
            Default = 40,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['HPCritical']        = {
            DisplayName = "HP Critical",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 104,
            Tooltip =
            "The HP % that we will use abilities like Lay on Hands or Gift of Life.\nMost other rotations are cut to give our full focus to survival.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },

        --Equipment
        ['DoChestClick']      = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoCharmClick']      = {
            DisplayName = "Do Charm Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your charm for Geomantra.",
            Default = false,
        },
        ['UseBandolier']      = {
            DisplayName = "Dynamic Weapon Swap",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 101,
            Tooltip = "Enable 1H+S/2H swapping based off of current health. ***YOU MUST HAVE BANDOLIER ENTRIES NAMED \"Shield\" and \"2Hand\" TO USE THIS FUNCTION.***",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['EquipShield']       = {
            DisplayName = "Equip Shield",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 102,
            Tooltip = "Under this HP%, you will swap to your \"Shield\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['Equip2Hand']        = {
            DisplayName = "Equip 2Hand",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 103,
            Tooltip = "Over this HP%, you will swap to your \"2Hand\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 75,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['NamedShieldLock']   = {
            DisplayName = "Shield on Named",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 104,
            Tooltip = "Keep Shield equipped while tanking a named.",
            Default = true,
            FAQ = "Why does my PAL switch to a Shield on puny gray named?",
            Answer = "The Shield on Named option doesn't check levels, so feel free to disable this setting (or Bandolier swapping entirely) if you are farming fodder.",
        },
        ['DoTouchHeal']       = {
            DisplayName = "Touch Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Choose when the Paladin will use the single-target Touch-line healing spell.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Emergency Use(BigHeal)', 'Standard Use(MainHeal)', 'Never', },
            Default = mq.TLO.Me.Level() > 72 and 3 or 2,
            Min = 1,
            Max = 3,
        },
        ['DoLightHeal']       = {
            DisplayName = "Do Light Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your ToT heal ('... Light') line of spells.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoSelfHeal']        = {
            DisplayName = "Do Self Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your emergency self-heal line of spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoWaveHeal']        = {
            DisplayName = "Do Wave Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your group heal ('Wave of ...') line of spells.",
            RequiresLoadoutChange = true,
            Default = mq.TLO.Me.Level() < 83 and true or false,
        },
        ['KeepSplashMemmed']  = {
            DisplayName = "Mem Splash Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip =
            "Memorize your 'Splash' line AE heal/cure, and use it as a group heal or cure. (If unchecked, we may mem/use it out of combat as a cure, depending on other settings.)",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTwinHealNuke']    = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['KeepPurityMemmed']  = {
            DisplayName = "Mem Purity Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Memorize your Purity line (cure poi/dis/curse) when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if enabled.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['KeepCorruptMemmed'] = {
            DisplayName = "Mem Cure Corruption",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Memorize cure corruption spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['SplashHealAsCure']  = {
            DisplayName = "Use Splash Heal to Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 103,
            Tooltip = "If the Splash Heal is available, use it to cure detrimental effects.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoReverseDS']       = {
            DisplayName = "Reverse DS",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 101,
            Tooltip = "Choose when to use your Reverse DS ('Mark of ...') line of debuffs.",
            Type = "Combo",
            ComboOptions = { 'Always', 'Only on Named', 'Never', },
            Default = 3,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['HealPriority']      = {
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
            Answer = "This class config is an Alpha config, lacking playtesting.\n\n" ..
                "  The defaults are aimed towards late game live tanking, but it has the options for other modes or methods.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
