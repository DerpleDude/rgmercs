local mq           = require('mq')
local ItemManager  = require("utils.item_manager")
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Core         = require("utils.core")
local Ui           = require("utils.ui")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")
local Set          = require('mq.set')
local Combat       = require("utils.combat")

--todo: add a LOT of tooltips or scrap them entirely. Hopefully the former.
local Tooltips     = {
    Mantle              = "Spell Line: Melee Absorb Proc",
    Carapace            = "Spell Line: Melee Absorb Proc",
    CombatEndRegen      = "Discipline Line: Endurance Regen (In-Combat Useable)",
    EndRegen            = "Discipline Line: Endurance Regen (Out of Combat)",
    Blade               = "Ability Line: Double 2HS Attack w/ Accuracy Mod",
    Crimson             = "Disicpline Line: Triple Attack w/ Accuracy Mod",
    MeleeMit            = "Discipline Line: Absorb Incoming Dmg",
    BlockDisc           = "Discipline: Shield Block Chance 98-99%",
    LeechCurse          = "Discipline: Melee LifeTap w/ Increase Hit Chance",
    UnholyAura          = "Discipline: Increase LifeTap Spell Damage",
    Guardian            = "Discipline: Melee Mitigation w/ Defensive LifeTap & Lowered Melee DMG Output",
    PetSpell            = "Spell Line: Summons SK Pet",
    PetHaste            = "Spell Line: Haste Buff for SK Pet",
    Shroud              = "Spell Line: Add Melee LifeTap Proc",
    Horror              = "Spell Line: Proc HP Return",
    Mental              = "Spell Line: Proc Mana Return",
    Skin                = "Spell Line: Melee Absorb Proc",
    SelfDS              = "Spell Line: Self Damage Shield",
    Demeanor            = "Spell Line: Add LifeTap Proc Buff on Killshot",
    HealBurn            = "Spell Line: Add Hate Proc on Incoming Spell Damage",
    CloakHP             = "Spell Line: Increase HP and Stacking DS",
    Covenant            = "Spell Line: Increase Mana Regen + Ultravision / Decrease HP Per Tick",
    CallAtk             = "Spell Line: Increase Attack / Decrease HP Per Tick",
    AETaunt             = "Spell Line: PBAE Hate Increase + Taunt",
    PoisonDot           = "Spell Line: Poison Dot",
    SpearNuke           = "Spell Line: Instacast Disease Nuke",
    BondTap             = "Spell Line: LifeTap DOT",
    DireTap             = "Spell Line: LifeTap",
    LifeTap             = "Spell Line: LifeTap",
    BiteTap             = "Spell Line: LifeTap + ManaTap",
    ForPower            = "Spell Line: Hate Increase + Hate Increase DOT + AC Buff 'BY THE POWER OF GRAYSKULL, I HAVE THE POWER -- HE-MAN'",
    Terror              = "Spell Line: Hate Increase + Taunt",
    TempHP              = "Spell Line: Temporary Hitpoints (Decrease per Tick)",
    Dicho               = "Spell Line: Hate Increase + LifeTap",
    PowerTapAC          = "Spell Line: AC Tap",
    PowerTapAtk         = "Spell Line: Attack Tap",
    SnareDot            = "Spell Line: Snare + HP DOT",
    Acrimony            = "Spell Increase: Aggrolock + LifeTap DOT + Hate Generation",
    SpiteStrike         = "Spell Line: LifeTap + Caster 1H Blunt Increase + Target Armor Decrease",
    ReflexStrike        = "Ability: Triple 2HS Attack + HP Increase",
    DireDot             = "Spell Line: DOT + AC Decrease + Strength Decrease",
    AllianceNuke        = "Spell Line: Alliance (Requires Multiple of Same Class) - Increase Spell Damage Taken by Target + Large LifeTap",
    InfluenceDisc       = "Ability Line: Increase AC + Absorb Damage + Melee Proc (LifeTap + Max HP Increase)",
    DLUA                = "AA: Cast Highest Level of Scribed Buffs (Shroud, Horror, Drape, Demeanor, Skin, Covenant, CallATK)",
    DLUB                = "AA: Cast Highest Level of Scribed Buffs (Shroud, Mental, Drape, Demeanor, Skin, Covenant, CallATK)",
    HarmTouch           = "AA: Harms Target HP",
    ThoughtLeech        = "AA: Harms Target HP + Harms Target Mana",
    VisageOfDeath       = "Spell: Increases Melee Hit Dmg + Illusion",
    LeechTouch          = "AA: LifeTap Touch",
    Tvyls               = "Spell: Triple 2HS Attack + % Melee Damage Increase on Target",
    ActivateShield      = "Activate 'Shield' if set in Bandolier",
    Activate2HS         = "Activate '2HS' if set in Bandolier",
    ExplosionOfHatred   = "Spell: Targeted AE Hatred Increase",
    ExplosionOfSpite    = "Spell: Targeted PBAE Hatred Increase",
    Taunt               = "Ability: Increases Hatred to 100% + 1",
    EncroachingDarkness = "Ability: Snare + HP DOT",
    Epic                = 'Item: Casts Epic Weapon Ability',
    ViciousBiteOfChaos  = "Spell: Duration LifeTap + Mana Return",
    Bash                = "Use Bash Ability",
    Slam                = "Use Slam Ability",
    HateBuff            = "Spell/AA: Increase Hate Generation",
}

