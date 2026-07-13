local mq                   = require('mq')
local Set                  = require("mq.set")
local Globals              = require("utils.globals")
local Logger               = require("utils.logger")
local Strings              = require("utils.strings")

local Comms                = { _version = '1.0', _name = "Comms", _author = 'Derple', }
Comms.__index              = Comms
Comms.Actors               = require('actors')
Comms.ScriptName           = "RGMercs"
Comms.LastHeartbeat        = 0
Comms.Peers                = Set.new({})
Comms.PeersToServerNameMap = {}
Comms.PeersHeartbeats      = {}
Comms.OutgoingToasts       = {}

-- Putting this here for lack of a beter spot.
--- Returns "Name (Server)" for use as the actor peer key. Uppercases
--- the first letter of the server name for Live compatibility.
--- @param peerName string? Character name; defaults to Me.DisplayName().
--- @param peerServer string? Server name; defaults to the local server.
--- @return string The formatted "Name (Server)" peer identifier.
function Comms.GetPeerName(peerName, peerServer)
    local server = peerServer or Globals.CurServer
    --upper first letter if it isnt (Live)
    if server:len() > 0 then
        server = server:sub(1, 1):upper() .. server:sub(2)
    end

    return string.format("%s (%s)", peerName and peerName or mq.TLO.Me.DisplayName(), server)
end

--- Returns true if the given char/server/class identifies the local current character.
--- @param charName string The character name to test.
--- @param server string The server name to test.
--- @param class string The class short name to test.
--- @return boolean
function Comms.IsLocalCurrent(charName, server, class)
    return charName == Globals.CurLoadedChar and server == Globals.CurServer and class == Globals.CurLoadedClass
end

--- Returns true if the given char/server/class is the local current character
--- or a networked peer currently running RGMercs on that class.
--- @param charName string The character name to test.
--- @param server string The server name to test.
--- @param class string The class short name to test.
--- @return boolean
function Comms.IsCharRunning(charName, server, class)
    if Comms.IsLocalCurrent(charName, server, class) then return true end
    local hb = Comms.GetPeerHeartbeat(Comms.GetPeerName(charName, server))
    return hb and hb.Data and hb.Data.Class == class and true or false
end

--- Looks up a peer key in PeersToServerNameMap and returns its
--- character name and server name as separate values.
--- @param peer string The peer key ("Name (Server)") to look up.
--- @return string|nil name The character name, or nil if not found.
--- @return string|nil server The server name, or nil if not found.
function Comms.GetNameAndServerFromPeer(peer)
    local data = Comms.PeersToServerNameMap[peer]
    if data then
        return data.Name, data.Server
    end

    return nil, nil
end

--- Looks up a peer key in PeersToServerNameMap and returns only
--- the character name portion.
--- @param peer string The peer key ("Name (Server)") to look up.
--- @return string|nil The character name, or nil if not found.
function Comms.GetNameFromPeer(peer)
    local data = Comms.PeersToServerNameMap[peer]
    if data then
        return data.Name
    end

    return nil
end

--- Sends an actor broadcast to all MQ instances on the network.
--- @param module string The target module name for the message.
--- @param event string The event type to broadcast.
--- @param data table? The data payload for the event.
function Comms.BroadcastMessage(module, event, data)
    Comms.Actors.send({ mailbox = 'RGMercs', script = 'rgmercs', }, {
        From = Comms.GetPeerName(),
        Script = Comms.ScriptName,
        Module = module,
        Event = event,
        Data = data,
    })
    Comms.Actors.send({ mailbox = 'RGMercs-Heartbeat', script = 'rgmercs/heartbeat', }, {
        From = Comms.GetPeerName(),
        Script = Comms.ScriptName,
        Module = module,
        Event = event,
        Data = data,
    })
    Logger.log_super_verbose("Broadcasted: %s event: %s", event, Strings.TableToString(data or {}, 512))
end

--- Sends a directed actor message to a single peer by looking up
--- their server and character name from PeersToServerNameMap.
--- @param peer string The peer key ("Name (Server)") to send to.
--- @param module string The target module name for the message.
--- @param event string The event type to send.
--- @param data table? The data payload for the event.
function Comms.SendMessage(peer, module, event, data)
    local char, server = Comms.GetNameAndServerFromPeer(peer)
    if not char or not server then return end
    Comms.Actors.send({ mailbox = 'RGMercs', script = 'rgmercs', server = server, character = char, }, {
        From = Comms.GetPeerName(),
        Script = Comms.ScriptName,
        Module = module,
        Event = event,
        Data = data,
    })
    Logger.log_super_verbose("Sent Message: %s to:  %s event: %s", event, peer, Strings.TableToString(data or {}, 512))
