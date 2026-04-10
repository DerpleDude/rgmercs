local Tables   = { _version = '1.0', _name = "Tables", _author = 'Derple', }
Tables.__index = Tables

--- Gets the size of a table.
--- @param t table The table whose size is to be determined.
--- @return number The size of the table.
function Tables.GetTableSize(t)
    local i = 0
    for _, _ in pairs(t) do i = i + 1 end
    return i
end

--- Checks if a table contains a specific value.
--- @param t table The table to search.
--- @param value any The value to search for in the table.
--- @return boolean True if the value is found in the table, false otherwise.
function Tables.TableContains(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

--- Converts an ImVec4 to a table.
--- @param vec ImVec4 The ImVec4 to convert.
--- @return table|nil The converted table with x, y, z, w keys.
function Tables.ImVec4ToTable(vec)
    if not vec then return nil end
    return { x = vec.x, y = vec.y, z = vec.z, w = vec.w, }
end

--- Converts an ImVec4 to a table.
--- @param t table The table to convert.
--- @return table|nil The converted table with x, y, z, w keys.
function Tables.TableRGBAToXYZW(t)
    if not t then return nil end
    return { x = t.r, y = t.g, z = t.b, w = t.a, }
end

--- Converts a table to an ImVec4.
--- @param t table The table to convert. Must have x, y, z, w keys.
--- @return ImVec4|nil The converted ImVec4.
function Tables.TableToImVec4(t)
    if not t then return nil end
    return ImVec4(t.x or t.r, t.y or t.g, t.z or t.b, t.w or t.a)
end

--- Converts an ImVec2 to a table.
--- @param vec ImVec2 The ImVec2 to convert.
--- @return table|nil The converted table with x, y keys.
function Tables.ImVec2ToTable(vec)
    if not vec then return nil end
    return { x = vec.x, y = vec.y, }
end

--- Converts a table to an ImVec2.
--- @param t table The table to convert. Must have x, y keys.
--- @return ImVec2 The converted ImVec2.
function Tables.TableToImVec2(t)
    if not t then return ImVec2(0, 0) end
    return ImVec2(t.x, t.y)
end

function Tables.DeepCopy(orig, copies)
    copies = copies or {} -- to handle cycles
    if type(orig) ~= "table" then
        return orig
    elseif copies[orig] then
        return copies[orig]
    end

    local copy = {}
    copies[orig] = copy
    for k, v in pairs(orig) do
        copy[Tables.DeepCopy(k, copies)] = Tables.DeepCopy(v, copies)
    end
    return setmetatable(copy, getmetatable(orig))
end

function Tables._compareValues(v1, v2)
    if type(v1) ~= type(v2) then
        printf("\arType mismatch: %s (type %s) ~= %s (type %s)", tostring(v1), type(v1), tostring(v2), type(v2))
        return false
    end
    if type(v1) == "table" then
        return Tables._compareTables(v1, v2, {})
    else
        if type(v1) == 'number' then
            if math.abs(v1 - v2) >= 1e-9 then
                printf("\arValue mismatch: %s (type %s) ~= %s (type %s)", tostring(v1), type(v1), tostring(v2), type(v2))
            end
            return math.abs(v1 - v2) < 1e-9
        end

        if v1 ~= v2 then
            printf("\arValue mismatch: %s (type %s) ~= %s (type %s)", tostring(v1), type(v1), tostring(v2), type(v2))
        end
        return v1 == v2
    end
end

function Tables._compareTables(a, b, visited)
    if visited[a] and visited[a] == b then
        return true -- already compared these tables
    end
    visited[a] = b

    for k in pairs(a) do
        if not Tables._compareValues(a[k], b[k]) then
            printf("\arTable A mismatch at key: %s", tostring(k))
            printf(Tables.TableToString(a))
            printf(Tables.TableToString(b))
            return false
        end
    end
    for k in pairs(b) do
        if not Tables._compareValues(a[k], b[k]) then
            printf("\arTable B mismatch at key: %s", tostring(k))
            printf(Tables.TableToString(a))
            printf(Tables.TableToString(b))
            return false
        end
    end
    return true
end

function Tables.AreTablesEqual(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end

    return Tables._compareTables(t1, t2, {})
end

local function dumpTable(o, depth, accLen, maxLen)
    accLen = accLen or 0
    if not depth then depth = 0 end
    if type(o) == 'table' then
        local s = '{'
        accLen = accLen + #s
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            local entry = string.rep(" ", depth) .. ' [' .. k .. '] = '
            local valueStr = dumpTable(v, depth + 1, accLen + #entry, maxLen)
            entry = entry .. valueStr .. ', '
            s = s .. entry
            accLen = accLen + #entry
            if accLen >= maxLen then
                return s .. '...}'
            end
        end
        return s .. string.rep(" ", depth) .. '}'
    else
        local str = tostring(o)
        accLen = accLen + #str
        if accLen >= maxLen then
            return str:sub(1, maxLen - (accLen - #str)) .. '...'
        end
        return str
    end
end

--- Converts a table value to its string representation.
--- @param t table: The boolean value to convert.
--- @param maxLen number?: The maximum length of the resulting string. Defaults to 60 if not provided.
--- @return string: "true" if the boolean is true, "false" otherwise.
function Tables.TableToString(t, maxLen)
    if maxLen == nil then
        maxLen = 60
    end

    if type(t) ~= "table" then
        return "{}"
    end

    return dumpTable(t, 0, 0, maxLen)
end

return Tables
