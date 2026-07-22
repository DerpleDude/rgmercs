local mq           = require('mq')
local Set          = require('mq.set')
local Combat       = require("utils.combat")
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Core         = require("utils.core")
local DanNet       = require('lib.dannet.helpers')
local Events       = require("utils.events")
local Globals      = require('utils.globals')
local Logger       = require("utils.logger")
local Modules      = require("utils.modules")
local Movement     = require('utils.movement')
local Strings      = require("utils.strings")
local Tables       = require("utils.tables")
local Targeting    = require("utils.targeting")

local Casting      = { _version = '2.1', _name = "Casting", _author = 'Derple, Algar', }
Casting.__index    = Casting
Casting.Memorizing = false

-- cached for UI display
Casting.UseGem     = mq.TLO.Me.NumGems()

--- Checks if a spell target type is a group-affecting type (group buffs, AE PC buffs, etc.)
--- @param targetType string|nil The TargetType() value from a spell.
--- @return boolean
function Casting.IsGroupSpell(targetType)
    if not targetType then return false end
    return Globals.Constants.GroupTargetTypes:contains(targetType)
end

--- Checks if a spell target type is self.
--- @param targetType string|nil The TargetType() value from a spell.
--- @return boolean
function Casting.IsSelfSpell(targetType)
    if not targetType then return false end
    return targetType:lower() == "self"
end

--- Simple (no trigger or stacking checks) check to see if the player has a buff. Can pass a spell(userdata), ID, or effect name(string).
--- @param effect MQSpell|string|integer|nil The effect to check for.
--- @return boolean Returns true if the player has the buff, false otherwise.
function Casting.IHaveBuff(effect)
    if not effect then return false end
    if type(effect) ~= "string" then effect = tostring(effect) end
    local spell = mq.TLO.Spell(effect)() or effect

    Logger.log_verbose("IHaveBuff - Searching Buff and Song windows for %s.", effect)

    if mq.TLO.Me.Buff(spell)() then
        Logger.log_verbose("IHaveBuff - %s found in Buff window!", effect)
        return true
    end
    if mq.TLO.Me.Song(spell)() then
        Logger.log_verbose("IHaveBuff - %s found in Song window!", effect)
        return true
    end
    return false
end

--- Simple (no trigger or stacking checks) check to see if the target has a buff. Can pass a spell(userdata), ID, or effect name(string).
--- @param effect MQSpell|string|integer The effect to check for.
--- @param target MQTarget|MQSpawn|MQCharacter? The target to check for the buff.
--- @param bAllowTargetChange boolean|nil Allows the function to set the target to check buffs if true.
--- @return boolean Returns true if the target has the buff, false otherwise.
function Casting.TargetHasBuff(effect, target, bAllowTargetChange)
    if not target then target = mq.TLO.Target end
    if not (target and target()) then return false end
    if not effect then return false end
    if type(effect) ~= "string" then effect = tostring(effect) end
    local spell = mq.TLO.Spell(effect)() or effect

    if target.ID() ~= mq.TLO.Target.ID() then
        if not bAllowTargetChange then
            Logger.log_verbose("TargetHasBuff: Passed target(ID:%d) isn't our current target(ID:%d), cannot check spell stacking, aborting.", target.ID(), mq.TLO.Target.ID())
            return false
        else
            Logger.log_verbose("TargetHasBuff: Passed target(ID:%d) isn't our current target(ID:%d), setting target to populate buffs.", target.ID(), mq.TLO.Target.ID())
            Targeting.SetTarget(target.ID())
        end
    end

    return mq.TLO.Target.Buff(spell)() ~= nil
end

-- Buff Check Family: Local, LocalPet, Peer, Actor, ActorPet.
-- By default, if the buff's triggers are still up we won't recast it, even after the parent spell has expired. This stops Unity-style spells (short duration parent buff we don't care about) from recasting every 6 seconds.
-- Set skipTriggerCheck to ignore triggers and recast whenever the parent spell itself is missing -- needed for spells like ENC illusion buffs with an illusion trigger we don't care about. Can also be used if we know we don't need triggers.

--- Complex buff check that will check for presence and stacking of the buff (and any triggers) on the PC or the PC's pet.
--- @param spellId integer The ID of the spell to check.
--- @param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.LocalBuffCheck(spellId, skipBlockCheck, skipTriggerCheck)
    if not spellId then return false end

    local buffSpell = mq.TLO.Spell(spellId)
    if not buffSpell or not buffSpell() then return false end
    local spellName = buffSpell.Name()
    if not spellName then return false end

    local spellBlocked = not skipBlockCheck and mq.TLO.Me.BlockedBuff(spellName)() == spellName
    if spellBlocked then
        Logger.log_verbose("LocalBuffCheck: %s(ID:%d) is blocked, counting as present.", spellName, spellId)
    end

    local spellPresent = spellBlocked or mq.TLO.Me.FindBuff("id " .. spellId)() ~= nil

    if not spellPresent and not buffSpell.Stacks() then
        Logger.log_verbose("LocalBuffCheck: %s(ID:%d) does not stack, ending check.", spellName, spellId)
        return false
    end

    if skipTriggerCheck then
        if spellPresent then
            Logger.log_verbose("LocalBuffCheck: %s(ID:%d) present, trigger check skipped.", spellName, spellId)
            return false
        end
        Logger.log_verbose("LocalBuffCheck: %s(ID:%d) missing and stacks, trigger check skipped, let's do it!", spellName, spellId)
        return true
    end

    Logger.log_verbose("LocalBuffCheck: %s(ID:%d) checking for triggers.", spellName, spellId)
    local numEffects = buffSpell.NumEffects()
    local hasTriggers = false
    for i = 1, numEffects do
        local triggerSpell = buffSpell.Trigger(i)
        --Some Laz spells report trigger 1 as "Unknown Spell" with an ID of 0, which always reports false on stack checks
        if not (triggerSpell and triggerSpell() and triggerSpell.ID() > 0) then
            Logger.log_verbose("LocalBuffCheck: We've checked every trigger for %s(ID:%d).", spellName, spellId)
            break
        end
        hasTriggers = true

        local triggerName = triggerSpell.Name()
        local triggerId = triggerSpell.ID()

        if not skipBlockCheck and mq.TLO.Me.BlockedBuff(triggerName)() == triggerName then
            Logger.log_verbose("LocalBuffCheck: Trigger %s(ID:%d) is blocked, counting as present.", triggerName, triggerId)
        elseif mq.TLO.Me.FindBuff("id " .. triggerId)() then
            Logger.log_verbose("LocalBuffCheck: Trigger %s(ID:%d) found, moving on.", triggerName, triggerId)
        elseif triggerSpell.Stacks() then
            Logger.log_verbose("LocalBuffCheck: Trigger %s(ID:%d) missing and stacks, let's do it!", triggerName, triggerId)
            return true
        else
            Logger.log_verbose("LocalBuffCheck: Trigger %s(ID:%d) does not stack, moving on.", triggerName, triggerId)
        end
    end

    if not hasTriggers and not spellPresent then
        Logger.log_verbose("LocalBuffCheck: %s(ID:%d) missing and stacks with no triggers, let's do it!", spellName, spellId)
        return true
    end

    Logger.log_verbose("LocalBuffCheck: %s(ID:%d) handled, no need to cast.", spellName, spellId)
    return false
end

--- Delegates to LocalBuffCheck after resolving the spell rank via
--- GetUseableSpellId. Checks blocked list, buff/song window presence,
--- and stacking including trigger spells.
---@param spell MQSpell The spell to check.
---@param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
---@param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
---@return boolean True if the spell should be cast on self.
function Casting.SelfBuffCheck(spell, skipBlockCheck, skipTriggerCheck)
    if not (spell and spell()) then return false end
    return Casting.LocalBuffCheck(Casting.GetUseableSpellId(spell), skipBlockCheck, skipTriggerCheck)
end

--- Gates on CanUseAA, then delegates to LocalBuffCheck using the AA's
--- spell ID to confirm not blocked, not present, and stacks.
---@param aaName string The AA name to check.
---@param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
---@param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
---@return boolean True if the AA buff should be cast on self.
function Casting.SelfBuffAACheck(aaName, skipBlockCheck, skipTriggerCheck)
    if not Casting.CanUseAA(aaName) then return false end
    return Casting.LocalBuffCheck(mq.TLO.Me.AltAbility(aaName).Spell.ID(), skipBlockCheck, skipTriggerCheck)
end

--- Gets the clicky spell via GetClickySpell, then delegates to
--- LocalBuffCheck to confirm not blocked, not present, and stacks.
---@param itemName string The item name whose clicky to check.
---@param skipBlockCheck boolean|nil whether to skip the blocked-spell check
---@param skipTriggerCheck boolean|nil whether to skip the trigger check
---@return boolean True if the item's clicky buff should be applied to self.
function Casting.SelfBuffItemCheck(itemName, skipBlockCheck, skipTriggerCheck)
    local clickySpell = Casting.GetClickySpell(itemName)
    if not (clickySpell and clickySpell()) then return false end
    return Casting.LocalBuffCheck(clickySpell.ID(), skipBlockCheck, skipTriggerCheck)
end

--- Complex buff check that will check for presence and stacking of the buff (and any triggers) on the PC or the PC's pet.
--- @param spellId integer The ID of the spell to check.
--- @param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.LocalPetBuffCheck(spellId, skipBlockCheck, skipTriggerCheck)
    if not spellId then return false end
    if mq.TLO.Me.Pet.ID() == 0 then return false end

    local buffSpell = mq.TLO.Spell(spellId)
    if not buffSpell or not buffSpell() then return false end
    local spellName = buffSpell.Name()
    if not spellName then return false end

    local spellBlocked = not skipBlockCheck and mq.TLO.Me.BlockedPetBuff(spellName)() == spellName
    if spellBlocked then
        Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) is blocked, counting as present.", spellName, spellId)
    end

    -- I would like to use FindBuff with an ID here but it mysteriously does not see certain buffs.
    local spellPresent = spellBlocked or mq.TLO.Me.Pet.Buff(spellName)() ~= nil

    if not spellPresent and not buffSpell.StacksPet() then
        Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) does not stack, ending check.", spellName, spellId)
        return false
    end

    if skipTriggerCheck then
        if spellPresent then
            Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) present, trigger check skipped.", spellName, spellId)
            return false
        end
        Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) missing and stacks, trigger check skipped, let's do it!", spellName, spellId)
        return true
    end

    Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) checking for triggers.", spellName, spellId)
    local numEffects = buffSpell.NumEffects()
    local hasTriggers = false
    for i = 1, numEffects do
        local triggerSpell = buffSpell.Trigger(i)
        --Some Laz spells report trigger 1 as "Unknown Spell" with an ID of 0, which always reports false on stack checks
        if not (triggerSpell and triggerSpell() and triggerSpell.ID() > 0) then
            Logger.log_verbose("LocalPetBuffCheck: We've checked every trigger for %s(ID:%d).", spellName, spellId)
            break
        end
        hasTriggers = true

        local triggerName = triggerSpell.Name()
        local triggerId = triggerSpell.ID()

        if not skipBlockCheck and mq.TLO.Me.BlockedPetBuff(triggerName)() == triggerName then
            Logger.log_verbose("LocalPetBuffCheck: Trigger %s(ID:%d) is blocked, counting as present.", triggerName, triggerId)
        elseif mq.TLO.Me.Pet.Buff(triggerName)() then
            Logger.log_verbose("LocalPetBuffCheck: Trigger %s(ID:%d) found, moving on.", triggerName, triggerId)
        elseif triggerSpell.StacksPet() then
            Logger.log_verbose("LocalPetBuffCheck: Trigger %s(ID:%d) missing and stacks, let's do it!", triggerName, triggerId)
            return true
        else
            Logger.log_verbose("LocalPetBuffCheck: Trigger %s(ID:%d) does not stack, moving on.", triggerName, triggerId)
        end
    end

    if not hasTriggers and not spellPresent then
        Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) missing and stacks with no triggers, let's do it!", spellName, spellId)
        return true
    end

    Logger.log_verbose("LocalPetBuffCheck: %s(ID:%d) handled, no need to cast.", spellName, spellId)
    return false
end

--- Delegates to LocalPetBuffCheck after resolving the spell rank via
--- GetUseableSpellId. Checks pet blocked list, pet buff window, and
--- stacking including trigger spells.
---@param spell MQSpell The spell to check.
---@param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
---@param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
---@return boolean True if the spell should be cast on the player's pet.
function Casting.PetBuffCheck(spell, skipBlockCheck, skipTriggerCheck)
    if not (spell and spell()) then return false end
    return Casting.LocalPetBuffCheck(Casting.GetUseableSpellId(spell), skipBlockCheck, skipTriggerCheck)
end

--- Gates on CanUseAA, then delegates to LocalPetBuffCheck using the
--- AA's spell ID to confirm not blocked on pet, not present, stacks.
---@param aaName string The AA name to check.
---@param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
---@param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
---@return boolean True if the AA buff should be cast on the pet.
function Casting.PetBuffAACheck(aaName, skipBlockCheck, skipTriggerCheck)
    if not Casting.CanUseAA(aaName) then return false end
    return Casting.LocalPetBuffCheck(mq.TLO.Me.AltAbility(aaName).Spell.ID(), skipBlockCheck, skipTriggerCheck)
end

--- Gets the clicky spell via GetClickySpell, then delegates to
--- LocalPetBuffCheck to confirm not blocked on pet, not present, stacks.
---@param itemName string The item name whose clicky to check.
---@param skipBlockCheck boolean|nil whether to skip the blocked-spell check
---@param skipTriggerCheck boolean|nil whether to skip the trigger check
---@return boolean True if the item's clicky buff should be applied to the pet.
function Casting.PetBuffItemCheck(itemName, skipBlockCheck, skipTriggerCheck)
    local clickySpell = Casting.GetClickySpell(itemName)
    if not (clickySpell and clickySpell()) then return false end
    return Casting.LocalPetBuffCheck(clickySpell.ID(), skipBlockCheck, skipTriggerCheck)
end

--- Helper that will perform complex checks for presence and stacking of buffs (and any triggers) using the best (determined) method available.
--- @param spellId integer The spellId to check stacking for
--- @param target MQTarget|MQSpawn|MQCharacter? The target to check for the buff.
--- @param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.ResolveBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck)
    if not spellId or type(spellId) ~= "number" then return false end
    if not (target and target()) then return false end

    local spell = mq.TLO.Spell(spellId)
    local targetId = target.ID()

    if targetId == mq.TLO.Me.ID() then
        Logger.log_verbose("ResolveBuffCheck: Target is myself, using LocalBuffCheck.")
        return Casting.LocalBuffCheck(spellId, skipBlockCheck, skipTriggerCheck)
    elseif targetId == mq.TLO.Me.Pet.ID() then
        Logger.log_verbose("ResolveBuffCheck: Target is my pet, using LocalPetBuffCheck.")
        return Casting.LocalPetBuffCheck(spellId, skipBlockCheck, skipTriggerCheck)
    else
        local targetName = target.DisplayName() or ""
        --Let's check spell range in case our group/OA starts moving while we are trying to buff (common in hunt/farm modes).
        local spellRange = Casting.GetSpellRange(spell)
        if Targeting.GetTargetDistance(target) > spellRange then
            Logger.log_verbose("ResolveBuffCheck: Aborting check because %s(Range:%d) is out of range(%d) for %s.", targetName, Targeting.GetTargetDistance(target), spellRange,
                spell.RankName.Name())
            return false
        end

        local isPet = Targeting.TargetIsType("Pet", target)
        local heartbeatName = (isPet and target.Master()) and target.Master.DisplayName() or targetName
        local heartbeat = Comms.GetPeerHeartbeatByName(heartbeatName)

        if heartbeat and heartbeat.Data then
            local buffList = heartbeat.Data.Buffs
            local songList = heartbeat.Data.Songs
            local blockedList = heartbeat.Data.Blocked
            local petBuffList = heartbeat.Data.PetBuffs
            local petBlockedList = heartbeat.Data.PetBlocked

            if isPet and petBuffList and (skipBlockCheck or petBlockedList) then
                Logger.log_verbose("ResolveBuffCheck: Target(%s) ID(%d) is an actor peer pet, using ActorPetBuffCheck.", target.DisplayName(), targetId)
                return Casting.ActorPetBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck, heartbeat, spell)
            end
            if buffList and songList and (skipBlockCheck or blockedList) then
                Logger.log_verbose("ResolveBuffCheck: Target(%s) ID(%d) is an actor peer, using ActorBuffCheck.", target.DisplayName(), targetId)
                return Casting.ActorBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck, heartbeat, spell)
            end
        end

        if mq.TLO.DanNet(mq.TLO.Spawn(targetId).CleanName())() then
            Logger.log_verbose("ResolveBuffCheck: Target(%s) ID(%d) is a DanNet peer, using PeerBuffCheck.", target.DisplayName(), targetId)
            return Casting.PeerBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck)
        end

        local allowTargetChange = (mq.TLO.Me.CombatState() or ""):lower() ~= "combat"
        if allowTargetChange and targetId ~= mq.TLO.Target.ID() then
            local now = Globals.GetTimeSeconds()
            if now - (Globals.LastCachedBuffUpdate[targetId] or 0) < Config:GetSetting('BuffTargetingInterval') then
                Logger.log_verbose("ResolveBuffCheck: Throttled target-change for %s(ID:%d).", target.CleanName(), targetId)
                return false
            end
            Globals.LastCachedBuffUpdate[targetId] = now
        end
        Logger.log_verbose("ResolveBuffCheck: Target is not myself or a DanNet peer, using TargetBuffCheck.")
        return Casting.TargetBuffCheck(spellId, target, allowTargetChange, false, skipTriggerCheck)
    end
end

--- Calls ResolveBuffCheck with block and trigger checks both skipped.
--- Used for manual stacking overrides where only presence matters.
---@param spellId number The spell ID to check for on the target.
---@param target MQSpawn? The target to check; defaults to current target.
---@return boolean True if the spell is not already present on the target.
function Casting.AddedBuffCheck(spellId, target)
    return Casting.ResolveBuffCheck(spellId, target, true, true)
end

--- Resolves spell rank via GetUseableSpellId, then delegates to
--- ResolveBuffCheck which picks the best method (local, pet, actor
--- heartbeat, DanNet peer, or target-change) based on the target.
---@param spell MQSpell The spell to check.
---@param target MQSpawn? The target to check.
---@param skipBlockCheck boolean? Skip the blocked-buff list check.
---@param skipTriggerCheck boolean? Skip trigger stacking checks.
---@return boolean True if the spell should be cast on the target.
function Casting.GroupBuffCheck(spell, target, skipBlockCheck, skipTriggerCheck)
    if not (spell and spell()) then return false end
    if not Casting.LevelCheckPass(spell, target) then return false end
    return Casting.ResolveBuffCheck(Casting.GetUseableSpellId(spell), target, skipBlockCheck, skipTriggerCheck)
