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

RNGWR_EllywickGFGemPercent()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_RNGWaitingRoom.UpdateSetting("EllywickGFGemPercent", value)
}

RNGWR_EllywickGFGemMaxRerolls()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_RNGWaitingRoom.UpdateSetting("EllywickGFGemMaxRerolls", value)
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
        ; Ellywick (femfarm)
        center := ySpacing + 4
        Gui, ICScriptHub:Add, CheckBox, xs y+%center% vRNGWR_EllywickGFEnabled gRNGWR_EllywickGFEnabled, Gem farm mode (Ellywick)
        ; Gem cards
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs y+%ySpacing% Limit4 vRNGWR_EllywickGFGemCards gRNGWR_EllywickGFGemCards
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vRNGWR_EllywickGFGemCardsText, Number of gem cards
        ; Gem percent
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs y+%ySpacing% Limit3 vRNGWR_EllywickGFGemPercent gRNGWR_EllywickGFGemPercent
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vRNGWR_EllywickGFGemPercentText, Percent bonus
        ; Rerolls with ult
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, w40 xs y+%ySpacing% Limit3 vRNGWR_EllywickGFGemMaxRerolls gRNGWR_EllywickGFGemMaxRerolls
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 h%ctrlH% 0x200 vRNGWR_EllywickGFGemMaxRerollsText, Max rerolls
    }

    UpdateGUISettings(data)
    {
        GuiControl, ICScriptHub:, RNGWR_EllywickGFEnabled, % data.EllywickGFEnabled
        GuiControl, ICScriptHub:, RNGWR_EllywickGFGemCards, % data.EllywickGFGemCards
        GuiControl, ICScriptHub:, RNGWR_EllywickGFGemPercent, % data.EllywickGFGemPercent
        GuiControl, ICScriptHub:, RNGWR_EllywickGFGemMaxRerolls, % data.EllywickGFGemMaxRerolls
    }
}