local Math   = { _version = '1.0', _name = "Math", _author = 'Derple', }
Math.__index = Math

--- Calculates the distance between two points (x1, y1) and (x2, y2).
--- @param x1 number The x-coordinate of the first point.
--- @param y1 number The y-coordinate of the first point.
--- @param x2 number The x-coordinate of the second point.
--- @param y2 number The y-coordinate of the second point.
--- @return number The distance between the two points.
function Math.GetDistance(x1, y1, x2, y2)
    --return mq.TLO.Math.Distance(string.format("%d,%d:%d,%d", y1 or 0, x1 or 0, y2 or 0, x2 or 0))()
    return math.sqrt(Math.GetDistanceSquared(x1, y1, x2, y2))
end

--- Calculates the squared distance between two points (x1, y1) and (x2, y2).
--- This is useful for distance comparisons without the computational cost of a square root.
--- @param x1 number The x-coordinate of the first point.
--- @param y1 number The y-coordinate of the first point.
--- @param x2 number The x-coordinate of the second point.
--- @param y2 number The y-coordinate of the second point.
--- @return number The squared distance between the two points.
function Math.GetDistanceSquared(x1, y1, x2, y2)
    return ((x2 or 0) - (x1 or 0)) ^ 2 + ((y2 or 0) - (y1 or 0)) ^ 2
end

--- Rotates point (x, y) by angle (radians) around the origin.
---@param angle number Rotation angle in radians.
---@param x number X-coordinate of the point to rotate.
---@param y number Y-coordinate of the point to rotate.
---@return number rotX Rotated x-coordinate.
---@return number rotY Rotated y-coordinate.
function Math.Rotate(angle, x, y)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)

    return
        x * cos_a - y * sin_a,
        x * sin_a + y * cos_a
end

--- Clamps value to the inclusive range [low, high].
---@param value number The value to clamp.
---@param low number The minimum allowed value.
---@param high number The maximum allowed value.
---@return number The clamped value.
function Math.Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

--- Linearly interpolates between a and b by factor t (0=a, 1=b).
---@param a number Start value.
---@param b number End value.
---@param t number Interpolation factor, typically in [0, 1].
---@return number The interpolated value.
function Math.Lerp(a, b, t)
    return a + ((b - a) * t)
end

--- Linearly interpolates between two ImVec4 colors by factor t.
---@param c1 ImVec4 Start color.
---@param c2 ImVec4 End color.
---@param t number Interpolation factor, typically in [0, 1].
---@return ImVec4 The interpolated color.
function Math.ColorLerp(c1, c2, t)
    return ImVec4(Math.Lerp(c1.x, c2.x, t),
        Math.Lerp(c1.y, c2.y, t),
        Math.Lerp(c1.z, c2.z, t),
        Math.Lerp(c1.w, c2.w, t))
end

return Math
