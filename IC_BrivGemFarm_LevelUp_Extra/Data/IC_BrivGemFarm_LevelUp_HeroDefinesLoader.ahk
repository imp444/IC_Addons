; Functions used to load hero definitions into the GUI
class IC_BrivGemFarm_LevelUp_HeroDefinesLoader
{
    static cachedFileName := "cached_definitions.json"
    static rootCachedPath := "IdleChampions\IdleDragons_Data\StreamingAssets\downloaded_files\"
    static DEFS_LOAD_FAIL := -1
    static FILE_LOAD := 0
    static TEXT_DEFS := 1
    static HERO_DEFS := 2
    static ATTACK_DEFS := 3
    static UPGRADE_DEFS := 4
    static EFFECT_DEFS := 5
    static EFFECT_KEY_DEFS := 6
    static DEFS_LOAD_SUCCESS := 7
    static HERO_DATA_FINISHED := 8

    CachedHeroDefines := ""
    HeroDefines := ""
    TimerFunctions := {}
    Status := ""
    CNETime := ""

    Start(params*)
    {
        if (this.CheckForDefsChange(params*) OR !FileExist(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath))
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

    ; Returns the path to cached_definitions.
    ; Parameters: - silent:bool - If false, prompts a Yes/No dialog if new path / path not found
    GetCachedDefinitionsPath(silent := true)
    {
        lastCachedPath := g_BrivGemFarm_LevelUp.Settings.LastCachedPath
        if (lastCachedPath == "" OR !FileExist(lastCachedPath) OR !silent)
            cachedPath := this.FindCachedDefinitionsPath(silent)
        else
            cachedPath := lastCachedPath
        return cachedPath
    }

    ; Find cached_definitions path.
    ; Saves the last known valid path
    ; Parameters: - silent:bool - If false, prompts a Yes/No dialog if new path / path not found
    FindCachedDefinitionsPath(silent := true)
    {
        fileName := this.cachedFileName
        rootFolder := this.rootCachedPath
        if (silent)
            cachedPath := this.SearchForCachedDefinitionsPath(fileName)
        else ; Clicked on "Load Definitions"
        {
            lastCachedPath := g_BrivGemFarm_LevelUp.Settings.LastCachedPath
            MsgBox, 4, , Load file from new location?
            IfMsgBox, Yes
                FileSelectFile, cachedPath, 1, % rootFolder, %fileName%, %fileName%
            IfMsgBox, No
                return lastCachedPath
            if (cachedPath == "")
                return lastCachedPath
        }
        settings := g_BrivGemFarm_LevelUp.Settings
        settings.LastCachedPath := cachedPath
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
        return cachedPath
    }

    ; Returns the name of the folder that contains the game"s .exe
    GetPlatForm(exePath)
    {
        if InStr(exePath, "Steam\steamapps\common\IdleChampions")
            platform := "Steam"
        else if (InStr(exePath, "Epic Games\IdleChampions") || InStr(exePath, "com.epicgames.launcher"))
            platform := "Epic Games"
        else if InStr(exePath, "Idle Champions\IdleChampions")
            platform := "Idle Champions"
        return platform
    }

    ; Returns the path to cached_definitions for Steam, EG or CNE.
    SearchForCachedDefinitionsPath(fileName)
    {
        rootFolder := this.rootCachedPath
        exePath := % g_UserSettings[ "InstallPath" ]
        platform := this.GetPlatForm(exePath)
        if platform in Steam,Idle Champions
        {
            subPattern := (platform == "Steam" ? "common\" : "Idle Champions\") . rootFolder
            pattern := exePath . "\..\..\" . rootFolder . fileName
        }
        else
        {
            return ""
;            wildPattern := "\*" . "Program Files"
;            Loop Files, % wildPattern, D
;                epicDir := A_LoopFileLongPath
;            pattern := epicDir . "\" . fileName
;            subPattern := "Epic Games\" . rootFolder
        }
        return this.SearchForFile(pattern, subPattern)
    }

    ; Returns the file path matching pattern and subPatterns* parameters.
    SearchForFile(pattern, subPatterns*)
    {
        this.UpdateLoading(this.Status . " Searching for " . pattern)
        Loop Files, % pattern, R  ; Recurse into subfolders.
        {
            for k, v in subPatterns
                if (InStr(A_LoopFileLongPath, v))
                    return %A_LoopFileLongPath%
        }
    }

    ; Check if last known definitions from HeroDefines.json match cached_definitions.json
    CheckForDefsChange(params*)
    {
        this.UpdateLoading("Checking for new definitions...")
        fileName := this.GetCachedDefinitionsPath(params*)
        fileExists := FileExist(fileName)
        if (fileExists)
        {
            FileRead, contents, %fileName%
            RegExMatch(contents, "(\d)+", checksum, InStr(contents, "checksum"))
            ; Update server time
            RegExMatch(contents, "(\d)+", current_time, InStr(contents, """current_time"":"))
            this.CNETime := current_time
            IC_BrivGemFarm_LevelUp_ToolTip.UpdateDefsCNETime(current_time)
            ; Check file checksum
            settings := g_BrivGemFarm_LevelUp.Settings
            if (settings.LastChecksum == "" OR settings.LastChecksum != checksum)
            {
                settings.LastChecksum := checksum
                ;tableChecksums := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetTableChecksums(contents) ; Check table_checksums
                if (settings.LastTableChecksums == "" OR !IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(settings.LastTableChecksums, tableChecksums))
                {
                    this.UpdateLoading("New definitions found")
                    ;settings.LastTableChecksums := tableChecksums
                    g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
                    this.CachedHeroDefines := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetHeroDefs(contents)
                    return true
                }
                g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Component.SettingsPath, settings)
            }
        }
        if (params.Count())
        {
            if (!params[2])
                this.UpdateLoading()
            else if (fileExists)
                this.CachedHeroDefines := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetHeroDefs(contents)
        }
        return false
    }

    /*  CreateHeroDefs - Create definitions with upgrade levels from cached_definitions.json

        Returns:         object - Definitions used to build the GUI
    */
    CreateHeroDefs()
    {
        static state := IC_BrivGemFarm_LevelUp_HeroDefinesLoader.FILE_LOAD
        static index := 0
        static maxIndex := 0
        static defs := ""
        static trimmedHeroDefs := ""

        if (state == this.FILE_LOAD)
        {
            this.UpdateLoading("Loading new definitions...")
            defs := this.CachedHeroDefines
            if (defs == "")
            {
                fileName := this.GetCachedDefinitionsPath()
                if (!FileExist(fileName))
                    return this.DEFS_LOAD_FAIL
                FileRead, contents, %fileName%
                defs := this.CachedHeroDefines := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.GetHeroDefs(contents)
                if (defs == "")
                    return this.DEFS_LOAD_FAIL
            }
            state := this.TEXT_DEFS
            return this.TEXT_DEFS
        }
        if (state == this.TEXT_DEFS)
        {
            this.UpdateLoading("Loading new definitions... Loading text")
            trimmedHeroDefs := {}
            ; Text definitions
            text_defines := {}
            for k, v in defs.text_defines
            {
                key := v.key
                v.Delete("id")
                v.Delete("key")
                text_defines[key] := v
            }
            trimmedHeroDefs.text_defines := text_defines
            state := this.HERO_DEFS
            return this.HERO_DEFS
        }
        if (state == this.HERO_DEFS)
        {
            this.UpdateLoading("Loading new definitions... Loading heroes")
            ; Hero definitions
            hero_defines := {}
            for k, v in defs.hero_defines
            {
                if (RegExMatch(v.name, "Y\d+E\d+") OR ErrorLevel != 0) ; skip placeholder
                    continue
                obj := {name:v.name, seat_id:v.seat_id, ultimate_attack_id:v.ultimate_attack_id}
                if (v.properties.allow_time_gate != "" AND v.properties.allow_time_gate != -1)
                    obj.allow_time_gate := v.properties.allow_time_gate
                hero_defines[v.id] := obj
            }
            trimmedHeroDefs.hero_defines := hero_defines
            state := this.ATTACK_DEFS
            return this.ATTACK_DEFS
        }
        if (state == this.ATTACK_DEFS)
        {
            this.UpdateLoading("Loading new definitions... Loading attacks")
            ; Text definitions
            attack_defines := {}
            for k, v in defs.attack_defines
            {
                obj := {}
                for k1, v1 in ["description", "long_description", "name"]
                    if (v.HasKey(v1) AND v[v1] != "")
                        obj[v1] := v[v1]
                attack_defines[v.id] := obj
            }
            trimmedHeroDefs.attack_defines := attack_defines
            state := this.UPGRADE_DEFS
            return this.UPGRADE_DEFS
        }
        if (state == this.UPGRADE_DEFS)
        {
            ; Upgrade definitions
            if (index == 0)
            {
                trimmedHeroDefs.upgrade_defines := {}
                maxIndex := IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter.Length()
                this.UpdateLoading("Loading new definitions... Loading upgrades " . index . "/" . maxIndex)
            }
            while (index < maxIndex)
            {
                for k, v in defs[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.UpgradeFilter[++index]]
                {
                    hero_id := v.hero_id, required_level := v.required_level
                    obj := {hero_id:hero_id, required_level:required_level}
                    heroDef := trimmedHeroDefs.hero_defines[hero_id]
                    if (v.name != "")
                        obj.name := v.name
                    if (v.upgrade_type != "")
                        obj.upgrade_type := v.upgrade_type
                    if ((effect := v.effect) != "")
                    {
                        if (RegExMatch(effect, "effect_string")) ; Convert string to Object
                        {
                            fixedEffect := {}, nextPos := 1
                            regexChar := "\\u([0-9a-f]+)"
                            while (RegExMatch(effect, "O)" . regexChar, matchO))
                            {
                                char := Chr("0x" . matchO[1])
                                effect := StrReplace(effect, matchO[0], char,, 1)
                            }
                            regex := "O)""\b([^""]+)""\B:(?:\s?)+""?([^""]+)(?:""|,|})\B"
                            while (nextPos := RegExMatch(effect, regex, matchO, nextPos) + matchO.len())
                                fixedEffect[matchO.value(1)] := matchO.value(2)
                            v.effect := fixedEffect
                        }
                        obj.effect := v.effect
                    }
                    if (v.specialization_name)
                        obj.specialization_name := v.specialization_name
                    if (v.specialization_description)
                        obj.specialization_description := v.specialization_description
                    if (v.tip_text)
                        obj.tip_text := v.tip_text
                    trimmedHeroDefs.upgrade_defines[v.id] := obj
                    if (required_level == 9999)
                        continue
                    if (heroDef.tempUpgrades.HasKey(required_level))
                    {
                        if (IsObject(heroDef.tempUpgrades[required_level]))
                            heroDef.tempUpgrades[required_level].Push(v.id)
                        else
                            heroDef.tempUpgrades[required_level] := [heroDef.tempUpgrades[required_level], v.id]
                    }
                    else
                        heroDef.tempUpgrades[required_level] := v.id
                }
                this.UpdateLoading("Loading new definitions... Loading upgrades " . index . "/" . maxIndex)
                return this.UPGRADE_DEFS
            }
            ; Sorted upgrades by required_level
            for k, v in trimmedHeroDefs.hero_defines
            {
                upgrades := []
                for k1, v1 in v.tempUpgrades
                {
                    if (IsObject(v1))
                        upgrades.Push(v1*)
                    else
                        upgrades.Push(v1)
                }
                v.upgrades := upgrades
                v.Delete("tempUpgrades")
            }
            state := this.EFFECT_DEFS, index := 0, maxIndex := 0
        }
        if (state == this.EFFECT_DEFS)
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
                        if (v.HasKey(v1) AND (v[v1] == "" OR v[v1].Count() == 0))
                            v.Delete(v1)
                    trimmedHeroDefs.effect_defines[id] := v
                }
                this.UpdateLoading("Loading new definitions... Loading upgrade effects " . index . "/" . maxIndex)
                return this.EFFECT_DEFS
            }
            state := this.EFFECT_KEY_DEFS, index := 0, maxIndex := 0
        }
        ; Effect key definitions
        trimmedHeroDefs.effect_key_defines := {}
        for k, v in defs.effect_key_defines
        {
            key := v.key
            v.Delete("id")
            v.Delete("key")
            for k1, v1 in ["descriptions", "owner", "param_names", "properties"]
                if (v.HasKey(v1) AND (v[v1] == "" OR v[v1].Count() == 0))
                    v.Delete(v1)
            trimmedHeroDefs.effect_key_defines[key] := v
        }
        FormatTime, timeStr, % A_Now
        lastUpdateString := "Last updated: " . timeStr
        Status := lastUpdateString
        g_BrivGemFarm_LevelUp.UpdateLastUpdated(lastUpdateString, true)
        this.HeroDefines := trimmedHeroDefs
        this.CachedHeroDefines := "", defs := "", trimmedHeroDefs := "", state := this.FILE_LOAD
        return this.DEFS_LOAD_SUCCESS
    }

    /*  ReadOrCreateHeroDefs - Read/Write definitions from/to HeroDefines.json
        Parameters:            silent: bool - If true, doesn't prompt the dialog to choose the file if not found
                               create: bool - If true, force new definitions

        Returns:
    */
    ReadOrCreateHeroDefs(silent := true, create := false)
    {
        static state := IC_BrivGemFarm_LevelUp_HeroDefinesLoader.FILE_LOAD

        this.PauseOrResume(0)
        if (state == this.FILE_LOAD)
        {
            if (!create)
                this.HeroDefines := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath)
            heroDefsLoaded := create OR !IsObject(this.HeroDefines) ? g_DefinesLoader.CreateHeroDefs() : this.DEFS_LOAD_SUCCESS
            if (heroDefsLoaded == this.DEFS_LOAD_FAIL)
            {
                if (this.HeroDefines == "")
                    this.UpdateLoading("WARNING: Could not load cached_definitions. Click on 'load definitions' to resume.`nThis file should be located in your game folder under: " . this.rootCachedPath)
                else
                    this.UpdateLoading()
                this.Stop()
                g_BrivGemFarm_LevelUp.OnHeroDefinesFailed()
                return
            }
            else if (heroDefsLoaded != this.DEFS_LOAD_SUCCESS)
            {
                this.PauseOrResume(1)
                return
            }
            state := this.DEFS_LOAD_SUCCESS
            this.PauseOrResume(1)
            return
        }
        if (state == this.DEFS_LOAD_SUCCESS)
        {
            g_HeroDefines.Init(this.HeroDefines)
            IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished()
            state := this.HERO_DATA_FINISHED
            this.PauseOrResume(1)
            return
        }
        if (state == this.HERO_DATA_FINISHED)
        {
            this.Stop()
            state := this.FILE_LOAD
            if (create)
                this.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Functions.HeroDefsPath, this.HeroDefines)
        }
    }

    ;Writes beautified json (object) to a file (FileName)
    WriteObjectToJSON(FileName, ByRef object)
    {
        objectJSON := JSON.stringify( object )
        objectJSON := JSON.Beautify( objectJSON )
        FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%, UTF-8
        return
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
    static TextFilter := "text_defines"

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
                {
                    if (jsObject[k] != "")
                        object[k] := this._CreateObject(jsObject[k], v)
                }
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
        childrenFilter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.TextFilter] := ""
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
        filter[IC_BrivGemFarm_LevelUp_CachedDefinitionsReader.TextFilter] := ""
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