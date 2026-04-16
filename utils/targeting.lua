local mq                    = require('mq')
local Config                = require('utils.config')
local Globals               = require('utils.globals')
local Core                  = require('utils.core')
local Comms                 = require("utils.comms")
local Modules               = require("utils.modules")
local Logger                = require("utils.logger")
local Strings               = require("utils.strings")
local Movement              = require("utils.movement")
local Set                   = require('mq.set')

local Targeting             = { _version = '1.0', _name = "Targeting", _author = 'Derple', }
Targeting.__index           = Targeting
Targeting.ForceNamed        = false
Targeting.ForceBurnTargetID = 0
Targeting.SafeTargetCache   = {}

function Targeting.IsNamed(spawn)
    if not spawn or not spawn() then return false end
    if (spawn.Level() or 0) < Config:GetSetting("NamedMinLevel") then return false end
    return Modules:ExecModule("Named", "IsNamed", spawn) or false
end

--- Sets the target.
--- @param targetId number The ID of the target to be set.
--- @param ignoreBuffPopulation boolean? Wait to return until buffs are populated Default: false
function Targeting.SetTarget(targetId, ignoreBuffPopulation)
    -- avoid breaking change.
    return Core.SetTarget(targetId, ignoreBuffPopulation)
end

--- Retrieves the current auto-target.
---
--- @return MQSpawn The current auto-target.
function Targeting.GetAutoTarget()
    return mq.TLO.Spawn(string.format("id %d", Globals.AutoTargetID))
end

--- Retrieves the current auto-target.
---
--- @return MQSpawn The current auto-target.
function Targeting.GetAggroTarget()
    return mq.TLO.Spawn(string.format("id %d", Globals.AggroTargetID))
end

--- Clears the current target.
---
--- This function is used to clear any selected target in the game.
function Targeting.ClearTarget()
    if Config:GetSetting('DoAutoTarget') then
        Logger.log_debug("Clearing Target")
        Globals.AutoTargetID = 0
        Globals.AutoTargetIsNamed = false
        Globals.AggroTargetID = 0
        if Globals.ForceTargetID > 0 and not Targeting.IsSpawnXTHater(Globals.ForceTargetID) then Globals.SetForcedTargetId(0) end
        Globals.ForceCombatID = 0
        if mq.TLO.Stick.Status():lower() == "on" then Movement:DoStickCmd("off") end
        if mq.TLO.Me.Combat() then Core.DoCmd("/attack off") end
        Core.DoCmd("/squelch /target clear")
        if mq.TLO.Me.XTarget(1).TargetType() ~= "Auto Hater" then Targeting.ResetXTSlot(1) end
    end
end

--- Retrieves the ID of the given target.
--- @param target MQTarget? The target whose ID is to be retrieved.
--- @return number The ID of the target.
function Targeting.GetTargetID(target)
    return (target and target.ID() or (mq.TLO.Target.ID() or 0))
end

--- Checks if the target's body type matches the specified type.
--- @param target MQTarget|MQSpawn The target whose body type is to be checked.
--- @param type string The body type to check against.
--- @return boolean True if the target's body type matches the specified type, false otherwise.
function Targeting.TargetBodyIs(target, type)
    if not target then target = mq.TLO.Target end
    if not target or not target() then return false end

    local targetBody = (target() and target.Body() and target.Body.Name()) or "none"
    return targetBody:lower() == type:lower()
end

--- Checks if the target's class is in the provided class table.
---
--- @param classTable string|table The string or table of strings containing class names to check against.
--- @param target MQTarget The class name of the target to check.
--- @return boolean True if the target's class is in the class table, false otherwise.
function Targeting.TargetClassIs(classTable, target)
    local classSet = type(classTable) == 'table' and Set.new(classTable) or Set.new({ classTable, })

    if not target then target = mq.TLO.Target end
    if not target or not target() or not target.Class() then return false end

    return classSet:contains(target.Class.ShortName() or "None")
end

--- Retrieves the level of the specified target.
---
--- @param target MQTarget? The target whose level is to be retrieved.
--- @return number The level of the target.
function Targeting.GetTargetLevel(target)
    return (target and target.Level() or (mq.TLO.Target.Level() or 0))
end

