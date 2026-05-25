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
        ['Epic'] = {
            "Harmony of the Soul",
            "Aegis of Superior Divinity",
        },
    },
    ['AbilitySets']       = {
        ['WardBuff'] = {             -- Level 97+
            "Ward of Virtue VII",    -- Level 127
            "Ward of Commitment",    -- Level 122
            "Ward of Persistence",   -- Level 117
            "Ward of Righteousness", -- Level 112
            "Ward of Assurance",     -- Level 107
            "Ward of Surety",        -- Level 102
            "Ward of Certitude",     -- Level 97
        },
        ['HealingLight'] = {
            "Eminent Light",           -- Level 128
            "Avowed Light",            -- Level 123
            "Fervent Light",           -- Level 118
            "Sincere Light",           -- Level 113
            "Merciful Light",          -- Level 108
            "Ardent Light",            -- Level 103
            "Reverent Light",          -- Level 98
            "Zealous Light",           -- Level 93
            "Earnest Light",           -- Level 88
            "Devout Light",            -- Level 83
            "Solemn Light",            -- Level 78
            "Sacred Light",            -- Level 73
            "Ancient: Hallowed Light", -- Level 70
            "Pious Light",             -- Level 68
            "Holy Light",              -- Level 65
            "Supernal Light",          -- Level 63
            "Ethereal Light",          -- Level 58
            "Divine Light",            -- Level 53
            "Healing Light",           -- Level 45
            "Superior Healing",        -- Level 30
            "Greater Healing",         -- Level 20
            "Healing",                 -- Level 10
            "Light Healing",           -- Level 4
            "Minor Healing",           -- Level 1
        },
        ['RemedyHeal'] = {             -- Not great until 96/RoF (Graceful)
            "Holy Remedy XIV",         -- Level 126
            "Avowed Remedy",           -- Level 121
            "Guileless Remedy",        -- Level 116
            "Sincere Remedy",          -- Level 111
            "Merciful Remedy",         -- Level 106
            "Spiritual Remedy",        -- Level 101
            "Graceful Remedy",         -- Level 96
            "Faithful Remedy",         -- Level 91
            "Earnest Remedy",          -- Level 86
            "Devout Remedy",           -- Level 81
            "Solemn Remedy",           -- Level 76
            "Sacred Remedy",           -- Level 71
            "Pious Remedy",            -- Level 66
            "Supernal Remedy",         -- Level 61
            "Ethereal Remedy",         -- Level 59
            -- "Remedy",        -- Level 51, No place to slot this, Ethereal used as a fallback at some level ranges
        },
        ['RemedyHeal2'] = {
            "Holy Remedy XIV",        -- Level 126
            "Avowed Remedy",          -- Level 121
            "Guileless Remedy",       -- Level 116
            "Sincere Remedy",         -- Level 111
            "Merciful Remedy",        -- Level 106
            "Spiritual Remedy",       -- Level 101
            "Graceful Remedy",        -- Level 96
        },
        ['Renewal'] = {               -- Level 70 +, large heal, slower cast
            "Desperate Renewal XIII", -- Level 130
            "Heroic Renewal",         -- Level 125
            "Determined Renewal",     -- Level 120
            "Dire Renewal",           -- Level 115
            "Furial Renewal",         -- Level 110
            "Fraught Renewal",        -- Level 100
            "Fervent Renewal",        -- Level 95
            "Frenzied Renewal",       -- Level 90
            "Frenetic Renewal",       -- Level 85
            "Frantic Renewal",        -- Level 80
            "Desperate Renewal",      -- Level 70
        },
        ['Renewal2'] = {              -- Level 70 +, large heal, slower cast
            "Heroic Renewal",         -- Level 125
            "Determined Renewal",     -- Level 120
            "Dire Renewal",           -- Level 115
            "Furial Renewal",         -- Level 110
            "Fraught Renewal",        -- Level 100
            "Fervent Renewal",        -- Level 95
            "Frenzied Renewal",       -- Level 90
            "Frenetic Renewal",       -- Level 85
            "Frantic Renewal",        -- Level 80
            "Desperate Renewal",      -- Level 70
        },
        ['Renewal3'] = {              -- Level 70 +, large heal, slower cast
            "Heroic Renewal",         -- Level 125
            "Determined Renewal",     -- Level 120
            "Dire Renewal",           -- Level 115
            "Furial Renewal",         -- Level 110
            "Fraught Renewal",        -- Level 100
            "Fervent Renewal",        -- Level 95
            "Frenzied Renewal",       -- Level 90
            "Frenetic Renewal",       -- Level 85
            "Frantic Renewal",        -- Level 80
            "Desperate Renewal",      -- Level 70
        },
        ['DichoHeal'] = {
            "Reciprocal Blessing",       -- Level 121
            "Ecliptic Blessing",         -- Level 116
            "Composite Blessing",        -- Level 111
            "Dissident Blessing",        -- Level 106
            "Undying Life",              -- Level 101
        },
        ['GroupFastHeal'] = {            -- Level 98
            "Syllable of Wellbeing",     -- Level 128
            "Syllable of Acceptance",    -- Level 123
            "Syllable of Invigoration",  -- Level 118
            "Syllable of Soothing",      -- Level 113
            "Syllable of Mending",       -- Level 108
            "Syllable of Convalescence", -- Level 103
            "Syllable of Renewal",       -- Level 98
        },
        ['GroupHealCure'] = {
            "Word of Greater Vivification",  -- Level 124
            "Word of Greater Rejuvenation",  -- Level 120
            "Word of Greater Replenishment", -- Level 115
            "Word of Greater Restoration",   -- Level 110
            "Word of Greater Reformation",   -- Level 105
            "Word of Reformation",           -- Level 100
            "Word of Rehabilitation",        -- Level 95
            "Word of Resurgence",            -- Level 90
            "Word of Recovery",              -- Level 85
            "Word of Vivacity",              -- Level 80
            "Word of Vivification",          -- Level 69
            "Word of Replenishment",         -- Level 64
            "Word of Replenishment",         -- Level 64, Poi/Dis/Curse
            "Word of Restoration",           -- Level 57, Poi/Dis
        },
        ['GroupHealNoCure'] = {
            -----Group Heals No Cure Slot 5
            "Word of Wellbeing",     -- Level 126
            "Word of Acceptance",    -- Level 121
            "Word of Redress",       -- Level 116
            "Word of Soothing",      -- Level 111
            "Word of Mending",       -- Level 106
            "Word of Convalescence", -- Level 101
            "Word of Renewal",       -- Level 96
            "Word of Recuperation",  -- Level 91
            "Word of Awakening",     -- Level 86, back to no cures
            "Word of Recovery",      -- Level 85
            "Word of Vivacity",      -- Level 80
            "Word of Vivification",  -- Level 69
            "Word of Replenishment", -- Level 64
            "Word of Restoration",   -- Level 57, No good NoCure in these level ranges using w/Cure... Note Word of Redemption omitted (12sec cast)
            "Word of Vigor",         -- Level 52
            "Word of Healing",       -- Level 45
            "Word of Health",        -- Level 30
        },
        ['HealNuke'] = {
            -- Heal Tank and Nuke Tanks Target -- Intervention Lines
            "Eminent Intervention",   -- Level 128
            "Avowed Intervention",    -- Level 123
            "Atoned Intervention",    -- Level 118
            "Sincere Intervention",   -- Level 113
            "Merciful Intervention",  -- Level 108
            "Mystical Intervention",  -- Level 103
            "Virtuous Intervention",  -- Level 98
            "Elysian Intervention",   -- Level 93
            "Celestial Intervention", -- Level 88
            "Holy Intervention",      -- Level 83
        },
        ['HealNuke2'] = {
            -- Heal Tank and Nuke Tanks Target -- Intervention Lines
            "Eminent Intervention",   -- Level 128
            "Avowed Intervention",    -- Level 123
            "Atoned Intervention",    -- Level 118
            "Sincere Intervention",   -- Level 113
            "Merciful Intervention",  -- Level 108
            "Mystical Intervention",  -- Level 103
            "Virtuous Intervention",  -- Level 98
            "Elysian Intervention",   -- Level 93
            "Celestial Intervention", -- Level 88
            "Holy Intervention",      -- Level 83
        },
        ['HealNuke3'] = {
            -- Heal Tank and Nuke Tanks Target -- Intervention Lines
            "Eminent Intervention",   -- Level 128
            "Avowed Intervention",    -- Level 123
            "Atoned Intervention",    -- Level 118
            "Sincere Intervention",   -- Level 113
            "Merciful Intervention",  -- Level 108
            "Mystical Intervention",  -- Level 103
            "Virtuous Intervention",  -- Level 98
            "Elysian Intervention",   -- Level 93
            "Celestial Intervention", -- Level 88
            "Holy Intervention",      -- Level 83
        },
        ['NukeHeal'] = {
            -- Nuke Target and Heal Tank -  Dps Heals
            "Eminent Contravention",   -- Level 130
            "Avowed Contravention",    -- Level 125
            "Divine Contravention",    -- Level 120
            "Sincere Contravention",   -- Level 115
            "Merciful Contravention",  -- Level 110
            "Ardent Contravention",    -- Level 105
            "Virtuous Contravention",  -- Level 100
            "Elysian Contravention",   -- Level 95
            "Celestial Contravention", -- Level 90
            "Holy Contravention",      -- Level 85
        },
        ['NukeHeal2'] = {
            -- Nuke Target and Heal Tank -  Dps Heals
            "Eminent Contravention",   -- Level 130
            "Avowed Contravention",    -- Level 125
            "Divine Contravention",    -- Level 120
            "Sincere Contravention",   -- Level 115
            "Merciful Contravention",  -- Level 110
            "Ardent Contravention",    -- Level 105
            "Virtuous Contravention",  -- Level 100
            "Elysian Contravention",   -- Level 95
            "Celestial Contravention", -- Level 90
            "Holy Contravention",      -- Level 85
        },
        ['NukeHeal3'] = {
            -- Nuke Target and Heal Tank -  Dps Heals
            "Eminent Contravention",   -- Level 130
            "Avowed Contravention",    -- Level 125
            "Divine Contravention",    -- Level 120
            "Sincere Contravention",   -- Level 115
            "Merciful Contravention",  -- Level 110
            "Ardent Contravention",    -- Level 105
            "Virtuous Contravention",  -- Level 100
            "Elysian Contravention",   -- Level 95
            "Celestial Contravention", -- Level 90
            "Holy Contravention",      -- Level 85
        },
        ['ReverseDS'] = {
            -- Reverse Damage Shield Proc (LVL >=85) -- Ignoring the Mark Line
            "Hazuri's Retort",   -- Level 125
            "Axoeviq's Retort",  -- Level 120
            "Jorlleag's Retort", -- Level 115
            "Curate's Retort",   -- Level 110
            "Vicarum's Retort",  -- Level 105
            "Olsif's Retort",    -- Level 100
            "Galvos' Retort",    -- Level 95
            "Fintar's Retort",   -- Level 90
            "Erud's Retort",     -- Level 85
        },
        ['SelfHPBuff'] = {
            --Self Buff for Mana Regen and armor
            "Armor of the Eminent",           -- Level 130
            "Armor of the Avowed",            -- Level 125
            "Armor of Penance",               -- Level 120
            "Armor of Sincerity",             -- Level 115
            "Armor of the Merciful",          -- Level 110
            "Armor of the Ardent",            -- Level 105
            "Armor of the Reverent",          -- Level 100
            "Armor of the Zealous",           -- Level 95
            "Armor of the Earnest",           -- Level 90
            "Armor of the Devout",            -- Level 85
            "Armor of the Solemn",            -- Level 80
            "Armor of the Sacred",            -- Level 75
            "Armor of the Pious",             -- Level 70
            "Armor of the Zealot",            -- Level 65
            "Ancient: High Priest's Bulwark", -- Level 60
            "Blessed Armor of the Risen",     -- Level 58
            "Armor of Protection",            -- Level 34
        },
        ['GroupHealProcBuff'] = {
            ----Self buff casts group heal on AE spell damage
            "Divine Rejoinder",   -- Level 124
            "Divine Contingency", -- Level 118
            "Divine Consequence", -- Level 113
            "Divine Reaction",    -- Level 108
            "Divine Response",    -- Level 102
        },
        ['AegoBuff'] = {
            ----Use HP Type one until Temperance at 40... Group Buff at 45 (Blessing of Temperance)
            "Unified Hand of Aegolism XV",   -- Level 130
            "Unified Hand of Infallibility", -- Level 125
            "Unified Hand of Persistence",   -- Level 120
            "Unified Hand of Righteousness", -- Level 115
            "Unified Hand of Assurance",     -- Level 110
            "Unified Hand of Surety",        -- Level 105
            "Unified Hand of Certitude",     -- Level 100
            "Unified Hand of Credence",      -- Level 95
            "Hand of Reliance",              -- Level 90
            "Hand of Gallantry",             -- Level 85
            "Hand Of Temerity",              -- Level 80
            "Hand of Tenacity",              -- Level 75
            "Hand of Conviction",            -- Level 70
            "Hand of Virtue",                -- Level 65
            "Aegolism",                      -- Level 60
            "Ancient: Gift of Aegolism",     -- Level 60
            "Blessing of Aegolism",          -- Level 60
            "Blessing of Temperance",        -- Level 45
            "Temperance",                    -- Level 40
            "Valor",                         -- Level 32
            "Bravery",                       -- Level 22
            "Daring",                        -- Level 17
            "Center",                        -- Level 7
            "Courage",                       -- Level 1
        },
        ['ACBuff'] = {                       --Sometimes single, sometimes group, used on tank before Aego or until it is rolled into Unified (Symbol)
            "Order of the Earnest",          -- Level 90
            "Ward of the Earnest",           -- Level 86
            "Order of the Devout",           -- Level 85
            "Ward of the Devout",            -- Level 81
            "Order of the Resolute",         -- Level 80
            "Ward of the Resolute",          -- Level 76
            "Ward of the Dauntless",         -- Level 71
            "Ward of Valiance",              -- Level 66
            "Ward of Gallantry",             -- Level 61
            "Bulwark of Faith",              -- Level 57
            "Shield of Words",               -- Level 45
            "Armor of Faith",                -- Level 35
            "Guard",                         -- Level 25
            "Spirit Armor",                  -- Level 15
            "Holy Armor",                    -- Level 1
        },
        ['ShiningBuff'] = {
            --Tank Buff Traditionally Shining Series of Buffs
            "Shining Rampart IX", -- Level 130
            "Shining Steel",      -- Level 124
            "Shining Fortitude",  -- Level 119
            "Shining Aegis",      -- Level 114
            "Shining Fortress",   -- Level 109
            "Shining Bulwark",    -- Level 104
            "Shining Bastion",    -- Level 99
            "Shining Armor",      -- Level 94
            "Shining Rampart",    -- Level 89
        },
        ['SingleVieBuff'] = {     -- Level 20-73 We don't use this once we have the group version
            "Aegis of Vie",       -- Level 73
            "Panoply of Vie",     -- Level 67
            "Bulwark of Vie",     -- Level 62
            "Protection of Vie",  -- Level 54
            "Guard of Vie",       -- Level 40
            "Ward of Vie",        -- Level 20
        },
        ['GroupVieBuff'] = {
            "Rallied Bulwark of Vie",            -- Level 130
            "Rallied Greater Aegis of Vie",      -- Level 125
            "Rallied Greater Protection of Vie", -- Level 115
            "Rallied Greater Guard of Vie",      -- Level 110
            "Rallied Greater Ward of Vie",       -- Level 105
            "Rallied Bastion of Vie",            -- Level 100
            "Rallied Armor of Vie",              -- Level 95
            "Rallied Rampart of Vie",            -- Level 90
            "Rallied Palladium of Vie",          -- Level 85
            "Rallied Shield of Vie",             -- Level 80
            "Rallied Aegis of Vie",              -- Level 75
        },
        ['GroupSymbolBuff'] = {
            ----Group Symbols
            "Unified Hand of Helmsbane",       -- Level 125
            "Unified Hand of the Diabo",       -- Level 120
            "Unified Hand of Jorlleag",        -- Level 115
            "Unified Hand of Emra",            -- Level 110
            "Unified Hand of Assurance",       -- Level 110
            "Unified Hand of Nonia",           -- Level 105
            "Unified Hand of Gezat",           -- Level 100
            "Unified Hand of the Triumvirate", -- Level 95
            "Ealdun's Mark",                   -- Level 90
            "Darianna's Mark",                 -- Level 85
            "Kaerra's Mark",                   -- Level 80
            "Elushar's Mark",                  -- Level 75
            "Balikor's Mark",                  -- Level 70
            "Kazad's Mark",                    -- Level 63
            "Marzin's Mark",                   -- Level 60
            "Naltron's Mark",                  -- Level 58
            "Symbol of Marzin",                -- Level 54
            "Symbol of Naltron",               -- Level 41
            "Symbol of Pinzarn",               -- Level 31
            "Symbol of Ryltan",                -- Level 21
            "Symbol of Transal",               -- Level 11
        },
        ['AbsorbAura'] = {
            ----Aura Buffs - Aura Name is seperate than the buff name
            "Aura of the Persistent", -- Level 119
            "Aura of the Reverent",   -- Level 100
            "Aura of the Pious",      -- Level 70
            "Aura of the Zealot",     -- Level 55
        },
        ['HPAura'] = {
            ---- Aura Buff 2 - Aura Name is the same as the buff name
            "Bastion of Divinity", -- Level 120
            "Aura of Divinity",    -- Level 100
            "Circle of Divinity",  -- Level 80
        },
        ['DivineBuff'] = {
            --Divine Buffs REQUIRES extra spell slot because of the 90s recast
            "Divine Interstition",    -- Level 127
            "Divine Interference",    -- Level 122
            "Divine Intermediation",  -- Level 112
            "Divine Imposition",      -- Level 107
            "Divine Indemnification", -- Level 102
            "Divine Interposition",   -- Level 97
            "Divine Invocation",      -- Level 92
            "Divine Intercession",    -- Level 87
            "Divine Intervention",    -- Level 60
            "Death Pact",             -- Level 51
        },
        ['TwinHealNuke'] = {
            "Unyielding Denunciation", -- Level 129
            "Unyielding Admonition",   -- Level 124
            "Unyielding Rebuke",       -- Level 119
            "Unyielding Censure",      -- Level 114
            "Unyielding Judgment",     -- Level 109
            "Glorious Judgment",       -- Level 104
            "Glorious Rebuke",         -- Level 99
            "Glorious Admonition",     -- Level 94
            "Glorious Censure",        -- Level 89
            "Glorious Denunciation",   -- Level 84
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
        ['AERezSpell'] = {
            "Superior Reviviscence", -- Level 76
            "Eminent Reviviscence",  -- Level 71
            "Greater Reviviscence",  -- Level 66
            "Larger Reviviscence",   -- Level 61
        },
        ['ClutchHeal'] = {
            -- 11th-17th Rejuv Spell Line Clutch Heals Require Life below 35-45% to cast
            "Twentieth Dictum",         -- Level 127
            "Nineteenth Commandment",   -- Level 122
            "Eighteenth Rejuvenation",  -- Level 117
            "Seventeenth Rejuvenation", -- Level 112
            "Sixteenth Serenity",       -- Level 107
            "Fifteenth Emblem",         -- Level 97
            "Fourteenth Catalyst",      -- Level 92
            "Thirteenth Salve",         -- Level 87
            "Twelfth Night",            -- Level 82
            "Eleventh-Hour",            -- Level 77
        },
        ['GroupInfusionBuff'] = {
            -- Hand of Infusion Line
            "Hand of Avowed Infusion",     -- Level 124
            "Hand of Unyielding Infusion", -- Level 119
            "Hand of Sincere Infusion",    -- Level 114
            "Hand of Merciful Infusion",   -- Level 109
            "Hand of Graceful Infusion",   -- Level 99
            "Hand of Faithful Infusion",   -- Level 94
        },
        ['SingleElixir'] = {
            "Eminent Elixir",    -- Level 127
            "Earnest Elixir",    -- Level 87
            "Devout Elixir",     -- Level 82
            "Solemn Elixir",     -- Level 77
            "Sacred Elixir",     -- Level 72
            "Pious Elixir",      -- Level 67
            "Holy Elixir",       -- Level 65
            "Supernal Elixir",   -- Level 62
            "Celestial Elixir",  -- Level 59
            "Celestial Healing", -- Level 44
            "Celestial Health",  -- Level 29
            "Celestial Remedy",  -- Level 19
        },
        ['GroupElixir'] = {
            -- Group Hot Line - Elixirs No Cure
            "Elixir of Absolution",     -- Level 130
            "Elixir of Realization",    -- Level 125
            "Elixir of Benevolence",    -- Level 120
            "Elixir of Transcendence",  -- Level 115
            "Elixir of Wulthan",        -- Level 110
            "Elixir of the Seas",       -- Level 105
            "Elixir of the Acquittal",  -- Level 100
            "Elixir of the Beneficent", -- Level 95
            "Elixir of the Ardent",     -- Level 90
            "Elixir of Expiation",      -- Level 85
            "Elixir of Atonement",      -- Level 80
            "Elixir of Redemption",     -- Level 75
            "Elixir of Divinity",       -- Level 70
            "Ethereal Elixir",          -- Level 60
        },
        ['GroupAcquittal'] = {
            -- Group Hot Line Cure + Hot 99+
            "Eminent Acquittal",   -- Level 129
            "Avowed Acquittal",    -- Level 124
            "Devout Acquittal",    -- Level 119
            "Sincere Acquittal",   -- Level 114
            "Merciful Acquittal",  -- Level 109
            "Ardent Acquittal",    -- Level 104
            "Cleansing Acquittal", -- Level 99
        },
        ['SpellBlessing'] = {
            -- Spell haste Blessings 15-92, defunct at 95 due to Unifieds.
            -- -- Do not add future version unless you have verified that they are not simply Symbol/Aego Unified triggers.
            "Hand of Will",          -- Level 87
            "Blessing of Will",      -- Level 86
            "Aura of Loyalty",       -- Level 82
            "Blessing of Loyalty",   -- Level 81
            "Aura of Resolve",       -- Level 77
            "Blessing of Resolve",   -- Level 76
            "Aura of Purpose",       -- Level 72
            "Blessing of Purpose",   -- Level 71
            "Aura of Devotion",      -- Level 69
            "Blessing of Devotion",  -- Level 67
            "Aura of Reverence",     -- Level 64
            "Blessing of Reverence", -- Level 62
            "Blessing of Faith",     -- Level 35
            "Blessing of Piety",     -- Level 15
        },
        ['CureAll'] = {
            "Sanctified Blood",  -- Level 119
            "Expurgated Blood",  -- Level 109
            "Unblemished Blood", -- Level 104
            "Cleansed Blood",    -- Level 99
            "Perfected Blood",   -- Level 94
            "Purged Blood",      -- Level 89, does not cure corruption
            "Purified Blood",    -- Level 84, does not cure curse, 5 level gap where we will use this without curing curse, but AA should cover
            -- "Pure Blood",     -- Level 51, Much better single cures occur after this one
        },
        ['CureCorrupt'] = {
            "Purge Corruption",     -- Level 119
            "Extricate Corruption", -- Level 109
            "Nullify Corruption",   -- Level 104
            "Abrogate Corruption",  -- Level 99
            "Eradicate Corruption", -- Level 94
            "Dissolve Corruption",  -- Level 89, group from here up
            "Pristine Blood",       -- Level 87, single target from here down
            "Abolish Corruption",   -- Level 84
            "Vitiate Corruption",   -- Level 79
            "Expunge Corruption",   -- Level 64
        },
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
        ['YaulpSpell'] = {
            "Yaulp IX",              -- Level 76, AA starts at 75 with Yaulp IX
            "Yaulp VIII",            -- Level 71
            "Yaulp VII",             -- Level 69
            "Yaulp VI",              -- Level 65
            "Yaulp V",               -- Level 56, first rank with haste/mana regen
        },
        ['StunTimer6'] = {           -- Timer 6 Stun, Fast Cast, Level 63+ (with ToT Heal 88+)
            "Sound of Vehemence",    -- Level 128
            "Sound of Heroism",      -- Level 123
            "Sound of Providence",   -- Level 118
            "Sound of Rebuke",       -- Level 113
            "Sound of Wrath",        -- Level 108
            "Sound of Thunder",      -- Level 103
            "Sound of Plangency",    -- Level 98
            "Sound of Fervor",       -- Level 93
            "Sound of Fury",         -- Level 88
            "Sound of Reverberance", -- Level 83
            "Sound of Resonance",    -- Level 78
            "Sound of Zeal",         -- Level 73
            "Sound of Divinity",     -- Level 68
            "Sound of Might",        -- Level 63
            --Filler before this
            "Tarnation",             -- Level 61, Timer 4, up to Level 65
            "Force",                 -- Level 31, No Timer #, up to Level 58
            "Holy Might",            -- Level 16, No Timer #, up to Level 55
        },
        ['LowLevelStun'] = {         --Adding a second stun at low levels
            "Stun",                  -- Level 2
        },
        ['UndeadNuke'] = {           -- Level 4+
            "Expunge the Undead",    -- Level 129
            "Banish the Undead",     -- Level 121
            "Extirpate the Undead",  -- Level 116
            "Obliterate the Undead", -- Level 111
            "Repudiate the Undead",  -- Level 106
            "Eradicate the Undead",  -- Level 101
            "Abrogate the Undead",   -- Level 96
            "Abolish the Undead",    -- Level 91
            "Annihilate the Undead", -- Level 86
            "Desolate Undead",       -- Level 68
            "Destroy Undead",        -- Level 64
            "Exile Undead",          -- Level 55
            "Banish Undead",         -- Level 43
            "Expel Undead",          -- Level 33
            "Dismiss Undead",        -- Level 23
            "Expulse Undead",        -- Level 13
            "Ward Undead",           -- Level 4
        },
        ['MagicNuke'] = {
            "Veto",         -- Level 127
            "Decree",       -- Level 122
            "Divine Writ",  -- Level 117
            "Injunction",   -- Level 112
            "Sanction",     -- Level 107
            "Justice",      -- Level 102
            "Castigation",  -- Level 97
            "Remonstrance", -- Level 92
            "Rebuke",       -- Level 87
            "Reprehend",    -- Level 82
            "Reproval",     -- Level 72
            "Reproach",     -- Level 67
            "Order",        -- Level 65
            "Condemnation", -- Level 62
            "Judgment",     -- Level 56
            "Retribution",  -- Level 44
            "Wrath",        -- Level 29
            "Smite",        -- Level 14
            "Furor",        -- Level 5
            "Strike",       -- Level 1
        },
        ['HammerPet'] = {
            "Hammer of Eminence",                   -- Level 127
            "Unrelenting Hammer of Zeal",           -- Level 124
            "Incorruptible Hammer of Obliteration", -- Level 119
            "Unyielding Hammer of Obliteration",    -- Level 114
            "Unyielding Hammer of Zeal",            -- Level 109
            "Ardent Hammer of Zeal",                -- Level 104
            "Infallible Hammer of Reverence",       -- Level 99
            "Infallible Hammer of Zeal",            -- Level 94
            "Devout Hammer of Zeal",                -- Level 89
            "Unwavering Hammer of Zeal",            -- Level 84
            "Indomitable Hammer of Zeal",           -- Level 79
            "Unflinching Hammer of Zeal",           -- Level 74
            "Unswerving Hammer of Retribution",     -- Level 68
            "Unswerving Hammer of Faith",           -- Level 54
        },
        ['CompleteHeal'] = {
            "Complete Heal", -- Level 39
        },
    },                       -- end AbilitySets
    ['Helpers']           = {
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
        {
            name = 'Combat Buffs',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
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
            RequiresLoadoutChange = true,
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
            Warning = function()
                if Config:GetSetting('CompleteHealPct') > Config:GetSetting('MaxHealPoint') then
                    return true, "Warning: CompleteHealPct exceeds MaxHealPoint - we will not check if heals are needed until health is under MaxHealPoint."
                end
                return false, ""
            end,
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
