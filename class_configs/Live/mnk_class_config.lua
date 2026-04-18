local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")
local Core         = require("utils.core")
local Combat       = require("utils.combat")

local _ClassConfig = {
    _version          = "2.0 - Live",
    _author           = "Algar, Derple",
    ['Modes']         = {
        'DPS',
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Transcended Fistwraps of Immortality",
            "Fistwraps of Celestial Discipline",
        },
        ['Coating'] = {
            "Spirit Drinker's Coating",
            "Blood Drinker's Coating",
        },
    },
    ['AbilitySets']   = {
        ['EndRegen'] = {
            --Timer 13, can't be used in combat
            "Second Wind", -- Level 72
            "Third Wind",
            "Fourth Wind",
            "Respite",
            "Reprieve",
            "Rest",
            "Breather", --Level 101
        },
        ['CombatEndRegen'] = {
            --Timer 13, can be used in combat.
            "Hiatus V",
            "Hiatus", --Level 106
            "Relax",
            "Night's Calming",
            "Convalesce",
        },
        ['MonkAura'] = {
            "Disciple's Aura",
            "Master's Aura",
        },
        ['Dicho'] = {
            "Dichotomic Form",
            "Dissident Form",
            "Composite Form",
            "Ecliptic Form",
            "Reciprocal Form",
        },
        ['Drunken'] = {
            "Drunken Monkey Style",
        },
        ['Curse'] = {
            -- Curse Line - Alternating expansions
            "Curse of the Thirteen Fingers", -- 103 TBM
            "Curse of Fourteen Fists",       -- 108 TBM
            "Curse of Fifteen Strikes",      -- 113 COV
            "Curse of Sixteen Shadows",      -- 118 NOS
            "Curse of Seventeen Facets",     -- 123 TOB
        },
        ['Fang'] = {
            "Dragon Fang",
            "Zalikor's Fang",
            "Hoshkar's Fang",
            "Zlexak's Fang",
            "Uncia's Fang",
        },
        ['Fists'] = {
            "Wheel of Fists XII",
            "Buffeting of Fists",
            "Wheel of Fists",
            "Whorl of Fists",
            "Torrent of Fists",
            "Firestorm of Fists",
            "Barrage of Fists",
            "Flurry of Fists",
        },
        ['Precision1'] = {
            "Doomwalker's Precision Strike",
            "Firewalker's Precision Strike",
            "Icewalker's Precision Strike",
            "Bloodwalker's Precision Strike",
            "Fatewalker's Precision Strike",
        },
        ['Precision2'] = {
            "Doomwalker's Precision Strike",
            "Firewalker's Precision Strike",
            "Icewalker's Precision Strike",
            "Bloodwalker's Precision Strike",
            "Fatewalker's Precision Strike",
        },
        ['Precision3'] = {
            "Doomwalker's Precision Strike",
            "Firewalker's Precision Strike",
            "Icewalker's Precision Strike",
            "Bloodwalker's Precision Strike",
            "Fatewalker's Precision Strike",
        },
        ['Precision4'] = {
            "Doomwalker's Precision Strike",
            "Firewalker's Precision Strike",
            "Icewalker's Precision Strike",
            "Bloodwalker's Precision Strike",
            "Fatewalker's Precision Strike",
        },
        ['Precision5'] = {
            "Doomwalker's Precision Strike",
            "Firewalker's Precision Strike",
            "Icewalker's Precision Strike",
            "Bloodwalker's Precision Strike",
            "Fatewalker's Precision Strike",
        },
        ['Shuriken'] = {
            "Vigorous Shuriken",
        },
        ['CraneStance'] = {
            "Crane Stance",
            "Heron Stance",
        },
        ['Synergy'] = {
            "Lifewalker's Synergy",
            "Fatewalker's Synergy",  -- LS 125
            "Bloodwalker's Synergy", -- TOL 120
            "Calanin's Synergy",
            "Dreamwalker's Synergy",
            "Veilwalker's Synergy",
            "Shadewalker's Synergy",
            "Doomwalker's Synergy",
            "Firewalker's Synergy",
            "Icewalker's Synergy",
        },
        ['Alliance'] = {
            -- Alliance line - Alternates expansions
            "Doomwalker's Alliance",
            "Firewalker's Covenant",
            "Icewalker's Coalition",     -- COV
            "Bloodwalker's Conjunction", -- NOS
            "Fatewalker's Covariance",   -- TOB
        },
        ['Storm'] = {
            "Eye of the Storm",
        },
        ['Breaths'] = {
            --- Breaths Endurance Line
            "Five Breaths",
            "Six Breaths",
            "Seven Breaths",
            "Eight Breaths",
            "Nine Breaths",
            "Breath of Tranquility",
            "Breath of Stillness",
            "Moment of Stillness",
        },
        ['FistsOfWu'] = {
            --- Fists of Wu - Double Attack
            "Fists Of Wu",
        },
        ['EarthDisc'] = {
            -- EarthDisc - Melee Mitigation
            "Earthwalk Discipline",
            "Earthforce Discipline",
        },
        ['ShadedStep'] = {
            -- ShadedStep - Dodge Bonus 18 Seconds
            "Void Step",
            "Shaded Step",
        },
        ['RejectDeath'] = {
            "Delay Death XI",
            "Repeal Death",
            "Delay Death",
            "Defer Death",
            "Deny Death",
            "Decry Death",
            "Forestall Death",
            "Refuse Death",
            "Reject Death",
            "Rescind Death",
            "Defy Death",
        },
        ['DodgeBody'] = {
            "Void Body",
            "Veiled Body",
        },
        ['MezSpell'] = {
            "Echo of Disorientation",
            "Echo of Flinching",
            "Echo of Diversion",
        },
        ['FistDisc'] = {
            "Ashenhand Discipline",
            "Scaledfist Discipline",
            "Ironfist Discipline",
        },
        ['Heel'] = {
            "Rapid Kick Discipline",
            "Heel of Kanji",
            "Heel of Kai",
            "Heel of Kojai",
            "Heel of Zagali",
        },
        ['Speed'] = {
            "Hundred Fists Discipline",
            "Speed Focus Discipline",
        },
        ['Palm'] = {
            "Innerflame Discipline",
            "Crystalpalm Discipline",
            "Diamondpalm Discipline",
            "Terrorpalm Discipline",
        },
        ['Poise'] = {
            "Eagles's Symmetry",
            "Dragon's Poise",
            "Tiger's Poise",
            "Eagle's Poise",
            "Tiger's Symmetry",
        },
    },
    ['Helpers']       = {
        BurnDiscCheck = function(self)
            if mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart') then return false end
            local burnDisc = { "Heel", "Speed", "FistDisc", "Palm", }
            for _, buffName in ipairs(burnDisc) do
                local resolvedDisc = self:GetResolvedActionMapItem(buffName)
                if resolvedDisc and resolvedDisc.RankName() == mq.TLO.Me.ActiveDisc.Name() then return false end
            end
            return true
        end,
        --function to make sure we don't have non-hostiles in range before we use AE damage

    },
    ['RotationOrder'] = {
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'Emergency',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and not Casting.IAmFeigning() and
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99))
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and not Casting.IAmFeigning()
            end,
        },
        {
            name = 'CombatBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning()
            end,
        },
        {
            name = 'Precision',
            state = 1,
            steps = 1,
            load_cond = function(self) return self:GetResolvedActionMapItem('Precision1') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning()
            end,
        },
    },
    ['Rotations']     = {
        ['Downtime'] = {
            {
                name = "MonkAura",
                type = "Disc",
                active_cond = function(self, discSpell)
                    return Casting.AuraActiveByName(discSpell.RankName.Name())
                end,
                cond = function(self, discSpell)
                    return not mq.TLO.Me.Aura(1).ID()
                end,
            },
            {
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    if self:GetResolvedActionMapItem("CombatEndRegen") then return false end
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
                name = "Breaths",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Mend",
                type = "Ability",
                cond = function(self, abilityName)
                    return mq.TLO.Me.PctHPs() < 50
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Imitate Death",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('AggroFeign') then return false end
                    return (mq.TLO.Me.PctHPs() <= 40 and Targeting.IHaveAggro(100)) or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99)
                        and not Core.IAmMA()
                end,
            },
            {
                name = "Feign Death",
                type = "Ability",
                cond = function(self, abilityName)
                    if not Config:GetSetting('AggroFeign') then return false end
                    return Targeting.IHaveAggro(80) and not Core.IAmMA()
                end,
            },
            {
                name = "Defy Death",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctHPs() < 25
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
                name = "Mend",
                type = "Ability",
                cond = function(self, abilityName)
                    return mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart')
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
            {
                name = "Epic",
                type = "Item",
            },
        },
        ['Burn'] = {
            { -- 5m reuse
                name = "Dicho",
                type = "Disc",
            },
            { -- 5m reuse
                name = "Ton Po's Stance",
                type = "AA",
            },
            {
                name = "Heel",
                type = "Disc",
                cond = function(self, discSpell)
                    return self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "Speed",
                type = "Disc",
                cond = function(self, discSpell)
                    return self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "FistDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "Palm",
                type = "Disc",
                cond = function(self, discSpell)
                    return self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "Spire of the Sensei",
                type = "AA",
            },
            {
                name = "Infusion of Thunder",
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
            { --10m reuse
                name = "CraneStance",
                type = "Disc",
            },
            { --20m reuse, using NOT burndisccheck means we will only use this with a burn disc active
                name = "Poise",
                type = "Disc",
                cond = function(self, discSpell)
                    return self.Helpers.BurnDiscCheck(self)
                end,
            },
            { --pairs with Speed Focus Disc, AE, T2
                name = "Destructive Force",
                type = "AA",
                cond = function(self, aaName)
                    local speedDisc = self:GetResolvedActionMapItem("Speed")
                    if not Config:GetSetting("DoAEDamage") or not speedDisc then return false end
                    return mq.TLO.Me.ActiveDisc.Name() == speedDisc.RankName() and Combat.AETargetCheck()
                end,
            },
            { --pairs with Speed Focus Disc, single target, T2
                name = "Focused Destructive Force",
                type = "AA",
                cond = function(self, aaName)
                    local speedDisc = self:GetResolvedActionMapItem("Speed")
                    if Config:GetSetting("DoAEDamage") or not speedDisc then return false end
                    return mq.TLO.Me.ActiveDisc.Name() == speedDisc.RankName()
                end,
            },
            {
                name = "Silent Strikes",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and (mq.TLO.Me.PctAggro() or 0) > 60
                end,
            },
            {
                name = "Swift Tails' Chant",
                type = "AA",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['CombatBuff'] = {
            {
                name = "CombatEndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Drunken",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Zan Fi's Whistle",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "FistsOfWu",
                type = "Disc",
                cond = function(self, discSpell)
                    if mq.TLO.Me.Level() >= 100 then return false end
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Alliance",
                type = "Disc",
                cond = function(self, discSpell)
                    if not Config:GetSetting('DoAlliance') then return false end
                    return not Casting.TargetHasBuff(discSpell.Trigger(1))
                end,
            },
            {
                name = "Storm",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "EarthDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
        },
        ['DPS'] = {
            {
                name = "Synergy",
                type = "Disc",
            },
            {
                name = "Curse",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "Two-Finger Wasp Touch",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "Fists",
                type = "Disc",
            },
            {
                name = "Fang",
                type = "Disc",
            },
            {
                name = "Shuriken",
                type = "Disc",
            },
            {
                name = "Five Point Palm",
                type = "AA",
            },
            {
                name = "Intimidation",
                type = "Ability",
                cond = function(self, abilityName)
                    return Casting.AARank("Intimidation") > 1
                end,
            },
            {
                name = "Flying Kick",
                type = "Ability",
            },
            {
                name = "Eagle Strike",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return mq.TLO.Me.PctEndurance() < 25
                end,
            },
            {
                name = "Tiger Claw",
                type = "Ability",
            },
        },
        ['Precision'] = {
            {
                name = "Precision5",
                type = "Disc",
            },
            {
                name = "Precision4",
                type = "Disc",
            },
            {
                name = "Precision3",
                type = "Disc",
            },
            {
                name = "Precision2",
                type = "Disc",
            },
            {
                name = "Precision1",
                type = "Disc",
            },
        },
    },
    ['PullAbilities'] = {
        {
            id = 'Distant Strike',
            Type = "AA",
            DisplayName = 'Distant Strike',
            AbilityName = 'Distant Strike',
            AbilityRange = 300,
            cond = function(self)
                return mq.TLO.Me.AltAbility('Distant Strike')
            end,
        },
    },
    ['DefaultConfig'] = {
        ['Mode']           = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different Modes Do?",
            Answer = "Currently there is only DPS mode for Monks, more modes may be added in the future.",
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
        ['AggroFeign']     = {
            DisplayName = "Emergency Feign",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use your Feign AA when you have aggro at low health or aggro on a mob detected as a 'named' by RGMercs (see Named tab)..",
            Default = true,
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
        ['DoChestClick']   = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your chest item during burns.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
            ConfigType = "Advanced",
        },
        ['DoCoating']      = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
        },
    },
    ['ClassFAQ']      = {
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
