-- Sample Basic Class Module
local mq          = require('mq')
local Icons       = require('mq.ICONS')
local Set         = require("mq.Set")
local Base        = require('modules.base')
local Casting     = require("utils.casting")
local ClassLoader = require('utils.classloader')
local Combat      = require('utils.combat')
local Comms       = require("utils.comms")
local Config      = require('utils.config')
local Core        = require("utils.core")
local DanNet      = require('lib.dannet.helpers')
local Entries     = require("utils.entries")
local Events      = require("utils.events")
local Globals     = require('utils.globals')
local Logger      = require("utils.logger")
local Modules     = require("utils.modules")
local Movement    = require("utils.movement")
local Rotation    = require("utils.rotation")
local Strings     = require("utils.strings")
local Tables      = require("utils.tables")
local Targeting   = require("utils.targeting")
local Ui          = require("utils.ui")

require('utils.datatypes')

local Module   = { _version = '0.1a', _name = "Class", _author = 'Derple', }
Module.__index = Module
setmetatable(Module, { __index = Base, })

Module.ModuleLoaded                          = false
Module.SpellLoadOut                          = {}
Module.LoadOutName                           = "Loading..."
Module.ResolvedActionMap                     = {}
Module.TempSettings                          = {}
Module.CombatState                           = "None"
Module.CurrentRotation                       = { name = "None", state = 0, }
Module.ClassConfig                           = nil

Module.Constants                             = {}

-- Track the state of rotations between frames
Module.TempSettings.CurrentRotationStateId   = 0
Module.TempSettings.CurrentRotationStateType = 0 -- 0 : Invalid, 1 : Combat, 2 : Healing
Module.TempSettings.RotationStates           = {}
Module.TempSettings.HealRotationStates       = {}
Module.TempSettings.RotationTable            = {}
Module.TempSettings.HealRotationTable        = {}
Module.TempSettings.RotationTimers           = {}
Module.TempSettings.RezTimers                = {}
Module.TempSettings.RezAbilities             = nil
Module.TempSettings.CureCheckTimer           = Globals.GetTimeSeconds() -- set this out a bit so we have time to get actor data.
Module.TempSettings.ResolvingActions         = true
Module.TempSettings.CombatModeSet            = false
Module.TempSettings.NewCombatMode            = false
Module.TempSettings.ForceRepackGems          = false
Module.TempSettings.MaxGems                  = mq.TLO.Me.NumGems()
Module.TempSettings.GemEditing               = false
Module.TempSettings.GemDraftOrder            = {}
Module.TempSettings.GemDraftEnabled          = {}
Module.TempSettings.GemDraftReset            = false
Module.TempSettings.LastFastPathTime         = 0
Module.TempSettings.CombatModeChangeTime     = 0
Module.TempSettings.MissingSpells            = {}
Module.TempSettings.MissingSpellsHighestOnly = true
Module.TempSettings.QueuedAbilities          = {}
Module.TempSettings.CureCoroutines           = {}
Module.TempSettings.NeedCuresList            = {}
Module.TempSettings.NeedCuresListMutex       = false
Module.TempSettings.CureChecksStale          = false
Module.TempSettings.ImmuneTargets            = {}
Module.TempSettings.RotationClickies         = Set.new({})
Module.TempSettings.RotationAAs              = Set.new({})
Module.TempSettings.MidSongFireable          = {}

Module.FAQ                                   = {
    {
        Question = "How does RGMercs decide which action to use?",
        Answer =
            "  Every action RGMercs takes comes from a 'rotation': an ordered list of actions the loaded class config runs for a given situation, such as combat, downtime, or buffing.\n\n" ..
            "  Each line in a rotation is a 'rotation entry'. An entry has its own usage conditions and maps to a real spell, AA, item, or discipline. This mapped action is the 'Resolved Action' shown in the rotation table.\n\n" ..
            "  When a rotation runs, RGMercs checks its entries in order and uses those whose conditions pass. Disabled entries and entries whose conditions fail are skipped, along with actions blocked by things like cooldowns, mana, or movement.\n\n" ..
            "  Rotations come in two types, Full and Standard. A Full rotation re-checks every entry from the top on each run, while a Standard rotation resumes from the entry after the last one that succeeded. Leaving combat resets this position to the top.\n\n" ..
            "  Rotations can be viewed in the UI on the Class tab.\n\n" ..
            "  Note: Mez, charm, rez, and cures run on this same rotation engine (and are all treated as Full rotations).",
        Settings_Used = "",
    },
    {
        Question = "How do I add, remove, or change what spells, AA, items or disciplines are being used?",
        Answer = "  RGMercs is designed to choose actions automatically based on the currently loaded 'Class Config'.\n\n" ..
            "  In addition to being able to adjust common settings, the default class configs generally offer some options to enable, disable, or fine-tune action use. These are generally found in (Options > Abililties).\n\n" ..
            "  If you open the options menu from the Class tab, all options added by the class config will have highlighting added.\n\n" ..
            "  Some default configs may also offer different role-based modes, such as a Shaman having a Healing Mode or Hybrid mode, or a Paladin having a Tank Mode and a DPS Mode. These modes can be selected on the Class tab.\n\n" ..
            "  If you find that the options or loadouts do not meet your needs, we support a system to allow the use of 'Custom Configs' that can be freely edited by the user (see FAQs on custom configs).",
        Settings_Used = "",
    },
    {
        Question = "There isn't a setting to change the use of spell, AA, item or discipline, how do I stop it from being used in a rotation?",
        Answer =
            "  A rotation or rotation entry may be disabled using the GUI or CLI:\n\n" ..
            "    GUI: Use the toggle found in the rotation list on the class tab. \n\n" ..
            "    CLI: Use the rotation or rotation entry disable commands (search for 'rotation' and check the command list). \n\n" ..
            "  Please note that there is no performance benefit to disabling unused or unmapped entries, it is suggested that you simply ignore them... your experience or (class) performance may be (negatively) impacted when you do receive the ability.",

        Settings_Used = "",
    },
    {
        Question = "How do I create a Custom Class Config?",
        Answer = "  The GUI can be found on the Class Tab. Near the config load area, you will find a button to create the custom config.\n\n" ..
            "  The final destination will vary by server, but all files will be created in the (MQconfigdir)/rgmercs/class_configs directory. If you are currently on Live or Test, look for the 'Live folder there, otherwise, on emu, look for a server-specifc folder.\n\n" ..
            "  The process will copy the currently loaded config, so ensure you have selected the config you wish to use as a base before hitting the button. If the currently loaded config is *already* a custom config, it will be backed up with a date/time append on the old config.",
        Settings_Used = "",
    },
    {
        Question = "How do I change which Class Config is loaded, or, how do I use my new Custom Class Config?",
        Answer = "  The GUI to change your currently loaded config can be found on the Class Tab.\n\n" ..
            "  The drop-down selection box can be used to choose which config you have loaded. Any configs found for your class (both default and custom) will be displayed.",
        Settings_Used = "",
    },
    {
        Question = "How do I edit my class config?",
        Answer = "  Class configs are written in Lua - a fully documented language - and are fully customizable. Two easy paths:\n\n" ..
            "  Edit it yourself: While it may be possible with a basic editor such as Notepad++, the preferred method is to use a code editor like VS Code (free) and install the 'mq-defs' extension (by ZenithCodeForge, also free) from the Extensions marketplace. This will give you important information about the MQ API, autocomplete, hover docs, and live error-checking.\n\n" ..
            "  Use an AI: run '/rgl copy guide' and paste it into an AI chat, then run '/rgl copy config' and paste that too (paste each one before running the next - the clipboard only holds one at a time). Tell the AI what to change. Claude, ChatGPT, and DeepSeek worked well in our testing; some other models did not.\n\n" ..
            "  Either way, edits belong in a custom config, not the default - see the custom config FAQs for info.",
        Settings_Used = "",
    },
}

