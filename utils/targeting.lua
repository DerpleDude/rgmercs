local mq                        = require('mq')
local Set                       = require('mq.set')
local Comms                     = require("utils.comms")
local Config                    = require('utils.config')
local Core                      = require('utils.core')
local Globals                   = require('utils.globals')
local Logger                    = require("utils.logger")
local Modules                   = require("utils.modules")
local Movement                  = require("utils.movement")
local Strings                   = require("utils.strings")

local Targeting                 = { _version = '1.0', _name = "Targeting", _author = 'Derple', }
Targeting.__index               = Targeting
Targeting.ForceNamed            = false
Targeting.ForceBurnTargetID     = 0
Targeting.SafeTargetCache       = {}
Targeting.XTClearTime           = 0
Targeting.TankingNamedCheckTime = 0
Targeting.TankingNamedFound     = false

Targeting.XTargetTypeKeywords   = {
    ["Target's Target"]      = "targetstarget",
    ["Group Tank"]           = "grouptank",
    ["Group Tank's Target"]  = "grouptanktarget",
    ["Group Assist"]         = "groupassist",
    ["Group Assist Target"]  = "groupassisttarget",
    ["Group Puller"]         = "puller",
    ["Group Puller Target"]  = "grouppullertarget",
    ["Group Mark 1"]         = "groupmark1",
    ["Group Mark 2"]         = "groupmark2",
    ["Group Mark 3"]         = "groupmark3",
    ["Raid Assist 1"]        = "raidassist1",
    ["Raid Assist 2"]        = "raidassist2",
    ["Raid Assist 3"]        = "raidassist3",
    ["Raid Assist 1 Target"] = "raidassist1target",
    ["Raid Assist 2 Target"] = "raidassist2target",
    ["Raid Assist 3 Target"] = "raidassist3target",
    ["Raid Mark 1"]          = "raidmark1",
    ["Raid Mark 2"]          = "raidmark2",
    ["Raid Mark 3"]          = "raidmark3",
    ["Pet Target"]           = "pettarget",
    ["Mercenary Target"]     = "mercenarytarget",
}

--- Returns true if spawn qualifies as a named mob per the Spawns module,
--- ignoring spawns below the NamedMinLevel config setting.
---@param spawn MQSpawn The spawn to check.
---@return boolean True if the spawn is a named mob.
function Targeting.IsNamed(spawn)
    if not spawn or not spawn() then return false end
    if (spawn.Level() or 0) < Config:GetSetting("NamedMinLevel") then return false end
    return Modules:ExecModule("Spawns", "IsNamed", spawn) or false
end

--- Returns true if spawn is barred from auto-targeting (session ignore or zone deny); force-target overrides both.
---@param spawn MQSpawn The spawn to check.
---@return boolean True if the spawn is denied.
function Targeting.IsDeniedTarget(spawn)
    local spawnId = spawn and spawn.ID() or 0
    if spawnId <= 0 then return false end
    if spawnId == Globals.ForceTargetID or spawnId == Globals.ForceCombatID then return false end
    if Globals.IgnoredTargetIDs:contains(spawnId) then return true end
    if not Globals.ZoneHasDeny then return false end
    if Globals.ZoneDenyNames[Strings.TrimSpaces(spawn.CleanName() or ""):lower()] then return true end
    return false
end

--- Id form of IsDeniedTarget; resolves the spawn only when the zone has deny entries.
---@param spawnId number Spawn ID to check.
---@return boolean True if the spawn is denied.
function Targeting.IsDeniedTargetId(spawnId)
    if (spawnId or 0) <= 0 then return false end
    if spawnId == Globals.ForceTargetID or spawnId == Globals.ForceCombatID then return false end
    if Globals.IgnoredTargetIDs:contains(spawnId) then return true end
    if not Globals.ZoneHasDeny then return false end
    return Targeting.IsDeniedTarget(mq.TLO.Spawn(spawnId))
end

--- Thin wrapper around Core.SetTarget; exists to avoid a breaking API change.
---@param targetId number Spawn ID to target.
---@param ignoreBuffPopulation boolean? If true, don't wait for buff population.
function Targeting.SetTarget(targetId, ignoreBuffPopulation)
    -- avoid breaking change.
    return Core.SetTarget(targetId, ignoreBuffPopulation)
end

--- Returns the spawn object for the current auto target ID.
---@return MQSpawn The spawn with id Globals.AutoTargetID.
function Targeting.GetAutoTarget()
    return mq.TLO.Spawn(string.format("id %d", Globals.AutoTargetID))
end

--- Returns the spawn object for the current aggro target ID.
---@return MQSpawn The spawn with id Globals.AggroTargetID.
function Targeting.GetAggroTarget()
    return mq.TLO.Spawn(string.format("id %d", Globals.AggroTargetID))
end

