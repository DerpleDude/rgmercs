local mq       = require('mq')
local Icons    = require('mq.ICONS')
local ImGui    = require('ImGui')
local Base     = require("modules.base")
local Config   = require('utils.config')
local Core     = require("utils.core")
local Globals  = require('utils.globals')
local Logger   = require('utils.logger')
local Modules  = require("utils.modules")
local Ui       = require('utils.ui')

local Module   = { _version = '1.0', _name = "UserModules", _author = 'Algar', }
Module.__index = Module
setmetatable(Module, { __index = Base, })

Module.CommandHandlers = {
    usermodule = {
        usage = "/rgl usermodule <name> <on|off>",
        about = "Enable or disable a user module by its declared name, without opening the UserModules tab.",
        handler = function(self, moduleName, state)
            state = (state or ""):lower()
            if not moduleName or (state ~= "on" and state ~= "off") then
                Logger.log_error("\arUsage: /rgl usermodule <name> <on|off>")
                return true
            end

            self:SetModuleEnabled(moduleName, state == "on")
            return true
        end,
    },
}

Module.FAQ             = {
    {
        Question = "How do I add my own module to RGMercs?",
        Answer =
            "  The GUI can be found on the UserModules tab. Any .lua file placed in (MQconfigdir)/rgmercs/modules will appear in the list after a Refresh, where it can be enabled, reordered, or turned back off.\n\n" ..
            "  A working example, hello_world.lua, is placed in that folder for you. Enable it to watch a user module run, then copy it under a new name and change its _name to begin your own.\n\n" ..
            "  Your module runs in the RGMercs loop alongside the built-in modules, with access to the same settings, lifecycle hooks, tab and commands they use. The full guide is docs/user_modules.md in your RGMercs folder.\n\n" ..
            "  If a module will not enable, the Status column will say why - most often the file failed to load, or the name it declares is already in use. Hover the status for details.\n\n" ..
            "  /rgl usermodule <name> <on|off> enables or disables a module from the command line.\n\n" ..
            "  Please bear in mind that a user module is your own code running inside RGMercs, and a misbehaving one can affect the rest of the script. Feedback on the hooks and helpers available to you is welcome.",
        Settings_Used = "UserModuleList",
    },
}

