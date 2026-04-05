--- @type Mq
local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Strings      = require("utils.strings")
local Logger       = require("utils.logger")
local ItemManager  = require('utils.item_manager')
local Combat       = require("utils.combat")

local Tooltips     = {
    Epic            = 'Item: Casts Epic Weapon Ability',
    RunBuffSong     = "Song Line: Movement Speed Modifier",
    AriaSong        = "Song Line: Spell Damage Focus / Haste v3 Modifier",
    WarMarchSong    = "Song Line: Melee Haste / DS / STR/ATK Increase",
    SufferingSong   = "Song Line: Melee Proc With Damage and Aggro Reduction",
    SpitefulSong    = "Song Line: Increase AC / Aggro Increase Proc",
    SprySonataSong  = "Song Line: Magic Asorb / AC Increase / Mitigate Damage Shield / Resist Spells",
    DotBuffSong     = "Song Line: Fire and Magic DoT Modifier",
    CrescendoSong   = "Song Line: Group v2 Increase Hit Points and Mana",
    ArcaneSong      = "Song Line: Group Melee and Spell Proc",
    InsultSong      = "Song Line: Single Target DD (Group Spell Proc Effect at higher levels)",
    DichoSong       = "Song Line: HP/Mana/End Increase / Melee and Caster Damage Increase",
    BardDPSAura     = "Aura Line: OverHaste / Melee and Caster DPS",
    BardRegenAura   = "Aura Line: HP/Mana Regen",
    AreaRegenSong   = "Song Line: AE HP/Mana Regen",
    GroupRegenSong  = "Song Line: Group HP/Mana Regen",
    FireBuffSong    = "Song Line: Fire DD Spell Damage Increase and Effiency",
    SlowSong        = "Song Line: ST Melee Attack Slow",
    AESlowSong      = "Song Line: PBAE Melee Attack Slow",
    AccelerandoSong = "Song Line: Reduce Beneficial Spell Casttime / Aggro Reduction Modifier",
    RecklessSong    = "Song Line: Increase Crit Heal and Crit HoT Chance",
    ColdBuffSong    = "Song Line: Cold DD Damage Increase and Effiency",
    FireDotSong     = "Song Line: Fire DoT and minor resist debuff",
    DiseaseDotSong  = "Song Line: Disease DoT and minor resist debuff",
    PoisonDotSong   = "Song Line: Poison DoT and minor resist debuff",
    IceDotSong      = "Song Line: Ice DoT and minor resist debuff",
    EndBreathSong   = "Song Line: Enduring Breath",
    CureSong        = "Song Line: Single Target Cure: Poison/Disease/Corruption",
    AllianceSong    = "Song Line: Mob Debuff Increase Insult Damage for other Bards",
    CharmSong       = "Song Line: Charm Mob",
    ReflexStrike    = "Disc Line: Attack 4 times to restore Mana to Group",
    ChordsAE        = "Song Line: PBAE Damage if Target isn't moving",
    AmpSong         = "Song Line: Increase Singing Skill",
    DispelSong      = "Song Line: Dispel a Benefical Effect",
    ResistSong      = "Song Line: Damage Shield / Group Resist Increase",
    MezSong         = "Song Line: Single Target Mez",
    MezAESong       = "Song Line: PBAE Mez",
    Bellow          = "AA: DD + Resist Debuff that leads to a much larger DD upon expiry",
    Spire           = "AA: Lowers Incoming Melee Damage / Increases Melee and Spell Damage",
    FuneralDirge    = "AA: DD / Increases Melee Damage Taken on Target",
    FierceEye       = "AA: Increases Base and Crit Melee Damage / Increase Proc Rate / Increase Spell Crit Chance",
    QuickTime       = "AA: Hundred Hands Effect / Increase Melee Hit / Increase Atk",
    BladedSong      = "AA: Reverse Damage Shield",
    Jonthan         = "Song Line: (Self-only) Haste / Melee Damage Modifier / Melee Min Damage Modifier / Proc Modifier",
}

