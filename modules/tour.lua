local mq            = require('mq')
local ImGui         = require('ImGui')
local Base          = require("modules.base")
local Config        = require('utils.config')
local Core          = require('utils.core')
local Globals       = require('utils.globals')
local Modules       = require("utils.modules")
local OptionsUI     = require('ui.options')
local Tables        = require('utils.tables')
local Ui            = require('utils.ui')

local Module        = { _version = '1.0', _name = "Tour", _author = 'Derple', }
Module.__index      = Module
Module.TempSettings = { StepIdx = 0, Steps = {}, FirstRunChecked = false, }
setmetatable(Module, { __index = Base, })

Module.FAQ             = {}

local sampleXTarget    = setmetatable({
    ID = function() return 999999 end,
    Name = function() return "a_tour_sample_target" end,
    CleanName = function() return "a tour sample target" end,
    PctHPs = function() return 72 end,
    PctAggro = function() return 100 end,
    Distance = function() return 25 end,
    Level = function() return mq.TLO.Me.Level() or 1 end,
    Dead = function() return false end,
    ConColor = function() return "WHITE" end,
    Class = { ShortName = function() return "WAR" end, },
}, { __call = function() return true end, })

Module.DefaultConfig   = {
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Default = false,
    },
    ['TourSeen'] = {
        DisplayName = "Tour Seen",
        Type = "Custom",
        Default = false,
        Scope = "global",
    },
}

Module.CommandHandlers = {
    tour = {
        usage = "/rgl tour",
        about = "Starts a guided tour of the controls and settings new users ask about most.",
        handler = function(self, _)
            self:Start()
        end,
    },
}

