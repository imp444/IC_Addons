SM_CXVSCROLL := 2
CBN_DROPDOWN := 7
CBN_SELENDCANCEL := 10
WM_COMMAND := 0x0111
CB_DELETESTRING := 0x0144
CB_GETCOUNT := 0x146
CB_GETCURSEL := 0x147
CB_GETDROPPEDCONTROLRECT := 0x0152
CB_SETITEMHEIGHT := 0x0153
CB_GETDROPPEDSTATE := 0x0157
CB_SETDROPPEDWIDTH := 0x0160
CB_GETCOMBOBOXINFO := 0x0164
WM_ENTERSIZEMOVE := 0x0231
WM_EXITSIZEMOVE := 0x0232

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

BGFLU_CheckResizeEvent(WM)
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_CheckResizeEvent(WM)
}

BGFLU_DoResizeEvent()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_DoResizeEvent()
}

BGFLU_CheckComboStatus(W)
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_CheckComboStatus(W)
}

BGFLU_LB_Section()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_LB_Section()
}

BGFLU_Name()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_Name()
}

BGFLU_MinMax_Clamp()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_MinMax_Clamp()
}

BGFLU_LoadFormation()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_LoadFormation()
}

BGFLU_ShowSpoilers()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_ShowSpoilers()
}

BGFLU_Default()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_Default()
}

BGFLU_Save()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_Save()
}

BGFLU_Changes()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_Changes()
}

BGFLU_Undo()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_Undo()
}

BGFLU_MinDefault()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_MinDefault()
}

BGFLU_MaxDefault()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_MaxDefault()
}

BGFLU_ForceBrivShandie()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_ForceBrivShandie()
}

BGFLU_SkipMinDashWait()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_SkipMinDashWait()
}

BGFLU_MaxSimultaneousInputs()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_MaxSimultaneousInputs()
}

BGFLU_MinLevelTimeout()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_MinLevelTimeout()
}

BGFLU_BrivMinLevelArea()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_BrivMinLevelArea()
}

BGFLU_LevelToSoftCapFailedConversion()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_LevelToSoftCapFailedConversion()
}

BGFLU_LevelToSoftCapFailedConversionBriv()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_LevelToSoftCapFailedConversionBriv()
}

BGFLU_LoadDefinitions()
{
    IC_BrivGemFarm_LevelUp_GUI.BGFLU_LoadDefinitions()
}

