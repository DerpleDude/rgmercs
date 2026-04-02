local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Logger    = require("utils.logger")
local Modules   = require("utils.modules")
local Math      = require("utils.math")
local Comms     = require("utils.comms")
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Set       = require('mq.set')
local Strings   = require("utils.strings")
local Movement  = require("utils.movement")
local Events    = require("utils.events")

local Combat    = { _version = '1.0', _name = "Combat", _author = 'Derple', }
Combat.__index  = Combat

-- actual combat state right now
function Combat.GetCombatState()
    return Targeting.GetXTHaterCount(true) > 0 and "Combat" or "Downtime"
end

-- this is what combat state was during the last main loop frame
function Combat.GetCachedCombatState()
    return Globals.CurrentState
end

--- This function is responsible for designating the main assist.
---
function Combat.SetMainAssist()
    local inRaid = mq.TLO.Raid.Members() > 0
    local inGroup = mq.TLO.Raid.Members() == 0 and mq.TLO.Group()

    if Config:GetSetting('UseAssistList') then
        if #Config:GetSetting('AssistList') > 0 then
            Logger.log_verbose("SetMainAssist: Checking Assist List.")
            for _, name in ipairs(Config:GetSetting('AssistList')) do
                Logger.log_verbose("SetMainAssist: Checking Assist List: %s", name)
                local listAssistSpawn = mq.TLO.Spawn(string.format("PC =%s", name))
                if listAssistSpawn() and not listAssistSpawn.Dead() then
                    local assistName = listAssistSpawn.CleanName()
                    if listAssistSpawn.ID() ~= Core.GetMainAssistId() then
                        Logger.log_info("SetMainAssist: Setting new assist to %s [%d]", assistName, listAssistSpawn.ID())
                        Globals.MainAssist = assistName or ""
                    end
                    if assistName ~= mq.TLO.Me.CleanName() then
                        Targeting.AddXTByName(2, assistName)
                    end
                    return
                end
            end
        end
    elseif inRaid then
        Logger.log_verbose("SetMainAssist: Checking Raid Assist.")
        local raidAssistSpawn = mq.TLO.Raid.MainAssist(Config:GetSetting('RaidAssistTarget'))
        if raidAssistSpawn() and raidAssistSpawn.ID() > 0 and not raidAssistSpawn.Dead() then
            if raidAssistSpawn.ID() ~= Core.GetMainAssistId() then
                Logger.log_info("SetMainAssist: Setting new assist to %s [%d]", raidAssistSpawn.CleanName(), raidAssistSpawn.ID())
                Globals.MainAssist = raidAssistSpawn.CleanName() or ""
            end
            return
        end
    elseif inGroup then
        Logger.log_verbose("SetMainAssist: Checking Group Assist.")
        local groupAssistSpawn = mq.TLO.Group.MainAssist
        if groupAssistSpawn() and groupAssistSpawn.ID() > 0 and not groupAssistSpawn.Dead() then
            if groupAssistSpawn.ID() ~= Core.GetMainAssistId() then
                Logger.log_info("SetMainAssist: Setting new assist to %s [%d]", groupAssistSpawn.CleanName(), groupAssistSpawn.ID())
                Globals.MainAssist = groupAssistSpawn.CleanName() or ""
            end
            return
        end
    else
        Combat.SetMAToSelf()
        return
    end

    -- Check to see if we should fall back to ourselves based on our current group/raid/fallback settings.
    -- If we shouldn't, clear the MA so we don't go rogue on our group/raid and mess something up.
    local fallBackCheck = { false, inGroup, inRaid, true, } -- see SelfAssistFallback setting entry
    local fallBack = Config:GetSetting('SelfAssistFallback')
    if fallBackCheck[fallBack] then
        Combat.SetMAToSelf()
    else
        Globals.MainAssist = ""
    end
end

function Combat.SetMAToSelf()
    if not Core.IAmMA() then -- only give the log message if we weren't already the MA
        Logger.log_info("SetMainAssist: No valid assists! Falling back to ourselves.")
    end
    Globals.MainAssist = mq.TLO.Me.CleanName() or ""
end

--- Engages the target specified by the given autoTargetId.
--- @param autoTargetId number The ID of the target to engage.
function Combat.EngageTarget(autoTargetId)
    if not Config:GetSetting('DoAutoEngage') then return end

    local target = mq.TLO.Target

    if (mq.TLO.Me.Feigning() or mq.TLO.Me.State():lower() == "feign") and Config:GetSetting('AutoStandFD') then
        mq.TLO.Me.Stand()
    end

    Logger.log_verbose("\awNOTICE:\ax EngageTarget(%s) Checking for valid Target.", Targeting.GetTargetCleanName())

    if target() and (target.ID() or 0) == autoTargetId and Targeting.GetTargetDistance() <= Config:GetSetting('AssistRange') then
        if (Targeting.GetTargetPctHPs() <= Config:GetSetting('AutoAssistAt') or Core.IAmMA()) and not Targeting.GetTargetDead(target) then
            if not mq.TLO.Me.Combat() then
                local classConfig = Modules:ExecModule("Class", "GetClassConfig")
                if classConfig and classConfig.HelperFunctions and classConfig.HelperFunctions.PreEngage then
                    classConfig.HelperFunctions.PreEngage(target)
                end
            end

            if Config:GetSetting('DoMelee') then
                if mq.TLO.Me.Sitting() then
                    mq.TLO.Me.Stand()
                end

                if Targeting.GetTargetDistance(target) > Targeting.GetTargetMaxRangeTo(target) then
                    Logger.log_verbose("EngageTarget(): Target is too far! %d>%d attempting to nav to it.", target.Distance3D(),
                        target.MaxRangeTo())

                    Movement:NavInCombat(autoTargetId, Targeting.GetTargetMaxRangeTo(target), false)
                else
                    Logger.log_verbose("EngageTarget(): Target is in range moving to combat")
                    if mq.TLO.Navigation.Active() then
                        Movement:DoNav(false, "stop log=off")
                    end
                    if mq.TLO.Stick.Status():lower() == "off" or (mq.TLO.Stick.StickTarget() or autoTargetId) ~= autoTargetId then
                        Movement:DoStick(autoTargetId)
                    end
                end

                if not mq.TLO.Me.Combat() then
                    Logger.log_info("\awNOTICE:\ax Engaging %s in mortal combat.", Targeting.GetTargetCleanName())
                    if Core.IAmMA() then
                        Comms.HandleAnnounce(Comms.FormatChatEvent("Tanking", Targeting.GetTargetCleanName(), "Started"), Config:GetSetting('AnnounceTargetGroup'),
                            Config:GetSetting('AnnounceTarget'), Config:GetSetting('AnnounceToRaidIfInRaid'))
                    end
                    Logger.log_debug("EngageTarget(): Attacking target!")
                    if Core.MyClassIs("ROG") and mq.TLO.Me.AbilityReady("Backstab")() then
                        local maxWait = 2000
                        while maxWait > 0 do
                            if Targeting.GetTargetDistance(target) <= Targeting.GetTargetMaxRangeTo(target) then
                                break
                            end
                            mq.delay(100)
                            Logger.log_verbose("EngageTarget(): Rogue closing distance before opening with backstab.")
                            maxWait = maxWait - 100
                        end
                        if maxWait <= 0 then Logger.log_verbose("EngageTarget(): Rogue did not close distance within two seconds, moving on.") end
                        Core.DoCmd("/doability Backstab")
                    end
                    Core.DoCmd("/attack on")
                else
                    Logger.log_verbose("EngageTarget(): Target already engaged not re-engaging.")
                end
            else
                Logger.log_verbose("\awNOTICE:\ax EngageTarget(%s) DoMelee is false.", Targeting.GetTargetCleanName())

                if not Config:GetSetting('DoMelee') and Config:GetSetting("BellyCastStick") and Globals.Constants.RGCasters:contains(mq.TLO.Me.Class.ShortName()) and target.Body.Name() == "Dragon" and Globals.AutoTargetIsNamed then
                    Logger.log_verbose("\awNOTICE:\ax EngageTarget(%s) Dragon Named detected, sticking for belly cast.", Targeting.GetTargetCleanName())
                    Movement:DoStickCmd("pin 40")
                end

                if Core.MyClassIs("RNG") and not mq.TLO.Me.AutoFire() then
                    Logger.log_verbose("\awNOTICE:\ax EngageTarget(%s) turning autofire on.", Targeting.GetTargetCleanName())
                    Core.DoCmd('/squelch face fast')
                    Core.DoCmd('/autofire on')
                end
            end
        else
            Logger.log_verbose("\awNOTICE:\ax EngageTarget(%s) Target is above Assist HP or Dead.",
                Targeting.GetTargetCleanName())
        end
    else
        Logger.log_super_verbose("\awNOTICE:\ax EngageTarget(%s) Target is not the autotarget or out of range.",
            Targeting.GetTargetCleanName())
    end
end

--- MercAssist handles the assistance logic for mercenaries.
--- This function is responsible for coordinating the actions of mercenaries to assist in combat or other tasks.
---
function Combat.MercAssist()
    mq.TLO.Window("MMGW_ManageWnd").Child("MMGW_CallForAssistButton").LeftMouseUp()
end

--- Engages the mercenaries in combat.
---
--- This function initiates the engagement process for mercenaries.
--- It is typically called when mercenaries need to start fighting.
---
function Combat.MercEngage()
    local merc = mq.TLO.Me.Mercenary

    if merc() and Targeting.GetTargetID() == Globals.AutoTargetID and Targeting.GetTargetDistance() < Config:GetSetting('AssistRange') then
        if Targeting.GetTargetPctHPs() <= Config:GetSetting('AutoAssistAt') or                         -- Hit Assist HP
            merc.Class.ShortName():lower() == "clr" or                                                 -- Cleric can engage right away
            (merc.Class.ShortName():lower() == "war" and mq.TLO.Group.MainTank.ID() == merc.ID()) then -- Merc is our Main Tank
            return true
        end
    end

    return false
end

--- Checks if combat actions should happen
--- This function handles the combat logic for the Casting module.
---
--- @return boolean True if actions should happen.
function Combat.DoCombatActions()
    if not Movement.LastMove then return false end
    if Globals.AutoTargetID == 0 then return false end
    if Targeting.GetXTHaterCount() == 0 then return false end

    -- We can't assume our target is our autotargetid for where this sub is used.
    local autoSpawn = mq.TLO.Spawn(Globals.AutoTargetID)
    if autoSpawn() and Targeting.GetTargetDistance(autoSpawn) > Config:GetSetting('AssistRange') then return false end

    return true
end

--- @param target xtarget The target spawn to validate.
--- @return boolean true if the target is valid for MATargeting, false otherwise.
function Combat.ValidMAXTarget(target)
    local spawnId = target.ID() or 0

    if spawnId <= 0 then
        Logger.log_verbose("ValidateMATarget: Invalid Spawn ID %d", spawnId)
        return false
    end

    if target.ID() > 0 and target.Dead() then
        Logger.log_verbose("ValidateMATarget: Spawn ID %d is dead", spawnId)
        return false
    end

    if target.ID() > 0 and not (target.Aggressive() or target.TargetType():lower() == "auto hater" or spawnId == Globals.ForceTargetID) then
        Logger.log_verbose("ValidateMATarget: Spawn ID %d is not aggressive or auto hater or forced (Aggressive: %s, TargetType: %s)", spawnId,
            Strings.BoolToColorString(target.Aggressive()), target.TargetType())
        return false
    end

    if Targeting.IsTempPet(target) then
        Logger.log_verbose("ValidateMATarget: Spawn ID %d is a temporary pet", spawnId)
        return false
    end

    if Globals.IgnoredTargetIDs:contains(spawnId) then
        Logger.log_verbose("ValidateMATarget: Spawn ID %d is in ignored target list", spawnId)
        return false
    end

    -- believe it or not, target can become invalid between the time we get its ID and now
    if target.ID() <= 0 then
        Logger.log_verbose("ValidateMATarget: Spawn ID %d is no longer valid", spawnId)
        return false
    end

    return true
end

--- Scans for targets within a specified radius.
---
--- @param radius number The horizontal radius to scan for targets.
--- @param zradius number The vertical radius to scan for targets.
--- @return number spawn id of the new target.
function Combat.MATargetScan(radius, zradius)
    local aggroSearch      = string.format("npc radius %d zradius %d targetable playerstate 4", radius, zradius)
    local aggroSearchPet   = string.format("npcpet radius %d zradius %d targetable playerstate 4", radius, zradius)
    local lowestHP         = 101 -- we used to initialize this as the autotarget HP, but that won't work if we are switching between trash/named...
    local highestHP        = 0   -- unless we used some convoluted logic to initialize them that is more expensive than the extra checks
    local killId           = Globals.AutoTargetID or 0
    local namedSpawn       = nil -- initialize fallback for attacking a named when we prefer trash and its the only thing left
    local preferNamed      = Globals.Constants.ScanNamedPriority[Config:GetSetting('ScanNamedPriority')] == "Named"
    local preferTrash      = Globals.Constants.ScanNamedPriority[Config:GetSetting('ScanNamedPriority')] == "Non-Named"
    local preferLowHealth  = Globals.Constants.ScanHPPriority[Config:GetSetting('ScanHPPriority')] == "Lowest HP%"
    local preferHighHealth = Globals.Constants.ScanHPPriority[Config:GetSetting('ScanHPPriority')] == "Highest HP%"
    local xtCount          = mq.TLO.Me.XTarget()

    local function TargetScanLowHealth(targetSpawn)
        if (targetSpawn.PctHPs() or 101) < lowestHP then
            Logger.log_verbose("MATargetScan \atFound Possible Target: %s :: %d --  Storing for Lowest HP Check", targetSpawn.CleanName(), targetSpawn.ID())
            lowestHP = targetSpawn.PctHPs() or 0
            killId = targetSpawn.ID() or 0
        end
    end

    local function TargetScanHighHealth(targetSpawn)
        if (targetSpawn.PctHPs() or 0) > highestHP then
            Logger.log_verbose("MATargetScan \atFound Possible Target: %s :: %d --  Storing for Highest HP Check", targetSpawn.CleanName(), targetSpawn.ID())
            highestHP = targetSpawn.PctHPs() or 101
            killId = targetSpawn.ID() or 0
        end
    end

    for i = 1, xtCount do
        local xtSpawn = mq.TLO.Me.XTarget(i)

        if xtSpawn and xtSpawn() then
            local xtName = xtSpawn.CleanName() or "Error"
            local spawnId = xtSpawn.ID() or 0

            if Combat.ValidMAXTarget(xtSpawn) then
                if not Config:GetSetting('SafeTargeting') or not Targeting.IsSpawnFightingStranger(xtSpawn, radius) then
                    Logger.log_verbose("MATargetScan Found %s [%d] Distance: %d", xtName, spawnId, xtSpawn.Distance() or 0)
                    if (xtSpawn.Distance() or 999) <= radius then
                        -- Check for lack of aggro and make sure we get the ones we haven't aggro'd. We can only get aggro data from xtargs
                        if Config:GetSetting("MAAggroScan") and mq.TLO.Me.Level() >= 20 then
                            -- Added move check to prevent false positives on the pull from things like bard song aggro. Testing. Algar 3/5/25
                            if xtSpawn.PctAggro() < 100 and not xtSpawn.Moving() and Core.IsTanking() then
                                -- Coarse check to determine if a mob is _not_ mezzed. No point in waking a mezzed mob if we don't need to.
                                if Globals.Constants.RGNotMezzedAnims:contains(xtSpawn.Animation()) then
                                    Logger.log_verbose("MATargetScan \agHave not fully aggro'd %s -- returning %s [%d]", xtName, xtName, spawnId)
                                    return spawnId
                                end
                            end
                        end

                        local spawnIsNamed = Targeting.IsNamed(xtSpawn)
                        if preferNamed and spawnIsNamed then
                            if preferLowHealth then
                                TargetScanLowHealth(xtSpawn)
                            elseif preferHighHealth then
                                TargetScanHighHealth(xtSpawn)
                            else -- We don't care. Choose... THIS ONE!
                                Logger.log_verbose("\agMATargetScan Returning: \at%d", killId)
                                return xtSpawn.ID() or 0
                            end
                            Logger.log_verbose("MATargetScan \agFound Named: %s -- returning %d", xtName, spawnId)
                        elseif preferTrash then
                            if not spawnIsNamed then -- prioritize trash
                                if preferLowHealth then
                                    TargetScanLowHealth(xtSpawn)
                                elseif preferHighHealth then
                                    TargetScanHighHealth(xtSpawn)
                                else -- We don't care. Choose... THIS ONE!
                                    Logger.log_verbose("\agMATargetScan Returning: \at%d", killId)
                                    return xtSpawn.ID() or 0
                                end
                            else -- keep this around in case its the only mob left... if we have multiple named and prefer trash, we won't sort them
                                Logger.log_verbose("MATargetScan \agFound a named to kill last: %s (%d)", xtName, spawnId)
                                namedSpawn = xtSpawn
                            end
                        else -- No preference on whether it's named or not... just sort by health.
                            if preferLowHealth then
                                TargetScanLowHealth(xtSpawn)
                            elseif preferHighHealth then
                                TargetScanHighHealth(xtSpawn)
                            else -- We don't care. Choose... THIS ONE!
                                Logger.log_verbose("\agMATargetScan Returning: \at%d", killId)
                                return spawnId
                            end
                        end
                    else
                        Logger.log_verbose("MATargetScan \ar%s distance[%d] is out of radius: %d", xtName, xtSpawn.Distance() or 0, radius)
                    end
                else
                    Logger.log_verbose("MATargetScan XTarget %s [%d] Distance: %d - is fighting someone else - ignoring it.", xtName, spawnId, xtSpawn.Distance())
                end
            end
        end
    end

    if killId == 0 then
        if namedSpawn and namedSpawn() then
            Logger.log_verbose("MATargetScan \ag%s is named, but we only have named left! -- returning %d", namedSpawn.CleanName(), namedSpawn.ID())
            killId = namedSpawn.ID()
        elseif Config:GetSetting('AreaScanFallback') then
            -- We didn't find anything to kill yet so spawn search
            Logger.log_verbose("MATargetScan Falling back on Spawn Searching")
            local aggroMobCount = mq.TLO.SpawnCount(aggroSearch)()
            local aggroMobPetCount = mq.TLO.SpawnCount(aggroSearchPet)()
            Logger.log_verbose("MATargetScan NPC Target Scan: %s ===> %d", aggroSearch, aggroMobCount)
            Logger.log_verbose("MATargetScan NPCPET Target Scan: %s ===> %d", aggroSearchPet, aggroMobPetCount)

            for i = 1, aggroMobCount do
                local spawn = mq.TLO.NearestSpawn(i, aggroSearch)

                if spawn and spawn() and not Targeting.IsTempPet(spawn) and (spawn.CleanName() or "None"):find("Guard") == nil then
                    -- If the spawn is already in combat with someone else, we should skip them.
                    if not Config:GetSetting('SafeTargeting') or not Targeting.IsSpawnFightingStranger(spawn, radius) then
                        --These are fallback checks... if we missed more than one named on XT, we are FUBAR. Let's skip the advanced logic.
                        if preferNamed and Targeting.IsNamed(spawn) then
                            Logger.log_verbose("MATargetScan DEBUG Found Named: %s -- returning %d", spawn.CleanName(), spawn.ID())
                            killId = spawn.ID() or 0
                        else
                            TargetScanLowHealth(spawn)
                        end
                    end
                end
            end

            for i = 1, aggroMobPetCount do
                local petSpawn = mq.TLO.NearestSpawn(i, aggroSearchPet)

                if not Config:GetSetting('SafeTargeting') or not Targeting.IsSpawnFightingStranger(petSpawn, radius) then
                    -- this is a fallback check, unconcerned with advanced options
                    TargetScanLowHealth(petSpawn)
                end
            end
        end
    end

    Logger.log_verbose("\agMATargetScan Returning: \at%d", killId)
    return killId
end

function Combat.TankAggroScan()
    Globals.AggroTargetID = 0

    if Globals.ForceTargetID > 0 and Config:GetSetting('AggroScanRespectFT') then
        Logger.log_verbose("TankAggroScan: Respecting the Forced Target, aborting checks.")
        return
    end

    local xtCount = mq.TLO.Me.XTarget() or 0
    local assistRange = Config:GetSetting('AssistRange')

    for i = 1, xtCount do
        local xtarg = mq.TLO.Me.XTarget(i)
        if xtarg() then
            local xtId = xtarg.ID() or 0
            if xtId > 0 and xtId ~= Globals.AutoTargetID and ((xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater")) then
                if xtarg.PctAggro() < 100 and (xtarg.Distance() or 999) <= assistRange and Globals.Constants.RGNotMezzedAnims:contains(xtarg.Animation()) then
                    if Combat.OkToEngagePreValidateId(xtId) then
                        Logger.log_verbose("TankAggroScan: Found Aggro Target: %s (id %d).", xtarg.DisplayName(), xtId)
                        Globals.AggroTargetID = xtId
                        return
                    end
                end
            end
        end
    end
    Logger.log_verbose("TankAggroScan: No Aggro Target found.")
end

--- Sets the AutoTarget to that of your group or raid MA.
function Combat.GetGroupOrRaidAssistTargetId()
    -- maintained so as to not cause a breaking change.
    return Core.GetGroupOrRaidAssistTargetId()
end

--- This will find a valid target and set it to : Globals.AutoTargetID
--- @param validateFn function? A function used to validate potential targets. Should return true for valid targets and false otherwise.
function Combat.FindBestAutoTarget(validateFn)
    Logger.log_verbose("FindAutoTarget()")

    -- Handle cases where our autotarget is no longer valid because it isn't a valid spawn or is dead.
    if Globals.AutoTargetID ~= 0 then
        if not Combat.ValidCombatTarget(Globals.AutoTargetID) then
            Logger.log_debug("\ayFindAutoTarget() : Clearing Target (%d) because it is a corpse or no longer valid.", Globals.AutoTargetID)
            Targeting.ClearTarget()
        end
    end

    -- FollowMarkTarget causes RG to have allow RG toons focus on who the group has marked. We'll exit early if this is the case.
    if Config:GetSetting('FollowMarkTarget') then
        local markNPC = mq.TLO.Me.GroupMarkNPC(1)
        if markNPC and markNPC() and markNPC.ID() > 0 and Globals.AutoTargetID ~= markNPC.ID() then
            Globals.AutoTargetID = markNPC.ID()
            Globals.AutoTargetIsNamed = Targeting.IsNamed(markNPC)
            Logger.log_debug("FindAutoTarget(): Following Marked Target: \ag%s\ax [ID: \ag%d\ax] Named(%s)", markNPC.CleanName() or "None", markNPC.ID(),
                Strings.BoolToColorString(Globals.AutoTargetIsNamed))
            return
        end
    end

    local target = mq.TLO.Target
    local targetValidated = false
    local assistTargetIsNamed = false

    -- Now handle normal situations where we need to choose a target because we don't have one.
    if Core.IAmMA() then
        Logger.log_verbose("FindAutoTarget() ==> I am MA!")
        if Globals.ForceTargetID ~= 0 then
            local forceSpawn = mq.TLO.Spawn(Globals.ForceTargetID)
            if forceSpawn and forceSpawn() and not forceSpawn.Dead() then
                if Globals.AutoTargetID ~= Globals.ForceTargetID then
                    Globals.AutoTargetID = Globals.ForceTargetID
                    Logger.log_debug("FindAutoTarget(): Forced Targeting: \ag%s\ax [ID: \ag%d\ax]", forceSpawn.CleanName() or "None", forceSpawn.ID())
                end
            else
                if mq.TLO.Me.XTarget(1).ID() == Globals.ForceTargetID then
                    Targeting.ResetXTSlot(1)
                end
                Globals.ForceTargetID = 0
            end
        else
            local targetValid = (Targeting.TargetIsType("npc", target) or Targeting.TargetIsType("npcpet", target))
                and target.Mezzed.ID() == nil and target.Charmed.ID() == nil
                and Targeting.GetTargetDistance(target) < Config:GetSetting('AssistRange')
                and Targeting.GetTargetDistanceZ(target) < 20
                and Targeting.GetTargetAggressive(target)

            -- We need to handle manual targeting and autotargeting seperately
            if not Config:GetSetting('DoAutoTarget') then
                -- Manual targeting (or pull targeting) let the manual user target any npc or npcpet.
                if Globals.AutoTargetID ~= target.ID() and targetValid then
                    Logger.log_debug("FindAutoTarget(): Targeting: \ag%s\ax [ID: \ag%d\ax]", target.CleanName() or "None", target.ID())
                    Globals.AutoTargetID = target.ID()
                end
            else
                -- If we don't have an AutoTarget and we are using the AutoTarget System:
                -- If we already have a target, we should check to see if we automatically pulled it, or if it is likely that we manually pulled it.)
                -- If not, we need to scan our nearby area and choose a target based on our built in algorithm. We
                -- only need to do this if we don't already have a target. Assume if any mob runs into camp, we shouldn't reprioritize
                -- unless specifically told.

                if Globals.AutoTargetID == 0 then
                    if Globals.LastPulledID > 0 and Targeting.IsSpawnXTHater(Globals.LastPulledID) then
                        Logger.log_verbose("It seems that we pulled %s(ID: %d), setting it as the initial AutoTarget.",
                            mq.TLO.Spawn(Globals.LastPulledID).CleanName() or "None", Globals.LastPulledID)
                        Globals.AutoTargetID = Globals.LastPulledID
                    elseif target.ID() > 0 and (target and target.Distance3D() or 0) > Targeting.GetTargetMaxRangeTo(target) and targetValid then
                        Logger.log_verbose("It seems that we manually pulled %s(ID: %d), setting it as the initial AutoTarget.", target.CleanName(), target.ID())
                        Globals.AutoTargetID = target.ID()
                    else
                        -- Set our autotarget to the target MATargetScan chooses.
                        Globals.AutoTargetID = Combat.MATargetScan(Config:GetSetting('AssistRange'),
                            Config:GetSetting('MAScanZRange'))
                        Logger.log_verbose("MATargetScan returned %d -- Setting initial AutoTarget: %s",
                            Globals.AutoTargetID, mq.TLO.Spawn(Globals.AutoTargetID).CleanName() or "None")
                    end
                elseif not Config:GetSetting('StayOnTarget') then -- rescan our auto target unless we are forced to stay on one
                    Globals.AutoTargetID = Combat.MATargetScan(Config:GetSetting('AssistRange'),
                        Config:GetSetting('MAScanZRange'))
                    local autoTarget = mq.TLO.Spawn(Globals.AutoTargetID)
                    Logger.log_verbose(
                        "Re-Targeting: MATargetScan says we need to autotarget %s [%d] -- Current Target: %s [%d]",
                        autoTarget.CleanName() or "None", Globals.AutoTargetID or 0,
                        target() and target.CleanName() or "None", target() and target.ID() or 0)
                end
            end
        end
    else
        local assistId = 0

        -- check if we are currently forcing a target, use it as the assistId to validate if so, clear the ForceTargetID if its dead.
        if Combat.ValidCombatTarget(Globals.ForceTargetID) then
            assistId = Globals.ForceTargetID
            Logger.log_verbose("\ayFindAutoTarget(): Forced target detected (%s).", Globals.ForceTargetID)
        else
            Globals.ForceTargetID = 0
        end

        -- If we have a target and are staying on target, use it (unless we have a force target)
        if Config:GetSetting('StayOnTarget') and assistId == 0 and Combat.ValidCombatTarget(Globals.AutoTargetID) then
            assistId = Globals.AutoTargetID
            Logger.log_verbose("\ayFindAutoTarget(): Stay On Target enabled, staying on our original targetid (%s).", Globals.AutoTargetID)
        end

        -- if we aren't forcing or staying on a target, then lets get an autotarget from the MA
        if assistId == 0 then
            -- We're not the main assist so we need to choose our target based on our main assist.
            -- Only change if the group main assist target is an NPC ID that doesn't match the current autotargetid. This prevents us from
            -- swapping to non-NPCs if the  MA is trying to heal/buff a friendly or themselves.

            assistId, assistTargetIsNamed = Core.GetMainAssistTargetID()
        end

        if assistId > 0 and (validateFn == nil or validateFn(assistId)) then
            targetValidated = true
            Globals.AutoTargetID = assistId
        else
            Globals.AutoTargetID = 0
            assistTargetIsNamed = false
        end
    end

    if Globals.AutoTargetID > 0 then
        Globals.AutoTargetIsNamed = assistTargetIsNamed or Targeting.IsNamed(mq.TLO.Spawn(Globals.AutoTargetID))
    end

    Logger.log_verbose("FindAutoTarget(): FoundTargetID(%d) - Named(%s), myTargetId(%d)", Globals.AutoTargetID or 0, Strings.BoolToColorString(Globals.AutoTargetIsNamed),
        mq.TLO.Target.ID())

    if Config:GetSetting('DoAutoTarget') then
        local autoTargetId = Globals.AutoTargetID or 0
        if autoTargetId > 0 and (targetValidated or (validateFn == nil or validateFn(autoTargetId))) then
            if mq.TLO.Target.ID() ~= autoTargetId then
                Targeting.SetTarget(autoTargetId)
            end

            -- For Assist Lists, this ensures we correctly and quickly receive health percent to assist in a timely manner
            -- For Emu, this helps correct for emu xtarget bugs
            -- For Force Target, this makes sure a non-aggressive mob is added to our xtargets for tracking
            -- Second dead check because targets were ocasionally dying between the validateFn and this check
            if Config:GetSetting('UseAssistList') or Core.OnEMU() or autoTargetId == Globals.ForceTargetID then
                if mq.TLO.Spawn(autoTargetId)() and not mq.TLO.Spawn(autoTargetId).Dead() and not Targeting.IsSpawnXTHater(autoTargetId) then
                    Targeting.AddXTByID(1, Globals.AutoTargetID)
                    Logger.log_verbose("FindAutoTarget(): FoundTargetID(%d) not on xt list, adding.", autoTargetId or 0)
                end
            end
        end
    end
end

--- Validates if it is acceptable to engage with a target based on its ID.
--- This function performs pre-validation checks to determine if engagement is permissible.
---
--- @param targetId number The ID of the target to be validated.
--- @return boolean Returns true if it is acceptable to engage with the target, false otherwise.
function Combat.OkToEngagePreValidateId(targetId)
    if not Config:GetSetting('DoAutoEngage') then return false end
    local target = mq.TLO.Spawn(targetId)
    local targetName = target.CleanName() or "Unknown"

    if not target() then
        Logger.log_verbose("\ayOkToEngagePrevalidate check - No Target Spawn --> Not Engaging")
        return false
    end

    if target.Dead() then
        Logger.log_verbose("\ayOkToEngagePrevalidate check for %s(ID: %d) - Target Spawn Dead --> Not Engaging", targetName, targetId)
        return false
    end

    if Globals.IgnoredTargetIDs:contains(targetId) then
        Logger.log_verbose("\ayOkToEngagePrevalidate check for %s(ID: %d) - Target is in IgnoredTargetIDs --> Not Engaging", targetName, targetId)
        return false
    end

    local pcCheck = Targeting.TargetIsType("pc", target) or (Targeting.TargetIsType("pet", target) and Targeting.TargetIsType("pc", target.Master))
    local mercCheck = Targeting.TargetIsType("mercenary", target)
    if pcCheck or mercCheck then
        Logger.log_verbose("\ayOkToEngagePrevalidate check for %s(ID: %d) - \aw[\atpcCheckFailed(%s) mercCheckFailed(%s)\aw]\ay", targetName, targetId,
            Strings.BoolToColorString(pcCheck), Strings.BoolToColorString(mercCheck))
        return false
    end

    if Config:GetSetting('SafeTargeting') and Targeting.IsSpawnFightingStranger(target, 100) then
        Logger.log_verbose("\ayOkToEngagePrevalidate check for %s(ID: %d) - Fighting Stranger --> Not Engaging", targetName, targetId)
        return false
    end

    if not Globals.BackOffFlag then
        if Core.IAmMA() then
            Logger.log_verbose("OkToEngagePrevalidate check for %s(ID: %d) - I am MA, proceeding!", targetName, targetId)
            return true
        else -- can't check HP yet, as we haven't targeted
            local distanceCheck = Targeting.GetTargetDistance(target) < Config:GetSetting('AssistRange')
            local hostileCheck = Config:GetSetting('TargetNonAggressives') or target.Aggressive()
            local forcedTarget = Globals.ForceTargetID > 0 and target.ID() == Globals.ForceTargetID
            local forcedCombat = Globals.ForceCombatID > 0 and targetId == Globals.ForceCombatID

            Logger.log_verbose("OkToEngagePrevalidate check for %s(ID: %d) - DistanceCheck(%s), HostileCheck(%s), ForcedTarget(%s), ForcedCombat(%s)", targetName, targetId,
                Strings.BoolToColorString(distanceCheck), Strings.BoolToColorString(hostileCheck), Strings.BoolToColorString(forcedTarget), Strings.BoolToColorString(forcedCombat))

            -- in range, and the mob is aggressive, the forced target, or the MA's force target
            return distanceCheck and (hostileCheck or forcedTarget or forcedCombat)
        end
    end

    Logger.log_verbose("\ayOkToEngagePrevalidate check for %s(ID: %d) - Failed with Fall Through!", targetName, targetId)
    return false
end

--- Determines if it is acceptable to engage a target.
--- @param autoTargetId number The ID of the target to check.
--- @return boolean Returns true if it is okay to engage the target, false otherwise.
function Combat.OkToEngage(autoTargetId)
    if not Config:GetSetting('DoAutoEngage') then return false end

    if autoTargetId == 0 then
        Logger.log_verbose("\ayOkToEngage check - No Auto Target to Engage --> Not Engaging")
        return false
    end

    local target = mq.TLO.Target
    local targetName = target.CleanName() or "Unknown"
    local targetId = target.ID()


    if not target() then
        Logger.log_verbose("\ayOkToEngage check - No Target to Engage --> Not Engaging")
        return false
    end

    if Targeting.GetTargetID() ~= autoTargetId then
        Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - Target isn't the Auto Target, can't perform checks--> Not Engaging", targetName, targetId)
        return false
    end

    if target.Dead() then
        Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - Target Dead --> Not Engaging", targetName, targetId)
        return false
    end

    if Globals.IgnoredTargetIDs:contains(targetId) then
        Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - Target is in IgnoredTargetIDs --> Not Engaging", targetName, targetId)
        return false
    end

    local pcCheck = Targeting.TargetIsType("pc", target) or (Targeting.TargetIsType("pet", target) and Targeting.TargetIsType("pc", target.Master))
    local mercCheck = Targeting.TargetIsType("mercenary", target)
    if pcCheck or mercCheck then
        Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - \aw[\atpcCheckFailed(%s) mercCheckFailed(%s)\aw]\ay", targetName, targetId, Strings.BoolToColorString(pcCheck),
            Strings.BoolToColorString(mercCheck))
        return false
    end

    if Config:GetSetting('SafeTargeting') and Targeting.IsSpawnFightingStranger(target, 100) then
        Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - Fighting Stranger --> Not Engaging", targetName, targetId)
        return false
    end

    -- can only check this on engage check, and not during prevalidate, as .Mezzed is a cached buff
    if target.Mezzed() and target.Mezzed.ID() and not Config:GetSetting('AllowMezBreak') then
        Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - Target Mezzed and Allow Mez Break disabled --> Not Engaging", targetName, targetId)
        return false
    end

    if not Globals.BackOffFlag then
        if Core.IAmMA() then
            Logger.log_verbose("OkToEngage check for %s(ID: %d) - I am MA, proceeding!", targetName, targetId)
            return true
        else
            local distanceCheck = Targeting.GetTargetDistance() < Config:GetSetting('AssistRange')
            local assistHPCheck = Targeting.GetTargetPctHPs() <= Config:GetSetting('AutoAssistAt')
            local hostileCheck = Config:GetSetting('TargetNonAggressives') or target.Aggressive()
            local forcedTarget = Globals.ForceTargetID > 0 and targetId == Globals.ForceTargetID
            local forcedCombat = Globals.ForceCombatID > 0 and targetId == Globals.ForceCombatID

            Logger.log_verbose("OkToEngage check for %s(ID: %d) - DistanceCheck(%s), AssistHPCheck(%s), HostileCheck(%s), ForcedTarget(%s), ForcedCombat(%s)", targetName, targetId,
                Strings.BoolToColorString(distanceCheck), Strings.BoolToColorString(assistHPCheck), Strings.BoolToColorString(hostileCheck), Strings.BoolToColorString(forcedTarget),
                Strings.BoolToColorString(forcedCombat))

            -- in range, and forced target. if not a forced target, check for assist HP, and make sure its hostile or we have forcecombat set (don't check aggressive on the MA's force target)
            return distanceCheck and (forcedTarget or (assistHPCheck and (hostileCheck or forcedCombat)))
        end
    end

    Logger.log_verbose("\ayOkToEngage check for %s(ID: %d) - Failed with Fall Through!", targetName, targetId)
    return false
