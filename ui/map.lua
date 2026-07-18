local mq              = require('mq')
local Icons           = require('mq.ICONS')
local ImGui           = require('ImGui')
local Config          = require('utils.config')
local Modules         = require('utils.modules')
local Strings         = require('utils.strings')
local Ui              = require('utils.ui')

local MapUI           = { _version = '1.0', _name = "MapUI", _author = 'Derple', }
MapUI.__index         = MapUI

-- Module State

local mapLinesZone    = ''
local mapLinesFolder  = ''
local mapLines        = {}
local editMode        = false
local addWaypointMode = false
local zoom            = 1.0
local panX            = 0
local panY            = 0

-- Helpers

local function getCurrentZoneKey()
    return (mq.TLO.Zone.ShortName() or "unknown"):lower()
end

local function getMapFolder()
    local customFolder = Config:GetSetting('CustomMapsFolder', true)

    local eqPath = mq.TLO.EverQuest.Path() or ''
    if eqPath == '' then return '' end
    return string.format('%s/maps/%s', eqPath, customFolder)
end

local function parseBrewallMapLine(line)
    if not line or line:sub(1, 1) ~= 'L' then return nil end
    local nums = {}
    for num in line:gmatch('[-%d%.]+') do
        table.insert(nums, tonumber(num))
    end
    if #nums < 6 then return nil end
    return { x1 = nums[1] or 0, y1 = nums[2] or 0, x2 = nums[4] or 0, y2 = nums[5] or 0, }
end

local function loadMapLines(zoneName)
    local mapFolder = getMapFolder()
    if zoneName == mapLinesZone and mapFolder == mapLinesFolder then return end
    mapLinesZone = zoneName
    mapLinesFolder = mapFolder
    mapLines = {}
    if mapFolder == '' then return end
    for _, suffix in ipairs({ '', '_1', '_2', }) do
        local file = io.open(string.format('%s/%s%s.txt', mapFolder, zoneName, suffix), 'r')
        if file then
            for line in file:lines() do
                local segment = parseBrewallMapLine(line)
                if segment then table.insert(mapLines, segment) end
            end
            file:close()
        end
    end
end

