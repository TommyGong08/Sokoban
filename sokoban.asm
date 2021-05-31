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

hInstance		dd ? ; ��������
hGuide			dd ? ; �������־��
hLevel			dd ? ; �ؿ����
hLevelText      dd ? ; �ؿ��ı����
hStep			dd ? ; �������
hStepText		dd ? ; �����ı����
hMenu			dd ? ; �˵����

hIcon			dd ? ; ͼ����
hAcce			dd ? ; �ȼ����
hStage			dd ? ; �����ⲿ���
hDialogBrush    dd ? ; �Ի��򱳾���ˢ
hStageBrush     dd ? ; �����ⲿ������ˢ

iScore          dd		0; 0
cScore          db		MAX_LEN dup(0); 0
currentLevel	dd		0;��¼��ǰ�ؿ�
currentStep		dd		0
CurrPosition	dd		0; ��¼�˵�λ��
temp_for_initrec	dd	1018
temp_ebx		dd		0
temp_ecx		dd		0
OriginMapText	dd		MAX_LEN dup(0); ԭʼ��ͼ����
CurrentMapText  dd      MAX_LEN dup(0); ��ǰ��ͼ����

ProgramName		db		"Game", 0; ��������
GameName		db		"sokoban", 0; ��������
Author			db		"MonsterGe", 0; ����
cGuide          db		"Sokoban!", 0; ������Ϣ
cWin            db		"You win! Please click the button to restart", 0; �ɹ���Ϣ
cLose           db		"You lose! Please click the button to restart", 0; ʧ����Ϣ
szFormat	    db	    "%d ", 0
isWin			db		0; �ж��Ƿ�ɹ�
isLose			db		0; �ж��Ƿ�ʧ��

iprintf			db		"%d", 0ah, 0
.code

WinMain PROC hInst : dword, hPrevInst : dword, cmdLine : dword, cmdShow : dword
	local wc : WNDCLASSEX; ������
	local msg : MSG; ��Ϣ
	local hWnd : HWND; �Ի�����

	invoke RtlZeroMemory, addr wc, sizeof WNDCLASSEX

	mov wc.cbSize, sizeof WNDCLASSEX; ������Ĵ�С
	mov wc.style, CS_HREDRAW or CS_VREDRAW; ���ڷ��
	mov wc.lpfnWndProc, offset Calculate; ������Ϣ��������ַ
	mov wc.cbClsExtra, 0; �ڴ�����ṹ���ĸ����ֽ����������ڴ�
	mov wc.cbWndExtra, DLGWINDOWEXTRA; �ڴ���ʵ����ĸ����ֽ���

	push hInst
	pop wc.hInstance; ��������������

	mov wc.hbrBackground, COLOR_WINDOW; ������ˢ���
	mov wc.lpszMenuName, NULL; �˵�����ָ��
	mov wc.lpszClassName, offset ProgramName; ������������
	; ����ͼ����
	; invoke LoadIcon, hInst, IDI_ICON
	; mov wc.hIcon, eax

	; ���ع����
	invoke LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor, eax

	mov wc.hIconSm, 0; ����Сͼ����

	invoke RegisterClassEx, addr wc; ע�ᴰ����
	; ���ضԻ��򴰿�
	invoke CreateDialogParam, hInst, IDD_DIALOG1, 0, offset Calculate, 0
	mov hWnd, eax
	
	; ����������id
	invoke sySetMainWinId, eax

	invoke ShowWindow, hWnd, cmdShow; ��ʾ����
	invoke UpdateWindow, hWnd; ���´���

	; ��Ϣѭ��
	.while TRUE
		invoke GetMessage, addr msg, NULL, 0, 0; ��ȡ��Ϣ
		.break .if eax == 0
		invoke TranslateAccelerator, hWnd, hAcce, addr msg; ת����ݼ���Ϣ
		.if eax == 0
			invoke TranslateMessage, addr msg; ת��������Ϣ
			invoke DispatchMessage, addr msg; �ַ���Ϣ
		.endif
	.endw

	mov eax, msg.wParam
	ret
WinMain endp


; �ж���Ӯ
JudgeWin proc
	; ��ͼ�в���������5��֤������ȫ����λ
	xor eax, eax
	xor ebx, ebx; ebx��¼ͼ�����Ӵ�ŵ�����
	mov eax, 0
	.while eax < MAX_LEN
		.if OriginMapText[eax * 4] == 5 
			;���Origin��5��λ�� Current����4������
			.if CurrentMapText[eax * 4] == 4
			jmp L1
			.else ;������4,˵��û�ɹ�
				jmp NotWin
			.endif 
		.endif
L1:		inc eax
	.endw
	mov isWin, 1 ;�þֻ�ʤ
	inc currentLevel ;�ؿ���+1
	invoke crt_printf, addr szFormat, isWin
	ret
