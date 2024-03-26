# patternmatch.s - pattern matching (regexp)
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

* based on "fre.c" fre.c,v 2.1 1992/06/10 05:49:22 candy Exp candy


* Include File -------------------------------- *

		.include	mint.mac
		.include	sysval.def
		.include	doscall.mac
		.include	twoncall.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	copy_dir_name_a1_a2
* look.s
		.xref	bm_comp,bm_forward
* madoka3.s
		.xref	＠buildin,＠status
* mint.s
		.xref	twon_getopt
		.xref	search_cursor_file
		.xref	file_match_read,file_match_buffer
		.xref	ctypetable
* outside.s
		.xref	search_user_value_arg
		.xref	set_user_value_match_a2
		.xref	atoi_a0


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* -i/-c オプション処理 ------------------------ *

* -i/-c 初期値を設定する
* break	d0
* 備考:
*	(V)TwentyOne.sys -C、+C のとき、それぞれ
*	-i、-c が指定された状態に設定する.

init_i_c_option::
		jsr	(twon_getopt)
		lsl.l	#32-_TWON_C_BIT,d0
		subx.l	d0,d0
		addq.l	#1,d0
		move.l	d0,(_ignore_case)
		rts


* -i/-c オプションを解釈する
* in	a0.l	引数のアドレス
* out	a0.l	引数が "-i"、"-c" なら、次の引数
*	ccrZ	1:-i/-c オプション 0:それ以外
* break	d0
* 備考:
*	結果は _ignore_case に格納される.
*	-i/-c オプションでない場合は _ignore_case は
*	変更されないので、予め初期化しておくこと.

take_i_c_option::
		cmpi.b	#'-',(a0)+
		bne	take_ic_opt_end
		moveq	#1,d0
		cmpi.b	#'i',(a0)
		beq	@f
		moveq	#'c',d0
		sub.b	(a0),d0
		bne	take_ic_opt_end
@@:
		tst.b	(1,a0)
		bne	take_ic_opt_end

		move.l	d0,(_ignore_case)
		addq.l	#2+1,a0
		moveq	#0,d0			;ccrZ=1
take_ic_opt_end:
		subq.l	#1,a0
		rts


*************************************************
*		&exist				*
*************************************************

＆exist::
		tst	(PATH_FILENUM,a6)
		beq	exist_error

		bsr	init_i_c_option
exist_arg_next:
		subq.l	#1,d7
		bcs	exist_error		;パターン指定なし

		bsr	take_i_c_option
		beq	exist_arg_next
		move.b	(a0)+,d0
		beq	exist_arg_next
		cmpi.b	#'-',d0
		beq	exist_error		;不正なオプション

		subq.l	#1,a0			;パターン指定あり

		movea.l	(PATH_BUF,a6),a4
		bsr	exist_sub
		bmi	exist_error

		lea	(-24,sp),sp		;見つかったら $& にセット
		lea	(DIR_NAME,a4),a1
		lea	(sp),a2
		jsr	(copy_dir_name_a1_a2)
		jsr	(set_user_value_match_a2)
		lea	(24,sp),sp
		bra	@f
exist_error:
		moveq	#0,d0
@@:		bra	set_status
**		rts


.if 0
set_status_1:
		moveq	#1,d0
		bra.s	set_status
set_status_0:
		moveq	#0,d0
.endif
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts


* パターン指定ファイル検索
* in*	d7.l	引数の数-1(0 以上)
*	a0.l	引数列のアドレス
*	a4.l	検索を開始するバッファアドレス
*	a6.l	パスバッファ
* out	d0.l	見つかったバッファの位置(負数なら検索失敗)
*	a4.l	見つかったバッファのアドレス
*	ccr	<tst.l d0> の結果
* 備考:
*	Buffer を破壊する.

exist_sub_sp::
		PUSH	d1-d2/a0-a3		;空白を'|'に置換しない
		lea	(-24,sp),sp

		lea	(Buffer),a3		;コンパイルデータ格納用

		bsr	match_cat_pattern_sp
		bra	exist_sub_2

exist_sub::
		PUSH	d1-d2/a0-a3
		lea	(-24,sp),sp

		lea	(Buffer),a3		;コンパイルデータ格納用

		bsr	match_cat_pattern
exist_sub_2:
		tst.l	d7
		beq	@f
		move.b	#'|',-(a1)		;最後の引数も繋げる
@@:
		pea	(a0)			;pattern
		pea	(1024*10/2).w		;buffer size(.w)
		pea	(a3)
		bsr	_fre_compile
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	exist_sub_start
exist_sub_error:
		moveq	#-1,d0
		bra	exist_sub_end

exist_sub_loop:
		lea	(sizeof_DIR,a4),a4
exist_sub_start:
		lea	(DIR_ATR,a4),a1
		cmpi.b	#-1,(a1)+
		beq	exist_sub_error

		lea	(sp),a2
		jsr	(copy_dir_name_a1_a2)

		pea	(sp)			;string
		pea	(a3)			;buffer
		bsr	_fre_match
		addq.l	#8,sp
		tst.l	d0
		beq	exist_sub_loop
*exist_sub_found:
		move.l	a4,d0
		sub.l	(PATH_BUF,a6),d0
		divu	#sizeof_DIR,d0
**		andi.l	#$ffff,d0
exist_sub_end:
		lea	(24,sp),sp
		POP	d1-d2/a0-a3
		tst.l	d0
		rts


*************************************************
*		&file-match			*
*************************************************

＆file_match::
		moveq	#0,d2
		move	(＄fcmp),d2		;オフセット最大値
		moveq	#0,d5			;-o<offset>
		moveq	#0,d6
		move.l	d6,(_ignore_case)
file_match_arg_next:
		subq.l	#1,d7
		bcs	file_match_end		;パターン無指定

		bsr	take_i_c_option
		beq	file_match_arg_next
		move.b	(a0)+,d0
		beq	file_match_arg_next
		cmpi.b	#'-',d0
		bne	file_match_pattern	;パターン指定あり
*file_match_option:
		cmpi.b	#'o',(a0)+
		bne	file_match_end		;不正なオプション
*file_match_opt_o:
		jsr	(atoi_a0)		;-o<offset>
		cmp.l	d2,d0
		bhi	file_match_end		;オフセットが大きすぎる
		move.l	d0,d5
		tst.b	(a0)+
		bne	file_match_end		;数値指定エラー
		bra	file_match_arg_next

file_match_pattern:
		subq.l	#1,a0
		bsr	match_cat_pattern

		lea	(file_match_buffer),a2	;バッファ
		tst.l	d7
		beq	file_match_pat_only	;パターンだけ指定されている

		jsr	(file_match_read)	;ファイル読み込み
		bmi	file_match_end
file_match_pat_only:
		lea	(a0),a1			;a1 = パターン
@@:
		tst.b	(a0)+
		bne	@b
		clr.b	(a0)			;もうファイル名を破壊しても構わない
		move.b	#'*',-(a0)		;パターン末尾に '*' を加える

		adda.l	d5,a2			;オフセットを加算
		bsr	match_sub
		move.l	d0,d6
file_match_end:
		move.l	d6,d0
		bra	set_status
**		rts


* パターンマッチ
* in	a1.l	パターン(正規表現)のアドレス
*	a2.l	比較する文字列のアドレス
* out	d0.l	1:一致 0:不一致/エラー
*	ccr	<tst.l d0> の結果
* 備考:
*	Buffer を破壊する.

match_sub:
		PUSH	d1-d2/a0-a4
		lea	(Buffer),a3		;コンパイルデータ格納用
		lea	(a2),a4

		pea	(a1)			;pattern
		pea	(1024*10/2).w		;buffer size(.w)
		pea	(a3)			;buffer
		bsr	_fre_compile
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bne	match_sub_error

		pea	(a4)			;string
		pea	(a3)			;buffer
		bsr	_fre_match
		addq.l	#8,sp
		tst.l	d0			;0/1
@@:
		POP	d1-d2/a0-a4
		rts
match_sub_error:
		moveq	#0,d0
		bra	@b


* 複数のパターンを連結し、最後の引数のアドレスを得る
* in	d7.l	引数の数-1(0 以上)
*	a0.l	引数列のアドレス
* out	a0.l	パターン(最後の引数は連結されない)
*	a1.l	最後の引数のアドレス
* break	d0
* 機能:
*	match_cat_pattern:
*	  最後の引数以外を '|' で連結し、空白も '|' に置き換える.
*	match_cat_pattern_sp:
*	  最後の引数以外を '|' で連結する.
*
*	また、最後の引数のアドレスを a1 に返す.
*
*	例えば、
*	.dc.b	'reg exp',0,'xxx',0,'arg',0	;d7.l = 2 (=3-1)
*	となっている時に
*	.dc.b	'reg|exp|xxx',0,'arg',0
*	として返す. a1 は 'arg' を指す.

match_cat_pattern_sp:
		move.l	d1,-(sp)
		moveq	#0,d1			;空白はそのまま
		bra	@f
match_cat_pattern:
		move.l	d1,-(sp)
		moveq	#SPACE,d1		;空白を '|' に置き換える
@@:
		move.l	d7,-(sp)
		lea	(a0),a1
		bra	match_cat_pat_next
match_cat_pat_loop:
		cmp.b	d1,d0
		bne	match_cat_pat_next
		move.b	#'|',(-1,a1)		;' ' -> '|'
match_cat_pat_next:
		move.b	(a1)+,d0
		bne	match_cat_pat_loop

		move.b	#'|',(-1,a1)		;パターンを繋げる
		subq.l	#1,d7
		bhi	match_cat_pat_next

		clr.b	(-1,a1)			;繋げすぎたのを戻す
		move.l	(sp)+,d7
		move.l	(sp)+,d1
		rts


*************************************************
*		&match				*
*************************************************

＆match::
		moveq	#0,d6
		move.l	d6,(_ignore_case)
match_arg_next:
		subq.l	#1,d7
		bcs	match_end		;パターン指定なし

		bsr	take_i_c_option
		beq	match_arg_next
		move.b	(a0)+,d0
		beq	match_arg_next
		cmpi.b	#'-',d0
		beq	match_end		;不正なオプション

		subq.l	#1,a0			;パターン指定あり

		bsr	match_cat_pattern
		tst.l	d7
		bne	@f			;パターン/文字列指定あり
*match_pat_only:
		jsr	(search_user_value_arg)	;パターン省略時は $_
		movea.l	d0,a1
		addq.l	#2,a1			;'_',$01 を飛ばす
@@:
		lea	(a1),a2			;文字列
		lea	(a0),a1			;パターン
		bsr	match_sub
		move.l	d0,d6
match_end:
		move.l	d6,d0
		bra	set_status
**		rts


* fre_compile() ------------------------------- *

PUT:		.macro	ea
		cmp.l	a2,d5
		bls	@skip
		move	ea,(a2)+		;コンパイルデータ書き込み
@skip:
		.endm

_fre_compile::
		PUSH	d3-d7/a3-a5
		move.l	(36,sp),d0		;buffer
		move.l	(44,sp),a1		;pattern
		move.l	(40,sp),d1		;size
		add.l	d1,d1
		move.l	d0,d5
		add.l	d1,d5			;buffer end
		move.l	d0,a2
		lea	(ctypetable),a4

		moveq	#0,d7			;論理和の個数を求める
		moveq	#0,d1
		move.l	a1,a3
_mlp:
		move.b	(a3)+,d1
		beq	_orend
		cmpi.b	#'\',d1			;'\' なら次の一文字を飛ばす
		beq	_skip
		tst.b	(a4,d1.w)
		bpl	@f
		addq.l	#1,a3			;二バイト文字
		bra	_mlp
@@:		cmpi.b	#'|',d1
		bne	_mlp
		addq	#1,d7
		bra	_mlp
_skip:
		move.b	(a3)+,d1
		tst.b	(a4,d1.w)
		bpl	_mlp
		addq.l	#1,a3			;二バイト文字
		bra	_mlp
_orend:
_frec_next:
		moveq	#0,d1
		move.b	(a1)+,d1
		tst.b	(a4,d1.w)
		bpl	?10
		lsl	#8,d1			;二バイト文字
		move.b	(a1)+,d1
		bne	?10
		subq.l	#1,a1			;下位バイトが 0 だった
		moveq	#0,d1
		bra	?10

* ?10 に飛んだあとバッファが溢れてなければここへ来る
?150:
		tst.l	d1
		beq	?11
		moveq	#-'"',d0		;$22
		add	d1,d0
		cmpi	#'\'-'"',d0		;$3a
		bhi	_frec_normal
		add	d0,d0
@@:
		move	(_fre_jmptbl,pc,d0.w),d0
		jmp	(_fre_jmptbl,pc,d0.w)
_fre_jmptbl::
@@:		.dc	_frec_quote-@b		;$22 : "
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_quote-@b		;$27 : '
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_asterisk-@b	;$2a : * 
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
_fpr::		.dc	_frec_normal-@b		;$2e : . 
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
_fque::		.dc	_frec_question-@b	;$3f : ? 
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_normal-@b
		.dc	_frec_bracket-@b	;$5b : [
		.dc	_frec_b_slash-@b	;$5c : \

* メタキャラ『\』のコンパイル
_frec_b_slash:
		moveq	#0,d1
		move.b	(a1)+,d1
		beq	?16
		tst.b	(a4,d1.w)
		bmi	?15			;\Ａ
		cmpi.b	#'x',d1
		bne	?20			;\A

		move.b	(a1),d1			;\x..
		btst.b	#IS_XDIGT,(a4,d1.w)
		beq	?17			;数字が続いていない

		addq.l	#1,a1
		btst.b	#IS_DIGIT,(a4,d1.w)
		beq	1f
		subi.b	#'0',d1
		bra	2f
1:		ori.b	#$20,d1
		subi.b	#'a'-10,d1
2:		moveq	#0,d0
		move.b	(a1),d0
		btst.b	#IS_XDIGT,(a4,d0.w)
		beq	5f			;\x1
		btst.b	#IS_DIGIT,(a4,d0.w)
		beq	3f
		subi.b	#'0',d0
		bra	4f
3:		ori.b	#$20,d0
		subi.b	#'a'-10,d0
4:		lsl.b	#4,d1
		or.b	d0,d1
		addq.l	#1,a1
5:		ori	#$d700,d1
		bra	?20
?15:
		lsl	#8,d1
		move.b	(a1)+,d1		;二バイト文字
		bne	?20
**		subq.l	#1,a1			;下位バイトが 0 だった
**		moveq	#0,d1
?16:
		pea	(no_char_after_bslash_mes,pc)
		bra	_frec_error
?17:
		moveq	#'x',d1			;\xA などは xA と解釈する
?20:
		PUT	d1
		moveq	#0,d1
		bra	_frec_next

* メタキャラ『?』のコンパイル
_frec_question::
		PUT	#$d600+'?'
		bra	_frec_next

* メタキャラ『*』のコンパイル
_frec_asterisk:
		PUT	#$d600+'*'
		bra	_frec_next

* メタキャラ『[』のコンパイル
_frec_bracket:
		tst.b	(a1)
		bne	@f

		PUT	#'['			;パターンの末尾なら \[ と見なす
		bra	_frec_next
@@:
		moveq	#0,d0
		move.b	(a1)+,d0
		move.l	d0,d1
		tst.b	(a4,d0.w)
		bpl	?55

		move.b	(a1),d2			;二バイト文字
		beq	@f
		lsl	#8,d1
		moveq	#0,d0
		move.b	d2,d0
		or.l	d0,d1
		addq.l	#1,a1
		bra	?55
@@:
		moveq	#0,d1
?55:
		cmpi	#'^',d1
		beq	@f
		cmpi	#'!',d1
		bne	?60
@@:
		PUT	#$d600+'^'		;[^～] [!～]

		moveq	#0,d0
		move.b	(a1)+,d0
		move.l	d0,d1
		tst.b	(a4,d0.w)
		bpl	?69

		move.b	(a1),d2
		beq	@f
		lsl	#8,d1
		moveq	#0,d0
		move.b	d2,d0
		or.l	d0,d1
		addq.l	#1,a1
		bra	?69
@@:
		moveq	#0,d1
		bra	?69
?60:
		PUT	#$d600+'['		;[～]
?69:
		move.l	a2,a3
		cmp.l	a2,d5
		bls	@f
		clr	(a2)+
@@:
		cmpi	#']',d1
		bne	?72

		PUT	#'['

		moveq	#0,d0
		move.b	(a1)+,d0
		move.l	d0,d1
		tst.b	(a4,d0.w)
		bpl	?72

		move.b	(a1),d2			;二バイト文字
		beq	@f
		lsl	#8,d1
		moveq	#0,d0
		move.b	d2,d0
		or.l	d0,d1
		addq.l	#1,a1
		bra	?72
@@:
		moveq	#0,d1
?72:
		moveq	#0,d3
		bra	?80
?99:
		tst.l	d1
		beq	?81
		cmpi	#']',d1
		beq	?81
		cmpi	#'-',d1
		bne	?82
		tst.l	d3
		beq	?82

		moveq	#0,d0
		move.b	(a1)+,d0
		move.l	d0,d1
		tst.b	(a4,d0.w)
		bpl	?84

		move.b	(a1),d2			;二バイト文字
		beq	@f
		lsl	#8,d1
		moveq	#0,d0
		move.b	d2,d0
		or.l	d0,d1
		addq.l	#1,a1
		bra	?84
@@:
		moveq	#0,d1
?84:
		lea	(-2,a2),a0
		move	(a0),d0
		move	#$d600+'-',(a0)
		PUT	d0
		PUT	d1
		moveq	#0,d3
		bra	@f
?82:
		PUT	d1
		moveq	#1,d3
@@:
		moveq	#0,d0
		move.b	(a1)+,d0
		move.l	d0,d1
		tst.b	(a4,d0.w)
		bpl	?80

		move.b	(a1),d2			;二バイト文字
		beq	@f
		lsl	#8,d1
		moveq	#0,d0
		move.b	d2,d0
		or.l	d0,d1
		addq.l	#1,a1
		bra	?80
@@:
		moveq	#0,d1
?80:
		cmp.l	a2,d5
		bhi	?99
?81:
		tst.l	d1
		beq	_frec_bracket_error
		cmp.l	a2,d5
		bls	?10

		move.l	a2,d0
		sub.l	a3,d0
		asr.l	#1,d0
		subq	#1,d0
		move	d0,(a3)			;ワード数
		bra	_frec_next
_frec_bracket_error:
		pea	(missing_class_end_mes,pc)
		bra	_frec_error

* メタキャラ『"』『'』のコンパイル
_frec_quote:
		move.l	d1,d6
		moveq	#0,d0
		move.b	(a1)+,d0
		move.l	d0,d1
		tst.b	(a4,d0.w)
		bpl	?111

		move.b	(a1),d2			;二バイト文字
		beq	@f
		lsl	#8,d1
		moveq	#0,d0
		move.b	d2,d0
		or.l	d0,d1
		addq.l	#1,a1
		bra	?111
@@:
		moveq	#0,d1
?111:
		moveq	#0,d4
		moveq	#0,d3
		bra	?116
?125:
		cmp.l	d1,d6
		beq	?117			;同じ記号が出たら終わり

		PUT	d1

		move.b	(a1)+,d4
		move.l	d4,d1
		move.b	d1,d0
		tst.b	(a4,d4.w)
		bpl	?116

		move.b	(a1),d2
		beq	@f
		move.l	d1,d0
		lsl	#8,d0
		move.b	d2,d3
		move.l	d0,d1
		or.l	d3,d1
		addq.l	#1,a1
		bra	?116
@@:
		moveq	#0,d1
?116:
		tst.l	d1
		bne	?125
?117:
		tst.l	d1
		bne	_frec_next

		pea	(missing_dquote_mes,pc)
		cmpi	#'"',d6
		beq	@f
		addq.l	#4,sp
		pea	(missing_squote_mes,pc)
@@:		bra	_frec_error

* 通常文字のコンパイル
_frec_normal::
		moveq	#0,d4
		moveq	#0,d3
		bra	@f
?148:
		btst	#IS_ALPHA,(a4,d1.w)
		beq	?10			;英字でなかったらやめる
@@:
		PUT	d1			;A-Za-z

		move.b	(a1)+,d4
		move.l	d4,d1
		move.b	d1,d0
		tst.b	(a4,d4.w)
		bpl	?138

		move.b	(a1),d2
		beq	@f
		move.l	d1,d0
		lsl	#8,d0
		move.b	d2,d3
		move.l	d0,d1
		or.l	d3,d1
		addq.l	#1,a1
		bra	?138
@@:
		moveq	#0,d1
?138:
		cmpi	#$7f,d1
		bls	?148			;ASCII なら続ける
?10:
		tst.l	d7
		bpl	_or_comp		;初めの一回は '|' で無くても飛ぶ
		cmpi	#'|',d1
		bne	_or_exit		;*.p[i2]|*.x => _| 06 _* . _[ 02 i 2 
_or_comp:
		tst.l	d7			;'|' が存在しない、若しくは
		beq	_or_exit		;総ての '|' の処理が終った

		tst	d7
		beq	_or_done		;全部の '|' のマーク $d67c を書き終えた

		subq	#1,d7
		cmp.l	a2,d5
		bls	_frec_buf_over		;バッファが溢れた

		tst.l	d7
		bmi	_other_or		;二回目以降

		move	#$d600+'|',(a2)+
		move.l	a2,a5			;サイズを書き込むアドレス
		addq.l	#2,a2
		bset	#31,d7
		bra	_or_exit
_or_done:
		moveq	#0,d7			;'|' の全処理終了フラグ

		move.l	a2,d0
		sub.l	a5,d0
		lsr.l	#1,d0			;最後の論理和間のワード数
		move	d0,(a5)
		clr	(a2)+			;論理和グループの終了マーク

		move.b	(a1)+,d1
		tst.b	(a4,d1.w)
		bpl	_or_exit
		lsl	#8,d1
		move.b	(a1)+,d1
		bne	_or_exit
		subq.l	#1,a1
		moveq	#0,d1
		bra	_or_exit
_other_or:
		clr	(a2)+
		move	#$d600+'|',(a2)+
		move.l	a2,d0
		sub.l	a5,d0
		lsr.l	#1,d0			;最後の論理和間のワード数
		subq	#2,d0
		move	d0,(a5)
		move.l	a2,a5			;次のサイズを書き込むアドレス
		addq.l	#2,a2

		move.b	(a1)+,d1
		tst.b	(a4,d1.w)
		bpl	_or_exit
		lsl	#8,d1
		move.b	(a1)+,d1
		bne	_or_exit
		subq.l	#1,a1
		moveq	#0,d1
_or_exit:
		cmp.l	a2,d5
		bhi	?150
?11:
		cmp.l	a2,d5
		bls	_frec_buf_over

		clr	(a2)			;終了マーク
		moveq	#0,d0			;正常終了
_frec_return:
		POP	d3-d7/a3-a5
		rts
_frec_buf_over:
		pea	(regex_buffer_overflow_mes,pc)
_frec_error:
		move.l	(sp)+,d0
		bra	_frec_return


* fre_match() --------------------------------- *

* candy's _fre_match upper compatible routine by KIRAH

* d7 = ignore/first match exit flag
* a5 = pattern 先頭
* a6 = '|' の若いものを保持

_fre_match::
		PUSH	d3-d7/a2-a6
		lea	(ctypetable),a2
		move.l	(48,sp),a3		;string
		move.l	(44,sp),a4		;pattern
		movea.l	a4,a5
		move.l	(_text_end_address,pc),a6	;d7 31bit=1 の時のみ有効
		move.l	(_ignore_case,pc),d7
_fre_entry2:
		tst.l	d7
		bpl	_fre_entry		;通常モード
_fre_textmode:
		btst	#30,d7
		bne	_fre_entry		;マッチするまで読み飛ばさない
		cmpi.b	#$d6,(a4)
		beq	_fre_entry		;パターン先頭がメタキャラ
		cmpi.b	#$d7,(a4)
		beq	_fre_entry		;〃(\x??)

		PUSH	d0-d7/a2-a6
		link	a0,#-256
		lea	(-256,a0),a2
1:
		move.b	(a4)+,d0
		bne	2f
		move.b	(a4)+,d0
		beq	3f			;パターン終了
		move.b	d0,(a2)+		;一バイト文字を書き出す
		bra	1b
2:
		cmpi.b	#$d6,d0
		beq	3f			;メタキャラが出たら終わり
		cmpi.b	#$d7,d0
		beq	3f			;〃

		move.b	d0,(a2)+		;二バイト文字を書き出す
		move.b	(a4)+,(a2)+
		bra	1b
3:
		clr.b	(a2)

		lea	(-256,a0),a1		;検索用テーブル作成
		jsr	(bm_comp)

		movea.l	a3,a5
		move.l	(_text_end_address,pc),a6
		jsr	(bm_forward)		;パターン先頭の文字列を検索する
		unlk	a0
		POP	d0-d7/a2-a6
		beq	4f			;見つけた
		tst	d7
		bpl	_not_match		;他の論理和でもマッチしなかった
		movea.l	a6,a3
		bra	_match
4:
		movea.l	a1,a3			;見つけたアドレスから比較を開始する
_fre_entry:
		moveq	#0,d3
		moveq	#0,d4
		move.l	a3,a0			;string
		move.l	a4,a1			;pattern

		moveq	#0,d2
		move.b	(a0)+,d2
		tst.b	(a2,d2.w)
		bpl	?168
		lsl	#8,d2
		move.b	(a0)+,d2
		bne	?168
		subq.l	#1,a0
		moveq	#0,d2
		bra	?162
?168:
		move	(a1),d0
		beq	?160			;パターン終了
		move	d0,d1
		andi	#$ff00,d0
		cmpi	#$d600,d0
		beq	?161			;メタキャラ
		cmpi	#$d700,d0
		beq	?161			;〃
		cmp	d2,d1
		bne	?161

		addq.l	#2,a1			;一文字マッチした
		moveq	#0,d2
		move.b	(a0)+,d2
		tst.b	(a2,d2.w)
		bpl	?168
		lsl	#8,d2
		move.b	(a0)+,d2
		bne	?168
		subq.l	#1,a0
		moveq	#0,d2
		bra	?162
?160:
		tst.l	d7
		bmi	_match			;パターン終了の時点で一致と見なす
?161:
		tst.l	d2
		bne	_fre_next1
?162:
		tst	(a1)			;文字列が終了した場合
		beq	_match			;パターンも終了していれば一致
		bra	_fre_next1

* パターンの処理
_fre_loop:
		tst.b	(a3)
		bne	_fre_branch
		cmpi	#$d600+'*',(a4)
		beq	_fre_branch
		cmpi.b	#$d7,(a4)
		beq	_fre_branch

		tst	d7
		bpl	_not_match
		movea.l	a6,a3			;他の論理和で一致した場合
		bra	_match
_fre_branch:
		cmp.b	#$d7,(a4)
		beq	_fre_binary		;\x??
		move	(a4)+,d0
		cmpi	#$d600+'?',d0
		beq	_fre_question
		bgt	@f
		cmpi	#$d600+'*',d0
		beq	_fre_asta
		bra	_fre_normal
@@:
		cmpi	#$d600+'[',d0
		beq	_fre_class
		cmpi	#$d600+'^',d0
		beq	_fre_nclass
		cmpi	#$d600+'|',d0
		beq	_fre_or
		bra	_fre_normal

* メタキャラ『\x??』の処理
_fre_binary:
		addq.l	#1,a4			;$d7 を飛ばす
		cmp.b	(a3)+,(a4)+
		beq	_fre_next1		;一致
		tst.l	d7
		bpl	_not_match		;通常モードなら不一致
		btst	#30,d7
		bne	_not_match		;くっつき検索

		movea.l	a5,a4
		bra	_fre_textmode

* メタキャラ『|』の処理
_fre_or:
		moveq	#0,d3
		move	(a4)+,d5		;この区間のワード数

		move.l	a3,-(sp)
		move.l	a4,-(sp)
		bsr	_fre_match
		addq.l	#8,sp
		tst.l	d0
		beq	_fre_or_next		;不一致

		tst.l	d7
		bmi	@f
		movea.l	a1,a3			;通常モードなら一致確定
		bra	_match
@@:
		bset	#15,d7			;'|' で一致したフラグを立てておく
		cmpa.l	a6,a1
		bcc	@f
		movea.l	a1,a6			;若い方を保持
@@:
_fre_or_next:
		ext.l	d5
		add.l	d5,d5
		lea	(a4,d5.l),a4		;次のパターンまで飛ばす
		movea.l	a4,a5
		bra	_fre_entry2

* パターン
*	.dc	$d67c,7,'r','e','g','e','x','p',0
*	.dc	$d67c,4,'F','O','O',0
*	.dc	'T','E','S','T',0

* メタキャラ『?』の処理
_fre_question:
		moveq	#0,d0
		move.b	(a3)+,d0
		beq	?178			;空文字に一致
		tst.b	(a2,d0.w)
		bmi	2f
		tst.l	d7
		bpl	_fre_next1		;通常モードなら一致

		cmpi.b	#LF,d0			;復帰改行は不一致
		beq	@f
		cmpi.b	#CR,d0
		bne	_fre_next1
@@:		movea.l	a5,a4
		bra	_fre_textmode
2:
		tst.b	(a3)+			;二バイト文字
		bne	_fre_next1
?178:
		subq.l	#1,a3			;行き過ぎた分を戻す(ここへは滅多に来ない)
		bra	_fre_next1

* メタキャラ『*』の処理
_fre_asta:
		moveq	#0,d3
		move	(a4),d1
		bne	@f
		tst.l	d7
		bmi	_match			;パターン終了なら一致確定
@@:
		move.l	d1,d0
		andi	#$ff00,d0
		cmpi	#$d600,d0
		beq	?182			;'*' の次がメタキャラ
		cmpi	#$d700,d0
		beq	?182			;〃

		cmpi	#$00ff,d1
		bhi	?182
		moveq	#1,d3			;一バイト文字
		bra	?182
?217:
		tst.l	d3
		beq	?184
		move	(a4),d2
		cmpi	#$00ff,d2
		bhi	?186
		btst.b	#IS_LOWER,(a2,d2.w)
		beq	?186
		subi	#$20,d2		;大文字化
?186:
		tst.b	d7
		beq	?203
?201:
		moveq	#0,d1
		move.b	(a3),d1
		beq	?184
		tst.l	d7
		bpl	@f
		cmpi.b	#CR,d1
		beq	_fre_next1
		cmpi.b	#LF,d1
		beq	_fre_next1
@@:
		btst.b	#IS_LOWER,(a2,d1.w)
		beq	@f
		subi	#$20,d1			;大文字化
@@:
		cmp	d2,d1
		beq	?184

		moveq	#0,d0
		move.b	(a3)+,d0
		beq	@f
		tst.b	(a2,d0.w)
		bpl	?201
		tst.b	(a3)+
		bne	?201
@@:
		subq.l	#1,a3
		bra	?184
?210:
		moveq	#0,d0
		move.b	(a3),d0
		move.b	d0,d1
		ext	d1
		cmp	(a4),d1
		beq	?184
		tst.b	(a2,d0.w)
		bpl	?205
?207:
		moveq	#1,d0
		tst.b	(1,a3)
		beq	?206
		moveq	#2,d0
		bra	?206
?205:
		tst.b	d0
		beq	?184
		moveq	#1,d0
?206:
		add.l	d0,a3
?203:
		tst.b	(a3)
		bne	?210
?184:
		move.l	a3,-(sp)
		move.l	a4,-(sp)
		bset	#6,(_ignore_case)	;bset.l #30,(_ignore_case)
		bsr	_fre_match
		bclr	#6,(_ignore_case)
		addq.l	#8,sp
		tst.l	d0
		bne	_match

		move.b	(a3),d0
		tst.b	(a2,d0.w)
		bpl	@f

		moveq	#1,d0
		tst.b	(1,a3)
		beq	?213
		moveq	#2,d0
		bra	?213
@@:
		tst.b	d0
		beq	_fre_entry
		moveq	#1,d0
?213:
		add.l d0,a3
?182:
		move.b	(a3),d2
		beq	_fre_entry		;先に文字列が終わったら空にマッチさせる
		tst.l	d7
		bpl	?217
		cmpi.b	#CR,d2
		bne	?217
		cmpi.b	#LF,(1,a3)
		bne	@f
		addq.l	#1,a3			;LF を飛ばす
@@:
		addq.l	#1,a3			;CR を飛ばす
		movea.l	a5,a4
		bra	_fre_textmode

* メタキャラ『[^～]』の処理
_fre_nclass:
		moveq	#1,d6
		bra	@f

* メタキャラ『[～]』の処理
_fre_class:
		moveq	#0,d6
@@:
		move	(a4)+,d5		;ワード数
		ext.l	d5
		move.l	d5,d0
		add.l	d0,d0
		lea	(a4,d0.l),a0		;次のパターン
		moveq	#0,d4

		clr	d3
		move.b	(a3)+,d3
		tst.b	(a2,d3.w)
		bpl	@f
		lsl	#8,d3
		move.b	(a3)+,d3
		bne	?232
		subq.l	#1,a3
		clr	d3
@@:
		tst.b	d7
		beq	?232
		cmpi	#$00ff,d3
		bhi	?232
		btst	#IS_LOWER,(a2,d3.w)
		beq	?232
		subi	#$20,d3		;大文字化
		bra	?232
?251:
		tst.l	d4
		bne	?233
		cmpi	#$d600+'-',(a4)
		bne	?234

		move	(2,a4),d1		;'-' の処理
		move	(4,a4),d2
		tst.b	d7
		beq	?235
		cmpi	#$00ff,d1
		bhi	@f
		btst	#IS_LOWER,(a2,d1.w)
		beq	@f
		subi	#$20,d1		;大文字化
@@:
		cmpi	#$00ff,d2
		bhi	?235
		btst	#IS_LOWER,(a2,d2.w)
		beq	?235
		subi	#$20,d2		;大文字化
?235:
		moveq	#0,d0
		cmp	d3,d1
		bhi	@f
		cmp	d3,d2
		bcs	@f
		moveq	#1,d0			;範囲内に入った
@@:
		move.l	d0,d4
		addq.l	#6,a4
		subq.l	#3,d5
		bra	?232
?234:
		move	(a4),d1
		tst.b	d7
		beq	@f
		cmpi	#$00ff,d1
		bhi	@f
		btst	#IS_LOWER,(a2,d1.w)
		beq	@f
		subi	#$20,d1		;大文字化
@@:
		cmp	d1,d3
		seq	d0
		moveq	#1,d4
		and.l	d0,d4			;一文字と比較
		addq.l	#2,a4
		subq.l	#1,d5
?232:
		tst.l	d5
		bgt	?251			;まだ文字が残っている
?233:
		move.l	a0,a4
		tst.l	d4
		bne	@f			;文字があった

		tst.l	d6			;ない場合
		bne	_fre_next1		;[^～] なら一致したと見なす
		bra	?255
@@:
		tst.l	d6
		beq	_fre_next1		;一致した
?255:
		tst.l	d7
		bpl	_not_match		;通常モードなら不一致
		ror	#8,d3
		tst.b	d3
		beq	@f
		subq.l	#1,a3
@@:
		movea.l	a5,a4
		bra	_fre_textmode

* 通常文字の処理
_fre_normal:
		move	d0,d1
		clr	d2
		move.b	(a3)+,d2
		tst.b	(a2,d2.w)
		bpl	@f
		lsl	#8,d2
		move.b	(a3)+,d2
		bne	@f
		clr	d2
		subq	#1,a3
@@:
		tst.b	d7
		beq	_fre_normal_case
		cmpi	#$00ff,d2
		bhi	@f
		btst	#IS_LOWER,(a2,d2.w)
		beq	@f
		subi	#$20,d2		;大文字化
@@:
		cmpi	#$00ff,d1
		bhi	@f
		btst	#IS_LOWER,(a2,d1.w)
		beq	@f
		subi	#$20,d1		;大文字化
@@:
_fre_normal_case:
		cmp	d1,d2
		beq	_fre_next1		;一文字一致
		tst.l	d7
		bpl	_not_match		;通常モードなら不一致
		btst	#30,d7
		bne	_not_match		;くっつき検索

		ror	#8,d2
		tst.b	d2
		beq	@f
		subq.l	#1,a3
@@:
		subq.l	#1,a3
		movea.l	a5,a4
		bra	_fre_textmode

_fre_next1:
		tst	(a4)
		bne	_fre_loop		;パターンがまだある
		tst.l	d7
		bmi	_match			;パターン終了で一致確定
		tst.b	(a3)
		beq	_match			;通常モードは文字列も終了
_not_match:
		moveq	#0,d0
		POP	d3-d7/a2-a6
		rts
_match:
		moveq	#1,d0
		tst	d7
		bpl	@f			;論理和ではマッチしていない
		cmp.l	a6,a3
		bcs	@f
		movea.l	a6,a3			;前の論理和の方を返す
@@:
		movea.l	a3,a1
		POP	d3-d7/a2-a6
		rts


* Data Section -------------------------------- *

*		.data
		.even

_ignore_case::	.dc.l	0
_text_end_address::
		.dc.l	0

no_char_after_bslash_mes:
		.dc.b 'No character after \',0
missing_class_end_mes:
		.dc.b 'Missing ]',0
missing_dquote_mes:
		.dc.b 'Missing "',0
missing_squote_mes:
		.dc.b "Missing '",0
regex_buffer_overflow_mes:
		.dc.b 'Regex buffer overflow',0
		.even


		.end

* End of File --------------------------------- *
