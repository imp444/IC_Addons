GUIFunctions.AddTab("Briv Feat Swap")

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Briv Feat Swap
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Skip setup:
Gui, ICScriptHub:Font, w400

leftAlign := 20
xSpacing := 5
Gui, ICScriptHub:Add, Text, vBrivFeatSwapQText x%leftAlign% y+10 w15, Q:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapQValue x+%xSpacing% w40
Gui, ICScriptHub:Add, Text, vBrivFeatSwapWText x%leftAlign% y+5 w15, W:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapWValue x+%xSpacing% w40
Gui, ICScriptHub:Add, Text, vBrivFeatSwapEText x%leftAlign% y+5 w15, E:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapEValue x+%xSpacing% w40
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, vBrivFeatSwapStatus x%leftAlign% xs+10 y+10, Status:
Gui, ICScriptHub:Add, Text, vBrivFeatSwapStatusText x+%xSpacing% w170, Not Running
Gui, ICScriptHub:Font, w400

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
    TimerFunctions := ""

    __New()
    {
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
            SharedRunData.BrivFeatSwap_UpdateSkipAmount()
            GuiControl, ICScriptHub:Text, BrivFeatSwapQValue, % SharedRunData.BrivFeatSwap_savedQSKipAmount
            GuiControl, ICScriptHub:Text, BrivFeatSwapWValue, % SharedRunData.BrivFeatSwap_savedWSKipAmount
            GuiControl, ICScriptHub:Text, BrivFeatSwapEValue, % SharedRunData.BrivFeatSwap_savedESKipAmount
            GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Running
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BrivFeatSwapStatusText, Waiting for Gem Farm to start
        }
    }
}

IC_BrivGemFarm_BrivFeatSwap_Functions.InjectAddon()

#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk