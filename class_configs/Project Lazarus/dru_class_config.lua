local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require("utils.combat")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "2.1 - Lazarus",
    _author               = "Algar",
    ['ModeChecks']        = {
        CanCharm = function() return true end,
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
                    return Casting.DowntimeRezOkay()
                        and not Casting.CanUseAA('Rejuvenation of Spirit')
                end,
            },
        },
    },
    ['Modes']             = {
        'Heal',
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
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'PureBlood', 'CurePoison', }) end, },
        },
        ['Disease'] = {
            {
                type = "Spell",
                name = "GroupHeal",
                load_cond = function(self)
                    return self.Helpers.UseGroupHealCure(self)
                end,
            },
            { type = "Spell", name_func = function(self) return Casting.GetFirstMapItem({ 'PureBlood', 'CureDisease', }) end, },
        },
        ['Curse'] = {
            { type = "Spell", name = "GroupHeal", load_cond = function(self) return self.Helpers.UseGroupHealCure(self, 'KeepCurseMemmed') end, },
            { type = "Spell", name = "CureCurse", },
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
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Staff of Living Brambles",
            "Staff of Everliving Brambles",
        },
        ['OoW_Chest'] = {
            "Everspring Jerkin of Tangled Briars",
            "Greenvale Jerkin",
        },
    },
    ['AbilitySets']       = {
        ['HealingAura'] = {
            -- Healing Aura >= 55
            "Aura of Life",      -- Level 65
            "Aura of the Grove", -- Level 55
        },
        ['HealSpell'] = {
            -- Long Heal >= 1 -- skipped 10s cast heals.
            -- "Ancient: Chlorobalm", -- Level 71 Laz Custom, verify existence and source
            "Ancient: Chlorobon",          -- Level 70
            "Chlorotrope",                 -- Level 68
            "Sylvan Infusion",             -- Level 65
            "Nature's Infusion",           -- Level 63
            "Nature's Touch",              -- Level 60
            "Chloroblast",                 -- Level 55
            "Forest's Renewal",            -- Level 49
            "Superior Healing",            -- Level 45
            "Nature's Renewal",            -- Level 39
            "Healing Water",               -- Level 34
            "Greater Healing",             -- Level 29
            "Healing",                     -- Level 19
            "Light Healing",               -- Level 9
            "Minor Healing",               -- Level 1
        },
        ['GroupHeal'] = {                  -- Laz specific, some taken from cleric, some custom
            "Word of Reconstitution",      -- Level 70 Laz Custom
            "Word of Redemption",          -- Level 65
            "Word of Restoration",         -- Level 62
            "Word of Vigor",               -- Level 56
            "Word of Healing",             -- Level 50
            "Word of Health",              -- Level 40
        },
        ['ATKDebuff'] = {                  -- ATK Debuff
            "Sun's Blistering Corona",     -- Level 71 Laz Custom
            "Sun's Corona",                -- Level 67
            "Ro's Illumination",           -- Level 62
        },
        ['ATKACDebuff'] = {                -- ATK/AC Debuff, replaced by AA (Fixation > Blessing of Ro)
            "Fixation of Ro",              -- Level 42
        },
        ['FireDebuff'] = {                 -- Fire and some other stats, replaced by AA (Hand > Blessing of Ro)
            "Hand of Ro",                  -- Level 61
            "Ro's Smoldering Disjunction", -- Level 56
            "Ro's Fiery Sundering",        -- Level 37
        },
        ['ColdDebuff'] = {                 -- Cold/AC Debuff
            "Breath of the Ascent",        -- Level 71 Laz Custom
            "Glacier Breath",              -- Level 67
            "E`ci's Frosty Breath",        -- Level 63
        },
        ['ReptileBuff'] = {
            "Skin of the Reptile",   -- Level 68
        },
        ['SwarmDot'] = {             -- Magic Dot, 54s
            "Wasp Swarm",            -- Level 68
            "Swarming Death",        -- Level 63
            "Winged Death",          -- Level 53
            "Drifting Death",        -- Level 40
            "Drones of Doom",        -- Level 32
            "Creeping Crud",         -- Level 24
            "Stinging Swarm",        -- Level 10
        },
        ['VengeanceDot'] = {         -- Fire Dot, 30s
            "Vengeance of the Sun",  -- Level 69
            "Vengeance of Tunare",   -- Level 64
            "Vengeance of Nature",   -- Level 55
            "Vengeance of the Wild", -- Level 49
        },
        ['FlameLickDot'] = {         -- Fire Dot with Fire Resist Reduction, 60s
            "Immolation of the Sun", -- Level 67
            "Sylvan Embers",         -- Level 65
            "Immolation of Ro",      -- Level 62
            "Breath of Ro",          -- Level 52
            "Immolate",              -- Level 25
            "Flame Lick",            -- Level 1
        },
        ['StunNuke'] = {
            "Stormwatch",   -- Level 66
            "Storm's Fury", -- Level 61
            -- "Breath of Karana", -- Level 56, Only cast outdoors
            -- "Dustdevil",        -- Level 43, Does not Stun
            "Fury of Air", -- Level 30
            -- "Dizzying Wind",    -- Level 16, Only cast outdoors
            -- "Whirling Wind",    -- Level 3, Only cast outdoors
        },
        ['SnareSpell'] = {
            -- "Hungry Vines", -- Level 70, The out-of-era Serpent Vines is much less mana and lasts longer without the Dot And melee guard
            "Serpent Vines",   -- Level 69
            "Entangle",        -- Level 61
            "Mire Thorns",     -- Level 61
            "Bonds of Tunare", -- Level 57
            "Ensnare",         -- Level 26
            "Snare",           -- Level 1
            "Tangling Weeds",  -- Level 1
        },
        ['FireNuke'] = {
            "Solstice Strike",         -- Level 69
            "Sylvan Fire",             -- Level 65
            "Summer's Flame",          -- Level 64
            "Ancient: Starfire of Ro", -- Level 60
            "Wildfire",                -- Level 59
            "Scoriae",                 -- Level 54
            "Starfire",                -- Level 48
            "Firestrike",              -- Level 38
            "Combust",                 -- Level 28
            "Ignite",                  -- Level 8
            "Burst of Fire",           -- Level 3
            "Burst of Flame",          -- Level 1
        },
        ['IceNuke'] = {
            "Ascent Frost",           -- Level 71 Laz Custom
            "Ancient: Glacier Frost", -- Level 70
            "Glitterfrost",           -- Level 70
            "Ancient: Chaos Frost",   -- Level 65
            "Winter's Frost",         -- Level 65
            "Moonfire",               -- Level 60
            "Frost",                  -- Level 55
        },
        ['IceRain'] = {
            "Tempest Wind",    -- Level 66
            "Winter's Storm",  -- Level 61
            "Blizzard",        -- Level 54
            "Avalanche",       -- Level 37
            "Pogonip",         -- Level 22
            "Cascade of Hail", -- Level 12
        },
        ['SelfShield'] = {
            "Nettlecoat",  -- Level 68
            "Brackencoat", -- Level 64
            "Bladecoat",   -- Level 56
            "Thorncoat",   -- Level 47
            "Spikecoat",   -- Level 37
            "Bramblecoat", -- Level 27
            "Barbcoat",    -- Level 17
            "Thistlecoat", -- Level 7
        },
        ['SelfManaRegen'] = {
            "Mask of the Wild",    -- Level 70
            "Mask of the Forest",  -- Level 65
            "Mask of the Hunter",  -- Level 60
            "Mask of the Stalker", -- Level 60
        },
        ['HPTypeOne'] = {
            "Blessing of Spiritoak",    -- Level 71 Laz Custom
            "Blessing of Steeloak",     -- Level 70 Group
            -- "Steeloak Skin",            -- Level 68 Single
            "Blessing of the Nine",     -- Level 65 Group
            -- "Protection of the Nine",   -- Level 63 Single
            "Protection of the Glades", -- Level 60 Group
            -- "Natureskin",               -- Level 57 Single
            "Protection of Nature",     -- Level 49 Group
            -- "Skin like Nature",         -- Level 46 Single
            "Protection of Diamond",    -- Level 39 Group
            -- "Skin like Diamond",        -- Level 36 Single
            "Protection of Steel",      -- Level 27 Group
            -- "Skin like Steel",          -- Level 24 Single
            "Protection of Rock",       -- Level 19 Group
            -- "Skin like Rock",           -- Level 14 Single
            "Protection of Wood",       -- Level 9 Group
            "Skin like Wood",           -- Level 1 Single
        },
        ['GroupRegenBuff'] = {
            "Blessing of Moss",          -- Level 71 Laz Custom
            "Blessing of Oak",           -- Level 69
            "Blessing of Replenishment", -- Level 63
            "Regrowth of the Grove",     -- Level 58
            "Pack Chloroplast",          -- Level 45
            "Pack Regeneration",         -- Level 39
            "Regeneration",              -- Level 34
        },
        ['AtkBuff'] = {                  --Hit Damage/STR Buff
            "Lion's Strength",           -- Level 67, 5% Hit Damage
            "Nature's Might",            -- Level 62, STR Buff
            "Girdle of Karana",          -- Level 55
            "Storm Strength",            -- Level 44
            "Strength of Stone",         -- Level 34
            "Strength of Earth",         -- Level 7
        },
        ['GroupDmgShield'] = {
            "Legacy of Nettles",         -- Level 70
            "Legacy of Bracken",         -- Level 65
            "Ancient: Legacy of Blades", -- Level 60
            "Legacy of Thorn",           -- Level 59
            "Legacy of Spike",           -- Level 49
            -- Before this, use ST filler
            "Shield of Thorns",          -- Level 47
            "Shield of Spikes",          -- Level 37
            "Shield of Brambles",        -- Level 27
            "Shield of Barbs",           -- Level 17
            "Shield of Thistles",        -- Level 7
        },
        ['MoveSpells'] = {
            "Flight of Eagles", -- Level 62
            "Spirit of Eagle",  -- Level 54
            "Pack Spirit",      -- Level 35
            "Spirit of Wolf",   -- Level 10
        },
        ['PetSpell'] = {
            "Nature Seeker's Behest",   -- Level 71 Laz Custom
            "Nature Wanderer's Behest", -- Level 70 Laz Custom
            "Nature Walker's Behest",   -- Level 55
        },
        ['Dawnstrike'] = {              -- I think better to just spam solstice strike
            "Dawnflame",                -- Level 71 Laz Custom
            "Dawnstrike",               -- Level 70
        },
        -- ['BurstDS'] = { -- Laz specific, short duration 210pt damge shield
        --     "Barkspur", -- Level 70
        -- },
        ['RezSpell'] = {
            'Incarnate Anew', -- Level 59
            'Resuscitate',    -- Level 49 Laz Custom
            'Revive',         -- Level 39 Laz Custom
            'Reanimation',    -- Level 29 Laz Custom
        },
        ['CurePoison'] = {
            -- "Eradicate Poison", -- Level 58
            "Counteract Poison", -- Level 28
            "Cure Poison",       -- Level 5
        },
        ['CureDisease'] = {
            -- "Eradicate Disease", -- Level 58
            "Counteract Disease", -- Level 28
            "Cure Disease",       -- Level 4
        },
        ['CureCurse'] = {
            -- "Eradicate Curse",   -- Level 54
            "Remove Greater Curse", -- Level 54
            "Remove Curse",         -- Level 38
            "Remove Lesser Curse",  -- Level 23
            "Remove Minor Curse",   -- Level 8
        },
        ['PureBlood'] = {
            "Pure Blood", -- Level 52
        },
        ['TwinHealNuke'] = {
            "Sunburst Blessing", -- Level 70, Laz Custom, description wrong, target mob
        },
        ['HealBoostNuke'] = {
            "Sunburst Devotion", -- Level 71 Laz Custom
        },
        ['PBAEMagic'] = {
            "Earth Shiver", -- Level 66
            "Catastrophe",  -- Level 61
            "Upheaval",     -- Level 48
            "Earthquake",   -- Level 31
            "Tremor",       -- Level 21
        },
        ['PetHaste'] = {
            "Savage Spirit",         -- Level 41
            "Feral Spirit",          -- Level 18
        },
        ['GroupResistBuff'] = {      -- Fire/Cold Resist
            "Protection of Seasons", -- Level 64
            "Circle of Seasons",     -- Level 58
        },
        ['Elixir'] = {               --Laz gives these to druids
            "Celestial Elixir",      -- Level 65
            "Celestial Healing",     -- Level 49
            "Celestial Health",      -- Level 35
            "Celestial Remedy",      -- Level 25
        },
        ['EvacSpell'] = {
            "Succor",        -- Level 57
            "Lesser Succor", -- Level 18
        },
        ['QuickGroupHeal'] = {
            "Lunar Shadow", -- Level 71 Laz Custom
            "Moon Shadow",  -- Level 70 Laz Custom
        },
    },
    ['AASets']            = {
        ['FireDebuffAA'] = {
            "Blessing of Ro",
            "Hand of Ro",
        },
    },
    ['Charm']             = {
        ['Abilities'] = {
            { name = "Dire Charm", type = "AA", },
            { name = "CharmSpell", type = "Spell", },
        },
    },
    ['HealRotationOrder'] = {
        {
            name           = 'BigHealPoint',
            state          = 1,
            steps          = 1,
            doFullRotation = true,
            cond           = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
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
        ['BigHealPoint'] = {
            {
                name = "Protection of Direwood",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "QuickGroupHeal",
                type = "Spell",
            },
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "Spirit of the Bear",
                type = "AA",
            },
            {
                name = "Kelp-Covered Hammer",
                type = "Item",
            },
            { --Let's make the mainheal autocrit since we have nothing better
                name = "Nature's Blessing",
                type = "AA",
            },
        },
        ['GroupHealPoint'] = {
            {
                name = "QuickGroupHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "GroupHeal",
                type = "Spell",
            },
        },
        ['MainHealPoint'] = {
            {
                name = "Elixir",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoElixir') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
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
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff() and Casting.AmIBuffable()
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
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
            name = 'Debuff',
            state = 1,
            steps = 1,
            load_cond = function()
                return (Config:GetSetting('DoFireDebuff') and Core.GetResolvedActionMapItem("FireDebuff")) or
                    (Config:GetSetting('DoColdDebuff') and Core.GetResolvedActionMapItem("ColdDebuff")) or
                    (Config:GetSetting('DoATKDebuff') and Core.GetResolvedActionMapItem("ATKDebuff"))
            end,
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
            name = 'DPS(AE)',
            state = 1,
            steps = 1,
            load_cond = function(self)
                return (Config:GetSetting('DoPBAE') and Core.GetResolvedActionMapItem('PBAEMagic')) or
                    (Config:GetSetting('DoRain') and Core.GetResolvedActionMapItem('IceRain'))
            end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoAEDamage') then return false end
                return combat_state == "Combat" and Core.CombatActionsCheck() and Targeting.AggroCheckOkay() and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() < 71 end,
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
                return combat_state == "Combat" and Core.CombatActionsCheck() and not mq.TLO.Me.Buff("Focus of Arcanum")()
            end,
        },
        {
            name = 'CombatBuffs',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
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
                local combat = combat_state == "Combat" and Core.CombatActionsCheck()
                return downtime or combat
            end,
        },
    },
    ['Rotations']         = {
        ['DPS']            = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "Storm Strike",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "Nature Walkers Scimitar",
                type = "Item",
                cond = function(self, itemName, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Targeting.MobNotLowHP(target) and Casting.DetItemCheck(itemName, target)
                end,
            },
            {
                name = "FlameLickDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFlameLickDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Forsaken Elder Spiritist's Gauntlets",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Elder Spiritist's Gauntlets")() end,
                cond = function(self, itemName, target)
                    return Casting.DotItemCheck(itemName, target)
                end,
            },
            {
                name = "SwarmDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoSwarmDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "VengeanceDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoVengeanceDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "StunNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('StunNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('StunNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.HaveManaToNuke() and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "HealBoostNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('HealBoostNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('HealBoostNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke()
                end,
            },
            { -- in-game description is incorrect, mob must be targeted.
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('TwinHealNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('TwinHealNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke() and not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Dawnstrike",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DawnstrikeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DawnstrikeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke(true) and not mq.TLO.Me.Song("Shadow of Dawn")()
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('FireNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('FireNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke(true) and not mq.TLO.Me.Song("Shadow of Dawn")()
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('IceNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('IceNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke(true) and not mq.TLO.Me.Song("Shadow of Dawn")()
                end,
            },
        },
        ['DPS(AE)']        = {
            {
                name = "PBAEMagic",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAE') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "IceRain",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRain') end,
                cond = function(self, spell, target)
                    if not self.Helpers.RainCheck(target) then return false end
                    return Casting.HaveManaToNuke(true)
                end,
            },
        },
        ['Burn']           = {
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Group Spirit of the Black Wolf",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Nature's Fury",
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
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
                name = "Spirits of Nature",
                type = "AA",
            },
            { -- Spire, the SpireChoice setting will determine which ability is displayed/used.
                name_func = function(self)
                    local spireAbil = string.format("Fundament: %s Spire of Nature", Globals.Constants.SpireChoices[Config:GetSetting('SpireChoice') or 4])
                    return Casting.CanUseAA(spireAbil) and spireAbil or "Spire Not Purchased/Selected"
                end,
                type = "AA",
            },
            {
                name = "Shattered Gnoll Slayer",
                type = "Item",
            },
        },
        ['Debuff']         = {
            { -- Fire Debuff AA, will use the first(best) available
                name = "FireDebuffAA",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoFireDebuff') and Core.GetResolvedActionMapItem('FireDebuffAA') end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "FireDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFireDebuff') and not Core.GetResolvedActionMapItem('FireDebuffAA') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "ColdDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoColdDebuff') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "ATKDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoATKDebuff') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Snare']          = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['GroupBuff']      = {
            {
                name = "Flight of Eagles",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') and Casting.CanUseAA("Flight of Eagles") end,
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(Casting.GetAASpell(aaName))
                end,
                cond = function(self, aaName, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "MoveSpells",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') and not Casting.CanUseAA("Flight of Eagles") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ReptileBuff",
                type = "Spell",
                active_cond = function(self, spell) return true end,
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs({ "WAR", "SHD", }, target) and Casting.GroupBuffCheck(spell, target) --does not stack with PAL innate buff
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
                name = "HPTypeOne",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHPBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoGroupRegen') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupDmgShield",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoGroupDmgShield') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Wrath of the Wild",
                type = "AA",
                active_cond = function(self, aaName) return true end,
                cond = function(self, aaName, target)
                    if Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
        },
        ['Downtime']       = {
            {
                name = "HealingAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    return spell() and not Casting.AuraActiveByName(spell.BaseName())
                end,
            },
            { -- Wolf Spirit, the WolfSpiritChoice setting will determine which color you use.
                name_func = function(self)
                    local wolves = { 'White', 'Black', }
                    local spiritChoice = wolves[Config:GetSetting('WolfSpiritChoice')]
                    return string.format("Spirit of the %s Wolf", spiritChoice)
                end,
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName) and not Casting.IHaveBuff("Group " .. aaName)
                end,
            },
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
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
        },
        ['PetSummon']      = {
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
        ['PetBuff']        = {
            {
                name = "PetHaste",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "Crystalized Soul Gem", -- This isn't a typo
                type = "Item",
                cond = function(self, itemName)
                    return Casting.PetBuffItemCheck(itemName)
                end,
            },
        },
        ['ArcanumWeave']   = {
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
        ['CombatBuffs']    = {
            {
                name = "ReptileBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs({ "WAR", "SHD", }, target) and Casting.GroupBuffCheck(spell, target) --does not stack with PAL innate buff
                end,
            },
        },
        ['InstantRunBuff'] = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                cond = function(self, aaName, target)
                    local aaBuff = Casting.GetAASpell(aaName).Name() or ""
                    local combatState = Combat.GetCachedCombatState()
                    -- if in combat, check self, out of combat, also check others
                    return (combatState == "Combat" and (mq.TLO.Me.Buff(aaBuff).Duration.TotalSeconds() or 0) < 15) or
                        (combatState == "Downtime" and Casting.GroupBuffAACheck(aaName, target))
                end,
            },
        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Heal Mode",
            cond = function(self) return Core.IsModeActive("Heal") end,
            spells = {
                { name = "HealSpell", },
                { name = "QuickGroupHeal", },
                { name = "GroupHeal", },
                { name = "Elixir",         cond = function(self) return Config:GetSetting('DoElixir') end, },
                { name = "SnareSpell",     cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Entrap") end, },
                { name = "ReptileBuff", },
                { name = "ATKDebuff",      cond = function(self) return Config:GetSetting('DoATKDebuff') end, },
                { name = "FireDebuff",     cond = function(self) return Config:GetSetting('DoFireDebuff') and not Casting.CanUseAA("Hand of Ro") end, },
                { name = "ColdDebuff",     cond = function(self) return Config:GetSetting('DoColdDebuff') end, },
                {
                    name = "PureBlood",
                    cond = function(self)
                        return (Config:GetSetting('KeepDiseaseMemmed') or Config:GetSetting('KeepPoisonMemmed')) and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CurePoison",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepPoisonMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CureDisease",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepDiseaseMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "EvacSpell",      cond = function(self) return Config:GetSetting('KeepEvacMemmed') and not Casting.CanUseAA("Exodus") end, },
                { name = "StunNuke",       cond = function(self) return Config:GetSetting('StunNukeUse') > 1 end, },
                { name = "HealBoostNuke",  cond = function(self) return Config:GetSetting('HealBoostNukeUse') > 1 end, },
                { name = "TwinHealNuke",   cond = function(self) return Config:GetSetting('TwinHealNukeUse') > 1 end, },
                { name = "Dawnstrike",     cond = function(self) return Config:GetSetting('DawnstrikeUse') > 1 end, },
                { name = "FireNuke",       cond = function(self) return Config:GetSetting('FireNukeUse') > 1 end, },
                { name = "IceNuke",        cond = function(self) return Config:GetSetting('IceNukeUse') > 1 end, },
                { name = "PBAEMagic",      cond = function(self) return Config:GetSetting('DoPBAE') end, },
                { name = "IceRain",        cond = function(self) return Config:GetSetting('DoRain') end, },
                { name = "FlameLickDot",   cond = function(self) return Config:GetSetting('DoFlameLickDot') end, },
                { name = "SwarmDot",       cond = function(self) return Config:GetSetting('DoSwarmDot') end, },
                { name = "VengeanceDot",   cond = function(self) return Config:GetSetting('DoVengeanceDot') end, },
                -- { name = "BurstDS",      cond = function(self) return Config:GetSetting('DoBurstDS') end, },
                { name = "PureBlood",      cond = function(self) return Config:GetSetting('KeepPoisonMemmed') or Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CurePoison",     cond = function(self) return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",    cond = function(self) return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                --fallback QoL to take up extra slots
                { name = "GroupRegenBuff", cond = function(self) return Config:GetSetting('DoGroupRegen') end, },
                { name = "GroupDmgShield", cond = function(self) return Config:GetSetting('DoGroupDmgShield') end, },
                { name = "HPTypeOne",      cond = function(self) return Config:GetSetting('DoHPBuff') end, },
            },
        },
    },
    ['Helpers']           = {
        RainCheck = function(target) -- I made a funny
            if not Config:GetSetting('DoRain') or not Config:GetSetting('DoAEDamage') then return false end
            return Targeting.GetTargetDistance() >= Config:GetSetting('RainDistance')
        end,
        UseGroupHealCure = function(self, keepSetting)
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHeal')
            return Config:GetSetting('GroupHealAsCure') and (not keepSetting or not Config:GetSetting(keepSetting)) and (ghealSpell and ghealSpell.Level() or 0) >= 70
        end,
    },
    ['DefaultConfig']     = {
        ['Mode']              = { DisplayName = "Mode", Category = "Combat", Tooltip = "Select the Combat Mode for this Toon", Type = "Custom", RequiresLoadoutChange = true, Default = 1, Min = 1, Max = 3, },

        -- Buffs
        ['DoMoveBuffs']       = {
            DisplayName = "Do Movement Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Cast Run/Movement Spells/AA.",
            RequiresLoadoutChange = true,
            Default = false,
            FAQ = "Why am I spamming movement or runspeed buffs?",
            Answer = "Some move spells freely overwrite those of other classes, so if multiple movebuffs are being used, a buff loop may occur.\n" ..
                "Simply turn off movement buffs for the undesired class in their class options.",
        },
        ['DoHPBuff']          = {
            DisplayName = "Group HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Use your group HP Buff. Disable as desired to prevent conflicts with CLR or PAL buffs.",
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
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoGroupDmgShield']  = {
            DisplayName = "Group Dmg Shield",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Use your group damage shield buff.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "Why do my druid and mage constantly both try to use the damage shield?",
            Answer =
            "The internal mechanisms used to check stacking for these DS buffs report cross-stacking and can lead to spamming. Disable using damage shields on one or the other.",
        },
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
        ['SpireChoice']       = {
            DisplayName = "Spire Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Choose which Fundament you would like to use during burns:\n" ..
                "First Spire: Spell Crit Buff to Self.\n" ..
                "Second Spire: Healing Power Buff to Self.\n" ..
                "Third Spire: Large Group HP Buff.",
            Type = "Combo",
            ComboOptions = Globals.Constants.SpireChoices,
            Default = 3,
            Min = 1,
            Max = #Globals.Constants.SpireChoices,
        },
        ['WolfSpiritChoice']  = {
            DisplayName = "Self Wolfbuff Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Choose which wolf spirit buff you would like to maintain on yourself:\n" ..
                "White: Increased healing and reduced mana cost for healing spells. Mana Regeneration and Cold Resist.\n" ..
                "Black: Increased damage and reduced mana cost for damage spells. Mana Regeneration and Fire Resist.",
            Type = "Combo",
            ComboOptions = { 'White', 'Black', },
            Default = 1,
            Min = 1,
            Max = 2,
        },

        --Debuffs
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
        ['DoFireDebuff']      = {
            DisplayName = "Fire Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use your fire resist debuff (to include the (Hand > Blessing) of Ro AA).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoColdDebuff']      = {
            DisplayName = "Cold Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "Use your cold resist debuff.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoATKDebuff']       = {
            DisplayName = "ATK Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 101,
            Tooltip = "Use your attack resist debuff.",
            Default = false,
            RequiresLoadoutChange = true,
        },

        --Damage
        ['FireNukeUse']       = {
            DisplayName = "Fire Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your single-target fire nukes.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['IceNukeUse']        = {
            DisplayName = "Cold Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your single-target cold nukes.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['StunNukeUse']       = {
            DisplayName = "Stun Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your stun nukes (magic damage with stun component).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 1,
            Min = 1,
            Max = 3,
            lt = true,
        },
        ['TwinHealNukeUse']   = {
            DisplayName = "Twinheal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Use your twinheal nuke (fire damage with a twinheal buff effect).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['DawnstrikeUse']     = {
            DisplayName = "Dawnstrike",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 105,
            Tooltip = "Use your Dawnstrike spell (quick nuke with a chance to proc a self- beneficial or detrimental spell damage buff.).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['HealBoostNukeUse']  = {
            DisplayName = "Heal Boost Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 106,
            Tooltip = "Use your Sunburst Devotion nuke (fire damage that also buffs your healing for a short time).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['DoFlameLickDot']    = {
            DisplayName = "Fire Debuff Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Flame Lick line of dots (fire damage, fire resist debuff, 60s duration).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoVengeanceDot']    = {
            DisplayName = "Fire Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your Vengeance line of dots (fire damage, 30s duration).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoSwarmDot']        = {
            DisplayName = "Magic Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use your Swarm line of dots (magic damage, 54s duration).",
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
            FAQ = "Why am I not using my dots?",
        },

        --Damage(AE)
        ['DoPBAE']            = {
            DisplayName = "Use PBAE Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Magic PB AE Spells . **WILL BREAK MEZ**",
            Default = false,
        },
        ['DoRain']            = {
            DisplayName = "Use Ice Rain",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            Tooltip = "**WILL BREAK MEZ** Use your cold damage rain spell. **WILL BREAK MEZ***",
            Default = false,
        },
        ['RainDistance']      = {
            DisplayName = "Min Rain Distance",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 103,
            ConfigType = "Advanced",
            Tooltip = "The minimum distance a target must be to use a Rain (Rain AE Range: 25'). Used to avoid damaging the caster.",
            Default = 30,
            Min = 0,
            Max = 100,
        },

        -- Utility
        ['DoElixir']          = {
            DisplayName = "Use Elixir",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use the Elixir Line (Yes, druids get Elixirs on Laz).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why isn't my druid using the elixir line?",
            Answer = "Since the elixirs druids get are slighly behind clerics of equal level, we will bypass their use if your target is already in \"BigHeal\" range.",
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
        ['DoArcanumWeave']    = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 105,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
        ['KeepEvacMemmed']    = {
            DisplayName = "Memorize Evac",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Keep (Lesser) Succor memorized.",
            Default = false,
            RequiresLoadoutChange = true,
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
        {
            Question = "Why would I only want to nuke on an 'Epic Proc'",
            Answer = "Epic 1.5, 2,0, and 2.5 worn foci have the chance to proc 'Wrath of the Wilderness', which makes your next nuke an instant cast.",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
