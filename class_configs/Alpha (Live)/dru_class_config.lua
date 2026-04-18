local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require('utils.globals')
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version              = "Alpha 1.2 - Live (Heal Mode Only)",
    _author               = "Algar (based on default by Derple)",
    ['ModeChecks']        = {
        IsHealing = function() return true end,
        IsCuring = function() return Config:GetSetting('DoCureAA') or Config:GetSetting('DoCureSpells') end,
        IsRezing = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },
    ['Modes']             = {
        'Heal',
    },
    ['Cures']             = {
        -- this code is slightly ineffecient since we only have SingleTgtCure here, but adding more options would have us change it back to this
        -- -- since it is only run at startup, i'm fine with it. - Algar 8/29/25
        GetCureSpells = function(self)
            --(re)initialize the table for loadout changes
            self.TempSettings.CureSpells = {}

            -- Find the map for each cure spell we need
            local neededCures = {
                ['Poison'] = Casting.GetFirstMapItem({ "GroupCure", "SingleTgtCure", }),
                ['Disease'] = Casting.GetFirstMapItem({ "GroupCure", "SingleTgtCure", }),
                ['Curse'] = Casting.GetFirstMapItem({ "GroupCure", "SingleTgtCure", }),
                ['Corruption'] = Casting.GetFirstMapItem({ "CureCorrupt", "SingleTgtCure", }),
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
            "Staff of Living Brambles",
            "Staff of Everliving Brambles",
        },
    },
    ['AbilitySets']       = {
        ['Alliance'] = {
            --, Buff >= LVL102
            "Bosquetender's Alliance,",
            "Arbor Tender's Coalition",
            "Arboreal Atonement",
            "Ferntender's Covariance",
        },
        ['FireAura'] = {
            -- Spell Series >= 87LVL Minimum
            "Wildspark Aura",
            "Wildblaze Aura",
            "Wildfire Aura",
        },
        ['IceAura'] = {
            -- Spell Series >= 88LVL Minimum -- Only Heroic Aura that will be used
            "Frostfell Aura IX",
            "Coldburst Aura",
            "Nightchill Aura",
            "Icerend Aura",
            "Frostreave Aura",
            "Frostweave Aura",
            "Frostone Aura",
            "Frostcloak Aura",
            "Frostfell Aura",
        },
        ['HealingAura'] = {
            -- Healing Aura >= 55
            "Aura of Life",
            "Aura of the Grove",
        },
        ['SingleTgtCure'] = {
            -- Single Target Multi-Cure >= 84
            "Mastery: Sanctified Blood",
            "Expurgated Blood",
            "Unblemished Blood",
            "Cleansed Blood",
            "Perfected Blood",
            "Purged Blood",
            "Purified Blood",
            "Sanctified Blood",
        },
        ['GroupCure'] = {
            -- Group Multi-Cure >=91
            "Mastery: Nightwhisper's Breeze",
            "Nightwhisper's Breeze",
            "Wildtender's Breeze",
            "Copsetender's Breeze",
            "Bosquetender's Breeze",
            "Fawnwalker's Breeze",
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
        ['QuickHealSurge'] = {
            -- Main Quick heal >=75
            "Adrenaline Surge XII",
            "Adrenaline Fury",
            "Adrenaline Spate",
            "Adrenaline Deluge",
            "Adrenaline Barrage",
            "Adrenaline Torrent",
            "Adrenaline Rush",
            "Adrenaline Flood",
            "Adrenaline Blast",
            "Adrenaline Burst",
            "Adrenaline Swell",
            "Adrenaline Surge",
            "Adrenaline Spate",
        },
        ['QuickHeal'] = {
            -- Backup Quick heal >= LVL90
            "Rejuvilation IX",
            "Resuscitation",
            "Sootheseance",
            "Rejuvenescence",
            "Revitalization",
            "Resurgence",
            "Vivification",
            "Invigoration",
            "Rejuvilation",
            "Sootheseance",
        },
        ['LongHeal'] = {
            -- Long Heal >= 1 -- skipped 10s cast heals.
            "Puravida XI",
            "Vivavida",
            "Clotavida",
            "Viridavida",
            "Curavida",
            "Panavida",
            "Sterivida",
            "Sanavida",
            "Benevida",
            "Granvida",
            "Puravida",
            "Pure Life",
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
        ['QuickGroupHeal'] = {
            -- Quick Group heal >= LVL78
            "Survival of the Fittest XI",
            "Survival of the Heroic",
            "Survival of the Unrelenting",
            "Survival of the Favored",
            "Survival of the Auspicious",
            "Survival of the Serendipitous",
            "Survival of the Fortuitous",
            "Survival of the Prosperous",
            "Survival of the Propitious",
            "Survival of the Felicitous",
            "Survival of the Fittest",
            "Survival of the Unrelenting",
        },
        ['LongGroupHeal'] = {
            -- Long Group heal >= LVL 70
            "Lunamend",
            "Lunacea",
            "Lunarush",
            "Lunalesce",
            "Lunasalve",
            "Lunasoothe",
            "Lunassuage",
            "Lunalleviation",
            "Lunamelioration",
            "Lunulation",
            "Crescentbloom",
            "Lunarlight",
            "Moonshadow",
            "Lunarush",
        },
        ['PromHeal'] = {
            -- Promised Heals Line Druid
            "Promised Reknit X",
            "Promised Regrowth",
            "Promised Reknit",
            "Promised Replenishment",
            "Promised Revitalization",
            "Promised Recovery",
            "Promised Regeneration",
            "Promised Rebirth",
            "Promised Refreshment",
            "Promised Revivification",
        },
        ['FrostDebuff'] = {
            -- Frost Debuff Series -- >= 74LVL -- On Bar
            "Gelid Frost XI",
            "Mythic Frost",
            "Primal Frost",
            "Restless Frost",
            "Glistening Frost",
            "Moonbright Frost",
            "Lustrous Frost",
            "Silver Frost",
            "Argent Frost",
            "Blanched Frost",
            "Gelid Frost",
            "Hoar Frost",
        },
        ['RoDebuff'] = {
            -- Ro Debuff Series -- >= 37LVL -- AA Starts at LVL (Single Target) -- On Bar Until AA
            "Grasp of Ro IX",
            "Clench of Ro",
            "Cinch of Ro",
            "Clasp of Ro",
            "Cowl of Ro",
            "Crush of Ro",
            "Cowl of Ro",
            "Clutch of Ro",
            "Grip of Ro",
            "Grasp of Ro",
            "Sun's Corona",
            "Ro's Illumination",
            "Ro's Smoldering Disjunction",
            "Fixation of Ro",
            "Ro's Fiery Sundering",
        },
        ['RoDebuffAE'] = {
            -- Ro AE Debuff Series -- >= 97LVL -- AA Starts at LVL
            "Pillar of Ro VII",
            "Visage of Ro",
            "Scrutiny of Ro",
            "Glare of Ro",
            "Gaze of Ro",
            "Column of Ro",
            "Pillar of Ro",
        },
        ['IceBreathDebuff'] = {
            -- Ice Breath Series >= 63LVL -- On Bar
            "Glacier Breath XIV",
            "Algid Breath",
            "Twilight Breath",
            "Icerend Breath",
            "Frostreave Breath",
            "Blizzard Breath",
            "Frosthowl Breath",
            "Encompassing Breath",
            "Bracing Breath",
            "Coldwhisper Breath",
            "Chillvapor Breath",
            "Icefall Breath",
            "Glacier Breath",
            "E`ci's Frosty Breath",
        },
        ['SkinDebuff'] = {
            -- Skin Debuff Series >= 73LVL -- On Bar
            "Skin to Lichen",
            "Skin to Sumac",
            "Skin to Seedlings",
            "Skin to Foliage",
            "Skin to Leaves",
            "Skin to Flora",
            "Skin to Mulch",
            "Skin to Vines",
        },
        ['ReptileCombatInnate'] = {
            -- Reptile Combat Innate >= 68LVL -- On Bar
            "Skin of the Reptile XII",
            "Chitin of the Reptile",
            "Bulwark of the Reptile",
            "Defense of the Reptile",
            "Guard of the Reptile",
            "Pellicle of the Reptile",
            "Husk of the Reptile",
            "Hide of the Reptile",
            "Shell of the Reptile",
            "Carapace of the Reptile",
            "Scales of the Reptile",
            "Skin of the Reptile",
        },
        ['NaturesWrathDot'] = {
            -- Natures Wrath DOT Line >= 75LVL -- On Bar
            "Nature's Blazing Wrath XII",
            "Nature's Fervid Wrath",
            "Nature's Blistering Wrath",
            "Nature's Fiery Wrath",
            "Nature's Withering Wrath",
            "Nature's Scorching Wrath",
            "Nature's Incinerating Wrath",
            "Nature's Searing Wrath",
            "Nature's Burning Wrath",
            "Nature's Blazing Wrath",
            "Nature's Sweltering Wrath",
            "Nature's Boiling Wrath",
        },
        ['HordeDot'] = {
            "Horde of Spitewasps",
            "Horde of Hotaria",
            "Horde of Duskwigs",
            "Horde of Hyperboreads",
            "Horde of Polybiads",
            "Horde of Aculeids",
            "Horde of Mutillids",
            "Horde of Vespids",
            "Horde of Scoriae",
            "Horde of the Hive",
            "Horde of Fireants",
            "Swarm of Fireants",
            "Wasp Swarm",
            "Swarming Death",
            "Winged Death",
            "Drifting Death",
            "Drones of Doom",
            "Creeping Crud",
            "Stinging Swarm",
        },
        ['SunDot'] = {
            -- SUN Dot Line >= 49LVL -- On Bar
            "Sunscorch XII",
            "Sunscald",
            "Sunpyre",
            "Sunshock",
            "Sunflame",
            "Sunflash",
            "Sunblaze",
            "Sunscorch",
            "Sunbrand",
            "Sunsinge",
            "Sunsear",
            "Sunscorch",
            "Vengeance of the Sun",
            "Vengeance of Tunare",
            "Vengeance of Nature",
            "Vengeance of the Wild",
        },
        ['MoonbeamDot'] = {
            "Gelid Moonbeam IX",
            "Mythical Moonbeam",
            "Onyx Moonbeam",
            "Opaline Moonbeam",
            "Pearlescent Moonbeam",
            "Argent Moonbeam",
            "Frigid Moonbeam",
            "Algid Moonbeam",
            "Gelid Moonbeam",
        },
        ['SunrayDot'] = {
            "Blistering Sunray XII",
            "Searing Sunray",
            "Tenebrous Sunray",
            "Erupting Sunray",
            "Overwhelming Sunray",
            "Consuming Sunray",
            "Incinerating Sunray",
            "Blazing Sunray",
            "Scorching Sunray",
            "Withering Sunray",
            "Torrid Sunray",
            "Blistering Sunray",
            "Immolation of the Sun",
            "Sylvan Embers",
            "Immolation of Ro",
            "Breath of Ro",
            "Immolate",
            "Flame Lick",
        },
        ['RemoteMoonDD'] = {
            -- Remote Moon DD >= 99LVL
            "Remote Moonfire VII",
            "Remote Moonshiver",
            "Remote Moonchill",
            "Remote Moonrake",
            "Remote Moonflash",
            "Remote Moonflame",
            "Remote Moonfire",
        },
        ['RemoteSunDD'] = {
            -- Remote Sun DD >= 83LVL
            "Remote Sunflare X",
            "Remote Sunscorch",
            "Remote Sunbolt",
            "Remote Sunshock",
            "Remote Sunblaze",
            "Remote Sunflash",
            "Remote Sunfire",
            "Remote Sunburst",
            "Remote Sunflare",
            "Remote Manaflux",
        },
        ['RoarDD'] = {
            -- Roar DD >= 93LVL
            "Katabatic Roar VIII",
            "Tempest Roar",
            "Bloody Roar",
            "Typhonic Roar",
            "Cyclonic Roar",
            "Anabatic Roar",
            "Katabatic Roar",
            "Roar of Kolos",
        },
        ['QuickRoarDD'] = {
            -- Quick Cast Roar Series -- will be replaced by roar at lvl 93
            "Shattering of the Stormborn",
            "Revelry of the Stormborn",
            "Bedlam of the Sotrmborn",
            "Maelstrom of the Stormborn",
            "Thunderbolt of the Stormborn",
            "Typhoon of the Stormborn",
            "Whirlwind of the Stormborn",
            "Cyclone of the Stormborn",
            "Shear of the Stormborn",
            "Squall of the Stormborn",
            "Tempest of the Stormborn",
            "Gale of the Stormborn",
            "Stormwatch",
            "Storm's Fury",
            "Dustdevil",
            "Fury of Air",
        },
        ['StunDD'] = {
            -- Quick Cast Roar Series -- will be replaced by roar at lvl 93
            "Maelstrom of the Stormborn",
            "Thunderbolt of the Stormborn",
            "Typhoon of the Stormborn",
            "Whirlwind of the Stormborn",
            "Cyclone of the Stormborn",
            "Shear of the Stormborn",
            "Squall of the Stormborn",
            "Tempest of the Stormborn",
            "Gale of the Stormborn",
            "Stormwatch",
            "Storm's Fury",
            --"Dustdevil", --Does not Stun
            "Fury of Air",
        },
        ['DichoSpell'] = {
            -- Dicho Spell >= 101LVL
            "Ecliptic Winds",
            "Composite Winds",
            "Dissident Winds",
            "Dichotomic Winds",
            "Reciprocal Winds",
        },
        ['WinterFireDD'] = {
            -- Winters Fire DD Line >= 73LVL -- Using for Low level Fire DD as well
            "Winder's Wildflame XII",
            "Winder's Wildgale",
            "Winter's Wildbrume",
            "Winter's Wildshock",
            "Winter's Wildblaze",
            "Winter's Wildflame",
            "Winter's Wildfire",
            "Winter's Sear",
            "Winter's Pyre",
            "Winter's Flare",
            "Winter's Blaze",
            "Winter's Flame",
            "Solstice Strike",
            "Sylvan Fire",
            "Summer's Flame",
            "Wildfire",
            "Scoriae",
            "Starfire",
            "Firestrike",
            "Combust",
            "Ignite",
            "Burst of Fire",
            "Burst of Flame",
        },
        ['ChillDot'] = {
            -- Chill DOT Line -- >= 95LVL -- Used for Burns
            "Chill of the Dusksage Tender",
            "Chill of the Arbor Tender",
            "Chill of the Wildtender",
            "Chill of the Copsetender",
            "Chill of the Visionary",
            "Chill of the Natureward",
        },
        ['RootSpells'] = {
            -- Root Spells
            "Vinelash Assault",
            "Vinelash Cascade",
            "Spore Spiral",
            "Savage Roots",
            "Earthen Roots",
            "Entrapping Roots",
            "Engorging Roots",
            "Engulfing Roots",
            "Enveloping Roots",
            "Ensnaring Roots",
            "Grasping Roots",
        },
        ['SnareSpell'] = {
            -- Snare Spells
            "Thornmaw Vines",
            "Hungry Vines",
            "Serpent Vines",
            "Entangle",
            "Mire Thorns",
            "Bonds of Tunare",
            "Ensnare",
            "Snare",
            "Tangling Weeds",
        },
        ['TwincastSpell'] = {
            "Twincast",
        },
        ['TwinHealNuke'] = {
            "Sundew Blessing X",
            "Sunbliss Blessing",
            "Sundew Blessing",
            "Sunrise Blessing",
            "Sunbreeze Blessing",
            "Sunbeam Blessing",
            "Sunfire Blessing",
            "Sunflash Blessing",
            "Sunrake Blessing",
            "Sunwarmth Blessing",
        },
        ['IceNuke'] = {
            "Rime Crystals XII",
            "Ice",
            "Frost",
            "Moonfire",
            "Winter's Frost",
            "Glitterfrost",
            "Rime Crystals",
            "Hoar Crystals",
            "Glaciating Crystals",
            "Argent Crystals",
            "Sterlingfrost Crystals",
            "Gelid Crystals",
            "Frostweave Crystals",
            "Frostreave Crystals",
            "Icerend Crystals",
            "Moonwhisper Crystals",
            "Coldbite Crystals",
        },
        ['IceRainNuke'] = {
            "Cascade of Hail XVIII",
            "Cascade of Hail",
            "Pogonip",
            "Avalanche",
            "Blizzard",
            "Winter's Storm",
            "Tempest Wind",
            "Cloudburst Hail",
            "Torrential Hail",
            "Cascading Hail",
            "Cyclonic Hail",
            "Crashing Hail",
            "Hailstorm",
            "Plummeting Hail",
            "Plunging Hail",
            "Tempestuous Hail",
            "Howling Hail",
            "Unrelenting Hail",
        },
        ['ShroomPet'] = {
            --Druid Mushroom DOT Pet Line >= 84LVL --used for mana savings
            "Mycelid Assault",
            "Saprophyte Assault",
            "Chytrid Assault",
            "Fungusoid Assault",
            "Sporali Storm",
            "Sporali Assault",
            "Myconid Assault",
            "Polyporous Assault",
            "Blast of Hypergrowth",
        },
        ['IceDD'] = {
            -- Ice Nuke DD --Gap Filler
            "Moonfire",
            "Frost",
        },
        ['SelfShield'] = {
            -- Self Shield Buff
            "Brackenbriar Coat",
            "Bramblespike Coat",
            "Shadespine Coat",
            "Icebriar Coat",
            "Daggerspike Coat",
            "Daggerspur Coat",
            "Spikethistle Coat",
            "Spineburr Coat",
            "Bonebriar Coat",
            "Brierbloom Coat",
            "Viridithorn Coat",
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
            -- Self mana Regen Buff
            "Mask of the Grovetender",
            "Mask of the Ferntender",
            "Mask of the Dusksage Tender",
            "Mask of the Arbor Tender",
            "Mask of the Wildtender",
            "Mask of the Copsetender",
            "Mask of the Bosquetender",
            "Mask of the Thicket Dweller",
            "Mask of the Arboreal",
            "Mask of the Raptor",
            "Mask of the Shadowcat",
            "Mask of the Wild",
            "Mask of the Forest",
            "Mask of the Stalker",
            "Mask of the Hunter",
        },
        ['HPTypeOneGroup'] = {
            "Grovewood Blessing",
            "Emberquartz Blessing",
            "Luclinite Blessing",
            "Opaline Blessing",
            "Arcronite Blessing",
            "Shieldstone Blessing",
            "Granitebark Blessing",
            "Stonebark Blessing",
            "Blessing of the Timbercore",
            "Blessing of the Heartwood",
            "Blessing of the Ironwood",
            "Blessing of the Direwild",
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
        ['TempHPBuff'] = {
            -- Temp Health -- Focus on Tank
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
        ['GroupRegenBuff'] = {
            -- Group Regen BuffAll Have Long Duration HP Regen Buffs. Not Short term Heal.
            "Talisman of Perseverance XV",
            "Talisman of the Unforgettable",
            "Talisman of the Tenacious",
            "Talisman of the Enduring",
            "Talisman of the Unwavering",
            "Talisman of the Faithful",
            "Talisman of the Steadfast",
            "Talisman of the Indomitable",
            "Talisman of the Relentless",
            "Talisman of the Resolute",
            "Talisman of the Stalwart",
            "Talisman of Perseverance",
            "Pack Regeneration",
            "Pack Chloroplast",
            "Regrowth of the Grove",
            "Blessing of Oak",
            "Blessing of Replenishment",
        },
        ['AtkBuff'] = {
            -- Single Target Attack Buff for MeleeGuard
            "Mammoth's Force",
            "Mammoth's Strength",
            "Lion's Strength",
            "Nature's Might",
            "Girdle of Karana",
            "Storm Strength",
            "Strength of Stone",
            "Strength of Earth",
        },
        ['GroupDmgShield'] = {
            -- Group Damage Shield -- Focus on the tank
            "Legacy of Brackenbriars",
            "Legacy of Icebriars",
            "Legacy of Daggerspikes",
            "Legacy of Daggerspurs",
            "Legacy of Spikethistles",
            "Legacy of Spineburrs",
            "Legacy of Bonebriar",
            "Legacy of Brierbloom",
            "Legacy of Viridithorns",
            "Legacy of Viridiflora",
            "Legacy of Nettles",
            "Legacy of Bracken",
            "Legacy of Thorn",
            "Legacy of Spike",
            -- Group Damage Shield -- Combined all single and group dammage shields.
            "Legacy of Bloodspikes",
            "Legacy of Icebriars",
            "Icebriar Bulwark",
            "Legacy of Daggerspikes",
            "Daggerspike Bulwark",
            "Legacy of Daggerspurs",
            "Daggerspur Bulwark",
            "Legacy of Spikethistles",
            "Spikethistle Bulwark",
            "Legacy of Spineburrs",
            "Spineburr Bulwark",
            "Legacy of Bonebriar",
            "Bonebriar Bulwark",
            "Legacy of Brierbloom",
            "Brierbloom Bulwark",
            "Legacy of Viridithorns",
            "Viridifloral Bulwark",
            "Legacy of Viridiflora",
            "Viridifloral Shield",
            "Legacy of Nettles",
            "Legacy of Bracken",
            "Shield of Bracken",
            "Legacy of Thorn",
            "Shield of Blades",
            "Legacy of Spike",
            "Shield of Thorns",
            "Shield of Spikes",
            "Shield of Brambles",
            "Shield of Barbs",
            "Shield of Thistles",
        },
        ['MoveSpells'] = {
            "Spirit of Wolf",
            "Pack Spirit",
            "Spirit of Eagle",
            "Flight of Eagles",
            "Spirit of Falcons",
            "Flight of Falcons",
        },
        ['ManaBear'] = {
            --Druid Mana Bear Growth Line
            "Nurturing Growth",
            "Nourishing Growth",
            "Sustaining Growth",
            "Bolstered Growth",
            "Emboldened Growth",
        },
        ['PetSpell'] = {
            "Nature Walker's Behest",
        },
        ['CharmSpell'] = {
            -- Charm Spells >= 14
            "Beast's Beckoning XVIII",
            "Beast's Bestowing",
            "Beast's Bellowing",
            "Beast's Beckoning",
            "Beast's Beseeching",
            "Beast's Bidding",
            "Beast's Bespelling",
            "Beast's Behest",
            "Beast's Beguiling",
            "Beast's Befriending",
            "Beast's Bewitching",
            "Beast's Beckoning",
            "Nature's Beckon",
            "Command of Tunare",
            "Tunare's Request",
            "Call of Karana",
            "Allure of the Wild",
            "Beguile Animals",
            "Charm Animals",
            "Befriend Animal",
        },
        ['Barkspur'] = {
            "Barkspur XIII",
            "Frondbarb",
            "Duskthorn",
            "Vinespike",
            "Thornspike",
            "Daggerthorn",
            "Stemfang",
            "Vinespur",
            "Thornspur",
            "Frondspur",
            "Fernspike",
            "Fernspur",
            "Barkspur",
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
                name = "QuickGroupHeal",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Wildtender's Survival",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Convergence of Spirits",
                type = "AA",
            },
            {
                name = "Blessing of Tunare",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target)
                end,
            },
            {
                name = "Apothic Dragon Spine Hammer",
                type = "Item",
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['GroupHealPoint'] = {
            {
                name = "Blessing of Tunare",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "QuickGroupHeal",
                type = "Spell",
            },
            {
                name = "Wildtender's Survival",
                type = "AA",
            },
            {
                name = "LongGroupHeal",
                type = "Spell",
            },
        },
        ['MainHealPoint'] = {
            {
                name = "QuickHeal",
                type = "Spell",
            },
            {
                name = "QuickHealSurge",
                type = "Spell",
            },
            {
                name = "LongHeal",
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
            steps = 2,
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
            name = 'HealBurn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and Core.OkayToNotHeal()
            end,
        },
        {
            name = 'TwinHeal',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoTwinHeal') and self:GetResolvedActionMapItem('TwinHealNuke') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
        {
            name = 'Barkspur',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoBarkspur') and self:GetResolvedActionMapItem('Barkspur') end,
            targetId = function(self) return { Core.GetMainAssistId(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
        {
            name = 'HealDPS(71+)',
            state = 1,
            steps = 1,
            load_cond = function() return mq.TLO.Me.Level() > 70 end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal()
            end,
        },
        {
            name = 'HealDPS(1-70)',
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
        ['HealDPS(71+)'] = {
            {
                name = "NaturesWrathDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoNatureDot') end,
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "SunDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSunDot') end,
                cond = function(self, spell)
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "HordeDot",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoHordeDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell) and (Casting.GOMCheck() or Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "DichoSpell",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.OkayToNuke() and Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
            {
                name = "RemoteSunDD",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.LightHealsNeeded(mq.TLO.Me.TargetOfTarget)
                end,
            },
            {
                name = "Nature's Frost",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Fire",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Bolt",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke(true)
                end,
            },
        },
        ['HealDPS(1-70)'] = {
            {
                name = "StunDD",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke(true) and Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "WinterFireDD",
                type = "Spell",
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Frost",
                type = "AA",
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Fire",
                type = "AA",
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
            {
                name = "Nature's Bolt",
                type = "AA",
                cond = function(self)
                    return Casting.OkayToNuke(true)
                end,
            },
        },
        ['HealBurn'] = {
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoChestClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Distant Conflagration",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
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
                name = "Group Spirit of the Great Wolf",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Destructive Vortex",
                type = "AA",
            },
            {
                name = "Nature's Fury",
                type = "AA",
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
                name = "Spirit of Nature",
                type = "AA",
            },
            {
                name = "Spire of Nature",
                type = "AA",
            },
            {
                name = "TwincastSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTwincast') end,
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
        },
        ['TwinHeal'] = {
            {
                name = "TwinHealNuke",
                type = "CustomFunc",
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
        },
        ['Debuff'] = {
            {
                name = "Blessing of Ro",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoRoDebuff') then return false end
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and Casting.ReagentCheck(aaSpell and aaSpell.Trigger(1) or aaName)
                end,
            },
            {
                name = "Season's Wrath",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "RoDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoRoDebuff') or Casting.CanUseAA("Blessing of Ro") then return false end
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "Swarm of Fireflies",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "GroupDmgShield",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Spirit of Eagles",
                type = "AA",
                active_cond = function(self, aaName)
                    return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1).ID())
                end,
                cond = function(self, aaName, target)
                    local bookSpell = self:GetResolvedActionMapItem('MoveSpells')
                    local aaSpell = Casting.GetAASpell(aaName)
                    if Config.TempSettings.NoLevZone then return false end
                    if not Config:GetSetting('DoMoveBuffs') or (bookSpell and bookSpell.Level() or 999) > (aaSpell.Level() or 0) then return false end

                    return Casting.GroupBuffAACheck(aaName, target)
                end,
            },
            {
                name = "MoveSpells",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if Config.TempSettings.NoLevZone then return false end
                    local aaSpellLvl = mq.TLO.Me.AltAbility("Spirit of Eagles").Spell.Trigger(1).Level() or 0
                    if not Config:GetSetting("DoMoveBuffs") or aaSpellLvl >= (spell.Level() or 0) then return false end
                    return Casting.GroupBuffCheck(spell, target)
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
                name = "TempHPBuff",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTempHP') end,
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs("WAR", target) and Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HPTypeOneGroup",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoHPBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ReptileCombatInnate",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.TargetClassIs({ "WAR", "SHD", }, target) and Casting.GroupBuffCheck(spell, target) --does not stack with PAL innate buff
                end,
            },
            {
                name = "GroupRegenBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoGroupRegen') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Wrath of the Wild",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.TargetIsATank(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "IceAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell) return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName())) end,
            },
            {
                name = "HealingAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    if self:GetResolvedActionMapItem('IceAura') then return false end
                    return (spell and spell() and not Casting.AuraActiveByName(spell.BaseName()))
                end,
            },
            {
                name = "ManaBear",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return (spell and spell() and spell.MyCastTime() or 999999) < 30000 end,
            },
            {
                name = "Group Spirit of the Great Wolf",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Spirit of the Great Wolf",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName) and mq.TLO.Me.AltAbility(aaName).Spell.RankName.Stacks()
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
            {
                name = "Preincarnation",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
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
        ['Barkspur'] = {
            {
                name = "Barkspur",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.GroupBuffCheck(spell, target, false, true)
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Heal Mode",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "LongHeal", },
                { name = "QuickHealSurge",      cond = function(self) return mq.TLO.Me.Level() >= 75 end, },
                { name = "QuickHeal",           cond = function(self) return mq.TLO.Me.Level() >= 90 end, },
                { name = "QuickGroupHeal",      cond = function(self) return mq.TLO.Me.Level() >= 90 end, },
                { name = "LongGroupHeal",       cond = function(self) return mq.TLO.Me.Level() >= 70 end, },
                { name = "SnareSpell",          cond = function(self) return Config:GetSetting("DoSnare") and not Casting.CanUseAA("Entrap") end, },
                { name = "RoDebuff",            cond = function(self) return not Casting.CanUseAA("Blessing of Ro") end, },
                { name = "TwincastSpell",       cond = function(self) return Config:GetSetting("DoTwincast") end, },
                { name = "DichoSpell",          cond = function(self) return mq.TLO.Me.Level() >= 101 end, },
                { name = "RemoteSunDD",         cond = function(self) return mq.TLO.Me.Level() >= 83 end, },
                { name = "NaturesWrathDot",     cond = function(self) return Config:GetSetting("DoNatureDot") end, },
                { name = "SunDot",              cond = function(self) return Config:GetSetting("DoSunDot") end, },
                { name = "HordeDot",            cond = function(self) return Config:GetSetting("DoHordeDot") end, },
                { name = "TwinHealNuke",        cond = function(self) return Config:GetSetting("DoTwinHeal") end, },
                { name = "StunDD",              cond = function(self) return mq.TLO.Me.Level() < 71 end, },
                { name = "WinterFireDD",        cond = function(self) return mq.TLO.Me.Level() < 71 end, },
                { name = "TempHPBuff",          cond = function(self) return Config:GetSetting('DoTempHP') end, },
                { name = "Barkspur",            cond = function(self) return Config:GetSetting('DoBarkspur') end, },
                { name = "ReptileCombatInnate", },
                { name = "GroupCure", },
            },
        },
    },
    ['Helpers']           = {
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
    --TODO: These are nearly all in need of Display and Tooltip updates.
    ['DefaultConfig']     = {
        ['Mode']         = { DisplayName = "Mode", Category = "Combat", Tooltip = "Select the Combat Mode for this Toon", Type = "Custom", RequiresLoadoutChange = true, Default = 1, Min = 1, Max = 3, },
        --TODO: This is confusing because it is actually a choice between fire and ice and should be rewritten (need time to update conditions above)
        ['DoFire']       = {
            DisplayName = "Orphaned",
            Type = "Custom",
            Category = "Orphaned",
            Tooltip = "Orphaned setting from live, no longer used in this config.",
            Default = true,
        },
        ['DoRain']       = {
            DisplayName = "Orphaned",
            Type = "Custom",
            Category = "Orphaned",
            Tooltip = "Orphaned setting from live, no longer used in this config.",
            Default = false,
        },
        ['DoMoveBuffs']  = {
            DisplayName = "Do Movement Buffs",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Cast Movement Spells/AA.",
            Default = false,
            FAQ = "Why am I spamming movement buffs?",
            Answer = "Some move spells freely overwrite those of other classes, so if multiple movebuffs are being used, a buff loop may occur.\n" ..
                "Simply turn off movement buffs for the undesired class in their class options.",
        },
        ['DoNuke']       = {
            DisplayName = "Orphaned",
            Type = "Custom",
            Category = "Orphaned",
            Tooltip = "Orphaned setting from live, no longer used in this config.",
            Default = false,
        },
        ['NukePct']      = {
            DisplayName = "Orphaned",
            Type = "Custom",
            Category = "Orphaned",
            Tooltip = "Orphaned setting from live, no longer used in this config.",
            Default = false,
        },
        ['DoChestClick'] = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Click your chest item",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoDot']        = {
            DisplayName = "Orphaned",
            Type = "Custom",
            Category = "Orphaned",
            Tooltip = "Orphaned setting from live, no longer used in this config.",
            Default = false,
        },
        ['DoTwinHeal']   = {
            DisplayName = "Cast Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoHordeDot']   = {
            DisplayName = "Horde Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Tooltip = "Use Horde Dot on named or a GoM proc.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoNatureDot']  = {
            DisplayName = "Horde Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Tooltip = "Use your Nature's Wrath line Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSunDot']     = {
            DisplayName = "Horde Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Tooltip = "Use your Sun line Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoHPBuff']     = {
            DisplayName = "Group HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your group HP Buff. Disable as desired to prevent conflicts with CLR or PAL buffs.",
            Default = true,
            FAQ = "Why am I in a buff war with my Paladin or Druid? We are constantly overwriting each other's buffs.",
            Answer = "Disable [DoHPBuff] to prevent issues with Aego/Symbol lines overwriting. Alternatively, you can adjust the settings for the other class instead.",
        },
        ['DoTempHP']     = {
            DisplayName = "Temp HP Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use Temp HP Buff (Only for WAR, other tanks have their own)",
            RequiresLoadoutChange = true,
            Default = false,
            FAQ = "Why isn't my Temp HP Buff being used?",
            Answer = "You either have [DoTempHP] disabled, or you don't have a Warrior in your group (Other tanks have their own Temp HP Buff).",
        },
        ['DoGroupRegen'] = {
            DisplayName = "Group Regen Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your Group Regen buff.",
            Default = true,
            FAQ = "Why am I spamming my Group Regen buff?",
            Answer = "Certain Shaman and Druid group regen buffs report cross-stacking. You should deselect the option on one of the PCs if they are grouped together.",
        },
        ['DoTwincast']   = {
            DisplayName = "Use Twincast Spell",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Use your Twincast spell during burns.",
            Default = false,
        },
        ['DoRunSpeed']   = {
            DisplayName = "Orphaned",
            Type = "Custom",
            Category = "Orphaned",
            Tooltip = "Orphaned setting from live, no longer used in this config.",
            Default = true,
        },
        ['DoSnare']      = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']   = {
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
        ['DoRoDebuff']   = {
            DisplayName = "Use Ro Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use Ro Debuff",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoBarkspur']   = {
            DisplayName = "Use Barkspur",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your short duration damage shield (Barkspur line) on the MA during combat.",
            RequiresLoadoutChange = true,
            Default = false,
        },
    },
    ['ClassFAQ']          = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is an Alpha config aimed at late game live.\n\n" ..
                "  It should perform well as a healer, but may be lacking typical options or configuration.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
