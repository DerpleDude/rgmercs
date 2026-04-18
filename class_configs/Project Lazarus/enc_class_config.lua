local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require("utils.globals")
local Comms        = require("utils.comms")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local DanNet       = require('lib.dannet.helpers')
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version          = "1.4 - Project Lazarus",
    _author           = "Derple, Grimmier, Algar, Robban",
    ['ModeChecks']    = {
        CanMez     = function() return true end,
        CanCharm   = function() return true end,
        IsCharming = function() return Config:GetSetting('CharmOn') end,
        IsMezzing  = function() return Config:GetSetting('MezOn') end,
    },
    ['Modes']         = {
        'Default',
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
        --Commented any currently unused spell lines
        --Laz spells to look into: Echoing Madness
        ['TwincastAura'] = {
            "Twincast Aura",
        },
        ['SpellProcAura'] = {
            "Illusionist's Aura",
            "Beguiler's Aura",
        },
        ['VisageAura'] = {
            "Aura of Endless Glamour",
        },
        ['GroupHasteBuff'] = {
            "Hastening of Salik",
            "Vallon's Quickening",
            "Speed of the Brood",
        },
        ['SingleHasteBuff'] = {
            "Speed of Salik",
            "Speed of Vallon",
            "Visions of Grandeur",
            "Wondrous Rapidity",
            "Aanya's Quickening",
            "Swift Like the Wind",
            "Celerity",
            "Alacrity",
            "Quickness",
        },
        ['ManaRegen'] = {
            "Voice of Clairvoyance",
            "Clairvoyance",
            "Voice of Quellious",
            "Tranquility",
            "Koadic's Endless Intellect",
            "Gift of Pure Thought",
            "Clarity II",
            "Boon of the Clear Mind",
            "Clarity",
            "Breeze",
        },
        ['MezBuff'] = {
            "Ward of Bedazzlement",
        },
        ['NdtBuff'] = {
            "Boon of the Legion",
            "Night's Dark Terror",
            "Boon of the Garou",
        },
        ['SelfHPBuff'] = {
            "Mystic Shield",
            "Shield of Maelin",
            "Shield of the Arcane",
            "Shield of the Magi",
            "Arch Shielding",
            "Greater Shielding",
            "Major Shielding",
            "Shielding",
            "Lesser Shielding",
            "Minor Shielding",
        },
        ['SelfRune1'] = {
            "Ethereal Rune",
            "Arcane Rune",
        },
        ['SingleRune'] = {
            "Rune of Salik",
            "Rune of Zebuxoruk",
            "Rune V",
            "Rune IV",
            "Rune III",
            "Rune II",
            "Rune I",
        },
        ['GroupRune'] = {
            "Rune of Rikkukin",
            "Rune of the Scale",
        },
        ['HateBuff'] = {
            "Horrifying Visage",
            "Haunting Visage",
        },
        -- ['SingleSpellShield'] = {
        --     "Wall of Alendar",
        --     "Bulwark of Alendar",
        --     "Protection of Alendar",
        --     "Guard of Alendar",
        --     "Ward of Alendar",
        -- },
        ['GroupSpellShield'] = {
            "Circle of Alendar",
        },
        ['SpellProcBuff'] = {
            "Mana Recursion",
            "Mana Flare",
        },
        ['PBAEStunSpell'] = {
            "Color Snap",
            "Color Cloud",
            "Color Slant",
            "Color Skew",
            "Color Shift",
            "Color Flux",
        },
        ['SpinStunSpell'] = {
            "Whirl Till You Hurl",
        },
        ['CharmSpell'] = {
            "Ancient: Voice of Muram",
            "True Name",
            "Compel",
            "Command of Druzzil",
            "Beckon",
            "Dictate",
            "Boltran's Agacerie",
            "Ordinance",
            "Allure",
            "Cajoling Whispers",
            "Beguile",
            "Charm",
        },
        ['CrippleSpell'] = {
            -- "Synaptic Seizure", -- In resources but not available
            "Synapsis Spasm",
            "Cripple",
            "Incapacitate",
            "Listless Power",
            "Disempower",
            "Enfeeblement",
        },
        ['SlowSpell'] = {
            "Desolate Deeds",
            "Dreary Deeds",
            "Forlorn Deeds",
            "Shiftless Deeds",
            "Tepid Deeds",
            "Languid Pace",
        },
        ['Dispel'] = {
            "Abashi's Disempowerment",
            "Recant Magic",
            "Pillage Enchantment",
            "Nullify Magic",
            "Strip Enchantment",
            "Cancel Magic",
            "Taper Enchantment",
        },
        ['TashSpell'] = {
            "Echo of Tashan",
            "Howl of Tashan",
            "Tashanian",
            "Tashania",
            "Tashani",
            "Tashina",
        },
        -- ['ManaDrainNuke'] = {
        --     "Torment of Scio",
        --     "Torment of Argli",
        --     "Scryer's Trespass",
        --     "Wandering Mind",
        --     "Mana Sieve",
        -- },
        ['StrangleDot'] = {
            "Arcane Noose",
            "Strangle",
            "Asphyxiate",
            "Gasping Embrace",
            "Suffocate",
            "Choke",
            "Suffocating Sphere",
            "Shallow Breath",
        },
        ['MindDot'] = {
            "Mind Shatter",
        },
        ['MagicNuke'] = {
            "Ancient: Neurosis",
            "Psychosis",
            "Ancient: Chaos Madness",
            "Madness of Ikkibi",
            "Insanity",
            "Ancient: Chaotic Visions",
            "Dementing Visions",
            "Dementia",
            "Discordant Mind",
            "Anarchy",
            "Chaos Flux",
            "Sanity Warp",
            "Chaotic Feedback",
            "Chromarcana",
        },
        ['PetSpell'] = {
            "Salik's Animation",
            "Aeldorb's Animation",
            "Zumaik's Animation",
            "Kintaz's Animation",
            "Yegoreff's Animation",
            "Aanya's Animation",
            "Boltran's Animation",
            "Uleen's Animation",
            "Sagar's Animation",
            "Sisna's Animation",
            "Shalee's Animation",
            "Kilan's Animation",
            "Mircyl's Animation",
            "Juli's Animation",
            "Pendril's Animation",
        },
        ['MezAESpell'] = {
            "Wake of Felicity",
            "Bliss of the Nihil",
            "Fascination",
            "Mesmerization",
            "Bewildering Wave",
            "Stupefying Wave",
        },
        -- ['MezPBAESpell'] = {
        --     "Circle of Dreams",
        --     "Word of Morell",
        --     "Entrancing Lights",
        --     "Bewilderment",
        --     "Wonderment",
        -- },
        ['MezSpell'] = {
            "Euphoria",
            "Felicity",
            "Bliss",
            "Sleep",
            "Apathy",
            "Ancient: Eternal Rapture",
            "Rapture",
            "Glamour of Kintaz",
            "Enthrall",
            "Mesmerize",
        },
        -- ['MezSpellFast'] = {
        --     "Perplexing Flash",
        -- },
        -- ['BlurSpell'] = {
        --     "Memory Flux",
        --     "Reoccurring Amnesia",
        --     "Memory Blur",
        -- },
        -- ['AEBlurSpell'] = {
        --     "Blanket of Forgetfulness",
        --     "Mind Wipe",
        -- },
        -- ['CalmSpell'] = {
        --     "Placate",
        --     "Pacification",
        --     "Pacify",
        --     "Calm",
        --     "Soothe",
        --     "Lull",
        -- },
        -- ['FearSpell'] = {
        --     "Anxiety Attack",
        --     "Jitterskin",
        --     "Phobia",
        --     "Trepidation",
        --     "Invoke Fear",
        --     "Chase the Moon",
        --     "Fear",
        -- },
        -- ['RootSpell'] = {
        --     "Greater Fetter",
        --     "Fetter",
        --     "Paralyzing Earth",
        --     "Immobilize",
        --     "Instill",
        --     "Root",
        -- },
        ['HasteManaCombo'] = {
            "Unified Alacrity",
        },
        ['ColoredNuke'] = {
            "Colored Chaos",
        },
        ['Chromaburst'] = {
            "Chromaburst",
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
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        { --Summon pet even when buffs are off on emu
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() == 0 and Casting.OkayToPetBuff() and not Core.IsCharming() and Casting.AmIBuffable()
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
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        { --Slow and Tash separated so we use both before we start DPS
            name = 'Slow',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSlow') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'Dispel',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoDispel') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.OkayToDebuff()
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
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
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
    ['Helpers']       = { --used to autoinventory our crystals after summon. Crystal is a group-wide spell on Laz.
        StashCrystal = function(aaName)
            mq.delay("2s", function() return mq.TLO.Cursor.ID() == mq.TLO.Me.AltAbility(aaName).Spell.Base(1)() end)

            if not mq.TLO.Cursor() then
                Logger.log_debug("No valid item found on cursor, item handling aborted.")
                return false
            end

            Logger.log_info("Sending the %s to our bags.", mq.TLO.Cursor())

            Comms.PrintGroupMessage("%s summoned, issuing autoinventory command momentarily.", mq.TLO.Cursor())
            mq.delay(Config:GetSetting("AICrystalDelay"))
            Core.DoGroupCmd("/autoinventory")
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
                name_func = function(self)
                    return Casting.GetFirstAA({ "Mana Draw", "Gather Mana", })
                end,
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
                    if not Targeting.TargetIsATank(target) then return false end
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
            --         if not Config:GetSetting('DoAggroRune') or not Targeting.TargetIsATank(target) then return false end
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
                    return Globals.AutoTargetIsNamed and (mq.TLO.Me.TargetOfTarget.ID() or Core.GetMainAssistId()) ~= Core.GetMainAssistId()
                end,
            },

        },
        ['Emergency'] = {
            {
                name = "Self Stasis",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.Me.TargetOfTarget.ID() == mq.TLO.Me.ID() and mq.TLO.Target.ID() == Globals.AutoTargetID
                end,
                post_activate = function(self, aaName, success)
                    if success and mq.TLO.Me.Buff("Self Stasis")() then
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
                load_cond = function() return Config:GetSetting("DoNuke") end,
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
                load_cond = function() return Config:GetSetting("DoColored") end,
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
                { name = "CharmSpell",       cond = function(self) return Config:GetSetting('CharmOn') end, },
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
        ['AICrystalDelay']     = {
            DisplayName = "Crystal Autoinv Delay",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 103,
            Tooltip = "Delay in ms before /autoinventory after summoning, adjust if you notice items left on cursors regularly.",
            Default = 150,
            Min = 1,
            Max = 500,
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
