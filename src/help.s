# help.s - &ext-help, &describe-key
# Copyright (C) 2024 TcbnErik
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

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	copy_dir_name_a1_a2
* look.s
		.xref	iocs_key_flush
* madoka3.s
		.xref	execute_quick_no,free_token_buf
		.xref	execute_quick
* mint.s
		.xref	update_periodic_display
		.xref	skip_define_word
		.xref	iocs_b_keyinp_ex
		.xref	search_cursor_file
		.xref	search_file_define
		.xref	mintrc_buf_adr
		.xref	kq_buffer,key_quick_esc_default
		.xref	AK_ROLLUP,AK_ROLLDOWN,AK_UP,AK_DOWN
* mintarc.s
		.xref	mintarc_extract
* outside.s
		.xref	dos_inpout
		.xref	atoi_a0,print_sub
		.xref	set_user_value_a1_a2


* Constant ------------------------------------ *

MAX_LINE:	.equ	23


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&ext-help			*
*************************************************

＆ext_help::
		moveq	#MES_HELPM,d0
		bsr	help_menu_getarg0

		jsr	(search_cursor_file)
		btst	#DIRECTORY,(DIR_ATR,a4)
		bne	ext_help_end		;dir/end of buffer はエラー

		lea	(DIR_NAME,a4),a1
		lea	(Buffer),a2
		jsr	(copy_dir_name_a1_a2)

		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		moveq	#%011,d0
		jsr	(mintarc_extract)
@@:
		moveq	#1,d0			;help モード
		jsr	(search_file_define)
		bne	ext_help_found

* 全く定義されていないならエラー表示
		moveq	#0,d6			;待機時間
		moveq	#1,d7			;引数の数
		GETMES	MES_NODEF
		movea.l	d0,a0			;本文
		lea	(a3),a1			;タイトル
		jmp	(print_sub)
**		rts

ext_help_found:
		lea	(a1),a4

		lea	(Buffer),a0
		moveq	#$20,d1
		moveq	#0,d7			;行数

		move.b	(a1),d0			;行頭の文字
		cmpi.b	#'!',d0
		beq	@f
		cmpi.b	#'>',d0
		bne	ext_help_decode_loop2
@@:
		addq.l	#1,a1			;'!' と '>' は飛ばす
ext_help_decode_loop2:
		cmpi.b	#'^',d0
		seq	d6
ext_help_decode_loop:
		move.b	(a1)+,d0
		move.b	d0,(a0)+
		cmp.b	d1,d0
		bcc	ext_help_decode_loop	;普通の文字
		cmpi.b	#LF,d0
		beq	ext_help_decode_lf
		cmpi.b	#EOF,d0
		beq	ext_help_decode_eof
		cmpi.b	#CR,d0
		bne	ext_help_decode_loop	;他の制御記号
*ext_help_decode_cr:
		subq.l	#1,a0			;CR は無視する
		bra	ext_help_decode_loop
ext_help_decode_eof:
		subq.l	#1,a1			;行末処理をして終了
ext_help_decode_lf:
		clr.b	(-1,a0)
		addq	#1,d7
		cmpi	#$ffff,d7
		beq	ext_help_decode_end

		tst.b	d6
		beq	@f
		cmpi.b	#'^',(a1)
		beq	ext_help_decode_loop	;ファイル内容判別の複数定義
		cmpi.b	#'.',(a1)
		beq	ext_help_decode_loop2	;最初の拡張子判別
		cmpi.b	#'!',(a1)+
		beq	ext_help_decode_loop2	;最初のファイル名判別
		subq.l	#1,a1
@@:
		cmpi.b	#TAB,(a1)
		beq	ext_help_decode_loop2
		cmp.b	(a1),d1
		beq	ext_help_decode_loop2
ext_help_decode_end:
		lea	(subwin_ext_help,pc),a0
		move.l	a3,(SUBWIN_TITLE,a0)

		moveq	#MAX_LINE,d0
		cmp	d7,d0
		bls	@f
		move	d7,d0
