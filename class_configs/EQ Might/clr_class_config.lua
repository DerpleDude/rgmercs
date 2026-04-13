local mq           = require('mq')
local Combat       = require('utils.combat')
local Config       = require('utils.config')
local Globals      = require('utils.globals')
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")
local Combat       = require("utils.combat")

local _ClassConfig = {
    _version              = "2.3 - EQ Might",
    _author               = "Algar, Derple, Robban",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },
    ['Modes']             = {
        'Heal',
    },
    ['Cures']             = {
        GetCureSpells = function(self)
            --(re)initialize the table for loadout changes
            self.TempSettings.CureSpells = {}

            -- Choose whether we should be trying to resolve the groupheal based on our settings and whether it cures at its level
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHeal')
            local groupHeal = (Config:GetSetting('GroupHealAsCure') and (ghealSpell and ghealSpell.Level() or 0) >= 64) and "GroupHeal"

            -- Find the map for each cure spell we need, given availability of groupheal, groupcure. fallback to curespell
            -- These are convoluted: If Keepmemmed, always use cure, if not, use groupheal if available and fallback to cure
            local neededCures = {
                ['Poison'] = not Config:GetSetting('KeepPoisonMemmed') and (groupHeal or 'CurePoison') or 'CurePoison',
                ['Disease'] = not Config:GetSetting('KeepDiseaseMemmed') and (groupHeal or 'CureDisease') or 'CureDisease',
                ['Curse'] = not Config:GetSetting('KeepCurseMemmed') and (groupHeal or 'CureCurse') or 'CureCurse',
                ['Corruption'] = "CureCorrupt",
            }

            -- iterate to actually resolve the selected map item, if it is valid, add it to the cure table
            for k, v in pairs(neededCures) do
                local cureSpell = Core.GetResolvedActionMapItem(v)
                if cureSpell then
                    self.TempSettings.CureSpells[k] = cureSpell
                end
            end
        end,
        CureNow = function(self, type, targetId)
            local targetSpawn = mq.TLO.Spawn(targetId)
            if not targetSpawn and targetSpawn() then return false, false end

            if Config:GetSetting('DoCureAA') then
                local cureAA = Casting.AAReady("Purify Soul") and "Purify Soul"
                if Casting.AAReady("Group Purify Soul") and Targeting.GroupedWithTarget(targetSpawn) then
                    cureAA = "Group Purify Soul"
                elseif Casting.AAReady("Radiant Cure") then
                    cureAA = "Radiant Cure"
                    -- I am finding self-cures to be less than helpful when most effects on a healer are group-wide
                    -- elseif targetId == mq.TLO.Me.ID() and Casting.AAReady("Purified Spirits") then
                    --   cureAA = "Purified Spirits"
                end
                if cureAA then
                    Logger.log_debug("CureNow: Using %s for %s on %s.", cureAA, type:lower() or "unknown", mq.TLO.Spawn(targetId).CleanName() or "Unknown")
                    return Casting.UseAA(cureAA, targetId), true
                end
            end

            if Config:GetSetting('DoCureSpells') then
                for effectType, cureSpell in pairs(self.TempSettings.CureSpells) do
                    if type:lower() == effectType:lower() then
                        if cureSpell.TargetType():lower() == "group v1" and not Targeting.GroupedWithTarget(targetSpawn) then
                            Logger.log_debug("CureNow: We cannot use %s on %s, because it is a group-only spell and they are not in our group!", cureSpell.RankName(),
                                targetSpawn.CleanName() or "Unknown")
                        else
                            Logger.log_debug("CureNow: Using %s for %s on %s.", cureSpell.RankName(), type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
                            return Casting.UseSpell(cureSpell.RankName(), targetId, true), true
                        end
                    end
                end
            end

            Logger.log_debug("CureNow: No valid cure at this time for %s on %s.", type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
            return false, false
        end,
    },
    ['ItemSets']          = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Harmony of the Soul",
            "Aegis of Superior Divinity",
        },
        ['BlueBand'] = {
            "Legendary Ancient Frozen Blue Band",
            "Ancient Frozen Blue Band",
            "Fabled Blue Band of the Oak",
            "Blue Band of the Oak",
        },
        ['VampiricBlueBand'] = {
            "Mythical Ancient Vampiric Blue Band",
            "Legendary Ancient Vampiric Blue Band",
            "Ancient Vampiric Blue Band",
        },
        ['Timer2HealItem'] = {
            "Legendary Weighted Hammer of Conviction",
            "Legendary Aged Shissar Apothic Staff",
            "Weighted Hammer of Conviction",
            "Aged Shissar Apothic Staff",
        },
        ['OoW_Chest'] = {
            "Faithbringer's Breastplate of Conviction",
            "Sanctified Chestguard",
        },
    },
    ['AbilitySets']       = {
        -- ['WardSelfBuff'] = {
        --     "Ward of Retribution",
        -- },
        ['HealingLight'] = {
            "Minor Healing",
            "Light Healing",
            "Healing",
            "Greater Healing",
            "Superior Healing",
            "Healing Light",
            "Divine Light",
            "Ethereal Light",
            "Supernal Light",
            "Holy Light",
            "Pious Light",
            "Ancient: Hallowed Light",
            "Sacred Light",
        },
        ['RemedyHeal'] = { -- Not great until 96/RoF (Graceful)
            "Remedy",
            "Ethereal Remedy",
            "Supernal Remedy",
            "Pious Remedy",
        },
        ['Renewal'] = { -- Level 70 +, large heal, slower cast
            "Desperate Renewal",
        },
        ['GroupHeal'] = {
            "Word of Health",
            "Word of Healing",
            "Word of Vigor",
            "Word of Restoration", -- No good NoCure in these level ranges using w/Cure... Note Word of Redemption omitted (12sec cast)
            "Word of Replenishment",
            "Word of Vivification",
            "Word of Vivacity",
        },
        ['SelfHPBuff'] = {
            --Self Buff for Mana Regen and armor
            "Armor of Protection",
            "Blessed Armor of the Risen",
            "Ancient: High Priest's Bulwark",
            "Armor of the Zealot",
            "Armor of the Pious",
        },
        ['AegoBuff'] = {
            ----Use HP Type one until Temperance at 40... Group Buff at 45 (Blessing of Temperance)
            "Hand of Conviction",
            "Hand of Virtue",
            "Ancient: Gift of Aegolism",
            "Blessing of Aegolism",
            "Blessing of Temperance",
            "Temperance",
            "Valor",
            "Bravery",
            "Daring",
            "Center",
            "Courage",
        },
        ['ACBuff'] = {
            "Ward of Valiance",
            "Ward of Gallantry",
            "Bulwark of Faith",
            "Shield of Words",
            "Armor of Faith",
            "Guard",
            "Spirit Armor",
            "Holy Armor",
        },
        ['SingleVieBuff'] = {
            "Aegis of Vie",
            "Panoply of Vie",
            "Bulwark of Vie",
            "Protection of Vie",
            "Guard of Vie",
            "Ward of Vie",
        },
        ['GroupSymbolBuff'] = {
            ----Group Symbols
            "Symbol of Transal",
            "Symbol of Ryltan",
            "Symbol of Pinzarn",
            "Symbol of Naltron",
            "Symbol of Marzin",
            "Naltron's Mark",
            "Marzin's Mark",
            "Kazad's Mark",
            "Balikor's Mark",
        },
        ['AbsorbAura'] = {
            ----Aura Buffs - Aura Name is seperate than the buff name
            "Aura of the Pious",
            "Aura of the Zealot",
        },
        ['HPAura'] = {
            ---- Aura Buff 2 - Aura Name is the same as the buff name
            "Aura of Divinity",
        },
        ['DivineBuff'] = {
            --Divine Buffs REQUIRES extra spell slot because of the 90s recast
            "Divine Incursion",
            "Divine Interaction",
            "Divine Intervention",
            "Death Pact",
        },
        ['RezSpell'] = {
            "Spiritual Awakening",
            "Reviviscence",
            "Resurrection",
            "Restoration",
            "Resuscitate",
            "Renewal",
            "Revive",
            "Reparation",
            "Reconstitution",
            "Reanimation",
        },
        ['SingleElixir'] = {
            "Sacred Elixir",
            "Pious Elixir",
            "Holy Elixir",
            "Supernal Elixir",
            "Celestial Elixir",
            "Celestial Healing",
            "Celestial Health",
            "Celestial Remedy", -- Level 19
        },
        ['GroupElixir'] = {
            "Elixir of Divinity",
            "Ethereal Elixir",
        },
        ['SpellBlessing'] = {
            "Aura of Purpose",
            "Blessing of Purpose",
            "Aura of Devotion",
            "Blessing of Devotion",
            "Aura of Reverence",
            "Blessing of Reverence",
            "Blessing of Faith",
            "Blessing of Piety",
        },
        -- ['CureAll'] = { -- The single target cures that come after outclass this
        --     "Pure Blood",
        -- },
        ['CurePoison'] = {
            -- "Puratas", -- Excessive Cast Time
            "Antidote",
            "Eradicate Poison",
            "Abolish Poison",
            "Counteract Poison",
            "Cure Poison",
        },
        ['CureDisease'] = {
            "Eradicate Disease",
            "Counteract Disease",
            "Cure Disease",
        },
        ['CureCurse'] = {
            "Eradicate Curse",
            "Remove Greater Curse",
            "Remove Curse",
            "Remove Lesser Curse",
            "Remove Minor Curse",
        },
        ['CureCorrupt'] = {
            "Cure Corruption",
        },
        ['YaulpSpell'] = {
            "Yaulp VII",
            "Yaulp VI",
            "Yaulp V",           -- Level 56, first rank with haste/mana regen. We won't use it before this.
        },
        ['StunTimer6'] = {       -- Timer 6 Stun, Fast Cast, Level 63+ (with ToT Heal 88+)
            "Sound of Zeal",     -- works up to level 75
            "Sound of Divinity", -- works up to level 70
            "Sound of Might",
            --Filler before this
            "Tarnation",  -- Timer 4, up to Level 65
            "Force",      -- No Timer #, up to Level 58
            "Holy Might", -- No Timer #, up to Level 55
        },
        ['StunTimer4'] = {
            "Shock of Wonder",
        },
        ['LowLevelStun'] = { --Adding a second stun at low levels
            "Stun",
        },
        ['UndeadNuke'] = { -- Level 4+
            "Desolate Undead",
            "Destroy Undead",
            "Exile Undead",
            "Banish Undead",
            "Expel Undead",
            "Dismiss Undead",
            "Expulse Undead",
            "Ward Undead",
        },
        ['MagicNuke'] = {
            "Reproval",
            "Chromastrike",
            "Reproach",
            "Ancient: Chaos Censure",
            "Order",
            "Condemnation",
            "Judgment",
            "Retribution",
            "Wrath",
            "Smite",
            "Furor",
            "Strike",
        },
        ['QuickNuke'] = { -- Might specific
            "Verdict of Ascension",
            "Verdict of Radiance",
            "Verdict of Light",
        },
        -- ['HammerPet'] = {
        --     "Unswerving Hammer of Retribution",
        --     "Unswerving Hammer of Justice",
        --     "Unswerving Hammer of Faith",
        -- },
        ['CompleteHeal'] = {
            "Complete Heal",
        },
        ['PBAENuke'] = { --This isn't worthwhile before these spells come around.
            "Calamity",
            "Catastrophe",
        },
        ['PBAEStun'] = { --This isn't worthwhile before these spells come around. The stun won't land in many cases (level) but the damage is okay.
            "Silent Dictation",
            "The Silent Command",
        },
        ['PromisedHeal'] = {
            "Promised Renewal",
        },
    }, -- end AbilitySets
    ['HelperFunctions']   = {
        DoRez = function(self, corpseId)
            local rezAction = false
            local rezSpell = self.ResolvedActionMap['RezSpell']
            local rezStaff = self.ResolvedActionMap['RezStaff']
            local staffReady = mq.TLO.Me.ItemReady(rezStaff)()
            local okayToRez = Casting.OkayToRez(corpseId)
            local combatState = mq.TLO.Me.CombatState():lower() or "unknown"

            if combatState == "active" or combatState == "resting" then
                if mq.TLO.SpawnCount("pccorpse radius 80 zradius 30")() > 2 and Casting.SpellReady(mq.TLO.Spell("Larger Reviviscence"), true) then
                    rezAction = okayToRez and Casting.UseSpell("Larger Reviviscence", corpseId, true, true)
                end
            end

            if combatState == "combat" and Config:GetSetting('DoBattleRez') and Core.OkayToNotHeal() then
                -- legendary staff only has a 1.5s cast, use it first in combat
                if rezStaff == "Legendary Fabled Staff of Forbidden Rites" and staffReady then
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif staffReady then -- the lower 2 staves still cast faster or as fast as water sprinkler
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("Water Sprinkler of Nem Ankh", corpseId)
                else
                    Logger.log_debug("DoRez: No fast rez options available in combat for %s.", mq.TLO.Spawn(corpseId).CleanName() or "Unknown")
                end
            elseif combatState ~= "combat" then
                if Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif staffReady then
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("=Water Sprinkler of Nem Ankh", corpseId)
                elseif not Casting.CanUseAA("Blessing of Resurrection") and (combatState == "active" or combatState == "resting") then
                    -- ^ if we have BoR, just wait for it, rather than taking the time to memorize a spell
                    if Casting.SpellReady(rezSpell, true) then
                        rezAction = okayToRez and Casting.UseSpell(rezSpell, corpseId, true, true)
                    end
                end
            end

            return rezAction
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
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHeal',
            state = 1,
            steps = 1,
            cond = function(self, target)
                return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target)
            end,
        },
        {
            name = 'MainHeal',
            state = 1,
            steps = 1,
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
                pre_activate = function(self)
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
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
                name = "VampiricBlueBand",
                type = "Item",
                load_cond = function(self) return Core.GetResolvedActionMapItem("VampiricBlueBand") and mq.TLO.Me.Level() >= 68 end,
            },
            {
                name = "BlueBand",
                type = "Item",
                load_cond = function(self) return Core.GetResolvedActionMapItem("BlueBand") and (mq.TLO.Me.Level() < 68 or not Core.GetResolvedActionMapItem("VampiricBlueBand")) end,
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
                    return Targeting.TargetIsATank(target)
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
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Timer2HealItem",
                type = "Item",
            },
            { -- keep this for big heals, unless we are critically low on mana
                name = "Braided Kirin Mane",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Braided Kirin Mane")() end,
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
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Blessing of Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return target.ID() == (mq.TLO.Target.AggroHolder.ID() and not Targeting.TargetIsATank(target))
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
            { -- keep this for big heals, unless we are critically low on mana
                name = "Timer2HealItem",
                type = "Item",
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            { -- keep this for big heals, unless we are critically low on mana
                name = "Braided Kirin Mane",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Braided Kirin Mane")() end,
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
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
                    if not Config:GetSetting("DoCompleteHeal") or not Targeting.TargetIsATank(target) then return false end
                    return (target.PctHPs() or 999) <= Config:GetSetting('CompleteHealPct')
                end,
            },
            {
                name = "HealingLight",
                type = "Spell",
                cond = function(self, spell, target)
                    return not (Config:GetSetting("DoCompleteHeal") and Targeting.TargetIsATank(target))
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
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Spells that should be checked on group members
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
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
                return (downtime or combat) and Core.OkayToNotHeal()
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
                return combat_state == "Combat" and Core.OkayToNotHeal() and Config:GetSetting('DoAEDamage') and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
        {
            name = 'Combat Buffs',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
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
            { --homework: Check if this is necessary (does not exceed 50% spell haste cap)
                name = "Celestial Rapidity",
                type = "AA",
            },
            {
                name = "Graverobber's Icon",
                type = "Item",
            },
        },
        ['Combat Buffs'] = {
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
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
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTimer6Stun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) -- no stun checks because these are Recourse of Life procs as well
                end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTimer4Stun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) -- no stun checks because these are Recourse of Life procs as well
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
                name = "QuickNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoQuickNuke') end,
                cond = function(self)
                    return Casting.OkayToNuke(true)
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
                    if not Targeting.TargetIsATank(target) then return false end
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
                name_func = function(self)
                    if mq.TLO.FindItem("=Mythical Armband of Elushar")() then return "Mythical Armband of Elushar" end
                    if mq.TLO.FindItem("=Legendary Armband of Mithaniel")() then return "Legendary Armband of Mithaniel" end
                    return "Symbol Buff Clicky"
                end,
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and (mq.TLO.FindItem("=Mythical Armband of Elushar")() or mq.TLO.FindItem("=Legendary Armband of Mithaniel")()) end,
                cond = function(self, itemName, target)
                    if Config:GetSetting('AegoSymbol') == (1 or 4) then return false end
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "GroupSymbolBuff",
                type = "Spell",
                load_cond = function() return mq.TLO.Me.Level() < 68 or not mq.TLO.FindItem("=Legendary Armband of Mithaniel")() end,
                cond = function(self, spell, target)
                    if Config:GetSetting('AegoSymbol') == (1 or 4) or ((spell.TargetType() or ""):lower() == "single" and target.ID() ~= Core.GetMainAssistId()) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SpellBlessing",
                type = "Spell",
                cond = function(self, spell, target)
                    if mq.TLO.Me.Level() > 91 then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ACBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoACBuff') end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Aegis",
                type = "Item",
                load_cond = function() return Config:GetSetting('DoVieBuff') and mq.TLO.Me.Level() >= 69 and mq.TLO.FindItem("=Artifact of Aegis")() end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "SingleVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVieBuff') and (mq.TLO.Me.Level() < 69 or not mq.TLO.FindItem("=Artifact of Aegis")()) end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
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
                { name = "CureCorrupt",   cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
                { name = "DivineBuff",    cond = function(self) return Config:GetSetting('DoDivineBuff') end, },
                { name = "YaulpSpell",    cond = function(self) return Config:GetSetting('DoYaulp') and not Casting.CanUseAA("Yaulp") end, },
                { name = "SingleVieBuff", cond = function(self) return Config:GetSetting('DoVieBuff') end, },
                { name = "StunTimer6",    cond = function(self) return Config:GetSetting('DoTimer6Stun') end, },
                { name = "StunTimer4",    cond = function(self) return Config:GetSetting('DoTimer4Stun') end, },
                { name = "LowLevelStun",  cond = function(self) return Config:GetSetting('DoLLStun') and mq.TLO.Me.Level() < 59 end, },
                { name = "QuickNuke",     cond = function(self) return Config:GetSetting('DoQuickNuke') end, },
                { name = "MagicNuke",     cond = function(self) return Config:GetSetting('DoMagicNuke') end, },
                { name = "PBAEStun",      cond = function(self) return Config:GetSetting('DoPBAEStun') end, },
                { name = "PBAENuke",      cond = function(self) return Config:GetSetting('DoPBAENuke') end, },
                { name = "UndeadNuke",    cond = function(self) return Config:GetSetting('DoUndeadNuke') end, },
                { name = "PromisedHeal", }, -- filler, for manual use only, the config does not use it automatically
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

        --Combat
        ['DoTimer6Stun']      = {
            DisplayName = "Timer 6 Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Use the Timer 6 Stun (\"Sound of\" Line).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTimer4Stun']      = {
            DisplayName = "Timer 4 Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 102,
            Tooltip = "Use the Timer 4 Stun (Shock of Wonder).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoLLStun']          = {
            DisplayName = "Low Level Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 103,
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
        ['DoQuickNuke']       = {
            DisplayName = "Do Verdict Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Use the Verdict Quicknuke line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        -- Heals and Cures
        ['DoCompleteHeal']    = {
            DisplayName = "Use Complete Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip = "Use Complete Heal on the MA (instead of the healing Light line).",
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
            Tooltip = "Pct we will use Complete Heal on the MA.",
            Default = 80,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
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
        ['KeepCorruptMemmed'] = {
            DisplayName = "Mem Cure Corruption",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 104,
            Tooltip = "Memorize cure corruption spell when possible (depending on other selected options). \n" ..
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
        },
        ['DoPBAENuke']        = {
            DisplayName = "Use PBAE Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
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
            Index = 102,
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
            FAQ = "Why am I using Yaulp? Clerics are not supposed to melee!",
            Answer = "The Yaulp spells we use also contain a mana regen component. You can disable this behavior on the Utility tab in the Class Options.",
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is currently a Work-In-Progress that was originally based off of the Project Lazarus config.\n\n" ..
                "  Up until level 71, it should work quite well, but may need some clickies managed on the clickies tab.\n\n" ..
                "  After level 68, however, there hasn't been any playtesting... some AA may need to be added or removed still, and some Laz-specific entries may remain.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
