-- Sample Basic Class Module
local mq        = require('mq')
local Base      = require("modules.base")
local Comms     = require("utils.comms")
local Core      = require("utils.core")
local Globals   = require('utils.globals')
local Logger    = require("utils.logger")
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")

local Module    = { _version = '0.1a', _name = "Travel", _author = 'Derple', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })

Module.FAQ                         = {}
Module.CommandHandlers             = {}

Module.TransportSpells             = {}
Module.ButtonWidth                 = 150
Module.ButtonHeight                = 25

Module.TempSettings                = {}
Module.TempSettings.ShouldRequest  = true
Module.TempSettings.SelectedPorter = 1
Module.TempSettings.PorterList     = {}
Module.TempSettings.FilteredList   = {}
Module.TempSettings.FilterText     = ""

local travelColors                 = {}
travelColors["Group v2"]           = {}
travelColors["Group v1"]           = {}
travelColors["Self"]               = {}
travelColors["Single"]             = {}

-- evac
travelColors["Group v2"]["r"]      = 220
travelColors["Group v2"]["g"]      = 80
travelColors["Group v2"]["b"]      = 80

-- group port
travelColors["Group v1"]["r"]      = 141
travelColors["Group v1"]["g"]      = 80
travelColors["Group v1"]["b"]      = 250

-- self gate
travelColors["Self"]["r"]          = 200
travelColors["Self"]["g"]          = 240
travelColors["Self"]["b"]          = 80

-- translocation
travelColors["Single"]["r"]        = 180
travelColors["Single"]["g"]        = 80
travelColors["Single"]["b"]        = 180

Module.DefaultConfig               = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
}

function Module:New()
    return Base.New(self)
end

function Module:TravelerUpdate(newData)
    if newData and newData.Server == Globals.CurServer then
        Logger.log_debug("\agGot new Traveler update from: \am%s", newData.Name)

        self.TransportSpells[newData.Name] = newData.Tabs and newData or nil

        self:CreatePorterList()
        self:GenerateFilteredPortsList()
    end
end

function Module:CreatePorterList()
    local selectedName = self.TempSettings.PorterList[self.TempSettings.SelectedPorter]

    self.TempSettings.PorterList = {}
    for k, v in pairs(self.TransportSpells) do
        if self:IsPorterRunning(k) then
            table.insert(self.TempSettings.PorterList, k)
        end
    end
    table.sort(self.TempSettings.PorterList)

    self.TempSettings.SelectedPorter = 1
    for index, porterName in ipairs(self.TempSettings.PorterList) do
        if porterName == selectedName then
            self.TempSettings.SelectedPorter = index
            break
        end
    end
end

--- Returns true if the porter is this character or a peer whose live heartbeat comes from a running RGMercs.
---@param porterName string Character name the porter's entry is keyed by.
---@return boolean
function Module:IsPorterRunning(porterName)
    if porterName == Globals.CurLoadedChar then return true end

    local state = (Comms.GetPeerHeartbeatByName(porterName).Data or {}).State
    return state ~= nil and state ~= "Standalone"
end

function Module:SendPorterInfo()
    Logger.log_debug("\atBroadcasting TravelerUpdate")
    Comms.BroadcastMessage(self._name, "TravelerUpdate", self.TransportSpells[Globals.CurLoadedChar])
end

function Module:RequestPorterInfo()
    Comms.BroadcastMessage(self._name, "SendPorterInfo")
end

--- Rebuilds this character's ports from the spellbook (WIZ/DRU only), or drops them, and tells peers.
function Module:BuildPorterInfo()
    if Core.MyClassIs("wiz") or Core.MyClassIs("dru") then
        local tabsTable = {}

        for i = 1, Globals.Constants.SpellBookSlots do
            local spell = mq.TLO.Me.Book(i)
            if spell.Category() == "Transport" then
                Logger.log_debug("\ayFound Transport Spell: <\ay%-15s\ay> => \at'%s'\ay \ao(%d) \ay[\am%s\ay]", spell.Subcategory(), spell.RankName(), spell.ID(),
                    spell.TargetType())
                local subCat = spell.Subcategory()
                tabsTable[subCat] = tabsTable[subCat] or {}
                local heading = math.floor(((((512 - spell.Base(4)()) % 512) / 32) + 1))
                table.insert(tabsTable[subCat],
                    {
                        Name = spell.RankName(),
                        Type = spell.TargetType(),
                        Level = spell.Level(),
                        TeleportText = string.format("Teleports %s to %d, %d, %d in %s facing %s", spell.TargetType(), spell.Base(1)() or 0, spell.Base(2)() or 0,
                            spell.Base(3)() or 0, spell.Extra(), Globals.Constants.Headings[heading] or "Unknown"),

                        SearchFields = string.format("%s,%s,%s,%s", spell.RankName(), spell.TargetType(), subCat, spell.Extra()):lower(),
                    })
            end
        end

        local sortedTabNames = {}
        for k in pairs(tabsTable) do
            table.insert(sortedTabNames, k)
        end

        table.sort(sortedTabNames)

        self.TransportSpells[Globals.CurLoadedChar] = {
            Class = mq.TLO.Me.Class.ShortName():lower(),
            Name = Globals.CurLoadedChar,
            Server = Globals.CurServer,
            Tabs = tabsTable,
            SortedTabNames = sortedTabNames,
        }

        -- notify everyone else of my state...
        self:SendPorterInfo()
    else
        self.TransportSpells[Globals.CurLoadedChar] = nil
        Comms.BroadcastMessage(self._name, "TravelerUpdate", { Name = Globals.CurLoadedChar, Server = Globals.CurServer, })
    end

    self:CreatePorterList()
    self:GenerateFilteredPortsList()
end

function Module:Init()
    Logger.log_debug("Travel Module Loaded.")

    self:LoadSettings()
    self:BuildPorterInfo()

    return { self = self, defaults = self.DefaultConfig, }
end

function Module:GetColorForType(type)
    return
        ((travelColors[type] and (travelColors[type]["r"] or 100) or 100) / 255),
        ((travelColors[type] and (travelColors[type]["g"] or 100) or 100) / 255),
        ((travelColors[type] and (travelColors[type]["b"] or 100) or 100) / 255), 1.0
end

function Module:GenerateFilteredPortsList()
    self.TempSettings.FilteredList = {}
    self.TempSettings.FilteredList.Tabs = {}
    self.TempSettings.FilteredList.SortedTabNames = {}

    if #self.TempSettings.PorterList == 0 or not self.TempSettings.PorterList[self.TempSettings.SelectedPorter] then
        return
    end

    for porter, data in pairs(self.TransportSpells or {}) do
        if porter == self.TempSettings.PorterList[self.TempSettings.SelectedPorter] then
            for subCat, spellList in pairs(data.Tabs or {}) do
                for _, spellData in ipairs(spellList) do
                    local s, _ = string.find(spellData.SearchFields, self.TempSettings.FilterText:lower())
                    if self.TempSettings.FilterText:len() >= 1 and (s ~= nil) then
                        self.TempSettings.FilteredList.Tabs[subCat] = self.TempSettings.FilteredList.Tabs[subCat] or {}
                        table.insert(self.TempSettings.FilteredList.Tabs[subCat], spellData)
                    elseif self.TempSettings.FilterText:len() < 1 then
                        self.TempSettings.FilteredList.Tabs[subCat] = self.TempSettings.FilteredList.Tabs[subCat] or {}
                        table.insert(self.TempSettings.FilteredList.Tabs[subCat], spellData)
                    end
                end
            end
        end
    end

    for k, _ in pairs(self.TempSettings.FilteredList.Tabs) do
        table.insert(self.TempSettings.FilteredList.SortedTabNames, k)
    end
    table.sort(self.TempSettings.FilteredList.SortedTabNames)
end

function Module:ShouldRender()
    return #self.TempSettings.PorterList > 0
