local mq          = require('mq')
local Casting     = require("utils.casting")
local Combat      = require("utils.combat")
local Comms       = require("utils.comms")
local Config      = require('utils.config')
local Core        = require("utils.core")
local DanNet      = require('lib.dannet.helpers')
local Globals     = require("utils.globals")
local ItemManager = require("utils.item_manager")
local Logger      = require("utils.logger")
local Targeting   = require("utils.targeting")

_ClassConfig      = {
    _version          = "1.5 - Project Lazarus",
    _author           = "Derple, Morisato, Algar",
    ['Modes']         = {
        'DPS',
        'PBAE',
    },
    ['PetPosition']   = {
        SummonAA = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        -- RelocateAA = function() return Casting.CanUseAA("Companion's Relocation") and "Companion's Relocation" end,
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
        ['Epic'] = {
            "Focus of Primal Elements",
            "Staff of Elemental Essence",
        },
        ['OoW_Chest'] = {
            "Glyphwielder's Tunic of the Summoner",
            "Runemaster's Robe",
        },
    },
    ['AbilitySets']   = {
        ['SwarmPet'] = {
            "Raging Servant", -- Level 70
        },
        ['SpearNuke'] = {
            -- "Ancient: Spear of Molten Slag", -- Level 71 Laz Custom, verify existence and source
            "Spear of Ro", -- Level 70
        },
        ['ChaoticNuke'] = {
            "Fickle Inferno",          -- Level 71 Laz Custom
            "Fickle Fire",             -- Level 69
        },
        ['FireDD'] = {                 --Mix of Fire Nukes and Bolts appropriate for use at lower levels.
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
            "Bolt of Jerikor",         -- Level 66
            "Firebolt of Tallon",      -- Level 61
            "Seeking Flame of Seukor", -- Level 59
        },
        ['MagicDD'] = {                -- Magic does not have any faster casts like Fire, we have only these.
            "Rock of Taelosia",        -- Level 65
            "Shock of Steel",          -- Level 57
            "Shock of Swords",         -- Level 41
            "Shock of Spikes",         -- Level 23
            "Shock of Blades",         -- Level 7
        },
        ['QuickMagicDD'] = {
            "Blade Rend",   -- Level 71 Laz Custom
            "Blade Strike", -- Level 68
            "Black Steel",  -- Level 63
        },
        ['SelfShield'] = {
            "Ward of the Conjurer", -- Level 71 Laz Custom
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
            "Ancient: Veil of Pyrilonus", -- Level 70
            "Pyrilen Skin",               -- Level 68
        },
        ['LongDurDmgShield'] = {
            "Circle of Magmaskin",   -- Level 71 Laz Custom
            "Circle of Fireskin",    -- Level 70
            "Fireskin",              -- Level 66
            "Maelstrom of Ro",       -- Level 63
            "Flameshield of Ro",     -- Level 61
            "Aegis of Ro",           -- Level 60
            "Cadeau of Flame",       -- Level 56
            "Boon of Immolation",    -- Level 53
            "Shield of Lava",        -- Level 45
            "Barrier of Combustion", -- Level 38
            "Inferno Shield",        -- Level 28
            "Shield of Flame",       -- Level 19
            "Shield of Fire",        -- Level 7
        },
        ['ManaRegenBuff'] = {
            "Phantom Shield",                  -- Level 68
            "Xegony's Phantasmal Guard",       -- Level 62
            "Transon's Phantasmal Protection", -- Level 58
        },
        ['PetAura'] = {
            "Monolithic Strength", -- Level 71 Laz Custom
            "Rathe's Strength",    -- Level 70
            "Earthen Strength",    -- Level 55
        },
        ['FireShroud'] = {
            "Burning Aura", -- Level 68
        },
        ['PetHealSpell'] = {
            "Goner's Urgent Renewal",       -- Level 71 Laz Custom
            "Renewal of Jerikor",           -- Level 69
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
            "Elemental Fury",    -- Level 69
            "Burnout V",         -- Level 62
            "Burnout IV",        -- Level 55
            "Elemental Empathy", -- Level 52
            "Burnout III",       -- Level 47
            "Burnout II",        -- Level 29
            "Burnout",           -- Level 11
        },
        ['PetIceFlame'] = {
            "Iceflame Guard", -- Level 70
        },
        ['EarthPetSpell'] = {
            "Child of Earth",             -- Level 70
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
            "Bulwark of Calliav",    -- Level 69
            "Protection of Calliav", -- Level 64
            "Guard of Calliav",      -- Level 58
            "Ward of Calliav",       -- Level 46
        },
        ['FireOrbSummon'] = {
            "Summon: Molten Orb", -- Level 69
            "Summon: Lava Orb",   -- Level 61
        },
        ['ManaRodSummon'] = {
            "Mass Mystical Transvergence", -- Level 56
            "Modulating Rod",              -- Level 44
        },
        ['MaloDebuff'] = {
            "Malosinia",   -- Level 63
            "Malosini",    -- Level 58
            "Malosi",      -- Level 51
            "Malaisement", -- Level 44
            "Malaise",     -- Level 22
        },
        ['SingleCotH'] = {
            "Call of the Hero", -- Level 55
        },
        ['GroupCotH'] = {
            "Call of the Heroes", -- Level 70
        },
        ['EpicPetOrb'] = {
            "Summon Orb", -- Level 45
        },
        ['Bladegusts'] = {
            "Burning Bladestorm", -- Level 71 Laz Custom
            "Burning Bladegusts", -- Level 69 Laz Custom
        },
        ['PBAE2'] = {
            "Scintillation", -- Level 51
        },
        ['PBAE1'] = {
            "Wind of the Desert", -- Level 60
        },
        ['Myriad'] = {
            "Shock of Myriad Minions", -- Level 70 Laz Custom
        },
        ['FranticDS'] = {
            "Frantic Blaze",  -- Level 71 Laz Custom
            "Frantic Flames", -- Level 70 Laz Custom
        },
    },
    ['AASets']        = {
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
                load_cond = function() return Config:GetSetting('DoMalo') and Casting.CanUseAA("Malosinete") end,
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
            load_cond = function() return Config:GetSetting('DoMalo') or Config:GetSetting('DoAEMalo') end,
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
            name = 'DPS(70)',
            state = 1,
            steps = 1,
            load_cond = function(self) return self:GetResolvedActionMapItem('SpearNuke') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay()
            end,
        },
        {
            name = 'DPS(1-69)',
            state = 1,
            steps = 1,
            load_cond = function(self) return not self:GetResolvedActionMapItem('SpearNuke') end,
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
        {
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not mq.TLO.Me.Buff("Focus of Arcanum")()
            end,
        },
    },
    -- Really the meat of this class.
    ['Helpers']       = {
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
                name = "Orb of Mastery",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseEpicPet") and mq.TLO.Me.Book("Summon Orb")() end,
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
                load_cond = function(self)
                    return not Config:GetSetting("UseEpicPet") or not mq.TLO.Me.Book("Summon Orb")()
                end,
                active_cond = function(self) return mq.TLO.Me.Pet.ID() > 0 end,
                cond = function(self, spell)
                    return Casting.ReagentCheck(spell)
                end,
                post_activate = function(self, spell, success)
                    local pet = mq.TLO.Me.Pet
                    if success and pet.ID() > 0 then
                        Comms.PrintGroupMessage("Summoned a new %d %s pet named %s using '%s'!", pet.Level(), pet.Class.Name(), pet.CleanName(), spell.RankName())
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
                name = "Minion's Memento",
                type = "Item",
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
                name = "Second Wind Ward",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Host in the Shell",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Aegis of Kildrukaun",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
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
                name = "Fundament: Second Spire of the Elements",
                type = "AA",
            },
            {
                name = "Heart of Flames",
                type = "AA",
                load_cond = function() return not Casting.CanUseAA("Fire Core") end,
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target) return Globals.AutoTargetIsNamed end,
            },
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Forsaken Conjurer's Shoes",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Conjurer's Shoes")() end,
            },
            {
                name = "Servant of Ro",
                type = "AA",
            },
            {
                name = "FranticDS",
                type = "CustomFunc",
                load_cond = function(self) return Config:GetSetting('DoFranticDS') end,
                cond = function(self, spell, target)
                    local shieldSpell = Core.GetResolvedActionMapItem("FranticDS")
                    return Casting.CastReady(shieldSpell) and Core.GetGroupTankId() > 0
                end,
                custom_func = function(self)
                    local shieldSpell = Core.GetResolvedActionMapItem("FranticDS")
                    return Casting.UseSpell(shieldSpell.RankName(), Core.GetGroupTankId(), false, false, 0)
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
            },
        },
        ['Weaves'] = {
            {
                name = "Force of Elements",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.AggroCheckOkay()
                end,
            },
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
        ['DPS(70)'] = {
            {
                name = "SwarmPet",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoSwarmPet') > 1 end,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke() and not (Config:GetSetting('DoSwarmPet') == 2 and not Globals.AutoTargetIsNamed)
                end,
            },
            {
                name = "Bladegusts",
                type = "Spell",
            },
            {
                name = "QuickMagicDD",
                type = "Spell",
            },
            {
                name = "ChaoticNuke",
                type = "Spell",
            },
            {
                name = "Myriad",
                type = "Spell",
            },
            {
                name = "SpearNuke",
                type = "Spell",
            },
            {
                name = "Turn Summoned",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.IsSummoned(target)
                end,
            },
            {
                name = "Dagger of Evil Summons",
                type = "Item",
            },
        },
        ['DPS(1-69)'] = {
            {
                name = "QuickMagicDD",
                type = "Spell",
            },
            {
                name = "BigFireDD",
                type = "Spell",
                load_cond = function() return Config:GetSetting('ElementChoice') == 1 end,
                cond = function(self, spell, target)
                    return Targeting.MobNotLowHP(target)
                end,
            },
            {
                name = "FireDD",
                type = "Spell",
                load_cond = function() return Config:GetSetting('ElementChoice') == 1 end,
                cond = function(self, spell, target)
                    return Targeting.MobHasLowHP(target) or not Core.GetResolvedActionMapItem("BigFireDD")
                end,
            },
            {
                name = "MagicDD",
                type = "Spell",
                load_cond = function() return Config:GetSetting('ElementChoice') == 2 end,
            },
            {
                name = "Turn Summoned",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.IsSummoned(target)
                end,
            },
            {
                name = "Bladegusts",
                type = "Spell",
            },
            {
                name = "ChaoticNuke",
                type = "Spell",
            },
        },
        ['Malo'] = {
            {
                name = "Wind of Malosinete",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoAEMalo') end,
                cond = function(self, aaName)
                    return Targeting.GetXTHaterCount() >= Config:GetSetting('AEMaloCount') and Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "Malosinete",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Malosinete") end,
                cond = function(self, aaName)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloDebuff",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Malosinete") end,
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
                        and Casting.AddedBuffCheck(8484, target)  -- decrepit skin
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
                name = "Fire Core",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "EpicPetOrb",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('UseEpicPet') and mq.TLO.Me.Book("Summon Orb")() end,
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
                load_cond = function(self) return Config:GetSetting('UseEpicPet') and mq.TLO.Me.Book("Summon Orb")() end,
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
    ['SpellList']     = {
        {
            name = "Low Level", --This name is abitrary, it is simply what shows up in the UI when this spell list is loaded.
            cond = function(self) return mq.TLO.Me.Level() < 70 end,
            spells = {          -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
                { name = "FireDD", },
                { name = "BigFireDD", },
                { name = "MagicDD", },
                { name = "QuickMagicDD", },
                { name = "Bladegusts", },
                { name = "EpicPetOrb",       cond = function(self) return Config:GetSetting('UseEpicPet') and mq.TLO.Me.Book("Summon Orb")() end, },
                { name = "PBAE1",            cond = function(self) return Core.IsModeActive("PBAE") end, },
                { name = "PBAE2",            cond = function(self) return Core.IsModeActive("PBAE") end, },
                { name = "MaloDebuff",       cond = function(self) return Config:GetSetting('DoMalo') and not Casting.CanUseAA("Malosinete") end, },
                { name = "PetHealSpell",     cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "FireOrbSummon", },
                { name = "GroupCotH", },
                { name = "SingleCotH",       cond = function() return not Casting.CanUseAA('Call of the Hero') end, },
                { name = "ManaRodSummon",    cond = function(self) return Config:GetSetting('SummonModRods') and not Core.GetResolvedActionMapItem('ModRod') end, },
                { name = "FireShroud", },
                { name = "LongDurDmgShield", },
            },
        },
        {
            name = "Level 70", --This name is abitrary, it is simply what shows up in the UI when this spell list is loaded.
            cond = function(self) return mq.TLO.Me.Level() >= 70 end,
            spells = {         -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
                { name = "SpearNuke", },
                { name = "ChaoticNuke", },
                { name = "SwarmPet", },
                { name = "EpicPetOrb",       cond = function(self) return Config:GetSetting('UseEpicPet') and mq.TLO.Me.Book("Summon Orb")() end, },
                { name = "Bladegusts", },
                { name = "QuickMagicDD", },
                { name = "Myriad", },
                { name = "PBAE1",            cond = function(self) return Core.IsModeActive("PBAE") end, },
                { name = "PBAE2",            cond = function(self) return Core.IsModeActive("PBAE") end, },
                { name = "MaloDebuff",       cond = function(self) return Config:GetSetting('DoMalo') and not Casting.CanUseAA("Malosinete") end, },
                { name = "PetHealSpell",     cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "FireOrbSummon", },
                { name = "FranticDS",        cond = function(self) return Config:GetSetting('DoFranticDS') end, },
                { name = "GroupCotH", },
                { name = "SingleCotH",       cond = function() return not Casting.CanUseAA('Call of the Hero') end, },
                { name = "FireShroud", },
                { name = "ManaRodSummon",    cond = function(self) return Config:GetSetting('SummonModRods') and not Core.GetResolvedActionMapItem('ModRod') end, },
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
        ['UseEpicPet']     = {
            DisplayName = "Summon Epic Pet",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 102,
            Tooltip = "Use your Orb of Mastery to summon the epic pet.",
            RequiresLoadoutChange = true,
            Default = true,
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
        ['ElementChoice']  = {
            DisplayName = "Element Choice:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 1,
            Tooltip = "Choose an element to focus on under level 71.",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
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
        ['DoFranticDS']    = {
            DisplayName = "Frantic Flames",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip = "Use Frantic Flames during burns.",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
        ['DoMalo']         = {
            DisplayName = "Cast Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 101,
            Tooltip = "Do Malo Spells/AAs",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
        },
        ['DoAEMalo']       = {
            DisplayName = "Cast AE Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 102,
            Tooltip = "Do AE Malo Spells/AAs",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = false,
        },
        ['AEMaloCount']    = {
            DisplayName = "AE Malo Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Index = 103,
            Tooltip = "Number of XT Haters before we use AE Malo.",
            Min = 1,
            Default = 2,
            Max = 30,
            ConfigType = "Advanced",
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
        ['DoArcanumWeave'] = {
            DisplayName = "Weave Arcanums",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
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
