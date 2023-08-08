; Class that allows to group controls under a GroupBox control.
Class IC_BrivGemFarm_LevelUp_GUI_Group
{
    Controls := []
    GroupID := 0
    Height := 0
    Width := 0
    XSpacing := 10
    YSpacing := 10
    YTitleSpacing := 20
    XSection := 10
    YSection := 10
    Hidden := false

    ; Creates a new GroupBox.
    ; Parameters: - name:str - The name/reference of the group.
    ;             - title:str - The title of the control that will appear on the outline.
    ;             - previous:str - The reference control that is used to position the new group.
    ;             - tabS:bool - If true, adds an x offset to this group from the previous control equal to XSection.
    ;             - newLine:bool - If true, position the group under the previous control.
    __New(name, title := "", previous := "BGFLU_DefaultSettingsGroup", tabS := true, newLine := true)
    {
        global
        this.GroupID := name
        GuiControlGet, previousPos, ICScriptHub:Pos, %previous%
        local groupX := previousPosX + (tabS ? this.XSection : 0) + (newLine ? 0 : previousPosW)
        local options := "Section w0 h10 v" . name . " x" . groupX
        local ySpacing := previousPosY + previousPosH + (newLine ? this.YSpacing : 0)
        options .= " y" . (newLine ? ySpacing : "s")
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, %options% , %title%
        Gui, ICScriptHub:Font, w400
    }

    ; Creates and adds a control to the GroupBox.
    ; Parameters: - controlID:str - The name/reference of the control.
    ;             - controlType:str - The type of the control.
    ;             - options:str - Options to apply to the control. X/Y positionals override the default values.
    ;             - text:str - The initial text of the control.
    ;             - newLine:bool - If true, position the control under the previous ones.
    AddControl(controlID, controlType := "", options := "", text := "", newLine := false)
    {
        global
        if (controlType != "")
        {
            if controlType in ComboBox,DropDownList,Edit,ListBox
                GUIFunctions.UseThemeTextColor("InputBoxTextColor")
            if (!RegExMatch(options, "x(\d+|\+|\-|m|p|s[^\s])"))
            {
                if (newLine)
                    options .= " xs+" . this.XSection
                else
                    options .= " x+" . this.XSpacing
            }
            if (!RegExMatch(options, "y(\d+|\+|\-|m|p|s[^\s])"))
            {
                if (this.Controls.Length() == 0)
                    options .= " ys+" . this.YTitleSpacing
                else if (newLine)
                    options .= " y+" . this.YSpacing
            }
            options .= " v" . controlID
            Gui, ICScriptHub:Add, %controlType%, %options%, % text
            GUIFunctions.UseThemeTextColor()
        }
        this.Controls.Push(controlID)
    }

    ; Creates and adds a CheckBox control to the GroupBox.
    ; The function BGFLU_CheckBoxEvent handles Checkbox events.
    AddCheckBox(controlID, options := "", text := "", newLine := false)
    {
        options .= " gBGFLU_CheckBoxEvent"
        return this.AddControl(controlID, "CheckBox", options, text, newLine)
    }

    ; Creates and adds a Edit control to the GroupBox.
    ; The function BGFLU_EditEvent handles Edit events.
    AddEdit(controlID, options := "", text := "", newLine := false)
    {
        options .= " gBGFLU_EditEvent"
        return this.AddControl(controlID, "Edit", options, text, newLine)
    }

    ; Show the GroupBox outline and its controls.
    Show()
    {
        for k, v in this.Controls
            GuiControl, ICScriptHub:Show, %v%
        controlID := this.GroupID
        GuiControl, ICScriptHub:Show, %controlID%
        this.Hidden := false
    }

    ; Hide the GroupBox outline and its controls.
    Hide()
    {
        for k, v in this.Controls
            GuiControl, ICScriptHub:Hide, %v%
        controlID := this.GroupID
        GuiControl, ICScriptHub:Hide, %controlID%
        this.Hidden := true
    }

    ; Moves the GroupBox outline and its controls to a new position.
    ; Parameters: - x:int - New X postion of the GroupBox.
    ;             - y:int - New Y postion of the GroupBox.
    Move(x := "", y := "")
    {
        controlID := this.GroupID
        GuiControlGet, oldPos, ICScriptHub:Pos, %controlID%
        x := x == "" ? oldPosX : x
        y := y == "" ? oldPosY : y
        if (x == oldPosX AND y == oldPosY)
            return
        GuiControl, ICScriptHub:Move, %controlID%, x%x% y%y%
        ; Bug when using Move in a Tab control
        GuiControlGet, bugPos, ICScriptHub:Pos, %controlID%
        xFixBug := 2 * x - bugPosX
        yFixBug := 2 * y - bugPosY
        xOffset := xFixBug - oldPosX
        yOffset := yFixBug - oldPosY
        GuiControl, ICScriptHub:MoveDraw, %controlID%, x%xFixBug% y%yFixBug%
        for k, v in this.Controls
        {
            GuiControlGet, oldPos, ICScriptHub:Pos, %v%
            newX := oldPosX + xOffset
            newY := oldPosY + yOffset
            GuiControl, ICScriptHub:MoveDraw, %v%, x%newX% y%newY%
        }
    }

    ; Returns the control with the lowest Y position within the GroupBox.
    ; Ignores controls that have been previousy hidden.
    GetLowestControl()
    {
        yMax := 0
        lowest := ""
        for k, v in this.Controls
        {
            if (IC_BrivGemFarm_LevelUp_GUI.GroupsByName[v].Hidden)
                continue
            GuiControlGet, pos, ICScriptHub:Pos, %v%
            if (posY + posH > yMax)
            {
                yMax := posY + posH
                lowest := v
            }
        }
        return lowest
    }

    ; Returns the control with the furthest X position within the GroupBox.
    ; Ignores controls that have been previousy hidden.
    GetRightMostControl()
    {
        xMax := 0
        rightMost := ""
        for k, v in this.Controls
        {
            if (IC_BrivGemFarm_LevelUp_GUI.GroupsByName[v].Hidden)
                continue
            GuiControlGet, pos, ICScriptHub:Pos, %v%
            if (posX + posW > xMax)
            {
                xMax := posX + posW
                rightMost := v
            }
        }
        return rightMost
    }

    ; Calculates the size of this GroupBox's outline that contours all of its controls.
    AutoResize()
    {
        lowest := this.GetLowestControl()
        GuiControlGet, posL, ICScriptHub:Pos, %lowest%
        rightMost := this.GetRightMostControl()
        GuiControlGet, posR, ICScriptHub:Pos, %rightMost%
        controlID := this.GroupID
        GuiControlGet, posS, ICScriptHub:Pos, %controlID%
        newHeight := posLY + posLH - posSY + this.YSection
        newWidth := posRX + posRW - posSX + this.XSection
        this.UpdateSize(newHeight, newWidth)
    }

    ; Resizes this GroupBox's outline.
    ; Parameters: - newHeight:int - New height of the GroupBox.
    ;             - newWidth:int - New width of the GroupBox.
    UpdateSize(newHeight := "", newWidth := "")
    {
        controlID := this.GroupID
        if (newHeight != "")
            this.Height := newHeight
        else
            newHeight := this.Height
        if (newWidth != "")
            this.Width := newWidth
        else
            newWidth := this.Width
        GuiControl, ICScriptHub:Move, %controlID%, h%newHeight% w%newWidth%
    }
}