local _ClassConfig = {
    _version            = "2.3 - Live",
    _author             = "Algar, Derple, Grimmier, Tiddliestix, SonicZentropy",
    ['Modes']           = {
        'General',
    },

    ['ModeChecks']      = {
        CanMez     = function() return true end,
        CanCharm   = function() return true end,
        IsMezzing  = function() return Config:GetSetting('MezOn') end,
        IsCuring   = function() return Config:GetSetting('UseCure') end,
        IsCharming = function() return Config:GetSetting('CharmOn') and mq.TLO.Pet.ID() == 0 end,
    },
    ['Cures']           = {
        CureNow = function(self, type, targetId)
            local targetSpawn = mq.TLO.Spawn(targetId)
            if not targetSpawn and targetSpawn() then return false, false end

            local cureSong = Core.GetResolvedActionMapItem('CureSong')
            local downtime = mq.TLO.Me.CombatState():lower() ~= "combat"
            if type:lower() == ("disease" or "poison") and Casting.SongReady(cureSong, downtime) then
                Logger.log_debug("CureNow: Using %s for %s on %s.", cureSong.RankName(), type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
                return Casting.UseSong(cureSong.RankName.Name(), targetId, downtime), true
            end
            Logger.log_debug("CureNow: No valid cure at this time for %s on %s.", type:lower() or "unknown", targetSpawn.CleanName() or "Unknown")
            return false, false
        end,
    },
    ['ItemSets']        = {
        ['Epic'] = {
            "Blade of Vesagran",
            "Prismatic Dragon Blade",
        },
        ['Coating'] = {
            "Spirit Drinker's Coating",
            "Blood Drinker's Coating",
        },
    },
    ['AbilitySets']     = {
        ['RunBuffSong'] = {
            -- Selo's Accelerato not used so that we don't go back to a short duration
            -- Other songs omitted due to issues with constant reinvis, etc.
            "Selo's Accelerating Chorus",
            "Selo's Accelerando",
        },
        ['EndBreathSong'] = {
            "Tarew's Aquatic Ayre", --Level 16
        },
        ['AriaSong'] = {
            "Aria of Kenburk",
            "Aria of Tenisbre", -- 125
            "Aria of Pli Xin Liako",
            "Aria of Margidor",
            "Aria of Begalru",
            "Aria of Maetanrus",
            "Aria of Va'Ker",
            "Aria of the Orator",
            "Aria of the Composer",
            "Aria of the Poet",
            "Performer's Psalm of Pyrotechnics",
            "Ancient: Call of Power",
            "Aria of the Artist",
            "Yelhun's Mystic Call",
            "Ancient: Call of Power",
            "Eriki's Psalm of Power",
            "Echo of the Trusik",
            "Rizlona's Call of Flame",   -- overhaste/spell damage, level 64
        },
        ['OverhasteSong'] = {            -- before effects are combined in aria
            "Warsong of the Vah Shir",   -- overhaste only, level 60
            "Battlecry of the Vah Shir", -- overhaste only, level 52
        },
        ['SpellDmgSong'] = {             -- before effects are combined in aria
            "Rizlona's Fire",            -- spell damage only, level 53
            "Rizlona's Embers",          -- spell damage only, level 45
        },
        ['SufferingSong'] = {
            "Sorrowful Song of Suffering IX",
            "Kanghammer's Song of Suffering", -- 125
            "Shojralen's Song of Suffering",
            "Omorden's Song of Suffering",
            "Travenro's Song of Suffering",
            "Fjilnauk's Song of Suffering",
            "Kaficus' Song of Suffering",
            "Hykast's Song of Suffering",
            "Noira's Song of Suffering",
            "Storm Blade",
            "Song of the Storm",
        },
        ['SprySonataSong'] = {
            "Boberstler's Spry Sonata",
            "Dhakka's Spry Sonata",
            "Xetheg's Spry Sonata",
            "Kellek's Spry Sonata",
            "Kluzen's Spry Sonata",
            "Doben's Spry Sonata",
            "Terasal's Spry Sonata",
            "Sionachie's Spry Sonata",
            "Coldcrow's Spry Sonata",
        },
        ['CrescendoSong'] = {
            -- CrescendoSong - Level Range 75 - 114
            "Alliana's Lively Crescendo",
            "Regar's Lively Crescendo", -- 125
            "Zelinstein's Lively Crescendo",
            "Zburator's Lively Crescendo",
            "Jembel's Lively Crescendo",
            "Silisia's Lively Crescendo",
            "Motlak's Lively Crescendo",
            "Kolain's Lively Crescendo",
            "Lyssa's Lively Crescendo",
            "Gruber's Lively Crescendo",
            "Kaerra's Spirited Crescendo",
            "Veshma's Lively Crescendo",
        },
        ['ArcaneSong'] = {
            "Arcane Aria XII",
            "Arcane Rhythm", -- 125
            "Arcane Harmony",
            "Arcane Symphony",
            "Arcane Ballad",
            "Arcane Melody",
            "Arcane Hymn",
            "Arcane Address",
            "Arcane Chorus",
            "Arcane Arietta",
            "Arcane Anthem",
            "Arcane Aria",
        },
        ['InsultSong'] = {
            --Bard Timers alternate between 6 and 3 every expansion. (Update: TOB has thrown this on its head)
            --We have to manage selection so we don't have insultsong2 using the same timer.
            --"Cutting Insult X", -- 127 push, timer 6
            "Yaran's Disdain",  -- 123 nopush, timer 3,
            -- "Eoreg's Insult",   -- 122 push, timer 3, LS
            "Nord's Disdain",   -- 118 nopush, timer 6, NoS
            -- "Sogran's Insult",  -- 117 push, timer 6, ToL
            "Yelinak's Insult", -- 115 nopush, timer 3
            --"Omorden's Insult",     -- 112 push, timer 3
            "Sathir's Insult",  -- 110 nopush, timer 6
            --"Travenro's Insult",    -- 107 push, timer 6
            "Tsaph's Insult",   -- 105 nopush, timer 3
            --"Fjilnauk's Insult",    -- 102 push, timer 3
            --"Kaficus' Insult",      -- 100 push, timer 6 --Note push/nopush levels reversed this expansion compared to later
            "Garath's Insult",  -- 97 nopush, timer 6
            "Hykast's Insult",  -- 95 nopush, timer 3
            "Lyrin's Insult",   -- 90 nopush, timer 6
            "Venimor's Insult", -- 85, nopush, timer 3
            -- Below Level 85 This line turns into "bellow" instead of "Insult" and I don't know of anyone who uses them, but keeping for posterity
            -- "Bellow of Chaos", --66, interrupt
            -- "Brusco's Bombastic Bellow", --55, stun
            -- "Brusco's Boastful Bellow", --12,
        },
        ['InsultSong2'] = {
            -- "Cutting Insult X", -- 127 push, timer 6
            "Yaran's Disdain",  -- 123 nopush, timer 3,
            -- "Eoreg's Insult",   -- 122 push, timer 3, LS
            "Nord's Disdain",   -- 118 nopush, timer 6, NoS
            -- "Sogran's Insult",  -- 117 push, timer 6, ToL
            "Yelinak's Insult", -- 115 nopush, timer 3
            --"Omorden's Insult",     -- 112 push, timer 3
            "Sathir's Insult",  -- 110 nopush, timer 6
            --"Travenro's Insult",    -- 107 push, timer 6
            "Tsaph's Insult",   -- 105 nopush, timer 3
            --"Fjilnauk's Insult",    -- 102 push, timer 3
            --"Kaficus' Insult",      -- 100 push, timer 6 --Note push/nopush levels reversed this expansion compared to later
            "Garath's Insult",  -- 97 nopush, timer 6
            "Hykast's Insult",  -- 95 nopush, timer 3
            "Lyrin's Insult",   -- 90 nopush, timer 6
            "Venimor's Insult", -- 85, nopush, timer 3
        },
        ['LLInsultSong'] = {
            "Venimor's Insult", -- 85, nopush, timer 3
        },
        ['LLInsultSong2'] = {
            "Lyrin's Insult", -- 90 nopush, timer 6
        },
        ['DichoSong'] = {
            -- DichoSong Level Range - 101+
            "Reciprocal Psalm",
            "Ecliptic Psalm",
            "Composite Psalm",
            "Dissident Psalm",
            "Dichotomic Psalm",
        },
        ['BardDPSAura'] = {
            "Aura of Kenburk",
            "Aura of Tenisbre", -- 125
            "Aura of Pli Xin Liako",
            "Aura of Margidor",
            "Aura of Begalru",
            "Aura of Maetanrus",
            "Aura of Va'Ker",
            "Aura of the Orator",
            "Aura of the Composer",
            "Aura of the Poet",
            "Aura of the Artist",
            "Aura of the Muse",
            "Aura of Insight",
        },
        ['BardRegenAura'] = {
            "Aura of Quellious",
            "Aura of Shalowain",
            "Aura of Shei Vinitras",
            "Aura of Vhal`Sera",
            "Aura of Xigam",
            "Aura of Sionachie",
            "Aura of Salarra",
            "Aura of Lunanyn",
            "Aura of Renewal",
            "Aura of Rodcet",
        },
        ['GroupRegenSong'] = {
            --Note level 77 pulse only offers a heal% buff and is not included here.
            "Pulse of Quellious",
            "Pulse of August", -- 125
            "Pulse of Nikolas",
            "Pulse of Vhal`Sera",
            "Pulse of Xigam",
            "Pulse of Sionachie",
            "Pulse of Salarra",
            "Pulse of Lunanyn",
            "Pulse of Renewal",              -- 86 start hp/mana/endurance
            "Cantata of Rodcet",             -- 81
            "Cantata of Restoration",        -- 76
            "Erollisi's Cantata",            -- 71
            "Cantata of Life",               -- 67
            "Wind of Marr",                  -- 62
            "Cantata of Replenishment",      -- 55
            "Cantata of Soothing",           -- 34 start hp/mana. Slightly less mana. They can custom if it they want the 2 mana/tick
            "Cassindra's Chorus of Clarity", -- 32, mana only
            "Cassindra's Chant of Clarity",  -- 20, mana only
            "Hymn of Restoration",           -- 7, hp only
        },
        ['AreaRegenSong'] = {
            "Chorus of Quellious",
            "Chorus of Shalowain",     -- 123
            "Chorus of Shei Vinitras", -- 118
            "Chorus of Vhal`Sera",     -- 113
            "Chorus of Xigam",         -- 108
            "Chorus of Sionachie",     -- 103
            "Chorus of Salarra",       -- 98
            "Chorus of Lunanyn",       -- 93
            "Chorus of Renewal",       -- 88
            "Chorus of Rodcet",        -- 83
            "Chorus of Restoration",   -- 78
            "Erollisi's Chorus",       -- 73
            "Chorus of Life",          -- 69
            "Chorus of Marr",          -- 64
            "Ancient: Lcea's Lament",  -- 60
            "Chorus of Replenishment", -- 58
        },
        ['WarMarchSong'] = {
            "War March of the Burning Host",
            "War March of Nokk", -- 125
            "War March of Centien Xi Va Xakra",
            "War March of Radiwol",
            "War March of Dekloaz",
            "War March of Jocelyn",
            "War March of Protan",
            "War March of Illdaera",
            "War March of Dagda",
            "War March of Brekt",
            "War March of Meldrath",
            "War March of Muram",
            "War March of the Mastruq",
            "Warsong of Zek",
            "McVaxius' Rousing Rondo",
            "Vilia's Chorus of Celerity",
            "Verses of Victory",
            "McVaxius' Berserker Crescendo",
            "Vilia's Verses of Celerity",
            "Anthem de Arms",
        },
        ['FireBuffSong'] = {
            -- CasterAriaSong - Level Range 72+
            "Severyn's Aria",
            "Flariton's Aria", -- 125
            "Constance's Aria",
            "Sontalak's Aria",
            "Qunard's Aria",
            "Nilsara's Aria",
            "Gosik's Aria",
            "Daevan's Aria",
            "Sotor's Aria",
            "Talendor's Aria",
            "Performer's Explosive Aria",
        },
        ['SlowSong'] = {
            "Requiem of Time",
            "Angstlich's Assonance",    --snare/slow
            "Largo's Assonant Binding", --snare/slow
            "Selo's Consonant Chain",   --snare/slow
        },
        ['AESlowSong'] = {
            -- AESlowSong - Level Range 20 - 114 (Single target works better)
            "Zinnia's Melodic Binding", -- 125
            "Radiwol's Melodic Binding",
            "Dekloaz's Melodic Binding",
            "Protan's Melodic Binding",
            "Selo's Assonant Strain",
            "Largo's Melodic Binding",
        },
        ['AccelerandoSong'] = {
            "Alleviating Accelerando VIII",
            "Appeasing Accelerando", -- 125
            "Satisfying Accelerando",
            "Placating Accelerando",
            "Atoning Accelerando",
            "Allaying Accelerando",
            "Ameliorating Accelerando",
            "Assuaging Accelerando",
            "Alleviating Accelerando",
        },
        ['SpitefulSong'] = {
            -- SpitefulSong - Level Range 90 -
            "Matriarch's Spiteful Lyric",
            "Tatalros' Spiteful Lyric", -- 125
            "Von Deek's Spiteful Lyric",
            "Omorden's Spiteful Lyric",
            "Travenro's Spiteful Lyric",
            "Fjilnauk's Spiteful Lyric",
            "Kaficus' Spiteful Lyric",
            "Hykast's Spiteful Lyric",
            "Lyrin's Spiteful Lyric",
        },
        ['RecklessSong'] = {
            "Onkrin's Reckless Renewal",
            "Grayleaf's Reckless Renewal", -- 125
            "Kai's Reckless Renewal",
            "Reivaj's Reckless Renewal",
            "Rigelon's Reckless Renewal",
            "Rytan's Reckless Renewal",
            "Ruaabri's Reckless Renewal",
            "Ryken's Reckless Renewal",
        },
        ['ColdBuffSong'] = {
            -- ColdBuffSong - Level Range 72 - 112 **
            "Fatesong of the Polar Vortex",
            "Fatesong of Zoraxmen", -- 125
            "Fatesong of Lucca",
            "Fatesong of Radiwol",
            "Fatesong of Dekloaz",
            "Fatesong of Jocelyn",
            "Fatesong of Protan",
            "Fatesong of Illdaera",
            "Fatesong of Fergar",
            "Fatesong of the Gelidran",
            "Garadell's Fatesong",
            "Weshlu's Chillsong Aria",
        },
        ['DotBuffSong'] = {
            -- Fire & Magic Dots song
            "Danfol's Psalm of Potency",
            "Tatalros' Psalm of Potency", -- 125
            "Fyrthek Fior's Psalm of Potency",
            "Velketor's Psalm of Potency",
            "Akett's Psalm of Potency",
            "Horthin's Psalm of Potency",
            "Siavonn's Psalm of Potency",
            "Wasinai's Psalm of Potency",
            "Lyrin's Psalm of Potency",
            "Druzzil's Psalm of Potency",
            "Erradien's Psalm of Potency",
        },
        ['FireDotSong'] = {
            "Severyn's Chant of Flame",
            "Kindleheart's Chant of Flame", -- 125
            "Shak Dathor's Chant of Flame",
            "Sontalak's Chant of Flame",
            "Qunard's Chant of Flame",
            "Nilsara's Chant of Flame",
            "Gosik's Chant of Flame",
            "Daevan's Chant of Flame",
            "Sotor's Chant of Flame",
            "Talendor's Chant of Flame",
            "Tjudawos' Chant of Flame",
            "Vulka's Chant of Flame",
            "Tuyen's Chant of Fire",
            "Tuyen's Chant of Flame",
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",
            "Angstlich's Assonance",
            "Fufil's Diminishing Dirge",
            "Fufil's Curtailing Chant",
        },
        ['IceDotSong'] = {
            "Tsikut's Chant of Frost",
            "Swarn's Chant of Frost",
            "Sylra Fris' Chant of Frost",
            "Yelinak's Chant of Frost",
            "Ekron's Chant of Frost",
            "Kirchen's Chant of Frost",
            "Edoth's Chant of Frost",
            "Kalbrok's Chant of Frost",
            "Fergar's Chant of Frost",
            "Gorenaire's Chant of Frost",
            "Zeixshi-Kar's Chant of Frost",
            "Vulka's Chant of Frost",
            "Tuyen's Chant of Ice",
            "Tuyen's Chant of Frost",
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",
            "Angstlich's Assonance",
            "Fufil's Diminishing Dirge",
            "Fufil's Curtailing Chant",
        },
        ['PoisonDotSong'] = {
            "Khrosik's Chant of Poison",
            "Marsin's Chant of Poison",
            "Cruor's Chant of Poison",
            "Malvus's Chant of Poison",
            "Nexona's Chant of Poison",
            "Serisaria's Chant of Poison",
            "Slaunk's Chant of Poison",
            "Hiqork's Chant of Poison",
            "Spinechiller's Chant of Poison",
            "Severilous' Chant of Poison",
            "Kildrukaun's Chant of Poison",
            "Vulka's Chant of Poison",
            "Tuyen's Chant of Venom",
            "Tuyen's Chant of Poison",
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",
            "Angstlich's Assonance",
            "Fufil's Diminishing Dirge",
            "Fufil's Curtailing Chant",
        },
        ['DiseaseDotSong'] = {
            "Pustim's Chant of Disease",
            "Goremand's Chant of Disease", -- 125
            "Coagulus' Chant of Disease",
            "Zlexak's Chant of Disease",
            "Hoshkar's Chant of Disease",
            "Horthin's Chant of Disease",
            "Siavonn's Chant of Disease",
            "Wasinai's Chant of Disease",
            "Shiverback's Chant of Disease",
            "Trakanon's Chant of Disease",
            "Vyskudra's Chant of Disease",
            "Vulka's Chant of Disease",
            "Tuyen's Chant of the Plague",
            "Tuyen's Chant of Disease",
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",
            "Angstlich's Assonance",
            "Fufil's Diminishing Dirge",
            "Fufil's Curtailing Chant",
        },
        ['CureSong'] = {
            "Aria of Absolution",
            "Aria of Impeccability",
            "Aria of Amelioration",
            --"Aria of Innocence", --curse only
            "Aria of Asceticism", --poison/disease Only
        },
        ['AllianceSong'] = {
            "Covariance of Sticks and Stones",
            "Conjunction of Sticks and Stones",
            "Alliance of Sticks and Stones",
            "Covenant of Sticks and Stones",
            "Coalition of Sticks and Stones",
        },
        ['CharmSong'] = {
            "Voice of Keftlik",
            "Voice of Suja", -- 125
            "Voice of the Diabo",
            "Omiyad's Demand",
            "Voice of Zburator",
            "Desirae's Demand",
            "Voice of Jembel",
            "Dawnbreeze's Demand",
            "Voice of Silisia",
            "Silisia's Demand",
            "Voice of Motlak",
            "Voice of Kolain",
            "Voice of Sionachie",
            "Voice of the Mindshear",
            "Yowl of the Bloodmoon",
            "Beckon of the Tuffein",
            "Voice of the Vampire",
            "Call of the Banshee",        -- 65
            "Solon's Bewitching Bravura", -- 39
            "Solon's Song of the Sirens", -- 27
        },
        ['ReflexStrike'] = {
            -- Bard ReflexStrike - Restores mana to group
            "Reflexive Retort",
            "Reflexive Rejoinder",
            "Reflexive Rebuttal",
        },
        ['ChordsAE'] = {
            "Chords of Dissonance",
        },
        ['AmpSong'] = {
            "Amplification",
        },
        ['DispelSong'] = {
            -- Dispel Song - For pulling to avoid Summons
            "Syvelian's Anti-Magic Aria",
            "Druzzil's Disillusionment",
        },
        ['ResistSong'] = {
            -- Resists Song
            "Psalm of Veeshan VII",
            "Psalm of Cooling",
            "Psalm of Purity",
            "Psalm of Warmth",
            "Psalm of Vitality",
            "Psalm of Veeshan",
            "Psalm of the Forsaken",
            "Second Psalm of Veeshan",
            "Psalm of the Restless",
            "Psalm of the Pious",
        },
        ['MezSong'] = {
            "Slumber of Keftlik	",
            "Slumber of Suja", -- 125
            "Slumber of the Diabo",
            -- [] = "Lullaby of Nightfall",
            -- [] = "Lullaby of Zburator",
            "Slumber of Zburator",
            "Slumber of Jembel",
            -- [] = "Lullaby of Jembel",
            "Slumber of Silisia",
            -- [] = "Lullaby of Silisia",
            "Slumber of Motlak",
            -- [] = "Lullaby of the Forsaken",
            "Slumber of Kolain",
            -- [] = "Lullaby of the Forlorn",
            "Slumber of Sionachie",
            -- [] = "Lullaby of the Lost",
            "Slumber of the Mindshear",
            "Serenity of Oceangreen",
            "Amber's Last Lullaby",
            "Queen Eletyl's Screech",
            "Command of Queen Veneneu",
            "Aelfric's Last Lullaby",
            "Vulka's Lullaby",
            "Creeping Dreams",
            "Luvwen's Lullaby",
            "Lullaby of Morell",
            "Dreams of Terris",
            "Dreams of Thule",
            "Dreams of Ayonae",
            "Song of Twilight",
            "Sionachie's Dreams",
            "Crission's Pixie Strike",
            "Kelin's Lucid Lullaby",
        },
        ['MezAESong'] = {
            -- MezAESong - Level Range 85 - 115 **
            "Wave of Slumber X",
            "Wave of Stupor", -- 125
            "Wave of Nocturn",
            "Wave of Sleep",
            "Wave of Somnolence",
            "Wave of Torpor",
            "Wave of Quietude",
            "Wave of the Conductor",
            "Wave of Dreams",
            "Wave of Slumber",
        },
        ['Jonthan'] = {
            "Jonthan's Mightful Caretaker",
            "Jonthan's Inspiration",
            "Jonthan's Provocation",
            "Jonthan's Whistling Warsong",
        },
        ['CalmSong'] = {
            -- CalmSong - Level Range 8+ --Included for manual use with /rgl usemap
            "Silence of the Vortex",     -- Level 126
            "Kelin's Lugubrious Lament", -- Level 8 (Max Mob Level of 60)
            "Silent Song of Quellious",  -- Level 61
            "Luvwen's Aria of Serenity", -- Level 66
            "Whispersong of Veshma",     -- Level 71
            "Elddar's Dawnsong",         -- Level 76
            "Silence of the Void",       -- Level 81
            "Silence of the Dreamer",    -- Level 86
            "Silence of the Windsong",   -- Level 91
            "Silence of the Forsaken",   -- Level 96
            "Silence of the Silisia",    -- Level 101
            "Silence of Jembel",         -- Level 106
            "Silence of Zburator",       -- Level 111
            "Silence of Quietus",        -- Level 116
            "Silence of the Forgotten",  -- Level 121
        },
        ['ThousandBlades'] = {
            "Thousand Blades",
        },
    },
    ['HelperFunctions'] = {
        SwapInst = function(type)
            if not Config:GetSetting('SwapInstruments') then return end
            Logger.log_verbose("\ayBard SwapInst(): Swapping to Instrument Type: %s", type)
            if type == "Percussion Instruments" then
                ItemManager.SwapItemToSlot("offhand", Config:GetSetting('PercInst'))
                return
            elseif type == "Wind Instruments" then
                ItemManager.SwapItemToSlot("offhand", Config:GetSetting('WindInst'))
                return
            elseif type == "Brass Instruments" then
                ItemManager.SwapItemToSlot("offhand", Config:GetSetting('BrassInst'))
                return
            elseif type == "Stringed Instruments" then
                ItemManager.SwapItemToSlot("offhand", Config:GetSetting('StringedInst'))
                return
            end
            ItemManager.SwapItemToSlot("offhand", Config:GetSetting('Offhand'))
        end,
        CheckSongStateUse = function(self, config)   --determine whether a song should be sung by comparing combat state to settings
            local usestate = Config:GetSetting(config)
            if Targeting.GetXTHaterCount() == 0 then --I have tried this with combat_state nand XTHater, and both have their ups and downs. Keep an eye on this.
                return usestate > 2                  --I think XTHater will work better if the bard autoassists at 99 or 100.
            else
                return usestate < 4
            end
        end,
        RefreshBuffSong = function(songSpell) --determine how close to a buff's expiration we will resing to maintain full uptime
            if not songSpell or not songSpell() then return false end
            local me = mq.TLO.Me
            local threshold = Targeting.GetXTHaterCount() == 0 and Config:GetSetting('RefreshDT') or Config:GetSetting('RefreshCombat')
            local duration = songSpell.DurationWindow() == 1 and (me.Song(songSpell.Name()).Duration.TotalSeconds() or 0) or (me.Buff(songSpell.Name()).Duration.TotalSeconds() or 0)
            local ret = duration <= threshold
            Logger.log_verbose("\ayRefreshBuffSong(%s) => memed(%s), duration(%d), threshold(%d), should refresh:(%s)", songSpell,
                Strings.BoolToColorString(me.Gem(songSpell.RankName.Name())() ~= nil), duration, threshold, Strings.BoolToColorString(ret))
            return ret
        end,
        UnwantedAggroCheck = function(self) --Self-Explanatory. Add isTanking to this if you ever make a mode for bardtanks!
            if Targeting.GetXTHaterCount() == 0 or Core.IAmMA() or mq.TLO.Group.Puller.ID() == mq.TLO.Me.ID() then return false end
            return Targeting.IHaveAggro(100)
        end,
        DotSongCheck = function(songSpell) --Check dot stacking, stop dotting when HP threshold is reached based on mob type, can't use utils function because we try to refresh just as the dot is ending
            if not songSpell or not songSpell() then return false end
            return songSpell.StacksTarget() and Targeting.MobNotLowHP(Targeting.GetAutoTarget())
        end,
        GetDetSongDuration = function(songSpell) -- Checks target for duration remaining on dot songs
            local duration = mq.TLO.Target.FindBuff("name " .. "\"" .. songSpell.Name() .. "\"").Duration.TotalSeconds() or 0
            Logger.log_debug("getDetSongDuration() Current duration for %s : %d", songSpell, duration)
            return duration
        end,

    },
    ['SpellList']       = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                --role and critical functions
                { name = "MezAESong",     cond = function(self) return Config:GetSetting('DoAEMez') end, },
                { name = "MezSong",       cond = function(self) return Config:GetSetting('DoSTMez') end, },
                { name = "CharmSong",     cond = function(self) return Config:GetSetting('CharmOn') end, },
                { name = "SlowSong",      cond = function(self) return Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSong",    cond = function(self) return Config:GetSetting('DoAESlow') end, },
                { name = "DispelSong",    cond = function(self) return Config:GetSetting('DoDispel') end, },
                { name = "CureSong",      cond = function(self) return Config:GetSetting('UseCure') end, },
                { name = "RunBuffSong",   cond = function(self) return Config:GetSetting('UseRunBuff') and not Casting.CanUseAA("Selo's Sonata") end, },
                { name = "EndBreathSong", cond = function(self) return Config:GetSetting('UseEndBreath') end, },

                -- main group dps
                { name = "WarMarchSong",  cond = function(self) return Config:GetSetting('UseMarch') > 1 end, },
                { name = "AriaSong",      cond = function(self) return Config:GetSetting('UseAria') > 1 end, },
                {
                    name = "OverhasteSong",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('LLAria') == 2 and Config:GetSetting('UseAria') > 1
                    end,
                },
                {
                    name = "SpellDamageSong",
                    cond = function(self)
                        return not Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('LLAria') == 3 and Config:GetSetting('UseAria') > 1
                    end,
                },
                { name = "ArcaneSong",     cond = function(self) return Config:GetSetting('UseArcane') > 1 end, },
                { name = "DichoSong",      cond = function(self) return Config:GetSetting('UseDicho') > 1 end, },
                -- regen songs
                { name = "GroupRegenSong", cond = function(self) return Config:GetSetting('RegenSong') == 2 end, },
                { name = "AreaRegenSong",  cond = function(self) return Config:GetSetting('RegenSong') == 3 end, },
                { name = "CrescendoSong",  cond = function(self) return Config:GetSetting('UseCrescendo') end, },
                { name = "AmpSong",        cond = function(self) return Config:GetSetting('UseAmp') > 1 end, },
                -- self dps songs
                { name = "AllianceSong",   cond = function(self) return Config:GetSetting('UseAlliance') end, },
                {
                    name = "InsultSong",
                    cond = function(self)
                        return Config:GetSetting('UseInsult') > 1 and (not Config:GetSetting('UseLLInsult') or not Core.GetResolvedActionMapItem('LLInsultSong'))
                    end,
                },
                { name = "LLInsultSong",   cond = function(self) return Config:GetSetting('UseInsult') > 1 and Config:GetSetting('UseLLInsult') end, },
                { name = "FireDotSong",    cond = function(self) return Config:GetSetting('UseFireDots') end, },
                { name = "IceDotSong",     cond = function(self) return Config:GetSetting('UseIceDots') end, },
                { name = "PoisonDotSong",  cond = function(self) return Config:GetSetting('UsePoisonDots') end, },
                { name = "DiseaseDotSong", cond = function(self) return Config:GetSetting('UseDiseaseDots') end, },
                { name = "Jonthan",        cond = function(self) return Config:GetSetting('UseJonthan') > 1 end, },
                {
                    name = "InsultSong2",
                    cond = function(self)
                        return Config:GetSetting('UseInsult') == 3 and (not Config:GetSetting('UseLLInsult') or not Core.GetResolvedActionMapItem('LLInsultSong'))
                    end,
                },
                { name = "LLInsultSong2",   cond = function(self) return Config:GetSetting('UseInsult') == 3 and Config:GetSetting('UseLLInsult') end, },
                -- melee dps songs
                { name = "SufferingSong",   cond = function(self) return Config:GetSetting('UseSuffering') > 1 end, },
                -- caster dps songs
                { name = "FireBuffSong",    cond = function(self) return Config:GetSetting('UseFireBuff') > 1 end, },
                { name = "ColdBuffSong",    cond = function(self) return Config:GetSetting('UseColdBuff') > 1 end, },
                { name = "DotBuffSong",     cond = function(self) return Config:GetSetting('UseDotBuff') > 1 end, },
                -- healer songs
                { name = "AccelerandoSong", cond = function(self) return Config:GetSetting('UseAccelerando') > 1 end, },
                { name = "RecklessSong",    cond = function(self) return Config:GetSetting('UseReckless') > 1 end, },
                -- tank songs
                { name = "SpitefulSong",    cond = function(self) return Config:GetSetting('UseSpiteful') > 1 end, },
                { name = "SprySonataSong",  cond = function(self) return Config:GetSetting('UseSpry') > 1 end, },
                { name = "ResistSong",      cond = function(self) return Config:GetSetting('UseResist') > 1 end, },
                -- filler
                { name = "CalmSong",        cond = function(self) return true end, }, -- condition not needed, for uniformity
            },
        },
    },
    ['RotationOrder']   = {
        {
            name = 'Enduring Breath',
            state = 1,
            steps = 1,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            load_cond = function(self) return Config:GetSetting('UseEndBreath') and Core.GetResolvedActionMapItem('EndBreathSong') end,
            cond = function(self, combat_state)
                return not (combat_state == "Downtime" and mq.TLO.Me.Invis()) and (mq.TLO.Me.FeetWet() or mq.TLO.Zone.ShortName() == 'thegrey')
            end,
        },
        {
            name = 'Melody',
            state = 1,
            steps = 1,
            timer = 0,
            doFullRotation = true,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return not (combat_state == "Downtime" and mq.TLO.Me.Invis()) and not Globals.InMedState
            end,
        },
        {
            name = 'Downtime',
            state = 1,
            steps = 1,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and not mq.TLO.Me.Invis()
            end,
        },
        {
            name = 'Emergency',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or self.ClassConfig.HelperFunctions.UnwantedAggroCheck(self))
            end,
        },
        {
            name = 'Debuff',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting("DoSTSlow") or Config:GetSetting("DoAESlow") or Config:GetSetting("DoDispel") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'CombatSongs',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
    },
    ['Rotations']       = {
        ['Burn'] = {
            {
                name = "Quick Time",
                type = "AA",
            },
            {
                name = "Funeral Dirge",
                type = "AA",
            },
            {
                name = "Spire of the Minstrels",
                type = "AA",
            },
            {
                name = "Bladed Song",
                type = "AA",
            },
            {
                name = "ThousandBlades",
                type = "Disc",
            },
            {
                name = "Song of Stone",
                type = "AA",
            },
            {
                name = "Flurry of Notes",
                type = "AA",
            },
            {
                name = "Dance of Blades",
                type = "AA",
            },
            { --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoChestClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Cacophony",
                type = "AA",
            },
            {
                name = "Frenzied Kicks",
                type = "AA",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Debuff'] = {
            {
                name = "AESlowSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('DoAESlow') end,
                cond = function(self, songSpell, target)
                    return Casting.DetSpellCheck(songSpell) and Targeting.GetXTHaterCount() > 2 and not mq.TLO.Target.Slowed() and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('DoSTSlow') end,
                cond = function(self, songSpell, target)
                    return Casting.DetSpellCheck(songSpell) and not mq.TLO.Target.Slowed() and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "DispelSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('DoDispel') end,
                cond = function(self, songSpell)
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['Combat'] = {
            -- Kludge that addresses bards not attempting to start attacking until after a song completes
            -- Uncomment if you'd like to occasionally start attacking earlier than normal
            --[[{
                name = "Force Attack",
                type = "AA",
                cond = function(self, itemName)
                    local mytar = mq.TLO.Target
                    if not mq.TLO.Me.Combat() and mytar() and mytar.Distance() < 50 then
                        Core.DoCmd("/keypress AUTOPRIM")
                    end
                end,
            },]]
            {
                name = "Epic",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('UseEpic') > 1 end,
                cond = function(self, itemName)
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "Fierce Eye",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UseFierceEye') > 1 end,
                cond = function(self, aaName)
                    return (Config:GetSetting('UseFierceEye') == 3 or (Config:GetSetting('UseFierceEye') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "ReflexStrike",
                type = "Disc",
                tooltip = Tooltips.ReflexStrike,
                cond = function(self, discSpell)
                    local pct = Config:GetSetting('GroupManaPct')
                    return (mq.TLO.Group.LowMana(pct)() or -1) >= Config:GetSetting('GroupManaCt')
                end,
            },
            {
                name = "Boastful Bellow",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UseBellow') > 1 end,
                cond = function(self, aaName, target)
                    return ((Config:GetSetting('UseBellow') == 3 and mq.TLO.Me.PctEndurance() > Config:GetSetting('SelfEndPct')) or (Config:GetSetting('UseBellow') == 2 and Casting.BurnCheck())) and
                        Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Vainglorious Shout",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UseShout') > 1 end,
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return ((Config:GetSetting('UseShout') == 3 and mq.TLO.Me.PctEndurance() > Config:GetSetting('SelfEndPct')) or (Config:GetSetting('UseShout') == 2 and Casting.BurnCheck())) and
                        Combat.AETargetCheck(true) and Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Rallying Solo", --Rallying Call theoretically possible but problematic, needs own rotation akin to Focused Paragon, etc
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA('Rallying Solo') end,
                cond = function(self, aaName)
                    return (mq.TLO.Me.PctEndurance() < 30 or mq.TLO.Me.PctMana() < 30)
                end,
            },
            {
                name = "Intimidation",
                type = "Ability",
                load_cond = function(self) return Casting.AARank("Intimidation") > 1 end,
            },
        },
        ['CombatSongs'] = {
            {
                name = "DichoSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseDicho') > 1 end,
                cond = function(self, songSpell)
                    return (Config:GetSetting('UseDicho') == 3 and (mq.TLO.Me.PctEndurance() > Config:GetSetting('SelfEndPct') or Casting.BurnCheck()))
                        or (Config:GetSetting('UseDicho') == 2 and Casting.IHaveBuff(Casting.GetAASpell("Quick Time")))
                end,
            },
            {
                name = "InsultSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseInsult') > 1 and (not Config:GetSetting('UseLLInsult') or not Core.GetResolvedActionMapItem('LLInsultSong')) end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "LLInsultSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseInsult') > 1 and Config:GetSetting('UseLLInsult') and Core.GetResolvedActionMapItem('LLInsultSong') end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "FireDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseFireDots') end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.DotSongCheck(songSpell) and
                        -- If dot is about to wear off, recast
                        self.ClassConfig.HelperFunctions.GetDetSongDuration(songSpell) <= 3
                end,
            },
            {
                name = "IceDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseIceDots') end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.DotSongCheck(songSpell) and
                        -- If dot is about to wear off, recast
                        self.ClassConfig.HelperFunctions.GetDetSongDuration(songSpell) <= 3
                end,
            },
            {
                name = "PoisonDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UsePoisonDots') end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.DotSongCheck(songSpell) and
                        -- If dot is about to wear off, recast
                        self.ClassConfig.HelperFunctions.GetDetSongDuration(songSpell) <= 3
                end,
            },
            {
                name = "DiseaseDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseDiseaseDots') end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.DotSongCheck(songSpell) and
                        -- If dot is about to wear off, recast
                        self.ClassConfig.HelperFunctions.GetDetSongDuration(songSpell) <= 3
                end,
            },
            {
                name = "InsultSong2",
                type = "Song",
                load_cond = function(self)
                    return Config:GetSetting('UseInsult') == 3 and (not Config:GetSetting('UseLLInsult') or not Core.GetResolvedActionMapItem('LLInsultSong'))
                end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "LLInsultSong2",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseInsult') == 3 and Config:GetSetting('UseLLInsult') and Core.GetResolvedActionMapItem('LLInsultSong') end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "AllianceSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseAlliance') end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck()) and Casting.DetSpellCheck(songSpell)
                end,
            },
            --used in combat when we have nothing else to refresh rather than standing there. Initial testing good, need more to ensure this doesn't interfere with Melody.
            {
                name = "AriaSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.Song(songSpell.Name()).Duration.TotalSeconds() or 0) <= 18
                end,
            },
            {
                name = "WarMarchSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('WarMarchSong') and Config:GetSetting('UseMarch') > 1 end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.Song(songSpell.Name()).Duration.TotalSeconds() or 0) <= 18
                end,
            },
        },
        ['Enduring Breath'] = {
            {
                name = "EndBreathSong",
                type = "Song",
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
        },
        ['Melody'] = {
            {
                name = "AriaSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseAria") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "OverhasteSong",
                type = "Song",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('LLAria') == 2 and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseAria") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "SpellDmgSong",
                type = "Song",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('LLAria') == 3 and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseAria") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "WarMarchSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('WarMarchSong') and Config:GetSetting('UseMarch') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseMarch") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "Jonthan",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('Jonthan') and Config:GetSetting('UseJonthan') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseJonthan") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "ArcaneSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('ArcaneSong') and Config:GetSetting('UseArcane') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseArcane") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "CrescendoSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('CrescendoSong') and Config:GetSetting('UseCrescendo') end,
                cond = function(self, songSpell)
                    if (mq.TLO.Me.GemTimer(songSpell.RankName())() or -1) > 0 then return false end
                    local pct = Config:GetSetting('GroupManaPct')
                    return (mq.TLO.Group.LowMana(pct)() or -1) >= Config:GetSetting('GroupManaCt')
                end,
            },
            {
                name = "GroupRegenSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('GroupRegenSong') and Config:GetSetting('RegenSong') == 2 end,
                cond = function(self, songSpell)
                    local pct = Config:GetSetting('GroupManaPct')
                    return self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell) and
                        ((Config:GetSetting('UseRegen') == 1 and (mq.TLO.Group.LowMana(pct)() or 999) >= Config:GetSetting('GroupManaCt'))
                            or (Config:GetSetting('UseRegen') > 1 and self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseRegen")))
                end,
            },
            {
                name = "AreaRegenSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AreaRegenSong') and Config:GetSetting('RegenSong') == 3 end,
                cond = function(self, songSpell)
                    local pct = Config:GetSetting('GroupManaPct')
                    return self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell) and
                        ((Config:GetSetting('UseRegen') == 1 and (mq.TLO.Group.LowMana(pct)() or 999) >= Config:GetSetting('GroupManaCt'))
                            or (Config:GetSetting('UseRegen') > 1 and self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseRegen")))
                end,
            },
            {
                name = "AmpSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AmpSong') and Config:GetSetting('UseAmp') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseAmp") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "SufferingSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('SufferingSong') and Config:GetSetting('UseSuffering') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseSuffering") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "SpitefulSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('SpitefulSong') and Config:GetSetting('UseSpiteful') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseSpiteful") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "SprySonataSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('SprySonataSong') and Config:GetSetting('UseSpry') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseSpry") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "ResistSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('ResistSong') and Config:GetSetting('UseResist') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseResist") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "RecklessSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('RecklessSong') and Config:GetSetting('UseReckless') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseReckless") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "AccelerandoSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AccelerandoSong') and Config:GetSetting('UseAccelerando') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseAccelerando") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "FireBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('FireBuffSong') and Config:GetSetting('UseFireBuff') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseFireBuff") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "ColdBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('ColdBuffSong') and Config:GetSetting('UseColdBuff') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseColdBuff") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "DotBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('DotBuffSong') and Config:GetSetting('UseDotBuff') > 1 end,
                cond = function(self, songSpell)
                    return self.ClassConfig.HelperFunctions.CheckSongStateUse(self, "UseDotBuff") and self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "Selo's Sonata",
                type = "AA",
                targetId = function(self) return { mq.TLO.Me.ID(), } end,
                load_cond = function(self) return Config:GetSetting('UseRunBuff') and Casting.CanUseAA("Selo's Sonata") end,
                cond = function(self, aaName)
                    if not Config:GetSetting('UseRunBuff') then return false end
                    --refresh slightly before expiry for better uptime
                    return (mq.TLO.Me.Buff(mq.TLO.AltAbility(aaName).Spell.Trigger(1)).Duration.TotalSeconds() or 0) < 30
                end,
            },
            {
                name = "RunBuffSong",
                type = "Song",
                targetId = function(self) return { mq.TLO.Me.ID(), } end,
                load_cond = function(self) return Config:GetSetting('UseRunBuff') and not Casting.CanUseAA("Selo's Sonata") end,
                cond = function(self, songSpell)
                    if Globals.InMedState then return false end
                    return self.ClassConfig.HelperFunctions.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "BardDPSAura",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('BardDPSAura') and Config:GetSetting('UseAura') == 1 end,
                pre_activate = function(self, songSpell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(songSpell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, songSpell)
                    return not Casting.AuraActiveByName(songSpell.BaseName())
                end,
            },
            {
                name = "BardRegenAura",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('BardRegenAura') and Config:GetSetting('UseAura') == 2 end,
                pre_activate = function(self, songSpell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(songSpell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, songSpell)
                    return not Casting.AuraActiveByName(songSpell.BaseName())
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 35
                end,
            },
            {
                name = "Fading Memories",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UseFading') and Casting.CanUseAA('Fading Memories') end,
                cond = function(self, aaName)
                    return self.ClassConfig.HelperFunctions.UnwantedAggroCheck(self)
                    --I wanted to use XTAggroCount here but it doesn't include your current target in the number it returns and I don't see a good workaround. For Loop it is.
                end,
            },
            {
                name = "Hymn of the Last Stand",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA('Hymn of the Last Stand') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Shield of Notes",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA('Shield of Notes') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Coating",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoCoating') end,
                cond = function(self, itemName, target)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
    },
    ['PullAbilities']   = {
        {
            id = 'Sonic Disturbance',
            Type = "AA",
            DisplayName = 'Sonic Disturbance',
            AbilityName = 'Sonic Disturbance',
            AbilityRange = 250,
            cond = function(self)
                return mq.TLO.Me.AltAbility('Sonic Disturbance')() ~= nil
            end,
        },
        {
            id = 'Boastful Bellow',
            Type = "AA",
            DisplayName = 'Boastful Bellow',
            AbilityName = 'Boastful Bellow',
            AbilityRange = 250,
            cond = function(self)
                return mq.TLO.Me.AltAbility('Boastful Bellow')() ~= nil
            end,
        },
    },
    ['DefaultConfig']   = {
        ['Mode']            = {
            DisplayName = "Mode",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different Modes do?",
            Answer = "Bard currently only has one mode.",
        },

        --Abilities
        ['SelfManaPct']     = {
            DisplayName = "Self Min Mana %",
            Group = "Abilities",
            Header = "Common",
            Category = "Common Rules",
            Index = 101,
            Tooltip = "Minimum Mana% to use Insult and Alliance outside of burns.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
            FAQ = "Why am I constantly low on mana?",
            Answer = "Insults take a lot of mana, but we can control that amount with the Self Min Mana %.\n" ..
                "Try adjusting this to the minimum amount of mana you want to keep in reserve. Note that burns will ignore this setting.",
        },
        ['SelfEndPct']      = {
            DisplayName = "Self Min End %",
            Group = "Abilities",
            Header = "Common",
            Category = "Common Rules",
            Index = 102,
            Tooltip = "Minimum End% to use Bellow or Dicho outside of burns.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
            FAQ = "Why am I constantly low on endurance?",
            Answer = "Bellow will quickly eat your endurance, and Dicho can help it along. By default your BRD will keep a reserve.\n" ..
                "You can adjust Self Mind End % to set the amount of endurance you want to keep in reserve. Note that burns will ignore this setting.",
        },

        --Debuffs
        ['DoSTSlow']        = {
            DisplayName = "Use Slow (ST)",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = Tooltips.SlowSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoAESlow']        = {
            DisplayName = "Use Slow (AE)",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 102,
            Tooltip = Tooltips.AESlowSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoDispel']        = {
            DisplayName = "Use Dispel",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Dispel",
            Index = 101,
            Tooltip = Tooltips.DispelSong,
            RequiresLoadoutChange = true,
            Default = false,
        },

        --Other Recovery
        ['RegenSong']       = {
            DisplayName = "Regen Song Choice:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 101,
            Tooltip = "Select the Regen Song to be used, if any.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'None', 'Group', 'Area', },
            Default = 2,
            Min = 1,
            Max = 3,
            FAQ = "Why can't I choose between HP and Mana for my regen songs?",
            Answer = "At low level, the regen songs are spaced broadly, and wallow back and forth before settling on providing both resources.\n" ..
                "Endurance is eventually added as well.",
        },
        ['UseRegen']        = {
            DisplayName = "Regen Song Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 102,
            Tooltip = "When to use the Regen Song selected above.",
            Type = "Combo",
            ComboOptions = { 'Under Group Mana % (Advanced Options Setting)', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
        },
        ['UseCrescendo']    = {
            DisplayName = "Crescendo Delayed Heal",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            Tooltip = Tooltips.CrescendoSong,
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['GroupManaPct']    = {
            DisplayName = "Group Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 104,
            Tooltip =
            "Enable the use of Crescendoes, Reflexive Strikes, and Regen songs (if configured) when we have a count (see below) of group members at or below this mana percentage.",
            Default = 80,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['GroupManaCt']     = {
            DisplayName = "Group Mana Count",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 105,
            Tooltip = "The number of party members (including yourself) that need to be under the above mana percentage.",
            Default = 2,
            Min = 1,
            Max = 6,
            ConfigType = "Advanced",
        },
        -- Curing
        ['UseCure']         = {
            DisplayName = "Cure Ailments",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = Tooltips.CureSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        -- Direct
        ['UseBellow']       = {
            DisplayName = "Use Bellow:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "When to use Boastful Bellow.",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
            FAQ = "Why is my Boastful Bellow being recast early? My BRD is using it again before the conclusion nuke!",
            Answer = "Unfortunately, MQ currently reports the buff falling off early; we are examining possible fixes at this time.",
        },
        ['UseInsult']       = {
            DisplayName = "Insults to Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = Tooltips.InsultSong,
            Type = "Combo",
            ComboOptions = { 'None', 'Current Tier', 'Current + Old Tier', },
            Default = 3,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['UseLLInsult']     = {
            DisplayName = "Use Low-Level Insults",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use the lowest level insults possible to trigger Troubador's Synergy. Reduces insult damage, but increases mana savings.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        -- Over Time
        ['UseFireDots']     = {
            DisplayName = "Use Fire Dots",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = Tooltips.FireDotSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['UseIceDots']      = {
            DisplayName = "Use Ice Dots",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = Tooltips.IceDotSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['UsePoisonDots']   = {
            DisplayName = "Use Poison Dots",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = Tooltips.PoisonDotSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['UseDiseaseDots']  = {
            DisplayName = "Use Disease Dots",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = Tooltips.DiseaseDotSong,
            RequiresLoadoutChange = true,
            Default = false,
        },
        -- Under the Hood
        ['RefreshDT']       = {
            DisplayName = "Downtime Threshold",
            Group = "Abilities",
            Header = "Common",
            Category = "Under the Hood",
            Index = 101,
            Tooltip =
            "The duration threshold for refreshing a buff song outside of combat. ***WARNING: Editing this value can drastically alter your ability to maintain buff songs!*** This needs to be carefully tailored towards your song line-up.",
            Default = 12,
            Min = 0,
            Max = 30,
            ConfigType = "Advanced",
            FAQ = "Why does my bard keep singing the same two songs?",
            Answer = "You may need to adjust your Downtime Threshold value downward at lower levels/song durations.\n" ..
                "This needs to be carefully tailored towards your song line-up.",
        },
        ['RefreshCombat']   = {
            DisplayName = "Combat Threshold",
            Group = "Abilities",
            Header = "Common",
            Category = "Under the Hood",
            Index = 102,
            Tooltip =
            "The duration threshold for refreshing a buff song in combat. ***WARNING: Editing this value can drastically alter your ability to maintain buff songs!*** This needs to be carefully tailored towards your song line-up.",
            Default = 6,
            Min = 0,
            Max = 30,
            ConfigType = "Advanced",
            FAQ = "Songs are dropping regularly, what can I do?",
            Answer = "You may need to stop using so many songs! Alternatively, try tuning your Threshold values as they determine when we will try to resing a song.\n" ..
                "This needs to be carefully tailored towards your song line-up.",
        },
        -- Self
        ['UseAmp']          = {
            DisplayName = "Use Amp",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = Tooltips.AmpSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseJonthan']      = {
            DisplayName = "Use Jonthan",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = Tooltips.Jonthan,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['UseAlliance']     = {
            DisplayName = "Use Alliance",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 103,
            Tooltip = Tooltips.AllianceSong,
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['DoVetAA']         = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 104,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        --Group
        ['UseRunBuff']      = {
            DisplayName = "Use RunSpeed Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Use the best runspeed buff you have available. Short Duration > Long Duration > Selo's Sonata AA",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['UseEndBreath']    = {
            DisplayName = "Use Enduring Breath",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = Tooltips.EndBreathSong,
            Default = false,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['UseAura']         = {
            DisplayName = "Use Bard Aura",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Select the Aura to be used, if any.",
            Type = "Combo",
            ComboOptions = { 'DPS Aura', 'Regen', 'None', },
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 3,
            FAQ = "Do bard auras and song stack when effects are similar?",
            Answer = "While certain parts of each will not stack, auras add some buffs not present in the song.\n" ..
                "This makes the auras and songs worth using together, and the answer is nearly always to use the DPS Aura.",
        },
        ['UseFierceEye']    = {
            DisplayName = "Fierce Eye Use:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "When to use the Fierce Eye AA.",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['UseAria']         = {
            DisplayName = "Use Aria",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = Tooltips.AriaSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['LLAria']          = {
            DisplayName = "Pre-Aria Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Choose your preference of overhaste or spell damage before these songs are combined into the Aria line. After, we will simply use your Aria settings.",
            Type = "Combo",
            ComboOptions = { 'None', 'Overhaste', 'Spell Damage', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['UseMarch']        = {
            DisplayName = "Use War March",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = Tooltips.WarMarchSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseArcane']       = {
            DisplayName = "Use Arcane Line",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = Tooltips.ArcaneSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseSuffering']    = {
            DisplayName = "Use Suffering Line",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 109,
            Tooltip = Tooltips.SufferingSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 4,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseDicho']        = {
            DisplayName = "Psalm (Dicho) Use:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 110,
            Tooltip = Tooltips.DichoSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'During QuickTime', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            FAQ = "Why is there no option to use Dicho in burns only?",
            Answer =
                "Since QuickTime is set to be used on burns and may last after the burns, aligning Dicho with it allows a smoother song rotation and allows some use even after a Burn was triggered.\n" ..
                "Dicho settings can be adjusted in the DPS - Group tab.",
        },
        ['UseSpiteful']     = {
            DisplayName = "Use Spiteful",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 111,
            Tooltip = Tooltips.SpitefulSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseSpry']         = {
            DisplayName = "Use Spry",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 112,
            Tooltip = Tooltips.SprySonataSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseResist']       = {
            DisplayName = "Use DS/Resist Psalm",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 113,
            Tooltip = Tooltips.ResistSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseReckless']     = {
            DisplayName = "Use Reckless",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 114,
            Tooltip = Tooltips.RecklessSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 4,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseAccelerando']  = {
            DisplayName = "Use Accelerando",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 115,
            Tooltip = Tooltips.AccelerandoSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['UseFireBuff']     = {
            DisplayName = "Use Fire Spell Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 116,
            Tooltip = Tooltips.FireBuffSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['UseColdBuff']     = {
            DisplayName = "Use Cold Spell Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 117,
            Tooltip = Tooltips.ColdBuffSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['UseDotBuff']      = {
            DisplayName = "Use Fire/Magic DoT Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 118,
            Tooltip = Tooltips.DotBuffSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },

        -- Clickies
        ['UseEpic']         = {
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
            RequiresLoadoutChange = true,
        },
        ['DoChestClick']    = {
            DisplayName = "Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your equipped chest item.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
            ConfigType = "Advanced",
            FAQ = "What is a Chest Click?",
            Answer = "Most Chest slot items after level 75ish have a clickable effect.\n" ..
                "BRD is set to use theirs during burns, so long as the item equipped has a clicky effect.",
        },
        ['DoCoating']       = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 103,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
            RequiresLoadoutChange = true,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },

        --Emergency
        ['EmergencyStart']  = {
            DisplayName = "Emergency HP%",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "Your HP % before we begin to use emergency mitigation abilities.",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['UseFading']       = {
            DisplayName = "Use Combat Escape",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use Fading Memories when you have aggro and you aren't the Main Assist.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },

        --Instruments--
        ['SwapInstruments'] = {
            DisplayName = "Auto Swap Instruments",
            Index = 101,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Auto swap instruments for songs",
            Default = false,
        },
        ['Offhand']         = {
            DisplayName = "Offhand",
            Index = 102,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Item to swap in when no instrument is available or needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['BrassInst']       = {
            DisplayName = "Brass Instrument",
            Index = 103,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Brass Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['WindInst']        = {
            DisplayName = "Wind Instrument",
            Index = 104,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Wind Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['PercInst']        = {
            DisplayName = "Percussion Instrument",
            Index = 105,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Percussion Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['StringedInst']    = {
            DisplayName = "Stringed Instrument",
            Index = 106,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Stringed Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },

        --AE Damage
        ['UseShout']        = {
            DisplayName = "Shout Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "When to use Vainglorious Shout.",
            Type = "Combo",
            ComboOptions = { 'Never', 'Burns Only', 'All Combat', },
            Default = 3,
            Min = 1,
            Max = 3,
            FAQ = "Why is my Vainglorious Shout being recast early? My BRD is using it again before the conclusion nuke!",
            Answer = "Unfortunately, MQ currently reports the buff falling off early; we are examining possible fixes at this time.",
        },
    },
    ['ClassFAQ']        = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release aimed at official servers.\n\n" ..
                "  This config should perform well from from start to endgame, but a TLP or emu player may find it to be lacking exact customization for a specific era.\n\n" ..
                "  Additionally, those wishing more fine-tune control for specific encounters or raids should customize this config to their preference. \n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
        {
            Question = "How does Bard meditation function?",
            Answer = "Bards can elect to med using the same settings as other classes. If a bard begins to med, they will stop singing any songs in the Melody rotation.\n\n" ..
                "  Using the default class configs, the combat rotations will still be used. Thus, there is generally little or no support for in-combat meditation for Bard.\n\n" ..
                "  The 'Stand When Done' med setting will ensure that a bard begins to sing again as soon as they reach the med stop threshold.\n\n" ..
                "  Note that the Enduring Breath song, if enabled (and needed), does not respect meditation settings, for the safety of your group.",
            Settings_Used = "",
        },
    },
}
return _ClassConfig
