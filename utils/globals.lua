local mq                              = require("mq")
local Set                             = require("mq.set")

-- very simple table to hold our globals that includes nothing.

local Globals                         = {}
Globals.__index                       = Globals

Globals.Logger                        = nil
Globals.Modules                       = nil

Globals.MainAssist                    = ""
Globals.ScriptDir                     = ""
Globals.AutoTargetID                  = 0
Globals.AggroTargetID                 = 0
Globals.ForceTargetID                 = 0
Globals.AutoTargetIsNamed             = false
Globals.ForceCombatID                 = 0
Globals.LastPulledID                  = 0
Globals.CurrentState                  = "None"
Globals.IgnoredTargetIDs              = Set.new({})
Globals.SubmodulesLoaded              = false
Globals.PauseMain                     = false
Globals.StopCast                      = false
Globals.BackOffFlag                   = false
Globals.InMedState                    = false
Globals.LastPetCmd                    = 0
Globals.LastFaceTime                  = 0
Globals.CurZoneId                     = mq.TLO.Zone.ID()
Globals.CurInstance                   = mq.TLO.Me.Instance()
Globals.CurLoadedChar                 = mq.TLO.Me.DisplayName()
Globals.CurLoadedClass                = mq.TLO.Me.Class.ShortName()
Globals.CurServer                     = mq.TLO.EverQuest.Server()
Globals.CurServerNormalized           = mq.TLO.EverQuest.Server():gsub(" ", "")
Globals.CastResult                    = 0
Globals.BuildType                     = mq.TLO.MacroQuest.BuildName()
Globals.Minimized                     = false
Globals.LastUsedSpell                 = "None"
Globals.CorpseConned                  = false
Globals.RezzedCorpses                 = {}
Globals.SLPeerLooting                 = false
Globals.LastBurnCheck                 = false
Globals.CurrentBuffs                  = {}
Globals.CurrentBuffCount              = 0
Globals.CurrentSongs                  = {}
Globals.CurrentBlocked                = {}
Globals.CurrentPetBuffs               = nil
Globals.CurrentPetBlocked             = nil

Globals.Constants                     = {}

Globals.Constants.SupportedEmuServers = Set.new({ "Project Lazarus", "EQ Might", })
Globals.Constants.LootModuleTypes     = { 'None', 'LootNScoot', 'SmartLoot', }
Globals.Constants.RGCasters           = Set.new({ "BRD", "BST", "CLR", "DRU", "ENC", "MAG", "NEC", "PAL", "RNG", "SHD",
    "SHM", "WIZ", })
Globals.Constants.RGMelee             = Set.new({ "BRD", "SHD", "PAL", "WAR", "ROG", "BER", "MNK", "RNG", "BST", })
Globals.Constants.RGHybrid            = Set.new({ "SHD", "PAL", "RNG", "BST", "BRD", })
Globals.Constants.RGTank              = Set.new({ "WAR", "PAL", "SHD", })
Globals.Constants.RGPetClass          = Set.new({ "BST", "NEC", "MAG", "SHM", "ENC", "SHD", })
Globals.Constants.RGNotMezzedAnims    = Set.new({ 1, 5, 6, 27, 43, 44, 45, 80, 82, 112, 134, 135, })
Globals.Constants.ModRods             = { "Modulation Shard", "Transvergence", "Modulation", "Modulating", "Azure Mind Crystal", }
Globals.Constants.ModRodUse           = { "Never", "Combat", "Anytime", }
Globals.Constants.SpellBookSlots      = 1120
Globals.Constants.CastCompleted       = Set.new({ "CAST_SUCCESS", "CAST_IMMUNE", "CAST_TAKEHOLD", "CAST_RESISTED", "CAST_RECOVER", })
Globals.Constants.GroupTargetTypes    = Set.new({ "Group v1", "Group v2", "AE PC v1", "AE PC v2", })

