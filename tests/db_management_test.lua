-- DB Management integration test (Options > DB Management: Copy / Reset / Delete + reload trigger).
--
-- Run from the RGMercs debug window (it must execute in RGMercs's Lua state):
--
--     package.loaded['tests.db_management_test'] = nil; require('tests.db_management_test').RunAll()
--
-- It operates on sentinel characters on a fake server ("rgtestsrv") inside the live config DB,
-- exercises the real CopySettings / ResetSettings / DeleteSettings / ClearList / DBManagement.RequestReload
-- and the running-peer reset/delete guards, then deletes the sentinel rows/characters. A handful of
-- functions (ClassLoader.reloadConfig, Comms.SendMessage / GetPeerHeartbeat / IsCharRunning, Config.Db.deleteModule, and briefly
-- Globals.CurLoadedChar/Server/Class) are swapped to observe behavior and restored afterward.
-- If anything leaks and mercs misbehaves, `/lua run rgmercs` to reload. Output goes straight to
-- the console via printf (not the RGMercs logger), so it shows regardless of log level.

local ClassLoader  = require('utils.classloader')
local Comms        = require('utils.comms')
local Config       = require('utils.config')
local DBManagement = require('utils.db_management')
local Globals      = require('utils.globals')
local OptionsUI    = require('ui.options')

local M            = {}

local SRV          = "rgtestsrv" -- starts with a lowercase letter on purpose: exercises GetPeerName's first-letter normalization
local CLS          = "WAR"
local CLS2         = "SHD"

local pass, fail   = 0, 0
local function check(label, cond, detail)
    if cond then
        pass = pass + 1
        printf("\ag[DBTEST PASS]\ax %s", label)
    else
        fail = fail + 1
        printf("\ar[DBTEST FAIL]\ax %s%s", label, detail and (" -- " .. detail) or "")
    end
end

local function deepEqual(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function nKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

--- Runs the DB Management integration tests. Returns true if all passed.
--- @return boolean
function M.RunAll()
    pass, fail = 0, 0
    printf("\ay==== DB Management Test starting ====\ax")

    if not next(Config.moduleDefaultSettings or {}) then
        printf("\ar[DBTEST] Config.moduleDefaultSettings is empty -- run this from the RGMercs debug window, not via /lua run.\ax")
        return false
    end

    -- Pick interesting modules from the real registered settings
    local allMods = {}
    for m in pairs(Config.moduleDefaultSettings) do table.insert(allMods, m) end
    table.sort(allMods)

    local function keysWithDefault(md)
        local out = {}
        for k, d in pairs(md or {}) do if d and d.Default ~= nil then out[#out + 1] = { k = k, d = d, } end end
        return out
    end

    local testMods = {}
    for _, m in ipairs(allMods) do
        if #keysWithDefault(Config.moduleDefaultSettings[m]) > 0 then
            testMods[#testMods + 1] = m
            if #testMods == 3 then break end
        end
    end
    if #testMods == 0 then
        printf("\ar[DBTEST] no modules with default settings found -- aborting.\ax")
        return false
    end

    local unseededMod
    for _, m in ipairs(allMods) do
        local inT = false
        for _, t in ipairs(testMods) do
            if t == m then
                inT = true; break
            end
        end
        if not inT then
            unseededMod = m; break
        end
    end

    printf("[DBTEST] testMods=[%s] unseededMod=%s", table.concat(testMods, ", "), tostring(unseededMod))

    -- Seed / DB helpers
    local function seedVal(d)
        local v, t = d.Default, type(d.Default)
        if t == "boolean" then return not v end
        if t == "number" then return v + 100000 end
        if t == "string" then return v .. "__rgt__" end
        if t == "table" then return { __rgt__ = true, } end
        return v
    end
    local function buildSeed(md)
        local s = {}; for _, e in ipairs(keysWithDefault(md)) do s[e.k] = seedVal(e.d) end; return s
    end
    local function setM(c, cl, m, t) Config.Db:setAll(SRV, c, cl, m, t) end
    local function getM(c, cl, m) return Config.Db:getAll(SRV, c, cl, m) or {} end
    local function wipe(c, cl) for _, m in ipairs(allMods) do Config.Db:deleteModule(SRV, c, cl, m) end end
    local function lbl(c) return c .. " (" .. SRV .. ")" end
    local function charRowExists(c)
        local stmt = Config.Db._db:prepare([[
            SELECT 1 FROM character ch JOIN server s ON s.id = ch.server_id
            WHERE s.name = ? AND ch.name = ? LIMIT 1;
        ]])
        if not stmt then return false end
        stmt:bind(1, SRV); stmt:bind(2, c)
        local found = false
        for _ in stmt:rows() do found = true end
        stmt:finalize()
        return found
    end

    -- Snapshots for restore (taken once, restored once unconditionally at the end).
    -- NOTE: deliberately never patch Globals.CurLoadedChar/CurServer/CurLoadedClass -- the render
    -- loop reads settings against them with no nil guard, so a bogus value crashes mercs.
    local sv = {
        reloadConfig     = ClassLoader.reloadConfig,
        SendMessage      = Comms.SendMessage,
        GetPeerHeartbeat = Comms.GetPeerHeartbeat,
        IsCharRunning    = Comms.IsCharRunning,
        deleteModule     = Config.Db.deleteModule,
        ToastStates      = OptionsUI.ToastStates,
        dbChars          = OptionsUI.dbChars,
        dbFromClasses    = OptionsUI.dbFromClasses,
    }
    local function restore()
        ClassLoader.reloadConfig = sv.reloadConfig
        Comms.SendMessage        = sv.SendMessage
        Comms.GetPeerHeartbeat   = sv.GetPeerHeartbeat
        Comms.IsCharRunning      = sv.IsCharRunning
        Config.Db.deleteModule   = sv.deleteModule
        OptionsUI.ToastStates    = sv.ToastStates
        OptionsUI.dbChars        = sv.dbChars
        OptionsUI.dbFromClasses  = sv.dbFromClasses
    end

    -- the real current char/server/class -- used as the target for the "local current" reload paths
    local meChar, meSrv, meCls = Globals.CurLoadedChar, Globals.CurServer, Globals.CurLoadedClass

    OptionsUI.ToastStates = {} -- absorb the test's toasts; restored at the end

    local sentinelChars = { "a", "b", "c", "d", "e", "f", "g", "h", "i", }
    local rec = {}
    local savedPullDeny = Config:GetSetting('PullDenyListShared')

    local ranOk, runErr = pcall(function()
        -- 1) Copy "All Modules"
        wipe("a", CLS); wipe("b", CLS)
        for _, m in ipairs(testMods) do setM("a", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:CopySettings({ lbl("a"), lbl("b"), }, 1, CLS, 2, CLS, "All Modules")
        for _, m in ipairs(testMods) do
            check("Copy All: " .. m .. " matches source", deepEqual(getM("a", CLS, m), getM("b", CLS, m)),
                string.format("src=%d dst=%d", nKeys(getM("a", CLS, m)), nKeys(getM("b", CLS, m))))
        end
        if unseededMod then check("Copy All: unseeded module empty on dst", nKeys(getM("b", CLS, unseededMod)) == 0) end

        -- 2) Copy single module
        wipe("c", CLS); wipe("d", CLS)
        for _, m in ipairs(testMods) do setM("c", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:CopySettings({ lbl("c"), lbl("d"), }, 1, CLS, 2, CLS, testMods[1])
        check("Copy single: target module copied", deepEqual(getM("c", CLS, testMods[1]), getM("d", CLS, testMods[1])))
        if testMods[2] then check("Copy single: other module NOT copied", nKeys(getM("d", CLS, testMods[2])) == 0) end

        -- 2a) Copying a module the source never saved reports failure rather than a success toast
        if unseededMod then
            local empty = DBManagement.CopySettings("c", SRV, CLS, "d", SRV, CLS, unseededMod)
            check("Copy empty module: reports failure", empty.ok == false, string.format("ok=%s", tostring(empty.ok)))
        end

        -- 3) Copy cross-class
        wipe("e", CLS); wipe("f", CLS); wipe("f", CLS2)
        for _, m in ipairs(testMods) do setM("e", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:CopySettings({ lbl("e"), lbl("f"), }, 1, CLS, 2, CLS2, "All Modules")
        check("Copy cross-class: lands on target class", deepEqual(getM("e", CLS, testMods[1]), getM("f", CLS2, testMods[1])))
        check("Copy cross-class: target's other class untouched", nKeys(getM("f", CLS, testMods[1])) == 0)

        -- 4) Reset "All Modules" clears saved rows (the target rebuilds its own defaults on next load)
        wipe("g", CLS)
        for _, m in ipairs(testMods) do setM("g", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:ResetSettings({ lbl("x"), lbl("g"), }, 2, CLS, "All Modules")
        for _, m in ipairs(testMods) do
            check("Reset All: " .. m .. " rows cleared", nKeys(getM("g", CLS, m)) == 0,
                string.format("left=%d", nKeys(getM("g", CLS, m))))
        end

        -- 5) Reset single module clears only that module
        wipe("h", CLS)
        for _, m in ipairs(testMods) do setM("h", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:ResetSettings({ lbl("x"), lbl("h"), }, 2, CLS, testMods[1])
        check("Reset single: target module cleared", nKeys(getM("h", CLS, testMods[1])) == 0)
        if testMods[2] then check("Reset single: other module NOT cleared", nKeys(getM("h", CLS, testMods[2])) > 0) end

        -- 5a) Reset: refuses while target is "running" (asserts the refusal itself, since surviving rows
        -- alone would not distinguish it from the other bails)
        wipe("h", CLS)
        setM("h", CLS, testMods[1], buildSeed(Config.moduleDefaultSettings[testMods[1]]))
        ---@diagnostic disable-next-line: duplicate-set-field
        Comms.IsCharRunning = function() return true end
        local guarded = DBManagement.ResetSettings("h", SRV, CLS, "All Modules")
        Comms.IsCharRunning = sv.IsCharRunning
        check("Reset guard: reports refusal", guarded.ok == false and guarded.refusedRunning == true,
            string.format("ok=%s refusedRunning=%s", tostring(guarded.ok), tostring(guarded.refusedRunning)))
        check("Reset guard: rows intact", nKeys(getM("h", CLS, testMods[1])) > 0)

        -- 5b) Reset: a busy db is reported to the caller rather than reloading stale settings
        ---@diagnostic disable-next-line: duplicate-set-field
        Config.Db.deleteModule = function(_, _, _, _, _) return false end
        local busy = DBManagement.ResetSettings("h", SRV, CLS, "All Modules")
        Config.Db.deleteModule = sv.deleteModule
        check("Reset busy: reports the busy db, not another bail", busy.ok == false and busy.refusedRunning ~= true,
            string.format("ok=%s refusedRunning=%s", tostring(busy.ok), tostring(busy.refusedRunning)))

        -- 6) Delete: refuses while target is "running", then succeeds
        wipe("i", CLS)
        setM("i", CLS, testMods[1], buildSeed(Config.moduleDefaultSettings[testMods[1]]))
        ---@diagnostic disable-next-line: duplicate-set-field
        Comms.IsCharRunning = function() return true end
        OptionsUI:DeleteSettings({ lbl("x"), lbl("i"), }, 2, CLS)
        check("Delete guard: refuses while target is running (rows intact)", nKeys(getM("i", CLS, testMods[1])) > 0)
        Comms.IsCharRunning = sv.IsCharRunning
        OptionsUI:DeleteSettings({ lbl("x"), lbl("i"), }, 2, CLS)
        do
            local left = 0
            for _, m in ipairs(testMods) do left = left + nKeys(getM("i", CLS, m)) end
            check("Delete: removes all module rows for char/class", left == 0)
        end

        -- 6a) Delete: last class for a char -> character row is also removed
        wipe("a", CLS); wipe("a", CLS2)
        setM("a", CLS, testMods[1], buildSeed(Config.moduleDefaultSettings[testMods[1]]))
        check("Orphan cleanup precondition: char row exists after seed", charRowExists("a"))
        OptionsUI:DeleteSettings({ lbl("x"), lbl("a"), }, 2, CLS)
        check("Orphan cleanup: char row removed when last class is deleted", not charRowExists("a"))

        -- 6b) Delete: char has another class -> character row is preserved
        wipe("b", CLS); wipe("b", CLS2)
        setM("b", CLS, testMods[1], buildSeed(Config.moduleDefaultSettings[testMods[1]]))
        setM("b", CLS2, testMods[1], buildSeed(Config.moduleDefaultSettings[testMods[1]]))
        OptionsUI:DeleteSettings({ lbl("x"), lbl("b"), }, 2, CLS)
        check("Orphan cleanup: char row preserved when another class remains", charRowExists("b"))
        check("Orphan cleanup: surviving class rows intact", nKeys(getM("b", CLS2, testMods[1])) > 0)

        -- 7) ClearList empties a shared list. This writes the live shared row rather than a
        -- sentinel one, so the restore lives in the teardown below, out of reach of an abort.
        Config:SetSetting('PullDenyListShared', { zonea = { "mob1", "mob2", }, zoneb = { "mob3", }, })
        DBManagement.ClearList("PullDenyListShared", "Pull Deny")
        check("ClearList: shared list emptied", nKeys(Config:GetSetting('PullDenyListShared')) == 0,
            string.format("left=%d", nKeys(Config:GetSetting('PullDenyListShared'))))

        -- The reload tests call DBManagement.RequestReload directly (no DB writes, no Globals patching).
        -- For the "local current" path we pass the real current char/server/class so Comms.IsLocalCurrent
        -- is true without touching anything. The send recorder only flags the actual "ReloadConfig" event
        -- and delegates everything else to the real function -- the render loop interleaves with
        -- debug-window execution and would otherwise both trip the recorder and get nil where it expects a value.
        -- ClassLoader.reloadConfig is stubbed outright: really reloading here would re-register every
        -- module's settings underneath the run.

        local function makeSendRecorder(onReload)
            return function(peer, mod, evt, ...)
                if evt == "ReloadConfig" then
                    onReload(peer, mod, evt); return
                end
                return sv.SendMessage(peer, mod, evt, ...)
            end
        end

        -- 7) Reload: local current -> ClassLoader.reloadConfig
        rec.reloadHit = false
        ---@diagnostic disable-next-line: duplicate-set-field
        ClassLoader.reloadConfig = function() rec.reloadHit = true end
        DBManagement.RequestReload(meChar, meSrv, meCls)
        ClassLoader.reloadConfig = sv.reloadConfig
        check("Reload: local current -> ClassLoader.reloadConfig()", rec.reloadHit)

        -- 8) Reload: networked peer running that class -> SendMessage (also exercises GetPeerName casing)
        local expectKey = "peerk (" .. SRV:sub(1, 1):upper() .. SRV:sub(2) .. ")"
        rec.sentPeer, rec.sentModule = nil, nil
        ---@diagnostic disable-next-line: duplicate-set-field
        Comms.GetPeerHeartbeat = function(key)
            if key == expectKey then return { Data = { Class = CLS, }, } end
            return sv.GetPeerHeartbeat(key)
        end
        Comms.SendMessage = makeSendRecorder(function(peer, mod) rec.sentPeer, rec.sentModule = peer, mod end)
        DBManagement.RequestReload("peerk", SRV, CLS)
        Comms.GetPeerHeartbeat, Comms.SendMessage = sv.GetPeerHeartbeat, sv.SendMessage
        check("Reload: running peer -> SendMessage(<normalized key>, Config, ReloadConfig)",
            rec.sentPeer == expectKey and rec.sentModule == "Config",
            string.format("got peer=%s module=%s (expectKey=%s)", tostring(rec.sentPeer), tostring(rec.sentModule), expectKey))

        -- 9) Reload: peer running a different class -> nothing fires
        rec.fired = false
        ---@diagnostic disable-next-line: duplicate-set-field
        Comms.GetPeerHeartbeat = function(key)
            if key == expectKey then return { Data = { Class = CLS2, }, } end
            return sv.GetPeerHeartbeat(key)
        end
        Comms.SendMessage = makeSendRecorder(function() rec.fired = true end)
        DBManagement.RequestReload("peerk", SRV, CLS)
        Comms.GetPeerHeartbeat, Comms.SendMessage = sv.GetPeerHeartbeat, sv.SendMessage
        check("Reload: peer on another class -> nothing fires", not rec.fired)

        -- 10) Reload: char isn't running anywhere -> nothing fires
        rec.fired = false
        ---@diagnostic disable-next-line: duplicate-set-field
        ClassLoader.reloadConfig = function() rec.fired = true end
        Comms.SendMessage = makeSendRecorder(function() rec.fired = true end)
        DBManagement.RequestReload("notrunning", SRV, CLS)
        ClassLoader.reloadConfig, Comms.SendMessage = sv.reloadConfig, sv.SendMessage
        check("Reload: char not running -> nothing fires", not rec.fired)
    end)

    restore()
    pcall(function() Config:SetSetting('PullDenyListShared', savedPullDeny or {}) end)

    -- Cleanup sentinel rows + characters (best effort). After restore(), so an abort mid-run
    -- can't leave Config.Db.deleteModule stubbed and silently skip every wipe below.
    for _, c in ipairs(sentinelChars) do
        pcall(function()
            wipe(c, CLS); wipe(c, CLS2)
        end)
        pcall(function() Config.Db:deleteCharacter(SRV, c) end)
    end

    if not ranOk then printf("\ar[DBTEST] ABORTED with error: %s\ax", tostring(runErr)) end
    printf("\ay==== DB Management Test complete: PASS %d  FAIL %d ====\ax", pass, fail)
    return fail == 0 and ranOk
end

return M
