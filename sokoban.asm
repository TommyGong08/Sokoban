.386
.model flat, stdcall
option casemap: none
includelib msvcrt.lib
printf PROTO C :ptr sbyte, :VARARG	
include sokoban.inc
.data

hInstance		dd		?       ; 主程序句柄
hGuide			dd		?       ; 引导文字句柄
hLevel			dd		?       ; 关卡句柄
hLevelText      dd		?       ; 关卡文本句柄
hStep			dd      ?       ; 步数句柄
hStepText		dd		?		; 步数文本句柄
hMenu			dd		?       ; 菜单句柄

hIcon			dd		?       ; 图标句柄
hAcce			dd		?       ; 热键句柄
hStage			dd		?       ; 矩形外部句柄
hDialogBrush    dd      ?       ; 对话框背景笔刷
hStageBrush     dd      ?       ; 矩形外部背景笔刷

iScore          dd		0                       ; 0
cScore          db		MAX_LEN dup(0)          ; 0
currentLevel	dd		0
currentStep		dd		0
CurrPosition	dd		0		;记录人的位置
temp_for_initrec	dd	1018
temp_ebx		dd		0
temp_ecx		dd		0
OriginMapText	dd		MAX_LEN dup(0)			;原始地图矩阵
CurrentMapText  dd      MAX_LEN dup(0)			;当前地图矩阵

hMapRec			dd		MAX_LEN dup(0)			;地图方块句柄数组
hMapBack		dd		BRUSH_LEN dup(0)		;背景句柄数组
hMapBrush		dd		BRUSH_LEN dup(0)		;笔刷数组

ProgramName		db		"Game", 0               ; 程序名称
GameName		db		"sokoban", 0               ; 程序名称
Author			db		"MonsterGe", 0           ; 作者
FontName        db		"Microsoft Sans Serif", 0
cGuide          db		"Sokoban!", 0     ; 引导信息
cWin            db		"You win! Please click the button to restart", 0    ; 成功信息
cLose           db		"You lose! Please click the button to restart", 0   ; 失败信息

isWin			db		0                       ; 判断是否成功
isLose			db		0                       ; 判断是否失败
cNum0			db		"0", 0
cNum1			db		"1", 0
cNum2			db		"2", 0
cNum3			db		"3", 0
cNum4			db		"4", 0
cNum5			db		"5", 0

iprintf			db		"%d",0ah ,0
.code

WinMain PROC hInst:dword, hPrevInst:dword, cmdLine:dword, cmdShow:dword
	local wc:WNDCLASSEX		;窗口类
	local msg:MSG			;消息
	local hWnd:HWND			;对话框句柄

	invoke RtlZeroMemory, addr wc, sizeof WNDCLASSEX

	mov wc.cbSize, sizeof WNDCLASSEX				;窗口类的大小
	mov wc.style, CS_HREDRAW or CS_VREDRAW			;窗口风格
	mov wc.lpfnWndProc, offset Calculate			;窗口消息处理函数地址
	mov wc.cbClsExtra, 0							;在窗口类结构体后的附加字节数，共享内存
	mov wc.cbWndExtra, DLGWINDOWEXTRA				;在窗口实例后的附加字节数

	push hInst
	pop wc.hInstance								;窗口所属程序句柄

	mov wc.hbrBackground, COLOR_WINDOW				; 背景画刷句柄
    mov wc.lpszMenuName, NULL						; 菜单名称指针
    mov wc.lpszClassName, offset ProgramName		; 窗口类类名称
	; 加载图标句柄
	;invoke LoadIcon, hInst, IDI_ICON
	;mov wc.hIcon, eax
	
	; 加载光标句柄
    invoke LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor, eax

	mov wc.hIconSm, 0								;窗口小图标句柄

	invoke RegisterClassEx, addr wc					;注册窗口类
	;加载对话框窗口
	invoke CreateDialogParam, hInst, IDD_DIALOG1, 0, offset Calculate, 0
	mov hWnd, eax
	invoke ShowWindow, hWnd, cmdShow				;显示窗口
	invoke UpdateWindow, hWnd						;更新窗口
	
    .while TRUE

        invoke GetMessage, addr msg, NULL, 0, 0                 ; 获取消息
        .break .if eax == 0
        invoke TranslateAccelerator, hWnd, hAcce, addr msg    ; 转换快捷键消息
        .if eax == 0
            invoke TranslateMessage, addr msg   ; 转换键盘消息
            invoke DispatchMessage, addr msg    ; 分发消息
        .endif
    .endw	

	mov eax, msg.wParam
	ret
WinMain endp

Calculate proc hWnd:dword, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    local hdc:HDC
    local ps:PAINTSTRUCT
    local hf:dword

    .if uMsg == WM_INITDIALOG
        ; 获取菜单的句柄并显示菜单
        invoke LoadMenu, hInstance, IDR_MENU1
        mov hMenu, eax
        invoke SetMenu, hWnd, hMenu

        ; 获取快捷键的句柄并显示菜单
        invoke LoadAccelerators, hInstance, IDR_ACCELERATOR2
        mov hAcce, eax

        ; 初始化数组和矩阵
        invoke InitRec, hWnd
        invoke InitBack
        invoke InitBrush

		; 生成字体
		invoke CreateFont, 26, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, offset FontName
        mov hf, eax

		; 初始化方格及其字体
        xor ebx, ebx
        .while ebx < REC_LEN
            invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, NULL
			invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETFONT, hf, NULL
            inc ebx
        .endw

    .elseif uMsg == WM_PAINT
        ; 绘制对话框背景
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke FillRect, hdc, addr ps.rcPaint, hDialogBrush
        invoke EndPaint, hWnd, addr ps
    
	.elseif uMsg == WM_CTLCOLORSTATIC
        ; 绘制静态文本框
        mov ecx, lParam
        .if hStage == ecx
            invoke SetTextColor, wParam, StageBack
            invoke SetBkColor, wParam, StageBack
            mov eax, hStageBrush

            ret
        .elseif hLevel == ecx || hStep == ecx
            invoke SetTextColor, wParam, TextColor
            invoke SetBkColor, wParam, DialogBack

            ret
        .elseif hLevelText == ecx || hStepText == ecx
            invoke SetTextColor, wParam, ButtonColor
            invoke SetBkColor, wParam, StageBack
            mov eax, hStageBrush

            ret
        .endif

        ; 获得当前操作的方格句柄
        xor ebx, ebx
        .while (dword ptr hMapRec[ebx * 4] != ecx) && (ebx < REC_LEN)
            inc ebx
        .endw

        invoke ShowNumber
		mov eax,TextColor
        invoke SetTextColor, wParam, TextColor              ; 绘制文本颜色
		movzx esi, word ptr CurrentMapText[ebx * 2]         ; 根据数字大小选择笔刷
        invoke SetBkColor, wParam, dword ptr hMapBack[esi * 4] ; 绘制背景颜色

        mov eax, dword ptr hMapBrush[esi * 4]                  ; 返回笔刷以便绘图

        ret
	.elseif uMsg == WM_COMMAND
		mov eax, wParam
        movzx eax, ax       ; 获得命令
		;开始新游戏，此时需要加载当前关卡对应的地图
		.if eax == IDC_NEW || eax == ID_NEW
			;调用加载地图的函数
			.if currentLevel == 0
				invoke CreateMap1
				;invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 1
			.elseif currentLevel == 1
				invoke CreateMap2
				;invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 2
			.elseif currentLevel == 2
				invoke CreateMap3
				;invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 3
			.endif
            invoke RefreshRec
			;invoke SendMessage, hStepText, WM_SETTEXT, 0, offset 0
			;把当前步数调成0，每移动一步，当前步数加一
			and currentStep, 0
            and isWin, 0
            and isLose, 0

		 ;上方向键
		.elseif eax == IDC_UP
			.if (isWin == 0) && (isLose == 0)
				invoke MoveUp
				invoke RefreshRec
			.endif
				;步数先不管
		 ;下方向键
		.elseif eax == IDC_DOWN
			.if (isWin == 0) && (isLose == 0)
				invoke MoveDown
				invoke RefreshRec
			.endif
		;左方向键
		.elseif eax == IDC_LEFT
			.if (isWin == 0) && (isLose == 0)
				invoke MoveLeft
				invoke RefreshRec
			.endif
		;右方向键
		.elseif eax == IDC_RIGHT
			.if (isWin == 0) && (isLose == 0)
				invoke MoveRight
				invoke RefreshRec
			.endif
		.endif
    .else
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    
    .endif

    xor eax, eax

    ret
Calculate endp


RefreshRec proc
	xor ebx, ebx
	.while ebx < REC_LEN
		invoke InvalidateRect, dword ptr hMapRec[ebx * 4], NULL, TRUE
		inc ebx
	.endw

	ret
RefreshRec endp

