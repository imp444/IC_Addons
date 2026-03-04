# RNG Waiting Room

<p align="left">
<img alt="Ellywick" height="128" src="Images/Ellywick_portrait.png" width="128"/>
</p>

___

## Description:

This addon allows you to get optimal gem card draws for Ellywick while gem farming.  
It will increase the Gems Per Hour (GPH) of your gem farm by allowing Ellywick to draw/redraw gem cards.

___

## How to use:
This addon requires ICScripthub v4.0 with EffectKeyHandler Memory v2.5.0 and the LevelUp addon.

### Ellywick

Set up her MinLevel in the LevelUp addon to level **200**, so that she gains her specialization **All That Sparkles**.

>**Level 200 - All That Sparkles**  
Additively increases the odds of Gem cards being drawn by 20% (additively reducing the odds of each other card by 5%)

This brings the percent chance of drawing Gem cards to **40**%.

### Modron Formation

This is a 4th formation that will be saved to the modron core as the formation loaded when you start a new run, it will hold all of the formations specializations.
you can use Emmote's [Example formations](https://emmotes.github.io/ic_scripting_routes/#formsTab) page on her site to build your Modron formation.

### Dungeon Master

If Dungeon Master is saved in the Modron formation, set his Min/Max in the Level up addon to 200/200, this will allow his ultimate will be used automatically to refresh Ellywick's.

## Settings:


* **Number of gem cards** (default: 1)   
The addon waits until Ellywick has drawn this number of cards before progressing.


* **Max redraws** (default: 1)  
Number of times to redraw cards using Ellywick's ultimate.  
>Even with no redraws left, her ult will be used on cooldown if she doesn't have any gem cards during the run.


* **Always wait for 5 draws** (default: True)  
Always waits for 5 cards to be drawn before progressing, even the target number of gem cards has been reached.
If your route hits bosses, you will want to activate this so the gem bonus is applied to bosses in the next save, 
since going to a boss zone triggers a save after you kill the boss and the bag of gems drops.

>If the desired number of gem cards can't be achieved with the remaining draws while waiting for a full hand,
> Ellywick's ultimate will be used early even if the **Always wait for 5 draws** setting is enabled.
> 
> Example: If Ellywick currently has **1** Gem card, **1** Moon card, and **Number of gem cards** is set to **5**, you'd need
> an additional 4 cards to have 5 gem cards, which is impossible since Ellywick can only have 5 cards in her hand at once.
> Her ultimate will be used early when there is at least 1 redraw left and her ultimate is off cooldown.

> You will have to switch formations manually if Ellywick is not on the field before pressing the **Start Gem Farm** button
> (unless switching from the stack formation).