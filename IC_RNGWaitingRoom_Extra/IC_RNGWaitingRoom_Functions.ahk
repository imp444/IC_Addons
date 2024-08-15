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

    WaitForEllywickCards(gemCardsNeeded := 1, gemPercentNeeded := 10, maxRedraws := 1)
    {
        redraws := 0
        success := true
        ElapsedTime := 0
        StartTime := A_TickCount
        timeout := 300000
        ; Wait for 5 cards drawn before checking if there are enough gem cards
        while (((numCards := this.GetNumCards()) < 5 || this.GetNumGemCards() < gemCardsNeeded) && ElapsedTime < timeout) ; && !this.IsPercentEnough(gemPercentNeeded))
        {
            redrawsLeft := maxRedraws - redraws
            if (numCards < 5)
            {
                str := "Waiting for card # " . (numCards + 1)
                str .= " - " . redrawsLeft . " redraw" . this.Plural(redrawsLeft) . " left"
                g_SharedData.RNGWR_SetStatus(str)
                cardDrawn := this.WaitForNextCard()
            }
            else
                cardDrawn := true
            if (cardDrawn && this.GetNumCards() == 5)
            {
                ;if (this.GetNumGemCards() < gemCardsNeeded && !this.IsPercentEnough(gemPercentNeeded) && redraws < maxRedraws)
                if (this.GetNumGemCards() < gemCardsNeeded && redrawsLeft)
                {
                    if(this.UseEllywickUlt())
                        ++redraws
                }
                else if (this.GetNumGemCards() < gemCardsNeeded) ; FAIL
                {
                    success := false
                    break
                }
            }
            ElapsedTime := A_TickCount - StartTime
        }
        str := success ? "Success" : "Failure"
        str .= " - Used " . redraws . " redraw" . this.Plural(redraws)
        g_SharedData.RNGWR_SetStatus(str)
    }

    WaitForNextCard(timeout := 65000)
    {
        g_SF.Memory.ActiveEffectKeyHandler.Refresh()
        numCards := this.GetNumCards()
        ElapsedTime := 0
        StartTime := A_TickCount
        while (this.GetNumCards() <= numCards && ElapsedTime < timeout)
        {
            Sleep, 20
            ElapsedTime := A_TickCount - StartTime
        }
        return ElapsedTime < timeout
    }

    GetNumCards()
    {
        size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand.size.Read()
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

    IsPercentEnough(percent)
    {
        gemMult := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
        return 100 * (gemMult - 1) >= percent
    }

    UseEllywickUlt(timeout := 1000)
    {
        heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
        ultReady := this.IsEllywickUltReady()
        ElapsedTime := 0
        StartTime := A_TickCount
        ; Try to use ult until it is on cooldown
        if (ultReady)
        {
            while (this.IsEllywickUltReady() && ElapsedTime < timeout)
            {
                g_SharedData.RNGWR_SetStatus("Using Ellywick's ultimate to redraw")
                g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(heroID) . "}")
                Sleep, 50
                ElapsedTime := A_TickCount - StartTime
            }
            return !this.IsEllywickUltReady()
        }
        return false
    }

    WaitForEllywickUlt()
    {
        isActive := ActiveEffectKeySharedFunctions.Ellywick.EllywickDeckOfManyThingsHandler.ReadUltimateActive()
        return isActive
    }

    IsEllywickUltReady()
    {
        heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
        ultButton := g_SF.GetUltimateButtonByChampID(heroID)
        ultCd := g_SF.Memory.ReadUltimateCooldownByItem(ultButton - 1)
        return ultCd <= 0 ; any <= 0 means it's not on cd
    }
}