; Functions used by this addon
class IC_BrivGemFarm_LevelUp_Functions
{
    static HeroDefsPath := A_LineFile . "\..\HeroDefines.json"

    ; Adds IC_BrivGemFarm_LevelUp_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_LevelUp_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ; Retrieves cached_definitions path. If silent = false, prompts a choose dialog if path not found
    ; Saves the last known valid path
    FindCachedDefinitionsPath(silent := true)
    {
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
        if (settings.lastCachedPath == "" OR !FileExist(settings.lastCachedPath))
        {
            exePath := % g_UserSettings[ "InstallPath" ] ; Steam
            cachedPath := % exePath . "\..\IdleDragons_Data\StreamingAssets\downloaded_files\cached_definitions.json"
            if (!FileExist(cachedPath) AND !silent) ; Try to find cached_definitions folder
                FileSelectFile, cachedPath, 1, % "\..\..\..\..\IdleChampions\IdleDragons_Data\StreamingAssets\downloaded_files\cached_definitions.json", cached_definitions.json, cached_definitions.json
            settings.lastCachedPath := cachedPath
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        else
            cachedPath := settings.lastCachedPath
        return cachedPath
    }

    ; Create definitions with upgrade levels from cached_definitions.json
    CreateHeroDefs(silent := true)
    {
        path := this.FindCachedDefinitionsPath(silent)
        if (path == "")
            return ""
        g_BrivGemFarm_LevelUp.UpdateLastUpdated("Loading new definitions...")
        defs := g_SF.LoadObjectFromJSON(path)
        ; Parse hero_defines
        heroDefs := defs.hero_defines
        trimmedHeroDefs := {}
        for k, v in heroDefs
        {
            if (RegExMatch(v.name, "Y\d+E\d+") OR ErrorLevel != 0) ; skip placeholder
                continue
            id := v.id
            obj := {}
            obj.name := v.name
            obj.seat_id := v.seat_id
            if (!IsObject(trimmedHeroDefs[v]))
                trimmedHeroDefs[v] = {}
            trimmedHeroDefs[id] := obj
        }
        ; Parse upgrade_defines
        index := 0
        key := "upgrade_defines_" . index
        while isObject(defs[key])
        {
            currentUpgradeDef := defs[key]
            for k, v in currentUpgradeDef
            {
                if (v.required_upgrade_id == 9999)
                    continue
                heroID := v.hero_id
                id := v.id
                if (!IsObject(trimmedHeroDefs[heroID]["upgrades"]))
                    trimmedHeroDefs[heroID]["upgrades"] := {}
                obj := {}
                if v.required_upgrade_id < 9999
                {
                    obj.required_level := v.required_level
                    if (v.name != "")
                        obj.name := v.name
                    if (v.specialization_name)
                        obj.specialization_name := v.specialization_name
                    if (v.tip_text)
                        obj.tip_text := v.tip_text
                }
                trimmedHeroDefs[heroID]["upgrades"][id] := obj
            }
            key := "upgrade_defines_" . index++
        }
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath, trimmedHeroDefs)
        lastUpdateString := "Last updated: " . A_YYYY . "/" A_MM "/" A_DD " at " A_Hour . ":" A_Min
        g_BrivGemFarm_LevelUp.UpdateLastUpdated(lastUpdateString)
        return trimmedHeroDefs
    }

    /*  ReadHeroDefs - Read last definitions from HeroDefines.json
        Parameters:    silent: bool - If true, doesn't prompt the dialog to choose the file if not found

        Returns:       bool - True if all champions in Q formation are at or past their target level, false otherwise
    */
    ReadHeroDefs(silent := true)
    {
        heroDefs := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath)
        if (!IsObject(heroDefs))
            heroDefs := this.CreateHeroDefs(silent)
        return heroDefs
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
        g_SharedData.LoadMinMaxLevels()
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
                g_SharedData.BossesHitThisRun := 0
                g_SF.ToggleAutoProgress( 0, false, true )
                g_SharedData.StackFail := this.CheckForFailedConv()
                g_SF.WaitForFirstGold()
                setupMaxDone := false
                this.DoPartySetupMin()
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

    /*  DoPartySetupMin - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                        This will only level champs to the minium target specified in BrivGemFarm_LevelUp_Settings.json.
                        It will wait for Shandie dash if necessary.
    */
    DoPartySetupMin()
    {
        g_SharedData.LoopString := "Leveling champions to the minimum level"
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        minLevels := g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].minLevels
        ; Level up speed champs first, priority to getting Briv, Shandie, Hew Maan, Nahara, Sentry, Virgil speed effects
        g_SF.DirectedInput(,, "{q}") ; switch to Briv in slot 5
        champIDs := [58, 47, 91, 28, 75, 102, 52, 115, 89, 114, 98, 79, 81, 95] ; speed champs
        keyspam := []
        for k, champID in champIDs
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite1) AND g_SF.Memory.ReadChampLvlByID(champID) < minLevels[champID])
                keyspam.Push("{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}")
        }
        setupDone := False
        StartTime := A_TickCount
        while(!setupDone)
        {
            g_SF.DirectedInput(,, keyspam*) ; level up all champs once
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
                                keyspam.Delete(k)
                        }
                    }
                }
            }
            g_SF.SetFormation(g_BrivUserSettings) ; switch to E formation if necessary
            if (keyspam.Length() == 0 OR (A_TickCount - StartTime) > 5000)
                setupDone := true
            Sleep, 20
        }
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1, false, true )
    }

    /*  DoPartySetupMax - Level up all champs to the specified max level

        Returns: bool - True if all champions in Q formation are at or past their target level, false otherwise
    */
    DoPartySetupMax()
    {
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        maxLevels := g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ].maxLevels.Clone()
        for champID, targetLevel in maxLevels
        {
            if (g_SF.IsChampInFormation(champID, formationFavorite1))
            {
                if (champID == 58 AND maxLevels[58] <= 170) ; If briv level is set to less than 170, he doesn't get MetalBorn - Level him back after stacking
                {
                    targetStacks := g_BrivUserSettings[ "AutoCalculateBrivStacks" ] ? (this.TargetStacks - this.LeftoverStacks) : g_BrivUserSettings[ "TargetStacks" ]
                    if g_SF.Memory.ReadSBStacks() < targetStacks
                        continue
                }
                if (g_SF.Memory.ReadChampLvlByID(champID) < targetLevel)
                {
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

    ; Load new leveling settings from the GUI settings file
    LoadMinMaxLevels()
    {
        settings := g_SF.LoadObjectFromJSON(A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json")
        if (!IsObject(settings))
            return
        g_BrivUserSettingsFromAddons[ "BrivGemFarm_LevelUp_Settings" ] := settings.BrivGemFarm_LevelUp_Settings
        this.UpdateMaxLevels := true
    }
}