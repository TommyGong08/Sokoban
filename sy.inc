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

; ��������

; ����������id
; win: HWND ����id
sySetMainWinId proto win: HWND
; ��ʼ��Ϸ
syStartGame proto
; ������Ϸ
syResetGame proto
; ��ȡ��Ϸ�Ƿ�ʼ
syIsGameStarted proto
; ˢ��ȫͼ
syUpdateMap proto
; ˢ�¸���
; u32GridInd: dword ���Ӻ�
syUpdateGrid proto u32GridInd: dword
; ����ȫͼ
; devc: HDC �豸������id
syDrawMap proto devc: HDC

; ����λͼ
syLoadImage proto
; ��ʼ����
syBeginDraw proto
; ��������
syEndDraw proto
; ����λͼ
; bitmap: HBITMAP λͼid
; i32X: sword ����λ��x
; i32Y: sword ����λ��y
; u32Width: dword ���ƿ���
; u32Height: dword ���Ƹ߶�
syDrawImage proto bitmap: HBITMAP, i32X: sword, i32Y: sword, u32Width: dword, u32Height: dword

; ��������

REC_LEN equ 100

externdef OriginMapText: dword
externdef CurrentMapText: dword
; ��Ϸ�Ƿ�ʼ
externdef syGameStarted: byte

endif