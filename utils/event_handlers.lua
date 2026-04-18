local mq          = require('mq')
local Config      = require('utils.config')
local Globals     = require('utils.globals')
local Modules     = require("utils.modules")
local Core        = require("utils.core")
local Combat      = require("utils.combat")
local Casting     = require("utils.casting")
local Targeting   = require("utils.targeting")
local Comms       = require("utils.comms")
local Logger      = require("utils.logger")
local Movement    = require("utils.movement")
local ClassLoader = require('utils.classloader')
local Strings     = require("utils.strings")


-- [ CANT SEE HANDLERS ] --

mq.event("CantSee", "You cannot see your target.", function()
    Logger.log_debug("CantSee: Event Detected")
    if Globals.BackOffFlag then return end
    if Globals.PauseMain then return end
    local target = mq.TLO.Target
    if mq.TLO.Stick.Active() then
        Movement:DoStickCmd("off")
        Movement:ClearLastStickTimer()
    end

    if Modules:ExecModule("Pull", "IsPullState", "PULL_PULLING") then
        Logger.log_debug("CantSee: \ayWe are in Pull_State PULLING and Cannot see our target!")
        Movement:DoNav(false, "id %d distance=%d lineofsight=on log=off", target.ID() or 0, (target.Distance3D() or 0) * 0.5)
        mq.delay("2s", function() return mq.TLO.Navigation.Active() end)
    elseif Modules:ExecModule("Pull", "IsPullState", "PULL_RETURN_TO_CAMP") then
        Logger.log_debug("CantSee event detected, but we are pulling and currently returning to camp.")
    else
        if Config:GetSetting('HandleCantSeeTarget') then
            local haterCount = Targeting.GetXTHaterCount()
            if Config:GetSetting('DoAutoEngage') and not mq.TLO.Me.Moving() or haterCount > 0 then
                local helpers = Core.GetHelpers()
                if helpers and helpers.combatNav then
                    Logger.log_debug("CantSee: \ayWe are in COMBAT and Cannot see our target - using custom combatNav!")
                    Core.SafeCallFunc("Ranger Custom Nav", helpers.combatNav, true)
                else
                    Logger.log_debug("CantSee: \ayWe are in COMBAT and Cannot see our target - using generic combatNav!")
                    if Combat.OkToEngage(target.ID() or 0) then
                        Core.DoCmd("/squelch /face fast")
                        -- if we are too close, lets just take a step back
                        local targDist = Targeting.GetTargetDistance()
                        if Config:GetSetting('DoMelee') and targDist < 10 and targDist < (Targeting.GetMaxMeleeRange(target, true)) then
                            Logger.log_debug("CantSee: Can't See target (%s [%d]). Moving back 10.", target.CleanName() or "", target.ID() or 0)
                            Movement:DoStickCmd("10 moveback uw")
                            -- wait to start moving, make our movement, turn stick off to yield to our original stick settings. If our original settings are bad, this could cause a loop
                            mq.delay(100, function() return mq.TLO.Stick.Active() end)
                            mq.delay(500, function() return not mq.TLO.Me.Moving() end)
                            Movement:DoStickCmd("off")
                            Movement:ClearLastStickTimer()
                        end
                        -- if we aren't too close, or still dont have LoS, lets nav, as long as the mob is still around
                        if target.ID() > 0 and not Targeting.GetTargetDead(target) and not Targeting.GetTargetLOS(target) then
                            local desiredDistance = (target.MaxRangeTo() or 0) * 0.7
                            if not Config:GetSetting('DoMelee') then
                                desiredDistance = Targeting.GetTargetDistance() * .95
                            end

                            Logger.log_debug("CantSee: Can't See target (%s [%d]). Naving to %d away.", target.CleanName() or "", target.ID(), desiredDistance)
                            Movement:NavInCombat(target.ID(), desiredDistance, false, true)
                        end
                    end
                end
            else
                Logger.log_debug("CantSee event detected, but checks failed: AutoEngage(%s), Moving(%s), HaterCount > 0(%s)",
                    Strings.BoolToColorString(Config:GetSetting('DoAutoEngage')), Strings.BoolToColorString(mq.TLO.Me.Moving()), Strings.BoolToColorString(haterCount > 0))
            end
        else
            Logger.log_debug("CantSee event detected, but HandleCantSeeTarget is not enabled.")
        end
    end
    mq.flushevents("CantSee")
end)

-- [ END CANT SEE HANDLERS ] --

-- [ TOO CLOSE HANDLERS] --

