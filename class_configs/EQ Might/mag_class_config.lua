local mq          = require('mq')
local Casting     = require("utils.casting")
local Combat      = require("utils.combat")
local Comms       = require("utils.comms")
local Config      = require('utils.config')
local Core        = require("utils.core")
local DanNet      = require('lib.dannet.helpers')
local Globals     = require('utils.globals')
local ItemManager = require("utils.item_manager")
local Logger      = require("utils.logger")
local Targeting   = require("utils.targeting")

_ClassConfig      = {
    _version          = "1.4 - EQ Might",
    _author           = "Derple, Morisato, Algar",
    ['ModeChecks']    = {
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
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
        'DPS',
        'PBAE',
    },
    ['PetPosition']   = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
    },
    ['Themes']        = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.60, g = 0.20, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.60, g = 0.20, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.24, g = 0.08, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.60, g = 0.20, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.60, g = 0.20, b = 0.02, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.24, g = 0.08, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.60, g = 0.20, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.60, g = 0.20, b = 0.02, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.60, g = 0.20, b = 0.02, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.40, g = 0.13, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.60, g = 0.20, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.60, g = 0.20, b = 0.02, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.60, g = 0.20, b = 0.02, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.24, g = 0.08, b = 0.01, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.55, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.55, b = 0.05, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.60, g = 0.20, b = 0.02, a = 1.0, }, },
        },
        ['PBAE'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.05, g = 0.25, b = 0.55, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.05, g = 0.25, b = 0.55, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.02, g = 0.10, b = 0.22, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.05, g = 0.25, b = 0.55, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.05, g = 0.25, b = 0.55, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.02, g = 0.10, b = 0.22, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.05, g = 0.25, b = 0.55, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.05, g = 0.25, b = 0.55, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.05, g = 0.25, b = 0.55, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.03, g = 0.16, b = 0.36, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.05, g = 0.25, b = 0.55, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.05, g = 0.25, b = 0.55, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.05, g = 0.25, b = 0.55, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.02, g = 0.10, b = 0.22, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.20, g = 0.75, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.20, g = 0.75, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.05, g = 0.25, b = 0.55, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Focus of Primal Elements",
            "Staff of Elemental Essence",
        },
        ['OoW_Chest'] = {
            "Glyphwielder's Tunic of the Summoner",
            "Runemaster's Robe",
        },
        ['Asterion'] = {
            "Artifact of Greater Asterion",
            "Artifact of Asterion",
            "Lesser Artifact of Asterion",
        },
    },
    ['AbilitySets']   = {
        --- Nukes
        ['SwarmPet'] = {
            "Raging Servant",            -- Level 70
            "Restrained Raging Servant", -- Level 65 EQM Custom
        },
        -- ['ChaoticNuke'] = {
        --     -- Chaotic Nuke with Beneficial Effect >= LVL69
        --     "Fickle Fire", -- Level 69
        -- },
        ['FireDD'] = {                 -- Mix of Fire Nukes and Bolts appropriate for use at lower levels.
            "Scalding Sands",          -- Level 71
            "Burning Earth",           -- Level 69
            "Burning Sand",            -- Level 62
            "Scars of Sigil",          -- Level 54
            "Lava Bolt",               -- Level 47
            "Cinder Bolt",             -- Level 33
            "Bolt of Flame",           -- Level 18
            "Shock of Flame",          -- Level 15
            "Flame Bolt",              -- Level 5
            "Burn",                    -- Level 4
            "Burst of Flame",          -- Level 1
        },
        ['BigFireDD'] = {              -- Longer cast time bolts we can use when mobs are at higher health.
            "Bolt of Molten Slag",     -- Level 70
            -- "Ancient: Nova Strike",  -- Level 70 -- considered how to implement smart toggles for this, didn't like what i've come up with so far. less dmg then spear, -300 resist vs 150
            "Spear of Ro",             -- Level 68
            "Bolt of Jerikor",         -- Level 66
            "Ancient: Chaos Vortex",   -- Level 65
            "Firebolt of Tallon",      -- Level 61
            "Ancient: Shock of Sun",   -- Level 60
            "Seeking Flame of Seukor", -- Level 59
        },
        ['MagicDD'] = {                -- Magic does not have any faster casts like Fire, we have only these.
            "Shock of Silvered Steel", -- Level 71
            "Blade Strike",            -- Level 68
            "Rock of Taelosia",        -- Level 65
            "Black Steel",             -- Level 63
            "Shock of Steel",          -- Level 57
            "Shock of Swords",         -- Level 41
            "Shock of Spikes",         -- Level 23
            "Shock of Blades",         -- Level 7
        },
        --- Buffs
        ['SelfShield'] = {
            "Prime Shielding",      -- Level 70
            "Elemental Aura",       -- Level 66
            "Shield of Maelin",     -- Level 64
            "Shield of the Arcane", -- Level 61
            "Shield of the Magi",   -- Level 54
            "Arch Shielding",       -- Level 43
            "Greater Shielding",    -- Level 32
            "Major Shielding",      -- Level 24
            "Shielding",            -- Level 16
            "Lesser Shielding",     -- Level 5
            "Minor Shielding",      -- Level 1
        },
        ['ShortDurDmgShield'] = {
            -- Use at the start of the DPS loop
            "Ancient: Veil of Pyrilonus", -- Level 70
            "Pyrilen Skin",               -- Level 68
        },
        ['LongDurDmgShield'] = {
            -- Preferring group buffs for ease. Included all Single target Now as well
            -- "Magmaskin", Single target vs group (convenience), minimal difference
            "Ancient: Circle of Fireskin", -- Level 70
            "Circle of Fireskin",          -- Level 70
            "Fireskin",                    -- Level 66
            "Maelstrom of Ro",             -- Level 63
            "Flameshield of Ro",           -- Level 61
            "Aegis of Ro",                 -- Level 60
            "Cadeau of Flame",             -- Level 56
            "Boon of Immolation",          -- Level 53
            "Shield of Lava",              -- Level 45
            "Barrier of Combustion",       -- Level 38
            "Inferno Shield",              -- Level 28
            "Shield of Flame",             -- Level 19
            "Shield of Fire",              -- Level 7
        },
        ['ManaRegenBuff'] = {
            "Phantasmal Warden",               -- Level 71
            "Phantom Shield",                  -- Level 68
            "Xegony's Phantasmal Guard",       -- Level 62
            "Transon's Phantasmal Protection", -- Level 58
        },
        ['PetAura'] = {
            -- Mage Pet Aura
            "Rathe's Strength", -- Level 70
            "Earthen Strength", -- Level 55
        },
        ['FireShroud'] = {
            -- Defensive Proc 3-6m Buff
            "Burning Aura", -- Level 68
        },
        -- Pet Spells Pets & Spells Affecting them
        ['PetHealSpell'] = {
            "Renewal of Aenda",             -- Level 71
            "Renewal of Jerikor",           -- Level 68
            "Renewal of Lucifer",           -- Level 66 EQM Custom
            "Planar Renewal",               -- Level 64
            "Transon's Elemental Renewal",  -- Level 60
            "Transon's Elemental Infusion", -- Level 52
            "Refresh Summoning",            -- Level 34
            "Renew Summoning",              -- Level 18
            "Renew Elements",               -- Level 7
        },
        ['PetManaConv'] = {
            "Elemental Simulacrum", -- Level 70
            "Elemental Siphon",     -- Level 65
            "Elemental Draw",       -- Level 54
        },
        ['PetHaste'] = {
            "Burnout VI",             -- Level 69
            "Elemental Fury",         -- Level 68
            "Burnout V",              -- Level 62
            "Ancient: Burnout Blaze", -- Level 60
            "Burnout IV",             -- Level 55
            "Elemental Empathy",      -- Level 52
            "Burnout III",            -- Level 47
            "Burnout II",             -- Level 29
            "Burnout",                -- Level 11
        },
        ['PetIceFlame'] = {
            "Iceflame Guard", -- Level 70
        },
        ['EarthPetSpell'] = {
            "Child of Earth",             -- Level 69
            "Rathe's Son",                -- Level 65
            "Greater Vocaration: Earth",  -- Level 57
            "Vocarate: Earth",            -- Level 51
            "Greater Conjuration: Earth", -- Level 46
            "Conjuration: Earth",         -- Level 44
            "Lesser Conjuration: Earth",  -- Level 39
            "Minor Conjuration: Earth",   -- Level 34
            "Greater Summoning: Earth",   -- Level 29
            "Summoning: Earth",           -- Level 25
            "Lesser Summoning: Earth",    -- Level 21
            "Minor Summoning: Earth",     -- Level 17
            "Elemental: Earth",           -- Level 13
            "Elementaling: Earth",        -- Level 9
            "Elementalkin: Earth",        -- Level 5
        },
        ['WaterPetSpell'] = {
            "Essence of Water",           -- Level 71
            "Child of Water",             -- Level 67
            "Servant of Marr",            -- Level 62
            "Greater Vocaration: Water",  -- Level 60
            "Vocarate: Water",            -- Level 54
            "Greater Conjuration: Water", -- Level 49
            "Conjuration: Water",         -- Level 41
            "Lesser Conjuration: Water",  -- Level 36
            "Minor Conjuration: Water",   -- Level 31
            "Greater Summoning: Water",   -- Level 26
            "Summoning: Water",           -- Level 22
            "Lesser Summoning: Water",    -- Level 18
            "Minor Summoning: Water",     -- Level 14
            "Elemental: Water",           -- Level 10
            "Elementaling: Water",        -- Level 6
            "Elementalkin: Water",        -- Level 2
        },
        ['AirPetSpell'] = {
            ----- Air Pet
            "Essence of Air",           -- Level 70
            "Child of Wind",            -- Level 66
            "Ward of Xegony",           -- Level 61
            "Greater Vocaration: Air",  -- Level 59
            "Vocarate: Air",            -- Level 53
            "Greater Conjuration: Air", -- Level 48
            "Conjuration: Air",         -- Level 43
            "Lesser Conjuration: Air",  -- Level 38
            "Minor Conjuration: Air",   -- Level 33
            "Greater Summoning: Air",   -- Level 28
            "Summoning: Air",           -- Level 24
            "Lesser Summoning: Air",    -- Level 20
            "Minor Summoning: Air",     -- Level 16
            "Elemental: Air",           -- Level 12
            "Elementaling: Air",        -- Level 8
            "Elementalkin: Air",        -- Level 4
        },
        ['FirePetSpell'] = {
            "Child of Fire",             -- Level 68
            "Child of Ro",               -- Level 63
            "Greater Vocaration: Fire",  -- Level 58
            "Vocarate: Fire",            -- Level 52
            "Greater Conjuration: Fire", -- Level 47
            "Conjuration: Fire",         -- Level 42
            "Lesser Conjuration: Fire",  -- Level 37
            "Minor Conjuration: Fire",   -- Level 32
            "Greater Summoning: Fire",   -- Level 27
            "Summoning: Fire",           -- Level 23
            "Lesser Summoning: Fire",    -- Level 19
            "Minor Summoning: Fire",     -- Level 15
            "Elemental: Fire",           -- Level 11
            "Elementaling: Fire",        -- Level 7
            "Elementalkin: Fire",        -- Level 3
        },
        ['AegisBuff'] = {
            ---Pet Aegis Shield Buff (Short Duration)*
            "Bulwark of Calliav",    -- Level 69
            "Protection of Calliav", -- Level 64
            "Guard of Calliav",      -- Level 58
            "Ward of Calliav",       -- Level 46
        },
        -- - Summoned item Spells
        ['FireOrbSummon'] = {
            "Summon: Molten Orb", -- Level 69
            "Summon: Lava Orb",   -- Level 61
        },
        ['ManaRodSummon'] = {
            --- ManaRodSummon - Focuses on group mana rod summon for ease. _
            -- "Wand of Elemental Transvergence", -- Level 71
            "Mass Mystical Transvergence", -- Level 56
            "Modulating Rod",              -- Level 44
        },
        -- - Debuffs
        ['MaloDebuff'] = {
            "Malosinise",  -- Level 70
            "Malosinia",   -- Level 63
            "Malosini",    -- Level 58
            "Malosi",      -- Level 51
            "Malaisement", -- Level 44
            "Malaise",     -- Level 22
        },
        ['SingleCotH'] = {
            "Call of the Hero", -- Level 55
        },
        -- ['GroupCotH'] = {
        --     "Call of the Harbinger", -- Level 68 -- does not appear to be added
        -- },
        ['PBAE2'] = {
            "Scintillation", -- Level 51
        },
        ['PBAE1'] = {
            "Wind of the Desert", -- Level 60
        },
        ['Minionskin'] = {        --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",   -- Level 66 EQM Custom
            "Greater Minionskin", -- Level 56 EQM Custom
            "Minionskin",         -- Level 43 EQM Custom
            "Lesser Minionskin",  -- Level 30 EQM Custom
        },
        ['EpicPetOrb'] = {
            "Summon Orb", -- Level 45
        },
    },
    ['AASets']        = {
        ['Spire'] = {
            "Fundament: Second Spire of the Elements",
            "Fundament: First Spire of the Elements",
        },
        ['ModRod'] = {
            "Large Modulation Shard",
            "Medium Modulation Shard",
            "Small Modulation Shard",
        },
    },
    ['Charm']         = {
        ['Assist'] = {
            {
                name = "Malosinete",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMaloAA') and Casting.CanUseAA("Malosinete") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "MaloDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMalo') and not Casting.CanUseAA("Malosinete") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
    },
    ['RotationOrder'] = { -- TODO: Add emergency rotation, shared health, etc
        {
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToPetBuff() and mq.TLO.Me.Pet.ID() == 0
                    and Casting.AmIBuffable()
            end,
        },
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this. Timer lowered for mage due to high volume of actions
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Malo',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoMalo') or Config:GetSetting('DoMaloAA') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 3,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'DPS(PBAE)',
            state = 1,
            steps = 1,
            load_cond = function(self) return Core.IsModeActive('PBAE') and self:GetResolvedActionMapItem('PBAE2') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoAEDamage') then return false end
                return combat_state == "Combat" and Targeting.AggroCheckOkay() and Combat.AETargetCheck(true)
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay()
            end,
        },
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'Summon ModRods',
            timer = 120, --this will only be checked once every 2 minutes
            state = 1,
            steps = 2,
            load_cond = function() return Config:GetSetting('SummonModRods') and Core.GetResolvedActionMapItem("ManaRodSummon") end,
            targetId = function(self)
                local groupIds = {}
                if not Core.OnEMU() or mq.TLO.Me.Inventory("MainHand")() then
                    table.insert(groupIds, mq.TLO.Me.ID())
                end
                local count = mq.TLO.Group.Members()
                for i = 1, count do
                    local mainHand = DanNet.query(mq.TLO.Group.Member(i).DisplayName(), "Me.Inventory[MainHand]", 1000)
                    if Core.OnEMU() and (mainHand and mainHand:lower() == "null") then
                        groupIds = {}
                        Logger.log_debug("%s has no weapon equipped, aborting ModRod summon to avoid corpse-looting conflicts.", mq.TLO.Group.Member(i).DisplayName())
                        break
                    else
                        table.insert(groupIds, mq.TLO.Group.Member(i).ID())
                    end
                end
                return groupIds
            end,
            cond = function(self, combat_state)
                local downtime = combat_state == "Downtime" and Casting.OkayToBuff()
                local pct = Config:GetSetting('GroupManaPct')
                local combat = combat_state == "Combat" and Config:GetSetting('CombatModRod') and (mq.TLO.Group.LowMana(pct)() or -1) >= Config:GetSetting('GroupManaCt')
                return downtime or combat
            end,
        },
    },
    -- Really the meat of this class.
    ['Helpers']       = {
        -- Resolves the currently-active element based on ElementMode.
        -- Auto: prefers Fire, then Magic, skipping either if the auto-target is immune
        -- (per the Spawn List) or toggled off via Skip<X>Spells.
        PickElement = function()
            local mode = Config:GetSetting('ElementMode') or 1
            if mode == 2 then return "Fire" end
            if mode == 3 then return "Magic" end
            local autoId = Globals.AutoTargetID or 0
            if not Casting.ShouldSkipElement("Fire", autoId) then return "Fire" end
            if not Casting.ShouldSkipElement("Magic", autoId) then return "Magic" end
            return "Fire" -- both skipped; default so downstream logic still resolves
        end,
        DeleteEpicOrb = function(self)
            if mq.TLO.Cursor() and mq.TLO.Cursor.ID() > 0 then
                Core.DoCmd("/autoinventory")
                mq.delay(50, function() return mq.TLO.Cursor() == nil end)
            end
            if not mq.TLO.Cursor() then
                Core.DoCmd("/nomodkey /itemnotify \"Orb of Mastery\" leftmouseup")
                mq.delay(50, function() return mq.TLO.Cursor() ~= nil end)
                if mq.TLO.Cursor() then
                    if mq.TLO.Cursor.ID() == 28034 then
                        Core.DoCmd("/destroy")
                        mq.delay(50, function() return mq.TLO.Cursor() == nil end)
                        if not mq.TLO.FindItem("28034")() then
                            return true
                        end
                    else
                        Logger.log_warning("Warning: We seem to have something else on the cursor! Do you have another item named 'Orb of Mastery'? Aborting delete.")
                    end
                end
            end
            Logger.log_warning("Warning: Mage pet orb not destroyed! An error or conflict has occured.")
            return false
        end,
        HandleItemSummon = function(self, itemSource, scope) --scope: "personal" or "group" summons
            if not itemSource and itemSource() then return false end
            if not scope then return false end

            mq.delay("2s", function() return mq.TLO.Cursor() ~= nil and mq.TLO.Cursor.ID() == mq.TLO.Spell(itemSource).RankName.Base(1)() end)

            if not mq.TLO.Cursor() then
                Logger.log_debug("No valid item found on cursor, item handling aborted.")
                return false
            end

            Logger.log_debug("Sending the %s to our bags.", mq.TLO.Cursor())

            local itemId = mq.TLO.Cursor.ID()
            if scope == "group" then
                ItemManager.BroadcastQueueAutoInv(itemId)
            elseif scope == "personal" then
                ItemManager.QueueAutoInv(itemId)
            else
                Logger.log_debug("Invalid scope sent: (%s). Item handling aborted.", scope)
                return false
            end
        end,
    },
    ['Rotations']     = {
        ['PetSummon'] = {
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
                name = "Ornate Orb of Mastery",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseEpicPet") and mq.TLO.FindItem("=Ornate Orb of Mastery")() end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, itemName, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50)
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "Orb of Mastery",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseEpicPet") and not mq.TLO.FindItem("=Ornate Orb of Mastery")() end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                cond = function(self, itemName, target)
                    local orb = mq.TLO.FindItem("28034")
                    return orb() and (orb.Charges() or 0) > 0
                end,
                post_activate = function(self, itemName, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50)
                        self:SetPetHold()
                        self.Helpers.DeleteEpicOrb(self)
                    end
                end,
            },
            {
                name_func = function(self)
                    return string.format("%sPetSpell", self.ClassConfig.DefaultConfig.PetType.ComboOptions[Config:GetSetting('PetType')])
                end,
                type = "Spell",
                active_cond = function(self) return mq.TLO.Me.Pet.ID() > 0 end,
                load_cond = function(self)
                    return (not Config:GetSetting("UseEpicPet") or not mq.TLO.Me.Book("Summon Orb")()) and
                        (not Config:GetSetting("UseDonorPet") or not Core.GetResolvedActionMapItem('Asterion'))
                end,
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
        ['PetHealing'] = {
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
        ['PetBuff'] = {
            { --if the buff is removed from the pet, the invisible rathe aura object remains; if we don't check for it, a spam condition could ensue
                -- buff will be lost on zone
                name = "PetAura",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell) and mq.TLO.SpawnCount("untargetable _strength radius 200 zradius 50")() == 0
                end,
            },
            {
                name = "PetIceFlame",
                type = "Spell",
                active_cond = function(self, spell)
                    return mq.TLO.Me.PetBuff(spell.RankName.Name())() ~= nil or mq.TLO.Me.PetBuff(spell.Name())() ~= nil
                end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetHaste",
                type = "Spell",
                active_cond = function(self, spell)
                    return mq.TLO.Me.PetBuff(spell.RankName.Name())() ~= nil or mq.TLO.Me.PetBuff(spell.Name())() ~= nil
                end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "PetManaConv",
                type = "Spell",
                cond = function(self, spell)
                    if not spell or not spell() then return false end
                    return Casting.SelfBuffCheck(spell)
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
        ['Burn'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if mq.TLO.Me.Pet.ID() == 0 then return false end
                    return Casting.PetBuffItemCheck(itemName)
                end,
            },
            {
                name = "Frenzied Burnout",
                type = "AA",
            },
            {
                name = "Host of the Elements",
                type = "AA",
            },
            {
                name = "Spire",
                type = "AA",
            },
            {
                name_func = function() return Casting.CanUseAA("Fire Core") and "Fire Core" or "Heart of Flames" end,
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Servant of Ro",
                type = "AA",
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
        },
        ['Weaves'] = {
            {
                name = "FireOrbItem",
                type = "CustomFunc",
                custom_func = function(self)
                    if not self.ResolvedActionMap['FireOrbSummon'] then return false end
                    local baseItem = self.ResolvedActionMap['FireOrbSummon'].RankName.Base(1)() or "None"
                    if mq.TLO.FindItemCount(baseItem)() == 1 then
                        local invItem = mq.TLO.FindItem(baseItem)
                        return Casting.UseItem(invItem.Name(), Globals.AutoTargetID)
                    end
                    return false
                end,
            },
            {
                name = "Arcane Whisper",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and mq.TLO.Me.PctAggro() > 90
                end,
            },
        },
        ['DPS(PBAE)'] = {
            {
                name = "PBAE1",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
            {
                name = "PBAE2",
                type = "Spell",
                allowDead = true,
                cond = function(self, spell, target)
                    return Targeting.InSpellRange(spell, target)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "Asterion",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and Core.GetResolvedActionMapItem('Asterion') end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "SwarmPet",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoSwarmPet') > 1 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke() and not (Config:GetSetting('DoSwarmPet') == 2 and not Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "BigFireDD",
                type = "Spell",
                cond = function(self, spell, target)
                    if self.Helpers.PickElement() ~= "Fire" then return false end
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "FireDD",
                type = "Spell",
                cond = function(self, spell, target)
                    if self.Helpers.PickElement() ~= "Fire" then return false end
                    return Targeting.MobHasLowHP(target) or not Core.GetResolvedActionMapItem("BigFireDD")
                end,
            },
            {
                name = "MagicDD",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.Helpers.PickElement() == "Magic"
                end,
            },
            {
                name = "Turn Summoned",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.IsSummoned(target)
                end,
            },
        },
        ['Malo'] = {
            {
                name = "Malosinete",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoMaloAA') and Casting.CanUseAA("Malosinete") end,
                cond = function(self, aaName)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMalo') and (not Casting.CanUseAA("Malosinete") or not Config:GetSetting('DoMaloAA')) end,
                cond = function(self, spell)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "LongDurDmgShield",
                type = "Spell",
                active_cond = function(self, spell)
                    return Casting.IHaveBuff(spell)
                end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() ~= "group v2" and not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target) and not Casting.IHaveBuff("Circle of " .. spell.Name())
                end,
            },
            {
                name = "FireShroud",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                        -- workarounds for laz
                        and Casting.AddedBuffCheck(19847, target) -- necrotic pustules
                        and Casting.AddedBuffCheck(5521, target)  -- decrepit skin
                end,
                post_activate = function(self, spell, success)
                    local petName = mq.TLO.Me.Pet.CleanName() or "None"
                    mq.delay("3s", function() return mq.TLO.Me.Casting() == nil end)
                    if success and mq.TLO.Me.XTarget(petName)() then
                        Comms.PrintGroupMessage("It seems %s has triggered combat due to a server bug, calling the pet back.", spell)
                        Core.DoCmd('/pet back off')
                    end
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "ManaRegenBuff",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SelfShield",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "EpicPetOrb",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('UseEpicPet') and not mq.TLO.FindItem("=Ornate Orb of Mastery")() end,
                cond = function(self, spell, target)
                    return not mq.TLO.FindItem("28034")()
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "personal")
                    end
                end,
            },
            {
                name = "Delete Used Epic Orb",
                type = "CustomFunc",
                load_cond = function(self) return Config:GetSetting('UseEpicPet') and not mq.TLO.FindItem("=Ornate Orb of Mastery")() end,
                cond = function(self)
                    local orb = mq.TLO.FindItem("28034")
                    return orb() and (orb.Charges() or 999) == 0
                end,
                custom_func = function(self) return self.Helpers.DeleteEpicOrb(self) end,
            },
            {
                name = "FireOrbSummon",
                type = "Spell",
                cond = function(self, spell)
                    return mq.TLO.FindItemCount(spell.RankName.Base(1)() or "")() == 0
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "group")
                    end
                end,
            },
            {
                name = "Elemental Form: Fire",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Summon ModRods'] = {
            { -- Mod Rod AA, will use the first(best) one found.
                name = "ModRod",
                type = "AA",
                load_cond = function() return Core.GetResolvedActionMapItem('ModRod') end,
                cond = function(self, aaName, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    local modRodItem = mq.TLO.Spell(aaName).RankName.Base(1)()
                    return modRodItem and DanNet.query(target.CleanName(), string.format("FindItemCount[%d]", modRodItem), 1000) == "0" and
                        (mq.TLO.Cursor.ID() or 0) == 0
                end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, aaName, "group")
                    end
                end,
            },
            {
                name = "ManaRodSummon",
                type = "Spell",
                load_cond = function() return not Core.GetResolvedActionMapItem('ModRod') end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    local modRodItem = spell.RankName.Base(1)()
                    return modRodItem and DanNet.query(target.CleanName(), string.format("FindItemCount[%d]", modRodItem), 1000) == "0" and
                        (mq.TLO.Cursor.ID() or 0) == 0
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "group")
                    end
                end,
            },
        },
    },
    ['SpellList']     = {
        {
            name = "Default", --This name is abitrary, it is simply what shows up in the UI when this spell list is loaded.
            spells = {        -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
                { name = "FireDD", },
                { name = "BigFireDD", },
                { name = "MagicDD", },
                { name = "SwarmPet", },
                { name = "EpicPetOrb",       cond = function(self) return Config:GetSetting('UseEpicPet') and not mq.TLO.FindItem("=Ornate Orb of Mastery")() end, },
                { name = "PBAE1",            cond = function(self) return Core.IsModeActive("PBAE") end, },
                { name = "PBAE2",            cond = function(self) return Core.IsModeActive("PBAE") end, },
                { name = "MaloDebuff",       cond = function(self) return Config:GetSetting('DoMalo') and (not Config:GetSetting('DoMaloAA') or not Casting.CanUseAA("Malosinete")) end, },
                { name = "PetHealSpell",     cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "FireOrbSummon", },
                { name = "SingleCotH", },
                { name = "ManaRodSummon",    cond = function(self) return Config:GetSetting('SummonModRods') and not Core.GetResolvedActionMapItem('ModRod') end, },
                { name = "FireShroud", },
                { name = "LongDurDmgShield", },
            },
        },
    },
    ['DefaultConfig'] = {
        ['Mode']           = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What is the difference between the modes?",
            Answer = "DPS Mode performs exactly as described.\n" ..
                "PBAE Mode will use PBAE spells when configured, alongside the DPS rotation.",
        },
        ['UseDonorPet']    = {
            DisplayName = "Summon Asterion",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 103,
            Tooltip = "Use your Artifact of Asterion to summon the donor minotaur pet.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['UseEpicPet']     = {
            DisplayName = "Summon Epic Pet",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 104,
            Tooltip = "Use your Orb of Mastery to summon the epic pet.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['PetType']        = {
            DisplayName = "Pet Type",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 101,
            Tooltip = "Choose the elemental to summon when not using the epic pet.",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Water', 'Earth', 'Air', },
            Default = 2,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['DoPetHealSpell'] = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Pet Heal spell. AA Pet Heals are always used in emergencies.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['PetHealPct']     = {
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
        ['SummonModRods']  = {
            DisplayName = "Summon Mod Rods",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 103,
            Tooltip = "Summon Mod Rods",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['ElementMode']    = {
            DisplayName = "Element Mode:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 1,
            Tooltip = "Pick the element strategy for nukes. Auto rotates Fire and Magic based on target immunity. " ..
                "See FAQ for details on Skip<Element>Spells conflicts.",
            Type = "Combo",
            ComboOptions = { 'Auto', 'Fire', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 3,
            FAQ = "How does Element Mode work?",
            Answer =
                "   The 'Element Mode' setting determines which element your nukes will use. Fire and Magic spell lines are always memorized so you can change mode in combat freely.\n\n" ..
                "   Auto mode prefers Fire, then Magic, automatically skipping either if your target is immune (per the Spawn List) or if you've globally toggled that element off via the Skip <Element> Spells settings. The explicit modes (Fire/Magic) lock to that element regardless of immunity data.\n\n" ..
                "   Heads up: explicit modes still respect the global Skip <Element> Spells toggles. If you pick Fire mode here but have SkipFireSpells enabled in your combat settings, the global skip wins and Fire casts will be blocked - you'll need to clear the conflicting toggle, or pick a different element here.",
        },
        ['DoSwarmPet']     = {
            DisplayName = "Swarm Pet Spell:",
            Group = "Abilities",
            Header = "Pet",
            Category = "Swarm Pets",
            Index = 101,
            Tooltip = "Choose the conditions to cast your Swarm Pet Spell.",
            Type = "Combo",
            ComboOptions = { 'Never', 'Named Only', 'Always', },
            Default = 2,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoMalo']         = {
            DisplayName = "Cast Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Use your Malo line spell.",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
        ['DoMaloAA']       = {
            DisplayName = "Cast Malo AA",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "If available, prefer the AA version of Malo (slight trade in debuff strength for less chance to be resisted).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
        ['CombatModRod']   = {
            DisplayName = "Combat Mod Rods",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 104,
            Tooltip = "Summon Mod Rods in combat if the criteria below are met.",
            Default = true,
            ConfigType = "Advanced",
        },
        ['GroupManaPct']   = {
            DisplayName = "Combat ModRod %",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 105,
            Tooltip = "Mana% to begin summoning Mod Rods in combat.",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['GroupManaCt']    = {
            DisplayName = "Combat ModRod Count",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 106,
            Tooltip = "The number of party members (including yourself) that need to be under the above mana percentage.",
            Default = 3,
            Min = 1,
            Max = 6,
            ConfigType = "Advanced",
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
