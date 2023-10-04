#SingleInstance Ignore
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
ListLines Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1

#include %A_LineFile%\..\..\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_HeroDefinesLoaderWorker.ahk

global g_GUID := A_Args[2]
global g_BGFLU_Worker := new IC_BrivGemFarm_LevelUp_HeroDefinesLoaderWorker

g_BGFLU_Worker.Start(A_Args[1])