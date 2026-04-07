local mq      = require('mq')
local Config  = require('utils.config')
local Globals = require('utils.globals')
local Comms   = require("utils.comms")
local Modules = require("utils.modules")
local DanNet  = require('lib.dannet.helpers')
local Logger  = require("utils.logger")
local Strings = require("utils.strings")
local LuaFS   = require('lfs')

local Core    = { _version = '1.0', _name = "Core", _author = 'Derple', }
Core.__index  = Core

--- Scans for updates in the class_configs folder.
function Core.ScanConfigDirs()
    Globals.ClassConfigDirs = {}
    local curloadedClassName = mq.TLO.Me.Class.ShortName():lower()

    local classConfigDir = Globals.ScriptDir .. "/class_configs"

    for dir in LuaFS.dir(classConfigDir) do
        if dir ~= "." and dir ~= ".." and LuaFS.attributes(classConfigDir .. "/" .. dir).mode == "directory" then
            -- scan for valid configs inside this directory.
            for file in LuaFS.dir(classConfigDir .. "/" .. dir) do
                local class = file:match("(.*)_class_config.lua")
                if class and class == curloadedClassName then
                    Logger.log_debug("Found class config: %s for class %s in directory %s", file, class, dir)
                    table.insert(Globals.ClassConfigDirs, dir)
                end
            end
        end
    end

    local customConfigFile = string.format("%s/rgmercs/class_configs", mq.configDir)
    for dir in LuaFS.dir(customConfigFile) do
        if dir ~= "." and dir ~= ".." and LuaFS.attributes(customConfigFile .. "/" .. dir).mode == "directory" then
            -- scan for valid configs inside this directory.
            for file in LuaFS.dir(customConfigFile .. "/" .. dir) do
                local class = file:match("(.*)_class_config.lua")
                if class and class == curloadedClassName then
                    Logger.log_debug("Found class config: %s for class %s in directory %s", file, class, dir)
                    table.insert(Globals.ClassConfigDirs, "Custom: " .. dir)
                end
            end
        end
    end
end

--- Safely calls a function and logs information.
---
--- @param logInfo string: Information to log before calling the function.
--- @param fn function: The function to be called safely.
--- @param ... any: Additional arguments to pass to the function.
--- @return any: Returns the result of the function call, or nil if an error occurs.
function Core.SafeCallFunc(logInfo, fn, ...)
    if not fn then return true end -- no condition func == pass

    local success, ret = pcall(fn, ...)
    if not success then
        Logger.log_error("\ay%s\n\ar\t%s", logInfo, ret)
        ret = false
    end
    return ret
end

--- Checks if the current environment is EMU (Emulator).
---
--- @return boolean True if the environment is EMU, false otherwise.
function Core.OnEMU()
    return Globals.BuildType:lower() == "emu"
end

--- Checks if the current server is Project Lazarus.
---
--- @return boolean True if the server is Project Lazarus, false otherwise.
function Core.OnLaz()
    return Globals.CurServer:lower() == "project lazarus"
end

--- Executes a given command with optional arguments.
--- @param cmd string: The command to execute.
--- @param ... any: Optional arguments for the command.
function Core.DoCmd(cmd, ...)
    local formatted = cmd
    if ... ~= nil then formatted = string.format(cmd, ...) end
    Logger.log_debug("\atRGMercs \awsent MQ \amCommand\aw: >> \ag%s\aw <<", formatted)
    mq.cmd(formatted)
end

--- Executes a group command with the provided arguments.
--- @param cmd string The command to be executed.
--- @param ... any Additional arguments for the command.
function Core.DoGroupCmd(cmd, ...)
    local dgcmd = "/dga /if ($\\{Zone.ID} == ${Zone.ID} && $\\{Group.Leader.Name.Equal[${Group.Leader.Name}]}) "
    local formatted = cmd
    if ... ~= nil then formatted = string.format(cmd, ...) end
    formatted = dgcmd .. formatted
    Logger.log_debug("\atRGMercs \awsent MQ \amGroup Command\aw: >> \ag%s\aw <<", formatted)
    mq.cmd(formatted)
