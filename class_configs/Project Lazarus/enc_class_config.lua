local mq           = require('mq')
local Casting      = require("utils.casting")
local Comms        = require("utils.comms")
local Config       = require('utils.config')
local Core         = require("utils.core")
local DanNet       = require('lib.dannet.helpers')
local Globals      = require("utils.globals")
local ItemManager  = require("utils.item_manager")
local Logger       = require("utils.logger")
local Targeting    = require("utils.targeting")

local _ClassConfig = {
    _version          = "1.5 - Project Lazarus",
    _author           = "Derple, Grimmier, Algar, Robban",
    ['ModeChecks']    = {
        CanMez    = function() return true end,
        CanCharm  = function() return true end,
        IsMezzing = function() return Config:GetSetting('MezOn') end,
    },
    ['Modes']         = {
        'Default',
    },
    ['PetPosition']   = {
        SummonAA = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        -- RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
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
        ['Epic'] = {
            "Staff of Eternal Eloquence",
            "Oculus of Persuasion",
        },
        ['OoW_Chest'] = {
            "Mindreaver's Vest of Coercion",
            "Charmweaver's Robe",
        },
    },
    ['AbilitySets']   = {
        ['TwincastAura'] = {
            "Twincast Aura", -- Level 65
        },
        ['SpellProcAura'] = {
            "Illusionist's Aura", -- Level 70
            "Beguiler's Aura",    -- Level 55
        },
        ['VisageAura'] = {
            "Aura of Endless Glamour", -- Level 65
        },
        ['GroupHasteBuff'] = {
            "Hastening of Ellowind", -- Level 71 Laz Custom
            "Hastening of Salik",    -- Level 70
            "Vallon's Quickening",   -- Level 65
            "Speed of the Brood",    -- Level 60
        },
        ['SingleHasteBuff'] = {
            "Speed of Ellowind",   -- Level 71 Laz Custom
            "Speed of Salik",      -- Level 67
            "Speed of Vallon",     -- Level 62
            "Visions of Grandeur", -- Level 60
            "Wondrous Rapidity",   -- Level 58
            "Aanya's Quickening",  -- Level 53
            "Swift Like the Wind", -- Level 47
            "Celerity",            -- Level 39
            "Alacrity",            -- Level 21
            "Quickness",           -- Level 15
        },
        ['ManaRegen'] = {
            "Voice of Intuition",         -- Level 71 Laz Custom
            "Voice of Clairvoyance",      -- Level 70
            "Clairvoyance",               -- Level 68
            "Voice of Quellious",         -- Level 65
            "Tranquility",                -- Level 63
            "Koadic's Endless Intellect", -- Level 60
            "Gift of Pure Thought",       -- Level 56
            "Clarity II",                 -- Level 52
            "Boon of the Clear Mind",     -- Level 42
            "Clarity",                    -- Level 26
            "Breeze",                     -- Level 14
        },
        ['MezBuff'] = {
            "Ward of Bedazzlement", -- Level 65
        },
        ['NdtBuff'] = {
            "Boon of the Sentinel", -- Level 71 Laz Custom
            "Boon of the Legion",   -- Level 67 Laz Custom
            "Night's Dark Terror",  -- Level 63
            "Boon of the Garou",    -- Level 40
        },
        ['SelfHPBuff'] = {
            "Presidio of the Seer", -- Level 71 Laz Custom
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
            "Ethereal Rune", -- Level 66
            "Arcane Rune",   -- Level 61
        },
        ['SingleRune'] = {
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
            "Mana Recursion", -- Level 70
            "Mana Flare",     -- Level 65
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
            --  "Ancient: Voice of Muram", -- Level 70 3m dur/10m reuse
            "Whispers of Emoush", -- Level 71 Laz Custom
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
            -- "Synaptic Seizure", -- Level 70, In resources but not available
            "Synapsis Spasm", -- Level 66
            "Cripple",        -- Level 53
            "Incapacitate",   -- Level 40
            "Listless Power", -- Level 25
            "Disempower",     -- Level 16
            "Enfeeblement",   -- Level 4
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
            "Abashi's Disempowerment", -- Level 70 Laz Custom
            "Recant Magic",            -- Level 53
            "Pillage Enchantment",     -- Level 42
            "Nullify Magic",           -- Level 28
            "Strip Enchantment",       -- Level 22
            "Cancel Magic",            -- Level 7
            "Taper Enchantment",       -- Level 1
        },
        ['TashSpell'] = {
            "Edict of Tashan", -- Level 71 Laz Custom
            "Echo of Tashan",  -- Level 70
            "Howl of Tashan",  -- Level 61
            "Tashanian",       -- Level 57
            "Tashania",        -- Level 41
            "Tashani",         -- Level 18
            "Tashina",         -- Level 2
        },
        -- ['ManaDrainNuke'] = {
        --     "Torment of Scio",   -- Level 63
        --     "Torment of Argli",  -- Level 56
        --     "Scryer's Trespass", -- Level 52
        --     "Wandering Mind",    -- Level 38
        --     "Mana Sieve",        -- Level 30
        -- },
        ['StrangleDot'] = {
            "Arcane Noose",       -- Level 69
            "Strangle",           -- Level 62
            "Asphyxiate",         -- Level 59
            "Gasping Embrace",    -- Level 47
            "Suffocate",          -- Level 26
            "Choke",              -- Level 11
            "Suffocating Sphere", -- Level 4
            "Shallow Breath",     -- Level 1
        },
        ['MindDot'] = {
            -- "Ancient: Mind Implosion", -- Level 71 Laz Custom, verify existence and source
            "Mind Shatter", -- Level 70
        },
        ['MagicNuke'] = {
            "Hysteria",                 -- Level 71 Laz Custom
            "Ancient: Neurosis",        -- Level 70
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
        ['PetSpell'] = {
            "Salik's Animation",    -- Level 66
            "Aeldorb's Animation",  -- Level 62
            "Zumaik's Animation",   -- Level 55
            "Kintaz's Animation",   -- Level 48
            "Yegoreff's Animation", -- Level 41
            "Aanya's Animation",    -- Level 37
            "Boltran's Animation",  -- Level 31
            "Uleen's Animation",    -- Level 29
            "Sagar's Animation",    -- Level 22
            "Sisna's Animation",    -- Level 17
            "Shalee's Animation",   -- Level 14
            "Kilan's Animation",    -- Level 9
            "Mircyl's Animation",   -- Level 7
            "Juli's Animation",     -- Level 2
            "Pendril's Animation",  -- Level 1
        },
        ['MezAESpell'] = {
            "Wake of Felicity",   -- Level 69
            "Bliss of the Nihil", -- Level 65
            "Fascination",        -- Level 52
            "Mesmerization",      -- Level 16
        },
        -- ['MezPBAESpell'] = {
        --     "Bewilderment",      -- Level 72
        --     "Circle of Dreams",  -- Level 68
        --     "Word of Morell",    -- Level 62
        --     "Entrancing Lights", -- Level 30
        -- },
        ['MezSpell'] = {
            "Euphoria",                 -- Level 69
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
        --     "Perplexing Flash", -- Level 65
        -- },
        -- ['BlurSpell'] = {
        --     "Memory Flux",         -- Level 55
        --     "Reoccurring Amnesia", -- Level 45
        --     "Memory Blur",         -- Level 10
        -- },
        -- ['AEBlurSpell'] = {
        --     "Blanket of Forgetfulness", -- Level 46
        --     "Mind Wipe",                -- Level 36
        -- },
        -- ['CalmSpell'] = {
        --     "Placate",      -- Level 67
        --     "Pacification", -- Level 62
        --     "Pacify",       -- Level 35
        --     "Calm",         -- Level 18
        --     "Soothe",       -- Level 6
        --     "Lull",         -- Level 1
        -- },
        -- ['FearSpell'] = {
        --     "Anxiety Attack", -- Level 67
        --     "Jitterskin",     -- Level 62
        --     "Phobia",         -- Level 57
        --     "Trepidation",    -- Level 56
        --     "Invoke Fear",    -- Level 35
        --     "Chase the Moon", -- Level 16
        --     "Fear",           -- Level 3
        -- },
        -- ['RootSpell'] = {
        --     "Greater Fetter",   -- Level 61
        --     "Fetter",           -- Level 58
        --     "Paralyzing Earth", -- Level 45
        --     "Immobilize",       -- Level 39
        --     "Instill",          -- Level 25
        --     "Root",             -- Level 6
        -- },
        ['HasteManaCombo'] = {
            "Unified Alacrity", -- Level 71 Laz Custom
        },
        ['ColoredNuke'] = {
            "Chromatic Chaos", -- Level 71 Laz Custom
            "Colored Chaos",   -- Level 69
        },
        ['Chromaburst'] = {
            "Chromaburst", -- Level 70
        },
        ['UrgentRune'] = {
            "Urgent Rune of Destiny", -- Level 71 Laz Custom
        },
    },
    ['AASets']        = {
        ['ManaRestore'] = {
            "Mana Draw",
            "Gather Mana",
        },
    },
    ['Mez']           = {
        { type = "AA",    name = "Stasis",          cond = function() return Globals.AutoTargetIsNamed end, },
        { type = "Spell", name = "MezSpell", },
        { type = "Spell", name = "MezAESpell", },
        { type = "AA",    name = "Beam of Slumber", cond = function() return Config:GetSetting('DoAAMez') end, },
    },
    ['Charm']         = {
        ['Abilities'] = {
            { name = "Dire Charm", type = "AA", },
            { name = "CharmSpell", type = "Spell", },
        },
        ['PreCharm']  = {
            {
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTash') end,
                cond = function(self, spell, target) return not target.Tashed() end,
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
                name = "TashSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTash') end,
                cond = function(self, spell, target) return Casting.DetSpellCheck(spell, target) end,
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
        { -- Dual-state emergency group rune: tanks in combat, whole group in downtime
            name = 'UrgentRune',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoUrgentRune') end,
            targetId = function(self)
                return Globals.CurrentState == "Combat" and Casting.GetBuffableTankingIDs() or Casting.GetBuffableIDs()
            end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local combat = combat_state == "Combat"
                return (downtime or combat) and Core.CombatActionsCheck()
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
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Buff("Focus of Arcanum")() and Core.CombatActionsCheck()
            end,
        },
    },
    ['Helpers']       = { --used to autoinventory our crystals after summon. Crystal is a group-wide spell on Laz.
        StashCrystal = function(aaName)
            mq.delay("2s", function() return mq.TLO.Cursor.ID() == mq.TLO.Me.AltAbility(aaName).Spell.Base(1)() end)

            if not mq.TLO.Cursor() then
                Logger.log_debug("No valid item found on cursor, item handling aborted.")
                return false
            end

            Logger.log_debug("Sending the %s to our bags.", mq.TLO.Cursor())

            ItemManager.BroadcastQueueAutoInv(mq.TLO.Cursor.ID())
        end,
    },
    ['Rotations']     = {
        ['Downtime'] = {
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
                name = "SpellProcAura",
                type = "Spell",
                load_cond = function() return Config:GetSetting('UseAura') == 1 end,
                active_cond = function(self, spell)
                    local aura = string.sub(spell.Name() or "", 1, 8)
                    return Casting.AuraActiveByName(aura)
                end,
                pre_activate = function(self, spell)                  -- remove the old aura if we leveled up or changed options, otherwise we will be spammed because of no focus.
                    local aura = string.sub(spell.Name() or "", 1, 8) -- we use a string sub because aura name doesn't have the apostrophe the spell name does
                    if not Casting.AuraActiveByName(aura) then
                        ---@diagnostic disable-next-line: undefined-field
                        mq.TLO.Me.Aura(1).Remove()
                    end
                end,
                cond = function(self, spell)
                    local aura = string.sub(spell.Name() or "", 1, 8)
                    return not Casting.AuraActiveByName(aura)
                end,
            },
            {
                name = "TwincastAura",
                type = "Spell",
                load_cond = function() return Config:GetSetting('UseAura') == 2 end,
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.Name()) end,
                pre_activate = function(self, spell) -- remove the old aura if we changed options, otherwise we will be spammed because of no focus.
                    if not Casting.AuraActiveByName(spell.Name()) then
                        ---@diagnostic disable-next-line: undefined-field
                        mq.TLO.Me.Aura(1).Remove()
                    end
                end,
                cond = function(self, spell)
                    return not Casting.AuraActiveByName(spell.Name())
                end,
            },
            {
                name = "VisageAura",
                type = "Spell",
                load_cond = function() return Config:GetSetting('UseAura') == 3 end,
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.Name()) end,
                pre_activate = function(self, spell) -- remove the old aura if we changed options, otherwise we will be spammed because of no focus.
                    if not Casting.AuraActiveByName(spell.Name()) then
                        ---@diagnostic disable-next-line: undefined-field
                        mq.TLO.Me.Aura(1).Remove()
                    end
                end,
                cond = function(self, spell)
                    return not Casting.AuraActiveByName(spell.Name())
                end,
            },
            {
                name = "Auroria Mastery",
                type = "AA",
                load_cond = function() return Config:GetSetting('UseAura') == 4 end,
                active_cond = function(self) return Casting.AuraActiveByName("Aura of Bedazzlement") end,
                pre_activate = function(self) -- remove the old aura if we leveled up, otherwise we will be spammed because of no focus.
                    if not Casting.AuraActiveByName("Aura of Bedazzlement") then
                        ---@diagnostic disable-next-line: undefined-field
                        mq.TLO.Me.Aura(1).Remove()
                    end
                end,
                cond = function(self, aaName)
                    return not Casting.AuraActiveByName("Aura of Bedazzlement")
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                cond = function(self, spell) return Casting.ReagentCheck(spell) end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "SingleHasteBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.ID()).ID() end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) and Casting.PetBuffCheck(mq.TLO.Spell("Unified Alacrity")) end,
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
                name = "Crystalized Soul Gem", -- This isn't a typo
                type = "Item",
                cond = function(self, itemName)
                    return Casting.PetBuffItemCheck(itemName)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "HasteManaCombo",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ManaRegen",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if self:GetResolvedActionMapItem('HasteManaCombo') or not Targeting.TargetIsACaster(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name_func = function(self)
                    return Casting.GetFirstMapItem({ "GroupHasteBuff", "SingleHasteBuff", })
                end,
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if self:GetResolvedActionMapItem('HasteManaCombo') or not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.GroupBuffCheck(spell, target) and Casting.AddedBuffCheck(40597, target) -- Fixes bad stacking check
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
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "NdtBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoNDTBuff') end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    --Single target versions of the spell will only be used on Melee, group versions will be cast if they are missing from any groupmember
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsAMelee(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SpellProcBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoProcBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRune",
                type = "Spell",
                load_cond = function() return Config:GetSetting('RuneChoice') == 2 end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
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
                    return Casting.GroupBuffCheck(spell, target) and Casting.ReagentCheck(spell)
                end,
            },
            {
                name = "Azure Mind Crystal",
                type = "AA",
                load_cond = function() return Config:GetSetting('SummonAzure') end,
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    local crystal = mq.TLO.Spell(aaName).RankName.Base(1)()
                    return crystal and DanNet.query(target.CleanName(), string.format("FindItemCount[%d]", crystal), 1000) == "0" and (mq.TLO.Cursor.ID() or 0) == 0
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
                    if not Targeting.GroupedWithTarget(target) then return false end
                    local crystal = mq.TLO.Spell(aaName).RankName.Base(1)()
                    return crystal and DanNet.query(target.CleanName(), string.format("FindItemCount[%d]", crystal), 1000) == "0" and (mq.TLO.Cursor.ID() or 0) == 0
                end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.StashCrystal(aaName))
                    end
                end,
            },
        },
        ['UrgentRune'] = {
            {
                name = "UrgentRune",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['CombatSupport'] = {
            {
                name = "Fundament: Second Spire of Enchantment",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.GroupLowManaCount(30) > 1
                end,
            },
            {
                name = "Tome of Nife's Mercy",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Tome of Nife's Mercy")() end,
                cond = function(self, itemName, target)
                    return Casting.GroupLowManaCount(50) > 1
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
                    if (Config:GetSetting('DoSpinStun') == 2 and Core.GetMainAssistPctHPs() > Config:GetSetting('EmergencyStart')) then return false end
                    return Targeting.TargetNotStunned() and not Globals.AutoTargetIsNamed
                end,
            },
            {
                name = "PBAEStunSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoAEStun') > 1 end,
                cond = function(self, spell, target)
                    if (Config:GetSetting('DoAEStun') == 2 and Core.GetMainAssistPctHPs() > Config:GetSetting('EmergencyStart')) then return false end
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

        },
        ['Emergency'] = {
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
        ['Dispel'] = {
            {
                name = "Dispel",
                type = "Spell",
                cond = function(self, spell, target)
                    if mq.TLO.Target.ID() == 0 then return false end
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['DPS'] = {
            { -- This triggers two nukes so we cast it whether the dot is up or not. Treat is as a nuke.
                name = "MindDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoMindDot") end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ColoredNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoColored") end,
                cond = function(self)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Chromaburst",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoChroma") end,
                cond = function(self)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck()))
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
                name = "MagicNuke",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoNuke") end,
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
        },
        ['Burn'] = {
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
            {
                name = "Fundament: Third Spire of Enchantment",
                type = "AA",
                cond = function(self) return not Casting.IHaveBuff("Illusions of Grandeur") end,
            },
            {
                name = "Crippling Aurora",
                type = "AA",
                load_cond = function() return Config:GetSetting("DoCrippleAA") end,
                cond = function(self, aaName, target)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AECount') or
                        (not Config:GetSetting('DoCrippleSpell') and Globals.AutoTargetIsNamed and Casting.DetSpellAACheck(aaName))
                end,
            },
            {
                name = "CrippleSpell",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoCrippleSpell") end,
                cond = function(self, spell, target)
                    return Globals.AutoTargetIsNamed and Casting.DetSpellCheck(spell)
                end,
            },
            -- { --Temporarily commented out due to high prevalance of xtarget bugs with this pet. will revisit.
            --     name = "Phantasmal Opponent",
            --     type = "AA",
            -- },
            {
                name = "Nightmare Stasis",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
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
        ['Tash'] = {
            {
                name = "Bite of Tashani",
                type = "AA",
                cond = function(self, aaName)
                    if Targeting.GetXTHaterCount() < Config:GetSetting('AECount') then return false end
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "TashSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and (not Casting.TargetHasBuff("Bite of Tashani") or Globals.AutoTargetIsNamed)
                end,
            },
        },
        ['Slow'] = {
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
        ['ArcanumWeave'] = {
            {
                name = "Empowered Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Enlightened Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Acute Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
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
                { name = "TashSpell",        cond = function(self) return Config:GetSetting('DoTash') end, },
                { name = "SlowSpell",        cond = function(self) return Config:GetSetting('DoSlow') and not Casting.CanUseAA("Dreary Deeds") end, },
                { name = "CrippleSpell",     cond = function(self) return Config:GetSetting('DoCrippleSpell') end, },
                { name = "SpinStunSpell",    cond = function(self) return Config:GetSetting('DoSpinStun') > 1 end, },
                { name = "PBAEStunSpell",    cond = function(self) return Config:GetSetting('DoAEStun') > 1 end, },
                { name = "NdtBuff",          cond = function(self) return Config:GetSetting('DoNDTBuff') end, },
                { name = "SpellProcBuff",    cond = function(self) return Config:GetSetting('DoProcBuff') end, },
                { name = "Dispel",           cond = function(self) return Config:GetSetting('DoDispel') end, },
                { name = "ColoredNuke",      cond = function(self) return Config:GetSetting('DoColored') end, },
                { name = "Chromaburst",      cond = function(self) return Config:GetSetting('DoChroma') end, },
                { name = "MagicNuke",        cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "MindDot",          cond = function(self) return Config:GetSetting('DoMindDot') end, },
                { name = "StrangleDot",      cond = function(self) return Config:GetSetting('DoStrangleDot') end, },
                { name = "HateBuff",         cond = function(self) return Config:GetSetting('DoHateBuff') end, },
                { name = "UrgentRune",       cond = function(self) return Config:GetSetting('DoUrgentRune') end, },
                { name = "SingleRune",       cond = function(self) return Config:GetSetting('RuneChoice') == 1 end, },
                { name = "GroupRune",        cond = function(self) return Config:GetSetting('RuneChoice') == 2 end, },
                { name = "GroupSpellShield", cond = function(self) return Config:GetSetting('DoGroupSpellShield') end, },
            },
        },
    },
    ['PullAbilities'] = {
        {
            id = 'TashSpell',
            Type = "Spell",
            DisplayName = function()
                local s = Core.GetResolvedActionMapItem('TashSpell'); return s and s.RankName.Name() or ""
            end,
            AbilityName = function()
                local s = Core.GetResolvedActionMapItem('TashSpell'); return s and s.RankName.Name() or ""
            end,
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
            DisplayName = function()
                local s = Core.GetResolvedActionMapItem('Dispel'); return s and s.RankName.Name() or ""
            end,
            AbilityName = function()
                local s = Core.GetResolvedActionMapItem('Dispel'); return s and s.RankName.Name() or ""
            end,
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
        ['UseAura']            = {
            DisplayName = "Aura Selection:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip = "Select the Aura to be used, if any.",
            Type = "Combo",
            ComboOptions = { 'Spell Proc', 'Twincast', 'Visage', 'Auroria', 'None', },
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 5,
        },
        ['RuneChoice']         = {
            DisplayName = "Rune Selection:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Select which line of Rune spells you prefer to use.\nPlease note that after level 73, the group rune has a built-in hate reduction when struck.",
            Type = "Combo",
            ComboOptions = { 'Single Target', 'Group', 'Off', },
            Default = 3,
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
        ['DoNDTBuff']          = {
            DisplayName = "Cast NDT",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Enable casting your Melee Proc Buff (Night's Dark Terror Line) on melee.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoUrgentRune']       = {
            DisplayName = "Cast Urgent Rune",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Cast Urgent Rune of Destiny, an instant emergency group melee absorb (tank in combat, group in downtime).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoHateBuff']         = {
            DisplayName = "Do Hate Visage",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Use your hatred visage buff on your tank.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoArcanumWeave']     = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 107,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
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
        ['DoCrippleSpell']     = {
            DisplayName = "Cast Cripple Spell",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 101,
            Tooltip = "Enable casting Cripple spells.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoCrippleAA']        = {
            DisplayName = "Use AE Cripple AA",
            Group = "Abilities",
            Header = "Debuffs",
            Index = 102,
            Category = "Misc Debuffs",
            Tooltip = "Enable casting Crippling Aurora when we meet the AE threshold, or on a named if we don't have the spell above selected.",
            RequiresLoadoutChange = true,
            Default = true,
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
        ['DoColored']          = {
            DisplayName = "Colored Chaos",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use the Colored Chaos magic nuke.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoChroma']           = {
            DisplayName = "Chromaburst",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use the Chromaburst magic nuke.",
            RequiresLoadoutChange = true,
            Default = true,
        },
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
        ['DoMindDot']          = {
            DisplayName = "Mind Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            Tooltip = "Use your mana drain/magic damage (Mind Line) Dot on Named.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DotNamedOnly']       = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
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
            Tooltip = "Summon Azure Mind Crystals (Mana Restore) for the group.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['SummonSanguine']     = {
            DisplayName = "Sanguine Mind Crystal",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 102,
            Tooltip = "Summon Sanguine Mind Crystals (Health Restore) for the group.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
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
    },
}

return _ClassConfig
