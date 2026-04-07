local mq            = require('mq')
local CommitVersion = require('extras.version')
local OptionsUI     = require("ui.options")
local ImGui         = require('ImGui')
local Config        = require('utils.config')
local Globals       = require('utils.globals')
local Comms         = require('utils.comms')
local Ui            = require('utils.ui')
local Icons         = require('mq.ICONS')
local ImageUI       = require('ui.images')
local Core          = require('utils.core')
local Targeting     = require('utils.targeting')
local Casting       = require('utils.casting')
local Combat        = require('utils.combat')
local Modules       = require('utils.modules')
local Movement      = require('utils.movement')
local ConsoleUI     = require('ui.console')

local StandardUI    = { _version = '1.0', _name = "StandardUI", _author = 'Derple', }
StandardUI.__index  = StandardUI

function StandardUI:renderModulesTabs()
    if not Config:SettingsLoaded() then return end

    for _, name in ipairs(Modules:GetModuleOrderedNames()) do
        if Modules:ExecModule(name, "ShouldRender") and not Config:GetSetting(name .. "_Popped", true) then
            if ImGui.BeginTabItem(name) then
                Modules:ExecModule(name, "Render")
                ImGui.EndTabItem()
            end
        end
    end
end

function StandardUI:RenderTargetInfo()
    ImGui.TableNextColumn()
    Ui.RenderText("Target")
    ImGui.TableNextColumn()

    local assistSpawn = mq.TLO.Target

    if not assistSpawn or assistSpawn.ID() == 0 then
        Ui.RenderText("None")
        return
    end

    if math.floor(assistSpawn.Distance() or 0) >= 350 then
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.AssistSpawnFarColor)
    else
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.BrightWhite)
    end

    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))
    Ui.RenderText("%s (%s) [", assistSpawn.CleanName() or "", assistSpawn.ID() or 0)
    ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(Ui.GetConColorBySpawn(assistSpawn)))

    ImGui.SameLine()
    Ui.RenderText("%d %s", assistSpawn.Level() or 0, assistSpawn.Class.ShortName() or "N/A")

    ImGui.PopStyleColor(1)

    ImGui.SameLine()
    Ui.RenderText("] HP: %d%% Dist: %d ", assistSpawn.PctHPs() or 0, assistSpawn.Distance() or 0)
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(1)

    ImGui.SameLine()
    local los = assistSpawn.LineOfSight()
    ImGui.TextColored(los and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionFailColor, los and Icons.FA_EYE or Icons.FA_EYE_SLASH)
end

function StandardUI:RenderAutoTargetInfo(assistSpawn)
    local pctHPs = assistSpawn and (assistSpawn.PctHPs() or 0) or 0

    if not assistSpawn or assistSpawn.ID() == 0 then
        Ui.RenderText("No Auto Target")
        return
    end

    if math.floor(assistSpawn.Distance() or 0) >= 350 then
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.AssistSpawnFarColor)
    else
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.BrightWhite)
    end
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))
    Ui.RenderText("%s (%s) [", assistSpawn.CleanName() or "", assistSpawn.ID() or 0)

    ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(Ui.GetConColorBySpawn(assistSpawn)))
    ImGui.SameLine()
    Ui.RenderText("%d %s", assistSpawn.Level() or 0, assistSpawn.Class.ShortName() or "N/A")
    ImGui.PopStyleColor(1)

    ImGui.SameLine()
    Ui.RenderText("] HP: %d%% Dist: %d ", assistSpawn.PctHPs() or 0, assistSpawn.Distance() or 0)
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(1)

    ImGui.SameLine()
    local los = assistSpawn.LineOfSight()
    ImGui.TextColored(los and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionFailColor, los and Icons.FA_EYE or Icons.FA_EYE_SLASH)
    Ui.Tooltip("Line of Sight")

    if Globals.AutoTargetIsNamed then
        ImGui.SameLine()
        ImGui.TextColored(IM_COL32(52, 200, 52, 255), Icons.FA_ID_BADGE)
        Ui.Tooltip("Named")
    end

    if assistSpawn.ID() == Globals.ForceTargetID then
        ImGui.SameLine()
        ImGui.TextColored(IM_COL32(52, 200, 200, 255), Icons.FA_BULLSEYE)
        Ui.Tooltip("Forced Target")
    end

    local burning = Globals.LastBurnCheck and assistSpawn.ID() > 0

    if burning then
        ImGui.SameLine()
        ImGui.TextColored(Globals.GetAlternatingColor(), Icons.FA_FIRE)
        Ui.Tooltip("Burning")
    end

    return pctHPs, burning
