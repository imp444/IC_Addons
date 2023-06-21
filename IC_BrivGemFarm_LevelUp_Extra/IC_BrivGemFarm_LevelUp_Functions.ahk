#include *i %A_LineFile%\..\..\IC_BrivGemFarm_BrivFeatSwap_Extra\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk

; Functions used by this addon
class IC_BrivGemFarm_LevelUp_Functions
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"
    static HeroDefsPath := A_LineFile . "\..\HeroDefines.json"

    ; Adds IC_BrivGemFarm_LevelUp_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        if (IC_BrivGemFarm_LevelUp_Functions.CheckForBrivFeatSwapAddon()) ; Load Briv Feat Swap before this addon
            IC_BrivGemFarm_BrivFeatSwap_Functions.InjectAddon()
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_LevelUp_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ; Returns true if the BrivGemFarm Briv Feat Swap addon is enabled in Addon Management or in the AddOnsIncluded.ahk file
    CheckForBrivFeatSwapAddon()
    {
        static AddonManagementConfigFile := % A_LineFile . "\..\..\IC_Addon_Management\AddonManagement.json"
        static AddOnsIncludedConfigFile := % A_LineFile . "\..\..\AddOnsIncluded.ahk"
        static AddonName := "BrivGemFarm Briv Feat Swap"

        if (FileExist(AddonManagementConfigFile)) ; Look for enabled BrivGemFarm Briv Feat Swap addon
        {
            AddonSettings:= g_SF.LoadObjectFromJSON(AddonManagementConfigFile)
            for k, v in AddonSettings
                if ((k == AddonName) AND v.Enabled)
                    return true
        }
        else if (FileExist(AddOnsIncludedConfigFile)) ; Try in the AddOnsIncluded file
        {
            Loop, Read, %AddOnsIncludedConfigFile%
            {
                if InStr(A_LoopReadLine, "#include *i %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Extra\IC_BrivGemFarm_BrivFeatSwap_Component.ahk")
                    return true
            }
        }
        return false
    }

    ; Returns true if the two objects have identical key/value pairs
    AreObjectsEqual(obj1 := "", obj2 := "")
    {
        if (obj1.Count() != obj2.Count())
            return false
        for k, v in obj1
        {
            if (IsObject(v) AND !this.AreObjectsEqual(obj2[k], v) OR !IsObject(v) AND obj2[k] != v AND obj2.HasKey(k))
                return false
        }
        return true
    }

    ; Creates a deep clone of an object
    ObjFullyClone(obj)
    {
        nobj := obj.Clone()
        for k,v in nobj
        {
            if IsObject(v)
                nobj[k] := this.ObjFullyClone(v)
        }
        return nobj
    }
}