--[[
    heartbeat.lua - Standalone RGMercs heartbeat sender / status viewer.

    Usage:
        /lua run rgmercs/heartbeat directed  -- sends heartbeats only
        /lua run rgmercs/heartbeat           -- sends + receives + renders MercsStatus popout

    In sender-only mode, this script publishes a minimal RGMercs heartbeat
    payload once per second so other peers running rgmercs can see this
    character in their MercsStatus panel.

    In standalone mode, it additionally registers an actor handler to
    receive other peers' heartbeats and renders the same MercsStatus
    table rgmercs itself uses, in a popout ImGui window.
]]

local mq           = require('mq')
local ImGui        = require('ImGui')

local args         = { ..., }
local isStandalone = (args[1] or ""):lower() ~= "directed"

local Config       = require('utils.config')
Config:LoadSettings()

local Logger = require('utils.logger')
Logger.set_log_level(Config:GetSetting('LogLevel') or 3)
Logger.set_log_to_file(Config:GetSetting('LogToFile') or false)

local Comms     = require('utils.comms')
local Core      = require('utils.core')
local Globals   = require('utils.globals')
local Ui        = require('utils.ui')

Globals.Logger  = Logger
Globals.Comms   = Comms
Globals.Config  = Config

local terminate = false
mq.bind('/heartbeat', function(cmd)
    if (cmd or ""):lower() == "stop" or (cmd or ""):lower() == "quit" then
        terminate = true
    end
end)

local openGUI = isStandalone

local function MercHeartbeatUI()
    if not isStandalone then return end
    if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then return end
    if not openGUI then return end
    ImGui.SetNextWindowSize(ImVec2(1200, 400), ImGuiCond.FirstUseEver)
    local display = ImGui.GetIO().DisplaySize
    ImGui.SetNextWindowPos(ImVec2(display.x * 0.5 - 600, display.y * 0.5 - 200), ImGuiCond.FirstUseEver)
    local showUI = true
    openGUI, showUI = ImGui.Begin("Mercs Status (Heartbeat)###MercsHeartbeatStandalone", openGUI)
    if showUI then
        Ui.RenderMercsStatus()
    end
    ImGui.End()
end
mq.imgui.init('HeartbeatMercsStatus', MercHeartbeatUI)

Logger.log_info("heartbeat.lua: type \ag/heartbeat stop\ax to exit.")

-- Receive handler: log inbound heartbeats into Comms.PeersHeartbeats.
---@diagnostic disable-next-line: unused-local
local script_actor = Comms.Actors.register('RGMercs-Heartbeat', function(message)
    local msg = message()
    if not msg or msg.Script ~= Comms.ScriptName then
        return
    end
    if msg.Event == "Heartbeat" then
        Comms.UpdatePeerHeartbeat(msg.From, msg.Data)
    end
end)

while mq.TLO.MacroQuest.GameState() == 'INGAME' and not terminate do
    mq.doevents()

    Core.UpdateBuffs()

    Globals.CurZoneId = mq.TLO.Zone.ID()
    Globals.CurInstanceId = mq.TLO.Me.Instance()

    Comms.SendHeartbeat(true)

    if isStandalone then
        Comms.ValidatePeers(30)
    end

    mq.delay(500)
end

Logger.log_info("heartbeat.lua: exiting.")
