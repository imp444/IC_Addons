#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Constants.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Events.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Control.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Group.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_ToolTip.ahk

GUIFunctions.AddTab("BrivGF LevelUp")
; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, BrivGF LevelUp

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, x+8 Section vBGFLU_Status, Status:
Gui, ICScriptHub:Add, Text, x+5 w170 vBGFLU_StatusText, Not Running

GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
Gui, ICScriptHub:Add, Text, xs ys+15 w500 vBGFLU_StatusWarning,
GUIFunctions.UseThemeTextColor() ; WARNING: Addon was loaded too late. Stop/start Gem Farm to resume.

; Create minLevel, maxLevel, order buttons/edits
IC_BrivGemFarm_LevelUp_GUI.SetupGroups()

; Temp settings ListView
Gui, IC_BrivGemFarm_LevelUp_TempSettings:New, -MaximizeBox -Resize
GUIFunctions.LoadTheme("IC_BrivGemFarm_LevelUp_TempSettings")
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()
Gui IC_BrivGemFarm_LevelUp_TempSettings:Add, GroupBox, w330 h310, BrivGemFarm LevelUp Settings
Gui IC_BrivGemFarm_LevelUp_TempSettings:Add, ListView, xp+15 yp+24 w300 h270 NoSortHdr vBGFLU_TempSettings , Setting|Current|New
GUIFunctions.UseThemeListViewBackgroundColor("BGFLU_TempSettings")
GUIFunctions.LoadTheme()

OnMessage(WM_COMMAND, "BGFLU_CheckComboStatus")
OnMessage(0x200, Func("BGFLU_CheckComboStatus"))
OnMessage(WM_ENTERSIZEMOVE, Func("BGFLU_CheckResizeEvent").Bind(WM_ENTERSIZEMOVE))
OnMessage(WM_EXITSIZEMOVE, Func("BGFLU_CheckResizeEvent").Bind(WM_EXITSIZEMOVE))

