; Object that holds stats from zone progress.
Class IC_AreaTiming_TimeObject
{
    Zones := 0
    AreaStartTimeStamp := 0
    AreaCompleteTimeStamp := 0
    AreaTransitionedTimeStamp := 0
    GameSpeed := 0

    __New(startZone)
    {
        this.AreaStartTimeStamp := this.GetCurrentMSecTime()
        this.Zones := (startZone << 32)
    }

    StartZone
    {
        get
        {
            return this.Zones >>> 32
        }
    }

    EndZone
    {
        get
        {
            return this.Zones & 0xFFFFFFFF
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
            return (this.Mod50StartZone << 32) + this.Mod50EndZone
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

    SetGameSpeed(gameSpeed)
    {
        this.GameSpeed := gameSpeed
    }

    SetAreaComplete(gameSpeed := "")
    {
        this.AreaCompleteTimeStamp := this.GetCurrentMSecTime()
        this.SetGameSpeed(gameSpeed)
        return this.AreaCompleteTimeStamp
    }

    SetAreaTransitioned(endZone)
    {
        this.AreaTransitionedTimeStamp := this.GetCurrentMSecTime()
        this.Zones += endZone
        return this.AreaTransitionedTimeStamp
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
Class IC_AreaTiming_StacksTimeObject extends IC_AreaTiming_TimeObject
{
    Stacks := 0

    SetAreaTransitioned(endZone, stacks)
    {
        base.SetAreaTransitioned(endZone)
        this.Stacks := stacks
        return this.AreaCompleteTimeStamp
    }

    UpdateStartZone(startZone)
    {
        this.Zones := (startZone << 32) + this.EndZone
    }
}