mq.event("TooClose", "Your target is too close to use a ranged weapon!", function()
    Logger.log_debug("TooClose: Event Detected")
    -- Check if we're in the middle of a pull and use a backup.
    if Config:GetSetting('DoPull') and Modules:ExecModule("Pull", "IsPullState", "PULL_PULLING") then
        Logger.log_debug("TooClose: Pull Mode Detected.")
        local discSpell = mq.TLO.Spell("Throw Stone")
        if Casting.DiscReady(discSpell) then
            Logger.log_debug("TooClose: Attempting to Throw Stone.")
            Casting.UseDisc(discSpell, mq.TLO.Target.ID())
        else
            if Casting.AbilityReady("Taunt") then
                Logger.log_debug("TooCloseHandler: Naving to target to use Taunt.")
                Movement:DoNav(false, "id %d distance=%d lineofsight=on log=off", Targeting.GetTargetID(), (Targeting.GetTargetMaxRangeTo() * .8))
                mq.delay("2s", function() return mq.TLO.Navigation.Active() end)
                Casting.UseAbility("Taunt")
                Logger.log_debug("TooClose: Attempting to Taunt.")
            end
            if Casting.AbilityReady("Kick") then
                Logger.log_debug("TooCloseHandler: Naving to target to use Kick.")
                Movement:DoNav(false, "id %d distance=%d lineofsight=on log=off", Targeting.GetTargetID(), (Targeting.GetTargetMaxRangeTo() * .8))
                mq.delay("2s", function() return mq.TLO.Navigation.Active() end)
                Casting.UseAbility("Kick")
                Logger.log_debug("TooClose: Attempting to Kick.")
            end
        end
    elseif Modules:ExecModule("Pull", "IsPullState", "PULL_RETURN_TO_CAMP") then
        Logger.log_debug("CantSee event detected, but we are pulling and currently returning to camp.")
    else
        if Config:GetSetting('HandleTooClose') then
            local haterCount = Targeting.GetXTHaterCount()
            if Config:GetSetting('DoAutoEngage') and not mq.TLO.Me.Moving() and haterCount > 0 then
                Logger.log_debug("TooCloseHandler: Pull State not detected, using Combat Nav.")
                local helpers = Core.GetHelpers()
                if helpers and helpers.combatNav then
                    Core.SafeCallFunc("Ranger Custom Nav", helpers.combatNav, false)
                else
                    Logger.log_debug("TooClose event detected, but we don't have class-specific combat nav for ranged combat!")
                end
            else
                Logger.log_debug("TooClose event detected, but checks failed: AutoEngage(%s), Moving(%s), HaterCount > 0(%s)",
                    Strings.BoolToColorString(Config:GetSetting('DoAutoEngage')), Strings.BoolToColorString(mq.TLO.Me.Moving()), Strings.BoolToColorString(haterCount > 0))
            end
        else
            Logger.log_debug("TooClose event detected, but HandleTooClose is not enabled.")
        end
    end
    mq.flushevents("TooClose")
end)

-- [ END TOO CLOSE HANDLERS] --

-- [ TOO FAR HANDLERS ] --

