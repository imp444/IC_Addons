#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Overrides.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\IC_UpdateClass_Class.ahk
IC_UpdateClass_Class.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_LevelUp_Class)
IC_UpdateClass_Class.UpdateClassFunctions(g_SF, IC_BrivGemFarm_LevelUp_SharedFunctions_Class)
IC_UpdateClass_Class.UpdateClassFunctions(g_SharedData, IC_BrivGemFarm_LevelUp_IC_SharedData_Class)
IC_UpdateClass_Class.UpdateClassFunctions(g_SF.Memory, IC_BrivGemFarm_LevelUp_IC_MemoryFunctions_Class)
; CloseWelcomeBack addon check
closeWelcomeBackEnabled := IsObject(IC_BrivCloseWelcomeBack_SharedFunctions_Class)
if (closeWelcomeBackEnabled)
{
    IC_BrivGemFarm_LevelUp_SharedFunctions_Fix_Class.BGFLU_SetOverrideFlag()
    IC_BrivCloseWelcomeBack_SharedFunctions_Class.base := IC_BrivGemFarm_LevelUp_SharedFunctions_Fix_Class
}
IC_UpdateClass_Class.UpdateClassFunctions(g_SF, IC_BrivGemFarm_LevelUp_SharedFunctions_Fix_Class, closeWelcomeBackEnabled)