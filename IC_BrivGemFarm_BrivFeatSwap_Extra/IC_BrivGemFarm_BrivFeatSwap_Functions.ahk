; Functions that set affinities to processes
class IC_BrivGemFarm_BrivFeatSwap_Functions
{
    ; Adds IC_BrivGemFarm_BrivFeatSwap_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_BrivFeatSwap_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}

; Overrides IC_BrivGemFarm_Class, check for compatibility
; Checks for Briv in E formation.
class IC_BrivGemFarm_BrivFeatSwap_Class extends IC_BrivGemFarm_Class
{
    ; Tests to make sure Gem Farm is properly set up before attempting to run.
    PreFlightCheck()
    {
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
        base.StackFarmSetup(params*)
        if (g_SF.IsCurrentFormation(g_SF.Memory.GetFormationByFavorite(2)))
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
    }
}

; Overrides IC_BrivSharedFunctions_Class, check for compatibility
class IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "")
    {
        static brivBenched := ""

        if(settings != "")
        {
            this.Settings := settings
        }
        if (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() == "") ; Not refreshed if for DoDashWait() is skipped
            this.Memory.ActiveEffectKeyHandler.Refresh()
        ;only send input messages if necessary
        if (brivBenched != "" AND g_SharedData.BrivFeatSwap_savedQSKipAmount != "" AND g_SharedData.BrivFeatSwap_savedESKipAmount != "")
        {
            if (brivBenched AND g_SharedData.BrivFeatSwap_UpdateSkipAmount() == g_SharedData.BrivFeatSwap_savedQSKipAmount)
                brivBenched := false
            if (!brivBenched AND g_SharedData.BrivFeatSwap_UpdateSkipAmount() == g_SharedData.BrivFeatSwap_savedESKipAmount)
                brivBenched := true
        }
        ;check to bench briv
        if (!brivBenched AND this.BenchBrivConditions(this.Settings))
        {
            if brivBenched != ""
                g_SharedData.BrivFeatSwap_UpdateSkipAmount(1)
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.SwapsMadeThisRun++
            brivBenched := true
            return
        }
        ;check to unbench briv
        if (brivBenched AND this.UnBenchBrivConditions(this.Settings))
        {
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(3)
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.SwapsMadeThisRun++
            brivBenched := false
            return
        }
        isFormation2 := this.IsCurrentFormation(this.Memory.GetFormationByFavorite(2))
        isWalkZone := this.Settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50)] == 0
        ; check to swap briv from favorite 2 to favorite 3 (W to E)
        if (!brivBenched AND isFormation2 AND isWalkZone)
        {
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.SwapsMadeThisRun++
            brivBenched := true
            return
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        if (!brivBenched AND isFormation2 AND !isWalkZone)
        {
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.SwapsMadeThisRun++
            brivBenched := false
            return
        }
    }

    ; True/False on whether Briv should be benched based on game conditions.
    BenchBrivConditions(settings)
    {
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
}

; Overrides IC_SharedData_Class, check for compatibility
class IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Class extends IC_SharedData_Class
{
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
    }
}