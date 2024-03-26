# window.s - window routines
# Copyright (C) 2000-2006 Tachibana Eriko
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
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac
		.include	gm_internal.mac


* Macro --------------------------------------- *

WIN_GET_PTR:	.macro	an
		lea	(wind_buf),an
		adda	d0,an
		.endm

WIN_DEBUG:	.equ	1

DEBUG_PRINT:	.macro	str
		move.l	d0,-(sp)
		pea	(@mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		move.l	(sp)+,d0
		bra	@skip
@mes:		.dc.b	'BUG: ',str,CR,LF,0
		.even
@skip:
		.endm


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* フォント関係の初期化を行う.

WinFontInit::
		PUSH	d0-d2/a0
		moveq	#SPACE,d1
		moveq	#8,d2			;16dot
		IOCS	_FNTADR
		subi.l	#16*SPACE,d0		;先頭アドレス
		lea	(font_addres,pc),a0
		move.l	d0,(a0)
		POP	d0-d2/a0
		rts


* ウィンドウ管理構造体のアドレスを得る.
* in	d0.w	ウィンドウ番号
* out	d0.l	アドレス

WinGetPtr::
		ext.l	d0
		addi.l	#wind_buf,d0
		rts


* ウィンドウを作成する.
* in	d1.w	左上Ｘ座標
*	d2.w	 〃 Ｙ 〃
*	d3.w	Ｘ方向の大きさ(桁数)
*	d4.w	Ｙ	〃    (行数)
* out	d0.l	ウィンドウ番号

WinCreate::
		PUSH	d1-d4/d7/a0
		lea	(wind_buf),a0
		move.l	a0,d7
		moveq	#WIND_MAX-1,d0
@@:
		tst.l	(WIND_TX_ADR,a0)	;未使用の構造体を探す
		beq	@f
		lea	(sizeof_WIND,a0),a0
		dbra	d0,@b
win_create_error:
.ifdef WIN_DEBUG
		DEBUG_PRINT 'WinCreate: ウィンドウが作成できません.'
.endif
		moveq	#-1,d0			;空きが無かった
		bra	win_create_end
@@:
		sub.l	a0,d7
		neg.l	d7			;ウィンドウ番号(実際はオフセット)

		clr	(WIND_CUR_X,a0)
		clr	(WIND_CUR_Y,a0)
		move	#WHITE,(WIND_COLOR,a0)
		move	#8,(WIND_TABC,a0)
		move	#-8,(WIND_TABCNEG,a0)
		st	(WIND_MB_FLAG,a0)

		moveq	#%1111_1110,d0
		and	d0,d1
		and	d0,d3
		move	d1,(WIND_TX_X,a0)
		move	d2,(WIND_TX_Y,a0)
		move	d3,(WIND_XSIZE,a0)
		move	d4,(WIND_YSIZE,a0)

		moveq	#96,d0
		cmp	d0,d1
		bcc	win_create_error	;Ｘ座標が大きすぎる
		add	d1,d3
		cmp	d0,d3
		bhi	win_create_error	;桁数〃

		moveq	#32,d0
		cmp	d0,d2
		bcc	win_create_error	;Ｙ座標が大きすぎる
		add	d2,d4
		cmp	d0,d4
		bhi	win_create_error	;行数〃

		move.l	#TVRAM_P0,d0
		add	d1,d0
		swap	d2
		clr	d2
		lsr.l	#5,d2			;*128*16
		add	d2,d0
		move.l	d0,(WIND_TX_ADR,a0)	;WIND_TX_ADR 設定後はエラー終了禁止
		move.l	d0,(WIND_CUR_ADR,a0)

		move.l	d7,d0			;ウィンドウ番号
win_create_end:
		POP	d1-d4/d7/a0
		rts


* ウィンドウを削除する.
* in	d0.w	ウィンドウ番号

WinDelete::
		PUSH	d0/a0
		WIN_GET_PTR a0
.ifdef WIN_DEBUG
		tst.l	(WIND_TX_ADR,a0)
		bne	@f
		DEBUG_PRINT 'WinDelete: ウィンドウ番号が不正です.'
@@:
.endif
		clr.l	(WIND_TX_ADR,a0)	;未使用状態にする
		POP	d0/a0
		rts


* ウィンドウの描画色を設定する.
* in	d0.w	ウィンドウ番号
*	d1.w	描画色

WinSetColor::
		PUSH	d0-d1/a0
		WIN_GET_PTR a0
		andi	#WCOL_MASK+$f,d1
		move	d1,(WIND_COLOR,a0)
		POP	d0-d1/a0
		rts


* ウィンドウのタブサイズを設定する.
* in	d0.w	ウィンドウ番号
*	d1.w	タブサイズ

WinSetTabsize::
		PUSH	d0-d1/a0
		WIN_GET_PTR a0
		move	d1,(WIND_TABC,a0)
		neg	d1
		move	d1,(WIND_TABCNEG,a0)
		POP	d0-d1/a0
		rts


* ウィンドウのカーソル位置を得る.
* in	d0.w	ウィンドウ番号
* out	d1.l	Ｘ座標
*	d2.l	Ｙ座標

WinGetCursor::
		PUSH	d0/a0
		WIN_GET_PTR a0
		moveq	#0,d1
		moveq	#0,d2
		move	(WIND_CUR_X,a0),d1
		move	(WIND_CUR_Y,a0),d2
		POP	d0/a0
		rts


* ウィンドウのカーソル位置を設定する
* in	d0.w	ウィンドウ番号
*	d1.w	Ｘ座標
*	d2.w	Ｙ座標

WinSetCursor::
		PUSH	d0-d2/a0
		WIN_GET_PTR a0

		cmp	(WIND_XSIZE,a0),d1
		bls	@f
		move	(WIND_XSIZE,a0),d1
@@:		move	d1,(WIND_CUR_X,a0)	;桁位置

		cmp	(WIND_YSIZE,a0),d2
		bls	@f
		move	(WIND_YSIZE,a0),d2
@@:		move	d2,(WIND_CUR_Y,a0)	;行位置

		swap	d2
		clr	d2
		lsr.l	#5,d2			;*128*16
		add	d1,d2
		add.l	(WIND_TX_ADR,a0),d2
		move.l	d2,(WIND_CUR_ADR,a0)	;カーソル位置テキストアドレス

		POP	d0-d2/a0
		rts


* ウィンドウのカーソルを一行上に移動する.
* in	d0.w	ウィンドウ番号
* 備考:
*	カーソルが最上行にある場合は何もしない.

WinCursorUp::
		PUSH	d0/a0
		WIN_GET_PTR a0
		tst	(WIND_CUR_Y,a0)
		beq	@f

		subq	#1,(WIND_CUR_Y,a0)
		subi.l	#128*16,(WIND_CUR_ADR,a0)
@@:
		POP	d0/a0
		rts


* ウィンドウのカーソルを一行下に移動する.
* in	d0.w	ウィンドウ番号
* 備考:
*	カーソルが最下行にある場合は何もしない.

WinCursorDown::
		PUSH	d0/a0
		WIN_GET_PTR a0
		move	(WIND_CUR_Y,a0),d0
		addq	#1,d0
		cmp	(WIND_YSIZE,a0),d0
		bcc	@f

		move	d0,(WIND_CUR_Y,a0)
		addi.l	#128*16,(WIND_CUR_ADR,a0)
@@:
		POP	d0/a0
		rts


* ウィンドウのカーソルを一桁左に移動する.
* in	d0.w	ウィンドウ番号
* 備考:
*	カーソルが左端にある場合は何もしない.

WinCursorLeft::
		PUSH	d0/a0
		WIN_GET_PTR a0
		tst	(WIND_CUR_X,a0)
		beq	@f

		subq	#1,(WIND_CUR_X,a0)
		subq.l	#1,(WIND_CUR_ADR,a0)
@@:
		POP	d0/a0
		rts


* ウィンドウのカーソル位置を一時的に退避する.
* in	d0.w	ウィンドウ番号

WinSaveCursor::
		PUSH	d0/a0
		WIN_GET_PTR a0
		move	(WIND_CUR_X,a0),(WIND_CUR_X2,a0)
		move	(WIND_CUR_Y,a0),(WIND_CUR_Y2,a0)
		move.l	(WIND_CUR_ADR,a0),(WIND_CUR_ADR2,a0)
		POP	d0/a0
		rts


* ウィンドウのカーソル位置を復帰する.
* in	d0.w	ウィンドウ番号

WinRestoreCursor::
		PUSH	d0/a0
		WIN_GET_PTR a0
		move	(WIND_CUR_X2,a0),(WIND_CUR_X,a0)
		move	(WIND_CUR_Y2,a0),(WIND_CUR_Y,a0)
		move.l	(WIND_CUR_ADR2,a0),(WIND_CUR_ADR,a0)
		POP	d0/a0
		rts


* カーソル位置の一文字(一桁)を反転する.
* in	d0.w	ウィンドウ番号

WinReverseChar::
		PUSH	d0-d1/a0-a1
		WIN_GET_PTR a0

		movea.l	(WIND_CUR_ADR,a0),a0
		lea	(a0),a1
		adda.l	#TVRAM_P1-TVRAM_P0,a1
		moveq	#128-1,d1

		TO_SUPER
		moveq	#16-1,d0
@@:		not.b	(a0)+
		not.b	(a1)+
		adda.l	d1,a0
		adda.l	d1,a1
		dbra	d0,@b
		TO_USER

		POP	d0-d1/a0-a1
		rts


* ウィンドウ全体をクリアする.
* in	d0.w	ウィンドウ番号

WinClearAll::
		PUSH	d0-d2/d6-d7/a0-a2
		WIN_GET_PTR a1

		TO_SUPER
		lea	(CRTC_R21),a2
		move	(a2),d6
		move	#$0133,(a2)

		movea.l	(WIND_TX_ADR,a1),a0
		move	(WIND_YSIZE,a1),d7
		lsl	#4,d7			;全ライン数
		subq	#1,d7

		move	(WIND_XSIZE,a1),d0
		move	#$80,d1
		sub	d0,d1			;次のラインへのオフセット
		lsr	#2,d0
		scs	d2			;$ff=半端なワードがある
		add	d0,d0
		lea	(win_clear_all_next,pc),a1
		suba	d0,a1

		moveq	#0,d0
win_clear_all_loop:
		tst.b	d2
		beq	@f
		move	d0,(a0)+		;半端なワードをクリア
@@:		jmp	(a1)

	.rept	128/4
		move.l	d0,(a0)+		;ロングワード単位でクリア
	.endm
win_clear_all_next:
		adda	d1,a0
		dbra	d7,win_clear_all_loop

		move	d6,(a2)
		TO_USER
		POP	d0-d2/d6-d7/a0-a2
		rts


* ウィンドウのカーソル行全体をクリアする.
* in	d0.w	ウィンドウ番号
* 注意:
*	48 桁幅のウィンドウ専用(PATH_WIN_FILE).

WinClearLine::
		PUSH	d0-d7/a0-a6
		WIN_GET_PTR a0
		movea.l	(WIND_CUR_ADR,a0),a0

		TO_SUPER
		lea	(CRTC_R21),a6
		move	(a6),-(sp)
		move	#$0133,(a6)

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		movea.l	d0,a1
		movea.l	d0,a2
		movea.l	d0,a3
		movea.l	d0,a4
		movea.l	d0,a5
		moveq	#16/2-1,d7
@@:
		movem.l	d0-d6/a1-a5,(a0)
		movem.l	d0-d6/a1-a5,(128,a0)
		lea	(128*2,a0),a0
		dbra	d7,@b

		move	(sp)+,(a6)
		TO_USER
		POP	d0-d7/a0-a6
		rts


* ウィンドウ先頭行から(ウィンドウの行数 - d1)行分を
* d1 行下の位置にコピーする.
* in	d0.w	ウィンドウ番号
*	d1.w	行数(1～)
* 注意:
*	48 桁幅のウィンドウ専用(PATH_WIN_FILE).

WinScrollDown::
		PUSH	d0-d7/a0-a5
		moveq	#-128,d6		;次のラインへのオフセット

		WIN_GET_PTR a4

		movea.l	(WIND_TX_ADR,a4),a0
		move	(WIND_YSIZE,a4),d0
		mulu	#128*16,d0
		lea	(-128,a0,d0.l),a0	;転送先左下アドレス(最後のラインの左端)
		lea	(a0),a1
		move	d1,d0
		mulu	#128*16,d0
		suba.l	d0,a1			;転送元〃
		bra	win_scroll_up_down


* ウィンドウ最終行から(ウィンドウの行数 - d1)行分を
* d1 行上の位置にコピーする.
* in	d0.w	ウィンドウ番号
*	d1.w	行数(1～)
* 注意:
*	48 桁幅のウィンドウ専用(PATH_WIN_FILE).

WinScrollUp::
		PUSH	d0-d7/a0-a5
		move	#+128,d6		;次のラインへのオフセット

		WIN_GET_PTR a4

		movea.l	(WIND_TX_ADR,a4),a0	;転送先右上アドレス(最初のラインの左端)
		move	d1,d0
		mulu	#128*16,d0
		lea	(a0,d0.l),a1		;転送元〃
win_scroll_up_down:
		movea.l	#$20000,a2
		movea.l	a2,a3
		adda.l	a0,a2			;プレーン1
		adda.l	a1,a3			;〃

		move	(WIND_YSIZE,a4),d7
		sub	d1,d7
		lsl	#4,d7			;ライン数
		subq.l	#1,d7

		TO_SUPER
		lea	(CRTC_R21),a5
		move	(a5),-(sp)
		clr	(a5)
@@:
		movem.l	(a1),d0-d5
		movem.l	d0-d5,(a0)		;プレーン 0
		movem.l	(4*6,a1),d0-d5
		movem.l	d0-d5,(4*6,a0)		;〃
		movem.l	(a3),d0-d5
		movem.l	d0-d5,(a2)		;プレーン 1
		movem.l	(4*6,a3),d0-d5
		movem.l	d0-d5,(4*6,a2)		;〃
		adda	d6,a0
		adda	d6,a1
		adda	d6,a2
		adda	d6,a3
		dbra	d7,@b

		move	(sp)+,(a5)
		TO_USER
		POP	d0-d7/a0-a5
		rts


* ウィンドウのカーソル行全体の指定プレーンを反転する.
* in	d0.w	ウィンドウ番号
*	d1.w	対象プレーン(%00～%11)

WinReverseLine2::
		PUSH	d0-d3/a0-a1
		bra.s	@f

* ウィンドウのカーソル行全体を反転する.
* in	d0.w	ウィンドウ番号

WinReverseLine::
		PUSH	d0-d3/a0-a1
		moveq	#WHITE,d1
@@:
		WIN_GET_PTR a1

		move	(WIND_XSIZE,a1),d3
		subq	#2,d3
		moveq	#128-2,d2
		sub	d3,d2			;d2 = 次のラインへのオフセット
		lsr	#1,d3			;d3 = X loop count

		movea.l	(WIND_CUR_ADR,a1),a0
		suba	(WIND_CUR_X,a1),a0	;X=0 のアドレス
		lea	(a0),a1
		adda.l	#TVRAM_P1-TVRAM_P0,a1

		TO_SUPER
		moveq	#16-1,d0		;d0 = Y loop count

		subq	#2,d1
		bhi	win_reverse_line_3	;%11
		beq	@f			;%10
		addq	#2,d1
		beq	win_reverse_line_end	;%00
		exg	a0,a1			;%01
@@:
		move	d3,d1
1:		not	(a1)+
		dbra	d1,1b
		adda.l	d2,a1
		dbra	d0,@b
		bra	win_reverse_line_end
win_reverse_line_3:
@@:		move	d3,d1
1:		not	(a0)+
		not	(a1)+
		dbra	d1,1b
		adda.l	d2,a0
		adda.l	d2,a1
		dbra	d0,@b
win_reverse_line_end:
		TO_USER
		POP	d0-d3/a0-a1
		rts


* ウィンドウのカーソル位置から指定した桁数だけ下線を引く.
* in	d0.w	ウィンドウ番号
*	d1.w	対象プレーン(%00～%11、+16 で点線)
*	d2.w	桁数

WinUnderLine2::
		PUSH	d0-d3/a0-a1
		bra.s	@f

* ウィンドウのカーソル行全体に下線を引く.
* in	d0.w	ウィンドウ番号
*	d1.w	対象プレーン(%00～%11、+16 で点線)
* 注意:
*	look.s からスーパーバイザモードで呼ばれている.

WinUnderLine::
		PUSH	d0-d3/a0-a1
		moveq	#0,d2
@@:
		WIN_GET_PTR a1

		movea.l	(WIND_CUR_ADR,a1),a0
		tst	d2
		bne	@f
		suba	(WIND_CUR_X,a1),a0	;X=0 のアドレス
		move	(WIND_XSIZE,a1),d2
@@:
		lea	(128*15,a0),a0		;一番下のライン
		lea	(a0),a1
		adda.l	#$20000,a1

		TO_SUPER
		moveq	#-1,d3
		bclr	#4,d1
		beq	@f
		move	#$aaaa,d3
@@:
		lsr.b	#1,d1
		scs	d0
		sne	d1
		ext	d0
		ext	d1
		and	d3,d0
		and	d3,d1

		move	a0,d3
		or	d2,d3
		subq	#1,d2			;X loop count
		lsr	#1,d3
		bcc	win_under_line_w
@@:
		eor.b	d0,(a0)+
		eor.b	d1,(a1)+
		dbra	d2,@b
		bra	win_under_line_end
win_under_line_w:
		lsr	#1,d2			;始点アドレス、桁数が偶数の場合
@@:
		eor	d0,(a0)+
		eor	d1,(a1)+
		dbra	d2,@b
win_under_line_end:
		TO_USER2
		POP	d0-d3/a0-a1
		rts


* 以下はフレーム付きウィンドウの処理 ---------- *

* フレーム付きウィンドウを表示する.
* in	a0.l	SUBWIN 構造体
* out	d0.l	ウィンドウ番号

WinOpen::
		PUSH	d1-d4/a1
		moveq	#%1111_1110,d0
		and	d0,(SUBWIN_X,a0)
		and	d0,(SUBWIN_XSIZE,a0)

		movem	(SUBWIN_X,a0),d1-d4
		addq	#2,d4			;タイトル行とフレーム枠の分

		bsr	WinCreate
		bsr	win_push_text
		bsr	WinClearAll
		bsr	win_draw_title
.if 0
		bsr	win_draw_mes
.endif
		bsr	win_draw_frame

		movea.l	(SUBWIN_TITLE,a0),a1
		bsr	win_emphasis

		moveq	#WHITE,d1
		bsr	WinSetColor

		POP	d1-d4/a1
		rts


* フレーム付きウィンドウを消去する.
* in	d0.w	ウィンドウ番号

WinClose::
.ifdef WIN_DEBUG
		PUSH	d0/a0
		WIN_GET_PTR a0
		tst.l	(WIND_TX_ADR,a0)
		POP	d0/a0
		bne	@f
		DEBUG_PRINT 'WinClose: ウィンドウ番号が不正です.'
		rts
@@:
.endif
		bsr	win_pop_text
		bsr	win_emp_pop_text
		bra	WinDelete
**		rts


* フレーム付きウィンドウ下請け ---------------- *

* ウィンドウ内の T-VRAM の内容を退避する.
* in	d0.w	ウィンドウ番号
* 備考:
*	退避用バッファとして、T-VRAM の表示されない
*	位置(右端の 128-96=32 桁分)を使用する.

win_push_text:
		PUSH	d0-d5/a0-a5
		WIN_GET_PTR a2
		TO_SUPER

		move	(WIND_XSIZE,a2),d0
		move	#$80,d1
		sub	d0,d1			;次のラインへのオフセット
		lsr	#1,d0
		subq	#1,d0
		move	(WIND_YSIZE,a2),d2
		lsl	#4,d2			;ライン数
		subq	#1,d2

		movea.l	(WIND_TX_ADR,a2),a0
		lea	(a0),a1
		adda.l	#$20000,a1
		lea	(TVRAM_P0+96),a2	;退避先
		lea	(TVRAM_P1+96),a3

		moveq	#96,d5
		moveq	#(128-96)/2-1,d4
win_push_text_loop_y:
		move	d0,d3
win_push_text_loop_x:
		move	(a0)+,(a2)+
		move	(a1)+,(a3)+
		dbra	d4,@f

		adda.l	d5,a2			;退避先のアドレスをずらす
		adda.l	d5,a3
		moveq	#(128-96)/2-1,d4
@@:
		dbra	d3,win_push_text_loop_x
		adda	d1,a0
		adda	d1,a1
		dbra	d2,win_push_text_loop_y

		TO_USER
		POP	d0-d5/a0-a5
		rts


* ウィンドウ内から退避した T-VRAM の内容を戻す.
* in	d0.w	ウィンドウ番号

win_pop_text:
		PUSH	d0-d5/a0-a5
		WIN_GET_PTR a2
		TO_SUPER

		move	(WIND_XSIZE,a2),d0
		move	#$80,d1
		sub	d0,d1			;次のラインへのオフセット
		lsr	#1,d0
		subq	#1,d0
		move	(WIND_YSIZE,a2),d2
		lsl	#4,d2			;ライン数
		subq	#1,d2

		movea.l	(WIND_TX_ADR,a2),a0
		lea	(a0),a1
		adda.l	#$20000,a1
		lea	(TVRAM_P0+96),a2	;退避先
		lea	(TVRAM_P1+96),a3

		moveq	#96,d5
		moveq	#(128-96)/2-1,d4
win_pop_text_loop_y:
		move	d0,d3
win_pop_text_loop_x:
		move	(a2)+,(a0)+
		move	(a3)+,(a1)+
		dbra	d4,@f

		adda.l	d5,a2			;退避先のアドレスをずらす
		adda.l	d5,a3
		moveq	#(128-96)/2-1,d4
@@:
		dbra	d3,win_pop_text_loop_x
		adda	d1,a0
		adda	d1,a1
		dbra	d2,win_pop_text_loop_y

		TO_USER
		POP	d0-d5/a0-a5
		rts


* ウィンドウのタイトル行を描画する.
* in	d0.w	ウィンドウ番号
*	a0.l	SUBWIN 構造体

win_draw_title:
		tst	(＄wind)
		bne	win_draw_title_skip	;強調時は別ルーチンで描画する

		PUSH	d1-d2/a1
		moveq	#0,d1
		movea.l	(SUBWIN_TITLE,a0),a1
.if 1
		move	(SUBWIN_XSIZE,a0),d1	;中央寄せ
		STRLEN	a1,d2
		sub.l	d2,d1
		bcc	@f
		moveq	#0,d1
@@:		lsr.l	#1,d1
.endif
		moveq	#0,d2
		bsr	WinSetCursor
		moveq	#BLUE,d1
		bsr	WinSetColor
		bsr	WinPrint
**		moveq	#BLUE,d1
		bsr	WinReverseLine2
		POP	d1-d2/a1
win_draw_title_skip:
		rts


* ウィンドウの本文を描画する(現在未使用).
* in	d0.w	ウィンドウ番号
.if 0
win_draw_mes:
		PUSH	d1-d4/a1-a2
		lea	(-512,sp),sp

		tst	(SUBWIN_YSIZE,a0)	;中身なし
		beq	win_draw_mes_end
		move.l	(SUBWIN_MES,a0),d1
		beq	win_draw_mes_end	;本文なし

		movea.l	d1,a2
		moveq	#1,d2			;Y
win_draw_mes_loop:
		moveq	#1,d1			;X
		bsr	WinSetCursor
		moveq	#YELLOW,d1
		bsr	WinSetColor

		move.b	(a2)+,d1		;ショートカットキー
		cmpi.b	#$20,d1
		bcs	win_draw_mes_end	;制御記号なら終わり

		bsr	WinPutChar

		moveq	#4,d1			;空白二個分
		bsr	WinSetCursor
		moveq	#WHITE,d1
		bsr	WinSetColor

		moveq	#$20,d3
@@:		cmp.b	(a2)+,d3		;タブ/スペースを飛ばす
		bcc	@b
		subq.l	#1,a2

		lea	(sp),a1
@@:
		move.b	(a2)+,d1		;"～" 展開
		cmp.b	d3,d1
		bls	9f
		cmpi.b	#'"',d1
		beq	1f
		cmpi.b	#"'",d1
		beq	1f
		move.b	d1,(a1)+
		bra	@b
1:
		move.b	(a2)+,d4
		move.b	d4,(a1)+
		cmp.b	d1,d4
		bne	1b
		subq.l	#1,a1
		bra	@b
9:		
		clr.b	(a1)
		subq.l	#1,a2

		lea	(sp),a1
		bsr	WinPrint
@@:
		move.b	(a2)+,d1		;行の残りを飛ばす
		cmpi.b	#EOF,d1
		beq	win_draw_mes_end
		cmpi.b	#LF,d1
		bne	@b
		cmpi.b	#TAB,(a2)
		beq	@b			;次の行頭がタブならその行も飛ばす

		addq	#1,d2			;Y++
		bra	win_draw_mes_loop
win_draw_mes_end:
		lea	(512,sp),sp
		POP	d1-d4/a1-a2
		rts
.endif


* ウィンドウのフレームを描画する.
* in	d0.w	ウィンドウ番号

win_draw_frame:
		tst	(＄wind)
		bne	win_draw_frame_skip	;強調時は別ルーチンで描画する

		PUSH	d0-d4/a0-a1
		WIN_GET_PTR a1
		TO_SUPER

		moveq	#128-2,d1
		move	#$8000,d2		;左枠パターン
		moveq	#$0001,d3		;右枠〃
		move	(WIND_YSIZE,a1),d4
		lsl	#4,d4
		subi	#16+8+1,d4		;左右枠のライン数-1

		movea.l	(WIND_TX_ADR,a1),a0
		lea	(128*16,a0),a0		;左枠アドレス
		move	(WIND_XSIZE,a1),d0
		lea	(-2,a0,d0.w),a1		;右枠〃
@@:
		or	d2,(a0)+		;左右の枠を引く
		or	d3,(a1)+
		adda	d1,a0
		adda	d1,a1
		dbra	d4,@b

		moveq	#$ff,d1
		lsr	#1,d0
		subq	#1,d0
@@:
		move	d1,(a0)+		;下の枠を引く
		dbra	d0,@b

		TO_USER
		POP	d0-d4/a0-a1
win_draw_frame_skip:
		rts


* 文字描画ルーチン ---------------------------- *

* ウィンドウに一バイト表示する.
* in	d0.w	ウィンドウ番号
*	d1.b	文字コード
* 備考
*	マルチバイト文字の場合は上位バイトと下位
*	バイトの二回に分けて呼び出す必要がある.

WinPutChar::
		PUSH	d0-d4/a0-a5
		WIN_GET_PTR a4

		movea.l	(WIND_CUR_ADR,a4),a1
		move	(WIND_CUR_X,a4),d3
		move	(WIND_XSIZE,a4),d4
		cmp	d3,d4
		bhi	@f

		suba.l	d3,a1			;次の行に移動する
		addq	#1,(WIND_CUR_Y,a4)
		lea	($800,a1),a1
		moveq	#0,d3
@@:
		TO_SUPER
		moveq	#$f,d0
		and	(WIND_COLOR,a4),d0
		lsl	#4,d0
		ori	#$0103,d0
		lea	(CRTC_R21),a5
		move	d0,(a5)

		bsr	win_print_char

		move	#$0033,(a5)
		TO_USER

		move.l	a1,(WIND_CUR_ADR,a4)
		move	d3,(WIND_CUR_X,a4)

		POP	d0-d4/a0-a5
		rts

* ウィンドウのフレームを考慮して、文字列を表示する(現在未使用).
* in	d0.w	ウィンドウ番号
*	a1.l	文字列のアドレス
* out	a1.l	文字列末尾＋１のアドレス
* 備考:
*	フレーム表示つきのサブウィンドウで、右端の枠線の
*	上まで文字を表示しないように、一桁少なくしてから
*	文字列表示を呼ぶ.

.if 0
WinPrint2::
		move.l	a4,-(sp)
		move	d0,-(sp)
		WIN_GET_PTR a4
		move	(sp)+,d0

		subq	#1,(WIND_XSIZE,a4)
		bsr	WinPrint
		addq	#1,(WIND_XSIZE,a4)	

		movea.l	(sp)+,a4
		rts
.endif


* ウィンドウに文字列を表示する.
* in	d0.w	ウィンドウ番号
*	a1.l	文字列のアドレス
* out	a1.l	文字列末尾＋１のアドレス
* 仕様:
*	文字列の終了条件は以下の通り.
*	NUL | EOF | LF | CRLF | CR
* 例:
*	a1.l = 'abc',CR,LF,'def...' や a1.l = 'abc',0,'def...' 
*	で呼び出した場合、返値の a1.l はいずれも 'd' を指す.

.if 1
WinPrint2::					;ダミー
.endif
WinPrint::
		PUSH	d0-d4/d7/a0/a2-a4
		WIN_GET_PTR a4

		movea.l	a1,a0			;文字列
		movea.l	(WIND_CUR_ADR,a4),a1	;カーソル位置テキストアドレス
		move	(WIND_CUR_X,a4),d3	;カーソル桁位置
		move	(WIND_XSIZE,a4),d4	;桁数
		moveq	#$20,d7

		TO_SUPER
		moveq	#$f,d0
		and	(WIND_COLOR,a4),d0
		lsl	#4,d0
		ori	#$0103,d0
		move	d0,(CRTC_R21)
		bra	win_print_loop

win_print_normal:
		bsr	win_print_char
win_print_loop:
		cmp	d4,d3
		bcc	win_print_end		;ウィンドウ右端まで行った

		move.b	(a0)+,d1
		beq	win_print_end
		cmp.b	d7,d1
		bcc	win_print_normal
		cmpi.b	#LF,d1
		beq	win_print_end
		cmpi.b	#CR,d1
		beq	win_print_cr
		cmpi.b	#EOF,d1
		beq	win_print_end
		cmpi.b	#TAB,d1
		bne	win_print_normal

		bsr	win_tab
		bra	win_print_loop		;TAB
win_print_cr:
		cmpi.b	#LF,(a0)+
		beq	win_print_end		;CR,LF
		subq.l	#1,a0			;CR のみの場合
win_print_end:
		move	#$0033,(CRTC_R21)
		TO_USER

		move.l	a1,(WIND_CUR_ADR,a4)
		move	d3,(WIND_CUR_X,a4)
		movea.l	a0,a1
		POP	d0-d4/d7/a0/a2-a4
		rts


* タブ処理 ------------------------------------ *
* look.s からも呼び出される.

win_tab::
		move	d3,d2
		and	(WIND_TABCNEG,a4),d3
		add	(WIND_TABC,a4),d3
		moveq	#0,d1
		move	d3,d1
		sub	d2,d1
		adda.l	d1,a1
		rts

* 一文字描画処理 ------------------------------ *
* in	d1.b	文字コード
*	d3.l	カーソル桁位置
*	d4.l	桁数
*	a0.l	文字列アドレス
*	a1.l	T-VRAM アドレス
*	a4.l	ウィンドウ管理構造体
* break	a2

win_print_char::
		tst.b	(WIND_MB_FLAG,a4)
		beq	win_pr_ch_mb2		;漢字の二バイト目が揃った

		move.b	d1,d0
		lsr	#5,d0
		btst	d0,#%10010000
		bne	win_pr_ch_mb1		;漢字の一バイト目
@@:
		cmpi.b	#$20,d1
		bcs	@f

		bsr	win_draw_char		;一バイト半角文字
		addq.l	#1,d3
		rts
@@:
		cmpi.b	#TAB,d1
		beq	win_tab			;TAB は特別な処理

		move	(CRTC_R21),-(sp)
		move	#$0123,(CRTC_R21)
		bsr	win_draw_char2		;制御記号
		move	(sp)+,(CRTC_R21)
		addq.l	#1,d3
		rts

* 漢字一バイト目
win_pr_ch_mb1:
		move	d4,d0
		subq.l	#1,d0
		cmp	d3,d0
		bls	@f

		move.b	d1,(WIND_MB_HIGH,a4)
		clr.b	(WIND_MB_FLAG,a4)
		rts
@@:
		move.b	d1,-(a0)		;全角を描画する幅が残っていなければ
		addq.l	#1,d3			;取り止めて、カーソルだけ進めておく
		addq.l	#1,a1
		rts

* 漢字二バイト目
win_pr_ch_mb2:
		move.b	d1,(WIND_MB_LOW,a4)
		move	(WIND_MB_CODE,a4),d1

* look.s からも呼び出される.
win_draw_mb_char::
		st	(WIND_MB_FLAG,a4)

		movea.l	a0,a2
		moveq	#8,d2
		movea.l	($400+_FNTADR*4),a0
		jsr	(a0)
		movea.l	a2,a0
		movea.l	d0,a2
		tst	d1
		beq	@f

		bsr	win_draw_double		;全角文字
		addq.l	#2,d3
		rts
@@:
		bsr	win_draw_half		;二バイト半角文字
		addq.l	#1,d3
		rts

* '\' '|' '~' は毎回 IOCS コールでフォントを収得する
win_draw_char_sw:
		movea.l	a0,a2
		moveq	#8,d2
		movea.l	($400+_FNTADR*4),a0
		jsr	(a0)
		movea.l	a2,a0
		movea.l	d0,a2
		bra	win_draw_half

* look.s からも呼び出される.
win_draw_char::
		cmpi.b	#'\',d1
		beq	win_draw_char_sw
		cmpi.b	#'|',d1
		beq	win_draw_char_sw
		cmpi.b	#'~',d1
		beq	win_draw_char_sw
win_draw_char2:
		andi	#$00ff,d1
		lsl	#4,d1
		movea.l	(font_addres,pc),a2
		adda	d1,a2

* look.s からも呼び出される.
win_draw_half::
		move	(WIND_COLOR,a4),d0
		lsr.b	#4,d0
		add	d0,d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	half_normal-@b
		.dc	half_emp-@b
		.dc	half_rev-@b
		.dc	half_emp_rev-@b
		.dc	half_ul-@b
		.dc	half_emp_ul-@b
		.dc	half_rev_ul-@b
		.dc	half_emp_rev_ul-@b

half_normal:
		move.b	(a2)+,(a1)+		;半角通常
	.irpc	%N,123456789abcdef
		move.b	(a2)+,(128*$%N-1,a1)
	.endm
		rts
half_emp:
		move.b	(a2)+,d0		;半角強調
		move.b	d0,d1
		lsr.b	#1,d0
		or.b	d1,d0
		move.b	d0,(a1)+
	.irpc	%N,123456789abcdef
		move.b	(a2)+,d0
		move.b	d0,d1
		lsr.b	#1,d0
		or.b	d1,d0
		move.b	d0,($80*$%N-1,a1)
	.endm
		rts
half_rev:
		move.b	(a2)+,d1		;半角反転
		not.b	d1
		move.b	d1,(a1)+
	.irpc	%N,123456789abcdef
		move.b	(a2)+,d1
		not.b	d1
		move.b	d1,($80*$%N-1,a1)
	.endm
		rts
half_emp_rev:
		move.b	(a2)+,d0		;半角強調反転
		move.b	d0,d1
		lsr.b	#1,d0
		or.b	d1,d0
		not.b	d0
		move.b	d0,(a1)+
	.irpc	%N,123456789abcdef
		move.b	(a2)+,d0
		move.b	d0,d1
		lsr.b	#1,d0
		or.b	d1,d0
		not.b	d0
		move.b	d0,($80*$%N-1,a1)
	.endm
		rts
half_ul:
		bsr	half_normal		;半角下線
		st	($077f,a1)
		rts
half_emp_ul:
		bsr	half_emp		;半角強調下線
		st	($077f,a1)
		rts
half_rev_ul:
		bsr	half_rev		;半角反転下線
		st	($077f,a1)
		rts
half_emp_rev_ul:
		bsr	half_emp_rev		;半角強調反転下線
		st	($077f,a1)
		rts

win_draw_double:
		move	a1,d0
		lsr	#1,d0
		bcc	win_draw_double_even
* 奇数アドレス
*win_draw_double_odd:
		move	(WIND_COLOR,a4),d0
		lsr.b	#4,d0
		add	d0,d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	odd_normal-@b
		.dc	odd_emp-@b
		.dc	odd_rev-@b
		.dc	odd_emp_rev-@b
		.dc	odd_ul-@b
		.dc	odd_emp_ul-@b
		.dc	odd_rev_ul-@b
		.dc	odd_emp_rev_ul-@b

odd_normal:
		move.b	(a2)+,(a1)+		;全角通常(奇数アドレス)
		move.b	(a2)+,(a1)+
	.irpc	%N,123456789abcdef
		move.b	(a2)+,($80*$%N-2,a1)
		move.b	(a2)+,($80*$%N-1,a1)
	.endm
		rts
odd_emp:
		move	(a2)+,d0		;全角強調(奇数アドレス)
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		move	d0,-(sp)
		move.b	(sp)+,(a1)+
		move.b	d0,(a1)+
	.irpc	%N,123456789abcdef
		move	(a2)+,d0
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		move	d0,-(sp)
		move.b	(sp)+,($80*$%N-2,a1)
		move.b	d0,   ($80*$%N-1,a1)
	.endm
		rts
odd_rev:
		move	(a2)+,d0		;全角反転(奇数アドレス)
		not	d0
		move	d0,-(sp)
		move.b	(sp)+,(a1)+
		move.b	d0,(a1)+
	.irpc	%N,123456789abcdef
		move	(a2)+,d0
		not	d0
		move	d0,-(sp)
		move.b	(sp)+,($80*$%N-2,a1)
		move.b	d0,   ($80*$%N-1,a1)
	.endm
		rts
odd_emp_rev:
		move	(a2)+,d0		;全角強調反転(奇数アドレス)
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		not	d0
		move	d0,-(sp)
		move.b	(sp)+,(a1)+
		move.b	d0,(a1)+
	.irpc	%N,123456789abcdef
		move	(a2)+,d0
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		not	d0
		move	d0,-(sp)
		move.b	(sp)+,($80*$%N-2,a1)
		move.b	d0,   ($80*$%N-1,a1)
	.endm
		rts
odd_ul:
		bsr	odd_normal		;全角下線(奇数アドレス)
		st	($0780-2,a1)
		st	($0781-2,a1)
		rts
odd_emp_ul:
		bsr	odd_emp			;全角強調下線(奇数アドレス)
		st	($0780-2,a1)
		st	($0781-2,a1)
		rts
odd_rev_ul:
		bsr	odd_rev			;全角反転下線(奇数アドレス)
		st	($0780-2,a1)
		st	($0781-2,a1)
		rts
odd_emp_rev_ul:
		bsr	odd_emp_rev		;全角強調反転下線(奇数アドレス)
		st	($0780-2,a1)
		st	($0781-2,a1)
		rts

* 偶数アドレス
win_draw_double_even:
		move	(WIND_COLOR,a4),d0
		lsr.b	#4,d0
		add	d0,d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	even_normal-@b
		.dc	even_emp-@b
		.dc	even_rev-@b
		.dc	even_emp_rev-@b
		.dc	even_ul-@b
		.dc	even_emp_ul-@b
		.dc	even_rev_ul-@b
		.dc	even_emp_rev_ul-@b

even_normal:
		move	(a2)+,(a1)+		;全角通常(偶数アドレス)
	.irpc	%N,123456789abcdef
		move	(a2)+,($80*$%N-2,a1)
	.endm
		rts
even_emp:
		move	(a2)+,d0		;全角強調(偶数アドレス)
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		move	d0,(a1)+
	.irpc	%N,123456789abcdef
		move	(a2)+,d0
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		move	d0,($80*$%N-2,a1)
	.endm
		rts
even_rev:
		move	(a2)+,d0		;全角反転(偶数アドレス)
		not	d0
		move	d0,(a1)+
	.irpc	%N,123456789abcdef
		move	(a2)+,d0
		not	d0
		move	d0,($80*$%N-2,a1)
	.endm
		rts
even_emp_rev:
		move	(a2)+,d0
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		not	d0
		move	d0,(a1)+
	.irpc	%N,123456789abcdef
		move	(a2)+,d0
		move	d0,d1
		lsr	#1,d1
		or	d1,d0
		not	d0
		move	d0,($80*$%N-2,a1)
	.endm
		rts
even_ul:
		bsr	even_normal		;全角下線(偶数アドレス)
		move	#$ffff,($0780-2,a1)
		rts
even_emp_ul:
		bsr	even_emp		;全角強調下線(偶数アドレス)
		move	#$ffff,($0780-2,a1)
		rts
even_rev_ul:
		bsr	even_rev		;全角反転下線(偶数アドレス)
		move	#$ffff,($0780-2,a1)
		rts
even_emp_rev_ul:
		bsr	even_emp_rev		;全角強調反転下線(偶数アドレス)
		move	#$ffff,($0780-2,a1)
		rts


* ウィンドウ強調ルーチン ---------------------- *
* この部分は整形程度しか手を入れていない.

* ウィンドウを強調する.
* in	d1.w	左上Ｘ座標
*	d2.w	 〃 Ｙ 〃
*	d3.w	Ｘ方向の大きさ(桁数)
*	d4.w	Ｙ	〃    (行数)
*	a1.l	タイトル文字列

win_emphasis:
		bsr	test_wind
		bcs	win_emp_end		;%wind 0

		PUSH	d0-d7/a0-a6
		lsl	#3,d1
		lsl	#3,d3
		lsl	#4,d2
		lsl	#4,d4

		bsr	win_emp_push_text
		bsr	win_emp_title
		bsr	win_emp_write
		bsr	win_emp_frame
		bsr	win_emp_polish
		bsr	win_emp_solid
		POP	d0-d7/a0-a6
win_emp_end:
		rts


test_wind:
		cmpi	#1,(＄wind)
		rts


* 強調ウィンドウ: タイトル描画
* in	d1-d4/a1
win_emp_title:
		PUSH	d0-d7/a1-a2
		move	d3,d0
		lea	(win_emp_len,pc),a5
		clr	(a5)
@@:
		addq	#1,(a5)			;タイトルの文字列長
		tst.b	(a1)+
		bne	@b
		lsr	#3,d0
		subq	#4,d0
		cmp	(a5),d0
		bcc	@f
		move	d0,(a5)
@@:
		bsr	win_emp_calc
		movem.l	(sp),d0-d7/a1-a2

		moveq	#0,d0
		lsr	#3,d1
		lsr	#3,d3
		lsr	#4,d2
		lsr	#4,d4

		move.l	d3,d4			;x length
		subq.l	#1,d4
		move.l	d2,d3			;y start 
		move.l	d1,d2			;x start
		add	(win_emp_len2,pc),d0
		lsr	#3,d0
		addq	#1,d0

		lea	(-128,sp),sp
		lea	(sp),a2
@@:		move.b	#SPACE,(a2)+
		dbra	d0,@b
@@:		move.b	(a1)+,(a2)+
		bne	@b

		moveq	#BLUE+REVERSE,d1
		lea	(1,sp),a1
		IOCS	_B_PUTMES
		lea	(128,sp),sp

		POP	d0-d7/a1-a2
		rts


* 強調ウィンドウ: 外枠描画
win_emp_frame:
		PUSH	d0-d7
		subq.l	#1,d2
		subq.l	#2,d3
		subq.l	#8,d4

		lea	(win_emp_txb,pc),a1
		move	d1,(TXBOX_XSTART,a1)
		move	d2,(TXBOX_YSTART,a1)
		move	d3,(TXBOX_XLEN,a1)
		move	d4,(TXBOX_YLEN,a1)
		IOCS	_TXBOX
		addq	#1,(TXBOX_XLEN,a1)
		addq	#1,(TXBOX_YLEN,a1)
		IOCS	_TXBOX
		addq	#1,(TXBOX_XLEN,a1)

		bsr	test_wind
		bls	@f
		addq	#1,(TXBOX_YLEN,a1)	;%wind 2 なら更に重厚
@@:		IOCS	_TXBOX

		POP	d0-d7
		rts


* 強調ウィンドウ: 縞々模様描画
win_emp_write:
		PUSH	d0-d7
		bsr	win_emp_calc

		lea	(win_emp_txl,pc),a1
		addq	#2,d2
		PUSH	d0-d3
		subq	#3,d2
		subq	#2,d3
		move	d1,(TXXL_XSTART,a1)
		move	d2,(TXXL_YSTART,a1)
		move	d3,(TXXL_XLEN,a1)
		IOCS	_TXXLINE
		addq	#4,(TXXL_XSTART,a1)
		subq	#4,(TXXL_XLEN,a1)
		addq	#2,(TXXL_YSTART,a1)
		IOCS	_TXXLINE
		POP	d0-d3

		addq	#1,d2
		PUSH	d0-d4
		addq	#4,d1			;左側
		move	d1,(TXXL_XSTART,a1)
		move	d2,(TXXL_YSTART,a1)
		move	d5,(TXXL_XLEN,a1)
		moveq	#6-1,d6
@@:
		IOCS	_TXXLINE
		addq	#2,(TXXL_YSTART,a1)
		dbra	d6,@b

		subq	#2,(TXXL_XSTART,a1)
		addq	#2,(TXXL_XLEN,a1)
		IOCS	_TXXLINE

		bsr	test_wind
		bls	@f
		subq	#1,(TXXL_YSTART,a1)	;%wind 2 なら更に重厚な影
		IOCS	_TXXLINE
@@:		POP	d0-d4

		move	d1,(TXXL_XSTART,a1)	;右側
		add	d0,(TXXL_XSTART,a1)
		add	d5,(TXXL_XSTART,a1)
		move	d2,(TXXL_YSTART,a1)
		subq	#5,(TXXL_XLEN,a1)
		moveq	#7-1,d6
@@:
		IOCS	_TXXLINE
		addq	#2,(TXXL_YSTART,a1)
		dbra	d6,@b

		bsr	test_wind
		bls	@f
		subq	#3,(TXXL_YSTART,a1)	;%wind 2 なら更に重厚な影
		IOCS	_TXXLINE
@@:
		POP	d0-d7
		rts


* 強調ウィンドウ: 艶効果描画
win_emp_polish:
		PUSH	d0-d5
		addq	#1,d1
		addq	#1,d2
		subq	#2,d3

		lea	(win_emp_txl2,pc),a1
		movem	d1-d3,(TXXL_XSTART,a1)	;2ライン目 上の長い艶
		subq	#1,(TXXL_YSTART,a1)
		IOCS	_TXXLINE
		move	#14,(TXXL_XLEN,a1)	;左上 横の艶
		IOCS	_TXYLINE

		clr	(TXXL_PLANE,a1)
		add	d4,(TXXL_YSTART,a1)	;下 二層目 
		subi	#11,(TXXL_YSTART,a1)
		move	d3,(TXXL_XLEN,a1)
		subq	#3,(TXXL_XLEN,a1)
		IOCS	_TXXLINE

		subq	#3,d3
		add	d3,(TXYL_XSTART,a1)	;右端 内側
		addi	#15,d2
		move	d2,(TXYL_YSTART,a1)
		subi	#26,d4
		move	d4,(TXYL_YLEN,a1)
		IOCS	_TXYLINE
		move	d1,(TXYL_XSTART,a1)	;左端 内側
		IOCS	_TXYLINE

		addq	#1,(TXYL_PLANE,a1)
		POP	d0-d5
		rts


* 強調ウィンドウ: 立体的装飾描画
win_emp_solid:
		PUSH	d0-d7

		lea	(win_emp_txl,pc),a1	;左側
		move	d1,d0
		add	(win_emp_len2,pc),d0
		addq	#4,d0
		move	d0,(TXYL_XSTART,a1)
		addq	#2,d2
		move	d2,(TXYL_YSTART,a1)
		move	#16-2,(TXYL_YLEN,a1)
		IOCS	_TXYLINE

		lea	(win_emp_txl2,pc),a1	;右側
		move	(win_emp_len,pc),d0
		lsl	#3,d0
		add	d1,d0
		add	(win_emp_len2,pc),d0
		subq	#2,d0
		move	d0,(TXYL_XSTART,a1)
		move	d2,(TXYL_YSTART,a1)
		move	#14,(TXYL_YLEN,a1)
		IOCS	_TXYLINE

		add	(win_emp_len2,pc),d1	;下側
		addq	#3,d1
		move	d1,(TXXL_XSTART,a1)
		addi	#13,(TXXL_YSTART,a1)
		move	(win_emp_len,pc),d0
		lsl	#3,d0
		subq	#4,d0
		move	d0,(TXXL_XLEN,a1)
		IOCS	_TXXLINE

		POP	d0-d7
		rts


* 強調ウィンドウ: 各種パラメータ計算
win_emp_calc:
		move.l	a0,-(sp)
		lea	(win_emp_len,pc),a0
		moveq	#0,d5
		bra	1f
@@:
		subq	#1,(a0)
1:		moveq	#2,d0			;スペーサ
		add	(a0),d0
		lsl	#3,d0			;strings length dot
		cmp	d3,d0			;X length	dot
		bhi	@b

		move	(a0),d0
		lsl	#3,d0			;strings length dot
		move	d3,d5
		sub	d0,d5			;d5.l = 実際に縞々を書くドット数
		move	d0,d7
		lsr	#1,d5			;片側の分
		move	d5,(win_emp_len2)

		movea.l	(sp)+,a0
		rts


* 強調ウィンドウ: T-VRAM プレーン 2 退避/パレット保存&設定
win_emp_push_text:
		PUSH	d0-d7/a0-a6
		tst	d2
		beq	@f
		subq	#1,d2
@@:		subq	#8,d3

		moveq	#0,d0
		move	d1,d0
		moveq	#0,d1
		move	d2,d1

		asl.l	#7,d1
		asr	#3,d0
		add.l	d0,d1

		lea	(win_emp_offs,pc),a0
		move.l	d1,(a0)+		;win_emp_offs
		move	d4,(a0)+		;win_emp_y_size
		move	d3,(a0)+		;win_emp_x_size

		lea	(TVRAM_P2),a0		;T-VRAM 保存
		pea	(win_emp_push_text_sub,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp

		lea	(win_emp_palet,pc),a0	;パレット保存
		moveq	#4,d1
		moveq	#-1,d2
		IOCS	_TPALET
		move	d0,(a0)+
		moveq	#8,d1
		IOCS	_TPALET
		move	d0,(a0)

		moveq	#0,d2
		move	(＄wcl1),d2
		bne	@f
		move	-(a0),d2		;%wcl1 0 なら #4～7 の色を #8～15 に設定
@@:
		moveq	#4,d1			;パレット設定
		IOCS	_TPALET
		moveq	#8,d1
		IOCS	_TPALET

		POP	d0-d7/a0-a6
		rts


* 強調ウィンドウ: T-VRAM プレーン 2 復帰/パレット復帰
win_emp_pop_text:
		bsr	test_wind
		bcs	win_emp_pop_text_end	;%wind 0

		PUSH	d0-d7/a0-a6
		lea	(TVRAM_P2),a0		;T-VRAM 復帰
		pea	(win_emp_pop_text_sub,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp

		lea	(win_emp_palet,pc),a0	;パレット復帰
		moveq	#0,d2
		move	(a0)+,d2
		moveq	#4,d1
		IOCS	_TPALET
		move	(a0),d2
		moveq	#8,d1
		IOCS	_TPALET

		POP	d0-d7/a0-a6
win_emp_pop_text_end:
		rts


* 強調ウィンドウ: T-VRAM プレーン 2 退避下請け
win_emp_push_text_sub:
		bsr	win_emp_push_pop_text
@@:
		move.b	(a0)+,(a1)+		;text -> buffer
		dbra	d5,@b
		rts


* 強調ウィンドウ: T-VRAM プレーン 2 復帰下請け
win_emp_pop_text_sub:
		bsr	win_emp_push_pop_text
@@:
		move.b	(a1)+,(a0)+		;buffer -> text
		dbra	d5,@b
		rts

win_emp_push_pop_text:
		movea.l	(sp)+,a2		;ライン転送ルーチン
		movea.l	a0,a1
		adda.l	(win_emp_offs,pc),a0
		adda.l	#$10000,a1
		move	(win_emp_y_size,pc),d7
		move	(win_emp_x_size,pc),d6
		lsr	#3,d6
@@:
		move	d6,d5
		jsr	(a2)			;1 ライン転送する
		lea	($80-1,a0),a0
		suba	d6,a0
		dbra	d7,@b
		rts


* Data Section -------------------------------- *

**		.data
		.even

win_emp_txl:	.dc	$8004,0,0,0,$ffff
win_emp_txl2:	.dc	    1,0,0,0,$ffff
win_emp_txb:	.dc	  2,0,0,0,0,$ffff


* Block Storage Section ----------------------- *

**		.bss
		.even

font_addres:	.ds.l	1

win_emp_offs:	.ds.l	1
win_emp_y_size:	.ds	1
win_emp_x_size:	.ds	1
win_emp_len:	.ds	1
win_emp_len2:	.ds	1
win_emp_palet:	.ds	2


* 以下は本当の BSS
		.bss
		.even

wind_buf:	.ds.b	sizeof_WIND*WIND_MAX


		.end

* End of File --------------------------------- *