local _ClassConfig = {
    -- Added BladeDisc line for AE taunt, return spears to ST
    _version            = "2.6 - EQ Might",
    _author             = "Algar, Derple",
    ['ModeChecks']      = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
        IsRezing = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Modes']           = {
        'Tank',
        'DPS',
    },
    ['Themes']          = {
        ['Tank'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.5, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.5, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.2, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.5, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.5, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.2, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.5, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.5, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.5, g = 0.05, b = 0.05, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.3, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.5, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.5, g = 0.05, b = 0.05, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.2, g = 0.05, b = 0.05, a = .1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.2, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 1.0, g = 0.05, b = 0.05, a = .8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 1.0, g = 0.05, b = 0.05, a = .9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.5, g = 0.05, b = 0.05, a = 1.0, }, },
        },
    },
    ['ItemSets']        = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Innoruuk's Dark Wrath", -- 2.1, EQM custom
            "Innoruuk's Dark Blessing",
            "Innoruuk's Voice",
        },
        ['OoW_Chest'] = {
            "Heartstiller's Mail Chestguard",
            "Duskbringer's Plate Chestguard of the Hateful",
        },
    },
    ['AbilitySets']     = {
        --Laz spells to look into: Fickle Shadows
        ['Mantle'] = {
            "Soul Carapace",
            "Ancient: Guard of Chivalry", -- EQM Custom
            "Soul Shield",
            "Soul Guard",
            "Ichor Guard", -- Level 56, Timer 5
            "Squire Guard",
        },
        ['BlockDisc'] = {
            "Deflection Discipline",
        },

        ['LeechCurse'] = { 'Leechcurse Discipline', },

        ['UnholyAura'] = { 'Unholy Aura Discipline', },

        ['PetSpell'] = {
            "Son of Decay",
            "Invoke Death",
            "Cackling Bones",
            "Leering Corpse",
            "Malignant Dead",
            "Summon Dead",
            "Animate Dead",
            "Restless Bones",
            "Bone Walk",
            "Convoke Shadow",
            "Leering Corpse,",
        },
        ['PetHaste'] = {
            "Amplify Death",
            "Rune of Decay",
            "Augmentation of Death",
            "Augment Death",
            "Strengthen Death",
        },
        ['Horror'] = {                 -- HP Tap Proc
            "Shroud of the Nightborn", -- Level 71
            "Marrowthirst Horror",     -- EQM Added
            "Shroud of Discord",       -- Level 67 -- Buff Slot 1 <
            "Black Shroud",            -- Level 65
            "Shroud of Chaos",         -- Level 63
            "Shroud of Death",         -- Level 55
        },
        ['Mental'] = {                 -- Mana Tap Proc
            "Mental Horror",           -- Level 65 --Buff Slot 1 >
            "Mental Corruption",       -- Level 52
        },
        ['Skin'] = {
            "Decrepit Skin", -- Level 70
        },
        ['SelfDS'] = {
            "Banshee Aura",
        },
        ['CloakHP'] = {
            "Cloak of the Akheva",
            "Cloak of Luclin",
            "Cloak of Discord",
        },
        ['CallAtk'] = {
            "Call of Darkness",
        },
        ['AETaunt'] = {
            "Dread Gaze", -- Level 69
        },
        ['PoisonDot'] = {
            "Blood of the Blacktalon", -- Level 71
            "Blood of Pain",           -- Level 41
            "Blood of Hate",
            "Blood of Discord",
            "Blood of Inruku",
        },
        ['SpearNuke'] = {
            "Spear of Decay",
            "Miasmic Spear",
            "Spear of Muram",
            "Spike of Disease", -- Level 1
            "Spear of Disease",
            "Spear of Pain",
            "Spear of Plague",
        },
        ['BondTap'] = {
            "Bond of the Blacktalon", -- EQM Added
            "Bond of Inruku",
            "Bond of Death",
            "Vampiric Curse", -- Level 57
        },
        ['LifeTap'] = {
            "Touch of the Devourer",
            "Leech Soul", -- EQM Custom
            "Touch of Inruku",
            "Touch of Innoruuk",
            "Touch of Volatis",
            "Drain Soul",
            "Drain Spirit",
            "Spirit Tap",
            "Siphon Life",
            "Life Leech",
            "Lifedraw",
            "Lifespike", -- Level 15
            "Lifetap",   -- Level 8
        },
        ['LifeTap2'] = {
            "Touch of the Devourer",
            "Leech Soul", -- EQM Custom
            "Touch of Inruku",
            "Touch of Innoruuk",
            "Touch of Volatis",
            "Drain Soul",
            "Drain Spirit",
            "Spirit Tap",
            "Siphon Life",
            "Life Leech",
            "Lifedraw",
            "Lifespike",
            "Lifetap", -- Level 8
        },
        ['LifeTap3'] = {
            "Touch of the Devourer",
            "Leech Soul", -- EQM Custom
            "Touch of Inruku",
            "Touch of Innoruuk",
            "Touch of Volatis",
            "Drain Soul",
            "Drain Spirit",
            "Spirit Tap",
            "Siphon Life",
            "Life Leech",
            "Lifedraw",
            "Lifespike",
            "Lifetap", -- Level 8
        },
        -- ['TouchTap'] = {
        --     "Touch of Draygun",
        -- },
        ['BiteTap'] = {
            "Zevfeer's Bite", -- Level 62
            "Ancient: Bite of Chaos",
            "Inruku's Bite",
            "Ancient: Bite of Muram",
            "Blacktalon Bite", -- EQM Added
        },
        ['Terror'] = {
            "Terror of Darkness", -- Level 33
            "Terror of Shadows",  -- Level 42
            "Terror of Death",
            "Terror of Terris",
            "Terror of Thule",
            "Terror of Discord",
            "Terror of Vergalid", -- EQM added
        },
        ['Terror2'] = {
            "Terror of Darkness",
            "Terror of Shadows",
            "Terror of Death",
            "Terror of Terris",
            "Terror of Thule",
            "Terror of Discord",
            "Terror of Vergalid", -- EQM added
        },
        ['Terror3'] = {
            "Terror of Darkness",
            "Terror of Shadows",
            "Terror of Death",
            "Terror of Terris",
            "Terror of Thule",
            "Terror of Discord",
            "Terror of Vergalid", -- EQM added
        },
        ['PowerTapAC'] = {
            "Theft of Agony",
            "Theft of Pain",
            "Aura of Pain",
            "Torrent of Pain",
            "Shroud of Pain",
            "Scream of Pain",
        },
        ['PowerTapAtk'] = {
            "Theft of Hate",
            "Aura of Hate",
            "Torrent of Hate",
            "Shroud of Hate",
            "Scream of Hate",
        },
        ['SnareDot'] = {
            "Festering Darkness",
            "Cascading Darkness",
            "Dooming Darkness",
            "Engulfing Darkness",
            "Clinging Darkness", -- Level 11
        },
        ['DireDot'] = {
            "Dark Constriction",
            "Asystole",
            "Heart Flutter",
            "Disease Cloud",
        },
        ['HateBuff'] = {         --9 minute reuse makes these somewhat ridiculous to gem on the fly.
            "Voice of Thule",    -- level 60, 12% hate
            "Voice of Terris",   -- level 55, 10% hate
            "Voice of Death",    -- level 50, 6% hate
            "Voice of Shadows",  -- level 46, 4% hate
            "Voice of Darkness", -- level 39, 2% hate
        },
        ['BladeDisc'] = {
            "Whirlwind Blade",
            "Mayhem Blade",
        },
        ['Minionskin'] = { --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",
            "Greater Minionskin",
            "Minionskin",
            "Lesser Minionskin",
        },
        ['Protective'] = {
            "Protective Discipline",
            "Protective Surge Discipline",
        },
        ['ForPower'] = {
            "Challenge for Power",
        },
        -- pact of decay ... is this a lich? level 69
    },
    ['HelperFunctions'] = {
        DoRez = function(self, corpseId)
            local rezStaff = self.ResolvedActionMap['RezStaff']

            if mq.TLO.Me.ItemReady(rezStaff)() then
                if Casting.OkayToRez(corpseId) then
                    return Casting.UseItem(rezStaff, corpseId)
                end
            end

            return false
        end,
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
        --function to space out Epic and Omens Chest with Mortal Coil old-school swarm style. Epic has an override condition to fire anyway on named.
        LeechCheck = function(self)
            local LeechEffects = { "Leechcurse Discipline", "Mortal Coil", "Lich Sting Recourse", "Reaper Strike Recourse", "Vampiric Aura", }
            for _, buffName in ipairs(LeechEffects) do
                if Casting.IHaveBuff(buffName) then return false end
            end
            return true
        end,

    },
    ['RotationOrder']   = {
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Summon pet even when buffs are off on emu
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            load_cond = function(self) return Config:GetSetting('DoPet') end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and Casting.AmIBuffable()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            load_cond = function(self) return Config:GetSetting('DoPet') end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
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
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat"
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'HateTools(AutoTarget)',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function() return Core.IsTanking() end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Targeting.HateToolsNeeded()
            end,
        },
        { --Actions that establish or maintain hatred
            name = 'AEHateTools',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function()
                if not Core.IsTanking() then return false end
                local bladeDisc = Config:GetSetting('BladeDiscUse') > 1 and Core.GetResolvedActionMapItem('BladeDisc')
                local hateAA = Config:GetSetting('AETauntAA') and (Casting.CanUseAA("Explosion of Spite") or Casting.CanUseAA("Explosion of Hatred"))
                local tauntSpell = Config:GetSetting('AETauntSpell') and Core.GetResolvedActionMapItem('AETaunt')
                return bladeDisc or hateAA or tauntSpell
            end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and Combat.AETauntCheck(true)
            end,
        },
        { --Dynamic weapon swapping if UseBandolier is toggled
            name = 'Weapon Management',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('UseBandolier') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        { --Defensive actions triggered by low HP
            name = 'EmergencyDefenses',
            state = 1,
            steps = 2, -- help ensure that we cancel visage when needed
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart')
            end,
        },
        { --Prioritized in their own rotation to help keep HP topped to the desired level, includes emergency abilities
            name = 'LifeTaps',
            state = 1,
            steps = 1,
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
                return combat_state == "Combat" and Targeting.IHaveAggro(100) and
                    -- we are under our defense start HP
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('DefenseStart') or
                        -- we have met our defense count threshold
                        self.ClassConfig.HelperFunctions.DefensiveDiscCheck(true) or
                        -- we are fighting a named and we are (presumably) tanking it
                        (Globals.AutoTargetIsNamed and Targeting.GetAutoTargetAggroPct() >= 100))
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
                return combat_state == "Combat" and not Globals.AutoTargetIsNamed and Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        { --DPS Spells, includes recourse/gift maintenance
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat"
            end,
        },
    },
    ['Rotations']       = {
        ['Downtime'] = {
            {
                name = "Horror",
                type = "Spell",
                tooltip = Tooltips.Horror,
                load_cond = function(self) return Config:GetSetting('ProcChoice') == 1 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Mental",
                type = "Spell",
                tooltip = Tooltips.Horror,
                load_cond = function(self) return Config:GetSetting('ProcChoice') == 2 end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "CloakHP",
                type = "Spell",
                tooltip = Tooltips.CloakHP,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SelfDS",
                type = "Spell",
                tooltip = Tooltips.SelfDS,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "CallAtk",
                type = "Spell",
                tooltip = Tooltips.CallAtk,
                load_cond = function(self) return Config:GetSetting("DoCallBuff") end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            --You'll notice my use of TotalSeconds, this is to keep as close to 100% uptime as possible on these buffs, rebuffing early to decrease the chance of them falling off in combat
            --I considered creating a function (helper or utils) to govern this as I use it on multiple classes but the difference between buff window/song window/aa/spell etc makes it unwieldy
            -- if using duration checks, dont use SelfBuffCheck() (as it could return false when the effect is still on)
            {
                name = "Skin",
                type = "Spell",
                tooltip = Tooltips.Skin,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 60
                end,
            },
            {
                name = "Voice of Thule",
                type = "AA",
                tooltip = Tooltips.HateBuff,
                load_cond = function(self) return Casting.CanUseAA("Voice of Thule") and Config:GetSetting('DoHateBuff') end,
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.ID()) end,
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "HateBuff",
                type = "Spell",
                tooltip = Tooltips.HateBuff,
                load_cond = function(self) return not Casting.CanUseAA("Voice of Thule") and Config:GetSetting('DoHateBuff') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    if not Casting.CastReady(spell) then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Emergency Visage Cancel",
                desc = "Removes VoD at Critical HP",
                type = "CustomFunc",
                load_cond = function(self) Casting.CanUseAA("Visage of Death") end,
                cond = function(self) return Config:GetSetting('HPCritical') and mq.TLO.Me.Buff("Visage of Death")() end,
                custom_func = function(self)
                    Core.DoCmd("/removebuff \"Visage of Death\"")
                end,
            },
        },
        ['PetSummon'] = {
            {
                name = "PetSpell",
                type = "Spell",
                tooltip = Tooltips.PetSpell,
                active_cond = function(self, spell) return mq.TLO.Me.Pet.ID() > 0 end,
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
                name = "PetHaste",
                type = "Spell",
                tooltip = Tooltips.PetHaste,
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell)
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
        ['EmergencyDefenses'] = {
            --Note that in Tank Mode, defensive discs are preemptively cycled on named in the (non-emergency) Defenses rotation
            --Abilities should be placed in order of lowest to highest triggered HP thresholds
            --Some conditionals are commented out while I tweak percentages (or determine if they are necessary)
            {
                name = "OoW_Chest",
                type = "Item",
                tooltip = Tooltips.OoW_BP,
            },
            { --Note that on named we may already have a defensive disc running already, could make this remove other discs, but we have other options.
                name = "BlockDisc",
                type = "Disc",
                tooltip = Tooltips.BlockDisc,
                pre_activate = function(self)
                    if Config:GetSetting('UseBandolier') then
                        Core.SafeCallFunc("Equip Shield", ItemManager.BandolierSwap, "Shield")
                    end
                end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "LeechCurse",
                type = "Disc",
                tooltip = Tooltips.LeechCurse,
                cond = function(self)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "UnholyAura",
                type = "Disc",
                tooltip = Tooltips.UnholyAura,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Emergency Visage Cancel",
                desc = "Removes VoD at Critical HP",
                type = "CustomFunc",
                load_cond = function(self) Casting.CanUseAA("Visage of Death") end,
                cond = function(self) return Config:GetSetting('HPCritical') and mq.TLO.Me.Buff("Visage of Death")() end,
                custom_func = function(self)
                    Core.DoCmd("/removebuff \"Visage of Death\"")
                end,
            },
        },
        ['HateTools(AutoTarget)'] = {
            { --more valuable on laz because we have less hate tools and no other hatelist + 1 abilities
                name = "Taunt",
                type = "Ability",
                tooltip = Tooltips.Taunt,
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro() and Targeting.GetTargetDistance(target) < 30
                end,
            },
            {
                name = "Xeno's Faceguard",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Xeno's Faceguard")() end,
            },
            {
                name = "Terror",
                type = "Spell",
                tooltip = Tooltips.Terror,
                load_cond = function(self) return Config:GetSetting('DoTerror') end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 60
                end,
            },
            {
                name = "Terror2",
                type = "Spell",
                tooltip = Tooltips.Terror,
                load_cond = function(self) return Config:GetSetting('DoTerror') end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 60
                end,
            },
            {
                name = "Terror3",
                type = "Spell",
                tooltip = Tooltips.Terror,
                load_cond = function(self) return Config:GetSetting('DoTerror') end,
                cond = function(self, spell, target)
                    return (mq.TLO.Target.SecondaryPctAggro() or 0) > 80
                end,
            },
        },
        ['AEHateTools'] = {
            {
                name = "Artifact of Dread Gaze",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Artifact of Dread Gaze")() end,
            },
            {
                name = "Explosion of Hatred",
                type = "AA",
                tooltip = Tooltips.ExplosionOfHatred,
            },
            {
                name = "Explosion of Spite",
                type = "AA",
                tooltip = Tooltips.ExplosionOfSpite,
            },
            {
                name = "BladeDisc",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('BladeDiscUse') > 1 end,
                cond = function(self, discSpell)
                    return Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "AETaunt",
                type = "Spell",
                tooltip = Tooltips.AETaunt,
                cond = function(self, spell, target)
                    return mq.TLO.Me.PctHPs() > Config:GetSetting('EmergencyStart')
                end,
            },
        },
        ['HateTools(AggroTarget)'] = {
            {
                name = "Taunt",
                type = "Ability",
                tooltip = Tooltips.Taunt,
            },
            {
                name = "Xeno's Faceguard",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Xeno's Faceguard")() end,
            },
            {
                name = "Terror",
                type = "Spell",
                tooltip = Tooltips.Terror,
                load_cond = function(self) return Config:GetSetting('DoTerror') end,
            },
            {
                name = "Terror2",
                type = "Spell",
                tooltip = Tooltips.Terror,
                load_cond = function(self) return Config:GetSetting('DoTerror') end,
            },
            {
                name = "Terror3",
                type = "Spell",
                tooltip = Tooltips.Terror,
                load_cond = function(self) return Config:GetSetting('DoTerror') end,
            },
            {
                name = "ForPower",
                type = "Spell",
                tooltip = Tooltips.ForPower,
            },
        },
        ['Burn'] = {
            {
                name = "Visage of Death",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoVisage')
                end,
            },
            { -- for DPS mode
                name = "UnholyAura",
                type = "Disc",
                tooltip = Tooltips.UnholyAura,
                load_cond = function(self) return not Core.IsTanking() end,
                cond = function(self)
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Harm Touch",
                type = "AA",
                tooltip = Tooltips.HarmTouch,
            },
            {
                name = "Leech Touch",
                type = "AA",
                tooltip = Tooltips.ThoughtLeech,
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoLeechTouch') ~= 1
                end,
            },
            {
                name = "Skin",
                type = "Spell",
                tooltip = Tooltips.Skin,
                cond = function(self, spell, target)
                    if not Core.IsTanking() or not Globals.AutoTargetIsNamed then return false end
                    return Casting.SelfBuffCheck(spell)
                end,
            },
        },
        ['Snare'] = {
            {
                name = "Encroaching Darkness",
                tooltip = Tooltips.EncroachingDarkness,
                type = "AA",
                load_cond = function(self) return Casting.CanUseAA("Encroaching Darkness") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
            {
                name = "SnareDot",
                type = "Spell",
                tooltip = Tooltips.SnareDot,
                load_cond = function(self) return not Casting.CanUseAA("Encroaching Darkness") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target) and not Casting.SnareImmuneTarget(target)
                end,
            },
        },
        ['Defenses'] = {
            {
                name = "Protective",
                type = "Disc",
                cond = function(self, discSpell, target)
                    if not Core.IsTanking() then return false end
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Mantle",
                type = "Disc",
                tooltip = Tooltips.Mantle,
                cond = function(self, discSpell, target)
                    if not Core.IsTanking() then return false end
                    return Casting.NoDiscActive()
                end,
            },
            {
                name = "Epic",
                type = "Item",
                tooltip = Tooltips.Epic,
                cond = function(self, itemName, target)
                    return self.ClassConfig.HelperFunctions.LeechCheck(self) or Globals.AutoTargetIsNamed
                end,
            },
        },
        ['LifeTaps'] = {
            --Full rotation to make sure we use these in priority for emergencies
            {
                name = "Leech Touch",
                type = "AA",
                tooltip = Tooltips.LeechTouch,
                cond = function(self, aaName, target)
                    if Config:GetSetting('DoLeechTouch') == 2 then return false end
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "LifeTap",
                type = "Spell",
                tooltip = Tooltips.LifeTap,
                cond = function(self, spell)
                    local myHP = mq.TLO.Me.PctHPs()
                    return Casting.HaveManaToNuke() and myHP <= Config:GetSetting('StartLifeTap') or myHP <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "LifeTap2",
                type = "Spell",
                tooltip = Tooltips.LifeTap,
                cond = function(self, spell)
                    local myHP = mq.TLO.Me.PctHPs()
                    return Casting.HaveManaToNuke() and myHP <= Config:GetSetting('StartLifeTap') or myHP <= Config:GetSetting('EmergencyStart')
                end,
            },
            {
                name = "LifeTap3",
                type = "Spell",
                tooltip = Tooltips.LifeTap,
                cond = function(self, spell)
                    local myHP = mq.TLO.Me.PctHPs()
                    return Casting.HaveManaToNuke() and myHP <= Config:GetSetting('StartLifeTap') or myHP <= Config:GetSetting('EmergencyStart')
                end,
            },
        },
        ['Combat'] = {
            {
                name = "ForPower",
                type = "Spell",
                tooltip = Tooltips.ForPower,
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell, target)
                end,
            },
            {
                name = "SpearNuke",
                type = "Spell",
                tooltip = Tooltips.SpearNuke,
                cond = function(self, spell, target)
                    return Casting.HaveManaToNuke()
                end,
            },
            {
                name = "BladeDisc",
                type = "Disc",
                load_cond = function(self) return Config:GetSetting('BladeDiscUse') == 3 and Core.GetResolvedActionMapItem('BladeDisc') end,
                cond = function(self, discSpell)
                    return Config:GetSetting('DoAEDamage') and mq.TLO.Me.PctEndurance() >= Config:GetSetting("ManaToNuke") -- save endurance for emergency discs
                end,
            },
            {
                name = "BondTap",
                type = "Spell",
                tooltip = Tooltips.BondTap,
                load_cond = function(self) return Config:GetSetting('DoBondTap') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.HaveManaToDot() and Casting.SelfBuffCheck(spell) -- use for recourse --Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "PoisonDot",
                type = "Spell",
                tooltip = Tooltips.PoisonDot,
                load_cond = function(self) return Config:GetSetting('DoPoisonDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "DireDot",
                type = "Spell",
                tooltip = Tooltips.DireDot,
                load_cond = function(self) return Config:GetSetting('DoDireDot') end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.HaveManaToDot() and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "BiteTap",
                type = "Spell",
                tooltip = Tooltips.BiteTap,
            },
            {
                name = "Vicious Bite of Chaos",
                type = "AA",
                tooltip = Tooltips.ViciousBiteOfChaos,
            },
            {
                name = "Companion's Blessing",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.Pet.PctHPs() or 999) <= Config:GetSetting('BigHealPoint')
                end,
            },
            {
                name = "PowerTapAC",
                type = "Spell",
                tooltip = Tooltips.PowerTapAC,
                load_cond = function(self) return Config:GetSetting('DoACTap') end,
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "PowerTapAtk",
                type = "Spell",
                tooltip = Tooltips.PowerTapAtk,
                load_cond = function(self) return Config:GetSetting('DoAtkTap') end,
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                tooltip = Tooltips.Bash,
                cond = function(self)
                    return (Core.ShieldEquipped() or Casting.CanUseAA("2 Hand Bash"))
                end,
            },
            {
                name = "Slam",
                type = "Ability",
                load_cond = function(self) return mq.TLO.Me.Ability("Slam")() end,
                tooltip = Tooltips.Slam,
            },
        },
        ['Weapon Management'] = {
            {
                name = "Equip Shield",
                type = "CustomFunc",
                cond = function(self, target)
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("Shield") end,
            },
            {
                name = "Equip 2Hand",
                type = "CustomFunc",
                cond = function()
                    if mq.TLO.Me.Bandolier("2Hand").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('Equip2Hand') and mq.TLO.Me.ActiveDisc() ~= "Deflection Discipline" and
                        not (Globals.AutoTargetIsNamed and Config:GetSetting('NamedShieldLock'))
                end,
                custom_func = function(self) return ItemManager.BandolierSwap("2Hand") end,
            },
        },
    },
    -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
    -- The list name ("Default" in the list below) is abitrary, it is simply what shows up in the UI when this spell list is loaded.
    -- Virtually any helper function or TLO can be used as a condition. Example: Mode or level-based lists.
    -- The first list without conditions or whose conditions returns true will be loaded, all subsequent lists will be ignored.
    -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
    -- Loadout checks (such as scribing a spell or using the "Rescan Loadout" or "Reload Spells" buttons) will re-check these lists and may load a different set if things have changed.
    ['SpellList']       = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "SpearNuke", },
                { name = "LifeTap", },
                { name = "SnareDot",    cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Encroaching Darkness") end, },
                { name = "Terror",      cond = function(self) return Config:GetSetting('DoTerror') end, },
                { name = "AETaunt",     cond = function(self) return Config:GetSetting('AETauntSpell') end, },
                { name = "BiteTap", },
                { name = "BondTap",     cond = function(self) return Config:GetSetting('DoBondTap') end, },
                { name = "PoisonDot",   cond = function(self) return Config:GetSetting('DoPoisonDot') end, },
                { name = "DireDot",     cond = function(self) return Config:GetSetting('DoDireDot') end, },
                { name = "PowerTapAC",  cond = function(self) return Config:GetSetting('DoACTap') end, },
                { name = "PowerTapAtk", cond = function(self) return Config:GetSetting('DoAtkTap') end, },
                { name = "Skin", },
                { name = "HateBuff",    cond = function(self) return Config:GetSetting('DoHateBuff') and not Casting.CanUseAA("Voice of Thule") end, },
                { name = "LifeTap2", },
                { name = "Terror2",     cond = function(self) return Config:GetSetting('DoTerror') end, },
                { name = "Terror3",     cond = function(self) return Config:GetSetting('DoTerror') end, },
                { name = "LifeTap3", },
                { name = "SelfDS", },
            },
        },
    },
    ['PullAbilities']   = {
        {
            id = 'SpearNuke',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('SpearNuke').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('SpearNuke').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('SpearNuke')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Terror',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Terror').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Terror').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('Terror')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Terror2',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('Terror2').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('Terror2').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('Terror2')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'LifeTap',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('LifeTap').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('LifeTap').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('LifeTap')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'LifeTap2',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('LifeTap2').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('LifeTap2').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('LifeTap2')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'LifeTap3',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('LifeTap2').RankName.Name() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('LifeTap2').RankName.Name() or "" end,
            AbilityRange = 200,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('LifeTap2')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
    },
    ['DefaultConfig']   = {
        --Mode
        ['Mode']            = {
            DisplayName = "Mode",
            Category = "Mode",
            Tooltip = "Select the active Combat Mode for this PC.",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What Modes does the Shadowknight have?",
            Answer = "Shadowknights have a mode for Tanking and a mode for DPS.",
        },

        --Buffs and Debuffs
        ['DoSnare']         = {
            DisplayName = "Use Snares",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Snare",
            Index = 101,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['SnareCount']      = {
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
        ['ProcChoice']      = {
            DisplayName = "Proc Self-Buff Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Choose which proc you prefer, if any.",
            Type = "Combo",
            ComboOptions = { 'HP Proc: Terror Line', 'Mana Proc: Mental Line,', 'Disabled', },
            Default = 1,
            Min = 1,
            Max = 3,
            RequiresLoadoutChange = true,
        },
        ['DoCallBuff']      = {
            DisplayName = "Use Call of Darkness",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Use your Call of Darkness buff (Slowly drains your HP to grant Atk).",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoVisage']        = {
            DisplayName = "Use Visage of Death",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 103,
            Tooltip = "Use the Visage of Death AA.",
            Default = true,
            FAQ = "Why is my health draining so quickly out of combat?",
            Answer =
            "You may have Visage of Death enabled, which has a sizable self-damage component. While we will attempt to autocancel this at low health in downtime, you can disable VoD use in the Class options.",
        },

        --Taps
        ['StartLifeTap']    = {
            DisplayName = "HP % for LifeTaps",
            Group = "Abilities",
            Header = "Damage",
            Category = "Taps",
            Index = 101,
            Tooltip = "Your HP % before we use Life Taps.",
            Default = 99,
            Min = 1,
            Max = 100,
        },
        ['DoACTap']         = {
            DisplayName = "Use AC Tap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Taps",
            Index = 102,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("PowerTapAC") end,
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoAtkTap']        = {
            DisplayName = "Use Attack Tap",
            Group = "Abilities",
            Header = "Damage",
            Category = "Taps",
            Index = 103,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("PowerTapAtk") end,
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoLeechTouch']    = {
            DisplayName = "Leech Touch Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "Taps",
            Index = 104,
            Tooltip = "When to use Leech Touch",
            Type = "Combo",
            ComboOptions = { 'On critically low HP', 'As DD during burns', 'For HP or DD', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },

        --DoT Spells
        ['DoBondTap']       = {
            DisplayName = "Use Bond Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 101,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("BondTap") end,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoPoisonDot']     = {
            DisplayName = "Use Poison Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 102,
            ToolTip = function() return Ui.GetDynamicTooltipForSpell("PoisonDot") end,
            RequiresLoadoutChange = false,
            Default = true,
        },
        ['DoDireDot']       = {
            DisplayName = "Use Dire Dot",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 103,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("DireDot") end,
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DotNamedOnly']    = {
            DisplayName = "Only Dot Named",
            Group = "Abilities",
            Header = "Damage",
            Category = "Over Time",
            Index = 104,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
        },

        -- AE Damage
        ['BladeDiscUse']    = {
            DisplayName = "Blade Disc Use:",
            Group = "Abilities",
            Header = "Damage",
            Category = "AE",
            Index = 101,
            Tooltip = "When to use your AE Blade Disc Line (DPS mode will not attempt to regain hate).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Disabled', 'Only To Regain Hate', 'Whenever Possible', },
            Default = 2,
            Min = 1,
            Max = 3,
        },

        --Hate Tools
        ['DoHateBuff']      = {
            DisplayName = "Use Hate Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 103,
            Tooltip =
            "Use your Visage buff (Voice of ... line). We will continue to use the spell if slots are available (for the damage shield). The spell can be disabled directly in rotations.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['DoTerror']        = {
            DisplayName = "Use Terror Taunts",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use Terror line taunts (the number memorized is based on your other selected options).",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },
        ['AETauntAA']       = {
            DisplayName = "Use AE Taunt AA",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 102,
            Tooltip = "Use Explosions of Hatred and Spite.",
            Default = true,
            ConfigType = "Advanced",
            FAQ = "Why do we treat the Explosions the same? One is targeted, one is PBAE",
            Answer = "There are currently no scripted conditions where Hatred would be used at long range, thus, for ease of use, we can treat them similarly.",
        },
        ['AETauntSpell']    = {
            DisplayName = "Use AE Taunt Spell",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 103,
            Tooltip = "Use your AE Taunt spell line.",
            Default = true,
            ConfigType = "Advanced",
        },

        --Defenses
        ['DiscCount']       = {
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
        ['DefenseStart']    = {
            DisplayName = "Defense HP",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 102,
            Tooltip = "The HP % where we will use defensive actions like discs, epics, etc.\nNote that fighting a named will also trigger these actions.",
            Default = 60,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['EmergencyStart']  = {
            DisplayName = "Emergency Start",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 103,
            Tooltip = "The HP % before all but essential rotations are cut in favor of emergency or defensive abilities.",
            Default = 40,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['HPCritical']      = {
            DisplayName = "HP Critical",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 104,
            Tooltip =
            "The HP % that we will use abilities like Leechcurse and Leech Touch.\nMost other rotations are cut to give our full focus to survival.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },

        --Equipment
        ['UseBandolier']    = {
            DisplayName = "Dynamic Weapon Swap",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 101,
            Tooltip = "Enable 1H+S/2H swapping based off of current health. ***YOU MUST HAVE BANDOLIER ENTRIES NAMED \"Shield\" and \"2Hand\" TO USE THIS FUNCTION.***",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['EquipShield']     = {
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
        ['Equip2Hand']      = {
            DisplayName = "Equip 2Hand",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 103,
            Tooltip = "Over this HP%, you will swap to your \"2Hand\" bandolier entry. (Dynamic Bandolier Enabled Only)",
            Default = 75,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },
        ['NamedShieldLock'] = {
            DisplayName = "Shield on Named",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 104,
            Tooltip = "Keep Shield equipped for mobs detected as 'named' by RGMercs (see Named tab).",
            Default = true,
            FAQ = "Why does my SHD switch to a Shield on puny gray named?",
            Answer = "The Shield on Named option doesn't check levels, so feel free to disable this setting (or Bandolier swapping entirely) if you are farming fodder.",
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
