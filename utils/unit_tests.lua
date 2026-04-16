---@diagnostic disable: duplicate-set-field
local Logger    = require("utils.logger")
local Combat    = require("utils.combat")
local Targeting = require("utils.targeting")
local Globals   = require("utils.globals")

local UnitTests = {}

local function mockSpawn(id, name, pctHp, isNamed, distance)
    local t = {
        _id        = id,
        _name      = name,
        _pctHp     = pctHp,
        _isNamed   = isNamed,
        _dist      = distance or 50,
        _isTempPet = false,
    }
    setmetatable(t, { __call = function() return true end, })
    t.ID         = function() return t._id end
    t.CleanName  = function() return t._name end
    t.Name       = function() return t._name end
    t.PctHPs     = function() return t._pctHp end
    t.Distance   = function() return t._dist end
    t.Distance3D = function() return t._dist end
    t.PctAggro   = function() return 100 end
    t.Moving     = function() return false end
    t.Animation  = function() return 0 end
    t.Dead       = function() return t._pctHp <= 0 end
    t.Aggressive = function() return true end
    t.TargetType = function() return "Auto Hater" end
    t.Surname    = function() return "" end
    return t
end

local function assertEq(label, got, expected)
    if got ~= expected then
        Logger.log_error("\arSELF TEST FAILED\ax [%s]: expected %s got %s", label, tostring(expected), tostring(got))
    else
        Logger.log_debug("\agSELF TEST PASSED\ax [%s]", label)
    end
end

