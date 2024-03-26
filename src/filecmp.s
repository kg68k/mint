# filecmp.s - &file-compare
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
		.include	message.mac
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac

* Global Symbol ------------------------------- *

* fileop.s
		.xref	copy_dir_name_a1_a2
* mint.s
		.xref	set_status
		.xref	is_mb,is_alpha
		.xref	get_dir_buf_a4_d7
		.xref	cursor_to_home_sub,cursor_down_sub
		.xref	print_mark_information
		.xref	AK_UP,AK_DOWN,AK_LEFT,AK_RIGHT
* outside.s
		.xref	dos_inpout


* Offset Section ------------------------------ *

* 以下のワークはスタック上に確保し、
* その先頭アドレスを a5.l に保持する.

		.offset	0
~fc_cur_fn:	.ds.b	18+1+3	;カーソル側加工済みファイル名
~fc_cur_fn2:	.ds.b	23
		.even
~fc_opp_fn_ptr:	.ds.l	1	;反対側加工済みファイル名バッファのアドレス
~fc_opp_dirbuf:	.ds.l	1	;反対側ディレクトリバッファ先頭アドレス

*~fc_cur_file_c:.ds	1	;カーソル側ファイル数カウンタ
*~fc_opp_file:	.ds	1	;反対側ファイル数カウンタ初期化
*~fc_opp_file_c:.ds	1	;	〃	 カウンタ

~fc_scrl_save:	.ds	1	;%scrl 保存バッファ

~fc_menu_req:	.ds.b	1	;$00=メニュー使用 $01=使用しない $ff=強制使用
~fc_verbose:	.ds.b	1	;0=寡黙 2=冗長
~fc_cmp_file:	.ds.b	1	;0=一致 2=大小同一視 4=曖昧
~fc_cmp_time:	.ds.b	1	;0=一致 2=new 4=old   6=無視 8=不一致 10=曖昧
~fc_cmp_size:	.ds.b	1	;0=一致 2=big 4=small 6=無視 8=不一致 10=曖昧

~fc_fcsiz:	.ds.b	MESLEN_MAX+1
~fc_fctim:	.ds.b	MESLEN_MAX+1
~fc_fcszt:	.ds.b	MESLEN_MAX+1
		.quad
FC_WORK_SIZE:


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&file-compare			*
*************************************************

＆file_compare::
		move	#FC_WORK_SIZE/4-1,d0
@@:
		clr.l	-(sp)			;ワーク初期化
		dbra	d0,@b
		lea	(sp),a5

		lea	(＄scrl),a1
		move	(a1),(~fc_scrl_save,a5)
		move	(＄dirh-＄scrl,a1),d0	;スクロールの高速化の為、一時的に
		subq	#2,d0			;%scrl を最大値(%dirh-2)に変更する
		move	d0,(a1)

		GETMES	MES_FCOMP
		movea.l	d0,a2
		bra	file_compare_arg_next
file_compare_arg_loop:
		move.b	(a0)+,d0
		beq	file_compare_arg_next
		cmpi.b	#'-',d0
		bne	file_compare_error

		move.b	(a0)+,d0
		cmpi.b	#'f',d0
		beq	file_compare_opt_f
		cmpi.b	#'d',d0
		beq	file_compare_opt_d
		cmpi.b	#'l',d0
		beq	file_compare_opt_l
		cmpi.b	#'m',d0
		beq	file_compare_opt_m
		cmpi.b	#'v',d0
		beq	file_compare_opt_v
		cmpi.b	#'t',d0
		bne	file_compare_error
*file_compare_opt_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	file_compare_error
@@:		lea	(-1,a0),a2
		bra	@f
file_compare_opt_v:
		move.b	#2,(~fc_verbose,a5)	;-verbose = 冗長表示モード
		bra	@f

file_compare_opt_m:
		st	(~fc_menu_req,a5)	;-menu = メニューを使用する
@@:
		tst.b	(a0)+
		bne	@b
		bra	file_compare_arg_next

* -f (exact/ignore-case/fuzzy) : ファイル名
file_compare_opt_f:
		lea	(file_compare_f_table,pc),a1
		bsr	file_compare_check_option
		bmi	file_compare_error
		move.b	d0,(~fc_cmp_file,a5)
		bra	file_compare_arg_exist

file_compare_f_table:
		.dc	str_exact-$
		.dc	str_ignore_c-$
		.dc	str_fuzzy-$
		.dc	0

* -d (same/new/old/ignore/diff/fuzzy) : タイムスタンプ
file_compare_opt_d:
		lea	(file_compare_d_table,pc),a1
		bsr	file_compare_check_option
		bmi	file_compare_error
		move.b	d0,(~fc_cmp_time,a5)
		bra	file_compare_arg_exist

file_compare_d_table:
		.dc	str_same-$
		.dc	str_new-$
		.dc	str_old-$
		.dc	str_ignore-$
		.dc	str_diff-$
		.dc	str_fuzzy-$
		.dc	0

* -l (same/big/small/ignore/diff/fuzzy) : ファイルサイズ
file_compare_opt_l:
		lea	(file_compare_l_table,pc),a1
		bsr	file_compare_check_option
		bmi	file_compare_error
		move.b	d0,(~fc_cmp_size,a5)
		bra	file_compare_arg_exist

file_compare_l_table:
		.dc	str_same-$
		.dc	str_big-$
		.dc	str_small-$
		.dc	str_ignore-$
		.dc	str_diff-$
		.dc	str_fuzzy-$
		.dc	0

file_compare_v_table:
		.dc	str_off-$
		.dc	str_on-$
		.dc	0

file_compare_arg_exist:
		ori.b	#$01,(~fc_menu_req,a5)	;メニューは使用しない
file_compare_arg_next:
		subq.l	#1,d7
		bcc	file_compare_arg_loop

		tst.b	(~fc_menu_req,a5)
		bgt	@f

* 引数無指定時か、-menu 指定時はメニューを出す
		bsr	file_compare_menu
		bmi	file_compare_error	;キャンセル
@@:
		moveq	#MES_FCSIZ,d0		;冗長表示用にメッセージ文字列を
		lea	(~fc_fcsiz,a5),a1	;バッファに用意する
		bsr	file_compare_mes_copy
		moveq	#MES_FCTIM,d0
		lea	(~fc_fctim,a5),a1
		bsr	file_compare_mes_copy
		moveq	#MES_FCSZT,d0
		lea	(~fc_fcszt,a5),a1
		bsr	file_compare_mes_copy
		bra	@f
file_compare_mes_copy:
		jsr	(get_message)
		move.l	d0,a0
		STRCPY	a0,a1
		rts
@@:
		jsr	(get_dir_buf_a4_d7)
*		move	d7,(~fc_cur_file_c,a5)
		move	d7,d6
		beq	file_compare_no_cur_file

		lea	(a4),a3			;カーソル側ファイルバッファポインタ

		movea.l	(PATH_OPP,a6),a6
		jsr	(get_dir_buf_a4_d7)
		movea.l	(PATH_OPP,a6),a6
		move.l	a4,(~fc_opp_dirbuf,a5)
*		move	d7,(~fc_opp_file,a5)
		tst	d7
		beq	file_compare_no_opp_file

		moveq	#18+1+3,d0
		mulu	d7,d0
		move.l	d0,-(sp)
		DOS	_MALLOC
		move.l	d0,(sp)+
		bmi	file_compare_malloc_error

		move.l	d0,(~fc_opp_fn_ptr,a5)
		movea.l	d0,a1

		addq.l	#DIR_NAME,a4
		subq	#1,d7
@@:
		lea	(a4),a0			;ファイル名
		bsr	file_compare_to_fuzzy_filename
		lea	(18+1+3,a1),a1
		lea	(sizeof_DIR,a4),a4
		dbra	d7,@b

* a1.l	カーソル側加工済みファイル名バッファ
* a2.l	反対側〃
* a3.l	カーソル側ファイルバッファ
* a4.l	反対側〃

		jsr	(cursor_to_home_sub)
		cmp	(PATH_FILENUM,a6),d6
		beq	@f
		jsr	(cursor_down_sub)	;skip ".."
