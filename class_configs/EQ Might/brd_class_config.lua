local mq           = require('mq')
local Casting      = require("utils.casting")
local Combat       = require('utils.combat')
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require('utils.globals')
local ItemManager  = require('utils.item_manager')
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")

local Tooltips     = {
    Epic           = 'Item: Casts Epic Weapon Ability',
    AriaSong       = "Song Line: Spell Damage Focus / Haste v3 Modifier",
    WarMarchSong   = "Song Line: Melee Haste / DS / STR/ATK Increase",
    ArcaneSong     = "Song Line: Group Melee and Spell Proc",
    DPSAura        = "Aura Line: OverHaste / Melee and Caster DPS",
    AreaRegenSong  = "Song Line: AE HP/Mana Regen",
    GroupRegenSong = "Song Line: Group HP/Mana Regen",
    SlowSong       = "Song Line: ST Melee Attack Slow",
    AESlowSong     = "Song Line: PBAE Melee Attack Slow",
    FireDotSong    = "Song Line: Fire DoT and minor resist debuff",
    DiseaseDotSong = "Song Line: Disease DoT and minor resist debuff",
    PoisonDotSong  = "Song Line: Poison DoT and minor resist debuff",
    IceDotSong     = "Song Line: Ice DoT and minor resist debuff",
    EndBreathSong  = "Song Line: Enduring Breath",
    CureSong       = "Song Line: Single Target Cure: Poison/Disease",
    CharmSong      = "Song Line: Charm Mob",
    LowAriaSong    = "Song Line: Warsong and BattleCry prior to combination of effects into Aria",
    AmpSong        = "Song Line: Increase Singing Skill",
    DispelSong     = "Song Line: Dispel a Benefical Effect",
    ResistSong     = "Song Line: Damage Shield / Group Resist Increase",
    MitigationSong = "Song Line: Group Melee/Spell Damage Mitigation",
    MezSong        = "Song Line: Single Target Mez",
    MezAESong      = "Song Line: PBAE Mez",
    Bellow         = "AA: DD + Resist Debuff that leads to a much larger DD upon expiry",
    FuneralDirge   = "AA: DD / Increases Melee Damage Taken on Target",
    FierceEye      = "AA: Increases Base and Crit Melee Damage / Increase Proc Rate / Increase Spell Crit Chance",
    QuickTime      = "AA: Hundred Hands Effect / Increase Melee Hit / Increase Atk",
    Jonthan        = "Song Line: (Self-only) Haste / Melee Damage Modifier / Melee Min Damage Modifier / Proc Modifier",
}

