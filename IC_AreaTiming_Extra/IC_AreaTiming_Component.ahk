GUIFunctions.AddTab("Area Timing")

global g_AreaTiming := new IC_AreaTiming_Component

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Area Timing
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Recording:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Button , x+10 vAreaTimingStart gAreaTimingStart, Start
Gui, ICScriptHub:Add, Button , x+10 vAreaTimingStop gAreaTimingStop, Stop
Gui, ICScriptHub:Add, Button , x+60 vAreaTimingReset gAreaTimingReset, Reset

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, R40 x15 y+10 w375 vAreaTimingView gAreaTimingView, Area|Next|T_area|T_tran|Time (s)|Previous|Average|Count
GUIFunctions.UseThemeListViewBackgroundColor("AreaTimingView")

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, , Mod 50 (Excluding area 1 and offline stack area):
Gui, ICScriptHub:Font, w400

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, R8 x15 y+10 w375 vModAreaTimingView gModAreaTimingView, Area|Next|T_area|T_tran|Time (s)|Previous|Average|Count
GUIFunctions.UseThemeListViewBackgroundColor("ModAreaTimingView")

; Start button
AreaTimingStart()
{
    g_AreaTiming.Start()
}

; Stop button
AreaTimingStop()
{
    g_AreaTiming.Stop()
}

; Reset button
AreaTimingReset()
{
    g_AreaTiming.Reset()
}

AreaTimingView()
{
    Sleep, 100
}

ModAreaTimingView()
{
    Sleep, 100
}

; Test to see if BrivGemFarm addon is avaialbe.
if(IsObject(IC_BrivGemFarm_Component))
{
    g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_AreaTiming, "Start"))
    g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(g_AreaTiming, "Stop"))
}