Module.Steps           = {
    {
        Title = "Welcome to RGMercs",
        Anchors = {},
        Text = "This tour points out the controls and settings new users ask about most.\n\n" ..
            "Use Next and Back to move between steps, or close this window at any time. Steps that cover Options settings open the Options window with a search filter applied.\n\n" ..
            "Show Advanced Options is turned on while the tour runs so every setting mentioned is visible; it is turned back off when the tour ends if you had it off.\n\n" ..
            "Run /rgl tour to start it again.",
    },
    {
        Title = "Pause and Resume",
        DidYouKnow = "/rgl pauseall and /rgl unpauseall pause or resume automation on every client running RGMercs.",
        Anchors = { "PauseButton", },
        Text = "This button pauses or resumes automation for this character.\n\n" ..
            "/rgl pause and /rgl unpause do the same from the command line. /rgl pauseall and /rgl unpauseall apply to every client running RGMercs.",
    },
    {
        Title = "Options Window",
        DidYouKnow = "/rgl search <text> opens the Options window with the search filter already set.",
        Anchors = { "OptionsButton", },
        Text = "Opens the Options window, where nearly every setting lives.\n\n" ..
            "The search box in its top left corner filters settings by name, tooltip or category. /rgl search <text> opens it with the filter already set.",
    },
    {
        Title = "Show Advanced Options",
        DidYouKnow = "Many settings are hidden until Show Advanced Options is turned on. If a search does not find a setting you expect, turn it on and search again.",
        Filter = "",
        Group = "General",
        Anchors = { "AdvancedToggle", },
        Text = "Many settings are marked advanced and are hidden from the Options window unless Show Advanced Options is turned on.\n\n" ..
            "If a search does not find a setting you expect, turn this on and search again.\n\n" ..
            "It is turned on while the tour runs so every setting mentioned is visible.",
    },
    {
        Title = "Mini Mode",
        DidYouKnow = "The main window can shrink down to a small icon. Click the icon or use /rgl mini to bring the window back.",
        Anchors = { "MiniButton", },
        Text = "Shrinks the main window down to a small icon. Click the icon or use /rgl mini to bring the window back.",
    },
    {
        Title = "Main Assist and the Assist List",
        DidYouKnow = "With Use Assist List enabled, the first valid character on the Assist List is used as the Main Assist. /rgl assistadd <Name> adds to it.",
        Tab = "Main",
        Expand = "AssistList",
        Anchors = { "AssistList", },
        Faq = "assist",
        Text =
            "RGMercs follows the Main Assist role set in the EQ group window. In a raid, use the Raid Assist Target setting (Options > Combat > Assisting) to pick which raid assist to follow.\n\n" ..
            "With Use Assist List enabled, the first valid character on this list is used as the Main Assist instead. Add names here or with /rgl assistadd <Name>.\n\n" ..
            "If no valid Main Assist is found and Self-Assist Fallback is on, the character assists itself until one appears.",
    },
    {
        Title = "Heal List",
        DidYouKnow = "Healers can heal characters outside their group when those characters are on the Heal List. /rgl heallistadd <Name> adds to it.",
        Tab = "Main",
        Expand = "HealList",
        Anchors = { "HealList", },
        Faq = "heal",
        Text = "Healers always check their own group first. Characters on this list are monitored as well, worst hurt first, which is how you heal someone outside your group.\n\n" ..
            "If the Heal List is not used, healers scan PCs on their XTarget window instead. Add names here or with /rgl heallistadd <Name>.",
    },
    {
        Title = "Force Target",
        DidYouKnow = "/rgl forcetarget <id?> forces a mob to be the autotarget until it is no longer valid, and /rgl forcetargetclear clears it.",
        Tab = "Main",
        Expand = "ForceTarget",
        Anchors = { "ForceTargetList", },
        Sample = true,
        Text = "This list shows every mob on your XTarget window that RGMercs treats as a hater. The row shown now is a sample added for the tour.\n\n" ..
            "Click the arrow column or the name to force that mob to be the autotarget until it is no longer valid. This also works on non-hostiles such as objects, a special NPC or a target dummy.\n\n" ..
            "The X column ignores a mob for this session (a gray X marks a persistent deny from the Spawns tab); the ban column stops hate abilities on it.\n\n" ..
            "/rgl forcetarget <id?> and /rgl forcetargetclear do the same from the command line.",
    },
    {
        Title = "Targeting",
        DidYouKnow = "Stay On Target keeps an assigned autotarget from changing, but it greatly interferes with MA Target Scan.",
        Filter = "Targeting",
        Group = "Combat",
        Expand = "Header:Targeting",
        Anchors = { "Category:Targeting Behavior", "AdvancedToggle", },
        Text = "All of these are advanced settings.\n\n" ..
            "Auto Target: as the MA, scan for and assign targets in combat; as a non-MA, switch to the MA's autotarget.\n\n" ..
            "Stay On Target: once an autotarget is assigned, do not change it. This greatly interferes with MA Target Scan.\n\n" ..
            "Auto Attack Safety Check: turn off auto-attack when not in combat and not cleared to engage the current target.\n\n" ..
            "Tank Aggro Scan lets a tank reclaim aggro from an xtarget without changing the autotarget; MA Aggro Scan sets the autotarget to haters not aggroed on the MA.",
    },
    {
        Title = "Assisting and Engaging",
        DidYouKnow = "Turn off Auto Engage to control engagement yourself.",
        Filter = "Assisting",
        Group = "Combat",
        Expand = "Header:Assisting",
        Anchors = { "Setting:AssistRange", },
        Text = "Auto Assist Percent: begin combat actions when the autotarget reaches this health percentage.\n\n" ..
            "Assist Range: engage the combat target only when it is within this distance.\n\n" ..
            "Auto Engage: engage targets automatically at all. Turn it off to control engagement yourself.\n\n" ..
            "Enable Melee Combat: auto attack the combat target. Rangers disable this to use ranged combat.",
    },
    {
        Title = "Camp",
        DidYouKnow = "/rgl campon and /rgl campoff set or clear the camp.",
        Filter = "Following",
        Group = "Movement",
        Expand = "Header:Following",
        Anchors = { "Category:Camp", },
        Text = "Camp Radius: the distance a character may move from camp before returning to it.\n\n" ..
            "Leash to Camp (Combat): return to the exact camp spot during combat when outside the Camp Radius.\n\n" ..
            "Set or clear the camp with /rgl campon and /rgl campoff.",
    },
    {
        Title = "Chase (Follow)",
        DidYouKnow = "/rgl chaseon <name?> and /rgl chaseoff toggle Chase, which uses MQ2Nav and requires a navmesh for the zone.",
        Filter = "Following",
        Group = "Movement",
        Expand = "Header:Following",
        Anchors = { "Category:Chase", },
        Text = "Chase On: follow the Chase Target using MQ2Nav. This requires a navmesh for the zone.\n\n" ..
            "Chase Distance: how far from the chase target before we start moving. Chase Stop Distance: how close before we stop.\n\n" ..
            "Chase or Camp While Paused: keep following or returning to camp even while RGMercs is paused.\n\n" ..
            "/rgl chaseon <name?> and /rgl chaseoff toggle this from the command line.",
    },
    {
        Title = "Positioning and Stick",
        DidYouKnow = "Manual Mode disables all automated movement for a character without disabling abilities.",
        Filter = "Positioning",
        Group = "Combat",
        Expand = "Header:Positioning",
        Anchors = { "Category:General Positioning", "AdvancedToggle", },
        Text = "Most of these are advanced settings.\n\n" ..
            "Enable Auto Stick: let RGMercs issue /stick commands in combat. Disable it to control movement yourself.\n\n" ..
            "Stick Arguments and Stick Distance: custom /stick flags and distance; leave blank for role-based defaults.\n\n" ..
            "Manual Mode: disables all automated movement for this character without disabling abilities.",
    },
    {
        Title = "Meditation",
        DidYouKnow = "Stand When Done Medding stands as soon as the meditation stop thresholds are reached.",
        Filter = "Meditation",
        Group = "Movement",
        Expand = "Header:Meditation",
        Anchors = { "Category:Med Rules", },
        Faq = "medit",
        Text = "Do Meditate: choose if and when to meditate. Bards: see the Bard Meditation FAQ, since sitting can interfere with songs.\n\n" ..
            "Med Start Mana% and Med Stop Mana% (advanced, under Med Thresholds): meditate at or under the start value and allow standing at or over the stop value. HP and Endurance have matching thresholds.\n\n" ..
            "Stand When Done Medding: stand as soon as the stop thresholds are reached.",
    },
    {
        Title = "Healing Thresholds",
        DidYouKnow = "If healers are overhealing, lower the heal points under Healing Thresholds.",
        Filter = "Healing Thresholds",
        Group = "Abilities",
        Expand = "Header:Recovery",
        Anchors = { "Category:Healing Thresholds", "AdvancedToggle", },
        Faq = "heal",
        Text = "Heal rotations fire when a target's HP% drops under these points. They are all advanced settings.\n\n" ..
            "Light, Main and Big Heal Point pick which heal rotation is used. Group Heal Point applies once Group Injured Count members are under it.\n\n" ..
            "Lower them if healers are overhealing.",
    },
    {
        Title = "Pulling",
        DidYouKnow = "/rgl pulldeny \"<name>\" adds your target to the Pull Deny list.",
        Filter = "Pulling",
        Group = "Movement",
        Expand = "Header:Pulling",
        Anchors = { "Category:Pull Rules", },
        Faq = "pull",
        Text =
            "Pull Mode and Pull Ability are chosen on the Pull tab of the main window. /rgl pullmode <camp|chain|area|roam|circuit|fightto> changes the mode, and /rgl pullstart and /rgl pullstop toggle pulling.\n\n" ..
            "Camp Pull Radius: how far from camp to scan for targets in camp modes. Max Path Range: the maximum travel distance, measured along the actual path.\n\n" ..
            "Pull Min Con and Pull Max Con: the con color range of valid targets.\n\n" ..
            "The Pull Allow, Deny and Preferred lists on the Pull tab filter targets by name; /rgl pulldeny \"<name>\" adds your target to the Deny list.",
    },
    {
        Title = "Burns",
        DidYouKnow = "/rgl burnnow <id?> forces burns on your target until combat ends.",
        Filter = "Burning",
        Group = "Combat",
        Expand = "Header:Burning",
        Anchors = { "Setting:BurnAuto", },
        Text =
            "Use Auto Burn: use burn rotations when the conditions below it are met: Always, Named (the mob must be on the RGMercs Spawn List or detected by SpawnMaster or Alert Master), or Mob Threshold (fighting this many haters). The conditions are advanced settings.\n\n" ..
            "/rgl burnnow <id?> forces burns on your target until combat ends. The FORCE BURN button on the main window sends it to every peer.",
    },
    {
        Title = "Clickies",
        DidYouKnow = "Clicky items can be managed on the Clickies tab or under Options > Items > Clickies.",
        Tab = "Clickies",
        Anchors = { "Tab:Clickies", },
        Faq = "click",
        Text = "Clicky items are managed on this tab: add an item, then set when it is used and any conditions it must pass.\n\n" ..
            "The same list is also available under Options > Items > Clickies.",
    },
    {
        Title = "Rezzing and Curing",
        DidYouKnow = "Do Cures clears curable detrimental effects from yourself and your peers.",
        Filter = "Recovery",
        Group = "Abilities",
        Expand = "Header:Recovery",
        Anchors = { "Category:Rezzing", },
        Text =
            "Do Rez: use rez spells at all. Rez In-Zone PCs (advanced): rez corpses of PCs who are in the zone, outside of combat; otherwise only PCs not in the zone are rezzed.\n\n" ..
            "Do Cures (under Curing): clear curable detrimental effects from yourself and your peers.",
    },
    {
        Title = "Logging",
        DidYouKnow = "Log To File also writes the RGMercs log to a file named RGMercs_<YourName>.log.",
        Filter = "Internals",
        Group = "General",
        Expand = "Header:Mercs Internals",
        Anchors = { "Category:Internals", },
        Text = "Log Level: how much RGMercs prints to the console. Raise it when reporting a problem.\n\n" ..
            "Log To File: also write the log to a file named RGMercs_<YourName>.log.",
    },
    {
        Title = "Class Mode and Config",
        DidYouKnow = "Custom class configs live under config/rgmercs/class_configs/, outside the script folder.",
        Tab = "Class",
        Anchors = { "ClassMode", },
        Faq = "config",
        Text = "Current Mode selects the role for this class config, such as Tank, DPS, Heal or Hybrid; the modes offered vary by class.\n\n" ..
            "Active Config picks which class config is loaded. Custom configs live under config/rgmercs/class_configs/, outside the script folder.",
    },
    {
        Title = "Bard Meditation",
        Show = function() return Globals.CurLoadedClass == "BRD" end,
        Filter = "bard",
        Group = "Commands/FAQ",
        Anchors = {},
        Faq = "bard",
        Text =
        "Sitting to meditate can interfere with singing, so Do Meditate (Options > Movement > Meditation) matters more for Bards than for other classes. The Bard Meditation FAQ entry shown here explains how it works.",
    },
    {
        Title = "Mezzing",
        Show = function() return Modules:ExecModule("Class", "CanMez") end,
        Tab = "Mez",
        Anchors = { "Tab:Mez", },
        Faq = "mez",
        Text = "Enable Mezzing (Options > Abilities > Mez) is the master toggle; ST Mez and AE Mez enable the single-target and AE spells or songs.\n\n" ..
            "Mez Start Count: start mezzing once this many mobs are engaged. Mez AE Count: switch to AE mez at this many. Mez Stop HPs (advanced): do not single-target mez a mob below this HP%.\n\n" ..
            "This tab shows the mez abilities in use, the CC target list and the immune list.",
    },
    {
        Title = "Charming",
        Show = function() return Core.CanCharm() end,
        Tab = "Charm",
        Anchors = { "Tab:Charm", },
        Faq = "charm",
        Text = "Charm On (Options > Abilities > Charm): charm a valid nearby mob to fight for you.\n\n" ..
            "/rgl forcecharm <id?> force-charms your target or the given spawn, held until it is in range; /rgl forcecharmclear cancels it. /rgl charmallow and /rgl charmdeny manage which mobs may be charmed.\n\n" ..
            "This tab shows the charm abilities in use and invalid charm targets.",
    },
    {
        Title = "Debuffs and Slows",
        Show = function() return Config:HaveSetting('DoSlow') end,
        Filter = "Debuffs",
        Group = "Abilities",
        Expand = "Header:Debuffs",
        Anchors = { "Category:Debuff Rules", },
        Text = "Mob Debuffing and Named Debuffing (advanced): the circumstances in which regular and named mobs are debuffed.\n\n" ..
            "Mana to Debuff: the minimum mana% to keep casting debuffs. Debuff Min Con: the lowest con color to debuff when con-based debuffing is enabled.\n\n" ..
            "Class-specific toggles such as Do Slow sit in the categories below.",
    },
    {
        Title = "Pets",
        Show = function() return Globals.Constants.RGPetClass:contains(Globals.CurLoadedClass) end,
        Filter = "Pet",
        Group = "Abilities",
        Expand = "Header:Pet",
        Anchors = { "Setting:DoPet", },
        Text = "Summon Pet: enable summoning and buffing of pets. Pet Buffs and Swarm Pets have their own categories under this header.",
    },
}

