local mq       = require('mq')
local Icons    = require('mq.ICONS')
local ImGui    = require('ImGui')
local Casting  = require('utils.casting')
local Comms    = require('utils.comms')
local Config   = require('utils.config')
local Core     = require('utils.core')
local Globals  = require('utils.globals')
local ImagesUI = require('ui.images')
local Logger   = require('utils.logger')
local RGShare  = require('utils.rg_config_share')
local Strings  = require('utils.strings')
local Ui       = require('utils.ui')

local HudUI    = { _version = '1.0', _name = "HudUI", _author = 'Derple', }
HudUI.__index  = HudUI
HudUI.Settings = {}
HudUI.InitMsg  = "cmV0dXJuIHsKIFsxXSA9ICJIYXBweSBBcHJpbCBGb29scyBEYXkgZnJvbSBSR01lcmNzISIsCn0="
HudUI.ClickMsg =
"cmV0dXJuIHsKIFsxXSA9ICJBV1csIFlPVSdSRSBOTyBGVU4hISEiLAogWzJdID0gIk1JTklNT0RFIEJFU1QgTU9ERSIsCiBbM10gPSAiWSBVIE5PIExJS0UgTUlOST8hPyIsCiBbNF0gPSAiQlVUVE9OIEVSUk9SLCBQTEVBU0UgVFJZIEFHQUlOISIsCn0="

function HudUI:LoadAllOptions()
    local moduleSettings = Config:GetAllModuleSettings()
    for _, settings in pairs(moduleSettings) do
        for settingName, settingValue in pairs(settings) do
            if not settingName:match("_Popped") and type(settingValue) == 'boolean' then
                local settingDefaults = Config:GetSettingDefaults(settingName)
                self.Settings[settingName] = settingDefaults.DisplayName or settingName
            end
        end
    end

    if tonumber(os.date("%m%d")) == 401 and not Config:GetSetting('ForceAFUIOff') then
        self:AFPopUp(self.InitMsg, 1)
        Config:SetSetting('EnableAFUI', true)
    elseif Config:GetSetting('EnableAFUI') then
        Config:SetSetting('EnableAFUI', false)
    end
end

function HudUI:RenderToggleHud()
    local miniWidth = 210
    local miniHeight = 56
    local enableAFUI = Config:GetSetting("EnableAFUI")

    if enableAFUI then
        miniWidth = 310
        miniHeight = 400
    end

    ImGui.SetNextWindowSize(ImVec2(miniWidth, miniHeight), ImGuiCond.Always)

    local open, show = ImGui.Begin(Ui.GetWindowTitle("RGMercsHUD"), true,
        bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoFocusOnAppearing))
    if not open then show = false end
    if show then
        local btnImg = Globals.LastBurnCheck and ImagesUI.burnImg or ImagesUI.derpImg
        if Globals.PauseMain then
            if ImGui.ImageButton('RGMercsButton', btnImg:GetTextureID(), ImVec2(30, 30), ImVec2(0.0, 0.0), ImVec2(1, 1), Globals.Constants.Colors.Black, Globals.Constants.Colors.Red) then
                if enableAFUI then
                    self:AFPopUp(self.ClickMsg, math.random(4))
                else
                    Globals.Minimized = not Globals.Minimized
                end
            end
            if ImGui.IsItemHovered() then
                Ui.Tooltip("RGMercs is Paused.\n Click to open the main window.")
            end
        else
            if ImGui.ImageButton('RGMercsButton', btnImg:GetTextureID(), ImVec2(30, 30)) then
                if enableAFUI then
                    self:AFPopUp(self.ClickMsg, math.random(4))
                else
                    Globals.Minimized = not Globals.Minimized
                end
            end
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                if Globals.LastBurnCheck then
                    ImGui.TextColored(Globals.GetAlternatingColor(), "RGMercs is BURNING!\nClick to open the main window.")
                else
                    ImGui.Text("RGMercs is Running.\n Click to open the main window.")
                end
                ImGui.EndTooltip()
            end
        end
        if ImGui.BeginPopupContextWindow() then
            local pauseLabel = Globals.PauseMain and "Resume" or "Pause"
            if ImGui.MenuItem(pauseLabel) then
                Globals.PauseMain = not Globals.PauseMain
            end
            ImGui.EndPopup()
        end
        ImGui.SameLine()

        local lbl = Globals.PauseMain and "Paused" or "Running"
        local cursorPos = ImGui.GetCursorPosVec()
        local toggleHeight = 16
        local toggleXPos = ImGui.GetCursorPosX()

        local pause_main, pause_main_pushed = Ui.RenderFancyToggle("##rgmercs_hud_toggle_pause", lbl, not Globals.PauseMain, ImVec2(32, toggleHeight),
            Globals.Constants.Colors.MainButtonUnpausedColor, Globals.Constants.Colors.MainButtonPausedColor, nil, true)
        ImGui.SameLine()
        ImGui.SetCursorPosX(miniWidth - (enableAFUI and 30 or 20) - ImGui.GetStyle().WindowPadding.x)

        if ImGui.SmallButton(Icons.MD_SETTINGS) then
            Config:ClearAllHighlightedModules()
            Config:SetSetting('EnableOptionsUI', not Config:GetSetting('EnableOptionsUI'))
        end

        local cursorPosAfter = ImGui.GetCursorPosVec()

        if pause_main_pushed then
            Globals.PauseMain = not pause_main
        end

        lbl = Config:GetSetting('DoPull') and Strings.PadString("Pulling", 10, false) or "Not Pulling"

        cursorPos.y = cursorPos.y + toggleHeight + ImGui.GetStyle().ItemSpacing.y
        ImGui.SetCursorPos(cursorPos)
        local pull_toggle, pull_toggle_changed = Ui.RenderFancyToggle("##rgmercs_hud_toggle_pulls", lbl, Config:GetSetting('DoPull'), nil,
            Globals.Constants.Colors.MainButtonUnpausedColor, Globals.Constants.Colors.MainButtonPausedColor, nil, true)
        ImGui.SetCursorPos(cursorPosAfter)
        ImGui.Dummy(ImVec2(0, 0))

        if pull_toggle_changed then
            Config:SetSetting('DoPull', not pull_toggle)
            local cmd = Config:GetSetting('DoPull') and "pullstop" or "pullstart"
            Core.DoCmd("/rgl %s", cmd)
        end

        if ImGui.IsKeyPressed(ImGuiKey.Escape) and Config:GetSetting("EscapeMinimizes") and not Globals.Minimized then
            Globals.Minimized = true
        end

        if enableAFUI then
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 25)
            ImGui.Separator()
            for k, displayName in pairs(self.Settings) do
                ImGui.SetCursorPosX(toggleXPos)

                local newTog, changeTog = Ui.RenderFancyToggle("##rgmercs_hud_toggle_" .. k, displayName, Config:GetSetting(k), nil,
                    Globals.Constants.Colors.MainButtonUnpausedColor, Globals.Constants.Colors.MainButtonPausedColor, nil, true)

                if changeTog then
                    Config:SetSetting(k, newTog)
                end
            end
        end
    end
    ImGui.End()
end

function HudUI:AFPopUp(msg, key)
    if msg and key then
        local _, clickMsg = RGShare.ImportConfig(msg)
        Comms.PopUp(clickMsg[key] or "Error")
    end
end

return HudUI
