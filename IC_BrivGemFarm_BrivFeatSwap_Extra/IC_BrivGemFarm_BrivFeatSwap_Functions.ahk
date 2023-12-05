#include *i %A_LineFile%\..\..\IC_BrivGemFarm_LevelUp_Extra\IC_BrivGemFarm_LevelUp_Functions.ahk

; Functions that allow Q/E swaps with Briv in E formation
class IC_BrivGemFarm_BrivFeatSwap_Functions
{
    static Injected := false
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_BrivFeatSwap_Settings.json"

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

    GetExeName()
    {
        default := "IdleDragons.exe"
        exeName := g_UserSettings[ "ExeName" ]
        return (exeName != default && exeName != "") ? exeName : default
    }

    ; Returns the index of the active monitor of a given window handle
    ; https://www.autohotkey.com/board/topic/94735-get-active-monitor/
    GetMonitor(hwnd := 0)
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

    IsGameFullScreen()
    {
        exeName := IC_BrivGemFarm_BrivFeatSwap_Functions.GetExeName()
        ; Get monitor coords
        WinGet, hwnd, ID, ahk_exe %exeName%
        monitor := IC_BrivGemFarm_BrivFeatSwap_Functions.GetMonitor(hwnd)
        SysGet, monitorCoords, MonitorWorkArea, %monitor%
        ; Get game window coords
        WinGetPos, x, y, w, h, ahk_exe %exeName%
        return (monitorCoordsLeft == x && monitorCoordsTop == y)
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

    CalculateAreaSkipValues(gild, enchant, rarity, decimals := 5)
    {
        baseEffect := 25
        gildMult := (gild == 1) ? 1.5 : (gild == 2) ? 2 : 1
        lootMultBonus := (1 + Max(enchant, 0) * 0.004) * gildMult
        rarityMult := (rarity == 1) ? 0.1 : (rarity == 2) ? 0.3 : (rarity == 3) ? 0.5 : (rarity == 4) ? 1 : 0
        skipChance := baseEffect * (1 + (lootMultBonus * rarityMult)) * 0.01
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
        return [skipAmount, Round(100 * skipChance, decimals)]
    }

    GetTargetQSkipValues()
    {
        skipValues := this.GetBrivSkipValues()
        if (skipValues[2] == 100)
            return [skipValues[1]]
        return [skipValues[1] - 1, skipValues[1]]
    }
}