; Class that allows to group controls under a GroupBox control.
Class IC_BrivGemFarm_LevelUp_GUI_Group
{
    Controls := []
    GroupID := 0
    Height := 0
    Width := 0
    XSpacing := 10
    YSpacing := 10
    YTitleSpacing := 20
    XSection := 10
    YSection := 10
    Hidden := false

    ; Creates a new GroupBox.
    ; Parameters: - name:str - The name/reference of the group.
    ;             - title:str - The title of the control that will appear on the outline.
    ;             - previous:str - The reference control that is used to position the new group.
    ;             - tabS:bool - If true, adds an x offset to this group from the previous control equal to XSection.
    ;             - newLine:bool - If true, position the group under the previous control.
    __New(name, title := "", previous := "BGFLU_DefaultSettingsGroup", tabS := true, newLine := true)
    {
        global
        this.GroupID := name
        GuiControlGet, previousPos, ICScriptHub:Pos, %previous%
        local groupX := previousPosX + (tabS ? this.XSection : 0) + (newLine ? 0 : previousPosW)
        local options := "Section w0 h10 v" . name . " x" . groupX
        local ySpacing := previousPosY + previousPosH + (newLine ? this.YSpacing : 0)
        options .= " y" . (newLine ? ySpacing : "s")
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, %options% , %title%
        Gui, ICScriptHub:Font, w400
    }

    ; Creates and adds a control to the GroupBox.
    ; Parameters: - controlID:str - The name/reference of the control.
    ;             - controlType:str - The type of the control.
    ;             - options:str - Options to apply to the control. X/Y positionals override the default values.
    ;             - text:str - The initial text of the control.
    ;             - newLine:bool - If true, position the control under the previous ones.
    AddControl(controlID, controlType := "", options := "", text := "", newLine := false)
    {
        global
        if (controlType != "")
        {
            if controlType in ComboBox,DropDownList,Edit,ListBox
                GUIFunctions.UseThemeTextColor("InputBoxTextColor")
            if (!RegExMatch(options, "x(\d+|\+|\-|m|p|s[^\s])"))
            {
                if (newLine)
                    options .= " xs+" . this.XSection
                else
                    options .= " x+" . this.XSpacing
            }
            if (!RegExMatch(options, "y(\d+|\+|\-|m|p|s[^\s])"))
            {
                if (this.Controls.Length() == 0)
                    options .= " ys+" . this.YTitleSpacing
                else if (newLine)
                    options .= " y+" . this.YSpacing
            }
            options .= " v" . controlID
            Gui, ICScriptHub:Add, %controlType%, %options%, % text
            GUIFunctions.UseThemeTextColor()
        }
        this.Controls.Push(controlID)
    }

    ; Show the GroupBox outline and its controls.
    Show()
    {
        for k, v in this.Controls
            GuiControl, ICScriptHub:Show, %v%
        controlID := this.GroupID
        GuiControl, ICScriptHub:Show, %controlID%
        this.Hidden := false
    }

    ; Hide the GroupBox outline and its controls.
    Hide()
    {
        for k, v in this.Controls
            GuiControl, ICScriptHub:Hide, %v%
        controlID := this.GroupID
        GuiControl, ICScriptHub:Hide, %controlID%
        this.Hidden := true
    }

    ; Moves the GroupBox outline and its controls to a new position.
    ; Parameters: - x:int - New X postion of the GroupBox.
    ;             - y:int - New Y postion of the GroupBox.
    Move(x := "", y := "")
    {
        controlID := this.GroupID
        GuiControlGet, oldPos, ICScriptHub:Pos, %controlID%
        x := x == "" ? oldPosX : x
        y := y == "" ? oldPosY : y
        if (x == oldPosX AND y == oldPosY)
            return
        GuiControl, ICScriptHub:Move, %controlID%, x%x% y%y%
        ; Bug when using Move in a Tab control
        GuiControlGet, bugPos, ICScriptHub:Pos, %controlID%
        xFixBug := 2 * x - bugPosX
        yFixBug := 2 * y - bugPosY
        xOffset := xFixBug - oldPosX
        yOffset := yFixBug - oldPosY
        GuiControl, ICScriptHub:MoveDraw, %controlID%, x%xFixBug% y%yFixBug%
        for k, v in this.Controls
        {
            GuiControlGet, oldPos, ICScriptHub:Pos, %v%
            newX := oldPosX + xOffset
            newY := oldPosY + yOffset
            GuiControl, ICScriptHub:MoveDraw, %v%, x%newX% y%newY%
        }
    }

    ; Returns the control with the lowest Y position within the GroupBox.
    ; Ignores controls that have been previousy hidden.
    GetLowestControl()
    {
        yMax := 0
        lowest := ""
        for k, v in this.Controls
        {
            if (IC_BrivGemFarm_LevelUp_GUI.GroupsByName[v].Hidden)
                continue
            GuiControlGet, pos, ICScriptHub:Pos, %v%
            if (posY + posH > yMax)
            {
                yMax := posY + posH
                lowest := v
            }
        }
        return lowest
    }

    ; Returns the control with the furthest X position within the GroupBox.
    ; Ignores controls that have been previousy hidden.
    GetRightMostControl()
    {
        xMax := 0
        rightMost := ""
        for k, v in this.Controls
        {
            if (IC_BrivGemFarm_LevelUp_GUI.GroupsByName[v].Hidden)
                continue
            GuiControlGet, pos, ICScriptHub:Pos, %v%
            if (posX + posW > xMax)
            {
                xMax := posX + posW
                rightMost := v
            }
        }
        return rightMost
    }

    ; Calculates the size of this GroupBox's outline that contours all of its controls.
    AutoResize()
    {
        lowest := this.GetLowestControl()
        GuiControlGet, posL, ICScriptHub:Pos, %lowest%
        rightMost := this.GetRightMostControl()
        GuiControlGet, posR, ICScriptHub:Pos, %rightMost%
        controlID := this.GroupID
        GuiControlGet, posS, ICScriptHub:Pos, %controlID%
        newHeight := posLY + posLH - posSY + this.YSection
        newWidth := posRX + posRW - posSX + this.XSection
        this.UpdateSize(newHeight, newWidth)
    }

    ; Resizes this GroupBox's outline.
    ; Parameters: - newHeight:int - New height of the GroupBox.
    ;             - newWidth:int - New width of the GroupBox.
    UpdateSize(newHeight := "", newWidth := "")
    {
        controlID := this.GroupID
        if (newHeight != "")
            this.Height := newHeight
        else
            newHeight := this.Height
        if (newWidth != "")
            this.Width := newWidth
        else
            newWidth := this.Width
        GuiControl, ICScriptHub:Move, %controlID%, h%newHeight% w%newWidth%
    }
}

