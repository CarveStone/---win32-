;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; by CarveStone
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ʹ�� nmake ������������б��������:
; ml /c /coff ������.asm
; Link /subsystem:windows ������.obj
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.386
		.model flat,stdcall
		option casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include �ļ�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include		windows.inc
include		gdi32.inc
includelib	gdi32.lib
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
include		Msimg32.inc
includelib	Msimg32.lib
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;EQU
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ICO_MAIN	equ	1000h
IDB_BLACK	equ	100
IDB_WHITE	equ	101
IDB_BG		equ	102
IDB_BOARD	equ	103
IDC_BACK	equ	104
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	�ṹ
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
StackBack	STRUCT	;���ڻ���
	x	WORD	?	;���ӵ���������
	y	WORD	?	;
	ALIGN	DWORD	
	;State	DWORD	?	;1��ʾ���壬0��ʾ����
	Top	DWORD	?

StackBack	ENDS
PosInfo	STRUCT			;����λ����Ϣ
	State	DWORD	?	;λ��״̬��0�����ӣ�1�����ӣ�2����
	x_0	DWORD	?	;����	���������
	x_45	DWORD	?	;��б��	���������
	x_90	DWORD	?	;����	���������
	x_135	DWORD	?	;��б��	���������
	
	back	StackBack	<>	;����
PosInfo	ENDS


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ���ݶ�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.data?
hInstance	dd		?
hWinMain	dd		?	
hBmpBoard	dd		?	;���̾��
;hDcBoard	dd		?	;����DC���
hBrush		dd		?	;��ˢ���
hBlack		dd		?	;����
hWhite		dd		?	;����
hDcBlack	dd		?	;����DC���
hDcWhite	dd		?	;����DC���
hButton		dd		?	;��ť���
IDC_Button	dw		?	;��ť�ؼ�
hreStart	dd		?	;���¿�ʼ��ť���
IDC_reStart	dw		?	;���¿�ʼ��ť�ؼ�
Side		dd		?	;�ڰ�˫��
lSide		dd		?	;��һ��Side
click_x		dd		?	;���λ��x
click_y		dd		?	;���λ��y
gPos		dd		?	;һά����λ��	ȫ�ֱ���
MaxCount	dd		?	;����������
;row_index	dd		?	;���ڶ�ά���� ��
;column_index	dd		?	;             ��
step_number	dd		?	;����



;szBuffer	db	10 dup	(?)
;szBuf		db	10 dup	(?)
ChessPos	db	225 dup	(?)
		.data
ChessBoard	PosInfo	225 DUP (<2,0,0,0,0>)
GameOver	db		FALSE	;ʤ����־



		.const
szClassName	db	'MyClass',0
szCaptionMain	db	'������',0
szButton	db	'button',0
szButtonText	db	'����',0
szButtonStart	db	'���¿�ʼ',0
szText1		db	'�ڷ�ʤ��',0
szText2		db	'�׷�ʤ��',0
szCaption	db	'Game Over',0
dwidth		dd	16
szButtonName	dd	"����",0
;lpFmt		db	'%d',0
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_OnTheGrid	proc	x,y
;*******************************************************************
; ����������������õ������������ϵ�����λ��   ����(75,110)==>(1,2)
;*******************************************************************
	local	Grid,eGrid
	mov	Grid,35				
	mov	eGrid,23
	
	fild	x
	fisub	eGrid				;int((x-40)/Grid)
	fidiv	Grid	
	fistp x
	
	fild	y
	fisub	eGrid				;int((y-40)/Grid)
	fidiv	Grid	
	fistp y
	mov	ebx,x
	mov	ecx,y
	mov	click_x,ebx
	mov	click_y,ecx
		
	ret
_OnTheGrid	endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_GetArrPos	proc	x,y
;************************************************
; �õ������������ϵ�λ������  ���磺(1,2)==>(16)
;************************************************
		
	mov	ebx,15
	;click_x+click_y*15
	mov	eax,y
	mul	ebx
	add	eax,x
	
	ret

_GetArrPos	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Update_array_structure	proc	State,x,y,Top,Pos
;********************************************************************
;	��������ṹ			
;********************************************************************
	;local	num
	mov	esi,offset ChessBoard
	mov	eax,Pos

	;mov	bx, TYPE PosInfo	;ָ���Ӧ������
	imul	ebx,eax,28
	
	mov	eax,State
	mov	(PosInfo PTR [esi + ebx]).State,eax
	
	

	mov	edi,esi
	add	edi,offset PosInfo.back
	mov	eax,x
	imul	ebx,Pos,8
	
	
	mov	(StackBack PTR [edi+ebx]).x,ax

	mov	eax,y
	mov	(StackBack PTR [edi+ebx]).y,ax
	
	mov	eax,Top
	dec	eax
	mov	eax,Top
	mov	(PosInfo PTR [esi + ebx]).back.Top,eax
	
	ret