end

--- Executes a group command with the provided arguments.
--- @param cmd string The command to be executed.
--- @param ... any Additional arguments for the command.
function Core.DoGroupOrRaidCmd(cmd, ...)
    local dgcmd = "/dga /if ($\\{Zone.ID} == ${Zone.ID} && $\\{Group.Leader.Name.Equal[${Group.Leader.Name}]}) "
    if mq.TLO.Raid.Members() > 0 then
        dgcmd = "/dga /if ($\\{Zone.ID} == ${Zone.ID} && $\\{Raid.Leader.Name.Equal[${Raid.Leader.Name}]}) "
    end
    local formatted = cmd
    if ... ~= nil then formatted = string.format(cmd, ...) end
    formatted = dgcmd .. formatted
    Logger.log_debug("\atRGMercs \awsent MQ \amGroup Command\aw: >> \ag%s\aw <<", formatted)
    mq.cmd(formatted)
end

--- Checks the status of plugins.
---
--- This function iterates over the provided table of plugins and performs a check on each one.
---
--- @param t table A table containing plugin information to be checked.
function Core.CheckPlugins(t, reloadingUnloaded)
    for _, p in pairs(t) do
        if not mq.TLO.Plugin(p)() then
            Core.DoCmd("/squelch /plugin %s %s", p, reloadingUnloaded and "" or "noauto")

            if reloadingUnloaded then
                Logger.log_info("\aw %s \ar is being reloaded as RGMercs is shutting down...", p)
            else
                Logger.log_info("\aw %s \ar not detected! \aw This script requires it! Loading ...", p)
            end
        end
    end
end

--- Unchecks the specified plugins.
---
--- This function iterates over the provided table `t` and unchecks each plugin listed.
---
--- @param t table A table containing the plugins to be unchecked.
function Core.UnCheckPlugins(t)
    local r = {}
    for _, p in pairs(t) do
        if mq.TLO.Plugin(p)() then
            Core.DoCmd("/squelch /plugin %s unload noauto", p)
            Logger.log_warning("\ar %s detected! \aw Unloading it due to known conflicts with RGMercs!", p)
            table.insert(r, p)
        end
    end

    return r
end

function Core.CheckSpawnMasterVersion()
    if mq.TLO.Plugin("MQ2SpawnMaster").IsLoaded() then
        ---@diagnostic disable-next-line: undefined-field
        if mq.TLO.SpawnMaster == nil or mq.TLO.SpawnMaster.HasSpawn == nil then
            Logger.log_warning("\ar MQ2SpawnMaster issue detected! \aw Plugin out of date or from a non-RG build! Named funcionality may be impeded.")
        end
    end
end

--- Retrieves the ID of the main assist in the group.
--- @return number The ID of the main assist in the group.
function Core.GetGroupMainAssistID()
    return (mq.TLO.Group.MainAssist.ID() or 0)
end

--- Retrieves the name of the main assist in the group.
--- @return string The name of the main assist in the group.
function Core.GetGroupMainAssistName()
    return (mq.TLO.Group.MainAssist.CleanName() or "")
end

--- Retrieves the ID of the selected number assist in the raid.
--- @return number The ID of the chosen assist in the raid.
function Core.GetRaidMainAssistID(assistNumber)
    return (mq.TLO.Raid.MainAssist(assistNumber).ID() or 0)
end

--- Retrieves the name of the selected number assist in the raid.
--- @return string The name of the chosesn assist in the raid.
function Core.GetRaidMainAssistName(assistNumber)
    return (mq.TLO.Raid.MainAssist(assistNumber).CleanName() or "")
end

