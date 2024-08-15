; Overrides IC_BrivGemFarm_Class.DoPartySetup()
class IC_RNGWaitingRoom_Class extends IC_BrivGemFarm_Class
{
    DoPartySetup()
    {
        g_SharedData.LoopString := "Leveling champions"
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        ; Ellywick
        waitForEllywickCards := false
        isEllywickInFormation := g_SF.IsChampInFormation( 83, formationFavorite1 )
        if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && isEllywickInFormation)
        {
            waitForEllywickCards := true
            g_SF.LevelChampByID( 83, 200, 7000, "{q}") ; level Ellywick
        }
        isShandieInFormation := g_SF.IsChampInFormation( 47, formationFavorite1 )
        g_SF.LevelChampByID( 58, 170, 7000, "{q}") ; level briv
        if (isShandieInFormation)
            g_SF.LevelChampByID( 47, 230, 7000, "{q}") ; level shandie
        isHavilarInFormation := g_SF.IsChampInFormation( 56, formationFavorite1 )
        if (isHavilarInFormation)
            g_SF.LevelChampByID( 56, 15, 7000, "{q}") ; level havi
        ; Ellywick
        if (waitForEllywickCards)
        {
            gemCardsNeeded := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemCards" ]
            percentBonus := g_BrivUserSettingsFromAddons[ "EllywickGFGemPercent" ]
            Redraws := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ]
            IC_RNGWaitingRoom_Functions.WaitForEllywickCards(gemCardsNeeded, percentBonus, Redraws)
            ; Thellora
            isThelloraInFormation := g_SF.IsChampInFormation( 139, formationFavorite1 )
            if (isThelloraInFormation)
                g_SF.LevelChampByID( 139, 1, 7000, "{q}") ; level Thellora
        }
        if (g_BrivUserSettings[ "Fkeys" ])
        {
            keyspam := g_SF.GetFormationFKeys(g_SF.Memory.GetActiveModronFormation()) ; level other formation champions
            keyspam.Push("{ClickDmg}")
            g_SF.DirectedInput(,release :=0, keyspam*) ;keysdown
        }
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (g_SF.ShouldRushWait())
            g_SF.DoRushWait()
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1, false, true )
    }

    GemFarm()
    {
        static lastResetCount := 0
        g_SharedData.TriggerStart := true
        g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName"])
        existingProcessID := g_UserSettings[ "ExeName"]
        Process, Exist, %existingProcessID%
        g_SF.PID := ErrorLevel
        Process, Priority, % g_SF.PID, High
        g_SF.Memory.OpenProcessReader()
        if (g_SF.VerifyAdventureLoaded() < 0)
            return
        g_SF.CurrentAdventure := g_SF.Memory.ReadCurrentObjID()
        g_ServerCall.UpdatePlayServer()
        g_SF.ResetServerCall()
        g_SF.PatronID := g_SF.Memory.ReadPatronID()
        this.LastStackSuccessArea := g_UserSettings [ "StackZone" ]
        this.StackFailAreasThisRunTally := {}
        g_SF.GameStartFormation := g_BrivUserSettings[ "BrivJumpBuffer" ] > 0 ? 3 : 1
        g_SaveHelper.Init() ; slow call, loads briv dictionary (3+s)
        formationModron := g_SF.Memory.GetActiveModronFormation()
        if (this.PreFlightCheck() == -1) ; Did not pass pre flight check.
            return -1
        g_PreviousZoneStartTime := A_TickCount
        g_SharedData.StackFail := 0
        g_SF.BGFLU_CalcLastUpgradeLevels()
        g_SharedData.BGFLU_UpdateSettingsFromFile(true)
        firstLoop := true
        loop
        {
            g_SharedData.LoopString := "Main Loop"
            CurrentZone := g_SF.Memory.ReadCurrentZone()
            if (CurrentZone == "" AND !g_SF.SafetyCheck() ) ; Check for game closed
                g_SF.ToggleAutoProgress( 1, false, true ) ; Turn on autoprogress after a restart
            if(firstLoop)
                firstLoop := false
            else
                g_SF.SetFormation(g_BrivUserSettings)
            if (g_SF.Memory.ReadResetting())
                this.ModronResetCheck()
            if (g_SF.Memory.ReadResetsCount() > lastResetCount OR g_SharedData.TriggerStart) ; first loop or Modron has reset
            {
                g_SF.ToggleAutoProgress( 0, false, true )
                g_SharedData.BGFLU_SetStatus()
                g_SharedData.BGFLU_SaveFormations()
                g_SharedData.SwapsMadeThisRun := 0
                g_SharedData.BossesHitThisRun := 0
                g_SharedData.StackFail := this.CheckForFailedConv()
                g_SF.WaitForFirstGold()
                setupMaxDone := false
                setupFailedConversionDone := true
                this.BGFLU_DoPartySetupMin(g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivShandie" ])
                lastResetCount := g_SF.Memory.ReadResetsCount()
                g_SF.Memory.ActiveEffectKeyHandler.Refresh()
                worstCase := g_BrivUserSettings[ "AutoCalculateWorstCase" ]
                g_SharedData.TargetStacks := this.TargetStacks := g_SF.CalculateBrivStacksToReachNextModronResetZone(worstCase) + 50 ; 50 stack safety net
                this.LeftoverStacks := g_SF.CalculateBrivStacksLeftAtTargetZone(g_SF.Memory.ReadCurrentZone(), g_SF.Memory.GetModronResetArea() + 1, worstCase)
                ; Don't reset last stack success area if 3 or more runs have failed to stack.
                this.LastStackSuccessArea := this.StackFailAreasTally[g_UserSettings [ "StackZone" ]] < this.MaxStackRestartFails ? g_UserSettings [ "StackZone" ] : this.LastStackSuccessArea
                this.StackFailAreasThisRunTally := {}
                this.StackFailRetryAttempt := 0
                StartTime := g_PreviousZoneStartTime := A_TickCount
                PreviousZone := 1
                g_SharedData.TriggerStart := false
                g_SharedData.LoopString := "Main Loop"
            }
            if (g_SharedData.StackFail != 2)
                g_SharedData.StackFail := Max(this.TestForSteelBonesStackFarming(), g_SharedData.StackFail)
            if (g_SharedData.StackFail == 2 OR g_SharedData.StackFail == 4 OR g_SharedData.StackFail == 6 ) ; OR g_SharedData.StackFail == 3
                g_SharedData.TriggerStart := true
            if (!Mod( g_SF.Memory.ReadCurrentZone(), 5 ) AND Mod( g_SF.Memory.ReadHighestZone(), 5 ) AND !g_SF.Memory.ReadTransitioning())
                g_SF.ToggleAutoProgress( 1, true ) ; Toggle autoprogress to skip boss bag
            if (g_SF.Memory.ReadResetting())
                this.ModronResetCheck()
            else
            {
                needToStack := this.BGFLU_NeedToStack()
                ; Level up Briv to MaxLevel after stacking
                if (!needToStack AND g_SF.Memory.ReadChampLvlByID(58) < g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ].maxLevels[58])
                    setupMaxDone := false
                ; Check for failed stack conversion
                if (g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversion" ] AND g_SF.Memory.ReadHasteStacks() < 50 AND needToStack)
                    setupFailedConversionDone := false
                if (!setupMaxDone)
                    setupMaxDone := this.BGFLU_DoPartySetupMax() ; Level up all champs to the specified max level
                else if (!setupFailedConversionDone)
                    setupFailedConversionDone := this.BGFLU_DoPartySetupFailedConversion() ; Level up all champs to soft cap (including Briv if option checked)
                if (g_SharedData.BGFLU_UpdateMaxLevels)
                {
                    setupMaxDone := false
                    g_SharedData.BGFLU_UpdateMaxLevels := false
                    ; Stop click spam
                    if (!g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ])
                        g_SF.BGFLU_StopSpamClickDamage()
                }
                ; Click damage
                if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
                    g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel())
            }
            if (CurrentZone > PreviousZone ) ; needs to be greater than because offline could stacking getting stuck in descending zones.
            {
                PreviousZone := CurrentZone
                if ((!Mod( g_SF.Memory.ReadCurrentZone(), 5 )) AND (!Mod( g_SF.Memory.ReadHighestZone(), 5)))
                {
                    g_SharedData.TotalBossesHit++
                    g_SharedData.BossesHitThisRun++
                }
                lastModronResetZone := g_SF.ModronResetZone
                g_SF.InitZone( ["{ClickDmg}"] )
                if (g_SF.ModronResetZone != lastModronResetZone)
                {
                    worstCase := g_BrivUserSettings[ "AutoCalculateWorstCase" ]
                    g_SharedData.TargetStacks := this.TargetStacks := g_SF.CalculateBrivStacksToReachNextModronResetZone(worstCase) + 50 ; 50 stack safety net
                    this.LeftoverStacks := g_SF.CalculateBrivStacksLeftAtTargetZone(this.Memory.ReadCurrentZone(), this.Memory.GetModronResetArea() + 1, worstCase)
                }
                g_SF.ToggleAutoProgress( 1 )
                continue
            }
            g_SF.ToggleAutoProgress( 1 )
            if (g_SF.CheckifStuck())
            {
                g_SharedData.TriggerStart := true
                g_SharedData.StackFail := StackFailStates.FAILED_TO_PROGRESS ; 3
                g_SharedData.StackFailStats.TALLY[g_SharedData.StackFail] += 1
            }
            Sleep, 20 ; here to keep the script responsive.
        }
    }
}

