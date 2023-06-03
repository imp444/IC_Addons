# BrivGemFarm_LevelUp
## Description:
This Addon will allow to set up maximum champion level settings for the Briv Gem Farm addon.  

**For each champion:**  
* Min level is the minimum level for a champion after a reset before waiting for Shandie dash.  
* Max level is the maximum level for a champion when minimum leveling is complete or after 5s on z1.

It performs the best using **x100** upgrade settings, although in some cases **x25** is preferred to prevent a champion from getting upgrades that would end up being detrimental to performance.  
If you have set upgrade settings to next upgrade mode, Briv may not achieve level 170 in time.
It is recommended to set his min level to 80 instead at the expense of a small increase in stacks consumption.
## Briv stacking:
**For stacking purposes:**  

During stack restarts, Briv gets more stacks as he is able to survive longer.
Sometimes it is undesirable to get many stacks because the simulation takes longer to complete.
Select a maximum level in the dropdown list, so he won't receive as many health upgrades.

If you're setting Briv's min level to less than level 110 so that he gets Unnatural Haste but not Healing Phlo, set up MaxLevel to 170 and under.
After stacking, Briv will be leveled back to level 170 and obtain his MetalBorn upgrade.

## Settings:

* **Show spoilers** (default: unchecked)   
Show unreleased champions in their respective seat.


* **Level up Briv/Shandie to MinLevel first** (default: unchecked)   
Level up Briv and Shandie before other champions after resetting.  
This is useful when using the in-game next upgrade/double arrow setting as leveling champions that multipy the amount of quest items received has a side effect of causing the area to be completed before Briv gets his jump ability at level 80.


* **Maximum simultaneous F keys inputs during MinLevel** (default: 4)  
Maximum number of champions being leveled up during the intial leveling to minLevel. This can help if input lag causes champions to be overleveled during the initial leveling.


* **MinLevel timeout (ms)** (default: 5000)  
Timeout before stopping the initial champion leveling. If set to 0, only a single leveling loop will be done before starting maximum leveling.