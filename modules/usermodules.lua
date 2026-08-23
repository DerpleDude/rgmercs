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

--- Puts the user module authoring guide on the clipboard.
function Module:CopyGuideToClipboard()
    local guidePath = string.format("%s/docs/user_modules.md", Globals.ScriptDir)
    local guide = io.open(guidePath, "r")
    if not guide then
        Logger.log_error("\arCould not find the user module guide at: %s", guidePath)
        return
    end

    local contents = guide:read("*all")
    guide:close()
    ImGui.SetClipboardText(contents)
    Logger.log_info("\agThe user module guide has been copied to your clipboard.")
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

function Module:Render()
    local controlPadding = Base.Render(self)

    if not self.ModuleLoaded then return end

    local moduleList = Config:GetSetting('UserModuleList') or {}
    local loadedCount = 0
    for _, listEntry in ipairs(moduleList) do
        if Modules.LoadedUserModules[listEntry.name] then loadedCount = loadedCount + 1 end
    end

    if ImGui.BeginTable("##UserModulesInfo", 2, bit32.bor(ImGuiTableFlags.BordersInner, ImGuiTableFlags.SizingFixedFit),
            ImVec2(ImGui.GetWindowWidth() - (controlPadding + 20), 0)) then
        ImGui.TableNextColumn()
        Ui.RenderText("Modules Folder")
        ImGui.TableNextColumn()
        Ui.RenderText("%s/rgmercs/modules", mq.configDir)
        ImGui.TableNextColumn()
        Ui.RenderText("Loaded")
        ImGui.TableNextColumn()
        Ui.RenderColoredText(loadedCount > 0 and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionDisabledColor,
            "%d of %d", loadedCount, #moduleList)
        ImGui.EndTable()
    end

    if ImGui.SmallButton(Icons.MD_REFRESH .. " Refresh") then
        Modules:RequestUserModuleSync()
    end
    Ui.Tooltip("Rescan the modules folder and apply any changes.")
    ImGui.SameLine()
    if ImGui.SmallButton("Copy Guide") then
        self:CopyGuideToClipboard()
    end
    Ui.Tooltip("Copy the user module authoring guide to your clipboard.")

    ImGui.Separator()

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

    if ImGui.BeginTable("UserModulesTable", 8, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.Resizable)) then
        ImGui.TableSetupColumn('Enabled', ImGuiTableColumnFlags.WidthFixed, 55.0)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, 140.0)
        ImGui.TableSetupColumn('File', ImGuiTableColumnFlags.WidthFixed, 140.0)
        ImGui.TableSetupColumn('Version', ImGuiTableColumnFlags.WidthFixed, 55.0)
        ImGui.TableSetupColumn('Author', ImGuiTableColumnFlags.WidthFixed, 90.0)
        ImGui.TableSetupColumn('ms', ImGuiTableColumnFlags.WidthFixed, 45.0)
        ImGui.TableSetupColumn('Status', ImGuiTableColumnFlags.WidthStretch, 150.0)
        ImGui.TableSetupColumn('Controls', ImGuiTableColumnFlags.WidthFixed, 80.0)
        ImGui.TableHeadersRow()

        for _, row in ipairs(rows) do
            local manifestEntry = row.manifest
            local rowKey = row.idx or manifestEntry.fileName
            local loadable = manifestEntry ~= nil and manifestEntry.error == nil and manifestEntry.collisionWith == nil
            local isLoaded = manifestEntry ~= nil and Modules.LoadedUserModules[row.name] == manifestEntry.filePath

            ImGui.PushID("##_user_module_" .. (row.name or "") .. "_" .. rowKey)

            local canToggle = loadable or row.idx ~= nil

            ImGui.TableNextColumn()
            ImGui.BeginGroup()
            ImGui.BeginDisabled(not canToggle)
            local _, toggled = Ui.RenderOptionToggle("user_module_tggl_" .. rowKey, "", row.enabled)
            ImGui.EndDisabled()
            ImGui.EndGroup()
            if not canToggle then
                Ui.Tooltip("This module can't be loaded until the problem in the Status column is fixed.")
            end
            if toggled then
                if row.idx then
                    self:ToggleModule(row.idx)
                else
                    self:AddModule(manifestEntry)
                end
            end

            ImGui.TableNextColumn()
            Ui.RenderText(row.name or "?")
            if manifestEntry and manifestEntry.about then
                ImGui.SameLine()
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionMidColor, Icons.MD_INFO_OUTLINE)
                Ui.Tooltip(manifestEntry.about)
            end
            if manifestEntry and manifestEntry.replaces and Modules.BuiltInModulePaths[row.name] then
                ImGui.SameLine()
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionMidColor, Icons.MD_SWAP_HORIZ)
                Ui.Tooltip(string.format("Replaces the built-in %s module while enabled.", row.name))
            end
            ImGui.TableNextColumn()
            Ui.RenderText(manifestEntry and manifestEntry.fileName or "-")
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(manifestEntry and manifestEntry.version or "-"))
            ImGui.TableNextColumn()
            Ui.RenderText(tostring(manifestEntry and manifestEntry.author or "-"))

            ImGui.TableNextColumn()
            local frameTime = Modules.UserModuleFrameTimes[row.name]
            if isLoaded and frameTime then
                Ui.RenderColoredText(frameTime < 5 and Globals.Constants.Colors.ConditionPassColor or
                    (frameTime < 15 and Globals.Constants.Colors.ConditionMidColor or Globals.Constants.Colors.ConditionFailColor),
                    "%d", math.floor(frameTime + 0.5))
                Ui.Tooltip("Average time this module spends in the RGMercs loop each pass, to the nearest millisecond.")
            else
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionDisabledColor, "-")
            end

            ImGui.TableNextColumn()
            if isLoaded then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionPassColor, "Loaded")
            elseif not manifestEntry then
                Ui.RenderColoredText(Globals.Constants.Colors.ConditionFailColor, "File missing")
                Ui.Tooltip("No file in the modules folder matches this entry. It will be forgotten on the next refresh.")
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
            end

            ImGui.PopID()
        end

        ImGui.EndTable()
    end

    Ui.RenderColoredText(Globals.Constants.Colors.ConditionDisabledColor, "Load order applies the next time a module is loaded.")
end

return Module
