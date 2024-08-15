; Test to see if BrivGemFarm addon is available.
if(IsObject(IC_BrivGemFarm_Component))
{
    IC_RNGWaitingRoom_Functions.InjectAddon()
    global g_RNGWaitingRoom := new IC_RNGWaitingRoom_Component
    global g_RNGWaitingRoomGui := new IC_RNGWaitingRoom_GUI
    g_RNGWaitingRoom.Init()
}

/*  IC_RNGWaitingRoom_Component

    Class that manages the GUI for RNG Waiting Room.
    Starts automatically on script launch and waits for Briv Gem Farm to be started,
    then stops/starts every time buttons on the main Briv Gem Farm window are clicked.
*/
Class IC_RNGWaitingRoom_Component
{
    Settings := ""
    TimerFunction := ObjBindMethod(this, "UpdateStatus")

    Init()
    {
        g_RNGWaitingRoomGui.Init()
        ; Read settings
        this.LoadSettings()
        ; Update loop
        this.Start()
    }

    Functions
    {
        get
        {
            return IC_RNGWaitingRoom_Functions
        }
    }

    ; Load saved or default settings.
    LoadSettings()
    {
        needSave := false
        default := this.GetNewSettings()
        this.Settings := settings := g_SF.LoadObjectFromJSON(this.Functions.SettingsPath)
        if (!IsObject(settings))
        {
            this.Settings := settings := default
            needSave := true
        }
        else
        {
            ; Delete extra settings
            for k, v in settings
            {
                if (!default.HasKey(k))
                {
                    settings.Delete(k)
                    needSave := true
                }
            }
            ; Add missing settings
            for k, v in default
            {
                if (!settings.HasKey(k) || settings[k] == "")
                {
                    settings[k] := default[k]
                    needSave := true
                }
            }
        }
        if (needSave)
            this.SaveSettings()
        ; Set the state of GUI buttons with saved settings.
        g_RNGWaitingRoomGui.UpdateGUISettings(settings)
    }

    ; Returns an object with default values for all settings.
    GetNewSettings()
    {
        settings := {}
        settings.EllywickGFEnabled := true
        settings.EllywickGFGemCards := 1
        settings.EllywickGFGemPercent := 10
        settings.EllywickGFGemMaxRedraws := 1
        settings.EllywickGFGemWaitFor5Draws := true
        return settings
    }

    UpdateSetting(setting, value)
    {
        this.Settings[setting] := value
    }

    ; Save settings.
    SaveSettings()
    {
        settings := this.Settings
        g_SF.WriteObjectToJSON(IC_RNGWaitingRoom_Functions.SettingsPath, settings)
        GuiControl, ICScriptHub:Text, RNGWR_StatusText, Settings saved
        ; Apply settings to BrivGemFarm
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.RNGWR_UpdateSettingsFromFile()
        }
        catch
        {
            GuiControl, ICScriptHub:Text, RNGWR_StatusText, Waiting for Gem Farm to start
        }
    }

    Start()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 500, 0
    }

    Stop()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, Off
    }

    ; GUI update loop.
    UpdateStatus()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (SharedRunData.RNGWR_Running == "")
            {
                this.Stop()
            }
            else if (SharedRunData.RNGWR_Running)
            {
                status := SharedRunData.RNGWR_Status
                str := "Running" . (status != "" ? " - " . status : "")
                GuiControl, ICScriptHub:Text, RNGWR_StatusText, % str
                stats := SharedRunData.RNGWR_GetStats()
                g_RNGWaitingRoomGui.UpdateGUI(stats)
            }
            else
                GuiControl, ICScriptHub:Text, RNGWR_StatusText, Disabled
        }
        catch
        {
            GuiControl, ICScriptHub:Text, RNGWR_StatusText, Waiting for Gem Farm to start
        }
    }
}