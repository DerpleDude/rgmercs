local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require('utils.combat')
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "2.3 - Project Lazarus",
    _author               = "Algar, Derple, Robban",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCures') end,
        IsRezing = function()
            local rezAction = Casting.CanUseAA("Blessing of Resurrection") or mq.TLO.FindItem("=Water Sprinkler of Nem Ankh")()
            return ((Core.GetResolvedActionMapItem('RezSpell') or rezAction) and Targeting.GetXTHaterCount() == 0) or (Config:GetSetting('DoBattleRez') and rezAction)
        end,
    },
    ['Rez']               = {
        ['Combat'] = {
            { type = "AA",   name = "Blessing of Resurrection", },
            { type = "Item", name = "Water Sprinkler of Nem Ankh", },
        },
        ['Downtime'] = {
            {
                type = "Spell",
                name = "Larger Reviviscence",
                cond = function(self, spell, target)
                    return Casting.DowntimeRezOkay()
                        and mq.TLO.SpawnCount("pccorpse radius 80 zradius 30")() > 2
                end,
            },
            { type = "AA",   name = "Blessing of Resurrection", },
            { type = "Item", name = "Water Sprinkler of Nem Ankh", },
            {
                type = "Spell",
                name = "RezSpell",
                cond = function(self, spell, target)
                    return Casting.DowntimeRezOkay()
                        and not Casting.CanUseAA('Blessing of Resurrection')
                end,
            },
        },
    },
    ['Modes']             = {
        'Heal',
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Group Purify Soul", },
            { type = "AA", name = "Radiant Cure", },
            { type = "AA", name = "Purify Soul",       selfOnly = true, },
            { type = "AA", name = "Purified Spirits",  selfOnly = true, },
        },
        ['Poison'] = {
            { type = "Spell", name = "GroupHeal",  load_cond = function(self) return self.Helpers.UseGroupHealCure(self, 'KeepPoisonMemmed') end, },
            { type = "Spell", name = "CurePoison", },
        },
        ['Disease'] = {
            { type = "Spell", name = "GroupHeal",   load_cond = function(self) return self.Helpers.UseGroupHealCure(self, 'KeepDiseaseMemmed') end, },
            { type = "Spell", name = "CureDisease", },
        },
        ['Curse'] = {
            { type = "Spell", name = "GroupHeal", load_cond = function(self) return self.Helpers.UseGroupHealCure(self, 'KeepCurseMemmed') end, },
            { type = "Spell", name = "CureCurse", },
        },
    },
    ['Themes']            = {
        ['Heal'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.30, g = 0.28, b = 0.21, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.30, g = 0.28, b = 0.21, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.70, g = 0.65, b = 0.50, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.48, g = 0.44, b = 0.34, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.70, g = 0.65, b = 0.50, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.30, g = 0.28, b = 0.21, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.99, b = 0.90, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.99, b = 0.90, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Harmony of the Soul",
            "Aegis of Superior Divinity",
        },
        ['OoW_Chest'] = {
            "Faithbringer's Breastplate of Conviction",
            "Sanctified Chestguard",
        },
    },
    ['AbilitySets']       = {
        -- ['WardSelfBuff'] = {
        --     "Ward of Retribution", -- Level 69
        -- },
        ['HealingLight'] = {
            -- "Ancient: Sacred Remedy", -- Level 71, verify existence and source
            "Ancient: Hallowed Light", -- Level 70
            "Pious Light",             -- Level 68
            "Holy Light",              -- Level 65
            "Supernal Light",          -- Level 63
            "Ethereal Light",          -- Level 58
            "Divine Light",            -- Level 53
            "Healing Light",           -- Level 39
            "Superior Healing",        -- Level 30
            "Greater Healing",         -- Level 20
            "Healing",                 -- Level 10
            "Light Healing",           -- Level 4
            "Minor Healing",           -- Level 1
        },
        ['RemedyHeal'] = {             -- Not great until 96/RoF (Graceful)
            "Pious Remedy",            -- Level 66
            "Supernal Remedy",         -- Level 61
            "Ethereal Remedy",         -- Level 59
            "Remedy",                  -- Level 51
        },
        ['Renewal'] = {                -- Level 70 +, large heal, slower cast
            "Urgent Renewal",          -- Level 71 Laz Custom
            "Desperate Renewal",       -- Level 70
        },
        ['GroupHeal'] = {
            -----Group Heals No Cure Slot 5
            "Word of Vivacity",      -- Level 80
            "Word of Vivification",  -- Level 69
            "Word of Replenishment", -- Level 64
            "Word of Restoration",   -- Level 57, No good NoCure in these level ranges using w/Cure... Note Word of Redemption omitted (12sec cast)
            "Word of Vigor",         -- Level 52
            "Word of Healing",       -- Level 45
            "Word of Health",        -- Level 30
        },
        ['SelfHPBuff'] = {
            --Self Buff for Mana Regen and armor
            "Armor of the Sacred",            -- Level 71 Laz Custom
            "Armor of the Pious",             -- Level 70
            "Armor of the Zealot",            -- Level 65
            "Ancient: High Priest's Bulwark", -- Level 60
            "Blessed Armor of the Risen",     -- Level 58
            "Armor of Protection",            -- Level 34
        },
        ['AegoBuff'] = {
            ----Use HP Type one until Temperance at 40... Group Buff at 45 (Blessing of Temperance)
            "Hand of Allegiance",     -- Level 71 Laz Custom
            "Hand of Conviction",     -- Level 70
            "Hand of Virtue",         -- Level 65
            "Blessing of Aegolism",   -- Level 60
            "Blessing of Temperance", -- Level 45
            "Temperance",             -- Level 40
            "Valor",                  -- Level 32
            "Bravery",                -- Level 22
            "Daring",                 -- Level 17
            "Center",                 -- Level 7
            "Courage",                -- Level 1
        },
        ['ACBuff'] = {
            "Ward of Valiance",  -- Level 66
            "Ward of Gallantry", -- Level 61
            "Bulwark of Faith",  -- Level 57
            "Shield of Words",   -- Level 45
            "Armor of Faith",    -- Level 35
            "Guard",             -- Level 25
            "Spirit Armor",      -- Level 15
            "Holy Armor",        -- Level 1
        },
        ['SingleVieBuff'] = {
            "Aegis of Vie",      -- Level 71 Laz Custom
            "Panoply of Vie",    -- Level 67
            "Bulwark of Vie",    -- Level 62
            "Protection of Vie", -- Level 54
            "Guard of Vie",      -- Level 40
            "Ward of Vie",       -- Level 20
        },
        ['GroupSymbolBuff'] = {
            ----Group Symbols
            "Symbol of Elushar", -- Level 71
            "Balikor's Mark",    -- Level 70
            "Kazad's Mark",      -- Level 63
            "Marzin's Mark",     -- Level 60
            "Naltron's Mark",    -- Level 58
            "Symbol of Marzin",  -- Level 54
            "Symbol of Naltron", -- Level 41
            "Symbol of Pinzarn", -- Level 31
            "Symbol of Ryltan",  -- Level 21
            "Symbol of Transal", -- Level 11
        },
        ['AbsorbAura'] = {
            ----Aura Buffs - Aura Name is seperate than the buff name
            "Aura of the Pious",  -- Level 65
            "Aura of the Zealot", -- Level 55
        },
        ['HPAura'] = {
            ---- Aura Buff 2 - Aura Name is the same as the buff name
            "Aura of Divinity", -- Level 65
        },
        ['DivineBuff'] = {
            --Divine Buffs REQUIRES extra spell slot because of the 90s recast
            "Divine Redemption",   -- Level 71 Laz Custom
            "Divine Intervention", -- Level 60
            "Death Pact",          -- Level 51
        },
        ['TwinHealNuke'] = {
            "Vigilant Censure",      -- Level 71 Laz Custom
            "Vigilant Condemnation", -- Level 70 Laz Custom
        },
        ['RezSpell'] = {
            "Spiritual Awakening", -- Level 65 Laz Custom
            "Reviviscence",        -- Level 56
            "Resurrection",        -- Level 47
            "Restoration",         -- Level 42
            "Resuscitate",         -- Level 37
            "Renewal",             -- Level 32
            "Revive",              -- Level 27
            "Reparation",          -- Level 22
            "Reconstitution",      -- Level 18
            "Reanimation",         -- Level 12
        },
        ['SingleElixir'] = {
            "Pious Elixir",      -- Level 67
            "Holy Elixir",       -- Level 65
            "Supernal Elixir",   -- Level 62
            "Celestial Elixir",  -- Level 59
            "Celestial Healing", -- Level 44
            "Celestial Health",  -- Level 29
            "Celestial Remedy",  -- Level 19
        },
        ['GroupElixir'] = {
            "Elixir of Redemption", -- Level 71 Laz Custom
            "Elixir of Divinity",   -- Level 70
            "Ethereal Elixir",      -- Level 60
        },
        ['SpellBlessing'] = {
            "Aura of Devotion",      -- Level 69
            "Blessing of Devotion",  -- Level 67
            "Aura of Reverence",     -- Level 64
            "Blessing of Reverence", -- Level 62
            "Blessing of Faith",     -- Level 35
            "Blessing of Piety",     -- Level 15
        },
        -- ['CureAll'] = { -- The single target cures that come after outclass this
        --     "Pure Blood", -- Level 51
        -- },
        ['CurePoison'] = {
            "Antidote",          -- Level 58
            -- "Eradicate Poison", -- Level 52, not currently available on Laz
            "Abolish Poison",    -- Level 48
            "Counteract Poison", -- Level 22
            "Cure Poison",       -- Level 1
        },
        ['CureDisease'] = {
            -- "Eradicate Disease", -- Level 58, not currently available on Laz
            "Counteract Disease", -- Level 28
            "Cure Disease",       -- Level 4
        },
        ['CureCurse'] = {
            -- "Eradicate Curse",   -- Level 54, not currently available on Laz
            "Remove Greater Curse", -- Level 54
            "Remove Curse",         -- Level 38
            "Remove Lesser Curse",  -- Level 23
            "Remove Minor Curse",   -- Level 8
        },
        ['YaulpSpell'] = {
            "Yaulp VII",         -- Level 69
            "Yaulp VI",          -- Level 65
            "Yaulp V",           -- Level 56, first rank with haste/mana regen. We won't use it before this.
        },
        ['StunTimer6'] = {       -- Timer 6 Stun, Fast Cast, Level 63+ (with ToT Heal 88+)
            "Sound of Zeal",     -- Level 71 Laz Custom
            "Sound of Divinity", -- Level 68, works up to level 70
            "Sound of Might",    -- Level 63
            --Filler before this
            "Tarnation",         -- Level 61, Timer 4, up to Level 65
            "Force",             -- Level 31, No Timer #, up to Level 58
            "Holy Might",        -- Level 16, No Timer #, up to Level 55
        },
        ['LowLevelStun'] = {     --Adding a second stun at low levels
            "Stun",              -- Level 2
        },
        ['UndeadNuke'] = {       -- Level 4+
            "Desolate Undead",   -- Level 68
            "Destroy Undead",    -- Level 64
            "Exile Undead",      -- Level 55
            "Banish Undead",     -- Level 43
            "Expel Undead",      -- Level 33
            "Dismiss Undead",    -- Level 23
            "Expulse Undead",    -- Level 13
            "Ward Undead",       -- Level 4
        },
        ['MagicNuke'] = {
            "Chromablast",  -- Level 71 Laz Custom
            "Chromastrike", -- Level 69, Laz specific
            -- "Calamity",  -- Level 69, Chroma is better
            "Reproach",     -- Level 67
            "Order",        -- Level 65
            "Condemnation", -- Level 62
            "Judgment",     -- Level 56
            "Retribution",  -- Level 44
            "Wrath",        -- Level 29
            "Smite",        -- Level 14
            "Furor",        -- Level 5
            "Strike",       -- Level 1
        },
        -- ['HammerPet'] = {
        --     "Unswerving Hammer of Retribution", -- Level 68
        --     "Unswerving Hammer of Justice",     -- Level 65
        --     "Unswerving Hammer of Faith",       -- Level 54
        -- },
        ['CompleteHeal'] = {
            "Complete Heal",      -- Level 39
        },
        ['PBAENuke'] = {          --This isn't worthwhile before these spells come around.
            "Calamity",           -- Level 69
            "Catastrophe",        -- Level 64
        },
        ['PBAEStun'] = {          --This isn't worthwhile before these spells come around. The stun won't land in many cases (level) but the damage is okay.
            "Silent Dictation",   -- Level 70
            "The Silent Command", -- Level 62
        },
    },                            -- end AbilitySets
    ['Charm']             = {
        ['Assist'] = {
            { name = "LowLevelStun", type = "Spell", cond = function(self, spell, target) return Targeting.TargetNotStunned() end, },
            { name = "StunTimer6",   type = "Spell", cond = function(self, spell, target) return Targeting.TargetNotStunned() end, },
            { name = "PBAEStun",     type = "Spell", cond = function(self, spell, target) return Targeting.TargetNotStunned() and Targeting.InSpellRange(spell, target) end, },
        },
    },
    ['Helpers']           = {
        UseGroupHealCure = function(self, keepSetting)
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHeal')
            return Config:GetSetting('GroupHealAsCure') and not Config:GetSetting(keepSetting) and (ghealSpell and ghealSpell.Level() or 0) >= 64
        end,
    },

    -- These are handled differently from normal rotations in that we try to make some intelligent desicions about which spells to use instead
    -- of just slamming through the base ordered list.
    -- These will run in order and exit after the first valid spell to cast
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
                name = "Beacon of Life",
                type = "AA",
            },
            {
                name = "Celestial Regeneration",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigHealsNeeded(target) -- if multiples are hurt with at least one needing big heals
                end,
            },
            {
                name = "GroupElixir",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupElixir') or (target.PctHPs() or 999) <= Config:GetSetting('BigHealPoint') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Exquisite Benediction",
                type = "AA",
                cond = function(self)
                    return Casting.BurnCheck()
                end,
            },
            {
                name = "GroupHeal",
                type = "Spell",
            },
        },
        ['BigHeal'] = {
            {
                name = "Divine Arbitration",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Burst of Life",
                type = "AA",
            },
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Weighted Hammer of Conviction",
                type = "Item",
            },
            { --This entry is for RemedyHeal until we learn a Renewal
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "Renewal", "RemedyHeal", })
                end,
                type = "Spell",
            },
            {
                name = "Focused Celestial Regeneration",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsTanking(target)
                end,
            },
            {
                name = "Blessing of Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return target.ID() == (mq.TLO.Target.AggroHolder.ID() and not Targeting.TargetIsTanking(target))
                end,
            },
            { --The stuff above is down, lets make mainhealpoint faster.
                name = "Celestial Rapidity",
                type = "AA",
            },
            { --if we hit this we need spells back ASAP
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['MainHeal'] = {
            {
                name = "SingleElixir",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSingleElixir') end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "CompleteHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting("DoCompleteHeal") or not Targeting.TargetIsTanking(target) then return false end
                    return (target.PctHPs() or 999) <= Config:GetSetting('CompleteHealPct')
                end,
            },
            {
                name = "HealingLight",
                type = "Spell",
                cond = function(self, spell, target)
                    return not (Config:GetSetting("DoCompleteHeal") and Targeting.TargetIsTanking(target))
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
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff() and Casting.AmIBuffable()
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
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'ManaRestore',
            timer = 30,
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoManaRestore') and (Casting.CanUseAA("Veturika's Perseverance") or Casting.CanUseAA("Quiet Miracle")) end,
            targetId = function(self) return { Combat.FindWorstHurtMana(Config:GetSetting('ManaRestorePct')), } end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(AE)',
            state = 1,
            steps = 1,
            load_cond = function(self)
                return (Config:GetSetting('DoPBAENuke') and self:GetResolvedActionMapItem('PBAENuke')) or
                    (Config:GetSetting('DoPBAEStun') and self:GetResolvedActionMapItem('PBAEStun'))
            end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Config:GetSetting('DoAEDamage') and
                    Combat.AETargetCheck(true)
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
            name = 'CombatBuffs',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableTankingIDs() end, -- change back to buffableIDs if we ever add non-tank stuff here
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']         = {
        ['ManaRestore'] = {
            {
                name = "Veturika's Perseverance",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target) and Casting.AmIBuffable()
                end,
            },
            {
                name = "Quiet Miracle",
                type = "AA",
                cond = function(self, aaName, target)
                    if Targeting.TargetIsMyself(target) then return false end
                    local rezSearch = string.format("pccorpse %s radius 100 zradius 50", target.DisplayName())
                    return mq.TLO.SpawnCount(rezSearch)() == 0
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Celestial Hammer",
                type = "AA",
            },
            {
                name = "Flurry of Life",
                type = "AA",
            },
            {
                name = "Healing Frenzy",
                type = "AA",
            },
            { -- Spire, the SpireChoice setting will determine which ability is displayed/used.
                name_func = function(self)
                    local spireAbil = string.format("Fundament: %s Spire of Divinity", Globals.Constants.SpireChoices[Config:GetSetting('SpireChoice') or 4])
                    return Casting.CanUseAA(spireAbil) and spireAbil or "Spire Not Purchased/Selected"
                end,
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Divine Avatar",
                type = "AA",
                cond = function(self)
                    return Config:GetSetting('DoMelee') and mq.TLO.Me.Combat()
                end,
            },
            { --homework: This is a defensive proc, likely need to add elsewhere
                name = "Divine Retribution",
                type = "AA",
                cond = function(self)
                    return Config:GetSetting('DoMelee') and mq.TLO.Me.Combat()
                end,
            },
            {
                name = "Battle Frenzy",
                type = "AA",
            },
            {
                name = "Improved Twincast",
                type = "AA",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            { --homework: Check if this is necessary (does not exceed 50% spell haste cap)
                name = "Celestial Rapidity",
                type = "AA",
            },
            {
                name = "Graverobber's Icon",
                type = "Item",
            },
        },
        ['CombatBuffs'] = {
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "GroupElixir",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoGroupElixir') end,
                cond = function(self, spell)
                    if not Config:GetSetting('GroupElixirUptime') then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 6
                end,
            },
            {
                name = "Yaulp",
                type = "AA",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoYaulp') and Casting.CanUseAA("Yaulp") end,
                cond = function(self, aaName)
                    return not mq.TLO.Me.Mount() and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "YaulpSpell",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoYaulp') and not Casting.CanUseAA("Yaulp") end,
                cond = function(self, spell)
                    return not mq.TLO.Me.Mount() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTwinHeal') end,
                cond = function(self, spell)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealStun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed and not Casting.StunImmuneTarget(target)
                end,
            },
            {
                name = "LowLevelStun",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStun') end,
                cond = function(self, spell, target)
                    local targetLevel = Targeting.GetAutoTargetLevel()
                    if targetLevel == 0 or targetLevel > 55 then return false end
                    return Casting.HaveManaToNuke(true) and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Turn Undead",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead") and Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "UndeadNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoUndeadNuke') end,
                cond = function(self, aaName, target)
                    if not Targeting.TargetBodyIs(target, "Undead") then return false end
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoMagicNuke') end,
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Config:GetSetting('DoMelee') and Core.ShieldEquipped()
                end,
            },
        },
        ['DPS(AE)'] = {
            {
                name = "PBAEStun",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAEStun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "PBAENuke",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAENuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "SelfHPBuff",
                type = "Spell",
                cond = function(self, spell)
                    if Config:GetSetting('AegoSymbol') == 3 then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Spirit Mastery",
                type = "AA",
                pre_activate = function(self, aaName) --remove the old aura if we just purchased the AA, otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName("Aura of Pious Divinity") then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, aaName)
                    return not Casting.AuraActiveByName("Aura of Pious Divinity")
                end,
            },
            {
                name = "AbsorbAura",
                type = "Spell",
                pre_activate = function(self, spell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(spell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, spell)
                    if Casting.CanUseAA('Spirit Mastery') then return false end
                    return not Casting.AuraActiveByName(spell.BaseName()) and Config:GetSetting('UseAura') == 1
                end,
            },
            {
                name = "HPAura",
                type = "Spell",
                pre_activate = function(self, spell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(spell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, spell)
                    if Casting.CanUseAA('Spirit Mastery') then return false end
                    return not Casting.AuraActiveByName(spell.BaseName()) and Config:GetSetting('UseAura') == 2
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Divine Guardian",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "AegoBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AegoSymbol') <= 2 end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupSymbolBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if Config:GetSetting('AegoSymbol') == 1 or Config:GetSetting('AegoSymbol') == 4 or ((spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsTanking(target)) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SpellBlessing",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ACBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoACBuff') end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVieBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
        },
    },
    -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
    -- The list name ("Default" in the list below) is abitrary, it is simply what shows up in the UI when this spell list is loaded.
    -- Virtually any helper function or TLO can be used as a condition. Example: Mode or level-based lists.
    -- The first list without conditions or whose conditions returns true will be loaded, all subsequent lists will be ignored.
    -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
    -- Loadout checks (such as scribing a spell or using the "Rescan Loadout" or "Reload Spells" buttons) will re-check these lists and may load a different set if things have changed.
    ['SpellList']         = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "HealingLight",  cond = function(self) return not Config:GetSetting('DoCompleteHeal') or not Core.GetResolvedActionMapItem("CompleteHeal") end, },
                { name = "CompleteHeal",  cond = function(self) return Config:GetSetting('DoCompleteHeal') end, },
                { name = "Renewal", },
                { name = "RemedyHeal",    cond = function(self) return not Core.GetResolvedActionMapItem("Renewal") end, },
                { name = "GroupHeal", },
                { name = "SingleElixir",  cond = function(self) return Config:GetSetting('DoSingleElixir') end, },
                { name = "GroupElixir",   cond = function(self) return Config:GetSetting('DoGroupElixir') end, },
                { name = "CurePoison",    cond = function(self) return Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",   cond = function(self) return Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",     cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "DivineBuff",    cond = function(self) return Config:GetSetting('DoDivineBuff') end, },
                { name = "YaulpSpell",    cond = function(self) return Config:GetSetting('DoYaulp') and not Casting.CanUseAA("Yaulp") end, },
                { name = "SingleVieBuff", cond = function(self) return Config:GetSetting('DoVieBuff') end, },
                { name = "TwinHealNuke",  cond = function(self) return Config:GetSetting('DoTwinHeal') end, },
                { name = "StunTimer6",    cond = function(self) return Config:GetSetting('DoHealStun') end, },
                { name = "LowLevelStun",  cond = function(self) return Config:GetSetting('DoLLStun') and mq.TLO.Me.Level() < 59 end, },
                { name = "MagicNuke",     cond = function(self) return Config:GetSetting('DoMagicNuke') end, },
                { name = "PBAEStun",      cond = function(self) return Config:GetSetting('DoPBAEStun') end, },
                { name = "PBAENuke",      cond = function(self) return Config:GetSetting('DoPBAENuke') end, },
                { name = "UndeadNuke",    cond = function(self) return Config:GetSetting('DoUndeadNuke') end, },
                { name = "RezSpell",      cond = function(self) return not Casting.CanUseAA('Blessing of Resurrection') end, },
            },
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
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Clerics currently only have one Mode. This may change in the future.",
        },
        --Buffs
        ['AegoSymbol']        = {
            DisplayName = "Aego/Symbol Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip =
            "Choose whether to use the Aegolism or Symbol Line of HP Buffs.\nPlease note using both is supported for party members who block buffs, but these buffs do not stack once we transition from using a HP Type-One buff in place of Aegolism.",
            Type = "Combo",
            ComboOptions = { 'Aegolism', 'Both (See Tooltip!)', 'Symbol', 'None', },
            Default = 1,
            Min = 1,
            Max = 4,
        },
        ['DoACBuff']          = {
            DisplayName = "Use AC Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip =
                "Use your single-slot AC Buff on the Main Assist. USE CASES:\n" ..
                "You have Aegolism selected and are below level 40 (We are still using a HP Type One buff).\n" ..
                "You have Symbol selected and don't have someone else providing a Type One buff.\n" ..
                "Leaving this on in other cases is not likely to cause issue, but may cause unnecessary buff checking.",
            Default = false,
        },
        ['DoVieBuff']         = {
            DisplayName = "Use Vie Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Melee Damage absorb (Vie) line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['UseAura']           = {
            DisplayName = "Aura Spell Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Select the Aura to be used, prior to purchasing the Spirit Mastery AA.",
            Type = "Combo",
            ComboOptions = { 'Absorb', 'HP', 'None', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoDivineBuff']      = {
            DisplayName = "Do Divine Intervetion",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your Divine Intervention line (death save) on the MA.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['SpireChoice']       = {
            DisplayName = "Spire Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Choose which Fundament you would like to use during burns:\n" ..
                "First Spire: Self Damage and Mitigation Buff.\n" ..
                "Second Spire: Healing Power Buff to Self.\n" ..
                "Third Spire: Group Mitigation Buff.",
            Type = "Combo",
            ComboOptions = Globals.Constants.SpireChoices,
            Default = 3,
            Min = 1,
            Max = #Globals.Constants.SpireChoices,
        },

        --Combat
        ['DoTwinHeal']        = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoHealStun']        = {
            DisplayName = "Timer 6 Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Use the Timer 6 Stun (\"Sound of\" Line).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoLLStun']          = {
            DisplayName = "Low Level Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 102,
            Tooltip = "Use the Level 2 \"Stun\" spell, as long as it is level-appropriate (works on targets up to Level 55).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why is a Cleric stunning? It should be healing!?",
            Answer =
            "At low levels, Cleric stuns are often more efficient than healing the damage an non-stunned mob would cause.",
        },
        ['DoUndeadNuke']      = {
            DisplayName = "Do Undead Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use the Undead nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoMagicNuke']       = {
            DisplayName = "Do Magic Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use the Magic nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        -- Heals and Cures
        ['DoCompleteHeal']    = {
            DisplayName = "Use Complete Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip = "Use Complete Heal on a tank class (instead of the healing Light line).",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
            FAQ = "Does RGMercs support Complete Heal Chains (CHC)?",
            Answer =
            "No, it does not. If this is important to you, there are resources on RedGuides that can handle it! You could, though, consider staggering Complete Heal percentages to break up CH usage amongst multiple clerics.",
        },
        ['CompleteHealPct']   = {
            DisplayName = "Complete Heal Pct",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Tooltip = "Pct we will use Complete Heal on any tank classes.",
            Default = 80,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
            Warning = function()
                if Config:GetSetting('CompleteHealPct') > Config:GetSetting('MaxHealPoint') then
                    return true, "Warning: CompleteHealPct exceeds MaxHealPoint - we will not check if heals are needed until health is under MaxHealPoint (Healing Threshold)."
                end
                return false, ""
            end,
        },
        ['DoSingleElixir']    = {
            DisplayName = "Single Elixir",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use your single-target Elixir Line.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoGroupElixir']     = {
            DisplayName = "Group Elixir",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your group-wide Elixir Line.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['GroupElixirUptime'] = {
            DisplayName = "Group Elixir Uptime",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 103,
            Tooltip = "In combat, attempt to keep full uptime on your Group Elixir. Note: There are scenarios where single elixirs could interfere with uptime.",
            Default = true,
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
            Tooltip = "If Word of Replenishment or Vivification are available, use these to cure instead of individual cure spells. \n" ..
                "Please note that we will prioritize single target cures if you have selected to keep them memmed above (due to the counter disparity).",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },

        --Damage(AE)
        ['DoPBAENuke']        = {
            DisplayName = "Use PBAE Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Magic PB AE Spells . **WILL BREAK MEZ**",
            Default = false,
        },
        ['DoPBAEStun']        = {
            DisplayName = "Use PBAE Stun",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 104,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Magic PB AE Stun Spells . **WILL BREAK MEZ**",
            Default = false,
        },

        --Utility
        ['DoManaRestore']     = {
            DisplayName = "Use Mana Restore AAs",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Use Veturika's Prescence (on self) or Quiet Miracle (on others) at critically low mana.",
            RequiresLoadoutChange = true, -- used as a load condition
            Default = true,
            ConfigType = "Advanced",
        },
        ['ManaRestorePct']    = {
            DisplayName = "Mana Restore Pct",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "Min Mana to use restore AA.",
            Default = 10,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
        },
        ['DoYaulp']           = {
            DisplayName = "Use Yaulp",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use your Yaulp (AA or spell line) to help maintain your mana and buff your melee ability.",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why am I using Yaulp? Clerics are not supposed to melee!",
            Answer = "The Yaulp spells we use also contain a mana regen component. You can disable this behavior on the Utility tab in the Class Options.",
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
