.386
.model flat, stdcall
option casemap : none
includelib msvcrt.lib
include msvcrt.inc
include kernel32.inc
includelib kernel32.lib
include sy.inc
include sokoban.inc
.data

hInstance		dd ? ; 主程序句柄
hGuide			dd ? ; 引导文字句柄
hLevel			dd ? ; 关卡句柄
hLevelText      dd ? ; 关卡文本句柄
hStep			dd ? ; 步数句柄
hStepText		dd ? ; 步数文本句柄
hMenu			dd ? ; 菜单句柄

hIcon			dd ? ; 图标句柄
hAcce			dd ? ; 热键句柄
hStage			dd ? ; 矩形外部句柄
hDialogBrush    dd ? ; 对话框背景笔刷
hStageBrush     dd ? ; 矩形外部背景笔刷

iScore          dd		0; 0
cScore          db		MAX_LEN dup(0); 0
currentLevel	dd		0;记录当前关卡
cLevel			dd		5 dup(0)
currentStep		dd		0
cStep			dd		5 dup(0)
CurrPosition	dd		0; 记录人的位置
temp_for_initrec	dd	1018
temp_ebx		dd		0
temp_ecx		dd		0
OriginMapText	dd		MAX_LEN dup(0); 原始地图矩阵
CurrentMapText  dd      MAX_LEN dup(0); 当前地图矩阵

ProgramName		db		"Game", 0; 程序名称
GameName		db		"sokoban", 0; 程序名称
Author			db		"MonsterGe", 0; 作者
cGuide          db		"Sokoban!", 0; 引导信息
cWin            db		"You win! Please click the button to restart", 0; 成功信息
cLose           db		"You lose! Please click the button to restart", 0; 失败信息
szFormat	    db	    "%d ", 0
isWin			db		0; 判断是否成功
isLose			db		0; 判断是否失败

iprintf			db		"%d", 0ah, 0

cLevel1			db		"1", 0
cLevel2			db		"2", 0
cLevel3			db		"3", 0
cLevel4			db		"4", 0
cLevel5			db		"5", 0
.code

WinMain PROC hInst : dword, hPrevInst : dword, cmdLine : dword, cmdShow : dword
	local wc : WNDCLASSEX; 窗口类
	local msg : MSG; 消息
	local hWnd : HWND; 对话框句柄

	invoke RtlZeroMemory, addr wc, sizeof WNDCLASSEX

	mov wc.cbSize, sizeof WNDCLASSEX; 窗口类的大小
	mov wc.style, CS_HREDRAW or CS_VREDRAW; 窗口风格
	mov wc.lpfnWndProc, offset Calculate; 窗口消息处理函数地址
	mov wc.cbClsExtra, 0; 在窗口类结构体后的附加字节数，共享内存
	mov wc.cbWndExtra, DLGWINDOWEXTRA; 在窗口实例后的附加字节数

	push hInst
	pop wc.hInstance; 窗口所属程序句柄

	mov wc.hbrBackground, COLOR_WINDOW; 背景画刷句柄
	mov wc.lpszMenuName, NULL; 菜单名称指针
	mov wc.lpszClassName, offset ProgramName; 窗口类类名称
	; 加载图标句柄
	; invoke LoadIcon, hInst, IDI_ICON
	; mov wc.hIcon, eax

	; 加载光标句柄
	invoke LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor, eax

	mov wc.hIconSm, 0; 窗口小图标句柄

	invoke RegisterClassEx, addr wc; 注册窗口类
	; 加载对话框窗口
	invoke CreateDialogParam, hInst, IDD_DIALOG1, 0, offset Calculate, 0
	mov hWnd, eax
	
	; 设置主窗体id
	invoke sySetMainWinId, eax

	invoke ShowWindow, hWnd, cmdShow; 显示窗口
	invoke UpdateWindow, hWnd; 更新窗口

	; 消息循环
	.while TRUE
		invoke GetMessage, addr msg, NULL, 0, 0; 获取消息
		.break .if eax == 0
		invoke TranslateAccelerator, hWnd, hAcce, addr msg; 转换快捷键消息
		.if eax == 0
			invoke TranslateMessage, addr msg; 转换键盘消息
			invoke DispatchMessage, addr msg; 分发消息
		.endif
	.endw

	mov eax, msg.wParam
	ret
WinMain endp


