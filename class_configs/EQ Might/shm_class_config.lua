local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require('utils.globals')
local Comms        = require("utils.comms")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")
local Combat       = require("utils.combat")

local _ClassConfig = {
    _version              = "3.1 - EQ Might",
    _author               = "Algar, Derple",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },
    ['Modes']             = {
        'Heal',
        'Hybrid',
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
            "Crafted Talisman of Fates",
            "Blessed Spiritstaff of the Heyokah",
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
            "Legendary Zun'Muram's Spear of Doom",
            "Legendary Aged Hammer of the Dragonborn",
            "Zun'Muram's Spear of Doom",
            "Aged Hammer of the Dragonborn",
        },
        ['OoW_Chest'] = {
            "Ritualchanter's Tunic of the Ancestors",
            "Spiritkin Tunic",
        },
    },
    ['AbilitySets']       = {
        ["GroupFocusSpell"] = {
            -- Focus Spell - Group Spells will be used on everyone
            "Khura's Focusing",            -- Level 60 - Group
            "Focus of the Seventh",        -- Level 65 - Group
            "Talisman of Wunshi",          -- Level 70 - Group
            "Ancient: Blessing of Wunshi", -- EQM 70
        },
        ["RunSpeedBuff"] = {
            -- Run Speed Buff - 9 - 74
            "Spirit of Bih`Li",
            "Pack Shrew",
            "Spirit of Wolf",
        },
        ["HasteBuff"] = {
            -- Haste Buff - 26 - 64
            "Talisman of Celerity",
            "Swift Like the Wind",
            "Celerity",
            "Quickness",
        },
        ["LowLvlStaBuff"] = {
            -- Low Level Stamina Buff --- I guess this may be okay for tanks (but largely a raid thing). Need to scrub which levels. Not currently used.
            "Spirit of Bear",
            "Spirit of Ox",
            "Health",
            "Stamina",
            "Riotous Health",
            "Talisman of the Brute",
            "Endurance of the Boar",
            "Talisman of the Boar",
            "Spirit of Fortitude",
            "Talisman of Fortitude",
            "Talisman of Persistence",
        },
        ["LowLvlAtkBuff"] = {
            -- Low Level Attack Buff --- user under level 86. Including Harnessing of Spirit as they will have similar usecases and targets.
            "Harnessing of Spirit",
            "Primal Avatar",
            "Ancient: Feral Avatar",
            "Ferine Avatar",
            "Champion",
        },
        ["LowLvlHPBuff"] = {
            "Inner Fire",         -- Level 1 - Single
            "Talisman of Tnarg",  -- Level 32 - Single
            "Talisman of Altuna", -- Level 40 - Single
            "Talisman of Kragg",  -- Level 55 - Single
        },
        ["LowLvlStrBuff"] = {
            -- Low Level Strength Buff -- Below 68 these are only worthwhile on non-live, defiant stat caps too easily. Even then arguable.
            "Talisman of the Diaku",
            "Infusion of Spirit", -- Level 49, Str/Dex/Sta, can use HP buff
            "Tumultuous Strength",
            "Raging Strength",
            "Spirit Strength", -- Level 18, Can't see this as being very worth but keeping for now.
        },
        ["LowLvlDexBuff"] = {
            -- Low Level Dex Buff -- This has no real place outside of raids on select tanks. Waste of mana.
            "Talisman of the Raptor",
            "Mortal Deftness",
            "Dexterity",
            "Deftness",
            "Rising Dexterity",
            "Spirit of Monkey",
            "Dexterous Aura",
        },
        ['EvasionBuff'] = { -- on EQM these are evasion buffs, not AGI.
            "Preternatural Foresight",
            "Talisman of Sense",
            "Spirit of Sense",
        },
        ["LowLvlAgiBuff"] = {
            --- Low Level AGI Buff -- This has no real place outside of raids on select tanks. Waste of mana.
            -- "Talisman of Sense",
            -- "Spirit of Sense",
            "Talisman of the Wrulan",
            "Agility of the Wrulan",
            "Talisman of the Cat",
            "Deliriously Nimble",
            "Agility",
            "Nimble",
            "Spirit of Cat",
            "Feet like Cat",
        },
        ["AEMaloSpell"] = {
            "Idol of Malos",
        },
        ["MaloSpell"] = {
            "Malosinise",
            "Malos",
            "Malosinia",
            "Malo",
            "Malosini",
            --Below this these spells are considered by many to be a waste of mana, but the user can elect to turn this off.
            "Malosi",
            "Malaisement",
            "Malaise",
        },
        ["AESlowSpell"] = { --Often considered a waste of mana in group situations, user option.
            "Tigir's Insects",
            -- PBAE Slow spell at 71, Tortugone's Drowse, also has a self melee absorb. chew on this for later. (50' range)
        },
        ["SlowSpell"] = {
            "Balance of Discord",
            "Balance of the Nihil",
            "Turgur's Insects", --Can save mana by continuing to use Togor's on group mobs, but this is problematic for automation. Not worth splitting the entry.
            "Togor's Insects",
            "Tagar's Insects",
            --"Walking Sleep", --Too much mana with little benefit at these levels
            --"Drowsy", --Too much mana with little benefit at these levels
        },
        ["DiseaseSlow"] = {
            "Hungry Plague",
            "Cloud of Grummus",
            "Plague of Insects",
        },
        ["CrippleSpell"] = {   -- needs to be added to spell list and have entries made
            "Crippling Spasm", -- Level 66
            "Cripple",         -- Level 53, Starts to become worth it, depending on target
            "Incapacitate",    -- Level 41, Likely not worth
            "Listless Power",  -- Level 29, Definitely not worth
        },
        ["MeleeProcBuff"] = {
            "Talisman of the Panther",
            -- "Spirit of the Panther", -- 69, group spell == less casting, longer duration, more avail to do other things
            --"Talisman of the Leopard", -- EQ Might Custom, but item only currently
            -- "Spirit of the Leopard", -- 61, group spell == less casting, longer duration, more avail to do other things
            "Talisman of the Jaguar", -- 61
            --  "Spirit of the Jaguar", -- 57, group spell == less casting, longer duration, more avail to do other things
            "Talisman of the Puma",   -- 55
            "Spirit of the Puma",     -- 50
        },
        ["SlowProcBuff"] = {
            "Lassitude",
            "Lingering Sloth",
        },
        ['RezSpell'] = {
            'Incarnate Anew', -- Level 59
        },
        ["HealSpell"] = {
            "Ancient: Wilslik's Mending",
            "Yoppa's Mending",
            "Daluda's Mending",
            "Tnarg's Mending",
            "Chloroblast",
            "Kragg's Salve",
            "Superior Healing",
            "Spirit Salve",
            "Greater Healing",
            "Healing",
            "Light Healing",
            "Minor Healing",
        },
        ["GroupRenewalHoT"] = {
            "Ancient: Ghost of Vitality",
            "Ghost of Renewal",
        },
        ['SnareHot'] = {
            "Torpor",
            "Stoicism",
        },
        ["SingleHot"] = {
            "Halcyon Breeze",
            "Spiritual Serenity",
            "Breath of Trushar",
            "Quiescence",
            "Spiritual Rejuvenation",
        },
        ["CanniSpell"] = {
            "Ancestral Bargain",
            "Ancient: Ancestral Calling",
            "Pained Memory",
            "Ancient: Chaotic Pain",
            "Cannibalize IV",
            "Cannibalize III",
            "Cannibalize II",
            "Cannibalize",
        },
        ["PoisonNuke"] = {
            "Sting of the Queen", -- Start fast poison nuke
            "Ahnkaul's Spear of Venom",
            "Yoppa's Spear of Venom",
            "Spear of Torment",
            "Blast of Venom",
            "Shock of Venom",
            "Blast of Poison",
            "Shock of the Tainted",
        },
        ["ColdNuke"] = {
            --- ColdNuke - Level 4+
            "Ice Age",
            "Velium Strike",
            "Ice Strike",
            "Blizzard Blast",
            "Winter's Roar",
            "Frost Strike",
            "Spirit Strike",
            "Frost Rift",
        },
        ["CurseDot"] = {
            -- Curse Dot 1 Stacking: Curse - Long Dot(30s) - Level 34+
            "Curse of Sisslak",
            "Bane",
            "Anathema",
            "Odium",
            "Curse",
        },
        ["SaryrnDot"] = {
            -- Stacking: Blood of Saryrn - Long Dot(42s) - Level 8+
            "Blood of Yoppa",
            "Blood of Saryrn",
            "Ancient: Scourge of Nife",
            "Bane of Nife",
            "Envenomed Bolt",
            "Venom of the Snake",
            "Envenomed Breath",
            "Tainted Breath",
        },
        ["UltorDot"] = {
            ---, Stacking: Breath of Ultor - Long Dot(84s) - Level 4+
            "Breath of Ternsmochin",
            "Breath of Wunshi",
            "Breath of Ultor",
            "Pox of Bertoxxulous",
            "Plague",
            "Scourge",
            "Affliction",
            "Sicken",
        },
        ['PBAEPoison'] = {
            "Yoppa's Rain of Venom",
            "Tears of Saryn",
            "Torrent of Poison",
            -- "Gale of Poison",
            -- "Poison Storm",
        },
        ["PetSpell"] = { --We need to add handling for commune to get the mammoth/etc
            -- Pet Spell - 32+
            "Farrel's Companion",
            "True Spirit",
            "Spirit of the Howler",
            "Frenzied Spirit",
            "Guardian spirit",
            "Vigilant Spirit",
            "Companion Spirit",
        },
        -- ["PetBuffSpell"] = { -- Haste is generally better
        --     ---Pet Buff Spell - 50+
        --     "Spirit Quickening",
        -- },
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
        -- ['GroupCure'] = {
        --     "Blood of Nadox",
        -- },
        ["RegenBuff"] = {
            "Spirit of the Stoic One",
            "Talisman of Perseverance",
            "Spirit of Perseverance",
            "Blessing of Replenishment", -- 63
            "Replenishment",
            "Regrowth of Dar Khura",     -- Level 56
            "Regrowth",
            "Chloroplast",
            "Regeneration", -- Level 22
        },
        ["ShrinkSpell"] = {
            "Shrink",
        },
        ["PutridDecay"] = { -- Level 66 Poi/Dis resist debuff
            "Putrid Decay",
        },
        ['Minionskin'] = { --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",
            "Greater Minionskin",
            "Minionskin",
            "Lesser Minionskin",
        },
        ['MeleeBuff'] = {
            "Ancient: Talisman of Might", -- Level 70, Group
            "Talisman of Might",          -- Level 70, Group
            "Spirit of Might",            -- Level 68, Single Target
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

        ProcBuffChoice = function()
            local buffSpell = Core.GetResolvedActionMapItem('MeleeProcBuff')
            local buffLevel = buffSpell and buffSpell.Level() or 0
            if mq.TLO.FindItem("=Legendary Armband of the Panther")() and mq.TLO.Me.Level() >= 68 and buffLevel < 70 then
                return "PantherItem"
            elseif mq.TLO.FindItem("=Artifact of the Leopard")() and mq.TLO.Me.Level() >= 65 and buffLevel < 70 then
                return "LeopardItem"
            elseif mq.TLO.FindItem("=Artifact of the Jaguar")() and mq.TLO.Me.Level() >= 52 and buffLevel < 55 then
                return "JaguarItem"
            end
            return "ProcSpell"
        end,
    },
    -- These are handled differently from normal rotations in that we try to make some intelligent desicions about which spells to use instead
    -- of just slamming through the base ordered list.
    -- These will run in order and exit after the first valid spell to cast
    ['HealRotationOrder'] = {
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ["GroupHealPoint"] = {
            {
                name = "Call of the Ancients",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigHealsNeeded(target)
                end,
            },
            { -- use the blue band first if someone is lower health, don't load this if we don't have any blue band
                name = "GroupRenewalHoT",
                type = "Spell",
                load_cond = function(self) return Core.GetResolvedActionMapItem("VampiricBlueBand") or Core.GetResolvedActionMapItem("BlueBand") end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target)
                end,
            },
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
            { -- use this regardless of health setting if the blue band isn't ready
                name = "GroupRenewalHoT",
                type = "Spell",
            },
        },
        ["BigHealPoint"] = {
            {
                name = "SnareHot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSnareHot') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Ancestral Guard",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Timer2HealItem",
                type = "Item",
            },
            {
                name = "Mark of the Brood Warden",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Mark of the Brood Warden")() end,
            },
            {
                name = "Union of Spirits",
                type = "AA",
            },
            { --if we hit this we need spells back ASAP
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ["MainHealPoint"] = {
            { -- keep this for big heals, unless we are critically low on mana
                name = "Timer2HealItem",
                type = "Item",
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            { -- keep this for big heals, unless we are critically low on mana
                name = "Mark of the Brood Warden",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Mark of the Brood Warden")() end,
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            {
                name = "SingleHot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSingleHot') end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target) and Casting.GroupBuffCheck(spell, target)
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
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToBuff() and
                    Casting.AmIBuffable()
            end,
        },
        { --Summon pet even when buffs are off on emu
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and
                    Casting.AmIBuffable()
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
        { --Spells that should be checked on group members
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Malo',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSTMalo') or Config:GetSetting('DoAEMalo') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'Slow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSTSlow') or Config:GetSetting('DoAESlow') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'Cripple',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoCripple') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'PutridDecay',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoPutrid') and Core.GetResolvedActionMapItem("PutridDecay") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'CombatBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'MeleeProcBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'DPS(AE)',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoPBAE') and self:GetResolvedActionMapItem('PBAEPoison') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoAEDamage') then return false end
                return combat_state == "Combat" and Core.OkayToNotHeal() and Targeting.AggroCheckOkay() and Combat.AETargetCheck(true)
            end,
        },

    },
    ['Rotations']         = {
        ['MeleeProcBuff'] = {
            {
                name = "Legendary Armband of the Panther",
                type = "Item",
                load_cond = function(self) return self.Helpers.ProcBuffChoice() == "PantherItem" end,
                cond = function(self, itemName, target)
                    if (mq.TLO.Me.CombatState():lower() or "") ~= "combat" then return false end
                    return Casting.GroupBuffItemCheck(itemName, target) and Casting.AddedBuffCheck(9975, target) --Panther Rk. II
                end,
            },
            {
                name = "Artifact of the Leopard",
                type = "Item",
                load_cond = function(self) return self.Helpers.ProcBuffChoice() == "LeopardItem" end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target) and Casting.AddedBuffCheck(9975, target) --Panther Rk. II
                end,
            },
            {
                name = "Artifact of the Jaguar",
                type = "Item",
                load_cond = function(self) return self.Helpers.ProcBuffChoice() == "JaguarItem" end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target) and Casting.AddedBuffCheck(9975, target) --Panther Rk. II
                end,
            },
            {
                name = "MeleeProcBuff",
                type = "Spell",
                load_cond = function(self) return self.Helpers.ProcBuffChoice() == "ProcSpell" end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end                                 --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target) and Casting.AddedBuffCheck(9975, target) --Panther Rk. II
                end,
            },
        },
        ['CombatBuff']    = {
            {
                name = "Companion's Blessing",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name = "Cannibalization",
                type = "AA",
                allowDead = true,
                cond = function(self, aaName)
                    if not (Config:GetSetting('DoAACanni') and Config:GetSetting('DoCombatCanni')) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell)
                    if not (Config:GetSetting('DoSpellCanni') and Config:GetSetting('DoCombatCanni')) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "Artifact of Nature Spirit",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Nature Spirit")() end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['Burn']          = {
            {
                name = "Ancestral Aid",
                type = "AA",
                pre_activate = function(self)
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
                end,
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Spirit Call",
                type = "AA",
            },
            {
                name = "Rabid Bear",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoMelee') and mq.TLO.Me.Combat()
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Spear of Fate",
                type = "Item",
                cond = function(self, itemName, target)
                    return Globals.AutoTargetIsNamed and Casting.DotItemCheck(itemName, target)
                end,
            },
        },
        ['Malo']          = {
            {
                name = "AEMaloSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAEMalo') then return false end
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "Malosinete",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoSTMalo') and Casting.CanUseAA("Malosinete") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoSTMalo') and not Casting.CanUseAA("Malosinete") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow']          = {
            {
                name = "Tigir's Insect Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and Casting.CanUseAA("Tigir's Insect Swarm") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "AESlowSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and not Casting.CanUseAA("Tigir's Insect Swarm") end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoAESlow') or Casting.CanUseAA("Tigir's Insect Swarm") then return false end
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "Turgur's Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and (Casting.CanUseAA("Turgur's Swarm") and not Config:GetSetting('DoDiseaseSlow')) end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name_func = function(self)
                    return Config:GetSetting('DoDiseaseSlow') and "DiseaseSlow" or "SlowSpell"
                end,
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and (not Casting.CanUseAA("Turgur's Swarm") or Config:GetSetting('DoDiseaseSlow')) end,
                type = "Spell",
                waitReadyTime = function() return Config:GetSetting('DiseaseSlowWaitTime') end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['PutridDecay']   = {
            {
                name = "PutridDecay",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Cripple']       = {
            {
                name = "CrippleSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['DPS']           = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "CurseDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoCurseDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "SaryrnDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSaryrnDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "UltorDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoUltorDot') or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "ColdNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoColdNuke') then return false end
                    return (Targeting.MobHasLowHP or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed)) and Casting.OkayToNuke(true)
                end,
            },
            {
                name = "PoisonNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoPoisonNuke') then return false end
                    return (Targeting.MobHasLowHP or (Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed)) and Casting.OkayToNuke(true)
                end,
            },
        },
        ['DPS(AE)']       = {
            {
                name = "PBAEPoison",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
        },
        ['PetSummon']     = {
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
        ['Downtime']      = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Cannibalization",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoAACanni') and mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoSpellCanni') and Casting.CastReady(spell) and mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and
                        mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "Pact of the Wolf",
                type = "AA",
                load_cond = function() return not Casting.CanUseAA("Group Pact of the Wolf") end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['PetBuff']       = {
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHaste') and not Casting.CanUseAA("Talisman of Celerity") end,
                cond = function(self, spell, target)
                    if Casting.CanUseAA("Pet Affinity") then return false end
                    return Casting.PetBuffCheck(spell)
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
                name = "Minionskin",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
        },
        ['GroupBuff']     = {
            {
                name = "Communion of the Cheetah",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoRunSpeed') and Casting.CanUseAA("Communion of the Cheetah") end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "SlowProcBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
                post_activate = function(self, spell, success)
                    local petName = mq.TLO.Me.Pet.CleanName() or "None"
                    mq.delay("3s", function() return mq.TLO.Me.Casting() == nil end)
                    if success and mq.TLO.Me.XTarget(petName)() then
                        Comms.PrintGroupMessage("It seems %s has triggered combat due to a server bug, calling the pet back.", spell)
                        Core.DoCmd('/pet back off')
                    end
                end,
            },
            {
                name = "Group Pact of the Wolf",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Group Pact of the Wolf") end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            { --Used on the entire group
                name = "GroupFocusSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of the Champion",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Artifact of the Champion")() and mq.TLO.Me.Level() >= 68 end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
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
            { --Fix this, some priests will want this, adjust options
                name = "LowLvlAtkBuff",
                type = "Spell",
                load_cond = function(self) return not mq.TLO.FindItem("=Artifact of the Champion")() or mq.TLO.Me.Level() < 68 end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                        -- Don't try to overwrite Champion with Ferine Avatar
                        and Casting.AddedBuffCheck(5417, target)
                end,
            },
            {
                name = "EvasionBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Talisman of Celerity",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoHaste') and Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHaste') and not Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "RegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegenBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not (Targeting.TargetIsATank(target) or Targeting.TargetIsMyself(target)) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoRunSpeed') and not Casting.CanUseAA("Communion of the Cheetah") end,
                cond = function(self, spell, target) --We get Tala'tak at 74, but don't get the AA version until 90
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Group Shrink",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') end,
                active_cond = function(self) return mq.TLO.Me.Height() < 2 end,
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoGroupShrink') then return false end
                    return Targeting.GetTargetHeight(target) > 2.2
                end,
            },
            {
                name = "ShrinkSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') and not Casting.CanUseAA("Group Shrink") end,
                active_cond = function(self) return mq.TLO.Me.Height() < 2 end,
                cond = function(self, spell, target)
                    return Targeting.GetTargetHeight(target) > 2.2
                end,
            },
            {
                name = "LowLvlHPBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLHPBuff') end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlAgiBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLAgiBuff') end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlStaBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStaBuff') end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlStrBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStrBuff') end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
    },
    -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
    -- Conditions are not limited to modes. Virtually any helper function or TLO can be used. Example: Level-based lists.
    -- The first list whose conditions returns true will be loaded, all subsequent lists will be ignored.
    -- Loadout checks (such as scribing a spell or using the "Rescan Loadout" or "Reload Spells" buttons) will re-check these lists and may load a different set if things have changed.
    ['SpellList']         = {
        {
            name = "Heal Mode", --This name is abitrary, it is simply what shows up in the UI when this spell list is loaded.
            cond = function(self) return Core.IsModeActive("Heal") end,
            spells = {          -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
                { name = "HealSpell", },
                { name = "GroupRenewalHoT", },
                { name = "SingleHot",       cond = function(self) return Config:GetSetting('DoSingleHot') end, },
                { name = "SnareHot",        cond = function(self) return Config:GetSetting('DoSnareHot') end, },
                { name = "CurePoison",      cond = function(self) return Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",     cond = function(self) return Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "CureCorrupt",     cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
                { name = "SlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSpell",     cond = function(self) return not Casting.CanUseAA("Tigir's Insect Swarm") and Config:GetSetting('DoAESlow') end, },
                { name = "DiseaseSlow",     cond = function(self) return Config:GetSetting('DoSTSlow') and Config:GetSetting('DoDiseaseSlow') end, },
                { name = "MaloSpell",       cond = function(self) return not Casting.CanUseAA("Malosinete") and Config:GetSetting('DoSTMalo') end, },
                { name = "AEMaloSpell",     cond = function(self) return Config:GetSetting('DoAEMalo') end, },
                { name = "CrippleSpell",    cond = function(self) return Config:GetSetting('DoCripple') end, },
                { name = "PutridDecay",     cond = function(self) return Config:GetSetting('DoPutrid') end, },
                { name = "CanniSpell",      cond = function(self) return Config:GetSetting('DoSpellCanni') end, },
                { name = "MeleeProcBuff",   cond = function(self) return self.Helpers.ProcBuffChoice() == "ProcSpell" end, },
                { name = "SlowProcBuff", },
                { name = "LowLvlAtkBuff",   cond = function(self) return not mq.TLO.FindItem("=Artifact of the Champion")() or mq.TLO.Me.Level() < 68 end, },
                { name = "ColdNuke",        cond = function(self) return Config:GetSetting('DoColdNuke') end, },
                { name = "PoisonNuke",      cond = function(self) return Config:GetSetting('DoPoisonNuke') end, },
                { name = "CurseDot",        cond = function(self) return Config:GetSetting('DoCurseDot') end, },
                { name = "SaryrnDot",       cond = function(self) return Config:GetSetting('DoSaryrnDot') end, },
                { name = "UltorDot",        cond = function(self) return Config:GetSetting('DoUltorDot') end, },
                { name = "PBAEPoison",      cond = function(self) return Config:GetSetting('DoPBAE') end, },
            },
        },
        {
            name = "Hybrid Mode",
            cond = function(self) return Core.IsModeActive("Hybrid") end,
            spells = {
                { name = "HealSpell", },
                { name = "SlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSpell",     cond = function(self) return not Casting.CanUseAA("Tigir's Insect Swarm") and Config:GetSetting('DoAESlow') end, },
                { name = "DiseaseSlow",     cond = function(self) return Config:GetSetting('DoSTSlow') and Config:GetSetting('DoDiseaseSlow') end, },
                { name = "MaloSpell",       cond = function(self) return not Casting.CanUseAA("Malosinete") and Config:GetSetting('DoSTMalo') end, },
                { name = "AEMaloSpell",     cond = function(self) return Config:GetSetting('DoAEMalo') end, },
                { name = "CrippleSpell",    cond = function(self) return Config:GetSetting('DoCripple') end, },
                { name = "PutridDecay",     cond = function(self) return Config:GetSetting('DoPutrid') end, },
                { name = "CanniSpell",      cond = function(self) return Config:GetSetting('DoSpellCanni') end, },
                { name = "MeleeProcBuff",   cond = function(self) return self.Helpers.ProcBuffChoice() == "ProcSpell" end, },
                { name = "SlowProcBuff", },
                { name = "LowLvlAtkBuff",   cond = function(self) return not mq.TLO.FindItem("=Artifact of the Champion")() or mq.TLO.Me.Level() < 68 end, },
                { name = "ColdNuke",        cond = function(self) return Config:GetSetting('DoColdNuke') end, },
                { name = "PoisonNuke",      cond = function(self) return Config:GetSetting('DoPoisonNuke') end, },
                { name = "CurseDot",        cond = function(self) return Config:GetSetting('DoCurseDot') end, },
                { name = "SaryrnDot",       cond = function(self) return Config:GetSetting('DoSaryrnDot') end, },
                { name = "UltorDot",        cond = function(self) return Config:GetSetting('DoUltorDot') end, },
                { name = "PBAEPoison",      cond = function(self) return Config:GetSetting('DoPBAE') end, },
                { name = "SingleHot",       cond = function(self) return Config:GetSetting('DoSingleHot') end, },
                { name = "SnareHot",        cond = function(self) return Config:GetSetting('DoSnareHot') end, },
                { name = "GroupRenewalHoT", },
                { name = "CurePoison",      cond = function(self) return Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",     cond = function(self) return Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "CureCorrupt",     cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
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
        ['Mode']                = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes do?",
            Answer =
            "Heal Mode: Primarily focuses on healing, cures, and maintaining HoTs. Secondary DPS focus with remaining spell gems. Hybrid: Prioritizes DPS spells over some utility healing abilities on the spell bar.",
        },

        -- Damage
        ['DoColdNuke']          = {
            DisplayName = "Cold Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your single-target cold nukes.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoPoisonNuke']        = {
            DisplayName = "Poison Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use your single-target poison nukes.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSaryrnDot']         = {
            DisplayName = "Poison Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your Saryrn line of dots (poison damage, single target).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoUltorDot']          = {
            DisplayName = "Disease Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your Ultor line of dots (disease damage, single target).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoCurseDot']          = {
            DisplayName = "Magic Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use your Curse line of dots (magic damage, single target).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DotNamedOnly']        = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
        },

        -- Healing
        ['DoSingleHot']         = {
            DisplayName = "Use Single HoT",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use single target (non-snaring) HoTs like Spiritual Serenity as a main heal.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoSnareHot']          = {
            DisplayName = "Use Snare HoT",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use snaring HoTs like torpor when HP is very low.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['KeepPoisonMemmed']    = {
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
        ['KeepDiseaseMemmed']   = {
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
        ['KeepCurseMemmed']     = {
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
        ['KeepCorruptMemmed']   = {
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

        -- Canni
        ['DoAACanni']           = {
            DisplayName = "Use AA Canni",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip = "Use Canni AA",
            RequiresLoadoutChange = true, -- This is a load condition
            Default = true,
            ConfigType = "Advanced",
        },
        ['AACanniManaPct']      = {
            DisplayName = "AA Canni Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 105,
            Tooltip = "Use Canni AA Under [X]% mana",
            Default = 70,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['AACanniMinHP']        = {
            DisplayName = "AA Canni HP %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 106,
            Tooltip = "Dont Use Canni AA Under [X]% HP",
            Default = 90,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoSpellCanni']        = {
            DisplayName = "Use Spell Canni",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Mem and use Canni Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['SpellCanniManaPct']   = {
            DisplayName = "Spell Canni Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "Use Canni Spell Under [X]% mana",
            Default = 70,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['SpellCanniMinHP']     = {
            DisplayName = "Spell Canni HP %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            Tooltip = "Dont Use Canni Spell Under [X]% HP",
            Default = 85,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoCombatCanni']       = {
            DisplayName = "Canni in Combat",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 107,
            Tooltip = "Use Canni AA and Spells in combat",
            Default = true,
            ConfigType = "Advanced",
        },

        -- Buffs
        ['UseEpic']             = {
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
        ['DoRunSpeed']          = {
            DisplayName = "Do Run Speed",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Do Run Speed Spells/AAs",
            Default = true,
            FAQ = "Why are my buffers in a run speed buff war?",
            Answer = "Many run speed spells freely stack and overwrite each other, you will need to disable Run Speed Buffs on some of the buffers.",
        },
        ['DoGroupShrink']       = {
            DisplayName = "Group Shrink",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip = "Use Group Shrink Buff",
            Default = true,
            FAQ = "Group Shrink is enabled, why are my dudes still big?",
            Answer =
            "For simplicity, the check to use it is keyed to the Shaman's height, rather than checking each group member.",
        },
        ['DoRegenBuff']         = {
            DisplayName = "Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Regen buff (best of single or group versions).",
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoHaste']             = {
            DisplayName = "Use Haste",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Do Haste Spells/AAs",
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoMeleeBuff']         = {
            DisplayName = "Use Melee Skill Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your 'All (melee) Skills Damage Modifier' line of buffs. May conflict with druid buffs.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        -- Debuffs
        ['DoSTMalo']            = {
            DisplayName = "Do ST Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Do ST Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAEMalo']            = {
            DisplayName = "Do AE Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "Do AE Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoSTSlow']            = {
            DisplayName = "Do ST Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = "Do ST Slow Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,

        },
        ['DoAESlow']            = {
            DisplayName = "Do AE Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 102,
            Tooltip = "Do AE Slow Spells/AAs",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['AESlowCount']         = {
            DisplayName = "AE Slow Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 103,
            Tooltip = "Number of XT Haters before we use AE Slow.",
            Min = 1,
            Default = 2,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['AEMaloCount']         = {
            DisplayName = "AE Malo Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 103,
            Tooltip = "Number of XT Haters before we use AE Malo.",
            Min = 1,
            Default = 2,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['DoDiseaseSlow']       = {
            DisplayName = "Disease Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 104,
            Tooltip = "Use Disease Slow instead of normal ST Slow",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
            FAQ = "What is a Disease Slow?",
            Answer =
            "During early eras of play, a slow that checked against disease resist was added to slow magic-resistant mobs. If selected, this will be used instead of a magic-based slow until the Turgur's AA becomes available.",
        },
        ['DiseaseSlowWaitTime'] = {
            DisplayName = "Disease Slow Wait",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 105,
            Tooltip = "Maximum amount of time (in miliseconds) to wait for Disease Slow to be ready before giving up.",
            Default = 100,
            Min = 0,
            Max = 10000,
            ConfigType = "Advanced",
        },
        ['DoPutrid']            = {
            DisplayName = "Putrid Decay",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use your disease/poison resist debuff.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoCripple']           = {
            DisplayName = "Cast Cripple",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 101,
            Tooltip = "Enable casting Cripple spells.",
            RequiresLoadoutChange = true,
            Default = false,
        },

        -- Low Level Buffs
        ['DoLLHPBuff']          = {
            DisplayName = "HP Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLAgiBuff']         = {
            DisplayName = "Agility Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStaBuff']         = {
            DisplayName = "Stamina Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStrBuff']         = {
            DisplayName = "Strength Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 109,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },

        --Damage(AE)
        ['DoPBAE']              = {
            DisplayName = "Use PBAE Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Poison PB AE Spells . **WILL BREAK MEZ**",
            Default = false,
        },

        ['UseDonorPet']         = {
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