end

--- Sends your pet in to attack.
--- @param targetId number The ID of the target to attack.
--- @param sendSwarm boolean Whether to send a swarm attack or not.
function Combat.PetAttack(targetId, sendSwarm)
    local pet = mq.TLO.Me.Pet

    local target = mq.TLO.Spawn(targetId)

    if not target() then return end
    if pet.ID() == 0 then return end

    if Config:GetSetting('DoPetCommands') and (not pet.Combat() or pet.Target.ID() ~= targetId) and (targetId == Globals.ForceTargetID or targetId == Globals.AutoTargetID or Targeting.TargetIsType("npc", target)) then
        Core.DoCmd("/squelch /pet attack %d", targetId)
        if sendSwarm then
            Core.DoCmd("/squelch /pet swarm")
        end
        Logger.log_debug("Pet sent to attack target: %s!", target.Name())
    end
end

--- Determines whether the target is valid for combat
---
--- @return boolean True if the target is present and alive, false if not.
function Combat.ValidCombatTarget(targetId)
    -- avoid breaking change
    return Core.ValidCombatTarget(targetId)
end

--- Checks if we should be doing our camping functionality
--- This function handles the logic required to return to camp.
---
--- @return boolean
function Combat.ShouldDoCamp()
    return
        (Targeting.GetXTHaterCount() == 0 and Globals.AutoTargetID == 0) or
        (not Core.IsTanking() and Targeting.GetAutoTargetPctHPs() > Config:GetSetting('AutoAssistAt'))
