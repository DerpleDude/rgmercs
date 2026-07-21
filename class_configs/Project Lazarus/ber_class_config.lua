local mq        = require('mq')
local Casting   = require("utils.casting")
local Combat    = require("utils.combat")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Targeting = require("utils.targeting")

return {
    _version          = "2.1 - Project Lazarus",
    _author           = "Algar, Derple",
    ['Modes']         = {
        'DPS',
    },
    ['Themes']        = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.22, g = 0.02, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.22, g = 0.02, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.55, g = 0.05, b = 0.05, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.36, g = 0.03, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.55, g = 0.05, b = 0.05, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.22, g = 0.02, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.35, b = 0.05, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Vengeful Taelosian Blood Axe",
            "Raging Taelosian Alloy Axe",
        },
        ['OoW_Chest'] = {
            "Wrathbringer's Chain Chestguard of the Vindicator",
            "Ragebound Chain Chestguard",
        },
    },
    ['AbilitySets']   = {
        ['EndRegen'] = {
            "Fourth Wind Discipline", -- Level 71 Laz Custom
            "Third Wind Discipline",  -- Level 70 Laz Custom
            -- "Second Wind",        -- Level 65
        },
        ['BerAura'] = {
            "Bloodlust Aura", -- Level 65
            "Aura of Rage",   -- Level 55
        },
        ['FrenzyDisc'] = {
            "Overpowering Frenzy", -- Level 65
        },
        ['VolleyDisc'] = {
            -- "Ancient: Annihilator's Volley", -- Level 71 Laz Custom, verify existence and source
            "Destroyer's Volley", -- Level 69
            "Rage Volley",        -- Level 61
        },
        ['FlurryDisc'] = {
            "Rancorous Flurry Discipline", -- Level 71 Laz Custom
            "Vengeful Flurry Discipline",  -- Level 70
        },
        ['RageDisc'] = {
            "Cleaving Madness Discipline", -- Level 71 Laz Custom
            -- "Blind Rage Discipline",       -- Level 58
            "Cleaving Rage Discipline",    -- Level 54
        },
        ['AngerDisc'] = {
            "Cleaving Anger Discipline", -- Level 65
        },
        ['CryDisc'] = {
            "Cry of Catastrophe",        -- Level 71 Laz Custom
            "Battle Cry of the Mastruq", -- Level 65
            "Ancient: Cry of Chaos",     -- Level 65
            "War Cry of Dravel",         -- Level 64
            "Battle Cry of Dravel",      -- Level 57
            "War Cry",                   -- Level 50
            "Battle Cry",                -- Level 30
        },
        ['GroupCrit'] = {
            "Cry Havoc",            -- Level 65
        },
        ['Scream'] = {              -- Stun, Throwing/Archery Dmg taken debuff
            "Bloodcurdling Scream", -- Level 71 Laz Custom
            "Bewildering Scream",   -- Level 70 Laz Custom
            "Unsettling Scream",    -- Level 65
        },
        ['StunStrike'] = {
            "Mind Strike", -- Level 68
            "Head Crush",  -- Level 60
            "Head Pummel", -- Level 40
            "Head Strike", -- Level 16
        },
        ['SnareStrike'] = {
            "Crippling Strike", -- Level 67
            "Leg Slice",        -- Level 54
            "Leg Cut",          -- Level 32
            "Leg Strike",       -- Level 8
        },
        ['Timer6Disc'] = {
            "Wounding Rage",                 -- Level 71 Laz Custom, offensive attack-proc buff
            "Unpredictable Rage Discipline", -- Level 66, defensive proc when struck
        },
        ['BattleFocus'] = {
            -- "Combat Focus Discipline", -- Level 71 Laz Custom, verify existence and source
            "Battle Focus Discipline", -- Level 59
        },
        ['ReprisalDisc'] = {           -- Manual use only for now, reprisal does not fire unless the rune is broken
            "Arcane Reprisal",         -- Level 71 Laz Custom
        },
        ['AxeThrow'] = {
            "Vigorous Axe Throw", -- Level 71 Laz Custom
        },
    },
    ['AASets']        = {
        ['RageAA'] = {
            "Cascading Rage",
            "Untamed Rage",
        },
    },
    ['RotationOrder'] = {
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
    ['Rotations']     = {
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
                name = "RageAA",
                type = "AA",
            },
            {
                name = "Timer6Disc",
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
                name = "AxeThrow",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('UseAxeThrow') and Core.GetResolvedActionMapItem('AxeThrow') end,
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell, target)
                end,
            },
            {
                name = "FrenzyDisc",
                type = "Disc",
                load_cond = function(self) return not (Config:GetSetting('UseAxeThrow') and Core.GetResolvedActionMapItem('AxeThrow')) end,
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
    ['Helpers']       = {

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
        ['UseAxeThrow']    = {
            DisplayName = "Use Axe Throw",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use Vigorous Axe Throw as your timer-10 disc instead of Frenzy (falls back to Frenzy if unavailable).",
            Default = true,
            RequiresLoadoutChange = true,
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
    ['ClassFAQ']      = {
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
