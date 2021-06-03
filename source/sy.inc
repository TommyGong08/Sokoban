ifndef SY_INC
SY_INC equ <1>

include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include masm32.inc
include shell32.inc
include gdi32.inc
include msvcrt.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib masm32.lib
includelib gdi32.lib
includelib msvcrt.lib

; 函数声明

; 设置主窗体id
; win: HWND 窗体id
sySetMainWinId proto win: HWND

; 开始游戏
syStartGame proto
; 重置游戏
syResetGame proto
; 进入关卡选择
sySelectLevel proto
; 结束游戏
syEndGame proto

; 设置角色脸朝向
sySetPlayerFace proto u32Face: dword
; 刷新全图
syUpdateMap proto
; 刷新格子
; u32GridInd: dword 格子号
syUpdateGrid proto u32GridInd: dword
; 绘制全图
; devc: HDC 设备上下文id
syDrawMap proto devc: HDC

; 变量声明

SY_FACE_UP equ 0
SY_FACE_RIGHT equ 1
SY_FACE_DOWN equ 2
SY_FACE_LEFT equ 3

endif