Class IC_BrivGemFarm_LevelUp_GUI
{
    static MainGroup := ""
    static Groups := []
    static GroupsByName := {}

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
        for k, v in this.Groups
        {
            if (k > 1) ; BGFLU_DefaultSettingsGroup
                v.UpdateSize(, rightMostGroupWidth)
        }
        this.ShowSection()
    }

    ; Add a group to the main BGFLU_SettingsGroup group.
    AddGroup(group)
    {
        group.AutoResize()
        this.Groups.Push(group)
        this.GroupsByName[group.GroupID] := group
        this.MainGroup.AddControl(group.GroupID)
    }

    SetupBGFLUSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_SettingsGroup", "BrivGemFarm LevelUp Settings", "BGFLU_StatusWarning", false)
        this.MainGroup := group
        this.SetupBGFLU_DefaultSettingsGroup()
        GuiControlGet, pos, ICScriptHub:Pos, BGFLU_DefaultSettingsGroup
        sections := "Min/Max Settings||Min Settings|Fail Run Recovery Settings|GUI Settings"
        Gui, Font, s11
        group.AddControl("BGFLU_LB_Section", "ListBox", "AltSubmit R4 w175 gBGFLU_LB_Section x" . (PosX + PosW + 10) . " y" . (posY + 6), sections, false)
        Gui, Font, s9
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
        PostMessage, CB_SETITEMHEIGHT, -1, 17,, ahk_id %BGFLU_LoadFormation%
        group.AddControl("BGFLU_ShowSpoilers", "CheckBox", "y+-17 gBGFLU_ShowSpoilers", "Show spoilers")
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
        group.AddControl("BGFLU_ForceBrivShandie", "CheckBox", "gBGFLU_ForceBrivShandie", "Level up Briv/Shandie to MinLevel first", true)
        group.AddControl("BGFLU_SkipMinDashWait", "CheckBox", "gBGFLU_SkipMinDashWait", "Skip DashWait after Min Leveling")
        group.AddControl("BGFLU_MaxSimultaneousInputs", "Edit", "w50 Limit2 gBGFLU_MaxSimultaneousInputs",, true)
        group.AddControl("BGFLU_MaxSimultaneousInputsText", "Text", "x+5 yp+4", "Maximum simultaneous F keys inputs during MinLevel")
        group.AddControl("BGFLU_MinLevelTimeout", "Edit", "w50 Limit5 gBGFLU_MinLevelTimeout",, true)
        group.AddControl("BGFLU_MinLevelTimeoutText", "Text", "x+5 yp+4", "MinLevel timeout (ms)")
        group.AddControl("BGFLU_Combo_BrivMinLevelStacking", "ComboBox", "w50 Limit5 hwndHBGFLU_BrivMinLevelStacking gBGFLU_MinMax_Clamp",, true)
        group.AddControl("BGFLU_BrivMinLevelStackingText", "Text", "x+5 yp+4", "Briv MinLevel before stacking")
        group.AddControl("BGFLU_BrivMinLevelArea", "Edit", "w50 Limit4 gBGFLU_BrivMinLevelArea",, true)
        group.AddControl("BGFLU_BrivMinLevelAreaText", "Text", "x+5 yp+4", "Minimum area to reach before leveling Briv")
        this.AddGroup(group)
    }

    SetupBGFLU_FailRunRecoverySettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_FailRunRecoverySettingsGroup", "Fail Run Recovery Settings",, false)
        group.AddControl("BGFLU_LevelToSoftCapFailedConversion", "CheckBox", "gBGFLU_LevelToSoftCapFailedConversion", "Level champions to soft cap after failed conversion", true)
        group.AddControl("BGFLU_LevelToSoftCapFailedConversionBriv", "CheckBox", "gBGFLU_LevelToSoftCapFailedConversionBriv", "Briv included")
        this.AddGroup(group)
    }

    SetupBGFLU_GUISettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_GUISettingsGroup", "GUI Settings",, false)
        group.AddControl("BGFLU_LoadDefinitions", "Button", "Disabled gBGFLU_LoadDefinitions", "Load Definitions", true)
        group.AddControl("BGFLU_DefinitionsStatus", "Text", "yp+4 w450 R3", "No definitions.")
        this.AddGroup(group)
    }

    ; Show the maximum amount of groups.
    ; Always include BGFLU_DefaultSettingsGroup, BGFLU_LB_Section control and at least one group.
    ShowSection(section := 2)
    {
        minY := this.GetDefaultSettingsGroupYPos()
        displayed := this.GetDisplayedSections(section)
        for k, v in this.Groups
        {
            control := this.Groups[k]
            if (k > 1)
            {
                if (displayed.HasKey(k))
                {
                    if (displayed.HasKey(k - 1))
                        control.Move(, displayed[k-1])
                    else
                        control.Move(, minY)
                    v.Show()
                }
                else
                {
                    v.Hide()
                    control.Move(, minY)
                }
            }
        }
        this.MainGroup.AutoResize()
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
        GuiControlGet, maxPos, ICScriptHub:Pos, ModronTabControl
        maxHeight := maxPosH + maxPosY
        belowGroupCount := this.Groups.Length() - firstSection + 1
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
        group := this.Groups[index]
        controlID := group.GroupID
        GuiControlGet, nextGroupPos, ICScriptHub:Pos, %controlID%
        return nextGroupPosH
    }

    ; Checks performed on GUI resize event
    BGFLU_CheckResizeEvent(WM)
    {
        global
        GuiControlGet, currentTab,, ModronTabControl, Tab
        if (WM == WM_ENTERSIZEMOVE AND currentTab == "BrivGF LevelUp")
            SetTimer, BGFLU_DoResizeEvent, 200
        else if (WM == WM_EXITSIZEMOVE)
        {
            SetTimer, BGFLU_DoResizeEvent, Delete
            this.BGFLU_DoResizeEvent()
        }
    }

    ; Action performed on GUI resize event
    BGFLU_DoResizeEvent()
    {
        global
        this.ShowSection(BGFLU_LB_Section + 1)
    }

    ; Jump to section
    BGFLU_LB_Section()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        this.ShowSection(value + 1)
    }

    ; Switch names
    BGFLU_Name()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local name := % %A_GuiControl%
        local heroData := g_HeroDefines.HeroDataByName[name]
        IC_BrivGemFarm_LevelUp_Seat.Seats[heroData.seat_id].UpdateMinMaxLevels(name)
    }

    ; Input upgrade level when selected from DDL, then verify that min/max level inputs are in 0-999999 range
    BGFLU_MinMax_Clamp()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        local clamped := value
        Loop, Parse, clamped, :, " "
        {
            clamped := A_LoopField
            break
        }
        if clamped is not digit
        {
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % beforeSubmit
            Gui, ICScriptHub:Submit, NoHide
            return
        }
        if (clamped != value)
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % clamped
        local split := StrSplit(A_GuiControl, "_")
        local heroId := IC_BrivGemFarm_LevelUp_Seat.Seats[split[4]].GetCurrentHeroData().id
        Switch split[3]
        {
            Case "MinLevel":
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "minLevels", heroId], clamped)
            Case "MaxLevel":
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "maxLevels", heroId], clamped)
            Case "BrivMinLevelStacking":
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting("BrivMinLevelStacking", clamped)
            Default:
                return
        }
    }

    ; Load formation to the GUI
    BGFLU_LoadFormation()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        GuiControl, ICScriptHub:Disable, BGFLU_LoadFormation
        Sleep, 20
        g_BrivGemFarm_LevelUp.LoadFormation(%A_GuiControl%)
        GuiControl, ICScriptHub:Enable, BGFLU_LoadFormation
    }

    ; Spoilers
    BGFLU_ShowSpoilers()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local showSpoilers := BGFLU_ShowSpoilers
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("ShowSpoilers", showSpoilers)
        g_BrivGemFarm_LevelUp.ToggleSpoilers(showSpoilers) ; Effect is immediate
    }

    ; Default settings button
    BGFLU_Default()
    {
        global
        MsgBox, 4, , Restore Default settings?, 10
        IfMsgBox, No
            Return
        IfMsgBox, Timeout
            Return
        GuiControl, ICScriptHub:Disable, BGFLU_Default
        g_BrivGemFarm_LevelUp.LoadSettings(true)
        GuiControl, ICScriptHub:Enable, BGFLU_Default
    }

    ; Save settings button
    BGFLU_Save()
    {
        global
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
    BGFLU_Changes()
    {
        global
        g_BrivGemFarm_LevelUp.TempSettings.ReloadTempSettingsDisplay()
        Gui, IC_BrivGemFarm_LevelUp_TempSettings:Show
    }

    ; Undo temp settings button
    BGFLU_Undo()
    {
        global
        MsgBox, 4, , Undo all changes?, 10
        IfMsgBox, No
            Return
        IfMsgBox, Timeout
            Return
        g_BrivGemFarm_LevelUp.UndoTempSettings()
        Gui, IC_BrivGemFarm_LevelUp_TempSettings:Hide
    }

    ; Default min values for champions without default parameters.
    BGFLU_MinDefault()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("DefaultMinLevel", BGFLU_MinRadio0 ? 0 : 1)
        g_BrivGemFarm_LevelUp.FillMissingDefaultSettings()
    }

    ; Default max values for champions without default parameters.
    BGFLU_MaxDefault()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("DefaultMaxLevel", BGFLU_MaxRadio1 ? 1 : "Last")
        g_BrivGemFarm_LevelUp.FillMissingDefaultSettings()
    }

    ; Force Briv/Shandie MinLevel
    BGFLU_ForceBrivShandie()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("ForceBrivShandie", BGFLU_ForceBrivShandie)
    }

    ; Skip early Dashwait
    BGFLU_SkipMinDashWait()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("SkipMinDashWait", BGFLU_SkipMinDashWait)
    }

    ; Maximum number of simultaneous F keys inputs during MinLevel
    BGFLU_MaxSimultaneousInputs()
    {
        global
        local beforeSubmit := BGFLU_MaxSimultaneousInputs
        Gui, ICScriptHub:Submit, NoHide
        local maxSimultaneousInputs := BGFLU_MaxSimultaneousInputs
        if maxSimultaneousInputs is not digit
        {
            GuiControl, ICScriptHub:Text, BGFLU_MaxSimultaneousInputs, % beforeSubmit
            return
        }
        else if (maxSimultaneousInputs < 1)
        {
            maxSimultaneousInputs := 1
            GuiControl, ICScriptHub:Text, BGFLU_MaxSimultaneousInputs, % maxSimultaneousInputs
        }
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("MaxSimultaneousInputs", maxSimultaneousInputs)
    }

    ; Maximum number of simultaneous F keys inputs during MinLevel
    BGFLU_MinLevelTimeout()
    {
        global
        local beforeSubmit := BGFLU_MinLevelTimeout
        Gui, ICScriptHub:Submit, NoHide
        local minLevelTimeout := BGFLU_MinLevelTimeout
        if minLevelTimeout is not digit
            GuiControl, ICScriptHub:Text, BGFLU_MinLevelTimeout, % beforeSubmit
        else
            g_BrivGemFarm_LevelUp.TempSettings.AddSetting("MinLevelTimeout", minLevelTimeout)
    }

    ; BrivMinLevelArea
    BGFLU_BrivMinLevelArea()
    {
        global
        local beforeSubmit := BGFLU_BrivMinLevelArea
        Gui, ICScriptHub:Submit, NoHide
        local brivMinLevelArea := BGFLU_BrivMinLevelArea
        if brivMinLevelArea is not digit
        {
            GuiControl, ICScriptHub:Text, BGFLU_BrivMinLevelArea, % beforeSubmit
            return
        }
        else if (brivMinLevelArea < 1)
        {
            brivMinLevelArea := 1
            GuiControl, ICScriptHub:Text, BGFLU_BrivMinLevelArea, % brivMinLevelArea
        }
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("BrivMinLevelArea", brivMinLevelArea)
    }

    ; Level champions to soft cap after a failed conversion to reach stack zone faster
    BGFLU_LevelToSoftCapFailedConversion()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("LevelToSoftCapFailedConversion", BGFLU_LevelToSoftCapFailedConversion)
    }

    ; Level champions to soft cap after a failed conversion to reach stack zone faster (Briv is excluded, desireable for early stacking)
    BGFLU_LevelToSoftCapFailedConversionBriv()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("LevelToSoftCapFailedConversionBriv", BGFLU_LevelToSoftCapFailedConversionBriv)
    }

    ; Load new definitions
    BGFLU_LoadDefinitions()
    {
        global
        GuiControl, ICScriptHub:Disable, BGFLU_LoadDefinitions
        g_DefinesLoader.Start(false, true)
    }

    ; Checks performed on combo mouseover / selection cancel
    BGFLU_CheckComboStatus(W)
    {
        global
        local arr := this.GetCurrentlyDroppedCombo()
        if (local seat_ID := arr[1])
        {
            if ((W >> 16) & 0xFFFF == CBN_SELENDCANCEL) ; Refresh min/max values after a ComboBox sends a selection cancel event to the parent tab
            {
                ToolTip
                if (seat_ID == 58)
                {
                    local ctrlH := arr[2], k := "BrivMinLevelStacking"
                    local brivMinLevelStacking := g_BrivGemFarm_LevelUp.TempSettings.TempSettings.HasKey(k) ? g_BrivGemFarm_LevelUp.TempSettings.TempSettings[k] : g_BrivGemFarm_LevelUp.Settings[k]
                    SendMessage, CB_GETCOUNT, 0, 0,, ahk_id %ctrlH%
                    local count := Errorlevel
                    GuiControl, ICScriptHub:, BGFLU_Combo_BrivMinLevelStacking, % brivMinLevelStacking ; Add item
                    GuiControl, ICScriptHub:Text, BGFLU_Combo_BrivMinLevelStacking, % brivMinLevelStacking ; so only the level is kept in edit
                    PostMessage, CB_DELETESTRING, count, 0,, ahk_id %ctrlH% ; Remove item
                }
                else
                {
                    local choice := % BGFLU_DDL_Name_%seat_ID%
                    if (choice == g_HeroDefines.HeroDataByID[58].name) ; After %choice%, ErrorLevel is set to 1 for an unknown reason
                        GuiControl, ICScriptHub:ChooseString, BGFLU_DDL_Name_5, % "|" . choice
                    else
                        GuiControl, ICScriptHub:ChooseString, %choice%, % "|" . choice
                }
            }
            else if (this.MouseOverComboBoxList(ctrlH := arr[2])) ; Show current selection as tooltip
            {
                OnMessage(0x200, "CheckControlForToolTip",0)
                func := ObjBindMethod(this, "RemoveToolTip")
                SetTimer, %func%, -500
                SendMessage, CB_GETCURSEL, 0, 0,, ahk_id %ctrlH%
                local currentSel := ErrorLevel ; 0 based
                heroData := IC_BrivGemFarm_LevelUp_Seat.Seats[(seat_ID == 58 ? 5 : seat_ID)].GetCurrentHeroData()
                ToolTip, % IC_BrivGemFarm_LevelUp_Functions.WrapText(heroData.UpgradeDescriptionFromIndex(currentSel + 1))
                SetTimer, HideToolTip, Delete
                OnMessage(0x200, "CheckControlForToolTip")
            }
        }
    }

    ; Remove comboBox toolip when not hovering
    RemoveToolTip()
    {
        arr := this.GetCurrentlyDroppedCombo()
        MouseGetPos,,,, VarControl ; CheckControlForToolTip()
        if (!VarControl AND !(arr[1] AND this.MouseOverComboBoxList(arr[2])))
            ToolTip
    }

    ; Returns an array containing the corresponding seatID / control Hwnd of the currently dropped combo
    GetCurrentlyDroppedCombo()
    {
        global
        GuiControlGet, CurrentTab,, ModronTabControl, Tab
        if (CurrentTab != "BrivGF LevelUp")
            return
        Loop, 12
        {
            local ctrlHwnd := HBGFLU_MinLevel_%A_Index%
            SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
            if (Errorlevel)
                return [A_Index, ctrlHwnd]
            ctrlHwnd := HBGFLU_MaxLevel_%A_Index%
            SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
            if (Errorlevel)
                return [A_Index, ctrlHwnd]
        }
        ctrlHwnd := HBGFLU_BrivMinLevelStacking
        SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
        if (Errorlevel)
            return [58, ctrlHwnd]
    }

    ; Returns true if the mouse is within the rectangle of a combobox's item list
    MouseOverComboBoxList(controlID)
    {
        global
        SysGet, scrollW, %SM_CXVSCROLL% ; Scrollbar width
        VarSetCapacity(COMBOBOXINFO, size := 40 + A_PtrSize*3, 0)
        NumPut(size, COMBOBOXINFO)
        SendMessage, CB_GETCOMBOBOXINFO,, &COMBOBOXINFO,, ahk_id %controlID%
        local yMaxEdit := NumGet(COMBOBOXINFO, 16, "Int") ; Combo edit height
        VarSetCapacity(RECT, 16, 0)
        NumPut(16, RECT)
        SendMessage, CB_GETDROPPEDCONTROLRECT,, &RECT,, ahk_id %controlID% ; Full combo rect
        local xMin := NumGet(RECT, 0, "Int")
        local yMin := NumGet(RECT, 4, "Int") + yMaxEdit
        local xMax := NumGet(RECT, 8, "Int") - scrollW
        local yMax := NumGet(RECT, 12, "Int")
        local height := yMax - yMin
        local monitor := IC_BrivGemFarm_LevelUp_Functions.GetMonitor(controlID)
        SysGet, monitorCoords, Monitor, %monitor%
        if (height >= monitorCoordsBottom) ; List bigger than screen height
        {
            yMin := 0
            yMax := monitorCoordsBottom
        }
        else if (yMax > monitorCoordsBottom) ; List opens upwards instead of downwards
        {
            yMax := yMin - yMaxEdit
            yMin := yMax - height
        }
        CoordMode, Mouse, Screen
        MouseGetPos, xPos, yPos
        CoordMode, Mouse, Client
        return (xMin <= xPos) AND (xPos <= xMax) AND (yMin <= yPos) AND (yPos <= yMax)
    }
}