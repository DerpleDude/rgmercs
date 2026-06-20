local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require('utils.combat')
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require('utils.globals')
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version              = "2.3 - EQ Might",
    _author               = "Algar, Derple, Robban",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function()
            local rezAction = Casting.CanUseAA("Blessing of Resurrection") or mq.TLO.FindItem("=Water Sprinkler of Nem Ankh")() or Core.GetResolvedActionMapItem('RezStaff')
            return ((Core.GetResolvedActionMapItem('RezSpell') or rezAction) and Targeting.GetXTHaterCount() == 0) or (Config:GetSetting('DoBattleRez') and rezAction)
        end,
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
            local groupHeal = (Config:GetSetting('GroupHealAsCure') and (ghealSpell and ghealSpell.Level() or 0) >= 64) and "GroupHeal"

            -- Find the map for each cure spell we need, given availability of groupheal, groupcure. fallback to curespell
            -- These are convoluted: If Keepmemmed, always use cure, if not, use groupheal if available and fallback to cure
            local neededCures = {
                ['Poison'] = not Config:GetSetting('KeepPoisonMemmed') and (groupHeal or 'CurePoison') or 'CurePoison',
                ['Disease'] = not Config:GetSetting('KeepDiseaseMemmed') and (groupHeal or 'CureDisease') or 'CureDisease',
                ['Curse'] = not Config:GetSetting('KeepCurseMemmed') and (groupHeal or 'CureCurse') or 'CureCurse',
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
            if not targetSpawn and targetSpawn() then return false, false end

            if Config:GetSetting('DoCureAA') then
                local cureAA = Casting.AAReady("Purify Soul") and "Purify Soul"
                if Casting.AAReady("Group Purify Soul") and Targeting.GroupedWithTarget(targetSpawn) then
                    cureAA = "Group Purify Soul"
                elseif Casting.AAReady("Radiant Cure") then
                    cureAA = "Radiant Cure"
                    -- I am finding self-cures to be less than helpful when most effects on a healer are group-wide
                    -- elseif targetId == mq.TLO.Me.ID() and Casting.AAReady("Purified Spirits") then
                    --   cureAA = "Purified Spirits"
                end
                if cureAA then
                    Logger.log_debug("CureNow: Using %s for %s on %s.", cureAA, type:lower() or "unknown", mq.TLO.Spawn(targetId).CleanName() or "Unknown")
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
    ['Themes']            = {
        ['Heal'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.30, g = 0.28, b = 0.21, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.30, g = 0.28, b = 0.21, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.70, g = 0.65, b = 0.50, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.48, g = 0.44, b = 0.34, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.70, g = 0.65, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.70, g = 0.65, b = 0.50, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.30, g = 0.28, b = 0.21, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.99, b = 0.90, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.99, b = 0.90, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.70, g = 0.65, b = 0.50, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Harmony of the Soul",
            "Aegis of Superior Divinity",
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
            "Legendary Weighted Hammer of Conviction",
            "Legendary Aged Shissar Apothic Staff",
            "Weighted Hammer of Conviction",
            "Aged Shissar Apothic Staff",
        },
        ['OoW_Chest'] = {
            "Faithbringer's Breastplate of Conviction",
            "Sanctified Chestguard",
        },
    },
    ['AbilitySets']       = {
        -- ['WardSelfBuff'] = {
        --     "Ward of Retribution", -- Level 69
        -- },
        ['HealingLight'] = {
            "Sacred Light",            -- Level 71
            "Ancient: Hallowed Light", -- Level 70
            "Pious Light",             -- Level 67
            "Holy Light",              -- Level 65
            "Supernal Light",          -- Level 63
            "Ethereal Light",          -- Level 58
            "Divine Light",            -- Level 53
            "Healing Light",           -- Level 39
            "Superior Healing",        -- Level 30
            "Greater Healing",         -- Level 20
            "Healing",                 -- Level 10
            "Light Healing",           -- Level 4
            "Minor Healing",           -- Level 1
        },
        ['RemedyHeal'] = {             -- Not great until 96/RoF (Graceful)
            "Pious Remedy",            -- Level 66
            "Supernal Remedy",         -- Level 61
            "Ethereal Remedy",         -- Level 59
            "Remedy",                  -- Level 51
        },
        ['Renewal'] = {                -- Level 70 +, large heal, slower cast
            "Desperate Renewal",       -- Level 70
        },
        ['GroupHeal'] = {
            "Word of Vivacity",      -- Level 80
            "Word of Vivification",  -- Level 69
            "Word of Replenishment", -- Level 64
            "Word of Restoration",   -- Level 57, No good NoCure in these level ranges using w/Cure... Note Word of Redemption omitted (12sec cast)
            "Word of Vigor",         -- Level 52
            "Word of Healing",       -- Level 45
            "Word of Health",        -- Level 30
        },
        ['SelfHPBuff'] = {
            --Self Buff for Mana Regen and armor
            "Armor of the Pious",             -- Level 70
            "Armor of the Zealot",            -- Level 65
            "Ancient: High Priest's Bulwark", -- Level 60
            "Blessed Armor of the Risen",     -- Level 58
            "Armor of Protection",            -- Level 34
        },
        ['AegoBuff'] = {
            ----Use HP Type one until Temperance at 40... Group Buff at 45 (Blessing of Temperance)
            "Hand of Conviction",        -- Level 70
            "Hand of Virtue",            -- Level 65
            "Ancient: Gift of Aegolism", -- Level 60
            "Blessing of Aegolism",      -- Level 60
            "Blessing of Temperance",    -- Level 45
            "Temperance",                -- Level 40
            "Valor",                     -- Level 32
            "Bravery",                   -- Level 22
            "Daring",                    -- Level 17
            "Center",                    -- Level 7
            "Courage",                   -- Level 1
        },
        ['ACBuff'] = {
            "Ward of Valiance",  -- Level 66
            "Ward of Gallantry", -- Level 61
            "Bulwark of Faith",  -- Level 57
            "Shield of Words",   -- Level 45
            "Armor of Faith",    -- Level 35
            "Guard",             -- Level 25
            "Spirit Armor",      -- Level 15
            "Holy Armor",        -- Level 1
        },
        ['SingleVieBuff'] = {
            "Aegis of Vie",      -- Level 71
            "Panoply of Vie",    -- Level 67
            "Bulwark of Vie",    -- Level 62
            "Protection of Vie", -- Level 54
            "Guard of Vie",      -- Level 40
            "Ward of Vie",       -- Level 20
        },
        ['GroupSymbolBuff'] = {
            ----Group Symbols
            "Balikor's Mark",    -- Level 70
            "Kazad's Mark",      -- Level 63
            "Marzin's Mark",     -- Level 60
            "Naltron's Mark",    -- Level 58
            "Symbol of Marzin",  -- Level 54
            "Symbol of Naltron", -- Level 41
            "Symbol of Pinzarn", -- Level 31
            "Symbol of Ryltan",  -- Level 21
            "Symbol of Transal", -- Level 11
        },
        ['AbsorbAura'] = {
            ----Aura Buffs - Aura Name is seperate than the buff name
            "Aura of the Pious",  -- Level 66
            "Aura of the Zealot", -- Level 55
        },
        ['HPAura'] = {
            ---- Aura Buff 2 - Aura Name is the same as the buff name
            "Aura of Divinity", -- Level 100
        },
        ['DivineBuff'] = {
            --Divine Buffs REQUIRES extra spell slot because of the 90s recast
            "Divine Incursion",    -- Level 69 EQM Custom
            "Divine Interaction",  -- Level 65 EQM Custom
            "Divine Intervention", -- Level 60
            "Death Pact",          -- Level 51
        },
        ['RezSpell'] = {
            "Reviviscence",   -- Level 56
            "Resurrection",   -- Level 47
            "Restoration",    -- Level 42
            "Resuscitate",    -- Level 37
            "Renewal",        -- Level 32
            "Revive",         -- Level 27
            "Reparation",     -- Level 22
            "Reconstitution", -- Level 18
            "Reanimation",    -- Level 12
        },
        ['SingleElixir'] = {
            "Sacred Elixir",     -- Level 71
            "Pious Elixir",      -- Level 67
            "Holy Elixir",       -- Level 65
            "Supernal Elixir",   -- Level 62
            "Celestial Elixir",  -- Level 59
            "Celestial Healing", -- Level 44
            "Celestial Health",  -- Level 29
            "Celestial Remedy",  -- Level 19
        },
        ['GroupElixir'] = {
            "Elixir of Divinity", -- Level 70
            "Ethereal Elixir",    -- Level 60
        },
        ['SpellBlessing'] = {
            "Aura of Purpose",       -- Level 71
            "Blessing of Purpose",   -- Level 71
            "Aura of Devotion",      -- Level 69
            "Blessing of Devotion",  -- Level 67
            "Aura of Reverence",     -- Level 64
            "Blessing of Reverence", -- Level 62
            "Blessing of Faith",     -- Level 35
            "Blessing of Piety",     -- Level 15
        },
        -- ['CureAll'] = { -- The single target cures that come after outclass this
        --     "Pure Blood", -- Level 51
        -- },
        ['CurePoison'] = {
            "Antidote",          -- Level 58
            "Eradicate Poison",  -- Level 52
            "Abolish Poison",    -- Level 48
            "Counteract Poison", -- Level 22
            "Cure Poison",       -- Level 1
        },
        ['CureDisease'] = {
            "Eradicate Disease",  -- Level 58
            "Counteract Disease", -- Level 28
            "Cure Disease",       -- Level 4
        },
        ['CureCurse'] = {
            "Eradicate Curse",      -- Level 54
            "Remove Greater Curse", -- Level 54
            "Remove Curse",         -- Level 38
            "Remove Lesser Curse",  -- Level 23
            "Remove Minor Curse",   -- Level 8
        },
        ['CureCorrupt'] = {
            "Cure Corruption", -- Level 70
        },
        ['YaulpSpell'] = {
            "Yaulp VII",         -- Level 69
            "Yaulp VI",          -- Level 65
            "Yaulp V",           -- Level 56, first rank with haste/mana regen. We won't use it before this.
        },
        ['StunTimer6'] = {       -- Timer 6 Stun, Fast Cast, Level 63+ (with ToT Heal 88+)
            "Sound of Zeal",     -- Level 71, works up to level 75
            "Sound of Divinity", -- Level 68, works up to level 70
            "Sound of Might",    -- Level 63
            --Filler before this
            "Tarnation",         -- Level 61, Timer 4, up to Level 65
            "Force",             -- Level 31, No Timer #, up to Level 58
            "Holy Might",        -- Level 16, No Timer #, up to Level 55
        },
        ['StunTimer4'] = {
            "Shock of Wonder", -- Level 66
        },
        ['LowLevelStun'] = {   --Adding a second stun at low levels
            "Stun",            -- Level 2
        },
        ['UndeadNuke'] = {     -- Level 4+
            "Desolate Undead", -- Level 68
            "Destroy Undead",  -- Level 64
            "Exile Undead",    -- Level 55
            "Banish Undead",   -- Level 43
            "Expel Undead",    -- Level 33
            "Dismiss Undead",  -- Level 23
            "Expulse Undead",  -- Level 13
            "Ward Undead",     -- Level 4
        },
        ['MagicNuke'] = {
            "Reproval",               -- Level 71
            "Chromastrike",           -- Level 69
            "Reproach",               -- Level 67
            "Ancient: Chaos Censure", -- Level 65
            "Order",                  -- Level 65
            "Condemnation",           -- Level 62
            "Judgment",               -- Level 56
            "Retribution",            -- Level 44
            "Wrath",                  -- Level 29
            "Smite",                  -- Level 14
            "Furor",                  -- Level 5
            "Strike",                 -- Level 1
        },
        ['QuickNuke'] = {             -- Might specific
            "Verdict of Ascension",   -- Level 69 EQM Custom
            "Verdict of Radiance",    -- Level 65 EQM Custom
            "Verdict of Light",       -- Level 60 EQM Custom
        },
        -- ['HammerPet'] = {
        --     "Unswerving Hammer of Retribution", -- Level 68
        --     "Unswerving Hammer of Faith",       -- Level 54
        -- },
        ['CompleteHeal'] = {
            "Complete Heal",      -- Level 39
        },
        ['PBAENuke'] = {          --This isn't worthwhile before these spells come around.
            "Calamity",           -- Level 69
            "Catastrophe",        -- Level 64
        },
        ['PBAEStun'] = {          --This isn't worthwhile before these spells come around. The stun won't land in many cases (level) but the damage is okay.
            "Silent Dictation",   -- Level 70
            "The Silent Command", -- Level 65
        },
        ['PromisedHeal'] = {
            "Promised Renewal", -- Level 71
        },
    },                          -- end AbilitySets
    ['Helpers']           = {
        -- Artifact of Aegis is Aegis of Vie Rk. I
        PreferAegisSpell = function(self)
            if mq.TLO.Me.Level() < 69 or not mq.TLO.FindItem("=Artifact of Aegis")() then return true end
            local vieBuff = self.ResolvedActionMap['SingleVieBuff']
            return vieBuff and vieBuff() and vieBuff.Name() == "Aegis of Vie" and (vieBuff.RankName.Rank() or 0) >= 2
        end,
        DoRez = function(self, corpseId)
            local rezAction = false
            local rezSpell = Core.GetResolvedActionMapItem('RezSpell')
            local rezStaff = Core.GetResolvedActionMapItem('RezStaff')
            local staffReady = mq.TLO.Me.ItemReady(rezStaff)()
            local okayToRez = Casting.OkayToRez(corpseId)
            local combatState = mq.TLO.Me.CombatState():lower() or "unknown"

            if combatState == "active" or combatState == "resting" then
                if mq.TLO.SpawnCount("pccorpse radius 80 zradius 30")() > 2 and Casting.SpellReady(mq.TLO.Spell("Larger Reviviscence"), true) then
                    rezAction = okayToRez and Casting.UseSpell("Larger Reviviscence", corpseId, true, true)
                end
            end

            if combatState == "combat" and Config:GetSetting('DoBattleRez') and Core.OkayToNotHeal() then
                -- legendary staff only has a 1.5s cast, use it first in combat
                if rezStaff == "Legendary Fabled Staff of Forbidden Rites" and staffReady then
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif staffReady then -- the lower 2 staves still cast faster or as fast as water sprinkler
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("Water Sprinkler of Nem Ankh", corpseId)
                else
                    Logger.log_debug("DoRez: No fast rez options available in combat for %s.", mq.TLO.Spawn(corpseId).CleanName() or "Unknown")
                end
            elseif combatState ~= "combat" then
                if Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif staffReady then
                    rezAction = okayToRez and Casting.UseItem(rezStaff, corpseId)
                elseif mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("=Water Sprinkler of Nem Ankh", corpseId)
                elseif not Casting.CanUseAA("Blessing of Resurrection") and (combatState == "active" or combatState == "resting") then
                    -- ^ if we have BoR, just wait for it, rather than taking the time to memorize a spell
                    if Casting.SpellReady(rezSpell, true) then
                        rezAction = okayToRez and Casting.UseSpell(rezSpell.RankName(), corpseId, true, true)
                    end
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
            name = 'GroupHeal',
            state = 1,
            steps = 1,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHeal',
            state = 1,
            steps = 1,
            cond = function(self, target)
                return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target)
            end,
        },
        {
            name = 'MainHeal',
            state = 1,
            steps = 1,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
    },
    ['HealRotations']     = {
        ['GroupHeal'] = {
            {
                name = "Beacon of Life",
                type = "AA",
            },
            {
                name = "Celestial Regeneration",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigHealsNeeded(target) -- if multiples are hurt with at least one needing big heals
                end,
                pre_activate = function(self)
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
                end,
            },
            {
                name = "GroupElixir",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupElixir') or (target.PctHPs() or 999) <= Config:GetSetting('BigHealPoint') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Exquisite Benediction",
                type = "AA",
                cond = function(self)
                    return Casting.BurnCheck()
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
            {
                name = "GroupHeal",
                type = "Spell",
            },
        },
        ['BigHeal'] = {
            {
                name = "Divine Arbitration",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Burst of Life",
                type = "AA",
            },
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Timer2HealItem",
                type = "Item",
            },
            { -- keep this for big heals, unless we are critically low on mana
                name = "Braided Kirin Mane",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Braided Kirin Mane")() end,
            },
            { --This entry is for RemedyHeal until we learn a Renewal
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "Renewal", "RemedyHeal", })
                end,
                type = "Spell",
            },
            {
                name = "Focused Celestial Regeneration",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Blessing of Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return target.ID() == (mq.TLO.Target.AggroHolder.ID() and not Targeting.TargetIsATank(target))
                end,
            },
            { --The stuff above is down, lets make mainhealpoint faster.
                name = "Celestial Rapidity",
                type = "AA",
            },
            { --if we hit this we need spells back ASAP
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['MainHeal'] = {
            { -- keep this for big heals, unless we are critically low on mana
                name = "Timer2HealItem",
                type = "Item",
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            { -- keep this for big heals, unless we are critically low on mana
                name = "Braided Kirin Mane",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Braided Kirin Mane")() end,
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
            {
                name = "SingleElixir",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSingleElixir') end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "CompleteHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting("DoCompleteHeal") or not Targeting.TargetIsATank(target) then return false end
                    return (target.PctHPs() or 999) <= Config:GetSetting('CompleteHealPct')
                end,
            },
            {
                name = "HealingLight",
                type = "Spell",
                cond = function(self, spell, target)
                    return not (Config:GetSetting("DoCompleteHeal") and Targeting.TargetIsATank(target))
                end,
            },
        },
    },
    ['Charm']             = {
        ['Assist'] = {
            { name = "LowLevelStun", type = "Spell", cond = function(self, spell, target) return Targeting.TargetNotStunned() end, },
            { name = "StunTimer6",   type = "Spell", cond = function(self, spell, target) return Targeting.TargetNotStunned() end, },
            { name = "PBAEStun",     type = "Spell", cond = function(self, spell, target) return Targeting.TargetNotStunned() and Targeting.InSpellRange(spell, target) end, },
        },
    },
    ['RotationOrder']     = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Spells that should be checked on group members
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Core.CombatActionsCheck() and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'ManaRestore',
            timer = 30,
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoManaRestore') and (Casting.CanUseAA("Veturika's Perseverance") or Casting.CanUseAA("Quiet Miracle")) end,
            targetId = function(self) return { Combat.FindWorstHurtMana(Config:GetSetting('ManaRestorePct')), } end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(AE)',
            state = 1,
            steps = 1,
            load_cond = function(self)
                return (Config:GetSetting('DoPBAENuke') and self:GetResolvedActionMapItem('PBAENuke')) or
                    (Config:GetSetting('DoPBAEStun') and self:GetResolvedActionMapItem('PBAEStun'))
            end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck() and Config:GetSetting('DoAEDamage') and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Combat Buffs',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']         = {
        ['ManaRestore'] = {
            {
                name = "Veturika's Perseverance",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target) and Casting.AmIBuffable()
                end,
            },
            {
                name = "Quiet Miracle",
                type = "AA",
                cond = function(self, aaName, target)
                    if Targeting.TargetIsMyself(target) then return false end
                    local rezSearch = string.format("pccorpse %s radius 100 zradius 50", target.DisplayName())
                    return mq.TLO.SpawnCount(rezSearch)() == 0
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Celestial Hammer",
                type = "AA",
            },
            {
                name = "Flurry of Life",
                type = "AA",
            },
            {
                name = "Healing Frenzy",
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Divine Avatar",
                type = "AA",
                cond = function(self)
                    return Config:GetSetting('DoMelee') and mq.TLO.Me.Combat()
                end,
            },
            { --homework: This is a defensive proc, likely need to add elsewhere
                name = "Divine Retribution",
                type = "AA",
                cond = function(self)
                    return Config:GetSetting('DoMelee') and mq.TLO.Me.Combat()
                end,
            },
            {
                name = "Battle Frenzy",
                type = "AA",
            },
            {
                name = "Improved Twincast",
                type = "AA",
            },
            { --homework: Check if this is necessary (does not exceed 50% spell haste cap)
                name = "Celestial Rapidity",
                type = "AA",
            },
        },
        ['Combat Buffs'] = {
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Aegis",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('VieBuffMode') > 2 and not self.Helpers.PreferAegisSpell(self) end,
                cond = function(self, itemName, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffItemCheck(itemName, target) and Casting.AddedBuffCheck(43037, target) -- Bulwark of the Pegasus
                end,
            },
            {
                name = "SingleVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('VieBuffMode') > 2 and self.Helpers.PreferAegisSpell(self) end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.AddedBuffCheck(43037, target) -- Bulwark of the Pegasus
                end,
            },
        },
        ['DPS'] = {
            {
                name = "GroupElixir",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoGroupElixir') end,
                cond = function(self, spell)
                    if not Config:GetSetting('GroupElixirUptime') then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 6
                end,
            },
            {
                name = "Yaulp",
                type = "AA",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoYaulp') and Casting.CanUseAA("Yaulp") end,
                cond = function(self, aaName)
                    return not mq.TLO.Me.Mount() and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "YaulpSpell",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoYaulp') and not Casting.CanUseAA("Yaulp") end,
                cond = function(self, spell)
                    return not mq.TLO.Me.Mount() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTimer6Stun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) -- no stun checks because these are Recourse of Life procs as well
                end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTimer4Stun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) -- no stun checks because these are Recourse of Life procs as well
                end,
            },
            {
                name = "LowLevelStun",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStun') end,
                cond = function(self, spell, target)
                    local targetLevel = Targeting.GetAutoTargetLevel()
                    if targetLevel == 0 or targetLevel > 55 then return false end
                    return Casting.HaveManaToNuke(true) and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Turn Undead",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead") and Targeting.AggroCheckOkay()
                end,
            },
            {
                name = "QuickNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoQuickNuke') end,
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "UndeadNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoUndeadNuke') end,
                cond = function(self, aaName, target)
                    if not Targeting.TargetBodyIs(target, "Undead") then return false end
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoMagicNuke') end,
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Config:GetSetting('DoMelee') and Core.ShieldEquipped()
                end,
            },
        },
        ['DPS(AE)'] = {
            {
                name = "PBAEStun",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAEStun') end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "PBAENuke",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoPBAENuke') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true) and Targeting.InSpellRange(spell, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "SelfHPBuff",
                type = "Spell",
                cond = function(self, spell)
                    if Config:GetSetting('AegoSymbol') == 3 then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Spirit Mastery",
                type = "AA",
                pre_activate = function(self, aaName) --remove the old aura if we just purchased the AA, otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName("Aura of Pious Divinity") then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, aaName)
                    return not Casting.AuraActiveByName("Aura of Pious Divinity")
                end,
            },
            {
                name = "AbsorbAura",
                type = "Spell",
                pre_activate = function(self, spell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(spell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, spell)
                    if Casting.CanUseAA('Spirit Mastery') then return false end
                    return not Casting.AuraActiveByName(spell.BaseName()) and Config:GetSetting('UseAura') == 1
                end,
            },
            {
                name = "HPAura",
                type = "Spell",
                pre_activate = function(self, spell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(spell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, spell)
                    if Casting.CanUseAA('Spirit Mastery') then return false end
                    return not Casting.AuraActiveByName(spell.BaseName()) and Config:GetSetting('UseAura') == 2
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Divine Guardian",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "AegoBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AegoSymbol') <= 2 end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name_func = function(self)
                    if mq.TLO.FindItem("=Mythical Armband of Elushar")() then return "Mythical Armband of Elushar" end
                    if mq.TLO.FindItem("=Legendary Armband of Mithaniel")() then return "Legendary Armband of Mithaniel" end
                    return "Symbol Buff Clicky"
                end,
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and (mq.TLO.FindItem("=Mythical Armband of Elushar")() or mq.TLO.FindItem("=Legendary Armband of Mithaniel")()) end,
                cond = function(self, itemName, target)
                    if Config:GetSetting('AegoSymbol') == (1 or 4) then return false end
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "GroupSymbolBuff",
                type = "Spell",
                load_cond = function() return mq.TLO.Me.Level() < 68 or not mq.TLO.FindItem("=Legendary Armband of Mithaniel")() end,
                cond = function(self, spell, target)
                    if Config:GetSetting('AegoSymbol') == (1 or 4) or ((spell.TargetType() or ""):lower() == "single" and target.ID() ~= Core.GetMainAssistId()) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SpellBlessing",
                type = "Spell",
                cond = function(self, spell, target)
                    if mq.TLO.Me.Level() > 91 then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ACBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoACBuff') end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Aegis",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('VieBuffMode') > 1 and not self.Helpers.PreferAegisSpell(self) end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target) and Casting.AddedBuffCheck(43037, target) -- Bulwark of the Pegasus
                end,
            },
            {
                name = "SingleVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('VieBuffMode') > 1 and self.Helpers.PreferAegisSpell(self) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target) and Casting.AddedBuffCheck(43037, target) -- Bulwark of the Pegasus
                end,
            },
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
    },
    -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
    -- The list name ("Default" in the list below) is abitrary, it is simply what shows up in the UI when this spell list is loaded.
    -- Virtually any helper function or TLO can be used as a condition. Example: Mode or level-based lists.
    -- The first list without conditions or whose conditions returns true will be loaded, all subsequent lists will be ignored.
    -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
    -- Loadout checks (such as scribing a spell or using the "Rescan Loadout" or "Reload Spells" buttons) will re-check these lists and may load a different set if things have changed.
    ['SpellList']         = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "HealingLight",  cond = function(self) return not Config:GetSetting('DoCompleteHeal') or not Core.GetResolvedActionMapItem("CompleteHeal") end, },
                { name = "CompleteHeal",  cond = function(self) return Config:GetSetting('DoCompleteHeal') end, },
                { name = "Renewal", },
                { name = "RemedyHeal",    cond = function(self) return not Core.GetResolvedActionMapItem("Renewal") end, },
                { name = "GroupHeal", },
                { name = "SingleElixir",  cond = function(self) return Config:GetSetting('DoSingleElixir') end, },
                { name = "GroupElixir",   cond = function(self) return Config:GetSetting('DoGroupElixir') end, },
                { name = "CurePoison",    cond = function(self) return Config:GetSetting('KeepPoisonMemmed') end, },
                { name = "CureDisease",   cond = function(self) return Config:GetSetting('KeepDiseaseMemmed') end, },
                { name = "CureCurse",     cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "CureCorrupt",   cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
                { name = "DivineBuff",    cond = function(self) return Config:GetSetting('DoDivineBuff') end, },
                { name = "YaulpSpell",    cond = function(self) return Config:GetSetting('DoYaulp') and not Casting.CanUseAA("Yaulp") end, },
                { name = "SingleVieBuff", cond = function(self) return Config:GetSetting('VieBuffMode') > 1 and self.Helpers.PreferAegisSpell(self) end, },
                { name = "StunTimer6",    cond = function(self) return Config:GetSetting('DoTimer6Stun') end, },
                { name = "StunTimer4",    cond = function(self) return Config:GetSetting('DoTimer4Stun') end, },
                { name = "LowLevelStun",  cond = function(self) return Config:GetSetting('DoLLStun') and mq.TLO.Me.Level() < 59 end, },
                { name = "QuickNuke",     cond = function(self) return Config:GetSetting('DoQuickNuke') end, },
                { name = "MagicNuke",     cond = function(self) return Config:GetSetting('DoMagicNuke') end, },
                { name = "PBAEStun",      cond = function(self) return Config:GetSetting('DoPBAEStun') end, },
                { name = "PBAENuke",      cond = function(self) return Config:GetSetting('DoPBAENuke') end, },
                { name = "UndeadNuke",    cond = function(self) return Config:GetSetting('DoUndeadNuke') end, },
                { name = "PromisedHeal", }, -- filler, for manual use only, the config does not use it automatically
                { name = "RezSpell",      cond = function(self) return not Casting.CanUseAA('Blessing of Resurrection') end, },
            },
        },
    },
    ['DefaultConfig']     = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Clerics currently only have one Mode. This may change in the future.",
        },
        --Buffs
        ['AegoSymbol']        = {
            DisplayName = "Aego/Symbol Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip =
            "Choose whether to use the Aegolism or Symbol Line of HP Buffs.\nPlease note using both is supported for party members who block buffs, but these buffs do not stack once we transition from using a HP Type-One buff in place of Aegolism.",
            Type = "Combo",
            ComboOptions = { 'Aegolism', 'Both (See Tooltip!)', 'Symbol', 'None', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['DoACBuff']          = {
            DisplayName = "Use AC Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip =
                "Use your single-slot AC Buff on the Main Assist. USE CASES:\n" ..
                "You have Aegolism selected and are below level 40 (We are still using a HP Type One buff).\n" ..
                "You have Symbol selected and don't have someone else providing a Type One buff.\n" ..
                "Leaving this on in other cases is not likely to cause issue, but may cause unnecessary buff checking.",
            Default = false,
        },
        ['VieBuffMode']       = {
            DisplayName = "Use Vie Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your Melee Damage absorb (Vie) line.",
            Type = "Combo",
            ComboOptions = { 'None', 'Downtime Only', 'Downtime + Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['UseAura']           = {
            DisplayName = "Aura Spell Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Select the Aura to be used, prior to purchasing the Spirit Mastery AA.",
            Type = "Combo",
            ComboOptions = { 'Absorb', 'HP', 'None', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoDivineBuff']      = {
            DisplayName = "Do Divine Intervetion",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your Divine Intervention line (death save) on the MA.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },

        --Combat
        ['DoTimer6Stun']      = {
            DisplayName = "Timer 6 Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Use the Timer 6 Stun (\"Sound of\" Line).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTimer4Stun']      = {
            DisplayName = "Timer 4 Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 102,
            Tooltip = "Use the Timer 4 Stun (Shock of Wonder).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoLLStun']          = {
            DisplayName = "Low Level Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 103,
            Tooltip = "Use the Level 2 \"Stun\" spell, as long as it is level-appropriate (works on targets up to Level 55).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why is a Cleric stunning? It should be healing!?",
            Answer =
            "At low levels, Cleric stuns are often more efficient than healing the damage an non-stunned mob would cause.",
        },
        ['DoUndeadNuke']      = {
            DisplayName = "Do Undead Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use the Undead nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoMagicNuke']       = {
            DisplayName = "Do Magic Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use the Magic nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoQuickNuke']       = {
            DisplayName = "Do Verdict Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Use the Verdict Quicknuke line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        -- Heals and Cures
        ['DoCompleteHeal']    = {
            DisplayName = "Use Complete Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip = "Use Complete Heal on the MA (instead of the healing Light line).",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
            FAQ = "Does RGMercs support Complete Heal Chains (CHC)?",
            Answer =
            "No, it does not. If this is important to you, there are resources on RedGuides that can handle it! You could, though, consider staggering Complete Heal percentages to break up CH usage amongst multiple clerics.",
        },
        ['CompleteHealPct']   = {
            DisplayName = "Complete Heal Pct",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Tooltip = "Pct we will use Complete Heal on the MA.",
            Default = 80,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
            Warning = function()
                if Config:GetSetting('CompleteHealPct') > Config:GetSetting('MaxHealPoint') then
                    return true, "Warning: CompleteHealPct exceeds MaxHealPoint - we will not check if heals are needed until health is under MaxHealPoint."
                end
                return false, ""
            end,
        },
        ['DoSingleElixir']    = {
            DisplayName = "Single Elixir",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use your single-target Elixir Line.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoGroupElixir']     = {
            DisplayName = "Group Elixir",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your group-wide Elixir Line.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['GroupElixirUptime'] = {
            DisplayName = "Group Elixir Uptime",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 103,
            Tooltip = "In combat, attempt to keep full uptime on your Group Elixir. Note: There are scenarios where single elixirs could interfere with uptime.",
            Default = true,
            ConfigType = "Advanced",
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
        ['GroupHealAsCure']   = {
            DisplayName = "Use Group Heal to Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 104,
            Tooltip = "If Word of Replenishment or Vivification are available, use these to cure instead of individual cure spells. \n" ..
                "Please note that we will prioritize single target cures if you have selected to keep them memmed above (due to the counter disparity).",
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoPBAENuke']        = {
            DisplayName = "Use PBAE Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Magic PB AE Spells . **WILL BREAK MEZ**",
            Default = false,
        },
        ['DoPBAEStun']        = {
            DisplayName = "Use PBAE Stun",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip =
            "**WILL BREAK MEZ** Use your Magic PB AE Stun Spells . **WILL BREAK MEZ**",
            Default = false,
        },

        --Utility
        ['DoManaRestore']     = {
            DisplayName = "Use Mana Restore AAs",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Use Veturika's Prescence (on self) or Quiet Miracle (on others) at critically low mana.",
            RequiresLoadoutChange = true, -- used as a load condition
            Default = true,
            ConfigType = "Advanced",
        },
        ['ManaRestorePct']    = {
            DisplayName = "Mana Restore Pct",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "Min Mana to use restore AA.",
            Default = 10,
            Min = 1,
            Max = 99,
            ConfigType = "Advanced",
        },
        ['DoYaulp']           = {
            DisplayName = "Use Yaulp",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use your Yaulp (AA or spell line) to help maintain your mana and buff your melee ability.",
            Default = true,
            FAQ = "Why am I using Yaulp? Clerics are not supposed to melee!",
            Answer = "The Yaulp spells we use also contain a mana regen component. You can disable this behavior on the Utility tab in the Class Options.",
        },
        ['HealPriority']      = {
            DisplayName = "Healing Priority",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Type = "Combo",
            ComboOptions = { 'Ignore', 'Big Heal Point', 'Main Heal Point', },
            Default = 3,
            Min = 1,
            Max = 3,
            Tooltip = "When to yield offensive rotations for healing:\n1 - Ignore (never)\n2 - Big Heal Point\n3 - Main Heal Point",
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

return _ClassConfig
