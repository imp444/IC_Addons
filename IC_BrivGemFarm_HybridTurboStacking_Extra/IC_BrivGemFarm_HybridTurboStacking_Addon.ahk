#include %A_LineFile%\..\IC_BrivGemFarm_HybridTurboStacking_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_HybridTurboStacking_Overrides.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk

SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_HybridTurboStacking_Class)
SH_UpdateClass.UpdateClassFunctions(g_SharedData, IC_BrivGemFarm_HybridTurboStacking_IC_SharedData_Class)
SH_UpdateClass.UpdateClassFunctions(g_SF.Memory, IC_BrivGemFarm_HybridTurboStacking_IC_MemoryFunctions_Class)

g_SharedData.BGFHTS_Init()