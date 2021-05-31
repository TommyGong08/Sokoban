.386
.model flat, stdcall
option casemap: none

include sy.inc

.data

; 位图文件名
syTitleFileName byte "title.bmp", 0h
syBoxFileName byte "box.bmp", 0h
syPlayerFileName byte "player.bmp", 0h
syWallFileName byte "wall.bmp", 0h
syEmptyFileName byte "empty.bmp", 0h
syTargetFileName byte "target.bmp", 0h
syBoxTargetFileName byte "box-target.bmp", 0h

; 位图
syTitleBitmap HBITMAP ?
syBoxBitmap HBITMAP ?
syPlayerBitmap HBITMAP ?
syWallBitmap HBITMAP ?
syEmptyBitmap HBITMAP ?
syTargetBitmap HBITMAP ?
syBoxTargetBitmap HBITMAP ?

; 主窗体id
syMainWinId HWND ?
; DC
; I hate GDI
syMainWinDC HDC ?
syMainBitmapDC HDC ?

; 游戏是否开始
syGameStarted byte 0

; 地图区域x
SY_MAPX equ 144
; 地图区域y
SY_MAPY equ 192
; 格子尺寸
SY_GRID_SIZE equ 48
SY_MAP_SIZE equ 480

; 地图类型x
SY_GRID_TYPE_NOTHING equ 0
SY_GRID_TYPE_WALL equ 1
SY_GRID_TYPE_EMPTY equ 2
SY_GRID_TYPE_PLAYER equ 3
SY_GRID_TYPE_BOX equ 4
SY_GRID_TYPE_TARGET equ 5
SY_GRID_TYPE_BOX_TARGET equ 6

fmt byte "left: %d", 0ah, 0h

.code

sySetMainWinId proc win: HWND
	; 设置主窗体id，省得传来传去
	mov eax, win
	mov syMainWinId, eax

	ret
sySetMainWinId endp

syStartGame proc
	mov syGameStarted, 1

	ret
syStartGame endp

syResetGame proc
	mov syGameStarted, 0
	invoke syUpdateMap

	ret
syResetGame endp

syIsGameStarted proc
	movzx eax, syGameStarted

	ret
syIsGameStarted endp

syGetGridType proc u32Index: dword
	; 获取格子类型
	local oldebx: dword ; I hate Assembler

	mov oldebx, ebx
	mov ebx, u32Index

	mov eax, CurrentMapText[ebx * 4]

	.if eax == SY_GRID_TYPE_BOX
		mov eax, OriginMapText[ebx * 4]
		.if eax == SY_GRID_TYPE_TARGET
			; 在目标点
			mov eax, SY_GRID_TYPE_BOX_TARGET
		.else
			; 不在目标点
			mov eax, SY_GRID_TYPE_BOX
		.endif
	.endif

	mov ebx, oldebx

	ret
syGetGridType endp

syUpdateMap proc
	; 无效化地图区域
	local rect: RECT

	; [rect.left, rect.top, rect.right, rect.bottom] = [SY_MAPX, SY_MAPY, SY_MAPX + SY_MAP_SIZE, SY_MAPY + SY_MAP_SIZE]
	mov rect.left, SY_MAPX
	mov rect.top, SY_MAPY

	mov eax, SY_MAP_SIZE
	add eax, SY_MAPX
	mov rect.right, eax

	mov eax, SY_MAP_SIZE
	add eax, SY_MAPY
	MOV rect.bottom, eax

	invoke InvalidateRect, syMainWinId, addr rect, TRUE

	ret
syUpdateMap endp

syUpdateGrid proc u32GridInd: dword
	; 无效化格子
	local rect: RECT
	local p: dword
	
	; p = u32GridInd / 10
	; edx = u32GridInd % 10
	mov eax, u32GridInd
	mov ebx, 10
	div ebx
	mov p, eax

	; rect.left = SY_MAPX + edx * SY_GRID_SIZE
	mov eax, edx
	mov ebx, SY_GRID_SIZE
	mul ebx
	add eax, SY_MAPX
	mov rect.left, eax
	; rect.right = rect.left + SY_GRID_SIZE
	add eax, SY_GRID_SIZE
	mov rect.right, eax

	; rect.top = SY_MAPY + p * SY_GRID_SIZE
	mov eax, p
	mov ebx, SY_GRID_SIZE
	mul ebx
	add eax, SY_MAPY
	mov rect.top, eax
	; rect.bottom = rect.top + SY_GRID_SIZE
	add eax, SY_GRID_SIZE
	MOV rect.bottom, eax

	invoke InvalidateRect, syMainWinId, addr rect, FALSE

	ret
syUpdateGrid endp