NotWin:		
	mov isWin, 0 
	invoke crt_printf, addr szFormat, isWin

	ret
JudgeWin endp

Calculate proc hWnd : dword, uMsg : UINT, wParam : WPARAM, lParam : LPARAM
	local hdc : HDC
	local ps : PAINTSTRUCT

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
		invoke InitBrush

	.elseif uMsg == WM_PAINT
		; ���ƶԻ��򱳾�
		invoke BeginPaint, hWnd, addr ps
		mov hdc, eax
		invoke FillRect, hdc, addr ps.rcPaint, hDialogBrush

		; ���Ƶ�ͼ
		invoke syDrawMap, hdc

		invoke EndPaint, hWnd, addr ps

	.elseif uMsg == WM_COMMAND
		mov eax, wParam
		movzx eax, ax; �������
		; ��ʼ����Ϸ����ʱ��Ҫ���ص�ǰ�ؿ���Ӧ�ĵ�ͼ
		.if eax == IDC_NEW || eax == ID_NEW
			; ���ü��ص�ͼ�ĺ���
			.if currentLevel == 0
				invoke CreateMap1
				; invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 1
			.elseif currentLevel == 1
			Map2:	
				invoke CreateMap2
				; invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 2
			 .elseif currentLevel == 2
			Map3:
				invoke CreateMap3
				; invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 3
				; .elseif currentLevel == 3
			Map4:
				invoke CreateMap4
			; invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 4
			;.elseif currentLevel == 4
		;Map5:
			;invoke CreateMap5
			; invoke SendMessage, hLevelText, WM_SETTEXT, 0, offset 5
			.endif
			invoke syStartGame
			invoke syUpdateMap
			; invoke SendMessage, hStepText, WM_SETTEXT, 0, offset 0
			; �ѵ�ǰ��������0��ÿ�ƶ�һ������ǰ������һ
			and currentStep, 0
			and isWin, 0
			and isLose, 0

		.elseif eax == IDC_REMAKE
			; �ؿ���Ϸ

			mov currentLevel, 0
			mov currentStep, 0
			mov isWin, 0
			mov isLose, 0

			invoke syResetGame
		; �Ϸ����
		.elseif eax == IDC_UP
			invoke syIsGameStarted
			.if eax
				; ��Ϸ��ʼ��
				.if (isWin == 0) && (isLose == 0)
				invoke MoveUp
				invoke JudgeWin
					.if isWin == 1 && currentLevel == 1;Ӯ�����ڶ���
						jmp Map2
					.elseif isWin == 1 && currentLevel == 2; Ӯ����������
						jmp Map3
					.elseif isWin == 1 && currentLevel == 3; Ӯ�������Ĺ�
						jmp Map4
					;.elseif isWin == 1 && currentLevel == 4; Ӯ���������
						;jmp Map5
					.endif
				.endif
				; �����Ȳ���
			.endif
		; �·����
		.elseif eax == IDC_DOWN
			invoke syIsGameStarted
			.if eax
				; ��Ϸ��ʼ��
				.if (isWin == 0) && (isLose == 0)
				invoke MoveDown
				invoke JudgeWin
					.if isWin == 1 && currentLevel == 1; Ӯ�����ڶ���
					jmp Map2
					.elseif isWin == 1 && currentLevel == 2; Ӯ����������
					jmp Map3
					.elseif isWin == 1 && currentLevel == 3; Ӯ�������Ĺ�
					jmp Map4
					; .elseif isWin == 1 && currentLevel == 4; Ӯ���������
					; jmp Map5
					.endif
				.endif
			.endif
		; �����
		.elseif eax == IDC_LEFT
			invoke syIsGameStarted
			.if eax
				; ��Ϸ��ʼ��
				.if (isWin == 0) && (isLose == 0)
				invoke MoveLeft
				invoke JudgeWin
					.if isWin == 1 && currentLevel == 1; Ӯ�����ڶ���
					jmp Map2
					.elseif isWin == 1 && currentLevel == 2; Ӯ����������
					jmp Map3
					.elseif isWin == 1 && currentLevel == 3; Ӯ�������Ĺ�
					jmp Map4
					; .elseif isWin == 1 && currentLevel == 4; Ӯ���������
					; jmp Map5
					.endif
				.endif
			.endif
		; �ҷ����
		.elseif eax == IDC_RIGHT
			invoke syIsGameStarted
			.if eax
				; ��Ϸ��ʼ��
				.if (isWin == 0) && (isLose == 0)
				invoke MoveRight
				invoke JudgeWin
					.if isWin == 1 && currentLevel == 1; Ӯ�����ڶ���
					jmp Map2
					.elseif isWin == 1 && currentLevel == 2; Ӯ����������
					jmp Map3
					.elseif isWin == 1 && currentLevel == 3; Ӯ�������Ĺ�
					jmp Map4
					; .elseif isWin == 1 && currentLevel == 4; Ӯ���������
					; jmp Map5
					.endif
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
	; ����GetDlgItem������÷���ľ��
	; �������屳���ľ����
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
	; ������ͬ����Ļ�ˢ��ɫ
	invoke CreateSolidBrush, DialogBack
	mov hDialogBrush, eax

	ret