--- Checks if the specified expansion is available.
--- @param name string The name of the expansion to check.
--- @return boolean True if the expansion is available, false otherwise.
function Core.HaveExpansion(name)
    return mq.TLO.Me.HaveExpansion(Globals.Constants.ExpansionNameToID[name])
end

--- Checks if the player's class matches the specified class.
--- @param class string The class to check against the player's class.
--- @return boolean True if the player's class matches the specified class, false otherwise.
function Core.MyClassIs(class)
    return mq.TLO.Me.Class.ShortName():lower() == class:lower()
end

--- Checks if the current character is a Main Assistant (MA).
--- @return boolean True if the character is the Main Assistant, false otherwise.
function Core.IAmMA()
    return Core.GetMainAssistId() == mq.TLO.Me.ID()
end

--- Retrieves the ID of the main assist.
---
--- @return number The ID of the main assist.
function Core.GetMainAssistId()
    return (Globals.MainAssist or ""):len() > 0 and mq.TLO.Spawn(string.format("PC =%s", Globals.MainAssist or "")).ID() or 0
end

--- Retrieves the main assist spawn.
--- @return MQSpawn The main assist spawn data.
function Core.GetMainAssistSpawn()
    return Globals.MainAssist:len() > 0 and mq.TLO.Spawn(string.format("PC =%s", Globals.MainAssist)) or mq.TLO.Spawn("")
end

function Core.GetMainAssistTargetID()
    local assistId = 0
    local heartbeat = Comms.GetPeerHeartbeatByName(Globals.MainAssist)
    local assistTarget = nil
    local assistTargetIsNamed = false

    -- if the MA has a force target, use it, and also force combat on this target (don't check aggressiveness on the MA's force target)
    if heartbeat and heartbeat.Data then
        local forceTargId = tonumber(heartbeat.Data.ForceTargetID) or 0
        if forceTargId > 0 then
            Globals.ForceCombatID = forceTargId
            assistId = forceTargId
            assistTarget = mq.TLO.Spawn(forceTargId)
            Logger.log_verbose("\atGetMainAssistTargetID\aw() \ayFindAutoTarget Assist's Forced Target via Actors :: %s (%s). Ignoring mob aggressiveness.",
                assistTarget.CleanName() or "None", forceTargId)
            if heartbeat.Data.TargetIsNamed then
                Globals.AutoTargetIsNamed = true
                assistTargetIsNamed = true
            end
        else
            -- reset force combat ID if the MA is no longer forcing that target
            Globals.ForceCombatID = 0
            local paused = heartbeat.Data.State == "Paused"
            local rawTarget = paused and heartbeat.Data.TargetID or heartbeat.Data.AutoTargetID
            local targetID = tonumber(rawTarget) or 0
            if targetID > 0 then
                assistId = targetID
                assistTarget = mq.TLO.Spawn(targetID)
                Logger.log_verbose("\atGetMainAssistTargetID\aw() \ayFindAutoTarget Assist's Target via Actors :: %s (%s)",
                    assistTarget.CleanName() or "None", targetID)
                if heartbeat.Data.TargetIsNamed then
                    Globals.AutoTargetIsNamed = true
                    assistTargetIsNamed = true
                end
            end
        end
        -- check if the MA is a dannet peer
    elseif mq.TLO.DanNet(Globals.MainAssist)() then
        local queryResult = DanNet.query(Globals.MainAssist, "Target.ID", 1000)
        if queryResult then
            assistId = tonumber(queryResult) or 0
            assistTarget = mq.TLO.Spawn(queryResult)
            Logger.log_verbose("\atGetMainAssistTargetID\aw() \ayFindAutoTarget Assist's Target via DanNet :: %s (%s)",
                assistTarget.CleanName() or "None", queryResult)
        end
        -- Check for the Group/Raid Assist Target via TLO. Don't do this if we are using assist list, the assumption is we don't *want* to assist the group/raid
    elseif not Config:GetSetting('UseAssistList') then
        assistId = Core.GetGroupOrRaidAssistTargetId()
        assistTarget = mq.TLO.Spawn(assistId)
        Logger.log_verbose("\atGetMainAssistTargetID\aw() \ayFindAutoTarget Assist's Target via Group/Raid TLO :: %s (%s)",
            assistTarget.CleanName() or "None", assistId)
    else
        -- if we cant get a target any other way, just stay on our current one if its valid, rather then constantly retargeting an MA.
        if Core.ValidCombatTarget(Globals.AutoTargetID) then
            assistId = Globals.AutoTargetID
        else
            -- otherwise, manually target the MA to get their target of target. this is a last-ditch fallback. it would be much better to let a mercs toon be the MA.
            -- compromise here is to leave all mercs toons assisting a mercs MA, but the mercs MA setting an outsider to the MA, so we aren't all targeting randomly.
            local assistSpawn = Core.GetMainAssistSpawn()
            if assistSpawn and assistSpawn() then
                Core.SetTarget(assistSpawn.ID(), true)

                assistTarget = mq.TLO.Me.TargetOfTarget
                assistId = assistTarget.ID() or 0
                Logger.log_verbose("\atGetMainAssistTargetID\aw() \ayFindAutoTarget Assist's Target via TargetOfTarget :: %s ",
                    assistTarget.CleanName() or "None")
            end
        end
    end

    return assistId, assistTargetIsNamed
end

--- Determines whether the target is valid for combat
---
--- @return boolean True if the target is present and alive, false if not.
function Core.ValidCombatTarget(targetId)
    if not targetId or targetId <= 0 then return false end
    local targetSpawn = mq.TLO.Spawn(string.format("targetable id %d", targetId))
    local targetCorpse = mq.TLO.Spawn(string.format("corpse id %d", targetId))
    return targetSpawn() ~= nil and not targetSpawn.Dead() and not targetCorpse()
end

function Core.SetTarget(targetId, ignoreBuffPopulation)
    if targetId == 0 then return end

    local maxWaitBuffs = ((mq.TLO.EverQuest.Ping() * 2) + 500)

    if targetId == mq.TLO.Target.ID() then return end
    Logger.log_debug("SetTarget(): Setting Target: %d (buffPopWait: %d)", targetId, ignoreBuffPopulation and 0 or maxWaitBuffs)
    if mq.TLO.Target.ID() ~= targetId then
        mq.TLO.Spawn(targetId).DoTarget()
        mq.delay(10, function() return mq.TLO.Target.ID() == targetId end)
        local targetBuffsPopulated = (mq.TLO.Target() and mq.TLO.Target.BuffsPopulated() or false)
        mq.delay(maxWaitBuffs, function() return (ignoreBuffPopulation or targetBuffsPopulated) end)
    end
    Logger.log_debug("SetTarget(): Set Target to: %d (buffsPopulated: %s)", targetId, Strings.BoolToColorString(mq.TLO.Target.BuffsPopulated() ~= nil))

    Modules:ExecAll("OnTargetChange", targetId)
end

--- Sets the AutoTarget to that of your group or raid MA.
function Core.GetGroupOrRaidAssistTargetId()
    local targetId = 0
    if mq.TLO.Raid.Members() > 0 then
        local assistTarg = Config:GetSetting('RaidAssistTarget')
        targetId = ((mq.TLO.Me.RaidAssistTarget(assistTarg) and mq.TLO.Me.RaidAssistTarget(assistTarg).ID()) or 0)
    elseif mq.TLO.Group.Members() > 0 then
        --- @diagnostic disable-next-line: undefined-field
        targetId = ((mq.TLO.Me.GroupAssistTarget() and mq.TLO.Me.GroupAssistTarget.ID()) or 0)
    end
    return targetId
end

--- Retrieves the percentage of hit points (HP) of the main assist.
---
--- @return number The percentage of HP of the main assist.
function Core.GetMainAssistPctHPs()
    if Globals.MainAssist:len() == 0 then return 100 end

    local groupMember = mq.TLO.Group.Member(Globals.MainAssist)
    if groupMember and groupMember() then
        return groupMember.PctHPs() or 100
    end

    local raidMember = mq.TLO.Raid.Member(Globals.MainAssist)
    if raidMember and raidMember() then
        return raidMember.PctHPs() or 100
    end

    local heartbeat = Comms.GetPeerHeartbeatByName(Globals.MainAssist)
    if heartbeat and heartbeat.Data and heartbeat.Data.HPs then
        local hpPct = tonumber(heartbeat.Data.HPs)
        if hpPct and type(hpPct) == 'number' then
            return hpPct
        end
    end

    local ret = tonumber(DanNet.query(Globals.MainAssist, "Me.PctHPs", 1000))

    if ret and type(ret) == 'number' then return ret end

    return mq.TLO.Spawn(string.format("PC =%s", Globals.MainAssist)).PctHPs() or 100
end

--- Retrieves the percentage of mana (MP) of the main assist.
---
--- @return number The percentage of MP of the main assist.
function Core.GetMainAssistPctMana()
    if Globals.MainAssist:len() == 0 then return 100 end

    local groupMember = mq.TLO.Group.Member(Globals.MainAssist)
    if groupMember and groupMember() then
        return groupMember.PctMana() or 100
    end

    local raidMember = mq.TLO.Raid.Member(Globals.MainAssist)
    if raidMember and raidMember() then
        return raidMember.PctMana() or 100
    end

    local heartbeat = Comms.GetPeerHeartbeatByName(Globals.MainAssist)
    if heartbeat and heartbeat.Data and heartbeat.Data.Mana then
        local manaPct = tonumber(heartbeat.Data.Mana)
        if manaPct and type(manaPct) == 'number' then
            return manaPct
        end
    end

    local ret = tonumber(DanNet.query(Globals.MainAssist, "Me.PctHPs", 1000))

    if ret and type(ret) == 'number' then return ret end

    return mq.TLO.Spawn(string.format("PC =%s", Globals.MainAssist)).PctHPs() or 100
end

function Core.AAUsedInRotation(aaName)
    local rotationAAs = Modules:ExecModule("Class", "GetRotationAAs")
    return rotationAAs:contains(aaName)
end

function Core.GetLastCombatModeChangeTime(aaName)
    return Modules:ExecModule("Class", "GetLastCombatModeChangeTime")
end

--- Checks if a given mode is active.
--- @param mode string The mode to check.
--- @return boolean Returns true if the mode is active, false otherwise.
function Core.IsModeActive(mode)
    return Modules:ExecModule("Class", "IsModeActive", mode)
end

--- Checks if the character is currently tanking.
--- @return boolean True if the character is tanking, false otherwise.
function Core.IsTanking()
    return Modules:ExecModule("Class", "IsTanking")
end

--- Checks if the current character is performing a healing action.
--- @return boolean True if the character is healing, false otherwise.
function Core.IsHealing()
    return Modules:ExecModule("Class", "IsHealing")
end

--- Checks if the curing process is active.
--- @return boolean True if curing is active, false otherwise.
function Core.IsCuring()
    return Modules:ExecModule("Class", "IsCuring")
end

--- Checks if the character is currently mezzing.
--- @return boolean True if the character is mezzing, false otherwise.
function Core.IsMezzing()
    return Modules:ExecModule("Class", "IsMezzing")
end

--- Checks if the character is currently charming.
--- @return boolean True if the character is charming, false otherwise.
function Core.IsCharming()
    return Modules:ExecModule("Class", "IsCharming")
end

--- Determines if the character can perform a mez (mesmerize) action.
--- @return boolean True if the character can mez, false otherwise.
function Core.CanMez()
    return Modules:ExecModule("Class", "CanMez")
end

