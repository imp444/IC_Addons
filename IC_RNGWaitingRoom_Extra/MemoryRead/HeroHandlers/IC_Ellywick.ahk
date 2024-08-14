class Ellywick
{
    static HeroID := 83
    class EllywickDeckOfManyThingsHandler
    {
        static CardType := {1:"Knight", 2:"Moon", 3:"Gem", 4:"Fates", 5:"Flames"}
        static EffectKeyString := "ellywick_deck_of_many_things"

        ReadGemMult()
        {
            return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].StatHandler.EllywickGemMult.Read()
        }

        ReadCurrentMonsterKills()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.currentMonsterKills.Read()
        }

        ReadCardsInHand()
        {
            size := g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.cardsInHand.size.Read()
            ; sanity check, 5 is the max number of cards in hands possible.
            if (size < 1 OR size > 5)
                return ""
            cards := []
            loop, %size%
            {
                cardType := g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.cardsInHand[A_index - 1].CardType.Read()
                cards.Push(cardType)
            }
            return cards
        }

        ReadTempProbabilityMap()
        {
            size := g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.tempProbabilityMap.size.Read()
            ; sanity check, 5 should be the number of card types
            if (size != 5)
                return ""
            pmap := {}
            loop, 5
            {
                cardType := g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.tempProbabilityMap["key", A_index - 1].Read()
                probability := g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.tempProbabilityMap["value", A_index - 1].Read()
                map[cardType] := probability
            }
            return pmap
        }

        ReadUltimateActive()
        {
            return g_SF.Memory.ActiveEffectKeyHandler.EllywickDeckOfManyThingsHandler.ultimateActive.Read()
        }
    }
}