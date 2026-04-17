local mq                   = require('mq')
local Set                  = require("mq.set")
local Logger               = require("utils.logger")
local Strings              = require("utils.strings")
local Globals              = require("utils.globals")

local Comms                = { _version = '1.0', _name = "Comms", _author = 'Derple', }
Comms.__index              = Comms
Comms.Actors               = require('actors')
Comms.ScriptName           = "RGMercs"
Comms.LastHeartbeat        = 0
Comms.Peers                = Set.new({})
Comms.PeersToServerNameMap = {}
Comms.PeersHeartbeats      = {}

-- Putting this here for lack of a beter spot.
--- @param peerName string? The character name string if not supplied then we use Me.DisplayName()
function Comms.GetPeerName(peerName)
    local server = mq.TLO.EverQuest.Server()
    --upper first letter if it isnt (Live)
    if server:len() > 0 then
        server = server:sub(1, 1):upper() .. server:sub(2)
    end

    return string.format("%s (%s)", peerName and peerName or mq.TLO.Me.DisplayName(), server)
end

function Comms.GetNameAndServerFromPeer(peer)
    local data = Comms.PeersToServerNameMap[peer]
    if data then
        return data.Name, data.Server
    end

    return nil, nil
end

function Comms.GetNameFromPeer(peer)
    local data = Comms.PeersToServerNameMap[peer]
    if data then
        return data.Name
    end

    return nil
end

--- Broadcasts an update event to the specified module.
---
--- @param module string The name of the module to broadcast the update to.
--- @param event string The event type to broadcast.
--- @param data table? The data associated with the event.
function Comms.BroadcastMessage(module, event, data)
    Comms.Actors.send({
        From = Comms.GetPeerName(),
        Script = Comms.ScriptName,
        Module = module,
        Event = event,
        Data = data,
    })
    Logger.log_super_verbose("Broadcasted: %s event: %s", event, Strings.TableToString(data or {}, 512))
end

--- @param module string The name of the module to broadcast the update to.
--- @param event string The event type to broadcast.
--- @param data table? The data associated with the event.
function Comms.SendMessage(peer, module, event, data)
    local char, server = Comms.GetNameAndServerFromPeer(peer)
    Comms.Actors.send({ server = server, character = char, }, {
        From = Comms.GetPeerName(),
        Script = Comms.ScriptName,
        Module = module,
        Event = event,
        Data = data,
    })
    Logger.log_super_verbose("Sent Message: %s to:  %s event: %s", event, peer, Strings.TableToString(data or {}, 512))
end

function Comms.SendPeerDoCmd(peer, cmd, ...)
    cmd = string.format(cmd, ...)

    if peer == Comms.GetPeerName() then
        mq.cmd(cmd)
        return
    end

    Comms.SendMessage(peer, "Core", "DoCmd", {
        cmd = cmd, })
end

function Comms.SendAllPeersDoCmd(inZoneOnly, includeSelf, cmd, ...)
    cmd = string.format(cmd, ...)

    if includeSelf then
        mq.cmd(cmd)
    end

    for peer, data in pairs(Comms.PeersHeartbeats) do
        if data.Data.Zone == mq.TLO.Zone.Name() or not inZoneOnly then
            Comms.SendMessage(peer, "Core", "DoCmd", {
                cmd = cmd, })
        end
    end
end