/*  IC_AreaTiming_Component

    Class that manages the GUI for area timing.
    Based on IC_BrivGemFarm_Stats_Functions.ahk.
*/
Class IC_AreaTiming_Component
{
    __New()
    {
        this.CreateTimedFunctions()
        this.UpdateRunStats := false
        this.ResetStats := true
    }

    ; Adds timed functions to be run when briv gem farm is started
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "UpdateAreaTimingStatTimers")
        this.TimerFunctions[fncToCallOnTimer] := 20
        fncToCallOnTimer := ObjBindMethod(this, "UpdateGUI")
        this.TimerFunctions[fncToCallOnTimer] := 400
        fncToCallOnTimer := ObjBindMethod(this, "UpdateModGUI")
        this.TimerFunctions[fncToCallOnTimer] := 400
        fncToCallOnTimer := ObjBindMethod(IC_AreaTimingObject, "ProcessQueue")
        this.TimerFunctions[fncToCallOnTimer] := 200
    }

    Start()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "AreaTimingView")
        LV_ModifyCol(1, "Integer")
        LV_ModifyCol(2, "NoSort")
        LV_ModifyCol(6, "Integer")
        this.ResetStats := true
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
    }

    Reset()
    {
        IC_AreaTimingObject.Items := {}
        IC_AreaTimingObject.Queue := []
        IC_AreaTimingObject.Pending := {}
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "AreaTimingView")
        LV_Delete()
        this.Reset2()
    }

    Reset2()
    {
        IC_AreaTimingObject.PendingMod50 := {}
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ModAreaTimingView")
        LV_Delete()
    }

    ; Based on IC_BrivGemFarm_Stats_Functions.ahk\UpdateStatTimers()
    UpdateAreaTimingStatTimers()
    {
        static currentZoneStartTime := A_TickCount
        static previousLoopStartTime := A_TickCount ; not used
        static lastZone := 1
        static lastResetCount := 0
        static LastTriggerStart := false
        static skipMod50 := false
        static running := false
        static areaClearTrigger := false
        static dtAreaTime := 0
        static skipFirstArea := 1
        static skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        static mem := g_SF.Memory

        Critical, On
        TriggerStart := IsObject(this.SharedRunData) ? this.SharedRunData.TriggerStart : LastTriggerStart
        currentZone := g_SF.Memory.ReadCurrentZone()
        highestZone := g_SF.Memory.ReadHighestZone()
        if (!areaClearTrigger AND highestZone > currentZone) ; area cleared
        {
            dtAreaTime := Round((A_TickCount - currentZoneStartTime ) / 1000, 2)
            areaClearTrigger := true
        }
        if (this.ResetStats) ; Manual reset
        {
            currentZoneStartTime := A_TickCount
            previousLoopStartTime := A_TickCount
            lastZone := currentZone
            lastResetCount := g_SF.Memory.ReadResetsCount()
            LastTriggerStart := false
            this.ResetStats := false
            skipFirstArea := currentZone
            skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
            return
        }
        if (g_SF.Memory.ReadResetsCount() > lastResetCount OR (g_SF.Memory.ReadResetsCount() == 0 AND g_SF.Memory.ReadAreaActive() AND lastResetCount != 0 ) OR (TriggerStart AND LastTriggerStart != TriggerStart)) ; Modron or Manual reset happend
        {
            if (g_SF.Memory.ReadResetsCount() > lastResetCount) ; Modron reset
                this.UpdateRunStats := true
            lastResetCount := g_SF.Memory.ReadResetsCount()
            previousLoopStartTime := A_TickCount
            currentZoneStartTime := A_TickCount ; Reset zone timer after modron reset
            lastZone := 1
        }
        if !g_SF.Memory.ReadUserIsInited() ; resetting/restarting
        {
            skipMod50 := true
            ; do not update lastZone if game is loading
        }
        else if ((currentZone > lastZone) AND (currentZone >= 2)) ; zone reset
        {
            while (g_SF.Memory.ReadTransitioning() > 0) ; wait for screen transition
            {
                Sleep, 1
            }
            dtAreaToNextTime := Round(( A_TickCount - currentZoneStartTime ) / 1000, 2)
            currentZoneStartTime := A_TickCount
            if (lastZone <= 1)
                skipMod50 := true
            if (lastZone != skipFirstArea AND ((lastZone + skipAmount + 1) >= currentZone)) ; Skip first value
            {
                IC_AreaTimingObject.AddToQueue(lastZone, currentZone, dtAreaTime, dtAreaToNextTime, skipMod50)
            }
            lastZone := currentZone
            skipMod50 := false
            areaClearTrigger := false
        }
        else if ((g_SF.Memory.ReadHighestZone() < 3) AND (lastZone >= 3) AND (currentZone > 0) ) ; After reset. +1 buffer for time to read value
        {
            lastZone := currentZone
            previousLoopStartTime := A_TickCount
        }
        Critical, Off
    }

    ; Function that updates the AreaTiming GUI
    ; Area|Next|T_area|T_tran|Time (s)|Previous|Average|Count
    UpdateGUI()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "AreaTimingView")
        pending := IC_AreaTimingObject.Pending ; Current run
        Loop % LV_GetCount()
        {
            LV_GetText(area, A_Index, 1)
            LV_GetText(next, A_Index, 2)
            k := area . "to" . next
            item := pending[k]
            if (IsObject(item))
            {
                LV_GetText(previous, A_Index, 6)
                LV_Modify(A_Index, "Col3", item.areaTime, item.transitionTime, item.time, previous, item.averageTime, item.count)
                pending.Delete(k)
            }
            if pending.Count() == 0
                break
        }
        for k, v in pending ; New items
        {
            LV_Add(, v.lastZone, v.currentZone, v.areaTime, v.transitionTime, v.time, "", v.averageTime, v.count)
            pending.Delete(k)
        }
        if (this.UpdateRunStats) ; Move current stats to previous stats
        {
            Loop % LV_GetCount()
            {
                LV_GetText(time, A_Index, 5)
                LV_GetText(average, A_Index, 7)
                LV_GetText(count, A_Index, 8)
                LV_Modify(A_Index, "Col5", "", time, average, count)
            }
            LV_ModifyCol(1, "Sort")
            this.UpdateRunStats := false
        }
        Loop % LV_GetCount("Col") ; Resize columns
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
    }

    ; Function that updates the AreaTiming Mod50 GUI
    ; Area|Next|T_area|T_tran|Time (s)|Previous|Average|Count
    UpdateModGUI()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ModAreaTimingView")
        pending := IC_AreaTimingObject.PendingMod50 ; Current run
        Loop % LV_GetCount()
        {
            LV_GetText(area, A_Index, 1)
            LV_GetText(next, A_Index, 2)
            k := "mod" . area . "to" . next
            item := pending[k]
            if (IsObject(item))
            {
                LV_GetText(previous, A_Index, 5)
                LV_Modify(A_Index, "Col3", item.areaTime, item.transitionTime, item.time, previous, item.averageTime, item.count)
                pending.Delete(k)
            }
            if pending.Count() == 0
                break
        }
        for k, v in pending ; New items
        {
            LV_Add(, v.lastZone, v.currentZone, v.areaTime, v.transitionTime, v.time, "", v.averageTime, v.count)
            pending.Delete(k)
        }
        Loop % LV_GetCount("Col") ; Resize columns
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
        LV_ModifyCol(1, "Integer")
        LV_ModifyCol(1, "Sort")
    }
}