end

--- Checks if the auto camp feature should be activated based on the provided temporary configuration.
--- @param tempConfig table: A table containing temporary configuration settings for the auto camp feature.
--- @param bCalledFromInsideEvent? boolean: A flag indicating whether the function is called from within an event.
function Combat.AutoCampCheck(tempConfig, bCalledFromInsideEvent)
    if not bCalledFromInsideEvent then bCalledFromInsideEvent = false end

    if not Config:GetSetting('ReturnToCamp') then return end

    if mq.TLO.Me.Casting() and not Core.MyClassIs("brd") then return end

    -- chasing a toon dont use camnp.
    if Config:GetSetting('ChaseOn') then return end

    -- camped in a different zone.
    if tempConfig.CampZoneId ~= mq.TLO.Zone.ID() then return end

    -- let pulling module handle camp decisions while it is enabled.
    if Config:GetSetting('DoPull') then
        local pullState = Modules:ExecModule("Pull", "GetPullState")

        -- if we are idle or in groupwatch waiting its possible we wandered out of camp to loot and need to come back.
        if pullState > 2 then
            return
        end
    end

    local me = mq.TLO.Me

    local distanceToCamp = Math.GetDistance(me.Y(), me.X(), tempConfig.AutoCampY, tempConfig.AutoCampX)

    if distanceToCamp >= 400 then
        Comms.PrintGroupMessage("I'm over 400 units from camp, not returning!")
        Core.DoCmd("/rgl campoff")
        return
    end

    if not Config:GetSetting('CampHard') then
        if distanceToCamp < Config:GetSetting('AutoCampRadius') then return end
    end

    if distanceToCamp > 5 then
        local navTo = string.format("locyxz %d %d %d", tempConfig.AutoCampY, tempConfig.AutoCampX, tempConfig.AutoCampZ)
        if mq.TLO.Navigation.PathExists(navTo)() then
            Movement:DoNav(false, "%s", navTo)
            mq.delay("2s", function() return mq.TLO.Navigation.Active() and mq.TLO.Navigation.Velocity() > 0 end)
            while mq.TLO.Navigation.Active() and mq.TLO.Navigation.Velocity() > 0 do
                mq.delay(10)
                if not bCalledFromInsideEvent then
                    mq.doevents()
                    Events.DoEvents()
                end
            end
        else
            Core.DoCmd("/moveto loc %d %d|on", tempConfig.AutoCampY, tempConfig.AutoCampX)
            while mq.TLO.MoveTo.Moving() and not mq.TLO.MoveTo.Stopped() do
                mq.delay(10)
                if not bCalledFromInsideEvent then
                    mq.doevents()
                    Events.DoEvents()
                end
            end
        end
    end

    if mq.TLO.Navigation.Active() then
        Movement:DoNav(false, "stop")
    end
