local mq                     = require('mq')
local Config                 = require('utils.config')
local Core                   = require("utils.core")
local Events                 = require('utils.events')
local Globals                = require("utils.globals")
local Logger                 = require("utils.logger")
local Modules                = require("utils.modules")

local Movement               = { _version = '1.0', _name = "Movement", _author = 'Derple', }
Movement.__index             = Movement
Movement.LastDoStick         = 0
Movement.LastDoStickCmd      = ""
Movement.LastReposition      = 0
Movement.LastDoNav           = 0
Movement.LastDoNavCmd        = ""
Movement.LastDoNavTracer     = ""
Movement.LastMoveTo          = 0
Movement.LastMoveToCmd       = ""
Movement.LastMove            = {}
Movement.LastMove.X          = mq.TLO.Me.X()
Movement.LastMove.Y          = mq.TLO.Me.Y()
Movement.LastMove.Z          = mq.TLO.Me.Z()
Movement.LastMove.Heading    = mq.TLO.Me.Heading.Degrees()
Movement.LastMove.Sitting    = mq.TLO.Me.Sitting()
Movement.LastMove.TimeAtMove = Globals.GetTimeSeconds()
Movement.MoveToActive        = false

--- Sticks the player to targetId using config-driven stick settings,
--- rate-limited to once per second to avoid spamming.
---@param targetId number The spawn ID of the target to stick to.
function Movement:DoStick(targetId)
    if Globals.GetTimeSeconds() - self.LastDoStick < 1 then
        Logger.log_debug(
            "\ayIgnoring DoStick because we just stuck a second ago - let's give it some time.")
        return
    end

    if Config:GetSetting('StickHow'):len() > 0 then
        self:DoStickCmd("%s", Config:GetSetting('StickHow'))
    else
        if Core.IsTanking() then
            self:DoStickCmd("10 id %d %s uw", targetId, Config:GetSetting('MovebackWhenTank') and "moveback" or "")
        else
            local stickDist = (mq.TLO.Spawn(targetId).Height() or 5) > 15 and 20 or 10
            self:DoStickCmd("%d id %d behindonce moveback uw", stickDist, targetId)
        end
    end
end

function Movement:MoveToLoc(locX, locY)
    local cmd = string.format("loc %d %d|on", locX, locY)
    Core.DoCmd("/squelch /moveto " .. cmd)
    self.LastMoveTo = Globals.GetTimeSeconds()
    self.LastMoveToCmd = cmd
    self.MoveToActive = true
end

function Movement:MoveToSpawnId(spawnId, distance)
    local cmd = string.format("id %d uw mdist %d", spawnId, distance)
    Core.DoCmd("/squelch /moveto " .. cmd)
    self.LastMoveTo = Globals.GetTimeSeconds()
    self.LastMoveToCmd = cmd
    self.MoveToActive = true
end

function Movement:StopMoveTo()
    if self.MoveToActive then
        Core.DoCmd("/squelch /moveto stop")
        self.LastMoveTo = Globals.GetTimeSeconds()
        self.LastMoveToCmd = "stop"
        self.MoveToActive = false
    end
end

--- Issues a /stick command with formatted params if DoAutoStick is enabled.
---@param params string Format string for the stick parameters.
---@param ... any Arguments for the format string.
function Movement:DoStickCmd(params, ...)
    if not Config:GetSetting('DoAutoStick') then return end
    local formatted = params
    if ... ~= nil then formatted = string.format(params, ...) end
    Core.DoCmd("/stick %s", formatted)
    self:SetLastStickTimer(Globals.GetTimeSeconds())
    self.LastDoStickCmd = formatted
end

