local mq           = require('mq')
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Logger       = require("utils.logger")
local Modules      = require("utils.modules")
local Strings      = require("utils.strings")
local Tables       = require("utils.tables")
local Ui           = require("utils.ui")

local Base         = { _version = '1.0', _name = "RGMercsBaseBaseClass", _author = 'Derple', }
Base.__index       = Base
Base.SaveRequested = nil
Base.ModuleLoaded  = false
-- Tables must be defined in sub classes to avoid caching issues across modules

function Base:New()
    local newBase = setmetatable({}, self)
    return newBase
end

function Base:LoadSettings(preLoadFn, postLoadFn)
    Logger.log_debug("\aw[\atLoading Settings\aw] Character: \am%s \awModule: \ay%s", Globals.CurLoadedChar, self._name)
    local firstSaveRequired = false

    if preLoadFn then
        preLoadFn()
    end

    -- load all module settings from db.
    local settings = Config:GetAllModuleSettingsFromDb(self._name)
    local settingsCount = Tables.GetTableSize(settings)
    if settingsCount == 0 and (self.ClassConfig and #self.ClassConfig.DefaultConfig or #self.DefaultConfig) > 0 then
        Logger.log_info("\ayNo settings found in DB for %s, loading defaults.", self._name)
        firstSaveRequired = true
    else
        Logger.log_debug("\agLoaded \at%d\ag settings from DB for \ay%s\aw", settingsCount, self._name)
    end

    Config:RegisterModuleSettings(self._name, settings, self.ClassConfig and self.ClassConfig.DefaultConfig or self.DefaultConfig, self.FAQ, firstSaveRequired)

    if postLoadFn then
        postLoadFn(settings, firstSaveRequired)
    end
end

function Base:Init()
    Logger.log_debug("\aw[\atInitiailize\aw] \am%s Module.", self._name)
    self:LoadSettings()

    self.ModuleLoaded = true
end

function Base:ShouldRender()
    return true
end

function Base:Render()
    return Ui.RenderPopAndSettings(self._name)
end

function Base:Pop()
    Config:SetSetting(self._name .. "_Popped", not Config:GetSetting(self._name .. "_Popped"))
end

function Base:GiveTime()
end

function Base:OnDeath()
    -- Death Handler
end

function Base:OnZone()
    -- Zone Handler
end

function Base:OnCombatModeChanged()
end

function Base:OnForceTargetChange(forceTargetId)
end

function Base:OnTargetChange(targetId)
end

function Base:DoGetState()
    return "Running..."
end

function Base:GetCommandHandlers()
    return { Module = self._name, CommandHandlers = self.CommandHandlers, }
end

function Base:GetFAQ()
    return { Module = self._name, FAQ = self.FAQ or {}, }
end

---@param cmd string
---@param ... string
---@return boolean
function Base:HandleBind(cmd, ...)
    if self.CommandHandlers[cmd:lower()] ~= nil then
        self.CommandHandlers[cmd:lower()].handler(self, ...)
        return true
    end

    -- try to process as a substring
    for bindCmd, bindData in pairs(self.CommandHandlers or {}) do
        if Strings.StartsWith(bindCmd, cmd) then
            bindData.handler(self, ...)
            return true
        end
    end

    return false
end

function Base:Shutdown()
    Logger.log_debug("\aw[\atShutdown\aw] \am%s Module Unloaded.", self._name)
end

return Base
