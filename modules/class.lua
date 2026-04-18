-- Sample Basic Class Module
local mq          = require('mq')
local Combat      = require('utils.combat')
local Config      = require('utils.config')
local Globals     = require('utils.globals')
local Core        = require("utils.core")
local Modules     = require("utils.modules")
local Events      = require("utils.events")
local Movement    = require("utils.movement")
local Targeting   = require("utils.targeting")
local Rotation    = require("utils.rotation")
local Casting     = require("utils.casting")
local Ui          = require("utils.ui")
local Comms       = require("utils.comms")
local Strings     = require("utils.strings")
local Tables      = require("utils.tables")
local Logger      = require("utils.logger")
local Set         = require("mq.Set")
local ClassLoader = require('utils.classloader')
local DanNet      = require('lib.dannet.helpers')
local Icons       = require('mq.ICONS')
local Base        = require('modules.base')

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
Module.Constants.RezSearchGroup              = "pccorpse group radius 100 zradius 50"
Module.Constants.RezSearchOutOfGroup         = "pccorpse radius 100 zradius 50"

-- Track the state of rotations between frames
Module.TempSettings.CurrentRotationStateId   = 0
Module.TempSettings.CurrentRotationStateType = 0 -- 0 : Invalid, 1 : Combat, 2 : Healing
Module.TempSettings.RotationStates           = {}
Module.TempSettings.HealRotationStates       = {}
Module.TempSettings.RotationTable            = {}
Module.TempSettings.HealRotationTable        = {}
Module.TempSettings.RotationTimers           = {}
Module.TempSettings.RezTimers                = {}
Module.TempSettings.CureCheckTimer           = Globals.GetTimeSeconds() -- set this out a bit so we have time to get actor data.
Module.TempSettings.ShowFailedSpells         = false
Module.TempSettings.ResolvingActions         = true
Module.TempSettings.CombatModeSet            = false
Module.TempSettings.NewCombatMode            = false
Module.TempSettings.CombatModeChangeTime     = 0
Module.TempSettings.MissingSpells            = {}
Module.TempSettings.MissingSpellsHighestOnly = true
Module.TempSettings.CorpsesAlreadyRezzed     = {}
Module.TempSettings.QueuedAbilities          = {}
Module.TempSettings.CureCoroutines           = {}
Module.TempSettings.NeedCuresList            = {}
Module.TempSettings.NeedCuresListMutex       = false
Module.TempSettings.CureChecksStale          = false
Module.TempSettings.ImmuneTargets            = {}
Module.TempSettings.RotationClickies         = Set.new({})
Module.TempSettings.RotationAAs              = Set.new({})

Module.FAQ                                   = {
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
}