--- Issues a /nav command, skipping duplicates that are already active.
---@param squelch boolean Prepend /squelch to suppress MQ output.
---@param params string Format string for the nav parameters.
---@param ... any Arguments for the format string.
function Movement:DoNav(squelch, params, ...)
    local formatted = params
    if ... ~= nil then formatted = string.format(params, ...) end

    if mq.TLO.Navigation.Active() and formatted == self.LastDoNavCmd then
        Logger.log_verbose("\ayIgnoring DoNav (%s) because the last nav command is the same - let's not spam it.", formatted)
        return
    end

    local callerTracer = Logger.getCallStack(true) or ""

    Core.DoCmd("%s/nav %s", squelch and "/squelch " or "", formatted)
    self.LastDoNav = Globals.GetTimeSeconds()
    self.LastDoNavTracer = callerTracer
    self.LastDoNavCmd = formatted
    self:StoreLastMove()
end

--- Returns the last /nav command string that was issued.
---@return string, string The last nav command, or "" if none and the last nav call's caller info for debugging.
function Movement:GetLastNavCmd()
    return self.LastDoNavCmd, self.LastDoNavTracer
end

--- Returns the last /stick command string that was issued.
---@return string The last stick command, or "" if none.
function Movement:GetLastStickCmd()
    return self.LastDoStickCmd
end

--- Resets the stick timer so the next DoStick call is not rate-limited.
function Movement:ClearLastStickTimer()
    self.LastDoStick = 0
end

--- Returns the timestamp (seconds) when the last stick command was sent.
---@return number Seconds since MQ epoch of the last stick.
function Movement:GetLastStickTimer()
    return self.LastDoStick
end

--- Records t as the timestamp of the most recent stick command.
---@param t number Timestamp in seconds (from Globals.GetTimeSeconds).
function Movement:SetLastStickTimer(t)
    self.LastDoStick = t
end

--- Returns elapsed seconds since the last stick command as a string,
--- or "N/A" if no stick has been issued yet.
---@return string Elapsed time string like "5s", or "N/A".
function Movement:GetTimeSinceLastStick()
    if self.LastDoStickCmd == "" then
        return "N/A"
    end

    return string.format("%ds", Globals.GetTimeSeconds() - self.LastDoStick)
end

--- Returns elapsed seconds since the last nav command as a string,
--- or "N/A" if no nav has been issued yet.
---@return string Elapsed time string like "5s", or "N/A".
function Movement:GetTimeSinceLastNav()
    if self.LastDoNavCmd == "" then
        return "N/A"
    end

    return string.format("%ds", Globals.GetTimeSeconds() - self.LastDoNav)
end

--- Returns elapsed seconds since the last nav command as a number,
--- or 0 if no nav has been issued.
---@return number Seconds elapsed since the last nav command.
function Movement:GetSecondsSinceLastNav()
    if self.LastDoNavCmd == "" then
        return 0
    end

    return Globals.GetTimeSeconds() - self.LastDoNav
end

--- Navigates to the combat target then sticks; bNoWait issues the nav and returns immediately instead of waiting for arrival.
---@param targetId number Spawn ID of the combat target.
---@param distance number Desired distance to maintain from the target.
---@param bDontStick boolean If true, skips the final DoStick call.
---@param bCalledFromInsideEvent boolean? If true, skips mq.doevents during nav.
---@param bNoWait boolean? If true, issues the nav and returns immediately (skips the wait loop and trailing stick).
function Movement:NavInCombat(targetId, distance, bDontStick, bCalledFromInsideEvent, bNoWait)
    if bCalledFromInsideEvent == nil then bCalledFromInsideEvent = false end

    if not Config:GetSetting('DoAutoEngage') then return end
    if not Config:GetSetting('DoAutoNav') then return end

    if mq.TLO.Stick.Active() then
        self:DoStickCmd("off")
    end

    if mq.TLO.Navigation.PathExists("id " .. tostring(targetId) .. " distance " .. tostring(distance))() then
        Globals.CombatNavTargetId = targetId
        Movement:DoNav(false, "id %d distance=%d log=off lineofsight=on", targetId, distance or 15)
        while not bNoWait and mq.TLO.Navigation.Active() and mq.TLO.Navigation.Velocity() > 0 do
            mq.delay(100)
            if not bCalledFromInsideEvent then
                mq.doevents()
                Events.DoEvents()
            end
        end
    else
        Movement:MoveToSpawnId(targetId, distance)

        while not bNoWait and mq.TLO.MoveTo.Moving() and not mq.TLO.MoveUtils.Stuck() do
            mq.delay(100)
            if not bCalledFromInsideEvent then
                mq.doevents()
                Events.DoEvents()
            end
        end
    end

    if not bDontStick and not bNoWait then
        self:DoStick(targetId)
    end
