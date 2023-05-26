CBN_SELENDCANCEL := 10
WM_COMMAND := 0x0111
CB_SETITEMHEIGHT := 0x0153
CB_GETDROPPEDSTATE := 0x0157
CB_SETDROPPEDWIDTH := 0x0160

GUIFunctions.AddTab("BrivGF LevelUp")

global g_BrivGemFarm_LevelUp := new IC_BrivGemFarm_LevelUp_Component
global g_DefinesLoader := new IC_BrivGemFarm_LevelUp_DefinesLoader

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
    Gui, ICScriptHub:Add, ComboBox, Limit6 hwndHBrivGemFarmLevelUpMinLevel_%seat% vCombo_BrivGemFarmLevelUpMinLevel_%seat% gBrivGemFarm_LevelUp_MinMax_Clamp x+%xSpacing% w60
    Gui, ICScriptHub:Add, ComboBox, Limit6 hwndHBrivGemFarmLevelUpMaxLevel_%seat% vCombo_BrivGemFarmLevelUpMaxLevel_%seat% gBrivGemFarm_LevelUp_MinMax_Clamp x+%xSpacing% w60
    GUIFunctions.UseThemeTextColor()
}

Gui, ICScriptHub:Add, Text, x20 y+20, Formation
Gui, ICScriptHub:Add, DropDownList, x+10 y+-17 w35 AltSubmit Disabled hwndBrivGemFarm_LevelUp_LoadFormation vBrivGemFarm_LevelUp_LoadFormation gBrivGemFarm_LevelUp_LoadFormation, Q||W|E
PostMessage, CB_SETITEMHEIGHT, -1, 17,, ahk_id %BrivGemFarm_LevelUp_LoadFormation%
Gui, ICScriptHub:Add, Button, x+20 Disabled vBrivGemFarm_LevelUp_Default gBrivGemFarm_LevelUp_Default, Default Settings
Gui, ICScriptHub:Add, Button, x+20 Hidden vBrivGemFarm_LevelUp_Save gBrivGemFarm_LevelUp_Save, Save
Gui, ICScriptHub:Add, Text, x+15 y+-18 w90 vBrivGemFarm_LevelUp_Changes
Gui, ICScriptHub:Add, Button, x+15 y+-18 Hidden vBrivGemFarm_LevelUp_Undo gBrivGemFarm_LevelUp_Undo, Undo
Gui, ICScriptHub:Add, Text, x20 y+15 w450 R2 vBrivGemFarm_LevelUp_Text, % "No settings."
Gui, ICScriptHub:Add, Button, x20 y+10 Disabled vBrivGemFarm_LevelUp_LoadDefinitions gBrivGemFarm_LevelUp_LoadDefinitions, Load Definitions
Gui, ICScriptHub:Add, Text, x+10 y+-18 w450 R2 vBrivGemFarm_LevelUp_DefinitionsStatus, % "No definitions."
Gui, ICScriptHub:Add, CheckBox, x20 y+10 vBrivGemFarm_LevelUp_Spoilers gBrivGemFarm_LevelUp_Spoilers, Show spoilers

OnMessage(WM_COMMAND, "CheckComboStatus")

; Refresh min/max values after a ComboBox sends a selection cancel event to the parent tab
CheckComboStatus(W)
{
    global
    GuiControlGet, CurrentTab,, ModronTabControl, Tab
    if (CurrentTab != "BrivGF LevelUp")
        return
    seat_ID := 0
    Loop, 12
    {
        ctrlH := HBrivGemFarmLevelUpMinLevel_%A_Index%
        SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlH%
        if (Errorlevel)
        {
            seat_ID := A_Index
            break
        }
        ctrlH := HBrivGemFarmLevelUpMaxLevel_%A_Index%
        SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlH%
        if (Errorlevel)
        {
            seat_ID := A_Index
            break
        }
    }
    if (seat_ID)
    {
        if ((W >> 16) & 0xFFFF == CBN_SELENDCANCEL)
        {
            choice := % DDL_BrivGemFarmLevelUpName_%seat_ID%
            if (choice == "Briv") ; After %choice%, ErrorLevel is set to 1 for an unknown reason
                GuiControl, ICScriptHub:ChooseString, DDL_BrivGemFarmLevelUpName_5, % "|" . choice
            else
                GuiControl, ICScriptHub:ChooseString, %choice%, % "|" . choice
        }
    }
}

; Switch names
BrivGemFarm_LevelUp_Name()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local name := % %A_GuiControl%
    heroDefs := g_DefinesLoader.HeroDefines
    for k, v in heroDefs
    {
        if (v.name == name)
        {
            IC_BrivGemFarm_LevelUp_Seat.Seats[v.seat_id].UpdateMinMaxLevels(name)
            break
        }
    }
}

; Sets the width of min/max comboBoxes for a seat
SetMinMaxComboWidth(seat_id, width)
{
    global
    minH := HBrivGemFarmLevelUpMinLevel_%seat_id%
    maxH := HBrivGemFarmLevelUpMaxLevel_%seat_id%
    PostMessage, CB_SETDROPPEDWIDTH, width, 0, , ahk_id %minH%
    PostMessage, CB_SETDROPPEDWIDTH, width, 0, , ahk_id %maxH%
}

; Returns the width of DDL accomodating the longest item in list
DropDownSize(List, Font:="", FontSize:=10, Padding:=24)
{
	Loop, Parse, List, |
	{
		if Font
			Gui DropDownSize:Font, s%FontSize%, %Font%
		Gui DropDownSize:Add, Text, R1, %A_LoopField%
		GuiControlGet T, DropDownSize:Pos, Static%A_Index%
		TW > X ? X := TW :
	}
	Gui DropDownSize:Destroy
	return X + Padding
}

; Input upgrade level when selected from DDL, then verify that min/max level inputs are in 0-999999 range
BrivGemFarm_LevelUp_MinMax_Clamp()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    local clamped := value
    Loop, Parse, clamped, :, " "
    {
        clamped := A_LoopField
        break
    }
    if clamped is not integer
        clamped := 0
    clamped := clamped <= 0 ? 0 : clamped
    clamped := clamped > 999999 ? 999999 : clamped
    if (clamped != value)
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % clamped
    Gui, ICScriptHub:Submit, NoHide
    g_BrivGemFarm_LevelUp.UpdateTempSettings()
}

; Load formation to the GUI
BrivGemFarm_LevelUp_LoadFormation()
{
    Gui, ICScriptHub:Submit, NoHide
    GuiControl, ICScriptHub:Disable, BrivGemFarm_LevelUp_LoadFormation
    Sleep, 20
    g_BrivGemFarm_LevelUp.LoadFormation(%A_GuiControl%)
    GuiControl, ICScriptHub:Enable, BrivGemFarm_LevelUp_LoadFormation
}

; Default settings button
BrivGemFarm_LevelUp_Default()
{
    MsgBox, 4, , Restore Default settings?, 5
    IfMsgBox, No
        Return
    IfMsgBox, Timeout
        Return
    GuiControl, ICScriptHub:Disable, BrivGemFarm_LevelUp_Default
    g_BrivGemFarm_LevelUp.LoadSettings(true)
    GuiControl, ICScriptHub:Enable, BrivGemFarm_LevelUp_Default
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
    g_BrivGemFarm_LevelUp.SaveSettings(true)
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
    GuiControl, ICScriptHub:Disable, BrivGemFarm_LevelUp_LoadDefinitions
    g_DefinesLoader.Start(false, true)
}

; Spoilers
BrivGemFarm_LevelUp_Spoilers()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    showSpoilers := BrivGemFarm_LevelUp_Spoilers
    g_BrivGemFarm_LevelUp.Settings.ShowSpoilers := showSpoilers
    g_BrivGemFarm_LevelUp.SaveSettings()
    Loop, 12
        IC_BrivGemFarm_LevelUp_Seat.Seats[A_Index].ToggleSpoilers(showSpoilers)
}

g_BrivGemFarm_LevelUp.Init()