function Comms.SendHeartbeat(assist, chase, forceSend)
    if not forceSend and Globals.GetTimeSeconds() - Comms.LastHeartbeat < 1 then return end
    local useMana = Globals.Constants.RGCasters:contains(mq.TLO.Me.Class.ShortName())
    local useEnd = Globals.Constants.RGMelee:contains(mq.TLO.Me.Class.ShortName())
    local curAutoTarget = mq.TLO.Spawn(string.format("id %d", Globals.AutoTargetID))

    Comms.LastHeartbeat = Globals.GetTimeSeconds()
    local heartBeat = {
        From          = Comms.GetPeerName(),
        Name          = Globals.CurLoadedChar,
        Server        = mq.TLO.EverQuest.Server(),
        Zone          = mq.TLO.Zone.Name(),
        ZoneShortName = mq.TLO.Zone.ShortName(),
        ID            = mq.TLO.Me.ID(),
        Level         = mq.TLO.Me.Level(),
        X             = mq.TLO.Me.X(),
        Y             = mq.TLO.Me.Y(),
        Z             = mq.TLO.Me.Z(),
        Class         = mq.TLO.Me.Class.ShortName(),
        Poison        = tostring(mq.TLO.Me.Poisoned.ID()),
        Disease       = tostring(mq.TLO.Me.Diseased.ID()),
        Curse         = tostring(mq.TLO.Me.Cursed.ID()),
        Mezzed        = tostring(mq.TLO.Me.Mezzed.ID()),
        Corruption    = tostring(mq.TLO.Me.Corrupted.ID()),
        Stunned       = mq.TLO.Me.Stunned(),
        HPs           = mq.TLO.Me.Dead() and 0 or mq.TLO.Me.PctHPs(),
        Mana          = useMana and mq.TLO.Me.PctMana() or nil,
        Endurance     = useEnd and mq.TLO.Me.PctEndurance() or nil,
        Target        = mq.TLO.Target.DisplayName() or "None",
        TargetID      = mq.TLO.Target.ID() or 0,
        AutoTargetID  = Globals.AutoTargetID,
        ForceTargetID = Globals.ForceTargetID,
        TargetIsNamed = Globals.AutoTargetIsNamed,
        Casting       = mq.TLO.Me.Casting.ID() ~= 0 and mq.TLO.Me.Casting.RankName() or "None",
        Burning       = Globals.LastBurnCheck,
        PetID         = mq.TLO.Me.Pet.ID() or 0,
        PetHPs        = mq.TLO.Me.Pet.ID() ~= 0 and (mq.TLO.Me.Pet.Dead() and 0 or mq.TLO.Me.Pet.PctHPs()) or 0,
        PetLevel      = mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.Level() or 0,
        PetName       = mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.DisplayName() or "",
        PetTarget     = mq.TLO.Me.Pet.ID() ~= 0 and (mq.TLO.Me.Pet.Target.CleanName() or "None") or "None",
        PetConColor   = mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.ConColor() or "Grey",
        AutoTarget    = curAutoTarget and (curAutoTarget.DisplayName() or "None") or "None",
        UnSpentAA     = mq.TLO.Me.AAPoints(),
        SpentAA       = mq.TLO.Me.AAPointsSpent(),
        TotalAA       = mq.TLO.Me.AAPointsTotal(),
        PctExp        = mq.TLO.Me.PctExp(),
        Assist        = assist,
        State         = Globals.PauseMain and "Paused" or Globals.CurrentState,
        Chase         = chase,
        Invis         = mq.TLO.Me.Invis(),
        FreeInventory = mq.TLO.Me.FreeInventory(3)(),
        Buffs         = Globals.CurrentBuffs,
        Songs         = Globals.CurrentSongs,
        Blocked       = Globals.CurrentBlocked,
        PetBuffs      = Globals.CurrentPetBuffs,
        PetBlocked    = Globals.CurrentPetBlocked,
        OpenBuffSlots = mq.TLO.Me.MaxBuffSlots() - Globals.CurrentBuffCount,
        MaxBuffSlots  = mq.TLO.Me.MaxBuffSlots(),
        Forced        = forceSend and true or false,
    }
    Comms.BroadcastMessage("RGMercs", "Heartbeat", heartBeat)
    -- update our own heartbeat too
    Comms.UpdatePeerHeartbeat(Comms.GetPeerName(), heartBeat)
end

function Comms.GetAllPeerHeartbeats(includeSelf)
    if not includeSelf then
        local heartbeats = {}
        for peer, heartbeat in pairs(Comms.PeersHeartbeats) do
            if peer ~= Comms.GetPeerName() then
                heartbeats[peer] = heartbeat
            end
        end
        return heartbeats
    end

    return Comms.PeersHeartbeats or {}
end