Module.ExtraDidYouKnow = {
    "Characters not running RGMercs can still show up in the Mercs Status panel: /lua run rgmercs/heartbeat directed sends their heartbeat, and /lua run rgmercs/heartbeat also opens a standalone Mercs Status window.",
    "Run /lua run rgmercs/heartbeat on any character you play manually or with other automation so your RGMercs characters can buff, heal and assist it better.",
    "With the heartbeat running on a character, RGMercs can read its buffs without targeting it.",
    "If your Main Assist is not running RGMercs, running the heartbeat on it gets its target to your other characters quickly.",
    "/rgl tempset <setting> <value> changes a setting until you restart or run /rgl cleartempset <setting> or /rgl cleartempall.",
    "/rgl set_all <setting> <value> sets a setting on this character and every RGMercs peer.",
    "/rgl set show lists every setting with its current value.",
    "/rgl rebuff forces buff checks to run again on the next rotation instead of waiting.",
    "/rgl spellreload, or Rescan Loadout on the Class tab, rescans your spells after scribing new ones or when something looks off.",
    "Any rotation entry can be turned off on the Class tab or with /rgl disablerotationentry \"<Name>\", without changing settings.",
    "Any ability set entry can be turned off on the Class tab or with /rgl disableabilitysetentry \"<Name>\", so the set uses its next best entry.",
    "/rgl stopcast stops the current cast and clears retries. It is useful in hotkeys before priority abilities like gate.",
    "/rgl cast, /rgl castaa and /rgl usemap queue a spell, AA or mapped ability so it fits between RGMercs' own casts.",
    "/rgl backoff stops a character from assisting or engaging until you toggle it back.",
    "/rgl assistup <Name> moves a character up the Assist List, which is a quick way to change who everyone assists.",
    "/rgl ignoretarget <id?> ignores a mob for auto-targeting for this session.",
    "/rgl namedadd <Name> marks a mob as named in the current zone.",
}

function Module:New()
    return Base.New(self)
end

function Module:ShouldRender()
    return false
end

function Module:Start()
    self.TempSettings.Steps = {}
    for _, step in ipairs(self.Steps) do
        if not step.Show or step.Show() then
            table.insert(self.TempSettings.Steps, step)
        end
    end
    Globals.Minimized = false
    self.TempSettings.RestoreAdvanced = not Config:GetSetting('ShowAdvancedOpts')
    if self.TempSettings.RestoreAdvanced then
        Config:SetSetting('ShowAdvancedOpts', true)
        OptionsUI:SetSearchFilter("")
    end
    self:GoToStep(1)
end

function Module:GetDidYouKnowFacts()
    local facts = Tables.ConcatTables(self.ExtraDidYouKnow)
    for _, step in ipairs(self.Steps) do
        if step.DidYouKnow then
            table.insert(facts, step.DidYouKnow)
        end
    end
    return facts
end

function Module:ClearSample()
    Globals.IgnoredTargetIDs:remove(sampleXTarget.ID())
    Globals.NoHateTargetIDs:remove(sampleXTarget.ID())
    if Globals.ForceTargetID == sampleXTarget.ID() then
        Globals.SetForcedTargetId(0)
    end
end

function Module:SampleXTarget()
    local step = self:CurrentStep()
    return step and step.Sample and sampleXTarget or nil
end

function Module:Stop()
    self.TempSettings.StepIdx = 0
    self:ClearSample()
    if self.TempSettings.RestoreAdvanced then
        Config:SetSetting('ShowAdvancedOpts', false)
        self.TempSettings.RestoreAdvanced = false
    end
    OptionsUI:SetSearchFilter("")
end

function Module:GoToStep(idx)
    local step = self.TempSettings.Steps[idx]
    self:ClearSample()
    self.TempSettings.StepIdx = idx
    self.TempSettings.ExpandPending = step.Expand ~= nil
    self.TempSettings.TabPending = step.Tab ~= nil
    self.TempSettings.FocusPending = true
    if step.Filter then
        OptionsUI:OpenAndSetSearchFilter(step.Filter, step.Group)
        OptionsUI:RequestFocus()
    end
end

function Module:CurrentStep()
    return self.TempSettings.Steps[self.TempSettings.StepIdx]
end

function Module:TabFlags(name)
    local step = self:CurrentStep()
    if step and self.TempSettings.TabPending and step.Tab == name then
        self.TempSettings.TabPending = false
        return ImGuiTabItemFlags.SetSelected
    end
    return ImGuiTabItemFlags.None
end

function Module:Prepare(name)
    local step = self:CurrentStep()
    if step and self.TempSettings.ExpandPending and step.Expand == name then
        self.TempSettings.ExpandPending = false
        ImGui.SetNextItemOpen(true, ImGuiCond.Always)
    end