local function tooFarHandler()
    Logger.log_debug("TooFar: Event Detected")
    if Globals.BackOffFlag then return end
    if Globals.PauseMain then return end

    if mq.TLO.Stick.Active() then
        Movement:DoStickCmd("off")
        Movement:ClearLastStickTimer()
    end
    local target = mq.TLO.Target

    if Modules:ExecModule("Pull", "IsPullState", "PULL_PULLING") then
        Logger.log_debug("TooFar: \ayWe are in Pull_State PULLING and too far from our target! target(%s) targetDistance(%d)",
            Targeting.GetTargetCleanName(),
            Targeting.GetTargetDistance())
        Movement:DoNav(false, "id %d distance=%d lineofsight=on log=off", target.ID() or 0, (target.Distance3D() or 0) * 0.7)
        mq.delay("2s", function() return mq.TLO.Navigation.Active() end)
    elseif Modules:ExecModule("Pull", "IsPullState", "PULL_RETURN_TO_CAMP") then
        Logger.log_debug("CantSee event detected, but we are pulling and currently returning to camp.")
    else
        if Config:GetSetting('HandleTooFar') then
            local helpers = Core.GetHelpers()
            local haterCount = Targeting.GetXTHaterCount()
            if Config:GetSetting('DoAutoEngage') and not mq.TLO.Me.Moving() and haterCount > 0 then
                if helpers and helpers.combatNav then
                    Core.SafeCallFunc("Custom Nav", helpers.combatNav)
                elseif Config:GetSetting('DoMelee') then
                    Logger.log_debug("TooFar: \ayWe are in COMBAT and too far from our target!")
                    if Config:GetSetting('DoAutoEngage') and Combat.OkToEngage(target.ID() or 0) then
                        local maxRange = (target.MaxRangeTo() or 999) < 30 and target.MaxRangeTo() or 10 -- account for some mobs like giant elementals that have a maxrangeto of 70
                        local distance = Targeting.GetTargetDistance()
                        if distance < 10 and distance < maxRange then                                    --not sure if this is necessary or still happening since we changed distance to use 3D.
                            Logger.log_debug("TooFar: Too Far from Target (%s [%d]). Possible flyer detected. Moving back 10.", target.CleanName() or "", target.ID() or 0)
                            Core.DoCmd("/squelch /face fast")
                            Movement:DoStickCmd("10 moveback uw")
                            -- wait to start moving, make our movement, turn stick off to yield to our original stick settings. If our original settings are bad, this could cause a loop
                            mq.delay(100, function() return mq.TLO.Stick.Active() end)
                            mq.delay(500, function() return not mq.TLO.Me.Moving() end)
                            Movement:DoStickCmd("off")
                            Movement:ClearLastStickTimer()
                        else
                            local navDist = maxRange * 0.7
                            Logger.log_debug("TooFar: Too Far from Target (%s [%d]). Naving to %d away.", target.CleanName() or "", target.ID() or 0, navDist)
                            Movement:NavInCombat(target.ID(), navDist, false, true)
                        end
                    else
                        Logger.log_debug("TooFar event detected, but we are not ok to engage or autoengage is disabled.")
                    end
                end
            else
                Logger.log_debug("TooFar event detected, but checks failed: AutoEngage(%s), Moving(%s), HaterCount > 0(%s)",
                    Strings.BoolToColorString(Config:GetSetting('DoAutoEngage')), Strings.BoolToColorString(mq.TLO.Me.Moving()), Strings.BoolToColorString(haterCount > 0))
            end
        else
            Logger.log_debug("TooFar event detected, but HandleTooFar is not enabled.")
        end
    end
end

mq.event("TooFar1", "#*#Your target is too far away, get closer!", function()
    tooFarHandler()
    mq.flushevents("TooFar1")
end)
mq.event("TooFar2", "#*#You can't hit them from here.", function()
    tooFarHandler()
    mq.flushevents("TooFar2")
end)
mq.event("TooFar3", "#*#You are too far away#*#", function()
    tooFarHandler()
    mq.flushevents("TooFar3")
end)

-- [ END TOO FAR HANDLERS ] --

-- [ MEM SPELL HANDLERS ] --
mq.event('Begin Memo', "Beginning to memorize#*#", function()
    Casting.Memorizing = true
end)

mq.event('End Memo', "You have finished memorizing#*#", function()
    Casting.Memorizing = false
end)

mq.event('Abort Memo', "Aborting memorization of spell.", function()
    Casting.Memorizing = false
end)

-- [ END MEM SPELL HANDLERS ] --

-- [ SCRIBE SPELL HANDLERS ] --
mq.event('Begin Scribe', "Beginning to scribe#*#.", function()
    Casting.Memorizing = true
end)

mq.event('End Scribe', "You have finished scribing#*#", function()
    Casting.Memorizing = false
    -- Rescan spell list
    Modules:ExecModule("Class", "RescanLoadout")
end)

mq.event('Abort Scribe', "Aborting scribing of spell.", function()
    Casting.Memorizing = false
end)

-- [ END SCRIBE SPELL HANDLERS ] --

mq.event('New Discipline', "You have learned a new discipline!", function()
    Modules:ExecModule("Class", "RescanLoadout")
    mq.flushevents("New Discipline")
end)

mq.event('Level Up', "You have gained a level! Welcome to level#*#", function()
    -- we may have spells scribed for the new level already on EQ Might, where deleveling is a standard part of play
    -- Feb 2026, live added "autoscribe"
    if not Core.OnEMU() or Globals.CurServer == "EQ Might" then
        Modules:ExecModule("Class", "RescanLoadout")
    end
end)

mq.event('Level Down', "You have LOST a level! You are now level#*#", function()
    -- support EQ Might, where deleveling is a standard part of play
    if Globals.CurServer == "EQ Might" then
        Modules:ExecModule("Class", "RescanLoadout")
    end
end)

-- [ CAST RESULT HANDLERS ] --
mq.event('Success1', "You begin casting#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_SUCCESS)
end)

mq.event('Success2', "You begin singing#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_SUCCESS)
end)

mq.event('Success3', "Your #1# begins to glow.#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_SUCCESS)
end)

mq.event('Overwritten1', "Your#*#has been overwritten#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_OVERWRITTEN)
end)

