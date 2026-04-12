local mq       = require('mq')
local ImGui    = require('ImGui')
local ImAnim   = require('ImAnim')
local ImagesUI = require('ui.images')
local Config   = require('utils.config')
local Globals  = require('utils.globals')
local Ui       = require("utils.ui")

-- seed the rng
math.randomseed(mq.gettime())

local LoaderUI           = { _version = '1.0', _name = "LoaderUI", _author = 'Derple', }
LoaderUI.__index         = LoaderUI
LoaderUI.Initialized     = false

-- Shared constants
LoaderUI.imgEndSize      = 60
LoaderUI.settleDuration  = 0.7

-- Lissajous animation constants
LoaderUI.imgStartSize    = 220
LoaderUI.flyDuration     = 1.0

-- Drop animation constants
LoaderUI.dropDuration    = 1.5

-- Sweep animation constants
LoaderUI.sweepDuration   = 1.4

-- Animation state
-- "lissajous" | "drop" | "sweep" (chosen randomly on init)
local animRoll           = math.floor(math.random() * 100) % 3
LoaderUI.animType        = animRoll == 0 and "lissajous" or animRoll == 1 and "drop" or "sweep"
-- lissajous: "flying" | "settling" | "done" | "donedone"
-- drop:      "dropping" | "done" | "donedone"
-- sweep:     "sweeping" | "done" | "donedone"
local stateMap           = { lissajous = "flying", drop = "dropping", sweep = "sweeping", }
LoaderUI.animState       = stateMap[LoaderUI.animType]

LoaderUI.animStartTime   = nil
LoaderUI.flyPos          = { x = 0, y = 0, }
LoaderUI.settleStartTime = nil
LoaderUI.dropBigSize     = 0

-- ImAnim IDs
LoaderUI.animId          = ImHashStr("loader_anim")
LoaderUI.chSize          = ImHashStr("loader_size")
LoaderUI.chX             = ImHashStr("loader_x")
LoaderUI.chY             = ImHashStr("loader_y")
LoaderUI.chDropY         = ImHashStr("loader_drop_y")
LoaderUI.chDropSize      = ImHashStr("loader_drop_size")
LoaderUI.chSweepX        = ImHashStr("loader_sweep_x")
LoaderUI.chSweepY        = ImHashStr("loader_sweep_y")
LoaderUI.chSweepSize     = ImHashStr("loader_sweep_size")
LoaderUI.chSweepAngle    = ImHashStr("loader_sweep_angle")

-- `Renders the lissajous fly-then-settle animation`
--- @param dl ImDrawList foreground draw list`
--- @param display ImVec2 display size`
--- @param finalX number target screen X of the image top-left`
--- @param finalY number target screen Y of the image top-left`
--- @param dt number delta time`
--- @return boolean true while animation is still running`
local function renderLissajous(self, dl, display, finalX, finalY, dt)
    if self.animState == "flying" then
        if not self.animStartTime then self.animStartTime = Globals.GetTimeSeconds() end
        local cx      = display.x / 2
        local cy      = display.y / 2

        local offset  = ImAnim.OscillateVec2(
            self.animId,
            ImVec2(cx * 0.65, cy * 0.55),
            ImVec2(0.477, 0.318),
            IamWaveType.Sine,
            ImVec2(math.pi / 4, 0),
            dt)
        local ix      = cx + offset.x
        local iy      = cy + offset.y
        self.flyPos.x = ix
        self.flyPos.y = iy

        local half    = self.imgStartSize / 2
        dl:AddImage(ImagesUI.imgDisplayed:GetTextureID(),
            ImVec2(ix - half, iy - half),
            ImVec2(ix + half, iy + half))

        if Globals.GetTimeSeconds() - self.animStartTime >= self.flyDuration then
            self.animState       = "settling"
            self.settleStartTime = Globals.GetTimeSeconds()
        end
        return true
    elseif self.animState == "settling" then
        local targetCX = finalX + self.imgEndSize / 2
        local targetCY = finalY + self.imgEndSize / 2

        local size     = ImAnim.TweenFloat(self.animId, self.chSize, self.imgEndSize, self.settleDuration,
            ImAnim.EasePreset(IamEaseType.InQuart), IamPolicy.Crossfade, dt, self.imgStartSize)
        local cx       = ImAnim.TweenFloat(self.animId, self.chX, targetCX, self.settleDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, self.flyPos.x)
        local cy       = ImAnim.TweenFloat(self.animId, self.chY, targetCY, self.settleDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, self.flyPos.y)
        local half     = size / 2

        dl:AddImage(ImagesUI.imgDisplayed:GetTextureID(),
            ImVec2(cx - half, cy - half),
            ImVec2(cx + half, cy + half))

        if Globals.GetTimeSeconds() - self.settleStartTime >= self.settleDuration then
            self.animState     = "done"
            self.animEndedTime = Globals.GetTimeMS()
        end
        return true
    end

    return false
