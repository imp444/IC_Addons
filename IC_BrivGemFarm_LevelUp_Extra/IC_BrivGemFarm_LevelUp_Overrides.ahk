; Overrides IC_BrivGemFarm_Class.GemFarm()
; Overrides IC_BrivGemFarm_Class.StackFarmSetup()
class IC_BrivGemFarm_LevelUp_Class extends IC_BrivGemFarm_Class
{
    ;=====================================================
    ;Primary Functions for Briv Gem Farm
    ;=====================================================
    ;The primary loop for gem farming using Briv and modron.
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
            g_SF.SetFormation(g_BrivUserSettings)
            if (g_SF.Memory.ReadResetsCount() > lastResetCount OR g_SharedData.TriggerStart) ; first loop or Modron has reset
            {
                g_SharedData.BGFLU_SaveFormations()
                g_SharedData.SwapsMadeThisRun := 0
                g_SharedData.BossesHitThisRun := 0
                g_SF.ToggleAutoProgress( 0, false, true )
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

    ; Stops progress and switches to appropriate party to prepare for stacking Briv's SteelBones.
    StackFarmSetup()
    {
        if (!g_SF.KillCurrentBoss() ) ; Previously/Alternatively FallBackFromBossZone()
            g_SF.FallBackFromBossZone()
        inputValues := "{w}" ; Stack farm formation hotkey
        g_SF.DirectedInput(,, inputValues )
        g_SF.WaitForTransition( inputValues )
        g_SF.ToggleAutoProgress( 0 , false, true )
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 50
        g_SharedData.LoopString := "Setting stack farm formation."
        while ( !g_SF.IsCurrentFormation(g_SF.Memory.GetFormationByFavorite( 2 )) AND ElapsedTime < 5000 )
        {
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                g_SF.DirectedInput(,,inputValues)
                counter++
            }
            this.BGFLU_DoPartySetupMax(2)
        }
        while (!this.BGFLU_DoPartySetupMax(2) AND (A_TickCount - StartTime) < 5000)
           Sleep, 30
        return
    }

