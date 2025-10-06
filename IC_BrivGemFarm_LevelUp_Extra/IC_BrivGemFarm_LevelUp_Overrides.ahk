; Overrides IC_BrivGemFarm_Class.GemFarmDoZone()
; Overrides IC_BrivGemFarm_Class.GemFarmPreLoopSetup()
; Overrides IC_BrivGemFarm_Class.GemFarmResetSetup()
; Overrides IC_BrivGemFarm_Class.GemFarmDoNonModronActions()
; Overrides IC_BrivGemFarm_Class.StackFarmSetup()
class IC_BrivGemFarm_LevelUp_Class extends IC_BrivGemFarm_Class
{
    ;=====================================================
    ;Primary Functions for Briv Gem Farm
    ;=====================================================
    GemFarmDoZone(formationModron := "")
    {
        this.DoKeySpam := False
        base.GemFarmDoZone(formationModron)
    }
    
    GemFarmPreLoopSetup()
    {
        isFailed := base.GemFarmPreLoopSetup(True)
        if(!isFailed)
        {
            g_SF.BGFLU_CalcLastUpgradeLevels()
            g_SharedData.BGFLU_UpdateSettingsFromFile(true)
            g_SharedData.BGFLU_SaveFormations()
        }
        return isFailed
    }

    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
        g_SharedData.BGFLU_SetStatus("Leveling champions to the minimum level")
        this.SetupMaxDone := false
        this.SetupFailedConversionDone := true
        resetsCount := base.GemFarmResetSetup(formationModron, doBasePartySetup := False)
        if(this.GemFarmShouldSetFormation())
            g_SF.SetFormationForStart()
        this.BGFLU_DoPartySetupMin(g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivShandie" ])
        this.BGFLU_DoPartyWaits(formationModron)
        return resetsCount
    }

    GemFarmDoNonModronActions(currentZone := "")
    {
        needToStack := this.BGFLU_NeedToStack()
        ; Level up Briv to MaxLevel after stacking
        if (!needToStack AND g_SF.Memory.ReadChampLvlByID(ActiveEffectKeySharedFunctions.Briv.HeroID) < g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ].maxLevels[58])
            this.SetupMaxDone := false
        ; Check for failed stack conversion
        if (g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversion" ] AND g_SF.Memory.ReadHasteStacks() < 50 AND needToStack)
            this.SetupFailedConversionDone := false
        if (!this.SetupMaxDone AND currentZone > 5) ; ignore doing max at setup since this method runs first.
            this.SetupMaxDone := this.BGFLU_DoPartySetupMax() ; Level up all champs to the specified max level
        else if (!this.SetupFailedConversionDone)
            this.SetupFailedConversionDone := this.BGFLU_DoPartySetupFailedConversion() ; Level up all champs to soft cap (including Briv if option checked)
        if (g_SharedData.BGFLU_UpdateMaxLevels)
        {
            this.SetupMaxDone := false
            g_SharedData.BGFLU_UpdateMaxLevels := false
            ; Stop click spam
            if (!g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ])
                g_SF.BGFLU_StopSpamClickDamage()
        }
        ; Click damage
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
            g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel())
    }

    ; Stops progress and switches to appropriate party to prepare for stacking Briv's SteelBones.
    StackFarmSetup()
    {
        g_SharedData.LoopString := "Switching to stack farm formation."
        if (!g_SF.KillCurrentBoss() ) ; Previously/Alternatively FallBackFromBossZone()
            g_SF.FallBackFromBossZone() ; Boss kill Timeout
        inputValues := "{w}" ; Stack farm formation hotkey
        g_SF.DirectedInput(,, inputValues )
        keyspam := this.BGFLU_GetMinLevelingKeyspam(g_SF.Memory.GetFormationByFavorite(2))
        g_SF.WaitForTransition( inputValues )
        g_SF.DirectedInput(,, keyspam*)
        g_SF.ToggleAutoProgress( 0 , false, true )
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 50
        g_SharedData.LoopString := "Setting stack farm formation."
        stackFormation := g_SF.Memory.GetFormationByFavorite(2)
        isFormation2 := g_SF.Memory.ReadMostRecentFormationFavorite() == 2 AND g_SF.IsCurrentFormation(stackFormation)
        if (!isFormation2)
        {
            g_SF.DirectedInput(,,inputValues)
            isFormation2 := g_SF.Memory.ReadMostRecentFormationFavorite() == 2
            if(!isFormation2 AND g_SF.IsCurrentFormation(stackFormation))
                isFormation2 := True
        }
        while (!g_SF.IsCurrentFormation(stackFormation) AND ElapsedTime < 5000 )
        {
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > (counter * sleepTime)) ; input limiter..
            {
                g_SF.DirectedInput(,,inputValues)
                counter++
            }
            ; Can't formation switch when under attack.
            if (ElapsedTime > 1000 && g_SF.Memory.ReadNumAttackingMonstersReached() > 10 || g_SF.Memory.ReadNumRangedAttackingMonsters())
                g_SF.FallBackFromZone()
            else
                this.BGFLU_DoPartySetupMax(stackFormation)
            Sleep, 20
        }
        while (!this.BGFLU_DoPartySetupMax(stackFormation) AND (A_TickCount - StartTime) < 5000)
           Sleep, 30
        return
    }
}

class IC_BrivGemFarm_LevelUp_Added_Class ; Added to IC_BrivGemFarm_Class
{
    /*  BGFLU_DoPartySetupMin - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                          This will only level champs to the minium target specified in BrivGemFarm_LevelUp_Settings.json.
                          This will not level champs whose minimum level is set to 0.
                          It will wait for Shandie dash / Thellora Rush if necessary.
                          It will only level up at a time the number of champions specified in the MaxSimultaneousInputs setting.
        Parameters:       forceBrivShandie: bool - If true, force Briv/Shandie to minLevel before leveling other champions
                          timeout: integer - Time in ms before abandoning the initial leveling

        Returns:
    */
    BGFLU_DoPartySetupMin(forceBrivShandie := false, timeout := 5000)
    {
        currentZone := g_SF.Memory.ReadCurrentZone()
        if (forceBrivShandie || currentZone == 1)
            g_SF.ToggleAutoProgress( 0, false, true )
        formation := g_SF.GetInitialFormation()
        ; If low favor mode is active, cheapeast upgrade first
        lowFavorMode := g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ]
        ; Level up speed champs first, priority to getting Briv, Shandie, Hew Maan, Nahara, Sentry, Virgil speed effects
        ; Set formation
        g_SF.SetFormationForStart()
        StartTime := A_TickCount
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            keyspam := this.BGFLU_DoPartySetupMin_NoLowFavor(formation, forceBrivShandie, timeout, currentZone)
        if(keyspam)
            remainingTime := timeout
        else
            remainingTime := timeout - (A_TickCount - StartTime)
        g_SF.DirectedInput(hold := 0,, keyspam*) ; keysup
        if (forceBrivShandie AND remainingTime > 0)
            this.BGFLU_DoPartySetupMin(false, remainingTime)
        if (currentZone == 1 || g_SharedData.TriggerStart)
            g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel(), Max(remainingTime, 2000))
        ; Click damage (should be enough to kill monsters at the area Thellora jumps to unless using x1)
        g_SF.ToggleAutoProgress( 1, false, true )
        return results
    }

    BGFLU_DoPartySetupMin_NoLowFavor(formation, forceBrivShandie := false, timeout := "", currentZone := 1)
    {
        StartTime := A_TickCount, ElapsedTime := 0
        if (timeout == "")
            timeout := g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ]
        timeout := timeout == "" ? 5000 : timeout
        keyspam := {}
        keyspam.Push("")
        loopCount := 0
        allowClick := False
        while(keyspam.Length() != 0 AND ElapsedTime < timeout)
        {
            if(loopCount > 2)
                allowClick := True
            keyspam := this.BGFLU_DoPartySetupMinInnerLoop_NoLowFavor(formation, forceBrivShandie, currentZone, allowClick)
            loopCount++
            ElapsedTime := A_TickCount - StartTime
        }
        return keyspam
    }

    BGFLU_DoPartySetupMinInnerLoop_NoLowFavor(formation, forceBrivShandie := false, currentZone := 1, allowClick := True)
    {
            keyspam := {}
            ; Update formation on zone change
            if (currentZone < g_SF.Memory.ReadCurrentZone())
            {
                currentZone := g_SF.Memory.ReadCurrentZone()
                formation := g_SF.GetInitialFormation()
            }
            if (g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            {
                formationInOrder := this.BGFLU_OrderByCheapeastUpgrade(formation)
                keyspam := this.BGFLU_GetMinLevelingKeyspamLowFavor(formationInOrder, forceBrivShandie)
            }
            else
                keyspam := this.BGFLU_GetMinLevelingKeyspam(formation, forceBrivShandie)
            ; Level up speed champions once
            g_SF.DirectedInput(,, keyspam*)
            ; Set formation
            g_SF.SetFormationForStart()
            Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
            if(allowClick OR currentZone > 1)
            {
                if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
                    g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel())
                g_SF.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
            }
            return keyspam
    }

    BGFLU_DoPartyWaits(formation)
    {
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] AND g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        if (g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Thellora.HeroID, formation))
            g_SF.DoRushWait()
    }

    ; Returns a list of FKeys that are spammed during min leveling.
    ; Params: formation:array - List of champion IDs.
    ;         forceBrivShandie:bool - If true, only Briv and Shandie are leveled.

    BGFLU_GetMinLevelingKeyspam(formation, forceBrivShandie := false)
    {
        keyspam := []
        ; List of champion IDs
        if (forceBrivShandie)
        {
            champIDs := [ Briv := 58
                        , Ellywick := 83 
                        , Widdle := 91]
        }
        else
        {
            champIDs := [ Briv := 58
                        , Widdle := 91
                        , Ellywick := 83
                        , HewMaan := 75
                        , Tatyana := 97
                        , Melf := 59
                        , Dynaheir := 145
                        , Diana := 14
                        , Laezel  := 128
                        , Deekin := 28
                        , Virgil := 115
                        , Sentry := 52
                        , Nahara := 102
                        , BBEG  := 125
                        , Dhani := 89
                        , Kent := 114
                        , Gazrick := 98
                        , Alyndra := 79
                        , Selise := 81
                        , Vi := 95
                        , Havilar := 56
                        , Shandie := 47
                        , Thellora := 139
                        , Baldric := 165 ]
        }
        ; Need to walk while Briv is in all formations
        if (!this.BGFLU_AllowBrivLeveling())
            champIDs.RemoveAt(1)
        if (!forceBrivShandie)
        {
            nonSpeedIDs := {}
            for k, champID in formation
            {
                ; Need to walk while Briv is in all formations
                if (champID == 58 && !this.BGFLU_AllowBrivLeveling())
                    continue
                if (champID != -1 && champID != "")
                    nonSpeedIDs[champID] := champID
            }
        }
        ; Get Fkeys for speed champs
        while (keyspam.Length() < g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ])
        {
            for k, champID in champIDs
            {
                if (g_SF.IsChampInFormation(champID, formation))
                {
                    if (this.BGFLU_ChampUnderTargetLevel(champID, this.BGFLU_GetTargetLevel(champID, "Min")) AND (champID == this.SelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID))))
                        keyspam.Push(this.BGFLU_GetFKey(champID))
                    if (!forceBrivShandie)
                        nonSpeedIDs.Delete(champID)
                }
            }
            if (keyspam.Length() == 0) ; no champs to add, length cannot reach MaxSimultaneousInputs > 0 here.
                break
        }
        ; Get Fkeys for other champs
        if (!forceBrivShandie)
        {
            for k, champID in nonSpeedIDs
            {
                if (this.BGFLU_ChampUnderTargetLevel(champID, this.BGFLU_GetTargetLevel(champID, "Min")) AND (champID == this.SelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID))))
                    keyspam.Push(this.BGFLU_GetFKey(champID))
            }
        }
        return keyspam
    }

    ; Returns a list of FKeys that are spammed during min leveling.
    ; The low favor version doesn't use the priority list of speed champions,
    ; rather the list of champions ordered by lowest upgrade cost first.
    ; If a champion upgrade can't be afforded, the champion won't be leveled up.
    ; Params: formation:array - List of champion IDs.
    ;         forceBrivShandie:bool - If true, only Briv and Shandie are leveled.
    BGFLU_GetMinLevelingKeyspamLowFavor(formation, forceBrivShandie := false)
    {
        keyspam := []
        if (forceBrivShandie)
        {
            champIDs := []
            for k, champID in formation
            {
                ; Need to walk while Briv is in all formations
                if (champID == 58 && this.BGFLU_AllowBrivLeveling())
                    champIDs.Push(champID)
                else if (champID == 47)
                    champIDs.Push(champID)
            }
            formation := champIDs
        }
        for k, champID in formation
            if (this.BGFLU_ChampUnderTargetLevel(champID, this.BGFLU_GetTargetLevel(champID, "Min")))
                if this.BGFLU_CanAffordUpgrade(champID)
                    keyspam.Push(this.BGFLU_GetFKey(champID))
        return keyspam
    }

    /*  BGFLU_DoPartySetupMax - Level up all champs to the specified max level.
        This will not level champs whose maximum level is set at 0.
        Returns: bool - True if all champions in Q formation are at or past their target level, false otherwise.
    */
    BGFLU_DoPartySetupMax(formation := "")
    {
        ; Speed champions without Briv
        static champIDs := [ Briv := 58
                        , Widdle := 91
                        , Ellywick := 83
                        , HewMaan := 75
                        , Tatyana := 97
                        , Melf := 59
                        , Dynaheir := 145
                        , Diana := 14
                        , Laezel  := 128
                        , Deekin := 28
                        , Virgil := 115
                        , Sentry := 52
                        , Nahara := 102
                        , BBEG  := 125
                        , Dhani := 89
                        , Kent := 114
                        , Gazrick := 98
                        , Alyndra := 79
                        , Selise := 81
                        , Vi := 95
                        , Havilar := 56
                        , Shandie := 47
                        , Thellora := 139 ]
        levelupx10 := {} ; Not implemented yet
        levelupx25 := {}
        levelBriv := true ; Return value
        if (!formation)
            formation := g_SF.GetInitialFormation()
        else
            formation := this.BGFLU_GetFormationNoEmptySlots(formation)
        if (this.BGFLU_ChampUnderTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, this.BGFLU_GetTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, "Min")))
        {
            levelBriv := false
            if (this.BGFLU_AllowBrivLeveling()) ; Level Briv to be able to skip areas
                this.BGFLU_DoPartySetupMin_NoLowFavor(formation, forceBrivShandie := True) ; this.BGFLU_DoPartySetupMin(true)
            else
                levelBriv := false
        }
        ; Speed champions are leveled up first (without Briv)
        ; If low favor mode is active, cheapeast upgrade first
        if (g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            formation := this.BGFLU_OrderByCheapeastUpgrade(formation)
        else
            for k, champID in champIDs
                ;if (g_SF.IsChampInFormation(champID, formation) AND this.BGFLU_LevelUpChamp(champID, this.BGFLU_GetTargetLevel(champID)))
                    ;return false
                if (g_SF.IsChampInFormation(champID, formation))
                {
                    targetLevel := this.BGFLU_GetTargetLevel(champID)
                    targetLevelMod := Mod(this.BGFLU_GetTargetLevel(champID), 100)
                    if (targetLevelMod > 0 && this.BGFLU_ChampUnderTargetLevel(champID, targetLevel))
                    {
                        levelupx25[champId] := targetLevel
                        targetLevel := targetLevel - targetLevelMod
                    }
                    if (champID == this.SelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID)) && this.BGFLU_LevelUpChamp(champID, targetLevel))
                        return false
                }
        ; Now do x25 levelling.
        if (this.ArrSize(levelupx25) > 0)
        {
            levelBriv := false
            this.ToggleControl(true) ; To go back to x10 - change to ToggleShift
            for champID, targetLevel in levelupx25
            {
                champSeat := g_SF.Memory.ReadChampSeatByID(champID)
                champIDInSeat := this.SelectedChampIDBySeat(champSeat)
                if (champID != champIDInSeat)
                    continue
                if (this.BGFLU_LevelUpChamp(champID, targetLevel))
                {
                    this.ToggleControl()
                    return false
                }
            }
            this.ToggleControl()
        }
        else
            levelBriv := true                    
        ; Complete leveling
        for k, champID in formation
        {
            champSeat := g_SF.Memory.ReadChampSeatByID(champID)
            champIDInSeat := this.SelectedChampIDBySeat(champSeat)
            if (champID != champIDInSeat)
                continue
            targetLevel := this.BGFLU_GetTargetLevel(champID)
            targetLevelMod := Mod(targetLevel, 100)
            if (targetLevelMod > 0 && this.BGFLU_ChampUnderTargetLevel(champID, targetLevel))
            {
                levelupx25[champId] := targetLevel
                targetLevel := targetLevel - targetLevelMod
            }
            ; Briv
            if (champID == 58)
            {
                if (!levelBriv)
                    continue
                ; Level up Briv to BrivMinLevelStacking before stacking
                if (this.BGFLU_NeedToStack())
                    targetLevel := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStacking" . (g_BrivGemFarm.ShouldOfflineStack() ? "" : "Online") ]
            }
            if (this.BGFLU_LevelUpChamp(champID, targetLevel))
                return false
        }
        if (levelBriv)
            g_SharedData.BGFLU_SetStatus("All champions leveled up.")
        return levelBriv
    }

        
    ToggleShift(shiftKeyDown := false)
    {
        g_SF.DirectedInput(shiftKeyDown ? 1 : 0, shiftKeyDown ? 0 : 1, "{Shift}")
        startTime:=A_TickCount
        elapsedTime:=0
        while (g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes[0].levelUpInfoHandler.OverrideLevelUpAmount.Read()!=shiftKeyDown AND elapsedTime < 100) ;Allow 100ms for the keypress to apply at maximum to avoid getting stuck. On a fast PC it only took AHK tick (15ms) extra when needed
        {
            Sleep 1
            elapsedTime:=A_TickCount - startTime
        }
    }
    
    ToggleControl(controlKeyDown := false)
    {
        g_SF.DirectedInput(controlKeyDown ? 1 : 0, controlKeyDown ? 0 : 1, "{RCtrl}")
        startTime:=A_TickCount
        elapsedTime:=0
        while (g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes[0].levelUpInfoHandler.OverrideLevelUpAmount.Read()!=controlKeyDown AND elapsedTime < 100) ;Allow 100ms for the keypress to apply at maximum to avoid getting stuck. On a fast PC it only took AHK tick (15ms) extra when needed
        {
            Sleep 1
            elapsedTime:=A_TickCount - startTime
        }
    }
    
    SelectedChampIDBySeat(seat)
    {
        return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes[seat - 1].hero.def.ID.Read()
    }
    
    ArrSize(arr)
    {
        if (IsObject(arr))
        {
            CDP_currArrSize := arr.MaxIndex()
            if (CDP_currArrSize == "")
                return 0
            return CDP_currArrSize
        }
        return 0
    }

    /*  BGFLU_DoPartySetupFailedConversion - Level up all champs to soft cap after a failed conversion.
        If the setting LevelToSoftCapFailedConversionBriv is set to true, also level Briv.

        Returns: bool - True if all champions in Q formation are soft capped, false otherwise
    */
    BGFLU_DoPartySetupFailedConversion(formation := "")
    {
        if (!formation)
            formation := g_SF.GetInitialFormation()
        else
            formation := this.BGFLU_GetFormationNoEmptySlots(formation)
        if (g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            formation := this.BGFLU_OrderByCheapeastUpgrade(formation)
        for k, champID in formation
            if (g_SF.IsChampInFormation(champID, formation) AND (champID != 58 OR g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversionBriv" ]))
                if (this.BGFLU_LevelUpChamp(champID, g_SF.BGFLU_GetLastUpgradeLevel(champID)))
                    return false
        g_SharedData.BGFLU_SetStatus("Finished leveling champions.")
        return true
    }

    ; Returns the minimum / maximum level a champion should be leveled at.
    ; Params: champID:int - ID of the champion.
    ;         minOrMax:str - If equal to "Min", level up the champion to minLevel,
    ;                        or to 0 or 1 depending on default settings.
    ;                        If equal to "Max", level up the champion to maxLevel,
    ;                        or to 1 or last upgrade depending on default settings.
    BGFLU_GetTargetLevel(champID := 0, minOrMax := "Max")
    {
        if (champID < 1)
            return 0
        levelSettings := g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ]
        if (minOrMax == "Min")
        {
            if (levelSettings.minLevels[champID] != "")
                return levelSettings.minLevels[champID]
            minLevel := g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMinLevel" ]
            return (minLevel == "") ? 0 : minLevel
        }
        else if (minOrMax == "Max")
        {
            if (levelSettings.maxLevels[champID] != "")
                return levelSettings.maxLevels[champID]
            maxLevel := g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMaxLevel" ]
            if (maxLevel == "Last")
                return g_SF.BGFLU_GetLastUpgradeLevel(champID)
            else
                return (maxLevel == "") ? 1 : maxLevel
        }
        else
            return 0
    }

    ; Returns true if the champion needs to be leveled.
    BGFLU_ChampUnderTargetLevel(champID := 0, target := 0)
    {
        if (champID < 1)
            return false
        if target is not integer
            return false
        return target != 0 && g_SF.Memory.ReadChampLvlByID(champID) < target
    }

    ; Returns the target value for click damage level.
    ; Min click damage value should be 1 after resetting.
    BGFLU_GetClickDamageTargetLevel()
    {
        setting := g_BrivUserSettingsFromAddons[ "BGFLU_MinClickDamage" ]
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
            return Max(setting, ((highestLvl := g_SF.Memory.ReadHighestZone()) > 1000 ? highestLvl + 100 : highestLvl))
        return Max(1, setting)
    }

    ; Returns true if stacking Briv is necessary during this run.
    BGFLU_NeedToStack()
    {
        stacks := this.GetNumStacksFarmed()
        return stacks < g_BrivUserSettings[ "TargetStacks" ]
    }

    ; List of conditions that enable or disable Briv leveling.
    ; If Briv is under level 80, he can't jump. Then walking is possible even
    ; Briv is in the field formation, e.g. for feat swapping.
    BGFLU_AllowBrivLeveling()
    {
        ; Briv can't skip zones if he has under 50 stacks
        if (g_SF.Memory.ReadHasteStacks() < 50)
            return true
        highestZone := g_SF.Memory.ReadHighestZone()
        brivMinLevelArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ]
        if (highestZone < brivMinLevelArea)
            return false
        ; Wait for transition to highestZone before leveling during DoRushWait()
        if (highestZone == brivMinLevelArea && !g_SF.Memory.ReadTransitioning())
        {
            if (g_SF.Memory.ReadCurrentZone() < highestZone)
                return false
        }
        mod50Index := Mod(highestZone, 50) == 0 ? 50 : Mod(highestZone, 50)
        mod50Zones := g_BrivUserSettingsFromAddons[ "BGFLU_BrivLevelingZones" ]
        if (mod50Zones[mod50Index] == 0 && this.BGFLU_ChampUnderTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, 80))
            return false
        return true
    }

    ; Returns the list of champion IDs sorted by cheapast upgrade first.
    ; Params: champIDs:array - List of champion IDs.
    ;         num:int - Number of champions that need to be returned.
    BGFLU_GetCheapeastUpgrade(champIDs, num := 1)
    {
        if (num == 1 && champIDs.Length() == num)
            return champIDs
        cheapest := []
        costs := {}
        for k, champID in champIDs
        {
            if (champID < 1)
                continue
            seat := g_SF.Memory.ReadChampSeatByID(champID)
            cost := g_SF.Memory.ReadLevelUpCostBySeat(seat)
            i := IC_BrivGemFarm_LevelUp_Functions.ConvertNumberStringToInt(cost)
            costs[i] := champID
        }
        for k, v in costs
        {
            if (num-- < 1)
                break
            cheapest.Push(v)
        }
        return cheapest
    }

    BGFLU_OrderByCheapeastUpgrade(formation)
    {
        return this.BGFLU_GetCheapeastUpgrade(formation, formation.Length())
    }

    BGFLU_GetFormationNoEmptySlots(formation)
    {
        ids := []
        for k, champID in formation
        {
            if (champID > 0)
                ids.Push(champID)
        }
        return ids
    }

    BGFLU_LevelUpChamp(champID, target)
    {
        if (this.BGFLU_ChampUnderTargetLevel(champID, target))
        {
            ; Level up a single champion once
            text := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to the maximum level (" . target . ")"
            g_SharedData.BGFLU_SetStatus(text)
            g_SF.DirectedInput(,, this.BGFLU_GetFKey(champID))
            return true
        }
        return false
    }

    BGFLU_GetFKey(champID)
    {
        if (champID < 1)
            return ""
        return "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}"
    }

    BGFLU_CanAffordUpgrade(champID)
    {
        if (champID < 1)
            return false
        seat := g_SF.Memory.ReadChampSeatByID(champID)
        cost := g_SF.Memory.ReadLevelUpCostBySeat(seat)
        gold := g_SF.Memory.ReadGoldString()
        compareIntCost := IC_BrivGemFarm_LevelUp_Functions.ConvertNumberStringToInt(cost)
        compareIntGold := IC_BrivGemFarm_LevelUp_Functions.ConvertNumberStringToInt(gold)
        return compareIntCost < compareIntGold
    }
}

; Overrides IC_BrivSharedFunctions_Class.GetInitialFormation()
; Overrides IC_BrivSharedFunctions_Class.DoRushWait()
; Overrides IC_BrivSharedFunctions_Class.InitZone()
; Overrides IC_SharedFunctions_Class.DoDashWaitingIdling()
; Overrides IC_SharedFunctions_Class.SetFormationForStart()
class IC_BrivGemFarm_LevelUp_SharedFunctions_Class extends IC_SharedFunctions_Class
{
    ; Special case for Thellora+Briv combined jump on z1 if z1 is set to walk in advanced settings.
    GetInitialFormation()
    {
        currentZone := this.Memory.ReadCurrentZone()
        if (currentZone == 1)
        {
            Switch this.BGFLU_GetZ1FormationKey()
            {
                case "q":
                    favorite := 1
                case "w":
                    favorite := 2
                case "e":
                    favorite := 3
                default:
                    favorite := 1
            }
        }
        else
        {
            settings := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
            mod50Index := Mod(currentZone, 50) == 0 ? 50 : Mod(currentZone, 50)
            favorite := settings[mod50Index] ? 1 : 3
        }
        ; Without empty slots
        return this.Memory.GetFormationSaveBySlot(this.Memory.GetSavedFormationSlotByFavorite(favorite), true)
    }

    DoDashWaitingIdling(startTime := 1, estimate := 1)
    {
        this.ToggleAutoProgress(0)
        this.SetFormationForStart()
        g_BrivGemFarm.BGFLU_DoPartySetupMax()
        this.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
        ElapsedTime := A_TickCount - StartTime
        g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
        percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10 + 15), 15)
        Sleep, %percentageReducedSleep%
    }

    ; Special case for Thellora+Briv combined jump on z1 if z1 is set to walk in advanced settings.
    SetFormationForStart()
    {
        if (this.Memory.ReadCurrentZone() == 1 AND "q" != (key := this.BGFLU_GetZ1FormationKey())) ; walk formation exception
            this.DirectedInput(,, "{" . key . "}") ; do before check ?
        else if ( this.Memory.ReadCurrentZone() == 1 )
            return
        else 
            this.SetFormation(g_BrivUserSettings)
    }

    BGFLU_SecondWindActive()
    {
        feats := this.Memory.GetHeroFeats(ActiveEffectKeySharedFunctions.Shandie)
        for k, v in feats
            if (v == 1035)
                return true
        return false
    }

    DoRushWaitIdling(StartTime, estimate)
    {
        this.ToggleAutoProgress(0)
        this.SetFormationForStart()
        g_BrivGemFarm.BGFLU_DoPartySetupMax()
        this.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
        ElapsedTime := A_TickCount - StartTime
        g_SharedData.LoopString := "Rush Wait: " . ElapsedTime . " / " . estimate
        Sleep, 30
        return ElapsedTime
    }

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        Critical, On
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ])
        {
            ; Level up click damage once
            this.BGFLU_DoClickDamageSetup(1)
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
}

