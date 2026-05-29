-- Drag Module
local mq        = require('mq')
local Base      = require("modules.base")
local Comms     = require("utils.comms")
local Config    = require('utils.config')
local Core      = require("utils.core")
local DanNet    = require('lib.dannet.helpers')
local Logger    = require("utils.logger")
local Targeting = require("utils.targeting")

local Module    = { _version = '0.1a', _name = "Drag", _author = 'Derple', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })

Module.FAQ             = {}
Module.CommandHandlers = {}
Module.DefaultConfig   = {
    ['DoDrag']                                 = {
        DisplayName = "Drag Corpses",
        Group = "Movement",
        Header = "Drag",
        Category = "Drag",
        Tooltip = "Enable dragging friendly corpses in your vacinity.",
        Index = 1,
        Default = false,
    },
    ['DoDanNetDrag']                           = {
        DisplayName = "Use DanNet Dragging",
        Group = "Movement",
        Header = "Drag",
        Category = "Drag",
        Tooltip = "Use DanNet peer checks to identify corpses that should be dragged within a 95 unit radius.",
        Index = 2,
        Default = true,
    },
    ['DoActorsDrag']                           = {
        DisplayName = "Use Actor Peers Dragging",
        Group = "Movement",
        Header = "Drag",
        Category = "Drag",
        Tooltip = "Use Actor peers checks to identify corpses that should be dragged within a 95 unit radius.",
        Index = 2,
        Default = true,
    },
    ['DoSearchDrag']                           = {
        DisplayName = "Use Spawn Search Dragging",
        Group = "Movement",
        Header = "Drag",
        Category = "Drag",
        Tooltip = "Use an MQ Spawn Search to identify corpses that should be dragged.",
        Index = 3,
        Default = false,
    },
    ['SearchDrag']                             = {
        DisplayName = "Spawn Search",
        Group = "Movement",
        Header = "Drag",
        Category = "Drag",
        Tooltip = "The MQ Spawn Search used when Spawn Search Dragging is enabled above. Note the max drag distance is 100 units.",
        Index = 4,
        Default = "pccorpse group radius 95",
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Render()
    Base.Render(self)

    if self.ModuleLoaded then
        if ImGui.Button(Config:GetSetting('DoDrag') and "Stop Dragging" or "Start Dragging", ImGui.GetWindowWidth() * .3, 25) then
            Config:SetSetting('DoDrag', not Config:GetSetting('DoDrag'))
        end
    end
end

function Module:Drag(corpse)
    if corpse and corpse() and corpse.Distance() > 10 then
        Logger.log_debug("Dragging: %s (%d)", corpse.DisplayName(), corpse.ID())
        Targeting.SetTarget(corpse.ID())
        Core.DoCmd("/corpse")
    end
end

function Module:GiveTime()
    -- Main Module logic goes here.

    local corpseSearch = "pccorpse %s's radius 90"
    if Config:GetSetting('DoDrag') then
        local myCorpse = mq.TLO.Spawn(string.format(corpseSearch, mq.TLO.Me.DisplayName()))

        self:Drag(myCorpse)

        if Config:GetSetting('DoSearchDrag') then
            local numCorpses = mq.TLO.SpawnCount(Config:GetSetting('SearchDrag'))()

            for i = numCorpses, 1, -1 do
                local corpse = mq.TLO.NearestSpawn(i, Config:GetSetting('SearchDrag'))
                self:Drag(corpse)
            end
        end

        if Config:GetSetting('DoDanNetDrag') then
            local dannetPeers = mq.TLO.DanNet.PeerCount()
            for i = 1, dannetPeers do
                local peer = DanNet.getPeer(i)

                if peer and peer:len() > 0 then
                    Logger.log_debug("Searching corpses for: %s", peer)
                    local currentSearch = string.format(corpseSearch, peer)
                    local numCorpses = mq.TLO.SpawnCount(currentSearch)()

                    for i = numCorpses, 1, -1 do
                        local corpse = mq.TLO.NearestSpawn(i, currentSearch)
                        self:Drag(corpse)
                    end
                end
            end
        end

        if Config:GetSetting('DoActorsDrag') then
            local actors = Comms.GetPeers(true)
            for _, peerFullName in ipairs(actors) do
                local peerName = Comms.GetNameFromPeer(peerFullName)

                Logger.log_debug("Searching corpses for: %s", peerName)
                local currentSearch = string.format(corpseSearch, peerName)
                local numCorpses = mq.TLO.SpawnCount(currentSearch)()

                for i = numCorpses, 1, -1 do
                    local corpse = mq.TLO.NearestSpawn(i, currentSearch)
                    self:Drag(corpse)
                end
            end
        end
    end
end

return Module
