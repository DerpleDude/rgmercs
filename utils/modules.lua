local mq            = require("mq")
local Globals       = require("utils.globals")
local Logger        = require("utils.logger")

local Modules       = { _version = '0.1a', _author = 'Derple', }
Modules.__index     = Modules

Modules.ModuleOrder = {
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
    "Debug",
}

Modules.ModuleList  = {}

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
        self.ModuleList[moduleName]:Shutdown()
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
                if self.ModuleList.Perf then
                    self.ModuleList.Perf:OnFrameExec(name, (Globals.GetTimeSeconds() * 1000) - startTime)
                end
            end
        end
    end

    return ret
end

return Modules