; 判断输赢
JudgeWin proc
	; 若图中不出现属性5，证明箱子全部到位
	xor eax, eax
	xor ebx, ebx; ebx记录图中箱子存放点数量
	mov eax, 0
	.while eax < MAX_LEN
		.if OriginMapText[eax * 4] == 5 
			;如果Origin是5的位置 Current都是4就行了
			.if CurrentMapText[eax * 4] == 4
			jmp L1
			.else ;不等于4,说明没成功
				jmp NotWin
			.endif 
		.endif
L1:		inc eax
	.endw
	mov isWin, 1 ;该局获胜
	inc currentLevel ;关卡数+1
	ret
NotWin:		
	mov isWin, 0 
	ret
JudgeWin endp

Calculate proc hWnd : dword, uMsg : UINT, wParam : WPARAM, lParam : LPARAM
	local hdc : HDC
	local ps : PAINTSTRUCT

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
		invoke InitBrush

	.elseif uMsg == WM_PAINT
		; 绘制对话框背景
		invoke BeginPaint, hWnd, addr ps
		mov hdc, eax
		invoke FillRect, hdc, addr ps.rcPaint, hDialogBrush

		; 绘制地图
		invoke syDrawMap, hdc

		invoke EndPaint, hWnd, addr ps

	.elseif uMsg == WM_COMMAND
		mov eax, wParam
		movzx eax, ax; 获得命令
		; 开始新游戏，此时需要加载当前关卡对应的地图
		.if eax == IDC_NEW || eax == ID_NEW
			; 调用加载地图的函数
			.if currentLevel == 0
				invoke CreateMap1
				invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset cLevel1
			.elseif currentLevel == 1
			Map2:
				invoke CreateMap2
				invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset cLevel2
			 .elseif currentLevel == 2
			Map3:
				invoke CreateMap3
				invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset cLevel3
			 .elseif currentLevel == 3
			Map4:
				invoke CreateMap4
				invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset cLevel4
			 .elseif currentLevel == 4
		    Map5:
				invoke CreateMap5
				invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset cLevel5
			.endif
			invoke syStartGame
			invoke syUpdateMap
			; 把当前步数调成0，每移动一步，当前步数加一
			and currentStep, 0
			and isWin, 0
			and isLose, 0
			invoke dwtoa, currentStep, offset cStep
			invoke SendMessage, hStepText, WM_SETTEXT, 0, offset cStep
		;重开
		.elseif eax == IDC_REMAKE
			mov currentLevel, 0
			mov currentStep, 0
			mov isWin, 0
			mov isLose, 0
			invoke syResetGame
		; 上方向键
		.elseif eax == IDC_UP
			.if (isWin == 0) && (isLose == 0)
			invoke MoveUp
			inc currentStep
			invoke dwtoa, currentStep, offset cStep
			invoke SendMessage, hStepText, WM_SETTEXT, 0, offset cStep
			invoke JudgeWin
				.if isWin == 1 && currentLevel == 1;赢了跳第二关
				 ;invoke MessageBox, hWnd, offset cLose, offset GameName, MB_OK
					jmp Map2
				.elseif isWin == 1 && currentLevel == 2; 赢了跳第三关
					jmp Map3
				.elseif isWin == 1 && currentLevel == 3; 赢了跳第四关
					jmp Map4
				.elseif isWin == 1 && currentLevel == 4; 赢了跳第五关
					jmp Map5
				.endif
			.endif
		; 下方向键
		.elseif eax == IDC_DOWN
			.if (isWin == 0) && (isLose == 0)
			invoke MoveDown
			inc currentStep
			invoke dwtoa, currentStep, offset cStep
			invoke SendMessage, hStepText, WM_SETTEXT, 0, offset cStep
			invoke JudgeWin
				.if isWin == 1 && currentLevel == 1; 赢了跳第二关
				 ;invoke MessageBox, hWnd, offset cLose, offset GameName, MB_OK
					jmp Map2
				.elseif isWin == 1 && currentLevel == 2; 赢了跳第三关
					jmp Map3
				.elseif isWin == 1 && currentLevel == 3; 赢了跳第四关
					jmp Map4
				.elseif isWin == 1 && currentLevel == 4; 赢了跳第五关
					jmp Map5
				.endif
			.endif
		; 左方向键
		.elseif eax == IDC_LEFT
			.if (isWin == 0) && (isLose == 0)
			invoke MoveLeft
			inc currentStep
			invoke dwtoa, currentStep, offset cStep
			invoke SendMessage, hStepText, WM_SETTEXT, 0, offset cStep
			invoke JudgeWin
				.if isWin == 1 && currentLevel == 1; 赢了跳第二关
					jmp Map2
				.elseif isWin == 1 && currentLevel == 2; 赢了跳第三关
					jmp Map3
				.elseif isWin == 1 && currentLevel == 3; 赢了跳第四关
					jmp Map4
				.elseif isWin == 1 && currentLevel == 4; 赢了跳第五关
					jmp Map5
				.endif
			.endif
		; 右方向键
		.elseif eax == IDC_RIGHT
			.if (isWin == 0) && (isLose == 0)
			invoke MoveRight
			inc currentStep
			invoke dwtoa, currentStep, offset cStep
			invoke SendMessage, hStepText, WM_SETTEXT, 0, offset cStep
			invoke JudgeWin
				.if isWin == 1 && currentLevel == 1; 赢了跳第二关
					jmp Map2
				.elseif isWin == 1 && currentLevel == 2; 赢了跳第三关
					jmp Map3
				.elseif isWin == 1 && currentLevel == 3; 赢了跳第四关
					jmp Map4
				.elseif isWin == 1 && currentLevel == 4; 赢了跳第五关
					jmp Map5
				.endif
			.endif
		.endif
	.elseif uMsg == WM_ERASEBKGND
		ret
	.elseif uMsg == WM_CLOSE
		invoke DestroyWindow, hWnd
	.elseif uMsg == WM_DESTROY
		invoke PostQuitMessage, 0
	.else
	invoke DefWindowProc, hWnd, uMsg, wParam, lParam
	ret

	.endif

	xor eax, eax

	ret
