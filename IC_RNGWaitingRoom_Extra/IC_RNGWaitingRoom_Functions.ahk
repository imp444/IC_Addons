; Functions that are used by this Addon.
class IC_RNGWaitingRoom_Functions
{
    static SettingsPath := A_LineFile . "\..\RNGWaitingRoom_Settings.json"

    ; Adds IC_RNGWaitingRoom_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_RNGWaitingRoom_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ; Returns the text to append for values not equal to 1.
    ; Parameters: - value:int - Value of anything countable.
    Plural(value)
    {
        return value == 1 ? "" : "s"
    }

    ReadResets()
    {
        return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.StatHandler.Resets.Read()
    }

    ; Ellywick

    class EllywickHandlerHandler
    {
        LoopTimer := ObjBindMethod(this, "MainLoop")
        GemCardsNeeded := 0
        MaxRedraws := 0
        WaitForAllCards := false
        WaitedForEllywickThisRun := false
        Redraws := 0
        UltimateTimer := ObjBindMethod(this, "CheckUltimateUsed")
        UsedUlt := false

        __New(gemCardsNeeded := 1, maxRedraws := 1, wait := false)
        {
            this.GemCardsNeeded := gemCardsNeeded
            this.MaxRedraws := maxRedraws
            this.WaitForAllCards := wait
            this.WaitedForEllywickThisRun := false
        }

        UpdateGlobalSettings()
        {
            this.GemCardsNeeded := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemCards" ]
            this.MaxRedraws := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ]
            this.WaitForAllCards := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemWaitFor5Draws" ]
            if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ])
                this.Start()
            else
                this.Stop()
        }

        Start()
        {
            fncToCallOnTimer := this.LoopTimer
            SetTimer, %fncToCallOnTimer%, 20, 0
            this.MainLoop()
        }

        Stop()
        {
            fncToCallOnTimer := this.LoopTimer
            SetTimer, %fncToCallOnTimer%, Off
            this.Reset()
        }

        Reset()
        {
            this.WaitedForEllywickThisRun := false
            this.Redraws := 0
            fncToCallOnTimer := this.UltimateTimer
            SetTimer, %fncToCallOnTimer%, Off
            this.UsedUlt := false
        }

        MainLoop()
        {
            if (g_SF.Memory.ReadResetting() || g_SF.Memory.ReadCurrentZone() == "")
                return
            if (this.WaitedForEllywickThisRun)
            {
                ; Use ultimate to redraw cards if Ellywick doesn't have any gem cards.
                if (this.GetNumGemCards() == 0 && !this.UsedUlt && this.GetNumCards() == 5 && this.IsEllywickUltReady())
                    this.UseEllywickUlt()
            }
            else if (this.ShouldDrawMoreCards())
            {
                numCards := this.GetNumCards()
                ; Use ultimate if it's not on cooldown and there are redraws left.
                if (this.RedrawsLeft)
                {
                    shouldRedraw := this.ShouldRedraw()
                    if (!this.UsedUlt && shouldRedraw && this.IsEllywickUltReady())
                        this.UseEllywickUlt()
                    if (!shouldRedraw)
                        g_SharedData.RNGWR_SetStatus("Waiting for card #" . (numCards + 1))
                }
                else if (!this.WaitForAllCards && numCards == 5 && this.Redraws == 0 || !this.WaitForAllCards && this.Redraws || this.WaitForAllCards && numCards == 5 && !this.RedrawsLeft)
                {
                    this.WaitedForEllywickThisRun := true
                    g_SharedData.RNGWR_SetStatus(this.GetResultString())
                    bonusGems := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
                    g_SharedData.RNGWR_UpdateStats(bonusGems, this.Redraws)
                }
                else if (numCards < 5)
                    g_SharedData.RNGWR_SetStatus("Waiting for card #" . (numCards + 1))
            }
            else
            {
                this.WaitedForEllywickThisRun := true
                g_SharedData.RNGWR_SetStatus(this.GetResultString())
                bonusGems := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
                g_SharedData.RNGWR_UpdateStats(bonusGems, this.Redraws)
            }
        }

        DrawsLeft
        {
            get
            {
                return 5 - this.GetNumCards()
            }
        }

        RedrawsLeft
        {
            get
            {
                return this.MaxRedraws - this.Redraws
            }
        }

        ShouldDrawMoreCards()
        {
            if (this.DrawsLeft && this.WaitForAllCards)
                return true
            return this.GetNumGemCards() < this.GemCardsNeeded
        }

        ShouldRedraw()
        {
            numCards := this.GetNumCards()
            if (numCards == 5)
                return true
            else if (numCards == 0)
                return false
            return this.DrawsLeft < this.GemCardsNeeded - this.GetNumGemCards()
        }

        GetResultString()
        {
            success := this.GetNumGemCards() >= this.GemCardsNeeded
            redraws := this.Redraws
            str := success ? "Success" : "Failure"
            str .= " - Used " . redraws . " redraw" . IC_RNGWaitingRoom_Functions.Plural(redraws)
            return str
        }

        GetNumCards()
        {
            size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand.size.Read()
            if (size == "")
            {
                g_SF.Memory.ActiveEffectKeyHandler.Refresh()
                size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand.size.Read()
            }
            return size == "" ? 0 : size
        }

        GetNumGemCards()
        {
            return this.GetNumCardsOfType(3)
        }

        GetNumCardsOfType(cardType := 3)
        {
            numCards := 0
            cards := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadCardsInHand()
            for _, cardTypeInHand in cards
            {
                if (cardTypeInHand == cardType)
                    ++numCards
            }
            return numCards
        }

        UseEllywickUlt()
        {
            heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
            if (this.IsEllywickUltReady())
            {
                g_SharedData.RNGWR_SetStatus("Using Ellywick's ultimate to redraw cards")
                g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(heroID) . "}")
                ; Check if the ultimate is on cooldown one second later.
                fncToCallOnTimer := this.UltimateTimer
                SetTimer, %fncToCallOnTimer%, -1000, 0
                this.UsedUlt := true
            }
        }

        IsEllywickUltReady()
        {
            heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
            ultButton := g_SF.GetUltimateButtonByChampID(heroID)
            ultCd := g_SF.Memory.ReadUltimateCooldownByItem(ultButton - 1)
            return ultCd <= 0 ; any <= 0 means it's not on cd
        }

        CheckUltimateUsed()
        {
            if (!this.IsEllywickUltReady())
                this.Redraws += 1
            this.UsedUlt := false
        }
    }

    RemoveThelloraKeyFromInputValues(values)
    {
        if (IsObject(values))
        {
            newValues := []
            for k, v in values
            {
                slot := this.GetFavoriteFormationSlot(v)
                if (!slot || !this.IsThelloraInFavoriteFormation(slot))
                    newValues.Push(v)
            }
            return newValues
        }
        else
        {
            slot := this.GetFavoriteFormationSlot(values)
            if (slot && this.IsThelloraInFavoriteFormation(slot))
                values := ""
            return values
        }
    }

    GetFavoriteFormationSlot(key)
    {
        key := Trim(key, "{}")
        StringLower, key, key
        Switch key
        {
            case "q":
                slot := 1
            case "w":
                slot := 2
            case "e":
                slot := 3
            default:
                slot := 0
        }
        return slot
    }

    ; Checks if Thellora is in Q/W/E formation
    IsThelloraInFavoriteFormation(favorite := 1)
    {
        formationFavorite := g_SF.Memory.GetFormationByFavorite(favorite)
        heroID := ActiveEffectKeySharedFunctions.Thellora.HeroID
        return g_SF.IsChampInFormation(heroID, formationFavorite)
    }
}