end

function Module:Anchor(name)
    local step = self:CurrentStep()
    if not step then return end
    for priority, anchorName in ipairs(step.Anchors) do
        if anchorName == name and ImGui.IsItemVisible() and (not self.TempSettings.AnchorPriority or priority < self.TempSettings.AnchorPriority) then
            self.TempSettings.AnchorPriority = priority
            self.TempSettings.AnchorMin = ImGui.GetItemRectMinVec()
            self.TempSettings.AnchorMax = ImGui.GetItemRectMaxVec()
        end
    end
end

local function renderDim(viewport, holes)
    local drawList = ImGui.GetForegroundDrawList()
    local dimColor = IM_COL32(0, 0, 0, 140)
    local left, top = viewport.Pos.x, viewport.Pos.y
    local right, bottom = left + viewport.Size.x, top + viewport.Size.y

    local edges = { top, bottom, }
    for _, hole in ipairs(holes) do
        table.insert(edges, math.max(top, math.min(bottom, hole.Min.y)))
        table.insert(edges, math.max(top, math.min(bottom, hole.Max.y)))
    end
    table.sort(edges)

    for i = 1, #edges - 1 do
        local bandTop, bandBottom = edges[i], edges[i + 1]
        if bandBottom > bandTop then
            local bandHoles = {}
            for _, hole in ipairs(holes) do
                if hole.Min.y < bandBottom and hole.Max.y > bandTop then
                    table.insert(bandHoles, hole)
                end
            end
            table.sort(bandHoles, function(a, b) return a.Min.x < b.Min.x end)

            local x = left
            for _, hole in ipairs(bandHoles) do
                if hole.Min.x > x then
                    drawList:AddRectFilled(ImVec2(x, bandTop), ImVec2(hole.Min.x, bandBottom), dimColor)
                end
                x = math.max(x, hole.Max.x)
            end
            if right > x then
                drawList:AddRectFilled(ImVec2(x, bandTop), ImVec2(right, bandBottom), dimColor)
            end
        end
    end
end

