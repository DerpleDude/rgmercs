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
            "Selo's Accelerating Chorus", -- level 49, SoL
            "Selo's Accelerando",         -- level 5, Base Game
        },
        ['EndBreathSong'] = {
            "Tarew's Aquatic Ayre", -- level 16, Base Game
        },
        ['AriaSong'] = {
            "Aria of Kenburk",           -- level 126, SoR
            "Aria of Tenisbre",          -- level 121, LS
            "Aria of Pli Xin Liako",     -- level 116, ToL
            "Aria of Margidor",          -- level 111, ToV
            "Aria of Begalru",           -- level 106, RoS
            "Aria of Maetanrus",         -- level 101, TDS
            "Aria of Va'Ker",            -- level 96, RoF
            "Aria of the Orator",        -- level 91, VoA
            "Aria of the Composer",      -- level 86, HoT
            "Aria of the Poet",          -- level 81, SoD
            "Aria of the Artist",        -- level 76, SoF
            "Ancient: Call of Power",    -- level 70, OoW
            "Eriki's Psalm of Power",    -- level 69, OoW
            "Yelhun's Mystic Call",      -- level 68, OoW
            "Echo of the Trusik",        -- level 65, GoD
            "Rizlona's Call of Flame",   -- level 64, PoP (overhaste/spell damage)
        },
        ['OverhasteSong'] = {            -- before effects are combined in aria
            "Warsong of the Vah Shir",   -- level 60, SoL (overhaste only)
            "Battlecry of the Vah Shir", -- level 52, SoL (overhaste only)
        },
        ['SpellDmgSong'] = {             -- before effects are combined in aria
            "Rizlona's Fire",            -- level 53, LDoN (spell damage only)
            "Rizlona's Embers",          -- level 45, LDoN (spell damage only)
        },
        ['SufferingSong'] = {
            "Sorrowful Song of Suffering IX", -- level 130, SoR
            "Kanghammer's Song of Suffering", -- level 125, LS
            "Shojralen's Song of Suffering",  -- level 119, ToL
            "Omorden's Song of Suffering",    -- level 114, ToV
            "Travenro's Song of Suffering",   -- level 109, RoS
            "Fjilnauk's Song of Suffering",   -- level 104, TDS
            "Kaficus' Song of Suffering",     -- level 99, RoF
            "Hykast's Song of Suffering",     -- level 94, VoA
            "Noira's Song of Suffering",      -- level 89. HoT
            "Storm Blade",                    -- level 69, DoN (not the same song line, but is a HP decrease proc)
            "Song of the Storm",              -- level 61, DoN (not the same song line, but is a HP decrease proc)
        },
        ['SprySonataSong'] = {
            "Boberstler's Spry Sonata", -- level 128, SoR
            "Dhakka's Spry Sonata",     -- level 123, LS
            "Xetheg's Spry Sonata",     -- level 118, ToL
            "Kellek's Spry Sonata",     -- level 113, ToV
            "Kluzen's Spry Sonata",     -- level 108, RoS
            "Doben's Spry Sonata",      -- level 98, RoF
            "Terasal's Spry Sonata",    -- level 93, VoA
            "Sionachie's Spry Sonata",  -- level 88, HoT
            "Dance of the Dragorn",     -- level 83, SoD
            "Coldcrow's Spry Sonata",   -- level 78, SoF
            "Aviak's Wondrous Warble",  -- Level 73, TBS
        },
        ['CrescendoSong'] = {
            "Alliana's Lively Crescendo",    -- level 129, SoR
            "Regar's Lively Crescendo",      -- level 124. LS
            "Zelinstein's Lively Crescendo", -- level 119, ToL
            "Zburator's Lively Crescendo",   -- level 114, ToV
            "Jembel's Lively Crescendo",     -- level 109, RoS
            "Silisia's Lively Crescendo",    -- level 104, TDS
            "Motlak's Lively Crescendo",     -- level 100, RoF
            "Kolain's Lively Crescendo",     -- level 95, VoA
            "Lyssa's Lively Crescendo",      -- level 90, HoT
            "Gruber's Lively Crescendo",     -- level 85, SoD
            "Kaerra's Spirited Crescendo",   -- level 80, SoF
            "Veshma's Lively Crescendo",     -- level 75, TSS
        },
        ['ArcaneSong'] = {
            "Arcane Aria XII", -- level 129, SoR
            "Arcane Rhythm",   -- level 124, LS
            "Arcane Harmony",  -- level 120, ToL
            "Arcane Symphony", -- level 115, ToV
            "Arcane Ballad",   -- level 110, RoS
            "Arcane Melody",   -- level 105, TDS
            "Arcane Hymn",     -- level 100, RoF
            "Arcane Address",  -- level 95, VoA
            "Arcane Chorus",   -- level 90, HoT
            "Arcane Arietta",  -- level 85, SoD
            "Arcane Anthem",   -- level 80, SoF (only spell proc)
            "Arcane Aria",     -- level 70, PoR (only spell proc)
        },
        ['InsultSong'] = {     --alternating timers are necessary to always use the best when the user only opts to use one insult
            --Bard Timers alternate between 6 and 3 every expansion, with some early exception. Use nopush if available.
            -- "Cutting Insult X",      -- level 127, SoR (push, timer 6)
            "Yaran's Disdain",  -- level 123, TOB (nopush, timer 3)
            -- "Eoreg's Insult",        -- level 122, LS (push, timer 3)
            "Nord's Disdain",   -- level 118, NoS (nopush, timer 6)
            -- "Sogran's Insult",       -- level 117, ToL (push, timer 6)
            "Yelinak's Insult", -- level 115, CoV (nopush, timer 3)
            --"Omorden's Insult",       -- level 112, ToV (push, timer 3)
            "Sathir's Insult",  -- level 110, RoS (nopush, timer 6)
            --"Travenro's Insult",      -- level 107, RoS (push, timer 6)
            "Tsaph's Insult",   -- level 105, Eok (nopush, timer 3)
            -- "Fjilnauk's Insult",      -- level 102, TDS (push, timer 3)
            -- "Kaficus' Insult",  -- level 100, RoF (push, timer 6)
            "Garath's Insult",  -- level 97, CoTH (nopush, timer 6)
            "Hykast's Insult",  -- level 95, VoA (push, timer 3)
            "Lyrin's Insult",   -- level 90, HoT (push, timer 6)
            "Venimor's Insult", -- level 85, UF (push, timer 3)
        },
        ['InsultSong2'] = {
            --Keep these two sets identical so timers will always be different unless people skip spells (which is their problem)
            -- "Cutting Insult X",      -- level 127, SoR (push, timer 6)
            "Yaran's Disdain",  -- level 123, TOB (nopush, timer 3)
            -- "Eoreg's Insult",        -- level 122, LS (push, timer 3)
            "Nord's Disdain",   -- level 118, NoS (nopush, timer 6)
            -- "Sogran's Insult",       -- level 117, ToL (push, timer 6)
            "Yelinak's Insult", -- level 115, CoV (nopush, timer 3)
            --"Omorden's Insult",       -- level 112, ToV (push, timer 3)
            "Sathir's Insult",  -- level 110, RoS (nopush, timer 6)
            --"Travenro's Insult",      -- level 107, RoS (push, timer 6)
            "Tsaph's Insult",   -- level 105, Eok (nopush, timer 3)
            -- "Fjilnauk's Insult",      -- level 102, TDS (push, timer 3)
            -- "Kaficus' Insult",  -- level 100, RoF (push, timer 6)
            "Garath's Insult",  -- level 97, CoTH (nopush, timer 6)
            "Hykast's Insult",  -- level 95, VoA (push, timer 3)
            "Lyrin's Insult",   -- level 90, HoT (push, timer 6)
            "Venimor's Insult", -- level 85, UF (push, timer 3)
        },
        ['LLInsultSong'] = {    -- use the lowest we have until we have a nopush, then use that
            "Garath's Insult",  -- level 97, CoTH (nopush, timer 6)
            "Lyrin's Insult",   -- level 90, HoT (push, timer 6)
        },
        ['LLInsultSong2'] = {   -- use the lowest we have until we have a nopush, then use that
            "Tsaph's Insult",   -- level 105, Eok (nopush, timer 3)
            "Venimor's Insult", -- level 85, UF (push, timer 3)
        },
        ['DichoSong'] = {
            -- DichoSong Level Range - 101+
            "Reciprocal Psalm", -- level 121, ToB
            "Ecliptic Psalm",   -- level 116, NoS
            "Composite Psalm",  -- level 111, CoV
            "Dissident Psalm",  -- level 106, TBL
            "Dichotomic Psalm", -- level 101, TBM
        },
        ['BardDPSAura'] = {
            "Aura of Kenburk",       -- level 130, SoR
            "Aura of Tenisbre",      -- level 125, LS
            "Aura of Pli Xin Liako", -- level 120, ToL
            "Aura of Margidor",      -- level 115, ToV
            "Aura of Begalru",       -- level 110, RoS
            "Aura of Maetanrus",     -- level 105, TDS
            "Aura of Va'Ker",        -- level 100, RoF
            "Aura of the Orator",    -- level 95, VoA
            "Aura of the Composer",  -- level 90, HoT
            "Aura of the Poet",      -- level 85, SoD
            "Aura of the Artist",    -- level 80, SoF
            "Aura of the Muse",      -- level 70, PoR
            "Aura of Insight",       -- level 55, PoR
        },
        ['BardRegenAura'] = {
            "Aura of Quellious",     -- level 127, SoR
            "Aura of Shalowain",     -- level 122, LS
            "Aura of Shei Vinitras", -- level 117, ToL
            "Aura of Vhal`Sera",     -- level 112, ToV
            "Aura of Xigam",         -- level 107, RoS
            "Aura of Sionachie",     -- level 102, TDS
            "Aura of Salarra",       -- level 97, RoF
            "Aura of Lunanyn",       -- level 92, VoA
            "Aura of Renewal",       -- level 87, HoT
            "Aura of Rodcet",        -- level 82, SoD
        },
        ['GroupRegenSong'] = {
            --Note level 77 pulse only offers a heal% buff and is not included here.
            "Pulse of Quellious",            -- level 126, SoR
            "Pulse of August",               -- level 121, LS
            "Pulse of Nikolas",              -- level 116, ToL
            "Pulse of Vhal`Sera",            -- level 111, ToV
            "Pulse of Xigam",                -- level 106, RoS
            "Pulse of Sionachie",            -- level 101, TDS
            "Pulse of Salarra",              -- level 96, RoF
            "Pulse of Lunanyn",              -- level 91, VoA
            "Pulse of Renewal",              -- levle 86 (start hp/mana/endurance/increased healing)
            "Cantata of Rodcet",             -- level 81, SoD
            "Cantata of Restoration",        -- level 76, SoF
            "Erollisi's Cantata",            -- level 71, TSS
            "Cantata of Life",               -- level 67, OoW
            "Wind of Marr",                  -- level 62, PoP
            "Cantata of Replenishment",      -- level 55, RoK
            "Cantata of Soothing",           -- level 34, SoV (start hp/mana. Slightly less mana. They can custom if it they want the 2 mana/tick)
            "Cassindra's Chorus of Clarity", -- level 32, Base Game (mana only)
            "Cassindra's Chant of Clarity",  -- level 20, SoL (mana only)
            "Hymn of Restoration",           -- level 6, Base Game (hp only)
        },
        ['AreaRegenSong'] = {
            "Chorus of Quellious",     -- level 125, SoR
            "Chorus of Shalowain",     -- level 123, LS
            "Chorus of Shei Vinitras", -- level 118, ToL
            "Chorus of Vhal`Sera",     -- level 113, ToV
            "Chorus of Xigam",         -- level 108, RoS
            "Chorus of Sionachie",     -- level 103, TDS
            "Chorus of Salarra",       -- level 98, RoF
            "Chorus of Lunanyn",       -- level 93, VoA
            "Chorus of Renewal",       -- level 88, HoT
            "Chorus of Rodcet",        -- level 83, SoD
            "Chorus of Restoration",   -- level 78, SoF
            "Erollisi's Chorus",       -- level 73, TSS
            "Chorus of Life",          -- level 69, OoW
            "Chorus of Marr",          -- level 64, PoP
            "Ancient: Lcea's Lament",  -- level 60, SoL
            "Chorus of Replenishment", -- level 58, SoL
        },
        ['WarMarchSong'] = {
            "War March of the Burning Host",    -- level 129, SoR
            "War March of Nokk",                -- level 124, LS
            "War March of Centien Xi Va Xakra", -- level 119, ToL
            "War March of Radiwol",             -- level 114, ToV
            "War March of Dekloaz",             -- level 109, RoS
            "War March of Jocelyn",             -- level 104, TDS
            "War March of Protan",              -- level 99, RoF
            "War March of Illdaera",            -- level 94, VoA
            "War March of Dagda",               -- level 89, HoT
            "War March of Brekt",               -- level 84, SoD
            "War March of Meldrath",            -- level 79, SoF
            "War March of Muram",               -- level 68, OoW
            "War March of the Mastruq",         -- level 65, GoD
            "Warsong of Zek",                   -- level 62, PoP
            "McVaxius' Rousing Rondo",          -- level 57, RoK
            "Vilia's Chorus of Celerity",       -- level 54, RoK (melee haste only, 45%)
            "Verses of Victory",                -- level 50, Base Game
            "McVaxius' Berserker Crescendo",    -- level 42, Base Game
            "Vilia's Verses of Celerity",       -- level 36, Base Game
            "Anthem de Arms",                   -- level 10, Base Game
        },
        ['FireBuffSong'] = {
            -- CasterAriaSong - Level Range 72+
            "Severyn's Aria",                    -- level 127, SoR
            "Flariton's Aria",                   -- level 122, LS
            "Constance's Aria",                  -- level 118, ToL
            "Sontalak's Aria",                   -- level 113, ToV
            "Qunard's Aria",                     -- level 108, RoS
            "Nilsara's Aria",                    -- level 103, TDS
            "Gosik's Aria",                      -- level 98, RoF
            "Daevan's Aria",                     -- level 93, VoA
            "Sotor's Aria",                      -- level 88, HoT
            "Talendor's Aria",                   -- level 83, SoD
            "Performer's Explosive Aria",        -- level 78, SoF
            "Performer's Psalm of Pyrotechnics", -- level 73, TSS
        },
        ['SlowSong'] = {
            "Requiem of Time",          -- level 64, PoP (slow only, best slow at 54%)
            "Angstlich's Assonance",    -- level 60, RoK, 40% slow (slow/HP DoT)
            "Largo's Assonant Binding", -- level 51, RoK, (35% slow, 131% snare)
            "Selo's Consonant Chain",   -- level 23, Base Game (40 % slow, 160% snare)
        },
        ['AESlowSong'] = {
            -- AESlowSong - Level Range 20 - 114 (Single target works better)
            "Zinnia's Melodic Binding",     -- level 124, LS
            "Radiwol's Melodic Binding",    -- level 114, ToV
            "Dekloaz's Melodic Binding",    -- level 109, RoS
            "Protan's Melodic Binding",     -- level 99, RoF
            "Zuriki's Song of Shenanigans", -- level 67, OoW
            "Melody of Mischief",           -- level 62, PoP
            "Selo's Assonant Strain",       -- level 54, RoK
            "Selo's Chords of Cessation",   -- level 48, Base Game
            "Largo's Melodic Binding",      -- level 20, Base Game
        },
        ['AccelerandoSong'] = {
            "Alleviating Accelerando VIII", -- level 128, SoR
            "Appeasing Accelerando",        -- level 123, LS
            "Satisfying Accelerando",       -- level 118 ToL
            "Placating Accelerando",        -- level 113, ToV
            "Atoning Accelerando",          -- level 108, RoS
            "Allaying Accelerando",         -- level 103, TDS
            "Ameliorating Accelerando",     -- level 98, RoF
            "Assuaging Accelerando",        -- level 93, VoA
            "Alleviating Accelerando",      -- level 88, HoT
        },
        ['SpitefulSong'] = {
            -- SpitefulSong - Level Range 90 -
            "Matriarch's Spiteful Lyric", -- level 130, SoR
            "Tatalros' Spiteful Lyric",   -- level 125, LS
            "Von Deek's Spiteful Lyric",  -- level 120, ToL
            "Omorden's Spiteful Lyric",   -- level 115, ToV
            "Travenro's Spiteful Lyric",  -- level 110, RoS
            "Fjilnauk's Spiteful Lyric",  -- level 105, TDS
            "Kaficus' Spiteful Lyric",    -- level 100, RoF
            "Hykast's Spiteful Lyric",    -- level 95, VoA
            "Lyrin's Spiteful Lyric",     -- level 90, HoT
        },
        ['RecklessSong'] = {
            "Onkrin's Reckless Renewal",   -- level 128, SoR
            "Grayleaf's Reckless Renewal", -- level 125, LS
            "Kai's Reckless Renewal",      -- level 118, ToL
            "Reivaj's Reckless Renewal",   -- level 113, ToV
            "Rigelon's Reckless Renewal",  -- level 108, RoS
            "Rytan's Reckless Renewal",    -- level 103, TDS
            "Ruaabri's Reckless Renewal",  -- level 98, RoF
            "Ryken's Reckless Renewal",    -- level 93 VoA
        },
        ['ColdBuffSong'] = {
            -- ColdBuffSong - Level Range 72 - 112 **
            "Fatesong of the Polar Vortex", -- level 127, SoR
            "Fatesong of Zoraxmen",         -- level 122, LS
            "Fatesong of Lucca",            -- level 117, ToL
            "Fatesong of Radiwol",          -- level 112, ToV
            "Fatesong of Dekloaz",          -- level 107, RoS
            "Fatesong of Jocelyn",          -- level 102, TDS
            "Fatesong of Protan",           -- level 97, RoF
            "Fatesong of Illdaera",         -- level 92, VoA
            "Fatesong of Fergar",           -- level 87, HoT
            "Fatesong of the Gelidran",     -- level 82, SoD
            "Garadell's Fatesong",          -- level 77, SoF
            "Weshlu's Chillsong Aria",      -- level 72, TSS
        },
        ['DotBuffSong'] = {
            -- Fire & Magic Dots song
            "Danfol's Psalm of Potency",       -- level 128, SoR
            "Tatalros' Psalm of Potency",      -- level 123, LS
            "Fyrthek Fior's Psalm of Potency", -- level 118, ToL
            "Velketor's Psalm of Potency",     -- level 113, ToV
            "Akett's Psalm of Potency",        -- level 108, RoS
            "Horthin's Psalm of Potency",      -- level 103, TDS
            "Siavonn's Psalm of Potency",      -- level 98, RoF
            "Wasinai's Psalm of Potency",      -- level 93, VoA
            "Lyrin's Psalm of Potency",        -- level 88, HoT
            "Druzzil's Psalm of Potency",      -- level 83, SoD
            "Erradien's Psalm of Potency",     -- level 78, SoF
        },
        ['FireDotSong'] = {
            "Severyn's Chant of Flame",     -- level 130, SoR
            "Kindleheart's Chant of Flame", -- level 125, LS
            "Shak Dathor's Chant of Flame", -- level 120, ToL
            "Sontalak's Chant of Flame",    -- level 115, ToV
            "Qunard's Chant of Flame",      -- level 110, RoS
            "Nilsara's Chant of Flame",     -- level 105, TDS
            "Gosik's Chant of Flame",       -- level 100, RoF
            "Daevan's Chant of Flame",      -- level 95, VoA
            "Sotor's Chant of Flame",       -- level 90, HoT
            "Talendor's Chant of Flame",    -- level 85, SoD
            "Tjudawos' Chant of Flame",     -- level 80 SoF
            "Vulka's Chant of Flame",       -- level 70, OoW
            "Tuyen's Chant of Fire",        -- level 65, PoP
            "Tuyen's Chant of Flame",       -- level 38, Base Game
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",         -- level 65, GoD
            "Angstlich's Assonance",        -- level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",    -- level 60, LDoN (also decrease magic resist 34)
            "Fufil's Curtailing Chant",     -- level 30, Base Game
        },
        ['IceDotSong'] = {
            "Tsikut's Chant of Frost",      -- level 127, SoR
            "Swarn's Chant of Frost",       -- level 122, LS
            "Sylra Fris' Chant of Frost",   -- level 117, ToL
            "Yelinak's Chant of Frost",     -- level 112, ToV
            "Ekron's Chant of Frost",       -- level 107, RoS
            "Kirchen's Chant of Frost",     -- level 102 TDS
            "Edoth's Chant of Frost",       -- level 97, RoF
            "Kalbrok's Chant of Frost",     -- level 92, VoA
            "Fergar's Chant of Frost",      -- level 87, HoT
            "Gorenaire's Chant of Frost",   -- level 82, SoD
            "Zeixshi-Kar's Chant of Frost", -- level 77, SoF
            "Vulka's Chant of Frost",       -- Level 67, OW
            "Tuyen's Chant of Ice",         -- level 63, PoP
            "Tuyen's Chant of Frost",       -- level 46, Base Game
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",         -- level 65, GoD
            "Angstlich's Assonance",        -- level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",    -- level 60, LDoN (also decrease magic resist 34)
            "Fufil's Curtailing Chant",     -- level 30, Base Game
        },
        ['PoisonDotSong'] = {
            "Khrosik's Chant of Poison",      -- level 128, SoR
            "Marsin's Chant of Poison",       -- level 123, LS
            "Cruor's Chant of Poison",        -- level 118, ToL
            "Malvus's Chant of Poison",       -- level 113, ToV
            "Nexona's Chant of Poison",       -- level 108, RoS
            "Serisaria's Chant of Poison",    -- level 103, TDS
            "Slaunk's Chant of Poison",       -- level 98, RoF
            "Hiqork's Chant of Poison",       -- level 93, VoA
            "Spinechiller's Chant of Poison", -- level 88, HoT
            "Severilous' Chant of Poison",    -- level 83 SoD
            "Kildrukaun's Chant of Poison",   -- level 78, SoF
            "Vulka's Chant of Poison",        -- level 68, OoW
            "Tuyen's Chant of Venom",         -- level 63, PoP
            "Tuyen's Chant of Poison",        -- level 50, PoP
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",           -- level 65, GoD
            "Angstlich's Assonance",          -- level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",      -- level 60, LDoN (also decrease magic resist 34)
            "Fufil's Curtailing Chant",       -- level 30, Base Game
        },
        ['DiseaseDotSong'] = {
            "Pustim's Chant of Disease",     -- level 126, SoR
            "Goremand's Chant of Disease",   -- level 121, LS
            "Coagulus' Chant of Disease",    -- level 116. ToL
            "Zlexak's Chant of Disease",     -- level 111, ToV
            "Hoshkar's Chant of Disease",    -- level 106, RoS
            "Horthin's Chant of Disease",    -- level 101, TDS
            "Siavonn's Chant of Disease",    -- level 96, RoF
            "Wasinai's Chant of Disease",    -- level 91, VoA
            "Shiverback's Chant of Disease", -- level 86, HoT
            "Trakanon's Chant of Disease",   -- level 81, SoD
            "Vyskudra's Chant of Disease",   -- level 76, SoF
            "Vulka's Chant of Disease",      -- level 66, OoW
            "Tuyen's Chant of the Plague",   -- level 61, PoP
            "Tuyen's Chant of Disease",      -- level 42, PoP
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",          -- level 65, GoD
            "Angstlich's Assonance",         -- level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",     -- level 60, LDoN (also decrease magic resist 34)
            "Fufil's Curtailing Chant",      -- level 30, Base Game
        },
        ['CureSong'] = {
            "Mastery: Aria of Absolution", -- level 126, SoR
            "Aria of Absolution",          -- level 96, RoF
            "Aria of Impeccability",       -- level 91, VoA
            "Aria of Amelioration",        -- level 86, HoT
            --"Firion's Blessed Clarinet",          -- level 84, SoD (corruption only)
            --"Kirathas' Cleansing Clarinet",       -- level 79, SoF (corruption only)
            --"Aria of Innocence",                  -- level 52, LoY (curse only)
            "Aria of Asceticism", -- level 45, LoY (poison/disease only)
        },
        ['AllianceSong'] = {
            "Covariance of Sticks and Stones",  -- level 125, ToB
            "Conjunction of Sticks and Stones", -- level 120, NoS
            "Coalition of Sticks and Stones",   -- level 115, CoV
            "Covenant of Sticks and Stones",    -- level 110, TBL
            "Alliance of Sticks and Stones",    -- level 102, EoK
        },
        ['CharmSong'] = {
            -- Demand line has memblur chance, but costs significantly more mana
            "Voice of Keftlik",           -- level 129, SoR (up to 128)
            -- "Yaran's Demand",                   -- level 124, ToB (up to 123, 40% memblur)
            "Voice of Suja",              -- level 124, LS (up to 123)
            -- "Omiyad's Demand",                   -- level 119, NoS (up to 118, 40% memblur)
            "Voice of the Diabo",         -- level 119, ToL (up to 118)
            -- "Desirae's Demand",                  -- level 114. CoV (up to 113, 40% memblur)
            "Voice of Zburator",          -- level 114, ToV (up to 113)
            -- "Dawnbreeze's Demand",               -- level 109, TBL (up to 108, 40% memblur)
            "Voice of Jembel",            -- level 109, RoS (up to 108)
            -- "Silisia's Demand",                  -- level 102, EoK (up to 103, 40% memblur)
            "Voice of Silisia",           -- level 104, TDS (up to 103)
            "Voice of Motlak",            -- level 99, RoF (up to 98)
            "Voice of Kolain",            -- level 94, VoA (up to 94)
            "Voice of Sionachie",         -- level 89, HoT (up to 88)
            "Voice of the Mindshear",     -- level 84, SoD (up to SoD)
            "Yowl of the Bloodmoon",      -- level 79, SoF (up to 78)
            "Beckon of the Tuffein",      -- level 73, TSS (up to 73)
            "Voice of the Vampire",       -- level 70, OoW (up to 68)
            "Call of the Banshee",        -- level 64, PoP (up to 57)
            "Solon's Bewitching Bravura", -- level 39, Base Game (up to 51)
            "Solon's Song of the Sirens", -- level 27, Base Game (up to 37)
        },
        ['ReflexStrike'] = {
            -- Bard ReflexStrike - Restores mana to group
            "Reflexive Retort",
            "Reflexive Rejoinder",
            "Reflexive Rebuttal",
        },
        ['ChordsAE'] = {
            -- ChordsAE only work if target is not moving on Live
            "Selo's Chords of Cessation", -- level 48, Base Game
            "Chords of Dissonance",       -- level 2, Base Game
        },
        ['AmpSong'] = {
            "Amplification", -- level 30, SoL
        },
        ['DispelSong'] = {
            -- Dispel Song - For pulling to avoid Summons
            "Druzzil's Disillusionment",  -- level 62, PoP (dispel 9)
            -- "Song of Highsun",                  -- level 56, RoK (dispel 9, also ports NPC to spawn point)
            "Syvelian's Anti-Magic Aria", -- level 40, Base Game (dispel 4)
        },
        ['ResistSong'] = {
            -- Resists Song
            "Psalm of Veeshan VII",    -- level 128, SoR
            "Psalm of the Nomad",      -- level 123, LS
            "Psalm of the Pious",      -- level 118, ToL
            "Psalm of the Restless",   -- level 113, ToV
            "Second Psalm of Veeshan", -- level 108, RoS
            "Psalm of the Forsaken",   -- level 98, CoTF
            "Psalm of Veeshan",        -- level 63, PoP
            "Psalm of Purity",         -- level 37, Base Game (poison only)
            "Psalm of Cooling",        -- level 33, Base Game (fire onyl)
            "Psalm of Vitality",       -- level 29, Base Game (disease only)
            "Psalm of Warmth",         -- level 25, Base Game (cold only)
        },
        ['MezSong'] = {
            -- Lullaby line has lower max level and has pushback, but you get them earlier.
            "Slumber of Keftlik	",      -- level 129, SoR (up to 133)
            -- "Lullaby of the Sundered",            -- level 126, SoR (up to 130)
            "Slumber of Suja",          -- level 124, LS (up to 128,)
            -- "Lullaby of the Forgotten",           -- level 121, LS (up to 125)
            "Slumber of the Diabo",     -- level 119, ToL (up to 123)
            -- "Lullaby of Nightfall",              -- level 116, ToL (up to 120)
            "Slumber of Zburator",      -- level 114, ToV (up to 118)
            -- "Lullaby of Zburator",               -- level 111, ToV (up to 115)
            "Slumber of Jembel",        -- level 109, RoS (up to 113)
            -- "Lullaby of Jembel",                 -- level 106, RoS (up to 110)
            "Slumber of Silisia",       -- level 104, TDS (up to 108)
            -- "Lullaby of Silisia",                -- level 101, TDS (up to 105)
            "Slumber of Motlak",        -- level 99, RoF (up to 103)
            -- "Lullaby of the Forsaken",           -- level 96, RoF (up to 100)
            "Slumber of Kolain",        -- level 94, VoA (up to 98)
            -- "Lullaby of the Forlorn",            -- level 91, VoA (up to 95)
            "Slumber of Sionachie",     -- level 89, HoT (up to 93)
            -- "Lullaby of the Lost",               -- level 86, HoT (up to 90)
            "Slumber of the Mindshear", -- level 84, SoD (up to 88)
            -- "Serenity of Oceangreen",            -- level 81, SoD (up to 85)
            "Command of Queen Veneneu", -- level 79, SoF (up to 83)
            -- "Amber's Last Lullaby",              -- level 76, SoF (up to 80)
            "Queen Eletyl's Screech",   -- level 74, TSS (up to 79)
            -- "Aelfric's Last Lullaby",            -- level 71, TSS (up to 75)
            "Vulka's Lullaby",          -- level 70, OoW (up to 73)
            "Creeping Dreams",          -- level 68, DoD (up to 73)
            "Luvwen's Lullaby",         -- level 67, OoW (up to 70)
            "Lullaby of Morell",        -- level 65, PoP (up to 68)
            "Dreams of Terris",         -- level 64, PoP (up to 65)
            "Dreams of Thule",          -- level 62, PoP (up to 62)
            "Dreams of Ayonae",         -- level 58, SoL (up to 57)
            "Song of Twilight",         -- level 53, RoK (up to 55)
            "Sionachie's Dreams",       -- level 40, SoL (up to 53)
            "Crission's Pixie Strike",  -- level 28, Base Game (up to 45)
            "Kelin's Lucid Lullaby",    -- level 15, Base Game (up to 30)
        },
        ['MezAESong'] = {
            -- MezAESong - Level Range 85 - 115 **
            "Wave of Slumber X",     -- level 130, SoR (up to 133)
            "Wave of Stupor",        -- level 125, LS (up to 128)
            "Wave of Nocturn",       -- level 120, ToL (up to 123)
            "Wave of Sleep",         -- level 115, ToV (up to 118)
            "Wave of Somnolence",    -- level 110, RoS (up to 113)
            "Wave of Torpor",        -- level 105, TDS (up to 108)
            "Wave of Quietude",      -- level 100, RoF (up to 103)
            "Wave of the Conductor", -- level 95, VoA (up to 98)
            "Wave of Dreams",        -- level 90, HoT (up to 93)
            "Wave of Slumber",       -- level 85. UF (up to 88)
        },
        ['Jonthan'] = {
            "Jonthan's Mightful Caretaker", -- level 71,. TBS
            "Jonthan's Inspiration",        -- level 58, RoK
            "Jonthan's Provocation",        -- level 45, Base Game
            "Jonthan's Whistling Warsong",  -- level 7, Base Game
        },
        ['CalmSong'] = {
            -- CalmSong - Level Range 8+ --Included for manual use with /rgl usemap
            "Silence of the Vortex",     -- Level 126, SoR (up to 130)
            "Silence of the Forgotten",  -- Level 121, LS (up to 125)
            "Silence of Quietus",        -- Level 116, TOL (up to 120)
            "Silence of Zburator",       -- Level 111, ToV (up to 115)
            "Silence of Jembel",         -- Level 106, RoS (up to 110)
            "Silence of the Silisia",    -- Level 101, TDS (up to 105)
            "Silence of the Forsaken",   -- Level 96, RoF (up to 100)
            "Silence of the Windsong",   -- Level 91, VoA (up to 95)
            "Silence of the Dreamer",    -- Level 86, HoT (up to 90)
            "Silence of the Void",       -- Level 81, SoD (up to 85)
            "Elddar's Dawnsong",         -- Level 76, SoF (up to 80)
            "Whispersong of Veshma",     -- Level 71, TSS (up to 75)
            "Luvwen's Aria of Serenity", -- Level 66, OoW (up to 70)
            "Silent Song of Quellious",  -- Level 61, PoP (up to 65)
            "Kelin's Lugubrious Lament", -- Level 8, Base Game, (up to 60)
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