    /*  BGFLU_DoPartySetupMin - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                          This will only level champs to the minium target specified in BrivGemFarm_LevelUp_Settings.json.
                          This will not level champs whose minimum level is set to 0.
                          It will wait for Shandie dash / Thellora Rush if necessary.
                          It will only level up at a time the number of champions specified in the MaxSimultaneousInputs setting.
        Parameters:       forceBrivShandie: bool - If true, force Briv/Shandie to minLevel before leveling other champions
                          timeout: integer - Time in ms before abandoning the initial leveling

        Returns:
    */
    BGFLU_DoPartySetupMin(forceBrivShandie := false, timeout := "")
    {
        currentZone := g_SF.Memory.ReadCurrentZone()
        if (forceBrivShandie || currentZone == 1)
            g_SF.ToggleAutoProgress(0)
        g_SharedData.LoopString := "Leveling champions to the minimum level"
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        minLevels := g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ].minLevels
        ; Level up speed champs first, priority to getting Briv, Shandie, Hew Maan, Nahara, Sentry, Virgil speed effects
        g_SF.DirectedInput(,, "{q}") ; switch to Briv in slot 5
        if (forceBrivShandie)
            champIDs := [58, 47]
        else
            champIDs := [58, 47, 91, 128, 28, 75, 59, 115, 52, 102, 125, 89, 114, 98, 79, 81, 95, 56, 139] ; speed champs
        if (!this.BGFLU_AllowBrivLeveling()) ; Need to walk while Briv is in all formations
            champIDs.RemoveAt(1)
        keyspam := []
        if (!forceBrivShandie)
        {
            nonSpeedIDs := {}
            for k, champID in formationFavorite1
            {
                if (champID == 58 && !this.BGFLU_AllowBrivLeveling()) ; Need to walk while Briv is in all formations
                    continue
                if (champID != -1 && champID != "")
                    nonSpeedIDs[champID] := champID
            }
        }
        ; Get Fkeys for speed champs
        for k, champID in champIDs
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite1))
            {
                if (this.BGFLU_ChampUnderTargetLevel(champID, minLevels[champID]))
                    keyspam.Push("{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}")
                if (!forceBrivShandie)
                    nonSpeedIDs.Delete(champID)
            }
        }
        ; Get Fkeys for other champs
        if (!forceBrivShandie)
        {
            for k, champID in nonSpeedIDs
            {
                if (this.BGFLU_ChampUnderTargetLevel(champID, minLevels[champID]))
                    keyspam.Push("{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}")
            }
        }
        StartTime := A_TickCount, ElapsedTime := 0
        if (timeout == "")
            timeout := g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ]
        timeout := timeout == "" ? 5000 : timeout
        index := 0
        while(keyspam.Length() != 0 AND ElapsedTime < timeout)
        {
            maxKeyspam := [] ; Maximum number of champions leveled up every loop
            Loop % Min(g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ], keyspam.Length())
                maxKeyspam.Push(keyspam[A_Index])
            g_SF.DirectedInput(,, maxKeyspam*) ; Level up speed champions once
            for champID, targetLevel in minLevels
            {
                if (g_SF.IsChampInFormation(champID, formationFavorite1))
                {
                    Fkey := "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}"
                    if (!this.BGFLU_ChampUnderTargetLevel(champID, targetLevel))
                    {
                        for k, v in keyspam
                        {
                            if (v == Fkey)
                            {
                                keyspam.RemoveAt(k)
                                break
                            }
                        }
                    }
                }
            }
            g_SF.SetFormation(g_BrivUserSettings) ; Switch to E formation if necessary
            Sleep, 30
            ElapsedTime := A_TickCount - StartTime
        }
        this.DirectedInput(hold := 0,, keyspam*) ; keysup
        if (forceBrivShandie AND ElapsedTime < timeout) ; remaining time > 0
            return this.BGFLU_DoPartySetupMin(false, g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ] - ElapsedTime)
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        ; Click damage (should be enough to kill monsters at the area Thellora jumps to unless using x1)
        if (currentZone == 1 || g_SharedData.TriggerStart)
            g_SF.BGFLU_DoClickDamageSetup(g_BrivUserSettingsFromAddons[ "BGFLU_MinClickDamage" ])
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] AND g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        if (g_SF.IsChampInFormation(139, formationFavorite1))
            g_SF.DoRushWait()
        g_SF.ToggleAutoProgress( 1, false, true )
    }

    /*  BGFLU_DoPartySetupMax - Level up all champs to the specified max level
                          This will not level champs whose maximum level is set to 0.
        Returns: bool - True if all champions in Q formation are at or past their target level, false otherwise
    */
    BGFLU_DoPartySetupMax(formation := 1)
    {
        static champIDs := [47, 91, 128, 28, 75, 59, 115, 52, 102, 125, 89, 114, 98, 79, 81, 95, 56, 139] ; speed champs without Briv

        levelBriv := true ; Return value
        formationFavorite := g_SF.Memory.GetFormationByFavorite( formation )
        levelSettings := g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ]
        if (this.BGFLU_ChampUnderTargetLevel(58, levelSettings.minLevels[58]))
        {
            if (this.BGFLU_AllowBrivLeveling()) ; Level Briv to be able to skip areas
                this.BGFLU_DoPartySetupMin(true)
            else
                levelBriv := false
        }
        for k, champID in champIDs
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite))
            {
                maxLevel := levelSettings.maxLevels[champID]
                if (this.BGFLU_ChampUnderTargetLevel(champID, maxLevel))
                {
                    g_SharedData.LoopString := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to the maximum level (" . maxLevel . ")"
                    g_SF.DirectedInput(,, "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}") ; Level up single champ once
                    return false
                }
            }
        }
        for champID, targetLevel in levelSettings.maxLevels
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite))
            {
                ; Briv
                if (champID == 58)
                {
                    if (!levelBriv)
                        continue
                    ; Level up Briv to BrivMinLevelStacking before stacking
                    if (this.BGFLU_NeedToStack())
                        targetLevel := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStacking" . (this.ShouldOfflineStack() ? "" : "Online") ]
                }
                ; Level up a single champion once
                if (this.BGFLU_ChampUnderTargetLevel(champID, targetLevel))
                {
                    g_SharedData.LoopString := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to the maximum level (" . targetLevel . ")"
                    g_SF.DirectedInput(,, "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}")
                    return false
                }
            }
        }
        return levelBriv
    }

    /*  BGFLU_DoPartySetupFailedConversion - Level up all champs to soft cap after a failed conversion.
        If the setting LevelToSoftCapFailedConversionBriv is set to true, also level Briv.

        Returns: bool - True if all champions in Q formation are soft capped, false otherwise
    */
    BGFLU_DoPartySetupFailedConversion(formationIndex := 1)
    {
        formation := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(formationIndex), true) ; without empty slots
        for k, champID in formation
        {
            if (g_SF.IsChampInFormation(champID, formation) AND (champID != 58 OR g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversionBriv" ]))
            {
                if (this.BGFLU_ChampUnderTargetLevel(champID, g_SF.LastUpgradeLevelByID[champID]))
                {
                    g_SharedData.LoopString := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to soft cap (" . g_SF.LastUpgradeLevelByID[champID] . ")"
                    g_SF.DirectedInput(,, "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}") ; level up single champ once
                    return false
                }
            }
        }
        return true
    }

    ; Returns true if the champion needs to be levelled.
    BGFLU_ChampUnderTargetLevel(champID := 0, target := 0)
    {
        if target is not integer
            return false
        return target != 0 && g_SF.Memory.ReadChampLvlByID(champID) < target
    }

    ; Returns true if stacking Briv is necessary during this run.
    BGFLU_NeedToStack()
    {
        stacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? g_SF.Memory.ReadSBStacks() : this.GetNumStacksFarmed()
        targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]
        return stacks < targetStacks
    }

    BGFLU_AllowBrivLeveling()
    {
        if (g_SF.Memory.ReadHasteStacks() < 50)
            return true
        highestZone := g_SF.Memory.ReadHighestZone()
        if (highestZone < g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ])
            return false
        mod50Index := Mod(highestZone, 50) == 0 ? 50 : Mod(highestZone, 50)
        mod50Zones := g_BrivUserSettingsFromAddons[ "BGFLU_BrivLevelingZones" ]
        if (mod50Zones[mod50Index] == 0 && this.BGFLU_ChampUnderTargetLevel(58, 80))
            return false
        return true
    }
}

; Overrides IC_BrivSharedFunctions_Class.DoDashWait()
; Overrides IC_BrivSharedFunctions_Class.DoRushWait()
; Overrides IC_BrivSharedFunctions_Class.InitZone()
class IC_BrivGemFarm_LevelUp_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
;    LastUpgradeLevelByID := "" ; Filled before entering GemFarm() loop

    ;================================
    ;Functions mostly for gem farming
    ;================================
    /*  DoDashWait - A function that will wait for Dash ability to activate by reading the current time scale multiplier.

        Parameters:
        DashWaitMaxZone ;Maximum zone to attempt to Dash wait.

        Returns: nothing
    */
    DoDashWait( DashWaitMaxZone := 2000 )
    {
        this.ToggleAutoProgress( 0, false, true )
        if(this.Memory.ReadChampLvlByID(47) < 120)
            this.LevelChampByID( 47, 120, 7000, "{q}") ; level shandie
        ; Make sure the ability handler has the correct base address.
        ; It can change on game restarts or modron resets.
        this.Memory.ActiveEffectKeyHandler.Refresh()
        StartTime := A_TickCount
        ElapsedTime := 0
        timeScale := this.Memory.ReadTimeScaleMultiplier()
        timeScale := timeScale < 1 ? 1 : timeScale ; time scale should never be less than 1
        timeout := 30000 ; 60s seconds ( previously / timescale (6s at 10x) )
        estimate := (timeout / timeScale) ; no buffer: 60s / timescale to show in LoopString
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted dashwait triggering area
        ;   dash is active, dash.GetScaleActive() toggles to true when dash is active and returns "" if fails to read.
        while ( ElapsedTime < timeout AND this.Memory.ReadCurrentZone() < DashWaitMaxZone AND !this.IsDashActive() )
        {
            this.ToggleAutoProgress(0)
            this.SetFormation()
            g_BrivGemFarm.BGFLU_DoPartySetupMax()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
            Sleep, 30
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }

    ; Wait for Thellora to activate her Rush ability.
    DoRushWait()
    {
        this.ToggleAutoProgress( 0, false, true )
        ; Make sure the ability handler has the correct base address.
        ; It can change on game restarts or modron resets.
        this.Memory.ActiveEffectKeyHandler.Refresh()
        StartTime := A_TickCount
        ElapsedTime := 0
        timeScale := this.Memory.ReadTimeScaleMultiplier()
        timeScale := timeScale < 1 ? 1 : timeScale ; time scale should never be less than 1
        timeout := 8000 ; 8s seconds
        estimate := (timeout / timeScale)
        ; Loop escape conditions:
        ;   does full timeout duration
        ;   past highest accepted rushwait triggering area
        ;   rush is active
        while (ElapsedTime < timeout && this.ShouldRushWait())
        {
            this.ToggleAutoProgress(0)
            this.SetFormation()
            g_BrivGemFarm.BGFLU_DoPartySetupMax()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Rush Wait: " . ElapsedTime . " / " . estimate
            Sleep, 30
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        Critical, On
        this.BGFLU_DoClickDamageSetup(g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamagePerArea" ])
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ])
        {
            ; turn Fkeys off/on again
            this.DirectedInput(hold := 0,, spam*) ;keysup
            this.DirectedInput(,release := 0, spam*) ;keysdown
        }
        ; try to progress
        this.DirectedInput(,,"{Right}")
        this.ToggleAutoProgress(1)
        this.ModronResetZone := this.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        g_PreviousZoneStartTime := A_TickCount
        Critical, Off
    }

    ; LevelUp click damage.
    ; Depending on the <NoCtrlKeypress> setting, uses either in-game settings or x100.
    BGFLU_DoClickDamageSetup(numClicks := 1)
    {
        Loop, % numClicks
        {
            if(g_UserSettings[ "NoCtrlKeypress" ])
            {
                this.DirectedInput(,release := 0, "{ClickDmg}") ;keysdown
                this.DirectedInput(hold := 0,, "{ClickDmg}") ;keysup
            }
            else
            {
                this.DirectedInput(,release := 0, ["{RCtrl}","{ClickDmg}"]*) ;keysdown
                this.DirectedInput(hold := 0,, ["{ClickDmg}","{RCtrl}"]*) ;keysup
            }
        }
    }

    ; Retrieves the required level of the last upgrade of every champion
    BGFLU_CalcLastUpgradeLevels()
    {
        obj := {}
        Loop, % this.Memory.ReadChampListSize()
        {
            champID := A_Index, maxUpgradeLevel := 0
            Loop, % this.Memory.ReadHeroUpgradesSize(champID)
            {
                requiredLevel := this.Memory.ReadHeroUpgradeRequiredLevel(champID, A_Index - 1)
                if (requiredLevel != 9999)
                    maxUpgradeLevel := Max(requiredLevel, maxUpgradeLevel)
            }
            obj[champID] := maxUpgradeLevel
        }
        this.LastUpgradeLevelByID := obj
    }
}

; Extends IC_SharedData_Class
class IC_BrivGemFarm_LevelUp_IC_SharedData_Class extends IC_SharedData_Class
{
;    BGFLU_UpdateMaxLevels := false ; Update max level immediately

    ; Return true if the class has been updated by the addon
    BrivGemFarmLevelUpRunning()
    {
        return true
    }

    ; Return true if the class has been updated by the addon
    BGFLU_Running()
    {
        return true
    }

    ; Load settings from the GUI settings file
    BGFLU_UpdateSettingsFromFile(updateMaxLevels := false, fileName := "")
    {
        if (fileName == "")
            fileName := IC_BrivGemFarm_LevelUp_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ] := settings.BrivGemFarm_LevelUp_Settings
        this.BGFLU_FillMissingDefaultSettings(settings.DefaultMinLevel, settings.DefaultMaxLevel)
        g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivShandie" ] := settings.ForceBrivShandie
        g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] := settings.SkipMinDashWait
        g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ] := settings.MaxSimultaneousInputs
        g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ] := settings.MinLevelTimeout
        g_BrivUserSettingsFromAddons[ "BGFLU_MinClickDamage" ] := settings.MinClickDamage
        g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamagePerArea" ] := settings.ClickDamagePerArea
        g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ] := settings.ClickDamageSpam
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStacking" ] := settings.BrivMinLevelStacking
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStackingOnline" ] := settings.BrivMinLevelStackingOnline
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ] := settings.BrivMinLevelArea
        mod50Zones := IC_BrivGemFarm_LevelUp_Functions.ConvertBitfieldToArray(settings.BrivLevelingZones)
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivLevelingZones" ] := mod50Zones
        g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversion" ] := settings.LevelToSoftCapFailedConversion
        g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversionBriv" ] := settings.LevelToSoftCapFailedConversionBriv
        if (updateMaxLevels)
            this.BGFLU_UpdateMaxLevels := true
    }

    ; Update min/max values for champions added after default settings have been initialized
    BGFLU_FillMissingDefaultSettings(minLevel := 0, maxLevel := "Last")
    {
        levelSettings := g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ]
        numChamps := g_SF.Memory.ReadChampListSize()
        if ((numChamps := g_SF.Memory.ReadChampListSize()) == "")
        {
            func := ObjBindMethod(this, "BGFLU_RetryCalc")
            SetTimer, %func%, -1000
            return
        }
        Loop, % numChamps
        {
            champID := A_Index
            if levelSettings.minLevels[champID] == ""
                levelSettings.minLevels[champID] := (minLevel == "") ? 0 : minLevel
            if levelSettings.maxLevels[champID] == ""
            {
                if (maxLevel == "Last")
                    levelSettings.maxLevels[champID] := g_SF.LastUpgradeLevelByID[champID]
                else
                    levelSettings.maxLevels[champID] := (maxLevel == "") ? 1 : maxLevel
            }
        }
    }

    BGFLU_RetryCalc()
    {
        g_SF.Memory.OpenProcessReader()
        g_SF.BGFLU_CalcLastUpgradeLevels()
        this.BGFLU_UpdateSettingsFromFile(true)
    }

    ; Save full Q,W,E formations to BrivGemFarm_LevelUp_Settings.json
    BGFLU_SaveFormations()
    {
        static formationsFromIndex := {1: "Q", 2: "W", 3: "E"}
        static lastFormations := ""
        static lastFormationsNotSaved := true

        CurrentObjID := g_SF.Memory.ReadCurrentObjID() ; VerifyAdventureLoaded()
        if (CurrentObjID == "" OR CurrentObjID <= 0)
            return
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.SettingsPath)
        if (!IsObject(settings))
            settings := {}
        savedFormations := settings.SavedFormations
        if (!IsObject(savedFormations))
        {
            savedFormations := {}
            settings["SavedFormations"] := savedFormations
            save := true
        }
        if (lastFormations == "")
            lastFormations := {}
        if (!save) ; Compare the last known formation to the current in-game formation, then current formation to saved formation
        {
            Loop, 3
            {
                currentFormation := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(A_Index), true) ; without empty slots
                lastFormation := lastFormations[formationsFromIndex[A_Index]]
                if (!IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(currentFormation, lastFormation))
                {
                    lastFormations[formationsFromIndex[A_Index]] := currentFormation
                    if (!lastFormationsNotSaved)
                    {
                        save := true
                        break
                    }
                }
                savedFormation := savedFormations[formationsFromIndex[A_Index]]
                if (!IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(currentFormation, savedFormation))
                {
                    save := true
                    break
                }
            }
            lastFormationsNotSaved := false
        }
        if (save)
        {
            savedFormations.Q := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(1), true)
            savedFormations.W := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(2), true)
            savedFormations.E := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(3), true)
            settings["SavedFormations"] := savedFormations
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Functions.SettingsPath, settings)
        }
    }
}