end

--- Checks the combat camp configuration.
--- @param tempConfig table: A table containing temporary configuration settings.
function Combat.CombatCampCheck(tempConfig)
    if not Config:GetSetting('ReturnToCamp') then return end

    if mq.TLO.Me.Casting() and not Core.MyClassIs("brd") then return end

    -- chasing a toon dont use camnp.
    if Config:GetSetting('ChaseOn') then return end

    -- camped in a different zone.
    if tempConfig.CampZoneId ~= mq.TLO.Zone.ID() then return end

    local me = mq.TLO.Me

    local distanceToCampSq = Math.GetDistanceSquared(me.Y(), me.X(), tempConfig.AutoCampY, tempConfig.AutoCampX)

    if not Config:GetSetting('CampHard') then
        if distanceToCampSq < Config:GetSetting('AutoCampRadius') ^ 2 then return end
    end

    if distanceToCampSq > 25 then
        local navTo = string.format("locyxz %d %d %d", tempConfig.AutoCampY, tempConfig.AutoCampX, tempConfig.AutoCampZ)
        if mq.TLO.Navigation.PathExists(navTo)() then
            Movement:DoNav(false, "%s", navTo)
            mq.delay("2s", function() return mq.TLO.Navigation.Active() and mq.TLO.Navigation.Velocity() > 0 end)
            while mq.TLO.Navigation.Active() and mq.TLO.Navigation.Velocity() > 0 do
                mq.delay(10)
                mq.doevents()
                Events.DoEvents()
            end
        else
            Core.DoCmd("/moveto loc %d %d|on", tempConfig.AutoCampY, tempConfig.AutoCampX)
            while mq.TLO.MoveTo.Moving() and not mq.TLO.MoveTo.Stopped() do
                mq.delay(10)
                mq.doevents()
                Events.DoEvents()
            end
        end
    end

    if mq.TLO.Navigation.Active() then
        Movement:DoNav(false, "stop")
    end
end

--- Finds the group member with the lowest mana percentage.
--- @param minMana number The minimum mana percentage to consider.
--- @return number The group member with the lowest mana percentage, or nil if no member meets the criteria.
function Combat.FindWorstHurtManaGroupMember(minMana)
    local groupSize = mq.TLO.Group.Members()
    local worstId = mq.TLO.Me.ID() --initializes with the BST's ID/Mana because it isn't checked below
    local worstPct = mq.TLO.Me.PctMana()

    Logger.log_verbose("\ayChecking for worst HurtMana Group Members. Group Count: %d", groupSize)

    for i = 1, groupSize do
        local healTarget = mq.TLO.Group.Member(i)

        if healTarget and healTarget() and not healTarget.OtherZone() and not healTarget.Offline() then
            if Globals.Constants.RGCasters:contains(healTarget.Class.ShortName()) then
                if not healTarget.Dead() and healTarget.PctMana() < worstPct then
                    Logger.log_verbose("\aySo far %s is the worst off.", healTarget.DisplayName())
                    worstPct = healTarget.PctMana()
                    worstId = healTarget.ID()
                end
            end
        end
    end

    --Still possibly carrying the BST ID, but only reports BST if under 100%, which is when they will self-Paragon
    if worstId > 0 and worstPct < 100 then
        Logger.log_verbose("\agWorst HurtMana group member id is %d", worstId)
    else
        Logger.log_verbose("\agNo one is HurtMana!")
    end

    return (worstPct < minMana and worstId or 0)
end

