local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")
local Combat       = require("utils.combat")

local _ClassConfig = {
    _version              = "2.0 - Lazarus",
    _author               = "Algar",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },
    ['Modes']             = {
        'Heal',
    },
    ['Cures']             = {
        GetCureSpells = function(self)
            --(re)initialize the table for loadout changes
            self.TempSettings.CureSpells = {}

            -- Choose whether we should be trying to resolve the groupheal based on our settings and whether it cures at its level
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHeal')
            local groupHeal = (Config:GetSetting('GroupHealAsCure') and (ghealSpell and ghealSpell.Level() or 0) >= 70) and "GroupHeal"

            -- Find the map for each cure spell we need, given availability of groupheal, groupcure. fallback to curespell
            -- Curse is convoluted: If Keepmemmed, always use cure, if not, use groupheal if available and fallback to cure
            local neededCures = {
                ['Poison'] = Casting.GetFirstMapItem({ groupHeal, "PureBlood", "CurePoison", }),
                ['Disease'] = Casting.GetFirstMapItem({ groupHeal, "PureBlood", "CureDisease", }),
                ['Curse'] = not Config:GetSetting('KeepCurseMemmed') and (groupHeal or 'CureCurse') or 'CureCurse',
                -- ['Corruption'] = -- Project Lazarus does not currently have any Corruption Cures.
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
        ['Epic'] = {
            "Staff of Living Brambles",
            "Staff of Everliving Brambles",
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
        ['GroupHeal'] = { -- Laz specific, some taken from cleric, some custom
            "Word of Reconstitution",
            "Word of Redemption",
            "Word of Restoration",
            "Word of Vigor",
            "Word of Healing",
            "Word of Health",
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
            "Glacier Breath",
            "E`ci's Frosty Breath",
            "Twilight Breath",
        },
        ['ReptileBuff'] = {
            "Skin of the Reptile",
        },
        ['SwarmDot'] = { -- Magic Dot, 54s
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
            "Mask of the Hunter",
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
        ['AtkBuff'] = {        --Hit Damage/STR Buff
            "Lion's Strength", -- 5% Hit Damage
            "Nature's Might",  -- STR Buff
            "Girdle of Karana",
            "Storm Strength",
            "Strength of Stone",
            "Strength of Earth",
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
            'Resuscitate',    --emu only
            'Revive',         --emu only
            'Reanimation',    --emu only
        },
        ['CurePoison'] = {
            --"Eradicate Poison",
            "Counteract Poison",
            "Cure Poison",
        },
        ['CureDisease'] = {
            --"Eradicate Disease",
            "Counteract Disease",
            "Cure Disease",
        },
        ['CureCurse'] = {
            --"Eradicate Curse",
            "Remove Greater Curse",
            "Remove Curse",
            "Remove Lesser Curse",
            "Remove Minor Curse",
        },
        ['PureBlood'] = {
            "Pure Blood",
        },
        ['TwinHealNuke'] = {
            "Sunburst Blessing", -- Laz custom, description wrong, target mob
        },
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
        ['QuickGroupHeal'] = {
            "Moon Shadow",
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
                name = "Protection of Direwood",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "QuickGroupHeal",
                type = "Spell",
            },
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "Spirit of the Bear",
                type = "AA",
            },
            {
                name = "Kelp-Covered Hammer",
                type = "Item",
            },
            { --Let's make the mainheal autocrit since we have nothing better
                name = "Nature's Blessing",
                type = "AA",
            },
        },
        ['GroupHealPoint'] = {
            {
                name = "QuickGroupHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "GroupHeal",
                type = "Spell",
            },
        },
        ['MainHealPoint'] = {
            {
                name = "Elixir",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoElixir') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
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
        {
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal() and not mq.TLO.Me.Buff("Focus of Arcanum")()
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
                name = "Forsaken Elder Spiritist's Gauntlets",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Elder Spiritist's Gauntlets")() end,
                cond = function(self, itemName, target)
                    return Casting.DotItemCheck(itemName, target)
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
                load_cond = function() return Config:GetSetting('StunNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('StunNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.HaveManaToNuke() and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            { -- in-game description is incorrect, mob must be targeted.
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('TwinHealNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('TwinHealNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke() and not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Dawnstrike",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DawnstrikeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DawnstrikeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke(true) and not mq.TLO.Me.Song("Shadow of Dawn")()
                end,
            },
            {
                name = "FireNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('FireNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('FireNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke(true) and not mq.TLO.Me.Song("Shadow of Dawn")()
                end,
            },
            {
                name = "IceNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('IceNukeUse') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('IceNukeUse') == 2 and not mq.TLO.Me.Song("Wrath of the Wilderness")() then return false end
                    return Casting.OkayToNuke(true) and not mq.TLO.Me.Song("Shadow of Dawn")()
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
        ['GroupBuff'] = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMoveBuffs') end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName)
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
                name = "AtkBuff",
                type = "Spell",
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
                name = "PetSpell",
                type = "Spell",
                active_cond = function() return mq.TLO.Me.Pet.ID() ~= 0 end,
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
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Heal Mode",
            cond = function(self) return Core.IsModeActive("Heal") end,
            spells = {
                { name = "HealSpell", },
                { name = "QuickGroupHeal", },
                { name = "GroupHeal", },
                { name = "Elixir",         cond = function(self) return Config:GetSetting('DoElixir') end, },
                { name = "SnareSpell",     cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Entrap") end, },
                { name = "ReptileBuff", },
                { name = "ATKDebuff",      cond = function(self) return Config:GetSetting('DoATKDebuff') end, },
                { name = "FireDebuff",     cond = function(self) return Config:GetSetting('DoFireDebuff') and not Casting.CanUseAA("Hand of Ro") end, },
                { name = "ColdDebuff",     cond = function(self) return Config:GetSetting('DoColdDebuff') end, },
                {
                    name = "PureBlood",
                    cond = function(self)
                        return (Config:GetSetting('KeepDiseaseMemmed') or Config:GetSetting('KeepPoisonMemmed')) and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CurePoison",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepPoisonMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CureDisease",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepDiseaseMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "EvacSpell",      cond = function(self) return Config:GetSetting('KeepEvacMemmed') and not Casting.CanUseAA("Exodus") end, },
                { name = "StunNuke",       cond = function(self) return Config:GetSetting('StunNukeUse') > 1 end, },
                { name = "TwinHealNuke",   cond = function(self) return Config:GetSetting('TwinHealNukeUse') > 1 end, },
                { name = "Dawnstrike",     cond = function(self) return Config:GetSetting('DawnstrikeUse') > 1 end, },
                { name = "FireNuke",       cond = function(self) return Config:GetSetting('FireNukeUse') > 1 end, },
                { name = "IceNuke",        cond = function(self) return Config:GetSetting('IceNukeUse') > 1 end, },
                { name = "PBAEMagic",      cond = function(self) return Config:GetSetting('DoPBAE') end, },
                { name = "IceRain",        cond = function(self) return Config:GetSetting('DoRain') end, },
                { name = "FlameLickDot",   cond = function(self) return Config:GetSetting('DoFlameLickDot') end, },
                { name = "SwarmDot",       cond = function(self) return Config:GetSetting('DoSwarmDot') end, },
                { name = "VengeanceDot",   cond = function(self) return Config:GetSetting('DoVengeanceDot') end, },
                -- { name = "BurstDS",      cond = function(self) return Config:GetSetting('DoBurstDS') end, },
                { name = "PureBlood",      cond = function(self) return Config:GetSetting('KeepPoisonMemmed') or Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CurePoison",     cond = function(self) return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",    cond = function(self) return not Core.GetResolvedActionMapItem('PureBlood') and Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",      cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
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
            local okayToRez = Casting.OkayToRez(corpseId)
            local combatState = mq.TLO.Me.CombatState():lower() or "unknown"

            if combatState == "combat" and Config:GetSetting('DoBattleRez') and Core.OkayToNotHeal() then
                if mq.TLO.FindItem("Staff of Forbidden Rites")() and mq.TLO.Me.ItemReady("Staff of Forbidden Rites")() then
                    rezAction = okayToRez and Casting.UseItem("Staff of Forbidden Rites", corpseId)
                elseif Casting.AAReady("Call of the Wild") and not mq.TLO.Spawn(string.format("PC =%s", ownerName))() then
                    rezAction = okayToRez and Casting.UseAA("Call of the Wild", corpseId, true, 1)
                end
            elseif combatState == "active" or combatState == "resting" then
                if Casting.AAReady("Rejuvenation of Spirit") then
                    rezAction = okayToRez and Casting.UseAA("Rejuvenation of Spirit", corpseId, true, 1)
                elseif not Casting.CanUseAA("Rejuvenation of Spirit") and Casting.SpellReady(rezSpell, true) then
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

        --Damage
        ['FireNukeUse']       = {
            DisplayName = "Fire Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your single-target fire nukes.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['IceNukeUse']        = {
            DisplayName = "Cold Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your single-target cold nukes.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['StunNukeUse']       = {
            DisplayName = "Stun Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your stun nukes (magic damage with stun component).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 1,
            Min = 1,
            Max = 3,
            lt = true,
        },
        ['TwinHealNukeUse']   = {
            DisplayName = "Twinheal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Use your twinheal nuke (fire damage with a twinheal buff effect).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['DawnstrikeUse']     = {
            DisplayName = "Dawnstrike",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 105,
            Tooltip = "Use your Dawnstrike spell (quick nuke with a chance to proc a self- beneficial or detrimental spell damage buff.).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'Epic Procs Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
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
        ['DoElixir']          = {
            DisplayName = "Use Elixir",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use the Elixir Line (Yes, druids get Elixirs on Laz).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why isn't my druid using the elixir line?",
            Answer = "Since the elixirs druids get are slighly behind clerics of equal level, we will bypass their use if your target is already in \"BigHeal\" range.",
        },
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
        ['GroupHealAsCure']   = {
            DisplayName = "Use Group Heal to Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 104,
            Tooltip = "If Word of Reconstitution is available, use this to cure instead of individual cure spells. \n" ..
                "Please note that we will prioritize Remove Greater Curse if you have selected to keep it memmed as above (due to the counter disparity).",
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoArcanumWeave']    = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 105,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
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
        {
            Question = "Why would I only want to nuke on an 'Epic Proc'",
            Answer = "Epic 1.5, 2,0, and 2.5 worn foci have the chance to proc 'Wrath of the Wilderness', which makes your next nuke an instant cast.",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
