local mq                      = require("mq")
local Globals                 = require("utils.globals")
local Logger                  = require("utils.logger")

local Modules                 = { _version = '0.1a', _author = 'Derple', }
Modules.__index               = Modules

Modules.ModuleOrder           = {
    "Class",
    "Movement",
    "Clickies",
    "Pull",
    "Drag",
    "Charm",
    "Mez",
    "Travel",
    "Spawns",
    "Map",
    "Perf",
    "Contributors",
    "FAQ",
    "UserModules",
    "Debug",
}

Modules.ModuleList            = {}

--- Name → file path for the user modules currently loaded from mq.configDir.
Modules.LoadedUserModules     = {}

--- Name → message from the most recent failed load attempt.
Modules.UserModuleLoadErrors  = {}

--- Name → smoothed GiveTime cost in milliseconds.
Modules.UserModuleFrameTimes  = {}

Modules.UserModuleSyncPending = false

---@return any
function Modules:load(lootModule)
    if lootModule ~= "None" then
        table.insert(self.ModuleOrder, lootModule)
    end
    self.ModuleList = {
        Movement     = require("modules.move"):New(),
        Travel       = require("modules.travel"):New(),
        Clickies     = require("modules.clickies"):New(),
        Class        = require("modules.class"):New(),
        Pull         = require("modules.pull"):New(),
        Drag         = require("modules.drag"):New(),
        Mez          = require("modules.mez"):New(),
        Charm        = require("modules.charm"):New(),
        Spawns       = require("modules.spawns"):New(),
        Map          = require("modules.map"):New(),
        Perf         = require("modules.performance"):New(),
        Contributors = require("modules.contributors"):New(),
        FAQ          = require("modules.faq"):New(),
        UserModules  = require("modules.usermodules"):New(),
        Debug        = require("modules.debug"):New(),
        LootNScoot   = lootModule == "LootNScoot" and require("modules.lootnscoot"):New() or nil,
        SmartLoot    = lootModule == "SmartLoot" and require("modules.smartloot"):New() or nil,
    }
end

--- Shuts down and removes a module by name, also removing it from
--- the execution order list.
---@param moduleName string Name of the module to unload.
function Modules:unloadModule(moduleName)
    if self.ModuleList[moduleName] ~= nil then
        local module = self.ModuleList[moduleName]
        local shutdownOk, shutdownError = pcall(function() module:Shutdown() end)
        if not shutdownOk then
            Logger.log_error("\ar%s errored during shutdown: %s", moduleName, shutdownError)
        end

        for _, eventName in ipairs(module._trackedEvents or {}) do
            mq.unevent(eventName)
        end
        for _, slash in ipairs(module._trackedBinds or {}) do
            mq.unbind(slash)
        end
        for _, imguiName in ipairs(module._trackedImGui or {}) do
            mq.imgui.destroy(imguiName)
        end
        for _, dropbox in ipairs(module._trackedActors or {}) do
            dropbox:unregister()
        end

        self.ModuleList[moduleName] = nil
        for i, v in pairs(self.ModuleOrder) do
            if v == moduleName then
                table.remove(self.ModuleOrder, i)
                break
            end
        end
        Logger.log_info("Unload %s", moduleName) -- temp debug text
    end
end

--- Loads (or reloads) a module from filePath, appends it to the
--- execution order, then calls its Init function.
---@param moduleName string Name key to store the module under.
---@param filePath string Require-style path to the module file.
function Modules:loadModule(moduleName, filePath)
    self:unloadModule(moduleName)
    self.ModuleList[moduleName] = require(filePath):New()
    table.insert(self.ModuleOrder, moduleName)
    Logger.log_info("Load %s", moduleName) -- temp debug text
    Modules:ExecModule(moduleName, "Init")
end

--- Loads a user module from an absolute file path, appends it to the execution
--- order and initializes it, rolling back if the file errors.
---@param moduleName string Declared _name of the module.
---@param filePath string Absolute path to the user module file.
---@return boolean success True when the module loaded and initialized.
function Modules:loadUserModule(moduleName, filePath)
    local Config = require("utils.config")

    self:unloadUserModule(moduleName)

    local chunk, loadError = loadfile(filePath)
    if not chunk then
        Logger.log_error("\arUser module \at%s\ar failed to load: %s", moduleName, loadError)
        self.UserModuleLoadErrors[moduleName] = loadError
        return false
    end

    local success, initError = pcall(function()
        local instance = chunk():New()
        if type(instance) ~= "table" then
            error("New() did not return a module instance.", 0)
        end

        local claimedBy, claimedSetting = Config:FindConflictingSettingOwner(moduleName, instance.DefaultConfig)
        if claimedBy then
            error(string.format("setting '%s' is already owned by the %s module.", claimedSetting, claimedBy), 0)
        end

        self.ModuleList[moduleName] = instance
        self.LoadedUserModules[moduleName] = filePath
        self:ExecModule(moduleName, "Init")

        table.insert(self.ModuleOrder, moduleName)
        Config:UpdateCommandHandlers()
    end)

    if not success then
        Logger.log_error("\arUser module \at%s\ar failed to initialize: %s", moduleName, initError)
        self:unloadUserModule(moduleName)
        self.UserModuleLoadErrors[moduleName] = initError
        return false
    end

    self.UserModuleLoadErrors[moduleName] = nil
    Logger.log_info("\agLoaded user module \at%s", moduleName)
    return true
end

