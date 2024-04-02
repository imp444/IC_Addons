#include %A_LineFile%\..\RNG\IC_BrivGemFarm_HybridTurboStacking_Melf.ahk

; Functions that are used by this Addon.
class IC_BrivGemFarm_HybridTurboStacking_Functions
{
    static BRIV_ID := 58
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
}