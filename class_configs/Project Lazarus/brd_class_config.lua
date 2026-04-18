local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Strings      = require("utils.strings")
local Logger       = require("utils.logger")
local ItemManager  = require('utils.item_manager')

local Tooltips     = {
    Epic           = 'Item: Casts Epic Weapon Ability',
    BardRunBuff    = "Song Line: Movement Speed Modifier",
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
    MezSong        = "Song Line: Single Target Mez",
    MezAESong      = "Song Line: PBAE Mez",
    Bellow         = "AA: DD + Resist Debuff that leads to a much larger DD upon expiry",
    FuneralDirge   = "AA: DD / Increases Melee Damage Taken on Target",
    FierceEye      = "AA: Increases Base and Crit Melee Damage / Increase Proc Rate / Increase Spell Crit Chance",
    QuickTime      = "AA: Hundred Hands Effect / Increase Melee Hit / Increase Atk",
    Jonthan        = "Song Line: (Self-only) Haste / Melee Damage Modifier / Melee Min Damage Modifier / Proc Modifier",
}

local _ClassConfig = {
    _version          = "3.1 - Project Lazarus",
    _author           = "Algar, Derple, Grimmier, Tiddliestix, SonicZentropy",
    ['Modes']         = { --other modes to reorder spell priorities may be added back in at a later date.
        'General',
    },

    ['ModeChecks']    = {
        CanMez     = function() return true end,
        CanCharm   = function() return true end,
        IsMezzing  = function() return Config:GetSetting('MezOn') end,
        IsCuring   = function() return Config:GetSetting('UseCure') end,
        IsCharming = function() return Config:GetSetting('CharmOn') and mq.TLO.Pet.ID() == 0 end,
    },
    ['Cures']         = {
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
    ['ItemSets']      = {
        ['Epic'] = {
            "Blade of Vesagran",
            "Prismatic Dragon Blade",
        },
    },
    ['AbilitySets']   = {
        -- TO DO: Added Dirgle of Metala/Snare line
        -- bellow of chaos 66 dd nuke??
        -- one bard band --- this spell does not exist
        -- vulka's chant of lightning - not available as a spell, fuku glyph only
        ['RunBuff'] = {
            "Selo's Accelerating Chorus",
            "Selo's Accelerando",
        },
        ['EndBreathSong'] = {
            "Tarew's Aquatic Ayre", --Level 16
        },
        ['AriaSong'] = {
            "Ancient: Call of Power",
            "Eriki's Psalm of Power",
            "Yelhun's Mystic Call",
            "Echo of the Trusik",
            "Rizlona's Call of Flame",   -- overhaste/spell damage
            "Battlecry of the Vah Shir", -- overhaste only
            "Warsong of the Vah Shir",   -- overhaste only
            -- "Rizlona's Fire",   -- spell damage only
            -- "Rizlona's Embers", -- spell damage only
        },
        ['ArcaneSong'] = {
            "Arcane Aria",
        },
        ['DPSAura'] = {
            "Aura of the Muse",
            "Aura of Insight",
        },
        ['GroupRegenSong'] = {
            "Cantata of Life",               -- 67
            "Wind of Marr",                  -- 62
            "Cantata of Replenishment",      -- 55
            "Cantata of Soothing",           -- 34 start hp/mana. Slightly less mana. They can custom if it they want the 2 mana/tick
            "Cassindra's Chorus of Clarity", -- 32, mana only
            "Cassindra's Chant of Clarity",  -- 20, mana only
            "Hymn of Restoration",           -- 7, hp only
        },
        ['AreaRegenSong'] = {
            "Chorus of Life",          -- 69
            "Chorus of Marr",          -- 64
            "Ancient: Lcea's Lament",  -- 60
            "Chorus of Replenishment", -- 58
        },
        ['WarMarchSong'] = {
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
        ['SlowSong'] = {
            "Requiem of Time",
            "Angstlich's Assonance",    --snare/slow
            "Largo's Assonant Binding", --snare/slow
            "Selo's Consonant Chain",   --snare/slow
        },
        ['AESlowSong'] = {
            "Zuriki's Song of Shenanigans",
            "Largo's Melodic Binding",
        },
        ['FireDotSong'] = {
            "Vulka's Chant of Flame",
            "Tuyen's Chant of Fire",
            "Tuyen's Chant of Flame",
        },
        ['IceDotSong'] = {
            "Vulka's Chant of Frost",
            "Tuyen's Chant of Ice",
            "Tuyen's Chant of Frost",
        },
        ['PoisonDotSong'] = {
            "Vulka's Chant of Poison",
            "Tuyen's Chant of Venom",
            "Tuyen's Chant of Poison",
        },
        ['DiseaseDotSong'] = {
            "Vulka's Chant of Disease",
            "Tuyen's Chant of the Plague",
            "Tuyen's Chant of Disease",
        },
        ['CureSong'] = {
            --"Aria of Innocence", --curse only, and only 2 x 2 counters
            "Aria of Asceticism", --poison/disease Only
        },
        ['CharmSong'] = {
            "Voice of the Vampire",
            "Call of the Banshee",        -- 65
            "Solon's Bewitching Bravura", -- 39
            "Solon's Song of the Sirens", -- 27
        },
        -- ['ChordsAE'] = {
        --     "Chords of Dissonance",
        -- },

        ['AmpSong'] = {
            "Amplification",
        },
        ['DispelSong'] = {
            -- Dispel Song - For pulling to avoid Summons
            "Syvelian's Anti-Magic Aria",
            "Druzzil's Disillusionment",
        },
        ['ResistSong'] = {
            "Verse of Veeshan",
            "Psalm of Veeshan",
        },
        ['MezSong'] = {
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
        ['Jonthan'] = {
            "Jonthan's Inspiration",
            "Jonthan's Provocation",
            "Jonthan's Whistling Warsong",
        },
        ['CalmSong'] = {
            -- CalmSong - Level Range 8+ --Included for manual use with /rgl usemap
            "Luvwen's Aria of Serenity", -- Level 66
            "Silent Song of Quellious",  -- Level 61
            "Kelin's Lugubrious Lament", -- Level 8 (Max Mob Level of 60)
        },
        ['ThousandBlades'] = {
            "Thousand Blades",
        },
        ['StormBlade'] = {
            "Storm Blade Flourish",
        },
        ['SpellAbsorbSong'] = {
            "Echoes of the Past",
        },
        ['ResistDebuff'] = {
            "Harmony of Sound",
        },
        ['BellowSong'] = {
            "Bellow of Chaos",
        },
    },
    ['Helpers']       = {
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
        CheckSongStateUse = function(self, config)   --determine whether a song should be song by comparing combat state to settings
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
    ['RotationOrder'] = {
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
    ['Rotations']     = {
        ['Burn'] = { --Order is heavy WIP
            {
                name = "Quick Time",
                type = "AA",
            },
            {
                name = "Fierce Eye",
                type = "AA",
            },
            {
                name = "Funeral Dirge",
                type = "AA",
            },
            { -- Spire, the SpireChoice setting will determine which ability is displayed/used.
                name_func = function(self)
                    local spireAbil = string.format("Fundament: %s Spire of the Minstrels", Globals.Constants.SpireChoices[Config:GetSetting('SpireChoice') or 4])
                    return Casting.CanUseAA(spireAbil) and spireAbil or "Spire Not Purchased/Selected"
                end,
                type = "AA",
            },
            {
                name = "Bladed Song",
                type = "AA",
            },
            {
                name = "Song of Stone",
                type = "AA",
            },
            {
                name = "ThousandBlades",
                type = "Disc",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Dance of Blades",
                type = "AA",
            },
            {
                name = "Cacophony",
                type = "AA",
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "A Tune Stuck In Your Head",
                type = "AA",
            },
            {
                name = "SpellAbsorbSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseSpellAbsorb') end,
                cond = function(self, songSpell)
                    return Casting.CastReady(songSpell)
                end,
            },
        },
        ['Debuff'] = {
            {
                name = "AESlowSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting("DoAESlow") end,
                cond = function(self, songSpell, target)
                    return Casting.DetSpellCheck(songSpell) and Targeting.GetXTHaterCount() > 2 and not mq.TLO.Target.Slowed() and
                        not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting("DoSTSlow") end,
                cond = function(self, songSpell, target)
                    return Casting.DetSpellCheck(songSpell) and not mq.TLO.Target.Slowed() and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "ResistDebuff",
                type = "Song",
                load_cond = function(self) return Config:GetSetting("DoResistDebuff") end,
                cond = function(self, songSpell)
                    return Casting.DetSpellCheck(songSpell)
                end,
            },
            {
                name = "DispelSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting("DoDispel") end,
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
            },
            {
                name = "Boastful Bellow",
                type = "AA",
            },
            {
                name = "Vainglorious Shout",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('UseShout') end,
            },
            {
                name = "Kick",
                type = "Ability",
            },
        },
        ['CombatSongs'] = {
            {
                name = "StormBlade",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseStormBlade') > 1 end,
                cond = function(self, songSpell)
                    if not Casting.BurnCheck() and mq.TLO.Me.PctMana() <= Config:GetSetting('ReserveManaPct') then return false end
                    return Config:GetSetting('UseStormBlade') == 3 or self.Helpers.RefreshBuffSong(mq.TLO.Spell("Storm Blade"))
                end,
            },
            {
                name = "BellowSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseBellow') end,
                cond = function(self, songSpell)
                    if not Casting.BurnCheck() and mq.TLO.Me.PctMana() <= Config:GetSetting('ReserveManaPct') then return false end
                    return true
                end,
            },
            {
                name = "FireDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseFireDots') end,
                cond = function(self, songSpell)
                    return self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('RefreshCombat')
                end,
            },
            {
                name = "IceDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseIceDots') end,
                cond = function(self, songSpell)
                    return self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('RefreshCombat')
                end,
            },
            {
                name = "PoisonDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UsePoisonDots') end,
                cond = function(self, songSpell)
                    return self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('RefreshCombat')
                end,
            },
            {
                name = "DiseaseDotSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseDiseaseDots') end,
                cond = function(self, songSpell)
                    return self.Helpers.DotSongCheck(songSpell) and
                        self.Helpers.GetDetSongDuration(songSpell) <= Config:GetSetting('RefreshCombat')
                end,
            },
            --failsafe/fallback to fill dead space and/or refresh charges, may adjust after more testing
            {
                name = "AriaSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.Song(songSpell.Name()).Duration.TotalSeconds() or 0) <= 6
                end,
            },
            {
                name = "ArcaneSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseArcane') > 1 end,
                cond = function(self, songSpell)
                    return (mq.TLO.Me.Song(songSpell.Name()).Duration.TotalSeconds() or 0) <= 6
                end,
            },
        },
        ['Enduring Breath'] = {
            {
                name = "EndBreathSong",
                type = "Song",
                cond = function(self, songSpell)
                    return self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
        },
        ['Melody'] = {
            {
                name = "AriaSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseAria') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAria") and self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "WarMarchSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseMarch') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseMarch") and self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "Jonthan",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseJonthan') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseJonthan") and self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "ResistSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseResist') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseResist") and self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "ArcaneSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseArcane') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseArcane") and self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
            {
                name = "GroupRegenSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('RegenSong') == 2 end,
                cond = function(self, songSpell)
                    local pct = Config:GetSetting('GroupManaPct')
                    return self.Helpers.RefreshBuffSong(songSpell) and
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
                    return self.Helpers.RefreshBuffSong(songSpell) and
                        ((Config:GetSetting('UseRegen') == 1 and (mq.TLO.Group.LowMana(pct)() or 999) >= Config:GetSetting('GroupManaCt'))
                            or (Config:GetSetting('UseRegen') > 1 and self.Helpers.CheckSongStateUse(self, "UseRegen")))
                end,
            },
            {
                name = "AmpSong",
                type = "Song",
                load_cond = function(self) return Config:GetSetting('UseAmp') > 1 end,
                cond = function(self, songSpell)
                    return self.Helpers.CheckSongStateUse(self, "UseAmp") and self.Helpers.RefreshBuffSong(songSpell)
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
                    return (mq.TLO.Me.Buff(aaName).Duration.TotalSeconds() or 0) < 30
                end,
            },
            {
                name = "RunBuff",
                type = "Song",
                targetId = function(self) return { mq.TLO.Me.ID(), } end,
                load_cond = function(self) return Config:GetSetting('UseRunBuff') and not Casting.CanUseAA("Selo's Sonata") end,
                cond = function(self, songSpell)
                    if Globals.InMedState then return false end
                    return self.Helpers.RefreshBuffSong(songSpell)
                end,
            },
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
                cond = function(self, aaName)
                    if not Config:GetSetting('UseFading') then return false end
                    return self.Helpers.UnwantedAggroCheck(self)
                    --I wanted to use XTAggroCount here but it doesn't include your current target in the number it returns and I don't see a good workaround. For Loop it is.
                end,
            },
            {
                name = "Hymn of the Last Stand",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Shield of Notes",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "Blood Drinker's Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
    },
    ['SpellList']     = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                --role and critical functions
                { name = "MezSong",         cond = function(self) return Config:GetSetting('DoSTMez') end, },
                { name = "CharmSong",       cond = function(self) return Config:GetSetting('CharmOn') end, },
                { name = "SlowSong",        cond = function(self) return Config:GetSetting('DoSTSlow') end, },
                { name = "AESlowSong",      cond = function(self) return Config:GetSetting('DoAESlow') end, },
                { name = "DispelSong",      cond = function(self) return Config:GetSetting('DoDispel') end, },
                { name = "ResistDebuff",    cond = function(self) return Config:GetSetting('DoResistDebuff') end, },
                { name = "CureSong",        cond = function(self) return Config:GetSetting('UseCure') end, },
                { name = "RunBuff",         cond = function(self) return Config:GetSetting('UseRunBuff') and not Casting.CanUseAA("Selo's Sonata") end, },
                { name = "EndBreathSong",   cond = function(self) return Config:GetSetting('UseEndBreath') end, },
                -- major group buffs
                { name = "AriaSong",        cond = function(self) return Config:GetSetting('UseAria') > 1 end, },
                { name = "WarMarchSong",    cond = function(self) return Config:GetSetting('UseMarch') > 1 end, },
                { name = "StormBlade",      cond = function(self) return Config:GetSetting('UseStormBlade') > 1 end, },
                { name = "ArcaneSong",      cond = function(self) return Config:GetSetting('UseArcane') > 1 end, },
                { name = "ResistSong",      cond = function(self) return Config:GetSetting('UseResist') > 1 end, },
                { name = "SpellAbsorbSong", cond = function(self) return Config:GetSetting('UseSpellAbsorb') end, },
                { name = "GroupRegenSong",  cond = function(self) return Config:GetSetting('RegenSong') == 2 end, },
                { name = "AreaRegenSong",   cond = function(self) return Config:GetSetting('RegenSong') == 3 end, },
                -- personal dps
                { name = "AmpSong",         cond = function(self) return Config:GetSetting('UseAmp') > 1 end, },
                { name = "Jonthan",         cond = function(self) return Config:GetSetting('UseJonthan') > 1 end, },
                { name = "BellowSong",      cond = function(self) return Config:GetSetting('UseBellow') end, },
                { name = "FireDotSong",     cond = function(self) return Config:GetSetting('UseFireDots') end, },
                { name = "IceDotSong",      cond = function(self) return Config:GetSetting('UseIceDots') end, },
                { name = "PoisonDotSong",   cond = function(self) return Config:GetSetting('UsePoisonDots') end, },
                { name = "DiseaseDotSong",  cond = function(self) return Config:GetSetting('UseDiseaseDots') end, },
                -- filler
                { name = "CalmSong",        cond = function(self) return true end, }, -- condition not needed, for uniformity
            },
        },
    },
    ['PullAbilities'] = {
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
    ['DefaultConfig'] = {
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
            Tooltip = "Use your run speed buff song or AA.",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why am I slowing down in combat?",
            Answer = "Runspeed songs, if selected, are only sung in the downtime rotation. Higher level bards will have longer durations.",
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
        ['SpireChoice']     = {
            DisplayName = "Spire Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Choose which Fundament you would like to use during burns:\n" ..
                "First Spire: Spell Crit Buff to Self.\n" ..
                "Second Spire: Healing Power Buff to Self.\n" ..
                "Third Spire: Large Group HP Buff.",
            Type = "Combo",
            ComboOptions = Globals.Constants.SpireChoices,
            Default = 3,
            Min = 1,
            Max = #Globals.Constants.SpireChoices,
        },
        ['DoVetAA']         = {
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
            Tooltip = "Use the Harmony of Sound Resist Debuff.",
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
        ['UseSpellAbsorb']  = {
            DisplayName = "Use Spell Absorb",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "When is the Spell Damage Absorb/Shield used?",
            Answer = "This song is used during burns.",
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
        ['DoCoating']       = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood Drinker's Coating in an emergency.",
            Default = false,
            ConfigType = "Advanced",
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
        ['UseStormBlade']   = {
            DisplayName = "Use Storm Blade Flourish",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use your Storm Blade Flourish (on hit, triggers a proc buff).\n We will only use this song when over the Reserve Mana Pct, unless we are burning.",
            Type = "Combo",
            ComboOptions = { 'Never', 'To Maintain Buff', 'Whenever Possible', },
            Default = 2,
            Min = 1,
            Max = 3,
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
        ['UseBellow']       = {
            DisplayName = "Use Bellow of Chaos",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your Bellow of Chaos DD song.\nWe will only use this song when over the Reserve Mana Pct, unless we are burning.",
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
        ['UseShout']        = {
            DisplayName = "Use Vain. Shout",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "Use Vainglorious Shout (Conal DD/Resist Debuff) ***WILL BREAK MEZ***",
            Default = false,
        },

        -- Song Duration Adjustment
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
        ['ReserveManaPct']  = {
            DisplayName = "Reserve Mana %",
            Group = "Abilities",
            Header = "Common",
            Category = "Common Rules",
            Index = 101,
            Tooltip = "Minimum Mana% to use Storm Blade Flourish or Bellow of Chaos outside of burns.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
            FAQ = "Why am I constantly low on mana?",
            Answer = "Storm Blade and Bellow can take a lot of mana, but we can control that amount with the Reserve Mana %.\n" ..
                "Try adjusting this to the minimum amount of mana you want to keep in reserve. Note that burns will ignore this setting.",
        },
    },
    ['ClassFAQ']      = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is a current release customized specifically for Project Lazarus server.\n\n" ..
                "  This config should perform admirably from start to endgame.\n\n" ..
                "  Clickies that aren't already included should be managed via the clickies tab, or by customizing the config to add them directly.\n" ..
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