mq.event('Collapsed1', "Your gate is too unstable, and collapses#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_COLLAPSE)
end)

mq.event('Distracted1', "You need to play a#*#instrument for this song#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_DISTRACTED)
end)

mq.event('Distracted2', "You are too distracted to cast a spell now#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_DISTRACTED)
end)

mq.event('Distracted3', "You can't cast spells while invulnerable#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_DISTRACTED)
end)

mq.event('Distracted4', "You *CANNOT* cast spells, you have been silenced#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_DISTRACTED)
end)

mq.event('Distracted5', "You do not have sufficient focus to maintain that ability.", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_DISTRACTED)
end)

mq.event('Fizzle1', "Your spell fizzles#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_FIZZLE)
end)

mq.event('Fizzle2', "You miss a note, bringing your song to a close#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_FIZZLE)
end)

mq.event('Fizzle3', "You miss a note, bringing your #*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_FIZZLE)
end)

mq.event('Interrupted1', "Your spell is interrupted#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_INTERRUPTED)
end)

mq.event('Interrupted2', "Your casting has been interrupted#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_INTERRUPTED)
end)

mq.event('Interrupted3', "Your #1# spell is interrupted#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_INTERRUPTED)
end)

mq.event('NoTarget1', "You must first select a target for this spell#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_NOTARGET)
end)

mq.event('NoTarget2', "This spell only works on#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_NOTARGET)
end)

mq.event('NoTarget3', "You must first target a group member#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_NOTARGET)
end)

mq.event('NotReady1', "Spell recast time not yet met#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_NOTREADY)
end)

mq.event('OutOfMana1', "Insufficient Mana to cast this spell#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_OUTOFMANA)
end)

mq.event('OutOfRange1', "Your target is out of range, get closer#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_OUTOFRANGE)
end)

mq.event('OutDoors1', "This spell does not work here#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_OUTDOORS)
end)

mq.event('OutDoors2', "You can only cast this spell in the outdoors#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_OUTDOORS)
end)

mq.event('Recover1', "You haven't recovered yet#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_RECOVER)
end)

mq.event('Recover2', "Spell recovery time not yet met#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_RECOVER)
end)

mq.event('Resist1', "Your target resisted the #1# spell#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_RESISTED)
end)

mq.event('Resist2', "#2# resisted your #1#!", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_RESISTED)
end)

mq.event('Standing1', "You must be standing to cast a spell#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_STANDING)
end)

mq.event('Stunned1', "You can't cast spells while stunned#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_STUNNED)
end)

mq.event('Stunned2', "You are stunned#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_STUNNED)
end)

mq.event('TakeHold1', "Your #*# did not take hold on #*#. (Blocked by #*#.)", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_TAKEHOLD)
end)

mq.event('TakeHold2', "Your spell did not take hold#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_TAKEHOLD)
end)

mq.event('TakeHold3', "Your spell would not have taken hold#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_TAKEHOLD)
end)

mq.event('TakeHold4', "Your spell is too powerfull for your intended target#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_TAKEHOLD)
end)

mq.event('CanNotSee1', "You cannot see your target#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_CANNOTSEE)
end)

mq.event('Components1', "You are missing some required components#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_COMPONENTS)
end)

mq.event('Components2', "Your ability to use this item has been disabled because you do not have at least a gold membership#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_COMPONENTS)
end)

mq.event('FDFail1', "#1# has fallen to the ground.#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_FDFAIL)
end)

mq.event('Immune1', "Your target has no mana to affect#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
end)

mq.event('Immune2', "Your target is immune to changes in its attack speed#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    Modules:ExecModule("Class", "AddImmuneTarget", "Slow", Globals.AutoTargetID or 0)
end)

mq.event('Immune3', "Your target is immune to changes in its run speed#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    Modules:ExecModule("Class", "AddImmuneTarget", "Snare", Globals.AutoTargetID or 0)
end)

mq.event('Immune4', "Your target is immune to snare spells#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    Modules:ExecModule("Class", "AddImmuneTarget", "Snare", Globals.AutoTargetID or 0)
end)

mq.event('Immune5', "Your target is immune to the stun portion of this effect#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    Modules:ExecModule("Class", "AddImmuneTarget", "Stun", Globals.AutoTargetID or 0)
end)

mq.event('Immune6', "Your target looks unaffected#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
end)

mq.event('ImmuneMez', "Your target cannot be mesmerized#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    local target = mq.TLO.Target
    Modules:ExecModule("Mez", "AddImmuneTarget", target.ID(),
        { id = target.ID(), name = target.CleanName(), lvl = target.Level(), body = target.Body(), reason = "IMMUNE", })
end)

