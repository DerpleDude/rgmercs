local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require("utils.globals")
local Core      = require("utils.core")
local Movement  = require("utils.movement")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Strings   = require("utils.strings")
local Logger    = require("utils.logger")

return {
    _version          = "2.1 - Project Lazarus",
    _author           = "Derple, Algar, mackal",
    ['Modes']         = {
        'DPS',
    },
    ['ItemSets']      = {
        ['OoW_Chest'] = {
            "Whisperer's Ascendant Tunic of Shadows",
            "Whispering Tunic of Shadows",
            "Darkraider's Vest",
        },
        ['Epic'] = {
            "Fatestealer",
            "Nightshade, Blade of Entropy",
        },
    },
    ['AbilitySets']   = {
        ["ThiefBuff"] = {
            "Brigand's Gaze", -- Level 70
            "Thief's Eyes",   -- Level 65
        },
        ["Kinesthetics"] = {
            "Kinesthetics Discipline", -- Level 57
        },
        ['Duelist'] = {
            "Duelist Discipline", -- Level 59
        },
        ["ChanceDisc"] = {
            "Twisted Chance Discipline", -- Level 65
            "Deadeye Discipline",        -- Level 54
        },
        ["Frenzied"] = {
            "Frenzied Stabbing Discipline", -- Level 70
        },
        ["SneakAttack"] = {
            "Razorarc",              -- Level 70
            "Daggerfall",            -- Level 69
            "Ancient: Chaos Strike", -- Level 65
            "Kyv Strike",            -- Level 65
            "Assassin's Strike",     -- Level 63
            "Thief's Vengeance",     -- Level 52
            "Sneak Attack",          -- Level 20
        },
        ["FellStrike"] = {
            "Assault", -- Level 70 on Laz
        },
        ["Pinpoint"] = {
            "Pinpoint Vulnerability", -- Level 69 on Laz
        },
        ['EndRegen'] = {
            "Third Wind Discipline",
            --"Second Wind",
        },
        ["CADisc"] = {
            "Counterattack Discipline",
        },
        ["AimDisc"] = {
            "Deadly Aim Discipline", --  Level 68
        },
        ['Precision'] = {
            "Deadly Precision Discipline",
        },
        ['Nimble'] = {
            "Nimble Discipline",
        },

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
            name = 'Hide & Sneak',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.AmIBuffable()
            end,
        },
        {
            name = 'Aggro Management',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctAggro() > Config:GetSetting('HideAggro')
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
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
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
        ['Burn'] = {
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName, target)
                    return Casting.DetItemCheck(itemName, target)
                end,
            },
            {
                name = "Rogue's Fury",
                type = "AA",
            },
            {
                name = "Fundament: Second Spire of the Rake",
                type = "AA",
            },
            {
                name = "Pinpoint",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell, target)
                end,
            },
            {
                name = "Dirty Fighting",
                type = "AA",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['BurnDisc'] = {
            {
                name = "Frenzied",
                type = "Disc",
            },
            {
                name = "Duelist",
                type = "Disc",
            },
            {
                name = "ChanceDisc",
                type = "Disc",
            },
            {
                name = "Kinesthetics",
                type = "Disc",
            },
            {
                name = "Precision",
                type = "Disc",
            },
        },
        ["Aggro Management"] = {
            {
                name = "Escape",
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Hide",
                type = "Ability",
                pre_activate = function(self, abilityName)
                    if Core.OnEMU() then
                        Core.DoCmd("/attack off")
                        mq.delay(100, function() return not mq.TLO.Me.Combat() end)
                    end
                end,
                cond = function(self)
                    return not mq.TLO.Me.Moving() or (mq.TLO.Me.AltAbility("Nimble Evasion").Rank() or 0) == 5
                end,
                post_activate = function(self, abilityName, success)
                    if not mq.TLO.Me.Combat() then
                        Core.DoCmd("/attack on")
                    end
                end,
            },
            {
                name = "Sleight of Hand",
                type = "AA",
            },
        },
        ['DPS'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "Ligament Slice",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "Backstab",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Casting.CanUseAA("Chaotic Stab") or mq.TLO.Stick.Behind()
                end,
            },
            {
                name = "FellStrike",
                type = "Disc",
            },
            {
                name = "Twisted Shank",
                type = "AA",
            },
            {
                name = "PoisonName",
                type = "ClickyItem",
                cond = function(self)
                    return Casting.SelfBuffItemCheck(Config:GetSetting('PoisonName'))
                end,
            },
            {
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Nimble",
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
                    return mq.TLO.Me.PctHPs() < 35 and not mq.TLO.Me.Buff("Nimble Effect")()
                end,
            },
            {
                name = "Tumble",
                type = "AA",
            },
            {
                name = "Blood Drinker's Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "CADisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Targeting.IHaveAggro(100)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "ThiefBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "PoisonClicky",
                type = "ClickyItem",
                active_cond = function(self, _)
                    return (mq.TLO.FindItemCount(Config:GetSetting('PoisonName'))() or 0) >= Config:GetSetting('PoisonItemCount')
                end,
                cond = function(self, _)
                    return (mq.TLO.FindItemCount(Config:GetSetting('PoisonName'))() or 0) < Config:GetSetting('PoisonItemCount') and
                        mq.TLO.Me.ItemReady(Config:GetSetting('PoisonClicky'))()
                end,
            },
            {
                name = "PoisonName",
                type = "ClickyItem",
                active_cond = function(self, _)
                    local poisonItem = mq.TLO.FindItem(Config:GetSetting('PoisonName'))
                    return poisonItem and poisonItem() and Casting.IHaveBuff(poisonItem.Spell.ID() or 0)
                end,
                cond = function(self)
                    return Casting.SelfBuffItemCheck(Config:GetSetting('PoisonName'))
                end,
            },
            {
                name = "Envenomed Blades",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Hide & Sneak'] = {
            {
                name = "Hide & Sneak",
                type = "CustomFunc",
                active_cond = function(self)
                    return mq.TLO.Me.Invis() and mq.TLO.Me.Sneaking()
                end,
                pre_activate = function(self, abilityName)
                    if Core.OnEMU() and mq.TLO.Me.Combat() then
                        Core.DoCmd("/attack off")
                        mq.delay(100, function() return not mq.TLO.Me.Combat() end)
                    end
                end,
                cond = function(self)
                    return Config:GetSetting('DoHideSneak') and (not mq.TLO.Me.Sneaking() or not mq.TLO.Me.Invis())
                end,
                custom_func = function(self)
                    if not mq.TLO.Me.Sneaking() and mq.TLO.Me.AbilityReady("Sneak")() then
                        Core.DoCmd("/doability sneak")
                        mq.delay(200, function() return mq.TLO.Me.Sneaking() end)
                    end
                    if not mq.TLO.Me.Invis() and mq.TLO.Me.AbilityReady("Hide")() then
                        if not mq.TLO.Me.Moving() or (mq.TLO.Me.AltAbility("Nimble Evasion").Rank() or 0) == 5 then
                            Core.DoCmd("/doability hide")
                            mq.delay(100, function() return (mq.TLO.Me.AbilityTimer("Hide")() or 0) > 0 end)
                            ---@diagnostic disable-next-line: undefined-field
                        elseif mq.TLO.Me.Moving() and mq.TLO.Nav.Active() and not mq.TLO.Nav.Paused() then
                            -- let's get crazy: if we are naving, quickly pause and "sneak" a hide in
                            Movement:DoNav(false, "pause")
                            mq.delay(200, function() return not mq.TLO.Me.Moving() end)
                            mq.delay((2 * mq.TLO.EverQuest.Ping()) or 200) --addl delay to avoid "must be perfectly still..." server desync
                            Core.DoCmd("/doability hide")
                            mq.delay(100, function() return (mq.TLO.Me.AbilityTimer("Hide")() or 0) > 0 end)
                            ---@diagnostic disable-next-line: undefined-field
                            if mq.TLO.Nav.Paused() then Movement:DoNav(false, "pause") end
                        end
                    end
                end,
            },
        },
    },
    ['Helpers']       = {
        PreEngage = function(target)
            if not target or not target() then return end
            local openerAbility = Core.GetResolvedActionMapItem('SneakAttack')

            if not Config:GetSetting("DoOpener") or not openerAbility then return end

            Logger.log_debug("\ayPreEngage(): Testing Opener ability = %s", openerAbility or "None")

            if mq.TLO.Me.CombatAbilityReady(openerAbility)() and not mq.TLO.Me.AbilityReady("Hide")() and mq.TLO.Me.AbilityTimer("Hide")() <= math.max(0, mq.TLO.Me.AbilityTimerTotal("Hide")() - 4000) and mq.TLO.Me.Invis() then
                Casting.UseDisc(openerAbility, target.ID())
                Logger.log_debug("\agPreEngage(): Using Opener ability = %s", openerAbility or "None")
            else
                Logger.log_debug("\arPreEngage(): NOT using Opener ability = %s, DoOpener = %s, Hide Ready = %s, Hide Timer = %d, Invis = %s", openerAbility or "None",
                    Strings.BoolToColorString(Config:GetSetting("DoOpener")), Strings.BoolToColorString(mq.TLO.Me.AbilityReady("Hide")()),
                    mq.TLO.Me.AbilityTimer("Hide")(), Strings.BoolToColorString(mq.TLO.Me.Invis()))
            end
        end,
        --function to make sure we don't have non-hostiles in range before we use AE damage

        UnwantedAggroCheck = function(self) --Self-Explanatory. Add isTanking to this if you ever make a mode for roguetanks!
            if Targeting.GetXTHaterCount() == 0 or Core.IAmMA() or mq.TLO.Group.Puller.ID() == mq.TLO.Me.ID() then return false end
            return Targeting.IHaveAggro(100)
        end,
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
            FAQ = "What do the different Modes do?",
            Answer = "Currently Rogues only have DPS mode, this may change in the future",
        },
        -- Poison
        ['PoisonName']      = {
            DisplayName = "Poison Item",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Click the poison you want to use here.",
            Type = "ClickyItem",
            Default = "",
        },
        ['PoisonClicky']    = {
            DisplayName = "Poison Clicky",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Click the poison summoner you want to use here.",
            Type = "ClickyItem",
            Default = "",
        },
        ['PoisonItemCount'] = {
            DisplayName = "Poison Item Count",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Min number of poison before we start summoning more.",
            Default = 3,
            Min = 1,
            Max = 50,
        },
        -- Abilities
        ['DoHideSneak']     = {
            DisplayName = "Do Hide/Sneak Click",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use Hide/Sneak during Downtime.",
            Default = false,
        },
        ['DoOpener']        = {
            DisplayName = "Use Openers",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use Sneak Attack line to start combat (e.g, Daggerslash).",
            Default = true,
        },
        ['EmergencyStart']  = {
            DisplayName = "Emergency HP%",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "Your HP % before we begin to use emergency mitigation abilities.",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['HideAggro']       = {
            DisplayName = "Hide Aggro%",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            Tooltip = "Your Aggro % before we will attempt to Hide from our current target.",
            Default = 90,
            Min = 1,
            Max = 100,
        },
        ['DoVetAA']         = {
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
        --Equipment
        ['UseEpic']         = {
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
        ['DoCoating']       = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood Drinker's Coating in an emergency.",
            Default = false,
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
