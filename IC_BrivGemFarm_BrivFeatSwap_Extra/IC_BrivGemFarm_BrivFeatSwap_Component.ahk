#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_GUI.ahk

; Test to see if BrivGemFarm addon is available.
if(IsObject(IC_BrivGemFarm_Component))
{
    IC_BrivGemFarm_BrivFeatSwap_Functions.InjectAddon()
    global g_BrivFeatSwap := new IC_BrivGemFarm_BrivFeatSwap_Component
    global g_BrivFeatSwapGui := new IC_BrivGemFarm_BrivFeatSwap_GUI
    g_BrivFeatSwap.Init()
}
else
{
    GuiControl, ICScriptHub:Text, BGFBFS_StatusText, WARNING: This addon needs IC_BrivGemFarm enabled.
    return
}

/*  IC_BrivGemFarm_BrivFeatSwap_Component

    Class that manages the GUI for BrivFeatSwap.
    Starts automotically on script launch and waits for Briv Gem Farm to be started, then stops/starts every time buttons on the main Briv Gem Farm window are clicked.
*/
Class IC_BrivGemFarm_BrivFeatSwap_Component
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_BrivFeatSwap_Settings.json"

    SavedPreferredAdvancedSettings := 0
    Settings := ""
    TimerFunctions := ""

    Init()
    {
        g_BrivFeatSwapGui.SetupGroups()
        ; Save the state of the mod50 checkboxes for Preferred Briv Jump Zones in Advanced Settings tab.
        this.SavedPreferredAdvancedSettings := this.GetSavedPreferredAdvancedSettings()
        this.SetupPresets()
        this.Settings := settings := g_SF.LoadObjectFromJSON(this.SettingsPath)
        if (IsObject(settings))
        {
            GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ, % settings.targetQ
            GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE, % settings.targetE
            GuiControl, ICScriptHub:ChooseString, BGFBFS_Preset, % settings.Preset
            Sleep, 50
            if (settings.Preset)
                this.SaveMod50Preset()
        }
        else
            this.Settings := {}
        this.CreateTimedFunctions()
        g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(this, "Start"))
        g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(this, "Stop"))
        this.Start()
    }

    ; Adds timed functions to be run when briv gem farm is started
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "UpdateStatus")
        this.TimerFunctions[fncToCallOnTimer] := 1000
    }

    Start()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, %v%, 0
        }
    }

    Stop()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Not Running
        GuiControl, ICScriptHub:Hide, BGFBFS_StatusWarning
    }

    ; Update the GUI, try to read Q/W/E skip amounts
    UpdateStatus()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (!SharedRunData.BGFBFS_Running)
            {
                this.Stop()
                GuiControl, ICScriptHub:Show, BGFBFS_StatusWarning
                str := "BrivGemFarm Briv Feat Swap addon was loaded after Briv Gem Farm started.`n"
                MsgBox, % str . "If you want it enabled, press Stop/Start to retry."
            }
            else
            {
                GuiControl, ICScriptHub:Text, BrivFeatSwapQValue, % SharedRunData.BrivFeatSwap_savedQSKipAmount
                GuiControl, ICScriptHub:Text, BrivFeatSwapWValue, % SharedRunData.BrivFeatSwap_savedWSKipAmount
                GuiControl, ICScriptHub:Text, BrivFeatSwapEValue, % SharedRunData.BrivFeatSwap_savedESKipAmount
                GuiControl, ICScriptHub:Text, BrivFeatSwapsMadeThisRunValue, % SharedRunData.SwapsMadeThisRun
                GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Running
            }
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Waiting for Gem Farm to start
        }
    }

    ; Save settings.
    ; Parameters: - targetQ:int - Target Briv skip value to look for when switching to Q formation.
    ;             - targetE:int - Target Briv skip value to look for when switching to E formation.
    Save(targetQ, targetE)
    {
        settings := this.Settings
        GuiControlGet, presetName, ICScriptHub:, BGFBFS_Preset
        if (presetName)
            settings.Preset := presetName
        else
            settings.Preset := ""
        this.SaveMod50Preset()
        settings.targetQ := targetQ
        settings.targetE := targetE
        g_SF.WriteObjectToJSON(this.SettingsPath, settings)
        GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Settings saved
        ; Apply settings to BrivGemFarm
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.UpdateTargetAmounts(targetQ, targetE)
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Waiting for Gem Farm to start
        }
    }

    ; Copy the state of the mod50 checkboxes for Preferred Briv Jump Zones in this addon's tab
    ; into the mod50 checkboxes in Advanced Settings tab, then reload and save.
    ; Doesn't save settings to the current profile.
    SaveMod50Preset()
    {
        Loop, 50
        {
            isChecked := BGFBFS_CopyPasteBGFAS_Mod_50_%A_Index%
            g_BrivUserSettings[ "PreferredBrivJumpZones" ][A_Index] := isChecked
        }
        IC_BrivGemFarm_AdvancedSettings_Functions.LoadPreferredBrivJumpSettings()
        IC_BrivGemFarm_AdvancedSettings_Component.SaveAdvancedSettings()
    }

    ; Read the state of the mod50 checkboxes for Preferred Briv Jump Zones in Advanced Settings tab.
    GetSavedPreferredAdvancedSettings()
    {
        value := 0
        Loop, 50
        {
            GuiControlGet, isChecked, ICScriptHub:, PreferredBrivJumpSettingMod_50_%A_Index%
            if (isChecked)
                value += 2 ** (A_Index - 1)
        }
        return value
    }

    ; Setup choices for the Presets ListBox.
    SetupPresets()
    {
        choices := "||5J/4J|8J/4J|8J/4J + walk 1/2/3/4|9J/4J"
        GuiControl, ICScriptHub:, BGFBFS_Preset, % "|" . choices
        GuiControl, ICScriptHub:Choose, BGFBFS_Preset, |0
    }

    ; Apply settings for a specific preset.
    ; Parameters: - name:str - Name of a preset shown in the Presets ListBox.
    LoadPreset(name)
    {
        Switch name
        {
            case "5J/4J":
                this.ApplyPresets(1125891005438934, 5, 4)
            case "8J/4J":
                this.ApplyPresets(1125897724754935, 8, 4)
            case "8J/4J + walk 1/2/3/4":
                this.ApplyPresets(1125897724754928, 8, 4,, true)
            case "9J/4J":
                this.ApplyPresets(580042328931855, 9, 4)
            case default:
                this.ApplyPresets(this.SavedPreferredAdvancedSettings, this.Settings.targetQ, this.Settings.targetE, true)
        }
        ; Apply BrivMinLevelArea setting to BGFLU addon
        if (name == "8J/4J + walk 1/2/3/4" && IsObject(g_BrivGemFarm_LevelUp))
        {
            GuiControl, ICScriptHub:, BGFBFS_BrivMinLevelArea, 5
            GuiControl, ICScriptHub:, BGFLU_BrivMinLevelArea, 5
        }
        else
            GuiControl, ICScriptHub:, BGFLU_BrivMinLevelArea, % g_BrivGemFarm_LevelUp.Settings.BrivMinLevelArea
    }

    ; Apply temporary GUI settings for the selected preset.
    ; Parameters: - mod50Value:int - Bitfield representing checked values for each mod50 checkbox.
    ;             - targetQ:int - Value to apply to the targetQ edit field.
    ;             - targetE:int - Value to apply to the targetE edit field.
    ;             - default:bool - Used to toggle mod50 checkboxes. If true, hide mod50 checkboxes.
    ;             - showBrivMinLevelArea:bool - Used to toggle BrivMinLevelArea setting . If true, hide BrivMinLevelArea.
    ApplyPresets(mod50Value, targetQ, targetE, default := false, showBrivMinLevelArea := false)
    {
        GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ, % targetQ
        GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE, % targetE
        this.LoadMod50(mod50Value)
        this.ToggleMod50(!default)
        this.ToggleBrivMinLevelArea(showBrivMinLevelArea)
    }

    ; Set the state of the mod50 checkboxes for Preferred Briv Jump Zones in BGFBFS tab.
    ; Parameters: value:int - A bitfield that represents the checked state of each checkbox.
    LoadMod50(value)
    {
        Loop, 50
        {
            checked := (value & (2 ** (A_Index - 1))) != 0
            GuiControl, ICScriptHub:, BGFBFS_CopyPasteBGFAS_Mod_50_%A_Index%, % checked
        }
        Gui, ICScriptHub:Submit, NoHide
    }

    ; Show / hide mod50 checkboxes for Preferred Briv Jump Zones in BGFBFS tab.
    ; Parameters: - show:bool - If true, show Preferred Briv Jump Zones, else hide it.
    ToggleMod50(show := true)
    {
        value := show ? "Show" : "Hide"
        Loop, 50
            GuiControl, ICScriptHub:%value%, BGFBFS_CopyPasteBGFAS_Mod_50_%A_Index%
        GuiControl, ICScriptHub:%value%, BGFBFS_PreferredBrivJumpZones
    }

    ; Show / hide BrivMinLevelArea setting in BGFBFS tab.
    ; Parameters: - show:bool - If true, show BrivMinLevelArea, else hide it.
    ToggleBrivMinLevelArea(show := true)
    {
        value := show ? "Show" : "Hide"
        GuiControl, ICScriptHub:%value%, BGFBFS_BrivMinLevelArea
        GuiControl, ICScriptHub:%value%, BGFBFS_BrivMinLevelAreaText
        GuiControl, ICScriptHub:%value%, BGFBFS_BGFLU
    }
}