Update_array_structure	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
generateAllNextPossibleMove	proc	pos,nType
;********************************************************************
;	�ҳ�˫�����п������ӵ�λ��
;********************************************************************
	local	nState,tx,ty,x,y,nCurChess,nSearchChess
	mov	esi,offset ChessBoard
	imul	ebx,pos,28

	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nState,eax






	ret
generateAllNextPossibleMove	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
pointsFilter	porc
;********************************************************************
;	����Щλ���н�����ѡ��ѡ���ܹ������������Ƶ�����λ�ã�
;	���ٲ����������ڵ�Ĵ���
;********************************************************************
	ret
pointsFilter	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawChess	proc	hDc,Click_X,Click_Y,state
;********************************************************************
;	��ָ��λ�û�������	
;	���������������꣬����״̬1��0
;********************************************************************
	local	Grid,eGrid,x:dword,y:dword	;��x��y����ʾ���ӵ���������
	
	mov	Grid,35	;35.36			
	mov	eGrid,23

	.if	Click_X>=0 && Click_X<=14 && Click_Y>=0 && Click_Y<=14
	
	
		;mov	ebx,click_x
		;mov	arr_x,ebx
		;mov	ebx,click_y
		;mov	arr_y,ebx
				
		mov	eax,Click_X
		mul	Grid
		add	eax,eGrid
		sub	eax,dwidth
		mov	x,eax
				
		mov	eax,Click_Y
		mul	Grid
		add	eax,eGrid
		sub	eax,dwidth
		mov	y,eax

		.if	state == 0
			invoke	TransparentBlt,hDc,x,y,32,32,hDcWhite,0,0,32,32,00ffffffh
		.elseif	state == 1

			invoke	TransparentBlt,hDc,x,y,32,32,hDcBlack,0,0,32,32,00ffffffh
		.endif
	.endif
	ret

DrawChess	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawChessBoardToWnd	proc	
;********************************************************************
;	������ӳ��������̵�����
;********************************************************************
	local	x,y,hDc ;,pos
	
	mov	y,0
	mov	x,0
	invoke	GetDC,hWinMain		;��ȡ�豸�������
	mov	hDc,eax
	invoke	CreatePatternBrush,hBmpBoard			;����
	mov	hBrush,eax
	invoke	SelectObject,hDc,hBrush	
	invoke	PatBlt,hDc,0,0,540,540,PATCOPY
	;invoke	DrawChess,hDc,x,y,1
	.while	y<15
		.while	x<15
			mov	esi,offset ChessBoard
			invoke	_GetArrPos,x,y	;���eax�����������������е�һά����
			;mov	pos,eax
			imul	ebx,eax,28
			mov	eax,(PosInfo PTR [esi+ebx]).State
			;invoke	wsprintf,addr szBuffer,addr lpFmt,eax
			;invoke	wsprintf,addr szBuf,addr lpFmt,eax
			;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK
			;invoke	DrawChess,hDc,x,y,eax
			.if	eax == 0	
				invoke	DrawChess,hDc,x,y,0
			.elseif	eax == 1
				invoke	DrawChess,hDc,x,y,1
			.endif
			
			inc	x	
		.endw
		
		mov	x,0
		inc	y
			
	.endw
	invoke	ReleaseDC,hWinMain,hDc		;�ͷ�hDC
	ret

DrawChessBoardToWnd	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
MaxChess	proc	pos
;********************************************************************
;	��������λ�ã�	���ָ��λ�õ����������
;********************************************************************

	local	nCount,tx,ty,x,y
	
	mov	esi,offset ChessBoard

	imul	ebx,pos,28


	mov	eax,(PosInfo PTR [esi+ebx]).x_0
	;.if	MaxCount < eax
	mov	MaxCount,eax
	;.endif
	mov	eax,(PosInfo PTR [esi+ebx]).x_45
	.if	MaxCount < eax
		mov	MaxCount,eax
	.endif
	mov	eax,(PosInfo PTR [esi+ebx]).x_90
	.if	MaxCount < eax
		mov	MaxCount,eax
	.endif
	mov	eax,(PosInfo PTR [esi+ebx]).x_135
	
	.if	MaxCount < eax
		mov	MaxCount,eax
	.endif

	ret
