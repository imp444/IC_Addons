BGFLU_CheckResizeEvent(WM)
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_CheckResizeEvent(WM)
}

BGFLU_DoResizeEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_DoResizeEvent()
}

BGFLU_CheckComboStatus(W)
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_CheckComboStatus(W)
}

BGFLU_CheckBoxEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_CheckBoxEvent()
}

BGFLU_Mod50CheckBoxEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_Mod50CheckBoxEvent()
}

BGFLU_EditEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_EditEvent()
}

BGFLU_LB_Section()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_LB_Section()
}

BGFLU_Name()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_Name()
}

BGFLU_MinMax_Clamp()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_MinMax_Clamp()
}

BGFLU_LoadFormation()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_LoadFormation()
}

BGFLU_Default()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_Default()
}

BGFLU_Save()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_Save()
}

BGFLU_Changes()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_Changes()
}

BGFLU_Undo()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_Undo()
}

BGFLU_MinDefault()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_MinDefault()
}

BGFLU_MaxDefault()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_MaxDefault()
}

BGFLU_SelectLanguage()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_SelectLanguage()
}

BGFLU_LoadDefinitions()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.BGFLU_LoadDefinitions()
}

Class IC_BrivGemFarm_LevelUp_GUI_Events
{
    ; Checked/ unchecked
    BGFLU_CheckBoxEvent()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local setting := StrReplace(A_GuiControl, "BGFLU_")
        local value := % %A_GuiControl%
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting(setting, value)
        if (setting == "ShowSpoilers")
            g_BrivGemFarm_LevelUp.ToggleSpoilers(value) ; Effect is immediate
    }

    ; Checked/ unchecked (mod50)
    BGFLU_Mod50CheckBoxEvent()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        RegExMatch(A_GuiControl, "BGFLU_([^_]+)_Mod50_\d+", setting)
        rootControlID := "BGFLU_" . setting1 . "_Mod50_"
        value := 0
        Loop, 50
        {
            GuiControlGet, isChecked, ICScriptHub:, %rootControlID%%A_Index%
            if (isChecked)
                value += 2 ** (A_Index - 1)
        }
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting(setting1, value)
    }

    ; Keyboard or c/p input
    BGFLU_EditEvent()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local setting := StrReplace(A_GuiControl, "BGFLU_")
        local value := % %A_GuiControl%
        if value is not digit
        {
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % beforeSubmit
            return
        }
        else if (value < 1 && setting != "MinLevelTimeout" && setting != "MinClickDamage" && setting != "ClickDamagePerArea")
        {
            value := 1
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % value
        }
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting(setting, value)
    }

    ; Moves a MsgBox window after a short delay to create a new thread.
    ; Should be called right before showing a MsgBox window.
    ; Params: controlID:str - Name of the control where the MsgBox should be moved near.
    SetupMoveMsgBox(controlID)
    {
        params := [controlID]
        func := ObjBindMethod(this, "MoveMsgBox", params*)
        SetTimer, %func%, -1
    }

    ; Moves the currently active window after it has appeared on screen.
    ; Params: controlID:str - Name of the control where the MsgBox should be moved near.
    MoveMsgBox(controlID)
    {
        targetPos := this.GetPopupPos(controlID)
        newX := targetPos[1]
        newY := targetPos[2]
        WinGetActiveTitle, title
        if (title == "" || title == "IC Script Hub")
            return this.SetupMoveMsgBox(controlID)
        WinMove, %title%,, %newX%, %newY%
        this.MoveIfOutOfBounds(title, newX, newY)
    }

    ; Moves the target window inside the bounds of the current monitor.
    MoveIfOutOfBounds(winTitle, xLoc, yLoc)
    {
        WinGetPos, x, y, w, h, %winTitle%
        monitor := IC_BrivGemFarm_LevelUp_Functions.GetMonitor(winTitle)
        SysGet, monitorCoords, MonitorWorkArea, %monitor%
        if ((xLoc + w) > monitorCoordsRight)
            xLoc := monitorCoordsRight - w
        if ((yLoc + h) > monitorCoordsBottom)
            yLoc := monitorCoordsBottom - h
        WinMove, %winTitle%,, xLoc, yLoc
    }

    ; Returns the position where the MsgBox / new window should appear.
    ; Params: controlID:str - Name of the control where the MsgBox should be moved near.
    GetPopupPos(controlID)
    {
        WinGetPos, x, y, w, h, IC Script Hub
        GuiControlGet, hwnd, ICScriptHub:Hwnd, %controlID%
        ControlGetPos, posX, posY, posW, posH,, ahk_id %hwnd%
        xLoc := x + posX
        yLoc := y + posY + posH
        return [xLoc, yLoc]
    }

    ; Jump to section
    BGFLU_LB_Section()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        IC_BrivGemFarm_LevelUp_GUI.ShowSection(value + 1)
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
            Case "BrivMinLevelStackingOnline":
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting("BrivMinLevelStackingOnline", clamped)
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

    ; Default settings button
    BGFLU_Default()
    {
        global
        this.SetupMoveMsgBox("BGFLU_Default")
        MsgBox, 4, BrivGemFarm LevelUp, Restore Default settings?, 10
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
        this.SetupMoveMsgBox("BGFLU_Save")
        MsgBox, 4, BrivGemFarm LevelUp, Save and apply changes?, 10
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
        ; Show the window under the "View changes" button
        targetPos := this.GetPopupPos("BGFLU_Changes")
        xLoc := targetPos[1]
        yLoc := targetPos[2]
        Gui, IC_BrivGemFarm_LevelUp_TempSettings:Show, x%xLoc% y%yLoc%
        ; Move window if out of monitor bounds
        this.MoveIfOutOfBounds("BrivGemFarm LevelUp Settings", xLoc, yLoc)
    }

    ; Undo temp settings button
    BGFLU_Undo()
    {
        global
        this.SetupMoveMsgBox("BGFLU_Undo")
        MsgBox, 4, BrivGemFarm LevelUp, Undo all changes?, 10
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

    ; Select language used for defintions.
    ; Doesn't save to temp settings, loads a new language immediately.
    BGFLU_SelectLanguage()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        if (value != beforeSubmit)
        {
            g_BrivGemFarm_LevelUp.SetSetting("DefinitionsLanguage", BGFLU_SelectLanguage)
            this.BGFLU_LoadDefinitions()
        }
    }

    ; Load new definitions
    BGFLU_LoadDefinitions()
    {
        global
        GuiControl, ICScriptHub:Disable, BGFLU_SelectLanguage
        GuiControl, ICScriptHub:Disable, BGFLU_LoadDefinitions
        g_DefinesLoader.Start(false, true)
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
        IC_BrivGemFarm_LevelUp_GUI.ShowSection(BGFLU_LB_Section + 1)
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
                if (seat_ID == "58Off" || seat_ID == "58On")
                {
                    local setting := "BrivMinLevelStacking" . (seat_ID == "58On" ? "Online" : "")
                    local controlID := "BGFLU_Combo_" . setting
                    local value := g_BrivGemFarm_LevelUp.GetSetting(setting)
                }
                else
                {
                    local controlID := "BGFLU_DDL_Name_" . seat_ID
                    GuiControlGet, value,, %controlID%
                }
                GuiControl, ICScriptHub:ChooseString, %controlID%, % "|" . value
            }
            else if (this.MouseOverComboBoxList(ctrlH := arr[2])) ; Show current selection as tooltip
            {
                OnMessage(0x200, "CheckControlForToolTip",0)
                local func := ObjBindMethod(this, "RemoveToolTip")
                SetTimer, %func%, -500
                SendMessage, CB_GETCURSEL, 0, 0,, ahk_id %ctrlH%
                local currentSel := ErrorLevel ; 0 based
                local trueSeatID := (seat_ID == "58Off" || seat_ID == "58On") ? 5 : seat_ID
                local heroData := IC_BrivGemFarm_LevelUp_Seat.Seats[trueSeatID].GetCurrentHeroData()
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
            return ["58Off", ctrlHwnd]
        ctrlHwnd := HBGFLU_BrivMinLevelStackingOnline
        SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
        if (Errorlevel)
            return ["58On", ctrlHwnd]
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