@@:		move	d0,(SUBWIN_YSIZE,a0)

		moveq	#32,d1
		sub	d0,d1
		lsr	#2,d1
		addq	#1,d1
		move	d1,(SUBWIN_Y,a0)

		move.l	d3,d0			;-l<n>
		move.l	d7,d1			;行数
		lea	(ext_help_getstr,pc),a1
		bsr	help_menu
		move.l	d0,d7
		beq	ext_help_end

		lea	(a4),a1
		moveq	#LF,d1
		subq	#1,d0
		bra	1f
@@:
		cmp.b	(a1)+,d1		;目的の行まで進める
		bne	@b
1:		dbra	d0,@b
		jsr	(skip_define_word)
		tst.l	d7
		bmi	ext_help_edit

		moveq	#%0000_0010,d0
		jmp	(execute_quick)
ext_help_edit:
		bsr	set_minthline
		move	#KQ_HELP_E<<8,d0
		jsr	(free_token_buf)
		jmp	(execute_quick_no)
ext_help_end:
		rts


* 選択肢文字列収得ルーチン -------------------- *
* in	d0.w	行番号(1～)
* out	d0.l	文字列のアドレス

ext_help_getstr:
		move.l	a0,-(sp)
		lea	(Buffer),a0
		subq	#1,d0
		bra	1f
@@:
		tst.b	(a0)+
		bne	@b
1:		dbra	d0,@b
		move.l	a0,d0
		movea.l	(sp)+,a0
		rts


* $MINTHLINE 設定 ----------------------------- *

* in	a1.l	定義ファイル上のアドレス

set_minthline:
		PUSH	d0/a0-a2
		moveq	#0,d0
		cmpa.l	#key_quick_esc_default,a1
		beq	set_minthline_esc

		movea.l	(mintrc_buf_adr),a0
@@:
		cmpi.b	#LF,(a0)+		;a1 が定義ファイルの何行目にあるか調べる
		bne	@b
		addq.l	#1,d0
		cmpa.l	a0,a1
		bcc	@b
set_minthline_esc:
		lea	(-16,sp),sp
		lea	(sp),a0
		FPACK	__LTOS			;行数を文字列化
		lea	(str_minthline,pc),a1
		lea	(sp),a2
		jsr	(set_user_value_a1_a2)
		lea	(16,sp),sp

		POP	d0/a0-a2
		rts


*************************************************
*		&describe-key			*
*************************************************

＆describe_key::
		moveq	#MES_DESCT,d0
		bsr	help_menu_getarg0
		GETMES	MES_DESCP
		movea.l	d0,a1

		lea	(subwin_desc_key,pc),a0
		move.l	a3,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)
		jsr	(WinPrint)

		move	d0,d1
		bsr	desc_key_input
		exg	d0,d1
		jsr	(WinClose)

		move.l	d1,d0			;d0 = キー番号
desc_key_sub:
		lsl	#2,d0
		beq	desc_key_end

		lea	(kq_buffer),a0
		move.l	(a0,d0.w),d0
		beq	desc_key_end

		movea.l	d0,a1
		moveq	#'>',d0
@@:		cmp.b	-(a1),d0
		bne	@b
		bra	ext_help_found
**		rts


* キー入力
desc_key_input_loop:
		DOS	_CHANGE_PR
		jsr	(update_periodic_display)
desc_key_input:
		jsr	(iocs_b_keyinp_ex)
		beq	desc_key_input_loop
desc_key_end:
		rts


* OPT.1/2 による &describe-key 起動 ----------- *

describe_key_opt::
		PUSH	d0-d7/a0-a5
		IOCS	_B_SFTSNS
		cmpi	#1,(＄opt！)
		bcs	describe_key_opt_end
		beq	@f
		not.b	d0
@@:		andi.b	#%1100,d0
		cmpi.b	#%0100,d0
		bne	describe_key_opt_end

		jsr	(iocs_key_flush)
		GETMES	MES_DESCT
		movea.l	d0,a3
		moveq	#0,d3
		bsr	desc_key_input
		bsr	desc_key_sub
describe_key_opt_end:
		POP	d0-d7/a0-a5
		rts


* 引数解析/タイトル収得 ----------------------- *

* in	d0.b	標準タイトルのメッセージ番号
*	d3.l	初期カーソル位置(0～)
*	d7.l	引数の数
*	a0.l	引数列のアドレス
* out	d3.l	初期カーソル位置(0～)
*	a3.l	タイトル文字列
* break	d0/d7/a0

help_menu_getarg0:
		moveq	#0,d3
help_menu_getarg::
		jsr	(get_message)
		movea.l	d0,a3
		bra	get_arg_next
get_arg_loop:
		move.b	(a0)+,d0
		beq	get_arg_next
		cmpi.b	#'-',d0
		bne	get_arg_skip
		move.b	(a0)+,d0
		beq	get_arg_next
		cmpi.b	#'t',d0
		beq	get_arg_opt_t
		cmpi.b	#'l',d0
		bne	get_arg_skip
*get_arg_opt_l:
		jsr	(atoi_a0)		;-l<n> : 初期カーソル行
		bne	get_arg_skip
		tst.b	(a0)+
		bne	get_arg_skip

		move.l	d0,d3
		bra	get_arg_next
get_arg_opt_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	get_arg_end
@@:
		lea	(-1,a0),a3
get_arg_skip:
		tst.b	(a0)+
		bne	get_arg_skip
get_arg_next:
		subq.l	#1,d7
		bcc	get_arg_loop
get_arg_end:
		rts


* ヘルプ用メニュー ---------------------------- *

* in	d0.w	初期カーソル位置(0～)
*	d1.w	行数(1～)
*	a0.l	SUBWIN 構造体
*	a1.l	選択肢文字列収得ルーチンのアドレス
* out	d0.hw	$0000:確定終了 $ffff:'E'/'V'
*	d0.lw	選択した行番号(1～入力の d1.l)
*		d0.l = 0 ならキャンセル
*	ccr	<tst.l d0> の結果

~y_size:	.reg	d3
~page_top:	.reg	d4
~line_num:	.reg	d5
~csr_y:		.reg	d6
~win_no:	.reg	d7

help_menu::
		PUSH	d1-d7/a0-a5
		move	d0,~csr_y
		move	d1,~line_num
		move	(SUBWIN_YSIZE,a0),~y_size
		lea	(a1),a2

		jsr	(WinOpen)
		move	d0,~win_no

		cmp	~line_num,~csr_y
		bls	@f
		move	~line_num,~csr_y	;初期カーソル位置を補正する
@@:
		moveq	#0,~page_top		;表示先頭行
		move	~csr_y,d0
		sub	~y_size,d0
		bls	@f
		add	d0,~page_top		;予めスクロールしておく
@@:
		lea	(txfill_buf,pc),a1	;ウィンドウ消去用のパラメータを計算
		move	(SUBWIN_Y,a0),d0
		addq	#1,d0
		lsl	#4,d0
		move	d0,(TXBOX_YSTART,a1)
		move	~y_size,d0
		lsl	#4,d0
		move	d0,(TXBOX_YLEN,a1)
		bra	@f
help_menu_loop2:
		IOCS	_TXFILL			;ウィンドウ再描画
@@:		bsr	help_menu_print
help_menu_loop:
		moveq	#0,d1			;X
		move	~csr_y,d2		;Y
		move	~win_no,d0
		jsr	(WinSetCursor)

		bsr	help_menu_currev
		jsr	(dos_inpout)
		move	d0,-(sp)
		bsr	help_menu_currev
		move	(sp)+,d0

		move.l	~page_top,d1
		add	~csr_y,d1		;カーソル行番号(0,1～)
		cmpi.b	#CR,d0
		beq	help_menu_end		;確定終了

		not.l	d1			;上位ワード = $ffff
		not	d1
		bne	@f
		addq	#1,d1
@@:		moveq	#$20,d2
		or.b	d0,d2
		cmpi.b	#'e',d2
		beq	@f
		cmpi.b	#'v',d2
@@:		beq	help_menu_end		;定義ファイル編集

**		moveq	#0,d2
		move.b	d0,d2
		subi.b	#'0',d2
		bls	@f
		cmpi.b	#9,d2
		bhi	@f
		moveq	#0,d1
		cmp	~y_size,d2
		bhi	help_menu_end

		move	~page_top,d1		;行番号入力
		add	d2,d1
		bra	help_menu_end
@@:
		cmp.b	(AK_ROLLUP),d0
		bne	@f

		cmp	~y_size,~csr_y
		beq	1f
		move	~y_size,~csr_y		;ROLLUP = 最下行へ移動
		bra	help_menu_loop
1:
		move	~line_num,d1
		sub	~y_size,d1		;~page_top 最大値
		sub	~page_top,d1
		beq	help_menu_loop		;既に最下行
		cmp	~y_size,d1
		bls	1f
		move	~y_size,d1
1:
		add	d1,~page_top		;次頁
		bra	help_menu_loop2
@@:
		cmp.b	(AK_ROLLDOWN),d0
		bne	@f

		cmpi	#1,~csr_y
		beq	1f
		moveq	#1,~csr_y		;ROLLDOWN = 最上行へ移動
		bra	help_menu_loop
1:
		tst	~page_top
		beq	help_menu_loop		;既に最上行
		move	~page_top,d1
		cmp	~y_size,d1
		bls	1f
		move	~y_size,d1
1:
		sub	d1,~page_top		;前頁
		bra	help_menu_loop2
@@:
		cmp.b	(AK_UP),d0
		bne	@f

		subq	#1,~csr_y		;↑ = 一行上へ移動
		bhi	help_menu_loop

		cmp	~y_size,~line_num
		bhi	1f
		move	~y_size,~csr_y		;最下行へ移動(一画面)
		bra	help_menu_loop
1:
		tst	~page_top
		beq	1f
		addq	#1,~csr_y		;スクロール
		subq	#1,~page_top
		bra	help_menu_loop2
1:
		move	~y_size,~csr_y		;最下行へ移動(多画面)
		move	~line_num,~page_top
		sub	~csr_y,~page_top
		bra	help_menu_loop2
@@:
		cmp.b	(AK_DOWN),d0
		bne	@f

		addq	#1,~csr_y		;↓ = 一行下へ移動
		cmp	~y_size,~csr_y
		bls	help_menu_loop

		cmp	~y_size,~line_num
		bhi	1f
		moveq	#1,~csr_y		;最上行へ移動(一画面)
		bra	help_menu_loop
1:
		move	~line_num,d1
		sub	~y_size,d1
		cmp	d1,~page_top
		bcc	1f
		subq	#1,~csr_y		;スクロール
		addq	#1,~page_top
		bra	help_menu_loop2
1:
		moveq	#0,~page_top		;最上行へ移動(多画面)
		moveq	#1,~csr_y
		bra	help_menu_loop2
@@:
		moveq	#0,d1
help_menu_end:
		move	~win_no,d0
		jsr	(WinClose)

		move.l	d1,d0
		POP	d1-d7/a0-a5
		rts


* カーソル反転
help_menu_currev:
		tst	~csr_y
		beq.s	help_menu_currev_end
		move	~win_no,d0
		move	(＄cusr),d1
		beq	@f
		jmp	(WinUnderLine)		;%cusr 1～3 なら下線
@@:		jmp	(WinReverseLine)	;%cusr 0 なら反転
**		rts
help_menu_currev_end:
		rts


* １ページ表示
help_menu_print:
		PUSH	d0-d3/a1/a4
		move	~win_no,d0
		jsr	(WinGetPtr)
		movea.l	d0,a4
		subq	#1,(WIND_XSIZE,a4)

		moveq	#1,d1			;X
		moveq	#1,d2			;Y
		subq	#1,~y_size
help_menu_print_loop:
		move	~page_top,d0
		add	d2,d0
		jsr	(a2)
		movea.l	d0,a1
		move	~win_no,d0
		jsr	(WinSetCursor)
		jsr	(WinPrint)

		addq	#1,d2			;Y++
		dbra	~y_size,help_menu_print_loop

		addq	#1,(WIND_XSIZE,a4)	
		POP	d0-d3/a1/a4
		rts


* Data Section -------------------------------- *

**		.data
**		.even

subwin_ext_help:
		SUBWIN	8,6,80,0,NULL,NULL
subwin_desc_key:
		SUBWIN	32,9,30,1,NULL,NULL

txfill_buf:	.dc	$8003,(8+1)*8,0,(80-2)*8,0,0

str_minthline:	.dc.b	'MINTHLINE',0


		.end

* End of File --------------------------------- *
