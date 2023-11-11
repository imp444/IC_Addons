Class IC_BrivGemFarm_LevelUp_ToolTip
{
    ; Show tooltips on mouseover
    AddToolTips()
    {
        GUIFunctions.AddToolTip("BGFLU_LoadFormationText", "Show current Q/W/E game formation.")
        GUIFunctions.AddToolTip("BGFLU_ShowSpoilers", "Show unreleased champions in their respective seat.")
        GUIFunctions.AddToolTip("BGFLU_DefaultMinLevelText", "Default min level for champions with no default values.")
        GUIFunctions.AddToolTip("BGFLU_MinRadio0", "Don't initially put the champion on the field.")
        GUIFunctions.AddToolTip("BGFLU_MinRadio1", "Put the champion on the field at level 1.")
        GUIFunctions.AddToolTip("BGFLU_DefaultMaxLevelText", "Default max level for champions with no default values.")
        GUIFunctions.AddToolTip("BGFLU_MaxRadio1", "Put the champion on the field and don't level them.")
        GUIFunctions.AddToolTip("BGFLU_MaxRadioLast", "Level up the champion until soft cap.")
        GUIFunctions.AddToolTip("BGFLU_ForceBrivShandie", "Level up Briv and Shandie before other champions after resetting.")
        GUIFunctions.AddToolTip("BGFLU_SkipMinDashWait", "Skip waiting for Shandie's dash being active after leveling champions to MinLevel. Useful if stacking really early in the run.")
        GUIFunctions.AddToolTip("BGFLU_MaxSimultaneousInputs", "Maximum number of champions being leveled during the intial leveling to minLevel.")
        GUIFunctions.AddToolTip("BGFLU_MaxSimultaneousInputsText", "Maximum number of champions being leveled during the intial leveling to minLevel.")
        GUIFunctions.AddToolTip("BGFLU_MinLevelTimeout", "Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.")
        GUIFunctions.AddToolTip("BGFLU_MinLevelTimeoutText", "Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.")
        GUIFunctions.AddToolTip("BGFLU_MinClickDamage", "Number of times to level click damage after leveling champs to MinLevel.")
        GUIFunctions.AddToolTip("BGFLU_MinClickDamageText", "Number of times to level click damage after leveling champs to MinLevel.")
        GUIFunctions.AddToolTip("BGFLU_ClickDamagePerArea", "Number of times to level click damage when moving to a new area.")
        GUIFunctions.AddToolTip("BGFLU_ClickDamagePerAreaText", "Number of times to level click damage when moving to a new area.")
        GUIFunctions.AddToolTip("BGFLU_ClickDamageSpam", "Continuously level click damage.")
        GUIFunctions.AddToolTip("BGFLU_Combo_BrivMinLevelStacking", "Minimum Briv level to reach before offline stacking. After stacking, leveling will resume up to MaxLevel.")
        GUIFunctions.AddToolTip("BGFLU_BrivMinLevelStackingText", "Minimum Briv level to reach before offline stacking. After stacking, leveling will resume up to MaxLevel.")
        GUIFunctions.AddToolTip("BGFLU_Combo_BrivMinLevelStackingOnline", "Minimum Briv level to reach before online stacking. After stacking, leveling will resume up to MaxLevel.")
        GUIFunctions.AddToolTip("BGFLU_BrivMinLevelStackingOnlineText", "Minimum Briv level to reach before online stacking. After stacking, leveling will resume up to MaxLevel.")
        GUIFunctions.AddToolTip("BGFLU_BrivMinLevelArea", "Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation).")
        GUIFunctions.AddToolTip("BGFLU_BrivMinLevelAreaText", "Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation).")
        GUIFunctions.AddToolTip("BGFLU_LevelToSoftCapFailedConversion", "Level up champions to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.")
        GUIFunctions.AddToolTip("BGFLU_LevelToSoftCapFailedConversionBriv", "Level up Briv to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.")
        GUIFunctions.AddToolTip("BGFLU_MinLevelText", "Minimum level for every champion in the formation before progressing/waiting for Shandie's Dash.")
        GUIFunctions.AddToolTip("BGFLU_MaxLevelText", "Maximum level for every champion in the formation before leveling stops.")
    }

    UpdateDefsCNETime(unixTime)
    {
        now := A_Now
        EnvSub, now, A_NowUTC, s
        EnvAdd, unixTime, now
        localTime := IC_BrivGemFarm_LevelUp_Functions.UnixToUTC(unixTime)
        FormatTime, timeStr, % localTime
        GUIFunctions.AddToolTip("BGFLU_DefinitionsStatus", "Last server update: " . timeStr)
    }
}