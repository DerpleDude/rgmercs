local mq      = require('mq')
local Comms   = require("utils.comms")
local Config  = require('utils.config')
local DanNet  = require('lib.dannet.helpers')
local Globals = require('utils.globals')
local Logger  = require("utils.logger")
local LuaFS   = require('lfs')
local Modules = require("utils.modules")
local Strings = require("utils.strings")

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

--- Calls fn via pcall, logging an error with logInfo context on failure.
--- Returns true (pass) when fn is nil, treating a missing condition as success.
---@param logInfo string Context string prepended to any error message.
---@param fn function? Function to call; nil is treated as a passing condition.
---@param ... any Arguments forwarded to fn.
---@return any Return value of fn, or false if fn raised an error.
function Core.SafeCallFunc(logInfo, fn, ...)
    if not fn then return true end -- no condition func == pass

    local success, ret = pcall(fn, ...)
    if not success then
        Logger.log_error("\ay%s\n\ar\t%s", logInfo, ret)
        ret = false
    end
    return ret
end

--- Returns true if running on an EMU (emulator) MacroQuest build.
---@return boolean True on EMU, false on Live.
function Core.OnEMU()
    return Globals.BuildType:lower() == "emu"
end

--- Returns true if the current server is Project Lazarus.
---@return boolean True if connected to Project Lazarus.
function Core.OnLaz()
    return Globals.CurServer:lower() == "project lazarus"
end

--- Returns true if the current server is EQ Might or Project Might.
---@return boolean True if connected to an EQ Might server.
function Core.OnMight()
    return Globals.CurServer:lower() == "eq might" or Globals.CurServer:lower() == "project might"
end

--- Returns true if a Ward of Might buff is active.
---@return boolean True if the Ward of Might buff is active.
function Core.IsWarden()
    return (mq.TLO.Me.Buff("Ward of Might").ID() or 0) > 0
end

--- Formats and executes an MQ command, logging it at debug level.
---@param cmd string Format string for the command.
---@param ... any Arguments for the format string.
function Core.DoCmd(cmd, ...)
    local formatted = cmd
    if ... ~= nil then formatted = string.format(cmd, ...) end
    Logger.log_debug("\atRGMercs \awsent MQ \amCommand\aw: >> \ag%s\aw <<", formatted)
    mq.cmd(formatted)
end

--- Broadcasts cmd to all group members in the same zone via /dga.
---@param cmd string Format string for the command.
---@param ... any Arguments for the format string.
function Core.DoGroupCmd(cmd, ...)
    local dgcmd = "/dga /if ($\\{Zone.ID} == ${Zone.ID} && $\\{Group.Leader.Name.Equal[${Group.Leader.Name}]}) "
    local formatted = cmd
    if ... ~= nil then formatted = string.format(cmd, ...) end
    formatted = dgcmd .. formatted
    Logger.log_debug("\atRGMercs \awsent MQ \amGroup Command\aw: >> \ag%s\aw <<", formatted)
    mq.cmd(formatted)
end

--- Broadcasts cmd to raid or group members in the same zone via /dga.
--- Uses raid leader if in a raid, group leader otherwise.
---@param cmd string Format string for the command.
---@param ... any Arguments for the format string.
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

--- Loads any plugins in t that are not currently loaded. When
--- reloadingUnloaded is true, logs that the plugin is being reloaded.
---@param t string[] List of plugin names to verify are loaded.
---@param reloadingUnloaded boolean? If true, treat load as a reload operation.
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

--- Unloads any plugins in t that are currently loaded (conflict removal).
--- Returns the list of plugins that were actually unloaded.
---@param t string[] List of plugin names to unload if present.
---@return string[] Names of plugins that were unloaded.
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

--- Warns if MQ2SpawnMaster is loaded but is an outdated non-RG build
--- that lacks the HasSpawn TLO field required by the Spawns module.
function Core.CheckSpawnMasterVersion()
    if mq.TLO.Plugin("MQ2SpawnMaster").IsLoaded() then
        ---@diagnostic disable-next-line: undefined-field
        if mq.TLO.SpawnMaster == nil or mq.TLO.SpawnMaster.HasSpawn == nil then
            Logger.log_warning("\ar MQ2SpawnMaster issue detected! \aw Plugin out of date or from a non-RG build! Named detection may be impeded.")
        end
    end
end

--- Returns the spawn ID of the group's designated main assist.
---@return number The spawn ID of the group main assist, or 0 if none.
function Core.GetGroupMainAssistID()
    return (mq.TLO.Group.MainAssist.ID() or 0)
end

--- Returns the clean name of the group's designated main assist.
---@return string The clean name, or "" if no main assist is set.
function Core.GetGroupMainAssistName()
    return (mq.TLO.Group.MainAssist.CleanName() or "")
end

--- Returns the spawn ID of the Nth raid main assist (1-indexed).
---@param assistNumber number Raid assist slot number (1–3).
---@return number The spawn ID, or 0 if not set.
function Core.GetRaidMainAssistID(assistNumber)
    return (mq.TLO.Raid.MainAssist(assistNumber).ID() or 0)
end

--- Returns the clean name of the Nth raid main assist (1-indexed).
---@param assistNumber number Raid assist slot number (1–3).
---@return string The clean name, or "" if not set.
function Core.GetRaidMainAssistName(assistNumber)
    return (mq.TLO.Raid.MainAssist(assistNumber).CleanName() or "")
end

--- Returns true if the character owns the named expansion.
---@param name string Expansion constant key, e.g. "EXPANSION_LEVEL_TOV".
---@return boolean True if the player has access to the expansion.
function Core.HaveExpansion(name)
    return mq.TLO.Me.HaveExpansion(Globals.Constants.ExpansionNameToID[name])
end

--- Returns true if the player's class short name matches class (case-insensitive).
---@param class string Class short name to compare, e.g. "WAR".
---@return boolean True if the player is that class.
function Core.MyClassIs(class)
    return mq.TLO.Me.Class.ShortName():lower() == class:lower()
end

--- Returns true if this character's ID matches the configured main assist.
---@return boolean True if this toon is the main assist.
function Core.IAmMA()
    return Core.GetMainAssistId() == mq.TLO.Me.ID()
end

--- Returns true if this character is set as the EQ group's Main Tank.
---@return boolean True if this toon holds the group MT slot.
function Core.IAmGroupMT()
    return (mq.TLO.Group.MainTank.ID() or 0) == mq.TLO.Me.ID()
end

--- Returns the spawn ID of the group main tank roled character.
---@return number The spawn ID, or 0 if no group main tank is set.
function Core.GetGroupTankId()
    return mq.TLO.Group.MainTank.ID() or 0
end

--- Returns the spawn ID of the configured main assist character.
---@return number The spawn ID, or 0 if no main assist is set or not found.
function Core.GetMainAssistId()
    return (Globals.MainAssist or ""):len() > 0 and mq.TLO.Spawn(string.format("PC =%s", Globals.MainAssist or "")).ID() or 0
end

--- Returns the spawn object for the configured main assist character.
---@return MQSpawn The main assist spawn, or an empty spawn if not set.
function Core.GetMainAssistSpawn()
    return Globals.MainAssist:len() > 0 and mq.TLO.Spawn(string.format("PC =%s", Globals.MainAssist)) or mq.TLO.Spawn("")
end

--- Returns true if targetId refers to a targetable, living spawn.
---@param targetId number Spawn ID to validate.
---@return boolean True if the spawn exists, is targetable, and is not dead.
function Core.ValidCombatTarget(targetId)
    if not targetId or targetId <= 0 then return false end
    local targetSpawn = mq.TLO.Spawn(string.format("targetable id %d", targetId))
    local targetCorpse = mq.TLO.Spawn(string.format("corpse id %d", targetId))
    return targetSpawn() ~= nil and not targetSpawn.Dead() and not targetCorpse()
end

--- Targets targetId and waits up to 2×ping+500 ms for buffs to populate,
--- then fires OnTargetChange on all modules.
---@param targetId number Spawn ID to target.
---@param ignoreBuffPopulation boolean? If true, don't wait for buff population.
function Core.SetTarget(targetId, ignoreBuffPopulation)
    if targetId == 0 then return end
    if targetId == mq.TLO.Target.ID() then return end

    local maxWaitBuffs = (mq.TLO.EverQuest.Ping() * 2) + 500
    Logger.log_debug("SetTarget(): Setting Target: %d (buffPopWait: %d)", targetId, ignoreBuffPopulation and 0 or maxWaitBuffs)

    mq.TLO.Spawn(targetId).DoTarget()
    mq.delay(10, function() return mq.TLO.Target.ID() == targetId end)

    if not ignoreBuffPopulation then
        mq.delay(maxWaitBuffs, function() return mq.TLO.Target.BuffsPopulated() or false end)
    end

    Logger.log_debug("SetTarget(): Set Target to: %d (buffsPopulated: %s)", targetId, Strings.BoolToColorString(mq.TLO.Target.BuffsPopulated() ~= nil))

    Modules:ExecAll("OnTargetChange", targetId)
end

--- Returns the target ID of the group or raid main assist via TLO,
--- preferring raid assist when in a raid.
---@return number Spawn ID of the assist's current target, or 0.
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

--- Returns the main assist's current HP percentage, checking group,
--- raid, actors heartbeat, DanNet, and spawn TLO in order.
---@return number HP percentage 0–100; defaults to 100 if not found.
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

--- Returns the main assist's current mana percentage, checking group,
--- raid, actors heartbeat, DanNet, and spawn TLO in order.
---@return number Mana percentage 0–100; defaults to 100 if not found.
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

--- Returns true if aaName appears in the class module's rotation AA set.
---@param aaName string Name of the AA to check.
---@return boolean True if the AA is referenced in any rotation entry.
function Core.AAUsedInRotation(aaName)
    local rotationAAs = Modules:ExecModule("Class", "GetRotationAAs")
    return rotationAAs:contains(aaName)
end

--- Returns the timestamp of the last combat mode change from the class module.
---@return number Timestamp in seconds of the last combat mode change.
function Core.GetLastCombatModeChangeTime()
    return Modules:ExecModule("Class", "GetLastCombatModeChangeTime")
end

--- Returns true if the named class-module mode is currently active.
---@param mode string Mode name to query from the class module.
---@return boolean True if the mode is active.
function Core.IsModeActive(mode)
    return Modules:ExecModule("Class", "IsModeActive", mode)
end

--- Returns true if the class module reports the character is in tank mode.
---@return boolean True if actively tanking.
function Core.IsTanking()
    return Modules:ExecModule("Class", "IsTanking")
end

--- True when a tank reposition is needed (rear hater detected, setting on, reposition can fire, and we haven't repositioned in the last 3 seconds).
---@return boolean
function Core.TankRepositionNeeded()
    return Modules:ExecModule("Movement", "TankRepositionNeeded")
end

--- Returns true if the class module reports the character is in heal mode.
---@return boolean True if actively healing.
function Core.IsHealing()
    return Modules:ExecModule("Class", "IsHealing")
end

--- Returns true if the class module reports the character is in cure mode.
---@return boolean True if actively curing.
function Core.IsCuring()
    return Modules:ExecModule("Class", "IsCuring")
end

--- Returns true if the class module reports the character is in mez mode.
---@return boolean True if actively mezzing.
function Core.IsMezzing()
    return Modules:ExecModule("Class", "IsMezzing")
end

--- Returns true if the class module reports the character is in charm mode.
---@return boolean True if actively charming.
function Core.IsCharming()
    return Modules:ExecModule("Class", "IsCharming")
end

--- Returns true if the class module reports the character is capable of mezzing.
---@return boolean True if the character has mez capability.
function Core.CanMez()
    return Modules:ExecModule("Class", "CanMez")
end

--- Returns true if the class module reports the character is capable of charming.
---@return boolean True if the character has charm capability.
function Core.CanCharm()
    return Modules:ExecModule("Class", "CanCharm")
end

--- Returns true if spell is the resolved spell of the charm ability selected in the Charm panel.
---@param spell MQSpell The resolved spell a SpellList entry's cond is given.
---@return boolean
function Core.IsSelectedCharmSpell(spell)
    return Modules:ExecModule("Charm", "IsSelectedCharmSpell", spell) == true
end

--- Returns true if a shield is equipped in the offhand slot.
---@return boolean True if the offhand item type is "Shield".
function Core.ShieldEquipped()
    return (mq.TLO.InvSlot("Offhand").Item.Type() or "") == "Shield"
end

--- Safe to skip healing this frame.
---@param priority integer? HealPriority setting: 1 Ignore, 2 Big Heal Point, 3 Main Heal Point (nil/absent treats as Ignore)
---@return boolean True if it is safe to perform non-heal actions.
function Core.OkayToNotHeal(priority)
    if not Core.IsHealing() then return true end

    if Core.IsCuring() and Modules:ExecModule("Class", "CureIsQueued") then
        Logger.log_verbose("OkayToNotHeal: We have a queued cure to process! Skipping.")
        return false
    end

    if (priority or 1) == 1 then return true end
    return not Modules:ExecModule("Class", "NeedToHeal", priority)
end

--- Safe to skip mezzing this frame.
---@param priority boolean? PriorityMez setting; false disables the mez yield entirely
---@return boolean True if it is safe to perform non-mez actions (e.g. DPS).
function Core.OkayToNotMez(priority)
    if priority == false then return true end
    if not Core.IsMezzing() then return true end
    return not Modules:ExecModule("Mez", "NeedToMez")
end

--- Safe to skip charming this frame.
---@return boolean True if it is safe to perform non-charm actions.
function Core.OkayToNotCharm()
    return not Core.IsCharming() or not Modules:ExecModule("Charm", "NeedToCharm")
end

--- True when we should pause the rotation to act on a loose charm pet.
---@return boolean True when a loose charm needs our assist.
function Core.CharmAssistNeeded()
    return Modules:ExecModule("Charm", "CharmAssistNeeded") == true
end

--- Ensure that high-priority actions aren't ignored in favor of what we are currently checking.
---@return boolean True if it is okay to run normal offensive actions.
function Core.CombatActionsCheck()
    if not Core.OkayToNotCharm() then return false end
    if Core.CharmAssistNeeded() then return false end
    if not Core.OkayToNotHeal(Config:GetSetting('HealPriority', true)) then return false end
    if not Core.OkayToNotMez(Config:GetSetting('PriorityMez')) then return false end
    if Core.TankRepositionNeeded() then return false end
    return true
end

--- Returns the resolved (ranked) spell/item/AA for action from the class module.
---@param action string Action key from the class rotation table.
---@return any The resolved action entry, or nil if not found.
function Core.GetResolvedActionMapItem(action)
    return Modules:ExecModule("Class", "GetResolvedActionMapItem", action)
end

--- Returns the class module's helpers table (named callbacks keyed by name).
---@return table<string, function> Map of helper name → function.
function Core.GetHelpers()
    return Modules:ExecModule("Class", "GetHelpers")
end

--- Safely invokes class helper name via SafeCallFunc; no-op if not defined.
---@param logInfo string Context string shown in the error log on failure.
---@param name string Key into the helpers table returned by GetHelpers.
---@param ... any Arguments forwarded to the helper function.
---@return any Return value of the helper, or nil on error/missing.
function Core.SafeCallClassHelper(logInfo, name, ...)
    local helpers = Modules:ExecModule("Class", "GetHelpers")
    if helpers and helpers[name] then
        return Core.SafeCallFunc(logInfo, helpers[name], ...)
    end
end

--- Tells the class module to issue the appropriate pet hold command.
function Core.SetPetHold()
    Modules:ExecModule("Class", "SetPetHold")
end

--- Returns the name of the current chase target from the movement module.
---@return string The chase target name, or "" if chase is disabled.
function Core.GetChaseTarget()
    return Modules:ExecModule("Movement", "GetChaseTarget")
end

--- Refreshes buff/song/blocked/pet-buff tables in Globals by re-reading every slot from TLO.
function Core.UpdateBuffs()
    Core.GetBuffTable()
    Core.GetSongTable()
    Core.GetBlockedTable()
    if Config:GetSetting('DoActorPetBuffs') then
        Core.GetPetBuffTable()
        Core.GetPetBlockedTable()
    end
end

--- Rebuilds Globals.CurrentBuffs, Globals.CurrentBuffCount, and Globals.CurrentCureEffects from all
--- active buff slots, excluding empty or zero-ID entries.
function Core.GetBuffTable()
    local buffCount = 0 --count buffs here because BuffCount member is cached, requires self target
    Globals.CurrentBuffs = {}
    Globals.CurrentCureEffects = {}

    for i = 1, mq.TLO.Me.MaxBuffSlots() do
        local buff = mq.TLO.Me.Buff(i)
        if buff() and (buff.Spell.ID() or 0) > 0 then
            table.insert(Globals.CurrentBuffs, buff.Spell.ID())
            buffCount = buffCount + 1
            if (buff.Spell.SpellType() or "") == "Detrimental" then
                local counterType = buff.Spell.CounterType() or ""
                table.insert(Globals.CurrentCureEffects, { name = buff.Spell.Name(), cureType = (counterType ~= "" and counterType ~= "None") and counterType or nil, })
            end
        end
    end
    Globals.CurrentBuffCount = buffCount
end

--- Rebuilds Globals.CurrentSongs from active song slots (20 on EMU, 30 Live).
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

--- Rebuilds Globals.CurrentBlocked from up to 60 blocked buff slots.
function Core.GetBlockedTable()
    Globals.CurrentBlocked = {}

    for i = 1, 60 do --afaik this is current max blocked buffs and that data is not exposed
        local blocked = mq.TLO.Me.BlockedBuff(i)
        if not blocked() then break end
        table.insert(Globals.CurrentBlocked, blocked.ID())
    end
end

--- Rebuilds Globals.CurrentPetBuffs from active pet buff slots if a pet exists.
function Core.GetPetBuffTable()
    Globals.CurrentPetBuffs = {}

    if mq.TLO.Me.Pet.ID() > 0 then
        for i = 1, 30 do
            local buff = mq.TLO.Me.PetBuff(i)
            if buff() and (buff.ID() or 0) > 0 then
                table.insert(Globals.CurrentPetBuffs, buff.ID())
            end
        end
    end
end

--- Rebuilds Globals.CurrentPetBlocked from up to 60 blocked pet buff slots.
function Core.GetPetBlockedTable()
    Globals.CurrentPetBlocked = {}

    if mq.TLO.Me.Pet.ID() > 0 then
        for i = 1, 60 do --afaik this is current max blocked buffs and that data is not exposed
            local blocked = mq.TLO.Me.BlockedPetBuff(i)
            if not blocked() then break end
            table.insert(Globals.CurrentPetBlocked, blocked.ID())
        end
    end
end

return Core
