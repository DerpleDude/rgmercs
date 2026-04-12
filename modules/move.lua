-- Sample Basic Class Module
local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Math      = require('utils.math')
local Combat    = require('utils.combat')
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Movement  = require("utils.movement")
local Casting   = require("utils.casting")
local Ui        = require("utils.ui")
local Comms     = require("utils.comms")
local Files     = require("utils.files")
local Logger    = require("utils.logger")
local Strings   = require("utils.strings")
local Set       = require("mq.Set")
local Base      = require("modules.base")
local Icons     = require('mq.ICONS')

local Module    = { _version = '0.1a', _name = "Movement", _author = 'Derple', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })

Module.TempSettings                = {}
Module.TempSettings.CampZoneId     = 0
Module.TempSettings.LastCmd        = ""
Module.TempSettings.StuckAtTime    = 0

Module.Constants                   = {}
Module.Constants.GGHZones          = Set.new({ "poknowledge", "potranquility", "stratos", "guildlobby", "moors", "crescent", "guildhalllrg_int", "guildhall", })
Module.Constants.CampfireNameToKit = {
    ['Regular Fellowship']           = 1,
    ['Empowered Fellowship']         = 2,
    ['Empowered Barbarian']          = 3,
    ['Empowered Dark Elf']           = 4,
    ['Empowered Dwarf']              = 5,
    ['Empowered Erudite']            = 6,
    ['Empowered Gnome']              = 7,
    ['Empowered Half Elf']           = 8,
    ['Empowered Halfling']           = 9,
    ['Empowered High Elf']           = 10,
    ['Empowered Human']              = 11,
    ['Empowered Iksar']              = 12,
    ['Empowered Ogre']               = 13,
    ['Empowered Troll']              = 14,
    ['Empowered Vah Shir']           = 15,
    ['Empowered Woodelf']            = 16,
    ['Empowered Guktan']             = 17,
    ['Empowered Drakkin']            = 18,
    ['Empowered Earthen Elemental']  = 19,
    ['Empowered Aery Elemental']     = 20,
    ['Empowered Firey Elemental']    = 21,
    ['Empowered Aqueous Elemental']  = 22,
    ['Empowered Spirit Wolf']        = 23,
    ['Empowered Werewolf']           = 24,
    ['Empowered Evil Eye']           = 25,
    ['Empowered Imp']                = 26,
    ['Empowered Froglok']            = 27,
    ['Empowered Scarecrow']          = 28,
    ['Empowered Skeleton']           = 29,
    ['Empowered Drybone Skeleton']   = 30,
    ['Empowered Frostbone Skeleton'] = 31,
    ['Empowered Orc']                = 32,
    ['Empowered Goblin']             = 33,
    ['Empowered Sporali']            = 34,
    ['Empowered Fairy']              = 35,
    ['Scaled Wolf']                  = 36,
}


Module.Constants.CampfireTypes = { 'All Off', }
for t, _ in pairs(Module.Constants.CampfireNameToKit) do table.insert(Module.Constants.CampfireTypes, t) end
table.sort(Module.Constants.CampfireTypes)

Module.FAQ             = {
    {
        Question = "How do I move my PCs or have them follow my driver?",
        Answer =
            "Enable \"Chase\" on the Movement tab (or via Command-Line, refer to the command list) and adjust settings in the Following category (Movement Options) to your liking.\n" ..
            "There are two commonly used forms of following in MQ currently: \"Nav\" and \"A(dvanced)Follow\".\n\n" ..
            "Nav uses the MQ2Nav plugin to check zone geometry to move from point-to-point. This is the type of movement that RGMercs uses by default.\n\n" ..
            "Afollow, which is a feature of MQ2AdvPath, uses recording and playback of player movement to mimic the PC being followed. This is the type of nav typically seen on \"Follow Me\" buttons in the group window.\n\n" ..
            "There are times when Chase(Nav) and Afollow both have advantages, so situationally using both is common. Please note that using Afollow may interfere with RGMercs movement, meditation, or casting while it is enabled!",
        Settings_Used = "",
    },
    {
        Question = "What is a camp in RGMercs? How do I use one?",
        Answer = "Camping is setting a tether to a particular location.\n\n" ..
            "Rather than chasing/following another PC, you will continually return to the vicinity of the camp location you've set.\n\n" ..
            "This mode is mutually-exclusive with Chase, i.e, you cannot Chase and Camp at the same time.\n" ..
            "Enabling one disables the other.\n" ..
            "Camp settings can be adjusted in the Following category (Movement Options).",
        Settings_Used = "",
    },
}

