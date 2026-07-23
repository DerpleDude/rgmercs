local mq              = require('mq')
local Casting         = require("utils.casting")
local Comms           = require("utils.comms")
local Config          = require('utils.config')
local Core            = require("utils.core")
local Globals         = require('utils.globals')
local ItemManager     = require("utils.item_manager")
local Logger          = require("utils.logger")
local Targeting       = require("utils.targeting")

-- Provide a valid aura name to check as they are named differently then the spells
-- -- Only use the first word(s) of the aura name, they are all unique (enough)
local auraSpellToName = {
    ["Beguiler's Aura"] = "Beguiler",
    ["Illusionist's Aura"] = "Illusionist",
    ["Entrancer's Aura"] = "Entrancer",
}

local _ClassConfig    = {
    _version          = "1.6 - EQ Might",
    _author           = "Derple, Grimmier, Algar, Robban",
    ['ModeChecks']    = {
        CanMez    = function() return true end,
        CanCharm  = function() return true end,
        IsMezzing = function() return Config:GetSetting('MezOn') end,
        IsRezing  = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Rez']           = {
        ['Combat']   = {
            { type = "Item", name = "RezStaff", },
        },
        ['Downtime'] = {
            { type = "Item", name = "RezStaff", },
        },
    },
    ['Modes']         = {
        'Default',
    },
    ['PetPosition']   = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
    },
    ['Themes']        = {
        ['Default'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.02, g = 0.17, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.02, g = 0.17, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.05, g = 0.45, b = 0.50, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.03, g = 0.28, b = 0.32, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.05, g = 0.45, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.05, g = 0.45, b = 0.50, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.02, g = 0.17, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.10, g = 0.90, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.10, g = 0.90, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.05, g = 0.45, b = 0.50, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Staff of Eternal Eloquence",
            "Oculus of Persuasion",
        },
        ['OoW_Chest'] = {
            "Mindreaver's Vest of Coercion",
            "Charmweaver's Robe",
        },
        ['Asterion'] = {
            "Artifact of Greater Asterion",
            "Artifact of Asterion",
            "Lesser Artifact of Asterion",
        },
        ['TashRod'] = {
            "Legendary Rod of Tashan",
            "Rod of Tashan",
        },
    },
    ['AbilitySets']   = {
        --Commented any currently unused spell lines
        ['TwincastAura'] = {
            "Entrancer's Aura", -- Level 71
        },
        ['SpellProcAura'] = {
            "Illusionist's Aura", -- Level 66
            "Beguiler's Aura",    -- Level 55
        },
        ['HasteBuff'] = {
            "Speed of Ellowind",   -- Level 71
            "Hastening of Salik",  -- Level 70
            "Speed of Salik",      -- Level 67
            "Vallon's Quickening", -- Level 65
            -- "Speed of Vallon",
            "Speed of the Brood",  -- Level 60
            "Visions of Grandeur", -- Level 60
            "Wondrous Rapidity",   -- Level 58
            "Aanya's Quickening",  -- Level 53
            "Swift Like the Wind", -- Level 47
            "Celerity",            -- Level 39
            "Alacrity",            -- Level 21
            "Quickness",           -- Level 15
        },
        ['ManaRegen'] = {
            -- "Seer's Intuition",               -- Level 71, not worth the hassle over the group item click
            "Ancient: Blessing of Clairvoyance", -- Level 70 EQM Custom
            "Voice of Clairvoyance",             -- Level 70
            "Clairvoyance",                      -- Level 68
            "Voice of Quellious",                -- Level 65
            "Tranquility",                       -- Level 63
            "Koadic's Endless Intellect",        -- Level 60
            "Gift of Pure Thought",              -- Level 56
            "Clarity II",                        -- Level 52
            "Boon of the Clear Mind",            -- Level 42
            "Clarity",                           -- Level 26
            "Breeze",                            -- Level 14
        },
        ['MezBuff'] = {
            "Ward of Bedazzlement", -- Level 70
        },
        ['TankIllusionBuff'] = {
            "Boon of the Brute", -- Level 66 EQM Custom
        },
        ['IllusionBuff'] = {
            "Boon of the Sanguinarch", -- Level 68 EQM Custom
            "Boon of the Vampire",     -- Level 65 EQM Custom
            "Night's Dark Terror",     -- Level 63
            "Boon of the Garou",       -- Level 40
        },
        ['SelfHPBuff'] = {
            "Sorcerous Shield",     -- Level 70
            "Mystic Shield",        -- Level 66
            "Shield of Maelin",     -- Level 64
            "Shield of the Arcane", -- Level 61
            "Shield of the Magi",   -- Level 54
            "Arch Shielding",       -- Level 40
            "Greater Shielding",    -- Level 31
            "Major Shielding",      -- Level 23
            "Shielding",            -- Level 16
            "Lesser Shielding",     -- Level 6
            "Minor Shielding",      -- Level 1
        },
        ['SelfRune1'] = {
            "Draconic Rune", -- Level 70
            "Ethereal Rune", -- Level 66
            "Arcane Rune",   -- Level 61
        },
        ['SingleRune'] = {
            "Rune of Ellowind",  -- Level 70
            "Rune of Salik",     -- Level 67
            "Rune of Zebuxoruk", -- Level 61
            "Rune V",            -- Level 52
            "Rune IV",           -- Level 40
            "Rune III",          -- Level 33
            "Rune II",           -- Level 22
            "Rune I",            -- Level 13
        },
        ['GroupRune'] = {
            "Rune of Rikkukin",  -- Level 69
            "Rune of the Scale", -- Level 61
        },
        ['HateBuff'] = {
            "Horrifying Visage", -- Level 56
            "Haunting Visage",   -- Level 26
        },
        -- ['SingleSpellShield'] = {
        --     "Aegis of Alendar",      -- Level 71
        --     "Wall of Alendar",       -- Level 68
        --     "Bulwark of Alendar",    -- Level 63
        --     "Protection of Alendar", -- Level 55
        --     "Guard of Alendar",      -- Level 44
        --     "Ward of Alendar",       -- Level 29
        -- },
        ['GroupSpellShield'] = {
            "Circle of Alendar", -- Level 70
        },
        ['SpellProcBuff'] = {
            "Mana Recursion", -- Level 71
            "Mana Flare",     -- Level 69
        },
        ['PBAEStunSpell'] = {
            "Color Snap",  -- Level 69
            "Color Cloud", -- Level 63
            "Color Slant", -- Level 52
            "Color Skew",  -- Level 43
            "Color Shift", -- Level 20
            "Color Flux",  -- Level 3
        },
        ['SpinStunSpell'] = {
            "Whirl Till You Hurl", -- Level 9
        },
        ['CharmSpell'] = {
            "Coax",               -- Level 71
            "True Name",          -- Level 70
            "Compel",             -- Level 68
            "Command of Druzzil", -- Level 64
            "Beckon",             -- Level 62
            "Boltran's Agacerie", -- Level 53
            "Allure",             -- Level 46
            "Cajoling Whispers",  -- Level 37
            "Beguile",            -- Level 23
            "Charm",              -- Level 11
        },
        ['CrippleSpell'] = {
            "Fractured Consciousness", -- Level 70
            "Synapsis Spasm",          -- Level 66
            "Cripple",                 -- Level 53
            "Incapacitate",            -- Level 40
            "Listless Power",          -- Level 25
            "Disempower",              -- Level 16
            "Enfeeblement",            -- Level 4
        },
        ['SlowSpell'] = {
            "Desolate Deeds",  -- Level 69
            "Dreary Deeds",    -- Level 65
            "Forlorn Deeds",   -- Level 57
            "Shiftless Deeds", -- Level 41
            "Tepid Deeds",     -- Level 23
            "Languid Pace",    -- Level 9
        },
        ['Dispel'] = {
            "Recant Magic",        -- Level 53
            "Pillage Enchantment", -- Level 42
            "Nullify Magic",       -- Level 28
            "Strip Enchantment",   -- Level 22
            "Cancel Magic",        -- Level 7
            "Taper Enchantment",   -- Level 1
        },
        ['TashSpell'] = {
            "Echo of Tashan", -- Level 71
            "Howl of Tashan", -- Level 61
            "Tashanian",      -- Level 57
            "Tashania",       -- Level 41
            "Tashani",        -- Level 18
            "Tashina",        -- Level 2
        },
        -- ['ManaDrainNuke'] = {
        --     "Torment of Scio",     -- Level 63
        --     "Torment of Argli",    -- Level 56
        --     "Scryer's Trespass",   -- Level 52
        --     "Wandering Mind",      -- Level 38
        --     "Mana Sieve",          -- Level 30
        -- },
        ['StrangleDot'] = {
            "Thin Air",           -- Level 71
            "Arcane Noose",       -- Level 68
            "Strangle",           -- Level 62
            "Asphyxiate",         -- Level 59
            "Gasping Embrace",    -- Level 47
            "Suffocate",          -- Level 26
            "Choke",              -- Level 11
            "Suffocating Sphere", -- Level 4
            "Shallow Breath",     -- Level 1
        },
        ['MindDot'] = {
            "Mind Shatter", -- Level 70
        },
        ['MindstingDot'] = {
            "Mindsting Swarm", -- Level 66 EQM Custom
        },
        ['Avatar'] = {
            "Phantasmal Might", -- Level 70 EQM Custom
            "Phantasmal Power", -- Level 66 EQM Custom
            "Phantasmal Surge", -- Level 62 EQM Custom
            "Phantasmal Touch", -- Level 55 EQM Custom
        },
        ['MagicNuke'] = {
            "Polychromatic Assault",    -- Level 71
            "Ancient: Neurosis",        -- Level 68
            "Psychosis",                -- Level 68
            "Ancient: Chaos Madness",   -- Level 65
            "Madness of Ikkibi",        -- Level 65
            "Insanity",                 -- Level 64
            "Ancient: Chaotic Visions", -- Level 60
            "Dementing Visions",        -- Level 58
            "Dementia",                 -- Level 54
            "Discordant Mind",          -- Level 43
            "Anarchy",                  -- Level 32
            "Chaos Flux",               -- Level 21
            "Sanity Warp",              -- Level 16
            "Chaotic Feedback",         -- Level 7
        },
        ['PetSpell'] = {                -- Might Specific: Monster Summoning avail on ENC and superior to normal pets
            "Monster Summoning V",      -- Level 70
            "Monster Summoning IV",     -- Level 66
            -- "Salik's Animation",     -- Level 66
            "Monster Summoning III",    -- Level 61
            -- "Aeldorb's Animation",   -- Level 62
            -- "Zumaik's Animation",    -- Level 55
            "Monster Summoning II", -- Level 52
            -- "Kintaz's Animation",    -- Level 48
            -- "Yegoreff's Animation",  -- Level 41
            -- "Aanya's Animation",     -- Level 37
            "Monster Summoning I", -- Level 32
            "Boltran's Animation", -- Level 31
            "Uleen's Animation",   -- Level 29
            "Sagar's Animation",   -- Level 22
            "Sisna's Animation",   -- Level 17
            "Shalee's Animation",  -- Level 14
            "Kilan's Animation",   -- Level 9
            "Mircyl's Animation",  -- Level 7
            "Juli's Animation",    -- Level 2
            "Pendril's Animation", -- Level 1
        },
        ['MezAESpell'] = {
            "Wake of Felicity",   -- Level 69
            "Bliss of the Nihil", -- Level 65
            "Fascination",        -- Level 52
            "Mesmerization",      -- Level 16
        },
        -- ['MezPBAESpell'] = {
        --     "Dreams of Veldyn",  -- Level 71
        --     "Circle of Dreams",  -- Level 68
        --     "Word of Morell",    -- Level 62
        --     "Entrancing Lights", -- Level 30
        -- },
        ['MezSpell'] = {
            "Bewilderment",             -- Level 71
            "Perplexing Flash",         -- Level 70
            "Euphoria",                 -- Level 69
            "Echoing Madness",          -- Level 68
            "Felicity",                 -- Level 67
            "Bliss",                    -- Level 64
            "Sleep",                    -- Level 63
            "Apathy",                   -- Level 61
            "Ancient: Eternal Rapture", -- Level 60
            "Rapture",                  -- Level 59
            "Glamour of Kintaz",        -- Level 54
            "Enthrall",                 -- Level 13
            "Mesmerize",                -- Level 2
        },
        -- ['MezSpellFast'] = {
        --     "Perplexing Flash",  -- Level 70
        -- },
        -- ['BlurSpell'] = {
        --     "Memory Flux",          -- Level 55
        --     "Reoccurring Amnesia",  -- Level 45
        --     "Memory Blur",          -- Level 10
        -- },
        -- ['AEBlurSpell'] = {
        --     "Blanket of Forgetfulness",  -- Level 46
        --     "Mind Wipe",                 -- Level 36
        -- },
        -- ['CalmSpell'] = {
        --     "Quiet Mind",     -- Level 70
        --     "Placate",        -- Level 67
        --     "Pacification",   -- Level 62
        --     "Pacify",         -- Level 35
        --     "Calm",           -- Level 18
        --     "Soothe",         -- Level 6
        --     "Lull",           -- Level 1
        -- },
        -- ['FearSpell'] = {
        --     "Anxiety Attack",  -- Level 67
        --     "Jitterskin",      -- Level 62
        --     "Phobia",          -- Level 57
        --     "Trepidation",     -- Level 56
        --     "Invoke Fear",     -- Level 35
        --     "Chase the Moon",  -- Level 16
        --     "Fear",            -- Level 3
        -- },
        -- ['RootSpell'] = {
        --     "Greater Fetter",    -- Level 61
        --     "Fetter",            -- Level 58
        --     "Paralyzing Earth",  -- Level 45
        --     "Immobilize",        -- Level 39
        --     "Instill",           -- Level 25
        --     "Root",              -- Level 6
        -- },
        -- ['ColoredNuke'] = {
        --     "Colored Chaos",  -- Level 69
        -- },
        ['Minionskin'] = {        --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",   -- Level 66 EQM Custom
            "Greater Minionskin", -- Level 56 EQM Custom
            "Minionskin",         -- Level 43 EQM Custom
            "Lesser Minionskin",  -- Level 30 EQM Custom
        },
        ['KoadicRune'] = {
            "Koadic's Guard IV",  -- Level 67 EQM Custom
            "Koadic's Guard III", -- Level 62 EQM Custom
            "Koadic's Guard II",  -- Level 55 EQM Custom
            "Koadic's Guard I",   -- Level 43 EQM Custom
        },
        ['PetHealSpell'] = {
            "Renewal of Lucifer", -- Level 68 EQM Custom
        },
        ['ColdDot'] = {
            "Chillgrave", -- Level 69 EQM Custom
            "Frostgrave", -- Level 63 EQ Custom
        },
    },
    ['AASets']        = {
        ['Spire'] = {
            "Fundament: Second Spire of Enchantment",
        },
        ['ManaRestore'] = {
            "Mana Draw",
            "Gather Mana",
        },
    },
    ['Mez']           = {
        { type = "AA",    name = "Nightmare Stasis", cond = function() return Globals.AutoTargetIsNamed end, },
        { type = "AA",    name = "Stasis",           cond = function() return Globals.AutoTargetIsNamed end, },
        { type = "Spell", name = "MezSpell", },
        { type = "Spell", name = "MezAESpell", },
    },
    ['Charm']         = {
        ['Abilities'] = {
            { name = "Dire Charm", type = "AA", },
            { name = "CharmSpell", type = "Spell", },
        },
        ['PreCharm']  = {
            {
                name = "TashRod",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoTash') and self.Helpers.PreferTashItem(self) end,
                cond = function(self, itemName, target)
                    return not
                        target.Tashed()
                end,
            },
            {
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTash') and not self.Helpers.PreferTashItem(self) end,
                cond = function(self, spell, target)
                    return not target
                        .Tashed()
                end,
            },
        },
        ['Assist']    = {
            {
                name = "SpinStunSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSpinStun') > 1 end,
                cond = function(self, spell, target) return Targeting.TargetNotStunned() end,
            },
            {
                name = "PBAEStunSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoAEStun') > 1 end,
                cond = function(self, spell, target) return Targeting.TargetNotStunned() and Targeting.InSpellRange(spell, target) end,
            },
            {
                name = "TashRod",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoTash') and self.Helpers.PreferTashItem(self) end,
                cond = function(
                    self, itemName, target)
                    return Casting.DetItemCheck(itemName, target)
                end,
            },
            {
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTash') and not self.Helpers.PreferTashItem(self) end,
                cond = function(
                    self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
    },
    ['RotationOrder'] = {
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and not Core.IsCharming() and Casting.AmIBuffable()
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
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
            end,
        },
        { --Slow and Tash separated so we use both before we start DPS
            name = 'Tash',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoTash') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        { --Slow and Tash separated so we use both before we start DPS
            name = 'Slow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSlow') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Cripple',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoCripple') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Dispel',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoDispel') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff() and Core.CombatActionsCheck()
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
        { --AA Stuns, Runes, etc, moved from previous home in DPS
            name = 'CombatSupport',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },

        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.CombatActionsCheck()
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
    },
    ['Helpers']       = { --used to autoinventory our crystals after summon. Crystal is a group-wide spell on Laz.
        -- Rod clicks Echo of Tashan Rk. I; the spell casts faster
        PreferTashItem = function(self)
            if not Core.GetResolvedActionMapItem('TashRod') then return false end
            local tashSpell = self.ResolvedActionMap['TashSpell']
            return not (tashSpell and tashSpell() and tashSpell.Name() == "Echo of Tashan")
        end,
        ManaBuffChoice = function()
            if mq.TLO.Me.Level() >= 69 and mq.TLO.FindItem("=Legendary Timeless Belt of the Wise")() then
                return "BeltItem"
            elseif mq.TLO.Me.Level() >= 68 and mq.TLO.FindItem("=Ancient Artifact of Clairvoyance")() then
                return "ArtifactItem"
            end
            return "ManaSpell"
        end,
        StashCrystal = function(aaName)
            mq.delay("2s", function() return mq.TLO.Cursor.ID() == mq.TLO.Me.AltAbility(aaName).Spell.Base(1)() end)

            if not mq.TLO.Cursor() then
                Logger.log_debug("No valid item found on cursor, item handling aborted.")
                return false
            end

            Logger.log_debug("Sending the %s to our bags.", mq.TLO.Cursor())
            ItemManager.QueueAutoInv(mq.TLO.Cursor.ID())
        end,
        AuraActive = function(name)
            if not name then return false end
            local stripName = string.gsub(name, "'", "")
            for i = 1, 3 do
                local slot = mq.TLO.Me.Aura(i)() or ""
                if string.find(slot, name) or string.find(slot, stripName) then return true end
            end
            return false
        end,
        AuraCheck = function(self)
            local twincast = self.ResolvedActionMap['TwincastAura']
            local spellproc = self.ResolvedActionMap['SpellProcAura']
            local currentTwincast = (twincast and twincast() and auraSpellToName[twincast.Name()]) or nil
            local currentSpellProc = (spellproc and spellproc() and auraSpellToName[spellproc.Name()]) or nil
            for i = 1, 3 do
                local slot = mq.TLO.Me.Aura(i)() or ""
                for _, searchKey in pairs(auraSpellToName) do
                    if searchKey ~= currentTwincast and searchKey ~= currentSpellProc and string.find(slot, searchKey) then
                        mq.TLO.Me.Aura(i).Remove()
                        break
                    end
                end
            end
            local rank = Casting.AARank('Auroria Mastery')
            if rank == 0 then
                mq.TLO.Me.Aura(1).Remove()
                return
            end
            if rank == 1 and currentTwincast and currentSpellProc then
                for i = 1, 2 do
                    local slot = mq.TLO.Me.Aura(i)() or ""
                    if slot ~= "" and not (string.find(slot, currentTwincast) or string.find(slot, currentSpellProc)) then
                        mq.TLO.Me.Aura(i).Remove()
                    end
                end
            end
        end,
    },
    ['Rotations']     = {
        ['Downtime']      = {
            {
                name = "Eldritch Rune",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(aaName) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "SelfRune1",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Eldritch Rune") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end, --Laz stacking fix
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) and not Casting.IHaveBuff("Talisman of Wunshi") end,
            },
            {
                name = "MezBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            { -- Mana Restore AA, will use the first(best) available
                name = "ManaRestore",
                type = "AA",
                cond = function(self, aaName) return mq.TLO.Me.PctMana() < 30 end,
            },
            {
                name = "TwincastAura",
                type = "Spell",
                load_cond = function(self) return Casting.CanUseAA('Auroria Mastery') end,
                active_cond = function(self, spell) return self.Helpers.AuraActive(auraSpellToName[spell.Name()]) end,
                pre_activate = function(self) self.Helpers.AuraCheck(self) end,
                cond = function(self, spell) return not self.Helpers.AuraActive(auraSpellToName[spell.Name()]) end,
            },
            {
                name = "SpellProcAura",
                type = "Spell",
                active_cond = function(self, spell) return self.Helpers.AuraActive(auraSpellToName[spell.Name()]) end,
                pre_activate = function(self) self.Helpers.AuraCheck(self) end,
                cond = function(self, spell) return not self.Helpers.AuraActive(auraSpellToName[spell.Name()]) end,
            },
            {
                name = "Azure Mind Crystal",
                type = "AA",
                load_cond = function() return Config:GetSetting('SummonAzure') end,
                cond = function(self, aaName, target)
                    local crystalAA = mq.TLO.Me.AltAbility(aaName)
                    if not crystalAA and crystalAA() then return false end
                    local crystal = crystalAA.Spell.Base(1)()
                    return not mq.TLO.FindItem(string.format("id %s", crystal))()
                end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.StashCrystal(aaName))
                    end
                end,
            },
            {
                name = "Sanguine Mind Crystal",
                type = "AA",
                load_cond = function() return Config:GetSetting('SummonSanguine') end,
                cond = function(self, aaName, target)
                    local crystalAA = mq.TLO.Me.AltAbility(aaName)
                    if not crystalAA and crystalAA() then return false end
                    local crystal = crystalAA.Spell.Base(1)()
                    return not mq.TLO.FindItem(string.format("id %s", crystal))()
                end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.StashCrystal(aaName))
                    end
                end,
            },
        },
        ['PetSummon']     = {
            {
                name = "Asterion",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and Core.GetResolvedActionMapItem('Asterion') end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "PetSpell",
                type = "Spell",
                load_cond = function(self) return not Config:GetSetting("UseDonorPet") or not Core.GetResolvedActionMapItem('Asterion') end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff']       = {
            {
                name = "HasteBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.ID()).ID() end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell) and Casting.LocalBuffCheck(5521, true) -- Don't cast if we have Hastening of Salik
                end,
            },
            {
                name = "Fortify Companion",
                type = "AA",
                active_cond = function(self, aaName) return mq.TLO.Me.PetBuff(aaName)() ~= nil end,
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Minionskin",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
        },
        ['GroupBuff']     = {
            {
                name = "Legendary Timeless Belt of the Wise",
                type = "Item",
                load_cond = function(self) return self.Helpers.ManaBuffChoice() == "BeltItem" end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "Ancient Artifact of Clairvoyance",
                type = "Item",
                load_cond = function(self) return self.Helpers.ManaBuffChoice() == "ArtifactItem" end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "ManaRegen",
                type = "Spell",
                load_cond = function(self) return self.Helpers.ManaBuffChoice() == "ManaSpell" end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Salik",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 67 and mq.TLO.FindItem("=Artifact of Salik")() end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function() return mq.TLO.Me.Level() < 67 or not mq.TLO.FindItem("=Artifact of Salik")() end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsAMelee(target) then return false end
                    -- Don't cast if we have Hastening of Salik
                    return Casting.GroupBuffCheck(spell, target) and Casting.AddedBuffCheck(5521, target)
                end,
            },
            {
                name = "Avatar",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoAvatar') end,
                cond = function(self, spell, target)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HateBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoHateBuff') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupSpellShield",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoGroupSpellShield') end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "TankIllusionBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoTankIllusionBuff') end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.CastReady(spell) and
                        Casting.GroupBuffCheck(spell, target, false, true) -- skip trigger checks, we are not worried about spells with a seperate illusion trigger
                end,
            },
            {
                name = "IllusionBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoIllusionBuff') end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DoTankIllusionBuff') and Targeting.TargetIsTanking(target) and Core.GetResolvedActionMapItem('TankIllusionBuff') then return false end
                    return Casting.CastReady(spell) and
                        Casting.GroupBuffCheck(spell, target, false, true) -- skip trigger checks, we are not worried about spells with a seperate illusion trigger
                end,
            },
            {
                name = "Artifact of Mana Strike",
                type = "Item",
                load_cond = function() return Config:GetSetting('DoProcBuff') and mq.TLO.FindItem("=Artifact of Mana Strike")() end,
                cond = function(self, itemName, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "SpellProcBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoProcBuff') and not mq.TLO.FindItem("=Artifact of Mana Strike")() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "KoadicRune",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRune",
                type = "Spell",
                load_cond = function() return Config:GetSetting('RuneChoice') == 2 end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            -- {
            --     name = "AggroRune",
            --     type = "Spell",
            --     active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
            --     cond = function(self, spell, target)
            --         if not Config:GetSetting('DoAggroRune') or not Targeting.TargetIsTanking(target) then return false end
            --         return Casting.GroupBuffCheck(spell, target)
            --     end,
            -- },
            {
                name = "SingleRune",
                type = "Spell",
                load_cond = function() return Config:GetSetting('RuneChoice') == 1 end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['CombatSupport'] = {
            {
                name = "Spire",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.GroupLowManaCount(30) > 1
                end,
            },
            {
                name = "Glyph Spray",
                type = "AA",
            },
            {
                name = "SpinStunSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoSpinStun') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DoSpinStun') == 2 and (mq.TLO.Group.Injured(Config:GetSetting('EmergencyStart'))() or 0) < 1 then return false end
                    return Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "PBAEStunSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoAEStun') > 1 end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DoAEStun') == 2 and (mq.TLO.Group.Injured(Config:GetSetting('EmergencyStart'))() or 0) < 1 then return false end
                    return Targeting.GetXTHaterCount() >= Config:GetSetting("AECount")
                end,
            },
            {
                name = "Soothing Words",
                type = "AA",
                load_cond = function() return Config:GetSetting("DoSoothing") end,
                cond = function(self, aaName, target)
                    local tankId = mq.TLO.Group.MainTank.ID() or 0
                    return Globals.AutoTargetIsNamed and (mq.TLO.Me.TargetOfTarget.ID() or tankId) ~= tankId
                end,
            },
            {
                name = "Artifact of Asterion",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Asterion")() end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetHealing']    = {
            {
                name = "Companion's Blessing",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name = "PetHealSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoPetHealSpell') end,
            },
        },
        ['Emergency']     = {
            {
                name = "Self Stasis",
                type = "AA",
                cond = function(self, aaName)
                    if Config:GetSetting('CharmOn') and mq.TLO.Me.Pet.ID() > 0 then return false end
                    return mq.TLO.Me.TargetOfTarget.ID() == mq.TLO.Me.ID() and mq.TLO.Target.ID() == Globals.AutoTargetID
                end,
                post_activate = function(self, aaName, success)
                    if not success then return end
                    mq.delay(1000, function() return mq.TLO.Me.Buff("Self Stasis")() ~= nil end)
                    if mq.TLO.Me.Buff("Self Stasis")() then
                        Comms.PrintGroupMessage("We're out of combat, removing the Self Stasis buff so we can act again.")
                        Core.DoCmd('/removebuff =Self Stasis')
                    end
                end,
            },
            {
                name = "Veil of Mindshadow",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Beguiler's Directed Banishment",
                type = "AA",
                load_cond = function() return Config:GetSetting("DoBeguilers") end,
                cond = function(self, aaName, target)
                    if target.ID() == Globals.AutoTargetID then return false end
                    return Targeting.IHaveAggro(100) and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Beguiler's Banishment",
                type = "AA",
                load_cond = function() return Config:GetSetting("DoBeguilers") end,
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100) and mq.TLO.SpawnCount("npc radius 20")() > 2
                end,
            },

            {
                name = "Doppelganger",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Color Shock",
                type = "AA",
            },
            {
                name = "Arcane Whisper",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "Eldritch Rune",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Dispel']        = {
            {
                name = "Dispel",
                type = "Spell",
                cond = function(self, spell, target)
                    if mq.TLO.Target.ID() == 0 then return false end
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['DPS']           = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck())) and Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "ColdDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoColdDot") end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Trinket of Suffocation",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and mq.TLO.FindItem("=Trinket of Suffocation")() end,
                cond = function(self, itemName, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotItemCheck(itemName, target)
                end,
            },
            {
                name = "StrangleDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoStrangleDot") end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "MindstingDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoMindstingDot") end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "MindDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoMindDot") end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "MagicNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoNuke") end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['Burn']          = {
            {
                name = "Illusions of Grandeur",
                type = "AA",
            },
            {
                name = "Improved Twincast",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Calculated Insanity",
                type = "AA",
            },
            {
                name = "Mental Contortion",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Chromatic Haze",
                type = "AA",
            },
            -- { --Temporarily commented out due to high prevalance of xtarget bugs with this pet. will revisit.
            --     name = "Phantasmal Opponent",
            --     type = "AA",
            -- },
            {
                name = "Tarnished Skeleton Key",
                type = "Item",
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
            {
                name = "Silent Casting",
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
        },
        ['Tash']          = {
            {
                name = "Bite of Tashani",
                type = "AA",
                cond = function(self, aaName)
                    if Targeting.GetXTHaterCount() < Config:GetSetting('AECount') then return false end
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "TashRod",
                type = "Item",
                load_cond = function(self) return self.Helpers.PreferTashItem(self) end,
                cond = function(self, itemName, target)
                    return Casting.DetItemCheck(itemName, target) and (not Casting.TargetHasBuff("Bite of Tashani") or Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return not self.Helpers.PreferTashItem(self) end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (not Casting.TargetHasBuff("Bite of Tashani") or Globals.AutoTargetIsNamed)
                end,
            },
        },
        ['Cripple']       = {
            {
                name = "CrippleSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow']          = {
            {
                name = "Enveloping Helix",
                type = "AA",
                cond = function(self, aaName, target)
                    if Targeting.GetXTHaterCount() < Config:GetSetting('AECount') then return false end
                    return Casting.DetAACheck(aaName) and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "Dreary Deeds",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Dreary Deeds") end,
                cond = function(self, aaName, target)
                    local aaSpell = Casting.GetAASpell(aaName)
                    return Casting.DetAACheck(aaName) and (aaSpell.SlowPct() or 0) > Targeting.GetTargetSlowedPct() and not Casting.SlowImmuneTarget(target)
                end,
            },
            {
                name = "SlowSpell",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Dreary Deeds") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (spell.RankName.SlowPct() or 0) > (Targeting.GetTargetSlowedPct()) and not Casting.SlowImmuneTarget(target)
                end,
            },
        },
    },
    ['SpellList']     = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "MezSpell",         cond = function(self) return Config:GetSetting('DoSTMez') end, },
                { name = "MezAESpell",       cond = function(self) return Config:GetSetting('DoAEMez') end, },
                { name = "CharmSpell",       cond = function(self, spell) return Config:GetSetting('CharmOn') and Core.IsSelectedCharmSpell(spell) end, },
                { name = "TashSpell",        cond = function(self) return Config:GetSetting('DoTash') and not self.Helpers.PreferTashItem(self) end, },
                { name = "SlowSpell",        cond = function(self) return Config:GetSetting('DoSlow') and not Casting.CanUseAA("Dreary Deeds") end, },
                { name = "CrippleSpell",     cond = function(self) return Config:GetSetting('DoCripple') end, },
                { name = "SpinStunSpell",    cond = function(self) return Config:GetSetting('DoSpinStun') > 1 end, },
                { name = "PBAEStunSpell",    cond = function(self) return Config:GetSetting('DoAEStun') > 1 end, },
                { name = "IllusionBuff",     cond = function(self) return Config:GetSetting('DoIllusionBuff') end, },
                { name = "TankIllusionBuff", cond = function(self) return Config:GetSetting('DoTankIllusionBuff') end, },
                { name = "SpellProcBuff",    cond = function(self) return Config:GetSetting('DoProcBuff') end, },
                { name = "Dispel",           cond = function(self) return Config:GetSetting('DoDispel') end, },
                { name = "Avatar",           cond = function(self) return Config:GetSetting('DoAvatar') end, },
                { name = "MagicNuke",        cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "ColdDot",          cond = function(self) return Config:GetSetting('DoColdDot') end, },
                { name = "StrangleDot",      cond = function(self) return Config:GetSetting('DoStrangleDot') end, },
                { name = "MindstingDot",     cond = function(self) return Config:GetSetting('DoMindstingDot') end, },
                { name = "MindDot",          cond = function(self) return Config:GetSetting('DoMindDot') end, },
                { name = "PetHealSpell",     cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "HateBuff",         cond = function(self) return Config:GetSetting('DoHateBuff') end, },
                { name = "SingleRune",       cond = function(self) return Config:GetSetting('RuneChoice') == 1 end, },
                { name = "GroupRune",        cond = function(self) return Config:GetSetting('RuneChoice') == 2 end, },
                { name = "GroupSpellShield", cond = function(self) return Config:GetSetting('DoGroupSpellShield') end, },
                { name = "KoadicRune", },
                -- todo: Add PBAE Mez for filler (manual use, script doesnt use it)
            },
        },
    },
    ['PullAbilities'] = {
        {
            id = 'TashSpell',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('TashSpell').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('TashSpell').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('TashSpell')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Dispel',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Dispel').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Dispel').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('Dispel')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig'] = {
        ['Mode']               = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this PC.",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What are the different Modes about?",
            Answer = "The Default Mode is designed for all levels on Project Lazarus.",
        },

        --Buffs
        ['RuneChoice']         = {
            DisplayName = "Rune Selection:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Select which line of Rune spells you prefer to use.\nPlease note that after level 73, the group rune has a built-in hate reduction when struck.",
            Type = "Combo",
            ComboOptions = { 'Single Target', 'Group', 'Off', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoGroupSpellShield'] = {
            DisplayName = "Do Group Spellshield",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Enable casting the Group Spell Shield Line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoProcBuff']         = {
            DisplayName = "Do Spellproc Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Enable casting the spell proc (Mana ... ) line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoIllusionBuff']     = {
            DisplayName = "Cast Illusion Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Enable casting your Illusion Proc Buff (NDT and EQM customs).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTankIllusionBuff'] = {
            DisplayName = "Cast Tank Illusion Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Enable casting your Tank Illusion Proc Buff (e.g Boon of the Brute).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoHateBuff']         = {
            DisplayName = "Do Hate Visage",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use your hatred visage buff on your tank.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoAvatar']           = {
            DisplayName = "Do Avatar",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 108,
            Tooltip = "Cast your Phantasmal Avatar buff.",
            RequiresLoadoutChange = true,
            Default = false,
        },

        --Debuffs
        ['DoTash']             = {
            DisplayName = "Do Tash",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Cast Tash Spells",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoSlow']             = {
            DisplayName = "Cast Slow",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Slow",
            Index = 101,
            Tooltip = "Enable casting Slow spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoCripple']          = {
            DisplayName = "Cast Cripple",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 102,
            Tooltip = "Enable casting Cripple spells.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoDispel']           = {
            DisplayName = "Do Dispel",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Dispel",
            Index = 101,
            Tooltip = "Enable removing beneficial enemy effects.",
            RequiresLoadoutChange = true,
            Default = true,
        },

        --Combat
        ['UseEpic']            = {
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
        ['AECount']            = {
            DisplayName = "AE Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Debuff Rules",
            Index = 101,
            Tooltip = "Number of XT Haters before we will use AE Slow, Tash, or Stun.",
            Min = 1,
            Default = 3,
            Max = 15,
        },
        ['DoSpinStun']         = {
            DisplayName = "Spin Stun use:",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "When to use your Spin Stun Line.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'At low MA health', 'Whenever Possible', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoAEStun']           = {
            DisplayName = "PBAE Stun use:",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 102,
            Tooltip = "When to use your PBAE Stun Line.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Never', 'At low MA health', 'Whenever Possible', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['EmergencyStart']     = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 101,
            Tooltip = "The HP % emergency abilities will be used (Abilities used depend on whose health is low, the ENC or the MA).",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['DoSoothing']         = {
            DisplayName = "Do Soothing Words",
            Group = "Abilities",
            Header = "Utility",
            Category = "Hate Reduction",
            Index = 101,
            RequiresLoadoutChange = true,
            Tooltip = "Use the Soothing Words AA (large aggro reduction) on a named whose target is not our MA.",
            Default = false,
        },
        ['DoBeguilers']        = {
            DisplayName = "Do Beguiler's",
            Group = "Abilities",
            Header = "Utility",
            Category = "Emergency",
            Index = 102,
            RequiresLoadoutChange = true,
            Tooltip = "Use Beguiler's (Directed) Banishment AA when you have aggro.",
            Default = false,
        },

        --DPS
        ['DoNuke']             = {
            DisplayName = "Magic Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use your primary magic nuke line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        -- ['DoColored']          = {
        --     DisplayName = "Colored Chaos",
        --     Group = "Abilities",
        --     Header = "Damage",
        --     Category = "Direct",
        --     Index = 102,
        --     Tooltip = "Use the Colored Chaos magic nuke.",
        --     RequiresLoadoutChange = true,
        --     Default = true,
        -- },
        ['DoStrangleDot']      = {
            DisplayName = "Strangle Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = "Use your magic damage (Strangle Line) Dot.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoMindstingDot']     = {
            DisplayName = "Mindsting Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your Mindsting magic damage Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoMindDot']          = {
            DisplayName = "Mind Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = "Use your mana drain/magic damage (Mind Line) Dot.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoColdDot']          = {
            DisplayName = "Do Cold Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Use your grave (cold) line of dots.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DotNamedOnly']       = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 105,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
        },

        -- Crystal Summoning
        ['SummonAzure']        = {
            DisplayName = "Azure Mind Crystal",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 101,
            Tooltip = "Summon Azure Mind Crystals (Mana Restore) for yourself.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['SummonSanguine']     = {
            DisplayName = "Sanguine Mind Crystal",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 102,
            Tooltip = "Summon Sanguine Mind Crystals (Health Restore) for yourself.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['UseDonorPet']        = {
            DisplayName = "Summon Asterion",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 101,
            Tooltip = "Use your Artifact of Asterion to summon the donor minotaur pet.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['DoPetHealSpell']     = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Pet Heal (Salve) spell. AA Pet Heals are always used in emergencies.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['PetHealPct']         = {
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
    },
    ['ClassFAQ']      = {
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
