local mq        = require('mq')
local Casting   = require("utils.casting")
local Config    = require('utils.config')
local Core      = require("utils.core")
local Globals   = require("utils.globals")
local Logger    = require("utils.logger")
local Strings   = require("utils.strings")
local Targeting = require("utils.targeting")

return {
    _version          = "1.4 - Live",
    -- 1.1 added Dicho to rotation -SCVOne
    -- 1.2 added Bfrenzy  timer 11 -SCVOne
    -- 1.3 seperated DPS into 3 sections to increase freq of attacks -SCVOne
    -- 1.4 Added toggle for Disconcering Disc, Fixed errors in burn phase with minor refactors --Algar

    _author           = "Derple, SCVOne, Algar",
    ['Modes']         = {
        'DPS',
    },
    ['Themes']        = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.22, g = 0.02, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.22, g = 0.02, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.55, g = 0.05, b = 0.05, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.36, g = 0.03, b = 0.03, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.55, g = 0.05, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.55, g = 0.05, b = 0.05, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.22, g = 0.02, b = 0.02, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.00, g = 0.35, b = 0.05, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.00, g = 0.35, b = 0.05, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.55, g = 0.05, b = 0.05, a = 1.0, }, },
        },
    },
    ['ItemSets']      = {
        ['Epic'] = {
            "Vengeful Taelosian Blood Axe",
            "Raging Taelosian Alloy Axe",
        },
        ['Coat'] = {
            "Cohort's Warmonger Coat",
        },
    },
    ['AbilitySets']   = {
        ['EndRegen'] = {
            "Hiatus V",        -- Level 126
            "Convalesce",      -- Level 121
            "Night's Calming", -- Level 116
            "Relax",           -- Level 111
            "Hiatus",          -- Level 106
            "Breather",        -- Level 101
            "Rest",            -- Level 96
            "Reprieve",        -- Level 91
            "Respite",         -- Level 86
            "Fourth Wind",     -- Level 82
            "Third Wind",      -- Level 77
            "Second Wind",     -- Level 72
        },
        ['BerAura'] = {
            "Bloodlust Aura", -- Level 70
            "Aura of Rage",   -- Level 55
        },
        ['Dicho'] = {
            "Reciprocal Rage", -- Level 121
            "Ecliptic Rage",   -- Level 116
            "Composite Rage",  -- Level 111
            "Dissident Rage",  -- Level 106
            "Dichotomic Rage", -- Level 101
        },
        ['Dfrenzy'] = {
            "Obliterating Frenzy", -- Level 127
            "Eviscerating Frenzy", -- Level 121
            "Oppressing Frenzy",   -- Level 116
            "Vindicating Frenzy",  -- Level 111
            "Mangling Frenzy",     -- Level 106
            "Demolishing Frenzy",  -- Level 101
            "Vanquishing Frenzy",  -- Level 96
            "Conquering Frenzy",   -- Level 91
            "Overwhelming Frenzy", -- Level 86
            "Overpowering Frenzy", -- Level 81
        },
        ['Bfrenzy'] = {
            "Augmented Frenzy VII", -- Level 129
            -- "Desperate Frenzy",  -- Level 125
            "Heightened Frenzy",    -- Level 124
            "Blinding Frenzy",      -- Level 120
            "Buttressed Frenzy",    -- Level 119
            "Restless Frenzy",      -- Level 115
            "Magnified Frenzy",     -- Level 114
            "Torrid Frenzy",        -- Level 110
            "Bolstered Frenzy",     -- Level 109
            "Stormwild Frenzy",     -- Level 105
            "Amplified Frenzy",     -- Level 104
            "Fearless Frenzy",      -- Level 100
            "Augmented Frenzy",     -- Level 99
            "Steel Frenzy",         -- Level 95
            "Fighting Frenzy",      -- Level 90
            "Combat Frenzy",        -- Level 85
            "Battle Frenzy",        -- Level 80
        },
        ['Dvolley'] = {
            "Obliterating Volley",  -- Level 130
            "Eviscerating Volley",  -- Level 124
            "Pulverizing Volley",   -- Level 119
            "Vindicating Volley",   -- Level 114
            "Mangling Volley",      -- Level 109
            "Demolishing Volley",   -- Level 104
            "Brutal Volley",        -- Level 99
            "Sundering Volley",     -- Level 94
            "Savage Volley",        -- Level 89
            "Eradicator's Volley",  -- Level 84
            "Decimator's Volley",   -- Level 79
            "Annihilator's Volley", -- Level 74
            "Destroyer's Volley",   -- Level 69
            "Rage Volley",          -- Level 61
        },
        ['Daxethrow'] = {
            "Obliterating Axe Throw", -- Level 128
            "Rending Axe Throw",      -- Level 123
            "Maiming Axe Throw",      -- Level 118
            "Vindicating Axe Throw",  -- Level 113
            "Mangling Axe Throw",     -- Level 108
            "Demolishing Axe Throw",  -- Level 103
            "Brutal Axe Throw",       -- Level 98
            "Spirited Axe Throw",     -- Level 93
            "Energetic Axe Throw",    -- Level 88
            "Vigorous Axe Throw",     -- Level 83
        },
        ['Daxeof'] = {
            "Axe of Trung",     -- Level 130
            "Axe of Orrak",     -- Level 125
            "Axe of Xin Diabo", -- Level 120
            "Axe of Derakor",   -- Level 115
            "Axe of Empyr",     -- Level 107
            "Axe of the Aeons", -- Level 102
            "Axe of Zurel",     -- Level 100
            "Axe of Illdaera",  -- Level 95
            "Axe of Graster",   -- Level 90
            "Axe of Rallos",    -- Level 85
        },
        ['Phantom'] = {
            "Phantom Assailant", -- Level 100
        },
        ['Alliance'] = {
            "Eviscerator's Covariance", -- Level 125
            "Conqueror's Conjunction",  -- Level 120
            "Vindicator's Coalition",   -- Level 115
            "Mangler's Covenant",       -- Level 110
            "Demolisher's Alliance",    -- Level 105
        },
        ['CheapShot'] = {
            "Slap in the Face IX", -- Level 128
            "Swift Punch",         -- Level 117
            "Rabbit Punch",        -- Level 112
            "Sucker Punch",        -- Level 107
            "Kick in the Shins",   -- Level 102
            "Punch in The Throat", -- Level 97
            "Kick in the Teeth",   -- Level 92
            "Slap in the Face",    -- Level 87
        },
        ['AESlice'] = {
            "Arcscale", -- Level 124
            "Arcshear", -- Level 119
            "Arcslash", -- Level 114
            "Arcsteel", -- Level 109
            "Arcslice", -- Level 104
            "Arcblade", -- Level 99
        },
        ['AEVicious'] = {
            "Vicious Spiral VII", -- Level 127
            "Vicious Whirl",      -- Level 117
            "Vicious Revolution", -- Level 112
            "Vicious Cycle",      -- Level 107
            "Vicious Cyclone",    -- Level 102
            "Vicious Spiral",     -- Level 97
        },
        ['FrenzyBoost'] = {
            "Augmented Frenzy VII", -- Level 129
            "Heightened Frenzy",    -- Level 124
            "Buttressed Frenzy",    -- Level 119
            "Magnified Frenzy",     -- Level 114
            "Bolstered Frenzy",     -- Level 109
            "Amplified Frenzy",     -- Level 104
            "Augmented Frenzy",     -- Level 99
        },
        ['RageStrike'] = {
            "Festering Rage VII", -- Level 127
            "Roiling Rage",       -- Level 122
            "Frothing Rage",      -- Level 117
            "Seething Rage",      -- Level 112
            "Smoldering Rage",    -- Level 107
            "Bubbling Rage",      -- Level 102
            "Festering Rage",     -- Level 98
        },
        ['SharedBuff'] = {
            "Shared Bloodlust X",  -- Level 130
            "Shared Barbarism",    -- Level 125
            "Shared Violence",     -- Level 120
            "Shared Atavism",      -- Level 115
            "Shared Ruthlessness", -- Level 110
            "Shared Cruelty",      -- Level 105
            "Shared Viciousness",  -- Level 100
            "Shared Savagery",     -- Level 95
            "Shared Brutality",    -- Level 90
            "Shared Bloodlust",    -- Level 85
        },
        ['PrimaryBurnDisc'] = {
            "Brutal Discipline",     -- Level 100
            "Sundering Discipline",  -- Level 95
            "Berserking Discipline", -- Level 75
        },
        ['CleavingDisc'] = {
            "Cleaving Acrimony Discipline", -- Level 86
            "Cleaving Anger Discipline",    -- Level 65
            "Cleaving Rage Discipline",     -- Level 54
        },
        ['FlurryDisc'] = {
            "Avenging Flurry Discipline", -- Level 89
            "Vengeful Flurry Discipline", -- Level 70
        },
        ['DisconDisc'] = {
            "Disconcerting Discipline", -- Level 104
        },
        ['ResolveDisc'] = {
            "Frenzied Resolve Discipline", -- Level 94
        },
        ['HHEBuff'] = {
            "Ancient: Cry of Chaos",     -- Level 65
            "Battle Cry of the Mastruq", -- Level 65
            "War Cry of Dravel",         -- Level 64
            "Battle Cry of Dravel",      -- Level 57
            "War Cry",                   -- Level 50
            "Battle Cry",                -- Level 30
        },
        ['CryDmg'] = {
            "Cry Carnage", -- Level 98
            "Cry Havoc",   -- Level 68
        },
        ['Tendon'] = {
            "Tendon Slice",    -- Level 121
            "Tendon Shred",    -- Level 116
            "Tendon Rip",      -- Level 111
            "Tendon Rupture",  -- Level 106
            "Tendon Tear",     -- Level 101
            "Tendon Gash",     -- Level 96
            "Tendon Slash",    -- Level 91
            "Tendon Lacerate", -- Level 86
            "Tendon Shear",    -- Level 81
            "Tendon Sever",    -- Level 76
            "Tendon Cleave",   -- Level 71
            "Tendon Cleave",   -- Level 71
        },
        ['SappingStrike'] = {
            "Draining Strikes",   -- Level 123
            "Shriveling Strikes", -- Level 113
            "Sapping Strikes",    -- Level 103
        },
        ['ReflexDisc'] = {
            "Instinctive Retaliation", -- Level 118
            "Reflexive Retaliation",   -- Level 113
        },
        ['RestFrenzy'] = {
            "Desperate Frenzy", -- Level 125
            "Blinding Frenzy",  -- Level 120
            "Restless Frenzy",  -- Level 115
        },
        ['RetaliationDodge'] = {
            "Anticipatory Retaliation", -- Level 126
            "Preemptive Retaliation",   -- Level 121
            "Primed Retaliation",       -- Level 116
            "Premature Retaliation",    -- Level 111
            "Proactive Retaliation",    -- Level 106
            "Prior Retaliation",        -- Level 101
            "Advanced Retaliation",     -- Level 96
            "Early Retaliation",        -- Level 91
        },
        ['TempleStun'] = {
            "Temple Strike XVI", -- Level 128
            "Temple Shatter",    -- Level 118
            "Temple Shatter",    -- Level 118
            "Temple Crack",      -- Level 113
            "Temple Slam",       -- Level 108
            "Temple Demolish",   -- Level 103
            "Temple Crush",      -- Level 98
            "Temple Smash",      -- Level 93
            "Temple Chop",       -- Level 88
            "Temple Bash",       -- Level 83
            "Temple Strike",     -- Level 78
            "Temple Blow",       -- Level 73
        },
        ['JarringStrike'] = {
            "Jarring Strike XVI", -- Level 129
            "Jarring Crash",      -- Level 124
            "Jarring Impact",     -- Level 119
            "Jarring Shock",      -- Level 114
            "Jarring Jolt",       -- Level 109
            "Jarring Smite",      -- Level 104
            "Jarring Crush",      -- Level 99
            "Jarring Blow",       -- Level 94
            "Jarring Slam",       -- Level 89
            "Jarring Clash",      -- Level 84
            "Jarring Smash",      -- Level 79
            "Jarring Strike",     -- Level 74
        },
        ['SnareDisc'] = {
            "Tendon Slice",     -- Level 121
            "Tendon Shred",     -- Level 116
            "Tendon Rip",       -- Level 111
            "Tendon Rupture",   -- Level 106
            "Tendon Tear",      -- Level 101
            "Tendon Gash",      -- Level 96
            "Tendon Slash",     -- Level 91
            "Tendon Lacerate",  -- Level 86
            "Tendon Shear",     -- Level 81
            "Tendon Sever",     -- Level 76
            "Tendon Cleave",    -- Level 71
            "Crippling Strike", -- Level 67
            "Leg Slice",        -- Level 54
            "Leg Cut",          -- Level 32
            "Leg Strike",       -- Level 8
        },
    },
    ['Charm']         = {
        ['Assist'] = {},
    },
    ['RotationOrder'] = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('Timer10Disc') == 2 end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
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
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'DPS2',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'DPS3',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
    },

    ['Rotations']     = {
        ['Downtime'] = {
            {
                name = "Summon Axes",
                type = "CustomFunc",
                custom_func = function(self)
                    if not Config:GetSetting('SummonAxes') then return false end

                    local AxeSkills = {
                        "Corroded Axe",
                        "Blunt Axe",
                        "Steel Axe",
                        "Bearded Axe",
                        "Mithril Axe",
                        "Balanced War Axe",
                        "Bonesplicer Axe",
                        "Fleshtear Axe",
                        "Cold Steel Cleaving Axe",
                        "Mithril Bloodaxe",
                        "Rage Axe",
                        "Bloodseeker's Axe",
                        "Battlerage Axe",
                        "Deathfury Axe",
                        "Tainted Axe of Hatred",
                        "Axe of The Destroyer",
                        "Axe of The Annihilator",
                        "Axe of The Decimator",
                        "Axe of The Eradicator",
                        "Axe of The Savage",
                        "Axe of the Sunderer",
                        "Axe of The Brute",
                        "Axe of The Demolisher",
                        "Axe of The Mangler",
                        "Axe of The Vindicator",
                        "Axe of the Conqueror",
                        "Axe of the Eviscerator",
                        "Axe of the Obliterator",
                    }

                    if not self.TempSettings.CachedAxeMap then
                        Logger.log_debug("\atCaching Axe Skill to Item Mapping...")
                        self.TempSettings.CachedAxeMap = {}
                        for _, axeSkill in ipairs(AxeSkills) do
                            local itemID = Casting.GetSummonedItemIDFromSpell(mq.TLO.Spell(axeSkill))
                            if itemID > 0 then
                                Logger.log_debug("\ayCached: \at%s\aw summons \am%d", axeSkill, itemID)
                                self.TempSettings.CachedAxeMap[itemID] = axeSkill
                            end
                        end
                    end

                    local abilitiesThatNeedAxes = {
                        { name = 'Dvolley',   count_name = 'AutoAxeCount', },
                        { name = 'Daxethrow', count_name = 'AutoAxeCount', },
                        { name = 'Daxeof',    count_name = 'AutoAxeCount', },
                        { name = 'Dicho',     count_name = 'DichoAxeCount', },
                        { name = 'SnareDisc', count_name = 'AutoAxeCount', },
                    }

                    local summonNeededItem = function(summonSkill, itemId, count)
                        local maxLoops = 10
                        while mq.TLO.FindItemCount(itemId)() < count do
                            Logger.log_debug("\ayWe need more %d because we dont have %d - using %s", itemId, count, summonSkill)
                            self.Helpers.SummonAxe(mq.TLO.Spell(summonSkill))
                            maxLoops = maxLoops - 1
                            if maxLoops <= 0 then return end
                        end
                    end

                    for _, ability in ipairs(abilitiesThatNeedAxes) do
                        local spell = self:GetResolvedActionMapItem(ability.name)
                        if spell and spell() then
                            for i = 1, 4 do
                                local requiredItemID = spell.ReagentID(i)()
                                if requiredItemID > 0 then
                                    local summonSkill = self.TempSettings.CachedAxeMap[requiredItemID]
                                    if summonSkill then
                                        Logger.log_verbose("\ayReagent(%d) for: \at%s\aw needs to use \am%s", i, ability.name, summonSkill)
                                        summonNeededItem(summonSkill, requiredItemID, Config:GetSetting(ability.count_name))
                                    end
                                end
                            end
                            for i = 1, 4 do
                                local requiredItemID = spell.NoExpendReagentID(i)()
                                if requiredItemID > 0 then
                                    local summonSkill = self.TempSettings.CachedAxeMap[requiredItemID]
                                    if summonSkill then
                                        Logger.log_verbose("\ayNoExpendReagent(%d) for: \at%s\aw needs to use \am%s", i, ability.name, summonSkill)
                                        summonNeededItem(summonSkill, requiredItemID, Config:GetSetting(ability.count_name))
                                    end
                                end
                            end
                        end
                    end
                end,
            },
            {
                name = "Communion of Blood",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctEndurance() <= 75
                end,
            },
            {
                name = "EndRegen",
                type = "Disc",
                cond = function(self, discSpell)
                    return mq.TLO.Me.PctEndurance() <= 21
                end,
            },
            {
                name = "BerAura",
                type = "Disc",
                cond = function(self, discSpell)
                    return not mq.TLO.Me.Aura(1).ID() and mq.TLO.Me.PctEndurance() > 10
                end,
            },
            {
                name = "Emergency Rage Cancel",
                type = "CustomFunc",
                custom_func = function(self)
                    if mq.TLO.Me.PctHPs() < 10 and mq.TLO.Me.Buff("Untamed Rage")() then
                        Core.DoCmd("/removebuff \"Untamed Rage\"")
                    end
                end,
            },
            {
                name = "ReflexDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
        },
        ['Snare'] = {
            {
                name = "SnareDisc",
                type = "Disc",
                cond = function(self, discSpell, target)
                    return Casting.DetSpellCheck(discSpell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Burn'] = { --This really needs to be refactored with helper functions sometime. Other prioriities atm. Algar 3/2/25
            {
                name = "PrimaryBurnDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    local discondisc = self:GetResolvedActionMapItem('DisconDisc')
                    return Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(discondisc).RankName()
                end,
            },
            {
                name = "Savage Spirit",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Juggernaut Surge",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Blood Pact",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Blinding Fury",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Silent Strikes",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Spire of the Juggernaut",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Desperation",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Focused Furious Rampage",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Untamed Rage",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Coat",
                type = "Item",
                cond = function(self, itemName)
                    return not mq.TLO.Me.PetBuff("Primal Fusion")()
                end,
            },
            {
                name = "CleavingDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return Casting.NoDiscActive() and not Casting.DiscReady(burndisc)
                end,
            },
            {
                name = "Reckless Abandon",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "Vehement Rage",
                type = "AA",
                cond = function(self, aaName)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(burndisc).RankName())
                end,
            },
            {
                name = "ResolveDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    local cleavingdisc = self:GetResolvedActionMapItem('CleavingDisc')
                    local discondisc = self:GetResolvedActionMapItem('DisconDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(discondisc).RankName())
                        and not (Casting.DiscReady(burndisc) or Casting.DiscReady(cleavingdisc))
                end,
            },
            {
                name = "FlurryDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    local burndisc = self:GetResolvedActionMapItem('PrimaryBurnDisc')
                    local cleavingdisc = self:GetResolvedActionMapItem('CleavingDisc')
                    local discondisc = self:GetResolvedActionMapItem('DisconDisc')
                    local resolvedisc = self:GetResolvedActionMapItem('ResolveDisc')
                    return (Casting.NoDiscActive() or mq.TLO.Me.ActiveDisc() == mq.TLO.Spell(discondisc).RankName())
                        and not (Casting.DiscReady(burndisc) or Casting.DiscReady(cleavingdisc) or Casting.DiscReady(resolvedisc))
                end,
            },
            {
                name = "Braxi's Howl",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "HHEBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Casting.AAReady("Braxi's Howl") and Casting.NoDiscActive() and Casting.SelfBuffCheck(discSpell)
                end,
            },
        },
        ['DPS'] = {
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoEpic') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Frenzy",
                type = "Ability",
            },
            {
                name = "Dfrenzy",
                type = "Disc",
            },
            {
                name = "Dvolley",
                type = "Disc",
            },
            {
                name = "Daxeof",
                type = "Disc",
            },
            {
                name = "Daxethrow",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('Timer10Disc') == 1 end,
            },
            {
                name = "SharedBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "RageStrike",
                type = "Disc",
            },
            {
                name = "Phantom",
                type = "Disc",
                cond = function(self, discSpell)
                    return Config:GetSetting('DoPet')
                end,
            },
            {
                name = "SappingStrike",
                type = "Disc",
            },
            {
                name = "Binding Axe",
                type = "AA",
            },
            {
                name = "Intimidation",
                type = "Ability",
                load_cond = function(self) return Casting.AARank("Intimidation") > 1 end,
            },
            {
                name = "AESlice",
                type = "Disc",
                cond = function(self, discSpell)
                    return Config:GetSetting('DoAoe')
                end,
            },
            {
                name = "Alliance",
                type = "Spell",
                cond = function(self, spell)
                    return Config:GetSetting('DoAlliance') and Casting.CanAlliance() and
                        not Casting.TargetHasBuff(spell)
                end,
            },
            {
                name = "BraxiChain",
                type = "CustomFunc",
                custom_func = function(self)
                    if not Casting.AAReady("Braxi's Howl") then return false end
                    local ret = false
                    ret = ret or Casting.UseAA("Braxi's Howl", Globals.AutoTargetID)
                    ret = ret or Casting.UseDisc(self.ResolvedActionMap['Dicho'], Globals.AutoTargetID)

                    return ret
                end,
            },
            {
                name = "DisconDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    if not Config:GetSetting('DoDisconDisc') then return false end
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Bloodfury",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.DiscReady(self.ResolvedActionMap['FrenzyBoost']) and mq.TLO.Me.PctHPs() >= 90
                end,
            },
            {
                name = "FrenzyBoost",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "CryDmg",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.SelfBuffCheck(discSpell)
                end,
            },
            {
                name = "Communion of Blood",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.PctEndurance() <= 75
                end,
            },
        },
        ['DPS2'] = {
            {
                name = "Battle Leap",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoBattleLeap') and not Casting.IHaveBuff("Battle Leap Warcry") and
                        not Casting.IHaveBuff("Group Bestial Alignment")
                        and not mq.TLO.Me.HeadWet() --Stops Leap from launching us above the water's surface
                end,
            },
            {
                name = "Drawn to Blood",
                type = "AA",
                cond = function(self, aaName)
                    return Targeting.GetTargetDistance() > 15
                end,
            },
        },
        ['DPS3'] = {
            {
                name = "Dicho",
                type = "Disc",
            },
            {
                name = "Bfrenzy",
                type = "Disc",
            },
        },
    },
    ['Helpers']       = {
        SummonAxe = function(axeDisc)
            if not axeDisc or not axeDisc() then return false end
            Logger.log_verbose("\aySummonAxe(): Checking if %s is ready.", axeDisc.Name())
            if not Casting.DiscReady(axeDisc) then return false end
            Logger.log_verbose("\aySummonAxe(): Checking AutoAxeAcount")
            if Config:GetSetting('AutoAxeCount') == 0 then return false end
            if mq.TLO.FindItemCount(axeDisc)() > Config:GetSetting('AutoAxeCount') then return false end

            Logger.log_verbose("\aySummonAxe(): Checking For Reagents")
            if mq.TLO.FindItemCount(axeDisc.ReagentID(1)())() == 0 then return false end

            if mq.TLO.Cursor.ID() ~= nil then Core.DoCmd("/autoinv") end
            local ret = Casting.UseDisc(axeDisc, mq.TLO.Me.ID())
            Logger.log_verbose("\aySummonAxe(): Summoning the Axe.")
            mq.delay(500, function() return mq.TLO.Cursor.ID() ~= nil end)
            while mq.TLO.Cursor.ID() ~= nil do Core.DoCmd("/autoinv") end
            return ret
        end,
        PreEngage = function(target)
            if not target or not target() then return end
            local openerAbility = Core.GetResolvedActionMapItem('CheapShot')

            if not openerAbility then return end

            Logger.log_debug("\ayPreEngage(): Testing Opener ability = %s", openerAbility or "None")

            if openerAbility and mq.TLO.Me.CombatAbilityReady(openerAbility)() and mq.TLO.Me.PctEndurance() >= 5 and Config:GetSetting("DoOpener") and Targeting.GetTargetDistance() < 50 then
                Casting.UseDisc(openerAbility, target.ID())
                Logger.log_debug("\agPreEngage(): Using Opener ability = %s", openerAbility or "None")
            else
                Logger.log_debug("\arPreEngage(): NOT using Opener ability = %s, DoOpener = %s, Distance to Target = %d, Endurance = %d", openerAbility or "None",
                    Strings.BoolToColorString(Config:GetSetting("DoOpener")), Targeting.GetTargetDistance(), mq.TLO.Me.PctEndurance() or 0)
            end
        end,
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
            FAQ = "What do the different modes do?",
            Answer = "Currently Berserkers Only have DPS mode.",
        },
        ['DoEpic']          = {
            DisplayName = "Do Epic",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Tooltip = "Enable using your epic clicky",
            Default = true,
        },
        ['DoOpener']        = {
            DisplayName = "Use Openers",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Use Opening Arrow Shot Silent Shot Line.",
            Default = true,
        },
        ['DoBattleLeap']    = {
            DisplayName = "Do Battle Leap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Tooltip = "Enable using Battle Leap",
            Default = true,
        },
        ['DoAoe']           = {
            DisplayName = "Do AoE",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Tooltip = "Enable using AoE Abilities",
            Default = true,
        },
        ['SummonAxes']      = {
            DisplayName = "Summon Axes",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 101,
            Tooltip = "Enable Summon Axes",
            Default = true,
        },
        ['AutoAxeCount']    = {
            DisplayName = "Auto Axe Count",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 102,
            Tooltip = "Summon more Primary Axes when you hit [x] left.",
            Default = 100,
            Min = 0,
            Max = 600,
        },
        ['DichoAxeCount']   = {
            DisplayName = "Auto Dicho Axe Count",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 104,
            Tooltip = "Summon more Dicho Axes when you hit [x] left.",
            Default = 100,
            Min = 0,
            Max = 600,
        },
        ['SummonDichoAxes'] = {
            DisplayName = "Summon Dicho Axes",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 103,
            Tooltip = "Enable Summon Dicho Axes",
            Default = true,
        },
        ['DoDisconDisc']    = {
            DisplayName = "Do Discon Disc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Tooltip = "Enable using Disconcerting Discipline",
            Default = true,
        },
        ['Timer10Disc']     = {
            DisplayName = "Timer 10 Disc Choice",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Choose between your Axe Throw Disc or Snare Disc (Leg/Tendon line). The timer is shared.",
            Type = "Combo",
            ComboOptions = { 'Throw Disc', 'Snare Disc', },
            Default = 1,
            Min = 1,
            Max = 2,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']      = {
            DisplayName = "Snare Max Mob Count",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro. Helpful for AoE groups.",
            Default = 3,
            Min = 1,
            Max = 99,
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
