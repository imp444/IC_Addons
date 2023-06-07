; Functions used to load hero definitions into the GUI
class IC_BrivGemFarm_LevelUp_DefinesLoader
{
    static DEFS_LOAD_FAIL := -1
    static FILE_LOAD := 0
    static HERO_DEFS := 1
    static UPGRADE_DEFS := 2
    static EFFECT_DEFS := 3
    static EFFECT_KEY_DEFS := 4
    static DEFS_LOAD_SUCCESS := 5

    CachedHeroDefines := ""
    HeroDefines := ""
    TimerFunctions := {}
    Status := ""

    Start(params*)
    {
        if (this.CheckForDefsChange(params*))
        {
            if (params.Count())
                params[2] := true
            else
                params := [true, true]
        }
        fncToCallOnTimer := ObjBindMethod(this, "ReadOrCreateHeroDefs", params*)
        this.TimerFunctions[fncToCallOnTimer] := 10
        for k, v in this.TimerFunctions
        SetTimer, %k%, %v%, 0
    }

    PauseOrResume(value)
    {
        value := value ? "On" : "Off"
        for k, v in this.TimerFunctions
            SetTimer, %k%, %value%
    }

    Stop()
    {
        for k, v in this.TimerFunctions
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
        static fileName := "cached_definitions.json"

        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath)
        if (settings.LastCachedPath == "" OR !FileExist(settings.LastCachedPath))
        {
            exePath := % g_UserSettings[ "InstallPath" ] ; Steam
            cachedPath := % exePath . "\..\IdleDragons_Data\StreamingAssets\downloaded_files\" . fileName
            if (!FileExist(cachedPath) AND !silent) ; Try to find cached_definitions folder
                FileSelectFile, cachedPath, 1, % "\..\..\..\..\IdleChampions\IdleDragons_Data\StreamingAssets\downloaded_files\" . fileName, %fileName%, %fileName%
            settings.LastCachedPath := cachedPath
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        else
            cachedPath := settings.LastCachedPath
        return cachedPath
    }

    ; Check if last known definitions from HeroDefines.json match cached_definitions.json
    CheckForDefsChange(params*)
    {
        this.UpdateLoading("Checking for new definitions...")
        settings := g_BrivGemFarm_LevelUp.Settings
        fileName := this.FindCachedDefinitionsPath(params*)
        FileRead, contents, %fileName%
        RegExMatch(contents, "(\d)+", checksum, InStr(contents, "checksum")) ; Check file checksum
        if (settings.LastChecksum == "" OR settings.LastChecksum != checksum)
        {
            settings.LastChecksum := checksum
            tableChecksums := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetTableChecksums(contents) ; Check table_checksums
            if (settings.LastTableChecksums == "" OR !IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(settings.LastTableChecksums, tableChecksums))
            {
                this.UpdateLoading("New definitions found")
                settings.LastTableChecksums := tableChecksums
                g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
                this.CachedHeroDefines := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetHeroDefs(contents)
                return true
            }
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        }
        if (params.Count())
        {
            if (!params[2])
                this.UpdateLoading()
            else
                this.CachedHeroDefines := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetHeroDefs(contents)
        }
        return false
    }

