# mrl.s - readline, &input
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

		.include	rl.mac
		.include	mrl.mac
		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* madoka3.s
		.xref	sys_res_val_tbl
* mint.s
		.xref	mint_start
		.xref	set_status
		.xref	update_periodic_display
		.xref	next_line_a1
		.xref	cut_filename_pattern
		.xref	fep_enable,fep_disable
		.xref	MINTSLASH
		.xref	sys_val_name,func_name_list
* music.s
		.xref	print_music_title
* outside.s
		.xref	＆v_bell
		.xref	atoi_a0
		.xref	set_user_value_a1_a2
		.xref	user_value_tbl
* patternmatch.s
		.xref	_fre_compile,_fre_match,_ignore_case


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&input=&readline		*
*************************************************

INPUT_MAX:	.equ	94

＆input::
		lea	(-(INPUT_MAX+2),sp),sp
		lea	(sp),a1			;バッファ
		clr.b	(a1)

		lea	(subwin_input,pc),a5
		GETMES	MES_INPUT
		move.l	d0,(SUBWIN_TITLE,a5)

		moveq	#INPUT_MAX,d4		;残り容量
		moveq	#70,d5			;省略時のウィンドウ幅
		moveq	#-1,d6			;カーソル位置
		lea	(underline,pc),a2	;省略時の変数名
		lea	(a1),a4
		bra	arg_next
arg_loop:
		move.b	(a0)+,d0
		beq	arg_next
		cmpi.b	#'-',d0
		beq	arg_option
		lea	(-1,a0),a2		;変数名
		bra	arg_skip
arg_option:
		move.b	(a0)+,d1
		beq	arg_next
		subi.b	#'s',d1
		beq	option_s
		subq.b	#'t'-'s',d1
		beq	option_t
		subq.b	#'w'-'t',d1
		bne	arg_skip
*option_w:
		jsr	(atoi_a0)		;-w<n> : ウィンドウ幅
		andi	#$fffe,d0
		cmpi	#4,d0
		bcs	arg_skip		;狭すぎる
		cmpi	#INPUT_MAX,d0		;94 以下であること(96 だと画面モード破壊)
		bhi	arg_skip		;広すぎる
		move	d0,d5
		bra	arg_skip
option_t:
		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	option_t
		bra	arg_end
@@:		subq.l	#1,a0
		move.l	a0,(SUBWIN_TITLE,a5)	;-t"タイトル"
		bra	arg_skip
option_s:
		STRLEN	a0,d0			;-s"初期文字列"
		cmp.l	d4,d0
		bhi	arg_next		;長すぎる
		sub.l	d0,d4			;残り容量
		tst.l	d6
		bmi	option_s_1st		;一回目

* 二回目の -s"string" で、初期カーソル位置を
* "string" の左端(一回目の文字列の右端)にする.
		move.l	a4,d6			;STRLEN a1,d6
		sub.l	a1,d6
		bra	@f
option_s_1st:
		move.l	d0,d6
@@:
		STRCPY	a0,a4
		subq.l	#1,a4
		bra	arg_next
arg_skip:
		tst.b	(a0)+
		bne	arg_skip
arg_next:
		subq.l	#1,d7
		bcc	arg_loop
arg_end:
		lea	(a5),a0			;subwin_input
		move	d5,(SUBWIN_XSIZE,a0)
		addq	#2,(SUBWIN_XSIZE,a0)
		moveq	#96-2,d0
		sub	d5,d0
		lsr	#2,d0
		add	d0,d0
		move	(＄kz_x),d1
		bmi	@f			;中央寄せ
		moveq	#96-2,d0
		sub	d5,d0
		cmp	d1,d0
		bls	@f
		move	d1,d0
@@:		move	d0,(SUBWIN_X,a0)

		move	(＄kz_y),d0
		cmpi	#28,d0
		bhi	@f
		move	d0,(SUBWIN_Y,a0)
@@:		jsr	(WinOpen)
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

		swap	d5
		move	d0,d5
		move.l	d5,d0
		move.l	#INPUT_MAX<<16+RL_F_CSR,d1
		move.l	d6,d2
		bpl	@f
		moveq	#0,d2
@@:		bsr	MintReadLine
		move.l	d0,d7
		move	d5,d0
		jsr	(WinClose)

		moveq	#0,d0
		tst.l	d7
		bmi	input_skip_set		;ESC、CTRL+G で抜けた

		exg	a1,a2			;a1=変数名 a2=バッファ
		tst.b	(a2)
		bne	@f
		move.l	#'NUL'<<8,(a2)
@@:
		jsr	(set_user_value_a1_a2)
input_skip_set:
		jsr	(set_status)

		lea	(INPUT_MAX+2,sp),sp
		jmp	(print_music_title)
**		rts


subwin_input:
		SUBWIN	12,8,72,1,NULL,NULL

underline:	.dc.b	'_',0
		.even


* 行入力呼び出し ------------------------------ *
* in	d0.hw	ウィンドウ幅(0 の場合は d1.hw を幅と見なす)
*	d0.lw	ウィンドウ番号
*	d1.hw	最大入力バイト数
*	d1.lw	フラグ
*	d2.l	カーソル位置(RL_F_CSR 指定時のみ)
*	a1.l	バッファアドレス(d1.hw+1 の容量が必要)
* out	d0.l	-1:キャンセル(C-g など)
*		 0:確定終了(RETERN など)
*		 1:↓/ROLL UP による終了
*		 2:↑/ROLL DOWN 〃
*	ccr	<tst.l d0> の結果

MintReadLine::
		PUSH	d1-d3/a0-a2/a5
		lea	(rl_buf,pc),a5
		lea	(-256,sp),sp
		move.l	d0,d3

* バッファアドレス/サイズ
		move.l	a1,(_RL_BUF,a5)
		move.l	d1,d0
		clr	d0
		swap	d0
		addq.l	#1,d0
		move.l	d0,(_RL_SIZE,a5)

* 単語構成文字
		lea	(sp),a2
		move.l	a2,(_RL_WORDS,a5)
		pea	(a2)
		clr.l	-(sp)
		pea	(str_mintwordchars,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		pea	(str_wordchars,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		GETMES	MES_MWCHR
		movea.l	d0,a0
		STRCPY	a0,a2
@@:
		addq.l	#12-4,sp

* キー入力待ち処理
		lea	(null_job,pc),a0
		btst	#RL_B_QUIET,d1
		beq	@f
		suba.l	a0,a0
@@:		move.l	a0,(_RL_NULL,a5)

* カーソル位置
		btst	#RL_B_DOT,d1
		sne	(_RL_F_DOT,a5)
		bne	@f			;設定不要
		btst	#RL_B_CSR,d1
		bne	1f			;d2.l に指定済み
		STRLEN	a1,d2
1:		move.l	d2,(_RL_CSR_X,a5)
@@:
* マーク位置初期化
		clr.l	(_RL_MARK_X,a5)

* ウィンドウ幅
		move.l	d3,d0
		clr	d0
		swap	d0
		bne	@f
		move.l	d1,d0
		clr	d0
		swap	d0
@@:		move.l	d0,(_RL_WIDTH,a5)

* ウィンドウ位置/描画色
		move	d3,d0
		jsr	(WinGetPtr)
		movea.l	d0,a0
		move	(WIND_TX_X,a0),d0
		add	(WIND_CUR_X,a0),d0
		move	d0,(_RL_WIN_X,a5)
		move	(WIND_TX_Y,a0),d0
		add	(WIND_CUR_Y,a0),d0
		move	d0,(_RL_WIN_Y,a5)
		moveq	#3,d0
		and	(WIND_COLOR,a0),d0
		move.b	d0,(_RL_COL,a5)

* 補完関係のフラグ
		moveq	#$ff-(1<<VOLUME),d0
		btst	#RL_B_DIR,d1
		beq	@f
		moveq	#1<<DIRECTORY,d0
@@:		move.b	d0,(_RL_C_ATR,a5)
		move.b	(MINTSLASH),(_RL_C_SLASH,a5)
		tst	(＄adds)
		sne	(_RL_C_ADDS,a5)
		btst	#RL_B_QUIET,d1
		seq	(_RL_C_DISP,a5)

* 操作モード
		tst	(＄esc！)
		sne	(_RL_F_EMACS,a5)
**		st	(_RL_F_FEP,a5)
		btst	#RL_B_UP,d1
		sne	(_RL_F_UP,a5)
		btst	#RL_B_DOWN,d1
		sne	(_RL_F_DOWN,a5)
		btst	#RL_B_RU,d1
		sne	(_RL_F_RU,a5)
		btst	#RL_B_RD,d1
		sne	(_RL_F_RD,a5)

		bsr	to_mint_cursor
		jsr	(fep_enable)

		pea	(a5)
		jsr	(_ReadLine)
		move.l	d0,(sp)

		jsr	(fep_disable)
		bsr	to_os_cursor

		move.l	(sp)+,d1
		moveq	#RL_E_RET,d0
		cmpi.b	#CR,d1
		beq	@f
		cmpi.b	#LF,d1
		beq	@f

		moveq	#RL_E_NEXT,d0
		cmpi.b	#$0e,d1
		beq	@f

		moveq	#RL_E_PREV,d0
		cmpi.b	#$10,d1
		beq	@f

		moveq	#RL_E_ESC,d0
@@:
		lea	(256,sp),sp
		POP	d1-d3/a0-a2/a5
		tst.l	d0
		rts


* カーソル形状変更 ---------------------------- *
* 備考:
*	IOCS _B_CONMOD を使用する(要 IOCS.X/ROM1.3).

to_mint_cursor:
		PUSH	d0-d2
		moveq	#14,d2
		bra.s	@f
to_os_cursor:
		PUSH	d0-d2
		moveq	#0,d2
@@:
		tst	(＄curm)
		beq	to_os_cursor_skip

		swap	d2
		not	d2			;開始ライン|反転パターン($ffff)
		moveq	#2,d1
		IOCS	_B_CONMOD
to_os_cursor_skip:
		POP	d0-d2
		rts


* キー入力待ち処理 ---------------------------- *

null_job:
		DOS	_CHANGE_PR
		jmp	(update_periodic_display)
**		rts


* 補完リスト展開処理 -------------------------- *
* in	(4,sp).l	バッファ先頭アドレス			a2
*	(8,sp).l	補完対象文字列のアドレスへのポインタ	a3 -> a6
*	(12,sp).l		〃	長さ	〃		a4 -> d4
*	(16,sp).l	リスト展開バッファのアドレス		a5
*	(20,sp).l		〃	    サイズ		a6 -> d5
* out	d0.l	項目数(負数ならエラー)
* break	d1-d2/a0-a2

comp_job:
		PUSH	d3-d7/a3-a6
		movem.l	(4+4*9,sp),a2/a3/a4/a5/a6
		move.l	a6,d5
		moveq	#0,d6			;バッファに書き込んだ個数

		movea.l	(a3),a6			;補完対象文字列のアドレス
		move.l	(a4),d4			;	〃	 長さ
		beq	cj_error

		move.b	(a6)+,d0
		cmpi.b	#'&',d0
		beq	cj_builtin_func		;関数
		cmpi.b	#'-',d0
		beq	cj_option		;オプション
		cmpi.b	#'$',d0
		bne	cj_error

* $ : 変数補完
		moveq	#0,d7
		subq.l	#1+1,d4
		bcs	cj_value		;変数 $
		move.b	(a6)+,d0
		cmpi.b	#'?',d0
		bne	@f
		subq.l	#1,d4
		bcs	cj_value		;変数 $?
		move.b	(a6)+,d0
@@:
		moveq	#+1,d7
		cmpi.b	#'@',d0
		beq	1f			;システム変数 $@
		moveq	#0,d7
		cmpi.b	#'%',d0
		bne	@f
		moveq	#-1,d7			;環境変数 $%
1:
		subq.l	#1,d4
		bcs	cj_value
		move.b	(a6)+,d0
@@:
		cmpi.b	#'{',d0
		beq	@f			;${
		subq.l	#1,a6			;$x
cj_value:
		addq.l	#1,d4
@@:
		tst	d7
		bgt	cj_value_env_end
* 環境変数
*	.dc.b	'name1=value1',0
*	.dc.b	'name2=value2',0
*	.dc.b	0
		movea.l	(mint_start-$100+$10),a2
		addq.l	#4,a2
		moveq	#'=',d1
		bra	cj_value_env_start
cj_value_env_loop:
		bsr	cj_strcmp
		bne	cj_value_env_next
@@:
		move.b	(a0)+,d0
		beq	cj_value_env_next
		cmp.b	d1,d0
		bne	@b

		move.l	a0,d0
		sub.l	a2,d0			;長さ
		addq.l	#1,d0
		sub.l	d0,d5
		bcs	cj_end

		move.b	#1<<ARCHIVE,(a5)+	;属性(%adds 1 で空白付加)
		subq.l	#2,d0
@@:
		move.b	(a2)+,(a5)+
		subq.l	#1,d0
		bne	@b
		clr.b	(a5)+
		addq.l	#1,d6
cj_value_env_next:
		tst.b	(a2)+
		bne	cj_value_env_next
cj_value_env_start:
		tst.b	(a2)
		bne	cj_value_env_loop
cj_value_env_end:
		tst	d7
		bne	cj_value_res_usr_end
* システム予約変数
*	.dc.b	'name1',0
*	.dc.b	'name2',1,'name3',0
*	.dc.b	0
		lea	(sys_res_val_tbl),a2
		moveq	#$01,d1
cj_value_res_loop:
		bsr	cj_strcmp
		bne	cj_value_res_next
@@:
		cmp.b	(a0)+,d1
		bcs	@b

		move.l	a0,d0
		sub.l	a2,d0			;長さ
		addq.l	#1,d0
		sub.l	d0,d5
		bcs	cj_end

		move.b	#1<<ARCHIVE,(a5)+	;属性(%adds 1 で空白付加)
		lea	(a2),a0
		subq.l	#2,d0
@@:
		move.b	(a0)+,(a5)+
		subq.l	#1,d0
		bne	@b
		clr.b	(a5)+
		addq.l	#1,d6
cj_value_res_next:
		cmp.b	(a2)+,d1
		bcs	cj_value_res_next
		tst.b	(a2)
		bne	cj_value_res_loop
* ユーザ変数
*	.dc.b	'name1',1,'value1',0
*	.dc.b	'name2',1,'value2',0
*	.dc.b	0
		lea	(user_value_tbl),a2
**		moveq	#$01,d1
		bra	cj_value_usr_start
cj_value_usr_loop:
		bsr	cj_strcmp
		bne	cj_value_usr_next
@@:
		move.b	(a0)+,d0
		beq	cj_value_usr_next
		cmp.b	d0,d1
		bne	@b

		move.l	a0,d0
		sub.l	a2,d0			;長さ
		addq.l	#1,d0
		sub.l	d0,d5
		bcs	cj_end

		move.b	#1<<ARCHIVE,(a5)+	;属性(%adds 1 で空白付加)
		subq.l	#2,d0
@@:
		move.b	(a2)+,(a5)+
		subq.l	#1,d0
		bne	@b
		clr.b	(a5)+
		addq.l	#1,d6
cj_value_usr_next:
		tst.b	(a2)+
		bne	cj_value_usr_next
cj_value_usr_start:
		tst.b	(a2)
		bne	cj_value_usr_loop
cj_value_res_usr_end:
		tst	d7
		bmi	cj_value_sys_end
* システム変数
*	.dc.l	'aaaa'
*	.dc.l	'bbbb'
*	.dc.l	0
		moveq	#4,d0
		cmp.l	d0,d4
		bhi	cj_value_sys_end	;5 バイト以上は常に不一致

		lea	(sys_val_name),a2
cj_value_sys_loop:
		bsr	cj_strcmp
		bne	cj_value_sys_next

		subq.l	#4+2,d5
		bcs	cj_end

		suba.l	d4,a0
		move.b	#1<<ARCHIVE,(a5)+	;属性(%adds 1 で空白付加)
	.rept	4
		move.b	(a0)+,(a5)+
	.endm
		clr.b	(a5)+
		addq.l	#1,d6
cj_value_sys_next:
		addq.l	#4,a2
		tst.b	(a2)
		bne	cj_value_sys_loop
cj_value_sys_end:
		bra	cj_end

* & : 内部命令補完
*	.dc.b	'break',1,'last',0
*	.dc.b	'if',0
*	.dc.b	0
cj_builtin_func:
		lea	(func_name_list),a2
		moveq	#$01,d1
		moveq	#'&',d2
		subq.l	#1,d4			;補完対象の '&' は比較しない
cj_func_loop:
		bsr	cj_strcmp
		bne	cj_func_next
@@:
		cmp.b	(a0)+,d1
		bcs	@b

		move.l	a0,d0
		sub.l	a2,d0			;長さ
		addq.l	#2,d0
		sub.l	d0,d5
		bcs	cj_func_end

		move.b	#1<<ARCHIVE,(a5)+	;属性(%adds 1 で空白付加)
		lea	(a2),a0
		move.b	d2,(a5)+
		subq.l	#3,d0
@@:
		move.b	(a0)+,(a5)+
		subq.l	#1,d0
		bne	@b
		clr.b	(a5)+
		addq.l	#1,d6
cj_func_next:
		cmp.b	(a2)+,d1
		bcs	cj_func_next
		tst.b	(a2)
		bne	cj_func_loop
cj_func_end:
		subq.l	#1,a6
		addq.l	#1,d4
		bra	cj_end

* - : オプション補完
cj_option:
		cmpa.l	(a3),a2
		beq	cj_opt_error		;先頭ならオプション補完は出来ない
		move.l	(at_complete_list),d0
		beq	cj_opt_error
		movea.l	d0,a1

		lea	(a2),a0
cj_opt_cmd_loop:
		move.b	(a0)+,d0
		cmpi.b	#$20,d0
		bls	cj_opt_cmd_last
		cmpi.b	#'/',d0
		beq	cj_opt_cmd_delim
		cmpi.b	#'\',d0
		beq	cj_opt_cmd_delim
		cmpi.b	#':',d0
		beq	cj_opt_cmd_delim
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	cj_opt_cmd_loop
		addq.l	#1,a0
		bra	cj_opt_cmd_loop
cj_opt_cmd_delim:
		lea	(a0),a2			;パスデリミタがあった
		bra	cj_opt_cmd_loop
cj_opt_cmd_last:
		subq.l	#1,a0
		move.l	a0,d7
		sub.l	a2,d7			;コマンド名の長さ
		beq	cj_opt_error

		moveq	#1,d0
		move.l	d0,(_ignore_case)
		subq.l	#1,a6
cj_opt_sch_loop:
		cmpi.b	#$20,(a1)
		bls	cj_opt_sch_next
		cmpi.b	#'@',(a1)
		beq	cj_opt_error
		cmpi.b	#'>',(a1)
		beq	cj_opt_error
		cmpi.b	#'!',(a1)
		beq	cj_opt_error
		cmpi.b	#'.',(a1)
		beq	cj_opt_error
		cmpi.b	#'#',(a1)
		beq	cj_opt_error

		moveq	#LF,d0
		lea	(a1),a0
@@:		cmp.b	(a0)+,d0
		bne	@b
		move.l	a0,d0
		sub.l	a1,d0			;この行の長さ
		cmp.l	d0,d5
		bcs	cj_opt_sch_next

		lea	(a5),a0			;バッファ
		jsr	(cut_filename_pattern)
		bmi	cj_opt_sch_next

		move.l	a0,d1
		sub.l	a5,d1
		move.l	d5,d0
		sub.l	d1,d0			;バッファ残量
		bls	cj_opt_sch_next		;念の為…

		PUSH	a0-a2
		pea	(a5)			;pattern
		lsr.l	#1,d0
		move.l	d0,-(sp)		;buffer size(.w)
		pea	(a0)			;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		POP	a0-a2
		bne	cj_opt_sch_next

		move.b	(a2,d7.l),d3
		clr.b	(a2,d7.l)
		PUSH	a0-a2
		pea	(a2)			;filename
		pea	(a0)			;buffer
		jsr	(_fre_match)
		addq.l	#8,sp
		POP	a0-a2
		move.b	d3,(a2,d7.l)
		tst.l	d0
		beq	cj_opt_sch_next
cj_opt_loop_y:
		jsr	(next_line_a1)
		beq	cj_opt_end

		cmpi.b	#SPACE,(a1)
		beq	@f
		cmpi.b	#TAB,(a1)
		bne	cj_opt_end
@@:
		bsr	cj_opt_skip_blank
		bne	cj_opt_end
cj_opt_loop_x:
		lea	(a1),a0
@@:		cmpi.b	#$20,(a0)+
		bhi	@b
		move.l	a0,d1
		sub.l	a1,d1			;オプションの長さ+1
		addq.l	#1,d1
		cmp.l	d1,d5
		bcs	cj_opt_end

		lea	(a5),a0			;とりあえずバッファに書き出す
		move.b	#1<<ARCHIVE,(a0)+	;属性(%adds 1 で空白付加)
		move.l	d1,d0
		subq.l	#2,d0
@@:
		move.b	(a1)+,(a0)+
		subq.l	#1,d0
		bne	@b
		clr.b	(a0)+

		PUSH	a0-a2
		lea	(1,a5),a2
		bsr	cj_strcmp
		POP	a0-a2
		bne	@f

		adda.l	d1,a5
		sub.l	d1,d5
		addq.l	#1,d6
@@:
		bsr	cj_opt_skip_blank
		beq	cj_opt_loop_x		;オプションの記述が続いている
		bra	cj_opt_loop_y		;次の行へ
cj_opt_end:
		tst.l	d6
		ble	cj_opt_error
		bra	cj_end
cj_opt_sch_next:
		jsr	(next_line_a1)
		bne	cj_opt_sch_loop
cj_opt_error:
		bra	cj_error

cj_opt_skip_blank_loop:
		addq.l	#1,a1
cj_opt_skip_blank:
		cmpi.b	#SPACE,(a1)
		beq	cj_opt_skip_blank_loop
		cmpi.b	#TAB,(a1)
		beq	cj_opt_skip_blank_loop
		cmpi.b	#'-',(a1)
		rts

cj_end:
		move.l	d6,d0
		ble	cj_error		;一つもない場合はファイル補完を行う

		move.l	a6,(a3)
		move.l	d4,(a4)
@@:
		POP	d3-d7/a3-a6
		rts
cj_error:
		moveq	#-1,d0
		bra.s	@b


* 文字列比較
* in	a2.l	文字列
*	a6.l	補完対象文字列のアドレス
*	d4.l		〃	長さ
* out	a0.l	ccrZ=1 の時、a2.l + d4.l
*	ccr	Z=1:一致 Z=0:不一致
cj_strcmp:
		lea	(a2),a0
		move.l	d4,d0
		beq	cj_strcmp_end
		lea	(a6),a1
@@:
		cmpm.b	(a0)+,(a1)+
		bne	cj_strcmp_end
		subq.l	#1,d0
		bne	@b
cj_strcmp_end:
		rts


* Data Section -------------------------------- *

**		.data
		.even

rl_buf:
		.dc.l	0			;_RL_BUF
		.dc.l	0			;_RL_SIZE
		.dc.l	0			;_RL_YANK_BUF
		.dc.l	0			;_RL_WORDS
		.dc.l	0			;_RL_NULL
		.dc.l	＆v_bell		;_RL_BELL
		.dc.l	comp_job		;_RL_COMPLETE
		.dc.l	0			;_RL_MALLOC
		.dc.l	0			;_RL_MFREE
		.dc.l	0			;_RL_CSR_X
		.dc.l	0			;_RL_MARK_X
		.dc.l	5			;_RL_MARGIN
		.dc.l	0			;_RL_WIDTH
		.dc	0			;_RL_WIN_X
		.dc	0			;_RL_WIN_Y

		.dc.b	0			;_RL_COL
		.dc.b	WHITE			;_RL_C_COL
		.dc.b	0			;_RL_C_ATR
		.dc.b	0			;_RL_C_SLASH
		.dc.b	0			;_RL_C_ADDS
		.dc.b	0			;_RL_C_DISP

		.dc.b	0			;_RL_F_DOT
		.dc.b	0			;_RL_F_EMACS
		.dc.b	$ff			;_RL_F_FEP
		.dc.b	0			;_RL_F_UP
		.dc.b	0			;_RL_F_DOWN
		.dc.b	0			;_RL_F_RU
		.dc.b	0			;_RL_F_RD

str_mintwordchars:
		.dc.b	'MINT'
str_wordchars:	.dc.b	    'WORDCHARS',0
		.even


* Block Storage Section ----------------------- *

**		.bss
		.even

at_complete_list::
		.ds.l	1


		.end

* End of File --------------------------------- *
