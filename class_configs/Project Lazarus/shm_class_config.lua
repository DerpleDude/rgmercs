local mq           = require('mq')
local Casting      = require("utils.casting")
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "3.1 - Project Lazarus",
    _author               = "Algar, Derple",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCures') end,
        IsRezing = function()
            return (Core.GetResolvedActionMapItem('RezSpell') and Targeting.GetXTHaterCount() == 0) or
                ((Casting.CanUseAA("Call of the Wild") or mq.TLO.FindItem("=Staff of Forbidden Rites")()) and Config:GetSetting('DoBattleRez'))
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
                    return Casting.DowntimeRezOkay() and not Casting.CanUseAA('Rejuvenation of Spirit')
                end,
            },
        },
    },
    ['Modes']             = {
        'Heal',
        'Hybrid',
    },
    ['PetPosition']       = {
        SummonAA = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        --  RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
            { type = "AA", name = "Purified Spirits", selfOnly = true, },
        },
        ['Poison'] = {
            {
                type = "Spell",
                name = "GroupHeal",
                load_cond = function(self)
                    return self.Helpers.UseGroupHealCure(self)
                end,
            },
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'CurePoison', }) end, },
        },
        ['Disease'] = {
            {
                type = "Spell",
                name = "GroupHeal",
                load_cond = function(self)
                    return self.Helpers
                        .UseGroupHealCure(self)
                end,
            },
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'GroupCure', 'CureDisease', }) end, },
        },
        ['Curse'] = {
            { type = "Spell", name = "GroupHeal", load_cond = function(self) return self.Helpers.UseGroupHealCure(self, 'KeepCurseMemmed') end, },
            { type = "Spell", name = "CureCurse", },
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
        ['OoW_Chest'] = {
            "Ritualchanter's Tunic of the Ancestors",
            "Spiritkin Tunic",
        },
    },
    ['AbilitySets']       = {
        ['GroupFocusSpell'] = {
            -- Focus Spell - Group Spells will be used on everyone
            "Talisman of the Stillmoon", -- Level 71 Laz Custom
            "Talisman of Wunshi",        -- Level 70, - Group
            "Focus of the Seventh",      -- Level 65, - Group
            "Khura's Focusing",          -- Level 60, - Group
            "Infusion of Spirit",        -- Level 49, Str/Dex/Sta, can use HP buff. Not sure if this is the final home for this one or not.
        },
        ['RunSpeedBuff'] = {
            -- Run Speed Buff - 9 - 74
            "Spirit of Bih`Li", -- Level 36
            "Pack Shrew",       -- Level 34
            "Spirit of Wolf",   -- Level 9
        },
        ['HasteBuff'] = {
            "Swift Like the Wind", -- Level 63
            "Celerity",            -- Level 56
            "Alacrity",            -- Level 42
            "Quickness",           -- Level 26
        },
        ['GroupHasteBuff'] = {
            "Talisman of Celerity",    -- Level 64
        },
        ['Unification'] = {            -- Many buffs combined: 75 Sta, 50 sta cap, 7% evasion, 5% damage
            "Talisman of Coalescence", -- Level 71 Laz Custom
            "Talisman of Unification", -- Level 70 Laz Custom
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
            "Champion",              -- Level 70
            "Ferine Avatar",         -- Level 65
            "Ancient: Feral Avatar", -- Level 60
            "Primal Avatar",         -- Level 60
            "Harnessing of Spirit",  -- Level 46
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
            "Talisman of Sense",      -- Level 68
            "Spirit of Sense",        -- Level 66
            "Talisman of the Wrulan", -- Level 62
            "Agility of the Wrulan",  -- Level 61
            "Talisman of the Cat",    -- Level 57
            "Deliriously Nimble",     -- Level 53
            "Agility",                -- Level 41
            "Nimble",                 -- Level 31
            "Spirit of Cat",          -- Level 18
            "Feet like Cat",          -- Level 3
        },
        ['AEMaloSpell'] = {
            "Idol of Malos", -- Level 70
        },
        ['MaloSpell'] = {
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
        ['CrippleSpell'] = {     -- needs to be added to spell list and have entries made
            "Crippling Spasm",   -- Level 66
            "Cripple",           -- Level 53, Starts to become worth it, depending on target
            "Incapacitate",      -- Level 41, Likely not worth
            "Listless Power",    -- Level 29, Definitely not worth
        },
        ['MeleeProcBuff'] = {
            "Talisman of the Cougar",  -- Level 71 Laz Custom
            "Talisman of the Panther", -- Level 70
            "Spirit of the Panther",   -- Level 69
            "Spirit of the Leopard",   -- Level 61
            "Spirit of the Jaguar",    -- Level 57
            "Spirit of the Puma",      -- Level 50
        },
        ['SlowProcBuff'] = {
            "Shadowy Sloth",   -- Level 71 Laz Custom
            "Lingering Sloth", -- Level 68
        },
        ['RezSpell'] = {
            'Incarnate Anew', -- Level 59
            'Resuscitate',    -- Level 49 Laz Custom
            'Revive',         -- Level 39 Laz Custom
            'Reanimation',    -- Level 29 Laz Custom
        },
        ['HealSpell'] = {
            -- "Ancient: Emoush's Mending", -- Level 71 Laz Custom, verify existence and source
            "Ancient: Wilslik's Mending", -- Level 70
            "Yoppa's Mending",            -- Level 68
            "Daluda's Mending",           -- Level 65
            "Tnarg's Mending",            -- Level 62
            "Chloroblast",                -- Level 55
            "Kragg's Salve",              -- Level 49
            "Superior Healing",           -- Level 45
            "Spirit Salve",               -- Level 39
            "Greater Healing",            -- Level 29
            "Healing",                    -- Level 19
            "Light Healing",              -- Level 9
            "Minor Healing",              -- Level 1
        },
        ['GroupHeal'] = {                 -- Laz specific, some taken from cleric, some custom
            "Word of Reconstitution",     -- Level 70 Laz Custom
            "Word of Redemption",         -- Level 65
            "Word of Restoration",        -- Level 62
            "Word of Vigor",              -- Level 56
            "Word of Healing",            -- Level 50
            "Word of Health",             -- Level 40
        },
        ['GroupRenewalHoT'] = {
            --This seems entirely not worth using since they were given direct group heals
            "Ghost of Renewal", -- Level 70
        },
        ['SnareHot'] = {
            "Transcendental Torpor", -- Level 71 Laz Custom
            "Transcendent Torpor",   -- Level 70 Laz Custom
            "Torpor",                -- Level 60
            "Stoicism",              -- Level 44
        },
        ['SingleHot'] = {            -- some elixirs given to shm/dru on laz
            "Spiritual Serenity",    -- Level 70
            "Breath of Trushar",     -- Level 65
            "Quiescence",            -- Level 65
            -- "Celestial Elixir", -- Level 65, Quiescence same level and better
            "Celestial Healing",     -- Level 49
            "Celestial Health",      -- Level 35
            "Celestial Remedy",      -- Level 25
        },
        ['CanniSpell'] = {
            -- Convert Health to Mana - Level  23 -
            "Ancient: Ancestral Calling", -- Level 70
            "Pained Memory",              -- Level 68
            "Ancient: Chaotic Pain",      -- Level 65
            "Cannibalize IV",             -- Level 58
            "Cannibalize III",            -- Level 54
            "Cannibalize II",             -- Level 38
            "Cannibalize",                -- Level 23
        },
        -- ['CureSpell'] = { --This is not useful in light of the alternatives
        --     "Blood of Nadox", -- Level 52
        -- },
        ['TwinHealNuke'] = {
            -- Nuke the MA Not the assist target - Levels 70
            "Frostfall Boon", -- Level 70 Laz Custom
        },
        ['PoisonNuke'] = {
            -- Poison Nuke LVL34 +
            "Yoppa's Spear of Venom", -- Level 66
            "Spear of Torment",       -- Level 61
            "Blast of Venom",         -- Level 54
            "Shock of Venom",         -- Level 47
            "Blast of Poison",        -- Level 42
            "Shock of the Tainted",   -- Level 34
        },
        ['ColdNuke'] = {
            --- ColdNuke - Level 4+
            -- "Dire Avalanche", -- Level 70, In resources but not scribable I think?
            "Ice Age",        -- Level 69
            "Velium Strike",  -- Level 64
            "Ice Strike",     -- Level 54
            "Blizzard Blast", -- Level 44
            "Winter's Roar",  -- Level 33
            "Frost Strike",   -- Level 23
            "Spirit Strike",  -- Level 14
            "Frost Rift",     -- Level 4
        },
        ['CurseDot'] = {
            -- Curse Dot 1 Stacking: Curse - Long Dot(30s) - Level 34+
            "Curse of Emoush",  -- Level 71 Laz Custom
            "Curse of Sisslak", -- Level 69
            "Bane",             -- Level 64
            "Anathema",         -- Level 54
            "Odium",            -- Level 43
            "Curse",            -- Level 34
        },
        ['SaryrnDot'] = {
            -- Stacking: Blood of Saryrn - Long Dot(42s) - Level 8+
            "Blood of Volkara",         -- Level 71 Laz Custom
            "Nectar of Pain",           -- Level 70
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
            "Breath of Shadows",       -- Level 71 Laz Custom
            "Breath of Wunshi",        -- Level 67
            "Breath of Ultor",         -- Level 64
            "Pox of Bertoxxulous",     -- Level 59
            "Plague",                  -- Level 49
            "Scourge",                 -- Level 31
            "Affliction",              -- Level 19
            "Sicken",                  -- Level 4
        },
        ['AEDot'] = {                  -- do homework for Laz
            "Blood of Yoppa",          -- Level 70
        },
        ['PetSpell'] = {               --We need to add handling for commune to get the mammoth/etc
            -- Pet Spell - 32+
            "Gray Elephant Companion", -- Level 71 Laz Custom
            -- "Cunning Lioness Companion", -- Level 71 Laz Custom
            -- "Black Scorpion Companion",  -- Level 71 Laz Custom
            -- "Wooly Rhino Companion",     -- Level 71 Laz Custom
            -- "Blood Raptor Companion",    -- Level 71 Laz Custom
            -- "Sea Cow Companion",         -- Level 71 Laz Custom
            "Commune with the Wild", -- Level 70 Laz Custom
            "Farrel's Companion",    -- Level 67
            "True Spirit",           -- Level 61
            "Spirit of the Howler",  -- Level 55
            "Frenzied Spirit",       -- Level 45
            "Guardian Spirit",       -- Level 41
            "Vigilant Spirit",       -- Level 37
            "Companion Spirit",      -- Level 32
        },
        -- ['PetBuffSpell'] = { -- Haste is generally better
        --     ---Pet Buff Spell - 50+
        --     "Spirit Quickening", -- Level 50
        -- },
        ['CurePoison'] = {
            -- "Eradicate Poison", -- Level 56
            "Counteract Poison", -- Level 26
            "Cure Poison",       -- Level 2
        },
        ['CureDisease'] = {
            -- "Eradicate Disease", -- Level 52
            "Counteract Disease", -- Level 22
            "Cure Disease",       -- Level 1
        },
        ['CureCurse'] = {
            -- "Eradicate Curse",   -- Level 54
            "Remove Greater Curse", -- Level 54
            "Remove Curse",         -- Level 38
            "Remove Lesser Curse",  -- Level 24
            "Remove Minor Curse",   -- Level 9
        },
        ['GroupCure'] = {
            "Blood of Nadox", -- Level 52
        },
        ['GroupRegenBuff'] = {
            "Talisman of Perseverance", -- Level 69
            "Regrowth of Dar Khura",    -- Level 56
        },
        ['SingleRegenBuff'] = {
            "Regrowth",     -- Level 52
            "Chloroplast",  -- Level 39
            "Regeneration", -- Level 23
        },
        ['ShrinkSpell'] = {
            "Shrink",       -- Level 15
        },
        ['PutridDecay'] = { -- Level 66 Poi/Dis resist debuff
            "Putrid Decay", -- Level 66
        },
    },
    ['Charm']             = {
        ['Assist'] = {
            {
                name = "Malosinete",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSTMalo') then return false end
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSTMalo') or Casting.CanUseAA("Malosinete") then return false end
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
    },
    ['Helpers']           = {
        UseGroupHealCure = function(self, keepSetting)
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHeal')
            return Config:GetSetting('GroupHealAsCure') and (not keepSetting or not Config:GetSetting(keepSetting)) and (ghealSpell and ghealSpell.Level() or 0) >= 70
        end,
    },
    -- These are handled differently from normal rotations in that we try to make some intelligent desicions about which spells to use instead
    -- of just slamming through the base ordered list.
    -- These will run in order and exit after the first valid spell to cast
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
                name = "Call of the Ancients",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigHealsNeeded(target)
                end,
            },
            {
                name = "GroupHeal",
                type = "Spell",
            },
        },
        ['BigHealPoint'] = {
            {
                name = "SnareHot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSnareHot') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Ancestral Guard",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Zun'Muram's Spear of Doom",
                type = "Item",
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
                name = "Armor of Ancestral Spirits",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
        },
        ['MainHealPoint'] = {
            {
                name = "SingleHot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSingleHot') end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
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
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
            name = 'PutridDecay',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoPutrid') and Core.GetResolvedActionMapItem("PutridDecay") end,
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
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Buff("Focus of Arcanum")() and Core.CombatActionsCheck()
            end,
        },

    },
    ['Rotations']         = {
        ['ProcBuff'] = {
            {
                name = "MeleeProcBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SlowProcBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsTanking(target) and Casting.GroupBuffCheck(spell, target)
                end,
                post_activate = function(self, spell, success)
                    local petName = mq.TLO.Me.Pet.CleanName() or "None"
                    mq.delay("3s", function() return not mq.TLO.Me.Casting() end)
                    if success and mq.TLO.Me.XTarget(petName)() then
                        Comms.PrintGroupMessage("It seems %s has triggered combat due to a server bug, calling the pet back.", spell)
                        Core.DoCmd('/pet back off')
                    end
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
                name = "Fundament: Second Spire of Ancestors",
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
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Spirit Call",
                type = "AA",
            },
            {
                name = "Extended Pestilence",
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
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Spear of Fate",
                type = "Item",
                cond = function(self, itemName, target)
                    return Globals.AutoTargetIsNamed and Casting.DotItemCheck(itemName, target)
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "Shattered Gnoll Slayer",
                type = "Item",
            },
        },
        ['Malo'] = {
            {
                name = "AEMaloSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAEMalo') then return false end
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "Malosinete",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSTMalo') then return false end
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSTMalo') or Casting.CanUseAA("Malosinete") then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow'] = {
            {
                name = "Tigir's Insect Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and Casting.CanUseAA("Tigir's Insect Swarm") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "AESlowSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and not Casting.CanUseAA("Tigir's Insect Swarm") end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAESlow') or Casting.CanUseAA("Tigir's Insect Swarm") then return false end
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "Turgur's Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and (Casting.CanUseAA("Turgur's Swarm") and not Config:GetSetting('DoDiseaseSlow')) end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name_func = function(self)
                    return Config:GetSetting('DoDiseaseSlow') and "DiseaseSlow" or "SlowSpell"
                end,
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and (not Casting.CanUseAA("Turgur's Swarm") or Config:GetSetting('DoDiseaseSlow')) end,
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (spell and spell.RankName.SlowPct() or 0) > Targeting.GetTargetSlowedPct() and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['PutridDecay'] = {
            {
                name = "PutridDecay",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "CurseDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoCurseDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "SaryrnDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSaryrnDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "UltorDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoUltorDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Cannibalization",
                type = "AA",
                allowDead = true,
                cond = function(self, aaName)
                    if not (Config:GetSetting('DoAACanni') and Config:GetSetting('DoCombatCanni')) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell)
                    if not (Config:GetSetting('DoSpellCanni') and Config:GetSetting('DoCombatCanni')) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            { -- in-game description is incorrect, mob must be targeted.
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoTwinHealNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true) and not Casting.IHaveBuff("Twincast")
                end,
            },
            {
                name = "ColdNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoColdNuke') then return false end
                    return (Targeting.MobHasLowHP or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed)) and Casting.OkayToNuke(true)
                end,
            },
            {
                name = "PoisonNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoPoisonNuke') then return false end
                    return (Targeting.MobHasLowHP or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed)) and Casting.OkayToNuke(true)
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() ~= 0 end,
                cond = function(self, _) return Config:GetSetting('DoPet') and mq.TLO.Me.Pet.ID() == 0 end,
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
                name = "Cannibalization",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoAACanni') and mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoSpellCanni') and Casting.CastReady(spell) and mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and
                        mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "Pact of the Wolf",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['PetBuff'] = { -- pet haste is a little messy here because pets cant receive group v2 spells without pet affinity.
            {
                name = "Talisman of Celerity",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoHaste') and Casting.CanUseAA("Pet Affinity") and Casting.CanUseAA("Talisman of Celerity") end,
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name_func = function(self) return Casting.GetFirstMapItem(Casting.CanUseAA("Pet Affinity") and { 'GroupHasteBuff', 'HasteBuff', } or { 'HasteBuff', }) end,
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHaste') and not (Casting.CanUseAA("Pet Affinity") and Casting.CanUseAA("Talisman of Celerity")) end,
                cond = function(self, spell, target)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "Fortify Companion",
                type = "AA",
                active_cond = function(self, aaName) return mq.TLO.Me.PetBuff(aaName)() ~= nil end,
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Crystalized Soul Gem", -- This isn't a typo
                type = "Item",
                cond = function(self, itemName)
                    return Casting.PetBuffItemCheck(itemName)
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
                name = "GroupFocusSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Unification",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            { --Fix this, some priests will want this, adjust options
                name = "LowLvlAtkBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Talisman of Celerity",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoHaste') and Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name_func = function(self) return Casting.GetFirstMapItem({ 'GroupHasteBuff', 'HasteBuff', }) end,
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHaste') and not Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegenBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
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
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, spell, target) --We get Tala'tak at 74, but don't get the AA version until 90
                    if (mq.TLO.Me.AltAbility("Lupine Spirit").Rank() or -1) > 3 then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Group Shrink",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') end,
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
        ['ArcanumWeave'] = {
            {
                name = "Empowered Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Enlightened Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Acute Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
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
                { name = "HealSpell", },
                { name = "SingleHot", cond = function(self) return Config:GetSetting('DoSingleHot') end, },
                { name = "SnareHot",  cond = function(self) return Config:GetSetting('DoSnareHot') end, },
                { name = "GroupHeal", },
                {
                    name = "GroupCure",
                    cond = function(self)
                        return (Config:GetSetting('KeepDiseaseMemmed') or Config:GetSetting('KeepPoisonMemmed')) and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CurePoison",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepPoisonMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CureDisease",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepDiseaseMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "SlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSpell",     cond = function(self) return not Casting.CanUseAA("Tigir's Insect Swarm") and Config:GetSetting('DoAESlow') end, },
                { name = "DiseaseSlow",     cond = function(self) return Config:GetSetting('DoSTSlow') and Config:GetSetting('DoDiseaseSlow') end, },
                { name = "MaloSpell",       cond = function(self) return not Casting.CanUseAA("Malosinete") and Config:GetSetting('DoSTMalo') end, },
                { name = "AEMaloSpell",     cond = function(self) return Config:GetSetting('DoAEMalo') end, },
                { name = "PutridDecay",     cond = function(self) return Config:GetSetting('DoPutrid') end, },
                { name = "CanniSpell",      cond = function(self) return Config:GetSetting('DoSpellCanni') end, },
                { name = "MeleeProcBuff", },
                { name = "SlowProcBuff", },
                { name = "LowLvlAtkBuff", },
                { name = "SingleRegenBuff", cond = function(self) return not Core.GetResolvedActionMapItem('GroupRegenBuff') and Config:GetSetting('DoRegenBuff') end, },
                { name = "TwinHealNuke",    cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "ColdNuke",        cond = function(self) return Config:GetSetting('DoColdNuke') end, },
                { name = "PoisonNuke",      cond = function(self) return Config:GetSetting('DoPoisonNuke') end, },
                { name = "GroupCure",       cond = function(self) return Config:GetSetting('KeepPoisonMemmed') or Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CurePoison",      cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",     cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "CurseDot",        cond = function(self) return Config:GetSetting('DoCurseDot') end, },
                { name = "SaryrnDot",       cond = function(self) return Config:GetSetting('DoSaryrnDot') end, },
                { name = "UltorDot",        cond = function(self) return Config:GetSetting('DoUltorDot') end, },
            },
        },
        {
            name = "Hybrid Mode",
            cond = function(self) return Core.IsModeActive("Hybrid") end,
            spells = {
                { name = "HealSpell", },
                { name = "SlowSpell",     cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSpell",   cond = function(self) return not Casting.CanUseAA("Tigir's Insect Swarm") and Config:GetSetting('DoAESlow') end, },
                { name = "DiseaseSlow",   cond = function(self) return Config:GetSetting('DoSTSlow') and Config:GetSetting('DoDiseaseSlow') end, },
                { name = "MaloSpell",     cond = function(self) return not Casting.CanUseAA("Malosinete") and Config:GetSetting('DoSTMalo') end, },
                { name = "AEMaloSpell",   cond = function(self) return Config:GetSetting('DoAEMalo') end, },
                { name = "PutridDecay",   cond = function(self) return Config:GetSetting('DoPutrid') end, },
                { name = "CanniSpell",    cond = function(self) return Config:GetSetting('DoSpellCanni') end, },
                { name = "MeleeProcBuff", },
                { name = "SlowProcBuff", },
                { name = "LowLvlAtkBuff", },
                { name = "ColdNuke",      cond = function(self) return Config:GetSetting('DoColdNuke') end, },
                { name = "PoisonNuke",    cond = function(self) return Config:GetSetting('DoPoisonNuke') end, },
                { name = "CurseDot",      cond = function(self) return Config:GetSetting('DoCurseDot') end, },
                { name = "SaryrnDot",     cond = function(self) return Config:GetSetting('DoSaryrnDot') end, },
                { name = "UltorDot",      cond = function(self) return Config:GetSetting('DoUltorDot') end, },
                { name = "TwinHealNuke",  cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "SingleHot",     cond = function(self) return Config:GetSetting('DoSingleHot') end, },
                { name = "SnareHot",      cond = function(self) return Config:GetSetting('DoSnareHot') end, },
                { name = "GroupHeal", },
                { name = "GroupCure",     cond = function(self) return Config:GetSetting('KeepPoisonMemmed') or Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CurePoison",    cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",   cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",     cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
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
            id = 'DDSpell',
            Type = "Spell",
            DisplayName = "Burst of Flame",
            AbilityName = "Burst of Flame",
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = mq.TLO.Spell("Burst of Flame")
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
            "Heal Mode: Primarily focuses on healing, cures, and maintaining HoTs. Secondary DPS focus with remaining spell gems. Hybrid: Prioritizes DPS spells over some utility healing abilities on the spell bar.",
        },

        -- Damage
        ['DoColdNuke']        = {
            DisplayName = "Cold Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your single-target cold nukes.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoPoisonNuke']      = {
            DisplayName = "Poison Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your single-target poison nukes.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTwinHealNuke']    = {
            DisplayName = "Twinheal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your twinheal nuke (cold damage with a twinheal buff effect).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSaryrnDot']       = {
            DisplayName = "Poison Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Saryrn line of dots (poison damage, single target).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoUltorDot']        = {
            DisplayName = "Disease Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your Ultor line of dots (disease damage, single target).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoCurseDot']        = {
            DisplayName = "Magic Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use your Curse line of dots (magic damage, single target).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DotNamedOnly']      = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
        },

        -- Healing
        ['DoSingleHot']       = {
            DisplayName = "Use Single HoT",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use single target (non-snaring) HoTs like Spiritual Serenity as a main heal.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoSnareHot']        = {
            DisplayName = "Use Snare HoT",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use snaring HoTs like torpor when HP is very low.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepPoisonMemmed']  = {
            DisplayName = "Mem Cure Poison",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Memorize cure poison spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepDiseaseMemmed'] = {
            DisplayName = "Mem Cure Disease",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Memorize cure disease spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepCurseMemmed']   = {
            DisplayName = "Mem Remove Curse",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 103,
            Tooltip = "Memorize remove curse spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['GroupHealAsCure']   = {
            DisplayName = "Use Group Heal to Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 104,
            Tooltip = "If Word of Reconstitution is available, use this to cure instead of individual cure spells. \n" ..
                "Please note that we will prioritize Remove Greater Curse if you have selected to keep it memmed as above (due to the counter disparity).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },

        -- Canni
        ['DoAACanni']         = {
            DisplayName = "Use AA Canni",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip = "Use Canni AA",
            RequiresLoadoutChange = true, -- This is a load condition
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
            Default = true,
            ConfigType = "Advanced",
        },

        -- Buffs
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
            "For simplicity, the check to use it is keyed to the Shaman's height, rather than checking each group member.",
        },
        ['DoRegenBuff']       = {
            DisplayName = "Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Regen buff (single target will be used until the group version is available).",
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
            Index = 104,
            Tooltip = "Do Haste Spells/AAs",
            Default = true,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['DoArcanumWeave']    = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
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

        -- Debuffs
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
            Default = false,
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
            Default = false,
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
            FAQ = "What is a Disease Slow?",
            Answer =
            "During early eras of play, a slow that checked against disease resist was added to slow magic-resistant mobs. If selected, this will be used instead of a magic-based slow until the Turgur's AA becomes available.",
        },
        ['DoPutrid']          = {
            DisplayName = "Putrid Decay",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use your disease/poison resist debuff.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },

        -- Low Level Buffs
        ['DoLLHPBuff']        = {
            DisplayName = "HP Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLAgiBuff']       = {
            DisplayName = "Agility Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStaBuff']       = {
            DisplayName = "Stamina Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStrBuff']       = {
            DisplayName = "Strength Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
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
            Answer = "This class config is a current release customized specifically for Project Lazarus server.\n\n" ..
                "  This config should perform admirably from start to endgame.\n\n" ..
                "  Clickies that aren't already included should be managed via the clickies tab, or by customizing the config to add them directly.\n" ..
                "  Additionally, those wishing more fine-tune control for specific encounters or raids should customize this config to their preference. \n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
