# outside.s - misc functions
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

* ─────────────────────────────────────────
*	本来 mint.s に含まれるべきものだが、本体編集、アセンブル等の負荷を
*	軽減するために、以下の条件でこちらに移行した.
*	・原則的に ひとつの内部命令が移動の一単位である
*	・mint.s 内ルーチンへの依存度が比較的低いもの、
*	  即ち mint.s の書き換えにより影響を受け難いということ
*	・移行によってある程度の容量削減が見込まれるもの
*	・書き換えられる可能性のあるラベル名を外部参照にあまり含まないもの
* ──────────────────────────────────────────


* Include File -------------------------------- *

		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	sysval.def

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac
		.include	scsicall.mac
		.include	twoncall.mac


* Global Symbol ------------------------------- *

* look.s
		.xref	iocs_key_flush
* menu.s
		.xref	menu_sub
* madoka3.s
		.xref	＠buildin,＠status
		.xref	execute_quick_no,free_token_buf
		.xref	init_schr_tbl
* mint.s
		.xref	mint_start
		.xref	interrupt_window_print
		.xref	＆mpu_power,＆clear_and_redraw
		.xref	＆cd,chdir_a1
		.xref	search_cursor_file
		.xref	twon_getopt,mint_getenv
		.xref	ctypetable,is_xdigt
		.xref	correct_system_value
		.xref	print_regexp_compile_error
		.xref	update_periodic_display,dos_kflush
		.xref	MpuType,oldpwd_buf
		.xref	sys_val_name,sys_val_table
		.xref	kq_buffer,時間_実行前
		.xref	AK_UP,AK_DOWN,AK_LEFT,AK_RIGHT
* patternmatch.s
		.xref	init_i_c_option,take_i_c_option
		.xref	_fre_compile,_fre_match,_ignore_case


* Constant ------------------------------------ *

DIRSTACK_NUM:	.equ	4
DIRSTACK_SIZE:	.equ	64


* Text Section -------------------------------- *

		.cpu    68000

		.text
		.even


*************************************************
*		&equ=&strcmp			*
*************************************************

＆equ::
		clr.l	(_ignore_case)
		subq.l	#2,d7
		bcs	equ_error		;引数が 2 個未満
		bra	equ_arg_next
equ_arg_loop:
		jsr	(take_i_c_option)
		beq	equ_arg_next
		tst.b	(a0)+
		bne	equ_error		;不正な引数/オプション
equ_arg_next:
		subq.l	#1,d7
		bcc	equ_arg_loop

		lea	(a0),a1			;a1 = 文字列１
@@:		tst.b	(a0)+
		bne	@b
		lea	(a0),a2			;a2 = 文字列２

		moveq	#1,d0
		bsr	strcmp_a1_a2_ic
		beq	equ_end
equ_error:
		moveq	#0,d0
equ_end:
		bra	set_status
**		rts


* _ignore_case に従って文字列比較を呼び出す
strcmp_a1_a2_ic::
		tst.l	(_ignore_case)
		bne	stricmp_a1_a2
		bra	strcmp_a1_a2


* 文字列比較(大文字小文字区別あり)
* in	a1.l	文字列のアドレス
*	a2.l	〃
* out	ccrZ	1:一致 0:不一致

strcmp_a1_a2::
		PUSH	a1-a2
@@:
		cmpm.b	(a1)+,(a2)+
		bne	@f
		tst.b	(-1,a1)
		bne	@b
@@:
		POP	a1-a2
		rts


* 文字列比較(大文字小文字区別なし)
* in	a1.l	文字列のアドレス
*	a2.l	〃
* out	ccrZ	1:一致 0:不一致

stricmp_a1_a2::
		PUSH	d1-d2/a1-a2
stricmp_a1_a2_loop:
		move.b	(a2)+,d2
		move.b	(a1)+,d1
		bpl	stricmp_a1_a2_ascii
		cmpi.b	#$a0,d1
		bcs	stricmp_a1_a2_mb
		cmpi.b	#$e0,d1
		bls	stricmp_a1_a2_kana
stricmp_a1_a2_mb:
		cmp.b	d1,d2
		bne	stricmp_a1_a2_end
		move.b	(a2)+,d2
		move.b	(a1)+,d1
		bra	stricmp_a1_a2_kana
stricmp_a1_a2_ascii:
		cmp.b	d1,d2
		beq	stricmp_a1_a2_next
		andi.b	#$df,d1
		cmpi.b	#'A',d1
		bcs	stricmp_a1_a2_end
		cmpi.b	#'Z',d1
		bhi	stricmp_a1_a2_end
		andi.b	#$df,d2
stricmp_a1_a2_kana:
		cmp.b	d1,d2
		bne	stricmp_a1_a2_end
stricmp_a1_a2_next:
		tst.b	d1
		bne	stricmp_a1_a2_loop
stricmp_a1_a2_end:
		POP	d1-d2/a1-a2
unset_error:
		rts


*************************************************
*		&unset				*
*************************************************

UNSET_REGEXP_SIZE:	.equ	1024*2

＆unset::
		bsr	set_status_0
		tst.l	d7
		beq.s	unset_error

		bsr	cat_regexp_arg
		lea	(Buffer),a5

		clr.l	(_ignore_case)

		move.l	a0,-(sp)		;pattern
		pea	(UNSET_REGEXP_SIZE/2)	;size
		pea	(a5)			;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	unset_compile_ok

		jmp	(print_regexp_compile_error)
**		rts
unset_compile_ok:
		moveq	#0,d7			;マッチした数
		lea	(user_value_tbl),a0	;read
		lea	(a0),a1			;write
unset_loop:
		tst.b	(a0)
		beq	unset_end

		lea	(a0),a2
@@:		cmpi.b	#$01,(a2)+
		bne	@b
		clr.b	-(a2)			;.dc.b	'変数名',0,'値',0

		PUSH	a0-a2
		pea	(a0)			;string
		pea	(a5)			;compiled pattern
		jsr	(_fre_match)
		addq.l	#8,sp

		POP	a0-a2
		move.b	#$01,(a2)
		tst.l	d0
		bne	unset_match

		STRCPY	a0,a1			;今の変数はそのままコピー
		bra	unset_loop
unset_match:
		tst.b	(a0)+			;今の変数はコピーしない
		bne	unset_match
		addq	#1,d7
		bra	unset_loop
unset_end:
		clr.b	(a1)
		move	d7,d0
		bra	set_status
**		rts


* 分割された正規表現パターンを連結する.
* in	d7.l	引数の数
*	a0.l	引数列
*		.dc.b	'foo',0,'bar',0
*			↓
*		.dc.b	'foo|bar',0

cat_regexp_arg::
		PUSH	d0-d1/d7/a0-a1
		lea	(a0),a1
		moveq	#SPACE,d1
cat_regexp_arg_loop:
		move.b	(a0)+,d0
		cmp.b	d1,d0
		bne	@f
1:		cmp.b	(a0)+,d1		;連続する空白は一つにする
		beq	1b
		subq.l	#1,a0
		move.b	#'|',(a1)+
		bra	cat_regexp_arg_loop
@@:
		move.b	d0,(a1)+
		bne	cat_regexp_arg_loop
		move.b	#'|',(-1,a1)
		subq.l	#1,d7
		bne	cat_regexp_arg_loop
		clr.b	-(a1)
		POP	d0-d1/d7/a0-a1
		rts


*************************************************
*		&set				*
*************************************************

＆set::
		moveq	#0,d6			;-1 = &clear-and-redraw を呼び出す
		tst.l	d7
		beq	set_error
set_option_loop:
		cmpi.b	#'-',(a0)
		bne	set_no_option
		addq.l	#1,a0
		cmpi.b	#'c',(a0)+
		bne	set_error
		tst.b	(a0)+
		bne	set_error
		moveq	#-1,d6
		subq.l	#1,d7
		bne	set_option_loop
set_no_option:
		lea	(a0),a2
@@:		tst.b	(a2)+
		bne	@b

		subq.l	#2,d7			;残りは変数名と値
		beq	set_arg2
		bcs	set_error

		lea	(a2),a1			;値が複数ある場合は空白で繋げる
set_cat_loop:
		tst.b	(a1)+
		bne	set_cat_loop
		move.b	#SPACE,-(a1)
		subq.l	#1,d7
		bne	set_cat_loop
set_arg2:
		lea	(a0),a1			;a0=変数名
		bsr	search_system_value
		beq	set_user_value
		movea.l	d0,a0

		lea	(a2),a1
		bsr	atoi_a1
		bne	set_error
		tst.b	(a1)			;念の為チェック
		bne	set_error
cal_set_system_value:
		cmpi.l	#$ffff,d0
		bhi	set_error

		move	d0,(a0)
		move.l	d6,-(sp)
		jsr	(correct_system_value)
		jsr	(init_schr_tbl)
		tst.l	(sp)+
		beq	@f			;-c は指定されていない
		jsr	(＆clear_and_redraw)
@@:		bra	set_status_1

set_user_value:
		lea	(a1),a2
@@:		tst.b	(a2)+
		bne	@b
		bsr	set_user_value_a1_a2
		bra	set_status
**		rts
set_error:
		bra	set_status_0
**		rts


* システム変数を検索する
* in	a1.l	変数名のアドレス
* out	d0.l	変数のアドレス(NULL ならエラー)
*	ccr	<tst.l d0> の結果

search_system_value::
		PUSH	d1/a0-a1
		moveq	#4-1,d1
@@:
		lsl.l	#8,d0			;変数名4バイト
		move.b	(a1)+,d0
		dbeq	d1,@b
		beq	search_system_value_error
		tst.b	(a1)
		bne	search_system_value_error

		lea	(sys_val_name),a0
		lea	(sys_val_table),a1
search_system_value_loop:
		cmp.l	(a0)+,d0
		beq	search_system_value_found
		addq.l	#2,a1
		tst.b	(a0)
		bne	search_system_value_loop
search_system_value_error:
		moveq	#0,d0
		bra	search_system_value_end
search_system_value_found:
		move.l	a1,d0
search_system_value_end:
		POP	d1/a0-a1
		rts


USER_VAL_SIZE:	.equ	1024*6

* ユーザ変数 _ ($ARC)を設定する
set_user_value_arg_a2::
		PUSH	a0-a4
		lea	(underline,pc),a1
		bra	@f

* ユーザ変数 & ($MATCH)を設定する
set_user_value_match_a2::
		PUSH	a0-a4
		lea	(ampersand,pc),a1
		bra	@f

* ユーザ変数を設定する
* in	a1.l	変数名のアドレス
*	a2.l	設定する文字列のアドレス
* out	d0.l	1:正常終了 0:異常終了
*	ccr	<tst.l d0> の結果

set_user_value_a1_a2::
		PUSH	a0-a4
@@:		bsr	unset_user_value_a1

		lea	(user_value_tbl),a0
		lea	(USER_VAL_SIZE,a0),a3
		bra	1f
@@:
		tst.b	(a0)+			;変数リスト末尾まで移動
		bne	@b
1:		tst.b	(a0)+
		bne	@b
		subq.l	#1,a0

		STRLEN	a1,d0
		lea	(2,a0,d0.l),a4		;2=strlen("=" "\0")
		STRLEN	a2,d0
		adda.l	d0,a4			;追加後の変数リスト末尾
		cmpa.l	a3,a4
		bhi	set_user_value_a1_a2_error

		STRCPY	a1,a0
		addq.b	#$01,(-1,a0)		;move.b #$01,(-1,a0)
		STRCPY	a2,a0
		clr.b	(a0)

		moveq	#1,d0
@@:		POP	a0-a4
		rts
set_user_value_a1_a2_error:
		moveq	#0,d0
		bra	@b


* ユーザ変数 _ ($ARC)を取り消す
unset_user_value_arg::
		PUSH	a0-a1
		lea	(underline,pc),a1
		bra	@f

* ユーザ変数 & ($MATCH)を取り消す
unset_user_value_match::
		PUSH	a0-a1
		lea	(ampersand,pc),a1
		bra	@f

* ユーザ変数を取り消す
* in	a1.l	変数名のアドレス
* out	d0.l	0:正常終了 -1:異常終了
*	ccr	<tst.l d0> の結果

unset_user_value_a1::
		PUSH	a0-a1
@@:
		bsr	search_user_value_a1
		beq	unset_user_value_a1_error

		movea.l	d0,a0
		movea.l	d0,a1
@@:
		tst.b	(a0)+
		bne	@b
@@:
		STRCPY	a0,a1			;後の変数を前に詰める
		move.b	(a0)+,(a1)+
		bne	@b			;まだ変数が続いている

		moveq	#1,d0
@@:		POP	a0-a1
		rts
unset_user_value_a1_error:
		moveq	#0,d0
		bra	@b


* ユーザ変数 _ ($ARC)を検索する
search_user_value_arg::
		PUSH	a0-a3
		lea	(underline,pc),a1
		bra	@f

* ユーザ変数 & ($MATCH)を検索する
search_user_value_match::
		PUSH	a0-a3
		lea	(ampersand,pc),a1
		bra	@f

* ユーザ変数を検索する
* in	a1.l	変数名のアドレス
* out	d0.l	変数のアドレス(NULL ならエラー)
*	ccr	<tst.l d0> の結果

search_user_value_a1::
		PUSH	a0-a3
@@:
		lea	(user_value_tbl),a0
		moveq	#$01,d0
		bra	search_user_val_a1_start
search_user_val_a1_loop:
		lea	(a0),a2
		lea	(a1),a3
@@:
		cmpm.b	(a2)+,(a3)+
		bne	search_user_val_a1_next
		cmp.b	(a2),d0
		beq	search_user_val_a1_eq
		tst.b	(a3)
		bne	@b
		bra	search_user_val_a1_next
search_user_val_a1_eq:
		tst.b	(a3)
		bne	search_user_val_a1_next

		move.l	a0,d0			;変数が見つかった
		bra	search_user_val_a1_end
search_user_val_a1_next:
		tst.b	(a0)+
		bne	search_user_val_a1_next
search_user_val_a1_start:
		tst.b	(a0)
		bne	search_user_val_a1_loop
		moveq	#0,d0			;見つからなかった
search_user_val_a1_end:
		POP	a0-a3
		rts


underline:	.dc.b	'_',0
ampersand:	.dc.b	'&',0
		.even

* ユーザ変数バッファの構造
*	.dc.b	'変数名a',$01,'値a',0
*	.dc.b	'変数名b',$01,'値b',0
*	.dc.b	0


*************************************************
*		&cal				*
*************************************************

＆cal::
		moveq	#0,d6			;-1 なら &clear-and-redraw を呼び出す
		tst.l	d7
		beq	cal_error
cal_option_loop:
		cmpi.b	#'-',(a0)
		bne	cal_no_option
		addq.l	#1,a0
		cmpi.b	#'c',(a0)+
		bne	cal_error
		tst.b	(a0)+
		bne	cal_error
		moveq	#-1,d6
		subq.l	#1,d7
		bne	cal_option_loop
cal_no_option:
		subq.l	#1,d7
		bls	cal_error

		lea	(a0),a5			;値を返す変数名
@@:		tst.b	(a0)+
		bne	@b

		lea	(a0),a1			;read ptr
		lea	(a0),a2			;write ptr
		bra	cal_catarg_next
cal_catarg_loop:
		cmpi.b	#TAB,d0			;分割された引数を連結する
		beq	cal_catarg_next
		cmpi.b	#SPACE,d0
		beq	cal_catarg_next
		move.b	d0,(a2)+
cal_catarg_next:
		move.b	(a1)+,d0
		bne	cal_catarg_loop
		subq.l	#1,d7
		bne	cal_catarg_next
		clr.b	(a2)

		bsr	cal_expression
		bmi	cal_error
		tst.b	(a0)
		bne	cal_error

		move.l	d1,d7
		lea	(a5),a1
		bsr	search_system_value
		beq	@f

		movea.l	d0,a0			;システム変数にセット
		move.l	d7,d0
		bra	cal_set_system_value
@@:
		lea	(-12,sp),sp
		lea	(sp),a0
		move.l	d7,d0
		FPACK	__LTOS
		lea	(sp),a2
		bsr	set_user_value_a1_a2
		lea	(12,sp),sp
		bra	set_status
**		rts
cal_error:
		bra	set_status_0
**		rts


* 数式演算ルーチン(再帰的下向き構文解析)
* in	a0.l	文字列のアドレス
* out	d0.l	エラーコード
*	d1.l	数値

# 対応演算子(評価優先順位順)
# ( )
# + - ! ~
# * / % << >>
# + -
# == != < > <= >=
# &
# ^ |
# && ||
# ?:

cal_number:
		move.l	a1,-(sp)
cal_number_skip:
		move.b	(a0)+,d0
		cmpi.b	#'+',d0
		beq	cal_number_skip		;+x = x
		cmpi.b	#'-',d0
		beq	cal_number_minus
		cmpi.b	#'!',d0
		beq	cal_number_logical_not
		cmpi.b	#'~',d0
		beq	cal_number_not
		cmpi.b	#'$',d0
		beq	@f
		subi.b	#'0',d0
		cmpi.b	#9,d0
		bhi	cal_number_error
@@:
		subq.l	#1,a0
		bsr	atoi_a0
		bne	cal_number_error

		move.l	d0,d1
cal_number_end:
		moveq	#0,d0
		movea.l	(sp)+,a1
		rts
cal_number_minus:
*		cmp.b	(a0)+,d0
*		beq	cal_number_skip		;--x = x
*		subq.l	#1,a0
		bsr	cal_factor
		bmi	cal_number_error
		neg.l	d1
		bra	cal_number_end
cal_number_logical_not:
		bsr	cal_factor
		bmi	cal_number_error
		tst.l	d1
		beq	1f
		moveq	#0,d1			;真(0以外)→偽(0)
		bra	cal_number_end
1:		moveq	#1,d1			;偽(0)→真(1)
		bra	cal_number_end
cal_number_not:
*		cmp.b	(a0)+,d0
*		beq	cal_number_skip		;~~x = x
*		subq.l	#1,a0
		bsr	cal_factor
		bmi	cal_number_error
		not.l	d1
		bra	cal_number_end
cal_number_error:
		moveq	#-1,d0
		movea.l	(sp)+,a1
		rts

cal_factor:
		cmpi.b	#'(',(a0)		;式の値か数値を返す
		beq	cal_factor_exp

		bra	cal_number
**		rts
cal_factor_exp:
		addq.l	#1,a0
		bsr	cal_expression
		bmi	cal_factor_error
		cmpi.b	#')',(a0)+
		bne	cal_factor_error
		moveq	#0,d0
		rts
cal_factor_error:
		moveq	#-1,d0
		rts

;項の値を計算する
cal_term:
		move.l	a1,-(sp)
		bsr	cal_factor		;因子同士を演算して返す
		bmi	cal_term_error
cal_term_loop:
		move.b	(a0)+,d0
		lea	(cal_term_mul,pc),a1
		cmpi.b	#'*',d0
		beq	cal_term_muldivmod
		addq.l	#cal_term_div-cal_term_mul,a1
		cmpi.b	#'/',d0
		beq	cal_term_muldivmod
		addq.l	#cal_term_mod-cal_term_div,a1
		cmpi.b	#'%',d0
		beq	cal_term_muldivmod

		lea	(cal_term_shl,pc),a1
		cmpi.b	#'<',d0
		beq	@f
		addq.l	#cal_term_shr-cal_term_shl,a1
		cmpi.b	#'>',d0
		bne	1f
@@:		cmp.b	(a0)+,d0
		beq	cal_term_shlshr
		subq.l	#1,a0
1:
		subq.l	#1,a0
		moveq	#0,d0
		movea.l	(sp)+,a1
		rts
cal_term_muldivmod:
		move.l	d1,-(sp)
		bsr	cal_factor
		bmi	cal_term_error2
		move.l	(sp)+,d0
		jmp	(a1)
cal_term_mul:	FPACK	__LMUL			;x*y
		bra	@f
cal_term_div:	FPACK	__LDIV			;x/y
		bra	@f
cal_term_mod:	FPACK	__LMOD			;x mod y
@@:		bcs	cal_term_error
		move.l	d0,d1
		bra	cal_term_loop
cal_term_shlshr:
		move.l	d1,-(sp)
		bsr	cal_factor
		bmi	cal_term_error2
		move.l	(sp)+,d0
		jmp	(a1)
cal_term_shl:	lsl.l	d1,d0
		bra	@f
cal_term_shr:	lsr.l	d1,d0
@@:		move.l	d0,d1
		bra	cal_term_loop
cal_term_error2:
		addq.l	#4,sp
cal_term_error:
		moveq	#-1,d0
		movea.l	(sp)+,a1
		rts

;加減算(+,-)
cal_expression7:
		move.l	a1,-(sp)
		bsr	cal_term		;項同士を演算して返す
		bmi	cal_expression_error
cal_expression7_loop:
		move.b	(a0)+,d0
		lea	(cal_expression7_minus,pc),a1
		cmpi.b	#'-',d0
		beq	cal_expression7_plusminus
		addq.l	#cal_expression7_plus-cal_expression7_minus,a1
		cmpi.b	#'+',d0
		bne	cal_expression_end
cal_expression7_plusminus:
		move.l	d1,-(sp)
		bsr	cal_term
		bmi	cal_expression_error2
		jmp	(a1)
cal_expression7_minus:
		neg.l	d1			;x-y = x + (-y)
cal_expression7_plus:
		add.l	(sp)+,d1
		bra	cal_expression7_loop
cal_expression_end:
		subq.l	#1,a0
		moveq	#0,d0
		movea.l	(sp)+,a1
		rts
cal_expression_error2:
		addq.l	#4,sp
cal_expression_error:
		moveq	#-1,d0
		movea.l	(sp)+,a1
		rts

;比較(== != < > <= >=)
cal_expression6:
		move.l	a1,-(sp)
		bsr	cal_expression7
		bmi	cal_expression_error
cal_expression6_loop:
		move.b	(a0)+,d0
		lea	(cal_expression6_eq,pc),a1
		cmpi.b	#'=',d0
		beq	cal_expression6_eqne
		addq.l	#cal_expression6_ne-cal_expression6_eq,a1
		cmpi.b	#'!',d0
		beq	cal_expression6_eqne

		addq.l	#cal_expression6_ge-cal_expression6_ne,a1
		cmpi.b	#'<',d0
		bne	@f
		cmp.b	(a0),d0
		beq	cal_expression_end	;<<なら無視
		cmpi.b	#'=',(a0)
		beq	cal_expression6_gele	;<=
		addq.l	#cal_expression6_gt-cal_expression6_ge,a1
		bra	cal_expression6_gtlt	;<
@@:
		addq.l	#cal_expression6_le-cal_expression6_ge,a1
		cmpi.b	#'>',d0
		bne	cal_expression_end
		cmp.b	(a0),d0
		beq	cal_expression_end	;>>なら無視
		cmpi.b	#'=',(a0)
		beq	cal_expression6_gele	;>=
		addq.l	#cal_expression6_lt-cal_expression6_le,a1
		bra	cal_expression6_gtlt	;>
cal_expression6_eqne:
		cmpi.b	#'=',(a0)
		bne	cal_expression_end	;== !=ではなかった
cal_expression6_gele:
		addq.l	#1,a0			;<= >=は確認済み
cal_expression6_gtlt:
		move.l	d1,-(sp)		;< >
		bsr	cal_expression7
		bmi	cal_expression_error2
		cmp.l	(sp)+,d1
		jmp	(a1)
cal_expression6_eq:
		beq	1f
		bra	@f
cal_expression6_ne:
		bne	1f
		bra	@f
cal_expression6_ge:
		bge	1f
		bra	@f
cal_expression6_gt:
		bgt	1f
		bra	@f
cal_expression6_le:
		ble	1f
		bra	@f
cal_expression6_lt:
		blt	1f
@@:		moveq	#0,d1
		bra	cal_expression6_loop
1:		moveq	#1,d1
		bra	cal_expression6_loop

;ビット論理積(&)
cal_expression5:
		move.l	a1,-(sp)
		bsr	cal_expression6
		bmi	cal_expression_error
cal_expression5_loop:
		move.b	(a0)+,d0
		cmpi.b	#'&',d0
		bne	cal_expression_end
		cmp.b	(a0),d0
		beq	cal_expression_end	;&&なら無視
*cal_expression5_and:
		move.l	d1,-(sp)
		bsr	cal_expression6
		bmi	cal_expression_error2
		and.l	(sp)+,d1
		bra	cal_expression5_loop

;ビット論理和、ビット排他的論理和(|,^)
cal_expression4:
		move.l	a1,-(sp)
		bsr	cal_expression5
		bmi	cal_expression_error
cal_expression4_loop:
		move.b	(a0)+,d0
		lea	(cal_expression4_or,pc),a1
		cmpi.b	#'|',d0
		beq	@f
		addq.l	#cal_expression4_xor-cal_expression4_or,a1
		cmpi.b	#'^',d0
		bne	cal_expression_end
@@:		cmp.b	(a0),d0
		beq	cal_expression_end	;|| ^^ なら無視
*cal_expression4_orxor:
		move.l	d1,-(sp)
		bsr	cal_expression5
		bmi	cal_expression_error2
		jmp	(a1)
cal_expression4_or:
		or.l	(sp)+,d1
		bra	cal_expression4_loop
cal_expression4_xor:
		eor.l	d1,(sp)
		move.l	(sp)+,d1
		bra	cal_expression4_loop

;論理積(&&)
cal_expression3:
		move.l	a1,-(sp)
		bsr	cal_expression4
		bmi	cal_expression_error
cal_expression3_loop:
		move.b	(a0)+,d0
		cmpi.b	#'&',d0
		bne	cal_expression_end
		cmp.b	(a0),d0
		bne	cal_expression_end
*cal_expression3_and:
		addq.l	#1,a0
		move.l	d1,-(sp)
		bsr	cal_expression4
		bmi	cal_expression_error2
		tst.l	(sp)+
		beq	@f
		tst.l	d1
		beq	@f
		moveq	#1,d1			;両方とも真なら真(1)を返す
		bra	cal_expression3_loop
@@:		moveq	#0,d1
		bra	cal_expression3_loop

;論理和(||)
cal_expression2:
		move.l	a1,-(sp)		;^^ で排他的論理和とか(^^;
		bsr	cal_expression3
		bmi	cal_expression_error
cal_expression2_loop:
		move.b	(a0)+,d0
		cmpi.b	#'|',d0
		bne	cal_expression_end
		cmp.b	(a0),d0
		bne	cal_expression_end
*cal_expression2_or:
		addq.l	#1,a0
		move.l	d1,-(sp)
		bsr	cal_expression3
		bmi	cal_expression_error2
		or.l	(sp)+,d0
		beq	cal_expression2_loop
		moveq	#1,d1			;どちらかでも真なら真(1)を返す
		bra	cal_expression2_loop

;条件(a ? b : c)
cal_expression1:
		move.l	a1,-(sp)
		bsr	cal_expression2
		bmi	cal_expression_error
cal_expression1_loop:
		move.b	(a0)+,d0
		cmpi.b	#'?',d0
		bne	cal_expression_end
		tst.l	d1
		beq	cal_expression1_false
*cal_expression1_true:
		bsr	cal_expression2		;true ? [a] : b
		bmi	cal_expression_error
		cmpi.b	#':',(a0)+
		bne	cal_expression_error
		move.l	d1,-(sp)
		bsr	cal_expression2
		bmi	cal_expression_error2
		move.l	(sp)+,d1
		bra	cal_expression1_loop
cal_expression1_false:
		bsr	cal_expression2
		bmi	cal_expression_error
		cmpi.b	#':',(a0)+
		bne	cal_expression_error
		bsr	cal_expression2		;false ? a : [b]
		bmi	cal_expression_error
		bra	cal_expression1_loop

;式の値を計算する
cal_expression:
		bra	cal_expression1
**		rts


*************************************************
*		&online-switch			*
*************************************************

＆online_switch::
		GETMES	MES_SWITC
		movea.l	d0,a1
		bra	ol_sw_arg_next
ol_sw_arg_loop:
		cmpi.b	#'-',(a0)
		bne	ol_sw_arg_skip
		cmpi.b	#'t',(1,a0)
		bne	ol_sw_arg_skip
*ol_sw__option_t:
		addq.l	#2,a0			;-t"タイトル"
@@:		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
		rts				;引数がない
@@:
		lea	(-1,a0),a1
ol_sw_arg_skip:
		tst.b	(a0)+
		bne	ol_sw_arg_skip
ol_sw_arg_next:
		subq.l	#1,d7
		bcc	ol_sw_arg_loop

		lea	(subwin_ol_sw,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		move	d0,d7
		moveq	#WHITE,d1
		jsr	(WinSetColor)

		lea	(ol_sw_mes,pc),a1
		moveq	#2,d2			;Y
		moveq	#17-1,d6
@@:
		moveq	#2,d1			;X
		jsr	(WinSetCursor)
		jsr	(WinPrint)		;ウィンドウ内の文字列を表示

		addq	#1,d2			;Y++
		dbra	d6,@b

		bsr	ol_sw_get_ptr
@@:		move	(a1)+,d1		;システム変数の内容を退避
		move	(a2,d1.w),(a3)+
		dbra	d0,@b

		lea	(Buffer),a4
		lea	(a4),a2
		moveq	#2,d6			;Y
@@:
		bsr	ol_sw_print_on_off
		addq.l	#2,a2			;次の変数
		addq	#1,d6			;Y++
		cmpi	#18,d6
		bls	@b

		moveq	#2,d6
		move	d6,d2
		bsr	ol_sw_underline

		move	d6,d5			;移動前のカーソル位置
ol_sw_loop:
		bsr	dos_inpout
		cmpi.b	#CR,d0
		beq	ol_sw_go
		cmpi.b	#ESC,d0
		beq	ol_sw_go
		cmpi.b	#SPACE,d0		;SPACE/←/→ で on/off 切り換え
		beq	@f
		cmp.b	(AK_RIGHT),d0
		beq	@f
		cmp.b	(AK_LEFT),d0
		bne	ol_sw_keychk
@@:
		move	d6,d0
		add	d0,d0
		lea	(-2*2,a4,d0.w),a2
		moveq	#1,d0			;タブ以外は 0 <-> 1 トグル
		cmpi	#17,d6
		bcs	@f
		moveq	#4.xor.8,d0		;タブ幅は 4 <-> 8 トグル
@@:
		eor	d0,(a2)
		bsr	ol_sw_print_on_off
		bra	ol_sw_loop
ol_sw_keychk:
		cmp.b	(AK_DOWN),d0
		bne	@f
		addq	#1,d6			;カーソル下移動
		cmpi	#18,d6
		bls	1f
		moveq	#2,d6
1:		bra	ol_sw_csr_move
@@:
		cmp.b	(AK_UP),d0
		bne	ol_sw_loop
		subq	#1,d6			;カーソル上移動
		cmpi	#2,d6
		bcc	1f
		moveq	#18,d6
1:		bra	ol_sw_csr_move

ol_sw_csr_move:
		move	d5,d2			;移動前のカーソルを消去
		bsr	ol_sw_underline
		move	d6,d2			;移動先にカーソルを表示
		bsr	ol_sw_underline
		move	d6,d5
		bra	ol_sw_loop

* カーソル表示/消去
ol_sw_underline:
		move	d7,d0
		moveq	#1,d1
		jsr	(WinSetCursor)
		moveq	#40,d2			;桁数
		move	(＄cusr),d1
		bne	@f
		move	(＄cbcl),d1
@@:		jmp	(WinUnderLine2)
**		rts

* 決定/取消
ol_sw_go:
		exg	d7,d0
		jsr	(WinClose)
		cmpi.b	#CR,d7
		bne.s	ol_sw_cancel

		bsr	ol_sw_get_ptr
@@:		move	(a1)+,d1		;システム変数の値を更新
		move	(a3)+,(a2,d1.w)
		dbra	d0,@b

		jmp	＆clear_and_redraw
**		rts


* システム変数保存/更新用パラメータ収得
ol_sw_get_ptr:
		lea	(ol_sw_tbl,pc),a1
		lea	(sys_val_table),a2
		lea	(Buffer),a3
		moveq	#17-1,d0
ol_sw_cancel:
		rts

* on/off 表示
ol_sw_print_on_off:
		move	d7,d0
		moveq	#42,d1
		move	d6,d2
		jsr	(WinSetCursor)

		moveq	#WHITE,d1
		jsr	(WinSetColor)
		lea	(left_bracket,pc),a1	;' [ '
		jsr	(WinPrint)

		moveq	#YELLOW,d1
		jsr	(WinSetColor)

		lea	(ol_sw_off_mes,pc),a1	;off/on 表示
		tst	(a2)
		beq	@f
		addq.l	#ol_sw_on_mes-ol_sw_off_mes,a1
@@:
		cmpi	#17,d6
		bcs	@f
		lea	(ol_sw_8_mes,pc),a1	;タブ幅は 8/4 表示
		cmpi	#8,(a2)
		beq	@f
		addq.l	#ol_sw_4_mes-ol_sw_8_mes,a1
@@:
		jsr	(WinPrint)

		moveq	#WHITE,d1
		jsr	(WinSetColor)
		lea	(right_bracket,pc),a1
		jmp	(WinPrint)
**		rts


subwin_ol_sw:
		SUBWIN	22,6,54,18,NULL,NULL

ol_sw_tbl:
	.irp	i,＄case,＄srtc,＄hidn,＄sysn,＄fumd,＄nmcp,＄mdxt,＄zdrv,＄fnmd,＄drvv,＄lrgp,＄code,＄lnum,＄vfst,＄tabc,＄ctbw,＄tabw
		.dc	i-sys_val_table
	.endm

ol_sw_mes:
		.dc.b	'[assort letter upper/lower ]     &find',0
		.dc.b	'                                 &sort',0
		.dc.b	'[path mask]                     hidden',0
		.dc.b	'                                system',0
		.dc.b	'[mint mode]                cursor down',0
		.dc.b	'            non marked file management',0
		.dc.b	'                           music title',0
		.dc.b	'             display drive name by JIS',0
		.dc.b	'             real time shift functions',0
		.dc.b	' change-drive-menu display volume name',0
		.dc.b	'[other]         get upstairs by cursor',0
		.dc.b	'         show _EXEC return code & time',0
		.dc.b	'[&look-file]               line number',0
		.dc.b	'                           fast scroll',0
		.dc.b	'                       show tabulation',0
		.dc.b	'                    tab columns[.c .h]',0
		.dc.b	'                    tab columns    [*]',0

ol_sw_off_mes:	.dc.b	'  no  ',0
ol_sw_on_mes:	.dc.b	'  yes ',0
ol_sw_8_mes:	.dc.b	'   8  ',0
ol_sw_4_mes:	.dc.b	'   4  ',0

left_bracket:	.dc.b	' [',0
right_bracket:	.dc.b	' ]',0
		.even


*************************************************
*		&iso9660			*
*************************************************

＆iso9660::
		moveq	#0,d7
		bsr	iso9660_msdos
iso9660_check:
		move.b	(a1)+,d0
		cmpi.b	#SPACE,d0
		beq	@f
		cmpi.b	#'_',d0
		beq	@f
		cmpi.b	#'A',d0
		bcs	1f
		cmpi.b	#'Z',d0
		bls	@f
1:		cmpi.b	#'0',d0
		bcs	1f
		cmpi.b	#'9',d0
		bls	@f
1:
		moveq	#-1,d0
		rts
@@:
		dbra	d1,iso9660_check
		moveq	#0,d0
		rts


*************************************************
*		&msdos				*
*************************************************

＆msdos::
		moveq	#7,d7
		bsr	iso9660_msdos
msdos_check:
		move.b	(a1)+,d0
		cmpi.b	#SPACE,d0
		beq	@f			;空白を含むファイル名に対応していない
		cmpi.b	#'a',d0
		bcs	@f
		cmpi.b	#'z',d0
		bhi	@f
		moveq	#-1,d0			;アルファベットの小文字があればエラー
		rts
@@:
		dbra	d1,msdos_check
		moveq	#0,d0
		rts


iso9660_msdos:
		movea.l	(sp)+,a0		;チェックルーチン

		bsr	set_status_0
		tst.b	(PATH_NODISK,a6)
		bmi	iso_msdos_end
		jsr	(search_cursor_file)
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	iso_msdos_end

* オリジナルのコメントでは
* 「+3 以外の拡張子は前に詰まる性質を利用して...
*   まず、主部が 8文字以上ないかどうかチェックする.」
* とのことだが、空白を含むファイル名に対応していない.
		lea	(DIR_NAME,a4),a1
		cmpi.b	#SPACE,(8,a1)		;ノード名の文字数をチェック
		bne	iso_msdos_long_error

		moveq	#8-1,d1
		jsr	(a0)			;ノード名をチェック
		bmi	iso_msdos_end

		lea	(DIR_EXT,a4),a1
		moveq	#3-1,d1
		jsr	(a0)			;拡張子をチェック
		bmi	iso_msdos_end

		bra	set_status_1
**		rts
iso_msdos_long_error:
		move	d7,(＠status)
iso_msdos_end:
rnd_error:
		rts


*************************************************
*		&rnd				*
*************************************************

＆rnd::
		bsr	set_status_0
		tst.l	d7
		beq.s	rnd_error

		suba.l	a2,a2

		move.b	(a0),d0
		subi.b	#'0',d0
		cmpi.b	#9,d0
		bls	rnd_no_name

		subq.l	#1,d7
		beq.s	rnd_error
		lea	(a0),a2
@@:
		tst.b	(a0)+
		bne	@b
rnd_no_name:
		FPACK	__RND
		move.l	d0,d2
		move.l	d1,d3			;d2/d3 乱数

		bsr	atoi_a0
		tst.l	d0
		beq.s	rnd_error		;記述エラー or 0
		tst.b	(a0)
		bne	rnd_error

		FPACK	__LTOD			;d0/d1 最大値
		FPACK	__DMUL			;d0/d1 *= d2/d3
		FPACK	__DTOL			;d0 整数
		bcs.s	rnd_error
		addq	#1,d0
		andi.l	#$ffff,d0
		beq.s	rnd_error

		move.l	a2,d1
		beq	rnd_status		;変数名未指定時は$STATUSに返す

		subq.l	#8,sp
		lea	(sp),a0
		FPACK	__LTOS
		lea	(a2),a1
		lea	(sp),a2
		bsr	set_user_value_a1_a2
		addq.l	#8,sp
rnd_status:
		bra	set_status
**		rts


*************************************************
*		&set-crtc			*
*************************************************

CRTC_REG_NUM:	.equ	24			;r00～r23

＆set_crtc::
*		lea	(-CRTC_REG_NUM*2,sp),sp
		moveq	#(CRTC_REG_NUM*2)/4-1,d0
		moveq	#-1,d1
@@:		move.l	d1,-(sp)
		dbra	d0,@b

		bsr	set_status_0
		tst.l	d7
		beq	set_crtc_error

		moveq	#0,d6			;レジスタ番号
set_crtc_arg_loop1:
		moveq	#$20,d0
		or.b	(a0),d0
		cmpi.b	#'r',d0
		bne	set_crtc_arg_loop2

		addq.l	#1,a0			;r??=
		bsr	set_crtc_regno_getnum
		bhi	set_crtc_error
		moveq	#10,d6
		mulu	d0,d6
		bsr	set_crtc_regno_getnum
		bhi	set_crtc_error
		add	d0,d6
		cmpi.b	#'=',(a0)+
		bne	set_crtc_error
set_crtc_arg_loop2:
		move.b	(a0)+,d0
		beq	set_crtc_arg_nul
		cmpi.b	#',',d0
		beq	set_crtc_next_reg

		cmpi	#CRTC_REG_NUM,d6
		bcc	set_crtc_error

		subq.l	#1,a0
		bsr	atoi_a0
		bne	set_crtc_error

		move	d6,d1
		add	d6,d1
		move	d0,(sp,d1.w)
		bra	set_crtc_arg_loop2
set_crtc_next_reg:
		addq	#1,d6
		bra	set_crtc_arg_loop2

set_crtc_arg_nul:
		subq.l	#1,d7
		bne	set_crtc_arg_loop1

		lea	(sp),a0
		lea	(CRTC),a1
		moveq	#-1,d5
		moveq	#CRTC_REG_NUM-1,d6
*		moveq	#0,d7
set_crtc_write_loop:
		move	(a0)+,d1
		cmp	d5,d1
		beq	set_crtc_write_skip

		IOCS	_B_WPOKE
		subq.l	#2,a1
		moveq	#-1,d7
set_crtc_write_skip:
		addq.l	#2,a1
		dbra	d6,set_crtc_write_loop

		cmp	(CRTC_R20-CRTC,sp),d5
		beq	set_crtc_write_vc_skip

		moveq	#%111,d1		;CRTC R20に書き込んだ場合は
		and.b	(CRTC_R20h-CRTC,sp),d1	;VC R0にも同じ値を設定する
		lea	(VC_R0),a1
		IOCS	_B_WPOKE
set_crtc_write_vc_skip:
		tst	d7
		beq	set_crtc_error		;指定が一つもなかった

		bsr	set_status_1
set_crtc_error:
		lea	(CRTC_REG_NUM*2,sp),sp
		rts

set_crtc_regno_getnum:
		move.b	(a0)+,d0
		subi.b	#'0',d0
		cmpi.b	#9,d0
		rts


*************************************************
*		&sram-contrast			*
*************************************************

＆sram_contrast::
		lea	(contrast_save,pc),a1
		move.b	(a1),d0
		bne	sram_cont_skip_save

		moveq	#-1,d1
		IOCS	_CONTRAST
		move.b	d0,(a1)			;現在の設定を保存
sram_cont_skip_save:
		moveq	#15,d1			;省略時はコントラスト最大
		tst.l	d7
		beq	sram_cont_set
		bsr	atoi_a0
		bne	sram_cont_set
		tst.b	(a0)
		bne	sram_cont_set

		and.b	d0,d1			;指定された値
sram_cont_set:
		pea	(sram_cont_change,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp

		moveq	#-2,d1			;システム設定値に戻す
		IOCS	_CONTRAST
		rts


* コントラストの設定を元に戻す
sram_contrast_pop:
		lea	(contrast_save,pc),a1
		move.b	(a1),d1
		sf	(a1)
		bne	sram_cont_set
		rts


* SRAM のコントラスト設定値を書き換える
* in	d1.b	コントラスト値
* 備考:
*	必ずスーパーバイザモードで呼び出すこと.

sram_cont_change:
		move	sr,-(sp)
		ori	#$700,sr
		SRAM_WRITE_ENABLE
		move.b	d1,(SRAM_CONTRAST)
		SRAM_WRITE_DISABLE
		move	(sp)+,sr
		rts


		.even
stop_flags::
contrast_save:	.dc.b	0
twon_ic_flag:	.dc.b	0
cond_stop_flag:	.dc.b	0
vdisp_stop_flag:.dc.b	0

getsec_flag::	.dc.b	0
break_flag:	.dc.b	0
		.even


*************************************************
*		&stop-condrv			*
*************************************************

＆stop_condrv::
		lea	(cond_stop_flag,pc),a0
		tst.b	(a0)
		bne	stop_condrv_end

		moveq	#1,d1			;stop_level++
		bra	condrv_onoff


stop_condrv_pop:
		lea	(cond_stop_flag,pc),a0
		tst.b	(a0)
		beq	stop_condrv_end

		clr.b	(a0)
		moveq	#-1,d1			;stop_level--
condrv_onoff:
		bsr	get_condrv_work
		bne	stop_condrv_end

		TO_SUPER
		movea.l	(-22,a1),a1		;システムコールのアドレス
		moveq	#$24,d0			;バッファリング制御II
		jsr	(a1)
		or.l	d0,d1
		spl	(a0)
		TO_USER
stop_condrv_end:
		rts


get_condrv_work::
		move	#$0100+_KEY_INIT,-(sp)
		DOS	_INTVCG
		addq.l	#2,sp
		movea.l	d0,a1
		subq.l	#4,a1
		IOCS	_B_LPEEK
		cmpi.l	#'hmk*',d0
		rts


*************************************************
*		&stop-vdisp			*
*************************************************

＆stop_vdisp::
		TO_SUPER
		lea	(MFP),a1
		moveq	#$20,d0
		and.b	(MFP_IERA-MFP,a1),d0
		and.b	(MFP_IMRA-MFP,a1),d0
		beq	stop_vdisp_end		;割り込み未使用

		lea	(vdisp_stop_flag,pc),a0
		st	(a0)

		moveq	#.not.$20,d0		;割り込み禁止
		and.b	d0,(MFP_IERA-MFP,a1)
		and.b	d0,(MFP_IMRA-MFP,a1)
stop_vdisp_end:
		TO_USER
		rts


stop_vdisp_pop:
		lea	(vdisp_stop_flag,pc),a0
		tst.b	(a0)
		beq	stop_vdisp_pop_end

		clr.b	(a0)

		moveq	#1,d1
		lea	(vdisp_int,pc),a1
		IOCS	_VDISPST
		tst.l	d0
		bne	@f

		suba.l	a1,a1			;割り込みが未使用になっていたら
		IOCS	_VDISPST		;復帰しない
		rts
@@:
		TO_SUPER
		lea	(MFP),a1
		moveq	#$20,d0			;割り込み許可
		or.b	d0,(MFP_IERA-MFP,a1)
		or.b	d0,(MFP_IMRA-MFP,a1)
		TO_USER
stop_vdisp_pop_end:
		rts

vdisp_int:
		rte


*************************************************
*		&twentyone-ignore-case		*
*************************************************

＆twentyone_ignore_case::
		bsr	twon_getopt2
		bclr	d1,d0
		beq	twon_ignore_case_end	;もともと -C なら変更不要

		st	(a0)
		bra	twon_ignore_case_set


twentyone_ignore_case_pop:
		bsr	twon_getopt2
		tst.b	(a0)
		beq	twon_ignore_case_end	;設定は変更されていない

		clr.b	(a0)
		bset	d1,d0
twon_ignore_case_set:
		move.l	d0,-(sp)
		move	#_TWON_SETOPT,-(sp)
		DOS	_TWON
		addq.l	#6,sp
twon_ignore_case_end:
		rts

twon_getopt2:
		lea	(twon_ic_flag,pc),a0
		moveq	#_TWON_C_BIT,d1
		jmp	(twon_getopt)
**		rts


* &stop-～ 系内部命令の復帰 ------------------- *

resume_stops::
		PUSH	d0-d7/a0-a5
		bsr	sram_contrast_pop
		bsr	stop_condrv_pop
		bsr	stop_vdisp_pop
		bsr	twentyone_ignore_case_pop
		POP	d0-d7/a0-a5
		rts


*************************************************
*		&unsetenv			*
*************************************************

＆unsetenv::
		moveq	#0,d6
		bra	unsetenv_next
unsetenv_loop:
		tst.b	(a0)
		beq	unsetenv_skip

		clr.l	-(sp)			;変数削除
		clr.l	-(sp)
		pea	(a0)
		DOS	_SETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	unsetenv_skip
		addq.l	#1,d6
unsetenv_skip:
		tst.b	(a0)+
		bne	unsetenv_skip
unsetenv_next:
		subq.l	#1,d7
		bcc	unsetenv_loop

		bra.s	unsetenv_end
**		rts


*************************************************
*		&setenv				*
*************************************************

＆setenv::
		moveq	#0,d6
		subq.l	#2,d7
		bcs	setenv_end
		tst.b	(a0)			;a0 = 環境変数名
		beq	setenv_end

		lea	(a0),a1
@@:		tst.b	(a1)+
		bne	@b
		lea	(a1),a2			;a1 = 文字列
		bra	@f
setenv_strcat_loop:
		move.b	#' ',-(a2)		;引数を空白で繋げる
@@:
		tst.b	(a2)+
		bne	@b
		subq.l	#1,d7
		bcc	setenv_strcat_loop

		move.l	a2,d0
		sub.l	a0,d0
		lsr.l	#8,d0			;cmpi.l #256,d0 / bcc
		bne	setenv_end		;文字列が長すぎる

		pea	(a1)
		clr.l	-(sp)
		pea	(a0)
		DOS	_SETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	setenv_end

		addq.l	#1,d6			;設定できた
setenv_end:
unsetenv_end:
		tst.l	d6
		beq	@f
		jsr	(mint_getenv)
@@:
		move.l	d6,d0
		bra	set_status
**		rts


* @status/@buildin 格納 ----------------------- *

set_status_0:
		moveq	#0,d0
		bra.s	set_status
set_status_1:
		moveq	#1,d0
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts


*************************************************
*		&iocs				*
*************************************************

		.offset	0
~trap_no:	.ds.l	1
~trap_d0:	.ds.l	1
~trap_d1:	.ds.l	1
~trap_d2:	.ds.l	1
~trap_d3:	.ds.l	1
~trap_d4:	.ds.l	1
~trap_d5:	.ds.l	1
~trap_d6:	.ds.l	1
~trap_d7:	.ds.l	1
sizeof_trapbuf:
		.text

＆iocs::
		moveq	#15,d2			;trap #15
		moveq	#4,d1
		bra	iocs_trap


*************************************************
*		&trap				*
*************************************************


＆trap::
*		moveq	#0,d2			;省略不可なのでゴミでもいい
		moveq	#0,d1
iocs_trap:
*		lea	(-sizeof_trapbuf,sp),sp
		moveq	#(sizeof_trapbuf-1)/4-1,d0
@@:		clr.l	-(sp)
		dbra	d0,@b
		move.l	d2,-(sp)		;~trap_no

		lea	(Buffer),a2		;バッファ
		clr.l	(a2)

		tst.l	d7
		bne	trap_arg_next
		lea	(a2),a0			;ダミーの引数を用意
		bra	trap_arg_end
trap_arg_next_reg:
		addq	#4,d1
trap_arg_loop:
		move.b	(a0)+,d0
		beq	trap_arg_next
		cmpi.b	#',',d0
		beq	trap_arg_next_reg	;次のレジスタに進める

		subq.l	#1,a0
		bsr	atoi_a0
		bne	trap_arg_end		;数値指定ではなかった
		cmpi	#sizeof_trapbuf,d1
		bcc	trap_error		;引数が多すぎる

		move.l	d0,(sp,d1.w)		;値を格納
		addq	#4,d1
trap_arg_skip_comma:
		move.b	(a0)+,d0
		beq	@f
		cmpi.b	#',',d0
		beq	trap_arg_loop		;後の ',' を飛ばす
		subq.l	#1,a0
		bra	trap_arg_loop
@@:		subq.l	#1,d7
		bcc	trap_arg_skip_comma
		bra	trap_arg_end
trap_arg_next:
		subq.l	#1,d7
		bcc	trap_arg_loop
trap_arg_end:
		tst	d1
		beq	trap_error		;trap #n の番号も指定されなかった

		moveq	#15,d0
		cmp.l	(~trap_no,sp),d0
		bcs	trap_error		;0～15 でなければエラー

		lea	(a0),a1			;オプション引数
**		lea	(Buffer),a2	

		move.l	(~trap_no,sp),d0
		lsl	#2,d0			;trap + rts で各 4 バイト
		lea	(trap_table,pc,d0.w),a0

		movem.l	(~trap_d0,sp),d0-d7
		move.l	a6,-(sp)
		jsr	(a0)			;trap #n 実行
		movea.l	(sp)+,a6
trap_end:
		lea	(sizeof_trapbuf,sp),sp
		bra	set_status
**		rts
trap_error:
		moveq	#0,d0
		bra	trap_end

i:=0
trap_table:
	.rept	16
		trap	#i
		rts
		i:=i+1
	.endm


*************************************************
*		&execute-binary			*
*************************************************

＆execute_binary::
		moveq	#0,d1
		lea	(a0),a1			;a1=書き込みポインタ
		lea	(a0),a2			;a2=読み込みポインタ
		bra	exec_bin_next
exec_bin_loop:
		move.b	(a2)+,d0
		beq	exec_bin_next
		cmpi.b	#'0',d0
		bcs	exec_bin_error
		cmpi.b	#'9',d0
		bls	exec_bin_num
		andi.b	#$df,d0
		cmpi.b	#'A',d0
		bcs	exec_bin_error
		cmpi.b	#'F',d0
		bhi	exec_bin_error
		addi.b	#'9'+1-'A',d0
exec_bin_num:
		andi.b	#$0f,d0
		or.b	d0,(a1)+
		not	d1
		beq	exec_bin_loop		;下位 4bit
		lsl.b	#4,d0
		move.b	d0,-(a1)		;上位 4bit
		bra	exec_bin_loop
exec_bin_next:
		subq.l	#1,d7
		bcc	exec_bin_loop

		tst	d1
		bne	exec_bin_error		;下位 4bit が無い
		move.l	a1,d0
		sub.l	a0,d0
		lsr.l	#1,d0
		bls	exec_bin_error		;0 または奇数バイト

		move.l	a6,-(sp)		;a0=先頭アドレス
		jsr	(a0)			;a1=末尾アドレス
		movea.l	(sp)+,a6
		bra	set_status
exec_bin_error:
		bra	set_status_0
**		rts


*************************************************
*		&getsec				*
*************************************************

＆getsec::
		lea	(getsec_flag,pc),a1
		st	(a1)
		IOCS	_ONTIME
		move.l	d0,(時間_実行前)
		rts


*************************************************
*		&key-wait			*
*************************************************

＆key_wait::
		PUSH	d1-d7/a0-a6
		moveq	#-1,d1
		IOCS	_B_LOCATE
		move.l	d0,d7
		swap	d0
		tst	d0
		beq	@f

		moveq	#CR,d1			;カーソルが行の途中にあるなら改行する
		IOCS	_B_PUTC
		moveq	#LF,d1
		IOCS	_B_PUTC
		moveq	#-1,d1
		IOCS	_B_LOCATE
		move.l	d0,d7
@@:
		moveq	#31,d1			;最下行に移動
		IOCS	_B_DOWN

		GETMES	MES_KWAIT
		movea.l	d0,a0
		movea.l	d0,a1
@@:
		tst.b	(a0)+
		bne	@b
		subq.l	#2,a0
		move.l	a0,d4
		sub.l	a1,d4

		moveq	#-1,d1
		moveq	#-1,d2
		IOCS	_B_CONSOL
		lsr	#4,d1
		add	d2,d1
		move	d1,d3
		moveq	#WHITE,d1
		moveq	#0,d2

		PUSH	d1-d4
		IOCS	_B_PUTMES
		move	d2,d1
		IOCS	_B_RIGHT		;カーソルが "...!" の次にくるようにする
		bsr	dos_inpout
		jsr	(dos_kflush)
		POP	d1-d4

		clr	-(sp)
		lea	(sp),a1			;表示した文字を消す
		IOCS	_B_PUTMES
		addq.l	#2,sp

		move.l	d7,-(sp)
		move	(sp)+,d1
		move	(sp)+,d2
		IOCS	_B_LOCATE

		POP	d1-d7/a0-a6
		rts


* 時計更新つきキー入力
dos_inpout::
		bsr	update_periodic_disp
		move	#$ff,-(sp)
		DOS	_INPOUT
		addq.l	#2,sp
		cmpi.b	#BEL,d0
		bne	@f
		moveq	#ESC,d0
@@:
		tst.l	d0
		beq	dos_inpout
		rts


*************************************************
*		&wait=&sleep			*
*************************************************

＆wait::
		tst.l	d7
		beq	wait_end

		bsr	atoi_a0
		tst.b	(a0)
		bne	wait_end

		clr.l	-(sp)
		lea	(sp),a0
		bsr	init_timer
wait_loop:
		bsr	update_periodic_disp
		bsr	break_check
		bmi	@f

		move.l	d7,d0
		bsr	check_timer
		bne	wait_loop
@@:
		addq.l	#4,sp
wait_end:
		rts


* ブレーク検査 -------------------------------- *

* 現在のブレークキーの押し下げ状態を記録する.
* break	d0
* 備考:
*	quick 実行を行う要因となるキー入力の直後に
*	呼び出すこと.

break_check0::
		pea	(break_check_sub,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		move.b	d0,(break_flag)
		rts


* ブレークキーの押し下げ状態を更新する.
* break	d0
* 備考:
*	チェイン実行中、ある程度の感覚で呼び出すこと.	

break_check1::
		move.b	(break_flag,pc),d0
		beq	break_check_end
		bra	break_check


* ブレークキーの押し下げ状態を調べる.
* out	d0.l	0:ブレークなし -1:ブレークあり
*	ccr	<tst.l d0> の結果

break_check::
		pea	(break_check_sub,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		and.b	d0,(break_flag)		;離されたキーをクリアする
		sub.b	(break_flag,pc),d0
		beq	break_check_end
		moveq	#-1,d0			;新たな押し下げが発生したらブレーク
break_check_end:
		rts


* ブレークチェック下請け
* out	d0.l	bit3=1:ESC 押し下げ
*		bit2=1:BREAK 〃
*		bit1=1:CTRL+C 〃
*		bit0=1:CTRL+D 〃
* 備考:
*	ESC、BREAK、CTRL+C、CTRL+D の押し下げ状態を見る.
*	スーパーバイザモードで呼び出すこと.

break_check_sub:
		moveq	#0,d0
		btst	#1,($800)		;ESC
		beq	@f
		addq.b	#1<<3,d0
@@:
		btst	#1,($80c)		;BREAK
		beq	@f
		addq.b	#1<<2,d0
@@:
		btst	#1,($811)		;CTRL
		beq	break_check_sub_end
		btst	#4,($805)		;C
		beq	@f
		addq.b	#1<<1,d0
@@:
		btst	#0,($804)		;D
		beq	@f
		addq.b	#1<<0,d0
@@:
break_check_sub_end:
		rts


*************************************************
*		&prchk=&keep-check		*
*************************************************

＆prchk::
		jsr	(init_i_c_option)
		moveq	#0,d6
prchk_arg_next:
		subq.l	#1,d7
		bcs	prchk_error		;ファイル名指定なし

		jsr	(take_i_c_option)
		beq	prchk_arg_next
		move.b	(a0)+,d0
		beq	prchk_arg_next
		cmpi.b	#'-',d0
		beq	prchk_error		;不正なオプション

		lea	(-1,a0),a4		;ファイル名指定あり
		STRLEN	a4,d0
		moveq	#22,d1
		cmp.l	d1,d0
		bhi	prchk_error		;ファイル名が長すぎる

		lea	(mint_start-PSP_SIZE),a0
		lea	(ctypetable),a3
		move.l	(_ignore_case),d7
		lsl.b	#5,d7			;$00:case $20:ignore-case
		TO_SUPER
		bra	@f
prchk_parent_loop:
		move.l	d0,a0
@@:		bsr	prchk_compare_filename	;自分自身(mint.x)かその祖先から探す
		beq	prchk_found

		move.l	(pare,a0),d0
		bne	prchk_parent_loop
prchk_keeppr_loop:
		cmpi.b	#MEM_KEEP,(pare,a0)
		bne	@f
		bsr	prchk_compare_filename	;常駐プロセスから探す
		beq	prchk_found
@@:
		move.l	(next,a0),a0
		move.l	a0,d0
		bne	prchk_keeppr_loop
		bra	prchk_not_found
prchk_found:
		moveq	#1,d6
prchk_not_found:
		TO_USER
prchk_error:
		move.l	d6,d0
		bra	set_status
**		rts


* in	a0.l	PSP
*	a3.l	ctypetable
*	a4.l	filename
*	d7.b	$00:case $20:ignore-case
* out	ccrZ	1:一致 0:不一致

prchk_compare_filename:
		lea	(a4),a1
		lea	(PSP_Filename,a0),a2	;比較用ファイル名
		moveq	#0,d1
prchk_cmp_loop:
		move.b	(a1)+,d1
		beq	prchk_cmp_file1_end
		move.b	(a2)+,d2
		move.b	(a3,d1.w),d0
		bmi	prchk_cmp_mb

		btst	#2,d0
		beq	prchk_cmp_byte

		or.b	d7,d1
		or.b	d7,d2
prchk_cmp_byte:
		cmp.b	d1,d2
		beq	prchk_cmp_loop
		rts
prchk_cmp_mb:
		cmpm.b	(a1)+,(a2)+
		beq	prchk_cmp_byte
		rts

prchk_cmp_file1_end:
		tst.b	(a2)
		beq	prchk_cmp_end
		cmpi.b	#'.',(a2)		;拡張子は省略可能にする
prchk_cmp_end:
		rts


*************************************************
*		&scsi-check			*
*************************************************

＆scsi_check::
		GETMES	MES_SCSIC
		movea.l	d0,a1

		move.l	d7,d0
		bra	scsi_check_arg_next
scsi_check_arg_loop:
		cmpi.b	#'-',(a0)
		bne	scsi_check_arg_skip
		cmpi.b	#'t',(1,a0)
		bne	scsi_check_arg_skip
		addq.l	#2,a0			;-t"タイトル"
@@:		tst.b	(a0)+
		bne	@f
		subq.l	#1,d0
		bcc	@b
		bra	scsi_check_arg_end	;文字列がない
@@:		lea	(-1,a0),a1
scsi_check_arg_skip:
		tst.b	(a0)+
		bne	scsi_check_arg_skip
scsi_check_arg_next:
		subq.l	#1,d0
		bcc	scsi_check_arg_loop
scsi_check_arg_end:
		bsr	is_scsi_iocs_included
		bmi	scsi_check_no_scsi

* SCSI IOCS 使用可能
		lea	(subwin_scsi_check,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		bsr	scsi_get_maxid
		addq	#1,d7
		move	d7,(SUBWIN_YSIZE,a0)	;行数 8/16
		jsr	(WinOpen)
		move	d0,-(sp)
		bsr	scsi_check_sub
		bsr	dos_inpout
		move	(sp)+,d0
		jmp	(WinClose)
**		rts

* SCSI IOCS 使用不可能
scsi_check_no_scsi:
		GETMES	MES_SCSIE
		movea.l	d0,a0
		moveq	#1,d7
		moveq	#0,d6
*		moveq	#MES_SCSIC,d0		;a1 != 0 なので不要
		bra	print_sub
**		rts


scsi_check_sub:
		moveq	#0,d5			;bit=1:機器が接続されている
		moveq	#0,d6
		bsr	scsi_get_maxid
scsi_check_loop:
		moveq	#$40/4-1,d0
@@:		clr.l	-(sp)			;inquiry 読み込みバッファ初期化
		dbra	d0,@b

		move.l	#' 0:'<<8,-(sp)
		add	d6,(sp)
		cmpi	#10,d6
		bcs	@f
		addi	#'10'-' 0'-10,(sp)	;ID 10～15
@@:		move	#'ID',-(sp)

		moveq	#9,d3			;先に ID 番号を表示しておく
		add	d6,d3
		moveq	#WHITE+EMPHASIS,d1
		moveq	#30,d2
		moveq	#5-1,d4
		lea	(sp),a1
		IOCS	_B_PUTMES
		addq.l	#6,sp

		lea	(SRAM_SCSIMODE),a1
		IOCS	_B_BPEEK
		eor.b	d6,d0
		lsl.b	#5,d0
		beq	scsi_check_initiator

		moveq	#$38,d3
		move.l	d6,d4
		lea	(sp),a1
		SCSI	_S_INQUIRY
		tst.l	d0
		bmi	scsi_check_no_device

		addq.l	#8,a1
		bset	d6,d5
		moveq	#WHITE,d1
		bra	scsi_check_print
scsi_check_initiator:
		moveq	#WHITE,d1		;イニシエータ
		moveq	#MES_SCSIX,d0
		bra	@f
scsi_check_no_device:
		moveq	#BLUE,d1		;未接続
		moveq	#MES_SCSIN,d0
@@:
		jsr	(get_message)
		movea.l	d0,a1
scsi_check_print:
		moveq	#9,d3
		add	d6,d3
		moveq	#30+6,d2
		moveq	#28-1,d4
		IOCS	_B_PUTMES
		lea	($40,sp),sp
*scsi_check_next:
		bsr	update_periodic_disp
		addq	#1,d6
		cmp	d7,d6
		bls	scsi_check_loop

		lea	(scsi_flag,pc),a1
		move	d5,(a1)
		rts


* SCSI の最大 ID 番号を得る.
* out	d7.l	最大 ID 番号(通常は 7、TWOSCSI 組み込み時は 15)
* break	d0-d1

_S_TW_CHK:	.equ	$001e

scsi_get_maxid:
		moveq	#7,d7
		SCSI	_S_TW_CHK
		addq.l	#2,d0
		bne	@f
		moveq	#15,d7			;TWOSCSI が組み込まれている
@@:		rts


* SCSI IOCS が使用可能か調べる.
* out	ccr	Z=1/N=0:使用可能
*		Z=0/N=1:使用不可能
is_scsi_iocs_included:
		PUSH	d0-d7/a0-a6
		moveq	#-1,d2
		TO_SUPER
		move	sr,-(sp)
		ori	#$0700,sr
		move.l	(TRAP14_VEC*4),-(sp)
		move.l	sp,(scsi_check_sp)
		pea	(is_scsi_iocs_inc_error,pc)
		move.l	(sp)+,(TRAP14_VEC*4)

		SCSI	_S_LEVEL
		moveq	#0,d2
is_scsi_iocs_inc_error:
		movea.l	(scsi_check_sp,pc),sp
		move.l	(sp)+,(TRAP14_VEC*4)
		move	(sp)+,sr
		TO_USER
		tst.l	d2
		POP	d0-d7/a0-a6
		rts


subwin_scsi_check:
		SUBWIN	29,8,38,8,NULL,NULL

scsi_check_sp:	.dc.l	0
scsi_flag:	.dc	-1


*************************************************
*		&scsi-menu			*
*************************************************

＆scsi_menu::
		bsr	is_scsi_iocs_included
		bmi	scsi_menu_iocs_error
		move.l	d7,d6
		bsr	scsi_get_maxid

		GETMES	MES_SCSIM
		movea.l	d0,a1
		bra	scsi_menu_arg_next
scsi_menu_arg_loop:
		lea	(a0),a2
		cmpi.b	#'-',(a2)+
		bne	scsi_menu_arg_skip
		move.b	(a2)+,d0
		cmpi.b	#'a',d0
		beq	scsi_menu_option_a
		cmpi.b	#'t',d0
		bne	scsi_menu_arg_skip
*scsi_menu_option_t:
@@:		tst.b	(a2)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d6
		bcc	@b
		bra	scsi_menu_arg_end	;文字列がない
@@:		lea	(-1,a2),a1
		bra	@f
scsi_menu_option_a:
		not	d7			;-a
		not.l	d7			;d7.hw = -1: -a が指定された
@@:
		lea	(a2),a0
scsi_menu_arg_skip:
		tst.b	(a0)+
		bne	scsi_menu_arg_skip
scsi_menu_arg_next:
		subq.l	#1,d6
		bcc	scsi_menu_arg_loop
scsi_menu_arg_end:
		move.l	a1,(subwin_scsi_menu+SUBWIN_TITLE)

		move	(scsi_flag,pc),d5	;有効な ID(ビットマップ)
		moveq	#0,d6			;現在の ID
		moveq	#0,d2			;有効な ID 数

		lea	(Buffer),a5
		lea	(a5),a3			;選択肢リスト
		lea	(MENU_MAX*4,a0),a4	;文字列バッファ

		lea	(-36,sp),sp
scsi_menu_device_check_loop:
		lea	(SRAM_SCSIMODE),a1
		IOCS	_B_BPEEK
		eor.b	d6,d0
		lsl.b	#5,d0
		bne	scsi_menu_target

		bclr	d6,d5			;イニシエータ
		moveq	#MES_SCSII,d0
		bra	@f
scsi_menu_device_no_dev:
		moveq	#MES_SCSID,d0
@@:		tst.l	d7
		bpl	scsi_menu_device_check_next
		jsr	(get_message)
		movea.l	d0,a1
		bra	scsi_menu_device_ok	;-a 指定時は全て表示する

scsi_menu_target:
		bclr	d6,d5			;ターゲット
		bne	@f
		tst.l	d7
		bpl	scsi_menu_device_check_next
@@:
		moveq	#36,d3
		move.l	d6,d4
		lea	(sp),a1
		SCSI	_S_INQUIRY
		tst.l	d0
		bmi	scsi_menu_device_no_dev

		bset	d6,d5			;機器が接続されている
		lea	(8,sp),a1
		lea	(sp),a2
		moveq	#8-1,d1
@@:
		move.b	(a1)+,d0		;ベンダ名
		bne	1f
		moveq	#SPACE,d0
1:		move.b	d0,(a2)+
		dbra	d1,@b

		moveq	#20-1,d1
@@:		move.b	(a1)+,(a2)+		;製品名
		dbeq	d1,@b
		clr.b	(a2)

		lea	(sp),a1
scsi_menu_device_ok:
		move.l	a4,(a3)+		;選択肢リストに登録

		moveq	#'0',d0			;ショートカットキーの作成
		add.b	d6,d0
		cmpi	#10,d6
		bcs	@f
		addq.b	#'A'-'0'-10,d0		;ID10～15 は A～F にする
@@:		move.b	d0,(a4)+
@@:
		move.b	(a1)+,(a4)+		;本文
		bne	@b

		addq	#1,d2			;選択肢の数++
scsi_menu_device_check_next:
		addq	#1,d6
		cmp	d7,d6
		bls	scsi_menu_device_check_loop

		lea	(36,sp),sp

		lea	(subwin_scsi_menu,pc),a0
		move	d5,(scsi_flag-subwin_scsi_menu,a0)
		move	d2,(SUBWIN_YSIZE,a0)
		beq	scsi_menu_device_error	;選択可能なデバイスが一つも無い

		moveq	#1,d0
		lea	(a5),a1
		jsr	(menu_sub)
		swap	d0
		beq	scsi_menu_end		;キャンセル

		clr	(a5)			;ユーザ変数 _ に ID 番号を設定する
		move.b	d0,(a5)
		lea	(a5),a2
		bsr	set_user_value_arg_a2
scsi_menu_end:
		bra	set_status
**		rts


*scsi_menu_option_error:
*		pea	(scsi_menu_option_err_mes,pc)
*		bra	@f
scsi_menu_iocs_error:
		pea	(scsi_menu_iocs_err_mes,pc)
		bra	@f
scsi_menu_device_error:
		pea	(scsi_menu_device_err_mes,pc)
@@:
		DOS	_PRINT
		addq.l	#4,sp
		jsr	(PrintCrlf)
		bra	set_status_0
**		rts


subwin_scsi_menu:
		SUBWIN	30,6,34,0,NULL,NULL

*scsi_menu_option_err_mes:
*		.dc.b	'&scsi-menu: 引数が不正です.',0
scsi_menu_iocs_err_mes:
		.dc.b	'&scsi-menu: SCSI IOCS は使用不可能です.',0
scsi_menu_device_err_mes:
		.dc.b	'&scsi-menu: 機器が接続されていません.',0
		.even


*************************************************
*		&bell=&beep			*
*************************************************

＆bell::
		move	#BEL,-(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp
		rts


*************************************************
*		&v-bell=&visual-bell		*
*************************************************

＆v_bell::
		PUSH	d0-d1/a0-a2
		TO_SUPER

		lea	(TEXT_PAL),a0
		lea	(MFP_GPIP),a1
		lea	(v_bell_sub,pc),a2
		movem.l	(a0),d0-d1
		cmp.l	(10*2,a0),d1
		bne	@f
		cmp	(9*2,a0),d0
		bne	@f
		cmpi	#1,(8*2,a0)
		bne	@f
		lea	(v_bell_gm,pc),a2
@@:
		bsr	v_bell_flash		;二個一組で反転復帰
		bsr	v_bell_flash

		TO_USER2
		POP	d0-d1/a0-a2
		rts

v_bell_flash:
@@:		btst	#4,(a1)
		beq	@b			;垂直表示期間まで待つ
@@:		btst	#4,(a1)
		bne	@b			;垂直帰線期間まで待つ
		jmp	(a2)

v_bell_gm:
		movem.l	(8*2,a0),d0-d1
		swap	d0
		swap	d1
		exg	d0,d1
		movem.l	d0-d1,(8*2,a0)		;テキストパレットを反転する

		movem.l	(a0),d0-d1
v_bell_sub:
		swap	d0
		swap	d1
		exg	d0,d1
		movem.l	d0-d1,(a0)		;テキストパレットを反転する
		rts


*************************************************
*		&echo				*
*************************************************

＆echo::
		tst.l	d7
		beq	echo_crlf
		moveq	#0,d6

		cmpi.b	#'-',(a0)
		bne	echo_no_option
		tst.b	(1,a0)
		beq	echo_ignore_option

		lea	(1,a0),a1
		move.b	(a1)+,d0
		moveq	#0,d5
echo_option_loop:
		cmpi.b	#'e',d0
		beq	echo_option_e
		cmpi.b	#'n',d0
		bne	echo_no_option
echo_option_n:
		bchg	#0,d5
		bra	@f
echo_option_e:
		bchg	#1,d5
@@:		move.b	(a1)+,d0
		bne	echo_option_loop

		move	d5,d6
		lea	(a1),a0
		subq.l	#1,d7
		bne	echo_no_option

		bsr	echo_clear_screen	;&echo -n
		bra	echo_crlf

echo_ignore_option:
		subq.l	#1,d7
		beq	echo_crlf		;&echo -

		addq.l	#2,a0
echo_no_option:
		move.l	a0,-(sp)
		bsr	echo_clear_screen
		lsr	#1,d6
		bcs	echo_esc		;&echo -e
@@:
		tst.b	(a0)+
		bne	@b
		move.b	#SPACE,(-1,a0)
		subq.l	#1,d7
		bne	@b
echo_print:
		clr.b	-(a0)
		DOS	_PRINT
		addq.l	#4,sp
echo_crlf:
		jsr	(PrintCrlf)
		bra	set_status_1
**		rts

echo_clear_screen:
		lsr	#1,d6			;&echo -n||%cclr 1なら初期化しない
		bcs	@f
		jmp	(ConsoleClear2)
@@:		rts

echo_esc:
		lea	(a0),a1			;a1 -> a0
echo_esc_loop:
		move.b	(a1)+,d0
		move.b	d0,(a0)+
		beq	echo_esc_next_arg
		cmpi.b	#'\',d0
		bne	echo_esc_loop

		move.b	(a1),d0
		cmpi.b	#'x',d0
		beq	echo_esc_x

		lea	(echo_esc_table-1,pc),a2
@@:
		addq.l	#1,a2
		tst.b	(a2)
		beq	echo_esc_loop
		cmp.b	(a2)+,d0
		bne	@b

		addq.l	#1,a1
		move.b	(a2),(-1,a0)
		bra	echo_esc_loop

echo_esc_x:
		move.b	d0,(a0)+

		moveq	#0,d0
		move.b	(1,a1),d0
		jsr	(is_xdigt)
		beq	echo_esc_loop
		move.b	(2,a1),d0
		jsr	(is_xdigt)
		beq	echo_esc_loop

		subq.l	#2,a0
		addq.l	#1,a1
		bsr	echo_esc_x_to_num
		lsl.b	#4,d0
		move.b	d0,-(sp)
		bsr	echo_esc_x_to_num
		or.b	(sp)+,d0
		move.b	d0,(a0)+
		bra	echo_esc_loop

echo_esc_x_to_num:
		move.b	(a1)+,d0
		cmpi.b	#'9',d0
		bls	@f
		andi.b	#$df,d0
		subq.b	#'A'-('9'+1),d0
@@:		subi.b	#'0',d0
		rts

echo_esc_next_arg:
		move.b	#SPACE,(-1,a0)
		subq.l	#1,d7
		bne	echo_esc_loop
		bra	echo_print

echo_esc_table:
		.dc.b	'\','\'
		.dc.b	'a',BEL
		.dc.b	'b',BS
		.dc.b	'e',ESC
		.dc.b	'f',FF
		.dc.b	'n',LF
		.dc.b	'r',CR
		.dc.b	't',TAB
		.dc.b	'v',VT
		.dc.b	0
		.even


*************************************************
*		&print=&ask-yn			*
*************************************************

＆print::
		moveq	#0,d6			;待機時間
		movea.l	d6,a1			;タイトル

		tst.l	d7
		beq	print_no_arg		;引数がなければ "NUL" を表示
print_arg_loop:
		cmpi.b	#'-',(a0)
		bne	print_option_end
		move.b	(1,a0),d0
		beq	print_option_nul
		cmpi.b	#'t',d0
		beq	print_option_t
		cmpi.b	#'s',d0
		bne	print_option_end
*print_option_s:
		lea	(a0),a2
		addq.l	#2,a0
		bsr	atoi_a0
		exg	a0,a2
		bne	print_option_end
		tst.b	(a2)
		bne	print_option_end

		move.l	d0,d6
		bra	print_next_option
print_option_t:
		addq.l	#2,a0
		lea	(a0),a1
		bra	print_next_option
print_next_option:
		tst.b	(a0)+
		bne	print_next_option
print_next_option2:
		subq.l	#1,d7
		bne	print_arg_loop
		bra	print_no_arg
print_option_nul:
		addq.l	#2,a0
		subq.l	#1,d7
		bne	print_option_end
print_no_arg:
		moveq	#1,d7
		lea	(print_nul_mes,pc),a0
print_option_end:
		moveq	#MES_PRINT,d0
		bsr	print_sub
		bra	set_status
**		rts


* &print 下請け.
* in	d0.w	デフォルトタイトルのメッセージ番号
*	d6.l	待機時間(0 なら時間制限なし)
*	d7.l	引数の数(1～)
*	a0.l	引数のアドレス
*	a1.l	タイトルのアドレス(0 ならデフォルトタイトルを使用)
* out	d0.l	終了時のキー入力の種類
*		d0.l = 1：CR,Y,y,SPACE(%sp_y 1の場合のみ)
*		d0.l = 0：それ以外
* 備考
*	レジスタを破壊するので、必要なら呼び出し元で保存すること.

print_sub::
		move.l	a1,-(sp)		;SUBWIN_TITLE
		bne	@f
		jsr	(get_message)
		move.l	d0,(sp)
@@:		clr.l	-(sp)			;SUBWIN_MES
		clr.l	-(sp)			;SUBWIN_X/YSIZE
		clr.l	-(sp)			;SUBWIN_X/Y

		lea	(a0),a5			;先頭文字列
		moveq	#94,d1
print_check_str_loop:
		move.l	a0,d0
@@:
		tst.b	(a0)+
		bne	@b
		sub.l	a0,d0
		addq.l	#1,d0
		neg.l	d0
		cmp.l	d1,d0
		bls	@f
		moveq	#94,d0			;一行が長すぎる
@@:
		cmp	(SUBWIN_XSIZE,sp),d0
		bls	@f
		move	d0,(SUBWIN_XSIZE,sp)
@@:
		addq	#1,(SUBWIN_YSIZE,sp)
		cmpi	#26,(SUBWIN_YSIZE,sp)
		bcc	@f
		subq.l	#1,d7
		bne	print_check_str_loop
@@:
		movea.l	(SUBWIN_TITLE,sp),a0
		STRLEN	a0,d0
		tst	(＄wind)
		beq	@f
		addq	#2,d0
@@:
		cmp	(SUBWIN_XSIZE,sp),d0
		bcc	@f
		move	(SUBWIN_XSIZE,sp),d0
@@:
		addq	#2+1,d0
		andi	#$fffe,d0
		move	d0,(SUBWIN_XSIZE,sp)
		moveq	#96,d1
		sub	d0,d1
		lsr	#2,d1
		add	d1,d1
		move	d1,(SUBWIN_X,sp)

		moveq	#32,d0
		sub	(SUBWIN_YSIZE,sp),d0
		lsr	#2,d0
		addq	#1,d0
		move	d0,(SUBWIN_Y,sp)
		move	(＄mesl),d0
		cmpi	#-1,d0
		beq	@f
		move	d0,(SUBWIN_Y,sp)
@@:
		lea	(sp),a0
		jsr	(WinOpen)
		move	(SUBWIN_YSIZE,sp),d7
		lea	(sizeof_SUBWIN,sp),sp
		move	d0,-(sp)		;ウィンドウ番号

		subq	#1,d7
		moveq	#1,d2			;Y
		lea	(a5),a1			;先頭文字列
@@:
		moveq	#1,d1			;X
		jsr	(WinSetCursor)
		jsr	(WinPrint)
		addq	#1,d2			;Y++
		dbra	d7,@b

		clr.l	-(sp)
		lea	(sp),a0
		bsr	init_timer
		jsr	(iocs_key_flush)
		moveq	#0,d5
print_wait_loop:
		bsr	update_periodic_disp
*		bsr	break_check
*		bmi	print_wait_end

		IOCS	_B_KEYSNS
		tst.l	d0
		beq	@f
		IOCS	_B_KEYINP
*		move.b	d0,d5			;UNDO とかカーソルで終了しないので×
*		bne	print_wait_end
		cmpi	#$5500,d0
		bcc	@f			;シフト/LED/リリース系は無視する
		move.b	d0,d5
		bra	print_wait_end
@@:
		move.l	d6,d0
		beq	print_wait_loop		;時間無制限

		bsr	check_timer
		bne	print_wait_loop
print_wait_end:
		addq.l	#4,sp

		moveq	#1,d1
		cmpi.b	#CR,d5
		beq	@f
		tst	(＄sp_y)
		beq	1f
		cmpi.b	#SPACE,d5		;%sp_y 1 の時はスペースも 'Y' 扱い
		beq	@f
1:		andi.b	#$df,d5
		cmpi.b	#'Y',d5
		beq	@f
		moveq	#0,d1
@@:
		move	(sp)+,d0		;ウィンドウ番号
		jsr	(WinClose)
		jsr	(dos_kflush)
		move.l	d1,d0
		rts


print_nul_mes:
		.dc.b	'NUL',0
		.even


*************************************************
*		&palet0-up			*
*************************************************

＆palet0_up::
		bsr	palet0_sub
		move	d0,d1
		moveq	#%11111<<1,d4
		and	d4,d1
		cmp	d4,d1
		beq	@f
		addq	#%00001<<1,d1
@@:
		move	d0,d2
		lsl	#5,d4
		and	d4,d2
		cmp	d4,d2
		beq	@f
		addi	#%00001<<6,d2
@@:
		move	d0,d3
		lsl	#5,d4
		and	d4,d3
		cmp	d4,d3
		beq	@f
		addi	#%00001<<11,d3
@@:
		andi	#1,d0
		or	d1,d0
		or	d2,d0
		or	d3,d0
		move	d0,(a0)
		bra	＆palet0_set

palet0_sub:
		lea	(＄col0),a0
		move	(a0),d0
		rts


*************************************************
*		&palet0-down			*
*************************************************

＆palet0_down::
		bsr	palet0_sub
		moveq	#%11111<<1,d1
		and	d0,d1
		beq	@f
		subq	#%00001<<1,d0
@@:
		move	#%11111<<6,d1
		and	d0,d1
		beq	@f
		subi	#%00001<<6,d0
@@:
		move	#%11111<<11,d1
		and	d0,d1
		beq	@f
		subi	#%00001<<11,d0
@@:
		move	d0,(a0)
		bra	＆palet0_set


*************************************************
*		&palet0-set			*
*************************************************

＆palet0_set::
		moveq	#0,d2
		move	(＄col0),d2
		bra	palet0_set_sub


*************************************************
*		&palet0-system			*
*************************************************

＆palet0_system::
		moveq	#-2,d2
palet0_set_sub:
		moveq	#0,d1
		IOCS	_TPALET
		rts


*************************************************
*		MPU 内蔵キャッシュ制御		*
*************************************************

＆data_cache_on::
		moveq	#%10,d3
		bra	@f
＆instruction_cache_on::
		moveq	#%01,d3
		bra	@f
＆cache_on::
		moveq	#%11,d3
@@:
		bsr	get_mpu_cache
		or	d3,d2
		bra	set_mpu_cache

＆data_cache_off::
		moveq	#%01,d3
		bra	@f
＆instruction_cache_off::
		moveq	#%10,d3
		bra	@f
＆cache_off::
		moveq	#%00,d3
@@:
		bsr	get_mpu_cache
		and	d3,d2
		bra	set_mpu_cache

set_mpu_cache:
		moveq	#4,d1
		IOCS	_SYS_STAT
		jmp	(＆mpu_power)

get_mpu_cache:
		cmpi.b	#2,(MpuType)
		bcs	cache_error

		moveq	#1,d1
		IOCS	_SYS_STAT
		move.l	d0,d2
		rts
cache_error:
		addq.l	#4,sp			;直接帰る
		rts


*************************************************
*		&older-file			*
*************************************************

＆older_file::
		moveq	#0,d6
		bra.s	older_newer_file


*************************************************
*		&newer-file			*
*************************************************

＆newer_file::
		moveq	#-1,d6
older_newer_file:
		subq.l	#2,d7
		bne	older_file_error

		lea	(a0),a1			;a0 = file1
@@:		tst.b	(a1)+			;a1 = file2
		bne	@b

		bsr	older_file_sub
		bmi	older_file_error
		move.l	d1,d2

		lea	(a1),a0
		bsr	older_file_sub
		bmi	older_file_error

		tst	d6
		beq	@f
		exg	d1,d2			;&newer-file なら逆にする
@@:
		cmp.l	d1,d2
		bcs	set_status_1		;より古い
older_file_error:
		bra	set_status_0		;より新しいか全く同じ
**		rts


* in	a0.l	ファイル名
* out	d0.l	エラーコード
*	d1.l	タイムスタンプ

older_file_sub:
		clr	-(sp)
		pea	(a0)
		DOS	_OPEN
		tst.l	d0
		bmi	older_file_sub_end

		clr.l	(sp)			;clr.l (2,sp)
		move	d0,(sp)
		DOS	_FILEDATE
		move.l	d0,d1
		bmi	older_file_sub_end

		DOS	_CLOSE
older_file_sub_end:
		addq.l	#6,sp
		tst.l	d0
		rts


*************************************************
*		&sync				*
*************************************************

＆sync::
		DOS	_FFLUSH
		clr.l	-(sp)
		move	#$f03,-(sp)
		DOS	_OS_PATCH
		subq	#1,(sp)
		DOS	_OS_PATCH
		subq	#1,(sp)
		DOS	_OS_PATCH
		addq.l	#6,sp
		rts


*************************************************
*		&clear-path-stack		*
*************************************************

＆clear_path_stack::
		lea	(directory_stack),a0
	.irpc	n,0123
		clr.b	(DIRSTACK_SIZE*n,a0)
	.endm
		bra	set_status_1
**		rts


*************************************************
*		&pushd				*
*************************************************

＆pushd::
		jsr	(＆cd)
		tst	(＠status)
		beq	pushd_end

		lea	(directory_stack+DIRSTACK_SIZE*DIRSTACK_NUM),a1
		lea	(-DIRSTACK_SIZE,a1),a0
		moveq	#(DIRSTACK_SIZE/8)*(DIRSTACK_NUM-1)-1,d0
@@:
		move.l	-(a0),-(a1)
		move.l	-(a0),-(a1)
		dbra	d0,@b

		lea	(oldpwd_buf),a1
		STRCPY	a1,a0
pushd_end:
		rts


*************************************************
*		&popd				*
*************************************************

＆popd::
		moveq	#0,d0
		lea	(directory_stack),a1
		tst.b	(a1)
		beq	popd_end

		jsr	(chdir_a1)
		beq	popd_end

		lea	(DIRSTACK_SIZE,a1),a0
		moveq	#(DIRSTACK_SIZE/8)*(DIRSTACK_NUM-1)-1,d0
@@:
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		dbra	d0,@b
		clr.b	(a1)
popd_end:
		bra	set_status
**		rts


*************************************************
*		&toggle-palet-illumination	*
*************************************************

＆toggle_palet_illumination::
		lea	(＄kpal),a0
		moveq	#1,d0
		and	d0,(a0)
		eor	d0,(a0)
		rts


* パレットイルミネーション -------------------- *

palet_illumination::
		tst	(＄kpal)
		beq	p_il_end

		PUSH	d1-d7/a0-a5

		moveq	#1,d1			;パレット 1 を処理
		lea	(p_il_time_1),a0
		lea	(＄col1),a1
		bsr	palet_illumi_sub

		moveq	#2,d1			;パレット 2 を処理
		addq.l	#p_il_time_2-p_il_time_1,a0
		lea	(＄col2-＄col1,a1),a1
		bsr	palet_illumi_sub

		POP	d1-d7/a0-a5
p_il_end:
		rts


* パレットイルミネーション下請け
* in	d1.l	パレット番号(1 or 2)
*	a0.l	p_il_time_1 or p_il_time_2
*	a1.l	＄col1 or ＄col2
* break	d0/d2-d3

palet_illumi_sub:
		moveq	#0,d0
		move	(＄kpc1-＄col1,a1),d0
		bsr	check_timer
		bne	p_il_sub_end

		moveq	#0,d2
		moveq	#$80-2,d3

		tst.b	(p_il_mode_1-p_il_time_1,a0)
		bmi	p_il_sub_dec		;減算中
p_il_sub_inc:
		move	(a1),d2			;現在のパレット
		add	(＄kps1-＄col1,a1),d2
		bcs	@f			;加算終了
		cmp	(＄kpu1-＄col1,a1),d2
		bls	p_il_sub_set
@@:
		addq.b	#1,d3
		bmi	p_il_sub_end		;加算も減算も出来ない

		st	(p_il_mode_1-p_il_time_1,a0)
		bra	p_il_sub_dec		;減算に切り換える
p_il_sub_dec:
		move	(a1),d2			;現在のパレット
		sub	(＄kps1-＄col1,a1),d2
		bcs	@f			;減算終了
		cmp	(＄kpd1-＄col1,a1),d2
		bcc	p_il_sub_set
@@:
		addq.b	#1,d3
		bmi	p_il_sub_end		;加算も減算も出来ない

		sf	(p_il_mode_1-p_il_time_1,a0)
		bra	p_il_sub_inc		;加算に切り換える
p_il_sub_set:
		move	d2,(a1)
		IOCS	_TPALET			;パレット変更
p_il_sub_end:
		rts


* IOCS _ONTIME タイマー ----------------------- *

* カウンタ初期化
* in	a0.l	前回時間バッファ(1.l)

init_timer::
		PUSH	d0-d3
		moveq	#0,d2
		bra.s	@f

* 指定時間が経過したか調べる
* in	d0.l	時間(1/100 秒単位)
*	a0.l	前回時間バッファ(1.l)
* out	ccr	Z=1: 経過した Z=0:経過していない

check_timer::
		PUSH	d0-d3
		move.l	d0,d2
@@:
		add.l	(a0),d2
		IOCS	_ONTIME
		move.l	d0,d3
		cmp.l	(a0),d0
		bcc	@f
		addi.l	#100*60*60*24,d0	;起動後 24 時間経過した場合の補正
@@:
		cmp.l	d2,d0
		bcc	check_timer_passed
		moveq	#-1,d0
		bra	check_timer_end
check_timer_passed:
		move.l	d3,(a0)			;経過していたら現在の時刻を記憶
		moveq	#0,d0
check_timer_end:
		POP	d0-d3
		rts


* スクリーンセーバ ---------------------------- *

* タイマー初期化
init_ss_timer::
		move.l	a0,-(sp)
		lea	(ss_time,pc),a0
		bsr	init_timer
		movea.l	(sp)+,a0
		rts


* 指定時間が経過していればセーバ起動
auto_screen_saver::
		move	(＄down),d0
		beq	auto_ss_end		;自動起動しない
		mulu	#100,d0
		lea	(ss_time,pc),a0
		bsr	check_timer
		beq	go_screen_saver_auto	;>T_DOWN 実行(未定義時は内蔵セーバ)
auto_ss_end:
		rts


*************************************************
*		&go-screen-saver		*
*************************************************

＆go_screen_saver::
		move.b	(in_ss_flag,pc),d0
		beq	go_ss_arg_next

		bra	builtin_ss		;>T_DOWN からの実行時は内蔵セーバ
go_ss_arg_loop:
		lea	(a0),a1
		cmpi.b	#'-',(a1)+
		bne	go_ss_arg_skip
		cmpi.b	#'z',(a1)+
		bne	go_ss_arg_skip
		tst.b	(a1)+
		beq	builtin_ss		;-z 指定時は初回でも直接内蔵セーバ
go_ss_arg_skip:
		tst.b	(a0)+
		bne	go_ss_arg_skip
go_ss_arg_next:
		subq.l	#1,d7
		bcc	go_ss_arg_loop

		jsr	(free_token_buf)
go_screen_saver_auto:
		tst.l	(kq_buffer+KQ_T_DOWN*4)
		beq	builtin_ss		;>T_DOWN 未定義時は内蔵セーバ

		lea	(in_ss_flag,pc),a1
		st	(a1)			;初回の実行時は >T_DOWN を呼び出す
		move	#KQ_T_DOWN<<8,d0
		jsr	(execute_quick_no)
		clr.b	(a1)
		rts


* 内蔵スクリーンセーバ
builtin_ss:
		move	(＄cont),d1
		IOCS	_CONTRAST

		bsr	init_ss_timer		;電源オフタイマ初期化
		lea	(ss_led_time,pc),a0	;LED 切り換え〃
		bsr	init_timer

		moveq	#14-1,d7		;LED フェーズ
builtin_ss_loop1:
		bsr	builtin_ss_keysns	;コントラストダウン中
		bne	builtin_ss_end

		DOS	_CHANGE_PR
		bsr	update_periodic_disp
		bsr	builtin_ss_led

		move	(＄crt！),d0
		beq	builtin_ss_loop1	;電源オフはしない
		mulu	#100,d0
		lea	(ss_time,pc),a0
		bsr	check_timer
		bne	builtin_ss_loop1

		moveq	#$0d,d1			;電源オフ
		IOCS	_TVCTRL
builtin_ss_loop2:
		bsr	builtin_ss_keysns	;CRT 電源オフ中
		bne	builtin_ss_end2

		DOS	_CHANGE_PR
		bsr	builtin_ss_led

		bra	builtin_ss_loop2
builtin_ss_end2:
		bsr	update_periodic_disp

		moveq	#$07,d1			;電源オン
		IOCS	_TVCTRL
builtin_ss_end:
		IOCS	_B_KEYINP

		IOCS	_LEDSET
		moveq	#-2,d1
		IOCS	_CONTRAST
		bra	init_ss_timer
**		rts


update_periodic_disp:
		jmp	(update_periodic_display)


* キー入力を見る
builtin_ss_keysns:
		move.l	(ss_time,pc),-(sp)
		moveq	#100,d0			;開始後 1 秒間はキー入力を無視する
		lea	(sp),a0
		bsr	check_timer
		addq.l	#4,sp
		bne	builtin_ss_keysns_skip

		IOCS	_B_KEYSNS
		tst.l	d0
		rts
builtin_ss_keysns_skip:
		moveq	#0,d0
		rts

* LED を点滅させる
builtin_ss_led:
		moveq	#10,d0
		lea	(ss_led_time,pc),a0
		bsr	check_timer
		bne	builtin_ss_led_skip
@@:
		lea	(MFP_TSR),a1
		IOCS	_B_BPEEK
		tst.b	d0
		bpl	@b			;送信可能になるまで待つ

		move.b	(ss_led_tbl,pc,d7.w),d1
		lea	(MFP_UDR-(MFP_TSR+1),a1),a1
		IOCS	_B_BPOKE

		subq.b	#1,d7
		bcc	@f
		moveq	#14-1,d7
@@:
builtin_ss_led_skip:
		rts


ss_time:	.ds.l	1
ss_led_time:	.ds.l	1
ss_led_phase:	.ds.b	1
in_ss_flag:	.ds.b	1

ss_led_tbl:	.dc.b	%1111_1111
		.dc.b	%1111_1110
		.dc.b	%1111_1100
		.dc.b	%1111_1001
		.dc.b	%1111_0011
		.dc.b	%1111_0111
		.dc.b	%1111_1111
		.dc.b	%1111_1111
		.dc.b	%1111_0111
		.dc.b	%1111_0011
		.dc.b	%1111_1001
		.dc.b	%1111_1100
		.dc.b	%1111_1110
		.dc.b	%1111_1111
		.even


*************************************************
*		&toggle-screen-saver		*
*************************************************

＆toggle_screen_saver::
		lea	(down_save,pc),a0
		move	(a0),d0
		lea	(＄down),a1
		move	(a1),d1
		beq	@f
		moveq	#0,d0			;0 以外 -> 0、0 -> 以前の %down
@@:
		move	d1,(a0)
		move	d0,(a1)
		bsr	set_status
		jmp	interrupt_window_print
**		rts

down_save:	.ds	1


*************************************************
*		&one-ring			*
*************************************************

＆one_ring::
		moveq	#0,d0
		moveq	#0,d6
		moveq	#4,d7
		lea	(one_ring_mes,pc),a0
		lea	(one_ring_ttl,pc),a1
		bra	print_sub
**		rts

one_ring_ttl:
		.dc.b	'The Lord of the Rings',0
one_ring_mes:
		.dc.b	'   One Ring to rule them all,',0
		.dc.b	'     One Ring to find them,',0
		.dc.b	'   One Ring to bring them all',0
		.dc.b	' and in the darkness bind them.',0
		.even


* 文字列の数値変換 ---------------------------- *

* atoi_a0 の a0 が a1 になっているだけ.
atoi_a1::
		exg	a0,a1
		bsr	atoi_a0
		exg	a0,a1
		rts


* 文字列を数値に変換する
* in	a0.l	文字列のアドレス
* out	d0.l	数値(エラーの場合は 0)
*	a0.l	数値の次のアドレス(エラーの場合は変わらない)
*	ccr	Z=1:変換成功 Z=0:エラー
* 備考:
*	オーバーフローは考慮しない.
*	自分自身を再帰呼び出ししている.

atoi_a0_sp:
		bsr	atoi_a0_skip_blank
atoi_a0::
		PUSH	d1-d3/a1
		lea	(a0),a1
		moveq	#0,d0
		moveq	#'0',d2
		moveq	#9,d3

		moveq	#0,d1
		move.b	(a0)+,d1
		cmp.b	d2,d1
		bne	@f
		move.b	(a0)+,d1
		cmpi.b	#'x',d1
		beq	atoi_a0_hex		;0x...
		cmpi.b	#'b',d1
		beq	atoi_a0_bin		;0b...
		bra	atoi_a0_dec_dive	;それ以外なら '0' を飛ばして十進
@@:
		cmpi.b	#'$',d1
		beq	atoi_a0_hex		;$...
		cmpi.b	#'R',d1
		beq	atoi_a0_rgb		;RGB(...)
*atoi_a0_dec:
		sub.b	d2,d1
		cmp.b	d3,d1
		bhi	atoi_a0_error
atoi_a0_dec_loop:
		add.l	d0,d0
		add.l	d0,d1
		add.l	d0,d0
		add.l	d0,d0
		add.l	d1,d0			;10N+n

		moveq	#0,d1
		move.b	(a0)+,d1
atoi_a0_dec_dive:
		sub.b	d2,d1
		cmp.b	d3,d1
		bls	atoi_a0_dec_loop
atoi_a0_ok:
		subq.l	#1,a0			;読み過ぎた分を戻す
atoi_a0_ok3:
		moveq	#0,d1			;CCR Z=1
atoi_a0_end:
		POP	d1-d3/a1
		rts

atoi_a0_error:
		lea	(a1),a0
atoi_a0_error2:
		moveq	#1,d1			;CCR Z=0
		bra	atoi_a0_end


* 0x[0-9a-fA-F]+
atoi_a0_hex:
		moveq	#'9',d3
		move.b	(a0)+,d1
		cmp.b	d3,d1
		bls	@f			;0-9
		andi.b	#$df,d1
		cmpi.b	#'A',d1
		bcs	atoi_a0_ok2
		cmpi.b	#'F',d1
		bhi	atoi_a0_ok2
		subq.b	#'A'-('9'+1),d1		;a-fA-F
@@:
		sub.b	d2,d1
		bcc	atoi_a0_hex_loop
		subq.l	#2,a0
		cmpa.l	a0,a1
		bne	atoi_a0_ok3		;"0x-" などは 0 + "x-" と見なす
		bra	atoi_a0_error2		;$x などは駄目
atoi_a0_hex_loop:
		lsl.l	#4,d0
		or.b	d1,d0			;16N+n

		moveq	#0,d1
		move.b	(a0)+,d1
		cmp.b	d3,d1
		bls	@f			;0-9
		andi.b	#$df,d1
		cmpi.b	#'A',d1
		bcs	atoi_a0_ok
		cmpi.b	#'F',d1
		bhi	atoi_a0_ok
		subq.b	#'A'-('9'+1),d1		;a-fA-F
@@:
		sub.b	d2,d1
		bcc	atoi_a0_hex_loop
		bra	atoi_a0_ok


* 0b[0-1]+
atoi_a0_bin:
		move.b	(a0)+,d1
		sub.b	d2,d1
		subq.b	#2,d1
		bcs	atoi_a0_bin_loop
atoi_a0_ok2:
		subq.l	#2,a0			;読み過ぎた分を戻す
		bra	atoi_a0_ok3		;"0b-" などは 0 + "b-" と見なす
atoi_a0_bin_loop:
		lsr.b	#1,d1
		addx.l	d0,d0			;2N+n

		moveq	#0,d1
		move.b	(a0)+,d1
		sub.b	d2,d1
		subq.b	#2,d1
		bcs	atoi_a0_bin_loop
		bra	atoi_a0_ok


* RGB(r,g,b[,i])
atoi_a0_rgb:
		cmpi.b	#'G',(a0)+
		bne	atoi_a0_rgb_error
		cmpi.b	#'B',(a0)+
		bne	atoi_a0_rgb_error
		cmpi.b	#'(',(a0)+
		bne	atoi_a0_rgb_error

		bsr	atoi_a0_sp		;R
		bne	atoi_a0_rgb_error
		moveq	#$1f,d1
		and	d0,d1
		ror	#5,d1			;%RRRR_R000_0000_0000

		moveq	#',',d2
		bsr	atoi_a0_skip_blank
		cmp.b	(a0)+,d2
		bne	atoi_a0_rgb_error

		bsr	atoi_a0_sp		;G
		bne	atoi_a0_rgb_error
		moveq	#$1f,d3
		and	d3,d0
		or	d0,d1
		ror	#5,d1			;%BBBB_BRRR_RR00_0000

		bsr	atoi_a0_skip_blank
		cmp.b	(a0)+,d2
		bne	atoi_a0_rgb_error

		bsr	atoi_a0_sp		;B
		bne	atoi_a0_rgb_error
		and	d3,d0
		add	d0,d0
		or	d0,d1			;%GGGG_GRRR_RRBB_BBB0

		bsr	atoi_a0_skip_blank
		cmp.b	(a0),d2
		bne	@f

		addq.l	#1,a0
		bsr	atoi_a0_sp		;I
		bne	atoi_a0_rgb_error
		andi	#1,d0
		or	d0,d1
@@:
		bsr	atoi_a0_skip_blank
		cmpi.b	#')',(a0)+
		bne	atoi_a0_rgb_error
*atoi_a0_rgb_ok:
		move.l	d1,d0
		bra	atoi_a0_ok3
atoi_a0_rgb_error:
		moveq	#0,d0
		bra	atoi_a0_error


* 空白文字を飛ばす.
atoi_a0_skip_blank:
		move.b	(a0)+,d0
		cmpi.b	#SPACE,d0
		beq	atoi_a0_skip_blank
		cmpi.b	#TAB,d0
		beq	atoi_a0_skip_blank
		subq.l	#1,a0
		rts


* Block Storage Section ----------------------- *

		.bss
		.even

p_il_time_1:	.ds.l	1
p_il_mode_1:	.ds.b	1
		.even
p_il_time_2:	.ds.l	1
p_il_mode_2:	.ds.b	1
		.even


directory_stack:
		.ds.b	DIRSTACK_SIZE*DIRSTACK_NUM

user_value_tbl::
		.ds.b	USER_VAL_SIZE
user_value_stopper::


		.end

* End of File --------------------------------- *