function Module:RenderOverlay()
    if not self.TempSettings.FirstRunChecked and mq.TLO.EverQuest.Foreground() then
        self.TempSettings.FirstRunChecked = true
        if not Config:GetSetting('TourSeen') then
            Config:SetSetting('TourSeen', true)
            self:Start()
        end
    end

    local step = self:CurrentStep()
    if not step then return end

    local anchorMin, anchorMax = self.TempSettings.AnchorMin, self.TempSettings.AnchorMax
    self.TempSettings.AnchorMin, self.TempSettings.AnchorMax, self.TempSettings.AnchorPriority = nil, nil, nil

    local viewport = ImGui.GetMainViewport()
    local style = ImGui.GetStyle()
    local windowSize = self.TempSettings.WindowSize or ImVec2(0, 0)
    local holes = {}
    if self.TempSettings.WindowPos then
        table.insert(holes, { Min = self.TempSettings.WindowPos, Max = self.TempSettings.WindowPos + windowSize, })
    end
    if anchorMin then
        local pad = style.FramePadding.y
        table.insert(holes, { Min = ImVec2(anchorMin.x - pad, anchorMin.y - pad), Max = ImVec2(anchorMax.x + pad, anchorMax.y + pad), })
    end
    renderDim(viewport, holes)

    if anchorMin then
        ImGui.GetForegroundDrawList():AddRect(holes[#holes].Min, holes[#holes].Max,
            Globals.GetAlternatingColor(Globals.Constants.Colors.Orange, Globals.Constants.Colors.BrightWhite), style.FrameRounding, 0, 3)
        local posX = math.min(anchorMin.x, viewport.Pos.x + viewport.Size.x - windowSize.x - style.WindowPadding.x)
        local posY = anchorMax.y + style.WindowPadding.y * 2
        if posY + windowSize.y > viewport.Pos.y + viewport.Size.y then
            posY = anchorMin.y - windowSize.y - style.WindowPadding.y * 2
        end
        ImGui.SetNextWindowPos(ImVec2(posX, posY), ImGuiCond.Always)
    elseif self.TempSettings.FocusPending then
        ImGui.SetNextWindowPos(viewport:GetCenter(), ImGuiCond.Always, ImVec2(0.5, 0.5))
    end

    if self.TempSettings.FocusPending then
        ImGui.SetNextWindowFocus()
        self.TempSettings.FocusPending = false
    end

    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 1.0)
    ImGui.SetNextWindowBgAlpha(1.0)
    local open, show = ImGui.Begin(string.format("RGMercs Tour (%d/%d)###RGMercsTour", self.TempSettings.StepIdx, #self.TempSettings.Steps), true,
        bit32.bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.NoDocking))
    if show then
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 26)
        Ui.RenderColoredText(Globals.Constants.Colors.Orange, step.Title)
        ImGui.TextUnformatted(step.Text)
        if #step.Anchors > 0 and not anchorMin then
            Ui.RenderColoredText(Globals.Constants.Colors.LightBlue, "The highlighted control is not visible right now; open the %s window to see it.",
                step.Filter and "Options" or "RGMercs main")
        end
        ImGui.PopTextWrapPos()
        ImGui.Separator()

        if self.TempSettings.StepIdx > 1 then
            if ImGui.Button("Back") then
                self:GoToStep(self.TempSettings.StepIdx - 1)
            end
            ImGui.SameLine()
        end
        if self.TempSettings.StepIdx < #self.TempSettings.Steps then
            if ImGui.Button("Next") then
                self:GoToStep(self.TempSettings.StepIdx + 1)
            end
        elseif ImGui.Button("Finish") then
            open = false
        end
        if step.Faq then
            ImGui.SameLine()
            if ImGui.Button("Related FAQ") then
                OptionsUI:OpenAndSetSearchFilter(step.Faq, "Commands/FAQ")
                OptionsUI:RequestFocus()
            end
        end
    end
    self.TempSettings.WindowPos = ImGui.GetWindowPosVec()
    self.TempSettings.WindowSize = ImGui.GetWindowSizeVec()
    ImGui.End()
    ImGui.PopStyleVar()

    if not open then
        self:Stop()
    end
end

return Module
