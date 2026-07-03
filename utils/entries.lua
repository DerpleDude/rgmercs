local mq      = require('mq')
local Casting = require("utils.casting")
local Modules = require("utils.modules")

-- Shared Entry helpers for the config-driven ability lists (Mez / Charm / Rez); the caller pre-resolves
-- entry.name through the Class ActionMap and passes resolvedName (matching the rotation engine's resolve-once pattern).

local Entries = { _version = '1.0', _name = "Entries", _author = 'Algar', }

-- resolve an entry's identifier to its MQSpell (for TargetType / cast-time / range reads); ability returns its name string
function Entries.Spell(entry, resolvedName)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then return Casting.GetAASpell(resolvedName) end
    if entryType == "item" then return Casting.GetClickySpell(resolvedName) end
    if entryType == "ability" then return entry.name end
    -- spell / song / disc: a resolved ActionMap value is the MQSpell object; a literal name (string) falls back to mq.TLO.Spell
    if type(resolvedName) ~= "string" then return resolvedName end
    return mq.TLO.Spell(entry.name)
end

-- did the entry resolve to a usable action? abilities resolve by name (string); all others need a live spell TLO
function Entries.Resolves(entry, spell)
    if (entry.type or ""):lower() == "ability" then return spell ~= nil end
    return spell ~= nil and spell() ~= nil
end

-- only spell/song are gemmed abilities we ever WAIT on; AA/item/ability run off reuse timers
function Entries.IsGemmed(entry)
    local entryType = (entry.type or ""):lower()
    return entryType == "spell" or entryType == "song"
end

-- type-dispatched readiness; skipGemTimer lets a mem-on-demand spell read ready while merely in the book (rez)
function Entries.Ready(entry, spell, resolvedName, skipGemTimer)
    local entryType = (entry.type or ""):lower()
    if entryType == "aa" then return Casting.AAReady(resolvedName) end
    if entryType == "item" then return Casting.ItemReady(resolvedName) end
    if entryType == "ability" then return Casting.AbilityReady(entry.name) end
    if entryType == "song" then return Casting.SongReady(spell, skipGemTimer) end
    if entryType == "disc" then return Casting.DiscReady(spell) end
    return Casting.SpellReady(spell, skipGemTimer)
end

-- keep only entries whose load_cond passes (reuses the Class module's scan-time evaluator)
function Entries.FilterLoaded(list)
    local out = {}
    for _, entry in ipairs(list or {}) do
        if Modules:ExecModule("Class", "LoadConditionPass", entry) then table.insert(out, entry) end
    end
    return out
end

return Entries