Module.CommandHandlers                       = {
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

                if not self:IsModeActive(newMode) then
                    Config:SetSetting('Mode', newModeIdx)
                    self:SetCombatMode(newMode)
                    return true
                end

                Logger.log_info("\awMode successfully set to: \am%s", newMode)

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
        about = "Resets the delay timer on buff rotations. Does not force the cast of any buff.",
        handler = function(self)
            self:ResetRotationTimer("SlowDowntime")
            self:ResetRotationTimer("GroupBuff")
            self:ResetRotationTimer("PetBuff")

            Logger.log_info("\awResetting buff rotation timers.")

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
            if not action or not action() then
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
                    self:QueueAbility("disc", action, targetId)
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

function Module:SetCombatMode(mode)
    if not Tables.TableContains(self.ClassConfig.Modes, mode) then
        Logger.log_error("\ayInvalid Mode: \am%s", mode)
        return false
    end
    Logger.log_debug("\aySettings Combat Mode to: \am%s", mode)
    self.TempSettings.ResolvingActions = true

    if self.ClassConfig then
        self.ResolvedActionMap = Rotation.ResolveActions(self.ClassConfig.ItemSets, self.ClassConfig.AbilitySets)
        self.TempSettings.ResolvingActions = false

        if self.ClassConfig.SpellList then
            self.SpellLoadOut, self.LoadOutName = Rotation.SetSpellLoadOutByPriority(self, self.ClassConfig.SpellList)
        else
            self.SpellLoadOut = Rotation.SetSpellLoadOutByGem(self, self.ClassConfig.Spells)
            self.LoadOutName = "Default"
        end
    end

    Rotation.LoadSpellLoadOut(self.SpellLoadOut)

    if self.ClassConfig.OnModeChange then
        self.ClassConfig.OnModeChange(self, mode)
    end

    self.TempSettings.MissingSpells = Rotation.FindAllMissingSpells(self.ClassConfig.AbilitySets, self.TempSettings.MissingSpellsHighestOnly)

    Modules:ExecAll("OnCombatModeChanged")
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

function Module:RenderRotationWithToggle(r, rotationTable)
    local enabledRotationEntriesChanged = false
    local rotationName = r.name
    local enabledRotations = Config:GetSetting('EnabledRotations') or {}
    local enabledRotationEntries = Config:GetSetting('EnabledRotationEntries') or {}
    local rotationDisabled = enabledRotations[r.name] == false
    local rotationIcon = rotationDisabled and Icons.MD_ERROR or (r.lastCondCheck and Icons.MD_CHECK or Icons.MD_CLOSE)
    local headerText = string.format("[%s] %s", rotationIcon, rotationName)
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
            self.TempSettings.ShowFailedSpells, enabledRotationEntries, enabledRotationEntriesChanged = Ui.RenderRotationTable(r.name,
                rotationTable[r.name],
                self.ResolvedActionMap, r.state or 0, self.TempSettings.ShowFailedSpells, enabledRotationEntries)

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
    Ui.RenderColoredText(Globals.Constants.BasicColors.LightYellow, self.CurrentRotation.state)
    ImGui.TableNextColumn()
    ImGui.EndTable()

    ---@type boolean|nil
    local pressed = false

    if self.ClassConfig and self.ModuleLoaded then
        Ui.RenderText("Active Mode:")
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
            if ImGui.SmallButton("Reload Spells") then
                self:RescanLoadout()
                Logger.log_info("\awManual loadout scan initiated.")
            end

            if Tables.GetTableSize(self.SpellLoadOut) > 0 then
                Ui.RenderLoadoutTable(self.SpellLoadOut)
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
                    self:RenderRotationWithToggle(r, self.TempSettings.RotationTable)
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
    end
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
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.IsTanking then
        return false
    end
    return self.ClassConfig.ModeChecks.IsTanking()
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
    if not self.ClassConfig or not self.ClassConfig.ModeChecks or not self.ClassConfig.ModeChecks.IsCharming then
        return false
    end
    return self.ClassConfig.ModeChecks.IsCharming()
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
                Modules:ExecModule("Clickies", "GetClickiesForRotation", rname) or {})
        end
    end

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
                Modules:ExecModule("Clickies", "GetClickiesForHealRotation", rname) or {})
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

function Module:SelfCheckAndRez(combat_state)
    if combat_state == "Downtime" then -- don't try to rez ourselves in combat
        -- we are always in zone with ourself, I would hope
        if not Config:GetSetting('RezInZonePC') then
            Logger.log_verbose("\atSelfCheckAndRez(): We are configured to only rez out-of-zone PCs, no need to check for our own corpse.")
            return
        end

        local rezSearch = string.format("pccorpse %s' radius 100 zradius 50", mq.TLO.Me.DisplayName()) -- use ' to prevent partial name matches (foo's corpse vs foobar's corpse)
        local rezCount = mq.TLO.SpawnCount(rezSearch)()

        for i = 1, rezCount do
            Logger.log_debug("\atSelfCheckAndRez(): Looking for corpse #%d", i)
            local rezSpawn = mq.TLO.NearestSpawn(i, rezSearch)

            if rezSpawn() then
                Logger.log_debug("\atSelfCheckAndRez(): Found corpse of %s :: %s", rezSpawn.CleanName() or "Unknown", rezSpawn.Name() or "Unknown")
                if self.Helpers and self.Helpers.DoRez then
                    if Config:GetSetting('ConCorpseForRez') and Tables.TableContains(Globals.RezzedCorpses, rezSpawn.ID()) then
                        Logger.log_debug("\atSelfCheckAndRez(): Found corpse of %s(ID:%d), but it appears to have been rezzed already.", rezSpawn.CleanName() or "Unknown",
                            rezSpawn.ID() or 0)
                    elseif (Globals.GetTimeSeconds() - (self.TempSettings.RezTimers[rezSpawn.ID()] or 0)) >= Config:GetSetting('RetryRezDelay') then
                        Core.SafeCallFunc("SelfCheckAndRez", self.Helpers.DoRez, self, rezSpawn.ID())
                        self.TempSettings.RezTimers[rezSpawn.ID()] = Globals.GetTimeSeconds()
                        self:ResetRotationTimer("GroupBuff")
                    end
                end
            end
        end
    else
        Logger.log_verbose("\atSelfCheckAndRez(): Combat detected, we will only rez ourselves in downtime.")
    end
