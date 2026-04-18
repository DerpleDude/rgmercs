-- Requires: here we load and run libraries ("utils" as we have named them) which contain functions that we call in this file.
-- Every file is different, we generally only require if we actually need something from that file.
-- If you end up using a table or function from a library that isn't called here, you'll need to add it. You can copy paste from other files!
-- Please not that modules are accessed differently (Through the Exec function in the Modules util). Ask in Discord for help with that one if you need that access!
-- Reference: https://www.lua.org/pil/8.1.html
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

-- Tooltips: 100% optional. Most configs don't have them.
-- They are niceties to explain rotation entries in the UI.
local Tooltips     = {
    Mantle         = "Spell Line: Melee Absorb Proc",
    Carapace       = "Spell Line: Melee Absorb Proc",
    CombatEndRegen = "Discipline Line: Endurance Regen (In-Combat Useable)",
    EndRegen       = "Discipline Line: Endurance Regen (Out of Combat)",
    Blade          = "Ability Line: Double 2HS Attack w/ Accuracy Mod",
    Crimson        = "Disicpline Line: Triple Attack w/ Accuracy Mod",
    --Further tooltips omitted for brevity
}

-- The class config table itself, which is largely controlled by the class module. Version/Author can be as you'd like, this is what displays in the UI.
local _ClassConfig = {
    _version          = "3.0 - Live",
    _author           = "Algar, Derple",
    -- Mode Checks: Functions to check under what conditions a PC will perform certain special checks or actions.
    -- For example, we won't run rez checks if your IsRezzing doesn't return true for that PC.
    -- SHD CAN'T DO ALL THIS STUFF! I stole them from other configs for illustrations. Generally, you can copy the checks from the default config for your class.
    ['ModeChecks']    = {
        IsTanking  = function() return Core.IsModeActive("Tank") end, -- This is the only check actually present in the SK config.
        CanMez     = function() return true end,
        CanCharm   = function() return true end,
        IsMezzing  = function() return Config:GetSetting('MezOn') end,
        IsCharming = function() return Config:GetSetting('CharmOn') and mq.TLO.Pet.ID() == 0 end,
        IsHealing  = function() return true end,
        IsCuring   = function() return true end,
        IsRezing   = function() return Config:GetSetting('DoBattleRez') or Targeting.GetXTHaterCount() == 0 end,
    },

    -- Modes: Set in the options. Can be used as a condition to load a rotation, perform an action, etc.
    -- Must also be added to the "Mode" setting at the bottom (omitted in this example file).
    -- 'Tank' and 'DPS' are abitary names. Some examples of other modes could be splitting DPS into raid and group modes, etc...
    -- ... We have modes for PBAE use, modes based on level, you can use your imagination!
    ['Modes']         = {
        'Tank',
        'DPS',
    },

    -- Themes control the colors in the UI. Feel free to play with these! Derple would love PR's for other classes, as not many have them added!
    ['Themes']        = {
        ['Tank'] = { -- Note: I did not omit anything from this table. This is everything you need!
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

    -- Item and Ability Sets
    -- These are the main tables that we iterate through to find the best action for a given entry when we start mercs.
    -- A "resolved action" is the action that the script has selected as the best for that set. The term is used in the configs and the UI.
    -- The order matters! It is recommended (but not required) to list in reverse-level order (highest at top).
    -- You will note many configs have one or more sets that don't follow this recommendation, we are slowly converting to the preferred method.
    -- In the event that two items are listed, the first item found is the one used.
    -- For each table, the script will select the highest level spell out of those we have scribed.
    -- In the event that two spells of the same level are listed, the first spell found is the one used.
    -- Any spell/song/disc rotation entry should also have an entry here, even if it is a single spell!
    -- Note that AA do not use sets (AA are referred to directly by name in their entries).
    -- Note that single items (i.e, not in a set) do not require an entry here (Items can be referred to directly by name in their entries).
    -- Generally, if you aren't using a spell line at all, you could consider commenting the entire thing out to stop it from being processed on load. This way it is still there if you change your mind.
    ['ItemSets']      = {
        ['Epic'] = {
            -- In this set, we will used the epic 2.0 if it is present (Dark Blessing), and use the epic 1.5 if we have it but not the 2.0.
            -- If we don't have either, the rotation UI will list "Epic" as the action, but not show either of these as the "Resolved Action"
            -- In this case, if we check for the resolved action for this set later, it will return nil.
            "Innoruuk's Dark Blessing",
            "Innoruuk's Voice",
        },
        ['OoW_Chest'] = {
            "Heartstiller's Mail Chestguard",
            "Duskbringer's Plate Chestguard of the Hateful",
        },
        -- further sets omitted
    },
    -- Please note that for brevity, I have removed most of the Ability Sets. This is not a functioning config.
    ['AbilitySets']   = {
        -- As noted above, even a single ability should be its own "set".
        ['Deflection'] = { 'Deflection Discipline', },
        ['LeechCurse'] = { 'Leechcurse Discipline', },

        -- Note that this table is "backwards". It still works. Going back and forth confuses people, though. I'm guilty of being confused and confusing others.
        ['Mantle'] = {
            "Ichor Guard", -- Level 56, Timer 5
            "Soul Guard",
            "Soul Shield",
            "Soul Carapace",
            "Umbral Carapace",
            "Malarian Mantle",
            "Gorgon Mantle",
            "Recondite Mantle",
            "Bonebrood Mantle",
            "Doomscale Mantle",
            "Krellnakor Mantle",
            "Restless Mantle",
            "Fyrthek Mantle",
            "Geomimus Mantle",
        },

        -- You will see author various author notes using comments, feel free to follow suit.
        ['Carapace'] = {
            -- Added to mantle because we won't use carapace until it becomes Timer 11
            -- "Soul Carapace", -- Level 73, Timer 5
            -- "Umbral Carapace",
            -- "Malarian Carapace", -- much worse than Malarian Mantle and shares a timer
            "Gorgon Carapace", -- Level 88, Timer 11 from here on
            "Sholothian Carapace",
            "Grelleth's Carapace",
            "Vizat's Carapace",
            "Tylix's Carapace",
            "Cadcane's Carapace",
            "Xetheg's Carapace",
            "Kanghammer's Carapace",
        },
        ['EndRegen'] = {
            --Timer 13, can't be used in combat
            "Respite", --Level 86
            "Reprieve",
            "Rest",
            "Breather", --Level 101
        },
        ['MeleeMit'] = {
            -- "Withstand", -- Level 83, extreme endurance problems until 86 when we have Respite and Bard Regen Song gives endurance
            "Defy",
            "Renounce",
            "Reprove",
            "Repel",
            "Spurn",
            "Thwart",
            "Repudiate",
            "Gird",
        },
        ['HateBuff'] = {         --9 minute reuse makes these somewhat ridiculous to gem on the fly.
            "Voice of Thule",    -- level 60, 12% hate
            "Voice of Terris",   -- level 55, 10% hate
            "Voice of Death",    -- level 50, 6% hate
            "Voice of Shadows",  -- level 46, 4% hate
            "Voice of Darkness", -- level 39, 2% hate
        },
    },

    -- Helper Functions
    -- These are complex functions that are generally either used by more than one ability or as the condition of a rotation.
    -- Placing these here can save space and improve readability in rotations and entries
    -- These functions are generally not used by every class. Occasionally, if they are copied to enough configs, we will elect to move them into the utils instead.
    -- Usage will (hopefully) become apparent from reading and seeing how each is called.
    -- I generally try to leave basic notes as to what does what for the next guy.
    ['Helpers']       = {
        --determine whether we should overwrite DLU buffs with better single buffs
        SingleBuffCheck = function(self)
            if Casting.CanUseAA("Dark Lord's Unity (Azia)") and not Config:GetSetting('OverwriteDLUBuffs') then return false end
            return true
        end,
        --function to determine if we should AE taunt and optionally, if it is safe to do so
        AETauntCheck = function(printDebug)
            local mobs = mq.TLO.SpawnCount("NPC radius 50 zradius 50")()
            local xtCount = mq.TLO.Me.XTarget() or 0

            if (mobs or xtCount) < Config:GetSetting('AETauntCnt') then return false end

            local tauntme = Set.new({})
            for i = 1, xtCount do
                local xtarg = mq.TLO.Me.XTarget(i)
                if xtarg and xtarg.ID() > 0 and ((xtarg.Aggressive() or xtarg.TargetType():lower() == "auto hater")) and xtarg.PctAggro() < 100 and (xtarg.Distance() or 999) <= 50 then
                    if printDebug then
                        Logger.log_verbose("AETauntCheck(): XT(%d) Counting %s(%d) as a hater eligible to AE Taunt.", i, xtarg.CleanName() or "None",
                            xtarg.ID())
                    end
                    tauntme:add(xtarg.ID())
                end
                if not Config:GetSetting('SafeAETaunt') and #tauntme:toList() > 0 then return true end --no need to find more than one if we don't care about safe taunt
            end
            return #tauntme:toList() > 0 and not (Config:GetSetting('SafeAETaunt') and #tauntme:toList() < mobs)
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
        --further help functions omitted
    },

    -- Rotation Order
    -- This section controls both what rotations will load, and which will be processed, based on conditions.
    -- Order absolutely matters! We will process rotations in the order listed here, NOT the order that the entry tables are placed in (which is irrelevant).
    -- We will continually loop through all of these rotations, at almost all times!
    -- If the rotation condition is met, check entries in the rotations and use an action, if appropriate.
    -- We will iterate through the entire rotation until we find an entry whose condition passes. More explained below.
    -- We heavily use helper functions from our libraries ("utils") for these conditions to keep things easier to read and digest. They can be searched for in the respective util file.
    -- Please note that some abilities will cease functioning if the targets change, so the provided targetId is relevant.
    -- Even though it is not strictly required (by the particular spell), some abilities have the PC listed as a target for ease of conformity.
    -- Please refer to "Hate Tools" below for a rotation for a fully marked up example!
    -- Note: I have reordered and deleted rotations for illustration. The ones that remain are good examples or have comments!
    ['RotationOrder'] = {
        { --Actions that establish or maintain hatred

            -- Name:
            -- The name of the rotation, arbitary, displays in the UI
            name = 'HateTools',

            -- Timer:
            -- If we have processed this rotation in the last X seconds, we will skip it.
            -- SHD Hate Tools don't have a timer! Example only.
            -- This is commonly used on group buffs, as buff checking with an entire group is relatively "expensive" or perhaps just "extensive" in some cases.
            -- If we checked these all the time, we would be slower to react when a heal was needed, or when combat started, etc.
            -- Tangent for group buffs: The Group Buff timer (and some others) can instantly be reset with the /rgl rebuff command! I broadcast it before big pulls to make sure I'm prepared!
            timer = 60,

            -- State:
            -- Which entry number the rotation will start on after a reset:
            -- Every detected switch between combat and downtime will trigger a rotation state reset.
            -- Generally, we only need a few milliseconds once a target dies to change states, and this will be reset between mobs.
            -- Sometimes when targets are changed during combat, you may continue combat without hitting ever hitting downtime to reset the state.
            -- I can't think of any good reason we would want this to reset to anything else other than 1.
            state = 1,

            -- Steps:
            -- The number of actions that are processed based off of SUCCESSFULL checks before we move to the next rotation.
            -- If a check passes and we send the command to use the spell, it is considered successful, even if the spell than fails due to movement/etc.
            -- Using more than one step can be handy on burn rotations where you are quickly hitting a sequence of AA, and most of our configs could stand to see the burns increased to use between 2 and 4 steps (WIP).
            steps = 1,

            -- doFullRotation:
            -- This "flags" the rotation to ALWAYS check from the first entry, in essence, the state is eternally "1".
            -- This style of rotation ensures entries are processed on a strict priority basis, and is generally not required.
            -- The most obvious use is when you are layering critical abilities: You don't want to use simply use a lifetap when your health is at 10% and you should be using Leech Touch!
            -- As such, careful consideration to entry order is important to properly leverage the full rotation.
            -- Please note that this isn't necessary nearly as often as you think: since we check every entry in a rotation until we find one that meets its condition to use, we generally process entire rotations multiple times a second!
            doFullRotation = true,

            -- Load Conditions:
            -- Quite simply, this function governs whether the rotation is loaded at all.
            -- This check occcurs on startup, or whenever a loadout change is triggered (manually with the buttons in the class UI, or automatically by changing modes or many options)
            -- This prevents us from having to check rotations and entries that will never return true: For example:
            -- Note below, that this particular rotation will only load when IsTanking is true (which, if you follow the breadcrumbs, basically means if the Tank mode is active).
            -- That way, our DPS SHD isn't constantly checking to see if he should use taunts (because the answer is always no!)
            -- Nearly any imaginable condition can be used here, including TLOs. You will see mode-based, level-based, and setting-based load conditions in our confings, to name a few.
            load_cond = function() return Core.IsTanking() end,

            -- Target ID:
            -- Quite simply, the ID of the target the entries should be used on, or will be checked against (if they call for target checks, for things like debuff stacking, for example)
            -- The function below calls for our "CheckForAutoTargetID" helper function in the Targeting util to give us that ID, if there is one.
            -- We heavily leverage helpers to keep this section readable and make it easy to edit/adapt/create rotations.
            -- I encourage you to note the targetIds listed in other functions here!
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,


            -- Condition:
            -- These are the conditions that must be met before we will check entries in this rotation.
            -- Please note that there are many other ways to correctly write these! Lua is Lua. However, you will commonly see the below styling and copying it should be simple enough!
            -- While not required, we sometimes use "early out" conditional checks so that we don't make complex checks if a simple setting is disabled, etc.
            -- In this instance, you will see that we won't even bother checking anything else if our HP is in the critical HP range, as we need to skip this rotation to get to our emergency stuff to fix that!
            cond = function(self, combat_state)
                -- The early out conditional statement discussed above.
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end

                -- The return conditions... basically, this rotation will "return" true and process if all of these conditions are met
                return combat_state == "Combat" and (mq.TLO.Me.PctAggro() < 100 or (mq.TLO.Target.SecondaryPctAggro() or 0) > 60 or Globals.AutoTargetIsNamed)
                -- This is a complex check, which returns true under varying conditions (as the entries themselves are each used in specific scenarios).
                -- I must editorialize and disclaim that most conditions aren't this convoluted. Please refer to the above and below rotations!
                -- The following must be true for this rotation to process
                -- ... We must be in the Mercs "Combat" state (note that this isn't necessarily the same as any combat TLO)
                -- Additionally, ONE of the following must be true:
                -- ... We have lost aggro on the target (aggro percent is under 100) OR
                -- ... Someone else has a high aggro on the taret (Secondary Aggro is greater than 60) OR
                -- ... The target is a named, as detected by spawnmaster, or our built-in named list (see named tab of the UI for further info)
            end,
        },
        { -- SHD doesn't have group buffs! Listed as a reference as to where we get our table of buffable group IDs from!
            name = 'GroupBuff',
            state = 1,
            steps = 1,
            targetId = function(self) return Casting.GetBuffableIDs() end,
            cond = function(self, combat_state)
                -- much simpler conditions here! "OkayToBuff" has things like... am I moving, is nav active, etc. Search for this function in the Casting util file!
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },

        -- Note the use of a helper function here! You can look at the function above.
        { -- Leech Effect (Epic, OoW BP, Coating) maintenance
            name = 'LeechEffects',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                if mq.TLO.Me.PctHPs() <= Config:GetSetting('HPCritical') then return false end
                return combat_state == "Combat" and self.Helpers.LeechCheck(self)
            end,
        },
        -- The below are just examples of standard rotations you see in most configs.
        -- Please note the lack of state and steps! This means we will process the ENTIRE rotation...
        -- executing each entry whose conditions are met as we go.
        { --Self Buffs
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                -- AmIBuffable will check things like "Is there a corpse of mine within range? etc. (in this case we have an option to buff anyway!)"
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 10,
            --The targetId here is simply a condition statement, if we have a pet, we return the ID in a table; if not, we return an empty table.
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
            end,
        },

    },

    -- Rotation Entry Table:
    -- Now we list each specific ability in the rotation.
    -- While it would be nice if the order matched the rotation order, in most configs it does not, and it is not required.
    -- As a recap from the rotation explanation above:
    -- ... We will start the entry # that correlates to our "state" (Which starts at 1, and is advanced one by each successful check/attempted entry)
    -- ... We will perform a number of actions equial to our "step"
    -- ... If the entry conditions are not met, we will move on until we find an entry whose conditions are.
    -- ... In the absence of a condition being met, we will continue checking until we have checked every entry in the rotatation, and only then move on to the next.
    -- I have deleted or reordered rotations for illustrations sake, I'll break down a few examples below:
    ['Rotations']     = {
        ['Downtime'] = {
            {
                -- Name: The name of the entry.
                -- For a spell/disc/song, this must correlate to an ability set above!
                -- Items can either use ability sets or be named directly without using an ability set.
                -- AA will be named directly without using an ability set.
                name = "EndRegen",

                -- Type:
                -- Options: Spell, Disc, Item, AA, custom_func
                -- Custom functions will be demonstrated below and are generally means of using direct commands, etc.
                type = "Disc",

                -- Condition:
                -- These function largely the same as rotation conditions.
                -- Please note the order in which the variables below are passed, as this is critical to using them.
                -- You cannot change them, for example, if you wanted to use the discSpell variable and tried to pass (self, target, discSpell), it wouldn't work.
                -- Passed variables are a bit more in-depth, but you can largely get away with copying existing entries and editing as needed!
                cond = function(self, discSpell, target)
                    -- Again, you'll see an early out. This one basically says that if we have a valid "CombatEndRegen" disc, don't try to use this one.
                    if self:GetResolvedActionMapItem("CombatEndRegen") then return false end
                    -- A simple return condition, this will only return true when our endurance is critically low.
                    return mq.TLO.Me.PctEndurance() < 15
                end,
            },
            {
                name = "Dark Lord's Unity (Azia)",
                type = "AA",

                -- Note the use of the Tooltip in this entry, again, this will be displayed when you mouseover in the rotation window (UI)
                tooltip = Tooltips.DLUA,

                -- Active Conditions:
                -- Take a look at the rotation UI. See the little smiley face in the "active" column?
                -- If the function below returns true, we will get the smiley face. We know the buff is up!
                -- I tend to only use these in "Downtime" rotations. I don't want to be spending extra processing power during combat checking this stuff, and most combat entries don't need them.
                -- These have nothing to do with how or whether an action is used! Author comment, they totally confused me when I started and I very much thought they did.
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.Me.AltAbility(aaName).Spell.Trigger(2).ID() or 0) end,

                -- Here we will early out if our Proc Choice setting isn't "1" (which if you look in the settings is to use the HP proc)
                -- If it is, we will make presence and stacking checks for this AA's spell. If they return true, we will use it.
                cond = function(self, aaName, target)
                    if Config:GetSetting('ProcChoice') ~= 1 then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },

            -- The below notes are in the config, not part of this example, but I'll keep them, as it is a useful technique to maintain buff uptime.
            -- Please note that "Stacks" TLOs actually have some duration basis to them, but checking total seconds may give you more granularity.

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
                name = "TempHP",
                type = "Spell",
                tooltip = Tooltips.TempHP,
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    -- Cast Ready is important: It means... don't try to cast this if I don't have this memorize and its reuse is up.
                    -- This is very important for long reuse time spells. We don't want to mem this and then wait 30 seconds to cast it!
                    if not Config:GetSetting('DoTempHP') or not Casting.CastReady(spell) then return false end
                    return spell.RankName.Stacks() and (mq.TLO.Me.Buff(spell).Duration.TotalSeconds() or 0) < 45
                end,
            },


            -- Name functions:
            -- We can have a function return the name of an entry instead of typing it ourselves.
            -- In this example, it will either return the name of our Charm, or, if we don't have one, the entry name will be "CharmClick(Missing)"
            -- I will demonstrate one other use of a name function below.

            { --Charm Click, name function stops errors in rotation window when slot is empty
                name_func = function() return mq.TLO.Me.Inventory("Charm").Name() or "CharmClick(Missing)" end,
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCharmClick') or not Casting.ItemHasClicky(itemName) then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },

            -- Example of an Item that is named directly, this is not part of an ItemSet
            {
                name = "Huntsman's Ethereal Quiver",
                type = "Item",
                active_cond = function(self) return mq.TLO.FindItemCount("Ethereal Arrow")() > 100 end,
                cond = function(self)
                    if not Config:GetSetting('SummonArrows') then return false end
                    return mq.TLO.FindItemCount("Ethereal Arrow")() < 101
                end,
            },

            --- I have removed a lot of rotations here

            -- Good example... No conditions, you ask? They aren't needed!
            -- Any ability without a condition will be used whenever it is checked (if it is ready)!
            {
                name = "Visage of Death",
                type = "AA",
            },
            {
                name = "Crimson",
                type = "Disc",
                tooltip = Tooltips.Crimson,
            },

            -- Advanced name function usage:
            -- Stole this from the Laz Druid Config. I have a table of spires, and we pick the nth entry from it based on the setting).
            -- This basically means that we can account for the option of using all three spires (on laz they are stil separate), but only use one entry.
            -- Remember, every entry we have to check that will never return true is just dead weight.
            -- This isn't to say that settings based entries are bad, the individual peformance hit is quite negligible.
            -- However, eventually you reach a point of too many, which could hypothetically lead to your PC reacting just a hair slower...
            -- ... and sometimes can be the difference between taunting/healing/etc in time to avoid a loss.

            { -- Spire, the SpireChoice setting will determine which ability is displayed/used.
                name_func = function(self)
                    local spireAbil = string.format("Fundament: %s Spire of Nature", Globals.Constants.SpireChoices[Config:GetSetting('SpireChoice') or 4])
                    return Casting.CanUseAA(spireAbil) and spireAbil or "Spire Not Purchased/Selected"
                end,
                type = "AA",
            },
        },
    },

    -- Spells Table: Gem-based spell selection
    -- This is the old style table you will see in most configs.
    -- We will process each gem to determine which spell should go there.
    -- By now, you should be familiar with our condition checks: the first condition that is met (or the first one without a condition) will be selected!
    -- Note that many of the default config spell lists have grown to be convoluted in the face of so many options and possiblities.
    -- Below this table is the "new" style Spell List table, which is strictly prioritized.
    -- Never look at bard if you value your sanity. Eventually we will convert that to the new style and be done with the custom code. It was the pioneer!
    ['Spells']        = {
        {
            gem = 1,
            spells = {
                { name = "SpearNuke", },
            },
        },
        {
            gem = 2,
            spells = {
                { name = "LifeTap", },
            },
        },
        -- Here is where the complexity I was talking about comes in. If you are writing your own config, I suggest you check out the new list below!
        -- However, simple static entries like the abovee are perfectly reasonable if you don't need the flexibility!
        -- This system can place a certain spell in a certain gem every time, where the priority system might not!
        {
            gem = 3,
            spells = {
                { name = "SnareDot", cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA("Encroaching Darkness") end, },
                { name = "DireTap",  cond = function(self) return Config:GetSetting('DoDireTap') end, },
                { name = "Dicho",    cond = function(self) return Config:GetSetting('DoDicho') end, },
                { name = "ForPower", cond = function(self) return Config:GetSetting('DoForPower') end, },
                {
                    name = "Terror",
                    cond = function(self)
                        local setting = Config:GetSetting('DoTerror')
                        return setting == 3 or (setting == 2 and mq.TLO.Me.Level() < 72)
                    end,
                },
                {
                    name = "AETaunt",
                    cond = function(self)
                        local setting = Config:GetSetting('AETauntSpell')
                        return setting == 3 or (setting == 2 and not Casting.CanUseAA("Explosion of Hatred"))
                    end,
                },
                { name = "BiteTap", },
            },
        },

        -- Note the condition function... in this case, we won't fill the eighth gem until we have nine gems!
        -- Previously, this was important because we would commonly overwrite those spells with buffs.
        -- Since then, handling of using the last gem slot has improved...
        -- ...we now have the option to leave it as is, rememorize the spell in the slot before we used it, or to reload the gem from the loadout.
        {
            gem = 8,
            cond = function(self) return mq.TLO.Me.NumGems() >= 9 end,
            spells = {
                -- spells omitted for brevity
            },
        },

        -- In this example, we will only check this to fill if we have 11 gems in the first place.
        { -- Level 80
            gem = 11,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                -- spells omitted for brevity
            },
        },
    },

    -- Spell List : Priority-based spell selection
    -- To change the order they are loaded, simply change the order they are listed!
    -- Note that conditions are supported, so multiple lists can be present, refer to Laz SHM for an example.
    -- (The following is pulled from the Laz SHD config.)

    -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
    -- The list name ("Default" in the list below) is abitrary, it is simply what shows up in the UI when this spell list is loaded.
    -- Virtually any helper function or TLO can be used as a condition. Example: Mode or level-based lists.
    -- The first list without conditions or whose conditions returns true will be loaded, all subsequent lists will be ignored.
    -- Spells will be loaded in order (if the conditions are met), until all gem slots are full.
    -- Loadout checks (such as scribing a spell or using the "Rescan Loadout" or "Reload Spells" buttons) will re-check these lists and may load a different set if things have changed.
    ['SpellList']     = {
        {
            name = "Default",
            -- cond = function(self) return true end, --Kept here for illustration, this line could be removed in this instance since we aren't using conditions.
            spells = {
                { -- We can use name functions to choose between two spells based on whether the listed conditions are true or false (so that we don't memorize both).
                    name_func = function(self)
                        return (Config:GetSetting('DoAESpearNuke') and Core.GetResolvedActionMapItem('AESpearNuke')) and "AESpearNuke" or "SpearNuke"
                    end, -- This will set the spell name to "AESpearNuke" if the setting is enabled and we have a valid spell in our book.
                },
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
                { name = "AELifeTap",   cond = function(self) return Config:GetSetting('DoAELifeTap') end, },
                { name = "Skin", },
                { name = "HateBuff",    cond = function(self) return Config:GetSetting('DoHateBuff') end, },
                { name = "LifeTap2", },
                { name = "Terror2",     cond = function(self) return Config:GetSetting('DoTerror') end, },
            },
        },
    },


    -- Pull Abilities
    -- Used to populate the drop-down list in the pull module
    -- Most of this is self-explanatory.
    -- If you desire a new ability, I highly recommend that you copy an existing entry and then edit as you see fit.
    ['PullAbilities'] = {
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
    },

    -- Config Settings
    -- These are class-specific settings, many of the settings referenced in a class config may come from the config utility, or directly from a module instead.
    -- I will briefly break one of them down, but you can largely use those already provided as an example.
    ['DefaultConfig'] = {

        -- Example of a boolean (true/false) style setting.
        ['DoSnare']           = {
            DisplayName = "Use Snares",                                   -- Note the difference between setting and display names. Keeping them the same would have upsides, and downsides.
            Category = "Buffs/Debuffs",                                   -- The display category this falls under
            Index = 1,                                                    -- Settings indexes are used to place the settings in a desired order within the category.
            -- Note: If there is no index, they will be listed alphabetically.
            Tooltip = "Use Snare(Snare Dot used until AA is available).", -- The tooltip displayed when you mouse over the setting.
            Default = false,
            RequiresLoadoutChange = true,                                 -- This will trigger a loadout change, which recalculates the rotations and spells we will use.
            FAQ = "Why is my Shadow Knight not snaring?",                 -- Searchable FAQ entry. These are WIP. Some are hardly more than placeholders.
            Answer = "Make sure Use Snares is enabled in your class settings.",
        },

        -- Example of a number style setting.
        ['SnareCount']        = {
            DisplayName = "Snare Max Mob Count",
            Category = "Buffs/Debuffs",
            Index = 2,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro. Helpful for AoE groups.",
            Default = 3,
            Min = 1,
            Max = 99,
            FAQ = "Why is my Shadow Knight Not snaring?",
            Answer = "Make sure you have [DoSnare] enabled in your class settings.\n" ..
                "Double check the Snare Max Mob Count setting, it will prevent snare from being used if there are more than [x] mobs on aggro.",
        },

        -- Example of a setting that displays spell information from the game on mouseover.
        ['DoTempHP']          = {
            DisplayName = "Use HP Buff",
            Category = "Buffs/Debuffs",
            Index = 3,
            Tooltip = function() return Ui.GetDynamicTooltipForSpell("TempHP") end,
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "Why do we have the Temp HP Buff always memorized?",
            Answer = "Temp HP buffs have a very long refresh time after scribing, making them infeasible to use if not gemmed.",
        },

        -- Example of a setting that uses a combo box.
        ['ProcChoice']        = {
            DisplayName = "HP/Mana Proc:",
            Category = "Buffs/Debuffs",
            Index = 4,
            Tooltip = "Prefer HP Proc and DLU(Azia) or Mana Proc and DLU(Beza)",
            Type = "Combo",
            ComboOptions = { 'HP Proc: Terror Line, DLU(Azia)', 'Mana Proc: Mental Line, DLU(Beza)', 'Disabled', },
            Default = 1,
            Min = 1,
            Max = 3,
            FAQ = "I am constantly running out of mana, what can I do to help?",
            Answer = "During certain level ranges, it may be helpful to use the Mana Proc (Mental) line over the HP proc (Terror) line.\n" ..
                "This can be adjusted on the Buffs/Debuffs tab.",
        },

        -- Example of an advanced setting, which only displays when the advanced settings option is toggled.
        ['OverwriteDLUBuffs'] = {
            DisplayName = "Overwrite DLU Buffs",
            Category = "Buffs/Debuffs",
            Index = 5,
            Tooltip = "Overwrite DLU with single buffs when they are better than the DLU effect.",
            Default = false,
            ConfigType = "Advanced",
            FAQ = "I have new buffs but I am still using DLU, why?",
            Answer = "Toggle to Overwrite DLU with single buffs when appropriate from the Buffs/Debuffs tab. This is disabled by default to speed up buffing.",
        },

        -- Example of a setting that uses a dynamic default. These are still boolean (true/false) checks.
        -- If we are on emu, the default will initialize as false.
        -- You could also check a table to see if an entry exists (for example, check to see if your class is on the "melee" table we have in the Config util), etc.
        -- Please note that funtions are not supported.
        ['DoChestClick']      = {
            DisplayName = "Do Chest Click",
            Category = "Equipment",
            Index = 1,
            Tooltip = "Click your equipped chest.",
            Default = mq.TLO.MacroQuest.BuildName() ~= "Emu",
            FAQ = "What the heck is a chest click?",
            Answer = "Most classes have useful abilities on their equipped chest after level 75 or so. The SHD's is generally a healing tool (a lifetapping pet).",
        },
    },
}

return _ClassConfig
