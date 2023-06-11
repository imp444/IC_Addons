; Functions used by this addon
class IC_BrivGemFarm_LevelUp_Functions
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"
    static HeroDefsPath := A_LineFile . "\..\HeroDefines.json"

    ; Adds IC_BrivGemFarm_LevelUp_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_LevelUp_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ; Returns true if the two objects have identical key/value pairs
    AreObjectsEqual(obj1 := "", obj2 := "")
    {
        if (obj1.Count() != obj2.Count())
            return false
        for k, v in obj1
        {
            if (IsObject(v) AND !this.AreObjectsEqual(obj2[k], v) OR !IsObject(v) AND obj2[k] != v AND obj2.HasKey(k))
                return false
        }
        return true
    }
}

; Overrides IC_BrivGemFarm_Class, check for compatibility
class IC_BrivGemFarm_LevelUp_Class extends IC_BrivGemFarm_Class
{
    ;=====================================================
    ;Primary Functions for Briv Gem Farm
    ;=====================================================
    ;The primary loop for gem farming using Briv and modron.
    GemFarm()
    {
        g_SharedData.UpdateSettingsFromFile(true)
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
        loop
        {
            g_SharedData.LoopString := "Main Loop"
            CurrentZone := g_SF.Memory.ReadCurrentZone()
            if (CurrentZone == "" AND !g_SF.SafetyCheck() ) ; Check for game closed
                g_SF.ToggleAutoProgress( 1, false, true ) ; Turn on autoprogress after a restart
            g_SF.SetFormation(g_BrivUserSettings)
            if (g_SF.Memory.ReadResetsCount() > lastResetCount OR g_SharedData.TriggerStart) ; first loop or Modron has reset
            {
                g_SharedData.SaveFormations()
                g_SharedData.BossesHitThisRun := 0
                g_SF.ToggleAutoProgress( 0, false, true )
                g_SharedData.StackFail := this.CheckForFailedConv()
                g_SF.WaitForFirstGold()
                setupMaxDone := false
                this.DoPartySetupMin(g_BrivUserSettingsFromAddons[ "ForceBrivShandie" ])
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
                g_SharedData.SwapsMadeThisRun := 0
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
            ; If briv level is set to less than 170, he doesn't get MetalBorn - Level him back after stacking
            if (g_SF.Memory.ReadChampLvlByID(58) < 170 AND g_SF.Memory.ReadSBStacks() >= (g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]))
                setupMaxDone := false
            if (!setupMaxDone)
                setupMaxDone := this.DoPartySetupMax() ; Level up all champs to the specified max level
            if (g_SharedData.UpdateMaxLevels)
            {
                setupMaxDone := false, g_SharedData.UpdateMaxLevels := false
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

    /*  StackRestart - Stops progress and wwitches to appropriate party to prepare for stacking Briv's SteelBones.
                       Falls back from a boss zone if necessary.

    Parameters:

    Returns:
    */
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
            this.DoPartySetupMax(2)
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                g_SF.DirectedInput(,,inputValues)
                counter++
            }
        }
        return
    }

    /*  DoPartySetupMin - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                          This will only level champs to the minium target specified in BrivGemFarm_LevelUp_Settings.json.
                          It will wait for Shandie dash if necessary.
                          It will only level up at a time the number of champions specified in the MaxSimultaneousInputs setting
        Parameters:       forceBrivShandie: bool - If true, force Briv/Shandie to minLevel before leveling other champions
                          timeout: integer - Time in ms before abandoning the initial leveling

        Returns:
    */
    DoPartySetupMin(forceBrivShandie := false, timeout := "")
    {
        g_SharedData.LoopString := "Leveling champions to the minimum level"
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        minLevels := g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].minLevels
        ; Level up speed champs first, priority to getting Briv, Shandie, Hew Maan, Nahara, Sentry, Virgil speed effects
        g_SF.DirectedInput(,, "{q}") ; switch to Briv in slot 5
        if (forceBrivShandie)
            champIDs := [58, 47]
        else
            champIDs := [58, 47, 91, 28, 75, 59, 115, 52, 102, 125, 89, 114, 98, 79, 81, 95] ; speed champs
        keyspam := []
        for k, champID in champIDs
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite1) AND g_SF.Memory.ReadChampLvlByID(champID) < minLevels[champID])
                keyspam.Push("{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}")
        }
        StartTime := A_TickCount, ElapsedTime := 0
        if (timeout == "")
            timeout := g_BrivUserSettingsFromAddons[ "MinLevelTimeout" ]
        timeout := timeout == "" ? 5000 : timeout
        index := 0
        while(keyspam.Length() != 0 AND ElapsedTime < timeout)
        {
            maxKeyspam := [] ; Maximum number of champions leveled up every loop
            Loop % Min(g_BrivUserSettingsFromAddons[ "MaxSimultaneousInputs" ], keyspam.Length())
                maxKeyspam.Push(keyspam[A_Index])
            g_SF.DirectedInput(,, maxKeyspam*) ; Level up speed champions once
            for champID, targetLevel in minLevels
            {
                if (g_SF.IsChampInFormation(champID, formationFavorite1))
                {
                    level := g_SF.Memory.ReadChampLvlByID(champID)
                    Fkey := "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}"
                    if (level >= targetLevel)
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
        if (forceBrivShandie AND ElapsedTime < timeout) ; remaining time > 0
            return this.DoPartySetupMin(false, g_BrivUserSettingsFromAddons[ "MinLevelTimeout" ] - ElapsedTime)
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1, false, true )
    }

    /*  DoPartySetupMax - Level up all champs to the specified max level

        Returns: bool - True if all champions in Q formation are at or past their target level, false otherwise
    */
    DoPartySetupMax(formation := 1)
    {
        static champIDs := [47, 91, 28, 75, 59, 115, 52, 102, 125, 89, 114, 98, 79, 81, 95] ; speed champs without Briv

        formationFavorite := g_SF.Memory.GetFormationByFavorite( formation )
        for k, champID in champIDs
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite))
            {
                if (g_SF.Memory.ReadChampLvlByID(champID) < g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].maxLevels[champID])
                {
                    g_SharedData.LoopString := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to the maximum level (" . g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].maxLevels[champID] . ")"
                    g_SF.DirectedInput(,, "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}") ; level up single champ once
                    return false
                }
            }
        }
        for champID, targetLevel in g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].maxLevels
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite))
            {
                if (champID == 58 AND g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].maxLevels[58] <= 170) ; If briv level is set to less than 170, he doesn't get MetalBorn - Level him back after stacking
                {
                    targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]
                    if g_SF.Memory.ReadSBStacks() < targetStacks
                        continue
                }
                if (g_SF.Memory.ReadChampLvlByID(champID) < targetLevel)
                {
                    g_SharedData.LoopString := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to the maximum level (" . targetLevel . ")"
                    g_SF.DirectedInput(,, "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}") ; level up single champ once
                    return false
                }
            }
        }
        return true
    }
}

; Overrides IC_BrivSharedFunctions_Class, check for compatibility
class IC_BrivGemFarm_LevelUp_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
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
            while(!g_BrivGemFarm.DoPartySetupMax() AND !this.IsDashActive() AND ElapsedTime < timeout)
                g_BrivGemFarm.DoPartySetupMax()
            ElapsedTime := A_TickCount - StartTime
            g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
            percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10), 15)
            Sleep, %percentageReducedSleep%
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }
}

; Overrides IC_SharedData_Class, check for compatibility
class IC_BrivGemFarm_LevelUp_IC_SharedData_Class extends IC_SharedData_Class
{
    UpdateMaxLevels := false ; Update max level immediately

    ; Load settings from the GUI settings file
    UpdateSettingsFromFile(updateMaxLevels := false)
    {
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.SettingsPath)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ] := settings.BrivGemFarm_LevelUp_Settings
        g_BrivUserSettingsFromAddons[ "ForceBrivShandie" ] := settings.ForceBrivShandie
        g_BrivUserSettingsFromAddons[ "MaxSimultaneousInputs" ] := settings.MaxSimultaneousInputs
        g_BrivUserSettingsFromAddons[ "MinLevelTimeout" ] := settings.MinLevelTimeout
        if (updateMaxLevels)
            this.UpdateMaxLevels := true
    }

    ; Save full Q,W,E formations to BrivGemFarm_LevelUp_Settings.json
    SaveFormations()
    {
        static formationsFromIndex := {1: "Q", 2: "W", 3: "E"}
        static lastFormations := ""
        static lastFormationsNotSaved := true

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