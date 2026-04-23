local mq        = require('mq')
local Combat    = require('utils.combat')
local Config    = require('utils.config')
local Globals   = require('utils.globals')
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Logger    = require("utils.logger")

return {
    _version              = "1.6 - EQ Might",
    _author               = "Derple, Algar",
    ['Modes']             = {
        'DPS',
    },
    ['ModeChecks']        = {
        IsHealing = function() return Config:GetSetting('DoHeals') end,
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
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
    },
    ['AbilitySets']       = { --TODO/Under Consideration: Add AoE Roar line, add rotation entry (tie it to Do AoE setting), swap in instead of lance 2, especially since the last lance2 is level 112
        ['SwarmPet'] = {
            -- Swarm Pet
            "Bestial Empathy",
        },
        ['Icelance1'] = {
            -- Lance 1 Timer 7 Ice Nuke Fast Cast
            "Blast of Frost",        -- Level 12 - Timer 7
            "Frost Shard",           -- Level 47 - Timer 7
            "Blizzard Blast",        -- Level 59 - Timer ???
            "Frost Spear",           -- Level 63 - Timer 7
            "Ancient: Frozen Chaos", -- Level 65 - Timer 7
            "Ancient: Savage Ice",   -- Level 70 - Timer 7
        },
        ['Icelance2'] = {
            -- Lance 2 Timer 11 Ice Nuke Fast Cast
            "Ice Spear",       -- Level 33 - Timer 11
            "Ice Shard",       -- Level 54 - Timer 11
            "Trushar's Frost", -- Level 65 - Timer 11
            "Glacier Spear",   -- Level 69 - Timer 11
        },
        ['EndemicDot'] = {
            -- Disease DoT
            "Sicken",           -- Level 14
            "Malaria",          -- Level 40
            "Plague",           -- Level 65
            "Festering Malady", -- Level 70
            "Fever Spike",      -- Level 71
        },
        ['BloodDot'] = {
            -- Poison DoT Instant Cast
            "Tainted Breath",     -- Level 19
            "Envenomed Breath",   -- Level 35
            "Venom of the Snake", -- Level 52
            "Scorpion Venom",     -- Level 61
            "Turepta Blood",      -- Level 65
            "Chimera Blood",      -- Level 66
            "Diregriffon's Bite", -- 70 EQM
        },
        ['SlowSpell'] = {
            -- Slow Spell
            "Drowsy",          -- Level 20
            "Sha's Lethargy",  -- Level 50
            "Sha's Advantage", -- Level 60
            "Sha's Revenge",   -- Level 65
            "Sha's Legacy",    -- Level 70
        },
        ['HealSpell'] = {
            "Salve",             -- Level 1
            "Minor Healing",     -- Level 6
            "Light Healing",     -- Level 18
            "Healing",           -- Level 28
            "Greater Healing",   -- Level 38
            "Spirit Salve",      -- Level 48
            "Chloroblast",       -- Level 59
            "Trushar's Mending", -- Level 65
            "Muada's Mending",   -- Level 67
            "Minohten Mending",  -- Level 71
        },
        ['PetHealSpell'] = {
            "Sharik's Replenishing",   -- Level 9
            "Keshuval's Rejuvenation", -- Level 15
            "Herikol's Soothing",      -- Level 27
            "Yekan's Recovery",        -- Level 36
            "Vigor of Zehkes",         -- Level 49
            "Aid of Khurenz",          -- Level 52
            "Sha's Restoration",       -- Level 55
            "Healing of Sorsha",       -- Level 61
            "Healing of Mikkily",      -- Level 66
            "Healing of Uluanes",      -- 70 EQM Custom
        },
        ['PetSpell'] = {
            "Spirit of Sharik",    -- Level 8
            "Spirit of Khaliz",    -- Level 15
            "Spirit of Keshuval",  -- Level 21
            "Spirit of Herikol",   -- Level 30
            "Spirit of Yekan",     -- Level 39
            "Spirit of Kashek",    -- Level 46
            "Spirit of Omakin",    -- Level 54
            "Spirit of Zehkes",    -- Level 56
            "Spirit of Khurenz",   -- Level 58
            "Spirit of Khati Sha", -- Level 60
            "Spirit of Arag",      -- Level 62
            "Spirit of Sorsha",    -- Level 64
            "Spirit of Alladnu",   -- Level 68
            "Spirit of Rashara",   -- Level 70
        },
        ['PetHaste'] = {
            "Unparalleled Voracity",
            "Yekan's Quickening",
            "Bond of The Wild",
            "Omakin's Alacrity",
            "Sha's Ferocity",
            "Arag's Celerity",
            "Growl of the Beast",
        },
        ['PetSlowProc'] = {
            "Spirit of Sha",
        },
        ['PetGrowl'] = {
            "Growl of the Panther",
        },
        ['PetDamageProc'] = {
            "Spirit of Shoru",
            "Spirit of Lightning",
            "Spirit of the Blizzard",
            "Spirit of Inferno",
            "Spirit of the Scorpion",
            "Spirit of Vermin",
            "Spirit of Wind",
            "Spirit of the Storm",
            "Spirit of Snow",
            "Spirit of Flame",
            "Spirit of Rellic",
            "Spirit of Irionu",
            "Spirit of Oroshar",
        },
        ['RunSpeedBuff'] = {
            "Spirit of Wolf",
        },
        ['ManaRegenBuff'] = {
            --Mana/Hp/End Regen Buff*
            "Spiritual Light",
            "Spiritual Radiance",
            "Spiritual Purity",
            "Spiritual Dominion",
            "Spiritual Ascendance",
        },
        ['PetBlockSpell'] = {
            "Ward of Calliav",       -- Level 49
            "Guard of Calliav",      -- Level 58
            "Protection of Calliav", -- Level 64
            "Feral Guard",           -- Level 69
            "Mammoth-Hide Guard",    -- Level 70 EQM
        },
        ['AvatarSpell'] = {
            -- Str Stam Dex Buff
            "Infusion of Spirit", -- Level 61
        },
        ['FocusSpell'] = {
            -- Single target Talismans ( Like Focus)
            "Inner Fire",
            "Talisman of Tnarg",
            "Talisman of Altuna",
            "Talisman of Kragg",
            "Focus of Alladnu",
            "Focus of Amilan", -- EQM Group
        },
        ['AtkHPBuff'] = {
            "Spiritual Vim",
            "Spiritual Vitality",
            "Spiritual Vigor",
            "Spiritual Brawn",
            "Spiritual Strength",
        },
        ['AtkBuff'] = {
            -- - Single Ferocity
            "Savagery",           -- Level 60
            "Ferocity",           -- Level 65
            "Ferocity of Irionu", -- Level 70
        },
        ['DmgModDisc'] = {
            --All Skills Damage Modifier*
            "Empathic Fury",
            "Bestial Fury Discipline",
        },
        ['ProtDisc'] = {
            "Protective Spirit Discipline",
            "Skal's Stance Discipline",
        },
        -- ['VigorBuff'] = {
        --     "Feral Vigor",
        -- },
        ['Minionskin'] = { --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",
            "Greater Minionskin",
            "Minionskin",
            "Lesser Minionskin",
        },
        ['Rake'] = {
            "Rake",
        },
        ['BiteNuke'] = {
            "Bite of the Empress",
        },
        ["HasteBuff"] = {
            -- Haste Buff - 26 - 64
            "Celerity",
            "Alacrity",
        },
    },
    ['HealRotationOrder'] = {
        { -- configured as a backup healer, will not cast in the mainpoint
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
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
        { --Summon pet even when buffs are off on emu
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
                return (downtime or combat) and not Casting.IHaveBuff(mq.TLO.Me.AltAbility('Paragon of Spirit').Spell)
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
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'Growl',
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Song("Growl")()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay()
            end,
        },
    },
    ['Helpers']           = {
        DoRez = function(self, corpseId)
            local rezStaff = self.ResolvedActionMap['RezStaff']

            if mq.TLO.Me.ItemReady(rezStaff)() then
                if Casting.OkayToRez(corpseId) then
                    return Casting.UseItem(rezStaff, corpseId)
                end
            end

            return false
        end,
        DmgModActive = function(self) --Song active by name will check both Bestial Alignments (Self and Group)
            local disc = self.ResolvedActionMap['DmgModDisc']
            return Casting.IHaveBuff("Bestial Alignment") or (disc and disc() and Casting.IHaveBuff(disc.Name()))
                or Casting.IHaveBuff("Ferociousness")
        end,
        --function to make sure we don't have non-hostiles in range before we use AE damage or non-taunt AE hate abilities

    },
    ['Rotations']         = {
        ['Burn']           = {
            {
                name = "Bestial Bloodrage",
                type = "AA",
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
                name = "Fundament: Third Spire of the Savage Lord",
                type = "AA",
            },
            {
                name = "DmgModDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not self.Helpers.DmgModActive(self)
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
                    return (mq.TLO.Me.Pet.PctHPs() and mq.TLO.Me.Pet.PctHPs() > 50)
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
                type = "Discipline",
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
        {
            {
                name = "PetGrowl",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
        },
        ['DPS']       = {
            {
                name = "PetSpell",
                type = "Spell",
                cond = function(self, spell)
                    return mq.TLO.Me.Pet.ID() == 0
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
                name = "PoiBite",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
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
            {
                name = "Nature's Salve",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.TotalCounters() > 0
                end,
            },
            {
                name = "Artifact of Razorclaw",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Razorclaw")() end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['Weaves']    = {
            {
                name = "Summon Companion",
                type = "AA",
                cond = function(self, aaName, target)
                    if mq.TLO.Me.Pet.ID() == 0 then return false end
                    local pet = mq.TLO.Me.Pet
                    return not pet.Combat() and (pet.Distance3D() or 0) > 200
                end,
            },
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
        ['GroupBuff'] = {
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
                load_cond = function() return mq.TLO.Me.Level() >= 67 and mq.TLO.FindItem("=Artifact of Irionu")() end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "AtkBuff",
                type = "Spell",
                load_cond = function() return mq.TLO.Me.Level() < 67 or not mq.TLO.FindItem("=Artifact of Irionu")() end,
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
        ['PetSummon'] = {
            {
                name = "Artifact of Razorclaw",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Razorclaw")() end,
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
                load_cond = function(self) return not Config:GetSetting("UseDonorPet") or not mq.TLO.FindItem("=Artifact of Razorclaw")() end,
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
        ['Downtime']  = {
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
        ['PetBuff']   = {
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
                cond = function(self, aaName, target)
                    local slowProc = self.ResolvedActionMap['PetSlowProc']
                    return Config:GetSetting('DoPetSnare') and (slowProc and slowProc() and mq.TLO.Me.PetBuff(slowProc.RankName()) == nil) and
                        mq.TLO.Me.PetBuff(mq.TLO.Me.AltAbility(aaName).Spell.RankName.Name())() == nil
                end,
            },
            {
                name = "AvatarSpell",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoAvatar') and Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoRunSpeed') and Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetSlowProc",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoPetSlow') and Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetHaste",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
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
        },
        {
            name = "Minionskin",
            type = "Spell",
            cond = function(self, spell)
                return not mq.TLO.Me.Pet.Buff(spell.Name() or "None")()
            end,
        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "HealSpell",    cond = function(self) return Config:GetSetting('DoHeals') end, },
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
                { name = "AtkBuff", cond = function(self) return mq.TLO.Me.Level() < 67 or not mq.TLO.FindItem("=Artifact of Irionu")() end,
                },
                { name = "PetGrowl", },
                { name = "PetBlockSpell", },
                { name = "PetSpell",      cond = function(self) return Config:GetSetting('KeepPetMemmed') and not mq.TLO.FindItem("=Artifact of Razorclaw")() end, },
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
        ['DoHeals']        = {
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