InitBrush endp

MoveUp proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	sub edi, 10; edi��¼�˵��Ϸ�λ��

	; ���ý�ɫ������
	invoke sySetPlayerFace, SY_FACE_UP

	; �ж��Ϸ���������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov  CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��Ϸ���������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; ˢ�¸���
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi

	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 10; ecx���˵����Ϸ�λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			; ˢ�¸���
			invoke syUpdateGrid, esi
		.else
			; ֻ�����ǿյػ��ŵ㣬�����ƶ�
			mov CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; ˢ�¸���
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi

		.endif

	.else
		; ��ǽ
		invoke syUpdateGrid, esi
	.endif
	ret
MoveUp endp

MoveDown proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	add edi, 10; edi��¼�˵��·�λ��

	; ���ý�ɫ������
	invoke sySetPlayerFace, SY_FACE_DOWN

	; �ж��·���������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��·���������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; ˢ�¸���
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi

	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		add ecx, 10; ecx���˵����·�λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
		; ɾ����continue
			; ˢ�¸���
			invoke syUpdateGrid, esi
		.else
			; ֻ�����ǿյػ��ŵ㣬�����ƶ�
			mov CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; ˢ�¸���
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi
		.endif

	.else
		; ��ǽ
		invoke syUpdateGrid, esi
	.endif
	ret
MoveDown endp

MoveLeft proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	sub edi, 1; edi��¼�˵���λ��

	; ���ý�ɫ������
	invoke sySetPlayerFace, SY_FACE_LEFT

	; �ж��󷽸�������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��󷽷�������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; ˢ�¸���
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi
	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		sub ecx, 1; ecx���˵�����λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			; .continue
			; ˢ�¸���
			invoke syUpdateGrid, esi
		.else
			; ֻ�����ǿյػ��ŵ㣬�����ƶ�
			mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; ˢ�¸���
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi
		.endif

	.else
		; ��ǽ
		invoke syUpdateGrid, esi
	.endif
	ret
MoveLeft endp

MoveRight proc
	; �ҵ���ǰ�˵�λ��
	xor esi, esi
	mov esi, CurrPosition; ����CurrPosition��¼��ǰ�˵�λ��, esi��¼��ǰ��λ��
	mov edi, esi
	add edi, 1; edi��¼�˵��ҷ�λ��

	; ���ý�ɫ������
	invoke sySetPlayerFace, SY_FACE_RIGHT

	; �ж��󷽸�������
	; ����ǿյػ������, ���ƶ�
	.if CurrentMapText[edi * 4] == 2 || CurrentMapText[edi * 4] == 5
		mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
		mov dword ptr CurrentMapText[edi * 4], 3; �ı��ҷ���������
		mov eax, OriginMapText[esi * 4]
		mov CurrentMapText[esi * 4], eax
		; ˢ�¸���
		invoke syUpdateGrid, edi
		invoke syUpdateGrid, esi
	; ���������
	.elseif CurrentMapText[edi * 4] == 4
		; �ж������Ǳ���ʲô
		xor ecx, ecx
		mov ecx, edi
		add ecx, 1; ecx���˵����ҷ�λ��

		; �����Χǽ������
		.if CurrentMapText[ecx * 4] == 1 || CurrentMapText[ecx * 4] == 4
			; .continue
			; ˢ�¸���
			invoke syUpdateGrid, esi
		.else
			; ֻ�����ǿյػ��ŵ㣬�����ƶ�
			mov dword ptr CurrPosition, edi; �ı��˵ĵ�ǰλ��
			mov dword ptr CurrentMapText[ecx * 4], 4
			mov dword ptr CurrentMapText[edi * 4], 3
			mov eax, OriginMapText[esi * 4]
			mov CurrentMapText[esi * 4], eax
			; ˢ�¸���
			invoke syUpdateGrid, ecx
			invoke syUpdateGrid, edi
			invoke syUpdateGrid, esi
		.endif

	.else
		; ��ǽ
		invoke syUpdateGrid, esi
	; .continue
	.endif
	ret
MoveRight endp


	; ��һ�ص�ͼ��ʼ��
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

	; �ڶ��ص�ͼ��ʼ��
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

	; �����ص�ͼ��ʼ��
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

	; ���Ĺص�ͼ��ʼ��
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

; ������
main proc

	invoke GetModuleHandle, NULL
	mov hInstance, eax
	invoke WinMain, hInstance, 0, 0, SW_SHOWNORMAL
	invoke ExitProcess, eax

main endp
end main