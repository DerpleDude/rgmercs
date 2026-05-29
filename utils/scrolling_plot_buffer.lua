---@diagnostic disable: duplicate-doc-field
-- Global
---@class ScrollingPlotBuffer
---@field MaxSize number
---@field Offset number
---@field DataX number[]
---@field DataY number[]

local ScrollingPlotBuffer = {}

---@param max_size? number
---@return ScrollingPlotBuffer
function ScrollingPlotBuffer:new(max_size)
    max_size = max_size or 2000
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject.MaxSize = max_size
    newObject.Offset = 1
    newObject.DataX = {}
    newObject.DataY = {}
    return newObject
end

---@param x number
---@param y number
function ScrollingPlotBuffer:AddPoint(x, y)
    if #self.DataX < self.MaxSize then
        table.insert(self.DataX, x)
        table.insert(self.DataY, y)
    else
        self.DataX[self.Offset] = x
        self.DataY[self.Offset] = y
        self.Offset = self.Offset + 1
        if self.Offset > self.MaxSize then
            self.Offset = 1
        end
    end
end

function ScrollingPlotBuffer:Erase()
    self.DataX = {}
    self.DataY = {}
end

return ScrollingPlotBuffer
