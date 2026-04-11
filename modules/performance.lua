-- Sample Performance Monitor Class Module
local mq                  = require('mq')
local Config              = require('utils.config')
local Globals             = require("utils.globals")
local Ui                  = require("utils.ui")
local Comms               = require("utils.comms")
local Modules             = require("utils.modules")
local Logger              = require("utils.logger")
local Strings             = require("utils.strings")
local ImPlot              = require('ImPlot')
local ScrollingPlotBuffer = require('utils.scrolling_plot_buffer')
local Base                = require("modules.base")

local Module              = { _version = '0.1a', _name = "Perf", _author = 'Derple', }
Module.__index            = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                = {}
Module.CommandHandlers    = {}

Module.MaxFrameStep       = 5.0
Module.GoalMaxFrameTime   = 0
Module.CurMaxMaxFrameTime = 0
Module.xAxes              = {}
Module.FrameTimingData    = {}
Module.MaxFrameTime       = 0
Module.LastExtentsCheck   = Globals.GetTimeSeconds()


Module.DefaultConfig = {
    ['SecondsToStore']                         = {
        DisplayName = "Seconds to Store",
        Group = "General",
        Header = "Misc",
        Category = "Misc",
        Tooltip = "The number of Seconds to keep in history.",
        Default = 30,
        Min = 10,
        Max = 120,
        Step = 5,
    },
    ['EnablePerfMonitoring']                   = {
        DisplayName = "Enable Performance Monitoring",
        Group       = "General",
        Header      = "Misc",
        Category    = "Misc",
        Tooltip     = "Enable the Performance Module for advanced testing.",
        Default     = false,
        OnChange    = function(_, newValue)
            Config.Db:setCollectStats(newValue)
        end,
    },
    ['PlotFillLines']                          = {
        DisplayName = "Enable Fill Lines",
        Group = "General",
        Header = "Misc",
        Category = "Misc",
        Tooltip = "Fill in the Plot Lines",
        Default = true,
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Init()
    Base.Init(self)
    Config.Db:setCollectStats(Config:GetSetting('EnablePerfMonitoring'))
end

function Module:ShouldRender()
    return Config:GetSetting('EnablePerfMonitoring', true)
end

function Module:Render()
    Base.Render(self)

    if not self.ModuleLoaded then return end

    if Globals.GetTimeSeconds() - self.LastExtentsCheck > 0.01 then
        self.GoalMaxFrameTime = 0
        self.LastExtentsCheck = Globals.GetTimeSeconds()
        for _, data in pairs(self.FrameTimingData) do
            for idx, time in ipairs(data.frameTimes.DataY) do
                -- is this entry visible?
                local visible = data.frameTimes.DataX[idx] > Globals.GetTimeSeconds() - Config:GetSetting('SecondsToStore') and
                    data.frameTimes.DataX[idx] < Globals.GetTimeSeconds()
                if visible and time > self.GoalMaxFrameTime then
                    self.GoalMaxFrameTime = math.ceil(time / self.MaxFrameStep) * self.MaxFrameStep
                end
            end
        end
    end

    if ImGui.CollapsingHeader("Database Stats") then
        Config.Db:renderTelemetryGraph()
        Config.Db:renderTelemetry()
    end

    if ImGui.CollapsingHeader("Frame Times") then
        -- converge on new max recalc min and maxes
        if self.CurMaxMaxFrameTime < self.GoalMaxFrameTime then self.CurMaxMaxFrameTime = self.CurMaxMaxFrameTime + 1 end
        if self.CurMaxMaxFrameTime > self.GoalMaxFrameTime then self.CurMaxMaxFrameTime = self.CurMaxMaxFrameTime - 1 end

        if ImPlot.BeginPlot("Frame Times for RGMercs Modules") then
            ImPlot.SetupAxes("Time (s)", "Frame Time (ms)")
            ImPlot.SetupAxisLimits(ImAxis.X1, Globals.GetTimeSeconds() - Config:GetSetting('SecondsToStore'), Globals.GetTimeSeconds(), ImGuiCond.Always)
            ImPlot.SetupAxisLimits(ImAxis.Y1, 1, self.CurMaxMaxFrameTime, ImGuiCond.Always)

            for _, module in pairs(Modules:GetModuleOrderedNames()) do
                if self.FrameTimingData[module] and not self.FrameTimingData[module].mutexLock then
                    local framData = self.FrameTimingData[module]

                    if framData then
                        ImPlot.PlotLine(module, framData.frameTimes.DataX, framData.frameTimes.DataY,
                            #framData.frameTimes.DataX,
                            Config:GetSetting('PlotFillLines') and ImPlotLineFlags.Shaded or ImPlotLineFlags.None,
                            framData.frameTimes.Offset - 1)
                    end
                end
            end

            ImPlot.EndPlot()
        end
    end
end

function Module:GiveTime()
    Config:UpdateDbTelemetry()
end

function Module:OnFrameExec(module, frameTime)
    if not Config:GetSetting('EnablePerfMonitoring') then return end

    if not self.FrameTimingData[module] then
        self.FrameTimingData[module] = {
            mutexLock = false,
            lastFrame = Globals.GetTimeSeconds(),
            frameTimes =
                ScrollingPlotBuffer:new(),
        }
    end

    self.FrameTimingData[module].lastFrame = Globals.GetTimeSeconds()
    self.FrameTimingData[module].frameTimes:AddPoint(Globals.GetTimeSeconds(), frameTime)
end

function Module:DoGetState()
    if not Config:GetSetting('EnablePerfMonitoring') then return "Disabled" end

    return "Enabled"
end

return Module