mq.event('ImmuneCharm', "Your target cannot be charmed#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    local target = mq.TLO.Target
    Modules:ExecModule("Charm", "AddImmuneTarget", target.ID(),
        { id = target.ID(), name = target.CleanName(), lvl = target.Level(), body = target.Body(), reason = "IMMUNE", })
end)

mq.event('ImmuneCharm2', "This NPC cannot be charmed#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    local target = mq.TLO.Target
    Modules:ExecModule("Charm", "AddImmuneTarget", target.ID(),
        { id = target.ID(), name = target.CleanName(), lvl = target.Level(), body = target.Body(), reason = "IMMUNE", })
end)

mq.event('LvlHighCharm', "Your target is too high of a level for your charm spell.#*#", function()
    Casting.SetLastCastResult(Globals.Constants.CastResults.CAST_IMMUNE)
    Logger.log_debug("\awNOTICE:\ax Target is to \aoHigh Level\ax to Charm with this spell!")
    local target = mq.TLO.Target

    Modules:ExecModule("Charm", "CharmLvlToHigh", target.Level())
    Modules:ExecModule("Charm", "AddImmuneTarget", target.ID(),
        { id = target.ID(), name = target.CleanName(), lvl = target.Level(), body = target.Body(), reason = "HIGH_LVL", })
end)
-- [ END CAST RESULT HANDLERS ] --

-- [ MEZ HANDLERS ] --

mq.event('MezBroken', "#1# has been awakened by #2#.", function(_, mobName, breakerName)
    Modules:ExecModule("Mez", "HandleMezBroke", mobName, breakerName)
end)

-- [ END MEZ HANDLERS ] --

-- [ SUMMONED HANDLERS ] --

mq.event('Summoned', "You have been summoned!", function(_)
    if Config:GetSetting('DoAutoEngage') and not Config:GetSetting('DoMelee') and not Core.IAmMA() and Config:GetSetting('ReturnToCamp') then
        Comms.PrintGroupMessage("%s was just summoned -- returning to camp!", Globals.CurLoadedChar)
        Modules:ExecModule("Movement", "DoAutoCampCheck", true)
    end
end)

-- [ END SUMMONED HANDLERS ] --

-- [ GAME EVENT HANDLERS ] --

mq.event('Camping', "It will take you about #1# seconds to prepare your camp.", function(_, seconds)
    Globals.PauseMain = true
end)

-- [ END GAME EVENT HANDLERS ] --

-- [ FD EVENT HANDLERS ] --

mq.event('FallToGround', "#1# has fallen to the ground#*#", function(_, who)
    if who == mq.TLO.Me.DisplayName() and Config:GetSetting('StandFailedFD') then
        Core.DoCmd("/stand")
    end
end)

-- [ END FD EVENT HANDLERS ] --

-- [ CLASS CHANGE EVENT HANDLERS ] --
mq.event('PersonaEquipLoad', "You successfully loaded your #*# equipment set.", function()
    if Globals.CurLoadedClass ~= mq.TLO.Me.Class.ShortName() then
        ClassLoader.changeLoadedClass()
    end
end)
-- [ END CLASS CHANGE EVENT HANDLERS ] --

-- [ EMU REZ HANDLERS] --
mq.event('CorpseConned', "This corpse will decay#*#.", function()
    if Core.OnEMU and Modules:ExecModule("Class", "IsRezing") then
        Logger.log_verbose("Corpse /con message received for rez checks.")
        Globals.CorpseConned = true
    end
end)

mq.event('AlreadyRezzed', "This corpse has already accepted a resurrection.", function()
    if Core.OnEMU and Modules:ExecModule("Class", "IsRezing") then
        Logger.log_verbose("Already rezzed corpse detected, we will ignore this corpse for now.")
        table.insert(Globals.RezzedCorpses, mq.TLO.Target.ID()) --target.id returns 0 if no target
    end
end)
-- [ END EMU REZ HANDLERS] --

-- [ Character Flag Events ] --
mq.event('Flagged1', "You receive a character flag!", function()
    Comms.HandleAnnounce(Comms.FormatChatEvent("Character Flag", mq.TLO.Target.CleanName() or "", mq.TLO.Me.DisplayName()),
        Config:GetSetting('CharacterFlagAnnounceGroup'),
        Config:GetSetting('CharacterFlagAnnounce'),
        Config:GetSetting('AnnounceToRaidIfInRaid'))
end)
-- [ END Character Flag Events] --

mq.event('NoLevZone', "You have entered an area where levitation effects do not function.", function()
    Config.TempSettings.NoLevZone = true
end)