Calculate endp

InitRec proc hWnd : dword
	; 调用GetDlgItem函数获得方块的句柄
	; 包括整体背景的句柄等
	invoke GetDlgItem, hWnd, IDC_STEP
	mov hStep, eax

	invoke GetDlgItem, hWnd, IDC_STEPTEXT
	mov hStepText, eax

	invoke GetDlgItem, hWnd, IDC_LEVEL
	mov hLevel, eax

	invoke GetDlgItem, hWnd, IDC_LEVELTEXT
	mov hLevelText, eax

	ret
	InitRec endp

InitBrush proc
	; 创建不同种类的画刷颜色
	invoke CreateSolidBrush, DialogBack
	mov hDialogBrush, eax

	ret
InitBrush endp

MoveUp proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	sub edi, 10; edi记录人的上方位置

	; 设置角色脸朝向
	invoke sySetPlayerFace, SY_FACE_UP

	; 判断上方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov  CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变上方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; 刷新格子
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi

	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 10; ecx是人的上上方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			; 刷新格子
			invoke syUpdateGrid, esi
		.else
			; 只可能是空地或存放点，可以移动
			mov CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; 刷新格子
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi

		.endif

	.else
		; 是墙
		invoke syUpdateGrid, esi
	.endif
	ret
MoveUp endp

MoveDown proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	add edi, 10; edi记录人的下方位置

	; 设置角色脸朝向
	invoke sySetPlayerFace, SY_FACE_DOWN

	; 判断下方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变下方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; 刷新格子
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi

	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		add ecx, 10; ecx是人的下下方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
		; 删除了continue
			; 刷新格子
			invoke syUpdateGrid, esi
		.else
			; 只可能是空地或存放点，可以移动
			mov CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; 刷新格子
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi
		.endif

	.else
		; 是墙
		invoke syUpdateGrid, esi
	.endif
	ret
MoveDown endp

MoveLeft proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	sub edi, 1; edi记录人的左方位置

	; 设置角色脸朝向
	invoke sySetPlayerFace, SY_FACE_LEFT

	; 判断左方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变左方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; 刷新格子
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi
	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 1; ecx是人的左左方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			; .continue
			; 刷新格子
			invoke syUpdateGrid, esi
		.else
			; 只可能是空地或存放点，可以移动
			mov dword ptr CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; 刷新格子
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi
		.endif

	.else
		; 是墙
		invoke syUpdateGrid, esi
	.endif
	ret
MoveLeft endp