end

--- Sends a /cmd to a single peer via SendMessage. If the peer is
--- self, executes the command locally instead.
--- @param peer string The peer key to target.
--- @param cmd string The command format string.
--- @param ... any Format arguments for the command string.
function Comms.SendPeerDoCmd(peer, cmd, ...)
    cmd = string.format(cmd, ...)

    if peer == Comms.GetPeerName() then
        mq.cmd(cmd)
        return
    end

    Comms.SendMessage(peer, "Core", "DoCmd", {
        cmd = cmd, })
end

--- Broadcasts a /cmd to all known peers. Optionally restricted to
--- peers in the current zone, and optionally including self.
--- @param inZoneOnly boolean Only send to peers in the current zone.
--- @param includeSelf boolean Execute the command locally as well.
--- @param cmd string The command format string.
--- @param ... any Format arguments for the command string.
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

--- Sends a /cmd to each peer entry in the given list, running locally for self when present.
function Comms.SendPeersDoCmd(peers, cmd, ...)
    for _, peer in ipairs(peers) do
        Comms.SendPeerDoCmd(peer.key, cmd, ...)
    end
end

--- Returns fresh same-server/zone/instance peer entries ({ name, key, data }); memberCheck filters non-self peers when given.
function Comms.GetFilteredPeers(includeSelf, memberCheck)
    includeSelf = includeSelf or false
    local peers = {}
    local myName = Comms.GetPeerName()
    local myServer = mq.TLO.EverQuest.Server() or ""
    local myZone = mq.TLO.Zone.ID() or 0
    local myInst = mq.TLO.Me.Instance() or 0

    for peer, heartbeat in pairs(Comms.PeersHeartbeats) do
        local data = heartbeat.Data
        local isSelf = peer == myName
        local fresh = (Globals.GetTimeSeconds() - (heartbeat.LastHeartbeat or 0)) <= 2
        if data and (isSelf or fresh) and data.Server == myServer and data.ZoneId == myZone and data.InstanceId == myInst then
            local include = includeSelf
            if not isSelf then
                include = not memberCheck or memberCheck(data.Name)
            end

            if include then
                table.insert(peers, { name = data.Name, key = peer, data = data, })
            end
        end
    end

    -- the heartbeat store may not carry our own entry, so add it when requested
    if includeSelf then
        local haveSelf = false
        for _, entry in ipairs(peers) do
            if entry.key == myName then
                haveSelf = true
                break
            end
        end

        if not haveSelf then
            local selfHb = Comms.GetPeerHeartbeat(myName)
            table.insert(peers, { name = mq.TLO.Me.DisplayName(), key = myName, data = selfHb and selfHb.Data or {}, })
        end
    end

    return peers
end

--- Returns fresh peer entries ({ name, key, data }) in our zone and instance, honoring includeSelf.
function Comms.GetZonePeers(includeSelf)
    return Comms.GetFilteredPeers(includeSelf)
end

--- Returns fresh in-zone peer entries ({ name, key, data }) that are in our group, honoring includeSelf.
function Comms.GetGroupPeers(includeSelf)
    return Comms.GetFilteredPeers(includeSelf, function(name) return mq.TLO.Group.Member(name)() ~= nil end)
end

--- Returns fresh in-zone peer entries ({ name, key, data }) that are in our raid, honoring includeSelf.
function Comms.GetRaidPeers(includeSelf)
    return Comms.GetFilteredPeers(includeSelf, function(name) return mq.TLO.Raid.Member(name)() ~= nil end)
end

