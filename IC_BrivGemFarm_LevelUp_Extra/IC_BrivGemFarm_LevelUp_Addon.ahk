#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
if (IsObject(SH_UpdateClass))
{
    SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_LevelUp_Class)
    SH_UpdateClass.UpdateClassFunctions(g_SF, IC_BrivGemFarm_LevelUp_SharedFunctions_Class)
    SH_UpdateClass.UpdateClassFunctions(g_SharedData, IC_BrivGemFarm_LevelUp_IC_SharedData_Class)
    SH_UpdateClass.UpdateClassFunctions(g_SF.Memory, IC_BrivGemFarm_LevelUp_IC_MemoryFunctions_Class)
}
else
{
    #include *i %A_LineFile%\..\..\..\SharedFunctions\IC_UpdateClass_Class.ahk
    IC_UpdateClass_Class.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_LevelUp_Class)
    IC_UpdateClass_Class.UpdateClassFunctions(g_SF, IC_BrivGemFarm_LevelUp_SharedFunctions_Class)
    IC_UpdateClass_Class.UpdateClassFunctions(g_SharedData, IC_BrivGemFarm_LevelUp_IC_SharedData_Class)
    IC_UpdateClass_Class.UpdateClassFunctions(g_SF.Memory, IC_BrivGemFarm_LevelUp_IC_MemoryFunctions_Class)
}