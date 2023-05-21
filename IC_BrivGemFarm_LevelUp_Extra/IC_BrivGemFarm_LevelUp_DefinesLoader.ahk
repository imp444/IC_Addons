; Functions used to load hero definitions into the GUI
class IC_BrivGemFarm_LevelUp_DefinesLoader
{
    HeroDefines := ""
    TimerFunctions := {}
    Status := ""

    Start(params*)
    {
        fncToCallOnTimer := ObjBindMethod(this, "ReadOrCreateHeroDefs", params*)
        this.TimerFunctions[fncToCallOnTimer] := 20
        for k,v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    PauseOrResume(value)
    {
        value := value ? "On" : "Off"
        for k,v in this.TimerFunctions
            SetTimer, %k%, %value%
    }

    Stop()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        this.TimerFunctions := {}
    }

    ; Updates the loading text shown
    UpdateLoading(text := "")
    {
        Status := text
        g_BrivGemFarm_LevelUp.UpdateLastUpdated(text)
    }

    ; Retrieves cached_definitions path. If silent = false, prompts a choose dialog if path not found
    ; Saves the last known valid path
    FindCachedDefinitionsPath(silent := true)
    {
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
        if (settings.LastCachedPath == "" OR !FileExist(settings.LastCachedPath))
        {
            exePath := % g_UserSettings[ "InstallPath" ] ; Steam
            cachedPath := % exePath . "\..\IdleDragons_Data\StreamingAssets\downloaded_files\cached_definitions.json"
            if (!FileExist(cachedPath) AND !silent) ; Try to find cached_definitions folder
                FileSelectFile, cachedPath, 1, % "\..\..\..\..\IdleChampions\IdleDragons_Data\StreamingAssets\downloaded_files\cached_definitions.json", cached_definitions.json, cached_definitions.json
            settings.LastCachedPath := cachedPath
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        else
            cachedPath := settings.LastCachedPath
        return cachedPath
    }

    /*  CreateHeroDefs - Create definitions with upgrade levels from cached_definitions.json
        Parameters:      silent: bool - If true, doesn't prompt the dialog to choose the file if not found

        Returns:         object - Definitions used to build the GUI
    */
    CreateHeroDefs(silent := true)
    {
        static state := 0
        static index := 0
        static maxIndex := 0
        static defs := ""
        static trimmedHeroDefs := ""

        if (state == 0)
        {
            path := this.FindCachedDefinitionsPath(silent)
            if (path == "")
                return -1
            this.UpdateLoading("Loading new definitions...")
            defs := g_SF.LoadObjectFromJSON(path)
            ; Parse hero_defines
            heroDefs := defs.hero_defines
            trimmedHeroDefs := {}
            for k, v in heroDefs
            {
                if (RegExMatch(v.name, "Y\d+E\d+") OR ErrorLevel != 0) ; skip placeholder
                    continue
                id := v.id
                obj := {}
                obj.name := v.name
                obj.seat_id := v.seat_id
                if (v.properties.allow_time_gate != "")
                {
                    if (v.properties.allow_time_gate != -1)
                        obj.allow_time_gate := v.properties.allow_time_gate
                }
                if (!IsObject(trimmedHeroDefs[v]))
                    trimmedHeroDefs[v] = {}
                trimmedHeroDefs[id] := obj
            }
            state := 1
            return
        }
        ; Parse upgrade_defines
        if (index == 0)
        {
            maxIndex := 0
            key := "upgrade_defines_" . maxIndex
            while isObject(defs[key])
                key := "upgrade_defines_" . ++maxIndex
            this.UpdateLoading("Loading new definitions... Loading upgrades " . index . "/" . maxIndex)
        }
        key := "upgrade_defines_" . index
        while isObject(defs[key])
        {
            currentUpgradeDef := defs[key]
            for k, v in currentUpgradeDef
            {
                if (v.required_upgrade_id == 9999)
                    continue
                heroID := v.hero_id
                id := v.id
                if (!IsObject(trimmedHeroDefs[heroID]["upgrades"]))
                    trimmedHeroDefs[heroID]["upgrades"] := {}
                obj := {}
                if v.required_upgrade_id < 9999
                {
                    obj.required_level := v.required_level
                    if (v.name != "")
                        obj.name := v.name
                    if (v.effect != "" AND RegExMatch(v.effect, "set_ultimate_attack")) ; fill old data struct
                    {
                        split := StrSplit(v.effect, ",")
                        for k1, v1 in defs.attack_defines
                        {
                            if (v1.id == split[2])
                            {
                                obj.name := v1.name
                                break
                            }
                        }
                    }
                    if (v.specialization_name)
                        obj.specialization_name := v.specialization_name
                    if (v.tip_text)
                        obj.tip_text := v.tip_text
                    if (v.effect != "")
                        obj.effect := v.effect
                }
                trimmedHeroDefs[heroID]["upgrades"][id] := obj
            }
            this.UpdateLoading("Loading new definitions... Loading upgrades " . ++index . "/" . maxIndex)
            return
        }
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath, trimmedHeroDefs)
        lastUpdateString := "Last updated: " . A_YYYY . "/" A_MM "/" A_DD " at " A_Hour . ":" A_Min
        Status := lastUpdateString
        g_BrivGemFarm_LevelUp.UpdateLastUpdated(lastUpdateString, true)
        this.HeroDefines := trimmedHeroDefs
        defs := "", trimmedHeroDefs := "", state := 0, index := 0
        return 1
    }

    /*  ReadHeroDefs - Read last definitions from HeroDefines.json
        Parameters:    silent: bool - If true, doesn't prompt the dialog to choose the file if not found

        Returns:       bool - True if all champions in Q formation are at or past their target level, false otherwise
    */
    ReadHeroDefs(silent := true)
    {
        heroDefs := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath)
        if (!IsObject(heroDefs))
            return this.CreateHeroDefs(silent)
        this.HeroDefines := heroDefs
        return 1
    }

    /*  ReadOrCreateHeroDefs - Read/Write definitions from/to HeroDefines.json
        Parameters:            silent: bool - If true, doesn't prompt the dialog to choose the file if not found
                               create: bool - If true, force new definitions

        Returns:
    */

    ReadOrCreateHeroDefs(silent := true, create := false)
    {
        static state := 0

        this.PauseOrResume(0)
        if (create)
            state := 0
        if (state == 0)
        {
            heroDefsLoaded := create ? g_DefinesLoader.CreateHeroDefs(silent) : g_DefinesLoader.ReadHeroDefs(silent)
            if (heroDefsLoaded == -1 AND silent == true)
                this.UpdateLoading("WARNING: Could not load Hero definitions. Click on 'load definitions' to resume.")
            else if (heroDefsLoaded != 1)
            {
                this.PauseOrResume(1)
                return
            }
            this.PauseOrResume(0)
            state := 1
        }
        if (state == 1)
        {
            for k, v in this.HeroDefines
            {
                seat_id := v.seat_id
                name := v.name
                heroData := {}
                heroData.id := k
                heroData.name := name
                heroData.seat_id := seat_id
                heroData.allow_time_gate := v.allow_time_gate
                upgrades := v.upgrades
                maxUpgradeLevelW := 0
                for upgradeKey, upgrade in upgrades
                {
                    level := upgrade.required_level
                    if (level == "")
                        continue
                    maxUpgradeLevelW := Max(maxUpgradeLevelW, 2 * StrLen(level))
                }
                listContents := ""
                specializations := {}
                for upgradeKey, upgrade in upgrades
                {
                    level := upgrade.required_level
                    levelStr := level
                    if (level == "")
                        continue
                    s := ""
                    if (upgrade.specialization_name)
                    {
                        if (specializations[level] == "")
                            specializations[level] := 1
                        levelStr .=  "." . specializations[level]
                        s .= "↰↱ " . specializations[level]++ . "." . upgrade.specialization_name
                    }
                    else if (upgrade.name)
                        s .= "★  " . upgrade.name
                    else if (upgrade.effect)
                    {
                        split := StrSplit(upgrade.effect, ",")
                        if (split[1] == "health_add")
                            s .= "♥ Health +" . split[2]
                        else if (split[1] == "hero_dps_multiplier_mult")
                            s .= "🗡️ Damage +" . split[2] . "%"
                        else if (split[1] == "global_dps_multiplier_mult")
                            s .= "⚔️ Global Damage +" . split[2] . "%"
                        else if (split[1] == "set_ultimate_attack")
                            s := "⚡️ " . upgrade.name
                        else if (split[1] == "buff_ultimate")
                            s := "++ Ultimate damage +" split[2] . "%"
                        else if (split[1] == "buff_upgrade")
                            s := "++ " . upgrades[split[3]].name . " + " split[2] . "%"
                        else if (split[1] == "increase_revive_effect_post_stack")
                            s := "++ " . upgrades[split[3]].name . " + " split[2] . "%"
                    }
                    p := "" ; Longest number has no padding before ':'
                    Loop, % maxUpgradeLevelW - 2 * StrLen(level) + StrLen(level) - StrLen(levelStr)
                        p .= " "
                    listContents .= levelStr . p . ": " . s . "|"
                }
                Sort, listContents, N D|
                heroData.upgrades := RegExReplace(listContents, "((\d)+)(\.)(\d)+", "$1  ")
                specializations := ""
                IC_BrivGemFarm_LevelUp_Seat.AddChampionData(heroData)
            }
            IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished()
        }
        this.Stop()
    }
}