--- Resets AutoTargetID, AggroTargetID, ForceCombatID, stops stick, and
--- clears the in-game target. No-op when DoAutoTarget is disabled.
function Targeting.ClearTarget()
    if Config:GetSetting('DoAutoTarget') then
        Logger.log_debug("Clearing Target")
        Globals.AutoTargetID = 0
        Globals.MATargetID = 0
        Globals.AutoTargetIsNamed = false
        Globals.AutoTargetElementalImmunities = {}
        Globals.AutoTargetStatusImmunities = {}
        Globals.AggroTargetID = 0
        if Globals.ForceTargetID > 0 and not Targeting.IsSpawnXTHater(Globals.ForceTargetID) then Globals.SetForcedTargetId(0) end
        Globals.ForceCombatID = 0
        if mq.TLO.Stick.Status():lower() == "on" then Movement:DoStickCmd("off") end
        if mq.TLO.Me.Combat() then Core.DoCmd("/attack off") end
        Core.DoCmd("/squelch /target clear")
        if mq.TLO.Me.XTarget(1).TargetType() ~= "Auto Hater" then Targeting.ResetXTSlot(1) end
    end
end

--- Returns the spawn ID of target, or the current in-game target if nil.
---@param target MQTarget? The target to query; defaults to mq.TLO.Target.
---@return number The spawn ID, or 0 if no target.
function Targeting.GetTargetID(target)
    return (target and target.ID() or (mq.TLO.Target.ID() or 0))
end

--- Returns true if the target's body type name matches type (case-insensitive).
---@param target MQTarget|MQSpawn The spawn to test; defaults to current target.
---@param type string Body type name to compare against.
---@return boolean True if body type matches.
function Targeting.TargetBodyIs(target, type)
    if not target then target = mq.TLO.Target end
    if not target or not target() then return false end

    local targetBody = (target() and target.Body() and target.Body.Name()) or "none"
    return targetBody:lower() == type:lower()
end

-- Returns true if the proper body type for magician/druid anti-summoned spells
function Targeting.IsSummoned(target)
    if not target then target = mq.TLO.Target end
    if not target or not target() then return false end

    local targetBody = target.Body() and target.Body.Name() or "none"

    return targetBody:lower() == "construct" or targetBody:lower() == "undead pet"
end

--- Returns true if target's class short name is in classTable (string or array).
---@param classTable string|table Class short name or array of them to check.
---@param target MQTarget The spawn to test; defaults to current target.
---@return boolean True if the target's class matches any entry in classTable.
function Targeting.TargetClassIs(classTable, target)
    local classSet = type(classTable) == 'table' and Set.new(classTable) or Set.new({ classTable, })

    if not target then target = mq.TLO.Target end
    if not target or not target() or not target.Class() then return false end

    return classSet:contains(target.Class.ShortName() or "None")
end

--- Returns the level of target, or the current in-game target level if nil.
---@param target MQTarget? Target to query; defaults to mq.TLO.Target.
---@return number The spawn's level, or 0 if no target.
function Targeting.GetTargetLevel(target)
    return (target and target.Level() or (mq.TLO.Target.Level() or 0))
end

--- Returns the 3D distance to target, or current target distance if nil.
---@param target MQSpawn|MQTarget|string|nil? Target to measure; defaults to current target.
---@return number Distance in EQ units, or 9999 if no target.
function Targeting.GetTargetDistance(target)
    return (target and target.Distance3D() or (mq.TLO.Target.Distance3D() or 9999))
end

--- Returns the vertical (Z-axis) distance to target, or current target if nil.
---@param target MQTarget|MQSpawn? Target to measure; defaults to current target.
---@return number Z-axis distance in EQ units, or 9999 if no target.
function Targeting.GetTargetDistanceZ(target)
    return (target and target.DistanceZ() or (mq.TLO.Target.DistanceZ() or 9999))
end

--- Returns the maximum range from the player to target, or current target if nil.
---@param target MQSpawn? Target to measure; defaults to current target.
---@return number MaxRangeTo in EQ units, or 15 if no target.
function Targeting.GetTargetMaxRangeTo(target)
    return (target and target.MaxRangeTo() or (mq.TLO.Target.MaxRangeTo() or 15))
end