local function isPointOnSegment2D(px, py, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local lenSq = dx * dx + dy * dy
    if lenSq == 0 then
        return (px - x1) ^ 2 + (py - y1) ^ 2 < 0.01
    end
    local t = ((px - x1) * dx + (py - y1) * dy) / lenSq
    if t < 0 or t > 1 then return false end
    local cx, cy = x1 + t * dx, y1 + t * dy
    return (px - cx) ^ 2 + (py - cy) ^ 2 < 0.01
end

local function isPointInsideSafeArea(x, y)
    local points = Config:GetSetting('SafePullAreaPoints', true) or {}
    if #points < 3 then return false end
    local px, py = tonumber(x) or 0, tonumber(y) or 0
    local inside = false
    local j = #points
    for i = 1, #points do
        local pi, pj = points[i], points[j]
        local xi = tonumber(pi and pi.x) or 0
        local yi = tonumber(pi and pi.y) or 0
        local xj = tonumber(pj and pj.x) or 0
        local yj = tonumber(pj and pj.y) or 0
        if isPointOnSegment2D(px, py, xi, yi, xj, yj) then return true end
        local intersects = ((yi > py) ~= (yj > py)) and
            (px < ((xj - xi) * (py - yi) / ((yj - yi) ~= 0 and (yj - yi) or 0.000001)) + xi)
        if intersects then inside = not inside end
        j = i
    end
    return inside
end

local function isSpawnInsideSafeArea(spawn)
    if not spawn or not spawn() then return false end
    return isPointInsideSafeArea(spawn.X() or 0, spawn.Y() or 0)
end

local function getEditorBounds()
    local me = mq.TLO.Me
    local myX = -(me.X() or 0)
    local myY = me.Y() or 0
    local halfRange = math.max(Config:GetSetting('TargetRadius', true) or 300,
        Config:GetSetting('PullRouteRadius', true) or 120, 120)
    local minX, maxX = myX - halfRange, myX + halfRange
    local minY, maxY = myY - halfRange, myY + halfRange

    local padding = 40
    minX, maxX = minX - padding, maxX + padding
    minY, maxY = minY - padding, maxY + padding

    if math.abs(maxX - minX) < 50 then minX, maxX = myX - 25, myX + 25 end
    if math.abs(maxY - minY) < 50 then minY, maxY = myY - 25, myY + 25 end

    return minX, maxX, minY, maxY
end

-- Public API

function MapUI:ResetCache()
    mapLinesZone = ''
    mapLinesFolder = ''
    mapLines = {}
end

function MapUI:ResetView()
    zoom = 1.0
    panX = 0
    panY = 0
end

function MapUI:IsEditMode() return editMode end

function MapUI:SetEditMode(v) editMode = v and true or false end

function MapUI:IsAddWaypointMode() return addWaypointMode end

function MapUI:SetAddWaypointMode(v) addWaypointMode = v and true or false end

function MapUI:GetZoom() return zoom end

function MapUI:SetZoom(v) zoom = tonumber(v) or 1.0 end

function MapUI:IsSpawnInsideSafeArea(spawn) return isSpawnInsideSafeArea(spawn) end

function MapUI:IsPointInsideSafeArea(x, y) return isPointInsideSafeArea(x, y) end

function MapUI:RenderCanvas(canvasWidth, canvasHeight)
    canvasWidth = canvasWidth or 520
    canvasHeight = canvasHeight or 320
    loadMapLines(getCurrentZoneKey())

    local me = mq.TLO.Me
    local canvasX, canvasY = ImGui.GetCursorScreenPos()
    local canvasMin = ImVec2(canvasX, canvasY)
    local canvasMax = ImVec2(canvasX + canvasWidth, canvasY + canvasHeight)
    local drawList = ImGui.GetWindowDrawList()

    drawList:AddRectFilled(canvasMin, canvasMax, ImGui.GetColorU32(ImVec4(0.08, 0.08, 0.10, 0.95)), 6)
    drawList:AddRect(canvasMin, canvasMax, ImGui.GetColorU32(ImVec4(0.35, 0.35, 0.40, 1.0)), 6, 0, 1.5)

    ImGui.InvisibleButton('##MapUICanvas', canvasWidth, canvasHeight,
        bit32.bor(ImGuiButtonFlags.MouseButtonLeft, ImGuiButtonFlags.MouseButtonRight))
    local isHovered = ImGui.IsItemHovered()
    local isActive = ImGui.IsItemActive()
    local mouseX, mouseY = ImGui.GetMousePos()
    local io = ImGui.GetIO()

    if isHovered then
        ImGui.SetNextFrameWantCaptureMouse(true)
    end

    local minX, maxX, minY, maxY = getEditorBounds()
    local worldW = math.max(1, maxX - minX)
    local worldH = math.max(1, maxY - minY)
    local baseScale = math.min((canvasWidth - 24) / worldW, (canvasHeight - 24) / worldH)
    local scale = baseScale * math.max(0.2, math.min(8.0, zoom))
    local centerX = (minX + maxX) * 0.5
    local centerY = (minY + maxY) * 0.5
    local originX = canvasX + (canvasWidth * 0.5) + panX
    local originY = canvasY + (canvasHeight * 0.5) + panY

    local function worldToScreen(wx, wy)
        return originX + ((tonumber(wx) or 0) - centerX) * scale,
            originY - ((tonumber(wy) or 0) - centerY) * scale
    end

    local function screenToWorld(sx, sy)
        return centerX + ((tonumber(sx) or originX) - originX) / scale,
            centerY - ((tonumber(sy) or originY) - originY) / scale
    end

    if isActive and (ImGui.IsMouseDragging(ImGuiMouseButton.Left, 0) or ImGui.IsMouseDragging(ImGuiMouseButton.Right, 0)) then
        panX = panX + (io.MouseDelta and io.MouseDelta.x or 0)
        panY = panY + (io.MouseDelta and io.MouseDelta.y or 0)
        originX = canvasX + (canvasWidth * 0.5) + panX
        originY = canvasY + (canvasHeight * 0.5) + panY
    end

    if addWaypointMode and isHovered and ImGui.IsMouseClicked(ImGuiMouseButton.Left) then
        local displayX, displayY = screenToWorld(mouseX, mouseY)
        Modules:ExecModule("Pull", "AddLocationAt", { y = displayY, x = -displayX, z = me.Z() or 0, })
    end

    local viewMinX, viewMaxY = screenToWorld(canvasX, canvasY)
    local viewMaxX, viewMinY = screenToWorld(canvasX + canvasWidth, canvasY + canvasHeight)

    drawList:PushClipRect(canvasMin, canvasMax, true)

    for _, segment in ipairs(mapLines) do
        local x1 = tonumber(segment.x1) or 0
        local y1 = -(tonumber(segment.y1) or 0)
        local x2 = tonumber(segment.x2) or 0
        local y2 = -(tonumber(segment.y2) or 0)
        local segMinX = math.min(x1, x2)
        local segMaxX = math.max(x1, x2)
        local segMinY = math.min(y1, y2)
        local segMaxY = math.max(y1, y2)
        if segMaxX >= viewMinX and segMinX <= viewMaxX and segMaxY >= viewMinY and segMinY <= viewMaxY then
            local sx1, sy1 = worldToScreen(x1, y1)
            local sx2, sy2 = worldToScreen(x2, y2)
            drawList:AddLine(ImVec2(sx1, sy1), ImVec2(sx2, sy2),
                ImGui.GetColorU32(ImVec4(0.45, 0.45, 0.50, 0.90)), 1.0)
        end
    end

    local mySx, mySy = worldToScreen(-(me.X() or 0), me.Y() or 0)

    local target = mq.TLO.Target
    if (target.ID() or 0) > 0 and not target.Dead() then
        local tSx, tSy = worldToScreen(-(target.X() or 0), target.Y() or 0)
        drawList:AddLine(ImVec2(mySx, mySy), ImVec2(tSx, tSy),
            ImGui.GetColorU32(ImVec4(1.0, 0.4, 0.4, 0.75)), 1.5)
    end

    local heading = math.rad(me.Heading.Degrees() or 0)
    local sinH, cosH = math.sin(heading), math.cos(heading)
    local tipX, tipY = mySx + sinH * 10, mySy - cosH * 10
    local tailLX, tailLY = mySx - sinH * 6 - cosH * 6, mySy + cosH * 6 - sinH * 6
    local tailRX, tailRY = mySx - sinH * 6 + cosH * 6, mySy + cosH * 6 + sinH * 6
    local baseMidX, baseMidY = mySx - sinH * 4, mySy + cosH * 4
    local tip = ImVec2(tipX, tipY)
    local tailL = ImVec2(tailLX, tailLY)
    local tailR = ImVec2(tailRX, tailRY)
    local baseMid = ImVec2(baseMidX, baseMidY)
    local litColor = ImGui.GetColorU32(ImVec4(0.55, 0.95, 1.00, 1.0))
    local shadeColor = ImGui.GetColorU32(ImVec4(0.05, 0.45, 0.70, 1.0))
    local outlineColor = ImGui.GetColorU32(ImVec4(0.02, 0.10, 0.20, 1.0))
    drawList:AddTriangleFilled(tip, tailL, baseMid, litColor)
    drawList:AddTriangleFilled(tip, baseMid, tailR, shadeColor)
    drawList:AddTriangle(tip, tailL, tailR, outlineColor, 1.0)

    local pullLocations = (Config:GetSetting('PullLocations', true) or {})[getCurrentZoneKey()] or {}
    if #pullLocations > 0 then
        local circuitScreenPoints = {}
        local wpColor = ImGui.GetColorU32(ImVec4(0.30, 1.00, 0.45, 1.0))
        for _, entry in ipairs(pullLocations) do
            local sx, sy = worldToScreen(-(entry.x or 0), entry.y or 0)
            if entry.enabled then
                table.insert(circuitScreenPoints, ImVec2(sx, sy))
            end
            drawList:AddCircleFilled(ImVec2(sx, sy), 4, wpColor, 12)
            drawList:AddText(ImVec2(sx + 6, sy - 8), wpColor, entry.name)
        end
        if #circuitScreenPoints >= 2 then
            drawList:AddPolyline(circuitScreenPoints, wpColor, 0, 2.0)
        end
    end

    local safePoints = Config:GetSetting('SafePullAreaPoints', true) or {}
    if #safePoints > 0 then
        local safeScreenPoints = {}
        for idx, point in ipairs(safePoints) do
            local sx, sy = worldToScreen(-(point.x or 0), point.y or 0)
            table.insert(safeScreenPoints, ImVec2(sx, sy))
            drawList:AddCircleFilled(ImVec2(sx, sy), 4, ImGui.GetColorU32(ImVec4(0.30, 1.00, 0.45, 1.0)), 12)
            drawList:AddText(ImVec2(sx + 6, sy - 8), ImGui.GetColorU32(ImVec4(0.8, 1.0, 0.8, 1.0)), tostring(idx))
        end
        if #safeScreenPoints >= 2 then
            local flags = #safeScreenPoints >= 3 and ImDrawFlags.Closed or 0
            drawList:AddPolyline(safeScreenPoints, ImGui.GetColorU32(ImVec4(0.30, 1.00, 0.45, 0.95)), flags, 2.5)
        end
    end

    local spawnRadius = math.max(Config:GetSetting('TargetRadius'), 100)
    local npcsMaxRenderCount = math.max(Config:GetSetting('MaxMapNPCsToRender'), 40)
    local allowedNames, deniedNames = Modules.ModuleList["Pull"]:GetPullListSets()
    local allowColor = ImGui.GetColorU32(ImVec4(0.30, 1.00, 0.45, 1.0))
    local denyColor = ImGui.GetColorU32(ImVec4(1.00, 0.55, 0.10, 1.0))
    local hoveredSpawn = nil
    local hoveredInside = false
    for i = 1, npcsMaxRenderCount do
        local spawn = mq.TLO.NearestSpawn(i, string.format('npc targetable radius %d', spawnRadius))
        if not spawn or not spawn() then break end
        if spawn.Type() == "NPC" and not spawn.Dead() then
            local sx, sy = worldToScreen(-(spawn.X() or 0), spawn.Y() or 0)
            local inside = isSpawnInsideSafeArea(spawn)
            local r, g, b = Ui.GetConColorBySpawn(spawn)
            local alpha = inside and 0.9 or 0.55
            local cleanLower = (spawn.CleanName() or ""):lower()
            local isChest = cleanLower:match("^a.*chest$") ~= nil and (spawn.Race() or "") == "Chest"
            local isNamed = Modules:ExecModule("Spawns", "IsNamed", spawn)
            if isChest or isNamed then
                local starColor = isChest and ImGui.GetColorU32(ImVec4(1.0, 0.84, 0.0, 1.0)) or allowColor
                local starPts = {}
                for k = 0, 9 do
                    local angle = -math.pi / 2 + k * math.pi / 5
                    local radius = (k % 2 == 0) and 8 or 3.2
                    table.insert(starPts, ImVec2(sx + math.cos(angle) * radius, sy + math.sin(angle) * radius))
                end
                drawList:AddConvexPolyFilled(starPts, starColor)
            else
                drawList:AddCircleFilled(ImVec2(sx, sy), 3, ImGui.GetColorU32(ImVec4(r, g, b, alpha)), 10)
            end
            local pullListKey = Strings.TrimSpaces(cleanLower)
            if allowedNames[pullListKey] then
                drawList:AddCircle(ImVec2(sx, sy), 6, allowColor, 12, 1.5)
            elseif deniedNames[pullListKey] then
                drawList:AddLine(ImVec2(sx - 5, sy - 5), ImVec2(sx + 5, sy + 5), denyColor, 1.5)
                drawList:AddLine(ImVec2(sx - 5, sy + 5), ImVec2(sx + 5, sy - 5), denyColor, 1.5)
            end
            drawList:AddText(ImVec2(sx + 5, sy - 7), ImGui.GetColorU32(ImVec4(r, g, b, alpha)),
                spawn.CleanName() or spawn.Name() or '?')
            if isHovered and not hoveredSpawn then
                local dx, dy = mouseX - sx, mouseY - sy
                if dx * dx + dy * dy <= 36 then
                    hoveredSpawn = spawn
                    hoveredInside = inside
                end
            end
        end
    end

    if hoveredSpawn and ImGui.IsMouseReleased(ImGuiMouseButton.Right) then
        local dragVec = ImGui.GetMouseDragDelta(ImGuiMouseButton.Right)
        ---@diagnostic disable-next-line: undefined-field
        local dragDx, dragDy = dragVec.x or 0, dragVec.y or 0
        if dragDx * dragDx + dragDy * dragDy < 16 then
            mq.cmdf('/target id %d', hoveredSpawn.ID() or 0)
        end
    end

    if isHovered then
        if hoveredSpawn then
            ImGui.SetTooltip('%s\nLevel %d %s | %.0f away\n%s',
                hoveredSpawn.CleanName() or hoveredSpawn.Name() or '?',
                hoveredSpawn.Level() or 0,
                hoveredSpawn.Class.ShortName() or '?',
                hoveredSpawn.Distance() or 0,
                hoveredInside and 'Inside safe area' or 'Outside safe area')
        elseif editMode then
            local worldX, worldY = screenToWorld(mouseX, mouseY)
            ImGui.SetTooltip('World: %.1f, %.1f | Drag to pan | %s',
                worldX, worldY,
                editMode and 'Left-click to add safe-area vertex' or 'Toggle edit mode to draw safe-area vertices')
        end
    end

    drawList:PopClipRect()
end

return MapUI