local _ClassConfig = {
    _version              = "3.4 - EQ Might",
    _author               = "Algar, Derple, Grimmier, Tiddliestix, SonicZentropy",
    ['Modes']             = { --other modes to reorder spell priorities may be added back in at a later date.
        'General',
    },
    ['ModeChecks']        = {
        CanMez    = function() return true end,
        CanCharm  = function() return true end,
        IsMezzing = function() return Config:GetSetting('MezOn') end,
        IsCuring  = function() return Config:GetSetting('UseCure') end,
        IsRezing  = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Rez']               = {
        ['Combat']   = {
            { type = "Item", name = "RezStaff", },
        },
        ['Downtime'] = {
            { type = "Item", name = "RezStaff", },
        },
    },
    ['Cure']              = {
        ['Poison'] = {
            { type = "Song", name = "CureSong", },
        },
        ['Disease'] = {
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
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Blade of Vesagran",
            "Prismatic Dragon Blade",
        },
        ['OoW_Chest'] = {
            "Farseekers's Plate Chestguard of Harmony",
            "Traveler's Mail Chestguard",
        },
    },
    ['AbilitySets']       = {
        -- TO DO: Added Dirgle of Metala/Snare line
        -- bellow of chaos 66 dd nuke??
        ['RunBuff'] = {
            "Selo's Accelerating Chorus", -- Level 49
            "Selo's Accelerando",         -- Level 5
        },
        ['EndBreathSong'] = {
            "Tarew's Aquatic Ayre",      -- Level 16
        },
        ['AreaAriaSong'] = {             -- AoE, standard Aria
            "Aria of the Harmoniarch",   -- Level 70 EQM Custom
            "Ancient: Call of Power",    -- Level 70
            "Yelhun's Mystic Call",      -- Level 68
            "Echo of the Trusik",        -- Level 65 overhaste/spell damage
            "Warsong of the Vah Shir",   -- Level 60 overhaste only
            "Battlecry of the Vah Shir", -- Level 52 overhaste only
            "Rizlona's Embers",          -- Level 45 spell damage only
        },
        ['GroupAriaSong'] = {            -- Group only, also affects procs
            "Eriki's Psalm of Power",    -- Level 69
            "Call of the Muse",          -- Level 65
            "Rizlona's Call of Flame",   -- Level 64 overhaste/spell damage
            "Rizlona's Fire",            -- Level 53 spell damage only
        },
        ['ArcaneSong'] = {
            "Arcane Aria", -- Level 70
        },
        ['DPSAura'] = {
            "Aura of the Muse", -- Level 66
            "Aura of Insight",  -- Level 55
        },
        ['GroupRegenSong'] = {
            "Erollisi's Cantata",            -- Level 70
            "Cantata of Life",               -- Level 67
            "Wind of Marr",                  -- Level 62
            "Cantata of Replenishment",      -- Level 55
            "Cantata of Soothing",           -- Level 34 start hp/mana. Slightly less mana. They can custom if it they want the 2 mana/tick
            "Cassindra's Chorus of Clarity", -- Level 32 mana only
            "Cassindra's Chant of Clarity",  -- Level 20 mana only
            "Hymn of Restoration",           -- Level 6 hp only
        },
        ['AreaRegenSong'] = {
            "Erollisi's Chorus",       -- Level 71
            "Chorus of Life",          -- Level 69
            "Chorus of Marr",          -- Level 64
            "Ancient: Lcea's Lament",  -- Level 60
            "Chorus of Replenishment", -- Level 58
        },
        ['WarMarchSong'] = {
            "War March of Muram",            -- Level 68
            "War March of the Mastruq",      -- Level 65
            "Warsong of Zek",                -- Level 62
            "McVaxius' Rousing Rondo",       -- Level 57
            "Vilia's Chorus of Celerity",    -- Level 54
            "Verses of Victory",             -- Level 50
            "McVaxius' Berserker Crescendo", -- Level 42
            "Vilia's Verses of Celerity",    -- Level 36
            "Anthem de Arms",                -- Level 10
            "Chant of Battle",               -- Level 1
        },
        ['SlowSong'] = {
            "Requiem of Time",          -- Level 64
            "Angstlich's Assonance",    -- Level 60 snare/slow
            "Largo's Assonant Binding", -- Level 51 snare/slow
            "Selo's Consonant Chain",   -- Level 23 snare/slow
        },
        ['AESlowSong'] = {
            "Zuriki's Song of Shenanigans", -- Level 67
            "Largo's Melodic Binding",      -- Level 20
        },
        ['FireDotSong'] = {
            "Vulka's Chant of Flame", -- Level 70
            "Tuyen's Chant of Fire",  -- Level 65
            "Tuyen's Chant of Flame", -- Level 38
        },
        ['IceDotSong'] = {
            "Vulka's Chant of Frost", -- Level 67
            "Tuyen's Chant of Ice",   -- Level 63
            "Tuyen's Chant of Frost", -- Level 46
        },
        ['PoisonDotSong'] = {
            "Vulka's Chant of Poison", -- Level 68
            "Tuyen's Chant of Venom",  -- Level 63
            "Tuyen's Chant of Poison", -- Level 50
        },
        ['DiseaseDotSong'] = {
            "Vulka's Chant of Disease",    -- Level 66
            "Tuyen's Chant of the Plague", -- Level 61
            "Tuyen's Chant of Disease",    -- Level 42
        },
        ['CureSong'] = {
            -- "Aria of Innocence", -- Level 52 curse only, and only 2 x 2 counters
            "Aria of Asceticism", -- Level 45 poison/disease Only
        },
        ['CharmSong'] = {
            "Voice of the Vampire",       -- Level 70
            "Call of the Banshee",        -- Level 64
            "Solon's Bewitching Bravura", -- Level 39
            "Solon's Song of the Sirens", -- Level 27
        },
        -- ['ChordsAE'] = {
        --     "Chords of Dissonance", -- Level 2
        -- },

        ['AmpSong'] = {
            "Amplification", -- Level 30
        },
        ['DispelSong'] = {
            -- Dispel Song - For pulling to avoid Summons
            "Druzzil's Disillusionment",  -- Level 62
            "Syvelian's Anti-Magic Aria", -- Level 40
        },
        ['ResistSong'] = {
            "Psalm of Veeshan", -- Level 63
            "Elemental Chorus", -- Level 54
        },
        ['MezSong'] = {
            "Aelfric's Last Lullaby",     -- Level 70
            "Vulka's Lullaby",            -- Level 70
            "Creeping Dreams",            -- Level 68
            "Luvwen's Lullaby",           -- Level 67
            "Lullaby of Morell",          -- Level 65
            "Dreams of Terris",           -- Level 64
            "Dreams of Thule",            -- Level 62
            "Ancient: Lullaby of Shadow", -- Level 60
            "Dreams of Ayonae",           -- Level 58
            "Song of Twilight",           -- Level 53
            "Sionachie's Dreams",         -- Level 40
            "Crission's Pixie Strike",    -- Level 28
            "Kelin's Lucid Lullaby",      -- Level 15
        },
        ['MezAESong'] = {
            "Wave of Morell", -- Level 66 EQM Custom
        },
        ['Jonthan'] = {
            "Jonthan's Mightful Caretaker", -- Level 70
            "Jonthan's Mightful Watcher",   -- Level 64 EQM Custom
            "Jonthan's Inspiration",        -- Level 58
            "Jonthan's Provocation",        -- Level 45
            "Jonthan's Whistling Warsong",  -- Level 7
        },
        ['CalmSong'] = {
            -- CalmSong - Level Range 8+ --Included for manual use with /rgl usemap
            "Whispersong of Veshma",     -- Level 70
            "Luvwen's Aria of Serenity", -- Level 66
            "Silent Song of Quellious",  -- Level 61
            "Kelin's Lugubrious Lament", -- Level 8 (Max Mob Level of 60)
        },
        ['ThousandBlades'] = {
            "Thousand Blades", -- Level 69
        },
        ['Steelwrath'] = {
            "Steelwrath Discipline", -- Level 67 EQM Custom
        },
        ['ProcSong'] = {
            "Storm Blade",       -- Level 69
            "Song of the Storm", -- Level 61
        },
        ['ResistDebuff'] = {
            "Harmony of Sound",   -- Level 65
            "Occlusion of Sound", -- Level 55
        },
        ['MitigationSong'] = {
            "Song of the Dryads", -- Level 71
            "Verse of Vesagran",  -- Level 69
            "Verse of Huell",     -- Level 65 EQM Custom
        },
        ['Protective'] = {
            "Protective Surge Discipline", -- Level 55 EQM Custom
        },
        ['Skals'] = {
            "Skal's Stance Discipline", -- Level 61 EQM Custom
        },
        ['Revitalize'] = {
            "Iron Revitalize",     -- Level 68 EQM Custom
            "Hardened Revitalize", -- Level 62 EQM Custom
            "Revitalize",          -- Level 51 EQM Custom
        },
    },
    ['AASets']            = {
        ['Spire'] = {
            "Fundament: Second Spire of the Minstrels",
            "Fundament: First Spire of the Minstrels",
        },
    },
    ['Helpers']           = {
        SwapInst = function(type)
            if not Config:GetSetting('SwapInstruments') then return end
            Logger.log_verbose("\ayBard SwapInst(): Swapping to Instrument Type: %s", type)
            if type == "Percussion Instruments" then
                if mq.TLO.Me.Bandolier('drum')() and Config:GetSetting('UseBandolier') then
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atDrum Bandolier")
                    ItemManager.BandolierSwap('drum')
                    return
                else
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atPercussion Instrument")
                    ItemManager.SwapItemToSlot("offhand", Config:GetSetting('PercInst'))
                    return
                end
            elseif type == "Wind Instruments" then
                if mq.TLO.Me.Bandolier('wind')() and Config:GetSetting('UseBandolier') then
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atWind Bandolier")
                    ItemManager.BandolierSwap('wind')
                    return
                else
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atWind Instrument")
                    ItemManager.SwapItemToSlot("offhand", Config:GetSetting('WindInst'))
                    return
                end
            elseif type == "Brass Instruments" then
                if mq.TLO.Me.Bandolier('brass')() and Config:GetSetting('UseBandolier') then
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atBrass Bandolier")
                    ItemManager.BandolierSwap('brass')
                    return
                else
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atBrass Instrument")
                    ItemManager.SwapItemToSlot("offhand", Config:GetSetting('BrassInst'))
                    return
                end
            elseif type == "Stringed Instruments" then
                if mq.TLO.Me.Bandolier('string')() and Config:GetSetting('UseBandolier') then
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atStringed Bandolier")
                    ItemManager.BandolierSwap('string')
                else
                    Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atStringed Instrument")
                    ItemManager.SwapItemToSlot("offhand", Config:GetSetting('StringedInst'))
                end
                return
            end
            if mq.TLO.Me.Bandolier('main')() and Config:GetSetting('UseBandolier') then
                ItemManager.BandolierSwap('main')
                Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atMain Bandolier")
            else
                Logger.log_debug("\ayBard SwapInst()\ax:\ao Swapping to \atOffhand Weapon")
                ItemManager.SwapItemToSlot("offhand", Config:GetSetting('Offhand'))
            end
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
        AriaClickyChoice = function()
            if not Config:GetSetting('UseAriaClickies') or Config:GetSetting('AriaChoice') == 1 then return "None" end
            if mq.TLO.FindItem("=Ancient Artifact of Power")() and mq.TLO.Me.Level() >= 68 then
                return "AncientArtifact"
            elseif mq.TLO.FindItem("=Echo of Trusik Lute")() and mq.TLO.Me.Level() >= 65 then
                return "EchoLute"
            end
            return "None"
        end,
        AriaClickyRefresh = function(self, itemName)
            local clickySpell = Casting.GetClickySpell(itemName)
            if not (clickySpell and clickySpell()) then return false end
            return (mq.TLO.Me.Song(clickySpell.Name()).Duration.TotalSeconds() or 0) < 10
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
        MarchTimer = function(self) --minimum gap between War March resings, from the Song Duration setting
            local interval = Config:GetSetting('SongDuration') - self.Helpers.GetSongBuffer()
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
    ['Mez']               = {
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
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
            midSong = true,
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
                return Casting.GetBuffableIDs()
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
        ['Burn'] = { --Order is heavy WIP
            {
                name = "Quick Time",
                type = "AA",
                midSong = true,
            },
            {
                name = "Fierce Eye",
                type = "AA",
                midSong = true,
            },
            {
                name = "Funeral Dirge",
                type = "AA",
                midSong = true,
            },
            {
                name = "Spire",
                type = "AA",
                midSong = true,
            },
            {
                name = "Bladed Song",
                type = "AA",
                midSong = true,
            },
            {
                name = "Song of Stone",
                type = "AA",
                midSong = true,
            },
            {
                name = "ThousandBlades",
                type = "Disc",
                midSong = true,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Steelwrath",
                type = "Disc",
                midSong = true,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
                midSong = true,
            },
            {
                name = "Dance of Blades",
                type = "AA",
                midSong = true,
            },
            {
                name = "Cacophony",
                type = "AA",
                midSong = true,
            },
            {
                name = "A Tune Stuck In Your Head",
                type = "AA",
                midSong = true,
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
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
                pre_activate = function(self) --Epic is MGB capable on EQM
                    if Casting.AAReady("Mass Group Buff") and Globals.AutoTargetIsNamed then
                        Casting.UseAA("Mass Group Buff", Globals.AutoTargetID)
                    end
                end,
            },
            {
                name = "Boastful Bellow",
                type = "AA",
                midSong = true,
            },
            {
                name = "Selo's Kick",
                type = "AA",
                midSong = true,
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
                name = "AreaAriaSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('AriaChoice') == 2 and self.Helpers.AriaClickyChoice() == "None" end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "GroupAriaSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('AriaChoice') == 3 and self.Helpers.AriaClickyChoice() == "None" end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "Ancient Artifact of Power",
                type = "Item",
                midSong = true,
                load_cond = function(self) return self.Helpers.AriaClickyChoice() == "AncientArtifact" end,
                cond = function(self, itemName)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.AriaClickyRefresh(self, itemName)
                end,
            },
            {
                name = "Echo of Trusik Lute",
                type = "Item",
                midSong = true,
                load_cond = function(self) return self.Helpers.AriaClickyChoice() == "EchoLute" end,
                cond = function(self, itemName)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.AriaClickyRefresh(self, itemName)
                end,
            },
            {
                name = "WarMarchSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseMarch') > 1 end,
                cond = function(self, songSpell)
                    if not self.Helpers.CheckSongStateUse(self, "UseMarch") then return false end
                    return self.Helpers.MarchTimer(self) and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
                post_activate = function(self, songSpell, success)
                    if success then self.TempSettings.LastMarchCast = Globals.GetTimeSeconds() end
                end,
            },
            {
                name = "RunBuff",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseRunBuff') > 1 and not Casting.CanUseAA("Selo's Sonata") end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseRunBuff") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "Jonthan",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseJonthan') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseJonthan") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "ProcSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseProcSong') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseProcSong") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "ResistSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseResist') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseResist") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "MitigationSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseMitigation') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseMitigation") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "ArcaneSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseArcane') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseArcane") and self.Helpers.RefreshBuffSong(self, songSpell)
                end,
            },
            {
                name = "GroupRegenSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('RegenSong') == 2 end,
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
                load_cond = function(self) return Config:GetSetting('RegenSong') == 3 end,
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
                load_cond = function(self) return Config:GetSetting('UseAmp') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAmp") and self.Helpers.RefreshBuffSong(self, songSpell)
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
                name = "Refresh Expiring Song",
                type = "customfunc",
                custom_func = function(self) return self.Helpers.RefreshExpiringSong(self) end,
            },
        },
        ['Downtime'] = {
            {
                name = "DPSAura",
                type = "Song",
                pre_activate = function(self, songSpell) --remove the old aura if we leveled up (or the other aura if we just changed options), otherwise we will be spammed because of no focus.
                    ---@diagnostic disable-next-line: undefined-field
                    if not Casting.AuraActiveByName(songSpell.BaseName()) then mq.TLO.Me.Aura(1).Remove() end
                end,
                cond = function(self, songSpell)
                    if not Config:GetSetting('UseAura') then return false end
                    return not Casting.AuraActiveByName(songSpell.BaseName())
                end,
            },
        },
        ['Emergency'] = {
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
                name = "Revitalize",
                type = "Disc",
                midSong = true,
                cond = function(self, discSpell, target)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Hymn of the Last Stand",
                type = "AA",
                midSong = true,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Shield of Notes",
                type = "AA",
                midSong = true,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Protective",
                type = "Disc",
                midSong = true,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Skals",
                type = "Disc",
                midSong = true,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
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
        ['GroupBuff'] = { -- Added to anchor clickies to

        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                --role and critical functions
                { name = "MezAESong",      cond = function(self) return Config:GetSetting('DoAEMez') end, },
                { name = "MezSong",        cond = function(self) return Config:GetSetting('DoSTMez') end, },
                { name = "CharmSong",      cond = function(self) return Config:GetSetting('CharmOn') end, },
                { name = "SlowSong",       cond = function(self) return Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSong",     cond = function(self) return Config:GetSetting('DoAESlow') end, },
                { name = "DispelSong",     cond = function(self) return Config:GetSetting('DoDispel') end, },
                { name = "ResistDebuff",   cond = function(self) return Config:GetSetting('DoResistDebuff') end, },
                { name = "CureSong",       cond = function(self) return Config:GetSetting('UseCure') end, },
                { name = "RunBuff",        cond = function(self) return Config:GetSetting('UseRunBuff') > 1 and not Casting.CanUseAA("Selo's Sonata") end, },
                { name = "EndBreathSong",  cond = function(self) return Config:GetSetting('UseEndBreath') end, },
                -- major group buffs
                { name = "AreaAriaSong",   cond = function(self) return Config:GetSetting('AriaChoice') == 2 and self.Helpers.AriaClickyChoice() == "None" end, },
                { name = "GroupAriaSong",  cond = function(self) return Config:GetSetting('AriaChoice') == 3 and self.Helpers.AriaClickyChoice() == "None" end, },
                { name = "WarMarchSong",   cond = function(self) return Config:GetSetting('UseMarch') > 1 end, },
                { name = "ProcSong",       cond = function(self) return Config:GetSetting('UseProcSong') > 1 end, },
                { name = "ArcaneSong",     cond = function(self) return Config:GetSetting('UseArcane') > 1 end, },
                { name = "ResistSong",     cond = function(self) return Config:GetSetting('UseResist') > 1 end, },
                { name = "MitigationSong", cond = function(self) return Config:GetSetting('UseMitigation') > 1 end, },
                { name = "GroupRegenSong", cond = function(self) return Config:GetSetting('RegenSong') == 2 end, },
                { name = "AreaRegenSong",  cond = function(self) return Config:GetSetting('RegenSong') == 3 end, },
                -- personal dps
                { name = "AmpSong",        cond = function(self) return Config:GetSetting('UseAmp') > 1 end, },
                { name = "Jonthan",        cond = function(self) return Config:GetSetting('UseJonthan') > 1 end, },
                { name = "FireDotSong",    cond = function(self) return Config:GetSetting('UseFireDots') end, },
                { name = "IceDotSong",     cond = function(self) return Config:GetSetting('UseIceDots') end, },
                { name = "PoisonDotSong",  cond = function(self) return Config:GetSetting('UsePoisonDots') end, },
                { name = "DiseaseDotSong", cond = function(self) return Config:GetSetting('UseDiseaseDots') end, },
                -- filler
                { name = "CalmSong",       cond = function(self) return true end, }, -- condition not needed, for uniformity
            },
        },
    },
    ['PullAbilities']     = {
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
                return (mq.TLO.Me.Buff(aaName).Duration.TotalSeconds() or 0) < 15
            end,
        },
        {
            name = "RunBuff",
            type = "Song",
            load_cond = function(self) return Core.GetResolvedActionMapItem('RunBuff') and Config:GetSetting('UseRunBuff') > 1 and not Casting.CanUseAA("Selo's Sonata") end,
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
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different combat modes do?",
            Answer = "Currently Bards only have one general mode. More modes may be added in the future.",
        },
        -- Buffs
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
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
        },
        ['UseAura']         = {
            DisplayName = "Use Aura",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Use Bard Aura.",
            Default = true,
            ConfigType = "Advanced",
            FAQ = "My bard is spam casting aura, what do I do?",
            Answer = "We have code to prevent this, but if it has slipped the cracks, check what aura you have active in your window (Shift+A by default). You may need to clear it.",
        },
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
        -- Debuffs
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

        -- Defensive
        ['UseResist']       = {
            DisplayName = "Use Resist Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = Tooltips.ResistSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseMitigation']   = {
            DisplayName = "Use Mitigation Song",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = Tooltips.MitigationSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
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
            FAQ = "Why is my Bard regularly using Fading Memories",
            Answer = "When Use Combat Escape is enabled, Fading Memories will be used when the Bard has any unwanted aggro.\n" ..
                "This helps the common issue of bards gaining aggro from singing before a tank has the chance to secure it.",
        },
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

        -- Healing
        ['RegenSong']       = {
            DisplayName = "Regen Song Choice:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 110,
            Tooltip = "Select the Regen Song to be used, if any. Always used out of combat if selected. Use in-combat is determined by sustain settings.",
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
        ['GroupManaPct']    = {
            DisplayName = "Group Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Index = 103,
            Tooltip = "Mana% to begin using our regen song, if configured under the Regen Song Use.",
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
            Index = 104,
            Tooltip = "The number of party members (including yourself) that need to be under the above mana percentage.",
            Default = 2,
            Min = 1,
            Max = 6,
            ConfigType = "Advanced",
        },
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

        -- Instruments
        ['SwapInstruments'] = {
            DisplayName = "Auto Swap Instruments",
            Index = 101,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Auto swap instruments for songs",
            Default = false,

        },
        ['UseBandolier']    = {
            DisplayName = "Use Bandolier",
            Index = 102,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Auto swap instruments using bandolier if avail, valid names (wind, drum, brass, string or main), if a bandolier is missing we will direct swap instead.",
            Default = true,
        },
        ['Offhand']         = {
            DisplayName = "Offhand",
            Index = 103,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Item to swap in when no instrument is available or needed.",
            Type = "ClickyItem",

            Default = "",
        },
        ['BrassInst']       = {
            DisplayName = "Brass Instrument",
            Index = 104,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Brass Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['WindInst']        = {
            DisplayName = "Wind Instrument",
            Index = 105,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Wind Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['PercInst']        = {
            DisplayName = "Percussion Instrument",
            Index = 106,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Percussion Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },
        ['StringedInst']    = {
            DisplayName = "Stringed Instrument",
            Index = 107,
            Group = "Items",
            Header = "Instruments",
            Category = "Instruments",
            Tooltip = "Stringed Instrument to Swap in as needed.",
            Type = "ClickyItem",
            Default = "",
        },

        -- Offensive
        ['AriaChoice']      = {
            DisplayName = "Aria Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = Tooltips.AriaSong,
            Type = "Combo",
            ComboOptions = { 'None', 'AoE', 'Group', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['UseAria']         = {
            DisplayName = "Use Aria",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = Tooltips.AriaSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseAriaClickies'] = {
            DisplayName = "Use Aria Clickies",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Use available Aria clickies (Such as Ancient Artifact of Power or Echo of Trusik Lute) instead of the song.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['UseMarch']        = {
            DisplayName = "Use War March",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = Tooltips.WarMarchSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 3,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['UseProcSong']     = {
            DisplayName = "Use Group Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = Tooltips.ProcSong,
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
            Index = 106,
            Tooltip = Tooltips.ArcaneSong,
            Type = "Combo",
            ComboOptions = { 'Never', 'In-Combat Only', 'Always', 'Out-of-Combat Only', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
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
        },
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

        -- Song Duration Adjustment
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
        ['SongDuration']    = {
            DisplayName = "Song Duration",
            Group = "Abilities",
            Header = "Common",
            Category = "Under the Hood",
            Index = 102,
            Tooltip = "Song duration in seconds; EMU cannot autodetect it, mostly used for Jonthan and War March together.",
            Default = mq.TLO.Me.AltAbility("Extended Ingenuity")() ~= nil and 18 or 12,
            Min = 1,
            Max = 60,
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
