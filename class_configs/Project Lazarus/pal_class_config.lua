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

return {
    _version              = "2.1 - Project Lazarus",
    _author               = "Derple, Algar",
    ['ModeChecks']        = {
        IsTanking = function() return Core.IsModeActive("Tank") end,
        IsHealing = function() return true end,
        IsCuring  = function() return Config:GetSetting('DoCures') end,
        IsRezing  = function()
            return (Core.GetResolvedActionMapItem('RezSpell') and Targeting.GetXTHaterCount() == 0) or
                ((Casting.CanUseAA("Gift of Resurrection") or mq.TLO.FindItem("=Staff of Forbidden Rites")()) and Config:GetSetting('DoBattleRez'))
        end,
    },
    ['Rez']               = {
        ['Combat'] = {
            { type = "AA",   name = "Gift of Resurrection", },
            { type = "Item", name = "Staff of Forbidden Rites", },
        },
        ['Downtime'] = {
            { type = "AA",   name = "Gift of Resurrection", },
            { type = "Item", name = "Staff of Forbidden Rites", },
            {
                type = "Spell",
                name = "RezSpell",
                cond = function(self, spell, target)
                    return Casting.DowntimeRezOkay()
                        and not Casting.CanUseAA('Gift of Resurrection')
                end,
            },
        },
    },
    ['Modes']             = {
        'Tank',
        'DPS',
    },
    ['Cure']              = {
        ['DetDispel'] = {
            { type = "AA", name = "Radiant Cure", },
            { type = "AA", name = "Purification", selfOnly = true, },
        },
        ['Poison'] = {
            { type = "Spell", name = "PurityCure", },
        },
        ['Disease'] = {
            { type = "Spell", name = "PurityCure", },
        },
        ['Curse'] = {
            { type = "Spell", name = "CureCurse",  cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
            { type = "Spell", name = "PurityCure", cond = function(self) return not Config:GetSetting('KeepCurseMemmed') end, },
        },
    },
    ['Themes']            = {
        ['Tank'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.15, g = 0.02, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.15, g = 0.02, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.40, g = 0.05, b = 0.50, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.25, g = 0.03, b = 0.32, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.40, g = 0.05, b = 0.50, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.40, g = 0.05, b = 0.50, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.15, g = 0.02, b = 0.20, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.75, g = 0.20, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.75, g = 0.20, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.40, g = 0.05, b = 0.50, a = 1.0, }, },
        },
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.12, g = 0.02, b = 0.16, a = 0.8, }, },
            { element = ImGuiCol.TabSelected,      color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.12, g = 0.02, b = 0.16, a = 0.8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.30, g = 0.05, b = 0.40, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.20, g = 0.03, b = 0.26, a = 0.8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.30, g = 0.05, b = 0.40, a = 0.8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.30, g = 0.05, b = 0.40, a = 0.1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.12, g = 0.02, b = 0.16, a = 0.8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.75, g = 0.20, b = 1.00, a = 0.8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.75, g = 0.20, b = 1.00, a = 0.9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.30, g = 0.05, b = 0.40, a = 1.0, }, },
        },
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Nightbane, Sword of the Valiant",
            "Redemption",
        },
        ['OoW_Chest'] = {
            "Dawnseeker's Chestpiece of the Defender",
            "Oathbound Breastplate",
        },
    },
    ['AbilitySets']       = {
        ['WardProc'] = {
            -- Timer 12 - Preservation
            "Ward of Tunare", -- Level 70
        },
        ['QuickUndeadNuke'] = {
            -- Undead Quick Nuke with chance to snare and reduce AC
            "Last Rites", -- Level 68, - Timer 7
        },
        ['DDProc'] = {
            --- Fury Proc Strike
            "Virtuous Fervor", -- Level 71 Laz Custom
            "Pious Fury",      -- Level 68, 250pt, + 250pt if undead
            "Holy Order",      -- Level 65, 180pt
            "Pious Might",     -- Level 63, 150pt
            "Divine Might",    -- Level 45, 65pt
        },
        ['UndeadProc'] = {
            --- Undead Proc Strike : does not stack with Fury Proc, will be used until Fury is available even if setting not enabled.
            "Silvered Fury",      -- Level 67, 750pt
            "Ward of Nife",       -- Level 62, 500pt
            "Instrument of Nife", -- Level 26, 243pt
        },
        ['StunTimer5'] = {
            "Force of the Sentinel",   -- Level 71 Laz Custom
            "Ancient: Force of Jeron", -- Level 70
            "Ancient: Force of Chaos", -- Level 65
            "Force of Akera",          -- Level 53
            "Stun",                    -- Level 28
            "Desist",                  -- Level 13, - Not Timer 5, use for TLP Low Level Stun
        },
        ['StunTimer4'] = {
            "Force of the Sacred", -- Level 71 Laz Custom
            "Force of Piety",      -- Level 66
            "Force of Akilae",     -- Level 62
            "Force",               -- Level 52, - Not Timer 4, use for TLP Low Level Stun
            "Cease",               -- Level 7, - Not Timer 4, use for TLP Low Level Stun
        },
        ['AegoBuff'] = {
            --- Pally Aegolism
            "Affirmation",           -- Level 70
            "Guidance",              -- Level 65
            "Blessing of Austerity", -- Level 58, - Group
            "Austerity",             -- Level 55, --First actual Aego
            "Valor",                 -- Level 47
            "Daring",                -- Level 37
            "Center",                -- Level 20
            "Courage",               -- Level 8
        },
        -- ['HPTypeOne'] = {
        --     "Hand of Direction", -- Level 69, GV1
        --     "Direction",         -- Level 66, ST
        --     "Heroic Bond",       -- Level 64, ST
        --     "Heroism",           -- Level 61, ST
        --     "Resolution",        -- Level 60
        -- },
        ['Brells'] = {
            "Brell's Unshakable Barricade", -- Level 71 Laz Custom
            "Brell's Vibrant Barricade",    -- Level 70 Laz Custom
            "Brell's Brawny Bulwark",       -- Level 69
            "Brell's Stalwart Shield",      -- Level 65
            "Brell's Mountainous Barrier",  -- Level 60
            "Brell's Steadfast Aegis",      -- Level 49
        },
        ['WaveHeal'] = {
            "Wave of the Stillmoon",  -- Level 71 Laz Custom
            "Wave of Piety",          -- Level 70
            "Wave of Trushar",        -- Level 65
            "Wave of Marr",           -- Level 65
            "Healing Wave of Prexus", -- Level 58
            "Wave of Healing",        -- Level 51
            "Wave of Life",           -- Level 44
        },
        ['WaveHeal2'] = {
            "Wave of the Stillmoon",  -- Level 71 Laz Custom
            "Wave of Piety",          -- Level 70
            "Wave of Trushar",        -- Level 65
            "Wave of Marr",           -- Level 65
            "Healing Wave of Prexus", -- Level 58
            "Wave of Healing",        -- Level 51
            "Wave of Life",           -- Level 44
        },
        ['Cleansing'] = {
            "Pious Cleansing",     -- Level 69
            "Supernal Cleansing",  -- Level 64
            "Celestial Cleansing", -- Level 59
            "Ethereal Cleansing",  -- Level 44
        },
        ['ArmorSelfBuff'] = {
            --- Self Buff Armor Line Ac/Hp/Mana regen
            "Armor of the Savior",   -- Level 71 Laz Custom
            "Armor of the Champion", -- Level 69
            "Armor of the Crusader", -- Level 64 Laz Custom
            "Armor of the Divine",   -- Level 60 Laz Custom
        },
        ['SymbolBuff'] = {
            "Jeron's Mark",      -- Level 68
            "Symbol of Jeron",   -- Level 67
            "Symbol of Marzin",  -- Level 63
            "Symbol of Naltron", -- Level 58
            "Symbol of Pinzarn", -- Level 46
            "Symbol of Ryltan",  -- Level 33
            "Symbol of Transal", -- Level 24
        },
        ['SereneStun'] = {
            --- Lesson Stun - Timer 6
            "Serene Command",                 -- Level 68
            "Quellious' Word of Serenity",    -- Level 64
            "Quellious' Word of Tranquility", -- Level 54
        },
        ['TouchHeal'] = {
            -- Target Light Heal
            "Touch of Piety",   -- Level 66
            "Touch of Nife",    -- Level 61
            "Superior Healing", -- Level 57
            "Greater Healing",  -- Level 36
            "Healing",          -- Level 27
            "Light Healing",    -- Level 12
            "Minor Healing",    -- Level 6
            "Salve",            -- Level 1
        },
        ['LightHeal'] = {
            -- ToT Light Heal
            "Light of Piety", -- Level 68
            "Light of Order", -- Level 65
            "Light of Nife",  -- Level 63
            -- "Light of Life", -- Level 52, -- Currently ST heal, not a ToT
        },
        ['LightHeal2'] = {
            -- ToT Light Heal
            "Light of Piety", -- Level 68
            "Light of Order", -- Level 65
            "Light of Nife",  -- Level 63
            -- "Light of Life", -- Level 52
        },
        -- ['Pacify'] = {
        --     "Pacify", -- Level 49
        --     "Calm",   -- Level 43
        --     "Soothe", -- Level 25
        --     "Lull",   -- Level 10
        -- },
        ['PurityCure'] = {
            --- Purity Cure Poison/Diease Cure Half Power to curse
            "Crusader's Purity", -- Level 67
            "Crusader's Touch",  -- Level 62
        },
        ['HealReceivedAura'] = {
            -- Aura Buffs
            "Benevolent Aura", -- Level 71 Laz Custom
            "Blessed Aura",    -- Level 70
            "Holy Aura",       -- Level 55
        },
        ['UndeadNuke'] = {
            -- Undead Nuke
            "Spurn Undead",   -- Level 67, - Timer 7
            "Deny Undead",    -- Level 62, - Timer 7
            "Expel Undead",   -- Level 54
            "Dismiss Undead", -- Level 46
            "Expulse Undead", -- Level 30
            "Ward Undead",    -- Level 14
        },
        ['CureCurse'] = {
            -- Curse Cure Line
            "Remove Greater Curse", -- Level 60
            "Remove Curse",         -- Level 45
            "Remove Lesser Curse",  -- Level 34
            "Remove Minor Curse",   -- Level 19
        },
        ['ForgeDisc'] = {
            "Hallowforge Discipline", -- Level 70 Laz Custom
            "Holyforge Discipline",   -- Level 55
        },
        ['RezSpell'] = {
            "Resurrection",   -- Level 59
            "Restoration",    -- Level 55
            "Renewal",        -- Level 49
            "Revive",         -- Level 39
            "Reparation",     -- Level 31
            "Reconstitution", -- Level 30
            "Reanimation",    -- Level 22
        },
        ['PBAEStun'] = {
            "The Silent Decree",  -- Level 71 Laz Custom
            "The Silent Command", -- Level 65, does damage
        },
        ['AEStun'] = {            --Targeted AE
            "Stun Command",       -- Level 57, no damage
            "Sacred Word",        -- Level 41, does damage
        },
        ['BlockDisc'] = {
            "Rampart Discipline",    -- Level 70 Laz Custom
            "Deflection Discipline", -- Level 59
        },
        ['SancDisc'] = {
            "Sanctification Discipline", -- Level 60
        },
        ['TwinHealNuke'] = {
            -- "Ancient: Justice of Firiona", -- Level 71 Laz Custom, verify existence and source
            "Justice of Marr", -- Level 70
        },
        ['GuardDisc'] = {
            "Aegis of Righteousness", -- Level 71 Laz Custom
            "Guard of Righteousness", -- Level 69
            "Guard of Humility",      -- Level 61
            "Guard of Piety",         -- Level 56
        },
        ['ACBuff'] = {
            "Bulwark of Piety", -- Level 69
            "Bulwark of Faith", -- Level 65
            "Shield of Words",  -- Level 60
            "Armor of Faith",   -- Level 48
        },
    },
    ['SpellList']         = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { name = "TouchHeal",       cond = function(self) return Config:GetSetting('DoTouchHeal') < 3 end, },
                { name = "LightHeal",       cond = function(self) return Config:GetSetting('DoLightHeal') < 3 end, },
                { name = "LightHeal2",      cond = function(self) return Config:GetSetting('DoLightHeal') == 2 end, },
                { name = "WaveHeal",        cond = function(self) return Config:GetSetting('DoWaveHeal') < 3 end, },
                { name = "WaveHeal2",       cond = function(self) return Config:GetSetting('DoWaveHeal') == 2 end, },
                { name = "Cleansing",       cond = function(self) return Config:GetSetting('DoCleansing') < 3 end, },
                { name = "TwinHealNuke",    cond = function(self) return Config:GetSetting('DoTwinHealNuke') end, },
                { name = "SereneStun",      cond = function(self) return Config:GetSetting('DoSereneStun') end, },
                { name = "StunTimer4",      cond = function(self) return Core.IsTanking() end, },
                { name = "StunTimer5",      cond = function(self) return Core.IsTanking() end, },
                { name = "PBAEStun",        cond = function(self) return Config:GetSetting('PBAEStunUse') > 1 end, },
                { name = "AEStun",          cond = function(self) return Config:GetSetting('AEStunUse') > 1 end, },
                { name = "CureCurse",       cond = function(self) return Config:GetSetting('KeepCurseMemmed') end, },
                { name = "PurityCure",      cond = function(self) return Config:GetSetting('KeepPurityMemmed') end, },
                { name = "UndeadNuke",      cond = function(self) return Config:GetSetting('DoUndeadNuke') end, },
                { name = "QuickUndeadNuke", cond = function(self) return Config:GetSetting('DoQuickUndeadNuke') end, },
                { name = "WardProc", },
            },
        },
    },
    ['Helpers']           = {
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
        shieldNeeded = function()
            -- check for exactly 100% to help ensure the mob is targeting us, over 100% can indicate another is still targeted
            return (mq.TLO.Me.PctHPs() <= Config:GetSetting('EquipShield')) or mq.TLO.Me.ActiveDisc() == "Deflection Discipline" or mq.TLO.Me.Song("Rampart")() or
                (Config:GetSetting('NamedShieldLock') and ((Globals.AutoTargetIsNamed and Targeting.GetAutoTargetAggroPct() == 100) or Targeting.TankingXTNamed()))
        end,
    },
    ['HealRotationOrder'] = {
        {
            name = 'GroupHeal',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target) return Targeting.GroupHealsNeeded() end,
        },
        {
            name = 'BigHeal',
            state = 1,
            steps = 1,
            doFullRotation = true,
            cond = function(self, target)
                return Targeting.BigHealsNeeded(target) and not Targeting.TargetIsType("pet", target)
            end,
        },
        {
            name = 'MainHeal',
            state = 1,
            steps = 1,
            doFullRotation = true,
            load_cond = function(self) return Config:GetSetting('DoCleansing') == 1 or Config:GetSetting("DoTouchHeal") == 2 or Config:GetSetting('WaveHealUse') == 2 end,
            cond = function(self, target)
                return Targeting.MainHealsNeeded(target)
            end,
        },
    },
    ['HealRotations']     = {
        ['GroupHeal'] = {
            {
                name = "Hand of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.BigGroupHealsNeeded()
                end,
            },
            {
                name = "Imbued Rune of Piety",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Imbued Rune of Piety")() end,
            },
            {
                name = "WaveHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') < 3 end,
            },
            {
                name = "WaveHeal2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') == 2 end,
            },
        },
        ['BigHeal'] = {
            {
                name = "Lay on Hands",
                type = "AA",
                cond = function(self, aaName, target)
                    return self.CombatState == "Combat" and Targeting.GetTargetPctHPs(target) < Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "Hand of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    if not Targeting.GroupedWithTarget(target) then return false end
                    return self.CombatState == "Combat" and (Targeting.TargetIsMyself(target) or Targeting.GetTargetPctHPs(target) < Config:GetSetting('HPCritical'))
                end,
            },
            {
                name = "Forsaken Deepwater Helm",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Deepwater Helm")() end,
                cond = function(self, itemName, target)
                    return self.CombatState == "Combat" and Targeting.TargetIsMyself(target)
                end,
            },
            {
                name = "Imbued Rune of Piety",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Imbued Rune of Piety")() and Config:GetSetting('WaveHealUse') == 1 end,
                cond = function(self, itemName, target)
                    return Targeting.GroupedWithTarget(target)
                end,
            },
            {
                name = "WaveHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') < 3 and Config:GetSetting('WaveHealUse') == 1 end,
                cond = function(self, spell, target)
                    return Targeting.GroupedWithTarget(target)
                end,
            },
            {
                name = "WaveHeal2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') == 2 and Config:GetSetting('WaveHealUse') == 1 end,
                cond = function(self, spell, target)
                    return Targeting.GroupedWithTarget(target)
                end,
            },
            {
                name = "TouchHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoTouchHeal") == 1 end,
            },
        },
        ['MainHeal'] = {
            {
                name = "Cleansing",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoCleansing') == 1 end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Imbued Rune of Piety",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Imbued Rune of Piety")() and Config:GetSetting('WaveHealUse') == 2 end,
                cond = function(self, spell, target)
                    return Targeting.GroupedWithTarget(target)
                end,
            },
            {
                name = "WaveHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') < 3 and Config:GetSetting('WaveHealUse') == 2 end,
                cond = function(self, spell, target)
                    return Targeting.GroupedWithTarget(target)
                end,
            },
            {
                name = "WaveHeal2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWaveHeal') == 2 and Config:GetSetting('WaveHealUse') == 2 end,
                cond = function(self, spell, target)
                    return Targeting.GroupedWithTarget(target)
                end,
            },
            {
                name = "TouchHeal",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoTouchHeal") == 2 end,
            },
        },
    },
    ['Charm']             = {
        ['Assist'] = {
            { name = "Taunt",               type = "Ability", },
            { name = "StunTimer5",          type = "Spell",   load_cond = function(self) return Core.IsTanking() end, },
            { name = "StunTimer4",          type = "Spell",   load_cond = function(self) return Core.IsTanking() end, },
            { name = "Force of Disruption", type = "AA", },
        },
    },
    ['RotationOrder']     = {
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Core.CombatActionsCheck() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Core.CombatActionsCheck()
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
                local aeStun = Config:GetSetting('AEStunUse') > 1 and Core.GetResolvedActionMapItem('AEStun')
                local pbaeStun = Config:GetSetting('PBAEStunUse') > 1 and Core.GetResolvedActionMapItem('PBAEStun')
                local hateAA = Config:GetSetting('AETauntAA') and Casting.CanUseAA("Beacon of the Righteous")
                return Core.IsTanking() and (aeStun or pbaeStun or hateAA)
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
            doFullRotation = true,
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
            name = 'ToTHeals',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (mq.TLO.Me.TargetOfTarget.PctHPs() or 0) < Config:GetSetting('LightHealPoint')
            end,
        },
        { --Defensive actions used proactively to prevent emergencies
            name = 'Defenses',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.IHaveAggro(100) and
                    -- we are under our defense start HP
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('DefenseStart') or
                        -- we have met our defense count threshold
                        self.Helpers.DefensiveDiscCheck(true) or
                        -- we are fighting a named and we are tanking it
                        Targeting.TankingXTNamed())
            end,
        },
        { --Offensive actions to temporarily boost damage dealt
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Casting.BurnCheck() and Core.CombatActionsCheck()
            end,
        },
        { --Stun and damage enemies per your settings
            name = 'AECombat',
            state = 1,
            steps = 1,
            load_cond = function()
                local aeSpell = Config:GetSetting('AEStunUse') == 3 and Core.GetResolvedActionMapItem('AEStun')
                local pbaeSpell = Config:GetSetting('PBAEStunUse') == 3 and Core.GetResolvedActionMapItem('PBAEStun')
                return Core.IsTanking() or aeSpell or pbaeSpell
            end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if not Config:GetSetting('DoAEDamage') or (Core.IsTanking() and mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical')) then return false end
                return combat_state == "Combat" and Combat.AETargetCheck(true) and Core.CombatActionsCheck()
            end,
        },
        { --DPS Spells, includes recourse/gift maintenance
            name = 'Combat',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') then return false end
                return combat_state == "Combat" and Core.CombatActionsCheck()
            end,
        },
    },
    ['Rotations']         = {
        ['Downtime'] = {
            {
                name = "Yaulp",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Blessing of Life",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "ArmorSelfBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            --You'll notice my use of TotalSeconds, this is to keep as close to 100% uptime as possible on these buffs, rebuffing early to decrease the chance of them falling off in combat
            --I considered creating a function (helper or utils) to govern this as I use it on multiple classes but the difference between buff window/song window/aa/spell etc makes it unwieldy
            -- if using duration checks, dont use SelfBuffCheck() (as it could return false when the effect is still on)
            {
                name = "WardProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWardProc') end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 60
                end,
            },
            {
                name_func = function(self)
                    local proc = "Proc Buff Disabled"
                    local procChoice = Config:GetSetting('ProcChoice')
                    if procChoice < 3 then
                        if not Core.GetResolvedActionMapItem("DDProc") or procChoice == 2 then
                            proc = "UndeadProc"
                        else
                            proc = "DDProc"
                        end
                        return proc
                    end
                end,
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
        },
        ['GroupBuff'] = {
            {
                name = "AegoBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('AegoSymbol') < 3 end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "SymbolBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('AegoSymbol') == 2 or Config:GetSetting('AegoSymbol') == 3 end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Brells",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoBrells') end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "HealReceivedAura",
                type = "Spell",
                active_cond = function(self, spell) return Casting.AuraActiveByName(spell.BaseName()) end,
                cond = function(self, spell)
                    return spell() and not Casting.AuraActiveByName(spell.BaseName())
                end,
            },
            {
                name = "ACBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoACBuff') end,
                cond = function(self, spell, target)
                    if (spell.TargetType() or ""):lower() == "single" and not Targeting.TargetIsTanking(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Marr's Salvation",
                type = "AA",
                load_cond = function() return Config:GetSetting('DoSalvation') end,
                cond = function(self, aaName, target)
                    return not Targeting.TargetIsTanking(target) and Casting.GroupBuffAACheck(aaName, target)
                end,
            },
        },
        ['EmergencyDefenses'] = {
            --Note that in Tank Mode, defensive discs are preemptively cycled on named in the (non-emergency) Defenses rotation
            --Abilities should be placed in order of lowest to highest triggered HP thresholds
            --Some conditionals are commented out while I tweak percentages (or determine if they are necessary)
            {
                name = "Armor of Experience",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
                cond = function(self)
                    return mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "OoW_Chest",
                type = "Item",
                cond = function(self, itemName, target)
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            { --Note that on named we may already have a defensive disc running already, could make this remove other discs, but we have other options.
                name = "BlockDisc",
                type = "Disc",
                pre_activate = function(self)
                    if Config:GetSetting('UseBandolier') then
                        Core.SafeCallFunc("Equip Shield", ItemManager.BandolierSwap, "Shield")
                    end
                end,
                cond = function(self, discSpell)
                    return Casting.NoDiscActive()
                end,
            },
            { -- use this only when we have no better active disc to use
                name = "SancDisc",
                type = "Disc",
                cond = function(self, discSpell)
                    return Casting.NoDiscActive() and Casting.DiscOnCoolDown('BlockDisc') and Casting.DiscOnCoolDown('GuardDisc')
                end,
            },
        },
        ['HateTools(AggroTarget)'] = {
            {
                name = "Force of Disruption",
                type = "AA",
            },
            {
                name = "StunTimer5",
                type = "Spell",
            },
            {
                name = "StunTimer4",
                type = "Spell",
            },
            {
                name = "Taunt",
                type = "Ability",
            },
        },
        ['HateTools(AutoTarget)'] = {
            { --8min reuse, save for we still can't get a mob back after trying to taunt
                name = "Ageless Enmity",
                type = "AA",
                cond = function(self, aaName, target)
                    return (Globals.AutoTargetIsNamed or Targeting.GetAutoTargetPctHPs() < 90) and Targeting.LostAutoTargetAggro()
                end,
            },
            {
                name = "Force of Disruption",
                type = "AA",
            },
            {
                name = "Projection of Piety",
                type = "AA",
                cond = function(self, aaName, target)
                    return Globals.AutoTargetIsNamed and (mq.TLO.Target.SecondaryPctAggro() or 0) > 80
                end,
            },
            {
                name = "StunTimer5",
                type = "Spell",
            },
            {
                name = "StunTimer4",
                type = "Spell",
            },
            {
                name = "Taunt",
                type = "Ability",
                cond = function(self, abilityName, target)
                    return Targeting.LostAutoTargetAggro()
                end,
            },
        },
        ['AEHateTools'] = {
            {
                name = "Beacon of the Righteous",
                type = "AA",
            },
            {
                name = "PBAEStun",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('PBAEStunUse') > 1 end,
                cond = function(self, spell, target)
                    return Config:GetSetting('DoAEDamage')
                end,
            },
            {
                name = "AEStun",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AEStunUse') > 1 end,
                cond = function(self, spell, target)
                    return Config:GetSetting('DoAEDamage') or spell.Name() ~= "Sacred Word" -- Sacred Word does damage
                end,
            },
        },
        ['AECombat'] = {
            {
                name = "AEStun",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('AEStunUse') == 3 and Core.GetResolvedActionMapItem('AEStun') end,
            },
            {
                name = "PBAEStun",
                type = "Spell",
                allowDead = true,
                load_cond = function(self) return Config:GetSetting('PBAEStunUse') == 3 and Core.GetResolvedActionMapItem('PBAEStun') end,
            },
            {
                name = "Forsaken Fayguard Bladecatcher",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Fayguard Bladecatcher")() end,
            },
        },
        ['Burn'] = {
            {
                name_func = function(self)
                    return string.format("Fundament: %s Spire of Holiness", Core.IsTanking() and "Third" or "First")
                end,
                type = "AA",
            },
            {
                name = "Inquisitor's Judgement",
                type = "AA",
            },
            {
                name = "Valorous Rage",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoValorousRage') end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                load_cond = function(self) return Config:GetSetting('DoVetAA') end,
            },
            {
                name = "WardProc",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoWardProc') and Core.IsTanking() end,
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            { -- for DPS mode
                name = "ForgeDisc",
                type = "Disc",
                load_cond = function(self) return not Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    if not Targeting.TargetBodyIs(target, "Undead") then return false end
                    return Globals.AutoTargetIsNamed and Casting.NoDiscActive() and not mq.TLO.Me.Song("Rampart")()
                end,
            },
        },
        ['Defenses'] = {
            {
                name = "GuardDisc",
                type = "Disc",
                load_cond = function(self) return Core.IsTanking() end,
                cond = function(self, discSpell, target)
                    return Casting.NoDiscActive() and not mq.TLO.Me.Song("Rampart")()
                end,
            },
            {
                name = "Blood Drinker's Coating",
                type = "Item",
                load_cond = function(self) return Config:GetSetting('DoCoating') end,
                cond = function(self, itemName, target)
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "Armor of the Inquisitor",
                type = "AA",
            },
        },
        ['ToTHeals'] = {
            {
                name = "Gift of Life",
                type = "AA",
                cond = function(self, aaName, target)
                    return (mq.TLO.Me.TargetOfTarget.PctHPs() or 0) < Config:GetSetting('HPCritical')
                end,
            },
            {
                name = "Forsaken Deepwater Gauntlets",
                type = "Item",
                load_cond = function(self) return mq.TLO.FindItem("=Forsaken Deepwater Gauntlets")() end,
            },
            {
                name = "LightHeal",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLightHeal') < 3 end,
            },
            {
                name = "LightHeal2",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoLightHeal') == 2 end,
            },
        },
        ['Combat'] = {
            {
                name = "StunTimer5",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
            },
            {
                name = "StunTimer4",
                type = "Spell",
                load_cond = function(self) return Core.IsTanking() end,
            },
            {
                name = "TwinHealNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoTwinHealNuke') end,
            },
            {
                name = "Yaulp",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "SereneStun",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoSereneStun') end,
            },
            {
                name = "Epic",
                type = "Item",
                cond = function(self, itemName)
                    if Config:GetSetting('UseEpic') == 1 then return false end
                    return (Config:GetSetting('UseEpic') == 3 or (Config:GetSetting('UseEpic') == 2 and Casting.BurnCheck())) and Casting.SelfBuffItemCheck(itemName)
                end,
            },
            {
                name = "QuickUndeadNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoQuickUndeadNuke') end,
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead")
                end,
            },
            {
                name = "UndeadNuke",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoUndeadNuke') end,
                cond = function(self, aaName, target)
                    return Targeting.TargetBodyIs(target, "Undead")
                end,
            },
            {
                name = "Disruptive Persecution",
                type = "AA",
                cond = function(self, aaName, target)
                    return ((mq.TLO.Target.SecondaryPctAggro() or 999) < 60) or not Core.IsTanking()
                end,
            },
            {
                name = "Bash",
                type = "Ability",
                cond = function(self)
                    return Core.ShieldEquipped() or Casting.CanUseAA("2 Hand Bash")
                end,
            },
            {
                name = "Slam",
                type = "Ability",
                load_cond = function(self) return mq.TLO.Me.Ability("Slam")() end,
            },
        },
        ['Weapon Management'] = {
            {
                name = "Equip Shield",
                type = "CustomFunc",
                cond = function(self)
                    if mq.TLO.Me.Bandolier("Shield").Active() then return false end
                    return self.Helpers.shieldNeeded()
                end,
                custom_func = function(self)
                    ItemManager.BandolierSwap("Shield")
                    return true
                end,
            },
            {
                name = "Equip 2Hand",
                type = "CustomFunc",
                cond = function(self)
                    if mq.TLO.Me.Bandolier("2Hand").Active() then return false end
                    return mq.TLO.Me.PctHPs() >= Config:GetSetting('Equip2Hand') and not self.Helpers.shieldNeeded()
                end,
                custom_func = function(self)
                    ItemManager.BandolierSwap("2Hand")
                    return true
                end,
            },
        },
    },
    ['PullAbilities']     = {
        {
            id = 'StunTimer4',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('StunTimer4')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('StunTimer4')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('StunTimer4')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'StunTimer5',
            Type = "Spell",
            DisplayName = function() return Core.GetResolvedActionMapItem('StunTimer5')() or "" end,
            AbilityName = function() return Core.GetResolvedActionMapItem('StunTimer5')() or "" end,
            AbilityRange = 150,
            cond = function(self)
                local resolvedSpell = Core.GetResolvedActionMapItem('StunTimer5')
                if not resolvedSpell then return false end
                return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
            end,
        },
        {
            id = 'Force of Disruption',
            Type = "AA",
            DisplayName = function() return Casting.CanUseAA("Force of Disruption") and "Force of Disruption" or "" end,
            AbilityName = function() return Casting.CanUseAA("Force of Disruption") and "Force of Disruption" or "" end,
            AbilityRange = 150,
            cond = function(self)
                return Casting.CanUseAA("Force of Disruption")
            end,
        },
    },
    ['DefaultConfig']     = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "What Modes does the Paladin have?",
            Answer = "Paladins have a mode for Tanking and a mode for DPS.",
        },

        --AE(All Modes)
        ['AEStunUse']         = {
            DisplayName = "AE Stun Use:",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 101,
            Tooltip = "When to use your Targeted AE Stun (Stun Command / Sacred Word).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Disabled', 'To Regain Hate If In Tank Mode', 'Whenever Possible', },
            Default = 2,
            Min = 1,
            Max = 3,
        },
        ['PBAEStunUse']       = {
            DisplayName = "PBAE Stun Use:",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 102,
            Tooltip = "When to use your PBAE Stun (The Silent Command).",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Disabled', 'To Regain Hate If In Tank Mode', 'Whenever Possible', },
            Default = 2,
            Min = 1,
            Max = 3,
        },

        --Hate Tools
        ['AETauntAA']         = {
            DisplayName = "Use Beacon",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Hate Tools",
            Index = 101,
            Tooltip = "Use Beacon of the Righteous to regain AE aggro in Tank Mode.",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },

        --Defenses
        ['DiscCount']         = {
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
        ['DefenseStart']      = {
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
        ['EmergencyStart']    = {
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
        ['HPCritical']        = {
            DisplayName = "HP Critical",
            Group = "Abilities",
            Header = "Tanking",
            Category = "Defenses",
            Index = 104,
            Tooltip =
            "The HP % that we will use abilities like Lay on Hands or Gift of Life.\nMost other rotations are cut to give our full focus to survival.",
            Default = 20,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
        },

        --Equipment
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
        ['DoCoating']         = {
            DisplayName = "Use Coating",
            Group = "Items",
            Header = "Clickies",
            Category = "Class Config Clickies",
            Index = 102,
            Tooltip = "Click your Blood/Spirit Drinker's Coating when defenses are triggered.",
            Default = false,
        },
        ['UseBandolier']      = {
            DisplayName = "Dynamic Weapon Swap",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 101,
            Tooltip = "Enable 1H+S/2H swapping based off of current health. ***YOU MUST HAVE BANDOLIER ENTRIES NAMED \"Shield\" and \"2Hand\" TO USE THIS FUNCTION.***",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['EquipShield']       = {
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
        ['Equip2Hand']        = {
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
        ['NamedShieldLock']   = {
            DisplayName = "Shield on Named",
            Group = "Items",
            Header = "Bandolier",
            Category = "Bandolier",
            Index = 104,
            Tooltip = "Keep Shield equipped while tanking a named.",
            Default = true,
        },

        --Heals/Cures
        ['DoTouchHeal']       = {
            DisplayName = "Touch Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Choose when the Paladin will use the single-target Touch-line healing spell.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Emergency Use(BigHeal)', 'Standard Use(MainHeal)', 'Never', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoLightHeal']       = {
            DisplayName = "Light Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 102,
            Tooltip = "Choose how many ToT heals (\"Light of\" line) to keep memorized, if any.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Current Tier', 'Current Tier + Last Tier', 'Never', },
            Default = 2,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoWaveHeal']        = {
            DisplayName = "Wave Heal Use:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 103,
            Tooltip = "Choose how many group heals to keep memorized, if any.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Current Tier', 'Current Tier + Last Tier', 'Never', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['WaveHealUse']       = {
            DisplayName = "Use Waves for ST:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 104,
            Tooltip = "Use your Wave Heals as single-target heals as needed.",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Emergency Use(BigHeal)', 'Standard Use(MainHeal)', 'Never', },
            Default = 1,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['DoCleansing']       = {
            DisplayName = "Cleansing HoT:",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 105,
            Tooltip = "Select your preference for Cleansing HoT use:",
            RequiresLoadoutChange = true,
            Type = "Combo",
            ComboOptions = { 'Automatic', 'Memorize-Only (Manual Use)', 'Never', },
            Default = 3,
            Min = 1,
            Max = 3,
            ConfigType = "Advanced",
        },
        ['KeepPurityMemmed']  = {
            DisplayName = "Mem Crusader's Cure",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 101,
            Tooltip = "Memorize your Crusader's xxx line (Cure poi/dis/curse) when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if enabled.",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['KeepCurseMemmed']   = {
            DisplayName = "Mem Remove Curse",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Curing",
            Index = 102,
            Tooltip = "Memorize remove curse spell when possible (depending on other selected options). \n" ..
                "Please note that we will still memorize a cure out-of-combat if needed, and AA will always be used if enabled.",
            RequiresLoadoutChange = true,
            Default = false,
        },

        --Combat
        ['DoTwinHealNuke']    = {
            DisplayName = "Twin Heal Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 101,
            Tooltip = "Use Twin Heal Nuke Spells",
            RequiresLoadoutChange = true,
            Default = true,
            ConfigType = "Advanced",
        },
        ['DoSereneStun']      = {
            DisplayName = "Do Serene Stun",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Stun",
            Index = 103,
            Tooltip = "Use the Quellious/Serene stun line (long duration stun with DD component).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoUndeadNuke']      = {
            DisplayName = "Do Undead Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 102,
            Tooltip = "Use the standard Undead nuke line.",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoQuickUndeadNuke'] = {
            DisplayName = "Do Undead Quick Nuke",
            Group = "Abilities",
            Header = "Damage",
            Category = "Direct",
            Index = 103,
            Tooltip = "Use the quick undead nuke line (which includes a potential snare and ac debuff trigger).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoValorousRage']    = {
            DisplayName = "Valorous Rage",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 101,
            Tooltip = "Use the Valorous Rage AA during burns.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoVetAA']           = {
            DisplayName = "Use Vet AA",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 102,
            Tooltip = "Use Veteran AA such as Intensity of the Resolute or Armor of Experience as necessary.",
            Default = true,
            ConfigType = "Advanced",
            RequiresLoadoutChange = true,
        },

        --Buffs
        ['AegoSymbol']        = {
            DisplayName = "Aego/Symbol Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 101,
            Tooltip =
            "Choose whether to use the Aegolism or Symbol Line of HP Buffs.\nPlease note using both is supported for party members who block buffs, but these buffs do not stack once we transition from using a HP Type-One buff in place of Aegolism.",
            Type = "Combo",
            ComboOptions = { 'Aegolism', 'Both (See Tooltip!)', 'Symbol', 'None', },
            Default = 1,
            Min = 1,
            Max = 4,
            RequiresLoadoutChange = true,
        },
        ['DoACBuff']          = {
            DisplayName = "Use AC Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 102,
            Tooltip =
                "Use your single-slot AC Buff on the Main Assist. USE CASES:\n" ..
                "You have Aegolism selected and are below level 40 (We are still using a HP Type One buff).\n" ..
                "You have Symbol selected and don't have another Type One Buff.\n" ..
                "Leaving this on in other cases is not likely to cause issue, but may cause unnecessary buff checking.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['DoBrells']          = {
            DisplayName = "Do Brells",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 103,
            Tooltip = "Enable Casting Brells",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoWardProc']        = {
            DisplayName = "Do Ward Proc",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 103,
            Tooltip = "Use your Ward of Tunare defensive proc buff.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['DoSalvation']       = {
            DisplayName = "Marr's Salvation",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 104,
            Tooltip = "Use your group hatred reduction buff AA.",
            Default = true,
            RequiresLoadoutChange = true,
        },
        ['ProcChoice']        = {
            DisplayName = "Proc Buff Choice:",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Self",
            Index = 104,
            Tooltip =
                "Choose which DD proc buff you prefer. The Undead proc does higher damage but is restricted to that target type.\n" ..
                "Please note that we will use the undead proc at low levels if you select Standard and it is not yet available.",
            Type = "Combo",
            ComboOptions = { 'All Enemies', 'Undead', 'Disabled', },
            Default = 1,
            Min = 1,
            Max = 3,
            FAQ = "Why am I using and Undead proc, I'm not fighting any undead?",
            Answer = "If you have elected to use the Standard DD proc (default) and it is not yet available, we will use the Undead proc still.\n" ..
                "Your desired proc can be adjusted with the Proc Buff Choice setting in Self Buff category.",
        },
        ['HealPriority']      = {
            DisplayName = "Healing Priority",
            Group = "Abilities",
            Header = "Recovery",
            Category = "Healing Thresholds",
            Index = 101,
            Type = "Combo",
            ComboOptions = { 'Ignore', 'Big Heal Point', },
            Default = 2,
            Min = 1,
            Max = 2,
            Tooltip = "When to yield offensive rotations for healing:\n1 - Ignore (never)\n2 - Big Heal Point",
            ConfigType = "Advanced",
        },
    },
    ['ClassFAQ']          = {
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
