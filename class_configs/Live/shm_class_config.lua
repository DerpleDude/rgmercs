local mq           = require('mq')
local Casting      = require("utils.casting")
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "2.2 - Live",
    _author               = "Algar, Derple",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring  = function() return Config:GetSetting('DoCures') end,
        IsRezing  = function()
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
                end,
            },
        },
    },
    ['Modes']             = {
        'Heal',
        'Hybrid',
    },
    ['PetPosition']       = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function()
            local cdAA = mq.TLO.Me.AltAbility("Companion's Discipline")
            return (cdAA and cdAA.Rank() or 0) >= 4 and "Companion's Discipline"
        end,
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
            { type = "AA", name = "Purified Spirits", selfOnly = true, },
        },
        ['Poison'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'CureSpell', 'CurePoison', }) end, },
        },
        ['Disease'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'CureSpell', 'CureDisease', }) end, },
        },
        ['Curse'] = {
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'CureSpell', 'CureCurse', }) end, },
        },
        ['Corruption'] = {
            { type = "Spell", name = "CureCorrupt", },
        },
    },
    ['Themes']            = {
        ['Heal'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.55, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.55, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.22, g = 0.14, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.55, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.55, g = 0.35, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.22, g = 0.14, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.55, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.55, g = 0.35, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.55, g = 0.35, b = 0.05, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.36, g = 0.23, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.55, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.55, g = 0.35, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.55, g = 0.35, b = 0.05, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.22, g = 0.14, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.95, g = 0.70, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.95, g = 0.70, b = 0.15, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.55, g = 0.35, b = 0.05, a = 1.0, }, },
        },
        ['Hybrid'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.25, g = 0.38, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.25, g = 0.38, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.10, g = 0.15, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.25, g = 0.38, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.25, g = 0.38, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.10, g = 0.15, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.25, g = 0.38, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.25, g = 0.38, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.25, g = 0.38, b = 0.08, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.16, g = 0.25, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.25, g = 0.38, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.25, g = 0.38, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.25, g = 0.38, b = 0.08, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.10, g = 0.15, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.55, g = 0.80, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.55, g = 0.80, b = 0.20, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.25, g = 0.38, b = 0.08, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Crafted Talisman of Fates",
            "Blessed Spiritstaff of the Heyokah",
        },
    },
    ['AbilitySets']       = {
        ['GroupFocusSpell'] = {
            -- Focus Spell - Group Spells will be used on everyone
            "Talisman of Unity X",        -- Level 126, - Group
            "Talisman of the Heroic",     -- Level 125, - Group
            "Talisman of the Usurper",    -- Level 120, - Group
            "Talisman of the Ry'Gorr",    -- Level 115, - Group
            "Talisman of the Wulthan",    -- Level 110, - Group
            "Talisman of the Doomscale",  -- Level 105, - Group
            "Talisman of the Courageous", -- Level 100, - Group
            "Talisman of Kolos' Unity",   -- Level 95, - Group
            "Talisman of Soul's Unity",   -- Level 90, - Group
            "Talisman of Unity",          -- Level 85, - Group
            "Talisman of the Bloodworg",  -- Level 80, - Group
            "Talisman of the Dire",       -- Level 75, - Group
            "Talisman of Wunshi",         -- Level 70, - Group
            "Focus of the Seventh",       -- Level 65, - Group
            "Khura's Focusing",           -- Level 60, - Group
            "Focus of Spirit",            -- Level 60, - Single, added for TLP without Khura's
            "Infusion of Spirit",         -- Level 49, Str/Dex/Sta, can use HP buff. Not sure if this is the final home for this one or not.
        },
        ['RunSpeedBuff'] = {
            -- Run Speed Buff - 9 - 74
            "Spirit of Tala'Tak", -- Level 74
            "Spirit of Bih`Li",   -- Level 36
            "Pack Shrew",         -- Level 34
            "Spirit of Wolf",     -- Level 9
        },
        ['HasteBuff'] = {
            -- Haste Buff - 26 - 64
            "Talisman of Celerity", -- Level 64
            "Swift Like the Wind",  -- Level 63
            "Celerity",             -- Level 56
            "Alacrity",             -- Level 42
            "Quickness",            -- Level 26
        },
        ['TempHPBuff'] = {
            -- Growth Buff 81+
            "Wild Growth X",       -- Level 126
            "Overwhelming Growth", -- Level 121
            "Fervent Growth",      -- Level 116
            "Frenzied Growth",     -- Level 111
            "Savage Growth",       -- Level 106
            "Ferocious Growth",    -- Level 101
            "Rampant Growth",      -- Level 96
            "Unfettered Growth",   -- Level 91
            "Untamed Growth",      -- Level 86
            "Wild Growth",         -- Level 81
        },
        ['LowLvlStaBuff'] = {
            -- Low Level Stamina Buff --- I guess this may be okay for tanks (but largely a raid thing). Need to scrub which levels. Not currently used.
            "Talisman of Vehemence",   -- Level 76
            "Spirit of Vehemence",     -- Level 76
            "Talisman of Persistence", -- Level 71
            "Talisman of Fortitude",   -- Level 69
            "Spirit of Fortitude",     -- Level 68
            "Talisman of the Boar",    -- Level 63
            "Endurance of the Boar",   -- Level 62
            "Talisman of the Brute",   -- Level 57
            "Riotous Health",          -- Level 54
            "Stamina",                 -- Level 43
            "Health",                  -- Level 30
            "Spirit of Ox",            -- Level 21
            "Spirit of Bear",          -- Level 6
        },
        ['LowLvlAtkBuff'] = {
            -- Low Level Attack Buff --- user under level 86. Including Harnessing of Spirit as they will have similar usecases and targets.
            "Champion",             -- Level 70
            "Ferine Avatar",        -- Level 65
            "Primal Avatar",        -- Level 60
            "Harnessing of Spirit", -- Level 46
        },
        ['LowLvlHPBuff'] = {
            "Talisman of Kragg",  -- Level 55, - Single
            "Talisman of Altuna", -- Level 40, - Single
            "Talisman of Tnarg",  -- Level 32, - Single
            "Inner Fire",         -- Level 1, - Single
        },
        ['LowLvlStrBuff'] = {
            -- Low Level Strength Buff -- Below 68 these are only worthwhile on non-live, defiant stat caps too easily. Even then arguable.
            "Talisman of Might",     -- Level 70, Group
            "Spirit of Might",       -- Level 67, Single Target
            "Talisman of the Diaku", -- Level 64
            "Talisman of the Rhino", -- Level 58
            "Maniacal Strength",     -- Level 57
            "Strength",              -- Level 46
            "Tumultuous Strength",   -- Level 35
            "Raging Strength",       -- Level 28
            "Spirit Strength",       -- Level 18, Can't see this as being very worth but keeping for now.
        },
        ['LowLvlDexBuff'] = {
            -- Low Level Dex Buff -- This has no real place outside of raids on select tanks. Waste of mana.
            "Talisman of the Raptor", -- Level 59
            "Mortal Deftness",        -- Level 58
            "Dexterity",              -- Level 48
            "Deftness",               -- Level 39
            "Rising Dexterity",       -- Level 25
            "Spirit of Monkey",       -- Level 21
            "Dexterous Aura",         -- Level 1
        },
        ['LowLvlAgiBuff'] = {
            --- Low Level AGI Buff -- This has no real place outside of raids on select tanks. Waste of mana.
            "Talisman of Foresight",   -- Level 74
            "Preternatural Foresight", -- Level 71
            "Talisman of Sense",       -- Level 68
            "Spirit of Sense",         -- Level 66
            "Talisman of the Wrulan",  -- Level 62
            "Agility of the Wrulan",   -- Level 61
            "Talisman of the Cat",     -- Level 57
            "Deliriously Nimble",      -- Level 53
            "Agility",                 -- Level 41
            "Nimble",                  -- Level 31
            "Spirit of Cat",           -- Level 18
            "Feet like Cat",           -- Level 3
        },
        ['AEMaloSpell'] = {
            "Wind of Malisene", -- Level 89
            "Wind of Malis",    -- Level 84
        },
        ['MaloSpell'] = {
            -- AA Starts at LVL 75
            "Malaise XVI",     -- Level 127
            "Malosinera",      -- Level 122
            "Malosinetra",     -- Level 117
            "Malosinise",      -- Level 72
            "Malos",           -- Level 65
            "Malosinia",       -- Level 63
            "Malosini",        -- Level 57
            --Below this these spells are considered by many to be a waste of mana, but the user can elect to turn this off.
            "Malosi",          -- Level 48
            "Malaisement",     -- Level 32
            "Malaise",         -- Level 18
        },
        ['AESlowSpell'] = {    --Often considered a waste of mana in group situations, user option.
            "Tigir's Insects", -- Level 58
        },
        ['SlowSpell'] = {
            "Balance of Discord",   -- Level 69
            "Balance of the Nihil", -- Level 65
            "Turgur's Insects",     -- Level 51, Can save mana by continuing to use Togor's on group mobs, but this is problematic for automation. Not worth splitting the entry.
            "Togor's Insects",      -- Level 38
            "Tagar's Insects",      -- Level 27
            -- "Walking Sleep",     -- Level 13, Too much mana with little benefit at these levels
            -- "Drowsy",            -- Level 5, Too much mana with little benefit at these levels
        },
        ['DiseaseSlow'] = {
            "Cloud of Grummus",  -- Level 61
            "Plague of Insects", -- Level 54
        },
        ['CrippleSpell'] = {     --not currently utilized for groups, gem slots are precious
            "Crippling Spasm",   -- Level 66
            "Cripple",           -- Level 53, Starts to become worth it, depending on target
            "Incapacitate",      -- Level 41, Likely not worth
            "Listless Power",    -- Level 29, Definitely not worth
        },
        ['GroupHealProcBuff'] = {
            "Mindful Spirit",    -- Level 122
            "Watchful Spirit",   -- Level 117
            "Attentive Spirit",  -- Level 112
            "Responsive Spirit", -- Level 101
        },
        ['WardBuff'] = {
            -- Self Heal Ward Spells
            "Ward of Resurgence XI",  -- Level 130
            "Ward of Heroic Deeds",   -- Level 125
            "Ward of Rebirth",        -- Level 120
            "Ward of Recuperation",   -- Level 115
            "Ward of Remediation",    -- Level 110
            "Ward of Regeneration",   -- Level 105
            "Ward of Rejuvenation",   -- Level 100
            "Ward of Reconstruction", -- Level 95
            "Ward of Recovery",       -- Level 90
            "Ward of Restoration",    -- Level 85
            "Ward of Resurgence",     -- Level 80
        },
        ['DichoSpell'] = {
            "Reciprocal Roar",  -- Level 121
            "Ecliptic Roar",    -- Level 116
            "Composite Roar",   -- Level 111
            "Dissident Roar",   -- Level 106
            "Roar of the Lion", -- Level 101
        },
        ['MeleeProcBuff'] = {
            -- Melee Proc Buff - Level 50 - 111
            -- To be used when the Shaman does not have Dicho
            "Talisman of the Panther XVI",  -- Level 126
            "Talisman of the Manul",        -- Level 121
            "Talisman of the Kerran",       -- Level 116
            "Talisman of the Lioness",      -- Level 111
            "Talisman of the Sabretooth",   -- Level 106
            "Talisman of the Leopard",      -- Level 101
            "Talisman of the Snow Leopard", -- Level 96
            "Talisman of the Lion",         -- Level 91
            "Talisman of the Tiger",        -- Level 86
            "Talisman of the Lynx",         -- Level 81
            "Talisman of the Cougar",       -- Level 76
            "Talisman of the Panther",      -- Level 71
            "Spirit of the Panther",        -- Level 69
            "Spirit of the Leopard",        -- Level 61
            "Spirit of the Jaguar",         -- Level 57
            "Spirit of the Puma",           -- Level 50
        },
        ['SlowProcBuff'] = {
            -- Slow Proc Buff for MA - Level 68 - 122
            "Lassitude XIII",  -- Level 127
            "Moroseness",      -- Level 122
            "Melancholy",      -- Level 117
            "Ennui",           -- Level 112
            "Incapacity",      -- Level 107
            "Sluggishness",    -- Level 102
            "Fatigue",         -- Level 97
            "Apathy",          -- Level 92
            "Lethargy",        -- Level 87
            "Listlessness",    -- Level 82
            "Languor",         -- Level 77
            "Lassitude",       -- Level 72
            "Lingering Sloth", -- Level 68
        },
        ['PackSelfBuff'] = {
            -- Pack Self Buff - Level 90 - 115
            --- Ignoring the LVL 85 Call the Pack buff due to the decrease in mana per tick.
            "Pack of Dire Wolves",      -- Level 130
            "Pack of Ancestral Beasts", -- Level 125
            "Pack of Lunar Wolves",     -- Level 120
            "Pack of The Black Fang",   -- Level 115
            "Pack of Mirtuk",           -- Level 110
            "Pack of Olesira",          -- Level 105
            "Pack of Kriegas",          -- Level 100
            "Pack of Hilnaah",          -- Level 95
            "Pack of Wurt",             -- Level 90
        },
        ['AllianceBuff'] = {
            "Ancient Covariance", -- Level 123
            "Ancient Coalition",  -- Level 113
            "Ancient Alliance",   -- Level 103
        },
        ['RezSpell'] = {
            "Incarnate Anew", -- Level 59
        },
        ['RecklessHeal1'] = {
            "Reckless Mending VIII",      -- Level 130
            "Reckless Reinvigoration",    -- Level 125
            "Reckless Resurgence",        -- Level 120
            "Reckless Renewal",           -- Level 115
            "Reckless Rejuvenation",      -- Level 110
            "Reckless Regeneration",      -- Level 105
            "Reckless Restoration",       -- Level 100
            "Reckless Remedy",            -- Level 95
            "Reckless Mending",           -- Level 90
            "Qirik's Mending",            -- Level 88
            "Dannal's Mending",           -- Level 83
            "Gemmi's Mending",            -- Level 78
            "Ahnkaul's Mending",          -- Level 73
            "Ancient: Wilslik's Mending", -- Level 70
            "Yoppa's Mending",            -- Level 68
            "Daluda's Mending",           -- Level 65
            "Tnarg's Mending",            -- Level 62
            "Chloroblast",                -- Level 55
            "Kragg's Salve",              -- Level 50
            "Superior Healing",           -- Level 45
            "Spirit Salve",               -- Level 40
            "Greater Healing",            -- Level 29
            "Healing",                    -- Level 19
            "Light Healing",              -- Level 9
            "Minor Healing",              -- Level 1
        },
        ['RecklessHeal2'] = {
            --worthless to mem two mendings because they don't have a recast time, keep Qirik's for when we don't have enough Reckless.
            "Reckless Mending VIII",   -- Level 130
            "Reckless Reinvigoration", -- Level 125
            "Reckless Resurgence",     -- Level 120
            "Reckless Renewal",        -- Level 115
            "Reckless Rejuvenation",   -- Level 110
            "Reckless Regeneration",   -- Level 105
            "Reckless Restoration",    -- Level 100
            "Reckless Remedy",         -- Level 95
            "Reckless Mending",        -- Level 90
            "Qirik's Mending",         -- Level 88
        },
        ['RecklessHeal3'] = {
            --fallback just in case we have some other DPS stuff disabled, but 3 reckless is overkill for automation
            "Reckless Mending VIII",   -- Level 130
            "Reckless Reinvigoration", -- Level 125
            "Reckless Resurgence",     -- Level 120
            "Reckless Renewal",        -- Level 115
            "Reckless Rejuvenation",   -- Level 110
            "Reckless Regeneration",   -- Level 105
            "Reckless Restoration",    -- Level 100
            "Reckless Remedy",         -- Level 95
            "Reckless Mending",        -- Level 90
            "Qirik's Mending",         -- Level 88
        },
        ['AESpiritualHeal'] = {
            -- Pulsing AE Heal, 100+
            "Spiritual Shower", -- Level 118
            "Spiritual Squall", -- Level 110
            "Spiritual Swell",  -- Level 105
            "Spiritual Surge",  -- Level 100
        },
        ['RecourseHeal'] = {
            --- RecourseHeal Level 87+
            "Baratu's Recourse",   -- Level 127
            "Grayleaf's Recourse", -- Level 122
            "Rowain's Recourse",   -- Level 117
            "Zrelik's Recourse",   -- Level 112
            "Eyrzekla's Recourse", -- Level 107
            "Krasir's Recourse",   -- Level 102
            "Blezon's Recourse",   -- Level 97
            "Gotikan's Recourse",  -- Level 92
            "Qirik's Recourse",    -- Level 87
        },
        ['InterventionHeal'] = {
            -- Intervention Heal 78+
            "Ancestral Intervention XI", -- Level 128
            "Immortal Intervention",     -- Level 123
            "Antediluvian Intervention", -- Level 118
            "Primordial Intervention",   -- Level 113
            "Prehistoric Intervention",  -- Level 108
            "Historian's Intervention",  -- Level 103
            "Antecessor's Intervention", -- Level 98
            "Progenitor's Intervention", -- Level 93
            "Ascendant's Intervention",  -- Level 88
            "Antecedent's Intervention", -- Level 83
            "Ancestral Intervention",    -- Level 78
        },
        ['GroupRenewalHoT'] = {
            -- Prior to 70 Breath of Trushar, single HoTs will be used including the
            --- the Torpor/Stoicism line. LVL 44 is the lowest level.
            "Ghost of Renewal XIII", -- Level 128
            "Reverie of Renewal",    -- Level 125
            "Spirit of Renewal",     -- Level 120
            "Spectre of Renewal",    -- Level 115
            "Cloud of Renewal",      -- Level 110
            "Shear of Renewal",      -- Level 105
            "Wisp of Renewal",       -- Level 100
            "Phantom of Renewal",    -- Level 95
            "Penumbra of Renewal",   -- Level 90
            "Shadow of Renewal",     -- Level 85
            "Shade of Renewal",      -- Level 80
            "Specter of Renewal",    -- Level 75
            "Ghost of Renewal",      -- Level 70
            "Spiritual Serenity",    -- Level 70
            "Breath of Trushar",     -- Level 65
            "Quiescence",            -- Level 65
            "Torpor",                -- Level 60
            "Stoicism",              -- Level 44
        },
        ['CanniSpell'] = {
            -- Convert Health to Mana - Level  23+
            "Ancestral Bargain XIV",      -- Level 129
            "Traumatic Exchange",         -- Level 124
            "Hoary Agreement",            -- Level 118
            "Ancient Bargain",            -- Level 113
            "Tribal Bargain",             -- Level 108
            "Tribal Pact",                -- Level 103
            "Ancestral Pact",             -- Level 98
            "Ancestral Arrangement",      -- Level 93
            "Ancestral Covenant",         -- Level 88
            "Ancestral Obligation",       -- Level 83
            "Ancestral Hearkening",       -- Level 78
            "Ancestral Bargain",          -- Level 73
            "Ancient: Ancestral Calling", -- Level 70
            "Pained Memory",              -- Level 68
            "Ancient: Chaotic Pain",      -- Level 65
            "Cannibalize IV",             -- Level 58
            "Cannibalize III",            -- Level 54
            "Cannibalize II",             -- Level 38
            "Cannibalize",                -- Level 23
        },
        ['CureSpell'] = {
            "Mastery: Blood of Mayong", -- Level 130
            "Blood of Mayong",          -- Level 120
            "Blood of Tevik",           -- Level 110
            "Blood of Rivans",          -- Level 105
            "Blood of Sanera",          -- Level 100
            "Blood of Klar",            -- Level 95
            "Blood of Corbeth",         -- Level 90
            "Blood of Avoling",         -- Level 85
            "Blood of Nadox",           -- Level 52
        },
        ['CureCorrupt'] = {
            "Mastery: Chant of the Zelniak", -- Level 129
            "Chant of the Zelniak",          -- Level 119
            "Chant of the Wulthan",          -- Level 109
            "Chant of the Kromtus",          -- Level 104
            "Chant of Jaerol",               -- Level 99
            "Chant of the Izon",             -- Level 94
            "Chant of the Tae Ew",           -- Level 89
            "Chant of the Burynai",          -- Level 84
            "Chant of the Darkvine",         -- Level 79
            "Chant of the Napaea",           -- Level 64
            "Cure Corruption",               -- Level 62
        },
        ['TwinHealNuke'] = {
            -- Nuke the MA Not the assist target - Levels 85+
            "Frost Gift X",     -- Level 130
            "Gelid Gift",       -- Level 125
            "Polar Gift",       -- Level 120
            "Wintry Gift",      -- Level 115
            "Frostbitten Gift", -- Level 110
            "Glacial Gift",     -- Level 105
            "Frigid Gift",      -- Level 100
            "Freezing Gift",    -- Level 95
            "Frozen Gift",      -- Level 90
            "Frost Gift",       -- Level 85
        },
        ['PoisonNuke'] = {
            -- Poison Nuke LVL34 +
            "Tserik's Spear of Venom",       -- Level 126
            "Red Eye's Spear of Venom",      -- Level 121
            "Fleshrot's Spear of Venom",     -- Level 116
            "Narandi's Spear of Venom",      -- Level 111
            "Nexona's Spear of Venom",       -- Level 106
            "Serisaria's Spear of Venom",    -- Level 101
            "Slaunk's Spear of Venom",       -- Level 96
            "Hiqork's Spear of Venom",       -- Level 91
            "Spinechiller's Spear of Venom", -- Level 86
            "Severilous' Spear of Venom",    -- Level 81
            "Vestax's Spear of Venom",       -- Level 76
            "Ahnkaul's Spear of Venom",      -- Level 71
            "Yoppa's Spear of Venom",        -- Level 66
            "Spear of Torment",              -- Level 61
            "Blast of Venom",                -- Level 54
            "Shock of Venom",                -- Level 47
            "Blast of Poison",               -- Level 42
            "Shock of the Tainted",          -- Level 34
        },
        ['FastPoisonNuke'] = {
            -- Fast Poison Nuke LVL73+
            "Tserik's Bite",          -- Level 128
            "Oka's Bite",             -- Level 123
            "Ander's Bite",           -- Level 118
            "Direfang's Bite",        -- Level 113
            "Mawmun's Bite",          -- Level 108
            "Reefmaw's Bite",         -- Level 103
            "Seedspitter's Bite",     -- Level 98
            "Bite of the Grendlaen",  -- Level 93
            "Bite of the Blightwolf", -- Level 88
            "Bite of the Ukun",       -- Level 83
            "Bite of the Brownie",    -- Level 78
            "Sting of the Queen",     -- Level 73
        },
        ['IceNuke'] = {
            --- IceNuke - Level 4+
            "Frost Rift XX",     -- Level 129
            "Ice Barrage",       -- Level 124
            "Heavy Sleet",       -- Level 119
            "Ice Salvo",         -- Level 114
            "Ice Shards",        -- Level 109
            "Ice Squall",        -- Level 104
            "Ice Burst",         -- Level 99
            "Ice Mass",          -- Level 94
            "Ice Floe",          -- Level 89
            "Ice Sheet",         -- Level 84
            "Tundra Crumble",    -- Level 79
            "Glacial Avalanche", -- Level 74
            "Ice Age",           -- Level 69
            "Velium Strike",     -- Level 64
            "Ice Strike",        -- Level 54
            "Blizzard Blast",    -- Level 44
            "Winter's Roar",     -- Level 33
            "Frost Strike",      -- Level 23
            "Spirit Strike",     -- Level 14
            "Frost Rift",        -- Level 4
        },
        ['ChaoticDot'] = {
            -- Long Dot(42s) LVL 104+
            -- Two resist types because it throws 2 dots
            -- Stacking: Nectar of Pain - Stacking: Blood of Saryrn
            "Chaotic Bloodcurse", -- Level 125
            "Chaotic Toxin",      -- Level 120
            "Chaotic Venin",      -- Level 115
            "Chaotic Poison",     -- Level 109
            "Chaotic Venom",      -- Level 104
        },
        ['PandemicDot'] = {
            -- Pandemic Dot Long Dot(84s) Level 103+
            -- Two resist types because it throws 2 dots
            -- Stacking: Kralbor's Pandemic  -    Stacking: Breath of Ultor
            "Hotariton Pandemic",     -- Level 124
            "Tegi Pandemic",          -- Level 119
            "Bledrek's Pandemic",     -- Level 114
            "Elkikatar's Pandemic",   -- Level 108
            "Hemocoraxius' Pandemic", -- Level 103
        },
        ['MaloDot'] = {
            -- Malo Dot Stacking: Yubai's Affliction - LongDot(96s) Level 99+
            "Torrentclaw's Malosinera", -- Level 129
            "Krizad's Malosinera",      -- Level 124
            "Txiki's Malosinara",       -- Level 119
            "Svartmane's Malosinara",   -- Level 114
            "Rirwech's Malosinata",     -- Level 109
            "Livio's Malosenia",        -- Level 104
            "Falhotep's Malosenia",     -- Level 99
        },
        ['CurseDot1'] = {
            -- Curse Dot 1 Stacking: Curse - Long Dot(30s) - Level 34+
            "Curse XVII",       -- Level 129
            "Malediction",      -- Level 124
            "Obeah",            -- Level 119
            "Evil Eye",         -- Level 114
            "Jinx",             -- Level 109
            "Garugaru",         -- Level 104
            "Naganaga",         -- Level 99
            "Hoodoo",           -- Level 94
            "Hex",              -- Level 89
            "Mojo",             -- Level 84
            "Pocus",            -- Level 79
            "Juju",             -- Level 74
            "Curse of Sisslak", -- Level 69
            "Bane",             -- Level 64
            "Anathema",         -- Level 54
            "Odium",            -- Level 43
            "Curse",            -- Level 34
        },
        ['CurseDot2'] = {
            ---, Stacking: Enalam's Curse - Long Dot(54s) - 100+
            "Maniadry's Curse", -- Level 130
            "Fandrel's Curse",  -- Level 125
            "Lenrel's Curse",   -- Level 120
            "Marlek's Curse",   -- Level 115
            "Erogo's Curse",    -- Level 110
            "Sraskus' Curse",   -- Level 105
            "Enalam's Curse",   -- Level 100
        },
        ['SaryrnDot'] = {
            -- Stacking: Blood of Saryrn - Long Dot(42s) - Level 8+
            "Blood of Torrentclaw",     -- Level 129
            "Caustic Blood",            -- Level 124
            "Desperate Vampyre Blood",  -- Level 120
            "Restless Blood",           -- Level 115
            "Reef Crawler Blood",       -- Level 105
            "Phase Spider Blood",       -- Level 100
            "Naeya Blood",              -- Level 95
            "Spinechiller Blood",       -- Level 90
            "Blood of Jaled'Dar",       -- Level 85
            "Blood of Kerafyrm",        -- Level 80
            "Vengeance of Ahnkaul",     -- Level 75
            "Blood of Yoppa",           -- Level 70
            "Blood of Saryrn",          -- Level 65
            "Ancient: Scourge of Nife", -- Level 60
            "Bane of Nife",             -- Level 56
            "Envenomed Bolt",           -- Level 49
            "Venom of the Snake",       -- Level 37
            "Envenomed Breath",         -- Level 24
            "Tainted Breath",           -- Level 8
        },
        ['UltorDot'] = {
            ---, Stacking: Breath of Ultor - Long Dot(84s) - Level 4+
            "Breath of Pustim",         -- Level 126
            "Breath of the Hotariton",  -- Level 121
            "Breath of the Tegi",       -- Level 116
            "Breath of Bledrek",        -- Level 111
            "Breath of Hemocoraxius",   -- Level 101
            "Breath of Natigo",         -- Level 96
            "Breath of Silbar",         -- Level 91
            "Breath of the Shiverback", -- Level 86
            "Breath of Queen Malarian", -- Level 81
            "Breath of Big Bynn",       -- Level 76
            "Breath of Ternsmochin",    -- Level 71
            "Breath of Wunshi",         -- Level 67
            "Breath of Ultor",          -- Level 64
            "Pox of Bertoxxulous",      -- Level 59
            "Plague",                   -- Level 49
            "Scourge",                  -- Level 31
            "Affliction",               -- Level 19
            "Sicken",                   -- Level 4
        },
        ['AfflictionDot'] = {
            ---, Stacking: Yubai's Affliction - Long Dot(96s) - Level 9+, used on named only for hybrid
            "Torrentclaw's Affliction", -- Level 127
            "Krizad's Affliction",      -- Level 122
            "Brightfeld's Affliction",  -- Level 117
            "Svartmane's Affliction",   -- Level 112
            "Rirwech's Affliction",     -- Level 107
            "Livio's Affliction",       -- Level 102
            "Falhotep's Affliction",    -- Level 97
            "Yubai's Affliction",       -- Level 92
        },
        ['NectarDot'] = {               --almost never worth casting in a group, not currently gemmed.
            "Nectar of Pain XIII",      -- Level 129
            "Nectar of Obscurity",      -- Level 124
            "Nectar of Destitution",    -- Level 119
            "Nectar of Misery",         -- Level 114
            "Nectar of Suffering",      -- Level 109
            "Nectar of Woe",            -- Level 104
            "Nectar of Anguish",        -- Level 99
            "Nectar of Sholoth",        -- Level 94
            "Nectar of Torment",        -- Level 89
            "Nectar of the Slitheren",  -- Level 84
            "Nectar of Rancor",         -- Level 79
            "Nectar of Agony",          -- Level 74
            "Nectar of Pain",           -- Level 70
        },
        ['PetSpell'] = {
            -- Pet Spell - 32+
            "Aramna's Faithful",        -- Level 127
            "Suja's Faithful",          -- Level 122
            "Diabo Sivuela's Faithful", -- Level 117
            "Grondo's Faithful",        -- Level 112
            "Mirtuk's Faithful",        -- Level 107
            "Olesira's Faithful",       -- Level 102
            "Kriegas' Faithful",        -- Level 97
            "Hilnaah's Faithful",       -- Level 92
            "Wurt's Faithful",          -- Level 87
            "Aina's Faithful",          -- Level 82
            "Vegu's Faithful",          -- Level 77
            "Kyrah's Faithful",         -- Level 72
            "Farrel's Companion",       -- Level 67
            "True Spirit",              -- Level 61
            "Spirit of the Howler",     -- Level 55
            "Frenzied Spirit",          -- Level 45
            "Guardian spirit",          -- Level 41
            "Vigilant Spirit",          -- Level 37
            "Companion Spirit",         -- Level 32
        },
        ['PetBuffSpell'] = {
            ---Pet Buff Spell - 50+
            "Spirit Bolstering V",  -- Level 127
            "Spirit Augmentation",  -- Level 122
            "Spirit Reinforcement", -- Level 117
            "Spirit Bracing",       -- Level 112
            "Spirit Bolstering",    -- Level 97
            "Spirit Quickening",    -- Level 50
        },
        ['CureDisease'] = {
            "Eradicate Disease",  -- Level 52
            "Counteract Disease", -- Level 22
            "Cure Disease",       -- Level 1
        },
        ['CurePoison'] = {
            "Eradicate Poison",  -- Level 56
            "Counteract Poison", -- Level 26
        },
        ['CureCurse'] = {
            -- "Eradicate Curse",   -- Level 54, counters, twice, 400 mana
            "Remove Greater Curse",          -- Level 54, counters, 5 times, 100 mana
            "Remove Curse",                  -- Level 38
            "Remove Lesser Curse",           -- Level 24
            "Remove Minor Curse",            -- Level 9
        },
        ['GroupRegenBuff'] = {               --Does not stack with Dicho Regen
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
            "Talisman of the Stoic One",     -- Level 74
            "Talisman of Perseverance",      -- Level 69
            "Regrowth of Dar Khura",         -- Level 56
        },
        ['SingleRegenBuff'] = {
            "Regrowth",     -- Level 52
            "Chloroplast",  -- Level 39
            "Regeneration", -- Level 23
        },
        ['ShrinkSpell'] = {
            "Tiny Terror", -- Level 64
            "Shrink",      -- Level 15
        },
    },
    ['Helpers']           = {
    },
    -- These are handled differently from normal rotations in that we try to make some intelligent desicions about which spells to use instead
    -- of just slamming through the base ordered list.
    -- These will run in order and exit after the first valid spell to cast
    ['HealRotationOrder'] = {
        {
            name = 'LowLevelHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return mq.TLO.Me.Level() < 65 end,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return mq.TLO.Me.Level() > 64 end,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return mq.TLO.Me.Level() > 64 end,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return mq.TLO.Me.Level() > 64 end,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['LowLevelHealPoint'] = {
            {
                name = "Call of the Ancients",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigHealsNeeded(target)
                end,
            },
            {
                name = "RecklessHeal1",
                type = "Spell",
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    if not Targeting.GroupedWithTarget(target) or not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['GroupHealPoint'] = {
            {
                name = "InterventionHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.BigHealsNeeded(target) -- if multiples hurt with at least one in big heal range
                end,
            },
            {
                name = "Soothsayer's Intervention",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigGroupHealsNeeded() -- if multiples hurt with multiples in big heal range
                end,
            },
            {
                name = "RecourseHeal",
                type = "Spell",
            },
            {
                name = "AESpiritualHeal",
                type = "Spell",
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
                name = "Call of the Ancients",
                type = "AA",
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    if not Targeting.GroupedWithTarget(target) or not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['BigHealPoint'] = {
            {
                name = "Ancestral Guard",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "InterventionHeal",
                type = "Spell",
            },
            {
                name = "Soothsayer's Intervention",
                type = "AA",
            },
            {
                name = "Union of Spirits",
                type = "AA",
            },
            { --The stuff above is down, lets make mainhealpoint chonkier.
                name = "Spiritual Blessing",
                type = "AA",
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
            { --if we hit this we need intervention back ASAP
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['MainHealPoint'] = {
            {
                name = "RecourseHeal",
                type = "Spell",
            },
            {
                name = "AESpiritualHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "RecklessHeal1",
                type = "Spell",
            },
            {
                name = "RecklessHeal2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SpellLoaded(spell)
                end,
            },
            {
                name = "RecklessHeal3",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SpellLoaded(spell)
                end,
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
        },
    },
    ['Charm']             = {
        ['Assist'] = {
            {
                name = "Malaise",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTMalo') and Casting.CanUseAA("Malaise") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSTMalo') and not Casting.CanUseAA("Malaise") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
    },
    ['RotationOrder']     = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff() and
                    Casting.AmIBuffable()
            end,
        },
        {
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and
                    Casting.AmIBuffable()
            end,
        },
        { --Downtime buffs that don't need constant checks
            name = 'SlowDowntime',
            timer = 30,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    Core.CombatActionsCheck() and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Spells that should be checked on group members
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
            end,
        },
        {
            name = 'Malo',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSTMalo') or Config:GetSetting('DoAEMalo') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Slow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSTSlow') or Config:GetSetting('DoAESlow') end,
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
                return combat_state == "Combat" and Casting.BurnCheck() and
                    Core.CombatActionsCheck()
            end,
        },
        {
            name = 'ProcBuff',
            state = 1,
            steps = 1,
            load_cond = function(self) return self:GetResolvedActionMapItem('MeleeProcBuff') end,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'CombatBuff',
            timer = 10,
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
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
                return combat_state == "Combat" and ((not Core.IsModeActive('Heal') or Config:GetSetting('DoHealDPS')) and Core.CombatActionsCheck())
            end,
        },
    },
    ['Rotations']         = {
        ['ProcBuff'] = {
            {
                name = "DichoSpell",
                type = "Spell",
                load_cond = function(self) return Core.GetResolvedActionMapItem('DichoSpell') end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "MeleeProcBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('DichoSpell') end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Fleeting Spirit",
                type = "AA",
            },
            {
                name = "Ancestral Aid",
                type = "AA",
            },
            {
                name = "Spire of Ancestors",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Spirit Call",
                type = "AA",
            },
            {
                name = "Rabid Bear",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoMelee') and mq.TLO.Me.Combat()
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Malo'] = {
            {
                name = "Wind of Malaise",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAEMalo') and Casting.CanUseAA("Wind of Malaise") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "AEMaloSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAEMalo') and not Casting.CanUseAA("Wind of Malaise") end,
                cond = function(self, spell, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "Malaise",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTMalo') and Casting.CanUseAA("Malaise") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSTMalo') and not Casting.CanUseAA("Malaise") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow'] = {
            {
                name = "Turgur's Virulent Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and Casting.CanUseAA("Turgur's Virulent Swarm") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "AESlowSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and not Casting.CanUseAA("Turgur's Virulent Swarm") end,
                cond = function(self, spell, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "Turgur's Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and Casting.CanUseAA("Turgur's Swarm") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and not Casting.CanUseAA("Turgur's Swarm") end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSTSlow') or Casting.CanUseAA("Turgur's Swarm") then return false end
                    return Casting.DetSpellCheck(spell) and (spell and spell.RankName.SlowPct() or 0) > Targeting.GetTargetSlowedPct() and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "DiseaseSlow",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDiseaseSlow') end,
                cond = function(self, spell, target)
                    return not mq.TLO.Target.Slowed() and Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['CombatBuff'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "Cannibalization",
                type = "AA",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoAACanni') and Config:GetSetting('DoCombatCanni') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoSpellCanni') and Config:GetSetting('DoCombatCanni') end,
                cond = function(self, spell)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Casting.CanUseAA("Luminary's Synergy") and Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end
                    return Targeting.MobHasLowHP() and spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 30
                end,
            },
        },
        ['DPS'] = {
            {
                name = "TwinHealNuke",
                type = "CustomFunc",
                load_cond = function(self) return Config:GetSetting('DoTwinHealNuke') and self:GetResolvedActionMapItem('TwinHealNuke') end,
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
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "ChaoticDot", "SaryrnDot", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPoisonDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "CurseDot2", "CurseDot1", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoCurseDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "PandemicDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDiseaseDot') end,
                cond = function(self, spell, target)
                    if Core.IsModeActive("Heal") and not Config:GetSetting('DoHealDPS') then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- for hybrid mode, which will use both curses if we have them
                name = "CurseDot1",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoCurseDot') and Core.IsModeActive("Hybrid") and Core.GetResolvedActionMapItem('CurseDot2') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- for hybrid mode, which loads this even after we get chaotic as a dot to use when chaotic is down
                name = "SaryrnDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPoisonDot') and Core.IsModeActive("Hybrid") and Core.GetResolvedActionMapItem('ChaoticDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "AfflictionDot", "UltorDot", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDiseaseDot') end,
                cond = function(self, spell, target)
                    return Globals.AutoTargetIsNamed and Casting.DotSpellCheck(spell)
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "FastPoisonNuke", "PoisonNuke", "IceNuke", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() ~= 0 end,
                cond = function(self, _) return Config:GetSetting('DoPet') and mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell)
                    local pet = mq.TLO.Me.Pet
                    if pet.ID() > 0 then
                        Comms.PrintGroupMessage("Summoned a new %d %s pet named %s using '%s'!", pet.Level(),
                            pet.Class.Name(), pet.CleanName(), spell.RankName())
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "Cannibalization",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAACanni') and Casting.CanUseAA('Cannibalization') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSpellCanni') end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "GroupHealProcBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                cond = function(self, spell)
                    if not Casting.CanUseAA("Luminary's Synergy") or not Config:GetSetting('DoHealOverTime') or not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 30
                end,
            },
            {
                name = "Preincarnation",
                type = "AA",
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName)
                        .Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "PetBuffSpell",
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
        ['SlowDowntime'] = {
            {
                name = "Pact of the Wolf",
                type = "AA",
                active_cond = function(self, aaName) return mq.TLO.Me.Aura(aaName)() ~= nil end,
                cond = function(self, aaName)
                    return Config:GetSetting('DoAura') and not Casting.IHaveBuff(aaName) and
                        mq.TLO.Me.Aura(aaName)() == nil
                end,
            },
            {
                name = "Visionary's Unity",
                type = "AA",
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName)
                        .Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName) --Check ranks because we don't want the first pack buff (drains mana)
                    if (mq.TLO.Me.AltAbility(aaName).Rank() or 999) < 2 then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "PackSelfBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if (mq.TLO.Me.AltAbility("Visionary's Unity").Rank() or 999) > 1 then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "WardBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Config:GetSetting('DoSelfWard') then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Spirit Guardian",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
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
                name = "SlowProcBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsTanking(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            { --Used on the entire group
                name = "GroupFocusSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            { --Only cast below 86 because past that our focus spells take over. Could check which unity we have, but expensive.
                name = "LowLvlAtkBuff",
                type = "Spell",
                load_cond = function(self) return mq.TLO.Me.Level() < 86 end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.CastReady(spell) and
                        Casting.GroupBuffCheck(spell, target)
                end,
            },
            { -- Only cast below 111 because past that our focus spells take over. Could check which unity we have, but expensive.
                name = "Talisman of Celerity",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoHaste') and Casting.CanUseAA("Talisman of Celerity") and mq.TLO.Me.Level() < 111 end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHaste') and not Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleRegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegenBuff') and not Core.GetResolvedActionMapItem('GroupRegenBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return (Targeting.TargetIsTanking(target) or Targeting.TargetIsMyself(target)) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegenBuff') and not Core.GetResolvedActionMapItem('DichoSpell') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Lupine Spirit",
                type = "AA",
                -- We get Tala'tak at 74, but this doesn't use it until 90. Check Ranks.
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') and (mq.TLO.Me.AltAbility("Lupine Spirit").Rank() or -1) > 3 end,
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                -- We get Tala'tak at 74, but Lupine Spirit doesn't use it until 90. Check Ranks.
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') and (mq.TLO.Me.AltAbility("Lupine Spirit").Rank() or -1) < 4 end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Group Shrink",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') and Casting.CanUseAA("Group Shrink") end,
                active_cond = function(self) return mq.TLO.Me.Height() < 2 end,
                cond = function(self, aaName, target)
                    return Targeting.GetTargetHeight(target) > 2.2
                end,
            },
            {
                name = "ShrinkSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') and not Casting.CanUseAA("Group Shrink") end,
                active_cond = function(self) return mq.TLO.Me.Height() < 2 end,
                cond = function(self, spell, target)
                    return Targeting.GetTargetHeight(target) > 2.2
                end,
            },
            {
                name = "LowLvlHPBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLHPBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsTanking(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlAgiBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLAgiBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsTanking(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlStaBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStaBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsTanking(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlStrBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStrBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
    },
    -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
    -- Conditions are not limited to modes. Virtually any helper function or TLO can be used. Example: Level-based lists.
    -- The first list whose conditions returns true will be loaded, all subsequent lists will be ignored.
    -- Loadout checks (such as scribing a spell or using the "Rescan Loadout" or "Reload Spells" buttons) will re-check these lists and may load a different set if things have changed.
    ['SpellList']         = {
        {
            name = "Heal Mode", --This name is abitrary, it is simply what shows up in the UI when this spell list is loaded.
            cond = function(self) return Core.IsModeActive("Heal") end,
            spells = {          -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
                -- Role-Critical
                { name = "RecklessHeal1", },
                { name = "RecourseHeal", },
                { name = "InterventionHeal", },
                { name = "AESpiritualHeal", },
                { name = "RecklessHeal2", },
                { name = "SlowSpell",         cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },          -- 27-77
                { name = "DiseaseSlow",       cond = function(self) return Config:GetSetting('DoDiseaseSlow') end, },
                { name = "AESlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Virulent Swarm") and Config:GetSetting('DoAESlow') end, }, -- 58-79
                { name = "MaloSpell",         cond = function(self) return not Casting.CanUseAA("Malaise") and Config:GetSetting('DoSTMalo') end, },                 -- 47-74
                { name = "AEMaloSpell",       cond = function(self) return not Casting.CanUseAA("Wind of Malaise") and Config:GetSetting('DoAEMalo') end, },         -- 84-94
                { name = "DichoSpell", },
                { name = "MeleeProcBuff",     cond = function(self) return not Core.GetResolvedActionMapItem('DichoSpell') end, },
                { name = "LowLvlAtkBuff",     cond = function(self) return mq.TLO.Me.Level() < 86 end, }, -- 60-85

                -- Utility
                { name = "CanniSpell",        cond = function(self) return Config:GetSetting('DoSpellCanni') end, },   -- 23 - ???
                { name = "GroupRenewalHoT",   cond = function(self) return Config:GetSetting('DoHealOverTime') end, }, -- 44-125 Heal
                { name = "SingleRegenBuff",   cond = function(self) return Config:GetSetting('DoRegenBuff') and not Core.GetResolvedActionMapItem('GroupRegenBuff') end, },
                { name = "TempHPBuff",        cond = function(self) return Config:GetSetting('DoTempHP') end, },       -- 81-125
                { name = "CureSpell",         cond = function(self) return Config:GetSetting('MemCureSpell') end, },

                -- DPS
                { name = "ChaoticDot",        cond = function(self) return Config:GetSetting('DoPoisonDot') end, },                                                     -- 104-125
                { name = "SaryrnDot",         cond = function(self) return not Core.GetResolvedActionMapItem('ChaoticDot') and Config:GetSetting('DoPoisonDot') end, }, -- 8-?? Heal, 8-125 Hybrid
                { name = "PandemicDot",       cond = function(self) return Config:GetSetting('DoDiseaseDot') end, },                                                    -- 103-125
                { name = "TwinHealNuke",      cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },                                                  -- 85-125
                { name = "FastPoisonNuke",    cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "PoisonNuke",        cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('FastPoisonNuke') end, },
                { name = "IceNuke",           cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('PoisonNuke') end, },
                { name = "CurseDot2",         cond = function(self) return Config:GetSetting('DoCurseDot') end, },                                                          -- 100-125
                { name = "CurseDot1",         cond = function(self) return Config:GetSetting('DoCurseDot') and not Core.GetResolvedActionMapItem('CurseDot2') end, },       -- 34-??? Heal, 34-125 Hybrid
                { name = "AfflictionDot",     cond = function(self) return not Core.GetResolvedActionMapItem('PandemicDot') and Config:GetSetting('DoDiseaseDot') end, },   -- 92-125 (Boss Only)
                { name = "UltorDot",          cond = function(self) return not Core.GetResolvedActionMapItem('AfflictionDot') and Config:GetSetting('DoDiseaseDot') end, }, -- 4-91 (Boss Only)

                -- Filler
                { name = "CurePoison",        cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureDisease",       cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureCurse",         cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "GroupHealProcBuff", }, -- 101-125,
                { name = "RecklessHeal3", },
                { name = "SlowProcBuff", },
            },
        },
        {
            name = "Hybrid Mode",
            cond = function(self) return Core.IsModeActive("Hybrid") end,
            spells = {
                -- Role-Critical
                { name = "RecklessHeal1", },
                { name = "RecourseHeal", },
                { name = "InterventionHeal", },
                { name = "AESpiritualHeal", },
                { name = "SlowSpell",         cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },          -- 27-77
                { name = "DiseaseSlow",       cond = function(self) return Config:GetSetting('DoDiseaseSlow') end, },
                { name = "AESlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Virulent Swarm") and Config:GetSetting('DoAESlow') end, }, -- 58-79
                { name = "MaloSpell",         cond = function(self) return not Casting.CanUseAA("Malaise") and Config:GetSetting('DoSTMalo') end, },                 -- 47-74
                { name = "AEMaloSpell",       cond = function(self) return not Casting.CanUseAA("Wind of Malaise") and Config:GetSetting('DoAEMalo') end, },         -- 84-94
                { name = "DichoSpell", },
                { name = "MeleeProcBuff",     cond = function(self) return not Core.GetResolvedActionMapItem('DichoSpell') end, },
                { name = "LowLvlAtkBuff",     cond = function(self) return mq.TLO.Me.Level() < 86 end, },

                -- DPS
                { name = "ChaoticDot",        cond = function(self) return Config:GetSetting('DoPoisonDot') end, },                                                     -- 104-125
                { name = "SaryrnDot",         cond = function(self) return not Core.GetResolvedActionMapItem('ChaoticDot') and Config:GetSetting('DoPoisonDot') end, }, -- 8-?? Heal, 8-125 Hybrid
                { name = "PandemicDot",       cond = function(self) return Config:GetSetting('DoDiseaseDot') end, },                                                    -- 103-125
                { name = "FastPoisonNuke",    cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "PoisonNuke",        cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('FastPoisonNuke') end, },
                { name = "IceNuke",           cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('PoisonNuke') end, },
                { name = "CurseDot2",         cond = function(self) return Config:GetSetting('DoCurseDot') end, },                                                          -- 100-125
                { name = "CurseDot1",         cond = function(self) return Config:GetSetting('DoCurseDot') end, },                                                          -- 34-??? Heal, 34-125 Hybrid
                { name = "SaryrnDot",         cond = function(self) return Config:GetSetting('DoPoisonDot') end, },                                                         -- backup for if Chaotic is Down
                { name = "AfflictionDot",     cond = function(self) return Config:GetSetting('DoDiseaseDot') end, },                                                        -- 92-125 (Boss Only)
                { name = "UltorDot",          cond = function(self) return not Core.GetResolvedActionMapItem('AfflictionDot') and Config:GetSetting('DoDiseaseDot') end, }, -- 4-91 (Boss Only)
                { name = "PoisonNuke",        cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "TwinHealNuke",      cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },                                                      -- 85-125

                -- Utility, Filler
                { name = "CanniSpell",        cond = function(self) return Config:GetSetting('DoSpellCanni') end, },   -- 23 - ???
                { name = "GroupRenewalHoT",   cond = function(self) return Config:GetSetting('DoHealOverTime') end, }, -- 44-125 Heal
                { name = "SingleRegenBuff",   cond = function(self) return Config:GetSetting('DoRegenBuff') and not Core.GetResolvedActionMapItem('GroupRegenBuff') end, },
                { name = "TempHPBuff",        cond = function(self) return Config:GetSetting('DoTempHP') end, },       -- 81-125
                { name = "TwinHealNuke",      cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, }, -- 85-125
                { name = "CureSpell",         cond = function(self) return Config:GetSetting('MemCureSpell') end, },
                { name = "CurePoison",        cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureDisease",       cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureCurse",         cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "RecklessHeal2", },
                { name = "GroupHealProcBuff", }, -- 101-125,
                { name = "SlowProcBuff", },
            },
        },
    },
    ['PullAbilities']     = {
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
        {
            id = 'SaryrnDot',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('SaryrnDot')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('SaryrnDot')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('SaryrnDot')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'NukeSpell',
            Type = "Spell",
            DisplayName = function()
                local resolved = Core.GetResolvedActionMapItem(Casting.GetFirstMapItem({ "FastPoisonNuke", "PoisonNuke", "IceNuke", }))
                return resolved and resolved() or ""
            end,
            AbilityName = function()
                local resolved = Core.GetResolvedActionMapItem(Casting.GetFirstMapItem({ "FastPoisonNuke", "PoisonNuke", "IceNuke", }))
                return resolved and resolved() or ""
            end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem(Casting.GetFirstMapItem({ "FastPoisonNuke", "PoisonNuke", "IceNuke", }))
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']     = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes do?",
            Answer =
            "Heal Mode: Primarily focuses on healing, cures, and maintaining HoTs. Secondary DPS focus with remaining spell gems. Hybrid: Prioritizes slightly more DPS at the expense of keeping a HoT, Cure Spell and second Reckless heal memorized.",
        },

        --DPS
        ['DoHealDPS']         = {
            DisplayName = "Heal Mode DPS",
            Group = "Abilities",
            Header = "Common",
            Category = "Common Rules",
            Index = 101,
            Tooltip = "This is a top-level setting that governs any DPS spells in heal mode, and can be used as a quick-toggle to enable/disable abilities without reloading spells.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "I feel that my Shaman is too concerned with DPS, dots and nukes, what can be done?",
            Answer = "Disabling Use HealDPS will stop the use of these spells. You can control which individual spells you mem with their respective settings.",
        },
        ['DoNuke']            = {
            DisplayName = "Use Nukes",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use a level-appropriate single-target nuke.\n" ..
                "Heal Mode: We will choose one avaiable nuke: Fast Poison (Bite) > Poison (Venom) > Ice.\n" ..
                "Hybrid Mode: Uses Fast Poison (Bite) and Poison (Venom), and Ice Nuke before they are available.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTwinHealNuke']    = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why am I using the Twin Heal Nuke?",
            Answer =
            "Due to the nature of automation, we are likely to have the time to do so, and it helps hedge our bets against spike damage. Drivers that manually target switch may wish to disable this setting to allow for more cross-dotting. ",
        },
        ['DoPoisonDot']       = {
            DisplayName = "Use Poison DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use one or more mode- and level-appropriate poison dots.\n" ..
                "Heal Mode: Saryrn line is used until Chaotic line is available.\n" ..
                "Hybrid Mode: Both Curse lines are used.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoDiseaseDot']      = {
            DisplayName = "Use Disease DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use one or more mode- and level-appropriate poison dots.\n" ..
                "Heal Mode: Uses the best of Pandemic > Afflicition > Ultor on named.\n" ..
                "Hybrid Mode: Uses Pandemic and Affliction on named, and Ultor before they are available.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoCurseDot']        = {
            DisplayName = "Use Curse DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use one or more mode- and level-appropriate curse dots.\n" ..
                "Heal Mode: Curse line is used until X's Curse line is available.\n" ..
                "Hybrid Mode: Both Curse lines are used.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        -- Healing
        ['DoHealOverTime']    = {
            DisplayName = "Use HoTs",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Heal Mode: Use Heal Over Time Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why does my Shaman randomly use HoTs in downtime?",
            Answer = "Maintaining HoTs prevents emergencies and hopefully allows for better DPS. It also grants Synergy Procs at high level.",
        },
        ['MemCureSpell']      = {
            DisplayName = "Mem Cure Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Mem your cure spells:\n" ..
                "Heal Mode: Prioritizes the combined cure spell. Memorizes others if able, if the combined spell isn't available.\n" ..
                "Hybrid Mode: Will memorize cure spells, if able, after other selected DPS spells have been prioritized.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoChestClick']      = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
            FAQ = "What the heck is a chest click?",
            Answer = "Most classes have useful abilities on their equipped chest after level 75 or so. The SHM's is generally a healing tool (emergency group heal).",
        },
        --Canni
        ['DoAACanni']         = {
            DisplayName = "Use AA Canni",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip = "Use Canni AA",
            Default = true,
            ConfigType = "Advanced",
        },
        ['AACanniManaPct']    = {
            DisplayName = "AA Canni Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 105,
            Tooltip = "Use Canni AA Under [X]% mana",
            Default = 70,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['AACanniMinHP']      = {
            DisplayName = "AA Canni HP %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 106,
            Tooltip = "Dont Use Canni AA Under [X]% HP",
            Default = 90,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoSpellCanni']      = {
            DisplayName = "Use Spell Canni",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Mem and use Canni Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['SpellCanniManaPct'] = {
            DisplayName = "Spell Canni Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "Use Canni Spell Under [X]% mana",
            Default = 70,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['SpellCanniMinHP']   = {
            DisplayName = "Spell Canni HP %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            Tooltip = "Dont Use Canni Spell Under [X]% HP",
            Default = 85,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoCombatCanni']     = {
            DisplayName = "Canni in Combat",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 107,
            Tooltip = "Use Canni AA and Spells in combat",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        --Buffs
        ['UseEpic']           = {
            DisplayName = "Epic Use:",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Use Epic 1-Never 2-Burns 3-Always",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoRunSpeed']        = {
            DisplayName = "Do Run Speed",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Do Run Speed Spells/AAs",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why are my buffers in a run speed buff war?",
            Answer = "Many run speed spells freely stack and overwrite each other, you will need to disable Run Speed Buffs on some of the buffers.",
        },
        ['DoGroupShrink']     = {
            DisplayName = "Group Shrink",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip = "Use Group Shrink Buff",
            Default = true,
            FAQ = "Group Shrink is enabled, why are my dudes still big?",
            Answer =
            "For simplicity, the check to use it is keyed to the Shaman's height, rather than checking each group member. Also, the AA isn't available until level 80 (on official servers).",
        },
        ['DoTempHP']          = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use Temp HP Buff on Warriors in the group.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoAura']            = {
            DisplayName = "Use Aura",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Use Aura (Pact of Wolf)",
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoRegenBuff']       = {
            DisplayName = "Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your Regen buff (best of single or group versions).",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoHaste']           = {
            DisplayName = "Use Haste",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Do Haste Spells/AAs",
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why aren't I casting Talisman of Celerity or other haste buffs?",
            Answer = "Even with Use Haste enabled, these buffs are part of your Focus spell (Unity) at very high levels, so they may not be needed.",
        },
        ['DoSelfWard']        = {
            DisplayName = "Do Self Ward",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use your Ward of... self-heal ward buff line.",
            Default = true,
        },
        ['DoVetAA']           = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        --Debuffs
        ['DoSTMalo']          = {
            DisplayName = "Do ST Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Do ST Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAEMalo']          = {
            DisplayName = "Do AE Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "Do AE Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSTSlow']          = {
            DisplayName = "Do ST Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = "Do ST Slow Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAESlow']          = {
            DisplayName = "Do AE Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 102,
            Tooltip = "Do AE Slow Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['AESlowCount']       = {
            DisplayName = "AE Slow Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 103,
            Tooltip = "Number of XT Haters before we use AE Slow.",
            Min = 1,
            Default = 2,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['AEMaloCount']       = {
            DisplayName = "AE Malo Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 103,
            Tooltip = "Number of XT Haters before we use AE Malo.",
            Min = 1,
            Default = 2,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['DoDiseaseSlow']     = {
            DisplayName = "Disease Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 104,
            Tooltip = "Use Disease Slow instead of normal ST Slow",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLHPBuff']        = {
            DisplayName = "HP Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLAgiBuff']       = {
            DisplayName = "Agility Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStaBuff']       = {
            DisplayName = "Stamina Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 109,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStrBuff']       = {
            DisplayName = "Strength Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 110,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
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
