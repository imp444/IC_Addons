; Overrides IC_BrivGemFarm_LevelUp_Class.GemFarm()
class IC_RNGWaitingRoom_Class extends IC_BrivGemFarm_Class
{
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
        loop
        {
            g_SharedData.LoopString := "Main Loop"
            CurrentZone := g_SF.Memory.ReadCurrentZone()
            if (CurrentZone == "" AND !g_SF.SafetyCheck() ) ; Check for game closed
                g_SF.ToggleAutoProgress( 1, false, true ) ; Turn on autoprogress after a restart
            ; Prevent Thellora from being put in the formation on z1 before stacking Ellywick
            EllywickEnabled := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ]
            if (EllywickEnabled && g_SF.Memory.ReadResetting() || g_SF.Memory.ReadResetsCount() > lastResetCount)
            {
                g_SharedData.RNGWR_Elly.Reset()
                g_SharedData.RNGWR_LockFormationSwitch := !g_SharedData.RNGWR_FirstRun
            }
            if (!EllywickEnabled || !g_SharedData.RNGWR_Elly.RNGWR_LockFormationSwitch)
                g_SF.SetFormation(g_BrivUserSettings)
            if (g_SF.Memory.ReadResetsCount() > lastResetCount OR g_SharedData.TriggerStart) ; first loop or Modron has reset
            {
                ; Allow formation switch on startup
                g_SharedData.RNGWR_LockFormationSwitch := !g_SharedData.RNGWR_FirstRun ; Allow formation switch on startup
                g_SharedData.RNGWR_Elly.Reset()
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

    BGFLU_DoPartySetupMin(forceBrivShandie := false, timeout := "")
    {
        currentZone := g_SF.Memory.ReadCurrentZone()
        if (forceBrivShandie || currentZone == 1)
            g_SF.ToggleAutoProgress( 0, false, true )
        g_SharedData.BGFLU_SetStatus("Leveling champions to the minimum level")
        formation := g_SF.BGFLU_GetDefaultFormation()
        ; If low favor mode is active, cheapeast upgrade first
        lowFavorMode := g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ]
        ; Level up speed champs first, priority to getting Briv, Shandie, Hew Maan, Nahara, Sentry, Virgil speed effects
        ; Set formation
        g_SF.BGFLU_LoadZ1Formation()
        if (!lowFavorMode)
            keyspam := this.BGFLU_GetMinLevelingKeyspam(formation, forceBrivShandie)
        StartTime := A_TickCount, ElapsedTime := 0
        if (timeout == "")
            timeout := g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ]
        timeout := timeout == "" ? 5000 : timeout
        index := 0
        while(keyspam.Length() != 0 AND ElapsedTime < timeout)
        {
            ; Update formation on zone change
            if (currentZone < g_SF.Memory.ReadCurrentZone())
            {
                currentZone := g_SF.Memory.ReadCurrentZone()
                formation := g_SF.BGFLU_GetDefaultFormation()
            }
            if (lowFavorMode)
            {
                formationInOrder := this.BGFLU_OrderByCheapeastUpgrade(formation)
                keyspam := this.BGFLU_GetMinLevelingKeyspamLowFavor(formationInOrder, forceBrivShandie)
            }
            else
                keyspam := this.BGFLU_GetMinLevelingKeyspam(formation, forceBrivShandie)
            ; Maximum number of champions leveled up every loop
            maxKeyspam := []
            Loop % Min(g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ], keyspam.Length())
                maxKeyspam.Push(keyspam[A_Index])
            ; Level up speed champions once
            g_SF.DirectedInput(,, maxKeyspam*)
            ; Set formation
            g_SF.BGFLU_LoadZ1Formation()
            Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
            ElapsedTime := A_TickCount - StartTime
            if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
                g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel())
            g_SF.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
        }
        this.DirectedInput(hold := 0,, keyspam*) ; keysup
        remainingTime := timeout - ElapsedTime
        if (forceBrivShandie AND remainingTime > 0)
            return this.BGFLU_DoPartySetupMin(false, remainingTime)
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] AND g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Ellywick.HeroID, formation))
            g_SF.RNGWR_DoEllyWait()
        if (g_SF.IsChampInFormation(139, formation))
            g_SF.DoRushWait()
        ; Click damage (should be enough to kill monsters at the area Thellora jumps to unless using x1)
        if (currentZone == 1 || g_SharedData.TriggerStart)
            g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel(), Max(remainingTime, 2000))
        g_SF.ToggleAutoProgress( 1, false, true )
    }
}

; Overrides IC_BrivSharedFunctions_Class.RestartAdventure()
; Overrides IC_BrivSharedFunctions_Class.DirectedInput()
; Overrides IC_BrivGemFarm_LevelUp_Class.DoRushWait()
class IC_RNGWaitingRoom_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    RestartAdventure( reason := "" )
    {
            g_SharedData.LoopString := "ServerCall: Restarting adventure"
            this.CloseIC( reason )
            g_SharedData.RNGWR_Elly.Reset()
            g_SharedData.RNGWR_LockFormationSwitch := !g_SharedData.RNGWR_FirstRun
            if (this.sprint != "" AND this.steelbones != "" AND (this.sprint + this.steelbones) < 190000)
            {
                response := g_serverCall.CallPreventStackFail(this.sprint + this.steelbones)
            }
            else if (this.sprint != "" AND this.steelbones != "")
            {
                response := g_serverCall.CallPreventStackFail(this.sprint + this.steelbones)
                g_SharedData.LoopString := "ServerCall: Restarting with >190k stacks, some stacks lost."
            }
            else
            {
                g_SharedData.LoopString := "ServerCall: Restarting adventure (no manual stack conv.)"
            }
            response := g_ServerCall.CallEndAdventure()
            response := g_ServerCall.CallLoadAdventure( this.CurrentAdventure )
            g_SharedData.TriggerStart := true
    }

    DirectedInput(hold := 1, release := 1, s* )
    {
        Critical, On
        ; TestVar := {}
        ; for k,v in g_KeyPresses
        ; {
        ;     TestVar[k] := v
        ; }
        timeout := 5000
        directedInputStart := A_TickCount
        hwnd := this.Hwnd
        ControlFocus,, ahk_id %hwnd%
        ;while (ErrorLevel AND A_TickCount - directedInputStart < timeout * 10)  ; testing reliability
        ; if ErrorLevel
        ;     ControlFocus,, ahk_id %hwnd%
        values := s
        ; Remove Thellora
        if (hold && g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && g_SharedData.RNGWR_LockFormationSwitch)
            values := IC_RNGWaitingRoom_Functions.RemoveThelloraKeyFromInputValues(values)
        if(IsObject(values))
        {
            if(hold)
            {
                for k, v in values
                {
                    g_InputsSent++
                    ; if TestVar[v] == ""
                    ;     TestVar[v] := 0
                    ; TestVar[v] += 1
                    key := g_KeyMap[v]
                    sc := g_SCKeyMap[v]
                    sc := sc << 16
                    lparam := Format("0x{:X}", 0x0 | sc)
                    SendMessage, 0x0100, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
                    if ErrorLevel
                        this.ErrorKeyDown++
                    ;     PostMessage, 0x0100, %key%, 0,, ahk_id %hwnd%,
                }
            }
            if(release)
            {
                for k, v in values
                {
                    key := g_KeyMap[v]
                    sc := g_SCKeyMap[v]
                    sc := sc << 16
                    lparam := Format("0x{:X}", 0xC0000001 | sc)
                    SendMessage, 0x0101, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
                    if ErrorLevel
                        this.ErrorKeyUp++
                    ;     PostMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,
                }
            }
        }
        else
        {
            key := g_KeyMap[values]
            sc := g_SCKeyMap[values] << 16
            if(hold)
            {
                g_InputsSent++
                ; if TestVar[v] == ""
                ;     TestVar[v] := 0
                ; TestVar[v] += 1

                lparam := Format("0x{:X}", 0x0 | sc)
                SendMessage, 0x0100, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
                if ErrorLevel
                    this.ErrorKeyDown++
            }
            if(release)
            {
                lparam := Format("0x{:X}", 0xC0000001 | sc)
                SendMessage, 0x0101, %key%, %lparam%,, ahk_id %hwnd%,,,,%timeout%
            }
            if ErrorLevel
                this.ErrorKeyUp++
            ;     PostMessage, 0x0101, %key%, 0xC0000001,, ahk_id %hwnd%,
        }
        Critical, Off
        ; g_KeyPresses := TestVar
    }

    RNGWR_DoEllyWait()
    {
        this.Memory.ActiveEffectKeyHandler.Refresh()
        if (g_SharedData.RNGWR_Elly.IsEllyWickOnTheField())
        {
            timeout := 60000
            ElapsedTime := 0
            StartTime := A_TickCount
            while(!g_SharedData.RNGWR_Elly.WaitedForEllywickThisRun && ElapsedTime < timeout)
            {
                if (!g_SharedData.RNGWR_LockFormationSwitch)
                    g_SF.BGFLU_LoadZ1Formation()
                g_SharedData.LoopString := "Elly Wait: " . ElapsedTime
                this.BGFLU_DoClickDamageSetup(1, g_BrivGemFarm.BGFLU_GetClickDamageTargetLevel())
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

; Extends IC_SharedData_Class
class IC_RNGWaitingRoom_IC_SharedData_Class extends IC_SharedData_Class
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