--- Returns the HP percentage of target, or the current in-game target if nil.
---@param target MQTarget|MQSpawn? Target to query; defaults to current target.
---@return number HP percentage 0–100, or 0 if no valid target.
function Targeting.GetTargetPctHPs(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return 0 end

    return useTarget.PctHPs() or 0
end

--- Returns the model height of target, or the current in-game target if nil.
---@param target MQTarget|MQSpawn? Target to query; defaults to current target.
---@return number Height in EQ units, or 0 if no target.
function Targeting.GetTargetHeight(target)
    return (target and target.Height() or (mq.TLO.Target.Height() or 0))
end

--- Returns the HP percentage of the current auto target, or 0 if no auto target.
---@return number HP percentage 0–100, or 0 if no auto target.
function Targeting.GetAutoTargetPctHPs()
    local autoTarget = Targeting.GetAutoTarget()
    if not autoTarget or not autoTarget() then return 0 end
    return autoTarget.PctHPs() or 0
end

--- Returns the level of the current auto target, or 0 if no auto target.
---@return number The auto target's level, or 0.
function Targeting.GetAutoTargetLevel()
    local autoTarget = Targeting.GetAutoTarget()
    if not autoTarget or not autoTarget() then return 0 end
    return autoTarget.Level() or 0
end

--- Returns true if target is dead or does not exist.
---@param target MQTarget The spawn to check; defaults to current target.
---@return boolean True if dead or no valid target.
function Targeting.GetTargetDead(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return true end

    return useTarget.Dead()
end

--- Returns true if the target is in line of sight.
---@param target MQTarget The spawn to check; defaults to current target.
---@return boolean True if the target is in LoS, false if not or no target.
function Targeting.GetTargetLOS(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return false end

    return useTarget.LineOfSight()
end

--- Returns the max melee range to target. When target is invalid,
--- returns 999 if failHigh is true, otherwise 0.
---@param target MQTarget The spawn to measure; defaults to current target.
---@param failHigh boolean Return 999 on invalid target instead of 0.
---@return number MaxRangeTo in EQ units, or 999/0 if invalid.
function Targeting.GetMaxMeleeRange(target, failHigh)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then
        return failHigh and 999 or 0
    end

    return useTarget.MaxRangeTo() or (failHigh and 999 or 0)
end

--- Returns the raw name of target, or current target's name if nil.
---@param target MQTarget? Target to query; defaults to current target.
---@return string The spawn name, or "" if no target.
function Targeting.GetTargetName(target)
    return (target and target.Name() or (mq.TLO.Target.Name() or ""))
end

--- Returns the clean (surname-stripped) name of target, or current target if nil.
---@param target MQTarget|MQSpawn? Target to query; defaults to current target.
---@return string The clean name, or "" if no target.
function Targeting.GetTargetCleanName(target)
    return (target and target.Name() or (mq.TLO.Target.CleanName() or ""))
end

--- Returns the aggro percentage the player has on the current in-game target.
---@return number Aggro percentage 0–100, or 0 if no target.
function Targeting.GetTargetAggroPct()
    return (mq.TLO.Target.PctAggro() or 0)
end

--- Returns the aggro percentage the player has on AutoTargetID, checking
--- the current target and all XTargets to find it.
---@return number Aggro percentage 0–100, or 0 if AutoTargetID is 0 or not found.
function Targeting.GetAutoTargetAggroPct()
    if Globals.AutoTargetID == 0 then return 0 end

    if mq.TLO.Target.ID() == Globals.AutoTargetID then
        return mq.TLO.Target.PctAggro() or 0
    end

    local xtCount = mq.TLO.Me.XTarget()

    for i = 1, xtCount do
        local xtSpawn = mq.TLO.Me.XTarget(i)

        if xtSpawn() and (xtSpawn.ID() or 0) == Globals.AutoTargetID then
            return xtSpawn.PctAggro() or 0
        end
    end

    return 0
end

--- Returns the spawn type string of target (e.g. "PC", "NPC"), or "" if nil.
---@param target MQSpawn|MQTarget|groupmember? Target to query; defaults to current target.
---@return string The spawn type string, or "" if no target.
function Targeting.GetTargetType(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return "" end

    return (useTarget.Type() or "")
end

--- Returns true if target's type matches type (case-insensitive).
---@param type string Spawn type to compare, e.g. "NPC", "PC".
---@param target MQSpawn|groupmember|MQTarget? Target to test; defaults to current target.
---@return boolean True if types match.
function Targeting.TargetIsType(type, target)
    return Targeting.GetTargetType(target):lower() == type:lower()
end

--- Returns the aggressive flag of target, or the current in-game target if nil.
---@param target MQTarget? Target to query; defaults to current target.
---@return boolean True if the spawn is flagged aggressive.
function Targeting.GetTargetAggressive(target)
    return (target and target.Aggressive() or (mq.TLO.Target.Aggressive() or false))
end

--- Returns the slow percentage on the current in-game target, or 0 if not slowed.
---@return number Slow percentage, or 0 if target is not slowed or has no target.
function Targeting.GetTargetSlowedPct()
    -- no valid target
    if mq.TLO.Target and not mq.TLO.Target.Slowed() then return 0 end

    return (mq.TLO.Target.Slowed.SlowPct() or 0)
end

--- Returns true if the player's heading is within 20 degrees of the target.
---@return boolean True if facing the current target.
function Targeting.FacingTarget()
    return math.abs((mq.TLO.Target.HeadingTo.DegreesCCW() or mq.TLO.Me.Heading.DegreesCCW()) - mq.TLO.Me.Heading.DegreesCCW()) <= 20
end

--- Returns the highest aggro percentage the player has across the current
--- target and all aggressive or force-targeted XTarget entries.
---@return number Highest aggro percentage 0–100.
function Targeting.GetHighestAggroPct()
    local target     = mq.TLO.Target
    local me         = mq.TLO.Me

    local highestPct = target.PctAggro() or 0

    local xtCount    = mq.TLO.Me.XTarget()

    for i = 1, xtCount do
        local xtSpawn = mq.TLO.Me.XTarget(i)

        if xtSpawn() and (xtSpawn.ID() or 0) > 0 and (xtSpawn.Aggressive() or xtSpawn.TargetType():lower() == "auto hater" or xtSpawn.ID() == Globals.ForceTargetID) then
            if xtSpawn.PctAggro() > highestPct then highestPct = xtSpawn.PctAggro() end
        end
    end

    return highestPct
end

--- Returns true if any aggressive XTarget (or the current target) shows
--- the player at or above pct aggro.
---@param pct number Aggro threshold to test against (0–100).
---@return boolean True if any tracked mob shows player aggro ≥ pct.
function Targeting.IHaveAggro(pct)
    local target = mq.TLO.Target
    local me     = mq.TLO.Me

    if (target() and (target.PctAggro() or 0) >= pct) then return true end

    local xtCount = mq.TLO.Me.XTarget()

    for i = 1, xtCount do
        local xtSpawn = mq.TLO.Me.XTarget(i)

        if xtSpawn() and (xtSpawn.ID() or 0) > 0 and (xtSpawn.Aggressive() or xtSpawn.TargetType():lower() == "auto hater" or xtSpawn.ID() == Globals.ForceTargetID) then
            if xtSpawn.PctAggro() >= pct then return true end
        end
    end

    return false
end

--- Returns true if any XT row is a named mob we currently have aggro on; result cached 1s.
---@return boolean True if we are the current aggro target of a named XT row.
function Targeting.TankingXTNamed()
    if Globals.GetTimeSeconds() - Targeting.TankingNamedCheckTime < 1 then
        return Targeting.TankingNamedFound
    end
    Targeting.TankingNamedCheckTime = Globals.GetTimeSeconds()
    Targeting.TankingNamedFound = false
    local xtCount = mq.TLO.Me.XTarget() or 0
    for i = 1, xtCount do
        local xt = mq.TLO.Me.XTarget(i)
        -- check for exactly 100% to help ensure the mob is targeting us, over 100% can indicate another is still targeted
        if xt and xt.ID() > 0 and not xt.Dead()
            and (xt.Aggressive() or (xt.TargetType() or ""):lower() == "auto hater")
            and (xt.PctAggro() or 0) == 100
            and Targeting.IsNamed(xt) then
            Targeting.TankingNamedFound = true
            break
        end
    end
    return Targeting.TankingNamedFound
end

--- Returns a Set of spawn IDs currently hating the player on XTarget.
---@param printDebug boolean? If true, logs each hater found.
---@return table Set of hater spawn IDs.
function Targeting.GetXTHaterIDsSet(printDebug)
    local xtCount = mq.TLO.Me.XTarget() or 0
    local uniqHaters = Set.new({})

    for i = 1, xtCount do
        local xtarg = mq.TLO.Me.XTarget(i)
        if xtarg and xtarg.ID() > 0 and not xtarg.Dead() and (xtarg.Type() or "Corpse") ~= "Corpse" and (xtarg.Aggressive() or (xtarg.TargetType() or ""):lower() == "auto hater" or xtarg.ID() == Globals.ForceTargetID) then
            if printDebug then
                Logger.log_verbose("GetXTHaters(): XT(%d) Counting %s(%d) as a hater.", i, xtarg.CleanName() or "None", xtarg.ID())
            end
            uniqHaters:add(xtarg.ID())
        end
    end

    return uniqHaters
end

--- Returns an array of spawn IDs currently hating the player on XTarget.
---@param printDebug boolean? If true, logs each hater found.
---@return number[] Array of hater spawn IDs.
function Targeting.GetXTHaterIDs(printDebug)
    return Targeting.GetXTHaterIDsSet(printDebug):toList()
end

--- Returns the number of spawns currently hating the player on XTarget.
---@param printDebug boolean? If true, logs each hater counted.
---@return number Count of current XTarget haters.
function Targeting.GetXTHaterCount(printDebug)
    return #Targeting.GetXTHaterIDs(printDebug)
end

--- Returns true if any XTarget hater is within range units of us.
---@param range number Distance in units to check against.
---@return boolean True if a hater is within range.
function Targeting.XTHaterInRange(range)
    local xtCount = mq.TLO.Me.XTarget() or 0

    for i = 1, xtCount do
        local xtarg = mq.TLO.Me.XTarget(i)
        if xtarg and xtarg.ID() > 0 and not xtarg.Dead() and (xtarg.Type() or "Corpse") ~= "Corpse" and (xtarg.Aggressive() or (xtarg.TargetType() or ""):lower() == "auto hater" or xtarg.ID() == Globals.ForceTargetID) then
            if (xtarg.Distance3D() or 999) <= range then return true end
        end
    end

    return false
end

--- Returns true if any current XTarget hater ID is not in t (new hater appeared).
---@param t number[] Previously known hater ID list to compare against.
---@param printDebug boolean? If true, logs each comparison.
---@return boolean True if a new hater appeared since t was captured.
function Targeting.DiffXTHaterIDs(t, printDebug)
    local oldHaterSet = Set.new(t)
    local curHaters   = Targeting.GetXTHaterIDs(printDebug)

    for _, xtargID in ipairs(curHaters) do
        if printDebug then
            Logger.log_verbose("DiffXTHaterIDs(): XT(%d) Checking list for known hater. %s", xtargID, Strings.TableToString(oldHaterSet:toList()))
        end
        if not oldHaterSet:contains(xtargID) then return true end
    end

    return false
end

--- Returns true if either list has an ID the other doesn't (any hater gained or lost).
---@param t number[] Previously known hater ID list to compare against.
---@param printDebug boolean? If true, logs each comparison.
---@return boolean True if the hater list changed in either direction.
function Targeting.CrossDiffXTHaterIDs(t, printDebug)
    local oldHaterSet  = Set.new(t)
    local curHatersSet = Targeting.GetXTHaterIDsSet(printDebug)
    local curHaters    = curHatersSet:toList()


    for _, xtargID in ipairs(curHaters) do
        if printDebug then Logger.log_verbose("CrossDiffXTHaterIDs(): XT(%d) Checking list for known hater. %s", xtargID, Strings.TableToString(oldHaterSet:toList())) end
        if not oldHaterSet:contains(xtargID) then return true end
    end

    for _, oldID in ipairs(t) do
        if printDebug then Logger.log_verbose("CrossDiffXTHaterIDs(): Old XT(%d) Checking list for known hater. %s", oldID, Strings.TableToString(curHaters)) end
        if not curHatersSet:contains(oldID) then return true end
    end


    return false
end

--- Returns true if spawnId is in the XTarget list. When autoHater is true,
--- only counts entries whose TargetType is "auto hater".
---@param spawnId number Spawn ID to look for in XTarget slots.
---@param autoHater boolean? If true, require the slot to be an auto hater.
---@return boolean True if the spawn is found in XTarget (and meets autoHater if set).
function Targeting.IsSpawnXTHater(spawnId, autoHater)
    local xtCount = mq.TLO.Me.XTarget() or 0

    for i = 1, xtCount do
        local xtarg = mq.TLO.Me.XTarget(i)
        if xtarg and xtarg.ID() == spawnId then
            if autoHater == true then
                if xtarg.TargetType():lower() == "auto hater" then
                    return true
                end
                -- if we got here then we continue iterating.
            else -- false or nil
                return true
            end
        end
    end

    return false
end

--- Sets XTarget slot to the spawn named name if the slot doesn't already hold it.
---@param slot number XTarget slot index (1–20).
---@param name string Exact spawn name to target.
function Targeting.AddXTByName(slot, name)
    if not name then return end
    local spawnToAdd = mq.TLO.Spawn("=" .. name)
    if spawnToAdd and spawnToAdd() and mq.TLO.Me.XTarget(slot).ID() ~= spawnToAdd.ID() then
        Core.DoCmd("/xtarget set %d \"%s\"", slot, name)
    end
end

--- Sets XTarget slot to the spawn with the given ID if not already set.
---@param slot number XTarget slot index (1–20).
---@param id number Spawn ID to target in the slot.
function Targeting.AddXTByID(slot, id)
    local spawnToAdd = mq.TLO.Spawn(id)
    if spawnToAdd and spawnToAdd() and spawnToAdd.Type() and mq.TLO.Me.XTarget(slot).ID() ~= spawnToAdd.ID() then
        if spawnToAdd.Type() == "PC" then
            Core.DoCmd("/xtarget set %d \"%s\"", slot, spawnToAdd.CleanName())
        else
            -- Need dirty name to differentiate which mob
            Core.DoCmd("/xtarget set %d \"%s\"", slot, spawnToAdd.Name())
        end
    end
end

--- Clears XTarget slot by setting it to Empty Target then back to autohater.
---@param slot number XTarget slot index to reset (1–20).
function Targeting.ResetXTSlot(slot)
    Core.DoCmd("/xtarget set %d ET", slot)
    mq.delay(500, function() return (mq.TLO.Me.XTarget(slot).TargetType() or "") == "Empty Target" end)
    Core.DoCmd("/xtarget set %d autohater", slot)
end

--- EMU only: when any Auto Hater XTarget slot is holding a corpse during downtime, fires #clearxtargets and restores user-configured slot types.
function Targeting.ClearStuckXTargets()
    if not Core.OnEMU() then return end
    if not Config:GetSetting('ClearStuckXTargets') then return end
    if Globals.CurrentState ~= "Downtime" then return end
    if (Globals.GetTimeMS() - (Globals.LastCombatTime or 0)) < 1000 then return end
    if (Globals.GetTimeSeconds() - Targeting.XTClearTime) < 10 then return end

    local slotCount       = mq.TLO.Me.XTargetSlots() or 20
    local stuckSlots      = {}
    local idSnap          = {}
    local populatedBefore = {}
    for i = 1, slotCount do
        local xt = mq.TLO.Me.XTarget(i)
        local tt = xt.TargetType() or ""
        local id = xt.ID() or 0
        local isCorpse = (xt.Type() or "") == "Corpse"
        if id > 0 then populatedBefore[i] = true end
        if tt == "Auto Hater" and id > 0 and isCorpse then
            stuckSlots[i] = true
        elseif (tt == "Specific PC" or tt == "Specific NPC") and id > 0 and not isCorpse then
            idSnap[i] = id
        end
    end

    if not next(stuckSlots) then return end

    Targeting.XTClearTime = Globals.GetTimeSeconds()
    Logger.log_info("ClearStuckXTargets: clearing bugged XTarget corpses via #clearxtargets.")

    Core.DoCmd("/say #clearxtargets")
    mq.delay(2000, function()
        for slot in pairs(populatedBefore) do
            if (mq.TLO.Me.XTarget(slot).ID() or 0) ~= 0 then return false end
        end
        return true
    end)

    for i = 1, slotCount do
        if idSnap[i] then
            if mq.TLO.Spawn(idSnap[i])() then
                Targeting.AddXTByID(i, idSnap[i])
                mq.delay(500, function() return (mq.TLO.Me.XTarget(i).ID() or 0) == idSnap[i] end)
            end
        else
            local tt = mq.TLO.Me.XTarget(i).TargetType() or ""
            if tt ~= "Empty Target" and tt ~= "Auto Hater" then
                local kw = Targeting.XTargetTypeKeywords[tt]
                if kw then
                    Core.DoCmd("/xtarget set %d emptytarget", i)
                    mq.delay(500, function() return (mq.TLO.Me.XTarget(i).TargetType() or "") == "Empty Target" end)
                    Core.DoCmd("/xtarget set %d %s", i, kw)
                    mq.delay(500, function() return (mq.TLO.Me.XTarget(i).TargetType() or "") == tt end)
                end
            end
        end
    end
end

--- Returns true if any PC/pet/merc within radius is assisting spawn but is
--- not in our group, raid, guild, or DanNet — meaning attacking them would
--- grief another player.
---@param spawn MQSpawn The spawn to check for cross-player fighting.
---@param radius number Search radius in EQ units.
---@return boolean True if an unfamiliar player is fighting spawn.
function Targeting.IsSpawnFightingStranger(spawn, radius)
    local searchTypes = { "PC", "PCPET", "MERCENARY", }

    for _, t in ipairs(searchTypes) do
        local count = mq.TLO.SpawnCount(string.format("%s radius %d zradius %d", t, radius, radius))()

        for i = 1, count do
            local cur_spawn = mq.TLO.NearestSpawn(i, string.format("%s radius %d zradius %d", t, radius, radius))

            if cur_spawn() and not Targeting.SafeTargetCache[cur_spawn.ID()] then
                if (cur_spawn.AssistName() or ""):len() > 0 then
                    Logger.log_verbose("My Interest: %s =? Their Interest: %s", spawn.CleanName(),
                        cur_spawn.AssistName())
                    if cur_spawn.AssistName() == spawn.Name() then
                        Logger.log_verbose("[%s] Fighting same mob as: %s Theirs: %s Ours: %s", t,
                            cur_spawn.CleanName(), cur_spawn.AssistName(), spawn.Name())
                        local checkName = cur_spawn and cur_spawn() or cur_spawn.CleanName() or "None"

                        if Targeting.TargetIsType("mercenary", cur_spawn) and cur_spawn.Owner() then checkName = cur_spawn.Owner.CleanName() end
                        if Targeting.TargetIsType("pet", cur_spawn) then checkName = cur_spawn.Master.CleanName() end

                        if not Targeting.IsSafeName("pc", checkName) then
                            Logger.log_verbose(
                                "\ar WARNING: \ax Almost attacked other PCs [%s] mob. Not attacking \aw%s\ax",
                                checkName, cur_spawn.AssistName())
                            return true
                        end
                    end
                end

                -- this is pretty expensive to calculate so lets cache it.
                Targeting.SafeTargetCache[cur_spawn.ID()] = true
            end
        end
    end

    return false
end

--- Returns true if name is a "safe" player: DanNet peer, group, raid, guild,
--- or on the AssistList config. Prevents accidentally engaging friendly players.
---@param spawnType string Spawn type for guild check query, e.g. "pc".
---@param name string Character name to verify.
---@return boolean True if the name belongs to a friendly player.
function Targeting.IsSafeName(spawnType, name)
    Logger.log_verbose("IsSafeName(%s)", name)
    if mq.TLO.DanNet(name)() then
        Logger.log_verbose("IsSafeName(%s): Dannet Safe", name)
        return true
    end

    for _, n in ipairs(Config:GetSetting('AssistList')) do
        if name == n then
            Logger.log_verbose("IsSafeName(%s): AssistList Safe", name)
            return true
        end
    end

    for _, n in ipairs(Config:GetSetting('HealList')) do
        if name == n then
            Logger.log_verbose("IsSafeName(%s): HealList Safe", name)
            return true
        end
    end

    if mq.TLO.Group.Member(name)() then
        Logger.log_verbose("IsSafeName(%s): Group Safe", name)
        return true
    end
    if mq.TLO.Raid.Member(name)() then
        Logger.log_verbose("IsSafeName(%s): Raid Safe", name)
        return true
    end

    if mq.TLO.Me.Guild() ~= nil then
        if mq.TLO.Spawn(string.format("%s =%s", spawnType, name)).Guild() == mq.TLO.Me.Guild() then
            Logger.log_verbose("IsSafeName(%s): Guild Safe", name)
            return true
        end
    end

    Logger.log_verbose("IsSafeName(%s): false", name)
    return false
end

--- Resets SafeTargetCache so IsSpawnFightingStranger re-evaluates each spawn
--- from scratch on the next call.
function Targeting.ClearSafeTargetCache()
    Targeting.SafeTargetCache = {}
end

--- Returns true if target is a member of the player's current group.
---@param target MQSpawn The spawn to check.
---@return boolean True if target is in the group.
function Targeting.GroupedWithTarget(target)
    local targetName = target.CleanName() or "None"
    return mq.TLO.Group.Member(targetName)() and true or false
end

--- Marks targetId (or current target if 0) as the force-burn target and
--- announces it to group/raid per config settings.
---@param targetId number Spawn ID to force burn; 0 uses the current target.
function Targeting.SetForceBurn(targetId)
    if Targeting.ForceBurnTargetID == tonumber(targetId) then
        Logger.log_debug("Force Burn already set to %d. Ignoring request.", Targeting.ForceBurnTargetID)
        return
    end

    Targeting.ForceBurnTargetID = tonumber(targetId) or mq.TLO.Target.ID()
    local burnNowSpawn = mq.TLO.Spawn(Targeting.ForceBurnTargetID)
    local burnName = burnNowSpawn and (burnNowSpawn() and burnNowSpawn.CleanName() or "None") or "None"
    Logger.log_info("\aoForcing Burn Now: \at%s \aw(\am%d\aw)", burnName, Targeting.ForceBurnTargetID)

    Comms.HandleAnnounce(string.format("Force Burning: %s!", burnName), Config:GetSetting('BurnAnnounceGroup'), Config:GetSetting('BurnAnnounce'),
        Config:GetSetting('AnnounceToRaidIfInRaid'))
end

--- Returns true if target's ID matches the configured main assist.
---@param target MQSpawn Spawn to compare against the main assist.
---@return boolean True if target is the main assist.
function Targeting.TargetIsMA(target)
    if not (target and target()) then return false end
    return target.ID() == Core.GetMainAssistId()
end

--- Returns true if target's class short name is in the RGCasters set.
---@param target MQSpawn Spawn to check.
---@return boolean True if the spawn is a caster class.
function Targeting.TargetIsACaster(target)
    if not (target and target()) then return false end
    return Config.Constants.RGCasters:contains(target.Class.ShortName())
end

--- Returns true if target's class short name is in the RGMelee set.
---@param target MQSpawn Spawn to check.
---@return boolean True if the spawn is a melee class.
function Targeting.TargetIsAMelee(target)
    if not (target and target()) then return false end
    return Config.Constants.RGMelee:contains(target.Class.ShortName())
end

--- Returns true if target's class short name is in the RGTank set.
---@param target MQSpawn Spawn to check.
---@return boolean True if the spawn is a tank class.
function Targeting.TargetIsATank(target)
    if not (target and target()) then return false end
    return Config.Constants.RGTank:contains(target.Class.ShortName())
end

--- Returns true if target is actively tanking: self via Core.IsTanking, a peer via its broadcast IsTanking flag, otherwise tank class or the group Main Tank.
---@param target MQSpawn Spawn to check.
---@return boolean True if the spawn is currently tanking.
function Targeting.TargetIsTanking(target)
    if not (target and target()) then return false end
    if target.ID() == mq.TLO.Me.ID() then return Core.IsTanking() end

    local heartbeat = Comms.GetPeerHeartbeatByName(target.DisplayName() or "")
    if heartbeat.Data and type(heartbeat.Data.IsTanking) == "boolean" then
        return heartbeat.Data.IsTanking
    end

    return target.Type() ~= "Pet" and (Targeting.TargetIsATank(target) or (mq.TLO.Group.MainTank.ID() or 0) == target.ID())
end

--- Returns true if target's ID matches the player's own spawn ID.
---@param target MQSpawn Spawn to compare against self.
---@return boolean True if target is the player.
function Targeting.TargetIsMyself(target)
    if not (target and target()) then return false end
    return target.ID() == mq.TLO.Me.ID()
end

--- Returns true if target's HP% is at or above the low-HP threshold
--- (uses NamedLowHP for named mobs, MobLowHP otherwise).
---@param target MQSpawn|MQTarget? Target to check; defaults to auto target.
---@return boolean True if HP is at or above the threshold.
function Targeting.MobNotLowHP(target)
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end
    if not (target and target()) then return false end

    local threshold = Globals.AutoTargetIsNamed and Config:GetSetting('NamedLowHP') or Config:GetSetting('MobLowHP')
    return Targeting.GetTargetPctHPs(target) >= threshold
end

--- Returns true if target's HP% is below the low-HP threshold
--- (uses NamedLowHP for named mobs, MobLowHP otherwise).
---@param target MQSpawn|MQTarget? Target to check; defaults to auto target.
---@return boolean True if HP is below the threshold.
function Targeting.MobHasLowHP(target)
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end
    if not (target and target()) then return false end

    local threshold = Globals.AutoTargetIsNamed and Config:GetSetting('NamedLowHP') or Config:GetSetting('MobLowHP')
    return threshold > Targeting.GetTargetPctHPs(target)
end

--- Returns true if target's HP% is below the BigHealPoint config threshold.
---@param target MQSpawn|groupmember Spawn or group member to check.
---@return boolean True if a big heal is needed.
function Targeting.BigHealsNeeded(target)
    return (target.PctHPs() or 999) < Config:GetSetting('BigHealPoint')
end

--- Returns true if target's HP% is below the MainHealPoint config threshold.
---@param target MQSpawn|groupmember Spawn or group member to check.
---@return boolean True if a main heal is needed.
function Targeting.MainHealsNeeded(target)
    return (target.PctHPs() or 999) < Config:GetSetting('MainHealPoint')
end

--- Returns true if target's HP% is below the LightHealPoint config threshold.
---@param target MQSpawn|groupmember Spawn or group member to check.
---@return boolean True if a light heal is needed.
function Targeting.LightHealsNeeded(target)
    return (target.PctHPs() or 999) < Config:GetSetting('LightHealPoint')
end

--- Returns true if at least GroupInjureCnt members are below GroupHealPoint.
---@return boolean True if a group heal is warranted.
function Targeting.GroupHealsNeeded()
    return (mq.TLO.Group.Injured(Config:GetSetting('GroupHealPoint'))() or 0) >= Config:GetSetting('GroupInjureCnt')
end

--- Returns true if at least GroupInjureCnt members are below BigHealPoint.
---@return boolean True if a big group heal is warranted.
function Targeting.BigGroupHealsNeeded()
    return (mq.TLO.Group.Injured(Config:GetSetting('BigHealPoint'))() or 0) >= Config:GetSetting('GroupInjureCnt')
end

--- Returns { AutoTargetID } if there's a valid auto-target matching the in-game target, else {}.
--- Used by rotation conditions that require being on the right target.
---@return number[]
function Targeting.CheckForAutoTargetID()
    if (Globals.AutoTargetID or 0) > 0 and mq.TLO.Target.ID() == Globals.AutoTargetID then
        return { Globals.AutoTargetID, }
    end
    return {}
end

--- Returns { AggroTargetID } if AggroTargetID is non-zero, else {}.
---@return number[]
function Targeting.CheckForAggroTargetID()
    if (Globals.AggroTargetID or 0) > 0 then
        return { Globals.AggroTargetID, }
    end
    return {}
end

--- Returns true if target is within the spell's effective range (MyRange,
--- AERange, or 250 as fallback).
---@param spell MQSpell The spell to check range for.
---@param target MQSpawn|MQTarget|string|nil? Target to measure; defaults to current target.
---@return boolean True if the target is in range.
function Targeting.InSpellRange(spell, target)
    if not spell or not spell() then return false end
    if not target then target = mq.TLO.Target() end
    local range = spell.MyRange() > 0 and spell.MyRange() or (spell.AERange() > 0 and spell.AERange() or 250)
    local distance = Targeting.GetTargetDistance(target)
    Logger.log_verbose("InSpellRange: Spell: %s (Range: %d), Target: %s (Range: %d).", spell, range, target, distance)

    return distance <= range
end

--- Returns true if it is safe to perform actions from an aggro standpoint —
--- either aggro throttling is off, the player is the tank, or aggro is below MobMaxAggro.
---@return boolean True if aggro is within acceptable limits.
function Targeting.AggroCheckOkay()
    if not mq.TLO.Group() or Core.IsTanking() then return true end
    return (mq.TLO.Target.PctAggro() or 0) < Config:GetSetting('MobMaxAggro') or not Config:GetSetting('AggroThrottling')
end

--- Returns true if the auto target exists and is not currently stunned.
---@return boolean True if there is a valid auto target and it is not stunned.
function Targeting.TargetNotStunned()
    local autoTarget = Targeting.GetAutoTarget()
    if not autoTarget or not autoTarget() then return false end
    return not autoTarget.Stunned()
end

--- Returns true if there is an auto target on the current in-game target
--- and the player's aggro percentage is below 100.
---@return boolean True if aggro is not maxed on the auto target.
function Targeting.LostAutoTargetAggro()
    if Globals.AutoTargetID == 0 or mq.TLO.Target.ID() ~= Globals.AutoTargetID then return false end
    return mq.TLO.Me.PctAggro() < 100
end

--- Returns true if hate tools should fire: aggro below 100%, secondary
--- aggro above 60%, or the auto target is a named mob.
---@return boolean True if hate generation is appropriate this frame.
function Targeting.HateToolsNeeded()
    if Globals.AutoTargetID == 0 or mq.TLO.Target.ID() ~= Globals.AutoTargetID then return false end
    if Globals.NoHateTargetIDs:contains(Globals.AutoTargetID) then return false end
    return mq.TLO.Me.PctAggro() < 100 or (mq.TLO.Target.SecondaryPctAggro() or 0) > 60 or Globals.AutoTargetIsNamed
end

--- Removes no hate target IDs whose spawns are confirmed dead.
function Targeting.PruneNoHateTargets()
    for _, id in ipairs(Globals.NoHateTargetIDs:toList()) do
        local spawn = mq.TLO.Spawn(id)
        if spawn() and (spawn.Dead() or (spawn.Type() or "") == "Corpse") then
            Logger.log_debug("PruneNoHateTargets(): %d is dead, removing from no hate targets.", id)
            Globals.NoHateTargetIDs:remove(id)
        end
    end
end

--- Returns true if spawn's surname contains "'s Pet", "`s Pet", or "Doppelganger",
--- indicating it is a temporary summoned pet rather than a proper mob.
---@param spawn MQSpawn The spawn to inspect.
---@return boolean True if the spawn appears to be a temporary pet.
function Targeting.IsTempPet(spawn)
    if not spawn() then return false end
    local surname = spawn.Surname()
    local isTempPet = false
    if surname then
        isTempPet = surname:find("'s Pet", 1, true) ~= nil or surname:find("`s Pet", 1, true) ~= nil or surname:find("Doppelganger", 1, true) ~= nil
    end
    return isTempPet
end

return Targeting