end

--- Finds a navigable, line-of-sight point radius units from target and
--- navigates there, used for circling mobs that block direct approach.
---@param target MQSpawn The spawn to circle around.
---@param radius number Distance from the target to navigate to.
---@return boolean True if a valid circling loc was found and nav started.
function Movement:NavAroundCircle(target, radius)
    if not Config:GetSetting('DoAutoEngage') then return false end
    if not target or not target() and not target.Dead() then return false end
    if not mq.TLO.Navigation.MeshLoaded() then return false end

    local spawn_x = target.X()
    local spawn_y = target.Y()
    local spawn_z = target.Z()

    local tgt_x, tgt_y
    -- We need to get the spawn's heading to _us_ based on our heading to the spawn
    -- to nav a circle around it. This is done by inverting the coordinates. E.g.,
    -- If our heading to the mob is 90 degrees CCW, their heading to us is 270 degrees CCW.

    local tmp_degrees = target.HeadingTo.DegreesCCW() - 180
    if tmp_degrees < 0 then tmp_degrees = 360 + tmp_degrees end

    -- Loop until we find an x,y loc ${radius} away from the mob,
    -- that we can navigate to, and is in LoS

    -- Skip our current angle (start at +10 deg): repositioning to where we already stand can't fix a
    -- blocked shot, and re-picking it would loop when the LoS TLO and the game's LoS disagree.
    for steps = 1, 35 do
        -- EQ's x coordinates have an opposite number line. Positive x values are to the left of 0,
        -- negative values are to the right of 0, so we need to - our radius.
        -- EQ's unit circle starts 0 degrees at the top of the unit circle instead of the right, so
        -- the below still finds coordinates rotated counter-clockwise 90 degrees.

        local rad = math.rad(tmp_degrees + steps * 10)
        tgt_x = spawn_x + (-1 * radius * math.cos(rad))
        tgt_y = spawn_y + (radius * math.sin(rad))

        Logger.log_debug("\aw%d\ax tmp_degrees \aw%d\ax tgt_x \aw%0.2f\ax tgt_y \aw%02.f\ax", steps, tmp_degrees,
            tgt_x, tgt_y)
        -- First check that we can navigate to our new target
        if mq.TLO.Navigation.PathExists(string.format("locyxz %0.2f %0.2f %0.2f", tgt_y, tgt_x, spawn_z))() then
            -- Then check if our new spots has line of sight to our target.
            if mq.TLO.LineOfSight(string.format("%0.2f,%0.2f,%0.2f:%0.2f,%0.2f,%0.2f", tgt_y, tgt_x, spawn_z, spawn_y, spawn_x, spawn_z))() then
                -- Make sure it's a valid loc...
                if mq.TLO.EverQuest.ValidLoc(string.format("%0.2f %0.2f %0.2f", tgt_x, tgt_y, spawn_z))() then
                    Logger.log_debug(" \ag--> Found Valid Circling Loc: %0.2f %0.2f %0.2f", tgt_x, tgt_y, spawn_z)
                    Movement:DoNav(false, "locyxz %0.2f %0.2f %0.2f", tgt_y, tgt_x, spawn_z)
                    mq.delay("2s", function() return mq.TLO.Navigation.Active() end)
                    mq.delay("5s", function() return not mq.TLO.Navigation.Active() end)
                    Core.DoCmd("/squelch /face fast")
                    return true
                else
                    Logger.log_debug(" \ar--> Invalid Loc: %0.2f %0.2f %0.2f", tgt_x, tgt_y, spawn_z)
                end
            end
        end
    end

    return false
end

-- Reposition (rear-mob handling for tanks)