Globals.Constants.CastResults         = {
    ['CAST_RESULT_NONE'] = 0,
    ['CAST_SUCCESS']     = 1,
    ['CAST_BLOCKED']     = 2,
    ['CAST_IMMUNE']      = 3,
    ['CAST_FDFAIL']      = 4,
    ['CAST_COMPONENTS']  = 5,
    ['CAST_CANNOTSEE']   = 6,
    ['CAST_TAKEHOLD']    = 7,
    ['CAST_STUNNED']     = 8,
    ['CAST_STANDING']    = 9,
    ['CAST_RESISTED']    = 10,
    ['CAST_RECOVER']     = 11,
    ['CAST_PENDING']     = 12,
    ['CAST_OUTDOORS']    = 13,
    ['CAST_OUTOFRANGE']  = 14,
    ['CAST_OUTOFMANA']   = 15,
    ['CAST_NOTREADY']    = 16,
    ['CAST_NOTARGET']    = 17,
    ['CAST_INTERRUPTED'] = 18,
    ['CAST_FIZZLE']      = 19,
    ['CAST_DISTRACTED']  = 20,
    ['CAST_COLLAPSE']    = 21,
    ['CAST_OVERWRITTEN'] = 22,
}

Globals.Constants.CastResultsIdToName = {}
for k, v in pairs(Globals.Constants.CastResults) do Globals.Constants.CastResultsIdToName[v] = k end

Globals.Constants.ExpansionNameToID = {
    ['EXPANSION_LEVEL_CLASSIC'] = 0,  -- No Expansion
    ['EXPANSION_LEVEL_ROK']     = 1,  -- The Ruins of Kunark
    ['EXPANSION_LEVEL_SOV']     = 2,  -- The Scars of Velious
    ['EXPANSION_LEVEL_SOL']     = 3,  -- The Shadows of Luclin
    ['EXPANSION_LEVEL_POP']     = 4,  -- The Planes of Power
    ['EXPANSION_LEVEL_LOY']     = 5,  -- The Legacy of Ykesha
    ['EXPANSION_LEVEL_LDON']    = 6,  -- Lost Dungeons of Norrath
    ['EXPANSION_LEVEL_GOD']     = 7,  -- Gates of Discord
    ['EXPANSION_LEVEL_OOW']     = 8,  -- Omens of War
    ['EXPANSION_LEVEL_DON']     = 9,  -- Dragons of Norrath
    ['EXPANSION_LEVEL_DODH']    = 10, -- Depths of Darkhollow
    ['EXPANSION_LEVEL_POR']     = 11, -- Prophecy of Ro
    ['EXPANSION_LEVEL_TSS']     = 12, -- The Serpent's Spine
    ['EXPANSION_LEVEL_TBS']     = 13, -- The Buried Sea
    ['EXPANSION_LEVEL_SOF']     = 14, -- Secrets of Faydwer
    ['EXPANSION_LEVEL_SOD']     = 15, -- Seeds of Destruction
    ['EXPANSION_LEVEL_UF']      = 16, -- Underfoot
    ['EXPANSION_LEVEL_HOT']     = 17, -- House of Thule
    ['EXPANSION_LEVEL_VOA']     = 18, -- Veil of Alaris
    ['EXPANSION_LEVEL_ROF']     = 19, -- Rain of Fear
    ['EXPANSION_LEVEL_COTF']    = 20, -- Call of the Forsaken
    ['EXPANSION_LEVEL_TDS']     = 21, -- The Darkened Sea
    ['EXPANSION_LEVEL_TBM']     = 22, -- The Broken Mirror
    ['EXPANSION_LEVEL_EOK']     = 23, -- Empires of Kunark
    ['EXPANSION_LEVEL_ROS']     = 24, -- Ring of Scale
    ['EXPANSION_LEVEL_TBL']     = 25, -- The Burning Lands
    ['EXPANSION_LEVEL_TOV']     = 26, -- Torment of Velious
    ['EXPANSION_LEVEL_COV']     = 27, -- Claws of Veeshan
    ['EXPANSION_LEVEL_TOL']     = 28, -- Terror of Luclin
    ['EXPANSION_LEVEL_NOS']     = 29, -- Night of Shadows
    ['EXPANSION_LEVEL_LS']      = 30, -- Laurion's Song
    ['EXPANSION_LEVEL_TOB']     = 31, -- The Outer Brood
}

