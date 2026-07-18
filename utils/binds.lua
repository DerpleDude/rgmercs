local mq               = require('mq')
local Set              = require('mq.set')
local Combat           = require("utils.combat")
local Comms            = require("utils.comms")
local Config           = require('utils.config')
local ConfigShare      = require("utils.rg_config_share")
local Core             = require("utils.core")
local Globals          = require('utils.globals')
local Logger           = require("utils.logger")
local Modules          = require("utils.modules")
local OptionsUI        = require("ui.options")
local Strings          = require("utils.strings")
local Targeting        = require("utils.targeting")

local Binds            = { _version = '0.1a', _name = "Binds", _author = 'Derple', }

Binds.ImmunityKeywords = {}
for _, name in ipairs(Globals.Constants.ResistTypes) do Binds.ImmunityKeywords[name:lower()] = { canonical = name, group = "elementalImmunities", } end
for _, name in ipairs(Globals.Constants.ImmunityEffects) do Binds.ImmunityKeywords[name:lower()] = { canonical = name, group = "statusImmunities", } end

Binds.MainHandler = function(cmd, ...)
    if not cmd or cmd:len() == 0 then cmd = "help" end

    cmd = cmd:lower()

    if Binds.Handlers[cmd] then
        return Binds.Handlers[cmd].handler(...)
    end

    -- try to process as a substring
    for bindCmd, bindData in pairs(Binds.Handlers) do
        if Strings.StartsWith(bindCmd, cmd) then
            return bindData.handler(...)
        end
    end

    local processed = false
    local results = Modules:ExecAll("HandleBind", cmd, ...)

    for _, r in pairs(results) do processed = processed or r end

    if not processed then
        Logger.log_warn("\ayWarning:\ay '\at%s\ay' is not a valid command", cmd)
    end
end

