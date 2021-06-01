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

MAX_LEN		EQU	100
REC_LEN		EQU	100
BRUSH_LEN	EQU 6
Number0		EQU 00b4c1cdh
Number1		EQU 008cfeffh
Number2		EQU 0097d0e8h
Number3		EQU 0091d2ffh
Number4		EQU 007999e8h
Number5		EQU 00918fffh

DialogBack	EQU 00eff8fah
StageBack   EQU 00a0adbbh
TextColor   EQU 00000000h
ButtonColor EQU 00ffffffh

WinMain             PROTO :DWORD, :DWORD, :DWORD, :DWORD	; 窗口主程序
Calculate           PROTO :DWORD, :DWORD, :DWORD, :DWORD	; 消息处理程序
InitRec             PROTO :DWORD							; 初始化方格矩阵
InitBack            PROTO       							; 初始化颜色数组
InitBrush           PROTO       							; 初始化笔刷数组
RefreshRec			PROTO
MoveUp				PROTO
MoveDown			PROTO
MoveLeft			PROTO
MoveRight			PROTO
CreateMap1			PROTO
CreateMap2			PROTO
CreateMap3			PROTO
CreateMap4			PROTO
CreateMap5			PROTO
CreateMap6			PROTO
CreateMap7			PROTO
CreateMap8			PROTO
CreateMap9			PROTO
CreateMap10			PROTO
ShowNumber			PROTO

IDD_DIALOG1            EQU         102
IDR_MENU1              EQU         108
IDR_ACCELERATOR2       EQU         109
IDC_NEW                EQU         1007
IDC_DATE               EQU         1008
IDC_UP                 EQU         1118
IDC_DOWN               EQU         1119
IDC_LEFT               EQU         1120
IDC_RIGHT              EQU         1121
IDC_STEP               EQU         1122
IDC_STEPTEXT           EQU         1123
IDC_LEVEL              EQU         1124
IDC_LEVELTEXT          EQU         1125
IDC_REMAKE             EQU         1126
ID_NEW                 EQU         40007
ID_EXIT                EQU         40008
ID_ABOUT               EQU         40009
ID_WRITER              EQU         40012