end

function Module:IGCheckAndRez(combat_state)
    local rezCount = mq.TLO.SpawnCount(self.Constants.RezSearchGroup)()

    for i = 1, rezCount do
        Logger.log_debug("\atIGCheckAndRez(): Looking for corpse #%d", i)
        local rezSpawn = mq.TLO.NearestSpawn(i, self.Constants.RezSearchGroup)
        local corpseName = rezSpawn.CleanName() or "None"
        local ownerName = corpseName:gsub("'s corpse$", "")

        if rezSpawn() and ownerName ~= mq.TLO.Me.CleanName() then -- don't try to rez ourselves in the group checks
            if self.Helpers and self.Helpers.DoRez then
                Logger.log_debug("\atIGCheckAndRez(): Found corpse of %s :: %s", rezSpawn.CleanName() or "Unknown", rezSpawn.Name() or "Unknown")
                -- don't rez someone nearby during combat or any time if we have it set that way
                if (combat_state == "Combat" or not Config:GetSetting('RezInZonePC')) and mq.TLO.Spawn(string.format("PC =%s", ownerName))() then
                    Logger.log_debug("\atIGCheckAndRez(): Found corpse of %s(ID:%d), but the player appears to be in-zone.", ownerName or "Unknown",
                        rezSpawn.ID() or 0)
                elseif Config:GetSetting('ConCorpseForRez') and Tables.TableContains(Globals.RezzedCorpses, rezSpawn.ID()) then
                    Logger.log_debug("\atIGCheckAndRez(): Found corpse of %s(ID:%d), but it appears to have been rezzed already.", rezSpawn.CleanName() or "Unknown",
                        rezSpawn.ID() or 0)
                elseif (Globals.GetTimeSeconds() - (self.TempSettings.RezTimers[rezSpawn.ID()] or 0)) >= Config:GetSetting('RetryRezDelay') then
                    Logger.log_debug("\atIGCheckAndRez(): Attempting to Res: %s", rezSpawn.CleanName())
                    self.TempSettings.RezTimers[rezSpawn.ID()] = Globals.GetTimeSeconds()
                    if Core.SafeCallFunc("IGCheckAndRez", self.Helpers.DoRez, self, rezSpawn.ID(), ownerName) then
                        self:ResetRotationTimer("GroupBuff")
                        -- make sure we process other healing/etc instead of chain rezzing
                        if combat_state == "Combat" then
                            Logger.log_verbose("\atIGCheckAndRez(): Rez successful: %s. Returning to allow for heal checks before we attempt to rez the next corpse.",
                                rezSpawn.CleanName())
                            break
                        end
                    end
                end
            end
        end
    end
end