--- Returns +1 if the stray sits on the player's right side, -1 if left, 0 if straddled (engaged-stray-me collinear).
---@param meX number
---@param meY number
---@param engagedX number
---@param engagedY number
---@param strayX number
---@param strayY number
---@return integer
function Movement:PickStraySide(meX, meY, engagedX, engagedY, strayX, strayY)
    -- Standard 2D cross of (engaged-me) x (stray-me); in EQ coords (positive x = left of 0, per :241),
    -- cross > 0 maps to stray physically on the player's right, cross < 0 = left.
    local cross = (engagedX - meX) * (strayY - meY) - (engagedY - meY) * (strayX - meX)
    if cross > 0 then return 1 end
    if cross < 0 then return -1 end
    return 0
end

--- Returns world (X, Y) for a destination at sideAngleDeg off the player's current facing, length units away.
---@param meX number
---@param meY number
---@param headingDegCCW number Current heading (Me.Heading.DegreesCCW).
---@param sideAngleDeg number Lateral angle off facing (0-90).
---@param side integer +1 right side, -1 left side (per PickStraySide).
---@param length number Step distance in units.
---@return number, number
function Movement:LateralDestFromFacing(meX, meY, headingDegCCW, sideAngleDeg, side, length)
    local facingRad = math.rad(headingDegCCW or 0)
    local fx, fy = math.sin(facingRad), math.cos(facingRad)
    local rotRad = math.rad((side or 0) * sideAngleDeg)
    local cr, sr = math.cos(rotRad), math.sin(rotRad)
    local dx = fx * cr - fy * sr
    local dy = fx * sr + fy * cr
    return meX + length * dx, meY + length * dy
end

--- Returns the worst (nearest) XTarget that is behind the player and meets the per-mob aggro/animation guards, or nil.
---@return MQSpawn? worstBehind
function Movement:DetectMobBehind()
    local me = mq.TLO.Me
    local myHeading = me.Heading.DegreesCCW() or 0
    local xtCount = me.XTarget() or 0
    local nearest = nil
    local nearestDistSq = math.huge

    for i = 1, xtCount do
        local xtSpawn = me.XTarget(i)
        if xtSpawn and (xtSpawn.ID() or 0) > 0 and not xtSpawn.Dead() and not xtSpawn.Fleeing()
            and (math.ceil(xtSpawn.PctHPs() or 0)) > 0
            and (xtSpawn.Aggressive() or (xtSpawn.TargetType() or ""):lower() == "auto hater" or xtSpawn.ID() == Globals.ForceTargetID)
            and Globals.Constants.RGNotMezzedAnims:contains(xtSpawn.Animation())
            and (xtSpawn.PctAggro() or 0) >= 100 then
            local theirHeadingTo = xtSpawn.HeadingTo.DegreesCCW() or 0
            local diff = math.abs(myHeading - theirHeadingTo) % 360
            if diff > 180 then diff = 360 - diff end
            if diff > 90 then
                local maxRange = xtSpawn.MaxRangeTo() or 15
                local distance = xtSpawn.Distance3D() or 999
                if distance <= maxRange then
                    Logger.log_debug("\arXT(%s) is behind us! \awMyHeading(\am%d\aw) BearingToMob(\am%d\aw) Diff(\am%d\aw) Distance(\am%d\aw)",
                        xtSpawn.DisplayName() or "", myHeading, theirHeadingTo, diff, distance)
                    local distSq = distance * distance
                    if distSq < nearestDistSq then
                        nearest = xtSpawn
                        nearestDistSq = distSq
                    end
                end
            end
        end
    end

    return nearest
end

