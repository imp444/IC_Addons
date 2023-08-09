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
        if (g_SF.IsCurrentFormation(g_SF.Memory.GetFormationByFavorite(2)))
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(2)
    }
}

; Overrides IC_BrivSharedFunctions_Class, check for compatibility
class IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    static BrivFeatSwap_Initialized := false

    ; Update target values from file on launch
    BrivFeatSwap_Init()
    {
        if (g_SharedData.BrivGemFarmLevelUpRunning()) ; LevelUp addon check
            IC_BrivGemFarm_BrivFeatSwap_Class.base := IC_BrivGemFarm_LevelUp_Class
        settings := this.LoadObjectFromJSON(A_LineFile . "\..\BrivGemFarm_BrivFeatSwap_Settings.json")
        if (!IsObject(settings))
            return false
        g_SharedData.UpdateTargetAmounts(settings.targetQ, settings.targetE)
        return true
    }

    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "")
    {
        if(settings != "")
        {
            this.Settings := settings
        }
        if (!this.BrivFeatSwap_Initialized) ;only send input messages if necessary
            this.BrivFeatSwap_Initialized := this.BrivFeatSwap_Init()
        if (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() == "") ; Not refreshed if for DoDashWait() is skipped
            this.Memory.ActiveEffectKeyHandler.Refresh()
        ;check to bench briv
        if (g_SharedData.BrivFeatSwap_UpdateSkipAmount() != g_BrivUserSettingsFromAddons[ "TargetE" ] AND this.BenchBrivConditions(this.Settings))
        {
            this.DirectedInput(,,["{e}"]*)
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(3)
            return
        }
        ;check to unbench briv
        if (g_SharedData.BrivFeatSwap_UpdateSkipAmount() != g_BrivUserSettingsFromAddons[ "TargetQ" ] AND this.UnBenchBrivConditions(this.Settings))
        {
            this.DirectedInput(,,["{q}"]*)
            g_SharedData.BrivFeatSwap_UpdateSkipAmount(1)
            return
        }
        ; Prevent incorrect read if Briv is the only champion leveled in Q/E (e.g. using "Level Briv/Shandie to MinLevel first" LevelUp addon option)
        if (this.Memory.ReadCurrentZone() == 1)
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
    ; Return true if the class has been updated by the addon
    BGFBFS_Running()
    {
        return true
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
    UpdateTargetAmounts(targetQ := 0, targetE := 0)
    {
        g_BrivUserSettingsFromAddons[ "TargetQ" ] := targetQ
        g_BrivUserSettingsFromAddons[ "TargetE" ] := targetE
    }
}