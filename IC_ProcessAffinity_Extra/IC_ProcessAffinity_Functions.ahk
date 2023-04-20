; Functions that set affinities to processes
class IC_ProcessAffinity_Functions
{
    ; Adds IC_ProcessAffinity_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_ProcessAffinity_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    /*  SetProcessAffinity - A function to sets the affinity of a process

        Parameters:
        PID - PID of the target process
        inverse - Inverse affinity, if e.g. core 0 is selected for the game, core 0 is unselected for the scripts
        Returns:
    */
    SetProcessAffinity(PID := 0, inverse := 0)
    {
        if (PID == 0)
            return
        affinity := this.AffinitySettings()
        if (affinity == 0)
            return
        affinity := inverse ? this.InverseAffinity(affinity) : affinity
        ProcessHandle := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", False, "UInt", PID)
        size := A_Is64bitOS ? "Int64" : "UInt"
        DllCall("SetProcessAffinityMask", "UInt", ProcessHandle, size, affinity)
        DllCall("CloseHandle", "UInt", ProcessHandle)
    }

    ; Returns the inverse affinity depending on the number of processor cores
    InverseAffinity(affinity := 0)
    {
        EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
        invMask := ProcessorCount == 64 ? -1 : -1 >>> (64 - ProcessorCount)
        invAffinity := affinity ^ invMask
        invAffinity := !invAffinity ? affinity : invAffinity ; If all cores are selected for IdleDragons.exe, identical mask
        return invAffinity
    }

    ; Loads settings from the addon's setting.json file.
    AffinitySettings()
    {
        settings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\ProcessAffinitySettings.json")
        if (!IsObject(settings))
            return 0
        coreMask := settings["ProcessAffinityMask"]
        if coreMask == "" or coreMask == 0)
            return 0
        return coreMask
    }
}

; Overrides IC_BrivSharedFunctions_Class, check for compatibility
class IC_ProcessAffinity_SharedFunctions_Class extends IC_BrivSharedFunctions_Class
{
    ; Set affinity after restart
    OpenProcessAndSetPID(timeoutLeft := 32000)
    {
        base.OpenProcessAndSetPID(timeoutLeft)
        IC_ProcessAffinity_Functions.SetProcessAffinity(this.PID) ; IdleDragons.exe
        ; Keep the script's affinity in line with the game's affinity after ICScriptHub is closed
        IC_ProcessAffinity_Functions.SetProcessAffinity(DllCall("GetCurrentProcessId"), 1) ; IC_BrivGemFarm_Run.ahk
    }

    ; Set affinity after clicking "Start Gem Farm"
    VerifyAdventureLoaded()
    {
        IC_ProcessAffinity_Functions.SetProcessAffinity(this.PID) ; IdleDragons.exe
        return base.VerifyAdventureLoaded()
    }
}