MaxChess	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SearchChess	proc	pos
;********************************************************************
;	��������λ��	��������	
;********************************************************************
	local	nCount,tx,ty,x,y,nCurChess,nSearchChess
	;nCount��ʾ�����������nSearchChess��ʾ��ǰ����,nCurChess��ʾ�����жϵ�����
	;mov	eax,pos
	mov	esi,offset ChessBoard
	imul	ebx,pos,28

	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nSearchChess,eax

	mov	edi,offset ChessBoard.back
	imul	ebx,pos,8
	mov	ax,(StackBack PTR [edi+ebx]).x
	mov	x,eax

	mov	ax,(StackBack PTR [edi+ebx]).y
	mov	y,eax
	;invoke	wsprintf,addr szBuffer,addr lpFmt,y
	;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK
	;************************************************************************
	;	�����µ���������
	;************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x-1
	dec	tx
	mov	eax,y
	mov	ty,eax		;ty=y-1
	dec	ty
	
	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	;invoke	wsprintf,addr szBuffer,addr lpFmt,nCurChess
	;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK
	mov	nCount,1

	;mov	eax,nCurChess
	;.while	(eax == nSearchChess && tx >= 0 && ty >= 0)
	;	inc	nCount
	;	dec	tx
	;	dec	ty
	;	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
	;	imul	ebx,eax,28
	;	mov	eax,(PosInfo PTR [esi+ebx]).State
	;	mov	nCurChess,eax
	;	.break	.if	ty <= 0 
		;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
		;invoke	wsprintf,addr szBuf,addr lpFmt,ty
		;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK
		;.break	.if	eax != nSearchChess
	
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
		
	;.endw
	beginwhile1:
		cmp	eax,nSearchChess
		jne	endwhile1
		cmp	tx,0
		jl	endwhile1
		cmp	ty,0
		jl	endwhile1

		inc	nCount
		dec	tx
		dec	ty
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		
		;cmp	ty,0
		;jl	beginwhile1
		jmp	beginwhile1

	endwhile1:
	;invoke	wsprintf,addr szBuffer,addr lpFmt,ty
	;invoke	wsprintf,addr szBuf,addr lpFmt,eax
	;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK
	mov	eax,x
	mov	tx,eax		;tx=x+1
	inc	tx
	mov	eax,y
	mov	ty,eax		;ty=y+1
	inc	ty

	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax

	.while	(eax==nSearchChess && tx<=14 &&ty<=14)
		inc	nCount
		inc	tx
		inc	ty
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
	
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax != nSearchChess
		
	.endw

		

	imul	ebx,pos,28
	mov	eax,nCount
	;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
	;invoke	wsprintf,addr szBuf,addr lpFmt,ty
	;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK

	mov	(PosInfo PTR [esi+ebx]).x_135,eax


	;**************************************************************************************
	;�����µ���������
	;**************************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x+1
	inc	tx
	mov	eax,y
	mov	ty,eax		;ty=y-1
	dec	ty
	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax

	mov	nCount,1

	mov	eax,nCurChess
	;.while	(eax==nSearchChess && tx<=14 &&ty>=0)
	;	inc	nCount
	;	inc	tx
	;	dec	ty
	;	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	;	imul	ebx,eax,28
	;	mov	eax,(PosInfo PTR [esi+ebx]).State
	;	mov	nCurChess,eax
	;	.break	.if	ty <= 0
		;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
		;invoke	wsprintf,addr szBuf,addr lpFmt,ty
		;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK
		;.break	.if	eax == 2
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
	;.endw
	beginwhile2:
		cmp	eax,nSearchChess
		jne	endwhile2
		cmp	tx,14
		ja	endwhile2
		cmp	ty,0
		jl	endwhile2

		inc	nCount
		inc	tx
		dec	ty
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax

		jmp	beginwhile2

	endwhile2:

	mov	eax,x
	mov	tx,eax		;tx=x-1
	dec	tx
	mov	eax,y
	mov	ty,eax		;ty=y+1
	inc	ty

	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	;mov	eax,nCurChess
	.while	(eax==nSearchChess && tx>=0 &&ty<=14)
		inc	nCount
		dec	tx
		inc	ty
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����	

		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
	.endw
	

	imul	ebx,pos,28
	mov	eax,nCount
	mov	(PosInfo PTR [esi+ebx]).x_45,eax
	;.endif
	;************************************************************************
	; ��������
	;************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x-1
	dec	tx
	mov	eax,y
	mov	ty,eax		;ty=y
	
	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax

	mov	nCount,1

	mov	eax,nCurChess
	.while	(eax==nSearchChess && tx>=0)
		inc	nCount
		dec	tx
		
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
	
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
	.endw

	mov	eax,x
	mov	tx,eax		;tx=x+1
	inc	tx
	

	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	;mov	eax,nCurChess
	.while	(eax==nSearchChess && tx<=14)
		inc	nCount
		inc	tx
		
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
		;mov	ebx,TYPE PosInfo
		;mul	eax
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
	.endw
	

	imul	ebx,pos,28
	mov	eax,nCount
	mov	(PosInfo PTR [esi+ebx]).x_0,eax
	;.endif
	;**************************************************************************************
	;	��������
	;**************************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x
	
	mov	eax,y
	mov	ty,eax		;ty=y-1
	dec	ty
	
	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
	
	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	
	mov	nCount,1


	;.while	(eax==nSearchChess && ty>=0)
	;	inc	nCount
		
	;	dec	ty
	;	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
		
	;	imul	ebx,eax,28
	;	mov	eax,(PosInfo PTR [esi+ebx]).State
	;	mov	nCurChess,eax
	;	.break	.if	ty <= 0
		;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
		;invoke	wsprintf,addr szBuf,addr lpFmt,ty
		;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK

		
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
	;.endw
	beginwhile3:
		cmp	eax,nSearchChess
		jne	endwhile3
		
		cmp	ty,0
		jl	endwhile3

		inc	nCount
		
		dec	ty
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax

		jmp	beginwhile3

	endwhile3:

	mov	eax,y
	mov	ty,eax		;ty=y+1
	inc	ty

	invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
	
	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	
	.while	(eax==nSearchChess &&ty<=14)
		inc	nCount
		inc	ty
		invoke	_GetArrPos,tx,ty	;�����eax   ���һά����
	
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;�൱��nCurChess=g_ChessBoard[tx][ty].nState;
	.endw
	

	imul	ebx,pos,28
	mov	eax,nCount
	mov	(PosInfo PTR [esi+ebx]).x_90,eax
	;.endif
	ret
