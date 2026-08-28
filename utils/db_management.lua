local Comms        = require('utils.comms')
local Config       = require('utils.config')
local Globals      = require('utils.globals')
local Logger       = require('utils.logger')

local DBManagement = { _version = '1.0', _name = "DBManagement", _author = 'Derple', 'Algar', }

--- Has the given char/server/class re-read its settings and class config after its rows
--- were written externally. No-op when that character is not running that class.
--- @param charName string
--- @param server string
--- @param class string
function DBManagement.RequestReload(charName, server, class)
    if Comms.IsLocalCurrent(charName, server, class) then
        Config:ReloadConfig()
        return
    end

    local peerKey = Comms.GetPeerName(charName, server)
    local hb = Comms.GetPeerHeartbeat(peerKey)
    if hb and hb.Data and hb.Data.Class == class then
        Comms.SendMessage(peerKey, "Config", "ReloadConfig", {})
    end
end

--- Copies module settings between two char/server/class targets, and has the destination
--- pick them up in place when it is running that class.
--- @param fromName string
--- @param fromServer string
--- @param fromClass string
--- @param toName string
--- @param toServer string
--- @param toClass string
--- @param moduleName string Module name, or "All Modules".
--- @return table result { ok, sameChar, toastMessage }
function DBManagement.CopySettings(fromName, fromServer, fromClass, toName, toServer, toClass, moduleName)
    if not fromName or not toName then return { ok = false, } end

    local fromLabel = string.format("%s (%s)", fromName, fromServer)
    local toLabel   = string.format("%s (%s)", toName, toServer)

    local toCopy    = {}
    if moduleName == "All Modules" then
        for modName in pairs(Config.moduleDefaultSettings) do
            table.insert(toCopy, modName)
        end
    else
        table.insert(toCopy, moduleName)
    end

    local anyWritten   = false
    local writesQueued = false
    for _, modName in ipairs(toCopy) do
        local values = Config.Db:getAll(fromServer, fromName, fromClass, modName)
        if values and next(values) then
            if not Config.Db:setAll(toServer, toName, toClass, modName, values) then
                writesQueued = true
            end
            anyWritten = true
        end
    end

    if writesQueued then
        Logger.log_error("DB Management: copy to %s [%s] is queued -- the config database was busy; it will apply shortly, retry to load the copied settings now", toLabel, toClass)
        return { ok = false, }
    end

    if not anyWritten then
        Logger.log_error("DB Management: nothing copied -- %s [%s] has no saved %s settings", fromLabel, fromClass, moduleName)
        return { ok = false, }
    end

    DBManagement.RequestReload(toName, toServer, toClass)

    Logger.log_info("DB Management: copied %s settings from %s [%s] to %s [%s]", moduleName, fromLabel, fromClass, toLabel, toClass)

    return {
        ok           = true,
        sameChar     = fromName == toName and fromServer == toServer,
        toastMessage = string.format("Copied %s from %s [%s] to %s [%s]", moduleName, fromLabel, fromClass, toLabel, toClass),
    }
end

--- Clears saved module settings for the given char/server/class so the target rebuilds
--- its own defaults on next load. Refuses if the target is a peer currently running
--- RGMercs; reloads in place when the target is the local character.
--- @param charName string
--- @param server string
--- @param class string
--- @param moduleName string Module name, or "All Modules".
--- @return table result { ok, refusedRunning, toastMessage }
function DBManagement.ResetSettings(charName, server, class, moduleName)
    if not charName then return { ok = false, } end

    local label = string.format("%s (%s)", charName, server)

    if not Comms.IsLocalCurrent(charName, server, class) and Comms.IsCharRunning(charName, server, class) then
        Logger.log_error("DB Management: refusing to reset %s [%s] -- target is currently running RGMercs", label, class)
        return { ok = false, refusedRunning = true, }
    end

    local toReset = {}
    if moduleName == "All Modules" then
        for modName in pairs(Config.moduleDefaultSettings) do
            table.insert(toReset, modName)
        end
    else
        table.insert(toReset, moduleName)
    end

    local deletesQueued = false
    for _, modName in ipairs(toReset) do
        if not Config.Db:deleteModule(server, charName, class, modName) then
            deletesQueued = true
        end
    end

    if deletesQueued then
        Logger.log_error("DB Management: reset of %s [%s] is queued -- the config database was busy; it will apply shortly, retry to rebuild settings now", label, class)
        return { ok = false, }
    end

    DBManagement.RequestReload(charName, server, class)

    Logger.log_info("DB Management: reset %s settings for %s [%s] to defaults", moduleName, label, class)

    return {
        ok           = true,
        toastMessage = string.format("Reset %s for %s [%s] to defaults", moduleName, label, class),
    }
end

--- Deletes all settings for the given char/server/class. Refuses if the
--- target is currently running RGMercs. Removes the character row entirely
--- when no classes remain.
--- @param charName string
--- @param server string
--- @param class string
--- @return table result { ok, refusedRunning, toastMessage }
function DBManagement.DeleteSettings(charName, server, class)
    if not charName then return { ok = false, } end

    local label = string.format("%s (%s)", charName, server)

    -- Don't delete an active character's settings -- they'd save them back.
    if Comms.IsCharRunning(charName, server, class) then
        Logger.log_error("DB Management: refusing to delete %s [%s] -- target is currently running RGMercs", label, class)
        return { ok = false, refusedRunning = true, }
    end

    if not Config.Db:deleteCharacterClass(server, charName, class) then
        Logger.log_error("DB Management: delete of %s [%s] is queued -- the config database was busy; it will apply shortly", label, class)
        return { ok = false, }
    end

    if not Config.Db:characterHasAnyConfig(server, charName) then
        Config.Db:deleteCharacter(server, charName)
    end

    Logger.log_info("DB Management: deleted all settings for %s [%s]", label, class)

    return {
        ok           = true,
        toastMessage = string.format("Deleted %s [%s] from DB", label, class),
    }
end

--- Empties a shared list setting for the current server environment.
--- @param key string The setting name of the list.
--- @param label string Display name of the list, used in the log and toast.
--- @return table result { ok, toastMessage }
function DBManagement.ClearList(key, label)
    Config:SetSetting(key, {})

    Logger.log_info("DB Management: cleared shared %s for %s", label, Globals.ServerEnv)

    return {
        ok           = true,
        toastMessage = string.format("Cleared shared %s for %s", label, Globals.ServerEnv),
    }
end

return DBManagement