    /*  CreateHeroDefs - Create definitions with upgrade levels from cached_definitions.json
        Parameters:      silent: bool - If true, doesn't prompt the dialog to choose the file if not found

        Returns:         object - Definitions used to build the GUI
    */
    CreateHeroDefs(silent := true)
    {
        static state := IC_BrivGemFarm_LevelUp_DefinesLoader.FILE_LOAD
        static index := 0
        static maxIndex := 0
        static defs := ""
        static trimmedHeroDefs := ""

        if (state == IC_BrivGemFarm_LevelUp_DefinesLoader.FILE_LOAD)
        {
            this.UpdateLoading("Loading new definitions...")
            defs := this.CachedHeroDefines
            if (defs == "")
                return IC_BrivGemFarm_LevelUp_DefinesLoader.DEFS_LOAD_FAIL
            state := IC_BrivGemFarm_LevelUp_DefinesLoader.HERO_DEFS
            return IC_BrivGemFarm_LevelUp_DefinesLoader.HERO_DEFS
        }
        if (state == IC_BrivGemFarm_LevelUp_DefinesLoader.HERO_DEFS)
        {
            this.UpdateLoading("Loading new definitions... Loading heroes")
            trimmedHeroDefs := {}
            ; Hero definitions
            hero_defines := {}
            for k, v in defs.hero_defines
            {
                if (RegExMatch(v.name, "Y\d+E\d+") OR ErrorLevel != 0) ; skip placeholder
                    continue
                obj := {name:v.name, seat_id:v.seat_id}
                if (v.properties.allow_time_gate != "" AND v.properties.allow_time_gate != -1)
                    obj.allow_time_gate := v.properties.allow_time_gate
                hero_defines[v.id] := obj
            }
            trimmedHeroDefs.hero_defines := hero_defines
            state := IC_BrivGemFarm_LevelUp_DefinesLoader.UPGRADE_DEFS
            return IC_BrivGemFarm_LevelUp_DefinesLoader.UPGRADE_DEFS
        }
        if (state == IC_BrivGemFarm_LevelUp_DefinesLoader.UPGRADE_DEFS)
        {
            ; Upgrade definitions
            if (index == 0)
            {
                maxIndex := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter.Length()
                this.UpdateLoading("Loading new definitions... Loading upgrades " . index . "/" . maxIndex)
            }
            while (index < maxIndex)
            {
                for k, v in defs[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter[++index]]
                {
                    if (v.required_upgrade_id == 9999)
                        continue
                    heroDef := trimmedHeroDefs.hero_defines[v.hero_id]
                    if (!heroDef.HasKey("upgrades"))
                        heroDef.upgrades := {}
                    obj := {required_level:v.required_level}
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
                    heroDef.upgrades[v.id] := obj
                }
                this.UpdateLoading("Loading new definitions... Loading upgrades " . index . "/" . maxIndex)
                return IC_BrivGemFarm_LevelUp_DefinesLoader.UPGRADE_DEFS
            }
            state := IC_BrivGemFarm_LevelUp_DefinesLoader.EFFECT_DEFS, index := 0, maxIndex := 0
        }
        if (state == IC_BrivGemFarm_LevelUp_DefinesLoader.EFFECT_DEFS)
        {
            ; Effect definitions
            if (index == 0)
            {
                trimmedHeroDefs.effect_defines := {}
                maxIndex := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectFilter.Length()
                this.UpdateLoading("Loading new definitions... Loading upgrade effects" . index . "/" . maxIndex)
            }
            while (index < maxIndex)
            {
                for k, v in defs[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectFilter[++index]]
                {
                    id := v.id
                    v.Delete("id")
                    v.Delete("graphic_id")
                    for k1, v1 in ["description", "effect_keys", "flavour_text", "properties", "requirements"]
                    {
                        if (v.HasKey(v1) AND (v[v1] == "" OR v[v1].Count() == 0))
                            v.Delete(v1)
                    }
                    trimmedHeroDefs.effect_defines[id] := v
                }
                this.UpdateLoading("Loading new definitions... Loading upgrade effects " . index . "/" . maxIndex)
                return IC_BrivGemFarm_LevelUp_DefinesLoader.EFFECT_DEFS
            }
            state := IC_BrivGemFarm_LevelUp_DefinesLoader.EFFECT_KEY_DEFS, index := 0, maxIndex := 0
        }
        ; Effect key definitions
        trimmedHeroDefs.effect_key_defines := {}
        for k, v in defs.effect_key_defines
        {
            id := v.id
            v.Delete("id")
            for k1, v1 in ["descriptions", "key", "owner", "param_names", "properties"]
            {
                if (v.HasKey(v1) AND (v[v1] == "" OR v[v1].Count() == 0))
                    v.Delete(v1)
            }
            trimmedHeroDefs.effect_key_defines[id] := v
        }
        lastUpdateString := "Last updated: " . A_YYYY . "/" A_MM "/" A_DD " at " A_Hour . ":" A_Min
        Status := lastUpdateString
        g_BrivGemFarm_LevelUp.UpdateLastUpdated(lastUpdateString, true)
        this.HeroDefines := trimmedHeroDefs
        this.CachedHeroDefines := "", defs := "", trimmedHeroDefs := "", state := IC_BrivGemFarm_LevelUp_DefinesLoader.FILE_LOAD
        return IC_BrivGemFarm_LevelUp_DefinesLoader.DEFS_LOAD_SUCCESS
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
            if (!create)
                this.HeroDefines := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath)
            heroDefsLoaded := create OR !IsObject(this.HeroDefines) ? g_DefinesLoader.CreateHeroDefs(silent) : IC_BrivGemFarm_LevelUp_DefinesLoader.DEFS_LOAD_SUCCESS
            if (heroDefsLoaded == IC_BrivGemFarm_LevelUp_DefinesLoader.DEFS_LOAD_FAIL AND silent == true)
            {
                this.UpdateLoading("WARNING: Could not load Hero definitions. Click on 'load definitions' to resume.`nThe location of this file should be in your game folder.")
                this.Stop()
                g_BrivGemFarm_LevelUp.OnHeroDefinesFailed()
                return
            }
            else if (heroDefsLoaded != IC_BrivGemFarm_LevelUp_DefinesLoader.DEFS_LOAD_SUCCESS)
            {
                this.PauseOrResume(1)
                return
            }
            this.PauseOrResume(0)
            state := 1
        }
        this.Stop()
        if (state == 1)
        {
            for k, v in this.HeroDefines.hero_defines
                IC_BrivGemFarm_LevelUp_Seat.AddChampionData(new IC_BrivGemFarm_LevelUp_HeroData(k, v))
            IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished()
            if (create)
                g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath, this.HeroDefines)
        }
    }
}

; Class that contains the data of a champion
Class IC_BrivGemFarm_LevelUp_HeroData
{
    UpgradesList := ""

    __New(id, heroData)
    {
        this.ID := id
        this.Name := heroData.name
        this.Seat_id := heroData.seat_id
        this.Allow_time_gate := heroData.allow_time_gate
        this.Upgrades := this.BuildUpgrades(heroData.upgrades)
    }

    BuildUpgrades(data)
    {
        upgrades := {}
        maxUpgradeLevelW := 0
        for upgradeKey, upgrade in data
        {
            level := upgrade.required_level
            if (level == "")
                continue
            maxUpgradeLevelW := Max(maxUpgradeLevelW, 2 * StrLen(level))
        }
        listContents := ""
        specializations := {}
        for upgradeKey, upgrade in data
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
            if (upgrade.effect)
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
                    s := "++ " . data[split[3]].name . " + " split[2] . "%"
                else if (split[1] == "increase_revive_effect_post_stack")
                    s := "++ " . data[split[3]].name . " + " split[2] . "%"
            }
            p := "" ; Longest number has no padding before ':'
            Loop, % maxUpgradeLevelW - 2 * StrLen(level) + StrLen(level) - StrLen(levelStr)
                p .= " "
            listContents .= levelStr . p . ": " . s . "|"
        }
        Sort, listContents, N D|
        this.UpgradesList := RegExReplace(listContents, "((\d)+)(\.)(\d)+", "$1  ")
        return upgrades
    }
}

; Modified JSON class with parent/child key filters
Class IC_BrivGemFarm_LevelUp_CachedDefinitionsReader extends JSON
{
    static TableFilter := "table_checksums"
    static HeroFilter := "hero_defines"
    static UpgradeFilter := ""
    static EffectFilter := ""
    static EffectKeyFilter := "effect_key_defines"
    static AttackFilter := "attack_defines"

    parse(script, js := false, filter := "")  {
		if jsObject := this.verify(script)
			return js ? jsObject : this._CreateObject(jsObject, filter)
		else
			return false
	}

    _CreateObject(jsObject, filter := "") {
		if !IsObject(jsObject)
			return jsObject

		result := jsObject.IsArray()

		if (result = "")
			return jsObject
		else if (result = -1) {
			object := []

			Loop % jsObject.length
				object[A_Index] := this._CreateObject(jsObject[A_Index - 1])
		}
		else if (result = 0) {
			object := {}
			keys := jsObject.GetKeys()

            if (filter == "")
            {
			    Loop % keys.length
				    k := keys[A_Index - 1], object[k] := this._CreateObject(jsObject[k])
		    }
		    else if (IsObject(filter))
		    {
		        for k, v in filter
                    object[k] := this._CreateObject(jsObject[k], v)
		    }
		    else
                 object[filter] := this._CreateObject(jsObject[filter])
		}

		return object
	}

    ; Filter table_checksums from cachedDefinitions.json
	GetTableChecksums(ByRef script)
	{
	    jsObject := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpdateFilters(script)
	    filter := {}, childrenFilter := {}
	    childrenFilter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.HeroFilter] := ""
	    childrenFilter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectKeyFilter] := ""
	    childrenFilter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.AttackFilter] := ""
	    for k, v in IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter
	        childrenFilter[v] := ""
	    for k, v in IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectFilter
	        childrenFilter[v] := ""
	    filter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.TableFilter] := childrenFilter
	    return IC_BrivGemFarm_LevelUp_CachedDefinitionsReader._CreateObject(jsObject, filter)[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.TableFilter]
	}

	; Filter relevant keys from cachedDefinitions.json
	GetHeroDefs(ByRef script)
	{
	    jsObject := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpdateFilters(script)
	    filter := {}
	    filter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.HeroFilter] := ""
	    filter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectKeyFilter] := ""
	    filter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.AttackFilter] := ""
	    for k, v in IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter
	        filter[v] := ""
	    for k, v in IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectFilter
	        filter[v] := ""
	    return IC_BrivGemFarm_LevelUp_CachedDefinitionsReader._CreateObject(jsObject, filter)
	}

    ; Update key filters from cachedDefinitions.json
	UpdateFilters(ByRef script)
	{
	    jsObject := this.verify(script)
	    keys := jsObject.GetKeys()
	    keysObj := {}
	    Loop % keys.length
		    k := keys[A_Index - 1], keysObj[k] := k
	    upgradeFilter := [], effectFilter := []
        for k in keysObj
        {
            if (RegExMatch(k, "upgrade_defines_(\d+)", upgradeKey))
                upgradeFilter.Push(upgradeKey)
            else if (RegExMatch(k, "effect_defines_(\d+)", upgradeKey))
                effectFilter.Push(upgradeKey)
        }
        IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter := upgradeFilter
        IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.EffectFilter := effectFilter
        return jsObject
	}
}