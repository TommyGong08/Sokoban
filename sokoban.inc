include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include masm32.inc
include shell32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib masm32.lib
includelib gdi32.lib

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
ShowNumber			PROTO

IDD_DIALOG1            EQU         102
IDR_MENU1              EQU         108
IDR_ACCELERATOR2       EQU         109
IDC_NEW                EQU         1007
IDC_DATE               EQU         1008
IDC_POS00              EQU         1018
IDC_POS01              EQU         1019
IDC_POS02              EQU         1020
IDC_POS03              EQU         1021
IDC_POS04              EQU         1022
IDC_POS05              EQU         1023
IDC_POS06              EQU         1024
IDC_POS07              EQU         1025
IDC_POS08              EQU         1026
IDC_POS09              EQU         1027
IDC_POS10              EQU         1028
IDC_POS11              EQU         1029
IDC_POS12              EQU         1030
IDC_POS13              EQU         1031
IDC_POS14              EQU         1032
IDC_POS15              EQU         1033
IDC_POS16              EQU         1034
IDC_POS17              EQU         1035
IDC_POS18              EQU         1036
IDC_POS19              EQU         1037
IDC_POS20              EQU         1038
IDC_POS21              EQU         1039
IDC_POS22              EQU         1040
IDC_POS23              EQU         1041
IDC_POS24              EQU         1042
IDC_POS25              EQU         1043
IDC_POS29              EQU         1044
IDC_POS28              EQU         1045
IDC_POS27              EQU         1046
IDC_POS26              EQU         1047
IDC_POS30              EQU         1048
IDC_POS31              EQU         1049
IDC_POS32              EQU         1050
IDC_POS33              EQU         1051
IDC_POS34              EQU         1052
IDC_POS35              EQU         1053
IDC_POS36              EQU         1054
IDC_POS37              EQU         1055
IDC_POS38              EQU         1056
IDC_POS39              EQU         1057
IDC_POS40              EQU         1058
IDC_POS41              EQU         1059
IDC_POS42              EQU         1060
IDC_POS43              EQU         1061
IDC_POS44              EQU         1062
IDC_POS45              EQU         1063
IDC_POS46              EQU         1064
IDC_POS47              EQU         1065
IDC_POS48              EQU         1066
IDC_POS49              EQU         1067
IDC_POS50              EQU         1068
IDC_POS51              EQU         1069
IDC_POS52              EQU         1070
IDC_POS53              EQU         1071
IDC_POS54              EQU         1072
IDC_POS55              EQU         1073
IDC_POS56              EQU         1074
IDC_POS57              EQU         1075
IDC_POS58              EQU         1076
IDC_POS59              EQU         1077
IDC_POS60              EQU         1078
IDC_POS61              EQU         1079
IDC_POS62              EQU         1080
IDC_POS63              EQU         1081
IDC_POS64              EQU         1082
IDC_POS65              EQU         1083
IDC_POS66              EQU         1084
IDC_POS67              EQU         1085
IDC_POS68              EQU         1086
IDC_POS69              EQU         1087
IDC_POS70              EQU         1088
IDC_POS80              EQU         1089
IDC_POS71              EQU         1090
IDC_POS72              EQU         1091
IDC_POS73              EQU         1092
IDC_POS74              EQU         1093
IDC_POS75              EQU         1094
IDC_POS76              EQU         1095
IDC_POS77              EQU         1096
IDC_POS78              EQU         1097
IDC_POS79              EQU         1098
IDC_POS81              EQU         1099
IDC_POS82              EQU         1100
IDC_POS83              EQU         1101
IDC_POS84              EQU         1102
IDC_POS85              EQU         1103
IDC_POS86              EQU         1104
IDC_POS87              EQU         1105
IDC_POS88              EQU         1106
IDC_POS89              EQU         1107
IDC_POS90              EQU         1108
IDC_POS91              EQU         1109
IDC_POS92              EQU         1110
IDC_POS93              EQU         1111
IDC_POS94              EQU         1112
IDC_POS95              EQU         1113
IDC_POS96              EQU         1114
IDC_POS97              EQU         1115
IDC_POS98              EQU         1116
IDC_POS99              EQU         1117
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