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
local Targeting = require("utils.targeting")

return {
    _version          = "2.11 - EQ Might",
    _author           = "Derple, Algar",
    ['ModeChecks']    = {
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or not Targeting.HasXTHaters()) end,
        IsCuring = function() return Config:GetSetting('DoCures') and Casting.CanUseAA("Radiant Cure") end,
        IsDispelling = function() return Config:GetSetting('DoDispel') and Casting.CanUseAA("Eradicate Magic") end,
    },
    ['Dispel']        = {
        { name = "Eradicate Magic", type = "AA", },
    },
    ['Rez']           = {
        ['Combat']   = {
            { type = "Item", name = "RezStaff", },
        },
        ['Downtime'] = {
            { type = "Item", name = "RezStaff", },
        },
    },
    ['Cure']          = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
        },
    },
    ['Modes']         = {
        'DPS',
        'PBAE',
    },
    ['OnModeChange']  = function(self, mode)
        -- if this is enabled weaves will break.
        self.TempSettings.AutoElementOrder = self.Helpers.AutoElementOrder(self)
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
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
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
        --     "Claw of Selay", -- Level 72
        --     "Claw of Vox",   -- Level 69
        --     "Claw of Frost", -- Level 61
        -- },
        ['FlashNuke'] = {
            "Flashfires", -- Level 72
        },
        ['FireNuke'] = {
            "Sothgar's Flame",               -- Level 72
            -- "Chaos Immolation",           -- Level 72
            "Chaos Flame",                   -- Level 70
            "Spark of Fire",                 -- Level 66
            "Draught of Ro",                 -- Level 62
            "Draught of Fire",               -- Level 51
            "Conflagration",                 -- Level 43
            "Inferno Shock",                 -- Level 26
            "Flame Shock",                   -- Level 15
            "Fire Bolt",                     -- Level 5
            "Shock of Fire",                 -- Level 4
        },
        ['BigFireNuke'] = {                  -- Level 51-70, Long Cast, Heavy Damage
            "Ethereal Conflagration",        -- Level 72
            "Ether Flame",                   -- Level 70
            "Ancient: Core Fire",            -- Level 68
            "Corona Flare",                  -- Level 67
            "Ancient: Strike of Chaos",      -- Level 65
            "White Fire",                    -- Level 65
            "Strike of Solusek",             -- Level 65
            "Garrison's Superior Sundering", -- Level 60
            "Sunstrike",                     -- Level 60
        },
        ['SnapNuke'] = {
            "Cold Snap", -- Level 71
        },
        ['SpearNuke'] = {
            "Ancient: Spear of Gelaqua", -- Level 68
        },
        ['ColdNuke'] = {
            "Spark of Ice",                -- Level 69
            "Black Ice",                   -- Level 65
            "Draught of E`ci",             -- Level 64
            "Draught of Ice",              -- Level 57
            "Frozen Harpoon",              -- Level 52
            "Ice Comet",                   -- Level 49
            "Ice Shock",                   -- Level 34
            "Frost Shock",                 -- Level 24
            "Shock of Ice",                -- Level 8
            "Blast of Cold",               -- Level 1
        },
        ['BigColdNuke'] = {                -- Level 60-70, Timed with great Ratio or High Cast Time/Damage
            "Icefall Avalanche",           -- Level 72
            "Gelidin Comet",               -- Level 69
            "Ice Meteor",                  -- Level 64
            "Ancient: Destruction of Ice", -- Level 60, 13s T1
            "Ice Spear of Solist",         -- Level 60, 13s T2
        },
        ['BurstNuke'] = {
            "Cloudburst Strike", -- Level 71
        },
        ['MidMagicNuke'] = {
            "Intertwining Energy", -- Level 72
            "Ball Lightning",      -- Level 71
        },
        ['QuickMagicNuke'] = {
            "Pure Wildmagic", -- Level 72
            "Leap of Sparks", -- Level 71
        },
        ['MagicNuke'] = {
            "Spark of Lightning",            -- Level 68
            "Draught of Lightning",          -- Level 63
            "Voltaic Draught",               -- Level 54
            "Rend",                          -- Level 47
            "Lightning Shock",               -- Level 37
            "Garrison's Mighty Mana Shock",  -- Level 18
            "Shock of Lightning",            -- Level 10
        },
        ['BigMagicNuke'] = {                 -- Level 60-70, High Cast Time/Damage
            "Mana Weave",                    -- Level 69
            "Thundaka",                      -- Level 68
            "Shock of Magic",                -- Level 65
            "Agnarr's Thunder",              -- Level 63
            "Elnerick's Electrical Rending", -- Level 60
        },
        ['StunSpell'] = {
            "Telakisz",         -- Level 72
            "Telekara",         -- Level 70
            "Telaka",           -- Level 65
            "Telekin",          -- Level 64
            "Markar's Discord", -- Level 56
            "Markar's Clash",   -- Level 47
            "Tishan's Clash",   -- Level 19
        },
        ['SelfHPBuff'] = {
            "Shield of the Crystalwing", -- Level 70
            "Ether Shield",              -- Level 66
            "Shield of Maelin",          -- Level 64
            "Shield of the Arcane",      -- Level 61
            "Shield of the Magi",        -- Level 54
            "Arch Shielding",            -- Level 44
            "Greater Shielding",         -- Level 33
            "Major Shielding",           -- Level 23
            "Shielding",                 -- Level 15
            "Lesser Shielding",          -- Level 6
            "Minor Shielding",           -- Level 1
        },
        ['FamiliarBuff'] = {
            "Greater Familiar", -- Level 60
            "Familiar",         -- Level 54
            "Lesser Familiar",  -- Level 45
            "Minor Familiar",   -- Level 25
        },
        ['ManaBuff'] = {
            "Inner Arcane Calm", -- Level 72 EQM Custom
        },
        ['SelfRune1'] = {
            "Crystalwing Ward", -- Level 72
            "Ether Ward",       -- Level 69
            "Ether Skin",       -- Level 68
            "Force Shield",     -- Level 63
        },
        ['Dispel'] = {
            "Annul Magic",   -- Level 53
            "Nullify Magic", -- Level 34
            "Cancel Magic",  -- Level 11
        },
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
            "Patient Harvest", -- Level 71
            "Harvest",         -- Level 32
        },
        ['JoltSpell'] = {
            "Concussive Blast",            -- Level 70
            "Ancient: Greater Concussion", -- Level 60
            "Concussion",                  -- Level 37
        },
        -- Lure Spells (I may implement these in the future. It would need some testing... and yet more options. Custom config users, double check these lists before use!)
        -- ['IceLureNuke'] = {
        --     "Rimelure",      -- Level 70
        --     "Icebane",       -- Level 66
        --     "Lure of Ice",   -- Level 60
        --     "Lure of Frost", -- Level 52
        -- },
        -- ['FireLureNuke'] = {
        --     "Lavalure",            -- Level 71
        --     "Firebane",            -- Level 68
        --     "Lure of Ro",          -- Level 62
        --     "Lure of Flame",       -- Level 55
        --     "Lure of Fire",        -- Level 48 EQM Custom
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
        ['ColdRain'] = {
            "Icicle Deluge",   -- Level 72
            "Gelid Rains",     -- Level 70
            "Tears of Marr",   -- Level 65
            "Tears of Prexus", -- Level 58
            "Frost Storm",     -- Level 41
            "Icestrike",       -- Level 6
        },
        ['FireRain'] = {
            "Tears of the Betrayed", -- Level 70
            "Tears of the Sun",      -- Level 66
            "Tears of Ro",           -- Level 61
            "Tears of Solusek",      -- Level 55
            "Lava Storm",            -- Level 32
            "Firestorm",             -- Level 12
        },
        -- ['FireLureRain'] = {
        --     "Meteor Storm",     -- Level 69
        --     "Tears of Arlyxir", -- Level 64
        -- },
        ['PBTimer4'] = {
            "Magmaraug's Presence", -- Level 71, Fire
            "Circle of Thunder",    -- Level 70, Magic
            "Circle of Fire",       -- Level 67, Fire
            "Winds of Gelid",       -- Level 60, Ice
            "Supernova",            -- Level 45, Fire
            "Thunderclap",          -- Level 30, Magic
        },
        ['FireJyll'] = {
            "Jyll's Wave of Heat", -- Level 59
        },
        ['ColdJyll'] = {
            "Jyll's Zephyr of Ice", -- Level 56
        },
        ['MagicJyll'] = {
            "Jyll's Static Pulse", -- Level 53
        },
        ['SwarmPet'] = {
            -- "Solist's Frozen Sword", -- Level 69, Bugged, does not attack on Laz/Emu
            "Flaming Sword of Xuzl", -- Level 59
        },
        -- ['SpellWard'] = {
        --     "Bulwark of Calrena", -- Level 70
        --     "Defense of Calrena", -- Level 70
        -- },
    },
    ['AASets']        = {
        ['Spire'] = {
            "Fundament: Third Spire of Arcanum",
            "Fundament: Second Spire of Arcanum",
            "Fundament: First Spire of Arcanum",
        },
        ['SnareAA'] = {
            "Atol's Unresistable Shackles",
            "Atol's Shackles",
        },
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
    },
    ['Helpers']       = {
        RainCheck = function(target) -- I made a funny
            if not (Config:GetSetting('DoRain') and Config:GetSetting('DoAEDamage')) then return false end
            return Targeting.GetTargetDistance() >= Config:GetSetting('RainDistance') and Targeting.MobNotLowHP(target)
        end,

        --- Don't start a slow-casting nuke when the target is low hp (lvl 72 nukes are faster).
        ---@param spell MQSpell The resolved big nuke.
        ---@param target MQSpawn The nuke target.
        ---@return boolean
        BigNukeCheck = function(spell, target)
            return (spell.Level() or 0) >= 72 or Targeting.MobNotLowHP(target)
        end,

        --- Returns true once all three level 71+ magic nuke sets resolve.
        ---@return boolean
        HasMagicNukes = function()
            return Core.GetResolvedActionMapItem('BurstNuke') ~= nil and Core.GetResolvedActionMapItem('MidMagicNuke') ~= nil and
                Core.GetResolvedActionMapItem('QuickMagicNuke') ~= nil
        end,

        --- Returns the Auto mode element order, strongest first for the nukes in your book.
        ---@return string[]
        AutoElementOrder = function(self)
            local bigFire = Core.GetResolvedActionMapItem('BigFireNuke')
            local bigCold = Core.GetResolvedActionMapItem('BigColdNuke')
            if self.Helpers.HasMagicNukes() then
                if (bigFire and bigFire.Level() or 0) < 72 then return { "Magic", "Fire", "Cold", } end
            elseif (bigCold and bigCold.Level() or 0) >= 69 then
                return { "Fire", "Cold", "Magic", }
            end
            return { "Fire", "Magic", "Cold", }
        end,

        -- Resolves the currently-active element based on ElementMode.
        -- Auto: tries elements in AutoElementOrder, skipping any element the auto-target is
        -- immune to (per the Spawn List) or one toggled off via Skip<X>Spells.
        PickElement = function(self)
            local mode = Config:GetSetting('ElementMode') or 1
            if mode == 2 then return "Fire" end
            if mode == 3 then return "Cold" end
            if mode == 4 then return "Magic" end
            local autoId = Globals.AutoTargetID or 0
            for _, element in ipairs(self.TempSettings.AutoElementOrder or { "Fire", "Magic", "Cold", }) do
                if not Casting.ShouldSkipElement(element, autoId) then return element end
            end
            return "Fire" -- all skipped; default so Fury/Familiar still resolve
        end,

        -- Familiar element pick: explicit element if set, Fire fallback in Auto. See FAQ.
        PickFamiliarElement = function(self)
            local mode = Config:GetSetting('ElementMode') or 1
            if mode == 2 then return "Fire" end
            if mode == 3 then return "Cold" end
            if mode == 4 then return "Magic" end
            return "Fire"
        end,

        CurrentFamiliarName = function(self)
            local familiars = { Fire = "Ro's Flaming Familiar", Cold = "E'ci's Icy Familiar", Magic = "Druzzil's Mystical Familiar", }
            if (Config:GetSetting('ElementMode') or 1) == 1 then
                for _, element in ipairs(self.TempSettings.AutoElementOrder or { "Fire", }) do
                    if Casting.CanUseAA(familiars[element]) then return familiars[element] end
                end
            end
            return familiars[self.Helpers.PickFamiliarElement(self)] or "Unknown Error"
        end,
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Emergency(Health)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return Targeting.HasXTHaters() and Core.AtEmergencyHP()
            end,
        },
        {
            name = 'Aggro Management',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctAggro() > (Config:GetSetting('JoltAggro') or 90) and Casting.OkayToCombatEscape()
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
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.HasXTHatersMax(Config:GetSetting('SnareCount'))
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
            name = 'DPS(Fire)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if self.Helpers.PickElement(self) ~= "Fire" then return false end
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(Cold)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if self.Helpers.PickElement(self) ~= "Cold" then return false end
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(Magic)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if self.Helpers.PickElement(self) ~= "Magic" then return false end
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
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
            name = 'Weaves',
            state = 1,
            steps = 1,
            load_cond = function() return Casting.CanUseAA("Force of Will") or Casting.CanUseAA("Lower Element") end,
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
    },
    ['Rotations']     = {
        ['GroupBuff'] = { -- Added to anchor clickies to

        },
        ['Burn'] = {
            {
                name = "Epic",
                type = "Item",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
            },
            { -- Use the selected spire, fall back to the AA set if we don't have it.
                name_func = function(self)
                    local chosen = "Fundament: " .. Globals.Constants.SpireChoices[Config:GetSetting('SpireChoice')] .. " Spire of Arcanum"
                    return Casting.CanUseAA(chosen) and chosen or "Spire"
                end,
                type = "AA",
                load_cond = function() return Config:GetSetting('SpireChoice') ~= 4 end,
            },
            { -- Fury AA: split per element so Auto mode picks the right one on the fly each burn pass
                name = "Fury of Ro",
                type = "AA",
                cond = function(self) return self.Helpers.PickElement(self) == "Fire" end,
            },
            {
                name = "Fury of Eci",
                type = "AA",
                cond = function(self) return self.Helpers.PickElement(self) == "Cold" end,
            },
            {
                name = "Fury of Druzzil",
                type = "AA",
                cond = function(self) return self.Helpers.PickElement(self) == "Magic" end,
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
            -- { -- temporarily commented, can lead to serious xtarg issues
            --     name = "Ward of Destruction",
            --     type = "AA",
            --     cond = function(self, aaName, target)
            --         return Config:GetSetting('DoAEDamage')
            --     end,
            -- },
        },
        ['Emergency(Health)'] = {
            {
                name = "Eternal Recovery",
                type = "AA",
            },
        },
        ['Aggro Management'] =
        {
            {
                name = "Mind Crash",
                type = "AA",
                IgnoreImmuneCheck = true,
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Arcane Whisper",
                type = "AA",
                IgnoreImmuneCheck = true,
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "JoltSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoJoltSpell') end,
            },
        },
        ['Snare'] = {
            {
                name = "SnareAA",
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
        ['CombatBuff'] = {
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
                load_cond = function(self) return not Casting.CanUseAA("Harvest of Druzzil") end,
                allowDead = true,
                cond = function(self)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('CombatHarvestManaPct')
                end,
            },
        },
        ['Weaves'] = {
            {
                name = "Lower Element",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Force of Will",
                type = "AA",
            },
        },
        ['DPS(Fire)'] = {
            {
                name = "Pyromancy",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Pyromancy") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "FireRain",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRain') end,
                cond = function(self, spell, target)
                    return self.Helpers.RainCheck(target)
                end,
            },
            {
                name = "FlashNuke",
                type = "Spell",
            },
            {
                name = "BigFireNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.BigNukeCheck(spell, target)
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
            },
        },
        ['DPS(Cold)'] = {
            {
                name = "Cryomancy",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Cryomancy") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "ColdRain",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRain') end,
                cond = function(self, spell, target)
                    return self.Helpers.RainCheck(target)
                end,
            },
            {
                name = "SnapNuke",
                type = "Spell",
            },
            {
                name = "SpearNuke",
                type = "Spell",
            },
            {
                name = "BigColdNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.BigNukeCheck(spell, target)
                end,
            },
            {
                name = "ColdNuke",
                type = "Spell",
            },
        },
        ['DPS(Magic)'] = {
            {
                name = "Arcomancy",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Arcomancy") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "BurstNuke",
                type = "Spell",
            },
            {
                name = "MidMagicNuke",
                type = "Spell",
            },
            {
                name = "QuickMagicNuke",
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
                name = "ColdJyll",
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
                name = "ManaBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SelfRune1",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Improved Familiar",
                type = "AA",
                load_cond = function(self)
                    return Casting.CanUseAA("Improved Familiar") and
                        (Config:GetSetting('FamiliarChoice') == 1 or not Casting.CanUseAA(self.Helpers.CurrentFamiliarName(self)))
                end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return not mq.TLO.Me.Buff(aaName)()
                end,
            },
            { --Familiar AA, will use the correct element; Improved above covers the fallback
                name_func = function(self)
                    return self.Helpers.CurrentFamiliarName(self)
                end,
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                load_cond = function(self) return Config:GetSetting('FamiliarChoice') == 2 end,
                pre_activate = function(self, aaName) -- remove the old familiar in case of stacking issues when switching elements
                    if not mq.TLO.Me.Buff(aaName)() and mq.TLO.Me.Buff("Familiar")() then
                        mq.TLO.Me.Buff("Familiar").Remove()
                    end
                end,
                cond = function(self, aaName)
                    if not Casting.CanUseAA(aaName) then return false end
                    return not mq.TLO.Me.Buff(aaName)()
                end,
            },
            {
                name = "FamiliarBuff",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Improved Familiar") and not Casting.CanUseAA("Ro's Flaming Familiar") end, --in case someone skipped improved
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
                load_cond = function(self) return not Casting.CanUseAA("Harvest of Druzzil") end,
                cond = function(self, spell)
                    return Casting.CastReady(spell) and mq.TLO.Me.PctMana() < Config:GetSetting('HarvestManaPct')
                end,
            },
        },
    },
    ['SpellList']     = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "FlashNuke", },
                { name = "BigFireNuke", },
                { name = "FireNuke", },
                { name = "SnapNuke", },
                { name = "SpearNuke", },
                { name = "BigColdNuke", },
                { name = "ColdNuke",       cond = function() return not Core.GetResolvedActionMapItem('SnapNuke') end, },
                { name = "BurstNuke", },
                { name = "MidMagicNuke", },
                { name = "QuickMagicNuke", },
                { name = "BigMagicNuke",   cond = function(self) return not self.Helpers.HasMagicNukes() end, },
                { name = "MagicNuke",      cond = function(self) return not self.Helpers.HasMagicNukes() end, },
                { name = "FireRain",       cond = function() return Config:GetSetting('DoRain') end, },
                { name = "ColdRain",       cond = function() return Config:GetSetting('DoRain') end, },
                { name = "HarvestSpell",   cond = function() return not Casting.CanUseAA("Harvest of Druzzil") end, },
                { name = "SnareSpell",     cond = function() return Config:GetSetting('DoSnare') and not Core.GetResolvedActionMapItem('SnareAA') end, },
                { name = "EvacSpell",      cond = function() return Config:GetSetting('KeepEvacMemmed') end, },
                { name = "StunSpell",      cond = function() return Config:GetSetting('DoStun') end, },
                { name = "JoltSpell",      cond = function() return Config:GetSetting('DoJoltSpell') end, },
                { name = "PBTimer4",       cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "FireJyll",       cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "ColdJyll",       cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "MagicJyll",      cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "SelfRune1", },
                { name = "SelfHPBuff", },
            },
        },
    },
    ['DefaultConfig'] = {
        ['Mode']                 = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon. PBAE mode beats single target at 3-4 targets in the mid 60s, 5 at 70, 7 at 71 and 8 at 72.",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes Do?",
            Answer = "DPS mode nukes your target with your current element. PBAE mode memorizes point-blank AE spells and uses them instead when enough targets are in range.",
        },
        ['DoDispel']             = {
            DisplayName = "Do Dispel",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Dispel",
            Index = 101,
            Tooltip = "Enable removing beneficial enemy effects.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        -- Damage (ST)
        ['ElementMode']          = {
            DisplayName = "Element Mode:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Choose the element you nuke with. Auto uses your strongest element, skipping any your target is immune to.",
            Type = "Combo",
            ComboOptions = { 'Auto', 'Fire', 'Cold', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
            FAQ = "How does Element Mode work?",
            Answer =
                "Element Mode chooses the element you nuke with.\n" ..
                "Auto uses the strongest element you have nukes for, skipping any element your target is immune to or that you turned off with Skip <Element> Spells.\n" ..
                "Fire, Cold and Magic modes lock to that element, but Skip <Element> Spells still applies.",
        },
        ['DoManaBurn']           = {
            DisplayName = "Use Mana Burn AA",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Enable usage of the Mana Burn series of AA.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoRain']               = {
            DisplayName = "Do Rain",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 105,
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
            Index = 106,
            ConfigType = "Advanced",
            Tooltip = "The minimum distance a target must be to use a Rain (Rain AE Range: 25'). Used to avoid harming the caster.",
            Default = 30,
            Min = 0,
            Max = 100,
        },

        -- Utility
        ['DoJoltSpell']          = {
            DisplayName = "Use Jolt Spell",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 101,
            Tooltip = "Memorize and cast your jolt line of spells.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['JoltAggro']            = {
            DisplayName = "Jolt Aggro %",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 102,
            Tooltip = "Aggro at which to use Jolt and other similar abilities.",
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
            Default = 60,
            Min = 1,
            Max = 99,
        },
        ['KeepEvacMemmed']       = {
            DisplayName = "Memorize Evac",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Keep (Lesser) Evacuate memorized.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['FamiliarChoice']       = {
            DisplayName = "Familiar Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Choose which familiar buff you would like to maintain on yourself:\n" ..
                "Improved: Increased spell crit damage, etc.\n" ..
                "Elemental: Improved spell damage.",
            Type = "Combo",
            ComboOptions = { 'Improved', 'Elemental', },
            Default = 1,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
        },
        ['SpireChoice']          = {
            DisplayName = "Spire Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Choose which Fundament you would like to use during burns:\n" ..
                "First Spire: Spell Crit Chance Buff to Self.\n" ..
                "Second Spire: Spell Crit Damage Buff to Self.\n" ..
                "Third Spire: Detrimental Spell Mana Cost Reduction.",
            Type = "Combo",
            ComboOptions = Globals.Constants.SpireChoices,
            RequiresLoadoutChange = true,
            Default = 2,
            Min = 1,
            Max = #Globals.Constants.SpireChoices,
        },
    },
}
