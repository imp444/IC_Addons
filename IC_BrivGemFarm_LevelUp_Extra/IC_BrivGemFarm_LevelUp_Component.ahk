CBN_SELENDCANCEL := 10
WM_COMMAND := 0x0111
CB_SETITEMHEIGHT := 0x0153
CB_GETDROPPEDSTATE := 0x0157
CB_SETDROPPEDWIDTH := 0x0160

GUIFunctions.AddTab("BrivGF LevelUp")

global g_BrivGemFarm_LevelUp := new IC_BrivGemFarm_LevelUp_Component
global g_DefinesLoader := new IC_BrivGemFarm_LevelUp_DefinesLoader
global g_HeroDefines := IC_BrivGemFarm_LevelUp_HeroData

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, BrivGF LevelUp
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, x+5 w463 h645 vMinMaxSettingsGroup, BrivGemFarm LevelUp Settings
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x23 y100, Seat
Gui, ICScriptHub:Add, Text, x+51, Name
Gui, ICScriptHub:Add, Text, x+64, MinLevel
Gui, ICScriptHub:Add, Text, x+31, MaxLevel

; Create minLevel, maxLevel, order buttons/edits
leftAlign := 25
xSpacing := 15
ySpacing := 10

Loop, 12
{
    AddSeat(xSpacing, ySpacing, A_Index)
}
; Add settings for the next seat
AddSeat(xSpacing, ySpacing, seat)
{
    global
    Gui, ICScriptHub:Add, Text, Center x%leftAlign% y+%ySpacing% w15, % seat
    GUIFunctions.UseThemeTextColor("InputBoxTextColor")
    Gui, ICScriptHub:Add, DropDownList , vDDL_BrivGemFarmLevelUpName_%seat% gBrivGemFarm_LevelUp_Name x+%xSpacing% y+-16 w111
    Gui, ICScriptHub:Add, ComboBox, Limit6 hwndHBrivGemFarmLevelUpMinLevel_%seat% vCombo_BrivGemFarmLevelUpMinLevel_%seat% gBrivGemFarm_LevelUp_MinMax_Clamp x+%xSpacing% w60
    Gui, ICScriptHub:Add, ComboBox, Limit6 hwndHBrivGemFarmLevelUpMaxLevel_%seat% vCombo_BrivGemFarmLevelUpMaxLevel_%seat% gBrivGemFarm_LevelUp_MinMax_Clamp x+%xSpacing% w60
    GUIFunctions.UseThemeTextColor()
}