syDrawMap proc devc: HDC
	; 绘制地图
	local nextX: sword ; 循环中下一个x
	local nextY: sword ; 循环中下一个y
	local colInd: dword ; 循环中列号
	
	; 保存主窗体DC
	mov eax, devc
	mov syMainWinDC, eax
	invoke syLoadImage
	invoke syBeginDraw

	.if !syGameStarted
		; 游戏没有开始
		; 绘制主界面

		invoke syDrawImage, syTitleBitmap, SY_MAPX, SY_MAPY, SY_MAP_SIZE, SY_MAP_SIZE
	.else
		; 游戏开始了
		; 绘制所有格子（可优化）

		; 循环绘制方格
		mov nextX, SY_MAPX
		mov nextY, SY_MAPY
		mov colInd, 0
		xor ebx, ebx
		.while ebx < REC_LEN
			invoke syGetGridType, ebx
			; 该画啥画啥
			.if eax == SY_GRID_TYPE_WALL
				invoke syDrawImage, syWallBitmap, nextX, nextY, SY_GRID_SIZE, SY_GRID_SIZE
			.elseif eax == SY_GRID_TYPE_EMPTY
				invoke syDrawImage, syEmptyBitmap, nextX, nextY, SY_GRID_SIZE, SY_GRID_SIZE
			.elseif eax == SY_GRID_TYPE_PLAYER
				invoke syDrawImage, syPlayerBitmap, nextX, nextY, SY_GRID_SIZE, SY_GRID_SIZE
			.elseif eax == SY_GRID_TYPE_BOX
				invoke syDrawImage, syBoxBitmap, nextX, nextY, SY_GRID_SIZE, SY_GRID_SIZE
			.elseif eax == SY_GRID_TYPE_TARGET
				invoke syDrawImage, syTargetBitmap, nextX, nextY, SY_GRID_SIZE, SY_GRID_SIZE
			.elseif eax == SY_GRID_TYPE_BOX_TARGET
				invoke syDrawImage, syBoxTargetBitmap, nextX, nextY, SY_GRID_SIZE, SY_GRID_SIZE
			.endif

			add nextX, SY_GRID_SIZE
			inc colInd
			.if colInd == 10
				; 列号到10了，开始下一行
				mov nextX, SY_MAPX
				add nextY, SY_GRID_SIZE
				mov colInd, 0
			.endif

			inc ebx
		.endw
	.endif
	
	invoke syEndDraw

	ret
syDrawMap endp

syLoadImage proc
	; 加载位图

	.if !syGameStarted
		; 游戏没有开始
		; 加载主界面位图

		invoke LoadImage, NULL, offset syTitleFileName, IMAGE_BITMAP, SY_MAP_SIZE, SY_MAP_SIZE, LR_LOADFROMFILE
		mov syTitleBitmap, eax
	.else
		; 游戏开始了
		; 加载格子位图

		invoke LoadImage, NULL, offset syBoxFileName, IMAGE_BITMAP, SY_GRID_SIZE, SY_GRID_SIZE, LR_LOADFROMFILE
		mov syBoxBitmap, eax
		invoke LoadImage, NULL, offset syPlayerFileName, IMAGE_BITMAP, SY_GRID_SIZE, SY_GRID_SIZE, LR_LOADFROMFILE
		mov syPlayerBitmap, eax
		invoke LoadImage, NULL, offset syWallFileName, IMAGE_BITMAP, SY_GRID_SIZE, SY_GRID_SIZE, LR_LOADFROMFILE
		mov syWallBitmap, eax
		invoke LoadImage, NULL, offset syEmptyFileName, IMAGE_BITMAP, SY_GRID_SIZE, SY_GRID_SIZE, LR_LOADFROMFILE
		mov syEmptyBitmap, eax
		invoke LoadImage, NULL, offset syTargetFileName, IMAGE_BITMAP, SY_GRID_SIZE, SY_GRID_SIZE, LR_LOADFROMFILE
		mov syTargetBitmap, eax
		invoke LoadImage, NULL, offset syBoxTargetFileName, IMAGE_BITMAP, SY_GRID_SIZE, SY_GRID_SIZE, LR_LOADFROMFILE
		mov syBoxTargetBitmap, eax
	.endif

	ret
syLoadImage endp

syBeginDraw proc
	; 创建DC
	invoke CreateCompatibleDC, syMainWinDC
	mov syMainBitmapDC, eax

	ret
syBeginDraw endp

syDrawImage proc bitmap: HBITMAP, i32X: sword, i32Y: sword, u32Width: dword, u32Height: dword
	; 输出位图数据
	invoke SelectObject, syMainBitmapDC, bitmap
	invoke BitBlt, syMainWinDC, i32X, i32Y, u32Width, u32Height, syMainBitmapDC, 0, 0, SRCCOPY
	ret
syDrawImage endp

syEndDraw proc
	; 删除位图

	.if !syGameStarted
		; 游戏没有开始
		; 删除主界面位图

		invoke DeleteObject, syTitleBitmap
	.else
		; 游戏开始了
		; 删除格子位图

		invoke DeleteObject, syBoxBitmap
		invoke DeleteObject, syPlayerBitmap
		invoke DeleteObject, syWallBitmap
		invoke DeleteObject, syEmptyBitmap
		invoke DeleteObject, syTargetBitmap
		invoke DeleteObject, syBoxTargetBitmap
	.endif

	; 删除DC
	invoke DeleteDC, syMainBitmapDC

	ret
syEndDraw endp
end