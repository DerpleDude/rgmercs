--- @type Mq
local mq                     = require('mq')
local Console                = require("utils.console")
local Globals                = require("utils.globals")
local Strings                = require("utils.strings")

local actions                = {}
local logDir                 = mq.TLO.MacroQuest.Path("Logs")()
local logFileOpened          = nil
local logLeaderStart         = '\ar[\ax\agRGMercs'
local logLeaderEnd           = '\ar]\ax\aw >>>'

--- @type number
local currentLogLevel        = 3
local currentToastLevel      = 3
local logToFileAlways        = false
local filters                = {}
local logTimestampsToConsole = false
local enableTracer           = true
local logFileHandle          = nil

actions.ToastStates          = {}

--- Returns the current log level threshold (1=Errors … 6=Super-Verbose).
---@return number The active log level.
function actions.get_log_level() return currentLogLevel end

--- Sets the log level threshold; messages below this level are suppressed.
---@param level number New log level (1=Errors … 6=Super-Verbose).
function actions.set_log_level(level) currentLogLevel = level end

--- Controls whether timestamps are prepended to console log output.
---@param value boolean True to include timestamps.
function actions.set_log_timestamps_to_console(value) logTimestampsToConsole = value end

--- Enables or disables the caller stack-trace appended to each log line.
---@param value boolean True to enable the debug tracer.
function actions.set_debug_tracer_enabled(value) enableTracer = value end

--- Sets the toast popup level; messages at or below this level show toasts.
---@param level number New toast level (1=Errors … 4=Info).
function actions.set_toast_level(level) currentToastLevel = level end

--- Enables or disables always-on file logging; closes the handle when disabled.
---@param logToFile boolean True to write every log line to the log file.
function actions.set_log_to_file(logToFile)
	if logToFileAlways ~= logToFile then
		logToFileAlways = logToFile
		if not logToFileAlways and logFileHandle then
			logFileHandle:close()
			logFileHandle = nil
			logFileOpened = nil
		end
	end
end

--- Sets a pipe-separated filter; only log lines matching any token are shown.
---@param filter string Pipe-separated list of substrings to match (case-insensitive).
function actions.set_log_filter(filter)
	filters = Strings.split(filter:lower(), "|")
end

--- Clears the log filter so all messages at the current level are shown.
function actions.clear_log_filter() filters = {} end

local logLevels = {
	['super_verbose'] = { level = 6, header = "\atSUPER\aw-\apVERBOSE\ax", },
	['verbose']       = { level = 5, header = "\apVERBOSE\ax", },
	['debug']         = { level = 4, header = "\amDEBUG  \ax", },
	['info']          = { level = 3, header = "\aoINFO   \ax", color = ImVec4(0.2, 0.8, 0.2, 1.0):ToImU32(), },
	['warn']          = { level = 2, header = "\ayWARN   \ax", color = ImVec4(1.0, 1.0, 0.2, 1.0):ToImU32(), },
	['warning']       = { level = 2, header = "\ayWARN   \ax", color = ImVec4(1.0, 1.0, 0.2, 1.0):ToImU32(), },
	['error']         = { level = 1, header = "\arERROR  \ax", color = ImVec4(1.0, 0.2, 0.2, 1.0):ToImU32(), },
}

local function openLogFile()
	local newFileName = string.format("RGMercs_%s.log", mq.TLO.Me.Name())
	local newFilePath = string.format("%s/%s", logDir, newFileName)

	if logFileHandle and logFileOpened ~= newFilePath then
		logFileHandle:close()
		logFileHandle = nil
		logFileOpened = nil
	end

	if not logFileHandle then
		logFileHandle = io.open(newFilePath, "a")
		logFileOpened = newFilePath
		if not logFileHandle then
			print("Could not open log file for writing.")
		end
	end
end

---@param plainOutput? boolean True to strip color codes from the trace.
function actions.getCallStack(plainOutput)
	local info = debug.getinfo(4, "Snl")

	local callerTracer = string.format(plainOutput == true and "%s::%s():%d" or " \aw(\ao%s\aw::\ao%s()\aw:\ao%d\ax\aw)",
		info and info.short_src and info.short_src:match("[^\\^/]*.lua$") or "unknown_file", info and info.name or "unknown_func", info and info.currentline or 0)

	return callerTracer
end

local function log(logLevel, output, ...)
	-- if no one wants this then bail early to avoid processing costs.
	if currentLogLevel < logLevels[logLevel].level and currentToastLevel < logLevels[logLevel].level then return end

	if (... ~= nil) then output = string.format(output, ...) end
	local plainOutput = output:gsub("\a.", "")

	if currentToastLevel >= logLevels[logLevel].level then
		table.insert(actions.ToastStates, {
			active = true,
			timer = 0,
			message = plainOutput,
			receivedTime = os.time(),
			color = logLevels[logLevel].color,
		})

		if Globals.Comms then
			table.insert(Globals.Comms.OutgoingToasts, {
				active = true,
				timer = 0,
				from = mq.TLO.Me.DisplayName(),
				message = plainOutput,
				logLevel = logLevels[logLevel].level,
				color = logLevels[logLevel].color,
			})
		end
	end

	if currentLogLevel < logLevels[logLevel].level then return end

	local callerTracer = enableTracer and actions.getCallStack() or ""

	local now = string.format("%.03f", Globals.GetTimeMS() / 1000)

	-- only log out warnings and errors
	if logLevels[logLevel].level <= 2 or logToFileAlways then
		local fileHeader = logLevels[logLevel].header:gsub("\a.", "")
		local fileTracer = callerTracer:gsub("\a.", "")

		openLogFile()
		if logFileHandle then
			logFileHandle:write(string.format("[%s:%s%s] <%s> %s\n", mq.TLO.Me.Name(), fileHeader, fileTracer, now, plainOutput))
			logFileHandle:flush() -- Ensure the output is immediately written to the file
		end
	end

	if #filters > 0 then
		local found = false
		local lowerOutput = output:lower()
		for _, logFilter in ipairs(filters) do
			if logFilter:len() > 0 and (callerTracer:find(logFilter) or lowerOutput:find(logFilter, 1, true)) then found = true end
		end

		if not found then return end
	end

	local RGMercsConsole = Console:GetConsole("##RGMercs")

	if RGMercsConsole ~= nil then
		local consoleText = string.format('[%s%s] %s', logLevels[logLevel].header, logTimestampsToConsole and " \aw<\at" .. now .. ">\aw" or "", output)
		RGMercsConsole:AppendText(consoleText)
	end

	printf('%s\aw:%s \aw<\at%s\aw>%s%s \ax%s', logLeaderStart, logLevels[logLevel].header, now, callerTracer, logLeaderEnd, output)
end


function actions.GenerateShortcuts()
	for level, _ in pairs(logLevels) do
		--- @diagnostic disable-next-line
		actions["log_" .. level:lower()] = function(output, ...)
			log(level, output, ...)
		end
	end
end

actions.GenerateShortcuts()

return actions
