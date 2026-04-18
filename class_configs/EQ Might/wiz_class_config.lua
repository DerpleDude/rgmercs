-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require("utils.globals")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Core      = require("utils.core")
local Logger    = require("utils.logger")
local Combat    = require("utils.combat")

return {
    _version          = "2.2 - EQ Might",
    _author           = "Derple, Algar",
    ['ModeChecks']    = {
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Modes']         = {
        'DPS',
        'PBAE',
    },
    ['OnModeChange']  = function(self, mode)
        -- if this is enabled weaves will break.
    end,
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
        --     "Claw of Vox",
        --     "Claw of Frost",
        -- },
        ['WildNuke'] = {
            "Wildmagic Strike",
        },
        ['FireNuke'] = {
            "Chaos Flame",
            "Spark of Fire",
            "Draught of Ro",
            "Draught of Fire",
            "Conflagration",
            "Inferno Shock",
            "Flame Shock",
            "Fire Bolt",
            "Shock of Fire",
        },
        ['BigFireNuke'] = { -- Level 51-70, Long Cast, Heavy Damage
            "Ether Flame",
            "Ancient: Core Fire",
            "Corona Flare", --67 on EQM
            "Ancient: Strike of Chaos",
            "White Fire",
            "Strike of Solusek",
            "Garrison's Superior Sundering",
            "Sunstrike",
        },
        ['IceNuke'] = {
            "Ancient: Spear of Gelaqua",
            "Spark of Ice",
            "Black Ice",
            "Draught of E`ci",
            "Draught of Ice",
            "Ice Comet",
            "Ice Shock",
            "Frost Shock",
            "Shock of Ice",
            "Blast of Cold",
        },
        ['BigIceNuke'] = { -- Level 60-70, Timed with great Ratio or High Cast Time/Damage
            "Gelidin Comet",
            "Ice Meteor",
            "Ancient: Destruction of Ice", --13s T1
            "Ice Spear of Solist",         --13s T2
        },
        ['MagicNuke'] = {
            "Spark of Lightning",
            "Draught of Lightning",
            "Voltaic Draught",
            "Rend",
            "Lightning Shock",
            "Garrison's Mighty Mana Shock",
            "Shock of Lightning",
        },
        ['BigMagicNuke'] = { -- Level 60-70, High Cast Time/Damage
            "Mana Weave",
            "Thundaka",
            "Shock of Magic",
            "Agnarr's Thunder",
            "Elnerick's Electrical Rending",
        },
        ['StunSpell'] = {
            "Telekara",
            "Telaka",
            "Telekin",
            "Markar's Discord",
            "Markar's Clash",
            "Tishan's Clash",
        },
        ['SelfHPBuff'] = {
            "Shield of the Crystalwing",
            "Ether Shield",
            "Shield of Maelin",
            "Shield of the Arcane",
            "Shield of the Magi",
            "Arch Shielding",
            "Greater Shielding",
            "Major Shielding",
            "Shielding",
            "Lesser Shielding",
            "Minor Shielding",
        },
        ['FamiliarBuff'] = {
            "Greater Familiar",
            "Familiar",
            "Lesser Familiar",
            "Minor Familiar",
        },
        ['SelfRune1'] = {
            "Ether Ward",
            "Ether Skin",
            "Force Shield",
        },
        ['Dispel'] = {
            "Annul Magic",
            "Nullify Magic",
            "Cancel Magic",
        },
        -- ['RootSpell'] = {
        -- "Iceblock",
        --     "Greater Fetter",
        --     "Fetter",
        --     "Paralyzing Earth",
        --     "Immobilize",
        --     "Instill",
        --     "Root",
        -- },
        ['SnareSpell'] = {
            "Atol's Spectral Shackles",
            "Bonds of Force",
        },
        ['EvacSpell'] = {
            "Evacuate",
            "Lesser Evacuate",
        },
        ['HarvestSpell'] = {
            "Patient Harvest",
            "Harvest",
        },
        ['JoltSpell'] = {
            "Concussive Blast",
            "Ancient: Greater Concussion",
            "Concussion",
        },
        -- Lure Spells
        -- ['IceLureNuke'] = {
        -- "RimeLure",
        --     "Icebane",
        --     "Lure of Ice",
        --     "Lure of Frost",
        -- },
        -- ['FireLureNuke'] = {
        --     "Firebane",
        --     "Lure of Ro",
        --     "Lure of Flame",
        --     "Enticement of Flame",
        -- },
        -- ['MagicLureNuke'] = {
        --     "Lightningbane",
        --     "Lure of Thunder",
        --     "Lure of Lightning",
        -- },
        -- ['StunMagicNuke'] = {
        --     "Spark of Thunder",
        --     "Draught of Thunder",
        --     "Draught of Jiva",
        --     "Force Strike",
        --     "Thunder Strike",
        --     "Force Snap",
        --     "Lightning Bolt",
        -- },
        -- ['MagicRain'] = { -- Last one is at 54, not sustainable
        --     "Pillar of Lightning",
        --     "Tears of Druzzil",
        --     "Energy Storm",
        -- },
        ['IceRain'] = {
            "Gelid Rains",
            "Tears of Marr",
            "Tears of Prexus",
            "Frost Storm",
            "Icestrike",
        },
        ['FireRain'] = {
            "Tears of the Betrayed",
            "Tears of the Sun",
            "Tears of Ro",
            "Tears of Solusek",
            "Lava Storm",
            "Firestorm",
        },
        -- ['FireLureRain'] = {
        --     "Meteor Storm",
        --     "Tears of Arlyxir",
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
        ['IceJyll'] = {
            "Jyll's Zephyr of Ice", -- Level 56
        },
        ['MagicJyll'] = {
            "Jyll's Static Pulse", -- Level 53
        },
        ['SwarmPet'] = {
            -- "Solist's Frozen Sword", -- Bugged, does not attack on Laz/Emu
            "Flaming Sword of Xuzl", --homework
        },
        -- ['SpellWard'] = {
        --     "Bulwark of Calrena",
        --     "Defense of Calrena",
        -- },
    },
    ['Helpers']       = {
        DoRez = function(self, corpseId)
            local rezStaff = self.ResolvedActionMap['RezStaff']

            if mq.TLO.Me.ItemReady(rezStaff)() then
                if Casting.OkayToRez(corpseId) then
                    return Casting.UseItem(rezStaff, corpseId)
                end
            end

            return false
        end,

        RainCheck = function(target) -- I made a funny
            if not (Config:GetSetting('DoRain') and Config:GetSetting('DoAEDamage')) then return false end
            return Targeting.GetTargetDistance() >= Config:GetSetting('RainDistance') and Targeting.MobNotLowHP(target)
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
            name = 'WildNuke',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoWildNuke') and Core.GetResolvedActionMapItem('WildNuke') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(Fire)',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('ElementChoice') == 1 or Config:GetSetting('KeepFireMemmed') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if Config:GetSetting('ElementChoice') ~= 1 then return false end
                return combat_state == "Combat" and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(Ice)',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('ElementChoice') == 2 or Config:GetSetting('KeepIceMemmed') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if Config:GetSetting('ElementChoice') ~= 2 then return false end
                return combat_state == "Combat" and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
            end,
        },
        {
            name = 'DPS(Magic)',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('ElementChoice') == 3 or Config:GetSetting('KeepMagicMemmed') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if Config:GetSetting('ElementChoice') ~= 3 then return false end
                return combat_state == "Combat" and not (Core.IsModeActive('PBAE') and Combat.AETargetCheck(true))
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
                return combat_state == "Combat" and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            load_cond = function() return Casting.CanUseAA("Force of Will") or Casting.CanUseAA("Lower Element") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
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
            { --Familiar AA, will use the correct element, and fallback to improved
                name_func = function(self)
                    local furyBuff = { "Fury of Ro", "Fury of Eci", "Fury of Druzzil", }
                    return furyBuff[Config:GetSetting('ElementChoice')] or "Unknown Error"
                end,
                type = "AA",
            },
            { --Crit Chance AA, will use the first(best) one found
                name_func = function(self)
                    return Casting.GetFirstAA({ "Prolonged Destruction", "Frenzied Devastation", })
                end,
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
                name_func = function(self)
                    return Casting.GetFirstAA({ "Volatile Mana Blaze", "Mana Blaze", "Mana Blast", "Mana Burn", })
                end,
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
                name = "JoltSpell",
                type = "Spell",
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
        ['WildNuke'] = {
            {
                name = "WildNuke",
                type = "Spell",
            },
        },
        ['DPS(Fire)'] = {
            {
                name = "Pyromancy",
                type = "AA",
                load_condtion = function(self) return Casting.CanUseAA("Pyromancy") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "FireRain",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRain') end,
                cond = function(self, spell, target)
                    if not self.Helpers.RainCheck(target) then return false end
                    return Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "BigFireNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target) and Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay()
                end,
            },
        },
        ['DPS(Ice)'] = {
            {
                name = "Cryomancy",
                type = "AA",
                load_condtion = function(self) return Casting.CanUseAA("Cryomancy") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "IceRain",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRain') end,
                cond = function(self, spell, target)
                    if not self.Helpers.RainCheck(target) then return false end
                    return Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "BigIceNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target) and Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay()
                end,
            },
        },
        ['DPS(Magic)'] = {
            {
                name = "Acromancy",
                type = "AA",
                load_condtion = function(self) return Casting.CanUseAA("Acromancy") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "BigMagicNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target) and Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay()
                end,
            },
        },
        ['DPS(PBAE)'] = {
            {
                name = "PBTimer4",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay() and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "FireJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay() and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "IceJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay() and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "MagicJyll",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.AggroCheckOkay() and Targeting.InSpellRange(spell, target)
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
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            { --Familiar AA, will use the correct element, and fallback to improved
                name_func = function(self)
                    local familiars = { "Ro's Flaming Familiar", "E'ci's Icy Familiar", "Druzzil's Mystical Familiar", }
                    local currentFam = familiars[Config:GetSetting('ElementChoice')] or "Unknown Error"
                    return Casting.CanUseAA(currentFam) and currentFam or "Improved Familiar"
                end,
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
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
                { name = "FireNuke",     cond = function() return Config:GetSetting('ElementChoice') == 1 or Config:GetSetting('KeepFireMemmed') end, },
                { name = "BigFireNuke",  cond = function() return Config:GetSetting('ElementChoice') == 1 or Config:GetSetting('KeepFireMemmed') end, },
                { name = "IceNuke",      cond = function() return Config:GetSetting('ElementChoice') == 2 or Config:GetSetting('KeepIceMemmed') end, },
                { name = "BigIceNuke",   cond = function() return Config:GetSetting('ElementChoice') == 2 or Config:GetSetting('KeepIceMemmed') end, },
                { name = "MagicNuke",    cond = function() return Config:GetSetting('ElementChoice') == 3 or Config:GetSetting('KeepMagicMemmed') end, },
                { name = "BigMagicNuke", cond = function() return Config:GetSetting('ElementChoice') == 3 or Config:GetSetting('KeepMagicMemmed') end, },
                { name = "WildNuke",     cond = function() return Config:GetSetting('DoWildNuke') end, },
                { name = "FireRain",     cond = function() return Config:GetSetting('DoRain') and Config:GetSetting('ElementChoice') == 1 end, },
                { name = "IceRain",      cond = function() return Config:GetSetting('DoRain') and Config:GetSetting('ElementChoice') == 2 end, },
                { name = "HarvestSpell", cond = function() return not Casting.CanUseAA("Harvest of Druzzil") end, },
                { name = "SnareSpell",   cond = function() return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Atol's Shackles") end, },
                { name = "EvacSpell",    cond = function() return Config:GetSetting('KeepEvacMemmed') end, },
                { name = "StunSpell",    cond = function() return Config:GetSetting('DoStun') end, },
                { name = "JoltSpell",    cond = function() return Config:GetSetting('DoJoltSpell') end, },
                { name = "PBTimer4",     cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "FireJyll",     cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "IceJyll",      cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "MagicJyll",    cond = function() return Core.IsModeActive('PBAE') end, },
                { name = "SelfRune1", },
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
            Tooltip = "Choose which element-specific nukes and buffs will be used. See FAQ for more details.",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Ice', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
            FAQ = "How do I select to use multiple elements in combat?",
            Answer =
                "   The 'Element Choice' setting determines which element you will use in combat. To avoid conflicts with the Familiar, 'Fury' and '-mancy' AA buffs, the default class config will focus on a single element at a time.\n\n" ..
                "   The choice can be changed in combat (used in conjuction with the 'Keep X Memmed' settings), but we will not rescribe spells in combat, and Fury/Familiars will not be updated in the rotation until after combat is over.\n\n" ..
                "   PBAE spells, if enabled, will use any available element, due to the nature of their recast timers.",
        },
        ['KeepFireMemmed']       = {
            DisplayName = "Keep Fire Memmed",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Regardless of our current element selection, keep fire spells memorized so that we can switch elements in combat without changing our loadout.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['KeepIceMemmed']        = {
            DisplayName = "Keep Ice Memmed",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Regardless of our current element selection, keep ice spells memorized so that we can switch elements in combat without changing our loadout.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['KeepMagicMemmed']      = {
            DisplayName = "Keep Magic Memmed",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Regardless of our current element selection, keep magic spells memorized so that we can switch elements in combat without changing our loadout.",
            RequiresLoadoutChange = true,
            Default = false,
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
        ['DoWildNuke']           = {
            DisplayName = "Do Wild Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 105,
            Tooltip = "Cast Wildmagic Strike.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoRain']               = {
            DisplayName = "Do Rain",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 106,
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
            Index = 107,
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
    },
    ['ClassFAQ']      = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is currently a Work-In-Progress that was originally based off of the Project Lazarus config.\n\n" ..
                "  Up until level 70, it should work quite well, but may need some clickies managed on the clickies tab.\n\n" ..
                "  After level 68, however, there hasn't been any playtesting... some AA may need to be added or removed still, and some Laz-specific entries may remain.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}