--- Calculates the distance to the specified target.
--- @param target MQTarget|MQSpawn? The target entity whose distance is to be calculated.
--- @return number The distance to the target.
function Targeting.GetTargetDistance(target)
    return (target and target.Distance3D() or (mq.TLO.Target.Distance3D() or 9999))
end

--- Calculates the vertical distance (Z-axis) to the specified target.
--- @param target MQTarget|MQSpawn? The target entity to measure the distance to.
--- @return number The vertical distance to the target.
function Targeting.GetTargetDistanceZ(target)
    return (target and target.DistanceZ() or (mq.TLO.Target.DistanceZ() or 9999))
end

--- Gets the maximum range to the specified target.
--- @param target MQSpawn|nil The target entity to measure the range to.
--- @return number The maximum range to the target.
function Targeting.GetTargetMaxRangeTo(target)
    return (target and target.MaxRangeTo() or (mq.TLO.Target.MaxRangeTo() or 15))
end

--- Retrieves the percentage of hit points (HP) remaining for the specified target.
--- @param target MQTarget|MQSpawn? The target entity whose HP percentage is to be retrieved.
--- @return number The percentage of HP remaining for the target.
function Targeting.GetTargetPctHPs(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return 0 end

    return useTarget.PctHPs() or 0
end

--- Returns the height of the target.
--- @param target MQTarget|MQSpawn? The target entity
--- @return number The distance to the target.
function Targeting.GetTargetHeight(target)
    return (target and target.Height() or (mq.TLO.Target.Height() or 0))
end

--- Retrieves the percentage of HPs for auto-targeting.
---
--- @return number The percentage of HPs for auto-targeting.
function Targeting.GetAutoTargetPctHPs()
    local autoTarget = Targeting.GetAutoTarget()
    if not autoTarget or not autoTarget() then return 0 end
    return autoTarget.PctHPs() or 0
end

--- Retrieves the level of the autotarget spawn.
---
--- @return number The level of the autotarget spawn
function Targeting.GetAutoTargetLevel()
    local autoTarget = Targeting.GetAutoTarget()
    if not autoTarget or not autoTarget() then return 0 end
    return autoTarget.Level() or 0
end

--- Checks if the specified target is dead.
--- @param target MQTarget The name or identifier of the target to check.
--- @return boolean Returns true if the target is dead, false otherwise.
function Targeting.GetTargetDead(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return true end

    return useTarget.Dead()
end

--- Checks if the specified target is in Line Of Sight.
--- @param target MQTarget The name or identifier of the target to check.
--- @return boolean Returns true if the target is in LoS, false otherwise.
function Targeting.GetTargetLOS(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return false end

    return useTarget.LineOfSight()
end

--- Returns the max distance from this spawn for you to hit it.
--- @param target MQTarget The name or identifier of the target to check.
--- @param failHigh boolean Return 999 for an invalid target, otherwise return 0.
--- @return number Returns The max distance to hit this target
function Targeting.GetMaxMeleeRange(target, failHigh)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then
        return failHigh and 999 or 0
    end

    return useTarget.MaxRangeTo() or (failHigh and 999 or 0)
end

--- Retrieves the name of the given target.
--- @param target MQTarget? The target whose name is to be retrieved.
--- @return string The name of the target.
function Targeting.GetTargetName(target)
    return (target and target.Name() or (mq.TLO.Target.Name() or ""))
end

--- Retrieves the clean name of the given target.
--- @param target MQTarget|MQSpawn? The target from which to extract the clean name.
--- @return string The clean name of the target.
function Targeting.GetTargetCleanName(target)
    return (target and target.Name() or (mq.TLO.Target.CleanName() or ""))
end

--- Retrieves the aggro percentage of the current target.
--- @return number The aggro percentage of the current target.
function Targeting.GetTargetAggroPct()
    return (mq.TLO.Target.PctAggro() or 0)
end

--- Retrieves the aggro percentage of the current autotarget.
--- @return number The aggro percentage of the current autotarget.
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

--- Determines the type of the given target.
--- @param target MQSpawn|MQTarget|groupmember? The target whose type is to be determined.
--- @return string The type of the target as a string.
function Targeting.GetTargetType(target)
    local useTarget = target
    if not useTarget then useTarget = mq.TLO.Target end
    if not useTarget or not useTarget() then return "" end

    return (useTarget.Type() or "")
end

--- Checks if the target is of the specified type.
--- @param type string The type to check against the target.
--- @param target MQSpawn|groupmember|MQTarget? The target to be checked.
--- @return boolean Returns true if the target is of the specified type, false otherwise.
function Targeting.TargetIsType(type, target)
    return Targeting.GetTargetType(target):lower() == type:lower()
end

--- @param target MQTarget|nil
--- @return boolean
function Targeting.GetTargetAggressive(target)
    return (target and target.Aggressive() or (mq.TLO.Target.Aggressive() or false))
end

--- Retrieves the percentage by which the target is slowed.
--- @return number The percentage by which the target is slowed.
function Targeting.GetTargetSlowedPct()
    -- no valid target
    if mq.TLO.Target and not mq.TLO.Target.Slowed() then return 0 end

    return (mq.TLO.Target.Slowed.SlowPct() or 0)
end

--- Determines if the player is facing the target.
--- @return boolean True if the player is facing the target, false otherwise.
function Targeting.FacingTarget()
    return math.abs((mq.TLO.Target.HeadingTo.DegreesCCW() or mq.TLO.Me.Heading.DegreesCCW()) - mq.TLO.Me.Heading.DegreesCCW()) <= 20
end

--- Retrieves the highest aggro percentage among all players.
---
--- @return number The highest aggro percentage.
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

--- Checks if the player has aggro based on a given percentage.
--- @param pct number The percentage threshold to determine if the player has aggro.
--- @return boolean Returns true if the player has aggro above the given percentage, false otherwise.
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

--- Retrieves the IDs of the top haters.
--- @param printDebug boolean?: If true, debug information will be printed.
--- @return table: A table containing the IDs of the top haters.
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

--- Retrieves the IDs of the top haters.
--- @param printDebug boolean?: If true, debug information will be printed.
--- @return table: A table containing the IDs of the top haters.
function Targeting.GetXTHaterIDs(printDebug)
    return Targeting.GetXTHaterIDsSet(printDebug):toList()
end

--- Gets the count of XTHaters.
--- @param printDebug boolean?: If true, debug information will be printed.
--- @return number: The count of XTHaters.
function Targeting.GetXTHaterCount(printDebug)
    return #Targeting.GetXTHaterIDs(printDebug)
end

--- Computes the difference in Hater IDs.
---
--- @param t table The table containing Hater IDs.
--- @param printDebug boolean? Whether to print debug information.
--- @return boolean True if there is a difference, false otherwise
function Targeting.DiffXTHaterIDs(t, printDebug)
    local oldHaterSet = Set.new(t)
    local curHaters   = Targeting.GetXTHaterIDs(printDebug)

    for _, xtargID in ipairs(curHaters) do
        Logger.log_verbose("DiffXTHaterIDs(): XT(%d) Checking list for known hater. %s", xtargID, Strings.TableToString(oldHaterSet:toList()))
        if not oldHaterSet:contains(xtargID) then return true end
    end

    return false
end

--- Computes the difference in Hater IDs.
---
--- @param t table The table containing Hater IDs.
--- @param printDebug boolean? Whether to print debug information.
--- @return boolean True if there is a difference, false otherwise
function Targeting.CrossDiffXTHaterIDs(t, printDebug)
    local oldHaterSet  = Set.new(t)
    local curHatersSet = Targeting.GetXTHaterIDsSet(printDebug)
    local curHaters    = curHatersSet:toList()


    for _, xtargID in ipairs(curHaters) do
        Logger.log_verbose("CrossDiffXTHaterIDs(): XT(%d) Checking list for known hater. %s", xtargID, Strings.TableToString(oldHaterSet:toList()))
        if not oldHaterSet:contains(xtargID) then return true end
    end

    for _, oldID in ipairs(t) do
        Logger.log_verbose("CrossDiffXTHaterIDs(): Old XT(%d) Checking list for known hater. %s", oldID, Strings.TableToString(curHaters))
        if not curHatersSet:contains(oldID) then return true end
    end


    return false
end

--- Checks if the given spawn is an XTHater.
--- @param spawnId number The ID of the spawn to check.
--- @param autoHater boolean? required to be an autohater
--- @return boolean True if the spawn is an XTHater, false otherwise.
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

--- Adds an XT by its name to the specified slot.
--- @param slot number The slot number where the XT should be added.
--- @param name string The name of the XT to be added.
function Targeting.AddXTByName(slot, name)
    if not name then return end
    local spawnToAdd = mq.TLO.Spawn("=" .. name)
    if spawnToAdd and spawnToAdd() and mq.TLO.Me.XTarget(slot).ID() ~= spawnToAdd.ID() then
        Core.DoCmd("/xtarget set %d \"%s\"", slot, name)
    end
end

--- Adds an item to a slot by its ID.
--- @param slot number The slot number where the item should be added.
--- @param id number The ID of the item to be added.
function Targeting.AddXTByID(slot, id)
    local spawnToAdd = mq.TLO.Spawn(id)
    if spawnToAdd and spawnToAdd() and spawnToAdd.Type() and mq.TLO.Me.XTarget(slot).ID() ~= spawnToAdd.ID() then
        if spawnToAdd.Type() == "PC" then
            Core.DoCmd("/xtarget set %d \"%s\"", slot, spawnToAdd.CleanName())
        else
            Core.DoCmd("/xtarget set %d \"%s\"", slot, spawnToAdd.Name())
        end
    end
end

--- Resets the specified XT slot.
--- @param slot number The slot number to reset.
function Targeting.ResetXTSlot(slot)
    Core.DoCmd("/xtarget set %d ET", slot)
    mq.delay(500, function() return (mq.TLO.Me.XTarget(slot).TargetType():lower() or "empty target") == "empty target" end)
    Core.DoCmd("/xtarget set %d autohater", slot)
end

--- Checks if a given spawn is fighting a stranger within a specified radius.
---
--- @param spawn MQSpawn The spawn object to check.
--- @param radius number The radius within which to check for strangers.
--- @return boolean Returns true if the spawn is fighting a stranger within the specified radius, false otherwise.
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

--- Checks if the given name is considered safe within the provided table.
--- @param spawnType string Type of spawn pc/pcpet/merc/etc.
--- @param name string The name to check for safety.
--- @return boolean Returns true if the name is safe, false otherwise.
function Targeting.IsSafeName(spawnType, name)
    Logger.log_verbose("IsSafeName(%s)", name)
    if mq.TLO.DanNet(name)() then
        Logger.log_verbose("IsSafeName(%s): Dannet Safe", name)
        return true
    end

    for _, n in ipairs(Config:GetSetting('AssistList')) do
        if name == n then
            Logger.log_verbose("IsSafeName(%s): OA Safe", name)
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

--- Clears the Safe Target Cache after combat.
function Targeting.ClearSafeTargetCache()
    Targeting.SafeTargetCache = {}
end

--- Checks if the target is in the same group.
function Targeting.GroupedWithTarget(target)
    local targetName = target.CleanName() or "None"
    return mq.TLO.Group.Member(targetName)() and true or false
end

function Targeting.SetForceBurn(targetId)
    if Targeting.ForceBurnTargetID == tonumber(targetId) then
        Logger.log_info("Force Burn already set to %d. Ignoring request.", Targeting.ForceBurnTargetID)
        return
    end

    Targeting.ForceBurnTargetID = tonumber(targetId) or mq.TLO.Target.ID()
    local burnNowSpawn = mq.TLO.Spawn(Targeting.ForceBurnTargetID)
    local burnName = burnNowSpawn and (burnNowSpawn() and burnNowSpawn.CleanName() or "None") or "None"
    Logger.log_info("\aoForcing Burn Now: \at%s \aw(\am%d\aw)", burnName, Targeting.ForceBurnTargetID)

    Comms.HandleAnnounce(string.format("Force Burning: %s!", burnName), Config:GetSetting('BurnAnnounceGroup'), Config:GetSetting('BurnAnnounce'),
        Config:GetSetting('AnnounceToRaidIfInRaid'))
end

function Targeting.TargetIsMA(target)
    if not (target and target()) then return false end
    return target.ID() == Core.GetMainAssistId()
end

function Targeting.TargetIsACaster(target)
    if not (target and target()) then return false end
    return Config.Constants.RGCasters:contains(target.Class.ShortName())
end

function Targeting.TargetIsAMelee(target)
    if not (target and target()) then return false end
    return Config.Constants.RGMelee:contains(target.Class.ShortName())
end

function Targeting.TargetIsATank(target)
    if not (target and target()) then return false end
    return Config.Constants.RGTank:contains(target.Class.ShortName())
end

function Targeting.TargetIsMyself(target)
    if not (target and target()) then return false end
    return target.ID() == mq.TLO.Me.ID()
end

function Targeting.MobNotLowHP(target)
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end
    if not (target and target()) then return false end

    local threshold = Globals.AutoTargetIsNamed and Config:GetSetting('NamedLowHP') or Config:GetSetting('MobLowHP')
    return Targeting.GetTargetPctHPs(target) >= threshold
end

function Targeting.MobHasLowHP(target)
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end
    if not (target and target()) then return false end

    local threshold = Globals.AutoTargetIsNamed and Config:GetSetting('NamedLowHP') or Config:GetSetting('MobLowHP')
    return threshold > Targeting.GetTargetPctHPs(target)
end

function Targeting.BigHealsNeeded(target)
    return (target.PctHPs() or 999) < Config:GetSetting('BigHealPoint')
end

function Targeting.MainHealsNeeded(target)
    return (target.PctHPs() or 999) < Config:GetSetting('MainHealPoint')
end

function Targeting.LightHealsNeeded(target)
    return (target.PctHPs() or 999) < Config:GetSetting('LightHealPoint')
end

function Targeting.GroupHealsNeeded()
    return (mq.TLO.Group.Injured(Config:GetSetting('GroupHealPoint'))() or 0) >= Config:GetSetting('GroupInjureCnt')
end

function Targeting.BigGroupHealsNeeded()
    return (mq.TLO.Group.Injured(Config:GetSetting('BigHealPoint'))() or 0) >= Config:GetSetting('GroupInjureCnt')
end

function Targeting.CheckForAutoTargetID()
    return mq.TLO.Target.ID() == Globals.AutoTargetID and { Globals.AutoTargetID, } or {}
end

function Targeting.CheckForAggroTargetID()
    return (Globals.AggroTargetID or 0) > 0 and { Globals.AggroTargetID, } or {}
end

function Targeting.InSpellRange(spell, target)
    if not spell or not spell() then return false end
    if not target then target = mq.TLO.Target() end
    local range = spell.MyRange() > 0 and spell.MyRange() or (spell.AERange() > 0 and spell.AERange() or 250)
    local distance = Targeting.GetTargetDistance(target)
    Logger.log_verbose("InSpellRange: Spell: %s (Range: %d), Target: %s (Range: %d).", spell, range, target, distance)

    return distance <= range
end

--- This function evaluates the current aggro level and allows actions based on the result.
--- @return boolean True if you have less aggro than your aggro threshold setting or have disabled aggro throttling, false otherwise
function Targeting.AggroCheckOkay()
    if not mq.TLO.Group() or (mq.TLO.Group.MainTank.ID() or 0) == mq.TLO.Me.ID() or Core.IsTanking() then return true end
    return (mq.TLO.Target.PctAggro() or 0) < Config:GetSetting('MobMaxAggro') or not Config:GetSetting('AggroThrottling')
end

function Targeting.TargetNotStunned()
    local autoTarget = Targeting.GetAutoTarget()
    if not autoTarget or not autoTarget() then return false end
    return not autoTarget.Stunned()
end

function Targeting.LostAutoTargetAggro()
    if Globals.AutoTargetID == 0 or mq.TLO.Target.ID() ~= Globals.AutoTargetID then return false end
    return mq.TLO.Me.PctAggro() < 100
end

function Targeting.HateToolsNeeded()
    if Globals.AutoTargetID == 0 or mq.TLO.Target.ID() ~= Globals.AutoTargetID then return false end
    return mq.TLO.Me.PctAggro() < 100 or (mq.TLO.Target.SecondaryPctAggro() or 0) > 60 or Globals.AutoTargetIsNamed
end

--- Checks spawn surname to check if it is a pet that has evaded other TLO checks.
--- @param spawn MQSpawn The spawn to check.
function Targeting.IsTempPet(spawn)
    if not spawn() then return false end
    local surname = spawn.Surname()
    return surname and (surname:find("'s Pet", 1, true) or surname:find("`s Pet", 1, true) or surname:find("Doppelganger", 1, true))
end

return Targeting
