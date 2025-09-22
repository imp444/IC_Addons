; Overrides IC_BrivGemFarm_Class.TestEFormation()
class IC_BrivGemFarm_BrivFeatSwap_Class extends IC_BrivGemFarm_Class
{
    ; Tests to make sure Gem Farm is properly set up before attempting to run and Briv is in E formation.
    TestEFormation()
    {
        formationE := g_SF.FindChampIDinSavedFavorite( ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 3, includeChampion := True )
        if (formationE == -1 AND this.RunChampionInFormationTests(ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 3, includeChampion := True, txtCheck) == -1)
            return -1
        return 0
    }
}

; Overrides IC_BrivSharedFunctions_Class.SetFormation()
; Overrides IC_BrivSharedFunctions_Class.KillCurrentBoss()
class IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class extends IC_SharedFunctions_Class
{
    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "", forceCheck := False)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ])
            return base.SetFormation(settings)
        if(settings != "")
            this.Settings := settings
        ; Not refreshed if for DoDashWait() is skipped
        if (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() == "")
            this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.EffectKeyString)   
        currentZone := this.Memory.ReadCurrentZone()
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
        ;check to bench briv
        if (this.BGFBFS_ShouldSwitchFormation(3))
        {
            if (this.Memory.ReadNumAttackingMonstersReached() > 10 || this.Memory.ReadNumRangedAttackingMonsters())
                this.FallBackFromZone(2000)
            base.DirectedInput(,,["{e}"]*)  ; try to switch before checking monsters to not get stuck on boss fallback.
            Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
            g_SharedData.BGFBFS_UpdateSkipAmount(3)
            return
        }
        ;check to unbench briv
        if (this.BGFBFS_ShouldSwitchFormation(1))
        {
            if (this.Memory.ReadNumAttackingMonstersReached() > 10 || this.Memory.ReadNumRangedAttackingMonsters())
                this.FallBackFromZone(2000)
            base.DirectedInput(,,["{q}"]*)
            Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
            g_SharedData.BGFBFS_UpdateSkipAmount(1)
            return
        }
        ; Prevent incorrect read if Briv is the only champion leveled in Q/E (e.g. using "Level Briv/Shandie to MinLevel first" LevelUp addon option)
        if (currentZone == 1)
            return
        if (forceCheck)
            isFormation2 := this.IsCurrentFormation(this.Memory.GetFormationByFavorite(2))
        else
            isFormation2 := this.Memory.ReadMostRecentFormationFavorite() == 2 ; (watch for fix for changing on failed swap)
        isWalkZone := this.Settings["PreferredBrivJumpZones"][Mod( this.Memory.ReadCurrentZone(), 50) == 0 ? 50 : Mod( this.Memory.ReadCurrentZone(), 50)] == 0
        ; check to swap briv from favorite 2 to favorite 3 (W to E)
        if (isFormation2 AND isWalkZone)
        {
            g_SharedData.BGFBFS_UpdateSkipAmount(2)
            base.DirectedInput(,,["{e}"]*)
            Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
            return
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        if (isFormation2 AND !isWalkZone)
        {
            g_SharedData.BGFBFS_UpdateSkipAmount(2)
            base.DirectedInput(,,["{q}"]*)
            Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
            return
        }
    }

    ; If Briv has enough stacks to jump, don't force switch to e and wait for the boss to be killed.
    KillCurrentBoss(params*)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ] || this.Memory.ReadHasteStacks() < 50)
            return base.KillCurrentBoss(params*)
        return true
    }
}

class IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Added_Class
{
    ; Check if formation switch conditions are met.
    ; Params: formationFavoriteIndex:int - 1:Q, 2:W, 3:E.
    BGFBFS_ShouldSwitchFormation(formationFavoriteIndex)
    {
        if (formationFavoriteIndex == 1)
            return (!IC_BrivGemFarm_BrivFeatSwap_Functions.BrivFunctions.CurrentFormationMatchesBrivConfig(1) && this.UnBenchBrivConditions(this.Settings))
        else if (formationFavoriteIndex == 3)
            return (!IC_BrivGemFarm_BrivFeatSwap_Functions.BrivFunctions.CurrentFormationMatchesBrivConfig(3) && this.BenchBrivConditions(this.Settings))
        return false
    }

    ; Returns true if there are no champions in the current formation.
    BGFBFS_IsFormationEmpty(formation)
    {
        for k, v in formation
            if (v != -1)
                return false
        return true
    }   
}

class IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Added_Class ;Added to IC_SharedData_Class
{
;    BGFBFS_savedQSKipAmount
;    BGFBFS_savedWSKipAmount
;    BGFBFS_savedESKipAmount

    ; Load settings after "Start Gem Farm" has been clicked.
    BGFBFS_Init()
    {
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
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        if (skipChance == 0)
            skipAmount -= 1
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
        g_BrivUserSettingsFromAddons[ "BGFBFS_Preset" ] := settings.Preset
        g_BrivGemFarm.Settings[ "FeatSwapEnabled" ] := g_BrivUserSettingsFromAddons[ "BGFBFS_Enabled" ]
    }
}