MoveRight proc
	; 找到当前人的位置
	xor esi, esi
	mov esi, CurrPosition; 假设CurrPosition记录当前人的位置, esi记录当前人位置
	mov edi, esi
	add edi, 1; edi记录人的右方位置

	; 设置角色脸朝向
	invoke sySetPlayerFace, SY_FACE_RIGHT

	; 判断左方格子类型
	; 如果是空地或结束点, 人移动
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; 改变人的当前位置
		mov dword ptr CurrentMapText[edi * 4], 3; 改变右方方格属性
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; 刷新格子
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi
	; 如果是箱子
	.elseif CurrentMapText[edi * 4] == 4
		; 判断箱子那边是什么
		xor ecx, ecx
		mov ecx, edi
		add ecx, 1; ecx是人的右右方位置

		; 如果是围墙或箱子
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			; .continue
			; 刷新格子
			invoke syUpdateGrid, esi
		.else
			; 只可能是空地或存放点，可以移动
			mov dword ptr CurrPosition, edi; 改变人的当前位置
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; 刷新格子
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi
		.endif

	.else
		; 是墙
		invoke syUpdateGrid, esi
	; .continue
	.endif
	ret
MoveRight endp

	; 第一关地图初始化
CreateMap1 proc

	xor ebx, ebx
	.while ebx < REC_LEN
	.if (ebx < 13 || (ebx > 15 && ebx < 23) || (ebx > 25 && ebx < 33) || ebx == 39 || ebx == 40 || ebx == 49 || ebx == 50 || ebx == 59 || ebx == 60 || (ebx > 66 && ebx < 74) || (ebx > 76 && ebx < 84) || ebx > 86)
	mov dword ptr CurrentMapText[ebx * 4], 0
	inc ebx
	.elseif((ebx > 12 && ebx < 16) || ebx == 23 || ebx == 25 || ebx == 33 || (ebx > 34 && ebx < 39) || (ebx > 40 && ebx < 44) || ebx == 48 || ebx == 51 || (ebx > 55 && ebx < 59) || (ebx > 60 && ebx < 65) || ebx == 66 || ebx == 74 || ebx == 76 || (ebx > 83 && ebx < 87))
	mov dword ptr CurrentMapText[ebx * 4], 1
	inc ebx
	.elseif(ebx == 34 || ebx == 45 || ebx == 53)
	mov dword ptr CurrentMapText[ebx * 4], 2
	inc ebx
	.elseif ebx == 55
	mov dword ptr CurrentMapText[ebx * 4], 3
	inc ebx
	.elseif(ebx == 44 || ebx == 46 || ebx == 54 || ebx == 65)
	mov dword ptr CurrentMapText[ebx * 4], 4
	inc ebx
	.elseif(ebx == 24 || ebx == 47 || ebx == 52 || ebx == 75)
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
	mov CurrPosition, 55
	ret

CreateMap1 endp

	; 第二关地图初始化
CreateMap2 proc

	xor ebx, ebx
	.while ebx < REC_LEN
	.if (ebx == 0 || (ebx > 5 && ebx < 11) || (ebx > 15 && ebx < 21) || ebx == 26 || ebx == 30 || ebx == 36 || ebx == 40 || (ebx > 49 && ebx < 52) || (ebx > 59 && ebx < 62) || (ebx > 69 && ebx < 72) || (ebx > 79 && ebx < 82) || ebx > 86)
	mov dword ptr CurrentMapText[ebx * 4], 0
	inc ebx
	.elseif((ebx > 0 && ebx < 6) || ebx == 11 || ebx == 15 || ebx == 21 || ebx == 25 || (ebx > 26 && ebx < 30) || ebx == 31 || ebx == 35 || ebx == 37 || ebx == 39 || (ebx > 40 && ebx < 44) || (ebx > 44 && ebx < 48) || ebx == 49 || ebx == 52 || ebx == 53)
	mov dword ptr CurrentMapText[ebx * 4], 1
	inc ebx
	.elseif(ebx == 59 || ebx == 62 || ebx == 66 || ebx == 69 || ebx == 72 || (ebx > 75 && ebx < 80) || (ebx > 81 && ebx < 87))
	mov dword ptr CurrentMapText[ebx * 4], 1
	inc ebx
	.elseif(ebx == 13 || ebx == 14 || ebx == 22 || ebx == 32 || ebx == 34 || ebx == 44 || (ebx > 53 && ebx < 58) || (ebx > 62 && ebx < 66) || ebx == 67 || ebx == 68 || (ebx > 72 && ebx < 76))
	mov dword ptr CurrentMapText[ebx * 4], 2
	inc ebx
	.elseif ebx == 12
	mov dword ptr CurrentMapText[ebx * 4], 3
	inc ebx
	.elseif(ebx == 23 || ebx == 24 || ebx == 33)
	mov dword ptr CurrentMapText[ebx * 4], 4
	inc ebx
	.elseif(ebx == 38 || ebx == 48 || ebx == 58)
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
	mov CurrPosition, 12
	ret

