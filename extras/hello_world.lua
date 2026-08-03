-- Hello World - a working example user module for RGMercs.
--
-- Enable it on the UserModules tab to see it run, then copy this file under a
-- new name, change _name, and make it your own.
--
-- The full authoring guide is docs/user_modules.md in your RGMercs folder.

local mq       = require('mq')
local ImGui    = require('ImGui')
local Base     = require("modules.base")
local Comms    = require("utils.comms")
local Config   = require('utils.config')
local Globals  = require("utils.globals")
local Logger   = require("utils.logger")

local Module   = { _version = '1.0', _name = "HelloWorld", _author = 'RGMercs', }
Module.__index = Module
setmetatable(Module, { __index = Base, })

Module.TempSettings    = {}

Module.CommandHandlers = {
    hello = {
        usage = "/rgl hello",
        about = "Say hello from the Hello World example module.",
        handler = function(self)
            Comms.PrintGroupMessage("Hello from %s, running on %s!", self._name, Globals.CurLoadedChar)
            return true
        end,
    },
}

Module.FAQ             = {
    {
        Question = "What is the Hello World module?",
        Answer =
            "  A working example user module, shipped with RGMercs so there is something running to copy from. It draws this tab, adds a setting, answers /rgl hello, and says hello in your log when you zone.\n\n" ..
            "  To start your own, copy hello_world.lua in (MQconfigdir)/rgmercs/modules under a new name and change its _name. The full guide is docs/user_modules.md in your RGMercs folder.",
        Settings_Used = "HelloWorldGreetOnZone",
    },
}

Module.DefaultConfig   = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['HelloWorldGreetOnZone'] = {
        DisplayName = "Greet On Zone",
        Group = "General",
        Header = "Hello World",
        Category = "Hello World",
        Index = 1,
        Tooltip = "Say hello in your log after every zone.",
        Default = false,
        FAQ = "Can a user module react to what I am doing?",
        Answer = "Yes. A module can override the same hooks RGMercs uses - zoning, death, combat and target changes. " ..
            "Greet On Zone is the example.",
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Init()
    Base.Init(self)
    Logger.log_info("\agHello, Norrath! \ax%s is loaded.", self._name)
end

function Module:OnZone()
    if not Config:GetSetting('HelloWorldGreetOnZone') then return end

    Logger.log_info("\agHello from \at%s\ag! Welcome to \at%s\ag.", self._name, mq.TLO.Zone.Name() or "parts unknown")
end

function Module:ShouldRender()
    return true
end

function Module:Render()
    Base.Render(self)

    if not self.ModuleLoaded then return end

    ImGui.TextWrapped(string.format("Hello, %s!", Globals.CurLoadedChar))
    ImGui.Spacing()
    ImGui.TextWrapped("This tab is drawn by a user module living in your MQ config folder. Copy the file, change _name, and it becomes yours.")
    ImGui.Spacing()
    ImGui.TextWrapped("Guide: docs/user_modules.md in your RGMercs folder.")
    ImGui.Spacing()

    if ImGui.SmallButton("Say Hello") then
        Comms.PrintGroupMessage("Hello from %s!", self._name)
    end
end

function Module:Shutdown()
    Logger.log_info("\ayGoodbye from %s.", self._name)
end

return Module
