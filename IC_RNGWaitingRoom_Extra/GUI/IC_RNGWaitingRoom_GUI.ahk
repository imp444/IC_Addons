; Main tab

GUIFunctions.AddTab("RNG Waiting Room")
Gui, ICScriptHub:Tab, RNG Waiting Room

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, Section vRNGWR_Status, Status:
Gui, ICScriptHub:Add, Text, x+5 w420 vRNGWR_StatusText, Getting gems
GUIFunctions.UseThemeTextColor()

; Controls

RNGWR_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    GuiControl, ICScriptHub: Disable, RNGWR_Save
    g_RNGWaitingRoom.SaveSettings()
    GuiControl, ICScriptHub: Enable, RNGWR_Save
}

RNGWR_EllywickGFEnabled()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_RNGWaitingRoom.UpdateSetting("EllywickGFEnabled", value)
}

RNGWR_EllywickGFGemCards()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_RNGWaitingRoom.UpdateSetting("EllywickGFGemCards", value)
}

RNGWR_EllywickGFGemMaxRedraws()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_RNGWaitingRoom.UpdateSetting("EllywickGFGemMaxRedraws", value)
}

RNGWR_EllywickGFGemWaitFor5Draws()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_RNGWaitingRoom.UpdateSetting("EllywickGFGemWaitFor5Draws", value)
}

RNGWR_ResetStats()
{
    g_RNGWaitingRoom.ResetStats()
}

Class IC_RNGWaitingRoom_GUI
{
    LastMaxTabHeight := 0
    LastMaxTabWidth := 0
    LastPatronColumn := 0

    Init()
    {
        global
        local xSection := 10
        local xSpacing := 10
        local yTitleSpacing := 20
        local ySpacing := 10
        local ctrlH:= 21
        Gui, ICScriptHub:Add, Button, xs y+%yTitleSpacing% vRNGWR_Save gRNGWR_Save, Save
        ; Ellywick (gemfarm)
        center := ySpacing + 4
        Gui, ICScriptHub:Add, CheckBox, xs y+%center% vRNGWR_EllywickGFEnabled gRNGWR_EllywickGFEnabled, Gem farm mode (Ellywick)
        ; Gem cards
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs y+%ySpacing% Limit4 vRNGWR_EllywickGFGemCards gRNGWR_EllywickGFGemCards
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vRNGWR_EllywickGFGemCardsText, Number of gem cards (z1)
        ; Redraws with ult
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs y+%ySpacing% Limit3 vRNGWR_EllywickGFGemMaxRedraws gRNGWR_EllywickGFGemMaxRedraws
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vRNGWR_EllywickGFGemMaxRedrawsText, Max redraws (z1)
        Gui, ICScriptHub:Add, CheckBox, xs y+%center% vRNGWR_EllywickGFGemWaitFor5Draws gRNGWR_EllywickGFGemWaitFor5Draws, Always wait for 5 draws
        ; Stats
        GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
        Gui, ICScriptHub:Add, Groupbox, Section xs y+%ySpacing% vRNGWR_StatsGroup, Stats
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, xs+%xSection% ys+%yTitleSpacing% vRNGWR_RunsText, Runs:
        Gui, ICScriptHub:Add, Text, x+5 w220 vRNGWR_Runs
        Gui, ICScriptHub:Add, Text, xs+%xSection% y+%ySpacing% vRNGWR_AvgBonusGemsText, Avg. gem bonus (z1):
        Gui, ICScriptHub:Add, Text, x+5 w220 vRNGWR_AvgBonusGems
        Gui, ICScriptHub:Add, Text, xs+%xSection% vRNGWR_AvgRedrawsText, Avg. redraws:
        Gui, ICScriptHub:Add, Text, x+5 w220 vRNGWR_AvgRedraws
        Gui, ICScriptHub:Add, Button, xs+%xSection% y+%ySpacing% vRNGWR_ResetStats gRNGWR_ResetStats, Reset stats
        ; Resize Stats group box
        maxX := 500
        GuiControlGet, pos, ICScriptHub:Pos, RNGWR_ResetStats
        maxY := posY + posH + ySpacing
        GuiControlGet, pos, ICScriptHub:Pos, RNGWR_StatsGroup
        newW := maxX - posX
        newH := maxY - posY
        GuiControl, ICScriptHub:MoveDraw, RNGWR_StatsGroup, w%newW% h%newH%
    }

    UpdateGUISettings(data)
    {
        GuiControl, ICScriptHub:, RNGWR_EllywickGFEnabled, % data.EllywickGFEnabled
        GuiControl, ICScriptHub:, RNGWR_EllywickGFGemCards, % data.EllywickGFGemCards
        GuiControl, ICScriptHub:, RNGWR_EllywickGFGemMaxRedraws, % data.EllywickGFGemMaxRedraws
        GuiControl, ICScriptHub:, RNGWR_EllywickGFGemWaitFor5Draws, % data.EllywickGFGemWaitFor5Draws
    }

    UpdateGUI(data)
    {
        runs := data[3]
        avgBonusGemsStr := Round(data[1] / runs, 2) . "%"
        avgRedrawsStr := Round(data[2] / runs, 2)
        GuiControl, ICScriptHub:Text, RNGWR_Runs, % runs
        GuiControl, ICScriptHub:Text, RNGWR_AvgBonusGems, % avgBonusGemsStr
        GuiControl, ICScriptHub:Text, RNGWR_AvgRedraws, % avgRedrawsStr
    }
}