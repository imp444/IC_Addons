#include %A_LineFile%\..\IC_AreaTiming_TimeObject.ahk

Class IC_AreaTiming_SingleRun
{
    ID := 0
    SessionID := 0
    Items := []
    StackItems := []
    StartTime := 0
    CurrentZone := 0
    Ended := false

    ; Create a new object that contains data for a single run.
    ; Parameters: - obj:IC_AreaTiming_TimeObject - Time object that contains
    ;               timestamps for area start, zone clear and transition end.
    ;               First record.
    __New(id, session)
    {
        this.StartTime := IC_AreaTiming_TimeObject.GetCurrentMSecTime()
        this.ID := ID
        this.SessionID := session.ID
    }

    ; Add a time object to the current run.
    ; Parameters: - obj:IC_AreaTiming_TimeObject - Time object that contains
    ;               timestamps for area start, zone clear and transition end.
    AddItem(obj)
    {
        this.Items.Push(obj)
        this.CurrentZone := obj.EndZone ? obj.EndZone : obj.StartZone
    }

    AddStacksItem(obj)
    {
        this.StackItems.Push(obj)
    }

    ; Dispose of all timeObjects.
    Clear()
    {
        items := this.Items
        Loop, % items.Length()
            items[A_Index] := ""
        VarSetCapacity(items, 0)
        items := this.StackItems
        Loop, % items.Length()
            items[A_Index] := ""
        VarSetCapacity(items, 0)
    }

    ; Mark this run as finished.
    EndRun()
    {
        this.Ended := true
    }
}