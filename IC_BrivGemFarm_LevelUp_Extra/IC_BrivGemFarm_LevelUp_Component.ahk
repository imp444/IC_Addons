GUIFunctions.AddTab("BrivGF LevelUp")

global g_BrivGemFarm_LevelUp := new IC_BrivGemFarm_LevelUp_Component

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, BrivGF LevelUp
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , BrivGemFarm LevelUp Settings
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x13 y+15, Seat
Gui, ICScriptHub:Add, Text, x+51, Name
Gui, ICScriptHub:Add, Text, x+64, MinLevel
Gui, ICScriptHub:Add, Text, x+31, MaxLevel

; Create minLevel, maxLevel, order buttons/edits
Loop, 12
{
    AddSeat(15, 10, A_Index)
}
; Add settings for the next seat
AddSeat(xSpacing, ySpacing, seat)
{
    global
    Gui, ICScriptHub:Add, Text, Center x%xSpacing% y+%ySpacing% w15, % seat
    GUIFunctions.UseThemeTextColor("InputBoxTextColor")
    Gui, ICScriptHub:Add, DropDownList , vDDL_BrivGemFarmLevelUpName_%seat% gBrivGemFarm_LevelUp_Name x+%xSpacing% y+-16 w111
    Gui, ICScriptHub:Add, ComboBox, Limit6 vCombo_BrivGemFarmLevelUpMinLevel_%seat% gBrivGemFarm_LevelUp_MinMax_Clamp x+%xSpacing% w60
    Gui, ICScriptHub:Add, ComboBox, Limit6 vCombo_BrivGemFarmLevelUpMaxLevel_%seat% gBrivGemFarm_LevelUp_MinMax_Clamp x+%xSpacing% w60

    GUIFunctions.UseThemeTextColor()
}

Gui, ICScriptHub:Add, Button, x20 y+20 Disabled vBrivGemFarm_LevelUp_LoadQFormation gBrivGemFarm_LevelUp_LoadQFormation, Load Q formation
Gui, ICScriptHub:Add, Button, x+20 Disabled vBrivGemFarm_LevelUp_Default gBrivGemFarm_LevelUp_Default, Default Settings
Gui, ICScriptHub:Add, Button, x+20 Disabled vBrivGemFarm_LevelUp_Save gBrivGemFarm_LevelUp_Save, Save
Gui, ICScriptHub:Add, Text, x+15 y+-18 w90 vBrivGemFarm_LevelUp_Changes
Gui, ICScriptHub:Add, Button, x+15 y+-18 Hidden vBrivGemFarm_LevelUp_Undo gBrivGemFarm_LevelUp_Undo, Undo
Gui, ICScriptHub:Add, Text, x20 y+15 w400 vBrivGemFarm_LevelUp_Text, % "No settings."
Gui, ICScriptHub:Add, Button, x20 y+20 vBrivGemFarm_LevelUp_LoadDefinitions gBrivGemFarm_LevelUp_LoadDefinitions, Load Definitions
Gui, ICScriptHub:Add, Text, x+10 y+-18 w400 vBrivGemFarm_LevelUp_DefinitionsStatus, % "No settings."

; Switch names
BrivGemFarm_LevelUp_Name()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local name := % %A_GuiControl%
    heroDefs := g_BrivGemFarm_LevelUp.HeroDefines
    for k, v in heroDefs
    {
        if (v.name == name)
        {
            seat_id := v.seat_id
            break
        }
    }
    GuiControl, Text, Combo_BrivGemFarmLevelUpMinLevel_%seat_id%, % g_BrivGemFarm_LevelUp.TempSettings.minLevels[k]
    GuiControl, Text, Combo_BrivGemFarmLevelUpMaxLevel_%seat_id%, % g_BrivGemFarm_LevelUp.TempSettings.maxLevels[k]
}

; Check min/max level inputs
BrivGemFarm_LevelUp_MinMax_Clamp()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    local clamped := value
    if clamped is not integer
        clamped := 0
    clamped := clamped <= 0 ? 0 : clamped
    clamped := clamped > 999999 ? 999999 : clamped
    if (clamped != value)
        GuiControl, Text, %A_GuiControl%, % clamped
    Gui, ICScriptHub:Submit, NoHide
    Sleep, 20
    g_BrivGemFarm_LevelUp.UpdateTempSettings()
}

