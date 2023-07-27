Class IC_BrivGemFarm_LevelUp_ToolTip
{
    ; Show tooltips on mouseover
    AddToolTips()
    {
        GUIFunctions.AddToolTip("LoadFormationText", "Show current Q/W/E game formation.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_ShowSpoilers", "Show unreleased champions in their respective seat.")
        GUIFunctions.AddToolTip("DefaultMinLevelText", "Default min level for champions with no default values.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinRadio0", "Don't initially put the champion on the field.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinRadio1", "Put the champion on the field at level 1.")
        GUIFunctions.AddToolTip("DefaultMaxLevelText", "Default max level for champions with no default values.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxRadio1", "Put the champion on the field and don't level them.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxRadioLast", "Level up the champion until soft cap.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_ForceBrivShandie", "Level up Briv and Shandie before other champions after resetting.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_SkipMinDashWait", "Skip waiting for Shandie's dash being active after leveling champions to MinLevel. Useful if stacking really early in the run.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxSimultaneousInputs", "Maximum number of champions being leveled during the intial leveling to minLevel.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxSimultaneousInputsText", "Maximum number of champions being leveled during the intial leveling to minLevel.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinLevelTimeout", "Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinLevelTimeoutText", "Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.")
        GUIFunctions.AddToolTip("Combo_BrivGemFarmLevelUpBrivMinLevelStacking", "Minimum Briv level to reach before stacking. After stacking is done, leveling will resume up to MaxLevel")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelStackingText", "Minimum Briv level to reach before stacking. After stacking is done, leveling will resume up to MaxLevel")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelArea", "Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation).")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelAreaText", "Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation).")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_LevelToSoftCapFailedConversion", "Level up champions to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_LevelToSoftCapFailedConversionBriv", "Level up Briv to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.")
        GUIFunctions.AddToolTip("MinLevelText", "Minimum level for every champion in the formation before progressing/waiting for Shandie's Dash.")
        GUIFunctions.AddToolTip("MaxLevelText", "Maximum level for every champion in the formation before leveling stops.")
    }

    UpdateDefsCNETime(unixTime)
    {
        now := A_Now
        EnvSub, now, A_NowUTC, s
        EnvAdd, unixTime, now
        localTime := IC_BrivGemFarm_LevelUp_Functions.UnixToUTC(unixTime)
        FormatTime, timeStr, % localTime
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_DefinitionsStatus", "Last server update: " . timeStr)
    }
}