--- True when reposition guards (tanking, auto-nav/stick, not in chase/pull/back-off, rate-limit) all pass.
---@return boolean
function Movement:CanReposition()
    if not Core.IsTanking() then
        Logger.log_debug("\ayReposition skipped: not tanking.")
        return false
    end
    if Config:GetSetting('ManualMode') then
        Logger.log_debug("\ayReposition skipped: Manual Mode on.")
        return false
    end
    if not Config:GetSetting('DoAutoNav') then
        Logger.log_debug("\ayReposition skipped: DoAutoNav off.")
        return false
    end
    if not Config:GetSetting('DoAutoStick') then
        Logger.log_debug("\ayReposition skipped: DoAutoStick off.")
        return false
    end
    if Config:GetSetting('ChaseOn') then
        Logger.log_debug("\ayReposition skipped: ChaseOn enabled.")
        return false
    end
    if Globals.BackOffFlag then
        Logger.log_debug("\ayReposition skipped: BackOffFlag set.")
        return false
    end
    if Modules:ExecModule("Pull", "IsPullState", "PULL_PULLING") or Modules:ExecModule("Pull", "IsPullState", "PULL_RETURN_TO_CAMP") then
        Logger.log_debug("\ayReposition skipped: in pull state.")
        return false
    end
    local sinceReposition = Globals.GetTimeSeconds() - self.LastReposition
    if sinceReposition < 0.5 then
        Logger.log_debug("\ayReposition skipped: rate-limit (%0.2fs since last reposition).", sinceReposition)
        return false
    end
    return true
end

