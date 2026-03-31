local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Comms        = require("utils.comms")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version              = "3.0 - Project Lazarus",
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

            -- Choose whether we should be trying to resolve the groupheal based on our settings and whether it cures at its level
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHeal')
            local groupHeal = (Config:GetSetting('GroupHealAsCure') and (ghealSpell and ghealSpell.Level() or 0) >= 70) and "GroupHeal"

            -- Find the map for each cure spell we need, given availability of groupheal, groupcure. fallback to curespell
            -- Curse is convoluted: If Keepmemmed, always use cure, if not, use groupheal if available and fallback to cure
            local neededCures = {
                ['Poison'] = Casting.GetFirstMapItem({ groupHeal, "GroupCure", "CurePoison", }),
                ['Disease'] = Casting.GetFirstMapItem({ groupHeal, "GroupCure", "CureDisease", }),
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
            "Crafted Talisman of Fates",
            "Blessed Spiritstaff of the Heyokah",
        },
        ['OoW_Chest'] = {
            "Ritualchanter's Tunic of the Ancestors",
            "Spiritkin Tunic",
        },
    },
    ['AbilitySets']       = {
        ["GroupFocusSpell"] = {
            -- Focus Spell - Group Spells will be used on everyone
            "Khura's Focusing",     -- Level 60 - Group
            "Focus of the Seventh", -- Level 65 - Group
            "Talisman of Wunshi",   -- Level 70 - Group
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
        ["Unification"] = { -- Many buffs combined: 75 Sta, 50 sta cap, 7% evasion, 5% damage
            "Talisman of Unification",
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
            "Talisman of Vehemence",
            "Spirit of Vehemence",
        },
        ["LowLvlAtkBuff"] = {
            -- Low Level Attack Buff --- user under level 86. Including Harnessing of Spirit as they will have similar usecases and targets.
            "Harnessing of Spirit",
            "Primal Avatar",
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
            "Talisman of Might",  -- Level 70, Group
            "Spirit of Might",    -- Level 68, Single Target
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
        ["LowLvlAgiBuff"] = {
            --- Low Level AGI Buff -- This has no real place outside of raids on select tanks. Waste of mana.
            "Talisman of Sense",
            "Spirit of Sense",
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
            -- Below Level 70 This is a single target buff and will be keyed off of the MA
            "Spirit of the Panther",
            "Spirit of the Leopard",
            "Spirit of the Jaguar",
            "Spirit of the Puma",
        },
        ["SlowProcBuff"] = {
            "Lingering Sloth",
        },
        ['RezSpell'] = {
            'Incarnate Anew', -- Level 59
            'Resuscitate',    --emu only
            'Revive',         --emu only
            'Reanimation',    --emu only
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
        ['GroupHeal'] = { -- Laz specific, some taken from cleric, some custom
            "Word of Reconstitution",
            "Word of Redemption",
            "Word of Restoration",
            "Word of Vigor",
            "Word of Healing",
            "Word of Health",
        },
        ["GroupRenewalHoT"] = {
            --This seems entirely not worth using since they were given direct group heals
            "Ghost of Renewal",
        },
        ['SnareHot'] = {
            "Transcendent Torpor",
            "Torpor",
            "Stoicism",
        },
        ["SingleHot"] = { -- some elixirs given to shm/dru on laz
            "Spiritual Serenity",
            "Breath of Trushar",
            "Quiescence",
            -- "Celestial Elixir" -- Quiescence same level and better
            "Celestial Healing",
            "Celestial Health",
            "Celestial Remedy",
        },
        ["CanniSpell"] = {
            -- Convert Health to Mana - Level  23 -
            "Ancient: Ancestral Calling",
            "Pained Memory",
            "Ancient: Chaotic Pain",
            "Cannibalize IV",
            "Cannibalize III",
            "Cannibalize II",
            "Cannibalize",
        },
        -- ["CureSpell"] = { --This is not useful in light of the alternatives
        --     "Blood of Nadox",
        -- },
        ["TwinHealNuke"] = {
            -- Nuke the MA Not the assist target - Levels 70
            "Frostfall Boon",
        },
        ["PoisonNuke"] = {
            -- Poison Nuke LVL34 +
            "Yoppa's Spear of Venom",
            "Spear of Torment",
            "Blast of Venom",
            "Shock of Venom",
            "Blast of Poison",
            "Shock of the Tainted",
        },
        ["ColdNuke"] = {
            --- ColdNuke - Level 4+
            --"Dire Avalanche", -- In resources but not scribable I think?
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
            "Nectar of Pain",
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
            "Breath of Wunshi",
            "Breath of Ultor",
            "Pox of Bertoxxulous",
            "Plague",
            "Scourge",
            "Affliction",
            "Sicken",
        },
        ["AEDot"] = { -- do homework for Laz
            "Blood of Yoppa",
        },
        ["PetSpell"] = { --We need to add handling for commune to get the mammoth/etc
            -- Pet Spell - 32+
            "Commune with the Wild",
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
        ['GroupCure'] = {
            "Blood of Nadox",
        },
        ["GroupRegenBuff"] = {
            "Talisman of Perseverance",
            "Regrowth of Dar Khura", -- Level 56
        },
        ["SingleRegenBuff"] = {
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
    },
    ['HelperFunctions']   = {
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
            {
                name = "GroupHeal",
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
                name = "Zun'Muram's Spear of Doom",
                type = "Item",
            },
            {
                name = "Union of Spirits",
                type = "AA",
            },
            { --The stuff above is down, lets make mainhealpoint chonkier.
                name = "Spiritual Blessing",
                type = "AA",
            },
            {
                name = "Armor of Ancestral Spirits",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
        },
        ["MainHealPoint"] = {
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
            timer = 10,
            state = 1,
            steps = 1,
            load_cond = function(self) return self:GetResolvedActionMapItem('MeleeProcBuff') end,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
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
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Buff("Focus of Arcanum")() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },

    },
    ['Rotations']         = {
        ['CombatBuff'] = {
            {
                name = "MeleeProcBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Fleeting Spirit",
                type = "AA",
            },
            {
                name = "Ancestral Aid",
                type = "AA",
            },
            {
                name = "Fundament: Second Spire of Ancestors",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Spirit Call",
                type = "AA",
            },
            {
                name = "Extended Pestilence",
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
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "Shattered Gnoll Slayer",
                type = "Item",
            },
        },
        ['Malo'] = {
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
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSTMalo') then return false end
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSTMalo') or Casting.CanUseAA("Malosinete") then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow'] = {
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
        ['PutridDecay'] = {
            {
                name = "PutridDecay",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
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
            { -- in-game description is incorrect, mob must be targeted.
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoTwinHealNuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true) and not Casting.IHaveBuff("Twincast")
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
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() ~= 0 end,
                cond = function(self, _) return Config:GetSetting('DoPet') and mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['Downtime'] = {
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
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },

            -- {
            --     -- this is emu only and lands only on your group but not yourself
            --     name = "Pact of the Wolf",
            --     type = "CustomFunc",
            --     active_cond = function(self) return mq.TLO.Me.Aura("Pact of the Wolf Effect")() ~= nil end,
            --     custom_func = function(self)
            --         if not Config:GetSetting('DoAura') or mq.TLO.Me.Aura("Pact of the Wolf Effect")() ~= nil then return false end
            --         Casting.UseAA("Pact of the Wolf", mq.TLO.Me.ID())
            --         mq.delay(500, function() return Casting.AAReady('Group Pact of the Wolf') end)
            --         Casting.UseAA("Group Pact of the Wolf", mq.TLO.Me.ID())
            --         return true
            --     end,
            -- },
        },
        ['PetBuff'] = {
            {
                name = "HasteBuff",
                type = "Spell",
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
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
                name = "Crystalized Soul Gem", -- This isn't a typo
                type = "Item",
                cond = function(self, itemName)
                    return Casting.PetBuffItemCheck(itemName)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Spirit Guardian",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.TargetIsATank(target) then return false end
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
                    mq.delay("3s", function() return not mq.TLO.Me.Casting() end)
                    if success and mq.TLO.Me.XTarget(petName)() then
                        Comms.PrintGroupMessage("It seems %s has triggered combat due to a server bug, calling the pet back.", spell)
                        Core.DoCmd('/pet back off')
                    end
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
                name = "Unification",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            { --Fix this, some priests will want this, adjust options
                name = "LowLvlAtkBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Talisman of Celerity",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoHaste') and Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHaste') and not Casting.CanUseAA("Talisman of Celerity") end,
                active_cond = function(self, aaName) return mq.TLO.Me.Haste() end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegenBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleRegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRegenBuff') and not Core.GetResolvedActionMapItem('GroupRegenBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return (Targeting.TargetIsATank(target) or Targeting.TargetIsMyself(target)) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') end,
                cond = function(self, spell, target) --We get Tala'tak at 74, but don't get the AA version until 90
                    if (mq.TLO.Me.AltAbility("Lupine Spirit").Rank() or -1) > 3 then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Group Shrink",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') end,
                active_cond = function(self) return mq.TLO.Me.Height() < 2 end,
                cond = function(self, aaName, target)
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
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlAgiBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLAgiBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlStaBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStaBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "LowLvlStrBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStrBuff') end,
                cond = function(self, spell, target)
                    return mq.TLO.Me.Level() < 71 and Targeting.TargetIsAMelee(target) and Casting.GroupBuffCheck(spell, target)
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
                { name = "SingleHot", cond = function(self) return Config:GetSetting('DoSingleHot') end, },
                { name = "SnareHot",  cond = function(self) return Config:GetSetting('DoSnareHot') end, },
                { name = "GroupHeal", },
                {
                    name = "GroupCure",
                    cond = function(self)
                        return (Config:GetSetting('KeepDiseaseMemmed') or Config:GetSetting('KeepPoisonMemmed')) and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CurePoison",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepPoisonMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                {
                    name = "CureDisease",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepDiseaseMemmed') and
                            not Casting.CanUseAA("Radiant Cure")
                    end,
                },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "SlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSpell",     cond = function(self) return not Casting.CanUseAA("Tigir's Insect Swarm") and Config:GetSetting('DoAESlow') end, },
                { name = "DiseaseSlow",     cond = function(self) return Config:GetSetting('DoSTSlow') and Config:GetSetting('DoDiseaseSlow') end, },
                { name = "MaloSpell",       cond = function(self) return not Casting.CanUseAA("Malosinete") and Config:GetSetting('DoSTMalo') end, },
                { name = "AEMaloSpell",     cond = function(self) return Config:GetSetting('DoAEMalo') end, },
                { name = "PutridDecay",     cond = function(self) return Config:GetSetting('DoPutrid') end, },
                { name = "CanniSpell",      cond = function(self) return Config:GetSetting('DoSpellCanni') end, },
                { name = "MeleeProcBuff", },
                { name = "SlowProcBuff", },
                { name = "LowLvlAtkBuff", },
                { name = "SingleRegenBuff", cond = function(self) return not Core.GetResolvedActionMapItem('GroupRegenBuff') and Config:GetSetting('DoRegenBuff') end, },
                { name = "TwinHealNuke",    cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "ColdNuke",        cond = function(self) return Config:GetSetting('DoColdNuke') end, },
                { name = "PoisonNuke",      cond = function(self) return Config:GetSetting('DoPoisonNuke') end, },
                { name = "GroupCure",       cond = function(self) return Config:GetSetting('KeepPoisonMemmed') or Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CurePoison",      cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",     cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "CurseDot",        cond = function(self) return Config:GetSetting('DoCurseDot') end, },
                { name = "SaryrnDot",       cond = function(self) return Config:GetSetting('DoSaryrnDot') end, },
                { name = "UltorDot",        cond = function(self) return Config:GetSetting('DoUltorDot') end, },
            },
        },
        {
            name = "Hybrid Mode",
            cond = function(self) return Core.IsModeActive("Hybrid") end,
            spells = {
                { name = "HealSpell", },
                { name = "SlowSpell",     cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSpell",   cond = function(self) return not Casting.CanUseAA("Tigir's Insect Swarm") and Config:GetSetting('DoAESlow') end, },
                { name = "DiseaseSlow",   cond = function(self) return Config:GetSetting('DoSTSlow') and Config:GetSetting('DoDiseaseSlow') end, },
                { name = "MaloSpell",     cond = function(self) return not Casting.CanUseAA("Malosinete") and Config:GetSetting('DoSTMalo') end, },
                { name = "AEMaloSpell",   cond = function(self) return Config:GetSetting('DoAEMalo') end, },
                { name = "PutridDecay",   cond = function(self) return Config:GetSetting('DoPutrid') end, },
                { name = "CanniSpell",    cond = function(self) return Config:GetSetting('DoSpellCanni') end, },
                { name = "MeleeProcBuff", },
                { name = "SlowProcBuff", },
                { name = "LowLvlAtkBuff", },
                { name = "ColdNuke",      cond = function(self) return Config:GetSetting('DoColdNuke') end, },
                { name = "PoisonNuke",    cond = function(self) return Config:GetSetting('DoPoisonNuke') end, },
                { name = "CurseDot",      cond = function(self) return Config:GetSetting('DoCurseDot') end, },
                { name = "SaryrnDot",     cond = function(self) return Config:GetSetting('DoSaryrnDot') end, },
                { name = "UltorDot",      cond = function(self) return Config:GetSetting('DoUltorDot') end, },
                { name = "TwinHealNuke",  cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "SingleHot",     cond = function(self) return Config:GetSetting('DoSingleHot') end, },
                { name = "SnareHot",      cond = function(self) return Config:GetSetting('DoSnareHot') end, },
                { name = "GroupHeal", },
                { name = "GroupCure",     cond = function(self) return Config:GetSetting('KeepPoisonMemmed') or Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CurePoison",    cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",   cond = function(self) return not Core.GetResolvedActionMapItem('GroupCure') and Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",     cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
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
        {
            id = 'DDSpell',
            Type = "Spell",
            DisplayName = "Burst of Flame",
            AbilityName = "Burst of Flame",
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = mq.TLO.Spell("Burst of Flame")
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
        ['DoTwinHealNuke']      = {
            DisplayName = "Twinheal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your twinheal nuke (cold damage with a twinheal buff effect).",
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
        ['GroupHealAsCure']     = {
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
            Tooltip = "Use your Regen buff (single target will be used until the group version is available).",
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
        ['DoArcanumWeave']      = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
        ['DoVetAA']             = {
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

        -- Low Level Buffs
        ['DoLLHPBuff']          = {
            DisplayName = "HP Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLAgiBuff']         = {
            DisplayName = "Agility Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStaBuff']         = {
            DisplayName = "Stamina Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStrBuff']         = {
            DisplayName = "Strength Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
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

return _ClassConfig
