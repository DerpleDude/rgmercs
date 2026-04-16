local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require('utils.globals')
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Ui           = require("utils.ui")
local Casting      = require("utils.casting")
local ItemManager  = require("utils.item_manager")
local Logger       = require("utils.logger")
local Set          = require('mq.set')
local Combat       = require("utils.combat")

local _ClassConfig = {
    _version              = "2.0 - Live",
    _author               = "Algar",
    ['ModeChecks']        = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },
    ['Modes']             = {
        'Tank',
        'DPS',
    },
    ['Cures']             = {
        GetCureSpells = function(self)
            -- These are the default cure choices. I prefer PurityCure but a user may wish to change this to something else.
            -- -- I chose not to add the option to use CurseCure or keep that memmed like emu because this is aimed and Live.
            local neededCures = {
                Poison     = 'PurityCure',
                Disease    = 'PurityCure',
                Curse      = 'PurityCure',
                Corruption = 'CureCorrupt',
            }

            -- If we have chose the option, and have a splash heal in our books, use that instead
            if Config:GetSetting('SplashHealAsCure') and Core.GetResolvedActionMapItem('SplashHeal') then
                neededCures = {
                    Poison     = 'SplashHeal',
                    Disease    = 'SplashHeal',
                    Curse      = 'SplashHeal',
                    Corruption = 'SplashHeal',
                }
            end

            -- Make sure that we have the curespell, and then place into the tempsettings table for CureNow to use
            self.TempSettings.CureSpells = {}
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

                if not cureAA and targetId == mq.TLO.Me.ID() and Casting.AAReady("Purification") then
                    cureAA = "Purification"
                end

                if cureAA then
                    Logger.log_debug("CureNow: Using %s for %s on %s.", cureAA, type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
                    return Casting.UseAA(cureAA, targetId), true
                end
            end

            if Config:GetSetting('DoCureSpells') then
                for effectType, cureSpell in pairs(self.TempSettings.CureSpells) do
                    if type:lower() == effectType:lower() then
                        Logger.log_debug("CureNow: Using %s for %s on %s.", cureSpell.RankName(), type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
                        return Casting.UseSpell(cureSpell.RankName(), targetId, true), true
                    end
                end
            end

            Logger.log_debug("CureNow: No valid cure at this time for %s on %s.", type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
            return false, false
        end,
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Nightbane, Sword of the Valiant",
            "Redemption",
        },
    },
    ['AbilitySets']       = {
        ["CrushTimer6"] = {
            "Crush of Eminence",     -- Level 129
            "Crush of Compunction",  -- Level 85
            "Crush of Repentance",   -- Level 90
            "Crush of Tides",        -- Level 95
            "Crush of Tarew",        -- Level 100
            "Crush of Povar",        -- Level 105
            "Crush of E'Ci",         -- Level 110
            "Crush of Restless Ice", -- Level 115
            "Crush of the Umbra",    -- Level 120
            "Crush of the Heroic",   -- Level 124
        },
        ["CrushTimer5"] = {
            "Crush of the Crying Seas X", -- Level 127
            "Crush of the Crying Seas",   -- Level 82
            "Crush of Marr",              -- Level 87
            "Crush of Oseka",             -- Level 92
            "Crush of the Iceclad",       -- Level 97
            "Crush of the Darkened Sea",  -- Level 102
            "Crush of the Timorous Deep", -- Level 107
            "Crush of the Grotto",        -- Level 112
            "Crush of the Twilight Sea",  -- Level 117
            "Crush of the Wayunder",      -- Level 122
        },
        ["TwinHealNuke"] = {
            "Brilliant Expurgation",  -- Level 130
            "Glorious Vindication",   -- Level 85
            "Glorious Exoneration",   -- Level 90
            "Glorious Exculpation",   -- Level 95
            "Glorious Expurgation",   -- Level 100
            "Brilliant Vindication",  -- Level 105
            "Brilliant Exoneration",  -- Level 110
            "Brilliant Exculpation",  -- Level 115
            "Brilliant Acquittal",    -- Level 120
            "Brilliant Denouncement", -- Level 125
        },
        ["TempHP"] = {
            "Unyielding Stance",
            "Steely Stance",
            "Stubborn Stance",
            "Stoic Stance",
            "Staunch Stance",
            "Steadfast Stance",
            "Defiant Stance",
            "Stormwall Stance",
            "Adamant Stance",
            "Unwavering Stance",
        },
        ["Preservation"] = {
            "Preservation of Quellious",    -- Level 130
            "Ward of Tunare",               -- Level 70
            "Sustenance of Tunare",         -- Level 80
            "Preservation of Tunare",       -- Level 85
            "Preservation of Marr",         -- Level 90
            "Preservation of Oseka",        -- Level 95
            "Preservation of the Iceclad",  -- Level 100
            "Preservation of Rodcet",       -- Level 110
            "Preservation of the Grotto",   -- Level 115
            "Preservation of the Basilica", -- Level 120
            "Preservation of the Fern",     -- Level 125
        },
        ["HealNuke"] = {
            "Denouncement IX",
            "Denouncement",
            "Reprimand",
            "Ostracize",
            "Admonish",
            "Censure",
            "Remonstrate",
            "Upbraid",
            "Chastise",
        },
        ["BlessingProc"] = {
            "Harmonious Blessing",
            "Concordant Blessing",
            "Confluent Blessing",
            "Penumbral Blessing",
            "Paradoxical Blessing",
        },
        ["DebuffNuke"] = {
            "Committal",    -- Level 126
            "Last Rites",   -- Level 68 - Timer 7
            "Burial Rites", -- Level 71 - Timer 7
            "Benediction",  -- Level 76
            "Eulogy",       -- Level 81
            "Elegy",        -- Level 86
            "Paean",        -- Level 91
            "Laudation",    -- Level 96
            "Consecration", -- Level 101
            "Remembrance",  -- Level 106
            "Requiem",      -- Level 111
            "Hymnal",       -- Level 116
            "Revelation",   -- Level 121
        },
        ["SteelProc"] = {   --Proc Heal ToT
            "Rejuvenating Steel VII",
            "Restoring Steel",
            "Regenerating Steel",
            "Rejuvenating Steel",
            "Reinvigorating Steel",
            "Revitalizating Steel",
            "Renewing Steel",
        },
        ["FuryProc"] = {
            "Eminent Fury",   -- Level 130
            "Divine Might",   -- Level 45, 65pt
            "Pious Might",    -- Level 63, 150pt
            "Holy Order",     -- Level 65, 180pt
            "Pious Fury",     -- Level 68, 190pt
            "Righteous Fury", -- Level 80, 268pt --For simplicity of coding and conflict prevention, once fury is rolled into DPU at 80, we will no longer use the undead proc.
            "Devout Fury",    -- Level 85
            "Earnest Fury",   -- Level 90
            "Zealous Fury",   -- Level 95
            "Reverent Fury",  -- Level 100
            "Ardent Fury",    -- Level 105
            "Merciful Fury",  -- Level 110
            "Sincere Fury",   -- Level 115
            "Wrathful Fury",  -- Level 120
            "Avowed Fury",    -- Level 125
        },
        ["UndeadProc"] = {
            --- Undead Proc Strike : does not stack with Fury Proc, will be used until Fury is available even if setting not enabled.
            "Instrument of Nife", -- Level 26, 243pt
            "Ward of Nife",       -- Level 62, 300pt
            "Silvered Fury",      -- Level 67, 390pt
        },
        ["Aurora"] = {
            "Aurora of Sunlight XI",
            "Aurora of Dawning",
            "Aurora of Dawnlight",
            "Aurora of Daybreak",
            "Aurora of Splendor",
            "Aurora of Sunrise",
            "Aurora of Dayspring",
            "Aurora of Morninglight",
            "Aurora of Wakening",
            "Aurora of Realizing",
        },
        ["StunTimer5"] = {
            "Force of Akera XV",          -- Level 130
            "Desist",                     -- Level 13 - Not Timer 5, use for TLP Low Level Stun
            "Stun",                       -- Level 28
            "Force of Akera",             -- Level 53
            "Ancient: Force of Chaos",    -- Level 65
            "Ancient: Force of Jeron",    -- Level 70
            "Force of Prexus",            -- Level 75
            "Force of Timorous",          -- Level 80
            "Force of the Crying Seas",   -- Level 85
            "Force of Marr",              -- Level 90
            "Force of Oseka",             -- Level 95
            "Force of the Iceclad",       -- Level 100
            "Force of the Darkened Sea",  -- Level 105
            "Force of the Timorous Deep", -- Level 110
            "Force of the Grotto",        -- Level 115
            "Force of the Umbra",         -- Level 120
            "Force of the Wayunder",      -- Level 125
        },
        ["StunTimer4"] = {
            "Eminent Force",   -- Level 126
            "Cease",           -- Level 7 - Not Timer 4, use for TLP Low Level Stun
            "Force of Akilae", -- Level 62
            "Force of Piety",  -- Level 66
            "Sacred Force",    -- Level 71
            "Devout Force",    -- Level 81
            "Solemn Force",    -- Level 83
            "Earnest Force",   -- Level 86
            "Zealous Force",   -- Level 91
            "Reverent Force",  -- Level 96
            "Ardent Force",    -- Level 101
            "Merciful Force",  -- Level 106
            "Sincere Force",   -- Level 111
            "Pious Force",     -- Level 116
            "Avowed Force",    -- Level 121
        },
        ["HealStun"] = {
            "Force of Eminence",   -- Level 129
            "Force of the Avowed", --Level 124
            "Force of Generosity",
            "Force of Reverence",
            "Force of Ardency",
            "Force of Mercy",
            "Force of Sincerity",
        },
        ["HealWard"] = { -- Heal ToT, Ward on Self
            "Protective Confession X",
            "Protective Acceptance",
            "Protective Revelation",
            "Protective Confession",
            "Protective Devotion",
            "Protective Dedication",
            "Protective Allegiance",
            "Protective Proclamation",
            "Protective Devotion",
            "Protective Consecration",
        },
        ["Aego"] = {
            "Hand of Austerity XVII",        -- Level 127 - Group
            "Austerity",                     -- Level 55
            "Blessing of Austerity",         -- Level 58 - Group
            "Guidance",                      -- Level 65
            "Affirmation",                   -- Level 70
            "Sworn Protector",               -- Level 75
            "Oathbound Protector",           -- Level 80
            "Sworn Keeper",                  -- Level 85
            "Oathbound Keeper",              -- Level 90
            "Avowed Keeper",                 -- Level 92
            "Hand of the Avowed Keeper",     -- Level 95 - Group
            "Pledged Keeper",                -- Level 97
            "Hand of the Pledged Keeper",    -- Level 100 - Group
            "Stormbound Keeper",             -- Level 102
            "Hand of the Stormbound Keeper", -- Level 105 - Group
            "Ashbound Keeper",               -- Level 107
            "Hand of the Ashbound Keeper",   -- Level 110 - Group
            "Stormwall Keeper",              -- Level 112
            "Hand of the Stormwall Keeper",  -- Level 115 - Group
            "Shadewell Keeper",              -- Level 117
            "Hand of the Dreaming Keeper",   -- Level 120 - Group
            "Fernshade Keeper",              -- Level 122
            "Hand of the Fernshade Keeper",  -- Level 125 - Group
        },
        ["Brells"] = {
            "Brell's Mountainous Barrior XVI",
            "Brell's Tenacious Barrier",
            "Brell's Loamy Ward",
            "Brell's Tellurian Rampart",
            "Brell's Adamantine Armor",
            "Brell's Steadfast Bulwark",
            "Brell's Stalwart Bulwark",
            "Brell's Blessed Bastion",
            "Brell's Blessed Barrier",
            "Brell's Earthen Aegis",
            "Brell's Stony Guard",
            "Brell's Brawny Bulwark",
            "Brell's Stalwart Shield",
            "Brell's Mountainous Barrier",
            "Brell's Steadfast Aegis",
            "Brell's Unbreakable Palisade",
        },
        ["SplashHeal"] = {
            "Splash of Eminence",
            "Splash of Heroism",
            "Splash of Repentance",
            "Splash of Sanctification",
            "Splash of Purification",
            "Splash of Cleansing",
            "Splash of Atonement",
            "Splash of Depuration",
            "Splash of Exaltation",
        },
        ["HealTaunt"] = {
            "Valiant Defiance",
            "Valiant Disruption",
            "Valiant Deflection",
            "Valiant Defense",
            "Valiant Diversion",
            "Valiant Deterrence",
        },
        ["Affirmation"] = { --- Improved Super Taunt - Gets you Aggro for X seconds and reduces other Haters generation.
            "Unquestioned Affirmation",
            "Unconditional Affirmation",
            "Unending Affirmation",
            "Unrelenting Affirmation",
            "Undivided Affirmation",
            "Unbroken Affirmation",
            "Unflinching Affirmation",
            "Unyielding Affirmation",
        },
        ["WaveHeal"] = { -- Group Heal
            "Wave of Inspiriation",
            "Wave of Regret",
            "Wave of Bereavement",
            "Wave of Propitiation",
            "Wave of Expiation",
            "Wave of Grief",
            "Wave of Sorrow",
            "Wave of Contrition",
            "Wave of Penitence",
            "Wave of Remitment",
            "Wave of Absolution",
            "Wave of Forgiveness",
            "Wave of Piety",
            "Wave of Marr",
            "Wave of Trushar",
            "Healing Wave of Prexus",
            "Wave of Healing",
            "Wave of Life",
        },
        ["SelfHeal"] = {
            "Penitence IX",
            "Penitence",
            "Contrition",
            "Sorrow",
            "Grief",
            "Exaltation",
            "Propitiation",
            "Culpability",
            "Angst",
        },
        ["ReverseDS"] = {
            "Mark of Sharash",
            "Mark of the Saint",
            "Mark of the Crusader",
            "Mark of the Pious",
            "Mark of the Pure",
            "Mark of the Defender",
            "Mark of the Reverent",
            "Mark of the Exemplar",
            "Mark of the Commander",
            "Mark of the Jade Cohort",
            "Mark of the Eclipsed Cohort",
            "Mark of the Forgotten Hero",
        },
        -- ["Cleansing"] = {           -- ST HoT
        --     "Ethereal Cleansing",   -- Level 44
        --     "Celestial Cleansing",  -- Level 59
        --     "Supernal Cleansing",   -- Level 64
        --     "Pious Cleansing",      -- Level 69
        --     "Sacred Cleansing",     -- Level 73
        --     "Solemn Cleansing",     -- Level 78
        --     "Devout Cleansing",     -- Level 93
        --     "Earnest Cleansing",    -- Level 88
        --     "Zealous Cleansing",    -- Level 93
        --     "Reverent Cleansing",   -- Level 98
        --     "Ardent Cleansing",     -- Level 103
        --     "Merciful Cleansing",   -- Level 108
        --     "Sincere Cleansing",    -- Level 113
        --     "Forthright Cleansing", -- Level 118
        --     "Avowed Cleansing",     -- Level 123
        -- },
        ["BurstHeal"] = { -- Smart Heal, Target or ToT
            "Burst of Sunlight XII",
            "Burst of Sunlight",
            "Burst of Morrow",
            "Burst of Dawnlight",
            "Burst of Daybreak",
            "Burst of Splendor",
            "Burst of Sunrise",
            "Burst of Dayspring",
            "Burst of Morninglight",
            "Burst of Wakening",
            "Burst of Dawnbreak",
            "Burst of Sunspring",
        },
        ["ArmorSelfBuff"] = {
            "Armor of Unyielding Faith",  -- Level 128
            "Aura of the Crusader",       -- Level 64
            "Armor of the Champion",      -- Level 69
            "Armor of Unrelenting Faith", -- Level 73
            "Armor of Inexorable Faith",  -- Level 78
            "Armor of Unwavering Faith",  -- Level 83
            "Armor of Implacable Faith",  -- Level 88
            "Armor of Formidable Faith",  -- Level 93
            "Armor of Formidable Grace",  -- Level 98
            "Armor of Formidable Spirit", -- Level 103
            "Armor of Steadfast Faith",   -- Level 108
            "Armor of Steadfast Grace",   -- Level 113
            "Armor of Unyielding Grace",  -- Level 118
            "Armor of Heroic Faith",      -- Level 118
        },
        ["RighteousStrike"] = {
            "Righteous Indignation VIII",
            "Righteous Antipathy",
            "Righteous Fury",
            "Righteous Indignation",
            "Righteous Vexation",
            "Righteous Umbrage",
            "Righteous Condemnation",
            "Righteous Antipathy",
            "Righteous Censure",
            "Righteous Disdain",
        },
        ["Symbol"] = {
            "Symbol of Liako",
            "Symbol of Jeneca",
            "Symbol of Jyleel",
            "Symbol of Erillion",
            "Symbol of Burim",
            "Symbol of Niparson",
            "Symbol of Teralov",
            "Symbol of Sevalak",
            "Symbol of Bthur",
            "Symbol of Jeron",
            "Symbol of Marzin",
            "Symbol of Naltron",
            "Symbol of Pinzarn",
            "Symbol of Ryltan",
            "Symbol of Transal",
            "Symbol of Sevalak",
            "Symbol of Thormir",
        },
        ["StunTimer6"] = {                    -- Timer 6, less damage than timer 6 crush, but inlcudes stun. Has Push.
            "Lesson of Penitence XV",         -- Level 127
            "Quellious' Word of Tranquility", -- Level 54
            "Quellious' Word of Serenity",    -- Level 64
            "Serene Command",                 -- Level 68
            "Lesson of Penitence",            -- Level 72
            "Lesson of Contrition",           -- Level 77
            "Lesson of Compunction",          -- Level 82
            "Lesson of Repentance",           -- Level 87
            "Lesson of Remorse",              -- Level 92
            "Lesson of Sorrow",               -- Level 97
            "Lesson of Grief",                -- Level 102
            "Lesson of Expiation",            -- Level 107
            "Lesson of Propitiation",         -- Level 112
            "Lesson of Guilt",                -- Level 117
            "Lesson of Remembrance",          -- Level 122
        },
        ["Audacity"] = {                      -- Magic Resist debuff, Hate over time
            "Impassioned Audacity",
            "Fanatical Audacity",
            "Ardent Audacity",
            "Fervent Audacity",
            "Sanctimonious Audacity",
            "Devout Audacity",
            "Righteous Audacity",
        },
        ["LightHeal"] = {      --ToT Heal
            "Eminent Light",   -- Level 127
            "Light of Life",   -- Level 52
            "Light of Nife",   -- Level 63
            "Light of Order",  -- Level 65
            "Light of Piety",  -- Level 68
            "Gleaming Light",  -- Level 72
            "Radiant Light",   -- Level 77
            "Shining Light",   -- Level 82
            "Joyous Light",    -- Level 87
            "Brilliant Light", -- Level 92
            "Dazzling Light",  -- Level 97
            "Blessed Light",   -- Level 102
            "Merciful Light",  -- Level 107
            "Sincere Light",   -- Level 112
            "Raptured Light",  -- Level 117
            "Avowed Light",    -- Level 122
        },
        -- ["Pacify"] = {
        --     "Assuring Words",
        --     "Placating Words",
        --     "Tranquil Words",
        --     "Propitiate",
        --     "Mollify",
        --     "Reconcile",
        --     "Dulcify",
        --     "Soothe",
        --     "Pacify",
        --     "Calm",
        --     "Lull",
        -- },
        ["TouchHeal"] = {
            "Eminent Touch",
            "Touch of Nife",
            "Touch of Piety",
            "Sacred Touch",
            "Solemn Touch",
            "Devout Touch",
            "Earnest Touch",
            "Zealous Touch",
            "Reverent Touch",
            "Ardent Touch",
            "Merciful Touch",
            "Sincere Touch",
            "Soothing Touch",
            "Avowed Touch",
            "Superior Healing", -- Level 48
            "Healing",          -- Level 27
            "Light Healing",    -- Level 12
            "Minor Healing",    -- Level 6
            "Salve",            -- Level 1
        },
        ["Dicho"] = {
            --- Dissident Stun
            "Dichotomic Force",
            "Dissident Force",
            "Composite Force",
            "Ecliptic Force",
            "Reciprocal Force",
        },
        ["PurityCure"] = { --- Purity Cure Poison/Diease Cure Half Power to curse
            "Mastery: Balanced Purity",
            "Balanced Purity",
            "Devoted Purity",
            "Earnest Purity",
            "Zealous Purity",
            "Reverent Purity",
            "Ardent Purity",
            "Merciful Purity",
        },
        -- ["CureCurse"] = {
        --     "Remove Minor Curse",
        --     "Remove Lesser Curse",
        --     "Remove Curse",
        --     "Remove Greater Curse",
        --     "Eradicate Curse",
        -- },
        ['CureCorrupt'] = {
            "Mastery: Consecrate",
            "Consecrate",
            "Sanctify",
            "Depurate",
            "Expurgate",
            "Purify",
            "Cleanse",
            "Cure Corruption",
        },
        ["ForHonor"] = { --- Challenge Taunt Over time Debuff
            "Duel for Honor",
            "Challenge for Honor",
            "Trial For Honor",
            "Charge for Honor",
            "Confrontation for Honor",
            "Provocation for Honor",
            "Demand for Honor",
            "Impose for Honor",
            "Refute for Honor",
            "Protest for Honor",
            "Parlay for Honor",
            "Petition for Honor",
        },
        ["Piety"] = { -- Spell Resist Buff
            "Silent Piety",
        },
        ["Remorse"] = { -- Killshot buff
            "Penitence for the Fallen",
            "Remorse for the Fallen",
        },
        ["HealAura"] = {
            "Blessed Aura",
            "Holy Aura",
        },
        ["UndeadNuke"] = {
            "Doctrine of Revocation",  -- Level 128
            "Doctrine of Repudiation", -- Level 121
            "Ward Undead",             -- Level 14
            "Expulse Undead",          -- Level 30
            "Dismiss Undead",          -- Level 46
            "Expel Undead",            -- Level 54
            "Deny Undead",             -- Level 62 - Timer 7
            "Spurn Undead",            -- Level 67 - Timer 7
            --[] = "Wraithguard's Vengeance",  -- Level 75 - Unobtainable?
            "Annihilate the Undead",   -- Level 86 - Res Debuff / Extra Damage
            "Abolish the Undead",      -- Level 91 - Res Debuff / Extra Damage
            "Doctrine of Abrogation",  -- Level 96
            "Abrogate the Undead",     -- Level 96 - Res Debuff / Extra Damage
            "Doctrine of Rescission",  -- Level 101
            "Doctrine of Exculpation", -- Level 106
            "Doctrine of Abolishment", -- Level 111
            "Doctrine of Annulment",   -- Level 116
        },
        ["AllianceNuke"] = {
            "Holy Alliance",
            "Stormwall Coalition",
            "Aureate Covariance",
        },
        ['EndRegen'] = {
            --Timer 13, can't be used in combat
            "Second Wind",
            "Third Wind",
            "Fourth Wind",
            "Respite",
            "Reprieve",
            "Rest",
            "Breather", --Level 101
        },
        ['CombatEndRegen'] = {
            --Timer 13, can be used in combat.
            "Hiatus V",
            "Hiatus", --Level 106
            "Relax",
            "Night's Calming",
            "Convalesce",
        },
        ["MeleeMit"] = {
            "Impede",
            -- "Withstand",
            "Defy",
            "Renounce",
            "Reprove",
            "Repel",
            "Spurn",
            "Thwart",
            "Repudiate",
            "Gird",
        },
        ["ArmorDisc"] = {
            --- Armor Timer 11
            "Armor of Eminence",
            "Armor of Avowal",
            "Armor of the Forthright",
            "Armor of Sincerity",
            "Armor of Mercy",
            "Armor of Ardency",
            "Armor of Reverence",
            "Armor of Zeal",
            "Armor of Courage",
        },
        ["Undeadburn"] = {
            "Holyforge Discipline",
        },
        ["Penitent"] = {
            -- Penitent Armor Discipline Timer 11
            "Avowed Penitence",
            "Fervent Penitence",
            "Reverent Penitence",
            "Devout Penitence",
            "Merciful Penitence",
            "Sincere Penitence",
        },
        ["Mantle"] = {
            "Mantle of Eminence",
            "Supernal Mantle",
            "Mantle of the Sapphire Cohort",
            "Kar`Zok Mantle",
            "Skalber Mantle",
            "Brightwing Mantle",
            "Prominent Mantle",
            "Exalted Mantle",
            "Honorific Mantle",
            "Armor of Decorum",
            "Armor of Righteousness",
            "Guard of Righteousness",
            "Guard of Humility",
            "Guard of Piety",
        },
        ["Guardian"] = {
            "Holy Guardian Discipline IV",
            "Revered Guardian Discipline",
            "Blessed Guardian Discipline",
            "Holy Guardian Discipline",
        },
        ["Spellblock"] = {
            "Sanctification Discipline",
        },
        ['Deflection'] = {
            'Deflection Discipline',
        },
        ["ReflexStrike"] = {
            --- Reflexive Strike Heal
            "Reflexive Resolution",
            "Reflexive Redemption",
            "Reflexive Righteousness",
            "Reflexive Reverence",
        },
        ['RezSpell'] = {
            'Resurrection',
            'Restoration',
            'Renewal',
            'Revive',
            'Reparation',
            'Reconstitution',
            'Reanimation',
        },
    },
    ['HelperFunctions']   = {
        DoRez = function(self, corpseId)
            local rezAction = false
            local rezSpell = Core.GetResolvedActionMapItem('RezSpell')
            local okayToRez = Casting.OkayToRez(corpseId)

            if (Config:GetSetting('DoBattleRez') or mq.TLO.Me.CombatState():lower() ~= "combat") and Casting.AAReady("Gift of Resurrection") then
                rezAction = okayToRez and Casting.UseAA("Gift of Resurrection", corpseId, true, 1)
            elseif not Casting.CanUseAA("Gift of Resurrection") and mq.TLO.Me.CombatState():lower() ~= "combat" and Casting.SpellReady(rezSpell, true) then
                rezAction = okayToRez and Casting.UseSpell(rezSpell, corpseId, true, true)
            end

            return rezAction
        end,
        --determine whether we should overwrite DPU buffs with better single buffs
        SingleBuffCheck = function(self)
            if Casting.CanUseAA("Divine Protector's Unity") and not Config:GetSetting('OverwriteDPUBuffs') then return false end
            return true
        end,
        --function to determine if we have enough mobs in range to use a defensive disc
        DefensiveDiscCheck = function(printDebug)
            local xtCount = mq.TLO.Me.XTarget() or 0
            if xtCount < Config:GetSetting('DiscCount') then return false end
            local haters = Set.new({})
            for i = 1, xtCount do
                local xtarg = mq.TLO.Me.XTarget(i)
                if xtarg and xtarg.ID() > 0 and ((xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater")) and (xtarg.Distance() or 999) <= 30 then
                    if printDebug then
                        Logger.log_verbose("DefensiveDiscCheck(): XT(%d) Counting %s(%d) as a hater in range.", i, xtarg.CleanName() or "None", xtarg.ID())
                    end
                    haters:add(xtarg.ID())
                end
                if #haters:toList() >= Config:GetSetting('DiscCount') then return true end -- no need to keep counting once this threshold has been reached
            end
            return false
        end,
    },
    ['HealRotationOrder'] = {
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
    },
    ['HealRotations']     = {
        ["GroupHeal"] = {
            {
                name = "Hand of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "Gift of Life",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "SplashHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('KeepSplashMemmed') end,
            },
            {
                name = "WaveHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') end,
            },
        },
        ["BigHeal"] = {
            {
                name = "Lay on Hands",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.GetTargetPctHPs() < Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "SelfHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSelfHeal') end,
                cond = function(self, spell, target)
                    return self.CombatState == "Combat" and Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Marr's Gift",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Hand of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and (Targeting.TargetIsMyself(target) or Targeting.GetTargetPctHPs(target) < Config:GetSetting('HPCritical'))
                end,
            },
            {
                name = "Gift of Life",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and (Targeting.TargetIsMyself(target) or Targeting.GetTargetPctHPs(target) < Config:GetSetting('HPCritical'))
                end,
            },
            {
                name = "TouchHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoTouchHeal") == 1 end,
            },
        },
        ["MainHeal"] = {
            {
                name = "BurstHeal",
                type = "Spell",
            },
            {
                name = "TouchHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoTouchHeal") == 2 end,
            },
        },
    },
    ['RotationOrder']     = {
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Core.OkayToNotHeal() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Core.OkayToNotHeal()
            end,
        },
        { --Actions to lock down xtarg haters
            name = 'HateTools(AggroTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('TankAggroScan') end,
            targetId = function(self) return Targeting.CheckForAggroTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat"
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'HateTools(AutoTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Targeting.HateToolsNeeded()
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'AEHateTools',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('AETauntAA') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Combat.AETauntCheck(true)
            end,
        },
        { --Dynamic weapon swapping if UseBandolier is toggled
            name = 'Weapon Management',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('UseBandolier') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        { --Defensive actions triggered by low HP
            name = 'EmergencyDefenses',
            state = 1,
            steps = 2, -- help ensure that we cancel visage when needed
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
            end,
        },
        { --Prioritized in their own rotation to help keep HP topped to the desired level, includes emergency abilities
            name = 'ToTHeals',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
            end,
        },
        { --Defensive actions used proactively to prevent emergencies
            name = 'Defenses',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.IHaveAggro(100) and
                    -- we are under our defense start HP
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('DefenseStart') or
                        -- we have met our defense count threshold
                        self.ClassConfig.HelperFunctions.DefensiveDiscCheck(true) or
                        -- we are fighting a named and we are (presumably) tanking it
                        (Globals.AutoTargetIsNamed and Targeting.GetAutoTargetAggroPct() >= 100))
            end,
        },
        {
            name = 'Debuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Casting.BurnCheck() and Core.OkayToNotHeal()
            end,
        },
        { --DPS Spells, includes recourse/gift maintenance
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
    },
    ['Rotations']         = {
        ['Downtime'] = {
            {
                name = "EndRegen",
                type = "Disc",
                load_cond = function(self) return not Core.GetResolvedActionMapItem("CombatEndRegen") end,
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "CombatEndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "HealAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName()))
                end,
            },
            {
                name = "Divine Protector's Unity",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID() or 0) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "ArmorSelfBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.ClassConfig.HelperFunctions.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "FuryProc",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.ClassConfig.HelperFunctions.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "UndeadProc",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) --use this always until we have a Fury proc, and optionally after that, up until the point that Fury is rolled into DPU
                    if (mq.TLO.Me.AltAbility("Divine Protector's Unity").Rank() or 0) > 1 or (Core.GetResolvedActionMapItem("FuryProc") and not Config:GetSetting('DoUndeadProc')) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Remorse",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.ClassConfig.HelperFunctions.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Piety",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return self.ClassConfig.HelperFunctions.SingleBuffCheck() and Casting.SelfBuffCheck(spell)
                end,
            },
            --You'll notice my use of TotalSeconds, this is to keep as close to 100% uptime as possible on these buffs, rebuffing early to decrease the chance of them falling off in combat
            --I considered creating a function (helper or utils) to govern this as I use it on multiple classes but the difference between buff window/song window/aa/spell etc makes it unwieldy
            -- if using duration checks, dont use SelfBuffCheck() (as it could return false when the effect is still on)
            {
                name = "Preservation",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell) and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 30
                end,
            },
            {
                name = "TempHP",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTempHP') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 45
                end,
            },
            {
                name = "BlessingProc",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 15
                end,
            },
            {
                name = "HealWard",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 15
                end,
            },
            { --Charm Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Charm").Name() or "CharmClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCharmClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "SteelProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSteelProc') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 45
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Brells",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoBrells') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Aego",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AegoSymbol') == 1 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Symbol",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AegoSymbol') == 2 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Marr's Salvation",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSalvation') end,
                cond = function(self, aaName, target)
                    if Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
                post_activate = function(self, aaName, success)
                    -- mq.delay(200, function() return mq.TLO.Me.Buff("Marr's Salvation")() ~= nil end)
                    if success and Core.IsTanking() and mq.TLO.Me.Buff("Marr's Salvation")() then
                        Core.DoCmd("/removebuff \"Marr's Salvation\"")
                    end
                end,
            },
        },
        ['EmergencyDefenses'] = {
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < Config:GetSetting('HPCritical')
                end,
            },
            --Note that on named we may already have a mantle/carapace running already, could make this remove other discs, but meh, Shield Flash still a thing.
            {
                name = "Deflection",
                type = "Disc",
                pre_activate = function(self)
                    if Config:GetSetting('UseBandolier') then
                        Core.SafeCallFunc("Equip Shield", ItemManager.BandolierSwap, "Shield")
                    end
                end,
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') and Casting.NoDiscActive() and
                        (mq.TLO.Me.AltAbilityTimer("Shield Flash")() or 0) < 234000
                end,
            },
            {
                name = "Shield Flash",
                type = "AA",
                pre_activate = function(self)
                    if Config:GetSetting('UseBandolier') then
                        Core.SafeCallFunc("Equip Shield", ItemManager.BandolierSwap, "Shield")
                    end
                end,
                cond = function(self, aaName)
                    return mq.TLO.Me.ActiveDisc.Name() ~= "Deflection Discipline"
                end,
            },
            --Penitent vs Armor is something I will need to do more homework on
            {
                name = "Penitent",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Group Armor of The Inquisitor",
                type = "AA",
                cond = function(self, aaName)
                    return not Casting.IHaveBuff("Armor of the Inquisitor")
                end,
            },
            {
                name = "Armor of the Inquisitor",
                type = "AA",
                cond = function(self, aaName)
                    return not Casting.IHaveBuff("Armor of the Inquisitor")
                end,
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoChestClick') end,
                cond = function(self, itemName, target)
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Mantle",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['HateTools(AggroTarget)'] = {
            {
                name = "HealTaunt",
                type = "Spell",
            },
            {
                name = "Audacity",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "ForHonor",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name_func = function(self) return Casting.GetFirstAA({ "Force of Disruption", "Divine Stun", }) end,
                type = "AA",
            },
            {
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.GetTargetDistance(target) < 30
                end,
            },
            {
                name = "CrushTimer5",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end,
            },
            {
                name = "CrushTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end,
            },
            {
                name = "StunTimer5",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5')
                end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer4Choice') end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 2 end,
            },
        },
        ['HateTools(AutoTarget)'] = {
            {
                name_func = function(self) return Casting.GetFirstAA({ "Force of Disruption", "Divine Stun", }) end,
                type = "AA",
            },
            {
                name = "HealTaunt",
                type = "Spell",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro()
                end,
            },
            --used when we've lost hatred after it is initially established
            {
                name = "Ageless Enmity",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() < 90 and Targeting.LostAutoTargetAggro()
                end,
            },
            --used to jumpstart hatred on named from the outset and prevent early rips from burns
            {
                name = "Affirmation",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Projection of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and (mq.TLO.Target.SecondaryPctAggro() or 0) > 80
                end,
            },
            {
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro() and Targeting.GetTargetDistance(target) < 30
                end,
            },
            {
                name = "Audacity",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "ForHonor",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "CrushTimer5",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 60
                end,
            },
            {
                name = "CrushTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 60
                end,
            },
        },
        ['AEHateTools'] = {
            {
                name = "Heroic Leap",
                type = "AA",
                cond = function(self, aaName, target)
                    return not mq.TLO.Me.HeadWet()
                end,
            },
            {
                name = "Beacon of the Righteous",
                type = "AA",
            },
            {
                name = "Hallowed Lodestar",
                type = "AA",
            },
        },
        ['Debuff'] = {
            {
                name = "Audacity",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "ReverseDS",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoReverseDS') < 3 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DoReverseDS') == 2 and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Valorous Rage",
                type = "AA",
            },
            {
                name = "RighteousStrike",
                type = "Disc",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "Spire of Chivalry",
                type = "AA",
            },
            {
                name = "Thunder of Karana",
                type = "AA",
            },
            {
                name = "Hand of Tunare",
                type = "AA",
            },
            {
                name = "Holyforge",
                type = "Disc",
                load_cond = function(self) return not Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive() and Targeting.TargetBodyIs(target, "Undead")
                end,
            },
            {
                name = "Pureforge",
                type = "Disc",
                load_cond = function(self) return not Core.IsTanking() end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Inquisitor's Judgment",
                type = "AA",
            },
            {
                name = "Preservation",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "BlessingProc",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SteelProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSteelProc') end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Marr's Gift",
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.Me.PctMana() < 10
                end,
            },
        },
        ['Defenses'] = {
            {
                name = "MeleeMit",
                type = "Disc",
                cond = function(self, discSpell)
                    return not ((discSpell.Level() or 0) < 108 and not Casting.NoDiscActive)
                end,
            },
            {
                name = "ArmorDisc",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Mantle",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Guardian",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Purification",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.TotalCounters() > 0
                end,
            },
        },
        ['ToTHeals'] = {
            {
                name = "Dicho",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDicho') end,
                cond = function(self, spell, target)
                    return Targeting.GroupHealsNeeded() or Targeting.BigHealsNeeded(mq.TLO.Me)
                end,
            },
            {
                name = "BurstHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MainHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
            {
                name = "HealTaunt",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
            },
            {
                name = "HealNuke",
                type = "Spell",
            },
            {
                name = "LightHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoLightHeal") end,
            },
        },
        ['CombatWeave'] = {
            { --Used if the group could benefit from the heal
                name = "ReflexStrike",
                type = "Disc",
                cond = function(self, discSpell)
                    return Targeting.GroupHealsNeeded()
                end,
            },
            {
                name = "CombatEndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Vanquish the Fallen",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead")
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Core.ShieldEquipped() or Casting.CanUseAA("Improved Bash")
                end,
            },
            {
                name = "Slam",
                type = "Ability",
            },
        },
        ['Combat'] = {
            {
                name = "ForHonor",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "HealStun",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MainHealsNeeded(mq.TLO.Me) or
                        (Core.IsTanking() and spell.RankName.Stacks() and (mq.TLO.Me.Song(spell.Trigger(1).Name).Duration.TotalSeconds() or 0) < 12)
                end,
            },
            {
                name = "HealWard",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTwinHealNuke') end,
            },
            {
                name = "Disruptive Persecution",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.HaveManaToNuke()
                end,
            },
            {
                name = "CrushTimer5",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer5Choice') == 1 end,
            },
            {
                name = "CrushTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 1 end,
            },
            {
                name = "StunTimer5",
                type = "Spell",
                load_cond = function(self)
                    return Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5')
                end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer4Choice') end,
            },
            {
                name = "StunTimer6",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('Timer6Choice') == 2 end,
            },
            {
                name_func = function(self) return Casting.GetFirstAA({ "Force of Disruption", "Divine Stun", }) end,
                type = "AA",
                load_cond = function(self) return Core.IsTanking() end,
            },
        },
        ['Weapon Management'] = {
            {
                name = "Equip Shield",
                type = "CustomFunc",
                active_cond = function()
                    return mq.TLO.Me.Bandolier("Shield").Active()
                end,
                cond = function(self, target)
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("Shield") end,
            },
            {
                name = "Equip 2Hand",
                type = "CustomFunc",
                active_cond = function(self, target)
                    return mq.TLO.Me.Bandolier("2Hand").Active()
                end,
                cond = function()
                    if mq.TLO.Me.Bandolier("2Hand").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('Equip2Hand') and mq.TLO.Me.ActiveDisc.Name() ~= "Deflection Discipline" and
                        (mq.TLO.Me.AltAbilityTimer("Shield Flash")() or 0) < 234000 and not (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("2Hand") end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "TouchHeal",   cond = function(self) return Config:GetSetting('DoTouchHeal') < 3 end, },
                { name = "LightHeal",   cond = function(self) return Config:GetSetting('DoLightHeal') end, },
                { name = "BurstHeal", },
                { name = "SelfHeal",    cond = function(self) return Config:GetSetting('DoSelfHeal') end, },
                { name = "SplashHeal",  cond = function(self) return Config:GetSetting('KeepSplashMemmed') end, },
                { name = "WaveHeal",    cond = function(self) return Config:GetSetting('DoWaveHeal') end, },
                { name = "HealTaunt",   cond = function(self) return Core.IsTanking() end, },
                { name = "Audacity",    cond = function(self) return Core.IsTanking() end, },
                { name = "ForHonor",    cond = function(self) return Core.IsTanking() end, },
                { name = "StunTimer4",  cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer4Choice') end, },
                { name = "CrushTimer5", cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer5Choice') == 1 end, },
                {
                    name = "StunTimer5",
                    cond = function(self)
                        return Core.IsTanking() and
                            (Config:GetSetting('Timer5Choice') == 2 or ((Config:GetSetting('Timer5Choice') == 1)) and not Core.GetResolvedActionMapItem('CrushTimer5'))
                    end,
                },
                { name = "CrushTimer6",  cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer6Choice') == 1 end, },
                { name = "StunTimer6",   cond = function(self) return Core.IsTanking() and Config:GetSetting('Timer6Choice') == 2 end, },
                { name = "Preservation", cond = function(self) return Core.IsTanking() end, },
                { name = "TempHP",       cond = function(self) return Config:GetSetting('DoTempHP') end, },
                { name = "SteelProc",    cond = function(self) return Config:GetSetting('DoSteelProc') end, },
                { name = "HealStun", },
                { name = "HealNuke", },
                { name = "Dicho",        cond = function(self) return Config:GetSetting('DoDicho') end, },
                { name = "TwinHealNuke", cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "ReverseDS",    cond = function(self) return Config:GetSetting('DoReverseDS') < 3 end, },
                { name = "HealWard",     cond = function(self) return Core.IsTanking() end, },
                { name = "PurityCure",   cond = function(self) return Config:GetSetting('KeepPurityMemmed') end, },
                { name = "CureCorrupt",  cond = function(self) return Config:GetSetting('KeepCorruptMemmed') end, },
                { name = "BlessingProc", },
            },
        },
    },
    ['PullAbilities']     = {
        {
            id = 'StunTimer4',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('StunTimer4')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('StunTimer4')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('StunTimer4')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Audacity',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Audacity').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Audacity').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('Audacity')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'ForHonor',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('ForHonor').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('ForHonor').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('ForHonor')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']     = {
        --Mode
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Mode",
            Tooltip = "Select the active Combat Mode for this PC.",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes do?",
            Answer = "Tank Mode will focus on tanking and aggro, while DPS mode will focus on DPS. Both have a secondary focus of healing.",
        },

        --Buffs and Debuffs
        ['DoTempHP']          = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 3,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("TempHP") end,
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why do we have the Temp HP Buff always memorized?",
            Answer = "Temp HP buffs have a very long refresh time after scribing, making them infeasible to use if not gemmed.",
        },
        ['OverwriteDPUBuffs'] = {
            DisplayName = "Overwrite DPU Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 5,
            Tooltip = "Overwrite DPU with single buffs when they are better than the DPU effect.",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoVetAA']           = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 8,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoUndeadProc']      = {
            DisplayName = "Use Undead Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Use Undead proc over Fury proc until Fury is rolled into Divine Protector's Unity (Level 80).",
            Default = false,
        },
        ['DoSteelProc']       = {
            DisplayName = "Use Steel Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 3,
            Tooltip = "Use your Steel Proc line.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoBrells']          = {
            DisplayName = "Do Brells",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Enable Casting Brells",
            Default = true,
        },
        ['AegoSymbol']        = {
            DisplayName = "Aego/Symbol Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Choose whether to use the Aegolism or Symbol Line of HP Buffs.",
            Type = "Combo",
            ComboOptions = { 'Aegolism Line (Keeper)', 'Symbol Line', 'None', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoSalvation']       = {
            DisplayName = "Marr's Salvation",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your group hatred reduction buff AA (The Paladin will cancel it on themself if in Tank Mode).",
            Default = true,
            RequiresLoadoutChange = true,
        },

        --Hate Tools
        ['Timer4Choice']      = {
            DisplayName = "Use Timer 4 Stun",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use your Timer 4 'Force' line of stuns.",
            Default = mq.TLO.Me.Level() < 92 and true or false,
            RequiresLoadoutChange = true,
        },
        ['Timer5Choice']      = {
            DisplayName = "Timer 5 Choice:",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip =
            "Choose which Timer 5 spell line to use (For the best experience for leveling, the standard stun will be used until others are available.\nIt is recommended to switch this line out for the Timer 3 'Healstun' once it is available.).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Crush', 'Standard Stun', 'Disabled', },
            Default = mq.TLO.Me.Level() < 99 and 1 or 3,
            Min = 1,
            Max = 4,
            ConfigType = "Advanced",
        },
        ['Timer6Choice']      = {
            DisplayName = "Timer 6 Choice:",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 102,
            Tooltip = "Choose which Timer 6 spell line to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Crush', '"Lesson" Stun', 'Disabled', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoDicho']           = {
            DisplayName = "Cast Dicho",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 104,
            Tooltip = "Use your Dichotomic Hate/Stun/GroupHeal spell.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['AETauntAA']         = {
            DisplayName = "Use AE Taunt AA",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use AE Taunt AA.",
            Default = true,
            ConfigType = "Advanced",
        },

        --Defenses
        ['DiscCount']         = {
            DisplayName = "Def. Disc. Count",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 101,
            Tooltip = "Number of mobs around you before you use preemptively use Defensive Discs.",
            Default = 4,
            Min = 1,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['DefenseStart']      = {
            DisplayName = "Defense HP",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 102,
            Tooltip = "The HP % where we will use defensive actions like discs, epics, etc.\nNote that fighting a named will also trigger these actions.",
            Default = 60,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['EmergencyStart']    = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 103,
            Tooltip = "The HP % before all but essential rotations are cut in favor of emergency or defensive abilities.",
            Default = 40,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['HPCritical']        = {
            DisplayName = "HP Critical",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 104,
            Tooltip =
            "The HP % that we will use abilities like Lay on Hands or Gift of Life.\nMost other rotations are cut to give our full focus to survival.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },

        --Equipment
        ['DoChestClick']      = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoCharmClick']      = {
            DisplayName = "Do Charm Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your charm for Geomantra.",
            Default = false,
        },
        ['UseBandolier']      = {
            DisplayName = "Dynamic Weapon Swap",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 101,
            Tooltip = "Enable 1H+S/2H swapping based off of current health. ***YOU MUST HAVE BANDOLIER ENTRIES NAMED \"Shield\" and \"2Hand\" TO USE THIS FUNCTION.***",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['EquipShield']       = {
            DisplayName = "Equip Shield",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 102,
            Tooltip = "Under this HP%, you will swap to your \"Shield\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['Equip2Hand']        = {
            DisplayName = "Equip 2Hand",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 103,
            Tooltip = "Over this HP%, you will swap to your \"2Hand\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 75,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['NamedShieldLock']   = {
            DisplayName = "Shield on Named",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 104,
            Tooltip = "Keep Shield equipped for mobs detected as 'named' by RGMercs (see Named tab).",
            Default = true,
            FAQ = "Why does my PAL switch to a Shield on puny gray named?",
            Answer = "The Shield on Named option doesn't check levels, so feel free to disable this setting (or Bandolier swapping entirely) if you are farming fodder.",
        },
        ['DoTouchHeal']       = {
            DisplayName = "Touch Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Choose when the Paladin will use the single-target Touch-line healing spell.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Emergency Use(BigHeal)', 'Standard Use(MainHeal)', 'Never', },
            Default = mq.TLO.Me.Level() > 72 and 3 or 2,
            Min = 1,
            Max = 3,
        },
        ['DoLightHeal']       = {
            DisplayName = "Do Light Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your ToT heal ('... Light') line of spells.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoSelfHeal']        = {
            DisplayName = "Do Self Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your emergency self-heal line of spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoWaveHeal']        = {
            DisplayName = "Do Wave Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Use your group heal ('Wave of ...') line of spells.",
            RequiresLoadoutChange = true,
            Default = mq.TLO.Me.Level() < 83 and true or false,
        },
        ['KeepSplashMemmed']  = {
            DisplayName = "Mem Splash Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip =
            "Memorize your 'Splash' line AE heal/cure, and use it as a group heal or cure. (If unchecked, we may mem/use it out of combat as a cure, depending on other settings.)",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTwinHealNuke']    = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['KeepPurityMemmed']  = {
            DisplayName = "Mem Purity Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Memorize your Purity line (cure poi/dis/curse) when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if enabled.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['KeepCorruptMemmed'] = {
            DisplayName = "Mem Cure Corruption",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Memorize cure corruption spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if available.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['SplashHealAsCure']  = {
            DisplayName = "Use Splash Heal to Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 103,
            Tooltip = "If the Splash Heal is available, use it to cure detrimental effects.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoReverseDS']       = {
            DisplayName = "Reverse DS",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 101,
            Tooltip = "Choose when to use your Reverse DS ('Mark of ...') line of debuffs.",
            Type = "Combo",
            ComboOptions = { 'Always', 'Only on Named', 'Never', },
            Default = 3,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is an Alpha config, lacking playtesting.\n\n" ..
                "  The defaults are aimed towards late game live tanking, but it has the options for other modes or methods.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