--- Checks if the character can charm.
--- @return boolean True if the character can charm, false otherwise.
function Core.CanCharm()
    return Modules:ExecModule("Class", "CanCharm")
end

--- Checks if the shield is equipped.
--- @return boolean True if the shield is equipped, false otherwise.
function Core.ShieldEquipped()
    return mq.TLO.InvSlot("Offhand").Item.Type() and mq.TLO.InvSlot("Offhand").Item.Type() == "Shield"
end

--- Checks if a health is not critically low or a cure is not queued before a healer performs other actions.
function Core.OkayToNotHeal()
    if not Core.IsHealing() then return true end

    if Core.IsCuring() and Modules:ExecModule("Class", "CureIsQueued") then
        Logger.log_verbose("OkayToNotHeal: We have a queued cure to process! Skipping.")
        return false
    end
    return (mq.TLO.Group.Injured(Config:GetSetting('BigHealPoint'))() or 0) == 0
end

--- Retrieves the resolved action map item for a given action.
--- @param action string The action for which to retrieve the resolved map item.
--- @return any The resolved action map item corresponding to the given action.
function Core.GetResolvedActionMapItem(action)
    return Modules:ExecModule("Class", "GetResolvedActionMapItem", action)
end

function Core.ProcessCureChecks()
    Modules:ExecModule("Class", "DoEvents")
end

function Core.SetPetHold()
    Modules:ExecModule("Class", "SetPetHold")
end

function Core.GetChaseTarget()
    return Modules:ExecModule("Movement", "GetChaseTarget")
end

function Core.UpdateBuffs()
    Core.GetBuffTable()
    Core.GetSongTable()
    Core.GetBlockedTable()
    if Config:GetSetting('DoActorPetBuffs') then
        Core.GetPetBuffTable()
        Core.GetPetBlockedTable()
    end
end

function Core.GetBuffTable()
    Globals.CurrentBuffs = {}

    for i = 1, mq.TLO.Me.MaxBuffSlots() do
        local buff = mq.TLO.Me.Buff(i)
        if buff() and (buff.Spell.ID() or 0) > 0 then
            table.insert(Globals.CurrentBuffs, buff.Spell.ID())
        end
    end
end

function Core.GetSongTable()
    Globals.CurrentSongs = {}
    local songSlots = Core.OnEMU() and 20 or 30

    for i = 1, songSlots do
        local song = mq.TLO.Me.Song(i)
        if song() and (song.Spell.ID() or 0) > 0 then
            table.insert(Globals.CurrentSongs, song.Spell.ID())
        end
    end
end

function Core.GetBlockedTable()
    Globals.CurrentBlocked = {}

    for i = 1, 60 do --afaik this is current max blocked buffs and that data is not exposed
        local blocked = mq.TLO.Me.BlockedBuff(i)
        if not blocked() then break end
        table.insert(Globals.CurrentBlocked, blocked.ID())
    end
end

function Core.GetPetBuffTable()
    Logger.log_debug("Pet Buff Start")
    Globals.CurrentPetBuffs = {}

    if mq.TLO.Me.Pet.ID() > 0 then
        for i = 1, 30 do
            local buff = mq.TLO.Me.PetBuff(i)
            if buff() and (buff.ID() or 0) > 0 then
                table.insert(Globals.CurrentPetBuffs, buff.ID())
            end
        end
    end
    Logger.log_debug("Pet Buff Finish")
end

function Core.GetPetBlockedTable()
    Logger.log_debug("Pet Block Start")
    Globals.CurrentPetBlocked = {}

    if mq.TLO.Me.Pet.ID() > 0 then
        for i = 1, 60 do --afaik this is current max blocked buffs and that data is not exposed
            local blocked = mq.TLO.Me.BlockedPetBuff(i)
            if not blocked() then break end
            table.insert(Globals.CurrentPetBlocked, blocked.ID())
        end
    end
    Logger.log_debug("Pet Block Finish")
end

return Core