Gui, ICScriptHub:Add, Text, x%leftAlign% y+20, Formation
Gui, ICScriptHub:Add, DropDownList, x+10 y+-17 w35 AltSubmit Disabled hwndBrivGemFarm_LevelUp_LoadFormation vBrivGemFarm_LevelUp_LoadFormation gBrivGemFarm_LevelUp_LoadFormation, Q||W|E
PostMessage, CB_SETITEMHEIGHT, -1, 17,, ahk_id %BrivGemFarm_LevelUp_LoadFormation%
Gui, ICScriptHub:Add, CheckBox, x+%xSpacing% y+-17 vBrivGemFarm_LevelUp_ShowSpoilers gBrivGemFarm_LevelUp_ShowSpoilers, Show spoilers

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, xs+15 y500 w449 h80 vDefaultSettingsGroup, Default Settings
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Button, xs+%leftAlign% yp+20 Disabled vBrivGemFarm_LevelUp_Default gBrivGemFarm_LevelUp_Default, Load default settings
Gui, ICScriptHub:Add, Button, x+%xSpacing% Hidden vBrivGemFarm_LevelUp_Save gBrivGemFarm_LevelUp_Save, Save
Gui, ICScriptHub:Add, Button, x+%xSpacing% Hidden vBrivGemFarm_LevelUp_Changes gBrivGemFarm_LevelUp_Changes, Show unsaved changes
Gui, ICScriptHub:Add, Button, x+%xSpacing% Hidden vBrivGemFarm_LevelUp_Undo gBrivGemFarm_LevelUp_Undo, Undo
Gui, ICScriptHub:Add, Text, xs+%leftAlign% y+%ySpacing%, Default min level:
Gui, ICScriptHub:Add, Radio, x+5 vBrivGemFarm_LevelUp_MinRadioGroup vBrivGemFarm_LevelUp_MinRadio0 gBrivGemFarm_LevelUp_MinDefault, 0
Gui, ICScriptHub:Add, Radio, x+1 vBrivGemFarm_LevelUp_MinRadioGroup vBrivGemFarm_LevelUp_MinRadio1 gBrivGemFarm_LevelUp_MinDefault, 1
Gui, ICScriptHub:Add, Text, x+5, |   Default max level:
Gui, ICScriptHub:Add, Radio, x+5 vBrivGemFarm_LevelUp_MaxRadioGroup vBrivGemFarm_LevelUp_MaxRadio1 gBrivGemFarm_LevelUp_MaxDefault, 1
Gui, ICScriptHub:Add, Radio, x+1 vBrivGemFarm_LevelUp_MaxRadioGroup vBrivGemFarm_LevelUp_MaxRadioLast gBrivGemFarm_LevelUp_MaxDefault, Last upgrade

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, GroupBox, xs+15 y585 w449 h100 vMinSettingsGroup, Min Settings
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, CheckBox, xs+%leftAlign% yp+20 vBrivGemFarm_LevelUp_ForceBrivShandie gBrivGemFarm_LevelUp_ForceBrivShandie, Level up Briv/Shandie to MinLevel first
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, xs+%leftAlign% y+%ySpacing% w40 Limit2 vBrivGemFarm_LevelUp_MaxSimultaneousInputs gBrivGemFarm_LevelUp_MaxSimultaneousInputs
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, x+5 y+-18, Maximum simultaneous F keys inputs during MinLevel
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, xs+%leftAlign% y+%ySpacing% w40 Limit5 vBrivGemFarm_LevelUp_MinLevelTimeout gBrivGemFarm_LevelUp_MinLevelTimeout
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, x+5 y+-18, MinLevel timeout (ms)

Gui, ICScriptHub:Add, Text, xs+15 y+20 w445 R2 hwndBrivGemFarm_LevelUp_Text vBrivGemFarm_LevelUp_Text, % "Status: No settings."
Gui, ICScriptHub:Add, Button, x13 y+20 Disabled vBrivGemFarm_LevelUp_LoadDefinitions gBrivGemFarm_LevelUp_LoadDefinitions, Load Definitions
Gui, ICScriptHub:Add, Text, x+10 y+-18 w450 R2 vBrivGemFarm_LevelUp_DefinitionsStatus, % "No definitions."

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
    heroDefs := g_DefinesLoader.HeroDefines.hero_defines
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
    split := StrSplit(A_GuiControl, "_")
    heroId := IC_BrivGemFarm_LevelUp_Seat.Seats[split[3]].GetCurrentHeroData().id
    Switch split[2]
    {
        Case "BrivGemFarmLevelUpMinLevel":
            g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "minLevels", heroId], clamped)
        Case "BrivGemFarmLevelUpMaxLevel":
            g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "maxLevels", heroId], clamped)
        Default:
            return
    }
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

; Spoilers
BrivGemFarm_LevelUp_ShowSpoilers()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    showSpoilers := BrivGemFarm_LevelUp_ShowSpoilers
    g_BrivGemFarm_LevelUp.TempSettings.AddSetting("ShowSpoilers", showSpoilers)
    g_BrivGemFarm_LevelUp.ToggleSpoilers(showSpoilers) ; Effect is immediate
}

; Default settings button
BrivGemFarm_LevelUp_Default()
{
    MsgBox, 4, , Restore Default settings?, 10
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
    MsgBox, 4, , Save and apply changes?, 10
    IfMsgBox, No
        Return
    IfMsgBox, Timeout
        Return
    Gui, IC_BrivGemFarm_LevelUp_TempSettings:Hide
    Gui, ICScriptHub:Submit, NoHide
    g_BrivGemFarm_LevelUp.SaveSettings(true)
}

; TempsSettings changes
BrivGemFarm_LevelUp_Changes()
{
    g_BrivGemFarm_LevelUp.TempSettings.ReloadTempSettingsDisplay()
    Gui, IC_BrivGemFarm_LevelUp_TempSettings:Show
}

; Undo temp settings button
BrivGemFarm_LevelUp_Undo()
{
    MsgBox, 4, , Undo all changes?, 10
    IfMsgBox, No
        Return
    IfMsgBox, Timeout
        Return
    g_BrivGemFarm_LevelUp.UndoTempSettings()
    Gui, IC_BrivGemFarm_LevelUp_TempSettings:Hide
}

BrivGemFarm_LevelUp_MinDefault()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    g_BrivGemFarm_LevelUp.TempSettings.AddSetting("DefaultMinLevel", BrivGemFarm_LevelUp_MinRadio0 ? 0 : 1)
    g_BrivGemFarm_LevelUp.FillMissingDefaultSettings()
}

BrivGemFarm_LevelUp_MaxDefault()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    g_BrivGemFarm_LevelUp.TempSettings.AddSetting("DefaultMaxLevel", BrivGemFarm_LevelUp_MaxRadio1 ? 1 : "Last")
    g_BrivGemFarm_LevelUp.FillMissingDefaultSettings()
}

; Force Briv/Shandie MinLevel
BrivGemFarm_LevelUp_ForceBrivShandie()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    g_BrivGemFarm_LevelUp.TempSettings.AddSetting("ForceBrivShandie", BrivGemFarm_LevelUp_ForceBrivShandie)
}

; Maximum number of simultaneous F keys inputs during MinLevel
BrivGemFarm_LevelUp_MaxSimultaneousInputs()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    maxSimultaneousInputs := BrivGemFarm_LevelUp_MaxSimultaneousInputs
    if maxSimultaneousInputs is not integer
    {
        maxSimultaneousInputs := 1
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % maxSimultaneousInputs
    }
    else if (maxSimultaneousInputs < 1)
    {
        maxSimultaneousInputs := 1
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % maxSimultaneousInputs
    }
    g_BrivGemFarm_LevelUp.TempSettings.AddSetting("MaxSimultaneousInputs", maxSimultaneousInputs)
}

; Maximum number of simultaneous F keys inputs during MinLevel
BrivGemFarm_LevelUp_MinLevelTimeout()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    minLevelTimeout := BrivGemFarm_LevelUp_MinLevelTimeout
    if minLevelTimeout is not integer
    {
        minLevelTimeout := !minLevelTimeout ? 0 : 5000
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MinLevelTimeout, % minLevelTimeout
    }
    else if (minLevelTimeout < 0)
    {
        minLevelTimeout := 0
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MinLevelTimeout, % minLevelTimeout
    }
    g_BrivGemFarm_LevelUp.TempSettings.AddSetting("MinLevelTimeout", minLevelTimeout)
}

; Load new definitions
BrivGemFarm_LevelUp_LoadDefinitions()
{
    GuiControl, ICScriptHub:Disable, BrivGemFarm_LevelUp_LoadDefinitions
    g_DefinesLoader.Start(false, true)
}

; Temp settings ListView
Gui, IC_BrivGemFarm_LevelUp_TempSettings:New, -MaximizeBox -Resize
GUIFunctions.LoadTheme("IC_BrivGemFarm_LevelUp_TempSettings")
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()
Gui IC_BrivGemFarm_LevelUp_TempSettings:Add, GroupBox, w295 h295, BrivGemFarm LevelUp Settings
Gui IC_BrivGemFarm_LevelUp_TempSettings:Add, ListView, xp+15 yp+25 w265 h250 NoSortHdr vBrivTempSettingsID , Setting|Current|New
GUIFunctions.UseThemeListViewBackgroundColor("BrivTempSettingsID")

g_BrivGemFarm_LevelUp.Init()

/*  IC_BrivGemFarm_LevelUp_Component
    Class that manages the GUI for IC_BrivGemFarm_LevelUp.

*/
Class IC_BrivGemFarm_LevelUp_Component
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"

    Settings := ""
    TempSettings := new IC_BrivGemFarm_LevelUp_Component._IC_BrivGemFarm_LevelUp_TempSettings

    ; GUI startup
    Init()
    {
        this.LoadSettings()
        ; Preload settings into the GUI
        defaultMinLevel := this.Settings.DefaultMinLevel
        defaultMaxLevel := this.Settings.DefaultMaxLevel
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinRadio%defaultMinLevel%, 1
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxRadio%defaultMaxLevel%, 1
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ShowSpoilers, % this.Settings.ShowSpoilers
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ForceBrivShandie, % this.Settings.ForceBrivShandie
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % this.Settings.MaxSimultaneousInputs
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MinLevelTimeout, % this.Settings.MinLevelTimeout
        g_DefinesLoader.Start()
    }

    ; Performs additional functions after definitions have been fully loaded
    OnHeroDefinesFinished()
    {
        this.UndoTempSettings()
        levelSettings := this.Settings.BrivGemFarm_LevelUp_Settings
        for heroID in g_HeroDefines.HeroDataByID
        {
            if (!levelSettings.minLevels.HasKey(heroID))
                levelSettings.minLevels[heroID] := this.Settings.DefaultMinLevel
            if (!levelSettings.maxLevels.HasKey(heroID))
            {
                heroData := g_HeroDefines.HeroDataByID[heroID]
                levelSettings.maxLevels[heroID] := this.Settings.DefaultMaxLevel == "Last" ? heroData.lastUpgradeLevel : 1
            }
        }
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
                       save: bool - If true, save settings to file

        Returns:
    */
    LoadSettings(default := false, save := false)
    {
        if (this.Settings == "") ; Init
        {
            settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
            if (!IsObject(settings))
            {
                settings := {}
                save := true
            }
            this.Settings := settings
        }
        defaultSettings := this.LoadDefaultSettings()
        for k, v in defaultSettings ; Fill missing default settings
        {
            if (!this.Settings.HasKey(k))
            {
                this.Settings[k] := v
                save := true
            }
            else if (IsObject(v))
            {
                for k1, v1 in v
                if (!this.Settings[k].HasKey(k1))
                {
                    this.Settings[k][k1] := v1
                    save := true
                }
                else if (IsObject(v1))
                {
                    for k2, v2 in v1
                    if (!this.Settings[k][k1].HasKey(k2))
                    {
                        this.Settings[k][k1][k2] := v2
                        save := true
                    }
                }
            }
        }
        if (default) ; Load default settings as temp settings into the GUI
        {
            this.TempSettings.AddSetting("", defaultSettings)
            defaultMinLevel := this.TempSettings.TempSettings.HasKey("DefaultMinLevel") ? this.TempSettings.TempSettings.DefaultMinLevel : this.Settings.DefaultMinLevel
            defaultMaxLevel := this.TempSettings.TempSettings.HasKey("DefaultMaxLevel") ? this.TempSettings.TempSettings.DefaultMaxLevel : this.Settings.DefaultMaxLevel
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinRadio%defaultMinLevel%, 1
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxRadio%defaultMaxLevel%, 1
            this.FillMissingDefaultSettings()
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ShowSpoilers, % defaultSettings.ShowSpoilers
            this.ToggleSpoilers(defaultSettings.ShowSpoilers)
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ForceBrivShandie, % defaultSettings.ForceBrivShandie
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % defaultSettings.MaxSimultaneousInputs
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinLevelTimeout, % defaultSettings.MinLevelTimeout
            this.LoadFormation(this.GetFormationFromGUI())
        }
        if (save)
            this.SaveSettings()
        if (default)
            this.Update("Default settings loaded.")
        else
            this.Update("Settings loaded.")
    }

    ; Load default settings to be used by IC_BrivGemFarm_LevelUp_Functions.ahk
    ; Speed champs have specific values that limit leveling to the minimum required to obtain all their speed abilities
    LoadDefaultSettings()
    {
        settings := {}
        settings.ShowSpoilers := false
        settings.ForceBrivShandie := false
        settings.MaxSimultaneousInputs := 4
        settings.MinLevelTimeout := 5000
        settings.DefaultMinLevel := 0
        settings.DefaultMaxLevel := 1
        minLevels := {}, maxLevels := {}
        minLevels[58] := 170, maxLevels[58] := 1300 ; Briv
        minLevels[47] := 120, maxLevels[47] := 120 ; Shandie
        minLevels[91] := 260, maxLevels[91] := 350 ; Widdle 260 310 350
        minLevels[28] := 90, maxLevels[28] := 200 ; Deekin 90 200
        minLevels[75] := 220, maxLevels[75] := 360 ; Hew Maan 40 200 220 360
        minLevels[102] := 90, maxLevels[102] := 250 ; Nahara
        minLevels[125] := 1, maxLevels[125] := 370 ; BBEG
        minLevels[52] := 80, maxLevels[52] := 280 ; Sentry
        minLevels[59] := 70, maxLevels[59] := 100 ; Melf
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
        minLevels[4] := 1, maxLevels[4] := 2050 ; Jarlaxle
        minLevels[39] := 1, maxLevels[39] := 2930 ; Paultin
        minLevels[103] := 1, maxLevels[103] := 2000 ; Valentine
        minLevels[124] := 1, maxLevels[124] := 890 ; Evandra
        minLevels[113] := 1, maxLevels[113] := 1370 ; Egbert
        minLevels[94] := 1, maxLevels[94] := 2520 ; Rust
        minLevels[30] := 1, maxLevels[30] := 2020 ; Azaka
        minLevels[118] := 0, maxLevels[118] := 60 ; Fen
        minLevels[40] := 0, maxLevels[40] := 215 ; Black Viper
        minLevels[97] := 0, maxLevels[97] := 80 ; Tatyana
        settings.BrivGemFarm_LevelUp_Settings := {minLevels:minLevels, maxLevels:maxLevels}
        return settings
    }

    ; Reset min/max values for other champions
    FillMissingDefaultSettings()
    {
        defaultLevelSettings := this.LoadDefaultSettings().BrivGemFarm_LevelUp_Settings
        settings := {}, minLevels := {}, maxLevels := {}
        for heroID in g_HeroDefines.HeroDataByID
        {
            if (!defaultLevelSettings.minLevels.HasKey(heroID))
                minLevels[heroID] := this.TempSettings.TempSettings.HasKey("DefaultMinLevel") ? this.TempSettings.TempSettings.DefaultMinLevel : this.Settings.DefaultMinLevel
            if (!defaultLevelSettings.maxLevels.HasKey(heroID))
            {
                heroData := g_HeroDefines.HeroDataByID[heroID]
                maxLevels[heroID] := (this.TempSettings.TempSettings.HasKey("DefaultMaxLevel") ? this.TempSettings.TempSettings.DefaultMaxLevel : this.Settings.DefaultMaxLevel) == "Last" ? heroData.lastUpgradeLevel : 1
            }
        }
        settings.BrivGemFarm_LevelUp_Settings := {minLevels:minLevels, maxLevels:maxLevels}
        this.TempSettings.AddSetting("", settings)
        this.LoadFormation(this.GetFormationFromGUI())
    }

    ; Restore last saved settings
    UndoTempSettings()
    {
        defaultMinLevel := this.Settings.DefaultMinLevel
        defaultMaxLevel := this.Settings.DefaultMaxLevel
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinRadio%defaultMinLevel%, 1
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxRadio%defaultMaxLevel%, 1
        showSpoilers := this.Settings.ShowSpoilers
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ShowSpoilers, % showSpoilers
        this.ToggleSpoilers(showSpoilers)
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ForceBrivShandie, % this.Settings.ForceBrivShandie
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % this.Settings.MaxSimultaneousInputs
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinLevelTimeout, % this.Settings.MinLevelTimeout
        this.TempSettings.Reset()
        this.LoadFormation(this.GetFormationFromGUI())
        this.Update("Settings loaded.")
    }

    ; Returns a list of champIDs from the current selected champions
    GetFormationFromGUI()
    {
        Gui, ICScriptHub:Submit, NoHide
        formation := []
        heroDefs := g_DefinesLoader.HeroDefines.hero_defines
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
        if (applyTempSettings)
        {
            this.TempSettings.Apply()
            this.Update("Settings saved.")
        }
        ; Delete redundant min/max values from file
        settings := IC_BrivGemFarm_LevelUp_Functions.ObjFullyClone(this.Settings)
        defaultLevelSettings := this.LoadDefaultSettings().BrivGemFarm_LevelUp_Settings
        levelSettings := settings.BrivGemFarm_LevelUp_Settings
        for heroID in g_HeroDefines.HeroDataByID
        {
            if (!defaultLevelSettings.minLevels.HasKey(heroID) AND levelSettings.minLevels[heroID] == this.Settings.DefaultMinLevel)
                settings.BrivGemFarm_LevelUp_Settings.minLevels.Delete(heroID)
            if (!defaultLevelSettings.maxLevels.HasKey(heroID))
            {
                heroData := g_HeroDefines.HeroDataByID[heroID]
                if (levelSettings.maxLevels[heroID] == (this.Settings.DefaultMaxLevel == "Last" ? heroData.lastUpgradeLevel : 1))
                    settings.BrivGemFarm_LevelUp_Settings.maxLevels.Delete(heroID)
            }
        }
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.UpdateSettingsFromFile(applyTempSettings)
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
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_Text, % "Status: " . text
        this.UpdateLastUpdated()
        if (this.TempSettings.Haschanges())
        {
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Save
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Changes
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Undo
        }
        else
        {
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Save
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Changes
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Undo
        }
    }

    ; Update the text that shows the last time cached_definitions.json was loaded
    UpdateLastUpdated(lastUpdateString := "", save := false)
    {
        settings := this.Settings
        if (lastUpdateString == "")
            lastUpdateString := settings.LastUpdateString
        if (save)
        {
            settings.LastUpdateString := lastUpdateString
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_DefinitionsStatus, % lastUpdateString
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
            champData := g_DefinesLoader.HeroDefines.hero_defines[v]
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
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.SaveFormations()
            savedFormations := this.Settings.SavedFormations := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath).SavedFormations
        }
        catch
        {
            noGameSave := true
        }
        if (noGameSave OR !IsObject(savedFormations))
        {
            g_SF.Memory.OpenProcessReader()
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

    ; Toggle all seats's spoilers on/off
    ToggleSpoilers(value)
    {
        Loop, 12
            IC_BrivGemFarm_LevelUp_Seat.Seats[A_Index].ToggleSpoilers(value)
    }

    ; Returns saved min/max settings
    GetLevelSettings()
    {
        return this.Settings.BrivGemFarm_LevelUp_Settings
    }

    /*  _IC_BrivGemFarm_LevelUp_TempSettings
        Class that holds temporary settings from the GUI before they are saved and passed the game's instance

    */
    Class _IC_BrivGemFarm_LevelUp_TempSettings
    {
        TempSettings := {}

        /*  AddSetting - Assing a value to a temporary setting
            Parameters:  key - An array of strings keys used to register this parameter using the same data structure than the one in Settings
                         value - Value of the setting
            Returns:
        */
        AddSetting(key, value)
        {
            static recursionDepth := 0

            Gui, ICScriptHub:Submit, NoHide
            update := false, ++recursionDepth
            if (IsObject(value))
            {
                for k, v in value
                {
                    if (IsObject(v) AND !IsObject(key))
                        key := []
                    keyNext := key.Clone()
                    keyNext.Push(k)
                    this.AddSetting(keyNext, v)
                }
                update := true
            }
            else if (IsObject(key))
            {
                if key.Length() ; Array
                {
                    lastKey := key[key.Length()]
                    if (this.GetSettingsObject(key)[lastKey] == value) ; Same value
                    {
                        tempSettingsObject := this.GetTempSettingsObject(key)
                        if (IsObject(tempSettingsObject))
                            this.DeleteTempSettingsObject(key, tempSettingsObject) ; Remove key
                        else
                            return --recursionDepth
                    }
                    else
                        this.SetTempSettingsObject(key, value) ; Add
                }
                else
                    return --recursionDepth
                update := true
            }
            else
            {
                if (value == g_BrivGemFarm_LevelUp.Settings[key]) ; Same value
                {
                    if (this.TempSettings.HasKey(key))
                        this.TempSettings.Delete(key) ; Remove key
                    else
                        return --recursionDepth
                }
                else
                    this.TempSettings[key] := value ; Add
                update := true
            }
            if (update AND --recursionDepth == 0) ; Only refresh after a change when all values have been added
            {
                this.ReloadTempSettingsDisplay()
                g_BrivGemFarm_LevelUp.Update()
            }
        }

        ; Returns the setting object found at the last key in keys
        GetSettingsObject(keys)
        {
            obj := g_BrivGemFarm_LevelUp.Settings
            Loop, % keys.Length() - 1
                obj := obj[keys[A_Index]]
            return obj
        }

        ; Returns the temporary setting object found at the last key in keys
        GetTempSettingsObject(keys)
        {
            obj := this.TempSettings
            Loop, % keys.Length() - 1
                obj := obj[keys[A_Index]]
            return obj
        }

        ; Assigns a value to the temporary setting object found at the last key in keys
        SetTempSettingsObject(keys, value)
        {
            obj := this.TempSettings
            Loop, % keys.Length() - 1
            {
                if (!obj.HasKey(keys[A_Index]))
                    obj[keys[A_Index]] := {}
                obj := obj[keys[A_Index]]
            }
            lastKey := keys[keys.Length()]
            obj[lastKey] := value
            return obj
        }

        ; Deletes the temporary setting object found at the last key in keys
        DeleteTempSettingsObject(keys, obj)
        {
            obj.Delete(keys[keys.MaxIndex()])
            if (obj.Count() == 0)
            {
                for k, v in this.TempSettings
                {
                    for k1, v1 in v
                        if (v1.Count() == 0)
                            v.Delete(k1)
                    if (v.Count() == 0)
                        this.TempSettings.Delete(k)
                }
            }
        }

        ; Returns temporary min/max settings
        GetLevelTempSettings()
        {
            return this.TempSettings.BrivGemFarm_LevelUp_Settings
        }

        ; Returns true if there is at least one unsaved temporary setting
        HasChanges()
        {
            return this.TempSettings.Count()
        }

        ; Apply temporary settings
        Apply()
        {
            for k, v in this.TempSettings
            {
                if (IsObject(v))
                    continue
                g_BrivGemFarm_LevelUp.Settings[k] := v
            }
            for k, v in this.TempSettings
            {
                if (!IsObject(v))
                    continue
                for k1, v1 in v
                    for k2, v2 in v1
                        g_BrivGemFarm_LevelUp.Settings[k][k1][k2]:= v2
            }
            this.Reset()
        }

        ; Reset temporary settings
        Reset()
        {
            this.TempSettings := {}
            this.ReloadTempSettingsDisplay()
        }

        ; Build the listview with settings / min/Max settings, showing current (saved) and new (unsaved) values
        ReloadTempSettingsDisplay()
        {
            restore_gui_on_return := GUIFunctions.LV_Scope("IC_BrivGemFarm_LevelUp_TempSettings", "BrivTempSettingsID")
            Gui, IC_BrivGemFarm_LevelUp_TempSettings:ListView, BrivTempSettingsID
            LV_Delete()
            for k, v in this.TempSettings
            {
                if (IsObject(v))
                    continue
                if (k == "ShowSpoilers" OR k == "ForceBrivShandie")
                {
                    saved := g_BrivGemFarm_LevelUp.Settings[k] ? "Yes" : "No"
                    v := v ? "Yes" : "No"
                }
                else
                    saved := g_BrivGemFarm_LevelUp.Settings[k]
                LV_Add(, k, saved, v)
            }
            for k, v in this.TempSettings ; Min/Max
            {
                if (!IsObject(v))
                    continue
                for k1, v1 in v
                {
                    for k2, v2 in v1
                    {
                        heroData := g_HeroDefines.HeroDataByID[k2]
                        showSpoilers := this.TempSettings.HasKey("ShowSpoilers") ? this.TempSettings.ShowSpoilers : g_BrivGemFarm_LevelUp.Settings.ShowSpoilers
                        if (!showSpoilers AND IC_BrivGemFarm_LevelUp_Seat.IsSpoiler(heroData.allow_time_gate))
                            continue
                        heroName := heroData.name
                        minMaxFormat := k1 == "minLevels" ? "MinLevel " : k1 == "maxLevels" ? "MaxLevel" : k1
                        settingName := minMaxFormat . " [ " . heroName . " ] "
                        saved := g_BrivGemFarm_LevelUp.Settings[k][k1][k2]
                        LV_Add(, settingName, saved, v2)
                    }
                }
            }
            Loop % LV_GetCount("Col") ; Resize columns
                LV_ModifyCol(A_Index, "AutoHdr")
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
        upgrades := heroData.upgradesList
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % "|" . upgrades
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % "|" . upgrades
        if(heroData.cachedSize == "")
            heroData.cachedSize := DropDownSize(heroData.upgradesList)
        SetMinMaxComboWidth(seat, heroData.cachedSize)
        Sleep, 1
        levelSettings := g_BrivGemFarm_LevelUp.GetLevelSettings()
        levelTempSettings := g_BrivGemFarm_LevelUp.TempSettings.GetLevelTempSettings()
        minLevel := levelTempSettings.minLevels.HasKey(k) ? levelTempSettings.minLevels[k] : levelSettings.minLevels[k]
        minLevel := minLevel != "" ? minlevel : g_BrivGemFarm_LevelUp.Settings.DefaultMinLevel
        maxLevel := levelTempSettings.maxLevels.HasKey(k) ? levelTempSettings.maxLevels[k] : levelSettings.maxLevels[k]
        maxLevel := maxLevel != "" ? maxlevel : g_BrivGemFarm_LevelUp.Settings.DefaultMaxLevel == "Last" ? heroData.lastUpgradeLevel : 1
        GuiControl, ICScriptHub:Text, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % minLevel
        GuiControl, ICScriptHub:Text, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % maxLevel
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
    }

    ; Updates the list of champions names for this lot
    UpdateNames(showSpoilers := false)
    {
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
        seat := this.ID
        choice := DDL_BrivGemFarmLevelUpName_%seat% ; Remember the current name selection
        this.UpdateNames(value)
        GuiControl, ICScriptHub:ChooseString, DDL_BrivGemFarmLevelUpName_%seat%, % choice
        Gui, ICScriptHub:Submit, NoHide
        if (choice != DDL_BrivGemFarmLevelUpName_%seat%)
            this.DeleteContents()
    }

    GetCurrentHeroData()
    {
        id := this.ID
        name := DDL_BrivGemFarmLevelUpName_%id%
        return this.HeroDataByName[name]
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
        for ID, heroData in g_DefinesLoader.HeroDefines.hero_defines
            IC_BrivGemFarm_LevelUp_Seat.Seats[heroData.seat_id].HeroDataByID[ID] := heroData
        for seatID, seat in IC_BrivGemFarm_LevelUp_Seat.Seats
            seat.UpdateNames(g_BrivGemFarm_LevelUp.Settings.ShowSpoilers)
        g_BrivGemFarm_LevelUp.OnHeroDefinesFinished()
    }
}

IC_BrivGemFarm_LevelUp_Functions.InjectAddon()

#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_DefinesLoader.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk