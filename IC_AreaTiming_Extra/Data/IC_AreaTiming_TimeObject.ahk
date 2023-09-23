; Object that holds stats from zone progress.
; Uses a buffer to keep track of data.
Class IC_AreaTiming_TimeObject
{
    ; Struct - 28 bytes
    ; ?? - 2 bytes
    ; Zones:UInt - 4 bytes (Max area = 65535)
    ; AreaStartTimeStamp:UInt+UShort - 6 bytes
    ; AreaCompleteTimeStamp:UInt+UShort - 6 bytes
    ; AreaTransitionedTimeStamp:UInt+UShort - 6 bytes
    ; GameSpeed:Float - 4 bytes
    Data := ""

    __New(ByRef simpleObj)
    {
        timeStamp := simpleObj.AreaStartTimeStamp
        VarSetCapacity(buffer%timeStamp%, 28, 0)
        this.ConvertSimpleObjToStruct(simpleObj, buffer%timeStamp%)
        this.Data := &buffer%timeStamp%
    }

    ConvertSimpleObjToStruct(ByRef simpleObj, ByRef buffer)
    {
        NumPut(simpleObj.EndZone, buffer, 2, "UShort")
        NumPut(simpleObj.StartZone, buffer, 4, "UShort")
        timestamp := simpleObj.GetSplittedTimeStamp(simpleObj.AreaStartTimeStamp)
        NumPut(timestamp[1], buffer, 6, "UInt")
        NumPut(timestamp[2], buffer, 10, "UShort")
        timestamp := simpleObj.GetSplittedTimeStamp(simpleObj.AreaCompleteTimeStamp)
        NumPut(timestamp[1], buffer, 12, "UInt")
        NumPut(timestamp[2], buffer, 16, "UShort")
        timestamp := simpleObj.GetSplittedTimeStamp(simpleObj.AreaTransitionedTimeStamp)
        NumPut(timestamp[1], buffer, 18, "UInt")
        NumPut(timestamp[2], buffer, 22, "UShort")
        NumPut(simpleObj.GameSpeed, buffer, 24, "Float")
    }

    StartZone
    {
        get
        {
            return NumGet(this.Data, 4, "UShort")
        }
    }

    EndZone
    {
        get
        {
            return NumGet(this.Data, 2, "UShort")
        }
    }

    Zones
    {
        get
        {
            return NumGet(this.Data, 2, "UInt")
        }
    }

    Mod50StartZone
    {
        get
        {
            mod50Start := Mod(this.StartZone, 50)
            mod50Start := mod50Start ? mod50Start : 50
            return mod50Start
        }
    }

    Mod50EndZone
    {
        get
        {
            mod50End := Mod(this.EndZone, 50)
            mod50End := mod50End ? mod50End : 50
            return mod50End
        }
    }

    Mod50Zones
    {
        get
        {
            return (this.Mod50StartZone << 16) + this.Mod50EndZone
        }
    }

    AreaStartTimeStamp
    {
        get
        {
            return NumGet(this.Data, 6, "UInt") * 1000 + NumGet(this.Data, 10, "UShort")
        }
    }

    AreaCompleteTimeStamp
    {
        get
        {
            return NumGet(this.Data, 12, "UInt") * 1000 + NumGet(this.Data, 16, "UShort")
        }
    }

    AreaTransitionedTimeStamp
    {
        get
        {
            return NumGet(this.Data, 18, "UInt") * 1000 + NumGet(this.Data, 22, "UShort")
        }
    }

    AreaTime
    {
        get
        {
            return this.AreaCompleteTimeStamp - this.AreaStartTimeStamp
        }
    }

    TransitionTime
    {
        get
        {
            return this.AreaTransitionedTimeStamp - this.AreaCompleteTimeStamp
        }
    }

    TotalTime
    {
        get
        {
            return this.AreaTransitionedTimeStamp - this.AreaStartTimeStamp
        }
    }

    GameSpeed
    {
        get
        {
            return NumGet(this.Data, 24, "Float")
        }
    }

    GetCurrentMSecTime()
    {
        time := A_Now
        mSec := A_MSec + 0
        time -= 1970, s
        return time * 1000 + mSec
    }
}

; Object that holds stats from zone progress during stacking.
; Uses a buffer to keep track of data.
Class IC_AreaTiming_StacksTimeObject extends IC_AreaTiming_TimeObject
{
    ; Struct - 32 bytes
    ; ?? - 2 bytes
    ; Zones:UInt - 4 bytes (Max area = 65535)
    ; AreaStartTimeStamp:UInt+UShort - 6 bytes
    ; AreaCompleteTimeStamp:UInt+UShort - 6 bytes
    ; AreaTransitionedTimeStamp:UInt+UShort - 6 bytes
    ; GameSpeed:Float - 4 bytes
    ; Stacks:UInt - 4 bytes
    ; Data := ""

    __New(ByRef simpleObj)
    {
        timeStamp := simpleObj.AreaStartTimeStamp
        VarSetCapacity(buffer%timeStamp%, 32, 0)
        this.ConvertSimpleObjToStruct(simpleObj, buffer%timeStamp%)
        this.Data := &buffer%timeStamp%
    }

    ConvertSimpleObjToStruct(ByRef simpleObj, ByRef buffer)
    {
        NumPut(simpleObj.EndZone, buffer, 2, "UShort")
        NumPut(simpleObj.StartZone, buffer, 4, "UShort")
        timestamp := simpleObj.GetSplittedTimeStamp(simpleObj.AreaStartTimeStamp)
        NumPut(timestamp[1], buffer, 6, "UInt")
        NumPut(timestamp[2], buffer, 10, "UShort")
        timestamp := simpleObj.GetSplittedTimeStamp(simpleObj.AreaCompleteTimeStamp)
        NumPut(timestamp[1], buffer, 12, "UInt")
        NumPut(timestamp[2], buffer, 16, "UShort")
        timestamp := simpleObj.GetSplittedTimeStamp(simpleObj.AreaTransitionedTimeStamp)
        NumPut(timestamp[1], buffer, 18, "UInt")
        NumPut(timestamp[2], buffer, 22, "UShort")
        NumPut(simpleObj.GameSpeed, buffer, 24, "Float")
        NumPut(simpleObj.Stacks, buffer, 28, "UInt")
    }

    Stacks
    {
        get
        {
            return NumGet(this.Data, 28, "UInt")
        }
    }
}