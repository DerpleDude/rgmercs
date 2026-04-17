-- Clicky Module
local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Core      = require('utils.core')
local Comms     = require('utils.comms')
local Combat    = require('utils.combat')
local Casting   = require("utils.casting")
local Strings   = require("utils.strings")
local Ui        = require("utils.ui")
local Logger    = require("utils.logger")
local Targeting = require("utils.targeting")
local Tables    = require("utils.tables")
local Modules   = require("utils.modules")
local Set       = require('mq.set')
local Icons     = require('mq.ICONS')
local Base      = require("modules.base")
local animItems = mq.FindTextureAnimation("A_DragItem")

local Module    = { _version = '0.1a', _name = "Clickies", _author = 'Derple', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })

Module.FAQ                                 = {
    {
        Question = "How do I set RGmercs up to use a clicky item?",
        Answer = "  Using the GUI on the Clickies tab, you can add, remove and organize clickies you would like your PCs to use, under customizable conditions.\n\n" ..
            "  If we don't currently support the clicky by default***, you can use the GUI to add items and conditions as you see fit.\nCan't quite find the right conditions in the Clickies Logic Blocks? Feedback is highly welcome. Please bear in mind that some conditions are restricted due to technical limitations.\n\n" ..
            "  Ultimately, it is important to realize that class configs have better access to functions and conditions to fine-tune the use of a clicky, and for best results, some clickies may need to be added there instead.\n\n" ..
            "  Feedback on the default configs is welcome, but creating a custom config of your own is another possibility.\n\n" ..
            "  *** - Some clickies are already handled by default, or by a class config (like modrods). Options for these items are generally found in (Options > Items > Clickies). Additionally, some non-optional defaults may have Rotation Entries, which can be viewed on the Class tab.",
        Settings_Used = "",
    },
}

Module.ClickyRotationIndex                 = 1

