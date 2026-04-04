local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Comms        = require("utils.comms")
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version              = "2.2 - Live",
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
        -- this code is slightly ineffecient (we could just check for CureSpell once), but adding corruption or more options would have us change it back to this
        -- -- since it is only run at startup, i'm fine with it. - Algar 8/29/25
        GetCureSpells = function(self)
            --(re)initialize the table for loadout changes
            self.TempSettings.CureSpells = {}

            -- Find the map for each cure spell we need, given availability of curespell. fallback to individual cures
            local neededCures = {
                ['Poison'] = Casting.GetFirstMapItem({ "CureSpell", "CurePoison", }),
                ['Disease'] = Casting.GetFirstMapItem({ "CureSpell", "CureDisease", }),
                ['Curse'] = Casting.GetFirstMapItem({ "CureSpell", "CureCurse", }),
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
            if Config:GetSetting('DoCureAA') then
                if Casting.AAReady("Radiant Cure") then
                    return Casting.UseAA("Radiant Cure", targetId)
                end
            end
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
    },
    ['AbilitySets']       = {
        ["GroupFocusSpell"] = {
            -- Focus Spell - Group Spells will be used on everyone
            "Talisman of Unity X",        -- Level 130 - Group
            "Khura's Focusing",           -- Level 60 - Group
            "Focus of the Seventh",       -- Level 65 - Group
            "Talisman of Wunshi",         -- Level 70 - Group
            "Talisman of the Dire",       -- Level 75 - Group
            "Talisman of the Bloodworg",  -- Level 80 - Group
            "Talisman of Unity",          -- Level 85 - Group
            "Talisman of Soul's Unity",   -- Level 90 - Group
            "Talisman of Kolos' Unity",   -- Level 95 - Group
            "Talisman of the Courageous", -- Level 100 - Group
            "Talisman of the Doomscale",  -- Level 105 - Group
            "Talisman of the Wulthan",    -- Level 110 - Group
            "Talisman of the Ry'Gorr",    -- Level 115 - Group
            "Talisman of the Usurper",    -- Level 120 - Group
            "Talisman of the Heroic",     -- Level 125 - Group
        },
        ["RunSpeedBuff"] = {
            -- Run Speed Buff - 9 - 74
            "Spirit of Tala'Tak",
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
        ["TempHPBuff"] = {
            -- Growth Buff 81+
            "Wild Growth X",
            "Overwhelming Growth",
            "Fervent Growth",
            "Frenzied Growth",
            "Savage Growth",
            "Ferocious Growth",
            "Rampant Growth",
            "Unfettered Growth",
            "Untamed Growth",
            "Wild Growth",
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
            "Talisman of Foresight",
            "Preternatural Foresight",
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
            "Wind of Malisene",
            "Wind of Malis",
        },
        ["MaloSpell"] = {
            -- AA Starts at LVL 75
            "Malaise XVI",
            "Malosinera",
            "Malosinetra",
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
        ["CrippleSpell"] = {   --not currently utilized for groups, gem slots are precious
            "Crippling Spasm", -- Level 66
            "Cripple",         -- Level 53, Starts to become worth it, depending on target
            "Incapacitate",    -- Level 41, Likely not worth
            "Listless Power",  -- Level 29, Definitely not worth
        },
        ["GroupHealProcBuff"] = {
            "Mindful Spirit",
            "Watchful Spirit",
            "Attentive Spirit",
            "Responsive Spirit",
        },
        ["WardBuff"] = {
            -- Self Heal Ward Spells
            "Ward of Resurgence XI",
            "Ward of Heroic Deeds",
            "Ward of Recuperation",
            "Ward of Remediation",
            "Ward of Regeneration",
            "Ward of Rejuvenation",
            "Ward of Reconstruction",
            "Ward of Recovery",
            "Ward of Restoration",
            "Ward of Resurgence",
            "Ward of Rebirth",
        },
        ["DichoSpell"] = {
            "Reciprocal Roar",
            "Ecliptic Roar",
            "Composite Roar",
            "Dissident Roar",
            "Roar of the Lion",
        },
        ["MeleeProcBuff"] = {
            -- Melee Proc Buff - Level 50 - 111
            -- To be used when the Shaman does not have Dicho
            "Talisman of the Panther XVI",
            "Talisman of the Manul",
            "Talisman of the Kerran",
            "Talisman of the Lioness",
            "Talisman of the Sabretooth",
            "Talisman of the Leopard",
            "Talisman of the Snow Leopard",
            "Talisman of the Lion",
            "Talisman of the Tiger",
            "Talisman of the Lynx",
            "Talisman of the Cougar",
            "Talisman of the Panther",
            -- Below Level 71 This is a single target buff and will be keyed off of the MA
            "Spirit of the Panther",
            "Spirit of the Leopard",
            "Spirit of the Jaguar",
            "Spirit of the Puma",
        },
        ["SlowProcBuff"] = {
            -- Slow Proc Buff for MA - Level 68 - 122
            "Lassitude XIII",
            "Moroseness",
            "Melancholy",
            "Ennui",
            "Incapacity",
            "Sluggishness",
            "Fatigue",
            "Apathy",
            "Lethargy",
            "Listlessness",
            "Languor",
            "Lassitude",
            "Lingering Sloth",
        },
        ["PackSelfBuff"] = {
            -- Pack Self Buff - Level 90 - 115
            --- Ignoring the LVL 85 Call the Pack buff due to the decrease in mana per tick.
            "Pack of Dire Wolves",
            "Pack of Ancestral Beasts",
            "Pack of Lunar Wolves",
            "Pack of The Black Fang",
            "Pack of Mirtuk",
            "Pack of Olesira",
            "Pack of Kriegas",
            "Pack of Hilnaah",
            "Pack of Wurt",
        },
        ["AllianceBuff"] = {
            "Ancient Alliance",
            "Ancient Coalition",
            "Ancient Covariance",
        },
        ['RezSpell'] = {
            'Incarnate Anew', -- Level 59
        },
        ["RecklessHeal1"] = {
            "Reckless Mending VIII",
            "Reckless Reinvigoration",
            "Reckless Resurgence",
            "Reckless Renewal",
            "Reckless Rejuvenation",
            "Reckless Regeneration",
            "Reckless Restoration",
            "Reckless Remedy",
            "Reckless Mending",
            "Qirik's Mending",
            "Dannal's Mending",
            "Gemmi's Mending",
            "Ahnkaul's Mending",
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
        ["RecklessHeal2"] = {
            --worthless to mem two mendings because they don't have a recast time, keep Qirik's for when we don't have enough Reckless.
            "Reckless Mending VIII",
            "Reckless Reinvigoration",
            "Reckless Resurgence",
            "Reckless Renewal",
            "Reckless Rejuvenation",
            "Reckless Regeneration",
            "Reckless Restoration",
            "Reckless Remedy",
            "Reckless Mending",
            "Qirik's Mending",
        },
        ["RecklessHeal3"] = {
            --fallback just in case we have some other DPS stuff disabled, but 3 reckless is overkill for automation
            "Reckless Mending VIII",
            "Reckless Reinvigoration",
            "Reckless Resurgence",
            "Reckless Renewal",
            "Reckless Rejuvenation",
            "Reckless Regeneration",
            "Reckless Restoration",
            "Reckless Remedy",
            "Reckless Mending",
            "Qirik's Mending",
        },
        ["AESpiritualHeal"] = {
            -- Pulsing AE Heal, 100+
            "Spiritual Shower",
            "Spiritual Squall",
            "Spiritual Swell",
            "Spiritual Surge",
        },
        ["RecourseHeal"] = {
            --- RecourseHeal Level 87+
            "Baratu's Recourse",
            "Grayleaf's Recourse",
            "Rowain's Recourse",
            "Zrelik's Recourse",
            "Eyrzekla's Recourse",
            "Krasir's Recourse",
            "Blezon's Recourse",
            "Gotikan's Recourse",
            "Qirik's Recourse",
        },
        ["InterventionHeal"] = {
            -- Intervention Heal 78+
            "Ancestral Intervention XI",
            "Immortal Intervention",
            "Primordial Intervention",
            "Prehistoric Intervention",
            "Historian's Intervention",
            "Antecessor's Intervention",
            "Progenitor's Intervention",
            "Ascendant's Intervention",
            "Antecedent's Intervention",
            "Ancestral Intervention",
            "Antediluvian Intervention",
        },
        ["GroupRenewalHoT"] = {
            -- Prior to 70 Breath of Trushar, single HoTs will be used including the
            --- the Torpor/Stoicism line. LVL 44 is the lowest level.
            "Ghost of Renewal XIII",
            "Reverie of Renewal",
            "Spirit of Renewal",
            "Spectre of Renewal",
            "Cloud of Renewal",
            "Shear of Renewal",
            "Wisp of Renewal",
            "Phantom of Renewal",
            "Penumbra of Renewal",
            "Shadow of Renewal",
            "Shade of Renewal",
            "Specter of Renewal",
            "Ghost of Renewal",
            "Spiritual Serenity",
            "Breath of Trushar",
            "Quiescence",
            "Torpor",
            "Stoicism",
        },
        ["CanniSpell"] = {
            -- Convert Health to Mana - Level  23+
            "Ancestral Bargain XIV",
            "Traumatic Exchange",
            "Hoary Agreement",
            "Ancient Bargain",
            "Tribal Bargain",
            "Tribal Pact",
            "Ancestral Pact",
            "Ancestral Arrangement",
            "Ancestral Covenant",
            "Ancestral Obligation",
            "Ancestral Hearkening",
            "Ancestral Bargain",
            "Ancient: Ancestral Calling",
            "Pained Memory",
            "Ancient: Chaotic Pain",
            "Cannibalize IV",
            "Cannibalize III",
            "Cannibalize II",
            "Cannibalize",
        },
        ["CureSpell"] = {
            "Mastery: Blood of Mayong",
            "Blood of Mayong",
            "Blood of Tevik",
            "Blood of Rivans",
            "Blood of Sanera",
            "Blood of Klar",
            "Blood of Corbeth",
            "Blood of Avoling",
            "Blood of Nadox",
        },
        ['CureCorrupt'] = {
            "Mastery: Chant of the Zelniak",
            "Chant of the Zelniak",
            "Chant of the Wulthan",
            "Chant of the Kromtus",
            "Chant of Jaerol",
            "Chant of the Izon",
            "Chant of the Tae Ew",
            "Chant of the Burynai",
            "Chant of the Darkvine",
            "Chant of the Napaea",
            "Cure Corruption",
        },
        ["TwinHealNuke"] = {
            -- Nuke the MA Not the assist target - Levels 85+
            "Frost Gift X",
            "Gelid Gift",
            "Polar Gift",
            "Wintry Gift",
            "Frostbitten Gift",
            "Glacial Gift",
            "Frigid Gift",
            "Freezing Gift",
            "Frozen Gift",
            "Frost Gift",
        },
        ["PoisonNuke"] = {
            -- Poison Nuke LVL34 +
            "Tserik's Spear of Venom",
            "Red Eye's Spear of Venom",
            "Fleshrot's Spear of Venom",
            "Narandi's Spear of Venom",
            "Nexona's Spear of Venom",
            "Serisaria's Spear of Venom",
            "Slaunk's Spear of Venom",
            "Hiqork's Spear of Venom",
            "Spinechiller's Spear of Venom",
            "Severilous' Spear of Venom",
            "Vestax's Spear of Venom",
            "Ahnkaul's Spear of Venom",
            "Yoppa's Spear of Venom",
            "Spear of Torment",
            "Blast of Venom",
            "Shock of Venom",
            "Blast of Poison",
            "Shock of the Tainted",
        },
        ["FastPoisonNuke"] = {
            -- Fast Poison Nuke LVL73+
            "Tserik's Bite",
            "Oka's Bite",
            "Ander's Bite",
            "Direfang's Bite",
            "Mawmun's Bite",
            "Reefmaw's Bite",
            "Seedspitter's Bite",
            "Bite of the Grendlaen",
            "Bite of the Blightwolf",
            "Bite of the Ukun",
            "Bite of the Brownie",
            "Sting of the Queen",
        },
        ["IceNuke"] = {
            --- IceNuke - Level 4+
            "Frost Rift XX",
            "Ice Barrage",
            "Heavy Sleet",
            "Ice Salvo",
            "Ice Shards",
            "Ice Squall",
            "Ice Burst",
            "Ice Mass",
            "Ice Floe",
            "Ice Sheet",
            "Tundra Crumble",
            "Glacial Avalanche",
            "Ice Age",
            "Velium Strike",
            "Ice Strike",
            "Blizzard Blast",
            "Winter's Roar",
            "Frost Strike",
            "Spirit Strike",
            "Frost Rift",
        },
        ["ChaoticDot"] = {
            -- Long Dot(42s) LVL 104+
            -- Two resist types because it throws 2 dots
            -- Stacking: Nectar of Pain - Stacking: Blood of Saryrn
            "Chaotic Bloodcurse",
            "Chaotic Poison",
            "Chaotic Venom",
            "Chaotic Venin",
            "Chaotic Toxin",
        },
        ["PandemicDot"] = {
            -- Pandemic Dot Long Dot(84s) Level 103+
            -- Two resist types because it throws 2 dots
            -- Stacking: Kralbor's Pandemic  -    Stacking: Breath of Ultor
            "Hotariton Pandemic",
            "Tegi Pandemic",
            "Bledrek's Pandemic",
            "Elkikatar's Pandemic",
            "Hemocoraxius' Pandemic",
        },
        ["MaloDot"] = {
            -- Malo Dot Stacking: Yubai's Affliction - LongDot(96s) Level 99+
            "Torrentclaw's Malosinera",
            "Svartmane's Malosinara",
            "Rirwech's Malosinata",
            "Livio's Malosenia",
            "Falhotep's Malosenia",
            "Txiki's Malosinara",
            "Krizad's Malosinera",
        },
        ["CurseDot1"] = {
            -- Curse Dot 1 Stacking: Curse - Long Dot(30s) - Level 34+
            "Curse XVII",
            "Malediction",
            "Obeah",
            "Evil Eye",
            "Jinx",
            "Garugaru",
            "Naganaga",
            "Hoodoo",
            "Hex",
            "Mojo",
            "Pocus",
            "Juju",
            "Curse of Sisslak",
            "Bane",
            "Anathema",
            "Odium",
            "Curse",
        },
        ["CurseDot2"] = {
            ---, Stacking: Enalam's Curse - Long Dot(54s) - 100+
            "Maniadry's Curse",
            "Lenrel's Curse",
            "Marlek's Curse",
            "Erogo's Curse",
            "Sraskus' Curse",
            "Enalam's Curse",
            "Fandrel's Curse",
        },
        ["SaryrnDot"] = {
            -- Stacking: Blood of Saryrn - Long Dot(42s) - Level 8+
            "Blood of Torrentclaw",
            "Caustic Blood",
            "Desperate Vampyre Blood",
            "Restless Blood",
            "Reef Crawler Blood",
            "Phase Spider Blood",
            "Naeya Blood",
            "Spinechiller Blood",
            "Blood of Jaled'Dar",
            "Blood of Kerafyrm",
            "Vengeance of Ahnkaul",
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
            "Breath of Pustim",
            "Breath of the Hotariton",
            "Breath of the Tegi",
            "Breath of Bledrek",
            "Breath of Hemocoraxius",
            "Breath of Natigo",
            "Breath of Silbar",
            "Breath of the Shiverback",
            "Breath of Queen Malarian",
            "Breath of Big Bynn",
            "Breath of Ternsmochin",
            "Breath of Wunshi",
            "Breath of Ultor",
            "Pox of Bertoxxulous",
            "Plague",
            "Scourge",
            "Affliction",
            "Sicken",
        },
        ["AfflictionDot"] = {
            ---, Stacking: Yubai's Affliction - Long Dot(96s) - Level 9+, used on named only for hybrid
            "Torrentclaw's Affliction",
            "Krizad's Affliction",
            "Brightfeld's Affliction",
            "Svartmane's Affliction",
            "Rirwech's Affliction",
            "Livio's Affliction",
            "Falhotep's Affliction",
            "Yubai's Affliction",
        },
        ["NectarDot"] = { --almost never worth casting in a group, not currently gemmed.
            "Nectar of Pain XIII",
            "Nectar of Obscurity",
            "Nectar of Pain",
            "Nectar of Agony",
            "Nectar of Rancor",
            "Nectar of the Slitheren",
            "Nectar of Torment",
            "Nectar of Sholoth",
            "Nectar of Anguish",
            "Nectar of Woe",
            "Nectar of Suffering",
            "Nectar of Misery",
            "Nectar of Destitution",
        },
        ["PetSpell"] = {
            -- Pet Spell - 32+
            "Aramna's Faithful",
            "Suja's Faithful",
            "Diabo Sivuela's Faithful",
            "Grondo's Faithful",
            "Mirtuk's Faithful",
            "Olesira's Faithful",
            "Kriegas' Faithful",
            "Hilnaah's Faithful",
            "Wurt's Faithful",
            "Aina's Faithful",
            "Vegu's Faithful",
            "Kyrah's Faithful",
            "Farrel's Companion",
            "True Spirit",
            "Spirit of the Howler",
            "Frenzied Spirit",
            "Guardian spirit",
            "Vigilant Spirit",
            "Companion Spirit",
        },
        ["PetBuffSpell"] = {
            ---Pet Buff Spell - 50+
            "Spirit Bolstering V",
            "Spirit Augmentation",
            "Spirit Reinforcement",
            "Spirit Bracing",
            "Spirit Bolstering",
            "Spirit Quickening",
        },
        ["CureDisease"] = {
            "Cure Disease",
            "Counteract Disease",
            "Eradicate Disease",
        },
        ["CurePoison"] = {
            "Counteract Poison",
            "Abolish Poison",
            "Eradicate Poison",
        },
        ["CureCurse"] = {
            -- "Eradicate Curse",      -- Level 54 , 30 counters, twice, 400 mana
            "Remove Greater Curse", -- Level 54 , 9 counters, 5 times, 100 mana
            "Remove Curse",         -- Level 38
            "Remove Lesser Curse",  -- Level 24
            "Remove Minor Curse",   -- Level 9
        },
        ["GroupRegenBuff"] = {      --Does not stack with Dicho Regen
            "Talisman of Perseverance XV",
            "Talisman of the Unforgettable",
            "Talisman of the Tenacious",
            "Talisman of the Enduring",
            "Talisman of the Unwavering",
            "Talisman of the Faithful",
            "Talisman of the Steadfast",
            "Talisman of the Indomitable",
            "Talisman of the Reletntless",
            "Talisman of the Resolute",
            "Talisman of the Stalwart",
            "Talisman of the Stoic One",
            "Talisman of Perseverance",
            "Regrowth of Dar Khura", -- Level 56
        },
        ["SingleRegenBuff"] = {
            "Regrowth",
            "Chloroplast",
            "Regeneration", -- Level 22
        },
        ["ShrinkSpell"] = {
            "Tiny Terror",
            "Shrink",
        },
    },
    ['HelperFunctions']   = {
        DoRez = function(self, corpseId, ownerName)
            local rezAction = false
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
                elseif not Casting.CanUseAA("Rejuvenation of Spirit") and Casting.SpellReady(mq.TLO.Spell("Incarnate Anew"), true) then
                    rezAction = okayToRez and Casting.UseSpell("Incarnate Anew", corpseId, true, true)
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
            name = 'LowLevelHealPoint',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() < 65 end,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
        {
            name = 'GroupHealPoint',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 64 end,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 64 end,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target) end,
        },
        {
            name = 'MainHealPoint',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 64 end,
            cond = function(self, target) return Targeting.MainHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ["LowLevelHealPoint"] = {
            {
                name = "Call of the Ancients",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigHealsNeeded(target)
                end,
            },
            {
                name = "RecklessHeal1",
                type = "Spell",
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    if not Targeting.GroupedWithTarget(target) or not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ["GroupHealPoint"] = {
            {
                name = "InterventionHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.BigHealsNeeded(target) -- if multiples hurt with at least one in big heal range
                end,
            },
            {
                name = "Soothsayer's Intervention",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigGroupHealsNeeded() -- if multiples hurt with multiples in big heal range
                end,
            },
            {
                name = "RecourseHeal",
                type = "Spell",
            },
            {
                name = "AESpiritualHeal",
                type = "Spell",
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoChestClick') end,
                cond = function(self, itemName, target)
                    if not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Call of the Ancients",
                type = "AA",
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    if not Targeting.GroupedWithTarget(target) or not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ["BigHealPoint"] = {
            {
                name = "Ancestral Guard",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "InterventionHeal",
                type = "Spell",
            },
            {
                name = "Soothsayer's Intervention",
                type = "AA",
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
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
            { --if we hit this we need intervention back ASAP
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ["MainHealPoint"] = {
            {
                name = "RecourseHeal",
                type = "Spell",
            },
            {
                name = "AESpiritualHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsMA(target)
                end,
            },
            {
                name = "RecklessHeal1",
                type = "Spell",
            },
            {
                name = "RecklessHeal2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SpellLoaded(spell)
                end,
            },
            {
                name = "RecklessHeal3",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SpellLoaded(spell)
                end,
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
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
        { --Downtime buffs that don't need constant checks
            name = 'SlowDowntime',
            timer = 30,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and Casting.OkayToBuff() and Casting.AmIBuffable()
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
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal()) and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and
                    (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'ProcBuff',
            timer = 10,
            state = 1,
            steps = 1,
            load_cond = function(self) return self:GetResolvedActionMapItem('MeleeProcBuff') end,
            targetId = function(self) return { Core.GetMainAssistId(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'CombatBuff',
            timer = 10,
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (not Core.IsModeActive('Heal') or Core.OkayToNotHeal())
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (not Core.IsModeActive('Heal') or (Config:GetSetting('DoHealDPS') and Core.OkayToNotHeal()))
            end,
        },
    },
    ['Rotations']         = {
        ['ProcBuff'] = {
            {
                name = "DichoSpell",
                type = "Spell",
                load_cond = function(self) return Core.GetResolvedActionMapItem('DichoSpell') end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end --avoid constant group buff checks
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "MeleeProcBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('DichoSpell') end,
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
                name = "Spire of Ancestors",
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
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Malo'] = {
            {
                name = "Wind of Malaise",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAEMalo') and Casting.CanUseAA("Wind of Malaise") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "AEMaloSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAEMalo') and not Casting.CanUseAA("Wind of Malaise") end,
                cond = function(self, spell, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "Malaise",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTMalo') and Casting.CanUseAA("Malaise") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSTMalo') and not Casting.CanUseAA("Malaise") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow'] = {
            {
                name = "Turgur's Virulent Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and Casting.CanUseAA("Turgur's Virulent Swarm") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "AESlowSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAESlow') and not Casting.CanUseAA("Turgur's Virulent Swarm") end,
                cond = function(self, spell, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AESlowCount') and Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "Turgur's Swarm",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and Casting.CanUseAA("Turgur's Swarm") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') and not Casting.CanUseAA("Turgur's Swarm") end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSTSlow') or Casting.CanUseAA("Turgur's Swarm") then return false end
                    return Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "DiseaseSlow",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDiseaseSlow') end,
                waitReadyTime = function() return Config:GetSetting('DiseaseSlowWaitTime') end,
                cond = function(self, spell, target)
                    return not mq.TLO.Target.Slowed() and Casting.DetSpellCheck(spell) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
        ['CombatBuff'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "Cannibalization",
                type = "AA",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoAACanni') and Config:GetSetting('DoCombatCanni') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoSpellCanni') and Config:GetSetting('DoCombatCanni') end,
                cond = function(self, spell)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Casting.CanUseAA("Luminary's Synergy") and Config:GetSetting('DoHealOverTime') end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end
                    return Targeting.MobHasLowHP and spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 30
                end,
            },
        },
        ['DPS'] = {
            {
                name = "TwinHealNuke",
                type = "CustomFunc",
                load_cond = function(self) return Config:GetSetting('DoTwinHealNuke') and self:GetResolvedActionMapItem('TwinHealNuke') end,
                cond = function(self, spell, target)
                    if Casting.IHaveBuff("Healing Twincast") then return false end
                    local twinHeal = Core.GetResolvedActionMapItem("TwinHealNuke")
                    return Casting.CastReady(twinHeal)
                end,
                custom_func = function(self)
                    local twinHeal = Core.GetResolvedActionMapItem("TwinHealNuke")
                    Casting.UseSpell(twinHeal.RankName(), Core.GetMainAssistId(), false, false, 0)
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "ChaoticDot", "SaryrnDot", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPoisonDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "CurseDot2", "CurseDot1", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoCurseDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "PandemicDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDiseaseDot') end,
                cond = function(self, spell, target)
                    if Core.IsModeActive("Heal") and not Config:GetSetting('DoHealDPS') then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- for hybrid mode, which will use both curses if we have them
                name = "CurseDot1",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoCurseDot') and Core.IsModeActive("Hybrid") and Core.GetResolvedActionMapItem('CurseDot2') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- for hybrid mode, which loads this even after we get chaotic as a dot to use when chaotic is down
                name = "SaryrnDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPoisonDot') and Core.IsModeActive("Hybrid") and Core.GetResolvedActionMapItem('ChaoticDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "AfflictionDot", "UltorDot", })
                end,
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDiseaseDot') end,
                cond = function(self, spell, target)
                    return Globals.AutoTargetIsNamed and Casting.DotSpellCheck(spell)
                end,
            },
            { -- Calling "GetFirstMapItem" in a function so we don't need an entry for each of the below items... it simply chooses the "best"
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "FastPoisonNuke", "PoisonNuke", "IceNuke", })
                end,
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true)
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() ~= 0 end,
                cond = function(self, _) return Config:GetSetting('DoPet') and mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell)
                    local pet = mq.TLO.Me.Pet
                    if pet.ID() > 0 then
                        Comms.PrintGroupMessage("Summoned a new %d %s pet named %s using '%s'!", pet.Level(),
                            pet.Class.Name(), pet.CleanName(), spell.RankName())
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
                load_cond = function(self) return Config:GetSetting('DoAACanni') and Casting.CanUseAA('Cannibalization') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() < Config:GetSetting('AACanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('AACanniMinHP')
                end,
            },
            {
                name = "CanniSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSpellCanni') end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return mq.TLO.Me.PctMana() < Config:GetSetting('SpellCanniManaPct') and mq.TLO.Me.PctHPs() >= Config:GetSetting('SpellCanniMinHP')
                end,
            },
            {
                name = "GroupHealProcBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "GroupRenewalHoT",
                type = "Spell",
                cond = function(self, spell)
                    if not Casting.CanUseAA("Luminary's Synergy") or not Config:GetSetting('DoHealOverTime') or not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Song(spell).Duration.TotalSeconds() or 0) < 30
                end,
            },
            {
                name = "Preincarnation",
                type = "AA",
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName)
                        .Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "PetBuffSpell",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "Companion's Aegis",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
        },
        ['SlowDowntime'] = {
            {
                name = "Pact of the Wolf",
                type = "AA",
                active_cond = function(self, aaName) return mq.TLO.Me.Aura(aaName)() ~= nil end,
                cond = function(self, aaName)
                    return Config:GetSetting('DoAura') and not Casting.IHaveBuff(aaName) and
                        mq.TLO.Me.Aura(aaName)() == nil
                end,
            },
            {
                name = "Visionary's Unity",
                type = "AA",
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName)
                        .Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName) --Check ranks because we don't want the first pack buff (drains mana)
                    if (mq.TLO.Me.AltAbility(aaName).Rank() or 999) < 2 then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "PackSelfBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if (mq.TLO.Me.AltAbility("Visionary's Unity").Rank() or 999) > 1 then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "WardBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Config:GetSetting('DoSelfWard') then return false end
                    return Casting.SelfBuffCheck(spell)
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
                name = "TempHPBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTempHP') end,
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs("WAR", target) and Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SlowProcBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            { --Used on the entire group
                name = "GroupFocusSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            { --Only cast below 86 because past that our focus spells take over. Could check which unity we have, but expensive.
                name = "LowLvlAtkBuff",
                type = "Spell",
                load_cond = function(self) return mq.TLO.Me.Level() < 86 end,
                cond = function(self, spell, target)
                    return Targeting.TargetIsAMelee(target) and Casting.CastReady(spell) and
                        Casting.GroupBuffCheck(spell, target)
                end,
            },
            { -- Only cast below 111 because past that our focus spells take over. Could check which unity we have, but expensive.
                name = "Talisman of Celerity",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoHaste') and Casting.CanUseAA("Talisman of Celerity") and mq.TLO.Me.Level() < 111 end,
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
                name = "SingleRegenBuff",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('GroupRegenBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return (Targeting.TargetIsATank(target) or Targeting.TargetIsMyself(target)) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoGroupRegen') and not Core.GetResolvedActionMapItem('DichoSpell') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Lupine Spirit",
                type = "AA",
                -- We get Tala'tak at 74, but this doesn't use it until 90. Check Ranks.
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') and (mq.TLO.Me.AltAbility("Lupine Spirit").Rank() or -1) > 3 end,
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName, target)
                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "RunSpeedBuff",
                type = "Spell",
                -- We get Tala'tak at 74, but Lupine Spirit doesn't use it until 90. Check Ranks.
                load_cond = function(self) return Config:GetSetting('DoRunSpeed') and (mq.TLO.Me.AltAbility("Lupine Spirit").Rank() or -1) < 4 end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Group Shrink",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoGroupShrink') and Casting.CanUseAA("Group Shrink") end,
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
                -- Role-Critical
                { name = "RecklessHeal1", },
                { name = "RecourseHeal", },
                { name = "InterventionHeal", },
                { name = "AESpiritualHeal", },
                { name = "RecklessHeal2", },
                { name = "SlowSpell",         cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },          -- 27-77
                { name = "DiseaseSlow",       cond = function(self) return Config:GetSetting('DoDiseaseSlow') end, },
                { name = "AESlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Virulent Swarm") and Config:GetSetting('DoAESlow') end, }, -- 58-79
                { name = "MaloSpell",         cond = function(self) return not Casting.CanUseAA("Malaise") and Config:GetSetting('DoSTMalo') end, },                 -- 47-74
                { name = "AEMaloSpell",       cond = function(self) return not Casting.CanUseAA("Wind of Malaise") and Config:GetSetting('DoAEMalo') end, },         -- 84-94
                { name = "DichoSpell", },
                { name = "MeleeProcBuff",     cond = function(self) return not Core.GetResolvedActionMapItem('DichoSpell') end, },
                { name = "LowLvlAtkBuff",     cond = function(self) return mq.TLO.Me.Level() < 86 end, }, -- 60-85

                -- Utility
                { name = "CanniSpell",        cond = function(self) return Config:GetSetting('DoSpellCanni') end, },   -- 23 - ???
                { name = "GroupRenewalHoT",   cond = function(self) return Config:GetSetting('DoHealOverTime') end, }, -- 44-125 Heal
                { name = "SingleRegenBuff",   cond = function(self) return not Core.GetResolvedActionMapItem('GroupRegenBuff') end, },
                { name = "TempHPBuff",        cond = function(self) return Config:GetSetting('DoTempHP') end, },       -- 81-125
                { name = "CureSpell",         cond = function(self) return Config:GetSetting('MemCureSpell') end, },

                -- DPS
                { name = "ChaoticDot",        cond = function(self) return Config:GetSetting('DoPoisonDot') end, },                                                     -- 104-125
                { name = "SaryrnDot",         cond = function(self) return not Core.GetResolvedActionMapItem('ChaoticDot') and Config:GetSetting('DoPoisonDot') end, }, -- 8-?? Heal, 8-125 Hybrid
                { name = "PandemicDot",       cond = function(self) return Config:GetSetting('DoDiseaseDot') end, },                                                    -- 103-125
                { name = "TwinHealNuke",      cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },                                                  -- 85-125
                { name = "FastPoisonNuke",    cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "PoisonNuke",        cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('FastPoisonNuke') end, },
                { name = "IceNuke",           cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('PoisonNuke') end, },
                { name = "CurseDot2",         cond = function(self) return Config:GetSetting('DoCurseDot') end, },                                                          -- 100-125
                { name = "CurseDot1",         cond = function(self) return Config:GetSetting('DoCurseDot') and not Core.GetResolvedActionMapItem('CurseDot2') end, },       -- 34-??? Heal, 34-125 Hybrid
                { name = "AfflictionDot",     cond = function(self) return not Core.GetResolvedActionMapItem('PandemicDot') and Config:GetSetting('DoDiseaseDot') end, },   -- 92-125 (Boss Only)
                { name = "UltorDot",          cond = function(self) return not Core.GetResolvedActionMapItem('AfflictionDot') and Config:GetSetting('DoDiseaseDot') end, }, -- 4-91 (Boss Only)

                -- Filler
                { name = "CurePoison",        cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureDisease",       cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureCurse",         cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "GroupHealProcBuff", }, -- 101-125,
                { name = "RecklessHeal3", },
                { name = "SlowProcBuff", },
            },
        },
        {
            name = "Hybrid Mode",
            cond = function(self) return Core.IsModeActive("Hybrid") end,
            spells = {
                -- Role-Critical
                { name = "RecklessHeal1", },
                { name = "RecourseHeal", },
                { name = "InterventionHeal", },
                { name = "AESpiritualHeal", },
                { name = "SlowSpell",         cond = function(self) return not Casting.CanUseAA("Turgur's Swarm") and Config:GetSetting('DoSTSlow') end, },          -- 27-77
                { name = "DiseaseSlow",       cond = function(self) return Config:GetSetting('DoDiseaseSlow') end, },
                { name = "AESlowSpell",       cond = function(self) return not Casting.CanUseAA("Turgur's Virulent Swarm") and Config:GetSetting('DoAESlow') end, }, -- 58-79
                { name = "MaloSpell",         cond = function(self) return not Casting.CanUseAA("Malaise") and Config:GetSetting('DoSTMalo') end, },                 -- 47-74
                { name = "AEMaloSpell",       cond = function(self) return not Casting.CanUseAA("Wind of Malaise") and Config:GetSetting('DoAEMalo') end, },         -- 84-94
                { name = "DichoSpell", },
                { name = "MeleeProcBuff",     cond = function(self) return not Core.GetResolvedActionMapItem('DichoSpell') end, },
                { name = "LowLvlAtkBuff",     cond = function(self) return mq.TLO.Me.Level() < 86 end, },

                -- DPS
                { name = "ChaoticDot",        cond = function(self) return Config:GetSetting('DoPoisonDot') end, },                                                     -- 104-125
                { name = "SaryrnDot",         cond = function(self) return not Core.GetResolvedActionMapItem('ChaoticDot') and Config:GetSetting('DoPoisonDot') end, }, -- 8-?? Heal, 8-125 Hybrid
                { name = "PandemicDot",       cond = function(self) return Config:GetSetting('DoDiseaseDot') end, },                                                    -- 103-125
                { name = "FastPoisonNuke",    cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "PoisonNuke",        cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('FastPoisonNuke') end, },
                { name = "IceNuke",           cond = function(self) return Config:GetSetting('DoNuke') and not Core.GetResolvedActionMapItem('PoisonNuke') end, },
                { name = "CurseDot2",         cond = function(self) return Config:GetSetting('DoCurseDot') end, },                                                          -- 100-125
                { name = "CurseDot1",         cond = function(self) return Config:GetSetting('DoCurseDot') end, },                                                          -- 34-??? Heal, 34-125 Hybrid
                { name = "SaryrnDot",         cond = function(self) return Config:GetSetting('DoPoisonDot') end, },                                                         -- backup for if Chaotic is Down
                { name = "AfflictionDot",     cond = function(self) return Config:GetSetting('DoDiseaseDot') end, },                                                        -- 92-125 (Boss Only)
                { name = "UltorDot",          cond = function(self) return not Core.GetResolvedActionMapItem('AfflictionDot') and Config:GetSetting('DoDiseaseDot') end, }, -- 4-91 (Boss Only)
                { name = "PoisonNuke",        cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "TwinHealNuke",      cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },                                                      -- 85-125

                -- Utility, Filler
                { name = "CanniSpell",        cond = function(self) return Config:GetSetting('DoSpellCanni') end, },   -- 23 - ???
                { name = "GroupRenewalHoT",   cond = function(self) return Config:GetSetting('DoHealOverTime') end, }, -- 44-125 Heal
                { name = "SingleRegenBuff",   cond = function(self) return not Core.GetResolvedActionMapItem('GroupRegenBuff') end, },
                { name = "TempHPBuff",        cond = function(self) return Config:GetSetting('DoTempHP') end, },       -- 81-125
                { name = "TwinHealNuke",      cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, }, -- 85-125
                { name = "CureSpell",         cond = function(self) return Config:GetSetting('MemCureSpell') end, },
                { name = "CurePoison",        cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureDisease",       cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "CureCurse",         cond = function(self) return not Core.GetResolvedActionMapItem('CureSpell') and Config:GetSetting('MemCureSpell') end, },
                { name = "RecklessHeal2", },
                { name = "GroupHealProcBuff", }, -- 101-125,
                { name = "SlowProcBuff", },
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
            "Heal Mode: Primarily focuses on healing, cures, and maintaining HoTs. Secondary DPS focus with remaining spell gems. Hybrid: Prioritizes slightly more DPS at the expense of keeping a HoT, Cure Spell and second Reckless heal memorized.",
        },

        --DPS
        ['DoHealDPS']           = {
            DisplayName = "Heal Mode DPS",
            Group = "Abilities",
            Header = "Common",
            Category = "Common Rules",
            Index = 101,
            Tooltip = "This is a top-level setting that governs any DPS spells in heal mode, and can be used as a quick-toggle to enable/disable abilities without reloading spells.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "I feel that my Shaman is too concerned with DPS, dots and nukes, what can be done?",
            Answer = "Disabling Use HealDPS will stop the use of these spells. You can control which individual spells you mem with their respective settings.",
        },
        ['DoNuke']              = {
            DisplayName = "Use Nukes",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use a level-appropriate single-target nuke.\n" ..
                "Heal Mode: We will choose one avaiable nuke: Fast Poison (Bite) > Poison (Venom) > Ice.\n" ..
                "Hybrid Mode: Uses Fast Poison (Bite) and Poison (Venom), and Ice Nuke before they are available.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTwinHealNuke']      = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why am I using the Twin Heal Nuke?",
            Answer =
            "Due to the nature of automation, we are likely to have the time to do so, and it helps hedge our bets against spike damage. Drivers that manually target switch may wish to disable this setting to allow for more cross-dotting. ",
        },
        ['DoPoisonDot']         = {
            DisplayName = "Use Poison DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use one or more mode- and level-appropriate poison dots.\n" ..
                "Heal Mode: Saryrn line is used until Chaotic line is available.\n" ..
                "Hybrid Mode: Both Curse lines are used.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoDiseaseDot']        = {
            DisplayName = "Use Disease DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use one or more mode- and level-appropriate poison dots.\n" ..
                "Heal Mode: Uses the best of Pandemic > Afflicition > Ultor on named.\n" ..
                "Hybrid Mode: Uses Pandemic and Affliction on named, and Ultor before they are available.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoCurseDot']          = {
            DisplayName = "Use Curse DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use one or more mode- and level-appropriate curse dots.\n" ..
                "Heal Mode: Curse line is used until X's Curse line is available.\n" ..
                "Hybrid Mode: Both Curse lines are used.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        -- Healing
        ['DoHealOverTime']      = {
            DisplayName = "Use HoTs",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Heal Mode: Use Heal Over Time Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why does my Shaman randomly use HoTs in downtime?",
            Answer = "Maintaining HoTs prevents emergencies and hopefully allows for better DPS. It also grants Synergy Procs at high level.",
        },
        ['MemCureSpell']        = {
            DisplayName = "Mem Cure Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Mem your cure spells:\n" ..
                "Heal Mode: Prioritizes the combined cure spell. Memorizes others if able, if the combined spell isn't available.\n" ..
                "Hybrid Mode: Will memorize cure spells, if able, after other selected DPS spells have been prioritized.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoChestClick']        = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
            FAQ = "What the heck is a chest click?",
            Answer = "Most classes have useful abilities on their equipped chest after level 75 or so. The SHM's is generally a healing tool (emergency group heal).",
        },
        --Canni
        ['DoAACanni']           = {
            DisplayName = "Use AA Canni",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip = "Use Canni AA",
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
        --Buffs
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
            "For simplicity, the check to use it is keyed to the Shaman's height, rather than checking each group member. Also, the AA isn't available until level 80 (on official servers).",
        },
        ['DoTempHP']            = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use Temp HP Buff on Warriors in the group.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoAura']              = {
            DisplayName = "Use Aura",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Use Aura (Pact of Wolf)",
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoGroupRegen']        = {
            DisplayName = "Group Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Use your Group Regen buff.",
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoHaste']             = {
            DisplayName = "Use Haste",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Do Haste Spells/AAs",
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why aren't I casting Talisman of Celerity or other haste buffs?",
            Answer = "Even with Use Haste enabled, these buffs are part of your Focus spell (Unity) at very high levels, so they may not be needed.",
        },
        ['DoSelfWard']          = {
            DisplayName = "Do Self Ward",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use your Ward of... self-heal ward buff line.",
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
        --Debuffs
        ['DoSTMalo']            = {
            DisplayName = "Do ST Malo",
            Group = "Abilities",
            Header = "Debuff",
            Category = "Resist",
            Index = 101,
            Tooltip = "Do ST Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAEMalo']            = {
            DisplayName = "Do AE Malo",
            Group = "Abilities",
            Header = "Debuff",
            Category = "Resist",
            Index = 102,
            Tooltip = "Do AE Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSTSlow']            = {
            DisplayName = "Do ST Slow",
            Group = "Abilities",
            Header = "Debuff",
            Category = "Slow",
            Index = 101,
            Tooltip = "Do ST Slow Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAESlow']            = {
            DisplayName = "Do AE Slow",
            Group = "Abilities",
            Header = "Debuff",
            Category = "Slow",
            Index = 102,
            Tooltip = "Do AE Slow Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['AESlowCount']         = {
            DisplayName = "AE Slow Count",
            Group = "Abilities",
            Header = "Debuff",
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
            Header = "Debuff",
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
            Header = "Debuff",
            Category = "Slow",
            Index = 104,
            Tooltip = "Use Disease Slow instead of normal ST Slow",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
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
        ['DoLLHPBuff']          = {
            DisplayName = "HP Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLAgiBuff']         = {
            DisplayName = "Agility Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStaBuff']         = {
            DisplayName = "Stamina Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 109,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoLLStrBuff']         = {
            DisplayName = "Strength Buff (LowLvl)",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 110,
            Tooltip = "Use Low Level (<= 70) HP Buffs",
            Default = false,
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