; Overrides IC_BrivSharedFunctions_Class.WaitForFirstGold()
class IC_RNGWaitingRoom_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    WaitForFirstGold( maxLoopTime := 30000 )
    {
        g_SharedData.LoopString := "Waiting for first gold"
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 33
        ; this.BGFLU_LoadZ1Formation()
        gold := this.ConvQuadToDouble( this.Memory.ReadGoldFirst8Bytes(), this.Memory.ReadGoldSecond8Bytes() )
        while ( gold == 0 AND ElapsedTime < maxLoopTime )
        {
            ElapsedTime := A_TickCount - StartTime
;            if( ElapsedTime > (counter * sleepTime)) ; input limiter..
;            {
;                this.BGFLU_LoadZ1Formation()
;                counter++
;            }
            gold := this.ConvQuadToDouble( this.Memory.ReadGoldFirst8Bytes(), this.Memory.ReadGoldSecond8Bytes() )
            Sleep, 20
        }
        ; Ellywick
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        isEllywickInFormation := g_SF.IsChampInFormation( 83, formationFavorite1 )
        isWiddleInFormation := g_SF.IsChampInFormation( 91, formationFavorite1 )
        isBrivInFormation := g_SF.IsChampInFormation( 58, formationFavorite1 )
        if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && isEllywickInFormation)
        {
            if (this.Memory.ReadChampLvlByID(83) < 200)
                g_SF.LevelChampByID( 83, 200, 5000, "{}") ; level Ellywick
            this.DirectedInput(hold := 0,, "{F10}") ; keysup
            isShandieInFormation := g_SF.IsChampInFormation( 47, formationFavorite1 )
            if (isShandieInFormation && this.Memory.ReadChampLvlByID(47) < 120)
            {
                this.LevelChampByID(47, 120, 7000, "{}") ; level Shandie
                this.DirectedInput(hold := 0,, "{F6}") ; keysup
            }
            if (isBrivInFormation && g_BrivGemFarm.BGFLU_AllowBrivLeveling())
            {
                this.LevelChampByID( 58, 80, 5000, "{}") ; level Briv
                this.DirectedInput(hold := 0,, "{F5}") ; keysup
            }
            if (isWiddleInFormation && this.Memory.ReadChampLvlByID(91) < 260)
            {
                this.LevelChampByID( 91, 260, 5000, "{}") ; level Widdle
                this.DirectedInput(hold := 0,, "{F2}") ; keysup
            }
            gemCardsNeeded := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemCards" ]
            percentBonus := g_BrivUserSettingsFromAddons[ "EllywickGFGemPercent" ]
            redraws := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ]
            if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemWaitFor5Draws" ])
                result := IC_RNGWaitingRoom_Functions.WaitForEllywickCards(gemCardsNeeded, percentBonus, redraws)
            else
                result := IC_RNGWaitingRoom_Functions.WaitForEllywickCardsNoWait(gemCardsNeeded, percentBonus, redraws)
            bonusGems := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
            g_SharedData.RNGWR_UpdateStats(bonusGems, result)

