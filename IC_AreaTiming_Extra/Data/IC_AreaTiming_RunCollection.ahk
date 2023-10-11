#include %A_LineFile%\..\IC_AreaTiming_SingleRun.ahk

Class IC_AreaTiming_RunCollection
{
    ID := 0
    StartTime := 0
    Runs := []
    CurrentRun := ""
    ; Higher that that and read/write operations become much slower.
    MaxRuns := 4000

    __New(id)
    {
        this.StartTime := IC_AreaTiming_TimeObject.GetCurrentMSecTime()
        this.ID := id
    }

    NewRun()
    {
        runCount := this.Runs.Length()
        if (runCount >= this.MaxRuns)
            return g_AT_SharedData.NewSession().NewRun()
        run := new IC_AreaTiming_SingleRun(runCount + 1, this.ID)
        this.CurrentRun := run
        this.Runs.Push(run)
        return run
    }

    ; Dispose of all runs.
    Clear()
    {
        this.CurrentRun := ""
        items := this.Runs
        Loop, % items.Length()
        {
            items[A_Index].Clear()
            items[A_Index] := ""
        }
        VarSetCapacity(items, 0)
    }

    FindItem(run, key)
    {
        items := run.Items
        low := 1
        high := items.Length()
        while (low <= high && key >= run.GetItemZones(low) && key <= run.GetItemZones(high))
        {
            pos := low + Floor(((key - run.GetItemZones(low)) * (high - low)) / (run.GetItemZones(high) - run.GetItemZones(low)))
            if (run.GetItemZones(pos) == key)
                return items[pos]
            if (run.GetItemZones(pos) > key)
                high := pos - 1
            else
                low := pos + 1
        }
        return ""
    }

    ; Get all unique IC_AreaTiming_TimeObject.Zones keys from all runs.
    ; Returns: - arary:keys - All keys (IC_AreaTiming_TimeObject.Zones).
    GetAllItemKeys()
    {
        keys := []
        keysObj := {}
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            Loop, % run.Items.Length()
            {
                key := run.GetItemZones(A_Index)
                if (!keysObj.HasKey(key))
                    keysObj[key] := ""
            }
        }
        ; Return sorted keys
        for k, v in keysObj
            keys.Push(k)
        VarSetCapacity(keysObj, 0)
        return keys
    }

    ; Get all unique IC_AreaTiming_StacksTimeObject.Zones keys from all runs.
    ; Returns: - arary:keys - All keys (IC_AreaTiming_StacksTimeObject.Zones).
    GetAllStackItemKeys()
    {
        keys := []
        keysObj := {}
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            Loop, % run.StackItems.Length()
            {
                key := run.GetStackItemZones(A_Index)
                if (!keysObj.HasKey(key))
                    keysObj[key] := ""
            }
        }
        ; Return sorted keys
        for k, v in keysObj
            keys.Push(k)
        VarSetCapacity(keysObj, 0)
        return keys
    }

    GetAverageCount(key)
    {
        count := 0
        sumAreaTime := 0
        sumTransitionTime := 0
        sumTime := 0
        sumTimeFromStart := 0
        sumSpeed := 0
        runs := this.Runs
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            item := this.FindItem(run, key)
            if (item)
            {
                ++count
                sumAreaTime += this.GetItemAreaTime(item)
                sumTransitionTime += this.GetItemTransitionTime(item)
                sumTime += this.GetItemTotalTime(item)
                ; Prevent overflow
                runTime := this.GetItemAreaTransitionedTimeStamp(item) - run.StartTime
                sumTimeFromStart += runTime
                sumSpeed += this.GetItemGameSpeed(item)
            }
        }
        ; Return value
        arr := [count]
        arr.Push(sumAreaTime / count)
        arr.Push(sumTransitionTime / count)
        arr.Push(sumTime / count)
        arr.Push(sumTimeFromStart / count)
        arr.Push(sumSpeed / count)
        return arr
    }

    ; Get average stats from all runs.
    ; Returns: - arr: allAverage - All object data.
    ;                 keys - All allAverage keys (IC_AreaTiming_TimeObject.Zones)
    GetAllAverageCount()
    {
        allAverage := []
        keys := []
        keysObj := {}
        ; Loop all runs
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            runID := run.ID
            ; Loop all items
            Loop, % run.Items.Length()
            {
                key := run.GetItemZones(A_Index)
                ; New key
                if (!keysObj.HasKey(key))
                {
                    keysObj[key] := ""
                    keys.Push(key)
                    allAverage.Push(this.GetAverageCount(key))
                }
            }
        }
        VarSetCapacity(keysObj, 0)
        return [allAverage, keys]
    }

    ; Get average mod50 stats from all runs.
    ; Params: key:int - IC_AreaTiming_TimeObject.Mod50Zones.
    ;         runs:array - List of runs, default to all runs from this session.
    ; Returns: - arr:array - All mod50 average data.
    GetAverageMod50Count(key, runs := "")
    {
        count := 0
        sumAreaTime := 0
        sumTransitionTime := 0
        sumTime := 0
        runs := runs == "" ? this.Runs : runs
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; Loop all items
            Loop, % run.Items.Length()
            {
                if (run.GetItemMod50Zones(A_Index) == key)
                {
                    ++count
                    sumAreaTime += run.GetItemAreaTime(A_Index)
                    sumTransitionTime += run.GetItemTransitionTime(A_Index)
                    sumTime += run.GetItemTotalTime(A_Index)
                }
            }
        }
        ; Return value
        arr := [count]
        arr.Push(sumAreaTime / count)
        arr.Push(sumTransitionTime / count)
        arr.Push(sumTime / count)
        return arr
    }

    ; Get average mod50 stats from all runs.
    ; Exclude z1, stacking area and reset from result.
    ; Params: key:int - IC_AreaTiming_TimeObject.Mod50Zones.
    ;         runs:array - List of runs, default to all runs from this session.
    ; Returns: - arr:array - All mod50 average data.
    GetAverageMod50CountEx(key, runs := "")
    {
        count := 0
        sumAreaTime := 0
        sumTransitionTime := 0
        sumTime := 0
        runs := runs == "" ? this.Runs : runs
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; Loop all items
            Loop, % run.Items.Length()
            {
                itemStartZone := run.GetItemStartZone(A_Index)
                if (itemStartZone != 1 && run.GetItemEndZone(A_Index) != 1 && run.GetItemMod50Zones(A_Index) == key)
                {
                    ; Exclude stack areas
                    stackItems := run.StackItems
                    Loop, % stackItems.Length()
                    {
                        if (run.GetStackItemStartZone(A_Index) == itemStartZone)
                            continue 2
                    }
                    ++count
                    sumAreaTime += run.GetItemAreaTime(A_Index)
                    sumTransitionTime += run.GetItemTransitionTime(A_Index)
                    sumTime += run.GetItemTotalTime(A_Index)
                }
            }
        }
        ; Return value
        arr := [count]
        arr.Push(sumAreaTime / count)
        arr.Push(sumTransitionTime / count)
        arr.Push(sumTime / count)
        return arr
    }

    GetAverageStacksCount(key)
    {
        count := 0
        sumTime := 0
        sumStacks := 0
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; There can be multiple items for each start/end zones pair.
            Loop, % run.StackItems.Length()
            {
                if (run.GetStackItemZones(A_Index) == key)
                {
                    ++count
                    sumTime += run.GetStackItemTotalTime(A_Index)
                    sumStacks += run.GetStackItemStacks(A_Index)
                }
            }
        }
        return [sumTime / count, sumStacks / count, count]
    }

    ; Get average stack stats from all runs.
    ; Returns: - arr: allItems - All IC_AreaTiming_StacksTimeObject objects.
    ;                 allAverageStacks - All stack object data.
    ;                 keys - All allAverageStacks keys (IC_AreaTiming_StacksTimeObject.Zones)
    GetAllAverageStacks()
    {
        allItems := []
        allAverageStacks := []
        keys := []
        keysObj := {}
        ; Loop all runs
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            runID := run.ID
            ; Loop all stack items
            items := run.StackItems
            Loop, % items.Length()
            {
                key := run.GetStackItemZones(A_Index)
                ; New key
                if (!keysObj.HasKey(key))
                {
                    keysObj[key] := ""
                    keys.Push(key)
                    allAverageStacks.Push(this.GetAverageStacksCount(key))
                }
                allItems.Push([items[A_Index], runID])
            }
        }
        VarSetCapacity(keysObj, 0)
        return [allItems, allAverageStacks, keys]
    }

    GetItemStartZone(ptr)
    {
        return NumGet(ptr+0, 4, "UShort")
    }

    GetItemEndZone(ptr)
    {
        return NumGet(ptr+0, 2, "UShort")
    }

    GetItemZones(ptr)
    {
        return NumGet(ptr+0, 2, "UInt")
    }

    GetItemMod50StartZone(ptr)
    {
        mod50Start := Mod(this.GetItemStartZone(ptr), 50)
        mod50Start := mod50Start ? mod50Start : 50
        return mod50Start
    }

    GetItemMod50EndZone(ptr)
    {
        mod50End := Mod(this.GetItemEndZone(ptr), 50)
        mod50End := mod50End ? mod50End : 50
        return mod50End
    }

    GetItemMod50Zones(ptr)
    {
        return (this.GetItemMod50StartZone(ptr) << 16) + this.GetItemMod50EndZone(ptr)
    }

    GetItemAreaStartTimeStamp(ptr)
    {
        return NumGet(ptr+0, 6, "UInt") * 1000 + NumGet(ptr+0, 10, "UShort")
    }

    GetItemAreaCompleteTimeStamp(ptr)
    {
        return NumGet(ptr+0, 12, "UInt") * 1000 + NumGet(ptr+0, 16, "UShort")
    }

    GetItemAreaTransitionedTimeStamp(ptr)
    {
        return NumGet(ptr+0, 18, "UInt") * 1000 + NumGet(ptr+0, 22, "UShort")
    }

    GetItemAreaTime(ptr)
    {
        return this.GetItemAreaCompleteTimeStamp(ptr) - this.GetItemAreaStartTimeStamp(ptr)
    }

    GetItemTransitionTime(ptr)
    {
        return this.GetItemAreaTransitionedTimeStamp(ptr) - this.GetItemAreaCompleteTimeStamp(ptr)
    }

    GetItemTotalTime(ptr)
    {
        return this.GetItemAreaTransitionedTimeStamp(ptr) - this.GetItemAreaStartTimeStamp(ptr)
    }

    GetItemGameSpeed(ptr)
    {
        return NumGet(ptr+0, 24, "Float")
    }

    GetStackItemStartZone(ptr)
    {
        return NumGet(ptr+0, 4, "UShort")
    }

    GetStackItemEndZone(ptr)
    {
        return NumGet(ptr+0, 2, "UShort")
    }

    GetStackItemZones(ptr)
    {
        return NumGet(ptr+0, 2, "UInt")
    }

    GetStackItemMod50StartZone(ptr)
    {
        mod50Start := Mod(this.GetStackItemStartZone(ptr), 50)
        mod50Start := mod50Start ? mod50Start : 50
        return mod50Start
    }

    GetStackItemMod50EndZone(ptr)
    {
        mod50End := Mod(this.GetStackItemEndZone(ptr), 50)
        mod50End := mod50End ? mod50End : 50
        return mod50End
    }

    GetStackItemMod50Zones(ptr)
    {
        return (this.GetStackItemMod50StartZone(ptr) << 16) + this.GetStackItemMod50EndZone(ptr)
    }

    GetStackItemAreaStartTimeStamp(ptr)
    {
        return NumGet(ptr+0, 6, "UInt") * 1000 + NumGet(ptr+0, 10, "UShort")
    }

    GetStackItemAreaCompleteTimeStamp(ptr)
    {
        return NumGet(ptr+0, 12, "UInt") * 1000 + NumGet(ptr+0, 16, "UShort")
    }

    GetStackItemAreaTransitionedTimeStamp(ptr)
    {
        return NumGet(ptr+0, 18, "UInt") * 1000 + NumGet(ptr+0, 22, "UShort")
    }

    GetStackItemAreaTime(ptr)
    {
        return this.GetStackItemAreaCompleteTimeStamp(ptr) - this.GetStackItemAreaStartTimeStamp(ptr)
    }

    GetStackItemTransitionTime(ptr)
    {
        return this.GetStackItemAreaTransitionedTimeStamp(ptr) - this.GetStackItemAreaCompleteTimeStamp(ptr)
    }

    GetStackItemTotalTime(ptr)
    {
        return this.GetStackItemAreaTransitionedTimeStamp(ptr) - this.GetStackItemAreaStartTimeStamp(ptr)
    }

    GetStackItemGameSpeed(ptr)
    {
        return NumGet(ptr+0, 24, "Float")
    }

    GetStackItemStacks(ptr)
    {
        return NumGet(ptr+0, 28, "UInt")
    }
}