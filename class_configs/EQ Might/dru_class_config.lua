local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")
local Combat       = require("utils.combat")

local _ClassConfig = {
    _version              = "2.1 - EQ Might",
    _author               = "Algar",
    ['ModeChecks']        = {
        IsHealing  = function() return true end,
        IsCuring   = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing   = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
        CanCharm   = function() return true end,
        IsCharming = function() return Config:GetSetting('CharmOn') end,
    },
    ['Modes']             = {
        'Heal',
    },
    ['Cures']             = {
        GetCureSpells = function(self)
            --(re)initialize the table for loadout changes
            self.TempSettings.CureSpells = {}

            local neededCures = {
                ['Poison'] = "CurePoison",
                ['Disease'] = "CureDisease",
                ['Curse'] = "CureCurse",
                ['Corruption'] = "CureCorrupt",
            }

            -- iterate to actually resolve the selected map item, if it is valid, add it to the cure table
            for k, v in pairs(neededCures) do
                local cureSpell = Core.GetResolvedActionMapItem(v)
                if cureSpell then
                    self.TempSettings.CureSpells[k] = cureSpell
                end
            end
        end,
        CureNow = function(self, type, targetId)
            local targetSpawn = mq.TLO.Spawn(targetId)
            if not targetSpawn and targetSpawn then return false, false end

            if Config:GetSetting('DoCureAA') then
                local cureAA = Casting.AAReady("Radiant Cure") and "Radiant Cure"

                -- I am finding self-cures to be less than helpful when most effects on a healer are group-wide
                -- if not cureAA and targetId == mq.TLO.Me.ID() and Casting.AAReady("Purified Spirits") then
                --     cureAA = "Purified Spirits"
                -- end

                if cureAA then
                    Logger.log_debug("CureNow: Using %s for %s on %s.", cureAA, type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
                    return Casting.UseAA(cureAA, targetId), true
                end
            end

            if Config:GetSetting('DoCureSpells') then
                for effectType, cureSpell in pairs(self.TempSettings.CureSpells) do
                    if type:lower() == effectType:lower() then
                        if cureSpell.TargetType():lower() == "group v1" and not Targeting.GroupedWithTarget(targetSpawn) then
                            Logger.log_debug("CureNow: We cannot use %s on %s, because it is a group-only spell and they are not in our group!", cureSpell.RankName(),
                                targetSpawn.CleanName() or "Unknown")
                        else
                            Logger.log_debug("CureNow: Using %s for %s on %s.", cureSpell.RankName(), type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
                            return Casting.UseSpell(cureSpell.RankName(), targetId, true), true
                        end
                    end
                end
            end

            Logger.log_debug("CureNow: No valid cure at this time for %s on %s.", type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
            return false, false
        end,
    },
    ['ItemSets']          = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Staff of Living Brambles",
            "Staff of Everliving Brambles",
        },
        ['BlueBand'] = {
            "Legendary Ancient Frozen Blue Band",
            "Ancient Frozen Blue Band",
            "Fabled Blue Band of the Oak",
            "Blue Band of the Oak",
        },
        ['VampiricBlueBand'] = {
            "Mythical Ancient Vampiric Blue Band",
            "Legendary Ancient Vampiric Blue Band",
            "Ancient Vampiric Blue Band",
        },
        ['Timer2HealItem'] = {
            "Legendary Kelp-Covered Hammer",
            "Legendary Aged Dragon Spine Staff",
            "Kelp-Covered Hammer",
            "Aged Dragon Spine Staff",
        },
        ['OoW_Chest'] = {
            "Everspring Jerkin of Tangled Briars",
            "Greenvale Jerkin",
        },
    },
    ['AbilitySets']       = {
        ['HealingAura'] = {
            -- Healing Aura >= 55
            "Aura of Life",
            "Aura of the Grove",
        },
        ['HealSpell'] = {
            -- Long Heal >= 1 -- skipped 10s cast heals.
            "Ancient: Chlorobon",
            "Chlorotrope",
            "Sylvan Infusion",
            "Nature's Infusion",
            "Nature's Touch",
            "Chloroblast",
            "Forest's Renewal",
            "Superior Healing",
            "Nature's Renewal",
            "Healing Water",
            "Greater Healing",
            "Healing",
            "Light Healing",
            "Minor Healing",
        },
        ['GroupHeal'] = {
            "Moonshadow",
            "Lunarglow",
            "Lunargleam",
        },
        ['ATKDebuff'] = { -- ATK Debuff
            "Sun's Corona",
            "Ro's Illumination",
        },
        ['ATKACDebuff'] = { -- ATK/AC Debuff, replaced by AA (Fixation > Blessing of Ro)
            "Fixation of Ro",
        },
        ['FireDebuff'] = { -- Fire and some other stats, replaced by AA (Hand > Blessing of Ro)
            "Hand of Ro",
            "Ro's Smoldering Disjunction",
            "Ro's Fiery Sundering",
        },
        ['ColdDebuff'] = { -- Cold/AC Debuff
            "Icefall Breath",
            "Glacier Breath",
            "E`ci's Frosty Breath",
            "Twilight Breath",
        },
        ['ReptileBuff'] = {
            "Skin of the Green Dragon", -- EQM Custom
            "Skin of the Reptile",
            "Skin of the Serpent",      -- EQM Custom
        },
        ['SwarmDot'] = {                -- Magic Dot, 54s
            "Swarm of Fireants",
            "Wasp Swarm",
            "Swarming Death",
            "Winged Death",
            "Drifting Death",
            "Drones of Doom",
            "Creeping Crud",
            "Stinging Swarm",
        },
        ['VengeanceDot'] = { -- Fire Dot, 30s
            "Vengeance of the Sun",
            "Vengeance of Tunare",
            "Vengeance of Nature",
            "Vengeance of the Wild",
        },
        ['FlameLickDot'] = { -- Fire Dot with Fire Resist Reduction, 60s
            "Immolation of the Sun",
            "Sylvan Embers",
            "Immolation of Ro",
            "Breath of Ro",
            "Immolate",
            "Flame Lick",
        },
        ['StunNuke'] = {
            "Gale of the Stormborn",
            "Stormwatch",
            "Storm's Fury",
            -- "Breath of Karana", -- Only cast outdoors
            -- "Dustdevil", --Does not Stun
            "Fury of Air",
            -- "Dizzying Wind", -- Only cast outdoors
            -- "Whirling Wind", -- Only cast outdoors
        },
        ['SnareSpell'] = {
            -- "Hungry Vines", -- The out-of-era Serpent Vines is much less mana and lasts longer without the Dot And melee guard
            "Serpent Vines",
            "Entangle",
            "Mire Thorns",
            "Bonds of Tunare",
            "Ensnare",
            "Snare",
            "Tangling Weeds",
        },
        ['FireNuke'] = {
            "Winter's Flame", -- start to add cold damage in as well
            "Solstice Strike",
            "Sylvan Fire",
            "Summer's Flame",
            "Ancient: Starfire of Ro",
            "Wildfire",
            "Scoriae",
            "Starfire",
            "Firestrike",
            "Combust",
            "Ignite",
            "Burst of Fire",
            "Burst of Flame",
        },
        ['IceNuke'] = {
            "Ancient: Glacier Frost",
            "Glitterfrost",
            "Ancient: Chaos Frost",
            "Winter's Frost",
            "Moonfire",
            "Frost",
        },
        ['IceRain'] = {
            "Tempest Wind",
            "Winter's Storm",
            "Blizzard",
            "Avalanche",
            "Pogonip",
            "Cascade of Hail",
        },
        ['SelfDS'] = {
            "Viridicoat",
            "Nettlecoat",
            "Brackencoat",
            "Bladecoat",
            "Thorncoat",
            "Spikecoat",
            "Bramblecoat",
            "Barbcoat",
            "Thistlecoat",
        },
        ['SelfManaRegen'] = {
            "Mask of the Wild",
            "Mask of the Forest",
            "Mask of the Stalker",
        },
        ['HPTypeOneGroup'] = {
            "Blessing of Steeloak",
            "Blessing of the Nine",
            "Protection of the Glades",
            "Protection of Nature",
            "Protection of Diamond",
            "Protection of Steel",
            "Protection of Rock",
            "Protection of Wood",
            'Skin like Wood',
        },
        ['GroupRegenBuff'] = {
            "Blessing of Oak",
            "Blessing of Replenishment",
            "Regrowth of the Grove",
            "Pack Chloroplast",
            "Pack Regeneration",
            "Regeneration",
        },
        ['MeleeBuff'] = {      --Hit Damage/STR Buff
            "Mammoth's Strength",
            "Lion's Strength", -- 5% Hit Damage
            "Nature's Might",  -- STR Buff
        },
        ['GroupDmgShield'] = {
            "Legacy of Nettles",
            "Legacy of Bracken",
            "Ancient: Legacy of Blades",
            "Legacy of Thorn",
            "Legacy of Spike",
            -- Before this, use ST filler
            "Shield of Thorns",
            "Shield of Spikes",
            "Shield of Brambles",
            "Shield of Barbs",
            "Shield of Thistles",
        },
        ['MoveSpells'] = {
            "Flight of Eagles",
            "Spirit of Eagle",
            "Pack Spirit",
            "Spirit of Wolf",
        },
        ['PetSpell'] = {
            "Nature Wanderer's Behest",
            "Hierophant's Behest", -- EQM Custom
            "Nature Walker's Behest",
        },
        ['Dawnstrike'] = { -- I think better to just spam solstice strike
            "Dawnstrike",
        },
        -- ['BurstDS'] = { -- Laz specific, short duration 210pt damge shield
        --     "Barkspur",
        -- },
        ['RezSpell'] = {
            'Incarnate Anew', -- Level 59
        },
        ['CurePoison'] = {
            "Eradicate Poison",
            "Counteract Poison",
            "Cure Poison",
        },
        ['CureDisease'] = {
            "Eradicate Disease",
            "Counteract Disease",
            "Cure Disease",
        },
        ['CureCurse'] = {
            "Eradicate Curse",
            "Remove Greater Curse",
            "Remove Curse",
            "Remove Lesser Curse",
            "Remove Minor Curse",
        },
        ['CureCorrupt'] = {
            "Cure Corruption",
        },
        -- ['PureBlood'] = {
        --     "Pure Blood",
        -- },
        ['PBAEMagic'] = {
            "Earth Shiver",
            "Castastrophe",
            "Upheaval",
            "Earthquake",
            "Tremor",
        },
        ['PetHaste'] = {
            "Savage Spirit",
            "Feral Spirit",
        },
        ['GroupResistBuff'] = { -- Fire/Cold Resist
            "Protection of Seasons",
            "Circle of Seasons",
        },
        ['Elixir'] = { --Laz gives these to druids
            "Celestial Elixir",
            "Celestial Healing",
            "Celestial Health",
            "Celestial Remedy",
        },
        ['EvacSpell'] = {
            "Succor",
            "Lesser Succor",
        },
        ['Minionskin'] = { --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",
            "Greater Minionskin",
            "Minionskin",
            "Lesser Minionskin",
        },
        ['ColdSlow'] = {
            "Permafrost Grip",
            "Ancient: Permafrost Veil",
        },
    },
    ['HealRotationOrder'] = {
        {
            name  = 'BigHealPoint',
            state = 1,
            steps = 1,
            cond  = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['BigHealPoint'] = {
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "Timer2HealItem",
                type = "Item",
            },
            {
                name = "Mask of the Ancients",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Mask of the Ancients")() end,
            },
        },
        ['GroupHealPoint'] = {
            {
                name = "VampiricBlueBand",
                type = "Item",
                load_cond = function(self) return Core.GetResolvedActionMapItem("VampiricBlueBand") and mq.TLO.Me.Level() >= 68 end,
            },
            {
                name = "BlueBand",
                type = "Item",
                load_cond = function(self) return Core.GetResolvedActionMapItem("BlueBand") and (mq.TLO.Me.Level() < 68 or not Core.GetResolvedActionMapItem("VampiricBlueBand")) end,
            },
            {
                name = "GroupHeal",
                type = "Spell",
            },
        },
        ['MainHealPoint'] = {
            { -- keep this for big heals, unless we are critically low on mana
                name = "Timer2HealItem",
                type = "Item",
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            { -- keep this for big heals, unless we are critically low on mana
                name = "Mask of the Ancients",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Mask of the Ancients")() end,
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            {
                name = "HealSpell",
                type = "Spell",
            },
        },
    },
    ['RotationOrder']     = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.OkayToNotHeal() and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Summon pet even when buffs are off on emu
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            load_cond = function(self) return Core.OnEMU() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoPet') or mq.TLO.Me.Pet.ID() ~= 0 then return false end
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToPetBuff() and Casting.AmIBuffable()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.OkayToNotHeal() and Casting.OkayToBuff()
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
            name = 'Debuff',
            state = 1,
            steps = 1,
            load_cond = function()
                return (Config:GetSetting('DoFireDebuff') and Core.GetResolvedActionMapItem("FireDebuff")) or
                    (Config:GetSetting('DoColdDebuff') and Core.GetResolvedActionMapItem("ColdDebuff")) or
                    (Config:GetSetting('DoATKDebuff') and Core.GetResolvedActionMapItem("ATKDebuff"))
            end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal() and Casting.OkayToDebuff()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal() and not Globals.AutoTargetIsNamed and
                    Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and Core.OkayToNotHeal()
            end,
        },
        {
            name = 'DPS(AE)',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoPBAE') and self:GetResolvedActionMapItem('PBAEMagic') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoAEDamage') then return false end
                return combat_state == "Combat" and Core.OkayToNotHeal() and Targeting.AggroCheckOkay() and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() < 71 end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
    },
    ['Rotations']         = {
        ['DPS'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "Storm Strike",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "Nature Walkers Scimitar",
                type = "Item",
                cond = function(self, itemName, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Targeting.MobNotLowHP(target) and Casting.DetItemCheck(itemName, target)
                end,
            },
            {
                name = "FlameLickDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFlameLickDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "SwarmDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoSwarmDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "VengeanceDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoVengeanceDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "StunNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoStunNuke') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke() and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFireNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoIceNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Artifact of Nature Spirit",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Nature Spirit") end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['DPS(AE)'] = {
            {
                name = "PBAEMagic",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "IceRain",
                type = "Spell",
                cond = function(self, spell, target)
                    if not self.Helpers.RainCheck(target) then return false end
                    return Casting.HaveManaToNuke(true)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Group Spirit of the Black Wolf",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Nature's Fury",
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Spirit of the Wood",
                type = "AA",
                pre_activate = function(self)
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
                end,
            },
            {
                name = "Nature's Boon",
                type = "AA",
            },
            {
                name = "Nature's Guardian",
                type = "AA",
            },
            {
                name = "Spirits of Nature",
                type = "AA",
            },
            { -- Spire, the SpireChoice setting will determine which ability is displayed/used.
                name_func = function(self)
                    local spireAbil = string.format("Fundament: %s Spire of Nature", Globals.Constants.SpireChoices[Config:GetSetting('SpireChoice') or 4])
                    return Casting.CanUseAA(spireAbil) and spireAbil or "Spire Not Purchased/Selected"
                end,
                type = "AA",
            },
            {
                name = "Shattered Gnoll Slayer",
                type = "Item",
            },
        },
        ['Slow'] = {
            {
                name = "ColdSlow",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (spell.RankName.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['Debuff'] = {
            { -- Fire Debuff AA, will use the first(best) available
                name_func = function(self)
                    return Casting.GetFirstAA({ "Blessing of Ro", "Hand of Ro", })
                end,
                type = "AA",
                load_cond = function() return Config:GetSetting('DoFireDebuff') and Casting.CanUseAA("Hand of Ro") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "FireDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFireDebuff') and not Casting.CanUseAA("Hand of Ro") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "ColdDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoColdDebuff') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "ATKDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoATKDebuff') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "Flight of Eagles",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') and Casting.CanUseAA("Flight of Eagles") end,
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(Casting.GetAASpell(aaName))
                end,
                cond = function(self, aaName, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "MoveSpells",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') and not Casting.CanUseAA("Flight of Eagles") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ReptileBuff",
                type = "Spell",
                active_cond = function(self, spell) return true end,
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs({ "WAR", "SHD", }, target) and Casting.GroupBuffCheck(spell, target) --does not stack with PAL innate buff
                end,
            },
            {
                name = "MeleeBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoMeleeBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HPTypeOneGroup",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHPBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoGroupRegen') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupDmgShield",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoGroupDmgShield') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Wrath of the Wild",
                type = "AA",
                active_cond = function(self, aaName) return true end,
                cond = function(self, aaName, target)
                    if Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') end,
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "HealingAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName()))
                end,
            },
            { -- Wolf Spirit, the WolfSpiritChoice setting will determine which color you use.
                name_func = function(self)
                    local wolves = { 'White', 'Black', }
                    local spiritChoice = wolves[Config:GetSetting('WolfSpiritChoice')]
                    return string.format("Spirit of the %s Wolf", spiritChoice)
                end,
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName) and not Casting.IHaveBuff("Group " .. aaName)
                end,
            },
            {
                name = "SelfShield",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfManaRegen",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
        },
        ['PetSummon'] = {
            {
                name = "Artifact of Nature Spirit",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Nature Spirit")() end,
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
                load_cond = function(self)
                    return not Config:GetSetting("UseDonorPet") or not mq.TLO.FindItem("=Artifact of Nature Spirit")()
                end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "PetHaste",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "Crystalized Soul Gem", -- This isn't a typo
                type = "Item",
                cond = function(self, itemName)
                    return Casting.PetBuffItemCheck(itemName)
                end,
            },
            {
                name = "Minionskin",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Heal Mode",
            cond = function(self) return Core.IsModeActive("Heal") end,
            spells = {
                { name = "HealSpell", },
                { name = "GroupHeal", },
                { name = "SnareSpell",     cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Entrap") end, },
                { name = "ReptileBuff", },
                { name = "ATKDebuff",      cond = function(self) return Config:GetSetting('DoATKDebuff') end, },
                { name = "FireDebuff",     cond = function(self) return Config:GetSetting('DoFireDebuff') and not Casting.CanUseAA("Hand of Ro") end, },
                { name = "ColdDebuff",     cond = function(self) return Config:GetSetting('DoColdDebuff') end, },
                { name = "CurePoison",     cond = function(self) return Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",    cond = function(self) return Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "CureCorrupt",    cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
                { name = "EvacSpell",      cond = function(self) return Config:GetSetting('KeepEvacMemmed') and not Casting.CanUseAA("Exodus") end, },
                { name = "StunNuke",       cond = function(self) return Config:GetSetting('DoStunNuke') end, },
                { name = "FireNuke",       cond = function(self) return Config:GetSetting('DoFireNuke') end, },
                { name = "IceNuke",        cond = function(self) return Config:GetSetting('DoIceNuke') end, },
                { name = "PBAEMagic",      cond = function(self) return Config:GetSetting('DoPBAE') end, },
                { name = "IceRain",        cond = function(self) return Config:GetSetting('DoRain') end, },
                { name = "FlameLickDot",   cond = function(self) return Config:GetSetting('DoFlameLickDot') end, },
                { name = "SwarmDot",       cond = function(self) return Config:GetSetting('DoSwarmDot') end, },
                { name = "VengeanceDot",   cond = function(self) return Config:GetSetting('DoVengeanceDot') end, },
                -- { name = "BurstDS",      cond = function(self) return Config:GetSetting('DoBurstDS') end, },
                --fallback QoL to take up extra slots
                { name = "GroupRegenBuff", cond = function(self) return Config:GetSetting('DoGroupRegen') end, },
                { name = "GroupDmgShield", cond = function(self) return Config:GetSetting('DoGroupDmgShield') end, },
                { name = "HPTypeOneGroup", cond = function(self) return Config:GetSetting('DoHPBuff') end, },
            },
        },
    },
    ['Helpers']           = {
        DoRez = function(self, corpseId, ownerName)
            local rezAction = false
            local rezSpell = Core.GetResolvedActionMapItem('RezSpell')
            local rezStaff = self.ResolvedActionMap['RezStaff']
            local staffReady = mq.TLO.Me.ItemReady(rezStaff)()
            local okayToRez = Casting.OkayToRez(corpseId)
            local combatState = mq.TLO.Me.CombatState():lower() or "unknown"

            if combatState == "combat" and Config:GetSetting('DoBattleRez') and Core.OkayToNotHeal() then
                if staffReady then
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif Casting.AAReady("Call of the Wild") and not mq.TLO.Spawn(string.format("PC =%s", ownerName))() then
                    rezAction = okayToRez and Casting.UseAA("Call of the Wild", corpseId, true, 1)
                end
            elseif combatState ~= "combat" and staffReady then
                rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
            elseif combatState == "active" or combatState == "resting" then
                if Casting.SpellReady(rezSpell, true) then
                    rezAction = okayToRez and Casting.UseSpell(rezSpell, corpseId, true, true)
                end
            end

            return rezAction
        end,


        RainCheck = function(target) -- I made a funny
            if not Config:GetSetting('DoRain') or not Config:GetSetting('DoAEDamage') then return false end
            return Targeting.GetTargetDistance() >= Config:GetSetting('RainDistance')
        end,
    },
    ['DefaultConfig']     = {
        ['Mode']              = { DisplayName = "Mode", Category = "Combat", Tooltip = "Select the Combat Mode for this Toon", Type = "Custom", RequiresLoadoutChange = true, Default = 1, Min = 1, Max = 3, },

        -- Buffs
        ['DoMoveBuffs']       = {
            DisplayName = "Do Movement Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Cast Run/Movement Spells/AA.",
            RequiresLoadoutChange = true,
            Default = false,
            FAQ = "Why am I spamming movement or runspeed buffs?",
            Answer = "Some move spells freely overwrite those of other classes, so if multiple movebuffs are being used, a buff loop may occur.\n" ..
                "Simply turn off movement buffs for the undesired class in their class options.",
        },
        ['DoHPBuff']          = {
            DisplayName = "Group HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Use your group HP Buff. Disable as desired to prevent conflicts with CLR or PAL buffs.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoGroupRegen']      = {
            DisplayName = "Group Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Group Regen buff.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoGroupDmgShield']  = {
            DisplayName = "Group Dmg Shield",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Use your group damage shield buff.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "Why do my druid and mage constantly both try to use the damage shield?",
            Answer =
            "The internal mechanisms used to check stacking for these DS buffs report cross-stacking and can lead to spamming. Disable using damage shields on one or the other.",
        },
        ['DoMeleeBuff']       = {
            DisplayName = "Use Melee Skill Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your 'All (melee) Skills Damage Modifier' line of buffs. May conflict with shaman buffs.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['UseEpic']           = {
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
            ConfigType = "Advanced",
        },
        ['SpireChoice']       = {
            DisplayName = "Spire Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Choose which Fundament you would like to use during burns:\n" ..
                "First Spire: Spell Crit Buff to Self.\n" ..
                "Second Spire: Healing Power Buff to Self.\n" ..
                "Third Spire: Large Group HP Buff.",
            Type = "Combo",
            ComboOptions = Globals.Constants.SpireChoices,
            Default = 3,
            Min = 1,
            Max = #Globals.Constants.SpireChoices,
        },
        ['WolfSpiritChoice']  = {
            DisplayName = "Self Wolfbuff Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Choose which wolf spirit buff you would like to maintain on yourself:\n" ..
                "White: Increased healing and reduced mana cost for healing spells. Mana Regeneration and Cold Resist.\n" ..
                "Black: Increased damage and reduced mana cost for damage spells. Mana Regeneration and Fire Resist.",
            Type = "Combo",
            ComboOptions = { 'White', 'Black', },
            Default = 1,
            Min = 1,
            Max = 2,
        },

        --Debuffs
        ['DoSnare']           = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']        = {
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
        ['DoFireDebuff']      = {
            DisplayName = "Fire Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use your fire resist debuff (to include the (Hand > Blessing) of Ro AA).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoColdDebuff']      = {
            DisplayName = "Cold Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "Use your cold resist debuff.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoATKDebuff']       = {
            DisplayName = "ATK Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 101,
            Tooltip = "Use your attack resist debuff.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoSlow']            = {
            DisplayName = "Cast Cold Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = "Enable casting the cold-based Slow spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        --Damage
        ['DoFireNuke']        = {
            DisplayName = "Fire Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your single-target fire nukes.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoIceNuke']         = {
            DisplayName = "Cold Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your single-target cold nukes.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoStunNuke']        = {
            DisplayName = "Stun Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your stun nukes (magic damage with stun component).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoFlameLickDot']    = {
            DisplayName = "Fire Debuff Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Flame Lick line of dots (fire damage, fire resist debuff, 60s duration).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoVengeanceDot']    = {
            DisplayName = "Fire Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your Vengeance line of dots (fire damage, 30s duration).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoSwarmDot']        = {
            DisplayName = "Magic Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use your Swarm line of dots (magic damage, 54s duration).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DotNamedOnly']      = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
            FAQ = "Why am I not using my dots?",
        },

        --Damage(AE)
        ['DoPBAE']            = {
            DisplayName = "Use PBAE Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Magic PB AE Spells . **WILL BREAK MEZ**",
            Default = false,
        },
        ['DoRain']            = {
            DisplayName = "Use Ice Rain",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            Tooltip = "**WILL BREAK MEZ** Use your cold damage rain spell. **WILL BREAK MEZ***",
            Default = false,
        },
        ['RainDistance']      = {
            DisplayName = "Min Rain Distance",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 103,
            ConfigType = "Advanced",
            Tooltip = "The minimum distance a target must be to use a Rain (Rain AE Range: 25'). Used to avoid damaging the caster.",
            Default = 30,
            Min = 0,
            Max = 100,
        },

        -- Utility
        ['KeepPoisonMemmed']  = {
            DisplayName = "Mem Cure Poison",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Memorize cure poison spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepDiseaseMemmed'] = {
            DisplayName = "Mem Cure Disease",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Memorize cure disease spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepCurseMemmed']   = {
            DisplayName = "Mem Remove Curse",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 103,
            Tooltip = "Memorize remove curse spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepCorruptMemmed'] = {
            DisplayName = "Mem Cure Corruption",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 104,
            Tooltip = "Memorize cure corruption spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepEvacMemmed']    = {
            DisplayName = "Memorize Evac",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Keep (Lesser) Succor memorized.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['UseDonorPet']       = {
            DisplayName = "Summon Nature Spirit",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 101,
            Tooltip = "Use your Artifact of Nature Spirit to summon the donor mammoth pet.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
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

return _ClassConfig
