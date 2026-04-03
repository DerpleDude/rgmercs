local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Logger    = require("utils.logger")
local Core      = require("utils.core")

return {
    _version            = "2.1 - EQ Might",
    _author             = "Algar, Derple",
    ['ModeChecks']      = {
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Modes']           = {
        'DPS',
    },
    ['ItemSets']        = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Vengeful Taelosian Blood Axe",
            "Raging Taelosian Alloy Axe",
        },
        ['OoW_Chest'] = {
            "Wrathbringer's Chain Chestguard of the Vindicator",
            "Ragebound Chain Chestguard",
        },
    },
    ['AbilitySets']     = {
        ['BerAura'] = {
            "Aura of Rage",
            "Bloodlust Aura",
        },
        ['VolleyDisc'] = {
            "Rage Volley",
            "Destroyer's Volley",
        },
        ['FlurryDisc'] = {
            "Vengeful Flurry Discipline",
        },
        ['RageDisc'] = {
            --"Blind Rage Discipline",
            "Cleaving Rage Discipline",
        },
        ['AngerDisc'] = {
            "Cleaving Anger Discipline",
        },
        ['CryDisc'] = {
            "Battle Cry",
            "War Cry",
            "Battle Cry of Dravel",
            "War Cry of Dravel",
            "Battle Cry of the Mastruq",
            "Ancient: Cry of Chaos",
            "Ancient: Cry of Sullon",
        },
        ['GroupCrit'] = {
            "Cry Havoc",
        },
        ['StunStrike'] = {
            "Temple Blow",
            "Mind Strike",
            "Head Crush",
            "Head Pummel",
            "Head Strike",
        },
        ['SnareStrike'] = {
            "Tendon Cleave",
            "Crippling Strike",
            "Leg Slice",
            "Leg Cut",
            "Leg Strike",
        },
        ['DmgModProc'] = {
            "Unpredictable Rage Discipline",
        },
        ['HealingDisc'] = { --EQM Custom, 2m duration, 5m reuse, hp regen
            "Rejuvenating Will Discipline",
            "Healing Determination Discipline",
            "Healing Will Discipline",
        },
        ['Scream'] = { -- Throwing/Archery Dmg taken debuff
            "Unsettling Scream",
        },
    },
    ['RotationOrder']   = {
        {
            name = 'Buffs',
            state = 1,
            steps = 1,
            targetId = function(self)
                return mq.TLO.Target.ID() == Globals.AutoTargetID and { Globals.AutoTargetID, } or { mq.TLO.Me.ID(), }
            end,
            cond = function(self, combat_state)
                return combat_state == "Combat" or (combat_state == "Downtime" and Casting.OkayToBuff())
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
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        {
            name           = 'Burn(Active Discs)',
            state          = 1,
            steps          = 1,
            doFullRotation = true,
            targetId       = function(self) return Targeting.CheckForAutoTargetID() end,
            cond           = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Casting.NoDiscActive()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
    },
    ['Rotations']       = {
        ['Buffs'] = {
            {
                name = "BerAura",
                type = "Disc",
                cond = function(self, discSpell)
                    return not mq.TLO.Me.Aura(1).ID() and mq.TLO.Me.PctEndurance() > 10
                end,
            },
            {
                name = "GroupCrit",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Uncanny Resilience",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "HealingDisc",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('DoHealingDisc') end,
                cond = function(self, discName)
                    return mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart')
                end,
            },
        },
        ['Snare'] = {
            {
                name = "SnareStrike",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Burn(Active Discs)'] = {
            {
                name = "FlurryDisc",
                type = "Disc",
            },
            {
                name = "RageDisc",
                type = "Disc",
            },
            { -- goes to disc window
                name_func = function(self) return Casting.GetFirstAA({ "Cascading Rage", "Untamed Rage", }) end,
                type = "AA",
            },
            { -- goes to disc window
                name = "Savage Spirit",
                type = "AA",
            },
            {
                name = "AngerDisc",
                type = "Disc",
            },
            {
                name = "DmgModProc",
                type = "Disc",
            },
        },
        ['Burn'] = {
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Juggernaut Surge",
                type = "AA",
            },
            {
                name = "Cry of Battle",
                type = "AA",
            },
            {
                name = "CryDisc",
                type = "Disc",
            },
            {
                name = "Scream",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell, target)
                end,
            },
            {
                name = "Blood Pact",
                type = "AA",
            },
            {
                name = "Vehement Rage",
                type = "AA",
            },
            {
                name = "Blinding Fury",
                type = "AA",
            },
            {
                name = "Desperation",
                type = "AA",
            },
            {
                name = "Reckless Abandon",
                type = "AA",
            },

        },
        ['DPS'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck())) and Casting.SelfBuffItemCheck(itemName)
                end,
            },
            { --TODO: Verify all of this for laz. cursory exam shows it being the same
                name = "Battle Leap",
                type = "AA",
                cond = function(self, aaName)
                    if not Config:GetSetting('DoBattleLeap') then return false end
                    return not Casting.IHaveBuff("Battle Leap Warcry") and not Casting.IHaveBuff("Group Bestial Alignment")
                        and not mq.TLO.Me.HeadWet() --Stops Leap from launching us above the water's surface
                end,
            },
            {
                name = "VolleyDisc",
                type = "Disc",
            },
            {
                name = "Frenzy",
                type = "Ability",
            },
            {
                name = "Distraction Attack",
                type = "AA",
            },
            {
                name = "StunStrike",
                type = "Disc",
                cond = function(self, discSpell, target)
                    if not Config:GetSetting('DoStun') then return false end
                    return Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
        },
    },
    ['HelperFunctions'] = {
        DoRez = function(self, corpseId)
            local rezStaff = self.ResolvedActionMap['RezStaff']

            if mq.TLO.Me.ItemReady(rezStaff)() then
                if Casting.OkayToRez(corpseId) then
                    return Casting.UseItem(rezStaff, corpseId)
                end
            end

            return false
        end,

    },
    ['DefaultConfig']   = {
        ['Mode']           = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different combat modes do?",
            Answer = "Currently Berserkers only have a DPS mode. More modes may be added in the future.",
        },

        --Equipment
        ['UseEpic']        = {
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

        -- Combat
        ['DoBattleLeap']   = {
            DisplayName = "Do Battle Leap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use the Battle Leap AA on cooldown.",
            Default = true,
        },
        ['DoSnare']        = {
            DisplayName = "Do Snare",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Snare opponents with low health.",
            Default = false,
        },
        ['SnareCount']     = {
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
        ['DoStun']         = {
            DisplayName = "Do Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Attempt to stun your opponents.",
            Default = false,
            FAQ = "Why am I using Stun discs on an immune mob?",
            Answer = "If enabled, these abilities fires blindly. You can turn it off in your Class options.",
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
        ['DoHealingDisc']  = {
            DisplayName = "Do Healing Disc",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use the EQM Custom 'Healing Will/Determination' Disc to heal yourself in emergencies.",
            Default = false,
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']        = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is currently a Work-In-Progress that was originally based off of the Project Lazarus config.\n\n" ..
                "  Up until level 71, it should work quite well, but may need some clickies managed on the clickies tab.\n\n" ..
                "  After level 65, however, there hasn't been any playtesting... some AA may need to be added or removed still, and some Laz-specific entries may remain.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}