Module.CommandHandlers                       = {
    enablerezentry = {
        usage = "/rgl enablerezentry \"<Name>\"",
        about = "Enables a rez ability entry by name.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledRezEntries') or {}
            for _, phase in ipairs({ "Combat", "Downtime", }) do
                enabled[phase] = enabled[phase] or {}
                enabled[phase][name] = true
            end
            Config:SetSetting('EnabledRezEntries', enabled)
            return true
        end,
    },
    disablerezentry = {
        usage = "/rgl disablerezentry \"<Name>\"",
        about = "Disables a rez ability entry by name.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledRezEntries') or {}
            for _, phase in ipairs({ "Combat", "Downtime", }) do
                enabled[phase] = enabled[phase] or {}
                enabled[phase][name] = false
            end
            Config:SetSetting('EnabledRezEntries', enabled)
            return true
        end,
    },
    enablecureentry = {
        usage = "/rgl enablecureentry \"<Name>\"",
        about = "Enables a cure ability entry by name.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledCureEntries') or {}
            for _, bucket in ipairs({ "DetDispel", "Poison", "Disease", "Curse", "Corruption", }) do
                enabled[bucket] = enabled[bucket] or {}
                enabled[bucket][name] = true
            end
            Config:SetSetting('EnabledCureEntries', enabled)
            return true
        end,
    },
    disablecureentry = {
        usage = "/rgl disablecureentry \"<Name>\"",
        about = "Disables a cure ability entry by name.",
        handler = function(self, name)
            local enabled = Config:GetSetting('EnabledCureEntries') or {}
            for _, bucket in ipairs({ "DetDispel", "Poison", "Disease", "Curse", "Corruption", }) do
                enabled[bucket] = enabled[bucket] or {}
                enabled[bucket][name] = false
            end
            Config:SetSetting('EnabledCureEntries', enabled)
            return true
        end,
    },
    cureallow = {
        usage = "/rgl cureallow \"<effect name>\"",
        about = "Adds <effect name> to the Cure Allow List.",
        handler = function(self, name)
            if not name then
                Logger.log_error("/rgl cureallow - no effect name provided.")
                return true
            end
            Config:ZoneListAdd(name, self:ActiveCureList('CureAllowList'))
            return true
        end,
    },
    curedeny = {
        usage = "/rgl curedeny \"<effect name>\"",
        about = "Adds <effect name> to the Cure Deny List.",
        handler = function(self, name)
            if not name then
                Logger.log_error("/rgl curedeny - no effect name provided.")
                return true
            end
            Config:ZoneListAdd(name, self:ActiveCureList('CureDenyList'))
            return true
        end,
    },
    cureallowrm = {
        usage = "/rgl cureallowrm \"<effect name>\" or <List#>",
        about = "Removes <effect name> or <List#> from the Cure Allow List.",
        handler = function(self, arg1)
            if not arg1 then
                Logger.log_error("/rgl cureallowrm - no argument provided.")
                return true
            end
            Config:ZoneListDelete(arg1, self:ActiveCureList('CureAllowList'))
            return true
        end,
    },
    curedenyrm = {
        usage = "/rgl curedenyrm \"<effect name>\" or <List#>",
        about = "Removes <effect name> or <List#> from the Cure Deny List.",
        handler = function(self, arg1)
            if not arg1 then
                Logger.log_error("/rgl curedenyrm - no argument provided.")
                return true
            end
            Config:ZoneListDelete(arg1, self:ActiveCureList('CureDenyList'))
            return true
        end,
    },
    copy = {
        usage = "/rgl copy <config|guide>",
        about =
        "Copy your loaded class config, or the AI editing guide, to the clipboard to hand to an AI assistant (e.g. Claude, ChatGPT, Deepseek).",
        handler = function(self, what)
            what = (what or ""):lower()
            if what == "config" then
                self:CopyConfigToClipboard()
            elseif what == "guide" then
                self:CopyGuideToClipboard()
            else
                Logger.log_info("\awUsage: \ay/rgl copy <config|guide>")
            end
            return true
        end,
    },
    setmode = {
        usage = "/rgl setmode <mode>",
        about = "Change the active class mode to <mode>.",
        handler =
            function(self, mode)
                local newMode = nil
                local newModeIdx = 0

                for i, m in ipairs(self.ClassConfig.Modes) do
                    if m:lower() == mode:lower() then
                        newMode = m
                        newModeIdx = i
                        break
                    end
                end

                if not newMode then
                    Logger.log_error("\arInvalid Mode: \am%s", mode)
                    return true
                end

                if self:IsModeActive(newMode) then
                    Logger.log_info("\awMode \am%s\aw is already active.", newMode)
                    return true
                end

                Config:SetSetting('Mode', newModeIdx)
                Logger.log_info("\awMode change to \am%s\aw requested.", newMode)
                return true
            end,
    },
    spellreload = {
        usage = "/rgl spellreload",
        about = "Updates your class rotations and entries based on current settings. Rescans and (if necessary) reloads your default spell gems.",
        handler = function(self)
            self:RescanLoadout()

            Logger.log_info("\awManual loadout scan initiated.")

            return true
        end,
    },
    enablerotationentry = {
        usage = "/rgl enablerotationentry \"<Name>\"",
        about = "Enables <Name> Rotation Entry",
        handler = function(self, name)
            local enabledRotationEntries = Config:GetSetting('EnabledRotationEntries') or {}
            enabledRotationEntries[name] = true
            Config:SetSetting('EnabledRotationEntries', enabledRotationEntries)
            return true
        end,
    },
    disablerotationentry = {
        usage = "/rgl disablerotationentry \"<Name>\"",
        about = "Disables <Name> Rotation Entry",
        handler = function(self, name)
            local enabledRotationEntries = Config:GetSetting('EnabledRotationEntries') or {}
            enabledRotationEntries[name] = false
            Config:SetSetting('EnabledRotationEntries', enabledRotationEntries)
            return true
        end,
    },
    enablerotation = {
        usage = "/rgl enablerotation \"<Name>\"",
        about = "Enables <Name> Rotation",
        handler = function(self, name)
            local enabledRotations = Config:GetSetting('EnabledRotations') or {}
            enabledRotations[name] = true
            Config:SetSetting('EnabledRotations', enabledRotations)
            return true
        end,
    },
    disablerotation = {
        usage = "/rgl disablerotation \"<Name>\"",
        about = "Disables <Name> Rotation",
        handler = function(self, name)
            local enabledRotations = Config:GetSetting('EnabledRotations') or {}
            enabledRotations[name] = false
            Config:SetSetting('EnabledRotations', enabledRotations)
            return true
        end,
    },
    rebuff = {
        usage = "/rgl rebuff",
        about = "Forces buff checks to re-run on the next rotation. Does not cast any buff.",
        handler = function(self)
            self:ResetRotationTimer("SlowDowntime")
            self:ResetRotationTimer("GroupBuff")
            self:ResetRotationTimer("PetBuff")
            Globals.LastCachedBuffUpdate = {}

            Logger.log_info("\awForcing buff checks.")

            return true
        end,
    },
    cast = {
        usage = "/rgl cast \"<spell>\" <targetId?>",
        about = "Queus a spell for use (memorizes if necessary), falls back to AA if the spell is invalid. If no targetId is entered, your target is used.",
        handler = function(self, spell, targetId)
            targetId = targetId and tonumber(targetId)
            targetId = targetId or (mq.TLO.Target.ID() > 0 and mq.TLO.Target.ID() or mq.TLO.Me.ID())
            Logger.log_debug("\atQueueing Cast: \aw\"\am%s\aw\" on targetId(\am%d\aw)", spell, tonumber(targetId) or mq.TLO.Target.ID())

            self:QueueAbility("spell", spell, targetId)

            return true
        end,
    },
    castaa = {
        usage = "/rgl castaa \"<AAName>\" <targetId?>",
        about = "Queues an AA for use. If no targetId is entered, your target is used.",
        handler = function(self, aaname, targetId)
            targetId = targetId and tonumber(targetId)
            targetId = targetId or (mq.TLO.Target.ID() > 0 and mq.TLO.Target.ID() or mq.TLO.Me.ID())
            Logger.log_debug("\atUsing AA: \aw\"\am%s\aw\" on targetId(\am%d\aw)", aaname, tonumber(targetId) or mq.TLO.Target.ID())

            self:QueueAbility("aa", aaname, targetId)

            return true
        end,
    },
    useitem = {
        usage = "/rgl useitem \"<ItemName>\" <targetId?>",
        about = "Queues an item for use. If no targetId is entered, your target is used.",
        handler = function(self, itemName, targetId)
            targetId = targetId and tonumber(targetId)
            targetId = targetId or (mq.TLO.Target.ID() > 0 and mq.TLO.Target.ID() or mq.TLO.Me.ID())
            Logger.log_debug("\atUsing Item: \aw\"\am%s\aw\" on targetId(\am%d\aw)", itemName, tonumber(targetId) or mq.TLO.Target.ID())

            self:QueueAbility("item", itemName, targetId)

            return true
        end,
    },
    usemap = {
        usage = "/rgl usemap \"<maptype>\" \"<mapname>\" <targetId?>",
        about =
        "RGMercs will queue the mapped spell, song, AA, disc, or item (using smart targeting, or, if provided, on the specified <targetID>). The 'mapname' is the entry name from your rotation window.",
        handler = function(self, mapType, mapName, targetId)
            local action = Modules:ExecModule("Class", "GetResolvedActionMapItem", mapName)
            if not action or (type(action) ~= "string" and not action()) then
                Logger.log_debug("\arUseMap: \"\ay%s\ar\" does not appear to be a valid mapped action! \awPlease note this value is case-sensitive.", mapName)
                return false
            end
            targetId = targetId and tonumber(targetId)
            targetId = targetId or (mq.TLO.Target.ID() > 0 and mq.TLO.Target.ID() or mq.TLO.Me.ID())

            local actionHandlers = {
                spell = function(self)
                    self:QueueAbility("spell", action.RankName(), targetId)
                end,
                song = function(self)
                    self:QueueAbility("song", action.RankName(), targetId)
                end,
                aa = function(self)
                    self:QueueAbility("aa", action, targetId)
                end, --AFAIK we don't have any AA mapped, but, future proof.
                item = function(self)
                    self:QueueAbility("item", action, targetId)
                end,
                disc = function(self)
                    self:QueueAbility("disc", action.RankName(), targetId, action)
                end,
            }

            local handlerFunc = actionHandlers[mapType:lower()]
            if handlerFunc then
                handlerFunc(self)
            else
                Logger.log_debug("\arUseMap: \"\ay%s\ar\" is an invalid maptype. \awValid maptypes are : \agspell \aw| \agsong \aw| \agAA \aw| \agdisc \aw| \agitem", mapType)
            end

            return true
        end,
    },
    stopcast = {
        usage = "/rgl stopcast",
        about =
        "Stops the current cast, removes all retry attempts, and prevents any other rotations or clickies from running until after queued actions have processed.\nMost useful in hotkeys before priority abilities, gate, throne, etc.",
        handler = function(config, value)
            Globals.StopCast = true
            return true
        end,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:LoadSettings()
    Base.LoadSettings(self, function()
        -- load base configurations
        self.ClassConfig = ClassLoader.load(Globals.CurLoadedClass)
        -- HelperFunctions used in legacy configs
        self.Helpers = self.ClassConfig.Helpers or self.ClassConfig.HelperFunctions

        if not self.ClassConfig.DefaultConfig then
            Logger.log_error("\arFailed to Load Core Class Config for Classs: %s", Globals
                .CurLoadedClass)
            return
        end

        -- Add this to all class configs
        self.ClassConfig.DefaultConfig['EnabledRotationEntries'] = {
            DisplayName = "EnabledRotationEntries",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig['EnabledRotations'] = {
            DisplayName = "EnabledRotations",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig['RotationEntryOrder'] = {
            DisplayName = "RotationEntryOrder",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig['SpellGemOrder'] = {
            DisplayName = "SpellGemOrder",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig['EnabledSpellGems'] = {
            DisplayName = "EnabledSpellGems",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig['EnabledRezEntries'] = {
            DisplayName = "EnabledRezEntries",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig['EnabledCureEntries'] = {
            DisplayName = "EnabledCureEntries",
            Type = "Custom",
            Default = {},
        }

        self.ClassConfig.DefaultConfig[string.format("%s_Popped", self._name)] = {
            DisplayName = self._name .. " Popped",
            Type = "Custom",
            Default = false,
        }
    end)

    -- for config file change
    Module.TempSettings.CombatModeSet = false
end

function Module:WriteCustomConfig()
    ClassLoader.writeCustomConfig(Globals.CurLoadedClass)
end

-- Builds the per-user header prepended to the AI editing guide so the AI gets this character's exact save path.
function Module:BuildAIEnvBlock()
    local class = Globals.CurLoadedClass:lower()
    local savePath = string.format("%s/rgmercs/class_configs/%s/%s_class_config.lua", mq.configDir, Globals.ServerEnv, class)
    savePath = savePath:gsub("/", "\\")
    local onCustom = (Config:GetSetting('ClassConfigDir') or ""):find("Custom: ") ~= nil
    local statusLine = onCustom and
        "Custom config: YES - save the edited file to the path above, then reload." or
        "Custom config: NO (you're on a shipped default) - in-game, click Class tab -> Create Custom Config first, then save the edited file to the path above."

    return string.format(
        "<!-- RGMercs auto-filled this for the current user. Use these exact values; ignore the <placeholder> save path in the guide below. -->\n" ..
        "## Your save target (filled in by RGMercs)\n" ..
        "- Save the edited config to: %s\n" ..
        "- Server: %s   Class: %s\n" ..
        "- %s\n" ..
        "- Load it: on the Class tab, select this config in the dropdown if it isn't active, or click Reload Current Config if it is.\n" ..
        "<!-- end auto-filled -->\n\n",
        savePath, Globals.ServerEnv, class, statusLine)
end

function Module:CopyConfigToClipboard()
    local path = ClassLoader.getClassConfigFileName(Globals.CurLoadedClass)
    local f = io.open(path, "r")
    if not f then
        Logger.log_error("\arCould not read your class config at: %s", path)
        return
    end
    local content = f:read("*all")
    f:close()
    ImGui.SetClipboardText(content)
    Logger.log_info("\awCopied your loaded \ag%s\aw config to the clipboard. Paste it into your AI along with the guide (\ay/rgl copy guide\aw).", Globals.CurLoadedClass)
end

function Module:CopyGuideToClipboard()
    local guidePath = string.format("%s/docs/CUSTOMIZING_WITH_AI.md", Globals.ScriptDir)
    local f = io.open(guidePath, "r")
    if not f then
        Logger.log_error("\arCould not find the AI editing guide at: %s", guidePath)
        return
    end
    local guide = f:read("*all")
    f:close()
    ImGui.SetClipboardText(self:BuildAIEnvBlock() .. guide)
    Logger.log_info("\awCopied the AI editing guide (with your save path filled in) to the clipboard. Paste it into your AI, then run \ay/rgl copy config\aw and paste that too.")
end

function Module:Init()
    Base.Init(self)

    -- set dynamic names.
    self:SetDynamicNames()
    self:SetPetHold()
end

function Module:SetDynamicNames()
    for _, data in pairs(self.ClassConfig.Rotations) do
        for _, r in ipairs(data) do
            if r.name_func then
                r.name = Core.SafeCallFunc("SetDynamicName", r.name_func, self) or "Error in name_func!"
            end
        end
    end
    for _, data in pairs(self.ClassConfig.HealRotations or {}) do
        for _, r in ipairs(data) do
            if r.name_func then
                r.name = Core.SafeCallFunc("SetDynamicName", r.name_func, self) or "Error in name_func!"
            end
        end
    end
end

function Module:GetResolvedActionMapItem(item)
    if self.TempSettings.ResolvingActions then return nil end
    return self.ResolvedActionMap[item]
end

function Module:RescanLoadout()
    self.TempSettings.NewCombatMode = true
end

function Module:ReorderGems()
    self.TempSettings.ForceRepackGems = true
    self.TempSettings.NewCombatMode = true
end

function Module:MaintainSwapGem()
    local numGems = mq.TLO.Me.NumGems()
    if numGems ~= self.TempSettings.MaxGems then
        self.TempSettings.MaxGems = numGems
        self:RescanLoadout()
    end
    if Casting.UseGem > numGems or not Casting.IsGemEnabled(Casting.UseGem) then
        for gem = numGems, 1, -1 do
            if Casting.IsGemEnabled(gem) then
                Casting.UseGem = gem
                break
            end
        end
    end
end

function Module:SnapshotGemDraft()
    if not self.SpellLoadOut then return end
    local numGems = mq.TLO.Me.NumGems()

    local order = {}
    for gem = 1, numGems do
        if Casting.IsGemEnabled(gem) then
            local entry = self.SpellLoadOut[gem]
            if entry and entry.selectedSpellData then table.insert(order, entry.selectedSpellData.name) end
        end
    end
    self.TempSettings.GemDraftOrder = order

    local enabled = {}
    for gem = 1, numGems do
        if not Casting.IsGemEnabled(gem) then enabled[gem] = false end
    end
    self.TempSettings.GemDraftEnabled = enabled
end

function Module:BeginGemAdjust()
    self:SnapshotGemDraft()
    self.TempSettings.GemDraftReset = false
    self.TempSettings.GemEditing = true
end

function Module:ResetGemAdjust()
    local order = {}
    for gem = 1, mq.TLO.Me.NumGems() do
        local entry = self.SpellLoadOut and self.SpellLoadOut[gem]
        if entry and entry.selectedSpellData then table.insert(order, entry.selectedSpellData.name) end
    end
    self.TempSettings.GemDraftOrder = order
    self.TempSettings.GemDraftEnabled = {}
    self.TempSettings.GemDraftReset = true
end

function Module:CancelGemAdjust()
    self.TempSettings.GemEditing = false
    self.TempSettings.GemDraftReset = false
    self.TempSettings.GemDraftOrder = {}
    self.TempSettings.GemDraftEnabled = {}
end

function Module:ApplyGemAdjust()
    local order = Config:GetSetting('SpellGemOrder') or {}
    if self.TempSettings.GemDraftReset then
        order[self.LoadOutName] = nil
    else
        order[self.LoadOutName] = self.TempSettings.GemDraftOrder
    end
    Config:SetSetting('SpellGemOrder', order)
    Config:SetSetting('EnabledSpellGems', self.TempSettings.GemDraftEnabled)
    self.TempSettings.GemEditing = false
    self.TempSettings.GemDraftReset = false
    self:ReorderGems()
    Logger.log_info("\awGem adjustments applied.")
end

--- Renders the interactive spell-gem loadout: per-gem enable toggles and priority reordering, editable only while in gem-adjust mode.
--- @param loadoutTable table Map of gem slot → { spell, selectedSpellData } entries.
function Module:RenderGemLoadoutTable(loadoutTable)
    local numGems = mq.TLO.Me.NumGems() or 0
    if numGems == 0 then return end

    local loadOutName = self.LoadOutName
    local editing = self.TempSettings.GemEditing

    local activeEnabled
    if editing then
        activeEnabled = self.TempSettings.GemDraftEnabled
    else
        activeEnabled = Config:GetSetting('EnabledSpellGems') or {}
    end

    local hasOrder
    if editing then
        hasOrder = #self.TempSettings.GemDraftOrder > 0
    else
        hasOrder = (Config:GetSetting('SpellGemOrder') or {})[loadOutName] ~= nil
    end

    local enabledCount = 0
    local swapGem = nil
    for gem = 1, numGems do
        if activeEnabled[gem] ~= false then
            enabledCount = enabledCount + 1
            swapGem = gem
        end
    end

    local entryByName = {}
    for gem = 1, numGems do
        local entry = loadoutTable[gem]
        if entry and entry.selectedSpellData then entryByName[entry.selectedSpellData.name] = entry end
    end

    local orderedNames
    if editing then
        orderedNames = self.TempSettings.GemDraftOrder
    else
        orderedNames = {}
        for gem = 1, numGems do
            if activeEnabled[gem] ~= false and loadoutTable[gem] and loadoutTable[gem].selectedSpellData then
                table.insert(orderedNames, loadoutTable[gem].selectedSpellData.name)
            end
        end
    end

    local display = {}
    local gemToPos = {}
    local gemInsert = {}
    local placedCount = 0
    for gem = 1, numGems do
        gemInsert[gem] = placedCount + 1
        if activeEnabled[gem] ~= false then
            local name = orderedNames[placedCount + 1]
            if name then
                placedCount = placedCount + 1
                display[gem] = entryByName[name]
                gemToPos[gem] = placedCount
            end
        end
    end

    local pendingSwap = nil
    local pendingDrag = nil
    local toggleGem = nil

    if ImGui.BeginTable("GemLoadout", 7, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Icon', ImGuiTableColumnFlags.WidthFixed, 20.0)
        ImGui.TableSetupColumn('Gem', ImGuiTableColumnFlags.WidthFixed, 40.0)
        ImGui.TableSetupColumn('Enable', ImGuiTableColumnFlags.WidthFixed, 30.0)
        ImGui.TableSetupColumn('Set Name', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn('Level', ImGuiTableColumnFlags.WidthFixed, 40.0)
        ImGui.TableSetupColumn('Rank Name', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn("##reorder", ImGuiTableColumnFlags.WidthFixed, 55.0)
        ImGui.TableHeadersRow()

        for gem = 1, numGems do
            local enabled = activeEnabled[gem] ~= false
            local data = display[gem]
            ImGui.TableNextRow()

            ImGui.TableNextColumn()
            if data then Ui.DrawInspectableSpellIcon(data.spell) end

            ImGui.TableNextColumn()
            ImGui.Selectable(string.format("%d##gemrow_%d", gem, gem), false,
                bit32.bor(ImGuiSelectableFlags.SpanAllColumns, ImGuiSelectableFlags.AllowOverlap))
            if editing and data and ImGui.BeginDragDropSource() then
                ImGui.SetDragDropPayload("GEM_REORDER", gemToPos[gem])
                ImGui.Text(data.selectedSpellData.name or "")
                ImGui.EndDragDropSource()
            end
            if editing and ImGui.BeginDragDropTarget() then
                local payload = ImGui.AcceptDragDropPayload("GEM_REORDER")
                if payload then pendingDrag = { payload.Data, gemInsert[gem], } end
                ImGui.EndDragDropTarget()
            end

            ImGui.TableNextColumn()
            ImGui.BeginDisabled(not editing)
            local newState, changed = Ui.RenderOptionToggle(string.format("gem_enable_%d", gem), "", enabled)
            ImGui.EndDisabled()
            Ui.Tooltip("Turn off to keep RGMercs from using this gem.")
            if changed and (newState or enabledCount > 1) then toggleGem = gem end

            ImGui.TableNextColumn()
            if not enabled then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Grey)
                Ui.RenderText("User Defined")
                ImGui.PopStyleColor()
            elseif data then
                Ui.RenderText(data.selectedSpellData.name or "")
            end

            ImGui.TableNextColumn()
            if data then Ui.RenderText(tostring(data.spell.Level())) end

            ImGui.TableNextColumn()
            if data then
                local _, clicked = ImGui.Selectable(data.spell.RankName())
                if clicked then data.spell.RankName.Inspect() end
                Ui.Tooltip(string.format("%s: %s (click to inspect)", data.selectedSpellData.name or "Spell", data.spell.RankName() or "Unknown"))
                if gem == swapGem and hasOrder and (data.spell.RecastTime() or 0) >= 30000 then
                    ImGui.SameLine()
                    ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                    Ui.RenderText(Icons.MD_WARNING)
                    ImGui.PopStyleColor()
                    Ui.Tooltip("This long-refresh spell is parked in the last slot and will not be relocated while a custom order is set.")
                end
            end

            ImGui.TableNextColumn()
            local pos = gemToPos[gem]
            if pos then
                ImGui.BeginDisabled(not editing)
                if pos > 1 then
                    ImGui.PushID(string.format("gem_up_%d", gem))
                    if ImGui.SmallButton(Icons.FA_CHEVRON_UP) then pendingSwap = { pos, pos - 1, } end
                    ImGui.PopID()
                else
                    ImGui.InvisibleButton("##gem_upspace_" .. gem, ImVec2(22, 1))
                end
                ImGui.SameLine()
                if pos < placedCount then
                    ImGui.PushID(string.format("gem_dn_%d", gem))
                    if ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then pendingSwap = { pos, pos + 1, } end
                    ImGui.PopID()
                else
                    ImGui.InvisibleButton("##gem_dnspace_" .. gem, ImVec2(22, 1))
                end
                ImGui.EndDisabled()
            end
        end

        ImGui.EndTable()
    end

    if toggleGem then
        local gems = self.TempSettings.GemDraftEnabled
        if gems[toggleGem] == false then gems[toggleGem] = nil else gems[toggleGem] = false end
        self.TempSettings.GemDraftReset = false
    elseif pendingSwap then
        orderedNames[pendingSwap[1]], orderedNames[pendingSwap[2]] = orderedNames[pendingSwap[2]], orderedNames[pendingSwap[1]]
        self.TempSettings.GemDraftReset = false
    elseif pendingDrag and pendingDrag[1] ~= pendingDrag[2] then
        table.insert(orderedNames, math.min(pendingDrag[2], #orderedNames), table.remove(orderedNames, pendingDrag[1]))
        self.TempSettings.GemDraftReset = false
    end
end

function Module:SetCombatMode(mode)
    if not Tables.TableContains(self.ClassConfig.Modes, mode) then
        Logger.log_error("\ayInvalid Mode: \am%s", mode)
        return false
    end
    Logger.log_debug("\aySettings Combat Mode to: \am%s", mode)
    self.TempSettings.ResolvingActions = true

    if self.ClassConfig then
        self.ResolvedActionMap = Rotation.ResolveActions(self.ClassConfig.ItemSets, self.ClassConfig.AbilitySets, self.ClassConfig.AASets)
        self.TempSettings.ResolvingActions = false

        if self.ClassConfig.SpellList then
            local forceRepack = self.TempSettings.ForceRepackGems or not self.TempSettings.CombatModeSet
            self.SpellLoadOut, self.LoadOutName = Rotation.SetSpellLoadOutByPriority(self, self.ClassConfig.SpellList, forceRepack)
            self.TempSettings.ForceRepackGems = false
        else
            self.SpellLoadOut = Rotation.SetSpellLoadOutByGem(self, self.ClassConfig.Spells)
            self.LoadOutName = "Default"
        end
    end

    if self.ClassConfig.OnModeChange then
        self.ClassConfig.OnModeChange(self, mode)
    end

    self.TempSettings.MissingSpells = Rotation.FindAllMissingSpells(self.ClassConfig.AbilitySets, self.TempSettings.MissingSpellsHighestOnly)

    Modules:ExecAll("OnCombatModeChanged")
end

function Module:ComputedLoadoutMatchesCurrent()
    if not self.ClassConfig or not self.ClassConfig.SpellList then return false end

    local now = Globals.GetTimeMS()
    if (now - self.TempSettings.LastFastPathTime) < 1000 then return false end
    self.TempSettings.LastFastPathTime = now

    local savedMap = self.ResolvedActionMap
    self.ResolvedActionMap = Rotation.ResolveActions(self.ClassConfig.ItemSets, self.ClassConfig.AbilitySets, self.ClassConfig.AASets)

    local forceRepack = self.TempSettings.ForceRepackGems
    local candidate = Rotation.SetSpellLoadOutByPriority(self, self.ClassConfig.SpellList, forceRepack)

    local me = mq.TLO.Me
    for gem = 1, me.NumGems() do
        if Casting.IsGemEnabled(gem) then
            local entry = candidate[gem]
            local computedRank = entry and entry.spell and entry.spell.RankName() or nil
            if computedRank ~= me.Gem(gem)() then
                self.ResolvedActionMap = savedMap
                return false
            end
        end
    end
    return true
end

function Module:ReconcileLoadout()
    if not self.ClassConfig or not self.SpellLoadOut then return end
    if self.TempSettings.ResolvingActions then return end
    if Globals.CurrentState ~= "Downtime" then return end
    if not Combat.CombatSettled(1000) then return end

    local me = mq.TLO.Me
    if me.Feigning() then return end

    local numGems = me.NumGems()
    for gem = 1, numGems do
        local loadoutData = self.SpellLoadOut[gem]
        if loadoutData then
            local desiredRank = loadoutData.spell and loadoutData.spell.RankName() or nil
            if desiredRank and me.Gem(gem)() ~= desiredRank then
                Logger.log_debug("\ayReconcile:\ax gem \am%d\ax mismatch (have=\at%s\ax, want=\ag%s\ax)",
                    gem, tostring(me.Gem(gem)()), desiredRank)
                local _, permanent = Casting.MemorizeSpell(gem, desiredRank, false, 15000)
                if permanent then
                    Logger.log_warning("\ayReconcile:\ar %s no longer in book; skipping gem %d.", desiredRank, gem)
                end
            end
        end
    end
end

function Module:PromptRestoreSwapSlot()
    if not self.ClassConfig or not self.SpellLoadOut then return end
    if Targeting.GetXTHaterCount() > 0 then return end

    local me = mq.TLO.Me
    if me.Feigning() then return end

    local swapGem = Casting.UseGem
    for gem = 1, me.NumGems() do
        if gem ~= swapGem then
            local entry = self.SpellLoadOut[gem]
            local rank = entry and entry.spell and entry.spell.RankName() or nil
            if rank and me.Gem(gem)() ~= rank then return end
        end
    end

    local desired = self.SpellLoadOut[swapGem]
    local desiredRank = desired and desired.spell and desired.spell.RankName() or nil
    if not desiredRank then return end
    if me.Gem(swapGem)() == desiredRank then return end

    Casting.MemorizeSpell(swapGem, desiredRank, false, 15000)
end

function Module:OnCombatModeChanged()
    -- set dynamic names.
    self:SetDynamicNames()
end

function Module:RenderQueuedAbilities()
    if ImGui.CollapsingHeader("Queued Abilities") then
        ImGui.Indent()
        if ImGui.SmallButton("Clear Queue") then
            self.TempSettings.QueuedAbilities = {}
        end
        if #self.TempSettings.QueuedAbilities > 0 then
            if ImGui.BeginTable("QueuedAbilities", 4, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
                ImGui.TableSetupColumn('Time in Queue', (ImGuiTableColumnFlags.WidthFixed), 40.0)
                ImGui.TableSetupColumn('Type', (ImGuiTableColumnFlags.WidthFixed), 20.0)
                ImGui.TableSetupColumn('Target', (ImGuiTableColumnFlags.WidthFixed), 100.0)
                ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 150.0)
                ImGui.TableHeadersRow()

                for _, queueData in pairs(self.TempSettings.QueuedAbilities) do
                    ImGui.TableNextColumn()
                    Ui.RenderText(Strings.FormatTime((Globals.GetTimeSeconds() - queueData.queuedTime)))
                    ImGui.TableNextColumn()
                    Ui.RenderText(queueData.type)
                    ImGui.TableNextColumn()
                    Ui.RenderText(queueData.target and queueData.target.CleanName() or "None")
                    ImGui.TableNextColumn()
                    Ui.RenderText(queueData.name)
                end

                ImGui.EndTable()
            end
        end
        ImGui.Unindent()
        ImGui.Separator()
    end
end

function Module:RenderRotationWithToggle(r, rotationTable, showRotationType)
    local enabledRotationEntriesChanged = false
    local rotationName = r.name
    local enabledRotations = Config:GetSetting('EnabledRotations') or {}
    local enabledRotationEntries = Config:GetSetting('EnabledRotationEntries') or {}
    local rotationDisabled = enabledRotations[r.name] == false
    local rotationIcon = rotationDisabled and Icons.MD_ERROR or (r.lastCondCheck and Icons.MD_CHECK or Icons.MD_CLOSE)
    local headerText = string.format("[%s] %s###Header_%s", rotationIcon, rotationName, rotationName)
    local toggleOffset = 60  -- how far left to move from the far right of the window to render the toggle button
    local timingOffset = 160 -- how far left to move from the far right of the window to render the toggle button

    -- Get start rendering position before we draw anything
    local cursorScreenPos = ImGui.GetCursorPosVec()

    -- Move to the far right minus our offset to render an invis button that will handle mouse inputs
    -- This has to come here because if it comes after the Header, the header will eat our mouse events.
    ImGui.SetCursorPos(ImGui.GetWindowWidth() - toggleOffset, cursorScreenPos.y)
    if ImGui.InvisibleButton("##Enable" .. rotationName, ImVec2(20, 20)) then
        enabledRotations[r.name] = not enabledRotations[r.name]
        Config:SetSetting('EnabledRotations', enabledRotations)
    end

    -- Reset the cursor position to where we started
    ImGui.SetCursorPos(cursorScreenPos)
    if ImGui.CollapsingHeader(headerText) then
        if enabledRotations[r.name] ~= false then
            ImGui.Indent()
            if showRotationType then
                Ui.RenderText("Rotation Type: %s", r.doFullRotation and "Full" or "Standard")
                ImGui.SameLine()
                Ui.RenderText(Icons.MD_INFO_OUTLINE)
                Ui.Tooltip(
                    "Denotes whether entries will be checked from the top every time the rotation is run (Full) or whether the checks start from the entry after the last one to succeed (Standard).\nLeaving combat resets the position of the check marker.")
            end
            local reordered, resetRequested
            enabledRotationEntries, enabledRotationEntriesChanged, reordered, resetRequested = Ui.RenderRotationTable(r.name,
                rotationTable[r.name],
                self.ResolvedActionMap, r.state or 0, enabledRotationEntries, nil, r.reorderable ~= false)
            if reordered and r.state then r.state = 1 end
            if resetRequested then
                if r.state then r.state = 1 end
                self:GetRotations()
            end

            if enabledRotationEntriesChanged then Config:SetSetting('EnabledRotationEntries', enabledRotationEntries) end
            ImGui.Unindent()
        end
    end

    -- Store the position we are at after rendering the Header / Table
    local cursorScreenPosAfterRender = ImGui.GetCursorPosVec()

    -- Move back to where the invisible Button is and render the toggle button just for looks
    -- This has to come here because if we put it where the invisible button is then it renders under the header
    ImGui.SetCursorPos(ImGui.GetWindowWidth() - toggleOffset, cursorScreenPos.y)
    Ui.RenderOptionToggle("##EnableDrawn" .. rotationName, "", not rotationDisabled, true)

    if Config:GetSetting('ShowDebugTiming') then
        -- Draw Timing Data
        ImGui.SetCursorPos(ImGui.GetWindowWidth() - timingOffset, cursorScreenPos.y)
        Ui.RenderText(r.lastTimeSpent and ("<" .. Strings.FormatTimeMS(r.lastTimeSpent * 1000) .. ">") or "")
    end
    -- Now set the rendering cursor back to where we were after the Header / Tables were rendered
    ImGui.SetCursorPos(cursorScreenPosAfterRender)
end

function Module:Render()
    Base.Render(self)

    ImGui.BeginTable("##ClassInfoTable", 2, bit32.bor(ImGuiTableFlags.BordersInner, ImGuiTableFlags.SizingFixedFit))
    ImGui.TableNextColumn()
    Ui.RenderText("Combat State")
    ImGui.TableNextColumn()
    Ui.RenderColoredText(Combat.GetCachedCombatState() == "Combat" and Globals.Constants.Colors.MainCombatColor or Globals.Constants.Colors.MainDowntimeColor,
        "%s", Combat.GetCachedCombatState() or "N/A")
    ImGui.TableNextColumn()
    Ui.RenderText("Rotation")
    ImGui.TableNextColumn()
    Ui.RenderColoredText(Globals.Constants.BasicColors.Cyan, self.CurrentRotation.name)
    ImGui.TableNextColumn()
    Ui.RenderText("State")
    ImGui.TableNextColumn()
    Ui.RenderColoredText(Globals.Constants.BasicColors.LightYellow, tostring(self.CurrentRotation.state))
    ImGui.TableNextColumn()
    ImGui.EndTable()

    ---@type boolean|nil
    local pressed = false

    if self.ClassConfig and self.ModuleLoaded then
        Ui.RenderText("Current Mode:")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(150)
        Ui.Tooltip(self.ClassConfig.DefaultConfig.Mode.Tooltip)
        local newMode
        newMode, pressed = ImGui.Combo("##_select_ai_mode", Config:GetSetting('Mode'), self.ClassConfig.Modes,
            #self.ClassConfig.Modes)
        if pressed then
            Config:SetSetting('Mode', newMode)
            self:RescanLoadout()
        end

        Ui.RenderConfigSelector()

        ImGui.SeparatorText("Config Actions")
        --Ui.RenderText("Actions:")
        if ImGui.SmallButton(Icons.FA_EYE .. " Rescan Loadout") then
            self:RescanLoadout()
            Logger.log_info("\awManual loadout scan initiated.")
        end
        Ui.Tooltip(
            "Rescans settings to update memorized spells and rotations. May be needed if multiple settings are changed in rapid succession or when activatable AA are purchased.")

        ImGui.SameLine()
        if ImGui.SmallButton(Icons.FA_REFRESH .. " Reload Current Config") then
            ClassLoader.reloadConfig()
            Logger.log_info("\awReloading your current config.")
        end
        Ui.Tooltip("Reload the current config from file without restarting RGMercs. Handy for those editing configs out-of-game on the fly.")

        ImGui.SameLine()
        if ImGui.SmallButton(Icons.FA_PENCIL .. " Create Custom Config") then
            Modules:ExecModule("Class", "WriteCustomConfig")
        end
        Ui.Tooltip("Places a copy of the currently loaded class config in the MQ config directory for customization.\nWill back up the existing custom configuration.")

        ImGui.Separator()

        if ImGui.CollapsingHeader(string.format("Spell Loadout (%s)", self.LoadOutName)) then
            ImGui.Indent()
            if self.ClassConfig.SpellList then
                self:RenderGemLoadoutTable(self.SpellLoadOut)
            elseif Tables.GetTableSize(self.SpellLoadOut) > 0 then
                Ui.RenderLoadoutTable(self.SpellLoadOut)
            end

            if self.ClassConfig.SpellList then
                local style = ImGui.GetStyle()
                if self.TempSettings.GemEditing then
                    local resetLabel = self.TempSettings.GemDraftReset and "Reset Pending" or "Reset"
                    local width = ImGui.CalcTextSizeVec("Apply" .. "Cancel" .. resetLabel).x + style.FramePadding.x * 6 + style.ItemSpacing.x * 2
                    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvailVec().x - width)
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionPassColor)
                    if ImGui.SmallButton("Apply") then self:ApplyGemAdjust() end
                    ImGui.PopStyleColor()
                    Ui.Tooltip("Save your gem changes and re-memorize to match.")
                    ImGui.SameLine()
                    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.ConditionFailColor)
                    if ImGui.SmallButton("Cancel") then self:CancelGemAdjust() end
                    ImGui.PopStyleColor()
                    Ui.Tooltip("Discard your changes and leave adjust mode.")
                    ImGui.SameLine()
                    if ImGui.SmallButton(resetLabel) then self:ResetGemAdjust() end
                    Ui.Tooltip("Reset all gems to the default priority order and re-enable every gem.")
                else
                    local width = ImGui.CalcTextSizeVec("Adjust Gems").x + style.FramePadding.x * 2
                    if self.TempSettings.NewCombatMode then
                        width = width + style.ItemSpacing.x + ImGui.CalcTextSizeVec("Rescan Pending").x
                    end
                    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvailVec().x - width)
                    if ImGui.SmallButton("Adjust Gems") then self:BeginGemAdjust() end
                    Ui.Tooltip("Unlock the gem controls to reorder gems and enable or disable them.")
                    if self.TempSettings.NewCombatMode then
                        ImGui.SameLine()
                        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Yellow)
                        Ui.RenderText("Rescan Pending")
                        ImGui.PopStyleColor()
                    end
                end
            else
                if ImGui.SmallButton("Reload Spells") then
                    self:RescanLoadout()
                    Logger.log_info("\awManual loadout scan initiated.")
                end
            end
            ImGui.Unindent()
            ImGui.Separator()
        end
        if ImGui.CollapsingHeader("Missing Spells") then
            ImGui.Indent()
            local pressed, anyPressed
            pressed = ImGui.SmallButton("Reload Missing Spells")
            anyPressed = pressed
            ImGui.SameLine()
            self.TempSettings.MissingSpellsHighestOnly, pressed = Ui.RenderOptionToggle("HighestOnly", "Highest Only", self.TempSettings.MissingSpellsHighestOnly)
            anyPressed = anyPressed or pressed
            if anyPressed then
                self.TempSettings.MissingSpells = Rotation.FindAllMissingSpells(self.ClassConfig.AbilitySets, self.TempSettings.MissingSpellsHighestOnly)
            end

            if #self.TempSettings.MissingSpells > 0 then
                Ui.RenderLoadoutTable(self.TempSettings.MissingSpells)
            end
            ImGui.Unindent()
            ImGui.Separator()
        end

        self:RenderQueuedAbilities()

        if not self.TempSettings.ResolvingActions then
            if ImGui.CollapsingHeader("Rotations") then
                ImGui.Indent()
                Ui.RenderText("Combat State: %s", self.CombatState)
                Ui.RenderText("Current Rotation: %s [%d]", self.CurrentRotation.name, self.CurrentRotation.state)

                for _, r in ipairs(self.TempSettings.RotationStates) do
                    self:RenderRotationWithToggle(r, self.TempSettings.RotationTable, true)
                end
                Ui.RenderRotationTableKey()
                ImGui.Unindent()
            end
        end

        if not self.TempSettings.ResolvingActions and #self.TempSettings.HealRotationStates > 0 then
            if ImGui.CollapsingHeader("Healing Rotations") then
                ImGui.Indent()

                for _, r in pairs(self.TempSettings.HealRotationStates) do
                    self:RenderRotationWithToggle(r, self.TempSettings.HealRotationTable)
                end
                Ui.RenderRotationTableKey()
                ImGui.Unindent()
            end
        end

        if not self.TempSettings.ResolvingActions and ((self.ClassConfig and self.ClassConfig.Rez) or self:HasRezClickies()) then
            if ImGui.CollapsingHeader("Rez Abilities") then
                ImGui.Indent()
                local rezAbilities = self:GetRezAbilities()
                if rezAbilities then
                    local enabled = Config:GetSetting('EnabledRezEntries') or {}
                    local changed = false
                    for _, phase in ipairs({ "Downtime", "Combat", }) do
                        local list = rezAbilities[phase]
                        if list and #list > 0 then
                            ImGui.Text(phase)
                            local resolvedMap = {}
                            for _, entry in ipairs(list) do
                                resolvedMap[entry.name] = self:GetResolvedActionMapItem(entry.name)
                            end
                            enabled[phase] = enabled[phase] or {}
                            local newEnabled, entriesChanged, _, resetRequested = Ui.RenderRotationTable("Rez" .. phase, list, resolvedMap, 0, enabled[phase], true, true)
                            enabled[phase] = newEnabled
                            if entriesChanged then changed = true end
                            if resetRequested then self:RebuildRezAbilities() end
                        end
                    end
                    if changed then Config:SetSetting('EnabledRezEntries', enabled) end
                end
                ImGui.Unindent()
            end
        end

        if not self.TempSettings.ResolvingActions and ((self.ClassConfig and self.ClassConfig.Cure) or self:HasCureClickies()) then
            if ImGui.CollapsingHeader("Cure Abilities") then
                ImGui.Indent()
                local cureAbilities = self:GetCureAbilities()
                if cureAbilities then
                    local enabled = Config:GetSetting('EnabledCureEntries') or {}
                    local changed = false
                    for _, bucket in ipairs({ "DetDispel", "Poison", "Disease", "Curse", "Corruption", }) do
                        local list = cureAbilities[bucket]
                        if list and #list > 0 then
                            ImGui.Text(bucket == "DetDispel" and "Detrimental Dispels" or bucket)
                            local resolvedMap = {}
                            for _, entry in ipairs(list) do
                                resolvedMap[entry.name] = self:GetResolvedActionMapItem(entry.name)
                            end
                            enabled[bucket] = enabled[bucket] or {}
                            local newEnabled, entriesChanged, _, resetRequested = Ui.RenderRotationTable("Cure" .. bucket, list, resolvedMap, 0, enabled[bucket], true,
                                true)
                            enabled[bucket] = newEnabled
                            if entriesChanged then changed = true end
                            if resetRequested then self:RebuildCureAbilities() end
                        end
                    end
                    if changed then Config:SetSetting('EnabledCureEntries', enabled) end
                end
                self:RenderCureLists()
                ImGui.Unindent()
            end
        end
    end
end

-- text-entry editor for a zone-scoped cure name list (allow/deny); entries are typed since a buff can't be targeted
function Module:RenderCureList(displayName, settingName)
    self.TempSettings.CureListInput = self.TempSettings.CureListInput or {}
    ImGui.Text(displayName)
    local buffer = ImGui.InputText("##cure_input_" .. settingName, self.TempSettings.CureListInput[settingName] or "")
    self.TempSettings.CureListInput[settingName] = buffer
    ImGui.SameLine()
    ImGui.BeginDisabled(#buffer == 0)
    if ImGui.SmallButton("Add##cure_add_" .. settingName) then
        Config:ZoneListAdd(buffer, self:ActiveCureList(settingName))
        self.TempSettings.CureListInput[settingName] = ""
    end
    ImGui.EndDisabled()

    if ImGui.BeginTable(settingName, 3, bit32.bor(ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn('Id', ImGuiTableColumnFlags.WidthFixed, 40.0)
        ImGui.TableSetupColumn('Effect', ImGuiTableColumnFlags.WidthStretch, 150.0)
        ImGui.TableSetupColumn('Controls', ImGuiTableColumnFlags.WidthFixed, 60.0)
        ImGui.TableHeadersRow()
        for idx, effectName in ipairs(Config:GetZoneList(self:ActiveCureList(settingName))) do
            ImGui.TableNextColumn(); ImGui.Text(tostring(idx))
            ImGui.TableNextColumn(); ImGui.Text(effectName)
            ImGui.TableNextColumn()
            if ImGui.SmallButton(Icons.FA_TRASH .. "##cure_del_" .. settingName .. tostring(idx)) then
                Config:ZoneListDelete(idx, self:ActiveCureList(settingName))
            end
        end
        ImGui.EndTable()
    end
end

-- shared/individual toggle plus the allow/deny cure list editors
function Module:RenderCureLists()
    ImGui.NewLine()
    ImGui.Separator()
    local useShared = Config:GetSetting('UseSharedCureLists')
    local newUseShared = ImGui.Checkbox("Use Shared Cure Lists", useShared)
    Ui.Tooltip("On: shares cure lists with all RGMercs peers on this machine.\nOff: this character uses its own lists.")
    if newUseShared ~= useShared then
        Config:SetSetting('UseSharedCureLists', newUseShared)
    end
    self:RenderCureList("Allow List", "CureAllowList")
    self:RenderCureList("Deny List", "CureDenyList")
end

function Module:ResetRotation()
    for _, v in ipairs(self.TempSettings.RotationStates) do
        if v.state then
            v.state = 1
        end
    end
    for _, v in ipairs(self.TempSettings.HealRotationStates) do
        Logger.log_verbose("HealRotationsState(%s) reset from %d to 1", v.name, v.state)
        if v.state then
            v.state = 1
        end
    end
end

function Module:GetRotationNames()
    local names = {}
    for _, rotation in ipairs(self.ClassConfig and self.ClassConfig.RotationOrder or {}) do
        table.insert(names, rotation.name)
    end
    return names
end

function Module:GetHealRotationNames()
    local names = {}
    for _, rotation in ipairs(self.ClassConfig and self.ClassConfig.HealRotationOrder or {}) do
        table.insert(names, rotation.name)
    end
    return names
end

function Module:GetAllRotationNames()
    return Tables.ConcatTables(self:GetRotationNames(), self:GetHealRotationNames())
end

function Module:GetRotationTable(mode)
    return self.ClassConfig and self.TempSettings.RotationTable[mode] or {}
end

function Module:GetHealRotationTable(mode)
    return self.ClassConfig and self.TempSettings.HealRotationTable[mode] or {}
end

function Module:GetDefaultConfig(config)
    return self.ModuleLoaded and self.ClassConfig[config] or nil
end

---@return number
function Module:GetClassModeId()
    if not self.ModuleLoaded then return 0 end
    return Config:GetSetting('Mode')
end

---@return string
function Module:GetClassModeName()
    if not self.ModuleLoaded or not self.ClassConfig then return "None" end
    return self.ClassConfig.Modes[Config:GetSetting('Mode')] or "None"
end

---@return table
function Module:GetPullAbilities()
    if not self.ClassConfig then return {} end
    return self.ClassConfig.PullAbilities or {}
end

---@return table
function Module:GetPullMoveAbilities()
    if not self.ClassConfig then return {} end
    return self.ClassConfig.PullMoveAbilities or {}
end

---@param mode string
---@return boolean
function Module:IsModeActive(mode)
    local modeSet = Set.new(self.ClassConfig.Modes)
    if not modeSet:contains(mode) then
        Logger.log_error("\arIsModeActive(%s) ==> Invalid Mode Type!", mode)
        return false
    end
    return self:GetClassModeName():lower() == mode:lower()
end

---@return boolean
function Module:IsTanking()
    local modeChecks = self.ClassConfig and self.ClassConfig.ModeChecks
    local classTanking = modeChecks and modeChecks.IsTanking and modeChecks.IsTanking()
    return classTanking or Core.IAmGroupMT()
end

---@return boolean
function Module:IsHealing()
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.IsHealing then
        return false
    end
    return self.ClassConfig.ModeChecks.IsHealing()
end

---@return boolean
function Module:IsRezing()
    -- If we are healing then we are also rezing.
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.IsRezing then
        return self:IsHealing()
    end

    return self.ClassConfig.ModeChecks.IsRezing()
end

---@return boolean
function Module:IsCuring()
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.IsCuring then
        return false
    end
    return self.ClassConfig.ModeChecks.IsCuring()
end

---@return boolean
function Module:IsMezzing()
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.IsMezzing then
        return false
    end
    return self.ClassConfig.ModeChecks.IsMezzing()
end

---@return boolean
function Module:IsCharming()
    return self:CanCharm() and Config:GetSetting('CharmOn')
end

--- Runs the main-loop engage step mid-song, gated to the combat target so it never re-targets off a mez/charm/cure victim.
---@param targetId number The song's target (UseSong's targetId).
function Module:DoMidSongEngage(targetId)
    if (Globals.AutoTargetID or 0) <= 0 or targetId ~= Globals.AutoTargetID then return end

    if not Globals.BackOffFlag then
        Combat.FindBestAutoTarget(Combat.OkToEngagePreValidateId)
    end

    if Combat.OkToEngage(Globals.AutoTargetID) then
        Combat.EngageTarget(Globals.AutoTargetID)
    end
end

--- Whether a midSong-flagged entry is a fireable instant; errors once per zone when it isn't.
---@param entry table
---@return boolean
function Module:MidSongAllowed(entry)
    local cached = self.TempSettings.MidSongFireable[entry]
    if cached ~= nil then return cached end

    local entryType = (entry.type or ""):lower()
    local castTime = 0
    local instantType = true

    if entryType == "disc" then
        local discSpell = self.ResolvedActionMap[entry.name]
        castTime = discSpell and discSpell.MyCastTime() or 0
    elseif entryType == "aa" then
        local aaName = self.ResolvedActionMap[entry.name] or entry.name
        castTime = aaName and (mq.TLO.Me.AltAbility(aaName).Spell.MyCastTime() or 0) or 0
    elseif entryType == "item" or entryType == "clickyitem" then
        local itemName = entryType == "clickyitem" and (entry.name and Config:GetSetting(entry.name)) or self.ResolvedActionMap[entry.name] or entry.name
        local item = itemName and mq.TLO.FindItem("=" .. itemName)
        castTime = (item and item()) and ((item.Clicky() and item.Clicky.CastTime()) or item.CastTime() or 0) or 0
    elseif entryType ~= "ability" then
        instantType = false -- song/spell would start a song; customfunc excluded as a conservative default
    end

    local fireable = instantType and (castTime or 0) == 0
    self.TempSettings.MidSongFireable[entry] = fireable
    if not fireable then
        Logger.log_error("\arMidSong: '%s' (type %s) isn't instant - it can't fire mid-song; remove its midSong flag.", entry.name or "?", entry.type or "nil")
    end
    return fireable
end

--- Fires the midSong-flagged instant rotation entries at the combat auto-target via ExecEntry in fire-and-return mode, so a singing bard's instants go off without clipping the song.
function Module:DoMidSongActions()
    local autoTargetId = Globals.AutoTargetID
    if autoTargetId == 0 or mq.TLO.Target.ID() ~= autoTargetId then return end

    local combat_state = Combat.GetCachedCombatState()
    local enabledRotations = Config:GetSetting('EnabledRotations') or {}
    local enabledEntries = Config:GetSetting('EnabledRotationEntries') or {}

    for _, r in ipairs(self.TempSettings.RotationStates) do
        if r.midSong and enabledRotations[r.name] ~= false then
            if Core.SafeCallFunc("MidSong rotation cond " .. r.name, r.cond, self, combat_state) then
                for _, entry in ipairs(self:GetRotationTable(r.name)) do
                    if entry.midSong and enabledEntries[entry.name] ~= false and self:MidSongAllowed(entry) then
                        Core.SafeCallFunc("MidSong entry " .. entry.name, function()
                            if Rotation.TestConditionForEntry(self, self.ResolvedActionMap, entry, autoTargetId) then
                                Rotation.ExecEntry(self, entry, autoTargetId, self.ResolvedActionMap, false)
                            end
                        end)
                    end
                end
            end
        end
    end
end

---@return boolean
function Module:CanMez()
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.CanMez then
        return false
    end
    return self.ClassConfig.ModeChecks.CanMez()
end

---@return boolean
function Module:CanCharm()
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.CanCharm then
        return false
    end
    return self.ClassConfig.ModeChecks.CanCharm()
end

---@param mobId number
---@return boolean
function Module:CanMezTarget(mobId)
    if not self.ClassConfig or not self.ClassConfig.ModeChecks then
        return true
    end
    return Core.SafeCallFunc("CanMezTarget", self.ClassConfig.ModeChecks.CanMezTarget, self, mobId)
end

function Module:GetTheme()
    if self.ClassConfig and self.ClassConfig.Themes then
        return self.ClassConfig.Themes[self:GetClassModeName()]
    end
end

function Module:GetClassConfig()
    return self.ClassConfig
end

function Module:GetHelpers()
    return self.Helpers
end

function Module:GetRotations()
    -- filter rotations for load conditions, populate rotation states
    self.TempSettings.RotationStates = {} -- clear the array for loadout rescans
    self.TempSettings.RotationTable = {}
    for _, rotation in ipairs(self.ClassConfig.RotationOrder or {}) do
        if self:LoadConditionPass(rotation) then
            table.insert(self.TempSettings.RotationStates, rotation)
            self.TempSettings.RotationTable[rotation.name] = {}
            self.ClassConfig.Rotations[rotation.name] = self.ClassConfig.Rotations[rotation.name] or {}
        end
    end

    -- filter rotation entries for load conditions
    for rname, entries in pairs(self.ClassConfig.Rotations or {}) do
        if self.TempSettings.RotationTable[rname] then
            for _, entry in ipairs(entries) do
                if self:LoadConditionPass(entry) then
                    table.insert(self.TempSettings.RotationTable[rname], entry)
                end
            end
            self.TempSettings.RotationTable[rname] = Tables.ConcatTables(self.TempSettings.RotationTable[rname],
                Modules:ExecModule("Clickies", "GetClickiesForRotations", "During Rotation", rname) or {})
        end
    end

    -- apply any user-defined entry order to reorderable rotations (unmapped entries keep their built order)
    local rotationEntryOrder = Config:GetSetting('RotationEntryOrder') or {}
    local function applyEntryOrder(states, tables)
        for _, rotation in ipairs(states) do
            if rotation.reorderable ~= false then
                Rotation.ApplyEntryOrder(tables[rotation.name], rotationEntryOrder[rotation.name])
            end
        end
    end
    applyEntryOrder(self.TempSettings.RotationStates, self.TempSettings.RotationTable)

    -- Do it all again for heal rotations
    self.TempSettings.HealRotationStates = {} -- clear the array for loadout rescans
    self.TempSettings.HealRotationTable = {}
    for _, rotation in ipairs(self.ClassConfig.HealRotationOrder or {}) do
        if self:LoadConditionPass(rotation) then
            table.insert(self.TempSettings.HealRotationStates, rotation)
            self.TempSettings.HealRotationTable[rotation.name] = {}
        end
    end

    -- filter rotation entries for load conditions
    for rname, entries in pairs(self.ClassConfig.HealRotations or {}) do
        if self.TempSettings.HealRotationTable[rname] then
            for _, entry in ipairs(entries) do
                if self:LoadConditionPass(entry) then
                    table.insert(self.TempSettings.HealRotationTable[rname], entry)
                end
            end
            self.TempSettings.HealRotationTable[rname] = Tables.ConcatTables(self.TempSettings.HealRotationTable[rname],
                Modules:ExecModule("Clickies", "GetClickiesForRotations", "During Heal Rotation", rname) or {})
        end
    end
    applyEntryOrder(self.TempSettings.HealRotationStates, self.TempSettings.HealRotationTable)

    -- Cache the resist type on every entry so Rotation.TestConditionForEntry can gate without per-tick lookups.
    local function deriveResistType(entry)
        local etype = (entry.type or ""):lower()
        local spell = nil
        if etype == "spell" or etype == "song" or etype == "disc" then
            spell = self.ResolvedActionMap[entry.name]
        elseif etype == "aa" then
            local aaName = self.ResolvedActionMap[entry.name] or entry.name
            spell = Casting.GetAASpell(aaName)
        elseif etype == "item" then
            local itemName = self.ResolvedActionMap[entry.name] or entry.name
            spell = Casting.GetClickySpell(itemName)
        elseif etype == "clickyitem" then
            local itemName = Config:GetSetting(entry.name)
            if itemName and itemName:len() > 0 then
                spell = Casting.GetClickySpell(itemName)
            end
        else
            return nil
        end
        if not spell or not spell() then return nil end
        -- Beneficial spells (self/group buffs) are never cast at the mob, so a target's immunity can't gate them even if they carry a resist type.
        if spell.Beneficial() then return nil end
        local rt = spell.ResistType and spell.ResistType()
        return Globals.Constants.ResistTypesSet:contains(rt) and rt or nil
    end

    for _, entries in pairs(self.TempSettings.RotationTable) do
        for _, entry in ipairs(entries) do
            entry.cachedResistType = deriveResistType(entry)
        end
    end
    for _, entries in pairs(self.TempSettings.HealRotationTable) do
        for _, entry in ipairs(entries) do
            entry.cachedResistType = deriveResistType(entry)
        end
    end
end

---@param reason string
---@return boolean
function Module:ReleaseCuresListMutex(reason)
    if not self.TempSettings.NeedCuresListMutex then
        Logger.log_error("\arReleaseCuresListMutex(%s): Mutex was not acquired, cannot release!", reason or "Unknown")
        return false
    end

    Logger.log_verbose("\amReleaseCuresListMutex(%s): Mutex was released!", reason or "Unknown")
    self.TempSettings.NeedCuresListMutex = false
    return true
end

---@param reason string
---@param maxWaitTime integer?
---@return boolean
function Module:GetCuresListMutex(reason, maxWaitTime)
    if not maxWaitTime then
        maxWaitTime = 10000 -- default to 10 seconds
    end

    while self.TempSettings.NeedCuresListMutex do
        mq.delay(10) -- wait for the mutex to be released
        maxWaitTime = maxWaitTime - 10

        if maxWaitTime <= 0 then
            Logger.log_error("\arGetCuresListMutex(%s): Timeout waiting for mutex to be released!", reason or "Unknown")
            return false
        end
    end

    Logger.log_verbose("\amReleaseCuresListMutex(%s): Mutex was acquired!", reason or "Unknown")
    self.TempSettings.NeedCuresListMutex = true
    return true
end

function Module:LoadConditionPass(entry)
    return not entry.load_cond or Core.SafeCallFunc("CheckLoadCondition", entry.load_cond, self)
end

function Module:HealById(id)
    if id == 0 then return end
    if not self.TempSettings.HealRotationStates then return end
    local enabledRotations = Config:GetSetting('EnabledRotations') or {}


    Logger.log_verbose("\awHealById(%d)", id)

    local healTarget = mq.TLO.Spawn(id)

    if not healTarget or not healTarget() or Targeting.GetTargetPctHPs(healTarget) <= 0 or Targeting.GetTargetPctHPs(healTarget) == 100 then
        Logger.log_verbose("\ayHealById(%d):: Target is dead fully healed or in another zone bailing!", id)
        return
    end

    if Targeting.TargetIsType("npc", healTarget) then
        Logger.log_verbose("\ayHealById(%d):: Target is an NPC bailing", id)
        return
    end

    Logger.log_verbose("\awHealById(%d):: Finding best heal to use", id)

    local selectedRotation = nil

    for idx, rotation in ipairs(self.TempSettings.HealRotationStates or {}) do
        if Globals.PauseMain or Globals.StopCast then
            break
        end
        self.TempSettings.CurrentRotationStateType = 2
        self.TempSettings.CurrentRotationStateId = idx

        if enabledRotations and enabledRotations[rotation.name] == false then
            Logger.log_verbose("\aw:::Heal Rotation::: \arSkipping Rotation: %s because it is disabled in the settings.", rotation.name)
        else
            Logger.log_verbose("\awHealById(%d):: Checking if Heal Rotation: \at%s\aw is appropriate to use.", id,
                rotation.name)
            if Core.SafeCallFunc(string.format("Heal Rotation Condition Check for %s", rotation.name), rotation.cond, self, healTarget) then
                rotation.lastCondCheck = true
                Logger.log_verbose("\awHealById(%d):: Heal Rotation: \at%s\aw \agis\aw appropriate to use.", id,
                    rotation.name)
                -- since these are ordered by prioirty we can assume we are the best option.
                selectedRotation = rotation
                if selectedRotation then
                    self.CurrentRotation = { name = selectedRotation.name, state = selectedRotation.state or 0, }

                    -- If we need to heal others we should wait on the cooldown.
                    -- Casting.WaitGlobalCoolDown("Healing: ") -- Algarnote: This is dated to me, have we ever heard of AA or clickies? Let's rely on the OkayToNotHeals nowadays. Testing 7/2026

                    local newState, wasRun = Rotation.Run(self, self:GetHealRotationTable(selectedRotation.name), { id, },
                        self.ResolvedActionMap, selectedRotation.steps or 0, selectedRotation.state or 0,
                        self.CombatState == "Downtime", selectedRotation.doFullRotation or false, nil, Config:GetSetting('EnabledRotationEntries') or {})
                    if selectedRotation.state then selectedRotation.state = newState end

                    if wasRun and Casting.GetLastCastResultName() == "CAST_SUCCESS" then
                        Logger.log_verbose(
                            "\awHealById(%d):: Heal Rotation: \at%s\aw \agis\aw was \agSuccessful\aw!", id,
                            rotation.name)
                        Comms.HandleAnnounce(Comms.FormatChatEvent("Heal", healTarget.CleanName(), Casting.GetLastUsedSpell()),
                            Config:GetSetting('HealAnnounceGroup'),
                            Config:GetSetting('HealAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                        break
                    else
                        Logger.log_verbose(
                            "\awHealById(%d):: Heal Rotation: \at%s\aw \agis\aw was \arNOT \awSuccessful! Conditions: wasRun(%s) castResult(%s) \ayGoing to keep trying!",
                            id,
                            rotation.name, Strings.BoolToColorString(wasRun), Casting.GetLastCastResultName())
                    end
                end
            else
                Logger.log_verbose("\awHealById(%d):: Heal Rotation: \at%s\aw \aris NOT\aw appropriate to use.", id,
                    rotation.name)
                rotation.lastCondCheck = false
            end
        end
    end

    self.TempSettings.CurrentRotationStateType = 0

    if selectedRotation == nil then
        Logger.log_verbose("\ayHealById(%d):: No appropriate heal rotation found. Bailing.", id)
        return
    end
end

function Module:RunHealRotation()
    Logger.log_verbose("\ao[Heals] Checking for injured friends...")
    self:HealById(Combat.FindWorstHurtGroupMember(Config:GetSetting('MaxHealPoint')))

    if Config:GetSetting('UseHealList') then
        self:HealById(Combat.FindWorstHurtHealList(Config:GetSetting('MaxHealPoint')))
    else
        self:HealById(Combat.FindWorstHurtXT(Config:GetSetting('MaxHealPoint')))
    end
end

--- True if anyone we heal (group/pets + heal list or XT) is below the gate threshold this frame.
---@param priority integer HealPriority setting: 2 Big Heal Point, 3 Main Heal Point
---@return boolean
function Module:NeedToHeal(priority)
    local point = Config:GetSetting(priority == 3 and 'MainHealPoint' or 'BigHealPoint')
    if (mq.TLO.Group.Injured(point)() or 0) > 0 then return true end
    if Config:GetSetting('DoPetHeals') and Combat.AnyHurtGroupPet(Config:GetSetting('PetHealPoint')) then return true end
    if Config:GetSetting('UseHealList') then
        return Combat.FindWorstHurtHealList(point) > 0
    end
    return Combat.FindWorstHurtXT(point) > 0
end

function Module:ClearCureFromList(id)
    if self:GetCuresListMutex(string.format("ClearCureFromList(%d)", id)) then
        if self.TempSettings.NeedCuresList then
            if self.TempSettings.NeedCuresList[id] then
                self.TempSettings.NeedCuresList[id] = nil
            end
        end
        self:ReleaseCuresListMutex(string.format("ClearCureFromList(%d)", id))
    end
end

function Module:ClearCureList()
    if self:GetCuresListMutex("ClearCureList") then
        if self.TempSettings.NeedCuresList then
            self.TempSettings.NeedCuresList = {}
        end
        Logger.log_verbose("[Cures] Cure List cleared to avoid spam-curing. We'll check again soon.")
        self:ReleaseCuresListMutex("ClearCureList")
    end
    self.TempSettings.CureChecksStale = true
end

function Module:AddCureToList(id, type)
    if not self.TempSettings.NeedCuresList then
        self.TempSettings.NeedCuresList = {}
    end

    local contained = false

    if self:GetCuresListMutex(string.format("AddCureToList(%d, %s)", id, type)) then
        if self.TempSettings.NeedCuresList[id] then
            contained = self.TempSettings.NeedCuresList[id]:contains(type)
            self.TempSettings.NeedCuresList[id]:add(type)
        else
            self.TempSettings.NeedCuresList[id] = Set.new({ type, })
        end
        self:ReleaseCuresListMutex(string.format("AddCureToList(%d, %s)", id, type))
    end

    if not contained then
        Comms.HandleAnnounce(Comms.FormatChatEvent("Cure", mq.TLO.Spawn(id).CleanName(), "Queued"), Config:GetSetting('CureAnnounceGroup'),
            Config:GetSetting('CureAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
    end
end

-- Cure Engine (config-driven ['Cure'] buckets walked via utils/entries.lua, mirroring the Rez engine)

-- per-bucket user toggle (defaults on); bucket-scoped so a shared name toggles independently per cure kind
function Module:CureEntryEnabled(entry, bucket)
    local buckets = Config:GetSetting('EnabledCureEntries') or {}
    return ((buckets[bucket] or {})[entry.name]) ~= false
end

-- cast the resolved cure on a live target; allowMem lets an un-gemmed cure spell/song mem on demand
function Module:CureEntryCast(entry, spell, resolvedName, targetId)
    local entryType = (entry.type or ""):lower()
    local name = (entryType == "aa" or entryType == "item" or entryType == "ability") and resolvedName or spell.RankName()
    Casting.UseEntry(entryType, name, targetId, { allowMem = true, spell = spell, })
end

-- rebuild the load_cond-filtered cure lists per bucket on rescan; also derives CuresPeerCapable (any entry not selfOnly)
function Module:RebuildCureAbilities()
    local cure = self.ClassConfig and self.ClassConfig.Cure
    self.TempSettings.CureClickiesPresent = false
    local cureClickies = {}
    for _, bucket in ipairs({ "DetDispel", "Poison", "Disease", "Curse", "Corruption", }) do
        cureClickies[bucket] = Modules:ExecModule("Clickies", "GetClickiesForAction", "As a Cure Action", bucket) or {}
        if #cureClickies[bucket] > 0 then self.TempSettings.CureClickiesPresent = true end
    end
    if not cure and not self.TempSettings.CureClickiesPresent then
        self.TempSettings.CureAbilities = nil
        self.TempSettings.CuresPeerCapable = false
        return
    end
    self.TempSettings.CureAbilities = {}
    self.TempSettings.GroupDetDispelSpellIDs = {}
    local peerCapable = self.TempSettings.CureClickiesPresent
    local order = Config:GetSetting('RotationEntryOrder') or {}
    for _, bucket in ipairs({ "DetDispel", "Poison", "Disease", "Curse", "Corruption", }) do
        if (cure and cure[bucket]) or #cureClickies[bucket] > 0 then
            local entries = Entries.FilterLoaded(cure and cure[bucket] or {}, self)
            Rotation.ApplyEntryOrder(entries, order["Cure" .. bucket])
            self.TempSettings.CureAbilities[bucket] = Tables.ConcatTables(entries, cureClickies[bucket])
            for _, entry in ipairs(entries) do
                if not entry.selfOnly then peerCapable = true end
            end
        end
    end
    self.TempSettings.CuresPeerCapable = peerCapable

    -- record our group-scoped det dispels by spell ID so peers can tell (live, off Me.Casting) when we're covering the whole group
    for _, entry in ipairs(self.TempSettings.CureAbilities['DetDispel'] or {}) do
        if not entry.selfOnly then
            local resolvedName = self:GetResolvedActionMapItem(entry.name) or entry.name
            local spell        = Entries.Spell(entry, resolvedName)
            if type(spell) ~= "string" and spell and spell() and Casting.IsGroupSpell(spell.TargetType()) then
                self.TempSettings.GroupDetDispelSpellIDs[spell.ID()] = true
            end
        end
    end
end

function Module:GetCureAbilities()
    if self.TempSettings.CureClickiesPresent == nil then self:RebuildCureAbilities() end -- lazy build covers first-load ordering
    return self.TempSettings.CureAbilities
end

function Module:HasCureClickies()
    if self.TempSettings.CureClickiesPresent == nil then self:RebuildCureAbilities() end
    return self.TempSettings.CureClickiesPresent
end

-- walk the bucket's priority list on targetSpawn; first enabled, in-scope, resolved, reachable, cond-passing, ready entry casts and wins (one cast)
function Module:WalkCureBucket(bucket, targetSpawn)
    local cureAbilities = self:GetCureAbilities()
    if not cureAbilities then return false end
    local entries = cureAbilities[bucket]
    if not entries then return false end

    local isSelf = targetSpawn.ID() == mq.TLO.Me.ID()
    local downtime = Combat.GetCachedCombatState() == "Downtime"
    local clickyOnly = not self:IsCuring()
    for _, entry in ipairs(entries) do
        if (not clickyOnly or entry.from_clicky) and self:CureEntryEnabled(entry, bucket) and (not entry.selfOnly or isSelf) then
            local resolvedName = self:GetResolvedActionMapItem(entry.name) or entry.name
            local spell        = Entries.Spell(entry, resolvedName)
            if Entries.Resolves(entry, spell) then
                local isGroupCure      = type(spell) ~= "string" and spell and Casting.IsGroupSpell(spell.TargetType())
                local isGroupDetDispel = type(spell) ~= "string" and spell and (self.TempSettings.GroupDetDispelSpellIDs or {})[spell.ID()] == true
                -- skip group cures for out-of-group targets (cross-group stays single-target); hold our own group dispel if a peer is already covering our group
                if not (isGroupCure and not (isSelf or Targeting.GroupedWithTarget(targetSpawn)))
                    and not (isGroupDetDispel and self.TempSettings.GroupDispelCovered)
                    and (not entry.cond or Core.SafeCallFunc("Cure entry cond", entry.cond, self, spell, targetSpawn))
                    and Entries.Ready(entry, spell, resolvedName, downtime) then
                    if isGroupDetDispel then Globals.CastingGroupDispel = true end
                    Core.SafeCallFunc("CureEntryCast", self.CureEntryCast, self, entry, spell, resolvedName, targetSpawn.ID())
                    if isGroupDetDispel then Globals.CastingGroupDispel = false end
                    Comms.HandleAnnounce(Comms.FormatChatEvent("Cure", targetSpawn.DisplayName() or "target", string.format("processing cure with %s", entry.name)),
                        Config:GetSetting('CureAnnounceGroup'), Config:GetSetting('CureAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                    return true
                end
            end
        end
    end
    return false
end

-- the active cure list setting name, swapped to the shared variant when shared cure lists are enabled
function Module:ActiveCureList(base)
    return Config:GetSetting('UseSharedCureLists') and (base .. "Shared") or base
end

-- build a name->true set from the current zone's entries in the given cure list, for exact-name membership tests
function Module:ActiveCureNameSet(base)
    local set = {}
    for _, name in ipairs(Config:GetZoneList(self:ActiveCureList(base))) do
        set[name] = true
    end
    return set
end

-- decide and cast one cure for a target: deny/allow-filter its effects, then walk DetDispel / type buckets by priority (first match wins)
function Module:RunCure(targetSpawn, cureEffects, mezzed, denySet, allowSet)
    if (not cureEffects or #cureEffects == 0) and not mezzed then return nil end

    local hasAllow = false
    local types    = {}
    for _, effect in ipairs(cureEffects or {}) do
        if not denySet[effect.name] then
            if allowSet[effect.name] then
                hasAllow = true
            elseif effect.cureType then
                types[effect.cureType] = true
            end
        end
    end

    local downtime         = Combat.GetCachedCombatState() == "Downtime"
    local detDispelSetting = Config:GetSetting('DowntimeDetDispel') -- 1 = Never, 2 = Cure List, 3 = Always

    -- allow-listed effects route to an outright det dispel (no counter fallback); in downtime this needs Cure List or Always
    if hasAllow and (not downtime or detDispelSetting >= 2) and self:WalkCureBucket('DetDispel', targetSpawn) then return true end

    -- mez is always dispelled, regardless of the downtime setting
    if mezzed and self:WalkCureBucket('DetDispel', targetSpawn) then return true end

    -- general counter effects: prefer an outright det dispel (downtime needs Always), else the type-specific cure
    if next(types) then
        if (not downtime or detDispelSetting == 3) and self:WalkCureBucket('DetDispel', targetSpawn) then return true end
        for _, counterType in ipairs({ "Poison", "Disease", "Curse", "Corruption", }) do
            if types[counterType] and self:WalkCureBucket(counterType, targetSpawn) then return true end
        end
    end

    return nil
end

function Module:ProcessCuresList()
    -- make a copy just incase it changes in the other coroutine
    local curesList = self.TempSettings.NeedCuresList

    for id, types in pairs(curesList) do
        local cureTarget = mq.TLO.Spawn(id)
        if not cureTarget or not cureTarget() then
            Logger.log_verbose("\ar[Cures] %s is no longer valid, removing from cure list.", id)

            self:ClearCureFromList(id)
        else
            local typeList = types:toList()
            for _, type in ipairs(typeList) do
                local successful, haveValidOptions = Core.SafeCallFunc("CureNow", self.ClassConfig.Cures.CureNow, self, type, id)

                if not haveValidOptions or successful then
                    -- if succesful, clear the entire list so we don't chain group cures needlessly
                    self:ClearCureList()
                    return
                end
            end

            return
        end
    end
end

function Module:CheckActorForCures(peer, targetId)
    local checks = {
        { type = "Poison", },
        { type = "Disease", },
        { type = "Curse", },
        { type = "Mezzed", },
    }
    if not Core.OnLaz() then
        table.insert(checks, { type = "Corruption", })
    end

    local heartbeat = Comms.GetPeerHeartbeat(peer)
    if heartbeat and heartbeat.Data then
        for _, data in ipairs(checks) do
            local effectId = heartbeat.Data[data.type] or "null"

            Logger.log_verbose("\ay[Cures] CheckActorForCures %s :: %s [%s] => %s", peer, data.check, data.type, effectId)

            if effectId and effectId:lower() ~= "nil" and effectId:lower() ~= "null" and effectId ~= "0" then
                if self.ClassConfig.Cures and self.ClassConfig.Cures.CureNow then
                    self:AddCureToList(targetId, data.type)
                end
                Logger.log_verbose("\ay[Cures] CheckActorForCures %s :: Found effect: %s type %s", peer, tostring(effectId), data.type)
            end
        end
        Logger.log_verbose("\ay[Cures] CheckActorForCures %s :: All checks complete", peer)
        return true
    else
        Logger.log_verbose("\ay[Cures] CheckActorForCures %s :: Actor heartbeat not found.", peer)
    end
    return false
end

function Module:CheckPeerForCures(peer, targetId)
    local checks = {
        { type = "Poison",  check = "Me.Poisoned.ID", },
        { type = "Disease", check = "Me.Diseased.ID", },
        { type = "Curse",   check = "Me.Cursed.ID", },
        { type = "Mezzed",  check = "Me.Mezzed.ID", },
    }
    if not Core.OnLaz() then
        table.insert(checks, { type = "Corruption", check = "Me.Corrupted.ID", })
    end

    if not self.TempSettings.CureChecksStale then
        for _, data in ipairs(checks) do
            local effectId = DanNet.query(peer, data.check, 1000) or "null"
            Logger.log_verbose("\ay[Cures] %s :: %s [%s] => %s", peer, data.check, data.type, effectId)

            if effectId:lower() ~= "null" and effectId ~= "0" then
                -- Queue it!
                if not self.TempSettings.CureChecksStale then
                    if self.ClassConfig.Cures and self.ClassConfig.Cures.CureNow then
                        self:AddCureToList(targetId, data.type)
                    end
                else
                    Logger.log_verbose("\ay[Cures] CheckPeerforCures %s :: Cure Check is stale post-query, skipping.", peer)
                end
            end
        end
    else
        Logger.log_verbose("\ay[Cures] CheckPeerforCures %s :: Cure Check is stale pre-query, skipping.", peer)
    end
end

function Module:CheckSelfForCures()
    local me = mq.TLO.Me
    local selfChecks = {
        { type = "Poison",  check = me.Poisoned.ID() or 0, },
        { type = "Disease", check = me.Diseased.ID() or 0, },
        { type = "Curse",   check = me.Cursed.ID() or 0, },
        -- { type = "Mezzed",  check = me.Mezzed.ID() or 0, }, -- to my knowledge we cannot cure ourselves if mezzed
    }
    if not Core.OnLaz() then
        table.insert(selfChecks, { type = "Corruption", check = me.Corrupted.ID() or 0, })
    end

    for _, data in ipairs(selfChecks) do
        Logger.log_verbose("\ay[Cures] %s :: [%s] => %s", me.CleanName():lower(), data.type, data.check > 0 and data.check or "none")
        if data.check > 0 then
            Comms.HandleAnnounce(Comms.FormatChatEvent("Cure", me.CleanName(), string.format('%s effect found on myself, processing cure.', data.type)),
                Config:GetSetting('CureAnnounceGroup'),
                Config:GetSetting('CureAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
            if self.ClassConfig.Cures and self.ClassConfig.Cures.CureNow then
                local successful, haveValidOptions = Core.SafeCallFunc("CureNow", self.ClassConfig.Cures.CureNow, self, data.type, mq.TLO.Me.ID())

                if not haveValidOptions or successful then
                    -- if succesful, clear the entire list so we don't chain group cures needlessly
                    self:ClearCureList()
                end
                return
            end
        end
    end
end

function Module:CureIsQueued()
    return (Tables.GetTableSize(self.TempSettings.NeedCuresList) or 0) > 0
end

function Module:DoEvents()
    -- Process Cure Coroutines
    local deadCoroutines = {}
    for idx, c in ipairs(self.TempSettings.CureCoroutines) do
        if coroutine.status(c) ~= 'dead' then
            local success, err = coroutine.resume(c)
            if not success then
                Logger.log_error("\arError in Cure Coroutine: %s", err)
            end
        else
            table.insert(deadCoroutines, idx)
        end
    end

    for _, idx in ipairs(deadCoroutines) do
        table.remove(self.TempSettings.CureCoroutines, idx)
    end
end

-- true when the stagger option is set and a peer is landing a group det dispel on our group
function Module:GroupAACureStaggered(actorPeers)
    if not Config:GetSetting('StaggerGroupAACures') then return false end
    for _, heartbeat in pairs(actorPeers) do
        local data = heartbeat.Data
        if data and (Globals.GetTimeSeconds() - (heartbeat.LastHeartbeat or 0)) <= 3 then
            if data.CastingGroupDispel and mq.TLO.Group.Member(data.Target)() then
                Logger.log_debug("[Cures] %s is landing a group det dispel on my groupmate %s, bypassing cure checks.", data.Name, data.Target)
                return true
            end
            -- DEPRECATED 7/26 - sunset 9/1/26. Peers predating the ['Cure'] table don't broadcast the flag; fall back to the named group-cure AAs.
            local casting = data.Casting or ""
            if (casting == "Radiant Cure" or casting == "Group Purify Soul") and mq.TLO.Group.Member(data.Target)() then
                Logger.log_debug("[Cures] %s is casting %s on my groupmate %s, bypassing cure checks.", data.Name, casting, data.Target)
                return true
            end
        end
    end
    return false
end

-- new-model cure pass: cure myself from my own classified effects, then a group or heal-list peer that needs it (one cure per pass, self > group > heal list)
function Module:RunCureWalk()
    Core.GetBuffTable()
    local actorPeers = Comms.GetAllPeerHeartbeats(false)
    self.TempSettings.GroupDispelCovered = self:GroupAACureStaggered(actorPeers)

    local scope = Config:GetSetting('ActorCureScope')                     -- 1 = Self, 2 = Group, 3 = Heal List
    local scanPeers = self.TempSettings.CuresPeerCapable and scope > 1
    if #Globals.CurrentCureEffects == 0 and not scanPeers then return end -- nothing on me and no peers to scan; skip the list builds

    local denySet  = self:ActiveCureNameSet('CureDenyList')
    local allowSet = self:ActiveCureNameSet('CureAllowList')

    if self:RunCure(mq.TLO.Spawn(mq.TLO.Me.ID()), Globals.CurrentCureEffects, false, denySet, allowSet) then return end

    if not scanPeers then return end

    -- partition curable peers by priority: my group first, then heal-list peers outside my group (scope 3 only)
    local healList = scope >= 3 and Set.new(Config:GetSetting('HealList') or {}) or nil
    local groupPeers, healPeers = {}, {}
    for _, heartbeat in pairs(actorPeers) do
        local data = heartbeat.Data
        if data and (#(data.CureEffects or {}) > 0 or data.Mezzed) then -- skip the spawn search for peers with nothing to cure
            if mq.TLO.Group.Member(data.Name)() then
                table.insert(groupPeers, heartbeat)
            elseif healList and healList:contains(data.Name) then
                table.insert(healPeers, heartbeat)
            end
        end
    end

    for _, peerList in ipairs({ groupPeers, healPeers, }) do
        for _, heartbeat in ipairs(peerList) do
            local data = heartbeat.Data
            local cureTarget = mq.TLO.Spawn(string.format("pc =%s", data.Name))
            if (cureTarget.ID() or 0) > 0 and cureTarget.ID() ~= mq.TLO.Me.ID() and (cureTarget.Distance() or 999) < 150 then
                if self:RunCure(cureTarget, data.CureEffects, data.Mezzed, denySet, allowSet) then return end
            end
        end
    end
end

function Module:RunCureRotation(combat_state)
    if combat_state == "Downtime" then -- check freely in combat and the first frame of downtime; then avoid spamming
        if (Globals.GetTimeSeconds() - self.TempSettings.CureCheckTimer) < Config:GetSetting('CureInterval') then return end
        self.TempSettings.CureCheckTimer = Globals.GetTimeSeconds()
    end

    if (self.ClassConfig and self.ClassConfig.Cure) or not (self.ClassConfig and self.ClassConfig.Cures) then
        return self:RunCureWalk()
    end

    -- ===== DEPRECATED FALLBACK ===== DEPRECATED 7/26 - sunset 9/1/26.
    -- Legacy per-type detection + CureNow path for custom configs predating the ['Cure'] table.
    local actorPeers = Comms.GetAllPeerHeartbeats(false)

    if self:GroupAACureStaggered(actorPeers) then return end

    Logger.log_verbose("\ao[Cures] Checking for curables...")

    -- check ourselves locally every frame
    self:CheckSelfForCures()

    -- if we are still processing cure checks from before then just bail for now.
    local cureCount = Tables.GetTableSize(self.TempSettings.CureCoroutines)
    if cureCount > 0 then
        Logger.log_debug("\ay[Cures] Still have %d cure checks to process, will check again later.", cureCount)
        return
    end

    self.TempSettings.CureChecksStale = false

    local dannetPeers = mq.TLO.DanNet.PeerCount()
    local handledPeers = Set.new({})
    local handledPeerCount = 0

    for peer, heartbeat in pairs(actorPeers) do
        local cureTarget = mq.TLO.Spawn(string.format("pc =%s", heartbeat.Data.Name))
        local cureTargetID = cureTarget.ID() or 0 --0 if the peer is not in this zone
        local handled = false
        --current max range on live with raid gear is 137, radiant cure still limited to 100 (300 on laz now but not changing this), but CureNow includes range checks
        if cureTargetID > 0 then
            if cureTargetID == mq.TLO.Me.ID() then
                Logger.log_super_verbose("[Cures - Actors] Peer is myself, skipping.")
            elseif (cureTarget.Distance() or 999) < 150 then
                handled = self:CheckActorForCures(peer, cureTargetID)
            else
                Logger.log_verbose("\ao[Cures - Actors] %s is \arNOT\ao in range", peer or "Unknown")
            end
        else
            Logger.log_verbose("\ao[Cures - Actors] No valid ID for %s, \arNOT\ao in zone", peer or "Unknown")
        end

        Logger.log_verbose("\ay[Cures - Actors] %s :: Handled = %s", peer, tostring(handled))

        if handled then
            handledPeers:add(heartbeat.Data.Name:lower())
            handledPeerCount = handledPeerCount + 1
        end
    end

    if handledPeerCount ~= dannetPeers then
        for i = 1, dannetPeers do
            ---@diagnostic disable-next-line: redundant-parameter
            local peer = DanNet.getPeer(i)
            if peer and peer:len() > 0 then
                local startindex = string.find(peer, "_")
                if startindex then
                    peer = string.sub(peer, startindex + 1)
                end
                peer = peer:lower()
                if peer ~= mq.TLO.Me.Name():lower() and not handledPeers:contains(peer) then
                    local cureTarget = mq.TLO.Spawn(string.format("pc =%s", peer))
                    local cureTargetID = cureTarget.ID() or 0 --0 if the peer is not in this zone

                    --current max range on live with raid gear is 137, radiant cure still limited to 100 (300 on laz now but not changing this), but CureNow includes range checks
                    if cureTargetID > 0 then
                        if (cureTarget.Distance() or 999) < 150 then
                            Logger.log_verbose("\ag[Cures - DanNet] %s is in range - checking for curables", peer)

                            local newCoroutine = coroutine.create(function()
                                self:CheckPeerForCures(peer, cureTargetID)
                            end)

                            if newCoroutine then
                                table.insert(self.TempSettings.CureCoroutines, newCoroutine)
                            else
                                Logger.log_error("\ar[Cures - DanNet] Failed to create coroutine for %s", peer)
                            end
                        else
                            Logger.log_verbose("\ao[Cures - DanNet] %d::%s is \arNOT\ao in range", i, peer or "Unknown")
                        end
                    else
                        Logger.log_verbose("\ao[Cures - DanNet] %d::No valid ID for %s, \arNOT\ao in zone", i, peer or "Unknown")
                    end
                end
            end
        end
    end
end

function Module:RunCounterRotation()
    --can make this a modular table if more "features" are added. recommend adding a timer akin to cures if so.
    if mq.TLO.Me.Song("Curse of Subjugation")() and not mq.TLO.Me.Song("Aureate's Bane")() then
        if Casting.AAReady("Aureate's Bane") then
            return Casting.UseAA("Aureate's Bane", mq.TLO.Me.ID())
        else
            Logger.log_verbose("\ao[CounterActions] \ar***WARNING!***\ay Curse of Subjugation\aw detected, but Aureate's Bane \arNOT\aw available!")
        end
    end
end

function Module:ProcessQueuedEvents()
    if #self.TempSettings.QueuedAbilities == 0 then return false end

    -- wait for cast window to close
    mq.delay("5s", function() return mq.TLO.Me.Casting.ID() == nil end)
    local queueData = self.TempSettings.QueuedAbilities[1]

    Logger.log_debug("\ao[QueuedAbilities] Processing queued %s: %s on %s", queueData.type, queueData.name, queueData.targetId)

    local success = Casting.UseEntry(queueData.type, queueData.name, queueData.targetId, { allowMem = true, spell = queueData.spell, })
    if not success and queueData.type:lower() == "spell" then
        success = Casting.UseAA(queueData.name, queueData.targetId)
    end

    if not success and self.TempSettings.QueuedAbilities[1] ~= nil then
        Logger.log_debug("\arFailed to cast queued %s: %s on %s", queueData.type, queueData.name, queueData.targetId)
        self.TempSettings.QueuedAbilities[1].retries = (self.TempSettings.QueuedAbilities[1].retries or 0) + 1

        if self.TempSettings.QueuedAbilities[1].retries > 3 then
            Logger.log_warning("\arFailed to cast queued %s: %s on %s after 3 attempts - giving up", queueData.type, queueData.name, queueData.targetId)
            table.remove(self.TempSettings.QueuedAbilities, 1)
        else
            Logger.log_debug("\ayRetrying queued %s: %s on %s (%d)", queueData.type, queueData.name, queueData.targetId, self.TempSettings.QueuedAbilities[1].retries)
        end
    else
        Logger.log_debug("\agSuccessfully cast queued %s: %s on %s", queueData.type, queueData.name, queueData.targetId)
        table.remove(self.TempSettings.QueuedAbilities, 1)
    end

    return #self.TempSettings.QueuedAbilities > 0
end

function Module:QueueAbility(type, name, targetId, spell)
    Logger.log_debug("\ayQueuing %s: %s on %s", type, name, targetId)
    table.insert(self.TempSettings.QueuedAbilities, {
        name = name,
        spell = spell,
        targetId = targetId,
        target = mq.TLO.Spawn(targetId),
        type = type,
        queuedTime = Globals.GetTimeSeconds(),
    })
end

function Module:PositionPet()
    local petPos = self.ClassConfig.PetPosition
    if not petPos then return end

    local targetId = Globals.AutoTargetID
    if targetId == 0 then return end

    local pet = mq.TLO.Me.Pet
    if mq.TLO.Me.Pet.ID() == 0 then return false end

    if mq.TLO.Me.Moving() or mq.TLO.Me.Casting() then return end

    local ability

    if not pet.Combat() and (pet.Distance3D() or 0) > 200 then
        -- pet is lagging behind, summon it
        ability = petPos.SummonAA and petPos.SummonAA()
        Logger.log_verbose("PositionPet: Pet is far away and we are in combat, %s is needed.", ability)
    elseif Config:GetSetting('RepositionPet') then
        if pet.Combat() and pet.Target.ID() == targetId then
            -- check if pet needs reposition
            local target = mq.TLO.Spawn(targetId)
            if not target() then return end

            if (Globals.GetTimeSeconds() - (self.TempSettings.LastPetPosCheck or 0)) < 0.25 then return end
            self.TempSettings.LastPetPosCheck = Globals.GetTimeSeconds()

            local frontArc = 180
            local targetFacing = target.Heading.DegreesCCW() or 0
            local inFrontArc = function(y, x)
                local diff = (((target.HeadingToLoc(y, x).DegreesCCW() or 0) - targetFacing + 540) % 360) - 180
                return math.abs(diff) < frontArc / 2
            end

            if not inFrontArc(pet.Y(), pet.X()) then return end

            if inFrontArc(mq.TLO.Me.Y(), mq.TLO.Me.X()) then
                -- Relocate flings the pet in our faced direction, so don't fire mid-turn or it lands off-target.
                local myHeading = mq.TLO.Me.Heading.DegreesCCW() or 0
                local headingDelta = math.abs(myHeading - (self.TempSettings.LastPetPosHeading or myHeading))
                self.TempSettings.LastPetPosHeading = myHeading
                if headingDelta > 180 then headingDelta = 360 - headingDelta end
                if headingDelta > 5 then return end
                ability = petPos.RelocateAA and petPos.RelocateAA()
            else
                ability = petPos.SummonAA and petPos.SummonAA()
            end

            Logger.log_verbose("PositionPet: pet in %s's front arc, %s is needed.", target.CleanName() or "target", ability)
        end
    end

    if not ability or not Casting.AAReady(ability) then return end
    Logger.log_debug("PositionPet: Using %s to move my pet.", ability)
    Casting.UseAA(ability)
end

-- per-phase user toggle (defaults on); scoping by phase lets a shared name toggle independently in each phase
function Module:RezEntryEnabled(entry, phase)
    local phases = Config:GetSetting('EnabledRezEntries') or {}
    return ((phases[phase] or {})[entry.name]) ~= false
end

-- cast the resolved rez on the corpse; allowDead targets the dead corpse, allowMem mems an un-gemmed rez on demand
function Module:RezEntryCast(entry, spell, resolvedName, corpseId)
    local entryType = (entry.type or ""):lower()
    local name = (entryType == "aa" or entryType == "item" or entryType == "ability") and resolvedName or spell.RankName()
    Casting.UseEntry(entryType, name, corpseId, { allowMem = true, allowDead = true, spell = spell, })
end

-- rebuild the load_cond-filtered rez lists per phase on rescan, so a load-gated entry drops from both the cast logic and the UI
function Module:RebuildRezAbilities()
    local rez = self.ClassConfig and self.ClassConfig.Rez
    self.TempSettings.RezClickiesPresent = false
    local rezClickies = {}
    for _, phase in ipairs({ "Combat", "Downtime", }) do
        rezClickies[phase] = Modules:ExecModule("Clickies", "GetClickiesForAction", "As a Rez Action", phase) or {}
        if #rezClickies[phase] > 0 then self.TempSettings.RezClickiesPresent = true end
    end
    if not rez and not self.TempSettings.RezClickiesPresent then
        self.TempSettings.RezAbilities = nil
        return
    end
    self.TempSettings.RezAbilities = {}
    local order = Config:GetSetting('RotationEntryOrder') or {}
    for _, phase in ipairs({ "Combat", "Downtime", }) do
        if (rez and rez[phase]) or #rezClickies[phase] > 0 then
            local entries = Entries.FilterLoaded(rez and rez[phase] or {}, self)
            Rotation.ApplyEntryOrder(entries, order["Rez" .. phase])
            self.TempSettings.RezAbilities[phase] = Tables.ConcatTables(entries, rezClickies[phase])
        end
    end
end

function Module:GetRezAbilities()
    if self.TempSettings.RezClickiesPresent == nil then self:RebuildRezAbilities() end -- lazy build covers first-load ordering
    return self.TempSettings.RezAbilities
end

function Module:HasRezClickies()
    if self.TempSettings.RezClickiesPresent == nil then self:RebuildRezAbilities() end
    return self.TempSettings.RezClickiesPresent
end

-- walk the live phase's priority list; first enabled, resolved, cond-passing, ready, un-rezzed entry wins (one cast)
function Module:RunRez(corpseId, ownerName)
    local rezAbilities = self:GetRezAbilities()
    if not rezAbilities then return nil end

    local combat_state = Combat.GetCachedCombatState()
    local entries      = rezAbilities[combat_state]
    if not entries then return nil end

    local corpseSpawn = mq.TLO.Spawn(corpseId)
    local clickyOnly = not self:IsRezing()
    for _, entry in ipairs(entries) do
        if (not clickyOnly or entry.from_clicky) and self:RezEntryEnabled(entry, combat_state) then
            local resolvedName = self:GetResolvedActionMapItem(entry.name) or entry.name
            local spell        = Entries.Spell(entry, resolvedName)
            if Entries.Resolves(entry, spell)
                and (not entry.cond or Core.SafeCallFunc("Rez entry cond", entry.cond, self, spell, corpseSpawn, ownerName))
                and Entries.Ready(entry, spell, resolvedName, true)
                and Casting.OkayToRez(corpseId) then
                self:RezEntryCast(entry, spell, resolvedName, corpseId)
                return true
            end
        end
    end
    return nil
end

-- stamp the attempt time (retry debounce), then run the rez; ['Rez'] table path preferred, legacy DoRez as fallback
function Module:TryRez(corpseId, ownerName)
    self.TempSettings.RezTimers[corpseId] = Globals.GetTimeSeconds()

    if (self.ClassConfig and self.ClassConfig.Rez) or not (self.Helpers and self.Helpers.DoRez) then
        return Core.SafeCallFunc("RunRez", self.RunRez, self, corpseId, ownerName)
    end

    -- DEPRECATED 6/26 - sunset 9/1/26. Custom configs predating the ['Rez'] table fall here.
    local doRez = self.Helpers and self.Helpers.DoRez
    return Core.SafeCallFunc("DoRez", doRez, self, corpseId, ownerName)
end

-- one enumeration of every nearby PC corpse, partitioned into self / in-group / out-of-group (OOG gated here)
function Module:CheckAndRez(combat_state)
    local rezOutside = Config:GetSetting('RezOutside')
    local myName = mq.TLO.Me.DisplayName()
    local corpses = {}
    local search = "pccorpse radius 100 zradius 50"
    local count = mq.TLO.SpawnCount(search)()
    for i = 1, count do
        local spawn = mq.TLO.NearestSpawn(i, search)
        if spawn and spawn() then
            local ownerName = (spawn.CleanName() or ""):gsub("'s corpse$", "")
            local isSelf = ownerName == myName
            local keep = isSelf or mq.TLO.Group.Member(ownerName)() ~= nil
            if not keep then
                keep = rezOutside and Targeting.IsSafeName("pc", spawn.DisplayName())
            end
            if keep then
                table.insert(corpses, {
                    id         = spawn.ID(),
                    ownerName  = ownerName,
                    isSelf     = isSelf,
                    distance   = spawn.Distance() or 999,
                    classShort = spawn.Class.ShortName() or "",
                })
            end
        end
    end

    -- priority-tier sort (role tier first, distance second); None falls back to plain nearest-first
    local rolePriority = Config:GetSetting('RezRolePriority') or 4
    if rolePriority > 1 then
        local function isPriorityCorpse(corpseClass)
            if rolePriority == 2 then return Globals.Constants.RGHealer:contains(corpseClass) end
            if rolePriority == 3 then return Globals.Constants.RGTank:contains(corpseClass) end
            return Globals.Constants.RGHealer:contains(corpseClass) or Globals.Constants.RGTank:contains(corpseClass)
        end
        table.sort(corpses, function(a, b)
            local aPriority, bPriority = isPriorityCorpse(a.classShort), isPriorityCorpse(b.classShort)
            if aPriority ~= bPriority then return aPriority end
            return a.distance < b.distance
        end)
    else
        table.sort(corpses, function(a, b) return a.distance < b.distance end)
    end

    local rezInZonePC = Config:GetSetting('RezInZonePC')
    local retryRezDelay = Config:GetSetting('RetryRezDelay')
    local peersRezzing = #corpses > 0 and Comms.GetPeersRezzingCorpses() or {}
    for _, corpse in ipairs(corpses) do
        local selfBlocked = corpse.isSelf and (combat_state == "Combat" or not rezInZonePC)
        local ownerInZone = not corpse.isSelf and (combat_state == "Combat" or not rezInZonePC)
            and mq.TLO.Spawn(string.format("PC =%s", corpse.ownerName))()
        local peerRezzing = peersRezzing[corpse.id]
        local recentlyTried = (Globals.GetTimeSeconds() - (self.TempSettings.RezTimers[corpse.id] or 0)) < retryRezDelay
        if not selfBlocked and not ownerInZone and not peerRezzing and not recentlyTried then
            Logger.log_debug("\atRez: attempting rez of %s (%d)", corpse.ownerName, corpse.id)
            if self:TryRez(corpse.id, corpse.ownerName) and combat_state == "Combat" then
                break -- rez one in combat, then yield to the next tick's heal/cure pass
            end
        end
    end

    -- EMU: clear the already-rezzed set once corpses despawn, so a recycled spawn id isn't treated as rezzed
    if Core.OnEMU() and mq.TLO.SpawnCount("pccorpse radius 150 zradius 50")() == 0 then
        Globals.RezzedCorpses = {}
        Globals.CorpseConned = false
        Casting.RezConsiderCache = {}
    end
end

function Module:GiveTime()
    local combat_state = Combat.GetCachedCombatState()

    if not self.ClassConfig or not self.ModuleLoaded then return end
    self:MaintainSwapGem()
    local enabledRotations = Config:GetSetting('EnabledRotations') or {}

    local me               = mq.TLO.Me
    if me.Hovering() or me.Stunned() or me.Charmed() or me.Mezzed() or me.Feared() then
        Logger.log_super_verbose("Class GiveTime aborted, we aren't in control of ourselves. Hovering(%s) Stunned(%s) Charmed(%s) Feared(%s) Mezzed(%s)",
            Strings.BoolToColorString(me.Hovering()), Strings.BoolToColorString(me.Stunned()), Strings.BoolToColorString(me.Charmed() ~= nil),
            Strings.BoolToColorString(me.Mezzed() ~= nil), Strings.BoolToColorString(me.Feared() ~= nil))
        return
    end

    if self.TempSettings.NewCombatMode or not self.TempSettings.CombatModeSet then
        local canApply = (not self.TempSettings.CombatModeSet)
            or (combat_state == "Downtime" and Combat.CombatSettled(1000))
            or self:ComputedLoadoutMatchesCurrent()

        if canApply then
            Logger.log_debug("New Combat Mode Requested: %s", self.ClassConfig.Modes[Config:GetSetting('Mode')])

            self:SetCombatMode(self.ClassConfig.Modes[Config:GetSetting('Mode')])
            self:GetRotations()
            self:RebuildRezAbilities()
            self:RebuildCureAbilities()
            if self:IsCuring() then
                if self.ClassConfig.Cures and self.ClassConfig.Cures.GetCureSpells then
                    Core.SafeCallFunc("GetCureSpells", self.ClassConfig.Cures.GetCureSpells, self)
                end
            end
            self:SetRotationActions()
            self.TempSettings.NewCombatMode = false
            self.TempSettings.CombatModeSet = true
            self.TempSettings.CombatModeChangeTime = Globals.GetTimeSeconds()

            Config:BroadcastConfigs()
        end
    end

    self:ReconcileLoadout()

    if self.CombatState ~= combat_state and combat_state == "Downtime" then
        self:ResetRotation()
    end

    self.CombatState = combat_state

    if Config.ShouldPriorityFollow() then
        Logger.log_verbose("\arSkipping Class GiveTime because we are moving and follow is the priority.")
        return
    end

    Globals.StopCast = false

    if self:ProcessQueuedEvents() then
        -- more to do next frame.
        return
    end

    -- Healing happens first and anytime we aren't in downtime while invis and set not to break it.
    if self:IsHealing() then
        if not (combat_state == "Downtime" and mq.TLO.Me.Invis() and not Config:GetSetting('BreakInvisForHealing')) then
            self:RunHealRotation()
        end
    end

    if (self:IsRezing() or self:HasRezClickies()) and Config:GetSetting('DoRez') and Core.OkayToNotHeal(2) then
        if not (combat_state == "Downtime" and mq.TLO.Me.Invis() and not Config:GetSetting('BreakInvisForHealing')) then
            self:CheckAndRez(combat_state)
        end
    end

    if self:IsCuring() or (Config:GetSetting('DoCures') and self:HasCureClickies()) then
        local legacyCure = not (self.ClassConfig and self.ClassConfig.Cure) and (self.ClassConfig and self.ClassConfig.Cures) ~= nil
        if not (combat_state == "Downtime" and mq.TLO.Me.Invis() and not Config:GetSetting('BreakInvisForHealing')) then
            self:RunCureRotation(combat_state)

            if legacyCure then
                if Module.TempSettings.NeedCuresListMutex then
                    Logger.log_debug("\ay[Cures] A coroutine is currently in mutex, bypassing cure list processing.")
                else
                    self:ProcessCuresList()
                end
            end
        end

        if legacyCure then self:DoEvents() end
    end

    --Counter TOB Debuff with AA Buff, this can be refactored/expanded if they add other similar systems
    if Config:GetSetting('UseCounterActions') then
        Logger.log_verbose("\ao[CounterActions] Checking for debuffs to counter...")
        self:RunCounterRotation()
    end

    if self:IsTanking() and Config:GetSetting('KeepMobsInFront') and Movement:CanReposition() and Movement:DetectMobBehind() then
        Movement:TankReposition()
    end

    if combat_state == "Combat" then
        self:PositionPet()
    end

    -- stop singing after pause so we can take over again (if we are active, we will stop our own songs). If paused, allow user to manage their own songs.
    if Core.MyClassIs("BRD") and not Globals.PauseMain and mq.TLO.Me.Casting() ~= nil and not mq.TLO.Window("CastingWindow").Open() then
        Core.DoCmd("/stopsong")
    end

    -- Downtime rotation will just run a full rotation to completion
    for idx, r in ipairs(self.TempSettings.RotationStates) do
        if Globals.PauseMain or Globals.StopCast then
            break
        end
        Logger.log_verbose("\ay:::TEST ROTATION::: => \at%s", r.name)
        self.TempSettings.CurrentRotationStateType = 1
        self.TempSettings.CurrentRotationStateId = idx
        local timeCheckPassed = true

        if enabledRotations[r.name] == false then
            Logger.log_verbose("\aw:::RUN ROTATION::: \arSkipping Rotation: %s because it is disabled in the settings.", r.name)
        else
            self.TempSettings.RotationTimers[r.name] = self.TempSettings.RotationTimers[r.name] or 0
            local rotationTimer = r.timer
            if type(rotationTimer) == "function" then
                rotationTimer = Core.SafeCallFunc(string.format("Rotation Timer for %s", r.name), rotationTimer, self)
                if type(rotationTimer) ~= "number" then
                    Logger.log_error("\arRotation timer for \at%s\ar did not return a number, defaulting to 1 second.", r.name)
                    rotationTimer = 1
                end
            end
            if not rotationTimer then     -- default to only processing Downtime rotations once per second if no timer is specified.
                timeCheckPassed = self.CombatState ~= "Downtime" and true or ((Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name]) >= 1)
            elseif rotationTimer > 0 then -- see if we've waited the rotation timer out.
                timeCheckPassed = ((Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name]) >= rotationTimer)
            end

            if timeCheckPassed then
                local start = string.format("%.03f", Globals.GetTimeMS())
                local targetTable = Core.SafeCallFunc("Rotation Target Table", r.targetId)
                if targetTable and #targetTable > 0 then
                    if Core.SafeCallFunc(string.format("Rotation Condition Check for %s", r.name), r.cond, self, combat_state) then
                        r.lastCondCheck = true
                        Logger.log_verbose("\aw:::RUN ROTATION::: \am%s", r.name)
                        self.CurrentRotation = { name = r.name, state = r.state or 0, }
                        local newState = Rotation.Run(self, self:GetRotationTable(r.name), targetTable,
                            self.ResolvedActionMap, r.steps or 0, r.state or 0, self.CombatState == "Downtime" and not r.blockMem, r.doFullRotation or false, r.cond,
                            Config:GetSetting('EnabledRotationEntries') or {})

                        if r.state then r.state = newState end
                        self.TempSettings.RotationTimers[r.name] = Globals.GetTimeSeconds()
                    else
                        r.lastCondCheck = false
                    end
                end
                local stop = string.format("%.03f", Globals.GetTimeMS())

                r.lastTimeSpent = stop - start
            else
                Logger.log_verbose(
                    "\ay:::TEST ROTATION::: => \at%s :: Skipped due to timer! Last Run: %s Next Run %s", r.name,
                    Strings.FormatTime(Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name]),
                    Strings.FormatTime((rotationTimer or 1) - (Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name])))
                if rotationTimer then r.lastCondCheck = false end --update rotation UI when rotation doesn't fire due to timer check
            end
        end
    end

    self:PromptRestoreSwapSlot()

    self.TempSettings.CurrentRotationStateType = 0
end

function Module:SetCurrentRotationState(state)
    if self.TempSettings.CurrentRotationStateType == 0 then return end

    if self.TempSettings.CurrentRotationStateType == 1 then
        if not self.TempSettings.RotationStates[self.TempSettings.CurrentRotationStateId] then return end
        self.TempSettings.RotationStates[self.TempSettings.CurrentRotationStateId].state = state
    end

    if self.TempSettings.CurrentRotationStateType == 2 then
        if not self.TempSettings.HealRotationStates[self.TempSettings.CurrentRotationStateId] then return end
        self.TempSettings.HealRotationStates[self.TempSettings.CurrentRotationStateId].state = state
    end
end

function Module:OnDeath()
    Targeting.ClearTarget()
    Movement:DoNav(false, "stop")
    Movement:DoStickCmd("off")
end

function Module:OnZone()
    -- Zone Handler
    mq.delay("30s", function() return mq.TLO.Me.Zoning() == false end) --don't try to do anything while we are still zoning
    if not mq.TLO.Me.Zoning() then
        local addDelay = 8 * (mq.TLO.EverQuest.Ping() or 150)          -- add'l delay to ensure we are fully loaded
        mq.delay(addDelay)
        self:SetPetHold()
    end
    Module.TempSettings.ImmuneTargets = {}   -- clear list of slow/snare/stun immune mobs
    Module.TempSettings.QueuedAbilities = {} -- clear queued actions
    Module.TempSettings.MidSongFireable = {} -- re-check (and re-warn) mid-song eligibility each zone
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    local actionMap = "Action Map\n"
    actionMap = actionMap .. "-=-=-=-=-=\n"
    for k, entry in pairs(self.ResolvedActionMap) do
        local mappedAction = entry

        if type(mappedAction) ~= "string" then
            mappedAction = mappedAction.RankName()
        end

        actionMap = actionMap .. string.format("%-20s ==> %s\n", k, mappedAction)
    end
    local spellLoadout = "Spell Loadout\n-=-=-=-=-=-=-\n"

    for g, s in pairs(self.SpellLoadOut) do
        spellLoadout = spellLoadout .. string.format("[%-2d] :: %s\n", g, (s.spell.RankName.Name() or "None"))
    end

    local rotationStates = "Current Rotation States\n-=-=-=-=-=-=-=-\n"
    for idx, r in ipairs(self.TempSettings.RotationStates) do
        local actionEntry = self.TempSettings.RotationTable[r.name][r.state or 1]
        if actionEntry then
            rotationStates = rotationStates ..
                string.format("[%d] %s :: %d :: Type: %s Action: %s\n", idx, r.name, r.state or 0, actionEntry.type,
                    self.ResolvedActionMap[actionEntry.name] and self.ResolvedActionMap[actionEntry.name] or actionEntry
                    .name)
        end
    end

    local state = string.format("Combat State: %s", self.CombatState)

    return string.format("Class(%s)\n%s\n%s\n%s\n%s", Globals.CurLoadedClass, actionMap, spellLoadout,
        rotationStates, state)
end

function Module:GetVersionString()
    if not self.ClassConfig then return "Unknown" end
    return string.format("%s %s", Globals.CurLoadedClass, self.ClassConfig._version)
end

function Module:GetAuthorString()
    if not self.ClassConfig then return "Unknown" end
    return string.format("%s", self.ClassConfig._author)
end

function Module:GetCommandHandlers()
    local cmdHandlers = self.CommandHandlers or {}

    for cmd, data in pairs(self.ClassConfig.CommandHandlers or {}) do
        cmdHandlers[cmd] = data
    end

    return { module = self._name, CommandHandlers = cmdHandlers, }
end

function Module:GetClassFAQ()
    return { module = "Class Config", FAQ = self.ClassConfig.ClassFAQ or {}, }
end

---@param cmd string
---@param ... string
---@return boolean
function Module:HandleBind(cmd, ...)
    -- /rglua cmd handler
    if self.ClassConfig and self.ClassConfig.CommandHandlers and self.ClassConfig.CommandHandlers[cmd] then
        return Core.SafeCallFunc(string.format("Command Handler: %s", cmd), self.ClassConfig.CommandHandlers[cmd].handler, self, ...)
    end

    if self.CommandHandlers and self.CommandHandlers[cmd] then
        return Core.SafeCallFunc(string.format("Command Handler: %s", cmd), self.CommandHandlers[cmd].handler, self, ...)
    end

    -- try to process as a substring
    for bindCmd, bindData in pairs(self.ClassConfig.CommandHandlers or {}) do
        if Strings.StartsWith(bindCmd, cmd) then
            return Core.SafeCallFunc(string.format("Command Handler: %s", cmd), bindData.handler, self, ...)
        end
    end

    for bindCmd, bindData in pairs(self.CommandHandlers or {}) do
        if Strings.StartsWith(bindCmd, cmd) then
            return Core.SafeCallFunc(string.format("Command Handler: %s", cmd), bindData.handler, self, ...)
        end
    end

    return false
end

function Module:ResetRotationTimer(rotation)
    if self.TempSettings.RotationTimers[rotation] then
        Logger.log_verbose("\ayResetting Class:TempSettings.RotationTimers[\ag%s\ay].", rotation)
        self.TempSettings.RotationTimers[rotation] = 0
    end
end

function Module:SetPetHold()
    if Config:GetSetting('DoPetCommands') and mq.TLO.Me.Pet.ID() > 0 then
        if Casting.CanUseAA("Companion's Discipline") or Casting.CanUseAA("Pet Discipline") then
            if not mq.TLO.Me.Pet.GHold() then
                Core.DoCmd("/pet ghold on")
            end
        elseif not mq.TLO.Me.Pet.Hold() then
            Core.DoCmd("/pet hold on")
        end
    end
end

function Module:AddImmuneTarget(effect, targetId)
    if not effect or not targetId or targetId == 0 then return false end

    if not Module.TempSettings.ImmuneTargets[effect] then
        Module.TempSettings.ImmuneTargets[effect] = Set.new({})
    end
    Module.TempSettings.ImmuneTargets[effect]:add(targetId)
end

function Module:TargetIsImmune(effect, targetId)
    if not effect or not targetId or targetId == 0 then return false end

    local effectSet = Module.TempSettings.ImmuneTargets[effect]
    if effectSet and effectSet:contains(targetId) then
        Logger.log_verbose("\ay   :: Status immunity matched (runtime) - target(%d) flagged %s-immune", targetId, effect)
        return true
    end

    if targetId == Globals.AutoTargetID and Globals.AutoTargetStatusImmunities[effect] then
        Logger.log_verbose("\ay   :: Status immunity matched (registry) - auto-target flagged %s-immune", effect)
        return true
    end

    return false
end

function Module:SetRotationActions()
    -- clear lists for loadout rescan
    self.TempSettings.RotationAAs = Set.new({})
    self.TempSettings.RotationClickies = Set.new({})

    local aaSets = self.ClassConfig.AASets or {}
    local itemSets = self.ClassConfig.ItemSets or {}

    -- Single pass over the loaded (post-load_cond) rotation tables for both AA and Item tracking.
    -- For set entries, all set members are added so warnings/highlights cover stepping-stone ranks too.
    for _, rotationTable in ipairs({ self.TempSettings.RotationTable, self.TempSettings.HealRotationTable or {}, }) do
        for _, rotation in pairs(rotationTable) do
            for _, entry in ipairs(rotation) do
                local entryType = entry.type:lower()
                if entryType == "aa" then
                    local set = aaSets[entry.name]
                    if set then
                        for _, aaName in ipairs(set) do
                            self.TempSettings.RotationAAs:add(aaName)
                        end
                    else
                        self.TempSettings.RotationAAs:add(entry.name)
                    end
                elseif entryType == "item" and not entry.from_clicky then
                    local set = itemSets[entry.name]
                    if set then
                        for _, itemName in ipairs(set) do
                            self.TempSettings.RotationClickies:add(itemName)
                        end
                    elseif type(entry.name) == "string" then
                        self.TempSettings.RotationClickies:add(entry.name)
                    end
                end
            end
        end
    end

    -- add static spells this is hacky and it sucks but one day I will make it better. promise.
    self.TempSettings.RotationAAs:add("Radiant Cure")
    self.TempSettings.RotationAAs:add("Dire Charm")
    self.TempSettings.RotationAAs:add("Group Purify Soul")
    self.TempSettings.RotationAAs:add("Aureate's Bane")
    self.TempSettings.RotationAAs:add("Companion's Discipline")
    self.TempSettings.RotationAAs:add("Pet Discipline")
    self.TempSettings.RotationAAs:add("Beam of Slumber")
    self.TempSettings.RotationAAs:add("Dirge of the Sleepwalker")
end

function Module:GetRotationClickies()
    return self.TempSettings.RotationClickies or Set.new({})
end

function Module:GetRotationAAs()
    return self.TempSettings.RotationAAs or Set.new({})
end

function Module:GetLastCombatModeChangeTime()
    return self.TempSettings.CombatModeChangeTime
end

return Module
