; Overrides IC_BrivGemFarm_LevelUp_Class.GemFarmShouldSetFormation()
; Overrides IC_BrivGemFarm_LevelUp_Class.GemFarmResetSetup()
; Overrides IC_BrivGemFarm_LevelUp_Added_Class.BGFLU_DoPartyWaits()
class IC_RNGWaitingRoom_Class extends IC_BrivGemFarm_LevelUp_Class
{
    GemFarmShouldSetFormation()
    {
        ; Prevent Thellora from being put in the formation on z1 before stacking Ellywick
        EllywickEnabled := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ]
        if (EllywickEnabled && g_SF.Memory.ReadResetting() || g_SF.Memory.ReadResetsCount() > this.LastResetCount)
        {
            g_SharedData.RNGWR_Elly.Reset()
            g_SharedData.RNGWR_LockFormationSwitch := !g_SharedData.RNGWR_FirstRun
        }
        if (!EllywickEnabled || !g_SharedData.RNGWR_Elly.RNGWR_LockFormationSwitch)
            return True
        return False
    }

    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
        ; Allow formation switch on startup
        g_SharedData.RNGWR_LockFormationSwitch := !g_SharedData.RNGWR_FirstRun ; Allow formation switch on startup
        g_SharedData.RNGWR_Elly.Reset()
        return base.GemFarmResetSetup(formationModron, doBasePartySetup)
    }

    BGFLU_DoPartyWaits(formation)
    {
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] AND g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Ellywick.HeroID, formation))
            g_SF.RNGWR_DoEllyWait()
        if (g_SF.IsChampInFormation(139, formation))
            g_SF.DoRushWait()
    }
}

; Overrides IC_BrivGemFarm_LevelUp_SharedFunctions_Class.GetInitialFormation()
; Overrides IC_BrivSharedFunctions_Class.RestartAdventure()
; Overrides IC_BrivSharedFunctions_Class.DirectedInput()
class IC_RNGWaitingRoom_SharedFunctions_Class extends IC_SharedFunctions_Class
{
    GetInitialFormation()
    {
        formation := base.GetInitialFormation()
        ; Use extra champions if they're in the modron formation.
        heroIDs := [99,59,97,165] ; DM / Melf / Tatyana / Baldric
        modronFormation := g_SF.Memory.GetActiveModronFormation()
        for k,heroID in heroIDs
            if (g_SF.IsChampInFormation(heroID, modronFormation))
                formation.Push(heroID)
        return formation
    }

    RestartAdventure( reason := "" )
    {
            g_SharedData.RNGWR_Elly.Reset()
            g_SharedData.RNGWR_LockFormationSwitch := !g_SharedData.RNGWR_FirstRun
            base.RestartAdventure(reason)
    }

    DirectedInput(hold := 1, release := 1, values* )
    {
        ; Remove Thellora
        if (hold && g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && g_SharedData.RNGWR_LockFormationSwitch)
            values := IC_RNGWaitingRoom_Functions.RemoveThelloraKeyFromInputValues(values)
        base.DirectedInput(hold, release, values* )
    }
}

class IC_RNGWaitingRoom_SharedFunctions_Added_Class ; Added to IC_BrivSharedFunctions_Class
{
    RNGWR_DoEllyWait()
    {
        this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.EffectKey)
        if (g_SharedData.RNGWR_Elly.IsEllyWickOnTheField())
        {
            timeout := 60000
            ElapsedTime := 0
            StartTime := A_TickCount
            while(!g_SharedData.RNGWR_Elly.WaitedForEllywickThisRun && ElapsedTime < timeout)
            {
                if (!g_SharedData.RNGWR_LockFormationSwitch)
                    g_SF.LoadFormationForZ1()
                    g_SharedData.LoopString := "Elly Wait: " . ElapsedTime
                    this.BGFLU_DoClickDamageSetup(1, g_BrivGemFarm.BGFLU_GetClickDamageTargetLevel())
                    numMelee := g_SF.Memory.ReadNumAttackingMonstersReached()
                    if (numMelee >= 1 || numMelee + g_SF.Memory.ReadNumRangedAttackingMonsters() >= 15)
                        g_BrivGemFarm.BGFLU_DoPartySetupMax()
                Sleep, 30
                ElapsedTime := A_TickCount - StartTime
            }
            if (ElapsedTime >= timeout)
                g_SharedData.RNGWR_Elly.WaitedForEllywickThisRun := true
        }
        ; Unlock formation switch
        g_SharedData.RNGWR_FirstRun := false
        g_SharedData.RNGWR_LockFormationSwitch := false
    }
}

class IC_RNGWaitingRoom_IC_SharedData_Added_Class ; Added to IC_SharedData_Class
{
;    RNGWR_Status := ""
;    RNGWR_Stats := ""
;    RNGWR_Elly := ""
;    RNGWR_FirstRun := ""
;    RNGWR_LockFormationSwitch := ""

    ; Return true if the class has been updated by the addon
    RNGWR_Running()
    {
        return true
    }

    RNGWR_GemFarmEnabled()
    {
        return g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ]
    }

    RNGWR_SetStatus(text := "")
    {
        this.RNGWR_Status := text
    }

    ; Load settings after "Start Gem Farm" has been clicked.
    RNGWR_Init()
    {
        this.RNGWR_FirstRun := true
        this.RNGWR_ResetStats()
        this.RNGWR_Elly := new IC_RNGWaitingRoom_Functions.EllywickHandlerHandler
        this.RNGWR_UpdateSettingsFromFile()
        this.RNGWR_Elly.Start()
    }

    RNGWR_UpdateStats(bonusGems := 0, redraws := 0, success := true)
    {
        if (this.RNGWR_FirstRun)
            return
        this.Stats["BonusGemsSum"] += bonusGems
        this.Stats["RedrawsSum"] += redraws
        this.Stats["Runs"] += 1
        this.Stats["Success"] += success
    }

    RNGWR_GetStats()
    {
        stats := this.Stats
        return [stats.BonusGemsSum, stats.RedrawsSum, stats.Runs, stats.Success]
    }

    RNGWR_ResetStats()
    {
        stats := {}
        stats.BonusGemsSum := 0
        stats.RedrawsSum := 0
        stats.Runs := 0
        stats.Success := 0
        this.Stats := stats
    }

    ; Load settings from the GUI settings file
    RNGWR_UpdateSettingsFromFile(fileName := "")
    {
        if (fileName == "")
            fileName := IC_RNGWaitingRoom_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] := settings.EllywickGFEnabled
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemCards" ] := settings.EllywickGFGemCards
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ] := settings.EllywickGFGemMaxRedraws
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemWaitFor5Draws" ] := settings.EllywickGFGemWaitFor5Draws
        this.RNGWR_Elly.UpdateGlobalSettings()
    }
}