# RNG Waiting Room

<p align="left">
<img alt="Ellywick" height="128" src="Images/Ellywick_portrait.png" width="128"/>
</p>

___

## Description:

This addon allows to get optimal gem cards draws for Ellywick while gem farming.  
It will increase the Gems Per Hour (GPH) of your gem farm by allowing Ellywick to draw gem cards on z1 before Thellora
is placed on the field, getting more gems for all the bosses she skips in the process.

___

## How to use:
This addon requires ICScripthub v4.0 and the LevelUpAddon.  

Thellora needs to be removed from the Modron formation to stack Ellywick on z1.
If Thellora jumps before Ellywick has drawn gem cards, you will lose the gem bonus for every single boss skipped by Thellora.  

You have to save another formation containing all the champions in the starting formation (minus Thellora) if you want the game to pick specialzations while levelling.  
<img alt="Advanced settings" src="Images/modron_formation.png"/>

Select your formation in the Modron Automation Setup menu.

## Settings:

####

>The settings below are used on z1 before Thellora is placed on the field.
> 
* **Number of gem cards** (default: 1)   
The addon waits until Ellywick has drawn this number of cards before progressing.


* **Max redraws** (default: 1)  
Number of times to redraw cards using Ellywick's ultimate.


* **Always wait for 5 draws** (default: True)  
Always waits for 5 cards to be drawn before progressing, even the target number of gem cards has been reached.

>If the desired number of gem cards can't be achieved with the remaining draws while waiting for a full hand,
> Ellywick's ultimate will be used early even if the **Always wait for 5 draws** setting is enabled.
> 
> Example: If Ellywick currently has **1** Gem card, **1** Moon card, and **Number of gem cards** is set to **5**, then her
> ultimate will be used early when there is at least 1 redraw left and her ultimate is off cooldown.
> 

>Note:  
> This addon disables formation switching to prevent Thellora from being loaded on z1.
> You will have to switch formations manually if Ellywick is not on the field before pressing the **Stat Gem Farm** button.