end

function Module:Render()
    Base.Render(self)
    ImGui.NewLine()

    local width = ImGui.GetWindowWidth()
    local buttonsPerRow = math.max(1, math.floor(width / self.ButtonWidth))
    local changed

    if #self.TempSettings.PorterList > 0 then
        self.TempSettings.SelectedPorter, changed = ImGui.Combo("Select Character", self.TempSettings.SelectedPorter, self.TempSettings.PorterList)
        if changed then
            self:GenerateFilteredPortsList()
        end

        local selectedPorter = self.TempSettings.PorterList[self.TempSettings.SelectedPorter]
        local groupedWithPorter = mq.TLO.Group.Member(selectedPorter)() and true or false

        Ui.RenderText("Grouped with %s: ", selectedPorter)
        ImGui.SameLine()

        if groupedWithPorter then
            ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionPassColor)
        else
            ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.ConditionFailColor)
        end
        Ui.RenderText(groupedWithPorter and "Yes" or "No")
        ImGui.PopStyleColor()

        ImGui.Separator()
        Ui.RenderText("Filter Ports: ")
        ImGui.SameLine()
        self.TempSettings.FilterText, changed = ImGui.InputText("##text_filter", self.TempSettings.FilterText)
        if changed then
            self:GenerateFilteredPortsList()
        end

        if ImGui.BeginTabBar("Tabs", ImGuiTabBarFlags.FittingPolicyScroll) then
            for _, k in ipairs(self.TempSettings.FilteredList.SortedTabNames) do
                -- why is this here? ImGui.TableNextColumn()
                if ImGui.BeginTabItem(k) then
                    ImGui.BeginTable("Buttons", buttonsPerRow)
                    for _, sv in ipairs(self.TempSettings.FilteredList.Tabs[k]) do
                        ImGui.TableNextColumn()
                        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.Black)
                        ImGui.PushStyleColor(ImGuiCol.Button, self:GetColorForType(sv.Type))
                        if ImGui.Button(sv.Name, self.ButtonWidth, self.ButtonHeight) then
                            local cmd = string.format("/rgl cast \"%s\"", sv.Name)
                            if sv.Type == "Single" then
                                cmd = cmd .. string.format(" %d", Targeting.GetTargetID())
                            end

                            if selectedPorter ~= mq.TLO.Me.DisplayName() then
                                cmd = string.format("/dex %s %s", selectedPorter, cmd)
                            end

                            Core.DoCmd(cmd)
                        end
                        ImGui.PopStyleColor(2)
                        Ui.MultilineTooltipWithColors({
                            { text = string.format("Spell: %s", sv.Name),  color = Globals.Constants.Colors.FAQUsageAnswerColor, },
                            { text = string.format("Level: %d", sv.Level), color = Globals.Constants.Colors.ConditionPassColor, },
                            { text = "",                                   color = Globals.Constants.Colors.FAQDescColor, },
                            { text = sv.TeleportText,                      color = Globals.Constants.Colors.FAQDescColor, },
                        })
                    end
                    ImGui.EndTable()
                    ImGui.EndTabItem()
                end
            end

            ImGui.EndTabBar();
        end
    else
        Ui.RenderText("No Porters Loaded...")
    end
end

function Module:GiveTime()
    -- Main Module logic goes here.
    if self.TempSettings.ShouldRequest then
        self.TempSettings.ShouldRequest = false
        self:RequestPorterInfo()
    end

    local runningPorters = 0
    for porterName in pairs(self.TransportSpells) do
        if self:IsPorterRunning(porterName) then
            runningPorters = runningPorters + 1
        end
    end

    local listStale = runningPorters ~= #self.TempSettings.PorterList
    for _, porterName in ipairs(self.TempSettings.PorterList) do
        if not self:IsPorterRunning(porterName) then
            listStale = true
            break
        end
    end

    if listStale then
        self:CreatePorterList()
        self:GenerateFilteredPortsList()
    end
end

return Module
