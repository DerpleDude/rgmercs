local mq      = require('mq')
local lfs     = require("lfs")
local Logger  = require("utils.logger")

local Files   = { _version = '1.0', _name = "Files", _author = 'Derple', }
Files.__index = Files

--- Checks if a file exists at the given path.
--- @param path string: The path to the file.
--- @return boolean: True if the file exists, false otherwise.
function Files.file_exists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

--- Recursively creates every component of path, like `mkdir -p`.
---@param path string The full directory path to create.
---@return boolean|nil, string? True on success; nil + error string on failure.
function Files.make_p(path)
    local sep = package.config:sub(1, 1)

    -- normalize slashes
    path = path:gsub("[/\\]", sep)

    local drive = ""
    local start = 1

    -- Detect Windows drive letter (e.g., C:\)
    local d = path:match("^([A-Za-z]:)" .. sep)
    if d then
        drive = d
        start = #d + 2
    end

    -- Detect Unix absolute path (/...)
    if sep == "/" and path:sub(1, 1) == "/" then
        drive = "/"
        start = 2
    end

    local current = drive

    for part in path:sub(start):gmatch("[^" .. sep .. "]+") do
        if current == "" or current == "/" then
            current = current .. part
        else
            current = current .. sep .. part
        end

        local attr = lfs.attributes(current)
        if not attr then
            Logger.log_debug("Creating directory: %s", current)
            local ok, err = lfs.mkdir(current)
            if not ok then
                return nil, err
            end
        elseif attr.mode ~= "directory" then
            return nil, current .. " exists but is not a directory"
        end
    end

    return true
end

--- Creates all parent directories needed for filepath to be writable.
---@param filepath string Full path to the target file (not the directory).
---@return boolean|nil True on success; nil + error string on failure.
function Files.make_p_for_file(filepath)
    local sep = package.config:sub(1, 1)
    filepath = filepath:gsub("[/\\]", sep)

    -- strip filename
    local dir = filepath:match("^(.*" .. sep .. ")")
    if not dir then return true end

    return Files.make_p(dir)
end

--- Copies a file from one path to another.
--- @param from_path string The source file path.
--- @param to_path string The destination file path.
--- @return boolean success True if the file was copied successfully, false otherwise.
function Files.copy_file(from_path, to_path)
    if Files.file_exists(from_path) then
        local file = io.open(from_path, "r")
        if file ~= nil then
            local content = file:read("*all")
            file:close()
            Files.make_p_for_file(to_path)
            local fileNew = io.open(to_path, "w")
            if fileNew ~= nil then
                fileNew:write(content)
                fileNew:close()
                return true
            else
                Logger.log_error("\arFailed to create new file: %s", to_path)
                return false
            end
        end
    end

    return false
end

--- Deletes the file at path; logs an error and returns false on failure.
---@param path string Path to the file to delete.
---@return boolean True if deleted; false if not found or deletion failed.
function Files.delete_file(path)
    if Files.file_exists(path) then
        local success, err = os.remove(path)
        if not success then
            Logger.log_error("\arFailed to delete file: %s. Error: %s", path, err)
            return false
        end
        return true
    else
        Logger.log_error("File not found for deletion: %s", path)
        return false
    end
end

return Files
