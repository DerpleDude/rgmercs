local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local ItemManager  = require("utils.item_manager")
local Logger       = require("utils.logger")
local Set          = require('mq.set')
local Combat       = require("utils.combat")

local _ClassConfig = {
    -- Added Mayhem line for AE taunt
    _version          = "3.1 - EQ Might",
    _author           = "Algar, Derple",
    ['ModeChecks']    = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
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
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Kreljnok's Sword of Eternal Power",
            "Champion's Sword of Eternal Power",
        },
        ['OoW_Chest'] = {
            "Armsmaster's Breastplate",
            "Gladiator's Plate Chestguard of War",
        },
    },
    ['AbilitySets']   = {
        ['StandDisc'] = {             -- Timer 1
            "Final Stand Discipline", -- Level 71
            "Shelter Me Discipline",  -- Level 69
            -- "Stonewall Discipline", -- Level 65
            "Defensive Discipline",   -- Level 55
            "Evasive Discipline",     -- Level 52
        },
        ['StanceDisc'] = {
            "Myrmidon Stance Discipline", -- Level 61
            "Warrior Stance Discipline",  -- Level 40
        },
        ['Fortitude'] = {                 -- Timer 3
            "Fortitude Discipline",       -- Level 59
            "Furious Discipline",         -- Level 56
        },
        ['GroupDodgeBuff'] = {
            "Commanding Voice", -- Level 68
        },
        ['BladeDisc'] = {
            "Vortex Blade",    -- Level 74
            "Cyclone Blade",   -- Level 67
            "Whirlwind Blade", -- Level 61
            "Mayhem Blade",    -- Level 45
        },
        ['AddHate'] = {
            "Ancient: Chaos Cry",    -- Level 65
            "Bellow of the Mastruq", -- Level 65
            "Incite",                -- Level 63
            "Berate",                -- Level 56
            "Bellow",                -- Level 52
            "Provoke",               -- Level 20
        },
        ['AbsorbTaunt'] = {
            "Mock", -- Level 70
        },
        ['EndRegen'] = {
            "Third Wind",  -- Level 77 also does HP
            "Second Wind", -- Level 70
        },
        ['AuraBuff'] = {
            "Champion's Aura", -- Level 66
            "Myrmidon's Aura", -- Level 55
        },
        ['Onslaught'] = {
            "Brutal Onslaught Discipline", -- Level 74
            "Savage Onslaught Discipline", -- Level 68
        },
        ['StrikeDisc'] = {
            "Mighty Blow Discipline",   -- Level 66
            "Fellstrike Discipline",    -- Level 58
            "Mighty Strike Discipline", -- Level 54
        },
        ['Throat'] = {
            "Throat Jab", -- Level 71
        },
        -- ['ShockDisc'] = { -- Timer 7, defensive stun proc
        --     "Shocking Defense Discipline", -- Level 70
        -- },
        ['Protective'] = {
            "Protective Discipline",            -- Level 69
            "Protective Surge Discipline",      -- Level 45
        },
        ['HealingDisc'] = {                     --EQM Custom, 2m duration, 5m reuse, hp regen
            "Lifebloom Will Discipline",        -- Level 70
            "Rejuvenating Will Discipline",     -- Level 68
            "Healing Determination Discipline", -- Level 66
            "Healing Will Discipline",          -- Level 59
        },
        ['Revitalize'] = {
            "Steely Revitalize",      -- Level 69
            "Iron Revitalize",        -- Level 65
            "Hardened Revitalize",    -- Level 55
            "Revitalize",             -- Level 44
        },
        ['BattlecryHeal'] = {         -- EQM Custom, restores HP/End for group, 8m reuse
            "Invigorating Battlecry", -- Level 63
        },
    },
    ['AASets']        = {
        ['AreaTaunt'] = {
            "Enhanced Area Taunt",
            "Area Taunt",
        },
    },
    ['Helpers']       = {
        DoRez = function(self, corpseId)
            local rezStaff = self.ResolvedActionMap['RezStaff']

            if mq.TLO.Me.ItemReady(rezStaff)() then
                if Casting.OkayToRez(corpseId) then
                    return Casting.UseItem(rezStaff, corpseId)
                end
            end

            return false
        end,
        --function to make sure we don't have non-hostiles in range before we use AE damage or non-taunt AE hate abilities

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
            -- Allow healing disc to be cancelled by other defensive discs
            if Casting.NoDiscActive() then return true end
            local healingDisc = Core.GetResolvedActionMapItem('HealingDisc')
            return healingDisc and mq.TLO.Me.ActiveDisc.Name() == healingDisc.RankName()
        end,
        MeleeMitBuffCheck = function(self) -- Make sure we spread out our MeleeMit buffs because only the highest in slot 1 takes effect
            local standDisc = Core.GetResolvedActionMapItem('StandDisc')
            local protective = Core.GetResolvedActionMapItem('Protective')
            local mitEffects = { (standDisc and standDisc.RankName() or ""), (protective and protective.RankName() or ""), "Guardian's Boon", "Guardian's Bravery", }
            for _, buffName in ipairs(mitEffects) do
                if Casting.IHaveBuff(buffName) then return false end
            end
            return true
        end,
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
                if not Core.IsTanking() then return false end
                local bladeDisc = Config:GetSetting('BladeDiscUse') > 1 and Core.GetResolvedActionMapItem('BladeDisc')
                local hateAA = Config:GetSetting('AETauntAA') and Casting.CanUseAA("Area Taunt")
                local epic = Config:GetSetting('DoEpic') and Core.GetResolvedActionMapItem("Epic")
                return bladeDisc or hateAA or epic
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
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.IHaveAggro(100) and
                    -- we are under our defense start HP
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('DefenseStart') or
                        -- we have met our defense count threshold
                        self.Helpers.DefensiveDiscCheck(true) or
                        -- we are fighting a named and we are (presumably) tanking it
                        (Globals.AutoTargetIsNamed and Targeting.GetAutoTargetAggroPct() >= 100))
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        { --Non-threat combat actions
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat"
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
            { --more valuable on laz because we have less hate tools and no other hatelist + 1 abilities
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.GetTargetDistance(target) < 30
                end,
            },
            {
                name = "Xeno's Faceguard",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Xeno's Faceguard")() end,
            },
            {
                name = "Blast of Anger",
                type = "AA",
            },
            {
                name = "Bladed Fang Mantle",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Bladed Fang Mantle")() end,
            },
            {
                name = "AddHate",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "Grappling Strike",
                type = "AA",
            },
            {
                name = "Gut Punch",
                type = "AA",
            },
        },
        ['HateTools(AutoTarget)'] = {
            { --more valuable on laz because we have less hate tools and no other hatelist + 1 abilities
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro() and Targeting.GetTargetDistance(target) < 30
                end,
            },
            { --8min reuse, save for we still can't get a mob back after trying to taunt, try not to use it on the pull
                name = "Ageless Enmity",
                type = "AA",
                cond = function(self, aaName, target)
                    return (Globals.AutoTargetIsNamed or Targeting.GetAutoTargetPctHPs() < 90) and Targeting.LostAutoTargetAggro()
                end,
            },
            {
                name = "Xeno's Faceguard",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Xeno's Faceguard")() end,
            },
            {
                name = "Blast of Anger",
                type = "AA",
            },
            {
                name = "Bladed Fang Mantle",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Bladed Fang Mantle")() end,
            },
            {
                name = "AddHate",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "Grappling Strike",
                type = "AA",
            },
        },
        ['AEHateTools'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    return Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "BladeDisc",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('BladeDiscUse') > 1 end,
                cond = function(self, discSpell)
                    return Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "AreaTaunt",
                type = "AA",
            },
        },
        ['EmergencyDefenses'] = {
            --Note that in Tank Mode, defensive discs are preemptively cycled on named in the (non-emergency) Defenses rotation
            --Abilities should be placed in order of lowest to highest triggered HP thresholds
            {
                name = "Revitalize",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
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
                active_cond = function(self, target)
                    return mq.TLO.Me.Bandolier("Shield").Active()
                end,
                cond = function()
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("Shield") end,
            },
            {
                name = "Equip DW",
                type = "CustomFunc",
                active_cond = function(self, target)
                    return mq.TLO.Me.Bandolier("DW").Active()
                end,
                cond = function()
                    if mq.TLO.Me.Bandolier("DW").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('EquipDW') and not (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("DW") end,
            },
        },
        ['Defenses'] = {
            {
                name = "Protective",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return self.Helpers.DefenseBuffCheck(self)
                end,
            },
            { --shares effect with OoW Chest and Warlord's Bravery
                name = "StandDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return self.Helpers.DefenseBuffCheck(self) and Casting.DiscOnCoolDown('Protective')
                end,
            },
            { --shares effect with StandDisc
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName)
                    return Casting.DiscOnCoolDown('Protective') and Casting.DiscOnCoolDown('StandDisc') and self.Helpers.MeleeMitBuffCheck()
                end,
            },
            { --shares effect with StandDisc and OoW Chest
                name = "Warlord's Bravery",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.DiscOnCoolDown('Protective') and Casting.DiscOnCoolDown('StandDisc') and self.Helpers.MeleeMitBuffCheck()
                end,
            },
            {
                name = "Hold the Line",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.DiscOnCoolDown('Protective') and Casting.DiscOnCoolDown('StandDisc')
                end,
            },
            {
                name = "HealingDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DiscOnCoolDown('Protective') and Casting.DiscOnCoolDown('StandDisc')
                end,
            },

        },
        ['Burn'] = {
            {
                name_func = function(self)
                    return string.format("Fundament: %s Spire of the Warlord", Core.IsTanking() and "First" or "Second")
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
                name = "Rage of Rallos Zek",
                type = "AA",
            },
            {
                name = "BattlecryHeal",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart') or Targeting.BigGroupHealsNeeded()
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
                name = "GroupDodgeBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Battle Leap",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoBattleLeap') then return false end
                    return Casting.SelfBuffAACheck(aaName) and Casting.AddedBuffCheck(16439, target) --Group Bestial Alignment
                        and not mq.TLO.Me.HeadWet()                                                  --Stops Leap from launching us above the water's surface
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
                name = "Gut Punch",
                type = "AA",
                cond = function(self, aaName, target)
                    return Core.IsTanking()
                end,
            },
            {
                name = "BladeDisc",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('BladeDiscUse') == 3 and Core.GetResolvedActionMapItem('BladeDisc') end,
                cond = function(self, discSpell)
                    return Config:GetSetting('DoAEDamage') and mq.TLO.Me.PctEndurance() >= Config:GetSetting("ManaToNuke") -- save endurance for emergency discs
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
                name = "Rampage",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting("DoAEDamage") or Config:GetSetting('UseRampage') == 1 then return false end
                    return (Config:GetSetting('UseRampage') == 3 or (Config:GetSetting('UseRampage') == 2 and Casting.BurnCheck())) and
                        Combat.AETargetCheck(true)
                end,
            },
            {
                name = "Call of Challenge",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSnare') then return false end
                    return Casting.DetAACheck(aaName)
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

        --AE Damage
        ['BladeDiscUse']    = {
            DisplayName = "Blade Disc Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "When to use your AE Blade Disc Line (DPS mode will not attempt to regain hate).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Disabled', 'Only To Regain Hate', 'Whenever Possible', },
            Default = 2,
            Min = 1,
            Max = 3,
        },
        ['UseRampage']      = {
            DisplayName = "Rampage Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            Tooltip = "Use Rampage 1-Never 2-Burns 3-Always",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },

        --Hate Tools
        ['AETauntAA']       = {
            DisplayName = "Use AE Taunt AA",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use the Area Taunt AA.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
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
            Tooltip = "Keep Shield equipped for mobs detected as 'named' by RGMercs (see Named tab).",
            Default = true,
            FAQ = "Why does my WAR switch to a Shield on puny gray named?",
            Answer = "The Shield on Named option doesn't check levels, so feel free to disable this setting (or Bandolier swapping entirely) if you are farming fodder.",
        },
    },
    ['ClassFAQ']      = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is currently a Work-In-Progress that was originally based off of the Project Lazarus config.\n\n" ..
                "  Up until level 71, it should work quite well, but may need some clickies managed on the clickies tab.\n\n" ..
                "  After level 65, expect performance to degrade somewhat as not all EQMight custom spells or items are added, and some Laz-specific entries may remain.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