function Module:OOGCheckAndRez(combat_state)
    local rezCount = mq.TLO.SpawnCount(self.Constants.RezSearchOutOfGroup)()

    for i = 1, rezCount do
        local rezSpawn = mq.TLO.NearestSpawn(i, self.Constants.RezSearchOutOfGroup)
        local corpseName = rezSpawn.CleanName() or "None"
        local ownerName = corpseName:gsub("'s corpse$", "")

        -- don't try to rez in group, we just checked those PCs... we will check them again with IGCheckAndRez next loop.
        if rezSpawn() and not mq.TLO.Group.Member(ownerName)() and (Targeting.IsSafeName("pc", rezSpawn.DisplayName())) then
            if self.Helpers and self.Helpers.DoRez then
                -- don't rez someone nearby during combat or any time if we have it set that way
                if (combat_state == "Combat" or not Config:GetSetting('RezInZonePC')) and mq.TLO.Spawn(string.format("PC =%s", ownerName))() then
                    Logger.log_debug("\atIGCheckAndRez(): Found corpse of %s(ID:%d), but the player appears to be in-zone.", ownerName or "Unknown",
                        rezSpawn.ID() or 0)
                elseif Config:GetSetting('ConCorpseForRez') and Tables.TableContains(Globals.RezzedCorpses, rezSpawn.ID()) then
                    Logger.log_debug("\atOOGCheckAndRez(): Found corpse of %s(ID:%d), but it appears to have been rezzed already.", rezSpawn.CleanName() or "Unknown",
                        rezSpawn.ID() or 0)
                elseif (Globals.GetTimeSeconds() - (self.TempSettings.RezTimers[rezSpawn.ID()] or 0)) >= Config:GetSetting('RetryRezDelay') then
                    self.TempSettings.RezTimers[rezSpawn.ID()] = Globals.GetTimeSeconds()
                    if Core.SafeCallFunc("OOGCheckAndRez", self.Helpers.DoRez, self, rezSpawn.ID(), ownerName) then
                        self:ResetRotationTimer("GroupBuff")
                        -- make sure we process other healing/etc instead of chain rezzing
                        if combat_state == "Combat" then
                            Logger.log_verbose("\atOOGCheckAndRez(): Rez successful: %s. Returning to allow for heal checks before we attempt to rez the next corpse.",
                                rezSpawn.CleanName())
                            break
                        end
                    end
                end
            end
        end
    end
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
                    Casting.WaitGlobalCoolDown("Healing: ")

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

