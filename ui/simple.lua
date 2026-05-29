local mq                     = require('mq')
local Icons                  = require('mq.ICONS')
local ImGui                  = require('ImGui')
local Config                 = require('utils.config')
local Globals                = require("utils.globals")
local Ui                     = require('utils.ui')

local SimpleUI               = { _version = '1.0', _name = "SimpleUI", _author = 'Derple', }
SimpleUI.__index             = SimpleUI
SimpleUI.selectedSimplePanel = "General"

function SimpleUI:RenderSimplePanelOption(optionLabel, optionName)
    if ImGui.Selectable(optionLabel, self.selectedSimplePanel == optionName) then
        self.selectedSimplePanel = optionName
    end
end

function SimpleUI:RenderMainWindow(_, openGUI, flags)
    local shouldDrawGUI = true

    if not Globals.Minimized then
        if Config:GetSetting('MainWindowLocked') then
            flags = bit32.bor(flags, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize)
        end

        openGUI, shouldDrawGUI = ImGui.Begin(Ui.GetWindowTitle(('RGMercs%s'):format(Globals.PauseMain and " [Paused]" or ""), 'rgmercssimpleui'), openGUI, flags)

        ImGui.PushID("##RGMercsUI_" .. Globals.CurLoadedChar)

        if shouldDrawGUI then
            local _, y = ImGui.GetContentRegionAvail()
            if ImGui.BeginChild("left##RGmercsSimplePanel", ImGui.GetWindowContentRegionWidth() * .3, y - 1, ImGuiChildFlags.Borders) then
                local flags = bit32.bor(ImGuiTableFlags.RowBg, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.BordersV, ImGuiTableFlags.ScrollY)
                if ImGui.BeginTable('configmenu##RGmercsSimplePanel', 1, flags, 0, 0, 0.0) then
                    ImGui.TableNextColumn()
                    self:RenderSimplePanelOption(Icons.FA_COGS .. " General", "General")
                    ImGui.TableNextColumn()
                    self:RenderSimplePanelOption(Icons.FA_HEART .. " Healing", "Healing")
                    ImGui.TableNextColumn()
                    self:RenderSimplePanelOption(Icons.MD_RESTAURANT_MENU .. "Combat", "Combat")
                    ImGui.TableNextColumn()
                    self:RenderSimplePanelOption(Icons.FA_REBEL .. " Spells", "Spells")
                    ImGui.TableNextColumn()
                    ImGui.EndTable()
                end
            end
            ImGui.EndChild()
            ImGui.SameLine()
            local x, _ = ImGui.GetContentRegionAvail()
            if ImGui.BeginChild("right##RGmercsSimplePanel", x, y - 1, ImGuiChildFlags.Borders) then
                local flags = bit32.bor(ImGuiTableFlags.BordersOuter, ImGuiTableFlags.BordersInner)
                if ImGui.BeginTable('rightpanelTable##RGmercsSimplePanel', 1, flags, 0, 0, 0.0) then
                    ImGui.TableNextColumn()

                    local tmp, changed = Ui.RenderOptionToggle("ToggleFullUI", "Toggle Full UI", Config:GetSetting('FullUI'))
                    if changed then
                        Config:SetSetting('FullUI', tmp)
                    end

                    ImGui.TableNextColumn()
                    Ui.RenderText("Simple Panel: " .. self.selectedSimplePanel) -- Instead of this code this should now call to function which render each panel self:RenderGeneralPanel(), etc...
                    ImGui.EndTable()
                end
            end
            ImGui.EndChild()
        end

        ImGui.PopID()

        ImGui.End()
    end

    return openGUI, shouldDrawGUI
end

return SimpleUI