Binds.Handlers    = {
    ['export_config'] = {
        usage = "/rgl export_config <module>",
        about = "Exports your current RGMercs configuration to chat",
        handler = function(module)
            local configTable = {}

            configTable = Config:GetModuleSettings((not module or module:len() <= 0) and "Core" or module)

            local encodedConfig = ConfigShare.ExportConfig(configTable)
            printf("%s", encodedConfig)
        end,
    },
    ['set'] = {
        usage = "/rgl set [show | <setting> <value>]",
        about = "Show all settings or set a specific RGMercs setting.",
        handler = function(config, value)
            Config:HandleBind(config, value)
        end,
    },
    ['set_peer'] = {
        usage = "/rgl set_peer <peer> <setting> <value>",
        about = "Sets a specific setting for an RGMercs peer.",
        handler = function(peer, config, value)
            Config:PeerSetSetting(peer, config, value)
        end,
    },
    ['set_all'] = {
        usage = "/rgl set_all <setting> <value>",
        about = "Sets a specific setting for this character and all RGMercs peers.",
        handler = function(config, value)
            Config:HandleBind(config, value)
            local peers = Comms.GetPeers(false)
            for _, peer in pairs(peers) do
                if peer ~= mq.TLO.Me.Name() then
                    Config:PeerSetSetting(peer, config, value)
                end
            end
        end,
    },
    ['tempset'] = {
        usage = "/rgl tempset <setting> <value>",
        about = "Temporarily sets a specific RGMercs setting until you restart the script or clear the temp setting.",
        handler = function(config, value)
            Config:HandleTempSet(config, value)
        end,
    },
    ['cleartempset'] = {
        usage = "/rgl cleartempset <setting>",
        about = "Clears a specific temporarily set RGMercs setting back to the saved value.",

        handler = function(config)
            Config:ClearTempSetting(config)
        end,
    },
    ['cleartempall'] = {
        usage = "/rgl cleartempall",
        about = "Clears all temporarily set RGMercs setting back to their saved values.",

        handler = function(config)
            Config:ClearAllTempSettings()
        end,
    },
    ['ignoretarget'] = {
        usage = "/rgl ignoretarget <id?>",
        about =
        "Ignores a mob for auto-targeting for this session only. If no ID is entered, your target is used.",
        handler = function(targetId)
            targetId = targetId and tonumber(targetId) or mq.TLO.Target.ID()
            if targetId > 0 then
                Logger.log_info("\awIgnored Target: %d", targetId)
                Globals.IgnoredTargetIDs:add(targetId)
            else
                Logger.log_info("\awIgnoring a target requires a valid supplied ID or target!")
            end
        end,
    },
    ['ignoretargetclear'] = {
        usage = "/rgl ignoretargetclear",
        about = "Will clear all ignored targets.",
        handler = function()
            Globals.IgnoredTargetIDs = Set.new({})
            Logger.log_info("\awIgnored targets cleared.")
        end,
    },
    ['nohate'] = {
        usage = "/rgl nohate <id?>",
        about =
        "Will prevent this character from using hate abilities on the target or <id>. If no ID is supplied, uses the current target's ID.",
        handler = function(targetId)
            targetId = targetId and tonumber(targetId) or mq.TLO.Target.ID()
            if targetId > 0 then
                Logger.log_info("\awNo Hate Target: %d", targetId)
                Globals.NoHateTargetIDs:add(targetId)
            else
                Logger.log_info("\awMarking a no hate target requires a valid supplied ID or target!")
            end
        end,
    },
    ['nohateclear'] = {
        usage = "/rgl nohateclear",
        about = "Will clear all no hate targets.",
        handler = function()
            Globals.NoHateTargetIDs = Set.new({})
            Logger.log_info("\awNo hate targets cleared.")
        end,
    },
    ['forcetarget'] = {
        usage = "/rgl forcetarget <id?>",
        about =
        "Will force the current target or <id> to be your autotarget no matter what until it is no longer valid. Can force combat on non-hostiles like objects, a special NPC, or a target dummy. If no ID is supplied, uses the current target's ID.",
        handler = function(targetId)
            local forcedTarget = targetId and mq.TLO.Spawn(targetId) or mq.TLO.Target
            if forcedTarget and forcedTarget() and forcedTarget.ID() > 0 and (Targeting.TargetIsType("npc", forcedTarget) or Targeting.TargetIsType("npcpet", forcedTarget) or Targeting.TargetIsType("object", forcedTarget)) then
                Globals.SetForcedTargetId(forcedTarget.ID())
                Logger.log_info("\awForced Target: %s", forcedTarget.CleanName() or "None")
            end
        end,
    },
    ['forcetargetclear'] = {
        usage = "/rgl forcetargetclear",
        about = "Will clear the current forced target.",
        handler = function()
            Globals.SetForcedTargetId(0)
            Logger.log_info("\awForced target cleared.")
        end,
    },
    ['forcenamed'] = {
        usage = "/rgl forcenamed",
        about = "Will force the current target to be considered a Named (this flag does not persist and is for testing purposes).",
        handler = function()
            Targeting.ForceNamed = not Targeting.ForceNamed
            Logger.log_info("\awForced Named: %s", Strings.BoolToColorString(Targeting.ForceNamed))
        end,
    },
    ['burnnow'] = {
        usage = "/rgl burnnow <id?>",
        about = "Will force the target <id> or your current target to trigger all burn checks - resets when combat ends.",
        handler = function(targetId)
            Targeting.SetForceBurn(targetId)
        end,
    },
    ['assistadd'] = {
        usage = "/rgl assistadd <Name>",
        about = "Adds <Name> to the Assist List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl assistadd - no name given and no valid target exists!")
                return
            end
            Config:ListAdd(name, "AssistList")
        end,
    },
    ['assistdelete'] = {
        usage = "/rgl assistdelete (<Name> or <List#>)",
        about = "Deletes (<Name> or <List#>) from the Assist List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl assistdelete - no name given and no valid target exists!")
                return
            end
            Config:ListDelete(name, "AssistList")
        end,
    },
    ['assistup'] = {
        usage = "/rgl assistup (<Name> or <List#>)",
        about = "Moves (<Name> or <List#>) one position up on the Assist List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl assistup - no name given and no valid target exists!")
                return
            end
            Config:ListMoveUp(name, "AssistList")
        end,
    },
    ['assisttop'] = {
        usage = "/rgl assisttop (<Name> or <List#>)",
        about = "Moves (<Name> or <List#>) to the top of the Assist List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl assisttop - no name given and no valid target exists!")
                return
            end
            Config:ListMoveTop(name, "AssistList")
        end,
    },
    ['assistdown'] = {
        usage = "/rgl assistdown (<Name> or <List#>)",
        about = "Moves (<Name> or <List#>) one position down on the Assist List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl assistdown - no name given and no valid target exists!")
                return
            end
            Config:ListMoveDown(name, "AssistList")
        end,
    },
    ['assistclear'] = {
        usage = "/rgl assistclear",
        about = "Completely clears the Assist List.",
        handler = function()
            Config:ListClear("AssistList")
        end,
    },
    ['heallistadd'] = {
        usage = "/rgl heallistadd <Name>",
        about = "Adds <Name> to the Heal List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl heallistadd - no name given and no valid target exists!")
                return
            end
            Config:ListAdd(name, "HealList")
        end,
    },
    ['heallistdelete'] = {
        usage = "/rgl heallistdelete (<Name> or <List#>)",
        about = "Deletes (<Name> or <List#>) from the Heal List. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then name = mq.TLO.Target.CleanName() end
            if not name then
                Logger.log_error("/rgl heallistdelete - no name given and no valid target exists!")
                return
            end
            Config:ListDelete(name, "HealList")
        end,
    },
    ['heallistclear'] = {
        usage = "/rgl heallistclear",
        about = "Completely clears the Heal List.",
        handler = function()
            Config:ListClear("HealList")
        end,
    },
    ['namedadd'] = {
        usage = "/rgl namedadd <Name>",
        about = "Sets the Named flag for a mob in the current zone. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl namedadd - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl namedadd - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            Modules.ModuleList.Spawns:AddNamedToCustomList(name)
            Logger.log_info("\ag[Spawn List] \ay%s\ax flagged Named in this zone.", name)
        end,
    },
    ['nameddelete'] = {
        usage = "/rgl nameddelete [Name]",
        about = "Clears the Named flag for a mob in the current zone. If no name is entered, your target's name is used.",
        handler = function(arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl nameddelete - no argument given and no valid target exists!")
                return
            end
            Modules.ModuleList.Spawns:DeleteNamedFromCustomList(arg1)
            Logger.log_info("\ag[Spawn List] \ay%s\ax Named flag cleared.", tostring(arg1))
        end,
    },
    ['nameddeny'] = {
        usage = "/rgl nameddeny [Name]",
        about = "Marks a mob as NOT named in the current zone, overriding built-in named status. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl nameddeny - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl nameddeny - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            Modules.ModuleList.Spawns:AddNotNamedToCustomList(name)
            Logger.log_info("\ag[Spawn List] \ay%s\ax flagged Not Named in this zone.", name)
        end,
    },
    ['immuneadd'] = {
        usage = "/rgl immuneadd <Fire|Cold|Magic|Poison|Disease|Slow|Snare|Stun> [Name]",
        about =
        "Flag a mob as immune to an element (Fire/Cold/Magic/Poison/Disease) or status effect (Slow/Snare/Stun) in the current zone. If no name is entered, your target's name is used.",
        handler = function(keyword, name)
            local match = keyword and Binds.ImmunityKeywords[tostring(keyword):lower()]
            if not match then
                Logger.log_error("/rgl immuneadd - invalid or missing keyword. Use Fire/Cold/Magic/Poison/Disease or Slow/Snare/Stun.")
                return
            end
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl immuneadd - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl immuneadd - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            Config:ZoneRegistrySetSubFlag(name, "SpawnList", match.group, match.canonical, true)
            Logger.log_info("\ag[Immune] \ay%s\ax marked %s-immune in this zone.", name, match.canonical)
        end,
    },
    ['immunedelete'] = {
        usage = "/rgl immunedelete <Fire|Cold|Magic|Poison|Disease|Slow|Snare|Stun> [Name]",
        about = "Clear an elemental or status immunity flag from a mob in the current zone. If no name is entered, your target's name is used.",
        handler = function(keyword, arg1)
            local match = keyword and Binds.ImmunityKeywords[tostring(keyword):lower()]
            if not match then
                Logger.log_error("/rgl immunedelete - invalid or missing keyword. Use Fire/Cold/Magic/Poison/Disease or Slow/Snare/Stun.")
                return
            end
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl immunedelete - no name given and no valid target exists!")
                return
            end
            Config:ZoneRegistryClearFlag(arg1, "SpawnList", match.group, match.canonical)
            Logger.log_info("\ag[Immune] \ay%s\ax cleared %s flag.", tostring(arg1), match.canonical)
        end,
    },
    ['spawnadd'] = {
        usage = "/rgl spawnadd [Name]",
        about = "Adds a mob to the Spawn List for the current zone with no flags set. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl spawnadd - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl spawnadd - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            Modules.ModuleList.Spawns:AddSpawnToList(name)
            Logger.log_info("\ag[Spawn List] \ay%s\ax added with no flags.", name)
        end,
    },
    ['spawndelete'] = {
        usage = "/rgl spawndelete [Name]",
        about = "Removes a mob and all of its flags from the Spawn List for the current zone. If no name is entered, your target's name is used.",
        handler = function(arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl spawndelete - no argument given and no valid target exists!")
                return
            end
            Modules.ModuleList.Spawns:DeleteEntryFromCustomList(arg1)
            Logger.log_info("\ag[Spawn List] \ay%s\ax removed.", tostring(arg1))
        end,
    },
    ['spawndeny'] = {
        usage = "/rgl spawndeny [Name]",
        about = "Sets the Deny flag for a mob in the current zone, persistently preventing it from being your auto-target. If no name is entered, your target's name is used.",
        handler = function(name)
            if not name then
                if not mq.TLO.Target() then
                    Logger.log_error("/rgl spawndeny - no name given and no valid target exists!")
                    return
                end
                if not Targeting.TargetIsType("NPC") then
                    Logger.log_error("/rgl spawndeny - target must be an NPC!")
                    return
                end
                name = mq.TLO.Target.CleanName()
            end
            Modules.ModuleList.Spawns:AddDenyToCustomList(name)
            Logger.log_info("\ag[Spawn List] \ay%s\ax flagged Deny - will not be auto-targeted.", name)
        end,
    },
    ['spawndenydelete'] = {
        usage = "/rgl spawndenydelete [Name]",
        about = "Clears the Deny flag for a mob in the current zone. If no name is entered, your target's name is used.",
        handler = function(arg1)
            if not arg1 then arg1 = mq.TLO.Target.CleanName() end
            if not arg1 then
                Logger.log_error("/rgl spawndenydelete - no argument given and no valid target exists!")
                return
            end
            Modules.ModuleList.Spawns:DeleteDenyFromCustomList(arg1)
            Logger.log_info("\ag[Spawn List] \ay%s\ax Deny flag cleared.", tostring(arg1))
        end,
    },
    ['backoff'] = {
        usage = "/rgl backoff <on|off>",
        about = "Toggles or sets backoff flag, which temporarily stops the PC from assisting or engaging.",
        handler = function(value)
            if value == nil then
                Globals.BackOffFlag = not Globals.BackOffFlag
            elseif value:lower() == "on" or value == "1" then
                Globals.BackOffFlag = true
            else
                Globals.BackOffFlag = false
            end

            if Globals.BackOffFlag and Config:GetSetting('DoPetCommands') and mq.TLO.Me.Pet.ID() > 0 then
                Core.DoCmd("/squelch /pet back off")
            end

            Logger.log_info("\ayBackoff \awset to: %s", Strings.BoolToColorString(Globals.BackOffFlag))
        end,
    },
    ['qsay'] = {
        usage = "/rgl qsay <text>",
        about = "All groupmembers running RGMercs will target your target and say the <text> with a random delay.",
        handler = function(...)
            local allText = { ..., }
            local text
            for _, t in ipairs(allText) do
                text = (text and text .. " " or "") .. t
            end
            Core.DoCmd("/squelch /dggaexecute /mqtarget id %d", Targeting.GetTargetID())
            mq.delay(5)
            if Config:GetSetting('BreakInvisForSay') then
                Core.DoCmd("/squelch /dggaexecute /docommand /timed $\\{Math.Rand[1,60]} /makemevisible")
                mq.delay(100) -- we can't callback for someone else's invis. Give time for everyone to be visible.
            end
            Core.DoCmd("/squelch /dggaexecute /docommand /timed $\\{Math.Rand[1,60]} /say %s", text)
        end,
    },
    ['say'] = {
        usage = "/rgl say <text>",
        about = "All groupmembers running RGMercs will target your target and say the <text> after a very short delay.",
        handler = function(...)
            local allText = { ..., }
            local text
            for _, t in ipairs(allText) do
                text = (text and text .. " " or "") .. t
            end
            Core.DoCmd("/squelch /dggaexecute /mqtarget id %d", Targeting.GetTargetID())
            mq.delay(5)
            if Config:GetSetting('BreakInvisForSay') then
                Core.DoCmd("/squelch /dggaexecute /makemevisible")
                mq.delay(50) -- we can't callback for someone else's invis. Slight delay for execution.
            end
            Core.DoCmd("/squelch /dggaexecute /docommand /timed 5 /say %s", text)
        end,
    },
    ['rsay'] = {
        usage = "/rgl rsay <text>",
        about = "All raidmembers running RGMercs will target your target and say the <text> after a very short delay.",
        handler = function(...)
            local allText = { ..., }
            local text
            for _, t in ipairs(allText) do
                text = (text and text .. " " or "") .. t
            end
            Core.DoCmd("/squelch /dgraexecute /mqtarget id %d", Targeting.GetTargetID())
            mq.delay(5)
            if Config:GetSetting('BreakInvisForSay') then
                Core.DoCmd("/squelch /dgraexecute /makemevisible")
                mq.delay(50) -- we can't callback for someone else's invis. Slight delay for execution.
            end
            Core.DoCmd("/squelch /dgraexecute /docommand /timed 5 /say %s", text)
        end,
    },
    ['setlogfilter'] = {
        usage = "/rgl setlogfilter <filter|filter|filter|...>",
        about = "Set a Lua regex filter to match log lines against before printing (does not effect file logging).",
        handler = function(text)
            Config:SetSetting('LogFilter', text)
        end,
    },
    ['clearlogfilter'] = {
        usage = "/rgl clearlogfilter",
        about = "Clear log regex filter.",
        handler = function(...)
            Config:SetSetting('LogFilter', "")
        end,
    },
    ['iamnofun'] = {
        usage = "/rgl iamnofun",
        about = "Let the RGMercs devs know you don't like pranks or funny business.",
        handler = function()
            Config:SetSetting('EnableAFUI', false)
            Config:SetSetting('ForceAFUIOff', true)
        end,
    },
    ['togglepause'] = {
        usage = "/rgl togglepause",
        about = "Toggle the pause state of your RGMercs Main Loop.",
        handler = function()
            Globals.PauseMain = not Globals.PauseMain
        end,
    },
    ['pause'] = {
        usage = "/rgl pause",
        about = "Pauses your RGMercs Main Loop.",
        handler = function()
            Globals.PauseMain = true
        end,
    },
    ['pauseall'] = {
        usage = "/rgl pauseall",
        about = "Pauses the RGMercs Main Loop for every client running RGMercs.",
        handler = function()
            Globals.PauseMain = true
            Core.DoCmd("/squelch /dge /rgl pause")
            Logger.log_info("\ayAll clients paused!")
        end,
    },
    ['unpause'] = {
        usage = "/rgl unpause",
        about = "Unpauses your RGMercs Main Loop.",
        handler = function()
            Globals.PauseMain = false
        end,
    },
    ['unpauseall'] = {
        usage = "/rgl unpauseall",
        about = "Unpauses the RGMercs Main Loop for every client running RGMercs.",
        handler = function()
            Globals.PauseMain = false
            Core.DoCmd("/squelch /dge /rgl unpause")
            Logger.log_info("\agAll clients unpaused!")
        end,
    },
    ['rescanloadout'] = {
        usage = "/rgl rescanloadout",
        about = "Rescans your current loadout for changes.",
        handler = function()
            Modules:ExecModule("Class", "RescanLoadout")
        end,
    },
    ['yes'] = {
        usage = "/rgl yes",
        about = "All groupmembers running RGMercs will click on every possible 'Yes' Dialogue they have up.",
        handler = function()
            Comms.SendAllPeersDoCmd(false, true, "/notify LargeDialogWindow LDW_YesButton leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify LargeDialogWindow LDW_YesButton leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify LargeDialogWindow LDW_OkButton leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify ConfirmationDialogBox CD_Yes_Button leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify ConfirmationDialogBox CD_OK_Button leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify TradeWND TRDW_Trade_Button leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify GiveWnd GVW_Give_Button leftmouseup ")
            Comms.SendAllPeersDoCmd(false, true, "/notify ProgressionSelectionWnd ProgressionTemplateSelectAcceptButton leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify TaskSelectWnd TSEL_AcceptButton leftmouseup")
            Comms.SendAllPeersDoCmd(false, true, "/notify RaidWindow RAID_AcceptButton leftmouseup")
        end,
    },
    ['circle'] = {
        usage = "/rgl circle <radius>",
        about = "All groupmembers running RGMercss will form a circle around you using the entered radius.",
        handler = function(radius)
            if not radius then radius = 15 end

            local peers = Comms.GetPeers(false)
            local peerCount = #peers
            if peerCount < 1 then return end
            local angle_step = (2 * math.pi) / peerCount

            for i, peerFullName in ipairs(peers) do
                local peerName = Comms.GetNameFromPeer(peerFullName)
                local radians = (i - 1) * angle_step
                local xMove = math.cos(radians) * (radius)
                local yMove = math.sin(radians) * (radius)

                local xOff = mq.TLO.Me.X() + math.floor(xMove)
                local yOff = mq.TLO.Me.Y() + math.floor(yMove)

                Core.DoCmd("/dex %s /nav locyxz %2.3f %2.3f %2.3f", peerName, yOff, xOff, mq.TLO.Me.Z())
                Core.DoCmd("/dex %s /timed 50 /face %s", peerName, mq.TLO.Me.DisplayName())
            end
        end,
    },
    ['mini'] = {
        usage = "/rgl mini",
        about = "Toggle minimizing of the RGMercs window to a small icon.",
        handler = function()
            Globals.Minimized = not Globals.Minimized
        end,
    },
    ['help'] = {
        handler = function()
            printf("RGMercs [%s/%s] by: %s running for %s (%s)", Config._version, Config._subVersion, Config._author,
                Globals.CurLoadedChar,
                Globals.CurLoadedClass)
            printf("\n\agCore \awCommand Help\aw\n------------\n")
            for c, d in pairs(Binds.Handlers) do
                if c ~= "help" then
                    printf("\am%-20s\aw - \atUsage: \ay%-30s\aw | %s", c, d.usage, d.about)
                end
            end

            local moduleCommands = Modules:ExecAll("GetCommandHandlers")

            for _, info in pairs(moduleCommands) do
                local printHeader = true
                if info.CommandHandlers then
                    for c, d in pairs(info.CommandHandlers or {}) do
                        if printHeader then
                            printf("\n\ag%s\aw Specific Commands Help\n------------\n", info.module)
                            printHeader = false
                        end
                        printf("\am%-20s\aw - \atUsage: \ay%-60s\aw | %s", c, d.usage, d.about)
                    end
                end
            end
        end,
    },
    ['pop'] = {
        usage = "/rgl pop <modulename>",
        about = "Toggles between popped and docked states for <modulename>.",
        handler = function(config, value)
            if config == 'debug' or config == 'console' then
                Config:SetSetting("PopOutConsole", not Config:GetSetting("PopOutConsole"))
            else
                Modules:ExecModule(config, "Pop")
            end
        end,
    },
    ['faq'] = {
        usage = "/rgl faq \"<search terms>\"",
        about = "Search the FAQ and display the results in the mq2 console. Please see the FAQ tab for a friendlier experience!",
        handler = function(config, value)
            Modules:ExecModule('FAQ', "FaqFind", config)
        end,
    },
    ['options'] = {
        usage = "/rgl options [module]",
        about = "Opens the RGMercs Options window. If a module name is given, opens with that module's settings highlighted.",
        handler = function(module)
            if not module or module:len() == 0 then
                Config:SetSetting('EnableOptionsUI', true)
                return
            end
            for name in pairs(Modules:GetModuleList()) do
                if name:lower() == module:lower() then
                    Config:OpenOptionsUIAndHighlightModule(name)
                    return
                end
            end
            Logger.log_warn("\ayNo loaded module named '\at%s\ay' to highlight.", module)
        end,
    },
    ['search'] = {
        usage = "/rgl search <text>",
        about = "Opens the RGMercs Options window and places <text> in the search filter.",
        handler = function(...)
            local allText = { ..., }
            local text
            for _, t in ipairs(allText) do
                text = (text and text .. " " or "") .. t
            end
            OptionsUI:OpenAndSetSearchFilter(text)
        end,
    },
    ['reset_config_position'] = {
        usage = "/rgl reset_config_position",
        about = "Resets the Options Window position to the center of the screen.",
        handler = function()
            Config.TempSettings.ResetOptionsUIPosition = true
            Logger.log_info("\agOptions Window position will be reset on next open.")
        end,
    },
    ['dbconvert'] = {
        usage = "/rgl dbconvert",
        about = "Converts your config to the new DB format. Only needed for versions prior to 2.1.0.",
        handler = function()
            Logger.log_info("Converting config to DB format...")
            Config:ConvertToDb()
            Logger.log_info("Config conversion complete!")
        end,
    },
    ['dbcheck'] = {
        usage = "/rgl dbcheck",
        about = "Checks the integrity of your config DB. Only needed for versions prior to 2.1.0.",
        handler = function()
            Logger.log_info("Checking config DB integrity...")
            Config:DbConsistencyCheck()
            Logger.log_info("Config DB integrity check complete!")
        end,
    },
}

return Binds
