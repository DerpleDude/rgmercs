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
    _version              = "1.4 - Live",
    _author               = "Derple, Morisato, Algar",
    ['ModeChecks']        = {
        IsTanking = function() return Core.IsModeActive("PetTank") end,
    },
    ['Modes']             = {
        'DPS',
        'PetTank',
    },
    ['PetPosition']       = {
        SummonAA   = function() return Casting.CanUseAA("Summon Companion") and "Summon Companion" end,
        RelocateAA = function()
            local cdAA = mq.TLO.Me.AltAbility("Companion's Discipline")
            return (cdAA and cdAA.Rank() or 0) >= 4 and "Companion's Discipline"
        end,
    },
    ['OnModeChange']      = function(self, mode)
        if mode == "PetTank" then
            Core.DoCmd("/pet taunt on")
            Core.DoCmd("/pet resume on")
            -- leaving these here to show people what they may need to change when they change modes... you should use a hotbutton.
            -- RGMercs will no longer be changing others settings with abandon.
            -- Config:SetSetting('DoPetCommands', true)
            -- Config:SetSetting('AutoAssistAt', 100)
            -- Config:SetSetting('StayOnTarget', false)
            -- Config:SetSetting('DoAutoEngage', true)
            -- Config:SetSetting('DoAutoTarget', true)
            -- Config:SetSetting('AllowMezBreak', true)
        else
            Core.DoCmd("/pet taunt off")
            -- if Config:GetSetting('AutoAssistAt') == 100 then
            --     Config:SetSetting('AutoAssistAt', 98)
            -- end
        end
    end,
    ['Themes']            = {
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
        ['PetTank'] = {
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
    ['ItemSets']          = {
        ['Epic'] = {
            "Focus of Primal Elements",
            "Staff of Elemental Essence",
        },
        ['OoW_Chest'] = {
            "Glyphwielder's Tunic of the Summoner",
            "Runemaster's Robe",
        },
    },
    ['AbilitySets']       = { --TODO: Look into new TOB item summons (Boiling Orb?)
        --- Nukes
        ['SwarmPet'] = {
            -- Swarm Pet* >= LVL 70
            "Raging Servant XIII", -- Level 130
            "Ravening Servant",    -- Level 125
            "Roiling Servant",     -- Level 120
            "Riotous Servant",     -- Level 115
            "Reckless Servant",    -- Level 110
            "Remorseless Servant", -- Level 105
            "Relentless Servant",  -- Level 100
            "Ruthless Servant",    -- Level 95
            "Ruinous Servant",     -- Level 90
            "Rumbling Servant",    -- Level 85
            "Rancorous Servant",   -- Level 80
            "Rampaging Servant",   -- Level 75
            "Raging Servant",      -- Level 70
            -- "Rage of Zomm",     -- Level 55
        },
        ['SpearNuke'] = {
            -- Spear Nuke* >= LVL 70
            "Spear of Ro X",               -- Level 130
            "Spear of Molten Dacite",      -- Level 125
            "Spear of Molten Luclinite",   -- Level 120
            "Spear of Molten Komatiite",   -- Level 115
            "Spear of Molten Arcronite",   -- Level 110
            "Spear of Molten Shieldstone", -- Level 105
            "Spear of Blistersteel",       -- Level 100
            "Spear of Molten Steel",       -- Level 95
            "Spear of Magma",              -- Level 90
            "Bolt of Molten Slag",         -- Level 71, Added for TLP without spear unlocked yet
            "Spear of Ro",                 -- Level 70
        },
        ['ChaoticNuke'] = {
            -- Chaotic Nuke with Beneficial Effect >= LVL69
            "Chaotic Fire VI",   -- Level 130
            "Chaotic Magma",     -- Level 125
            "Chaotic Calamity",  -- Level 120
            "Chaotic Pyroclasm", -- Level 115
            "Chaotic Inferno",   -- Level 110
            "Chaotic Fire",      -- Level 105
            "Fickle Magma",      -- Level 100
            "Fickle Flames",     -- Level 95
            "Fickle Flare",      -- Level 90
            "Fickle Blaze",      -- Level 85
            "Fickle Pyroclasm",  -- Level 80
            "Fickle Inferno",    -- Level 75
            "Fickle Fire",       -- Level 69
        },
        -- ['FireNuke'] = {
        --     -- Fire Nuke 1 <= LVL <= 70
        --     "Burning Sands XIV",     -- Level 129
        --     "Cremating Sands",       -- Level 124
        --     "Ravaging Sands",        -- Level 118
        --     "Incinerating Sands",    -- Level 113
        --     "Crash of Sand",         -- Level 111
        --     "Blistering Sands",      -- Level 108
        --     "Searing Sands",         -- Level 103
        --     "Broiling Sands",        -- Level 98
        --     "Blast of Sand",         -- Level 96
        --     "Burning Sands",         -- Level 93
        --     "Burst of Sand",         -- Level 91
        --     "Strike of Sand",        -- Level 86
        --     "Torrid Sands",          -- Level 83
        --     "Scorching Sands",       -- Level 78
        --     "Scalding Sands",        -- Level 73
        --     "Star Strike",           -- Level 70
        --     "Ancient: Nova Strike",  -- Level 70
        --     "Sun Vortex",            -- Level 65
        --     "Burning Sand",          -- Level 62
        --     "Shock of Fiery Blades", -- Level 60
        --     "Char",                  -- Level 52
        --     "Blaze",                 -- Level 31
        --     "Shock of Flame",        -- Level 15
        --     "Burn",                  -- Level 4
        --     "Burst of Flame",        -- Level 1
        -- },
        -- ['FireBoltNuke'] = {
        --     "Bolt of Flame XVIII",        -- Level 126
        --     "Bolt of Molten Dacite",      -- Level 121
        --     "Bolt of Molten Olivine",     -- Level 116
        --     "Bolt of Molten Komatiite",   -- Level 111
        --     "Bolt of Skyfire",            -- Level 106
        --     "Bolt of Molten Shieldstone", -- Level 101
        --     "Bolt of Molten Magma",       -- Level 96
        --     "Bolt of Molten Steel",       -- Level 91
        --     "Bolt of Rhyolite",           -- Level 86
        --     "Bolt of Molten Scoria",      -- Level 81
        --     "Bolt of Molten Dross",       -- Level 76
        --     "Bolt of Molten Slag",        -- Level 71
        --     "Bolt of Jerikor",            -- Level 66
        --     "Firebolt of Tallon",         -- Level 61
        --     "Seeking Flame of Seukor",    -- Level 59
        --     "Scars of Sigil",             -- Level 54
        --     "Lava Bolt",                  -- Level 47
        --     "Cinder Bolt",                -- Level 33
        --     "Bolt of Flame",              -- Level 18
        --     "Flame Bolt",                 -- Level 5
        -- },
        -- ['MagicNuke'] = {
        --     -- Nuke 1 <= LVL <= 69
        --     "Shock of Blades XIX",       -- Level 127
        --     "Shock of Memorial Steel",   -- Level 122
        --     "Shock of Carbide Steel",    -- Level 117
        --     "Shock of Burning Steel",    -- Level 112
        --     "Shock of Arcronite Steel",  -- Level 107
        --     "Shock of Darksteel",        -- Level 102
        --     "Shock of Blistersteel",     -- Level 97
        --     "Shock of Argathian Steel",  -- Level 92
        --     "Shock of Ethereal Steel",   -- Level 87
        --     "Shock of Discordant Steel", -- Level 82
        --     "Shock of Cineral Steel",    -- Level 77
        --     "Shock of Silvered Steel",   -- Level 72
        --     "Blade Strike",              -- Level 68
        --     "Rock of Taelosia",          -- Level 65
        --     "Black Steel",               -- Level 63
        --     "Shock of Steel",            -- Level 57
        --     "Shock of Swords",           -- Level 41
        --     "Shock of Spikes",           -- Level 23
        --     "Shock of Blades",           -- Level 7
        -- },
        -- ['MagicBolt'] = {
        --     -- Magic Bolt Nukes
        --     "Voidstone Bolt", -- Level 123
        --     "Luclinite Bolt", -- Level 118
        --     "Komatiite Bolt", -- Level 113
        --     "Korascian Bolt", -- Level 108
        --     "Meteoric Bolt",  -- Level 103
        --     "Iron Bolt",      -- Level 98
        -- },
        ['FireDD'] = {                 --Mix of Fire Nukes and Bolts appropriate for use at lower levels.
            "Scalding Sands",          -- Level 73
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
            "Bolt of Jerikor",         -- Level 66
            "Firebolt of Tallon",      -- Level 61
            "Seeking Flame of Seukor", -- Level 59
        },
        ['MagicDD'] = {                -- Magic does not have any faster casts like Fire, we have only these.
            "Blade Strike",            -- Level 68
            "Rock of Taelosia",        -- Level 65
            "Black Steel",             -- Level 63
            "Shock of Steel",          -- Level 57
            "Shock of Swords",         -- Level 41
            "Shock of Spikes",         -- Level 23
            "Shock of Blades",         -- Level 7
        },
        ['TwinCast'] = {
            "Twincast", -- Level 85
        },
        ['BeamNuke'] = {
            -- Beam Frontal AOE Spell*
            "Beam of Molten Slag XII",    -- Level 127
            "Beam of Molten Dacite",      -- Level 122
            "Beam of Molten Olivine",     -- Level 117
            "Beam of Molten Komatiite",   -- Level 112
            "Beam of Molten Rhyolite",    -- Level 107
            "Beam of Molten Shieldstone", -- Level 102
            "Beam of Brimstone",          -- Level 97
            "Beam of Molten Steel",       -- Level 92
            "Beam of Rhyolite",           -- Level 87
            "Beam of Molten Scoria",      -- Level 82
            "Beam of Molten Dross",       -- Level 77
            "Beam of Molten Slag",        -- Level 72
        },
        ['RainNuke'] = {
            --- Rain AOE Spell*
            "Rain of Fire XVI",         -- Level 128
            "Rain of Molten Dacite",    -- Level 123
            "Rain of Molten Olivine",   -- Level 118
            "Rain of Molten Komatiite", -- Level 113
            "Rain of Molten Rhyolite",  -- Level 108
            "Coronal Rain",             -- Level 103
            "Rain of Blistersteel",     -- Level 97
            "Rain of Molten Steel",     -- Level 92
            "Rain of Rhyolite",         -- Level 87
            "Rain of Molten Scoria",    -- Level 82
            "Rain of Molten Dross",     -- Level 77
            "Rain of Molten Slag",      -- Level 72
            "Rain of Jerikor",          -- Level 67
            "Sun Storm",                -- Level 62
            "Sirocco",                  -- Level 55
            "Rain of Lava",             -- Level 35
            "Rain of Fire",             -- Level 17
        },
        ['MagicRainNuke'] = {
            "Rain of Blades XVII",      -- Level 129
            "Rain of Kukris",           -- Level 124
            "Rain of Falchions",        -- Level 119
            "Maelstrom of Thunder",     -- Level 64
            "Maelstrom of Electricity", -- Level 60
            "ManaStorm",                -- Level 59
            "Rain Of Swords",           -- Level 49
            "Rain of Spikes",           -- Level 26
            "Rain of Blades",           -- Level 10
        },
        ['VolleyNuke'] = {
            -- Volley Nuke - Pet buff*
            "Shock of Many XI",  -- Level 127
            "Fusillade of Many", -- Level 122
            "Barrage of Many",   -- Level 117
            "Shockwave of Many", -- Level 112
            "Volley of Many",    -- Level 107
            "Storm of Many",     -- Level 102
            "Salvo of Many",     -- Level 97
            "Strike of Many",    -- Level 92
            "Clash of Many",     -- Level 87
            "Jolt of Many",      -- Level 82
            "Shock of Many",     -- Level 77
        },
        ['SummonedNuke'] = {
            -- Unnatural Nukes >70
            "Expunge the Unnatural",     -- Level 129
            "Dismantle the Unnatural",   -- Level 124
            "Unmend the Unnatural",      -- Level 118
            "Obliterate the Unnatural",  -- Level 113
            "Repudiate the Unnatural",   -- Level 108
            "Eradicate the Unnatural",   -- Level 103
            "Exterminate the Unnatural", -- Level 98
            "Abolish the Divergent",     -- Level 93
            "Annihilate the Divergent",  -- Level 88
            "Annihilate the Anomalous",  -- Level 83
            "Annihilate the Aberrant",   -- Level 78
            "Annihilate the Unnatural",  -- Level 73
        },
        ['MaloNuke'] = {
            -- Shock/Malo Combo Line
            "Shock of Malaise VII",      -- Level 129
            "Memorial Steel Malosinera", -- Level 124
            "Carbide Malosinetra",       -- Level 119
            "Burning Malosinara",        -- Level 114
            "Arcronite Malosinata",      -- Level 109
            "Darksteel Malosenete",      -- Level 104
            "Blistersteel Malosenia",    -- Level 100
        },
        --- Buffs
        ['SelfShield'] = {
            "Shielding XXIII",         -- Level 126
            "Shield of Memories",      -- Level 121
            "Shield of Shadow",        -- Level 116
            "Shield of Restless Ice",  -- Level 111
            "Shield of Scales",        -- Level 106
            "Shield of the Pellarus",  -- Level 101
            "Shield of the Dauntless", -- Level 96
            "Shield of Bronze",        -- Level 91
            "Shield of Dreams",        -- Level 86
            "Shield of the Void",      -- Level 81
            "Prime Guard",             -- Level 76
            "Prime Shielding",         -- Level 71
            "Elemental Aura",          -- Level 66
            "Shield of Maelin",        -- Level 64
            "Shield of the Arcane",    -- Level 61
            "Shield of the Magi",      -- Level 54
            "Arch Shielding",          -- Level 43
            "Greater Shielding",       -- Level 32
            "Major Shielding",         -- Level 24
            "Shielding",               -- Level 16
            "Lesser Shielding",        -- Level 5
            "Minor Shielding",         -- Level 1
        },
        ['SkinDS'] = {
            -- Use at the start of the DPS loop
            "Searing Skin XI",            -- Level 128
            "Boiling Skin",               -- Level 123
            "63715",                      -- Level 118, Scorching Skin - deconflicts duplicate at Level 73
            "Burning Skin",               -- Level 113
            "Blistering Skin",            -- Level 108
            "Coronal Skin",               -- Level 103
            "Infernal Skin",              -- Level 98
            "Molten Skin",                -- Level 93
            "Blazing Skin",               -- Level 88
            "Torrid Skin",                -- Level 83
            "Searing Skin",               -- Level 78
            "10720",                      -- Level 73, Scorching Skin - deconflicts duplicate at Level 118
            "Ancient: Veil of Pyrilonus", -- Level 70
            "Pyrilen Skin",               -- Level 68
        },
        ['LongDurDmgShield'] = {
            -- Preferring group buffs for ease. Included all Single target Now as well.
            "Circle of Fireskin XVI",    -- Level 126
            "Circle of Forgefire Coat",  -- Level 124
            "Forgefire Coat",            -- Level 121
            "Circle of Emberweave Coat", -- Level 119
            "Emberweave Coat",           -- Level 116
            "Circle of Igneous Skin",    -- Level 114
            "Igneous Coat",              -- Level 111
            "Circle of the Inferno",     -- Level 109
            "Inferno Coat",              -- Level 106
            "Circle of Flameweaving",    -- Level 104
            "Flameweave Coat",           -- Level 101
            "Circle of Flameskin",       -- Level 99
            "Flameskin",                 -- Level 96
            "Circle of Embers",          -- Level 94
            "Embercoat",                 -- Level 91
            "Circle of Dreamfire",       -- Level 89
            "Dreamfire Coat",            -- Level 86
            "Circle of Brimstoneskin",   -- Level 84
            "Brimstoneskin",             -- Level 81
            "Circle of Lavaskin",        -- Level 79
            "Lavaskin",                  -- Level 76
            "Circle of Magmaskin",       -- Level 74
            "Magmaskin",                 -- Level 71
            "Circle of Fireskin",        -- Level 70
            "Fireskin",                  -- Level 66
            "Maelstrom of Ro",           -- Level 63
            "FlameShield of Ro",         -- Level 61
            "Aegis of Ro",               -- Level 60
            "Cadeau of Flame",           -- Level 56
            "Boon of Immolation",        -- Level 53
            "Shield of Lava",            -- Level 45
            "Barrier of Combustion",     -- Level 38
            "Inferno Shield",            -- Level 28
            "Shield of Flame",           -- Level 19
            "Shield of Fire",            -- Level 7
        },
        ['ManaRegenBuff'] = {
            -- LVL58 (Transon's Phantasmal Protection) and up to avoid reagent usage
            "Eidolic Guardian XVII",           -- Level 127
            "Courageous Guardian",             -- Level 122
            "Relentless Guardian",             -- Level 117
            "Restless Guardian",               -- Level 112
            "Burning Guardian",                -- Level 107
            "Praetorian Guardian",             -- Level 102
            "Phantasmal Guardian",             -- Level 97
            "Splendrous Guardian",             -- Level 92
            "Cognitive Guardian",              -- Level 87
            "Empyrean Guardian",               -- Level 82
            "Eidolic Guardian",                -- Level 77
            "Phantasmal Warden",               -- Level 72
            "Phantom Shield",                  -- Level 68
            "Xegony's Phantasmal Guard",       -- Level 62
            "Transon's Phantasmal Protection", -- Level 58
        },
        ['AllianceBuff'] = {
            "Firebound Covariance",  -- Level 125
            "Firebound Conjunction", -- Level 120
            "Firebound Coalition",   -- Level 115
            "Firebound Covenant",    -- Level 110
            "Firebound Alliance",    -- Level 101
        },
        ['SurgeDS1'] = {
            -- ShortDuration DS (Slot 4)
            "Surge of Shadow",        -- Level 100
            "Surge of Arcanum",       -- Level 95
            "Surge of Shadowflares",  -- Level 90
            "Surge of Thaumacretion", -- Level 85
        },
        ['SurgeDS2'] = {
            -- ShortDuration DS (Slot 4)
            "Surge of Shadow",        -- Level 100
            "Surge of Arcanum",       -- Level 95
            "Surge of Shadowflares",  -- Level 90
            "Surge of Thaumacretion", -- Level 85
        },
        ['PetAura'] = {
            -- Mage Pet Aura
            "Arcane Distillect", -- Level 85
        },
        --not used
        --[[ ['SingleDS'] = {
            -- Single target Dmg Shields For Pets
            "Forgefire Coat",
            "Emberweave Coat",
            "Igneous Coat",
            "Inferno Coat",
            "Flameweave Coat",
            "Flameskin",
            "Embercoat",
            "Dreamfire Coat",
            "Brimstoneskin",
            "Lavaskin",
            "Magmaskin",
            "Fireskin",
            "FlameShield of Ro",
            "Cadeau of Flame",
            "Shield of Lava",
            "Barrier of Combustion",
            "Inferno Shield",
            "Shield of Flame",
            "Shield of Fire",
        },]] --
        ['FireShroud'] = {
            -- Defensive Proc 3-6m Buff
            "Burning Veil X",     -- Level 129
            "Igneous Veil",       -- Level 124
            "Volcanic Veil",      -- Level 119
            "Exothermic Veil",    -- Level 114
            "Skyfire Veil",       -- Level 109
            "Magmatic Veil",      -- Level 99
            "Molten Veil",        -- Level 94
            "Burning Veil",       -- Level 89
            "Burning Pyroshroud", -- Level 84
            "Burning Brimbody",   -- Level 79
            "Burning Aura",       -- Level 68
        },
        ['PetBodyGuard'] = {
            "Hulking Bodyguard X",   -- Level 126
            "ValorForged Bodyguard", -- Level 121
            "Ophiolite Bodyguard",   -- Level 116
            "Pyroxenite Bodyguard",  -- Level 115
            "Rhyolitic Bodyguard",   -- Level 110
            "Shieldstone Bodyguard", -- Level 105
            "Groundswell Bodyguard", -- Level 100
            "Steelbound Bodyguard",  -- Level 95
            "Tellurian Bodyguard",   -- Level 90
            "Hulking Bodyguard",     -- Level 85
        },
        ['GatherMana'] = {
            "Gather Potential VIII", -- Level 130
            "Gather Zeal",           -- Level 125
            "Gather Vigor",          -- Level 120
            "Gather Potency",        -- Level 115
            "Gather Capability",     -- Level 110
            "Gather Magnitude",      -- Level 100
            "Gather Capacity",       -- Level 95
            "Gather Potential",      -- Level 90
        },
        -- Pet Spells Pets & Spells Affecting them
        ['MeleeGuard  '] = {
            "Shield of Fate VII",       -- Level 127
            "Shield of Inescapability", -- Level 122
            "Shield of Inevitability",  -- Level 117
            "Shield of Destiny",        -- Level 112
            "Shield of Order",          -- Level 107
            "Shield of Consequence",    -- Level 102
            "Shield of Fate",           -- Level 97
        },
        ['DichoSpell'] = {
            -- Dicho Spell*
            "Reciprocal Companion", -- Level 121
            "Ecliptic Companion",   -- Level 116
            "Composite Companion",  -- Level 111
            "Dissident Companion",  -- Level 106
            "Dichotomic Companion", -- Level 101
        },
        ['PetHealSpell'] = {
            -- Pet Heal*
            "Renewal of Magmath",           -- Level 128
            "Renewal of Shoru",             -- Level 123
            "Renewal of Iilivina ",         -- Level 118
            "Renewal of Evreth",            -- Level 113
            "Renewal of Ioulin",            -- Level 108
            "Renewal of Calix",             -- Level 103
            "Renewal of Hererra",           -- Level 98
            "Renewal of Sirqo",             -- Level 93
            "Renewal of Volark",            -- Level 88
            "Renewal of Cadwin",            -- Level 83
            "Revival of Aenro",             -- Level 78
            "Renewal of Aenda",             -- Level 73
            "Renewal of Jerikor",           -- Level 69
            "Planar Renewal",               -- Level 64
            "Transon's Elemental Renewal",  -- Level 60
            "Transon's Elemental Infusion", -- Level 52
            "Refresh Summoning",            -- Level 34
            "Renew Summoning",              -- Level 18
            "Renew Elements",               -- Level 7
        },
        ['PetPromisedSpell'] = {
            ---Pet Promised*
            "Promised Mending XII",    -- Level 128
            "Promised Reconstitution", -- Level 123
            "Promised Relief",         -- Level 118
            "Promised Healing",        -- Level 113
            "Promised Alleviation",    -- Level 108
            "Promised Invigoration",   -- Level 103
            "Promised Amelioration",   -- Level 98
            "Promised Amendment",      -- Level 93
            "Promised Wardmending",    -- Level 88
            "Promised Rejuvenation",   -- Level 83
            "Promised Recovery",       -- Level 78
        },
        ['PetStanceSpell'] = {
            ---Pet Stance*
            "Omphacite Stance",   -- Level 123
            "Kanoite Stance",     -- Level 118
            "Pyroxene Stance",    -- Level 113
            "Rhyolite Stance",    -- Level 108
            "Shieldstone Stance", -- Level 103
            "Groundswell Stance", -- Level 98
            "Steelstance",        -- Level 93
            "Tellurian Stance",   -- Level 88
            "Earthen Stance",     -- Level 83
            "Grounded Stance",    -- Level 78
            "Granite Stance",     -- Level 73
        },
        ['PetManaConv'] = {
            "Valiant Symbiosis",    -- Level 122
            "Relentless Symbiosis", -- Level 117
            "Restless Symbiosis",   -- Level 115
            "Burning Symbiosis",    -- Level 110
            "Dark Symbiosis",       -- Level 105
            "Phantasmal Symbiosis", -- Level 100
            "Arcane Symbiosis",     -- Level 95
            "Spectral Symbiosis",   -- Level 90
            "Ethereal Symbiosis",   -- Level 85
            "Prime Symbiosis",      -- Level 80
            "Elemental Symbiosis",  -- Level 75
            "Elemental Simulacrum", -- Level 70
            "Elemental Siphon",     -- Level 65
            "Elemental Draw",       -- Level 54
        },
        ['PetHaste'] = {
            "Burnout XVII",      -- Level 126
            "Burnout XVI",       -- Level 121
            "Burnout XV",        -- Level 116
            "Burnout XIV",       -- Level 111
            "Burnout XIII",      -- Level 106
            "Burnout XII",       -- Level 101
            "Burnout XI",        -- Level 96
            "Burnout XI",        -- Level 96
            "Burnout IX",        -- Level 86
            "Burnout VIII",      -- Level 81
            "Burnout VII",       -- Level 76
            "Burnout VI",        -- Level 71
            "Elemental Fury",    -- Level 69
            "Burnout V",         -- Level 62
            "Burnout IV",        -- Level 55
            "Elemental Empathy", -- Level 52
            "Burnout III",       -- Level 47
            "Burnout II",        -- Level 29
            "Burnout",           -- Level 11
        },
        ['PetIceFlame'] = {
            "Iceflame Guard XII",  -- Level 129
            "IceFlame Palisade",   -- Level 124
            "Iceflame Barricade ", -- Level 119
            "Iceflame Rampart",    -- Level 114
            "Iceflame Keep",       -- Level 109
            "Iceflame Armaments",  -- Level 104
            "Iceflame Eminence",   -- Level 99
            "Iceflame Armor",      -- Level 94
            "Iceflame Ward",       -- Level 89
            "Iceflame Efflux",     -- Level 84
            "Iceflame Tenement",   -- Level 79
            "Iceflame Body",       -- Level 74
            "Iceflame Guard",      -- Level 70
        },
        ['EarthPetSpell'] = {
            "Earth Elemental XXVI",       -- Level 129
            "Recruitment of Earth",       -- Level 124
            "Conscription of Earth",      -- Level 119
            "Manifestation of Earth",     -- Level 114
            "Embodiment of Earth",        -- Level 109
            "Convocation of Earth",       -- Level 104
            "Shard of Earth",             -- Level 99
            "Facet of Earth",             -- Level 94
            "Construct of Earth",         -- Level 89
            "Aspect of Earth",            -- Level 84
            "Core of Earth",              -- Level 79
            "Essence of Earth",           -- Level 74
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
            "Water Elemental XXVI",       -- Level 127
            "Recruitment of Water",       -- Level 122
            "Conscription of Water",      -- Level 117
            "Manifestation of Water",     -- Level 112
            "Embodiment of Water",        -- Level 107
            "Convocation of Water",       -- Level 102
            "Shard of Water",             -- Level 97
            "Facet of Water",             -- Level 92
            "Construct of Water",         -- Level 87
            "Aspect of Water",            -- Level 82
            "Core of Water",              -- Level 77
            "Essence of Water",           -- Level 72
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
            "Air Elemental XXVI",       -- Level 126
            "Recruitment of Air",       -- Level 121
            "Conscription of Air",      -- Level 116
            "Manifestation of Air",     -- Level 111
            "Embodiment of Air",        -- Level 106
            "Convocation of Air",       -- Level 101
            "Shard of Air",             -- Level 96
            "Facet of Air",             -- Level 91
            "Construct of Air",         -- Level 86
            "Aspect of Air",            -- Level 81
            "Core of Air",              -- Level 76
            "Essence of Air",           -- Level 71
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
            "Fire Elemental XXVI",       -- Level 128
            "Recruitment of Fire",       -- Level 123
            "Conscription of Fire",      -- Level 118
            "Manifestation of Fire",     -- Level 113
            "Embodiment of Fire",        -- Level 108
            "Convocation of Fire",       -- Level 103
            "Shard of Fire",             -- Level 98
            "Facet of Fire",             -- Level 93
            "Construct of Fire",         -- Level 88
            "Aspect of Fire",            -- Level 83
            "Core of Fire",              -- Level 78
            "Essence of Fire",           -- Level 73
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
            "Aegis of Valorforged",  -- Level 124
            "Auspice of Usira",      -- Level 122
            "Aegis of Rumblecrush",  -- Level 119
            "Auspice of Valia",      -- Level 117
            "Aegis of Orfur",        -- Level 114
            "Auspice of Kildrukaun", -- Level 112
            "Aegis of Zeklor",       -- Level 109
            "Auspice of Esianti",    -- Level 107
            "Aegis of Japac",        -- Level 104
            "Auspice of Eternity",   -- Level 102
            "Aegis of Nefori",       -- Level 99
            "Auspice of Shadows",    -- Level 96
            "Aegis of Kildrukaun",   -- Level 79
            "Aegis of Calliav",      -- Level 74
            "Bulwark of Calliav",    -- Level 69
            "Protection of Calliav", -- Level 64
            "Guard of Calliav",      -- Level 58
            "Ward of Calliav",       -- Level 46
        },
        ['PetManaNuke'] = {
            --- PetManaNuke
            "Thaumatize Pet", -- Level 83
        },
        -- ['PetArmorSummon'] = {
        --     -- >=LVL71
        --     "Grant Arcane Plate",           -- Level 127
        --     "Grant The Alloy's Plate",      -- Level 121
        --     "Grant the Centien's Plate",    -- Level 116
        --     "Grant Ocoenydd's Plate",       -- Level 111
        --     "Grant Wirn's Plate",           -- Level 106
        --     "Grant Thassis' Plate",         -- Level 101
        --     "Grant Frightforged Plate",     -- Level 96
        --     "Grant Manaforged Plate",       -- Level 91
        --     "Grant Spectral Plate",         -- Level 86
        --     "Summon Plate of the Prime",    -- Level 76
        --     "Summon Plate of the Elements", -- Level 71
        -- },
        -- ['PetWeaponSummon'] = {
        --     "Grant Arcane Armaments",        -- Level 128
        --     "Grant Goliath's Armaments",     -- Level 123
        --     "Grant Shak Dathor's Armaments", -- Level 118
        --     "Grant Yalrek's Armaments",      -- Level 113
        --     "Grant Wirn's Armaments",        -- Level 108
        --     "Grant Thassis' Armaments",      -- Level 103
        --     "Grant Frightforged Armaments",  -- Level 98
        --     "Grant Manaforged Armaments",    -- Level 93
        --     "Grant Spectral Armaments",      -- Level 88
        --     "Summon Ethereal Armaments",     -- Level 83
        --     "Summon Prime Armaments",        -- Level 78
        --     "Summon Elemental Armaments",    -- Level 73
        -- },
        -- ['PetHeirloomSummon'] = {
        --     "Grant Arcane Heirlooms",      -- Level 126
        --     "Grant Ankexfen's Heirlooms",  -- Level 121
        --     "Grant the Diabo's Heirlooms", -- Level 116
        --     "Grant Crystasia's Heirlooms", -- Level 111
        --     "Grant Ioulin's Heirlooms",    -- Level 106
        --     "Grant Calix's Heirlooms",     -- Level 101
        --     "Grant Nint's Heirlooms",      -- Level 96
        --     "Grant Atleris' Heirlooms",    -- Level 91
        --     "Grant Enibik's Heirlooms",    -- Level 86
        --     "Summon Zabella's Heirlooms",  -- Level 81
        --     "Summon Nastel's Heirlooms",   -- Level 76
        -- },
        ['IceOrbSummon'] = {
            "Grant Frostbound Paradox", -- Level 109
            "Grant Icebound Paradox",   -- Level 99
            "Grant Frostrift Paradox",  -- Level 94
            "Grant Glacial Paradox",    -- Level 89
            "Summon Frigid Paradox",    -- Level 84
            "Summon Gelid Paradox",     -- Level 79
            "Summon Wintry Paradox",    -- Level 74
        },
        ['FireOrbSummon'] = {
            "Summon Molten Dacite Orb",    -- Level 125
            "Summon Molten Komatiite Orb", -- Level 114
            "Summon Firebound Orb",        -- Level 102
            "Summon Blazing Orb",          -- Level 94
            "Summon: Molten Orb",          -- Level 69
            "Summon: Lava Orb",            -- Level 61
        },
        ['EarthPetItemSummon'] = {
            "Summon Arcane Servant",     -- Level 128
            "Summon Valorous Servant",   -- Level 123
            "Summon Forbearing Servant", -- Level 118
            "Summon Imperative Servant", -- Level 113
            "Summon Insurgent Servant",  -- Level 108
            "Summon Mutinous Servant",   -- Level 103
            "Summon Imperious Servant",  -- Level 98
            "Summon Exigent Servant",    -- Level 93
        },
        ['FirePetItemSummon'] = {
            "Summon Arcane Minion",         -- Level 130
            "Summon Valorous Minion",       -- Level 125
            "Summon Forbearing Minion",     -- Level 120
            "Summon Imperative Minion",     -- Level 115
            "Summon Insurgent Minion",      -- Level 110
            "Summon Mutinous Minion",       -- Level 105
            "Summon Imperious Minion",      -- Level 100
            "Summon Exigent Minion",        -- Level 95
        },
        ['ManaRodSummon'] = {               -- Level 44 - 105
            --- ManaRodSummon - Focuses on group mana rod summon for ease.
            "Mass Dark Transvergence",      -- Level 105
            "Mass Arcane Transvergence",    -- Level 95
            "Mass Spectral Transvergence",  -- Level 90
            "Mass Ethereal Transvergence",  -- Level 85
            "Mass Prime Transvergence",     -- Level 80
            "Mass Elemental Transvergence", -- Level 75
            "Mass Mystical Transvergence",  -- Level 56
            "Modulating Rod",               -- Level 44
        },
        ['SelfManaRodSummon'] = {
            ---, - Focuses on self mana rod summon separate from other timers. >95
            "Rod of Shattered Modulation",   -- Level 127
            "Rod of Courageous Modulation",  -- Level 122
            "Sickle of Umbral Modulation",   -- Level 117
            "Wand of Frozen Modulation",     -- Level 112
            "Wand of Burning Modulation",    -- Level 107
            "Wand of Dark Modulation",       -- Level 102
            "Wand of Phantasmal Modulation", -- Level 97
        },
        -- - Debuffs
        ['MaloDebuff'] = {
            -- line < LVL 75 @ LVL75 use the AA
            "Malaise XVI", -- Level 126
            "Malosinera",  -- Level 121
            "Malosinetra", -- Level 116
            "Malosinara",  -- Level 111
            "Malosinata",  -- Level 106
            "Malosenete",  -- Level 101
            "Malosenia",   -- Level 96
            "Maloseneta",  -- Level 91
            "Malosene",    -- Level 86
            "Malosenea",   -- Level 81
            "Malosinatia", -- Level 76
            "Malosinise",  -- Level 71
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
            "Call of the Heroes", -- Level 97
        },
        ['EpicPetOrb'] = {
            "Summon Orb", -- Level 45
        },
    },
    ['HealRotationOrder'] = {

    },
    ['Charm']             = {
        ['Assist'] = {
            {
                name = "Malaise",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Malaise") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName, target)
                end,
            },
            {
                name = "MaloDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMalo') and not Casting.CanUseAA("Malaise") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
        },
    },
    ['RotationOrder']     = {
        {
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToPetBuff() and mq.TLO.Me.Pet.ID() == 0 and Casting.AmIBuffable()
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
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
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'Malo',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoMalo') or Config:GetSetting('DoAEMalo') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'DPS PET',
            state = 1,
            steps = 1,
            load_cond = function() return Core.IsModeActive("PetTank") end,
            doFullRotation = true,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
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
            name = 'SkinDS',
            state = 1,
            steps = 1,
            load_cond = function(self) return Config:GetSetting('DoSkinDS') and self:GetResolvedActionMapItem('SkinDS') end,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'DPS(LowLevel)',
            state = 1,
            steps = 1,
            load_cond = function(self) return self.Helpers.ShouldUseLowLevelRotation() end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToNuke()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function(self) return not self.Helpers.ShouldUseLowLevelRotation() end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToNuke()
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
    ['Helpers']           = {
        ShouldUseLowLevelRotation = function() return not Core.GetResolvedActionMapItem('ChaoticNuke') end,
        PickElement = function()
            local mode = Config:GetSetting('ElementMode') or 1
            if mode == 2 then return "Fire" end
            if mode == 3 then return "Magic" end
            local autoId = Globals.AutoTargetID or 0
            if not Casting.ShouldSkipElement("Fire", autoId) then return "Fire" end
            if not Casting.ShouldSkipElement("Magic", autoId) then return "Magic" end
            return "Fire"
        end,
        user_tu_spell = function(self, aaName)
            local shroudSpell = self.ResolvedActionMap['ShroudSpell']
            local aaSpell = Casting.GetAASpell(aaName)
            if not shroudSpell or not shroudSpell() or not aaSpell or not aaSpell() or not Casting.CanUseAA(aaName) then return false end
            -- do we need to lookup the spell basename here? I dont think so but if this doesn't fire right take a look.
            if shroudSpell.Level() > aaSpell.Level() then return false end
            return true
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

            mq.delay("2s", function() return mq.TLO.Cursor() ~= nil and mq.TLO.Cursor.ID() == mq.TLO.Spell(itemSource).RankName.Base(1)() or false end)

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
    ['Rotations']         = {
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
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetHealing'] = {
            {
                name = "Mend Companion",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name = "Companion's Fortification",
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
        ['PetBuff'] = {
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
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if mq.TLO.Me.Pet.ID() == 0 then return false end
                    return Casting.PetBuffItemCheck(itemName)
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
                name = "Companion's Aegis",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
            {
                name = "Companion's Intervening Divine Aura",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "EarthPetItemUse",
                type = "CustomFunc",
                cond = function(self)
                    if not self.ResolvedActionMap['EarthPetItemSummon'] then return false end
                    local baseItem = self.ResolvedActionMap['EarthPetItemSummon'].RankName.Base(1)()
                    return mq.TLO.FindItemCount(baseItem)() >= 1
                end,
                custom_func = function(self)
                    if not self.ResolvedActionMap['EarthPetItemSummon'] then return false end
                    local baseItem = self.ResolvedActionMap['EarthPetItemSummon'].RankName.Base(1)()
                    if mq.TLO.FindItemCount(baseItem)() >= 1 then
                        local invItem = mq.TLO.FindItem(baseItem)
                        return Casting.UseItem(invItem.Name(), Globals.AutoTargetID)
                    end

                    return false
                end,
            },
            {
                name = "FirePetItemUse",
                type = "CustomFunc",
                cond = function(self)
                    if not self.ResolvedActionMap['FirePetItemSummon'] then return false end
                    local baseItem = self.ResolvedActionMap['FirePetItemSummon'].RankName.Base(1)()
                    return mq.TLO.FindItemCount(baseItem)() >= 1
                end,
                custom_func = function(self)
                    if not self.ResolvedActionMap['FirePetItemSummon'] then return false end
                    local baseItem = self.ResolvedActionMap['FirePetItemSummon'].RankName.Base(1)()
                    if mq.TLO.FindItemCount(baseItem)() >= 1 then
                        local invItem = mq.TLO.FindItem(baseItem)
                        return Casting.UseItem(invItem.Name(), Globals.AutoTargetID)
                    end

                    return false
                end,
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
                name = "AllianceBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Globals.AutoTargetIsNamed and not Casting.TargetHasBuff(spell) and
                        Config:GetSetting('DoAlliance') and Casting.CanAlliance()
                end,
            },
            {
                name = "Companion's Fury",
                type = "AA",
            },
            {
                name = "Host of the Elements",
                type = "AA",
            },
            {
                name = "Spire of Elements",
                type = "AA",
            },
            {
                name = "Heart of Skyfire",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
            },
            {
                name = "Improved Twincast",
                type = "AA",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "TwinCast",
                type = "Spell",
                cond = function(self)
                    return not mq.TLO.Me.Buff("Twincast")()
                end,
            },
            {
                name = "Thaumaturge's Focus",
                type = "AA",
            },
            {
                name = "Servant of Ro",
                type = "AA",
            },
        },
        ['DPS PET'] = {
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, spell)
                    return Core.IsModeActive("PetTank")
                end,
            },
            {
                name = "PetStanceSpell",
                type = "Spell",
                cond = function(self, spell)
                    local chestBuff = Casting.GetClickySpell(Core.GetResolvedActionMapItem('OoW_Chest'))
                    return Core.IsModeActive("PetTank") and mq.TLO.Me.Pet.PctHPs() <= 95 and Casting.PetBuffCheck(spell) and not mq.TLO.Me.PetBuff(chestBuff and chestBuff() or "")()
                end,
            },
            {
                name = "SurgeDS1",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "SurgeDS2",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "SkinDS",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
            {
                name = "FireShroud",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
                end,
            },
        },
        ['Weaves'] = {
            {
                name = "Force of Elements",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoForce')
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
        ['DPS'] = {
            {
                name = "SwarmPet",
                type = "Spell",
            },
            {
                name = "VolleyNuke",
                type = "Spell",
            },
            {
                name = "BeamNuke",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('DoAEBeam') end,
                cond = function(self)
                    if not Config:GetSetting('DoAEDamage') then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "ChaoticNuke",
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
                name = "SummonedNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSummonedNuke') end,
                cond = function(self, spell, target)
                    return Targeting.IsSummoned(target)
                end,
            },
            {
                name = "SpearNuke",
                type = "Spell",
            },
            {
                name = "FireDD",
                type = "Spell",
                load_cond = function(self) return not Core.GetResolvedActionMapItem('SpearNuke') end,
            },
        },
        ['DPS(LowLevel)'] = {
            {
                name = "SummonedNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSummonedNuke') end,
                cond = function(self, spell, target)
                    return Targeting.IsSummoned(target)
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
                name = "Malaise",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "MaloDebuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoMalo') end,
                cond = function(self, spell, target)
                    if Casting.CanUseAA("Malaise") then return false end
                    return Casting.DetSpellCheck(spell)
                end,
            },
            {
                name = "Wind of Malaise",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoAEMalo') then return false end
                    return Casting.DetAACheck(aaName)
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
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "Elemental Conversion",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() <= Config:GetSetting('GatherManaPct') and mq.TLO.Me.Pet.ID() > 0
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctMana() <= Config:GetSetting('GatherManaPct') and not mq.TLO.Me.SpellReady(self.ResolvedActionMap['GatherMana'] or "")() and
                        mq.TLO.Me.Pet.ID() > 0
                end,
            },
            {
                name = "GatherMana",
                type = "Spell",
                cond = function(self, spell)
                    return spell and spell() and mq.TLO.Me.PctMana() <= Config:GetSetting('GatherManaPct') and Casting.CastReady(spell)
                end,
            },
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
                name = "Thaumaturge's Unity",
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
                name = "PetAura",
                type = "Spell",
                active_cond = function(self, spell)
                    return Casting.AuraActiveByName(spell.BaseName()) ~= nil
                end,
                cond = function(self, spell)
                    return not Casting.AuraActiveByName(spell.BaseName())
                end,
            },
            {
                name = "FireOrbSummon",
                type = "Spell",
                cond = function(self, spell)
                    if not spell() then return false end
                    local myId = Casting.GetUseableSpellId(spell) -- Adjust for possible unsubbed accounts
                    local baseItem = mq.TLO.Spell(myId).Base(1)() or 0
                    return baseItem > 0 and mq.TLO.FindItemCount(baseItem)() == 0
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "personal")
                    end
                end,
            },
            {
                name = "EarthPetItemSummon",
                type = "Spell",
                cond = function(self, spell)
                    if not spell() then return false end
                    local myId = Casting.GetUseableSpellId(spell) -- Adjust for possible unsubbed accounts
                    local baseItem = mq.TLO.Spell(myId).Base(1)() or 0
                    return baseItem > 0 and mq.TLO.FindItemCount(baseItem)() == 0
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "personal")
                    end
                end,
            },
            {
                name = "FirePetItemSummon",
                type = "Spell",
                cond = function(self, spell)
                    if not spell() then return false end
                    local myId = Casting.GetUseableSpellId(spell) -- Adjust for possible unsubbed accounts
                    local baseItem = mq.TLO.Spell(myId).Base(1)() or 0
                    return baseItem > 0 and mq.TLO.FindItemCount(baseItem)() == 0
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "personal")
                    end
                end,
            },
            {
                name = "Elemental Form",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName, false, true)
                end,
            },
            {
                name = "Fire Core",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },

        },
        ['Summon ModRods'] = {
            {
                name = "Summon Modulation Shard",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('SummonModRods') or not Casting.CanUseAA(aaName) or not Targeting.TargetIsACaster(target) then return false end
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
                cond = function(self, spell, target)
                    if not spell() then return false end
                    if Casting.CanUseAA("Summon Modulation Shard") or not Config:GetSetting('SummonModRods') or not Targeting.TargetIsACaster(target) then return false end
                    local myId = Casting.GetUseableSpellId(spell) -- Adjust for possible unsubbed accounts
                    local modRodItemId = mq.TLO.Spell(myId).Base(1)() or 0
                    return (mq.TLO.Spell(myId).Base(1)() or 0) > 0 and DanNet.query(target.CleanName(), string.format("FindItemCount[%d]", modRodItemId), 1000) == "0" and
                        (mq.TLO.Cursor.ID() or 0) == 0
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "group")
                    end
                end,
            },
            {
                name = "SelfManaRodSummon",
                type = "Spell",
                cond = function(self, spell, target, combat_state)
                    if target.ID() ~= mq.TLO.Me.ID() or not spell() then return false end
                    local myId = Casting.GetUseableSpellId(spell) -- Adjust for possible unsubbed accounts
                    local modRodItemId = mq.TLO.Spell(myId).Base(1)() or 0
                    return modRodItemId > 0 and mq.TLO.FindItemCount(modRodItemId)() == 0 and (mq.TLO.Cursor.ID() or 0) == 0 and
                        not (combat_state == "Combat" and mq.TLO.Me.PctMana() > Config:GetSetting('GroupManaPct'))
                end,
                post_activate = function(self, spell, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.Helpers.HandleItemSummon, self, spell, "personal")
                    end
                end,
            },
        },
        ['SkinDS'] = {
            {
                name = "SkinDS",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Targeting.TargetIsTanking(target) or not Casting.CastReady(spell) then return false end
                    return Casting.GroupBuffCheck(spell, target, false, true)
                end,
            },
        },
    },
    ['SpellList']         = {
        {
            name = "Default Mode",
            spells = {
                { name = "PetHealSpell",       cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "SpearNuke", },
                { name = "ChaoticNuke", },
                { name = "SwarmPet", },
                { name = "VolleyNuke", },
                { name = "BeamNuke",           cond = function(self) return Config:GetSetting('DoAEBeam') end, },
                { name = "FireDD",             cond = function(self) return not Core.GetResolvedActionMapItem('SpearNuke') or self.Helpers.ShouldUseLowLevelRotation() end, },
                { name = "BigFireDD",          cond = function(self) return self.Helpers.ShouldUseLowLevelRotation() end, },
                { name = "MagicDD",            cond = function(self) return self.Helpers.ShouldUseLowLevelRotation() end, },
                { name = "SummonedNuke",       cond = function(self) return Config:GetSetting('DoSummonedNuke') end, },
                { name = "EpicPetOrb",         cond = function(self) return Config:GetSetting('UseEpicPet') and mq.TLO.Me.Book("Summon Orb")() end, },
                { name = "MaloDebuff",         cond = function(self) return Config:GetSetting('DoMalo') and not Casting.CanUseAA("Malaise") end, },
                { name = "TwinCast", },
                { name = "SkinDS",             cond = function(self) return Config:GetSetting('DoSkinDS') or Core.IsModeActive("PetTank") end, },
                { name = "PetStanceSpell",     cond = function(self) return Core.IsModeActive("PetTank") end, },
                { name = "SurgeDS1",           cond = function(self) return Core.IsModeActive("PetTank") end, },
                { name = "SurgeDS2",           cond = function(self) return Core.IsModeActive("PetTank") end, },
                { name = "FireShroud",         cond = function(self) return Core.IsModeActive("PetTank") end, },
                { name = "GatherMana", },
                { name = "EarthPetItemSummon", },
                { name = "FirePetItemSummon", },
                { name = "FireOrbSummon", },
                { name = "ManaRodSummon",      cond = function(self) return Config:GetSetting('SummonModRods') and not Casting.CanUseAA("Summon Modulation Shard") end, },
                { name = "SelfManaRodSummon",  cond = function(self) return Config:GetSetting('SummonModRods') end, },
                { name = "AllianceBuff",       cond = function(self) return Config:GetSetting('DoAlliance') end, },
                { name = "GroupCotH", },
                { name = "SingleCotH",         cond = function() return not Casting.CanUseAA('Call of the Hero') end, },
                { name = "LongDurDmgShield", },
            },
        },
    },
    ['DefaultConfig']     = {
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
            Answer = "DPS mode will focus on dealing damage.\n" ..
                "PetTank mode will Focus on keeping the Pet alive as the main tank.",
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
            Default = false,
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
            Default = 80,
            Min = 1,
            Max = 99,
        },
        ['SelfModRod']     = {
            DisplayName = "Self Mod Rod Item",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Tooltip = "Click the modrod clicky you want to use here",
            Type = "ClickyItem",
            Default = "",
        },
        ['SummonModRods']  = {
            DisplayName = "Summon Mod Rods",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 101,
            Tooltip = "Summon Mod Rods",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['GatherManaPct']  = {
            DisplayName = "Gather Mana %",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Other Recovery",
            Tooltip = "When to use Gather Mana",
            Default = 70,
            Min = 1,
            Max = 99,
        },
        ['DoForce']        = {
            DisplayName = "Do Force",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use Force of Elements AA.",
            Default = true,
        },
        ['ElementMode']    = {
            DisplayName = "Element Mode:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Choose an element for your low level nukes. Auto prefers Fire, switching to Magic when the target is Fire immune.",
            Type = "Combo",
            ComboOptions = { 'Auto', 'Fire', 'Magic', },
            Default = 1,
            Min = 1,
            Max = 3,
        },
        ['DoSummonedNuke'] = {
            DisplayName = "Do Summoned Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Memorize and use your anti-summoned mob nuke line ('x the Unnatural').",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoAEBeam']       = {
            DisplayName = "Use Beam Spells",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            RequiresLoadoutChange = true,
            Tooltip = "**WILL BREAK MEZ** Use your Frontal AE Spells (Beam Line). **WILL BREAK MEZ**",
            Default = false,
        },
        ['DoChestClick']   = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Click your chest item",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoMalo']         = {
            DisplayName = "Cast Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Tooltip = "Do Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoAEMalo']       = {
            DisplayName = "Cast AE Malo",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Resist",
            Tooltip = "Do AE Malo Spells/AAs",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['CombatModRod']   = {
            DisplayName = "Combat Mod Rods",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 102,
            Tooltip = "Summon Mod Rods in combat if the criteria below are met.",
            Default = true,
            ConfigType = "Advanced",
        },
        ['GroupManaPct']   = {
            DisplayName = "Combat ModRod %",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 103,
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
            Index = 104,
            Tooltip = "The number of party members (including yourself) that need to be under the above mana percentage.",
            Default = 3,
            Min = 1,
            Max = 6,
            ConfigType = "Advanced",
        },
        ['DoSkinDS']       = {
            DisplayName = "Use Skin DS",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Tooltip = "Use your short duration damage shield (Skin line) on tanks during combat.",
            RequiresLoadoutChange = true,
            Default = false,
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
    },
}

return _ClassConfig