@@:
		moveq	#0,d7			;一致した数
file_compare_loop1:
		lea	(DIR_ATR,a3),a0
		moveq	#1<<MARK+1<<DIRECTORY+1<<VOLUME,d0
		and.b	(a0)+,d0		;既にマークされているファイルや
		bne	file_compare_next2	;ディレクトリは無視

		tst.b	(~fc_verbose,a5)
		beq	@f
		lea	(a0),a1			;冗長表示モード用に
		lea	(~fc_cur_fn2,a5),a2	;ファイル名を用意しておく
		jsr	(copy_dir_name_a1_a2)
@@:
*		lea	(DIR_NAME,a3),a0
		lea	(~fc_cur_fn,a5),a1
		bsr	file_compare_to_fuzzy_filename
		move	(a1)+,d6		;最初の2バイト

		movea.l	(~fc_opp_fn_ptr,a5),a2
		movea.l	(~fc_opp_dirbuf,a5),a4
file_compare_loop2:
		cmp	(a2)+,d6
		bne	file_compare_next0

		PUSH	a1-a2
		moveq	#1<<DIRECTORY+1<<VOLUME,d0
		and.b	(DIR_ATR,a4),d0
		bne	file_compare_next
	.rept	(18+1+3-2)/4
		cmpm.l	(a1)+,(a2)+		;残りの20バイト
		bne	file_compare_next
	.endm

* ファイル名が一致した
		bsr	file_compare_time
		bne	@f			;時刻も一致

		tst.b	(~fc_verbose,a5)
		beq	file_compare_next
		lea	(~fc_fctim,a5),a0
		bsr	file_compare_size
		bne	file_compare_missmatch
		lea	(~fc_fcszt,a5),a0
		bra	file_compare_missmatch
@@:
		bsr	file_compare_size
		bne	file_compare_match	;サイズも一致

		tst.b	(~fc_verbose,a5)
		beq	file_compare_next
		lea	(~fc_fcsiz,a5),a0
file_compare_missmatch:
		move.l	#2<<16+(WHITE+EMPHASIS),-(sp)
		DOS	_CONCTRL
		move.l	a0,(sp)			;メッセージを表示する
		DOS	_PRINT
		move.l	#2<<16+WHITE,(sp)
		DOS	_CONCTRL
		pea	(~fc_cur_fn2,a5)
		DOS	_PRINT
		pea	(str_crlf,pc)
		DOS	_PRINT
		lea	(12,sp),sp
		bra	file_compare_next

file_compare_match:
		tas	(DIR_ATR,a3)		;mark set
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinReverseLine)
		addq	#1,d7
		POP	a1-a2
		bra	file_compare_next2

file_compare_next:
		POP	a1-a2
file_compare_next0:
		lea	(18+1+3-2,a2),a2
		lea	(sizeof_DIR,a4),a4
		cmpi.b	#-1,(DIR_ATR,a4)
		bne	file_compare_loop2
file_compare_next2:
		lea	(sizeof_DIR,a3),a3
*		cmpi.b	#-1,(DIR_ATR,a3)
*		bne	file_compare_loop1

		jsr	(cursor_down_sub)
		tst.l	d0
		bne	file_compare_loop1

		move	d7,-(sp)
		beq	@f
		jsr	(print_mark_information)
@@:		move	(sp)+,d7

		move.l	(~fc_opp_fn_ptr,a5),-(sp)
		DOS	_MFREE
		addq.l	#4,sp

		bra	file_compare_end
file_compare_no_cur_file:
file_compare_no_opp_file:
file_compare_malloc_error:
file_compare_error:
		moveq	#0,d7
file_compare_end:
		move	(~fc_scrl_save,a5),(＄scrl)

		lea	(FC_WORK_SIZE,sp),sp
		move	d7,d0
		jmp	(set_status)
**		rts


* オプション解析 ------------------------------ *
* in	d7.l	残りの引数の数(0～)
*	a0.l	引数のアドレス
*	a1.l	オプションテーブル
* out	d0.l	オプション番号(負数ならエラー)
*	d7.l	残りの引数の数
*	a0.l	次の引数
*	ccr	<tst.l d0> の結果(少し違うが)

