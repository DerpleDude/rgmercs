local Globals  = require("utils.globals")
local Base     = require("modules.base")

local Module   = { _version = '0.1a', _name = "Contributors", _author = 'Derple', }
Module.__index = Module
setmetatable(Module, { __index = Base, })

Module.FAQ             = {}
Module.CommandHandlers = {}
Module.DefaultConfig   = {}

Module.Credits         = require("extras.credits")
Module.ColorWheel      = {}
Module.ColorWheelTimer = {}

function Module:New()
    return Base.New(self)
end

function Module:ShouldRender()
    return false
end

function Module:RenderName(name)
    local length = name:len()

    self.ColorWheel[name] = self.ColorWheel[name] or math.random(10000)
    self.ColorWheelTimer[name] = self.ColorWheelTimer[name] or Globals.GetTimeSeconds()

    if Globals.GetTimeSeconds() - self.ColorWheelTimer[name] > 0.25 then
        self.ColorWheel[name] = self.ColorWheel[name] + 1 --math.random(500)
        self.ColorWheelTimer[name] = Globals.GetTimeSeconds()
    end

    for i = 1, length do
        local color = IM_COL32(
            math.floor(math.sin(0.3 * (self.ColorWheel[name] + i) + 0) * 127 + 128),
            math.floor(math.sin(0.3 * (self.ColorWheel[name] + i) + 2) * 127 + 128),
            math.floor(math.sin(0.3 * (self.ColorWheel[name] + i) + 4) * 127 + 128)
        )

        if i > 1 then
            ImGui.SameLine()
        end

        ImGui.PushStyleColor(ImGuiCol.Text, color)
        ImGui.Text(name:sub(i, i))
        ImGui.PopStyleColor()
    end
end

function Module:RenderConfig()
    if ImGui.CollapsingHeader("Developers", ImGuiTreeNodeFlags.DefaultOpen) then
        for _, c in ipairs(self.Credits.Devs) do
            self:RenderName(c)
        end
    end

    ImGui.NewLine()

    if ImGui.CollapsingHeader("Contributors - Thank You!") then
        for _, c in ipairs(self.Credits.Contributors) do
            self:RenderName(c)
        end
    end
end

return Module
