local Icons               = require('mq.ICONS')
local Config              = require('utils.config')
local Console             = require('utils.console')
local Globals             = require("utils.globals")
local Ui                  = require('utils.ui')

local ConsoleUI           = { _version = '1.0', _name = "ConsoleUI", _author = 'Derple', }
ConsoleUI.__index         = ConsoleUI
ConsoleUI.logFilterLocked = true

function ConsoleUI:DrawConsole(showPopout)
    local RGMercsConsole = Console:GetConsole("##RGMercs", Config:GetMainOpacity())

    if RGMercsConsole then
        if showPopout then
            ImGui.PushID("##console_popout_btn")
            if ImGui.SmallButton(Icons.MD_OPEN_IN_NEW) then
                Config:SetSetting('PopOutConsole', true)
            end
            Ui.Tooltip("Pop the Console out into its own window.")
            ImGui.NewLine()
            ImGui.PopID()
        end

        if ImGui.BeginTable("##debugoptions", 2, ImGuiTableFlags.None) then
            ImGui.TableSetupColumn("Opt Name", bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.NoResize), 150)
            ImGui.TableSetupColumn("Opt Value", ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableNextColumn()
            Ui.RenderText("Log to File")
            ImGui.TableNextColumn()
            local logToFile, logToFileChanged = Ui.RenderOptionToggle("##log_to_file",
                "", Config:GetSetting('LogToFile'))
            if logToFileChanged then
                Config:SetSetting('LogToFile', logToFile)
            end
            ImGui.TableNextColumn()
            Ui.RenderText("Show Timestamps")
            ImGui.TableNextColumn()
            local logTimestamps, logTimestampsChanged = Ui.RenderOptionToggle("##show_timestamps",
                "", Config:GetSetting('LogTimeStampsToConsole'))
            if logTimestampsChanged then
                Config:SetSetting('LogTimeStampsToConsole', logTimestamps)
            end
            ImGui.TableNextColumn()
            Ui.RenderText("Debug Level")
            ImGui.TableNextColumn()
            local logLevel, _, logLevelChanged = Ui.RenderOption("Combo", Config:GetSetting('LogLevel'), "LogLevelComboBox", false, Globals.Constants.LogLevels)
            if logLevelChanged then
                Config:SetSetting('LogLevel', logLevel)
            end
            ImGui.TableNextColumn()
            Ui.RenderText("Log Filter")
            ImGui.SameLine()
            if ImGui.Button(self.logFilterLocked and Icons.FA_LOCK or Icons.FA_UNLOCK, 22, 22) then
                self.logFilterLocked = not self.logFilterLocked
            end
            ImGui.TableNextColumn()
            ImGui.BeginDisabled(self.logFilterLocked)

            local logFilter, logFilterChanged = ImGui.InputText("##logfilter", Config:GetSetting('LogFilter'))
            if logFilterChanged and not self.logFilterLocked then
                Config:SetSetting('LogFilter', logFilter)
            end

            ImGui.EndDisabled()

            ImGui.EndTable()
        end

        if ImGui.CollapsingHeader("RGMercs Output", ImGuiTreeNodeFlags.DefaultOpen) then
            local cur_x, cur_y = ImGui.GetCursorPos()
            local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
            if not RGMercsConsole.opacity then
                local scroll = ImGui.GetScrollY()
                ImGui.Dummy(contentSizeX, 410)
                ImGui.SetCursorPos(cur_x, cur_y)
                RGMercsConsole:Render(ImVec2(contentSizeX, math.min(400, contentSizeY + scroll)))
            else
                RGMercsConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
            end
            ImGui.Separator()
        end
    end
end

return ConsoleUI
