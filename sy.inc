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
; 获取游戏是否开始
syIsGameStarted proto
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

; 加载位图
syLoadImage proto
; 开始绘制
syBeginDraw proto
; 结束绘制
syEndDraw proto
; 绘制位图
; bitmap: HBITMAP 位图id
; i32X: sword 绘制位置x
; i32Y: sword 绘制位置y
; u32Width: dword 绘制宽度
; u32Height: dword 绘制高度
syDrawImage proto bitmap: HBITMAP, i32X: sword, i32Y: sword, u32Width: dword, u32Height: dword

; 变量声明

REC_LEN equ 100
SY_FACE_UP equ 0
SY_FACE_RIGHT equ 1
SY_FACE_DOWN equ 2
SY_FACE_LEFT equ 3

externdef OriginMapText: dword
externdef CurrentMapText: dword
; 游戏是否开始
externdef syGameStarted: byte

endif