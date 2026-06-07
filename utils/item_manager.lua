local mq            = require('mq')
local Comms         = require("utils.comms")
local Config        = require("utils.config")
local Core          = require("utils.core")
local Globals       = require("utils.globals")
local Logger        = require("utils.logger")
local Movement      = require("utils.movement")
local Targeting     = require("utils.targeting")

local ItemManager   = { _version = '1.0', _name = "Trade", _author = 'Derple', }

ItemManager.__index = ItemManager

--- Gives a specified item to a target.
--- @param toId number The ID of the target to give the item to.
--- @param itemName string The name of the item to give.
--- @param count number The number of items to give.
function ItemManager.GiveTo(toId, itemName, count)
    if toId ~= mq.TLO.Target.ID() then
        Targeting.SetTarget(toId, true)
    end

    if not mq.TLO.Target() then
        Logger.log_error("\arGiveTo but unable to target %d!", toId)
        return
    end

    if mq.TLO.Target.Distance3D() >= 25 then
        Logger.log_debug("\arGiveTo but Target is too far away - moving closer!")
        Movement:DoNav(false, "id %d |log=off dist=10")

        mq.delay("10s", function() return mq.TLO.Navigation.Active() end)
    end

    while not mq.TLO.Cursor.ID() do
        Core.DoCmd("/shift /itemnotify \"%s\" leftmouseup", itemName)
        mq.delay(20, function() return mq.TLO.Cursor.ID() ~= nil end)
    end

    while mq.TLO.Cursor.ID() do
        Core.DoCmd("/nomodkey /click left target")
        mq.delay(20, function() return mq.TLO.Cursor.ID() == nil end)
    end

    -- Click OK on trade window and wait for it to go away
    if Targeting.TargetIsType("pc") then
        mq.delay("5s", function() return mq.TLO.Window("TradeWnd").Open() == true end)
        mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()
        mq.delay("5s", function() return mq.TLO.Window("TradeWnd").Open() == false end)
    else
        mq.delay("5s", function() return mq.TLO.Window("GiveWnd").Open() == true end)
        mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
        mq.delay("5s", function() return mq.TLO.Window("GiveWnd").Open() == false end)
    end

    -- We're giving something to a pet. In this case if the pet gives it back,
    -- get rid of it.
    if Targeting.TargetIsType("pet") then
        mq.delay("2s")
        if (mq.TLO.Cursor.ID() or 0) > 0 and mq.TLO.Cursor.NoRent() then
            Logger.log_debug("\arGiveTo Pet return item - that ingreat!")
            Core.DoCmd("/destroy")
            mq.delay("10s", function() return mq.TLO.Cursor.ID() == nil end)
        end
    end
end

--- Swaps the current bandolier set to the one specified by the index name.
--- @param indexName string The name of the bandolier set to swap to.
function ItemManager.BandolierSwap(indexName)
    if Config:GetSetting('UseBandolier') and mq.TLO.Me.Bandolier(indexName).Index() and not mq.TLO.Me.Bandolier(indexName).Active() then
        Core.DoCmd("/bandolier activate %s", indexName)
        Logger.log_debug("BandolierSwap() Swapping to %s. Current Health: %d", indexName, mq.TLO.Me.PctHPs())
    end
end

--- Swaps the specified item to the given slot.
---
--- @param slot string The slot number where the item should be placed.
--- @param item string The item to be swapped into the slot.
function ItemManager.SwapItemToSlot(slot, item)
    Logger.log_verbose("\aySwapping item %s to %s", item, slot)

    local swapItem = mq.TLO.FindItem(item)
    if not swapItem or not swapItem() then return end

    if mq.TLO.InvSlot(slot).Item.Name() == swapItem.Name() then return end

    Logger.log_verbose("\ag Found Item! Swapping item %s to %s", item, slot)

    Core.DoCmd("/itemnotify \"%s\" leftmouseup", item)
    mq.delay(100, function() return mq.TLO.Cursor() and mq.TLO.Cursor.Name() == item end)
    Core.DoCmd("/itemnotify %s leftmouseup", slot)
    mq.delay(100, function() return mq.TLO.Cursor() and mq.TLO.Cursor.Name() ~= item end)

    while mq.TLO.Cursor.ID() do
        mq.delay(1)
        Core.DoCmd("/autoinv")
    end
end

ItemManager.AutoInvItems = {}

--- Arms a 15s window to stow the summoned item id once it lands on the cursor and we're not casting.
--- @param itemId number The summoned item's template id, matched against the cursor each tick.
function ItemManager.QueueAutoInv(itemId)
    if not itemId or itemId <= 0 then return end
    ItemManager.AutoInvItems[itemId] = Globals.GetTimeMS() + 15000
end

--- Serviced every main-loop tick; polls every pending summon id (so overlapping summons each stow) which absorbs settle latency and waits out a cast.
function ItemManager.ServiceAutoInv()
    if not next(ItemManager.AutoInvItems) then return end

    local now = Globals.GetTimeMS()
    local cursorId = mq.TLO.Cursor.ID() or 0
    for itemId, deadline in pairs(ItemManager.AutoInvItems) do
        if now > deadline then
            if cursorId == itemId then
                Logger.log_debug("Autoinv window expired with %s still on cursor.", mq.TLO.Cursor())
            end
            ItemManager.AutoInvItems[itemId] = nil
        end
    end

    if cursorId > 0 and ItemManager.AutoInvItems[cursorId] and not mq.TLO.Me.Casting() then
        mq.cmd("/squelch /autoinv")
    end
end

--- Arms our own copy and tells same server+zone+instance peers to stow theirs by id over actors.
--- @param itemId number The summoned item's template id to match on each receiver's cursor.
function ItemManager.BroadcastQueueAutoInv(itemId)
    ItemManager.QueueAutoInv(itemId)
    for peer, data in pairs(Comms.PeersHeartbeats) do
        if peer ~= Comms.GetPeerName()
            and data.Data.Server == mq.TLO.EverQuest.Server()
            and data.Data.ZoneId == mq.TLO.Zone.ID()
            and data.Data.InstanceId == mq.TLO.Me.Instance() then
            Comms.SendMessage(peer, "ItemManager", "QueueAutoInv", { itemId = itemId, })
        end
    end
end

return ItemManager
