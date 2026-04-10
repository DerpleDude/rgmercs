local sqlite = require('lsqlite3')
local Logger = require('utils.logger')

local DB     = { _version = '1.0', _name = "DB", _author = 'Derple', }
DB.__index   = DB

local SCHEMA = [[
    PRAGMA journal_mode=WAL;
    PRAGMA foreign_keys=ON;

    CREATE TABLE IF NOT EXISTS server (
        id   INTEGER PRIMARY KEY,
        name TEXT    NOT NULL UNIQUE
    );

    CREATE TABLE IF NOT EXISTS character (
        id        INTEGER PRIMARY KEY,
        name      TEXT    NOT NULL,
        server_id INTEGER NOT NULL REFERENCES server(id) ON DELETE CASCADE,
        UNIQUE (name, server_id)
    );

    CREATE TABLE IF NOT EXISTS config_value (
        id           INTEGER PRIMARY KEY,
        character_id INTEGER NOT NULL REFERENCES character(id) ON DELETE CASCADE,
        module       TEXT    NOT NULL,
        class        TEXT    NOT NULL,
        key          TEXT    NOT NULL,
        value_type   TEXT    NOT NULL CHECK (value_type IN ('bool','number','string','lua')),
        value        TEXT,
        UNIQUE (character_id, module, class, key)
    );

    CREATE INDEX IF NOT EXISTS idx_config_lookup
        ON config_value(character_id, module, class);
]]

---@param path        string        Full path to the .db file
---@param onUpdate    function|nil  Optional callback: fn(operation, dbName, tableName, rowId)
---                                 operation is sqlite.INSERT, sqlite.UPDATE, or sqlite.DELETE
---@return any|nil  DB instance or nil on failure
function DB.new(path, onUpdate)
    local db = sqlite.open(path)
    if not db then
        Logger.log_error("\arDB: failed to open database at %s", path)
        return nil
    end

    db:busy_timeout(0)
    local self = setmetatable({ _db = db, _onUpdate = onUpdate, _writeQueue = {}, _cache = {}, _dataVersion = -1, }, DB)
    self:_exec(SCHEMA)
    self._dataVersion = self:_getDataVersion()

    if onUpdate then
        db:update_hook(function(ud, operation, dbName, tableName, rowId)
            onUpdate(operation, dbName, tableName, rowId)
        end)
    end

    return self
end

local opNames = {}
for k, v in pairs(sqlite) do
    if type(v) == "number" and (v == sqlite.INSERT or v == sqlite.UPDATE or v == sqlite.DELETE) then
        opNames[v] = k
    end
end

---@param op integer  sqlite.INSERT, sqlite.UPDATE, or sqlite.DELETE
---@return string
function DB.opName(op)
    return opNames[op] or ("UNKNOWN(" .. tostring(op) .. ")")
end

---@param onUpdate function  Callback: fn(operation, dbName, tableName, rowId)
---                          operation is sqlite.INSERT (18), sqlite.UPDATE (23), or sqlite.DELETE (9)
---@return nil
function DB:setUpdateHook(onUpdate)
    self._onUpdate = onUpdate
    -- lsqlite3 in MQ passes an extra leading userdata arg: (ud, operation, dbName, tableName, rowId)
    self._db:update_hook(function(ud, operation, dbName, tableName, rowId)
        onUpdate(operation, dbName, tableName, rowId)
    end)
end

---@return nil
function DB:close()
    if self._db then
        self._db:close()
        self._db = nil
    end
end

function DB:_exec(sql)
    local res = self._db:exec(sql)
    if res ~= sqlite.OK and res ~= sqlite.BUSY then
        Logger.log_error("\arDB exec error (%d): %s", res, self._db:errmsg())
    end
    return res == sqlite.OK
end

function DB:_prepare(sql)
    local stmt, err = self._db:prepare(sql)
    if not stmt then
        Logger.log_error("\arDB prepare error: %s\n  SQL: %s", self._db:errmsg(), sql)
    end
    return stmt
end

function DB:_step(stmt)
    local res = stmt:step()
    if res ~= sqlite.DONE and res ~= sqlite.ROW then
        if res ~= sqlite.BUSY then
            Logger.log_error("\arDB step error (%d): %s", res, self._db:errmsg())
        end
        return false
    end
    return true