class IC_BrivGemFarm_LevelUp_SharedFunctions_Added_Class ; Added to IC_BrivSharedFunctions_Class
{
;    BGFLU_LastUpgradeLevelByID := ""

    BGFLU_GetZ1FormationKey()
    {
        z1Formation := g_BrivUserSettingsFromAddons[ "BGFLU_FavoriteFormationZ1" ]
        if (z1Formation == "")
            z1Formation := "q"
        z1Formation := Format("{:L}", z1Formation)
        return z1Formation
    }

    ; LevelUp click damage.
    ; Depending on the <NoCtrlKeypress> setting, uses either in-game settings or x100.
    ; Params: numClicks:int - Number of clicks on level click damage.
    ;                         If set to 0, levels up to clickLevel.
    ;         clickLevel:int - If set at higher than 0, click damage is leveled up to this value.
    ;                          If numClicks is set at 1, will exit after 1 click.
    ;         timeout:int - Maximum waiting time.
    BGFLU_DoClickDamageSetup(numClicks := 0, clickLevel := 0, timeout := 100)
    {
        ; Don't level up click damage if the is not enough gold for at least one upgrade.
        maxAmount := g_SF.Memory.BGFLU_ReadClickLevelUpAllowed()
        if (maxAmount == 0)
            return true
        if (clickLevel > 0)
        {
            if (this.Memory.ReadClickLevel() >= clickLevel)
                return true
            if (numClicks == 1)
                return this.BGFLU_LevelClickDamage(1)
            StartTime := A_TickCount
            ElapsedTime := 0
            while (this.Memory.ReadClickLevel() < clickLevel && ElapsedTime < timeout)
            {
                ; Stop leveling up if not enough gold for a full upgrade.
                maxAmount := g_SF.Memory.BGFLU_ReadClickLevelUpAllowed()
                this.BGFLU_LevelClickDamage(1)
                levelUpAmount := g_SF.Memory.ReadLevelUpAmount()
                if (levelUpAmount > 1 && maxAmount < levelUpAmount)
                    return true
                ElapsedTime := A_TickCount - StartTime
            }
            return true
        }
        else if (numClicks > 0)
            this.BGFLU_LevelClickDamage(numClicks)
    }

