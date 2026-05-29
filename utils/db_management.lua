local Comms   = require('utils.comms')
local Config  = require('utils.config')
local Logger  = require('utils.logger')
local Modules = require('utils.modules')

local DBManagement = { _version = '1.0', _name = "DBManagement", _author = 'Derple', 'Algar', }

--- Triggers a loadout rescan locally or on the running peer matching the given
--- char/server/class, but only if any module in modulesAffected has a setting
--- with RequiresLoadoutChange. No-op otherwise.
--- @param charName string
--- @param server string
--- @param class string
--- @param modulesAffected table List of module names that were written.
function DBManagement.RequestRescan(charName, server, class, modulesAffected)
    local needsRescan = false
    for _, modName in ipairs(modulesAffected) do
        local mDefaults = Config.moduleDefaultSettings[modName]
        if mDefaults then
            for _, def in pairs(mDefaults) do
                if def.RequiresLoadoutChange then
                    needsRescan = true
                    break
                end
            end
        end
        if needsRescan then break end
    end
    if not needsRescan then return end

    if Comms.IsLocalCurrent(charName, server, class) then
        Modules:ExecModule("Class", "RescanLoadout")
        return
    end

    local peerKey = Comms.GetPeerName(charName, server)
    local hb = Comms.GetPeerHeartbeat(peerKey)
    if hb and hb.Data and hb.Data.Class == class then
        Comms.SendMessage(peerKey, "Class", "RescanLoadout", {})
    end
end

--- Copies module settings between two char/server/class targets. Triggers a
--- rescan on the destination if appropriate.
--- @param fromName string
--- @param fromServer string
--- @param fromClass string
--- @param toName string
--- @param toServer string
--- @param toClass string
--- @param moduleName string Module name, or "All Modules".
--- @return table result { ok, modulesWritten, sameChar, toastMessage }
function DBManagement.CopySettings(fromName, fromServer, fromClass, toName, toServer, toClass, moduleName)
    if not fromName or not toName then return { ok = false, } end

    local toCopy = {}
    if moduleName == "All Modules" then
        for modName in pairs(Config.moduleDefaultSettings) do
            table.insert(toCopy, modName)
        end
    else
        table.insert(toCopy, moduleName)
    end

    local modulesWritten = {}
    for _, modName in ipairs(toCopy) do
        local values = Config.Db:getAll(fromServer, fromName, fromClass, modName)
        if values and next(values) then
            Config.Db:setAll(toServer, toName, toClass, modName, values)
            table.insert(modulesWritten, modName)
        end
    end

    DBManagement.RequestRescan(toName, toServer, toClass, modulesWritten)

    local fromLabel = string.format("%s (%s)", fromName, fromServer)
    local toLabel   = string.format("%s (%s)", toName, toServer)
    Logger.log_info("DB Management: copied %s settings from %s [%s] to %s [%s]", moduleName, fromLabel, fromClass, toLabel, toClass)

    return {
        ok             = true,
        modulesWritten = modulesWritten,
        sameChar       = fromName == toName and fromServer == toServer,
        toastMessage   = string.format("Copied %s from %s [%s] to %s [%s]", moduleName, fromLabel, fromClass, toLabel, toClass),
    }
end

--- Resets module settings to defaults for the given char/server/class.
--- Triggers a rescan if appropriate.
--- @param charName string
--- @param server string
--- @param class string
--- @param moduleName string Module name, or "All Modules".
--- @return table result { ok, modulesAffected, toastMessage }
function DBManagement.ResetSettings(charName, server, class, moduleName)
    if not charName then return { ok = false, } end

    local toReset = {}
    if moduleName == "All Modules" then
        for modName in pairs(Config.moduleDefaultSettings) do
            table.insert(toReset, modName)
        end
    else
        table.insert(toReset, moduleName)
    end

    for _, modName in ipairs(toReset) do
        local mDefaults = Config.moduleDefaultSettings[modName]
        if mDefaults then
            local defaults = {}
            for key, def in pairs(mDefaults) do
                if def.Default ~= nil then
                    defaults[key] = def.Default
                end
            end
            if next(defaults) then
                Config.Db:setAll(server, charName, class, modName, defaults)
            end
        end
    end

    DBManagement.RequestRescan(charName, server, class, toReset)

    local label = string.format("%s (%s)", charName, server)
    Logger.log_info("DB Management: reset %s settings for %s [%s] to defaults", moduleName, label, class)

    return {
        ok              = true,
        modulesAffected = toReset,
        toastMessage    = string.format("Reset %s for %s [%s] to defaults", moduleName, label, class),
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

    Config.Db:deleteCharacterClass(server, charName, class)
    if not Config.Db:characterHasAnyConfig(server, charName) then
        Config.Db:deleteCharacter(server, charName)
    end

    Logger.log_info("DB Management: deleted all settings for %s [%s]", label, class)

    return {
        ok             = true,
        refusedRunning = false,
        toastMessage   = string.format("Deleted %s [%s] from DB", label, class),
    }
end

return DBManagement