Module.DefaultConfig   = {
    --Custom
    ['ReturnToCamp']                           = {
        DisplayName = "Return To Camp",
        Type = "Custom",
        Default = false,
        FAQ = "How do I set a camp?",
        Answer = "You can set a camp using a button on the Movement tab, or by using the campon command (see command list) .",
        OnChange = function(self) Movement.UpdateMapRadii() end,
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['ChaseTarget']                            = {
        DisplayName = "Chase Target",
        Type = "Custom",
        Default = "",
        FAQ = "How do I set my chase target?",
        Answer = "You can set your chase target using a button on the Movement tab, or by using the chaseon command (see command list).",
    },
    -- Chase
    ['ChaseOn']                                = {
        DisplayName = "Chase On",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 1,
        Tooltip = "Follow the Chase target using MQ2Nav. Requires navmeshes!",
        Default = false,
    },
    ['RunMovePaused']                          = {
        DisplayName = "Chase or Camp While Paused",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 2,
        Tooltip = "Continue to follow your chase target or return to camp, even if RGMercs is paused.",
        Default = true,
    },
    ['ChaseDistance']                          = {
        DisplayName = "Chase Distance",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 3,
        Tooltip = "The distance away from our chase target before we will begin to navigate to them. (This starts chase movement.)",
        Default = 25,
        Min = 5,
        Max = 100,
        Warning = function()
            if Config:GetSetting('ChaseStopDistance') > Config:GetSetting('ChaseDistance') then
                return true, "Warning: ChaseStopDistance exceeds ChaseDistance this will cause chase to fail."
            end
            return false, ""
        end,
    },
    ['ChaseStopDistance']                      = {
        DisplayName = "Chase Stop Distance",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 4,
        Tooltip = "The distance to our chase target to end navigation to them. (This ends chase movement.) High run speed may overshoot this value.",
        Default = 25,
        Min = 5,
        Max = 100,
        Warning = function()
            if Config:GetSetting('ChaseStopDistance') > Config:GetSetting('ChaseDistance') then
                return true, "Warning: ChaseStopDistance exceeds ChaseDistance this will cause chase to fail."
            end
            return false, ""
        end,
    },
    ['RequireLoS']                             = {
        DisplayName = "Require LOS",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 5,
        Tooltip = "Require Line-of-Sight to the chase target before navigation to them is ended.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['PriorityFollow']                         = {
        DisplayName = "Prioritize Follow",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 6,
        Tooltip =
        "Prioritize staying in range of the Chase Target over any other actions. This will prevent any rotations (heals, buffs, etc, to include bard songs) from being processed if we are out of range of the chase target.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['BreakOnDeath']                           = {
        DisplayName = "Break On Death",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 7,
        Tooltip = "Stop chasing after when you die.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['UseActorNav']                            = {
        DisplayName = "Use Actor Nav",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 8,
        Tooltip =
        "Use location data reported directly by RGMercs from the chase target to conduct chase checks and navigation if needed. May be useful if you notice PCs trying to chase your target to a stale location.",
        Default = false,
        ConfigType = "Advanced",
    },
    ['AttemptToFixStuck']                      = {
        DisplayName = "Attempt To Fix Stuck",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 9,
        Tooltip = "If we become stuck while chasing, attempt to fix it by toggling your height via MQ2AutoSize - requires MQ2AutoSize plugin.",
        Default = true,
        ConfigType = "Advanced",
    },
    ['AttemptToFixStuckTimer']                 = {
        DisplayName = "Stuck Fix Timer",
        Group = "Movement",
        Header = "Following",
        Category = "Chase",
        Index = 10,
        Tooltip = "The number of seconds we must be stuck before attempting to fix it.",
        Default = 5,
        Min = 1,
        Max = 600,
        ConfigType = "Advanced",
    },


    -- Camp
    ['AutoCampRadius']   = {
        DisplayName = "Camp Radius",
        Group = "Movement",
        Header = "Following",
        Category = "Camp",
        Index = 1,
        Tooltip = "The distance to allow from camp before you return to it. During combat, we relax this distance slightly.",
        Default = 100,
        Min = 10,
        Max = 300,
        Warning = function()
            if Config:GetSetting('AssistRange') > Config:GetSetting('AutoCampRadius') then
                return true, "Warning: AssistRange exceeds AutoCampRadius - this might cause your characters to run out of camp to assist."
            end
            return false, ""
        end,
        OnChange = function(self) Movement.UpdateMapRadii() end,
    },
    ['CampHard']         = {
        DisplayName = "Camp Hard",
        Group = "Movement",
        Header = "Following",
        Category = "Camp",
        Index = 2,
        Tooltip = "Return to the exact camp location whenever possible, even if we are within the Camp Radius.",
        Default = false,
    },
    ['MaintainCampfire'] = {
        DisplayName = "Maintain Campfire",
        Group = "Movement",
        Header = "Following",
        Category = "Camp",
        Index = 3,
        Tooltip = "Official Servers: Maintain the selected Fellowship Campfire.",
        Type = "Combo",
        ComboOptions = Module.Constants.CampfireTypes,
        Default = 1,
        Min = 1,
        Max = #Module.Constants.CampfireTypes,
    },
    ['DoFellow']         = {
        DisplayName = "Enable Fellowship Insignia",
        Group = "Movement",
        Header = "Following",
        Category = "Camp",
        Index = 4,
        Tooltip = "Official Servers: Use your fellowship insignia to automatically return to the zone you were camped in after death.",
        Default = false,
        ConfigType = "Advanced",
    },
}

Module.CommandHandlers = {
    chaseon = {
        usage = "/rgl chaseon <name?>",
        about = "Chase <name>. If no name is supplied, it will fall back in order: (Last Used Chase Target > Main Assist). Clears your camp.",
        handler = function(self, params)
            self:ChaseOn(params)
        end,
    },
    chaseoff = {
        usage = "/rgl chaseoff",
        about = "Stop chasing your current chase target.",
        handler = function(self, _)
            self:ChaseOff()
        end,
    },
    campon = {
        usage = "/rgl campon",
        about = "Set a camp here. Disables Chase.",
        handler = function(self, _)
            self:CampOn()
        end,
    },
    campoff = {
        usage = "/rgl campoff",
        about = "Clear your current camp.",
        handler = function(self, _)
            self:CampOff()
        end,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:ChaseOn(nameParam)
    local currentChase = Config:GetSetting('ChaseTarget')

    -- if no name passed, use current chase target
    local targetName = nameParam or (currentChase ~= "" and currentChase)

    -- if we end up chasing our tails then use the MA.
    if targetName == mq.TLO.Me.CleanName() then
        Logger.log_warn("\ayWarning: Attempting to chase yourself, defaulting to Main Assist.")
        targetName = Core.GetGroupMainAssistName()
    end

    -- if no current chase target, use MA
    local chaseTarget = targetName and mq.TLO.Spawn("pc =" .. targetName) or Core.GetMainAssistSpawn()

    if chaseTarget and chaseTarget() and chaseTarget.ID() > 0 then
        self:CampOff()
        Config:SetSetting('ChaseOn', true)
        Config:SetSetting('ChaseTarget', chaseTarget.CleanName())
        Logger.log_info("\aoNow Chasing \ag%s", chaseTarget.CleanName())
    else
        Logger.log_warn("\ayWarning:\ax No valid chase target!")
    end
end

function Module:RunCmd(cmd, ...)
    local formattedCmd = cmd

    if ... ~= nil then
        formattedCmd = string.format(cmd, ...)
    end

    self.TempSettings.LastCmd = formattedCmd
    Core.DoCmd(formattedCmd)
end

function Module:ChaseOff()
    if Config:GetSetting('ChaseOn') == false then return end
    Logger.log_info("\ayNo longer chasing \at%s\ay.", Config:GetSetting('ChaseTarget') or "None")
    Config:SetSetting('ChaseOn', false)
    Config:SetSetting('ChaseTarget', "")
    Movement:DoNav(true, "stop")
    self:SaveSettings(false)
end

function Module:CampOn()
    self:ChaseOff()
    Config:SetSetting('ReturnToCamp', true)
    self.TempSettings.AutoCampX  = mq.TLO.Me.X()
    self.TempSettings.AutoCampY  = mq.TLO.Me.Y()
    self.TempSettings.AutoCampZ  = mq.TLO.Me.Z()
    self.TempSettings.CampZoneId = mq.TLO.Zone.ID()
    Logger.log_info("\ayCamping On: (X: \at%d\ay ; Y: \at%d\ay)", self.TempSettings.AutoCampX, self.TempSettings.AutoCampY)
end

---@return table # camp settings table
function Module:GetCampData()
    return { returnToCamp = (Config:GetSetting('ReturnToCamp') and self.TempSettings.CampZoneId == mq.TLO.Zone.ID()), campSettings = self.TempSettings, }
end

---@return boolean
function Module:InCampZone()
    return self.TempSettings.CampZoneId == mq.TLO.Zone.ID()
end

function Module:CampOff()
    Config:SetSetting('ReturnToCamp', false)
    self:SaveSettings(false)
end

function Module:DestoryCampfire()
    if mq.TLO.Me.Fellowship.Campfire() == nil then return end
    Logger.log_debug("DestoryCampfire()")

    mq.TLO.Window("FellowshipWnd").DoOpen()
    mq.delay("3s", function() return mq.TLO.Window("FellowshipWnd").Open() == true end)
    mq.TLO.Window("FellowshipWnd").Child("FP_Subwindows").SetCurrentTab(2)

    if mq.TLO.Me.Fellowship.Campfire() then
        mq.TLO.Window("FellowshipWnd").Child("FP_DestroyCampsite").LeftMouseUp()
        mq.delay("5s", function() return mq.TLO.Window("ConfirmationDialogBox").Open() == true end)

        if mq.TLO.Window("ConfirmationDialogBox").Open() == true then
            mq.TLO.Window("ConfirmationDialogBox").Child("Yes_Button").LeftMouseUp()
        end

        mq.delay("5s", function() return mq.TLO.Me.Fellowship.Campfire() == nil end)
    end
    mq.TLO.Window("FellowshipWnd").DoClose()
end

function Module:GetCampfireTypeName()
    return self.DefaultConfig.MaintainCampfire.ComboOptions[Config:GetSetting('MaintainCampfire')]
end

function Module:GetCampfireTypeID()
    return self.Constants.CampfireNameToKit[self:GetCampfireTypeName()] or 0
end

function Module:Campfire(camptype)
    if camptype == -1 then
        self:DestoryCampfire()
        return
    end

    if mq.TLO.Zone.ID() == 33506 then return end

    if mq.TLO.Me.Fellowship.ID() == 0 or mq.TLO.Me.Fellowship.Campfire() then
        Logger.log_super_verbose("\arNot in a fellowship or already have a campfire -- not putting one down.")
        return
    end

    if Config:GetSetting('MaintainCampfire') > 2 then
        if mq.TLO.FindItemCount("Fellowship Campfire Materials")() == 0 then
            Config:SetSetting('MaintainCampfire', 36) -- Regular Fellowship
            self:SaveSettings(false)
            Logger.log_info("Fellowship Campfire Materials Not Found. Setting to Regular Fellowship.")
        end
    end

    local spawnCount  = mq.TLO.SpawnCount("PC radius 100")()
    local fellowCount = 0

    for i = 1, spawnCount do
        local spawn = mq.TLO.NearestSpawn(i, "PC radius 100")

        if spawn() and mq.TLO.Me.Fellowship.Member(spawn.CleanName()) then
            fellowCount = fellowCount + 1
        end
    end

    if fellowCount >= 3 then
        mq.TLO.Window("FellowshipWnd").DoOpen()
        mq.delay("3s", function() return mq.TLO.Window("FellowshipWnd").Open() == true end)
        mq.TLO.Window("FellowshipWnd").Child("FP_Subwindows").SetCurrentTab(2)

        if mq.TLO.Me.Fellowship.Campfire() then
            if mq.TLO.Zone.ID() ~= mq.TLO.Me.Fellowship.CampfireZone.ID() then
                mq.TLO.Window("FellowshipWnd").Child("FP_DestroyCampsite").LeftMouseUp()
                mq.delay("5s", function() return mq.TLO.Window("ConfirmationDialogBox").Open() == true end)

                if mq.TLO.Window("ConfirmationDialogBox").Open() == true then
                    mq.TLO.Window("ConfirmationDialogBox").Child("Yes_Button").LeftMouseUp()
                end

                mq.delay("5s", function() return mq.TLO.Me.Fellowship.Campfire() == nil end)
            end
        end

        Logger.log_debug("\atFellowship Campfire Type Selected: %s (%d)", camptype and "Override" or self:GetCampfireTypeName(), camptype or self:GetCampfireTypeID())
        mq.TLO.Window("FellowshipWnd").Child("FP_RefreshList").LeftMouseUp()
        mq.delay("1s")
        mq.TLO.Window("FellowshipWnd").Child("FP_CampsiteKitList").Select(camptype or self:GetCampfireTypeID())
        mq.delay("1s")
        mq.TLO.Window("FellowshipWnd").Child("FP_CreateCampsite").LeftMouseUp()
        mq.delay("5s", function() return mq.TLO.Me.Fellowship.Campfire() ~= nil end)
        mq.TLO.Window("FellowshipWnd").DoClose()
        mq.delay("2s", function() return (mq.TLO.Me.Fellowship.CampfireZone.ID() or 0) == mq.TLO.Zone.ID() end)

        Logger.log_info("\agCampfire Dropped")
    else
        Logger.log_info("\ayCan't create campfire. Only %d nearby. Setting MaintainCampfire to 0.", fellowCount)
        Config:SetSetting('MaintainCampfire', 1) -- off
    end
end

function Module:ValidChaseTarget()
    local chaseTarget = Config:GetSetting('ChaseTarget')
    return ((chaseTarget or ""):len() > 0) and chaseTarget ~= mq.TLO.Me.CleanName()
end

function Module:GetChaseTarget()
    return Config:GetSetting('ChaseTarget'):len() > 0 and Config:GetSetting('ChaseTarget') or "None"
end

function Module:ShouldRender()
    return true
end

function Module:Render()
    Base.Render(self)

    if self.ModuleLoaded and Globals.SubmodulesLoaded then
        local chaseSpawn = mq.TLO.Spawn("pc =" .. self:GetChaseTarget())
        local chaseDist = Config:GetSetting('ChaseDistance')
        local chaseStopDist = Config:GetSetting('ChaseStopDistance')
        local requireLOS = Config:GetSetting('RequireLoS')
        local chaseSpawnDist = chaseSpawn() and (chaseSpawn.Distance() or 999) or 999

        ImGui.BeginTable("##MoveInfoTable", 2, bit32.bor(ImGuiTableFlags.BordersInner, ImGuiTableFlags.SizingFixedFit))
        ImGui.TableNextColumn()
        Ui.RenderText("Chase Distance")
        ImGui.TableNextColumn()
        if not chaseSpawn() or chaseSpawn.ID() == 0 then
            Ui.RenderColoredText(Globals.Constants.BasicColors.Grey, "N/A")
        else
            Ui.RenderColoredText(chaseDist > chaseSpawnDist and Globals.Constants.BasicColors.Green or Globals.Constants.BasicColors.Red, "%d", chaseDist)
        end
        ImGui.TableNextColumn()
        Ui.RenderText("Chase Stop Distance")
        ImGui.TableNextColumn()
        if not chaseSpawn() or chaseSpawn.ID() == 0 then
            Ui.RenderColoredText(Globals.Constants.BasicColors.Grey, "N/A")
        else
            Ui.RenderColoredText(chaseStopDist < chaseSpawnDist and Globals.Constants.BasicColors.Green or Globals.Constants.BasicColors.Red, "%d", chaseStopDist)
        end
        ImGui.TableNextColumn()
        Ui.RenderText("Chase LOS Required")
        ImGui.TableNextColumn()
        Ui.RenderColoredText(requireLOS and Globals.Constants.BasicColors.Green or Globals.Constants.BasicColors.Red, requireLOS and "Yes" or "No")
        ImGui.TableNextColumn()
        Ui.RenderText("Last Movement Command")
        ImGui.TableNextColumn()
        Ui.RenderText(self.TempSettings.LastCmd)
        ImGui.EndTable()

        ImGui.Separator()

        local chaseOn = Config:GetSetting('ChaseOn')
        if ImGui.Button(chaseOn and "Turn Chase Off" or "Turn Chase On", ImGui.GetWindowWidth() * .3, 25) then
            if chaseOn then
                self:ChaseOff()
            else
                self:ChaseOn()
            end
        end
        Ui.Tooltip(
            "If Chase is enabled without a valid chase target, your Main Assist will be used.\nFind more information about Chasing by checking the Command List or FAQs in the Options Window.")

        ImGui.SameLine()

        local buttonDisabled = mq.TLO.Target() == nil or mq.TLO.Target.Type() ~= "PC"
        ImGui.BeginDisabled(buttonDisabled)
        local chaseTargetText = buttonDisabled and "Select a PC to Chase" or string.format("Set %s as Chase Target", mq.TLO.Target.DisplayName() or "Error")
        if ImGui.Button(chaseTargetText, ImGui.GetWindowWidth() * .3, 25) then
            Config:SetSetting("ChaseTarget", mq.TLO.Target.DisplayName() or "Error")
        end
        ImGui.EndDisabled()



        local haveChaseTarget = self:ValidChaseTarget() and chaseSpawn() and chaseSpawn.ID() > 0

        if ImGui.BeginTable("ChaseInfoTable", 2, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableNextColumn()
            Ui.RenderText("Chase Target")
            ImGui.TableNextColumn()
            Ui.RenderText(self:GetChaseTarget())
            ImGui.TableNextColumn()
            Ui.RenderText("Distance")
            ImGui.TableNextColumn()
            Ui.RenderText("%d", haveChaseTarget and chaseSpawn.Distance() or 0)
            ImGui.TableNextColumn()
            Ui.RenderText("ID")
            ImGui.TableNextColumn()
            Ui.RenderText("%d", haveChaseTarget and chaseSpawn.ID() or 0)
            ImGui.TableNextColumn()
            Ui.RenderText("Line of Sight")
            ImGui.TableNextColumn()
            if chaseSpawn.LineOfSight() then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
            else
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
            end
            Ui.RenderText(haveChaseTarget and (chaseSpawn.LineOfSight() and Icons.FA_EYE or Icons.FA_EYE_SLASH) or "N/A")
            ImGui.PopStyleColor(1)
            ImGui.TableNextColumn()
            Ui.RenderText("Loc")
            ImGui.TableNextColumn()
            Ui.NavEnabledLoc(haveChaseTarget and chaseSpawn.LocYXZ() or "0,0,0")
            ImGui.EndTable()
        end

        ImGui.Separator()

        if Config:GetSetting('ReturnToCamp') then
            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImGui.GetStyle().FramePadding.x, 0)
            if ImGui.Button("Break Camp", ImGui.GetWindowWidth() * .3, 25) then
                self:CampOff()
            end
            ImGui.PopStyleVar(1)
        else
            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImGui.GetStyle().FramePadding.x, 0)
            if ImGui.Button("Set New Camp Here", ImGui.GetWindowWidth() * .3, 25) then
                self:CampOn()
            end
            ImGui.PopStyleVar(1)
        end
        Ui.Tooltip("Find more information about Camping by checking the Command List or FAQs in the Options Window.")

        local me = mq.TLO.Me
        local distanceToCamp = Math.GetDistance(me.Y(), me.X(), self.TempSettings.AutoCampY or 0, self.TempSettings.AutoCampX or 0)
        if ImGui.BeginTable("CampInfoTable", 2, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableNextColumn()
            Ui.RenderText("Camp Set")

            ImGui.TableNextColumn()
            if Config:GetSetting('ReturnToCamp') then
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
                Ui.RenderText(Icons.FA_FREE_CODE_CAMP)
            else
                ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
                Ui.RenderText(Icons.MD_NOT_INTERESTED)
            end
            ImGui.PopStyleColor(1)

            ImGui.TableNextColumn()
            Ui.RenderText("Camp Location")
            ImGui.TableNextColumn()
            Ui.NavEnabledLoc(string.format("%d,%d,%d", self.TempSettings.AutoCampY or 0, self.TempSettings.AutoCampX or 0, self.TempSettings.AutoCampZ or 0))
            ImGui.TableNextColumn()
            Ui.RenderText("Distance to Camp")
            ImGui.TableNextColumn()
            Ui.RenderText("%d", self.TempSettings.CampZoneId == mq.TLO.Zone.ID() and distanceToCamp or 0)
            ImGui.TableNextColumn()
            Ui.RenderText("Camp Radius")
            ImGui.TableNextColumn()
            Ui.RenderText("%d", self.TempSettings.CampZoneId == mq.TLO.Zone.ID() and Config:GetSetting("AutoCampRadius") or 0)
            ImGui.EndTable()
        end
    end
end

function Module:OnDeath()
    if not Config:GetSetting('BreakOnDeath') then return end
    if Config:GetSetting('ChaseTarget') then
        Logger.log_info("\awNOTICE:\ax You're dead. I'm not chasing %s anymore.", Config:GetSetting('ChaseTarget'))
    end
    Config:SetSetting('ChaseOn', false)
    Config:SetSetting('ChaseTarget', "")
end

function Module:ShouldFollow()
    return not mq.TLO.MoveTo.Moving() and (not mq.TLO.Me.Casting() or Core.MyClassIs("brd"))
end

function Module:OnZone()
    self:CampOff()
end

function Module:DoAutoCampCheck(bCalledFromInsideEvent)
    Combat.AutoCampCheck(self.TempSettings, bCalledFromInsideEvent)
end

function Module:DoCombatCampCheck()
    Combat.CombatCampCheck(self.TempSettings)
end

function Module:GiveTime()
    if mq.TLO.Me.Hovering() and Config:GetSetting('ChaseOn') then
        if Config:GetSetting('BreakOnDeath') then
            Logger.log_warn("\awNOTICE:\ax You're dead. I'm not chasing \am%s\ax anymore.",
                Config:GetSetting('ChaseTarget'))
            Config:SetSetting('ChaseOn', false)
            self:SaveSettings()
        end
        return
    end

    if Globals.PauseMain and not Config:GetSetting('RunMovePaused') then
        return
    end

    self:CheckStuck()

    if not self:InCampZone() and Config:GetSetting("ReturnToCamp") then
        Config:SetSetting("ReturnToCamp", false)
    end

    local combat_state = Combat.GetCachedCombatState()

    if combat_state == "Downtime" then
        if Casting.ShouldShrink() then
            Casting.UseItem(Config:GetSetting('ShrinkItem'), mq.TLO.Me.ID())
        end

        if Casting.ShouldShrinkPet() then
            Casting.UseItem(Config:GetSetting('ShrinkPetItem'), mq.TLO.Me.Pet.ID())
        end

        if Config.ShouldMount() then
            Logger.log_debug("\ayMounting...")
            Casting.UseItem(Config:GetSetting('MountItem'), mq.TLO.Me.ID())
        end

        if Config.ShouldDismount() then
            Logger.log_debug("\ayDismounting...")
            self:RunCmd("/dismount")
        end
    end

    if Combat.ShouldDoCamp() then
        self:DoAutoCampCheck()
    end

    if (Core.IsTanking() and Config:GetSetting('MovebackWhenBehind')) and Targeting.IHaveAggro(100) then
        self:DoCombatCampCheck()
    end

    if Config:GetSetting('MaintainCampfire') > 1 and Casting.OkayToBuff() then
        if not mq.TLO.Me.Fellowship.CampfireZone() and self:InCampZone() then
            --Logger.log_debug("Doing campfire maintainance")
            self:Campfire()
        end
    else
        --Logger.log_debug("Skipping Campfire Checks")
    end

    if not self:ShouldFollow() then
        Logger.log_super_verbose("ShouldFollow() check failed.")
        return
    end

    if Config:GetSetting('ChaseOn') and not self:ValidChaseTarget() then
        Config:SetSetting('ChaseOn', false)
        Logger.log_warn("\awNOTICE:\ax \ayChase Target is invalid. Turning Chase Off!")
    end

    if Config:GetSetting('ChaseOn') and Config:GetSetting('ChaseTarget') then
        local chaseTarg = Config:GetSetting('ChaseTarget')
        local chaseSpawn = mq.TLO.Spawn("pc =" .. chaseTarg)
        local chaseId = chaseSpawn.ID()

        if not chaseSpawn or chaseSpawn.Dead() or chaseId == 0 then
            Logger.log_verbose("\awNOTICE:\ax Chase Target \am%s\ax is dead or not found in zone.", chaseTarg)
            return
        end

        if mq.TLO.Me.Dead() then return end

        -- determine if chase is needed
        local chaseDist = Config:GetSetting('ChaseDistance')
        local stopDist = Config:GetSetting('ChaseStopDistance')
        local chaseSpawnDist = chaseSpawn.Distance() or 0
        local navPathString = string.format("id %d", chaseId)
        local useLocNav = false

        if Config:GetSetting('UseActorNav') then
            local heartbeat = Comms.GetPeerHeartbeatByName(chaseTarg)
            local data = heartbeat and heartbeat.Data
            if data and data.Zone == mq.TLO.Zone.Name() and data.X and data.Y and data.Z then
                local peerLoc = string.format("%d, %d, %d", data.Y, data.X, data.Z)
                chaseSpawnDist = math.floor(mq.TLO.Math.Distance(peerLoc)()) -- math.distance returns 0 on invalid string
                -- Algar note: Emu server code seems to give constant updates up to 300, and periodic updates up to 600. Over 600, stops updating. Tested on EQMight 11/2025
                if chaseSpawnDist > 300 then
                    useLocNav = true
                    navPathString = string.format("loc %d %d %d", data.Y, data.X, data.Z)
                end
            else
                Logger.log_verbose("\awNOTICE:\ax Chase Target \am%s\ax has no valid actor data, falling back to spawn checks.", chaseTarg)
            end
        end

        -- Use MQ2Nav to navigate if able:
        -- -- If we are using actor nav, and the chase target is far enough away, nav to the loc, as spawn checks aren't reliable
        -- -- Otherwise, if the mesh is loaded, we will nav to the spawn to take advantage of MQ2Nav spawn tracking, and fallback to a moveto if no path exists
        -- -- Finally, if there is no mesh loaded, we will fall back on afollow if the target is close enough
        if chaseSpawnDist > chaseDist then
            --recheck valid spawn because they could have zoned
            if not chaseSpawn() or chaseSpawn.ID() == 0 then
                Logger.log_verbose("\awNOTICE:\ax Chase Target \am%s\ax is dead or not found in zone.", chaseTarg)
                return
            end

            local Nav = mq.TLO.Navigation
            if Nav.MeshLoaded() then
                if not Nav.Active() or useLocNav then -- if naving to a location, update that to the most recent location in case the target is moving
                    local requireLoS = Config:GetSetting('RequireLoS') and "on" or "off"

                    if Nav.PathExists(navPathString)() then
                        Logger.log_verbose("\awNOTICE:\ax Chase Target %s is out of range - naving", chaseTarg)
                        Movement:DoNav(true, "%s log=critical dist=%d lineofsight=%s", navPathString, stopDist, requireLoS)
                        mq.delay("1s", function() return mq.TLO.Navigation.Active() end)
                    else
                        -- Assuming no line of site problems.
                        Logger.log_verbose("\awNOTICE:\ax Chase Target %s Has no nav path, trying /moveto", chaseTarg)
                        self:RunCmd("/squelch /moveto id %d uw mdist %d", chaseId, Config:GetSetting('ChaseDistance'))
                    end
                end
            elseif chaseSpawnDist < 400 then -- Algarnote I left this alone, legacy code, not sure if this value is signifigant or arbitrary
                Logger.log_warning("\awWARNING:\ax Chase Target %s but no nav mesh - using afollow instead", chaseTarg)
                self:RunCmd("/squelch /afollow spawn %d", chaseId)
                self:RunCmd("/squelch /afollow %d", chaseDist)

                mq.delay("2s")

                if (chaseSpawn.Distance() or 0) < stopDist then
                    self:RunCmd("/squelch /afollow off")
                end
            end
        end
    end
end

function Module:IAmStuck()
    Movement:StoreLastMove()
    local Nav = mq.TLO.Navigation
    local stuck = Nav.Active() and not Nav.Paused() and Movement:GetSecondsSinceLastNav() >= Config:GetSetting('AttemptToFixStuckTimer') and
        (
            (Nav.Velocity() == 0) or
            (Movement:GetTimeSinceLastPositionChange() >= Config:GetSetting('AttemptToFixStuckTimer'))
        )

    if stuck then
        Logger.log_debug(
            "\ayIAmStuck\aw(): \atStuck\aw: %s, \atNav.Active()\aw: %s, \atNav.Paused()\aw: %s,\amNav.Velocity()\aw: \ao%d\aw, \amTimeSinceLastPositionChange()\aw: \ao%d\aw, \amAttemptToFixStuckTimer()\aw: \ao%d\aw, \amLastNavCmdTime\aw: \ao%s, \amLastNavCmd\aw: \at%s",
            Strings.BoolToColorString(stuck), Strings.BoolToColorString(Nav.Active()), Strings.BoolToColorString(Nav.Paused()), Nav.Velocity(),
            Movement:GetTimeSinceLastPositionChange(),
            Config:GetSetting('AttemptToFixStuckTimer'),
            Movement:GetTimeSinceLastNav(), Movement:GetLastNavCmd())
    else
        Logger.log_verbose(
            "\ayIAmStuck\aw(): \atStuck\aw: %s, \atNav.Active()\aw: %s, \atNav.Paused()\aw: %s, \amNav.Velocity()\aw: \ao%d\aw, \amTimeSinceLastPositionChange()\aw: \ao%d\aw, \amAttemptToFixStuckTimer()\aw: \ao%d\aw, \amLastNavCmdTime\aw: \ao%s, \amLastNavCmd\aw: \at%s",
            Strings.BoolToColorString(stuck), Strings.BoolToColorString(Nav.Active()), Strings.BoolToColorString(Nav.Paused()), Nav.Velocity(),
            Movement:GetTimeSinceLastPositionChange(),
            Config:GetSetting('AttemptToFixStuckTimer'),
            Movement:GetTimeSinceLastNav(), Movement:GetLastNavCmd())
    end

    return stuck
end

function Module:CheckStuck()
    local Nav = mq.TLO.Navigation

    if not Nav.Active() then
        Module.TempSettings.StuckAtTime = 0 -- not stuck
        return
    end

    -- are we stuck?
    if not self:IAmStuck() then
        Module.TempSettings.StuckAtTime = 0 -- not stuck
        return
    end

    if Config:GetSetting('AttemptToFixStuck') and self:IAmStuck() then
        if Module.TempSettings.StuckAtTime == 0 then
            Module.TempSettings.StuckAtTime = Globals.GetTimeSeconds()
        end

        if ((Globals.GetTimeSeconds() - Module.TempSettings.StuckAtTime) >= Config:GetSetting('AttemptToFixStuckTimer')) or Movement:GetTimeSinceLastPositionChange() >= Config:GetSetting('AttemptToFixStuckTimer') then
            Logger.log_warning("\awWARNING:\ax Navigation appears to be stuck")
            -- is autosize loaded?
            ---@diagnostic disable-next-line: undefined-field
            if mq.TLO.Plugin("MQ2AutoSize").IsLoaded() and mq.TLO.AutoSize ~= nil then
                Logger.log_warning("\awWARNING:\ax Attempting to unstick via MQ2AutoSize")
                ---@diagnostic disable-next-line: undefined-field
                local startingSize = mq.TLO.AutoSize.SizeSelf()
                ---@diagnostic disable-next-line: undefined-field
                local startingToggleEnabled = mq.TLO.AutoSize.Enabled()
                ---@diagnostic disable-next-line: undefined-field
                local startingToggleSelf = mq.TLO.AutoSize.ResizeSelf()

                if not startingToggleEnabled then
                    Logger.log_warning("\awWARNING:\ax Enabling AutoSize to unstick")
                    Core.DoCmd("/squelch /autosize on")
                end

                if not startingToggleSelf then
                    Logger.log_warning("\awWARNING:\ax Enabling AutoSize Self to unstick")
                    Core.DoCmd("/squelch /autosize self on")
                end

                local cycleSizes = { startingSize * 2, 1, startingSize * 1.5, 1, startingSize * 3, 1, }
                for _, size in ipairs(cycleSizes) do
                    Logger.log_warning("\awWARNING:\ax Setting size to %d to unstick", size)
                    Core.DoCmd("/squelch /autosize sizeself %d", size)

                    mq.delay("2s", function()
                        return not self:IAmStuck()
                    end)

                    if not self:IAmStuck() then
                        Logger.log_warning("\agUnstuck successful!\ax Resuming Navigation.")
                        break
                    end
                end
                Core.DoCmd("/squelch /autosize sizeself %d", startingSize) -- ensure we end back at starting size
                if not startingToggleSelf then
                    Core.DoCmd("/squelch /autosize self off")
                end
                if not startingToggleEnabled then
                    Core.DoCmd("/squelch /autosize off")
                end
                Module.TempSettings.StuckAtTime = 0
            else
                Logger.log_warning("\awWARNING:\ax MQ2AutoSize not loaded, cannot unstuck.")
            end
        end
    end
end

return Module
