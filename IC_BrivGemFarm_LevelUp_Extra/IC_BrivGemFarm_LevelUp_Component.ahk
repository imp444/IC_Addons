#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_DefinesLoader.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk

IC_BrivGemFarm_LevelUp_Functions.InjectAddon()

global g_BrivGemFarm_LevelUp := new IC_BrivGemFarm_LevelUp_Component
global g_DefinesLoader := new IC_BrivGemFarm_LevelUp_DefinesLoader
global g_HeroDefines := IC_BrivGemFarm_LevelUp_HeroData

g_BrivGemFarm_LevelUp.Init()

/*  IC_BrivGemFarm_LevelUp_Component
    Class that manages the GUI for IC_BrivGemFarm_LevelUp.

*/
Class IC_BrivGemFarm_LevelUp_Component
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"

    Settings := ""
    TempSettings := new IC_BrivGemFarm_LevelUp_Component._IC_BrivGemFarm_LevelUp_TempSettings
    TimerFunctions := ""

    ; GUI startup
    Init()
    {
        this.LoadSettings()
        ; Preload settings into the GUI
        defaultMinLevel := this.Settings.DefaultMinLevel
        defaultMaxLevel := this.Settings.DefaultMaxLevel
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinRadio%defaultMinLevel%, 1
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxRadio%defaultMaxLevel%, 1
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ShowSpoilers, % this.Settings.ShowSpoilers
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ForceBrivShandie, % this.Settings.ForceBrivShandie
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_SkipMinDashWait, % this.Settings.SkipMinDashWait
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % this.Settings.MaxSimultaneousInputs
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_MinLevelTimeout, % this.Settings.MinLevelTimeout
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_BrivMinLevelStacking, % this.Settings.BrivMinLevelStacking
        GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_BrivMinLevelArea, % this.Settings.BrivMinLevelArea
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_LevelToSoftCapFailedConversion, % this.Settings.LevelToSoftCapFailedConversion
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_LevelToSoftCapFailedConversionBriv, % this.Settings.LevelToSoftCapFailedConversionBriv
        this.AddToolTips()
        g_DefinesLoader.Start()
        this.CreateTimedFunctions()
        this.Start()
    }

    ; Adds timed functions to be run when briv gem farm is started
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "UpdateStatus")
        this.TimerFunctions[fncToCallOnTimer] := 3000
        g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(this, "Start"))
        g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(this, "Stop"))
    }

    Start()
    {
        for k,v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    Stop()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        GuiControl, ICScriptHub:Text, BrivGemFarmLevelUpStatusText, Waiting for Gem Farm to start
        GuiControl, ICScriptHub:Text, BrivGemFarmLevelUpStatusWarning,
    }

    ; Updates status string / warnings on a timer
    ; Checks if the addon is running while BrivGemFarm is active, and if F keys are enabled
    UpdateStatus()
    {
        static statuses := []
        static statusIndex := 0
        static fKeyWarning := false
        static fKeyWarningMsg1 := "WARNING: F keys disabled. This Addon uses them to level up champions."
        static fKeyWarningMsg2 := "Enable them both in the script (BrivGemFarm tab) and in the game (Settings -> General)."
        static loadWarning := false
        static loadWarningMsg := "WARNING: Addon was loaded too late. Stop/start Gem Farm to resume."

        if (!g_BrivUserSettings[ "Fkeys" ]) ; F kets check
        {
            if (!fKeyWarning)
            {
                fKeyWarning := true
                statuses.Push(fKeyWarningMsg1)
                statuses.Push(fKeyWarningMsg2)
            }
        }
        else if (fKeyWarning) ; Remove once resolved
        {
            Loop, 2
            {
                for k, v in statuses
                    if ((v == fKeyWarningMsg1) OR (v == fKeyWarningMsg2))
                        statuses.RemoveAt(k)
            }
            fKeyWarning := false
        }
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (!SharedRunData.BrivGemFarmLevelUpRunning) ; Addon running check
            {
                if (!loadWarning)
                {
                    loadWarning := true
                    statuses.Push(loadWarningMsg)
                    str := "BrivGemFarm LevelUp addon was loaded after Briv Gem Farm started.`n"
                    MsgBox, % str . "If you want it enabled, press Stop/Start to retry."
                }
            }
            else ; Remove once resolved
            {
                if (loadWarning)
                    for k, v in statuses
                        if (v == loadWarningMsg)
                            statuses.RemoveAt(k)
                GuiControl, ICScriptHub:Text, BrivGemFarmLevelUpStatusText, Running
            }
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BrivGemFarmLevelUpStatusText, Waiting for Gem Farm to start
        }
        ; Display all statuses one after the other, then start again from the beginning
        statusIndex := statuses.Length() < statusIndex ? 1 : statusIndex
        GuiControl, ICScriptHub:Text, BrivGemFarmLevelUpStatusWarning, % statuses[statusIndex++]
    }

    ; Performs additional functions after definitions have been fully loaded
    OnHeroDefinesFinished()
    {
        this.UndoTempSettings()
        levelSettings := this.Settings.BrivGemFarm_LevelUp_Settings
        for heroID in g_HeroDefines.HeroDataByID
        {
            if (!levelSettings.minLevels.HasKey(heroID))
                levelSettings.minLevels[heroID] := this.Settings.DefaultMinLevel
            if (!levelSettings.maxLevels.HasKey(heroID))
            {
                heroData := g_HeroDefines.HeroDataByID[heroID]
                levelSettings.maxLevels[heroID] := this.Settings.DefaultMaxLevel == "Last" ? heroData.lastUpgradeLevel : 1
            }
        }
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadFormation
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_Default
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadDefinitions
    }

    ; Allows to click on the button to manually load hero definitions
    OnHeroDefinesFailed()
    {
        GuiControl, ICScriptHub: Enable, BrivGemFarm_LevelUp_LoadDefinitions
    }

    /*  LoadSettings - Load GUI settings
        Parameters:    default: bool - If true, load default settings with specific values for speed champs
                       save: bool - If true, save settings to file

        Returns:
    */
    LoadSettings(default := false, save := false)
    {
        if (this.Settings == "") ; Init
        {
            settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
            if (!IsObject(settings))
            {
                settings := {}
                save := true
            }
            this.Settings := settings
        }
        defaultSettings := this.LoadDefaultSettings()
        for k, v in defaultSettings ; Fill missing default settings
        {
            if (!this.Settings.HasKey(k))
            {
                if (k == "BrivMinLevelStacking") ; Comes after settings.BrivGemFarm_LevelUp_Settings values have been initialized
                    this.Settings[k] := (settings.BrivGemFarm_LevelUp_Settings.maxLevels[58] < 170) ? settings.BrivGemFarm_LevelUp_Settings.minLevels[58] : settings.BrivGemFarm_LevelUp_Settings.maxLevels[58]
                else
                    this.Settings[k] := v
                save := true
            }
            else if (IsObject(v))
            {
                for k1, v1 in v
                if (!this.Settings[k].HasKey(k1))
                {
                    this.Settings[k][k1] := v1
                    save := true
                }
                else if (IsObject(v1))
                {
                    for k2, v2 in v1
                    if (!this.Settings[k][k1].HasKey(k2))
                    {
                        this.Settings[k][k1][k2] := v2
                        save := true
                    }
                }
            }
        }
        if (default) ; Load default settings as temp settings into the GUI
        {
            this.TempSettings.AddSetting("", defaultSettings)
            defaultMinLevel := this.TempSettings.TempSettings.HasKey("DefaultMinLevel") ? this.TempSettings.TempSettings.DefaultMinLevel : this.Settings.DefaultMinLevel
            defaultMaxLevel := this.TempSettings.TempSettings.HasKey("DefaultMaxLevel") ? this.TempSettings.TempSettings.DefaultMaxLevel : this.Settings.DefaultMaxLevel
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinRadio%defaultMinLevel%, 1
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxRadio%defaultMaxLevel%, 1
            this.FillMissingDefaultSettings()
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ShowSpoilers, % defaultSettings.ShowSpoilers
            this.ToggleSpoilers(defaultSettings.ShowSpoilers)
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ForceBrivShandie, % defaultSettings.ForceBrivShandie
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_SkipMinDashWait, % defaultSettings.SkipMinDashWait
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % defaultSettings.MaxSimultaneousInputs
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinLevelTimeout, % defaultSettings.MinLevelTimeout
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_BrivMinLevelStacking, % defaultSettings.BrivMinLevelStacking
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_BrivMinLevelArea, % defaultSettings.BrivMinLevelArea
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_LevelToSoftCapFailedConversion, % defaultSettings.LevelToSoftCapFailedConversion
            GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_LevelToSoftCapFailedConversionBriv, % defaultSettings.LevelToSoftCapFailedConversionBriv
            this.LoadFormation(this.GetFormationFromGUI())
        }
        if (save)
            this.SaveSettings()
        if (default)
            this.Update("", true)
        else
            this.Update("Settings loaded.", true)
    }

    ; Load default settings to be used by IC_BrivGemFarm_LevelUp_Functions.ahk
    ; Speed champs have specific values that limit leveling to the minimum required to obtain all their speed abilities
    LoadDefaultSettings()
    {
        settings := {}
        settings.ShowSpoilers := false
        settings.ForceBrivShandie := false
        settings.SkipMinDashWait := false
        settings.MaxSimultaneousInputs := 4
        settings.MinLevelTimeout := 5000
        settings.BrivMinLevelStacking := 1300
        settings.BrivMinLevelArea := 0
        settings.DefaultMinLevel := 0
        settings.DefaultMaxLevel := 1
        settings.LevelToSoftCapFailedConversion := true
        settings.LevelToSoftCapFailedConversionBriv := false
        minLevels := {}, maxLevels := {}
        minLevels[58] := 170, maxLevels[58] := 1300 ; Briv
        minLevels[47] := 120, maxLevels[47] := 120 ; Shandie
        minLevels[91] := 260, maxLevels[91] := 350 ; Widdle 260 310 350
        minLevels[28] := 90, maxLevels[28] := 200 ; Deekin 90 200
        minLevels[75] := 220, maxLevels[75] := 360 ; Hew Maan 40 200 220 360
        minLevels[102] := 90, maxLevels[102] := 250 ; Nahara
        minLevels[125] := 1, maxLevels[125] := 370 ; BBEG
        minLevels[52] := 80, maxLevels[52] := 280 ; Sentry
        minLevels[59] := 70, maxLevels[59] := 100 ; Melf
        minLevels[115] := 100, maxLevels[115] := 100 ; Virgil
        minLevels[89] := 1, maxLevels[89] := 1 ; D'hani
        minLevels[114] := 1, maxLevels[114] := 1 ; Kent
        minLevels[98] := 1, maxLevels[98] := 1 ; Gazrick 1540
        minLevels[79] := 1, maxLevels[79] := 1 ; Shaka
        minLevels[81] := 1, maxLevels[81] := 1 ; Selise
        minLevels[56] := 165, maxLevels[56] := 165 ; Havilar
        minLevels[95] := 100, maxLevels[95] := 250 ; Vi 100 250
        minLevels[70] := 90, maxLevels[70] := 90 ; Ezmeralda 90 315
        minLevels[12] := 65, maxLevels[12] := 65 ; Arkhan
        minLevels[4] := 1, maxLevels[4] := 2050 ; Jarlaxle
        minLevels[39] := 1, maxLevels[39] := 2930 ; Paultin
        minLevels[103] := 1, maxLevels[103] := 2000 ; Valentine
        minLevels[124] := 1, maxLevels[124] := 890 ; Evandra
        minLevels[113] := 1, maxLevels[113] := 1370 ; Egbert
        minLevels[94] := 1, maxLevels[94] := 2520 ; Rust
        minLevels[30] := 1, maxLevels[30] := 2020 ; Azaka
        minLevels[118] := 0, maxLevels[118] := 60 ; Fen
        minLevels[40] := 0, maxLevels[40] := 215 ; Black Viper
        minLevels[97] := 0, maxLevels[97] := 80 ; Tatyana
        settings.BrivGemFarm_LevelUp_Settings := {minLevels:minLevels, maxLevels:maxLevels}
        return settings
    }

    ; Reset min/max values for other champions
    FillMissingDefaultSettings()
    {
        defaultLevelSettings := this.LoadDefaultSettings().BrivGemFarm_LevelUp_Settings
        settings := {}, minLevels := {}, maxLevels := {}
        for heroID in g_HeroDefines.HeroDataByID
        {
            if (!defaultLevelSettings.minLevels.HasKey(heroID))
                minLevels[heroID] := this.TempSettings.TempSettings.HasKey("DefaultMinLevel") ? this.TempSettings.TempSettings.DefaultMinLevel : this.Settings.DefaultMinLevel
            if (!defaultLevelSettings.maxLevels.HasKey(heroID))
            {
                heroData := g_HeroDefines.HeroDataByID[heroID]
                maxLevels[heroID] := (this.TempSettings.TempSettings.HasKey("DefaultMaxLevel") ? this.TempSettings.TempSettings.DefaultMaxLevel : this.Settings.DefaultMaxLevel) == "Last" ? heroData.lastUpgradeLevel : 1
            }
        }
        settings.BrivGemFarm_LevelUp_Settings := {minLevels:minLevels, maxLevels:maxLevels}
        this.TempSettings.AddSetting("", settings)
        this.LoadFormation(this.GetFormationFromGUI())
    }

    ; Restore last saved settings
    UndoTempSettings()
    {
        defaultMinLevel := this.Settings.DefaultMinLevel
        defaultMaxLevel := this.Settings.DefaultMaxLevel
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinRadio%defaultMinLevel%, 1
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxRadio%defaultMaxLevel%, 1
        showSpoilers := this.Settings.ShowSpoilers
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ShowSpoilers, % showSpoilers
        this.ToggleSpoilers(showSpoilers)
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_ForceBrivShandie, % this.Settings.ForceBrivShandie
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_SkipMinDashWait, % this.Settings.SkipMinDashWait
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MaxSimultaneousInputs, % this.Settings.MaxSimultaneousInputs
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_MinLevelTimeout, % this.Settings.MinLevelTimeout
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_BrivMinLevelStacking, % this.Settings.BrivMinLevelStacking
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_BrivMinLevelArea, % this.Settings.BrivMinLevelArea
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_LevelToSoftCapFailedConversion, % this.Settings.LevelToSoftCapFailedConversion
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_LevelToSoftCapFailedConversionBriv, % this.Settings.LevelToSoftCapFailedConversionBriv
        this.TempSettings.Reset()
        this.LoadFormation(this.GetFormationFromGUI())
        this.Update("Settings loaded.", true)
    }

    ; Returns a list of champIDs from the current selected champions
    GetFormationFromGUI()
    {
        Gui, ICScriptHub:Submit, NoHide
        formation := []
        heroDefs := g_DefinesLoader.HeroDefines.hero_defines
        Loop, 12
        {
            seat_id = % A_Index
            if (DDL_BrivGemFarmLevelUpName_%seat_id% == "")
                continue
            for k, v in heroDefs
            {
                if (v.name == DDL_BrivGemFarmLevelUpName_%seat_id%)
                {
                    formation.Push(k)
                    break
                }
            }
        }
        return formation
    }

    /*  SaveSettings - Save GUI settings
        Parameters:    applyTempSettings: bool - If true, apply temporary settings before saving

        Returns:
    */
    SaveSettings(applyTempSettings := false)
    {
        if (applyTempSettings)
        {
            this.TempSettings.Apply()
            this.Update("Settings saved.")
        }
        ; Delete redundant min/max values from file
        settings := IC_BrivGemFarm_LevelUp_Functions.ObjFullyClone(this.Settings)
        defaultLevelSettings := this.LoadDefaultSettings().BrivGemFarm_LevelUp_Settings
        levelSettings := settings.BrivGemFarm_LevelUp_Settings
        for heroID in g_HeroDefines.HeroDataByID
        {
            if (!defaultLevelSettings.minLevels.HasKey(heroID) AND levelSettings.minLevels[heroID] == this.Settings.DefaultMinLevel)
                settings.BrivGemFarm_LevelUp_Settings.minLevels.Delete(heroID)
            if (!defaultLevelSettings.maxLevels.HasKey(heroID))
            {
                heroData := g_HeroDefines.HeroDataByID[heroID]
                if (levelSettings.maxLevels[heroID] == (this.Settings.DefaultMaxLevel == "Last" ? heroData.lastUpgradeLevel : 1))
                    settings.BrivGemFarm_LevelUp_Settings.maxLevels.Delete(heroID)
            }
        }
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.UpdateSettingsFromFile(applyTempSettings)
        }
    }

    /*  Update - Updates the GUI text strings, look for temp settings changes
        Parameters: text - The text shown under formation selection/default settings

        Returns:
    */
    Update(text := "", settingsText := false, invalidFormationText := false)
    {
        if (settingsText)
            GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_SettingsStatusText, % text
        else
        {
            GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_SettingsStatusText,
            GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_Text, % "Status: " . text
        }
        this.UpdateLastUpdated()
        if (this.TempSettings.HasChanges())
        {
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_SettingsStatusText
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Save
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Changes
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_Undo
        }
        else
        {
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Save
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Changes
            GuiControl, ICScriptHub:Hide, BrivGemFarm_LevelUp_Undo
            GuiControl, ICScriptHub:Show, BrivGemFarm_LevelUp_SettingsStatusText
        }
        if (invalidFormationText)
            GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_NoFormationText, % text
        else
            GuiControl, ICScriptHub:Text, BrivGemFarm_LevelUp_NoFormationText,
    }

    ; Update the text that shows the last time cached_definitions.json was loaded
    UpdateLastUpdated(lastUpdateString := "", save := false)
    {
        settings := this.Settings
        if (lastUpdateString == "")
            lastUpdateString := settings.LastUpdateString
        if (save)
        {
            settings.LastUpdateString := lastUpdateString
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        GuiControl, ICScriptHub:, BrivGemFarm_LevelUp_DefinitionsStatus, % lastUpdateString
    }

    ; Loads formation from champIDs into the GUI, defaults to Q formation
    LoadFormation(formation := 1)
    {
        if (!IsObject(formation) OR formation.Length() == 0)
        {
            formationIndex := formation.Length() == 0 ? 1 : formation
            formation := this.GetSavedFormation(formationIndex)
        }
        if (!IsObject(formation) OR formation.Length() == 0)
        {
            GuiControl, ICScriptHub:Choose, BrivGemFarm_LevelUp_LoadFormation, 0
            this.Update("Invalid formation. Game closed?",, true)
            return
        }
        seats := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        for k, v in formation
        {
            if (v <= 0 OR v == "")
                continue
            champData := g_DefinesLoader.HeroDefines.hero_defines[v]
            seat_id := champData.seat_id
            name := champData.name
            seats.Delete(seat_id)
            GuiControl, ICScriptHub:ChooseString, DDL_BrivGemFarmLevelUpName_%seat_id%, % "|" . name
            Sleep, 1
        }
        for k, v in seats ; Delete contents from unused seats
            IC_BrivGemFarm_LevelUp_Seat.Seats[v].DeleteContents()
        this.Update()
    }

    ; Returns one of the in-game formations that are saved by the gem farming script after each reset
    GetSavedFormation(formation := 1)
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.SaveFormations()
            savedFormations := this.Settings.SavedFormations := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath).SavedFormations
        }
        catch
        {
            noGameSave := true
        }
        if (noGameSave OR !IsObject(savedFormations))
        {
            g_SF.Memory.OpenProcessReader()
            return g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(formation), true) ; without empty slots
        }
        Switch formation
        {
            Case 1:
                return savedFormations.Q
            Case 2:
                return savedFormations.W
            Case 3:
                return savedFormations.E
            Default:
                return formation
        }
    }

    ; Toggle all seats's spoilers on/off
    ToggleSpoilers(value)
    {
        Loop, 12
            IC_BrivGemFarm_LevelUp_Seat.Seats[A_Index].ToggleSpoilers(value)
    }

    ; Returns saved min/max settings
    GetLevelSettings()
    {
        return this.Settings.BrivGemFarm_LevelUp_Settings
    }

    ; Show tooltips on mouseover
    AddToolTips()
    {
        GUIFunctions.AddToolTip("LoadFormationText", "Show current Q/W/E game formation.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_ShowSpoilers", "Show unreleased champions in their respective seat.")
        GUIFunctions.AddToolTip("DefaultMinLevelText", "Default min level for champions with no default values.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinRadio0", "Don't initially put the champion on the field.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinRadio1", "Put the champion on the field at level 1.")
        GUIFunctions.AddToolTip("DefaultMaxLevelText", "Default max level for champions with no default values.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxRadio1", "Put the champion on the field and don't level them.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxRadioLast", "Level up the champion until soft cap.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_ForceBrivShandie", "Level up Briv and Shandie before other champions after resetting.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_SkipMinDashWait", "Skip waiting for Shandie's dash being active after leveling champions to MinLevel. Useful if stacking really early in the run.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxSimultaneousInputs", "Maximum number of champions being leveled during the intial leveling to minLevel.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MaxSimultaneousInputsText", "Maximum number of champions being leveled during the intial leveling to minLevel.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinLevelTimeout", "Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_MinLevelTimeoutText", "Timeout before stopping the initial champion leveling. If set to 0, minimum leveling will be skipped.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelStacking", "Minimum Briv level to reach before stacking. After stacking is done, leveling will resume up to MaxLevel")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelStackingText", "Minimum Briv level to reach before stacking. After stacking is done, leveling will resume up to MaxLevel")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelArea", "Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation).")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_BrivMinLevelAreaText", "Minimum area before starting to level up Briv (used to walk at the beginning if using Briv in E formation).")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_LevelToSoftCapFailedConversion", "Level up champions to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.")
        GUIFunctions.AddToolTip("BrivGemFarm_LevelUp_LevelToSoftCapFailedConversionBriv", "Level up Briv to soft cap after failed conversion if Briv has lower than 50 Sprint stacks.")
        GUIFunctions.AddToolTip("MinLevelText", "Minimum level for every champion in the formation before progressing/waiting for Shandie's Dash.")
        GUIFunctions.AddToolTip("MaxLevelText", "Maximum level for every champion in the formation before leveling stops.")
    }

    /*  _IC_BrivGemFarm_LevelUp_TempSettings
        Class that holds temporary settings from the GUI before they are saved and passed the game's instance

    */
    Class _IC_BrivGemFarm_LevelUp_TempSettings
    {
        TempSettings := {}

        /*  AddSetting - Assing a value to a temporary setting
            Parameters:  key - An array of strings keys used to register this parameter using the same data structure than the one in Settings
                         value - Value of the setting
            Returns:
        */
        AddSetting(key, value)
        {
            static recursionDepth := 0

            Gui, ICScriptHub:Submit, NoHide
            update := false, ++recursionDepth
            if (IsObject(value))
            {
                for k, v in value
                {
                    if (IsObject(v) AND !IsObject(key))
                        key := []
                    keyNext := key.Clone()
                    keyNext.Push(k)
                    this.AddSetting(keyNext, v)
                }
                update := true
            }
            else if (IsObject(key))
            {
                if key.Length() ; Array
                {
                    lastKey := key[key.Length()]
                    if (this.GetSettingsObject(key)[lastKey] == value) ; Same value
                    {
                        tempSettingsObject := this.GetTempSettingsObject(key)
                        if (IsObject(tempSettingsObject))
                            this.DeleteTempSettingsObject(key, tempSettingsObject) ; Remove key
                        else
                            return --recursionDepth
                    }
                    else
                        this.SetTempSettingsObject(key, value) ; Add
                }
                else
                    return --recursionDepth
                update := true
            }
            else
            {
                if (value == g_BrivGemFarm_LevelUp.Settings[key]) ; Same value
                {
                    if (this.TempSettings.HasKey(key))
                        this.TempSettings.Delete(key) ; Remove key
                    else
                        return --recursionDepth
                }
                else
                    this.TempSettings[key] := value ; Add
                update := true
            }
            if (update AND --recursionDepth == 0) ; Only refresh after a change when all values have been added
            {
                this.ReloadTempSettingsDisplay()
                g_BrivGemFarm_LevelUp.Update()
            }
        }

        ; Returns the setting object found at the last key in keys
        GetSettingsObject(keys)
        {
            obj := g_BrivGemFarm_LevelUp.Settings
            Loop, % keys.Length() - 1
                obj := obj[keys[A_Index]]
            return obj
        }

        ; Returns the temporary setting object found at the last key in keys
        GetTempSettingsObject(keys)
        {
            obj := this.TempSettings
            Loop, % keys.Length() - 1
                obj := obj[keys[A_Index]]
            return obj
        }

        ; Assigns a value to the temporary setting object found at the last key in keys
        SetTempSettingsObject(keys, value)
        {
            obj := this.TempSettings
            Loop, % keys.Length() - 1
            {
                if (!obj.HasKey(keys[A_Index]))
                    obj[keys[A_Index]] := {}
                obj := obj[keys[A_Index]]
            }
            lastKey := keys[keys.Length()]
            obj[lastKey] := value
            return obj
        }

        ; Deletes the temporary setting object found at the last key in keys
        DeleteTempSettingsObject(keys, obj)
        {
            obj.Delete(keys[keys.MaxIndex()])
            if (obj.Count() == 0)
            {
                for k, v in this.TempSettings
                {
                    for k1, v1 in v
                        if (v1.Count() == 0)
                            v.Delete(k1)
                    if (v.Count() == 0)
                        this.TempSettings.Delete(k)
                }
            }
        }

        ; Returns temporary min/max settings
        GetLevelTempSettings()
        {
            return this.TempSettings.BrivGemFarm_LevelUp_Settings
        }

        ; Returns true if there is at least one unsaved temporary setting
        HasChanges()
        {
            return this.TempSettings.Count()
        }

        ; Apply temporary settings
        Apply()
        {
            for k, v in this.TempSettings
            {
                if (IsObject(v))
                    continue
                g_BrivGemFarm_LevelUp.Settings[k] := v
            }
            for k, v in this.TempSettings
            {
                if (!IsObject(v))
                    continue
                for k1, v1 in v
                    for k2, v2 in v1
                        g_BrivGemFarm_LevelUp.Settings[k][k1][k2]:= v2
            }
            this.Reset()
        }

        ; Reset temporary settings
        Reset()
        {
            this.TempSettings := {}
            this.ReloadTempSettingsDisplay()
        }

        ; Build the listview with settings / min/Max settings, showing current (saved) and new (unsaved) values
        ReloadTempSettingsDisplay()
        {
            restore_gui_on_return := GUIFunctions.LV_Scope("IC_BrivGemFarm_LevelUp_TempSettings", "BrivTempSettingsID")
            Gui, IC_BrivGemFarm_LevelUp_TempSettings:ListView, BrivTempSettingsID
            LV_Delete()
            for k, v in this.TempSettings
            {
                if (IsObject(v))
                    continue
                if (k == "ShowSpoilers" OR k == "ForceBrivShandie" OR k == "LevelToSoftCapFailedConversion" OR k == "LevelToSoftCapFailedConversionBriv")
                {
                    saved := g_BrivGemFarm_LevelUp.Settings[k] ? "Yes" : "No"
                    v := v ? "Yes" : "No"
                }
                else
                    saved := g_BrivGemFarm_LevelUp.Settings[k]
                LV_Add(, k, saved, v)
            }
            for k, v in this.TempSettings ; Min/Max
            {
                if (!IsObject(v))
                    continue
                for k1, v1 in v
                {
                    for k2, v2 in v1
                    {
                        heroData := g_HeroDefines.HeroDataByID[k2]
                        showSpoilers := this.TempSettings.HasKey("ShowSpoilers") ? this.TempSettings.ShowSpoilers : g_BrivGemFarm_LevelUp.Settings.ShowSpoilers
                        if (!showSpoilers AND IC_BrivGemFarm_LevelUp_Seat.IsSpoiler(heroData.allow_time_gate))
                            continue
                        heroName := heroData.name
                        minMaxFormat := k1 == "minLevels" ? "MinLevel " : k1 == "maxLevels" ? "MaxLevel" : k1
                        settingName := minMaxFormat . " [ " . heroName . " ] "
                        saved := g_BrivGemFarm_LevelUp.Settings[k][k1][k2]
                        LV_Add(, settingName, saved, v2)
                    }
                }
            }
            Loop % LV_GetCount("Col") ; Resize columns
                LV_ModifyCol(A_Index, "AutoHdr")
        }
    }
}

; Functions used to update min/max upgrade values of each seat
Class IC_BrivGemFarm_LevelUp_Seat
{
    static Seats := IC_BrivGemFarm_LevelUp_Seat.BuildSeats()

    ID := 0
    HeroDataByID := {}
    HeroDataByName := {}
    HasSpoiler := false

    __New(seat)
    {
        this.ID := seat
    }

    ; Adds the data for a champion to this seat's dictionnary sorted by name
    AddChampion(data)
    {
        this.HeroDataByName[data.name] := data
        if (!this.HasSpoiler)
            this.HasSpoiler := this.IsSpoiler(data.allow_time_gate)
    }

    ; Deletes min/max upgrade list and sets this seat's fields to empty values
    DeleteContents()
    {
        seat := this.ID
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
        GuiControl, ICScriptHub:Choose, DDL_BrivGemFarmLevelUpName_%seat%, 0
        GuiControl, ICScriptHub:Choose, Combo_BrivGemFarmLevelUpMinLevel_%seat%, 0
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % "|"
        GuiControl, ICScriptHub:Move, Combo_BrivGemFarmLevelUpMinLevel_%seat%, h25
        GuiControl, ICScriptHub:Choose, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, 0
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % "|"
        GuiControl, ICScriptHub:Move, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, h25
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
    }

    /*  UpdateMinMaxLevels - Update min/max upgrades values and upgrade list
                             The size of the longest item in the list will be cached at the first time the champion is chosen
        Parameters:          name: string - The name of a champion

        Returns:
    */
    UpdateMinMaxLevels(name)
    {
        global
        seat := this.ID
        heroData := this.HeroDataByName[name]
        upgrades := heroData.upgradesList
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, -Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % "|" . upgrades
        GuiControl, ICScriptHub:, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % "|" . upgrades
        if(heroData.cachedSize == "")
            heroData.cachedSize := IC_BrivGemFarm_LevelUp_Functions.DropDownSize(heroData.upgradesList)
        this.SetMinMaxComboWidth(heroData.cachedSize)
        Sleep, 1
        levelSettings := g_BrivGemFarm_LevelUp.GetLevelSettings()
        levelTempSettings := g_BrivGemFarm_LevelUp.TempSettings.GetLevelTempSettings()
        minLevel := levelTempSettings.minLevels.HasKey(k) ? levelTempSettings.minLevels[k] : levelSettings.minLevels[k]
        minLevel := minLevel != "" ? minlevel : g_BrivGemFarm_LevelUp.Settings.DefaultMinLevel
        maxLevel := levelTempSettings.maxLevels.HasKey(k) ? levelTempSettings.maxLevels[k] : levelSettings.maxLevels[k]
        maxLevel := maxLevel != "" ? maxlevel : g_BrivGemFarm_LevelUp.Settings.DefaultMaxLevel == "Last" ? heroData.lastUpgradeLevel : 1
        GuiControl, ICScriptHub:Text, Combo_BrivGemFarmLevelUpMinLevel_%seat%, % minLevel
        GuiControl, ICScriptHub:Text, Combo_BrivGemFarmLevelUpMaxLevel_%seat%, % maxLevel
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMinLevel_%seat%
        GuiControl, +Redraw, Combo_BrivGemFarmLevelUpMaxLevel_%seat%
    }

    ; Sets the width of min/max comboBoxes for a seat
    SetMinMaxComboWidth( width)
    {
        global
        local seat := this.ID
        local minH := HBrivGemFarmLevelUpMinLevel_%seat%
        local maxH := HBrivGemFarmLevelUpMaxLevel_%seat%
        PostMessage, CB_SETDROPPEDWIDTH, width, 0, , ahk_id %minH%
        PostMessage, CB_SETDROPPEDWIDTH, width, 0, , ahk_id %maxH%
    }

    ; Updates the list of champions names for this lot
    UpdateNames(showSpoilers := false)
    {
        names := "|"
        for ID, heroData in this.HeroDataByID
        {
            if (showSpoilers OR !this.IsSpoiler(heroData.allow_time_gate))
                names .= heroData.name . "|"
        }
        seat := this.ID
        GuiControl, ICScriptHub:, DDL_BrivGemFarmLevelUpName_%seat%, % names
    }

    ; Toggle this seat's spoilers on/off
    ToggleSpoilers(value)
    {
        if (!this.HasSpoiler)
            return
        seat := this.ID
        choice := DDL_BrivGemFarmLevelUpName_%seat% ; Remember the current name selection
        this.UpdateNames(value)
        GuiControl, ICScriptHub:ChooseString, DDL_BrivGemFarmLevelUpName_%seat%, % choice
        Gui, ICScriptHub:Submit, NoHide
        if (choice != DDL_BrivGemFarmLevelUpName_%seat%)
            this.DeleteContents()
    }

    GetCurrentHeroData()
    {
        id := this.ID
        name := DDL_BrivGemFarmLevelUpName_%id%
        return this.HeroDataByName[name]
    }

    ; Static methods

    /*  IsSpoiler -    Find if a champion is part of spoilers
        Parameters:    allow_time_gate: string - A time string that shows when the champion's Time Gate will be available (UTC)

        Returns:       bool - True if the champion's Time Gate is available in 12 days or less (when the event starts)
    */
    IsSpoiler(allow_time_gate := "")
    {
        if (allow_time_gate == "")
            return false
        dt := ""
        Loop, Parse, allow_time_gate, :%A_Space%-
            dt .= A_LoopField
        EnvAdd, dt, 7, H
        EnvAdd, dt, -12, D
        EnvSub, dt, A_NowUTC, S
        return dt > 0
    }

    ; Adds a single champion data to his seat's container
    AddChampionData(data)
    {
        IC_BrivGemFarm_LevelUp_Seat.Seats[data.seat_id].AddChampion(data)
    }

    ; Build seats on startup
    BuildSeats()
    {
        seats := []
        Loop, 12
            seats.Push(new IC_BrivGemFarm_LevelUp_Seat(A_Index))
        return seats
    }

    ; Performs additional functions after definitions have been fully loaded
    OnHeroDefinesFinished()
    {
        for ID, heroData in g_DefinesLoader.HeroDefines.hero_defines
            IC_BrivGemFarm_LevelUp_Seat.Seats[heroData.seat_id].HeroDataByID[ID] := heroData
        for seatID, seat in IC_BrivGemFarm_LevelUp_Seat.Seats
            seat.UpdateNames(g_BrivGemFarm_LevelUp.Settings.ShowSpoilers)
        g_BrivGemFarm_LevelUp.OnHeroDefinesFinished()
    }
}