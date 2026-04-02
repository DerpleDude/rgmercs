local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require("utils.globals")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Logger    = require("utils.logger")
local Combat    = require("utils.combat")

return {
    _version            = "2.0 - Project Lazarus",
    _author             = "Algar, Derple",
    ['Modes']           = {
        'DPS',
    },
    ['ItemSets']        = {
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
        ['EndRegen'] = {
            "Third Wind Discipline",
            --"Second Wind",
        },
        ['BerAura'] = {
            "Aura of Rage",
            "Bloodlust Aura",
        },
        ['FrenzyDisc'] = {
            "Overpowering Frenzy",
        },
        ['VolleyDisc'] = {
            "Rage Volley",
            "Destroyer's Volley",
        },
        ['FlurryDisc'] = {
            "Vengeful Flurry Discipline",
        },
        ['RageDisc'] = {
            "Blind Rage Discipline",
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
        },
        ['GroupCrit'] = {
            "Cry Havoc",
        },
        ['Scream'] = { -- Stun, Throwing/Archery Dmg taken debuff
            "Bloodcurdling Scream",
            "Bewildering Scream",
            "Unsettling Scream",
        },
        ['StunStrike'] = {
            "Mind Strike",
            "Head Crush",
            "Head Pummel",
            "Head Strike",
        },
        ['SnareStrike'] = {
            "Crippling Strike",
            "Leg Slice",
            "Leg Cut",
            "Leg Strike",
        },
        ['DmgModProc'] = {
            "Unpredictable Rage Discipline",
        },
        ['BattleFocus'] = {
            "Battle Focus Discipline",
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
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() <= 15 and mq.TLO.Me.Combat()
                end,
            },
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
            {
                name = "Decapitation",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "BattleFocus",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctHPs() < 35
                end,
            },
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 35 and not mq.TLO.Me.Buff("Battle Focus Effect")()
                end,
            },
            {
                name = "Uncanny Resilience",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Blood Drinker's Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
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
            { -- Goes to disc window on laz
                name = "Savage Spirit",
                type = "AA",
            },
            {
                name = "AngerDisc",
                type = "Disc",
            },
            {
                name = "RageDisc",
                type = "Disc",
            },
            {
                name = "FlurryDisc",
                type = "Disc",
            },
            { --goes to disc window on laz
                name_func = function(self) return Casting.GetFirstAA({ "Cascading Rage", "Untamed Rage", }) end,
                type = "AA",
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
                name = "Fundament: Third Spire of Savagery",
                type = "AA",
            },
            {
                name = "CryDisc",
                type = "Disc",
            },
            {
                name = "Blinding Fury",
                type = "AA",
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
                name = "Desperation",
                type = "AA",
            },
            {
                name = "Reckless Abandon",
                type = "AA",
            },
            {
                name = "Battered Smuggler's Barrel",
                type = "Item",
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
                        ---@diagnostic disable-next-line: undefined-field --Defs are not updated with HeadWet
                        and not mq.TLO.Me.HeadWet() --Stops Leap from launching us above the water's surface
                end,
            },
            {
                name = "Rampage",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting("DoAEDamage") or Config:GetSetting('UseRampage') == 1 then return false end
                    return (Config:GetSetting('UseRampage') == 3 or (Config:GetSetting('UseRampage') == 2 and Casting.BurnCheck())) and
                        Combat.AETargetCheck(true)
                end,
            },
            {
                name = "Scream",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell, target)
                end,
            },
            {
                name = "FrenzyDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell, target)
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
        ['DoCoating']      = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood Drinker's Coating in an emergency.",
            Default = false,
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

        ['UseRampage']     = {
            DisplayName = "Rampage Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 105,
            Tooltip = "Use Rampage 1-Never 2-Burns 3-Always",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']        = {
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