--- TankReposition: lateral nav around the engaged mob to bring rear adds into the front arc; backslide fallback if lateral is blocked.
function Movement:TankReposition()
    if not self:CanReposition() then return end

    local autoTargetId = Globals.AutoTargetID or 0
    if autoTargetId <= 0 then return end
    local engaged = mq.TLO.Spawn("id " .. autoTargetId)
    if not engaged() or engaged.Dead() then return end
    if not mq.TLO.Navigation.MeshLoaded() then return end

    local engagedBearing = engaged.HeadingTo.DegreesCCW() or 0
    local myHeading = mq.TLO.Me.Heading.DegreesCCW() or 0
    local headingDiff = math.abs(myHeading - engagedBearing) % 360
    if headingDiff > 180 then headingDiff = 360 - headingDiff end
    if headingDiff > 30 then
        Logger.log_debug("\ayReposition: /face fast id %d (heading diff %d).", autoTargetId, headingDiff)
        Core.DoCmd("/squelch /face fast id %d", autoTargetId)
        -- The /face may have shifted what's behind us; if rotation alone solved it, skip the maneuver entirely.
        local stillBehind = self:DetectMobBehind()
        if not stillBehind or (stillBehind.ID() or 0) == 0 then
            Logger.log_debug("\ayReposition: no mob behind after heading correction, no action.")
            return
        end
    end

    Logger.log_debug("\arReposition: starting series.")
    self:DoStickCmd("off")
    Globals.RepositioningActive = true
    Globals.RepositioningActiveSince = mq.gettime()

    local seriesStartMs = mq.gettime()
    local stepCount = 0

    while stepCount < 4 and (mq.gettime() - seriesStartMs) < 2000 do
        if not engaged() or engaged.Dead() then break end

        local stray = self:DetectMobBehind()
        if not stray or (stray.ID() or 0) == 0 then
            Logger.log_debug("\agReposition: series complete (%d steps).", stepCount)
            break
        end

        local me = mq.TLO.Me
        local meX = me.X() or 0
        local meY = me.Y() or 0
        local meZ = me.Z() or 0
        local headingCCW = me.Heading.DegreesCCW() or 0
        local engX = engaged.X() or 0
        local engY = engaged.Y() or 0
        local maxRange = engaged.MaxRangeTo() or 15
        local distNow = engaged.Distance3D() or maxRange
        local strX = stray.X() or 0
        local strY = stray.Y() or 0

        local strayLocation = self:PickStraySide(meX, meY, engX, engY, strX, strY)
        if strayLocation == 0 then
            Logger.log_debug("\ayReposition: straddled rear mob, giving up series.")
            break
        end
        -- Move opposite the stray's side; moving toward it would keep us inside the diameter circle where the stray stays behind us when we re-face engaged.
        local moveDir = -strayLocation

        local strayHeadingCCW = stray.HeadingTo.DegreesCCW() or 0
        local strayDiff = math.abs(headingCCW - strayHeadingCCW) % 360
        if strayDiff > 180 then strayDiff = 360 - strayDiff end
        -- Step just enough to rotate the stray into front-arc; overshooting wastes melee distance, undershooting forces extra iterations within the series budget.
        local L_ideal = math.max(2, (strayDiff - 80) * 0.01807 * distNow)
        local stepLength = math.min(L_ideal, maxRange - 1)

        local navIssued = false

        -- Ideal 75° first, then ±10° on the same side; switching sides would defeat the diameter-circle pick and undo the move.
        for _, lateralAngle in ipairs({ 75, 85, 65, }) do
            local destX, destY = self:LateralDestFromFacing(meX, meY, headingCCW, lateralAngle, moveDir, stepLength)
            local distToEngaged = math.sqrt((destX - engX) ^ 2 + (destY - engY) ^ 2)
            if distToEngaged > maxRange then
                local scale = (maxRange - 1) / distToEngaged
                destX = engX + (destX - engX) * scale
                destY = engY + (destY - engY) * scale
            end
            local stepDist = math.sqrt((destX - meX) ^ 2 + (destY - meY) ^ 2)
            if stepDist >= 2
                and mq.TLO.EverQuest.ValidLoc(string.format("%0.2f %0.2f %0.2f", destX, destY, meZ))()
                and mq.TLO.Navigation.PathExists(string.format("locyxz %0.2f %0.2f %0.2f", destY, destX, meZ))()
                and mq.TLO.LineOfSight(string.format("%0.2f,%0.2f,%0.2f:%0.2f,%0.2f,%0.2f", destY, destX, meZ, engY, engX, meZ))() then
                Logger.log_debug("\arReposition step %d: lateral %d° dir=%d L=%.1f -> %.1f %.1f", stepCount + 1, lateralAngle, moveDir, stepLength, destX, destY)
                self:DoNav(false, "locyxz %0.2f %0.2f %0.2f facing=backward log=off", destY, destX, meZ)
                navIssued = true
                break
            end
        end

        if not navIssued then
            local room = maxRange - distNow
            if room >= 2 then
                local facingRad = math.rad(headingCCW)
                local fx, fy = math.sin(facingRad), math.cos(facingRad)
                -- Pull back only as far as needed to flip the stray into front-arc; backsliding farther than necessary risks losing melee on the engaged mob.
                local rearOffset = -((strX - meX) * fx + (strY - meY) * fy)
                local slide = math.min(math.max(2, rearOffset + 2), room + maxRange * 0.5)
                local backX = meX - slide * fx
                local backY = meY - slide * fy
                if mq.TLO.EverQuest.ValidLoc(string.format("%0.2f %0.2f %0.2f", backX, backY, meZ))()
                    and mq.TLO.Navigation.PathExists(string.format("locyxz %0.2f %0.2f %0.2f", backY, backX, meZ))() then
                    Logger.log_debug("\arReposition step %d: backslide fallback %0.1fu (rear-offset %0.1f, lateral blocked).", stepCount + 1, slide, rearOffset)
                    self:DoNav(false, "locyxz %0.2f %0.2f %0.2f facing=backward log=off", backY, backX, meZ)
                    navIssued = true
                end
            end
        end

        if navIssued then
            local stepDeadline = mq.gettime() + 600
            while mq.TLO.Navigation.Active() and (mq.TLO.Navigation.Velocity() or 0) > 0
                and mq.gettime() < stepDeadline and (mq.gettime() - seriesStartMs) < 2000 do
                mq.delay(50)
                mq.doevents()
                Events.DoEvents()
            end
            Core.DoCmd("/squelch /face fast id %d", autoTargetId)
            stepCount = stepCount + 1
        else
            Logger.log_debug("\ayReposition step %d: no viable nav (lateral + backslide both blocked), ending series.", stepCount + 1)
            break
        end
    end

    if (stepCount >= 4 or (mq.gettime() - seriesStartMs) >= 2000) then
        local finalCheck = self:DetectMobBehind()
        if finalCheck and (finalCheck.ID() or 0) > 0 then
            Logger.log_debug("\ayReposition: budget hit after %d steps (%dms) with mob still behind.", stepCount, mq.gettime() - seriesStartMs)
        end
    end

    Globals.RepositioningActive = false
    self.LastReposition = Globals.GetTimeSeconds()