/*  IC_BrivGemFarm_LevelUp_Component
    Class that manages the GUI for IC_BrivGemFarm_LevelUp.

*/
Class IC_BrivGemFarm_LevelUp_Component
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"

    Settings := ""
    TempSettings := ""

    ; GUI startup
    Init()
    {
        this.TempSettings := {}
        this.LoadSettings()
        g_DefinesLoader.Start()
    }

    ; Performs additional functions after definitions have been fully loaded
    OnHeroDefinesFinished()
    {
        this.FillMissingDefaultSettings()
        this.UndoTempSettings()
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadFormation
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_Default
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadDefinitions
    }

    ; Allows to click on the button to manually load hero definitions
    OnHeroDefinesFailed()
    {
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadDefinitions
    }

    /*  LoadSettings - Load GUI settings
        Parameters:    default: bool - If true, load default settings with specific values for speed champs

        Returns:
    */
    LoadSettings(default := false, save := false)
    {
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
        if (!IsObject(settings))
            settings := {}
        if (!IsObject(settings.BrivGemFarm_LevelUp_Settings))
        {
            settings.BrivGemFarm_LevelUp_Settings := this.LoadDefaultMinMaxSettings()
            for k, v in settings.BrivGemFarm_LevelUp_Settings.minLevels
                this.TempSettings.minLevels[k] := v
            for k, v in settings.BrivGemFarm_LevelUp_Settings.maxLevels
                this.TempSettings.maxLevels[k] := v
            save := true
        }
        else if (default) ; Load defaultsettings as temp settings into GUI
        {
            levelSettings := this.LoadDefaultMinMaxSettings()
            for k, v in levelSettings.minLevels
                this.TempSettings.minLevels[k] := v
            for k, v in levelSettings.maxLevels
                this.TempSettings.maxLevels[k] := v
            this.LoadFormation(this.GetFormationFromGUI())
        }
        if (settings.ShowSpoilers == "")
        {
            settings.ShowSpoilers := false
            save := true
        }
        this.Settings := settings
        if (save)
            this.SaveSettings()
        else if (!default)
            this.UndoTempSettings()
        if (default)
            this.Update("Default settings loaded.")
        else
            this.Update("Settings loaded.")
    }

    ; Load default settings to be used by IC_BrivGemFarm_LevelUp_Functions.ahk
    ; Speed champs have specific values that limit leveling to the minimum required to obtain all their speed abilities
    LoadDefaultMinMaxSettings()
    {
        minLevels := {}, maxLevels := {}
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
        return {minLevels:minLevels, maxLevels:maxLevels}
    }

    ; Update min/max values for champions added after default settings have been initialized
    FillMissingDefaultSettings()
    {
        save := false
        levelSettings := this.Settings.BrivGemFarm_LevelUp_Settings
        for heroID in g_DefinesLoader.HeroDefines
        {
            if levelSettings.minLevels[heroID] == ""
            {
                levelSettings.minLevels[heroID] := 0
                save := true
            }
            if levelSettings.maxLevels[heroID] == ""
            {
                levelSettings.maxLevels[heroID] := 1
                save := true
            }
        }
        if (save)
            this.SaveSettings()
    }

    ; Update temporary min/max level settings
    UpdateTempSettings()
    {
        Gui, ICScriptHub:Submit, NoHide
        heroDefs := g_DefinesLoader.HeroDefines
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
        this.Update("Settings loaded.")
    }

    ; Returns a list of champIDs from the current selected champions
    GetFormationFromGUI()
    {
        Gui, ICScriptHub:Submit, NoHide
        formation := []
        heroDefs := g_DefinesLoader.HeroDefines
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

    /*  SaveSettings - Save GUI settings
        Parameters:    applyTempSettings: bool - If true, apply temporary settings before saving

        Returns:
    */
    SaveSettings(applyTempSettings := false)
    {
        settings := this.Settings
        if (applyTempSettings)
        {
            for k, v in this.TempSettings.minLevels
                settings.BrivGemFarm_LevelUp_Settings.minLevels[k] := v
            for k, v in this.TempSettings.maxLevels
                settings.BrivGemFarm_LevelUp_Settings.maxLevels[k] := v
            this.Update("Settings saved.")
        }
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.LoadMinMaxLevels()
        }
    }

    /*  Update - Updates the GUI text strings, look for temp settings changes
        Parameters: text - The text shown under formation selection/default settings

        Returns:
    */
    Update(text := "")
    {
        if (!g_BrivUserSettings[ "Fkeys" ])
            text := "WARNING: F keys disabled. This Addon uses them to level up champions.`nEnable them both in the script (BrivGemFarm tab) and in the game (Settings -> General)."
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, % text
        this.UpdateLastUpdated()
        ; Temp changes
        changed := !IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(this.Settings.BrivGemFarm_LevelUp_Settings.minLevels, this.TempSettings.minLevels)
        if (!changed)
            changed := !IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(this.Settings.BrivGemFarm_LevelUp_Settings.maxLevels, this.TempSettings.maxLevels)
        if (changed)
        {
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Changes, Unsaved changes.
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Save
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Undo
        }
        else
        {
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Changes
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Save
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Undo
        }
    }

    ; Update the text that shows the last time cached_definitions.json was loaded
    UpdateLastUpdated(lastUpdateString := "", save := false)
    {
        settings := this.Settings
        if (lastUpdateString != "")
        {
            settings.LastUpdateString := lastUpdateString
            if (save)
                g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_DefinitionsStatus, % this.Settings.LastUpdateString
    }

    ; Loads formation from champIDs into the GUI, defaults to Q formation
    LoadFormation(formation := 1)
    {
        if (!IsObject(formation) OR formation.Length() == 0)
        {
            formationIndex := formation.Length() == 0 ? 1 : formation
            formation := this.GetSavedFormation(formationIndex)
        }
        if (formation.Length() == 0)
        {
            GuiControl, ICScriptHub:Choose, BrivGemFarm_LevelUp_LoadFormation, 0
            this.Update("Invalid formation. Game closed?")
            return
        }
        seats := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        for k, v in formation
        {
            if (v <= 0 OR v == "")
                continue
            champData := g_DefinesLoader.HeroDefines[v]
            seat_id := champData.seat_id
            name := champData.name
            seats.Delete(seat_id)
            GuiControl, ICScriptHub:ChooseString, DDL_BrivGemFarmLevelUpName_%seat_id%, % "|" . name
            Sleep, 1
        }
        for k, v in seats ; Delete contents from unused seats
            IC_BrivGemFarm_LevelUp_Seat.Seats[v].DeleteContents()
        this.Update()
    }

    ; Returns one of the in-game formations that are saved by the gem farming script after each reset
    GetSavedFormation(formation := 1)
    {
        savedFormations := this.Settings.SavedFormations
        if (!IsObject(savedFormations))
        {
            g_SF.Memory.OpenProcessReader()
            try ; avoid thrown errors when comobject is not available.
            {
                SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
                SharedRunData.SaveFormations()
            }
            return g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(formation), true) ; without empty slots
        }
        Switch formation
        {
            Case 1:
                return savedFormations.Q
            Case 2:
                return savedFormations.W
            Case 3:
                return savedFormations.E
            Default:
                return formation
        }
    }
}