SearchChess	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

BackChess	proc
	dec	step_number

	mov	ebx,step_number

	dec	ebx
	mov	esi,offset ChessPos

	movzx	eax,byte PTR[esi+ebx]
	
	;invoke	wsprintf,addr szBuffer,addr lpFmt,eax
	;invoke	wsprintf,addr szBuf,addr lpFmt,eax
	;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK


	mov	byte ptr [esi+ebx],0
	imul	ebx,eax,28
	

	;��������õ����һ���ߵ����ӵ�һά����
	mov	esi,offset ChessBoard
	;*************************************************************
	;	�������ӽṹ����
	mov	(PosInfo PTR [esi+ebx]).State,2
	mov	(PosInfo PTR [esi+ebx]).x_0,0
	mov	(PosInfo PTR [esi+ebx]).x_45,0
	mov	(PosInfo PTR [esi+ebx]).x_90,0
	mov	(PosInfo PTR [esi+ebx]).x_135,0
	mov	(PosInfo PTR [esi+ebx]).back.x,0
	mov	(PosInfo PTR [esi+ebx]).back.y,0
	mov	(PosInfo PTR [esi+ebx]).back.Top,0
	;*************************************************************
	invoke	DrawChessBoardToWnd	;�����������黭����
	
	sub	Side,1					;�ڰ�˫����1��ʾ�ڷ���0��ʾ�׷�
	neg	Side
	mov	GameOver,FALSE	
	ret
BackChess	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Mod	proc	x,y
;********************************************************************
; ����	���磺17 Mod 2 = 1, x��y�������0
;********************************************************************	
	mov	eax,x
	.while	x>0
		sub	eax,y
	.endw
	.if	eax!=0
		add	eax,y
	.endif
	ret
_Mod	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Init_array	proc
;********************************************************************
;	��ʼ������
;********************************************************************
;��ʼ��
	mov	ecx,0
	.while	ecx < 225
		;��ʼ���ṹ����
		mov	esi,offset ChessBoard
		imul	ebx,ecx,28
		mov	(PosInfo PTR [esi+ebx]).State,2
		mov	(PosInfo PTR [esi+ebx]).x_0,0
		mov	(PosInfo PTR [esi+ebx]).x_45,0
		mov	(PosInfo PTR [esi+ebx]).x_90,0
		mov	(PosInfo PTR [esi+ebx]).x_135,0
		mov	(PosInfo PTR [esi+ebx]).back.x,0
		mov	(PosInfo PTR [esi+ebx]).back.y,0
		mov	(PosInfo PTR [esi+ebx]).back.Top,0
		;mov	edi,esi
		;add	edi,offset PosInfo.back		
		;imul	ebx,ecx,8
		;mov	(StackBack PTR [edi+ebx]).x,0
		;mov	(StackBack PTR [edi+ebx]).y,0
		;mov	(StackBack PTR [edi+ebx]).Top,0
		;��ʼ����������
		mov	esi,offset ChessPos
		mov	BYTE PTR [esi+ecx],0
		inc	ecx
		mov	Side,1
		mov	step_number,1	;����
	.endw
	mov	GameOver,FALSE
	ret
Init_array	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Init	proc	@hDc
;************************************************
; �������̡��ڰ����ӣ��������̻���������
;************************************************
	
	invoke	LoadBitmap,hInstance,IDB_BOARD
	mov	hBmpBoard,eax
	invoke	CreatePatternBrush,hBmpBoard			;����
	mov	hBrush,eax
	invoke	SelectObject,@hDc,hBrush	
	invoke	PatBlt,@hDc,0,0,540,540,PATCOPY
	invoke	LoadBitmap,hInstance,IDB_BLACK
	mov	hBlack,eax
	invoke	LoadBitmap,hInstance,IDB_WHITE
	mov	hWhite,eax
	;****************************************
	;invoke	CreateCompatibleDC,@hDc
	;mov	hDcBoard,eax
	invoke	CreateCompatibleDC,@hDc
	mov	hDcWhite,eax
	invoke	CreateCompatibleDC,@hDc
	mov	hDcBlack,eax
	;invoke	SelectObject,hDcBoard,hBmpBoard

	invoke	SelectObject,hDcWhite,hWhite
	invoke	SelectObject,hDcBlack,hBlack

	ret
_Init	endp


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ���ڹ���
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
		local	@stPs:PAINTSTRUCT
		local	@stRect:RECT
		local	@hDc
		local	@stPos:POINT			;@stPosΪ������������
		;local	Grid,eGrid	;,arr_x,arr_y,;arrPos	;arrPos��ʾһά����λ��
			
		mov	eax,uMsg
		;mov	esi,offset arrPiece	;������������[esi]��ʾ
;********************************************************************
		.if	eax ==	WM_PAINT
			invoke	BeginPaint,hWnd,addr @stPs
			mov	@hDc,eax
			invoke	_Init,eax
			

			invoke	EndPaint,hWnd,addr @stPs
;********************************************************************
		.elseif	eax == WM_LBUTTONDOWN
		  
			invoke	GetCursorPos,addr @stPos
			invoke	ScreenToClient,hWnd,addr @stPos
			invoke	GetDC,hWinMain
			mov	@hDc,eax
			;*************************************************************************************
			;	������
			invoke	_OnTheGrid,@stPos.x,@stPos.y	;����(75,110)==>(1,2) ��ֵ����click_X,click_y
			;	��ȡState �����жϵ��λ���Ƿ�����
			invoke	_GetArrPos,click_x,click_y	;�õ�eax һά����
			;mov	ebx,eax
			imul	ebx,eax,28			;ebxΪPos�ڽṹ�����е�λ��
		
			mov	esi,offset ChessBoard
	
			mov	ecx,(PosInfo PTR [esi+ebx]).State
			.if	ecx == 2 && GameOver == FALSE			
				invoke	DrawChess,@hDc,click_x,click_y,Side		;��ָ��λ�û�������
			
				;*************************************************************************************
				;�õ������������ϵ�λ��
				invoke	_GetArrPos,click_x,click_y	;����һά����λ�� 
				mov	gPos,eax
				mov	ebx,step_number		;����ָ��ChessPos������λ��
				dec	ebx
				;invoke	wsprintf,addr szBuf,addr lpFmt,ebx
				mov	ChessPos[ebx],al	;��һά����λ�÷������飬���ڻ���
				mov	cl,ChessPos[ebx]
				;******************************************************************************************************
				;	������������
				invoke	Update_array_structure,Side,click_x,click_y,step_number,gPos
				invoke	SearchChess,gPos				;�������ӣ�������������
				invoke	MaxChess,gPos					;�õ�ָ������λ�õ�����������������MaxCount
				;invoke	wsprintf,addr szBuffer,addr lpFmt,MaxCount
				;invoke	wsprintf,addr szBuf,addr lpFmt,ty
				;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK

				.if	MaxCount >= 5
					;��Ϸ����
					mov	GameOver,TRUE
					.if	Side == 1
						invoke	MessageBox,hWinMain,offset szText1,addr szCaption,MB_OK
					.elseif	Side == 0
						invoke	MessageBox,hWinMain,offset szText2,addr szCaption,MB_OK
					.endif
				.endif	
				sub	Side,1					;�ڰ�˫����1��ʾ�ڷ���0��ʾ�׷�
				neg	Side
			
				inc	step_number					;������1
			
			.endif
			invoke	ReleaseDC,hWinMain,@hDc
					
		
;********************************************************************
		.elseif	eax ==	WM_COMMAND
			mov	eax,wParam
			.if	ax == IDC_Button
				.if	step_number>1
					invoke	BackChess
				.endif
			
			.elseif	ax == IDC_reStart
				;���¿�ʼ
				invoke	GetDC,hWinMain		;��ȡ�豸�������
				mov	@hDc,eax
				invoke	CreatePatternBrush,hBmpBoard			;����
				mov	hBrush,eax
				invoke	SelectObject,@hDc,hBrush	
				invoke	PatBlt,@hDc,0,0,540,540,PATCOPY

				invoke	Init_array
				invoke	ReleaseDC,hWinMain,@hDc		;�ͷ�hDC
			.endif
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			invoke	DeleteDC,hDcBlack
			invoke	DeleteDC,hDcWhite
			
			invoke	DestroyWindow,hWinMain
			invoke	PostQuitMessage,NULL
;********************************************************************
		.else
			invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
;********************************************************************
		xor	eax,eax
		ret

_ProcWinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_WinMain	proc
		local	@stWndClass:WNDCLASSEX
		local	@stMsg:MSG
		
		;****************************************************
		mov	Side,1		;1��ʾ�ڷ��£�0��ʾ�׷���
		mov	step_number,1	;����
		;****************************************************
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
;********************************************************************
; ע�ᴰ����
;********************************************************************
		invoke	LoadCursor,0,IDC_ARROW
		mov	@stWndClass.hCursor,eax
		push	hInstance
		pop	@stWndClass.hInstance
		mov	@stWndClass.cbSize,sizeof WNDCLASSEX
		mov	@stWndClass.style,CS_HREDRAW or CS_VREDRAW
		mov	@stWndClass.lpfnWndProc,offset _ProcWinMain
		invoke	LoadBitmap,hInstance,IDB_BG		
		invoke	CreatePatternBrush,eax
		mov	@stWndClass.hbrBackground,eax
		mov	@stWndClass.lpszClassName,offset szClassName
		invoke	RegisterClassEx,addr @stWndClass
;********************************************************************
; ��������ʾ����
;********************************************************************
		invoke	CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,\
			WS_OVERLAPPEDWINDOW,\
			100,100,700,600,\
			NULL,NULL,hInstance,NULL
		mov	hWinMain,eax
		invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke	UpdateWindow,hWinMain
		;������ť
		invoke	CreateWindowEx,NULL,offset szButton,offset szButtonText,\
			WS_CHILD or WS_VISIBLE,\
			560,50,50,40,\
			hWinMain,1,hInstance,NULL
		mov	hButton,eax
		invoke	GetDlgCtrlID,hButton
		mov	IDC_Button,ax
		;���¿�ʼ��ť
		invoke	CreateWindowEx,NULL,offset szButton,offset szButtonStart,\
			WS_CHILD or WS_VISIBLE,\
			560,100,100,40,\
			hWinMain,2,hInstance,NULL
		mov	hreStart,eax
		invoke	GetDlgCtrlID,hreStart
		mov	IDC_reStart,ax
		;****************************************************
		;	����ͼ��
		;****************************************************
		invoke	LoadIcon,hInstance,ICO_MAIN
		invoke	SendMessage,hWinMain,WM_SETICON,ICON_BIG,eax
;********************************************************************
; ��Ϣѭ��
;********************************************************************
		.while	TRUE
			invoke	GetMessage,addr @stMsg,NULL,0,0
			.break	.if eax	== 0
			invoke	TranslateMessage,addr @stMsg
			invoke	DispatchMessage,addr @stMsg
		.endw
		ret

_WinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
		call	_WinMain
		invoke	ExitProcess,NULL
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		end	start
