local Strings   = { _version = '1.0', _name = "Strings", _author = 'Derple', }
Strings.__index = Strings

--- Returns a stateful iterator that yields each substring of text
--- separated by pattern, similar to Python's str.split.
---@param text string The input string to split.
---@param pattern string The separator pattern (or plain string if plain=true).
---@param plain boolean? If true, treats pattern as a literal string.
---@return function Iterator yielding successive substrings.
function Strings.gsplit(text, pattern, plain)
    local splitStart, length = 1, #text
    return function()
        if splitStart > 0 then
            local sepStart, sepEnd = string.find(text, pattern, splitStart, plain)
            local ret
            if not sepStart then
                ret = string.sub(text, splitStart)
                splitStart = 0
            elseif sepEnd < sepStart then
                -- Empty separator!
                ret = string.sub(text, splitStart, sepStart)
                if sepStart < length then
                    splitStart = sepStart + 1
                else
                    splitStart = 0
                end
            else
                ret = sepStart > splitStart and string.sub(text, splitStart, sepStart - 1) or ''
                splitStart = sepEnd + 1
            end
            return ret
        end
    end
end

--- Splits a given text into a table of substrings based on a specified pattern.
---
---@param text string: The text to be split.
---@param pattern string: The pattern to split the text by.
---@param plain boolean?: If true, the pattern is treated as a plain string.
---@return table: A table containing the substrings.
function Strings.split(text, pattern, plain)
    local ret = {}
    if text ~= nil then
        for match in Strings.gsplit(text, pattern, plain) do
            table.insert(ret, match)
        end
    end
    return ret
end

--- Case-insensitive check whether str begins with the prefix start.
---@param str string The string to test.
---@param start string The prefix to look for.
---@return boolean True if str starts with start (case-insensitive).
function Strings.StartsWith(str, start)
    if type(str) ~= "string" or type(start) ~= "string" then
        return false
    end
    if #start == 0 then
        return true
    end

    return str:lower():sub(1, #start) == start:lower()
end

--- Formats a given time
---
---@param time number The time value to format.
---@return string The formatted time as a string.
function Strings.FormatTime(time)
    local timeTable = Strings.GetTimeAsTable(time)

    return string.format("%d:%02d:%02d:%02d", timeTable.Days, timeTable.Hours, timeTable.Mins, timeTable.Secs)
end

--- Returns the current time as a table.
---
---@param time number The time value to format.
---@return table The time as a table with days, hours, minutes, and seconds.
function Strings.GetTimeAsTable(time)
    local days = math.floor(time / 86400)
    local hours = math.floor((time % 86400) / 3600)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = math.floor((time % 60))
    return { Days = days, Hours = hours, Mins = minutes, Secs = seconds, }
end

--- Formats a given time according to the specified format string.
---
---@param time number The time value to format.
---@param formatString string? The format string to use for formatting the time.
---@return string The formatted time as a string.
function Strings.FormatTimeMS(time, formatString)
    -- Convert milliseconds to seconds6
    local milliseconds = time % 1000
    return string.format(formatString and formatString or "%-3dms", milliseconds)
end

--- Converts a boolean value to its string representation.
---@param b boolean: The boolean value to convert.
---@return string: "true" if the boolean is true, "false" otherwise.
function Strings.BoolToString(b)
    if type(b) ~= "boolean" then
        return "\ayNOT A BOOL\ax"
    end

    return b and "true" or "false"
end

--- Converts a boolean value to a color string.
--- If the boolean is true, it returns "green", otherwise "red".
---@param b boolean: The boolean value to convert.
---@return string: The color string corresponding to the boolean value.
function Strings.BoolToColorString(b)
    if type(b) ~= "boolean" then
        return "\ayNOT A BOOL\ax"
    end

    return b and "\agtrue\ax" or "\arfalse\ax"
end

--- Trims leading and trailing whitespace from a string.
--- @param s string? Input string (passes nil through).
--- @return string? Trimmed string, or nil if input was nil.
function Strings.TrimSpaces(s)
    if not s then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
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
---@param t table: The boolean value to convert.
---@param maxLen number?: The maximum length of the resulting string. Defaults to 60 if not provided.
---@return string: "true" if the boolean is true, "false" otherwise.
function Strings.TableToString(t, maxLen)
    if maxLen == nil then
        maxLen = 60
    end

    if type(t) ~= "table" then
        return "{}"
    end

    return dumpTable(t, 0, 0, maxLen)
end

-- Parses values produced by dumpTable: numbers/booleans coerced, otherwise string.
-- TableToString writes strings unquoted (via tostring) so this is best-effort.
local function coerceValue(raw)
    if raw == "" then return "" end
    local num = tonumber(raw)
    if num ~= nil then return num end
    if raw == "true" then return true end
    if raw == "false" then return false end
    if raw == "nil" then return nil end
    return raw
end

-- Parse from src starting at position pos. Returns parsed table, next pos
-- after the closing '}'. Errors via error() on malformed input.
local function parseTable(src, pos)
    local result = {}
    local autoIdx = 1

    -- skip leading '{' and whitespace
    if src:sub(pos, pos) ~= '{' then
        error(string.format("expected '{' at position %d, got '%s'", pos, src:sub(pos, pos)))
    end
    pos = pos + 1

    while true do
        -- skip whitespace
        local _, ws = src:find("^%s*", pos)
        pos = (ws or pos - 1) + 1

        local ch = src:sub(pos, pos)
        if ch == '' then
            error("unexpected end of input while parsing table")
        end
        if ch == '}' then
            return result, pos + 1
        end

        -- detect optional key: either "[" key "]" "=" value, or bare value (array-style)
        local key
        if ch == '[' then
            -- find matching ']' allowing quoted strings inside
            local keyEnd
            if src:sub(pos + 1, pos + 1) == '"' then
                -- ["..."]
                local quoteClose = src:find('"%s*%]%s*=', pos + 2)
                if not quoteClose then
                    error(string.format("malformed string key starting at position %d", pos))
                end
                key = src:sub(pos + 2, quoteClose - 1)
                keyEnd = src:find('=', quoteClose, true)
            else
                -- [n]
                local closeBracket = src:find('%]%s*=', pos + 1)
                if not closeBracket then
                    error(string.format("malformed numeric key starting at position %d", pos))
                end
                local keyRaw = src:sub(pos + 1, closeBracket - 1):gsub("^%s+", ""):gsub("%s+$", "")
                key = tonumber(keyRaw) or keyRaw
                keyEnd = src:find('=', closeBracket, true)
            end
            pos = keyEnd + 1
            -- skip whitespace after '='
            local _, ws2 = src:find("^%s*", pos)
            pos = (ws2 or pos - 1) + 1
        else
            -- positional value, no key
            key = autoIdx
            autoIdx = autoIdx + 1
        end

        -- parse value
        local valCh = src:sub(pos, pos)
        if valCh == '{' then
            local subTable, nextPos = parseTable(src, pos)
            result[key] = subTable
            pos = nextPos
        else
            -- bare value: read until ',' or '}' at this nesting level
            local valEnd = pos
            while valEnd <= #src do
                local c = src:sub(valEnd, valEnd)
                if c == ',' or c == '}' then break end
                valEnd = valEnd + 1
            end
            local raw = src:sub(pos, valEnd - 1):gsub("^%s+", ""):gsub("%s+$", "")
            -- skip truncation markers
            if raw ~= "..." and raw ~= "" then
                result[key] = coerceValue(raw)
            end
            pos = valEnd
        end

        -- skip ',' if present
        local _, ws3 = src:find("^%s*", pos)
        pos = (ws3 or pos - 1) + 1
        if src:sub(pos, pos) == ',' then
            pos = pos + 1
        end
    end
end

--- Parses a string produced by Strings.TableToString back into a table.
--- Numbers and booleans are coerced; all other unquoted values become strings.
--- Truncated tables (`...}`) parse as much as possible and stop.
--- Returns nil + error message on malformed input.
---@param s string: The serialised table string.
---@return table|nil result, string|nil err
function Strings.TableFromString(s)
    if type(s) ~= "string" then return nil, "input must be a string" end
    local trimmed = s:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" or trimmed == "{}" then return {} end
    if trimmed:sub(1, 1) ~= '{' then return nil, "input must start with '{'" end

    local ok, result = pcall(parseTable, trimmed, 1)
    ---@diagnostic disable-next-line: return-type-mismatch
    if not ok then return nil, result end
    return result
end

--- Pads a string to a specified length with a given character.
---
---@param string string The original string to be padded.
---@param len number The desired length of the resulting string.
---@param padFront boolean If true, padding is added to the front of the string; otherwise, it is added to the back.
---@param padChar string? The character to use for padding. Defaults to a space if not provided.
---@return string The padded string.
function Strings.PadString(string, len, padFront, padChar)
    if not padChar then padChar = " " end
    local cleanText = string:gsub("\a[-]?.", "")

    local paddingNeeded = len - cleanText:len()

    for _ = 1, paddingNeeded do
        if padFront then
            string = padChar .. string
        else
            string = string .. padChar
        end
    end

    return string
end

return Strings
