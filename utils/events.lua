local mq       = require('mq')
local Comms    = require("utils.comms")
local Config   = require('utils.config')
local Core     = require("utils.core")
local Globals  = require('utils.globals')
local Logger   = require("utils.logger")
local Modules  = require("utils.modules")

local Events   = { _version = '1.0', _name = "Events", _author = 'Derple', }

Events.__index = Events

--- Handles player death: fires OnDeath on all modules, waits for
--- release or rez, then uses the fellowship insignia if configured.
function Events.HandleDeath()
    Logger.log_warn("You are sleeping with the fishes.")

    Modules:ExecAll("OnDeath")

    while mq.TLO.Me.Hovering() do
        Logger.log_debug("Trying to release...")
        if mq.TLO.Window("RespawnWnd").Open() and Config:GetSetting('InstantRelease') then
            mq.TLO.Window("RespawnWnd").Child("RW_OptionsList").Select(1)
            mq.delay("1s")
            mq.TLO.Window("RespawnWnd").Child("RW_SelectButton").LeftMouseUp()
        else
            break
        end
    end

    mq.delay("2m", function() return not mq.TLO.Me.Hovering() or (mq.TLO.Zone.ID() ~= Globals.CurZoneId) end)

    Logger.log_debug("Fishfood no more! Accepted rez or finished zoning post death.")

    -- if we want do do fellowship but we arent in the fellowship zone (rezed)
    if Config:GetSetting('DoFellow') and not Modules:ExecModule("Movement", "InCampZone") then
        Logger.log_debug("Doing fellowship post death.")
        if mq.TLO.FindItem("Fellowship Registration Insignia").Timer.TotalSeconds() == 0 then
            mq.delay("30s", function() return (mq.TLO.Me.CombatState():lower() == "active") end)
            Core.DoCmd("/useitem \"Fellowship Registration Insignia\"")
            mq.delay("2s",
                function() return (mq.TLO.FindItem("Fellowship Registration Insignia").Timer.TotalSeconds() ~= 0) end)
        else
            Logger.log_debug("\aw Bummer, Insignia on cooldown, you must really suck at this game...")
        end
    end
end

--- Sends the periodic heartbeat and dispatches DoEvents to all modules.
function Events.DoEvents()
    Modules:ExecAll("DoEvents")
end

return Events