    ; Level up click damage.
    ; Depending on the <NoCtrlKeypress> setting, uses either in-game settings or x100.
    ; Params: numClicks:int - Number of clicks on level click damage.
    BGFLU_LevelClickDamage(numClicks := 1)
    {
        Critical, On
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
        Critical, Off
    }

    ; Stop click damage input.
    BGFLU_StopSpamClickDamage()
    {
        Critical, On
        if (g_UserSettings[ "NoCtrlKeypress" ])
            this.DirectedInput(hold := 0,, "{ClickDmg}") ;keysup
        else
            this.DirectedInput(hold := 0,, ["{ClickDmg}","{RCtrl}"]*) ;keysup
        Critical, Off
    }

    ; Retrieves the required level of the last upgrade of a champion.
    BGFLU_GetLastUpgradeLevel(champID)
    {
        if (champID == "" || champID < 1)
            return 0
        ; Look for value in cache.
        ; The actual value could change because of definitions being updated
        ; when a new event starts, balance patch or level cap increase.
        cachedLevels := this.BGFLU_LastUpgradeLevelByID
        if !IsObject(cachedLevels)
            this.BGFLU_LastUpgradeLevelByID := cachedLevels := {}
        if (cachedLevels.HasKey(champID) && cachedLevels[champID] != "")
            return cachedLevels[champID]
        ; Loop upgrades until the upgrade with the highest level is found.
        size := this.Memory.ReadHeroUpgradesSize(champID)
        ; Sanity check
        if (size < 1 || size > 1000)
            return 0
        maxUpgradeLevel := 0
        Loop, %size%
        {
            requiredLevel := this.Memory.ReadHeroUpgradeRequiredLevel(champID, A_Index - 1)
            if (requiredLevel != 9999)
                maxUpgradeLevel := Max(requiredLevel, maxUpgradeLevel)
        }
        cachedLevels[champID] := maxUpgradeLevel
        return maxUpgradeLevel
    }
}

