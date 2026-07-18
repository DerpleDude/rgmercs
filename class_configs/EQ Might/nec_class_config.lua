local mq           = require('mq')
local Casting      = require("utils.casting")
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Core         = require("utils.core")
local Globals      = require("utils.globals")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version            = "2.1 - EQ Might",
    _author             = "Algar, Derple",
    ['Modes']           = {
        'DPS',
    },
    ['PetPosition']     = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
    },
    ['ModeChecks']      = {
        CanCharm = function() return true end,
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Rez']             = {
        ['Combat']   = {
            { type = "Item", name = "RezStaff", },
        },
        ['Downtime'] = {
            { type = "Item", name = "RezStaff", },
        },
    },
    ['Themes']          = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.5, g = 0.05, b = 1.0, a = .8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.4, g = 0.05, b = 0.8, a = .8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.2, g = 0.05, b = 0.6, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.1, g = 0.05, b = 0.5, a = .1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.5, g = 0.05, b = 1.0, a = .8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.5, g = 0.05, b = 1.0, a = .9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
        },
    },
    ['CommandHandlers'] = {
        startlich = {
            usage = "/rgl startlich",
            about = "Start your Lich Spell [Note: This will enabled DoLich if it is not already].",
            handler =
                function(self)
                    Config:SetSetting('DoLich', true)
                    Core.SafeCallFunc("Start Necro Lich", self.Helpers.StartLich, self)

                    return true
                end,
        },
        stoplich = {
            usage = "/rgl stoplich",
            about = "Stop your Lich Spell [Note: This will NOT disable DoLich].",
            handler =
                function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.Helpers.CancelLich, self)

                    return true
                end,
        },
    },
    ['ItemSets']        = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Deathwhisper",
            "Soulwhisper",
        },
        ['OoW_Chest'] = {
            "Blightbringer's Tunic of the Grave",
            "Deathcaller's Robe",
        },
        ['DeathDagger'] = {
            "Legendary Dagger of Death",
            "Dagger of Death",
        },
        ['RedDemon'] = {
            "Artifact of the Greater Red Demon",
            "Artifact of the Red Demon",
        },
        ['Thulik'] = {
            "Artifact of Thulik",
        },
    },
    ['AbilitySets']     = {
        ['SelfHPBuff'] = {
            "Shield of Darkness",   -- Level 70
            "Shadow Guard",         -- Level 66
            "Shield of Maelin",     -- Level 64
            "Shield of the Arcane", -- Level 61
            "Shield of the Magi",   -- Level 54
            "Arch Shielding",       -- Level 41
            "Greater Shielding",    -- Level 33
            "Major Shielding",      -- Level 24
            "Shielding",            -- Level 16
            "Lesser Shielding",     -- Level 8
            "Minor Shielding",      -- Level 1
        },
        ['SelfRune'] = {
            "Wraithskin",   -- Level 71
            "Dull Pain",    -- Level 69
            "Force Shield", -- Level 63
            "Manaskin",     -- Level 52
            "Diamondskin",  -- Level 43
            "Steelskin",    -- Level 32
            "Leatherskin",  -- Level 22
            "Shieldskin",   -- Level 14
        },
        ['CharmSpell'] = {
            "Word of Chaos",   -- Level 70
            "Word of Terris",  -- Level 65
            "Enslave Death",   -- Level 60
            "Thrall of Bones", -- Level 54
            "Cajole Undead",   -- Level 47
            "Beguile Undead",  -- Level 31
            "Dominate Undead", -- Level 18
        },
        ['LifeTap'] = {
            "Drain Life",                 -- Level 70
            "Ancient: Touch of Orshilak", -- Level 68
            "Soulspike",                  -- Level 67
            "Touch of Mujaki",            -- Level 61
            -- "Gangrenous Touch of Zum`uul", -- Level 60
            "Touch of Night",             -- Level 59
            "Deflux",                     -- Level 54
            "Drain Soul",                 -- Level 48
            "Drain Spirit",               -- Level 39
            "Spirit Tap",                 -- Level 26
            "Siphon Life",                -- Level 20
            "Lifedraw",                   -- Level 12
            "Lifespike",                  -- Level 3
            "Lifetap",                    -- Level 1
        },
        ['DurationTap'] = {
            "Dyn`leth's Grasp",       -- Level 71
            "Ancient: Chiasa's Kiss", -- Level 68 EQM Custom
            -- "Fang of Death",         -- Level 68
            -- "Night's Beckon",        -- Level 65
            -- "Saryrn's Kiss",         -- Level 62
            -- "Vexing Replenishment",  -- Level 57
            -- "Bond of Death",         -- Level 49
            -- "Auspice",               -- Level 45
            -- "Vampiric Curse",        -- Level 29
            -- "Shadow Compact",        -- Level 17
            -- "Leech",                 -- Level 9
        },
        ['PoisonNuke'] = {
            "Venin",                -- Level 70
            "Call for Blood",       -- Level 68
            "Acikin",               -- Level 66
            "Neurotoxin",           -- Level 61
            "Ancient: Lifebane",    -- Level 60
            "Torbas' Venom Blast",  -- Level 54
            "Torbas' Poison Blast", -- Level 49
            "Torbas' Acid Blast",   -- Level 32
            "Shock of Poison",      -- Level 21
        },
        ['FireDot'] = {
            "Pyre of the Fallen",      -- Level 71
            "Dread Pyre",              -- Level 70
            "Pyre of Mori",            -- Level 67
            "Night Fire",              -- Level 65
            "Funeral Pyre of Kelador", -- Level 60
            "Pyrocruor",               -- Level 58
            "Ignite Blood",            -- Level 47
            "Boil Blood",              -- Level 28
            "Heat Blood",              -- Level 10
        },
        ['FireDot2'] = {
            "Pyre of the Fallen",      -- Level 71
            "Dread Pyre",              -- Level 70
            "Pyre of Mori",            -- Level 67
            "Night Fire",              -- Level 65
            "Funeral Pyre of Kelador", -- Level 60
            "Pyrocruor",               -- Level 58
            "Ignite Blood",            -- Level 47
        },
        ['FireDot3'] = {
            "Pyre of the Fallen",      -- Level 71
            "Dread Pyre",              -- Level 70
            "Pyre of Mori",            -- Level 67
            "Night Fire",              -- Level 65
            "Funeral Pyre of Kelador", -- Level 60
        },
        -- ['SplurtDot'] = {
        --     "Splurt", -- Level 51
        -- },
        ['CurseDot'] = {
            "Curse of Mortality",     -- Level 71 Timer 4
            "Ancient: Curse of Mori", -- Level 70 Timer 5
            "Dark Nightmare",         -- Level 67 Timer 4
            "Horror",                 -- Level 63
            "Imprecation",            -- Level 54
            "Dark Soul",              -- Level 39
        },
        ['CurseDot2'] = {
            "Curse of Mortality",     -- Level 71 Timer 4
            "Ancient: Curse of Mori", -- Level 70 Timer 5
            "Dark Nightmare",         -- Level 67 Timer 4
            "Horror",                 -- Level 63
            "Imprecation",            -- Level 54
        },
        ['PlagueDot'] = {
            "Severan's Rot",    -- Level 70
            "Chaos Plague",     -- Level 66
            "Dark Plague",      -- Level 61
            "Cessation of Cor", -- Level 56
        },
        -- ['DebuffDot'] = {
        --     "Plague",           -- Level 52
        --     "Asystole",         -- Level 40
        --     "Scourge",          -- Level 35
        --     "Infectious Cloud", -- Level 15
        --     "Heart Flutter",    -- Level 13
        --     "Disease Cloud",    -- Level 1
        --     "Grip of Mori",     -- Level 67 (note: original list position kept)
        -- },
        ['PoisonDot'] = {
            -- "Chaos Venom",     -- Level 70 (worse than corath venom)
            "Corath Venom",       -- Level 69
            "Blood of Thule",     -- Level 65
            "Virulent Bolt",      -- Level 59 EQM Custom
            "Envenomed Bolt",     -- Level 50
            "Chilling Embrace",   -- Level 36
            "Venom of the Snake", -- Level 34
            "Poison Bolt",        -- Level 4
        },
        ['PoisonDot2'] = {
            -- "Chaos Venom",     -- Level 70 (worse than corath venom)
            "Corath Venom",       -- Level 69
            "Blood of Thule",     -- Level 65
            "Virulent Bolt",      -- Level 59 EQM Custom
            "Envenomed Bolt",     -- Level 50
            "Chilling Embrace",   -- Level 36
            "Venom of the Snake", -- Level 34
        },
        ['SnareDot'] = {
            "Desecrating Darkness", -- Level 68
            "Embracing Darkness",   -- Level 63
            "Devouring Darkness",   -- Level 59
            "Cascading Darkness",   -- Level 47
            "Scent of Darkness",    -- Level 37
            "Dooming Darkness",     -- Level 27
            "Engulfing Darkness",   -- Level 11
            "Clinging Darkness",    -- Level 4
        },
        ['ScentDebuff'] = {
            "Scent of Terris",   -- Level 52
            "Scent of Darkness", -- Level 37
            "Scent of Shadow",   -- Level 21
            "Scent of Dusk",     -- Level 10
        },
        ['ScentDebuff2'] = {
            "Scent of Twilight", -- Level 71
            "Scent of Midnight", -- Level 68
        },
        ['LichSpell'] = {
            "Dark Possession",             -- Level 70
            "Grave Pact",                  -- Level 70
            "Ancient: Seduction of Chaos", -- Level 65
            "Seduction of Saryrn",         -- Level 64
            "Ancient: Master of Death",    -- Level 60
            "Arch Lich",                   -- Level 60
            "Demi Lich",                   -- Level 56
            "Lich",                        -- Level 48
            "Call of Bones",               -- Level 31
            "Allure of Death",             -- Level 18
            "Dark Pact",                   -- Level 6
        },
        ['RogPetSpell'] = {
            "Dark Assassin",         -- Level 70
            "Child of Bertoxxulous", -- Level 65
            "Saryrn's Companion",    -- Level 63
            "Minion of Shadows",     -- Level 53
        },
        ['WarPetSpell'] = {
            "Lost Soul",             -- Level 66
            "Child of Bertoxxulous", -- Level 65
            "Legacy of Zek",         -- Level 61
            "Emissary of Thule",     -- Level 59
            "Servant of Bones",      -- Level 55
            "Invoke Death",          -- Level 48
            "Cackling Bones",        -- Level 44
            "Malignant Dead",        -- Level 39
            "Invoke Shadow",         -- Level 33
            "Summon Dead",           -- Level 29
            "Haunting Corpse",       -- Level 24
            "Animate Dead",          -- Level 20
            "Restless Bones",        -- Level 16
            "Convoke Shadow",        -- Level 12
            "Bone Walk",             -- Level 8
            "Leering Corpse",        -- Level 4
            "Cavorting Bones",       -- Level 1
        },
        ['PetHaste'] = {
            "Sigil of the Unnatural", -- Level 71
            "Glyph of Darkness",      -- Level 67
            "Rune of Death",          -- Level 62
            "Augmentation of Death",  -- Level 55
            "Augment Death",          -- Level 35
            "Intensify Death",        -- Level 23
            "Focus Death",            -- Level 11
        },
        ['UndeadNuke'] = {
            "Desolate Undead", -- Level 70
            "Destroy Undead",  -- Level 65
            "Exile Undead",    -- Level 57
            "Banish Undead",   -- Level 46
            "Expel Undead",    -- Level 38
            "Dismiss Undead",  -- Level 28
            "Expulse Undead",  -- Level 19
            "Ward Undead",     -- Level 6
        },
        ['OrbNuke'] = {
            "Umbra Orb",  -- Level 70
            "Shadow Orb", -- Level 69
            "Soul Orb",   -- Level 61
        },
        -- ['Calliav'] = { --35s refresh on mem, and this does not seem worth a gem slot currently
        --     "Bulwark of Calliav",    -- Level 69
        --     "Protection of Calliav", -- Level 64
        --     "Guard of Calliav",      -- Level 58
        --     "Ward of Calliav",       -- Level 49
        -- },
        ['PetHealSpell'] = {      -- Also has cure effect for pet
            "Chilling Renewal",   -- Level 71
            "Dark Salve",         -- Level 69
            "Renewal of Lucifer", -- Level 67 EQM Custom
            "Touch of Death",     -- Level 64
            "Renew Bones",        -- Level 26
            "Mend Bones",         -- Level 7
        },
        -- ['GroupLeech'] = {
        --     "Night Stalker",            -- Level 65
        --     "Zevfeer's Theft of Vitae", -- Level 60
        -- },
        ['FeignSpell'] = {
            "Death Peace", -- Level 60
            "Comatose",    -- Level 52
            "Feign Death", -- Level 16
        },
        ['HarmshieldSpell'] = {
            "Quivering Veil of Xarn", -- Level 58
            "Harmshield",             -- Level 20
        },
        -- ['UndeadConvert'] = {
        --     "Chill Bones",  -- Level 55
        --     "Ignite Bones", -- Level 42
        -- },
        ['Minionskin'] = {        --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",   -- Level 66 EQM Custom
            "Greater Minionskin", -- Level 56 EQM Custom
            "Minionskin",         -- Level 43 EQM Custom
            "Lesser Minionskin",  -- Level 30 EQM Custom
        },
        ['ColdDot'] = {
            "Chillgrave", -- Level 69 EQM Custom
            "Frostgrave", -- Level 63 EQ Custom
        },
    },
    ['AASets']          = {
        ['Spire'] = {
            "Fundament: First Spire of Necromancy",
        },
        ['DeadSwarm'] = {
            "Army of the Dead",
            "Wake the Dead",
        },
    },
    ['Charm']           = {
        ['Abilities'] = {
            { name = "Dire Charm", type = "AA", },
            { name = "CharmSpell", type = "Spell", },
        },
    },
    ['RotationOrder']   = {
        {
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and Casting.AmIBuffable() and not Core.IsCharming()
            end,
        },
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99))
            end,
        },
        {
            name = 'PetHealing',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, target) return (mq.TLO.Me.Pet.PctHPs() or 100) < Config:GetSetting('PetHealPct') end,
        },
        {
            name = 'Scent(Terris)',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('ScentDebuffUse') == 2 end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        { -- On Laz, this hits slightly different resists, and in different slots, it is a choice.
            name = 'Scent(Midnight)',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('ScentDebuffUse') == 3 end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount') and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and not Casting.IAmFeigning() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(MobHighHP)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Targeting.MobNotLowHP(Targeting.GetAutoTarget()) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS(MobLowHP)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Targeting.MobHasLowHP(Targeting.GetAutoTarget()) and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'CombatBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning()
            end,
        },
    },
    ['Rotations']       = {
        ['Emergency']       = {
            {
                name = "Death's Effigy",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('AggroFeign') then return false end
                    if Config:GetSetting('CharmOn') and mq.TLO.Me.Pet.ID() > 0 then return false end
                    return (Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 99) or (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Targeting.IHaveAggro(100))
                end,
            },
            {
                name = "Harm Shield",
                type = "AA",
                cond = function(self, aaName)
                    return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') and Targeting.IHaveAggro(100))
                end,
            },
        },
        ['Scent(Terris)']   = {
            {
                name_func = function(self)
                    local scentItems = { "Legendary Fabled Nightshade Scented Staff", "Fabled Nightshade Scented Staff", "Scent of Terris", }
                    for _, v in ipairs(scentItems) do
                        if mq.TLO.FindItem("=" .. v)() then
                            return v
                        end
                    end
                    return "No Scent Item Found"
                end,
                type = "Item",
                load_cond = function(self) return self.Helpers.GetScentItem ~= nil end,
                cond = function(self, itemName, target)
                    return Casting.DetItemCheck(itemName)
                end,
            },
            {
                name = "ScentDebuff",
                type = "Spell",
                load_cond = function(self) return not self.Helpers.GetScentItem end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Scent(Midnight)'] = {
            {
                name = "ScentDebuff2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Snare']           = {
            {
                name = "Encroaching Darkness",
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Encroaching Darkness") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareDot",
                type = "Spell",
                load_cond = function(self) return not Casting.CanUseAA("Encroaching Darkness") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['CombatBuff']      = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
                end,
            },
            {
                name = "LichSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLich') end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell, nil, true) and mq.TLO.Me.PctHPs() > Config:GetSetting('StopLichHP') and
                        mq.TLO.Me.PctMana() <= Config:GetSetting('StartLichMana')
                end,
            },
            {
                name = "LichControl",
                type = "CustomFunc",
                load_cond = function(self) return Config:GetSetting('DoLich') end,
                cond = function(self, _)
                    local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

                    return lichSpell and lichSpell() and Casting.IHaveBuff(lichSpell) and
                        (mq.TLO.Me.PctHPs() <= Config:GetSetting('StopLichHP') or mq.TLO.Me.PctMana() >= Config:GetSetting('StopLichMana'))
                end,
                custom_func = function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.Helpers.CancelLich, self)
                    return true
                end,
            },
            {
                name = "RedDemon",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("DonorPetChoice") == 2 and Core.GetResolvedActionMapItem('RedDemon') end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "Thulik",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("DonorPetChoice") == 3 and Core.GetResolvedActionMapItem('Thulik') end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['DPS(MobHighHP)']  = {
            {
                name = "FireDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFireDot') > 1 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "ColdDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoColdDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "CurseDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoCurseDot') > 1 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "PoisonDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoPoisonDot') > 1 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "Artifact of the Dread Pyre",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and mq.TLO.Me.Level() < 70 and mq.TLO.FindItem("=Artifact of the Dread Pyre")() end,
                cond = function(self, itemName, target)
                    return Casting.DotItemCheck(itemName, target)
                end,
            },
            {
                name = "Trinket of Suffocation",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and mq.TLO.FindItem("=Trinket of Suffocation")() end,
                cond = function(self, itemName, target)
                    return Casting.DotItemCheck(itemName, target)
                end,
            },
            {
                name = "PlagueDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoPlagueDot') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "FireDot2",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFireDot') > 2 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "PoisonDot2",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoPoisonDot') > 2 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "CurseDot2",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoCurseDot') > 2 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "DurationTap",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoDurationTap') end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "FireDot3",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoFireDot') > 3 end,
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell, target)
                end,
            },
            {
                name = "DeathDagger",
                type = "Item",
                cond = function(self, itemName, target)
                    return Casting.DotItemCheck(itemName, target)
                end,
            },
            {
                name = "PoisonNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['DPS(MobLowHP)']   = {
            {
                name = "OrbNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoOrbNuke') end,
                cond = function(self, spell, target)
                    local orbItem = spell() and spell.Trigger.Base(1)()
                    return orbItem ~= nil and (mq.TLO.FindItemCount(orbItem)() or 0) < 40
                end,
            },
            {
                name = "UndeadNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoUndeadNuke') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetBodyIs(target, "Undead") then return false end

                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "LifeTap",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLifetap') end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke() and Targeting.LightHealsNeeded(mq.TLO.Me)
                end,
            },
            {
                name = "PoisonNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['Burn']            = {
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold')
                end,
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName) and Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "DeadSwarm",
                type = "AA",
                cond = function(self, aaName, target)
                    return mq.TLO.SpawnCount("corpse radius 100 los")() >= Config:GetSetting('WakeDeadCorpseCnt') and Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Swarm of Decay",
                type = "AA",
            },
            {
                name = "Spire",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold')
                end,
            },
            {
                name = "Silent Casting",
                type = "AA",
            },
            {
                name = "Gathering Dusk",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and Targeting.GetAutoTargetPctHPs() <= Config:GetSetting('BurnHPThreshold') and mq.TLO.Me.PctAggro() <= 25
                end,
            },
            {
                name = "Life Burn",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoLifeBurn') end,
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() <= 25
                end,
            },
        },
        ['PetHealing']      = {
            {
                name = "Companion's Blessing",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name_func = function() return Casting.CanUseAA("Replenish Companion") and "Replenish Companion" or "Mend Companion" end,
                type = "AA",
            },
            {
                name = "PetHealSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPetHealSpell') end,
            },
        },
        ['Downtime']        = {
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfRune",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "LichSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLich') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell) and mq.TLO.Me.PctHPs() > Config:GetSetting('StopLichHP') and mq.TLO.Me.PctMana() <= Config:GetSetting('StartLichMana')
                end,
            },
            {
                name = "LichControl",
                type = "CustomFunc",
                load_cond = function(self) return Config:GetSetting('DoLich') end,
                active_cond = function(self, spell) return true end,
                cond = function(self, _)
                    local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

                    return lichSpell and lichSpell() and Casting.IHaveBuff(lichSpell) and
                        (mq.TLO.Me.PctHPs() <= Config:GetSetting('StopLichHP') or mq.TLO.Me.PctMana() >= Config:GetSetting('StopLichMana'))
                end,
                custom_func = function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.Helpers.CancelLich, self)
                    return true
                end,
            },
            {
                name = "Gift of the Grave",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName, target) return Casting.SelfBuffAACheck(aaName) end,
            },
        },
        ['PetSummon']       = {
            {
                name = "RedDemon",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("DonorPetChoice") == 2 and Core.GetResolvedActionMapItem('RedDemon') end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "Thulik",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("DonorPetChoice") == 3 and Core.GetResolvedActionMapItem('Thulik') end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name_func = function(self)
                    return string.format("%sPetSpell", self.ClassConfig.DefaultConfig.PetType.ComboOptions[Config:GetSetting('PetType')])
                end,
                type = "Spell",
                load_cond = function(self)
                    local settingValue = Config:GetSetting('DonorPetChoice')
                    return settingValue == 1 or (settingValue == 2 and not Core.GetResolvedActionMapItem('RedDemon')) or
                        (settingValue == 3 and not Core.GetResolvedActionMapItem('Thulik'))
                end,
                active_cond = function(self) return mq.TLO.Me.Pet.ID() > 0 end,
                cond = function(self, spell)
                    return Casting.ReagentCheck(spell)
                end,
                post_activate = function(self, spell, success)
                    local pet = mq.TLO.Me.Pet
                    if success and pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff']         = { -- TODO: Examine spectral guard 71
            {
                name = "PetHaste",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "Minionskin",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
        },
        ['GroupBuff']       = { -- Added to anchor clickies to

        },
    },
    ['Helpers']         = {
        CancelLich = function(self)
            -- detspa means detremental spell affect
            -- spa is positive spell affect
            local lichName = mq.TLO.Me.FindBuff("detspa hp and spa mana")()
            Core.DoCmd("/removebuff %s", lichName)
        end,
        StartLich = function(self)
            local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

            if lichSpell and lichSpell() then
                local targetId = mq.TLO.Me.ID()
                self:QueueAbility("spell", lichSpell, targetId)
            end
        end,
        GetScentItem = function(self)
            local scentItems = { "Legendary Fabled Nightshade Scented Staff", "Fabled Nightshade Scented Staff", "Scent of Terris", }
            for _, v in ipairs(scentItems) do
                if mq.TLO.FindItem("=" .. v)() then
                    return v
                end
            end
            return "No Scent Item Found"
        end,
    },
    ['SpellList']       = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "PetHealSpell", cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "CharmSpell",   cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "SnareDot",     cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Encroaching Darkness") end, },
                { name = "ScentDebuff",  cond = function(self) return Config:GetSetting('ScentDebuffUse') == 2 and not self.Helpers.GetScentItem end, },
                { name = "ScentDebuff2", cond = function(self) return Config:GetSetting('ScentDebuffUse') == 3 end, },
                { name = "PoisonNuke", },
                { name = "FireDot",      cond = function(self) return Config:GetSetting('DoFireDot') > 1 end, },
                { name = "ColdDot",      cond = function(self) return Config:GetSetting('DoColdDot') end, },
                { name = "CurseDot",     cond = function(self) return Config:GetSetting('DoCurseDot') > 1 end, },
                { name = "PoisonDot",    cond = function(self) return Config:GetSetting('DoPoisonDot') > 1 end, },
                { name = "FireDot2",     cond = function(self) return Config:GetSetting('DoFireDot') > 2 end, },
                { name = "CurseDot2",    cond = function(self) return Config:GetSetting('DoCurseDot') > 2 end, },
                { name = "PoisonDot2",   cond = function(self) return Config:GetSetting('DoPoisonDot') > 2 end, },
                { name = "FireDot3",     cond = function(self) return Config:GetSetting('DoFireDot') > 3 end, },
                { name = "DurationTap",  cond = function(self) return Config:GetSetting('DoDurationTap') end, },
                { name = "PlagueDot",    cond = function(self) return Config:GetSetting('DoPlagueDot') end, },
                { name = "LichSpell",    cond = function(self) return Config:GetSetting('DoLich') end, },
                { name = "OrbNuke",      cond = function(self) return Config:GetSetting('DoOrbNuke') end, },
                { name = "LifeTap",      cond = function(self) return Config:GetSetting('DoLifetap') end, },
                { name = "UndeadNuke",   cond = function(self) return Config:GetSetting('DoUndeadNuke') end, },
            },
        },
    },
    ['DefaultConfig']   = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different Modes Do?",
            Answer = "Currently Necros only have one mode, which is DPS. This mode will focus on DPS and some utility.",
        },

        --Pet
        ['PetType']           = {
            DisplayName = "Pet Class",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 101,
            Tooltip = "Choose which pet you wish to summon. Please note that rogue pets have uneven spacing at lower levels.",
            Type = "Combo",
            ComboOptions = { 'War', 'Rog', },
            Default = function() return Core.GetResolvedActionMapItem('RogPetSpell') and 2 or 1 end,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
        },
        ['DonorPetChoice']    = {
            DisplayName = "Donor Pet Choice",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 102,
            Tooltip = "Select the donor pet to use instead of the normal pet (if any).",
            Type = "Combo",
            ComboOptions = { 'Disabled', 'Red Demon', 'Thulik', },
            Default = 1,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoPetHealSpell']    = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Pet Heal (Salve) spell. AA Pet Heals are always used in emergencies.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['PetHealPct']        = {
            DisplayName = "Pet Heal Spell HP%",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Tooltip = "Use your pet heal spell when your pet is at or below this HP percentage.",
            Default = 60,
            Min = 1,
            Max = 99,
        },

        --Debuffs
        ['ScentDebuffUse']    = {
            DisplayName = "Scent Debuff:",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip =
                "Choose which scent resist debuff to use, if any.\n" ..
                "Terris denotes the standard scent debuffs, up to and including Scent of Terris (and the AA version).\n" ..
                "Midnight denotes the level 70 Scent of Midnight, which uses different slots and has different stacking.",
            Type = "Combo",
            ComboOptions = { 'Disabled', 'Terris', 'Midnight', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
            ConfigType = "Advanced",
            FAQ = "Why is Scent of Midnight a separate option from Scent of Terris?",
            Answer = "Scent of Midnight has been customized on Laz to use different slots, but also stack with other resist debuffs.",
        },
        ['DoSnare']           = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']        = {
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

        --Combat
        ['DoFireDot']         = {
            DisplayName = "Do Fire DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Select the number of fire dots to use. Third tier not used until it resolves to Funeral Pyre or better.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { "Disabled", "Current Tier", "Current + Last Tier", "Three Tiers", },
            Default = 4,
            Min = 1,
            Max = 4,
        },
        ['DoPoisonDot']       = {
            DisplayName = "Do Poison DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Select the number of poison dots to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { "Disabled", "Current Tier", "Current + Last Tier", },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['DoCurseDot']        = {
            DisplayName = "Do Curse DoTs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Select the number of Curse (Magic) dots to use.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { "Disabled", "Current Tier", "Current + Last Tier", },
            Default = 3,
            Min = 1,
            Max = 3,
        },
        ['DoDurationTap']     = {
            DisplayName = "Do Duration Tap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Use your duration tap line of dots.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoPlagueDot']       = {
            DisplayName = "Do Plague Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Use your plague (disease) line of dots.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoColdDot']         = {
            DisplayName = "Do Cold Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 105,
            Tooltip = "Use your grave (cold) line of dots.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoLifetap']         = {
            DisplayName = "Do Lifetap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Taps",
            Index = 101,
            Tooltip = "Use the your ST Lifetap nuke line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoUndeadNuke']      = {
            DisplayName = "Do Undead Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use the Undead nuke line.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['WakeDeadCorpseCnt'] = {
            DisplayName = "WtD Corpse Count",
            Group = "Abilities",
            Header = "Pet",
            Category = "Swarm Pets",
            Index = 101,
            Tooltip = "Number of Corpses before we cast Wake the Dead",
            Default = 5,
            Min = 1,
            Max = 20,
            ConfigType = "Advanced",
        },
        ['DoLifeBurn']        = {
            DisplayName = "Use Life Burn",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use Life Burn AA if your aggro is below 25%.",
            RequiresLoadoutChange = true,
            Default = false,
            ConfigType = "Advanced",
        },
        ['UseEpic']           = {
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
        ['EmergencyStart']    = {
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
        ['AggroFeign']        = {
            DisplayName = "Emergency Feign",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            Tooltip = "Use your Feign AA when you have aggro at low health or aggro on a mob detected as a 'named' by RGMercs (see Spawns tab)..",
            Default = true,
        },

        --Utility
        ['DoLich']            = {
            DisplayName = "Cast Lich",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Enable casting Lich spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['StopLichHP']        = {
            DisplayName = "Stop Lich HP",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Cancel your Lich spell once your health has dropped to this percentage.",
            RequiresLoadoutChange = false,
            Default = 25,
            Min = 1,
            Max = 99,
        },
        ['StartLichMana']     = {
            DisplayName = "Start Lich Mana",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 103,
            Tooltip = "Use your Lich spell when your mana has dropped to this percentage.",
            RequiresLoadoutChange = false,
            Default = 70,
            Min = 1,
            Max = 100,
        },
        ['StopLichMana']      = {
            DisplayName = "Stop Lich Mana",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 104,
            Tooltip = "Cancel your Lich spell when your mana has increased to this percentage. (Selecting 101 will disable canceling lich based on mana percent.)",
            RequiresLoadoutChange = false,
            Default = 100,
            Min = 1,
            Max = 101,
        },
        ['DoOrbNuke']         = {
            DisplayName = "Summon Orbs",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use your Orb nuke to summon more Soul/Shadow orbs when needed.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['BurnHPThreshold']   = {
            DisplayName = "Burn HP Threshold",
            Group = "Combat",
            Header = "Burning",
            Category = "Burning",
            Index = 101,
            Tooltip =
            "Burn abilities that are best used once dots have been applied will be held until a named has reached this HP value. (Affected abilities: Spire, Gathering Dusk, OoW Robe)",
            Default = 70,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']        = {
        {
            Question = "What is the current status of this class config?",
            Answer = "This class config is currently a Work-In-Progress that was originally based off of the Project Lazarus config.\n\n" ..
                "  Up until level 71, it should work quite well, but may need some clickies managed on the clickies tab.\n\n" ..
                "  After level 68, however, there hasn't been any playtesting... some AA may need to be added or removed still, and some Laz-specific entries may remain.\n\n" ..
                "  Community effort and feedback are required for robust, resilient class configs, and PRs are highly encouraged!",
            Settings_Used = "",
        },
    },
}

return _ClassConfig
