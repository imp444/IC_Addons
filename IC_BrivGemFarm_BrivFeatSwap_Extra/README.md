# Briv Feat Swap

## Description:
This Addon will allow to use Briv in E formation, so you can take advantage of the "save feats with formation" feature in order to have a faster gem farm (more quick transitions).  
Indeed, Briv's **Wasting Haste** feat (12500 gems) allows him to cap his **Unnatural haste** ability (level.80) to 800% (4J).
Using both Q and E formations you can alternate between jumping with Briv's current jump and jumping with 4J during the same adventure.  

This means you will have to get Briv to **5J+** to be able to use this feature.  
-> Item level required (**Epic** slot 4): **Dull**:15501, **Shiny**: 10251, **Golden**:7626.

## Setup:
1. Enable/Disable the Addon in **Addon Management** (Jigsaw puzzle piece in IC Script Hub) to turn it on/off. It should start/stop whenever you click on the main Briv Gem Farm tab.
2. Set up your **Preferred Briv Jump Zones** in this addon's tab or in **Advanced Settings** tab (IC Script Hub) then save.
You will have to manually save your profile in **Briv Gem Farm** tab.
3. To prevent input spam, enter the number of skips Briv should do in Q/E in the text fields then save.

![settings](Images/target_settings.png)

4. If you have the LevelUp addon, you can set the BrivMinLevelArea setting to walk the first few zones.

![levelup](Images/levelup_settings.png)

For steps 2 to 4, you can also use one of the **presets** to autofill target Q/E and advanced settings.

![presets](Images/presets.png) 

5. Set up your Briv feats in **Specialization and Feat Choices** (save formation menu in the game).
Hit save for each formation. It is not recommended to save feats for other champions.

6. Start **Briv Gem Farm** in IC Script Hub.

To stop this addon from working (e.g. to farm chests in events), uncheck **Enabled** next to **Save** then **Save**.

![enable](Images/save_enabled.png) 

**Disclaimer**: You may want to stop BrivGemFarm.ahk beforehand.

## Recommended settings:
### Specialization and Feat Choices
#### (Q:nJ, E:4J)

Use the Wasting haste feat if you want to 4J with a specific formation, and another feat if you want to nJ (n > 4).

![Q](Images/example_briv_q.png)   ![E](Images/example_briv_e.png)

You can fill the slots in W with feats such as HP or overwhelm to boost offline stacking.

### Advanced Settings Tab:

|                        **5J/4J TT**                        |
|:----------------------------------------------------------:|
| **Path:** 1, 6, *11*, 16, 21, 26, 31, 37, 43, 49, 55, *61* |
|         **+** 9 jumps /50 vs 10 jumps /50 for 4JTT         |
|           **+**     7/9 QTs vs 6/10 QTs for 4JTT           |
|    **-** Can't cancel Briv's jump during z37->z43->z49     |
|               ![](Images/5-4j_tt_setup.png)                |   

|             **8J/4J TT (requires perfect 8J)**              | **8J/4J TT (walk the first 4 areas using LevelUp addon)** |
|:-----------------------------------------------------------:|:---------------------------------------------------------:|
|   **Path:** 1, 10, 19, 28, *37*, 46, 55, 64, 73, 82, *87*   |    **Path:** 1, 2, 3, 4, *5*, 14, 23, 32, 37, 46, *55*    |
|         **-** 6 jumps /50 vs 11 jumps /100 for 8JTT         |                             /                             |
|        **+** 6/6 QTs after z37 vs 6/11 QTs for 8JTT         |                             /                             |
| **-** Can't cancel Briv's jump during z1->z10->z19-z28->z37 |                   + 100% QT, avoids z10                   |
|                ![](Images/8-4j_tt_setup.png)                |          ![](Images/8-4j_tt_setup_enhanced.png)           |


|               **9J/4J TT**                |
|:-----------------------------------------:|
|  **Path:** *1*, 11, 21, 31, 36, 46, *51*  |
| **-** 6 jumps /50 vs 5 jumps /50 for 9JTT |
|     **+** 6/6 QTs vs 3/5 QTs for 9JTT     |
|       ![](Images/9-4j_tt_setup.png)       |   