--- Broadcasts the player's full state (HP, mana, target, buffs,
--- position, etc.) to all peers at most once per second, then
--- updates own entry in PeersHeartbeats. forceSend bypasses the
--- throttle.
--- @param forceSend boolean|nil Skip the 1-second throttle if true.
function Comms.SendHeartbeat(forceSend)
    if not forceSend and Globals.GetTimeSeconds() - Comms.LastHeartbeat < 1 then
        return
    end

    ---@diagnostic disable-next-line: undefined-field
    local RGMercs = mq.TLO.RGMercs

    local useMana = Globals.Constants.RGCasters:contains(mq.TLO.Me.Class.ShortName())
    local useEnd = Globals.Constants.RGMelee:contains(mq.TLO.Me.Class.ShortName())
    local autoTargetID = RGMercs and RGMercs.Globals("AutoTargetID")() or mq.TLO.Target.ID()
    local curAutoTarget = mq.TLO.Spawn(string.format("id %d", autoTargetID))

    Comms.LastHeartbeat = Globals.GetTimeSeconds()
    local heartBeat = {
        From               = Comms.GetPeerName(),
        Name               = Globals.CurLoadedChar,
        Server             = mq.TLO.EverQuest.Server(),
        Zone               = mq.TLO.Zone.Name(),
        ZoneShortName      = mq.TLO.Zone.ShortName(),
        ZoneId             = mq.TLO.Zone.ID(),
        InstanceId         = mq.TLO.Me.Instance(),
        ID                 = mq.TLO.Me.ID(),
        Level              = mq.TLO.Me.Level(),
        X                  = mq.TLO.Me.X(),
        Y                  = mq.TLO.Me.Y(),
        Z                  = mq.TLO.Me.Z(),
        Class              = mq.TLO.Me.Class.ShortName(),
        Poison             = mq.TLO.Me.Poisoned(),
        Disease            = mq.TLO.Me.Diseased(),
        Curse              = mq.TLO.Me.Cursed(),
        Mezzed             = mq.TLO.Me.Mezzed(),
        Corruption         = mq.TLO.Me.Corrupted(),
        Stunned            = mq.TLO.Me.Stunned(),
        HPs                = mq.TLO.Me.Dead() and 0 or mq.TLO.Me.PctHPs(),
        Mana               = useMana and mq.TLO.Me.PctMana() or nil,
        Endurance          = useEnd and mq.TLO.Me.PctEndurance() or nil,
        Target             = mq.TLO.Target.DisplayName() or "None",
        TargetID           = mq.TLO.Target.ID() or 0,
        AutoTargetID       = autoTargetID,
        ForceTargetID      = RGMercs and RGMercs.Globals("ForceTargetID")() or 0,
        CharmedPetID       = RGMercs and RGMercs.Globals("MyCharmedPetID")() or 0,
        LooseCharmID       = RGMercs and RGMercs.Globals("MyLooseCharmID")() or 0,
        CastingGroupDispel = RGMercs and RGMercs.Globals("CastingGroupDispel")() or false,
        TargetIsNamed      = RGMercs and RGMercs.Globals("AutoTargetIsNamed")() or nil,
        Casting            = mq.TLO.Me.Casting.ID() ~= 0 and mq.TLO.Me.Casting.RankName() or "None",
        Burning            = RGMercs and RGMercs.Globals("LastBurnCheck")() or false,
        PetID              = mq.TLO.Me.Pet.ID() or 0,
        PetHPs             = mq.TLO.Me.Pet.ID() ~= 0 and (mq.TLO.Me.Pet.Dead() and 0 or mq.TLO.Me.Pet.PctHPs()) or 0,
        PetLevel           = mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.Level() or 0,
        PetName            = mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.DisplayName() or "",
        PetTarget          = mq.TLO.Me.Pet.ID() ~= 0 and (mq.TLO.Me.Pet.Target.CleanName() or "None") or "None",
        PetConColor        = mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.ConColor() or "Grey",
        AutoTarget         = curAutoTarget and (curAutoTarget.DisplayName() or "None") or "None",
        UnSpentAA          = mq.TLO.Me.AAPoints(),
        SpentAA            = mq.TLO.Me.AAPointsSpent(),
        TotalAA            = mq.TLO.Me.AAPointsTotal(),
        PctExp             = mq.TLO.Me.PctExp(),
        Assist             = RGMercs and RGMercs.Globals("MainAssist")() or "Standalone", --Globals.MainAssist,
        State              = RGMercs and (RGMercs.Globals("PauseMain")() and "Paused" or RGMercs and RGMercs.Globals("CurrentState")() or "Running") or "Standalone",
        Chase              = RGMercs and (RGMercs.Config('ChaseOn')() and RGMercs.Config('ChaseTarget')() or "Chase Off") or "Standalone",
        Invis              = mq.TLO.Me.Invis(),
        FreeInventory      = mq.TLO.Me.FreeInventory(3)(),
        Buffs              = Globals.CurrentBuffs,
        CureEffects        = Globals.CurrentCureEffects,
        Songs              = Globals.CurrentSongs,
        Blocked            = Globals.CurrentBlocked,
        PetBuffs           = Globals.CurrentPetBuffs,
        PetBlocked         = Globals.CurrentPetBlocked,
        OpenBuffSlots      = mq.TLO.Me.MaxBuffSlots() - Globals.CurrentBuffCount,
        MaxBuffSlots       = mq.TLO.Me.MaxBuffSlots(),
        BuffCount          = Globals.CurrentBuffCount,
        RaidLeader         = mq.TLO.Raid.Leader() or "None",
        GroupLeader        = mq.TLO.Group.Leader() or "None",
        Forced             = forceSend and true or false,
        Toasts             = Comms.OutgoingToasts,
    }
    Comms.BroadcastMessage("RGMercs", "Heartbeat", heartBeat)

    Comms.OutgoingToasts = {}
