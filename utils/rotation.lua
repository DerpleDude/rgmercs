local mq         = require('mq')
local Set        = require("mq.Set")
local Casting    = require("utils.casting")
local Combat     = require("utils.combat")
local Config     = require("utils.config")
local Core       = require("utils.core")
local Globals    = require("utils.globals")
local Logger     = require("utils.logger")
local Modules    = require("utils.modules")
local Strings    = require("utils.strings")

local Rotation   = { _version = '1.0', _name = "Rotation", _author = 'Derple', }
Rotation.__index = Rotation

--- Returns the first item name from t whose item is in the player's inventory,
--- or nil if none are found.
---@param t table Array of item name strings to search.
---@return string|nil The first found item name, or nil if none available.
function Rotation.GetBestItem(t)
    local selectedItem = nil

    for _, i in ipairs(t or {}) do
        if mq.TLO.FindItem("=" .. i)() then
            selectedItem = i
            break
        end
    end

    if selectedItem then
        Logger.log_debug("\agFound\ax %s!", selectedItem)
    else
        Logger.log_debug("\arNo items found for slot!")
    end

    return selectedItem
end

--- Returns the first AA name in aaList that the character has purchased,
--- or nil if none are available.
---@param aaList table Array of AA name strings to evaluate.
---@return string|nil The first purchasable AA, or nil if none found.
function Rotation.GetBestAA(aaList)
    local selectedAA = nil

    for _, abil in ipairs(aaList or {}) do
        if Casting.CanUseAA(abil) then
            selectedAA = abil
            break
        end
    end

    if selectedAA then
        Logger.log_debug("\agFound\ax %s!", selectedAA)
    else
        Logger.log_debug("\arNo AA found for slot!")
    end

    return selectedAA
end

--- Returns the highest-level known spell from spellList that is in the
--- spellbook or combat ability list and has not already been resolved.
---@param spellList table Array of spell name strings to evaluate.
---@param alreadyResolvedMap table Map of already-resolved spells to skip.
---@return MQSpell|nil The best usable spell, or nil if none qualify.
function Rotation.GetBestSpell(spellList, alreadyResolvedMap)
    local highestLevel = 0
    local selectedSpell = nil

    for _, spellName in ipairs(spellList or {}) do
        local spell = mq.TLO.Spell(spellName)
        if spell() ~= nil then
            --Logger.log_debug("Found %s level(%d) rank(%s)", s, spell.Level(), spell.RankName())
            if spell.Level() <= mq.TLO.Me.Level() then
                if mq.TLO.Me.Book(spell.RankName.Name())() or mq.TLO.Me.CombatAbility(spell.RankName.Name())() then
                    if spell.Level() > highestLevel then
                        -- make sure we havent already found this one.
                        local alreadyUsed = false
                        for _, resolvedSpell in pairs(alreadyResolvedMap) do
                            if type(resolvedSpell) ~= "string" and resolvedSpell.ID() == spell.ID() then
                                alreadyUsed = true
                            end
                        end

                        if not alreadyUsed then
                            highestLevel = spell.Level()
                            selectedSpell = spell
                        end
                    end
                    -- else         --temporarily removed, extreme spam, can possibly readd with Highest Only support so did not refactor
                    --     Comms.PrintGroupMessage(string.format(
                    --         "%s \aw [%s] \ax \ar ! MISSING SPELL ! \ax -- \ag %s \ax -- \aw LVL: %d \ax",
                    --         mq.TLO.Me.CleanName(), spellName,
                    --         spell.RankName.Name(), spell.Level()))
                end
            end
        end -- end if spell nil check
    end

    if selectedSpell then
        Logger.log_debug("\agFound\ax %s level(%d) rank(%s)", selectedSpell.BaseName(), selectedSpell.Level(),
            selectedSpell.RankName())
    else
        Logger.log_debug("\arNo spell found for slot!")
    end

    return selectedSpell
end

--- Executes a single rotation entry (spell/song/disc/AA/item/etc.) on targetId,
--- skipping mezzed targets when AllowMezBreak is off.
---@param caller any The class module calling the rotation (for PreActivate).
---@param entry table Rotation entry with type, name, and optional flags.
---@param targetId number Spawn ID to cast/use on.
---@param resolvedActionMap table Map of entry name → resolved spell/item/AA.
---@param bAllowMem boolean If true, gem-memming is allowed to ready the spell.
---@return boolean True if the entry was used successfully.
---@return boolean|nil True if the action targeted a group-type target.
function Rotation.ExecEntry(caller, entry, targetId, resolvedActionMap, bAllowMem)
    local ret = false
    local isGroup = nil

    if entry.type == nil then return false end -- bad data.

    local target = mq.TLO.Target

    if target and target() and target.ID() == targetId then
        if target.Mezzed() and target.Mezzed.ID() and not Config:GetSetting('AllowMezBreak') then
            Logger.log_debug("Target is mezzed and not AllowMezBreak --> Not Casting!")
            return false
        end
    end

    if entry.type:lower() == "item" then
        --Allow us to pass entry names directly for items in addition to Action Map tables
        local itemName = resolvedActionMap[entry.name]
        if not itemName then itemName = entry.name end

        if Casting.ItemReady(itemName) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret, isGroup = Casting.UseItem(itemName, entry.no_target == true and nil or targetId, nil, nil, not entry.mustWait)
        end
        Logger.log_verbose("Trying to use item %s :: %s", itemName, ret and "\agSuccess" or "\arFailed!")
    end

    -- different from items in that they are configured by the user instead of the class.
    if entry.type:lower() == "clickyitem" then
        local itemName = Config:GetSetting(entry.name)

        if not itemName or itemName:len() == 0 then return false end

        if Casting.ItemReady(itemName) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret, isGroup = Casting.UseItem(itemName, entry.no_target == true and nil or targetId, nil, nil, not entry.mustWait)
        end
        Logger.log_verbose("Trying to use clickyitem %s :: %s", itemName, ret and "\agSuccess" or "\arFailed!")
    end

    if entry.type:lower() == "spell" then
        local spell = resolvedActionMap[entry.name]

        if not spell or not spell() then return false end

        if Casting.SpellReady(spell, bAllowMem) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret, isGroup = Casting.UseSpell(spell.RankName(), targetId, bAllowMem, entry.allowDead, entry.retries)
        end
        Logger.log_verbose("(Spell) Trying to use %s - %s :: %s", entry.name, spell.RankName(), ret and "\agSuccess" or "\arFailed!")
    end

    if entry.type:lower() == "song" then
        local songSpell = resolvedActionMap[entry.name]

        if not songSpell or not songSpell() then return false end

        if Casting.SongReady(songSpell, bAllowMem) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret = Casting.UseSong(songSpell.RankName(), targetId, bAllowMem, entry.retries)
        end
        Logger.log_verbose("(Song) Trying to use %s - %s :: %s", entry.name, songSpell.RankName(), ret and "\agSuccess" or "\arFailed!")
    end

    if entry.type:lower() == "disc" then
        local discSpell = resolvedActionMap[entry.name]

        if not discSpell then return false end

        if Casting.DiscReady(discSpell) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret, isGroup = Casting.UseDisc(discSpell, targetId, not entry.mustWait)
        end
        Logger.log_verbose("(Disc) Trying to use %s - %s :: %s", entry.name, discSpell.RankName(), ret and "\agSuccess" or "\arFailed!")
    end

    if entry.type:lower() == "aa" then
        --Allow us to pass entry names directly for AA in addition to Action Map tables
        local aaName = resolvedActionMap[entry.name]
        if not aaName then aaName = entry.name end

        if Casting.AAReady(aaName) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret, isGroup = Casting.UseAA(aaName, targetId, entry.allowDead, entry.retries, not entry.mustWait)
        end
        Logger.log_verbose("(AA) Trying to use %s :: %s", aaName, ret and "\agSuccess" or "\arFailed!")
    end

    if entry.type:lower() == "ability" then
        if Casting.AbilityReady(entry.name, mq.TLO.Spawn(targetId)) then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret = Casting.UseAbility(entry.name, targetId)
        end
        Logger.log_verbose("(Ability) Trying to use %s :: %s", entry.name, ret and "\agSuccess" or "\arFailed!")
    end

    if entry.type:lower() == "customfunc" then
        if entry.custom_func then
            Rotation.RunPreActivate(caller, resolvedActionMap, entry)
            ret = Core.SafeCallFunc(string.format("Custom Func Entry: %s", entry.name), entry.custom_func, caller, targetId)
        end
        Logger.log_verbose("(Custom Function) Calling %s", entry.name, ret and "\agSuccess" or "\arFailed!")
    end

    if entry.post_activate then
        Logger.log_verbose("Running post-activate for %s.", entry.name)
        entry.post_activate(caller, Rotation.GetEntryConditionArg(resolvedActionMap, entry), ret)
    end

    return ret, isGroup
end

--- Resolves the condition argument for entry from resolvedActionMap —
--- returns a spell for spell/song/disc types, an item/AA name otherwise.
---@param map table ResolvedActionMap built by ResolveActions.
---@param entry table Rotation entry from the class config.
---@return any The resolved spell, item name, or AA name for condition checks.
function Rotation.GetEntryConditionArg(map, entry)
    local condArg
    local entryType = entry.type:lower()
    local spellTypes = Set.new({ "spell", "song", "disc", })

    if spellTypes:contains(entryType) then -- spell, song, disc need a spell type returned so we can check ranks later
        condArg = map[entry.name] or mq.TLO.Spell(entry.name)
    elseif entryType == "item" then        -- item mapping is optional, entry.name can be an actual item name
        condArg = map[entry.name] or entry.name
    elseif entryType == "aa" then          -- AA mapping is optional, entry.name can be an actual AA name
        condArg = map[entry.name] or entry.name
    else                                   -- abils needs to return a name directly
        condArg = entry.name
    end

    return condArg
end

--- Evaluates entry.cond and entry.active_cond for the given target,
--- returning separate pass and active booleans.
---@param caller any Class module instance (passed to condition functions).
---@param resolvedActionMap table Map of entry name → resolved action.
---@param entry table Rotation entry to evaluate.
---@param targetId number Spawn ID used to build the target arg for conditions.
---@return boolean pass True if entry.cond passed (or no condition).
---@return boolean active True if entry.active_cond passed.
function Rotation.TestConditionForEntry(caller, resolvedActionMap, entry, targetId)
    if not entry.IgnoreImmuneCheck and entry.cachedResistType and Casting.ShouldSkipElement(entry.cachedResistType, targetId) then
        local element = entry.cachedResistType
        local skipGlobal = Config:GetSetting("Skip" .. element .. "Spells") and true or false
        local skipPerMob = Globals.AutoTargetElementalImmunities[element] == true
        Logger.log_verbose("\ay   :: Elemental immunity gate skipped \at%s\ay (element=%s, global=%s, perMob=%s)",
            entry.name, element, Strings.BoolToColorString(skipGlobal), Strings.BoolToColorString(skipPerMob))
        return false, false
    end

    local condArg = Rotation.GetEntryConditionArg(resolvedActionMap, entry)
    local condTarg = mq.TLO.Spawn(targetId)
    local pass = false
    local active = false

    if condArg ~= nil then
        local logInfo = string.format(
            "check failed - Entry(\at%s\ay), condArg(\at%s\ay), condTarg(\at%s\ay)", entry.name or "NoName",
            (type(condArg) == 'userdata' and condArg() or condArg) or "None", condTarg.CleanName() or "None")
        pass = not entry.cond or Core.SafeCallFunc("Condition " .. logInfo, entry.cond, caller, condArg, condTarg)

        --temp suppress of error messaging while we evaluate.
        -- if type(pass) ~= "boolean" then
        --     Logger.log_error("Entry(%s): %s is not a boolean value!", entry.name, pass)
        -- end

        if entry.active_cond then
            active = Core.SafeCallFunc("Active " .. logInfo, entry.active_cond, caller, condArg)
        end
    end

    Logger.log_verbose("\ay   :: Testing Condition for entry(%s) type(%s) cond(%s, %s) ==> \ao%s",
        entry.name, entry.type, condArg or "None", condTarg.CleanName() or "None", Strings.BoolToColorString(pass))

    return pass, active
end

--- Iterates rotationTable from start_step, testing conditions and executing
--- entries against targetTable until steps successful casts or end of table.
---@param caller any Class module instance passed to condition/exec functions.
---@param rotationTable table Array of rotation entries from the class config.
---@param targetTable table Array of spawn IDs to target for each entry.
---@param resolvedActionMap table Map of entry name → resolved spell/item/AA.
---@param steps number Max successful casts per call; 0 = unlimited.
---@param start_step number Rotation index to begin from this call.
---@param bAllowMem boolean If true, allows spell gem memorization.
---@param bDoFullRotation boolean? If true, always restart from step 1.
---@param fnRotationCond function? Re-checked each step; rotation stops on false.
---@param enabledRotationEntries table Map of entry name → bool (false = skip).
---@return number nextStep The index to resume from on the next call.
---@return boolean anySuccess True if at least one entry executed successfully.
function Rotation.Run(caller, rotationTable, targetTable, resolvedActionMap, steps, start_step, bAllowMem, bDoFullRotation, fnRotationCond, enabledRotationEntries)
    local stepsThisTime = 0
    local lastStepIdx   = 0
    local anySuccess    = false

    -- This is useful when class config wants to re-check every rotation condition every run
    -- For example, if gem1 meets all condition criteria, it WILL cast repeatedly on every cast
    -- Used for bards to dynamically weave properly
    if bDoFullRotation then start_step = 1 end
    for idx, entry in ipairs(rotationTable) do
        if enabledRotationEntries[entry.name] ~= false then
            if idx >= start_step then
                local tStart = string.format("%.03f", Globals.GetTimeMS())
                caller:SetCurrentRotationState(idx)

                if Globals.PauseMain or Globals.StopCast then
                    break
                end

                if fnRotationCond then
                    local start = string.format("%.03f", Globals.GetTimeMS())

                    if not Core.SafeCallFunc("\tRotation Condition Loop Re-Check", fnRotationCond, caller, Combat.GetCachedCombatState()) then
                        Logger.log_verbose("\arStopping Rotation Due to condition check failure!")
                        break
                    end
                    local stop = string.format("%.03f", Globals.GetTimeMS())
                    entry.lastRotationCondTimeSpent = stop - start
                end

                if Config:GetSetting('ChaseOn') then
                    local start = string.format("%.03f", Globals.GetTimeMS())
                    if Config.ShouldPriorityFollow() then
                        break
                    end
                    local stop = string.format("%.03f", Globals.GetTimeMS())
                    entry.lastFollowTimeSpent = stop - start
                else
                    entry.lastFollowTimeSpent = 0
                end

                Logger.log_verbose("\aoDoing RunRotation(start(%d), step(%d), cur(%d))", start_step, steps, idx)
                lastStepIdx = idx

                local entryPass = false
                local entryActive = false
                local entryHadSuccess = false
                entry.lastCondTimeSpent = 0
                entry.lastExecTimeSpent = 0

                for _, targetId in ipairs(targetTable) do
                    if targetId and targetId > 0 then
                        local condStart = string.format("%.03f", Globals.GetTimeMS())
                        local pass, active = Rotation.TestConditionForEntry(caller, resolvedActionMap, entry, targetId)
                        local condStop = string.format("%.03f", Globals.GetTimeMS())
                        entry.lastCondTimeSpent = entry.lastCondTimeSpent + (condStop - condStart)

                        if pass then entryPass = true end
                        if active then entryActive = true end

                        Logger.log_verbose("\aoDoing RunRotation(start(%d), step(%d), cur(%d)) :: TestConditionsForEntry(target(%d)) => %s",
                            start_step, steps, idx, targetId, Strings.BoolToColorString(pass and true or false))

                        if pass then
                            local rStart = string.format("%.03f", Globals.GetTimeMS())
                            local res, isGroup = Rotation.ExecEntry(caller, entry, targetId, resolvedActionMap, bAllowMem)
                            local rStop = string.format("%.03f", Globals.GetTimeMS())
                            entry.lastExecTimeSpent = entry.lastExecTimeSpent + (rStop - rStart)
                            if entry.from_clicky then
                                Modules:ExecModule("Clickies", "SetUsed", entry.name)
                            end

                            Logger.log_verbose("\aoDoing RunRotation(start(%d), step(%d), cur(%d)) :: ExecEntry(target(%d)) => %s",
                                start_step, steps, idx, targetId, Strings.BoolToColorString(res))

                            if res == true then -- Algarnote... revisit: Either make sure customfuncs all return bools, or consider relaxing this so a customfunc will count as success if ~= false
                                entryHadSuccess = true
                                if isGroup then break end
                            end
                        end

                        if Globals.PauseMain then
                            break
                        end
                    end
                end

                entry.lastRun = { pass = entryPass, active = entryActive, }

                if entryHadSuccess then
                    anySuccess = true
                    stepsThisTime = stepsThisTime + 1

                    if steps > 0 and stepsThisTime >= steps then
                        break
                    end

                    if Globals.PauseMain then
                        break
                    end
                else
                    Logger.log_verbose("\aoFailed Condition RunRotation(start(%d), step(%d), cur(%d))", start_step, steps, idx)
                end

                local tStop = string.format("%.03f", Globals.GetTimeMS())
                entry.lastTotalTimeSpent = tStop - tStart
            end
        end
    end

    lastStepIdx = lastStepIdx + 1

    if lastStepIdx > #rotationTable then
        lastStepIdx = 1
    end

    Logger.log_verbose("Ended RunRotation(step(%d), start_step(%d), next(%d))", steps, (start_step or -1),
        lastStepIdx)

    return lastStepIdx, anySuccess
end

--- Reorders entryList in place to match a saved order of entry names, keying by name+occurrence so duplicate names stay distinct.
---@param entryList table Array of rotation entry descriptors, reordered in place.
---@param savedOrder table? Array of entry names defining the desired order; entries absent from it keep their built order at the end. Nil/empty is a no-op.
function Rotation.ApplyEntryOrder(entryList, savedOrder)
    if not savedOrder or #savedOrder == 0 then return end
    local pos = {}
    local savedSeen = {}
    for i, entryName in ipairs(savedOrder) do
        savedSeen[entryName] = (savedSeen[entryName] or 0) + 1
        pos[entryName .. "\0" .. savedSeen[entryName]] = i
    end
    local base = #savedOrder
    local liveSeen = {}
    local keyed = {}
    for i, entry in ipairs(entryList) do
        liveSeen[entry.name] = (liveSeen[entry.name] or 0) + 1
        keyed[i] = { entry = entry, key = pos[entry.name .. "\0" .. liveSeen[entry.name]] or (base + i), }
    end
    table.sort(keyed, function(a, b) return a.key < b.key end)
    for i, k in ipairs(keyed) do entryList[i] = k.entry end
end

--- Builds and returns a resolvedActionMap by calling GetBestItem, GetBestSpell,
--- and GetBestAA for each entry in itemSets, abilitySets, and aaSets.
---@param itemSets table Map of set name → array of item names.
---@param abilitySets table Map of set name → array of spell names.
---@param aaSets table|nil Map of set name → array of AA names.
---@return table Map of set name → resolved spell/item/AA.
function Rotation.ResolveActions(itemSets, abilitySets, aaSets)
    local resolvedActionMap = {}

    -- Map AbilitySet Items and Load Them
    for unresolvedName, itemTable in pairs(itemSets) do
        Logger.log_debug("Finding best item for Set: %s", unresolvedName)
        resolvedActionMap[unresolvedName] = Rotation.GetBestItem(itemTable)
    end

    local sortedAbilitySets = {}
    for unresolvedName, _ in pairs(abilitySets) do
        table.insert(sortedAbilitySets, unresolvedName)
    end
    table.sort(sortedAbilitySets)

    for _, unresolvedName in pairs(sortedAbilitySets) do
        local spellTable = abilitySets[unresolvedName]
        Logger.log_debug("\ayFinding best spell for Set: \am%s", unresolvedName)
        resolvedActionMap[unresolvedName] = Rotation.GetBestSpell(spellTable, resolvedActionMap)
    end

    for unresolvedName, aaTable in pairs(aaSets or {}) do
        Logger.log_debug("\ayFinding best AA for Set: \am%s", unresolvedName)
        resolvedActionMap[unresolvedName] = Rotation.GetBestAA(aaTable)
    end

    return resolvedActionMap
end

--- Builds a gem assignment from the first list in spellList whose cond passes, keeping long-refresh spells out of the swap slot and reusing already-memmed placements unless forceRepack is true.
---@param caller any Class module instance passed to list/spell conditions.
---@param spellList table Array of {name, cond, spells} list descriptors.
---@param forceRepack boolean? Ignore current gem placement and pack in priority order; default is stable.
---@return table spellLoadOut Map of gem number → {selectedSpellData, spell}.
---@return string listName Name of the selected list, or an error string.
function Rotation.SetSpellLoadOutByPriority(caller, spellList, forceRepack)
    local spellLoadOut = {}
    local listName = "Error: No Valid List Found!"

    local numGems = mq.TLO.Me.NumGems()
    local swapGem = numGems
    Casting.UseGem = swapGem

    local desired = {}
    local picked = {}

    for _, l in ipairs(spellList or {}) do
        if l ~= nil and (not l.cond or Core.SafeCallFunc(string.format("List Condition Check %s", l.name), l.cond, caller)) then
            Logger.log_debug("\ayList \am%s\ay will be loaded.", l.name)
            listName = l.name
            for _, s in ipairs(l.spells) do
                if #desired >= numGems then break end
                if s.name_func then
                    s.name = Core.SafeCallFunc("Spell Name Func", s.name_func, caller) or
                        "Error in name_func!"
                end
                local spellName = s.name
                Logger.log_debug("\aw  ==> Testing \at%s", spellName)
                local bestSpell = Core.GetResolvedActionMapItem(spellName)
                if bestSpell then
                    local rankName = bestSpell.RankName()
                    local bookSpell = mq.TLO.Me.Book(rankName)()
                    local pass = Core.SafeCallFunc(
                        string.format("Spell Condition Check: %s", bestSpell() or "None"), s.cond, caller, bestSpell)
                    if pass and bookSpell and not picked[rankName] then
                        local recastMs = bestSpell.RecastTime() or 0
                        local isLong = recastMs >= 30000
                        table.insert(desired, { selectedSpellData = s, spell = bestSpell, rankName = rankName, isLong = isLong, })
                        picked[rankName] = true
                        Logger.log_debug("    ==> \aydesired[%d]\ay = \at%s\ax (recast \am%.1fs\ax, \ag%s\ax)", #desired, rankName, recastMs / 1000,
                            isLong and "long" or "short")
                    else
                        Logger.log_debug(
                            "    ==> \arSkip\ay \at%s\ay (pass=%s, bookSpell=%d, alreadyPicked=%s)",
                            spellName, Strings.BoolToColorString(pass), bookSpell or -1,
                            Strings.BoolToColorString(picked[rankName] or false))
                    end
                else
                    Logger.log_debug("    ==> \arNo Resolved Spell for \at%s", spellName)
                end
            end
            break
        else
            Logger.log_debug("\ayList \am%s\ay will \arNOT\ay be loaded ==> \arCondition Check Failed!", l.name)
        end
    end

    local swapOccupantIdx = nil
    if #desired >= numGems then
        for i = #desired, 1, -1 do
            if not desired[i].isLong then
                swapOccupantIdx = i
                break
            end
        end
        if not swapOccupantIdx then
            swapOccupantIdx = #desired
        end
    end

    if swapOccupantIdx then
        local occ = desired[swapOccupantIdx]
        spellLoadOut[swapGem] = { selectedSpellData = occ.selectedSpellData, spell = occ.spell, }
        Logger.log_debug("\aySwap slot \am%d\ay = \at%s\ax (lowest-priority %s)", swapGem, occ.rankName,
            occ.isLong and "long-refresh fallback" or "short-refresh")
        table.remove(desired, swapOccupantIdx)
    end

    local nonSwapOpen = {}
    for g = 1, numGems - 1 do nonSwapOpen[g] = true end

    if not forceRepack then
        for i = #desired, 1, -1 do
            local d = desired[i]
            for g = 1, numGems - 1 do
                if nonSwapOpen[g] and mq.TLO.Me.Gem(g)() == d.rankName then
                    spellLoadOut[g] = { selectedSpellData = d.selectedSpellData, spell = d.spell, }
                    nonSwapOpen[g] = false
                    table.remove(desired, i)
                    Logger.log_debug("\ay  Stable: \at%s\ay kept in gem \am%d", d.rankName, g)
                    break
                end
            end
        end
    end

    for _, d in ipairs(desired) do
        for g = 1, numGems - 1 do
            if nonSwapOpen[g] then
                spellLoadOut[g] = { selectedSpellData = d.selectedSpellData, spell = d.spell, }
                nonSwapOpen[g] = false
                Logger.log_debug("\ay  Fill: gem \am%d\ay = \at%s", g, d.rankName)
                break
            end
        end
    end

    return spellLoadOut, listName