function Module:RunCureRotation(combat_state)
    if combat_state == "Downtime" then -- check freely in combat and the first frame of downtime; then avoid spamming
        if (Globals.GetTimeSeconds() - self.TempSettings.CureCheckTimer) < Config:GetSetting('CureInterval') then return end
        self.TempSettings.CureCheckTimer = Globals.GetTimeSeconds()
    end

    local actorPeers = Comms.GetAllPeerHeartbeats(false)

    -- if a peer is using Radiant Cure or Group Purify Soul on a group mate and we have set the option, don't bother checking for cures, let the cure process
    -- -- this may cause us to ocasionally skip curing a second group with radiant (if that group's healer is curing us for whatever reason)... this is preferred over double-tapping RC's
    if Config:GetSetting('StaggerGroupAACures') then
        for _, heartbeat in pairs(actorPeers) do
            local data = heartbeat.Data
            local casting = data and data.Casting or ""

            --nested conditions here to avoid preemptive data/spawn checks
            if casting == "Radiant Cure" or casting == "Group Purify Soul" then
                local target = data and data.Target
                local groupMate = mq.TLO.Group.Member(target)

                if groupMate and groupMate() then
                    local recentHeartbeat = (Globals.GetTimeSeconds() - (heartbeat.LastHeartbeat or 0)) <= 3

                    if recentHeartbeat then
                        Logger.log_debug("[Cures] %s is currently casting a group AA cure on my groupmate %s, bypassing cure checks.", heartbeat.Data.Name, target)
                        return
                    end
                end
            end
        end
    end

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
        local cureTargetID = cureTarget.ID() --will return 0 if the spawn doesn't exist
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
                    local cureTargetID = cureTarget.ID() --will return 0 if the spawn doesn't exist

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
    local success = false
    local queueData = self.TempSettings.QueuedAbilities[1]

    Logger.log_debug("\ao[QueuedAbilities] Processing queued %s: %s on %s", queueData.type, queueData.name, queueData.targetId)

    if queueData.type:lower() == "spell" then
        success = Casting.UseSpell(queueData.name, queueData.targetId, true)
        if not success then
            success = Casting.UseAA(queueData.name, queueData.targetId)
        end
    elseif queueData.type:lower() == "song" then
        success = Casting.UseSong(queueData.name, queueData.targetId, true)
    elseif queueData.type:lower() == "aa" then
        success = Casting.UseAA(queueData.name, queueData.targetId)
    elseif queueData.type:lower() == "item" then
        success = Casting.UseItem(queueData.name, queueData.targetId)
    elseif queueData.type:lower() == "disc" then
        success = Casting.UseDisc(queueData.name, queueData.targetId)
    end

    if not success then
        Logger.log_error("\arFailed to cast queued %s: %s on %s", queueData.type, queueData.name, queueData.targetId)
        self.TempSettings.QueuedAbilities[1].retries = (self.TempSettings.QueuedAbilities[1].retries or 0) + 1

        if self.TempSettings.QueuedAbilities[1].retries > 3 then
            Logger.log_error("\arFailed to cast queued %s: %s on %s after 3 attempts - giving up", queueData.type, queueData.name, queueData.targetId)
            table.remove(self.TempSettings.QueuedAbilities, 1)
        else
            Logger.log_info("\ayRetrying queued %s: %s on %s (%d)", queueData.type, queueData.name, queueData.targetId, self.TempSettings.QueuedAbilities[1].retries)
        end
    else
        Logger.log_info("\agSuccessfully cast queued %s: %s on %s", queueData.type, queueData.name, queueData.targetId)
        table.remove(self.TempSettings.QueuedAbilities, 1)
    end

    return #self.TempSettings.QueuedAbilities > 0
end

function Module:QueueAbility(type, name, targetId)
    Logger.log_debug("\ayQueuing %s: %s on %s", type, name, targetId)
    table.insert(self.TempSettings.QueuedAbilities, {
        name = name,
        targetId = targetId,
        target = mq.TLO.Spawn(targetId),
        type = type,
        queuedTime = Globals.GetTimeSeconds(),
    })
end

function Module:GiveTime()
    local combat_state = Combat.GetCachedCombatState()

    if not self.ClassConfig or not self.ModuleLoaded then return end
    local enabledRotations = Config:GetSetting('EnabledRotations') or {}

    local me               = mq.TLO.Me
    if me.Hovering() or me.Stunned() or me.Charmed() or me.Mezzed() or me.Feared() then
        Logger.log_super_verbose("Class GiveTime aborted, we aren't in control of ourselves. Hovering(%s) Stunned(%s) Charmed(%s) Feared(%s) Mezzed(%s)",
            Strings.BoolToColorString(me.Hovering()), Strings.BoolToColorString(me.Stunned()), Strings.BoolToColorString(me.Charmed() ~= nil),
            Strings.BoolToColorString(me.Mezzed() ~= nil), Strings.BoolToColorString(me.Feared() ~= nil))
        return
    end

    -- Main Module logic goes here.
    if (self.TempSettings.NewCombatMode and combat_state == "Downtime") or not self.TempSettings.CombatModeSet then
        Logger.log_debug("New Combat Mode Requested: %s", self.ClassConfig.Modes[Config:GetSetting('Mode')])

        self:SetCombatMode(self.ClassConfig.Modes[Config:GetSetting('Mode')])
        self:GetRotations()
        if self:IsCuring() then
            if self.ClassConfig.Cures and self.ClassConfig.Cures.GetCureSpells then
                Core.SafeCallFunc("GetCureSpells", self.ClassConfig.Cures.GetCureSpells, self)
            end
        end
        self:SetRotationClickies()
        self:SetRotationAAs()
        self.TempSettings.NewCombatMode = false
        self.TempSettings.CombatModeSet = true
        self.TempSettings.CombatModeChangeTime = Globals.GetTimeSeconds()

        -- update our peers about our new state.
        Config:BroadcastConfigs()
    end

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

    if self:IsRezing() and Config:GetSetting('DoRez') then
        -- Check Rezes
        if not (combat_state == "Downtime" and mq.TLO.Me.Invis() and not Config:GetSetting('BreakInvisForHealing')) then
            self:IGCheckAndRez(combat_state)

            self:SelfCheckAndRez(combat_state)

            if Config:GetSetting('RezOutside') then
                self:OOGCheckAndRez(combat_state)
            end

            --clear the table of corpses we've already rezzed if there are no PC corpses nearby
            if Core.OnEMU() then
                local rezCount = mq.TLO.SpawnCount("pccorpse radius 150 zradius 50")()
                if rezCount == 0 then
                    Globals.RezzedCorpses = {}
                    Globals.CorpseConned  = false
                end
            end
        end
    end

    if self:IsCuring() then
        if not (combat_state == "Downtime" and mq.TLO.Me.Invis() and not Config:GetSetting('BreakInvisForHealing')) then
            self:RunCureRotation(combat_state)

            if Module.TempSettings.NeedCuresListMutex then
                Logger.log_debug("\ay[Cures] A coroutine is currently in mutex, bypassing cure list processing.")
            else
                self:ProcessCuresList()
            end
        end

        self:DoEvents()
    end

    --Counter TOB Debuff with AA Buff, this can be refactored/expanded if they add other similar systems
    if Config:GetSetting('UseCounterActions') then
        Logger.log_verbose("\ao[CounterActions] Checking for debuffs to counter...")
        self:RunCounterRotation()
    end

    if self:IsTanking() and Config:GetSetting('MovebackWhenBehind') then
        -- make sure nothing is behind us when tanking.
        -- Maybe spawn search is failing us -- look through the xtarget list
        local xtCount = mq.TLO.Me.XTarget()

        for i = 1, xtCount do
            local xtSpawn = mq.TLO.Me.XTarget(i)
            if xtSpawn and xtSpawn.ID() > 0 and not xtSpawn.Dead() and not xtSpawn.Fleeing() and (math.ceil(xtSpawn.PctHPs() or 0)) > 0 and (xtSpawn.Aggressive() or xtSpawn.TargetType():lower() == "auto hater" or xtSpawn.ID() == Globals.ForceTargetID) and Globals.Constants.RGNotMezzedAnims:contains(xtSpawn.Animation()) and math.abs((mq.TLO.Me.Heading.Degrees() - (xtSpawn.Heading.Degrees() or 0))) < 100 then
                Logger.log_debug("\arXT(%s) is behind us! \atTaking evasive maneuvers! \awMyHeader(\am%d\aw) ThierHeading(\am%d\aw)", xtSpawn.DisplayName() or "",
                    mq.TLO.Me.Heading.Degrees(), (xtSpawn.Heading.Degrees() or 0))
                if Globals.GetTimeSeconds() - Movement:GetLastStickTimer() < 0.5 then
                    Logger.log_debug("\ayIgnoring moveback because we just stuck a second ago - let's give it some time.")
                else
                    Movement:DoStickCmd("moveback %d", Config:GetSetting('MovebackDistance'))
                    Movement:SetLastStickTimer(Globals.GetTimeSeconds())
                end
            end
        end
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
            if r.timer then -- see if we've waited the rotation timer out.
                timeCheckPassed = ((Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name]) >= r.timer)
            else            -- default to only processing Downtime rotations once per second if no timer is specified.
                timeCheckPassed = self.CombatState ~= "Downtime" and true or ((Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name]) >= 1)
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
                            self.ResolvedActionMap, r.steps or 0, r.state or 0, self.CombatState == "Downtime", r.doFullRotation or false, r.cond,
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
                    Strings.FormatTime((r.timer or 1) - (Globals.GetTimeSeconds() - self.TempSettings.RotationTimers[r.name])))
                if r.timer then r.lastCondCheck = false end --update rotation UI when rotation doesn't fire due to timer check
            end
        end
    end

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
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    local actionMap = "Action Map\n"
    actionMap = actionMap .. "-=-=-=-=-=\n"
    for k, entry in pairs(self.ResolvedActionMap) do
        local mappedAction = entry

        if mappedAction then
            if type(mappedAction) ~= "string" then
                mappedAction = mappedAction.RankName()
            end
        else
            if entry.type:lower() == "customfunc" then
                mappedAction = "cmd function"
            elseif entry.type:lower() == "spell" then
                mappedAction = "<Missing Spell>"
            elseif entry.type:lower() == "song" then
                mappedAction = "<Missing Song>"
            elseif entry.type:lower() == "ability" then
                mappedAction = entry.name
            elseif entry.type:lower() == "aa" then
                mappedAction = entry.name
            else
                mappedAction = entry.name
            end
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
        rotationStates = rotationStates ..
            string.format("[%d] %s :: %d :: Type: %s Action: %s\n", idx, r.name, r.state or 0, actionEntry.type,
                self.ResolvedActionMap[actionEntry.name] and self.ResolvedActionMap[actionEntry.name] or actionEntry
                .name)
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
    if self.ClassConfig.CommandHandlers and self.ClassConfig.CommandHandlers[cmd] then
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
    if effectSet then
        return effectSet:contains(targetId)
    end
    return false
