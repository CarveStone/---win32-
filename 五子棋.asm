;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; by CarveStone
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 使用 nmake 或下列命令进行编译和链接:
; ml /c /coff 五子棋.asm
; Link /subsystem:windows 五子棋.obj
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.386
		.model flat,stdcall
		option casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include 文件定义
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
;	结构
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
StackBack	STRUCT	;用于悔棋
	x	WORD	?	;棋子的落子坐标
	y	WORD	?	;
	ALIGN	DWORD	
	;State	DWORD	?	;1表示黑棋，0表示白棋
	Top	DWORD	?

StackBack	ENDS
PosInfo	STRUCT			;棋子位置信息
	State	DWORD	?	;位置状态：0，白子，1，黑子，2无子
	x_0	DWORD	?	;横线	最大连子数
	x_45	DWORD	?	;右斜线	最大连子数
	x_90	DWORD	?	;竖线	最大连子数
	x_135	DWORD	?	;左斜线	最大连子数
	
	back	StackBack	<>	;悔棋
PosInfo	ENDS


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 数据段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.data?
hInstance	dd		?
hWinMain	dd		?	
hBmpBoard	dd		?	;棋盘句柄
;hDcBoard	dd		?	;棋盘DC句柄
hBrush		dd		?	;画刷句柄
hBlack		dd		?	;黑棋
hWhite		dd		?	;白棋
hDcBlack	dd		?	;黑棋DC句柄
hDcWhite	dd		?	;白棋DC句柄
hButton		dd		?	;按钮句柄
IDC_Button	dw		?	;按钮控件
hreStart	dd		?	;重新开始按钮句柄
IDC_reStart	dw		?	;重新开始按钮控件
Side		dd		?	;黑白双方
lSide		dd		?	;上一个Side
click_x		dd		?	;点击位置x
click_y		dd		?	;点击位置y
gPos		dd		?	;一维数组位置	全局变量
MaxCount	dd		?	;最大的连子数
;row_index	dd		?	;用于二维数组 行
;column_index	dd		?	;             列
step_number	dd		?	;步数



;szBuffer	db	10 dup	(?)
;szBuf		db	10 dup	(?)
ChessPos	db	225 dup	(?)
		.data
ChessBoard	PosInfo	225 DUP (<2,0,0,0,0>)
GameOver	db		FALSE	;胜负标志



		.const
szClassName	db	'MyClass',0
szCaptionMain	db	'五子棋',0
szButton	db	'button',0
szButtonText	db	'悔棋',0
szButtonStart	db	'重新开始',0
szText1		db	'黑方胜利',0
szText2		db	'白方胜利',0
szCaption	db	'Game Over',0
dwidth		dd	16
szButtonName	dd	"悔棋",0
;lpFmt		db	'%d',0
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 代码段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_OnTheGrid	proc	x,y
;*******************************************************************
; 根据棋子像素坐标得到棋子在棋盘上的坐标位置   例如(75,110)==>(1,2)
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
; 得到棋子在数组上的位置索引  例如：(1,2)==>(16)
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
;	更新数组结构			
;********************************************************************
	;local	num
	mov	esi,offset ChessBoard
	mov	eax,Pos

	;mov	bx, TYPE PosInfo	;指向对应的数组
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
;	找出双方所有可能下子的位置
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
;	在这些位置中进行挑选，选出能够产生更大优势的下子位置，
;	减少博弈树搜索节点的次数
;********************************************************************
	ret
pointsFilter	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawChess	proc	hDc,Click_X,Click_Y,state
;********************************************************************
;	在指定位置绘制棋子	
;	输入鼠标的像素坐标，棋子状态1或0
;********************************************************************
	local	Grid,eGrid,x:dword,y:dword	;（x，y）表示棋子的像素坐标
	
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
;	按数组映射绘制棋盘到窗口
;********************************************************************
	local	x,y,hDc ;,pos
	
	mov	y,0
	mov	x,0
	invoke	GetDC,hWinMain		;获取设备环境句柄
	mov	hDc,eax
	invoke	CreatePatternBrush,hBmpBoard			;棋盘
	mov	hBrush,eax
	invoke	SelectObject,hDc,hBrush	
	invoke	PatBlt,hDc,0,0,540,540,PATCOPY
	;invoke	DrawChess,hDc,x,y,1
	.while	y<15
		.while	x<15
			mov	esi,offset ChessBoard
			invoke	_GetArrPos,x,y	;输出eax，棋子在棋子数组中的一维坐标
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
	invoke	ReleaseDC,hWinMain,hDc		;释放hDC
	ret

DrawChessBoardToWnd	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
MaxChess	proc	pos
;********************************************************************
;	输入棋子位置，	输出指定位置的最大连子数
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
;	输入棋子位置	搜索棋子	
;********************************************************************
	local	nCount,tx,ty,x,y,nCurChess,nSearchChess
	;nCount表示最大连子数，nSearchChess表示当前棋子,nCurChess表示进行判断的棋子
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
	;	从右下到左上搜索
	;************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x-1
	dec	tx
	mov	eax,y
	mov	ty,eax		;ty=y-1
	dec	ty
	
	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

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
	;	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
	;	imul	ebx,eax,28
	;	mov	eax,(PosInfo PTR [esi+ebx]).State
	;	mov	nCurChess,eax
	;	.break	.if	ty <= 0 
		;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
		;invoke	wsprintf,addr szBuf,addr lpFmt,ty
		;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK
		;.break	.if	eax != nSearchChess
	
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
		
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
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
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

	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax

	.while	(eax==nSearchChess && tx<=14 &&ty<=14)
		inc	nCount
		inc	tx
		inc	ty
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
	
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
	;从左下到右上搜索
	;**************************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x+1
	inc	tx
	mov	eax,y
	mov	ty,eax		;ty=y-1
	dec	ty
	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax

	mov	nCount,1

	mov	eax,nCurChess
	;.while	(eax==nSearchChess && tx<=14 &&ty>=0)
	;	inc	nCount
	;	inc	tx
	;	dec	ty
	;	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

	;	imul	ebx,eax,28
	;	mov	eax,(PosInfo PTR [esi+ebx]).State
	;	mov	nCurChess,eax
	;	.break	.if	ty <= 0
		;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
		;invoke	wsprintf,addr szBuf,addr lpFmt,ty
		;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK
		;.break	.if	eax == 2
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
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
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
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

	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	;mov	eax,nCurChess
	.while	(eax==nSearchChess && tx>=0 &&ty<=14)
		inc	nCount
		dec	tx
		inc	ty
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组	

		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
	.endw
	

	imul	ebx,pos,28
	mov	eax,nCount
	mov	(PosInfo PTR [esi+ebx]).x_45,eax
	;.endif
	;************************************************************************
	; 横向搜索
	;************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x-1
	dec	tx
	mov	eax,y
	mov	ty,eax		;ty=y
	
	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax

	mov	nCount,1

	mov	eax,nCurChess
	.while	(eax==nSearchChess && tx>=0)
		inc	nCount
		dec	tx
		
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
	
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
	.endw

	mov	eax,x
	mov	tx,eax		;tx=x+1
	inc	tx
	

	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组

	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	;mov	eax,nCurChess
	.while	(eax==nSearchChess && tx<=14)
		inc	nCount
		inc	tx
		
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
		;mov	ebx,TYPE PosInfo
		;mul	eax
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
	.endw
	

	imul	ebx,pos,28
	mov	eax,nCount
	mov	(PosInfo PTR [esi+ebx]).x_0,eax
	;.endif
	;**************************************************************************************
	;	竖向搜索
	;**************************************************************************************
	mov	eax,x
	mov	tx,eax		;tx=x
	
	mov	eax,y
	mov	ty,eax		;ty=y-1
	dec	ty
	
	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
	
	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	
	mov	nCount,1


	;.while	(eax==nSearchChess && ty>=0)
	;	inc	nCount
		
	;	dec	ty
	;	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
		
	;	imul	ebx,eax,28
	;	mov	eax,(PosInfo PTR [esi+ebx]).State
	;	mov	nCurChess,eax
	;	.break	.if	ty <= 0
		;invoke	wsprintf,addr szBuffer,addr lpFmt,nCount
		;invoke	wsprintf,addr szBuf,addr lpFmt,ty
		;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuf,MB_OK

		
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
	;.endw
	beginwhile3:
		cmp	eax,nSearchChess
		jne	endwhile3
		
		cmp	ty,0
		jl	endwhile3

		inc	nCount
		
		dec	ty
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax

		jmp	beginwhile3

	endwhile3:

	mov	eax,y
	mov	ty,eax		;ty=y+1
	inc	ty

	invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
	
	imul	ebx,eax,28
	mov	eax,(PosInfo PTR [esi+ebx]).State
	mov	nCurChess,eax
	
	.while	(eax==nSearchChess &&ty<=14)
		inc	nCount
		inc	ty
		invoke	_GetArrPos,tx,ty	;输出到eax   变成一维数组
	
		imul	ebx,eax,28
		mov	eax,(PosInfo PTR [esi+ebx]).State
		mov	nCurChess,eax
		;.break	.if	eax == 2
		;相当于nCurChess=g_ChessBoard[tx][ty].nState;
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
	

	;根据数组得到最后一步走的棋子的一维坐标
	mov	esi,offset ChessBoard
	;*************************************************************
	;	更新棋子结构数组
	mov	(PosInfo PTR [esi+ebx]).State,2
	mov	(PosInfo PTR [esi+ebx]).x_0,0
	mov	(PosInfo PTR [esi+ebx]).x_45,0
	mov	(PosInfo PTR [esi+ebx]).x_90,0
	mov	(PosInfo PTR [esi+ebx]).x_135,0
	mov	(PosInfo PTR [esi+ebx]).back.x,0
	mov	(PosInfo PTR [esi+ebx]).back.y,0
	mov	(PosInfo PTR [esi+ebx]).back.Top,0
	;*************************************************************
	invoke	DrawChessBoardToWnd	;根据棋子数组画棋子
	
	sub	Side,1					;黑白双方，1表示黑方，0表示白方
	neg	Side
	mov	GameOver,FALSE	
	ret
BackChess	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Mod	proc	x,y
;********************************************************************
; 求余	例如：17 Mod 2 = 1, x和y必须大于0
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
;	初始化数组
;********************************************************************
;初始化
	mov	ecx,0
	.while	ecx < 225
		;初始化结构数组
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
		;初始化悔棋数组
		mov	esi,offset ChessPos
		mov	BYTE PTR [esi+ecx],0
		inc	ecx
		mov	Side,1
		mov	step_number,1	;步数
	.endw
	mov	GameOver,FALSE
	ret
Init_array	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Init	proc	@hDc
;************************************************
; 加载棋盘、黑白棋子，并把棋盘画到窗体上
;************************************************
	
	invoke	LoadBitmap,hInstance,IDB_BOARD
	mov	hBmpBoard,eax
	invoke	CreatePatternBrush,hBmpBoard			;棋盘
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
; 窗口过程
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
		local	@stPs:PAINTSTRUCT
		local	@stRect:RECT
		local	@hDc
		local	@stPos:POINT			;@stPos为鼠标的像素坐标
		;local	Grid,eGrid	;,arr_x,arr_y,;arrPos	;arrPos表示一维数组位置
			
		mov	eax,uMsg
		;mov	esi,offset arrPiece	;把棋子数组用[esi]表示
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
			;	画棋子
			invoke	_OnTheGrid,@stPos.x,@stPos.y	;例如(75,110)==>(1,2) 把值赋给click_X,click_y
			;	获取State 用于判断点击位置是否有子
			invoke	_GetArrPos,click_x,click_y	;得到eax 一维数组
			;mov	ebx,eax
			imul	ebx,eax,28			;ebx为Pos在结构数组中的位置
		
			mov	esi,offset ChessBoard
	
			mov	ecx,(PosInfo PTR [esi+ebx]).State
			.if	ecx == 2 && GameOver == FALSE			
				invoke	DrawChess,@hDc,click_x,click_y,Side		;在指定位置绘制棋子
			
				;*************************************************************************************
				;得到棋子在数组上的位置
				invoke	_GetArrPos,click_x,click_y	;返回一维数组位置 
				mov	gPos,eax
				mov	ebx,step_number		;用于指定ChessPos的数组位置
				dec	ebx
				;invoke	wsprintf,addr szBuf,addr lpFmt,ebx
				mov	ChessPos[ebx],al	;把一维数组位置放入数组，用于悔棋
				mov	cl,ChessPos[ebx]
				;******************************************************************************************************
				;	更新棋子数组
				invoke	Update_array_structure,Side,click_x,click_y,step_number,gPos
				invoke	SearchChess,gPos				;搜索棋子；更新棋子数组
				invoke	MaxChess,gPos					;得到指定棋子位置的最大连子数，输出到MaxCount
				;invoke	wsprintf,addr szBuffer,addr lpFmt,MaxCount
				;invoke	wsprintf,addr szBuf,addr lpFmt,ty
				;invoke	MessageBox,hWinMain,addr szBuffer,addr szBuffer,MB_OK

				.if	MaxCount >= 5
					;游戏结束
					mov	GameOver,TRUE
					.if	Side == 1
						invoke	MessageBox,hWinMain,offset szText1,addr szCaption,MB_OK
					.elseif	Side == 0
						invoke	MessageBox,hWinMain,offset szText2,addr szCaption,MB_OK
					.endif
				.endif	
				sub	Side,1					;黑白双方，1表示黑方，0表示白方
				neg	Side
			
				inc	step_number					;步数加1
			
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
				;重新开始
				invoke	GetDC,hWinMain		;获取设备环境句柄
				mov	@hDc,eax
				invoke	CreatePatternBrush,hBmpBoard			;棋盘
				mov	hBrush,eax
				invoke	SelectObject,@hDc,hBrush	
				invoke	PatBlt,@hDc,0,0,540,540,PATCOPY

				invoke	Init_array
				invoke	ReleaseDC,hWinMain,@hDc		;释放hDC
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
		mov	Side,1		;1表示黑方下，0表示白方下
		mov	step_number,1	;步数
		;****************************************************
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
;********************************************************************
; 注册窗口类
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
; 建立并显示窗口
;********************************************************************
		invoke	CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,\
			WS_OVERLAPPEDWINDOW,\
			100,100,700,600,\
			NULL,NULL,hInstance,NULL
		mov	hWinMain,eax
		invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke	UpdateWindow,hWinMain
		;创建按钮
		invoke	CreateWindowEx,NULL,offset szButton,offset szButtonText,\
			WS_CHILD or WS_VISIBLE,\
			560,50,50,40,\
			hWinMain,1,hInstance,NULL
		mov	hButton,eax
		invoke	GetDlgCtrlID,hButton
		mov	IDC_Button,ax
		;重新开始按钮
		invoke	CreateWindowEx,NULL,offset szButton,offset szButtonStart,\
			WS_CHILD or WS_VISIBLE,\
			560,100,100,40,\
			hWinMain,2,hInstance,NULL
		mov	hreStart,eax
		invoke	GetDlgCtrlID,hreStart
		mov	IDC_reStart,ax
		;****************************************************
		;	加载图标
		;****************************************************
		invoke	LoadIcon,hInstance,ICO_MAIN
		invoke	SendMessage,hWinMain,WM_SETICON,ICON_BIG,eax
;********************************************************************
; 消息循环
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
