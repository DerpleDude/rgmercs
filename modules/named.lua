-- Sample Named Class Module
local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Modules      = require("utils.modules")
local Targeting    = require("utils.targeting")
local Ui           = require("utils.ui")
local Icons        = require('mq.ICONS')
local NamedDefault = require("namedlist.named_default")
local NamedEQMight = require("namedlist.named_eqmight")
local Base         = require("modules.base")

local Module       = { _version = '1.1', _name = "Named", _author = 'Derple, Algar, Grimmier', }
Module.__index     = Module
setmetatable(Module, { __index = Base, })

Module.CachedNamedList = {}
Module.CommandHandlers = {}

Module.NamedList       = {}
Module.LastNamedCheck  = 0

Module.DefNamed        = Globals.CurServer == "EQ Might" and (NamedEQMight or {}) or (NamedDefault or {})

Module.DefaultConfig   = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['CustomNamedList'] = {
        DisplayName = "Custom Named List",
        Type = "Custom",
        Default = {},
        Scope = "server",
        OnChange = function() Modules.ModuleList["Named"].LastZoneID = -1 end,
        FAQ = "Can I add my own named NPCs to RGMercs?",
        Answer = "Open the Named module tab and add your current target via the Custom Named List editor. " ..
            "This per-server, per-zone list is shared in real-time with all RGMercs peers on this machine.\n\n" ..
            "From the command line: /rgl namedadd \"<name>\" or /rgl nameddelete \"<name>\".",
    },
}

Module.FAQ             = {
    {
        Question = "Why am I not taking any special actions on a Named, boss, or mission mob?",
        Answer =
            "  RGMercs default class configs fully support burning, using defenses, or other special actions on Named mobs, " ..
            "however, your target must be identified as such. There are several ways to make this happen:\n\n" ..
            "  1) Add Named NPCs using the UI on the Named module tab, or using the CLI (search the command list for \"named\").\n\n" ..
            "  2) The built-in Named List: RGMercs has a list of known nameds per zone. If a mob is on the list, RGMercs treats it as a Named automatically.\n\n" ..
            "  3) SpawnMaster (optional): If 'Check SM For Named' is enabled and MQ2SpawnMaster is loaded, RGMercs queries it via TLO. Useful if you already maintain SpawnMaster watch lists.\n\n" ..
            "  4) Alert Master (optional): If 'Check AM For Named' is enabled and the Alert Master script is loaded, RGMercs queries it via TLO. Useful if you already maintain Alert Master alert lists.\n\n" ..
            "  Specific feedback on missing, incorrect, or otherwise erroneous entries on the built-in RGMercs Named List is always welcome!\n\n",
        Settings_Used = "",
    },
}

function Module:New()
    return Base.New(self)
end

function Module:Render()
    Base.Render(self)
    Ui.RenderZoneNamed()
    ImGui.NewLine()
    self:RenderCustomNamedList()
end

function Module:GiveTime()
    -- Main Module logic goes here.
    if Globals.GetTimeSeconds() - self.LastNamedCheck > 1 then
        self.LastNamedCheck = Globals.GetTimeSeconds()
        self:CheckZoneNamed()
    end
end

--- Caches the named list in the zone
function Module:RefreshNamedCache()
    local curZone = mq.TLO.Zone.ID()
    -- LastUserList identity catches cross-instance edits; local edits invalidate via OnChange.
    local userList = Config:GetSetting('CustomNamedList') or {}
    if self.LastZoneID ~= curZone or self.LastUserList ~= userList then
        self.LastZoneID = curZone
        self.LastUserList = userList
        self.NamedList = {}
        local zoneName = mq.TLO.Zone.Name():lower()

        for _, n in ipairs(self.DefNamed[zoneName] or {}) do
            self.NamedList[n] = true
        end

        zoneName = mq.TLO.Zone.ShortName():lower()

        for _, n in ipairs(self.DefNamed[zoneName] or {}) do
            self.NamedList[n] = true
        end

        for _, n in ipairs(userList[zoneName] or {}) do
            self.NamedList[n] = true
        end
    end
end