end

--- Assigns spells to specific gem slots per spellGemList, respecting each
--- gem's cond and supporting CollapseGems to pack spells into sequential slots.
---@param caller any Class module instance passed to gem/spell conditions.
---@param spellGemList table Array of {gem, cond, spells} gem descriptors.
---@return table spellLoadOut Map of gem number → {selectedSpellData, spell}.
function Rotation.SetSpellLoadOutByGem(caller, spellGemList)
    local spellLoadOut = {}
    local spellsToLoad = {}

    Casting.UseGem = mq.TLO.Me.NumGems()

    --Algar notes 4/20/25: Bard spell system is deprecated and will be replaced by the gemless spell lists. This code will eventually be removed.
    -- Allow a callback fn for generating spell loadouts rather than a static list
    -- Can be used by bards to prioritize loadouts based on user choices
    if spellGemList and spellGemList.getSpellCallback and type(spellGemList.getSpellCallback) == "function" then
        spellGemList = spellGemList.getSpellCallback()
    end

    local curGem = 1

    for _, g in ipairs(spellGemList or {}) do
        local gem = g.gem
        if spellGemList.CollapseGems then
            gem = curGem
        end

        if Core.SafeCallFunc(string.format("Gem Condition Check %d", gem), g.cond, caller, gem) then
            Logger.log_debug("\ayGem \am%d\ay will be loaded.", gem)

            if g ~= nil and g.spells ~= nil then
                for _, s in ipairs(g.spells) do
                    if s.name_func then
                        s.name = Core.SafeCallFunc("Spell Name Func", s.name_func, caller) or
                            "Error in name_func!"
                    end
                    local spellName = s.name
                    Logger.log_debug("\aw  ==> Testing \at%s\aw for Gem \am%d", spellName, gem)
                    local bestSpell = Core.GetResolvedActionMapItem(spellName)
                    if bestSpell then
                        local bookSpell = mq.TLO.Me.Book(bestSpell.RankName())()
                        local pass = Core.SafeCallFunc(
                            string.format("Spell Condition Check: %s", bestSpell() or "None"), s.cond, caller, bestSpell)
                        local loadedSpell = spellsToLoad[bestSpell.RankName()] or false

                        if pass and bestSpell and bookSpell and not loadedSpell then
                            Logger.log_debug("    ==> \ayGem \am%d\ay will load \at%s\ax ==> \ag%s", gem, s
                                .name, bestSpell.RankName())
                            spellLoadOut[gem] = { selectedSpellData = s, spell = bestSpell, }
                            spellsToLoad[bestSpell.RankName()] = true
                            curGem = curGem + 1
                            break
                        else
                            Logger.log_debug(
                                "    ==> \ayGem \am%d will \arNOT\ay load \at%s (pass=%s, bestSpell=%s, bookSpell=%d, loadedSpell=%s)",
                                gem, s.name,
                                Strings.BoolToColorString(pass), bestSpell and bestSpell.RankName() or "", bookSpell or -1,
                                Strings.BoolToColorString(loadedSpell))
                        end
                    else
                        Logger.log_debug(
                            "    ==> \ayGem \am%d\ay will \arNOT\ay load \at%s\ax ==> \arNo Resolved Spell!", gem,
                            s.name)
                    end
                end
            else
                Logger.log_debug("    ==> No Resolved Spell! class file not configured properly")
            end
        else
            Logger.log_debug("\agGem %d will not be loaded.", gem)
        end
    end

    return spellLoadOut
end

--- Appends entries for spells in spellList that are not in the spellbook
--- to alreadyMissingSpells. When highestOnly is true, only the highest-level
--- spell in the list is checked.
---@param varName string Set name label used in the returned entry's selectedSpellData.
---@param spellList table Array of spell name strings to check.
---@param alreadyMissingSpells table Accumulator array to append missing spell entries to.
---@param highestOnly boolean If true, only reports the highest-level missing spell.
---@return table The updated alreadyMissingSpells array.
function Rotation.FindMissingSpells(varName, spellList, alreadyMissingSpells, highestOnly)
    local tmpTable = {}
    for _, spellName in ipairs(spellList or {}) do
        local spell = mq.TLO.Spell(spellName)
        if spell() ~= nil then
            --Logger.log_debug("Found %s level(%d) rank(%s)", s, spell.Level(), spell.RankName())
            if spell.Level() <= mq.TLO.Me.Level() then
                if not mq.TLO.Me.Book(spell.RankName.Name())() and not mq.TLO.Me.CombatAbility(spell.RankName.Name())() then
                    table.insert(tmpTable, { selectedSpellData = { name = varName, }, missing = true, spell = spell, })
                else
                    table.insert(tmpTable, { selectedSpellData = { name = varName, }, missing = false, spell = spell, })
                end
            end
        end -- end if spell nil check
    end

    if #tmpTable > 0 then
        if not highestOnly then
            for _, data in ipairs(tmpTable) do
                Logger.log_debug("Set[%s] : Spell[%s (%d)] : Have[%s]", data.selectedSpellData.name, data.spell.RankName(), data.spell.Level(),
                    Strings.BoolToColorString(not data.missing))
                if data.missing then
                    table.insert(alreadyMissingSpells, data)
                end
            end
        else
            table.sort(tmpTable, function(a, b) return a.spell.Level() > b.spell.Level() end)
            for _, data in ipairs(tmpTable) do
                Logger.log_debug("Set[%s] : Spell[%s (%d)]: Have[%s]", data.selectedSpellData.name, data.spell.RankName(), data.spell.Level(),
                    Strings.BoolToColorString(not data.missing))
            end
            if tmpTable[1].missing then
                table.insert(alreadyMissingSpells, tmpTable[1])
            end
        end
    end

    return alreadyMissingSpells
end

--- Iterates all sets in abilitySets and collects missing spells by calling
--- FindMissingSpells for each one.
---@param abilitySets table Map of set name → spell name array.
---@param highestOnly boolean If true, only report the highest-level missing per set.
---@return table Array of missing spell entries from all ability sets.
function Rotation.FindAllMissingSpells(abilitySets, highestOnly)
    local missingSpellList = {}

    for varName, spellTable in pairs(abilitySets) do
        missingSpellList = Rotation.FindMissingSpells(varName, spellTable, missingSpellList, highestOnly)
    end

    return missingSpellList
end

--- Calls entry.pre_activate(caller, condArg) if the entry defines it,
--- allowing the class to prepare state before an action fires.
---@param caller any Class module instance.
---@param resolvedActionMap table Map of entry name → resolved action.
---@param entry table Rotation entry that may define pre_activate.
function Rotation.RunPreActivate(caller, resolvedActionMap, entry)
    if entry.pre_activate then
        Logger.log_verbose("Running pre-activate for %s.", entry.name)
        entry.pre_activate(caller, Rotation.GetEntryConditionArg(resolvedActionMap, entry))
    end
end

return Rotation
