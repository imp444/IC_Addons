#include %A_LineFile%\..\IC_BrivGemFarm_HybridTurboStacking_Colors.ahk

GUIFunctions.AddTab("BrivGF HybridTurboStacking")

; Add GUI fields to this addon's tab.HybridTurboStacking
Gui, ICScriptHub:Tab, BrivGF HybridTurboStacking

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, Section vBGFHTS_Status, Status:
Gui, ICScriptHub:Add, Text, x+5 w420 vBGFHTS_StatusText, Not Running
GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
Gui, ICScriptHub:Add, Text, xs ys+20 Hidden vBGFHTS_StatusWarning, WARNING: Addon was loaded too late. Stop/start Gem Farm to resume.
GUIFunctions.UseThemeTextColor()

; Validates inputs for targetQ/E and stack setup controls.
; Returns: - int:input or str:"RETURN" if input is invalid.
BGFHTS_ValidateInput(min := 0, max := 1)
{
    global
    local beforeSubmit := % %A_GuiControl%
    GuiControlGet, input,, %A_GuiControl%
    if input is not digit
    {
        onlyDigits := RegExReplace(beforeSubmit, "[^\d]+")
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % onlyDigits
        return "RETURN"
    }
    if input not between %min% and %max%
    {
        input := input < min ? min : max
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % input
    }
    if (LTrim(input, 0) == beforeSubmit && (input . " ") != (beforeSubmit . " "))
    {
        input := LTrim(beforeSubmit, "0")
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % input
    }
    Gui, ICScriptHub:Submit, NoHide
    return input
}

BGFHTS_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    GuiControl, ICScriptHub: Disable, BrivGemFarm_BrivFeatSwap_Save
    g_HybridTurboStacking.SaveSettings()
    GuiControl, ICScriptHub: Enable, BrivGemFarm_BrivFeatSwap_Save
}

BGFHTS_Enabled()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_HybridTurboStacking.UpdateSetting("Enabled", value)
}

BGFHTS_CompleteZone()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_HybridTurboStacking.UpdateSetting("CompleteOnlineStackZone", value)
}

BGFHTS_WardenUlt()
{
    global
    if ((value := BGFHTS_ValidateInput(0, 100)) != "RETURN")
        g_HybridTurboStacking.UpdateSetting("WardenUltThreshold", value)
}

BGFHTS_MelfMinStackZone()
{
    global
    if ((value := BGFHTS_ValidateInput(0, 9999)) != "RETURN")
        g_HybridTurboStacking.UpdateSetting("MelfMinStackZone", value)
}

BGFHTS_MelfMaxStackZone()
{
    global
    if ((value := BGFHTS_ValidateInput(0, 9999)) != "RETURN")
        g_HybridTurboStacking.UpdateSetting("MelfMaxStackZone", value)
}

BGFHTS_Multirun()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_HybridTurboStacking.UpdateSetting("Multirun", value)
    g_HybridTurboStackingGui.ToggleMultirun(value)
}

BGFHTS_MultirunTargetStacks()
{
    global
    if ((value := BGFHTS_ValidateInput(0, 99999)) != "RETURN")
        g_HybridTurboStacking.UpdateSetting("MultirunTargetStacks", value)
}

BGFHTS_MultirunDelayOffline()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_HybridTurboStacking.UpdateSetting("MultirunDelayOffline", value)
}

BGFHTS_100Melf()
{
    Gui, ICScriptHub:Submit, NoHide
    GuiControlGet, value,, %A_GuiControl%
    g_HybridTurboStacking.UpdateSetting("100Melf", value)
}

BGFHTS_ShowMelfForecast()
{
    g_HybridTurboStackingGui.FirstForecastUpdate()
    Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:Show, AutoSize Center
}

BGFHTS_Mod50CheckBoxes()
{
}

; Melf forecast resize events
OnMessage(0x0231, Func("BGFHTS_CheckResizeEvent").Bind(0x0231)) ; WM_ENTERSIZEMOVE
OnMessage(0x0232, Func("BGFHTS_CheckResizeEvent").Bind(0x0232)) ; WM_EXITSIZEMOVE

