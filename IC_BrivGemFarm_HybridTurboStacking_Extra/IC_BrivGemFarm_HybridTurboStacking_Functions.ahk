#include %A_LineFile%\..\RNG\IC_BrivGemFarm_HybridTurboStacking_Melf.ahk

; Functions that are used by this Addon.
class IC_BrivGemFarm_HybridTurboStacking_Functions
{
    static WARDEN_ID := 36
    static BRIV_ID := 58
    static MELF_ID := 59
    static TATYANA_ID := 97
    static BrivJumpSlot := 4
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

    GetHighestBrivSkipAmount()
    {
        BrivID := IC_BrivGemFarm_HybridTurboStacking_Functions.BRIV_ID
        BrivJumpSlot := IC_BrivGemFarm_HybridTurboStacking_Functions.BrivJumpSlot
        gild := g_SF.Memory.ReadHeroLootGild(BrivID, BrivJumpSlot)
        ilvls := Floor(g_SF.Memory.ReadHeroLootEnchant(BrivID, BrivJumpSlot))
        rarity := g_SF.Memory.ReadHeroLootRarityValue(BrivID, BrivJumpSlot)
        if (ilvls == "" || rarity == "" || gild == "")
            return 50
        return this.CalculateAreaSkipValues(gild, ilvls, rarity)[1]
    }

    CalculateAreaSkipValues(gild, ilvls, rarity)
    {
        baseEffect := 25
        ilvlMult := 1 + Max(ilvls - 1, 0) * 0.004
        rarityMult := (rarity == 0) ? 0 : (rarity == 1) ? 0.1 : (rarity == 2) ? 0.3 : (rarity == 3) ? 0.5 : (rarity == 4) ? 1 : 0
        gildMult := (gild == 0) ? 1 : (gild == 1) ? 1.5 : (gild == 2) ? 2 : 1
        skipChance := baseEffect * (1 + (ilvlMult * rarityMult * gildMult)) * 0.01
        skipAmount := 1
        if (skipChance > 1)
        {
            while (skipChance > 1)
            {
                skipChance *= 0.5
                ++skipAmount
            }
            skipChance := (skipChance - 0.5) / (1 - 0.5) * (1 - 0.01) + 0.01
        }
        return [skipAmount, skipChance]
    }

    GetLastSafeStackZone(modronReset := "")
    {
        if (modronReset == "")
            modronReset := g_SF.Memory.GetModronResetArea()
        lastZone := modronReset - 1
        ; Move back one zone if the last zone before reset is a boss.
        if (Mod(lastZone, 5 ) == 0)
            lastZone -= 1
        skipAmount := IC_BrivGemFarm_HybridTurboStacking_Functions.GetHighestBrivSkipAmount()
        return lastZone - skipAmount - 1
    }

    ; Stacks

