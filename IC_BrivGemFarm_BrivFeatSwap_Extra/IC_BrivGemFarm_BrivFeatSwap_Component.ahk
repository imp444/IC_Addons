GUIFunctions.AddTab("Briv Feat Swap")

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Briv Feat Swap
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Skip setup:
Gui, ICScriptHub:Font, w400

leftAlign := 20
xSpacing := 5
ySpacing := 20
Gui, ICScriptHub:Add, Text, Section vBrivFeatSwapReads xs+%leftAlign% y+%ySpacing% w30, Reads
Gui, ICScriptHub:Add, Text, vBrivFeatSwapTarget x+15 w30, Target
GuiControlGet, pos, ICScriptHub:Pos, BrivFeatSwapTarget
Gui, ICScriptHub:Add, Text, vBrivFeatSwapQText xs ys+30 w15, Q:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapQValue x+%xSpacing% w20
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x%posX% y+-16 h19 w33 Limit3 vBrivGemFarm_BrivFeatSwap_TargetQ gBrivGemFarm_BrivFeatSwap_Target, 0
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, vBrivFeatSwapWText xs ys+60 w15, W:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapWValue x+%xSpacing% w20
xPosSave := posX+1
Gui, ICScriptHub:Add, Button, x%xPosSave% y+-16 h19 w31 vBrivGemFarm_BrivFeatSwap_Save gBrivGemFarm_BrivFeatSwap_Save, Save
Gui, ICScriptHub:Add, Text, vBrivFeatSwapEText xs ys+90 w15, E:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapEValue x+%xSpacing% w20
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x%posX% y+-16 h19 w33 Limit3 vBrivGemFarm_BrivFeatSwap_TargetE gBrivGemFarm_BrivFeatSwap_Target, 0
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, vBrivFeatSwapsMadeThisRunText xs ys+120 w15, SwapsMadeThisRun:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapsMadeThisRunValue x+%xSpacing% w40

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, vBrivFeatSwapStatus x%leftAlign% y+%ySpacing%, Status:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapStatusText x+%xSpacing% w170, Not Running
Gui, ICScriptHub:Font, w400

; Maximum number of simultaneous F keys inputs during MinLevel
BrivGemFarm_BrivFeatSwap_Target()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    if value is not integer
    {
        value := 0
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % value
    }
    else if (value < 0)
    {
        value := 0
        GuiControl, ICScriptHub:Text, %A_GuiControl%, % value
    }
}

BrivGemFarm_BrivFeatSwap_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    GuiControl, ICScriptHub: Disable, BrivGemFarm_BrivFeatSwap_Save
    g_BrivFeatSwap.Save(BrivGemFarm_BrivFeatSwap_TargetQ, BrivGemFarm_BrivFeatSwap_TargetE)
    GuiControl, ICScriptHub: Enable, BrivGemFarm_BrivFeatSwap_Save
}

; Test to see if BrivGemFarm addon is avaialbe.
if(IsObject(IC_BrivGemFarm_Component))
    global g_BrivFeatSwap := new IC_BrivGemFarm_BrivFeatSwap_Component
else
    GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, WARNING: This addon needs IC_BrivGemFarm enabled.

/*  IC_BrivGemFarm_BrivFeatSwap_Component

    Class that manages the GUI for BrivFeatSwap.
    Starts automotically on script launch and waits for Briv Gem Farm to be started, then stops/starts every time buttons on the main Briv Gem Farm window are clicked.
*/
Class IC_BrivGemFarm_BrivFeatSwap_Component
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_BrivFeatSwap_Settings.json"

    TimerFunctions := ""

    __New()
    {
        settings := g_SF.LoadObjectFromJSON(this.SettingsPath)
        if (IsObject(settings))
        {
            GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ, % settings.targetQ
            GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE, % settings.targetE
        }
        this.CreateTimedFunctions()
        g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(this, "Start"))
        g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(this, "Stop"))
        this.Start()
    }

   ; Adds timed functions to be run when briv gem farm is started
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "Update")
        this.TimerFunctions[fncToCallOnTimer] := 1000
    }

    Start()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, %v%, 0
        }
    }

     Stop()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Not Running
    }

    ; Update the GUI, try to read Q/W/E skip amounts
    Update()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            GuiControl, ICScriptHub:Text, BrivFeatSwapQValue, % SharedRunData.BrivFeatSwap_savedQSKipAmount
            GuiControl, ICScriptHub:Text, BrivFeatSwapWValue, % SharedRunData.BrivFeatSwap_savedWSKipAmount
            GuiControl, ICScriptHub:Text, BrivFeatSwapEValue, % SharedRunData.BrivFeatSwap_savedESKipAmount
            GuiControl, ICScriptHub:Text, BrivFeatSwapsMadeThisRunValue, % SharedRunData.SwapsMadeThisRun
            GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Running
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Waiting for Gem Farm to start
        }
    }

    Save(targetQ, targetE)
    {
        settings := {targetQ:targetQ, targetE:targetE}
        g_SF.WriteObjectToJSON(this.SettingsPath, settings)
        GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Settings saved
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.UpdateTargetAmounts(targetQ, targetE)
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Waiting for Gem Farm to start
        }
    }
}

IC_BrivGemFarm_BrivFeatSwap_Functions.InjectAddon()

#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk