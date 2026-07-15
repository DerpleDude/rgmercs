local Config            = require('utils.config')
local Globals           = require("utils.globals")
local Modules           = require("utils.modules")
local Strings           = require("utils.strings")
local mq                = require 'mq'

---@class RGMercsModuleType
---@type DataType
local rgMercsModuleType = mq.DataType.new('RGMercsModule', {
    Members = {
        Name = function(_, self)
            return 'string', string.format("RGMercs [Module: %s/%s] by: %s", self._name, self._version, self._author)
        end,

        State = function(_, self)
            return 'string', self:DoGetState()
        end,
    },

    Methods = {
    },

    ToString = function(self)
        return self._name
    end,
})

---@class RGMercsMainType
---@type DataType
local rgMercsMainType   = mq.DataType.new('RGMercsMain', {
    Members = {
        Paused = function(_, self)
            return 'bool', Globals.PauseMain
        end,
        MA = function(_, self)
            return 'string', Globals.MainAssist or "None"
        end,
        Globals = function(param, self)
            if not param or param:len() == 0 or Globals[param] == nil then
                return 'string', "nil"
            end

            if type(Globals[param]) == "boolean" then
                return 'bool', Globals[param]
            end

            if type(Globals[param]) == "number" then
                return 'int', Globals[param]
            end

            if type(Globals[param]) == "table" then
                return 'string', Strings.TableToString(Globals[param], 4096)
            end

            return 'string', Globals[param] or "nil"
        end,
        Config = function(param, self)
            if not Globals.SubmodulesLoaded then
                return 'string', "Submodules not loaded yet, please wait..."
            end

            if not param or param:len() == 0 then
                return 'string', "false"
            end


            local value = Config:GetSetting(param)

            if value == nil then
                return 'string', "nil"
            end

            if type(value) == "boolean" then
                return 'bool', value
            end

            if type(value) == "number" then
                return 'int', value
            end

            if type(value) == "table" then
                return 'string', Strings.TableToString(value, 4096)
            end

            return 'string', value
        end,
        State = function(_, self)
            return 'string', Globals.PauseMain and "Paused" or "Running"
        end,
        IsTanking = function(_, self)
            return 'bool', Globals.SubmodulesLoaded and Modules:ExecModule("Class", "IsTanking") or false
        end,
    },

    ToString = function(self)
        return self._name
    end,
})

---@return MQType, RGMercsModuleType|string|boolean|nil
local function RGMercsTLOHandler(param)
    if not param or param:len() == 0 then
        return rgMercsMainType, Config
    end

    if param:lower() == "curable" then
        return 'string', string.format("Disease: %d, Poison: %d, Curse: %d, Corruption: %d",
            mq.TLO.Me.Diseased.ID() or 0,
            mq.TLO.Me.Poisoned.ID() or 0,
            mq.TLO.Me.Cursed.ID() or 0,
            mq.TLO.Me.Corrupted.ID() or 0)
    end

    return rgMercsModuleType, Modules:GetModule(param)
end
-- Register our TLO functions
mq.AddTopLevelObject('RGMercs', RGMercsTLOHandler)