Class IC_BrivGemFarm_LevelUp_GUI
{
    static MainGroup := ""
    static Groups := []
    static SectionNames := ["Min/Max Settings", "Min Settings", "Fail Run Recovery Settings", "GUI Settings"]

    ; Creates all of the groups of settings.
    ; All of the other groups are children of BGFLU_SettingsGroup.
    SetupGroups()
    {
        global
        this.SetupBGFLUSettingsGroup()
        this.SetupBGFLU_MinMaxSettingsGroup()
        this.SetupBGFLU_MinSettingsGroup()
        this.SetupBGFLU_FailRunRecoverySettingsGroup()
        this.SetupBGFLU_GUISettingsGroup()
        this.MainGroup.AutoResize()
        local rightMostGroupWidth := this.MainGroup.Width - 2 * this.MainGroup.XSection
        for k, v in this.MainGroup.Groups
        {
            if (k > 1) ; BGFLU_DefaultSettingsGroup
                v.UpdateSize(, rightMostGroupWidth)
        }
        this.ShowSection()
    }

    ; Add a group to the main BGFLU_SettingsGroup group.
    AddGroup(group)
    {
        group.AutoResize(true)
        this.MainGroup.AddGroup(group)
    }

    SetupBGFLUSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group_Main("BGFLU_SettingsGroup", "BrivGemFarm LevelUp Settings",, false,, "BGFLU_StatusWarning")
        this.MainGroup := group
        this.SetupBGFLU_DefaultSettingsGroup()
        GuiControlGet, pos, ICScriptHub:Pos, BGFLU_DefaultSettingsGroup
        sections := "Min/Max Settings||Min Settings|Fail Run Recovery Settings|GUI Settings"
        Gui, ICScriptHub:Font, s11
        group.AddControl("BGFLU_LB_Section", "ListBox", "AltSubmit R4 w175 gBGFLU_LB_Section x" . (PosX + PosW + 10) . " y" . (posY + 6), sections, false)
        Gui, ICScriptHub:Font, s9
    }

    SetupBGFLU_DefaultSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_DefaultSettingsGroup", "Default Settings", "BGFLU_SettingsGroup")
        group.AddControl("BGFLU_Default", "Button", "Disabled gBGFLU_Default", "Load default settings", true)
        group.AddControl("BGFLU_SettingsStatusText", "Text", "yp+5 w100", "No settings.")
        group.AddControl("BGFLU_Save", "Button", "xp yp-5 Hidden gBGFLU_Save", "Save")
        group.AddControl("BGFLU_Changes", "Button", "Hidden gBGFLU_Changes", "View changes")
        group.AddControl("BGFLU_Undo", "Button", "Hidden gBGFLU_Undo", "Undo")
        group.AddControl("BGFLU_DefaultMinLevelText", "Text",, "Default min level: ", true)
        group.AddControl("BGFLU_MinRadio0", "Radio", "x+5 gBGFLU_MinDefault", "0")
        group.AddControl("BGFLU_MinRadio1", "Radio", "x+0 gBGFLU_MinDefault", "1")
        group.AddControl("BGFLU_DefaultMaxLevelText", "Text",, "Default max level:", true)
        group.AddControl("BGFLU_MaxRadio1", "Radio", "x+5 gBGFLU_MaxDefault", "1")
        group.AddControl("BGFLU_MaxRadioLast", "Radio", "x+0 gBGFLU_MaxDefault", "Last upgrade")
        this.AddGroup(group)
    }

    SetupBGFLU_MinMaxSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_MinMaxSettingsGroup", "Min/Max Settings",, false)
        group.AddControl("BGFLU_SeatText", "Text", "Center", "Seat", true)
        group.AddControl("BGFLU_NameText", "Text", "Center w104", "Name")
        group.AddControl("BGFLU_MinLevelText", "Text", "Center w60", "MinLevel")
        group.AddControl("BGFLU_MaxLevelText", "Text", "Center w60", "MaxLevel")
        GuiControlGet, pos, ICScriptHub:Pos, BGFLU_SeatText
        Loop, 12
            this.AddSeat(A_Index, group, posW)
        group.AddControl("BGFLU_LoadFormationText", "Text", "y+15", "Formation", true)
        group.AddControl("BGFLU_LoadFormation", "DropDownList", "y+-17 w35 AltSubmit Disabled hwndBGFLU_LoadFormation gBGFLU_LoadFormation", "Q||W|E")
        SendMessage, CB_SETITEMHEIGHT, -1, 17,, ahk_id %BGFLU_LoadFormation%
        if (ErrorLevel)
            MsgBox, 16,, Failed to resize BGFLU_LoadFormation.
        ; Spoilers
        group.AddCheckBox("BGFLU_ShowSpoilers",, "y+-17", "Show spoilers")
        GUIFunctions.UseThemeTextColor("ErrorTextColor", 700)
        group.AddControl("BGFLU_NoFormationText", "Text", "w220")
        GUIFunctions.UseThemeTextColor()
        this.AddGroup(group)
    }

    ; Add settings for the next seat
    AddSeat(seat, group, seatW)
    {
        global
        group.AddControl("BGFLU_SeatIDText_" . seat, "Text", "Center w" . seatW, seat, true)
        group.AddControl("BGFLU_DDL_Name_" . seat, "DropDownList", "gBGFLU_Name yp-4 w104")
        group.AddControl("BGFLU_Combo_MinLevel_" . seat, "ComboBox", "Limit6 hwndHBGFLU_MinLevel_" . seat . " gBGFLU_MinMax_Clamp w60")
        group.AddControl("BGFLU_Combo_MaxLevel_" . seat, "ComboBox", "Limit6 hwndHBGFLU_MaxLevel_" . seat . " gBGFLU_MinMax_Clamp w60")
    }

    SetupBGFLU_MinSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_MinSettingsGroup", "Min Settings",, false)
        ; Force Briv/Shandie MinLevel
        group.AddCheckBox("BGFLU_ForceBrivShandie",,, "Level up Briv/Shandie to MinLevel first", true)
        ; Skip early Dashwait
        group.AddCheckBox("BGFLU_SkipMinDashWait",,, "Skip DashWait after Min Leveling")
        ; Maximum number of simultaneous F keys inputs during DoPartySetupMin()
        group.AddEdit("BGFLU_MaxSimultaneousInputs",, "w50 Limit2",, true)
        group.AddControl("BGFLU_MaxSimultaneousInputsText", "Text", "x+5 yp+4", "Maximum simultaneous F keys inputs during MinLevel")
        ; Timeout during DoPartySetupMin()
        group.AddEdit("BGFLU_MinLevelTimeout",, "w50 Limit5",, true)
        group.AddControl("BGFLU_MinLevelTimeoutText", "Text", "x+5 yp+4", "MinLevel timeout (ms)")
        group.AddControl("BGFLU_Combo_BrivMinLevelStacking", "ComboBox", "w50 Limit5 hwndHBGFLU_BrivMinLevelStacking gBGFLU_MinMax_Clamp",, true)
        group.AddControl("BGFLU_BrivMinLevelStackingText", "Text", "x+5 yp+4", "Briv MinLevel before stacking")
        ; BrivMinLevelArea
        group.AddEdit("BGFLU_BrivMinLevelArea",, "w50 Limit4",, true)
        group.AddControl("BGFLU_BrivMinLevelAreaText", "Text", "x+5 yp+4", "Minimum area to reach before leveling Briv")
        this.AddGroup(group)
    }

    SetupBGFLU_FailRunRecoverySettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_FailRunRecoverySettingsGroup", "Fail Run Recovery Settings",, false)
        ; Level champions to soft cap after a failed conversion to reach stack zone faster
        group.AddCheckBox("BGFLU_LevelToSoftCapFailedConversion",,, "Level champions to soft cap after failed conversion", true)
        ; Level champions to soft cap after a failed conversion to reach stack zone faster (Briv is excluded, desireable for early stacking)
        group.AddCheckBox("BGFLU_LevelToSoftCapFailedConversionBriv",,, "Briv included")
        this.AddGroup(group)
    }

    SetupBGFLU_GUISettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_GUISettingsGroup", "GUI Settings",, false)
        group.AddControl("BGFLU_LoadDefinitions", "Button", "Disabled gBGFLU_LoadDefinitions", "Load Definitions", true)
        group.AddControl("BGFLU_DefinitionsStatus", "Text", "yp+4 w450 R3", "No definitions.")
        group.AddControl("BGFLU_DefinitionsPathText", "Text",, "Current location:", true)
        group.AddControl("BGFLU_DefinitionsPath", "Edit", "-Background -VScroll Disabled w450 R2",, true)
        this.AddGroup(group)
    }

    ; Show the maximum amount of groups.
    ; Always include BGFLU_DefaultSettingsGroup, BGFLU_LB_Section control and at least one group.
    ShowSection(section := 2)
    {
        minY := this.GetDefaultSettingsGroupYPos()
        displayed := this.GetDisplayedSections(section)
        for k, v in this.MainGroup.Groups
        {
            if (k > 1)
            {
                if (displayed.HasKey(k))
                {
                    if (displayed.HasKey(k - 1))
                        v.Move(, displayed[k-1])
                    else
                        v.Move(, minY)
                    v.Show()
                }
                else
                {
                    v.Hide()
                    v.Move(, minY)
                }
            }
        }
        this.UpdateLBSection(displayed)
        this.MainGroup.AutoResize()
    }

    ; Update indicators showing currently displated sections
    UpdateLBSection(displayed)
    {
        names := this.SectionNames
        selection := ""
        for k, v in names
            selection .= (displayed.HasKey(k + 1) ? "‣" : " ") . v . "|"
        GuiControl, ICScriptHub:, BGFLU_LB_Section, % "|" . selection
    }

    ; Returns an object that contains the groups to display and the new Y position of the group.
    ; Doesn't include the first default group BGFLU_DefaultSettingsGroup.
    ; The maximum of groups that fit into the main window will be displayed.
    ; The groups after the group of firstSection index are prioritized in descending order.
    ; Then the groups above that one are backtracked in ascending order.
    GetDisplayedSections(firstSection := 2)
    {
        displayed := {}
        if (firstSection < 2)
            firstSection := 2
        cursor := this.GetDefaultSettingsGroupYPos()
        maxHeight := this.GetMaxDisplayHeight()
        belowGroupCount := this.MainGroup.Groups.Length() - firstSection + 1
        Loop, % belowGroupCount
        {
            groupIndex := firstSection + A_Index - 1
            cursor += this.GetNextGroupHeight(groupIndex)
            if (cursor < maxHeight OR displayed.Count() == 0)
            {
                cursor += 10
                displayed[groupIndex] := cursor
            }
            else
                return displayed
        }
        Loop, % firstSection - 2
        {
            groupIndex := firstSection - A_Index
            cursor += this.GetNextGroupHeight(groupIndex)
            if (cursor < maxHeight OR displayed.Count() == 0)
            {
                cursor += 10
                displayed[groupIndex] := cursor
            }
            else
                break
        }
        return this.GetMaxDisplayedSections(displayed)
    }

    ; Returns an object that contains the displayed groups in order and their Y positions.
    GetMaxDisplayedSections(displayed)
    {
        cursor := this.GetDefaultSettingsGroupYPos()
        for k, v in displayed
        {
            cursor += this.GetNextGroupHeight(k) + 10
            displayed[k] := cursor
        }
        return displayed
    }

    ; Returns the default position for all of the grousp below BGFLU_DefaultSettingsGroup.
    GetDefaultSettingsGroupYPos()
    {
        GuiControlGet, minPos, ICScriptHub:Pos, BGFLU_DefaultSettingsGroup
        return minPosY + minPosH + 10 ; Second group start pos
    }

    ; Returns the height of the next group to display.
    GetNextGroupHeight(index)
    {
        group := this.MainGroup.Groups[index]
        controlID := group.ControlID
        GuiControlGet, nextGroupPos, ICScriptHub:Pos, %controlID%
        return nextGroupPosH
    }

    ; Returns the maximum visible height of this addon's tab.
    GetMaxDisplayHeight()
    {
        GuiControlGet, maxPos, ICScriptHub:Pos, ModronTabControl
        maxTabHeight := maxPosH + maxPosY
        ; Get monitor height without task bar
        monitor := IC_BrivGemFarm_LevelUp_Functions.GetMonitor("ModronTabControl")
        SysGet, monitorCoords, MonitorWorkArea, %monitor%
        ; Get ICScriptHub window coords
        GuiControlGet, hnwd, ICScriptHub:Hwnd, ModronTabControl
        WinGetPos, x, y, w, h, IC Script Hub
        maxDisplayHeight := monitorCoordsBottom - y - h + maxTabHeight
        maxDisplayHeight := Min(maxTabHeight, maxDisplayHeight)
        return maxDisplayHeight
    }
}