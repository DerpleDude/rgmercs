local ImGui    = require('ImGui')
local Base     = require("modules.base")
local MapUI    = require("ui.map")

local Module   = { _version = '1.0', _name = "Map", _author = 'Derple', }
Module.__index = Module
setmetatable(Module, { __index = Base, })

Module.CommandHandlers = {}
Module.FAQ             = {}

Module.DefaultConfig   = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['CustomMapsFolder'] = {
        DisplayName = "Custom Map Folder",
        Category = "Map",
        Tooltip = "Override path to the EverQuest map folder used for canvas line data. Leave blank to use default maps under your EQ install.",
        Default = "",
    },
    ['SafePullAreaPoints'] = {
        DisplayName = "Safe Pull Area Vertices",
        Type = "Custom",
        Default = {},
    },
    ['TargetRadius'] = {
        DisplayName = "Map Target Radius",
        Category = "Map",
        Tooltip = "Radius used by the Map canvas to size view bounds and scan for nearby NPCs.",
        Default = 300,
        Min = 50,
        Max = 2000,
    },
    ['MaxMapNPCsToRender'] = {
        DisplayName = "Max Map NPCs to Render",
        Category = "Map",
        Tooltip = "Maximum number of NPCs to render on the map.",
        Default = 100,
        Min = 1,
        Max = 2000,
    },
    ['PullRouteRadius'] = {
        DisplayName = "Pull Route Radius",
        Category = "Map",
        Tooltip = "Radius around each pull route point considered valid for engaging pulls.",
        Default = 120,
        Min = 10,
        Max = 1000,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:ShouldRender()
    return true
end

function Module:Render()
    Base.Render(self)

    if ImGui.SmallButton("-") then
        MapUI:SetZoom(math.max(0.2, MapUI:GetZoom() / 1.2))
    end
    ImGui.SameLine()
    ImGui.Text(string.format("Zoom: %.2fx", MapUI:GetZoom()))
    ImGui.SameLine()
    if ImGui.SmallButton("+") then
        MapUI:SetZoom(math.min(8.0, MapUI:GetZoom() * 1.2))
    end
    ImGui.SameLine()
    if ImGui.SmallButton("Reset View") then
        MapUI:ResetView()
    end
    ImGui.SameLine()
    local adding = MapUI:IsAddWaypointMode()
    if adding then
        ImGui.PushStyleColor(ImGuiCol.Button, ImVec4(0.30, 0.70, 0.30, 1.0))
    end
    if ImGui.SmallButton(adding and "Adding Waypoints (click map)" or "Add Waypoints") then
        MapUI:SetAddWaypointMode(not adding)
    end
    if adding then
        ImGui.PopStyleColor()
    end

    local availX, availY = ImGui.GetContentRegionAvail()
    local canvasW = math.max(200, availX - 8)
    local canvasH = math.max(200, availY - 8)

    MapUI:RenderCanvas(canvasW, canvasH)
end

return Module
