; Overrides IC_BrivGemFarm_Class.TestForSteelBonesStackFarming()
; Overrides IC_BrivGemFarm_Class.ShouldOfflineStack()
; Overrides IC_BrivGemFarm_Class.GemFarmResetSetup()
; Overrides IC_BrivGemFarm_Class.GetNumStacksFarmed()
; Overrides IC_BrivGemFarm_Class.StackRestart()
; Overrides IC_BrivGemFarm_Class.StackNormal()
class IC_BrivGemFarm_HybridTurboStacking_Class extends IC_BrivGemFarm_Class
{
    static WARDEN_ID := 36
    static MELF_ID := 59
   BGFHTS_DelayedOffline := false
   BGFHTS_LastOfflineReset := 0

    ; Stacking offline uses g_BrivUserSettings[ "StackZone" ].
    ; While online uses BGFHTS_MelfMinStackZone.
    TestForSteelBonesStackFarming()
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ] || this.ShouldOfflineStack())
            return base.TestForSteelBonesStackFarming()
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ])
            return base.TestForSteelBonesStackFarming()
        ; If no Melf +spawn effect until reset, stack offline.
        range := g_SharedData.BGFHTS_CurrentRunStackRange
        if (range[1] == "" || range[2] == "")
            return base.TestForSteelBonesStackFarming()
        ; Use Melf Min StackZone settings.
        savedStackZone := g_BrivUserSettings[ "StackZone" ]
        g_BrivUserSettings[ "StackZone" ] := g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMinStackZone" ] - 1
        r := base.TestForSteelBonesStackFarming()
        g_BrivUserSettings[ "StackZone" ] := savedStackZone
        return r
    }

    ; Determines if offline stacking is expected with current settings and conditions.
    ShouldOfflineStack()
    {
        shouldOfflineStack := base.ShouldOfflineStack()
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ])
            return shouldOfflineStack
        ; If no Melf +spawn effect until reset, stack offline.
        range := g_SharedData.BGFHTS_CurrentRunStackRange
        if ((range[1] == "" || range[2] == "") && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 2)
            return True
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunDelayOffline" ])
            return shouldOfflineStack
        ; Delay offline until last restart for multiple runs.
        targetStacks := g_BrivUserSettings[ "TargetStacks" ]
        combinedStacks := g_SF.Memory.ReadHasteStacks() + g_SF.Memory.ReadSBStacks()
        if (shouldOfflineStack)
        {
            resetCount := g_SF.Memory.ReadResetsCount()
            if (lastOfflineReset == resetCount)
                return False
            lastOfflineReset := this.BGFHTS_LastOfflineReset
            this.BGFHTS_LastOfflineReset := resetCount
            if (!this.BGFHTS_DelayedOffline && combinedStacks >= targetStacks && resetCount != lastOfflineReset)
            {
                this.BGFHTS_DelayedOffline := True
                return False
            }
        }
        if (this.BGFHTS_DelayedOffline && combinedStacks < targetStacks)
        {
            this.BGFHTS_DelayedOffline := False
            return True
        }
        return shouldOfflineStack && !this.BGFHTS_DelayedOffline
    }

    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
            g_SharedData.BGFHTS_UpdateMelfStackZoneAfterReset()
            this.BGFHTS_UpdateMelfStackZoneAfterReset(true)
            return base.GemFarmResetSetup(formationModron := "", doBasePartySetup)
    }

    GetNumStacksFarmed(afterReset := false)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ])
            return base.GetNumStacksFarmed()
        if (base.ShouldOfflineStack())
            this.ShouldOfflineStack()
        if (afterReset || IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())
        {
            stacksAfterReset := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks()
            stacksAfterReset := g_SF.BrivHasThunderStep() ? stacksAfterReset * 1.2 : stacksAfterReset
            ; thunderstep recalc.
            g_SharedData.BGFHTS_SBStacksPredict := stacksAfterReset
            return stacksAfterReset
        }
        else
            return g_SF.Memory.ReadSBStacks() + 48
    }

    StackRestart()
    {
        IC_BrivGemFarm_HybridTurboStacking_Functions.SetRemovedIdsFromWFavorite([36, 59, 97])
        ; Just restart the game when hybrid turbo, don't wait
        g_SF.CloseIC( "FORT Restart" )
        g_SF.SafetyCheck()
        g_SF.AlreadyOfflineStackedThisRun := True
        ;base.StackRestart()
    }

    ; Tries to complete the zone before online stacking.
    ; TODO:: Update target stacks if Thellora doesn't have enough stacks for the next run.
    StackNormal(maxOnlineStackTime := 300000, targetStackModifier := 0)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ])
            return base.StackNormal(maxOnlineStackTime)
        ; Melf stacking
        if (g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ] && this.BGFHTS_PostponeStacking())
            return 0
        predictStacks := IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()
        SBStacksStart := g_SF.Memory.ReadSBStacks()
        stacks := this.GetNumStacksFarmed(predictStacks)
        targetStacks := g_BrivUserSettings[ "TargetStacks" ] + targetStackModifier
        if (this.ShouldAvoidRestack(stacks, targetStacks))
            return 0
        ; Check if offline stack is needed
        isMelfActive := IC_BrivGemFarm_HybridTurboStacking_Melf.IsCurrentEffectSpawnMore()
        if (this.BGFHTS_DelayedOffline || ((!isMelfActive) && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 2))
        {
            this.BGFHTS_DelayedOffline := false
            IC_BrivGemFarm_HybridTurboStacking_Functions.SetRemovedIdsFromWFavorite([36, 59, 97])
            return this.StackRestart()
        }
        if (g_BrivUserSettingsFromAddons[ "BGFHTS_Multirun" ])
            targetStacks := g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunTargetStacks" ]
        g_SF.ToggleAutoProgress( 0, false, true )
        ; Complete the current zone
        completed := g_BrivUserSettingsFromAddons[ "BGFHTS_CompleteOnlineStackZone" ] && this.BGFHTS_WaitForZoneCompleted()
        ; Conditional stack formation
        isMelfActive := IC_BrivGemFarm_HybridTurboStacking_Melf.IsCurrentEffectSpawnMore()
        removedIds := ""
        if (!isMelfActive && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 1)
            removedIds := [59] ; Melf
        else if (isMelfActive && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfActiveStrategy" ] == 1)
            removedIds := [36] ; Warden/Tatyana
        IC_BrivGemFarm_HybridTurboStacking_Functions.SetRemovedIdsFromWFavorite(removedIds)
        this.StackFarmSetup()
        ; Start online stacking
        StartTime := A_TickCount
        ElapsedTime := 0
        g_SharedData.LoopString := "Stack Normal"
        usedWardenUlt := false
        levelBrivZone := g_SF.Memory.ReadCurrentZone()
        levelBrivSomeMore := levelBrivZone >= 1100
        amountToLevelBriv := 0
        if (levelBrivSomeMore)
        {
            if (levelBrivZone >= 1400)
                amountToLevelBriv := 695
            else if (levelBrivZone >= 1300)
                amountToLevelBriv := 575
            else if (levelBrivZone >= 1200)
                amountToLevelBriv := 455
            else
                amountToLevelBriv := 340
        }
        ; Turn on Briv auto-heal
        autoHeal := g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ] > 0
        if (autoHeal)
        {
            fncToCallOnTimer := g_SharedData.BGFHTS_TimerFunctionHeal
            SetTimer, %fncToCallOnTimer%, 1000, 0
        }
        ; Haste stacks are taken into account
        if (predictStacks)
        {
            remainder := targetStacks - stacks
            SBStacksFarmed := 0
            while (SBStacksFarmed < remainder AND ElapsedTime < maxOnlineStackTime )
            {
                if (g_SF.Memory.ReadCurrentZone() < 1)
                    return g_SharedData.BGFHTS_Status := "Stacking interrupted due to game closed or reset"
                g_SharedData.BGFHTS_Status := "Stacking: " . (stacks + SBStacksFarmed ) . "/" . targetStacks
                g_SF.FallBackFromBossZone()
                if (levelBrivSomeMore)
                    this.BGFLU_LevelUpChamp(58, amountToLevelBriv)
                ; Warden ultimate
                wardenThreshold := g_BrivUserSettingsFromAddons[ "BGFHTS_WardenUltThreshold" ]
                if (!usedWardenUlt && wardenThreshold > 0)
                    usedWardenUlt := this.BGFHTS_TestWardenUltConditions(wardenThreshold)
                if (g_SF.Memory.ReadMostRecentFormationFavorite() != 2) ; not in formation 2 still
                    this.StackFarmSetup()
                else if (SBStacksFarmed < (remainder / 10) and ElapsedTime > 10000 ) ; not gaining stacks 
                    this.StackFarmSetup()
                Sleep, 30
                ElapsedTime := A_TickCount - StartTime
                SBStacksFarmed := g_SF.Memory.ReadSBStacks() - SBStacksStart
            }
        }
        else
        {
            while ( stacks < targetStacks AND ElapsedTime < maxOnlineStackTime )
            {
                if (g_SF.Memory.ReadCurrentZone() < 1)
                    return g_SharedData.BGFHTS_Status := "Stacking interrupted due to game closed or reset"
                g_SharedData.BGFHTS_Status := "Stacking: " . stacks . "/" . targetStacks
                g_SF.FallBackFromBossZone()
                if (levelBrivSomeMore)
                    this.BGFLU_LevelUpChamp(58, amountToLevelBriv)
                ; Warden ultimate
                wardenThreshold := g_BrivUserSettingsFromAddons[ "BGFHTS_WardenUltThreshold" ]
                if (!usedWardenUlt && wardenThreshold > 0)
                    usedWardenUlt := this.BGFHTS_TestWardenUltConditions(wardenThreshold)
                Sleep, 30
                ElapsedTime := A_TickCount - StartTime
                stacks := this.GetNumStacksFarmed()
            }
        }
        ; Turn off Briv auto-heal
        if (autoHeal)
            SetTimer, %fncToCallOnTimer%, Off
        if ( ElapsedTime >= maxOnlineStackTime)
        {
            this.RestartAdventure( "Online stacking took too long (> " . (maxOnlineStackTime / 1000) . "s) - z[" . g_SF.Memory.ReadCurrentZone() . "].")
            this.SafetyCheck()
            g_PreviousZoneStartTime := A_TickCount
            return ""
        }
        ; Update stats
        if (g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ])
        {
            g_SharedData.BGFHTS_PreviousStackZone := g_SF.Memory.ReadCurrentZone()
            g_SharedData.BGFHTS_CurrentRunStackRange := ["", ""]
        }
        g_PreviousZoneStartTime := A_TickCount
        ; Go back to z-1 if failed to complete the current zone
        if (g_SF.Memory.ReadQuestRemaining() > 0)
            g_SF.FallBackFromZone()
        g_SF.ToggleAutoProgress( 1, false, true )
        ; StackFarm won't be able to switch back to Q/E from W if the formation on the field isn't the exact
        ; formation saved in the second favorite formationslot.
        g_SF.SetFormation(g_BrivUserSettings)
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        ; Update stats
        if (predictStacks)
            g_SharedData.BGFHTS_SBStacksPredict := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks()
        g_SharedData.BGFHTS_Status := "Online stacking done"
        return ""
    }
}

