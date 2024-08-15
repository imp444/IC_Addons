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

    ReadResets()
    {
        return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.StatHandler.Resets.Read()
    }

    ; Ellywick

    WaitForEllywickCards(gemCardsNeeded := 1, gemPercentNeeded := 10, maxRerolls := 1)
    {
        rerolls := 0
        while (this.GetNumCardsOfType() < gemCardsNeeded) ; && !this.IsPercentEnough(gemPercentNeeded))
        {
            if (this.GetNumCards() < 5)
                cardDrawn := this.WaitForNextCard()
            else
                cardDrawn := true
            if (cardDrawn && this.GetNumCards() == 5)
            {
                ;if (this.GetNumCardsOfType() < gemCardsNeeded && !this.IsPercentEnough(gemPercentNeeded) && rerolls < maxRerolls)
                if (this.GetNumCardsOfType() < gemCardsNeeded && rerolls < maxRerolls)
                {
                    this.UseEllywickUlt()
                    ++rerolls
                }
            }
        }
    }

    WaitForNextCard(timeout := 65000)
    {
        g_SF.Memory.ActiveEffectKeyHandler.Refresh()
        numCards := this.GetNumCards()
        ElapsedTime := 0
        StartTime := A_TickCount
        while (this.GetNumCards() <= numCards && ElapsedTime < timeout)
            Sleep, 20
        return ElapsedTime < timeout
    }

    GetNumCards()
    {
        return ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadNumCardsInHand()
    }

    GetNumCardsOfType(cardType := 3)
    {
        gemCards := 0
        cards := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadCardsInHand()
        for _, cardTypeInHand in cards
        {
            if (cardTypeInHand == cardType)
                ++gemCards
        }
        return gemCards
    }

    IsPercentEnough(percent)
    {
        gemMult := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
        return 100 * (gemMult - 1) >= percent
    }

    UseEllywickUlt(timeout := 1000)
    {
        heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
        ElapsedTime := 0
        StartTime := A_TickCount
        while (this.IsEllywickUltReady() && ElapsedTime < timeout)
        {
            g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(heroID) . "}")
            Sleep, 50
        }
        return !this.IsEllywickUltReady()
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