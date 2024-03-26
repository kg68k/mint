# pathhis.s - path selector
# Copyright (C) 2002-2006 Tachibana Eriko
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA


* Include File -------------------------------- *

		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	sysval.def

.ifdef __DEBUG__
		.include	doscall.mac
.endif


* Global Symbol ------------------------------- *

* menu.s
		.xref	menu_sub,menu_sub2
* madoka3.s
		.xref	＠buildin,＠status
* mint.s
		.xref	chdir_a1
* outside.s
		.xref	set_user_value_arg_a2,unset_user_value_arg
		.xref	strcmp_a1_a2
		.xref	atoi_a0


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* パスヒストリ追加 ---------------------------- *
* in	d0.w	追加するバッファ(WIN_LEFT/WIN_RIGHT)
*	a1.l	パス名
* out	d0.l	0

add_path_history::
		tst	(＄his2)
		bne	add_path_history_sub	;%his2 1 -> 指定バッファに登録

		moveq	#WIN_RIGHT,d0		;%his2 0 -> 左右両方のバッファに登録
		bsr	add_path_history_sub
**		moveq	#WIN_LEFT,d0
		bra	add_path_history_sub
**		rts

add_path_history_sub:
		PUSH	d1-d7/a0-a6
		lea	(path_his_buf_l),a2
		tst	d0
		beq	@f			;WIN_LEFT
		lea	(path_his_buf_r-path_his_buf_l,a2),a2
@@:
		tst.b	(a2)
		beq	add_path_history_copy	;空なので先頭にコピー
		jsr	(strcmp_a1_a2)
		beq	add_path_history_end	;先頭と同じなら何もする必要はない

		moveq	#(PATH_HIS_BUF_NUM-1),d6
		moveq	#(PATH_HIS_BUF_NUM-1)-1,d7
@@:
		lea	(PATH_HIS_BUF_SIZE,a2),a2
		jsr	(strcmp_a1_a2)		;buf[1]～buf[25]に同じパスがあるか？
		dbeq	d7,@b
		lea	(PATH_HIS_BUF_SIZE,a2),a3
		bne	@f

		sub	d7,d6
@@:
		mulu	#PATH_HIS_BUF_SIZE/16,d6
		subq	#1,d6
@@:
		move.l	-(a2),-(a3)
		move.l	-(a2),-(a3)
		move.l	-(a2),-(a3)
		move.l	-(a2),-(a3)
		dbra	d6,@b
add_path_history_copy:
		STRCPY	a1,a2
add_path_history_end:
.ifdef __DEBUG__
		tst.b	(path_his_buf_end)
		beq	@f
		pea	(add_path_history_err_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
@@:
.endif
		POP	d1-d7/a0-a6
		moveq	#0,d0
		rts


*************************************************
*		&path-history-menu		*
*************************************************

＆path_history_menu::
		move	(PATH_WINRL,a6),d5
		swap	d5
		move	#2,d5			;-o | -l
		moveq	#0,d6			;-s
		movea.l	d6,a1			;-t
		bra	path_his_menu_arg_next
path_his_menu_arg_loop:
		cmpi.b	#'-',(a0)+
		bne	path_his_menu_error
		move.b	(a0)+,d0
		cmpi.b	#'l',d0
		beq	path_his_menu_l
		cmpi.b	#'o',d0
		beq	path_his_menu_o
		cmpi.b	#'t',d0
		beq	path_his_menu_t
		cmpi.b	#'s',d0
		bne	path_his_menu_error
*path_his_menu_s:
		jsr	(unset_user_value_arg)
		moveq	#-1,d6
		tst.b	(a0)+
		beq	path_his_menu_arg_next
path_his_menu_error:
		moveq	#0,d0
		bra	set_status
**		rts

path_his_menu_l:
		jsr	(atoi_a0)
		move	d0,d5
		bra	@f
path_his_menu_o:
		eori.l	#(WIN_LEFT.xor.WIN_RIGHT)<<16,d5
		bra	@f			;-o : パスヒストリ反対側モード
path_his_menu_t:
		lea	(a0),a1
@@:
		tst.b	(a0)+
		bne	@b
path_his_menu_arg_next:
		subq.l	#1,d7
		bcc	path_his_menu_arg_loop
path_his_menu_arg_end:
		move.l	d5,d0
		lea	(a1),a0
		bsr	path_history_menu_sub
		bmi	path_his_menu_error

		tst	d6
		beq	@f

		lea	(a0),a2
		jsr	(set_user_value_arg_a2)
		bra	path_his_menu_end
@@:
		lea	(a0),a1
		jsr	(chdir_a1)
path_his_menu_end:
		bra	set_status
**		rts


set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts


* パスヒストリーメニュー ---------------------- *
* in	d0.hw	左右ヒストリバッファ選択(WIN_LEFT/WIN_RIGHT)
*	d0.w	初期カーソル行(0～)
*	a0.l	サブウィンドウタイトル(NULL なら標準メッセージを使用)
* out	d0.l	エラーコード(0:正常終了 -1:エラー)
*	a0.l	選択したパス名
* 備考:
*	下請けルーチン内で Buffer を破壊する.

path_history_menu_sub::
path_his_menu_sub_loop:
		move.l	a0,-(sp)
		move.l	d0,-(sp)
		bsr	path_history_menu_sub2
		tst.l	d0
		beq	path_his_menu_sub_cancel
		bpl	path_his_menu_sub_decide

		eori	#WIN_LEFT.xor.WIN_RIGHT,(sp)	;←→で左右バッファ切り換え
		move.l	(sp)+,d0
		movea.l	(sp)+,a0
		bra	path_his_menu_sub_loop
path_his_menu_sub_cancel:
		moveq	#-1,d0
		bra	path_his_menu_sub_end
path_his_menu_sub_decide:
		moveq	#0,d0
path_his_menu_sub_end:
		addq.l	#8,sp
		rts


* パスヒストリーメニュー下請け ---------------- *
* in	d0.hw	左右ヒストリバッファ選択(WIN_LEFT/WIN_RIGHT)
*	d0.w	初期カーソル行(0～)
*	a0.l	サブウィンドウタイトル(NULL なら標準メッセージを使用)
* out	d0.l	1:正常終了 0:キャンセル -1:AK_LEFT -2:AK_RIGHT
*	a0.l	選択したパス名
* 備考:
*	Buffer を破壊する.

path_history_menu_sub2:
		PUSH	d1-d7/a1-a6
		move	d0,d5			;初期カーソル行
		swap	d0
		move	d0,d6			;左右ヒストリバッファ選択

		move.l	a0,-(sp)		;SUBWIN_TITLE
		clr.l	-(sp)			;SUBWIN_MES
		move.l	#72<<16+0,-(sp)		;SUBWIN_{X,Y}_SIZE
		move.l	#12<<16+2,-(sp)		;SUBWIN_{X,Y}

		lea	(path_his_buf_l),a5
		lea	(Buffer),a1

		moveq	#MES_PHIST,d0
		tst	(＄his2)
		beq	@f
		moveq	#MES_PHISL,d0		;WIN_LEFT
		subq	#4,(SUBWIN_X,sp)
		tst	d6
		beq	@f
		moveq	#MES_PHISR,d0		;WIN_RIGHT
		addq	#4+4,(SUBWIN_X,sp)
		lea	(path_his_buf_r-path_his_buf_l,a5),a5
@@:
		tst.l	(SUBWIN_TITLE,sp)
		bne	@f			;-t 指定あり
		jsr	(get_message)
		move.l	d0,(SUBWIN_TITLE,sp)
@@:

		move	(＄hisc),d0
*		bne	@f
*		moveq	#'0',d0
*@@:
		lea	(a5),a0
		lea	(a1),a2
		lea	(PATH_HIS_BUF_NUM*4,a1),a3
		moveq	#PATH_HIS_BUF_NUM-1,d7
@@:
		tst.b	(a0)			;登録されているパスの数を数える
		beq	@f
		addq	#1,(SUBWIN_YSIZE,sp)

		move.l	a3,(a2)+		;文字列のアドレス
		move.b	d0,(a3)+		;ショートカットキー
		lea	(a0),a4
		STRCPY	a4,a3

		addq	#1,d0
		lea	(PATH_HIS_BUF_SIZE,a0),a0
		dbra	d7,@b
@@:
		moveq	#PATH_HIS_BUF_NUM,d0
		sub	(SUBWIN_YSIZE,sp),d0
		lsr	#2,d0
		add	(SUBWIN_Y,sp),d0
		move	d0,(SUBWIN_Y,sp)

		lea	(menu_sub),a3
		tst	(＄his2)
		beq	@f			;←→切り換え無し
		lea	(menu_sub2-menu_sub,a3),a3
@@:
		move	d5,d0
		lea	(sp),a0
		jsr	(a3)
		tst.l	d0
		ble	path_his_menu_sub2_end	;キャンセル or ←→

		subq	#1,d0
		lea	(a5),a0
		mulu	#PATH_HIS_BUF_SIZE,d0
		adda.l	d0,a5			;選択したパス名

		lea	(-PATH_HIS_BUF_SIZE,sp),sp
		lea	(sp),a1
		STRCPY	a5,a1
		lea	(sp),a1
		move	d6,d0
		bsr	add_path_history	;選択したパスをヒストリの先頭に移動する
		lea	(PATH_HIS_BUF_SIZE,sp),sp

		moveq	#1,d0			;正常終了
path_his_menu_sub2_end:
		lea	(sizeof_SUBWIN,sp),sp
		POP	d1-d7/a1-a6
		rts


* Data Section -------------------------------- *

**		.data
**		.even

.ifdef __DEBUG__
add_path_history_err_mes:
		.dc.b	'path-history: バッファを破壊しました(bug).',LF,0
.endif


* Block Storage Section ----------------------- *

		.bss
		.even

path_history_buffer::
path_his_buf_l:
		.ds.b	PATH_HIS_BUF_SIZE*PATH_HIS_BUF_NUM
path_his_buf_r:
		.ds.b	PATH_HIS_BUF_SIZE*PATH_HIS_BUF_NUM
.ifdef __DEBUG__
path_his_buf_end:
		.ds.b	PATH_HIS_BUF_SIZE
.endif


		.end

* End of File --------------------------------- *