function UnitTests.RunAll()
    Logger.log_info("UnitTests: Running self tests...")

    -- Patch Targeting.IsNamed to use mock's _isNamed field
    local origIsNamed = Targeting.IsNamed
    ---@diagnostic disable-next-line: undefined-field
    Targeting.IsNamed = function(spawn) return spawn and spawn._isNamed or false end

    local noHpPref    = { prefLow = false, prefHigh = false, }
    local lowHpPref   = { prefLow = true, prefHigh = false, }
    local prefNamed   = { prefNamed = true, prefTrash = false, }
    local prefTrash   = { prefNamed = false, prefTrash = true, }
    local noNamePref  = { prefNamed = false, prefTrash = false, }

    local spawnA      = mockSpawn(1, "TrashA", 80, false)
    local spawnB      = mockSpawn(2, "TrashB", 40, false)
    local spawnC      = mockSpawn(3, "Named", 60, true)

    -- UpdateBucket: prefLow picks lower hp
    do
        local bucket = { hp = 101, id = 0, }
        Combat.UpdateBucket(spawnA, bucket, true)
        assertEq("UpdateBucket prefLow: first pick", bucket.id, 1)
        Combat.UpdateBucket(spawnB, bucket, true)
        assertEq("UpdateBucket prefLow: lower wins", bucket.id, 2)
        Combat.UpdateBucket(spawnA, bucket, true)
        assertEq("UpdateBucket prefLow: higher ignored", bucket.id, 2)
    end

    -- UpdateBucket: prefHigh picks higher hp
    do
        local bucket = { hp = 0, id = 0, }
        Combat.UpdateBucket(spawnB, bucket, false)
        assertEq("UpdateBucket prefHigh: first pick", bucket.id, 2)
        Combat.UpdateBucket(spawnA, bucket, false)
        assertEq("UpdateBucket prefHigh: higher wins", bucket.id, 1)
        Combat.UpdateBucket(spawnB, bucket, false)
        assertEq("UpdateBucket prefHigh: lower ignored", bucket.id, 1)
    end

    -- PickBestSpawn: no hp pref always takes the spawn unconditionally
    do
        local bucket = { hp = 0, id = 0, }
        Combat.PickBestSpawn(noHpPref, spawnA, bucket)
        assertEq("PickBestSpawn noHpPref: takes spawn", bucket.id, 1)
        Combat.PickBestSpawn(noHpPref, spawnB, bucket)
        assertEq("PickBestSpawn noHpPref: overwrites", bucket.id, 2)
    end

    -- ProcessXTarget: no namedPref, no hpPref => immediate return of first valid spawn
    do
        local kill   = { hp = 0, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        -- radius large enough spawn is within; PctAggro=100 bypasses aggro scan
        local result = Combat.ProcessXTarget(spawnA, 100, noNamePref, noHpPref, true, kill, named, false, 0)
        assertEq("ProcessXTarget noNamePref noHpPref: immediate return", result, 1)
    end

    -- ProcessXTarget: prefLow, no name pref => kill bucket updated, no immediate return
    do
        local kill   = { hp = 101, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        local result = Combat.ProcessXTarget(spawnA, 100, noNamePref, lowHpPref, false, kill, named, false, 0)
        assertEq("ProcessXTarget lowHpPref: no immediate return", result, nil)
        assertEq("ProcessXTarget lowHpPref: kill bucket updated", kill.id, 1)
        result = Combat.ProcessXTarget(spawnB, 100, noNamePref, lowHpPref, false, kill, named, false, 0)
        assertEq("ProcessXTarget lowHpPref: lower hp wins", kill.id, 2)
    end

    -- ProcessXTarget: prefNamed, spawn is trash => skipped (kill bucket unchanged)
    do
        local kill   = { hp = 101, id = 99, }
        local named  = { hp = 101, id = 0, name = "None", }
        local result = Combat.ProcessXTarget(spawnA, 100, prefNamed, lowHpPref, false, kill, named, false, 0)
        assertEq("ProcessXTarget prefNamed+trash: skipped", kill.id, 99)
        assertEq("ProcessXTarget prefNamed+trash: no immediate", result, nil)
    end

    -- ProcessXTarget: prefNamed, spawn is named, no hpPref => immediate return
    do
        local kill   = { hp = 0, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        local result = Combat.ProcessXTarget(spawnC, 100, prefNamed, noHpPref, true, kill, named, false, 0)
        assertEq("ProcessXTarget prefNamed+named+immediate: return named", result, 3)
    end

    -- ProcessXTarget: prefNamed, spawn is named, prefLow => kill bucket updated
    do
        local kill   = { hp = 101, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        local result = Combat.ProcessXTarget(spawnC, 100, prefNamed, lowHpPref, false, kill, named, false, 0)
        assertEq("ProcessXTarget prefNamed+named+prefLow: no immediate", result, nil)
        assertEq("ProcessXTarget prefNamed+named+prefLow: kill updated", kill.id, 3)
    end

    -- ProcessXTarget: prefTrash, spawn is trash, no hpPref => immediate return
    do
        local kill   = { hp = 0, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        local result = Combat.ProcessXTarget(spawnA, 100, prefTrash, noHpPref, true, kill, named, false, 0)
        assertEq("ProcessXTarget prefTrash+trash+immediate: return trash", result, 1)
    end

    -- ProcessXTarget: prefTrash, spawn is named => goes into named fallback bucket
    do
        local kill   = { hp = 0, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        local result = Combat.ProcessXTarget(spawnC, 100, prefTrash, noHpPref, true, kill, named, false, 0)
        assertEq("ProcessXTarget prefTrash+named: no immediate", result, nil)
        assertEq("ProcessXTarget prefTrash+named: kill untouched", kill.id, 0)
        assertEq("ProcessXTarget prefTrash+named: named bucket set", named.id, 3)
        assertEq("ProcessXTarget prefTrash+named: named name set", named.name, "Named")
    end

    -- ProcessXTarget: prefTrash, named spawn, prefLow => named bucket picks lowest
    do
        local spawnD = mockSpawn(4, "Named2", 30, true)
        local kill   = { hp = 0, id = 0, }
        local named  = { hp = 101, id = 0, name = "None", }
        Combat.ProcessXTarget(spawnC, 100, prefTrash, lowHpPref, false, kill, named, false, 0)
        assertEq("ProcessXTarget prefTrash+named+prefLow: first named", named.id, 3)
        Combat.ProcessXTarget(spawnD, 100, prefTrash, lowHpPref, false, kill, named, false, 0)
        assertEq("ProcessXTarget prefTrash+named+prefLow: lower hp named wins", named.id, 4)
    end

    Targeting.IsNamed = origIsNamed

    -- ValidMAXTarget tests
    do
        local origIsTempPet = Targeting.IsTempPet
        ---@diagnostic disable-next-line: undefined-field
        Targeting.IsTempPet = function(spawn) return spawn and spawn._isTempPet or false end

        local function validSpawn(id)
            local s = mockSpawn(id, "Mob", 80, false)
            s._isTempPet = false
            return s
        end

        -- valid spawn passes all checks
        assertEq("ValidMAXTarget: valid spawn", Combat.ValidMAXTarget(validSpawn(1)), true)

        -- id == 0 rejected
        local zeroId = validSpawn(0)
        assertEq("ValidMAXTarget: id 0 rejected", Combat.ValidMAXTarget(zeroId), false)

        -- dead spawn rejected
        local dead = validSpawn(2)
        dead._pctHp = 0
        assertEq("ValidMAXTarget: dead rejected", Combat.ValidMAXTarget(dead), false)

        -- non-aggressive, non-auto-hater, not forced rejected
        local passive = validSpawn(3)
        passive.Aggressive = function() return false end
        passive.TargetType = function() return "something else" end
        assertEq("ValidMAXTarget: passive rejected", Combat.ValidMAXTarget(passive), false)

        -- non-aggressive but TargetType == "auto hater" passes
        local autoHater = validSpawn(4)
        autoHater.Aggressive = function() return false end
        autoHater.TargetType = function() return "Auto Hater" end
        assertEq("ValidMAXTarget: auto hater accepted", Combat.ValidMAXTarget(autoHater), true)

        -- non-aggressive but is the ForceTargetID passes
        local forced = validSpawn(5)
        forced.Aggressive = function() return false end
        forced.TargetType = function() return "something else" end
        Globals.ForceTargetID = 5
        assertEq("ValidMAXTarget: forced target accepted", Combat.ValidMAXTarget(forced), true)
        Globals.ForceTargetID = 0

        -- temp pet rejected
        local tempPet = validSpawn(6)
        tempPet._isTempPet = true
        assertEq("ValidMAXTarget: temp pet rejected", Combat.ValidMAXTarget(tempPet), false)

        -- in ignored list rejected
        local ignored = validSpawn(7)
        Globals.IgnoredTargetIDs:add(7)
        assertEq("ValidMAXTarget: ignored id rejected", Combat.ValidMAXTarget(ignored), false)
        Globals.IgnoredTargetIDs:remove(7)

        Targeting.IsTempPet = origIsTempPet
    end

    -- IsTempPet tests
    do
        local function petSpawn(surname)
            local s = mockSpawn(10, "Test", 80, false)
            s.Surname = function() return surname end
            return s
        end

        assertEq("IsTempPet: apostrophe s Pet", Targeting.IsTempPet(petSpawn("Derple's Pet")), true)
        assertEq("IsTempPet: backtick s Pet", Targeting.IsTempPet(petSpawn("Derple`s Pet")), true)
        assertEq("IsTempPet: Doppelganger", Targeting.IsTempPet(petSpawn("Doppelganger")), true)
        assertEq("IsTempPet: normal mob", Targeting.IsTempPet(petSpawn("Gnoll")), false)
        assertEq("IsTempPet: nil surname", Targeting.IsTempPet(petSpawn(nil)), false)
    end

    -- CheckForAggroTargetID tests
    do
        Globals.AggroTargetID = 0
        assertEq("CheckForAggroTargetID: zero returns empty", #Targeting.CheckForAggroTargetID(), 0)

        Globals.AggroTargetID = 42
        local result = Targeting.CheckForAggroTargetID()
        assertEq("CheckForAggroTargetID: set returns list", #result, 1)
        assertEq("CheckForAggroTargetID: set returns correct id", result[1], 42)
        Globals.AggroTargetID = 0
    end

    -- InSpellRange tests
    do
        local function mockSpell(myRange, aeRange)
            local s = {}
            setmetatable(s, { __call = function() return true end, })
            s.MyRange = function() return myRange end
            s.AERange = function() return aeRange end
            return s
        end

        local nearSpawn = mockSpawn(20, "Near", 80, false, 10) -- distance 10
        local farSpawn  = mockSpawn(21, "Far", 80, false, 200) -- distance 200

        -- MyRange used when > 0
        assertEq("InSpellRange: MyRange in range", Targeting.InSpellRange(mockSpell(50, 0), nearSpawn), true)
        assertEq("InSpellRange: MyRange out of range", Targeting.InSpellRange(mockSpell(50, 0), farSpawn), false)

        -- AERange used when MyRange == 0
        assertEq("InSpellRange: AERange in range", Targeting.InSpellRange(mockSpell(0, 50), nearSpawn), true)
        assertEq("InSpellRange: AERange out of range", Targeting.InSpellRange(mockSpell(0, 50), farSpawn), false)

        -- both zero => falls back to 250
        assertEq("InSpellRange: fallback 250 in range", Targeting.InSpellRange(mockSpell(0, 0), nearSpawn), true)
        assertEq("InSpellRange: fallback 250 out of range", Targeting.InSpellRange(mockSpell(0, 0), farSpawn), true) -- 200 < 250

        -- nil spell returns false
        ---@diagnostic disable-next-line: param-type-mismatch
        assertEq("InSpellRange: nil spell", Targeting.InSpellRange(nil, nearSpawn), false)
    end

    Logger.log_info("UnitTests: Self tests complete.")
end

return UnitTests