function Module:CheckZoneNamed()
    self:RefreshNamedCache()
    local upNameds = {}
    local tmpTbl = {}

    local namedSpawns = mq.getFilteredSpawns(function(spawn)
        return self:IsNamed(spawn) and spawn.Type() == "NPC"
    end)

    for _, spawn in ipairs(namedSpawns) do
        local name = spawn.CleanName()
        table.insert(tmpTbl, { Name = name, Spawn = spawn, Distance = spawn and spawn.Distance() or 9999, Loc = spawn and spawn.LocYXZ() or "0,0,0", })
        upNameds[name] = true
    end

    for name, _ in pairs(self.NamedList) do
        if not upNameds[name] then
            table.insert(tmpTbl, { Name = name, Spawn = nil, Distance = 9999, Loc = "0,0,0", })
        end
    end

    table.sort(tmpTbl, function(a, b)
        return a.Distance < b.Distance
    end)

    self.CachedNamedList = tmpTbl
end

function Module:GetNamedList()
    return self.CachedNamedList
end

--- Checks if the given spawn is a named entity.
--- @param spawn MQSpawn The spawn object to check.
--- @return boolean True if the spawn is named, false otherwise.
function Module:IsNamed(spawn)
    if not spawn or not spawn() then return false end

    if Targeting.ForceNamed then return true end

    self:RefreshNamedCache()

    local cleanNameFixed = spawn.CleanName()
    if cleanNameFixed then
        -- if first or last character is a space then remove it.
        while cleanNameFixed:sub(1, 1) == " " do
            cleanNameFixed = cleanNameFixed:sub(2)
        end
        while cleanNameFixed:sub(-1) == " " do
            cleanNameFixed = cleanNameFixed:sub(1, -2)
        end
    end

    if self.NamedList[spawn.Name()] or self.NamedList[spawn.CleanName()] or self.NamedList[cleanNameFixed] then return true end

    ---@diagnostic disable-next-line: undefined-field
    if Config:GetSetting('CheckSMForNamed') and mq.TLO.Plugin("MQ2SpawnMaster").IsLoaded() and mq.TLO.SpawnMaster.HasSpawn ~= nil and mq.TLO.SpawnMaster.HasSpawn(spawn.ID())() then return true end

    ---@diagnostic disable-next-line: undefined-field
    if Config:GetSetting('CheckAMForNamed') and mq.TLO.AlertMaster ~= nil and mq.TLO.AlertMaster.IsNamed(spawn.DisplayName())() then return true end

    return false
end

function Module:AddNamedToCustomList(npcName)
    Config:ZoneListAdd(npcName, 'CustomNamedList')
end

function Module:DeleteNamedFromCustomList(arg1)
    Config:ZoneListDelete(arg1, 'CustomNamedList')
end

function Module:RenderCustomNamedList()
    if ImGui.CollapsingHeader("Custom Named List") then
        if mq.TLO.Target() and Targeting.TargetIsType("NPC") then
            ImGui.PushID("##_small_btn_add_target_custom_named")
            if ImGui.SmallButton("Add Target To List") then
                self:AddNamedToCustomList(mq.TLO.Target.CleanName())
            end
            ImGui.PopID()
        end

        if ImGui.BeginTable("CustomNamedList", 3, bit32.bor(ImGuiTableFlags.Borders)) then
            ImGui.TableSetupColumn('Id', ImGuiTableColumnFlags.WidthFixed, 40.0)
            ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 150.0)
            ImGui.TableSetupColumn('Controls', ImGuiTableColumnFlags.WidthFixed, 80.0)
            ImGui.TableHeadersRow()

            local zoneList = (Config:GetSetting('CustomNamedList') or {})[(mq.TLO.Zone.ShortName() or ""):lower()] or {}
            for idx, npcName in ipairs(zoneList) do
                ImGui.TableNextColumn()
                Ui.RenderText(tostring(idx))
                ImGui.TableNextColumn()
                Ui.RenderText(npcName)
                ImGui.TableNextColumn()
                ImGui.PushID("##_small_btn_delete_custom_named_" .. tostring(idx))
                if ImGui.SmallButton(Icons.FA_TRASH) then
                    self:DeleteNamedFromCustomList(idx)
                end
                ImGui.PopID()
            end

            ImGui.EndTable()
        end

        ImGui.Spacing()
        Ui.RenderText("Note: This list is shared in real-time with all RGMercs peers on this machine.")
    end
end

return Module
