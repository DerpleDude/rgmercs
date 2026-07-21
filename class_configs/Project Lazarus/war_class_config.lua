local mq           = require('mq')
local Set          = require('mq.set')
local Casting      = require("utils.casting")
local Combat       = require("utils.combat")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local ItemManager  = require("utils.item_manager")
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version          = "3.1 - Project Lazarus",
    _author           = "Algar, Derple",
    ['ModeChecks']    = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
    },
    ['Modes']         = {
        'Tank',
        'DPS',
    },
    ['Themes']        = {
        ['Tank'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.09, g = 0.10, b = 0.11, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.09, g = 0.10, b = 0.11, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.22, g = 0.25, b = 0.28, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.15, g = 0.17, b = 0.19, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.22, g = 0.25, b = 0.28, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.09, g = 0.10, b = 0.11, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.55, g = 0.60, b = 0.65, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.55, g = 0.60, b = 0.65, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
        },
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.14, g = 0.06, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.14, g = 0.06, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.35, g = 0.15, b = 0.10, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.23, g = 0.10, b = 0.07, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.35, g = 0.15, b = 0.10, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.14, g = 0.06, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.80, g = 0.20, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.80, g = 0.20, b = 0.15, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Kreljnok's Sword of Eternal Power",
            "Champion's Sword of Eternal Power",
        },
        ['OoW_Chest'] = {
            "Armsmaster's Breastplate",
            "Gladiator's Plate Chestguard of War",
        },
        ['Coating'] = {
            "Blood Drinker's Coating",
        },
    },
    ['AbilitySets']   = {
        ['StandDisc'] = {             -- Timer 1
            "Final Stand Discipline", -- Level 71 Laz Custom
            "Stonewall Discipline",   -- Level 65, no lost movement on laz, more mitigation than defensive
            "Defensive Discipline",   -- Level 55
            "Evasive Discipline",     -- Level 52
        },
        ['Fortitude'] = {             -- Timer 2
            -- "Ancient: Impervious Discipline", -- Level 71 Laz Custom, verify existence and source
            "Fortitude Discipline",   -- Level 59
            "Furious Discipline",     -- Level 56
        },
        ['GroupACBuff'] = {           -- Has Commanding Voice (Dodge Buff) baked in
            "Field Conqueror",        -- Level 71 Laz Custom
            "Field Armorer",          -- Level 65
        },
        ['AEBlades'] = {
            "Maelstrom Blade", -- Level 71 Laz Custom
            "Vortex Blade",    -- Level 69
            "Cyclone Blade",   -- Level 65
            "Whirlwind Blade", -- Level 61
        },
        ['AddHate'] = {
            "Roaring Hatred",        -- Level 71 Laz Custom
            "Ancient: Chaos Cry",    -- Level 65
            "Bellow of the Mastruq", -- Level 65
            "Incite",                -- Level 63
            "Berate",                -- Level 56
            "Bellow",                -- Level 52
            "Provoke",               -- Level 20
        },
        ['AbsorbTaunt'] = {
            "Jeer", -- Level 71 Laz Custom
            "Mock", -- Level 65
        },
        ['EndRegen'] = {
            "Fourth Wind Discipline", -- Level 71 Laz Custom
            "Third Wind Discipline",  -- Level 70, also does HP Laz Custom
            "Second Wind",            -- Level 65
        },
        ['AuraBuff'] = {
            "Vanquisher's Aura", -- Level 71 Laz Custom
            "Champion's Aura",   -- Level 70
            "Myrmidon's Aura",   -- Level 55
        },
        ['Attention'] = {
            "Unyielding Attention", -- Level 71
            "Undivided Attention",  -- Level 65
        },
        ['Onslaught'] = {
            -- "Ancient: Malicious Onslaught", -- Level 71 Laz Custom, verify existence and source
            "Brutal Onslaught Discipline", -- Level 68
            "Savage Onslaught Discipline", -- Level 65
        },
        ['StrikeDisc'] = {
            "Fellstrike Discipline",    -- Level 58
            "Mighty Strike Discipline", -- Level 54
        },
        ['Throat'] = {
            "Throat Jab", -- Level 69
        },
        ['Flaunt'] = {
            "Flaunt", -- Level 70 Laz Custom
        },
        -- ['ShockDisc'] = {                  -- Timer 6, defensive stun proc
        --     "Shocking Defense Discipline", -- Level 70
        -- },
        ['Scowl'] = {                    -- Timer 8, opt-in taunt + melee absorb via UseScowl (shares timer with AddHate)
            "Scowl",                     -- Level 71 Laz Custom
        },
        ['MaxEffort'] = {                -- Timer 6, endurance-fueled melee absorb
            "Maximum Effort Discipline", -- Level 71 Laz Custom
        },
    },
    ['AASets']        = {
        ['AreaTaunt'] = {
            "Enhanced Area Taunt",
            "Area Taunt",
        },
    },
    ['Helpers']       = {
        --function to determine if we have enough mobs in range to use a defensive disc
        DefensiveDiscCheck = function(printDebug)
            local xtCount = mq.TLO.Me.XTarget() or 0
            if xtCount < Config:GetSetting('DiscCount') then return false end
            local haters = Set.new({})
            for i = 1, xtCount do
                local xtarg = mq.TLO.Me.XTarget(i)
                if xtarg and xtarg.ID() > 0 and ((xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater")) and (xtarg.Distance() or 999) <= 30 then
                    if printDebug then
                        Logger.log_verbose("DefensiveDiscCheck(): XT(%d) Counting %s(%d) as a hater in range.", i, xtarg.CleanName() or "None", xtarg.ID())
                    end
                    haters:add(xtarg.ID())
                end
                if #haters:toList() >= Config:GetSetting('DiscCount') then return true end -- no need to keep counting once this threshold has been reached
            end
            return false
        end,
        BurnDiscCheck = function(self)
            if mq.TLO.Me.ActiveDisc.Name() == "Fortitude Discipline" or mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart') then return false end
            local burnDisc = { "Onslaught", "StrikeDisc", "ChargeDisc", }
            for _, buffName in ipairs(burnDisc) do
                local resolvedDisc = self:GetResolvedActionMapItem(buffName)
                if resolvedDisc and resolvedDisc.RankName() == mq.TLO.Me.ActiveDisc.Name() then return false end
            end
            return true
        end,
        DefenseBuffCheck = function(self)
            local standDisc = Core.GetResolvedActionMapItem('StandDisc')
            if not standDisc then return false end
            if standDisc() and mq.TLO.Me.ActiveDisc.Name() == standDisc.RankName() then return false end
            local defBuff = { "Guardian's Boon", "Guardian's Bravery", "Warlord's Bravery", }
            for _, buffName in ipairs(defBuff) do
                if mq.TLO.Me.Buff(buffName)() then return false end
            end
            return true
        end,
        shieldNeeded = function()
            -- check for exactly 100% to help ensure the mob is targeting us, over 100% can indicate another is still targeted
            return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or
                (Config:GetSetting('NamedShieldLock') and ((Globals.AutoTargetIsNamed and Targeting.GetAutoTargetAggroPct() == 100) or Targeting.TankingXTNamed()))
        end,
    },
    ['Charm']         = {
        ['Assist'] = {
            { name = "Taunt",          type = "Ability", },
            { name = "Attention",      type = "Disc", },
            { name = "Blast of Anger", type = "AA", },
            { name = "AddHate",        type = "Disc", },
        },
    },
    ['RotationOrder'] = {
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Actions to lock down xtarg haters
            name = 'HateTools(AggroTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('TankAggroScan') end,
            targetId = function(self) return Targeting.CheckForAggroTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat"
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'HateTools(AutoTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Targeting.HateToolsNeeded()
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'AEHateTools',
            state = 1,
            steps = 1,
            timer = 1, -- Don't check this more often than once a second to avoid blowing every ability at once (aggro takes time to update)
            doFullRotation = true,
            load_cond = function()
                return Core.IsTanking() and Config:GetSetting('DoAETaunt') and
                    (Casting.CanUseAA("Area Taunt") or Core.GetResolvedActionMapItem("Epic") or Core.GetResolvedActionMapItem("AEBlades"))
            end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Combat.AETauntCheck(true)
            end,
        },
        { --Dynamic weapon swapping if UseBandolier is toggled
            name = 'Weapon Management',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('UseBandolier') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        { --Defensive actions triggered by low HP
            name = 'EmergencyDefenses',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
            end,
        },
        { --Defensive actions used proactively to prevent emergencies
            name = 'Defenses',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.IHaveAggro(100) and
                    -- we are under our defense start HP
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('DefenseStart') or
                        -- we have met our defense count threshold
                        self.Helpers.DefensiveDiscCheck(true) or
                        -- we are fighting a named and we are tanking it
                        Targeting.TankingXTNamed())
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
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
        { --Non-threat combat actions
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']     = {
        ['Downtime'] = {
            {
                name = "AuraBuff",
                type = "Disc",
                active_cond = function(self, discSpell)
                    return Casting.AuraActiveByName(discSpell.RankName.Name())
                end,
                cond = function(self, discSpell)
                    return not mq.TLO.Me.Aura(1).ID()
                end,
            },
        },
        ['HateTools(AggroTarget)'] = {
            {
                name = "Taunt",
                type = "Ability",
            },
            {
                name = "Attention",
                type = "Disc",
            },
            {
                name = "Blast of Anger",
                type = "AA",
            },
            {
                name = "Scowl",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('UseScowl') and Core.GetResolvedActionMapItem('Scowl') end,
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "AddHate",
                type = "Disc",
                load_cond = function(self) return not (Config:GetSetting('UseScowl') and Core.GetResolvedActionMapItem('Scowl')) end,
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
        },
        ['HateTools(AutoTarget)'] = {
            {
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro()
                end,
            },
            { --8min reuse, save for we still can't get a mob back after trying to taunt, try not to use it on the pull
                name = "Ageless Enmity",
                type = "AA",
                cond = function(self, aaName, target)
                    return (Globals.AutoTargetIsNamed or Targeting.GetAutoTargetPctHPs() < 90) and Targeting.LostAutoTargetAggro()
                end,
            },
            { --used to jumpstart hatred on named from the outset and prevent early rips from burns
                name = "Attention",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Blast of Anger",
                type = "AA",
            },
            {
                name = "Scowl",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('UseScowl') and Core.GetResolvedActionMapItem('Scowl') end,
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "AddHate",
                type = "Disc",
                load_cond = function(self) return not (Config:GetSetting('UseScowl') and Core.GetResolvedActionMapItem('Scowl')) end,
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "Projection of Fury",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
        },
        ['AEHateTools'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if not Config:GetSetting('DoEpic') then return false end
                    return Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "AEBlades",
                type = "Disc",
                cond = function(self, discSpell)
                    return Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "AreaTaunt",
                type = "AA",
            },
            {
                name = "Rampage",
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting("DoAEDamage")
                end,
            },
        },
        ['EmergencyDefenses'] = {
            --Note that in Tank Mode, defensive discs are preemptively cycled on named in the (non-emergency) Defenses rotation
            --Abilities should be placed in order of lowest to highest triggered HP thresholds
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "Fortitude",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Warlord's Tenacity",
                type = "AA",
            },
            {
                name = "Warlord's Resurgence",
                type = "AA",
            },
            {
                name = "Mark of the Mage Hunter",
                type = "AA",
            },
            { --here for use in emergencies regarldless of ability staggering below
                name = "StandDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Core.IsTanking() and Casting.NoDiscActive()
                end,
            },
        },
        ['Weapon Management'] = {
            {
                name = "Equip Shield",
                type = "CustomFunc",
                cond = function(self)
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return self.Helpers.shieldNeeded()
                end,
                custom_func = function(self)
                    ItemManager.BandolierSwap("Shield")
                    return true
                end,
            },
            {
                name = "Equip DW",
                type = "CustomFunc",
                cond = function(self)
                    if mq.TLO.Me.Bandolier("DW").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('EquipDW') and not self.Helpers.shieldNeeded()
                end,
                custom_func = function(self)
                    ItemManager.BandolierSwap("DW")
                    return true
                end,
            },
        },
        ['Defenses'] = {
            { --shares effect with OoW Chest and Warlord's Bravery
                name = "StandDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return self.Helpers.DefenseBuffCheck(self)
                end,
            },
            { --shares effect with StandDisc and Warlord's Bravery
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName)
                    return self.Helpers.DefenseBuffCheck(self)
                end,
            },
            { --shares effect with StandDisc and OoW_Chest
                name = "Warlord's Bravery",
                type = "AA",
                cond = function(self, aaName)
                    return self.Helpers.DefenseBuffCheck(self)
                end,
            },
            {
                name = "MaxEffort",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive() and self.Helpers.DefenseBuffCheck(self)
                end,
            },
            {
                name = "Hold the Line",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
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
        },
        ['Burn'] = {
            {
                name_func = function(self)
                    return string.format("Fundament: %s Spire of the Warlord", Core.IsTanking() and "Third" or "Second")
                end,
                type = "AA",
            },
            {
                name = "Onslaught",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Core.IsTanking() and self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "StrikeDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Core.IsTanking() and self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "Vehement Rage",
                type = "AA",
                cond = function(self, aaName)
                    return not Core.IsTanking()
                end,
            },
            {
                name = "Rampage",
                type = "AA",
                load_cond = function(self) return not (Core.IsTanking() and Config:GetSetting('DoAETaunt')) end,
                cond = function(self, aaName, target)
                    if not Config:GetSetting("DoAEDamage") then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "Rage of Rallos Zek",
                type = "AA",
            },
            {
                name = "Warlord's Fury",
                type = "AA",
                cond = function(self, aaName, target)
                    return Core.IsTanking() and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Battered Smuggler's Barrel",
                type = "Item",
            },
            {
                name = "Resplendent Glory",
                type = "AA",
                cond = function(self, aaName)
                    return Core.IsTanking()
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Buffs'] = {
            {
                name = "GroupACBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Infused by Rage",
                type = "AA",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Combat'] = {
            {
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Battle Leap",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoBattleLeap') then return false end
                    return not Casting.IHaveBuff(aaName) and not Casting.IHaveBuff('Group Bestial Alignment')
                        and not mq.TLO.Me.HeadWet() --Stops Leap from launching us above the water's surface
                end,
            },
            {
                name = "AbsorbTaunt",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Core.IsTanking()
                end,
            },
            {
                name = "Flaunt",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return not Core.IsTanking()
                end,
            },
            {
                name = "Gut Punch",
                type = "AA",
                cond = function(self, aaName, target)
                    return Core.IsTanking()
                end,
            },
            {
                name = "Knee Strike",
                type = "AA",
            },
            {
                name = "Throat",
                type = "Disc",
            },
            {
                name = "Call of Challenge",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSnare') then return false end
                    return Casting.DetAACheck(aaName) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "Press the Attack",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting("DoPress") then return false end
                    return Core.IsTanking()
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Core.ShieldEquipped()
                end,
            },
            {
                name = "Slam",
                type = "Ability",
                load_cond = function(self) return mq.TLO.Me.Ability("Slam")() end,
            },
            {
                name = "Kick",
                type = "Ability",
            },
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
            Max = 2,
            FAQ = "What do the different Modes Do?",
            Answer = "Tank Mode is for when you are the main tank. DPS Mode is for when you are not the main tank and want to focus on damage.",
        },

        --Abilities
        ['DoBattleLeap']    = {
            DisplayName = "Do Battle Leap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Do Battle Leap",
            Default = true,
        },
        ['DoPress']         = {
            DisplayName = "Do Press the Attack",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Tooltip = "Use the Press to Attack stun/push AA.",
            Default = false,
        },
        ['DoSnare']         = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Tooltip = "Use Call of Challenge to snare enemies.",
            Default = true,
        },
        ['DoVetAA']         = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 104,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },

        -- AE Damage
        --Hate Tools
        ['DoAETaunt']       = {
            DisplayName = "Do AE Taunts",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use AE hatred Discs and AA (see FAQ for specifics).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['UseScowl']        = {
            DisplayName = "Use Scowl",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 102,
            Tooltip = "Use Scowl for a taunt and melee absorb instead of your timer 8 hate disc.",
            RequiresLoadoutChange = true,
            Default = false,
        },

        --Defenses
        ['DiscCount']       = {
            DisplayName = "Def. Disc. Count",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 101,
            Tooltip = "Number of mobs around you before you use preemptively use Defensive Discs.",
            Default = 4,
            Min = 1,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['DefenseStart']    = {
            DisplayName = "Defense HP",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 102,
            Tooltip = "The HP % where we will use defensive actions like discs, epics, etc.\nNote that fighting a named will also trigger these actions.",
            Default = 60,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['EmergencyStart']  = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 103,
            Tooltip = "The HP % before all but essential rotations are cut in favor of emergency or defensive abilities.",
            Default = 40,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['HPCritical']      = {
            DisplayName = "HP Critical",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 104,
            Tooltip =
            "The HP % that most other rotations are cut to give our full focus to survival.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },

        --Equipment
        ['DoEpic']          = {
            DisplayName = "Do Epic",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your Epic Weapon when AE Threat is needed. Also relies on Do AE Damage setting.",
            Default = false,
        },
        ['DoCoating']       = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood Drinker's Coating when defenses are triggered.",
            Default = false,
        },
        ['UseBandolier']    = {
            DisplayName = "Dynamic Weapon Swap",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 101,
            Tooltip = "Enable 1H+S/2H swapping based off of current health. ***YOU MUST HAVE BANDOLIER ENTRIES NAMED \"Shield\" and \"DW\" TO USE THIS FUNCTION.***",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['EquipShield']     = {
            DisplayName = "Equip Shield",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 102,
            Tooltip = "Under this HP%, you will swap to your \"Shield\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 50,
            Min = 1,
            Max = 100,
        },
        ['EquipDW']         = {
            DisplayName = "Equip DW",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 103,
            Tooltip = "Over this HP%, you will swap to your \"DW\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 75,
            Min = 1,
            Max = 100,
        },
        ['NamedShieldLock'] = {
            DisplayName = "Shield on Named",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 104,
            Tooltip = "Keep Shield equipped while tanking a named.",
            Default = true,
            FAQ = "Why does my WAR switch to a Shield on puny gray named?",
            Answer = "The Shield on Named option doesn't check levels, so feel free to disable this setting (or Bandolier swapping entirely) if you are farming fodder.",
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

return _ClassConfig