Globals.Constants.ExpansionIDToName = {}
for k, v in pairs(Globals.Constants.ExpansionNameToID) do Globals.Constants.ExpansionIDToName[v] = k end

Globals.Constants.LogLevels           = {
    "Errors",
    "Warnings",
    "Info",
    "Debug",
    "Verbose",
    "Super-Verbose",
}

Globals.Constants.BasicColors         = {
    Red         = ImVec4(0.8, 0.3, 0.3, 0.8),
    LightRed    = ImVec4(0.9, 0.5, 0.5, 0.8),
    Green       = ImVec4(0.3, 0.8, 0.3, 0.8),
    LightGreen  = ImVec4(0.6, 0.8, 0.4, 0.8),
    BrightGreen = ImVec4(0.2, 1.0, 0.2, 0.8),
    Blue        = ImVec4(0.3, 0.3, 0.8, 0.8),
    LightBlue   = ImVec4(0.4, 0.6, 0.8, 0.8),
    Yellow      = ImVec4(0.8, 0.8, 0.3, 0.8),
    LightYellow = ImVec4(0.9, 0.9, 0.4, 0.8),
    Purple      = ImVec4(0.8, 0.3, 0.8, 0.8),
    LightPurple = ImVec4(0.9, 0.4, 0.9, 0.8),
    Orange      = ImVec4(1.0, 0.5, 0.0, 0.8),
    LightOrange = ImVec4(1.0, 0.6, 0.2, 0.8),
    Grey        = ImVec4(0.7, 0.7, 0.7, 0.8),
    LightGrey   = ImVec4(0.9, 0.9, 0.9, 0.8),
    Cyan        = ImVec4(0.3, 0.8, 0.8, 0.8),
    Mint        = ImVec4(0.8, 1.0, 0.8, 0.8),
    Lavender    = ImVec4(0.8, 0.8, 1.0, 0.8),
    BrightWhite = ImVec4(1.0, 1.0, 1.0, 1.0),
    White       = ImVec4(0.8, 0.8, 0.8, 0.8),
    Black       = ImVec4(0.0, 0.0, 0.0, 1.0),
    NearBlack   = ImVec4(0.2, 0.2, 0.2, 0.8),
}

Globals.Constants.DefaultColors       = {
    FTHighlight             = Globals.Constants.BasicColors.Orange,
    CharmReasonColor        = Globals.Constants.BasicColors.Yellow,
    ConditionPassColor      = Globals.Constants.BasicColors.Green,
    ConditionFailColor      = Globals.Constants.BasicColors.Red,
    ConditionMidColor       = Globals.Constants.BasicColors.Yellow,
    ConditionDisabledColor  = Globals.Constants.BasicColors.Grey,
    FAQCmdQuestionColor     = Globals.Constants.BasicColors.LightOrange,
    FAQUsageAnswerColor     = Globals.Constants.BasicColors.LightBlue,
    FAQDescColor            = Globals.Constants.BasicColors.LightGreen,
    FAQLinkColor            = Globals.Constants.BasicColors.LightYellow,
    SearchHighlightColor    = Globals.Constants.BasicColors.Orange,
    AssistSpawnFarColor     = Globals.Constants.BasicColors.LightRed,
    BurnFlashColorOne       = Globals.Constants.BasicColors.Orange,
    BurnFlashColorTwo       = Globals.Constants.BasicColors.LightOrange,
    MainButtonPausedColor   = Globals.Constants.BasicColors.Red,
    MainButtonUnpausedColor = Globals.Constants.BasicColors.Green,
    MainCombatColor         = Globals.Constants.BasicColors.Red,
    MainDowntimeColor       = Globals.Constants.BasicColors.Green,
    TooltipTextColor        = Globals.Constants.BasicColors.White,
    HPHighColor             = ImVec4(0.20, 0.88, 0.30, 0.96),
    HPLowColor              = ImVec4(0.95, 0.12, 0.12, 0.96),
    ManaHighColor           = ImVec4(0.15, 0.55, 0.95, 0.96),
    ManaLowColor            = ImVec4(0.95, 0.12, 0.12, 0.96),
    TogglePulseColor        = ImVec4(1.0, 0.85, 0.2, 1.0),
}

