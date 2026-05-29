-- SmartLoot Integration Module
local mq        = require('mq')
local Set       = require("mq.Set")
local Base      = require("modules.base")
local Casting   = require("utils.casting")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Events    = require("utils.events")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Targeting = require("utils.targeting")
local Ui        = require("utils.ui")

local Module    = { _version = '1.0', _name = "SmartLoot", _author = 'andude2, Algar', }
Module.__index  = Module
setmetatable(Module, { __index = Base, })

Module.SettingCategories = {}
Module.TempSettings      = {}

Module.DefaultConfig     = {
	['UseSmartLoot']                           = {
		DisplayName = "Enable SmartLoot",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "SmartLoot",
		Index = 1,
		Tooltip = "Enable SmartLoot integration for automated looting.",
		Default = false,
		OnChange = function(self)
			if Config:GetSetting('UseSmartLoot') and not Module.smartLootInitialized then
				Module:InitializeSmartLoot()
			end
		end,
	},
	['SLMainLooter']                           = {
		DisplayName = "Set RG Main",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "SmartLoot",
		Index = 1,
		Tooltip = "Set this toon as the main looter for smartloot.",
		Default = false,
	},
	['LootingTimeoutSL']                       = {
		DisplayName = "Looting Timeout",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "SmartLoot",
		Index = 4,
		Tooltip = "Maximum time in seconds to wait for SmartLoot to complete before continuing.",
		Default = 30,
		Min = 10,
		Max = 60,
	},
	['PullsYieldForLooting']                   = {
		DisplayName = "Hold Pulls for Looting",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "SmartLoot",
		Index = 5,
		Tooltip = "Do not pull if this character currently has a pending loot decision, or if other peers are still currently looting via SmartLoot.",
		Default = false,
	},
	[string.format("%s_Popped", Module._name)] = {
		DisplayName = Module._name .. " Popped",
		Type = "Custom",
		Default = false,
	},
}

Module.FAQ               = {
	{
		Question = "How can I get help with SmartLoot?",
		Answer = "  SmartLoot (aka SL, Smart Loot) integration is offered by RGMercs on the basis of convenience'.\n\n" ..
			"  All SL issues not revolving around that integration should be addressed to the author.\n\n" ..
			"  The '/sl_help' or '/sl_getstarted' commands may assist you with setup and common issues.",
		Settings_Used = "",
	},
}

Module.CommandHandlers   = {
	['slreset'] = {
		handler = function(self, params)
			Logger.log_info("\\ay[LOOT]: \\agManually resetting loot state")
			self.TempSettings.Looting = false
			self.TempSettings.LootStartTime = nil
			Logger.log_info("\\ay[LOOT]: \\agLoot state reset - RGMercs should resume normal operations.")
		end,
		help = "Reset SmartLoot state if there is a hangup in the looting process for SL peers.",
	},
}

Module.SettingCategories = Set.new({})
for k, v in pairs(Module.DefaultConfig or {}) do
	if v.Type ~= "Custom" then
		Module.SettingCategories:add(v.Category)
	end

	Module.FAQ[k] = { Question = v.FAQ or 'None', Answer = v.Answer or 'None', Settings_Used = k, }
end

function Module:New()
	return Base.New(self)
end

function Module:Init()
	Base.Init(self)

	if not Core.OnEMU() then
		Logger.log_debug("\ay[LOOT]: \agWe are not on EMU, unloading module. Build: %s",
			mq.TLO.MacroQuest.BuildName())
	else
		self:InitializeSmartLoot()
		Logger.log_debug("\ay[LOOT]: \agSmartLoot integration module loaded.")
	end
end

function Module:ShouldRender()
	return Core.OnEMU()
end

function Module:GetSLState()
	---@diagnostic disable-next-line: undefined-field
	if not mq.TLO.SmartLoot then
		return "Unknown"
	end

	---@diagnostic disable-next-line: undefined-field
	return mq.TLO.SmartLoot.State()
end

function Module:GetSLMode()
	---@diagnostic disable-next-line: undefined-field
	if not mq.TLO.SmartLoot then
		return "Unknown"
	end

	---@diagnostic disable-next-line: undefined-field
	return mq.TLO.SmartLoot.Mode()
end

function Module:GetSLTLO()
	---@diagnostic disable-next-line: undefined-field
	if not mq.TLO.SmartLoot then
		return nil
	end

	---@diagnostic disable-next-line: undefined-field
	return mq.TLO.SmartLoot
end

function Module:SLRunning()
	return mq.TLO.Lua.Script('smartloot').Status() == 'RUNNING'
end

function Module:Render()
	Base.Render(self)

	local red = { 1.0, 0.3, 0.3, 1.0, }
	local yellow = { 1.0, 1.0, 0.3, 1.0, }
	local green = { 0.3, 1.0, 0.3, 1.0, }

	-- SmartLoot status display
	local mode = "Unknown"
	local smartLootStatus = "Not Running"
	local peerStatus = "Unavailable"
	local modeColor, statusColor, peerColor = red, red, red

	if self:SLRunning() then
		if self.smartLootInitialized then
			smartLootStatus = string.format("%s", self:GetSLState())
			statusColor = green
		else
			smartLootStatus = "SmartLoot Not Initialized"
			statusColor = yellow
		end
		if Globals.SLPeerLooting then
			peerStatus = "Looting"
			peerColor = yellow
		else
			peerStatus = "Idle"
			peerColor = green
		end
		local currentMode = self:GetSLMode()
		if currentMode == "rgmain" then
			mode = "RGMain"
			modeColor = green
		elseif currentMode == "background" then
			mode = "Background"
			modeColor = green
		end
	end

	ImGui.Text("Mode:")
	ImGui.SameLine()
	ImGui.TextColored(modeColor[1], modeColor[2], modeColor[3], modeColor[4], mode)

	ImGui.Text("Status:")
	ImGui.SameLine()
	ImGui.TextColored(statusColor[1], statusColor[2], statusColor[3], statusColor[4], smartLootStatus)

	ImGui.Text("Peers:")
	ImGui.SameLine()
	ImGui.TextColored(peerColor[1], peerColor[2], peerColor[3], peerColor[4], peerStatus)

	ImGui.NewLine()
	ImGui.Text("This module integrates with SmartLoot for automated looting.")
	ImGui.Text("Please ensure that SmartLoot is properly configured! Use '/sl_help' or '/sl_getstarted' for more details.")
