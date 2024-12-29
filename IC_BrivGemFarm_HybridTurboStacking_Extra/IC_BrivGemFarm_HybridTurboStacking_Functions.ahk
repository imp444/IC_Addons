#include %A_LineFile%\..\RNG\IC_BrivGemFarm_HybridTurboStacking_Melf.ahk

; Functions that are used by this Addon.
class IC_BrivGemFarm_HybridTurboStacking_Functions
{
    static WARDEN_ID := 36
    static MELF_ID := 59
    static TATYANA_ID := 97
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_HybridTurboStacking_Settings.json"

    ; Adds IC_BrivGemFarm_HybridTurboStacking_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_HybridTurboStacking_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ReadResets()
    {
        return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.StatHandler.Resets.Read()
    }

    ConvertBitfieldToArray(value)
    {
        if (IsObject(value))
            return value
        array := []
        Loop, 50
            array.Push((value & (2 ** (A_Index - 1))) != 0)
        return array
    }

    GetPreferredBrivStackZones(value)
    {
        array := this.ConvertBitfieldToArray(value)
        ; Disable stacking in a boss zone.
        Loop, 10
            array[5 * A_Index] := 0
        return array
    }

    GetLastSafeStackZone(modronReset := "")
    {
        if (modronReset == "")
            modronReset := g_SF.Memory.GetModronResetArea()
        lastZone := modronReset - 1
        ; Move back one zone if the last zone before reset is a boss.
        if (Mod(lastZone, 5 ) == 0)
            lastZone -= 1
        skipAmount := this.BrivFunctions.GetHighestBrivSkipAmount()
        return lastZone - skipAmount - 1
    }

    ; Stacks

    ; Calculates the path from z1 to the reset area.
    ; Parameters: - mod50values:Array - Preferred Briv jump zones for the Q/E favorite formations.
    ;             - currentZone:int - Starting zone.
    ;             - resetZone:int - Actual zone where the run is reset.
    ;             - startStacks:int - Briv Haste stacks.
    ;             - skipQ:int - Number of Briv jumps in the Q formation.
    ;             - skipE:int - Number of Briv jumps in the E formation.
    ;             - brivMinLevelArea:int - Minimum level where Briv can jump (LevelUp addon setting).
    ;             - brivMetalbornArea:int - Minimum level where Briv gets Metalborn (LevelUp addon setting).
    ; Returns:    - int - Number of Briv Haste stacks left at the reset zone.
    CalcStacksLeftAtReset(mod50values, currentZone, resetZone, startStacks, skipQ, skipE, brivMinLevelArea := 1, brivMetalbornArea := 1)
    {
        qVal := skipQ != "" ? Max(skipQ + 1, 1) : 1
        eVal := skipE != "" ? Max(skipE + 1, 1) : 1
        brivMinLevelArea := brivMinLevelArea > 0 ? brivMinLevelArea : 1
        brivMetalbornArea := brivMetalbornArea > 0 ? brivMetalbornArea : 1
        if (!Isobject(mod50values))
        {
            mod50Int := mod50values
            mod50values := []
            Loop, 50
                mod50values[A_Index] := (mod50Int & (2 ** (A_Index - 1))) != 0
        }
        ; Walk
        ; This assumes Briv won't be levelled before brivMinLevelArea
        currentZone := Max(currentZone, brivMinLevelArea)
        ; Jump
        while (currentZone < resetZone)
        {
            ; Area progress
            mod50Index := Mod(currentZone, 50) == 0 ? 50 : Mod(currentZone, 50)
            mod50Value := mod50values[mod50Index]
            move := mod50Value ? qVal : eVal
            if (move > 1)
                startStacks := Round(startStacks * (currentZone < brivMetalbornArea ? 0.96 : 0.968))
            currentZone += move
        }
        return startStacks
    }