Module.DefaultConfig   = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['UserModuleList'] = {
        DisplayName = "User Modules",
        Type = "Custom",
        Default = {},
        FAQ = "Does the order of my user modules matter?",
        Answer = "Modules load in the order shown on the UserModules tab, and the arrows reorder them. " ..
            "Turning one off keeps its place in the list and its saved settings, so enabling it again restores what you had.\n\n" ..
            "This list is saved per character and per class, the same as your other settings, so swapping personas loads that class's set of modules.",
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Init()
    Base.Init(self)
end

function Module:ShouldRender()
    return true
end

--- Appends a newly discovered module to the saved list and asks for a sync.
function Module:AddModule(manifestEntry)
    local moduleList = Config:GetSetting('UserModuleList') or {}
    table.insert(moduleList, { name = manifestEntry.name, file = manifestEntry.fileName, enabled = true, })
    Config:SetSetting('UserModuleList', moduleList)
    Modules:RequestUserModuleSync()
end

function Module:ToggleModule(idx)
    local moduleList = Config:GetSetting('UserModuleList') or {}
    local listEntry = moduleList[idx]
    if not listEntry then return end

    listEntry.enabled = not listEntry.enabled
    Config:SetSetting('UserModuleList', moduleList)
    Modules:RequestUserModuleSync()
end

--- Sets a module's enabled state by declared name, adding it to the saved list if it isn't there yet.
function Module:SetModuleEnabled(moduleName, enabled)
    Core.ScanUserModules()

    local manifestEntry = nil
    for _, entry in ipairs(Globals.UserModuleManifest) do
        if entry.name and entry.name:lower() == moduleName:lower() then manifestEntry = entry end
    end

    -- Fall back to the filename so a module that failed to load reports its error instead of going missing.
    for _, entry in ipairs(Globals.UserModuleManifest) do
        if not manifestEntry and entry.fileName:lower():gsub("%.lua$", "") == moduleName:lower():gsub("%.lua$", "") then manifestEntry = entry end
    end

    if not manifestEntry then
        Logger.log_error("\arNo user module named \at%s\ar was found in %s/rgmercs/modules.", moduleName, mq.configDir)
        return
    end

    if manifestEntry.error or manifestEntry.collisionWith then
        Logger.log_error("\ar%s can't be loaded: %s", manifestEntry.name or manifestEntry.fileName,
            manifestEntry.error or ("its name collides with " .. manifestEntry.collisionWith))
        return
    end

    local moduleList = Config:GetSetting('UserModuleList') or {}
    local listEntry = nil
    for _, entry in ipairs(moduleList) do
        if entry.name == manifestEntry.name then listEntry = entry end
    end

    if not listEntry then
        listEntry = { name = manifestEntry.name, file = manifestEntry.fileName, }
        table.insert(moduleList, listEntry)
    end

    listEntry.enabled = enabled
    Config:SetSetting('UserModuleList', moduleList)
    Modules:RequestUserModuleSync()
    Logger.log_info("\ag%s\ax user module \at%s\ax.", enabled and "Enabled" or "Disabled", manifestEntry.name)
end

function Module:MoveModuleUp(idx)
    local moduleList = Config:GetSetting('UserModuleList') or {}
    if idx < 2 or idx > #moduleList then return end
    moduleList[idx - 1], moduleList[idx] = moduleList[idx], moduleList[idx - 1]
    Config:SetSetting('UserModuleList', moduleList)
end

function Module:MoveModuleDown(idx)
    local moduleList = Config:GetSetting('UserModuleList') or {}
    if idx < 1 or idx + 1 > #moduleList then return end
    moduleList[idx + 1], moduleList[idx] = moduleList[idx], moduleList[idx + 1]
    Config:SetSetting('UserModuleList', moduleList)
end

function Module:DeleteModule(idx)
    local moduleList = Config:GetSetting('UserModuleList') or {}
    if not moduleList[idx] then return end

    table.remove(moduleList, idx)
    Config:SetSetting('UserModuleList', moduleList)
    Modules:RequestUserModuleSync()
end

function Module:Render()
    Base.Render(self)

    if not self.ModuleLoaded then return end

    if ImGui.SmallButton("Refresh") then
        Modules:RequestUserModuleSync()
    end
    ImGui.SameLine()
    Ui.RenderText(string.format("%s/rgmercs/modules", mq.configDir))

    local moduleList = Config:GetSetting('UserModuleList') or {}
    local shownFiles = {}
    local rows = {}

    for idx, listEntry in ipairs(moduleList) do
        local manifestEntry = Core.FindUserModule(listEntry.name, listEntry.file)
        if manifestEntry then shownFiles[manifestEntry.fileName] = true end
        table.insert(rows, { idx = idx, name = listEntry.name, enabled = listEntry.enabled, manifest = manifestEntry, })
    end

    for _, manifestEntry in ipairs(Globals.UserModuleManifest) do
        if not shownFiles[manifestEntry.fileName] then
            table.insert(rows, { name = manifestEntry.name, enabled = false, manifest = manifestEntry, })
        end
    end

    if #rows == 0 then
        Ui.RenderColoredText(Globals.Constants.Colors.ConditionDisabledColor, "No user modules found. Drop a .lua module in the folder above and press Refresh.")
        return
    end

    if ImGui.BeginTable("UserModulesTable", 7, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg)) then
        ImGui.TableSetupColumn('Enabled', ImGuiTableColumnFlags.WidthFixed, 55.0)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, 120.0)
        ImGui.TableSetupColumn('File', ImGuiTableColumnFlags.WidthFixed, 140.0)
        ImGui.TableSetupColumn('Version', ImGuiTableColumnFlags.WidthFixed, 55.0)
        ImGui.TableSetupColumn('Author', ImGuiTableColumnFlags.WidthFixed, 90.0)
        ImGui.TableSetupColumn('Status', ImGuiTableColumnFlags.WidthStretch, 150.0)
        ImGui.TableSetupColumn('Controls', ImGuiTableColumnFlags.WidthFixed, 80.0)
        ImGui.TableHeadersRow()

        for _, row in ipairs(rows) do
            local manifestEntry = row.manifest
            local rowKey = row.idx or manifestEntry.fileName
            local loadable = manifestEntry ~= nil and manifestEntry.error == nil and manifestEntry.collisionWith == nil
            local isLoaded = manifestEntry ~= nil and Modules.LoadedUserModules[row.name] == manifestEntry.filePath

            ImGui.PushID("##_user_module_" .. (row.name or "") .. "_" .. rowKey)

            ImGui.TableNextColumn()
            if loadable or row.idx then
                local _, toggled = Ui.RenderOptionToggle("user_module_tggl_" .. rowKey, "", row.enabled)
                if toggled then
                    if row.idx then
                        self:ToggleModule(row.idx)
                    else
                        self:AddModule(manifestEntry)
                    end
                end
            else
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, Icons.FA_BAN)
                Ui.Tooltip("This module can't be loaded until the problem in the Status column is fixed.")
            end

            ImGui.TableNextColumn()
            Ui.RenderText(row.name or "?")
            ImGui.TableNextColumn()
            Ui.RenderText(manifestEntry and manifestEntry.fileName or "-")
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(manifestEntry and manifestEntry.version or "-"))
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(manifestEntry and manifestEntry.author or "-"))

            ImGui.TableNextColumn()
            if isLoaded then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionPassColor, "Loaded")
            elseif not manifestEntry then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, "File missing")
                Ui.Tooltip("No file in the modules folder matches this entry. Delete the row to forget it.")
            elseif manifestEntry.collisionWith then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, "Name taken by %s", manifestEntry.collisionWith)
                Ui.Tooltip("Another module already uses this name. Change _name in this file and press Refresh.")
            elseif manifestEntry.error then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, "Load error")
                Ui.Tooltip(manifestEntry.error)
            elseif Modules.UserModuleLoadErrors[row.name] then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, "Load failed")
                Ui.Tooltip(Modules.UserModuleLoadErrors[row.name])
            else
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionDisabledColor, "Not loaded")
            end

            ImGui.TableNextColumn()
            if row.idx then
                if row.idx == 1 then
                    ImGui.InvisibleButton(Icons.FA_CHEVRON_UP, ImVec2(22, 1))
                elseif ImGui.SmallButton(Icons.FA_CHEVRON_UP) then
                    self:MoveModuleUp(row.idx)
                end
                ImGui.SameLine()
                if row.idx == #moduleList then
                    ImGui.InvisibleButton(Icons.FA_CHEVRON_DOWN, ImVec2(22, 1))
                elseif ImGui.SmallButton(Icons.FA_CHEVRON_DOWN) then
                    self:MoveModuleDown(row.idx)
                end
                ImGui.SameLine()
                if ImGui.SmallButton(Icons.FA_TRASH) then
                    self:DeleteModule(row.idx)
                end
                Ui.Tooltip("Forget this module and unload it.")
            end

            ImGui.PopID()
        end

        ImGui.EndTable()
    end

    Ui.RenderColoredText(Globals.Constants.Colors.ConditionDisabledColor, "Load order applies the next time a module is loaded.")
end

return Module