CreateMap2 endp

	; 第三关地图初始化
CreateMap3 proc

	xor ebx, ebx
	.while ebx < REC_LEN
	.if (ebx < 11 || (ebx > 17 && ebx < 21) || ebx == 69 || ebx == 70 || ebx > 78)
	mov dword ptr CurrentMapText[ebx * 4], 0
	inc ebx
	.elseif((ebx > 21 && ebx < 27) || (ebx > 35 && ebx < 39) || ebx == 41 || ebx == 43 || ebx == 45 || ebx == 46 || ebx == 48 || ebx == 51 || ebx == 55 || ebx == 57 || ebx == 65 || ebx == 66 || ebx == 67)
	mov dword ptr CurrentMapText[ebx * 4], 2
	inc ebx
	.elseif ebx == 42
	mov dword ptr CurrentMapText[ebx * 4], 3
	inc ebx
	.elseif(ebx == 32 || ebx == 44 || ebx == 47 || ebx == 56)
	mov dword ptr CurrentMapText[ebx * 4], 4
	inc ebx
	.elseif(ebx == 52 || ebx == 53 || ebx == 62 || ebx == 63)
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
	mov CurrPosition, 42
	ret
CreateMap3 endp

	; 第四关地图初始化
CreateMap4 proc

	xor ebx, ebx
	.while ebx < REC_LEN
	.if ((ebx > 12 && ebx < 17) || ebx == 22 || ebx == 23 || ebx == 26 || ebx == 32 || ebx == 36 || ebx == 42 || ebx == 43 || ebx == 46 || ebx == 47 || ebx == 52 || ebx == 53 || ebx == 57 || ebx == 62 || ebx == 67 || ebx == 72 || ebx == 77 || (ebx > 81 && ebx < 88))
	mov dword ptr CurrentMapText[ebx * 4], 1
	inc ebx
	.elseif(ebx == 24 || ebx == 25 || ebx == 35 || ebx == 45 || ebx == 54 || ebx == 56 || ebx == 65 || ebx == 66)
	mov dword ptr CurrentMapText[ebx * 4], 2
	inc ebx
	.elseif ebx == 33
	mov dword ptr CurrentMapText[ebx * 4], 3
	inc ebx
	.elseif(ebx == 34 || ebx == 44 || ebx == 55 || ebx == 64 || ebx == 75)
	mov dword ptr CurrentMapText[ebx * 4], 4
	inc ebx
	.elseif(ebx == 63 || ebx == 73 || ebx == 74 || ebx == 76)
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
	mov	CurrPosition,33
	ret
CreateMap4 endp

	; 第五关地图初始化
CreateMap5 proc
	
	xor ebx, ebx
	.while ebx < REC_LEN
		.if ( ebx < 12 || ( ebx > 16 && ebx < 22 ) || ( ebx > 27 && ebx < 32 ) || ( ebx > 37 && ebx < 41 ) || ebx == 49 || ebx == 50 || ebx == 59 || ebx == 60 || ebx == 69 || ebx == 70 || ebx == 79 || ebx == 80 || ebx > 88 )
			mov dword ptr CurrentMapText[ebx * 4], 0
			inc ebx 
		.elseif ( ebx == 24 || ebx == 33 || ebx == 35 || ebx == 36 || ebx == 44 || ebx == 46 || ebx == 54 || ebx == 56 || ebx == 57 || ebx == 64 || ebx == 65 || ebx == 67 || ebx == 73 || ebx == 74 || ebx == 75 || ebx == 77 )
			mov dword ptr CurrentMapText[ebx * 4], 2
			inc ebx
		.elseif ebx == 23
			mov dword ptr CurrentMapText[ebx * 4], 3
			inc ebx
		.elseif ( ebx == 34 || ebx == 63 || ebx == 76 )
			mov dword ptr CurrentMapText[ebx * 4], 4
			inc ebx
		.elseif ( ebx == 52 || ebx == 62 || ebx == 72 )
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
			.if ebx == 75
				mov dword ptr OriginMapText[ebx * 4], 5
			.endif
			inc ebx
		.else
			mov dword ptr OriginMapText[ebx * 4], eax
			inc ebx
		.endif
	.endw
	mov	CurrPosition,23
	ret

CreateMap5 endp


; 主程序
main proc

	invoke GetModuleHandle, NULL
	mov hInstance, eax
	invoke WinMain, hInstance, 0, 0, SW_SHOWNORMAL
	invoke ExitProcess, eax

main endp
end main