end

function DB:_lastInsertRowId()
    return self._db:last_insert_rowid()
end

-- Step a statement and return all rows as an array of tables.
local function collectRows(stmt)
    local rows = {}
    for row in stmt:nrows() do
        table.insert(rows, row)
    end
    stmt:finalize()
    return rows
end

-- Detect value_type from a Lua value.
local function inferType(v)
    local t = type(v)
    if t == "boolean" then
        return "bool"
    elseif t == "number" then
        return "number"
    elseif t == "table" or t == "function" then
        return "lua"
    else
        return "string"
    end
end

-- Recursively convert a Lua value to a source-code string (table constructor,
-- function body, primitive literal) that round-trips through load("return "..s).
local function luaToString(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "function" then
        local ok, src = pcall(string.dump, v)
        if ok then
            -- store as a load()-able hex string wrapped in a loadstring call
            local hex = src:gsub(".", function(c) return string.format("%02x", c:byte()) end)
            return string.format('(load((function() local h=%q local r="" for i=1,#h,2 do r=r..string.char(tonumber(h:sub(i,i+1),16)) end return r end)()))', hex)
        end
        return "nil"
    elseif t == "table" then
        local parts = {}
        local indent = string.rep("    ", depth + 1)
        local closeIndent = string.rep("    ", depth)
        -- preserve array portion in order
        local maxN = 0
        for i, _ in ipairs(v) do maxN = i end
        for i = 1, maxN do
            table.insert(parts, indent .. luaToString(v[i], depth + 1))
        end
        -- hash portion
        for k, val in pairs(v) do
            if type(k) ~= "number" or k < 1 or k > maxN or math.floor(k) ~= k then
                local keyStr
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. luaToString(k, depth + 1) .. "]"
                end
                table.insert(parts, indent .. keyStr .. " = " .. luaToString(val, depth + 1))
            end
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. closeIndent .. "}"
    else
        printf("\arCannot serialize value of type %s, returning nil", t)
        return "nil"
    end
end

-- Serialize a Lua value to its text representation for storage.
local function serialize(v, vtype)
    if vtype == "bool" then
        return v and "true" or "false"
    elseif vtype == "number" then
        return tostring(v)
    elseif vtype == "lua" then
        return luaToString(v)
    else
        return tostring(v)
    end
end

-- Deserialize a stored text value back to a Lua value.
local function deserialize(text, vtype)
    if text == nil then return nil end
    if vtype == "bool" then
        return text == "true" or text == "1"
    elseif vtype == "number" then
        return tonumber(text)
    elseif vtype == "lua" then
        local fn, err = load("return " .. text)
        if fn then return fn() end
        Logger.log_error("\arDB: failed to deserialize lua value: %s", err)
        return nil
    else
        return text
    end
end

---@param name   string
---@return integer|nil  server id, or nil if not found
function DB:getServerId(name)
    local stmt = self:_prepare("SELECT id FROM server WHERE name=?;")
    if not stmt then return nil end
    stmt:bind(1, name)
    local rows = collectRows(stmt)
    return rows[1] and rows[1].id or nil
end

---@param name   string
---@return integer|nil  server id, or nil on failure
function DB:upsertServer(name)
    local id = self:getServerId(name)
    if id then return id end
    local stmt = self:_prepare("INSERT INTO server(name) VALUES(?);")
    if not stmt then return nil end
    stmt:bind(1, name)
    self:_step(stmt)
    stmt:finalize()
    return self:_lastInsertRowId()
end

---@param serverName string
---@param charName   string
---@return integer|nil  character id, or nil if not found
function DB:getCharacterId(serverName, charName)
    local stmt = self:_prepare([[
        SELECT c.id FROM character c
        JOIN server s ON s.id = c.server_id
        WHERE s.name=? AND c.name=?;
    ]])
    if not stmt then return nil end
    stmt:bind(1, serverName)
    stmt:bind(2, charName)
    local rows = collectRows(stmt)
    return rows[1] and rows[1].id or nil
end

---@param serverName string
---@param charName   string
---@return integer|nil  character id, or nil on failure
function DB:upsertCharacter(serverName, charName)
    local id = self:getCharacterId(serverName, charName)
    if id then return id end
    local serverId = self:upsertServer(serverName)
    if not serverId then return nil end
    local stmt = self:_prepare("INSERT INTO character(name, server_id) VALUES(?,?);")
    if not stmt then return nil end
    stmt:bind(1, charName)
    stmt:bind(2, serverId)
    self:_step(stmt)
    stmt:finalize()
    return self:_lastInsertRowId()
end

---@return table  Array of { id, name, server_name }
function DB:getCharacters()
    local stmt = self:_prepare([[
        SELECT c.id, c.name, s.name AS server_name
        FROM character c JOIN server s ON s.id = c.server_id
        ORDER BY s.name, c.name;
    ]])
    if not stmt then return {} end
    return collectRows(stmt)
end

---@param serverName string
---@param charName   string
---@param charClass  string
---@param module     string
---@param key        string
---@return any|nil  deserialized value, or nil if not found
function DB:getValue(serverName, charName, charClass, module, key)
    local moduleCache = self._cache[serverName] and self._cache[serverName][charName] and
        self._cache[serverName][charName][charClass] and self._cache[serverName][charName][charClass][module]
    local entry = moduleCache and moduleCache[key]
    if entry == nil or entry.version < self._dataVersion then
        return self:_fetchValue(serverName, charName, charClass, module, key)
    end
    return entry.value
end

---@param serverName string
---@param charName   string
---@param charClass  string
---@param module     string
---@return table  { key -> deserialized value }
function DB:getAll(serverName, charName, charClass, module)
    local moduleCache = self._cache[serverName] and self._cache[serverName][charName] and
        self._cache[serverName][charName][charClass] and self._cache[serverName][charName][charClass][module]
    -- if any entry in the module is stale, re-fetch the whole module at once
    if moduleCache then
        for _, entry in pairs(moduleCache) do
            if entry.version < self._dataVersion then
                self:_fetchModule(serverName, charName, charClass, module)
                moduleCache = self._cache[serverName][charName][charClass][module]
                break
            end
        end
    else
        self:_fetchModule(serverName, charName, charClass, module)
        moduleCache = self._cache[serverName] and self._cache[serverName][charName] and
            self._cache[serverName][charName][charClass] and self._cache[serverName][charName][charClass][module]
    end
    if not moduleCache then return {} end
    local out = {}
    for k, entry in pairs(moduleCache) do
        out[k] = entry.value
    end
    return out
end

---@param serverName string
---@param charName   string
---@param charClass  string
---@param module     string
---@param key        string
---@param value      any
---@param vtype      string|nil  Inferred if omitted
---@return boolean  true on success, false if busy (write queued for retry)
function DB:setValue(serverName, charName, charClass, module, key, value, vtype)
    self:_cacheSet(serverName, charName, charClass, module, key, value)
    local charId = self:upsertCharacter(serverName, charName)
    if not charId then return false end
    vtype = vtype or inferType(value)
    local text = serialize(value, vtype)
    local stmt = self:_prepare([[
        INSERT INTO config_value(character_id, module, class, key, value_type, value)
        VALUES(?,?,?,?,?,?)
        ON CONFLICT(character_id, module, class, key)
        DO UPDATE SET value_type=excluded.value_type, value=excluded.value;
    ]])
    if not stmt then return false end
    stmt:bind(1, charId)
    stmt:bind(2, module)
    stmt:bind(3, charClass)
    stmt:bind(4, key)
    stmt:bind(5, vtype)
    stmt:bind(6, text)
    local ok = self:_step(stmt)
    stmt:finalize()
    if not ok then self:_enqueueWrite("setValue", serverName, charName, charClass, module, key, value, vtype) end
    return ok
end

---@param serverName string
---@param charName   string
---@param charClass  string
---@param module     string
---@param settings   table  { key -> value }
---@return boolean  true on success, false if busy (write queued for retry)
function DB:setAll(serverName, charName, charClass, module, settings)
    for key, value in pairs(settings) do
        self:_cacheSet(serverName, charName, charClass, module, key, value)
    end
    local charId = self:upsertCharacter(serverName, charName)
    if not charId then return false end

    local stmt = self:_prepare([[
        INSERT INTO config_value(character_id, module, class, key, value_type, value)
        VALUES(?,?,?,?,?,?)
        ON CONFLICT(character_id, module, class, key)
        DO UPDATE SET value_type=excluded.value_type, value=excluded.value;
    ]])
    if not stmt then return false end

    if not self:_exec("BEGIN IMMEDIATE TRANSACTION;") then
        stmt:finalize()
        self:_enqueueWrite("setAll", serverName, charName, charClass, module, settings)
        return false
    end
    for key, value in pairs(settings) do
        local vtype = inferType(value)
        stmt:bind(1, charId)
        stmt:bind(2, module)
        stmt:bind(3, charClass)
        stmt:bind(4, key)
        stmt:bind(5, vtype)
        stmt:bind(6, serialize(value, vtype))
        if not self:_step(stmt) then
            stmt:finalize()
            self:_exec("ROLLBACK;")
            self:_enqueueWrite("setAll", serverName, charName, charClass, module, settings)
            return false
        end
        stmt:reset()
    end
    stmt:finalize()
    self:_exec("COMMIT;")
    return true
end

---@param serverName string
---@param charName   string
---@param charClass  string
---@param module     string
---@param key        string
---@return boolean  true on success, false if busy (write queued for retry)
function DB:deleteValue(serverName, charName, charClass, module, key)
    self:_cacheDel(serverName, charName, charClass, module, key)
    local stmt = self:_prepare([[
        DELETE FROM config_value WHERE id IN (
            SELECT cv.id FROM config_value cv
            JOIN character c ON c.id = cv.character_id
            JOIN server s ON s.id = c.server_id
            WHERE s.name=? AND c.name=? AND cv.class=?
              AND cv.module=? AND cv.key=?
        );
    ]])
    if not stmt then return false end
    stmt:bind(1, serverName)
    stmt:bind(2, charName)
    stmt:bind(3, charClass)
    stmt:bind(4, module)
    stmt:bind(5, key)
    local ok = self:_step(stmt)
    stmt:finalize()
    if not ok then self:_enqueueWrite("deleteValue", serverName, charName, charClass, module, key) end
    return ok
end

---@param serverName string
---@param charName   string
---@param charClass  string
---@param module     string
---@return boolean  true on success, false if busy (write queued for retry)
function DB:deleteModule(serverName, charName, charClass, module)
    self:_cacheDelModule(serverName, charName, charClass, module)
    local stmt = self:_prepare([[
        DELETE FROM config_value WHERE id IN (
            SELECT cv.id FROM config_value cv
            JOIN character c ON c.id = cv.character_id
            JOIN server s ON s.id = c.server_id
            WHERE s.name=? AND c.name=? AND cv.class=?
              AND cv.module=?
        );
    ]])
    if not stmt then return false end
    stmt:bind(1, serverName)
    stmt:bind(2, charName)
    stmt:bind(3, charClass)
    stmt:bind(4, module)
    local ok = self:_step(stmt)
    stmt:finalize()
    if not ok then self:_enqueueWrite("deleteModule", serverName, charName, charClass, module) end
    return ok
end

---@param serverName string
---@param charName   string
---@return boolean  true on success, false if busy (write queued for retry)
function DB:deleteCharacter(serverName, charName)
    self:_cacheDelChar(serverName, charName)
    local stmt = self:_prepare([[
        DELETE FROM character WHERE id IN (
            SELECT c.id FROM character c
            JOIN server s ON s.id = c.server_id
            WHERE s.name=? AND c.name=?
        );
    ]])
    if not stmt then return false end
    stmt:bind(1, serverName)
    stmt:bind(2, charName)
    local ok = self:_step(stmt)
    stmt:finalize()
    if not ok then self:_enqueueWrite("deleteCharacter", serverName, charName) end
    return ok
end

--- In-Memory Cache
-- Each entry: { value = v, version = N }
-- _dataVersion is refreshed each tick. On read, if entry.version < _dataVersion
-- the entry is stale and re-fetched lazily from DB. Writes stamp the current version.

function DB:_getDataVersion()
    local stmt = self:_prepare("PRAGMA data_version;")
    if not stmt then return -1 end
    local rows = collectRows(stmt)
    return rows[1] and rows[1].data_version or -1
end

function DB:_cacheSet(serverName, charName, charClass, module, key, value)
    local sv = self._cache[serverName]
    if not sv then
        sv = {}
        self._cache[serverName] = sv
    end
    local ch = sv[charName]
    if not ch then
        ch = {}
        sv[charName] = ch
    end
    local cl = ch[charClass]
    if not cl then
        cl = {}
        ch[charClass] = cl
    end
    local moduleCache = cl[module]
    if not moduleCache then
        moduleCache = {}
        cl[module] = moduleCache
    end
    moduleCache[key] = { value = value, version = self._dataVersion, }
end

function DB:_cacheDel(serverName, charName, charClass, module, key)
    local moduleCache = self._cache[serverName] and self._cache[serverName][charName] and
        self._cache[serverName][charName][charClass] and self._cache[serverName][charName][charClass][module]
    if moduleCache then moduleCache[key] = nil end
end

function DB:_cacheDelModule(serverName, charName, charClass, module)
    local cl = self._cache[serverName] and self._cache[serverName][charName] and
        self._cache[serverName][charName][charClass]
    if cl then cl[module] = nil end
end

function DB:_cacheDelChar(serverName, charName)
    local sv = self._cache[serverName]
    if sv then sv[charName] = nil end
end

function DB:_fetchValue(serverName, charName, charClass, module, key)
    local stmt = self:_prepare([[
        SELECT cv.value, cv.value_type FROM config_value cv
        JOIN character c ON c.id = cv.character_id
        JOIN server s ON s.id = c.server_id
        WHERE s.name=? AND c.name=? AND cv.class=? AND cv.module=? AND cv.key=?;
    ]])
    if not stmt then return nil end
    stmt:bind(1, serverName)
    stmt:bind(2, charName)
    stmt:bind(3, charClass)
    stmt:bind(4, module)
    stmt:bind(5, key)
    local rows = collectRows(stmt)
    if not rows[1] then return nil end
    local value = deserialize(rows[1].value, rows[1].value_type)
    self:_cacheSet(serverName, charName, charClass, module, key, value)
    return value
end

function DB:_fetchModule(serverName, charName, charClass, module)
    local stmt = self:_prepare([[
        SELECT cv.key, cv.value, cv.value_type FROM config_value cv
        JOIN character c ON c.id = cv.character_id
        JOIN server s ON s.id = c.server_id
        WHERE s.name=? AND c.name=? AND cv.class=? AND cv.module=?;
    ]])
    if not stmt then return end
    stmt:bind(1, serverName)
    stmt:bind(2, charName)
    stmt:bind(3, charClass)
    stmt:bind(4, module)
    for row in stmt:nrows() do
        self:_cacheSet(serverName, charName, charClass, module, row.key, deserialize(row.value, row.value_type))
    end
    stmt:finalize()
end

---Poll data_version. Call from your main loop tick alongside flushQueue().
---@return boolean  true if version changed (some client wrote since last tick)
function DB:checkCache()
    local v = self:_getDataVersion()
    if v ~= self._dataVersion then
        self._dataVersion = v
        return true
    end
    return false
end

---@return integer  number of writes still pending in the retry queue
function DB:pendingWrites()
    return #self._writeQueue
end

function DB:_enqueueWrite(method, ...)
    table.insert(self._writeQueue, { method = method, args = { ..., }, })
end

---Retry queued writes and check for external changes. Call this from your main loop tick.
---@return nil
function DB:flushQueue()
    self:checkCache()
    if #self._writeQueue == 0 then return end
    local remaining = {}
    for _, entry in ipairs(self._writeQueue) do
        if not self[entry.method](self, unpack(entry.args)) then
            table.insert(remaining, entry)
        end
    end
    if #remaining > 0 then
        Logger.log_debug("\ayDB: %d write(s) still pending due to lock contention, will retry next tick.", #remaining)
    end
    self._writeQueue = remaining
end

return DB
