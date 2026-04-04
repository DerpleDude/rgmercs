local mq           = require('mq')
local Config       = require('utils.config')
local Globals      = require('utils.globals')
local Comms        = require("utils.comms")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")
local Logger       = require("utils.logger")

local _ClassConfig = {
    _version            = "1.5 - EQ Might",
    _author             = "Derple, Grimmier, Algar, Robban",
    ['ModeChecks']      = {
        CanMez     = function() return true end,
        CanCharm   = function() return true end,
        IsCharming = function() return Config:GetSetting('CharmOn') end,
        IsMezzing  = function() return Config:GetSetting('MezOn') end,
        IsRezing   = function() return Core.GetResolvedActionMapItem('RezStaff') ~= nil and (Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0) end,
    },
    ['Modes']           = {
        'Default',
    },
    ['ItemSets']        = {
        ['RezStaff'] = {
            "Legendary Fabled Staff of Forbidden Rites",
            "Fabled Staff of Forbidden Rites",
            "Legendary Staff of Forbidden Rites",
        },
        ['Epic'] = {
            "Staff of Eternal Eloquence",
            "Oculus of Persuasion",
        },
        ['OoW_Chest'] = {
            "Mindreaver's Vest of Coercion",
            "Charmweaver's Robe",
        },
    },
    ['AbilitySets']     = {
        --Commented any currently unused spell lines
        ['TwincastAura'] = {
            "Entrancer's Aura",
        },
        ['SpellProcAura'] = {
            "Illusionist's Aura",
            "Beguiler's Aura",
        },
        ['HasteBuff'] = {
            "Speed of Ellowind",
            "Hastening of Salik",
            "Speed of Salik",
            "Vallon's Quickening",
            -- "Speed of Vallon",
            "Speed of the Brood",
            "Visions of Grandeur",
            "Wondrous Rapidity",
            "Aanya's Quickening",
            "Swift Like the Wind",
            "Celerity",
            "Alacrity",
            "Quickness",
        },
        ['ManaRegen'] = {
            "Seer's Intuition",
            "Ancient: Blessing of Clairvoyance",
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
        ['TankIllusionBuff'] = {
            "Boon of the Brute",
        },
        ['IllusionBuff'] = {
            "Boon of the Sanguinarch",
            "Boon of the Vampire",
            "Night's Dark Terror",
            "Boon of the Garou",
        },
        ['SelfHPBuff'] = {
            "Sorcerous Shield",
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
            "Draconic Rune",
            "Ethereal Rune",
            "Arcane Rune",
        },
        ['SingleRune'] = {
            "Rune of Ellowind",
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
        -- "Aegist of Alendar",
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
            "Coax",
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
            "Fractured Consciousness",
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
            "Thin Air",
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
            "Polychromatic Assault",
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
        ['PetSpell'] = { -- Might Specific: Monster Summoning avail on ENC and superior to normal pets
            "Monster Summoning V",
            "Monster Summoning IV",
            "Monster Summoning III",
            "Monster Summoning II",
            "Monster Summoning I",
            -- "Salik's Animation",
            -- "Aeldorb's Animation",
            -- "Zumaik's Animation",
            -- "Kintaz's Animation",
            -- "Yegoreff's Animation",
            -- "Aanya's Animation",
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
            "Bewilderment",
            "Perplexing Flash",
            "Euphoria",
            "Echoing Madness",
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
        -- "Quiet Mind",
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
        -- ['ColoredNuke'] = {
        --     "Colored Chaos",
        -- },
        ['Minionskin'] = { --EQM Custom: HP/Regen/mitigation (May need to block druid HP buff line on pet)
            "Major Minionskin",
            "Greater Minionskin",
            "Minionskin",
            "Lesser Minionskin",
        },
        ['KoadicRune'] = {
            "Koadic's Guard IV",
            "Koadic's Guard III",
            "Koadic's Guard II",
            "Koadic's Guard I",
        },
        ['PetHealSpell'] = {
            "Renewal of Lucifer",
        },
    },
    ['RotationOrder']   = {
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
            name = 'Cripple',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoCripple') end,
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
            name = 'PetHealing',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, target) return (mq.TLO.Me.Pet.PctHPs() or 100) < Config:GetSetting('PetHealPct') end,
        },
    },
    ['HelperFunctions'] = { --used to autoinventory our crystals after summon. Crystal is a group-wide spell on Laz.
        DoRez = function(self, corpseId)
            local rezStaff = self.ResolvedActionMap['RezStaff']

            if mq.TLO.Me.ItemReady(rezStaff)() then
                if Casting.OkayToRez(corpseId) then
                    return Casting.UseItem(rezStaff, corpseId)
                end
            end

            return false
        end,
        StashCrystal = function(aaName)
            mq.delay("2s", function() return mq.TLO.Cursor.ID() == mq.TLO.Me.AltAbility(aaName).Spell.Base(1)() end)

            if not mq.TLO.Cursor() then
                Logger.log_debug("No valid item found on cursor, item handling aborted.")
                return false
            end

            Logger.log_info("Sending the %s to our bags.", mq.TLO.Cursor())
            mq.delay(Config:GetSetting("AICrystalDelay"))
            Core.DoCmd("/autoinventory")
        end,
    },
    ['Rotations']       = {
        ['Downtime']      = {
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
                load_cond = function(self) return Casting.CanUseAA('Auroria Mastery') end,
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
                name = "Azure Mind Crystal",
                type = "AA",
                load_cond = function() return Config:GetSetting('SummonAzure') end,
                cond = function(self, aaName, target)
                    local crystalAA = mq.TLO.Me.AltAbility(aaName)
                    if not crystalAA and crystalAA() then return false end
                    local crystal = crystalAA.Spell.Base(1)()
                    return not mq.TLO.FindItem(string.format("id %s", crystal))()
                end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.ClassConfig.HelperFunctions.StashCrystal(aaName))
                    end
                end,
            },
            {
                name = "Sanguine Mind Crystal",
                type = "AA",
                load_cond = function() return Config:GetSetting('SummonSanguine') end,
                cond = function(self, aaName, target)
                    local crystalAA = mq.TLO.Me.AltAbility(aaName)
                    if not crystalAA and crystalAA() then return false end
                    local crystal = crystalAA.Spell.Base(1)()
                    return not mq.TLO.FindItem(string.format("id %s", crystal))()
                end,
                post_activate = function(self, aaName, success)
                    if success then
                        Core.SafeCallFunc("Autoinventory", self.ClassConfig.HelperFunctions.StashCrystal(aaName))
                    end
                end,
            },
        },
        ['PetSummon']     = {
            {
                name = "Artifact of Asterion",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Asterion")() end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "PetSpell",
                type = "Spell",
                load_cond = function(self)
                    return not Config:GetSetting("UseDonorPet") or not mq.TLO.FindItem("=Artifact of Asterion")()
                end,
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() > 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff']       = {
            {
                name = "HasteBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.ID()).ID() end,
                cond = function(self, spell)
                    return Casting.PetBuffCheck(spell) and Casting.LocalBuffCheck(5521, true) -- Don't cast if we have Hastening of Salik
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
        ['GroupBuff']     = {
            {
                name = "Ancient Artifact of Clairvoyance",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and mq.TLO.FindItem("=Ancient Artifact of Clairvoyance")() end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "ManaRegen",
                type = "Spell",
                load_cond = function() return mq.TLO.Me.Level() < 68 or not mq.TLO.FindItem("=Ancient Artifact of Clairvoyance")() end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Salik",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 67 and mq.TLO.FindItem("=Artifact of Salik")() end,
                cond = function(self, itemName, target)
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "HasteBuff",
                type = "Spell",
                load_cond = function() return mq.TLO.Me.Level() < 67 or not mq.TLO.FindItem("=Artifact of Salik")() end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsAMelee(target) then return false end
                    -- Don't cast if we have Hastening of Salik
                    return Casting.GroupBuffCheck(spell, target) and Casting.AddedBuffCheck(5521, target)
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
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "TankIllusionBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoTankIllusionBuff') end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "IllusionBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoIllusionBuff') end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if Config:GetSetting('DoTankIllusionBuff') and Targeting.TargetIsATank(target) and Core.GetResolvedActionMapItem('TankIllusionBuff') then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "Artifact of Mana Strike",
                type = "Item",
                load_cond = function() return Config:GetSetting('DoProcBuff') and mq.TLO.FindItem("=Artifact of Mana Strike")() end,
                cond = function(self, itemName, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.GroupBuffItemCheck(itemName, target)
                end,
            },
            {
                name = "SpellProcBuff",
                type = "Spell",
                load_cond = function() return Config:GetSetting('DoProcBuff') and not mq.TLO.FindItem("=Artifact of Mana Strike")() end,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsACaster(target) then return false end
                    return Casting.CastReady(spell) and Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "KoadicRune",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    if not Targeting.TargetIsATank(target) then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "GroupRune",
                type = "Spell",
                load_cond = function() return Config:GetSetting('RuneChoice') == 2 end,
                active_cond = function(self, spell) return mq.TLO.Me.FindBuff("id " .. tostring(spell.ID()))() ~= nil end,
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target)
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
                    return Casting.GroupBuffCheck(spell, target)
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
            {
                name = "Artifact of Asterion",
                type = "Item",
                load_cond = function(self) return Config:GetSetting("UseDonorPet") and mq.TLO.FindItem("=Artifact of Asterion")() end,
                cond = function(self, _) return mq.TLO.Me.Pet.ID() == 0 end,
                post_activate = function(self, spell, success)
                    if success and mq.TLO.Me.Pet.ID() > 0 then
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetHealing']    = {
            {
                name = "Companion's Blessing",
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
        ['Emergency']     = {
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
        ['Dispel']        = {
            {
                name = "Dispel",
                type = "Spell",
                cond = function(self, spell, target)
                    if mq.TLO.Target.ID() == 0 then return false end
                    return mq.TLO.Target.Beneficial() ~= nil
                end,
            },
        },
        ['DPS']           = {
            {
                name = "Summon Companion",
                type = "AA",
                cond = function(self, aaName, target)
                    if mq.TLO.Me.Pet.ID() == 0 then return false end
                    local pet = mq.TLO.Me.Pet
                    return not pet.Combat() and (pet.Distance3D() or 0) > 200
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
                name = "Trinket of Suffocation",
                type = "Item",
                load_cond = function() return mq.TLO.Me.Level() >= 68 and mq.TLO.FindItem("=Trinket of Suffocation")() end,
                cond = function(self, itemName, target)
                    if Config:GetSetting('DotNamedOnly') and not Globals.AutoTargetIsNamed then return false end
                    return Casting.DotItemCheck(itemName, target)
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
                name = "MindDot",
                type = "Spell",
                load_cond = function() return Config:GetSetting("DoMindDot") end,
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
        ['Burn']          = {
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
        ['Tash']          = {
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
        ['Cripple']       = {
            {
                name = "CrippleSpell",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['Slow']          = {
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
    },
    ['SpellList']       = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "MezSpell",         cond = function(self) return Config:GetSetting('DoSTMez') end, },
                { name = "MezAESpell",       cond = function(self) return Config:GetSetting('DoAEMez') end, },
                { name = "CharmSpell",       cond = function(self) return Config:GetSetting('CharmOn') end, },
                { name = "TashSpell",        cond = function(self) return Config:GetSetting('DoTash') end, },
                { name = "SlowSpell",        cond = function(self) return Config:GetSetting('DoSlow') and not Casting.CanUseAA("Dreary Deeds") end, },
                { name = "CrippleSpell",     cond = function(self) return Config:GetSetting('DoCripple') end, },
                { name = "SpinStunSpell",    cond = function(self) return Config:GetSetting('DoSpinStun') > 1 end, },
                { name = "PBAEStunSpell",    cond = function(self) return Config:GetSetting('DoAEStun') > 1 end, },
                { name = "IllusionBuff",     cond = function(self) return Config:GetSetting('DoIllusionBuff') end, },
                { name = "TankIllusionBuff", cond = function(self) return Config:GetSetting('DoTankIllusionBuff') end, },
                { name = "SpellProcBuff",    cond = function(self) return Config:GetSetting('DoProcBuff') end, },
                { name = "Dispel",           cond = function(self) return Config:GetSetting('DoDispel') end, },
                { name = "MagicNuke",        cond = function(self) return Config:GetSetting('DoNuke') end, },
                { name = "StrangleDot",      cond = function(self) return Config:GetSetting('DoStrangleDot') end, },
                { name = "MindDot",          cond = function(self) return Config:GetSetting('DoMindDot') end, },
                { name = "PetHealSpell",     cond = function(self) return Config:GetSetting('DoPetHealSpell') end, },
                { name = "HateBuff",         cond = function(self) return Config:GetSetting('DoHateBuff') end, },
                { name = "SingleRune",       cond = function(self) return Config:GetSetting('RuneChoice') == 1 end, },
                { name = "GroupRune",        cond = function(self) return Config:GetSetting('RuneChoice') == 2 end, },
                { name = "GroupSpellShield", cond = function(self) return Config:GetSetting('DoGroupSpellShield') end, },
                { name = "KoadicRune", },
                -- todo: Add PBAE Mez for filler (manual use, script doesnt use it)
            },
        },
    },
    ['PullAbilities']   = {
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
    ['DefaultConfig']   = {
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
        ['DoIllusionBuff']     = {
            DisplayName = "Cast Illusion Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 105,
            Tooltip = "Enable casting your Illusion Proc Buff (NDT and EQM customs).",
            RequiresLoadoutChange = true,
            Default = true,
        },
        ['DoTankIllusionBuff'] = {
            DisplayName = "Cast Tank Illusion Buff",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 106,
            Tooltip = "Enable casting your Tank Illusion Proc Buff (e.g Boon of the Brute).",
            RequiresLoadoutChange = true,
            Default = false,
        },
        ['DoHateBuff']         = {
            DisplayName = "Do Hate Visage",
            Group = "Abilities",
            Header = "Buffs",
            Category = "Group",
            Index = 107,
            Tooltip = "Use your hatred visage buff on your tank.",
            RequiresLoadoutChange = true,
            Default = false,
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
        ['DoCripple']          = {
            DisplayName = "Cast Cripple",
            Group = "Abilities",
            Header = "Debuffs",
            Category = "Misc Debuffs",
            Index = 102,
            Tooltip = "Enable casting Cripple spells.",
            RequiresLoadoutChange = true,
            Default = false,
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
            Tooltip = "Use your mana drain/magic damage (Mind Line) Dot.",
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
            Tooltip = "Summon Azure Mind Crystals (Mana Restore) for yourself.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['SummonSanguine']     = {
            DisplayName = "Sanguine Mind Crystal",
            Group = "Items",
            Header = "Item Summoning",
            Category = "Item Summoning",
            Index = 102,
            Tooltip = "Summon Sanguine Mind Crystals (Health Restore) for yourself.",
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
        ['UseDonorPet']        = {
            DisplayName = "Summon Asterion",
            Group = "Abilities",
            Header = "Pet",
            Category = "Pet Summoning",
            Index = 101,
            Tooltip = "Use your Artifact of Asterion to summon the donor minotaur pet.",
            RequiresLoadoutChange = true, -- this is a load condition
            Default = true,
        },
        ['DoPetHealSpell']     = {
            DisplayName = "Pet Heal Spell",
            Group = "Abilities",
            Header = "Recovery",
            Category = "General Healing",
            Index = 101,
            Tooltip = "Mem and cast your Pet Heal (Salve) spell. AA Pet Heals are always used in emergencies.",
            Default = false,
            RequiresLoadoutChange = true,
        },
        ['PetHealPct']         = {
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
