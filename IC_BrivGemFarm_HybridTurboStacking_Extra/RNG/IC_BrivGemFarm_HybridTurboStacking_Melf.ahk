#include %A_LineFile%\..\..\..\..\SharedFunctions\CSharpRNG.ahk

Class IC_BrivGemFarm_HybridTurboStacking_Melf
{
    static MAX_ZONE := 2001

    GetCurrentEffectIndex()
    {
        rng := new CSharpRNG(IC_BrivGemFarm_HybridTurboStacking_Functions.ReadResets() * 10)
		num := Ceil(g_SF.Memory.ReadCurrentZone() / 50)
	    Loop, % num
		    result := rng.NextRange(0, 3)
	    return result
    }

    IsCurrentEffectSpawnMore()
    {
        return this.GetCurrentEffectIndex() == 0
    }

    GetFirstSpawnMoreEffectRange(reset := "", min := 1, max := 2050)
    {
        if (reset == "")
            reset := IC_BrivGemFarm_HybridTurboStacking_Functions.ReadResets()
        if (reset == "")
            return 0
        rng := new CSharpRNG(reset * 10)
        firstZoneInRange := 50 * Floor(min / 50) + 1
        k := 0
        while (true)
        {
            firstZone:= k++ * 50 + 1
            if (firstZone > max)
                break
            lastZone := firstZone + 49
		    result := rng.NextRange(0, 3)
		    if (result == 0 && firstZoneInRange <= firstZone)
		        return [firstZone, lastZone]
		}
		return 0
    }

    GetAllEffects(reset := "")
    {
        if (reset == "")
            reset := IC_BrivGemFarm_HybridTurboStacking_Functions.ReadResets()
        if (reset == "")
            return ""
        result := []
        rng := new CSharpRNG(reset * 10)
        num := Ceil(this.MAX_ZONE / 50)
        Loop, % num
		    result[A_Index] := rng.NextRange(0, 3)
		return result
    }
}