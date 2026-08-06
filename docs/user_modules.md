# User Modules

User modules are Lua files you drop into your own MQ config folder. RGMercs loads them alongside its built-in modules, so they get the same lifecycle hooks, settings storage, UI tab and `/rgl` command dispatch that a shipped module does.

## Getting started

1. RGMercs creates `<MQ config dir>/rgmercs/modules` on first run and puts `hello_world.lua` in it — a working example you can enable straight away to see one running. Copy it to `mymodule.lua` in the same folder to start your own.
2. Edit `_name` in the file to something unique.
3. Open the **UserModules** tab in RGMercs and press **Refresh**.
4. Toggle **Enabled** on your module's row.

Enabled modules reload automatically the next time RGMercs starts. Modules load in the order they appear in that table, and the arrows reorder them.

`/rgl usermodule <name> <on|off>` enables or disables a module from the command line. It locates the file itself, so the tab does not have to have been opened first.

Which modules are enabled is saved per character and per class, the same as the rest of your settings, so a persona swap switches to that class's set — anything no longer enabled is unloaded and anything newly enabled is loaded.

## The identity fields

```lua
local Module = { _version = '1.0', _name = "MyModule", _author = 'YourName', }
```

`_name` is the important one. It is simultaneously the tab label, the settings database namespace, and the key used to dispatch calls to your module. Changing it after you have saved settings orphans those settings, so pick it once and leave it alone. The filename itself is free — only `_name` matters.

`_name` must be unique across every loaded module, RGMercs' own included. If two files claim the same name the first one alphabetically wins; the loser shows a red status in the UserModules tab and refuses to load until you rename it.

`_about` is optional. Supply a sentence describing what your module does and the UserModules tab draws an info icon beside its name carrying that text, which is how anyone else on your machine finds out what it is for.

## Refresh vs. reload

**Refresh** re-reads the folder and rebuilds the list: new files, deleted files, changed `_name`s, new collisions. It does not touch anything that is already running.

**Reload** is unticking and re-ticking Enabled. Because the file is read from disk every time it loads, this is how you pick up your own edits without restarting RGMercs.

One caveat: if your module `require`s a sub-file of its own, edits to that sub-file will not be picked up by a reload — Lua caches it. Restart RGMercs to pick those up.

## Lifecycle hooks

Inherit from `modules.base` and override what you need. Everything below is optional except `New`.

| Hook | When it fires |
| --- | --- |
| `New()` | Construction. Return `Base.New(self)`. |
| `Init()` | Once at load. Call `Base.Init(self)` to load your settings. |
| `GiveTime()` | Every main loop tick. Keep this cheap. |
| `Render()` | Every UI frame your tab is visible. |
| `ShouldRender()` | Gates whether your tab exists at all. |
| `OnZone()` | After a zone change. |
| `OnDeath()` | When you die. |
| `OnCombatModeChanged()` | When RGMercs switches combat mode. |
| `OnTargetChange(targetId)` | When RGMercs changes your target. |
| `OnForceTargetChange(forceTargetId)` | When the forced target changes. |
| `Shutdown()` | On unload. Release in-memory state only. |

## Where things go

- **Settings** go in `Module.DefaultConfig`, keyed by setting name. Define the table even if it is empty — a module without one will not load. Each entry carries `DisplayName`, `Tooltip`, `Default` and friends, and every entry that is not `Type = "Custom"` must also carry a `Category`, which is what the settings UI groups it under.

  Setting names are global across RGMercs, not scoped to your module. If you declare a name another module already owns, your module is refused with an error naming the owner — so prefix your setting names with something distinctive.
- **Events, binds, actors and ImGui windows** go in `Init()`, registered through `self:RegisterEvent`, `self:RegisterBind`, `self:RegisterActor` and `self:RegisterImGui`. These wrap the equivalent `mq` calls and record what you registered, so unloading your module tears all of it down automatically. Register them any other way and they will survive an unload.
- **Per-tick work** goes in `GiveTime()`.
- **Your tab's UI** goes in `Render()`, gated by `ShouldRender()`.

## Commands

Two routes, and you can use both.

A `/rgl` subcommand is the native one: populate `Module.CommandHandlers` and RGMercs dispatches to it while your module is loaded, then stops the moment it unloads. Pick a distinctive subcommand name — `/rgl` offers the command to every loaded module, and built-in commands match on prefix, so a short name can be swallowed by one of them.

A standalone slash command like `/mybind` goes through `self:RegisterBind`, which is a tracked `mq.bind`.

## Settings persistence

Disabling a module clears its settings from memory but leaves them in the database, so re-enabling restores everything the user had configured. The module also keeps its position in the list while disabled.

Deleting the file drops the module from the list on the next refresh. Its saved settings survive that, and RGMercs' existing database cleanup is the way to remove them.

## What your module can reach

Everything RGMercs' own modules use, via the usual requires: `utils.config`, `utils.globals`, `utils.targeting`, `utils.casting`, `utils.core`, `utils.comms`, `utils.logger`, `utils.modules` and the rest of `utils/`.

## Things worth knowing

Every rescan executes the top level of every file in the folder — including files you have not enabled — in order to read its `_name`. Keep top-level code to requires and table construction, and put anything with an effect in `Init()`. A bind, event or actor registered at file scope runs again on every rescan and cannot be torn down, because the loader only tracks what you register through `self:Register*`.

Loading and unloading happen on the main loop rather than while the UI is drawing, so a slow `Init()` stalls RGMercs instead of freezing the window. Avoid `mq.delay` there regardless.

`_name` is read directly off your module table, so inheriting it from Base does not count — declare your own.

Your module is not sandboxed. An error thrown from `GiveTime()` surfaces as a normal Lua error, and RGMercs does not check your module against its own version, so an RGMercs upgrade can break a module that reaches into internals.
