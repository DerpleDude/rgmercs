-- do not require rgmercs specific things here so that this can be used in other scripts.

local ConfigShare   = { _version = '1.0', _name = "RG Config Share", _author = 'Derple', }
ConfigShare.__index = ConfigShare

local b             = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local base64        = {
    -- encoding
    enc = function(data)
        return ((data:gsub('.', function(x)
            local r, b = '', x:byte()
            for i = 8, 1, -1 do r = r .. (math.floor(b % 2 ^ i) - math.floor(b % 2 ^ (i - 1)) > 0 and '1' or '0') end
            return r;
        end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c = 0
            for i = 1, 6 do c = c + (x:sub(i, i) == '1' and math.ceil(2 ^ (6 - i)) or 0) end
            return b:sub(c + 1, c + 1)
        end) .. ({ '', '==', '=', })[#data % 3 + 1])
    end,

    -- decoding
    dec = function(data)
        data = string.gsub(data, '[^' .. b .. '=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r, f = '', (b:find(x) - 1)
            for i = 6, 1, -1 do r = r .. (math.floor(f % 2 ^ i) - math.floor(f % 2 ^ (i - 1)) > 0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == '1' and math.ceil(2 ^ (8 - i)) or 0) end
            return string.char(c)
        end))
    end,
}

local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then
        if type(name) ~= 'number' then name = '"' .. name .. '"' end
        tmp = tmp .. '[' .. name .. '] = '
    end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp ..
                serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

---@param config table Table to export
---@return string encodedConfig Base64 encoded string of the serialized table
function ConfigShare.ExportConfig(config)
    local encodedConfig = base64.enc('return ' .. serializeTable(config))
    return encodedConfig
end

---@param encString string String to import
---@return boolean success, table decodedTable Config Table decoded
function ConfigShare.ImportConfig(encString)
    local decodedStr = base64.dec(encString)
    local loadedFn, err = load(decodedStr)
    if not loadedFn then
        printf('\arERROR: Failed to import object [load failed]: %s!\ax', err)
        return false, {}
    end
    local success, decodedTable = pcall(loadedFn)
    if not success or not type(decodedTable) == 'table' then
        printf('\arERROR: Failed to import object! [pcall failed]: %s\ax', decodedTable or "Unknown")
        return false, {}
    end
    return true, decodedTable
end

return ConfigShare
