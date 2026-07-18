-- DB Management integration test (Options > DB Management: Copy / Reset / Delete + rescan trigger).
--
-- Run from the RGMercs debug window (it must execute in RGMercs's Lua state):
--
--     package.loaded['tests.db_management_test'] = nil; require('tests.db_management_test').RunAll()
--
-- It operates on sentinel characters on a fake server ("rgtestsrv") inside the live config DB,
-- exercises the real CopySettings / ResetSettings / DeleteSettings / DBManagement.RequestRescan
-- and the running-peer delete guard, then deletes the sentinel rows/characters. A handful of
-- functions (Modules.ExecModule, Comms.SendMessage / GetPeerHeartbeat / IsCharRunning, and briefly
-- Globals.CurLoadedChar/Server/Class) are swapped to observe behavior and restored afterward.
-- If anything leaks and mercs misbehaves, `/lua run rgmercs` to reload. Output goes straight to
-- the console via printf (not the RGMercs logger), so it shows regardless of log level.

local Comms        = require('utils.comms')
local Config       = require('utils.config')
local DBManagement = require('utils.db_management')
local Globals      = require('utils.globals')
local Modules      = require('utils.modules')
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
    local function hasFlag(m, f)
        for _, d in pairs(Config.moduleDefaultSettings[m] or {}) do if f(d) then return true end end
        return false
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
        for _, t in ipairs(testMods) do if t == m then
                inT = true; break
            end end
        if not inT then
            unseededMod = m; break
        end
    end

    local rescanMod
    for _, m in ipairs(allMods) do
        if #keysWithDefault(Config.moduleDefaultSettings[m]) > 0 and hasFlag(m, function(d) return d.RequiresLoadoutChange end) then
            rescanMod = m; break
        end
    end

    local noRescanMod
    for _, m in ipairs(testMods) do
        if not hasFlag(m, function(d) return d.RequiresLoadoutChange end) then
            noRescanMod = m; break
        end
    end

    local customMod, customKey
    for _, m in ipairs(allMods) do
        for k, d in pairs(Config.moduleDefaultSettings[m]) do
            if d.Type == "Custom" and d.Default ~= nil then
                customMod, customKey = m, k; break
            end
        end
        if customMod then break end
    end

    printf("[DBTEST] testMods=[%s] unseededMod=%s rescanMod=%s noRescanMod=%s customMod=%s",
        table.concat(testMods, ", "), tostring(unseededMod), tostring(rescanMod), tostring(noRescanMod), tostring(customMod))

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
    local function buildDefaults(md)
        local s = {}; for _, e in ipairs(keysWithDefault(md)) do s[e.k] = e.d.Default end; return s
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
        ExecModule       = Modules.ExecModule,
        SendMessage      = Comms.SendMessage,
        GetPeerHeartbeat = Comms.GetPeerHeartbeat,
        IsCharRunning    = Comms.IsCharRunning,
        ToastStates      = OptionsUI.ToastStates,
        dbChars          = OptionsUI.dbChars,
        dbFromClasses    = OptionsUI.dbFromClasses,
    }
    local function restore()
        Modules.ExecModule      = sv.ExecModule
        Comms.SendMessage       = sv.SendMessage
        Comms.GetPeerHeartbeat  = sv.GetPeerHeartbeat
        Comms.IsCharRunning     = sv.IsCharRunning
        OptionsUI.ToastStates   = sv.ToastStates
        OptionsUI.dbChars       = sv.dbChars
        OptionsUI.dbFromClasses = sv.dbFromClasses
    end

    -- the real current char/server/class -- used as the target for the "local current" rescan paths
    local meChar, meSrv, meCls = Globals.CurLoadedChar, Globals.CurServer, Globals.CurLoadedClass

    OptionsUI.ToastStates = {} -- absorb the test's toasts; restored at the end

    local sentinelChars = { "a", "b", "c", "d", "e", "f", "g", "h", "i", }
    local rec = {}

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

        -- 3) Copy cross-class
        wipe("e", CLS); wipe("f", CLS); wipe("f", CLS2)
        for _, m in ipairs(testMods) do setM("e", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:CopySettings({ lbl("e"), lbl("f"), }, 1, CLS, 2, CLS2, "All Modules")
        check("Copy cross-class: lands on target class", deepEqual(getM("e", CLS, testMods[1]), getM("f", CLS2, testMods[1])))
        check("Copy cross-class: target's other class untouched", nKeys(getM("f", CLS, testMods[1])) == 0)

        -- 4) Reset "All Modules" -> defaults
        wipe("g", CLS)
        for _, m in ipairs(testMods) do setM("g", CLS, m, buildSeed(Config.moduleDefaultSettings[m])) end
        OptionsUI:ResetSettings({ lbl("x"), lbl("g"), }, 2, CLS, "All Modules")
        for _, m in ipairs(testMods) do
            check("Reset All: " .. m .. " == defaults", deepEqual(getM("g", CLS, m), buildDefaults(Config.moduleDefaultSettings[m])))
        end

        -- 5) Reset includes Custom-typed settings
        if customMod and customKey then
            local cd = Config.moduleDefaultSettings[customMod][customKey].Default
            wipe("h", CLS)
            setM("h", CLS, customMod, buildSeed(Config.moduleDefaultSettings[customMod]))
            check("Reset(Custom) precondition: seed differs from default", not deepEqual((getM("h", CLS, customMod))[customKey], cd))
            OptionsUI:ResetSettings({ lbl("x"), lbl("h"), }, 2, CLS, customMod)
            check(string.format("Reset(Custom): %s.%s -> default", customMod, customKey), deepEqual((getM("h", CLS, customMod))[customKey], cd))
        else
            printf("[DBTEST] no Custom-typed setting with a Default found -- skipping Custom reset check.")
        end

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

        -- The rescan tests call DBManagement.RequestRescan directly (no DB writes, no Globals patching).
        -- For the "local current" path we pass the real current char/server/class so Comms.IsLocalCurrent
        -- is true without touching anything. The recorders only flag the actual ("Class","RescanLoadout")
        -- dispatch and delegate everything else to the real function -- the render loop interleaves with
        -- debug-window execution and would otherwise both trip the recorder and get nil where it expects a value.

        local function makeExecRecorder(onRescan)
            return function(self, mod, fn, ...)
                if mod == "Class" and fn == "RescanLoadout" then
                    onRescan(); return
                end
                return sv.ExecModule(self, mod, fn, ...)
            end
        end
        local function makeSendRecorder(onRescan)
            return function(peer, mod, evt, ...)
                if evt == "RescanLoadout" then
                    onRescan(peer, mod, evt); return
                end
                return sv.SendMessage(peer, mod, evt, ...)
            end
        end

        -- 7) Rescan: local current + a RequiresLoadoutChange setting -> ExecModule
        if rescanMod then
            rec.execHit = false
            Modules.ExecModule = makeExecRecorder(function() rec.execHit = true end)
            DBManagement.RequestRescan(meChar, meSrv, meCls, { rescanMod, })
            Modules.ExecModule = sv.ExecModule
            check("Rescan: local current + RequiresLoadoutChange -> ExecModule(Class, RescanLoadout)", rec.execHit)
        end

        -- 8) Rescan: networked peer running that class -> SendMessage (also exercises GetPeerName casing)
        if rescanMod then
            local expectKey = "peerk (" .. SRV:sub(1, 1):upper() .. SRV:sub(2) .. ")"
            rec.sentPeer = nil
            ---@diagnostic disable-next-line: duplicate-set-field
            Comms.GetPeerHeartbeat = function(key)
                if key == expectKey then return { Data = { Class = CLS, }, } end
                return sv.GetPeerHeartbeat(key)
            end
            Comms.SendMessage = makeSendRecorder(function(peer) rec.sentPeer = peer end)
            DBManagement.RequestRescan("peerk", SRV, CLS, { rescanMod, })
            Comms.GetPeerHeartbeat, Comms.SendMessage = sv.GetPeerHeartbeat, sv.SendMessage
            check("Rescan: running peer -> SendMessage(<normalized key>, Class, RescanLoadout)",
                rec.sentPeer == expectKey, string.format("got peer=%s (expectKey=%s)", tostring(rec.sentPeer), expectKey))
        end

        -- 9) Rescan: module has no RequiresLoadoutChange setting -> nothing fires (even when target is local current)
        if noRescanMod then
            rec.fired = false
            Modules.ExecModule = makeExecRecorder(function() rec.fired = true end)
            Comms.SendMessage = makeSendRecorder(function() rec.fired = true end)
            DBManagement.RequestRescan(meChar, meSrv, meCls, { noRescanMod, })
            Modules.ExecModule, Comms.SendMessage = sv.ExecModule, sv.SendMessage
            check("Rescan: module without RequiresLoadoutChange -> nothing fires", not rec.fired)
        end

        -- 10) Rescan: needs rescan but char isn't running anywhere -> nothing fires
        if rescanMod then
            rec.fired = false
            Modules.ExecModule = makeExecRecorder(function() rec.fired = true end)
            Comms.SendMessage = makeSendRecorder(function() rec.fired = true end)
            DBManagement.RequestRescan("notrunning", SRV, CLS, { rescanMod, })
            Modules.ExecModule, Comms.SendMessage = sv.ExecModule, sv.SendMessage
            check("Rescan: needs rescan but char not running -> nothing fires", not rec.fired)
        end
    end)

    -- Cleanup sentinel rows + characters (best effort)
    for _, c in ipairs(sentinelChars) do
        pcall(function()
            wipe(c, CLS); wipe(c, CLS2)
        end)
        pcall(function() Config.Db:deleteCharacter(SRV, c) end)
    end

    restore()
    if not ranOk then printf("\ar[DBTEST] ABORTED with error: %s\ax", tostring(runErr)) end
    printf("\ay==== DB Management Test complete: PASS %d  FAIL %d ====\ax", pass, fail)
    return fail == 0 and ranOk
end

return M
