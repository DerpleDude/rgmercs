-- Sample Basic Class Module
local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Combat    = require("utils.combat")
local Casting   = require("utils.casting")
local Ui        = require("utils.ui")
local Comms     = require("utils.comms")
local Tables    = require("utils.tables")
local Strings   = require("utils.strings")
local Logger    = require("utils.logger")
local Modules   = require("utils.modules")
local Events    = require("utils.events")
local Icons     = require('mq.ICONS')
local Base      = require("modules.base")

require('utils.datatypes')

local Module   = { _version = '0.1a', _name = "Charm", _author = 'Grimmier', }
Module.__index = Module
Module.__index = Module
setmetatable(Module, { __index = Base, })
Module.FAQ                           = {}
Module.CommandHandlers               = {}

Module.CombatState                   = "None"
Module.TempSettings                  = {}
Module.TempSettings.CharmImmune      = {}
Module.TempSettings.CharmTracker     = {}
Module.TempSettings.ImmuneModuleName = "Charm.Immune"
Module.ImmuneTable                   = {}

Module.DefaultConfig                 = {
	-- General
	['CharmOn']                                = {
		DisplayName           = "Charm On",
		Group                 = "Abilities",
		Header                = "Charm",
		Category              = "Charm General",
		Index                 = 1,
		Default               = false,
		Tooltip               = "Enables the memorization and use of charm spells.",
		RequiresLoadoutChange = true,
	},
	['DireCharm']                              = {
		DisplayName = "Dire Charm",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm General",
		Index       = 2,
		Default     = false,
		Tooltip     = "Use the Dire Charm AA.",
	},
	['CharmStartCount']                        = {
		DisplayName = "Charm Start Count",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm General",
		Index       = 3,
		Default     = 2,
		Min         = 1,
		Max         = 20,
		Tooltip     = "The minimum number of xtargets before we will attempt to charm one of them.",
	},
	['CharmRadius']                            = {
		DisplayName = "Charm Radius",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm General",
		Index       = 4,
		Default     = 100,
		Min         = 1,
		Max         = 200,
		Tooltip     = "The maximum distance away a potential charm target can be from the PC.",
	},
	['CharmZRadius']                           = {
		DisplayName = "Charm ZRadius",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm General",
		Index       = 5,
		Default     = 15,
		Min         = 1,
		Max         = 200,
		Tooltip     = "The maximum height difference between the potential charm target and the PC.",
	},
	-- Targets
	['CharmStopHPs']                           = {
		DisplayName = "Charm Stop HPs",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm Targets",
		Index       = 1,
		Default     = 80,
		Min         = 1,
		Max         = 100,
		Tooltip     = "Don't try to charm a mob that is below this HP%.",
	},
	['AutoLevelRangeCharm']                    = {
		DisplayName = "Auto Level Range",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm Targets",
		Index       = 2,
		Default     = true,
		Tooltip     = "Use automatic charm max-level detection based on the current charm spell.",
	},
	['CharmMinLevel']                          = {
		DisplayName = "Charm Min Level",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm Targets",
		Index       = 3,
		Default     = 1,
		Min         = 1,
		Max         = 200,
		Tooltip     = "If Auto Level Range is disabled, the minimum level of a potential charm target for charm spells.",
	},
	['CharmMaxLevel']                          = {
		DisplayName = "Charm Max Level",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm Targets",
		Index       = 4,
		Default     = 200,
		Min         = 1,
		Max         = 200,
		Tooltip     = "If Auto Level Range is disabled, the maximum level of a potential charm target for charm spells.",
	},
	['DireCharmMaxLvl']                        = {
		DisplayName = "DireCharm Max Level",
		Group       = "Abilities",
		Header      = "Charm",
		Category    = "Charm Targets",
		Index       = 5,
		Default     = 200,
		Min         = 1,
		Max         = 200,
		Tooltip     = "If Auto Level Range is disabled, the maximum level of a potential charm target for Dire Charm.",
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

function Module:LoadSettings()
	Base.LoadSettings(self)

	local existing = Config.Db:getValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, self.TempSettings.ImmuneModuleName, "ImmuneTable")
	if existing ~= nil then
		self.ImmuneTable = existing
	else
		-- one-time migration from legacy file
		local legacyFile = Config.GetConfigFileName(Module._name .. "_Immune")
		local loaded, err = loadfile(legacyFile)
		if loaded and not err then
			self.ImmuneTable = loaded() or {}
			Logger.log_info("\agCharm: migrated ImmuneTable from file to db.")
		else
			self.ImmuneTable = {}
		end
		Config.Db:setValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, self.TempSettings.ImmuneModuleName, "ImmuneTable", self.ImmuneTable)
	end
end

function Module:Init()
	-- bards don't have DireCharm so hide the settings.
	if Core.MyClassIs("BRD") then
		self.DefaultConfig['DireCharm'] = nil
		self.DefaultConfig['DireCharmMaxLvl'] = nil
	end

	Base.Init(self)
end

function Module:ShouldRender()
	return Modules:ExecModule("Class", "CanCharm")
end

function Module:Render()
	Base.Render(self)

	ImGui.NewLine()

	if self.ModuleLoaded then
		-- CCEd targets
		if ImGui.CollapsingHeader("Charm Target List") then
			ImGui.Indent()
			if ImGui.BeginTable("CharmedList", 4, bit32.bor(ImGuiTableFlags.None, ImGuiTableFlags.Borders, ImGuiTableFlags.Reorderable, ImGuiTableFlags.Resizable, ImGuiTableFlags.Hideable)) then
				ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 70.0)
				ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthFixed), 250.0)
				ImGui.TableSetupColumn('Level', (ImGuiTableColumnFlags.WidthFixed), 150.0)
				ImGui.TableSetupColumn('Body', (ImGuiTableColumnFlags.WidthStretch), 150.0)
				ImGui.TableHeadersRow()
				for id, data in pairs(self.TempSettings.CharmTracker) do
					ImGui.TableNextColumn()
					ImGui.Text(id)
					ImGui.TableNextColumn()
					ImGui.Text(data.name)
					ImGui.TableNextColumn()
					ImGui.Text(data.level)
					ImGui.TableNextColumn()
					ImGui.Text(data.body)
				end
				ImGui.EndTable()
			end
			ImGui.Unindent()
		end

		ImGui.Separator()
		-- Immune targets
		if ImGui.CollapsingHeader("Invalid Charm Targets") then
			ImGui.Indent()
			if ImGui.BeginTable("Immune", 5, bit32.bor(ImGuiTableFlags.None, ImGuiTableFlags.Borders, ImGuiTableFlags.Reorderable, ImGuiTableFlags.Resizable, ImGuiTableFlags.Hideable)) then
				ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 70.0)
				ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 250.0)
				ImGui.TableSetupColumn('Lvl', ImGuiTableColumnFlags.WidthFixed, 70.0)
				ImGui.TableSetupColumn('Body', (ImGuiTableColumnFlags.WidthFixed), 90.0)
				ImGui.TableSetupColumn('Reason', (ImGuiTableColumnFlags.WidthFixed), 90.0)
				ImGui.TableHeadersRow()
				for id, data in pairs(self.TempSettings.CharmImmune) do
					ImGui.TableNextColumn()
					ImGui.Text(id)
					ImGui.TableNextColumn()
					ImGui.Text(data.name)
					ImGui.TableNextColumn()
					ImGui.Text(data.lvl)
					ImGui.TableNextColumn()
					ImGui.Text(data.body)
					ImGui.TableNextColumn()
					ImGui.TextColored(Globals.Constants.Colors.CharmReasonColor, "%s", data.reason)
				end
				for name, data in pairs(self.ImmuneTable[mq.TLO.Zone.ShortName()] or {}) do
					for lvl, body in pairs(data) do
						for bodyType, reason in pairs(body) do
							ImGui.TableNextColumn()
							if ImGui.SmallButton(Icons.MD_DELETE .. '##' .. name .. lvl .. bodyType) then
								self.ImmuneTable[mq.TLO.Zone.ShortName()][name][lvl][bodyType] = nil
								Logger.log_debug(
									"\ayUpdateCharmList: Removing Spawn from our Immune List, \aw(\aoZone \at%s \aoMob \at%s \aoLvl \at%s \ao Body \at%s\aw.)",
									mq.TLO.Zone.ShortName(), name, lvl, bodyType)
								Config.Db:setValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, self.TempSettings.ImmuneModuleName, "ImmuneTable",
									self.ImmuneTable)
							end
							ImGui.TableNextColumn()
							ImGui.Text(name)
							ImGui.TableNextColumn()
							ImGui.Text(lvl)
							ImGui.TableNextColumn()
							ImGui.Text(bodyType)
							ImGui.TableNextColumn()
							ImGui.TextColored(Globals.Constants.Colors.CharmReasonColor, "%s", reason)
						end
					end
				end
				ImGui.EndTable()
			end
			ImGui.Unindent()
		end
	end