--- Shuts down a loaded user module and drops its in-memory settings
--- registration; persisted values are left in the database.
---@param moduleName string Declared _name of the module.
function Modules:unloadUserModule(moduleName)
    if not self.LoadedUserModules[moduleName] then return end

    local Config = require("utils.config")

    self:unloadModule(moduleName)
    self.LoadedUserModules[moduleName] = nil
    self.UserModuleLoadErrors[moduleName] = nil
    self.UserModuleFrameTimes[moduleName] = nil

    Config:ClearModuleSettings(moduleName)
    Config:UpdateCommandHandlers()
end

--- Flags that the loaded user modules need reconciling against the saved list.
--- Callers on the ImGui render thread must use this rather than syncing inline.
function Modules:RequestUserModuleSync()
    self.UserModuleSyncPending = true
end

--- Runs a pending sync. Called from the main loop, outside any ModuleOrder walk.
function Modules:ProcessUserModuleSync()
    if not self.UserModuleSyncPending then return end

    self.UserModuleSyncPending = false
    self:SyncUserModules()
end

--- Rescans the user modules folder and brings the loaded user modules in line
--- with the saved list, unloading what is no longer enabled and loading what is.
--- Safe to call repeatedly; already-loaded modules are left running.
function Modules:SyncUserModules()
    local Config = require("utils.config")
    local Core = require("utils.core")

    local scanned = Core.ScanUserModules()

    local savedList = Config:GetSetting('UserModuleList') or {}
    local wantLoaded = {}
    local listChanged = false

    if scanned then
        for idx = #savedList, 1, -1 do
            if not Core.FindUserModule(savedList[idx].name, savedList[idx].file) then
                Logger.log_info("\ayForgetting user module \at%s\ay; its file is no longer in the modules folder.", savedList[idx].name)
                table.remove(savedList, idx)
                listChanged = true
            end
        end
    end

    for _, listEntry in ipairs(savedList) do
        local manifestEntry = Core.FindUserModule(listEntry.name, listEntry.file)
        if manifestEntry and manifestEntry.name and not manifestEntry.error and not manifestEntry.collisionWith then
            if listEntry.name ~= manifestEntry.name or listEntry.file ~= manifestEntry.fileName then
                listEntry.name = manifestEntry.name
                listEntry.file = manifestEntry.fileName
                listChanged = true
            end

            if listEntry.enabled then
                wantLoaded[manifestEntry.name] = manifestEntry.filePath
            end
        end
    end

    local staleModules = {}
    for moduleName, filePath in pairs(self.LoadedUserModules) do
        if wantLoaded[moduleName] ~= filePath then
            table.insert(staleModules, moduleName)
        end
    end
    for _, moduleName in ipairs(staleModules) do
        self:unloadUserModule(moduleName)
    end

    for _, listEntry in ipairs(savedList) do
        if listEntry.enabled and wantLoaded[listEntry.name] and not self.LoadedUserModules[listEntry.name] then
            self:loadUserModule(listEntry.name, wantLoaded[listEntry.name])
        end
    end

    if listChanged then
        Config:SetSetting('UserModuleList', savedList)
    end
end

--- Returns the raw ModuleList table (name → module instance).
---@return table<string, RGMercsModuleType> The loaded module map.
function Modules:GetModuleList()
    return self.ModuleList
end

--- Returns the ordered list of module name strings used for GiveTime
--- and ExecAll dispatch.
---@return string[] Ordered array of module names.
function Modules:GetModuleOrderedNames()
    return self.ModuleOrder
end

---@param m string
---@return RGMercsModuleType|nil
function Modules:GetModule(m)
    for name, module in pairs(self.ModuleList) do
        if name == m then
            return module
        end
    end
    return nil
end

--- Calls fn on the named module (case-insensitive fallback), forwarding
--- any extra args. Logs an error if the module is not found.
---@param m string Module name.
---@param fn string Method name to call on the module.
---@param ... any Arguments forwarded to the method.
---@return any Return value from the module method, if any.
function Modules:ExecModule(m, fn, ...)
    if self.ModuleList[m] ~= nil then
        return self.ModuleList[m][fn](self.ModuleList[m], ...)
    end

    for name, module in pairs(self.ModuleList) do
        if name:lower() == m:lower() then
            return module[fn](module, ...)
        end
    end
    Logger.log_error("\arModule: \at%s\ar not found!", m)
end

--- Calls fn on every module in ModuleOrder, collecting return values
--- into a name-keyed table. Tracks per-frame timing for GiveTime calls.
---@param fn string Method name to call on each module.
---@param ... any Arguments forwarded to each module method.
---@return table<string, any> Map of module name → return value.
function Modules:ExecAll(fn, ...)
    local ret = {}
    for _, name in pairs(self.ModuleOrder) do
        local startTime = Globals.GetTimeSeconds() * 1000
        local module = self.ModuleList[name]
        if module and module[fn] then
            ret[name] = module[fn](module, ...)

            if fn == "GiveTime" then
                local frameTime = (Globals.GetTimeSeconds() * 1000) - startTime

                if self.ModuleList.Perf then
                    self.ModuleList.Perf:OnFrameExec(name, frameTime)
                end

                if self.LoadedUserModules[name] then
                    self.UserModuleFrameTimes[name] = ((self.UserModuleFrameTimes[name] or frameTime) * 0.9) + (frameTime * 0.1)
                end
            end
        end
    end

    return ret
end

return Modules