end

function Module:SetRotationClickies()
    -- clear list for loadout rescan
    self.TempSettings.RotationClickies = Set.new({})

    -- Check rotations for clickies, either by checking items that were resolved from the maps, or checking strings for item entries without a map
    for _, rotation in pairs(self.TempSettings.RotationTable) do
        for _, entry in ipairs(rotation) do
            if entry.type:lower() == "item" and not entry.from_clicky then
                local resolvedMap = self.ResolvedActionMap[entry.name]
                if resolvedMap and mq.TLO.FindItem(string.format("=%s", resolvedMap))() then
                    self.TempSettings.RotationClickies:add(resolvedMap)
                elseif type(entry.name) == "string" and mq.TLO.FindItem(string.format("=%s", entry.name))() then
                    self.TempSettings.RotationClickies:add(entry.name)
                end
            end
        end
    end

    -- do it again for heal rotation
    for _, rotation in pairs(self.TempSettings.HealRotationTable or {}) do
        for _, entry in ipairs(rotation) do
            if entry.type:lower() == "item" and not entry.from_clicky then
                local resolvedMap = self.ResolvedActionMap[entry.name]
                if resolvedMap and mq.TLO.FindItem(string.format("=%s", resolvedMap))() then
                    self.TempSettings.RotationClickies:add(resolvedMap)
                elseif type(entry.name) == "string" and mq.TLO.FindItem(string.format("=%s", entry.Name))() then
                    self.TempSettings.RotationClickies:add(entry.name)
                end
            end
        end
    end
end

function Module:SetRotationAAs()
    self.TempSettings.RotationAAs = Set.new({})

    -- Check rotations for clickies, either by checking items that were resolved from the maps, or checking strings for item entries without a map
    for rname, rotation in pairs(self.ClassConfig.Rotations) do
        for _, entry in ipairs(rotation) do
            if entry.type:lower() == "aa" then
                self.TempSettings.RotationAAs:add(entry.name)
            end
        end
    end

    -- do it again for heal rotation
    for _, rotation in pairs(self.ClassConfig.HealRotations or {}) do
        for _, entry in ipairs(rotation) do
            if entry.type:lower() == "aa" then
                self.TempSettings.RotationAAs:add(entry.name)
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

function Module:OnTargetChange(targetId)
    Logger.log_debug("OnTargetChange(): TargetID changed to %d", targetId)
    if Core.IAmMA() then
        Events.SendHeartbeat(true)
    end
end

function Module:OnForceTargetChange(forceTargetId)
    Logger.log_debug("OnForceTargetChange(): ForceTargetID changed to %d", Globals.ForceTargetID)

    if Core.IAmMA() then
        Events.SendHeartbeat(true)
    end
end

return Module