end

--- Returns all cached peer heartbeat data. When includeSelf is
--- false, the local peer's own entry is excluded.
--- @param includeSelf boolean? Include the local peer's heartbeat.
--- @return table Map of peer key to heartbeat data.
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

--- Looks up a heartbeat by character name by constructing the peer
--- key via GetPeerName, then returns the cached heartbeat or {}.
--- @param name string The character name to look up.
--- @return table The heartbeat data table, or {} if not found.
function Comms.GetPeerHeartbeatByName(name)
    return Comms.PeersHeartbeats[Comms.GetPeerName(name)] or {}
end

--- Returns the cached heartbeat for the given peer key, or {} if
--- the peer has no recorded heartbeat.
--- @param peer string The peer key ("Name (Server)") to look up.
--- @return table The heartbeat data table, or {} if not found.
function Comms.GetPeerHeartbeat(peer)
    return Comms.PeersHeartbeats[peer] or {}
end

--- Returns true if the peer key exists in the active Peers set.
--- @param peer string The peer key ("Name (Server)") to check.
--- @return boolean True if the peer is currently tracked as active.
function Comms.IsValidPeer(peer)
    return Comms.Peers:contains(peer)
end

--- Returns the list of active peer keys. When includeSelf is false,
--- the local peer's own key is excluded from the result.
--- @param includeSelf boolean Include the local peer in the list.
--- @return table List of active peer key strings.
function Comms.GetPeers(includeSelf)
    if not includeSelf then
        local peers = Set.new(Comms.Peers:toList() or {})
        peers:remove(Comms.GetPeerName())
        return peers:toList() or {}
    end

    return Comms.Peers:toList() or {}
end

--- Registers or refreshes a peer: adds the key to the Peers set,
--- updates PeersToServerNameMap, normalises nil buff/song/blocked
--- tables to {}, stores the heartbeat with a timestamp, and
--- processes any incoming toasts from the peer.
--- @param peer string The peer key ("Name (Server)") to update.
--- @param data table The heartbeat data payload from the peer.
function Comms.UpdatePeerHeartbeat(peer, data)
    Comms.Peers:add(peer)
    Comms.PeersToServerNameMap[peer] = { Server = data.Server, Name = data.Name, }

    -- tables that are empty come across actors as nil so we need to fix them up.
    data.Buffs                       = data.Buffs or {}
    data.CureEffects                 = data.CureEffects or {}
    data.Songs                       = data.Songs or {}
    data.Blocked                     = data.Blocked or {}
    data.PetBuffs                    = data.PetBuffs or {}
    data.PetBlocked                  = data.PetBlocked or {}

    Comms.PeersHeartbeats[peer]      = { LastHeartbeat = Globals.GetTimeSeconds(), Data = data or {}, }

    if peer ~= Comms.GetPeerName() and Globals.Config then
        local peerToastLevel = Globals.Config:GetSetting("PeerToastLevel") or 1
        for _, toast in ipairs(data.Toasts or {}) do
            -- PeerToastLevel is 2..n so it is 1 larger than the logLevel
            if toast.active and (tonumber(toast.logLevel) or 0) < peerToastLevel then
                Logger.log_super_verbose("Received toast from peer %s: %s", peer, toast.message)
                table.insert(Logger.ToastStates, {
                    active = true,
                    timer = 0,
                    from = toast.from,
                    peer = peer,
                    message = toast.message,
                    color = toast.color,
                    receivedTime = os.time(),
                })
            end
        end
    end