end

-- Initialize SmartLoot integration
function Module:InitializeSmartLoot()
	if not Config:GetSetting('UseSmartLoot') then return end

	if not self:SLRunning() then
		Core.DoCmd('/lua run smartloot')
	end

	if self:SLRunning() then
		Logger.log_info("\ay[LOOT]: \agSmartLoot integration enabled, please ensure you have the RGMain Looter set!")
		if Config:GetSetting('SLMainLooter') and self:GetSLMode():lower() ~= "rgmain" then
			mq.delay(500) -- time for command handler to load... we need something to callback preferably
			Core.DoCmd('/sl_mode rgmain')
			Logger.log_info("Loot: Setting this character as the main looter for SmartLoot.")
		end
		self.smartLootInitialized = true
	else
		self.smartLootInitialized = false
	end
end

-- Trigger SmartLoot to process corpses
function Module:DoLoot()
	-- Trigger SmartLoot RGMain processing
	if Config:GetSetting('SLMainLooter') then
		Logger.log_debug("\ay[LOOT]: \agTriggering SmartLoot RGMain processing")
		mq.cmd('/sl_rg_trigger')
	end

	-- Mark that we've initiated looting
	self.TempSettings.LootStartTime = Globals.GetTimeSeconds()
	self.TempSettings.Looting = true

	return true
end

-- Wait for SmartLoot to complete with proper focus holding
function Module:ProcessLooting()
	if not self.TempSettings.Looting then
		return
	end

	local timeoutMs = Config:GetSetting('LootingTimeoutSL') * 1000
	local startTime = self.TempSettings.LootStartTime or Globals.GetTimeSeconds()

	-- Hold focus in loot module while SmartLoot is working
	while self.TempSettings.Looting do
		local elapsed = Globals.GetTimeSeconds() - startTime

		-- Check for timeout
		if elapsed > timeoutMs then
			Logger.log_warn("\ay[LOOT]: \arLooting timeout reached (%d seconds) - continuing", Config:GetSetting('LootingTimeoutSL'))
			self.TempSettings.Looting = false
			break
		end

		-- Check for combat and abort if needed
		if self:GetSLState() == "Combat Detected" or Targeting.GetXTHaterCount() > 0 then
			Logger.log_debug("\ay[LOOT]: \arCombat detected - aborting looting")
			if mq.TLO.Window("LootWnd").Open() then
				mq.TLO.Window("LootWnd").DoClose()
			end
			self.TempSettings.Looting = false
			break
		end

		-- Check if SL is finished
		if self:GetSLState() == "Idle" or self:GetSLState() == "WaitingForInventorySpace" then -- we dont need to check for the TLO because it will close mercs if it isn't there
			Logger.log_verbose("\ay[LOOT]: \agSmartLoot processing complete (%.1fs elapsed)", elapsed / 1000)
			self.TempSettings.Looting = false
			break
		end

		-- Small delay to not hammer the CPU
		mq.delay(50)
		mq.doevents()
		Events.DoEvents()
	end

	Logger.log_verbose("\ay[LOOT]: \agFinished Processing Loot.")
end

function Module:GiveTime()
	if not Config:GetSetting('UseSmartLoot') or not self.smartLootInitialized then return end
	if not self:GetSLTLO() or not self:GetSLTLO().IsEnabled() then return end
	if Globals.PauseMain then return end

	if not Core.OkayToNotHeal() or mq.TLO.Me.Invis() or Casting.IAmFeigning() then return end

	-- Check for corpses using SmartLoot
	if self.TempSettings.Looting or (self:GetSLTLO() and (self:GetSLTLO().HasNewCorpses() and self:GetSLTLO().SafeToLoot())) then
		if self:DoLoot() then
			Logger.log_verbose("\ay[LOOT]: \agInitiated SmartLoot processing")
			-- Process looting immediately
			self:ProcessLooting()
		end
	end

	Globals.SLPeerLooting = self:GetSLTLO().AnyPeerLooting()
end

function Module:Shutdown()
	Logger.log_debug("\ay[LOOT]: \axSmartLoot Integration Module Unloaded.")
	-- Clear any pending loot state
	self.TempSettings.Looting = false
	self.TempSettings.LootStartTime = nil
end

-- for algar reference, ignore for now

-- Module.SmartLootEngineLootState = {
-- 	Idle = 1,
-- 	FindingCorpse = 2,
-- 	NavigatingToCorpse = 3,
-- 	OpeningLootWindow = 4,
-- 	ProcessingItems = 5,
-- 	WaitingForPendingDecision = 6,
-- 	ExecutingLootAction = 7,
-- 	CleaningUpCorpse = 8,
-- 	ProcessingPeers = 9,
-- 	OnceModeCompletion = 10,
-- 	CombatDetected = 11,
-- 	EmergencyStop = 12,
-- 	WaitingForWaterfallCompletion = 13,
-- 	WaitingForInventorySpace = 14,
-- }

return Module
