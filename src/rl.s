# rl.s - readline driver
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

		.include	rl.mac
		.include	doscall.mac
		.include	iocscall.mac
		.include	twoncall.mac
.ifdef LIBRL
		.include	macro.mac
		.include	dosdef.mac
		.include	console.mac
.else
		.include	mint.mac
ATR_DIR:	.equ	DIRECTORY
ATR_ARC:	.equ	ARCHIVE
ATR_VOL:	.equ	VOLUME
.endif


* Offset Table -------------------------------- *

		.offset	0
~margin:	.ds.l	1
~fnckey_buf:	.ds.b	6*12
~consol_buf:	.ds.l	2
~locate_buf:	.ds.l	1
~cursor_buf:	.ds.b	1
		.quad
~comp_buf:	.ds.l	1
~comp_size:	.ds.l	1
~key_prev:	.ds	1
~key_curr:	.ds	1
~con_top:	.ds	1
~con_num:	.ds	1
~con_disp:	.ds.b	1
~con_save:	.ds.b	1
		.quad
sizeof_work:
		.text


* Macro --------------------------------------- *

CUR_PTR:	.macro	an
		movea.l	(_RL_BUF,a5),an
		adda.l	d7,an
		adda.l	d6,an			;カーソル位置
		.endm


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

rl_version:	.dc.b	'librl.a version 0.92',0
		.even


* ReadLineVersion ----------------------------- *

* out	d0.l	バージョン文字列

_ReadLineVersion::
		pea	(rl_version,pc)
		move.l	(sp)+,d0
		rts


* ReadLine ------------------------------------ *

* in	(4,sp).l	Struct ReadLine
* out	d0.l	終了キー
* break	d1-d2/a0-a2

* d5.l	文字列長
* d6.l	カーソル位置
* d7.l	表示開始位置

_ReadLine::
		PUSH	d3-d7/a3-a6
		movea.l	(4*9+4,sp),a5		;Struct ReadLine
		lea	(-sizeof_work,sp),sp
		lea	(sp),a6

		move.l	(_RL_WIDTH,a5),d0
		lsr.l	#1,d0
		sub.l	(_RL_MARGIN,a5),d0
		bls	@f
		moveq	#0,d0
@@:		add.l	(_RL_MARGIN,a5),d0
		move.l	d0,(~margin,a6)		;min (_RL_WIDTH/2, _RL_MARGIN)

		moveq	#12-1,d1
		pea	(~fnckey_buf,a6)
		move	#21,-(sp)
@@:
		DOS	_FNCKEY			;キー定義を保存
		addq.l	#6,(2,sp)
		addq	#1,(sp)
		dbra	d1,@b
		addq.l	#6,sp

		moveq	#12-1,d1
		pea	(fnckey_list,pc)
		move	#$100+21,-(sp)
@@:
		DOS	_FNCKEY			;キー定義を設定
		addq.l	#2,(2,sp)
		addq	#1,(sp)
		dbra	d1,@b
		addq.l	#6,sp

		moveq	#-1,d1
		IOCS	_B_LOCATE
		move.l	d0,(~locate_buf,a6)
		moveq	#-1,d1
		moveq	#-1,d2
		IOCS	_B_CONSOL
		movem.l	d1/d2,(~consol_buf,a6)
		moveq	#0<<16+0,d1
		move.l	#(96-1)<<16+(31-1),d2
		IOCS	_B_CONSOL

		lea	($992),a1		;カーソル点滅フラグ
		IOCS	_B_BPEEK
		move.b	d0,(~cursor_buf,a6)

		clr.l	(~key_prev,a6)
**		clr	(~key_curr,a6)

		bsr	con_init

		moveq	#0,d0
		move.l	(_RL_SIZE,a5),d1
		ble	rl_end

		movea.l	(_RL_BUF,a5),a0
		clr.b	(-1,a0,d1.l)
		moveq	#'.',d1
		moveq	#-1,d2
		cmp.b	(a0)+,d1
		beq	rl_check_loop		;先頭の '.' は無視する
		subq.l	#1,a0
rl_check_loop:
		move.b	(a0)+,d0
		beq	rl_check_end
		cmp.b	d1,d0
		bne	@f
		move.l	a0,d2
		subq.l	#1,d2
		sub.l	(_RL_BUF,a5),d2
@@:
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	rl_check_loop
		tst.b	(a0)+
		bne	rl_check_loop
		subq.l	#2,a0
		clr.b	(a0)+
rl_check_end:
		tst.b	(_RL_F_DOT,a5)
		beq	@f

		move.l	d2,(_RL_CSR_X,a5)
@@:
		subq.l	#1,a0
		sub.l	(_RL_BUF,a5),a0
		cmpa.l	(_RL_CSR_X,a5),a0
		bcc	@f

		move.l	a0,(_RL_CSR_X,a5)
@@:
		move.l	a0,d5			;文字列長
		move.l	(_RL_CSR_X,a5),d6	;カーソル位置
		moveq	#0,d7			;表示開始位置
		bsr	adjust_cursor
rl_loop_pl:
		bsr	print_line
rl_loop_sc:
		bsr	set_cursor
rl_loop:
		IOCS	_OS_CURON
		bsr	key_input
rl_loop_key:
		tst	d0
		bmi	rl_key_mb
		cmpi	#$20,d0
		bhi	rl_key_sb
		bcs	rl_key_ctrl
*rl_key_space:
		IOCS	_B_SFTSNS
		lsr	#2,d0			;CTRL
		bcs	rl_key_ctrl_space

		moveq	#$20,d0
rl_key_sb:
		move.b	d0,-(sp)		;一バイト文字
		moveq	#1,d0
		bra	@f
rl_key_mb:
		move	d0,-(sp)		;二バイト文字
		moveq	#2,d0
@@:
		lea	(sp),a0
		bsr	insert_string		;一文字挿入
		addq.l	#2,sp
		bra	rl_loop

rl_key_ctrl:
		move	d0,d1			;d0.w は残しておくこと
		add	d1,d1
		move	(@f-2,pc,d1.w),d1
		jmp	(@f,pc,d1.w)
@@:
		.dc	rl_key_ctrl_a-@b	;$01: C-a
		.dc	rl_key_ctrl_b-@b	;$02: C-b
		.dc	rl_key_ctrl_c-@b	;$03: C-c
		.dc	rl_key_ctrl_d-@b	;$04: C-d
		.dc	rl_key_ctrl_e-@b	;$05: C-e
		.dc	rl_key_ctrl_f-@b	;$06: C-f
		.dc	rl_key_ctrl_g-@b	;$07: C-g (BEL)
		.dc	rl_key_ctrl_h-@b	;$08: C-h (BS)
		.dc	rl_key_ctrl_i-@b	;$09: C-i (TAB)
		.dc	rl_key_ctrl_j-@b	;$0a: C-j (LF)
		.dc	rl_key_ctrl_k-@b	;$0b: C-k
		.dc	rl_key_ctrl_l-@b	;$0c: C-l (CLR)
		.dc	rl_key_ctrl_m-@b	;$0d: C-m (CR)
		.dc	rl_key_ctrl_n-@b	;$0e: C-n
		.dc	rl_loop-@b		;$0f: C-o
		.dc	rl_key_ctrl_p-@b	;$10: C-p
		.dc	rl_loop-@b		;$11: C-q
		.dc	rl_loop-@b		;$12: C-r
		.dc	rl_loop-@b		;$13: C-s
		.dc	rl_key_ctrl_t-@b	;$14: C-t
		.dc	rl_key_ctrl_u-@b	;$15: C-u
		.dc	rl_loop-@b		;$16: C-v
		.dc	rl_key_ctrl_w-@b	;$17: C-w
		.dc	rl_key_ctrl_x-@b	;$18: C-x
		.dc	rl_key_ctrl_y-@b	;$19: C-y
		.dc	rl_loop-@b		;$1a: C-z (EOF)
		.dc	rl_key_esc-@b		;$1b: C-[ (ESC)
		.dc	rl_loop-@b		;$1c: C-\
		.dc	rl_loop-@b		;$1d: C-]
		.dc	rl_loop-@b		;$1e: C-^
		.dc	rl_loop-@b		;$1f: C-_

* C-space、M-space : マーク設定
rl_key_ctrl_space:
rl_key_esc_space:
		move.l	d7,d0
		add.l	d6,d0
		move.l	d0,(_RL_MARK_X,a5)
		bra	rl_loop

* C-a : カーソルを行頭に移動
rl_key_ctrl_a:
		move.l	d7,d0
		moveq	#0,d6
		moveq	#0,d7
		tst.l	d0
		beq	@f
		bsr	print_line
@@:
		bra	rl_loop_sc

* C-b : カーソルを一文字左に移動
rl_key_ctrl_b:
		bsr	backward_char
		bra	rl_loop

backward_char:
		bsr	get_prev_char_size
		sub.l	d0,d6
		bsr	adjust_cursor_l
		beq	@f
		bsr	print_line
@@:		bsr	set_cursor
		rts

* C-d : カーソル位置の一文字を削除
rl_key_ctrl_d:
		cmp	(~key_prev,a6),d0
		beq	rl_key_ctrl_d_repeat	;C-d キーリピート時

		tst.l	d5
		beq	rl_end			;空なら終了

		bsr	get_cur_char_size
		beq	rl_key_ctrl_i		;行末なら補完

		bsr	delete_string		;一文字削除
		bra	rl_loop
rl_key_ctrl_d_repeat:
		bsr	get_cur_char_size
		beq	@f			;空または行末でも終了・補完しない

		bsr	delete_string		;一文字削除
@@:		bra	rl_loop


* C-e : カーソルを行末に移動
rl_key_ctrl_e:
		move.l	d5,d6
		sub.l	d7,d6
		bsr	adjust_cursor_r
		beq	@f
		bsr	print_line
@@:		bra	rl_loop_sc

* C-f : カーソルを一文字右に移動
rl_key_ctrl_f:
		bsr	forward_char
		bra	rl_loop

forward_char:
		bsr	get_cur_char_size
		add.l	d0,d6
		bsr	adjust_cursor_r
		beq	@f
		bsr	print_line
@@:		bsr	set_cursor
		rts

* C-h(BS) : カーソルの直前の一文字を削除
rl_key_ctrl_h:
		bsr	get_prev_char_size
		neg.l	d0
		bsr	delete_string		;一文字削除
		bra	rl_loop

* C-i(TAB)、M-.、M-/ : 補完
rl_key_ctrl_i:
		tst.b	(_RL_C_ATR,a5)
		beq	@f			;補完禁止
		bsr	complete
		bne	rl_loop_key
@@:
		bra	rl_loop

* C-k : カーソルより右側の文字列を削除
rl_key_ctrl_k:
		move.l	d5,d0			;末尾
		move.l	d7,d1
		add.l	d6,d1			;カーソル位置
		bsr	copy_region

		move.l	d5,d0
		sub.l	d1,d0			;0～
		bsr	delete_string
		bra	rl_loop

* CLR : 入力破棄
* C-l : 再表示
rl_key_ctrl_l:
		bsr	iocs_bitsns7
		tst.b	d1
		bpl	@f

		st	(_RL_MARK_X,a5)		;CLR
		movea.l	(_RL_BUF,a5),a1
		clr.b	(a1)
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		bra	rl_loop_pl
@@:
		add.l	d6,d7			;C-l
		move.l	(_RL_WIDTH,a5),d6
		addq.l	#1,d6
		lsr.l	#1,d6			;センタリング
		sub.l	d6,d7
		bsr	adjust_cursor
		bra	rl_loop_pl

* ↓ : カーソルを単語終端まで移動
* C-n : ヒストリを新しい方向に移動
* ROLL UP : 〃
rl_key_ctrl_n:
		bsr	iocs_bitsns7
		add.b	d1,d1
		bpl	@f

		tst.b	(_RL_F_DOWN,a5)		;↓
		beq	rl_key_esc_f
		bra	rl_end
@@:
		tst.b	(_RL_F_RU,a5)		;C-n
		beq	rl_loop
		bra	rl_end

* ↑ : カーソルを単語先頭まで移動
* C-p : ヒストリを古い方向に移動
* ROLL DOWN : 〃
rl_key_ctrl_p:
		bsr	iocs_bitsns7
		lsl.b	#3,d1
		bpl	@f

		tst.b	(_RL_F_UP,a5)		;↑
		beq	rl_key_esc_b
		bra	rl_end
@@:
		tst.b	(_RL_F_RD,a5)		;C-p
		beq	rl_loop
		bra	rl_end

* C-t : カーソル前後の文字を入れ換え
rl_key_ctrl_t:
		move.l	d7,d0
		add.l	d6,d0
		beq	@f			;カーソル位置が先頭
		cmp.l	d0,d5
		bne	1f

		bsr	backward_char		;カーソル位置が右端
		move.l	d7,d0
		add.l	d6,d0
		beq	@f			;一文字しかなかった
1:
		bsr	transpose_char
@@:
		bsr	forward_char
		bra	rl_loop

transpose_char:
		move	d6,d2
		subq	#1,d2
		moveq	#2,d4			;表示桁数
		clr.l	-(sp)			;カーソル補正分

		bsr	prev_ptr

		moveq	#0,d1			;前(左側)の文字を収得
		move.b	(a1)+,d1
		move.b	d1,d0
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f
		lsl	#8,d1
		move.b	(a1)+,d1
		subq	#1,d2
		addq	#1,d4
		subq.l	#1,(sp)
@@:
		moveq	#0,d3			;次(右側)の文字を収得
		move.b	(a1),d3
		move.b	d3,d0
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f
		lsl	#8,d3
		addq.l	#1,a1
		move.b	(a1),d3
		addq	#1,d4
		addq.l	#1,(sp)
@@:
		tst	d1
		bpl	@f
		move.b	d1,(a1)			;下位
		subq.l	#1,a1
		lsr	#8,d1
@@:		move.b	d1,(a1)			;上位

		move.b	d3,-(a1)		;下位
		lsr	#8,d3
		beq	@f
		move.b	d3,-(a1)		;上位
@@:
		move.l	(sp)+,d3
		add.l	d3,d6			;カーソル位置補正
		move.l	(_RL_MARK_X,a5),d0
		bmi	@f			;マーク未設定
		move.l	d7,d1
		add.l	d6,d1
		cmp.l	d0,d1
		bne	@f
		add.l	d3,(_RL_MARK_X,a5)	;マーク位置補正
@@:
		bsr	b_putmes
		rts

* C-u : カーソルより左側の文字列を削除
rl_key_ctrl_u:
		moveq	#0,d0			;先頭
		move.l	d7,d1
		add.l	d6,d1			;カーソル位置
		bsr	copy_region

		moveq	#0,d0
		sub.l	d1,d0			;～0
		bsr	delete_string
		bra	rl_loop

* C-w : リージョン内(マーク・カーソル間)の文字列を削除
rl_key_ctrl_w:
		move.l	(_RL_MARK_X,a5),d0
		bmi	rl_loop			;マーク未設定
		move.l	d7,d1
		add.l	d6,d1
		bsr	copy_region

		move.l	(_RL_MARK_X,a5),d0
		sub.l	d1,d0
		bsr	delete_string
		bra	rl_loop

* C-x : 二ストロークキー入力(CTRL)
rl_key_ctrl_x:
		bsr	key_input2
		cmpi	#'c'.and.$1f,d0
		beq	rl_key_cx_cc		;C-x C-c
		cmpi	#'x'.and.$1f,d0
		beq	rl_key_cx_cx		;C-x C-x
		cmpi	#'=',d0
		beq	rl_key_cx_equ		;C-x =
rl_key_error:
		move.l	(_RL_BELL,a5),d0
		beq	@f
		movea.l	d0,a0
		jsr	(a0)
@@:
		bra	rl_loop

* C-x C-x : カーソル位置とマーク位置の交換
rl_key_cx_cx:
		move.l	(_RL_MARK_X,a5),d0
		bmi	rl_loop			;マーク未設定

		move.l	d7,(_RL_MARK_X,a5)
		add.l	d6,(_RL_MARK_X,a5)
rl_goto_mark:
		move.l	d0,d6
		sub.l	d7,d6

		bsr	adjust_cursor
		beq	rl_loop_sc
		bra	rl_loop_pl

* C-x = : カーソル位置の文字コード表示
rl_key_cx_equ:
		subq.l	#8,sp
		lea	(sp),a0
		move	#'0x',(a0)+

		CUR_PTR	a1
		bsr	a1b_to_hex
		move.b	(a1)+,d0
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f
		bsr	a1b_to_hex
@@:		clr.b	(a0)

		bsr	con_save
		bsr	con_clear

		lea	(sp),a0
		moveq	#6,d0			;STRLEN a0,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	con_print

		addq.l	#8,sp
		bra	rl_loop

a1b_to_hex:
		moveq	#0,d0
		move.b	(a1),d0
		lsr.b	#4,d0
		move.b	(hex_table,pc,d0.w),(a0)+
		moveq	#$f,d0
		and.b	(a1),d0
		move.b	(hex_table,pc,d0.w),(a0)+
		rts

hex_table:	.dc.b	'0123456789abcdef'
		.even

* C-y、UNDO : 削除バッファの内容を貼り付け
rl_key_ctrl_y:
		move.l	(_RL_YANK_BUF,a5),d0
		beq	rl_loop

		movea.l	d0,a0
		move.l	(a0)+,d0		;サイズ
		bsr	insert_string
		bra	rl_loop

* C-[(ESC) : 二ストロークキー入力(META)
rl_key_esc:
		tst.b	(_RL_F_EMACS,a5)
		beq	rl_end

		bsr	key_input2
		cmpi	#'d'.and.$1f,d0
		beq	rl_key_esc_cd		;M-C-d
		cmpi	#'g'.and.$1f,d0
		beq	rl_key_esc_cg		;M-C-g
		cmpi	#'h'.and.$1f,d0
		beq	rl_key_esc_ch		;M-C-h
		cmpi	#ESC,d0
		beq	rl_end			;M-esc / M-C-[
		cmpi	#SPACE,d0
		beq	rl_key_esc_space	;M-space
		cmpi	#'.',d0
		beq	@f			;M-.
		cmpi	#'/',d0
@@:		beq	rl_key_ctrl_i		;M-/

		ori.b	#$20,d0
		cmpi	#'b',d0
		beq	rl_key_esc_b		;M-b
		cmpi	#'c',d0
		beq	rl_key_esc_c		;M-c
		cmpi	#'d',d0
		beq	rl_key_esc_d		;M-d
		cmpi	#'f',d0
		beq	rl_key_esc_f		;M-f
		cmpi	#'h',d0
		beq	rl_key_esc_h		;M-h
		cmpi	#'l',d0
		beq	rl_key_esc_l		;M-l
		cmpi	#'u',d0
		beq	rl_key_esc_u		;M-u
		cmpi	#'w',d0
		beq	rl_key_esc_w		;M-w
		bra	rl_key_error

* M-C-g : マーク位置に移動
rl_key_esc_cg:
		move.l	(_RL_MARK_X,a5),d0
		bmi	rl_loop			;マーク未設定
		bra	rl_goto_mark

* M-b : カーソルを単語先頭まで移動
rl_key_esc_b:
		bsr	get_prev_word_size
		sub.l	d0,d6
		bsr	adjust_cursor_l
		beq	@f
		bsr	print_line
@@:		bra	rl_loop_sc

* M-h、M-C-h : カーソル直前の単語を削除
rl_key_esc_h:
rl_key_esc_ch:
		bsr	get_prev_word_size
		neg.l	d0
		bra.s	@f

* M-d、M-C-d : カーソル位置の単語を削除
rl_key_esc_d:
rl_key_esc_cd:
		bsr	get_word_size
@@:
		move.l	d0,d2
		move.l	d7,d1
		add.l	d6,d1			;開始位置
		add.l	d1,d0			;終了位置
		bsr	copy_region

		move.l	d2,d0
		bsr	delete_string
		bra	rl_loop

* M-f : カーソルを単語終端まで移動
rl_key_esc_f:
		bsr	get_word_size
		add.l	d0,d6
		bsr	adjust_cursor_r
		beq	@f
		bsr	print_line
@@:		bra	rl_loop_sc

* M-c : カーソル位置から単語終端までキャピタライズ
rl_key_esc_c:
		bsr	rl_key_esc_clu
case_word_c_sub:
		moveq	#$20,d0
		or.b	(a1),d0
		cmpi.b	#'a',d0
		bcs	@f
		cmpi.b	#'z',d0
		bhi	@f
		lea	(case_word_l_sub,pc),a0
		bra	case_word_u_sub
@@:		rts

* M-l : カーソル位置から単語終端まで小文字化
rl_key_esc_l:
		bsr	rl_key_esc_clu
case_word_l_sub:
		cmpi.b	#'A',(a1)
		bcs	@f
		cmpi.b	#'Z',(a1)
		bhi	@f
		ori.b	#$20,(a1)
@@:		rts

* M-u : カーソル位置から単語終端まで大文字化
rl_key_esc_u:
		bsr	rl_key_esc_clu
case_word_u_sub:
		cmpi.b	#'a',(a1)
		bcs	@f
		cmpi.b	#'z',(a1)
		bhi	@f
		andi.b	#$df,(a1)
@@:		rts

rl_key_esc_clu:
		movea.l	(sp)+,a0
		bsr	get_word_size
		bsr	case_word
		bra	rl_loop

case_word:
		move.l	d0,d1
		beq	case_word_end
		CUR_PTR	a1
		move.l	d6,d2
case_word_loop:
		jsr	(a0)
		bsr	get_cur_char_size
		adda.l	d0,a1
		add.l	d0,d6
		sub.l	d0,d1
		bne	case_word_loop

		bsr	adjust_cursor_r
		beq	@f
		bsr	print_line
		bra	case_word_end
@@:
		move.l	d6,d4
		sub.l	d2,d4
		suba.l	d4,a1
		bsr	b_putmes
case_word_end:
		bsr	set_cursor
		rts

* M-w : リージョン内(マーク・カーソル間)の文字列をコピー
rl_key_esc_w:
		move.l	(_RL_MARK_X,a5),d0
		bmi	@f			;マーク未設定
		move.l	d7,d1
		add.l	d6,d1
		bsr	copy_region
@@:
		bra	rl_loop

* C-c、C-g(BEL)、C-j(LF)、C-m(CR)、C-x C-c : 終了
rl_key_ctrl_c:
rl_key_ctrl_g:
rl_key_ctrl_j:
rl_key_ctrl_m:
rl_key_cx_cc:
		bra	rl_end

rl_end:
		move.l	d0,-(sp)		;終了コード(キーコード)

		bsr	con_end

		tst.b	(~cursor_buf,a6)
		bne	@f
		IOCS	_OS_CUROF
@@:
		movem.l	(~consol_buf,a6),d1/d2
		IOCS	_B_CONSOL
		movem	(~locate_buf,a6),d1/d2
		IOCS	_B_LOCATE

		moveq	#12-1,d1
		pea	(~fnckey_buf,a6)
		move	#$100+21,-(sp)
@@:
		DOS	_FNCKEY			;キー定義を復帰
		addq.l	#6,(2,sp)
		addq	#1,(sp)
		dbra	d1,@b
		addq.l	#6,sp

		move.l	(sp)+,d0

		lea	(sizeof_work,sp),sp
		POP	d3-d7/a3-a6
		rts


* 下請け -------------------------------------- *

* IOCS _B_PUTMES 呼び出し
* in	d2.w	表示開始桁位置(ウィンドウ内位置)
*	d4.w	表示桁数
*	a1.l	文字列
* break	d0-d4/a1
b_putmes:
		IOCS	_B_CUROFF
		move.b	(_RL_COL,a5),d1
		add	(_RL_WIN_X,a5),d2
		move	(_RL_WIN_Y,a5),d3
		subq	#1,d4
		IOCS	_B_PUTMES
		IOCS	_B_CURON
		rts

* IOCS _BITSNS(7) 呼び出し
* out	d1.w	キーの押し下げ状態
iocs_bitsns7:
		move.l	d0,-(sp)
		moveq	#7,d1
		IOCS	_BITSNS
		move	d0,d1
		move.l	(sp)+,d0
		rts

* 一行表示
print_line:
		PUSH	d0-d4/a1
		moveq	#0,d2
		move.l	(_RL_WIDTH,a5),d4
		movea.l	(_RL_BUF,a5),a1
		adda.l	d7,a1
		bsr	b_putmes
		POP	d0-d4/a1
		rts

* 直前の文字のアドレスを返す
* out	a1.l	アドレス
prev_ptr:
		move.l	a0,-(sp)
		movea.l	(_RL_BUF,a5),a0
		lea	(-1,a0,d7.l),a1
		adda.l	d6,a1			;一バイト前
		bsr	ismbtrail
		bcc	@f
		subq.l	#1,a1			;二バイト前
@@:		movea.l	(sp)+,a0
		rts

* カーソル位置設定
set_cursor:
		PUSH	d0-d2
		move	(_RL_WIN_X,a5),d1
		move	(_RL_WIN_Y,a5),d2
		add	d6,d1
		IOCS	_B_LOCATE
		POP	d0-d2
		rts

* 指定アドレスが二バイト文字の下位バイトか調べる
* in	a0.l	文字列先頭
*	a1.l	調べるバイト
* out	ccr	C=1:下位バイトだった
*		C=0:上位バイト若しくは一バイト文字

ismbtrail:
		PUSH	d0-d1/a0-a1
		move	a1,d1
		bra	1f
ismbtrail_loop:
		move.b	-(a1),d0
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f
1:		cmpa.l	a0,a1
		bhi	ismbtrail_loop
		subq.l	#1,a1
@@:
		addq.l	#1,a1
		sub	a1,d1
		lsr	#1,d1
		POP	d0-d1/a0-a1
		rts


* カーソル位置の単語のバイト数を得る ---------- *
* out	d0.l	バイト数
*	ccr	<tst.l d0> の結果

get_word_size:
		PUSH	d1/a1
		CUR_PTR	a1
		move.l	a1,d1
@@:
		move.b	(a1)+,d0
		beq	get_word_size_end
		bsr	is_wordchar
		bmi	@b
		adda.l	d0,a1
		bne	@b
@@:
		move.b	(a1)+,d0
		beq	get_word_size_end
		bsr	is_wordchar
		bmi	get_word_size_end
		adda.l	d0,a1
		bra	@b
get_word_size_end:
		subq.l	#1,a1
		suba.l	d1,a1
		move.l	a1,d0
		POP	d1/a1
		rts


* カーソル直前の単語のバイト数を得る ---------- *
* out	d0.l	バイト数
*	ccr	<tst.l d0> の結果

get_prev_word_size:
		PUSH	d1/a1
		movea.l	(_RL_BUF,a5),a0
		CUR_PTR	a1
		move.l	a1,d1
@@:
		cmpa.l	a0,a1
		beq	get_prev_word_size_end
		bsr	get_prev_word_size_sub
		bne	@b
@@:
		cmpa.l	a0,a1
		beq	get_prev_word_size_end
		bsr	get_prev_word_size_sub
		bpl	@b
		addq.l	#1,a1
get_prev_word_size_end:
		move.l	d1,d0
		sub.l	a1,d0
		POP	d1/a1
		rts

get_prev_word_size_sub:
		subq.l	#1,a1
		bsr	ismbtrail
		bcc	1f
		subq.l	#1,a1
1:		move.b	(a1),d0
		bsr	is_wordchar
		rts


* カーソル位置の文字のバイト数を得る ---------- *
* out	d0.l	0:行末 1:一バイト文字 2:二バイト文字
*	ccr	<tst.l d0> の結果

get_cur_char_size:
		move.l	a1,-(sp)
		CUR_PTR	a1
		moveq	#0,d0
		move.b	(a1),d0
		beq	@f			;行末
		lsr.b	#5,d0
		btst	d0,#%10010000
		seq	d0
		addq.b	#2,d0
@@:
		movea.l	(sp)+,a1
		tst.l	d0
		rts


* カーソル直前の文字のバイト数を得る ---------- *
* out	d0.l	0:行頭 1:一バイト文字 2:二バイト文字
*	ccr	<tst.l d0> の結果

get_prev_char_size:
		move.l	d7,d0
		add.l	d6,d0
		beq	@f			;行頭

		move.l	a1,-(sp)
		add.l	(_RL_BUF,a5),d0
		bsr	prev_ptr
		sub.l	a1,d0
		movea.l	(sp)+,a1
@@:
		rts


* カーソル位置補正 ---------------------------- *
* i/o	d6.l	カーソル位置
*	d7.l	表示開始位置
* out	ccr	Z=0:d7.l の値が変更された
*		Z=1:d7.l の値は同じ

adjust_cursor_l:
		PUSH	d0-d4/a0-a1
		moveq	#-1,d3
		bra	@f
adjust_cursor_r:
		PUSH	d0-d4/a0-a1
		moveq	#+1,d3
		bra	@f
adjust_cursor:
		PUSH	d0-d4/a0-a1
		moveq	#0,d3
@@:
		move.l	d7,d4

		movea.l	(_RL_BUF,a5),a0
		CUR_PTR	a1
		bsr	ismbtrail
		bcc	@f			;カーソルが二バイト文字の中にある場合は
		subq.l	#1,d6			;一桁左に移動して補正する
		bcc	@f

		moveq	#0,d6			;もともと左端なら
		subq.l	#1,d7			;表示位置を移動する
@@:
		tst.l	d7			;0 <= d7 に補正
		bpl	@f
		add.l	d7,d6
		moveq	#0,d7
@@:
		tst.l	d6			;0 <= d6 に補正
		bpl	@f
		add.l	d6,d7
		moveq	#0,d6
@@:
		move.l	(_RL_SIZE,a5),d0
		subq.l	#1,d0
		move.l	(_RL_WIDTH,a5),d1
		sub.l	d1,d0			;d0 = d7 上限
		bhi	adj_csr_wide

		add.l	d7,d6			;スクロールなしの場合は
		moveq	#0,d7			;左端から表示する
		bra	adj_csr_end
adj_csr_wide:
		cmp.l	d0,d7
		bls	@f
		add.l	d7,d6
		sub.l	d0,d6
		move.l	d0,d7
@@:
		CUR_PTR	a1
		tst.l	d6
		bmi	adj_csr_minus		;d6 < 0
		cmp.l	d6,d1
		bcc	adj_csr_center		;0 <= d6 <= XLEN

		STRLEN	a1,d0			;XLEN < d6
		bne	adj_csr_wide2

		add.l	d6,d7			;┌──┐	　┌──┐
		sub.l	d1,d7			;ａｂｃｄｅ□	ａｂｃｄｅ□
		move.l	d1,d6
		bra	adj_csr_chk_r
adj_csr_center:
		move.l	d1,d2
		sub.l	(~margin,a6),d2
		cmp.l	d6,d2
		bcs	adj_csr_c_r

		move.l	(~margin,a6),d2
		cmp.l	d2,d6
		bhi	adj_csr_chk_r
		tst	d3
		bgt	adj_csr_end		;右移動時は左端の処理をしない

		move.l	d7,d0
		add.l	d6,d0
		cmp.l	d2,d0
		bls	@f
		move.l	d2,d0
@@:
		add.l	d6,d7			;　┌──┐	┌──┐
		sub.l	d0,d7			;ａ■ｂｃｄ	ａ■ｂｃｄ
		move.l	d0,d6
		bra	adj_csr_chk_l
adj_csr_c_r:
		tst	d3
		bmi	adj_csr_chk_r
		STRLEN	a1,d0			;┌──┐	　　┌──┐
		beq	adj_csr_chk_r		;ａｂｃｄ■ｆ	ａｂｃｄ■ｆ
		move.l	d6,d2
		add.l	d0,d2
		cmp.l	d2,d1
		bcc	adj_csr_chk_r
adj_csr_wide2:
		move.l	(~margin,a6),d2
		cmp.l	d2,d0
		bls	@f
		move.l	d2,d0
@@:
		add.l	d6,d7
		move.l	d1,d6
		sub.l	d0,d6
		sub.l	d6,d7
		bra	adj_csr_chk_r
adj_csr_minus:
		add.l	d6,d7
		moveq	#0,d6
		tst.l	d7
		bpl	@f
		sub.l	d7,d6
		moveq	#0,d7
@@:
		tst.l	d7
		beq	adj_csr_end

		move.l	(~margin,a6),d0		;0 <= d6, 0 < d7
		cmp.l	d7,d0
		bls	@f
		move.l	d7,d0
@@:
		cmp.l	d0,d6
		bcc	adj_csr_chk_r

		add.l	d6,d7
		move.l	d0,d6
		sub.l	d6,d7
adj_csr_chk_r:
		moveq	#+1,d0
		bra	@f
adj_csr_chk_l:
		moveq	#-1,d0
@@:
		movea.l	(_RL_BUF,a5),a0
		lea	(a0),a1
		adda.l	d7,a1
		bsr	ismbtrail
		bcc	@f
		add.l	d0,d7
		sub.l	d0,d6
@@:
adj_csr_end:
		cmp.l	d4,d7
		POP	d0-d4/a0-a1
		rts


* キー入力(FEP コントロール版) ---------------- *
* out	d0.l	入力したキー(二バイト文字対応)

key_input2:
		tst.b	(_RL_F_FEP,a5)
		beq	key_input		;FEP コントロールは使用しない

		pea	(8)			;固定モード収得
		DOS	_KNJCTRL
		move.l	d0,(sp)+
		bmi	key_input		;FEP なし

		move.l	d0,-(sp)
		pea	(7)			;固定モード設定
		DOS	_KNJCTRL
		addq.l	#8,sp
		tst.l	d0
		beq	key_input		;変換モードになっていない

		subq.l	#4,sp
		move.l	d0,-(sp)
		clr.l	-(sp)
		pea	(1)			;変換モード設定
		DOS	_KNJCTRL
		addq.l	#8,sp

		bsr	key_input
		move.l	d0,(4,sp)

		pea	(1)			;変換モード設定
		DOS	_KNJCTRL
		addq.l	#8,sp

		move.l	(sp)+,d0
		rts


* キー入力 ------------------------------------ *
* out	d0.l	入力したキー(二バイト文字対応)

key_input_nul:
		addq.l	#2,sp
		move.l	(_RL_NULL,a5),d0
		beq	@f

		PUSH	d1-d2/a0-a2
		movea.l	d0,a0
		jsr	(a0)
		POP	d1-d2/a0-a2
		bra	key_input
@@:
		DOS	_CHANGE_PR
key_input:
		move	#$ff,-(sp)
		DOS	_INPOUT
		move.b	d0,(sp)
		beq	key_input_nul		;入力待ち

		lsr.b	#5,d0
		btst	d0,#%10010000
		bne	key_input_mb
*key_input_sb:
		move.b	(sp)+,d0		;一バイト文字
key_input_end:
		move	(~key_curr,a6),(~key_prev,a6)
		move	d0,(~key_curr,a6)
		rts
key_input_mb:
		DOS	_INKEY			;二バイト文字の下位バイトを収得
		move.b	d0,(1,sp)
		beq	key_input_nul		;$xx00 は無視する
		move	(sp)+,d0
		bra	key_input_end


* 指定範囲をカットバッファにコピー ------------ *
* in	d0.l	開始位置
*	d1.l	終了位置
* out	d0.l	エラーコード
* 備考:
*	d0 と d1 は逆でも構わない.

copy_region:
		PUSH	d1/a0-a1
		cmp.l	d0,d1
		bcc	@f
		exg	d0,d1
@@:
		movea.l	(_RL_BUF,a5),a1
		adda.l	d0,a1			;開始位置
		sub.l	d0,d1			;バイト数

		move.l	(_RL_YANK_BUF,a5),d0
		beq	cp_reg_free_skip

		clr.l	(_RL_YANK_BUF,a5)
		PUSH	d1-d2/a1-a2
		move.l	d0,-(sp)
		move.l	(_RL_MFREE,a5),d0
		beq	1f
		movea.l	d0,a0
		jsr	(a0)
		bra	@f
1:		DOS	_MFREE
@@:		addq.l	#4,sp
		POP	d1-d2/a1-a2
cp_reg_free_skip:
		move.l	d1,d0
		beq	cp_reg_end

		addq.l	#4+1,d0
		PUSH	d1-d2/a1-a2
		move.l	d0,-(sp)
		move.l	(_RL_MALLOC,a5),d0
		beq	1f
		movea.l	d0,a0
		jsr	(a0)
		bra	@f
1:		DOS	_MALLOC
@@:		move.l	d0,(sp)+
		POP	d1-d2/a1-a2
		ble	cp_reg_end

		move.l	d0,(_RL_YANK_BUF,a5)
		movea.l	d0,a0
		move.l	d1,(a0)+		;バイト数
		subq.l	#1,d1
@@:
		move.b	(a1)+,(a0)+
		dbra	d1,@b
		clr	d1
		subq.l	#1,d1
		bcc	@b
		clr.b	(a0)+

		moveq	#0,d0
cp_reg_end:
		POP	d1/a0-a1
		rts


* カーソル位置から文字列を削除する ------------ *
* in	d0.l	バイト数(負数ならカーソルより左側を削除)

delete_string:
		PUSH	d0-d4/a0-a1
		move.l	d7,d1
		add.l	d6,d1
		move.l	d1,d2
		add.l	d0,d2
		cmp.l	d1,d2
		bhi	del_str_right
		beq	del_str_end
*del_str_left:
		neg.l	d0			;d2 ～ [d1]
		exg	d1,d2
		bsr	del_str_sub
		sub.l	d0,d6
		bsr	adjust_cursor_l
		bra	@f
del_str_right:
		bsr	del_str_sub		;[d1] ～ d2
		bsr	adjust_cursor
@@:		beq	@f

		bsr	print_line
		bra	del_str_end
@@:
		CUR_PTR	a1
		move	d6,d2
		move.l	(_RL_WIDTH,a5),d4
		sub	d6,d4
		bsr	b_putmes
del_str_end:
		bsr	set_cursor
		POP	d0-d4/a0-a1
		rts

del_str_sub:
		move.l	(_RL_MARK_X,a5),d3	;マーク位置補正
		bmi	@f
		cmp.l	d3,d1
		bcc	@f			;マーク <= 先頭
		sub.l	d0,d3
		cmp.l	d1,d3
		bcc	1f			;末尾 <= マーク
		move.l	d1,d3			;先頭 < マーク < 末尾
1:		move.l	d3,(_RL_MARK_X,a5)
@@:
		movea.l	(_RL_BUF,a5),a0
		lea	(a0),a1
		adda.l	d1,a0
		adda.l	d2,a1
		STRCPY	a1,a0

		sub.l	d0,d5
		rts


* カーソル位置に文字列を挿入する -------------- *
* in	a0.l	挿入する文字列
*	d0.l	バイト数

insert_string:
		PUSH	d0-d4/a0-a3
		move.l	(_RL_SIZE,a5),d1
		subq.l	#1,d1
		sub.l	d5,d1			;残りサイズ
		cmp.l	d1,d0
		bls	@f
		move.l	d1,d0
@@:		tst.l	d0
		beq	ins_str_end

		lea	(-1,a0,d0.l),a1		;挿入文字列末尾
		move.b	(a1),d2			;最後の文字が二バイト文字の上位バイトなら
		lsr.b	#5,d2			;取り除く
		btst	d2,#%10010000
		beq	@f
		bsr	ismbtrail
		bcs	@f
		subq.l	#1,d0
		beq	ins_str_end
@@:
		move.l	d7,d1
		add.l	d6,d1
		move.l	(_RL_MARK_X,a5),d2
		bmi	@f			;マーク未設定
		cmp.l	d2,d1
		bcc	@f
		add.l	d0,(_RL_MARK_X,a5)	;マーク位置補正
@@:
		movea.l	(_RL_BUF,a5),a1
		adda.l	d1,a1			;カーソル位置
		lea	(a1),a2
@@:		tst.b	(a2)+
		bne	@b
		move.l	a2,d1
		sub.l	a1,d1			;NUL を含めたバイト数
		subq.l	#1,d1
		lea	(a2,d0.l),a3
@@:
		move.b	-(a2),-(a3)		;カーソル以降の文字をうしろにずらす
		dbra	d1,@b
		clr	d1
		subq.l	#1,d1
		bcc	@b

		lea	(a1),a2
		move.l	d0,d1
		subq.l	#1,d1
@@:
		move.b	(a0)+,(a2)+		;文字列をコピーする
		dbra	d1,@b
		clr	d1
		subq.l	#1,d1
		bcc	@b

		move	d6,d2
		add.l	d0,d5
		add.l	d0,d6			;カーソル位置補正
		bsr	adjust_cursor_r
		beq	@f

		bsr	print_line
		bra	ins_str_end
@@:
		move.l	(_RL_WIDTH,a5),d4
		sub	d2,d4
		bsr	b_putmes
ins_str_end:
		bsr	set_cursor
		POP	d0-d4/a0-a3
		rts


* カーソル直前の文字列を置換する -------------- *
* in	a0.l	挿入する文字列
*	d0.l	挿入するバイト数
*	d1.l	削除するバイト数

replace_string:
		PUSH	d0-d4/a0-a2
		tst.l	d1
		bne	@f

		bsr	insert_string		;挿入のみ
		bra	rep_str_end
@@:
		move.l	(_RL_SIZE,a5),d2
		subq.l	#1,d2
		sub.l	d5,d2
		add.l	d1,d2			;削除後の残りサイズ
		cmp.l	d2,d0
		bls	@f
		move.l	d2,d0
@@:		tst.l	d0
		beq	rep_str_delete

		lea	(-1,a0,d0.l),a1		;挿入文字列末尾
		move.b	(a1),d2			;最後の文字が二バイト文字の上位バイトなら
		lsr.b	#5,d2			;取り除く
		btst	d2,#%10010000
		beq	@f
		bsr	ismbtrail
		bcs	@f
		subq.l	#1,d0
		bne	@f
rep_str_delete:
		move.l	d1,d0
		neg.l	d0
		bsr	delete_string		;削除のみ
		bra	rep_str_end
@@:
		move.l	d7,d2
		add.l	d6,d2			;カーソル位置
		move.l	d2,d3
		sub.l	d1,d3			;削除先頭位置
		move.l	(_RL_MARK_X,a5),d4
		bmi	rep_str_no_mark		;マーク未設定
		cmp.l	d4,d3
		bcc	rep_str_no_mark		;マーク <= 削除先頭

		sub.l	d1,d4			;削除後のマーク位置
		cmp.l	d3,d4
		bgt	1f
		move.l	d3,d4			;削除先頭 < マーク <= カーソル
		bra	@f
1:		add.l	d0,d4			;カーソル < マーク
@@:
		move.l	d4,(_RL_MARK_X,a5)	;マーク位置補正
rep_str_no_mark:
		movea.l	(_RL_BUF,a5),a1
		lea	(a1,d2.l),a2		;カーソル位置

		move.l	d6,d2

		move.l	d0,d4
		sub.l	d1,d4			;増加サイズ
		bhi	rep_str_long
*rep_str_short:
		adda.l	d3,a1			;削除先頭位置
		subq.l	#1,d0
@@:
		move.b	(a0)+,(a1)+		;文字列を挿入
		dbra	d0,@b			;ABC...GHI
		clr	d0			;ABCX..GHI
		subq.l	#1,d0			;ABCXGHI
		bcc	@b
		STRCPY	a2,a1			;右側の文字列を詰める

		add.l	d4,d5
		add.l	d4,d6			;カーソル位置補正
		bsr	adjust_cursor_l
		bra	rep_str_print
rep_str_long:
		clr.b	-(a2)			;カーソルの直前を 0 にする
		adda.l	d5,a1			;末尾
		lea	(a1,d4.l),a2		;置換後の末尾
		clr.b	(a2)
@@:
		move.b	-(a1),-(a2)		;右側の文字列をずらす
		bne	@b
		addq.l	#1,a2
		suba.l	d0,a2			;削除先頭位置
		subq.l	#1,d0
@@:
		move.b	(a0)+,(a2)+		;文字列を挿入
		dbra	d0,@b			;ABC.EFG
		clr	d0			;ABC...EFG
		subq.l	#1,d0			;ABCXYZEFG
		bcc	@b

		add.l	d4,d5
		add.l	d4,d6			;カーソル位置補正
		bsr	adjust_cursor_r
rep_str_print:
		beq	@f
		bsr	print_line
		bra	rep_str_sc
@@:
		sub.l	d1,d2			;書き換え開始位置
		bcc	@f
		moveq	#0,d2
@@:
		move.l	(_RL_WIDTH,a5),d4	;	 終了位置
		sub.l	d2,d4
		movea.l	(_RL_BUF,a5),a1
		adda.l	d7,a1
		adda.l	d2,a1
		bsr	b_putmes
rep_str_sc:
		bsr	set_cursor
rep_str_end:
		POP	d0-d4/a0-a2
		rts


* カーソル位置が単語構成文字か調べる ---------- *
* in	d0.b	文字コード
* out	d0.l	-1:単語構成文字ではない
*		 0:単語構成文字である(一バイト文字)
*		 1:	〃	     (二バイト文字)
*	ccr	<tst.l d0> の結果
* 仕様:
*	単語構成文字とは、以下のいずれか.
*	0～9、A～Z、a～z
*	二バイト文字
*	_RL_WORDS で指定した文字列に含まれる一バイト文字

is_wordchar:
		PUSH	d1/a0
		cmpi.b	#'0',d0
		bcs	@f
		cmpi.b	#'9',d0
		bls	is_wordchar_sb		;0-9
@@:
		moveq	#$20,d1
		or.b	d0,d1
		cmpi.b	#'a',d1
		bcs	@f
		cmpi.b	#'z',d1
		bls	is_wordchar_sb		;A-Za-z
@@:
		move.b	d0,d1
		beq	is_wordchar_false

		lsr.b	#5,d1
		btst	d1,#%10010000
		bne	is_wordchar_mb		;二バイト文字

		movea.l	(_RL_WORDS,a5),a0
		bra	@f
is_wordchar_loop:
		cmp.b	d0,d1
		beq	is_wordchar_sb
@@:		move.b	(a0)+,d1
		bne	is_wordchar_loop
is_wordchar_false:
		moveq	#-1,d0
		bra	is_wordchar_end
is_wordchar_mb:
		moveq	#1,d0
		bra	is_wordchar_end
is_wordchar_sb:
		moveq	#0,d0
is_wordchar_end:
		POP	d1/a0
		rts


* 補完 ---------------------------------------- *
* out	d0.l	補完終了時の入力キー
*	ccr	<tst.l d0> の結果

complete:
		pea	(-1)
		DOS	_MALLOC
		move.l	d0,(sp)
		clr.b	(sp)
		DOS	_MALLOC
		move.l	(sp)+,(~comp_size,a6)	;最低 16 バイト
		move.l	d0,(~comp_buf,a6)
		bmi	comp_end

		movea.l	(_RL_BUF,a5),a0
		CUR_PTR	a1
		move.l	a1,d4
		bra	@f
comp_word_loop:
		bsr	ismbtrail
		bcs	@f			;下位バイト
		cmpi.b	#$20,d0
		bls	comp_word_end
		cmpi.b	#'=',d0
		beq	comp_word_end
@@:
		move.b	-(a1),d0
		cmpa.l	a0,a1
		bcc	comp_word_loop
comp_word_end:
		addq.l	#1,a1
		movea.l	a1,a4			;補完対象文字列
		sub.l	a1,d4			;長さ

		move.l	(_RL_COMPLETE,a5),d0
		beq	comp_dir_file

		movea.l	d0,a0
		bsr	comp_call_job
		bpl	@f
comp_dir_file:
		bsr	comp_wild		;ワイルドカード展開
		bpl	comp_end

**		lea	(comp_dir_file_job,pc),a0
**		bsr	comp_call_job
		bsr	comp_dir_file_job
@@:
		move.l	d0,d3
		ble	comp_end
		subq.l	#1,d0
		beq	comp_single

		movea.l	(~comp_buf,a6),a0
		addq.l	#1,a0			;a0 = 先頭
		lea	(a0),a1
		STREND	a1			;a1 = 不一致位置
		lea	(a0),a2			;a2 = 注目侯補
		bra	comp_head_next
comp_head_loop:
		PUSH	a0/a2
@@:
		cmpm.b	(a0)+,(a2)+
		bne	@f
		tst.b	(-1,a0)
		bne	@b
@@:
		subq.l	#1,a0
		cmpa.l	a0,a1
		bls	@f
		movea.l	a0,a1
@@:
		POP	a0/a2
comp_head_next:
@@:		tst.b	(a2)+
		bne	@b
		addq.l	#1,a2
		subq.l	#1,d0
		bcc	comp_head_loop

		bsr	ismbtrail
		bcc	@f
		subq.l	#1,a1
@@:
		move.l	a1,d0
		sub.l	a0,d0			;先頭の一致文字のバイト数
		beq	@f
		cmp.l	d0,d4
		bhi	@f

		bsr	comp_rep_str		;先頭の一致部分を確定する
@@:
		bsr	comp_print_list

		movea.l	(~comp_buf,a6),a2

		moveq	#-1,d2			;現在表示中の侯補
		tst.b	(~con_disp,a6)
		beq	comp_tab_forward	;表示禁止なら先頭の侯補を補完する

		lea	(1,a2),a0
		lea	(a4),a1
		move.l	d4,d0
@@:
		cmpm.b	(a0)+,(a1)+
		bne	@f
		subq.l	#1,d0
		bne	@b
		tst.b	(a0)+
		bne	@f			;補完文字列が先頭の侯補と同じなら
		moveq	#0,d2			;入力済みとして扱う
@@:
		bra	comp_tab_next
comp_tab_loop:
		IOCS	_B_SFTSNS
		lsl.b	#7,d0
		bmi	comp_tab_reverse	;SHIFT あり
		bcc	comp_tab_forward	;CTRL なし
		moveq	#2,d1
		IOCS	_BITSNS
		lsr.b	#1,d0
		bcc	comp_tab_forward	;C-i
comp_tab_reverse:
		tst.l	d2
		bgt	@f
		move.l	d3,d2
@@:		subq.l	#1,d2
		bra	@f
comp_tab_forward:
		addq.l	#1,d2
		cmp.l	d3,d2
		bcs	@f
		moveq	#0,d2
@@:
		lea	(a2),a0
		move.l	d2,d0
		bra	1f
comp_tab_skip_loop:
		addq.l	#1,a0			;目的の侯補まで移動
@@:		tst.b	(a0)+
		bne	@b
1:		subq.l	#1,d0
		bcc	comp_tab_skip_loop

		addq.l	#1,a0
		STRLEN	a0,d0
		bsr	comp_rep_str
comp_tab_next:
		bsr	key_input
		cmpi	#TAB,d0
		beq	comp_tab_loop

		bsr	con_restore
		bra	comp_end2
comp_rep_str:
		move.l	d4,d1
		bsr	replace_string
		CUR_PTR	a1
		move.l	a1,d4
		sub.l	a4,d4
		rts
comp_single:
		movea.l	(~comp_buf,a6),a0	;選択肢が一つだけなら確定する
		lea	(a0),a1
		lea	(a0),a2
		move.b	(a1)+,d0		;種類
		STRCPY	a1,a2
		subq.l	#1,a2

		tst.b	(_RL_C_ADDS,a5)
		beq	@f
		move.b	(_RL_C_SLASH,a5),d1
		rol.b	#7-ATR_DIR,d0
		beq	@f			;外部補完
		bmi	1f			;ディレクトリ
		moveq	#SPACE,d1		;ファイル
1:		move.b	d1,(a2)+
@@:
		move.l	a2,d0
		sub.l	a0,d0
		move.l	d4,d1
		bsr	replace_string
comp_end:
		moveq	#0,d0
comp_end2:
		move.l	d0,-(sp)

		move.l	(~comp_buf,a6),-(sp)
		bmi	@f
		DOS	_MFREE
@@:		addq.l	#4,sp

		move.l	(sp)+,d0
		rts


* コンソールに侯補を表示する ------------------ *
* in	d3.l	侯補数(2～)

comp_print_list:
		PUSH	d0-d7/a0-a1
		bsr	con_save
		bsr	con_clear

		moveq	#0,d2			;表示桁位置
		move	(~con_num,a6),d7
		movea.l	(~comp_buf,a6),a0
comp_pl_loop_x:
		moveq	#0,d6			;この列の最長桁数
		move	d7,d5
		move.l	d3,d4
		movea.l	a0,a1
comp_pl_loop_y:
		bsr	comp_pl_sub
		tst.b	d1
		beq	@f
		addq.l	#1,d0
@@:
		cmp.l	d0,d6
		bcc	@f
		move.l	d0,d6
@@:
		tst.b	(a0)+			;次の侯補へ
		bne	@b
		subq.l	#1,d4
		beq	@f			;列の途中だが侯補が尽きた
		subq	#1,d5
		bne	comp_pl_loop_y
@@:
		moveq	#96,d0
		move.l	d2,d1
		add.l	d6,d1
		cmp.l	d0,d1
		bhi	comp_pl_end		;表示する幅が残っていない

		movea.l	a1,a0
		move	d7,d5
comp_pl_loop_y2:
		bsr	comp_pl_sub
		lea	(a0,d0.l),a1
		move.b	d1,(a1)			;付加記号を追加
		beq	@f
		addq.l	#1,d0			;表示桁数
@@:
		move	d7,d1
		sub	d5,d1			;行位置
		bsr	con_print
		clr.b	(a1)			;付加記号を削除
@@:
		tst.b	(a0)+			;次の侯補へ
		bne	@b
		subq.l	#1,d3
		beq	comp_pl_end		;列の途中だが侯補が尽きた
		subq	#1,d5
		bne	comp_pl_loop_y2

		add.l	d6,d2
		addq.l	#1,d2			;空白の分
		bra	comp_pl_loop_x
comp_pl_end:
		POP	d0-d7/a0-a1
		rts


* 侯補表示準備
* in	a0.l	侯補のアドレス
* out	d0.l	文字列長(付加記号の分を含まない)
*	d1.b	付加記号
*	a0.l	文字列のアドレス
comp_pl_sub:
		PUSH	d2/a1
		move.b	(a0)+,d2
		lea	(a0),a1
@@:		tst.b	(a1)+
		bne	@b
		subq.l	#1,a1
		move.l	a1,d0
		sub.l	a0,d0			;文字列長+1

		moveq	#'@',d1
		rol.b	#1,d2			;%ladv_shrx
		bmi	@f
		move.b	(_RL_C_SLASH,a5),d1
		rol.b	#2,d2			;%dvsh_rxla
		bmi	@f
		moveq	#'*',d1
		lsr.b	#3,d2			;%000d_vshr:x
		bcs	@f
		moveq	#$20,d2
		or.b	-(a1),d2
		cmpi.b	#'x',d2
		beq	1f
		cmpi.b	#'r',d2
		bne	comp_pl_sub_no_exec
1:		cmpi.b	#'.',-(a1)
		bne	comp_pl_sub_no_exec
		cmpa.l	a0,a1
		bhi	@f
comp_pl_sub_no_exec:
		moveq	#0,d1			;付加記号なし
@@:
		POP	d2/a1
		rts


* リスト展開処理呼び出し ---------------------- *
* in	a0.l	処理関数のアドレス
*	a4.l	補完対象文字列のアドレス
*	d4.l		〃	長さ
* out	a4.l	本体のアドレス
*	d4.l	  〃  長さ
*	d0.l	項目数(負数ならエラー)
*	ccr	<tst.l d0> の結果
* break	d1-d2/a0-a2

comp_call_job:
		move.l	d4,-(sp)
		move.l	a4,-(sp)
		move.l	(~comp_size,a6),-(sp)
		move.l	(~comp_buf,a6),-(sp)
		pea	(12,sp)
		pea	(12,sp)
		move.l	(_RL_BUF,a5),-(sp)
		jsr	(a0)
		lea	(4*5,sp),sp
		movea.l	(sp)+,a4
		move.l	(sp)+,d4
		tst.l	d0
		rts


* ディレクトリ/ファイルリスト収得 ------------- *
* in	a4.l	補完対象文字列のアドレス
*	d4.l		〃	長さ
* out	a4.l	ファイル名のアドレス
*	d4.l		〃  長さ
*	d0.l	項目数(負数ならエラー)
*	ccr	<tst.l d0> の結果

comp_dir_file_job:
		PUSH	d1-d3/d7/a0-a3
		moveq	#0,d3
		bsr	comp_wild_getbuf
		bcs	comp_dfj_end		;バッファ容量不足

		bsr	comp_get_lastsep
		lea	(a4),a0
		adda.l	d0,a4			;ファイル名先頭
		sub.l	d0,d4			;	   長さ

		move.b	(a4),d1
		clr.b	(a4)
		move.l	a1,-(sp)		;バッファ
		move.l	a0,-(sp)		;ファイル名
		DOS	_NAMECK
		addq.l	#8,sp
		move.b	d1,(a4)
		tst.l	d0
		bmi	comp_dfj_end
		bsr	comp_wild_dskchk
		bne	comp_dfj_end

		lea	(3,a1),a3		;ディレクトリ名
		tst.b	(a3)
		seq	d7			;ルートディレクトリ

		STREND	a3
		moveq	#-(18-2),d1
		move.l	d4,d2
		beq	comp_dfj_cat_wild

		lea	(a4),a0
		move.b	(a0)+,d0		;先頭の '.' は通常の文字と見なす
		bra	@f
comp_dfj_fn_loop:
		move.b	(a0)+,d0
		cmpi.b	#'.',d0
		beq	comp_dfj_cat_wild
@@:
		addq	#1,d1
		bpl	comp_dfj_cat_wild	;16～17 バイト制限
		move.b	d0,(a3)+
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	comp_dfj_fn_next
		addq	#1,d1
		move.b	(a0)+,(a3)+
		subq.l	#1,d2
comp_dfj_fn_next:
		subq.l	#1,d2
		bhi	comp_dfj_fn_loop
comp_dfj_cat_wild:
		lea	(comp_dfj_wild,pc),a0
		STRCPY	a0,a3

		lea	(comp_dfj_fncmp,pc),a3
		clr	-(sp)			;_TWON_GETID
		DOS	_TWON
		cmpi.l	#_TWON_ID,d0
		bne	@f
		addq	#_TWON_GETOPT,(sp)
		DOS	_TWON
		add.l	d0,d0
		bpl	@f			;TwentyOne -C
		lea	(comp_dfj_fncmp_c,pc),a3
@@:		addq.l	#2,sp

		moveq	#-(1+22+1),d2
		add.l	a2,d2			;上限

		moveq	#0,d0
		move.b	(_RL_C_ATR,a5),d0
		move	d0,-(sp)
		move.l	a1,-(sp)		;ファイル名
		move.l	a2,-(sp)		;バッファ
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	comp_dfj_stop
comp_dfj_loop:
		cmpa.l	d2,a1
		bhi	comp_dfj_stop

		lea	(30,a2),a0		;ファイル名
		jsr	(a3)
		bne	comp_dfj_next

		cmpi	#'.'<<8,(a0)		;"." と ".." は無視する
		beq	comp_dfj_next
		cmpi	#'..',(a0)
		bne	@f
		tst.b	(2,a0)
		beq	comp_dfj_next
@@:
		move.b	(21,a2),d0		;属性
		bne	@f
		moveq	#1<<ATR_ARC,d0
@@:		move.b	d0,(a1)+

		STRCPY	a0,a1			;ファイル名をコピー
		addq.l	#1,d3
comp_dfj_next:
		move.l	a2,-(sp)
		DOS	_NFILES
		move.l	d0,(sp)+
		bpl	comp_dfj_loop
comp_dfj_stop:
		tst.l	d3
		bne	@f
		tst.b	d7
		bne	@f
		moveq	#2,d0
		cmp.l	d0,d4
		bne	@f
		moveq	#'.',d0
		cmp.b	(a4),d0
		bne	@f
		cmp.b	(1,a4),d0
		bne	@f

		st	(a1)+			;サブディレクトリで ".." なら
		move.b	d0,(a1)+		;"../" を補完する
		move.b	d0,(a1)+
		clr.b	(a1)
		moveq	#1,d3
		bra	comp_dfj_end
@@:
comp_dfj_end:
		move.l	d3,d0
		POP	d1-d3/d7/a0-a3
		rts


* ファイル名比較
* in	a0.l	見つかったファイル名
*	a4.l	比較するファイル名
*	d4.l	〃		  の長さ
* out	ccr	Z=1:一致 Z=0:不一致
* break	d0

* 大文字小文字区別あり
comp_dfj_fncmp_c:
		PUSH	a0/a4
		move.l	d4,d0
		beq	comp_dfj_fncmp_c_end
comp_dfj_fncmp_c_loop:
		cmpm.b	(a4)+,(a0)+
		bne	comp_dfj_fncmp_c_end
		subq.l	#1,d0
		bne	comp_dfj_fncmp_c_loop
comp_dfj_fncmp_c_end:
		POP	a0/a4
		rts

* 大文字小文字区別なし
comp_dfj_fncmp:
		PUSH	d1-d2/a0/a4
		move.l	d4,d0
		beq	comp_dfj_fncmp_end
comp_dfj_fncmp_loop:
		move.b	(a4)+,d1
		move.b	(a0)+,d2
		cmp.b	d1,d2
		beq	comp_dfj_fncmp_next
		cmpi.b	#'A',d1
		bcs	comp_dfj_fncmp_end
		cmpi.b	#'z',d1
		bhi	comp_dfj_fncmp_end
		cmpi.b	#'a',d1
		bcc	@f
		cmpi.b	#'Z',d1
		bhi	comp_dfj_fncmp_end
@@:
		eori.b	#$20,d1
		cmp.b	d1,d2
		bra	@f
comp_dfj_fncmp_next:
		subq.l	#1,d0
		beq	comp_dfj_fncmp_end
		lsr.b	#5,d1
		btst	d1,#%10010000
		beq	comp_dfj_fncmp_loop
		cmpm.b	(a4)+,(a0)+
@@:		bne	comp_dfj_fncmp_end
		subq.l	#1,d0
		bne	comp_dfj_fncmp_loop
comp_dfj_fncmp_end:
		POP	d1-d2/a0/a4
		rts


comp_dfj_wild:	.dc.b	'*.*',0
		.even


* ワイルドカード展開 -------------------------- *
* in	a4.l	補完対象文字列のアドレス
*	d4.l		〃	長さ
* out	d0.l	0:正常終了 -1:エラー
*	ccr	<tst.l d0> の結果

comp_wild:
		PUSH	d1-d3/a0-a3
		bsr	comp_wild_getbuf
		bcs	comp_wild_error		;バッファ容量不足

		lea	(a4,d4.l),a3
		move.b	(a3),d1
		clr.b	(a3)
		move.l	a1,-(sp)		;バッファ
		move.l	a4,-(sp)		;ファイル名
		DOS	_NAMECK
		addq.l	#8,sp
		move.b	d1,(a3)
		tst.l	d0
		bmi	comp_wild_error
		tst.b	d0
		ble	comp_wild_no_wild	;ワイルドカード指定なし
		bsr	comp_wild_dskchk
		bne	comp_wild_error

		lea	(0,a1),a3		;パス名
		STREND	a3
		lea	(67,a1),a0		;ファイル名
		STRCPY	a0,a3
		subq.l	#1,a3
		lea	(86,a1),a0		;拡張子
		STRCPY	a0,a3

		move	#$ff-(1<<ATR_DIR)-(1<<ATR_VOL),d0
		and.b	(_RL_C_ATR,a5),d0	;ファイルのみ検索
		move	d0,-(sp)
		move.l	a1,-(sp)		;ファイル名
		move.l	a2,-(sp)		;バッファ
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	comp_wild_error

		moveq	#-1,d1
comp_wild_loop:
		moveq	#(1<<ATR_DIR).or.(1<<ATR_VOL),d0
		and.b	(21,a2),d0		;属性
		bne	comp_wild_next

		move.l	d1,d0
		bpl	comp_wild_2nd
*comp_wild_1st:
		bsr	comp_get_lastsep
		move.l	d0,d1			;パス名の長さ

		lea	(-(22+1+1),a2),a3
		suba.l	d1,a3			;上限
		bra	comp_wild_copy
comp_wild_2nd:
		cmpa.l	a3,a1
		bhi	comp_wild_stop

		lea	(a4),a0
		bra	1f
@@:
		move.b	(a0)+,(a1)+		;パス名をコピー
1:		subq.l	#1,d0
		bcc	@b
comp_wild_copy:
		lea	(30,a2),a0		;ファイル名をコピー
		STRCPY	a0,a1
		move.b	#SPACE,(-1,a1)
comp_wild_next:
		move.l	a2,-(sp)
		DOS	_NFILES
		move.l	d0,(sp)+
		bpl	comp_wild_loop
comp_wild_stop:
		move.l	d1,d0
		bmi	comp_wild_error		;ファイルなし

		clr.b	-(a1)			;最後の空白を削除

		move.l	d4,d1
		sub.l	d0,d1			;ワイルドカードのバイト数
		movea.l	(~comp_buf,a6),a0
		move.l	a1,d0
		sub.l	a0,d0
		bsr	replace_string

		moveq	#0,d0
@@:		POP	d1-d3/a0-a3
		rts
comp_wild_error:
comp_wild_no_wild:
		moveq	#-1,d0
		bra.s	@b


* ワイルドカード展開用のバッファアドレスを得る
* out	a1.l	DOS _NAMECK 及びファイル名書き込みバッファ
*	a2.l	DOS _FILES バッファ
*	ccr	C=0:正常終了 C=1:エラー
* break	d0
comp_wild_getbuf:
		moveq	#$fe,d0
		and.l	(~comp_size,a6),d0
		cmpi.l	#(91+1)+(53+1),d0
		bcs	@f
		movea.l	(~comp_buf,a6),a1
		lea	(-(53+1),a1,d0.l),a2
@@:		rts


* ディスク検査
* in	a1.l	パス名
* out	ccr	Z=1:アクセス可能 Z=0:アクセス不可能
* break	d0
comp_wild_dskchk:
		moveq	#$1f,d0
		and.b	(0,a1),d0
		move	d0,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		andi	#%111,d0
		subq	#%010,d0
		rts


* パス名の長さを得る
* in	a4.l	補完対象文字列のアドレス
*	d4.l		〃	長さ
* out	d0.l	パス名の長さ

comp_get_lastsep:
		PUSH	d1/d4/a4
comp_get_ls_found:
		move.l	a4,d0
comp_get_ls_loop:
		subq.l	#1,d4
		bcs	comp_get_ls_end
		move.b	(a4)+,d1
		cmpi.b	#'/',d1
		beq	comp_get_ls_found
		cmpi.b	#'\',d1
		beq	comp_get_ls_found
		cmpi.b	#':',d1
		beq	comp_get_ls_found
		lsr.b	#5,d1
		btst	d1,#%10010000
		beq	comp_get_ls_loop
		addq.l	#1,a4
		subq.l	#1,d4
		bcc	comp_get_ls_loop
comp_get_ls_end:
		POP	d1/d4/a4
		sub.l	a4,d0
		rts


* コンソール制御 ------------------------------ *

* 初期化
con_init:
		PUSH	d0-d2
		clr.b	(~con_save,a6)
		move.b	(_RL_C_DISP,a5),(~con_disp,a6)
		beq	con_init_end

		move	(~consol_buf+2,a6),d0
		lsr	#4,d0			;先頭位置
		move	(~consol_buf+6,a6),d1
		add	d0,d1			;終了位置

		move	(_RL_WIN_Y,a5),d2
		addq	#2,d2
		cmp	d2,d0
		bcc	@f
		move	d2,d0			;先頭位置を _RL_WIN_Y+2 以降にする
@@:
		sub	d0,d1
		scc	(~con_disp,a6)
		addq	#1,d1			;行数
		movem	d0/d1,(~con_top,a6)
con_init_end:
		POP	d0-d2
		rts

* 終了
con_end:
		PUSH	d0-d3
		tst.b	(~con_save,a6)
		beq	con_end_end

		bsr	con_restore
		bsr	con_get_ras
		bsr	con_clear_sub		;裏画面を消去
con_end_end:
		POP	d0-d3
		rts

* 保存
con_save:
		PUSH	d0-d3
		tst.b	(~con_disp,a6)
		beq	con_save_end
		tst.b	(~con_save,a6)
		bne	con_save_end

		st	(~con_save,a6)
		bsr	con_get_ras
		moveq	#0<<8+%0011,d3
		IOCS	_TXRASCPY
con_save_end:
		POP	d0-d3
		rts

* ラスタ番号収得
con_get_ras:
		move	(~con_num,a6),d2
		lsl	#2,d2			;ラスタ数
		move	(~con_top,a6),d1
		lsl	#2,d1			;コピー元ラスタ番号
		lsl	#8,d1
		sub.b	d2,d1			;コピー先〃
		rts

* 復帰
con_restore:
		PUSH	d0-d3
		tst.b	(~con_save,a6)
		beq	con_restore_end

		clr.b	(~con_save,a6)
		bsr	con_get_ras
		ror	#8,d1
		move	#0<<8+%0011,d3
		IOCS	_TXRASCPY
con_restore_end:
		POP	d0-d3
		rts

* 消去
con_clear:
		PUSH	d0-d3
		tst.b	(~con_disp,a6)
		beq	con_clear_end

		bsr	con_get_ras
		lsr	#8,d1
		bsr	con_clear_sub		;表示画面を消去
con_clear_end:
		POP	d0-d3
		rts

* 消去下請け
con_clear_sub:
		PUSH	d0-d3/a0-a1
		moveq	#0,d0
		move.b	d1,d0			;ラスタ番号
		add	d0,d0
		lsl.l	#8,d0
		lea	($e00000),a0
		adda.l	d0,a0
		lea	($e8002a),a1
		pea	(con_clear_blk,pc)	;最初のラスタブロックを消去
		DOS	_SUPER_JSR
		addq.l	#4,sp

		move	d1,-(sp)
		move.b	d1,(sp)			;コピー元ラスタ番号
		move	(sp)+,d1
		addq.b	#1,d1			;コピー先〃
		subq	#1,d2
		moveq	#0<<8+%0011,d3
		IOCS	_TXRASCPY

		POP	d0-d3/a0-a1
		rts

con_clear_blk:
		move	(a1),-(sp)
		move	#%01_0011_0000,(a1)
		moveq	#128*4/(4*2)-1,d3
		moveq	#0,d0
@@:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d3,@b
		move	(sp)+,(a1)
		rts

* 表示
* in	d0.w	表示する桁数
*	d1.l	行位置
*	d2.l	桁位置
*	a0.l	文字列
con_print:
		PUSH	d0-d4/a1
		tst.b	(~con_disp,a6)
		beq	con_print_end

		move	d0,d4
		subq	#1,d4
		bcs	con_print_end

		move.l	d1,d3
		add	(~con_top,a6),d3
		move.b	(_RL_C_COL,a5),d1
		lea	(a0),a1
		IOCS	_B_PUTMES
con_print_end:
		POP	d0-d4/a1
		rts


* Data Section -------------------------------- *

**		.data
		.even

fnckey_list:
		.dc.b	$0e,0			;C-n (ROLL UP)
		.dc.b	$10,0			;C-p (ROLL DOWN)
		.dc.b	$00,0			;--- (INS)
		.dc.b	$04,0			;C-d (DEL)
		.dc.b	$10,0			;C-p (↑)
		.dc.b	$02,0			;C-b (←)
		.dc.b	$06,0			;C-f (→)
		.dc.b	$0e,0			;C-n (↓)
		.dc.b	$0c,0			;C-l (CLR)
		.dc.b	$00,0			;--- (HELP)
		.dc.b	$01,0			;C-a (HOME)
		.dc.b	$19,0			;C-y (UNDO)
		.even


* Block Storage Section ----------------------- *

**		.bss
**		.even


		.end

* End of File --------------------------------- *
