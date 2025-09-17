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
        static BrivSkipConfigByFavorite := []

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
        }
    }
}