end

--- Gates on CanUseAA, then delegates to ResolveBuffCheck using the
--- AA's spell ID. ResolveBuffCheck picks the best method based on
--- the target (local, pet, actor heartbeat, DanNet, target-change).
---@param aaName string The AA name to check.
---@param target MQSpawn? The target to check.
---@param skipBlockCheck boolean? Skip the blocked-buff list check.
---@param skipTriggerCheck boolean? Skip trigger stacking checks.
---@return boolean True if the AA buff should be cast on the target.
function Casting.GroupBuffAACheck(aaName, target, skipBlockCheck, skipTriggerCheck)
    if not Casting.CanUseAA(aaName) then return false end
    local aaSpell = mq.TLO.Me.AltAbility(aaName).Spell
    if not aaSpell or not aaSpell() then return false end
    if not Casting.LevelCheckPass(aaSpell, target) then return false end
    return Casting.ResolveBuffCheck(aaSpell.ID(), target, skipBlockCheck, skipTriggerCheck)
end

--- Gets clicky spell via GetClickySpell, then delegates to
--- ResolveBuffCheck. ResolveBuffCheck picks the best method based on
--- the target (local, pet, actor heartbeat, DanNet, target-change).
---@param itemName string The item name whose clicky to check.
---@param target MQSpawn? The target to check.
---@param skipBlockCheck boolean? Skip the blocked-buff list check.
---@param skipTriggerCheck boolean? Skip trigger stacking checks.
---@return boolean True if the item's clicky buff should be cast on the target.
function Casting.GroupBuffItemCheck(itemName, target, skipBlockCheck, skipTriggerCheck)
    local clickySpell = Casting.GetClickySpell(itemName)
    if not (clickySpell and clickySpell()) then return false end
    if not Casting.LevelCheckPass(clickySpell, target) then return false end
    return Casting.ResolveBuffCheck(clickySpell.ID(), target, skipBlockCheck, skipTriggerCheck)
end

--- Complex buff check that will check for presence and stacking of the buff (and any triggers) on a target.
--- @param spellId integer The ID of the spell to check.
--- @param target MQTarget|MQSpawn|MQCharacter? The target to check for the buff.
--- @param bAllowTargetChange boolean|nil Allows the function to set the target to check buffs if true.
--- @param bAllowDuplicates boolean|nil Checks whether the function should only return false if the effect was cast by this PC.
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.TargetBuffCheck(spellId, target, bAllowTargetChange, bAllowDuplicates, skipTriggerCheck)
    if not spellId then return false end
    if not target then target = mq.TLO.Target end
    if not (target and target()) then return false end

    if target.ID() ~= mq.TLO.Target.ID() then
        if not bAllowTargetChange then
            Logger.log_verbose("TargetBuffCheck: Passed target(ID:%d) isn't our current target(ID:%d), cannot check spell stacking, aborting.", target.ID(), mq.TLO.Target.ID())
            return false
        else
            Logger.log_verbose("TargetBuffCheck: Passed target(ID:%d) isn't our current target(ID:%d), setting target to populate buffs.", target.ID(), mq.TLO.Target.ID())
            Targeting.SetTarget(target.ID(), false)
        end
    end

    local targetName = target.CleanName()
    local targetId = target.ID()
    local buffSpell = mq.TLO.Spell(spellId)
    local spellName = buffSpell.Name() or buffSpell()

    if not spellName then return false end

    local buffSearch = bAllowDuplicates and string.format("id %d and caster =%s", spellId, mq.TLO.Me.DisplayName()) or string.format("id %d", spellId)

    if mq.TLO.Target.FindBuff(buffSearch)() then
        Logger.log_verbose("TargetBuffCheck: %s(ID:%d) found on %s(ID:%d), ending check.", spellName, spellId, targetName, targetId)
        return false
    end

    if not skipTriggerCheck then
        Logger.log_verbose("TargetBuffCheck: %s(ID:%d) not found on %s(ID:%d), let's check for triggers.", spellName, spellId, targetName, targetId)
        local numEffects = buffSpell.NumEffects()
        local triggerCount = 0
        local triggerFound = 0

        for i = 1, numEffects do
            local triggerSpell = buffSpell.Trigger(i)
            if not (triggerSpell and triggerSpell() and triggerSpell.ID() > 0) then
                Logger.log_verbose("TargetBuffCheck: We've checked every trigger for %s(ID:%d).", spellName, spellId)
                break
            end

            local triggerName = triggerSpell.Name()
            local triggerId = triggerSpell.ID()
            local triggerSearch = bAllowDuplicates and string.format("id %d and caster =%s", triggerId, mq.TLO.Me.DisplayName()) or string.format("id %d", triggerId)

            triggerCount = triggerCount + 1

            if mq.TLO.Target.FindBuff(triggerSearch)() then
                Logger.log_verbose("TargetBuffCheck: %s(ID:%d) found on %s(ID:%d), moving on.", triggerName, triggerId, targetName, targetId)
                triggerFound = triggerFound + 1
            elseif triggerSpell.StacksTarget() then
                Logger.log_verbose("TargetBuffCheck: %s(ID:%d) seems to stack on %s(ID:%d), let's do it!", triggerName, triggerId, targetName, targetId)
                return true
            else
                Logger.log_verbose("TargetBuffCheck: %s(ID:%d) does not stack on %s(ID:%d), moving on.", triggerName, triggerId, targetName, targetId)
                triggerFound = triggerFound + 1
            end
        end

        if triggerCount > 0 and triggerFound >= triggerCount then
            Logger.log_verbose("TargetBuffCheck: Total triggers for %s(ID:%d): %d. Triggers found: %d. Ending Check.", spellName, spellId, triggerCount, triggerFound)
            return false
        end
    end

    if buffSpell.StacksTarget() then
        Logger.log_verbose("TargetBuffCheck: %s(ID:%d) seems to stack on %s(ID:%d), let's do it!", spellName, spellId, targetName, targetId)
        return true
    end

    Logger.log_verbose("TargetBuffCheck: %s(ID:%d) does not seem to stack, ending check.", spellName, spellId)
    return false
end

--- Complex buff check that will check for presence and stacking of the buff (and any triggers) on a DanNet peer.
--- @param spellId integer The ID of the spell to check.
--- @param target MQTarget|MQSpawn|MQCharacter? The target to check for the buff.
--- @param skipBlockCheck boolean|nil whether to check the peers blocked spells, this needs to be skipped for certain manual stacking checks
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.PeerBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck)
    if not spellId then return false end
    if not (target and target()) then return false end

    local targetName = target.CleanName()
    local targetId = target.ID()
    local buffSpell = mq.TLO.Spell(spellId)
    local spellName = buffSpell.Name() or buffSpell()

    if not spellName then return false end

    if not mq.TLO.DanNet(mq.TLO.Spawn(targetId).CleanName())() then
        Logger.log_verbose(
            "PeerBuffCheck: Tried to check a peer's buff, but that peer isn't found! Did this peer zone or crash?" ..
            "If this behavior continues, please report this. Spell:%s(ID:%d), Target:%s(ID:%d)",
            spellName, spellId, targetName, targetId)
        return false
    end

    -- check presence first because blocking is rare
    local spellResult = DanNet.query(targetName, string.format("Me.FindBuff[id %d]", spellId), 1000)
    local spellPresent = spellResult:lower() == spellName:lower()
    if not spellPresent and spellResult:lower() ~= "null" then
        Logger.log_error(
            "PeerBuffCheck: Tried to check buff presence, but something seems to have gone wrong! Your character may not be responding. If this persists, please report it. Spell:%s(ID:%d), Target:%s(ID:%d) Result:%s",
            spellName, spellId, targetName, targetId, spellResult)
        return false
    end

    if not spellPresent and not skipBlockCheck then
        local blockedResult = DanNet.query(targetName, string.format("Me.BlockedBuff[%s]", spellName), 1000)
        if blockedResult:lower() == spellName:lower() then
            Logger.log_verbose("PeerBuffCheck: %s(ID:%d) is blocked on %s(ID:%d), counting as present.", spellName, spellId, targetName, targetId)
            spellPresent = true
        end
    end

    if not spellPresent then
        local spellStackResult = DanNet.query(targetName, string.format("Spell[%d].Stacks", spellId), 1000)
        if spellStackResult:lower() ~= "true" then
            Logger.log_verbose("PeerBuffCheck: %s(ID:%d) does not stack on %s(ID:%d), ending check.", spellName, spellId, targetName, targetId)
            return false
        end
    end

    if skipTriggerCheck then
        if spellPresent then
            Logger.log_verbose("PeerBuffCheck: %s(ID:%d) present on %s(ID:%d), trigger check skipped.", spellName, spellId, targetName, targetId)
            return false
        end
        Logger.log_verbose("PeerBuffCheck: %s(ID:%d) missing on %s(ID:%d) and stacks, trigger check skipped, let's do it!", spellName, spellId, targetName, targetId)
        return true
    end

    Logger.log_verbose("PeerBuffCheck: %s(ID:%d) checking for triggers on %s(ID:%d).", spellName, spellId, targetName, targetId)
    local numEffects = buffSpell.NumEffects()
    local hasTriggers = false
    for i = 1, numEffects do
        local triggerSpell = buffSpell.Trigger(i)
        if not (triggerSpell and triggerSpell() and triggerSpell.ID() > 0) then
            Logger.log_verbose("PeerBuffCheck: We've checked every trigger for %s(ID:%d).", spellName, spellId)
            break
        end
        hasTriggers = true

        local triggerName = triggerSpell.Name()
        local triggerId = triggerSpell.ID()
        local triggerResult = DanNet.query(targetName, string.format("Me.FindBuff[id %d]", triggerId), 1000)

        if triggerResult:lower() == triggerName:lower() then
            Logger.log_verbose("PeerBuffCheck: Trigger %s(ID:%d) found on %s(ID:%d), moving on.", triggerName, triggerId, targetName, targetId)
        elseif triggerResult:lower() == "null" then
            local triggerBlocked = false
            if not skipBlockCheck then
                local triggerBlockedResult = DanNet.query(targetName, string.format("Me.BlockedBuff[%s]", triggerName), 1000)
                if triggerBlockedResult:lower() == triggerName:lower() then
                    triggerBlocked = true
                end
            end
            if triggerBlocked then
                Logger.log_verbose("PeerBuffCheck: Trigger %s(ID:%d) is blocked on %s(ID:%d), counting as present.", triggerName, triggerId, targetName, targetId)
            else
                local triggerStackResult = DanNet.query(targetName, string.format("Spell[%d].Stacks", triggerId), 1000)
                if triggerStackResult:lower() == "true" then
                    Logger.log_verbose("PeerBuffCheck: Trigger %s(ID:%d) missing and stacks on %s(ID:%d), let's do it!", triggerName, triggerId, targetName, targetId)
                    return true
                end
                Logger.log_verbose("PeerBuffCheck: Trigger %s(ID:%d) does not stack on %s(ID:%d), moving on.", triggerName, triggerId, targetName, targetId)
            end
        end
    end

    if not hasTriggers and not spellPresent then
        Logger.log_verbose("PeerBuffCheck: %s(ID:%d) missing on %s(ID:%d) and stacks with no triggers, let's do it!", spellName, spellId, targetName, targetId)
        return true
    end

    Logger.log_verbose("PeerBuffCheck: %s(ID:%d) handled on %s(ID:%d), no need to cast.", spellName, spellId, targetName, targetId)
    return false
end

--- Complex buff check that will check for presence and stacking of the buff (and any triggers) on an actor peer.
--- @param spellId integer The ID of the spell to check.
--- @param target MQTarget|MQSpawn|MQCharacter? The target to check for the buff.
--- @param skipBlockCheck boolean|nil whether to skip checking the peers blocked spells, this needs to be skipped for certain manual stacking checks
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.ActorBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck, heartbeat, spell)
    if not spellId then return false end
    if not (target and target()) then return false end

    local targetName = target.DisplayName()
    local targetId = target.ID()
    local buffSpell = spell or mq.TLO.Spell(spellId)
    local spellName = buffSpell.Name() or buffSpell()

    if not spellName then return false end

    local heartbeat = heartbeat or Comms.GetPeerHeartbeatByName(targetName)

    if not heartbeat or not heartbeat.Data then
        Logger.log_error(
            "ActorBuffCheck: Tried to check a peer's buff, but that peer isn't found! If this behavior continues, please report this. Spell:%s(ID:%d), Target:%s(ID:%d)", spellName,
            spellId, targetName, targetId)
        return false
    end

    local blockedList = heartbeat.Data.Blocked
    local openBuffs = heartbeat.Data.OpenBuffSlots
    local buffList = heartbeat.Data.Buffs
    local songList = heartbeat.Data.Songs

    if not blockedList or not openBuffs or not songList or not buffList then
        Logger.log_error(
            "ActorBuffCheck: Tried to check a peer's buff, but data is not available! Fallng back on Dannet. If this behavior continues, please report this. Spell:%s(ID:%d), Target:%s(ID:%d)",
            spellName, spellId, targetName, targetId)
        return Casting.PeerBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck)
    end

    local spellBlocked = not skipBlockCheck and Tables.TableContains(blockedList, spellId)
    if spellBlocked then
        Logger.log_verbose("ActorBuffCheck: %s(ID:%d) is blocked on %s(ID:%d), counting as present.", spellName, spellId, targetName, targetId)
    end

    local spellWindow = buffSpell.DurationWindow()
    local activeList = spellWindow == 1 and songList or buffList
    local spellPresent = spellBlocked or Tables.TableContains(activeList, spellId)

    -- if the spell isn't already up and the target's buff window is full, have the PC check via DanNet to see if this could overwrite an existing spell instead of assuming it won't land
    if not spellPresent and spellWindow == 0 and openBuffs <= 0 then
        Logger.log_verbose("ActorBuffCheck: %s has a full buff window, falling back on DanNet checks for %s(ID:%d).", targetName, spellName, spellId)
        return Casting.PeerBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck)
    end

    if not spellPresent then
        for _, buffId in ipairs(activeList) do
            ---@diagnostic disable-next-line: redundant-parameter
            if not buffSpell.StacksWith(buffId)() then
                Logger.log_verbose("ActorBuffCheck: %s(ID:%d) does not stack with %s(ID:%d) on %s(ID:%d), ending check.", spellName, spellId,
                    mq.TLO.Spell(buffId).Name() or "Error", buffId, targetName, targetId)
                return false
            end
        end
    end

    if skipTriggerCheck then
        if spellPresent then
            Logger.log_verbose("ActorBuffCheck: %s(ID:%d) present on %s(ID:%d), trigger check skipped.", spellName, spellId, targetName, targetId)
            return false
        end
        Logger.log_verbose("ActorBuffCheck: %s(ID:%d) missing on %s(ID:%d) and stacks, trigger check skipped, let's do it!", spellName, spellId, targetName, targetId)
        return true
    end

    Logger.log_verbose("ActorBuffCheck: %s(ID:%d) checking for triggers on %s(ID:%d).", spellName, spellId, targetName, targetId)
    local numEffects = buffSpell.NumEffects()
    local hasTriggers = false
    for i = 1, numEffects do
        local triggerSpell = buffSpell.Trigger(i)
        --Some Laz spells report trigger 1 as "Unknown Spell" with an ID of 0, which always reports false on stack checks
        if not (triggerSpell and triggerSpell() and triggerSpell.ID() > 0) then
            Logger.log_verbose("ActorBuffCheck: We've checked every trigger for %s(ID:%d).", spellName, spellId)
            break
        end
        hasTriggers = true

        local triggerName = triggerSpell.Name()
        local triggerId = triggerSpell.ID()
        local triggerWindow = triggerSpell.DurationWindow()
        local triggerActiveList = triggerWindow == 1 and songList or buffList

        if not skipBlockCheck and Tables.TableContains(blockedList, triggerId) then
            Logger.log_verbose("ActorBuffCheck: Trigger %s(ID:%d) is blocked on %s(ID:%d), counting as present.", triggerName, triggerId, targetName, targetId)
        elseif Tables.TableContains(triggerActiveList, triggerId) then
            Logger.log_verbose("ActorBuffCheck: Trigger %s(ID:%d) found on %s(ID:%d), moving on.", triggerName, triggerId, targetName, targetId)
        elseif triggerWindow == 0 and openBuffs <= 0 then
            -- if the trigger isn't already up and the target's buff window is full, have the PC check via DanNet to see if this could overwrite an existing spell instead of assuming it won't land
            if Casting.PeerBuffCheck(triggerId, target, true, true) then
                Logger.log_verbose("ActorBuffCheck: Trigger %s(ID:%d) missing and stacks on %s(ID:%d) via fallback, let's do it!", triggerName, triggerId, targetName, targetId)
                return true
            end
        else
            local stacks = true
            for _, buffId in ipairs(triggerActiveList) do
                ---@diagnostic disable-next-line: redundant-parameter
                if not triggerSpell.StacksWith(buffId)() then
                    Logger.log_verbose("ActorBuffCheck: Trigger %s(ID:%d) does not stack with %s(ID:%d) on %s(ID:%d), moving on.", triggerName, triggerId,
                        mq.TLO.Spell(buffId).Name() or "Error", buffId, targetName, targetId)
                    stacks = false
                    break
                end
            end
            if stacks then
                Logger.log_verbose("ActorBuffCheck: Trigger %s(ID:%d) missing and stacks on %s(ID:%d), let's do it!", triggerName, triggerId, targetName, targetId)
                return true
            end
        end
    end

    if not hasTriggers and not spellPresent then
        Logger.log_verbose("ActorBuffCheck: %s(ID:%d) missing on %s(ID:%d) and stacks with no triggers, let's do it!", spellName, spellId, targetName, targetId)
        return true
    end

    Logger.log_verbose("ActorBuffCheck: %s(ID:%d) handled on %s(ID:%d), no need to cast.", spellName, spellId, targetName, targetId)
    return false
end

--- Complex buff check that will check for presence and stacking of the buff (and any triggers) on an actor peer.
--- @param spellId integer The ID of the spell to check.
--- @param target MQTarget|MQSpawn|MQCharacter? The target to check for the buff.
--- @param skipBlockCheck boolean|nil whether to skip checking the peers blocked spells, this needs to be skipped for certain manual stacking checks
--- @param skipTriggerCheck boolean|nil whether to skip a check for spell triggers, to be used for cost savings when we know the spell does not have triggers
--- @return boolean True if the PC checking should cast the buff, false otherwise.
function Casting.ActorPetBuffCheck(spellId, target, skipBlockCheck, skipTriggerCheck, heartbeat, spell)
    if not spellId then return false end
    if not (target and target()) then return false end

    local targetName = target.Master.DisplayName()
    local targetId = target.ID()
    local buffSpell = spell or mq.TLO.Spell(spellId)
    local spellName = buffSpell.Name() or buffSpell()

    if not spellName then return false end

    local masterName = target.Master() and target.Master.DisplayName() or nil

    local heartbeat = heartbeat or (masterName and Comms.GetPeerHeartbeatByName(masterName) or nil)

    if not heartbeat or not heartbeat.Data then
        Logger.log_error(
            "ActorPetBuffCheck: Tried to check a peer's pet buff, but that peer isn't found! " ..
            "If this behavior continues, please report this. Spell:%s(ID:%d), Target:%s(ID:%d)",
            spellName, spellId, targetName, targetId)
        return false
    end

    local blockedList = heartbeat.Data.PetBlocked
    local buffList = heartbeat.Data.PetBuffs

    if not blockedList or not buffList then
        Logger.log_error(
            "ActorPetBuffCheck: Tried to check a peer's pet buff, but data is not available! If this behavior continues, please report this. Spell:%s(ID:%d), Target:%s(ID:%d)",
            spellName, spellId, targetName, targetId)
        return false
    end

    local spellBlocked = not skipBlockCheck and Tables.TableContains(blockedList, spellId)
    if spellBlocked then
        Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) is blocked on %s's pet(%s, ID:%d), counting as present.", spellName, spellId, masterName, targetName, targetId)
    end

    local spellPresent = spellBlocked or Tables.TableContains(buffList, spellId)

    if not spellPresent then
        for _, buffId in ipairs(buffList) do
            ---@diagnostic disable-next-line: redundant-parameter
            if not buffSpell.StacksWith(buffId)() then
                Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) does not stack with %s(ID:%d) on %s's pet(%s, ID:%d), ending check.", spellName, spellId,
                    mq.TLO.Spell(buffId).Name() or "Error", buffId, masterName, targetName, targetId)
                return false
            end
        end
    end

    if skipTriggerCheck then
        if spellPresent then
            Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) present on %s's pet(%s, ID:%d), trigger check skipped.", spellName, spellId, masterName, targetName, targetId)
            return false
        end
        Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) missing on %s's pet(%s, ID:%d) and stacks, trigger check skipped, let's do it!", spellName, spellId, masterName, targetName,
            targetId)
        return true
    end

    Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) checking for triggers on %s's pet(%s, ID:%d).", spellName, spellId, masterName, targetName, targetId)
    local numEffects = buffSpell.NumEffects()
    local hasTriggers = false
    for i = 1, numEffects do
        local triggerSpell = buffSpell.Trigger(i)
        --Some Laz spells report trigger 1 as "Unknown Spell" with an ID of 0, which always reports false on stack checks
        if not (triggerSpell and triggerSpell() and triggerSpell.ID() > 0) then
            Logger.log_verbose("ActorPetBuffCheck: We've checked every trigger for %s(ID:%d).", spellName, spellId)
            break
        end
        hasTriggers = true

        local triggerName = triggerSpell.Name()
        local triggerId = triggerSpell.ID()

        if not skipBlockCheck and Tables.TableContains(blockedList, triggerId) then
            Logger.log_verbose("ActorPetBuffCheck: Trigger %s(ID:%d) is blocked on %s's pet(%s, ID:%d), counting as present.", triggerName, triggerId, masterName, targetName,
                targetId)
        elseif Tables.TableContains(buffList, triggerId) then
            Logger.log_verbose("ActorPetBuffCheck: Trigger %s(ID:%d) found on %s's pet(%s, ID:%d), moving on.", triggerName, triggerId, masterName, targetName, targetId)
        else
            local stacks = true
            for _, buffId in ipairs(buffList) do
                ---@diagnostic disable-next-line: redundant-parameter
                if not triggerSpell.StacksWith(buffId)() then
                    Logger.log_verbose("ActorPetBuffCheck: Trigger %s(ID:%d) does not stack with %s(ID:%d) on %s's pet(%s, ID:%d), moving on.", triggerName, triggerId,
                        mq.TLO.Spell(buffId).Name() or "Error", buffId, masterName, targetName, targetId)
                    stacks = false
                    break
                end
            end
            if stacks then
                Logger.log_verbose("ActorPetBuffCheck: Trigger %s(ID:%d) missing and stacks on %s's pet(%s, ID:%d), let's do it!", triggerName, triggerId, masterName, targetName,
                    targetId)
                return true
            end
        end
    end

    if not hasTriggers and not spellPresent then
        Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) missing on %s's pet(%s, ID:%d) and stacks with no triggers, let's do it!", spellName, spellId, masterName, targetName,
            targetId)
        return true
    end

    Logger.log_verbose("ActorPetBuffCheck: %s(ID:%d) handled on %s's pet(%s, ID:%d), no need to cast.", spellName, spellId, masterName, targetName, targetId)
    return false
end

--- Checks if an aura is active by its name.
--- @param auraName string The name of the aura to check.
--- @return boolean True if the aura is active, false otherwise.
function Casting.AuraActiveByName(auraName)
    if not auraName then return false end
    local stripName = string.gsub(auraName, "'", "")
    for i = 1, Casting.MaxAuraSlots() do
        local slot = mq.TLO.Me.Aura(i)() or ""
        if string.find(slot, auraName) or string.find(slot, stripName) then
            return true
        end
    end
    return false
end

--- Returns the maximum number of aura slots the player can have active.
--- @return integer
function Casting.MaxAuraSlots()
    if Core.OnLaz() then return 1 end
    local auroriaSlots = Casting.AARank('Auroria Mastery')
    local spiritSlots = Casting.CanUseAA('Spirit Mastery') and 1 or 0
    return auroriaSlots + spiritSlots + 1
end

--- Returns true if at least one aura slot is currently empty.
--- @return boolean
function Casting.HasFreeAuraSlot()
    for i = 1, Casting.MaxAuraSlots() do
        if (mq.TLO.Me.Aura(i)() or "") == "" then return true end
    end
    return false
end

