-- rgmercs
-- Copyright (C) 2025 Derple (derple@ntsj.com)
-- SPDX-License-Identifier: GPL-3.0-or-later
-- This file is part of rgmercs. See the `LICENSE` file in the repository root for license terms.
-- For the full license text, see https://www.gnu.org/licenses/gpl-3.0.txt

local mq         = require('mq')
local ImGui      = require('ImGui')

-- Preload these incase any modules need them.
local PackageMan = require('mq.PackageMan')
PackageMan.Require('lsqlite3')
PackageMan.Require('luafilesystem', 'lfs')

local Config = require('utils.config')
Config:LoadSettings()

local Logger = require("utils.logger")
Logger.set_log_level(Config:GetSetting('LogLevel'))
Logger.set_log_to_file(Config:GetSetting('LogToFile'))
Logger.set_log_timestamps_to_console(Config:GetSetting('LogTimeStampsToConsole'))
Logger.set_debug_tracer_enabled(Config:GetSetting('EnableLogTracer'))
if Config:GetSetting('LogFilter') ~= "" then
    Logger.set_log_filter(Config:GetSetting('LogFilter'))
end

local Binds = require('utils.binds')
require('utils.event_handlers')

local Core        = require("utils.core")
local ClassLoader = require('utils.classloader')
local Targeting   = require("utils.targeting")
local Combat      = require("utils.combat")
local Casting     = require("utils.casting")
local Events      = require("utils.events")
local Ui          = require("utils.ui")
local Comms       = require("utils.comms")
local Movement    = require("utils.movement")
local Set         = require('mq.set')
local Globals     = require("utils.globals")

-- Initialize class-based modules
local Modules     = require("utils.modules")
Modules:load(Globals.Constants.LootModuleTypes[Config:GetSetting('LootModuleType')])

-- pass through to avoid include loop
Globals.Modules = Modules
Globals.Logger  = Logger

require('utils.datatypes')

-- ImGui Variables
local openGUI         = true
local notifyZoning    = true
Globals.CurrentState  = "Downtime"

local initPctComplete = 0
local initMsg         = "Initializing RGMercs..."

-- UI --
local SimpleUI        = require("ui.simple")
local StandardUI      = require("ui.standard")
local OptionsUI       = require("ui.options")
local ConsoleUI       = require("ui.console")
local LoaderUI        = require("ui.loader")
local HudUI           = require("ui.hud")

local function Alive()
    return mq.TLO.NearestSpawn('pc')() ~= nil
end

local function GetTheme()
    local classTheme = Modules:ExecModule("Class", "GetTheme") or {}
    local userTheme = Config:GetSetting('UserTheme') or {}

    if #classTheme == 0 or (Config:GetSetting('UserThemeOverrideClassTheme') and #userTheme > 0) then
        return userTheme
    end

    return classTheme
end

