local mq         = require('mq')
local Icons      = require('mq.ICONS')
local ImGui      = require('ImGui')
local Config     = require('utils.config')
local Globals    = require('utils.globals')
local Targeting  = require('utils.targeting')
local Ui         = require('utils.ui')

local Colors     = Globals.Constants.BasicColors

local TargetUI   = { _version = '1.1', _name = "TargetUI", _author = 'Derple, Algar', }
TargetUI.__index = TargetUI

function TargetUI:RenderContent()
    local target = mq.TLO.Target

    if not target or target.ID() == 0 then
        Ui.RenderText("No Target")
        Ui.RenderFancyHPBar("##TargetHPBar0", 0, 25, false, 1.0)
        return
    end

    local pctHPs = Targeting.GetTargetPctHPs(target)

    local lineStartX = ImGui.GetCursorPosX()

    -- Level Class (left, con-colored)
    ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(Ui.GetConColorBySpawn(target)))
    Ui.RenderText("%d %s", target.Level() or 0, target.Class.ShortName() or "N/A")
    ImGui.PopStyleColor(1)

    -- Icons after level/class
    ImGui.SameLine()
    local los = target.LineOfSight()
    ImGui.TextColored(los and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionFailColor, los and Icons.FA_EYE or Icons.FA_EYE_SLASH)
    Ui.Tooltip("Line of Sight")

    if Globals.AutoTargetIsNamed then
        ImGui.SameLine()
        ImGui.TextColored(IM_COL32(52, 200, 52, 255), Icons.FA_ID_BADGE)
        Ui.Tooltip("Named")
    end

    if target.ID() == Globals.ForceTargetID then
        ImGui.SameLine()
        ImGui.TextColored(IM_COL32(52, 200, 200, 255), Icons.FA_BULLSEYE)
        Ui.Tooltip("Forced Target")
    end

    local burning = Globals.LastBurnCheck and (target.ID() or 0) > 0

    if burning then
        ImGui.SameLine()
        ImGui.TextColored(Globals.GetAlternatingColor(), Icons.FA_FIRE)
        Ui.Tooltip("Burning")
    end

    local distance = target.Distance() or 0
    local distText = string.format("%.1f", distance)
    local distWidth = ImGui.CalcTextSize(distText)
    local nameText = string.format("%s (%s)", target.CleanName() or "", target.ID() or 0)
    local nameWidth = ImGui.CalcTextSize(nameText)

    -- Centered Name (ID) on the same line, fall back to left-aligned if cramped
    ImGui.SameLine()
    local curX = ImGui.GetCursorPosX()
    local rightEdge = curX + ImGui.GetContentRegionAvailVec().x
    local centerX = lineStartX + ((rightEdge - lineStartX) - nameWidth) * 0.5
    local spacing = ImGui.GetStyle().ItemSpacing.x
    if centerX > curX and (centerX + nameWidth + spacing) < (rightEdge - distWidth) then
        ImGui.SetCursorPosX(centerX)
    end

    if math.floor(distance) >= 350 then
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.AssistSpawnFarColor)
    else
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.BrightWhite)
    end
    Ui.RenderText(nameText)
    ImGui.PopStyleColor(1)

    -- Right-aligned distance, colored using MercsStatus thresholds (AssistRange)
    local assistRange = Config:GetSetting('AssistRange')
    local distColor = distance > assistRange and Globals.Constants.Colors.ConditionFailColor
        or distance > assistRange / 2 and Globals.Constants.Colors.ConditionMidColor
        or Globals.Constants.Colors.ConditionPassColor

    ImGui.SameLine()
    local offset = ImGui.GetContentRegionAvailVec().x - distWidth
    if offset > 0 then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + offset)
    end
    ImGui.PushStyleColor(ImGuiCol.Text, distColor)
    Ui.RenderText(distText)
    ImGui.PopStyleColor(1)

    if Config:GetSetting('OverrideHP') > 0 then
        pctHPs = Config:GetSetting('OverrideHP')
    end

    local hpLowOverride, hpHighOverride = nil, nil
    if Config:GetSetting('HPBarStyle') == 2 then
        hpLowOverride  = ImVec4(Ui.GetConColorBySpawn(target))
        hpHighOverride = hpLowOverride
    end

    Ui.RenderFancyHPBar("##TargetHPBar" .. tostring(target.ID()), pctHPs, 25, burning, 1.0, nil, hpLowOverride, hpHighOverride)

    local showToT = Config:GetSetting('ShowTargetOfTarget')
    local showAggro = Config:GetSetting('ShowTargetSecondaryAggro')
    local totHeight = 20

    if Config:GetSetting('ShowTargetBuffs') then
        local iconSize = Config:GetSetting('TargetBuffIconSize')

        ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 0))
        local maxHeight = ImGui.GetContentRegionAvailVec().y - (totHeight + ImGui.GetStyle().ItemSpacing.y * 2)
        if ImGui.BeginChild("##TargetBuffsArea", ImVec2(0, math.max(24 * 2 + 2, maxHeight)), ImGuiChildFlags.None, bit32.bor(ImGuiWindowFlags.NoBackground)) then
            if target.BuffsPopulated() then
                local blinkAtTime = Config:GetSetting('TargetBuffBlinkAtTime')
                ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(2, 2))
                local buffCount = target.BuffCount() or 0
                local buffsPerRow = math.floor((ImGui.GetContentRegionAvailVec().x) / (iconSize + ImGui.GetStyle().ItemSpacing.x))
                local showBuffName = Config:GetSetting('TargetBuffNameTooltip')
                local showBuffDescription = Config:GetSetting('TargetBuffDescriptionTooltip')
                local showBuffCaster = Config:GetSetting('TargetBuffCasterTooltip')
                for i = 1, buffCount do
                    local buff = target.Buff(i)
                    if buff and buff() and buff.ID() ~= 0 then
                        ImGui.PushID(string.format("##target_buff_%d", i))
                        local borderCol = (buff.CasterName() == mq.TLO.Me.Name()) and Colors.Yellow:ToImU32() or nil
                        local doBlink = (math.floor((buff.Duration.TotalSeconds() or 0)) < blinkAtTime)
                        Ui.DrawInspectableSpellIcon(buff, iconSize, doBlink, borderCol)
                        self:RenderTooltipForBuff(buff, target.ID(), showBuffName, showBuffDescription, showBuffCaster)
                        ImGui.PopID()

                        if i == 1 or i % buffsPerRow ~= 0 then
                            ImGui.SameLine()
                        end
                    end
                end
                ImGui.PopStyleVar(1)
            end
        end
        ImGui.EndChild()
        ImGui.PopStyleVar(1)
    end

    if showToT then
        local tot = mq.TLO.Me.TargetOfTarget
        local totValid = tot and (tot.ID() or 0) > 0
        local totName = totValid and (tot.CleanName() or tot.Name() or "") or ""
        local totPctHPs = totValid and (tot.PctHPs() or 0) or 0
        local totBarLabel = totValid and string.format("%s: %d%%", totName, totPctHPs) or "No ToT"
        local totBarId = totValid and ("##TargetOfTargetHPBar" .. tostring(tot.ID())) or "##TargetOfTargetHPBar0"

        local availX = ImGui.GetContentRegionAvailVec().x
        local totWidth = availX * 0.65
        if not showAggro then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (availX - totWidth) / 2)
        end
        if ImGui.BeginChild("##TargetToTBlock", ImVec2(totWidth, 0), ImGuiChildFlags.AutoResizeY, ImGuiWindowFlags.NoBackground) then
            Ui.RenderAnimatedPercentage(totBarId, totPctHPs, totHeight, 0, Globals.Constants.Colors.HPLowColor, Globals.Constants.Colors.HPHighColor, totBarLabel, 1.0)
        end
        ImGui.EndChild()
    end

    if showAggro then
        local aggroName = target.SecondaryAggroPlayer.CleanName() or ""
        local aggroPct = target.SecondaryPctAggro() or 0
        local aggroText = (aggroName ~= "" and aggroPct > 0) and string.format("%s %d%%", aggroName, aggroPct) or ""

        if aggroText ~= "" then
            if showToT then
                ImGui.SameLine()
            end
            local aggroCol = Ui.GetPercentageColor(aggroPct, { Colors.LightRed, Colors.Orange, Colors.Yellow, Colors.LightGreen, })
            ImGui.PushFont(ImGui.GetFont(), ImGui.GetFontSize() * 1.15)
            local textWidth = ImGui.CalcTextSize(aggroText)
            local avail = ImGui.GetContentRegionAvailVec().x
            local offset = avail / 2 - textWidth / 2
            if offset > 0 then
                ImGui.SetCursorPosX(ImGui.GetCursorPosX() + offset)
            end
            local screenPos = ImGui.GetCursorScreenPosVec()
            ImGui.GetWindowDrawList():AddText(ImVec2(screenPos.x + 1, screenPos.y + 1), IM_COL32(0, 0, 0, 230), aggroText)
            ImGui.PushStyleColor(ImGuiCol.Text, aggroCol)
            Ui.RenderText(aggroText)
            ImGui.PopStyleColor()
            ImGui.PopFont()
        end
    end
