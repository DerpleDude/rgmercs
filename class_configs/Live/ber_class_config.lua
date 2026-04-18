local mq        = require('mq')
local Config    = require('utils.config')
local Globals   = require("utils.globals")
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Strings   = require("utils.strings")
local Logger    = require("utils.logger")

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
            "Hiatus V", -- 126
            "Second Wind",
            "Third Wind",
            "Fourth Wind",
            "Respite",
            "Reprieve",
            "Rest",
            "Breather",
            "Hiatus",
            "Relax",
            "Night's Calming",
            "Convalesce",
        },
        ['BerAura'] = {
            "Aura of Rage",
            "Bloodlust Aura",
        },
        ['Dicho'] = {
            "Dichotomic Rage",
            "Dissident Rage",
            "Composite Rage",
            "Ecliptic Rage",
            "Reciprocal Rage",
        },
        ['Dfrenzy'] = {
            "Obliterating Frenzy III", -- 127
            "Eviscerating Frenzy",
            "Oppressing Frenzy",
            "Overpowering Frenzy",
            "Overwhelming Frenzy",
            "Conquering Frenzy",
            "Vanquishing Frenzy",
            "Demolishing Frenzy",
            "Mangling Frenzy",
            "Vindicating Frenzy",
        },
        ['Bfrenzy'] = {
            "Augmented Frenzy VII", -- 129
            "Torrid Frenzy",
            "Steel Frenzy",
            "Augmented Frenzy",
            "Stormwild Frenzy",
            "Fighting Frenzy",
            "Combat Frenzy",
            "Restless Frenzy",
            "Battle Frenzy",
            "Amplified Frenzy",
            "Fearless Frenzy",
            "Buttressed Frenzy",
            "Blinding Frenzy",
            "Heightened Frenzy",
            -- "Desperate Frenzy",
            "Magnified Frenzy",
            "Bolstered Frenzy",
        },
        ['Dvolley'] = {
            "Obliterating Volley", -- 130
            "Rage Volley",
            "Destroyer's Volley",
            "Annihilator's Volley",
            "Decimator's Volley",
            "Eradicator's Volley",
            "Savage Volley",
            "Sundering Volley",
            "Brutal Volley",
            "Demolishing Volley",
            "Mangling Volley",
            "Vindicating Volley",
            "Pulverizing Volley",
            "Eviscerating Volley",
        },
        ['Daxethrow'] = {
            "Obliterating Axe Throw", -- 128
            "Maiming Axe Throw",
            "Vigorous Axe Throw",
            "Energetic Axe Throw",
            "Spirited Axe Throw",
            "Brutal Axe Throw",
            "Demolishing Axe Throw",
            "Mangling Axe Throw",
            "Vindicating Axe Throw",
            "Rending Axe Throw",
        },
        ['Daxeof'] = {
            "Axe of Trung", -- 130
            "Axe of Rallos",
            "Axe of Graster",
            "Axe of Illdaera",
            "Axe of Zurel",
            "Axe of the Aeons",
            "Axe of Empyr",
            "Axe of Derakor",
            "Axe of Xin Diabo",
            "Axe of Orrak",
        },
        ['Phantom'] = {
            "Phantom Assailant",
        },
        ['Alliance'] = {
            "Demolisher's Alliance,",
            "Mangler's Covenant",
            "Vindicator's Coalition",
            "Conqueror's Conjunction",
            "Eviscerator's Covariance",

        },
        ['CheapShot'] = {
            "Slap in the Face IX", -- 128
            "Slap in the Face",
            "Kick in the Teeth",
            "Punch in The Throat",
            "Kick in the Shins",
            "Sucker Punch",
            "Rabbit Punch",
            "Swift Punch",
        },
        ['AESlice'] = {
            "Arcblade",
            "Arcslice",
            "Arcsteel",
            "Arcslash",
            "Arcshear",
            "Arcscale",
        },
        ['AEVicious'] = {
            "Vicous Spiral VII", -- 127
            "Vicious Spiral",
            "Vicious Cyclone",
            "Vicious Cycle",
            "Vicious Revolution",
            "Vicious Whirl",
        },
        ['FrenzyBoost'] = {
            "Augmented Frenzy VII", -- 129
            "Augmented Frenzy",
            "Amplified Frenzy",
            "Bolstered Frenzy",
            "Magnified Frenzy",
            "Buttressed Frenzy",
            "Heightened Frenzy",
        },
        ['RageStrike'] = {
            "Festering Rage VII", -- 127
            "Roiling Rage",
            "Festering Rage",
            "Bubbling Rage",
            "Smoldering Rage",
            "Seething Rage",
            "Frothing Rage",
        },
        ['SharedBuff'] = {
            "Shared Bloodlust X", -- 130
            "Shared Barbarism",
            "Shared Bloodlust",
            "Shared Brutality",
            "Shared Savagery",
            "Shared Viciousness",
            "Shared Cruelty",
            "Shared Ruthlessness",
            "Shared Atavism",
            "Shared Violence",
        },
        ['PrimaryBurnDisc'] = {
            "Berserking Discipline",
            "Sundering Discipline",
            "Brutal Discipline",
        },
        ['CleavingDisc'] = {
            "Cleaving Rage Discipline",
            "Cleaving Anger Discipline",
            "Cleaving Acrimony Discipline",
        },
        ['FlurryDisc'] = {
            "Vengeful Flurry Discipline",
            "Avenging Flurry Discipline",
        },
        ['DisconDisc'] = {
            "Disconcerting Discipline",
        },
        ['ResolveDisc'] = {
            "Frenzied Resolve Discipline",
        },
        ['HHEBuff'] = {
            "Battle Cry",
            "War Cry",
            "Battle Cry of Dravel",
            "War Cry of Dravel",
            "Battle Cry of the Mastruq",
            "Ancient: Cry of Chaos",
        },
        ['CryDmg'] = {
            "Cry Havoc",
            "Cry Carnage",
        },
        ['Tendon'] = {
            "Tendon Cleave", -- 126
            "Tendon Slice",
            "Tendon Shred",
            "Tendon Cleave",
            "Tendon Sever",
            "Tendon Shear",
            "Tendon Lacerate",
            "Tendon Slash",
            "Tendon Gash",
            "Tendon Tear",
            "Tendon Rupture",
            "Tendon Rip",
        },
        ['SappingStrike'] = {
            "Sapping Strikes",
            "Shriveling Strikes",
            "Draining Strikes",
        },
        ['ReflexDisc'] = {
            "Reflexive Retaliation",
            "Instinctive Retaliation",
        },
        ['RestFrenzy'] = {
            "Desperate Frenzy",
            "Blinding Frenzy",
            "Restless Frenzy",
        },
        ['RetaliationDodge'] = {
            "Anticipatory Retaliation", -- 129
            "Preemptive Retaliation",
            "Primed Retaliation",
            "Premature Retaltion",
            "Proactive Retaliation",
            "Prior Retaliation",
            "Advanced Retaliation",
            "Early Retaliation",
        },
        ['TempleStun'] = {
            "Temple Strike XVI", -- 128
            "Temple Shatter",
            "Temple Bash",
            "Temple Blow",
            "Temple Chop",
            "Temple Crack",
            "Temple Crush",
            "Temple Demolish",
            "Temple Shatter",
            "Temple Slam",
            "Temple Smash",
            "Temple Strike",
        },
        ['JarringStrike'] = {
            "Jarring Strike XVI", -- 129
            "Jarring Crash",
            "Jarring Strike",
            "Jarring Smash",
            "Jarring Clash",
            "Jarring Slam",
            "Jarring Blow",
            "Jarring Crush",
            "Jarring Smite",
            "Jarring Jolt",
            "Jarring Shock",
            "Jarring Impact",
        },
        ['SnareDisc'] = {
            "Tendon Slice",
            "Tendon Shred",
            "Tendon Rip",
            "Tendon Rupture",
            "Tendon Tear",
            "Tendon Gash",
            "Tendon Slash",
            "Tendon Lacerate",
            "Tendon Shear",
            "Tendon Sever",
            "Tendon Cleave",
            "Crippling Strike",
            "Leg Slice",
            "Leg Cut",
            "Leg Strike",
        },
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
                name = "War Cry of the Braxi",
                type = "Disc",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "HHEBuff",
                type = "Disc",
                cond = function(self, discSpell)
                    return not Casting.AAReady("War Cry of the Braxi") and Casting.NoDiscActive() and Casting.SelfBuffCheck(discSpell)
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
                type = "spell",
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
            Logger.log_verbose("\aySummonAxe(): Waiting for Summon to Finish")
            Casting.WaitCastFinish(mq.TLO.Me, false, axeDisc.Range() or 0)
            Logger.log_verbose("\agSummonAxe(): Done!")
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