function Comms.GetPeerHeartbeatByName(name)
    return Comms.PeersHeartbeats[Comms.GetPeerName(name)] or {}
end

function Comms.GetPeerHeartbeat(peer)
    return Comms.PeersHeartbeats[peer] or {}
end

function Comms.IsValidPeer(peer)
    return Comms.Peers:contains(peer)
end

function Comms.GetPeers(includeSelf)
    if not includeSelf then
        local peers = Set.new(Comms.Peers:toList() or {})
        peers:remove(Comms.GetPeerName())
        return peers:toList() or {}
    end

    return Comms.Peers:toList() or {}
end

function Comms.UpdatePeerHeartbeat(peer, data)
    Comms.Peers:add(peer)
    Comms.PeersToServerNameMap[peer] = { Server = data.Server, Name = data.Name, }

    -- tables that are empty come across actors as nil so we need to fix them up.
    data.Buffs                       = data.Buffs or {}
    data.Songs                       = data.Songs or {}
    data.Blocked                     = data.Blocked or {}
    data.PetBuffs                    = data.PetBuffs or {}
    data.PetBlocked                  = data.PetBlocked or {}

    Comms.PeersHeartbeats[peer]      = { LastHeartbeat = Globals.GetTimeSeconds(), Data = data or {}, }
end

function Comms.ValidatePeers(timeout)
    Logger.log_super_verbose("\ayValidating peers heartbeats for timeouts: \n  :: %s\n  :: %s", Strings.TableToString(Comms.PeersHeartbeats, 512),
        Strings.TableToString(Comms.Peers:toList(), 512))
    for peer, heartbeat in pairs(Comms.PeersHeartbeats) do
        if Globals.GetTimeSeconds() - (heartbeat.LastHeartbeat or 0) > timeout then
            Logger.log_debug("\ayPeer \ag%s\ay has timed out, removing from active peer list.", peer)
            Comms.Peers:remove(peer)
            Comms.PeersHeartbeats[peer] = nil
            Comms.PeersToServerNameMap[peer] = nil
        end
    end
end

--- Prints a group message with the given format and arguments.
--- @param msg string: The message format string.
--- @param ... any: Additional arguments to format the message.
function Comms.PrintGroupMessage(msg, ...)
    local output = msg
    if (... ~= nil) then output = string.format(output, ...) end

    mq.cmdf("/dgt group_%s_%s %s", mq.TLO.EverQuest.Server():gsub(" ", ""), mq.TLO.Group.Leader() or "None", output)
end

--- Displays a pop-up message with the given text.
--- @param msg string: The message to be displayed in the pop-up.
--- @param ... any: Additional arguments that may be used within the function.
function Comms.PopUp(msg, ...)
    local output = msg
    if (... ~= nil) then output = string.format(output, ...) end

    mq.cmdf("/popupecho 15 5 %s", output)
end

--- Displays a pop-up message with the given text.
--- @param msg string: The message to be displayed in the pop-up.
--- @param ... any: Additional arguments that may be used within the function.
function Comms.PopUpColor(color, time, msg, ...)
    local output = msg
    if (... ~= nil) then output = string.format(output, ...) end

    mq.cmdf("/popupecho %d %d %s", color, time, output)
end

--- Handles the announcement message.
--- @param msg string: The message to be announced.
--- @param sendGroup boolean: Whether to send the message to the group.
--- @param sendDan boolean: Whether to send the message to DanNet.
function Comms.HandleAnnounce(msg, sendGroup, sendDan, AnnounceToRaidIfInRaid)
    if sendGroup then
        local cleanMsg = msg:gsub("\a.", "")

        if mq.TLO.Raid.Members() > 0 and AnnounceToRaidIfInRaid then
            mq.cmdf("/rsay %s", cleanMsg)
        else
            mq.cmdf("/gsay %s", cleanMsg)
        end
    end

    if sendDan then
        Comms.PrintGroupMessage(msg)
    end

    Logger.log_debug(msg)
end

function Comms.FormatChatEvent(event, target, source)
    return string.format("[%s] => %s <= {%s}", event or "Unknown", target or "None", source or "???")
end

return Comms