local function RGMercsGUI()
    local theme = GetTheme()
    local themeColorPop = 0
    local themeStylePop = 0

    if mq.TLO.MacroQuest.GameState() == "CHARSELECT" then
        openGUI = false
        return
    end

    ImGui.SetNextWindowSize(ImVec2(500, 600), ImGuiCond.FirstUseEver)

    if openGUI and Alive() and Config:SettingsLoaded() then
        ImGui.PushFont(ImGui.GetFont(), ImGui.GetFontSize() * (1 + (Config:GetSetting('FontScale') / 100)))
        if initPctComplete < 100 or not LoaderUI:IsDone() then
            LoaderUI:RenderLoader(initPctComplete, initMsg)
        else
            if theme ~= nil then
                for _, t in pairs(theme) do
                    if t.color then
                        local colorId = Ui.GetImGuiColorId(t.element)

                        if type(colorId) ~= 'number' then
                            colorId = tonumber(colorId) or 0
                        end

                        ImGui.PushStyleColor(colorId, t.color.r or t.color.x,
                            t.color.g or t.color.y,
                            t.color.b or t.color
                            .z, t.color.a or t.color.w)
                        themeColorPop = themeColorPop + 1
                    elseif t.value then
                        local elementId = Ui.GetImGuiStyleId(t.element)
                        if type(t.value) == 'number' then
                            ImGui.PushStyleVar(elementId, t.value)
                        else
                            ImGui.PushStyleVar(elementId, t.value.x, t.value.y)
                        end
                        themeStylePop = themeStylePop + 1
                    end
                end
            end

            local imGuiStyle = ImGui.GetStyle()

            ImGui.PushStyleVar(ImGuiStyleVar.Alpha, Config:GetMainOpacity()) -- Main window opacity.
            ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarRounding, Config:GetSetting('ScrollBarRounding'))
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, Config:GetSetting('FrameEdgeRounding'))
            local flags = bit32.bor(ImGuiWindowFlags.NoFocusOnAppearing)

            if Config:GetSetting('PopoutWindowsLockWithMain') and Config:GetSetting('MainWindowLocked') then
                flags = bit32.bor(flags, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize)
            end

            if Config:GetSetting('PopOutForceTarget') then
                local openFT, showFT = ImGui.Begin(
                    Ui.GetWindowTitle("Force Target"),
                    Config:GetSetting('PopOutForceTarget'), flags)

                if showFT then
                    Ui.RenderForceTargetList()
                end
                ImGui.End()
                if not openFT then
                    Config:SetSetting('PopOutForceTarget', false)
                    showFT = false
                end
            end
            if Config:GetSetting('PopOutMercsStatus') then
                local openMS, showMS = ImGui.Begin(Ui.GetWindowTitle("Mercs Status"),
                    Config:GetSetting('PopOutMercsStatus'), flags)

                if showMS then
                    Ui.RenderMercsStatus()
                end
                ImGui.End()
                if not openMS then
                    Config:SetSetting('PopOutMercsStatus', false)
                    showMS = false
                end
            end
            if Config:GetSetting('PopOutConsole') then
                local openConsole, showConsole = ImGui.Begin(Ui.GetWindowTitle("Debug Console"),
                    Config:GetSetting('PopOutConsole'), flags)
                if showConsole then
                    ConsoleUI:DrawConsole()
                end
                ImGui.End()
                if not openConsole then
                    Config:SetSetting('PopOutConsole', false)
                    showConsole = false
                end
            end

            Ui.RenderModulesPopped(flags)

            if Config:GetSetting("AlwaysShowMiniButton") or Globals.Minimized then
                HudUI:RenderToggleHud()
            end

            local flashingWarning = Globals.PauseMain and Targeting.GetXTHaterCount(false) > 0 and Config:GetSetting('WarnCombatPaused')

            if flashingWarning then
                if Globals.GetTimeSeconds() % 3 == 0 then
                    Comms.PopUpColor(15, 1, "RGMercs Warning: You have aggro while paused!")
                end

                ImGui.PushStyleColor(ImGuiCol.WindowBg, Globals.GetAlternatingColor(ImVec4(0.7, 0.1, 0.1, Config:GetMainOpacity()), ImVec4(0.3, 0.1, 0.1, Config:GetMainOpacity())))
            end

            if Config:GetSetting('FullUI') then
                openGUI = StandardUI:RenderMainWindow(imGuiStyle, openGUI, flags)
            else
                openGUI = SimpleUI:RenderMainWindow(imGuiStyle, openGUI, flags)
            end

            if flashingWarning then
                ImGui.PopStyleColor()
            end

            Ui.RenderAAOverlay()

            if Config:GetSetting('EnableOptionsUI') then
                local openOptionsUI = OptionsUI:RenderMainWindow(imGuiStyle, true, flags)
                if not openOptionsUI then
                    Config:SetSetting('EnableOptionsUI', false)
                end
            end

            ImGui.PopStyleVar(3)

            if themeColorPop > 0 then
                ImGui.PopStyleColor(themeColorPop)
            end
            if themeStylePop > 0 then
                ImGui.PopStyleVar(themeStylePop)
            end
        end
        ImGui.PopFont()
    end
end

mq.imgui.init('RGMercsUI', RGMercsGUI)

-- End UI --
local unloadedPlugins = {}

