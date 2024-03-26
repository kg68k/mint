# menu.s - &menu
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

		.include	mrl.mac
		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	sysval.def


* Global Symbol ------------------------------- *

* madoka3.s
		.xref	＠buildin,＠status
		.xref	execute_quick,free_token_buf
		.xref	expand_token
* mint.s
		.xref	fullpath_a1,chdir_a1
		.xref	next_line_a1
		.xref	skip_blank_a1
		.xref	at_jump,at_exec
		.xref	AK_ROLLUP,AK_ROLLDOWN,AK_UP,AK_DOWN,AK_RIGHT,AK_LEFT
* outside.s
		.xref	atoi_a0
		.xref	print_sub
		.xref	dos_inpout
		.xref	set_user_value_arg_a2


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


*************************************************
*	&chdir-to-registered-path-menu		*
*************************************************

＆chdir_to_registered_path_menu::
		move	#MES2_JUMP1,d0
		moveq	#MES_IJUMP,d1
		bsr	path_menu
		beq	chdir_menu_end
		movea.l	d0,a1
		move.l	d1,d0
		bne	chdir_menu_s

		jsr	(fullpath_a1)
		bmi	chdir_menu_end		;d0=0
		jsr	(chdir_a1)
		bra	chdir_menu_end
chdir_menu_s:
		lea	(a1),a2			;-s 指定時は $_ に設定する
		jsr	(set_user_value_arg_a2)
chdir_menu_end:
		bra	set_status
**		rts


* 登録パスメニュー選択 ------------------------ *

* in	d0.b	MES_{JUMP1,CPMV1}
*	d1.b	MES_{IJUMP,ICOPY,IMOVE}
*	d7.l	引数の数
*	a0.l	引数列のアドレス
* out	d0.l	選択したパス名のアドレス(0 ならキャンセル)
*	d1.l	通常は 0、-s オプション指定時は 1 になる.
*	ccr	<tst.l d0> の結果
* 備考:
*	reg_menu を呼び出して、マクロと環境変数を展開する.
*	文字列が '!' だった場合は行入力でパス名を入力する.
*	Buffer を使用する.

path_menu::
		PUSH	d2-d7/a0-a5
		move.b	d1,d5			;input_path 用に保存
		move.l	d7,d6
		lea	(a0),a5

		lea	(at_jump),a1
		bsr	reg_menu
		beq	path_menu_end

		movea.l	d0,a1
		jsr	(expand_token)
		movea.l	d0,a1
		cmpi	#'!'<<8,(a1)
		bne	path_menu_end

		move.b	d5,d0			;! なら行入力
		move.l	d6,d7
		lea	(a5),a0
		bsr	input_path
path_menu_end:
		POP	d2-d7/a0-a5
		tst.l	d0
		rts


* パス名の行入力 ------------------------------ *

* in	d0.b	MES_{IJUMP,ICOPY,IMOVE}
*	d7.l	引数の数
*	a0.l	引数列のアドレス
* out	d0.l	文字列のアドレス(Buffer)
*		キャンセル時は 0 が返る.
*	ccr	<tst.l d0> の結果

input_path::
		PUSH	d1-d7/a0-a5
		jsr	(get_message)
		movea.l	d0,a1
		bra	input_path_arg_next
input_path_arg_loop:
		move.b	(a0)+,d0
		beq	input_path_arg_next
		cmpi.b	#'-',d0
		bne	input_path_arg_skip
		cmpi.b	#'t',(a0)
		bne	input_path_arg_skip
*input_path_opt_t:
		addq.l	#1,a0			;-t"タイトル"
@@:		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	input_path_arg_end	;引数がない
@@:
		lea	(-1,a0),a1
input_path_arg_skip:
		tst.b	(a0)+
		bne	input_path_arg_skip
input_path_arg_next:
		subq.l	#1,d7
		bcc	input_path_arg_loop
