.386
.model flat, stdcall
option casemap: none
includelib msvcrt.lib
printf PROTO C :ptr sbyte, :VARARG	
include sokoban.inc
.data

hInstance		dd		?       ; ��������
hGuide			dd		?       ; �������־��
hLevel			dd		?       ; �ؿ����
hLevelText      dd		?       ; �ؿ��ı����
hStep			dd      ?       ; �������
hStepText		dd		?		; �����ı����
hMenu			dd		?       ; �˵����

hIcon			dd		?       ; ͼ����
hAcce			dd		?       ; �ȼ����
hStage			dd		?       ; �����ⲿ���
hDialogBrush    dd      ?       ; �Ի��򱳾���ˢ
hStageBrush     dd      ?       ; �����ⲿ������ˢ

iScore          dd		0                       ; 0
cScore          db		MAX_LEN dup(0)          ; 0
currentLevel	dd		0
currentStep		dd		0
CurrPosition	dd		0		;��¼�˵�λ��
temp_for_initrec	dd	1018
temp_ebx		dd		0
temp_ecx		dd		0
OriginMapText	dd		MAX_LEN dup(0)			;ԭʼ��ͼ����
CurrentMapText  dd      MAX_LEN dup(0)			;��ǰ��ͼ����

hMapRec			dd		MAX_LEN dup(0)			;��ͼ����������
hMapBack		dd		BRUSH_LEN dup(0)		;�����������
hMapBrush		dd		BRUSH_LEN dup(0)		;��ˢ����

ProgramName		db		"Game", 0               ; ��������
GameName		db		"sokoban", 0               ; ��������
Author			db		"MonsterGe", 0           ; ����
FontName        db		"Microsoft Sans Serif", 0
cGuide          db		"Sokoban!", 0     ; ������Ϣ
cWin            db		"You win! Please click the button to restart", 0    ; �ɹ���Ϣ
cLose           db		"You lose! Please click the button to restart", 0   ; ʧ����Ϣ

isWin			db		0                       ; �ж��Ƿ�ɹ�
isLose			db		0                       ; �ж��Ƿ�ʧ��
cNum0			db		"0", 0
cNum1			db		"1", 0
cNum2			db		"2", 0
cNum3			db		"3", 0
cNum4			db		"4", 0
cNum5			db		"5", 0

iprintf			db		"%d",0ah ,0
.code

WinMain PROC hInst:dword, hPrevInst:dword, cmdLine:dword, cmdShow:dword
	local wc:WNDCLASSEX		;������
	local msg:MSG			;��Ϣ
	local hWnd:HWND			;�Ի�����

	invoke RtlZeroMemory, addr wc, sizeof WNDCLASSEX

	mov wc.cbSize, sizeof WNDCLASSEX				;������Ĵ�С
	mov wc.style, CS_HREDRAW or CS_VREDRAW			;���ڷ��
	mov wc.lpfnWndProc, offset Calculate			;������Ϣ��������ַ
	mov wc.cbClsExtra, 0							;�ڴ�����ṹ���ĸ����ֽ����������ڴ�
	mov wc.cbWndExtra, DLGWINDOWEXTRA				;�ڴ���ʵ����ĸ����ֽ���

	push hInst
	pop wc.hInstance								;��������������

	mov wc.hbrBackground, COLOR_WINDOW				; ������ˢ���
    mov wc.lpszMenuName, NULL						; �˵�����ָ��
    mov wc.lpszClassName, offset ProgramName		; ������������
	; ����ͼ����
	;invoke LoadIcon, hInst, IDI_ICON
	;mov wc.hIcon, eax
	
	; ���ع����
    invoke LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor, eax

	mov wc.hIconSm, 0								;����Сͼ����

	invoke RegisterClassEx, addr wc					;ע�ᴰ����
	;���ضԻ��򴰿�
	invoke CreateDialogParam, hInst, IDD_DIALOG1, 0, offset Calculate, 0
	mov hWnd, eax
	invoke ShowWindow, hWnd, cmdShow				;��ʾ����
	invoke UpdateWindow, hWnd						;���´���
	
    .while TRUE

        invoke GetMessage, addr msg, NULL, 0, 0                 ; ��ȡ��Ϣ
        .break .if eax == 0
        invoke TranslateAccelerator, hWnd, hAcce, addr msg    ; ת����ݼ���Ϣ
        .if eax == 0
            invoke TranslateMessage, addr msg   ; ת��������Ϣ
            invoke DispatchMessage, addr msg    ; �ַ���Ϣ
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
        ; ��ȡ�˵��ľ������ʾ�˵�
        invoke LoadMenu, hInstance, IDR_MENU1
        mov hMenu, eax
        invoke SetMenu, hWnd, hMenu

        ; ��ȡ��ݼ��ľ������ʾ�˵�
        invoke LoadAccelerators, hInstance, IDR_ACCELERATOR2
        mov hAcce, eax

        ; ��ʼ������;���
        invoke InitRec, hWnd
        invoke InitBack
        invoke InitBrush

		; ��������
		invoke CreateFont, 26, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, offset FontName
        mov hf, eax

		; ��ʼ������������
        xor ebx, ebx
        .while ebx < REC_LEN
            invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETTEXT, 0, NULL
			invoke SendMessage, dword ptr hMapRec[ebx * 4], WM_SETFONT, hf, NULL
            inc ebx
        .endw

    .elseif uMsg == WM_PAINT
        ; ���ƶԻ��򱳾�
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke FillRect, hdc, addr ps.rcPaint, hDialogBrush
        invoke EndPaint, hWnd, addr ps
    
	.elseif uMsg == WM_CTLCOLORSTATIC
        ; ���ƾ�̬�ı���
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

        ; ��õ�ǰ�����ķ�����
        xor ebx, ebx
        .while (dword ptr hMapRec[ebx * 4] != ecx) && (ebx < REC_LEN)
            inc ebx
        .endw

        invoke ShowNumber
		mov eax,TextColor
        invoke SetTextColor, wParam, TextColor              ; �����ı���ɫ
		movzx esi, word ptr CurrentMapText[ebx * 2]         ; �������ִ�Сѡ���ˢ
        invoke SetBkColor, wParam, dword ptr hMapBack[esi * 4] ; ���Ʊ�����ɫ

        mov eax, dword ptr hMapBrush[esi * 4]                  ; ���ر�ˢ�Ա��ͼ

        ret
	.elseif uMsg == WM_COMMAND
		mov eax, wParam
        movzx eax, ax       ; �������
		;��ʼ����Ϸ����ʱ��Ҫ���ص�ǰ�ؿ���Ӧ�ĵ�ͼ
		.if eax == IDC_NEW || eax == ID_NEW
			;���ü��ص�ͼ�ĺ���
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
			;�ѵ�ǰ��������0��ÿ�ƶ�һ������ǰ������һ
			and currentStep, 0
            and isWin, 0
            and isLose, 0

		 ;�Ϸ����
		.elseif eax == IDC_UP
			.if (isWin == 0) && (isLose == 0)
				invoke MoveUp
				invoke RefreshRec
			.endif
				;�����Ȳ���
		 ;�·����
		.elseif eax == IDC_DOWN
			.if (isWin == 0) && (isLose == 0)
				invoke MoveDown
				invoke RefreshRec
			.endif
		;�����
		.elseif eax == IDC_LEFT
			.if (isWin == 0) && (isLose == 0)
				invoke MoveLeft
				invoke RefreshRec
			.endif
		;�ҷ����
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
;����GetDlgItem������÷���ľ��
;�������屳���ľ����100������ľ����
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
;���ò�ͬ���෽���Ӧ����ɫ���浽hMapBack��������
;һ�����֣�ǽ�⡢ǽ���յء��ˡ��䡢������
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
;������ͬ����Ļ�ˢ��ɫ
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
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	sub edi, 10; edi��¼�˵��Ϸ�λ��


	; �ж��Ϸ���������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov  CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��Ϸ���������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 10; ecx���˵����Ϸ�λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4

		; ֻ�����ǿյػ��ŵ㣬�����ƶ�
		.else
		mov CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[ecx * 4], 4
		mov dword ptr CurrentMapText[edi * 4], 3
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

		.endif

	; �����Χǽ, ���ı��ͼ
	.else
	ret
	.endif
	ret
MoveUp endp

MoveDown proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	add edi, 10; edi��¼�˵��·�λ��

	; �ж��·���������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��·���������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		add ecx, 10; ecx���˵����·�λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			;ɾ����continue

		; ֻ�����ǿյػ��ŵ㣬�����ƶ�
		.else
			mov CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
		.endif

	; �����Χǽ, ���ı��ͼ
	.else
		;.continue
	.endif
ret
MoveDown endp

MoveLeft proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	sub edi, 1; edi��¼�˵���λ��

	; �ж��󷽸�������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��󷽷�������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 1; ecx���˵�����λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			;.continue

		; ֻ�����ǿյػ��ŵ㣬�����ƶ�
		.else
			mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
		.endif

	; �����Χǽ, ���ı��ͼ
	.else
		;.continue
	.endif
	ret
MoveLeft endp

MoveRight proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	add edi, 1; edi��¼�˵��ҷ�λ��

	; �ж��󷽸�������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��ҷ���������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax

		; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		add ecx, 1; ecx���˵����ҷ�λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			;.continue

		; ֻ�����ǿյػ��ŵ㣬�����ƶ�
		.else
			mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
		.endif

	; �����Χǽ, ���ı��ͼ
	.else
		;.continue
	.endif
	ret
MoveRight endp

;��һ�ص�ͼ��ʼ��
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

;�ڶ��ص�ͼ��ʼ��
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

;�����ص�ͼ��ʼ��
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

;���Ĺص�ͼ��ʼ��
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
; ������
main proc

    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke WinMain, hInstance, 0, 0, SW_SHOWNORMAL
	invoke ExitProcess, eax

main endp
end main