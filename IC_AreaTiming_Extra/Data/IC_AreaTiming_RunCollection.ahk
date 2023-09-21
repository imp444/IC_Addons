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

    FindItem(items, key)
    {
        low := 1
        high := items.Length()
        while (low <= high && key >= items[low].Zones && key <= items[high].Zones)
        {
            pos := low + Floor(((key - items[low].Zones) * (high - low)) / (items[high].Zones - items[low].Zones))
            if (items[pos].Zones == key)
                return items[pos]
            if (items[pos].Zones > key)
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
            items := run.Items
            Loop, % items.Length()
            {
                key := items[A_Index].Zones
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
            items := run.StackItems
            Loop, % items.Length()
            {
                key := items[A_Index].Zones
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
            items := run.Items
            item := this.FindItem(items, key)
            if (item)
            {
                ++count
                sumAreaTime += item.AreaTime
                sumTransitionTime += item.TransitionTime
                sumTime += item.TotalTime
                ; Prevent overflow
                runTime := item.AreaTransitionedTimeStamp - run.StartTime
                sumTimeFromStart += runTime
                sumSpeed += item.GameSpeed
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
            items := run.Items
            Loop, % items.Length()
            {
                item := items[A_Index]
                key := item.Zones
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
    ; Returns: - arr:array - All mod50 average data.
    GetAverageMod50Count(key)
    {
        count := 0
        sumAreaTime := 0
        sumTransitionTime := 0
        sumTime := 0
        runs := this.Runs
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; Loop all items
            items := run.Items
            Loop, % items.Length()
            {
                item := items[A_Index]
                if (item.Mod50Zones == key)
                {
                    ++count
                    sumAreaTime += item.AreaTime
                    sumTransitionTime += item.TransitionTime
                    sumTime += item.TotalTime
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
    ; Returns: - arr:array - All mod50 average data.
    GetAverageMod50CountEx(key)
    {
        count := 0
        sumAreaTime := 0
        sumTransitionTime := 0
        sumTime := 0
        runs := this.Runs
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; Loop all items
            items := run.Items
            Loop, % items.Length()
            {
                item := items[A_Index]
                itemStartZone := item.StartZone
                if (itemStartZone != 1 && item.EndZone != 1 && item.Mod50Zones == key)
                {
                    ; Exclude stack areas
                    stackItems := run.StackItems
                    Loop, % stackItems.Length()
                    {
                        if (stackItems[A_Index].StartZone == itemStartZone)
                            continue 2
                    }
                    ++count
                    sumAreaTime += item.AreaTime
                    sumTransitionTime += item.TransitionTime
                    sumTime += item.TotalTime
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
            items := run.StackItems
            ; There can be multiple items for each start/end zones pair.
            Loop, % items.Length()
            {
                item := items[A_Index]
                if (item.Zones == key)
                {
                    ++count
                    sumTime += item.TotalTime
                    sumStacks += item.Stacks
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
                item := items[A_Index]
                key := item.Zones
                ; New key
                if (!keysObj.HasKey(key))
                {
                    keysObj[key] := ""
                    keys.Push(key)
                    allAverageStacks.Push(this.GetAverageStacksCount(key))
                }
                allItems.Push([item, runID])
            }
        }
        VarSetCapacity(keysObj, 0)
        return [allItems, allAverageStacks, keys]
    }
}