* オプションテーブルの構造:
*	.dc	option0-$	(返値=0)
*	.dc	option1-$	(返値=2)
*	.dc	option2-$	(返値=4)
*	.dc	0		(返値=-2)
*option0:
*	.dc.b	'option0',0
*option1:
*	.dc.b	'option1',0
*option2:
*	.dc.b	'option2',0

file_compare_check_option:
		PUSH	d1/a1-a3
@@:
		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
file_compare_check_option_error:
		moveq	#-1,d0
		bra	file_compare_check_option_end
@@:
		subq.l	#1,a0
		moveq	#-1,d0
file_compare_check_option_loop:
		addq.l	#1,d0
		move	(a1)+,d1
		beq	file_compare_check_option_error
		lea	(-2,a1,d1.w),a2
		lea	(a0),a3
@@:
		cmpm.b	(a2)+,(a3)+
		bne	file_compare_check_option_loop
		tst.b	(-1,a2)
		bne	@b
file_compare_check_option_end:
		POP	d1/a1-a3
@@:		tst.b	(a0)+
		bne	@b
		add.l	d0,d0
		rts


* ファイル名を比較しやすい形式に加工する ------ *
* in	a0.l	DIR_NAME
* in	a1.l	加工後ファイル名格納バッファアドレス
* break	d0.l

file_compare_to_fuzzy_filename:
		PUSH	d1-d2/a0-a2
		moveq	#$20,d2

		moveq	#0,d0
		move.b	(~fc_cmp_file,a5),d0
		beq	to_fuzzy_fn_exact
		subq.b	#2,d0
		beq	to_fuzzy_fn_ignore_case
*to_fuzzy_fn_fuzzy:
		lea	(a1),a2

;まず、'.' か NUL まで、小文字にしてコピー(空白は無視)
to_fuzzy_fn_fuzzy_loop:
		move.b	(a0)+,d0
		beq	to_fuzzy_fn_fuzzy_sep
		cmpi.b	#'.',d0
		beq	to_fuzzy_fn_fuzzy_sep
		cmpi.b	#SPACE,d0
		beq	to_fuzzy_fn_fuzzy_loop
		jsr	(is_alpha)
		bne	@f
		jsr	(is_mb)
		beq	1f
		move.b	d0,(a1)+
		move.b	(a0)+,d0
		beq	to_fuzzy_fn_fuzzy_sep
		move.b	d0,(a1)+
		bra	to_fuzzy_fn_fuzzy_loop
@@:
		or.b	d2,d0			;アルファベットは小文字にする
1:		move.b	d0,(a1)+
		bra	to_fuzzy_fn_fuzzy_loop
to_fuzzy_fn_fuzzy_sep:
		move.b	-(a1),d0
		cmp.l	a1,a2
		beq	to_fuzzy_fn_fuzzy_delend
		cmpi.b	#'_',d0
		beq	to_fuzzy_fn_fuzzy_sep
		cmpi.b	#'~',d0
		beq	to_fuzzy_fn_fuzzy_sep
to_fuzzy_fn_fuzzy_delend:
		addq.l	#1,a1
		move.b	(-1,a0),d0
		bne	1b			;"."

		moveq	#18+1+3,d0
		add.l	a2,d0
		sub.l	a1,d0
		subq	#1,d0
		bcs	to_fuzzy_fn_end
@@:
		clr.b	(a1)+
		dbra	d0,@b
		bra	to_fuzzy_fn_end


to_fuzzy_fn_exact:
		moveq	#(18+1+3)/2-1,d1
to_fuzzy_fn_exact_loop:
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		dbra	d1,to_fuzzy_fn_exact_loop
to_fuzzy_fn_end:
		POP	d1-d2/a0-a2
		rts


to_fuzzy_fn_ignore_case:
		moveq	#(18+1+3)-1,d1
to_fuzzy_fn_ignore_case_loop:
		move.b	(a0)+,d0
		jsr	(is_alpha)
		bne	@f
		jsr	(is_mb)
		beq	1f
		move.b	d0,(a1)+
		subq	#1,d1
		bcs	to_fuzzy_fn_end
		bra	1f
