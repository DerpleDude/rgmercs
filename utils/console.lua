local Console   = { _version = '1.0', _name = "Console", _author = 'Derple', }
Console.__index = Console
Console.Console = {}

function Console:New(name, opacity, maxBufferLines, autoScroll)
    if self.Console[name] == nil then
        self.Console[name] = ImGui.ConsoleWidget.new(name)
        self.Console[name].opacity = opacity or 1.0
        self.Console[name].maxBufferLines = maxBufferLines or 100
        self.Console[name].autoScroll = autoScroll == nil and true or autoScroll
    end

    return self.Console[name]
end

--- This function calculates the factorial of a given number.
--- @param name string: The name of the console to get.
--- @param opacity? number: The opacity of the console.
--- @return any: The console object
function Console:GetConsole(name, opacity)
    if self.Console[name] == nil then
        self:New(name, opacity, 100, true)
    end

    if opacity and self.Console[name].opacity then
        self.Console[name].opacity = opacity
    end

    return self.Console[name]
end

return Console
