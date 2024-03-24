#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
if (IsObject(SH_UpdateClass))
{
    	SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_BrivFeatSwap_Class, true)
        SH_UpdateClass.UpdateClassFunctions(g_SF,IC_BrivGemFarm_BrivFeatSwap_Class)
        SH_UpdateClass_Class.UpdateClassFunctions(g_SharedData, IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Class)
}
else
{
    	#include *i %A_LineFile%\..\..\..\SharedFunctions\IC_UpdateClass_Class.ahk
        IC_UpdateClass_Class.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_BrivFeatSwap_Class, true)   
        IC_UpdateClass_Class.UpdateClassFunctions(g_SF, IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class)
        IC_UpdateClass_Class.UpdateClassFunctions(g_SharedData, IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Class)
}

g_SharedData.BGFBFS_Init()