@@:
		or.b	d2,d0			;アルファベットは小文字にする
1:		move.b	d0,(a1)+
		dbra	d1,to_fuzzy_fn_ignore_case_loop
		bra	to_fuzzy_fn_end


* タイムスタンプの比較 ------------------------ *
* in	a3.l	カーソル側ファイルバッファ
*	a4.l	反対側〃
*	a5.l	ワーク
* out	d0.l	0:不一致 1:一致
*	ccr	<tst.l d0> の結果
* break	d1-d2

file_compare_time:
		move.l	(DIR_TIME,a3),d1
		move.l	(DIR_TIME,a4),d2
		swap	d1			;date | time
		swap	d2			;
		moveq	#0,d0
		move.b	(~fc_cmp_time,a5),d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	file_compare_time_same-@b
		.dc	file_compare_time_new-@b
		.dc	file_compare_time_old-@b
		.dc	file_compare_time_ignore-@b
		.dc	file_compare_time_diff-@b
		.dc	file_compare_time_fuzzy-@b

file_compare_time_fuzzy:
		clr	d1			;時刻は無視する
		clr	d2			;
file_compare_time_same:
		cmp.l	d1,d2
		bne	file_compare_time_false
file_compare_time_ignore:
file_compare_time_true:
		moveq	#1,d0
		rts

file_compare_time_new:
		cmp.l	d1,d2
		bcs	file_compare_time_true
file_compare_time_false:
		moveq	#0,d0
		rts

file_compare_time_old:
		cmp.l	d1,d2
		bhi	file_compare_time_true
		moveq	#0,d0
		rts

file_compare_time_diff:
		cmp.l	d1,d2
		bne	file_compare_time_true
		moveq	#0,d0
		rts


* ファイルサイズの比較 ------------------------ *
* in	a3.l	カーソル側ファイルバッファ
*	a4.l	反対側〃
*	a5.l	ワーク
* out	d0.l	0:不一致 1:一致
*	ccr	<tst.l d0> の結果
* break	d1-d2

file_compare_size:
		move.l	(DIR_SIZE,a3),d1
		move.l	(DIR_SIZE,a4),d2
		moveq	#0,d0
		move.b	(~fc_cmp_size,a5),d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	file_compare_size_same-@b
		.dc	file_compare_size_big-@b
		.dc	file_compare_size_small-@b
		.dc	file_compare_size_true-@b
		.dc	file_compare_size_diff-@b
		.dc	file_compare_size_fuzzy-@b

file_compare_size_same:
		cmp.l	d1,d2
		bne	file_compare_size_false
file_compare_size_true:
		moveq	#1,d0
		rts

file_compare_size_big:
		cmp.l	d1,d2
		bcs	file_compare_size_true
file_compare_size_false:
		moveq	#0,d0
		rts

file_compare_size_small:
		cmp.l	d1,d2
		bhi	file_compare_size_true
		moveq	#0,d0
		rts

file_compare_size_diff:
		cmp.l	d1,d2
		bne	file_compare_size_true
		moveq	#0,d0
		rts

file_compare_size_fuzzy:
		sub.l	d1,d2
		bcc	@f
		neg.l	d2
@@:		moveq	#0,d0
		move	(＄fuzy),d0
		cmp.l	d0,d2
		bls	file_compare_size_true
		moveq	#0,d0
		rts


* 比較モード選択メニュー ---------------------- *
* in	a2.l	タイトルのアドレス
*	a5.l	ローカルエリア
* out	d0.l	0:確定 -1:取消

file_compare_menu:
		PUSH	d1-d2/d5-d7/a0-a1
		lea	(subwin_menu,pc),a0
		move.l	a2,(SUBWIN_TITLE,a0)
		moveq	#16,d0
		add	(PATH_WINRL,a6),d0
		move	d0,(SUBWIN_X,a0)

		jsr	(WinOpen)
		move	d0,d5

* ウィンドウの中身を表示する
		lea	(menu_str,pc),a1
		moveq	#2,d2			;Y