end

function TargetUI:RenderTooltipForBuff(buff, targetId, showBuffName, showBuffDescription, showBuffCaster)
    if ImGui.IsItemHovered() then
        local toolTip = {}
        if showBuffName then
            local durationPercent = (buff.Spell.Duration.TotalSeconds() or 0) > 0 and
                (buff.Duration.TotalSeconds() or 0) / (buff.Spell.Duration.TotalSeconds() or 1.0) or
                1.0
            table.insert(toolTip,
                { text = string.format("%s (", buff.RankName() or "Unknown"), color = Colors.White, })
            table.insert(toolTip,
                {
                    text = buff.Duration.TimeHMS(),
                    color = durationPercent > 0.6 and Colors.LightGreen or
                        durationPercent > 0.2 and Colors.LightYellow or Colors.LightRed,
                    sameLine = true,
                })
            table.insert(toolTip,
                { text = ")", color = Colors.White, sameLine = true, })
        end

        if showBuffCaster then
            table.insert(toolTip, { text = "Caster:", color = Colors.White, padAfter = 4, })
            table.insert(toolTip, { text = buff.CasterName() or "Unknown Caster", color = Colors.LightOrange, sameLine = true, })
        end

        if showBuffDescription then
            table.insert(toolTip, { text = buff.Description() or "No description available.", color = Colors.LightBlue, })
        end

        if #toolTip > 0 then
            Ui.AnimatedTooltip("##BuffID_" .. tostring(targetId) .. "_" .. tostring(buff.ID()), toolTip)
        end
    end
end

function TargetUI:RenderWindow(flags)
    flags = bit32.bor(flags, ImGuiWindowFlags.NoTitleBar, Config:GetSetting('LockTargetWindow') and bit32.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize) or 0)
    ImGui.SetNextWindowSize(ImVec2(540, 160), ImGuiCond.FirstUseEver)
    local open, show = ImGui.Begin(Ui.GetWindowTitle("Target"), Config:GetSetting('ShowTargetWindow'), flags)
    if show then
        self:RenderContent()
    end
    ImGui.End()
    if not open then
        Config:SetSetting('ShowTargetWindow', false)
    end
end

return TargetUI
