#include *i %A_LineFile%\..\..\IC_BrivGemFarm_LevelUp_Extra\IC_BrivGemFarm_LevelUp_Functions.ahk

; Functions that allow Q/E swaps with Briv in E formation
class IC_BrivGemFarm_BrivFeatSwap_Functions
{
    static Injected := false

    ; Adds IC_BrivGemFarm_BrivFeatSwap_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon(external := false)
    {
        if (this.Injected OR this.CheckForLevelUpAddon() AND !external) ; Load LevelUp before this addon
            return
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_BrivFeatSwap_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
        this.Injected := true
    }

    ; Returns true if the BrivGemFarm LevelUp addon is enabled in Addon Management or in the AddOnsIncluded.ahk file
    CheckForLevelUpAddon()
    {
        static AddOnsIncludedConfigFile := % A_LineFile . "\..\..\AddOnsIncluded.ahk"
        static AddonName := "BrivGemFarm LevelUp"

        if (IsObject(AM := AddonManagement)) ; Look for enabled BrivGemFarm LevelUp addon
            for k, v in AM.EnabledAddons
                if (v.Name == AddonName)
                    return true
        if (FileExist(AddOnsIncludedConfigFile)) ; Try in the AddOnsIncluded file
            Loop, Read, %AddOnsIncludedConfigFile%
                if InStr(A_LoopReadLine, "#include *i %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Extra\IC_BrivGemFarm_LevelUp_Component.ahk")
                    return true
        return false
    }
}

; Overrides IC_BrivGemFarm_Class, check for compatibility
; Checks for Briv in E formation.
class IC_BrivGemFarm_BrivFeatSwap_Class extends IC_BrivGemFarm_Class
{
    ; Tests to make sure Gem Farm is properly set up before attempting to run.
    PreFlightCheck()
    {
        settings := g_SF.LoadObjectFromJSON(A_LineFile . "\..\BrivGemFarm_BrivFeatSwap_Settings.json")
        if (!settings.Enabled)
            return this.base.PreFlightCheck()
        else
            g_SharedData.BGFBFS_ToggleAddon(true)
        memoryVersion := g_SF.Memory.GameManager.GetVersion()
        ; Test Favorite Exists
        txtCheck := "`n`nOther potential solutions:"
        txtCheck .= "`n`n1. Be sure Imports are up to date. Current imports are for: v" . g_SF.Memory.GetImportsVersion()
        txtCheck .= "`n`n2. Check the correct memory file is being used. Current version: " . memoryVersion
        txtcheck .= "`n`n3. If IC is running with admin privileges, then the script will also require admin privileges."
        if (_MemoryManager.is64bit)
            txtcheck .= "`n`n3. Check AHK is 64bit."

        champion := 58   ; briv
        formationQ := g_SF.FindChampIDinSavedFavorite( champion, favorite := 1, includeChampion := True )
        if (formationQ == -1 AND this.RunChampionInFormationTests(champion, favorite := 1, includeChampion := True, txtCheck) == -1)
            return -1

        formationW := g_SF.FindChampIDinSavedFavorite( champion, favorite := 2, includeChampion := True  )
        if (formationW == -1 AND this.RunChampionInFormationTests(champion, favorite := 2, includeChampion := True, txtCheck) == -1)
            return -1

        formationE := g_SF.FindChampIDinSavedFavorite( champion, favorite := 3, includeChampion := False  )
        if (formationE == -1 AND this.RunChampionInFormationTests(champion, favorite := 3, includeChampion := True, txtCheck) == -1)
            return -1

        if ((ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 1, True)))
            MsgBox, %ErrorMsg%
        while (ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 2, False))
        {
            MsgBox, 5,, %ErrorMsg%
            IfMsgBox, Retry
            {
                g_SF.OpenProcessReader()
                ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 2, False)
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return -1
            }
        }
        if (ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 3, True))
            MsgBox, %ErrorMsg%

        return 0
    }

    ; Stops progress and switches to appropriate party to prepare for stacking Briv's SteelBones.
    StackFarmSetup(params*)
    {
        this.base.StackFarmSetup(params*)
        if (!g_SharedData.BGFBFS_Enabled)
            return
        if (g_SF.IsCurrentFormation(g_SF.Memory.GetFormationByFavorite(2)))
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
    }
}

; Overrides IC_BrivSharedFunctions_Class.SetFormation()
; Overrides IC_BrivSharedFunctions_Class.BenchBrivConditions()
; Overrides IC_BrivSharedFunctions_Class.KillCurrentBoss()
class IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    static BrivFeatSwap_Initialized := false
    static RetryInit := 0

    ; Update target values from file on launch
    BrivFeatSwap_Init()
    {
        if (g_SharedData.BrivGemFarmLevelUpRunning()) ; LevelUp addon check
            g_BrivGemFarm.base := IC_BrivGemFarm_LevelUp_Class
        settings := this.LoadObjectFromJSON(A_LineFile . "\..\BrivGemFarm_BrivFeatSwap_Settings.json")
        ; Retry once at most
        if (!IsObject(settings) && !IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class.RetryInit++)
            return false
        g_SharedData.BGFBFS_UpdateSettings(settings.targetQ, settings.targetE, settings.Preset, settings.MouseClick)
        return true
    }

    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "")
    {
        if (!this.BrivFeatSwap_Initialized) ;only send input messages if necessary
            this.BrivFeatSwap_Initialized := this.BrivFeatSwap_Init()
        if (!g_SharedData.BGFBFS_Enabled)
            return base.SetFormation(settings)
        if(settings != "")
        {
            this.Settings := settings
        }
        if (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() == "") ; Not refreshed if for DoDashWait() is skipped
            this.Memory.ActiveEffectKeyHandler.Refresh()
        currentZone := this.Memory.ReadCurrentZone()
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
        ; Using click on "Cancel" to clear champions out the formation
        currentFormation := this.Memory.GetCurrentFormation()
        if (g_BrivUserSettingsFromAddons[ "BGFBFS_MouseClick" ])
        {
            if (!this.BGFBFS_IsFormationEmpty(currentFormation))
            {
                if (this.Memory.ReadTransitionOverrideSize() == 1 AND this.Memory.ReadTransitionDirection() != 2 AND this.Memory.ReadFormationTransitionDir() == 3 || currentZone == 22 && g_SharedData.BGFBFS_Preset == "7J/4J Tall Tales")
                    return this.BGFBFS_MouseClickCancel(currentZone)
            }
            else if (this.Memory.ReadTransitionOverrideSize() == 1 || currentZone == 22 && g_SharedData.BGFBFS_Preset == "7J/4J Tall Tales")
                return
        }
        ;check to bench briv
        if ((g_SharedData.BrivFeatSwap_UpdateSkipAmount() != g_BrivUserSettingsFromAddons[ "TargetE" ] AND this.BenchBrivConditions(this.Settings)) || this.BGFBFS_IsFormationEmpty(currentFormation))
        {
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(3)
            return
        }
        ;check to unbench briv
        if ((g_SharedData.BrivFeatSwap_UpdateSkipAmount() != g_BrivUserSettingsFromAddons[ "TargetQ" ] AND this.UnBenchBrivConditions(this.Settings)) || this.BGFBFS_IsFormationEmpty(currentFormation))
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(1)
            return
        }
        ; Prevent incorrect read if Briv is the only champion leveled in Q/E (e.g. using "Level Briv/Shandie to MinLevel first" LevelUp addon option)
        if (currentZone == 1)
            return
        isFormation2 := this.IsCurrentFormation(this.Memory.GetFormationByFavorite(2))
        isWalkZone := this.Settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50)] == 0
        ; check to swap briv from favorite 2 to favorite 3 (W to E)
        if (isFormation2 AND isWalkZone)
        {
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
            this.DirectedInput(,,["{e}"]*)
            return
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        if (isFormation2 AND !isWalkZone)
        {
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
            this.DirectedInput(,,["{q}"]*)
            return
        }
    }

    ; True/False on whether Briv should be benched based on game conditions.
    BenchBrivConditions(settings)
    {
        if (!g_SharedData.BGFBFS_Enabled)
            return base.BenchBrivConditions(settings)
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
       ; if (this.Memory.ReadTransitionOverrideSize() == 1 AND this.Memory.ReadTransitionDirection() != 2 AND this.Memory.ReadFormationTransitionDir() == 3 )
           ; return true
        ;bench briv not in a preferred briv jump zone
        if (settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50) ] == 0)
            return true
        ;perform no other checks if 'Briv Jump Buffer' setting is disabled
        if !(settings[ "BrivJumpBuffer" ])
            return false
        ;bench briv if within the 'Briv Jump Buffer'-supposedly this reduces chances of failed conversions by having briv on bench during modron reset.
        maxSwapArea := this.ModronResetZone - settings[ "BrivJumpBuffer" ]
        if (this.Memory.ReadCurrentZone() >= maxSwapArea)
            return true
        return false
    }

    UnBenchBrivConditions(settings)
    {
        if (!g_SharedData.BGFBFS_Enabled)
            return base.UnBenchBrivConditions(settings)
        return base.UnBenchBrivConditions(settings) || this.BGFBFS_IsFormationEmpty() && this.Memory.ReadTransitionOverrideSize() != 1
    }

    ; If Briv has enough stacks to jump, don't force switch to e and wait for the boss to be killed.
    KillCurrentBoss(params*)
    {
        if (!g_SharedData.BGFBFS_Enabled || this.Memory.ReadHasteStacks() < 50)
            return base.KillCurrentBoss(params*)
        return true
    }

    ; Returns true if there are no champions in the current formation.
    BGFBFS_IsFormationEmpty(formation)
    {
        for k, v in formation
        {
            if (v != -1)
                return false
        }
        return true
    }

    ; Functions used to click clear formation, to cancel Briv's jump animation.

    BGFBFS_MouseClickCancel(currentZone := 1)
    {
        static coords := ""

        if (currentZone == 1 || coords == "")
            coords := this.BGFBFS_GetClickCoords()
        exeName := this.BGFBFS_GetExeName()
        WinActivate, ahk_exe %exeName%
        xClick := coords[1]
        yClick := coords[2]
        MouseClick, Left, xClick, yClick, 1, 0
    }

    BGFBFS_GetClickCoords()
    {
        xOffset := yOffset := 0
        ; Fullscreen
        if (this.BGFBFS_IsGameFullScreen())
        {
            exeName := this.BGFBFS_GetExeName()
            WinActivate, ahk_exe %exeName%
            WinGetPos, x, y, w, h, ahk_exe %exeName%
            ; Find if the game resolution is set to tall or wide
            midWidthPos := Round(x + w / 2)
            midHeightPos := Round(y + h / 2)
            PixelGetColor, colorW, midWidthPos, 0
            PixelGetColor, colorH, 0, midHeightPos
            color := 0
            step := 10
            ; Tall
            if (colorW > 0 && colorH == 0)
            {
                While (color == 0 && xOffset < w)
                {
                    PixelGetColor, color, xOffset, 0
                    xOffset += step
                }
                xOffset -= step
            }
            ; Wide
            else if (colorW == 0 && colorH > 0)
            {
                While (color == 0 && yOffset < h)
                {
                    PixelGetColor, color, 0, yOffset
                    yOffset += step
                }
                yOffset -= step
                yOffset := -yOffset
            }
            winBottom := y + h
        }
        else
            winBottom := g_SF.Memory.ReadScreenHeight()
        xClick := xOffset + 24
        yClick := winBottom + yOffset - 24
        return [xClick, yClick]
    }

    BGFBFS_IsGameFullScreen()
    {
        exeName := this.BGFBFS_GetExeName()
        ; Get monitor coords
        WinGet, hwnd, ID, ahk_exe %exeName%
        monitor := this.BGFBFS_GetMonitor(hwnd)
        SysGet, monitorCoords, MonitorWorkArea, %monitor%
        ; Get game window coords
        WinGetPos, x, y, w, h, ahk_exe %exeName%
        return (monitorCoordsLeft == x && monitorCoordsTop == y)
    }

    BGFBFS_GetMonitor(hwnd := 0)
    {
        ; If no hwnd is provided, use the Active Window
        if (hwnd)
            WinGetPos, winX, winY, winW, winH, ahk_id %hwnd%
        else
        { ; Needed
            WinGetActiveStats, winTitle, winW, winH, winX, winY
        }
        SysGet, numDisplays, MonitorCount
        SysGet, idxPrimary, MonitorPrimary
        Loop %numDisplays%
        {	SysGet, mon, MonitorWorkArea, %a_index%
        ; Left may be skewed on Monitors past 1
            if (a_index > 1)
                monLeft -= 10
        ; Right overlaps Left on Monitors past 1
            else if (numDisplays > 1)
                monRight -= 10
        ; Tracked based on X. Cannot properly sense on Windows "between" monitors
            if (winX >= monLeft && winX < monRight)
                return %a_index%
        }
        ; Return Primary Monitor if can't sense
        return idxPrimary
    }

    BGFBFS_GetExeName()
    {
        default := "IdleDragons.exe"
        exeName := g_UserSettings[ "ExeName" ]
        return (exeName != default && exeName != "") ? exeName : default
    }
}

; Overrides IC_SharedData_Class, check for compatibility
class IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Class extends IC_SharedData_Class
{
;    BGFBFS_Enabled
;    BGFBFS_Preset
;    BrivFeatSwap_savedQSKipAmount
;    BrivFeatSwap_savedWSKipAmount
;    BrivFeatSwap_savedESKipAmount

    ; Return true if the class has been updated by the addon
    BGFBFS_Running()
    {
        return true
    }

    BGFBFS_ToggleAddon(enabled)
    {
        this.BGFBFS_Enabled := enabled
    }

    ; Saves current Briv jump amount
    BrivFeatSwap_UpdateSkipAmount(formationIndex := 0)
    {
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        Switch formationIndex
        {
            Case 1:
                this.BrivFeatSwap_savedQSKipAmount := skipAmount
            Case 2:
                this.BrivFeatSwap_savedWSKipAmount := skipAmount
            Case 3:
                this.BrivFeatSwap_savedESKipAmount := skipAmount
            Default:
                return skipAmount
        }
        this.SwapsMadeThisRun++
    }

    ; Update target values used to check for briv Q/E formation swaps
    ; Update preset name
    BGFBFS_UpdateSettings(targetQ := 0, targetE := 0, preset := "", mouseClick := false)
    {
        g_BrivUserSettingsFromAddons[ "TargetQ" ] := targetQ
        g_BrivUserSettingsFromAddons[ "TargetE" ] := targetE
        this.BGFBFS_Preset := preset
        g_BrivUserSettingsFromAddons[ "BGFBFS_MouseClick" ] := mouseClick
    }
}