end

-- `Renders the big-drop-and-bounce animation`
--- @param dl ImDrawList foreground draw list`
--- @param display ImVec2 display size`
--- @param finalX number target screen X of the image top-left`
--- @param finalY number target screen Y of the image top-left`
--- @param dt number delta time`
--- @return boolean true while animation is still running`
local function renderDrop(self, dl, display, finalX, finalY, dt)
    if self.animState == "dropping" then
        if self.dropBigSize == 0 then
            self.dropBigSize   = math.min(display.x, display.y) * 0.65
            self.animStartTime = Globals.GetTimeSeconds()
        end

        local targetCX = finalX + self.imgEndSize / 2
        local targetCY = finalY + self.imgEndSize / 2
        local startCY  = display.y / 2 - self.dropBigSize / 2

        local size     = ImAnim.TweenFloat(self.animId, self.chDropSize, self.imgEndSize, self.dropDuration,
            ImAnim.EasePreset(IamEaseType.OutExpo), IamPolicy.Crossfade, dt, self.dropBigSize)
        local cy       = ImAnim.TweenFloat(self.animId, self.chDropY, targetCY, self.dropDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, startCY)
        local cx       = ImAnim.TweenFloat(self.animId, self.chX, targetCX, self.dropDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, display.x / 2)
        local half     = size / 2

        dl:AddImage(ImagesUI.imgDisplayed:GetTextureID(),
            ImVec2(cx - half, cy - half),
            ImVec2(cx + half, cy + half))

        if Globals.GetTimeSeconds() - self.animStartTime >= self.dropDuration then
            self.animState     = "done"
            self.animEndedTime = Globals.GetTimeMS()
        end
        return true
    end

    return false
end

-- `Renders the side-spin-with-depth animation: icon arcs in from screen edge, large-to-small`
--- @param dl ImDrawList foreground draw list`
--- @param display ImVec2 display size`
--- @param finalX number target screen X of the image top-left`
--- @param finalY number target screen Y of the image top-left`
--- @param dt number delta time`
--- @return boolean true while animation is still running`
local function renderSweep(self, dl, display, finalX, finalY, dt)
    if self.animState == "sweeping" then
        if not self.animStartTime then
            self.animStartTime = Globals.GetTimeSeconds()
            -- 1=left, 2=right, 3=top, 4=bottom
            self.sweepEdge     = math.floor(math.random() * 4) + 1
        end

        local targetCX = finalX + self.imgEndSize / 2
        local targetCY = finalY + self.imgEndSize / 2
        local bigSize  = self.imgStartSize * 1.4

        -- start position: off the chosen edge, centered on the other axis
        local startX, startY
        if self.sweepEdge == 1 then
            startX, startY = -bigSize, display.y * 0.4
        elseif self.sweepEdge == 2 then
            startX, startY = display.x + bigSize, display.y * 0.4
        elseif self.sweepEdge == 3 then
            startX, startY = display.x * 0.4, -bigSize
        else
            startX, startY = display.x * 0.4, display.y + bigSize
        end

        local cx           = ImAnim.TweenFloat(self.animId, self.chSweepX, targetCX, self.sweepDuration,
            ImAnim.EasePreset(IamEaseType.OutExpo), IamPolicy.Crossfade, dt, startX)
        local cy           = ImAnim.TweenFloat(self.animId, self.chSweepY, targetCY, self.sweepDuration,
            ImAnim.EasePreset(IamEaseType.OutBack), IamPolicy.Crossfade, dt, startY)
        -- shrinks as it approaches, giving a depth/perspective feel
        local size         = ImAnim.TweenFloat(self.animId, self.chSweepSize, self.imgEndSize, self.sweepDuration,
            ImAnim.EasePreset(IamEaseType.OutExpo), IamPolicy.Crossfade, dt, bigSize)
        -- spin direction: clockwise from left/top, counter from right/bottom
        local startAngle   = (self.sweepEdge == 1 or self.sweepEdge == 3) and (math.pi * 2) or -(math.pi * 2)
        local angle        = ImAnim.TweenFloat(self.animId, self.chSweepAngle, 0, self.sweepDuration,
            ImAnim.EasePreset(IamEaseType.OutExpo), IamPolicy.Crossfade, dt, startAngle)

        local half         = size / 2
        local p1           = ImVec2(cx - half, cy - half)
        local p2           = ImVec2(cx + half, cy + half)

        -- rotate the quad around the center of the image
        local cos_a, sin_a = math.cos(angle), math.sin(angle)
        local function rot(px, py)
            local rx = px - cx
            local ry = py - cy
            return ImVec2(cx + rx * cos_a - ry * sin_a, cy + rx * sin_a + ry * cos_a)
        end

        dl:AddImageQuad(ImagesUI.imgDisplayed:GetTextureID(),
            rot(p1.x, p1.y), rot(p2.x, p1.y), rot(p2.x, p2.y), rot(p1.x, p2.y),
            ImVec2(0, 0), ImVec2(1, 0), ImVec2(1, 1), ImVec2(0, 1))

        if Globals.GetTimeSeconds() - self.animStartTime >= self.sweepDuration then
            self.animState     = "done"
            self.animEndedTime = Globals.GetTimeMS()
        end
        return true
    end

    return false