--- Verifies the player has the spell's expended reagent (ReagentID slot 1) and, on live servers, the non-expended reagent (NoExpendReagentID slot 1) in inventory. Announces a chat message to the group/raid if either is missing. Returns false if any required reagent is absent.
--- @param spell MQSpell The name of the spell to check for reagents.
--- @return boolean True if the required reagents are available, false otherwise.
function Casting.ReagentCheck(spell)
    if not spell or not spell() then return false end

    if spell.ReagentID(1)() > 0 and mq.TLO.FindItemCount(spell.ReagentID(1)())() == 0 then
        Logger.log_verbose("Missing Reagent: (%d)", spell.ReagentID(1)())
        Comms.HandleAnnounce(Comms.FormatChatEvent("Cast", mq.TLO.Me.CleanName(),
                string.format('I want to cast %s, but I am missing a reagent(%d)!', spell(), spell.ReagentID(1)())),
            Config:GetSetting('ReagentAnnounceGroup'),
            Config:GetSetting('ReagentAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
        return false
    end

    if not Core.OnEMU() then
        if spell.NoExpendReagentID(1)() > 0 and mq.TLO.FindItemCount(spell.NoExpendReagentID(1)())() == 0 then
            Logger.log_verbose("Missing NoExpendReagent: (%d)", spell.NoExpendReagentID(1)())
            Comms.HandleAnnounce(
                Comms.FormatChatEvent("Cast", mq.TLO.Me.CleanName(),
                    string.format('I want to cast %s, but I am missing a non-expended reagent(%d)!', spell(), spell.NoExpendReagentID(1)())),
                Config:GetSetting('ReagentAnnounceGroup'),
                Config:GetSetting('ReagentAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
            return false
        end
    end

    return true
end

--- Returns true when DoShrink is enabled, a ShrinkItem is configured, the player's height is 2.3 or greater (i.e., not already shrunk), and OkayToBuff passes (visible, safe, stationary, not low-mana).
--- @return boolean True if the PC should be shrunk, false otherwise.
function Casting.ShouldShrink()
    return Config:GetSetting('DoShrink') and mq.TLO.Me.Height() >= 2.3 and
        (Config:GetSetting('ShrinkItem'):len() > 0) and Casting.OkayToBuff()
end

--- Returns true when DoShrinkPet is enabled, a ShrinkPetItem is configured, a pet exists, the pet's height is 1.9 or greater (i.e., not already shrunk), and OkayToPetBuff passes (DoPet enabled plus the same safe/stationary/visible/mana gates as OkayToBuff).
--- @return boolean True if the pet should be shrunk, false otherwise.
function Casting.ShouldShrinkPet()
    return Config:GetSetting('DoShrinkPet') and mq.TLO.Me.Pet.ID() > 0 and mq.TLO.Me.Pet.Height() >= 1.9 and
        (Config:GetSetting('ShrinkPetItem'):len() > 0) and Casting.OkayToPetBuff()
end

--- Evaluates three burn triggers: autoBurn (BurnAuto enabled and XT hater count exceeds BurnMobCount, or the auto-target is a named mob with BurnNamed enabled), alwaysBurn (BurnAuto and BurnAlways both set), and forcedBurn (ForceBurnTargetID matches the current target). Caches the result in Globals.LastBurnCheck and announces state changes to the group/raid.
--- @return boolean True if the burn condition is met, false otherwise.
function Casting.BurnCheck()
    local burnTarget = Targeting.GetAutoTarget()
    local burnTargetName = burnTarget and (burnTarget() and burnTarget.CleanName() or "None") or "None"
    local autoBurn = Config:GetSetting('BurnAuto') and
        ((Targeting.GetXTHaterCount() >= Config:GetSetting('BurnMobCount')) or (Globals.AutoTargetIsNamed and Config:GetSetting('BurnNamed') and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('NamedMinHPPct')))
    local alwaysBurn = (Config:GetSetting('BurnAlways') and Config:GetSetting('BurnAuto'))
    local forcedBurn = Targeting.ForceBurnTargetID > 0 and Targeting.ForceBurnTargetID == mq.TLO.Target.ID()

    local previousBurnState = Globals.LastBurnCheck

    Globals.LastBurnCheck = autoBurn or alwaysBurn or forcedBurn

    if Globals.LastBurnCheck ~= previousBurnState then
        Logger.log_info("BurnCheck: Burn state changed to %s.", tostring(Globals.LastBurnCheck))
        Comms.HandleAnnounce(Comms.FormatChatEvent("Burn", burnTargetName, Globals.LastBurnCheck and "Starting" or "Completed"), Config:GetSetting('BurnAnnounceGroup'),
            Config:GetSetting('BurnAnnounce'),
            Config:GetSetting('AnnounceToRaidIfInRaid'))
    end
    return Globals.LastBurnCheck
end

--- Returns true if the player currently has the "Gift of Mana" proc buff active in their buff or song window, indicating the next spell of appropriate type will cost no mana.
--- @return boolean
function Casting.GOMCheck()
    return Casting.IHaveBuff("Gift of Mana")
end

--- Resolves the 'GambitSpell' action map entry and checks whether that spell's buff is currently active in the player's buff or song window — used by Wizard to gate gambit-dependent nukes.
--- @return boolean Returns true if the gambit condition is met, false otherwise.
function Casting.GambitCheck() -- This should probably be moved to wizard as a helper --Algar
    local gambitSpell = Core.GetResolvedActionMapItem('GambitSpell')
    if not gambitSpell or not gambitSpell() then return false end

    return Casting.IHaveBuff(gambitSpell)
end

--- Stub seemingly intended for alliance spell use
--- @return boolean True if an alliance can be formed, false otherwise.
function Casting.CanAlliance()
    return true
end

--- The EMU consider-event "already rezzed?" determination (the expensive
--- part of OkayToRez): targets and /consider's the corpse, waits up to 1s
--- for the con event. No-op (returns true) when ConCorpseForRez is off.
---@param corpseId number The spawn ID of the corpse to evaluate.
---@return boolean True if the corpse is present and not yet rezzed.
function Casting.OkayToRezConsider(corpseId)
    if not Config:GetSetting('ConCorpseForRez') then return true end

    Globals.CorpseConned = false
    Targeting.SetTarget(corpseId, true)
    Core.DoCmd("/consider")

    local maxWait = 1000
    while maxWait > 0 do
        mq.doevents('CorpseConned')
        mq.delay(50)
        Events.DoEvents()
        if not mq.TLO.Spawn(corpseId)() then
            Logger.log_debug("\atEmuOkayToRez(): Corpse ID %d no longer exists, did someone else rez it? Aborting.", corpseId or 0)
            return false
        end
        if Globals.CorpseConned then
            mq.doevents('AlreadyRezzed')
            if Tables.TableContains(Globals.RezzedCorpses, corpseId) then
                Logger.log_debug("\atEmuOkayToRez(): Checked corpse ID %d, and it appears to have been rezzed already. Aborting.", corpseId or 0)
                return false
            else
                Logger.log_debug("\atEmuOkayToRez(): Checked corpse ID %d, and it appears to be in need of a rez. Proceeding.", corpseId or 0)
                break
            end
        end

        maxWait = maxWait - 50
        if maxWait <= 0 then
            Logger.log_warn(
                "\atEmuOkayToRez(): \arWarning! \atChecked corpse ID %d, but did not receive a con message. Allowing the check to proceed, but this may rez a corpse that has previously received one.",
                corpseId or 0)
        end
    end
    return true
end

Casting.RezConsiderCache = {}

--- Targets and /consider's the corpse (EMU only, ConCorpseForRez) to check for a prior rez, summoning it via
--- /corpse if beyond 25 units. The consider result is memoized briefly (per corpse) so a single rez pass doesn't
--- re-/consider the same corpse once per candidate entry; the /corpse summon still runs every call.
---@param corpseId number The spawn ID of the corpse to evaluate.
---@return boolean True if the corpse is present, in range, and unrezzed.
function Casting.OkayToRez(corpseId)
    local cached = Casting.RezConsiderCache[corpseId]
    local okay
    if cached and (Globals.GetTimeSeconds() - cached.time) < 2 then
        okay = cached.okay
    else
        okay = Casting.OkayToRezConsider(corpseId)
        Casting.RezConsiderCache[corpseId] = { time = Globals.GetTimeSeconds(), okay = okay, }
    end
    if not okay then return false end

    if mq.TLO.Spawn(corpseId).Distance3D() > 25 then
        Targeting.SetTarget(corpseId, true)
        Core.DoCmd("/corpse")
    end

    return true
end

--- EQ rejects InCombat=0 rez spells (e.g. Incarnate Anew, Larger Reviviscence)
--- unless the client CombatState is ACTIVE or RESTING; the RGMercs Downtime
--- phase also covers the post-combat COOLDOWN window where those casts fail.
---@return boolean True when an OOC-only rez spell may be cast.
function Casting.DowntimeRezOkay()
    local state = (mq.TLO.Me.CombatState() or ""):lower()
    return state == "active" or state == "resting"
end

--- Returns false immediately if the DoBuffs setting is off, otherwise delegates to CheckOkayToBuff which verifies the player is visible, not in combat, stationary long enough, and not critically low on mana.
--- @return boolean
function Casting.OkayToBuff()
    if not Config:GetSetting('DoBuffs') then return false end
    return Casting.CheckOkayToBuff()
end

--- Returns false immediately if the DoPet setting is off, otherwise delegates to CheckOkayToBuff which verifies the player is visible, not in combat, stationary long enough, and not critically low on mana.
--- @return boolean Returns true if the pet check is successful, false otherwise.
function Casting.OkayToPetBuff()
    if not Config:GetSetting('DoPet') then return false end
    return Casting.CheckOkayToBuff()
end

--- Core gate for OkayToBuff/OkayToPetBuff: checks visibility, no
--- XT haters or auto-target, stationary long enough (BuffWaitMoveTimer),
--- and casters above 10% mana.
---@return boolean True if all buff-safety conditions are met.
function Casting.CheckOkayToBuff()
    local visible = not mq.TLO.Me.Invis()
    local safe = Targeting.GetXTHaterCount() == 0 and Globals.AutoTargetID == 0
    local stationary = not (Config:GetSetting('BuffWaitMoveTimer') > Movement:GetTimeSinceLastMove() or mq.TLO.MoveTo.Moving() or mq.TLO.Me.Moving() or mq.TLO.Navigation.Active())
    local able = not (Globals.Constants.RGCasters:contains(mq.TLO.Me.Class.ShortName()) and mq.TLO.Me.PctMana() < 10)

    return visible and safe and stationary and able
end

--- Gates debuffing on aggro threshold, ManaToDebuff, and the debuff
--- policy (NamedDebuff or MobDebuff) vs. target con color.
---@param bIgnoreAggro boolean? Skip the aggro threshold check if true.
--- @return boolean True if all debuff-gate conditions are met.
function Casting.OkayToDebuff(bIgnoreAggro)
    local enoughMana = Casting.HaveManaToDebuff()
    local lowAggro = bIgnoreAggro or Targeting.AggroCheckOkay()
    local named = Globals.AutoTargetIsNamed
    local debuffChoice = Globals.Constants.DebuffChoice[Config:GetSetting(named and 'NamedDebuff' or 'MobDebuff')]
    local conLevel = (Globals.Constants.ConColorsNameToId[mq.TLO.Target.ConColor() or "Grey"] or 0)

    return lowAggro and enoughMana and (debuffChoice == "Always" or (debuffChoice == "Based on Con Color" and conLevel >= Config:GetSetting('DebuffMinCon')))
end

--- Gates nuking on aggro threshold (AggroCheckOkay) and mana above
--- ManaToNuke. Burn state bypasses the mana gate unless restricted.
---@param bRestrictBurns boolean? Ignore burn state for mana gate if true.
---@return boolean True if aggro and mana conditions are met.
function Casting.OkayToNuke(bRestrictBurns)
    local lowAggro = Targeting.AggroCheckOkay()
    local enoughMana = Casting.HaveManaToNuke(bRestrictBurns)

    return lowAggro and enoughMana
end

--- Returns false if the player has a nearby corpse (within 100/50 units) and BuffRezables is not set — used to abort buff rotations when the player is waiting for a rez, since buffs applied to a corpse state are wasted.
--- @return boolean True if the entity can be buffed, false otherwise.
function Casting.AmIBuffable()
    local myCorpseCount = Config:GetSetting('BuffRezables') and 0 or mq.TLO.SpawnCount(string.format('pccorpse =%s radius 100 zradius 50', mq.TLO.Me.CleanName()))()
    if myCorpseCount > 0 then Logger.log_debug("Corpse detected (%s), aborting rotation.", mq.TLO.Me.CleanName()) end
    return myCorpseCount == 0
end

--- SpawnCount search for a PC corpse within 100 horizontal and
--- 50 vertical units of the player.
---@param name string The PC name to search for.
---@return boolean True if a nearby corpse for that name exists.
function Casting.HasNearbyCorpse(name)
    return mq.TLO.SpawnCount(string.format("pccorpse =%s radius 100 zradius 50", name))() > 0
end

--- Dispatches to GetBuffableInZoneIDs, GetBuffableRaidIDs, or
--- GetBuffableGroupIDs based on the ActorBuffScope setting.
---@return table List of spawn IDs eligible to receive buffs.
function Casting.GetBuffableIDs()
    -- 1 = group only, 2 = raid 3 = in-zone... i just couldn't really justify a constants table for this
    local scope = Config:GetSetting('ActorBuffScope')
    if scope == 3 then return Casting.GetBuffableInZoneIDs() end
    if scope == 2 then return Casting.GetBuffableRaidIDs() end
    return Casting.GetBuffableGroupIDs()
end

--- Builds a deduplicated buff-eligible ID list from all in-zone
--- sources: player, group members, actor peers and their pets
--- (DoActorPetBuffs), and assist list. Aborts on nearby corpse.
---@return table Deduplicated list of in-zone spawn IDs for buffing.
function Casting.GetBuffableInZoneIDs()
    -- Corpse checks only guard downtime buff cycles; in combat, rebuff regardless.
    local inCombat = Combat.GetCachedCombatState() == "Combat"
    if not inCombat and not Casting.AmIBuffable() then
        return {}
    end

    local zoneIds = Set.new({})
    local checkCorpses = not Config:GetSetting('BuffRezables') and not inCombat

    -- if we are driving, check ourselves first
    if mq.TLO.EverQuest.Foreground() then
        zoneIds:add(mq.TLO.Me.ID())
    end

    local count = mq.TLO.Group.Members()
    for i = 1, count do
        local member = mq.TLO.Group.Member(i)
        if not member.OtherZone() then
            local memberName = member.DisplayName()
            if checkCorpses and Casting.HasNearbyCorpse(memberName) then
                Logger.log_debug("Groupmember corpse detected (%s), aborting group buff rotation.", memberName)
                return {}
            end
            zoneIds:add(member.ID())
        end
    end

    -- if we aren't foregrounded, check ourselves after we've already buffed the group (tank is likeliest to be first ID this way)
    zoneIds:add(mq.TLO.Me.ID())

    if Config:GetSetting("DoActorPetBuffs") then
        if mq.TLO.Pet.ID() > 0 then
            if not (mq.TLO.Pet.CleanName() or "familiar"):lower():find("familiar") then
                zoneIds:add(mq.TLO.Pet.ID())
            end
        end
    end

    for _, peer in ipairs(Comms.GetPeers(false)) do
        local peerName = Comms.GetNameFromPeer(peer)
        if peerName then
            local zoneSpawn = mq.TLO.Spawn(("pc =%s"):format(peerName))
            if zoneSpawn and zoneSpawn() then
                if checkCorpses and Casting.HasNearbyCorpse(peerName) then
                    Logger.log_debug("Peer corpse detected (%s), aborting group buff rotation.", peerName)
                    return {}
                end

                zoneIds:add(zoneSpawn.ID())

                if Config:GetSetting("DoActorPetBuffs") then
                    local groupMember = mq.TLO.Group.Member(peerName or "")
                    if groupMember() and groupMember.Pet.ID() > 0 then
                        if not (groupMember.Pet.CleanName() or "familiar"):lower():find("familiar") then
                            zoneIds:add(groupMember.Pet.ID())
                        end
                    end
                end
            end
        end
    end

    if Config:GetSetting("BuffAssistList") then
        for _, name in ipairs(Config:GetSetting('AssistList')) do
            local listSpawn = mq.TLO.Spawn(("pc =%s"):format(name))
            if listSpawn and listSpawn() then
                if checkCorpses and Casting.HasNearbyCorpse(name) then
                    Logger.log_debug("Assist List corpse detected (%s), aborting group buff rotation.", name)
                    return {}
                end
                zoneIds:add(listSpawn.ID())
            end
        end
    end

    return zoneIds:toList()
end

--- Builds a deduplicated buff-eligible ID list from raid sources:
--- player, group members, actor peers who are raid members and their
--- pets (DoActorPetBuffs), and assist list. Aborts on nearby corpse.
---@return table Deduplicated list of raid spawn IDs for buffing.
function Casting.GetBuffableRaidIDs()
    -- Corpse checks only guard downtime buff cycles; in combat, rebuff regardless.
    local inCombat = Combat.GetCachedCombatState() == "Combat"
    if not inCombat and not Casting.AmIBuffable() then
        return {}
    end

    local raidIds = Set.new({})
    local checkCorpses = not Config:GetSetting('BuffRezables') and not inCombat

    -- if we are driving, check ourselves first
    if mq.TLO.EverQuest.Foreground() then
        raidIds:add(mq.TLO.Me.ID())
    end

    local count = mq.TLO.Group.Members()
    for i = 1, count do
        local member = mq.TLO.Group.Member(i)
        if not member.OtherZone() then
            local memberName = member.DisplayName()
            if checkCorpses and Casting.HasNearbyCorpse(memberName) then
                Logger.log_debug("Groupmember corpse detected (%s), aborting group buff rotation.", memberName)
                return {}
            end
            raidIds:add(member.ID())
        end
    end

    -- if we aren't foregrounded, check ourselves after we've already buffed the group (tank is likeliest to be first ID this way)
    raidIds:add(mq.TLO.Me.ID())

    if Config:GetSetting("DoActorPetBuffs") then
        if mq.TLO.Pet.ID() > 0 then
            if not (mq.TLO.Pet.CleanName() or "familiar"):lower():find("familiar") then
                raidIds:add(mq.TLO.Pet.ID())
            end
        end
    end

    for _, peer in ipairs(Comms.GetPeers(false)) do
        local peerName = Comms.GetNameFromPeer(peer)
        local raidMember = mq.TLO.Raid.Member(peerName or "")
        if raidMember() and raidMember.Spawn() then
            if checkCorpses and Casting.HasNearbyCorpse(peer) then
                Logger.log_debug("Raidmember corpse detected (%s), aborting group buff rotation.", peer)
                return {}
            end
            raidIds:add(raidMember.ID())

            if Config:GetSetting("DoActorPetBuffs") then
                local groupMember = mq.TLO.Group.Member(peer)
                if groupMember() and groupMember.Pet.ID() > 0 and not groupMember.OtherZone() then
                    if not (groupMember.Pet.CleanName() or "familiar"):lower():find("familiar") then
                        raidIds:add(groupMember.Pet.ID())
                    end
                end
            end
        end
    end

    if Config:GetSetting("BuffAssistList") then
        for _, name in ipairs(Config:GetSetting('AssistList')) do
            local listSpawn = mq.TLO.Spawn(("pc =%s"):format(name))
            if listSpawn and listSpawn() then
                if checkCorpses and Casting.HasNearbyCorpse(name) then
                    Logger.log_debug("Assist List corpse detected (%s), aborting group buff rotation.", name)
                    return {}
                end
                raidIds:add(listSpawn.ID())
            end
        end
    end

    return raidIds:toList()
end

--- Builds a deduplicated buff-eligible ID list from group sources:
--- player, group members and their actor-peer pets (DoActorPetBuffs),
--- own pet, and non-group assist list. Aborts on nearby corpse.
--- @return table Deduplicated list of group spawn IDs for buffing.
function Casting.GetBuffableGroupIDs()
    -- Corpse checks only guard downtime buff cycles; in combat, rebuff regardless.
    local inCombat = Combat.GetCachedCombatState() == "Combat"
    if not inCombat and not Casting.AmIBuffable() then
        return {}
    end

    local groupIds = Set.new({})
    local checkCorpses = not Config:GetSetting('BuffRezables') and not inCombat

    -- if we are driving, check ourselves first
    if mq.TLO.EverQuest.Foreground() then
        groupIds:add(mq.TLO.Me.ID())
    end

    local count = mq.TLO.Group.Members()
    for i = 1, count do
        local member = mq.TLO.Group.Member(i)
        if not member.OtherZone() then
            local memberName = member.DisplayName()
            if checkCorpses and Casting.HasNearbyCorpse(memberName) then
                Logger.log_debug("Groupmember corpse detected (%s), aborting group buff rotation.", memberName)
                return {}
            end
            groupIds:add(member.ID())
            if Config:GetSetting("DoActorPetBuffs") then
                if Comms.GetPeerHeartbeatByName(memberName).Data then
                    local petId = member() and member.Pet.ID() or 0
                    if petId > 0 then
                        if not (member.Pet.CleanName() or "familiar"):lower():find("familiar") then
                            groupIds:add(petId)
                        end
                    end
                end
            end
        end
    end

    -- if we aren't foregrounded, check ourselves after we've already buffed the group (tank is likeliest to be first ID this way)
    groupIds:add(mq.TLO.Me.ID())

    if Config:GetSetting("DoActorPetBuffs") then
        if mq.TLO.Pet.ID() > 0 then
            if not (mq.TLO.Pet.CleanName() or "familiar"):lower():find("familiar") then
                groupIds:add(mq.TLO.Pet.ID())
            end
        end
    end

    if Config:GetSetting("BuffAssistList") then
        for _, name in ipairs(Config:GetSetting('AssistList')) do
            if not mq.TLO.Group.Member(name)() then
                local listSpawn = mq.TLO.Spawn(("pc =%s"):format(name))
                if listSpawn and listSpawn() then
                    if checkCorpses and Casting.HasNearbyCorpse(name) then
                        Logger.log_debug("Assist List corpse detected (%s), aborting group buff rotation.", name)
                        return {}
                    end
                    groupIds:add(listSpawn.ID())
                end
            end
        end
    end

    return groupIds:toList()
end

--- Returns buff-eligible spawn IDs in the active scope that are currently tanking (same-zone peers by broadcast flag, others by tank class or group main tank).
---@return table List of spawn IDs of buff-eligible tanks.
function Casting.GetBuffableTankingIDs()
    local buffableIds = Casting.GetBuffableIDs()
    if #buffableIds == 0 then return {} end

    local myServer = mq.TLO.EverQuest.Server() or ""
    local myZoneId = mq.TLO.Zone.ID() or 0
    local myInstance = mq.TLO.Me.Instance() or 0

    -- Spawn IDs repeat across zones, so only index same-zone/instance peers to avoid id collisions.
    local tankById = {}
    local petIds = {}
    for _, heartbeat in pairs(Comms.PeersHeartbeats) do
        local data = heartbeat.Data
        if data and data.Server == myServer and data.ZoneId == myZoneId and data.InstanceId == myInstance then
            if type(data.IsTanking) == "boolean" and (data.ID or 0) > 0 then
                tankById[data.ID] = data.IsTanking
            end
            if (data.PetID or 0) > 0 then
                petIds[data.PetID] = true
            end
        end
    end

    local myId = mq.TLO.Me.ID()
    if (mq.TLO.Me.Pet.ID() or 0) > 0 then petIds[mq.TLO.Me.Pet.ID()] = true end
    local iAmTanking = Core.IsTanking()
    local mainTankId = mq.TLO.Group.MainTank.ID() or 0

    local tankingIds = {}
    for _, id in ipairs(buffableIds) do
        local isTank
        if id == myId then
            isTank = iAmTanking
        elseif tankById[id] ~= nil then
            isTank = tankById[id]
        elseif petIds[id] then
            isTank = false
        else
            -- No broadcast flag (non-peer or standalone): fall back to tank class or the group main tank.
            local spawn = mq.TLO.Spawn(id)
            isTank = spawn() and spawn.Type() ~= "Pet" and (Globals.Constants.RGTank:contains(spawn.Class.ShortName()) or id == mainTankId)
        end
        if isTank then tankingIds[#tankingIds + 1] = id end
    end

    return tankingIds
end

--- Checks if the character is currently feigning death.
--- @return boolean True if the character is feigning death, false otherwise.
function Casting.IAmFeigning()
    return mq.TLO.Me.Feigning()
end

--- Returns true if the spell's ranked name is currently memorized in any gem slot on the spellbar (Me.Gem returns non-nil for that name).
--- @param spell MQSpell The name of the spell to check.
--- @return boolean Returns true if the spell is loaded, false otherwise.
function Casting.SpellLoaded(spell)
    if not spell or not spell() then return false end

    return mq.TLO.Me.Gem(spell.RankName.Name())() ~= nil
end

--- Checks if the spell is ready to cast (not in refresh, no gem timer).
---@param spell MQSpell The spell to check via Me.SpellReady.
---@return boolean True if the spell's gem timer has cleared.
function Casting.CastReady(spell)
    if not spell or not spell() then return false end
    return mq.TLO.Me.SpellReady(spell.RankName.Name())()
end

--- Issues /memspell for the given gem slot and polls until the slot shows the spell (and the gem is ready if waitSpellReady is true) or maxWait (ms) expires. Aborts early if aggro is gained, the player starts moving or casting, or the spell leaves the book due to a persona change. If AggressivelyMemorizeSpells is set and the gem stays empty past the configured timer, resends the /memspell command.
--- @param gem number The gem slot number where the spell should be memorized.
--- @param spell string The name of the spell to memorize.
--- @param waitSpellReady boolean Whether to wait until the spell is ready to be memorized.
--- @param maxWait number The maximum time to wait for the spell to be ready, in milliseconds.
--- @return boolean loaded True when the gem ended up showing the requested spell.
--- @return boolean permanent True when the spell is no longer in the book (e.g. persona change) and a retry is pointless.
function Casting.MemorizeSpell(gem, spell, waitSpellReady, maxWait)
    local me = mq.TLO.Me
    if (me.CombatState() or ""):lower() == "combat" and Targeting.IHaveAggro(100) then
        Logger.log_warning("\atMemorizeSpell\aw():\ar %s was not memorized in slot %d due to aggro! The loadout may need manual rescan after combat.", spell, gem)
        return false, false
    end
    local aggressiveMem      = Config:GetSetting('AggressivelyMemorizeSpells')
    local aggressiveMemTimer = Config:GetSetting('AggressivelyMemorizeTimer') * 1000

    -- Algarnote: Not sure where to put this, but there is a very edge-case bug that can cause us to memorize a lower level spell of the same name, since we can't use ID.
    -- /memspell (MQ) and /memspellslot (EQ) will memorize the first available by book position, which is generally the low level spell. Delete old spell, or swap positions in book to resolve... or add ID to /memspell
    local cmd                = string.format("/memspell %d \"%s\"", gem, spell)

    Logger.log_info("\atMemorizeSpell\aw():\ag Meming \aw%s in \agslot %d", spell, gem)
    Core.DoCmd(cmd)
    local lastMemCmd = Globals.GetTimeMS()

    Casting.Memorizing = true

    local interrupted = false
    local permanent = false
    local startMem = Globals.GetTimeMS()
    while (me.Gem(gem)() ~= mq.TLO.Spell(spell).Name() or (waitSpellReady and not me.SpellReady(gem)())) and ((Globals.GetTimeMS() - startMem) < maxWait) do
        Logger.log_debug("\atMemorizeSpell\aw():\ay Waiting for '%s' to load in slot %d'...", spell, gem)
        if ((me.CombatState() or ""):lower() == "combat" and Targeting.IHaveAggro(100)) or me.Casting() or me.Moving() or mq.TLO.Stick.Active() or mq.TLO.Navigation.Active() or mq.TLO.MoveTo.Moving() then
            Logger.log_debug(
                "\atMemorizeSpell\aw():\ay I was interrupted while waiting for spell '%s' to load in slot %d'! Aborting. CombatState(%s) Casting(%s) Moving(%s) Stick(%s) Nav(%s) MoveTo(%s))",
                spell, gem, me.CombatState(), me.Casting() or "None", Strings.BoolToColorString(me.Moving()), Strings.BoolToColorString(mq.TLO.Stick.Active()),
                Strings.BoolToColorString(mq.TLO.Navigation.Active()), Strings.BoolToColorString(mq.TLO.MoveTo.Moving()))
            interrupted = true
            break
        end
        if not me.Book(spell)() then
            Logger.log_debug("\atMemorizeSpell\aw():\ar I was trying to memorize %s as my persona was changed, aborting.", spell)
            permanent = true
            break
        end

        if me.Gem(gem)() == nil and aggressiveMem and (Globals.GetTimeMS() - lastMemCmd) > aggressiveMemTimer then
            Logger.log_debug(
                "\atMemorizeSpell\aw():\ay AggressiveMemorize is enabled and it's been more than %ds since the last mem command and the gem slot is still empty, resending mem command for '%s' in slot %d.",
                (Globals.GetTimeMS() - lastMemCmd) / 1000, spell, gem)
            Core.DoCmd(cmd)
            lastMemCmd = Globals.GetTimeMS()
        end

        mq.delay(100)
        mq.doevents()
        Events.DoEvents()
    end

    Logger.log_debug("\atMemorizeSpell\aw():\aw Finished waiting for '\at%s\aw' to load in slot \am%d\aw. Time taken: \ay%d\aws, maxWait(\ao%d\aws)",
        spell, gem, (Globals.GetTimeMS() - startMem) / 1000, maxWait / 1000)

    Casting.Memorizing = false

    local loaded = me.Gem(gem)() == mq.TLO.Spell(spell).Name()
    if not loaded and not interrupted and not permanent then
        Logger.log_error("\atMemorizeSpell\aw():\ar Timed out memming '%s' in slot %d with no interrupt detected - the spell bar may be incomplete.", spell, gem)
    end
    return loaded, permanent
end

--- Returns true if the player owns the AA (not nil), meets the minimum level requirement (or is on the Might server), and has at least rank 1 purchased. All three gates must pass.
--- @param aaName string The name of the AA ability to check.
--- @return boolean Returns true if the AA ability can be used, false otherwise.
function Casting.CanUseAA(aaName)
    local haveAbility = mq.TLO.Me.AltAbility(aaName)() ~= nil
    local levelCheck = haveAbility and (Core.OnMight() or mq.TLO.Me.AltAbility(aaName).MinLevel() <= mq.TLO.Me.Level())
    local rankCheck = haveAbility and mq.TLO.Me.AltAbility(aaName).Rank() > 0
    Logger.log_super_verbose("CanUseAA(%s): haveAbility(%s) levelCheck(%s) rankCheck(%s)", aaName, Strings.BoolToColorString(haveAbility),
        Strings.BoolToColorString(levelCheck), Strings.BoolToColorString(rankCheck))
    return haveAbility and levelCheck and rankCheck
end

--- Returns the purchased rank of an AA (via Me.AltAbility.Rank) if CanUseAA passes all ownership/level/rank checks, or 0 if the AA is unavailable or not yet purchased.
--- @param aaName string The name of the AA ability.
--- @return number The rank of the specified AA ability.
function Casting.AARank(aaName)
    return Casting.CanUseAA(aaName) and mq.TLO.Me.AltAbility(aaName).Rank() or 0
end

--- Returns the MQSpell for an AA's activated effect without going
--- through CanUseAA. Use when spell data is needed without the
--- ownership/level/rank gate.
---@param aaName string The AA name to look up.
---@return MQSpell The MQSpell object for the AA's activated spell effect.
function Casting.GetAASpell(aaName)
    return mq.TLO.Me.AltAbility(aaName).Spell
end

--- Returns true if the spell is a self-targeted skill with a positive duration that does not stack with other discs — indicating it occupies the active disc window rather than the buff window.
--- @param name string The name to check.
--- @return boolean True if the name is a discipline, false otherwise.
function Casting.IsActiveDisc(name)
    local spell = mq.TLO.Spell(name)

    return (spell() and spell.IsSkill() and spell.Duration.TotalSeconds() > 0 and not spell.StacksWithDiscs() and spell.TargetType():lower() == "self") and
        true or false
end

--- Checks whether the disc window is idle (Me.ActiveDisc has no ID).
---@return boolean True when no discipline is currently active.
function Casting.NoDiscActive()
    return not mq.TLO.Me.ActiveDisc.ID()
end

--- Resolves the action map entry to a disc via GetResolvedActionMapItem
--- and returns true if it is unavailable or CombatAbilityReady is false.
---@param actionMapName string The action map entry name to resolve.
---@return boolean True if the disc is on cooldown or unavailable.
function Casting.DiscOnCoolDown(actionMapName)
    local disc = Core.GetResolvedActionMapItem(actionMapName)
    return not (disc and mq.TLO.Me.CombatAbilityReady(disc.RankName())())
end

--- Exact-name FindItem lookup; returns true if the item exists and
--- has a Clicky effect.
---@param itemName string The exact item name to look up.
---@return boolean True if the item exists and has a clicky effect.
function Casting.ItemHasClicky(itemName)
    local item = mq.TLO.FindItem(string.format("=%s", itemName or "None"))
    if not (item and item()) then return false end

    return item.Clicky() ~= nil
end

--- Exact-name FindItem lookup; returns the MQSpell of the item's
--- Clicky effect, or nil if not found or no clicky is present.
---@param itemName string The exact item name to look up.
---@return MQSpell|nil
function Casting.GetClickySpell(itemName)
    local item = mq.TLO.FindItem(string.format("=%s", itemName or "None"))
    if not (item and item()) then return nil end

    return item.Clicky and item.Clicky.Spell
end

--- Scans the spell's effect list for SPA 32 (SPA_CREATE_ITEM) and returns the Base value of the first matching effect, which is the item ID that the spell summons. Returns 0 if the spell is nil or no create-item effect is found.
--- @param spell MQSpell The name or identifier of the spell.
--- @return number The ID of the summoned item.
function Casting.GetSummonedItemIDFromSpell(spell)
    if not spell or not spell() then return 0 end

    for i = 1, spell.NumEffects() do
        -- 32 means SPA_CREATE_ITEM
        if spell.Attrib(i)() == 32 then
            return tonumber(spell.Base(i)()) or 0
        end
    end

    return 0
end

---Returns true if mana percent is at or above the ManaToNuke threshold, or if burn is active (BurnCheck) and bRestrictBurns is not set — allowing nukes to continue during burn regardless of mana.
--- @param bRestrictBurns boolean|nil True if this function should ignore burn status, false otherwise.
--- @return boolean True if you have more mana than Mana To Nuke or are burning, false otherwise
function Casting.HaveManaToNuke(bRestrictBurns)
    return mq.TLO.Me.PctMana() >= Config:GetSetting('ManaToNuke') or (not bRestrictBurns and Casting.BurnCheck())
end

---Returns true if mana percent is at or above the ManaToDot threshold, or if burn is active (BurnCheck) and bRestrictBurns is not set — allowing DoTs to be applied during burn regardless of mana.
--- @param bRestrictBurns boolean|nil True if this function should ignore burn status, false otherwise.
--- @return boolean True if you have more mana than Mana To Dot or are burning, false otherwise
function Casting.HaveManaToDot(bRestrictBurns)
    return mq.TLO.Me.PctMana() >= Config:GetSetting('ManaToDot') or (not bRestrictBurns and Casting.BurnCheck())
end

---Returns true if mana percent is at or above the ManaToDebuff threshold, or if burn is active (BurnCheck) and bRestrictBurns is not set — allowing debuffs to be applied during burn regardless of mana.
--- @param bRestrictBurns boolean|nil True if this function should ignore burn status, false otherwise.
--- @return boolean True if you have more mana than Mana To Debuff or are burning, false otherwise
function Casting.HaveManaToDebuff(bRestrictBurns)
    return mq.TLO.Me.PctMana() >= Config:GetSetting('ManaToDebuff') or (not bRestrictBurns and Casting.BurnCheck())
end

---- "DetXChecks"s are helper functions that wrap debuff spells and checks in an easy-to-understand system for simpler class configs

--- Resolves spell rank, then delegates to TargetBuffCheck to confirm
--- the det effect is not already on the target. No HP check — use
--- DotSpellCheck for DoTs.
---@param spell MQSpell The detrimental spell to check.
---@param target MQSpawn? Defaults to auto-target or current target.
---@return boolean True if the det effect is not already present.
function Casting.DetSpellCheck(spell, target)
    if not (spell and spell()) then return false end
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end
    return Casting.TargetBuffCheck(Casting.GetUseableSpellId(spell), target)
end

--- Gates on CanUseAA, then delegates to TargetBuffCheck using the
--- AA's spell ID to confirm the det effect is not already on target.
---@param aaName string The AA name to check.
---@param target MQSpawn? Defaults to auto-target or current target.
---@return boolean True if the AA det effect is not already present.
function Casting.DetAACheck(aaName, target)
    if not Casting.CanUseAA(aaName) then return false end
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end

    return Casting.TargetBuffCheck(mq.TLO.Me.AltAbility(aaName).Spell.ID(), target)
end

--- Gets the clicky spell via GetClickySpell, then delegates to
--- TargetBuffCheck to confirm the det effect is not already on target.
---@param itemName string The item name whose clicky to check.
---@param target MQSpawn? Defaults to auto-target or current target.
---@return boolean True if the item's clicky det effect is not present.
function Casting.DetItemCheck(itemName, target)
    local clickySpell = Casting.GetClickySpell(itemName)
    if not (clickySpell and clickySpell()) then return false end
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end

    return Casting.TargetBuffCheck(clickySpell.ID(), target)
end

--- Returns false early if target HP is low (MobHasLowHP). Otherwise
--- resolves spell rank and delegates to TargetBuffCheck with
--- target-change and duplicate-from-self checks enabled.
---@param spell MQSpell The DoT spell to check.
---@param target MQSpawn? Defaults to auto-target or current target.
---@return boolean True if the DoT should be applied to the target.
function Casting.DotSpellCheck(spell, target)
    if not (spell and spell()) then return false end
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end

    if Targeting.MobHasLowHP(target) then return false end

    return Casting.TargetBuffCheck(Casting.GetUseableSpellId(spell), target, true, true)
end

--- Returns false early if target HP is low. Gets clicky spell via
--- GetClickySpell, then delegates to TargetBuffCheck with
--- target-change and duplicate-from-self checks enabled.
---@param itemName string The item name whose clicky DoT to check.
---@param target MQSpawn? Defaults to auto-target or current target.
---@return boolean True if the item's clicky DoT should be applied.
function Casting.DotItemCheck(itemName, target)
    local clickySpell = Casting.GetClickySpell(itemName)
    if not (clickySpell and clickySpell()) then return false end
    if not target then target = Targeting.GetAutoTarget() or mq.TLO.Target end

    if Targeting.MobHasLowHP(target) then return false end

    return Casting.TargetBuffCheck(clickySpell.ID(), target, true, true)
end

--- Verifies the player is not silenced, has the spell in their spellbook, and the gem timer has cleared (unless skipGemTimer is true — used to allow memorization mid-cooldown), then runs CastCheck for mana/endurance/movement/control conditions.
--- @param spell MQSpell The name of the spell to check.
--- @param skipGemTimer boolean? Whether to skip the gem timer check.
--- @return boolean Returns true if the spell is ready, false otherwise.
function Casting.SpellReady(spell, skipGemTimer)
    if not spell or not spell() then return false end

    local rankSpell = spell.RankName
    local ready = mq.TLO.Me.SpellReady(rankSpell.Name())()
    local bookCheck = (mq.TLO.Me.Book(rankSpell.Name())() or 0) > 0
    local silenced = mq.TLO.Me.Silenced() ~= nil

    Logger.log_verbose("SpellReady for %s(%d): Silenced (%s), BookCheck(%s), ReadyCheck(%s), Memorization Allowed (%s).", rankSpell.Name(), rankSpell.ID(),
        Strings.BoolToColorString(silenced), Strings.BoolToColorString(bookCheck), Strings.BoolToColorString(ready), Strings.BoolToColorString(skipGemTimer or false))

    if silenced or not bookCheck or (not ready and not skipGemTimer) then return false end

    return Casting.CastCheck(rankSpell)
end

--- Checks if a given song is ready to be sung: verifies the player is not silenced, has the song in their spellbook, and that the gem timer has expired (unless skipGemTimer is true), then runs CastCheck for mana/endurance/control/movement conditions.
--- @param songSpell MQSpell The name of the song spell to check.
--- @param skipGemTimer boolean? Whether to skip the gem timer check.
--- @return boolean Returns true if the song is ready, false otherwise.
function Casting.SongReady(songSpell, skipGemTimer)
    if not songSpell or not songSpell() then return false end

    local rankSong = songSpell.RankName
    local ready = mq.TLO.Me.SpellReady(rankSong.Name())()
    local bookCheck = mq.TLO.Me.Book(rankSong.Name())() ~= nil
    local silenced = mq.TLO.Me.Silenced() ~= nil

    Logger.log_verbose("SongReady for %s(%d): Silenced (%s), BookCheck(%s), ReadyCheck(%s), Memorization Allowed (%s).", rankSong.Name(), rankSong.ID(),
        Strings.BoolToColorString(silenced), Strings.BoolToColorString(bookCheck), Strings.BoolToColorString(ready), Strings.BoolToColorString(skipGemTimer or false))

    if silenced or not bookCheck or (not ready and not skipGemTimer) then return false end

    return Casting.CastCheck(rankSong)
end

--- True if the spell's gem is off its own recast timer (it may still be briefly blocked by the global cooldown).
---@param spell MQSpell
---@return boolean
function Casting.GemReady(spell)
    return (mq.TLO.Me.GemTimer(spell.RankName() or "")() or -1) == 0
end

--- A bard may fire an instant action while a song's cast window is open.
---@param castTimeMs number?
---@return boolean
function Casting.CanActMidSong(castTimeMs)
    return Core.MyClassIs("BRD") and (castTimeMs or -1) == 0
end

---@param castTimeMs number?
---@return boolean
function Casting.MoveBlocksCast(castTimeMs)
    if Core.MyClassIs("brd") then return false end
    return mq.TLO.Me.Moving() and (castTimeMs or -1) > 0
end

--- Checks CombatAbilityReady for the disc's ranked name, then runs CastCheck allowing movement and, for bards with an instant-cast disc (0 cast time), allowing an open casting window.
--- @param discSpell MQSpell The name of the discipline spell to check.
--- @return boolean Returns true if the discipline is ready, false otherwise.
function Casting.DiscReady(discSpell)
    if not discSpell or not discSpell() then return false end

    local rankDisc = discSpell.RankName
    local ready = mq.TLO.Me.CombatAbilityReady(rankDisc.Name())()

    Logger.log_verbose("DiscReady for %s(%d): Ready(%s)", rankDisc.Name(), rankDisc.ID(), Strings.BoolToColorString(ready))

    if not ready then return false end

    return Casting.CastCheck(rankDisc, true)
end

--- Verifies AltAbilityReady is true for the named AA and then runs CastCheck against the AA's associated spell to confirm mana/endurance/movement/control conditions are met.
--- @param aaName string The name of the AA ability to check.
--- @return boolean Returns true if the AA ability is ready, false otherwise.
function Casting.AAReady(aaName)
    local me = mq.TLO.Me
    if not me.AltAbility(aaName)() then return false end

    local ready = me.AltAbilityReady(aaName)()
    local aaSpell = me.AltAbility(aaName).Spell

    Logger.log_verbose("AAReady for AA %s (aaSpell: %s, %d): Ready(%s).", aaName, (aaSpell.Name() or "None"), (aaSpell.ID() or 0), Strings.BoolToColorString(ready))

    if not ready then return false end

    return Casting.CastCheck(aaSpell)
end

--- Verifies Me.AbilityReady is true for the named combat ability, then confirms the target is within maximum melee range.
--- @param abilityName string The name of the ability to check.
--- @param target MQSpawn|nil The intended target of the ability.
--- @return boolean True if the ability is ready, false otherwise.
function Casting.AbilityReady(abilityName, target)
    if not target then target = mq.TLO.Target end
    if not target or not target() then return false end

    local ready = mq.TLO.Me.AbilityReady(abilityName)()

    Logger.log_verbose("AbilityReady for  %s: Ready(%s)", abilityName, Strings.BoolToColorString(ready))

    if not ready then return false end

    return Targeting.GetTargetDistance(target) <= Targeting.GetTargetMaxRangeTo(target)
end

--- Checks ItemHasClicky, Me.ItemReady (off cooldown), required level,
--- movement (exempt for bards or 0-cast-time clickies), and control
--- state (stunned/feared/charmed/mezzed).
---@param itemName string The item name to check.
---@return boolean True if the item's clicky is ready to use.
function Casting.ItemReady(itemName)
    if not Casting.ItemHasClicky(itemName) then return false end
    local me = mq.TLO.Me
    if not me.ItemReady(itemName)() then
        Logger.log_verbose("ItemReady for %s: Item appears to be on cooldown! Aborting.", itemName)
        return false
    end

    local clicky = mq.TLO.FindItem("=" .. itemName).Clicky
    local levelCheck = me.Level() >= (clicky.RequiredLevel() or 0)
    local movingCheck = not Casting.MoveBlocksCast(clicky.CastTime())
    local controlCheck = not (me.Stunned() or me.Feared() or me.Charmed() or me.Mezzed())

    Logger.log_verbose("ItemReady for %s: LevelCheck(%s) MovingCheck(%s) ControlCheck(%s)", itemName, Strings.BoolToColorString(levelCheck),
        Strings.BoolToColorString(movingCheck), Strings.BoolToColorString(controlCheck))

    return levelCheck and movingCheck and controlCheck
end

--- Shared pre-cast gate used by SpellReady, SongReady, DiscReady,
--- and AAReady. Checks casting window, movement, mana/endurance
--- (adjusted for med regen ticks), and control state.
---@param spell MQSpell The spell whose cost and cast time to evaluate.
---@param bAllowMove boolean? Skip the movement check if true.
---@return boolean True if all pre-cast conditions are met.
function Casting.CastCheck(spell, bAllowMove)
    if not spell or not spell() then return false end

    local me = mq.TLO.Me
    local castingCheck = Casting.CanActMidSong(spell.MyCastTime()) or (not (me.Casting() or mq.TLO.Window("CastingWindow").Open()))
    local movingCheck = bAllowMove or not Casting.MoveBlocksCast(spell.MyCastTime())

    local currentMana = me.CurrentMana()
    local currentEnd = me.CurrentEndurance()
    if Globals.InMedState then --ensure false mana/end ticks don't make us stand early if we are medding by removing 2 ticks of resting for cost checks.
        currentMana = math.max(0, me.CurrentMana() - (2 * me.ManaRegen()))
        currentEnd = math.max(0, me.CurrentEndurance() - (2 * me.EnduranceRegen()))
    end
    local manaCheck = spell.Mana() == 0 or currentMana >= spell.Mana()
    local endCheck = spell.EnduranceCost() == 0 or currentEnd >= spell.EnduranceCost()

    local controlCheck = not (me.Stunned() or me.Feared() or me.Charmed() or me.Mezzed())

    Logger.log_verbose("CastCheck for %s (%d): CastingCheck(%s), MovingCheck(%s), ManaCheck(%s), EndCheck(%s), ControlCheck(%s)", spell.Name(), spell.ID(),
        Strings.BoolToColorString(castingCheck), Strings.BoolToColorString(movingCheck), Strings.BoolToColorString(manaCheck), Strings.BoolToColorString(endCheck),
        Strings.BoolToColorString(controlCheck))

    return castingCheck and movingCheck and manaCheck and endCheck and controlCheck
end

--- Type-dispatched cast shared by the entry-list engines (mez/charm/rez/cure) and the queued-ability processor; returns the underlying cast's success.
--- @param entryType string One of "aa"|"item"|"song"|"disc"|"ability"|"spell"; anything unrecognized is treated as a spell.
--- @param name string The resolved name to cast (an AA/item name, or a spell/song RankName); unused for disc, which casts opts.spell.
--- @param targetId? number The target spawn ID.
--- @param opts? table Optional flags: { allowMem = boolean, allowDead = boolean, spell = MQSpell (the disc's spell object) }.
--- @return boolean success
function Casting.UseEntry(entryType, name, targetId, opts)
    opts = opts or {}
    entryType = (entryType or ""):lower()
    if entryType == "aa" then return Casting.UseAA(name, targetId, opts.allowDead) end
    if entryType == "item" then return Casting.UseItem(name, targetId, opts.allowDead) end
    if entryType == "song" then return Casting.UseSong(name, targetId, opts.allowMem) end
    if entryType == "disc" then return Casting.UseDisc(opts.spell, targetId) end
    if entryType == "ability" then return Casting.UseAbility(name, targetId) end
    return Casting.UseSpell(name, targetId, opts.allowMem, opts.allowDead)
end

--- Casts a spell on a target. Bards are routed to UseSong.
--- @param spellName string The name of the spell to be used.
--- @param targetId? number The ID of the target on which the spell will be cast.
--- @param bAllowMem boolean Whether to allow the spell to be memorized if not already.
--- @param bAllowDead boolean? Whether to allow casting the spell on a dead target.
--- @param retryCount number? The number of times to retry casting the spell if it fails.
--- @return boolean success Returns true if the spell was successfully cast, false otherwise.
--- @return boolean|nil isGroup Returns true if the spell is a group-affecting target type.
function Casting.UseSpell(spellName, targetId, bAllowMem, bAllowDead, retryCount)
    local me = mq.TLO.Me
    if not targetId then targetId = mq.TLO.Target.ID() end
    -- Immediately send bards to the song handler.
    if me.Class.ShortName():lower() == "brd" then
        return Casting.UseSong(spellName, targetId, bAllowMem, retryCount)
    end

    local spell = mq.TLO.Spell(spellName)
    if not spell() then
        Logger.log_error("\ayUseSpell(): \arCasting Failed: Somehow I tried to cast a spell That doesn't exist: %s",
            spellName)
        return false
    end
    -- Check we actually have the spell -- Me.Book always needs to use RankName
    if not me.Book(spellName)() then
        Logger.log_error("\ayUseSpell(): \arCasting Failed: Somehow I tried to cast a spell I didn't know: %s", spellName)
        return false
    end

    if Casting.MoveBlocksCast(spell.MyCastTime()) then
        Logger.log_debug("\ayUseSpell(): \arCan't cast %s - I am moving", spellName)
        return false
    end

    if mq.TLO.Cursor.ID() then
        Core.DoCmd("/autoinv")
    end

    local selfTargeted = Casting.IsSelfSpell(spell.TargetType())
    local spellTargetId = selfTargeted and me.ID() or targetId
    local targetSpawn = mq.TLO.Spawn(spellTargetId)

    if not Casting.LevelCheckPass(spell, targetSpawn) then
        Logger.log_debug("\ayUseSpell(): \arCasting %s failed level check with target=%d and spell=%d", spellName,
            targetSpawn.Level() or 0, spell.Level() or 999)
        return false
    end

    if not Casting.ReagentCheck(spell) then
        Logger.log_debug("\ayUseSpell(): \arCasting Failed: I tried to cast a spell %s I don't have Reagents for.",
            spellName)
        return false
    end

    if me.CurrentMana() < spell.Mana() then
        Logger.log_verbose("\ayUseSpell(): \arCasting Failed: I tried to cast a spell %s I don't have mana for it.",
            spellName)
        return false
    end

    if targetId == 0 then
        Logger.log_debug("\ayUseSpell(): \arCasting Failed: I tried to cast a spell %s I don't have a target (%d) for it.",
            spellName, targetId)
        return false
    end
    -- TEMP 6/26: FeetWet swim-state check disabled - a flyer flying above a pool (e.g. Hartini in Stillmoon) reports FeetWet but its feet aren't actually wet, blocking all casts. Not a verified EQ mechanic.
    -- if targetSpawn() and targetSpawn.FeetWet() ~= me.FeetWet() then return false end

    if not bAllowDead and targetSpawn() and targetSpawn.Dead() then
        Logger.log_verbose("\ayUseSpell(): \arCasting Failed: I tried to cast a spell %s but my target (%d) is dead.",
            spellName, targetId)
        return false
    end

    local spellRange = Casting.GetSpellRange(spell)
    if spellTargetId ~= me.ID() and targetSpawn() and Targeting.GetTargetDistance(targetSpawn) > spellRange then
        Logger.log_debug("\ayUseSpell(): \arTried to cast %s on %s but they are too far away", spellName, targetSpawn.DisplayName() or "None")
        return false
    end

    if (Targeting.GetXTHaterCount() > 0 or not bAllowMem) and (not Casting.CastReady(spell) or not me.Gem(spellName)()) then
        Logger.log_debug("\ayUseSpell(): \ayI tried to cast %s but it was not ready and we are in combat - moving on.",
            spellName)
        return false
    end

    local spellRequiredMem = false
    if not me.Gem(spellName)() then
        Logger.log_debug("\ayUseSpell(): \ay%s is not memorized - meming!", spellName)
        Casting.MemorizeSpell(Casting.UseGem, spellName, true, 25000)
        spellRequiredMem = true
    end

    if not me.Gem(spellName)() then
        Logger.log_debug("\ayUseSpell(): \arFailed to memorize %s - moving on...", spellName)
        return false
    end

    local readyTimeout = 5000
    if spellRequiredMem then
        readyTimeout = (spell.RecastTime() or 0) + 5000
    end
    Casting.WaitCastReady(spellName, readyTimeout)

    Casting.WaitGlobalCoolDown()

    Casting.ActionPrep()

    local oldTargetId = mq.TLO.Target.ID()
    if not selfTargeted and targetId > 0 and targetId ~= oldTargetId then
        if Config:GetSetting('StopAttackForPCs') and me.Combat() and (targetSpawn.Type() or ""):lower() == "pc" then -- don't use helper here, don't want fallback to current target
            Logger.log_debug("\awUseSpell():NOTICE:\ax Turning off autoattack to cast on a PC.")
            Core.DoCmd("/attack off")
            mq.delay("2s", function() return not me.Combat() end)
        end

        Logger.log_debug("\awUseSpell():NOTICE:\ax Swapping target to %s [%d] to use %s", targetSpawn.DisplayName(), targetId, spellName)
        Targeting.SetTarget(targetId, true)
    end

    local cmd = string.format("/cast \"=%s\"", spellName)
    local castTime = spell.MyCastTime() or 0
    local readyCheck = function() return me.SpellReady(spellName)() end
    -- Expose this if needed for EZServer if they have instant CD spells with 0 gcd
    local noRecast = false

    Casting.RunCastLoop({
        cmd = cmd,
        readyCheck = readyCheck,
        actionName = spellName,
        targetId = spellTargetId,
        bAllowDead = bAllowDead or false,
        spellRange = spellRange,
        castTime = castTime,
        retryCount = retryCount,
    })
    if Globals.StopCast then return false end

    Globals.LastUsedSpell = spellName
    if mq.TLO.Target.ID() ~= oldTargetId and Combat.ValidCombatTarget(oldTargetId) and (oldTargetId == Globals.AutoTargetID or not Config:GetSetting('DoAutoTarget')) then
        Logger.log_debug("UseSpell(): Retargeting previous target after spell use.")
        Targeting.SetTarget(oldTargetId, true)
    end
    return Casting.CastSucceeded(readyCheck, noRecast), Casting.IsGroupSpell(spell.TargetType())
end

--- Plays a bard song on a target.
--- @param songName string The name of the song to be used.
--- @param targetId? number The ID of the target on which the song will be used.
--- @param bAllowMem boolean A flag indicating whether memorization is allowed.
--- @param retryCount number? The number of times to retry using the song if it fails.
--- @return boolean True if we were able to sing the song, false otherwise
function Casting.UseSong(songName, targetId, bAllowMem, retryCount)
    local me = mq.TLO.Me
    if not targetId then targetId = mq.TLO.Target.ID() end

    local songSpell = mq.TLO.Spell(songName)

    if not songSpell() then
        Logger.log_error("\ayUseSong(): \arSinging Failed: tried to sing a song that doesn't exist: %s",
            songName)
        return false
    end

    -- Check we actually have the song -- Me.Book always needs to use RankName
    if not me.Book(songName)() then
        Logger.log_error("\ayUseSong(): \arSinging Failed: tried to sing a song I didn't know: %s", songName)
        return false
    end

    if me.CurrentMana() < songSpell.Mana() then
        Logger.log_debug("\ayUseSong(): \arSinging Failed: I tried to sing %s but I don't have mana for it.",
            songName)
        return false
    end

    if mq.TLO.Cursor.ID() then
        Core.DoCmd("/autoinv")
    end

    local selfTargeted = Casting.IsSelfSpell(songSpell.TargetType())
    local spellTargetId = selfTargeted and me.ID() or targetId
    local targetSpawn = mq.TLO.Spawn(spellTargetId)

    local spellRange = Casting.GetSpellRange(songSpell)
    if spellTargetId ~= me.ID() and targetSpawn() and Targeting.GetTargetDistance(targetSpawn) > spellRange then
        Logger.log_debug("\ayUseSong(): \arTried to cast %s on %s but they are too far away", songName, targetSpawn.DisplayName() or "None")
        return false
    end

    if (Targeting.GetXTHaterCount() > 0 or not bAllowMem) and (not Casting.CastReady(songSpell) or not me.Gem(songName)()) then
        Logger.log_debug("\ayUseSong(): I tried to sing %s but it was not ready and we are in combat - moving on.",
            songName)
        return false
    end

    local spellRequiredMem = false
    if not me.Gem(songName)() then
        Logger.log_debug("\ayUseSong(): %s is not memorized - meming!", songName)
        Casting.MemorizeSpell(Casting.UseGem, songName, true, 5000)
        spellRequiredMem = true
    end

    if not me.Gem(songName)() then
        Logger.log_debug("\ayUseSong(): \arFailed to memorize %s - moving on...", songName)
        return false
    end

    local readyTimeout = 5000
    if spellRequiredMem then
        readyTimeout = (songSpell.RecastTime() or 0) + 5000
    end
    Casting.WaitCastReady(songName, readyTimeout)

    Casting.ActionPrep()

    local oldTargetId = mq.TLO.Target.ID()
    if not selfTargeted and targetId > 0 and targetId ~= oldTargetId and targetId ~= me.ID() then
        if Config:GetSetting('StopAttackForPCs') and me.Combat() and (targetSpawn.Type() or ""):lower() == "pc" then -- don't use helper here, don't want fallback to current target
            Logger.log_debug("\awUseSong():NOTICE:\ax Turning off autoattack to cast on a PC.")
            Core.DoCmd("/attack off")
            mq.delay("2s", function() return not me.Combat() end)
        end

        Logger.log_debug("\awUseSong():NOTICE:\ax Swapping target to %s [%d] to use %s", targetSpawn.DisplayName(), targetId, songName)
        Targeting.SetTarget(targetId, true)
    end

    Logger.log_verbose("\ayUseSong(): casting %s on %s", songName, targetSpawn.CleanName() or "None")

    Core.SafeCallClassHelper("SwapInst", "SwapInst", songSpell.Skill())

    retryCount = retryCount or Config:GetSetting('CastRetryCount')

    local cancel = false
    local castStarted = false
    local songCastTime = songSpell.MyCastTime() or 0
    local readyCheck = function() return me.SpellReady(songName)() end

    repeat
        Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_RESULT_NONE)
        Core.DoCmd("/cast \"=%s\"", songName)

        mq.delay("3s", function() return mq.TLO.Window("CastingWindow").Open() end)
        -- Cast window opening is our cross-platform "song started" signal (EMU has no "you begin singing" event).
        castStarted = mq.TLO.Window("CastingWindow").Open()

        -- If we /stopsong too soon after a cast, the server will re-open the cast window.
        -- -- This can be observed with the following: /multiline ; /cast 2 ; /timed 1 /stopsong
        -- -- Wait for the first half-second before allowing a stopsong command from the below conditions
        local cancelWait = 500
        local scanTimer = 0

        -- while the casting window is open, still do movement if not paused or if movement enabled during pause.
        while mq.TLO.Window("CastingWindow").Open() do
            if not Globals.PauseMain or Config:GetSetting('RunMovePaused') then
                Modules:ExecModule("Movement", "GiveTime")
            end

            if cancelWait <= 0 then
                if (not targetSpawn or not targetSpawn() or Targeting.TargetIsType("corpse", targetSpawn)) and songSpell.SpellType() == "Detrimental" then
                    Logger.log_debug("\ayUseSong(): Canceled singing %s because target is dead or no longer exists.", songName)
                    cancel = true
                elseif targetSpawn() and Targeting.GetTargetDistance(targetSpawn) > (spellRange * 1.1) then --allow for slight movement in and out of range, if the target runs off, this is still easily triggered
                    Logger.log_debug("\ayUseSong(): Canceled singing %s because spellTarget(%d, range %d) is out of spell range(%d)", songName, targetSpawn.ID(),
                        Targeting.GetTargetDistance(targetSpawn), spellRange)
                    cancel = true
                elseif Globals.StopCast then
                    Logger.log_debug("\ayUseSong(): Canceled singing %s because of stopcast command.", songName)
                    cancel = true
                end
                if cancel then
                    Core.DoCmd("/stopsong")
                    break
                end
            end

            -- track to avoid stuck gem bug by not using actions close to song finish
            local nearCastEnd = songCastTime > 0 and (songCastTime - scanTimer) <= 500

            if scanTimer % 500 == 0 then
                Casting.RescanCombatTargets()
                Modules:ExecModule("Class", "DoMidSongEngage", targetId)
            end

            if scanTimer % 100 == 0 and not nearCastEnd then
                Modules:ExecModule("Class", "DoMidSongActions")
            end

            mq.delay(20)
            mq.doevents()
            Events.DoEvents()
            cancelWait = cancelWait - 20
            scanTimer = scanTimer + 20
        end

        retryCount = retryCount - 1
    until cancel or (castStarted and not Globals.Constants.CastRetriable:contains(Casting.GetLastCastResultName())) or retryCount < 0

    -- if we interrupted ourselves earlier, we don't need to do this
    if me.Casting() then
        -- bard songs take a bit to refresh after casting window closes, otherwise we'll clip our song
        local clipDelay = mq.TLO.EverQuest.Ping() * Config:GetSetting('SongClipDelayFact')

        -- for performance, lets check for the buffs on buffsongs and exit this delay early if possible.
        -- -- If it lands on me but doesn't have a buff (or doesn't have a properly detected buff), we are no worse off than the static delay.
        if spellTargetId == me.ID() or Casting.IsGroupSpell(songSpell.TargetType()) then
            -- For expediency, just check for the base rank in case they are f2p without unlockers and rk2 spells scribed. If we need the exact spell later, GetUseableSpellId will check their unlocker status and get the correct ID
            local buffName = songSpell.BaseName()
            local durWindow = songSpell.DurationWindow()
            local minDuration = songSpell.MyDuration.TotalSeconds() -
                4 -- this doesn't factor in Quick Time, but as long as you aren't only singing one-two songs this shouldn't matter.

            while clipDelay > 0 do
                -- check for the buff in the correct window (want to cache this but can't)
                local spellBuff = durWindow == 1 and me.Song(buffName) or me.Buff(buffName)
                --ensure we aren't catching the old song if we are resinging. Ensure the song is at least 4 seconds older than max duration, meaning it has to be new.
                -- -- This number was tested and is not arbitrary, due to sever communication/etc in testing setting this any lower occasionally caused songs to be clipped from detecting an old buff
                if spellBuff and spellBuff() and spellBuff.Duration.TotalSeconds() >= minDuration then
                    Logger.log_verbose("\ayUseSong(): New buff detected, bypassing remaining clip delay of %d ms.", clipDelay)
                    break
                end
                mq.delay(10)
                mq.doevents()
                clipDelay = clipDelay - 10
            end
        else
            -- Algarnote 2/3/26: for insults, mezzes, etc, lets just use a static delay. I'm not sure whats possible and feel like it would add 800 more lines of code. I'll keep thinking about it.
            -- -- In my testing, buffs were generally detected in half to 3/4 of my ping, (Delay 170, buffs detected on average 100-120ms remaining on clip), so we might be able to squeak a tiny bit more performance at a later date
            mq.delay(clipDelay)
        end
        Core.DoCmd("/stopsong")
    end

    Core.SafeCallClassHelper("SwapInst", "SwapInst", "Weapon")

    if cancel then return false end -- don't try to retarget if we broke out above, but we still needed to swap equipment back.

    if mq.TLO.Target.ID() ~= oldTargetId and Combat.ValidCombatTarget(oldTargetId) and (oldTargetId == Globals.AutoTargetID or not Config:GetSetting('DoAutoTarget')) then
        Logger.log_debug("\ayUseSong(): Retargeting previous target after song use.")
        Targeting.SetTarget(oldTargetId, true)
    end

    return castStarted and Casting.CastSucceeded(readyCheck, true)
end

--- Activates a discipline on a target.
--- @param discSpell MQSpell The name of the discipline spell to use.
--- @param targetId? number The ID of the target on which to use the discipline spell.
--- @return boolean success True if we were able to fire the Disc, false otherwise.
--- @return boolean|nil isGroup True if the disc is a group-affecting target type.
function Casting.UseDisc(discSpell, targetId, fireAndForget)
    local me = mq.TLO.Me
    if not targetId then targetId = mq.TLO.Target.ID() end

    if not discSpell or not discSpell() then return false end

    local rankDisc = discSpell.RankName
    local discName = rankDisc.Name()
    local castTime = rankDisc.MyCastTime() or 0
    local selfTargeted = Casting.IsSelfSpell(rankDisc.TargetType())
    local spellTargetId = selfTargeted and me.ID() or targetId

    if (mq.TLO.Window("CastingWindow").Open() or me.Casting()) and not Casting.CanActMidSong(castTime) then
        Logger.log_debug("\ayUseDisc(): \arCan't use %s - Casting Window Open", discName)
        return false
    end

    if me.CurrentEndurance() < rankDisc.EnduranceCost() then
        Logger.log_debug("\ayUseDisc(): \arCan't use %s - insufficient endurance", discName)
        return false
    end

    local spellRange = Casting.GetSpellRange(rankDisc)
    if spellTargetId ~= me.ID() then
        local targetSpawn = mq.TLO.Spawn(spellTargetId)
        if targetSpawn() and Targeting.GetTargetDistance(targetSpawn) > spellRange then
            Logger.log_debug("\ayUseDisc(): \arTried to cast %s on %s but they are too far away", discName, targetSpawn.DisplayName() or "None")
            return false
        end
    end

    Logger.log_debug("\ayUseDisc(): trying %s", discName)

    Casting.ActionPrep()

    if Casting.IsActiveDisc(discName) and me.ActiveDisc.ID() then
        Logger.log_debug("\ayUseDisc(): canceling %s; current active disc is [%s]", discName, me.ActiveDisc.Name())
        Core.DoCmd("/stopdisc")
        mq.delay(20, function() return me.ActiveDisc() == nil end)
    end

    local oldTargetId = mq.TLO.Target.ID()
    if not selfTargeted and targetId > 0 and targetId ~= oldTargetId then
        local targetSpawn = mq.TLO.Spawn(targetId)
        if Config:GetSetting('StopAttackForPCs') and me.Combat() and (targetSpawn.Type() or ""):lower() == "pc" then -- don't use helper here, don't want fallback to current target
            Logger.log_debug("\awUseDisc():NOTICE:\ax Turning off autoattack to cast on a PC.")
            Core.DoCmd("/attack off")
            mq.delay("2s", function() return not me.Combat() end)
        end

        Logger.log_debug("\awUseDisc():NOTICE:\ax Swapping target to %s [%d] to use %s", targetSpawn.DisplayName(), targetId, discName)
        Targeting.SetTarget(targetId, true)
    end

    local cmd = string.format("/squelch /doability \"%s\"", discName)
    local readyCheck = function() return me.CombatAbilityReady(discName)() end

    Casting.RunCastLoop({
        cmd = cmd,
        readyCheck = readyCheck,
        actionName = discName,
        targetId = spellTargetId,
        bAllowDead = true,
        spellRange = spellRange,
        castTime = castTime,
        retryCount = 0,
        fireAndForget = fireAndForget,
    })
    if Globals.StopCast then return false end

    if mq.TLO.Target.ID() ~= oldTargetId and Combat.ValidCombatTarget(oldTargetId) and (oldTargetId == Globals.AutoTargetID or not Config:GetSetting('DoAutoTarget')) then
        Logger.log_debug("UseDisc(): Retargeting previous target after disc use.")
        Targeting.SetTarget(oldTargetId, true)
    end

    return Casting.CastSucceeded(readyCheck, false), Casting.IsGroupSpell(rankDisc.TargetType())
end

function Casting.GetSpellRange(spell)
    if not spell or not spell() then return 250 end
    local myRange = spell.MyRange() or 0
    if myRange > 0 then return myRange end
    local aeRange = spell.AERange() or 0
    if aeRange > 0 then return aeRange end
    return 250
end

--- noRecast actions can't be verified via cooldown flip, so silence is treated as success.
function Casting.CastSucceeded(readyCheck, noRecast)
    if Globals.Constants.CastCompleted:contains(Casting.GetLastCastResultName()) then return true end
    if not readyCheck() then return true end
    if noRecast and Casting.GetLastCastResultId() == Globals.Constants.CastResults.CAST_RESULT_NONE then return true end
    return false
end

--- MA / tank aggro target refresh, if applicable. Caller controls cadence (typically every ~500ms).
function Casting.RescanCombatTargets()
    local notValidTarget = not Combat.ValidCombatTarget(Globals.AutoTargetID)
    local notForcedTarget = Globals.ForceTargetID > 0 and Globals.ForceTargetID ~= Globals.AutoTargetID
    if Core.IAmMA() and not Globals.BackOffFlag and (notValidTarget or notForcedTarget) then
        Combat.FindBestAutoTarget(Combat.OkToEngagePreValidateId)
        if Core.IsTanking() and Config:GetSetting('TankAggroScan') then
            Combat.TankAggroScan()
        end
    end
end

--- @param opts table Named options:
---   - cmd        (string)   The EQ command that triggers the action.
---   - readyCheck (function) () -> boolean: true while the action is still ready to fire.
---   - actionName (string)   Human-readable action name used in log lines.
---   - targetId   (number?)  The spawn ID of the target
---   - bAllowDead (boolean?) allow this action to continue if the target is found to be dead.
---   - spellRange (number?)  Effective spell range.
---   - castTime   (number?)  Reported cast time in ms (0 for instants).
---   - retryCount (number?)  Additional attempts allowed on retriable failures.
function Casting.RunCastLoop(opts)
    local cmd = opts.cmd
    local readyCheck = opts.readyCheck
    local actionName = opts.actionName
    local targetId = opts.targetId
    local bAllowDead = opts.bAllowDead
    local spellRange = opts.spellRange
    local castTime = opts.castTime or 0
    local retryCount = opts.retryCount or Config:GetSetting('CastRetryCount')

    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_RESULT_NONE)

    if castTime == 0 and not Casting.IsActiveDisc(actionName) and (opts.fireAndForget or mq.TLO.Window("CastingWindow").Open() or mq.TLO.Me.Casting()) then
        Core.DoCmd(cmd)
        Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_SUCCESS)
        return
    end

    -- give a small delay for when we need to rely on an action changing to "not ready" to detect success, this is data from the server. values tested on laz/might numerous times
    local floor = math.max(300, 3 * (mq.TLO.EverQuest.Ping() or 0))
    local delay = castTime < floor and floor or castTime

    repeat
        Logger.log_verbose("\ayRunCastLoop(): Attempting to cast: %s", actionName)
        -- Active discs hold for discs to become active; other instants only hold until they go on cooldown.
        local isActiveDisc = castTime == 0 and Casting.IsActiveDisc(actionName)
        local confirmOnDisc = isActiveDisc and not mq.TLO.Me.ActiveDisc.ID()
        Core.DoCmd(cmd)
        Logger.log_verbose("\ayRunCastLoop(): Waiting to start cast: %s (delay=%dms)", actionName, delay)
        mq.delay(delay, function()
            if castTime == 0 then mq.doevents('Success1') end -- check for cast message on items (it seems to be sent from the server, not client/instant like spells)
            if isActiveDisc then
                return confirmOnDisc and (mq.TLO.Me.ActiveDisc.ID() or 0) > 0
            elseif castTime == 0 and not readyCheck() then
                return true
            end
            return mq.TLO.Me.Casting() ~= nil
                or Globals.Constants.CastCompleted:contains(Casting.GetLastCastResultName())
        end)
        -- Active discs confirm via ActiveDisc.ID above and have no cast bar to wait on.
        if mq.TLO.Me.Casting() and not isActiveDisc then
            Logger.log_verbose("\ayRunCastLoop(): Started to cast: %s - waiting to finish", actionName)
            Casting.WaitCastFinish(targetId, bAllowDead, spellRange, castTime)
        end
        if Globals.StopCast then
            Logger.log_verbose("\atRunCastLoop(): Canceled casting %s due to stopcast command.", actionName)
            return
        end
        mq.doevents()
        Events.DoEvents()
        mq.delay(20)
        local resultName = Casting.GetLastCastResultName()
        Logger.log_verbose("\atRunCastLoop(): Finished waiting on cast: %s result = %s ready = %s retries left = %d", actionName, resultName, Strings.BoolToColorString(readyCheck()),
            retryCount)
        retryCount = retryCount - 1
        if not readyCheck() then break end
        if not Globals.Constants.CastRetriable:contains(resultName) then break end
    until retryCount < 0
end

--- Activates an AA ability on a target.
--- @param aaName string The name of the AA ability to use.
--- @param targetId? number The ID of the target on which to use the AA ability.
--- @param bAllowDead boolean? Whether to allow casting on a dead target.
--- @param retryCount number? The number of times to retry if the cast fails.
--- @return boolean success True if the AA ability was successfully used, false otherwise.
--- @return boolean|nil isGroup True if the AA is a group-affecting target type.
function Casting.UseAA(aaName, targetId, bAllowDead, retryCount, fireAndForget)
    local me = mq.TLO.Me
    if not targetId then targetId = mq.TLO.Target.ID() end

    local aaAbility = mq.TLO.Me.AltAbility(aaName)

    if not aaAbility() then
        Logger.log_debug("\ayUseAA(): You don't have the AA: %s!", aaName)
        return false
    end

    local aaSpell = aaAbility.Spell

    if not aaSpell() then
        Logger.log_debug("\ayUseAA(): You can't activate a passive AA: %s!", aaName)
        return false
    end

    if not mq.TLO.Me.AltAbilityReady(aaName)() then
        Logger.log_debug("\ayUseAA(): Ability %s is not ready!", aaName)
        return false
    end

    if (mq.TLO.Window("CastingWindow").Open() or me.Casting()) and not Casting.CanActMidSong(aaSpell.MyCastTime()) then
        Logger.log_debug("\ayUseAA(): \arCan't cast %s - Casting Window Open", aaName)
        return false
    end

    local selfTargeted = Casting.IsSelfSpell(aaSpell.TargetType())
    local spellTargetId = selfTargeted and me.ID() or targetId
    local targetSpawn = mq.TLO.Spawn(spellTargetId)

    -- TEMP 6/26: FeetWet swim-state check disabled - a flyer flying above a pool (e.g. Hartini in Stillmoon) reports FeetWet but its feet aren't actually wet, blocking all casts. Not a verified EQ mechanic.
    -- if targetSpawn() and targetSpawn.FeetWet() ~= me.FeetWet() then
    --     Logger.log_debug("\ayUseAA(): \arCan't cast %s on %d - swim state mismatch", aaName, targetId)
    --     return false
    -- end

    if not bAllowDead and targetSpawn() and targetSpawn.Dead() then
        Logger.log_debug("\ayUseAA(): \arAbility Failed!: I tried to use %s but my target (%d) is dead.",
            aaName, targetId)
        return false
    end

    if not Casting.LevelCheckPass(aaSpell, targetSpawn) then
        Logger.log_debug("\ayUseAA(): \arCasting %s(spell: %s) failed level check with target=%d and spell=%d", aaName, aaSpell.Name(),
            targetSpawn.Level() or 0, aaSpell.Level() or 999)
        return false
    end

    local spellRange = Casting.GetSpellRange(aaSpell)
    if spellTargetId ~= me.ID() and targetSpawn() and Targeting.GetTargetDistance(targetSpawn) > spellRange then
        Logger.log_debug("\ayUseAA(): \arTried to cast %s on %s but they are too far away", aaName, targetSpawn.DisplayName() or "None")
        return false
    end

    Casting.ActionPrep()

    local oldTargetId = mq.TLO.Target.ID()
    if not selfTargeted and targetId > 0 and targetId ~= oldTargetId then
        if Config:GetSetting('StopAttackForPCs') and me.Combat() and (targetSpawn.Type() or ""):lower() == "pc" then -- don't use helper here, don't want fallback to current target
            Logger.log_debug("\awUseAA():NOTICE:\ax Turning off autoattack to cast on a PC.")
            Core.DoCmd("/attack off")
            mq.delay("2s", function() return not me.Combat() end)
        end

        Logger.log_debug("\awUseAA():NOTICE:\ax Swapping target to %s [%d] to use %s", targetSpawn.DisplayName(), targetId, aaName)
        Targeting.SetTarget(targetId, true)
    end

    local cmd = string.format("/alt act %d", aaAbility.ID())
    local castTime = aaSpell.MyCastTime() or 0
    local noRecast = (aaAbility.MyReuseTime() or 0) == 0
    local readyCheck = function() return me.AltAbilityReady(aaName)() end

    Casting.RunCastLoop({
        cmd = cmd,
        readyCheck = readyCheck,
        actionName = aaName,
        targetId = spellTargetId,
        bAllowDead = bAllowDead or false,
        spellRange = spellRange,
        castTime = castTime,
        retryCount = retryCount,
        fireAndForget = fireAndForget,
    })
    if Globals.StopCast then return false end

    if mq.TLO.Target.ID() ~= oldTargetId and Combat.ValidCombatTarget(oldTargetId) and (oldTargetId == Globals.AutoTargetID or not Config:GetSetting('DoAutoTarget')) then
        Logger.log_debug("UseAA(): Retargeting previous target after AA use.")
        Targeting.SetTarget(oldTargetId, true)
    end

    return Casting.CastSucceeded(readyCheck, noRecast), Casting.IsGroupSpell(aaSpell.TargetType())
end

--- Fires a combat ability (e.g., Taunt, Kick) via /doability.
--- @param abilityName string The name of the ability to use.
--- @return boolean
function Casting.UseAbility(abilityName, targetId)
    local me = mq.TLO.Me

    local oldTargetId = mq.TLO.Target.ID()
    if (targetId or 0) > 0 and targetId ~= oldTargetId then
        Logger.log_debug("\awUseAbility():NOTICE:\ax Swapping target to %s [%d] to use %s", mq.TLO.Spawn(targetId).DisplayName() or "None", targetId, abilityName)
        Targeting.SetTarget(targetId, true)
    end

    Core.DoCmd("/doability %s", abilityName)
    mq.delay(50, function() return me.AbilityReady(abilityName) ~= true end)
    Logger.log_debug("Using Ability \ao =>> \ag %s \ao <<=", abilityName)

    if mq.TLO.Target.ID() ~= oldTargetId and Combat.ValidCombatTarget(oldTargetId) and (oldTargetId == Globals.AutoTargetID or not Config:GetSetting('DoAutoTarget')) then
        Logger.log_debug("UseAbility(): Retargeting previous target after ability use.")
        Targeting.SetTarget(oldTargetId, true)
    end

    return true
end

--- Uses a clicky item on a target.
--- @param itemName string The name of the item to be used.
--- @param targetId number|nil The ID of the target on which the item will be used. May be nil for untargeted items.
--- @param bAllowDead boolean? Whether to allow using the item on a dead target.
--- @param retryCount number? The number of times to retry if the use fails.
--- @return boolean success True if the item was successfully used, false otherwise.
--- @return boolean|nil isGroup True if the item's spell is a group-affecting target type.
function Casting.UseItem(itemName, targetId, bAllowDead, retryCount, fireAndForget)
    local me = mq.TLO.Me

    if not itemName then
        Logger.log_debug("\ayUseItem(): \arGiven item name is nil!")
        return false
    end

    local item = mq.TLO.FindItem("=" .. itemName)

    if not item() then
        Logger.log_debug("\ayUseItem(): \arTried to use %s - not found", itemName)
        return false
    end

    if not me.ItemReady(itemName)() then
        Logger.log_debug("\ayUseItem(): \arTried to use %s - not ready", itemName)
        return false
    end

    local castTime = (item.Clicky() and item.Clicky.CastTime()) or item.CastTime() or 0
    local itemSpell = item.Clicky.Spell
    local targetType = itemSpell and itemSpell.TargetType()
    local selfTargeted = Casting.IsSelfSpell(targetType)
    local spellTargetId = selfTargeted and me.ID() or targetId

    if (mq.TLO.Window("CastingWindow").Open() or me.Casting()) and not Casting.CanActMidSong(castTime) then
        Logger.log_debug("\ayUseItem(): \arCan't use %s - Casting Window Open", itemName)
        return false
    end

    local spellRange = Casting.GetSpellRange(itemSpell)
    if spellTargetId and spellTargetId ~= me.ID() then
        local targetSpawn = mq.TLO.Spawn(spellTargetId)
        if targetSpawn and targetSpawn() and Targeting.GetTargetDistance(targetSpawn) > spellRange then
            Logger.log_debug("\ayUseItem(): \arTried to use %s on %s but they are too far away", itemName, targetSpawn and targetSpawn.DisplayName() or "None")
            return false
        end
    end

    if spellTargetId and spellTargetId == me.ID() then
        if Casting.IHaveBuff(item.Clicky.SpellID()) then
            Logger.log_debug("\ayUseItem(): \arTried to use %s - clicky already active or won't stack", itemName)
            return false
        end

        if itemSpell() and itemSpell.HasSPA(0)() then
            for i = 1, itemSpell.NumEffects() do
                if itemSpell.Attrib(i)() == 0 then
                    if me.CurrentHPs() + itemSpell.Base(i)() <= 0 then
                        Logger.log_verbose("\ayUseItem(): \arTried to use %s (%s) but it would kill me; HPs: %d SpaHP: %d", itemName, itemSpell.Name(), me.CurrentHPs(),
                            itemSpell.Base(i)())
                        return false
                    end
                end
            end
        end
    end

    Casting.ActionPrep()

    local oldTargetId = mq.TLO.Target.ID()
    if not selfTargeted and targetId and targetId > 0 and targetId ~= oldTargetId then
        local targetSpawn = mq.TLO.Spawn(targetId)
        if Config:GetSetting('StopAttackForPCs') and me.Combat() and (targetSpawn.Type() or ""):lower() == "pc" then -- don't use helper here, don't want fallback to current target
            Logger.log_debug("\awUseItem():NOTICE:\ax Turning off autoattack to cast on a PC.")
            Core.DoCmd("/attack off")
            mq.delay("2s", function() return not me.Combat() end)
        end

        Logger.log_debug("\awUseItem():NOTICE:\ax Swapping target to %s [%d] to use %s", targetSpawn.DisplayName(), targetId, itemName)
        Targeting.SetTarget(targetId, true)
    end

    local cmd = string.format("/useitem \"%s\"", itemName)
    local noRecast = (item.Clicky() and (item.Clicky.TimerID() or 0) == 0) or false
    local readyCheck = function() return me.ItemReady(itemName)() end

    Casting.RunCastLoop({
        cmd = cmd,
        readyCheck = readyCheck,
        actionName = itemName,
        targetId = spellTargetId,
        -- default true (unlike UseAA/UseSpell) so rez clickies still fire on dead targets
        bAllowDead = bAllowDead ~= false,
        spellRange = spellRange,
        castTime = castTime,
        retryCount = retryCount,
        fireAndForget = fireAndForget,
    })
    if Globals.StopCast then return false end

    if mq.TLO.Cursor.ID() then
        Core.DoCmd("/autoinv")
    end

    if mq.TLO.Target.ID() ~= oldTargetId and Combat.ValidCombatTarget(oldTargetId) and (oldTargetId == Globals.AutoTargetID or not Config:GetSetting('DoAutoTarget')) then
        Logger.log_debug("UseItem(): Retargeting previous target after item use.")
        Targeting.SetTarget(oldTargetId, true)
    end

    return Casting.CastSucceeded(readyCheck, noRecast), Casting.IsGroupSpell(targetType)
end

--- Ensures the character is in a castable state immediately before a cast: stands the player up if they are sitting, and closes the spellbook window if it is open.
function Casting.ActionPrep()
    if not mq.TLO.Me.Standing() then
        mq.TLO.Me.Stand()
        mq.delay(10, function() return mq.TLO.Me.Standing() end)

        --Globals.InMedState = false -- allow us to sit back down after the action, automed has been adjusted
    end

    if mq.TLO.Window("SpellBookWnd").Open() then
        mq.TLO.Window("SpellBookWnd").DoClose()
    end
end

--- Polls Me.Casting every 20 ms until it clears, up to a timeout derived from cast time plus 20x ping plus 1 second. While waiting, StopCasts the spell if the target dies or leaves range (beyond 110% of spellRange); every 200 ms prods the pet to attack if combat is active and HP is below PetEngagePct; every 500 ms runs MA auto-target and tank aggro scans; prints a group message and force-stops if the timeout expires.
--- @param targetId number|nil The target to check while waiting.
--- @param bAllowDead boolean Whether to allow the target to be dead.
--- @param spellRange number The max range of the spell.
--- @param castTime number|nil The length of the spell's cast.
function Casting.WaitCastFinish(targetId, bAllowDead, spellRange, castTime)
    local maxWaitOrig = (castTime or 5000) + ((mq.TLO.EverQuest.Ping() * 20) + 1000)
    local maxWait = maxWaitOrig

    -- A playing bard song keeps Me.Casting truthy with no cast window; don't count it as an in-flight cast.
    while mq.TLO.Me.Casting() and (mq.TLO.Window("CastingWindow").Open() or not mq.TLO.Me.BardSongPlaying()) do
        local currentCast = mq.TLO.Me.Casting()
        Logger.log_super_verbose("WaitCastFinish(): Waiting to Finish Casting...")
        mq.delay(20)

        if targetId and targetId > 0 then
            local target = mq.TLO.Spawn(targetId)
            if (not target or not target() or Targeting.TargetIsType("corpse", target)) and not bAllowDead then
                mq.TLO.Me.StopCast()
                Logger.log_debug("WaitCastFinish(): Canceled casting %s because target is dead or no longer exists.", currentCast)
                return
            elseif spellRange and target() and not Targeting.TargetIsMyself(target) and Targeting.GetTargetDistance(target) > (spellRange * 1.1) then --allow for slight movement in and out of range, if the target runs off, this is still easily triggered
                mq.TLO.Me.StopCast()
                Logger.log_debug("WaitCastFinish(): Canceled casting %s because spellTarget(%d, range %d) is out of spell range(%d)", currentCast, target.ID(),
                    Targeting.GetTargetDistance(), spellRange)
                return
            elseif target() and not Targeting.TargetIsMyself(target) and target.ID() ~= Targeting.GetTargetID() then
                Logger.log_debug("WaitCastFinish(): Warning your spellTarget(%d) for %s is no longer your currentTarget(%d)", target.ID(), currentCast, Targeting.GetTargetID())
            end
        end

        local currentWait = maxWaitOrig - maxWait
        if currentWait % 200 == 0 then
            if Combat.DoCombatActions() and mq.TLO.Me.Pet.ID() > 0 and not mq.TLO.Me.Pet.Combat() and not string.find(mq.TLO.Me.Pet.CleanName() or "", "familiar") then --alleviate pets standing around at early levels where mob HPs are low and cast times are long
                if Targeting.GetTargetPctHPs(Targeting.GetAutoTarget()) <= Config:GetSetting('PetEngagePct') then
                    Combat.PetAttack(Globals.AutoTargetID, true)
                end
            end
        end
        if currentWait % 500 == 0 then
            Casting.RescanCombatTargets()
        end

        maxWait = maxWait - 20

        if maxWait <= 0 then
            local msg = string.format("StuckGem Data::: %d - MaxWait - %d - Casting Window: %s - Assist Target ID: %d",
                (mq.TLO.Me.Casting.ID() or -1), maxWaitOrig,
                Strings.BoolToColorString(mq.TLO.Window("CastingWindow").Open()), Globals.AutoTargetID)

            Logger.log_debug(msg)
            Comms.PrintGroupMessage(msg)

            --Algarnote: Consider re-adding this, but i'm not sure this is the place where we need to be doing it (we are in the while casting loop here, i think gem freeze will have no casting active)
            --Core.DoCmd("/alt act 511")
            mq.TLO.Me.StopCast()
            return
        end

        if Globals.StopCast then
            mq.TLO.Me.StopCast()
            return
        end

        mq.doevents()
        Events.DoEvents()
    end
end

--- Polls Me.SpellReady every 20 ms until the spell's gem timer has cleared or maxWait (ms) expires; aborts early if combat begins or if the spell leaves the player's book due to a persona change. Adds a ping-scaled delay after the spell becomes ready to account for server lag.
--- @param spell string The name of the spell to wait for.
--- @param maxWait number The maximum amount of time (in miliseconds) to wait for the spell to be ready.
function Casting.WaitCastReady(spell, maxWait)
    while not mq.TLO.Me.SpellReady(spell)() and maxWait > 0 do
        mq.delay(20)
        mq.doevents()
        Events.DoEvents()
        if Targeting.GetXTHaterCount() > 0 then
            Logger.log_debug("I was interrupted by combat while waiting to cast %s.", spell)
            return
        end
        if not mq.TLO.Me.Book(spell)() then
            Logger.log_debug("I was trying to cast %s as my persona was changed, aborting.", spell)
            return
        end

        maxWait = maxWait - 20

        if (maxWait % 1000) == 0 then
            Logger.log_verbose("Waiting for spell '%s' to be ready...", spell)
        end
    end

    -- account for lag
    local pingDelay = mq.TLO.EverQuest.Ping() * Config:GetSetting('CastReadyDelayFact')
    mq.delay(pingDelay)
end

--- Generic blocking wait: polls pollFn every ~20 ms (pumping events to stay responsive) until it returns true, abortFn returns true, or maxWaitMs elapses; ability-agnostic sibling to WaitCastReady for callers needing a custom ready/abort condition.
---@param pollFn fun():boolean Returns true when the wait should end successfully.
---@param maxWaitMs number Maximum time to wait, in milliseconds.
---@param abortFn fun():boolean|nil Optional; returns true to abort the wait early.
function Casting.WaitForReady(pollFn, maxWaitMs, abortFn)
    local remaining = maxWaitMs or 0
    while remaining > 0 do
        if pollFn() then return end
        if abortFn and abortFn() then return end
        mq.delay(20)
        mq.doevents()
        Events.DoEvents()
        remaining = remaining - 20
        if (remaining % 1000) == 0 then
            Logger.log_verbose("WaitForReady: waiting... %dms left", remaining)
        end
    end
end

--- Polls Me.SpellInCooldown every 100 ms until the global spell cooldown (the "gem lockout" between casts) has cleared, processing events each iteration to keep the system responsive.
--- @param logPrefix string|nil: An optional prefix to be used in log messages.
function Casting.WaitGlobalCoolDown(logPrefix)
    while mq.TLO.Me.SpellInCooldown() do
        mq.delay(100)
        mq.doevents()
        Events.DoEvents()
        Logger.log_verbose(logPrefix and logPrefix or "" .. "Waiting for Global Cooldown to be ready...")
    end
end

--- Retrieves the name of the last cast result.
--- @return string The name of the last cast result.
function Casting.GetLastCastResultName()
    return Globals.Constants.CastResultsIdToName[Globals.CastResult]
end

--- Retrieves the ID of the last cast result.
--- @return number The ID of the last cast result.
function Casting.GetLastCastResultId()
    return Globals.CastResult
end

--- Sets the result of the last cast operation.
--- @param result number The result to be set for the last cast operation.
function Casting.SetLastCastResult(result)
    Logger.log_debug("\awSet Last Cast Result => \ag%s", Globals.Constants.CastResultsIdToName[result])
    Globals.CastResult = result
end

--- Retrieves the last used spell.
--- @return string The name of the last used spell.
function Casting.GetLastUsedSpell()
    return Globals.LastUsedSpell
end

--- Evaluates HP/mana/endurance thresholds and movement/combat state to decide whether to sit the character down to regenerate or stand them back up. Skips if feigning death, mounted outdoors, or in combat with aggro above MedAggroPct; uses per-class threshold settings (casters/hybrids check mana, melee check HP/endurance only) and a random post-combat delay before sitting.
function Casting.AutoMed()
    local me = mq.TLO.Me
    if Config:GetSetting('DoMed') == 1 then return end
    if Casting.IAmFeigning() then return end

    if me.Mount.ID() and not mq.TLO.Zone.Indoor() then
        Logger.log_verbose("Sit check returning early due to mount.")
        return
    end

    -- Stand up to fight or when threatened.
    local aggroStand  = Config:GetSetting('MedAggroCheck') and Targeting.IHaveAggro(Config:GetSetting('MedAggroPct'))
    local combatStand = Targeting.GetXTHaterCount() > 0 and (Config:GetSetting('DoMed') ~= 3 or Config:GetSetting('DoMelee'))
    if aggroStand or combatStand then
        Globals.InMedState = false
        if me.Sitting() and not Casting.Memorizing then
            Logger.log_debug("Forcing stand - Combat or aggro threshold reached.")
            me.Stand()
        end
        return
    end

    -- Allow sufficient time for the player to do something before char plunks down. Spreads out med sitting too.
    local afterCombatMedDelay = Config:GetSetting('AfterCombatMedDelay')
    if Targeting.GetXTHaterCount() == 0 and afterCombatMedDelay > 0 and Movement:GetTimeSinceLastMove() < math.random(afterCombatMedDelay) then return end

    Movement:StoreLastMove()

    --If we're moving/following/navigating/sticking, don't med.
    if me.Casting() or me.Moving() or mq.TLO.Stick.Active() or mq.TLO.Navigation.Active() or mq.TLO.MoveTo.Moving() then
        Logger.log_verbose(
            "Sit check returning early due to movement. Casting(%s) Moving(%s) Stick(%s) Nav(%s) MoveTo(%s)", me.Casting() or "None", Strings.BoolToColorString(me.Moving()),
            Strings.BoolToColorString(mq.TLO.Stick.Active()), Strings.BoolToColorString(mq.TLO.Navigation.Active()), Strings.BoolToColorString(mq.TLO.MoveTo.Moving()))
        return
    end

    local forcesit   = false
    local forcestand = false

    if Globals.Constants.RGHybrid:contains(me.Class.ShortName()) or Globals.Constants.RGCasters:contains(me.Class.ShortName()) then
        -- Handle the case where we're a Hybrid. We need to check mana and endurance. Needs to be done after
        -- the original stat checks.
        if me.PctHPs() >= Config:GetSetting('HPMedPctStop') and me.PctMana() >= Config:GetSetting('ManaMedPctStop') and me.PctEndurance() >= Config:GetSetting('EndMedPctStop') then
            Globals.InMedState = false
            forcestand = true
        end

        if me.PctHPs() < Config:GetSetting('HPMedPct') or me.PctMana() < Config:GetSetting('ManaMedPct') or me.PctEndurance() < Config:GetSetting('EndMedPct') then
            forcesit = true
        end
    elseif Globals.Constants.RGMelee:contains(me.Class.ShortName()) then
        if me.PctHPs() >= Config:GetSetting('HPMedPctStop') and me.PctEndurance() >= Config:GetSetting('EndMedPctStop') then
            Globals.InMedState = false
            forcestand = true
        end

        if me.PctHPs() < Config:GetSetting('HPMedPct') or me.PctEndurance() < Config:GetSetting('EndMedPct') then
            forcesit = true
        end
    else
        Logger.log_error(
            "\arYour character class is not in the type list(s): rghybrid, rgcasters, rgmelee. That's a problem for a dev.")
        Globals.InMedState = false
        return
    end

    Logger.log_verbose(
        "MED MAIN STATS CHECK :: HP %d :: HPMedPct %d :: Mana %d :: ManaMedPct %d :: Endurance %d :: EndPct %d :: forceSit %s :: forceStand %s :: Memorizing %s",
        me.PctHPs(), Config:GetSetting('HPMedPct'), me.PctMana(),
        Config:GetSetting('ManaMedPct'), me.PctEndurance(),
        Config:GetSetting('EndMedPct'), Strings.BoolToColorString(forcesit), Strings.BoolToColorString(forcestand), Strings.BoolToColorString(Casting.Memorizing))

    -- This could likely be refactored
    if me.Sitting() and not Casting.Memorizing then
        if (Config:GetSetting('StandWhenDone') or Config:GetSetting('DoPull')) and forcestand then
            Globals.InMedState = false
            Logger.log_debug("Forcing stand - all conditions met.")
            me.Stand()
            return
        end
    end

    -- if we aren't sitting, see if we were already medding and we got interrupted, or if our checks above say we should start medding
    if not me.Sitting() and (Globals.InMedState or forcesit) then
        Globals.InMedState = true
        Logger.log_debug("Forcing sit - all conditions met.")
        me.Sit()
    end
end

-- Deprecated 5/26 - Use AASets
--- Deprecated alias for GetFirstAA. Iterates the list and returns
--- the first AA name that passes CanUseAA.
---@param aaList table The list of AA names to check.
---@return string The first useable AA name, or "Unpurchased AA".
function Casting.GetBestAA(aaList)
    return Casting.GetFirstAA(aaList)
end

-- Deprecated 5/26 - Use AASets
--- Retrieves the first available purchased AA in a list.
--- @param aaList table The list of AA to check.
--- @return string The name of the selected AA (or "None" if no ability was found).
function Casting.GetFirstAA(aaList)
    local ret = "Unpurchased AA"
    if aaList and type(aaList) == "table" then
        for _, abil in ipairs(aaList) do
            if Casting.CanUseAA(abil) then
                ret = abil
                break
            end
        end
    end
    return ret
end

--- Retrieves the first available resolved map item in a list.
--- @param mapList table The list of mapped actions to check.
--- @return string The name of the selected map (or "None" if no ability was found).
function Casting.GetFirstMapItem(mapList)
    local ret = "Unlearned Spell/Ability"
    if mapList and type(mapList) == "table" then
        for _, abil in ipairs(mapList) do
            if Core.GetResolvedActionMapItem(abil) then
                ret = abil
                break
            end
        end
    end
    return ret
end

--- Scans inventory for a known modrod and clicks it on self. Skips
--- non-casters, players above ModRodManaPct mana, HP below 60%,
--- feigning, invisible, and EMU bards.
function Casting.ClickModRod()
    local me = mq.TLO.Me
    if not Globals.Constants.RGCasters:contains(me.Class.ShortName()) or me.PctMana() > Config:GetSetting('ModRodManaPct') or me.PctHPs() < 60 or Casting.IAmFeigning() or mq.TLO.Me.Invis() or (Core.MyClassIs("BRD") and Core.OnEMU()) then
        return
    end

    for _, itemName in ipairs(Globals.Constants.ModRods) do
        while mq.TLO.Cursor.Name() == itemName do
            Core.DoCmd("/squelch /autoinv")
            mq.delay(10)
        end

        local item = mq.TLO.FindItem(itemName)
        if item() and item.Clicky() and mq.TLO.Me.Level() >= (item.Clicky.RequiredLevel() or 999) and item.TimerReady() == 0 then
            Casting.UseItem(item.Name(), mq.TLO.Me.ID())
            return
        end
    end
end

--- Tallies group members below the mana threshold. Adds the player
--- on EMU servers where Group.LowMana excludes the local PC.
---@param percent number? Mana threshold to check; defaults to 50.
---@return number Count of group members below the threshold.
function Casting.GroupLowManaCount(percent)
    local count = mq.TLO.Group.LowMana(percent or 50)() or 0
    if Core.OnEMU() then
        count = count + (mq.TLO.Me.PctMana() < (percent or 50) and 1 or 0)
    end
    return count
end

--- Delegates to the Class module's TargetIsImmune check for "Slow".
---@param target MQSpawn? Defaults to current target if nil.
---@return boolean True if the target is immune to slow effects.
function Casting.SlowImmuneTarget(target)
    if not target then target = mq.TLO.Target end
    local targetId = target.ID() or 0
    return Modules:ExecModule("Class", "TargetIsImmune", "Slow", targetId)
end

--- Delegates to the Class module's TargetIsImmune check for "Snare".
---@param target MQSpawn? Defaults to current target if nil.
---@return boolean True if the target is immune to snare effects.
function Casting.SnareImmuneTarget(target)
    if not target then target = mq.TLO.Target end
    local targetId = target.ID() or 0
    return Modules:ExecModule("Class", "TargetIsImmune", "Snare", targetId)
end

--- Delegates to the Class module's TargetIsImmune check for "Stun".
---@param target MQSpawn? Defaults to current target if nil.
---@return boolean True if the target is immune to stun effects.
function Casting.StunImmuneTarget(target)
    if not target then target = mq.TLO.Target end
    local targetId = target.ID() or 0
    return Modules:ExecModule("Class", "TargetIsImmune", "Stun", targetId)
end

--- Returns true if a spell of the given element should be skipped against this spawn.
--- Only fires when targetId matches the current auto-target. Combines the global
--- Skip<Element>Spells toggle with the per-mob elemental immunity flag from the Named List.
--- Buffs, heals, and group abilities against non-auto-target spawns are never affected.
---@param element string Element name ("Fire"/"Cold"/"Magic"/"Poison"/"Disease").
---@param targetId number Spawn ID of the intended cast target.
---@return boolean True if the spell should be skipped.
function Casting.ShouldSkipElement(element, targetId)
    if not element or targetId ~= Globals.AutoTargetID then return false end
    if not Globals.Constants.ResistTypesSet:contains(element) then return false end
    if Config:GetSetting("Skip" .. element .. "Spells") then return true end
    return Globals.AutoTargetElementalImmunities[element] == true
end

--- Returns true if TempSettings flags the current zone as no-lev,
--- used to gate levitation buff casting.
---@return boolean True if the zone prohibits levitation.
function Casting.NoLevZone()
    return Config.TempSettings.NoLevZone or false
end

--- Return the proper spell ID based on subscription level and "Spell Unlocker" purchase
--- @param spell MQSpell The spell effect to check for
--- @return number spellId The proper ID of the spell to use in (de)buff checks
function Casting.GetUseableSpellId(spell)
    if not spell and not spell() then return 0 end

    -- first check if *we* have the spell
    local mySpell = mq.TLO.Me.Spell
    local baseName = spell.BaseName()

    local spellId = mySpell(baseName).ID() or 0

    if spellId > 0 then
        local rankCap = mq.TLO.Me.SpellRankCap()
        -- we have the spell, lets check our spell rank cap
        if rankCap == 1 then
            -- they aren't subscribed and haven't purchased the rank 2 unlocker.
            spellId = mq.TLO.Spell(baseName).ID()
        elseif rankCap == 2 and (mySpell(baseName).Rank() or 0) > 2 then
            --they've purchased the rank 2 unlocker
            local trueSpell = string.gsub(mySpell(baseName)(), "III", "II")
            spellId = mq.TLO.Spell(trueSpell).ID()
        end
    end

    -- also allow for buff checking spells we don't have
    return spellId > 0 and spellId or spell.ID()
end

--- Returns true if spell is allowed to land on target per EQ's buff-level restriction (only applies to persistent beneficial buffs on PC targets, global IgnoreLevelCheck bypasses).
---@param spell MQSpell The spell to evaluate.
---@param target MQSpawn|MQTarget|nil The target spawn handle to check.
---@return boolean True if the spell is allowed to land on target.
function Casting.LevelCheckPass(spell, target)
    if Config:GetSetting('IgnoreLevelCheck') then return true end
    if not spell or not spell() then return false end
    if not target or not target() then return false end
    if (target.Type() or ""):lower() ~= "pc" then return true end
    if not (spell.Beneficial() and (spell.Duration.TotalSeconds() or 0) > 0) then return true end
    local spellLevel = spell.Level() or 999
    if spellLevel > Globals.Constants.LiveLevelCap then return true end

    local targetLevel = target.Level() or 0
    local maxSpellLevel
    -- table data taken from https://everquest.fanra.info/wiki/Spells,_Songs,_Disciplines,_and_AAs#Buff_level_restrictions
    -- converted to perpetuate past the table limits. untested
    if targetLevel <= 39 then
        maxSpellLevel = 50
    elseif targetLevel <= 46 then
        maxSpellLevel = 51 + (targetLevel - 40) * 2
    elseif targetLevel <= 60 then
        maxSpellLevel = 65
    else
        maxSpellLevel = math.min(93 + (targetLevel - 61) * 2, Globals.Constants.LiveLevelCap)
    end

    return maxSpellLevel >= spellLevel
end

function Casting.SlowSpellCheck(spell, target)
    if not spell or not spell() then return false end
    return (spell.RankName.SlowPct() or 0) > Targeting.GetTargetSlowedPct() and not Casting.SlowImmuneTarget(target)
end

return Casting