class IC_BrivGemFarm_LevelUp_IC_SharedData_Added_Class ; Added to IC_SharedData_Class
{
;    BGFLU_Status := ""
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

    BGFLU_SetStatus(text := "")
    {
        this.BGFLU_Status := text
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
        g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMinLevel" ] := settings.DefaultMinLevel
        g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMaxLevel" ] := settings.DefaultMaxLevel
        g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivShandie" ] := settings.ForceBrivShandie
        g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] := settings.SkipMinDashWait
        g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ] := settings.MaxSimultaneousInputs
        g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ] := settings.MinLevelInputDelay
        g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ] := settings.MinLevelTimeout
        g_BrivUserSettingsFromAddons[ "BGFLU_FavoriteFormationZ1" ] := settings.FavoriteFormationZ1
        g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ] := settings.LowFavorMode
        g_BrivUserSettingsFromAddons[ "BGFLU_MinClickDamage" ] := settings.MinClickDamage
        g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ] := settings.ClickDamageMatchArea
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

class IC_BrivGemFarm_LevelUp_IC_MemoryFunctions_Added_Class ; Added to IC_MemoryFunctions_Class
{
    BGFLU_ReadClickLevelUpAllowed()
    {
        value := this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.clickDamageBox.maxLevelUpAllowed.Read()
        return value == "" ? 1 : value
    }
}