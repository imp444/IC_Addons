GUIFunctions.AddTab("Briv Feat Swap")

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Briv Feat Swap

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, Section vBGFBFS_Status, Status:
Gui, ICScriptHub:Add, Text, x+5 w170 vBGFBFS_StatusText, Not Running
GUIFunctions.UseThemeTextColor("WarningTextColor", 700)

Gui, ICScriptHub:Add, Text, xs ys+20 Hidden vBGFBFS_StatusWarning, WARNING: Addon was loaded too late. Stop/start Gem Farm to resume.
GUIFunctions.UseThemeTextColor()

; Maximum number of simultaneous F keys inputs during MinLevel
BrivGemFarm_BrivFeatSwap_Target()
{
    global
    local beforeSubmit := % %A_GuiControl%
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    if value is not digit
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % beforeSubmit
}

BrivGemFarm_BrivFeatSwap_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    GuiControl, ICScriptHub: Disable, BrivGemFarm_BrivFeatSwap_Save
    g_BrivFeatSwap.Save(BrivGemFarm_BrivFeatSwap_TargetQ, BrivGemFarm_BrivFeatSwap_TargetE)
    GuiControl, ICScriptHub: Enable, BrivGemFarm_BrivFeatSwap_Save
}

BGFBFS_Preset()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_BrivFeatSwap.LoadPreset(value)
}

; Disable mod50 checkboxes.
BGFBFS_DisabledCheckBox()
{
    global
    local beforeSubmit := % %A_GuiControl%
    GuiControl, ICScriptHub:, %A_GuiControl%, % beforeSubmit
    Gui, ICScriptHub:Submit, NoHide
}

Class IC_BrivGemFarm_BrivFeatSwap_GUI
{
    LeftAlign := 20
    XSection := 10
    YSection := 10
    XSpacing := 10
    YSpacing := 10
    YTitleSpacing := 20

    SetupGroups()
    {
        global
        local xSpacing := this.XSpacing
        local yTitleSpacing := this.YTitleSpacing
        Gui, ICScriptHub:Add, Button, xs y+%yTitleSpacing% vBrivGemFarm_BrivFeatSwap_Save gBrivGemFarm_BrivFeatSwap_Save, Save
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, Text, Section xs y+%yTitleSpacing% vBGFBFS_PresetText, Presets:
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, DropDownList, x+%xSpacing% yp-3 w100 vBGFBFS_Preset gBGFBFS_Preset
        this.SetupSkipSetupGroup()
        this.SetupPreferredBrivJumpZonesGroup()
        this.SetupBGFLUGroup()
    }

    SetupSkipSetupGroup()
    {
        global
        local leftAlign := this.LeftAlign
        local xSpacing := this.XSpacing
        local ySpacing := this.YSpacing
        local yTitleSpacing := this.YTitleSpacing
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, Section xs vBGFBFS_SkipSetup, Skip setup
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapReads xs+%xSpacing% ys+%yTitleSpacing% w30, Reads
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapTarget x+15 w30, Target
        GuiControlGet, pos, ICScriptHub:Pos, BrivFeatSwapTarget
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapQText xs+%xSpacing% y+%ySpacing% w15, Q:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapQValue x+%xSpacing% w20
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, x%posX% y+-16 h19 w33 Limit3 vBrivGemFarm_BrivFeatSwap_TargetQ gBrivGemFarm_BrivFeatSwap_Target, 0
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapWText xs+%XSpacing% y+%ySpacing% w15, W:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapWValue x+%xSpacing% w20
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapEText xs+%XSpacing% y+%ySpacing% w15, E:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapEValue x+%xSpacing% w20
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, x%posX% y+-16 h19 w33 Limit3 vBrivGemFarm_BrivFeatSwap_TargetE gBrivGemFarm_BrivFeatSwap_Target, 0
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapsMadeThisRunText xs+%XSpacing% y+%ySpacing% w15, SwapsMadeThisRun:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapsMadeThisRunValue x+%xSpacing% w40
        ; Resize
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_SkipSetup
        GuiControlGet, pos, ICScriptHub:Pos, BrivFeatSwapsMadeThisRunValue
        local newHeight := posY + posH - posGY + this.YSection
        local newWidth := posX + posW - posGX + this.XSection
        GuiControl, ICScriptHub:Move, BGFBFS_SkipSetup, h%newHeight% w%newWidth%
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_SkipSetup
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_Preset
        newWidth := posGX + posGW - posX
        GuiControl, ICScriptHub:Move, BGFBFS_Preset, w%newWidth%
    }

    SetupPreferredBrivJumpZonesGroup()
    {
        global
        local leftAlign := this.LeftAlign
        local xSpacing := this.XSpacing
        local ySpacing := this.YSpacing
        local yTitleSpacing := this.YTitleSpacing
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_SkipSetup
        local nextPos := posGY + posGH + ySpacing
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, Section x%posGX% y%nextPos% vBGFBFS_PreferredBrivJumpZones, Preferred Briv Jump Zones
        Gui, ICScriptHub:Font, w400
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_PreferredBrivJumpZones
        this.BuildModTable(posX + this.XSection, posY)
        ; Resize
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_PreferredBrivJumpZones
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_CopyPasteBGFAS_Mod_50_50
        local newHeight := posY + posH - posGY + this.YSection
        local newWidth := posX + posW - posGX + this.XSection
        GuiControl, ICScriptHub:Move, BGFBFS_PreferredBrivJumpZones, h%newHeight% w%newWidth%
    }

    SetupBGFLUGroup()
    {
        global
        local xSpacing := this.XSpacing
        local ySpacing := this.YSpacing
        local yTitleSpacing := this.YTitleSpacing
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, Section xs y+%yTitleSpacing% vBGFBFS_BGFLU, BrivGemFarm LevelUp
        Gui, ICScriptHub:Font, w400
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, -Background Disabled xs+%xSpacing% ys+%yTitleSpacing%  w50 Limit4 vBGFBFS_BrivMinLevelArea
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, x+5 yp+4 vBGFBFS_BrivMinLevelAreaText, Minimum area to reach before leveling Briv
        ; Resize
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_BGFLU
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_BrivMinLevelArea
        local newHeight := posY + posH - posGY + this.YSection
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_BrivMinLevelAreaText
        local newWidth := posX + posW - posGX + this.XSection
        GuiControl, ICScriptHub:Move, BGFBFS_BGFLU, h%newHeight% w%newWidth%
    }

    ; Builds one set of checkboxes for PreferredBrivJumpZones (e.g. Mod5 and associated checks)
    BuildModTable(xLoc, yLoc)
    {
        leftAlign := xLoc
        Loop, 50
        {
            if(Mod(A_Index, 10) != 1)
                xLoc += 35
            else
            {
                xLoc := leftAlign
                yLoc += 20
            }
            this.AddControlCheckbox(xLoc, yLoc, A_Index)
        }
    }

    AddControlCheckbox(xLoc, yLoc, loopCount)
    {
        global
        Gui, ICScriptHub:Add, Checkbox, vBGFBFS_CopyPasteBGFAS_Mod_50_%loopCount% Checked x%xLoc% y%yLoc% gBGFBFS_DisabledCheckBox, % loopCount
    }
}