input_path_arg_end:
		lea	(subwin_input_path,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		move.l	d0,d7

		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

		lea	(Buffer),a1
		clr.b	(a1)
		move.l	d7,d0
		move.l	#64<<16+RL_F_DIR,d1
		jsr	(MintReadLine)

		exg	d0,d7
		jsr	(WinClose)

		moveq	#0,d0
		tst.l	d7
		bmi	input_path_end		;キャンセル
		move.l	a1,d0
input_path_end:
		POP	d1-d7/a0-a5
		tst.l	d0
		rts


subwin_input_path:
		SUBWIN	14,8,66,1,NULL,NULL


*************************************************
*	&exec-registered-command-menu		*
*************************************************

＆exec_registered_command_menu::
		move	#MES2_EXEC1,d0
		lea	(at_exec),a1
		bsr	reg_menu
		beq	@f
		movea.l	d0,a1
		moveq	#%0000_0000,d0
		jsr	(free_token_buf)
		jmp	(execute_quick)
@@:
		rts


* 登録メニュー選択 ---------------------------- *

* in	d0.w	MES2_{EXEC1,JUMP1,CPMV1}
*	d7.l	引数の数
*	a0.l	引数列のアドレス
*	a1.l	at_{exec,jump}
* out	d0.l	選択したコマンドのアドレス(0 ならキャンセル)
*	d1.l	通常は 0、-s オプション指定時は 1 になる.
*	ccr	<tst.l d0> の結果
* 備考:
*	Buffer を使用する.

reg_menu:
		PUSH	d2-d7/a0-a5
		moveq	#0,d1			;-s
		moveq	#0,d4			;<n> (0～15)
		moveq	#1,d5			;-l<n>
		move	d0,d6			;タイトルのメッセージ番号
		suba.l	a3,a3			;-t"title"
		lea	(a1),a5			;at_xxx
		bra	reg_menu_arg_next
reg_menu_arg_loop:
		move.b	(a0)+,d0
		beq	reg_menu_arg_next
		cmpi.b	#'-',d0
		beq	reg_menu_arg_option

		subq.l	#1,a0			;<n> : メニュー番号
		jsr	(atoi_a0)
		bne	reg_menu_arg_skip
		tst.b	(a0)+
		bne	reg_menu_arg_skip

		subq.l	#1,d0			;0～15
		moveq	#REG_WIN_NUM-1,d2
		cmp.l	d2,d0
		bhi	reg_menu_arg_next	;番号が大きすぎる

		move.l	d0,d4
		bra	reg_menu_arg_next
reg_menu_arg_option:
		move.b	(a0)+,d0
		beq	reg_menu_arg_next
		cmpi.b	#'l',d0
		beq	reg_menu_opt_l
		cmpi.b	#'t',d0
		beq	reg_menu_opt_t
		cmpi.b	#'s',d0
		bne	reg_menu_arg_skip
*reg_menu_opt_s:
		tst.b	(a0)+
		bne	reg_menu_arg_skip
		moveq	#1,d1			;-s : 選択のみ
		bra	reg_menu_arg_next
reg_menu_opt_l:
		jsr	(atoi_a0)		;-l<n> : 初期カーソル行
		bne	reg_menu_arg_skip
		tst.b	(a0)+
		bne	reg_menu_arg_skip

		move.l	d0,d5
		bra	reg_menu_arg_next
reg_menu_opt_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	reg_menu_arg_end	;引数がない
@@:
		lea	(-1,a0),a3
reg_menu_arg_skip:
		tst.b	(a0)+
		bne	reg_menu_arg_skip
reg_menu_arg_next:
		subq.l	#1,d7
		bcc	reg_menu_arg_loop
reg_menu_arg_end:
		moveq	#sizeof_AT_DEF,d0
		mulu	d4,d0
		lea	(a5,d0.l),a1
		bsr	decode_reg_menu
		beq	reg_menu_end		;メニュー未登録
reg_menu_loop:
		lea	(subwin_reg_menu,pc),a0
		move	d0,(SUBWIN_YSIZE,a0)

		move.l	a3,d0
		bne	@f
		move.l	d4,d0			;デフォルトタイトルを使用
		add	d6,d0
		jsr	(get_message2)
@@:		move.l	d0,(SUBWIN_TITLE,a0)

		move	(＄regw),d0
		move	d0,(SUBWIN_XSIZE,a0)
		move	(＄wino),d2
		bpl	@f			;特定の座標が指定された

		moveq	#96-4,d2		;番号が大きい程左側に表示する
		sub	d0,d2
		moveq	#REG_WIN_NUM-1,d3
		sub	d4,d3
		mulu	d3,d2
		divu	#REG_WIN_NUM-1,d2	;d2 = ((15-no)*(92-%regw))/15
		addq	#2,d2
@@:
		andi	#$fffe,d2
		move	d2,(SUBWIN_X,a0)

		move.l	d5,d0			;初期カーソル位置
		bsr	menu_sub2
		beq	reg_menu_end
		bgt	reg_menu_decide		;確定

		moveq	#1,d2			;← : 次のメニュー
		addq.l	#1,d0
		beq	@f
		moveq	#-1,d2			;→ : 前のメニュー
@@:
		moveq	#0,d0
		tst	(＄winn)
		bne	reg_menu_end		;左右ページングはしない
reg_menu_lr_loop:
		add	d2,d4			;次or前のメニューに移動
		andi	#REG_WIN_NUM-1,d4
		.fail	(REG_WIN_NUM-1).and.REG_WIN_NUM

		moveq	#sizeof_AT_DEF,d0
		mulu	d4,d0
		lea	(a5,d0.l),a1
		bsr	decode_reg_menu
		beq	reg_menu_lr_loop	;未登録なら更に次or前に移動する

		moveq	#1,d5			;初期カーソル位置を戻す
		bra	reg_menu_loop
reg_menu_decide:
		lsl	#2,d0			;コマンド文字列のアドレスを返す
		move.l	(-4,a2,d0.w),d0
reg_menu_end:
		POP	d2-d7/a0-a5
		tst.l	d0
		rts


subwin_reg_menu:
		SUBWIN	0,2,0,0,NULL,NULL


*************************************************
*		&menu				*
*************************************************

* Buffer:
* subwin_menu:
*		SUBWIN	-1,-1,0,0,NULL,MES_MENUT
* menu_list:
*		.dc.l	line1	->	line1: .dc.b 'A','aaa',0
*		.dc.l	line2	->	line2: .dc.b 'B','bbb',0
*		...


＆menu::
		lea	(Buffer),a5

		lea	(a5),a4
		move	#-1,(a4)+		;SUBWIN_X
		move	#8,(a4)+		;SUBWIN_Y
		clr.l	(a4)+			;SUBWIN_{X,Y}SIZE
		clr.l	(a4)+			;SUBWIN_MES
		GETMES	MES_MENUT
		move.l	d0,(a4)+		;SUBWIN_TITLE

		moveq	#1,d6			;-l<n>
		bra	menu_arg_next
menu_arg_loop:
		move.b	(a0)+,d0
		beq	menu_arg_next
		cmpi.b	#'-',d0
		bne	menu_list
		move.b	(a0)+,d0
		beq	menu_arg_next
		cmpi.b	#'l',d0
		beq	menu_option_l
		cmpi.b	#'x',d0
		beq	menu_option_x
		cmpi.b	#'y',d0
		beq	menu_option_y
		cmpi.b	#'t',d0
		bne	menu_syntax_error
*menu_option_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	menu_syntax_error	;引数がない
@@:
		subq.l	#1,a0
		move.l	a0,(SUBWIN_TITLE,a5)
		bsr	menu_del_comma
		bra	menu_arg_next

* 引数文字列末尾の ',' を取り除く
* in	a0.l	引数のアドレス
* out	a0.l	次の引数のアドレス

menu_del_comma:
@@:		tst.b	(a0)+
		bne	@b
		cmpi.b	#',',(-2,a0)
		bne	@f
		clr.b	(-2,a0)			;末尾が ',' なら取り除く
@@:		rts


call_atoi_a0:
		jmp	(atoi_a0)
**		rts

menu_option_l:
		bsr	call_atoi_a0		;-l<n> : 初期カーソル行
		move	d0,d6
		bra	menu_arg_skip
menu_option_x:
		lea	(SUBWIN_X,a5),a2	;-x<n> : X 座標
		bra	@f
menu_option_y:
		lea	(SUBWIN_Y,a5),a2	;-y<n> : Y 座標
@@:
		bsr	call_atoi_a0
		move	d0,(a2)

menu_arg_skip:
		tst.b	(a0)+
		bne	menu_arg_skip
menu_arg_next:
		subq.l	#1,d7
		bcc	menu_arg_loop

menu_syntax_error:
		moveq	#MES_MENU1,d0		;文法違反
menu_error:
		jsr	(get_message)
		movea.l	d0,a0			;本文
		moveq	#1,d7			;行数
		moveq	#0,d6			;待機時間無制限
		suba.l	a1,a1
		moveq	#MES_MENUE,d0		;タイトル
		jsr	(print_sub)
		moveq	#0,d0
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts

menu_list:
		subq.l	#1,a0

		movea.l	(SUBWIN_TITLE,a5),a1
		STRLEN	a1,d2,+6		;タイトルに必要な横幅

		move	(SUBWIN_YSIZE,a5),d3
		moveq	#MES_MENU2,d0
menu_list_loop:
		addq	#1,d3
		cmpi	#MENU_MAX,d3
		bhi	menu_error		;項目数が多すぎる

		lea	(a0),a1
		move.l	a0,(a4)+
		bsr	menu_del_comma
		STRLEN	a1,d1,+4+2		;+2 は隙間用
		cmp.l	d1,d2
		bcc	@f
		move.l	d1,d2			;横幅を更新
@@:
		subq.l	#1,d7
		bcc	menu_list_loop
*menu_list_end:
		addq	#1,d2
		andi	#$fffe,d2
		moveq	#96,d1
		cmp.l	d1,d2
		bls	@f
		move.l	d1,d2			;念の為上限チェック
@@:
		move	d2,(SUBWIN_XSIZE,a5)
		move	d3,(SUBWIN_YSIZE,a5)

		move	(SUBWIN_X,a5),d0
		bpl	@f

		moveq	#96,d0			;-x 無指定時
		sub	d2,d0
		lsr	#2,d0
		add	d0,d0			;X 座標センタリング
@@:
		add	d0,d2			;d2 = X+XSIZE
		cmp	d1,d2
		bls	@f
		moveq	#96,d0
		sub	(SUBWIN_XSIZE,a5),d0	;X 座標補正
@@:
		move	d0,(SUBWIN_X,a5)

		moveq	#32-2,d1
		add	(SUBWIN_Y,a5),d3
		cmp	d1,d3
		bls	@f

		sub	(SUBWIN_YSIZE,a5),d1
		move	d1,(SUBWIN_Y,a5)	;Y 座標補正
@@:
		lea	(a5),a0
		lea	(sizeof_SUBWIN,a5),a1
		move.l	d6,d0
		bsr	menu_sub
		bra	set_status


* メニュー選択 -------------------------------- *

* in	d0.w	初期カーソル位置(1～SUBWIN_YSIZE)
*	a0.l	SUBWIN 構造体
*	a1.l	選択肢リストのアドレス
*	a2.l	拡張処理アドレス(menu_sub_ex のみ)
* out	d0.hw	選択したショートカットキー
*	d0.lw	選択した行番号(1～SUBWIN_YSIZE)
*		d0.l = 0 ならキャンセル
*	| menu_sub2 の時、AK_LEFT で d0.l = -1、
*	| AK_RIGHT で d0.l = -2 を返す.
*	ccr	<tst.l d0> の結果
* 備考:
*	menu_sub_ex ではメニュー描画後(キー入力前)に
*	a2.l で指定したサブルーチンを呼び出す.
*	in	d6.w	初期カーソル位置
*		d7.w	ウィンドウ番号
*		(4,sp)	ショートカットキーリストのアドレス
*	menu_sub2 では←(AK_LEFT)、→(AK_RIGHT)を特別扱いし、
*	それらが入力された場合は d0.l にそれぞれ -1、-2 を返す.

~list_size:	.equ	MENU_MAX+2
		.fail	~list_size.and.1

menu_sub_ex::
		PUSH	d1-d7/a0-a5
		move.l	a2,d4			;拡張処理アドレス
		bra	@f
menu_sub2::
		PUSH	d1-d7/a0-a5
		moveq	#-1,d4			;←→処理あり
		bra	@f
menu_sub::
		PUSH	d1-d7/a0-a5
		moveq	#0,d4			;拡張処理なし
@@:
		lea	(-~list_size,sp),sp
		lea	(sp),a5			;ショートカットキーリスト
		clr.b	(a5)+

		lea	(a1),a2
		move	d0,d6

		jsr	(WinOpen)
		move	d0,d7

		lea	(WinPutChar),a3
		lea	(WinSetColor),a4
		move	(SUBWIN_YSIZE,a0),d5
		subq	#1,d5
		moveq	#1,d2			;Y
menu_sub_print_loop:
		moveq	#1,d1			;X
		bsr	call_locate
		moveq	#YELLOW,d1
		jsr	(a4)

		movea.l	(a2)+,a1		;選択肢
**		moveq	#0,d1
		move.b	(a1)+,d1		;ショートカットキー
		move.b	d1,(a5)+
		jsr	(a3)

		moveq	#4,d1			;空白二個分
		bsr	call_locate
		moveq	#WHITE,d1
		jsr	(a4)
		jsr	(WinPrint)

		addq	#1,d2			;Y++
		dbra	d5,menu_sub_print_loop

		tst.l	d4
		ble	@f			;拡張処理なし
		movea.l	d4,a1
		jsr	(a1)			;拡張処理を呼び出す
@@:
		move	d7,d0
		move	d6,d1
		move	(SUBWIN_YSIZE,a0),d2
		bsr	menu_select

		exg	d0,d7
		jsr	(WinClose)
		exg	d0,d7

		cmpi.b	#CR,d0
		beq	menu_sub_cr		;確定
		cmpi.b	#$20,d0
		bcc	@f

		tst.l	d4
		bpl	menu_sub_cancel
		move.b	d0,d1			;menu_sub2 の←→処理
		moveq	#-1,d0
		cmp.b	(AK_LEFT),d1
		beq	menu_sub_end
		moveq	#-2,d0
		cmp.b	(AK_RIGHT),d1
		beq	menu_sub_end
		bra	menu_sub_cancel
@@:
		moveq	#0,d1
		move	(SUBWIN_YSIZE,a0),d5
		subq	#1,d5
menu_sub_check_loop:
		addq	#1,d1			;入力されたキーがショートカットキー
		move.b	(sp,d1.w),d2		;であるかどうか調べる
		cmpi.b	#'a',d2
		bcs	@f
		cmpi.b	#'z',d2
		bhi	@f
		andi.b	#$df,d2			;大文字化
@@:
		cmp.b	d0,d2
		dbeq	d5,menu_sub_check_loop
		beq	menu_sub_check_ok	;ショートカットキーにあった
menu_sub_cancel:
		moveq	#0,d0			;キャンセル
		bra	menu_sub_end
menu_sub_cr:
		moveq	#0,d0
		move.b	(sp,d1.w),d0		;ショートカットキー
menu_sub_check_ok:
		swap	d0
		move	d1,d0			;行番号
menu_sub_end:
		lea	(~list_size,sp),sp
		POP	d1-d7/a0-a5
		tst.l	d0
		rts


call_locate:
		jmp	(WinSetCursor)
**		rts


* メニュー選択下請け -------------------------- *
* in	d0.w	ウィンドウ番号
*	d1.w	初期カーソル位置(0～)
*	d2.w	行数(1～)
* out	d0.w	終了キー(アルファベットは大文字に変換される)
*	d1.w	行番号(1～; 終了キーが CR 以外の場合は無意味)
* 備考:
*	メニューは予め表示しておくこと.
*	d1.w に 0 を渡した場合カーソルは描画されず、↑、↓、
*	ROLLUP、ROLLDOWN を押すと初めて描画される.

menu_select::
		PUSH	d2/d5-d7
		move	d0,d7
		move	d1,d6
		move	d2,d5

		cmp	d5,d6
		bls	@f
		move	d5,d6			;初期カーソル位置を補正する
@@:
menu_select_loop:
		moveq	#0,d1			;X
		move	d6,d2			;Y
		move	d7,d0
		bsr	call_locate

		bsr	menu_select_currev

		jsr	(dos_inpout)
		cmpi.b	#$20,d0
		bcc	menu_select_char	;普通のキー

		cmpi.b	#CR,d0
		bne	@f
		tst	d6
		bne	1f
		moveq	#ESC,d0			;-l0 でそのまま確定はキャンセルと見なす
1:		bra	menu_select_end
@@:
		cmp.b	(AK_ROLLUP),d0
		bne	@f

		bsr	menu_select_currev
		move	d5,d6			;ROLLUP = 最下行へ移動
		bra	menu_select_loop
@@:
		cmp.b	(AK_ROLLDOWN),d0
		bne	@f

		bsr	menu_select_currev
		moveq	#1,d6			;ROLLDOWN = 最上行へ移動
		bra	menu_select_loop
@@:
		cmp.b	(AK_UP),d0
		bne	@f

		bsr	menu_select_currev
		subq	#1,d6			;↑ = 一行上へ移動
		bhi	1f
		move	d5,d6
1:		bra	menu_select_loop
@@:
		cmp.b	(AK_DOWN),d0
		bne	@f

		bsr	menu_select_currev
		addq	#1,d6			;↓ = 一行下へ移動
		cmp	d5,d6
		bls	1f
		moveq	#1,d6
1:		bra	menu_select_loop
@@:
		bra	menu_select_end

menu_select_char:
		cmpi.b	#'a',d0
		bcs	menu_select_end
		cmpi.b	#'z',d0
		bhi	menu_select_end
		andi.b	#$df,d0			;大文字化
menu_select_end:
		move	d6,d1
		POP	d2/d5-d7
menu_select_currenv_end:
		rts


menu_select_currev:
		tst	d6
		beq.s	menu_select_currenv_end
		move	d7,d0
menu_select_curclr::
		move	(＄cusr),d1
		beq	@f
		jmp	(WinUnderLine)		;%cusr 1～3 なら下線
@@:		jmp	(WinReverseLine)	;%cusr 0 なら反転
**		rts


* 登録メニュー展開 ---------------------------- *

* A "aaa" -api xxx
*	  -api yyy
* B "bbb"
*	  -api zzz
*
* といった形式の登録メニューを
*
* Buffer:
* menu_list:
*		.dc.l	line1	->	line1: .dc.b 'A','aaa',0
*		.dc.l	line2	->	line2: .dc.b 'B','bbb',0
*		...
* cmd_list:
*		.dc.l	「-api xxx」のアドレス(定義ファイル内)
*		.dc.l	「-api zzz」〃
*		...
*
* というように扱いやすい形式に変換する.

* in	a1.l	登録メニュー情報のアドレス(at_xxxx)
* out	d0.l	選択肢の数(0 ならエラー)
*	a1.l	選択肢リストのアドレス(menu_list)
*	a2.l	コマンドリストのアドレス(cmd_list)
*	ccr	<tst.l d0> の結果
* 備考:
*	Buffer を使用する.

decode_reg_menu::
		PUSH	d1/d5-d7/a0/a3-a5
		moveq	#0,d7
		move	(AT_DEF_NUM,a1),d7	;行数
		beq	dec_reg_menu_end	;メニュー定義が不正

		movea.l	(AT_DEF_PTR,a1),a1	;定義アドレス

		lea	(next_line_a1),a4
		lea	(Buffer),a5
		lea	(a5),a2			;選択肢/コマンドリスト
		lea	(MENU_MAX*4*2,a2),a3	;展開バッファ

		moveq	#$20,d5
		move	d7,d6
		subq	#1,d6
dec_reg_menu_loop:
		cmpi.b	#$20,(a1)
		bhi	@f			;選択肢あり

		jsr	(a4)			;先頭が空白なら無視する
		bra	dec_reg_menu_loop
@@:
		move.l	a3,(a2)+		;選択肢リストに登録

		move.b	(a1)+,(a3)+		;ショートカットキー
		bsr	call_skip_blank_a1
dec_reg_menu_loop2:
		move.b	(a1)+,d1		;"～" 展開
		cmp.b	d5,d1
		bls	dec_reg_menu_eol
		cmpi.b	#'"',d1
		beq	dec_reg_menu_quote
		cmpi.b	#"'",d1
		beq	dec_reg_menu_quote
		move.b	d1,(a3)+
		bra	dec_reg_menu_loop2
dec_reg_menu_quote:
		move.b	(a1)+,d0
		move.b	d0,(a3)+
		cmp.b	d1,d0
		bne	dec_reg_menu_quote
		subq.l	#1,a3
		bra	dec_reg_menu_loop2
dec_reg_menu_eol:
		clr.b	(a3)+

		subq.l	#1,a1
		bsr	seek_to_menu_command
		move.l	a1,(MENU_MAX*4-4,a2)	;コマンドリストに登録
		jsr	(a4)
dec_reg_menu_next:
		dbra	d6,dec_reg_menu_loop

		lea	(a5),a1			;選択肢リスト
		lea	(MENU_MAX*4,a1),a2	;コマンドリスト
dec_reg_menu_end:
		move.l	d7,d0			;行数
		POP	d1/d5-d7/a0/a3-a5
		rts


* メニュー選択肢の直後の改行を飛ばす
* i/o	a1.l	文字列のアドレス
* break	d0-d1

* A "foo"
*	-api foo.x
* B "bar"
*	*.txt

seek_to_menu_command:
		bsr	call_skip_blank_a1
		move.l	a1,d1

		cmpi.b	#CR,(a1)+
		beq	@f
		subq.l	#1,a1
@@:		cmpi.b	#LF,(a1)+
		bne	9f

		move.l	a1,-(sp)
		bsr	call_skip_blank_a1
		cmpa.l	(sp)+,a1
		beq	9f			;行頭が空白ではない

		cmpi.b	#$20,(a1)
		bhi	@f			;有効な文字があれば確定
9:
		movea.l	d1,a1
@@:		rts

call_skip_blank_a1:
		jmp	(skip_blank_a1)
**		rts


* デフォルトメニュー展開 ---------------------- *

*		.dc.b	'A','aaa',0
*		.dc.b	'B','bbb',0
*		...
*		.dc.b	0
*
* という形式のデフォルトメニューから選択肢リストを作る.

* in	a1.l	デフォルトメニューのアドレス
* out	a1.l	選択肢リストのアドレス(menu_list)

make_def_menu_list::
		PUSH	a2/a5
		lea	(Buffer),a5
		lea	(a5),a2
make_def_menu_list_loop:
		move.l	a1,(a2)+		;選択肢リストに登録
@@:
		tst.b	(a1)+
		bne	@b
		tst.b	(a1)
		bne	make_def_menu_list_loop

		lea	(a5),a1			;選択肢リスト
		POP	a2/a5
		rts


* Data Section -------------------------------- *

*		.data
		.even


* Block Storage Section ----------------------- *

*		.bss
		.even


		.end

* End of File --------------------------------- *