;            ; Thellora
;            isThelloraInFormation := g_SF.IsChampInFormation( 139, formationFavorite1 )
;            if (isThelloraInFormation)
;                g_SF.LevelChampByID( 139, 1, 7000, "{q}") ; level Thellora
        }
        return gold
    }
}

; Extends IC_SharedData_Class
class IC_RNGWaitingRoom_IC_SharedData_Class extends IC_SharedData_Class
{
;    RNGWR_Status := ""
;    RNGWR_Stats := ""

    ; Return true if the class has been updated by the addon
    RNGWR_Running()
    {
        return true
    }

    RNGWR_SetStatus(text := "")
    {
        this.RNGWR_Status := text
    }

    ; Load settings after "Start Gem Farm" has been clicked.
    RNGWR_Init()
    {
        stats := {}
        stats.BonusGemsSum := 0
        stats.RerollsSum := 0
        stats.Runs := 0
        this.Stats := stats
        this.RNGWR_UpdateSettingsFromFile()
    }

    RNGWR_UpdateStats(bonusGems := 0, rerolls := 0)
    {
        this.Stats["BonusGemsSum"] += bonusGems
        this.Stats["RerollsSum"] += rerolls
        this.Stats["Runs"] += 1
    }

    RNGWR_GetStats()
    {
        stats := this.Stats
        return [stats.BonusGemsSum, stats.RerollsSum, stats.Runs]
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
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemPercent" ] := settings.EllywickGFGemPercent
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ] := settings.EllywickGFGemMaxRedraws
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemWaitFor5Draws" ] := settings.EllywickGFGemWaitFor5Draws
    }
}