Module.CommandHandlers                     = {
    enableclicky = {
        usage = "/rgl enableclicky <clicky name|idx>",
        about = "Enables the clicky item with the specified name or index.",
        handler =
            function(self, clickyName)
                local clickies = Config:GetSetting('Clickies')
                local clickyFound = false

                local index = tonumber(clickyName)

                if index and (index < 1 or index > #clickies) then
                    Logger.log_error("Invalid clicky index: %d. Valid range is 1 to %d.", index, #clickies)
                    return true
                end

                if index then
                    clickies[index].enabled = true
                    clickyFound = true
                else
                    for clickyIdx, clicky in ipairs(clickies) do
                        if (index and clickyIdx == index) or clicky.itemName:lower() == clickyName:lower() then
                            clickyFound = true
                            clicky.enabled = true
                            -- dont break because there might be more than 1
                        end
                    end
                end
                if clickyFound then
                    Config:SetSetting('Clickies', clickies)
                end
                return true
            end,
    },
    disableclicky = {
        usage = "/rgl disableclicky <clicky name|idx>",
        about = "Disables the clicky item with the specified name or index.",
        handler =
            function(self, clickyName)
                local clickies = Config:GetSetting('Clickies')
                local clickyFound = false

                local index = tonumber(clickyName)

                if index and (index < 1 or index > #clickies) then
                    Logger.log_error("Invalid clicky index: %d. Valid range is 1 to %d.", index, #clickies)
                    return true
                end

                if index then
                    clickies[index].enabled = false
                    clickyFound = true
                else
                    for clickyIdx, clicky in ipairs(clickies) do
                        if (index and clickyIdx == index) or clicky.itemName:lower() == clickyName:lower() then
                            clickyFound = true
                            clicky.enabled = false
                            -- dont break because there might be more than 1
                        end
                    end
                end
                if clickyFound then
                    Config:SetSetting('Clickies', clickies)
                end
                return true
            end,
    },
}

Module.TempSettings                        = {}
Module.TempSettings.ClickyState            = {}
Module.TempSettings.ConditionsCache        = {}
Module.TempSettings.CombatClickiesTimer    = 0
Module.TempSettings.ClickyDropFrame        = {}
Module.TempSettings.ClickyHeaderOpen       = {}
Module.TempSettings.RotationComboIdx       = {}
Module.TempSettings.RotationNamesCache     = nil
Module.TempSettings.RotationNameSet        = nil
Module.TempSettings.HealRotationNamesCache = nil
Module.TempSettings.HealRotationNameSet    = nil

Module.DefaultServerClickies               = {
    ['Project Lazarus'] = {
        [1] = {
            ['conditions'] = {
                [1] = {
                    target = 'Self',
                    args = {
                        [1] = 0,
                        [2] = 30,
                    },
                    type = 'HP Threshold',
                },
            },
            ['iconId'] = 2484,
            ['itemName'] = 'Draught of Opulent Healing I',
            ['target'] = 'Self',
            ['combat_state'] = 'Combat',
        },
        [2] = {
            ['conditions'] = {
                [1] = {
                    ['target'] = 'Main Assist',
                    ['args'] = {
                        [1] = 0,
                        [2] = 40,
                    },
                    ['type'] = 'HP Threshold',
                },
            },
            ['iconId'] = 1002,
            ['itemName'] = 'Orb of Shadows',
            ['target'] = 'Main Assist',
            ['combat_state'] = 'Combat',
        },
        [3] = {
            ['conditions'] = {
                [1] = {
                    ['target'] = 'Self',
                    ['args'] = {
                        [1] = 0,
                        [2] = 40,
                    },
                    ['type'] = 'HP Threshold',
                },
            },
            ['iconId'] = 936,
            ['itemName'] = 'Sanguine Mind Crystal III',
            ['target'] = 'Self',
            ['combat_state'] = 'Combat',
        },
        [4] = {
            ['conditions'] = {
                [1] = {
                    ['target'] = 'Self',
                    ['args'] = {
                        [1] = 0,
                        [2] = 40,
                        [3] = 0,
                        [4] = 40,
                        [5] = 0,
                        [6] = 40,
                    },
                    ['type'] = 'Any Threshold',
                },
            },
            ['iconId'] = 178,
            ['itemName'] = 'Forsaken Fungus Covered Scale Tunic',
            ['target'] = 'Self',
            ['combat_state'] = 'Combat',
        },
        [5] = {
            ['conditions'] = {
                [1] = {
                    ['target'] = 'Self',
                    ['args'] = {
                        [1] = 0,
                        [2] = 50,
                    },
                    ['type'] = 'HP Threshold',
                },
            },
            ['iconId'] = 1002,
            ['itemName'] = 'Orb of Shadows',
            ['target'] = 'Self',
            ['combat_state'] = 'Combat',
        },
    },

    ['EQ Might']        = {
        [1] = {
            ['target'] = 'Self',
            ['combat_state'] = 'Downtime',
            ['itemName'] = 'Ring of the Warden',
            ['conditions'] = {},
            ['iconId'] = 6136,
        },
    },
}

Module.DefaultConfig                       = {
    ['MaxClickiesPerFrame']                    = {
        DisplayName = "Max Clickies Per Frame",
        Group = "Items",
        Header = "Clickies",
        Category = "User Clickies",
        Index = 1,
        Tooltip =
        "The max number of clickies that can successfully be used per frame/processing cycle before we move on, 0 for no limit.\nThis setting may help prevent delays in other processing if a high number of clickies are used.",
        Default = 0,
        Min = 0,
        Max = 99,
        ConfigType = "Advanced",
    },
    ['Clickies']                               = {
        DisplayName = "Item %d",
        Category    = "Clickies",
        Tooltip     = "Clicky Item to use",
        Type        = "Custom",
        Default     = {},
        ConfigType  = "Normal",
        OnChange    = function()
            Modules:ExecModule("Class", "GetRotations")
        end,
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
}

Module.CombatTargetTypes                   = { 'Self', 'Pet', 'Main Assist', 'Auto Target', 'Mercs Peer', }
Module.NonCombatTargetTypes                = { 'Self', 'Pet', 'Main Assist', 'Mercs Peer', }
Module.RotationTargetTypes                 = { 'Rotation Target', }
Module.MercPeerTargetTypes                 = { 'Mercs Peer', }
Module.CombatStates                        = { 'Downtime', 'Combat', 'Any', 'During Rotation', 'During Heal Rotation', }
Module.ImpliedCondition                    = {
    render_header_text = function(_, _)
        return "Not already active and will stack on the target"
    end,
}

-- each of these becomes a condition you can set per clickie
Module.LogicBlocks                         = {
    {
        name = "None",
        cond = function(self, target, peerData) return true end,
        tooltip = "No condition, always true.",
        render_header_text = function(self, cond)
            return string.format("No Condition")
        end,
        args = {},
    },

    {
        name = "HP Threshold",
        cond = function(self, target, peerData, aboveHP, belowHP)
            local pctHPs = -999
            local targetName = target and target.CleanName() or peerData and peerData.Name or "None"

            if target and target() then
                pctHPs = target.PctHPs() or 0
            elseif peerData and peerData.ID then
                pctHPs = peerData.HPs
            end

            if pctHPs == -999 then
                return false
            end

            Logger.log_super_verbose("\ayClicky: \ayClicky: \awHP Threshold condition check on \at%s\aw, aboveHP(\a-t%d\aw/%s) belowHP(\a-t%d\aw/%s) pctHPs(\a-t%d\aw)",
                targetName, aboveHP, Strings.BoolToColorString((pctHPs >= aboveHP)), belowHP, Strings.BoolToColorString((pctHPs <= belowHP)),
                pctHPs)

            if not (pctHPs >= aboveHP) then
                return false
            end
            if not (pctHPs <= belowHP) then
                return false
            end

            return true
        end,
        cond_targets = Module.CombatTargetTypes,
        tooltip = "Only use if [target] HP is above/below this percent.",
        render_header_text = function(self, cond)
            return string.format("HP of %s is between %d%% and %d%%", cond.target or "Self", cond.args[1] or 0, cond.args[2] or 100)
        end,
        args = {
            { name = ">= HP %", type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= HP %", type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "Mana Threshold",
        cond = function(self, target, peerData, aboveMana, belowMana)
            local pctMana = -999
            local targetName = target and target.CleanName() or peerData and peerData.Name or "None"

            if target and target() then
                pctMana = target.PctMana() or 0
            elseif peerData and peerData.ID then
                pctMana = peerData.Mana
            end

            if pctMana == -999 then
                return false
            end

            Logger.log_super_verbose("\ayClicky: \ayClicky: \awMana Threshold condition check on \at%s\aw, aboveMana(\a-t%d\aw/%s) belowMana(\a-t%d\aw/%s) pctMana(\a-t%d\aw)",
                targetName, aboveMana, Strings.BoolToColorString((pctMana >= aboveMana)), belowMana, Strings.BoolToColorString((pctMana <= belowMana)), pctMana)

            if not (pctMana >= aboveMana) then
                return false
            end
            if not (pctMana <= belowMana) then
                return false
            end

            return true
        end,
        cond_targets = Module.NonCombatTargetTypes,
        tooltip = "Only use if [target] Mana is above/below this percent.",
        render_header_text = function(self, cond)
            return string.format("Mana of %s is between %d%% and %d%%", cond.target or "Self", cond.args[1] or 0, cond.args[2] or 100)
        end,
        args = {
            { name = ">= Mana %", type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= Mana %", type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "Endurance Threshold",
        cond = function(self, target, peerData, aboveEndurance, belowEndurance)
            local pctEndurance = -999
            local targetName = target and target.CleanName() or peerData and peerData.Name or "None"

            if target and target() then
                pctEndurance = target.PctEndurance() or 0
            elseif peerData and peerData.ID then
                pctEndurance = peerData.Endurance
            end

            if pctEndurance == -999 then
                return false
            end

            Logger.log_super_verbose(
                "\ayClicky: \ayClicky: \awEndurance Threshold condition check on \at%s\aw, aboveEndurance(\a-t%d\aw/%s) belowEndurance(\a-t%d\aw/%s) pctEndurance(\a-t%d\aw)",
                targetName, aboveEndurance, Strings.BoolToColorString((pctEndurance >= aboveEndurance)), belowEndurance,
                Strings.BoolToColorString((pctEndurance <= belowEndurance)), pctEndurance)

            if not (pctEndurance >= aboveEndurance) then
                return false
            end
            if not (pctEndurance <= belowEndurance) then
                return false
            end

            return true
        end,
        cond_targets = Module.NonCombatTargetTypes,
        tooltip = "Only use if [target] Endurance is above/below this percent.",
        render_header_text = function(self, cond)
            return string.format("Endurance of %s is between %d%% and %d%%", cond.target or "Self", cond.args[1] or 0, cond.args[2] or 100)
        end,
        args = {
            { name = ">= Endurance %", type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= Endurance %", type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "Any Threshold",
        cond = function(self, target, peerData, aboveHP, belowHP, aboveMana, belowMana, aboveEndurance, belowEndurance)
            local pctEndurance = -999
            local pctMana = -999
            local pctHPs = -999

            if target and target() then
                pctEndurance = target.PctEndurance() or 0
                pctMana = target.PctMana() or 0
                pctHPs = target.PctHPs() or 0
            elseif peerData and peerData.ID then
                pctEndurance = peerData.Endurance
                pctMana = peerData.Mana
                pctHPs = peerData.HP
            end

            if pctHPs >= aboveHP and pctHPs <= belowHP then
                return true
            end

            if pctMana >= aboveMana and pctMana <= belowMana then
                return true
            end

            if pctEndurance >= aboveEndurance and pctEndurance <= belowEndurance then
                return true
            end

            return false
        end,
        cond_targets = Module.NonCombatTargetTypes,
        tooltip = "Only use if [target] vitals are above/below these percents.",
        render_header_text = function(self, cond)
            return string.format("%s is between [%d%% >= HP <= %d%%] or [%d%% >= Mana <= %d%%] or [%d%% >= End <= %d%%]", cond.target or "Self",
                cond.args[1] or 0, cond.args[2] or 100,
                cond.args[3] or 0, cond.args[4] or 100,
                cond.args[5] or 0, cond.args[6] or 100)
        end,
        args = {
            { name = ">= HP %",        type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= HP %",        type = "number", default = 100, min = 0, max = 100, },
            { name = ">= Mana %",      type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= Mana %",      type = "number", default = 100, min = 0, max = 100, },
            { name = ">= Endurance %", type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= Endurance %", type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "Group Injured Count",
        cond = function(self, target, peerData, hp, cnt)
            return (mq.TLO.Group.Injured(hp)() or 0) >= cnt
        end,
        tooltip = "Only use if [Count] group members are below [X] HP%.",
        render_header_text = function(self, cond)
            return string.format("%d group members are <= %d%% HP", cond.args[1] or 0, cond.args[2] or 100)
        end,
        args = {
            { name = "Grp Count", type = "number", default = 0,   min = 0, max = 6, },
            { name = "<= HP %",   type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "I Have Effect",
        cond = function(self, target, peerData, effect, negate)
            local hasEffect = Casting.IHaveBuff(effect)
            if negate then
                return not hasEffect
            else
                return hasEffect
            end
        end,
        tooltip = "Only use when you (do not) have this buff or song effect on you. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("You %s Effect '%s'", cond.args[2] and "don't have" or "have", cond.args[1] or "None")
        end,
        cond_targets = { "Self", },
        args = {
            { name = "Effect", type = "string",  default = "", },
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "I Have a Curable Detrimental Effect",
        cond = function(self, target, peerData, checkPoi, checkDis, checkCur, checkCor)
            local me = mq.TLO.Me
            return (checkPoi and me.Poisoned() ~= nil) or
                (checkDis and me.Diseased() ~= nil) or
                (checkCur and me.Cursed() ~= nil) or
                (checkCor and me.Corrupted() ~= nil)
        end,
        tooltip = "Only use when you have a poison, disease, curse or corruption effect on you.",
        render_header_text = function(self, cond)
            local header = "You have an effect with counters ("
            local anyChecked = false
            if cond.args[1] then
                header = header .. "Poison or "
                anyChecked = true
            end
            if cond.args[2] then
                header = header .. "Disease or "
                anyChecked = true
            end
            if cond.args[3] then
                header = header .. "Curse or "
                anyChecked = true
            end
            if cond.args[4] then
                header = header .. "Corruption or "
                anyChecked = true
            end
            if anyChecked then
                header = header:sub(0, -5) -- remove the last " or "
            else
                header = header .. "None"
            end
            header = header .. ")"
            return header
        end,
        cond_targets = { "Self", },
        args = {
            { name = "Poison",     type = "boolean", default = true, },
            { name = "Disease",    type = "boolean", default = true, },
            { name = "Curse",      type = "boolean", default = true, },
            { name = "Corruption", type = "boolean", default = true, },
        },
    },

    {
        name = "I Have A Pet",
        cond = function(self, _, peerData, negate)
            if negate then
                return mq.TLO.Me.Pet.ID() == 0
            else
                return mq.TLO.Me.Pet.ID() > 0
            end
        end,
        tooltip = "Only use this when I have a pet. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("You %s a pet.", cond.args[1] and "don't have" or "have")
        end,
        cond_targets = { "Self", },
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "My Pet Has Effect",
        cond = function(self, _, peerData, effect, negate)
            local hasEffect = not Casting.PetBuffCheck(mq.TLO.Spell(effect)) -- this will return false if the pet has it
            if negate then
                return not hasEffect
            else
                return hasEffect
            end
        end,
        tooltip = "Only use when this effect is (not) present on your pet. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("Your Pet %s Effect '%s'", cond.args[2] and "doesn't have" or "has", cond.args[1] or "None")
        end,
        cond_targets = { "Pet", },
        args = {
            { name = "Effect", type = "string",  default = "", },
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "My Pet Has a Primary Equipped",
        cond = function(self, _, peerData, negate)
            local primaryEquiped = mq.TLO.Me.Pet.Primary() > 0
            return ((not negate and primaryEquiped) or (negate and not primaryEquiped))
        end,
        tooltip = "Only use when this when your pet has (doesn't have) a primary weapon equiped.",
        render_header_text = function(self, cond)
            return string.format("Your Pet %s a Primary weapon equiped.", cond.args[1] and "doesn't have" or "has")
        end,
        cond_targets = { "Pet", },
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "My Pet Has a Secondary Equipped",
        cond = function(self, _, peerData, negate)
            local secondaryEquiped = mq.TLO.Me.Pet.Secondary() > 0
            return ((not negate and secondaryEquiped) or (negate and not secondaryEquiped))
        end,
        tooltip = "Only use when this when your pet has (doesn't have) a secondary item equiped.",
        render_header_text = function(self, cond)
            return string.format("Your Pet %s a Secondary weapon equiped.", cond.args[1] and "doesn't have" or "has")
        end,
        cond_targets = { "Pet", },
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "Your Aggro Percent",
        cond = function(self, target, peerData, aboveAggro, belowAggro)
            if not target or not target() then
                return false
            end

            if target.ID() ~= mq.TLO.Target.ID() then return false end

            local pctAggro = mq.TLO.Target.PctAggro() or 0

            Logger.log_super_verbose("\ayClicky: \ayClicky: \awYour Aggro condition check on \at%s\aw, aboveAggro(\a-t%d\aw/%s) belowAggro(\a-t%d\aw/%s) pctAggro(\a-t%d\aw)",
                target.CleanName() or "None", aboveAggro, Strings.BoolToColorString((pctAggro >= aboveAggro)), belowAggro,
                Strings.BoolToColorString((pctAggro <= belowAggro)), pctAggro)

            if not (pctAggro >= aboveAggro) then
                return false
            end
            if not (pctAggro <= belowAggro) then
                return false
            end

            return true
        end,
        cond_targets = { "Auto Target", },
        tooltip = "Only use if your aggro on the RGMercs combat auto target is above/below this percent.",
        render_header_text = function(self, cond)
            return string.format("Your aggro on the Auto Target is between %d%% and %d%%", cond.args[1] or 0, cond.args[2] or 100)
        end,
        args = {
            { name = ">= Aggro %", type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= Aggro %", type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "Secondary Aggro Percent",
        cond = function(self, target, peerData, aboveAggro, belowAggro)
            if not target or not target() then
                return false
            end

            if target.ID() ~= mq.TLO.Target.ID() then return false end

            local pctAggro = mq.TLO.Target.SecondaryPctAggro() or 0

            Logger.log_super_verbose(
                "\ayClicky: \ayClicky: \awSecondary Aggro Threshold condition check on \at%s\aw, aboveAggro(\a-t%d\aw/%s) belowAggro(\a-t%d\aw/%s) pctAggro(\a-t%d\aw)",
                target.CleanName() or "None", aboveAggro, Strings.BoolToColorString((pctAggro >= aboveAggro)), belowAggro,
                Strings.BoolToColorString((pctAggro <= belowAggro)), pctAggro)

            if not (pctAggro >= aboveAggro) then
                return false
            end
            if not (pctAggro <= belowAggro) then
                return false
            end

            return true
        end,
        cond_targets = { "Auto Target", },
        tooltip = "Only use if the secondary (next-highest) aggro on the RGMercs combat auto target is above/below this percent.",
        render_header_text = function(self, cond)
            return string.format("Auto Target secondary aggro is between %d%% and %d%%", cond.args[1] or 0, cond.args[2] or 100)
        end,
        args = {
            { name = ">= Aggro %", type = "number", default = 0,   min = 0, max = 100, },
            { name = "<= Aggro %", type = "number", default = 100, min = 0, max = 100, },
        },
    },

    {
        name = "XT Hater Count",
        cond = function(self, target, peerData, aboveCount, belowCount)
            local haterCount = Targeting.GetXTHaterCount()

            Logger.log_super_verbose(
                "\ayClicky: \ayClicky: \awXT Hater Count condition check, aboveCount(\a-t%d\aw/%s) belowCount(\a-t%d\aw/%s) pctAggro(\a-t%d\aw)", aboveCount,
                Strings.BoolToColorString((haterCount >= aboveCount)), belowCount, Strings.BoolToColorString((haterCount <= belowCount)), haterCount)

            if not (haterCount >= aboveCount) then
                return false
            end
            if not (haterCount <= belowCount) then
                return false
            end

            return true
        end,
        tooltip = "Only use if haters on your XTarget are above/below this count.",
        render_header_text = function(self, cond)
            return string.format("XT Hater Count is between %d and %d", cond.args[1] or 0, cond.args[2] or 50)
        end,
        args = {
            { name = ">= Count", type = "number", default = 0,  min = 0, max = 50, },
            { name = "<= Count", type = "number", default = 50, min = 0, max = 50, },
        },
    },

    {
        name = "During Burns",
        cond = function(self, target, peerData, negate)
            local burning = Casting.BurnCheck()
            if negate then
                return not burning
            else
                return burning
            end
        end,
        tooltip = "Only use when burns are (not) active. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("Burning is %sactivated", cond.args[1] and "not " or "")
        end,
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "No Disc is Active",
        cond = function(self, target, peerData, negate)
            if negate then
                return not Casting.NoDiscActive()
            else
                return Casting.NoDiscActive()
            end
        end,
        tooltip = "Only use when there is no/(any) active Disc. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("%s disc is active.", cond.args[1] and "Any" or "No")
        end,
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "Target Has (High/Low) HP",
        cond = function(self, target, peerData, negate)
            if negate then
                return Targeting.MobHasLowHP(target)
            else
                return Targeting.MobNotLowHP(target)
            end
        end,
        cond_targets = { "Auto Target", },
        tooltip = "Only use when RGMercs auto target has health above(below) the Low HP setting. Detects Named to use the correct value. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("Target has %s HP.", cond.args[1] and "low" or "high")
        end,
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "Target Is Not Immune To ...",
        cond = function(self, target, peerData, checkSlow, checkSnare, checkStun)
            return (checkSlow and not Casting.SlowImmuneTarget(target)) or
                (checkSnare and not Casting.SnareImmuneTarget(target)) or
                (checkStun and not Casting.StunImmuneTarget(target))
        end,
        tooltip = "Only use when the target is not immune to an effect.",
        render_header_text = function(self, cond)
            local header = "Target is not immune to ("
            local anyChecked = false
            if cond.args[1] then
                header = header .. "Slow or "
                anyChecked = true
            end
            if cond.args[2] then
                header = header .. "Snare or "
                anyChecked = true
            end
            if cond.args[3] then
                header = header .. "Stun or "
                anyChecked = true
            end
            if anyChecked then
                header = header:sub(0, -5) -- remove the last " or "
            else
                header = header .. "None"
            end
            header = header .. ")"
            return header
        end,
        cond_targets = { "Auto Target", },
        args = {
            { name = "Slow",  type = "boolean", default = true, },
            { name = "Snare", type = "boolean", default = true, },
            { name = "Stun",  type = "boolean", default = true, },
        },
    },

    {
        name = "Target Body Type Is ...",
        cond = function(self, target, peerData, checkUndead, checkSummoned)
            return (checkUndead and Targeting.TargetBodyIs(target, "Undead")) or
                (checkSummoned and Targeting.TargetBodyIs(target, "Undead Pet"))
        end,
        tooltip = "Only use when the target body type matches this criteria.",
        render_header_text = function(self, cond)
            local header = "Target body type is ("
            local anyChecked = false
            if cond.args[1] then
                header = header .. "Undead or "
                anyChecked = true
            end
            if cond.args[2] then
                header = header .. "Summoned or "
                anyChecked = true
            end
            if anyChecked then
                header = header:sub(0, -5) -- remove the last " or "
            else
                header = header .. "None"
            end
            header = header .. ")"
            return header
        end,
        cond_targets = { "Auto Target", },
        args = {
            { name = "Undead",   type = "boolean", default = true, },
            { name = "Summoned", type = "boolean", default = true, },
        },
    },

    {
        name = "Target Is A... (ClassType)",
        cond = function(self, target, peerData, checkCaster, checkMelee, checkTank)
            return (checkCaster and Targeting.TargetIsACaster(target)) or
                (checkMelee and Targeting.TargetIsAMelee(target)) or
                (checkTank and Targeting.TargetIsATank(target))
        end,
        tooltip = "Only use when the target class type matches this criteria.",
        render_header_text = function(self, cond)
            local header = "Target class type is ("
            local anyChecked = false
            if cond.args[1] then
                header = header .. "Caster or "
                anyChecked = true
            end
            if cond.args[2] then
                header = header .. "Melee or "
                anyChecked = true
            end
            if cond.args[3] then
                header = header .. "Tank or "
                anyChecked = true
            end
            if anyChecked then
                header = header:sub(0, -5) -- remove the last " or "
            else
                header = header .. "None"
            end
            header = header .. ")"
            return header
        end,
        cond_targets = Module.NonCombatTargetTypeIDs,
        args = {
            { name = "Caster", type = "boolean", default = true, },
            { name = "Melee",  type = "boolean", default = true, },
            { name = "Tank",   type = "boolean", default = true, },
        },
    },

    {
        name = "Target Is Myself",
        cond = function(self, target, peerData, negate)
            if negate then
                return not Targeting.TargetIsMyself(target)
            else
                return Targeting.TargetIsMyself(target)
            end
        end,
        tooltip = "Only use when the target is (not) myself. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("Target is %s", cond.args[1] and "not Myself" or "Myself")
        end,
        cond_targets = Module.NonCombatTargetTypeIDs,
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "The RGMercs Auto Target Is Named",
        cond = function(self, target, peerData, negate)
            local isNamed = Globals.AutoTargetIsNamed
            if negate then
                return not isNamed
            else
                return isNamed
            end
        end,
        tooltip = "Only use when RGMercs has (not) identified the RGMercs combat auto target as Named (see Named tab). (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("Auto Target is %s", cond.args[1] and "not Named" or "Named")
        end,
        args = {
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "The RGMercs Auto Target Has Effect",
        cond = function(self, target, peerData, effect, negate)
            local hasEffect = Casting.TargetHasBuff(effect, target)

            return mq.TLO.Target.ID() == Globals.AutoTargetID and (negate and not hasEffect or hasEffect)
        end,
        tooltip = "Only use when this effect is (not) present on the RGMercs combat auto target. (Optional Negate)",
        render_header_text = function(self, cond)
            return string.format("RGMercs Auto Target %s Effect: '%s'", cond.args[2] and "doen't have" or "has", cond.args[1] or "None")
        end,
        args = {
            { name = "Effect", type = "string",  default = "", },
            { name = "Negate", type = "boolean", default = false, },
        },
    },

    {
        name = "The RGMercs Auto Target Has Any Beneficial Effect",
        cond = function(self, target, peerData)
            return mq.TLO.Target.ID() == Globals.AutoTargetID and mq.TLO.Target.Beneficial() ~= nil
        end,
        tooltip = "Only use when a beneficial effect is present on the RGMercs combat auto target. (Generally used for dispel clickies.)",
        render_header_text = function(self, cond)
            return string.format("RGMercs Auto Target has a beneficial effect.")
        end,
    },

    {
        name = "Item Count",
        cond = function(self, target, peerData, item, belowCount, aboveCount)
            local itemCount = mq.TLO.FindItemCount(string.format("=%s", item))()
            return itemCount <= aboveCount and itemCount >= belowCount
        end,
        tooltip = "Only use we have a certain quantity range of an item.",
        render_header_text = function(self, cond)
            return string.format("We have between %d and %d of %s", cond.args[2], cond.args[3], cond.args[1])
        end,
        args = {
            { name = "Item",     type = "string", default = "", },
            { name = ">= Count", type = "number", default = 0,    min = 0, max = 1000, },
            { name = "<= Count", type = "number", default = 1000, min = 0, max = 1000, },
        },
    },

    {
        name = "Config Setting",
        cond = function(self, target, peerData, setting, value)
            Logger.log_super_verbose("\ayClicky: \a-yChecking if GetSetting(%s) == %s", setting, tostring(value))

            return Config:HaveSetting(setting) and (Config:GetSetting(setting) == value) or false
        end,
        tooltip = "Only use if the specifed setting returns the specified value.",
        render_header_text = function(self, cond)
            return Config:HaveSetting(cond.args[1]) and string.format("The '%s' setting is %s", cond.args[1], tostring(cond.args[2])) or
                "Please set a valid setting name..."
        end,
        args = {
            {
                name = "Setting",
                type = "string",
                default = "",
                on_changed =
                    function(self, newValue, cond)
                        if Config:HaveSetting(newValue) then
                            local settingInfo = Config:GetSettingDefaults(newValue)
                            if settingInfo then
                                self:GetLogicBlockArgByTypeAndIndex(cond.type, 2).min = settingInfo.Min
                                self:GetLogicBlockArgByTypeAndIndex(cond.type, 2).max = settingInfo.Max
                                self:GetLogicBlockArgByTypeAndIndex(cond.type, 2).default = settingInfo.Default
                                cond.args[2] = settingInfo.Default
                            end
                        end
                    end,
            },
            { name = "Value", type = "setting_value", default = "", },
        },
    },

    {
        name = "Server Type",
        cond = function(self, target, peerData, onLive, onEmu, onLaz)
            Logger.log_super_verbose("\ayClicky: \a-yChecking Server Type is onLive(%s) onEmu(%s), onLaz(%s)", Strings.BoolToColorString(onLive),
                Strings.BoolToColorString(onEmu), Strings.BoolToColorString(onLaz))

            return (onLive and not Core.OnEMU()) or (onEmu and Core.OnEMU()) or (onLaz and Core.OnLaz())
        end,
        tooltip = "Only use if you are on one of these server types.",
        render_header_text = function(self, cond)
            local serverTypes = ""
            for k, v in pairs(cond.args) do
                if v == true then
                    serverTypes = serverTypes .. (serverTypes == "" and "" or " or ") .. self:GetLogicBlockArgByTypeAndIndex('Server Type', k).name
                end
            end

            return string.format("Server type is %s", serverTypes == "" and "None" or serverTypes)
        end,
        args = {
            { name = "Live",            type = "boolean", default = true, },
            { name = "Emu",             type = "boolean", default = true, },
            { name = "Project Lazarus", type = "boolean", default = true, },
        },
    },

    {
        name = "In Zone",
        cond = function(self, target, peerData, zoneName, bNotInZone)
            Logger.log_super_verbose("\ayClicky: \a-yChecking if we are in Zone(s): \at%s\aw CurZone: \at%s\aw/\at%s", zoneName, mq.TLO.Zone.Name() or "None",
                mq.TLO.Zone.ShortName() or "None")
            local zoneChecks = Strings.split(zoneName or "", ",")
            for i, v in ipairs(zoneChecks) do
                v = v:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
                if v == (mq.TLO.Zone.Name() or "") or v == (mq.TLO.Zone.ShortName() or "") then
                    return not bNotInZone
                end
            end

            return bNotInZone
        end,
        tooltip = "Only use if you are (not) in the following zones. (Full or short name accepted, comma separated).",

        render_header_text = function(self, cond)
            local zoneList = ""
            local zoneChecks = Strings.split(cond.args[1] or "", ",")
            for _, v in pairs(zoneChecks) do
                zoneList = zoneList .. (zoneList == "" and "" or " or ") .. v
            end
            return string.format("%sIn Zone(s) %s", cond.args[2] and "Not " or "", zoneList == "" and "None" or zoneList)
        end,
        args = {
            { name = "Zone Name",   type = "string",  default = "ggh", },
            { name = "Not In Zone", type = "boolean", default = false, },
        },
    },
}

Module.LogicBlockTypeIDs                   = {}

for id, block in ipairs(Module.LogicBlocks) do
    Module.LogicBlockTypeIDs[block.name] = id
    if block.cond_targets then
        for k, v in pairs(block.cond_targets) do
            block.cond_targetIDs = block.cond_targetIDs or {}
            block.cond_targetIDs[v] = k
        end
    end
end

Module.CombatTargetTypeIDs = {}
for k, v in pairs(Module.CombatTargetTypes) do
    Module.CombatTargetTypeIDs[v] = k
end
Module.NonCombatTargetTypeIDs = {}
for k, v in pairs(Module.NonCombatTargetTypes) do
    Module.NonCombatTargetTypeIDs[v] = k
end
Module.RotationTargetTypeIDs = {}
for k, v in pairs(Module.RotationTargetTypes) do
    Module.RotationTargetTypeIDs[v] = k
end
Module.MercPeerTargetTypeIDs = {}
for k, v in pairs(Module.MercPeerTargetTypes) do
    Module.MercPeerTargetTypeIDs[v] = k
end
Module.CombatStateIDs = {}
for k, v in pairs(Module.CombatStates) do
    Module.CombatStateIDs[v] = k
end

function Module:New()
    return Base.New(self)
end

function Module:RebuildRotationCache()
    local names = { "None", }
    for _, name in ipairs(Modules:ExecModule("Class", "GetRotationNames") or {}) do
        table.insert(names, name)
    end
    self.TempSettings.RotationNamesCache = names
    self.TempSettings.RotationNameSet    = Set.new(names)

    local healNames                      = { "None", }
    for _, name in ipairs(Modules:ExecModule("Class", "GetHealRotationNames") or {}) do
        table.insert(healNames, name)
    end
    self.TempSettings.HealRotationNamesCache = healNames
    self.TempSettings.HealRotationNameSet    = Set.new(healNames)
end

function Module:GetValidRotationNames()
    if not self.TempSettings.RotationNamesCache then
        self:RebuildRotationCache()
    end
    return self.TempSettings.RotationNamesCache
end

function Module:GetValidHealRotationNames()
    if not self.TempSettings.HealRotationNamesCache then
        self:RebuildRotationCache()
    end
    return self.TempSettings.HealRotationNamesCache
end

function Module:ValidateRotationName(rotationName, isHeal)
    if not rotationName or rotationName == "None" then return true end
    if isHeal then
        if not self.TempSettings.HealRotationNameSet then self:RebuildRotationCache() end
        return self.TempSettings.HealRotationNameSet:contains(rotationName)
    end
    if not self.TempSettings.RotationNameSet then self:RebuildRotationCache() end
    return self.TempSettings.RotationNameSet:contains(rotationName)
end

function Module:LoadSettings()
    Base.LoadSettings(self, nil, function(settings, firstSaveRequired)
        local settingsChanged = false

        -- insert default server clickies on very first run per PC
        if firstSaveRequired then
            -- Live/Test use "Live". Emu servers use server-specific.
            local serverType = Globals.BuildType:lower() ~= "emu" and "Live" or Globals.CurServer
            local defaultClickyList = self.DefaultServerClickies[serverType]
            Config:SetSetting('Clickies', defaultClickyList or {})
        end

        -- validate condition targets and rotation names.
        local tempClickies = Tables.DeepCopy(settings.Clickies or {})
        for _, clicky in ipairs(tempClickies) do
            for _, cond in ipairs(clicky.conditions or {}) do
                local blockDef = self.LogicBlocks[self.LogicBlockTypeIDs[cond.type]]
                if blockDef and blockDef.cond_targets then
                    local condTarget = cond.target or 'Self'
                    if not Tables.TableContains(blockDef.cond_targets, condTarget) then
                        cond.target = blockDef.cond_targets[1] or 'Self'
                        Logger.log_warn(
                            "\ayClicky Module: \ayClicky Condition Target '%s' is invalid for Condition Type '%s', resetting to default.",
                            cond.target, cond.type)
                        settingsChanged = true
                    end
                end
            end
            if clicky.no_target_change == nil then
                clicky.no_target_change = false
                settingsChanged = true
            end
            settingsChanged = self:ValidateClickyRotationSettings(clicky) or settingsChanged
        end

        if settingsChanged then
            Config:SetSetting('Clickies', tempClickies)
        end
    end)
end

function Module:RenderClickyControls(clickies, clickyIdx, headerCursorPos, headerScreenPos, preRender)
    local startingPosVec = ImGui.GetCursorPosVec()
    local offset_trash = 40
    local offset_enable = 160
    local yOffset = 0

    self:RenderClickyHeaderIcon(clickies[clickyIdx], headerScreenPos)

    ImGui.SetCursorPos(ImGui.GetWindowWidth() - offset_enable, headerCursorPos.y + yOffset)

    ImGui.PushID("##_small_btn_ctrl_clicky_" .. tostring(clickyIdx) .. (preRender and "_pre" or ""))

    if clickies[clickyIdx] then
        local changed = false
        local enabled = clickies[clickyIdx].enabled == nil or clickies[clickyIdx].enabled

        enabled, changed = Ui.RenderOptionToggle("##EnableDrawn" .. tostring(clickyIdx), "", enabled, true)
        if changed then
            clickies[clickyIdx].enabled = enabled
            Config:SetSetting('Clickies', clickies)
        end
    end

    if clickyIdx > 1 then
        ImGui.SameLine()
        ImGui.PushID("##_small_btn_up_clicky_" .. tostring(clickyIdx) .. (preRender and "_pre" or ""))
        if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then
            clickies[clickyIdx], clickies[clickyIdx - 1] = clickies[clickyIdx - 1], clickies[clickyIdx]
            Config:SetSetting('Clickies', clickies)
        end
        ImGui.PopID()
    else
        ImGui.SameLine()
        ImGui.InvisibleButton(Icons.FA_CHEVRON_UP, ImVec2(22, 1))
    end

    if clickyIdx < #clickies then
        ImGui.SameLine()
        ImGui.PushID("##_small_btn_dn_clicky_" .. tostring(clickyIdx) .. (preRender and "_pre" or ""))
        if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then
            clickies[clickyIdx], clickies[clickyIdx + 1] = clickies[clickyIdx + 1], clickies[clickyIdx]
            Config:SetSetting('Clickies', clickies)
        end
        ImGui.PopID()
    else
        ImGui.SameLine()
        ImGui.InvisibleButton(Icons.FA_CHEVRON_DOWN, ImVec2(22, 1))
    end

    if clickies[clickyIdx] then
        local rotationClickies = Modules:ExecModule("Class", "GetRotationClickies")
        local hasWarning = rotationClickies:contains(clickies[clickyIdx].itemName)
        if hasWarning then
            ImGui.SameLine()
            ImGui.TextColored(Globals.Constants.Colors.ConditionFailColor, Icons.MD_WARNING)
            if not preRender then
                Ui.MultilineTooltipWithColors({
                    { text = "! WARNING !",                                                                                color = Globals.Constants.Colors.ConditionFailColor, },
                    { text = "",                                                                                           color = Globals.Constants.Colors.ConditionFailColor, },
                    { text = "This clicky is in use in your current class config rotation. Check for possible conflicts!", color = Globals.Constants.Colors.FAQCmdQuestionColor, },
                })
            end
        elseif self.TempSettings.ClickyState[clickies[clickyIdx].itemName] and not self.TempSettings.ClickyState[clickies[clickyIdx].itemName].itemFound then
            ImGui.SameLine()
            ImGui.TextColored(Globals.Constants.Colors.ConditionFailColor, Icons.MD_WARNING)
            if not preRender then
                Ui.MultilineTooltipWithColors({
                    { text = "! WARNING !",                                      color = Globals.Constants.Colors.ConditionFailColor, },
                    { text = "",                                                 color = Globals.Constants.Colors.ConditionFailColor, },
                    { text = "This clicky item is no longer in your inventory!", color = Globals.Constants.Colors.FAQCmdQuestionColor, },
                })
            end
        end
    end

    ImGui.SetCursorPos(ImGui.GetWindowWidth() - offset_trash, headerCursorPos.y + yOffset)

    if ImGui.SmallButton(Icons.FA_TRASH) then
        -- if we do this in the UI thread then there could be a race condition if the user is clicking fast
        clickies[clickyIdx].Delete = true
    end
    ImGui.PopID()

    ImGui.SetCursorPos(startingPosVec)
end

function Module:RenderConditionControls(clickyIdx, idx, conditionsTable)
    local startingPosVec = ImGui.GetCursorPosVec()
    local offset = 110

    ImGui.SetCursorPos(ImGui.GetWindowWidth() - offset, startingPosVec.y + 2)

    ImGui.PushID("##_small_btn_up_wp_" .. tostring(clickyIdx) .. "_" .. tostring(idx))
    if idx == 1 then
        ImGui.InvisibleButton(Icons.FA_CHEVRON_UP, ImVec2(22, 1))
    else
        if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then
            conditionsTable[idx], conditionsTable[idx - 1] = conditionsTable[idx - 1], conditionsTable[idx]
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end
    end
    ImGui.PopID()
    ImGui.SameLine()
    ImGui.PushID("##_small_btn_dn_cond_" .. tostring(clickyIdx) .. "_" .. tostring(idx))
    if idx == #conditionsTable then
        ImGui.InvisibleButton(Icons.FA_CHEVRON_DOWN, ImVec2(22, 1))
    else
        if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then
            conditionsTable[idx], conditionsTable[idx + 1] = conditionsTable[idx + 1], conditionsTable[idx]
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end
    end
    ImGui.PopID()
    ImGui.SameLine()
    ImGui.PushID("##_small_btn_delete_cond_" .. tostring(clickyIdx) .. "_" .. tostring(idx))
    if ImGui.SmallButton(Icons.FA_TRASH) then
        conditionsTable[idx].Delete = true
    end
    ImGui.PopID()


    ImGui.SetCursorPos(startingPosVec)
end

function Module:RenderConditionTypesCombo(cond, condIdx)
    if ImGui.BeginTable("##clicky_cond_type_table_" .. condIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 50)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
        ImGui.TableNextColumn()
        Ui.RenderText("Type")
        ImGui.TableNextColumn()
        local selectedNum, changed = ImGui.Combo("##clicky_cond_type_" .. "_" .. condIdx, self.LogicBlockTypeIDs[cond.type or "None"] or 1,
            function(idx)
                return self.LogicBlocks[idx].name or "None"
            end,
            #self.LogicBlocks)

        if changed then
            cond.type = self.LogicBlocks[selectedNum].name or "None"
            cond.args = {}
            cond.target = self.LogicBlocks[selectedNum].cond_targets and self.LogicBlocks[selectedNum].cond_targets[1] or "Self"
            for argIdx, arg in ipairs(self:GetLogicBlockArgsByType(cond.type) or {}) do
                cond.args[argIdx] = arg.default
            end
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end
        ImGui.EndTable()
    end
end

function Module:RenderConditionTargetCombo(cond, condIdx, combatState)
    local condBlock = self:GetLogicBlockByType(cond.type)
    if not condBlock or not condBlock.cond_targets then
        return
    end
    if ImGui.BeginTable("##clicky_cond_target_table_" .. condIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 50)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
        ImGui.TableNextColumn()
        Ui.RenderText("Target")
        ImGui.TableNextColumn()
        if combatState == "During Rotation" or combatState == "During Heal Rotation" then
            ImGui.TextDisabled("Rotation Target")
            if cond.target ~= "Rotation Target" then
                cond.target = "Rotation Target"
                Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
            end
        else
            local selectedNum, changed = ImGui.Combo("##clicky_cond_target_" .. "_" .. condIdx, tonumber(condBlock.cond_targetIDs[cond.target or "Self"]) or 1,
                condBlock.cond_targets,
                #condBlock.cond_targets)
            if changed then
                cond.target = condBlock.cond_targets[selectedNum] or "Self"
                Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
            end
        end
        ImGui.EndTable()
        Ui.Tooltip("Target Types\nSelf - This PC\nPet - This PC's pet\nMain Assist - The current RGMercs Main Assist\nAuto Target - The current RGMercs Combat Auto Target")
    end
end

function Module:RenderClickyTargetCombo(clicky, clickyIdx)
    if ImGui.BeginTable("##clicky_target_table_" .. clickyIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 140)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
        ImGui.TableNextColumn()
        Ui.RenderText("Target")
        ImGui.TableNextColumn()

        if clicky.combat_state == "During Rotation" or clicky.combat_state == "During Heal Rotation" then
            ImGui.TextDisabled("Rotation Target")
            if clicky.target ~= "Rotation Target" then
                clicky.target = "Rotation Target"
                Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
            end
        else
            local targetTypeIDs, targetTypes, defaultTarget
            if clicky.combat_state == "Downtime" then
                targetTypeIDs = self.NonCombatTargetTypeIDs
                targetTypes   = self.NonCombatTargetTypes
                defaultTarget = "Self"
            else
                targetTypeIDs = self.CombatTargetTypeIDs
                targetTypes   = self.CombatTargetTypes
                defaultTarget = "Self"
            end

            local selectedNum, changed = ImGui.Combo("##clicky_cond_target_" .. "_" .. clickyIdx, tonumber(targetTypeIDs[clicky.target or defaultTarget]) or 1,
                targetTypes, #targetTypes)
            if changed then
                clicky.target = targetTypes[selectedNum] or defaultTarget
                Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
            end
        end
        ImGui.EndTable()
        Ui.Tooltip(
            "Target Types\nSelf - This PC\nPet - This PC's pet\nMain Assist - The current RGMercs Main Assist\nAuto Target - The current RGMercs Combat Auto Target\nMercs Peer - A character running RGMercs on the same network\nRotation Target - The target passed in by the active rotation")
    end

    if clicky.target == "Mercs Peer" then
        if ImGui.BeginTable("##clicky_mercs_peer_name_table_" .. clickyIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
            ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 140)
            ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
            ImGui.TableNextColumn()
            Ui.RenderText("Mercs Peer Name")
            ImGui.TableNextColumn()
            local newName, changed = ImGui.InputText("##clicky_mercs_peer_name_" .. clickyIdx, clicky.mercs_peer_name or "")
            if changed then
                clicky.mercs_peer_name = newName
                Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
            end
            ImGui.EndTable()
        end
    end
end

function Module:RenderClickyNoTargetChangeToggle(clicky, clickyIdx)
    local isRotation = clicky.combat_state == "During Rotation" or clicky.combat_state == "During Heal Rotation"
    if ImGui.BeginTable("##clicky_target_no_change_table_" .. clickyIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 140)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
        ImGui.TableNextColumn()
        Ui.RenderText("Don't Change Target")
        ImGui.TableNextColumn()
        ImGui.BeginDisabled(isRotation)
        local new_no_target_change, clicked = Ui.RenderOptionToggle("##clicky_no_target_change_" .. clickyIdx, "",
            clicky.no_target_change)
        ImGui.EndDisabled()

        if isRotation and clicky.no_target_change then
            clicky.no_target_change = false
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end

        if not isRotation and clicked then
            clicky.no_target_change = new_no_target_change
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end
        Ui.Tooltip("If enabled, we will not change targets to use this clicky.")
        ImGui.EndTable()
    end
end

function Module:RenderClickyCombatStateCombo(clicky, clickyIdx)
    if ImGui.BeginTable("##clicky_combat_state_table_" .. clickyIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 140)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
        ImGui.TableNextColumn()
        Ui.RenderText("Combat State")
        ImGui.TableNextColumn()
        local selectedNum, changed = ImGui.Combo("##clicky_cond_combat_state_" .. "_" .. clickyIdx, tonumber(self.CombatStateIDs[clicky.combat_state or "Any"]) or 1,
            self.CombatStates,
            #self.CombatStates)
        if changed then
            clicky.combat_state = self.CombatStates[selectedNum] or "Any"
            if clicky.combat_state == "During Rotation" or clicky.combat_state == "During Heal Rotation" then
                clicky.rotation_name = "None"
                clicky.target        = "Rotation Target"
            else
                clicky.rotation_name = nil
                clicky.target        = "Self"
            end
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end
        ImGui.EndTable()
    end

    if clicky.combat_state == "During Rotation" or clicky.combat_state == "During Heal Rotation" then
        self:RenderClickyRotationCombo(clicky, clickyIdx)
    end
end

function Module:RenderClickyRotationCombo(clicky, clickyIdx)
    local rotationNames = clicky.combat_state == "During Heal Rotation" and self:GetValidHealRotationNames() or self:GetValidRotationNames()
    local currentName   = clicky.rotation_name or "None"
    local cachedIdx     = self.TempSettings.RotationComboIdx[clickyIdx]

    if cachedIdx == nil or rotationNames[cachedIdx] ~= currentName then
        cachedIdx = 1
        for i, name in ipairs(rotationNames) do
            if name == currentName then
                cachedIdx = i; break
            end
        end
        self.TempSettings.RotationComboIdx[clickyIdx] = cachedIdx
    end

    if ImGui.BeginTable("##clicky_rotation_table_" .. clickyIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 140)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)
        ImGui.TableNextColumn()
        Ui.RenderText("Rotation")
        ImGui.TableNextColumn()
        local selectedIdx, changed = Ui.SearchableCombo("clicky_rotation_" .. clickyIdx, cachedIdx, rotationNames)
        if changed then
            clicky.rotation_name = rotationNames[selectedIdx] or "None"
            self.TempSettings.RotationComboIdx[clickyIdx] = selectedIdx
            Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
        end
        ImGui.EndTable()
    end
end

function Module:RenderClickyOption(type, cond, condIdx, argIdx, clickyIdx)
    local changed = false

    if type == "number" then
        cond.args[argIdx], changed = Ui.RenderOptionNumber("##clicky_arg_" .. clickyIdx .. "_" .. condIdx .. "_" .. argIdx,
            "", cond.args[argIdx], self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).min, self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).max)
    elseif type == "boolean" then
        cond.args[argIdx], changed = Ui.RenderOptionToggle("##clicky_arg_" .. clickyIdx .. "_" .. condIdx .. "_" .. argIdx,
            "",
            cond.args[argIdx])
    elseif type == "string" then
        cond.args[argIdx], changed = ImGui.InputText("##clicky_arg_" .. clickyIdx .. "_" .. condIdx .. "_" .. argIdx,
            cond.args[argIdx])
    else
        ImGui.TextDisabled("Invalid Option Type: %s", type)
    end

    if changed then
        if self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).on_changed then
            Core.SafeCallFunc("On Changed Callback", self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).on_changed, self, cond.args[argIdx], cond)
        end

        Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
    end
end

function Module:RenderConditionArgs(cond, condIdx, clickyIdx)
    if ImGui.BeginTable("##clicky_cond_args_table_" .. condIdx, 2, bit32.bor(ImGuiTableFlags.None)) then
        ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 80)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch, 0)

        for argIdx = 1, #cond.args do
            ImGui.TableNextColumn()
            Ui.RenderText(self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).name or ("Arg " .. tostring(argIdx)))
            ImGui.TableNextColumn()

            if self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).type == "setting_value" then
                -- the arg before this must be a valid setting for this to work.
                if argIdx == 1 or not Config:HaveSetting(cond.args[argIdx - 1]) then
                    ImGui.TextDisabled("Please select a valid setting in the previous argument.")
                else
                    local settingName = cond.args[argIdx - 1] or ""
                    local settingInfo = Config:GetSettingDefaults(settingName)

                    if settingInfo then
                        self:RenderClickyOption(type(settingInfo.Default), cond, condIdx, argIdx, clickyIdx)
                    else
                        ImGui.TextDisabled("Unable to retrieve setting info for '%s'.", settingName)
                    end
                end
            else
                self:RenderClickyOption(self:GetLogicBlockArgByTypeAndIndex(cond.type, argIdx).type, cond, condIdx, argIdx, clickyIdx)
            end
        end
        ImGui.EndTable()
    end
end

function Module:GetLogicBlockByType(type)
    return self.LogicBlocks[self.LogicBlockTypeIDs[type]]
end

function Module:GetLogicBlockTargetsByType(type)
    return self:GetLogicBlockByType(type).cond_targets or {}
end

function Module:GetLogicBlockArgsByType(type)
    return self:GetLogicBlockByType(type).args or {}
end

--- comment
--- @param type string
--- @param idx number
--- @return any
function Module:GetLogicBlockArgByTypeAndIndex(type, idx)
    return self:GetLogicBlockByType(type).args[idx] or "None"
end

function Module:GetLogicBlockArgCountByType(type)
    return #self:GetLogicBlockByType(type).args or 0
end

function Module:RenderClickyHeaderIcon(clicky, headerPos)
    local offset = 30

    if not clicky then return end

    if clicky.iconId == nil then
        local item = mq.TLO.FindItem(clicky.itemName)
        clicky.iconId = item() and tonumber((item.Icon() or 500) - 500) or 0
        Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
    end

    local draw_list = ImGui.GetWindowDrawList()
    animItems:SetTextureCell(tonumber(clicky.iconId) or 0)
    draw_list:AddTextureAnimation(animItems, ImVec2(headerPos.x + offset, headerPos.y), ImVec2(20, 20))
end

function Module:RenderCondition(clickyIdx, condIdx, cond, conditionsTable, combatState)
    if condIdx == 0 then
        ImGui.SetNextItemOpen(false, ImGuiCond.Always);
        ImGui.TreeNodeEx(cond.render_header_text(self, cond) .. "###clicky_cond_tree_" .. clickyIdx .. "_" .. condIdx, ImGuiTreeNodeFlags.NoTreePushOnOpen)
    else
        local nodeOpen = ImGui.TreeNode(self:GetLogicBlockByType(cond.type).render_header_text(self, cond) .. "###clicky_cond_tree_" .. clickyIdx .. "_" .. condIdx)

        if conditionsTable then
            local payloadType = "CLICKY_COND_REORDER_" .. clickyIdx
            if ImGui.BeginDragDropSource() then
                ImGui.SetDragDropPayload(payloadType, condIdx)
                ImGui.Text(self:GetLogicBlockByType(cond.type).render_header_text(self, cond))
                ImGui.EndDragDropSource()
            end
            if ImGui.BeginDragDropTarget() then
                local payload = ImGui.AcceptDragDropPayload(payloadType)
                if payload then
                    local src = payload.Data
                    local dst = condIdx
                    local item = table.remove(conditionsTable, src)
                    table.insert(conditionsTable, dst, item)
                    Config:SetSetting('Clickies', Config:GetSetting('Clickies'))
                end
                ImGui.EndDragDropTarget()
            end
        end

        if nodeOpen then
            ImGui.PopStyleColor(1)
            Ui.Tooltip(self:GetLogicBlockByType(cond.type).tooltip or "No Tooltip Available.")

            self:RenderConditionTypesCombo(cond, condIdx)

            ImGui.Indent()
            ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 5.0)
            ImGui.BeginChild("##clicky_cond_child_" .. clickyIdx .. "_" .. condIdx, ImVec2(0, 0),
                bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.Borders, ImGuiChildFlags.AutoResizeY),
                bit32.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoTitleBar))
            self:RenderConditionTargetCombo(cond, condIdx, combatState)
            self:RenderConditionArgs(cond, condIdx, clickyIdx)
            ImGui.EndChild()
            ImGui.PopStyleVar(1)
            ImGui.Unindent()
            ImGui.TreePop()
        else
            ImGui.PopStyleColor(1)
            Ui.Tooltip(self:GetLogicBlockByType(cond.type).tooltip or "No Tooltip Available.")
        end
    end
end

function Module:RenderClickiesWithConditions(type, clickies)
    ImGui.BeginDisabled(not mq.TLO.Cursor())

    local filterApplied = #clickies ~= #Config:GetSetting('Clickies')

    if ImGui.SmallButton(mq.TLO.Cursor.Name() and string.format("%s Add %s to %s", Icons.FA_PLUS, mq.TLO.Cursor.Name() or "N/A", type) or "Pickup an Item To Add") then
        if mq.TLO.Cursor() then
            local spell = mq.TLO.Cursor.Clicky.Spell
            local targetType = spell and spell() and spell.TargetType() or "Unknown"
            table.insert(clickies, {
                itemName = mq.TLO.Cursor.Name(),
                target = 'Self',
                iconId = tonumber((mq.TLO.Cursor.Icon() or 500) - 500) or 0,
                combat_state = 'Any',
                no_target_change = targetType == "Self" or targetType == "Group v1" or targetType == "AE v1",
                conditions = {},
            })
            Config:SetSetting('Clickies', clickies)
        end
    end

    ImGui.EndDisabled()

    ImGui.SameLine()
    if ImGui.SmallButton("Add Server Defaults") then
        self:InsertDefaultClickies()
    end
    Ui.Tooltip("Add server-specific default clickies to the end of the list.")

    ImGui.SameLine()
    Ui.RenderText(Icons.MD_INFO_OUTLINE .. " Special Note on Clickies " .. Icons.MD_INFO_OUTLINE)
    Ui.Tooltip(
        "All clickies have inherent presence and stacking checks built in; that is to say, we will only use a clicky if we detect that the effect is absent (and would stack) on its intended target.\n\nAdding conditions to check for the clicky's effect is generally not required or performant, be it buff, debuff or otherwise.")

    ImGui.Separator()
    if #clickies > 0 then
        for clickyIdx, clicky in ipairs(clickies) do
            if clicky.itemName:len() > 0 and clickies[clickyIdx].Delete ~= true then
                local headerScreenPos = ImGui.GetCursorScreenPosVec()
                local headerCursorPos = ImGui.GetCursorPosVec()

                ImGui.BeginDisabled(filterApplied)
                self:RenderClickyControls(clickies, clickyIdx, headerCursorPos, headerScreenPos, true)
                ImGui.EndDisabled()

                ImGui.PushID("##clicky_header_" .. clickyIdx)

                -- if a drop landed on this header this frame, pin the open state to what it
                -- was last frame so the mouse-release that completed the drop doesn't toggle it
                if self.TempSettings.ClickyDropFrame[clickyIdx] == ImGui.GetFrameCount() then
                    ImGui.SetNextItemOpen(self.TempSettings.ClickyHeaderOpen[clickyIdx] or false, ImGuiCond.Always)
                end

                local headerOpen = ImGui.CollapsingHeader("             " .. clicky.itemName)
                self.TempSettings.ClickyHeaderOpen[clickyIdx] = headerOpen

                if not filterApplied then
                    if ImGui.BeginDragDropSource() then
                        ImGui.SetDragDropPayload("CLICKY_REORDER", clickyIdx)
                        ImGui.Text(clicky.itemName)
                        ImGui.EndDragDropSource()
                    end
                    if ImGui.BeginDragDropTarget() then
                        local payload = ImGui.AcceptDragDropPayload("CLICKY_REORDER")
                        if payload then
                            local src = payload.Data
                            local dst = clickyIdx
                            self.TempSettings.ClickyDropFrame[dst] = ImGui.GetFrameCount()
                            local item = table.remove(clickies, src)
                            table.insert(clickies, dst, item)
                            Config:SetSetting('Clickies', clickies)
                        end
                        ImGui.EndDragDropTarget()
                    end
                end

                if headerOpen then
                    ImGui.BeginDisabled(clicky.enabled == false)

                    ImGui.Indent()

                    self:RenderClickyCombatStateCombo(clicky, clickyIdx)
                    self:RenderClickyTargetCombo(clicky, clickyIdx)
                    self:RenderClickyNoTargetChangeToggle(clicky, clickyIdx)

                    ImGui.SeparatorText("Usage Info")
                    self:RenderClickyData(clicky, clickyIdx)
                    ImGui.SeparatorText("Conditions");
                    ImGui.PushID("##clicky_conditions_btn_" .. clickyIdx)
                    if ImGui.SmallButton(Icons.FA_PLUS .. " Add Condition") then
                        table.insert(clicky.conditions, { type = 'None', args = {}, target = 'Self', })
                        Config:SetSetting('Clickies', clickies)
                    end
                    Config:GetSetting('Clickies')
                    ImGui.PopID()
                    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 5.0)

                    ImGui.BeginChild("##clicky_conditions_child_" .. clickyIdx, ImVec2(0, 0),
                        bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.Borders, ImGuiChildFlags.AutoResizeY),
                        bit32.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoTitleBar))

                    self:RenderCondition(clickyIdx, 0, self.ImpliedCondition, nil, clicky.combat_state)

                    for condIdx, cond in ipairs(clicky.conditions or {}) do
                        if self:GetLogicBlockByType(cond.type) and cond.Delete ~= true then
                            -- only render configs if we are not filtered
                            ImGui.BeginDisabled(filterApplied)
                            self:RenderConditionControls(clickyIdx, condIdx, clicky.conditions)
                            ImGui.EndDisabled()

                            if self.TempSettings.ConditionsCache[clickyIdx] and self.TempSettings.ConditionsCache[clickyIdx][condIdx] == true then
                                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                            elseif self.TempSettings.ConditionsCache[clickyIdx] and self.TempSettings.ConditionsCache[clickyIdx][condIdx] == false then
                                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                            else
                                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionMidColor)
                            end
                            self:RenderCondition(clickyIdx, condIdx, cond, not filterApplied and clicky.conditions or nil, clicky.combat_state)
                        end
                    end

                    ImGui.EndChild()

                    ImGui.PopStyleVar(1)

                    ImGui.EndDisabled()

                    ImGui.Unindent()
                end

                ImGui.BeginDisabled(filterApplied)
                self:RenderClickyControls(clickies, clickyIdx, headerCursorPos, headerScreenPos, false)
                ImGui.EndDisabled()

                ImGui.PopID()
            end
        end
    end
end

function Module:SetUsed(clickyName)
    if self.TempSettings.ClickyState[clickyName] then
        self.TempSettings.ClickyState[clickyName].lastUsed = Globals.GetTimeSeconds()
    end
end

function Module:RenderClickyData(clicky, clickyIdx)
    if ImGui.BeginTable("##clickies_table_" .. clicky.itemName .. tostring(clickyIdx), 3, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Last Used', (ImGuiTableColumnFlags.WidthFixed), 100.0)
        ImGui.TableSetupColumn('Item', (ImGuiTableColumnFlags.WidthFixed), 150.0)
        ImGui.TableSetupColumn('Effect', (ImGuiTableColumnFlags.WidthStretch), 200.0)
        ImGui.TableHeadersRow()

        if clicky.itemName:len() > 0 then
            local clickyState = self.TempSettings.ClickyState[clicky.itemName] or {}
            local spellName = clickyState.spellName or "Unknown Effect"
            local lastUsed = clickyState.lastUsed or 0

            ImGui.TableNextColumn()
            Ui.RenderText(lastUsed > 0 and Strings.FormatTime((Globals.GetTimeSeconds() - lastUsed)) or "Never")
            ImGui.TableNextColumn()
            Ui.RenderText(clicky.itemName)
            ImGui.TableNextColumn()
            ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.LightOrange)
            ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Globals.Constants.Colors.NearBlack)
            local _, clicked = ImGui.Selectable(spellName)
            if clicked then
                local item = mq.TLO.FindItem(clicky.itemName)
                local itemSpell = item and item.Clicky and item.Clicky.Spell
                if itemSpell and itemSpell() then itemSpell.Inspect() end
            end
            ImGui.PopStyleColor(2)
            Ui.Tooltip(string.format("Clicky Spell: %s (click to inspect)", spellName))
        end

        ImGui.EndTable()
    end
    ImGui.Separator()
end

function Module:GetMatchingClickies(searchFilter)
    local clickies = Config:GetSetting('Clickies')

    if not searchFilter or searchFilter:len() == 0 then
        return clickies or {}
    end

    local matchingClickies = {}
    local searchLower = searchFilter:lower()
    for _, clicky in ipairs(clickies or {}) do
        if clicky.itemName:lower():find(searchLower) then
            table.insert(matchingClickies, clicky)
        elseif clicky.combat_state:lower():find(searchLower) then
            table.insert(matchingClickies, clicky)
        elseif clicky.target:lower():find(searchLower) then
            table.insert(matchingClickies, clicky)
        else
            for _, cond in ipairs(clicky.conditions or {}) do
                if cond.type:lower():find(searchLower) then
                    table.insert(matchingClickies, clicky)
                    break
                end
                if cond.target and cond.target:lower():find(searchLower) then
                    table.insert(matchingClickies, clicky)
                    break
                end
                for _, arg in ipairs(cond.args or {}) do
                    if tostring(arg):lower():find(searchLower) then
                        table.insert(matchingClickies, clicky)
                        break
                    end
                end
            end
        end
    end

    return matchingClickies
end

function Module:HaveSearchMatches(searchFilter)
    local matchingClickies = self:GetMatchingClickies(searchFilter)
    return #matchingClickies > 0
end

function Module:RenderConfig(searchFilter)
    local clickiesToRender = self:GetMatchingClickies(searchFilter)
    self:RenderClickiesWithConditions("Clickies", clickiesToRender)
end

function Module:Render()
    Base.Render(self)

    self:RenderClickiesWithConditions("Clickies", Config:GetSetting('Clickies'))
end

function Module:ValidateClickies()
    local clickies = Config:GetSetting('Clickies') or {}
    local clickiesChanged = false
    for idx = #clickies, 1, -1 do
        local clicky = clickies[idx]

        for cond_idx = #clicky.conditions, 1, -1 do
            local condition = clicky.conditions[cond_idx]
            if condition.Delete then
                table.remove(clicky.conditions, cond_idx)
                clickiesChanged = true
            end
        end

        if clicky.itemName:len() == 0 or clicky.Delete then
            table.remove(clickies, idx)
            clickiesChanged = true
        end
    end

    if clickiesChanged then
        -- update the actual settings since we just mutated the temp reference above.
        Config:SetSetting('Clickies', clickies)
    end
end

function Module:InsertDefaultClickies()
    -- Live/Test use "Live". Emu servers use server-specific.
    local serverType = Globals.BuildType:lower() ~= "emu" and "Live" or Globals.CurServer
    local defaultClickyList = self.DefaultServerClickies[serverType]
    local clickes = Config:GetSetting('Clickies') or {}

    if defaultClickyList then
        for _, defaultClicky in ipairs(defaultClickyList) do
            table.insert(clickes, defaultClicky)
        end
        Config:SetSetting('Clickies', clickes)
    end
end

function Module:GiveTime()
    local combat_state = Combat.GetCachedCombatState()

    if combat_state == "Downtime" and mq.TLO.Me.Invis() then
        Logger.log_super_verbose("\ayClicky: \aw\t|->\aw \arSkipping, Invis during downtime!")
        return
    end

    if Casting.IAmFeigning() then
        Logger.log_super_verbose("\ayClicky: \aw\t|->\aw \arSkipping, currently feigned!")
        return
    end

    -- Main Module logic goes here.
    self:ValidateClickies()

    local maxClickiesPerFrame = Config:GetSetting('MaxClickiesPerFrame') or 0
    local clickiesUsedThisFrame = 0
    local startingClickyIdx = maxClickiesPerFrame > 0 and self.ClickyRotationIndex or 1
    local clickies = Config:GetSetting('Clickies') or {}
    local numClickies = #clickies
    local moving = mq.TLO.Me.Moving() or mq.TLO.Navigation.Active() or mq.TLO.MoveTo.Moving()
    for clickyIdx = startingClickyIdx, numClickies do
        if Globals.PauseMain or Globals.StopCast then
            break
        end
        local clicky = clickies[clickyIdx]
        if clicky.itemName:len() > 0 and (clicky.enabled == nil or clicky.enabled == true) then
            self.ClickyRotationIndex = (clickyIdx % numClickies) + 1
            Logger.log_super_verbose("\ayClicky: \awChecking clicky entry: \ay%s\aw[\at%d\aw]", clicky.itemName, clickyIdx)

            local item = mq.TLO.FindItem(clicky.itemName)
            local itemSpell = item and item.Clicky and item.Clicky.Spell
            self.TempSettings.ClickyState[clicky.itemName] = self.TempSettings.ClickyState[clicky.itemName] or {}
            self.TempSettings.ClickyState[clicky.itemName].spellName = itemSpell and itemSpell.Name() or (item and "No Clicky Spell or Missing Item" or "Item Not Found")
            self.TempSettings.ClickyState[clicky.itemName].itemFound = item() ~= nil

            Logger.log_verbose("\ayClicky: \awLooking for clicky item: \am%s \awfound: %s", clicky.itemName, Strings.BoolToColorString(item() ~= nil))
            if item and item.Clicky then
                if not moving or (item.Clicky.CastTime() or -1) == 0 then
                    if clicky.combat_state == "Any" or clicky.combat_state == combat_state then
                        local condTarget = nil
                        local condPeer = nil
                        local allConditionsMet = true
                        -- store this by index incase the same name appears twice.
                        self.TempSettings.ConditionsCache[clickyIdx] = {}
                        for _, cond in ipairs(clicky.conditions or {}) do
                            local condBlock = self:GetLogicBlockByType(cond.type)
                            if condBlock then
                                if condBlock.cond_targets then
                                    if cond.target == "Self" then
                                        condTarget = mq.TLO.Me
                                    elseif cond.target == "Main Assist" then
                                        condTarget = Core.GetMainAssistSpawn()
                                    elseif cond.target == "Pet" then
                                        condTarget = mq.TLO.Me.Pet
                                    elseif cond.target == "Auto Target" then
                                        condTarget = Targeting.GetAutoTarget()
                                    elseif cond.target == "Mercs Peer" then
                                        condTarget = nil
                                        condPeer = Comms.GetPeerHeartbeatByName(clicky.mercs_peer_name or "")
                                    end
                                end
                                Logger.log_super_verbose("\ayClicky: \awTesting Condition: \at%s\aw on target: \at%s (%s)", cond.type,
                                    condTarget and (condTarget.CleanName() or "None") or "None",
                                    cond.target or "Self")

                                ---@diagnostic disable-next-line: deprecated --LuaJIT is based off of 5.1
                                if not Core.SafeCallFunc("Test clicky Condition", self:GetLogicBlockByType(cond.type).cond, self, condTarget, condPeer and condPeer.Data, unpack(cond.args or {})) then
                                    Logger.log_super_verbose("\ayClicky: \aw\t|->\aw \arFailed!")
                                    allConditionsMet = false
                                    table.insert(self.TempSettings.ConditionsCache[clickyIdx], false)
                                    break
                                else
                                    Logger.log_super_verbose("\ayClicky: \aw\t|->\aw \agSuccess!")
                                    table.insert(self.TempSettings.ConditionsCache[clickyIdx], true)
                                end
                            end
                        end

                        if allConditionsMet then
                            local target = nil
                            local buffCheckPassed = true
                            local targetId = nil
                            local targetPeer = nil

                            if clicky.target == "Self" then
                                target = mq.TLO.Me
                                buffCheckPassed = Casting.SelfBuffItemCheck(clicky.itemName)
                            elseif clicky.target == "Pet" then
                                target = mq.TLO.Me.Pet
                                buffCheckPassed = target and Casting.PetBuffItemCheck(clicky.itemName)
                            elseif clicky.target == "Main Assist" then
                                target = Core.GetMainAssistSpawn()
                                buffCheckPassed = target and Casting.GroupBuffItemCheck(clicky.itemName, target)
                            elseif clicky.target == "Auto Target" then
                                target = Targeting.GetAutoTarget()
                                buffCheckPassed = target and Casting.DetItemCheck(clicky.itemName, target)
                            elseif clicky.target == "Mercs Peer" then
                                targetPeer = Comms.GetPeerHeartbeatByName(clicky.mercs_peer_name or "")
                                Logger.log_verbose("\ayClicky: \awChecking Mercs Peer Target: \am%s\aw found: %s", clicky.mercs_peer_name or "",
                                    Strings.BoolToColorString(targetPeer and targetPeer.Data and targetPeer.Data.ID ~= nil))
                                if targetPeer and targetPeer.Data and targetPeer.Data.ID ~= nil then
                                    target = mq.TLO.Spawn(targetPeer.Data.ID)
                                    buffCheckPassed = target and Casting.ActorBuffCheck(item.Clicky.Spell.RankName.ID(), target)
                                end
                            end

                            if not clicky.no_target_change then
                                targetId = target and target.ID()
                            end

                            -- distance check
                            local distanceCheckPassed = true
                            if targetId and targetId ~= mq.TLO.Me.ID() then
                                local spellRange = itemSpell.MyRange() > 0 and itemSpell.MyRange() or (itemSpell.AERange() > 0 and itemSpell.AERange() or 200)
                                if Targeting.GetTargetDistance(target) > spellRange then
                                    Logger.log_debug("\ayClicky: \arTried to use item on targetId %s they are too far away!!", target and target.DisplayName() or "None")
                                    distanceCheckPassed = false
                                end
                            end

                            local readyCheckPassed = Casting.ItemReady(item())

                            if buffCheckPassed and distanceCheckPassed and readyCheckPassed then
                                Logger.log_verbose("\ayClicky: \awItem \am%s\aw Clicky Spell: \at%s\ag!", item.Name(), item.Clicky.Spell.RankName.Name())
                                Casting.UseItem(item.Name(), targetId)
                                clickiesUsedThisFrame = clickiesUsedThisFrame + 1
                                if maxClickiesPerFrame > 0 and clickiesUsedThisFrame >= maxClickiesPerFrame then
                                    Logger.log_debug("\ayClicky: \a-tMax Clickies Per Frame of \am%d\a-t reached, stopping for this frame and picking up with %d next frame.",
                                        maxClickiesPerFrame, self.ClickyRotationIndex)
                                    break
                                end
                                self.TempSettings.ClickyState[clicky.itemName].lastUsed = Globals.GetTimeSeconds()
                                break --ensure we stop after we process a single clicky to allow rotations to continue
                            else
                                Logger.log_verbose("\ayClicky: \awItem \am%s\aw Clicky: \at%s\ar checks failed, not using!\aw BuffCheck(%s), DistanceCheck(%s), ItemReady(%s)",
                                    item.Name(), item.Clicky.Spell.RankName.Name(), Strings.BoolToColorString(buffCheckPassed), Strings.BoolToColorString(distanceCheckPassed),
                                    Strings.BoolToColorString(readyCheckPassed))
                            end
                        end
                    else
                        Logger.log_super_verbose("\ayClicky: \arSkipping clicky entry: \am%s\ar due to Combat State mismatch (Clicky State: \at%s \arCurrent State: \at%s\ar)",
                            clicky.itemName, clicky.combat_state, combat_state)
                    end
                else
                    Logger.log_super_verbose("\ayClicky: \arSkipping clicky entry: \am%s\ar due to movement.", clicky.itemName)
                end
            end
        end
    end
end

function Module:GetClickiesForRotation(rotationName)
    local result   = {}
    local clickies = Config:GetSetting('Clickies') or {}

    for _, clicky in ipairs(clickies) do
        if clicky.combat_state == "During Rotation"
            and clicky.rotation_name == rotationName
            and clicky.itemName:len() > 0
            and (clicky.enabled == nil or clicky.enabled == true)
        then
            local itemName   = clicky.itemName
            local conditions = clicky.conditions or {}

            table.insert(result, {
                name = itemName,
                type = "Item",
                from_clicky = true,
                cond = function(caller, itemName, targetSpawn)
                    if not Casting.ItemReady(itemName) then return false end
                    local buffCheckPassed = true

                    if targetSpawn.ID() == mq.TLO.Me.ID() then
                        buffCheckPassed = Casting.SelfBuffItemCheck(clicky.itemName)
                    elseif targetSpawn.ID() == mq.TLO.Me.Pet.ID() then
                        ---@diagnostic disable-next-line: cast-local-type
                        buffCheckPassed = mq.TLO.Me.Pet.ID() > 0 and Casting.PetBuffItemCheck(clicky.itemName)
                    elseif targetSpawn.Type() == "PC" then
                        ---@diagnostic disable-next-line: cast-local-type
                        buffCheckPassed = Casting.GroupBuffItemCheck(clicky.itemName, targetSpawn)
                    else ---@diagnostic disable-next-line: cast-local-type
                        buffCheckPassed = Casting.DetItemCheck(clicky.itemName, targetSpawn)
                    end

                    if not buffCheckPassed then return false end

                    for _, cond in ipairs(conditions) do
                        local condBlock = self:GetLogicBlockByType(cond.type)
                        if condBlock then
                            ---@diagnostic disable-next-line: deprecated
                            if not Core.SafeCallFunc("Rotation Clicky :: Test clicky Condition", condBlock.cond, caller, targetSpawn, nil, unpack(cond.args or {})) then
                                return false
                            end
                        end
                    end
                    return true
                end,
            })
        end
    end

    return result
end

function Module:GetClickiesForHealRotation(rotationName)
    local result   = {}
    local clickies = Config:GetSetting('Clickies') or {}

    for _, clicky in ipairs(clickies) do
        if clicky.combat_state == "During Heal Rotation"
            and clicky.rotation_name == rotationName
            and clicky.itemName:len() > 0
            and (clicky.enabled == nil or clicky.enabled == true)
        then
            local itemName   = clicky.itemName
            local conditions = clicky.conditions or {}

            table.insert(result, {
                name = itemName,
                type = "Item",
                from_clicky = true,
                cond = function(caller, itemName, targetSpawn)
                    if not Casting.ItemReady(itemName) then return false end
                    local buffCheckPassed = true

                    if targetSpawn.ID() == mq.TLO.Me.ID() then
                        buffCheckPassed = Casting.SelfBuffItemCheck(clicky.itemName)
                    elseif targetSpawn.ID() == mq.TLO.Me.Pet.ID() then
                        ---@diagnostic disable-next-line: cast-local-type
                        buffCheckPassed = mq.TLO.Me.Pet.ID() > 0 and Casting.PetBuffItemCheck(clicky.itemName)
                    elseif targetSpawn.Type() == "PC" then
                        ---@diagnostic disable-next-line: cast-local-type
                        buffCheckPassed = Casting.GroupBuffItemCheck(clicky.itemName, targetSpawn)
                    else ---@diagnostic disable-next-line: cast-local-type
                        buffCheckPassed = Casting.DetItemCheck(clicky.itemName, targetSpawn)
                    end

                    if not buffCheckPassed then return false end

                    for _, cond in ipairs(conditions) do
                        local condBlock = self:GetLogicBlockByType(cond.type)
                        if condBlock then
                            ---@diagnostic disable-next-line: deprecated
                            if not Core.SafeCallFunc("Rotation Clicky :: Test clicky Condition", condBlock.cond, caller, targetSpawn, nil, unpack(cond.args or {})) then
                                return false
                            end
                        end
                    end
                    return true
                end,
            })
        end
    end

    return result
end

function Module:ValidateClickyRotationSettings(clicky)
    local isHeal = clicky.combat_state == "During Heal Rotation"
    if clicky.combat_state ~= "During Rotation" and not isHeal then return false end
    local changed = false
    if not self:ValidateRotationName(clicky.rotation_name, isHeal) then
        Logger.log_warn("\ayClicky Module: rotation '%s' is no longer valid, resetting to None.", tostring(clicky.rotation_name))
        clicky.rotation_name = "None"
        changed = true
    end
    if clicky.target ~= "Rotation Target" then
        clicky.target = "Rotation Target"
        changed = true
    end
    return changed
end

function Module:OnCombatModeChanged()
    self:RebuildRotationCache()
    local clickies = Config:GetSetting('Clickies')
    local changed = false
    for _, clicky in ipairs(clickies) do
        changed = self:ValidateClickyRotationSettings(clicky) or changed
    end
    if changed then
        Config:SetSetting('Clickies', clickies)
    end
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    local result = string.format("\awLoaded \ag%d\at Downtime Clickies and \ag%d\at Combat Clickies\n\n", #Config:GetSetting('DowntimeClickies'),
        #Config:GetSetting('CombatClickies'))
    result = result .. "-=-=-=-=-=\n"

    for i, v in ipairs(Config:GetSetting('Clickies')) do
        result = result .. string.format("\atClicky %d: \ay%s\at\n", i, v.itemName)
    end

    return result
end

return Module
