local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require("utils.combat")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version          = "2.2 - EQ Might",
    _author           = "Algar, Derple",
    ['ModeChecks']    = {
        IsCuring = function() return Config:GetSetting('DoCures') end,
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Rez']           = {
        ['Combat']   = {
            { type = "Item", name = "RezStaff", },
        },
        ['Downtime'] = {
            { type = "Item", name = "RezStaff", },
        },
    },
    ['Cure']          = {
        ['DetDispel'] = {
            { type = "AA", name = "Purify Body", selfOnly = true, },
        },
    },
    ['Modes']         = {
        'DPS',
    },
    ['Themes']        = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.35, g = 0.25, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.35, g = 0.25, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.14, g = 0.10, b = 0.06, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.35, g = 0.25, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.35, g = 0.25, b = 0.15, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.14, g = 0.10, b = 0.06, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.35, g = 0.25, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.35, g = 0.25, b = 0.15, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.35, g = 0.25, b = 0.15, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.23, g = 0.16, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.35, g = 0.25, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.35, g = 0.25, b = 0.15, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.35, g = 0.25, b = 0.15, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.14, g = 0.10, b = 0.06, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.85, g = 0.55, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.85, g = 0.55, b = 0.15, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.35, g = 0.25, b = 0.15, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Transcended Fistwraps of Immortality",
            "Fistwraps of Celestial Discipline",
        },
    },
    ['AbilitySets']   = {
        ['MonkAura'] = {
            "Master's Aura",   -- Level 66
            "Disciple's Aura", -- Level 55
        },
        ['Fang'] = {
            "Clawstriker's Flurry", -- Level 74
            "Dragon Fang",          -- Level 69
        },
        ['FistsOfWu'] = {
            "Fists of Wu", -- Level 68
        },
        ['MeleeMit'] = {
            "Impenetrable Discipline", -- Level 70
            "Earthwalk Discipline",    -- Level 65
            "Stonestance Discipline",  -- Level 51
        },
        ['FistDisc'] = {
            "Ashenhand Discipline",   -- Level 60
            "Thunderkick Discipline", -- Level 52
        },
        ['Heel'] = {
            "Heel of Kanji", -- Level 70
        },
        ['Focus'] = {
            "Last Mile Focus Discipline", -- Level 69 EQM Custom
            "Speed Focus Discipline",     -- Level 63
        },
        ['Palm'] = {
            "Hundred Fists Discipline", -- Level 57
            "Innerflame Discipline",    -- Level 56
        },
        -- ['ResistantDisc'] = {
        --     "Dreamwalk Discipline", -- Level 66
        --     "Resistant Discipline", -- Level 30
        -- },
        ['HealingDisc'] = {                     --EQM Custom, 2m duration, 5m reuse, hp regen
            "Lifebloom Will Discipline",        -- Level 70 EQM Custom
            "Rejuvenating Will Discipline",     -- Level 68 EQM Custom
            "Healing Determination Discipline", -- Level 66 EQM Custom
            "Healing Will Discipline",          -- Level 59
        },
        ['Claw'] = {
            "Panther Claw", -- Level 66 EQM Custom
            "Leopard Claw", -- Level 61
        },
    },
    ['AASets']        = {
        ['Spire'] = {
            "Fundament: Second Spire of the Sensei",
            "Fundament: First Spire of the Sensei",
        },
    },
    ['Helpers']       = {
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
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
            name = 'BurnDisc',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Casting.NoDiscActive()
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
        },
        ['Emergency'] = {
            {
                name = "Imitate Death",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('AggroFeign') end,
                cond = function(self, aaName, target)
                    if Core.IsTanking() then return false end
                    return (mq.TLO.Me.PctHPs() <= 40 and Targeting.IHaveAggro(100)) or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99)
                end,
            },
            {
                name = "Feign Death",
                type = "Ability",
                load_cond = function(self) return Config:GetSetting('AggroFeign') end,
                cond = function(self, abilityName)
                    return Targeting.IHaveAggro(80) and not Core.IsTanking()
                end,
            },
            {
                name = "MeleeMit",
                type = "Disc",
                cond = function(self, discName)
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
                name = "HealingDisc",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('DoHealingDisc') end,
                cond = function(self, discName)
                    return mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Epic",
                type = "Item",
            },
        },
        ['Burn'] = {
            {
                name = "Spire",
                type = "AA",
            },
            {
                name = "Zan Fi's Whistle",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Destructive Force",
                type = "AA",
                cond = function(self, aaName)
                    if not Config:GetSetting("DoAEDamage") then return false end
                    return Combat.AETargetCheck()
                end,
            },
            {
                name = "Five Point Palm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoFivePointPalm') end,
                cond = function(self, aaName, target)
                    return Targeting.GetTargetPctHPs(target) < 90 and Core.GetMainAssistPctHPs() > 80 and mq.TLO.Me.PctHPs() > 80
                end,
            },
        },
        ['BurnDisc'] = {
            {
                name = "Heel",
                type = "Disc",
            },
            {
                name = "Palm",
                type = "Disc",
            },
            {
                name = "FistDisc",
                type = "Disc",
            },
            {
                name = "Focus",
                type = "Disc",
            },
        },
        ['CombatBuff'] = {
            {
                name = "FistsOfWu",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "Eye Gouge",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "Claw",
                type = "Disc",
            },
            {
                name = "Fang",
                type = "Disc",
            },
            {
                name = "Tiger Claw",
                type = "Ability",
            },
            {
                name = "Flying Kick",
                type = "Ability",
            },
        },
        ['GroupBuff'] = { -- Added to anchor clickies to

        },
    },
    ['PullAbilities'] = {
        {
            id = 'Grappling Strike',
            Type = "AA",
            DisplayName = 'Grappling Strike',
            AbilityName = 'Grappling Strike',
            AbilityRange = 50,
            cond = function(self)
                return Casting.CanUseAA('Grappling Strike')
            end,
        },
    },
    ['DefaultConfig'] = {
        ['Mode']            = {
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
        ['DoFivePointPalm'] = {
            DisplayName = "Do Five Point Palm",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use your Five Point Palm proc AA (slowly drains your life but adds a heavy proc effect).",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['AggroFeign']      = {
            DisplayName = "Emergency Feign",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use your Feign AA when you have aggro at low health or aggro on a mob detected as a 'named' by RGMercs (see Spawns tab)..",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['EmergencyStart']  = {
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
        ['DoHealingDisc']   = {
            DisplayName = "Do Healing Disc",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use the EQM Custom 'Healing Will/Determination' Disc to heal yourself in emergencies.",
            Default = false,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']      = {
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
