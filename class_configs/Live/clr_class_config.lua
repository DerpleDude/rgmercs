local mq           = require('mq')
local Combat       = require('utils.combat')
local Config       = require('utils.config')
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version              = "2.1 - Live",
    _author               = "Algar, Derple",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },
    ['Modes']             = {
        'Heal',
    },
    ['Cures']             = {
        GetCureSpells = function(self) --To do at some point: Consider options or features for group vs single target curing
            --(re)initialize the table for loadout changes
            self.TempSettings.CureSpells = {}

            -- Choose whether we should be trying to resolve the groupheal based on our settings and whether it cures at its level
            local ghealSpell = Core.GetResolvedActionMapItem('GroupHealCure')
            local groupHeal = (Config:GetSetting('KeepCureMemmed') == 3 and (ghealSpell and ghealSpell.Level() or 0) >= 70) and "GroupHeal"

            -- Find the map for each cure spell we need, given availability of groupheal, groupcure. fallback to curespell
            -- Curse is convoluted: If Keepmemmed, always use cure, if not, use groupheal if available and fallback to cure
            local neededCures = {
                ['Poison'] = Casting.GetFirstMapItem({ groupHeal, "CureAll", "CurePoison", }),
                ['Disease'] = Casting.GetFirstMapItem({ groupHeal, "CureAll", "CureDisease", }),
                ['Curse'] = Casting.GetFirstMapItem({ groupHeal, "CureAll", "CureCurse", }),
                ['Corruption'] = 'CureCorrupt',
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
    ['ItemSets']          = {
        ['Epic'] = {
            "Harmony of the Soul",
            "Aegis of Superior Divinity",
        },
    },
    ['AbilitySets']       = {
        ['WardBuff'] = {          -- Level 97+
            "Ward of Virtue VII", -- 127
            "Ward of Certitude",
            "Ward of Surety",
            "Ward of Assurance",
            "Ward of Righteousness",
            "Ward of Persistence",
            "Ward of Commitment",
        },
        ['HealingLight'] = {
            "Eminent Light", -- Level 128
            "Minor Healing",
            "Light Healing",
            "Healing",
            "Greater Healing",
            "Superior Healing",
            "Healing Light",
            "Divine Light",
            "Ethereal Light",
            "Supernal Light",
            "Holy Light",
            "Pious Light",
            "Ancient: Hallowed Light",
            "Sacred Light",
            "Solemn Light",
            "Devout Light",
            "Earnest Light",
            "Zealous Light",
            "Reverent Light",
            "Ardent Light",
            "Merciful Light",
            "Sincere Light",
            "Fervent Light",
            "Avowed Light",
        },
        ['RemedyHeal'] = {     -- Not great until 96/RoF (Graceful)
            -- "Remedy", No place to slot this, Ethereal used as a fallback at some level ranges
            "Holy Remedy XIV", -- 126
            "Ethereal Remedy",
            "Supernal Remedy",
            "Pious Remedy",
            "Sacred Remedy",
            "Solemn Remedy",
            "Devout Remedy",
            "Earnest Remedy",
            "Faithful Remedy",
            "Graceful Remedy",
            "Spiritual Remedy",
            "Merciful Remedy",
            "Sincere Remedy",
            "Guileless Remedy",
            "Avowed Remedy",
        },
        ['RemedyHeal2'] = {
            "Holy Remedy XIV", -- 126
            "Graceful Remedy",
            "Spiritual Remedy",
            "Merciful Remedy",
            "Sincere Remedy",
            "Guileless Remedy",
            "Avowed Remedy",
        },
        ['Renewal'] = {               -- Level 70 +, large heal, slower cast
            "Desperate Renewal XIII", -- 130
            "Desperate Renewal",
            "Frantic Renewal",
            "Frenetic Renewal",
            "Frenzied Renewal",
            "Fervent Renewal",
            "Fraught Renewal",
            "Furial Renewal",
            "Dire Renewal",
            "Determined Renewal",
            "Heroic Renewal",
        },
        ['Renewal2'] = { -- Level 70 +, large heal, slower cast
            "Desperate Renewal",
            "Frantic Renewal",
            "Frenetic Renewal",
            "Frenzied Renewal",
            "Fervent Renewal",
            "Fraught Renewal",
            "Furial Renewal",
            "Dire Renewal",
            "Determined Renewal",
            "Heroic Renewal",
        },
        ['Renewal3'] = { -- Level 70 +, large heal, slower cast
            "Desperate Renewal",
            "Frantic Renewal",
            "Frenetic Renewal",
            "Frenzied Renewal",
            "Fervent Renewal",
            "Fraught Renewal",
            "Furial Renewal",
            "Dire Renewal",
            "Determined Renewal",
            "Heroic Renewal",
        },
        ['DichoHeal'] = {
            "Undying Life",
            "Dissident Blessing",
            "Composite Blessing",
            "Ecliptic Blessing",
            "Reciprocal Blessing",
        },
        ['GroupFastHeal'] = {        -- Level 98
            "Syllable of Wellbeing", -- 128
            "Syllable of Acceptance",
            "Syllable of Convalescence",
            "Syllable of Mending",
            "Syllable of Soothing",
            "Syllable of Invigoration",
            "Syllable of Renewal",
        },
        ['GroupHealCure'] = {
            "Word of Replenishment", -- 129
            "Word of Restoration",   -- Poi/Dis
            "Word of Replenishment", -- Poi/Dis/Curse
            "Word of Vivification",
            "Word of Vivacity",
            "Word of Recovery",
            "Word of Resurgence",
            "Word of Rehabilitation",
            "Word of Reformation",
            "Word of Greater Reformation",
            "Word of Greater Restoration",
            "Word of Greater Replenishment",
            "Word of Greater Rejuvenation",
            "Word of Greater Vivification",
        },
        ['GroupHealNoCure'] = {
            -----Group Heals No Cure Slot 5
            "Word of Wellbeing", -- 126
            "Word of Health",
            "Word of Healing",
            "Word of Vigor",
            "Word of Restoration", -- No good NoCure in these level ranges using w/Cure... Note Word of Redemption omitted (12sec cast)
            "Word of Replenishment",
            "Word of Vivification",
            "Word of Vivacity",
            "Word of Recovery",
            "Word of Awakening", --86, back to no cures
            "Word of Recuperation",
            "Word of Renewal",
            "Word of Convalescence",
            "Word of Mending",
            "Word of Soothing",
            "Word of Redress",
            "Word of Acceptance",
        },
        ['HealNuke'] = {
            -- Heal Tank and Nuke Tanks Target -- Intervention Lines
            "Eminent Intervention", -- Level 128
            "Holy Intervention",
            "Celestial Intervention",
            "Elysian Intervention",
            "Virtuous Intervention",
            "Mystical Intervention",
            "Merciful Intervention",
            "Sincere Intervention",
            "Atoned Intervention",
            "Avowed Intervention",
        },
        ['HealNuke2'] = {
            -- Heal Tank and Nuke Tanks Target -- Intervention Lines
            "Eminent Intervention", -- Level 128
            "Holy Intervention",
            "Celestial Intervention",
            "Elysian Intervention",
            "Virtuous Intervention",
            "Mystical Intervention",
            "Merciful Intervention",
            "Sincere Intervention",
            "Atoned Intervention",
            "Avowed Intervention",
        },
        ['HealNuke3'] = {
            -- Heal Tank and Nuke Tanks Target -- Intervention Lines
            "Eminent Intervention", -- Level 128
            "Holy Intervention",
            "Celestial Intervention",
            "Elysian Intervention",
            "Virtuous Intervention",
            "Mystical Intervention",
            "Merciful Intervention",
            "Sincere Intervention",
            "Atoned Intervention",
            "Avowed Intervention",
        },
        ['NukeHeal'] = {
            -- Nuke Target and Heal Tank -  Dps Heals
            "Eminent Contravention", -- 130
            "Holy Contravention",
            "Celestial Contravention",
            "Elysian Contravention",
            "Virtuous Contravention",
            "Ardent Contravention",
            "Merciful Contravention",
            "Sincere Contravention",
            "Divine Contravention",
            "Avowed Contravention",
        },
        ['NukeHeal2'] = {
            -- Nuke Target and Heal Tank -  Dps Heals
            "Eminent Contravention", -- 130
            "Holy Contravention",
            "Celestial Contravention",
            "Elysian Contravention",
            "Virtuous Contravention",
            "Ardent Contravention",
            "Merciful Contravention",
            "Sincere Contravention",
            "Divine Contravention",
            "Avowed Contravention",
        },
        ['NukeHeal3'] = {
            -- Nuke Target and Heal Tank -  Dps Heals
            "Eminent Contravention", -- 130
            "Holy Contravention",
            "Celestial Contravention",
            "Elysian Contravention",
            "Virtuous Contravention",
            "Ardent Contravention",
            "Merciful Contravention",
            "Sincere Contravention",
            "Divine Contravention",
            "Avowed Contravention",
        },
        ['ReverseDS'] = {
            -- Reverse Damage Shield Proc (LVL >=85) -- Ignoring the Mark Line
            "Erud's Retort",
            "Fintar's Retort",
            "Galvos' Retort",
            "Olsif's Retort",
            "Vicarum's Retort",
            "Curate's Retort",
            "Jorlleag's Retort",
            "Axoeviq's Retort",
            "Hazuri's Retort",
        },
        ['SelfHPBuff'] = {
            --Self Buff for Mana Regen and armor
            "Armor of the Eminent", -- 130
            "Armor of Protection",
            "Blessed Armor of the Risen",
            "Ancient: High Priest's Bulwark",
            "Armor of the Zealot",
            "Armor of the Pious",
            "Armor of the Sacred",
            "Armor of the Solemn",
            "Armor of the Devout",
            "Armor of the Earnest",
            "Armor of the Zealous",
            "Armor of the Reverent",
            "Armor of the Ardent",
            "Armor of the Merciful",
            "Armor of Sincerity",
            "Armor of Penance",
            "Armor of the Avowed",
        },
        ['GroupHealProcBuff'] = {
            ----Self buff casts group heal on AE spell damage
            "Divine Consequence",
            "Divine Reaction",
            "Divine Response",
            "Divine Contingency",
            "Divine Rejoinder",
        },
        ['AegoBuff'] = {
            ----Use HP Type one until Temperance at 40... Group Buff at 45 (Blessing of Temperance)
            "Unified Hand of Aegolism XV", -- Level 130
            "Courage",
            "Center",
            "Daring",
            "Bravery",
            "Valor",
            "Temperance",
            "Blessing of Temperance",
            "Aegolism",
            "Ancient: Gift of Aegolism",
            "Blessing of Aegolism",
            "Hand of Virtue",
            "Hand of Conviction",
            "Hand of Tenacity",
            "Hand Of Temerity",
            "Hand of Gallantry",
            "Hand of Reliance",
            "Unified Hand of Credence",
            "Unified Hand of Certitude",
            "Unified Hand of Surety",
            "Unified Hand of Assurance",
            "Unified Hand of Righteousness",
            "Unified Hand of Persistence",
            "Unified Hand of Infallibility",
        },
        ['ACBuff'] = { --Sometimes single, sometimes group, used on tank before Aego or until it is rolled into Unified (Symbol)
            "Order of the Earnest",
            "Ward of the Earnest",
            "Order of the Devout",
            "Ward of the Devout",
            "Order of the Resolute",
            "Ward of the Resolute",
            "Ward of the Dauntless",
            "Ward of Valliance",
            "Ward of Gallantry",
            "Bulwark of Faith",
            "Shield of Words",
            "Armor of Faith",
            "Guard",
            "Spirit Armor",
            "Holy Armor",
        },
        ['ShiningBuff'] = {
            --Tank Buff Traditionally Shining Series of Buffs
            "Shining Rampart IX",
            "Shining Rampart",
            "Shining Armor",
            "Shining Bastion",
            "Shining Bulwark",
            "Shining Fortress",
            "Shining Aegis",
            "Shining Fortitude",
            "Shining Steel",
        },
        ['SingleVieBuff'] = { -- Level 20-73 We don't use this once we have the group version
            "Aegis of Vie",
            "Panoply of Vie",
            "Bulwark of Vie",
            "Protection of Vie",
            "Guard of Vie",
            "Ward of Vie",
        },
        ['GroupVieBuff'] = {
            "Rallied Bulwark of Vie", -- 130
            "Rallied Aegis of Vie",
            "Rallied Shield of Vie",
            "Rallied Palladium of Vie",
            "Rallied Rampart of Vie",
            "Rallied Armor of Vie",
            "Rallied Bastion of Vie",
            "Rallied Greater Ward of Vie",
            "Rallied Greater Guard of Vie",
            "Rallied Greater Protection of Vie",
            "Rallied Greater Aegis of Vie",
        },
        ['GroupSymbolBuff'] = {
            ----Group Symbols
            "Symbol of Transal",
            "Symbol of Ryltan",
            "Symbol of Pinzarn",
            "Symbol of Naltron",
            "Symbol of Marzin",
            "Naltron's Mark",
            "Marzin's Mark",
            "Kazad's Mark",
            "Balikor's Mark",
            "Elushar's Mark",
            "Kaerra's Mark",
            "Darianna's Mark",
            "Ealdun's Mark",
            "Unified Hand of the Triumvirate",
            "Unified Hand of Gezat",
            "Unified Hand of Nonia",
            "Unified Hand of Emra",
            "Unified Hand of Jorlleag",
            "Unified Hand of Assurance",
            "Unified Hand of the Diabo",
            "Unified Hand of Helmsbane",
        },
        ['AbsorbAura'] = {
            ----Aura Buffs - Aura Name is seperate than the buff name
            "Aura of the Pious",
            "Aura of the Zealot",
            "Aura of the Reverent",
            "Aura of the Persistent",
        },
        ['HPAura'] = {
            ---- Aura Buff 2 - Aura Name is the same as the buff name
            "Bastion of Divinity",
            "Circle of Divinity",
            "Aura of Divinity",
        },
        ['DivineBuff'] = {
            --Divine Buffs REQUIRES extra spell slot because of the 90s recast
            "Divine Interstition", -- 127
            "Death Pact",
            "Divine Intervention",
            "Divine Intercession",
            "Divine Invocation",
            "Divine Interposition",
            "Divine Indemnification",
            "Divine Imposition",
            "Divine Intermediation",
            "Divine Interference",
        },
        ['TwinHealNuke'] = {
            "Unyielding Denunciation", -- 129
            "Glorious Denunciation",
            "Glorious Censure",
            "Glorious Admonition",
            "Glorious Rebuke",
            "Glorious Judgment",
            "Unyielding Judgment",
            "Unyielding Censure",
            "Unyielding Rebuke",
            "Unyielding Admonition",
        },
        ['RezSpell'] = {
            "Reviviscence",
            "Resurrection",
            "Restoration",
            "Resuscitate",
            "Renewal",
            "Revive",
            "Reparation",
            "Reconstitution",
            "Reanimation",
        },
        ['AERezSpell'] = {
            "Superior Reviviscence",
            "Eminent Reviviscence",
            "Greater Reviviscence",
            "Larger Reviviscence",
        },
        ['ClutchHeal'] = {
            -- 11th-17th Rejuv Spell Line Clutch Heals Require Life below 35-45% to cast
            "Twentieth Dictum", -- 127
            "Eleventh-Hour",
            "Twelfth Night",
            "Thirteenth Salve",
            "Fourteenth Catalyst",
            "Fifteenth Emblem",
            "Sixteenth Serenity",
            "Seventeenth Rejuvenation",
            "Eighteenth Rejuvenation",
            "Nineteenth Commandment",
        },
        ['GroupInfusionBuff'] = {
            -- Hand of Infusion Line
            "Hand of Faithful Infusion",
            "Hand of Graceful Infusion",
            "Hand of Merciful Infusion",
            "Hand of Sincere Infusion",
            "Hand of Unyielding Infusion",
            "Hand of Avowed Infusion",
        },
        ['SingleElixir'] = {
            "Eminent Elixir",   -- 127
            "Celestial Remedy", -- Level 19
            "Celestial Health",
            "Celestial Healing",
            "Celestial Elixir",
            "Supernal Elixir",
            "Holy Elixir",
            "Pious Elixir",
            "Sacred Elixir",
            "Solemn Elixir",
            "Devout Elixir",
            "Earnest Elixir",
        },
        ['GroupElixir'] = {
            -- Group Hot Line - Elixirs No Cure
            "Elixir of Absolution", -- 130
            "Ethereal Elixir",      -- Level 59
            "Elixir of Divinity",
            "Elixir of Redemption",
            "Elixir of Atonement",
            "Elixir of Expiation",
            "Elixir of the Ardent",
            "Elixir of the Beneficent",
            "Elixir of the Acquittal",
            "Elixir of the Seas",
            "Elixir of Wulthan",
            "Elixir of Transcendence",
            "Elixir of Benevolence",
            "Elixir of Realization",
        },
        ['GroupAcquittal'] = {
            -- Group Hot Line Cure + Hot 99+
            "Eminent Acquittal", -- 129
            "Cleansing Acquittal",
            "Ardent Acquittal",
            "Merciful Acquittal",
            "Sincere Acquittal",
            "Devout Acquittal",
            "Avowed Acquittal",
        },
        ['SpellBlessing'] = {
            -- Spell haste Blessings 15-92, defunct at 95 due to Unifieds.
            -- -- Do not add future version unless you have verified that they are not simply Symbol/Aego Unified triggers.
            "Blessing of Piety",
            "Blessing of Faith",
            "Blessing of Reverence",
            "Aura of Reverence",
            "Blessing of Devotion",
            "Aura of Devotion",
            "Blessing of Purpose",
            "Aura of Purpose",
            "Blessing of Resolve",
            "Aura of Resolve",
            "Blessing of Loyalty",
            "Aura of Loyalty",
            "Blessing of Will",
            "Hand of Will",
        },
        ['CureAll'] = {
            "Sanctified Blood",
            "Expurgated Blood",
            "Unblemished Blood",
            "Cleansed Blood",
            "Perfected Blood",
            "Purged Blood",   -- does not cure corruption
            "Purified Blood", -- does not cure curse, 5 level gap where we will use this without curing curse, but AA should cover
            -- "Pure Blood", --Much better single cures occur after this one
        },
        ['CureCorrupt'] = {
            "Purge Corruption",
            "Extricate Corruption",
            "Nullify Corruption",
            "Abrogate Corruption",
            "Eradicate Corruption",
            "Dissolve Corruption", -- group from here up
            "Pristine Blood",      -- single target from here down
            "Abolish Corruption",
            "Vitiate Corruption",
            "Expunge Corruption",
        },
        ['CurePoison'] = {
            "Antidote",
            "Eradicate Poison",
            "Abolish Poison",
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
        ['YaulpSpell'] = {
            "Yaulp V", -- Level 56, first rank with haste/mana regen
            "Yaulp VI",
            "Yaulp VII",
            "Yaulp VIII",
            "Yaulp IX",           -- Level 76, AA starts at 75 with Yaulp IX
        },
        ['StunTimer6'] = {        -- Timer 6 Stun, Fast Cast, Level 63+ (with ToT Heal 88+)
            "Sound of Vehemence", -- 128
            "Sound of Heroism",
            "Sound of Providence",
            "Sound of Rebuke",
            "Sound of Wrath",
            "Sound of Thunder",
            "Sound of Plangency",
            "Sound of Fervor",
            "Sound of Fury",
            "Sound of Reverberance",
            "Sound of Resonance",
            "Sound of Zeal",
            "Sound of Divinity",
            "Sound of Might",
            --Filler before this
            "Tarnation",     -- Timer 4, up to Level 65
            "Force",         -- No Timer #, up to Level 58
            "Holy Might",    -- No Timer #, up to Level 55
        },
        ['LowLevelStun'] = { --Adding a second stun at low levels
            "Stun",
        },
        ['UndeadNuke'] = {        -- Level 4+
            "Expunge the Undead", -- Level 129
            "Banish the Undead",
            "Extirpate the Undead",
            "Obliterate the Undead",
            "Repudiate the Undead",
            "Eradicate the Undead",
            "Abrogate the Undead",
            "Abolish the Undead",
            "Annihilate the Undead",
            "Desolate Undead",
            "Destroy Undead",
            "Exile Undead",
            "Banish Undead",
            "Expel Undead",
            "Dismiss Undead",
            "Expulse Undead",
            "Ward Undead",
        },
        ['MagicNuke'] = {
            "Veto", -- 127
            "Strike",
            "Furor",
            "Smite",
            "Wrath",
            "Retribution",
            "Judgment",
            "Condemnation",
            "Order",
            "Reproach",
            "Reproval",
            "Reprehend",
            "Rebuke",
            "Remonstrance",
            "Castigation",
            "Justice",
            "Sanction",
            "Injunction",
            "Divine Writ",
            "Decree",
        },
        ['HammerPet'] = {
            "Hammer of Emminence", -- 127
            "Unswerving Hammer of Faith",
            "Unswerving Hammer of Retribution",
            "Unflinching Hammer of Zeal",
            "Indomitable Hammer of Zeal",
            "Unwavering Hammer of Zeal",
            "Devout Hammer of Zeal",
            "Infallible Hammer of Zeal",
            "Infallible Hammer of Reverence",
            "Ardent Hammer of Zeal",
            "Unyielding Hammer of Zeal",
            "Unyielding Hammer of Obliteration",
            "Incorruptible Hammer of Obliteration",
            "Unrelenting Hammer of Zeal",
        },
        ['CompleteHeal'] = {
            "Complete Heal",
        },
    }, -- end AbilitySets
    ['HelperFunctions']   = {
        DoRez = function(self, corpseId)
            local rezAction = false
            local rezSpell = self.ResolvedActionMap['RezSpell']
            local okayToRez = Casting.OkayToRez(corpseId)
            local combatState = mq.TLO.Me.CombatState():lower() or "unknown"

            if combatState == "active" or combatState == "resting" then
                if mq.TLO.SpawnCount("pccorpse radius 80 zradius 30")() > 2 and Casting.SpellReady(mq.TLO.Spell("Larger Reviviscence"), true) then
                    rezAction = okayToRez and Casting.UseSpell("Larger Reviviscence", corpseId, true, true)
                end
            end

            if combatState == "combat" and Config:GetSetting('DoBattleRez') and Core.OkayToNotHeal() then
                if Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif mq.TLO.FindItem("=Water Sprinkler of Nem Ankh")() and mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("Water Sprinkler of Nem Ankh", corpseId)
                end
            else
                if Casting.AAReady("Blessing of Resurrection") then
                    rezAction = okayToRez and Casting.UseAA("Blessing of Resurrection", corpseId, true, 1)
                elseif mq.TLO.FindItem("=Water Sprinkler of Nem Ankh")() and mq.TLO.Me.ItemReady("=Water Sprinkler of Nem Ankh")() then
                    rezAction = okayToRez and Casting.UseItem("Water Sprinkler of Nem Ankh", corpseId)
                elseif not Casting.CanUseAA("Blessing of Resurrection") and Casting.SpellReady(rezSpell, true) then
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
        { -- Level 98+
            name = 'GroupHeal(98+)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 97 end,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        { -- Level 1-97
            name = 'GroupHeal(1-97)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() < 98 end,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        { -- Level 77+
            name = 'BigHeal(77+)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 76 end,
            cond = function(self, target)
                return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target)
            end,
        },
        { -- Level 59-76
            name = 'BigHeal(59-76)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 58 and mq.TLO.Me.Level() < 77 end,
            cond = function(self, target)
                return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target)
            end,
        },
        { -- Level 101+
            name = 'MainHeal(101+)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 100 end,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
        { -- Level 80-100
            name = 'MainHeal(80-100)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 79 and mq.TLO.Me.Level() < 101 end,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
        { -- Level 1-70
            name = 'MainHeal(1-79)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() < 80 end,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
    },
    ['HealRotations']     = {
        ['GroupHeal(98+)'] = {
            {
                name = "DichoHeal",
                type = "Spell",
                cond = function(self, spell)
                    return Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "Beacon of Life",
                type = "AA",
            },
            {
                name = "GroupFastHeal",
                type = "Spell",
            },
            {
                name = "Celestial Regeneration",
                type = "AA",
            },
            {
                name = "GroupHealCure",
                type = "Spell",
            },
            {
                name = "Exquisite Benediction",
                type = "AA",
            },
            {
                name = "GroupElixir",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['GroupHeal(1-97)'] = { --Level 1-97
            {
                name = "GroupHealNoCure",
                type = "Spell",
            },
            {
                name = "GroupElixir",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Celestial Regeneration",
                type = "AA",
            },
            {
                name = "Exquisite Benediction",
                type = "AA",
            },
        },
        ['BigHeal(77+)'] = {
            {
                name = "ClutchHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.GetTargetPctHPs() < 35
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
                name = "DichoHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Divine Arbitration",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsATank(target)
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
                name = "Blessing of Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return target.ID() == (mq.TLO.Target.AggroHolder.ID() and not Core.GetMainAssistId())
                end,
            },
            {
                name = "Veturika's Perseverance",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            { --The stuff above is down, lets make mainhealpoint chonkier. Homework: Wondering if we should be using this more/elsewhere.
                name = "Channeling the Divine",
                type = "AA",
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
            { --if we hit this we need spells back ASAP
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['BigHeal(59-76)'] = {
            {
                name = "Sanctuary",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Divine Arbitration",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsATank(target)
                end,
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
                name = "Renewal",
                type = "Spell",
            },
            {
                name = "RemedyHeal",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem("Renewal") end,
            },
        },
        ['MainHeal(101+)'] = {
            {
                name = "Focused Celestial Regeneration",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "HealNuke",
                type = "Spell",
                cond = function(self)
                    return mq.TLO.Me.CombatState():lower() == "combat"
                end,
            },
            {
                name = "RemedyHeal",
                type = "Spell",
            },
            {
                name = "RemedyHeal2",
                type = "Spell",
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
        },
        ['MainHeal(80-100)'] = { --Level 80-100
            {
                name = "Focused Celestial Regeneration",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "HealNuke",
                type = "Spell",
                cond = function(self)
                    return mq.TLO.Me.CombatState():lower() == "combat"
                end,
            },
            {
                name = "HealNuke2",
                type = "Spell",
                cond = function(self)
                    return mq.TLO.Me.CombatState():lower() == "combat"
                end,
            },
            {
                name = "HealNuke3",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('InterContraChoice') == 1 end,
                cond = function(self)
                    return mq.TLO.Me.CombatState():lower() == "combat"
                end,
            },
            {
                name = "RemedyHeal",
                type = "Spell",
            },
            {
                name = "Renewal",
                type = "Spell",
            },
            {
                name = "Renewal2",
                type = "Spell",
            },
            {
                name = "Renewal3",
                type = "Spell",
            },
            {
                name = "SingleElixir",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HealingLight",
                type = "Spell",
            },
        },
        ['MainHeal(1-79)'] = { --Level 1-79
            {
                name = "SingleElixir",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    return not Targeting.BigHealsNeeded(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "CompleteHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoCompleteHeal') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
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
    ['RotationOrder']     = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToBuff() and Casting.AmIBuffable()
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
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'ManaRestore',
            timer = 30,
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoManaRestore') and (Casting.CanUseAA("Veturika's Perseverance") or Casting.CanUseAA("Quiet Prayer")) end,
            targetId = function(self) return { Combat.FindWorstHurtMana(Config:GetSetting('ManaRestorePct')), } end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'CombatBuff',
            timer = 10,
            state = 1,
            steps = 1,
            load_cond = function(self) return self:GetResolvedActionMapItem('ReverseDS') or self:GetResolvedActionMapItem('WardBuff') end,
            targetId = function(self) return { Core.GetMainAssistId(), } or {} end,
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
                name = "Quiet Prayer",
                type = "AA",
                cond = function(self, aaName, target)
                    if Targeting.TargetIsMyself(target) then return false end
                    local rezSearch = string.format("pccorpse %s radius 100 zradius 50", target.DisplayName())
                    return mq.TLO.SpawnCount(rezSearch)() == 0
                end,
            },
        },
        ['CombatBuff'] = {
            {
                name = "ReverseDS",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "WardBuff",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
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
                name = "Spire of the Vicar",
                type = "AA",
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
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            { --homework: Check if this is necessary (does not exceed 50% spell haste cap)
                name = "Celestial Rapidity",
                type = "AA",
            },
            {
                name = "Exquisite Benediction",
                type = "AA",
            },
        },
        ['DPS'] = {
            {
                name = "TwinHealNuke",
                type = "Spell",
                retries = 0,
                load_cond = function(self) return Config:GetSetting('DoTwinHeal') end,
                cond = function(self, spell)
                    return not Casting.IHaveBuff("Healing Twincast")
                end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealStun') end,
                cond = function(self, spell)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "NukeHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.LightHealsNeeded(Core.GetMainAssistSpawn()) and Casting.HaveManaToNuke()
                end,
            },
            {
                name = "NukeHeal2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.LightHealsNeeded(Core.GetMainAssistSpawn()) and Casting.HaveManaToNuke()
                end,
            },
            {
                name = "NukeHeal3",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('InterContraChoice') == 3 end,
                cond = function(self, spell, target)
                    return Targeting.LightHealsNeeded(Core.GetMainAssistSpawn()) and Casting.HaveManaToNuke()
                end,
            },
            {
                name = "Yaulp",
                type = "AA",
                allowDead = true,
                cond = function(self, aaName)
                    return not mq.TLO.Me.Mount() and Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "YaulpSpell",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return not Casting.CanUseAA("Yaulp") end,
                cond = function(self, spell)
                    return not mq.TLO.Me.Mount() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "GroupElixir",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell)
                    if (mq.TLO.Me.Level() < 101 and not Casting.GOMCheck()) then return false end
                    return (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 15
                end,
            },
            {
                name = "LowLevelStun",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLLStun') and mq.TLO.Me.Level() < 59 end,
                cond = function(self, spell, target)
                    local targetLevel = Targeting.GetAutoTargetLevel()
                    if targetLevel == 0 or targetLevel > 55 then return false end
                    return Targeting.TargetNotStunned() and Casting.DetSpellCheck(spell) and Casting.HaveManaToDebuff() and not Casting.StunImmuneTarget(target)
                end,
            },
            {
                name = "Turn Undead",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead")
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
        ['Downtime'] = {
            {
                name = "Saint's Unity",
                type = "AA",
                cond = function(self, aaName)
                    if Config:GetSetting('AegoSymbol') == 3 then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "SelfHPBuff",
                type = "Spell",
                cond = function(self, spell)
                    if Config:GetSetting('AegoSymbol') == 3 or Casting.CanUseAA("Saint's Unity") then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "GroupHealProcBuff",
                type = "Spell",
                active_cond = function(self, spell)
                    return
                        Casting.IHaveBuff(spell)
                end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "AbsorbAura",
                type = "Spell",
                pre_activate = function(self, spell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    if not Casting.CanUseAA('Spirit Mastery') and not (Casting.AuraActiveByName("Reverent Aura") or Casting.AuraActiveByName(spell.BaseName())) then
                        ---@diagnostic disable-next-line: undefined-field
                        mq.TLO.Me.Aura(1).Remove()
                    end
                end,
                cond = function(self, spell)
                    return not (Casting.AuraActiveByName("Reverent Aura") or Casting.AuraActiveByName(spell.BaseName())) and
                        (Config:GetSetting('UseAura') == 1 or Casting.CanUseAA('Spirit Mastery'))
                end,
            },
            {
                name = "HPAura",
                type = "Spell",
                pre_activate = function(self, spell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.CanUseAA('Spirit Mastery') and not Casting.AuraActiveByName(spell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, spell)
                    return not Casting.AuraActiveByName(spell.BaseName()) and (Config:GetSetting('UseAura') == 2 or Casting.CanUseAA('Spirit Mastery'))
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
                name = "GroupSymbolBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if Config:GetSetting('AegoSymbol') == (1 or 4) or ((spell.TargetType() or ""):lower() == "single" and target.ID() ~= Core.GetMainAssistId()) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SpellBlessing",
                type = "Spell",
                load_cond = function(self) return mq.TLO.Me.Level() <= 95 end, -- could check to make sure we know a unified. This is cheaper.
                cond = function(self, spell, target)
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
                name = "GroupVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVieBuff') and self:GetResolvedActionMapItem('GroupVieBuff') end,
                cond = function(self, spell, target)
                    if Targeting.TargetIsATank(target) and self:GetResolvedActionMapItem('ShiningBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SingleVieBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoVieBuff') and not self:GetResolvedActionMapItem('GroupVieBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ShiningBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "DivineBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDivineBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Default",
            spells = {
                { name = "RemedyHeal",      cond = function(self) return mq.TLO.Me.Level() >= 96 end, },                                        -- Level 96+
                { name = "RemedyHeal2",     cond = function(self) return mq.TLO.Me.Level() >= 101 end, },                                       -- Level 101+
                { name = "HealingLight",    cond = function(self) return mq.TLO.Me.Level() < 80 end, },
                { name = "Renewal",         cond = function(self) return mq.TLO.Me.Level() >= 70 and mq.TLO.Me.Level() < 101 end, },            -- Level 80-95
                { name = "Renewal2",        cond = function(self) return mq.TLO.Me.Level() >= 80 and mq.TLO.Me.Level() < 101 end, },            -- Level 80+
                { name = "RemedyHeal",      cond = function(self) return mq.TLO.Me.Level() < 70 end, },
                { name = "CompleteHeal",    cond = function(self) return Config:GetSetting('DoCompleteHeal') and mq.TLO.Me.Level() < 80 end, }, -- Level 39
                { name = "ClutchHeal", },                                                                                                       -- Level 77+
                { name = "SingleElixir",    cond = function(self) return Config:GetSetting('DoHealOverTime') and mq.TLO.Me.Level() < 83 end, }, -- Level 19-79
                { name = "GroupElixir",     cond = function(self) return Config:GetSetting('DoHealOverTime') end, },                            -- Level 60+, gets better from 70 on, this may be overwritten before 75
                { name = "GroupFastHeal", },                                                                                                    -- Syllable, 98+
                { name = "GroupHealNoCure", cond = function(self) return not Core.GetResolvedActionMapItem('GroupFastHeal') end, },             -- Level 30-97
                { name = "DichoHeal", },                                                                                                        -- Level 101+ --may be overwritten from 101-104
                { name = "DivineBuff",      cond = function(self) return Config:GetSetting('DoDivineBuff') end, },                              -- Level 51+
                { name = "HealNuke",        cond = function(self) return Config:GetSetting('InterContraChoice') < 3 end, },
                { name = "HealNuke2",       cond = function(self) return Config:GetSetting('InterContraChoice') == 1 end, },
                { name = "NukeHeal",        cond = function(self) return Config:GetSetting('InterContraChoice') > 1 end, },
                { name = "NukeHeal2",       cond = function(self) return Config:GetSetting('InterContraChoice') == 3 end, },
                { name = "CureAll",         cond = function(self) return Config:GetSetting('KeepCureMemmed') == 2 end, },
                { name = "CurePoison",      cond = function(self) return Config:GetSetting('KeepCureMemmed') == 2 and not Core.GetResolvedActionMapItem('CureAll') end, },
                { name = "CureDisease",     cond = function(self) return Config:GetSetting('KeepCureMemmed') == 2 and not Core.GetResolvedActionMapItem('CureAll') end, },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCureMemmed') == 2 and not Core.GetResolvedActionMapItem('CureAll') end, },
                { name = "GroupHealCure",   cond = function(self) return Config:GetSetting('KeepCureMemmed') == 3 end, },
                { name = "StunTimer6",      cond = function(self) return Config:GetSetting('DoHealStun') end, },                          -- Level 16 - 76 (moved gems after)
                { name = "LowLevelStun",    cond = function(self) return Config:GetSetting('DoLLStun') and mq.TLO.Me.Level() < 59 end, }, -- Level 2-58
                { name = "WardBuff", },                                                                                                   -- Level 97
                { name = "ReverseDS", },                                                                                                  -- Level 85+
                { name = "TwinHealNuke",    cond = function(self) return Config:GetSetting('DoTwinHeal') end, },                          -- 84+
                { name = "YaulpSpell",      cond = function(self) return not Casting.CanUseAA("Yaulp") end, },                            -- Level 56-75
                { name = "MagicNuke",       cond = function(self) return Config:GetSetting('DoMagicNuke') end, },
                { name = "UndeadNuke",      cond = function(self) return Config:GetSetting('DoUndeadNuke') end, },
                --fallback
                { name = "ShiningBuff", },
                { name = "HealNuke", },
                { name = "NukeHeal", },
                { name = "HealNuke2",       cond = function(self) return Config:GetSetting('InterContraChoice') == 2 end, },
                { name = "NukeHeal2",       cond = function(self) return Config:GetSetting('InterContraChoice') == 2 end, },
                { name = "GroupVieBuff",    cond = function(self) return Config:GetSetting('DoVieBuff') end, },
                { name = "SingleVieBuff",   cond = function(self) return Config:GetSetting('DoVieBuff') and not Core.GetResolvedActionMapItem('GroupVieBuff') end, },
                { name = "HealNuke3",       cond = function(self) return Config:GetSetting('InterContraChoice') == 1 end, },
                { name = "NukeHeal3",       cond = function(self) return Config:GetSetting('InterContraChoice') == 3 end, },
                { name = "Renewal3",        cond = function(self) return mq.TLO.Me.Level() < 101 end, },
                { name = "RezSpell",        cond = function(self) return not Casting.CanUseAA('Blessing of Resurrection') end, },
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
            FAQ = "What do the different Modes do for Cleric?",
            Answer = "At this time Clerics only have a Heal mode. You can use the provided options to shape them into more of a hybrid role if needed.",
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
        },
        ['DoACBuff']          = {
            DisplayName = "Use AC Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip =
                "Use your single-slot AC Buff on the Main Assist. USE CASES:\n" ..
                "You have Aegolism selected and are below level 60 (We are still using a HP Type One buff).\n" ..
                "You have Symbol selected and you are below level 95 (We don't have Unified Symbols yet).\n" ..
                "Leaving this on in other cases is not likely to cause issue, but may cause unnecessary buff checking.",
            Default = false,
        },
        ['DoVieBuff']         = {
            DisplayName = "Use Vie Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use your melee damage absorb (Vie) line.",
            Default = true,
            FAQ = "Why am I using the Vie and Shining buffs together when the melee guard does not stack?",
            Answer = "We will always use the Shining line on the tank, but if selected, we will also use the Vie Buff on the Group.\n" ..
                "Before we have the Shining Buff, we will use our single-target Vie buff only on the tank.",
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
            DisplayName = "Do Divine Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your Divine Intervention line (death save) on the MA.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoVetAA']           = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        --Damage
        ['InterContraChoice'] = {
            DisplayName = "Inter/Contra:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Select your preference between the Intervention and Contravention lines.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Prefer Intervention', 'Balanced (usually one of each)', 'Prefer Contravention', },
            Default = 2,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoTwinHeal']        = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoUndeadNuke']      = {
            DisplayName = "Do Undead Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use the Undead nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoMagicNuke']       = {
            DisplayName = "Do Magic Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 104,
            Tooltip = "Use the Magic nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoHealStun']        = {
            DisplayName = "ToT-Heal Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "Use the Timer 6 HoT Stun (\"Sound of\" Line).",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "Which stun spells does the Cleric use?",
            Answer =
                "At low levels, we will use the \"Stun\" spell (until 58, if selected) and either \"Holy Might\", \"Force\", or \"Tarnation\" until level 65.\n" ..
                "After that, we transition to the Timer 6 stuns (\"Sound of\" line), which have a ToT heal from Level 88.\n" ..
                "Please note that the low level spell named \"Stun\" is controlled by the Low Level Stun option.",
        },
        ['DoLLStun']          = {
            DisplayName = "Low Level Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 102,
            Tooltip = "Use the Level 2 \"Stun\" spell, as long as it is level-appropriate (works on targets up to Level 55).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why is a Cleric stunning? It should be healing!?",
            Answer =
            "At low levels, Cleric stuns are often more efficient than healing the damage an non-stunned mob would cause.",
        },
        --Spells and Abilities
        ['DoManaRestore']     = {
            DisplayName = "Use Mana Restore AAs",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Use Veturika's Prescence (on self) or Quiet Prayer (on others) at critically low mana.",
            RequiresLoadoutChange = true, -- used as a load condition
            Default = true,
            ConfigType = "Advanced",
            FAQ = "What circumstances do we use Veturika's or Quiet Prayer?",
            Answer =
                "If the Mana Restore AA setting is set on the Spells and Abilities tab, we will use either of these once the Mana Restore Pct threshold is crossed.\n" ..
                "We will also use Veturika's as an emergency self-heal if required.",
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
        ['DoHealOverTime']    = {
            DisplayName = "Use HoTs",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Use the Elixir Line (Low Level: Single, Mid-Level: Both (situationally), High Level: Group).",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why isn't my Cleric using the Group Elixir HoT?",
            Answer = "Before Level 100, we will only use the Group Elixir if we have a GOM proc or the if the \"Group Injured Count\" is met (See Heal settings in RGMain config).",
        },
        ['DoCompleteHeal']    = {
            DisplayName = "Use Complete Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use Complete Heal on the MA (instead of the healing Light line).",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
            FAQ = "Why isn't my cleric using Complete Heal?",
            Answer =
            "Complete Heal use can be enabled in the Spells and Abilities tab. Please note that, if enabled, we will not use the healing Light line on the MA.",
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
            FAQ = "How can I stagger my clerics to use Complete Heal at different times?",
            Answer = "Adjust the Complete Heal Pct on the Spells and Abilities tab to different amounts to help stagger Complete Heals.",
        },
        ['KeepCureMemmed']    = {
            DisplayName = "Mem Cure:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Select your preference of a Cure spell to keep loaded (if a gem is availabe). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'None (Suggested for most cases)', 'Mem cure spells when possible', 'Mem GroupHealCure (\"Word of\" Line) when possible', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release aimed at official servers.\n\n" ..
                "  This config should perform well from from start to endgame, but a TLP or emu player may find it to be lacking exact customization for a specific era.\n\n" ..
                "  Additionally, those wishing more fine-tune control for specific encounters or raids should customize this config to their preference. \n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