end

function StandardUI:RenderForceBurnButton()
    ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.BurnFlashColorOne)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, Globals.Constants.Colors.BurnFlashColorTwo)
    local burnLabel = (Targeting.ForceBurnTargetID > 0 and Targeting.ForceBurnTargetID == mq.TLO.Target.ID()) and " FORCE BURN ACTIVATED " or " FORCE BURN THIS TARGET! "
    if ImGui.SmallButton(Icons.FA_FIRE .. burnLabel .. Icons.FA_FIRE) then
        local assistSpawn = Targeting.GetAutoTarget()
        Comms.SendAllPeersDoCmd(true, true, "/squelch /rgl burnnow %d", assistSpawn.ID())
    end
    ImGui.PopStyleColor(2)
end

function StandardUI:RenderTarget()
    local warningMessage = Config.TempSettings.AssistWarning

    if mq.TLO.Plugin("MQ2AdvPath").IsLoaded() and mq.TLO.AdvPath ~= nil and mq.TLO.AdvPath.Following() then
        warningMessage = 'AFOLLOW ("FOLLOW ME") ENGAGED - THIS MAY INTERFERE WITH RGMERCS!'
    end

    if warningMessage then
        ImGui.TextColored(Globals.GetAlternatingColor(), warningMessage)
    end

    local assistSpawn = Targeting.GetAutoTarget()

    if Config:GetSetting('DisplayManualTarget') and (not assistSpawn or not assistSpawn() or assistSpawn.ID() == 0) then
        assistSpawn = mq.TLO.Target
    end

    local pctHPs, burning = self:RenderAutoTargetInfo(assistSpawn)
    if Config:GetSetting('OverrideHP') > 0 then
        pctHPs = Config:GetSetting('OverrideHP')
    end

    local hpLowOverride, hpHighOverride = nil, nil
    if Config:GetSetting('HPBarStyle') == 2 then
        hpLowOverride = ImVec4(Ui.GetConColorBySpawn(assistSpawn))
        hpHighOverride = hpLowOverride
    end

    Ui.RenderFancyHPBar("##AutoTargetHPBar" .. tostring(assistSpawn.ID()), pctHPs, 25, burning, 1.0, nil, hpLowOverride, hpHighOverride)
    self:RenderForceBurnButton()
end

function StandardUI:RenderWindowControls()
    local position = ImGui.GetCursorPosVec()
    local smallButtonSize = 32

    local windowControlPos = ImVec2(ImGui.GetWindowWidth() - (smallButtonSize * 3), 0)
    ImGui.SetCursorPos(windowControlPos)

    if ImGui.SmallButton(Icons.MD_SETTINGS) then
        Config:ClearAllHighlightedModules()
        Config:SetSetting('EnableOptionsUI', not Config:GetSetting('EnableOptionsUI'))
    end
    Ui.Tooltip("Open the RGMercs Options Window")
    ImGui.SameLine()

    if ImGui.SmallButton((Config:GetSetting('MainWindowLocked') or false) and Icons.FA_LOCK or Icons.FA_UNLOCK) then
        Config:SetSetting('MainWindowLocked', not Config:GetSetting('MainWindowLocked'))
    end
    Ui.Tooltip("Lock the Main Window")
    ImGui.SameLine()

    if ImGui.SmallButton(Icons.FA_WINDOW_MINIMIZE) then
        Globals.Minimized = true
    end
    Ui.Tooltip("Activate Mini Mode")

    ImGui.SetCursorPos(position)
end

function StandardUI:RenderMainWindow(imgui_style, openGUI, flags)
    local shouldDrawGUI = true

    if not Globals.Minimized then
        if Config:GetSetting('MainWindowLocked') then
            flags = bit32.bor(flags, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize)
        end

        ImGui.SetNextWindowSize(ImVec2(600, 400), ImGuiCond.FirstUseEver)

        openGUI, shouldDrawGUI = ImGui.Begin(Ui.GetWindowTitle(('RGMercs%s'):format(Globals.PauseMain and " [Paused]" or ""), 'rgmercsui'), openGUI, flags)

        ImGui.PushID("##RGMercsUI_" .. Globals.CurLoadedChar)

        if shouldDrawGUI then
            ImGui.BeginChild("##RGMercsMainHeader", ImVec2(0, 0), bit32.bor(ImGuiChildFlags.AlwaysAutoResize, ImGuiChildFlags.AutoResizeY),
                bit32.bor(ImGuiWindowFlags.NoScrollbar))

            local imgDisplayed = Globals.LastBurnCheck and ImageUI.burnImg or ImageUI.derpImg
            Ui.RenderLogo(imgDisplayed:GetTextureID())
            ImGui.SameLine()
            local titlePos = ImGui.GetCursorPosVec()
            ImGui.PushFont(ImGui.GetFont(), ImGui.GetFontSize() * 1.05)
            Ui.RenderText("RGMercs %s [Build: %s]",
                Config._version,
                CommitVersion.version or "None"
            )
            ImGui.PopFont()
            titlePos = ImVec2(titlePos.x, titlePos.y + ImGui.GetTextLineHeightWithSpacing())
            ImGui.SetCursorPos(titlePos)

            Ui.RenderText("Class Config: ")
            ImGui.SameLine()

            local version = Modules:ExecModule("Class", "GetVersionString")
            Ui.RenderHyperText(version, IM_COL32(255, 255, 255, 255), IM_COL32(52, 52, 255, 255),
                function()
                    OptionsUI:OpenAndSetSearchFilter("what is the current status of this class config", "Commands/FAQ")
                end)
            Ui.Tooltip("Click to display notes about the status of this class config.")
            ImGui.SameLine()
            if ImGui.SmallButton(Icons.MD_INFO_OUTLINE) then
                OptionsUI:OpenAndSetSearchFilter("what is the current status of this class config", "Commands/FAQ")
            end
            Ui.Tooltip("Click to display notes about the status of this class config.")

            titlePos = ImVec2(titlePos.x, titlePos.y + ImGui.GetTextLineHeightWithSpacing())
            ImGui.SetCursorPos(titlePos)

            Ui.RenderText("Author(s): %s", Modules:ExecModule("Class", "GetAuthorString"))

            ImGui.NewLine()

            self:RenderWindowControls()

            if not Globals.PauseMain then
                ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.MainButtonUnpausedColor)
                ImGui.PushStyleColor(ImGuiCol.ButtonHovered, Ui.ImVec4ToColor(Globals.Constants.Colors.MainButtonUnpausedColor))
            else
                ImGui.PushStyleColor(ImGuiCol.Button, Globals.Constants.Colors.MainButtonPausedColor)
                ImGui.PushStyleColor(ImGuiCol.ButtonHovered, Ui.ImVec4ToColor(Globals.Constants.Colors.MainButtonPausedColor))
            end

            local pauseLabel = Globals.PauseMain and "PAUSED" or "Running"
            if Globals.BackOffFlag then
                pauseLabel = pauseLabel .. " [Backoff]"
            end

            local availableWidth = ImGui.GetContentRegionAvailVec().x

            ImGui.PushFont(ImGui.GetFont(), ImGui.GetFontSize() * 1.25)
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (availableWidth * .05) / 2)
            if Ui.AnimatedButton("##mercsmainbutton", pauseLabel, ImVec2(availableWidth * .95, 40)) then
                Globals.PauseMain = not Globals.PauseMain
            end
            ImGui.PopFont()

            ImGui.PopStyleColor(2)

            self:RenderTarget()

            ImGui.EndChild()

            ImGui.Separator()

            ImGui.BeginChild("##RGMercsMainBody", ImVec2(0, 0), bit32.bor(ImGuiChildFlags.None), bit32.bor(ImGuiWindowFlags.None))

            ImGui.NewLine()

            if ImGui.BeginTabBar("RGMercsTabs", ImGuiTabBarFlags.Reorderable) then
                ImGui.SetItemDefaultFocus()
                if ImGui.BeginTabItem("RGMercsMain") then
                    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))

                    ImGui.BeginTable("##MainInfoTable", 2, bit32.bor(ImGuiTableFlags.BordersInner, ImGuiTableFlags.SizingFixedFit))
                    ImGui.TableNextColumn()
                    Ui.RenderText("Current State")
                    ImGui.TableNextColumn()
                    Ui.RenderColoredText(Combat.GetCachedCombatState() == "Combat" and Globals.Constants.Colors.MainCombatColor or Globals.Constants.Colors.MainDowntimeColor,
                        "%s", Combat.GetCachedCombatState() or "N/A")
                    ImGui.TableNextColumn()
                    Ui.RenderText("Hater Count")
                    ImGui.TableNextColumn()
                    Ui.RenderColoredText((Targeting.GetXTHaterCount() or 0) > 0 and Globals.Constants.Colors.ConditionMidColor or Globals.Constants.Colors.ConditionPassColor, "%d",
                        Targeting.GetXTHaterCount() or 0)
                    ImGui.TableNextColumn()
                    Ui.RenderText("MA")
                    ImGui.TableNextColumn()

                    if Config.TempSettings.AssistWarning and Core.IAmMA() then
                        Ui.RenderColoredText(Globals.Constants.Colors.ConditionMidColor, "%s (Fallback Mode)", (Core.GetMainAssistSpawn().CleanName() or "None"))
                    else
                        Ui.RenderColoredText(Globals.Constants.Colors.ConditionPassColor, "%s", (Core.GetMainAssistSpawn().CleanName() or "None"))
                    end
                    self:RenderTargetInfo()
                    ImGui.TableNextColumn()
                    Ui.RenderText("Stuck To")
                    ImGui.TableNextColumn()
                    Ui.RenderColoredText(mq.TLO.Stick.Active() and ImVec4(Ui.GetConColorBySpawn(mq.TLO.Spawn(mq.TLO.Stick.StickTarget()))) or ImVec4(1, 1, 1, 1),
                        "%s ", (mq.TLO.Stick.Active() and (mq.TLO.Stick.StickTargetName() or "None") or "None"))
                    ImGui.SameLine()
                    Ui.RenderText("[")
                    ImGui.SameLine()
                    Ui.RenderColoredText(mq.TLO.Stick.Active() and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionDisabledColor,
                        "%s", (mq.TLO.Stick.Active() and Movement:GetLastStickCmd() or "N/A"))
                    ImGui.SameLine()
                    Ui.RenderText("] ")
                    ImGui.SameLine()
                    Ui.RenderText("<")
                    ImGui.SameLine()
                    Ui.RenderColoredText(Globals.Constants.Colors.LightBlue, "%s", Movement:GetTimeSinceLastStick() or "0s")
                    ImGui.SameLine()
                    Ui.RenderText(">")
                    ImGui.TableNextColumn()
                    Ui.RenderText("Last Nav")
                    ImGui.TableNextColumn()
                    if mq.TLO.Navigation.MeshLoaded() then
                        Ui.RenderColoredText(Globals.Constants.Colors.ConditionPassColor, "%s ", Movement:GetLastNavCmd() or "N/A")
                    else
                        Ui.RenderColoredText(Globals.GetAlternatingColor(), "%s ", "Mesh Not Loaded")
                    end
                    ImGui.SameLine()
                    Ui.RenderText("<")
                    ImGui.SameLine()
                    Ui.RenderColoredText(Globals.Constants.Colors.LightBlue, "%s", Movement:GetTimeSinceLastNav() or "0s")
                    ImGui.SameLine()
                    Ui.RenderText(">")
                    ImGui.PopStyleVar(1)

                    ImGui.EndTable()

                    ImGui.NewLine()

                    if ImGui.CollapsingHeader("Assist List") then
                        ImGui.Indent()
                        Ui.RenderList("AssistList", true)
                        ImGui.Unindent()
                    end

                    if ImGui.CollapsingHeader("Heal List") then
                        ImGui.Indent()
                        Ui.RenderList("HealList", false)
                        ImGui.Unindent()
                    end

                    if not Config:GetSetting('PopOutForceTarget') then
                        if ImGui.CollapsingHeader("Force Target") then
                            ImGui.Indent()
                            Ui.RenderForceTargetList(true)
                            ImGui.Unindent()
                        end
                    end

                    if not Config:GetSetting('PopOutMercsStatus') then
                        if ImGui.CollapsingHeader("Mercs Status") then
                            ImGui.Indent()
                            Ui.RenderMercsStatus(true)
                            ImGui.Unindent()
                        end
                    end
                    ImGui.EndTabItem()
                end

                self:renderModulesTabs()

                ImGui.EndTabBar();
            end

            ImGui.Separator()
            if not Config:GetSetting('PopOutConsole') then
                if ImGui.CollapsingHeader("Console") then
                    ConsoleUI:DrawConsole(true)
                end
            end

            ImGui.EndChild()
        end

        ImGui.PopID()

        ImGui.End()
    end

    return openGUI
end

return StandardUI