Globals.Constants.HeadingsShort       = {
    "N",
    "NNE",
    "NE",
    "ENE",
    "E",
    "ESE",
    "SE",
    "SSE",
    "S",
    "SSW",
    "SW",
    "WSW",
    "W",
    "WNW",
    "NW",
    "NNW",

}

Globals.Constants.Headings            = {
    "North",
    "North-Northeast",
    "Northeast",
    "East-Northeast",
    "East",
    "East-Southeast",
    "Southeast",
    "South-Southeast",
    "South",
    "South-Southwest",
    "Southwest",
    "West-Southwest",
    "West",
    "West-Northwest",
    "Northwest",
    "North-Northwest",
}

Globals.Constants.Colors              = {}

Globals.Constants.ConColors           = {
    "Grey", "Green", "Light Blue", "Blue", "White", "Yellow", "Red",
}
Globals.Constants.ConColorsNameToVec4 = {}
Globals.Constants.ConColorsNameToId   = {}
for i, v in ipairs(Globals.Constants.ConColors) do Globals.Constants.ConColorsNameToId[v:upper()] = i end

Globals.Constants.SpireChoices      = { "First", "Second", "Third", "Disabled", }

Globals.Constants.LastGemRemem      = { "Do Nothing", "Mem Previous Spell", "Mem Loadout Spell", }
Globals.Constants.DebuffChoice      = { "Never", "Based on Con Color", "Always", }

Globals.Constants.ScanNamedPriority = { "Named", "No Preference", "Non-Named", }
Globals.Constants.ScanHPPriority    = { "Lowest HP%", "No Preference", "Highest HP%", }

Globals.Constants.TankMercStances   = { "aggressive", "assist", }
Globals.Constants.HealerMercStances = { "balanced", "reactive", "efficient", }
Globals.Constants.MeleeMercStances  = { "balanced", "burn", }
Globals.Constants.CasterMercStances = { "balanced", "burn", "burnae", }

Globals.Constants.HPBarStyles       = { "Multi-Color", "Con-Color", }

Globals.Constants.DeprecatedConfigs = {
    ['NEC'] = { "Alpha (Live)", },
    ['PAL'] = { "Alpha (Live)", },
}

function Globals.GetTimeSeconds()
    return mq.gettime() / 1000
end

function Globals.GetTimeMS()
    return mq.gettime()
end

function Globals.GetAlternatingColor(colorA, colorB)
    colorA = colorA or IM_COL32(200, 200, 52, 255)
    colorB = colorB or IM_COL32(200, 52, 52, 255)
    return (math.floor(Globals.GetTimeSeconds() % 2) == 1) and ImGui.GetColorU32(colorA) or ImGui.GetColorU32(colorB)
end

function Globals.SetForcedTargetId(targetId)
    if targetId == Globals.ForceTargetID then return end

    local startingId = Globals.ForceTargetID
    if targetId and targetId > 0 then
        Globals.ForceTargetID = targetId
        if Globals.Logger then Globals.Logger.log_debug("SetForcedTargetId(): Force Target set to %d", targetId) end
    else
        if Globals.Logger then Globals.Logger.log_debug("SetForcedTargetId(): Force Target cleared from %d", Globals.ForceTargetID) end
        Globals.ForceTargetID = 0
    end

    if startingId ~= Globals.ForceTargetID and Globals.Modules then
        Globals.Modules:ExecAll("OnForceTargetChange", Globals.ForceTargetID)
    end
end

return Globals
