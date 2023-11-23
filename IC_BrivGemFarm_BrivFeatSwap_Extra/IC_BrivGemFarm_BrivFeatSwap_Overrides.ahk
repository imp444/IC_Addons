; Overrides IC_BrivGemFarm_Class.PreFlightCheck()
; Overrides IC_BrivGemFarm_Class.StackFarmSetup()
; Checks for Briv in E formation.
class IC_BrivGemFarm_BrivFeatSwap_Class extends IC_BrivGemFarm_Class
{
    ; Tests to make sure Gem Farm is properly set up before attempting to run.
    PreFlightCheck()
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ])
            return this.base.PreFlightCheck()
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
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ])
            return
        if (g_SF.IsCurrentFormation(g_SF.Memory.GetFormationByFavorite(2)))
            g_SharedData.BGFBFS_UpdateSkipAmount(2)
    }
}

; Overrides IC_BrivSharedFunctions_Class.SetFormation()
; Overrides IC_BrivSharedFunctions_Class.BenchBrivConditions()
; Overrides IC_BrivSharedFunctions_Class.KillCurrentBoss()
class IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "")
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ])
            return base.SetFormation(settings)
        if(settings != "")
            this.Settings := settings
        ; Not refreshed if for DoDashWait() is skipped
        if (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() == "")
            this.Memory.ActiveEffectKeyHandler.Refresh()
        currentZone := this.Memory.ReadCurrentZone()
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
        ; Using click on "Clear Formation" to clear champions out the formation
        currentFormation := this.Memory.GetCurrentFormation()
        mouseClickEnabled := g_BrivUserSettingsFromAddons[ "BGFBFS_MouseClick" ]
        if (mouseClickEnabled)
        {
            if (!this.BGFBFS_IsFormationEmpty(currentFormation))
            {
                if (this.Memory.ReadTransitionOverrideSize() == 1 AND this.Memory.ReadTransitionDirection() != 2 AND this.Memory.ReadFormationTransitionDir() == 3)
                    return this.BGFBFS_MouseClickCancel(currentZone)
            }
            else if (this.Memory.ReadTransitionOverrideSize() == 1)
                return
        }
        ;check to bench briv
        if ((g_SharedData.BGFBFS_UpdateSkipAmount() != g_BrivUserSettingsFromAddons[ "BGFBFS_TargetE" ] || mouseClickEnabled && this.BGFBFS_IsFormationEmpty(currentFormation)) && this.BenchBrivConditions(this.Settings))
        {
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.BGFBFS_UpdateSkipAmount(3)
            return
        }
        ;check to unbench briv
        if ((g_SharedData.BGFBFS_UpdateSkipAmount() != g_BrivUserSettingsFromAddons[ "BGFBFS_TargetQ" ] || mouseClickEnabled && this.BGFBFS_IsFormationEmpty(currentFormation)) && this.UnBenchBrivConditions(this.Settings))
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.BGFBFS_UpdateSkipAmount(1)
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
            g_SharedData.BGFBFS_UpdateSkipAmount(2)
            this.DirectedInput(,,["{e}"]*)
            return
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        if (isFormation2 AND !isWalkZone)
        {
            g_SharedData.BGFBFS_UpdateSkipAmount(2)
            this.DirectedInput(,,["{q}"]*)
            return
        }
    }

    ; True/False on whether Briv should be benched based on game conditions.
    BenchBrivConditions(settings)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ])
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

    ; If Briv has enough stacks to jump, don't force switch to e and wait for the boss to be killed.
    KillCurrentBoss(params*)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ] || this.Memory.ReadHasteStacks() < 50)
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
        exeName := IC_BrivGemFarm_BrivFeatSwap_Functions.GetExeName()
        WinActivate, ahk_exe %exeName%
        xClick := coords[1]
        yClick := coords[2]
        MouseClick, Left, xClick, yClick, 1, 0
    }

    BGFBFS_GetClickCoords()
    {
        xOffset := yOffset := 0
        ; Fullscreen
        if (IC_BrivGemFarm_BrivFeatSwap_Functions.IsGameFullScreen())
        {
            exeName := IC_BrivGemFarm_BrivFeatSwap_Functions.GetExeName()
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
}

; Extends IC_SharedData_Class
class IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Class extends IC_SharedData_Class
{
;    BGFBFS_savedQSKipAmount
;    BGFBFS_savedWSKipAmount
;    BGFBFS_savedESKipAmount

    ; Load settings after "Start Gem Farm" has been clicked.
    BGFBFS_Init()
    {
        if (this.BGFLU_Running()) ; LevelUp addon check
            g_BrivGemFarm.base := IC_BrivGemFarm_LevelUp_Class
        this.BGFBFS_UpdateSettingsFromFile()
    }

    ; Return true if the class has been updated by the addon
    BGFBFS_Running()
    {
        return g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ]
    }

    BGFBFS_CurrentPreset()
    {
        return g_BrivUserSettingsFromAddons[ "BGFBFS_Preset" ]
    }

    ; Save current Briv jump amount.
    BGFBFS_UpdateSkipAmount(formationIndex := 0)
    {
        champID := ActiveEffectKeySharedFunctions.Briv.HeroID
        if (g_SF.IsChampInFormation(champID, g_SF.Memory.GetCurrentFormation()))
            skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        else
            skipAmount := 0
        ; Can't swap during reset
        if (g_SF.Memory.ReadResetting())
            return skipAmount
        Switch formationIndex
        {
            Case 1:
                this.BGFBFS_savedQSKipAmount := skipAmount
            Case 2:
                this.BGFBFS_savedWSKipAmount := skipAmount
            Case 3:
                this.BGFBFS_savedESKipAmount := skipAmount
            Default:
                return skipAmount
        }
        this.SwapsMadeThisRun++
    }

    ; Load settings from the GUI settings file.
    BGFBFS_UpdateSettingsFromFile(fileName := "")
    {
        if (fileName == "")
            fileName := IC_BrivGemFarm_BrivFeatSwap_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ] := settings.Enabled
        g_BrivUserSettingsFromAddons[ "BGFBFS_TargetQ" ] := settings.targetQ
        g_BrivUserSettingsFromAddons[ "BGFBFS_TargetE" ] := settings.targetE
        g_BrivUserSettingsFromAddons[ "BGFBFS_Preset" ] := settings.Preset
        g_BrivUserSettingsFromAddons[ "BGFBFS_MouseClick" ] := settings.MouseClick
    }
}