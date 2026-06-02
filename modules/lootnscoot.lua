-- Sample Basic Class Module
local mq              = require('mq')
local Actors          = require("actors")
local Base            = require("modules.base")
local Casting         = require("utils.casting")
local Combat          = require("utils.combat")
local Comms           = require("utils.comms")
local Config          = require('utils.config')
local Core            = require("utils.core")
local Events          = require("utils.events")
local Globals         = require('utils.globals')
local Logger          = require("utils.logger")
local Ui              = require('utils.ui')

-- Server name formatted for LNS to recognize
local serverLNSFormat = mq.TLO.EverQuest.Server():gsub(" ", "_")
local suppressWarning = true

local Module          = { _version = '1.2', _name = "LootNScoot", _author = 'Derple, Grimmier, Algar', }
Module.__index        = Module
setmetatable(Module, { __index = Base, })
Module.CommandHandlers = {}

Module.TempSettings    = {}

Module.FAQ             = {
	{
		Question = "How can I loot corpses on emu servers?",
		Answer = "RGMercs offers a Loot Module to direct and integrate LootNScoot (LNS), an emu loot management script." ..
			"Refer to the RG forums or the LNS github for installation or usage instructions, settings here are simply to control how RGMercs interacts with it." ..
			"Note that at one time, we offered an integrated version of LNS, but that feature has been discontinued.",
		Settings_Used = "",
	},
}

Module.DefaultConfig   = {
	['DoLoot']                                 = {
		DisplayName = "Load LootNScoot",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "LNS",
		Index = 1,
		Tooltip = "Load the integrated LootNScoot in directed mode. Turning this off will unload the looting script.",
		Default = false,
		OnChange = function(oldValue, newValue)
			if newValue == true and mq.TLO.Lua.Script('lootnscoot').Status() ~= 'RUNNING' then
				Core.DoCmd("/lua run lootnscoot directed rgmercs")
				suppressWarning = true
				if not Module.Actor then Module:LootMessageHandler() end
			elseif newValue == false and mq.TLO.Lua.Script('lootnscoot').Status() == 'RUNNING' then
				Core.DoCmd("/lua stop lootnscoot")
			end
		end,
	},
	['CombatLooting']                          = {
		DisplayName = "Combat Looting",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "LNS",
		Index = 2,
		Tooltip = "Enables looting during RGMercs-defined combat.",
		Default = false,
	},
	['LootRespectMedState']                    = {
		DisplayName = "Respect Med State",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "LNS",
		Index = 3,
		Tooltip = "Hold looting if you are currently meditating.",
		Default = false,
	},
	['LootingTimeoutLNS']                      = {
		DisplayName = "Looting Timeout",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "LNS",
		Index = 4,
		Tooltip = "The length of time in seconds that RGMercs will allow LNS to process loot actions in a single check.",
		Default = 5,
		Min = 1,
		Max = 30,
	},
	['MaxChaseTargetDistance']                 = {
		DisplayName = "Max Chase Targ Dist",
		Group = "General",
		Header = "Loot(Emu)",
		Category = "LNS",
		Index = 5,
		Tooltip = "If chase is on, we won't loot (and will abort looting) any corpses when the chase target is farther than this value away from us.",
		Default = 300,
		Min = 1,
		Max = 20000,
	},
	[string.format("%s_Popped", Module._name)] = {
		DisplayName = Module._name .. " Popped",
		Type = "Custom",
		Default = false,
	},
}

function Module:New()
	return Base.New(self)
end

function Module:Init()
	Base.Init(self)
	local requireDelay = false
	self:LootMessageHandler()
	if not Core.OnEMU() then
		Logger.log_debug("\ay[LOOT]: \agWe are not on EMU unloading module. Build: %s", Globals.BuildType)
	else
		if Config:GetSetting('DoLoot') then
			if mq.TLO.Lua.Script('lootnscoot').Status() == 'RUNNING' then
				Core.DoCmd("/lua stop lootnscoot")
				requireDelay = true
			end
			Core.DoCmd("%s/lua run lootnscoot directed rgmercs", requireDelay and "/timed 15 " or "")
		end
		self.TempSettings.Looting = false
		Logger.log_debug("\ay[LOOT]: \agLoot(LNS) module Loaded.")
	end

	return { self = self, defaults = self.DefaultConfig, }
end

function Module:ShouldRender()
	return Core.OnEMU()
end

function Module:Render()
	Base.Render(self)
	local doLoot = Config:GetSetting('DoLoot')
	Ui.RenderColoredText(doLoot and Globals.Constants.BasicColors.Green or Globals.Constants.BasicColors.LightRed, "Directed LNS looting is %s.", doLoot and "ENABLED" or "DISABLED")
	ImGui.Text(
		"Directed control of the LootNScoot script for looting on emu servers.\nSee the Loot category in the General options for integration settings.\nPlease refer to LNS documentation for all else.")
end

function Module.DoLooting()
	if not Module.TempSettings.Looting then return end

	local maxWait = Config:GetSetting('LootingTimeoutLNS') * 1000
	while Module.TempSettings.Looting do
		if Combat.GetCombatState() == "Combat" and not Config:GetSetting('CombatLooting') then
			Logger.log_debug("\ay[LOOT]: Aborting Actions due to combat!")
			if mq.TLO.Window('LootWnd').Open() then mq.TLO.Window('LootWnd').DoClose() end
			Module.TempSettings.Looting = false
			break
		end

		if not Module:CheckChaseTargetInRange() then
			Logger.log_debug("\ay[LOOT]: Aborting Actions due to chase target distance!")
			Module.TempSettings.Looting = false
			break
		end

		mq.delay(20, function() return not Module.TempSettings.Looting end)

		maxWait = maxWait - 20

		if maxWait <= 0 then
			Logger.log_debug("\ay[LOOT]: Aborting Actions due to timeout.")
			Module.TempSettings.Looting = false
			break
		end
		mq.doevents()
		Events.DoEvents()
	end
	Logger.log_verbose("\ay[LOOT]: \atFinished or Aborted Looting: \agResuming")
end

function Module:LootMessageHandler()
	self.Actor = Actors.register('loot_module', function(message)
		local mail = message()
		local subject = mail.Subject or ''
		local who = mail.Who or ''

		if who ~= Globals.CurLoadedChar then return end

		if subject == ('done_looting' or 'done_processing') then
			Module.TempSettings.Looting = false
		elseif subject == 'processing' then
			Module.TempSettings.Looting = true
		end
	end)
end

function Module:CheckChaseTargetInRange()
	if Config:GetSetting('ChaseOn') then
		local chaseSpawn = mq.TLO.Spawn("pc =" .. Core.GetChaseTarget())
		if chaseSpawn() and chaseSpawn.ID() > 0 and (chaseSpawn.Distance3D() or 0) > Config:GetSetting('MaxChaseTargetDistance') then
			return false
		end
	end
	return true
end

function Module:GiveTime()
	local combat_state = Combat.GetCachedCombatState()

	if not Config:GetSetting('DoLoot') then return end
	if Globals.PauseMain then return end
	if mq.TLO.Lua.Script('lootnscoot').Status() ~= 'RUNNING' then
		if not suppressWarning then
			Logger.log_error("\ar[LOOT]: Looting is enabled, but LNS does not appear to be running!")
			Comms.PrintGroupMessage("%s has looting enabled, but LNS does not appear to be running!", mq.TLO.Me.CleanName())
			suppressWarning = true
		end
		return
	end

	suppressWarning = false

	if not Core.OkayToNotHeal() or mq.TLO.Me.Invis() or Casting.IAmFeigning() then return end

	if Combat.CombatNavActive() then return end

	if not self:CheckChaseTargetInRange() then
		Logger.log_super_verbose("\ay::LOOT:: \arAborted!\ax Chase Target too far away.")
		return
	end

	if Config:GetSetting('LootRespectMedState') and Globals.InMedState then
		Logger.log_super_verbose("\ay::LOOT:: \arAborted!\ax Meditating.")
		return
	end

	local deadCount = mq.TLO.SpawnCount("npccorpse radius 100 zradius 50")()
	local myCorpseCount = mq.TLO.SpawnCount(string.format("pccorpse %s radius 100 zradius 50", mq.TLO.Me.CleanName()))()
	if myCorpseCount > 0 then deadCount = deadCount + 1 end
	Logger.log_verbose("\ay[LOOT]: \agFound %d corpses within range.", deadCount)
	if self.Actor == nil then self:LootMessageHandler() end
	-- send actors message to loot
	if (combat_state ~= "Combat" or Config:GetSetting('CombatLooting')) and deadCount > 0 then
		if not self.TempSettings.Looting then
			self.Actor:send({ mailbox = 'lootnscoot', script = 'lootnscoot', },
				{ who = Globals.CurLoadedChar, server = serverLNSFormat, directions = 'doloot', })
			self.TempSettings.Looting = true
		end
	end

	if self.TempSettings.Looting then
		Logger.log_verbose("\ay[LOOT]: \aoPausing for \atLoot Actions")
		Module.DoLooting()
	end
end

return Module
