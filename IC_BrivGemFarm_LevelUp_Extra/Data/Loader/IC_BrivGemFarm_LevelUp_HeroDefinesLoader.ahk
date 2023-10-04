; Functions used to load hero definitions into the GUI.
class IC_BrivGemFarm_LevelUp_HeroDefinesLoader
{
    ; File locations
    static HeroDefsPath := A_LineFile . "\..\..\HeroDefines.json"
    static LastGUIDPath := A_LineFile . "\..\LastGUID_BrivGemFarm_LevelUp.json"
    static WorkerPath := A_LineFile . "\..\IC_BrivGemFarm_LevelUp_HeroDefinesLoader_Run.ahk"
    ; Loader states
    static STOPPED := 0
    static GET_PLAYSERVER := 1
    static CHECK_TABLECHECKSUMS := 2
    static FILE_PARSING := 3
    static TEXT_DEFS := 4
    static HERO_DEFS := 5
    static ATTACK_DEFS := 6
    static UPGRADE_DEFS := 7
    static EFFECT_DEFS := 8
    static EFFECT_KEY_DEFS := 9
    static FILE_SAVING := 10
    static HERO_DATA_FINISHED := 100
    static HERO_DATA_FINISHED_NOUPDATE := 101
    static SERVER_TIMEOUT := 200
    static DEFS_LOAD_FAIL := 201
    static LOADER_FILE_MISSING := 202

    CurrentState := 0
    GUID := ""
    HeroDefines := ""
    TimerFunction := ObjBindMethod(this, "WaitForDefs")

    Start()
    {
        state := this.CurrentState
        if (state > this.STOPPED && state < this.HERO_DATA_FINISHED)
            return
        ; Start worker
        scriptLocation := this.WorkerPath
        if (!FileExist(this.WorkerPath))
        {
            state := this.LOADER_FILE_MISSING
            g_BrivGemFarm_LevelUpGui.MoveProgressBar(state)
            return g_BrivGemFarm_LevelUpGui.UpdateLoadingText(state)
        }
        this.GUID := guid := ComObjCreate("Scriptlet.TypeLib").Guid
        ObjRegisterActive(this, guid)
        OnExit(ObjBindMethod(this, "ComObjectRevoke"))
        g_SF.WriteObjectToJSON(this.LastGUIDPath, guid)
        languageID := g_BrivGemFarm_LevelUp.GetSetting("DefinitionsLanguage")
        Run, %scriptLocation% %languageID% %guid%
        ; Update loop
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 50, 0
        this.CurrentState := this.GET_PLAYSERVER
    }

    Stop()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, Off
        this.UnregisterComObject()
        this.CurrentState := this.STOPPED
    }

    ; Unregister the shared data object.
    UnregisterComObject()
    {
        ObjRegisterActive(this, "")
    }

    ; Unregister the shared data object on exit.
    ComObjectRevoke()
    {
        this.UnregisterComObject()
        ExitApp
    }

    ; Update loop while IC_BrivGemFarm_LevelUp_HeroDefinesLoader_Run is busy.
    WaitForDefs()
    {
        state := this.CurrentState
        g_BrivGemFarm_LevelUpGui.MoveProgressBar(state)
        g_BrivGemFarm_LevelUpGui.UpdateLoadingText(state)
        if (state >= this.HERO_DATA_FINISHED)
        {
            this.Stop()
            if (state == this.HERO_DATA_FINISHED || this.HeroDefines == "")
            {
                this.HeroDefines := g_SF.LoadObjectFromJSON(this.HeroDefsPath)
                g_HeroDefines.Init(this.HeroDefines)
            }
            if (state >= this.SERVER_TIMEOUT)
                g_BrivGemFarm_LevelUp.OnHeroDefinesFailed()
            else
                IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished()
            IC_BrivGemFarm_LevelUp_ToolTip.UpdateDefsCNETime(this.HeroDefines.current_time)
        }
    }

    ; Called by IC_BrivGemFarm_LevelUp_HeroDefinesLoader_Run.
    UpdateState(state)
    {
        this.CurrentState := state
        return true
    }
}