end

function Module:AddImmuneTarget(mobId, mobData)
	if self.TempSettings.CharmImmune[mobId] ~= nil then return end
	local zone = mq.TLO.Zone.ShortName()
	self.TempSettings.CharmImmune[mobId] = mobData

	if mobData.reason ~= 'HIGH_LVL' then
		if self.ImmuneTable[zone] == nil then
			self.ImmuneTable[zone] = {}
		end
		if self.ImmuneTable[zone][mobData.name] == nil then
			self.ImmuneTable[zone][mobData.name] = {}
		end
		if self.ImmuneTable[zone][mobData.name][mobData.lvl] == nil then
			self.ImmuneTable[zone][mobData.name][mobData.lvl] = {}
		end
		if self.ImmuneTable[zone][mobData.name][mobData.lvl][mobData.body] == nil then
			self.ImmuneTable[zone][mobData.name][mobData.lvl][mobData.body] = mobData.reason
			Logger.log_debug(
				"\ayUpdateCharmList: Adding Spawn to our Immune List, \aw(\aoZone \at%s \aoMob \at%s \aoLvl \at%s \ao Body \at%s\aw.)",
				zone, mobData.name, mobData.lvl, mobData.body)
			Config.Db:setValue(Globals.CurServer, Globals.CurLoadedChar, Globals.CurLoadedClass, self.TempSettings.ImmuneModuleName, "ImmuneTable", self.ImmuneTable)
			self:RemoveCCTarget(mobId)
		end
	end
end

function Module:CharmLvlToHigh(mobLvl)
	if Core.MyClassIs("BRD") then return false end
	if Config:GetSetting("DireCharm", true) and Config:GetSetting("AutoLevelRangeCharm") then
		Config:SetSetting('DireCharmMaxLvl', mobLvl - 1)
		Logger.log_debug("\awNOTICE:\ax \aoTarget LVL to High,\ayLowering Max Level for Dire Charm!")
		return true
	end
	return false
end

function Module:IsCharmImmune(mobId)
	local tmpSpawn = mq.TLO.Spawn(mobId)
	local isNamed = Targeting.IsNamed(tmpSpawn)

	local mobName = tmpSpawn.CleanName() or "Unknown"
	local mobType = tmpSpawn.Body() or "Unknown"
	local zoneShort = mq.TLO.Zone.ShortName()
	local mobLvl = tmpSpawn.Level() or 0
	if self.ImmuneTable[zoneShort] == nil then
		self.ImmuneTable[zoneShort] = {}
	end
	if self.ImmuneTable[zoneShort][mobName] ~= nil then
		if self.ImmuneTable[zoneShort][mobName][mobLvl] ~= nil then
			if self.ImmuneTable[zoneShort][mobName][mobLvl][mobType] ~= nil then
				return true
			end
		end
	end
	if self.TempSettings.CharmImmune[mobId] ~= nil then
		return true
	end
	if isNamed then
		self:AddImmuneTarget(mobId, { id = tmpSpawn.ID(), name = tmpSpawn.CleanName(), lvl = tmpSpawn.Level(), body = tmpSpawn.Body(), reason = "Named", })
		return true
	end
	return false
end

function Module:ResetCharmStates()
	self.TempSettings.CharmImmune = {}
	self.TempSettings.CharmTracker = {}
end

function Module:GetCharmSpell()
	if Core.MyClassIs("BRD") then
		return Modules:ExecModule("Class", "GetResolvedActionMapItem", "CharmSong")
	end

	return Modules:ExecModule("Class", "GetResolvedActionMapItem", "CharmSpell")
end

