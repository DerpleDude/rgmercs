-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

local mq        = require('mq')
local Casting   = require("utils.casting")
local Combat    = require("utils.combat")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Targeting = require("utils.targeting")

return {
    _version          = "2.1 - Project Lazarus",
    _author           = "Derple, Algar",
    ['Modes']         = {
        'DPS',
        'PBAE',
    },
    ['OnModeChange']  = function(self, mode)
        -- if this is enabled weaves will break.
    end,
    ['Themes']        = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.02, g = 0.12, b = 0.24, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.02, g = 0.12, b = 0.24, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.05, g = 0.30, b = 0.60, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.03, g = 0.19, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.05, g = 0.30, b = 0.60, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.05, g = 0.30, b = 0.60, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.02, g = 0.12, b = 0.24, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.65, g = 0.92, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.65, g = 0.92, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.05, g = 0.30, b = 0.60, a = 1.0, }, },
        },
        ['PBAE'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.58, g = 0.15, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.58, g = 0.15, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.23, g = 0.06, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.58, g = 0.15, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.58, g = 0.15, b = 0.00, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.23, g = 0.06, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.58, g = 0.15, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.58, g = 0.15, b = 0.00, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.58, g = 0.15, b = 0.00, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.38, g = 0.10, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.58, g = 0.15, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.58, g = 0.15, b = 0.00, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.58, g = 0.15, b = 0.00, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.23, g = 0.06, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.45, b = 0.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.45, b = 0.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.58, g = 0.15, b = 0.00, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Staff of Phenomenal Power",
            "Staff of Prismatic Power",
        },

        ['OoW_Chest'] = {
            "Academic's Robe of the Arcanists",
            "Spelldeviser's Cloth Robe",
        },
    },
    ['AbilitySets']   = {
        -- ['IceClaw'] = {
        --     "Claw of Vox",   -- Level 69
        --     "Claw of Frost", -- Level 61
        -- },
        ['FireEtherealNuke'] = {
            "Ether Blaze", -- Level 71 Laz Custom
            "Ether Flame", -- Level 70
        },
        ['ChaosNuke'] = {
            -- "Ancient: Chaos Elements", -- Level 71 Laz Custom, verify existence and source
            "Chaos Flame", -- Level 70
        },
        ['WildNuke'] = {
            "Wildmagic Salvo", -- Level 71 Laz Custom
            "Wildmagic Burst", -- Level 68
        },
        ['FireNuke'] = {
            "Spark of Fire",   -- Level 66
            "Draught of Ro",   -- Level 62
            "Draught of Fire", -- Level 51
            "Conflagration",   -- Level 43
            "Inferno Shock",   -- Level 26
            "Flame Shock",     -- Level 15
            "Fire Bolt",       -- Level 5
            "Shock of Fire",   -- Level 4
        },
        ['BigFireNuke'] = {    -- Level 51-70, Long Cast, Heavy Damage
            -- "Ancient: Core Fire",         -- Level 70, Ether Flame beats this soundly at the same level
            -- "Corona Flare",               -- Level 70, Ether Flame beats this soundly at the same level
            "Ancient: Strike of Chaos",      -- Level 65
            "White Fire",                    -- Level 65
            "Strike of Solusek",             -- Level 65
            "Garrison's Superior Sundering", -- Level 60
            "Sunstrike",                     -- Level 60
        },
        ['IceNuke'] = {
            -- "Ancient: Spear of Gelaqua", -- Level 70, Commented for now, because of the recast... considering, need to playtest.
            "Spark of Ice",                -- Level 69
            "Black Ice",                   -- Level 65
            "Draught of E`ci",             -- Level 64
            "Draught of Ice",              -- Level 57
            "Ice Comet",                   -- Level 49
            "Ice Shock",                   -- Level 34
            "Frost Shock",                 -- Level 24
            "Shock of Ice",                -- Level 8
            "Blast of Cold",               -- Level 1
        },
        ['BigIceNuke'] = {                 -- Level 60-70, Timed with great Ratio or High Cast Time/Damage
            "Gelidin Comet",               -- Level 69
            "Ice Meteor",                  -- Level 64
            "Ancient: Destruction of Ice", -- Level 60, 13s T1
            "Ice Spear of Solist",         -- Level 60, 13s T2
        },
        ['MagicNuke'] = {
            "Draught of Lightning",          -- Level 63
            "Voltaic Draught",               -- Level 54
            "Rend",                          -- Level 47
            "Lightning Shock",               -- Level 37
            "Garrison's Mighty Mana Shock",  -- Level 18
            "Shock of Lightning",            -- Level 10
        },
        ['BigMagicNuke'] = {                 -- Level 60-68, High Cast Time/Damage
            "Thundaka",                      -- Level 68
            "Shock of Magic",                -- Level 65
            "Agnarr's Thunder",              -- Level 63
            "Elnerick's Electrical Rending", -- Level 60
        },
        ['StunSpell'] = {
            "Telakemara",       -- Level 70 Laz Custom
            "Telekara",         -- Level 70
            "Telaka",           -- Level 65
            "Telekin",          -- Level 61
            "Markar's Discord", -- Level 56
            "Markar's Clash",   -- Level 47
            "Tishan's Clash",   -- Level 19
        },
        ['SelfHPBuff'] = {
            "Bolster of the Sorcerer", -- Level 71 Laz Custom
            "Ether Shield",            -- Level 66
            "Shield of Maelin",        -- Level 64
            "Shield of the Arcane",    -- Level 61
            "Shield of the Magi",      -- Level 54
            "Arch Shielding",          -- Level 44
            "Greater Shielding",       -- Level 33
            "Major Shielding",         -- Level 23
            "Shielding",               -- Level 15
            "Lesser Shielding",        -- Level 6
            "Minor Shielding",         -- Level 1
        },
        ['FamiliarBuff'] = {
            "Greater Familiar", -- Level 60
            "Familiar",         -- Level 54
            "Lesser Familiar",  -- Level 45
            "Minor Familiar",   -- Level 25
        },
        ['SelfRune1'] = {
            "Supernal Skin", -- Level 71 Laz Custom
            "Ether Skin",    -- Level 68
            "Force Shield",  -- Level 63
        },
        ['ArcaneSanctuary'] = {
            "Arcane Sanctuary", -- Level 71 Laz Custom
        },
        -- ['Dispel'] = {
        --     "Annul Magic",   -- Level 53
        --     "Nullify Magic", -- Level 34
        --     "Cancel Magic",  -- Level 11
        -- },
        -- ['RootSpell'] = {
        --     "Greater Fetter",   -- Level 61
        --     "Fetter",           -- Level 58
        --     "Paralyzing Earth", -- Level 48
        --     "Immobilize",       -- Level 39
        --     "Instill",          -- Level 17
        --     "Root",             -- Level 3
        -- },
        ['SnareSpell'] = {
            "Atol's Spectral Shackles", -- Level 51
            "Bonds of Force",           -- Level 27
        },
        ['EvacSpell'] = {
            "Evacuate",        -- Level 57
            "Lesser Evacuate", -- Level 18
        },
        ['HarvestSpell'] = {
            "Serenity Harvest", -- Level 71 Laz Custom
            "Harvest",          -- Level 32
        },
        ['JoltSpell'] = {
            "Ancient: Greater Concussion", -- Level 60
            "Concussion",                  -- Level 37
        },
        -- ['IceLureNuke'] = {
        --     "Icebane",       -- Level 66
        --     "Lure of Ice",   -- Level 60
        --     "Lure of Frost", -- Level 52
        -- },
        -- ['FireLureNuke'] = {
        --     "Firebane",            -- Level 68
        --     "Lure of Ro",          -- Level 62
        --     "Lure of Flame",       -- Level 55
        --     "Enticement of Flame", -- Level 44
        -- },
        -- ['MagicLureNuke'] = {
        --     "Lightningbane",     -- Level 67
        --     "Lure of Thunder",   -- Level 61
        --     "Lure of Lightning", -- Level 58
        -- },
        -- ['StunMagicNuke'] = {
        --     "Spark of Thunder",   -- Level 68
        --     "Draught of Thunder", -- Level 63
        --     "Draught of Jiva",    -- Level 55
        --     "Force Strike",       -- Level 41
        --     "Thunder Strike",     -- Level 28
        --     "Force Snap",         -- Level 17
        --     "Lightning Bolt",     -- Level 16
        -- },
        -- ['MagicRain'] = { -- Last one is at 54, not sustainable
        --     "Pillar of Lightning", -- Level 54
        --     "Tears of Druzzil",    -- Level 52
        --     "Energy Storm",        -- Level 26
        -- },
        ['IceRain'] = {
            "Gelid Rains",     -- Level 70
            "Tears of Marr",   -- Level 65
            "Tears of Prexus", -- Level 58
            "Frost Storm",     -- Level 41
            "Icestrike",       -- Level 6
        },
        ['FireRain'] = {
            "Tears of the Sun", -- Level 66
            "Tears of Ro",      -- Level 61
            "Tears of Solusek", -- Level 55
            "Lava Storm",       -- Level 32
            "Firestorm",        -- Level 12
        },
        -- ['FireLureRain'] = {
        --     "Meteor Storm",     -- Level 69
        --     "Tears of Arlyxir", -- Level 64
        -- },
        ['PBTimer4'] = {
            "Circle of Thunder", -- Level 70, Magic
            "Circle of Fire",    -- Level 67, Fire
            "Winds of Gelid",    -- Level 60, Ice
            "Supernova",         -- Level 45, Fire
            "Thunderclap",       -- Level 30, Magic
        },
        ['FireJyll'] = {
            "Jyll's Wave of Heat", -- Level 59
        },
        ['IceJyll'] = {
            "Jyll's Zephyr of Ice", -- Level 56
        },
        ['MagicJyll'] = {
            "Jyll's Static Pulse", -- Level 53
        },
        ['WeaveNuke'] = {
            "Ethereal Weave", -- Level 71 Laz Custom
            "Mana Weave",     -- Level 69
        },
        ['AEStunNuke'] = {
            "Eruption of Telakemara", -- Level 71 Laz Custom
        },
        ['SwarmPet'] = {
            "Evoker's Pyromantic Blade", -- Level 71 Laz Custom
            -- "Solist's Frozen Sword", -- Level 69, Bugged, does not attack on Laz/Emu
            -- "Flaming Sword of Xuzl", -- Level 59, homework
        },
    },
    ['AASets']        = {
        ['Devastation'] = {
            "Prolonged Destruction",
            "Frenzied Devastation",
        },
        ['ManaBurn'] = {
            "Volatile Mana Blaze",
            "Mana Blaze",
            "Mana Blast",
            "Mana Burn",
        },
        ['FamiliarAA'] = {
            "Kerafyrm's Prismatic Familiar",
            "Ro's Flaming Familiar",
            "Improved Familiar",
        },
    },
    ['Charm']         = {
        ['Assist'] = {
            {
                name = "StunSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoStun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToDebuff() and Targeting.TargetNotStunned() and not Casting.StunImmuneTarget(target)
                end,
            },
        },
    },
    ['Helpers']       = {

        RainCheck = function(target) -- I made a funny
            if not (Config:GetSetting('DoRain') and Config:GetSetting('DoAEDamage')) then return false end
            return Targeting.GetTargetDistance() >= Config:GetSetting('RainDistance') and Targeting.MobNotLowHP(target)
        end,
        HasWeaveRotation = function()
            return Core.GetResolvedActionMapItem('WeaveNuke') and Core.GetResolvedActionMapItem('FireEtherealNuke')
        end,
        UseHarvestSpell = function()
            local harvest = Core.GetResolvedActionMapItem('HarvestSpell')
            return (harvest and harvest.RankName.Name() == "Serenity Harvest") or not Casting.CanUseAA("Harvest of Druzzil")
        end,
    },
    ['RotationOrder'] = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'Aggro Management',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctAggro() > (Config:GetSetting('JoltAggro') or 90)
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        { --Keep things from doing
            name = 'Stun',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoStun') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'DPS(HighLevel)',
            state = 1,
            steps = 1,
            load_cond = function(self) return self.Helpers.HasWeaveRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and
                    not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(FireLowLevel)',
            state = 1,
            steps = 1,
            load_cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 1 end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and
                    not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(IceLowLevel)',
            state = 1,
            steps = 1,
            load_cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 2 end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and
                    not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(MagicLowLevel)',
            state = 1,
            steps = 1,
            load_cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 3 end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and
                    not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(PBAE)',
            state = 1,
            steps = 1,
            load_cond = function() return Core.IsModeActive('PBAE') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoAEDamage') then return false end
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'Force of Will',
            state = 1,
            steps = 1,
            load_cond = function() return Casting.CanUseAA("Force of Will") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay()
            end,
        },
        {
            name = 'CombatBuff',
            state = 1,
            steps = 1,
            timer = 10,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Buff("Focus of Arcanum")()
            end,
        },
    },
    ['Rotations']     = {
        ['Burn'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
            },
            {
                name = "Fundament: Second Spire of Arcanum",
                type = "AA",
            },
            {
                name = "Fury of Ro",
                type = "AA",
            },
            {
                name = "Forsaken Sorceror's Shoes",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Sorceror's Shoes")() end,
            },
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            { --Crit Chance AA, will use the first(best) one found
                name = "Devastation",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Silent Casting",
                type = "AA",
            },
            {
                name = "ManaBurn",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoManaBurn') end,
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() < 70 and Casting.OkayToNuke(true) and not mq.TLO.Target.FindBuff("detspa 350")()
                end,
            },
            {
                name = "Call of Xuzl",
                type = "AA",
            },
        },
        ['Aggro Management'] =
        {
            {
                name = "Mind Crash",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 90
                end,
            },
            {
                name = "Arcane Whisper",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 90
                end,
            },
            {
                name = "A Hole in Space",
                type = "AA",
                cond = function(self)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Concussive Intuition",
                type = "AA",
                cond = function(self)
                    return mq.TLO.Me.PctAggro() > Config:GetSetting('JoltAggro')
                end,
            },
            {
                name = "JoltSpell",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Concussive Intuition") end,
                cond = function(self)
                    return mq.TLO.Me.PctAggro() > Config:GetSetting('JoltAggro')
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Atol's Shackles",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Stun'] = {
            {
                name = "StunSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.HaveManaToDebuff() and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed and not Casting.StunImmuneTarget(target)
                end,
            },
        },
        ['CombatBuff'] =
        {
            {
                name = "Harvest of Druzzil",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Harvest of Druzzil") end,
                allowDead = true,
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('CombatHarvestManaPct')
                end,
            },
            {
                name = "HarvestSpell",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UseHarvestSpell() end,
                allowDead = true,
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('CombatHarvestManaPct')
                end,
            },
        },
        ['Force of Will'] = {
            {
                name = "Force of Will",
                type = "AA",
            },
        },
        ['DPS(HighLevel)'] = {
            {
                name = "WeaveNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return not Casting.IHaveBuff("Weave of Power")
                end,
            },
            {
                name = "AEStunNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAEStunNuke') end,
                cond = function(self, spell, target)
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "SwarmPet",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSwarmPet') end,
            },
            {
                name = "ChaosNuke",
                type = "Spell",
            },
            {
                name = "WildNuke",
                type = "Spell",
            },
            {
                name = "Scepter of Incantations",
                type = "Item",
            },
            {
                name = "FireEtherealNuke",
                type = "Spell",
            },
        },
        ['DPS(FireLowLevel)'] = {
            {
                name = "WildNuke",
                type = "Spell",
            },
            {
                name = "FireRain",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.RainCheck(target)
                end,
            },
            {
                name = "BigFireNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
            },
        },
        ['DPS(IceLowLevel)'] = {
            {
                name = "WildNuke",
                type = "Spell",
            },
            {
                name = "IceRain",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.RainCheck(target)
                end,
            },
            {
                name = "BigIceNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
            },
        },
        ['DPS(MagicLowLevel)'] = {
            {
                name = "WildNuke",
                type = "Spell",
            },
            {
                name = "BigMagicNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
            },
        },
        ['DPS(PBAE)'] = {
            {
                name = "AEStunNuke",
                type = "Spell",
                allowDead = true,
            },
            {
                name = "PBTimer4",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "FireJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "IceJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "MagicJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return (spell.Level() or 0) > (mq.TLO.Me.AltAbility("Etherealist's Unity").Spell.Trigger(1).Level() or 0) and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SelfRune1",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "ArcaneSanctuary",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            { --Familiar AA, will use the first(best) one found
                name = "FamiliarAA",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "FamiliarBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('FamiliarAA') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Harvest of Druzzil",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Harvest of Druzzil") end,
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('HarvestManaPct')
                end,
            },
            {
                name = "HarvestSpell",
                type = "Spell",
                load_cond = function(self) return self.Helpers.UseHarvestSpell() end,
                cond = function(self, spell)
                    return Casting.CastReady(spell) and mq.TLO.Me.PctMana() < Config:GetSetting('HarvestManaPct')
                end,
            },
        },
        ['ArcanumWeave'] = {
            {
                name = "Empowered Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Enlightened Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Acute Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
    },
    ['SpellList']     = {
        {
            name = "Default Mode",
            spells = {
                { name = "WeaveNuke",        cond = function(self) return self.Helpers.HasWeaveRotation() end, },
                { name = "FireNuke",         cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 1 end, },
                { name = "IceNuke",          cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 2 end, },
                { name = "MagicNuke",        cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 3 end, },
                { name = "FireEtherealNuke", cond = function(self) return self.Helpers.HasWeaveRotation() end, },
                { name = "BigFireNuke",      cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 1 end, },
                { name = "BigIceNuke",       cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 2 end, },
                { name = "BigMagicNuke",     cond = function(self) return not self.Helpers.HasWeaveRotation() and Config:GetSetting('ElementChoice') == 3 end, },
                { name = "WildNuke", },
                {
                    name = "FireRain",
                    cond = function(self)
                        return not self.Helpers.HasWeaveRotation() and Config:GetSetting('DoRain') and Config:GetSetting('ElementChoice') == 1
                    end,
                },
                {
                    name = "IceRain",
                    cond = function(self)
                        return not self.Helpers.HasWeaveRotation() and Config:GetSetting('DoRain') and Config:GetSetting('ElementChoice') == 2
                    end,
                },
                { name = "ChaosNuke",    cond = function(self) return self.Helpers.HasWeaveRotation() end, },
                { name = "HarvestSpell", cond = function(self) return self.Helpers.UseHarvestSpell() end, },
                { name = "SnareSpell",   cond = function() return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Atol's Shackles") end, },
                { name = "StunSpell",    cond = function() return Config:GetSetting('DoStun') end, },
                { name = "JoltSpell",    cond = function() return not Casting.CanUseAA("Concussive Intuition") end, },
                { name = "SwarmPet",     cond = function() return Config:GetSetting('DoSwarmPet') end, },
                { name = "AEStunNuke",   cond = function() return Config:GetSetting('DoAEStunNuke') end, },
                { name = "PBTimer4",     cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "FireJyll",     cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "IceJyll",      cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "MagicJyll",    cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "SelfRune1", },
                { name = "EvacSpell",    cond = function() return not Casting.CanUseAA("Exodus") end, },
                { name = "SelfHPBuff", },
            },
        },
    },
    ['DefaultConfig'] = {
        ['Mode']                 = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes Do?",
            Answer = "Wizard only has a single mode, but the spells used will adjust based on your level range.",
        },

        -- Damage (ST)
        ['ElementChoice']        = {
            DisplayName = "Element Choice:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Choose an element to focus on.",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Ice', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoManaBurn']           = {
            DisplayName = "Use Mana Burn AA",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Enable usage of the Mana Burn series of AA.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoRain']               = {
            DisplayName = "Do Rain",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            Tooltip = "**WILL BREAK MEZ** Use your selected element's Rain Spell as a single-target nuke. **WILL BREAK MEZ***",
            Default = false,
            FAQ = "Why is Rain being used a single target nuke?",
            Answer = "In some situations, using a Rain can be an efficient single target nuke at low levels.\n" ..
                "Note that PBAE spells tend to be superior for AE dps at those levels.",
        },
        ['RainDistance']         = {
            DisplayName = "Min Rain Distance",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            ConfigType = "Advanced",
            Tooltip = "The minimum distance a target must be to use a Rain (Rain AE Range: 25'). Used to avoid harming the caster.",
            Default = 30,
            Min = 0,
            Max = 100,
        },
        ['DoAEStunNuke']         = {
            DisplayName = "Do AE Stun Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 105,
            Tooltip = "Use your targeted AE stun nuke on clustered mobs during your main rotation.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSwarmPet']           = {
            DisplayName = "Do Swarm Pet",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 106,
            Tooltip = "Use your swarm pet spell.",
            RequiresLoadoutChange = true,
            Default = false,
        },

        -- Utility
        ['JoltAggro']            = {
            DisplayName = "Jolt Aggro %",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 101,
            Tooltip = "Aggro at which to use Jolt",
            Default = 90,
            Min = 1,
            Max = 100,
        },
        ['DoSnare']              = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare Spells.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']           = {
            DisplayName = "Snare Max Mob Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 102,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro. Helpful for AoE groups.",
            Default = 3,
            Min = 1,
            Max = 99,
            FAQ = "Why is my Shadow Knight Not snaring?",
        },
        ['DoStun']               = {
            DisplayName = "Do Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Use your Stun Nukes (Stun with DD, not mana efficient).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['HarvestManaPct']       = {
            DisplayName = "Harvest Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            ConfigType = "Advanced",
            Tooltip = "What Mana % to hit before using a harvest spell or aa.",
            Default = 85,
            Min = 1,
            Max = 99,
        },
        ['CombatHarvestManaPct'] = {
            DisplayName = "Combat Harvest %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            ConfigType = "Advanced",
            Tooltip = "What Mana % to hit before using a harvest spell or aa in Combat.",
            Default = 40,
            Min = 1,
            Max = 99,
        },
        ['DoArcanumWeave']       = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
    },
    ['ClassFAQ']      = {
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