@@:
		moveq	#3,d1			;X
		bsr	fc_locate_print
		addq	#1,d2
		tst.b	(a1)
		bne	@b

		moveq	#YELLOW,d1
		jsr	(WinSetColor)

		bsr	fc_menu_print_f
		bsr	fc_menu_print_d
		bsr	fc_menu_print_l
		bsr	fc_menu_print_v

		moveq	#0*2,d7			;現在の位置(0*2～3*2)
*		moveq	#0,d7
*		move.b	(AK_DOWN),d7		;最初は行入力なので不要
fc_menu_loop:
		bsr	fc_menu_underline	;下線描画
		move	(fc_menu_job_tbl,pc,d7.w),d0
		jsr	(fc_menu_job_tbl,pc,d0.w)
		bsr	fc_menu_underline	;下線消去

		moveq	#0,d1
		cmpi.b	#CR,d6
		beq	fc_menu_end
		moveq	#-1,d1
		cmpi.b	#ESC,d6
		beq	fc_menu_end
		cmp.b	(AK_UP),d6
		beq	fc_menu_up
*		cmp.b	(AK_DOWN),d6
*		bne	fc_menu_loop
*fc_menu_down:
		addq	#2,d7
		cmpi	#3*2,d7
		bls	fc_menu_loop
		moveq	#0*2,d7			;一番下で↓なら一番上に移動する
		bra	fc_menu_loop
fc_menu_up:
		subq	#2,d7
		bcc	fc_menu_loop
		moveq	#3*2,d7			;一番上で↑なら一番下に移動する
		bra	fc_menu_loop

fc_menu_job_tbl:
@@:		.dc	fc_menu_fn-@b		;ファイル名
		.dc	fc_menu_ts-@b		;タイムスタンプ
		.dc	fc_menu_len-@b		;サイズ
		.dc	fc_menu_verb-@b		;バーボーズ

fc_menu_end:
		move	d5,d0
		jsr	(WinClose)

		move.l	d1,d0
		POP	d1-d2/d5-d7/a0-a1
		rts


fc_menu_underline:
		moveq	#3,d1			;X
		move.l	d7,d2
		lsr	#1,d2			;Y
		addq	#2,d2
		bsr	fc_locate

		moveq	#YELLOW,d1
		moveq	#13,d2			;下線の桁数
		tst	d7
		bne	@f
		moveq	#10,d2			;"File Name " だけ短い
@@:		jmp	(WinUnderLine2)
**		rts


* fcm_menu_～ : 行ごとの処理ルーチン.
* in	a5.l	ローカルエリア
* out	d6.b	処理ルーチン脱出時のキー(CR/ESC/AK_UP/AK_DOWN)
* break	d0-d3/a0-a2

* fc_menu_print_～ : -f/-d/-l/-v それぞれの選択肢を表示する.
* break	d0-d3/a1

fc_menu_fn:
		lea	(~fc_cmp_file,a5),a0
		lea	(file_compare_f_table,pc),a1
		bsr	fc_menu_sub
fc_menu_print_f:
		lea	(file_compare_f_table,pc),a1
		move.b	(~fc_cmp_file,a5),d0
		moveq	#2,d2			;Y
		moveq	#11,d3			;表示幅
		bra	fc_menu_print_sub

fc_menu_ts:
		lea	(~fc_cmp_time,a5),a0
		lea	(file_compare_d_table,pc),a1
		bsr	fc_menu_sub
fc_menu_print_d:
		lea	(file_compare_d_table,pc),a1
		move.b	(~fc_cmp_time,a5),d0
		moveq	#3,d2
		bra	@f

fc_menu_len:
		lea	(~fc_cmp_size,a5),a0
		lea	(file_compare_l_table,pc),a1
		bsr	fc_menu_sub
fc_menu_print_l:
		lea	(file_compare_l_table,pc),a1
		move.b	(~fc_cmp_size,a5),d0
		moveq	#4,d2
		bra	@f

fc_menu_verb:
		lea	(~fc_verbose,a5),a0
		lea	(file_compare_v_table,pc),a1
		bsr	fc_menu_sub