; Object that holds stats from zone progress
Class IC_AreaTimingObject
{
    static Items := {}
    static Pending := {}
    static PendingMod50 := {}
    static Queue := []

    __New(lastZone, currentZone, areaTime, areaToNextTime)
    {
        this.lastZone := lastZone
        this.currentZone := currentZone
        this.areaTime := areaTime
        this.transitionTime := Round(areaToNextTime - areaTime, 2)
        this.time := areaToNextTime
        this.totalTime := 0
        this.averageTime := 0
        this.count := 0
    }

    ; areaToNextTime = areaTime + transitonTime
    AddToQueue(lastZone, currentZone, areaTime, areaToNextTime, skipMod50 := false)
    {
        rawItem := {}
        rawItem.lastZone := lastZone
        rawItem.currentZone := currentZone
        rawItem.areaTime := areaTime
        rawItem.areaToNextTime := areaToNextTime
        rawItem.skipMod50 := skipMod50
        IC_AreaTimingObject.Queue.Push(rawItem)
    }

    ProcessQueue()
    {
        q := IC_AreaTimingObject.Queue
        while q.Length()
            IC_AreaTimingObject.AddProgress(q.RemoveAt(1))
    }

    ; Get/Create stats items
    AddProgress(rawItem)
    {
        lastZone := rawItem.lastZone
        currentZone := rawItem.currentZone
        areaTime := rawItem.areaTime
        areaToNextTime := rawItem.areaToNextTime
        k := lastZone . "to" . currentZone
        item := IC_AreaTimingObject.GetProgress(k, lastZone, currentZone, areaTime, areaToNextTime)
        IC_AreaTimingObject.Pending[k] := item.Clone()
        if (rawItem.skipMod50) ; Skip on reset/offline stacking
            return
        modLastZone := Mod(lastZone, 50) ? Mod(lastZone, 50) : 50
        modCurrentZone := Mod(currentZone, 50) ? Mod(currentZone, 50) : 50
        k := "mod" . modLastZone . "to" . modCurrentZone
        item := IC_AreaTimingObject.GetProgress(k, modLastZone, modCurrentZone, areaTime, areaToNextTime)
        IC_AreaTimingObject.PendingMod50[k] := item.Clone()
    }

    ; Update stats item
    GetProgress(key, lastZone, currentZone, areaTime, areaToNextTime)
    {
        item := IC_AreaTimingObject.Items[key]
        if (!IsObject(item))
        {
            item := new IC_AreaTimingObject(lastZone, currentZone, areaTime, areaToNextTime)
            IC_AreaTimingObject.Items[key] := item
        }
        item.count += 1
        item.areaTime := areaTime
        item.transitionTime := Round(areaToNextTime - areaTime, 2)
        item.time := Round(areaToNextTime, 2)
        item.totalTime := Round(item.totalTime + item.time, 2)
        item.averageTime := Round(item.totalTime / item.count, 2)
        return item
    }
}