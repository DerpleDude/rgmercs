local mq        = require('mq')
local Casting   = require("utils.casting")
local Combat    = require('utils.combat')
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require('utils.globals')
local Targeting = require("utils.targeting")

return {
    _version              = "1.8 - EQ Might",
    _author               = "Derple, Algar",
    ['Modes']             = {
        'DPS',
    },
    ['PetPosition']       = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
    },
    ['ModeChecks']        = {
        IsHealing = function() return Config:GetSetting('DoHealSpell') end,
        IsCuring = function() return Config:GetSetting('DoCures') end,
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Nature's Salve", selfOnly = true, },
        },
    },
    ['Rez']               = {
        ['Combat']   = {
            { type = "Item", name = "RezStaff", },
        },
        ['Downtime'] = {
            { type = "Item", name = "RezStaff", },
        },
    },
    ['Themes']            = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.20, g = 0.11, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.20, g = 0.11, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.50, g = 0.28, b = 0.03, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.33, g = 0.18, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.50, g = 0.28, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.50, g = 0.28, b = 0.03, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.20, g = 0.11, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.90, g = 0.45, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.90, g = 0.45, b = 0.05, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.50, g = 0.28, b = 0.03, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Savage Lord's Totem",             -- Epic    -- Epic 1.5
            "Spiritcaller Totem of the Feral", -- Epic    -- Epic 2.0
        },
        ['OoW_Chest'] = {
            "Beast Tamer's Jerkin",
            "Savagesoul Jerkin of the Wilds",
        },
        ['Razorclaw'] = {
            "Artifact of Greater Razorclaw",
            "Artifact of Razorclaw",
        },
    },
    ['AbilitySets']       = { --TODO/Under Consideration: Add AoE Roar line, add rotation entry (tie it to Do AoE setting), swap in instead of lance 2, especially since the last lance2 is level 112
        ['SwarmPet'] = {
            -- Swarm Pet
            "Bestial Empathy", -- Level 68
        },
        ['Icelance1'] = {
            -- Lance 1 Timer 7 Ice Nuke Fast Cast
            "Ancient: Savage Ice",   -- Level 68 - Timer 7
            "Ancient: Frozen Chaos", -- Level 65 - Timer 7
            "Frost Spear",           -- Level 63 - Timer 7
            "Blizzard Blast",        -- Level 59 - Timer ???
            "Frost Shard",           -- Level 47 - Timer 7
            "Blast of Frost",        -- Level 12 - Timer 7
        },
        ['Icelance2'] = {
            -- Lance 2 Timer 11 Ice Nuke Fast Cast
            "Glacier Spear",   -- Level 69 - Timer 11
            "Trushar's Frost", -- Level 65 - Timer 11
            "Ice Shard",       -- Level 54 - Timer 11
            "Ice Spear",       -- Level 33 - Timer 11
        },
        ['EndemicDot'] = {
            -- Disease DoT
            "Fever Spike",      -- Level 71
            "Festering Malady", -- Level 70
            "Plague",           -- Level 65
            "Malaria",          -- Level 40
            "Sicken",           -- Level 14
        },
        ['BloodDot'] = {
            -- Poison DoT Instant Cast
            "Diregriffon's Bite", -- Level 70
            "Chimera Blood",      -- Level 66
            "Turepta Blood",      -- Level 65
            "Scorpion Venom",     -- Level 61
            "Venom of the Snake", -- Level 52
            "Envenomed Breath",   -- Level 35
            "Tainted Breath",     -- Level 19
        },
        ['SlowSpell'] = {
            -- Slow Spell
            "Sha's Legacy",    -- Level 70
            "Sha's Revenge",   -- Level 65
            "Sha's Advantage", -- Level 60
            "Sha's Lethargy",  -- Level 50
            "Drowsy",          -- Level 20
        },
        ['HealSpell'] = {
            "Minohten Mending",  -- Level 71
            "Muada's Mending",   -- Level 67
            "Trushar's Mending", -- Level 65
            "Chloroblast",       -- Level 62
            "Greater Healing",   -- Level 57
            "Spirit Salve",      -- Level 48
            "Healing",           -- Level 36
            "Light Healing",     -- Level 20
            "Minor Healing",     -- Level 6
            "Salve",             -- Level 1
        },
        ['PetHealSpell'] = {
            "Healing of Uluanes",      -- Level 70
            "Healing of Mikkily",      -- Level 66
            "Healing of Sorsha",       -- Level 61
            "Sha's Restoration",       -- Level 55
            "Aid of Khurenz",          -- Level 52
            "Vigor of Zehkes",         -- Level 49
            "Yekan's Recovery",        -- Level 36
            "Herikol's Soothing",      -- Level 27
            "Keshuval's Rejuvenation", -- Level 15
            "Sharik's Replenishing",   -- Level 9
        },
        ['PetSpell'] = {
            "Spirit of Rashara",   -- Level 68
            "Spirit of Alladnu",   -- Level 66
            "Spirit of Sorsha",    -- Level 64
            "Spirit of Arag",      -- Level 62
            "Spirit of Khati Sha", -- Level 60
            "Spirit of Khurenz",   -- Level 58
            "Spirit of Zehkes",    -- Level 56
            "Spirit of Omakin",    -- Level 54
            "Spirit of Kashek",    -- Level 46
            "Spirit of Yekan",     -- Level 39
            "Spirit of Herikol",   -- Level 30
            "Spirit of Keshuval",  -- Level 21
            "Spirit of Khaliz",    -- Level 15
            "Spirit of Sharik",    -- Level 8
        },
        ['PetHaste'] = {
            "Unparalleled Voracity", -- Level 71
            "Growl of the Beast",    -- Level 68
            --"Arag's Celerity",       -- Level 63 -- Grunt has melee mod
            "Grunt of the Beast",    -- Level 62 EQM Custom
            "Sha's Ferocity",        -- Level 59
            "Omakin's Alacrity",     -- Level 55
            "Bond of the Wild",      -- Level 52
            "Yekan's Quickening",    -- Level 37
        },
        ['PetGrowl'] = {
            "Growl of the Panther", -- Level 69
            "Growl of the Leopard", -- Level 61
        },
        ['PetDamageProc'] = {
            "Spirit of Oroshar",      -- Level 70
            "Spirit of Irionu",       -- Level 68
            "Spirit of Rellic",       -- Level 63
            "Spirit of Flame",        -- Level 56
            "Spirit of Snow",         -- Level 54
            "Spirit of the Storm",    -- Level 53
            "Spirit of Wind",         -- Level 51
            "Spirit of Vermin",       -- Level 46
            "Spirit of the Scorpion", -- Level 38
            "Spirit of Inferno",      -- Level 28
            "Spirit of the Blizzard", -- Level 18
            "Spirit of Lightning",    -- Level 13
        },
        ['RunSpeedBuff'] = {
            "Spirit of Wolf", -- Level 24
        },
        ['ManaRegenBuff'] = {
            --Mana/Hp/End Regen Buff*
            "Spiritual Ascendance", -- Level 69
            "Spiritual Dominion",   -- Level 64
            "Spiritual Purity",     -- Level 59
            "Spiritual Radiance",   -- Level 52
            "Spiritual Light",      -- Level 41
        },
        ['PetBlockSpell'] = {
            "Mammoth-Hide Guard",    -- Level 70
            "Feral Guard",           -- Level 69
            "Protection of Calliav", -- Level 64
            "Guard of Calliav",      -- Level 58
            "Ward of Calliav",       -- Level 49
        },
        ['AvatarSpell'] = {
            -- Str Stam Dex Buff
            "Infusion of Spirit", -- Level 61
        },
        ['FocusSpell'] = {
            -- Single target Talismans ( Like Focus)
            "Focus of Amilan",    -- Level 70 Group
            "Focus of Alladnu",   -- Level 67
            "Talisman of Kragg",  -- Level 62
            "Talisman of Altuna", -- Level 58
            "Talisman of Tnarg",  -- Level 53
            "Inner Fire",         -- Level 7
        },
        ['AtkHPBuff'] = {
            "Spiritual Vim",      -- Level 71
            "Spiritual Vitality", -- Level 67
            "Spiritual Vigor",    -- Level 62
            "Spiritual Strength", -- Level 60
            "Spiritual Brawn",    -- Level 42
        },
        ['AtkBuff'] = {
            -- - Single Ferocity
            "Ferocity of Irionu", -- Level 69
            "Ferocity",           -- Level 65
            "Savagery",           -- Level 60
        },
        ['DmgModDisc'] = {
            --All Skills Damage Modifier*
            "Empathic Fury",           -- Level 69
            "Bestial Fury Discipline", -- Level 60
        },
        ['BestialRageDisc'] = {        -- Warden alt: crit instead of damage mod (Ward of Might has dmg mod)
            "Bestial Rage Discipline", -- Level 60 EQM Custom
        },
        ['ProtDisc'] = {
            "Skal's Stance Discipline",     -- Level 61 EQM Custom
            "Protective Spirit Discipline", -- Level 55
        },
        -- ['VigorBuff'] = {
        --     "Feral Vigor",
        -- },
        ['Minionskin'] = {        --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",   -- Level 66 EQM Custom
            "Greater Minionskin", -- Level 56 EQM Custom
            "Minionskin",         -- Level 43 EQM Custom
            "Lesser Minionskin",  -- Level 30 EQM Custom
        },
        ['Rake'] = {
            "Rake", -- Level 67
        },
        ['BiteNuke'] = {
            "Bite of the Empress", -- Level 71
        },
        ['HasteBuff'] = {
            -- Haste Buff
            "Celerity", -- Level 63
            "Alacrity", -- Level 60
        },
    },
    ['AASets']            = {
        ['Spire'] = {
            "Fundament: First Spire of the Savage Lord",
        },
    },
    ['HealRotationOrder'] = {
        { -- configured as a backup healer, will not cast in the mainpoint
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Config:GetSetting('DoHealSpell') end,
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
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and Casting.AmIBuffable()
            end,
        },
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
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
        {
            name = 'PetHealing',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, target) return (mq.TLO.Me.Pet.PctHPs() or 100) < Config:GetSetting('PetHealPct') end,
        },
        {
            name = 'FocusedParagon',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoParagon') and Casting.CanUseAA("Focused Paragon of Spirits") end,
            targetId = function(self) return { Combat.FindWorstHurtMana(Config:GetSetting('FParaPct')), } end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Config:GetSetting('DowntimeFP') and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and not Casting.IHaveBuff(mq.TLO.Me.AltAbility('Paragon of Spirit').Spell) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Slow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSlow') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
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
            name = 'Growl',
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            load_cond = function() return Core.GetResolvedActionMapItem("PetGrowl") end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Song("Growl")() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
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
        DmgModActive = function(self) --Song active by name will check both Bestial Alignments (Self and Group)
            local disc = self.ResolvedActionMap['DmgModDisc']
            return Casting.IHaveBuff("Bestial Alignment") or (disc and disc() and Casting.IHaveBuff(disc.Name()))
                or Casting.IHaveBuff("Ferociousness")
        end,
        -- Irionu artifact is only Rk. 1
        PreferAtkBuffSpell = function(self)
            if mq.TLO.Me.Level() < 67 or not mq.TLO.FindItem("=Artifact of Irionu")() then return true end
            local atkBuff = self.ResolvedActionMap['AtkBuff']
            return atkBuff and atkBuff() and atkBuff.Name() == "Ferocity of Irionu" and (atkBuff.RankName.Rank() or 0) >= 2
        end,
    },
    ['Rotations']         = {
        ['Burn']           = {
            {
                name = "Bestial Bloodrage",
                type = "AA",
            },
            {
                name = "BestialRageDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Core.IsWarden()
                end,
            },
            {
                name = "Group Bestial Alignment",
                type = "AA",
                cond = function(self, aaName)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Attack of the Warders",
                type = "AA",
            },
            {
                name = "Frenzy of Spirit",
                type = "AA",
            },
            {
                name = "Spire",
                type = "AA",
            },
            {
                name = "DmgModDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Core.IsWarden() and not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Bestial Alignment",
                type = "AA",
                cond = function(self, aaName)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "Bloodlust",
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName)
                    return not self.Helpers.DmgModActive(self)
                end,
            },
            {
                name = "SwarmPet",
                type = "Spell",
            },
        },
        ['Slow']           = {
            {
                name = "Legendary Armband of Muada",
                type = "Item",
                load_cond = function(self)
                    return mq.TLO.Me.Level() >= 68 and (Core.GetResolvedActionMapItem('SlowSpell').Level() or 99) < 70 and mq.TLO.FindItem("=Legendary Armband of Muada")()
                end,
                cond = function(self, itemName, target)
                    return Casting.DetItemCheck(itemName) and not Casting.SlowImmuneTarget(target)
                end,

            },
            {
                name = "SlowSpell",
                type = "Spell",
                load_cond = function(self)
                    return mq.TLO.Me.Level() < 68 or (Core.GetResolvedActionMapItem('SlowSpell').Level() or 99) >= 70 or not mq.TLO.FindItem("=Legendary Armband of Muada")()
                end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (spell.RankName.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['Emergency']      = {
            {
                name = "Warder's Gift",
                type = "AA",
                cond = function(self, aaName)
                    return (mq.TLO.Me.Pet.PctHPs() or 0) > 50
                end,
            },
            {
                name = "Protection of the Warder",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "ProtDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
        },
        ['PetHealing']     = {
            {
                name = "Companion's Blessing",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name_func = function() return Casting.CanUseAA("Replenish Companion") and "Replenish Companion" or "Mend Companion" end,
                type = "AA",
            },
            {
                name = "PetHealSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPetHealSpell') end,
            },
        },
        ['FocusedParagon'] = {
            {
                name = "Focused Paragon of Spirits",
                type = "AA",
            },
        },
        ['Growl']          = {
            {
                name = "PetGrowl",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
        },
        ['DPS']            = {
            {
                name = "PetSpell",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('KeepPetMemmed') and (not Config:GetSetting('UseDonorPet') or not Core.GetResolvedActionMapItem('Razorclaw'))
                end,
                cond = function(self, spell)
                    return mq.TLO.Me.Pet.ID() == 0
                end,
            },
            {
                name = "Razorclaw",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and Core.GetResolvedActionMapItem('Razorclaw') end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "Paragon of Spirit",
                type = "AA",
                cond = function(self, aaName)
                    if not Config:GetSetting('DoParagon') then return false end
                    return Casting.GroupLowManaCount(Config:GetSetting('ParaPct')) > 0
                end,
                pre_activate = function(self)
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
                end,
            },
            {
                name = "BloodDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "EndemicDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Icelance1",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Icelance2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['Weaves']         = {
            {
                name = "Roar of Thunder",
                type = "AA",
            },
            {
                name = "Raven's Claw",
                type = "AA",
            },
            {
                name = "Gorilla Smash",
                type = "AA",
            },
            {
                name = "Feral Swipe",
                type = "AA",
            },
            {
                name = "Rake",
                type = "Disc",
            },
            {
                name = "Kick",
                type = "Ability",
            },
            {
                name = "Tiger Claw",
                type = "Ability",
            },
            {
                name = "Bite of the Asp",
                type = "AA",
            },
            {
                name = "Chameleon Strike",
                type = "AA",
            },
        },
        ['GroupBuff']      = {
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Irionu",
                type = "Item",
                load_cond = function(self) return not self.Helpers.PreferAtkBuffSpell(self) end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "AtkBuff",
                type = "Spell",
                load_cond = function(self) return self.Helpers.PreferAtkBuffSpell(self) end,
                cond = function(self, spell, target)
                    -- Make sure this is gemmed due to long refresh, and only use the single target versions on classes that need it.
                    if not Targeting.TargetIsAMelee(target) or not Casting.CastReady(spell) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ManaRegenBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "AtkHPBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    -- Only use the single target versions on classes that need it
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                        --laz specific deconflict with brell's vibrant barricade
                        and Casting.AddedBuffCheck(40583, target)
                end,
            },
            {
                name = "FocusSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    -- Only use the single target versions on classes that need it
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "AvatarSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAvatar') or not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHaste') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['PetSummon']      = {
            {
                name = "Razorclaw",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and Core.GetResolvedActionMapItem('Razorclaw') end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "PetSpell",
                type = "Spell",
                load_cond = function(self) return not Config:GetSetting("UseDonorPet") or not Core.GetResolvedActionMapItem('Razorclaw') end,
                cond = function(self, spell)
                    return mq.TLO.Me.Pet.ID() == 0
                end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['Downtime']       = {
            {
                name = "Gelid Rending",
                type = "AA",
            },
            {
                name = "Pact of The Wurine",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName) and not mq.TLO.Me.Buff("Group Pact of the Wolf")()
                end,
            },
        },
        ['PetBuff']        = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if not Config:GetSetting('DoEpic') then return false end
                    return not mq.TLO.Me.PetBuff("Savage Wildcaller's Blessing")() and not mq.TLO.Me.PetBuff("Might of the Wild Spirits")()
                end,
            },
            {
                name = "Hobble of Spirits",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoPetSnare') end,
                cond = function(self, aaName, target)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "AvatarSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAvatar') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetHaste",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell, nil, true)
                end,
            },
            {
                name = "PetDamageProc",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetGrowl",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Fortify Companion",
                type = "AA",
                active_cond = function(self, aaName) return mq.TLO.Me.PetBuff(aaName)() ~= nil end,
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Taste of Blood",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Minionskin",
                type = "Spell",
                cond = function(self, spell)
                    return not mq.TLO.Me.Pet.Buff(spell.Name() or "None")()
                end,
            },
        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "HealSpell",    cond = function(self) return Config:GetSetting('DoHealSpell') end, },
                { name = "PetHealSpell", cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                {
                    name = "SlowSpell",
                    cond = function(self)
                        return Config:GetSetting('DoSlow') and
                            -- use this unless we don't have the armband, can't use the armband, or have a spell that casts faster than the armband
                            (mq.TLO.Me.Level() < 68 or (Core.GetResolvedActionMapItem('SlowSpell').Level() or 99) >= 70 or not mq.TLO.FindItem("=Legendary Armband of Muada")())
                    end,
                },
                { name = "Icelance1", },
                { name = "Icelance2", },
                { name = "BloodDot",   cond = function(self) return Config:GetSetting('DoDot') end, },
                { name = "EndemicDot", cond = function(self) return Config:GetSetting('DoDot') end, },
                { name = "SwarmPet", },
                { name = "AtkBuff", cond = function(self) return self.Helpers.PreferAtkBuffSpell(self) end,
                },
                { name = "PetGrowl", },
                { name = "PetBlockSpell", },
                {
                    name = "PetSpell",
                    cond = function(self)
                        return Config:GetSetting('KeepPetMemmed') and
                            (not Config:GetSetting('UseDonorPet') or not Core.GetResolvedActionMapItem('Razorclaw'))
                    end,
                },
                --filler
                { name = "PetHaste", },
                { name = "PetDamageProc", },
                { name = "RunSpeedBuff",  cond = function(self) return Config:GetSetting('DoRunSpeed') end, },
            },
        },
    },
    ['PullAbilities']     = {
        {
            id = 'SlowSpell',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('SlowSpell')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('SlowSpell')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('SlowSpell')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']     = {
        ['Mode']           = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Beastlords currently only have one Mode. This may change in the future.",
        },
        --Mana Management
        ['DoParagon']      = {
            DisplayName = "Use Paragon",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Use Group or Focused Paragon AAs.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['ParaPct']        = {
            DisplayName = "Paragon %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "Minimum mana % before we use Paragon of Spirit.",
            Default = 50,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
        },
        ['FParaPct']       = {
            DisplayName = "F.Paragon %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            Tooltip = "Minimum mana % before we use Focused Paragon.",
            Default = 90,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
        },
        ['DowntimeFP']     = {
            DisplayName = "Downtime F.Paragon",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip = "Use Focused Paragon outside of Combat.",
            Default = false,
            ConfigType = "Advanced",
        },
        --Pets
        ['DoPetHealSpell'] = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Mem and cast your Pet Heal (Salve) spell. AA Pet Heals are always used in emergencies.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['PetHealPct']     = {
            DisplayName = "Pet Heal Spell HP%",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Tooltip = "Use your pet heal spell when your pet is at or below this HP percentage.",
            Default = 60,
            Min = 1,
            Max = 99,
        },
        ['DoPetSlow']      = {
            DisplayName = "Pet Slow Proc",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Buffs",
            Index = 101,
            Tooltip = "Use your Pet Slow Proc Buff (does not stack with Pet Damage or Snare Proc Buff).",
            Default = false,
        },
        ['DoPetSnare']     = {
            DisplayName = "Pet Snare Proc",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Buffs",
            Index = 102,
            Tooltip = "Use your Pet Snare Proc Buff (does not stack with Pet Damage or Slow Proc Buff).",
            Default = false,
            FAQ = "Why am I continually using proc buffs on my pet?",
            Answer = "Pet proc buffs do not stack, you should only select one.\n" ..
                "If neither Snare nor Slow proc are selected, the Damage proc will be used.",
        },
        ['DoEpic']         = {
            DisplayName = "Do Epic",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your Epic Weapon.",
            Default = false,
        },
        ['KeepPetMemmed']  = {
            DisplayName = "Always Mem Pet",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 101,
            Tooltip = "Keep your pet spell memorized (allows combat resummoning).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['UseDonorPet']    = {
            DisplayName = "Summon Razorclaw",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 102,
            Tooltip = "Use your Artifact of Razorclaw to summon the donor raptor warder.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        --Spells/Abilities
        ['DoHealSpell']    = {
            DisplayName = "Do PC Heals",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Mending spell.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoSlow']         = {
            DisplayName = "Do Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = "Use your slow spell or AA.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoDot']          = {
            DisplayName = "Cast DOTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Enable casting Damage Over Time spells.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DotNamedOnly']   = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Only use DoTs on a named mob.",
            Default = true,
        },
        ['DoRunSpeed']     = {
            DisplayName = "Do Run Speed",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Use your Run/Move Speed buff spells or AA.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoAvatar']       = {
            DisplayName = "Do Avatar",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Buff Group/Pet with Infusion of Spirit",
            Default = false,
        },
        ['DoHaste']        = {
            DisplayName = "Use Haste",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Do Haste Spells",
            RequiresLoadoutChange = true,
            Default = false,
        },
        --Combat

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
            Answer = "This class config is currently a Work-In-Progress that was originally based off of the Project Lazarus config.\n\n" ..
                "  Up until level 71, it should work quite well, but may need some clickies managed on the clickies tab.\n\n" ..
                "  After level 68, however, there hasn't been any playtesting... some AA may need to be added or removed still, and some Laz-specific entries may remain.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}
