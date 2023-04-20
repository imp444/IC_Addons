GUIFunctions.AddTab("Process Affinity")

global g_ProcessAffinity := new IC_ProcessAffinity_Component

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Process Affinity
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Core affinity:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Button , x+10 vProcessAffinitySave gProcessAffinitySave, Save
Gui, ICScriptHub:Add, Text, vProcessAffinityText x+5 w125

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, AltSubmit Checked -Hdr -Multi x15 y+15 w120 h320 vProcessAffinityView gProcessAffinityView, CoreID
GUIFunctions.UseThemeListViewBackgroundColor("ProcessAffinityView")
IC_ProcessAffinity_Component.BuildCoreList()

; Save button
ProcessAffinitySave()
{
    IC_ProcessAffinity_Component.SaveSettings()
}

; ViewList
ProcessAffinityView()
{
    if (A_GuiEvent == "I")
    {
        if InStr(ErrorLevel, "C", true)
            IC_ProcessAffinity_Component.Update(A_EventInfo, 1)
        else if InStr(ErrorLevel, "c", true)
            IC_ProcessAffinity_Component.Update(A_EventInfo, 0)
    }
}

/*  IC_ProcessAffinity_Component

    Class that manages the GUI for process affinity settings.
    The first checkbox is a toggle button.
    The other checkboxes set affinity to any number > 0 of available processor cores (physical/logical) for IdleDragons.exe.
    Overrides ICScriptHub.ahk's "Launch Idle Champions" button.
*/
Class IC_ProcessAffinity_Component
{
    ; Builds checkboxes for CoreAffinity
    BuildCoreList()
    {
        EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
        this.ProcessorCount := ProcessorCount
        if (ProcessorCount == 0)
        {
            GuiControl, Disable, ProcessAffinitySave
            GuiControl, ICScriptHub:, ProcessAffinityText, No cores found.
            return
        }
        else if (ProcessorCount > 64) ; TODO: Support for CPU Groups
        {
            GuiControl, Disable, ProcessAffinitySave
            GuiControl, ICScriptHub:, ProcessAffinityText, > 64 CPUs not supported.
            return
        }
        this.LoadSettings()
        LV_Add(, "All processors") ; Create unchecked boxes
        loop, %ProcessorCount%
        {
            LV_Add(, "CPU " . A_Index - 1)
        }
        settings := this.Settings["ProcessAffinityMask"]
        loop, %ProcessorCount% ; Check boxes
        {
            checked := (settings & (2 ** (A_Index - 1))) != 0
            if (checked)
                LV_Modify(A_Index + 1, "Check")
        }
        this.SaveSettings()
    }

    ; Loads settings from the addon's setting.json file.
    LoadSettings()
    {
        this.Settings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\ProcessAffinitySettings.json")
        if (!IsObject(this.Settings))
            this.Settings := {}
        if (this.Settings["ProcessAffinityMask"] == "")
        {
            coreMask := 0
            loop, % this.ProcessorCount ; Sum up all bits
            {
                coreMask += 2 ** (A_Index - 1)
            }
            this.Settings["ProcessAffinityMask"] := coreMask
        }
    }

     ; Saves settings to addon's setting.json file.
    SaveSettings()
    {
        coreMask := 0
        rowNumber := 1
        loop ; Sum up all checked boxes as an integer || signed int for 64 cores
        {
            nextChecked := LV_GetNext(RowNumber, "C")
            if (not nextChecked)
                break
            rowNumber := nextChecked
            coreMask += 2 ** (rowNumber - 2)
        }
        if (coremask == 0)
            return
        if (!IsObject(this.Settings))
            this.Settings := {}
        this.Settings["ProcessAffinityMask"] := coremask
        ; g_SF.WriteObjectToJSON( A_LineFile . "\..\ProcessAffinitySettings.json", this.Settings ) doesn't work with 64 cores
        str := "{`n`t""ProcessAffinityMask"":""" . coremask . """`n}"
        path := A_LineFile . "\..\ProcessAffinitySettings.json"
        FileDelete, %path%
        FileAppend, % str, %path%
        this.SetAllAffinities()
    }

    ; Sets the appropriate affinities to the game and scripts
    SetAllAffinities()
    {
        ; Set affinity after starting the GUI
        IC_ProcessAffinity_Functions.SetProcessAffinity(DllCall("GetCurrentProcessId"), 1) ; ICScriptHub.ahk
        ; Override ICScriptHub.ahk's "Launch Idle Champions" button to set the game's affinity, check for compatibility
        f := ObjBindMethod(g_ProcessAffinity, "Launch_Clicked_Affinity")
        GuiControl,ICScriptHub: +g, LaunchClickButton, % f
        ; Set affinity if the game process exists
        existingProcessID := g_UserSettings[ "ExeName"]
        Process, Exist, %existingProcessID%
        gamePID := ErrorLevel
        IC_ProcessAffinity_Functions.SetProcessAffinity(gamePID) ; IdleDragons.exe
    }

    ; Set affinity after clicking ICScriptHub.ahk's "Launch Idle Champions" button
    Launch_Clicked_Affinity()
    {
        Launch_Clicked()
        IC_ProcessAffinity_Functions.SetProcessAffinity(g_SF.PID) ; IdleDragons.exe
    }

    ; Update checkboxes
    Update(checkBoxIndex := 0, on := 1)
    {
        if (checkBoxIndex == 1) ; Toggle all checkbox
            this.ToggleAllCores(on)
        else if (!on)
            LV_Modify(1, "-Check")
        if (this.AreAllCoresChecked() AND (LV_GetNext(,"Checked") == 2))
            LV_Modify(1, "Check")
        if (LV_GetNext(,"Checked") == 0) ; Disable save if no cores are selected
            GuiControl, Disable, ProcessAffinitySave
        else
            GuiControl, Enable, ProcessAffinitySave
    }

    ; Toggle all cores, toggle on if at least one core was previously unchecked
    ToggleAllCores(on := 1)
    {
        if (!on AND !this.AreAllCoresChecked())
            return
        loop % LV_GetCount() - 1 ; Skip the toggle all checkbox
        {
            LV_Modify(A_Index + 1, on ? "Check" : "-Check")
        }
    }

    ; Returns true if all the core checkboxes are checked
    AreAllCoresChecked()
    {
        rowNumber := 1 ; This causes the first loop iteration to start the search at the top of the list.
        loop
        {
            nextChecked := LV_GetNext(rowNumber, "C")
            if (nextChecked - rowNumber > 1) ; Skipped over an unchecked box
                return false
            if (not rowNumber OR rowNumber == LV_GetCount()) ; There are no more selected rows.
                return true
            rowNumber := nextChecked ; Resume the search at the row after that found by the previous iteration.
        }
        return false
    }
}

IC_ProcessAffinity_Functions.InjectAddon()

#include %A_LineFile%\..\IC_ProcessAffinity_Functions.ahk