class IC_BrivGemFarm_HybridTurboStacking_Added_Class ; Added to IC_BrivGemFarm_Class
{
    BGFHTS_WaitForZoneCompleted(maxTime := 3000)
    {
        g_SF.SetFormation(g_BrivUserSettings)
        highestZone := g_SF.Memory.ReadHighestZone()
        StartTime := A_TickCount
        ElapsedTime := 0
        g_SharedData.BGFHTS_Status := "Stacking: Waiting for transition"
        g_SF.WaitForTransition()
        quest := g_SF.Memory.ReadQuestRemaining()
        while (quest > 0 && ElapsedTime < maxTime)
        {
            quest := g_SF.Memory.ReadQuestRemaining()
            g_SharedData.BGFHTS_Status := "Stacking: Waiting for area completion " . quest
            if(ElapsedTime > maxTime / 2)
                g_SF.SetFormation(g_BrivUserSettings, forceCheck := True)
            else
                g_SF.SetFormation(g_BrivUserSettings)
            Sleep, 30
            ElapsedTime := A_TickCount - StartTime
        }
        return ElapsedTime < maxTime
    }

    BGFHTS_TestWardenUltConditions(threshold := 0)
    {
        champID := IC_BrivGemFarm_HybridTurboStacking_Class.WARDEN_ID
        champInWFormation := g_SF.IsChampInFormation(champID, g_SF.Memory.GetFormationByFavorite(2))
        if (champInWFormation && this.BGFHTS_CheckMaxEnemies(threshold))
            return this.BGFHTS_UseWardenUlt()
        return false
    }

    BGFHTS_CheckMaxEnemies(threshold := 0)
    {
        if (threshold == 0 || threshold == "")
            return true
        if (g_SF.Memory.ReadActiveMonstersCount() > threshold)
            return true
        return false
    }

    BGFHTS_UseWardenUlt()
    {
        champID := IC_BrivGemFarm_HybridTurboStacking_Class.WARDEN_ID
        g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(champID) . "}")
        return true
    }

    BGFHTS_PostponeStacking()
    {
        ; Stack immediately if Briv can't jump anymore.
        if (g_SF.Memory.ReadHasteStacks() < 50)
            return false
        currentZone := g_SF.Memory.ReadCurrentZone()
        ; Stack as soon as possible if not inside range.
        range := g_SharedData.BGFHTS_CurrentRunStackRange
        if (range[1] == "" || range[2] == "")
        {
            ; Offline stack after StackZone has been reached
            if (g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 2)
                return currentZone < g_BrivUserSettings[ "StackZone" ] + 1
            return false
        }
        stackZone := range[1]
        ; Stack immediately to prevent resetting before stacking.
        if (currentZone > IC_BrivGemFarm_Class.BrivFunctions.GetLastSafeStackZone())
            return false
        if (stackZone)
        {
            highestZone := g_SF.Memory.ReadHighestZone()
            mod50Zones := g_BrivUserSettingsFromAddons[ "BGFHTS_PreferredBrivStackZones" ]
            mod50Index := Mod(highestZone, 50) == 0 ? 50 : Mod(highestZone, 50)
            if (mod50Zones[mod50Index] == 0)
                return true
            if (!IC_BrivGemFarm_HybridTurboStacking_Melf.IsCurrentEffectSpawnMore())
                return true
        }
        ; Offline stack after StackZone has been reached
        if (this.BGFHTS_DelayedOffline)
            return currentZone < g_BrivUserSettings[ "StackZone" ] + 1
        return false
    }
}

; Overrides IC_MemoryFunctions_Class.GetFormationByFavorite()
class IC_BrivGemFarm_HybridTurboStacking_IC_MemoryFunctions_Class extends IC_MemoryFunctions_Class
{
    GetFormationByFavorite(favorite := 0 )
    {
        version := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2.__version.Read()
        if (this.FormationFavorites[favorite] != "" AND  favorite == this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2[this.FormationFavorites[favorite]].Favorite.Read())
            return this.GetFormationSaveBySlot(this.FormationFavoriteSlots[favorite]) 
        slot := this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationSaveBySlot(slot)
        if (favorite == 2) ; don't test stack formation for champions are still benched.
            for k, v in formation
                for _, champID in g_SharedData.BGFHTS_RemovedIdsFromWFavorite
                    if (v == champID)
                        if (g_SF.Memory.ReadChampBenchedByID(v)) 
                            formation[k] := g_SF.Memory.ReadChampBenchedByID(v) -2
        return formation
    }
}

class IC_BrivGemFarm_HybridTurboStacking_IC_SharedData_Added_Class ;Added to IC_SharedData_Class
{
;    BGFHTS_CurrentRunStackRange := ""
;    BGFHTS_PreviousStackZone := 0
;    BGFHTS_BrivDeaths := 0
;    BGFHTS_BrivHeals := 0
;    BGFHTS_Status := ""
;    BGFHTS_TimerFunction := ""
;    BGFHTS_TimerFunctionHeal := ""
;    BGFHTS_SBStacksPredict := 0
;    BGFHTS_StacksPredictionActive := false
;    BGFHTS_RemovedIdsFromWFavorite := ""

    ; Return true if the class has been updated by the addon.
    ; Returns "" if not properly loaded.
    BGFHTS_Running()
    {
        return g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ]
    }

    ; Load settings after "Start Gem Farm" has been clicked.
    BGFHTS_Init()
    {
        this.BGFHTS_BrivDeaths := 0
        this.BGFHTS_BrivHeals := 0
        this.BGFHTS_TimerFunction := ObjBindMethod(this, "BGFHTS_UpdateMelfStackZoneAfterReset")
        this.BGFHTS_TimerFunctionHeal := ObjBindMethod(IC_BrivGemFarm_HybridTurboStacking_Functions, "CheckBrivHealth")
        this.BGFHTS_UpdateSettingsFromFile()
    }

    ; Load settings from the GUI settings file.
    BGFHTS_UpdateSettingsFromFile(fileName := "")
    {
        if (fileName == "")
            fileName := IC_BrivGemFarm_HybridTurboStacking_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ] := settings.Enabled
        g_BrivUserSettingsFromAddons[ "BGFHTS_CompleteOnlineStackZone" ] := settings.CompleteOnlineStackZone
        g_BrivUserSettingsFromAddons[ "BGFHTS_WardenUltThreshold" ] := settings.WardenUltThreshold
        g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ] := settings.BrivAutoHeal
        g_BrivUserSettingsFromAddons[ "BGFHTS_Multirun" ] := settings.Multirun
        g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunTargetStacks" ] := settings.MultirunTargetStacks
        g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunDelayOffline" ] := settings.MultirunDelayOffline
        g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ] := settings.100Melf
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMinStackZone" ] := settings.MelfMinStackZone
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMaxStackZone" ] := settings.MelfMaxStackZone
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfActiveStrategy" ] := settings.MelfActiveStrategy
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] := settings.MelfInactiveStrategy
        mod50Zones := IC_BrivGemFarm_HybridTurboStacking_Functions.GetPreferredBrivStackZones(settings.PreferredBrivStackZones)
        g_BrivUserSettingsFromAddons[ "BGFHTS_PreferredBrivStackZones" ] := mod50Zones
    }

    BGFHTS_UpdateMelfStackZoneAfterReset(forceUpdate := false)
    {
        static lastResets := 0

        resets := g_SF.Memory.ReadResetsTotal()
        if (forceUpdate || resets > lastResets || !IsObject(this.BGFHTS_CurrentRunStackRange))
        {
            this.BGFHTS_Status := ""
            this.BGFHTS_CurrentRunStackRange := this.BGFHTS_CheckMelf()
            lastResets := resets
        }
        this.BGFHTS_UpdateStacksPredict()
    }

    BGFHTS_CheckMelf()
    {
        resets := g_SF.Memory.ReadResetsTotal()
        maxZone := g_SF.Memory.GetModronResetArea() - 1
        currentZone := g_SF.Memory.ReadCurrentZone()
        ; Modron reset happened but currentZone hasn't been reset to 1 yet.
        minZone := (currentZone == -1 || currentZone > maxZone) ? 1 : currentZone
        minZone := Max(minZone, g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMinStackZone" ])
        maxZone := Min(maxZone, g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMaxStackZone" ])
        range := IC_BrivGemFarm_HybridTurboStacking_Melf.GetFirstSpawnMoreEffectRange(, minZone, maxZone)
        this.BGFHTS_CurrentRunStackRange := range ? range : ["", ""]
        return range
    }

    BGFHTS_UpdateStacksPredict()
    {
        predictStacks := IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()
        this.BGFHTS_StacksPredictionActive := predictStacks
        if (predictStacks)
            g_SharedData.BGFHTS_SBStacksPredict := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks()
    }

}