fc_menu_print_v:
		lea	(file_compare_v_table,pc),a1
		move.b	(~fc_verbose,a5),d0
		moveq	#5,d2
@@:
		moveq	#8,d3
fc_menu_print_sub:
		ext	d0
		adda	d0,a1
		adda	(a1),a1			;文字列

		moveq	#26,d1
		sub	d3,d1			;[] 内左端の桁位置

		move.l	a1,-(sp)
		lea	(str_spc11+11,pc),a1
		suba	d3,a1
		bsr	fc_locate_print		;消去
		movea.l	(sp)+,a1

		STRLEN	a1,d0
		sub	d0,d3
		lsr	#1,d3
		add	d3,d1			;センタリングする

		bra	fc_locate_print		;選択肢を表示
**		rts


fc_locate_print:
		bsr	fc_locate
fc_print:
		jmp	(WinPrint)
**		rts

fc_locate:
		move	d5,d0
		jmp	(WinSetCursor)
**		rts


* メニュー下請け
* in	a0.l	フラグアドレス
*	a1.l	テーブルアドレス
*	a5.l	ローカルエリア
*	(sp).l	選択肢表示ルーチンのアドレス
* out	d6.b	処理ルーチン脱出時のキー(CR/ESC/AK_UP/AK_DOWN)
* break	d0-d3/a0-a2

fc_menu_sub:
		movea.l	(sp)+,a2		;選択肢表示ルーチン
fc_menu_sub_loop:
		jsr	(dos_inpout)
		move.l	d0,d6
		moveq	#0,d0
		cmpi.b	#CR,d6
		beq	@f
		cmpi.b	#ESC,d6
		beq	@f
		cmp.b	(AK_UP),d6
		beq	@f
		cmp.b	(AK_DOWN),d6
@@:		beq	fc_menu_sub_end

		cmp.b	(AK_LEFT),d6
		beq	fc_menu_sub_left
		cmp.b	(AK_RIGHT),d6
		beq	fc_menu_sub_right
		cmpi.b	#SPACE,d6		;スペースは→と同じ
		bne	fc_menu_sub_loop
fc_menu_sub_right:
		move.b	(a0),d0
		addq.b	#2,d0
		tst	(a1,d0.w)
		bne	fc_menu_sub_chg
		moveq	#0,d0			;最初の選択肢に戻る
		bra	fc_menu_sub_chg
fc_menu_sub_left:
		move.b	(a0),d0
		subq.b	#2,d0
		bcc	fc_menu_sub_chg
@@:
		addq.b	#2,d0			;最後の選択肢に遡る
		tst	(2,a1,d0.w)
		bne	@b
fc_menu_sub_chg:
		move.b	d0,(a0)			;フラグ更新
		move.l	a1,-(sp)
		jsr	(a2)			;選択肢の表示を更新する
		movea.l	(sp)+,a1
		bra	fc_menu_sub_loop
fc_menu_sub_end:
		rts


* Data Section -------------------------------- *

*		.data
		.even

subwin_menu:
		SUBWIN	0,2,30,5,NULL,NULL

menu_str:
		.dc.b	'File name  [           ]',0
		.dc.b	'Timestamp     [        ]',0
		.dc.b	'Length        [        ]',0
		.dc.b	'Verbose       [        ]',0
		.dc.b	0

str_spc11:	.dc.b	'           ',0
str_exact:	.dc.b	'exact',0
str_ignore_c:	.dc.b	'ignore-case',0
str_fuzzy:	.dc.b	'fuzzy',0
str_same:	.dc.b	'same',0
str_diff:	.dc.b	'diff',0
str_ignore:	.dc.b	'ignore',0
str_new:	.dc.b	'new',0
str_old:	.dc.b	'old',0
str_big:	.dc.b	'big',0
str_small:	.dc.b	'small',0
str_off:	.dc.b	'off',0
str_on:		.dc.b	'on',0
str_crlf:	.dc.b	CR,LF,0


* Block Storage Section ----------------------- *

*		.bss
		.even


		.end

* End of File --------------------------------- *