--- Finds the group member with the lowest health percentage.
--- @param minHPs number The minimum health percentage to consider.
--- @return number The group member with the lowest health percentage, or nil if no member meets the criteria.
function Combat.FindWorstHurtGroupMember(minHPs)
    local groupSize = mq.TLO.Group.Members()
    local worstId = mq.TLO.Me.PctHPs() < minHPs and mq.TLO.Me.ID() or 0
    local worstPct = mq.TLO.Me.PctHPs() < minHPs and mq.TLO.Me.PctHPs() or minHPs

    Logger.log_verbose("\ayChecking for worst Hurt Group Members. Group Count: %d", groupSize)

    for i = 1, groupSize do
        local healTarget = mq.TLO.Group.Member(i)

        if healTarget and healTarget() and not healTarget.OtherZone() and not healTarget.Offline() then
            if not healTarget.Dead() and (healTarget.PctHPs() or 101) < worstPct then
                Logger.log_verbose("\aySo far %s is the worst off.", healTarget.DisplayName())
                -- this looks weird but it guards against a possible yield between the if above and this line where the healtarget might have died.
                worstPct = (healTarget.PctHPs() or worstPct)
                worstId = (healTarget.PctHPs() and healTarget.ID() or worstId)
            end

            if Config:GetSetting('DoPetHeals') and (healTarget.Pet.ID() or 0) > 0 then
                local petHP = healTarget.Pet.PctHPs() or 101
                if petHP < worstPct and petHP < Config:GetSetting('PetHealPoint') then
                    Logger.log_verbose("\aySo far %s's pet %s is the worst off.", healTarget.DisplayName(),
                        healTarget.Pet.DisplayName())
                    -- this looks weird but it guards against a possible yield between the if above and this line where the healtarget might have died.
                    worstPct = (healTarget.Pet.PctHPs() or worstPct)
                    worstId = (healTarget.Pet.PctHPs() and healTarget.Pet.ID() or worstId)
                end
            end
        end
    end

    if worstId > 0 then
        Logger.log_verbose("\agWorst hurt group member id is %d", worstId)
    else
        Logger.log_verbose("\agNo one is hurt!")
    end

    return (worstPct < minHPs and worstId or 0)
end

--- Finds the entity with the worst hurt mana exceeding a minimum threshold.
--- @param minMana number The minimum mana threshold to consider.
--- @return number The spawn id with the worst hurt mana above the specified threshold.
function Combat.FindWorstHurtManaXT(minMana)
    local xtSize = mq.TLO.Me.XTargetSlots()
    local worstId = 0
    local worstPct = minMana

    Logger.log_verbose("\ayChecking for worst HurtMana XTargs. XT Slot Count: %d", xtSize)

    for i = 1, xtSize do
        local healTarget = mq.TLO.Me.XTarget(i)

        if healTarget and healTarget() and Targeting.TargetIsType("pc", healTarget) then
            if Globals.Constants.RGCasters:contains(healTarget.Class.ShortName()) then -- berzerkers have special handing
                if not healTarget.Dead() and healTarget.PctMana() < worstPct then
                    Logger.log_verbose("\aySo far %s is the worst off.", healTarget.DisplayName())
                    worstPct = healTarget.PctMana() or worstPct
                    worstId = healTarget.PctMana() and healTarget.ID() or worstId
                end
            end
        end
    end

    if worstId > 0 then
        Logger.log_verbose("\agWorst HurtMana xtarget id is %d", worstId)
    else
        Logger.log_verbose("\agNo one is HurtMana!")
    end

    return worstId
end

--- Finds the entity with the worst health condition that meets the minimum HP requirement.
--- @param minHPs number The minimum HP threshold to consider.
--- @return number The spawn id with the worst health condition that meets the criteria.
function Combat.FindWorstHurtXT(minHPs)
    local xtSize = mq.TLO.Me.XTargetSlots()
    local worstId = 0
    local worstPct = minHPs

    Logger.log_verbose("\ayChecking for worst Hurt XTargs. XT Slot Count: %d", xtSize)

    for i = 1, xtSize do
        local healTarget = mq.TLO.Me.XTarget(i)

        if healTarget and healTarget() and Targeting.TargetIsType("pc", healTarget) then
            local playerHP = healTarget.PctHPs() or 101
            if not healTarget.Dead() and playerHP < worstPct then
                Logger.log_verbose("\aySo far %s is the worst off.", healTarget.DisplayName() or "Error")
                worstPct = playerHP
                worstId = healTarget.ID()
            end

            if Config:GetSetting('DoPetHeals') and (healTarget.Pet.ID() or 0) > 0 then
                local petHP = healTarget.Pet.PctHPs() or 101
                if petHP < worstPct and petHP < Config:GetSetting('PetHealPoint') then
                    Logger.log_verbose("\aySo far %s's pet %s is the worst off.", healTarget.DisplayName() or "Error",
                        healTarget.Pet.DisplayName() or "Error")
                    worstPct = petHP
                    worstId = healTarget.Pet.ID()
                end
            end
        end
    end

    if worstId > 0 then
        Logger.log_verbose("\agWorst hurt xtarget id is %d", worstId)
    else
        Logger.log_verbose("\agNo one is hurt!")
    end

    return worstId
end

--function to determine if we should AE taunt and optionally, if it is safe to do so
function Combat.AETauntCheck(printDebug)
    local xtCount = mq.TLO.Me.XTarget() or 0
    if xtCount < Config:GetSetting('AETauntCnt') then return false end

    local mobs = mq.TLO.SpawnCount("NPC radius 50 zradius 50")()
    if mobs < Config:GetSetting('AETauntCnt') then return false end

    local tauntme = Set.new({})
    for i = 1, xtCount do
        local xtarg = mq.TLO.Me.XTarget(i)
        if xtarg and xtarg.ID() > 0 and (xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater" or xtarg.ID() == Globals.ForceTargetID) and xtarg.PctAggro() < 100 and (xtarg.Distance() or 999) <= 50 and Globals.Constants.RGNotMezzedAnims:contains(xtarg.Animation()) then
            if printDebug then
                Logger.log_verbose("AETauntCheck(): XT(%d) Counting %s(%d) as a hater eligible to AE Taunt.", i, xtarg.CleanName() or "None",
                    xtarg.ID())
            end
            tauntme:add(xtarg.ID())
        end
        if not Config:GetSetting('SafeAETaunt') and #tauntme:toList() > 0 then return true end --no need to find more than one if we don't care about safe taunt
    end
    return #tauntme:toList() > 0 and not (Config:GetSetting('SafeAETaunt') and #tauntme:toList() < mobs)
end

--function to determine if we should use AE damage abilities
function Combat.AETargetCheck(printDebug, minCount)
    if not minCount then minCount = Config:GetSetting('AETargetCnt') end

    local haters = mq.TLO.SpawnCount("NPC xtarhater radius 80 zradius 50")()
    local haterPets = mq.TLO.SpawnCount("NPCpet xtarhater radius 80 zradius 50")()
    local totalHaters = haters + haterPets
    if totalHaters < minCount or totalHaters > Config:GetSetting('MaxAETargetCnt') then return false end

    if Config:GetSetting('SafeAEDamage') then
        local npcs = mq.TLO.SpawnCount("NPC radius 80 zradius 50")()
        local npcPets = mq.TLO.SpawnCount("NPCpet radius 80 zradius 50")()
        if totalHaters < (npcs + npcPets) then
            if printDebug then
                Logger.log_verbose("AETargetCheck(): %d mobs in range but only %d xtarget haters, blocking AE damage actions.", npcs + npcPets, haters + haterPets)
            end
            return false
        end
    end

    return true
end

return Combat
