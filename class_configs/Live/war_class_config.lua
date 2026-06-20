local mq          = require('mq')
local Set         = require('mq.set')
local Casting     = require("utils.casting")
local Combat      = require("utils.combat")
local Config      = require('utils.config')
local Core        = require("utils.core")
local Globals     = require("utils.globals")
local ItemManager = require("utils.item_manager")
local Logger      = require("utils.logger")
local Targeting   = require("utils.targeting")


local _ClassConfig = {
    _version          = "2.2 - Live",
    _author           = "Algar, Derple",
    ['ModeChecks']    = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
    },
    ['Modes']         = {
        'Tank',
        'DPS',
    },
    ['Themes']        = {
        ['Tank'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.09, g = 0.10, b = 0.11, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.09, g = 0.10, b = 0.11, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.22, g = 0.25, b = 0.28, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.15, g = 0.17, b = 0.19, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.22, g = 0.25, b = 0.28, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.22, g = 0.25, b = 0.28, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.09, g = 0.10, b = 0.11, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.55, g = 0.60, b = 0.65, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.55, g = 0.60, b = 0.65, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.22, g = 0.25, b = 0.28, a = 1.0, }, },
        },
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.14, g = 0.06, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.14, g = 0.06, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.35, g = 0.15, b = 0.10, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.23, g = 0.10, b = 0.07, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.35, g = 0.15, b = 0.10, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.35, g = 0.15, b = 0.10, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.14, g = 0.06, b = 0.04, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.80, g = 0.20, b = 0.15, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.80, g = 0.20, b = 0.15, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.35, g = 0.15, b = 0.10, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Kreljnok's Sword of Eternal Power",
            "Champion's Sword of Eternal Power",
        },
        ['OoW_Chest'] = {
            "Armsmaster's Breastplate",
            "Gladiator's Plate Chestguard of War",
        },
        ['Coating'] = {
            "Spirit Drinker's Coating",
            "Blood Drinker's Coating",
        },
    },
    ['AbilitySets']   = {
        ['StandDisc'] = {
            "Final Stand Discipline VI",    -- Level 128
            "Climactic Stand",              -- Level 123
            "Resolute Stand",               -- Level 118
            "Ultimate Stand Discipline",    -- Level 113
            "Culminating Stand Discipline", -- Level 108
            "Last Stand Discipline",        -- Level 98
            "Final Stand Discipline",       -- Level 72
            -- "Stonewall Discipline",      -- Level 65
            "Defensive Discipline",         -- Level 55
        },
        ['Fortitude'] = {
            "Fortitude Discipline", -- Level 59
        },
        ['AbsorbDisc'] = {
            "Finish the Fight",  -- Level 112
            "Pain Doesn't Hurt", -- Level 102
            "No Time to Bleed",  -- Level 96
        },
        ['Flash'] = {
            "Flash of Anger", -- Level 87
        },
        ['ShieldHit'] = {
            "Shield Split",    -- Level 125
            "Shield Rupture",  -- Level 120
            "Shield Splinter", -- Level 115
            "Shield Sunder",   -- Level 110
            "Shield Break",    -- Level 104
            "Shield Topple",   -- Level 83
        },
        ['GroupACBuff'] = {
            "Field Armorer X",      -- Level 130
            "Field Bulwark",        -- Level 125
            "Full Moon's Champion", -- Level 120
            "Paragon Champion",     -- Level 115
            "Field Champion",       -- Level 110
            "Field Protector",      -- Level 105
            "Field Guardian",       -- Level 100
            "Field Defender",       -- Level 95
            "Field Outfitter",      -- Level 90
            "Field Armorer",        -- Level 85
        },
        ['GroupDodgeBuff'] = {
            "Commanding Voice", -- Level 68
        },
        ['DefenseACBuff'] = {
            "Bracing Defense X",  -- Level 130
            "Vigorous Defense",   -- Level 125
            "Primal Defense",     -- Level 120
            "Courageous Defense", -- Level 115
            "Resolute Defense",   -- Level 110
            "Stout Defense",      -- Level 105
            "Steadfast Defense",  -- Level 100
            "Stalwart Defense",   -- Level 95
            "Staunch Defense",    -- Level 90
            "Bracing Defense",    -- Level 85
        },
        ['DichoShield'] = {
            "Reciprocal Shield", -- Level 121
            "Ecliptic Shield",   -- Level 116
            "Composite Shield",  -- Level 111
            "Dissident Shield",  -- Level 106
            "Dichotomic Shield", -- Level 101
        },
        ['AERoar'] = {           --does not appear to be worthwhile, very limited level range and low hate value
            "Roar of Challenge", -- Level 93
            "Rallying Roar",     -- Level 88
        },
        ['SelfBuffAE'] = {
            "Wade into Conflict", -- Level 119
            "Wade into Battle",   -- Level 99
        },
        ['SelfBuffSingle'] = {
            "Determined Reprisal", -- Level 97
        },
        ['HealHateAE'] = {
            "Paradoxical Expanse", -- Level 122
            "Penumbral Expanse",   -- Level 117
            "Confluent Expanse",   -- Level 112
            "Concordant Expanse",  -- Level 107
            "Harmonious Expanse",  -- Level 102
        },
        ['HealHateSingle'] = {
            "Paradoxical Precision", -- Level 123
            "Penumbral Precision",   -- Level 118
            "Confluent Precision",   -- Level 113
            "Concordant Precision",  -- Level 108
            "Harmonious Precision",  -- Level 103
        },
        ['AEBlades'] = {
            "Cyclone Blades XIV",  -- Level 127
            "Spiraling Blades",    -- Level 124
            "Hurricane Blades",    -- Level 119
            "Tempest Blades",      -- Level 114
            "Dragonstrike Blades", -- Level 109
            "Stormstrike Blades",  -- Level 104
            "Stormwheel Blades",   -- Level 99
            "Cyclonic Blades",     -- Level 94
            "Wheeling Blades",     -- Level 89
            "Maelstrom Blade",     -- Level 84
            "Whorl Blade",         -- Level 79
            "Vortex Blade",        -- Level 74
            "Cyclone Blade",       -- Level 69
            "Whirlwind Blade",     -- Level 61
        },
        ['AddHate1'] = {
            "Bazu Roar X",           -- Level 126
            "Mortimus' Roar",        -- Level 121
            "Namdrows' Roar",        -- Level 116
            "Kragek's Roar",         -- Level 111
            "Kluzen's Roar",         -- Level 106
            "Cyclone Roar",          -- Level 101
            "Krondal's Roar",        -- Level 96
            "Grendlaen Roar",        -- Level 91
            "Bazu Roar",             -- Level 86
            "Bazu Bluster",          -- Level 81
            "Bazu Bellow",           -- Level 69
            "Ancient: Chaos Cry",    -- Level 65
            "Bellow of the Mastruq", -- Level 65
            "Incite",                -- Level 63
            "Berate",                -- Level 56
            "Bellow",                -- Level 52
            "Provoke",               -- Level 20
        },
        ['AddHate2'] = {
            "Harassing Shout VII", -- Level 128
            "Distressing Shout",   -- Level 123
            "Twilight Shout",      -- Level 118
            "Oppressing Shout",    -- Level 113
            "Burning Shout",       -- Level 108
            "Tormenting Shout",    -- Level 103
            "Harassing Shout",     -- Level 98
        },
        ['AbsorbTaunt'] = {
            "Provoke XIX", -- Level 128
            "Infuriate",   -- Level 123
            "Bristle",     -- Level 118
            "Aggravate",   -- Level 113
            "Slander",     -- Level 108
            "Insult",      -- Level 103
            "Ridicule",    -- Level 98
            "Scorn",       -- Level 95
            "Scoff",       -- Level 90
            "Jeer",        -- Level 85
            "Sneer",       -- Level 80
            "Scowl",       -- Level 75
            "Mock",        -- Level 70
        },
        ['StrikeDisc'] = {
            "Opportunistic Strike IX", -- Level 129
            "Decisive Strike",         -- Level 124
            "Exploitive Strike",       -- Level 119
            "Precision Strike",        -- Level 114
            "Cunning Strike",          -- Level 109
            "Calculated Strike",       -- Level 104
            "Vital Strike",            -- Level 93
            "Strategic Strike",        -- Level 88
            "Opportunistic Strike",    -- Level 78
        },
        ['EndRegen'] = {
            "Hiatus V",        -- Level 126
            "Convalesce",      -- Level 121
            "Night's Calming", -- Level 116
            "Hiatus",          -- Level 106
            "Breather",        -- Level 101
            "Rest",            -- Level 96
            "Reprieve",        -- Level 91
            "Respite",         -- Level 86
            "Fourth Wind",     -- Level 82
            "Third Wind",      -- Level 77
            "Second Wind",     -- Level 72
        },
        ['AuraBuff'] = {
            "Champion's Aura", -- Level 70
            "Myrmidon's Aura", -- Level 55
        },
        ['Attention'] = {
            "Unquestioned Attention",  -- Level 127
            "Unconditional Attention", -- Level 122
            "Unrelenting Attention",   -- Level 117
            "Unending Attention",      -- Level 112
            "Unyielding Attention",    -- Level 107
            "Unflinching Attention",   -- Level 102
            "Unbroken Attention",      -- Level 97
            "Undivided Attention",     -- Level 92
        },
        ['AggroPet'] = {
            "Phantom Aggressor", -- Level 100
        },
        ['Onslaught'] = {
            "Brightfeld's Onslaught Discipline", -- Level 117
            "Brutal Onslaught Discipline",       -- Level 74
            "Savage Onslaught Discipline",       -- Level 68
        },
        ['RuneShield'] = {
            "Warrior's Auspice VII", -- Level 129
            "Warrior's Resolve",     -- Level 124
            "Warrior's Aegis",       -- Level 119
            "Warrior's Rampart",     -- Level 114
            "Warrior's Bastion",     -- Level 109
            "Warrior's Bulwark",     -- Level 104
            "Warrior's Auspice",     -- Level 99
        },
        ['TongueDisc'] = {
            "Razor Tongue Discipline",  -- Level 122
            "Biting Tongue Discipline", -- Level 107
            "Barbed Tongue Discipline", -- Level 94
        },
        ['ChargeDisc'] = {
            "Charge Discipline", -- Level 53
        },
        ['OffensiveDisc'] = {
            "Offensive Discipline", -- Level 97
        },
        ['MightyStrike'] = {
            "Mighty Strike Discipline", -- Level 54
        },
    },
    ['Helpers']       = {
        --function to make sure we don't have non-hostiles in range before we use AE damage or non-taunt AE hate abilities

        --function to determine if we have enough mobs in range to use a defensive disc
        DefensiveDiscCheck = function(printDebug)
            local xtCount = mq.TLO.Me.XTarget() or 0
            if xtCount < Config:GetSetting('DiscCount') then return false end
            local haters = Set.new({})
            for i = 1, xtCount do
                local xtarg = mq.TLO.Me.XTarget(i)
                if xtarg and xtarg.ID() > 0 and ((xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater")) and (xtarg.Distance() or 999) <= 30 then
                    if printDebug then
                        Logger.log_verbose("DefensiveDiscCheck(): XT(%d) Counting %s(%d) as a hater in range.", i, xtarg.CleanName() or "None", xtarg.ID())
                    end
                    haters:add(xtarg.ID())
                end
                if #haters:toList() >= Config:GetSetting('DiscCount') then return true end -- no need to keep counting once this threshold has been reached
            end
            return false
        end,
        DiscOverwriteCheck = function(self)
            local defenseBuff = Core.GetResolvedActionMapItem('DefenseACBuff')
            if mq.TLO.Me.ActiveDisc.ID() and mq.TLO.Me.ActiveDisc.Name() ~= (defenseBuff and defenseBuff.RankName() or "None") then return false end
            return true
        end,
        BurnDiscCheck = function(self)
            if mq.TLO.Me.ActiveDisc.Name() == "Fortitude Discipline" or mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart') then return false end
            local burnDisc = { "Onslaught", "MightyStrike", "ChargeDisc", "OffensiveDisc", }
            for _, buffName in ipairs(burnDisc) do
                local resolvedDisc = self:GetResolvedActionMapItem(buffName)
                if resolvedDisc and resolvedDisc.RankName() == mq.TLO.Me.ActiveDisc.Name() then return false end
            end
            return true
        end,
    },
    ['Charm']         = {
        ['Assist'] = {
            { name = "Attention",      type = "Disc", },
            { name = "Blast of Anger", type = "AA", },
            { name = "Taunt",          type = "Ability", },
            { name = "AbsorbTaunt",    type = "Disc", },
            { name = "AddHate1",       type = "Disc", cond = function(self, discSpell, target) return Casting.DetSpellCheck(discSpell, target) end, },
            { name = "AddHate2",       type = "Disc", },
        },
    },
    ['RotationOrder'] = {
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Actions to lock down xtarg haters
            name = 'HateTools(AggroTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('TankAggroScan') end,
            targetId = function(self) return Targeting.CheckForAggroTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyLockout') then return false end
                return combat_state == "Combat"
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'HateTools(AutoTarget)',
            state = 1,
            steps = 1,
            load_cond = function() return Core.IsTanking() end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() > Config:GetSetting('EmergencyLockout')
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'AEHateTools',
            state = 1,
            steps = 1,
            timer = 1, -- Don't check this more often than once a second to avoid blowing every ability at once (aggro takes time to update)
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() and Config:GetSetting('DoAETaunt') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Combat.AETauntCheck(true) and mq.TLO.Me.PctHPs() > Config:GetSetting('EmergencyLockout')
            end,
        },
        { --Defensive actions triggered by low HP
            name = 'EmergencyDefenses',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
            end,
        },
        { --Dynamic weapon swapping if UseBandolier is toggled
            name = 'Weapon Management',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('UseBandolier') end,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        { --Defensive actions used proactively to prevent emergencies
            name = 'Defenses',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                --need to look at rotation and decide if it should fire during emergencies. leaning towards no
                return combat_state == "Combat" and Core.IsTanking() and (mq.TLO.Me.PctHPs() < Config:GetSetting('EmergencyStart') or
                    Globals.AutoTargetIsNamed or self.Helpers.DefensiveDiscCheck(true))
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck() and mq.TLO.Me.PctHPs() > Config:GetSetting('EmergencyLockout') and Core.CombatActionsCheck()
            end,
        },
        {
            name = 'Buffs',
            state = 1,
            steps = 1,
            targetId = function(self)
                return mq.TLO.Target.ID() == Globals.AutoTargetID and { Globals.AutoTargetID, } or { mq.TLO.Me.ID(), }
            end,
            cond = function(self, combat_state)
                return combat_state == "Combat" or (combat_state == "Downtime" and Casting.OkayToBuff())
            end,
        },
        { --DPS and Utility discs
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() > Config:GetSetting('EmergencyLockout') and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']     = {
        ['Downtime'] = {
            {
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "AuraBuff",
                type = "Disc",
                active_cond = function(self, discSpell)
                    return Casting.AuraActiveByName(discSpell.RankName.Name())
                end,
                cond = function(self, discSpell)
                    return not mq.TLO.Me.Aura(1).ID()
                end,
            },
            { --Charm Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Charm").Name() or "CharmClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCharmClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
        ['HateTools(AggroTarget)'] = {
            {
                name = "Attention",
                type = "Disc",
            },
            {
                name = "Blast of Anger",
                type = "AA",
            },
            {
                name = "Taunt",
                type = "Ability",
            },
            {
                name = "AbsorbTaunt",
                type = "Disc",
            },
            {
                name = "AddHate1",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "AddHate2",
                type = "Disc",
            },
        },
        ['HateTools(AutoTarget)'] = {
            {
                name = "Attention",
                type = "Disc",
            },
            {
                name = "Blast of Anger",
                type = "AA",
            },
            {
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro()
                end,
            },
            {
                name = "AbsorbTaunt",
                type = "Disc",
            },
            {
                name = "AddHate1",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.DetSpellCheck(discSpell)
                end,
            },
            {
                name = "AddHate2",
                type = "Disc",
            },
        },
        ['AEHateTools'] = {
            {
                name = "Area Taunt",
                type = "AA",
            },
            {
                name = "SelfBuffAE",
                type = "Disc",
            },
            {
                name = "Rampage",
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting("DoAEDamage")
                end,
            },
        },
        ['EmergencyDefenses'] = {
            --Note that in Tank Mode, defensive discs are preemptively cycled on named in the (non-emergency) Defenses rotation
            --Abilities should be placed in order of lowest to highest triggered HP thresholds
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self, aaName)
                    return mq.TLO.Me.PctHPs() < 25
                end,
            },
            {
                name = "Fortitude",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyLockout') and not Casting.IHaveBuff("Flash of Anger") and
                        not Casting.IHaveBuff("Blade Whirl")
                end,
            },
            {
                name = "Flash",
                type = "Disc",
                cond = function(self, discSpell)
                    return not mq.TLO.Me.ActiveDisc.Name() ~= "Fortitude Discipline" and not Casting.IHaveBuff("Blade Whirl")
                end,
            },
            {
                name = "Warlord's Tenacity",
                type = "AA",
            },
            {
                name = "Warlord's Resurgence",
                type = "AA",
            },
            {
                name = "RuneShield",
                type = "Disc",
            },
            {
                name = "Mark of the Mage Hunter",
                type = "AA",
            },
            { --here for use in emergencies regarldless of ability staggering below
                name = "StandDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Core.IsTanking() and self.Helpers.DiscOverwriteCheck(self)
                end,
            },
        },
        ['Weapon Management'] = {
            {
                name = "Equip Shield",
                type = "CustomFunc",
                active_cond = function(self, target)
                    return mq.TLO.Me.Bandolier("Shield").Active()
                end,
                cond = function()
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("Shield") end,
            },
            {
                name = "Equip DW",
                type = "CustomFunc",
                active_cond = function(self, target)
                    return mq.TLO.Me.Bandolier("DW").Active()
                end,
                cond = function()
                    if mq.TLO.Me.Bandolier("DW").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('EquipDW') and not (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("DW") end,
            },
        },
        ['Defenses'] = {
            --helper function(s) for ability stacking checks may reduce code, but this is functional.
            { --shares effect with modern chest click
                name = "DichoShield",
                type = "Disc",
                cond = function(self, discSpell)
                    local chestClicky = Casting.GetClickySpell(mq.TLO.Me.Inventory("Chest").Name())
                    return not Casting.IHaveBuff(chestClicky or "None")
                end,
            },
            { --shares effect with Dicho Shield --Chest Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Chest").Name() or "ChestClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoChestClick') or not Casting.ItemHasClicky(itemName) then return false end
                    local dichoShield = Core.GetResolvedActionMapItem('DichoShield')
                    return not mq.TLO.Me.Buff(dichoShield)() and Casting.SelfBuffItemCheck(itemName)
                end,
            },
            { --shares effect with OoW Chest and Warlord's Bravery, offset from AbsorbDisc for automation flow/coverage
                name = "StandDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    local absorbDisc = Core.GetResolvedActionMapItem('AbsorbDisc')
                    return not mq.TLO.Me.Song(absorbDisc)() and self.Helpers.DiscOverwriteCheck(self)
                end,
            },
            { --offset from StandDisc for automation flow/coverage
                name = "AbsorbDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    local standDisc = self:GetResolvedActionMapItem('StandDisc')
                    return (not standDisc or mq.TLO.Me.ActiveDisc.Name() ~= standDisc.RankName())
                end,
            },
            { --shares effect with StandDisc and Warlord's Bravery, offset from AbsorbDisc for automation flow/coverage
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName)
                    local absorbDisc = Core.GetResolvedActionMapItem('AbsorbDisc')
                    local standDisc = Core.GetResolvedActionMapItem('StandDisc')
                    return (not standDisc or mq.TLO.Me.ActiveDisc.Name() ~= standDisc.RankName()) and not mq.TLO.Me.Song(absorbDisc)()
                end,
            },
            { --See above entries for notes
                name = "Warlord's Bravery",
                type = "AA",
                cond = function(self, aaName)
                    local absorbDisc = Core.GetResolvedActionMapItem('AbsorbDisc')
                    local standDisc = Core.GetResolvedActionMapItem('StandDisc')
                    return (not standDisc or mq.TLO.Me.ActiveDisc.Name() ~= standDisc.RankName()) and mq.TLO.Me.Song(absorbDisc)() and not Casting.IHaveBuff("Guardian's Boon") and
                        not Casting.IHaveBuff("Guardian's Bravery")
                end,
            },
            {
                name = "Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            { --incredibly weak at high level, but low opportunity cost for use and optional
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    return Config:GetSetting('DoEpic')
                end,
            },
        },
        ['Buffs'] = {
            {
                name = "GroupACBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "GroupDodgeBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "DefenseACBuff",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Brace for Impact",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "HealHateAE",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() and Config:GetSetting('DoAETaunt') end,
                cond = function(self, discSpell, target)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "HealHateSingle",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() and not Config:GetSetting('DoAETaunt') end,
                cond = function(self, discSpell, target)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Blade Guardian",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Burn'] = {
            {
                name = "Spire of the Warlord",
                type = "AA",
            },
            {
                name = "Imperator's Command",
                type = "AA",
            },
            {
                name = "Onslaught",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Core.IsTanking() and self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "MightyStrike",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Core.IsTanking() and self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "OffensiveDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Core.IsTanking() and self.Helpers.BurnDiscCheck(self)
                end,
            },
            {
                name = "Vehement Rage",
                type = "AA",
                cond = function(self, aaName)
                    return not Core.IsTanking()
                end,
            },
            {
                name = "Rage of Rallos Zek",
                type = "AA",
            },
            {
                name = "Warlord's Fury",
                type = "AA",
                cond = function(self, aaName, target)
                    local dichoShield = Core.GetResolvedActionMapItem('DichoShield')
                    return Core.IsTanking() and not mq.TLO.Me.Buff(dichoShield)
                end,
            },
            {
                name = "Wars Sheol's Heroic Blade",
                type = "AA",
            },
            {
                name = "SelfBuffSingle",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() and not Config:GetSetting('DoAETaunt') end,
            },
            {
                name = "TongueDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Core.IsTanking()
                end,
            },
            {
                name = "Resplendent Glory",
                type = "AA",
                cond = function(self, aaName)
                    return Core.IsTanking()
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
        },
        ['Combat'] = {
            {
                name = "ShieldHit",
                type = "Disc",
            },
            {
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Battle Leap",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoBattleLeap') then return false end
                    return not mq.TLO.Me.HeadWet() --Stops Leap from launching us above the water's surface
                end,
            },
            {
                name = "Gut Punch",
                type = "AA",
                cond = function(self, aaName, target)
                    return Core.IsTanking()
                end,
            },
            {
                name = "Knee Strike",
                type = "AA",
            },
            {
                name = "Rampage",
                type = "AA",
                load_cond = function(self) return not (Core.IsTanking() and Config:GetSetting('DoAETaunt')) end,
                cond = function(self, aaName, target)
                    if not Config:GetSetting("DoAEDamage") then return false end
                    return Combat.AETargetCheck(true)
                end,
            },
            {
                name = "Call of Challenge",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting('DoSnare') then return false end
                    return Casting.DetAACheck(aaName) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "Press the Attack",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Config:GetSetting("DoPress") then return false end
                    return Core.IsTanking()
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Core.ShieldEquipped()
                end,
            },
            {
                name = "Slam",
                type = "Ability",
            },
            {
                name = "Kick",
                type = "Ability",
            },
            -- { --todo:homework
            --     name = "Disarm",
            --     type = "Ability",
            --     cond = function(self, abilityName)
            --         return mq.TLO.Me.AbilityReady(abilityName)() and
            --             Targeting.GetTargetDistance() < 15
            --     end,
            -- },
            {
                name = "StrikeDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Targeting.GetTargetPctHPs() <= 20
                end,
            },
            {
                name = "DefenseACBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Core.IsTanking() and Casting.NoDiscActive()
                end,
            },
        },
    },
    ['DefaultConfig'] = {
        ['Mode']             = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What do the different Modes Do?",
            Answer = "Warriors have a Tank mode and a DPS Mode.",
        },
        ['DoBattleLeap']     = {
            DisplayName = "Do Battle Leap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Do Battle Leap",
            Default = true,
        },
        ['DoPress']          = {
            DisplayName = "Do Press the Attack",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Tooltip = "Use the Press to Attack stun/push AA.",
            Default = false,
        },
        ['DoSnare']          = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Tooltip = "Enable casting Snare abilities.",
            Default = true,
        },
        ['DoVetAA']          = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 108,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoAETaunt']        = {
            DisplayName = "Do AE Taunts",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use AE hatred Discs and AA.",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why am I using AE damage when there are mezzed mobs around?",
            Answer = "It is not currently possible to properly determine Mez status without direct Targeting. If you are mezzing, consider turning this option off.",
        },

        --Defenses
        ['DiscCount']        = {
            DisplayName = "Def. Disc. Count",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 101,
            Tooltip = "Number of mobs around you before you use preemptively use Defensive Discs.",
            Default = 4,
            Min = 1,
            Max = 10,
            ConfigType = "Advanced",
        },
        ['EmergencyStart']   = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 102,
            Tooltip = "Your HP % before we begin to use emergency abilities.",
            Default = 55,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['EmergencyLockout'] = {
            DisplayName = "Emergency Only",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 103,
            Tooltip = "Your HP % before standard DPS rotations are cut in favor of emergency abilities.",
            Default = 35,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },

        --Equipment
        ['DoChestClick']     = {
            DisplayName = "Do Chest Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 101,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
        },
        ['DoCharmClick']     = {
            DisplayName = "Do Charm Click",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your charm for Geomantra.",
            Default = false,
        },
        ['DoCoating']        = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 103,
            Tooltip = "Click your Blood/Spirit Drinker's Coating when defenses are triggered.",
            Default = false,
        },
        ['UseBandolier']     = {
            DisplayName = "Dynamic Weapon Swap",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 101,
            Tooltip = "Enable 1H+S/2H swapping based off of current health. ***YOU MUST HAVE BANDOLIER ENTRIES NAMED \"Shield\" and \"DW\" TO USE THIS FUNCTION.***",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['EquipShield']      = {
            DisplayName = "Equip Shield",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 102,
            Tooltip = "Under this HP%, you will swap to your \"Shield\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['EquipDW']          = {
            DisplayName = "Equip DW",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 103,
            Tooltip = "Over this HP%, you will swap to your \"DW\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 75,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['NamedShieldLock']  = {
            DisplayName = "Shield on Named",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 104,
            Tooltip = "Keep Shield equipped for mobs detected as 'named' by RGMercs (see Named tab).",
            Default = true,
            FAQ = "Why does my WAR switch to a Shield on puny gray named?",
            Answer = "The Shield on Named option doesn't check levels, so feel free to disable this setting (or Bandolier swapping entirely) if you are farming fodder.",
        },
        ['DoEpic']           = {
            DisplayName = "Do Epic",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 104,
            Tooltip = "Click your Epic Weapon when defenses are triggered.",
            Default = false,
        },
    },
    ['ClassFAQ']      = {
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
