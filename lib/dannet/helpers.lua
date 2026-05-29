local mq = require('mq')
local Logger = require("utils.logger")
local Strings = require("utils.strings")

local helpers = {}

function helpers.query(peer, query, timeout)
    mq.cmdf('/dquery %s -q "%s"', peer, query)
    if timeout > 0 then
        mq.delay(25)
        mq.delay(timeout or 1000, function() return (mq.TLO.DanNet(peer).Q(query).Received() or 0) > 0 end)
    end
    local value = mq.TLO.DanNet(peer).Q(query)()
    Logger.log_verbose('\ayQuerying - mq.TLO.DanNet(%s).Q(%s) = %s [%d]', peer, query, value, mq.TLO.DanNet(peer).Q(query).Received() or 0)
    return value or "null"
end

function helpers.observe(peer, query, timeout)
    if not mq.TLO.DanNet(peer).OSet(query)() then
        mq.cmdf('/dobserve %s -q "%s"', peer, query)
        Logger.log_verbose('\ayAdding Observer - mq.TLO.DanNet(%s).O(%s)', peer, query)
    end
    ---@diagnostic disable-next-line: undefined-field
    mq.delay(timeout or 1000, function() return (mq.TLO.DanNet(peer).O(query).Received() or 0) > 0 end)
    local value = mq.TLO.DanNet(peer).O(query)()
    Logger.log_verbose('\ayObserving - mq.TLO.DanNet(%s).O(%s) = %s [%d]', peer, query, value, mq.TLO.DanNet(peer).Q(query).Received() or 0)
    return value
end

function helpers.unobserve(peer, query)
    mq.cmdf('/dobserve %s -q "%s" -drop', peer, query)
    Logger.log_verbose('\ayRemoving Observer - mq.TLO.DanNet(%s).O(%s) = %s', peer, query, mq.TLO.DanNet(peer).O(query)())
end

function helpers.getPeer(peerIdx)
    if peerIdx < 1 or peerIdx > mq.TLO.DanNet.PeerCount() then
        Logger.log_warn('\argetPeer: Invalid peer index %d (1-%d)', peerIdx, mq.TLO.DanNet.PeerCount())
        return nil
    end

    -- this looks redundant but since we cannot created yield proected blocks we need to check the idx again.
    ---@diagnostic disable-next-line: redundant-parameter
    local peer = peerIdx <= mq.TLO.DanNet.PeerCount() and mq.TLO.DanNet.Peers(peerIdx)() or nil
    Logger.log_verbose('\ayGetting Peer - mq.TLO.DanNet.Peers(%d) = %s', peerIdx, peer or "None")
    return peer
end

function helpers.getAllPeers()
    local peers = Strings.split(mq.TLO.DanNet.Peers() or "", "|")
    Logger.log_verbose('\ayGetting All Peers - mq.TLO.DanNet.Peers() = %s', Strings.TableToString(peers, 512))
    return peers
end

return helpers