    ; Predicts the number of Briv haste stacks after the next reset.
    ; After resetting, Briv's Steelborne stacks are added to the remaining Haste stacks.
    ; It is expected Briv gets levelled with Unnatural Haste since if Briv does not jump, he will not lose stacks and if
    ; he already has enough haste stacks for a full run, stacking never happens.
    ; It is expected Briv gets levelled with Metalborn as online stacking can happen anywhere up to the Modron reset zone.
    PredictStacks(addSBStacks := true, checkUpgrades := false, refreshCache := false)
    {
        preferred := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
        skipQ := this.BrivFunctions.GetBrivSkipConfig(1, refreshCache).HighestAvailableJump
        skipE := this.BrivFunctions.GetBrivSkipConfig(3, refreshCache).HighestAvailableJump
        modronReset := g_SF.Memory.GetModronResetArea()
        sbStacks := g_SF.Memory.ReadSBStacks()
        currentZone := g_SF.Memory.ReadCurrentZone()
        highestZone := g_SF.Memory.ReadHighestZone()
        sprintStacks := g_SF.Memory.ReadHasteStacks()
        ; Party has not progressed to the next zone yet but Briv stacks were consumed.
        if (highestZone - currentZone > 1)
            currentZone := highestZone
        ; Find the zone where Briv gets levelled to level 80+
        if (IsObject(g_BrivGemFarm_LevelUp)|| IsObject(IC_BrivGemFarm_LevelUp_Class))
        {
            if (IsObject(g_BrivGemFarm_LevelUp))
            {
                brivMinlevelArea := g_BrivGemFarm_LevelUp.Settings.BrivMinLevelArea
                brivLevelingZones:= g_BrivGemFarm_LevelUp.Settings.BrivLevelingZones
            }
            else
            {
                brivMinlevelArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ]
                brivLevelingZones := g_BrivUserSettingsFromAddons[ "BGFLU_BrivLevelingZones" ]
            }
            actualZone := this.FindActualBrivMinLevelingZone(brivMinlevelArea, brivLevelingZones)
            if (actualZone == -1)
                brivMinlevelArea := modronReset
            else
                brivMinlevelArea := actualZone
            if (currentZone < brivMinlevelArea && this.BrivFunctions.ReadUnnaturalHastePurchased())
                brivMinlevelArea := currentZone
            brivMetalbornArea := brivMinlevelArea
        }
        else
            brivMinlevelArea := brivMetalbornArea := 1
        ; Check current Briv upgrades
        if (checkUpgrades)
        {
            if (currentZone > brivMinlevelArea && !this.BrivFunctions.ReadUnnaturalHastePurchased())
                brivMinlevelArea := modronReset
            if (!this.BrivFunctions.ReadMetalbornPurchased())
                brivMetalbornArea := modronReset
        }
        ; This assumes Briv has gained more than 48 stacks ever.
        stacksAtReset := Max(48, this.CalcStacksLeftAtReset(preferred, currentZone, modronReset, sprintStacks, skipQ, skipE, brivMinlevelArea, brivMetalbornArea))
        if (addSBStacks)
            stacksAtReset += sbStacks
        return stacksAtReset
    }

    FindActualBrivMinLevelingZone(brivMinlevelArea := 1, brivLevelingZones := "")
    {
        if (brivLevelingZones)
        {
            firstArea := Mod(brivMinlevelArea, 50) == 0 ? 50 : Mod(brivMinlevelArea, 50)
            brivLevelingZones := this.ConvertBitfieldToArray(brivLevelingZones)
            repeatingNum := brivLevelingZones.Length()
            Loop, % repeatingNum - firstArea + 1
            {
                area := firstArea + A_Index - 1
                if (brivLevelingZones[area] == 1)
                    return brivMinlevelArea + A_Index - 1
            }
            Loop, % firstArea - 1
            {
                if (brivLevelingZones[A_Index] == 1)
                    return brivMinlevelArea + (repeatingNum - firstArea) + A_Index
            }
        }
        return -1
    }

    PredictStacksActive
    {
        get
        {
            return !g_BrivUserSettings[ "AutoCalculateBrivStacks" ] && !g_BrivUserSettings[ "IgnoreBrivHaste" ]
        }
    }

    ; Briv

    class BrivFunctions
    {
        static BrivId := 58
        static BrivJumpSlot := 4
        static UnnaturalHasteBaseEffect := 25
        static WastingHastePercentOverride := 800
        static StrategicStridePercentOverride := 25600
        static WastingHasteId := 791
        static StrategicStrideId := 2004
        static AccurateAcrobaticsFeatId := 2062
        static UnnaturalHasteId := 3452
        static MetalbornId := 3455
        static BrivSkipConfigByFavorite := []
        static BrivSkipValues := ""

        ReadUnnaturalHastePurchased()
        {
            return g_SF.Memory.ReadHeroUpgradeIsPurchased(this.BrivId, this.UnnaturalHasteId)
        }

        ReadMetalbornPurchased()
        {
            return g_SF.Memory.ReadHeroUpgradeIsPurchased(this.BrivId, this.MetalbornId)
        }

        GetBrivLoot()
        {
            BrivId := this.BrivId
            BrivJumpSlot := this.BrivJumpSlot
            gild := g_SF.Memory.ReadHeroLootGild(BrivId, BrivJumpSlot)
            enchant := Floor(g_SF.Memory.ReadHeroLootEnchant(BrivId, BrivJumpSlot))
            rarity := g_SF.Memory.ReadHeroLootRarityValue(BrivId, BrivJumpSlot)
            if (gild == "" || enchant == "" || rarity == "")
                return ""
            return {gild:gild, enchant:enchant, rarity:rarity}
        }

        GetHeroFeatsInFormationFavorite(formationFavorite, heroID)
        {
            if (heroID < 1)
                return ""
            slot := g_SF.Memory.GetSavedFormationSlotByFavorite(formationFavorite)
            size := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].FormationSaveHandler.formationSavesV2[slot].Feats[heroID].List.size.Read()
            ; Sanity check, should be < 4 but set to 6 in case of future feat num increase.
            if (size < 0 || size > 6)
                return ""
            featList := []
            Loop, %size%
            {
                value := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].FormationSaveHandler.formationSavesV2[slot].Feats[heroID].List[A_Index - 1].Read()
                featList.Push(value)
            }
            return featList
        }

        GetHighestBrivSkipAmount(refresh := false)
        {
            if ((refresh || this.BrivSkipValues == "") && g_SF.Memory.ReadCurrentZone() != "")
            {
                skipValues := this.GetBrivSkipValues()
                this.BrivSkipValues := skipValues
            }
            return this.BrivSkipValues[1]
        }

        GetBrivSkipValues(favoriteFormationSlot := "")
        {
            feats := ""
            hasAccurateFeat := false
            if (favoriteFormationSlot > 0)
            {
                formation := g_SF.Memory.GetFormationByFavorite(favoriteFormationSlot)
                heroID := this.BrivId
                if (g_SF.IsChampInFormation(heroID, formation))
                {
                    feats := this.GetHeroFeatsInFormationFavorite(favoriteFormationSlot, heroID)
                    for k, v in feats
                    {
                        if (v == this.AccurateAcrobaticsFeatId)
                            hasAccurateFeat := true
                    }
                }
                else
                    return [0, 0]
            }
            defaultSkipChance := this.GetDefaultBrivSkipChance(feats)
            return this.CalculateAreaSkipValues(defaultSkipChance, hasAccurateFeat)
        }

        GetDefaultBrivSkipChance(feats := "")
        {
            ; Check for 4J or 9J feat
            if (IsObject(feats))
            {
                hasFeatOverride := false
                featOverridePercent := 1234567890
                for k, v in feats
                {
                    ; 4J feat takes precedence over 9J feat
                    if (v == this.WastingHasteId)
                    {
                        hasFeatOverride := true
                        featOverridePercent := Min(this.WastingHastePercentOverride, featOverridePercent)
                    }
                    else if (v == this.StrategicStrideId)
                    {
                        hasFeatOverride := true
                        featOverridePercent := Min(this.StrategicStridePercentOverride, featOverridePercent)
                    }
                }
                if (hasFeatOverride)
                    return featOverridePercent
            }
            ; Compute effect from loot
            loot := this.GetBrivLoot()
            if (loot == "")
                return ""
            gild := loot.gild
            enchant := loot.enchant
            rarity := loot.rarity
            baseEffect := this.UnnaturalHasteBaseEffect
            ilvlMult := 1 + Max(enchant, 0) * 0.004
            rarityMult := (rarity == 0) ? 0 : (rarity == 1) ? 0.1 : (rarity == 2) ? 0.3 : (rarity == 3) ? 0.5 : (rarity == 4) ? 1 : 0
            gildMult := (gild == 0) ? 1 : (gild == 1) ? 1.5 : (gild == 2) ? 2 : 1
            skipChance := baseEffect * (1 + ilvlMult * rarityMult * gildMult)
            return skipChance
        }

        CalculateAreaSkipValues(defaultPercent, hasAccurateFeat := false)
        {
            if (defaultPercent < this.UnnaturalHasteBaseEffect)
                return ""
            skipChance := 0.01 * defaultPercent
            skipAmount := 1
            if (skipChance > 1)
            {
                while (skipChance > 1)
                {
                    skipChance *= 0.5
                    ++skipAmount
                }
                if (hasAccurateFeat && skipChance < 1)
                    skipChance := 0
                else
                    skipChance := (skipChance - 0.5) / (1 - 0.5) * (1 - 0.01) + 0.01
            }
            return [skipAmount, skipChance]
        }

        GetBrivSkipConfig(favorite := "", refresh := false)
        {
            if (favorite < 1)
                return
            if ((refresh || this.BrivSkipConfigByFavorite[favorite] == "") && g_SF.Memory.ReadCurrentZone() != "")
            {
                skipValues := this.GetBrivSkipValues(favorite)
                feats := this.GetHeroFeatsInFormationFavorite(favorite, this.BrivId)
                config := new this.BrivSkipConfig(skipValues[1], skipValues[2], feats)
                this.BrivSkipConfigByFavorite[favorite] := config
            }
            return this.BrivSkipConfigByFavorite[favorite]
        }

        CurrentFormationMatchesBrivConfig(favoriteFormationSlot, refresh := false)
        {
            if (g_SF.Memory.ReadResetting())
                return true
            config := this.GetBrivSkipConfig(favoriteFormationSlot, refresh)
            skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
            skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
            equalAmount := skipAmount == config.skipAmount
            equalChance := config.IsPartialJump ? (0 < skipChance && skipChance < 1) : (skipChance == config.skipChance)
            return equalAmount && equalChance
        }

        class BrivSkipConfig
        {
            SkipAmount := 0
            SkipChance := 0
            Feats := ""
            ; Cached properties
            4JFeat := false
            9JFeat := false
            AAFeat := false
            AvailableJumps := ""

            __New(skipAmount, skipChance, feats)
            {
                this.SkipAmount := skipAmount
                this.SkipChance := skipChance
                this.Feats := feats
                for k, v in feats
                {
                    if (v == this.WastingHasteId)
                        this.4JFeat := true
                    else if (v == this.StrategicStrideId)
                        this.9JFeat := true
                    else if (v == this.AccurateAcrobaticsFeatId)
                        this.AAFeat := true
                }
                ; Perfect jump or no Briv in formation
                if (skipChance == 1 || skipAmount == 0)
                    this.AvailableJumps := [skipAmount]
                ; Round down to previous jump
                ; nJ,0% := n(J - 1),100%
                else if (skipChance == 0)
                    this.AvailableJumps := [skipAmount - 1]
                ; Partial jump
                else
                    this.AvailableJumps := [skipAmount - 1, skipAmount]
            }

            IsPartialJump
            {
                get
                {
                    return this.AvailableJumps.Length() == 2
                }
            }

            HighestAvailableJump
            {
                get
                {
                    return this.AvailableJumps[this.AvailableJumps.Length()]
                }
            }
        }
    }

    ; Conditional stack formation

    SetRemovedIdsFromWFavorite(ids := "")
    {
        g_SharedData.BGFHTS_RemovedIdsFromWFavorite := ids
    }

    ; Heal

    ReadHealthPercent(champID := 58, toPercent := true)
    {
        if (champID < 1)
            return ""
        heroId := g_SF.Memory.GetHeroHandlerIndexByChampID(champID)
        healthPercent := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[heroId].lastHealthPercent.Read()
        return toPercent ? 100 * healthPercent : healthPercent
    }

    HealHero(champID := 58)
    {
        if (champID < 1)
            return ""
        ; x10 = full heal
        if (this.ReadLevelUpAmount() != 10)
            g_SF.DirectedInput(, release := 0, "{Shift}") ;keysdown
        keys := ["{Shift}", "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}"]
        g_SF.DirectedInput(, release := 0, keys*) ;keysdown
        g_SF.DirectedInput(hold := 0,, keys*) ;keysup
        return true
    }

    ReadLevelUpAmount()
    {
        value := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.bottomBar.levelUpAmount.Read()
        return value == "" ? 100 : value
    }

    CheckBrivHealth()
    {
        static lastPercent := ""

        brivId := this.BrivFunctions.BrivId
        percent := Max(0, this.ReadHealthPercent(brivId))
        if (lastPercent > 0 && percent == 0)
        {
            g_SharedData.BGFHTS_BrivDeaths += 1
            lastPercent := 0
        }
        else if (percent > 0 && percent < g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ])
        {
            if (IsObject(IC_BrivGemFarm_LevelUp_Class) && !IC_BrivGemFarm_LevelUp_Class.BGFLU_CanAffordUpgrade(brivId))
                return
            this.HealHero(brivId)
            g_SharedData.BGFHTS_BrivHeals += 1
        }
        lastPercent := percent
    }
}