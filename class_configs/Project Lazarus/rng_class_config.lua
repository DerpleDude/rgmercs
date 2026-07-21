local mq        = require('mq')
local Casting   = require("utils.casting")
local Combat    = require("utils.combat")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Movement  = require("utils.movement")
local Targeting = require("utils.targeting")

return {
    _version              = "2.1 - Project Lazarus",
    _author               = "Algar",
    ['ModeChecks']        = {
        IsHealing = function() return Config:GetSetting('DoHeals') end,
    },
    ['Modes']             = {
        'DPS',
    },
    ['Themes']            = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.05, g = 0.13, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.05, g = 0.13, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.12, g = 0.32, b = 0.08, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.08, g = 0.21, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.12, g = 0.32, b = 0.08, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.12, g = 0.32, b = 0.08, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.05, g = 0.13, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.70, g = 0.48, b = 0.12, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.70, g = 0.48, b = 0.12, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.12, g = 0.32, b = 0.08, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Aurora, the Heartwood Blade",
            "Heartwood Blade",
        },
        ['OoW_Chest'] = {
            "Sunrider's Vest",
            "Bladewhipser Chain Vest of Journeys",
        },
    },
    ['AbilitySets']       = {
        ['PredatorBuff'] = {          -- Groupv2 Atk Buff
            "Snarl of the Predator",  -- Level 71 Laz Custom
            "Howl of the Predator",   -- Level 69
            "Spirit of the Predator", -- Level 64
            "Call of the Predator",   -- Level 60
            "Mark of the Predator",   -- Level 53
        },
        ['StrengthHPBuff'] = {        -- Groupv2 HP Type 2, Atk
            "Strength of the Hunter", -- Level 67
            "Strength of Tunare",     -- Level 62
            "Strength of Nature",     -- Level 51, Single Target
        },
        ['SkinBuff'] = {              -- ST HP Type 1, small regen
            "Onyx Skin",              -- Level 70
            "Natureskin",             -- Level 65
            "Skin like Nature",       -- Level 59
            "Skin like Diamond",      -- Level 54
            "Skin like Steel",        -- Level 38
            "Skin like Rock",         -- Level 21
            "Skin like Wood",         -- Level 7
        },
        ['EyeBuff'] = {               -- Self Archery Buff
            "Eyes of the Drake",      -- Level 71 Laz Custom
            "Eyes of the Hawk",       -- Level 70 Laz Custom
            "Eyes of the Owl",        -- Level 65
            "Eyes of the Eagle",      -- Level 59 Laz Custom
        },
        ['FireNukeT1'] = {            -- ST Fire DD, Timer 1, 30s Recast
            "Embers of the Delve",    -- Level 71 Laz Custom
            "Hearth Embers",          -- Level 69
            "Sylvan Burn",            -- Level 65
            "Call of Flame",          -- Level 49
            "Flaming Arrow",          -- Level 29
        },
        ['ColdNukeT2'] = {            -- ST Cold DD, Timer 2, 30s Recast
            "Frost of the Ascent",    -- Level 71 Laz Custom
            "Frost Wind",             -- Level 68
            "Icewind",                -- Level 52
        },
        ['ColdNukeT3'] = {            -- ST Cold DD, Timer 3, 30s Recast
            "Ancient: North Wind",    -- Level 70
            "Frozen Wind",            -- Level 63
        },
        ['FireNukeT4'] = {            -- ST Fire DD, Timer 4, 30s Recast
            "Scorched Earth",         -- Level 70
            "Ancient: Burning Chaos", -- Level 65
            "Brushfire",              -- Level 64
            "Burning Arrow",          -- Level 39
        },
        ['DDProc'] = {
            "Call of Storms",    -- Level 71 Laz Custom
            "Call of Lightning", -- Level 70, Double damage against humanoids on Laz
            "Cry of Thunder",    -- Level 65
            "Call of Ice",       -- Level 58
            "Call of Fire",      -- Level 55
            "Call of Sky",       -- Level 36
        },
        -- ['SummonedProc'] = {
        --     "Nature's Denial", -- Level 69
        --     "Nature's Rebuke", -- Level 64
        -- },
        ['SelfBuff'] = {
            "Ward of the Stalker",    -- Level 71 Laz Custom
            "Ward of the Hunter",     -- Level 70
            "Protection of the Wild", -- Level 65
            "Warder's Protection",    -- Level 60
            "Nature's Precision",     -- Level 37, Self ATK Buff, filler
            "Firefist",               -- Level 17, Self ATK Buff, filler
        },
        ['ArrowHail'] = {             -- DirAE multihit archery attack
            "Hail of Arrows",         -- Level 65
        },
        ['FocusedHail'] = {           -- ST multihit archery attack
            -- "Ancient: Focused Barrage of Arrows", -- Level 71 Laz Custom, verify existence and source
            "Focused Hail of Arrows", -- Level 69 Laz Custom
        },
        ['Dispel'] = {
            "Nature's Balance", -- Level 69
            "Annul Magic",      -- Level 61
            "Nullify Magic",    -- Level 58
            "Cancel Magic",     -- Level 30
        },
        ['Heartshot'] = {
            "Heartshatter", -- Level 71 Laz Custom
            "Heartslit",    -- Level 68 Laz Custom
            "Heartshot",    -- Level 65
        },
        ['RegenBuff'] = {
            "Hunter's Vigor",        -- Level 68
            "Regrowth",              -- Level 64
            "Chloroplast",           -- Level 55
        },
        ['CoatBuff'] = {             -- Self DS
            "Briarcoat",             -- Level 68
            "Bladecoat",             -- Level 63
            "Thorncoat",             -- Level 60
            "Spikecoat",             -- Level 42
            "Bramblecoat",           -- Level 34
            "Barbcoat",              -- Level 30
            "Thistlecoat",           -- Level 13
        },
        ['GuardBuff'] = {            -- ST AC DS Buff
            "Guard of Thundercrest", -- Level 71 Laz Custom
            "Guard of the Earth",    -- Level 67
            "Call of the Rathe",     -- Level 62
            "Call of Earth",         -- Level 50
            "Riftwind's Protection", -- Level 25
        },
        ['HealSpell'] = {
            "Swift Salve of the Stillmoon", -- Level 71 Laz Custom
            "Sylvan Water",                 -- Level 67
            "Sylvan Light",                 -- Level 65
            "Chloroblast",                  -- Level 62
            "Greater Healing",              -- Level 57
            "Healing",                      -- Level 38
            "Light Healing",                -- Level 21
            "Minor Healing",                -- Level 8
            "Salve",                        -- Level 1
        },
        ['SwarmDot'] = {
            "Locust Swarm",      -- Level 67
            "Drifting Death",    -- Level 62
            "Fire Swarm",        -- Level 55
            "Drones of Doom",    -- Level 54
            "Swarm of Pain",     -- Level 40
            "Stinging Swarm",    -- Level 25
        },
        ['KickDisc'] = {         -- 2-hit kick attack
            -- "Jolting Thunderkicks", -- Level 71 Laz Custom, verify existence and source
            "Jolting Snapkicks", -- Level 66
        },
        ['Bullseye'] = {
            "Bullseye Discipline", -- Level 66
            "Trueshot Discipline", -- Level 55
        },
        ['ShieldDS'] = {           -- ST Slot 1 DS
            "Shield of Briar",     -- Level 66
            "Shield of Thorns",    -- Level 62
            "Shield of Spikes",    -- Level 58
            "Shield of Brambles",  -- Level 43
            "Shield of Thistles",  -- Level 24
        },
        ['FlameSnap'] = {
            "Flame Snap",  -- Level 66 Laz Custom
        },
        ['NatureProc'] = { -- ST Hade reduction defensive proc buff
            "Nature Veil", -- Level 66
        },
        -- ['DDStunProcBuff'] = {
        --     "Sylvan Call", -- Level 65
        -- },
        -- ['MaskBuff'] = { -- no stack with eyes of the hawk
        --     "Mask of the Stalker", -- Level 65
        -- },
        ['MoveBuff'] = {
            "Spirit of Eagle", -- Level 65
        },
        -- ['SelfWolfBuff'] = {
        --     "Feral Form",        -- Level 64
        --     "Greater Wolf Form", -- Level 56
        --     "Wolf Form",         -- Level 48
        -- },
        ['ColdResistBuff'] = {
            "Circle of Summer", -- Level 63
        },
        ['FireResistBuff'] = {
            "Circle of Winter", -- Level 61
        },
        ['SnareSpell'] = {
            "Earthen Shackles", -- Level 69
            "Earthen Embrace",  -- Level 61
            "Ensnare",          -- Level 51
            "Tangle",           -- Level 51
            "Snare",            -- Level 6
            "Tangling Weeds",   -- Level 5
        },
        ['WeaponShield'] = {
            "Weapon Shield Discipline", -- Level 60
        },
        ['JoltSpell'] = {
            "Cinder Jolt", -- Level 55
            "Jolt",        -- Level 50
        },
        -- ['JoltProcBuff'] = {
        --     "Jolting Blades", -- Level 54
        -- },
        -- ['ResistDisc'] = {
        --     "Resistant Discipline", -- Level 51
        -- },
    },
    ['Charm']             = {
        ['Assist'] = {
            { name = "Taunt", type = "Ability", },
        },
    },
    ['HealRotationOrder'] = {
        { -- configured as a backup healer, will not cast in the mainpoint
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Config:GetSetting('DoHeals') end,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['BigHealPoint'] = {
            {
                name = "HealSpell",
                type = "Spell",
            },
        },
    },
    ['RotationOrder']     = {
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Ranged Positioning',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Config:GetSetting('DoMelee')
            end,
        },
        {
            name = 'Emergency',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99))
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and not Globals.AutoTargetIsNamed and
                    Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Combat',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and (Config:GetSetting('DoHeals') and Casting.OkayToNuke() or Targeting.AggroCheckOkay())
            end,
        },
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and Core.CombatActionsCheck()
            end,
        },
    },
    ['Helpers']           = {
        HaveSelfWard = function(self)
            local ward = Core.GetResolvedActionMapItem('SelfBuff')
            return ward and Casting.IHaveBuff(ward) or false
        end,
        rangedNav = function(reason)
            if Config:GetSetting('DoMelee') then return false end
            if (Globals.AutoTargetID or 0) == 0 then return false end

            local bowRange = Config:GetSetting('BowRange')

            if reason then
                Logger.log_verbose("rangedNav: reason=%s dist=%d bowRange=%d stick=%s LoS=%s", reason,
                    Targeting.GetTargetDistance(), bowRange, Config:GetSetting('UseRangedStick'), mq.TLO.Target.LineOfSight())
            end

            if not mq.TLO.Me.Moving() then
                Core.DoCmd('/squelch /face fast')
            end

            if not mq.TLO.Me.AutoFire() then
                Core.DoCmd('/autofire on')
            end

            -- No line of sight: sweep laterally around the target for a spot with a real (game) clear shot.
            if reason == "cantsee" then
                if not Movement:NavAroundCircle(mq.TLO.Target, bowRange) then
                    -- Nav can't path (off the mesh): stick toward the target to walk back onto it.
                    Logger.log_warn("Ranged nav: no navigable line-of-sight spot (off mesh?), falling back to a stick.")
                    Movement:DoStickCmd("%d id %d moveback uw", bowRange, Globals.AutoTargetID)
                    if not Config:GetSetting('UseRangedStick') then
                        -- Loose holds nothing: run the stick only until we regain line of sight, then drop it.
                        mq.delay(100, function() return mq.TLO.Stick.Active() end)
                        mq.delay(3000, function() return mq.TLO.Target.ID() == 0 or mq.TLO.Target.LineOfSight() end)
                        Movement:DoStickCmd("off")
                        Movement:ClearLastStickTimer()
                    end
                end
                return true
            end

            if Config:GetSetting('UseRangedStick') then -- Use Ranged Stick: hold bow range with a stick.
                if reason == "toofar" or Targeting.GetTargetDistance() > bowRange + 10 then
                    if not mq.TLO.Navigation.Active() then
                        Movement:DoNav(true, "id %d distance=%d lineofsight=on", Globals.AutoTargetID, bowRange)
                        Core.DoCmd('/squelch /face fast')
                    end
                elseif (mq.TLO.Stick.StickTarget() or 0) ~= Globals.AutoTargetID or (mq.TLO.Stick.Status() or "off"):lower() == "off" then
                    Core.DoCmd('/squelch /face fast')
                    -- DEPRECATED 7/26 - sunset 9/1/26. StickHow passthrough, mirroring DoStick.
                    local stickHow = Config:GetSetting('StickHow') or ""
                    if #stickHow > 0 then
                        Movement:DoStickCmd("%s", stickHow)
                    else
                        local stickDist = Config:GetSetting('StickDistance') or ""
                        if stickDist == "" then stickDist = tostring(bowRange) end
                        local stickArgs = Config:GetSetting('StickArgs') or ""
                        if stickArgs == "" then stickArgs = "moveback uw" end
                        Movement:DoStickCmd("%s id %d %s", stickDist, Globals.AutoTargetID, stickArgs)
                    end
                end
            else -- Loose: react to the game's own range messages, one-shot, no held position.
                if reason == "toofar" then
                    Movement:DoNav(true, "id %d distance=%d lineofsight=on", Globals.AutoTargetID, bowRange)
                    Core.DoCmd('/squelch /face fast')
                elseif reason == "tooclose" then
                    Core.DoCmd('/squelch /face fast')
                    Movement:DoStickCmd("%d moveback uw", bowRange)
                    mq.delay(100, function() return mq.TLO.Stick.Active() end)
                    mq.delay(500, function() return not mq.TLO.Me.Moving() end)
                    Movement:DoStickCmd("off")
                    Movement:ClearLastStickTimer()
                end
            end
            return true
        end,
    },
    ['Rotations']         = {
        ['Ranged Positioning'] = {
            {
                name = "Ranged Nav",
                type = "CustomFunc",
                custom_func = function(self)
                    return Core.SafeCallFunc("Ranger Ranged Nav", self.Helpers.rangedNav)
                end,
            },
        },
        ['Burn']               = {
            {
                name = "Auspice of the Hunter",
                type = "AA",
            },
            {
                name = "Fundament: Third Spire of the Pathfinders",
                type = "AA",
            },
            {
                name = "Group Guardian of the Forest",
                type = "AA",
                cond = function(self, aaName, target)
                    return not mq.TLO.Me.Buff("Guardian of the Forest")()
                end,
            },
            {
                name = "Guardian of the Forest",
                type = "AA",
                cond = function(self, aaName, target)
                    return not mq.TLO.Me.Buff("Guardian of the Forest")()
                end,
            },
            { -- tuned on laz to be ranged exclusive
                name = "Outrider's Accuracy",
                type = "AA",
                cond = function(self, aaName, target)
                    return not Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "Outrider's Attack",
                type = "AA",
            },
            { -- increases melee proc chance, but hate reduction applies to all spells
                name = "Imbued Ferocity",
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoMelee') or mq.TLO.Me.PctAggro() >= 60
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Poison Arrows",
                type = "AA",
            },
            {
                name = "Bullseye",
                type = "Disc",
            },
            {
                name_func = function(self) return Config:GetSetting('ArrowBuffChoice') == 1 and "Scout's Mastery of Fire" or "Scout's Mastery of Ice" end,
                type = "AA",
            },
            {
                name_func = function(self) return Config:GetSetting('ArrowBuffChoice') == 1 and "Flaming Arrows" or "Frost Arrows" end,
                type = "AA",
                cond = function(self, aaName, target)
                    if mq.TLO.Me.Buff("Poison Arrows")() then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "JoltSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoJoltSpell') end,
                cond = function(self, spell, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 80
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['Snare']              = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Emergency']          = {
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 35 and Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Protection of the Spirit Wolf",
                type = "AA",
            },
            {
                name = "Outrider's Evasion",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.IHaveAggro(100) and mq.TLO.Me.ActiveDisc() ~= "Weapon Shield Discipline"
                end,
            },
            {
                name = "WeaponShield",
                type = "Disc",
                cond = function(self, discName, target)
                    return Targeting.IHaveAggro(100) and not mq.TLO.Me.Song("Outrider's Evasion")() and Casting.NoDiscActive()
                end,
            },
            {
                name = "Blood Drinker's Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
        ['Combat']             = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if not Config:GetSetting('DoMelee') or Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "SwarmDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSwarmDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Cold Snap",
                type = "AA",
            },
            {
                name = "FireNukeT4",
                type = "Spell",
            },
            {
                name = "FireNukeT1",
                type = "Spell",
            },
            {
                name = "FlameSnap",
                type = "Spell",
            },
            {
                name = "ColdNukeT3",
                type = "Spell",
            },
            {
                name = "ColdNukeT2",
                type = "Spell",
            },
            {
                name = "ArrowHail",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "FocusedHail",
                type = "Spell",
            },
            {
                name = "Heartshot",
                type = "Spell",
            },
        },
        ['Weaves']             = {
            {
                name = "Kick",
                type = "Ability",
            },
            {
                name = "KickDisc",
                type = "Disc",
                cond = function(self, discName, target)
                    return mq.TLO.Me.PctEndurance() >= Config:GetSetting("ManaToNuke")
                end,
            },
        },
        ['GroupBuff']          = {
            {
                name = "PredatorBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target) and not (Targeting.TargetIsMyself(target) and self.Helpers.HaveSelfWard(self))
                end,
            },
            {
                name = "StrengthHPBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoStrengthBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target) and not (Targeting.TargetIsMyself(target) and self.Helpers.HaveSelfWard(self))
                end,
            },
            {
                name = "GuardBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target) and not (Targeting.TargetIsMyself(target) and self.Helpers.HaveSelfWard(self))
                end,
            },
            {
                name = "RegenBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoRegenBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ShieldDS",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoShieldDS') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Spirit of Eagle",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') and Casting.CanUseAA("Spirit of Eagle") end,
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(Casting.GetAASpell(aaName))
                end,
                cond = function(self, aaName, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "MoveBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') and not Casting.CanUseAA("Spirit of Eagle") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ColdResistBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoColdResist') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "FireResistBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoFireResist') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Downtime']           = {
            {
                name = "SelfBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "EyeBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SkinBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "CoatBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "DDProc",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "NatureProc",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name_func = function(self) return Config:GetSetting('ArrowBuffChoice') == 1 and "Flaming Arrows" or "Frost Arrows" end,
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "HealSpell",   cond = function(self) return Config:GetSetting('DoHeals') end, },
                { name = "SnareSpell",  cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA('Entrap') end, },
                { name = "SwarmDot",    cond = function(self) return Config:GetSetting('DoSwarmDot') end, },
                { name = "FireNukeT1", },
                { name = "FireNukeT4", },
                { name = "ColdNukeT2", },
                { name = "ColdNukeT3", },
                { name = "FlameSnap", },
                { name = "Heartshot", },
                { name = "ArrowHail", },
                { name = "FocusedHail", },
                { name = "JoltSpell",   cond = function(self) return Config:GetSetting('DoJoltSpell') end, },
                { name = "MoveBuff",    cond = function(self) return Config:GetSetting('DoMoveBuffs') end, },
            },
        },
    },
    ['DefaultConfig']     = { --TODO: Condense pet proc options into a combo box and update entry conditions appropriately
        ['Mode']            = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Rangers currently only have one Mode. This may change in the future.",
        },

        --Archery
        ['BowRange']        = {
            DisplayName = "Bow Range",
            Group = "Combat",
            Header = "Positioning",
            Category = "Archery",
            Index = 101,
            Tooltip = "The preferred distance to reposition to if we are too close/far or have no LoS (also the default range for ranged stick).",
            Default = 15,
            Min = 10,
            Max = 300,
            FAQ = "Why is my ranger rubber-banding, charging back and forth or changing heading constantly?",
            Answer = "Some terrain blocks LoS while MQ reports that the ranger has LoS.\n" ..
                "While we will attempt to solve this issue, manual intervention or setting adjustment may be required (Bow Range, Ranged Stick, etc).",
        },
        ['UseRangedStick']  = {
            DisplayName = "Use Ranged Stick",
            Group = "Combat",
            Header = "Positioning",
            Category = "Archery",
            Index = 102,
            Tooltip = "Disabled - autofire from present position, moving only if needed (too close/far, no LoS).\n" ..
                "Enabled - use stick while autofiring. Uses Stick How setting if set, otherwise uses '<bowrangesetting> moveback uw'",
            Default = false,
            Warning = function()
                if not Config:GetSetting('UseRangedStick') then return false, "" end
                local bowRange = Config:GetSetting('BowRange')
                if Config:GetSetting('ChaseOn') then
                    if Config:GetSetting('ChaseDistance') < bowRange then
                        return true, "Warning: Chase Distance is below Bow Range - chase may fight the ranged stick hold."
                    end
                elseif Config:GetSetting('ReturnToCamp') and Config:GetSetting('CampLeashCombat') and Config:GetSetting('AutoCampRadius') < bowRange then
                    return true, "Warning: Camp Radius is below Bow Range - Leash to Camp (Combat) may fight the ranged stick hold."
                end
                return false, ""
            end,
            FAQ = "Why is my ranger rubber-banding, charging back and forth or changing heading constantly?",
            Answer = "Turn off Use Ranged Stick (the default), so the ranger only repositions when a shot is actually refused instead of holding position.",
        },

        --Buffs
        ['ArrowBuffChoice'] = {
            DisplayName = "Arrow Element:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Choose which element you would like to focus on with Arrow buffs and Scout's Mastery\n" ..
                "We will use Poison Arrows during burns and switch back to this element (as able) afterwards.",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Cold', },
            Default = 1,
            Min = 1,
            Max = 2,
        },
        ['DoMoveBuffs']     = {
            DisplayName = "Do Spirit of Eagle",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Cast Movement Spells/AA.",
            Default = false,
            RequiresLoadoutChange = true,
            FAQ = "Why am I spamming movement buffs?",
            Answer = "Some move spells freely overwrite those of other classes, so if multiple movebuffs are being used, a buff loop may occur.\n" ..
                "Simply turn off movement buffs for the undesired class in their class options.",
        },
        ['DoRegenBuff']     = {
            DisplayName = "Do Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Use your ST Regen Buff Line.",
            Default = false,
        },
        ['DoStrengthBuff']  = {
            DisplayName = " Do Strength HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Strength of ... HP buff line.",
            Default = true,
        },
        ['DoShieldDS']      = {
            DisplayName = "Do Shield DS",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Use your Shield DS line of spells.",
            Default = true,
        },
        ['DoColdResist']    = {
            DisplayName = "Do Cold Resist",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your group cold resist buff.",
            Default = false,
            FAQ = "Why am I not using my single-target resist buff?",
            Answer = "By default, we will use the group versions you select. Config customization is required if you wish to use the single-target version.",
        },
        ['DoFireResist']    = {
            DisplayName = "Do Fire Resist",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Use your group cold resist buff.",
            Default = false,
        },


        --Combat
        ['DoSwarmDot']     = {
            DisplayName = "Swarm Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Swarm line of dots (magic damage, 54s duration).",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DotNamedOnly']   = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
        },
        ['UseEpic']        = {
            DisplayName = "Epic Use:",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Use Epic 1-Never 2-Burns 3-Always",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['EmergencyStart'] = {
            DisplayName = "Emergency HP%",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Your HP % before we begin to use emergency mitigation abilities.",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoCoating']      = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood Drinker's Coating in an emergency.",
            Default = false,
        },
        ['DoVetAA']        = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },

        --Utility
        ['DoHeals']        = {
            DisplayName = "Do Heals",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Salve spell.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoJoltSpell']    = {
            DisplayName = "Do Jolt Spell",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 101,
            Tooltip = "Use your Jolt spell when your aggro is high.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoSnare']        = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']     = {
            DisplayName = "Snare Max Mob Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 102,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro. Helpful for AoE groups.",
            Default = 3,
            Min = 1,
            Max = 99,
        },
        ['HealPriority']   = {
            DisplayName = "Healing Priority",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Type = "Combo",
            ComboOptions = { 'Ignore', 'Big Heal Point', },
            Default = 2,
            Min = 1,
            Max = 2,
            Tooltip = "When to yield offensive rotations for healing:\n1 - Ignore (never)\n2 - Big Heal Point",
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release customized specifically for Project Lazarus server.\n\n" ..
                "  This config should perform admirably from start to endgame.\n\n" ..
                "  Clickies that aren't already included should be managed via the clickies tab, or by customizing the config to add them directly.\n" ..
                "  Additionally, those wishing more fine-tune control for specific encounters or raids should customize this config to their preference. \n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}