local function RGInit(...)
    Core.CheckPlugins({
        "MQ2Rez",
        "MQ2AdvPath",
        "MQ2MoveUtils",
        "MQ2Nav",
        "MQ2DanNet", })

    unloadedPlugins = Core.UnCheckPlugins({ "MQ2Melee", "MQ2Twist", })

    Core.CheckSpawnMasterVersion()

    initPctComplete = 0
    initMsg = "Initializing RGMercs..."
    local args = { ..., }
    -- check mini argument before loading other modules so it minimizes as soon as possible.
    if args and #args > 0 then
        Logger.log_info("Arguments passed to RGMercs: %s", table.concat(args, ", "))
        for _, v in ipairs(args) do
            if v == "mini" then
                Globals.Minimized = true
                break
            end
            if v == "paused" then
                Globals.PauseMain = true
                break
            end
        end
    end

    initPctComplete = 10
    initMsg = "Scanning for Configurations..."
    Core.ScanConfigDirs()

    if Config:GetSetting("RunSelfTestsOnStartup") then
        initPctComplete = 15
        initMsg = "Running Self Tests..."
        require('utils.unit_tests').RunAll()
    end

    initPctComplete = 20
    initMsg = "Initializing Modules..."
    -- complex objects are passed by reference so we can just use these without having to pass them back in for saving.
    Modules:ExecAll("Init")
    Globals.SubmodulesLoaded = true

    initPctComplete = 30
    initMsg = "Updating Command Handlers..."
    Config:UpdateCommandHandlers()

    initPctComplete = 40
    initMsg = "Setting Assist..."

    Combat.SetMainAssist()

    Ui.GetAssistWarningString()

    local assistString = Globals.MainAssist:len() > 0 and string.format("set to %s.", Globals.MainAssist) or string.format("unset!")

    if Config.TempSettings.AssistWarning then
        Comms.PopUp("RGMercs " .. Config.TempSettings.AssistWarning .. "\nYour assist is currently " .. assistString)
    else
        Comms.PopUp("Welcome to RGMercs!\nYour assist is currently set to %s.", Globals.MainAssist)
    end

    if Core.IAmMA() then
        Logger.log_warn("This PC has assigned itself as the MA! If this is not intentional, please check your assist setup.")
    end

    initPctComplete = 50
    initMsg = "We deleted the thing that used to be here..."

    initPctComplete = 60
    initMsg = "Setting up MQ2DanNet..."
    if mq.TLO.Plugin("MQ2DanNet")() then
        Core.DoCmd("/squelch /dnet commandecho off")
    end

    -- Don't pass this through the DoStickCmd system so our timing isn't affected.
    Core.DoCmd("/squelch /stick set breakontarget on")

    initPctComplete = 70
    initMsg = "Closing down Macro..."
    if (mq.TLO.Macro.Name() or ""):find("RGMERC") then
        Core.DoCmd("/macro end")
    end

    initMsg = "Pausing the CWTN Plugin..."
    Core.DoCmd("/squelch /docommand /%s pause on", mq.TLO.Me.Class.ShortName())

    initPctComplete = 80
    initMsg = "Clearing Cursor..."

    if mq.TLO.Cursor() and mq.TLO.Cursor.ID() > 0 then
        Logger.log_info("Sending Item(%s) on Cursor to Bag", mq.TLO.Cursor())
        Core.DoCmd("/autoinventory")
    end

    printf("\aw****************************")
    printf("\aw\awWelcome to \ag%s", Config._AppName)
    printf("\aw\awVersion \ag%s \aw(\at%s\aw)", Config._version, Config._subVersion)
    printf("\aw\awBy \ag%s", Config._author)
    printf("\aw****************************")
    -- keep these for easy editing/addition later
    printf("\agRGMercs! Where even fun has an option and a command attached.")
    printf("\awPlease visit us on the RG forums for the most recent news and updates.")
    printf("\awFAQs, Commands and Settings are searchable from the options panel!")

    -- store initial positioning data.
    initPctComplete = 90
    initMsg = "Storing Initial Positioning Data..."
    Movement:StoreLastMove()

    initPctComplete = 100
    initMsg = "Done!"

    HudUI:LoadAllOptions()
end