function Module:CharmNow(charmId, useAA)
	-- First thing we target the mob if we haven't already targeted them.
	Core.DoCmd("/attack off")
	local currentTargetID = mq.TLO.Target.ID()
	if charmId == Globals.AutoTargetID then return end
	Targeting.SetTarget(charmId)

	local charmSpell = self:GetCharmSpell()

	if not charmSpell or not charmSpell() then return end
	if not Core.MyClassIs("BRD") then
		local dCharm = Config:GetSetting("DireCharm", true) == true
		if dCharm and mq.TLO.Me.AltAbilityReady('Dire Charm') and (mq.TLO.Spawn(charmId).Level() or 0) <= Config:GetSetting('DireCharmMaxLvl') then
			Comms.HandleAnnounce(Comms.FormatChatEvent("Dire Charm", mq.TLO.Spawn(charmId).CleanName(), mq.TLO.Me.DisplayName()),
				Config:GetSetting('CharmAnnounceGroup'),
				Config:GetSetting('CharmAnnounce'),
				Config:GetSetting('AnnounceToRaidIfInRaid'))
			Casting.UseAA("Dire Charm", charmId)
		else
			-- This may not work for Bards but will work for DRU/NEC/ENCs
			Casting.UseSpell(charmSpell.RankName(), charmId, false)
			Logger.log_debug("Performing CHARM --> %d", charmId)
		end
	else
		Logger.log_debug("Performing Bard CHARM --> %d", charmId)
		Casting.UseSong(charmSpell.RankName(), charmId, false, 5)
	end

	mq.doevents()

	if Casting.GetLastCastResultId() == Globals.Constants.CastResults.CAST_SUCCESS and mq.TLO.Pet.ID() > 0 then
		Comms.HandleAnnounce(Comms.FormatChatEvent("Charm Success", mq.TLO.Spawn(charmId).CleanName(), charmSpell.RankName()), Config:GetSetting('CharmAnnounceGroup'),
			Config:GetSetting('CharmAnnounce'), Config:GetSetting('AnnounceToRaidIfInRaid'))
	else
		Comms.HandleAnnounce(Comms.FormatChatEvent("Charm Failed", mq.TLO.Spawn(charmId).CleanName(), charmSpell.RankName()), Config:GetSetting('CharmAnnounceGroup'),
			Config:GetSetting('CharmAnnounce'),
			Config:GetSetting('AnnounceToRaidIfInRaid'))
	end

	mq.doevents()

	Targeting.SetTarget(currentTargetID)
end

function Module:RemoveCCTarget(mobId)
	if mobId == 0 then return end
	self.TempSettings.CharmTracker[mobId] = nil
end

function Module:AddCCTarget(mobId)
	if mobId == 0 then return end
	local spawn = mq.TLO.Spawn(mobId)
	if self:IsCharmImmune(mobId) then
		Logger.log_debug("\awNOTICE:\ax Unable to charm %d - it is immune", mobId)
		return false
	end

	Targeting.SetTarget(mobId)

	self.TempSettings.CharmTracker[mobId] = {
		name = spawn.CleanName(),
		duration = mq.TLO.Target.Charmed.Duration() or 0,
		level = spawn.Level() or 0,
		body = spawn.Body() or "Unknown",
		last_check = Globals.GetTimeMS(),
		charm_spell = mq.TLO
			.Target.Charmed() or "None",
	}
end

function Module:IsValidCharmTarget(mobId)
	local spawn = mq.TLO.Spawn(mobId)

	-- Is the mob ID in our charm immune list? If so, skip.
	if self:IsCharmImmune(mobId) then
		Logger.log_debug(
			"\ayUpdateCharmList: Skipping \aoMob ID: \at%d \aoName: \at%s \aoLevel: \at%d \ayas it is in our immune list.",
			spawn.ID() or 0, spawn.CleanName() or "Unknown", spawn.Level() or 0)
		return false
	end
	-- Here's where we can add a necro check to see if the spawn is undead or not. If it's not
	-- undead it gets added to the charm immune list.
	if Core.MyClassIs('DRU') then
		if spawn.Body.Name() ~= "Animal" then
			Logger.log_debug(
				"\ayUpdateCharmList: Adding ID: %d Name: %s Level: %d to our immune list as it is not an animal.",
				spawn.ID() or 0,
				spawn.CleanName() or "Unknown", spawn.Level() or 0)
			return false
		end
	elseif Core.MyClassIs('NEC') then
		if spawn.Body.Name() ~= "Undead" then
			Logger.log_debug(
				"\ayUpdateCharmList: Adding ID: %d Name: %s Level: %d to our immune list as it is not undead.",
				spawn.ID() or 0, spawn.CleanName() or "Unknown", spawn.Level() or 0)
			return false
		end
	end
	if not spawn.LineOfSight() then
		Logger.log_debug("\ayUpdateCharmList: Skipping Mob ID: %d Name: %s Level: %d - No LOS.", spawn.ID() or 0,
			spawn.CleanName() or "Unknown", spawn.Level() or 0)
		return false
	end

	if (spawn.PctHPs() or 0) < Config:GetSetting('CharmStopHPs') then
		Logger.log_debug("\ayUpdateCharmList: Skipping Mob ID: %d Name: %s Level: %d - HPs too low.", spawn.ID() or 0,
			spawn.CleanName() or "Unknown", spawn.Level() or 0)
		return false
	end

	if (spawn.Distance() or 999) > Config:GetSetting('CharmRadius') then
		Logger.log_debug("\ayUpdateCharmList: Skipping Mob ID: %d Name: %s Level: %d - Out of Charm Radius",
			spawn.ID() or 0, spawn.CleanName() or "Unknown", spawn.Level() or 0)
		return false
	end

	return true
end

function Module:UpdateCharmList()
	local searchTypes = { "npc", }

	local charmSpell = self:GetCharmSpell()

	if not charmSpell or not charmSpell() then
		Logger.log_verbose("\ayayUpdateCharmList: No charm spell - bailing!")
		return
	end

	for _, t in ipairs(searchTypes) do
		local minLevel = Config:GetSetting('CharmMinLevel')
		local maxLevel = Config:GetSetting('CharmMaxLevel')
		if Config:GetSetting('AutoLevelRangeCharm') and charmSpell and charmSpell() then
			minLevel = 0
			maxLevel = charmSpell.MaxLevel()
			Config:SetSetting('CharmMaxLevel', maxLevel)
		end
		-- streamline search by body type for druids/necros this saves work when checking invalid.
		local npcType = ''
		if Core.MyClassIs("dru") then
			npcType = ' body Animal'
		elseif Core.MyClassIs("nec") then
			npcType = ' body Undead'
		end
		local searchString = string.format("%s radius %d zradius %d range %d %d targetable playerstate 4%s", t,
			Config:GetSetting('CharmRadius') * 2, Config:GetSetting('CharmZRadius') * 2, minLevel, maxLevel, npcType)

		local mobCount = mq.TLO.SpawnCount(searchString)()
		Logger.log_debug("\ayUpdateCharmList: Search String: '\at%s\ay' -- Count :: \am%d", searchString, mobCount)
		for i = 1, mobCount do
			local spawn = mq.TLO.NearestSpawn(i, searchString)

			if spawn and spawn() and spawn.ID() > 0 then
				Logger.log_debug(
					"\ayUpdateCharmList: Processing MobCount %d -- ID: %d Name: %s Level: %d BodyType: %s", i, spawn.ID(),
					spawn.CleanName(), spawn.Level(),
					spawn.Body.Name())

				if self:IsValidCharmTarget(spawn.ID()) then
					Logger.log_debug("\agAdding to Charm List: %d -- ID: %d Name: %s Level: %d BodyType: %s", i,
						spawn.ID(), spawn.CleanName(), spawn.Level(), spawn.Body.Name())
					self:AddCCTarget(spawn.ID())
				end
			end
		end
	end

	mq.doevents()
end

function Module:ProcessCharmList()
	-- Assume by default we never need to block for charm. We'll set this if-and-only-if
	-- we need to charm but our ability is on cooldown.
	if mq.TLO.Me.Pet.ID() ~= 0 then return end
	Core.DoCmd("/attack off")
	Logger.log_debug("\ayProcessCharmList() :: Loop")
	local charmSpell = self:GetCharmSpell()

	if not charmSpell or not charmSpell() then return end

	if not Config:GetSetting('CharmOn') then
		Logger.log_debug("\ayProcessCharmList(%d) :: Charming is off...")
		return
	end

	local removeList = {}
	for id, data in pairs(self.TempSettings.CharmTracker) do
		if mq.TLO.Pet.ID() > 0 then break end
		local spawn = mq.TLO.Spawn(id)
		Logger.log_debug("\ayProcessCharmList(%d) :: Checking...", id)

		if not spawn or not spawn() or spawn.Dead() or Targeting.TargetIsType("corpse", spawn) then
			table.insert(removeList, id)
			Logger.log_debug("\ayProcessCharmList(%d) :: Can't find mob removing...", id)
		else
			if self:IsCharmImmune(id) then
				-- somehow added an immune mod to our tracker...
				Logger.log_debug("\ayProcessCharmList(%d) :: Mob id is in immune list - removing...", id)
				table.insert(removeList, id)
			else
				if spawn.Distance() > Config:GetSetting('CharmRadius') or not spawn.LineOfSight() then
					Logger.log_debug("\ayProcessCharmList(%d) :: Distance(%d) LOS(%s)", id,
						spawn.Distance(), Strings.BoolToColorString(spawn.LineOfSight()))
				else
					if id == Globals.AutoTargetID then
						Logger.log_debug("\ayProcessCharmList(%d) :: Mob is MA's target skipping", id)
						table.insert(removeList, id)
					else
						Logger.log_debug("\ayProcessCharmList(%d) :: Mob needs charmed.", id)
						if mq.TLO.Me.Combat() or mq.TLO.Me.Casting() then
							Logger.log_debug(
								" \awNOTICE:\ax Stopping Melee/Singing -- must retarget to start charm.")
							Core.DoCmd("/attack off")
							mq.delay("3s", function() return not mq.TLO.Me.Combat() end)
							Core.DoCmd("/stopcast")
							Core.DoCmd("/stopsong")
							mq.delay("3s", function() return mq.TLO.Window("CastingWindow").Open() == false end)
						end

						Targeting.SetTarget(id)

						local maxWait = 5000
						while not Casting.SpellReady(charmSpell) and maxWait > 0 do
							mq.delay(100)
							maxWait = maxWait - 100
							mq.doevents()
							Events.DoEvents()
						end

						self:CharmNow(id, false)
					end
				end
			end
		end
	end

	for _, id in ipairs(removeList) do
		self:RemoveCCTarget(id)
	end

	mq.doevents()
end

function Module:DoCharm()
	local charmSpell = self:GetCharmSpell()
	self:UpdateTimings()

	if Targeting.GetXTHaterCount() >= Config:GetSetting('CharmStartCount') then
		self:UpdateCharmList()
	end
	if not Core.MyClassIs("BRD") then
		if ((charmSpell and charmSpell() and mq.TLO.Me.SpellReady(charmSpell.RankName.Name())()) or (Config:GetSetting("DireCharm", true) == true)) and
			Tables.GetTableSize(self.TempSettings.CharmTracker) >= 1 then
			self:ProcessCharmList()
		else
			Logger.log_verbose("DoCharm() : Skipping Charm list processing: Spell(%s) Ready(%s) TableSize(%d)",
				charmSpell and charmSpell() or "None",
				charmSpell and charmSpell() and
				Strings.BoolToColorString(mq.TLO.Me.SpellReady(charmSpell.RankName.Name())()) or "NoSpell",
				Tables.GetTableSize(self.TempSettings.CharmTracker))
		end
	else
		if (charmSpell and charmSpell() and mq.TLO.Me.SpellReady(charmSpell.RankName.Name())()) and
			Tables.GetTableSize(self.TempSettings.CharmTracker) >= 1 then
			self:ProcessCharmList()
		else
			Logger.log_verbose("DoCharm() : Skipping Charm list processing: Spell(%s) Ready(%s) TableSize(%d)",
				charmSpell and charmSpell() or "None",
				charmSpell and charmSpell() and
				Strings.BoolToColorString(mq.TLO.Me.SpellReady(charmSpell.RankName.Name())()) or "NoSpell",
				Tables.GetTableSize(self.TempSettings.CharmTracker))
		end
	end
end

function Module:UpdateTimings()
	for _, data in pairs(self.TempSettings.CharmTracker) do
		local timeDelta = (Globals.GetTimeMS()) - data.last_check

		data.duration = data.duration - timeDelta

		data.last_check = Globals.GetTimeMS()
	end
end

function Module:GiveTime()
	local combat_state = Combat.GetCachedCombatState()

	if not Core.IsCharming() then return end

	-- dead... whoops
	if mq.TLO.Me.Hovering() then return end

	if self.CombatState ~= combat_state and combat_state == "Downtime" then
		self:ResetCharmStates()
	end

	self.CombatState = combat_state

	self:DoCharm()
end

function Module:OnZone()
	self:ResetCharmStates()
	-- Zone Handler
end

return Module