; Functions used to update min/max upgrade values of each seat
Class IC_BrivGemFarm_LevelUp_Seat
{
    static Seats := IC_BrivGemFarm_LevelUp_Seat.BuildSeats()

    ID := 0
    HeroDataByID := {}
    HeroDataByName := {}
    HasSpoiler := false

    __New(seat)
    {
        this.ID := seat
    }

    ; Adds the data for a champion to this seat's dictionnary sorted by name
    AddChampion(data)
    {
        this.HeroDataByName[data.name] := data
        if (!this.HasSpoiler)
            this.HasSpoiler := this.IsSpoiler(data.allow_time_gate)
    }

    ; Deletes min/max upgrade list and sets this seat's fields to empty values
    DeleteContents()
    {
        seat := this.ID
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
        GuiControl, ICScriptHub:Choose, DDL_BrivGemFarmLevelUpName_%seat%, 0
        GuiControl, ICScriptHub:Choose, Combo_BrivGemFarmLevelUpMinLevel_%seat%, 0
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % "|"
        GuiControl, ICScriptHub:Move, Combo_BrivGemFarmLevelUpMinLevel_%seat%, h25
        GuiControl, ICScriptHub:Choose, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, 0
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % "|"
        GuiControl, ICScriptHub:Move, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, h25
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
    }

    /*  UpdateMinMaxLevels - Update min/max upgrades values and upgrade list
                             The size of the longest item in the list will be cached at the first time the champion is chosen
        Parameters:          name: string - The name of a champion

        Returns:
    */
    UpdateMinMaxLevels(name)
    {
        global
        seat := this.ID
        heroData := this.HeroDataByName[name]
        upgrades := heroData.upgrades
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % "|" . upgrades
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % "|" . upgrades
        if(heroData.cachedSize == "")
            heroData.cachedSize := DropDownSize(heroData.upgrades)
        SetMinMaxComboWidth(seat, heroData.cachedSize)
        Sleep, 1
        GuiControl, ICScriptHub:Text, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % g_BrivGemFarm_LevelUp.TempSettings.minLevels[k]
        GuiControl, ICScriptHub:Text, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % g_BrivGemFarm_LevelUp.TempSettings.maxLevels[k]
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
    }

    ; Updates the list of champions names for this lot
    UpdateNames()
    {
        global
        showSpoilers := g_BrivGemFarm_LevelUp.Settings.ShowSpoilers
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Spoilers, % showSpoilers
        names := "|"
        for ID, heroData in this.HeroDataByID
        {
            if (showSpoilers OR !this.IsSpoiler(heroData.allow_time_gate))
                names .= heroData.name . "|"
        }
        seat := this.ID
        GuiControl, ICScriptHub:, DDL_BrivGemFarmLevelUpName_%seat%, % names
    }

    ; Toggle this seat's spoilers on/off
    ToggleSpoilers(value)
    {
        if (!this.HasSpoiler)
            return
        names := "|"
        for ID, heroData in this.HeroDataByID
        {
            if (value OR !this.IsSpoiler(heroData.allow_time_gate))
                names .= heroData.name . "|"
        }
        seat := this.ID
        choice := DDL_BrivGemFarmLevelUpName_%seat% ; Remember the current name selection
        GuiControl, ICScriptHub:, DDL_BrivGemFarmLevelUpName_%seat%, % names
        GuiControl, ICScriptHub:ChooseString, DDL_BrivGemFarmLevelUpName_%seat%, % choice
        Gui, ICScriptHub:Submit, NoHide
        if (choice != DDL_BrivGemFarmLevelUpName_%seat%)
            this.DeleteContents()
    }

    ; Static methods

    /*  IsSpoiler -    Find if a champion is part of spoilers
        Parameters:    allow_time_gate: string - A time string that shows when the champion's Time Gate will be available (UTC)

        Returns:       bool - True if the champion's Time Gate is available in 12 days or less (when the event starts)
    */
    IsSpoiler(allow_time_gate := "")
    {
        if (allow_time_gate == "")
            return false
        dt := ""
        Loop, Parse, allow_time_gate, :%A_Space%-
            dt .= A_LoopField
        EnvAdd, dt, 7, H
        EnvAdd, dt, -12, D
        EnvSub, dt, A_NowUTC, S
        return dt > 0
    }

    ; Adds a single champion data to his seat's container
    AddChampionData(data)
    {
        IC_BrivGemFarm_LevelUp_Seat.Seats[data.seat_id].AddChampion(data)
    }

    ; Build seats on startup
    BuildSeats()
    {
        seats := []
        Loop, 12
            seats.Push(new IC_BrivGemFarm_LevelUp_Seat(A_Index))
        return seats
    }

    ; Performs additional functions after definitions have been fully loaded
    OnHeroDefinesFinished()
    {
        for ID, heroData in g_DefinesLoader.HeroDefines
            IC_BrivGemFarm_LevelUp_Seat.Seats[heroData.seat_id].HeroDataByID[ID] := heroData
        for seatID, seat in IC_BrivGemFarm_LevelUp_Seat.Seats
            seat.UpdateNames()
        g_BrivGemFarm_LevelUp.OnHeroDefinesFinished()
    }
}

IC_BrivGemFarm_LevelUp_Functions.InjectAddon()

#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_DefinesLoader.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk