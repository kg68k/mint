# isearch.s - &i-search
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
		.include	func.mac
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* mint.s
		.xref	set_status
		.xref	goto_cursor_sub,print_file_list
		.xref	search_cursor_file,mark_sub
		.xref	fep_enable,fep_disable
		.xref	scr_cplp_line
		.xref	update_periodic_display
* patternmatch.s
		.xref	init_i_c_option,take_i_c_option
		.xref	exist_sub,exist_sub_sp,_fre_compile,_ignore_case


* Offset Table -------------------------------- *

		.offset	0
~win_no:	.ds	1
~key_buf_top:	.ds.l	1
~key_buf_ptr:	.ds.l	1
~key_buf_end:	.ds.l	1
~str_buf:	.ds.b	23
~str_buf_end:	.ds.b	1
~str_buf2:	.ds.b	(1+23+1)+1
~emacs_mode:	.ds.b	1			;$00=normal $01=emacs-like $ff=extend
~reverse:	.ds.b	1
~stat:		.ds.b	1			;$01=incomplete $ff=missmatch
		.even
sizeof_work:

		.offset	0
~kb_code:	.ds	1
~kb_pagetop:	.ds	1
~kb_y:		.ds	1
~kb_reverse:	.ds.b	1
~kb_stat:	.ds.b	1
sizeof_kb:
		.fail	$.ne.8
		.text


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


*************************************************
*	&i-search=&incremental-search		*
*************************************************

＆i_search::
＆incremental_search::
		tst.b	(PATH_NODISK,a6)
		bne	i_search_end
		tst	(PATH_FILENUM,a6)
		beq	i_search_end

		moveq	#1,d0
		sub	(＄case),d0		;0 -> 1, 1 -> 0
		move.l	d0,(_ignore_case)	;%case 2 はあとで処理する

		GETMES	MES_F_SER
		movea.l	d0,a1
		moveq	#0,d5			;-r
		moveq	#0,d6			;-e
		bra	i_search_arg_next
i_search_arg_loop:
		jsr	(take_i_c_option)
		beq	i_search_arg_next
		move.b	(a0)+,d0
		beq	i_search_arg_next
		cmpi.b	#'-',d0
		bne	i_search_direct_mode
		move.b	(a0)+,d0
		beq	i_search_arg_next
		cmpi.b	#'e',d0
		beq	i_search_opt_e
		cmpi.b	#'r',d0
		beq	i_search_opt_r
		cmpi.b	#'t',d0
		bne	i_search_arg_skip
*i_search_opt_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	i_search_arg_end
@@:
		lea	(-1,a0),a1
		bra	i_search_arg_skip
i_search_opt_e:
		moveq	#1,d6			;-e : EMACS モード
		move.b	(a0)+,d0
		beq	i_search_arg_next
		cmpi.b	#'1',d0
		beq	i_search_arg_skip
		shi	d6			;-e0 : 通常モード
		bra	i_search_arg_skip	;-e2 : 拡張モード
i_search_opt_r:
		moveq	#-1,d5			;-r : 逆方向モード
		bra	i_search_arg_skip
i_search_arg_skip:
		tst.b	(a0)+
		bne	i_search_arg_skip
i_search_arg_next:
		subq.l	#1,d7
		bcc	i_search_arg_loop
i_search_arg_end:
		bra	i_search_input_mode

* パターン指定時
i_search_direct_mode:
		subq.l	#1,a0
		bsr	i_search_set_ic

		jsr	(search_cursor_file)
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	i_search_error		;バッファが空だった

		lea	(sizeof_DIR,a4),a4	;次ファイルから検索する
		jsr	(exist_sub)
		bmi	i_search_error

		jsr	(goto_cursor_sub)	;見つかったらそこに移動する
		bra	i_search_end

i_search_end:
		moveq	#1,d0
		bra	@f
i_search_error:
		moveq	#0,d0
@@:
		jmp	(set_status)
**		rts

* %case 2 の場合のモード設定
i_search_set_ic:
		moveq	#1,d0
		cmp.l	(_ignore_case),d0
		bcc	@f
		jmp	(init_i_c_option)	;%case 2 = (V)TwentyOne.sys の状態に従う
@@:		rts

* パターン省略時
i_search_input_mode:
		bsr	i_search_set_ic

		pea	(-1).w			;メモリ確保
		DOS	_MALLOC
		move.l	d0,d2
		andi.l	#$00ffff00,d2
		beq	@f
		move.l	d2,(sp)
		DOS	_MALLOC
		movea.l	d0,a0
@@:
		move.l	d0,(sp)+
		ble	i_search_error

		jsr	(fep_enable)

		lea	(-sizeof_work,sp),sp
		lea	(sp),a5

		move.l	a0,(~key_buf_top,a5)	;ワーク初期化
		move.l	a0,(~key_buf_ptr,a5)
		adda.l	d2,a0
		move.l	a0,(~key_buf_end,a5)
		clr.b	(~str_buf,a5)
		move.b	d5,(~reverse,a5)
		move.b	d6,(~emacs_mode,a5)

		lea	(subwin_i_search,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		move	(PATH_WINRL,a6),d0
		addq	#4,d0
		swap	d0
		move	(scr_cplp_line),d0
		cmpi	#DIRH_MAX+4,d0
		bcs	@f
		subq	#1,d0
@@:		move.l	d0,(SUBWIN_X,a0)	;X/Y
		jsr	(WinOpen)
		move	d0,(~win_no,a5)

		GETMES	MES_SEARC
		movea.l	d0,a1

		move	(~win_no,a5),d0
		moveq	#1,d1
		moveq	#2,d2
		jsr	(WinSetCursor)
		moveq	#BLUE,d1
		jsr	(WinSetColor)
		jsr	(WinPrint)
		moveq	#12,d1
		moveq	#2,d2
		jsr	(WinSetCursor)

		st	(~stat,a5)
		moveq	#$00,d0
		bsr	update_status
		bsr	print_case_mode

		bra	i_search_loop
i_search_key_error:
.if 0
		jsr	(＆v_bell)		;欝陶しいので何もしない
.endif
i_search_loop:
		lea	(~str_buf,a5),a0
		STREND	a0	
@@:
		bsr	key_input
		cmpi	#$20,d0
		bls	i_search_ctrl

		movea.l	(~key_buf_ptr,a5),a1	;キー履歴バッファの容量チェック
		cmpa.l	(~key_buf_end,a5),a1
		bcc	i_search_key_error

		tst	d0
		bmi	i_search_mb
*i_search_sb:
		lea	(~str_buf_end,a5),a2	;一バイト文字
		cmpa.l	a2,a0
		bcc	i_search_key_error
		cmpi.b	#'/',d0
		bne	@f
		moveq	#SPACE,d0		;'/'で半角スペース入力
		bra	@f
i_search_mb:
		lea	(~str_buf_end-1,a5),a2	;二バイト文字
		cmpa.l	a2,a0
		bcc	i_search_key_error

		move	d0,-(sp)		;文字列バッファに追加
		move.b	(sp)+,(a0)+
@@:		move.b	d0,(a0)+
		clr.b	(a0)

		move	d0,d1
		bsr	print_char		;文字を表示する

* 文字コードと現在の位置を保存する
		addq.l	#sizeof_kb,(~key_buf_ptr,a5)
		move	d0,(a1)+		;~kb_code
		move	(PATH_PAGETOP,a6),(a1)+	;~kb_pagetop
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		move	d2,(a1)+		;~kb_y
		move.b	(~reverse,a5),(a1)+	;~kb_reverse
		move.b	(~stat,a5),(a1)+	;~kb_stat
		bmi	i_search_loop		;不一致中

* メタキャラ [ " ' が [] "" '' の対になっていなければ
* 検索は後回しにする.
		bsr	make_search_pat		;*pat*
		bsr	check_pattern		;*pat[* *pat"* *pat'* ならエラー
		bne	i_search_incomp

		lea	(~str_buf2,a5),a0
@@:		tst.b	(a0)+
		bne	@b
		clr.b	(-2,a0)			;*pat
		bsr	check_pattern		;*pat\ ならエラー
		beq	@f
i_search_incomp:
		moveq	#$01,d0			;$01=incomplete
		bsr	update_status		;[\"' などが終わっていない
		bra	i_search_loop
@@:
		bsr	search_for_rev
		bsr	update_status
		bra	i_search_loop

check_pattern:
		pea	(~str_buf2,a5)		;pattern
		pea	(1024*10/2).w		;buffer size(.w)
		pea	(Buffer)		;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		rts

* 制御記号
i_search_ctrl:
		add	d0,d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	i_search_loop-@b	;$00 : NUL
		.dc	i_search_quit-@b	;$01
		.dc	i_search_quit-@b	;$02
		.dc	i_search_quit-@b	;$03
		.dc	i_search_quit-@b	;$04
		.dc	i_search_ctrl_e-@b	;$05 : CTRL+E
		.dc	i_search_quit-@b	;$06
		.dc	i_search_bel-@b		;$07 : CTRL+G(BEL)
		.dc	i_search_bs-@b		;$08 : CTRL+H(BS)
		.dc	i_search_tab-@b		;$09 : CTRL+I(TAB)
		.dc	i_search_quit-@b	;$0a
		.dc	i_search_quit-@b	;$0b
		.dc	i_search_quit-@b	;$0c
		.dc	i_search_cr-@b		;$0d : CTRL+M(CR)
		.dc	i_search_quit-@b	;$0e
		.dc	i_search_quit-@b	;$0f
		.dc	i_search_quit-@b	;$10
		.dc	i_search_quit-@b	;$11
		.dc	i_search_ctrl_r-@b	;$12 : CTRL+R
		.dc	i_search_ctrl_s-@b	;$13 : CTRL+S
		.dc	i_search_quit-@b	;$14
		.dc	i_search_quit-@b	;$15
		.dc	i_search_quit-@b	;$16
		.dc	i_search_quit-@b	;$17
		.dc	i_search_ctrl_x-@b	;$18 : CTRL+X
		.dc	i_search_quit-@b	;$19
		.dc	i_search_quit-@b	;$1a
		.dc	i_search_esc-@b		;$1b : CTRL+[(ESC)
		.dc	i_search_quit-@b	;$1c
		.dc	i_search_quit-@b	;$1d
		.dc	i_search_quit-@b	;$1e
		.dc	i_search_quit-@b	;$1f
		.dc	i_search_spc-@b		;$20 : SPACE

* CTRL+S、CTRL+X、TAB、CTRL+I : 次検索
i_search_ctrl_s:
i_search_ctrl_x:
i_search_tab:
		bsr	search_forward2
		sf	(~reverse,a5)
		bmi	i_search_loop
		bsr	update_status
		bra	i_search_loop

* CTRL+R、CTRL+E : 逆検索
i_search_ctrl_r:
i_search_ctrl_e:
		bsr	search_reverse2
		st	(~reverse,a5)
		bmi	i_search_loop
		bsr	update_status
		bra	i_search_loop

i_search_spc:
		IOCS	_B_SFTSNS
		lsr	#1,d0
		bcs	i_search_sft_spc
		lsr	#1,d0
		bcs	i_search_ctrl_spc

* SPACE : カーソル位置マーク＋次検索
		jsr	(mark_sub)
		bsr	search_forward2
		sf	(~reverse,a5)
		bmi	i_search_loop
		bsr	update_status
		bra	i_search_loop

* SHIFT+SPACE : 連続マーク
i_search_sft_spc:
@@:		jsr	(mark_sub)
		bsr	search_forward2
		sf	(~reverse,a5)
		bmi	i_search_loop
		bsr	update_status
		bra	@b

* CTRL+SPACE : カーソル位置マーク
i_search_ctrl_spc:
		jsr	(mark_sub)
		bra	i_search_loop

* CTRL+H、BS : 一文字削除
i_search_bs:
		movea.l	(~key_buf_ptr,a5),a1
		cmpa.l	(~key_buf_top,a5),a1
		bls	i_search_key_error

		subq.l	#sizeof_kb,a1
		move.l	a1,(~key_buf_ptr,a5)
		tst	(~kb_code,a1)
		beq	i_search_bs_no_char	;CTRL+S などの取り消し

		sf	-(a0)			;文字列バッファから削除
		smi	d3
		bpl	@f
		clr.b	-(a0)			;二バイト文字
@@:
		move	(~win_no,a5),d0		;直前の文字を消去
		jsr	(WinCursorLeft)
		moveq	#SPACE,d1
		bsr	print_char
		jsr	(WinCursorLeft)
		addq.b	#1,d3
		bcs	@b			;二バイト文字なら二回繰り返す

		move.b	(~kb_stat,a1),d0
		bsr	update_status
		bra	@f
i_search_bs_no_char:
**		bsr	surmise_reverse
@@:
		move.b	(~kb_reverse,a1),(~reverse,a5)
		bsr	back_position		;表示位置を戻す
		bra	i_search_loop

.if 0
* 元の検索方向を推測する
* (操作によっては正しく戻せないことがある)
surmise_reverse:
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		add	(PATH_PAGETOP,a6),d2	;現在のカーソル位置
		move.l	(a1)+,d0		;~kb_pagetop
		add	(a1)+,d0		;~kb_y
		cmp	d0,d2
		beq	@f
		scs	(~reverse,a5)
@@:		rts
.endif

* CR : 確定(CTRL+M の場合は -i/-c 切り換え)
i_search_cr:
		IOCS	_B_SFTSNS
		lsr	#2,d0
		bcc	i_search_quit		;CTRL + M 以外は確定終了
		moveq	#6,d1
		IOCS	_BITSNS
		lsr.b	#1,d0
		bcc	i_search_quit		;〃

* CTRL+M : -i/-c 切り換え
		moveq	#1,d0
		eor.l	d0,(_ignore_case)
		lea	(＄case),a0
		cmp	(a0),d0
		bcs	@f			;%case 2 なら変更しない
		eor	d0,(a0)			;%case 0 <-> 1
@@:
		bsr	print_case_mode
		bra	i_search_loop

* CTRL+G : 中断終了(カーソルを &i-search 実行前の位置に戻す)
i_search_bel:
		movea.l	(~key_buf_top,a5),a1
		cmpa.l	(~key_buf_ptr,a5),a1
		bcc	@f

		move.l	a1,(~key_buf_ptr,a5)
		bsr	back_position
@@:
		bra	i_search_quit

* ESC、CR、ENTER : 確定終了
i_search_esc:
i_search_quit:
		lea	(~str_buf,a5),a0
		tst.b	(a0)
		beq	@f

		lea	(prev_str),a1
		STRCPY	a0,a1			;検索文字列を保存する
@@:
		move	(~win_no,a5),d0
		jsr	(WinClose)

		move.l	(~key_buf_top,a5),(sp)
		DOS	_MFREE
		lea	(sizeof_work,sp),sp

		jsr	(fep_disable)
		bra	i_search_end


* モードごとに検索
search_for_rev:
		tst.b	(~emacs_mode,a5)
		beq	search_forward_from_top	:通常モードなら常に、先頭から↓方向
		tst.b	(~reverse,a5)
		bne	search_reverse		;EMACS モードで↑方向
		bra	search_forward		;〃	       ↓方向
**		rts

* 検索(↓).
* out	d0.l	エラーコード(負数なら検索失敗)
*	ccr	<tst.l d0> の結果
search_forward:
		PUSH	d1-d7/a0-a4
		moveq	#0,d0
		bsr	search_forward_sub
		bra	@f

search_forward_from_top:
		PUSH	d1-d7/a0-a4
		moveq	#0,d0
		movea.l	(PATH_BUF,a6),a4	;先頭から検索
		bsr	search_forward_sub2
		bra	@f

* 次検索(↓).
* out	d0.l	エラーコード(負数なら検索失敗)
*	ccr	<tst.l d0> の結果
search_forward2:
		PUSH	d1-d7/a0-a4
		moveq	#sizeof_DIR,d0
		lea	(search_forward_sub,pc),a3
		bsr	search_fr_sub
@@:		POP	d1-d7/a0-a4
		rts

* 検索(↑).
* out	d0.l	エラーコード(負数なら検索失敗)
*	ccr	<tst.l d0> の結果
search_reverse:
		PUSH	d1-d7/a0-a4
		moveq	#0,d0
		bsr	search_reverse_sub
		bra	@b

* 次検索(↑).
* out	d0.l	エラーコード(負数なら検索失敗)
*	ccr	<tst.l d0> の結果
search_reverse2:
		PUSH	d1-d7/a0-a4
		moveq	#-sizeof_DIR,d0
		lea	(search_reverse_sub,pc),a3
		bsr	search_fr_sub
		bra	@b


* 次検索下請け.
search_fr_sub:
		movea.l	(~key_buf_ptr,a5),a1
		cmpa.l	(~key_buf_end,a5),a1
		bcc	search_fr_sub_error

		move.l	d0,-(sp)
		clr	(a1)+			;~kb_code
		move	(PATH_PAGETOP,a6),(a1)+	;~kb_pagetop
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		move	d2,(a1)+		;~kb_y
		move.b	(~reverse,a5),(a1)+	;~kb_reverse
		clr.b	(a1)+			;~kb_stat
		move.l	(sp)+,d0

		jsr	(a3)
		bmi	search_fr_sub_error
		addq.l	#sizeof_kb,(~key_buf_ptr,a5)
		moveq	#0,d0
		rts
search_fr_sub_error:
		moveq	#-1,d0
		rts

* 検索(↓)下請け.
search_forward_sub:
		jsr	(search_cursor_file)	;検索開始位置を求める
		tst.l	d0
		beq	@f
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	search_forward_error
		adda.l	d0,a4			;次のファイルから検索
@@:
search_forward_sub2:
		bsr	make_search_pat
		bmi	search_forward_error

		moveq	#1-1,d7
		lea	(~str_buf2,a5),a0
		jsr	(exist_sub_sp)
		bpl	@f
		tst.b	(~emacs_mode,a5)
		bpl	search_forward_error	;見つからなかった

* 拡張検索モード
		movea.l	(PATH_BUF,a6),a4	;先頭から検索し直す
		jsr	(exist_sub_sp)
		bmi	search_forward_error
@@:
		jsr	(goto_cursor_sub)	;見つかったらそこに移動する
		moveq	#0,d0
		rts
search_forward_error:
		moveq	#-1,d0
		rts

* 検索(↑)下請け.
search_reverse_sub:
		bsr	make_search_pat
		bmi	search_reverse_error

		jsr	(search_cursor_file)
		move.l	a4,d6			;これより上のファイルを探す
		add.l	d0,d6			;(前のファイルから検索)
		movea.l	(PATH_BUF,a6),a4
		cmpa.l	d6,a4
		bhi	search_reverse_error	;既に一番上だった

		moveq	#-1,d5
		moveq	#1-1,d7
		lea	(~str_buf2,a5),a0
search_rev_loop:
		jsr	(exist_sub_sp)
		bmi	search_rev_loop_end
		cmpa.l	d6,a4
		bhi	search_rev_passed	;カーソルより下で見つかった

* カーソルより上で見つかった(まだ確定ではない)
* ただし、今見つけたところよりも下で、カーソルより上の残り部分
* (＝カーソル直近)から見つかるかも知れないので、検索し直す
		move.l	d0,d5
		lea	(sizeof_DIR,a4),a4
		cmpa.l	d6,a4			;このチェックはなくても
		bls	search_rev_loop		;遅くなるだけなので消しても平気
		bra	search_rev_loop_end

* カーソルより下で見つかった
search_rev_passed:
		tst.b	(~emacs_mode,a5)	;通常モードなら確定(発見orなし)
		bpl	search_rev_loop_end
		tst.l	d5			;拡張モードでも、カーソルより上で
		bpl	search_rev_loop_end	;見つかっていれば確定

* 拡張検索モード
* カーソルより上にはなかったので、カーソルより下から探す
@@:
		move.l	d0,d5
		lea	(sizeof_DIR,a4),a4
		jsr	(exist_sub_sp)
		bpl	@b
search_rev_loop_end:
		move.l	d5,d0
		bmi	search_reverse_error

		jsr	(goto_cursor_sub)	;見つかったらそこに移動する
		moveq	#0,d0
		rts
search_reverse_error:
		moveq	#-1,d0
		rts

* 検索パターン作成.
* out	d1.l	エラーコード(負数ならエラー)
*	ccr	<tst.l d1> の結果
* 備考:
*	d0.l を破壊しないこと.
make_search_pat:
		lea	(~str_buf,a5),a0
		tst.b	(a0)
		bne	@f
		lea	(prev_str),a0		;バッファが空なら前回の文字列で検索する
		tst.b	(a0)
		bne	@f
		moveq	#-1,d1			;前回の文字列も空
		rts
@@:
		lea	(a0),a2
		lea	(~str_buf2,a5),a1
		move.b	#'*',(a1)+
		cmpi.b	#'^',(a2)
		bne	@f			;pat -> *pat
		subq.l	#1,a1			;^pat -> pat
		addq.l	#1,a2
@@:		STRCPY	a2,a1
		clr.b	(a1)
		move.b	#'*',-(a1)		;*pat -> *pat*
		moveq	#0,d1
		rts


* ステータス表示更新.
* in	d0.b	新しいステータス
*		$00:未検索/一致中
*		$01:incomplete
*		$ff:missmatch
update_status:
		cmp.b	(~stat,a5),d0
		beq	update_st_skip

		PUSH	d0-d2
		move.b	d0,(~stat,a5)

		GETMES	MES_ISCLR
		movea.l	d0,a1

		move	(~win_no,a5),d0
		jsr	(WinSaveCursor)

		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		jsr	(WinPrint)		;先にクリアしておく
		moveq	#YELLOW,d1
		jsr	(WinSetColor)
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

		tst.b	(~stat,a5)
		bmi	update_st_missmatch
		bgt	update_st_incomplete

		moveq	#12,d1			;前回検索文字列を表示
		moveq	#1,d2
		jsr	(WinSetCursor)
		moveq	#BLUE,d1
		jsr	(WinSetColor)
		lea	(prev_str),a1
		bra	update_st_end
update_st_missmatch:
		moveq	#MES_ISMIS,d0
		bra	@f
update_st_incomplete:
		moveq	#MES_ISINC,d0
@@:
		jsr	(get_message)
		movea.l	d0,a1
update_st_end:
		move	(~win_no,a5),d0
		jsr	(WinPrint)

		jsr	(WinRestoreCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)

		POP	d0-d2
update_st_skip:
		rts


* 表示位置/カーソル位置を元に戻す.
back_position:
		PUSH	d0-d2/a1
		jsr	(ReverseCursorBar)	;カーソル消去

		movea.l	(~key_buf_ptr,a5),a1
		move.l	(a1)+,d0		;~kb_pagetop
		cmp	(PATH_PAGETOP,a6),d0
		beq	@f

		move	d0,(PATH_PAGETOP,a6)
		jsr	(print_file_list)
@@:
		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		move	(a1)+,d2		;~kb_y
		jsr	(WinSetCursor)

		jsr	(ReverseCursorBar)	;カーソル描画
		POP	d0-d2/a1
		rts


* 文字表示.
* in	d1.w	文字コード
print_char:
		PUSH	d0-d1
		move	(~win_no,a5),d0
		tst	d1
		bpl	print_char_one

		ror	#8,d1
		jsr	(WinPutChar)
		ror	#8,d1
print_char_one:
		jsr	(WinPutChar)
		POP	d0-d1
		rts


* -i/-c のモードを表示する.
print_case_mode:
		PUSH	d0-d2/a1
		moveq	#MES_ISIGN+1,d0
		sub.l	(_ignore_case),d0	;MES_ISIGN or MES_ISCON
		jsr	(get_message)
		movea.l	d0,a1

		move	(~win_no,a5),d0
		jsr	(WinSaveCursor)

		moveq	#1,d1
		moveq	#3,d2
		jsr	(WinSetCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		jsr	(WinPrint)

		jsr	(WinRestoreCursor)

		POP	d0-d2/a1
		rts


* キー入力.
* out	d0.l	入力したキー(二バイト文字対応)
*	ccr	<tst.w d0> の結果

key_input:
		jsr	(update_periodic_display)
		move	#$ff,-(sp)
		DOS	_INPOUT
		addq.l	#2,sp
		tst.l	d0
		beq	key_input

		move.b	d0,-(sp)
		lsr	#5,d0
		btst	d0,#%10010000
		beq	key_input_sb

		DOS	_INKEY			;二バイト文字の下位バイトを収得
		move.b	d0,(1,sp)
		bne	@f
		clr	(sp)
@@:		move	(sp)+,d0
		rts
key_input_sb:
		move.b	(sp)+,d0		;一バイト文字
		tst	d0
		rts


* Data Section -------------------------------- *

*		.data
		.even

subwin_i_search:
		SUBWIN	0,0,36,3,NULL,NULL


* Block Storage Section ----------------------- *

		.bss
		.even

prev_str:	.ds.b	23+1			;前回検索文字列


		.end

* End of File --------------------------------- *