; Load Q formation to the GUI
BrivGemFarm_LevelUp_LoadQFormation()
{
    GuiControl, Disable, BrivGemFarm_LevelUp_LoadQFormation
    g_BrivGemFarm_LevelUp.LoadFormation()
    GuiControl, Enable, BrivGemFarm_LevelUp_LoadQFormation
}

; Default settings button
BrivGemFarm_LevelUp_Default()
{
    MsgBox, 4, , Restore Default settings?, 5
    IfMsgBox, No
        Return
    IfMsgBox, Timeout
        Return
    GuiControl, Disable, BrivGemFarm_LevelUp_Default
    g_BrivGemFarm_LevelUp.LoadSettings(true)
    GuiControl, Enable, BrivGemFarm_LevelUp_Default
}

; Save settings button
BrivGemFarm_LevelUp_Save()
{
    MsgBox, 4, , Save changes?, 5
    IfMsgBox, No
        Return
    IfMsgBox, Timeout
        Return
    Gui, ICScriptHub:Submit, NoHide
    g_BrivGemFarm_LevelUp.SaveSettings()
}

; Undo temp settings button
BrivGemFarm_LevelUp_Undo()
{
    MsgBox, 4, , Undo all changes?, 5
    IfMsgBox, No
        Return
    IfMsgBox, Timeout
        Return
    g_BrivGemFarm_LevelUp.UndoTempSettings()
}

; Load new definitions
BrivGemFarm_LevelUp_LoadDefinitions()
{
    GuiControl, Disable, BrivGemFarm_LevelUp_LoadDefinitions
    g_BrivGemFarm_LevelUp.ReadOrCreateHeroDefs(false, true)
    GuiControl, Enable, BrivGemFarm_LevelUp_LoadDefinitions
}

g_BrivGemFarm_LevelUp.Init()

/*  IC_BrivGemFarm_LevelUp_Component
    Class that manages the GUI for IC_BrivGemFarm_LevelUp.

*/
Class IC_BrivGemFarm_LevelUp_Component
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"
    HeroDefines := ""
    Settings := ""
    TempSettings := ""

    ; GUI startup
    Init()
    {
        this.ReadOrCreateHeroDefs()
        this.Update()
    }

    /*  ReadOrCreateHeroDefs - Read/Write definitions from/to HeroDefines.json
        Parameters:    silent: bool - If true, doesn't prompt the dialog to choose the file if not found
                       create: bool - If true, force new definitions

        Returns:
    */
    ReadOrCreateHeroDefs(silent := true, create := false)
    {
        heroDefs := create ? IC_BrivGemFarm_LevelUp_Functions.CreateHeroDefs(silent) : IC_BrivGemFarm_LevelUp_Functions.ReadHeroDefs(silent)
        if (heroDefs == "" AND silent == true)
            this.UpdateLastUpdated("WARNING: Could not load Hero definitions. Try manually loading them.")
        else if (heroDefs == "" AND silent == false)
            return
        else
        {
            this.HeroDefines := heroDefs
            for k, v in heroDefs
            {
                seat_id := v.seat_id
                GuiControl, ICScriptHub:, DDL_BrivGemFarmLevelUpName_%seat_id%, % v.name
            }
            this.LoadSettings()
            GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadQFormation
            GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_Default
            GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_Save
        }
    }

    /*  LoadSettings - Load GUI settings
        Parameters:    default: bool - If true, load default settings with specific values for speed champs

        Returns:
    */
    LoadSettings(default := false)
    {
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
        save := false
        if (!IsObject(settings) OR default OR !IsObject(settings.BrivGemFarm_LevelUp_Settings))
        {
            settings := this.LoadDefaultSettings()
            save := true
        }
        if (!IsObject(settings))
            return
        this.Settings := settings
        if (save AND !default)
            this.SaveSettings()
        this.TempSettings := {}
        this.UndoTempSettings()
        if (default)
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, Default settings loaded.
        else
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, Settings loaded.
    }

    ; Load default settings to be used by IC_BrivGemFarm_LevelUp_Functions.ahk
    ; Speed champs have specific values that limit leveling to the minimum required to obtain all their speed abilities
    LoadDefaultSettings()
    {
        heroDefs := IC_BrivGemFarm_LevelUp_Functions.ReadHeroDefs(false)
        if (heroDefs == "")
            return
        this.HeroDefines := HeroDefs
        settings := {}
        minLevels := {}, maxLevels := {}
        for k, v in heroDefs
        {
            minLevels[k] := 0, maxLevels[k] := 1
        }
        minLevels[58] := 170, maxLevels[58] := 1300 ; Briv
        minLevels[47] := 120, maxLevels[47] := 120 ; Shandie
        minLevels[91] := 260, maxLevels[91] := 350 ; Widdle 260 310 350
        minLevels[28] := 90, maxLevels[28] := 200 ; Deekin 90 200
        minLevels[75] := 220, maxLevels[75] := 360 ; Hew Maan 40 200 220 360
        minLevels[102] := 90, maxLevels[102] := 250 ; Nahara
        minLevels[52] := 80, maxLevels[52] := 80 ; Sentry
        minLevels[115] := 100, maxLevels[115] := 100 ; Virgil
        minLevels[89] := 1, maxLevels[89] := 1 ; D'hani
        minLevels[114] := 1, maxLevels[114] := 1 ; Kent
        minLevels[98] := 1, maxLevels[98] := 1 ; Gazrick 1540
        minLevels[79] := 1, maxLevels[79] := 1 ; Shaka
        minLevels[81] := 1, maxLevels[81] := 1 ; Selise
        minLevels[56] := 165, maxLevels[56] := 165 ; Havilar
        minLevels[95] := 100, maxLevels[95] := 250 ; Vi 100 250
        minLevels[70] := 90, maxLevels[70] := 90 ; Ezmeralda 90 315
        minLevels[12] := 65, maxLevels[12] := 65 ; Arkhan
        minLevels[4] := 1, maxLevels[4] := 2150 ; Jarlaxle
        minLevels[39] := 1, maxLevels[39] := 3440 ; Paultin
        minLevels[113] := 1, maxLevels[113] := 1400 ; Egbert
        minLevels[94] := 1, maxLevels[94] := 2640 ; Rust
        minLevels[30] := 1, maxLevels[30] := 2020 ; Azaka
        settings.BrivGemFarm_LevelUp_Settings := {}
        settings.BrivGemFarm_LevelUp_Settings.minLevels := minLevels
        settings.BrivGemFarm_LevelUp_Settings.maxLevels := maxLevels
        return settings
    }

    ; Update temporary min/max level settings
    UpdateTempSettings()
    {
        Gui, ICScriptHub:Submit, NoHide
        heroDefs := this.HeroDefines
        Loop, 12
        {
            seat_id = % A_Index
            if (DDL_BrivGemFarmLevelUpName_%seat_id% == "")
                continue
            champID := 0
            for k, v in heroDefs
            {
                if (v.name == DDL_BrivGemFarmLevelUpName_%seat_id%)
                {
                    champID := k
                    break
                }
            }
            if (champID == 0)
                continue
            this.TempSettings.minLevels[champID] := Combo_BrivGemFarmLevelUpMinLevel_%seat_id%
            this.TempSettings.maxLevels[champID] := Combo_BrivGemFarmLevelUpMaxLevel_%seat_id%
        }
        this.Update()
    }

    ; Restore last saved settings
    UndoTempSettings()
    {
        for k, v in this.Settings.BrivGemFarm_LevelUp_Settings.minLevels
            this.TempSettings.minLevels[k] := v
        for k, v in this.Settings.BrivGemFarm_LevelUp_Settings.maxLevels
            this.TempSettings.maxLevels[k] := v
        this.LoadFormation(this.GetFormationFromGUI())
        this.Update()
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, Settings loaded.
    }

    GetFormationFromGUI()
    {
        formation := []
        heroDefs := this.HeroDefines
        Loop, 12
        {
            seat_id = % A_Index
            if (DDL_BrivGemFarmLevelUpName_%seat_id% == "")
                continue
            for k, v in heroDefs
            {
                if (v.name == DDL_BrivGemFarmLevelUpName_%seat_id%)
                {
                    formation.Push(k)
                    break
                }
            }
        }
        return formation
    }

    ; Save GUI settings
    SaveSettings()
    {
        settings := this.Settings
        for k, v in this.TempSettings.minLevels
            settings.BrivGemFarm_LevelUp_Settings.minLevels[k] := v
        for k, v in this.TempSettings.maxLevels
            settings.BrivGemFarm_LevelUp_Settings.maxLevels[k] := v
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        this.Update()
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.LoadMinMaxLevels()
        }
    }

    ; Updates the GUI text strings, looks for settings temp changes
    Update()
    {
        if (!g_BrivUserSettings[ "Fkeys" ])
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, WARNING: F keys disabled. This Addon uses them to level champions.
        this.UpdateLastUpdated()
        ; Temp changes
        changed := false
        for k, v in this.Settings.BrivGemFarm_LevelUp_Settings.minLevels
        {
            if (this.TempSettings.minLevels[k] != v)
            {
                changed := true
                break
            }
        }
        if (!changed)
        {
            for k, v in this.Settings.BrivGemFarm_LevelUp_Settings.maxLevels
            {
                if (this.TempSettings.maxLevels[k] != v)
                {
                    changed := true
                    break
                }
            }
        }
        if (changed)
        {
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Changes, Unsaved changes.
            GuiControl, Show, BrivGemFarm_LevelUp_Undo
        }
        else
        {
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Changes
            GuiControl, Hide, BrivGemFarm_LevelUp_Undo
        }
    }

    ; Update the text that shows the last time cached_definitions.json was loaded
    UpdateLastUpdated(lastUpdateString := "")
    {
        this.Settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
        if (!IsObject(this.Settings))
            this.Settings := {}
        if (lastUpdateString != "")
        {
            this.Settings.lastUpdateString := lastUpdateString
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, this.Settings)
        }
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_DefinitionsStatus, % this.Settings.lastUpdateString
    }

    ; Loads formation from champIDs into the GUI, defaults to Q formation
    LoadFormation(formation := "")
    {
        g_SF.Memory.OpenProcessReader()
        if (!isObject(formation))
        {
            slot := g_SF.Memory.GetSavedFormationSlotByFavorite(1)
            formation := g_SF.Memory.GetFormationSaveBySlot(slot, true) ; Q without empty slots
            formationIsQ := true
        }
        if (formation.Length() == 0)
        {
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, Invalid Q formation. Game closed?
            return
        }
        Loop, 12 ; Delete contents
        {
            GuiControl, Choose, DDL_BrivGemFarmLevelUpName_%A_Index%, 0
            GuiControl, Choose, Combo_BrivGemFarmLevelUpMinLevel_%A_Index%, 0
            GuiControl, Choose, Combo_BrivGemFarmLevelUpMaxLevel_%A_Index%, 0
        }
        for k, v in formation
        {
            if (v <= 0 OR v == "")
                continue
            champData := this.HeroDefines[v]
            seat_id := champData.seat_id
            GuiControl, ChooseString, DDL_BrivGemFarmLevelUpName_%seat_id%, % champData.name
            GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMinLevel_%seat_id%, % "|" . g_BrivGemFarm_LevelUp.TempSettings.minLevels[v]
            GuiControl, ChooseString, Combo_BrivGemFarmLevelUpMinLevel_%seat_id%, % "|" . g_BrivGemFarm_LevelUp.TempSettings.minLevels[v]
            GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMaxLevel_%seat_id%, % "|" . g_BrivGemFarm_LevelUp.TempSettings.maxLevels[v]
            GuiControl, ChooseString, Combo_BrivGemFarmLevelUpMaxLevel_%seat_id%, % "|" . g_BrivGemFarm_LevelUp.TempSettings.maxLevels[v]
        }
        if (formationIsQ)
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, Q formation loaded.
    }
}

IC_BrivGemFarm_LevelUp_Functions.InjectAddon()

#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk