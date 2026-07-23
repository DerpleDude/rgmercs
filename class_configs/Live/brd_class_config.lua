--- @type Mq
local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require("utils.combat")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local ItemManager  = require('utils.item_manager')
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")

local Tooltips     = {
    Epic            = 'Item: Casts Epic Weapon Ability',
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
    _version              = "2.4 - Live",
    _author               = "Algar, Derple, Grimmier, Tiddliestix, SonicZentropy",
    ['Modes']             = {
        'General',
    },
    ['OnModeChange']      = function(self, mode)
        local warMarch = Core.GetResolvedActionMapItem('WarMarchSong')
        if warMarch then
            self.TempSettings.MarchDuration = warMarch.MyDuration.TotalSeconds() or 0
        end
    end,

    ['ModeChecks']        = {
        CanMez    = function() return true end,
        CanCharm  = function() return true end,
        IsMezzing = function() return Config:GetSetting('MezOn') end,
        IsCuring  = function() return Config:GetSetting('UseCure') end,
    },
    ['Cure']              = {
        ['Poison'] = {
            { type = "Song", name = "CureSong", },
        },
        ['Disease'] = {
            { type = "Song", name = "CureSong", },
        },
        ['Corruption'] = {
            { type = "Song", name = "CureSong", },
        },
    },
    ['Themes']            = {
        ['General'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.50, g = 0.08, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.50, g = 0.08, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.20, g = 0.03, b = 0.14, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.50, g = 0.08, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.50, g = 0.08, b = 0.35, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.20, g = 0.03, b = 0.14, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.50, g = 0.08, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.50, g = 0.08, b = 0.35, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.50, g = 0.08, b = 0.35, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.33, g = 0.05, b = 0.23, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.50, g = 0.08, b = 0.35, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.50, g = 0.08, b = 0.35, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.50, g = 0.08, b = 0.35, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.20, g = 0.03, b = 0.14, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.80, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.80, b = 0.10, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.50, g = 0.08, b = 0.35, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Blade of Vesagran",
            "Prismatic Dragon Blade",
        },
        ['Coating'] = {
            "Spirit Drinker's Coating",
            "Blood Drinker's Coating",
        },
    },
    ['AbilitySets']       = {
        ['RunBuffSong'] = {
            -- Selo's Accelerato not used so that we don't go back to a short duration
            -- Other songs omitted due to issues with constant reinvis, etc.
            "Selo's Accelerating Chorus", -- Level 49, SoL
            "Selo's Accelerando",         -- Level 5, Base Game
        },
        ['EndBreathSong'] = {
            "Tarew's Aquatic Ayre", -- Level 16, Base Game
        },
        ['AriaSong'] = {
            "Aria of Kenburk",           -- Level 126, SoR
            "Aria of Tenisbre",          -- Level 121, LS
            "Aria of Pli Xin Liako",     -- Level 116, ToL
            "Aria of Margidor",          -- Level 111, ToV
            "Aria of Begalru",           -- Level 106, RoS
            "Aria of Maetanrus",         -- Level 101, TDS
            "Aria of Va'Ker",            -- Level 96, RoF
            "Aria of the Orator",        -- Level 91, VoA
            "Aria of the Composer",      -- Level 86, HoT
            "Aria of the Poet",          -- Level 81, SoD
            "Aria of the Artist",        -- Level 76, SoF
            "Ancient: Call of Power",    -- Level 70, OoW
            "Eriki's Psalm of Power",    -- Level 69, OoW
            "Yelhun's Mystic Call",      -- Level 68, OoW
            "Echo of the Trusik",        -- Level 65, GoD
            "Call of the Muse",          -- Level 65, LDoN
            "Rizlona's Call of Flame",   -- Level 64, PoP (overhaste/spell damage)
        },
        ['OverhasteSong'] = {            -- before effects are combined in aria
            "Warsong of the Vah Shir",   -- Level 60, SoL (overhaste only)
            "Battlecry of the Vah Shir", -- Level 52, SoL (overhaste only)
        },
        ['SpellDmgSong'] = {             -- before effects are combined in aria
            "Rizlona's Fire",            -- Level 53, LDoN (spell damage only)
            "Rizlona's Embers",          -- Level 45, LDoN (spell damage only)
        },
        ['SufferingSong'] = {
            "Sorrowful Song of Suffering IX", -- Level 130, SoR
            "Kanghammer's Song of Suffering", -- Level 124, LS
            "Shojralen's Song of Suffering",  -- Level 119, ToL
            "Omorden's Song of Suffering",    -- Level 114, ToV
            "Travenro's Song of Suffering",   -- Level 109, RoS
            "Fjilnauk's Song of Suffering",   -- Level 104, TDS
            "Kaficus' Song of Suffering",     -- Level 99, RoF
            "Hykast's Song of Suffering",     -- Level 94, VoA
            "Noira's Song of Suffering",      -- Level 89, . HoT
            "Storm Blade",                    -- Level 69, DoN (not the same song line, but is a HP decrease proc)
            "Song of the Storm",              -- Level 61, DoN (not the same song line, but is a HP decrease proc)
        },
        ['SprySonataSong'] = {
            "Boberstler's Spry Sonata",  -- Level 128, SoR
            "Dhakka's Spry Sonata",      -- Level 123, LS
            "Xetheg's Spry Sonata",      -- Level 118, ToL
            "Kellek's Spry Sonata",      -- Level 113, ToV
            "Kluzen's Spry Sonata",      -- Level 108, RoS
            "Doben's Spry Sonata",       -- Level 98, RoF
            "Terasal's Spry Sonata",     -- Level 93, VoA
            "Sionachie's Spry Sonata",   -- Level 88, HoT
            "Dance of the Dragorn",      -- Level 83, SoD
            "Coldcrow's Spry Sonata",    -- Level 78, SoF
            "Aviak's Wondrous Warble",   -- Level 73, TBS
            "Niv's Harmonic",            -- Level 58, RoK
            "Psalm of Mystic Shielding", -- Level 41, Base Game
        },
        ['CrescendoSong'] = {
            "Alliana's Lively Crescendo",    -- Level 129, SoR
            "Regar's Lively Crescendo",      -- Level 124, LS
            "Zelinstein's Lively Crescendo", -- Level 119, ToL
            "Zburator's Lively Crescendo",   -- Level 114, ToV
            "Jembel's Lively Crescendo",     -- Level 109, RoS
            "Silisia's Lively Crescendo",    -- Level 104, TDS
            "Motlak's Lively Crescendo",     -- Level 100, RoF
            "Kolain's Lively Crescendo",     -- Level 95, VoA
            "Lyssa's Lively Crescendo",      -- Level 90, HoT
            "Gruber's Lively Crescendo",     -- Level 85, SoD
            "Kaerra's Spirited Crescendo",   -- Level 80, SoF
            "Veshma's Lively Crescendo",     -- Level 75, TSS
        },
        ['ArcaneSong'] = {
            "Arcane Aria XII", -- Level 129, SoR
            "Arcane Rhythm",   -- Level 124, LS
            "Arcane Harmony",  -- Level 120, ToL
            "Arcane Symphony", -- Level 115, ToV
            "Arcane Ballad",   -- Level 110, RoS
            "Arcane Melody",   -- Level 105, TDS
            "Arcane Hymn",     -- Level 100, RoF
            "Arcane Address",  -- Level 95, VoA
            "Arcane Chorus",   -- Level 90, HoT
            "Arcane Arietta",  -- Level 85, SoD
            "Arcane Anthem",   -- Level 80, SoF (only spell proc)
            "Arcane Aria",     -- Level 70, PoR (only spell proc)
        },
        ['InsultSong'] = {     --alternating timers are necessary to always use the best when the user only opts to use one insult
            --Bard Timers alternate between 6 and 3 every expansion, with some early exception. Use nopush if available.
            -- "Cutting Insult X",  -- Level 127, SoR (push, timer 6)
            "Yaran's Disdain",  -- Level 123, TOB (nopush, timer 3)
            -- "Eoreg's Insult",    -- Level 122, LS (push, timer 3)
            "Nord's Disdain",   -- Level 118, NoS (nopush, timer 6)
            -- "Sogran's Insult",   -- Level 117, ToL (push, timer 6)
            "Yelinak's Insult", -- Level 115, CoV (nopush, timer 3)
            -- "Omorden's Insult",  -- Level 112, ToV (push, timer 3)
            "Sathir's Insult",  -- Level 110, RoS (nopush, timer 6)
            -- "Travenro's Insult", -- Level 107, RoS (push, timer 6)
            "Tsaph's Insult",   -- Level 105, Eok (nopush, timer 3)
            -- "Fjilnauk's Insult", -- Level 102, TDS (push, timer 3)
            -- "Kaficus' Insult",   -- Level 100, RoF (push, timer 6)
            "Garath's Insult",  -- Level 97, CoTH (nopush, timer 6)
            "Hykast's Insult",  -- Level 95, VoA (push, timer 3)
            "Lyrin's Insult",   -- Level 90, HoT (push, timer 6)
            "Venimor's Insult", -- Level 85, UF (push, timer 3)
        },
        ['InsultSong2'] = {
            --Keep these two sets identical so timers will always be different unless people skip spells (which is their problem)
            -- "Cutting Insult X",  -- Level 127, SoR (push, timer 6)
            "Yaran's Disdain",  -- Level 123, TOB (nopush, timer 3)
            -- "Eoreg's Insult",    -- Level 122, LS (push, timer 3)
            "Nord's Disdain",   -- Level 118, NoS (nopush, timer 6)
            -- "Sogran's Insult",   -- Level 117, ToL (push, timer 6)
            "Yelinak's Insult", -- Level 115, CoV (nopush, timer 3)
            -- "Omorden's Insult",  -- Level 112, ToV (push, timer 3)
            "Sathir's Insult",  -- Level 110, RoS (nopush, timer 6)
            -- "Travenro's Insult", -- Level 107, RoS (push, timer 6)
            "Tsaph's Insult",   -- Level 105, Eok (nopush, timer 3)
            -- "Fjilnauk's Insult", -- Level 102, TDS (push, timer 3)
            -- "Kaficus' Insult",   -- Level 100, RoF (push, timer 6)
            "Garath's Insult",  -- Level 97, CoTH (nopush, timer 6)
            "Hykast's Insult",  -- Level 95, VoA (push, timer 3)
            "Lyrin's Insult",   -- Level 90, HoT (push, timer 6)
            "Venimor's Insult", -- Level 85, UF (push, timer 3)
        },
        ['LLInsultSong'] = {    -- use the lowest we have until we have a nopush, then use that
            "Garath's Insult",  -- Level 97, CoTH (nopush, timer 6)
            "Lyrin's Insult",   -- Level 90, HoT (push, timer 6)
        },
        ['LLInsultSong2'] = {   -- use the lowest we have until we have a nopush, then use that
            "Tsaph's Insult",   -- Level 105, Eok (nopush, timer 3)
            "Venimor's Insult", -- Level 85, UF (push, timer 3)
        },
        ['DichoSong'] = {
            -- DichoSong Level Range - 101+
            "Reciprocal Psalm", -- Level 121, ToB
            "Ecliptic Psalm",   -- Level 116, NoS
            "Composite Psalm",  -- Level 111, CoV
            "Dissident Psalm",  -- Level 106, TBL
            "Dichotomic Psalm", -- Level 101, TBM
        },
        ['BardDPSAura'] = {
            "Aura of Kenburk",       -- Level 130, SoR
            "Aura of Tenisbre",      -- Level 125, LS
            "Aura of Pli Xin Liako", -- Level 120, ToL
            "Aura of Margidor",      -- Level 115, ToV
            "Aura of Begalru",       -- Level 110, RoS
            "Aura of Maetanrus",     -- Level 105, TDS
            "Aura of Va'Ker",        -- Level 100, RoF
            "Aura of the Orator",    -- Level 95, VoA
            "Aura of the Composer",  -- Level 90, HoT
            "Aura of the Poet",      -- Level 85, SoD
            "Aura of the Artist",    -- Level 80, SoF
            "Aura of the Muse",      -- Level 70, PoR
            "Aura of Insight",       -- Level 55, PoR
        },
        ['BardRegenAura'] = {
            "Aura of Quellious",     -- Level 127, SoR
            "Aura of Shalowain",     -- Level 122, LS
            "Aura of Shei Vinitras", -- Level 117, ToL
            "Aura of Vhal`Sera",     -- Level 112, ToV
            "Aura of Xigam",         -- Level 107, RoS
            "Aura of Sionachie",     -- Level 102, TDS
            "Aura of Salarra",       -- Level 97, RoF
            "Aura of Lunanyn",       -- Level 92, VoA
            "Aura of Renewal",       -- Level 87, HoT
            "Aura of Rodcet",        -- Level 82, SoD
        },
        ['GroupRegenSong'] = {
            --Note level 77 pulse only offers a heal% buff and is not included here.
            "Pulse of Quellious",            -- Level 126, SoR
            "Pulse of August",               -- Level 121, LS
            "Pulse of Nikolas",              -- Level 116, ToL
            "Pulse of Vhal`Sera",            -- Level 111, ToV
            "Pulse of Xigam",                -- Level 106, RoS
            "Pulse of Sionachie",            -- Level 101, TDS
            "Pulse of Salarra",              -- Level 96, RoF
            "Pulse of Lunanyn",              -- Level 91, VoA
            "Pulse of Renewal",              -- Level 86, levle 86 (start hp/mana/endurance/increased healing)
            "Cantata of Rodcet",             -- Level 81, SoD
            "Cantata of Restoration",        -- Level 76, SoF
            "Erollisi's Cantata",            -- Level 71, TSS
            "Cantata of Life",               -- Level 67, OoW
            "Wind of Marr",                  -- Level 62, PoP
            "Cantata of Replenishment",      -- Level 55, RoK
            "Cantata of Soothing",           -- Level 34, SoV (start hp/mana. Slightly less mana. They can custom if it they want the 2 mana/tick)
            "Cassindra's Chorus of Clarity", -- Level 32, Base Game (mana only)
            "Cassindra's Chant of Clarity",  -- Level 20, SoL (mana only)
            "Hymn of Restoration",           -- Level 6, Base Game (hp only)
        },
        ['AreaRegenSong'] = {
            "Chorus of Quellious",     -- Level 128, SoR
            "Chorus of Shalowain",     -- Level 123, LS
            "Chorus of Shei Vinitras", -- Level 118, ToL
            "Chorus of Vhal`Sera",     -- Level 113, ToV
            "Chorus of Xigam",         -- Level 108, RoS
            "Chorus of Sionachie",     -- Level 103, TDS
            "Chorus of Salarra",       -- Level 98, RoF
            "Chorus of Lunanyn",       -- Level 93, VoA
            "Chorus of Renewal",       -- Level 88, HoT
            "Chorus of Rodcet",        -- Level 83, SoD
            "Chorus of Restoration",   -- Level 78, SoF
            "Erollisi's Chorus",       -- Level 73, TSS
            "Chorus of Life",          -- Level 69, OoW
            "Chorus of Marr",          -- Level 64, PoP
            "Ancient: Lcea's Lament",  -- Level 60, SoL
            "Chorus of Replenishment", -- Level 58, SoL
        },
        ['WarMarchSong'] = {
            "War March of the Burning Host",    -- Level 129, SoR
            "War March of Nokk",                -- Level 124, LS
            "War March of Centien Xi Va Xakra", -- Level 119, ToL
            "War March of Radiwol",             -- Level 114, ToV
            "War March of Dekloaz",             -- Level 109, RoS
            "War March of Jocelyn",             -- Level 104, TDS
            "War March of Protan",              -- Level 99, RoF
            "War March of Illdaera",            -- Level 94, VoA
            "War March of Dagda",               -- Level 89, HoT
            "War March of Brekt",               -- Level 84, SoD
            "War March of Meldrath",            -- Level 79, SoF
            "War March of Muram",               -- Level 68, OoW
            "War March of the Mastruq",         -- Level 65, GoD
            "Warsong of Zek",                   -- Level 62, PoP
            "McVaxius' Rousing Rondo",          -- Level 57, RoK
            "Vilia's Chorus of Celerity",       -- Level 54, RoK (melee haste only, 45%)
            "Verses of Victory",                -- Level 50, Base Game
            "McVaxius' Berserker Crescendo",    -- Level 42, Base Game
            "Vilia's Verses of Celerity",       -- Level 36, Base Game
            "Anthem de Arms",                   -- Level 10, Base Game
            "Chant of Battle",                  -- Level 1, Base Game
        },
        ['FireBuffSong'] = {
            -- CasterAriaSong - Level Range 72+
            "Severyn's Aria",                    -- Level 127, SoR
            "Flariton's Aria",                   -- Level 122, LS
            "Constance's Aria",                  -- Level 118, ToL
            "Sontalak's Aria",                   -- Level 113, ToV
            "Qunard's Aria",                     -- Level 108, RoS
            "Nilsara's Aria",                    -- Level 103, TDS
            "Gosik's Aria",                      -- Level 98, RoF
            "Daevan's Aria",                     -- Level 93, VoA
            "Sotor's Aria",                      -- Level 88, HoT
            "Talendor's Aria",                   -- Level 83, SoD
            "Performer's Explosive Aria",        -- Level 78, SoF
            "Performer's Psalm of Pyrotechnics", -- Level 73, TSS
        },
        ['SlowSong'] = {
            "Requiem of Time",          -- Level 64, PoP (slow only, best slow at 54%)
            "Angstlich's Assonance",    -- Level 60, RoK, 40% slow (slow/HP DoT)
            "Largo's Assonant Binding", -- Level 51, RoK, (35% slow, 131% snare)
            "Selo's Consonant Chain",   -- Level 23, Base Game (40 % slow, 160% snare)
        },
        ['AESlowSong'] = {
            -- AESlowSong - Level Range 20 - 114 (Single target works better)
            "Zinnia's Melodic Binding",     -- Level 124, LS
            "Radiwol's Melodic Binding",    -- Level 114, ToV
            "Dekloaz's Melodic Binding",    -- Level 109, RoS
            "Protan's Melodic Binding",     -- Level 99, RoF
            "Zuriki's Song of Shenanigans", -- Level 67, OoW
            "Melody of Mischief",           -- Level 62, PoP
            "Selo's Assonant Strain",       -- Level 54, RoK
            "Selo's Chords of Cessation",   -- Level 48, Base Game
            "Largo's Melodic Binding",      -- Level 20, Base Game
        },
        ['AccelerandoSong'] = {
            "Alleviating Accelerando VIII", -- Level 128, SoR
            "Appeasing Accelerando",        -- Level 123, LS
            "Satisfying Accelerando",       -- Level 118, ToL
            "Placating Accelerando",        -- Level 113, ToV
            "Atoning Accelerando",          -- Level 108, RoS
            "Allaying Accelerando",         -- Level 103, TDS
            "Ameliorating Accelerando",     -- Level 98, RoF
            "Assuaging Accelerando",        -- Level 93, VoA
            "Alleviating Accelerando",      -- Level 88, HoT
        },
        ['SpitefulSong'] = {
            -- SpitefulSong - Level Range 90 -
            "Matriarch's Spiteful Lyric", -- Level 130, SoR
            "Tatalros' Spiteful Lyric",   -- Level 125, LS
            "Von Deek's Spiteful Lyric",  -- Level 120, ToL
            "Omorden's Spiteful Lyric",   -- Level 115, ToV
            "Travenro's Spiteful Lyric",  -- Level 110, RoS
            "Fjilnauk's Spiteful Lyric",  -- Level 105, TDS
            "Kaficus' Spiteful Lyric",    -- Level 100, RoF
            "Hykast's Spiteful Lyric",    -- Level 95, VoA
            "Lyrin's Spiteful Lyric",     -- Level 90, HoT
        },
        ['RecklessSong'] = {
            "Onkrin's Reckless Renewal",   -- Level 128, SoR
            "Grayleaf's Reckless Renewal", -- Level 123, LS
            "Kai's Reckless Renewal",      -- Level 118, ToL
            "Reivaj's Reckless Renewal",   -- Level 113, ToV
            "Rigelon's Reckless Renewal",  -- Level 108, RoS
            "Rytan's Reckless Renewal",    -- Level 103, TDS
            "Ruaabri's Reckless Renewal",  -- Level 98, RoF
            "Ryken's Reckless Renewal",    -- Level 93, VoA
        },
        ['ColdBuffSong'] = {
            -- ColdBuffSong - Level Range 72 - 112 **
            "Fatesong of the Polar Vortex", -- Level 127, SoR
            "Fatesong of Zoraxmen",         -- Level 122, LS
            "Fatesong of Lucca",            -- Level 117, ToL
            "Fatesong of Radiwol",          -- Level 112, ToV
            "Fatesong of Dekloaz",          -- Level 107, RoS
            "Fatesong of Jocelyn",          -- Level 102, TDS
            "Fatesong of Protan",           -- Level 97, RoF
            "Fatesong of Illdaera",         -- Level 92, VoA
            "Fatesong of Fergar",           -- Level 87, HoT
            "Fatesong of the Gelidran",     -- Level 82, SoD
            "Garadell's Fatesong",          -- Level 77, SoF
            "Weshlu's Chillsong Aria",      -- Level 72, TSS
        },
        ['DotBuffSong'] = {
            -- Fire & Magic Dots song
            "Danfol's Psalm of Potency",       -- Level 128, SoR
            "Tatalros' Psalm of Potency",      -- Level 123, LS
            "Fyrthek Fior's Psalm of Potency", -- Level 118, ToL
            "Velketor's Psalm of Potency",     -- Level 113, ToV
            "Akett's Psalm of Potency",        -- Level 108, RoS
            "Horthin's Psalm of Potency",      -- Level 103, TDS
            "Siavonn's Psalm of Potency",      -- Level 98, RoF
            "Wasinai's Psalm of Potency",      -- Level 93, VoA
            "Lyrin's Psalm of Potency",        -- Level 88, HoT
            "Druzzil's Psalm of Potency",      -- Level 83, SoD
            "Erradien's Psalm of Potency",     -- Level 78, SoF
        },
        ['FireDotSong'] = {
            "Severyn's Chant of Flame",     -- Level 130, SoR
            "Kindleheart's Chant of Flame", -- Level 125, LS
            "Shak Dathor's Chant of Flame", -- Level 120, ToL
            "Sontalak's Chant of Flame",    -- Level 115, ToV
            "Qunard's Chant of Flame",      -- Level 110, RoS
            "Nilsara's Chant of Flame",     -- Level 105, TDS
            "Gosik's Chant of Flame",       -- Level 100, RoF
            "Daevan's Chant of Flame",      -- Level 95, VoA
            "Sotor's Chant of Flame",       -- Level 90, HoT
            "Talendor's Chant of Flame",    -- Level 85, SoD
            "Tjudawos' Chant of Flame",     -- Level 80, SoF
            "Vulka's Chant of Flame",       -- Level 70, OoW
            "Tuyen's Chant of Fire",        -- Level 65, PoP
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",         -- Level 65, GoD
            "Angstlich's Assonance",        -- Level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",    -- Level 60, LDoN (also decrease magic resist 34)
            "Tuyen's Chant of Flame",       -- Level 38, Base Game
            "Fufil's Curtailing Chant",     -- Level 30, Base Game
        },
        ['IceDotSong'] = {
            "Tsikut's Chant of Frost",      -- Level 127, SoR
            "Swarn's Chant of Frost",       -- Level 122, LS
            "Sylra Fris' Chant of Frost",   -- Level 117, ToL
            "Yelinak's Chant of Frost",     -- Level 112, ToV
            "Ekron's Chant of Frost",       -- Level 107, RoS
            "Kirchen's Chant of Frost",     -- Level 102, TDS
            "Edoth's Chant of Frost",       -- Level 97, RoF
            "Kalbrok's Chant of Frost",     -- Level 92, VoA
            "Fergar's Chant of Frost",      -- Level 87, HoT
            "Gorenaire's Chant of Frost",   -- Level 82, SoD
            "Zeixshi-Kar's Chant of Frost", -- Level 77, SoF
            "Vulka's Chant of Frost",       -- Level 67, OW
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",         -- Level 65, GoD
            "Tuyen's Chant of Ice",         -- Level 63, PoP
            "Angstlich's Assonance",        -- Level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",    -- Level 60, LDoN (also decrease magic resist 34)
            "Tuyen's Chant of Frost",       -- Level 46, Base Game
            "Fufil's Curtailing Chant",     -- Level 30, Base Game
        },
        ['PoisonDotSong'] = {
            "Khrosik's Chant of Poison",      -- Level 128, SoR
            "Marsin's Chant of Poison",       -- Level 123, LS
            "Cruor's Chant of Poison",        -- Level 118, ToL
            "Malvus's Chant of Poison",       -- Level 113, ToV
            "Nexona's Chant of Poison",       -- Level 108, RoS
            "Serisaria's Chant of Poison",    -- Level 103, TDS
            "Slaunk's Chant of Poison",       -- Level 98, RoF
            "Hiqork's Chant of Poison",       -- Level 93, VoA
            "Spinechiller's Chant of Poison", -- Level 88, HoT
            "Severilous' Chant of Poison",    -- Level 83, SoD
            "Kildrukaun's Chant of Poison",   -- Level 78, SoF
            "Vulka's Chant of Poison",        -- Level 68, OoW
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",           -- Level 65, GoD
            "Tuyen's Chant of Venom",         -- Level 63, PoP
            "Angstlich's Assonance",          -- Level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",      -- Level 60, LDoN (also decrease magic resist 34)
            "Tuyen's Chant of Poison",        -- Level 50, PoP
            "Fufil's Curtailing Chant",       -- Level 30, Base Game
        },
        ['DiseaseDotSong'] = {
            "Pustim's Chant of Disease",     -- Level 126, SoR
            "Goremand's Chant of Disease",   -- Level 121, LS
            "Coagulus' Chant of Disease",    -- Level 116, . ToL
            "Zlexak's Chant of Disease",     -- Level 111, ToV
            "Hoshkar's Chant of Disease",    -- Level 106, RoS
            "Horthin's Chant of Disease",    -- Level 101, TDS
            "Siavonn's Chant of Disease",    -- Level 96, RoF
            "Wasinai's Chant of Disease",    -- Level 91, VoA
            "Shiverback's Chant of Disease", -- Level 86, HoT
            "Trakanon's Chant of Disease",   -- Level 81, SoD
            "Vyskudra's Chant of Disease",   -- Level 76, SoF
            "Vulka's Chant of Disease",      -- Level 66, OoW
            -- Misc Dot -- Or Minsc Dot (HEY HEY BOO BOO!)
            "Ancient: Chaos Chant",          -- Level 65, GoD
            "Tuyen's Chant of the Plague",   -- Level 61, PoP
            "Angstlich's Assonance",         -- Level 60, RoK (also decrease melee slow 40%)
            "Fufil's Diminishing Dirge",     -- Level 60, LDoN (also decrease magic resist 34)
            "Tuyen's Chant of Disease",      -- Level 42, PoP
            "Fufil's Curtailing Chant",      -- Level 30, Base Game
        },
        ['CureSong'] = {
            "Mastery: Aria of Absolution", -- Level 126, SoR
            "Aria of Absolution",          -- Level 96, RoF
            "Aria of Impeccability",       -- Level 91, VoA
            "Aria of Amelioration",        -- Level 86, HoT
            -- "Firiona's Blessed Clarinet",   -- Level 84, SoD (corruption only)
            -- "Kirathas' Cleansing Clarinet", -- Level 79, SoF (corruption only)
            -- "Aria of Innocence",            -- Level 52, LoY (curse only)
            "Aria of Asceticism", -- Level 45, LoY (poison/disease only)
        },
        ['AllianceSong'] = {
            "Covariance of Sticks and Stones",  -- Level 125, ToB
            "Conjunction of Sticks and Stones", -- Level 120, NoS
            "Coalition of Sticks and Stones",   -- Level 115, CoV
            "Covenant of Sticks and Stones",    -- Level 110, TBL
            "Alliance of Sticks and Stones",    -- Level 102, EoK
        },
        ['CharmSong'] = {
            -- Demand line has memblur chance, but costs significantly more mana
            "Voice of Keftlik",           -- Level 129, SoR (up to 128)
            -- "Yaran's Demand",          -- Level 124, ToB (up to 123, 40% memblur)
            "Voice of Suja",              -- Level 124, LS (up to 123)
            -- "Omiyad's Demand",         -- Level 119, NoS (up to 118, 40% memblur)
            "Voice of the Diabo",         -- Level 119, ToL (up to 118)
            -- "Desirae's Demand",        -- Level 114, . CoV (up to 113, 40% memblur)
            "Voice of Zburator",          -- Level 114, ToV (up to 113)
            -- "Dawnbreeze's Demand",     -- Level 109, TBL (up to 108, 40% memblur)
            "Voice of Jembel",            -- Level 109, RoS (up to 108)
            "Voice of Silisia",           -- Level 104, TDS (up to 103)
            -- "Silisia's Demand",        -- Level 102, EoK (up to 103, 40% memblur)
            "Voice of Motlak",            -- Level 99, RoF (up to 98)
            "Voice of Kolain",            -- Level 94, VoA (up to 94)
            "Voice of Sionachie",         -- Level 89, HoT (up to 88)
            "Voice of the Mindshear",     -- Level 84, SoD (up to SoD)
            "Yowl of the Bloodmoon",      -- Level 79, SoF (up to 78)
            "Beckon of the Tuffein",      -- Level 74, TSS (up to 73)
            "Voice of the Vampire",       -- Level 70, OoW (up to 68)
            "Call of the Banshee",        -- Level 64, PoP (up to 57)
            "Solon's Bewitching Bravura", -- Level 39, Base Game (up to 51)
            "Solon's Song of the Sirens", -- Level 27, Base Game (up to 37)
        },
        ['ReflexStrike'] = {
            -- Bard ReflexStrike - Restores mana to group
            "Reflexive Rebuttal",  -- Level 113
            "Reflexive Rejoinder", -- Level 105
            "Reflexive Retort",    -- Level 100
        },
        ['ChordsAE'] = {
            -- ChordsAE only work if target is not moving on Live
            "Selo's Chords of Cessation", -- Level 48, Base Game
            "Chords of Dissonance",       -- Level 2, Base Game
        },
        ['AmpSong'] = {
            "Amplification", -- Level 30, SoL
        },
        ['DispelSong'] = {
            -- Dispel Song - For pulling to avoid Summons
            "Druzzil's Disillusionment",  -- Level 62, PoP (dispel 9)
            -- "Song of Highsun",         -- Level 56, RoK (dispel 9, also ports NPC to spawn point)
            "Syvelian's Anti-Magic Aria", -- Level 40, Base Game (dispel 4)
        },
        ['ResistSong'] = {
            -- Resists Song
            "Psalm of Veeshan VII",    -- Level 128, SoR
            "Psalm of the Nomad",      -- Level 123, LS
            "Psalm of the Pious",      -- Level 118, ToL
            "Psalm of the Restless",   -- Level 113, ToV
            "Second Psalm of Veeshan", -- Level 108, RoS
            "Psalm of the Forsaken",   -- Level 98, CoTF
            "Psalm of Veeshan",        -- Level 63, PoP
            "Psalm of Purity",         -- Level 37, Base Game (poison only)
            "Psalm of Cooling",        -- Level 33, Base Game (fire onyl)
            "Psalm of Vitality",       -- Level 29, Base Game (disease only)
            "Psalm of Warmth",         -- Level 25, Base Game (cold only)
        },
        ['MezSong'] = {
            -- Lullaby line has lower max level and has pushback, but you get them earlier.
            "Slumber of Keftlik",       -- Level 129, SoR (up to 133)
            -- "Lullaby of the Sundered",  -- Level 126, SoR (up to 130)
            "Slumber of Suja",          -- Level 124, LS (up to 128,)
            -- "Lullaby of the Forgotten", -- Level 121, LS (up to 125)
            "Slumber of the Diabo",     -- Level 119, ToL (up to 123)
            -- "Lullaby of Nightfall",     -- Level 116, ToL (up to 120)
            "Slumber of Zburator",      -- Level 114, ToV (up to 118)
            -- "Lullaby of Zburator",      -- Level 111, ToV (up to 115)
            "Slumber of Jembel",        -- Level 109, RoS (up to 113)
            -- "Lullaby of Jembel",        -- Level 106, RoS (up to 110)
            "Slumber of Silisia",       -- Level 104, TDS (up to 108)
            -- "Lullaby of Silisia",       -- Level 101, TDS (up to 105)
            "Slumber of Motlak",        -- Level 99, RoF (up to 103)
            -- "Lullaby of the Forsaken",  -- Level 96, RoF (up to 100)
            "Slumber of Kolain",        -- Level 94, VoA (up to 98)
            -- "Lullaby of the Forlorn",   -- Level 91, VoA (up to 95)
            "Slumber of Sionachie",     -- Level 89, HoT (up to 93)
            -- "Lullaby of the Lost",      -- Level 86, HoT (up to 90)
            "Slumber of the Mindshear", -- Level 84, SoD (up to 88)
            -- "Serenity of Oceangreen",   -- Level 81, SoD (up to 85)
            "Command of Queen Veneneu", -- Level 79, SoF (up to 83)
            -- "Amber's Last Lullaby",     -- Level 76, SoF (up to 80)
            "Queen Eletyl's Screech",   -- Level 74, TSS (up to 79)
            -- "Aelfric's Last Lullaby",   -- Level 71, TSS (up to 75)
            "Vulka's Lullaby",          -- Level 70, OoW (up to 73)
            "Creeping Dreams",          -- Level 68, DoD (up to 73)
            "Luvwen's Lullaby",         -- Level 67, OoW (up to 70)
            "Lullaby of Morell",        -- Level 65, PoP (up to 68)
            "Dreams of Terris",         -- Level 64, PoP (up to 65)
            "Dreams of Thule",          -- Level 62, PoP (up to 62)
            "Dreams of Ayonae",         -- Level 58, SoL (up to 57)
            "Song of Twilight",         -- Level 53, RoK (up to 55)
            "Sionachie's Dreams",       -- Level 40, SoL (up to 53)
            "Crission's Pixie Strike",  -- Level 28, Base Game (up to 45)
            "Kelin's Lucid Lullaby",    -- Level 15, Base Game (up to 30)
        },
        ['MezAESong'] = {
            -- MezAESong - Level Range 85 - 115 **
            "Wave of Slumber X",     -- Level 130, SoR (up to 133)
            "Wave of Stupor",        -- Level 125, LS (up to 128)
            "Wave of Nocturn",       -- Level 120, ToL (up to 123)
            "Wave of Sleep",         -- Level 115, ToV (up to 118)
            "Wave of Somnolence",    -- Level 110, RoS (up to 113)
            "Wave of Torpor",        -- Level 105, TDS (up to 108)
            "Wave of Quietude",      -- Level 100, RoF (up to 103)
            "Wave of the Conductor", -- Level 95, VoA (up to 98)
            "Wave of Dreams",        -- Level 90, HoT (up to 93)
            "Wave of Slumber",       -- Level 85, . UF (up to 88)
        },
        ['Jonthan'] = {
            "Jonthan's Mightful Caretaker", -- Level 71, . TBS
            "Jonthan's Inspiration",        -- Level 58, RoK
            "Jonthan's Provocation",        -- Level 45, Base Game
            "Jonthan's Whistling Warsong",  -- Level 7, Base Game
        },
        ['CalmSong'] = {
            -- CalmSong - Level Range 8+ --Included for manual use with /rgl usemap
            "Silence of the Vortex",     -- Level 126, SoR (up to 130)
            "Silence of the Forgotten",  -- Level 121, LS (up to 125)
            "Silence of Quietus",        -- Level 116, TOL (up to 120)
            "Silence of Zburator",       -- Level 111, ToV (up to 115)
            "Silence of Jembel",         -- Level 106, RoS (up to 110)
            "Silence of Silisia",        -- Level 101, TDS (up to 105)
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
            "Thousand Blades", -- Level 69
        },
        ['ResistDebuff'] = {
            "Harmony of Sound",   -- Level 65
            "Occlusion of Sound", -- Level 55
        },
    },
    ['Helpers']           = {
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
        CheckSongStateUse = function(self, config) --determine whether a song should be sung by comparing combat state to settings
            local usestate = Config:GetSetting(config)
            local inCombat = Globals.CurrentState == "Combat"
            if usestate == 1 then return false end        -- Never
            if usestate == 3 then return true end         -- Always
            if usestate == 2 then return inCombat end     -- In-Combat Only
            if usestate == 4 then return not inCombat end -- Out-of-Combat Only
            return false
        end,
        GetSongBuffer = function() --seconds of remaining duration at which a buff song is resung
            return Config:GetSetting('SongRefresh')
        end,
        RefreshBuffSong = function(self, songSpell) --true once a buff song's remaining duration drops to the resing buffer (a dropped song reads 0 and resings)
            if not songSpell or not songSpell() then return false end
            local me = mq.TLO.Me
            local remaining = songSpell.DurationWindow() == 1
                and (me.Song(songSpell.Name()).Duration.TotalSeconds() or 0)
                or (me.Buff(songSpell.Name()).Duration.TotalSeconds() or 0)
            if self.TempSettings.upkeepFill then return remaining > 0 end
            return remaining <= self.Helpers.GetSongBuffer()
        end,
        MarchTimer = function(self) --minimum gap between War March resings
            local interval = (self.TempSettings.MarchDuration or 12) - self.Helpers.GetSongBuffer()
            return (Globals.GetTimeSeconds() - (self.TempSettings.LastMarchCast or 0)) >= interval
        end,
        RefreshExpiringSong = function(self) --idle upkeep: resing the active song closest to expiring
            local melody = self.TempSettings.RotationTable['Melody']
            if not melody then return false end
            local me = mq.TLO.Me
            local pick, pickRemaining, pickEntry = nil, nil, nil
            self.TempSettings.upkeepFill = true
            for _, entry in ipairs(melody) do
                local songSpell = Core.GetResolvedActionMapItem(entry.name)
                if songSpell and songSpell() and entry.cond and Core.SafeCallFunc("upkeep want", entry.cond, self, songSpell, me) then
                    local remaining = songSpell.DurationWindow() == 1
                        and (me.Song(songSpell.Name()).Duration.TotalSeconds() or 0)
                        or (me.Buff(songSpell.Name()).Duration.TotalSeconds() or 0)
                    if remaining > 0 and Casting.SongReady(songSpell) and (not pickRemaining or remaining < pickRemaining) then
                        pick, pickRemaining, pickEntry = songSpell, remaining, entry
                    end
                end
            end
            self.TempSettings.upkeepFill = false
            if not pick then return false end
            if pick.Name() == self.TempSettings.LastUpkeepSong and math.abs(pickRemaining - (self.TempSettings.LastUpkeepRemaining or 0)) < 1 then
                return false
            end
            if Casting.UseSong(pick.RankName(), me.ID(), false) then
                self.TempSettings.LastUpkeepSong = pick.Name()
                self.TempSettings.LastUpkeepRemaining = pickRemaining
                if pickEntry and pickEntry.post_activate then
                    Core.SafeCallFunc("upkeep post_activate", pickEntry.post_activate, self, pick, true)
                end
                return true
            end
            return false
        end,
        UnwantedAggroCheck = function(self)
            if Targeting.GetXTHaterCount() == 0 or Core.IsTanking() or mq.TLO.Group.Puller.ID() == mq.TLO.Me.ID() then return false end
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
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
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
                { name = "ResistDebuff",  cond = function(self) return Config:GetSetting('DoResistDebuff') end, },
                { name = "CureSong",      cond = function(self) return Config:GetSetting('UseCure') end, },
                { name = "RunBuffSong",   cond = function(self) return Config:GetSetting('UseRunBuff') > 1 and not Casting.CanUseAA("Selo's Sonata") end, },
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
                    name = "SpellDmgSong",
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
    ['Mez']               = {
        { type = "AA",   name = "Dirge of the Sleepwalker", cond = function() return Config:GetSetting('DoAAMez') end, },
        { type = "Song", name = "MezSong", },
        { type = "Song", name = "MezAESong", },
    },
    ['Charm']             = {
        ['Abilities'] = {
            { name = "CharmSong", type = "Song", },
        },
    },
    ['RotationOrder']     = {
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
            name = 'Downtime',
            state = 1,
            steps = 1,
            midSong = true,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and not mq.TLO.Me.Invis()
            end,
        },
        {
            name = 'Emergency',
            state = 1,
            steps = 1,
            midSong = true,
            doFullRotation = true,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or self.Helpers.UnwantedAggroCheck(self))
            end,
        },
        {
            name = 'Debuff',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting("DoSTSlow") or Config:GetSetting("DoAESlow") or Config:GetSetting("DoResistDebuff") or Config:GetSetting("DoDispel") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Melody',
            state = 1,
            steps = 1,
            timer = 0,
            doFullRotation = true,
            blockMem = true,
            targetId = function(self)
                local autoTarget = Targeting.CheckForAutoTargetID()
                if #autoTarget > 0 then return autoTarget end
                return { mq.TLO.Me.ID(), }
            end,
            cond = function(self, combat_state)
                if Globals.InMedState then return false end
                if combat_state == "Downtime" and mq.TLO.Me.Invis() then return false end
                return Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            midSong = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Combat',
            state = 1,
            steps = 1,
            midSong = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'InstantRunBuff',
            state = 1,
            steps = 1,
            midSong = true,
            timer = function(self) return Combat.GetCachedCombatState() == "Combat" and 15 or 1 end,
            targetId = function(self)
                local autoTarget = Targeting.CheckForAutoTargetID()
                if #autoTarget > 0 then return autoTarget end
                if Combat.GetCachedCombatState() == "Combat" then return { mq.TLO.Me.ID(), } end
                return Casting.GetBuffableGroupIDs()
            end,
            load_cond = function(self) return Casting.CanUseAA("Selo's Sonata") end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and not mq.TLO.Me.Invis()
                local combat = combat_state == "Combat"
                return downtime or combat
            end,
        },
    },
    ['Rotations']         = {
        ['Burn'] = {
            {
                name = "Quick Time",
                type = "AA",
                midSong = true,
            },
            {
                name = "Funeral Dirge",
                type = "AA",
                midSong = true,
            },
            {
                name = "Spire of the Minstrels",
                type = "AA",
                midSong = true,
            },
            {
                name = "Bladed Song",
                type = "AA",
                midSong = true,
            },
            {
                name = "ThousandBlades",
                type = "Disc",
                midSong = true,
            },
            {
                name = "Song of Stone",
                type = "AA",
                midSong = true,
            },
            {
                name = "Flurry of Notes",
                type = "AA",
                midSong = true,
            },
            {
                name = "Dance of Blades",
                type = "AA",
                midSong = true,
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
                midSong = true,
            },
            {
                name = "Frenzied Kicks",
                type = "AA",
                midSong = true,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                midSong = true,
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Debuff'] = {
            {
                name = "AESlowSong",
                type = "Song",
                load_cond = function() return Config:GetSetting('DoAESlow') end,
                cond = function(self, songSpell, target)
                    return Casting.DetSpellCheck(songSpell) and Targeting.GetXTHaterCount() > 2 and not mq.TLO.Target.Slowed() and
                        not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSong",
                type = "Song",
                load_cond = function() return Config:GetSetting('DoSTSlow') end,
                cond = function(self, songSpell, target)
                    return Casting.DetSpellCheck(songSpell) and not mq.TLO.Target.Slowed() and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "ResistDebuff",
                type = "Song",
                load_cond = function() return Config:GetSetting('DoResistDebuff') end,
                cond = function(self, songSpell)
                    return Casting.DetSpellCheck(songSpell)
                end,
            },
            {
                name = "DispelSong",
                type = "Song",
                load_cond = function() return Config:GetSetting('DoDispel') end,
                cond = function(self, songSpell)
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['Combat'] = {
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
                midSong = true,
                load_cond = function(self) return Config:GetSetting('UseFierceEye') > 1 end,
                cond = function(self, aaName)
                    return (Config:GetSetting('UseFierceEye') == 3 or (Config:GetSetting('UseFierceEye') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "ReflexStrike",
                type = "Disc",
                midSong = true,
                tooltip = Tooltips.ReflexStrike,
                cond = function(self, discSpell)
                    local pct = Config:GetSetting('GroupManaPct')
                    return (mq.TLO.Group.LowMana(pct)() or -1) >= Config:GetSetting('GroupManaCt')
                end,
            },
            {
                name = "Boastful Bellow",
                type = "AA",
                midSong = true,
                load_cond = function(self) return Config:GetSetting('UseBellow') > 1 end,
                cond = function(self, aaName, target)
                    return ((Config:GetSetting('UseBellow') == 3 and mq.TLO.Me.PctEndurance() > Config:GetSetting('SelfEndPct')) or (Config:GetSetting('UseBellow') == 2 and Casting.BurnCheck())) and
                        Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Vainglorious Shout",
                type = "AA",
                midSong = true,
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
                midSong = true,
                load_cond = function(self) return Casting.CanUseAA('Rallying Solo') end,
                cond = function(self, aaName)
                    return (mq.TLO.Me.PctEndurance() < 30 or mq.TLO.Me.PctMana() < 30)
                end,
            },
            {
                name = "Intimidation",
                type = "Ability",
                midSong = true,
                load_cond = function(self) return Casting.AARank("Intimidation") > 1 end,
            },
        },
        ['Enduring Breath'] = {
            {
                name = "EndBreathSong",
                type = "Song",
                cond = function(self, songSpell)
                    return self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
        },
        ['Melody'] = {
            {
                name = "AriaSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "OverhasteSong",
                type = "Song",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('LLAria') == 2 and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "SpellDmgSong",
                type = "Song",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('AriaSong') and Config:GetSetting('LLAria') == 3 and Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "WarMarchSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('WarMarchSong') and Config:GetSetting('UseMarch') > 1 end,
                cond = function(self, songSpell)
                    if not self.Helpers.CheckSongStateUse(self, "UseMarch") then return false end
                    return self.Helpers.MarchTimer(self) and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
                post_activate = function(self, songSpell, success)
                    if success then self.TempSettings.LastMarchCast = Globals.GetTimeSeconds() end
                end,
            },
            {
                name = "RunBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('RunBuffSong') and Config:GetSetting('UseRunBuff') > 1 and not Casting.CanUseAA("Selo's Sonata") end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseRunBuff") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "Jonthan",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('Jonthan') and Config:GetSetting('UseJonthan') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseJonthan") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "ArcaneSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('ArcaneSong') and Config:GetSetting('UseArcane') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseArcane") and self.Helpers.RefreshBuffSong(self, songSpell)
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
                    return self.Helpers.RefreshBuffSong(self, songSpell) and
                        ((Config:GetSetting('UseRegen') == 1 and (mq.TLO.Group.LowMana(pct)() or 999) >= Config:GetSetting('GroupManaCt'))
                            or (Config:GetSetting('UseRegen') > 1 and self.Helpers.CheckSongStateUse(self, "UseRegen")))
                end,
            },
            {
                name = "AreaRegenSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AreaRegenSong') and Config:GetSetting('RegenSong') == 3 end,
                cond = function(self, songSpell)
                    local pct = Config:GetSetting('GroupManaPct')
                    return self.Helpers.RefreshBuffSong(self, songSpell) and
                        ((Config:GetSetting('UseRegen') == 1 and (mq.TLO.Group.LowMana(pct)() or 999) >= Config:GetSetting('GroupManaCt'))
                            or (Config:GetSetting('UseRegen') > 1 and self.Helpers.CheckSongStateUse(self, "UseRegen")))
                end,
            },
            {
                name = "AmpSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AmpSong') and Config:GetSetting('UseAmp') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAmp") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "SufferingSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('SufferingSong') and Config:GetSetting('UseSuffering') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseSuffering") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "SpitefulSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('SpitefulSong') and Config:GetSetting('UseSpiteful') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseSpiteful") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "SprySonataSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('SprySonataSong') and Config:GetSetting('UseSpry') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseSpry") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "ResistSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('ResistSong') and Config:GetSetting('UseResist') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseResist") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "RecklessSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('RecklessSong') and Config:GetSetting('UseReckless') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseReckless") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "AccelerandoSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('AccelerandoSong') and Config:GetSetting('UseAccelerando') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAccelerando") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "FireBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('FireBuffSong') and Config:GetSetting('UseFireBuff') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseFireBuff") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "ColdBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('ColdBuffSong') and Config:GetSetting('UseColdBuff') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseColdBuff") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "DotBuffSong",
                type = "Song",
                load_cond = function(self) return Core.GetResolvedActionMapItem('DotBuffSong') and Config:GetSetting('UseDotBuff') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseDotBuff") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "DichoSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseDicho') > 1 end,
                cond = function(self, songSpell, target)
                    if target.ID() == mq.TLO.Me.ID() then return false end
                    local qt = Casting.GetAASpell("Quick Time")
                    return (Config:GetSetting('UseDicho') == 3 and (mq.TLO.Me.PctEndurance() > Config:GetSetting('SelfEndPct') or Casting.BurnCheck()))
                        or (Config:GetSetting('UseDicho') == 2 and qt and qt() and mq.TLO.Me.Song(qt.Name())())
                end,
            },
            {
                name = "InsultSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseInsult') > 1 and (not Config:GetSetting('UseLLInsult') or not Core.GetResolvedActionMapItem('LLInsultSong')) end,
                cond = function(self, songSpell, target)
                    if target.ID() == mq.TLO.Me.ID() then return false end
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "LLInsultSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseInsult') > 1 and Config:GetSetting('UseLLInsult') and Core.GetResolvedActionMapItem('LLInsultSong') end,
                cond = function(self, songSpell, target)
                    if target.ID() == mq.TLO.Me.ID() then return false end
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "FireDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseFireDots') end,
                cond = function(self, songSpell, target)
                    return target.ID() ~= mq.TLO.Me.ID() and self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('SongRefresh')
                end,
            },
            {
                name = "IceDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseIceDots') end,
                cond = function(self, songSpell, target)
                    return target.ID() ~= mq.TLO.Me.ID() and self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('SongRefresh')
                end,
            },
            {
                name = "PoisonDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UsePoisonDots') end,
                cond = function(self, songSpell, target)
                    return target.ID() ~= mq.TLO.Me.ID() and self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('SongRefresh')
                end,
            },
            {
                name = "DiseaseDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseDiseaseDots') end,
                cond = function(self, songSpell, target)
                    return target.ID() ~= mq.TLO.Me.ID() and self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('SongRefresh')
                end,
            },
            {
                name = "InsultSong2",
                type = "Song",
                load_cond = function(self)
                    return Config:GetSetting('UseInsult') == 3 and (not Config:GetSetting('UseLLInsult') or not Core.GetResolvedActionMapItem('LLInsultSong'))
                end,
                cond = function(self, songSpell, target)
                    if target.ID() == mq.TLO.Me.ID() then return false end
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "LLInsultSong2",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseInsult') == 3 and Config:GetSetting('UseLLInsult') and Core.GetResolvedActionMapItem('LLInsultSong') end,
                cond = function(self, songSpell, target)
                    if target.ID() == mq.TLO.Me.ID() then return false end
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck())
                end,
            },
            {
                name = "AllianceSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseAlliance') end,
                cond = function(self, songSpell, target)
                    if target.ID() == mq.TLO.Me.ID() then return false end
                    return (mq.TLO.Me.PctMana() > Config:GetSetting('SelfManaPct') or Casting.BurnCheck()) and Casting.DetSpellCheck(songSpell)
                end,
            },
            {
                name = "Refresh Expiring Song",
                type = "customfunc",
                custom_func = function(self) return self.Helpers.RefreshExpiringSong(self) end,
            },
        },
        ['Downtime'] = {
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
                midSong = true,
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 35
                end,
            },
            {
                name = "Fading Memories",
                type = "AA",
                midSong = true,
                load_cond = function(self) return Config:GetSetting('UseFading') and Casting.CanUseAA('Fading Memories') end,
                cond = function(self, aaName)
                    if Config:GetSetting('CharmOn') and mq.TLO.Me.Pet.ID() > 0 then return false end
                    return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or Globals.AutoTargetIsNamed) and self.Helpers.UnwantedAggroCheck(self)
                end,
            },
            {
                name = "Hymn of the Last Stand",
                type = "AA",
                midSong = true,
                load_cond = function(self) return Casting.CanUseAA('Hymn of the Last Stand') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Shield of Notes",
                type = "AA",
                midSong = true,
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
        ['InstantRunBuff'] = {
            {
                name = "Selo's Sonata",
                type = "AA",
                midSong = true,
                cond = function(self, aaName, target)
                    local combatState = Combat.GetCachedCombatState()
                    -- use at rotation timer interval in combat, check for need outside
                    return combatState == "Combat" or (combatState == "Downtime" and Casting.GroupBuffAACheck(aaName, target))
                end,
            },
        },
    },
    ['PullAbilities']     = {
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
    ['PullMoveAbilities'] = {
        {
            name = "Selo's Sonata",
            type = "AA",
            load_cond = function(self) return Casting.CanUseAA("Selo's Sonata") end,
            cond = function(self, aaName)
                local aaBuff = mq.TLO.Me.AltAbility(aaName).Spell.Trigger(1)() or ""
                return (mq.TLO.Me.Buff(aaBuff).Duration.TotalSeconds() or 0) < 15
            end,
        },
        {
            name = "RunBuffSong",
            type = "Song",
            load_cond = function(self) return Core.GetResolvedActionMapItem('RunBuffSong') and Config:GetSetting('UseRunBuff') > 1 and not Casting.CanUseAA("Selo's Sonata") end,
            cond = function(self, songSpell)
                if not mq.TLO.Me.Gem(songSpell.RankName())() then return false end
                if (mq.TLO.Me.Casting.ID() or 0) == songSpell.ID() then return false end
                local buffName = songSpell.BaseName()
                local spellBuff = songSpell.DurationWindow() == 1 and mq.TLO.Me.Song(buffName) or mq.TLO.Me.Buff(buffName)
                return not spellBuff()
            end,
        },
    },
    ['DefaultConfig']     = {
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
        ['DoResistDebuff']  = {
            DisplayName = "Use Resist Debuff",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use the Occlusion/Harmony of Sound Resist Debuff.",
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
        ['SongRefresh']     = {
            DisplayName = "Song Refresh Timer",
            Group = "Abilities",
            Header = "Common",
            Category = "Under the Hood",
            Index = 101,
            Tooltip = "Resing a song or effect once its remaining duration is at or below this many seconds.",
            Default = 4,
            Min = 1,
            Max = 13,
            ConfigType = "Advanced",
            FAQ = "Why does my bard refresh songs before the Song Refresh Timer?",
            Answer = "Rather than stand idle, the bard keeps singing, topping off whichever song in the Melody rotation is closest to expiring, " ..
                "so songs refresh before reaching the Song Refresh Timer and uptime stays high.",
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
            Tooltip = "Song Line: Movement Speed Modifier (Does not control the Selo's AA).",
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
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
            RequiresLoadoutChange = true,
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
    ['ClassFAQ']          = {
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