local function Main()
    Logger.log_verbose("Starting Main loop.")

    -- always do this and do it first
    Config:FlushDB()

    if mq.TLO.Zone.ID() ~= Globals.CurZoneId or mq.TLO.Me.Instance() ~= Globals.CurInstance then
        if notifyZoning then
            Modules:ExecAll("OnZone")
            notifyZoning = false
            Config.TempSettings.NoLevZone = false
            Globals.ForceCombatID = 0
            Globals.IgnoredTargetIDs = Set.new({})
            Globals.AutoTargetID = 0
            Globals.AutoTargetIsNamed = false
            Globals.AggroTargetID = 0
            Globals.SetForcedTargetId(0)
        end
        mq.delay(100)
        Globals.CurZoneId = mq.TLO.Zone.ID()
        Globals.CurInstance = mq.TLO.Me.Instance()
        return
    end

    Core.UpdateBuffs()

    Events.DoEvents()

    Config:ValidatePeers()

    notifyZoning = true

    if mq.TLO.Me.NumGems() ~= Casting.UseGem then
        -- sometimes this can get out of sync.
        Casting.UseGem = mq.TLO.Me.NumGems()
    end

    if Globals.PauseMain then
        mq.delay(100)
        mq.doevents()
        if Config:GetSetting('RunMovePaused') then
            Modules:ExecModule("Movement", "GiveTime")
        end
        Modules:ExecModule("Drag", "GiveTime")
        Modules:ExecModule("Debug", "GiveTime")
        Modules:ExecModule("Clickies", "ValidateClickies")
        return
    end

    if Targeting.GetXTHaterCount(true) > 0 then
        if Globals.CurrentState == "Downtime" and mq.TLO.Me.Sitting() then
            -- if switching into combat state stand up.
            mq.TLO.Me.Stand()
        end

        Globals.CurrentState = "Combat"
        if Config:GetSetting('FaceTarget') and not Targeting.FacingTarget() and mq.TLO.Target.ID() ~= mq.TLO.Me.ID() and not mq.TLO.Me.Moving() then
            Core.DoCmd("/squelch /face fast")
        end

        if Config:GetSetting('DoMed') == 3 then
            Casting.AutoMed()
        end
    else
        if Globals.CurrentState ~= "Downtime" then
            Logger.log_debug("Switching to Downtime state.")

            -- clear the cache during state transition.
            Targeting.ClearSafeTargetCache()
            Targeting.ForceBurnTargetID = 0
            Globals.LastPulledID        = 0
            Globals.AutoTargetID        = 0
            Globals.IgnoredTargetIDs    = Set.new({})
            Globals.LastBurnCheck       = false
            Modules:ExecModule("Pull", "SetLastPullOrCombatEndedTimer")
        end

        Globals.CurrentState = "Downtime"

        if Config:GetSetting('DoMed') ~= 1 then
            Casting.AutoMed()
        end
    end

    if mq.TLO.MacroQuest.GameState() ~= "INGAME" then return end

    if Globals.CurLoadedChar ~= mq.TLO.Me.DisplayName() then
        Config:LoadSettings()
        Modules:ExecAll("LoadSettings")
    end

    if Globals.CurLoadedClass ~= mq.TLO.Me.Class.ShortName() then
        ClassLoader.changeLoadedClass()
    end

    Movement:StoreLastMove()

    if mq.TLO.Me.Hovering() then Events.HandleDeath() end

    Combat.SetMainAssist()
    Ui.GetAssistWarningString()

    if not Globals.BackOffFlag then
        -- This will find a valid target and set it to : Globals.AutoTargetID
        Combat.FindBestAutoTarget(Combat.OkToEngagePreValidateId)
        -- finds the AggroTarget for a tank mode character
        if Core.IsTanking() and Config:GetSetting('TankAggroScan') then
            Combat.TankAggroScan()
        end
    end

    if Combat.OkToEngage(Globals.AutoTargetID) then
        Combat.EngageTarget(Globals.AutoTargetID)
    else
        if Globals.CurrentState == "Combat" then
            local targetId = Targeting.GetTargetID()
            local ignored = Globals.IgnoredTargetIDs:contains(targetId)                         -- don't target something in our ignore list
            local pullTarget = Config:GetSetting('DoPull') and targetId == Globals.LastPulledID -- don't clear your pull target while its traveling to you
            local assistHater = Core.IAmMA() and Targeting.IsSpawnXTHater(targetId)             -- don't clear a targeted hater as MA unless it is ignored

            if ignored or (not pullTarget and not assistHater) then
                Logger.log_debug("\ayClearing Target because we are not OkToEngage() and we are in combat!")
                Targeting.ClearTarget()
            end
        elseif mq.TLO.Me.Combat() and (Config:GetSetting('AutoAttackSafetyCheck') or not mq.TLO.Target()) then
            Logger.log_debug("\ayTurning off attack because we don't have a target or we are not OkToEngage the current target!")
            Core.DoCmd("/attack off")
        end
    end

    -- Handles state for when we're in combat
    if Globals.CurrentState == "Combat" then
        if ((Globals.GetTimeSeconds() - Globals.LastPetCmd) > 2) then
            Globals.LastPetCmd = Globals.GetTimeSeconds()
            if Config:GetSetting('DoPetCommands') and mq.TLO.Pet.ID() > 0 and Targeting.GetTargetPctHPs(Targeting.GetAutoTarget()) <= Config:GetSetting('PetEngagePct') then
                Combat.PetAttack(Globals.AutoTargetID, true)
            end
        end

        if Config:GetSetting('DoMercenary') then
            local merc = mq.TLO.Me.Mercenary

            if merc() and merc.ID() then
                if Combat.MercEngage() then
                    local class = merc.Class.ShortName():lower()
                    local stanceGroups = {
                        war = Globals.Constants.TankMercStances,
                        clr = Globals.Constants.HealerMercStances,
                        rog = Globals.Constants.MeleeMercStances,
                        wiz = Globals.Constants.CasterMercStances,
                    }
                    local stances = stanceGroups[class]
                    if stances and merc.Stance() then
                        local desiredStance = stances[Config:GetSetting("MercStance")]
                        if desiredStance then
                            if merc.Stance():lower() ~= desiredStance then
                                Core.DoCmd("/squelch /stance %s", desiredStance)
                            end
                        else
                            local fallbackStance = stances[1]
                            if merc.Stance():lower() ~= fallbackStance then
                                Core.DoCmd("/squelch /stance %s", fallbackStance)
                            end
                        end
                    end
                    Combat.MercAssist()
                else
                    if merc.Class.ShortName():lower() ~= "clr" and merc.Stance():lower() ~= "passive" then
                        Core.DoCmd("/squelch /stance passive")
                    end
                end
            end
        end
    end

    if Combat.ShouldDoCamp() then
        if Config:GetSetting('DoMercenary') and mq.TLO.Me.Mercenary.ID() and (mq.TLO.Me.Mercenary.Class.ShortName() or "none"):lower() ~= "clr" and mq.TLO.Me.Mercenary.Stance():lower() ~= "passive" then
            Core.DoCmd("/squelch /stance passive")
        end
    end

    if Globals.Constants.ModRodUse[Config:GetSetting('ModRodUse')] == "Anytime" or (Globals.Constants.ModRodUse[Config:GetSetting('ModRodUse')] == "Combat" and Globals.CurrentState == "Combat") then
        Casting.ClickModRod()
    end

    if not Combat.ValidCombatTarget(Globals.AutoTargetID) then
        Globals.AutoTargetID = 0
    end

    -- Revive our mercenary if they're dead and we're using a mercenary
    if Config:GetSetting('DoMercenary') then
        if mq.TLO.Me.Mercenary.State():lower() == "dead" then
            if mq.TLO.Window("MMGW_ManageWnd").Child("MMGW_SuspendButton").Text():lower() == "revive" then
                mq.TLO.Window("MMGW_ManageWnd").Child("MMGW_SuspendButton").LeftMouseUp()
                mq.delay(1000, function() return (mq.TLO.Me.Mercenary.State() or "dead"):lower() ~= "dead" end)
            end
        else
            if mq.TLO.Window("MMGW_ManageWnd").Child("MMGW_AssistModeCheckbox").Checked() then
                mq.TLO.Window("MMGW_ManageWnd").Child("MMGW_AssistModeCheckbox").LeftMouseUp()
            end
        end
    end

    Modules:ExecAll("GiveTime")

    mq.doevents()
    Logger.log_verbose("Completed Main loop.")
    mq.delay(10)