end

-- `Dispatches to the chosen animation renderer and handles the shared done states`
--- @param display ImVec2 display size`
--- @param finalX number target screen X of the image top-left`
--- @param finalY number target screen Y of the image top-left`
--- @return boolean true while animation is still running`
local function renderAnimImage(self, display, finalX, finalY)
    local dl = ImGui.GetForegroundDrawList()
    local dt = Ui.GetDeltaTime()

    if self.animState == "done" then
        if Globals.GetTimeMS() - self.animEndedTime >= 450 then
            self.animState = "donedone"
        end
        return false
    end

    if self.animType == "lissajous" then
        return renderLissajous(self, dl, display, finalX, finalY, dt)
    elseif self.animType == "drop" then
        return renderDrop(self, dl, display, finalX, finalY, dt)
    else
        return renderSweep(self, dl, display, finalX, finalY, dt)
    end
end

function LoaderUI:RenderLoader(initPctComplete, initMsg)
    if not self.Initialized then
        ImagesUI:InitLoader()
        self.Initialized = true
    end

    local display = ImGui.GetIO().DisplaySize
    local winX    = display.x / 2 - 200
    local winY    = display.y / 3 - 75

    -- Approximate screen position of the image inside the loader window (~8px window padding)
    local finalX  = winX + 8
    local finalY  = winY + 8

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 15)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 15)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1.25)
    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 100)
    ImGui.SetNextWindowSize(ImVec2(400, 80), ImGuiCond.Always)
    ImGui.SetNextWindowPos(ImVec2(winX, winY), ImGuiCond.Always)

    ImGui.Begin("RGMercs Loader", nil,
        bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoFocusOnAppearing))

    local animRunning = renderAnimImage(self, display, finalX, finalY)

    if animRunning then
        ImGui.Dummy(ImVec2(60, 60))
    else
        ImGui.Image(ImagesUI.imgDisplayed:GetTextureID(), ImVec2(60, 60))
    end
    ImGui.SameLine()
    Ui.RenderText("RGMercs %s: Loading...", Config._version)
    ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 35)
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 70)
    Ui.RenderAnimatedPercentage("RGMercsLoadProgressBar", initPctComplete, 16, 0, Globals.Constants.Colors.LightBlue, Globals.Constants.Colors.Green, initMsg)
    ImGui.PopStyleVar(4)
    ImGui.End()
end

function LoaderUI:IsDone()
    return self.animState == "donedone"
end

return LoaderUI