    ; Return the number of stacks needed to jump noMetalbornJumps + metalbornJumps times.
    ; Parameters: - noMetalbornJumps:int - Number of times Briv jumps without Metalborn.
    ;             - metalbornJumps:int - Number of times Briv jumps with Metalborn.
    CalcBrivStacksNeeded(noMetalbornJumps, metalbornJumps)
    {
        stacks := (noMetalbornJumps + metalbornJumps > 0) * 50
        ; Last jump is always with Metalborn unless Briv never gets to level 170
        ; Metalborn calculations must apply last meaning backtracking starts with Metalborn
        Loop, % (metalbornJumps > 0 ? metalbornJumps - 1 : metalbornJumps)
        {
            stacks := Ceil((stacks - 0.5) / 0.968)
            if (stacks > 999999999999999)
                return "Too many"
        }
        Loop, % (metalbornJumps > 0 ? noMetalbornJumps : noMetalbornJumps - 1)
        {
            stacks := Ceil((stacks - 0.5) / 0.96)
            if (stacks > 999999999999999)
                return "Too many"
        }
        return stacks
    }

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
        qVal := skipQ != "" ? skipQ + 1 : 1
        eVal := skipE != "" ? skipE + 1 : 1
        if (!Isobject(mod50values))
        {
            mod50Int := mod50values
            mod50values := []
            Loop, 50
                mod50values[A_Index] := (mod50Int & (2 ** (A_Index - 1))) != 0
        }
        ; Walk
        Loop, % brivMinLevelArea - 1
            ++currentZone > resetZone ? break : 1
        ; Jump
        while (currentZone < resetZone)
        {
            ; Area progress
            mod50Index := Mod(currentZone, 50) == 0 ? 50 : Mod(currentZone, 50)
            mod50Value := mod50values[mod50Index]
            move := mod50Value ? qVal : eVal
            ; Update walk and metalborn jump counters
            if (move == 1)
                ++walks
            else
                startStacks := Round(startStacks * (currentZone < brivMetalbornArea ? 0.96 : 0.968))
            currentZone += move
        }
        return startStacks
    }

    ; Predicts the number of Briv haste stacks after the next reset.
    ; After resetting, Briv's Steelborne stacks are added to the remaining Haste stacks.
    PredictStacks(addSBStacks := true, refreshCache := false)
    {
        static skipQ
        static skipE

        preferred := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
        if (IsObject(IC_BrivGemFarm_LevelUp_Component) || IsObject(IC_BrivGemFarm_LevelUp_Class))
        {
            brivMinlevelArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ]
            brivMetalbornArea := brivMinlevelArea
        }
        else
        {
            brivMinlevelArea := brivMetalbornArea := 1
        }
        if (refreshCache || skipQ == "" || skipE == "" || skipQ == 0 && skipE == 0)
        {
            skipQ := this.GetBrivSkipValue(1)
            skipE := this.GetBrivSkipValue(3)
        }
        modronReset := g_SF.Memory.GetModronResetArea()
        sbStacks := g_SF.Memory.ReadSBStacks()
        currentZone := g_SF.Memory.ReadCurrentZone()
        highestZone := g_SF.Memory.ReadHighestZone()
        sprintStacks := g_SF.Memory.ReadHasteStacks()
        ; Party has not progressed to the next zone yet but Briv stacks were consumed.
        if (highestZone - currentZone > 1)
            currentZone := highestZone
        ; This assumes Briv has gained more than 48 stacks ever.
        stacksAtReset := Max(48, this.CalcStacksLeftAtReset(preferred, currentZone, modronReset, sprintStacks, skipQ, skipE, brivMinlevelArea, brivMetalbornArea))
        if (addSBStacks)
            stacksAtReset += sbStacks
        return stacksAtReset
    }

    PredictStacksActive
    {
        get
        {
            return !g_BrivUserSettings[ "AutoCalculateBrivStacks" ] && !g_BrivUserSettings[ "IgnoreBrivHaste" ]
        }
    }

    GetBrivSkipValue(favoriteformationSlot := 1)
    {
        formation := g_SF.Memory.GetFormationByFavorite(favoriteformationSlot)
        heroID := ActiveEffectKeySharedFunctions.Briv.HeroID
        if (g_SF.IsChampInFormation(heroID, formation))
        {
            feats := this.GetHeroFeatsInFormationFavorite(favoriteformationSlot, heroID)
            has9JFeat := false
            for k, v in feats
            {
                ; 4J feat takes precedence over 9J feat
                if (v == 791)
                    return 4
                else if (v == 2004)
                    has9JFeat := true
                if (has9JFeat)
                    return 9
            }
            return this.GetBrivSkipValues()[1]
        }
        else
            return 0
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

    GetBrivLoot()
    {
        BrivID := 58
        BrivJumpSlot := 4
        gild := g_SF.Memory.ReadHeroLootGild(BrivID, BrivJumpSlot)
        enchant := Floor(g_SF.Memory.ReadHeroLootEnchant(BrivID, BrivJumpSlot))
        rarity := g_SF.Memory.ReadHeroLootRarityValue(BrivID, BrivJumpSlot)
        return {gild:gild, enchant:enchant, rarity:rarity}
    }

    GetBrivSkipValues()
    {
        loot := this.GetBrivLoot()
        gild := loot.gild
        enchant := loot.enchant
        rarity := loot.rarity
        if (gild == "" || enchant == "" || rarity == "")
            return ""
        return this.CalculateAreaSkipValues(gild, enchant, rarity)
    }

    GetTargetQSkipValues()
    {
        skipValues := this.GetBrivSkipValues()
        if (skipValues[2] == 100)
            return [skipValues[1]]
        return [skipValues[1] - 1, skipValues[1]]
    }

    ; Conditional stack formation

    SetRemovedIdsFromWFavorite(ids := "")
    {
        g_SharedData.BGFHTS_RemovedIdsFromWFavorite := ids
    }

    ; Heal

    ReadHealthPercent(champID := 58)
    {
        if (champID < 1)
            return ""
        obj := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[g_SF.Memory.GetHeroHandlerIndexByChampID(champID)].health.QuickClone()
        ; lastHealthPercent
        obj.FullOffsets[obj.FullOffsets.Length()] += 8
        return 100 * obj.Read()
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

        percent := Max(0, this.ReadHealthPercent())
        if (lastPercent > 0 && percent == 0)
        {
            g_SharedData.BGFHTS_BrivDeaths += 1
            lastPercent := 0
        }
        else if (percent > 0 && percent < g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ])
        {
            if (IsObject(IC_BrivGemFarm_LevelUp_Class) && !IC_BrivGemFarm_LevelUp_Class.BGFLU_CanAffordUpgrade(58))
                return
            this.HealHero()
            g_SharedData.BGFHTS_BrivHeals += 1
        }
        lastPercent := percent
    }
}