end

-- Global Messaging callback
---@diagnostic disable-next-line: unused-local
local script_actor = Comms.Actors.register(function(message)
    local msg = message()
    if msg.From == Comms.GetPeerName() then return end
    if msg.Script ~= Comms.ScriptName then return end

    Logger.log_verbose("\ayGot Event from(\am%s\ay) module(\at%s\ay) event(\at%s\ay)", msg.From,
        msg.Module,
        msg.Event)

    -- This is a core event so handle it here.
    if msg.Event == "Heartbeat" then
        --Logger.log_debug("Received Heartbeat from \am%s\aw: \ag%s", msg.From, Strings.TableToString(msg.Data))
        if Config:GetSetting('HeartbeatAnnounceGroup') and msg.Data.Forced then
            Comms.HandleAnnounce(
                Comms.FormatChatEvent("Heartbeat", msg.From, string.format("AutoTarget: %d, ForceTarget: %d", msg.Data.AutoTargetID, msg.Data.ForceTargetID)),
                true, false, true)
        end

        Comms.UpdatePeerHeartbeat(msg.From, msg.Data)
        return
    end

    if msg.Event == "DoCmd" then
        --Logger.log_debug("Received Heartbeat from \am%s\aw: \ag%s", msg.From, Strings.TableToString(msg.Data))
        Logger.log_debug("Received Command from \am%s\aw: \ag%s", msg.From, msg.Data.cmd or "nil")
        Core.DoCmd(msg.Data.cmd)
        return
    end

    if msg.Module == "Config" then
        if msg.Event and Config[msg.Event] then
            Config[msg.Event](Config, msg.Data)
        end
        return
    end

    -- all other handlers
    if Modules:GetModule(msg.Module) then
        Modules:ExecModule(msg.Module, msg.Event, msg.Data)
        return
    end
end)

-- Binds

mq.bind("/rglua", Binds.MainHandler)

RGInit(...)

while openGUI do
    Main()
    mq.doevents()
    mq.delay(10)
end

Core.CheckPlugins(unloadedPlugins, true)

Modules:ExecAll("Shutdown")
Config:Shutdown()