end

--- Updates the MQ map filter pull and camp radii based on current
--- config settings for pull mode and camp return.
function Movement.UpdateMapRadii()
    if Config:GetSetting('DoPull') or Config:GetSetting('ReturnToCamp') then
        if Modules:ExecModule("Pull", "IsPullMode", "Hunt") then
            Core.DoCmd("/squelch /mapfilter pullradius %d", Config:GetSetting('PullRadiusHunt'))
        elseif Config:GetSetting('ReturnToCamp') then
            Core.DoCmd("/squelch /mapfilter pullradius %d", Config:GetSetting('PullRadius'))
        end
        Core.DoCmd("/squelch /mapfilter campradius %d", Config:GetSetting('AutoCampRadius'))
    else
        Core.DoCmd("/squelch /mapfilter campradius off")
        Core.DoCmd("/squelch /mapfilter pullradius off")
    end
end

--- Returns seconds since the last "move" event, treating combat state
--- as movement so buff checks only fire in true downtime.
---@return number Seconds since the last recorded movement or combat event.
function Movement:GetTimeSinceLastMove()
    return Globals.GetTimeSeconds() - self.LastMove.TimeAtMove
end

--- Returns seconds since the last actual position change, ignoring
--- combat state - useful for detecting true standing still.
---@return number Seconds since coordinates last changed by more than 1 unit.
function Movement:GetTimeSinceLastPositionChange()
    return Globals.GetTimeSeconds() - (self.LastMove.TimeAtPositionChange or 0)
end

--- Resets the position-change clock to now, so stuck detection starts a
--- fresh window. Used to drop pre-nav idle time at the start of a nav
--- episode and as a cooldown after an unstick attempt.
function Movement:ResetPositionChangeTimer()
    self.LastMove.TimeAtPositionChange = Globals.GetTimeSeconds()
end

--- Deterministically pauses or resumes navigation, no-op if already in the
--- desired state. /nav pause is a toggle, so we check state first to avoid
--- flipping the wrong way.
---@param shouldPause boolean True to pause nav, false to resume.
function Movement:SetNavPaused(shouldPause)
    if mq.TLO.Navigation.Paused() == shouldPause then return end
    Core.DoCmd("/squelch /nav pause")
    mq.delay(200, function() return mq.TLO.Navigation.Paused() == shouldPause end)
end

--- Snapshots current position, heading, sitting state, and timestamps
--- if any coordinate or heading changed by more than 1 unit, or if in combat.
function Movement:StoreLastMove()
    local me = mq.TLO.Me

    -- only look at actual movement.
    if math.abs(self.LastMove.X - me.X()) > 1 or
        math.abs(self.LastMove.Y - me.Y()) > 1 or
        math.abs(self.LastMove.Z - me.Z()) > 1 then
        self.LastMove.TimeAtPositionChange = Globals.GetTimeSeconds()
    end

    if math.abs(self.LastMove.X - me.X()) > 1 or
        math.abs(self.LastMove.Y - me.Y()) > 1 or
        math.abs(self.LastMove.Z - me.Z()) > 1 or
        math.abs(self.LastMove.Heading - me.Heading.Degrees()) > 1 or
        me.Combat() or
        (me.CombatState() or ""):lower() == "combat" or
        me.Sitting() ~= self.LastMove.Sitting then
        self.LastMove = self.LastMove or {}
        self.LastMove.X = me.X()
        self.LastMove.Y = me.Y()
        self.LastMove.Z = me.Z()
        self.LastMove.Heading = me.Heading.Degrees()
        self.LastMove.Sitting = me.Sitting()
        self.LastMove.TimeAtMove = Globals.GetTimeSeconds()
    end
end

return Movement
