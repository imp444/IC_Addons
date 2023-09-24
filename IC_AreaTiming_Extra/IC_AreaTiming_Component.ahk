#include %A_LineFile%\..\IC_AreaTiming_GUI.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_RunCollection.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_SharedData.ahk

global g_AreaTimingGui := new IC_AreaTiming_GUI
global g_AreaTiming := new IC_AreaTiming_Component

/*  IC_AreaTiming_Component

    Class that manages the GUI for area timing.
    Based on IC_BrivGemFarm_Stats_Functions.ahk.
*/
Class IC_AreaTiming_Component
{
    static SettingsPath := A_LineFile . "\..\AreaTiming_Settings.json"

    Settings := ""
    TimerFunctions := ""
    TimerScriptGUID := ""
    TimerScriptLoc := A_LineFile . "\..\IC_AreaTiming_TimerScript_Run.ahk"
    FirstSessionID := 0
    TotalSessions := 0
    FirstRunID := 0
    TotalRuns := 0
    Session := ""
    Run := ""
    RunEnded := false
    LastSelectRunText := ""

    __New()
    {
        ; Read settings
        this.Settings := settings := g_SF.LoadObjectFromJSON(this.SettingsPath)
        if (!IsObject(settings))
        {
            settings := this.GetNewSettings()
            this.Settings := settings
            this.SaveSettings()
        }
        ; Set the state of GUI buttons with saved settings.
        GuiControl, ICScriptHub:, AreaTimingBGFSync, % settings.BrivGemFarmSync
        GuiControl, ICScriptHub:, AreaTimingUncappedSpeed, % settings.ShowUncappedGameSpeed
        GuiControl, ICScriptHub:, AT_ExcludeMod50Outliers, % settings.ExcludeMod50Outliers
        this.BGFSync(settings.BrivGemFarmSync)
        ; Try to reconnect if the timer script was already launched.
        this.UpdateLastGUID()
        this.CreateTimedFunctions()
        for k, v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    ; Returns an object with default values for all settings.
    GetNewSettings()
    {
        settings := {}
        settings.BrivGemFarmSync := false
        settings.ShowUncappedGameSpeed := false
        settings.ExcludeMod50Outliers := true
        return settings
    }

    ; Save the addon settings to the settings file.
    SaveSettings()
    {
        g_SF.WriteObjectToJSON(this.SettingsPath, this.Settings)
    }

    ; Add timed functions to be run when BrivGemFarm_Run is started.
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "Update")
        this.TimerFunctions[fncToCallOnTimer] := 1000
    }

    Start()
    {
        this.StartTimerScript()
        for k, v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    ; Synchronise start/stop buttons with the buttons in the Briv Gem Farm tab.
    ; Parameters: - sync:bool - If true, start/stop the timer script when
    ;               the buttons are clicked in the BrivGemFarm tab.
    ;               If false, remove the script from the Miniscripts list.
    BGFSync(sync)
    {
        static boundStart := ""
        static boundStop := ""

        this.Settings.BrivGemFarmSync := sync
        this.SaveSettings()
        if(IsObject(IC_BrivGemFarm_Component))
        {
            if (sync)
            {
                boundStart := ObjBindMethod(this, "Start")
                boundStop := ObjBindMethod(this, "StopFromBrivGemFarmStop")
                g_BrivFarmAddonStartFunctions.Push(boundStart)
                g_BrivFarmAddonStopFunctions.Push(boundStop)
                this.AddScriptToMiniscripts()
            }
            else
            {
                this.DeleteScriptFromMiniscripts()
                for k, v in g_BrivFarmAddonStartFunctions
                    if (v == boundStart)
                        g_BrivFarmAddonStartFunctions.Delete(k)
                for k, v in g_BrivFarmAddonStopFunctions
                    if (v == boundStop)
                        g_BrivFarmAddonStopFunctions.Delete(k)
                boundStart := boundStop := ""
            }
        }
    }

    ; Show uncapped timescale multiplier (for speeds over x10).
    ; Params: - capped:bool - If true, show uncapped speed, else up to 10x.
    ToggleUncappedGameSpeed(capped)
    {
        this.Settings.ShowUncappedGameSpeed := capped
        this.SaveSettings()
        ; Reload view.
        this.LoadRun(,, true)
    }

    ; Checkbox to show mod50 values with or without outliers.
    ; Params: - exclude:bool - If true, filter out z1, stack zone and reset area.
    ToggleExcludeMod50Outliers(exclude)
    {
        this.Settings.ExcludeMod50Outliers := exclude
        this.SaveSettings()
        ; Reload view.
        this.LoadRun(,, true)
    }

    ; Returns the COM object associated to the timer script's shared data class.
    TimerScript
    {
        get
        {
            try
            {
                return ComObjActive(this.TimerScriptGUID)
            }
            catch
            {
                return ""
            }
        }
    }

    IsTimerScriptRunning()
    {
        return this.GetScriptPID("IC_AreaTiming_TimerScript_Run.ahk")
    }

    ; Returns the PID from an ahk script.
    ; Params: - ScriptName:str - Name of the script.
    GetScriptPID(ScriptName)
    {
        DHW := A_DetectHiddenWindows
        TMM := A_TitleMatchMode
        DetectHiddenWindows, On
        SetTitleMatchMode, 2
        WinGet, PID, PID, \%ScriptName% - ahk_class AutoHotkey
        DetectHiddenWindows, %DHW%
        SetTitleMatchMode, %TMM%
        Return PID
    }

    ; If not found, launch a new instance of the timer script.
    StartTimerScript()
    {
        if (this.IsTimerScriptRunning())
        {
            if(this.UpdateLastGUID() == "")
            {
                this.Stop()
                this.StartTimerScript()
            }
            else
            {
                try
                {
                    sharedData := this.TimerScript
                    sharedData.Start()
                }
            }
        }
        else
        {
            this.AddScriptToMiniscripts()
            ; Start the script
            scriptLocation := this.TimerScriptLoc
            guid := this.TimerScriptGUID
            Run, %scriptLocation% %guid%
        }
    }

    ; Retrieve the saved GUID of the timer script in the Miniscripts file.
    UpdateLastGUID()
    {
        miniscriptsLoc := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\LastGUID_Miniscripts.json"
        miniscripts := g_SF.LoadObjectFromJSON(miniscriptsLoc)
        for k, v in miniscripts
        {
            if (v == this.TimerScriptLoc)
            {
                this.TimerScriptGUID := k
                g_Miniscripts[k] := v
                return k
            }
        }
        ; GUID not found
        return ""
    }

    ; Add this script's GUID to the Miniscripts file.
    AddScriptToMiniscripts()
    {
        ; Don't add if the process is still running.
        if (this.IsTimerScriptRunning())
            return
        ; Delete previous GUID
        this.DeleteScriptFromMiniscripts()
        ; Create unique identifier (GUID) for the addon to be used by Script Hub.
        this.TimerScriptGUID := guid := ComObjCreate("Scriptlet.TypeLib").Guid
        ; Added the script to be run when play is pressed to the list of scripts to be run.
        g_Miniscripts[guid] := scriptLocation := this.TimerScriptLoc
        miniscriptsLoc := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\LastGUID_Miniscripts.json"
        g_SF.WriteObjectToJSON(miniscriptsLoc, g_Miniscripts)
    }

    ; Remove this script's GUID from the Miniscripts file.
    DeleteScriptFromMiniscripts()
    {
        ; Don't delete if the process is still running.
        if (this.IsTimerScriptRunning())
            return
        for k, v in g_Miniscripts
            if (v == this.TimerScriptLoc)
                g_Miniscripts.Delete(k)
        miniscriptsLoc := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\LastGUID_Miniscripts.json"
        g_SF.WriteObjectToJSON(miniscriptsLoc, g_Miniscripts)
    }

    Stop()
    {
        for k, v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        if (this.TimerScript.Running)
        {
            this.Reset()
            this.Update(true)
        }
        if (!this.Settings.BrivGemFarmSync)
            this.DeleteScriptFromMiniscripts()
    }

    ; Function called when the stop button in the BrivGemFarm tab has been clicked
    ; on. It will prevent the timer script from being closed if the stop button
    ; is clicked on multiple times in a row.
    StopFromBrivGemFarmStop()
    {
        counter := 1
        for k, v in g_BrivFarmLastRunMiniscripts
        {
            if (k == this.TimerScriptGUID)
            {
                counter := 2
                break
            }
        }
        while (!ready && this.IsTimerScriptRunning())
        {
            try
            {
                sharedData := this.TimerScript
                sharedData.IgnoreClose := counter
                ready := sharedData.IgnoreClose == counter || sharedData == ""
            }
            Sleep, 30
        }
        this.Stop()
    }

    ; Reset ListViews / DDLs.
    Reset()
    {
        this.DeleteView("AreaTimingView")
        this.DeleteView("ModAreaTimingView")
        this.DeleteView("StacksAreaTimingView")
        GuiControl, ICScriptHub:, AreaTimingSelectSession, % "| "
        g_AreaTimingGui.UpdateSelectSessionText()
        GuiControl, ICScriptHub:, AreaTimingSelectRun, % "| "
        g_AreaTimingGui.UpdateSelectRunText()
        GuiControl, ICScriptHub:Text, AT_SelectSessionID,
        GuiControl, ICScriptHub:Text, AT_SelectRunID,
        this.FirstSessionID := 0
        this.TotalSessions := 0
        this.FirstRunID := 0
        this.TotalRuns := 0
        this.Session := ""
        this.Run := ""
    }

    DeleteView(controlID)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", controlID)
        LV_Delete()
    }

    ; Close the timer script.
    ; If the saved GUID doesn't match the script GUID, force close.
    CloseTimerScript()
    {
        try
        {
             script := ComObjActive(this.TimerScriptGUID)
             script.Close(true)
        }
        catch
        {
            PID := this.IsTimerScriptRunning()
            if (PID)
                Process, Close, %PID%
        }
        this.Reset()
    }

    ; Returns true if the script's current session start time matches the input session's start time.
    IsCurrentSession(session := "")
    {
        try
        {
            sharedData := ComObjActive(this.TimerScriptGUID)
            if (session == "")
                session := this.Session
            return session.StartTime == sharedData.CurrentSession.StartTime
        }
    }

    ; Returns true if the script's current run start time matches the input session's start time.
    IsCurrentRun(run := "")
    {
        try
        {
            sharedData := ComObjActive(this.TimerScriptGUID)
            if (run == "")
                run := this.Run
            return run.StartTime == sharedData.CurrentSession.CurrentRun.StartTime
        }
    }

    ; Main update for this addons GUI.
    ; Params: - stop:bool - If true, stop the timer script's loop, then update DDLs.
    Update(stop := false)
    {
        try
        {
            sharedData := ComObjActive(this.TimerScriptGUID)
            if (stop)
                sharedData.Stop()
            running := sharedData.Running
            ; Read sessions
            sessions := sharedData.Sessions
            sessionCount := sessions.Length()
            firstSessionID := sessions[1].ID
            if (!running || this.NewSessionExists(sessionCount, firstSessionID))
            {
                this.TotalSessions := sessionCount
                this.FirstSessionID := firstSessionID
                this.UpdateSelectSession(sessions, running)
            }
            ; Read current session
            session := sharedData.CurrentSession
            runs := session.Runs
            runCount := runs.Length()
            currentRun := session.CurrentRun
            firstID := runs[1].ID
            hasNewRun := runCount != this.TotalRuns || this.FirstRunID != firstID
            if (!running || hasNewRun && firstID != 0 && firstID != "" && runCount != "")
            {
                this.TotalRuns := runCount
                this.FirstRunID := firstID
                ; Update only if the selected session is the same as the session being recorded
                if (this.IsCurrentSession() && running)
                    this.UpdateSelectRun(runs)
                else if (!running)
                    this.UpdateSelectRun(this.Session.runs, false)
            }
            ; Update DDLs on first load.
            if (this.Session == "" && session)
            {
                this.Session := session
                if (this.Run == "" && runs[1])
                    this.Run := runs[1]
                GuiControl, ICScriptHub:Choose, AreaTimingSelectSession, |1
                GuiControl, ICScriptHub:Choose, AreaTimingSelectRun, |1
            }
            ; Stop updating if the timer script is not running.
            if (!running)
            {
                for k, v in this.TimerFunctions
                {
                    SetTimer, %k%, Off
                    SetTimer, %k%, Delete
                }
            }
        }
    }

    ; Returns true when a new session has started.
    ; Params: - count:int - Number of sessions in the shared data object.
    ;         - firstSessionID:int - ID of the first session object.
    NewSessionExists(count, firstSessionID)
    {
        if (firstSessionID == 0 || firstSessionID == "" || count == "")
            return false
        sessionCountDiff := count != this.TotalSessions
        firstSessionIDDiff := firstSessionID != this.FirstSessionID
        return sessionCountDiff || firstSessionIDDiff
    }

    ; Update choices for the "select session" DDL.
    ; Params: - sessions:list - List of sessions.
    ;         - showCurrent:bool - If true, show "Current session" as a choice.
    ; If showCurrent is true, 1:"Current session", 2+:list of sessions.
    ; If showCurrent is false, 1+:list of runs.
    UpdateSelectSession(sessions, showCurrent := true)
    {
        sessionCount := sessions.Length()
        ; Build list of choices with or without current session item
        if (showCurrent)
            choices := "Current session|" . this.GetFormattedTimeStamp(sessions[1].StartTime)
        else
            choices := this.GetFormattedTimeStamp(sessions[1].StartTime)
        Loop, % sessionCount - 1
            choices .= "|" . this.GetFormattedTimeStamp(sessions[A_Index + 1].StartTime)
        ; Remember current selection
        if (showCurrent)
        {
            GuiControlGet, sel, ICScriptHub:, AreaTimingSelectSession
            sel := (sel == "" || sel == 1) ? sessionCount + 1 : Min(sel + 1, sessionCount + 1)
        }
        else
            sel := sessionCount
        ; Update choices
        GuiControl, ICScriptHub:, AreaTimingSelectSession, % "|" . choices
        GuiControl, ICScriptHub:Choose, AreaTimingSelectSession, % sel
        ; Update counter
        this.LoadSession(sel)
    }

    ; Update choices for the "select run" DDL.
    ; Params: - runs:list - List of runs.
    ;         - showCurrent:bool - If true, show "Current run" as a choice.
    ; If showCurrent is true, 1:"All", 2:"Current session", 3+:list of sessions.
    ; If showCurrent is false, 1:"All", 2+:list of runs.
    UpdateSelectRun(runs, showCurrent := true)
    {
        runCount := runs.Length()
        ; Build list of choices with or without current run item
        choices := "All runs" . (showCurrent ? "|Current run" : "")
        Loop, % runCount
            choices .= "|" . this.GetFormattedTimeStamp(runs[A_Index].StartTime)
        ; Remember current selection, default to last run
        if (showCurrent)
        {
            GuiControlGet, sel, ICScriptHub:, AreaTimingSelectRun
            sel := sel == "" || sel == 2 ? runCount + 2 : Min(sel, runCount + 2)
        }
        else ; Default to first run
            sel := 2
        ; Update choices
        GuiControl, ICScriptHub:, AreaTimingSelectRun, % "|" . choices
        if ((ctrlID := g_AreaTimingGui.GetCurrentlyDroppedCombo()) == "")
            GuiControl, ICScriptHub:Choose, AreaTimingSelectRun, % sel
        else
        {
            text := this.LastSelectRunText
            GuiControl, ICScriptHub:ChooseString, AreaTimingSelectRun, % text
            GuiControlGet, hwnd, ICScriptHub:Hwnd, %ctrlID%
            SendMessage, 0x014f, 1, 0,, ahk_id %hwnd% ; CB_SHOWDROPDOWN
            GuiControlGet, runID, ICScriptHub:, AT_SelectRunID
            g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
            return
        }
        ; Update counter
        runID := showCurrent ? Min(sel - 2, runCount) : 1
        runID := (runID < 1 ) ? "-" : runID
        g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
    }

    ; Return a date/time format timestamp.
    ; Params: timestamp:int - Unix epoch time.
    GetFormattedTimeStamp(timestamp)
    {
        mSec := Mod(timestamp, 1000)
        unixTime := Round((timestamp - mSec)/ 1000)
        time := this.UnixToUTC(unixTime)
        FormatTime, timeStrDate, % time, ShortDate
        FormatTime, timeStrHHmmss, % time, HH:mm:ss
        return timeStrDate . " " . timeStrHHmmss
    }

    UnixToUTC(unixTime)
    {
        time := 1970
        time += unixTime, s
        return time
    }

    ; Load ListViews with values from the run chosen in the DDL.
    ; Params: - choice:int - List index. If viewing current session,
    ;           index starts at 2, with 1 being the current session.
    ;         - retry:bool - If true, on failure, retry in 30ms.
    ;         - sessionID:int - ID of the session to load (overrides choice).
    LoadSession(choice := 1, retry := true, sessionID := "")
    {
        try
        {
            sharedData := this.TimerScript
            sessions := sharedData.Sessions
            sessionCount := sessions.Length()
            running := sharedData.Running
            if (sessionID > 0)
            {
                session := sessions[sessionID]
                sel := sessionID + running
                GuiControl, ICScriptHub:Choose, AreaTimingSelectSession, % sel
            }
            else if (running)
            {
                session := (choice == 1) ? sharedData.CurrentSession : sessions[choice - 1]
                sessionID := (choice == 1) ? sessionCount : choice - 1
            }
            else
            {
                session := sessions[choice]
                sessionID := choice
            }
            g_AreaTimingGui.UpdateSelectSessionText(sessionID, sessionCount)
            ; Update only if another session has been chosen.
            if (session.StartTime != this.Session.StartTime)
            {
                g_AreaTimingGui.ToggleSelection(false)
                this.Session := session
                ; Load runs
                showCurrent := running && sharedData.CurrentSession.ID == session.ID
                this.UpdateSelectRun(session.Runs, showCurrent)
                this.LoadRun(, false)
            }
        }
        catch
        {
            ; Retry once if the COM object is busy.
            if (retry)
            {
                params := [choice, false]
                func := ObjBindMethod(this, "RetryLoadSession", params*)
                SetTimer, %func%, -30
            }
        }
        g_AreaTimingGui.ToggleSelection(true)
    }

    RetryLoadSession(params*)
    {
        this.LoadSession(params*)
    }

    ; Load ListViews with values from the run chosen in the DDL.
    ; Params: - choice:int - List index. If viewing current session,
    ;           index starts at 2, with 1 being the current run.
    ;         - retry:bool - If true, on failure, retry in 30ms.
    ;         - reload:bool - If true, reload currently selected run.
    ;         - runID:int - ID of the run to load (overrides choice).
    LoadRun(choice := 2, retry := true, reload := false, runID := "")
    {
        try
        {
            session := this.Session
            if (session.StartTime == "")
                return
            sharedData := this.TimerScript
            isCurrentSession := this.IsCurrentSession()
            runs := session.Runs
            runCount := runs.Length()
            running := sharedData.Running
            if (runID > 0)
            {
                run := runs[runID]
                sel := runID + 1 + (running && isCurrentSession)
                GuiControl, ICScriptHub:Choose, AreaTimingSelectRun, % sel
            }
            ; All runs
            else if (choice == 1)
            {
                g_AreaTimingGui.ToggleSelection(false)
                this.Run := ""
                this.LastSelectRunText := "All"
                g_AreaTimingGui.UpdateSelectRunText("-", runCount)
                this.UpdateRunGUIAll(session)
                this.UpdateStacksGUI(session)
                return g_AreaTimingGui.ToggleSelection(true)
            }
            else if (reload)
            {
                run := this.Run
                if (run == "")
                    return this.LoadRun(1,, true)
            }
            else if (running && isCurrentSession)
                run := (choice == 2) ? session.CurrentRun : runs[choice - 2]
            else
                run := runs[choice - 1]
            runID := run.ID
            ; Update only if another run has been chosen or run is not finished.
            if (reload || run.StartTime != this.Run.StartTime || running && !this.RunEnded && isCurrentSession)
            {
                g_AreaTimingGui.ToggleSelection(false)
                this.Run := run
                this.RunEnded := run.Ended
                if (!reload)
                    g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
                this.UpdateRunGUI(session, run)
                this.UpdateStacksGUI(session, run)
            }
            else
                g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
        }
        catch
        {
            ; Retry once if the COM object is busy.
            if (retry)
            {
                params := [choice, false]
                func := ObjBindMethod(this, "RetryLoadRun", params*)
                SetTimer, %func%, -30
            }
        }
        ; Remember current selection
        GuiControlGet, sel, ICScriptHub:, AreaTimingSelectRun, Text
        this.LastSelectRunText := sel
        g_AreaTimingGui.ToggleSelection(true)
    }

    RetryLoadRun(params*)
    {
        this.LoadRun(params*)
    }

    ; Function that updates the AreaTiming GUI.
    ; Area|Next|T_area|T_tran|T_time|AvgT_area|AvgT_tran|AvgT_time|T_run|AvgT_run|Count|Game speed|AvgGame speed
    UpdateRunGUI(session, run)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "AreaTimingView")
        LV_Delete()
        g_AreaTimingGui.BuildAreaTimingView()
        mod50Vals := {}
        runTime := 0
        uncapped := this.Settings.ShowUncappedGameSpeed
        items := run.Items
        Loop, % items.Length()
        {
            obj := items[A_Index]
            area := obj.StartZone
            next := obj.EndZone
            areaTime := Round(obj.AreaTime / 1000, 2)
            transitionTime := Round(obj.TransitionTime / 1000, 2)
            time := Round(obj.TotalTime / 1000, 2)
            runTime += obj.TotalTime
            runTimeRounded := Round(runTime / 1000, 2)
            ; Average
            avgCount := session.GetAverageCount(obj.Zones)
            count := avgCount[1]
            avgAreaTime := Round(avgCount[2] / 1000, 2)
            avgTransitionTime := Round(avgCount[3] / 1000, 2)
            avgTime := Round(avgCount[4] / 1000, 2)
            avgRunTime := Round(avgCount[5] / 1000, 2)
            ; Capped game speed = 10x
            gameSpeed := obj.GameSpeed
            gameSpeedRounded := uncapped ? Round(gameSpeed, 3) : Round(Min(gameSpeed, 10), 3)
            avgGameSpeed := avgCount[6]
            avgGameSpeedRounded := uncapped ? Round(avgGameSpeed, 3) : Round(Min(avgGameSpeed, 10), 3)
            ; Mod50
            mod50Key := obj.Mod50Zones
            if (!mod50Vals.HasKey(mod50Key))
                mod50Vals[mod50Key] := []
            mod50Vals[mod50Key].Push(obj)
            LV_Add(, area, next, areaTime, transitionTime, time, avgAreaTime, avgTransitionTime, avgTime, runTimeRounded, avgRunTime, count, gameSpeedRounded, avgGameSpeedRounded)
        }
        ; Resize columns
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
        this.UpdateMod50GUI(session, run, mod50Vals)
    }

    ; Function that updates the AreaTiming GUI (all runs).
    ; Area|Next|AvgT_area|AvgT_tran|AvgT_time|AvgT_run|CountGame speed|AvgGame speed
    UpdateRunGUIAll(session)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "AreaTimingView")
        LV_Delete()
        g_AreaTimingGui.BuildAreaTimingView(true)
        mod50Vals := {}
        uncapped := this.Settings.ShowUncappedGameSpeed
        keys := session.GetAllItemKeys()
        Loop, % keys.Length()
        {
            key := keys[A_Index]
            area := key >>> 16
            next := key & 0xFFFF
            ; Average
            avgCount := session.GetAverageCount(key)
            count := avgCount[1]
            avgAreaTime := Round(avgCount[2] / 1000, 2)
            avgTransitionTime := Round(avgCount[3] / 1000, 2)
            avgTime := Round(avgCount[4] / 1000, 2)
            avgRunTime := Round(avgCount[5] / 1000, 2)
            ; Capped game speed = 10x
            avgGameSpeed := avgCount[6]
            avgGameSpeedRounded := uncapped ? Round(avgGameSpeed, 3) : Round(Min(avgGameSpeed, 10), 3)
            ; Mod50
            simpleObj := new IC_AreaTiming_TimeObjectSimple(area)
            simpleObj.SetAreaTransitioned(next)
            mod50Key:= simpleObj.Mod50Zones
            if (!mod50Vals.HasKey(mod50Key))
                mod50Vals[mod50Key] := simpleObj
            LV_Add(, area, next, avgAreaTime, avgTransitionTime, avgTime, avgRunTime, count, avgGameSpeedRounded)
        }
        ; Resize columns
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
        this.UpdateMod50GUIAll(session, mod50Vals)
    }

    ; Function that updates the AreaTiming Mod50 GUI.
    ; Area|Next|T_area|T_tran|T_time|AvgT_area|AvgT_tran|AvgT_time|Count
    UpdateMod50GUI(session, run, mod50Vals)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ModAreaTimingView")
        LV_Delete()
        g_AreaTimingGui.BuildModAreaTimingView()
        excludeOutliers := this.Settings.ExcludeMod50Outliers
        for k, v in mod50Vals
        {
            area := v[1].Mod50StartZone
            next := v[1].Mod50EndZone
            ; Run average
            avgCount := excludeOutliers ? session.GetAverageMod50CountEx(v[1].Mod50Zones, [run]) : session.GetAverageMod50Count(v[1].Mod50Zones, [run])
            countRun := avgCount[1]
            areaTime := Round(avgCount[2] / 1000, 2)
            transitionTime := Round(avgCount[3] / 1000, 2)
            time := Round(avgCount[4] / 1000, 2)
            ; Session average
            avgCount := excludeOutliers ? session.GetAverageMod50CountEx(v[1].Mod50Zones) : session.GetAverageMod50Count(v[1].Mod50Zones)
            count := avgCount[1]
            avgAreaTime := Round(avgCount[2] / 1000, 2)
            avgTransitionTime := Round(avgCount[3] / 1000, 2)
            avgTime := Round(avgCount[4] / 1000, 2)
            LV_Add(, area, next, areaTime, transitionTime, time, countRun, avgAreaTime, avgTransitionTime, avgTime, count)
        }
        ; Resize columns
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
        LV_ModifyCol(1, "Sort")
    }

    ; Function that updates the AreaTiming Mod50 GUI (all runs).
    ; Area|Next|AvgT_area|AvgT_tran|AvgT_time|Count
    UpdateMod50GUIAll(session, mod50Vals)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ModAreaTimingView")
        LV_Delete()
        g_AreaTimingGui.BuildModAreaTimingView(true)
        excludeOutliers := this.Settings.ExcludeMod50Outliers
        for k, v in mod50Vals
        {
            area := v.Mod50StartZone
            next := v.Mod50EndZone
            ; Average
            avgCount := excludeOutliers ? session.GetAverageMod50CountEx(v.Mod50Zones) : session.GetAverageMod50Count(v.Mod50Zones)
            avgAreaTime := Round(avgCount[2] / 1000, 2)
            avgTransitionTime := Round(avgCount[3] / 1000, 2)
            avgTime := Round(avgCount[4] / 1000, 2)
            LV_Add(, area, next, avgAreaTime, avgTransitionTime, avgTime, avgCount[1])
        }
        ; Resize columns
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
        LV_ModifyCol(1, "Sort")
    }

    ; Function that updates the AreaTiming Stacks GUI.
    ; Area|Next|T_time|AvgT_Time|Stacks|AvgStacks|Count|Stacks/s|AvgStacks/s|Jumps/s|AvgJumps/s|Game speed
    ; Run ID|Area|Next|T_time|AvgT_Time|Stacks|AvgStacks|Count|Stacks/s|AvgStacks/s|Jumps/s|AvgJumps/s|Game speed
    UpdateStacksGUI(session, run := "")
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "StacksAreaTimingView")
        LV_Delete()
        isAll := (run == "")
        g_AreaTimingGui.BuildStacksAreaTimingView(isAll)
        if (isAll)
        {
            data := session.GetAllAverageStacks()
            allAverageStacks := data[2]
            keys := data[3]
            ; Build associative array
            averageData := {}
            Loop, % keys.Length()
                averageData[keys[A_Index]] := allAverageStacks[A_Index]
            items := data[1]
        }
        else
            items := run.StackItems
        uncapped := this.Settings.ShowUncappedGameSpeed
        Loop, % items.Length()
        {
            obj := isAll ? items[A_Index][1] : items[A_Index]
            ; Capped game speed = 10x
            gameSpeed := obj.GameSpeed
            gameSpeedRounded := uncapped ? Round(gameSpeed, 3) : Round(Min(gameSpeed, 10), 3)
            area := obj.StartZone
            next := obj.EndZone
            time := Round(obj.TotalTime / 1000, 2)
            ; Average
            averageCount := isAll ? averageData[obj.Zones] : session.GetAverageStacksCount(obj.Zones)
            averageTime := Round(averageCount[1] / 1000, 2)
            stacks := obj.Stacks
            averageStacks := Round(averageCount[2])
            count := averageCount[3]
            rate := Round(stacks / time)
            averageRate := Round(averageStacks / averageTime)
            jumpEqRate := Round((this.GetJumpsFromStacks(stacks) / time), 2)
            averageJumpEqRate := Round((this.GetJumpsFromStacks(averageStacks) / averageTime), 2)
            if (isAll)
            {
                runID := items[A_Index][2]
                LV_Add(, runID, area, next, time, averageTime, stacks, averageStacks, count, rate, averageRate, jumpEqRate, averageJumpEqRate, gameSpeedRounded)
            }
            else
                LV_Add(, area, next, time, averageTime, stacks, averageStacks, count, rate, averageRate, jumpEqRate, averageJumpEqRate, gameSpeedRounded)
        }
        ; Resize columns
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
    }

    ; Compute the number of Briv jumps from a number stacks (Metalborn active).
    ; Params: stacks:int - Number of Briv Haste stacks.
    ; Returns: - jumps:int - Maximum number of jumps.
    GetJumpsFromStacks(stacks)
    {
        while (stacks >= 50)
        {
            ++jumps
            stacks := Round(stacks * 0.968)
        }
        return jumps
    }
}