InitRec proc hWnd:dword
;调用GetDlgItem函数获得方块的句柄
;包括整体背景的句柄、100个方块的句柄等
    invoke GetDlgItem, hWnd, IDC_STEP
    mov hStep, eax

	invoke GetDlgItem, hWnd, IDC_STEPTEXT
    mov hStepText, eax

	invoke GetDlgItem, hWnd, IDC_LEVEL
    mov hLevel, eax

	invoke GetDlgItem, hWnd, IDC_LEVELTEXT
    mov hLevelText, eax

	xor ebx, ebx
	mov ecx, 1018
	mov edx, 1018
	.while ebx < REC_LEN
		.if temp_for_initrec < 1044
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[ebx * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec == 1044
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[29 * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec == 1045
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[28 * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec == 1046
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[27 * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec == 1047
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[26 * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec < 1089
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[ebx * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec == 1089
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[80 * 4], eax
			inc temp_for_initrec
		.elseif temp_for_initrec < 1099
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[ebx * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec == 1099
			inc ebx
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[ebx * 4], eax
			inc ebx
			inc temp_for_initrec
		.elseif temp_for_initrec < 1118
			invoke GetDlgItem, hWnd, temp_for_initrec
			mov dword ptr hMapRec[ebx * 4], eax
			inc ebx
			inc temp_for_initrec
		.endif
	.endw
	ret
InitRec endp

InitBack proc
;设置不同种类方块对应的颜色，存到hMapBack数组里面
;一共六种：墙外、墙、空地、人、箱、结束点
	xor ebx, ebx
	mov dword ptr hMapBack[ebx * 4], Number0

	inc ebx
	mov dword ptr hMapBack[ebx * 4], Number1

	inc ebx
	mov dword ptr hMapBack[ebx * 4], Number2

	inc ebx
	mov dword ptr hMapBack[ebx * 4], Number3

	inc ebx
	mov dword ptr hMapBack[ebx * 4], Number4

	inc ebx
	mov dword ptr hMapBack[ebx * 4], Number5

	ret
InitBack endp

InitBrush proc
;创建不同种类的画刷颜色
    invoke CreateSolidBrush, DialogBack
    mov hDialogBrush, eax

	xor ebx, ebx
    invoke CreateSolidBrush, Number0

    mov dword ptr hMapBrush[ebx * 4], eax

	inc ebx
    invoke CreateSolidBrush, Number1
    mov dword ptr hMapBrush[ebx * 4], eax

	inc ebx
    invoke CreateSolidBrush, Number2
    mov dword ptr hMapBrush[ebx * 4], eax

	inc ebx
    invoke CreateSolidBrush, Number3
    mov dword ptr hMapBrush[ebx * 4], eax

	inc ebx
    invoke CreateSolidBrush, Number4
    mov dword ptr hMapBrush[ebx * 4], eax

	inc ebx
    invoke CreateSolidBrush, Number5
    mov dword ptr hMapBrush[ebx * 4], eax

	ret
InitBrush endp

MoveUp proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	sub edi, 10; edi记录人的上方位置


	; 判断上方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov  CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变上方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 10; ecx是人的上上方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4

		; 只可能是空地或存放点，可以移动
		.else
		mov CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[ecx * 4], 4
		mov dword ptr CurrentMapText[edi * 4], 3
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

		.endif

	; 如果是围墙, 不改变地图
	.else
	ret
	.endif
	ret
MoveUp endp

MoveDown proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	add edi, 10; edi记录人的下方位置

	; 判断下方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变下方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		add ecx, 10; ecx是人的下下方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			;删除了continue

		; 只可能是空地或存放点，可以移动
		.else
			mov CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
		.endif

	; 如果是围墙, 不改变地图
	.else
		;.continue
	.endif
ret
MoveDown endp

MoveLeft proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	sub edi, 1; edi记录人的左方位置

	; 判断左方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变左方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 1; ecx是人的左左方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			;.continue

		; 只可能是空地或存放点，可以移动
		.else
			mov dword ptr CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
		.endif

	; 如果是围墙, 不改变地图
	.else
		;.continue
	.endif
	ret
MoveLeft endp

MoveRight proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	add edi, 1; edi记录人的右方位置

	; 判断左方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变右方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

		; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		add ecx, 1; ecx是人的右右方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			;.continue

		; 只可能是空地或存放点，可以移动
		.else
			mov dword ptr CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
		.endif

	; 如果是围墙, 不改变地图
	.else
		;.continue
	.endif
	ret
MoveRight endp

;第一关地图初始化
CreateMap1 proc
	
	xor ebx, ebx
	.while ebx < REC_LEN
		.if ( ebx < 13 || ( ebx > 15 && ebx < 23 ) || ( ebx > 25 && ebx < 33 ) || ebx == 39 || ebx == 40 || ebx == 49 || ebx == 50 || ebx == 59 || ebx == 60 || ( ebx > 66 && ebx < 74 ) || ( ebx > 76 && ebx < 84 ) || ebx > 86 )
			mov dword ptr CurrentMapText[ebx * 4], 0
			inc ebx 
		.elseif (( ebx > 12 && ebx < 16 ) || ebx == 23 || ebx == 25 || ebx == 33 || ( ebx > 34 && ebx < 39 ) || ( ebx > 40 && ebx < 44 ) || ebx == 48 || ebx == 51 || ( ebx > 55 && ebx < 59 ) || ( ebx > 60 && ebx < 65 ) || ebx == 66 || ebx == 74 || ebx == 76 || ( ebx > 83 && ebx < 87 ))
			mov dword ptr CurrentMapText[ebx * 4], 1
			inc ebx
		.elseif ( ebx == 34 || ebx == 45 || ebx == 53 )
			mov dword ptr CurrentMapText[ebx * 4], 2
			inc ebx
		.elseif ebx == 55
			mov dword ptr CurrentMapText[ebx * 4], 3
			inc ebx
		.elseif ( ebx == 44 || ebx == 46 || ebx == 54 || ebx == 65 )
			mov dword ptr CurrentMapText[ebx * 4], 4
			inc ebx
		.elseif ( ebx == 24 || ebx == 47 || ebx == 52 || ebx == 75 )
			mov dword ptr CurrentMapText[ebx * 4], 5
			inc ebx
		.endif
	.endw

	xor ebx, ebx
	.while ebx < REC_LEN
		mov eax, dword ptr CurrentMapText[ebx * 4]
		.if eax == 3 || eax == 4
			mov dword ptr OriginMapText[ebx * 4], 2
			inc ebx
		.else
			mov dword ptr OriginMapText[ebx * 4], eax
			inc ebx
		.endif
	.endw

	ret

CreateMap1 endp

;第二关地图初始化
CreateMap2 proc

	xor ebx, ebx
	.while ebx < REC_LEN
		.if ( ebx == 0 || ( ebx > 5 && ebx < 11 ) || ( ebx > 15 && ebx < 21 ) || ebx == 26 || ebx == 30 || ebx == 36 || ebx == 40 || ( ebx > 49 && ebx < 52 ) || ( ebx > 59  && ebx < 62 ) || ( ebx > 69 && ebx  < 72 ) || ( ebx > 79 && ebx  < 82 ) || ebx > 86 )
			mov dword ptr CurrentMapText[ebx * 4], 0
			inc ebx 
		.elseif (( ebx > 0 && ebx < 6 ) || ebx == 11 || ebx == 15 || ebx == 21 || ebx == 25 || ( ebx > 26 && ebx < 30 ) || ebx == 31 || ebx == 35 || ebx == 37 || ebx == 39 || ( ebx > 40 && ebx < 44 ) || ( ebx > 44 && ebx < 48 ) || ebx == 49 || ebx == 52 || ebx == 53 )  
			mov dword ptr CurrentMapText[ebx * 4], 1
			inc ebx
		.elseif ( ebx == 59 || ebx == 62 || ebx == 66 || ebx == 69 || ebx == 72 || ( ebx > 75 && ebx < 80 ) || ( ebx > 81 && ebx < 87 ))
			mov dword ptr CurrentMapText[ebx * 4], 1
			inc ebx
		.elseif ( ebx == 13 || ebx == 14 || ebx == 22 || ebx == 32 || ebx == 34 || ebx == 44 || ( ebx > 53 && ebx < 58 ) || ( ebx > 62 && ebx < 66 ) || ebx == 67 || ebx == 68 || ( ebx > 72 && ebx < 76 ))
			mov dword ptr CurrentMapText[ebx * 4], 2
			inc ebx
		.elseif ebx == 12
			mov dword ptr CurrentMapText[ebx * 4], 3
			inc ebx
		.elseif ( ebx == 23 || ebx == 24 || ebx == 33 )
			mov dword ptr CurrentMapText[ebx * 4], 4
			inc ebx
		.elseif ( ebx == 38 || ebx == 48 || ebx == 58 )
			mov dword ptr CurrentMapText[ebx * 4], 5
			inc ebx
		.endif
	.endw

	xor ebx, ebx
	.while ebx < REC_LEN
		mov eax, dword ptr CurrentMapText[ebx * 4]
		.if eax == 3 || eax == 4
			mov dword ptr OriginMapText[ebx * 4], 2
			inc ebx
		.else
			mov dword ptr OriginMapText[ebx * 4], eax
			inc ebx
		.endif
	.endw

	ret

CreateMap2 endp

;第三关地图初始化
CreateMap3 proc
	
	xor ebx, ebx
	.while ebx < REC_LEN
		.if ( ebx < 11 || ( ebx > 17  && ebx < 21 ) || ebx == 69 || ebx == 70 || ebx > 78 )
			mov dword ptr CurrentMapText[ebx * 4], 0
			inc ebx 
		.elseif (( ebx > 21 && ebx < 27) || ( ebx > 35 && ebx < 39) || ebx == 41 || ebx == 43 || ebx == 45 || ebx == 46 || ebx == 48 || ebx == 51 || ebx == 55 || ebx == 57 || ebx == 65 || ebx == 66 || ebx == 67 )
			mov dword ptr CurrentMapText[ebx * 4], 2
			inc ebx
		.elseif ebx == 42
			mov dword ptr CurrentMapText[ebx * 4], 3
			inc ebx
		.elseif ( ebx == 32 || ebx == 44 || ebx == 47 || ebx == 56 )
			mov dword ptr CurrentMapText[ebx * 4], 4
			inc ebx
		.elseif ( ebx == 52 || ebx == 53 || ebx == 62 || ebx == 63 )
			mov dword ptr CurrentMapText[ebx * 4], 5
			inc ebx
		.else
			mov dword ptr CurrentMapText[ebx * 4], 1
			inc ebx
		.endif
	.endw

	xor ebx, ebx
	.while ebx < REC_LEN
		mov eax, dword ptr CurrentMapText[ebx * 4]
		.if eax == 3 || eax == 4
			mov dword ptr OriginMapText[ebx * 4], 2
			inc ebx
		.else
			mov dword ptr OriginMapText[ebx * 4], eax
			inc ebx
		.endif
	.endw

	ret

CreateMap3 endp

;第四关地图初始化
CreateMap4 proc
	
	xor ebx, ebx
	.while ebx < REC_LEN
		.if ( (ebx > 12 && ebx < 17 ) || ebx == 22 || ebx == 23 || ebx == 26 || ebx == 32 || ebx == 36 || ebx == 42 || ebx == 43 || ebx == 46 || ebx == 47 || ebx == 52 || ebx == 53 || ebx == 57 || ebx == 62 || ebx == 67 || ebx == 72 || ebx == 77 || ( ebx > 81 && ebx < 88) )
			mov dword ptr CurrentMapText[ebx * 4], 1
			inc ebx 
		.elseif ( ebx == 24 || ebx == 25 || ebx == 35 || ebx == 45 || ebx == 54 || ebx == 56 || ebx == 65 || ebx == 66)
			mov dword ptr CurrentMapText[ebx * 4], 2
			inc ebx
		.elseif ebx == 33
			mov dword ptr CurrentMapText[ebx * 4], 3
			inc ebx
		.elseif ( ebx == 34 || ebx == 44 || ebx == 55 || ebx == 64 || ebx == 75 )
			mov dword ptr CurrentMapText[ebx * 4], 4
			inc ebx
		.elseif ( ebx == 63 || ebx == 73 || ebx == 74 || ebx == 76 )
			mov dword ptr CurrentMapText[ebx * 4], 5
			inc ebx
		.else
			mov dword ptr CurrentMapText[ebx * 4], 0
			inc ebx
		.endif
	.endw

	xor ebx, ebx
	.while ebx < REC_LEN
		mov eax, dword ptr CurrentMapText[ebx * 4]
		.if eax == 3 || eax == 4
			mov dword ptr OriginMapText[ebx * 4], 2
			.if ebx == 75
				mov dword ptr OriginMapText[ebx * 4], 5
			.endif
			inc ebx
		.else
			mov dword ptr OriginMapText[ebx * 4], eax
			inc ebx
		.endif
	.endw

	ret

CreateMap4 endp

ShowNumber proc

	movzx ecx, word ptr CurrentMapText[ebx * 2]

	.if ecx == 0
		invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, offset cNum0
	.elseif ecx == 1

		invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, offset cNum1
	.elseif ecx == 2
		invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, offset cNum2
	.elseif ecx == 3
		invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, offset cNum3
	.elseif ecx == 4
		invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, offset cNum4
	.elseif ecx == 5
		invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, offset cNum5
	.endif
	
	ret
ShowNumber endp
; 主程序
main proc

    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke WinMain, hInstance, 0, 0, SW_SHOWNORMAL
	invoke ExitProcess, eax

main endp
end main