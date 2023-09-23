#SingleInstance Ignore
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
ListLines Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1

#include %A_LineFile%\..\..\..\AddOns\IC_BrivGemFarm_Performance\IC_BrivGemFarm_Functions.ahk
#include %A_LineFile%\..\..\..\ServerCalls\IC_ServerCalls_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\IC_SharedFunctions_Class.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_RunCollection.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_SharedData.ahk

global g_SF := new IC_BrivSharedFunctions_Class ; includes MemoryFunctions in g_SF.Memory
global g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\..\Settings.json" )
global g_AT_SharedData := new IC_AreaTiming_SharedData
global g_AreaTimingWorker := new IC_AreaTiming_TimerScript

ObjRegisterActive(g_AT_SharedData, A_Args[1])
OnExit(ObjBindMethod(g_AreaTimingWorker, "ComObjectRevoke"))

g_AT_SharedData.Start()

Class IC_AreaTiming_TimerScript
{
    Running := false

    ; Main loop for this addon.
    Loop()
    {
        needUpdate := this.UpdateProcessReader(true)
        this.UpdateAreaTimingStatTimers(true)
        while (this.Running)
        {
            ; Only update when the game is open.
            needUpdate := this.UpdateProcessReader(needUpdate)
            this.UpdateAreaTimingStatTimers()
            Sleep, 1
        }
    }

    ; After the game has been closed, wait for the process to be launched again
    ; before updating the memory reader.
    ; Params: needUpdate:bool - If true, update g_SF.Memory.OpenProcessReader()
    ; when the game's process exists.
    UpdateProcessReader(needUpdate)
    {
        if (WinExist("ahk_exe " . g_userSettings[ "ExeName"]))
        {
            if (needUpdate)
            {
                g_SF.Memory.OpenProcessReader()
                needUpdate := false
            }
        }
        else
            needUpdate := true
        return needUpdate
    }

    ; Based on IC_BrivGemFarm_Stats_Functions.ahk\UpdateStatTimers()
    UpdateAreaTimingStatTimers(resetStats := false)
    {
        static mem := g_SF.Memory
        ; Last recorded area
        static lastZone := 1
        ; Last recorded reset count
        static lastResetCount := 0
        ; True when first recording area progress
        static areaClearTrigger := false
        ; Skips first record (skips stacks recording if launched during restart)
        static skipFirstValue := true
        ; Current recorded run
        static currentRun := ""
        ; Current recorded area progress
        static timeObj := ""
        ; Briv stacks value before stacking
        static stacksBefore := 0
        ; True during stacking
        static stacking := false
        ; Current recorded stacking progress
        static stacksTimeObj := ""
        ; True when first recording game speed during stacking
        static stackingGameSpeedTrigger := false
        ; True when the game is closed during stacking
        static offlineTrigger := false
        ; True after updating the startZone druitn offlien stacking
        static offlineStartZoneUpdate := false
        ; Saved formations
        static formationQ := ""
        static formationW := ""
        static formationE := ""

        Critical, On
        currentZone := g_SF.Memory.ReadCurrentZone()
        highestZone := g_SF.Memory.ReadHighestZone()
        ; Area cleared. CurrentZone = -1 after offline sim is completed.
        areaProgress := highestZone > currentZone || highestZone > lastZone
        if (!areaClearTrigger && areaProgress && currentZone != -1)
        {
            gameSpeed := this.ReadUncappedTimeScaleMultiplier()
            timeObj.SetAreaComplete(gameSpeed)
            areaClearTrigger := true
        }
        ; Manual reset
        if (resetStats)
        {
            stacking := stackingGameSpeedTrigger := false
            offlineTrigger := offlineStartZoneUpdate := false
            skipFirstValue := true
            areaClearTrigger := false
            currentRun := ""
            timeObj := ""
            lastZone := currentZone
            lastResetCount := g_SF.Memory.ReadResetsCount()
            return
        }
        areaActive := g_SF.Memory.ReadAreaActive()
        offlineDone := g_SF.Memory.ReadOfflineDone()
        cond := areaActive && offlineDone
        cond2 := g_SF.Memory.ReadResetsCount() > lastResetCount
        cond3 := g_SF.Memory.ReadResetsCount() == 0 && lastResetCount != 0
        if (cond && (cond2 || cond3) && areaClearTrigger)
        {
            ; Modron reset
            if (g_SF.Memory.ReadResetsCount() > lastResetCount)
            {
                timeObj.SetAreaTransitioned(currentZone)
                currentRun.AddItem(new IC_AreaTiming_TimeObject(timeObj))
            }
            stacking := stackingGameSpeedTrigger := false
            offlineTrigger := offlineStartZoneUpdate := false
            skipFirstValue := false
            areaClearTrigger := false
            ; Mark previous run as finished
            currentRun.EndRun()
            currentRun := g_AT_SharedData.CurrentSession.NewRun()
            timeObj := new IC_AreaTiming_TimeObjectSimple(currentZone)
            lastResetCount := g_SF.Memory.ReadResetsCount()
            lastZone := 1
            ; Update formations
            formationQ := g_SF.Memory.GetFormationByFavorite(1)
            formationW := g_SF.Memory.GetFormationByFavorite(2)
            formationE := g_SF.Memory.GetFormationByFavorite(3)
            return
        }
        ; Resetting/restarting
        if !g_SF.Memory.ReadUserIsInited()
        {
            ; do not update lastZone if game is loading
        }
        ; Zone reset
        else if ((currentZone > lastZone) AND (currentZone >= 2))
        {
            ; Wait for screen transition
            while (g_SF.Memory.ReadTransitioning() > 0)
            {
                Sleep, 1
            }
            ; Skip first value
            if (!skipFirstValue && timeObj.StartZone != currentZone)
            {
                timeObj.SetAreaTransitioned(currentZone)
                currentRun.AddItem(new IC_AreaTiming_TimeObject(timeObj))
            }
            timeObj := new IC_AreaTiming_TimeObjectSimple(currentZone)
            lastZone := currentZone
            areaClearTrigger := false
        }
        ; After reset. +1 buffer for time to read value
        else if ((highestZone < 3) && (lastZone >= 3) && (currentZone > 0) )
        {
            lastZone := currentZone
        }
        ; Stacking
        isQFormation := g_SF.IsCurrentFormation(formationQ)
        isWFormation := g_SF.IsCurrentFormation(formationW)
        isEFormation := g_SF.IsCurrentFormation(formationE)
        if (!stacking && cond && isWFormation && currentZone != 1 && !skipFirstValue)
        {
            if (!g_SF.Memory.ReadTransitioning())
            {
                stacking := true
                stacksBefore := g_SF.Memory.ReadSBStacks()
                currentZone := g_SF.Memory.ReadCurrentZone()
                stacksTimeObj := new IC_AreaTiming_StacksTimeObjectsimpleObj(currentZone)
                stacksTimeObj.SetAreaComplete()
            }
        }
        else if (stacking)
        {
            if (!offlineTrigger && !areaActive)
            {
                offlineTrigger := true
                stackingGameSpeedTrigger := false
            }
            if (!areaActive)
            {
                Critical, Off
                return
            }
            ; Record game speed during stacking
            if (isWFormation && !stackingGameSpeedTrigger || offlineTrigger && !offlineDone)
            {
                ; Update startZone if offline stacking
                if (!offlineStartZoneUpdate && offlineTrigger && !offlineDone)
                {
                    if (currentZone > stacksTimeObj.StartZone)
                    {
                        stacksTimeObj.UpdateStartZone(currentZone)
                        offlineStartZoneUpdate := true
                    }
                }
                ; Update game speed if offline stacking
                if (g_SF.Memory.ReadSBStacks() > stacksBefore || offlineTrigger && !offlineDone)
                {
                    gameSpeed := this.ReadUncappedTimeScaleMultiplier()
                    if (gameSpeed != "" && gameSpeed != 0)
                    {
                        stacksTimeObj.SetGameSpeed(gameSpeed)
                        stackingGameSpeedTrigger := true
                    }
                }
            }
            else if (offlineDone && (isQFormation || isEFormation))
            {
                stacking := stackingGameSpeedTrigger := false
                offlineTrigger := offlineStartZoneUpdate := false
                stacksAfter := g_SF.Memory.ReadSBStacks()
                dStacks := stacksAfter - stacksBefore
                currentZone := g_SF.Memory.ReadCurrentZone()
                stacksTimeObj.SetAreaTransitioned(currentZone, dStacks)
                currentRun.AddStacksItem(new IC_AreaTiming_StacksTimeObject(stacksTimeObj))
                stacksTimeObj := ""
            }
        }
        Critical, Off
    }

    ; Read uncapped timescale multiplier without rounding errors.
    ; The default script rounds the timescale down to 2 decimals at every step.
    ReadUncappedTimeScaleMultiplier()
    {
        multiplierTotal := 1
        size := g_SF.Memory.ReadTimeScaleMultipliersCount()
        if(size <= 0 OR size > 100)
            return ""
        timeScales := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].timeScales[0]
        Loop, % size
        {
            value := timeScales.Multipliers["value", A_Index - 1].read("Float")
            multiplierTotal *= Max(1.0, value)
        }
        return multiplierTotal + 0
    }

    ; Unregister the shared data object on exit.
    ComObjectRevoke()
    {
        ObjRegisterActive(g_AT_SharedData, "")
        ExitApp
    }
}