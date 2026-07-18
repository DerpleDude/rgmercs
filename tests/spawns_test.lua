-- Spawns registry integration test (SpawnList setters, row lifecycle, active-section writes, migration recipe, IsDeniedTarget live checks).
--
-- Run from the RGMercs debug window (it must execute in RGMercs's Lua state):
--
--     package.loaded['tests.spawns_test'] = nil; require('tests.spawns_test').RunAll()
--
-- Registry tests drive the real Config:ZoneRegistry* setters against the live SpawnList setting,
-- under a sentinel zone key where the zone doesn't matter and under the current zone's long-name
-- section for the active-section write checks. A deep-copy snapshot of SpawnList is taken first and
-- written back unconditionally at the end, so a failing check cannot leave the list dirty. Migration
-- tests drive Db:migrateServerModule (LoadSettings' copy+merge+delete) and seedServerValue's
-- never-overwrite guarantee against sentinel rows on a fake server ("rgtestsrv") inside the
-- live config DB, then delete them. Output goes
-- straight to the console via printf (not the RGMercs logger), so it shows regardless of log level.

local mq         = require('mq')
local Config     = require('utils.config')
local Globals    = require('utils.globals')
local Spawns     = require('modules.spawns')
local Strings    = require('utils.strings')
local Targeting  = require('utils.targeting')

local M          = {}

local SRV        = "rgtestsrv"

local pass, fail = 0, 0
local function check(label, cond, detail)
    if cond then
        pass = pass + 1
        printf("\ag[SPAWNSTEST PASS]\ax %s", label)
    else
        fail = fail + 1
        printf("\ar[SPAWNSTEST FAIL]\ax %s%s", label, detail and (" -- " .. detail) or "")
    end
end

local function deepEqual(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deepCopy(v) end
    return copy
end

--- Runs the Spawns registry and migration integration tests. Returns true if all passed.
--- @return boolean
function M.RunAll()
    pass, fail = 0, 0
    printf("\ay==== Spawns Registry Test starting ====\ax")

    if not (Config.TempSettings.SettingToModuleCache or {})['SpawnList'] then
        printf("\ar[SPAWNSTEST] SpawnList setting is not registered -- run this from the RGMercs debug window, not via /lua run.\ax")
        return false
    end

    local zoneFull = (mq.TLO.Zone.Name() or ""):lower()
    local zoneShort = (mq.TLO.Zone.ShortName() or ""):lower()
    local sentinelZone = "rgtest_sentinel_zone"
    local savedList = deepCopy(Config:GetSetting('SpawnList') or {})

    local regOk, regErr = pcall(function()
        -- Clear routing: clearing flags on unlisted names creates no section and no rows
        Config:ZoneRegistryClearFlag("RGTest Mob", 'SpawnList', 'named', nil, sentinelZone)
        Config:ZoneRegistryClearFlag("RGTest Mob", 'SpawnList', 'deny', nil, sentinelZone)
        Config:ZoneRegistryClearFlag("RGTest Mob", 'SpawnList', 'elementalImmunities', 'Fire', sentinelZone)
        local list = Config:GetSetting('SpawnList') or {}
        check("ClearFlag on unlisted name: no zone section created", list[sentinelZone] == nil)

        -- Row lifecycle: bare add persists a flagless row
        Config:ZoneRegistryAddEntry("RGTest Mob", 'SpawnList', sentinelZone)
        list = Config:GetSetting('SpawnList') or {}
        local entry = list[sentinelZone] and list[sentinelZone]["RGTest Mob"]
        check("Bare add: row exists", entry ~= nil)
        check("Bare add: row is flagless", entry ~= nil and next(entry) == nil)

        Config:ZoneRegistryClearFlag("RGTest Other", 'SpawnList', 'deny', nil, sentinelZone)
        list = Config:GetSetting('SpawnList') or {}
        check("ClearFlag on unlisted name: no row created in existing section", list[sentinelZone] ~= nil and list[sentinelZone]["RGTest Other"] == nil)

        Config:ZoneRegistrySetFlag("RGTest Mob", 'SpawnList', 'deny', true, sentinelZone)
        Config:ZoneRegistryAddEntry("RGTest Mob", 'SpawnList', sentinelZone)
        entry = (Config:GetSetting('SpawnList') or {})[sentinelZone]["RGTest Mob"]
        check("Re-add of existing row: flags preserved", entry.deny == true)

        -- Named and deny independence, raw tri-state storage
        Config:ZoneRegistrySetFlag("RGTest Mob", 'SpawnList', 'named', true, sentinelZone)
        entry = (Config:GetSetting('SpawnList') or {})[sentinelZone]["RGTest Mob"]
        check("SetFlag named true: stored", entry.named == true)
        check("SetFlag named true: deny untouched", entry.deny == true)

        Config:ZoneRegistrySetFlag("RGTest Mob", 'SpawnList', 'named', false, sentinelZone)
        entry = (Config:GetSetting('SpawnList') or {})[sentinelZone]["RGTest Mob"]
        check("SetFlag named false: stored raw, row kept", entry ~= nil and entry.named == false)
        check("SetFlag named false: deny untouched", entry.deny == true)

        Config:ZoneRegistryClearFlag("RGTest Mob", 'SpawnList', 'deny', nil, sentinelZone)
        entry = (Config:GetSetting('SpawnList') or {})[sentinelZone]["RGTest Mob"]
        check("ClearFlag deny arm: cleared", entry.deny == nil)
        check("ClearFlag deny arm: named untouched", entry.named == false)

        -- Last-flag-clear keeps the row; explicit delete removes it
        Config:ZoneRegistryClearFlag("RGTest Mob", 'SpawnList', 'named', nil, sentinelZone)
        entry = (Config:GetSetting('SpawnList') or {})[sentinelZone]["RGTest Mob"]
        check("Last flag cleared: row kept", entry ~= nil)
        check("Last flag cleared: row is flagless", entry ~= nil and next(entry) == nil)

        Spawns:DeleteEntryFromCustomList("RGTest Mob", sentinelZone)
        list = Config:GetSetting('SpawnList') or {}
        check("Explicit delete: row removed", list[sentinelZone] == nil or list[sentinelZone]["RGTest Mob"] == nil)

        -- Active-section writes: non-empty user long section captures default-zoneKey writes
        if zoneFull ~= "" and zoneShort ~= "" and zoneFull ~= zoneShort then
            Config:ZoneRegistryAddEntry("RGTest Long Anchor", 'SpawnList', zoneFull)
            Config:ZoneRegistryAddEntry("RGTest Default Write", 'SpawnList')
            list = Config:GetSetting('SpawnList') or {}
            check("Active-section add: lands in long section", list[zoneFull] ~= nil and list[zoneFull]["RGTest Default Write"] ~= nil)
            check("Active-section add: short section untouched", list[zoneShort] == nil or list[zoneShort]["RGTest Default Write"] == nil)
            Config:ZoneRegistrySetFlag("RGTest Default Write", 'SpawnList', 'deny', true)
            list = Config:GetSetting('SpawnList') or {}
            check("Active-section SetFlag: lands in long section", list[zoneFull]["RGTest Default Write"] ~= nil and list[zoneFull]["RGTest Default Write"].deny == true)
            check("Active-section SetFlag: no short-section row", list[zoneShort] == nil or list[zoneShort]["RGTest Default Write"] == nil)
        else
            printf("[SPAWNSTEST] zone long/short names unavailable or identical -- skipping active-section checks.")
        end
    end)

    Config:SetSetting('SpawnList', savedList)
    if not regOk then printf("\ar[SPAWNSTEST] registry tests ABORTED with error: %s\ax", tostring(regErr)) end

    -- IsDeniedTargetId: the deny name arm needs a real spawn, so drive our own through the id form's delegation
    local myId = mq.TLO.Me.ID() or 0
    local savedDenyNames, savedHasDeny = Globals.ZoneDenyNames, Globals.ZoneHasDeny
    local savedForceTarget, savedForceCombat = Globals.ForceTargetID, Globals.ForceCombatID
    local wasSessionIgnored = Globals.IgnoredTargetIDs:contains(myId)
    local denyOk, denyErr = pcall(function()
        local myKey = Strings.TrimSpaces(mq.TLO.Spawn(myId).CleanName() or ""):lower()
        if myId <= 0 or myKey == "" then
            printf("[SPAWNSTEST] own spawn unavailable -- skipping IsDeniedTarget checks.")
            return
        end
        if wasSessionIgnored then Globals.IgnoredTargetIDs:remove(myId) end

        Globals.ZoneDenyNames = { [myKey] = true, }
        Globals.ZoneHasDeny = true
        check("IsDeniedTargetId: denied name rejected", Targeting.IsDeniedTargetId(myId) == true)

        Globals.ForceTargetID = myId
        check("IsDeniedTargetId: force target overrides deny", Targeting.IsDeniedTargetId(myId) == false)
        Globals.ForceTargetID = savedForceTarget
        Globals.ForceCombatID = myId
        check("IsDeniedTargetId: force combat overrides deny", Targeting.IsDeniedTargetId(myId) == false)
        Globals.ForceCombatID = savedForceCombat

        Globals.ZoneHasDeny = false
        check("IsDeniedTargetId: ZoneHasDeny false short-circuit", Targeting.IsDeniedTargetId(myId) == false)

        Globals.ZoneHasDeny = true
        Globals.ZoneDenyNames = { ["rgtest no such mob"] = true, }
        check("IsDeniedTargetId: unlisted name passes", Targeting.IsDeniedTargetId(myId) == false)
        check("IsDeniedTargetId: nonexistent spawn id safe", Targeting.IsDeniedTargetId(999999999) == false)
    end)

    Globals.ZoneDenyNames = savedDenyNames
    Globals.ZoneHasDeny = savedHasDeny
    Globals.ForceTargetID = savedForceTarget
    Globals.ForceCombatID = savedForceCombat
    if wasSessionIgnored then Globals.IgnoredTargetIDs:add(myId) end
    if not denyOk then printf("\ar[SPAWNSTEST] IsDeniedTarget checks ABORTED with error: %s\ax", tostring(denyErr)) end

    local Db = Config.Db

    local function serverRowExists(module, key)
        local stmt = Db._db:prepare([[
            SELECT 1 FROM server_config sc JOIN server s ON s.id = sc.server_id
            WHERE s.name = ? AND sc.module = ? AND sc.key = ? LIMIT 1;
        ]])
        if not stmt then return false end
        stmt:bind(1, SRV); stmt:bind(2, module); stmt:bind(3, key)
        local found = false
        for _ in stmt:rows() do found = true end
        stmt:finalize()
        return found
    end

    -- ===== DEPRECATED MIGRATION TESTS (sunset 1/1/27 - delete this whole block with the Spawns migration) =====
    local function replayMigrationRecipe()
        local oldList = Db:getServerValue(SRV, 'Named', 'CustomNamedList')
        if oldList ~= nil then
            local newList = Db:getServerValue(SRV, 'Spawns', 'SpawnList')
            local merged = newList and Spawns:MergeZoneRegistries(oldList, newList) or oldList
            Db:migrateServerModule(SRV, 'Named', 'Spawns', 'SpawnList', merged)
        end
    end

    local migOk, migErr = pcall(function()
        Db:deleteServerModule(SRV, 'Named')
        Db:deleteServerModule(SRV, 'Spawns')

        local oldList = {
            zonea = { ["Conflict Mob"] = { named = true, }, ["Old Only"] = { deny = true, }, },
            zoneb = { ["Old Zone Mob"] = { named = true, }, },
        }
        Db:setServerValue(SRV, 'Named', 'CustomNamedList', oldList)
        check("seed: old row lands in DB", serverRowExists('Named', 'CustomNamedList'))

        local existingNew = { zonea = { ["Conflict Mob"] = { named = false, }, ["New Only"] = { named = true, }, }, }
        Db:setServerValue(SRV, 'Spawns', 'SpawnList', existingNew)

        replayMigrationRecipe()
        local migrated = Db:_fetchServerValue(SRV, 'Spawns', 'SpawnList')
        check("Migration: conflict pair new side wins", migrated ~= nil and migrated.zonea["Conflict Mob"].named == false)
        check("Migration: old-only pair carried", migrated ~= nil and migrated.zonea["Old Only"].deny == true)
        check("Migration: new-only pair kept", migrated ~= nil and migrated.zonea["New Only"].named == true)
        check("Migration: old-only zone carried", migrated ~= nil and migrated.zoneb["Old Zone Mob"].named == true)
        check("Migration: old Named row deleted from DB", not serverRowExists('Named', 'CustomNamedList'))
        check("Migration: old Named row read is nil", Db:getServerValue(SRV, 'Named', 'CustomNamedList') == nil)
        check("Migration: cached read matches DB", deepEqual(Db:getServerValue(SRV, 'Spawns', 'SpawnList'), migrated))

        local before = deepCopy(migrated)
        replayMigrationRecipe()
        check("Migration re-run: no-ops with old row absent", deepEqual(Db:_fetchServerValue(SRV, 'Spawns', 'SpawnList'), before))
        check("migrateServerModule: idempotent on absent old module", Db:migrateServerModule(SRV, 'Named', 'Spawns', 'SpawnList', before) == true)

        Db:deleteServerModule(SRV, 'Spawns')
        Db:setServerValue(SRV, 'Named', 'CustomNamedList', oldList)
        replayMigrationRecipe()
        check("Migration without existing Spawns row: copied verbatim", deepEqual(Db:_fetchServerValue(SRV, 'Spawns', 'SpawnList'), oldList))
        check("Migration without existing Spawns row: old row deleted", not serverRowExists('Named', 'CustomNamedList'))
    end)

    -- Cleanup sentinel rows (best effort)
    pcall(function()
        Db:deleteServerModule(SRV, 'Named')
        Db:deleteServerModule(SRV, 'Spawns')
    end)
    if not migOk then
        fail = fail + 1
        printf("\ar[SPAWNSTEST] migration tests ABORTED with error: %s\ax", tostring(migErr))
    end
    -- ===== END DEPRECATED MIGRATION TESTS (sunset 1/1/27) =====

    local seedOk, seedErr = pcall(function()
        -- seedServerValue never-clobber
        local original = { zonec = { ["Seed Guard Mob"] = { deny = true, }, }, }
        Db:setServerValue(SRV, 'Spawns', 'SpawnList', original)
        check("seedServerValue: true when row already exists", Db:seedServerValue(SRV, 'Spawns', 'SpawnList', { zonec = { ["Wrong Mob"] = { named = true, }, }, }) == true)
        check("seedServerValue: existing row not overwritten", deepEqual(Db:_fetchServerValue(SRV, 'Spawns', 'SpawnList'), original))
        check("seedServerValue: cache not polluted by attempted seed", deepEqual(Db:getServerValue(SRV, 'Spawns', 'SpawnList'), original))

        Db:deleteServerModule(SRV, 'Spawns')
        local seeded = { zoned = { ["Fresh Seed Mob"] = { named = true, }, }, }
        check("seedServerValue: inserts when absent", Db:seedServerValue(SRV, 'Spawns', 'SpawnList', seeded) == true)
        check("seedServerValue: inserted value round-trips", deepEqual(Db:_fetchServerValue(SRV, 'Spawns', 'SpawnList'), seeded))
    end)

    pcall(function()
        Db:deleteServerModule(SRV, 'Spawns')
    end)
    if not seedOk then printf("\ar[SPAWNSTEST] seedServerValue tests ABORTED with error: %s\ax", tostring(seedErr)) end

    printf("\ay==== Spawns Registry Test complete: PASS %d  FAIL %d ====\ax", pass, fail)
    return fail == 0 and regOk and denyOk and seedOk
end

return M