IC_BrivGemFarm_HybridTurboStacking_MelfGuiSize(WM)
{
    minMax := ErrorLevel
    IC_BrivGemFarm_HybridTurboStacking_GUI.CheckWindowMinSize(A_GuiWidth, A_GuiHeight)
    IC_BrivGemFarm_HybridTurboStacking_GUI.CheckResizeEvent(WM, minMax)
}

BGFHTS_CheckResizeEvent(WM)
{
    IC_BrivGemFarm_HybridTurboStacking_GUI.CheckResizeEvent(WM)
}

BGFHTS_DoResizeEvent()
{
    IC_BrivGemFarm_HybridTurboStacking_GUI.DoResizeEvent()
}

Class IC_BrivGemFarm_HybridTurboStacking_GUI
{
    static LastWinWidth := 0
    static LastWinHeight := 0
    static MaxLVWidth := 0
    static Colors := IC_BrivGemFarm_HybridTurboStacking_Colors

    LV_Colors_Instance := ""
    AllowForecastUpdate := false

    Init()
    {
        global
        local xSection := 10
        local xSpacing := 10
        local yTitleSpacing := 20
        local ySpacing := 10
        local ctrlH:= 21
        Gui, ICScriptHub:Add, Button, xs y+%yTitleSpacing% vBGFHTS_Save gBGFHTS_Save, Save
        Gui, ICScriptHub:Add, CheckBox, x+18 yp+5 vBGFHTS_Enabled gBGFHTS_Enabled, Enabled
        Gui, ICScriptHub:Add, CheckBox, xs y+%yTitleSpacing% vBGFHTS_CompleteZone gBGFHTS_CompleteZone, Complete the stacking zone before online stacking
        ; Warden ult
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs y+%ySpacing% Limit4 vBGFHTS_WardenUlt gBGFHTS_WardenUlt
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vBGFHTS_WardenUltText, Use Warden's ultimate when enemy count has reached this value (0 disables)
        ; Multi-run
        center := ySpacing + 4
        Gui, ICScriptHub:Add, CheckBox, xs y+%center% vBGFHTS_Multirun gBGFHTS_Multirun, Multiple run mode
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 x+%xSpacing% yp-4 Limit5 vBGFHTS_MultirunTargetStacks gBGFHTS_MultirunTargetStacks
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vBGFHTS_MultirunTargetStacksText, Multirun target stacks
        Gui, ICScriptHub:Add, CheckBox, x+15 yp+4 vBGFHTS_MultirunDelayOffline gBGFHTS_MultirunDelayOffline
        GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_MultirunDelayOffline
        ; When disabled, the checkbox overlaps the text.
        newW := posW - 10
        GuiControl, ICScriptHub:MoveDraw, BGFHTS_MultirunDelayOffline, w%newW%
        textPos := posX + 19
        Gui, ICScriptHub:Add, Text, x%textPos% yp-4 h%ctrlH% 0x200 vBGFHTS_MultirunDelayOfflineText, Delay offline until last run
        ; Disabled until this works properly
        GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
        Gui, ICScriptHub:Add, Text, xs y+5 vBGFHTS_TempWarning, Settings above will currently only work if late stacking (ignores Melf settings).
        GUIFunctions.UseThemeTextColor()
        ; Melf settings
        Gui, ICScriptHub:Add, Groupbox, Section xs y+%ySpacing% vBGFHTS_MelfGroup, Melf
        Gui, ICScriptHub:Add, CheckBox, xs+%xSection% ys+%yTitleSpacing% vBGFHTS_100Melf gBGFHTS_100Melf, % "Delay stacking until Melf's" . " ""% " . "chance to spawn additional enemies"" effect is active"
        ; Min/max online stack zones
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs+%xSection%  y+%ySpacing% Limit4 vBGFHTS_MelfMinStackZone gBGFHTS_MelfMinStackZone
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vBGFHTS_MelfMinStackZoneText, Min StackZone
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 x+%xSpacing% Limit4 vBGFHTS_MelfMaxStackZone gBGFHTS_MelfMaxStackZone
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vBGFHTS_MelfMaxStackZoneText, Max StackZone
        ; BGFHTS_CurrentRunStackRange
        Gui, ICScriptHub:Add, Text, xs+%xSection% y+%ySpacing% vBGFHTS_CurrentRunStackRangeText, Current Run Stack Range:
        Gui, ICScriptHub:Add, Text, x+5 w220 vBGFHTS_CurrentRunStackRange
        ; BGFHTS_PreviousStackZone
        Gui, ICScriptHub:Add, Text, xs+%xSection% y+5 vBGFHTS_PreviousStackZoneText, Previous StackZone:
        Gui, ICScriptHub:Add, Text, x+5 w220 vBGFHTS_PreviousStackZone
        ; Melf forecast
        this.InitForecast()
        Gui, ICScriptHub:Add, Button, xs+%xSection% y+%ySpacing% vBGFHTS_ShowMelfForecast gBGFHTS_ShowMelfForecast, Melf forecast
        ; Resets
        Gui, ICScriptHub:Add, Text, x+%xSpacing% h%ctrlH% 0x200 vBGFHTS_ResetsText, Resets:
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 w220 vBGFHTS_Resets
        ; Preferred Briv stack zones
        GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
        Gui, ICScriptHub:Add, Text, xs+%xSection% y+%ySpacing% vBGFHTS_BrivStackZonesText, Preferred Briv Stack Zones:
        GUIFunctions.UseThemeTextColor()
        GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_BrivStackZonesText
        this.BuildModTable(posX, posY)
        ; Resize Melf groupbox
        GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_100Melf
        maxX := posX + posW + xSection - 5
        GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_BrivStack_Mod_50_50
        maxY := posY + posH + ySpacing
        GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_MelfGroup
        newW := maxX - posX
        newH := maxY - posY
        GuiControl, ICScriptHub:MoveDraw, BGFHTS_MelfGroup, w%newW% h%newH%
    }

    InitForecast()
    {
        global
        local yTitleSpacing := 20
        local ySpacing := 10
        Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:New,, Melf forecast
        Gui, IC_BrivGemFarm_HybridTurboStacking_Melf: +MaximizeBox +Resize
        GUIFunctions.LoadTheme("IC_BrivGemFarm_HybridTurboStacking_Melf")
        GUIFunctions.UseThemeBackgroundColor()
        GUIFunctions.UseThemeTextColor()
        GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
        text := "0: +chance to spawn additional enemies`n"
        text .= "1: +enemy spawn speed`n"
        text .= "2: +chance of increased quest drops`n"
        Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:Add, Text, Section x5 y+%ySpacing% R3 vBGFHTS_MelfForecastLegend, % text
        ; Success rate
        Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:Add, Text, xs y+%ySpacing% vBGFHTS_SuccessText, Success:
        GUIFunctions.UseThemeTextColor()
        Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:Add, Text, x+5 w150 vBGFHTS_SuccessValueText
        ; LV
        if (VerCompare(A_AhkVersion, "<1.1.37.02"))
        {
            GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
            Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:Add, Text, xs y+5 vBGFHTS_VersionWarning, % "If you ever experience window crashes, try updating AHK to v1.1.37.02+."
        }
        GUIFunctions.UseThemeTextColor("TableTextColor")
        Gui, IC_BrivGemFarm_HybridTurboStacking_Melf:Add, ListView, xs y+%ySpacing% w2400 R50 AltSubmit NoSortHdr -LV0x10 vBGFHTS_MelfForecast
        GUIFunctions.UseThemeListViewBackgroundColor("BGFHTS_MelfForecast")
        GUIFunctions.LoadTheme()
        LV_InsertCol(1, "Integer Center", "Resets")
        num := Ceil(IC_BrivGemFarm_HybridTurboStacking_Melf.MAX_ZONE / 50)
        Loop, % num
        {
            start := A_Index * 50 - 49
            header := start . "-" . (start + 49)
            LV_InsertCol(A_Index + 1, "Integer Center", header)
        }
        ; Colors
        this.LV_Colors_Instance := this.Colors.NewColoredLV("IC_BrivGemFarm_HybridTurboStacking_Melf", "BGFHTS_MelfForecast")
    }

    ; Builds mod50 checkboxes for PreferredBrivStackZones.
    BuildModTable(xLoc, yLoc)
    {
        leftAlign := xLoc
        Loop, 50
        {
            if (Mod(A_Index, 10) != 1)
                xLoc += 35
            else
            {
                xLoc := leftAlign
                yLoc += 20
            }
            ; Disable stacking in a boss zone.
            disabled := Mod(A_Index, 5) == 0
            this.AddControlCheckbox(xLoc, yLoc, A_Index, disabled)
        }
    }

    ; Adds a single checkBox for PreferredBrivStackZones.
    AddControlCheckbox(xLoc, yLoc, loopCount, disabled)
    {
        global
        local options := "vBGFHTS_BrivStack_Mod_50_" . loopCount . " Checked x" . xLoc . " y" . yLoc . " gBGFHTS_Mod50CheckBoxes"
        if (disabled)
            options .= " Disabled"
        Gui, ICScriptHub:Add, Checkbox, %options%, % loopCount
    }

    UpdateGUI(data)
    {
        range := data.CurrentRunStackRange
        rangeStr := range[1] . "-" . range[2]
        GuiControl, ICScriptHub:Text, BGFHTS_CurrentRunStackRange, % rangeStr
        GuiControl, ICScriptHub:Text, BGFHTS_PreviousStackZone, % data.PreviousStackZone
    }

    UpdateGUISettings(data)
    {
        GuiControl, ICScriptHub:, BGFHTS_Enabled, % data.Enabled
        GuiControl, ICScriptHub:, BGFHTS_CompleteZone, % data.CompleteOnlineStackZone
        GuiControl, ICScriptHub:, BGFHTS_WardenUlt, % data.WardenUltThreshold
        GuiControl, ICScriptHub:, BGFHTS_Multirun, % data.Multirun
        GuiControl, ICScriptHub:, BGFHTS_MultirunTargetStacks, % data.MultirunTargetStacks
        GuiControl, ICScriptHub:, BGFHTS_MultirunDelayOffline, % data.MultirunDelayOffline
        GuiControl, ICScriptHub:, BGFHTS_100Melf, % data.100Melf
        GuiControl, ICScriptHub:, BGFHTS_MelfMinStackZone, % data.MelfMinStackZone
        GuiControl, ICScriptHub:, BGFHTS_MelfMaxStackZone, % data.MelfMaxStackZone
        this.ToggleMultirun(data.Multirun)
        this.LoadMod50(data.PreferredBrivStackZones)
    }

    ToggleMultirun(show := true)
    {
        showSetting := show ? "Enable" : "Disable"
        GuiControl, ICScriptHub:%showSetting%, BGFHTS_MultirunTargetStacks
        GuiControl, ICScriptHub:%showSetting%, BGFHTS_MultirunDelayOffline
    }

    UpdateResets(value)
    {
        GuiControl, ICScriptHub:, BGFHTS_Resets, % value
    }

    FirstForecastUpdate()
    {
        if (!this.AllowForecastUpdate)
        {
            this.AllowForecastUpdate := true
            g_HybridTurboStacking.UpdateMelfForecast(true)
        }
    }

    UpdateForecast(data, min := 0, max := 2050, success := 0)
    {
        controlID := "BGFHTS_MelfForecast"
        restore_gui_on_return := GUIFunctions.LV_Scope("IC_BrivGemFarm_HybridTurboStacking_Melf", controlID)
        GuiControl, -Redraw, %controlID%
        ; Delete values before current reset
        Loop, % data.Length()
            LV_Delete(1)
        ; Add rows
        listview := this.LV_Colors_Instance
        Loop, % data.Length()
        {
            rowData := data[A_Index]
            row := LV_Add(, data[A_Index]*)
            range := IC_BrivGemFarm_HybridTurboStacking_Melf.GetFirstSpawnMoreEffectRange(rowData[1], min, max)
            area := range[1]
            col := Round(range[2] / 50) + 1
            if (col > 1)
            {
                ; Highlight first success
                this.Colors.SetLVColor(listview, row, col)
                finalCol := Ceil(max / 50) + 1
                Loop, % finalCol - col
                {
                    effect := rowData[col + A_Index]
                    ; Highlight remaining successes
                    if (effect == 0)
                        this.Colors.SetLVColor(listview, row, col + A_Index,, true)
                }
            }
            else
            {
                ; Highlight fail rows
                Loop, % data.Length()
                    this.Colors.SetLVColor(listview, row, A_Index, false, true)
            }
        }
        ; Resize columns
        this.ResizeLVHeaders()
        GuiControl, +Redraw, %controlID%
        successStr := success . "/" . g_HybridTurboStacking.MAX_MELF_FORECAST_ROWS
        GuiControl, IC_BrivGemFarm_HybridTurboStacking_Melf:, BGFHTS_SuccessValueText, % successStr
    }

    ; Resize ListViews up to the maximum size of ICScriptHub's main tab.
    ; Params: - controlID:str - Name of the ListView's control variable.
    ResizeLV(controlID, w, h)
    {
        GuiControlGet, pos, IC_BrivGemFarm_HybridTurboStacking_Melf:Pos, %controlID%
        newH := h - posY - 45
        newW := this.GetMaxLVWidth()
        newW := Min(newW, w - posX - 20)
        newW := Max(newW, this.GetMinLVWidth())
        GuiControl, IC_BrivGemFarm_HybridTurboStacking_Melf:MoveDraw, %controlID%, h%newH% w%newW%
    }

    ResizeLVHeaders()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("IC_BrivGemFarm_HybridTurboStacking_Melf", BGFHTS_MelfForecast)
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
    }

    ; Checks performed on GUI resize event.
    ; Resize the UI on mouse release if this addon's tab is not focused.
    CheckResizeEvent(WM, minMax := 0)
    {
        global
        if (WM == 0x0231 && WinActive("Melf forecast"))
            SetTimer, BGFHTS_DoResizeEvent, 200
        else if ((WM == 0x0232 || minMax == 2) && WinActive("Melf forecast"))
        {
            SetTimer, BGFHTS_DoResizeEvent, Delete
            this.DoResizeEvent()
        }
    }

    ; Action performed on GUI resize event.
    DoResizeEvent()
    {
        ; Only resize when ICScriptHub has been resized.
        WinGetActiveStats, winTitle, winW, winH, winX, winY
        if (winW == this.LastWinWidth && winH == this.LastWinHeight)
            return
        this.LastWinWidth := winW
        this.LastWinHeight := winH
        this.ResizeLV("BGFHTS_MelfForecast", winW, winH)
    }

    CheckWindowMinSize(width, height)
    {
        minWidth := this.GetMinLVWidth()
        if (width < minWidth)
        {
            w := this.GetMinLVWidth() + 20
            WinMove, Melf forecast,,,, %w%
        }
    }

    GetMinLVWidth()
    {
        GuiControlGet, pos, IC_BrivGemFarm_HybridTurboStacking_Melf:Pos, BGFHTS_MelfForecastLegend
        return posX + posW
    }

    GetMaxLVWidth()
    {
        if (this.MaxLVWidth != 0)
            return this.MaxLVWidth
        controlID := "IC_BrivGemFarm_HybridTurboStacking_Melf"
        restore_gui_on_return := GUIFunctions.LV_Scope(controlID, BGFHTS_MelfForecast)
        ; Origin
        GuiControlGet, pos, %controlID%:Pos, BGFHTS_MelfForecast
        ; Size of all columns
        GuiControlGet, hwnd, %controlID%:Hwnd, BGFHTS_MelfForecast
        Loop % LV_GetCount("Col")
        {
            SendMessage, 0x101D, A_Index - 1, 0,, ahk_id %hwnd% ; LVM_GETCOLUMNWIDTH.
            width += ErrorLevel
        }
        SysGet, scrollWidth, 2 ; SM_CXVSCROLL Scrollbar width
        this.MaxLVWidth := posX + width + scrollWidth
        return this.MaxLVWidth
    }

    ; Set the state of the mod50 checkboxes for Preferred Briv Jump Zones in BGFBFS tab.
    ; Parameters: value:int - A bitfield that represents the checked state of each checkbox.
    LoadMod50(value)
    {
        Loop, 50
        {
            checked := (value & (2 ** (A_Index - 1))) != 0
            GuiControl, ICScriptHub:, BGFHTS_BrivStack_Mod_50_%A_Index%, % checked
        }
        Gui, ICScriptHub:Submit, NoHide
    }
}