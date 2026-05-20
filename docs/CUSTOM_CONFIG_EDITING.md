# Customizing Your RGMercs Class Config

**RGMercs** ships with default class configs for Official servers (referred to as "Live" throughout this guide, but these also work on Test and TLPs), along with configs for emu servers we are enthusiastic about or have played on (EQ Might, Project Might, Project Lazarus).

**The default configs are designed to do well in a broad variety of situations, and we do our best to provide options that fit common modes of play... but they are just the default.** The best config for you is going to be one that you have adjusted to fit your playstyle, or the content you do.

## Getting Started: Creating a Custom Config

Players can create a custom config from the class tab (refer to the in-game FAQs in the options window if needed). This will copy the *currently loaded config* to the mq config directory, in a place that is safe from overwrite.[^1]

Once you've done that, there are two paths forward: **manual editing**, or **using an AI** to assist (or do it for you). A couple of quick notes:

- Both are entirely possible for the layman. I am not a developer, and I picked up Lua largely from playing with RGMercs... the fever just happened to transform my tinkering into something a little grander in scale.
- Both will appeal to some more than others. I'm okay with that — I'm not here to debate the benefits or drawbacks of either approach.

---

## Manual Editing

I have helped users armed with nothing more than `Notepad.exe` make edits. It is doable. I would not recommend it. Lua is a well-documented language, and MQ has a very well-documented API. Take advantage of it.

- I recommend you check out [Visual Studio Code (VSC)](https://code.visualstudio.com/). It's free. You do not have to be a super-developer-nerd-dude to use VSC. Sometimes, that doesn't even help.
- Once you have VSC, you absolutely want to use the [Lua Language Server extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) — think of it as a spell/grammar check and autocomplete rolled into one for Lua.
- You also want to be using the [mq definitions](https://github.com/macroquest/mq-definitions). These give you additional error control and information about TLOs (the data objects you use to make decisions in your code) and other relevant MQ information.
- **There is a wonderful plugin for VSC that will install both of these for you, found [HERE](https://marketplace.visualstudio.com/items?itemName=ZenithCodeForge.mq-defs).** Having both installed will greatly aid your ability to read what is in the code and edit it to your liking — the LLS will point out when you've messed up a squiggly/comma/other code thingy after a fat-fingered copy/paste, and the defs will tell you when the TLO you're trying to check doesn't actually exist.

---

## Using "AI"

This section is aimed at basic use, without paid subscriptions, using web-based solutions.[^2] To get the best results, you'll need both of the following:

### 1. The AI Customization Guide

I've written some groundrules and pointers to help you get the results you want. In the rgmercs repo (in the `docs` folder), there's a file named **`CUSTOMIZING_WITH_AI.md`**. This file contains valuable information and instructions to help an AI help you when it comes to editing a class config. It references the mq docs, the mq defs, the rgmercs github repo, and more.

***You should always feed this file to your AI solution before giving it a config to edit.*** We've done our best to distill this file so it's super-packed with information while staying as lean as we can, to keep token use down.

> **Already in-game?** You don't need to trouble yourself with finding a file, pasting it, etc. The `/rgl copy guide` command **automatically places the entire guide on your Windows clipboard!** Simply paste it into your AI chat, hit enter, and boom — done. This will also give the AI a couple of other useful pieces of information, such as directions for placing an edited config exactly where it needs to go in your mq config folder when you're finished.

### 2. The Config Itself

You'll need to hand the AI your config, too. Custom configs are found in your mq config directory:

```
<mqconfigdir>\rgmercs\class_configs\<server>\<class>_class_config.lua
```

Replace `<server>` with your server's folder[^3] and `<class>` with your class's short name (so `wiz_class_config.lua`, etc.). Copy/paste, upload, etc. — OR, yes, you guessed it:

> **You can also do that in-game!** `/rgl copy config` copies your currently loaded class config directly to the Windows clipboard. I'd make sure you paste the guide first, though.

### After Editing

Once the edits are made, make sure your file goes back into the mq config folder! The guide file should assist you by giving you the exact directory as a helpful reminder.

---

[^1]: You do not want to edit the configs in your Lua directory — the next RGMercs update will smoosh them back into the default shape. Please use custom configs.

[^2]: I'd like to point out that MacroQuest has some [integration for Claude Code](https://docs.macroquest.org/main/claude-code-integration/). I use it, and I highly recommend it. Some of my resources (such as [Squire](https://www.redguides.com/community/resources/squire-arm-thy-pet.3291/)) were written almost entirely using this integration (note: quality of output will always be linked to quality and effort of input). There are also a couple of other projects out there — I know Coldblooded has done some work on MQ and codex.

[^3]: Official servers all fall under the "Live" folder.
