local mq           = require('mq')
local Combat       = require('utils.combat')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version              = "2.2 - Project Lazarus",
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
                -- ['Corruption'] = -- Project Lazarus does not currently have any Corruption Cures.
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
            -----Group Heals No Cure Slot 5
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
            "Death Pact",
            "Divine Intervention",
        },
        ['TwinHealNuke'] = {
            "Vigilant Condemnation",
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
            -- "Eradicate Poison", -- not currently available on Laz
            "Abolish Poison",
            "Counteract Poison",
            "Cure Poison",
        },
        ['CureDisease'] = {
            -- "Eradicate Disease", -- not currently available on Laz
            "Counteract Disease",
            "Cure Disease",
        },
        ['CureCurse'] = {
            -- "Eradicate Curse", -- not currently available on Laz
            "Remove Greater Curse",
            "Remove Curse",
            "Remove Lesser Curse",
            "Remove Minor Curse",
        },
        ['YaulpSpell'] = {
            "Yaulp VII",
            "Yaulp VI",
            "Yaulp V",           -- Level 56, first rank with haste/mana regen. We won't use it before this.
        },
        ['StunTimer6'] = {       -- Timer 6 Stun, Fast Cast, Level 63+ (with ToT Heal 88+)
            "Sound of Divinity", -- works up to level 70
            "Sound of Might",
            --Filler before this
            "Tarnation",     -- Timer 4, up to Level 65
            "Force",         -- No Timer #, up to Level 58
            "Holy Might",    -- No Timer #, up to Level 55
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
            "Chromastrike", --Laz specific
            -- "Calamity", -- Chroma is better
            "Reproach",
            "Order",
            "Condemnation",
            "Judgment",
            "Retribution",
            "Wrath",
            "Smite",
            "Furor",
            "Strike",
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
    }, -- end AbilitySets
    ['HelperFunctions']   = {
        DoRez = function(self, corpseId)
            local rezAction = false
            local rezSpell = self.ResolvedActionMap['RezSpell']
            local okayToRez = Casting.OkayToRez(corpseId)
            local combatState = mq.TLO.Me.CombatState():lower() or "unknown"

            if combatState == "active" or combatState == "resting" then
                if mq.TLO.SpawnCount("pccorpse radius 80 zradius 30")() > 2 and Casting.SpellReady(mq.TLO.Spell("Larger Reviviscence"), true) then
                    rezAction = okayToRez and Casting.UseSpell("Larger Reviviscence", corpseId, true, true)
                end
            end

            if combatState == "combat" and Config:GetSetting('DoBattleRez') and Core.OkayToNotHeal() then
                if Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif mq.TLO.FindItem("=Water Sprinkler of Nem Ankh")() and mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("Water Sprinkler of Nem Ankh", corpseId)
                end
            else
                if Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif mq.TLO.FindItem("=Water Sprinkler of Nem Ankh")() and mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("Water Sprinkler of Nem Ankh", corpseId)
                elseif not Casting.CanUseAA("Blessing of Resurrection") and Casting.SpellReady(rezSpell, true) then
                    rezAction = okayToRez and Casting.UseSpell(rezSpell, corpseId, true, true)
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
                return combat_state == "Combat" and Core.OkayToNotHeal() and Config:GetSetting('DoAEDamage') and
                    Combat.AETargetCheck(true)
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
                name = "GroupSymbolBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if Config:GetSetting('AegoSymbol') == (1 or 4) or ((spell.TargetType() or ""):lower() == "single" and target.ID() ~= Core.GetMainAssistId()) then return false end
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
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVieBuff') end,
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