end

--- Collects the corpse ids that fresh peers (same server/zone/instance, not
--- self) are actively casting a resurrection on, detected by SPA 81 on the
--- peer's current cast, so a rez pass can skip corpses a peer is already
--- rezzing. Freshness is 2s, well under ActorPeerTimeout.
--- @return table<number, boolean> Set of corpse ids a peer is currently rezzing.
function Comms.GetPeersRezzingCorpses()
    local rezzing = {}
    local myName = Comms.GetPeerName()
    local myServer = mq.TLO.EverQuest.Server() or ""
    local myZone = mq.TLO.Zone.ID() or 0
    local myInst = mq.TLO.Me.Instance() or 0

    for peer, heartbeat in pairs(Comms.PeersHeartbeats) do
        if peer ~= myName and (Globals.GetTimeSeconds() - (heartbeat.LastHeartbeat or 0)) <= 2 then
            local data = heartbeat.Data
            if data and data.Server == myServer and data.ZoneId == myZone and data.InstanceId == myInst then
                local casting = data.Casting or "None"
                if casting ~= "None" and (data.TargetID or 0) > 0 then
                    local spell = mq.TLO.Spell(casting)
                    if spell() and spell.HasSPA(81)() then rezzing[data.TargetID] = true end
                end
            end
        end
    end
    return rezzing
end

--- Removes peers whose last heartbeat is older than timeout seconds
--- from the Peers set, PeersHeartbeats, and PeersToServerNameMap.
--- @param timeout number Seconds since last heartbeat before expiry.
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

function Comms.HeartbeatWatchdog()
    if mq.TLO.Lua.Script('rgmercs/heartbeat').Status() ~= 'RUNNING' then
        mq.cmd("/lua run rgmercs/heartbeat directed")
    end
end

--- Sends msg to the group's DanNet channel via /dgt, scoped to the
--- current server and group leader to avoid cross-group bleed.
--- @param msg string The message format string.
--- @param ... any Format arguments for the message.
function Comms.PrintGroupMessage(msg, ...)
    local output = msg
    if (... ~= nil) then output = string.format(output, ...) end

    mq.cmdf("/dgt group_%s_%s %s", mq.TLO.EverQuest.Server():gsub(" ", ""), mq.TLO.Group.Leader() or "None", output)
end

--- Shows a /popupecho message with default color 15 for 5 seconds.
--- @param msg string The message format string.
--- @param ... any Format arguments for the message.
function Comms.PopUp(msg, ...)
    local output = msg
    if (... ~= nil) then output = string.format(output, ...) end

    mq.cmdf("/popupecho 15 5 %s", output)
end

--- Shows a /popupecho message with configurable color and duration.
--- @param color number The EQ color index for the popup text.
--- @param time number Display duration in seconds.
--- @param msg string The message format string.
--- @param ... any Format arguments for the message.
function Comms.PopUpColor(color, time, msg, ...)
    local output = msg
    if (... ~= nil) then output = string.format(output, ...) end

    mq.cmdf("/popupecho %d %d %s", color, time, output)
end

--- Sends an announcement via /gsay or /rsay (when in a raid and
--- AnnounceToRaidIfInRaid is set) and/or DanNet group channel,
--- then logs it at debug level. Color codes are stripped for chat.
--- @param msg string The message to announce.
--- @param sendGroup boolean Send via /gsay or /rsay if true.
--- @param sendDan boolean Send via DanNet group channel if true.
--- @param AnnounceToRaidIfInRaid boolean Use /rsay when in a raid.
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

--- Formats a structured chat event string used by HandleAnnounce
--- and similar callers to produce consistent log/announce messages.
--- @param event string The event type label (e.g. "Cast", "Burn").
--- @param target string|nil The target name, or "None" if absent.
--- @param source string|nil The source/detail string, or "???" if absent.
--- @return string Formatted string "[event] => target <= {source}".
function Comms.FormatChatEvent(event, target, source)
    return string.format("[%s] => %s <= {%s}", event or "Unknown", target or "None", source or "???")
end

return Comms
