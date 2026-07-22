# Editing an RGMercs Class Config — AI Instructions

This file is the instruction set for an AI editing a user's RGMercs class config. RGMercs is a MacroQuest-based Lua framework for EverQuest; a class config is a single Lua file defining one class's spell/AA/item/ability choices and rotation logic. Everything below is written for the AI doing the edit.

**If you are the user:** upload (or paste) this whole file to your AI together with your `<class>_class_config.lua`, then say what you want changed. That's all you need to do here.

---

## Read this first

> **Most important — never guess, and protect the user from mistakes.** Quick models tend to reply with the first plausible answer and look no deeper; don't. Verify how something works against the uploaded file, a fetched reference, or the linked docs *before* you assert it or make an edit. If you can't verify, say so plainly instead of stating it as fact. Anticipate the user's errors — wrong terminology, the wrong rotation named, a request that will misbehave — and catch them with a clarifying question or a safer suggestion. A confidently wrong edit is the worst outcome here; one clarifying question is cheap. The user is trusting you to keep them out of trouble.

1. **Your job is to edit the class config file the user uploads or pastes** — make the change they ask for, and nothing more.
2. **The uploaded file is your starting point — but fetch more if you can.** Treat the uploaded file as the source of truth for the user's config; most edits need nothing else. You don't have the rest of the RGMercs repo on hand, and you can't read the user's local disk. Only when a change actually depends on a helper or module behavior you can't see in the uploaded file, and you have web/URL-fetch access, **fetch the relevant link from the "Going further" section directly** rather than guessing — the GitHub and docs links there are public and fetchable. Only if you cannot fetch should you fall back to telling the user you need more, and either ask them to paste the relevant file or point them at the link. Either way, offer a best-effort edit.
3. **Return the COMPLETE file, with the smallest diff that does the job.** Preserve every existing section, table, key, comment, and the original ordering and formatting — change only what the request requires. Never strip unrelated sections, collapse tables, delete comments, "simplify"/reconstruct the file, or return a partial "surgical" subset — no ellipses, no `-- rest unchanged` placeholders; what you return must be directly saveable as-is, with no assembly by the user. The result must still end with `return _ClassConfig` (or the file's original final line). Deliver it as a downloadable file or a single complete code block. If your platform genuinely can't output the whole file, don't fake it with a partial one — instead give the exact edits to apply by hand (each as a clearly-located before → after block) and tell the user plainly that it's a manual patch. Then add this footer, REQUIRED on every response that changes the config:

   > **Save the result to your custom config:** `<MQ configDir>/rgmercs/class_configs/<server>/<class>_class_config.lua`
   > **Then load it in-game:** on the Class tab, select this config in the dropdown if it isn't already active; if it is, click **Reload Current Config** to re-read the file.
   > **What changed:** \<one or two sentences\>

   Fill `<server>` and `<class>` from "Footer path reference" below; for `<MQ configDir>`, tell the user to run `/echo ${MacroQuest.Path[config]}` rather than guessing an absolute path. If the message includes an auto-filled environment block (from the in-game `/rgl copy guide` command), use its resolved save path verbatim instead — it's already correct for this user.

4. **Check for the custom marker before assuming the file is editable.** Look at the `_version` line at the top of the uploaded file — a custom copy reads like `_version = "(CUSTOM) Source: 2.2 - EQ Might"`, a shipped default like `_version = "2.2 - EQ Might"`. If it starts with `(CUSTOM) Source:`, the user is editing a real custom config — proceed normally. If it does NOT, the user may be editing a shipped default. Still edit the file as requested, but add a warning line to the footer:

   > **Heads up:** The file you gave me is a shipped default, not a custom copy (no `(CUSTOM) Source:` marker). I've already applied your edit, but it needs to live as a *custom* config — defaults get overwritten on the next RGMercs update. Easiest way: in-game on the Class tab, click **Create Custom Config**. That writes the file into your MQ config folder (the correct per-server location) and adds it to the config dropdown, so you don't have to build the path by hand — then just overwrite that newly-created file with this edited result and load it. (The in-game FAQs cover the button.) No need to redo the change.

5. **Never edit files under the MQ lua folder** (e.g., paths containing `/lua/rgmercs/class_configs/`). Those are the shipped defaults and will be clobbered on update. The only safe destination is under the MQ config directory.
6. **Pick conservative edits; reuse what's already there.** Don't refactor adjacent code that wasn't asked about. Mirror existing patterns in the file instead of inventing new ones — and if the config already has a commented-out or unused implementation of what's being asked, re-enable that rather than writing something new. Match the surrounding style: 4-space indentation (never tabs), double quotes for in-game names, and a trailing comma after every table entry — including the last one.
7. **When in doubt, ask the user a clarifying question** instead of guessing. A class config can have hundreds of rotation entries — pick the right one.

---

## Scope

In scope (recipes below): swapping/adding/removing options in a set; changing memorized spells; adding, removing, reordering, disabling, or gating rotation entries (the `Cure`/`Rez`/`Mez`/`Charm` tables use the same entry shape); adding a `DefaultConfig` setting to make an ability optional; small `Helpers` functions; `PullAbilities` entries.

Out of scope — tell the user it needs a human (RGMercs Discord, linked at the bottom): reworking mode logic, themes, or command handlers, and any edit to the framework itself (modules, utils, UI).

---

## Footer path reference

Use this to fill the footer's save path: `<MQ configDir>/rgmercs/class_configs/<server>/<class>_class_config.lua`

- **`<MQ configDir>`** — don't guess an absolute path; have the user run `/echo ${MacroQuest.Path[config]}` in-game to get it.
- **`<server>`** — `Live` for Live/Test; on EMU, the server's exact name (e.g. `Project Lazarus`, `EQ Might`).
- **`<class>`** — lowercase 3-letter shortname: war, pal, shd, clr, dru, shm, nec, wiz, mag, enc, rng, bst, mnk, rog, ber, brd.

The footer's load step happens on the Class tab: selecting a config in the dropdown loads it; **Reload Current Config** re-reads the one that's already active. (Custom configs are created in-game via **Create Custom Config** — see the marker check above.)

---

## How a class config is shaped

A class config is a single Lua file that returns one big table (`_ClassConfig`). The tables inside it that you'll be editing most:

```
_version            -- "X.Y - ServerName" (gets "(CUSTOM) Source: " prepended when copied)
Modes               -- e.g., {'Tank', 'DPS'}, {'Heal', 'Hybrid'}
ItemSets            -- named groups of items; the first one you own is used
AbilitySets         -- named groups of spells/discs; the HIGHEST-level one you can use is auto-picked
AASets              -- named groups of AAs; the first one you've purchased is used
Spells              -- (some classes) gem-by-gem spell loadout
SpellList           -- (some classes) prioritized spell sets (newer style, preferred)
Rotations           -- the actual actions, grouped by rotation name
Mez/Charm/Cure/Rez  -- (some classes) dedicated action tables; same entry shape as a rotation
Helpers             -- class-private functions used inside cond logic
PullAbilities       -- abilities offered in the pull module's dropdown
DefaultConfig       -- per-character settings (HP thresholds, on/off toggles, etc.)
```

Two key relationships:

- **A set is a named list of options; RGMercs auto-picks one for you.** For spell/disc sets (`AbilitySets`) it picks the *highest-level* one you can use — list order is only for readability. For AA sets (`AASets`) and item sets (`ItemSets`) it picks the *first* one in the list you have. A rotation entry names a set and uses whatever was picked.
- **A rotation entry is one action.** It has a `name`, a `type` (`Spell`, `Disc`, `AA`, `Ability`, `Item`, `Song`, or `CustomFunc`), and optional `cond` functions that gate when it fires. What `name` may point to depends on the type — see below.

### `AbilitySets` example

```lua
['AbilitySets'] = {
    ['StandDisc'] = {
        "Stonewall Discipline",  -- best/highest-level first
        "Defensive Discipline",
        "Evasive Discipline",
    },
    ['EndRegen'] = {
        "Third Wind Discipline",
        "Second Wind",
    },
}
```

Reordering a spell/disc set does **not** change which one is used — the highest-level usable option always wins (listed highest-first only for readability). AA and item sets *do* go by list order. See "Change which option a set uses" below to change a pick.

A member may be a **spell ID in quotes** — `"43478", -- Level 102, Frozen Wind`. Use it where two spells share one name: a name resolves to the lowest-ID match, which may be the wrong level. The ID still upgrades to your highest known rank.

### `Rotations` example

```lua
['Rotations'] = {
    ['Burn'] = {
        {
            name = "Onslaught",
            type = "Disc",
            cond = function(self)
                return Casting.NoDiscActive()
            end,
        },
        {
            name = "Blade Rush",
            type = "AA",
        },
    },
}
```

Each rotation (`'Burn'`, `'Defenses'`, `'Downtime'`, etc.) is a list of actions evaluated in order. An action fires if its `cond` returns true (no `cond` = always eligible).

**What `name` refers to, by `type`:**

- `Spell` / `Song` / `Disc` — must be an `AbilitySets` key (resolved to the highest-level version you can use).
- `AA` — an `AASets` key, *or* a literal AA name (e.g. `"Divine Arbitration"`).
- `Item` — an `ItemSets` key, *or* a literal item name.
- `Ability` — a literal skill name (e.g. `"Taunt"`, `"Kick"`).
- `CustomFunc` — any label; the work happens in the entry's `custom_func`.

---

## The two spell-list styles

RGMercs has two styles for telling casters which spells to memorize. **Your config will use one or the other** (check which table is present in your file). They serve the same purpose; the new style is simpler.

### Old style — `Spells` (gem-indexed)

Each gem slot has its own list. The first entry whose `cond` passes goes in that gem.

```lua
['Spells'] = {
    {
        gem = 1,
        spells = {
            { name = "FireNuke" },
            { name = "IceNuke", cond = function() return Config:GetSetting('ElementChoice') == 2 end },
        },
    },
    {
        gem = 2,
        spells = {
            { name = "BigFireNuke" },
        },
    },
}
```

### New style — `SpellList` (priority-set)

A list of named *sets*. RGMercs picks the first whole set whose `cond` passes, then memorizes the spells in order until gem slots are full.

```lua
['SpellList'] = {
    {
        name = "Default Mode",
        -- cond = function(self) return true end,  -- optional
        spells = {
            { name = "FireNuke" },
            { name = "BigFireNuke" },
            { name = "ColdNuke" },
            { name = "WildNuke", cond = function() return Config:GetSetting('DoWildNuke') end },
        },
    },
}
```

**Spell names in both styles must be `AbilitySets` keys** (e.g. `FireNuke`, `BigFireNuke`) — they're resolved through the set to the right rank for your level. A name that isn't an `AbilitySets` key won't resolve and won't load.

---

## Common edits (recipes)

In the examples below, modules like `Casting`, `Core`, `Targeting`, `Config`, `Globals`, and `mq` are imported at the top of most configs. If you use one that *isn't* already in the file's `require` block, add it there (see Common traps).

### Change which option a set uses

How a set picks its winner depends on the set type — this matters, because reordering only works for some:

- **`AbilitySets` (spells & discs):** the **highest-level** option you can use is always chosen, regardless of list order. To force a different one, **remove** the entries you don't want — you can't promote a lower-level option by moving it up.
- **`AASets` (AAs) and `ItemSets` (items):** the **first** option in the list you have is chosen. **Reorder** to change the preference.

Spell/disc set — drop the top option so the next one down is used:
```lua
['BigFireNuke'] = {
    -- "Ancient: Strike of Chaos",  -- removed: don't want the top-level nuke
    "White Fire",
    "Strike of Solusek",
},
```

AA or item set — reorder so a different entry is preferred:
```lua
['Epic'] = {
    "Champion's Sword of Eternal Power",  -- now first choice
    "Kreljnok's Sword of Eternal Power",
},
```

To **add** a new option, insert the name as a string (mind the per-type rule above for where it lands in priority). To **remove** one, delete the line; the trailing comma stays on the new last entry.

### Change which spells get memorized — old style (`Spells`)

Edit the `spells = { ... }` list inside the relevant `gem = N` entry. The first entry whose `cond` passes wins for that gem.

```lua
{
    gem = 3,
    spells = {
        { name = "SnareDot", cond = function(self) return Config:GetSetting('DoSnare') end },
        { name = "Terror" },  -- fallback if DoSnare is off
    },
},
```

### Change which spells get memorized — new style (`SpellList`)

Add, remove, or reorder entries inside `spells = { ... }`. Higher in the list = memorized first.

```lua
['SpellList'] = {
    {
        name = "Default Mode",
        spells = {
            { name = "FireNuke" },
            { name = "ColdNuke" },                -- moved up
            { name = "BigFireNuke" },
            { name = "MagicNuke", cond = function() return Config:GetSetting('DoMagic') end },
        },
    },
},
```

**Keep the loadout and rotations in sync.** A spell is only memorized if it's in the loadout (`Spells` / `SpellList`), and only *cast* if a rotation entry references it. When you add or swap a spell, update both sides — otherwise you get a half-working edit: memorized but never cast, or referenced in a rotation but never available.

### Add a rotation entry

Add a new table inside the rotation. Match the existing style — same indent, trailing commas.

```lua
['Burn'] = {
    -- existing entries above...
    {
        name = "Reverse Time",
        type = "AA",
        cond = function(self)
            return mq.TLO.Me.PctHPs() <= 70
        end,
    },
},
```

### Remove or disable a rotation entry

Two safe options:

**(a) Delete the entry** — preferred if you know you never want it.

**(b) Disable in-game** — quicker, reversible, no file edit needed. On the Class tab, find the rotation entry in the rotation list and toggle it off. The framework remembers this per-character.

### Reorder rotation entries

Just move the entire `{ name = "...", ... },` block up or down inside its rotation. Order = priority.

### Cure, rez, mez & charm tables

Some classes carry `Mez`, `Charm`, `Cure`, and `Rez` tables. Entries are the **same shape as a rotation** (`type` + `name` + optional `cond`/`load_cond`) — add, remove, or reorder them the same way; first eligible wins. `Mez` is one flat list; the rest nest entries under fixed sub-keys, which you shouldn't rename or add to. `ModeChecks` gates whether the class runs any of it — leave it unless you're switching a whole behavior on/off.

### Add a pull ability

`PullAbilities` populates the dropdown the pull module uses to choose what to pull with. To add one, copy an existing entry and change the `id` (an ability-set name or spell/AA name), `Type`, and `AbilityRange`. The `cond` typically just confirms the ability is currently available (e.g. memorized).

```lua
{
    id = 'SpearNuke',
    Type = "Spell",
    DisplayName = function() return Core.GetResolvedActionMapItem('SpearNuke').RankName.Name() or "" end,
    AbilityName = function() return Core.GetResolvedActionMapItem('SpearNuke').RankName.Name() or "" end,
    AbilityRange = 200,
    cond = function(self)
        local resolved = Core.GetResolvedActionMapItem('SpearNuke')
        return resolved ~= nil and mq.TLO.Me.Gem(resolved.RankName.Name() or "")() ~= nil
    end,
},
```

### Gate a step on a condition

A rotation entry's `cond` decides *when* it fires. Most need only `self`, but the resolved ability and the `target` are also passed — declare them when a check uses them: `function(self, spell, target)` (name the 2nd arg to match the type: `spell`, `discSpell`, `aaName`, `itemName`). Combine checks with `and` / `or`.

```lua
-- On a setting toggle (recommended; gives you a UI checkbox)
cond = function(self) return Config:GetSetting('DoMyThing') end,

-- HP threshold
cond = function(self) return mq.TLO.Me.PctHPs() <= 60 end,

-- Only on named mobs
cond = function(self) return Globals.AutoTargetIsNamed end,

-- Only when tanking
cond = function(self) return Core.IsTanking() end,

-- Only during burn mode
cond = function(self) return Casting.BurnCheck() end,

-- Uses the target arg: only when the target is below 20% HP (e.g. a finisher)
cond = function(self, spell, target) return (target.PctHPs() or 100) <= 20 end,

-- Uses the ability arg: combine several checks
cond = function(self, discSpell)
    return Globals.AutoTargetIsNamed
        and mq.TLO.Me.PctHPs() <= 60
        and Casting.DetSpellCheck(discSpell)
end,
```

If a `cond` already exists, AND your new check onto its existing return.

**Don't gate on whether the action itself is usable.** Before firing an entry, RGMercs already checks that it's ready and that you actually have it (cooldown, gem/memorization, ownership) — so conditions like "do I have this AA?" or "is this spell ready?" are redundant. Gate only on *situational* logic (HP, mode, target type, settings). Checking a *different* ability is fine, e.g. "use this spell only if I don't have the AA version": `not Casting.CanUseAA("...")`.

**Tip — gate once, not many times.** A whole rotation can carry its own condition (in the config's `RotationOrder`), checked once per pass instead of per entry. If several entries share the same gate (say, tank discs that only matter while tanking), grouping them under one rotation with that condition is cheaper and cleaner than repeating the check on every entry. For one-off gates, a per-entry `cond` is fine.

### Make an ability optional (add a setting toggle)

To turn an always-on ability into something you can switch off in the GUI, do two things.

**1. Add the setting to `DefaultConfig`.** A simple on/off toggle just needs a boolean `Default` — the input type is inferred from it (boolean = checkbox, number = slider, string = text box):

```lua
['DoFlamingSword'] = {
    DisplayName = "Use Flaming Sword",
    Group = "Abilities",
    Header = "Damage",
    Category = "Direct",
    Tooltip = "Toggle use of Flaming Sword in combat.",
    Default = true,
},
```

`DisplayName` is the GUI label; `Group` / `Header` / `Category` just organize where it appears in the Options window. For a number setting, use a numeric `Default` and add `Min` / `Max`. If you copy an existing setting as a template, drop its `Index` or pick one that doesn't collide with others in the same Category (settings without an `Index` sort alphabetically).

**2. Gate the ability on it** in the rotation, using the setting's key:

```lua
{
    name = "Flaming Sword",
    type = "Disc",
    cond = function(self) return Config:GetSetting('DoFlamingSword') end,
},
```

After you reload, the toggle shows up in Options and controls the ability.

> If the setting instead gates a *memorized* spell (in `Spells` / `SpellList`) or a rotation's `load_cond`, also add `RequiresLoadoutChange = true,` to the setting so toggling it rebuilds your loadout. A plain live `cond` like the example above does not need it.

### Swap one ability for another based on a setting

To use B *instead of* A when a toggle is on, give the two entries mutually-exclusive `load_cond`s — A loads when the setting is off, B when it's on. Use `load_cond` (not `cond`) so only the chosen one is loaded/memorized, and mark the setting `RequiresLoadoutChange = true`.

```lua
{ name = "B", type = "Spell", load_cond = function(self) return Config:GetSetting('UseB') end },
{ name = "A", type = "Spell", load_cond = function(self) return not Config:GetSetting('UseB') end },
```

(Real example: the `dru` config swaps `VampiricBlueBand` / `BlueBand` this way.)

### Need custom logic? Put it in `Helpers`, not a local

If a `cond` needs logic that's too long to read inline, or that you reuse across several entries, add a function to the `Helpers` table rather than declaring a file-scope local (locals won't be in scope inside the config's `cond` closures). Helper functions receive `self` and can resolve abilities via `self:GetResolvedActionMapItem(name)`.

```lua
['Helpers'] = {
    NeedMyDefenses = function(self)
        if mq.TLO.Me.PctHPs() > Config:GetSetting('DefenseStart') then return false end
        return Casting.NoDiscActive()
    end,
},
```

Call it from a `cond` with `self.Helpers`:

```lua
cond = function(self)
    return self.Helpers.NeedMyDefenses(self)
end,
```

---

## The `cond` cheatsheet

Every `cond` is a Lua function RGMercs calls to decide whether the action should fire.

### Signature

```lua
cond = function(self, action, target)
    return true_or_false
end
```

- **`self`** — the class config table itself. Lets you reach class-specific helpers (`self.Helpers.SomeCheck(self)`).
- **`action`** — the resolved spell/AA/item/disc, as an MQ TLO object. Use `action.RankName()`, `action.Name()`, `action.ID()`, etc. Not all rotation types pass this — `Ability` and some `AA` entries may not.
- **`target`** — the resolved target spawn, as an MQ TLO. Use `target.ID()`, `target.PctHPs()`, `target.Distance()`, etc. Only meaningful when the rotation has a target (most combat rotations do).

All three are passed to every rotation entry `cond`; take only what you use — `function(self)` is fine. Name the second arg to match the entry type (`spell`, `discSpell`, `aaName`, `itemName`) when you need the resolved ability, and add `target` when you need the spawn.

### Most-used building blocks

These modules and globals are already available in every class config:

```lua
-- Config: read user settings the player toggled in the GUI
Config:GetSetting('SettingName')

-- Casting: spell/AA usability and timing checks
Casting.SelfBuffCheck(spell)        -- "should I cast this self-buff?"
Casting.SelfBuffAACheck(aaName)     -- same, for AA
Casting.IHaveBuff(spell)            -- am I already buffed with this?
Casting.DetSpellCheck(spell)        -- detrimental spell usability on target
Casting.CanUseAA("AA Name")         -- branch on AA ownership (e.g. cast a spell only if you DON'T have the AA)
Casting.NoDiscActive()              -- am I free to fire a disc?
Casting.BurnCheck()                 -- am I in burn mode?
Casting.OkayToBuff()                -- safe to buff right now?
Casting.AuraActiveByName(name)      -- is this aura up?

-- Core: state/mode checks
Core.IsTanking()                    -- in Tank mode?
Core.IsModeActive("Heal")           -- is a given mode active?
Core.OnEMU()                        -- on an EMU server?
Core.GetResolvedActionMapItem(name) -- look up an ability set's currently-selected member

-- Targeting: positioning and threat
Targeting.GetTargetDistance(target)
Targeting.GetAutoTargetPctHPs()
Targeting.LostAutoTargetAggro()
Targeting.IHaveAggro(pct)
Targeting.CheckForAutoTargetID()

-- Globals: shared state
Globals.AutoTargetIsNamed           -- current auto-target is a named mob

-- MQ TLOs: full EQ state
mq.TLO.Me.PctHPs()
mq.TLO.Me.PctMana()
mq.TLO.Me.PctEndurance()
mq.TLO.Me.Level()
mq.TLO.Me.Combat()
mq.TLO.Me.Buff("Buff Name")()       -- is this buff on me?
mq.TLO.Target.PctHPs()
mq.TLO.Target.Distance()
mq.TLO.Spawn("npc Vox")()           -- a specific NPC by name, nearby
```

This is only a subset. When you need something that isn't here, **first check whether RGMercs already has a helper** — the util modules (`Casting`, `Core`, `Targeting`, `Combat`) wrap a lot of common checks (buffs, stacking, AA readiness, distances, target and combat state), and a helper is almost always cleaner and safer than a raw TLO. Only if there's no helper, drop to raw `mq.TLO.*` — see the helper modules and MacroQuest docs under "Going further" below.

### Common traps

- **Don't chain methods on a TLO without guarding for nil.** `mq.TLO.Target.CleanName():lower()` will crash if there's no target. Use `(mq.TLO.Target.CleanName() or ""):lower()`.
- **`Spawn.ID()` returns 0 (not nil) when the spawn doesn't exist.** Check `> 0`, not `~= nil`.
- **Check requires before using a new module.** Common modules (`mq`, `Config`, `Core`, `Casting`, `Targeting`, `Combat`, `Globals`) are imported at the top of most configs — but not every config imports every one. If you call a module that isn't in the file's top `require` block (e.g. an `ItemManager.` call where `ItemManager` isn't required), add the matching `require` line alongside the others. Don't remove existing requires.
- **`cond` must return a boolean** — not a TLO value. `return mq.TLO.Me.PctHPs() <= 60` is fine (comparison returns bool); `return mq.TLO.Me.PctHPs()` is not (returns a number).
- **`load_cond` vs `cond` aren't interchangeable.** `load_cond` decides whether an entry is loaded at all (evaluated when the loadout is built); `cond` decides whether a loaded entry fires (evaluated at runtime). A setting that gates *loading* belongs in `load_cond` (and needs `RequiresLoadoutChange = true` on the setting); one that gates *use* belongs in `cond`. Each entry's `load_cond` is evaluated independently — every entry that passes is loaded (no first-match-wins), which is what makes mutual-exclusion swaps work.
- **Misspelled keys fail silently.** RGMercs ignores fields it doesn't recognize, so a typo'd key (`load_condtion` for `load_cond`, a mistyped `cond`, etc.) simply never applies — no error, no warning. Match field names exactly, and if you notice a suspicious or misspelled key near your edit, flag it to the user instead of assuming it's intentional.
- **Spell/AA/item names go in double quotes.** Many contain an apostrophe (e.g. `"Garrison's Superior Sundering"`), which would break a single-quoted string and fail to load.
- **Checking for a pet?** `mq.TLO.Pet` returns the string `"NO PET"` (which is truthy) when you have none, so `not mq.TLO.Pet()` won't catch it. Use `(mq.TLO.Pet.ID() or 0) == 0`.

---

## Diagnosing load errors

If the user pastes back an error after reloading, map it:

   | Error pattern                                  | Likely cause                                                 |
   |------------------------------------------------|--------------------------------------------------------------|
   | `Failed to load custom class config: ...`      | Lua syntax error — a missing comma, bracket, `end`, or quote |
   | `attempt to call a nil value (field 'X')`      | Typo in a helper/module name (e.g. `Castin.Foo`)             |
   | `attempt to index a nil value`                 | TLO chain without a nil guard                                |
   | Rotation doesn't fire as expected              | a `cond` returns false unexpectedly; suggest a `Logger.log_debug(...)` inside it to inspect |

If there's no error but the change didn't take effect, the user is likely editing a file they don't have loaded — have them confirm the Class-tab dropdown shows the "Custom: ..." entry, not a default.

---

## Going further

### Reference class configs

The configs RGMercs ships with are good study material. Default configs are provided for a handful of servers (e.g., Live, Project Lazarus, EQ Might) — but RGMercs runs on all kinds of servers, and you can build a custom config starting from any of these:

- Old-style `Spells` table: `class_configs/Project Lazarus/wiz_class_config.lua`
- New-style `SpellList` table: most `class_configs/EQ Might/` configs
- Heavy use of `Helpers` functions: any tank class (`war`, `pal`, `shd`)
- Named/auto-target distinctions: `class_configs/Project Lazarus/war_class_config.lua`

GitHub:
- All class configs: <https://github.com/DerpleDude/rgmercs/tree/main/class_configs>

### Helper modules

If you need a check that isn't in the cheatsheet above, the full helper module surface lives in:

- `utils/casting.lua` — spell/AA usability
- `utils/core.lua` — mode, state, action resolution
- `utils/targeting.lua` — distance, aggro, target categorization
- `utils/combat.lua` — combat-state helpers
- `utils/item_manager.lua` — item and bandolier utilities

Browse them on GitHub: <https://github.com/DerpleDude/rgmercs/tree/main/utils>

### MacroQuest documentation

The `mq.TLO.*` calls in your conditions come from MacroQuest, not RGMercs. When you need a TLO or datatype member the cheatsheet doesn't cover, these are the authoritative references:

- MacroQuest docs (home): <https://docs.macroquest.org/>
- Lua scripting guide: <https://docs.macroquest.org/lua/>
- Top-Level Objects (the `mq.TLO.*` roots like `Me`, `Target`, `Spawn`, `Spell`): <https://docs.macroquest.org/reference/top-level-objects/>
- Data Types (what a TLO returns and the members/methods it supports, e.g. `spawn`, `spell`, `character`): <https://docs.macroquest.org/reference/data-types/>

For exact Lua method signatures, field names, and return types — especially useful for an AI generating code, or for IDE autocomplete — the MacroQuest Lua **definitions** repo is the most precise source:

- MQ Lua definitions: <https://github.com/macroquest/mq-definitions>

### Asking a human

Your AI should be able to handle the edits in this guide. Reach for the RGMercs Discord when something is genuinely beyond a straightforward change — a config broken in a way you can't pin down, a complex rotation redesign, or behavior no one can explain. The class config maintainers hang out there and can often spot in seconds what an AI working from a single file would miss.

---

## Note for AI assistants with filesystem access

If you're an IDE-integrated or desktop AI with access to the user's machine, you can streamline the round-trip:

- Read the user's class config directly from `${MacroQuest.Path[config]}/rgmercs/class_configs/<server>/<class>_class_config.lua` and write your edits back in place.
- Skip the upload/paste-and-save round-trip — read and write the file directly.

Everything else still applies:

- The user must still run **Create Custom Config** in-game first (you should not try to replicate that — the in-game code handles server detection, backup-with-timestamp, and path creation correctly).
- The user must still load the config in-game to pick up your changes — select it in the Class-tab dropdown, or **Reload Current Config** if it's already active.
- Never write under the MQ `lua/` directory.
- Still include the footer summary at the end of your message — it's the safety net regardless of how the file got saved.
