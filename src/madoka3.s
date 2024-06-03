# madoka3.s - madoka interpreter
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

		.include	mrl.mac
		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	func.mac
		.include	sysval.def

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* cmdhis.s
		.xref	command_history
		.xref	command_history_menu
		.xref	add_cmd_his
		.xref	is_exist_cmd_his
* cpmv.s
		.xref	get_filesize
* fileop.s
		.xref	to_mintslash
		.xref	get_drive_status
		.xref	copy_dir_name_a1_a2
* funcname.s
		.xref	search_builtin_func
* gvon.s
		.xref	graph_home,GVON24_flag,GTONE,sq64k
		.xref	check_gusemd,gm_check_square
		.xref	g_half_16_usr,gvon_16_usr
		.xref	g_half_256_usr,gvon_256_usr
		.xref	g_half_64k_usr,gvon_64k_usr
* look.s
		.xref	LOOK_FILE_NAME,look_mode
* mint.s
		.xref	SaveFnckey,RestoreFnckey,ChangeFnckey
		.xref	search_cursor_file,search_mark_file
		.xref	to_fullpath_file
		.xref	print_screen,print_file_list
		.xref	get_fnckey_mode,orig_fnckey_mode
		.xref	restore_fnckey_mode,reset_fnckey_mode
		.xref	fnckey_disp_on2,fnckey_disp_off
		.xref	set_curfile2,set_status
		.xref	set_scr_param,set_scroll_narrow_console
		.xref	fep_disable,fep_enable
		.xref	breakck_save_kill,breakck_restore
		.xref	hook_keyinp_ex_vector,restore_keyinp_ex_vector
		.xref	set_crt_mode_768x512
		.xref	hextable
		.xref	dos_drvctrl_d1,reset_current_dir
		.xref	skip_connect_line
		.xref	GetArgChar,GetArgCharInit
		.xref	mintrc_filename
		.xref	oldpwd_buf,MpuType,MINTSLASH
		.xref	kq_buffer,macro_table
		.xref	disable_clock_flag,malloc_mode,stack_top
		.xref	時間_実行前,時間_実行後
* mintarc.s
		.xref	get_mintarc_dir
		.xref	get_mintarc_filename
		.xref	ma_list_adr,ma_list_num
		.xref	mintarc_extract
* outside.s
		.xref	atoi_a0
		.xref	dos_inpout
		.xref	break_check1,break_check
		.xref	strcmp_a1_a2,stricmp_a1_a2
		.xref	search_system_value,search_user_value_a1
		.xref	set_user_value_a1_a2,unset_user_value_a1
		.xref	set_user_value_match_a2
		.xref	getsec_flag


* Constant ------------------------------------ *

HUPAIR_ID_SIZE:	.equ	.sizeof.('#HUPAIR')+1

RL_MAX:		.equ	$ffff
MARGIN:		.equ	16

* マクロ展開後に使う特殊コード
PREFIX:		.equ	CR
TERM:		.equ	LF

* トークン分割後に使う特殊コード
TC_FILE:	.equ	$08
TC_ESC:		.equ	$09

* 内蔵固定バッファの大きさ
UNFOLD_BUF_SIZE:  .equ 256
CMDLINE_BUF_SIZE: .equ 256


* Offset Table -------------------------------- *

		.offset	0
Q_old_q_ptr:	.ds.l	1			;親の q_ptr
Q_funcname:**	.ds.l	1			;実行中の関数名
Q_sp_save:	.ds.l	1			;アボート時の sp
Q_rl_ptr:	.ds.l	1			;行編集のカーソル位置

Q_next_ptr:	.ds.l	1			;次回実行 madoka
Q_macro:	.ds.l	1			;マクロ情報
Q_buf_top:	.ds.l	1			;madoka バッファ
Q_buf_size:	.ds.l	1			;バッファサイズ

Q_miss_line:	.ds.l	1			;キー条件一致がない時に実行する行
Q_ext_exec:	.ds.l	1			;&ext-exec ファイル名
		.even
Q_ma_req_cur:	.ds.b	1			;┐mintarc 展開要求
Q_ma_req_opp:	.ds.b	1			;┘

Q_mintarc:	.ds.b	1			;>LZHS_?、>TARS_?、>ZIPS_? の実行
Q_redraw:**	.ds.b	1			;再描画要求
Q_from_help:	.ds.b	1			;&ext-help/&describe-key からの実行
Q_expand_only:	.ds.b	1			;expand_token からの実行
Q_getsec:	.ds.b	1			;&getsec 実行フラグ
Q_old_debug:	.ds.b	1			;&debug フラグ保存

Q_abort:	.ds.b	1			;強制終了
Q_skip:		.ds.b	1			;ブロック通過
Q_if_next:	.ds.b	1			;条件分岐命令フラグ
Q_if_flag:	.ds.b	1			;〃

Q_exec_j:	.ds.b	1			;&exec-j-special-entry からの実行
Q_key_prefix:	.ds.b	1			;&prefix 8 | ... | 1
Q_key_shift:	.ds.b	1			;OPT.2 | OPT.1 | CTRL | SHIFT
Q_key_xfn:	.ds.b	1			;XF5 | ... | XF1

Q_sw_start:
Q_sw_j:		.ds.b	1			;-j
Q_sw_prefix:	.ds.b	1			;-&8 | ... | -&1
Q_sw_shift:	.ds.b	1			;-o2 | -o1 | -c | -t
Q_sw_xfn:	.ds.b	1			;-x5 | ... | -x1
Q_sw_m:		.ds.b	1			;-m

Q_sw_a:		.ds.b	1			;-a
Q_sw_f:		.ds.b	1			;-f
Q_sw_i:		.ds.b	1			;-i
Q_sw_l:		.ds.b	1			;-l
Q_sw_n:		.ds.b	1			;-n
Q_sw_p:		.ds.b	1			;-p
Q_sw_q:		.ds.b	1			;-q
Q_sw_s:		.ds.b	1			;-s
Q_sw_v:		.ds.b	1			;-v
Q_sw_atmark:	.ds.b	1			;-@
Q_sw_h_k:	.ds.b	1			;-h / -k
Q_sw_d:		.ds.b	1			;$ff = -d / '1' = -d1 / '2' = -d2
Q_sw_g:		.ds.b	1			;-g? ($00 / '0'...'9')
Q_sw_end:
		.quad
sizeof_Quick:


MA_REQ_REDRAW:	.equ	3			;ウィンドウ再描画要求
MA_REQ_MARK:	.equ	2			;$M 展開要求
MA_REQ_FILE:	.equ	1			;$F 〃
MA_REQ_PATH:	.equ	0			;$C 〃


* Macro --------------------------------------- *

PR_EA:		.macro	ea
		move.l	d0,-(sp)
		pea	ea
		DOS	_PRINT
		addq.l	#4,sp
		move.l	(sp)+,d0
		.endm

PR_STR:		.macro	str
		PR_EA	(@str,pc)
		bra	@end
@str:		.dc.b	str,0
		.even
@end:
		.endm


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


*************************************************
*		&madoka				*
*************************************************

＆madoka::
		tst.l	d7
		beq	madoka_error

		lea	(Buffer),a1		;$argv0 用にフルパス化
		lea	(a1),a2
		STRCPY	a0,a1
		move.l	a2,-(sp)
		jsr	(to_fullpath_file)
		move.l	d0,(sp)+
		bmi	madoka_error

		clr	-(sp)			;ROPEN
		move.l	a2,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d6
		bmi	madoka_error

		jsr	(get_filesize)
		move.l	d0,d1
		bmi	madoka_error_close

		addq.l	#4,d0
		bsr	malloc_from_same_side
		move.l	d0,d5			;buffer
		bmi	madoka_error_close

		movea.l	d0,a1
		move.l	d1,-(sp)
		move.l	a1,-(sp)
		move	d6,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		bne	madoka_error_mfree
		clr.b	(a1,d0.l)

		cmpi	#'#!',(a1)+
		bne	madoka_error_mfree
madoka_skip_line:
		move.b	(a1)+,d0		;先頭行("#!madoka ...")を飛ばす
		beq	madoka_error_mfree
		cmpi.b	#LF,d0
		bne	madoka_skip_line
@@:
		move.b	(a1)+,d0		;コメント行を飛ばす
		beq	madoka_error_mfree
		cmpi.b	#TAB,d0
		beq	@b
		cmpi.b	#SPACE,d0
		beq	@b
		cmpi.b	#'#',d0
		beq	madoka_skip_line
		pea	(-1,a1)

		move	d6,-(sp)		;もうエラーはない
		DOS	_CLOSE
		addq.l	#2,sp

		lea	(str_argv0,pc),a1	;$argv0 = ファイル名
		lea	(Buffer),a2
		jsr	(set_user_value_a1_a2)

		lea	(str_argv,pc),a1
		jsr	(unset_user_value_a1)
		subq.l	#1,d7
		beq	madoka_no_arg

		lea	(a0),a2			;$argv = 引数列
		bra	@f
madoka_arg_loop:
		move.b	#SPACE,(-1,a0)
@@:		tst.b	(a0)+
		bne	@b
		subq.l	#1,d7
		bne	madoka_arg_loop

**		lea	(str_argv,pc),a1
		jsr	(set_user_value_a1_a2)
madoka_no_arg:
		moveq	#%0010_0000,d0
		movea.l	d5,a0
		movea.l	(sp)+,a1
		bsr	free_token_buf
		bsr	execute_quick

		lea	(str_argv0,pc),a1
		jsr	(unset_user_value_a1)
		lea	(str_argv,pc),a1
		jmp	(unset_user_value_a1)
**		rts

madoka_error_mfree:
		move.l	d5,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
madoka_error_close:
		move	d6,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
madoka_error:
		rts


*	.dc.b	'#!madoka...'
*	.dc.b	' -api command...'
*	.dc.b	0


* メモリブロック確保 -------------------------- *

* mint.x本体と同じモードでメモリブロックを確保する
* in  d0.l  確保するバイト数
* out d0.l  メモリブロックのアドレス(負数ならエラー)

malloc_from_same_side:
  move.l d0,-(sp)
  move (malloc_mode),-(sp)
  DOS _MALLOC2
  addq.l #6,sp
  rts


* 最大サイズでメモリブロックを確保する
* out d0.l  確保したバイト数(負数ならエラー)
*     a0.l  メモリブロックのアドレス

malloc_all:
  move.l #$00ffffff,-(sp)
  DOS _MALLOC
  and.l d0,(sp)
  DOS _MALLOC
  movea.l (sp)+,a0
  tst.l d0
  bmi @f
    exg d0,a0  ;d0=サイズ, a0=アドレス
  @@:
  rts


* quick 実行(番号指定) ------------------------ *
* in	d0.hb	quick 番号(KQ_xxx)
*	d0.b	フラグ

execute_quick_no::
		PUSH	d1/a1
		move	d0,d1
		lsr	#8,d1			;quick 番号
		lsl	#2,d1
		lea	(kq_buffer),a1
		move.l	(a1,d1.w),d1
		beq	@f			;未定義

		movea.l	d1,a1
		bsr	execute_quick
@@:
		POP	d1/a1
		rts


* トークン抽出 -------------------------------- *
* マクロ及び変数を展開して Buffer に書き込む.
* out	d0.l	Buffer

expand_buf:	.equ	expand_token+2

expand_token::
		clr.l	(Buffer)
		moveq	#%0100_0000,d0
		bsr	execute_quick
		move.l	(expand_buf,pc),d0
		rts


* quick 実行 ---------------------------------- *
* in	d0.l	フラグ
*		bit 6=1: expand_token からの実行
*		bit 5=1: マクロ展開後にバッファ解放
*		bit 4=1: &ext-exec からの実行
*		bit 3=1: &exec-j-special-entry からの実行
*		bit 2=1: &command-history(-menu)からの実行
*		bit 1=1: &ext-help/&describe-key からの実行
*		bit 0=1: >LZHS_?、>TARS_?、>ZIPS_? の実行
*	a1.l	quick 定義のアドレス(-api command...)
*	a0.l	bit 5=1 の場合: マクロ展開後に解放するバッファ
*		bit 4=1 の場合: ファイル名

execute_quick::
		PUSH	d0-d7/a0-a5
		cmpa.l	#stack_top,sp
		bls	exe_q_abort

		moveq	#sizeof_Quick/4-1,d2
		moveq	#0,d7
@@:		move.l	d7,-(sp)
		dbra	d2,@b
		lea	(sp),a5

		lea	(q_ptr,pc),a2
		move.l	(a2),(Q_old_q_ptr,a5)
		move.l	a5,(a2)

		move.l	a1,(Q_miss_line,a5)
		lsr.b	#1,d0
		bcc	1f
		st	(Q_mintarc,a5)
		lea	(debug_flag,pc),a2
		move.b	(a2),(Q_old_debug,a5)
		clr.b	(a2)
		bra	@f			;mintarc quick は >NO_MAP に行かない
1:
		move.l	(kq_buffer+KQ_NO_MAP*4),d1
		beq	@f
		move.l	d1,(Q_miss_line,a5)
@@:
		lsr.b	#1,d0
		scs	(Q_from_help,a5)
		lsr.b	#1,d0
		bcc	@f

		addq.b	#1,(Q_from_help,a5)	;&command-history(-menu)からの実行
		STRLEN	a1,d1,+1
		move.l	d1,(Q_buf_size,a5)
		bsr	lift_memory_block	;高位メモリに移動
		move.l	a1,d7			;『-n 対策』対策
@@:
		lsr.b	#1,d0
		scs	(Q_exec_j,a5)

		lsr.b	#1,d0
		bcc	@f
		move.l	a0,(Q_ext_exec,a5)
@@:
		lsr.b	#1,d0
		bcc	@f
		move.l	a0,d7
@@:
		lsr.b	#1,d0
		bcs	exe_q_expand

		move.l	d7,(Q_buf_top,a5)	;-n 対策
		tst.b	(Q_from_help,a5)
		bne	exe_q_from_help

		jsr	(skip_connect_line)
		move.l	a1,d0
		beq	exe_q_done

* 現在のキー条件を収得
		lea	(prefix_flag),a0
		move.b	(a0),(Q_key_prefix,a5)
		clr.b	(a0)

		moveq	#$e,d1
		IOCS	_BITSNS
		move.b	d0,(Q_key_shift,a5)

		moveq	#$b,d1
		IOCS	_BITSNS
		moveq	#%11,d2
		and.b	d0,d2
		lsl.b	#3,d2			;...54...
		moveq	#$a,d1
		IOCS	_BITSNS
		lsr.b	#5,d0			;.....321
		or.b	d2,d0
		move.b	d0,(Q_key_xfn,a5)
exe_q_loop:
		lea	(a1),a2
		bsr	clear_cmd_sw
		bsr	analyze_cmd_sw

* キー条件とスイッチを比較する
		move.b	(Q_exec_j,a5),d0
		cmp.b	(Q_sw_j,a5),d0
		bne	exe_q_missmatch
		move.b	(Q_key_prefix,a5),d0
		cmp.b	(Q_sw_prefix,a5),d0
		bne	exe_q_missmatch
		move.b	(Q_key_shift,a5),d0
		cmp.b	(Q_sw_shift,a5),d0
		bne	exe_q_missmatch
		move.b	(Q_key_xfn,a5),d0
		cmp.b	(Q_sw_xfn,a5),d0
		bne	exe_q_missmatch

		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		beq	@f
		tst.b	(Q_sw_m,a5)
		beq	exe_q_match		;マーク無し --
		bra	exe_q_missmatch		;マーク無し -m
@@:		tst.b	(Q_sw_m,a5)
		bne	exe_q_match		;マーク有り -m
						;マーク有り --
* 現在の状況
*	キー条件が一致
*	マーク有り、-m なし
* 以下の条件のとき、この行を実行する
*	他に完全に一致する行(-m のみ)がない
.if 0
* 以下の条件は不要
*	現在行で -&n -on -c -t -xn が指定されてない
		move.b	(Q_sw_prefix,a5),d0
		or.b	(Q_sw_shift,a5),d0
		or.b	(Q_sw_xfn,a5),d0
		bne	exe_q_missmatch
.endif
		move.l	a2,(Q_miss_line,a5)
exe_q_missmatch:
		bsr	skip_madoka
		bne	exe_q_loop		;次の行を試す

		movea.l	(Q_miss_line,a5),a1
exe_q_from_help:
		bsr	clear_cmd_sw
		bsr	analyze_cmd_sw
exe_q_match:
		tst.b	(Q_sw_n,a5)
		bne	exe_q_done		;-n 指定時は何もしないで終了する

		tst.b	(Q_from_help,a5)
		bgt	exe_q_main_loop		;&command-history(-menu)からの実行

		bsr	unfold_macro		;マクロ展開
		bmi	exe_q_done

  move.l d7,-(sp)
  ble @f
    DOS _MFREE  ;スクリプトファイルを読み込んだバッファを解放する
  @@:
  addq.l #4,sp

		move.b	(debug_flag,pc),d0
		beq	@f
		bsr	print_unfold_madoka
@@:
		movea.l	(Q_buf_top,a5),a1
exe_q_main_loop:
		bsr	execute_madoka
exe_q_main_loop2:
		tst.b	(Q_abort,a5)
		bne	exe_q_done
		move.l	a1,d0
		beq	exe_q_done
exe_q_main_loop3:
		bsr	fetch_char
		beq	exe_q_done
		cmpi.b	#'{',d0
		beq	exe_q_brace1
		cmpi.b	#'}',d0
		beq	exe_q_brace2
		cmpi.b	#';',d0
		bne	exe_q_main_loop

		clr.b	(Q_if_flag,a5)		;&if 成立フラグを初期化
		bsr	get_char		;';' を飛ばす
		bra	exe_q_main_loop3

* { : ブロック開始
exe_q_brace1:
		bsr	execute_block
		bra	exe_q_main_loop2

* } : ブロック終了
exe_q_brace2:
		moveq	#MES_MERR0,d0
		jsr	(PrintMsgCrlf)
		bra	exe_q_done

exe_q_expand:
		st	(Q_expand_only,a5)
		bsr	unfold_macro		;マクロ展開
		bmi	exe_q_done

		movea.l	(Q_buf_top,a5),a1
		bsr	execute_madoka
		bra	exe_q_done

* 実行終了
exe_q_done:
  move.l (Q_buf_top,a5),d0
  bsr free_unfold_buffer

		lea	(q_ptr,pc),a0
		move.l	(Q_old_q_ptr,a5),(a0)

		tst.b	(Q_mintarc,a5)
		beq	@f
		move.b	(Q_old_debug,a5),(debug_flag-q_ptr,a0)
@@:
		lea	(sizeof_Quick,sp),sp
exe_q_end:
		POP	d0-d7/a0-a5
		rts
exe_q_abort:
		moveq	#MES_STACK,d0
		jsr	(PrintMsgCrlf)
		bra	exe_q_end


* メモリブロックを高位アドレスに移動する ------ *
* in	d1.l	メモリブロックのサイズ
*	a1.l	メモリブロックのアドレス
* out	a1.l	移動先のアドレス
* 備考:
*	malloc_mode=2のときのみ移動する。
*	メモリが確保できなかった場合はそのままにする。

lift_memory_block:
  PUSH d0/d7/a0
  moveq #2,d0
  cmp (malloc_mode),d0
  bne lift_memblk_end
    move.l d1,-(sp)
    move d0,-(sp)
    DOS _MALLOC2
    addq.l #6,sp
    move.l d0,d7
    bmi lift_memblk_end
      pea (a1)  ;転送後に解放するメモリブロック

      movea.l d7,a0  ;転送先
      move.l d1,d0   ;サイズ
      bsr memory_copy

      DOS _MFREE  ;元のメモリブロックを解放する
      addq.l  #4,sp

      movea.l d7,a1
lift_memblk_end:
  POP d0/d7/a0
  rts


* メモリ内容を複写する ------------------------ *
* in  d0.l  バイト数
*     a0.l  バッファアドレス(偶数アドレスであること)
*     a1.l  データアドレス(偶数アドレスであること)
* out a0.l  転送先末尾のアドレス
*     a1.l  転送元末尾のアドレス
* break d0

memory_copy:
  move d0,-(sp)
  lsr.l #4,d0
  bra 1f
  @@:
    .rept 4
      move.l (a1)+,(a0)+  ;16バイト単位で転送
    .endm
  dbra d0,@b
  clr d0
  1:
  subq.l #1,d0
  bcc @b

  moveq #$f,d0
  and (sp)+,d0  ;16バイト未満の端数
  bra 1f
  @@:
    move.b (a1)+,(a0)+  ;1バイト単位で転送
  1:
  dbra d0,@b
  rts


* コマンドスイッチを初期化する ---------------- *

clear_cmd_sw::
		PUSH	d0/a0
		moveq	#Q_sw_end-Q_sw_start,d0
		lea	(Q_sw_start,a5),a0
@@:		clr.b	(a0)+
		dbra	d0,@b
		POP	d0/a0
		rts


* コマンドスイッチを解析する ------------------ *
* in	a1.l	コマンドスイッチ
* out	a1.l	madoka 本文

analyze_cmd_sw::
		PUSH	d0-d1/a0/a2
		bsr	skip_blank
		lea	(a1),a2			;先頭行を -! 用に保存しておく

		cmpi.b	#'-',(a1)
		bne	ana_cmd_sw_no_sw
**		addq.l	#1,a1
ana_cmd_sw_loop:
		move.b	(a1)+,d0
		cmpi.b	#$20,d0
		bls	ana_cmd_sw_end

		cmpi.b	#'-',d0
		beq	ana_cmd_sw_loop
		cmpi.b	#'!',d0
		beq	ana_cmd_sw_excl
		cmpi.b	#'@',d0
		beq	ana_cmd_sw_atmark
		cmpi.b	#'&',d0
		beq	ana_cmd_sw_and
		moveq	#$20,d1
		or.b	d0,d1
		subi	#'a',d1
		cmpi	#'x'-'a',d1
		bhi	ana_cmd_sw_loop

		add	d1,d1
		move	(@f,pc,d1.w),d1
		jmp	(@f,pc,d1.w)
@@:
		.dc	ana_cmd_sw_a-@b		;-a
		.dc	ana_cmd_sw_loop-@b
		.dc	ana_cmd_sw_c-@b		;-c
		.dc	ana_cmd_sw_d-@b		;-d
		.dc	ana_cmd_sw_loop-@b
		.dc	ana_cmd_sw_f-@b		;-f
		.dc	ana_cmd_sw_g-@b		;-g
		.dc	ana_cmd_sw_h-@b		;-h
		.dc	ana_cmd_sw_i-@b		;-i
		.dc	ana_cmd_sw_j-@b		;-j
		.dc	ana_cmd_sw_k-@b		;-k
		.dc	ana_cmd_sw_l-@b		;-l
		.dc	ana_cmd_sw_m-@b		;-m
		.dc	ana_cmd_sw_n-@b		;-n
		.dc	ana_cmd_sw_o-@b		;-o
		.dc	ana_cmd_sw_p-@b		;-p
		.dc	ana_cmd_sw_q-@b		;-q
		.dc	ana_cmd_sw_loop-@b
		.dc	ana_cmd_sw_s-@b		;-s
		.dc	ana_cmd_sw_t-@b		;-t
		.dc	ana_cmd_sw_loop-@b
		.dc	ana_cmd_sw_v-@b		;-v
		.dc	ana_cmd_sw_loop-@b
		.dc	ana_cmd_sw_x-@b		;-x

ana_cmd_sw_excl:
		move.l	a2,(Q_miss_line,a5)
		bra	ana_cmd_sw_loop
ana_cmd_sw_atmark:
		move.b	d0,(Q_sw_atmark,a5)
		bra	ana_cmd_sw_loop
ana_cmd_sw_and:
		cmpi.b	#'8',(a1)
		bhi	@f
		moveq	#'1',d1
		cmp.b	(a1),d1
		bhi	@f

		move.b	(a1)+,d0		;-&8 ～ -&1
		sub.b	d1,d0
		bset	d0,(Q_sw_prefix,a5)
@@:		bra	ana_cmd_sw_loop

ana_cmd_sw_a:
		move.b	d0,(Q_sw_a,a5)		;-a
		bra	ana_cmd_sw_loop
ana_cmd_sw_c:
		bset	#1,(Q_sw_shift,a5)	;-c
		bra	ana_cmd_sw_loop
ana_cmd_sw_d:
		moveq	#-1,d0			;-d
		cmpi.b	#'1',(a1)
		beq	1f
		cmpi.b	#'2',(a1)
		bne	@f
1:
		move.b	(a1)+,d0		;-d1 / -d2
@@:		move.b	d0,(Q_sw_d,a5)
		bra	ana_cmd_sw_loop
ana_cmd_sw_f:
		move.b	d0,(Q_sw_f,a5)		;-f
		bra	ana_cmd_sw_loop
ana_cmd_sw_g:
		cmpi.b	#'9',(a1)
		bhi	@f
		cmpi.b	#'0',(a1)
		bcs	@f

		move.b	(a1)+,(Q_sw_g,a5)	;-g9 ～ -g0
@@:		bra	ana_cmd_sw_loop
ana_cmd_sw_h:
ana_cmd_sw_k:
		move.b	d0,(Q_sw_h_k,a5)	;-h / -k
		bra	ana_cmd_sw_loop
ana_cmd_sw_i:
		move.b	d0,(Q_sw_i,a5)		;-i
		bra	ana_cmd_sw_loop
ana_cmd_sw_j:
		st	(Q_sw_j,a5)		;-j
		bra	ana_cmd_sw_loop
ana_cmd_sw_l:
		move.b	d0,(Q_sw_l,a5)		;-l
		bra	ana_cmd_sw_loop
ana_cmd_sw_m:
		st	(Q_sw_m,a5)		;-m
		bra	ana_cmd_sw_loop
ana_cmd_sw_n:
		move.b	d0,(Q_sw_n,a5)		;-n
		bra	ana_cmd_sw_loop
ana_cmd_sw_o:
		cmpi.b	#'1',(a1)
		beq	1f
		cmpi.b	#'2',(a1)
		bne	@f
1:
		moveq	#2-'1',d0		;-o1 / -o2
		add.b	(a1)+,d0
		bset	d0,(Q_sw_shift,a5)
@@:		bra	ana_cmd_sw_loop
ana_cmd_sw_p:
		move.b	d0,(Q_sw_p,a5)		;-p
		bra	ana_cmd_sw_loop
ana_cmd_sw_q:
		move.b	d0,(Q_sw_q,a5)		;-q
		bra	ana_cmd_sw_loop
ana_cmd_sw_s:
		move.b	d0,(Q_sw_s,a5)		;-s
		bra	ana_cmd_sw_loop
ana_cmd_sw_t:
		bset	#0,(Q_sw_shift,a5)	;-t
		bra	ana_cmd_sw_loop
ana_cmd_sw_v:
		move.b	d0,(Q_sw_v,a5)		;-v
		bra	ana_cmd_sw_loop
ana_cmd_sw_x:
		cmpi.b	#'5',(a1)
		bhi	@f
		moveq	#'1',d1
		cmp.b	(a1),d1
		bhi	@f

		move.b	(a1)+,d0		;-x5 ～ -x1
		sub.b	d1,d0
		bset	d0,(Q_sw_xfn,a5)
@@:		bra	ana_cmd_sw_loop

ana_cmd_sw_end:
		subq.l	#1,a1
.ifdef ALLOW_NL_AFTER_CMD_SW
		bsr	skip_nl_after_cmd_sw
.endif
ana_cmd_sw_no_sw:
		POP	d0-d1/a0/a2
		rts


* コマンドスイッチ直後の改行を飛ばす ---------- *
* i/o	a1.l	文字列のアドレス
* break	d0/a2

* 本来の madoka の仕様からは外れるが、v2.xx との互換性のため
* オプションの直後が改行になっている定義を許容する。
* 例: .pic -
*	hapic $F

* 影響を最小限に抑えるため、コマンドスイッチ解析の後処理として呼び出す。
* より広範囲に適用させる場合は、unfold_macro の初期化部を
*	move.l	#1<<AFTER_CHAIN,d6
* に替えるというアプローチもある。

.ifdef ALLOW_NL_AFTER_CMD_SW
skip_nl_after_cmd_sw:
		lea	(a1),a2
		cmpi.b	#CR,(a1)+
		beq	@f
		subq.l	#1,a1
@@:		cmpi.b	#LF,(a1)+
		bne	@f
		
		bsr	skip_blank		;次の行の先頭の空白を飛ばす
		beq	@f			;先頭が空白ではなかった
		cmpi.b	#$20,(a1)
		bls	@f			;有効な文字ではない
		cmpi.b	#'-',(a1)
		bne	9f			;条件成立
@@:
		lea	(a2),a1			;元に戻す
9:		rts
.endif


* コマンドスイッチを文字列にする -------------- *
* out	a0.l	コマンドスイッチ(tmp_buf)

CMD_SW_SIZE::	.equ	.sizeof.('-d2g9')+(Q_sw_d-Q_sw_a)

make_cmd_sw::
		lea	(tmp_buf),a0
		PUSH	d0-d1/a0-a1
		move.b	#'-',(a0)+
		lea	(Q_sw_a,a5),a1
		moveq	#Q_sw_d-Q_sw_a-1,d1
make_cmd_sw_loop:
		move.b	(a1)+,d0
		beq	@f
		move.b	d0,(a0)+
@@:		dbra	d1,make_cmd_sw_loop

		move.b	(a1)+,d0		;Q_sw_d
		beq	@f
		move.b	#'d',(a0)+
		tst.b	d0
		bmi	@f			;-d
		move.b	d0,(a0)+		;-d1 / -d2
@@:
		move.b	(a1)+,d0		;Q_sw_g
		beq	@f
		move.b	#'g',(a0)+
		move.b	d0,(a0)+
@@:
		clr.b	(a0)
		POP	d0-d1/a0-a1
		rts


* 空白を飛ばす -------------------------------- *
* i/o	a1.l	文字列のアドレス
* out	ccrZ	1:空白なし 0:空白あり

skip_blank::
		move.l	a1,-(sp)
		bra	@f
skip_blank_loop:
		addq.l	#1,a1
@@:		cmpi.b	#TAB,(a1)
		beq	skip_blank_loop
		cmpi.b	#SPACE,(a1)
		beq	skip_blank_loop

		cmpa.l	(sp)+,a1
		rts





* madoka を飛ばす ----------------------------- *
* i/o	a1.l	文字列のアドレス
* out	ccrZ	0:a1～ に次のコマンドスイッチ＋madoka が続いている
*		1:これ以上 madoka の記述はない
* break	d0

skip_madoka::
* まず、次の行に移動する
@@:		move.b	(a1)+,d0
		beq	skip_madoka_end
		cmpi.b	#EOF,d0
		beq	skip_madoka_end
		cmpi.b	#LF,d0
		bne	@b

		bsr	skip_blank
		beq	skip_madoka_end2	;行頭が空白でなければ madoka 終了

		move.b	(a1)+,d0
		cmpi.b	#'#',d0
		beq	skip_madoka_end		;コメントなら madoka 終了
		cmpi.b	#'-',d0
		bne	skip_madoka		;この行も飛ばす

*行頭から空白＋'-'となっていれば、次の madoka
		tst.b	d0			;ccrZ=0
skip_madoka_end:
		subq.l	#1,a1
skip_madoka_end2:
		rts


* マクロ展開 ---------------------------------- *
* in	a1.l	madoka 本文
* out	d0.l	0:正常終了 -1:メモリ不足
*	ccr	<tst.l d0> の結果
* バッファは free_unfold_buffer で解放すること。

* マクロ展開開始
*		.dc.b	PREFIX,'('
*		.dc.b	'00000000'
*		.dc.b	'macroname',TERM
*		.dc.b	'arg1',TERM
*		.dc.b	'arg2',TERM
*		.dc.b	TERM
*		～マクロ記述内容～
* マクロ展開終了
*		.dc.b	PREFIX,')'

REQ_BRACE1:	.equ	13
REQ_BRACE2:	.equ	12
S_QUOTE:	.equ	11
D_QUOTE:	.equ	10
REQ_BLOCK:	.equ	9
AFTER_CHAIN:	.equ	8

MASK:		.equ	.not.(1<<S_QUOTE+1<<D_QUOTE+1<<REQ_BRACE1+1<<REQ_BRACE2)

PUT: .macro put_op
  subq.l #1,d7
  bcc @skip
    bsr realloc_unfold_buffer
  @skip:
  put_op
.endm

unfold_macro::
  PUSH d1-d7/a0-a4
  move.l sp,(Q_sp_save,a5)

  move.l #UNFOLD_BUF_SIZE,d7
  movea.l (unfold_buf_ptr,pc),a0
  tas (unfold_buf_inuse)
  beq @f  ;内蔵固定バッファが未使用ならそちらを使う
    bsr malloc_all
    move.l d0,d7  ;バッファサイズ
    bmi unf_mac_error
  @@:
  move.l a0,(Q_buf_top,a5)
  lea (a0),a2  ;書き込みポインタ

  moveq #0,d6
  lea (sp),a4
  bsr unfold_macro_sub
  PUT <clr.b (a2)+>  ;正常終了

  movea.l (Q_buf_top,a5),a1
  move.l a2,d1
  sub.l a1,d1
  move.l d1,(Q_buf_size,a5)

  cmpa.l (unfold_buf_ptr,pc),a1
  beq @f
    move.l d1,-(sp)  ;メモリブロックを必要サイズに切り詰める
    pea (a1)
    DOS _SETBLOCK
    addq.l #8,sp
    bsr lift_memory_block  ;必要なら高位メモリに移動
    move.l a1,(Q_buf_top,a5)
  @@:
  moveq #0,d0
  bra unf_mac_return
unf_mac_overflow:
  move.l (Q_buf_top,a5),d0
  bsr free_unfold_buffer  ;バッファ容量不足
unf_mac_error:
  movea.l (Q_sp_save,a5),sp
  moveq #-1,d0  ;バッファ確保失敗
unf_mac_return:
  POP d1-d7/a0-a4
  rts


;マクロ展開バッファを再確保する
;  成功時はd7/a2、Q_buf_topが更新される。
;  エラー時は呼び出し元に戻らずエラー処理に飛ぶ(飛び先でspを復旧させること)。
realloc_unfold_buffer:
  PUSH d0/a0-a1
  movea.l (Q_buf_top,a5),a1
  cmpa.l (unfold_buf_ptr,pc),a1
  bne unf_mac_overflow  ;既に_MALLOCで確保している

  suba.l a1,a2  ;書き込み済みサイズ

  bsr malloc_all
  move.l a0,(Q_buf_top,a5)  ;新しいバッファ先頭アドレス
  move.l d0,d7              ;新しいバッファサイズ
  bmi unf_mac_error  ;このエラーは_MFREE不要

  sub.l a2,d7
  bls unf_mac_overflow
  subq.l #1,d7  ;PUTマクロで引いた分を新しいバッファ残量から引き直す
  ;bcs unf_mac_overflow  ;上でblsしているので不要

  move.l a2,d0  ;内蔵固定バッファから_MALLOCで確保したバッファに複写する
  bsr memory_copy

  lea (a0),a2  ;新しい書き込みポインタ
  POP d0/a0-a1
  bra free_internal_unfold_buffer


;マクロ展開バッファ(内蔵固定バッファ)を未使用状態にする
;  レジスタを破壊しないこと。

free_internal_unfold_buffer:
  clr.b (unfold_buf_inuse)
  rts


* マクロ展開バッファを解放する ---------------- *
* in  d0.l  バッファアドレス
* break d0

free_unfold_buffer:
  cmp.l (unfold_buf_ptr,pc),d0
  beq free_internal_unfold_buffer

  move.l d0,-(sp)
  DOS _MFREE
  addq.l #4,sp
  rts


* マクロ展開下請け ---------------------------- *

unfold_macro_sub::
unf_mac_loop:
		bsr	skip_blank
		beq	unf_mac_no_blank

		move.b	(a1)+,d0
		cmpi.b	#'#',d0
		beq	unf_mac_comment		;空白＋'#' でコメント
		cmpi.b	#'\',d0
		beq	unf_mac_bslash		;空白＋'\' で行連結
		subq.l	#1,a1
unf_mac_no_blank:
		move.b	(a1)+,d0
		beq	unf_mac_end
		cmpi.b	#LF,d0
		beq	unf_mac_lf
		cmpi.b	#CR,d0
		beq	unf_mac_cr
		cmpi.b	#EOF,d0
		beq	unf_mac_end

		cmpi.b	#"'",d0
		beq	unf_mac_s_quote
		btst	#S_QUOTE,d6
		bne	unf_mac_not_chain
		cmpi.b	#'"',d0
		beq	unf_mac_d_quote

		cmpi.b	#'$',d0
		beq	unf_mac_dollar
		cmpi.b	#'(',d0
		beq	unf_mac_paren
		tst.b	d6
		beq	@f
		cmpi.b	#')',d0
		bne	@f
		subq.l	#1,a1			;$(macro arg1 arg2)
		rts				;		  ^
@@:
		cmpi.b	#';',d0
		beq	unf_mac_chain
		cmpi.b	#'{',d0
		bne	@f
		bclr	#REQ_BRACE1,d6
		beq	unf_mac_chain		;ブロック開始の '{'
		bset	#REQ_BRACE2,d6
		bra	unf_mac_not_chain	;${foo} の '{'
@@:
		cmpi.b	#'}',d0
		bne	@f
		bclr	#REQ_BRACE2,d6
		beq	unf_mac_chain		;ブロック終了の '}'
		bra	unf_mac_not_chain	;${foo} の '}'
@@:
		cmpi.b	#'|',d0
		bne	unf_mac_not_chain
		cmp.b	(a1),d0
		bne	unf_mac_not_chain	;単独の '|'

		addq.l	#1,a1
		moveq	#';',d0			;'||' は ';' に変換する
unf_mac_chain:
		bset	#AFTER_CHAIN,d6		;チェイン記号
		bclr	#REQ_BLOCK,d6
		bra	unf_mac_put2
unf_mac_not_chain:
		bclr	#AFTER_CHAIN,d6
		bclr	#REQ_BLOCK,d6		;前の行がチェインで終わっていなければ
		bne	unf_mac_end		;次の文字は { } でなければならない
unf_mac_put:
		PUT	<move.b  d0,(a2)+>
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	unf_mac_next		;１バイト文字

		move.b	(a1)+,d0		;２バイト文字
		bne	unf_mac_put2
		addq.l	#1,d7
		subq.l	#1,a2
		bra	unf_mac_end
unf_mac_put2:
		PUT	<move.b  d0,(a2)+>
unf_mac_next:
		moveq	#$20,d0
		cmp.b	(a1),d0
		bcs	unf_mac_no_blank	;次の文字は空白ではない
		beq	@f
		cmpi.b	#TAB,(a1)
		bne	unf_mac_no_blank
@@:
		btst	#S_QUOTE,d6
		bne	1f
		btst	#D_QUOTE,d6
		beq	@f
1:
		PUT	<move.b  (a1)+,(a2)+>	;'～'/"～" 処理中の空白
		cmpi.b	#'\',(a1)
		bne	unf_mac_next
		addq.l	#1,a1			;'～'/"～" 処理中の行連結
		bra	unf_mac_bslash
@@:
		tst.b	d6
		bne	@f
		PUT	<move.b  d0,(a2)+>
		bra	unf_mac_loop
@@:		rts


* ' : シングルクオート
unf_mac_s_quote:
		bchg	#S_QUOTE,d6
		bra	unf_mac_not_chain

* " : ダブルクオート
unf_mac_d_quote:
		bclr	#S_QUOTE,d6
		bchg	#D_QUOTE,d6
		bra	unf_mac_not_chain


* $ : 変数
unf_mac_dollar:
		cmpi.b	#'(',(a1)
		beq	unf_mac_d_paren

		lea	(a1),a0
		move.b	(a1)+,d0
		cmpi.b	#'?',d0
		bne	@f
		move.b	(a1)+,d0		;$?
@@:
		cmpi.b	#'@',d0
		beq	1f			;$@
		cmpi.b	#'%',d0
		bne	@f
1:		move.b	(a1)+,d0		;$%
@@:
		cmpi.b	#'{',d0
		bne	@f
		bset	#REQ_BRACE1,d6		;${foo}
@@:
		lea	(a0),a1
		moveq	#'$',d0
		bra	unf_mac_not_chain


* $( : 引数付きマクロ
unf_mac_d_paren:
		PUSH	d7/a1/a2
		addq.l	#1,a1

		PUT	<move.b  #PREFIX,(a2)+>	;マクロ引数列開始マーク
		PUT	<move.b  #'(',(a2)+>
		moveq	#8-1,d0
@@:
		PUT	<move.b  #'0',(a2)+>
		dbra	d0,@b
		move.l	a2,d4			;マクロ名先頭アドレス

		move.b	(a1)+,d0
		bsr	is_macro_char1
		bra	1f
unf_mac_d_paren_loop:
		PUT	<move.b  d0,(a2)+>
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f			;１バイト文字
		move.b	(a1)+,d0		;２バイト文字
		cmpi.b	#$20,d0
		bls	unf_mac_paren9		;検索の都合上 $20 以下はエラー
		PUT	<move.b  d0,(a2)+>
@@:
		move.b	(a1)+,d0
		bsr	is_macro_char2
1:		bne	unf_mac_d_paren_loop

		subq.l	#1,a1

		move.l	a2,d5			;マクロ名末尾アドレス
		PUT	<clr.b  (a2)+>		;あとで LF に書き換える
unf_mac_d_paren_loop2:
		move.l	a2,-(sp)
		move.b	d6,-(sp)
		move.b	#')',d6
		PUSH	d4/d5
		bsr	unfold_macro_sub	;引数を展開する
		POP	d4/d5
		move.b	(sp)+,d6
		cmpa.l	(sp)+,a2
		beq	@f

		PUT	<move.b  #TERM,(a2)+>	;マクロ引数終了マーク
		bra	unf_mac_d_paren_loop2
@@:
		cmpi.b	#')',(a1)+
		bne	unf_mac_d_paren9

		PUT	<move.b  #TERM,(a2)+>	;マクロ引数列終了マーク

		move.l	d4,d0
		bsr	search_macro
		tst.l	d0
		beq	unf_mac_d_paren9	;未定義

		movea.l	d5,a0
		move.b	#TERM,(a0)		;NUL を書き換える

**		POP	d7/a1/a2
		lea	(.sizeof.(d7/a1/a2),sp),sp

		move.l	a1,-(sp)
		movea.l	d0,a1
		bsr	unfold_macro_sub	;再帰展開
		movea.l	(sp)+,a1

		PUT	<move.b  #PREFIX,(a2)+>	;マクロ展開終了マーク
		PUT	<move.b  #')',(a2)+>

		bra	unf_mac_next		;unf_mac_loop
unf_mac_d_paren9:
		POP	d7/a1/a2
		moveq	#'$',d0
		bra	unf_mac_not_chain


* ( : マクロ
unf_mac_paren:
		move.l	a1,-(sp)
		move.b	(a1)+,d0
		bsr	is_macro_char1
		bra	1f
unf_mac_paren_loop:
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f			;１バイト文字
		cmpi.b	#$20,(a1)+		;２バイト文字
		bls	unf_mac_paren9		;検索の都合上 $20 以下はエラー
@@:
		move.b	(a1)+,d0
		bsr	is_macro_char2
1:		bne	unf_mac_paren_loop
		cmpi.b	#')',-(a1)
		bne	unf_mac_paren9

		move.l	(sp),d0
		clr.b	(a1)			;')' を消す
		bsr	search_macro
		move.b	#')',(a1)+		;')' を戻す
		tst.l	d0
		beq	unf_mac_paren9		;未定義

		move.l	a1,(sp)
		movea.l	d0,a1
		bsr	unfold_macro_sub	;再帰展開
		movea.l	(sp)+,a1
		bra	unf_mac_next		;unf_mac_loop
unf_mac_paren9:
		movea.l	(sp)+,a1
		moveq	#'(',d0
		bra	unf_mac_not_chain

* マクロに使用可能な文字か調べる
is_macro_char2:
		cmpi.b	#'0',d0
		bcs	is_macro_char1
		cmpi.b	#'9',d0
		bls	is_macro_char_t		;0-9
is_macro_char1:
		tst.b	d0
		bmi	is_macro_char_t		;二バイト文字/片仮名
		cmpi.b	#'z',d0
		bhi	is_macro_char_f
		cmpi.b	#'a',d0
		bcc	is_macro_char_t		;a-z
		cmpi.b	#'_',d0
		beq	is_macro_char_t
		cmpi.b	#'-',d0
		beq	is_macro_char_t
		cmpi.b	#'Z',d0
		bhi	is_macro_char_f
		cmpi.b	#'A',d0
		bcc	is_macro_char_t		;A-Z
		cmpi.b	#'+',d0
		beq	is_macro_char_t
is_macro_char_f:
		moveq	#0,d0
		rts
is_macro_char_t:
		tst.b	d0
		rts

* マクロ検索
* in	d0.l	マクロ名のアドレス
* out	d0.l	展開する madoka のアドレス(0 ならマクロ未定義)
search_macro:
		PUSH	d1-d2/a0-a3
		movea.l	d0,a1
		moveq	#$20,d1
		lea	(macro_table),a3
		bra	sch_mac_start
sch_mac_loop:
		movea.l	d0,a2
		lea	(a2),a0
@@:		cmp.b	(a0)+,d1
		bcs	@b
		move.b	-(a0),d2
		clr.b	(a0)			;マクロ名を切り出す
		jsr	(strcmp_a1_a2)
		bne	sch_mac_next

		move.b	d2,(a0)			;元に戻す
		lea	(a0),a1
		bsr	skip_blank
		move.l	a1,d0
		bra	sch_mac_end
sch_mac_next:
		move.b	d2,(a0)			;元に戻す
sch_mac_start:
		move.l	(a3)+,d0
		bne	sch_mac_loop
sch_mac_end:
		POP	d1-d2/a0-a3
		rts


* \ : 行連結
unf_mac_bslash:
		lea	(a1),a0
		bsr	skip_blank
		move.b	(a1)+,d0
		cmpi.b	#LF,d0
		beq	unf_mac_bslash_lf	;空白＋'\'＋(空白)＋LF
		cmpi.b	#CR,d0
		beq	unf_mac_bslash_cr	;空白＋'\'＋(空白)＋CR
		cmpi.b	#'#',d0
		bne	@f
		subq.l	#1,a1
		cmpa.l	a0,a1
		bne	unf_mac_bslash_comment	;空白＋'\'＋空白＋'#'
@@:
		lea	(a0),a1			;行連結ではない '\'
		moveq	#'\',d0
		btst	#S_QUOTE,d6
		bne	unf_mac_not_chain	;'～' 処理中

		cmpi	#2,(＄unix)
		bcs	unf_mac_not_chain	;%unix 0/1 なら '\' そのもの

		bclr	#AFTER_CHAIN,d6
		bclr	#REQ_BLOCK,d6		;%unix 2 なら次の文字のエスケープ
		bne	unf_mac_end

		PUT	<move.b  d0,(a2)+>	;まず '\' を書き出す

		move.b	(a1)+,d0
		cmpi.b	#$20,d0
		bcc	unf_mac_put		;次の文字を書き出す
		move.l	#1<<EOF+1<<CR+1<<LF+1<<NUL,d1
		btst	d0,d1
		beq	unf_mac_put
		bra	unf_mac_end

* 空白＋'\'＋(空白)＋CR
unf_mac_bslash_cr:
		cmpi.b	#LF,(a1)+
		beq	@f
		subq.l	#1,a1
@@:		bra	unf_mac_bslash_lf

* 空白＋'\'＋空白＋'#'
unf_mac_bslash_comment:
		move.b	(a1)+,d0
		beq	unf_mac_end
		cmpi.b	#EOF,d0
		beq	unf_mac_end
		cmpi.b	#LF,d0
		bne	unf_mac_bslash_comment
		bra	unf_mac_bslash_lf

* 空白＋'\'＋(空白)＋LF
unf_mac_bslash_lf:
		andi	#MASK,d6
		bsr	skip_blank
		beq	unf_mac_end		;次行の先頭が空白ではない
		move.b	(a1),d0
		cmpi.b	#'-',d0
		beq	unf_mac_end		;コマンドスイッチ

		subq.l	#1,a1			;空白を指すようにする
		bra	unf_mac_loop


* CR : 復帰
unf_mac_cr:
		cmpi.b	#LF,(a1)+
		beq	@f
		subq.l	#1,a1
@@:		bra	unf_mac_lf


* # : コメント
unf_mac_comment:
		move.b	(a1)+,d0
		beq	unf_mac_end
		cmpi.b	#EOF,d0
		beq	unf_mac_end
		cmpi.b	#LF,d0
		bne	unf_mac_comment
		bra	unf_mac_lf


* LF : 改行
unf_mac_lf:
		andi	#MASK,d6
		bsr	skip_blank
		beq	unf_mac_end		;次行の先頭が空白ではない
		move.b	(a1),d0
		cmpi.b	#'-',d0
		beq	unf_mac_end		;コマンドスイッチ

		subq.l	#1,a1			;空白を指すようにする
		btst	#AFTER_CHAIN,d6
		bne	unf_mac_loop		;前の行がチェインで終わっていた
		bset	#REQ_BLOCK,d6
		bra	unf_mac_loop		;それ以外なら { } が必要

* 終了
unf_mac_end:
		rts


* マクロ展開済み madoka 表示(デバッグ用) ------ *

print_unfold_madoka:
		PUSH	d0/a0
		PR_STR	<"==== unfold ====",LF>
		movea.l	(Q_buf_top,a5),a0
1:
		moveq	#0,d0
		move.b	(a0)+,d0
		beq	9f
		cmpi.b	#PREFIX,d0
		beq	7f
		cmpi.b	#TERM,d0
		beq	5f

		move	d0,-(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp
		bra	1b
5:
		cmpi.b	#TERM,(a0)
		beq	6f
		PR_STR	<" ">			;TERM,'nextarg'
		bra	1b
6:
		addq.l	#1,a0			;TERM が二つ連続すれば引数列の終わり
		PR_STR	<"]">
		bra	1b
7:
		cmpi.b	#'(',(a0)+
		bne	8f
		addq.l	#8,a0			;PREFIX,'(',$00×8,'macroname'
		PR_STR	<"[マクロ開始 ">
		bra	1b
8:
		PR_STR	<"[マクロ終了]">	;PREFIX,')'
		bra	1b
9:
		jsr	(PrintCrlf)
		POP	d0/a0
		rts


* ブロック通過 -------------------------------- *
* in	a1.l	madoka 本文
* out	a1.l	次回実行アドレス(NULL なら終了)

skip_block::
		move.b	(Q_skip,a5),-(sp)
		st	(Q_skip,a5)
		bsr	execute_block
		move.b	(sp)+,(Q_skip,a5)
		rts


* ブロック実行 -------------------------------- *
* in	a1.l	madoka 本文
* out	a1.l	次回実行アドレス(NULL なら終了)

execute_block::
		move.l	d0,-(sp)
		bsr	get_char		;'{' を飛ばす

		move.l	(Q_funcname,a5),-(sp)
**		move.b	(Q_if_flag,a5),-(sp)
		clr.b	(Q_if_flag,a5)		;&if 成立フラグを初期化
exe_b_loop:
		bsr	execute_madoka
exe_b_loop2:
		tst.b	(Q_abort,a5)
		bne	exe_b_end
		move.l	a1,d0
		beq	exe_b_error
exe_b_loop3:
		bsr	fetch_char
		beq	exe_b_error
		cmpi.b	#'{',d0
		beq	exe_b_brace1
		cmpi.b	#'}',d0
		beq	exe_b_brace2
		cmpi.b	#';',d0
		bne	exe_b_loop

		clr.b	(Q_if_flag,a5)		;&if 成立フラグを初期化
		bsr	get_char		;';' を飛ばす
		bra	exe_b_loop3

* { : ブロック開始
exe_b_brace1:
		bsr	execute_block
		bra	exe_b_loop2

exe_b_error:
		suba.l	a1,a1
		moveq	#MES_MERR1,d0
		jsr	(PrintMsgCrlf)
		bra	exe_b_end

* } : ブロック終了
exe_b_brace2:
		bsr	get_char		;'}' を飛ばす
		bra	exe_b_end

exe_b_end:
**		move.b	(sp)+,(Q_if_flag,a5)
		move.l	(sp)+,(Q_funcname,a5)
		move.l	(sp)+,d0
		rts


* madoka 実行 --------------------------------- *
* in	a1.l	madoka 本文
* out	a1.l	次回実行アドレス(NULL なら終了)

execute_madoka::
		PUSH	d0-d7/a0/a2-a5
exe_m_loop:
		clr.l	(Q_rl_ptr,a5)

		bsr	malloc_all		;トークン切り出しバッファを確保
		move.l	d0,-(sp)
		bmi	exe_m_memory_error
		move.l	a0,(sp)			;終了時に解放するためスタックに積んでおく

		move.l	d0,d7			;バッファサイズ
		lea	(a0),a4			;バッファ先頭
		lea	(a0),a2			;書き込みポインタ
		moveq	#0,d6
		bra	1f
@@:
		add.l	d0,d6			;トークン数
1:		bsr	get_token
		bgt	@b
		bmi	exe_m_memory_error

		move.l	a1,(Q_next_ptr,a5)	;次回実行アドレス
		tst.l	d6
		beq	exe_m_return		;トークンなし
		tst.b	(Q_skip,a5)
		bne	exe_m_return		;スキップ中

		suba.l	a4,a2			;トークン列のバイト数
		pea	(MARGIN,a2)		;引数列の末尾に余裕を持たせる
		pea	(a4)
		DOS	_SETBLOCK
		addq.l	#8,sp

		bsr	execute_ma_req		;MA_REQ の処理

* $< があった場合は行編集を行う
		move.l	(Q_rl_ptr,a5),d5
		beq	exe_m_exec
		cmpa.l	#RL_MAX,a2
		bhi	exe_m_exec		;トークンが長すぎる

**		PR_STR	<"==== readline ====",LF>

* 行入力バッファを確保
		clr.l	-(sp)
		addq	#1,(sp)			;RL_MAX+1
		.fail	(RL_MAX+1)!=$0001_0000
		DOS	_MALLOC
		move.l	d0,(sp)+
		bmi	exe_m_memory_error
		movea.l	d0,a1			;バッファ

* トークンを文字列に戻す
		PUSH	d6/a0-a1
		lea	(a4),a0
		bra	@f
exe_m_rl_cat_loop:
		move.b	#SPACE,(-1,a1)
@@:
		cmpa.l	d5,a0
		bne	1f
		move.l	a1,(Q_rl_ptr,a5)	;カーソル位置を補正
1:
		move.b	(a0)+,d0		;↓ここから remove_tc とほぼ同じ
		cmpi.b	#TC_FILE,d0
		beq	@b
		cmpi.b	#TC_ESC,d0
		bne	1f
		move.b	(a0)+,d0
1:		cmpi.b	#PREFIX,d0
		beq	2f
		cmpi.b	#TERM,d0
		bne	3f
2:		moveq	#SPACE,d0		;マクロ制御コードは空白に置き換える
3:		move.b	d0,(a1)+
		beq	@f
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		move.b	(a0)+,(a1)+
		bne	@b			;↑ここまで
@@:
		subq.l	#1,d6
		bne	exe_m_rl_cat_loop
		POP	d6/a0-a1

		DOS	_MFREE			;トークン切り出しバッファを解放
		move.l	a1,(sp)			;行入力バッファ

		GETMES	MES_ICOMD
		bsr	open_rl_win
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)
		move	d0,-(sp)
		move	#78,-(sp)		;ウィンドウ幅

		move.l	#RL_MAX<<16+RL_F_CSR,d1
		jsr	(is_exist_cmd_his)
		beq	@f
		addq	#RL_F_RD,d1		;ROLL DOWN でヒストリ突入
@@:
		move.l	(Q_rl_ptr,a5),d2
		sub.l	a1,d2			;カーソル位置

		move.l	(sp),d0
		jsr	(MintReadLine)
		move.l	d0,d2
		jsr	(break_check1)		;ブレークキーの状態を更新
		move.l	(sp)+,d0
		jsr	(WinClose)
		tst.l	d2
		bgt	exe_m_rl_history

		tst.b	(Q_sw_a,a5)
		bne	@f
		bsr	make_cmd_sw		;ヒストリに登録する
		jsr	(add_cmd_his)
@@:
		tst.l	d2
		bmi	exe_m_rl_cancel
* 確定
		STRLEN	a1,d1
		bsr	eval_sub
		bmi	exe_m_memory_error

		DOS	_MFREE			;行入力バッファを解放
		addq.l	#4,sp

		movea.l	(Q_next_ptr,a5),a1	;もう一度解釈する
		bra	exe_m_loop
* ヒストリ突入
exe_m_rl_history:
		DOS	_MFREE			;行入力バッファを解放

		moveq	#0,d7			;引数なし
		bsr	call_command_history
		bra	exe_m_end


* そのまま実行する
exe_m_exec:
		lea	(a4),a0
		tst.b	(Q_expand_only,a5)
		bne	exe_m_expand

		move.l	d6,d0
		move.l	a2,d1			;トークンバッファのサイズ
		bsr	execute_command
		jsr	(break_check1)		;ブレークキーの状態を更新
		bra	exe_m_end
exe_m_expand:
		clr.b	(1023,a0)		;1KB 制限
		movea.l	(expand_buf,pc),a1
		STRCPY	a0,a1
		bra	exe_m_return

exe_m_rl_cancel:
exe_m_memory_error:
		st	(Q_abort,a5)
		clr.l	(Q_next_ptr,a5)
exe_m_return:
		tst.l	(sp)
		ble	exe_m_end
		DOS	_MFREE			;トークン切り出し/行入力バッファを解放
exe_m_end:
		addq.l	#4,sp
		move.l	(Q_next_ptr,a5),a1
		POP	d0-d7/a0/a2-a5
		rts


* 行入力ウィンドウを開く ---------------------- *
* in	d0.l	タイトル文字列
* out	d0.l	ウィンドウ番号

open_rl_win::
		PUSH	d1/a0
		lea	(subwin_rl,pc),a0
		move.l	d0,(SUBWIN_TITLE,a0)
		moveq	#(96-80)/2,d0
		move	(＄kz_x),d1
		bmi	@f			;中央寄せ
		moveq	#96-80,d0
		cmp	d1,d0
		bls	@f
		move	d1,d0
@@:		move	d0,(SUBWIN_X,a0)
		move	(＄kz_y),d0
		cmpi	#28,d0
		bhi	@f
		move	d0,(SUBWIN_Y,a0)
@@:		jsr	(WinOpen)
		POP	d1/a0
		rts


* MA_REQ の処理 ------------------------------- *
* mintarc 暫定対応.

execute_ma_req::
		PUSH	d0-d7/a0-a4
		movea.l	(PATH_OPP,a6),a6
		move.b	(Q_ma_req_opp,a5),d7	;反対側
		clr.b	(Q_ma_req_opp,a5)
		bsr	exe_ma_req_sub
		movea.l	(PATH_OPP,a6),a6
		beq	@f
		jsr	(ReverseCursorBarOpp)
@@:
		move.b	(Q_ma_req_cur,a5),d7	;カーソル側
		clr.b	(Q_ma_req_cur,a5)
		bsr	exe_ma_req_sub
		beq	@f
		jsr	(ReverseCursorBar)
@@:
		POP	d0-d7/a0-a4
		rts

* in	d7.b	Q_ma_req_{cur,opp}
* out	d0.l	0:再描画なし 1:あり
exe_ma_req_sub:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f			;mintarc でなければ展開不要
		tst.b	(Q_expand_only,a5)
		bne	@f

		moveq	#1<<MA_REQ_MARK+1<<MA_REQ_FILE+1<<MA_REQ_PATH,d0
		and.b	d7,d0
		beq	@f
		jsr	(mintarc_extract)
@@:
		btst	#MA_REQ_REDRAW,d7
		beq	exe_ma_req_end

		move	(PATH_WIN_MARK,a6),d0
		jsr	(WinClearAll)
		jsr	(print_file_list)
		moveq	#1,d0
		rts
exe_ma_req_end:
		moveq	#0,d0
		rts


* トークン切り出し ---------------------------- *
* in	a1.l	文字列のアドレス
*	a2.l	トークン書き込みバッファ
*	d7.l	バッファ残りバイト数
* out	d0.l	トークン数(-1 ならバッファ容量不足)
*	ccr	<tst.l d0> の結果
*	a1.l	トークン取り出し後のアドレス
*	a2.l	〃		    アドレス
*	d7.l	〃		    残りバイト数

PUT:		.macro	put_op
		subq.l	#1,d7
**		bcs	get_token_overflow
		bls	get_token_overflow	;２バイトあるか確認する
		put_op
		.endm

CHK:		.macro	ea
		cmp.l	ea,d7
		bcs	get_token_overflow
		.endm

PASS:		.macro
		STRLEN	a2,d0
		sub.l	d0,d7
		adda.l	d0,a2
		.endm

BACK:		.macro	ea
		add.l	ea,d7
		suba.l	ea,a2
		.endm


V_Q:		.equ	19
V_AT:		.equ	18
V_PER:		.equ	17
V_BRACE:	.equ	16

T_MACRO:	.equ	11
T_S_QUOTE:	.equ	10
T_D_QUOTE:	.equ	9
T_WORD:		.equ	8

get_token2::
		PUSH	d1-d7/a0/a3-a4/a6
		move.l	#1<<T_MACRO,d6
		bra	@f
get_token::
		PUSH	d1-d7/a0/a3-a4/a6	;変数展開中に a6 を変える事がある
		moveq	#0,d6
@@:		moveq	#0,d5

		move.l	(Q_sp_save,a5),-(sp)
		move.l	sp,(Q_sp_save,a5)

		bsr	skip_blank
		bsr	get_token_sub
		btst	#T_WORD,d6
		beq	@f

		PUT	<clr.b  (a2)+>
@@:
		move.l	d5,d0			;トークン数
get_token_end:
		move.l	(sp)+,(Q_sp_save,a5)
		POP	d1-d7/a0/a3-a4/a6
		tst.l	d0
		rts

get_token_overflow:
		movea.l	(Q_sp_save,a5),sp
		moveq	#-1,d0
		bra	get_token_end

* 下請け
get_token_loop:
		bset	#T_WORD,d6
		bne	get_token_loop2
		addq.l	#1,d5			;トークン開始
get_token_sub::
get_token_loop2:
		bsr	get_char
		beq	get_token_nul

		cmpi.b	#'z',d0
		bhi	@f
		cmpi.b	#'a',d0
		bcc	get_token_char1		;a-z
		cmpi.b	#'Z',d0
		bhi	@f
		cmpi.b	#'A',d0
		bcc	get_token_char1		;A-Z
@@:
		cmpi.b	#"'",d0
		beq	get_token_s_quote
		cmpi.b	#'"',d0
		beq	get_token_d_quote
		btst	#T_S_QUOTE,d6
		bne	get_token_char2

		cmpi.b	#'$',d0
		beq	get_token_dollar
		cmpi.b	#'~',d0
		beq	get_token_tilde
		cmpi.b	#'\',d0
		beq	get_token_bslash

		btst	#T_D_QUOTE,d6
		bne	get_token_char2

		cmpi.b	#SPACE,d0
		beq	get_token_blank
		cmpi.b	#';',d0
		beq	get_token_chain
		cmpi.b	#'{',d0
		beq	get_token_chain
		cmpi.b	#'}',d0
		beq	get_token_chain
get_token_char2:
		.fail	(TERM<=TC_FILE).or.(TERM<=TC_ESC)
		cmpi.b	#TERM,d0
		bhi	get_token_char3
		beq	get_token_lf		;マクロ引数の終了
		cmpi.b	#TC_FILE,d0
		beq	@f
		cmpi.b	#TC_ESC,d0
		bne	get_token_char3
@@:
* TC_FILE、TC_ESC と同じコードはエスケープする
		PUT	<move.b  #TC_ESC,(a2)+>
get_token_char3:
		PUT	<move.b  d0,(a2)+>
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	get_token_loop

		move.b	(a1)+,d0		;２バイト文字
get_token_char1:
		PUT	<move.b  d0,(a2)+>
		bra	get_token_loop

* 空白
get_token_blank:
		btst	#T_MACRO,d6
		bne	get_token_char1		;マクロ引数展開中
		btst	#T_WORD,d6
		beq	get_token_loop2		;まだトークンが始まっていない
		rts

* \ : エスケープ
get_token_bslash:
		cmpi	#2,(＄unix)
		bcs	get_token_char1		;%unix 0/1 なら '\' そのもの

		bsr	get_char		;%unix 2 なら次の文字を通す
		bne	get_token_char2
		bra	get_token_nul

* ; { } : チェイン記号
get_token_chain:
		btst	#T_MACRO,d6
		bne	get_token_char1		;マクロ引数展開中
* NUL
* LF : マクロ引数終了
get_token_nul:
get_token_lf:
		subq.l	#1,a1
		rts

* ' : クォーティング
get_token_s_quote:
		bchg	#T_S_QUOTE,d6
		btst	#T_D_QUOTE,d6
		bne	get_token_char1		;"～ 処理中の '
		bra	get_token_loop

* " : クォーティング
get_token_d_quote:
		btst	#T_S_QUOTE,d6
		beq	@f
		btst	#T_D_QUOTE,d6
		beq	get_token_char1		;'～ 処理中の "
		bclr	#T_S_QUOTE,d6		;"～'～ 処理中の "
@@:		bchg	#T_D_QUOTE,d6
		bra	get_token_loop


* 上層マクロのアドレスを収得する
* out	d0.l	マクロアドレス
get_prev_macro:
		PUSH	d1-d2/a1
		movea.l	(Q_macro,a5),a1
		moveq	#0,d1
		moveq	#8-1,d2
@@:
		moveq	#$f,d0
		lsl.l	#4,d1
		and.b	-(a1),d0
		or.b	d0,d1
		dbra	d2,@b
		add.l	a1,d1
		move.l	d1,d0
		POP	d1-d2/a1
		rts


* 文字収得
* in	a1.l	文字列のアドレス
* out	a1.l	〃
*	d0.b	文字コード
*	ccr	<tst.b d0> の結果
* 備考:
*	マクロ展開開始/終了マークは内部で処理し、返値には
*	現われない. マクロ記述内の再帰マクロも同様.
*	マクロ引数を走査中に引数終了マーク(LF)を発見したら
*	マークをそのまま返す.

get_char::
		move.b	(a1)+,d0
		beq	get_char_nul
		cmpi.b	#PREFIX,d0
		bne	get_char_end		;通常の文字 or TERM
		move.b	(a1)+,d0
		beq	get_char_nul
		cmpi.b	#')',d0
		beq	get_char_mac_end	;PREFIX,')' : マクロ展開終了マーク
		cmpi.b	#'(',d0
		beq	get_char_mac_start	;PREFIX,'(' : マクロ展開開始マーク
		bra	get_char
get_char_mac_end:
		bsr	get_prev_macro
		move.l	d0,(Q_macro,a5)
		bra	get_char
get_char_mac_start:
		PUSH	d1-d2
		move.l	(Q_macro,a5),d1
		sub.l	a1,d1
		moveq	#8-1,d2
@@:
		moveq	#$f,d0
		and.b	d1,d0
		addi.b	#'0',d0
		lsr.l	#4,d1
		move.b	d0,(a1)+
		dbra	d2,@b
		POP	d1-d2
		move.l	a1,(Q_macro,a5)
@@:
		bsr	get_char
		cmpi.b	#TERM,d0
		bne	@b			;引数を飛ばす
		cmp.b	(a1),d0
		bne	@b			;次の引数
		addq.l	#1,a1
		bra	get_char
get_char_nul:
get_char_end:
		tst.b	d0
		rts


* 次の文字を先読みする
fetch_char2::
		bsr	get_char
		bra	fetch_char

* 文字先読み
* in	a1.l	文字列のアドレス
*	d0.b	文字コード
*	ccr	<tst.b d0> の結果

fetch_char::
		move.l	(Q_macro,a5),-(sp)
		move.l	a1,-(sp)
		bsr	get_char
		movea.l	(sp)+,a1
		move.l	(sp)+,(Q_macro,a5)
		tst.b	d0
		rts


* ~/ : ホームディレクトリ展開
get_token_tilde:
		tst.b	(Q_skip,a5)
		bne	get_token_char1		;スキップ中

		bsr	fetch_char
		cmpi.b	#'/',d0
		bne	get_token_tilde9	;単独の '~'

* $HOME を展開する
		lea	(tmp_buf),a3
		pea	(a3)
		clr.l	-(sp)
		pea	(str_home,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	get_token_tilde9
		tst.b	(a3)
		beq	get_token_tilde9

		PUT	<move.b  #TC_FILE,(a2)+>
		move.l	a2,-(sp)
		exg	a1,a3
		bsr	put_a1_esc
		exg	a1,a3
		movea.l	(sp)+,a3

* 最後の文字を調べる
		moveq	#0,d1
@@:		move.b	(a3)+,d0
		beq	@f
		move.b	d0,d1
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		tst.b	(a3)+
		bne	@b
@@:
		bsr	get_char		;'/' を取り出す
		cmp.b	d0,d1
		beq	@f			;c:// にならないようにする
		PUT	<move.b  d0,(a2)+>
@@:
		PUT	<move.b  #TC_FILE,(a2)+>
		bra	get_token_loop
get_token_tilde9:
		moveq	#'~',d0
		bra	get_token_char1


* $ : 変数展開
get_token_dollar:
		move.l	(Q_macro,a5),-(sp)	;アボート用に保存
		move.l	a1,-(sp)		;〃

		ext.l	d6			;V_Q～V_BRACE をクリア

		bsr	fetch_char
		cmpi.b	#'?',d0
		bne	@f
		bset	#V_Q,d6			;変数 $?
		bsr	fetch_char2
@@:
		cmpi.b	#'@',d0
		bne	@f
		bset	#V_AT,d6		;システム変数 $@
		bra	1f
@@:
		cmpi.b	#'%',d0
		bne	@f
		bset	#V_PER,d6		;環境変数 $%
1:		bsr	fetch_char2
@@:
		cmpi.b	#'{',d0
		bne	@f
		bset	#V_BRACE,d6		;${
		bsr	fetch_char2
@@:

* 変数名を取り出す
		move.l	a2,d2
		PUSH	d7/a2
@@:
		cmpi.b	#'!',d0
		beq	1f			;$del! 対策
		cmpi.b	#'#',d0
**		seq	d3
		beq	1f			;$# 対策
		cmpi.b	#'&',d0
**		seq	d3
		beq	1f			;$& 対策
		cmpi.b	#'-',d0
		beq	1f
		cmpi.b	#'0',d0
		bcs	9f
		cmpi.b	#'9',d0
		bls	1f			;0-9
		cmpi.b	#'<',d0
**		seq	d3
		beq	1f			;$< 対策
		cmpi.b	#'A',d0
		bcs	9f
		cmpi.b	#'Z',d0
		bls	1f			;A-Z
		cmpi.b	#'_',d0
		beq	1f
		cmpi.b	#'a',d0
		bcs	9f
		cmpi.b	#'z',d0
		bls	1f			;a-z
		move.b	d0,d1
		bpl	9f
		lsr.b	#5,d1
		btst	d1,#%10010000
		beq	1f
		PUT	<move.b  d0,(a2)+>	;２バイト文字
		bsr	get_char		;上位バイトを読み捨てる
		PUT	<move.b  (a1)+,(a2)+>
		bsr	fetch_char
		bra	@b
1:
		PUT	<move.b  d0,(a2)+>
		bsr	fetch_char2
**		tst.b	d3
**		beq	@b			;$# $& $< $O# なら変数名は終了
		bra	@b
9:
		sub.l	a2,d2
		PUT	<clr.b  (a2)+>
		POP	d7/a2
		neg.l	d2			;変数名の長さ
		beq	get_token_d_9		;変数名が記述されていない

**		btst	#V_BRACE,d6
**		beq	@f
**		cmpi.b	#':',d0
**		beq	@f
**		cmpi.b	#'}',d0
**		bne	get_token_d_9		;変数名の記述が不正
**@@:
		moveq	#0,d4			;変数内項目数-1
		tst.b	(Q_skip,a5)
		beq	@f
		addq.l	#8,sp			;スキップ中
		bra	get_token_d_deco_loop
@@:
		btst	#V_AT,d6
		bne	get_token_d_usr_skip
		btst	#V_PER,d6
		bne	get_token_d_sys_skip

* マクロ引数
*get_token_d_macro:
		cmpi.b	#'9',(a2)
		bhi	get_token_d_mac_skip
		lea	(a2),a0
		cmpi.b	#'0',(a0)
		bhi	@f
		bcs	get_token_d_mac_skip
		moveq	#0,d0
		addq.l	#1,a0
		bra	get_token_d_mac2
@@:
		jsr	(atoi_a0)
		bne	get_token_d_mac_skip
get_token_d_mac2:
		tst.b	(a0)
		bne	get_token_d_mac_skip

		move.l	d0,d1			;引数番号(0～)
		move.l	(Q_macro,a5),d0
		beq	get_token_d_mac_skip	;マクロ展開中ではない

		move.l	(Q_macro,a5),-(sp)
		move.l	a1,-(sp)
		movea.l	d0,a1
		bra	1f
@@:
		bsr	get_char
		cmpi.b	#TERM,d0
		bne	@b
		cmp.b	(a1),d0
		beq	get_token_d_mac9	;引数番号が大きすぎる
1:		subq.l	#1,d1
		bcc	@b

		bsr	get_prev_macro
		move.l	d0,(Q_macro,a5)
		move.l	a2,d1
		bra	1f
@@:
		add.l	d0,d4
1:		bsr	get_token2
		bgt	@b
		bmi	get_token_overflow

		BACK	#1
		tst.l	d4
		beq	@f
		subq.l	#1,d4
@@:
		movea.l	(sp)+,a1
		move.l	(sp)+,(Q_macro,a5)

		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
		move.l	d1,-(sp)		;修飾用に保存

		bra	get_token_d_found2
get_token_d_mac9:
		movea.l	(sp)+,a1
		move.l	(sp)+,(Q_macro,a5)
get_token_d_mac_skip:

* システム予約変数

* $ARG $MATCH をテーブルで処理すると $?ARG $?MATCH
* が常に 1 になってしまうので、先に調べてユーザ変数
* の処理に飛ばす
		lea	(a2),a0
		cmpi.b	#'A',(a0)+
		bne	@f
	.irpc	c,RG
		cmpi.b	#'&c',(a0)+
		bne	9f
	.endm
		tst.b	(a0)
		bne	9f
		moveq	#'_',d0			;$ARG は $_ に置換する
		bra	8f
@@:
		cmpi.b	#'M',(a2)
		bne	9f
	.irpc	c,ATCH
		cmpi.b	#'&c',(a0)+
		bne	9f
	.endm
		tst.b	(a0)
		bne	9f
		moveq	#'&',d0			;$MATCH は $& に置換する
8:		move.b	d0,(a2)
		clr.b	(1,a2)
		bra	get_token_d_sys_res_skip
9:

* システム予約変数をテーブルから検索する
		moveq	#$01,d1
		moveq	#0,d3
		lea	(sys_res_val_tbl,pc),a4
1:
		cmp.b	(a4,d2.l),d1
		bcs	9f			;変数名の長さが違う
		lea	(a2),a0
		lea	(a4),a3
2:
		move.b	(a0)+,d0
		beq	get_token_d_sys_res_found
		cmp.b	(a3)+,d0
		beq	2b
9:
		cmp.b	(a4)+,d1		;テーブルの変数名を飛ばす
		bcs	9b
		beq	1b			;次の別名
		addq	#2,d3
		tst.b	(a4)
		bne	1b			;次の変数
		bra	get_token_d_sys_res_skip
get_token_d_sys_res_found:
		btst	#V_Q,d6
		bne	get_token_d_q_found

		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
		move.l	a2,-(sp)		;修飾用に保存

* 展開ルーチンを呼び出す
		lea	(sys_res_val_adr,pc),a0
		adda	d3,a0
		adda	(a0),a0
		jsr	(a0)
		bra	get_token_d_found2
get_token_d_sys_res_skip:

* ユーザ変数
		exg	a1,a2
		jsr	(search_user_value_a1)
		exg	a1,a2
		beq	get_token_d_usr_skip

		btst	#V_Q,d6
		bne	get_token_d_q_found

		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
		move.l	a2,-(sp)		;修飾用に保存

		movea.l	d0,a1
		moveq	#$01,d0
@@:		cmp.b	(a1)+,d0
		bne	@b
		bsr	put_a1_esc
		bra	get_token_d_found
get_token_d_usr_skip:

* システム変数
		btst	#V_PER,d6
		bne	get_token_d_sys_skip

		exg	a1,a2
		jsr	(search_system_value)
		exg	a1,a2
		beq	get_token_d_sys_skip

		btst	#V_Q,d6
		bne	get_token_d_q_found

		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
		move.l	a2,-(sp)		;修飾用に保存

		movea.l	d0,a1
		moveq	#0,d0
		move	(a1),d0
		bsr	ltos_d0
		bra	get_token_d_found2
get_token_d_sys_skip:

* 環境変数
		btst	#V_AT,d6
		bne	get_token_d_not_found

		lea	(tmp_buf),a3
		pea	(a3)
		clr.l	-(sp)
		pea	(a2)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	get_token_d_not_found

		btst	#V_Q,d6
		bne	get_token_d_q_found

		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
		move.l	a2,-(sp)		;修飾用に保存

		exg	a1,a3
		bsr	put_a1_esc
		exg	a1,a3
		bra	get_token_d_found

get_token_d_not_found:
		btst	#V_Q,d6
		bne	get_token_d_q_not_found

		btst	#V_BRACE,d6
		beq	get_token_d_9		;$foo なら、"$foo" をそのまま通す

		lea	(str_nul,pc),a3		;${foo} なら、"NUL" に展開する
		bra	@f
get_token_d_q_not_found:
		lea	(str_0,pc),a3
		bra	@f
get_token_d_q_found:
		lea	(str_1,pc),a3
@@:
		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
		move.l	a2,-(sp)		;修飾用に保存

		exg	a1,a3
		bsr	put_a1
		exg	a1,a3
		bra	get_token_d_found2	;分割不要

get_token_d_found:
**		tst.l	d4
**		bne	get_token_d_found2	;分割済み

* 展開した引数を分割する
		movea.l	(sp),a3			;展開したアドレス
		moveq	#SPACE,d1
		bra	@f
get_token_d_split:
		clr.b	(-1,a3)			;空白で分割する
		addq.l	#1,d4
@@:
		move.b	(a3)+,d0
		beq	get_token_d_found2
		cmp.b	d1,d0
		beq	get_token_d_split
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		tst.b	(a3)+			;２バイト文字
		bne	@b
		BACK	#2
		PUT	<clr.b (a2)+>
get_token_d_found2:
		movea.l	(sp)+,a3		;展開したアドレス

* 修飾
get_token_d_decorate:
		movea.l	(sp)+,a1
		move.l	(sp)+,(Q_macro,a5)
get_token_d_deco_loop:
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃

		bsr	get_char
		cmpi.b	#'}',d0
		beq	get_token_d_brace
		cmpi.b	#':',d0
		bne	get_token_d_8		;修飾なし
		bsr	get_modify_type
		beq	get_token_d_8

		tst.b	(Q_skip,a5)
		bne	get_token_d_deco_skip	;スキップ中

		tst.l	d7
		beq	get_token_overflow
		clr.b	(a2)

		move.l	a3,-(sp)
		movea.l	d0,a0
		jsr	(a0)			;修飾ルーチンを呼び出す
		movea.l	(sp)+,a3
get_token_d_deco_skip:
		addq.l	#8,sp
		bra	get_token_d_deco_loop

get_token_d_brace:
		btst	#V_BRACE,d6
		beq	get_token_d_8

		addq.l	#8,sp
		move.l	(Q_macro,a5),-(sp)	;次の収得位置
		move.l	a1,-(sp)		;〃
get_token_d_8:
**		tst.b	(Q_skip,a5)
**		bne	get_token_d_89		;スキップ中(d4=0 なので不要)
		tst.l	d4
		beq	get_token_d_89
		btst	#T_D_QUOTE,d6
		beq	get_token_d_88		;"～" 外なら複数のトークンとして返す

		moveq	#SPACE,d1		;分割しておいた引数を元に戻す
@@:
		tst.b	(a3)+
		bne	@b
		move.b	d1,(-1,a3)
		subq.l	#1,d4
		bne	@b
**		moveq	#0,d4
get_token_d_88:
		add.l	d4,d5
get_token_d_89:
		movea.l	(sp)+,a1
		move.l	(sp)+,(Q_macro,a5)
		bra	get_token_loop

get_token_d_9:
		movea.l	(sp)+,a1
		move.l	(sp)+,(Q_macro,a5)
		moveq	#'$',d0
		bra	get_token_char1


* 変数修飾 ------------------------------------ *

* 修飾の種類を得る
* in	a1.l	修飾操作記号のアドレス
* out	a1.l	+=1 (:al、:au の場合は += 2)
*	d0.l	修飾処理ルーチンのアドレス(NULL ならエラー)
*	ccr	<tst.l d0> の結果
* 備考:
*	修飾操作記号が正しく記述されていなかった場合、
*	a1.l の値は不定となる.

get_modify_type::
		PUSH	a2-a3
		bsr	get_char
		cmpi.b	#'a',d0
		bne	@f
		bsr	get_char
		andi.b	#$df,d0
@@:
		lea	(modify_tbl,pc),a2
		lea	(modify_adr,pc),a3
@@:
		cmp.b	(a2)+,d0
		beq	@f
		addq.l	#2,a3
		tst.b	(a2)
		bne	@b
		moveq	#0,d0
		bra	get_modify_type_end
@@:
		adda	(a3),a3
		move.l	a3,d0
get_modify_type_end:
		POP	a2-a3
		rts

* 修飾ルーチン
* in	d4.l	変数内項目数-1
*	d7.l	バッファ残りバイト数
*	a2.l	次の書き込みポインタ
*	a3.l	展開した文字列のアドレス
* break	d0-d3/a3-a4

* :al = 全小文字化
modify_al:
		moveq	#'A',d1
		moveq	#'Z',d2
		bra	modify_alu

* :au = 全大文字化
modify_au:
		moveq	#'a',d1
		moveq	#'z',d2
modify_alu:
		move.l	d4,d3
modify_alu_loop:
		bsr	skip_tc_a3
		cmp.b	(a3),d1
		bhi	@f
		cmp.b	(a3),d2
		bcs	@f
		eori.b	#$20,(a3)		;大文字 <-> 小文字
@@:
		move.b	(a3)+,d0
		beq	modify_alu_nul
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	modify_alu_loop
		tst.b	(a3)+			;２バイト文字
		bne	modify_alu_loop
modify_alu_nul:
		subq.l	#1,d3
		bcc	modify_alu_loop
		rts


* 特殊コードを飛ばす
skip_tc_a3_e:
		addq.l	#1,a3
		tst.b	(a3)
		beq	skip_tc_a3_end
skip_tc_a3_f:
		addq.l	#1,a3
skip_tc_a3:
		cmpi.b	#TC_FILE,(a3)
		beq	skip_tc_a3_f
		cmpi.b	#TC_ESC,(a3)
		beq	skip_tc_a3_e
skip_tc_a3_end:
		rts


* :l = 小文字化
modify_l:
		moveq	#'A',d1
		moveq	#'Z',d2
		bra	modify_lu

* :u = 大文字化
modify_u:
		moveq	#'a',d1
		moveq	#'z',d2
modify_lu:
		move.l	d4,d3
modify_lu_loop:
		cmpi.b	#TC_FILE,(a3)+		;先頭の TC_FILE を飛ばす
		beq	modify_lu_loop
		subq.l	#1,a3
		cmp.b	(a3),d1
		bhi	@f
		cmp.b	(a3),d2
		bcs	@f
		eori.b	#$20,(a3)		;大文字 <-> 小文字
@@:
		move.b	(a3)+,d0
		beq	modify_lu_nul
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		tst.b	(a3)+			;２バイト文字
		bne	@b
modify_lu_nul:
		subq.l	#1,d3
		bcc	modify_lu_loop
		rts


* :e = 拡張子抽出
modify_e:
		move.l	a2,d0
		sub.l	a3,d0
		BACK	d0			;書き込みポインタをバッファ先頭に戻す

		move.l	d4,d3
modify_e_loop:
		bsr	search_ext
		tst.b	(a3)+			;'.' を飛ばす
		bne	@f
		move.b	-(a3),d0		;TC_FILE は不要
@@:
		bsr	put_a3_tc
		beq	@f
		bsr	put_tc_file
@@:		PUT	<clr.b  (a2)+>

		subq.l	#1,d3
		bcc	modify_e_loop
		BACK	#1
		rts


* :r = 拡張子削除
modify_r:
		move.l	a2,d0
		sub.l	a3,d0
		BACK	d0			;書き込みポインタをバッファ先頭に戻す

		move.l	d4,d3
modify_r_loop:
		lea	(a3),a4
		bsr	search_ext
		exg	a3,a4
		move.b	(a4),-(sp)
		clr.b	(a4)			;'.' を NUL に書き換える

		moveq	#0,d0
		bsr	put_a3_tc

		move.b	(sp)+,-(a3)		;'.' を元に戻す
@@:		tst.b	(a3)+			;拡張子を飛ばす
		bne	@b

		tst.b	d0
		beq	@f
		bsr	put_tc_file
@@:
		PUT	<clr.b  (a2)+>

		subq.l	#1,d3
		bcc	modify_r_loop
		BACK	#1
		rts


* :d = ドライブ名抽出
modify_d:
		move.l	a2,d0
		sub.l	a3,d0
		BACK	d0			;書き込みポインタをバッファ先頭に戻す

		move.l	d4,d3
modify_d_loop:
		PUSH	d7/a2
		moveq	#0,d0
		bsr	trans_tc_file_a3
		moveq	#$df,d1
		and.b	(a3),d1
		cmpi.b	#'A',d1
		bcs	modify_d_fail		;ドライブ名の記述がなかった
		cmpi.b	#'Z',d1
		bhi	modify_d_fail		;〃
		PUT	<move.b  (a3)+,(a2)+>
		bsr	trans_tc_file_a3
		cmpi.b	#':',(a3)
		bne	modify_d_fail		;〃

		addq.l	#.sizeof.(d7/a2),sp
**		PUT	<move.b  (a3)+,(a2)+>	;':' は不要
		bra	@f
modify_d_fail:
		POP	d7/a2
		moveq	#0,d0
@@:
		tst.b	(a3)+			;残りの部分を飛ばす
		bne	@b

		tst.b	d0
		beq	@f
		bsr	put_tc_file
@@:
		PUT	<clr.b  (a2)+>
		subq.l	#1,d3
		bcc	modify_d_loop
		BACK	#1
		rts


* 文字列先頭の TC_FILE を転送する
* in	a3.l	文字列
*	d0.b	現在のモード
* out	d0.b	モード(TC_FILE or 0)

@@:
		eori.b	#TC_FILE,d0
		PUT	<move.b  (a3)+,(a2)+>
trans_tc_file_a3:
		cmpi.b	#TC_FILE,(a3)
		beq	@b
		rts


* :t = ファイル名抽出
modify_t:
		move.l	a2,d0
		sub.l	a3,d0
		BACK	d0			;書き込みポインタをバッファ先頭に戻す

		move.l	d4,d3
modify_t_loop:
		bsr	search_last_sep
		moveq	#TC_FILE,d1
		bra	1f
@@:
		addq.l	#1,a3
1:		cmpi.b	#'/',(a3)		;パスデリミタを飛ばす
		beq	@b
		cmpi.b	#'\',(a3)
		beq	@b
		cmp.b	(a3),d1
		bne	@f
		eor.b	d1,d0			;TC_FILE
		bra	@b
@@:
		tst.b	(a3)
		bne	@f
		moveq	#0,d0			;TC_FILE は不要
@@:
		bsr	put_a3_tc
		beq	@f
		bsr	put_tc_file
@@:		PUT	<clr.b  (a2)+>

		subq.l	#1,d3
		bcc	modify_t_loop
		BACK	#1
		rts


* :h = ファイル名削除
modify_h:
		move.l	a2,d0
		sub.l	a3,d0
		BACK	d0			;書き込みポインタをバッファ先頭に戻す

		move.l	d4,d3
modify_h_loop:
		lea	(a3),a4
		bsr	search_last_sep
		exg	a3,a4
		move.b	(a4),-(sp)
		clr.b	(a4)			;パスデリミタを NUL に書き換える

		moveq	#0,d0
		bsr	put_a3_tc

		move.b	(sp)+,-(a3)		;パスデリミタを元に戻す
@@:		tst.b	(a3)+			;ファイル名を飛ばす
		bne	@b

		tst.b	d0
		beq	@f
		bsr	put_tc_file
@@:
		PUT	<clr.b  (a2)+>

		subq.l	#1,d3
		bcc	modify_h_loop
		BACK	#1
		rts


		.offset	0
~mod_s_a1:	.ds.l	1
~mod_s_mac:	.ds.l	1
~mod_s_top:	.ds.l	1
~mod_s_from:	.ds.l	1
~mod_s_to:	.ds.l	1
~mod_s_new:	.ds.l	1
~mod_s_d7:	.ds.l	1
~mod_s_a2:	.ds.l	1
sizeof_mod_s:
		.text

* :s/from/to/[g] = 文字列置換
modify_s:
		lea	(-sizeof_mod_s,sp),sp
		move.l	(Q_macro,a5),(~mod_s_mac,sp)
		move.l	a1,(~mod_s_a1,sp)
		move.l	a3,(~mod_s_top,sp)
		movem.l	d7/a2,(~mod_s_d7,sp)

		PUT	<clr.b  (a2)+>
		moveq	#$20,d2

		bsr	get_char2
		beq	modify_s9
		move	d0,d1			;区切り記号

* 置換元文字列の収得
		move.l	a2,(~mod_s_from,sp)
		bsr	get_char2
		beq	modify_s9
modify_s_from_loop:
		cmp	d2,d0
		bne	@f
		bset	#31,d2			;from に空白が含まれる
@@:		bsr	put_char2
		bsr	get_char2
		beq	modify_s9
		cmp	d0,d1
		bne	modify_s_from_loop
		PUT	<clr.b  (a2)+>

* 置換先文字列の収得
		move.l	(Q_macro,a5),(~mod_s_mac,sp)
		move.l	a1,(~mod_s_a1,sp)	;この時点で実行確定
		move.l	a2,(~mod_s_to,sp)
		bra	@f
modify_s_to_loop:
		bsr	put_char2
@@:		bsr	get_char2
		cmp	d2,d0
		bls	@f
		cmpi	#':',d0
		beq	@f
		move.l	(Q_macro,a5),(~mod_s_mac,sp)
		move.l	a1,(~mod_s_a1,sp)
		cmp	d0,d1
		bne	modify_s_to_loop
		bsr	get_char
		cmpi.b	#'g',d0
		bne	@f
		move.l	(Q_macro,a5),(~mod_s_mac,sp)
		move.l	a1,(~mod_s_a1,sp)	;s/from/to/g
		bset	#30,d2
@@:		PUT	<clr.b  (a2)+>

		swap	d2			;bit16=1:spc bit15=1:g
		add	d2,d2
		bcc	modify_s_no_space
		tst.l	d4
		beq	modify_s_no_space
		move.l	a3,-(sp)
		moveq	#SPACE,d1
@@:
		tst.b	(a3)+
		bne	@b
		move.b	d1,-(a3)
		subq.l	#1,d4
		bne	@b
		movea.l	(sp)+,a3
modify_s_no_space:
		move.l	a2,(~mod_s_new,sp)

		move.l	d4,d3
modify_s_cmp_loop2:
		clr.b	d2
modify_s_cmp_loop:
		tst.b	d2
		bne	modify_s_skip		;置換済み(g なし)

		move.l	a3,d1
		movea.l	(~mod_s_from,sp),a4
@@:
		tst.b	(a4)
		beq	modify_s_match		;from が一致した
1:
		move.b	(a3)+,d0
		cmpi.b	#TC_FILE,d0
		beq	1b			;TC_FILE は無視する
		cmpi.b	#TC_ESC,d0
		bne	1f
		move.b	(a3)+,d0		;次の文字を取り出す
1:
		cmp.b	(a4)+,d0		;１バイト比較
		bne	modify_s_miss
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		cmpm.b	(a3)+,(a4)+		;下位バイトを比較
		beq	@b
modify_s_miss:
		movea.l	d1,a3			;不一致
modify_s_skip:
1:		move.b	(a3)+,d0
		cmpi.b	#TC_FILE,d0
		beq	1b			;TC_FILE は無視する
		cmpi.b	#TC_ESC,d0
		bne	1f
		PUT	<move.b  d0,(a2)+>
		move.b	(a3)+,d0		;次の文字を取り出す
1:
		PUT	<move.b  d0,(a2)+>	;１バイト転送
		beq	modify_s_nul
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	modify_s_cmp_loop
		PUT	<move.b  (a3)+,(a2)+>	;下位バイトを転送
		bra	modify_s_cmp_loop
modify_s_match:
		move.l	(~mod_s_to,sp),a1
		bsr	put_a1
		tst	d2
		spl	d2			;g なしなら以後は置換しない
		bra	modify_s_cmp_loop
modify_s_nul:
		subq.l	#1,d3
		bcc	modify_s_cmp_loop2

		move.l	a2,d0
		sub.l	(~mod_s_top,sp),d0
		BACK	d0			;書き込みポインタをバッファ先頭に戻す

		movea.l	(~mod_s_new,sp),a3
		move.l	d4,d3
modify_s_trans_loop:
		PUT	<move.b  (a3)+,(a2)+>
		bne	modify_s_trans_loop
		subq.l	#1,d3
		bcc	modify_s_trans_loop

		BACK	#1
		movem.l	d7/a2,(~mod_s_d7,sp)
modify_s9:
		move.l	(~mod_s_mac,sp),(Q_macro,a5)
		movea.l	(~mod_s_a1,sp),a1
		movem.l	(~mod_s_d7,sp),d7/a2
		lea	(sizeof_mod_s,sp),sp
		rts


* 文字書き込み(２バイト文字対応版)
put_char2:
		tst	d0
		bpl	@f
		move	d0,-(sp)
		PUT	<move.b  (sp)+,(a2)+>
@@:		PUT	<move.b  d0,(a2)+>
		rts


* 文字収得(２バイト文字対応版)
get_char2:
		moveq	#0,d0
		move.l	a1,-(sp)
		bsr	get_char
		beq	get_char2_error
		move	d0,-(sp)
		lsr.b	#5,d0
		btst	d0,#%10010000
		bne	@f
		move	(sp)+,d0
		bra	get_char2_end
@@:
		move.l	a1,(2,sp)
		move.b	(a1)+,d0
		beq	get_char2_error2
		move.b	d0,(sp)
		move	(sp)+,d0
		ror	#8,d0
get_char2_end:
		addq.l	#4,sp
		rts
get_char2_error2:
		clr	(sp)+
get_char2_error:
		movea.l	(sp)+,a1
		rts


* 修飾下請け ---------------------------------- *


* 拡張子検索
* in	a3.l	ファイル名
* out	a3.l	'.' のアドレス
*		(拡張子がない場合は NUL のアドレスを返す)
*	d0.b	モード(TC_FILE または 0)

search_ext:
		move.l	d1,-(sp)
		moveq	#0,d1
		move.b	d1,-(sp)
		clr.l	-(sp)
search_ext_loop1:
		move.b	(a3)+,d0
		cmpi.b	#'.',d0
		beq	search_ext_loop2	;先頭の '.' は無視する
		subq.l	#1,a3
		cmpi.b	#TC_FILE,d0
		beq	@f
		subi.b	#TC_ESC,d0
		bne	search_ext_loop2
		addq.l	#1,a3			;次の文字を飛ばす
@@:		addq.l	#1,a3
		eor.b	d0,d1
		bra	search_ext_loop1
search_ext_found:
		addq.l	#2+4,sp
		move.b	d1,-(sp)
		move.l	a3,-(sp)
search_ext_loop2:
		move.b	(a3)+,d0
		beq	search_ext_nul
		cmpi.b	#'.',d0
		beq	search_ext_found
		cmpi.b	#TC_FILE,d0
		bne	@f
		eor.b	d0,d1
		bra	search_ext_loop2
@@:
		cmpi.b	#TC_ESC,d0
		beq	@f			;次の文字を飛ばす
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	search_ext_loop2
@@:		tst.b	(a3)+			;２バイト文字
		bne	search_ext_loop2
search_ext_nul:
		move.l	(sp)+,d0
		beq	@f
		movea.l	d0,a3
@@:		subq.l	#1,a3
		move.b	(sp)+,d0

		move.l	(sp)+,d1
		rts


* 最後のパスデリミタ検索
* in	a3.l	ファイル名
* out	a3.l	最後のパスデリミタのアドレス
*	d0.b	モード(TC_FILE または 0)

search_last_sep:
		PUSH	d1-d3
		moveq	#0,d1
		moveq	#%10,d2			;ドライブ名検出用フラグ
		moveq	#TC_FILE,d3
		move.b	d1,-(sp)
		move.l	a3,-(sp)
		bra	search_l_s_loop
search_l_s_found:
		subq.l	#1,a3
		addq.l	#2+4,sp
		move.b	d1,-(sp)
		move.l	a3,-(sp)
		moveq	#0,d2
@@:
		addq.l	#1,a3
		cmpi.b	#'/',(a3)		;連続するパスデリミタを飛ばす
		beq	@b
		cmpi.b	#'\',(a3)
		beq	@b
		cmp.b	(a3),d3
		bne	search_l_s_loop
		eor.b	d3,d1			;TC_FILE
		bra	@b
search_l_s_drive:
		addq.l	#2+4,sp
		move.b	d1,-(sp)
		move.l	a3,-(sp)
search_l_s_loop:
		move.b	(a3)+,d0
		beq	search_l_s_nul
		cmpi.b	#'/',d0
		beq	search_l_s_found
		cmpi.b	#'\',d0
		beq	search_l_s_found
		cmpi.b	#':',d0
		bne	@f
		lsr	#1,d2
		bcs	search_l_s_drive
@@:
		cmp.b	d3,d0
		bne	@f
		eor.b	d3,d1			;TC_FILE
		bra	search_l_s_loop
@@:
		cmpi.b	#TC_ESC,d0
		beq	@f			;次の文字を飛ばす
		lsr	#1,d2
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	search_l_s_loop
@@:		moveq	#0,d2
		tst.b	(a3)+			;２バイト文字
		bne	search_l_s_loop
search_l_s_nul:
		movea.l	(sp)+,a3
		move.b	(sp)+,d0

		POP	d1-d3
		rts


* 文字列をバッファに書き込む
* in	a3.l	文字列
*	d0.b	現在のモード
* out	d0.b	モード(TC_FILE or 0)
*	ccr	<tst.b d0> の結果

put_a3_tc:
		move.b	d0,-(sp)
		beq	put_a3_tc_loop
		bsr	put_tc_file
put_a3_tc_loop:
		move.b	(a3)+,d0
		cmpi.b	#TC_FILE,d0
		bne	1f
		eor.b	d0,(sp)
		bra	2f
1:		cmpi.b	#TC_ESC,d0
		bne	2f
		PUT	<move.b  d0,(a2)+>
		move.b	(a3)+,d0
2:		PUT	<move.b  d0,(a2)+>
		beq	put_a3_tc_end
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	put_a3_tc_loop
		PUT	<move.b  (a3)+,(a2)+>
		bra	put_a3_tc_loop
put_a3_tc_end:
		BACK	#1
		move.b	(sp)+,d0
		rts


* システム変数展開 ---------------------------- *

* カーソル側パス名
*	$C $CURRENT $PWD
sys_res_c:
		bset	#MA_REQ_PATH,(Q_ma_req_cur,a5)

		bsr	put_tc_file
		bsr	put_path
		BACK	#1			;末尾のパスデリミタを削除
		bra	put_tc_file
**		rts


* カーソル位置ファイル名
*	$F $FILE
sys_res_f:
		tst.b	(Q_mintarc,a5)
		bne	sys_res_f_mintarc
		move.l	(Q_ext_exec,a5),d0
		bne	sys_res_f_extexec
sys_res_f2:
		bsr	put_tc_file
sys_res_f3:
		bset	#MA_REQ_FILE,(Q_ma_req_cur,a5)

		moveq	#FILENAME_MAX+1,d0
		CHK	d0
		jsr	(search_cursor_file)
		lea	(DIR_NAME,a4),a1
		jsr	(copy_dir_name_a1_a2)
		PASS
		bra	put_tc_file
**		rts


* mintarc での $P、$F は書庫ファイル名(フルパス)を展開する
sys_res_f_mintarc:
		jsr	(get_mintarc_filename)

* &ext-exec での $P、$F はファイル名を展開する
sys_res_f_extexec:
		movea.l	d0,a1
		bsr	put_tc_file
		bsr	put_a1
		bra	put_tc_file
**		rts


* カーソル位置ファイル名(フルパス)
*	$P $PFILE
sys_res_p:
		tst.b	(Q_mintarc,a5)
		bne	sys_res_f_mintarc
		move.l	(Q_ext_exec,a5),d0
		bne	sys_res_f_extexec

		bsr	put_tc_file
		bsr	put_path
		bra	sys_res_f3
**		rts


* カーソル側マークファイル名
*	$M $MARK
sys_res_m:
		moveq	#0,d3			;マーク解除なし、パスなし
		bra	sys_res_mark

* マークファイル名展開
* in	d3.hb	$ff=マーク解除
*	d3.b	$ff=フルパス
*	d4.l	変数内項目数-1
* out	d4.l	〃

sys_res_mark:
		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		beq	sys_res_mark2
		tst.b	d3			;マークなし
		beq	sys_res_f
		bra	sys_res_p
sys_res_mark2:
		bset	#MA_REQ_MARK,(Q_ma_req_cur,a5)
		tst	d3
		bpl	@f			;マーク解除時はあとで再描画する
		bset	#MA_REQ_REDRAW,(Q_ma_req_cur,a5)
@@:
		bra	sys_res_mark_start
sys_res_mark_next:
		addq.l	#1,d4
		PUT	<clr.b  (a2)+>
sys_res_mark_start:
		bsr	put_tc_file
		tst.b	d3
		beq	sys_res_mark_no_path

		bsr	put_path		;パス名を付ける
sys_res_mark_no_path:
		tst	d3
		bpl	@f
		bclr	#MARK,(DIR_ATR,a4)	;マークを解除する
@@:
		moveq	#FILENAME_MAX+1,d0
		CHK	d0
		lea	(DIR_NAME,a4),a1
		jsr	(copy_dir_name_a1_a2)
		PASS
		bsr	put_tc_file

		lea	(sizeof_DIR,a4),a4
		jsr	(search_mark_file)
		beq	sys_res_mark_next

		rts


* カーソル側マークファイル名(フルパス)
*	$PM $PMARK
sys_res_pm:
		moveq	#1,d3			;マーク解除なし、フルパス
		bra	sys_res_mark


* カーソル側マークファイル名(マーク解除)
*	$MARK_R
sys_res_m_r:
		moveq	#$80,d3			;マーク解除あり、パスなし
		add.b	d3,d3
		bra	sys_res_mark


* カーソル側マークファイル名(フルパス、マーク解除)
*	$PMARK_R
sys_res_pm_r:
		moveq	#-1,d3			;マーク解除あり、フルパス
		bra	sys_res_mark


* カーソル側マーク数
*	$# $MARK_COUNT
sys_res_m_c:
		bsr	get_mark_count
		bra	ltos_d0
**		rts


* カーソル側カーソル位置(行番号)
*	$CURSOR
sys_res_csr:
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		move.l	d2,d0
		add	(PATH_PAGETOP,a6),d0
		addq	#1,d0
		bra	ltos_d0
**		rts


* カーソル側ファイル数
*	$ENTRIES
sys_res_ent:
		moveq	#0,d0
		move	(PATH_FILENUM,a6),d0
		bra	ltos_d0
**		rts


* 反対側パス名
*	$O $OPPOSITE
sys_res_o:
		lea	(sys_res_c,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側カーソル位置ファイル名
*	$OF $OFILE
sys_res_of:
		lea	(sys_res_f,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側カーソル位置ファイル名(フルパス)
*	$OP $OPFILE
sys_res_op:
		lea	(sys_res_p,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側マークファイル名
*	$OM $OMARK
sys_res_om:
		lea	(sys_res_m,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側マークファイル名(フルパス)
*	$OPM $OPMARK
sys_res_opm:
		lea	(sys_res_pm,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側マークファイル名(マーク解除)
*	$OMARK_R
sys_res_om_r:
		lea	(sys_res_m_r,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側マークファイル名(フルパス、マーク解除)
*	$OPMARK_R
sys_res_opm_r:
		lea	(sys_res_pm_r,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側マーク数
*	$O# $OMARK_COUNT
sys_res_om_c:
		lea	(sys_res_m_c,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側カーソル位置(行番号)
*	$OCURSOR
sys_res_ocsr:
		lea	(sys_res_csr,pc),a0
		bra	call_sys_res_opp
**		rts


* 反対側ファイル数
*	$OENTRIES
sys_res_oent:
		lea	(sys_res_ent,pc),a0
		bra	call_sys_res_opp
**		rts


* 両ウィンドウマークファイル名
*	$B $BMARK $BOTH_SIDE_MARKS
sys_res_b:
		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		beq	@f

		movea.l	(PATH_OPP,a6),a4
		movea.l	(PATH_BUF,a4),a4
		jsr	(search_mark_file)
		bne	sys_res_f2		;無/無 = $F
		bra	sys_res_opm		;無/有 = $OPM
@@:
		moveq	#0,d3			;マーク解除なし、パスなし
		bsr	sys_res_mark2

		movea.l	(PATH_OPP,a6),a4
		movea.l	(PATH_BUF,a4),a4
		jsr	(search_mark_file)
		bne	sys_res_b_end		;有/無 = $M

		addq.l	#1,d4
		PUT	<clr.b  (a2)+>		;有/有 = $M $OPM
		bra	sys_res_opm
sys_res_b_end:
		rts


* 行編集
*	$< $READLINE
sys_res_rl:
		move.l	a2,(Q_rl_ptr,a5)
		rts


* ステータス値
*	$STATUS
sys_res_status:
		moveq	#0,d0
		move	(＠status,pc),d0
		bra	ltos_d0
**		rts


* 前回カレントパス名
*	$OLDPWD
sys_res_oldpwd:
		bsr	put_tc_file
		lea	(oldpwd_buf),a1
		bsr	put_a1
		bra	put_tc_file
**		rts


* カーソル左右位置
*	$SIDE
sys_res_side:
		lea	(str_left,pc),a1
		tst	(PATH_WINRL,a6)
		beq	@f
		addq.l	#str_right-str_left,a1
@@:		bra	put_a1
**		rts


* MPU の種類
*	$MPUTYPE
sys_res_mpu:
		moveq	#0,d0
		move.b	(MpuType),d0
		bra	ltos_d0
**		rts


* 定義ファイル
*	$MINTRC
sys_res_mintrc:
		bsr	put_tc_file
		lea	(mintrc_filename),a1
		bsr	put_a1
		bra	put_tc_file
**		rts


* 書庫ファイル名＋操作対象ファイル名
*	$MINTARC
sys_res_mintarc:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	sys_res_mintarc_end

		bsr	put_tc_file
		jsr	(get_mintarc_filename)
		movea.l	d0,a1
		bsr	put_a1
		bsr	put_tc_file

		movea.l	(ma_list_adr),a1
		move.l	(ma_list_num),d3
		bra	sys_res_mintarc_next
sys_res_mintarc_loop:
		addq.l	#1,d4
		PUT	<clr.b  (a2)+>
@@:
		bsr	put_tc_file
		addq.l	#1,a1			;フラグを飛ばす
		bsr	put_a1
		bsr	put_tc_file
sys_res_mintarc_next:
		subq.l	#1,d3
		bcc	sys_res_mintarc_loop
sys_res_mintarc_end:
		rts


* 左側書庫ファイル名
*	$MARC_LEFT
sys_res_mark_l:
		moveq	#WIN_LEFT,d0
		bra.s	@f


* 右側書庫ファイル名
*	$MARC_RIGHT
sys_res_mark_r:
		moveq	#WIN_RIGHT,d0
@@:		cmp	(PATH_WINRL,a6),d0
		bne	sys_res_marc_o
		bra	sys_res_marc

* カーソル側書庫ファイル名
*	$MARC
sys_res_marc:
		move.l	a6,-(sp)
		bra.s	@f

* 反対側書庫ファイル名
*	$MARC_OPPOSITE
sys_res_marc_o:
		move.l	a6,-(sp)
		movea.l	(PATH_OPP,a6),a6
@@:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	sys_res_marc_end

		bsr	put_tc_file
		jsr	(get_mintarc_filename)
		movea.l	d0,a1
		bsr	put_a1
		bsr	put_tc_file
sys_res_marc_end:
		movea.l	(sp)+,a6
		rts


* グラフィック画面モード
*	$GVON
sys_res_gvon:
		lea	(VC_R2),a1
		IOCS	_B_WPEEK
		cmpi	#T_ON,d1
		beq	sys_res_gvon_off

		move	d0,d1
		lea	(VC_R0-(VC_R2+2),a1),a1
		IOCS	_B_WPEEK
		subq	#3,d0
		beq	sys_res_gvon_64k	;64K 色モード

		cmpi	#64,(GTONE)
		bne	sys_res_gvon_half
sys_res_gvon_max:
		lea	(str_max,pc),a1
		bra	@f
sys_res_gvon_64k:
		cmpi	#T_ON+G_HALF_ON,d1
		bne	sys_res_gvon_max
sys_res_gvon_half:
		lea	(str_half,pc),a1
		bra	@f
sys_res_gvon_off:
		lea	(str_off,pc),a1
@@:		bra	put_a1
**		rts


* グラフィック画面正方形モード
*	$SQUARE
sys_res_square:
		moveq	#0,d0
		sub.b	(sq64k),d0		;$00->'0' $ff->'1'
		bra	ltos_d0
**		rts


* &look-file 表示モード
*	$LOOK
sys_res_look:
		moveq	#0,d0
		add	(look_mode),d0
		bra	ltos_d0
**		rts


* &look-file 閲覧ファイル名
*	$LOOK_FILE_NAME
sys_res_look_fn:
		bsr	put_tc_file
		lea	(LOOK_FILE_NAME),a1
		bsr	put_a1
		bra	put_tc_file
**		rts


;現在の年(西暦)をBCD 4桁で取得する
get_year_bcd4:
  IOCS _DATEGET
  swap d0
  ext d0  ;$00_yy
  addi #$2000-$20,d0
  cmpi #$2000,d0
  bcc @f
    addi #$1980-($2000-$20),d0
  @@:
  rts

;$YEAR 西暦(4桁)
sys_res_year:
  bsr get_year_bcd4
  moveq #4-1,d1
  bra sys_res_hex

;$YEAR2 西暦(2桁)
sys_res_year2:
  bsr get_year_bcd4
  bra sys_res_hex2

;$MONTH 月
sys_res_month:
  IOCS _DATEGET
  bra sys_res_hex2hi

;$DAY 日
sys_res_day:
  IOCS _DATEGET
  bra sys_res_hex2

;$HOUR 時
sys_res_hour:
  IOCS _TIMEGET
  swap d0
  bra sys_res_hex2

;$MINUTE 分
sys_res_minute:
  IOCS _TIMEGET
  bra sys_res_hex2hi

;$SECOND 秒
sys_res_second:
  IOCS _TIMEGET
  bra sys_res_hex2

sys_res_hex2:
  rol #8,d0
sys_res_hex2hi:
  moveq #2-1,d1
sys_res_hex:
  lea (tmp_buf),a1
  pea (a1)

  lea (hextable,pc),a0
  @@:
    rol #4,d0
    moveq #$f,d2
    and.b d0,d2
    move.b (a0,d2.w),(a1)+
  dbra d1,@b
  clr.b (a1)

  movea.l (sp)+,a1
  bra put_a1


* 変数展開下請け ------------------------------ *

* TC_FILE マークを書き込む
put_tc_file:
		PUT	<move.b  #TC_FILE,(a2)+>
		clr.b	(a2)
		rts


* パス名をバッファに書き込む
* break	d0/a1

put_path:
		lea	(PATH_DIRNAME,a6),a1
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		jsr	(get_mintarc_dir)
		movea.l	d0,a1
		bsr	put_a1
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a1
@@:
		bra	put_a1
**		rts


* 文字列をバッファに書き込む
* in	a1.l	文字列
* break	d0/a1

put_a1:
		STRLEN	a1,d0
		sub.l	d0,d7
		bls	get_token_overflow	;NUL の分も書き込むので bls
		STRCPY	a1,a2,-1
		rts


* 文字列をバッファに書き込む(エスケープ版)
* in	a1.l	文字列

put_a1_esc:
		PUSH	d0-d1/a1
		moveq	#TC_ESC,d1
put_a1_esc_loop:
		move.b	(a1)+,d0
		beq	put_a1_esc_end
		cmpi.b	#TC_FILE,d0
		beq	1f
		cmp.b	d1,d0
		bne	2f
1:		PUT	<move.b  d1,(a2)+>
2:		PUT	<move.b  d0,(a2)+>
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	put_a1_esc_loop
		move.b	(a1)+,d0
		beq	9f
		PUT	<move.b  d0,(a2)+>
		bra	put_a1_esc_loop
9:		BACK	#1
put_a1_esc_end:
		PUT	<clr.b  (a2)+>
		BACK	#1
		POP	d0-d1/a1
		rts


* 数値文字列変換
ltos_d0:
		PUSH	d1/a0
		moveq	#.sizeof.('2147483647')+1,d1
		CHK	d1
		lea	(a2),a0
		FPACK	__LTOS
		PASS
		POP	d1/a0
		rts


* 反対側処理呼び出し
* in	a0.l	変数展開ルーチン

call_sys_res_opp:
		bsr	@f
		jsr	(a0)
@@:
		movea.l	(PATH_OPP,a6),a6
		move	(Q_ma_req_cur,a5),d0
		ror	#8,d0
		move	d0,(Q_ma_req_cur,a5)
		rts


* マーク数算出
get_mark_count:
		PUSH	d1/a4
		moveq	#0,d0
		movea.l	(PATH_BUF,a6),a4
		bra	@f
get_m_c_mark:
		addq.l	#1,d0
get_m_c_next:
		lea	(sizeof_DIR,a4),a4
@@:		move.b	(DIR_ATR,a4),d1
		bpl	get_m_c_next
		not.b	d1
		bne	get_m_c_mark
		POP	d1/a4
		rts


* 変数修飾テーブル ---------------------------- *

**		.data
		.even
modify_adr:
		.dc	modify_al-$
		.dc	modify_au-$
		.dc	modify_l-$
		.dc	modify_u-$
		.dc	modify_e-$
		.dc	modify_r-$
		.dc	modify_d-$
		.dc	modify_t-$
		.dc	modify_h-$
		.dc	modify_s-$
modify_tbl:
		.dc.b	'LUluerdths',0


* システム予約変数テーブル -------------------- *

**		.data
		.even

TABLE_BODY:	.macro

* カーソル側ウィンドウ
		OBJ	sys_res_c,	'C','CURRENT','PWD'
		OBJ	sys_res_f,	'F','FILE'
		OBJ	sys_res_p,	'P','PFILE'
		OBJ	sys_res_m,	'M','MARK'
		OBJ	sys_res_pm,	'PM','PMARK'
		OBJ	sys_res_m_r,	'MARK_R'
		OBJ	sys_res_pm_r,	'PMARK_R'
		OBJ	sys_res_m_c,	'#','MARK_COUNT'
		OBJ	sys_res_csr,	'CURSOR'
		OBJ	sys_res_ent,	'ENTRIES'

* 反対側ウィンドウ
		OBJ	sys_res_o,	'O','OPPOSITE'
		OBJ	sys_res_of,	'OF','OFILE'
		OBJ	sys_res_op,	'OP','OPFILE'
		OBJ	sys_res_om,	'OM','OMARK'
		OBJ	sys_res_opm,	'OPM','OPMARK'
		OBJ	sys_res_om_r,	'OMARK_R'
		OBJ	sys_res_opm_r,	'OPMARK_R'
		OBJ	sys_res_om_c,	'O#','OMARK_COUNT'
		OBJ	sys_res_ocsr,	'OCURSOR'
		OBJ	sys_res_oent,	'OENTRIES'

* その他
		OBJ	sys_res_b,	'B','BMARK','BOTH_SIDE_MARKS'
		OBJ	sys_res_rl,	'<','READLINE'
		OBJ	sys_res_status,	'STATUS'
		OBJ	sys_res_oldpwd,	'OLDPWD'
		OBJ	sys_res_side,	'SIDE'
		OBJ	sys_res_mpu,	'MPUTYPE'
		OBJ	sys_res_mintrc,	'MINTRC'

* mintarc
		OBJ	sys_res_mintarc,'MINTARC'
		OBJ	sys_res_mark_l,	'MARC_LEFT'
		OBJ	sys_res_mark_r,	'MARC_RIGHT'
		OBJ	sys_res_marc,	'MARC'
		OBJ	sys_res_marc_o,	'MARC_OPPOSITE'

* &gvon / &look-file
		OBJ	sys_res_gvon,	'GVON'
		OBJ	sys_res_square,	'SQUARE'
		OBJ	sys_res_look,	'LOOK'
		OBJ	sys_res_look_fn,'LOOK_FILE_NAME'

* 時刻
		OBJ	sys_res_year,	'YEAR'
		OBJ	sys_res_year2,	'YEAR2'
		OBJ	sys_res_month,	'MONTH'
		OBJ	sys_res_day,	'DAY'
		OBJ	sys_res_hour,	'HOUR'
		OBJ	sys_res_minute,	'MINUTE'
		OBJ	sys_res_second,	'SECOND'
		.endm

* 処理アドレステーブル用マクロ
OBJ:		.macro	label,v1,v2,v3
		.dc	label-$
		.endm

sys_res_val_adr:
		TABLE_BODY

* 変数名テーブル用マクロ
OBJ:		.macro	label,v1,v2,v3
		.sizem	sz,cnt
		.dc.b	v1
	.if cnt>=3
		.dc.b	$01,v2
	.if cnt>=4
		.dc.b	$01,v3
	.endif
	.endif
		.dc.b	$00
		.endm

sys_res_val_tbl::
		TABLE_BODY
		.dc.b	0


* Text Section -------------------------------- *

**		.text
		.even


* コマンド実行 -------------------------------- *
* in	d0.l	トークン数
*	d1.l	トークンバッファのサイズ
*	a0.l	トークン列
* 備考:
*	トークン列のメモリは解放される.

execute_command::
		PUSH	d0-d1/d7/a1
		move.l	d0,d7

		clr.b	(Q_if_next,a5)

		move.b	(debug_flag,pc),d0
		beq	@f
		bsr	print_token_list
		jsr	(CursorBlinkOn)
		jsr	(dos_inpout)
		jsr	(CursorBlinkOff)
@@:
		bsr	search_builtin_func
		beq	exe_cmd_file
*exe_cmd_builtin:
		movea.l	d0,a1			;処理アドレス
		move.l	d7,d0
		bsr	execute_builtin		;内部命令実行
		bra	exe_cmd_end
exe_cmd_file:
		tst.b	(Q_sw_a,a5)
		beq	@f			;-a 未指定時はヒストリに登録する
		tst.b	(Q_sw_p,a5)
		bne	exe_cmd_skip_print	;-p 指定時は表示しない
@@:
		pea	(a0)			;トークン列を保存

		move.l	d7,d0
		lea	(str_nulstr,pc),a1
		bsr	hupair_encode
		bmi	exe_cmd_print_error

		move.l	a0,-(sp)		;HUPAIR バッファ(出力したら解放する)
		lea	(HUPAIR_ID_SIZE+1,a0),a1

		tst.b	(Q_sw_p,a5)
		bne	@f
		move.l	d1,-(sp)
		pea	(a1)
		move	#1,-(sp)		;STDOUT
		DOS	_WRITE			;コマンドラインを表示する
		lea	(10,sp),sp
		jsr	(PrintCrlf)
@@:
		tst.b	(Q_sw_a,a5)
		bne	@f
		bsr	make_cmd_sw		;ヒストリに登録する
		jsr	(add_cmd_his)
@@:
		movea.l	(sp)+,a0
		bsr	free_hupair_buffer
exe_cmd_print_error:
		movea.l	(sp)+,a0		;トークン列
exe_cmd_skip_print:
		move.l	d7,d0
		bsr	execute_file		;ファイル実行
exe_cmd_end:
		move.b	(Q_if_next,a5),(Q_if_flag,a5)

		POP	d0-d1/d7/a1
		rts


* トークン列表示(デバッグ用) ------------------ *

print_token_list:
		PUSH	d0/d7/a0
		PR_STR	<"==== token ====",LF>
@@:
		moveq	#0,d0
		move.b	(a0)+,d0
		beq	3f
		cmpi.b	#TC_FILE,d0
		beq	1f
		cmpi.b	#TC_ESC,d0
		beq	2f
		move	d0,-(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp
		bra	@b
1:		PR_STR	'<F>'
		bra	@b
2:		PR_STR	'<E>'
		bra	@b
3:		jsr	(PrintCrlf)

		subq.l	#1,d7
		bne	@b
		POP	d0/d7/a0
		rts


* トークンバッファ解放 ------------------------ *

free_token_buf::
		PUSH	d0/a5
		move.l	(q_ptr,pc),d0
		beq	free_token_buf_end
		movea.l	d0,a5
		move.l	(Q_funcname,a5),-(sp)
		ble	@f
		clr.l	(Q_funcname,a5)
		DOS	_MFREE
@@:		addq.l	#4,sp
free_token_buf_end:
		POP	d0/a5
		rts


* 内部命令実行 -------------------------------- *
* in	d0.l	トークン数
*	a0.l	トークン列
*	a1.l	処理アドレス
* 備考:
*	&cursor-opposite-window などの実行によって
*	a6.l が書き換えられることがある.

execute_builtin::
		PUSH	d0-d7/a0-a5
**		PR_STR	<"==== builtin ====",LF>

		move.l	d0,d7
		move.l	a0,(Q_funcname,a5)
@@:		tst.b	(a0)+			;関数名を飛ばす
		bne	@b

		lea	(a0),a3
		subq.l	#1,d7			;関数名の分を引く
		beq	exe_cmd_b_no_arg

		lea	(＆unless,pc),a2	;&unless &if &else-if は
		cmpa.l	a1,a2			;特殊コードを削除しない
		bhi	@f
		lea	(＆else_if,pc),a2
		cmpa.l	a1,a2
		bcc	exe_cmd_b_thru
@@:
		lea	(a0),a2
exe_cmd_b_loop:
		move.b	(a2)+,d1		;特殊コードを取り除く
		cmpi.b	#TC_FILE,d1
		beq	exe_cmd_b_loop		;無視
		cmpi.b	#TC_ESC,d1
		bne	@f
		move.b	(a2)+,d1		;次の１バイトをそのまま通す
@@:		move.b	d1,(a3)+
		bne	exe_cmd_b_loop
		subq.l	#1,d0
		bne	exe_cmd_b_loop
exe_cmd_b_no_arg:
exe_cmd_b_thru:
		move.l	d7,d0			;引数の数(0～)
		jsr	(a1)			;内部命令呼び出し
		bsr	free_token_buf

		POP	d0-d7/a0-a5
		rts


* 外部コマンド実行 ---------------------------- *
* in	d0.l	トークン数
*	a0.l	トークン列

		.offset	0
~exe_file:	.ds.b	128
~exe_argv0:	.ds.b	128
~exe_args:	.ds.b	256
		.text

execute_file::
		PUSH	d0-d7/a0-a6
		move.l	d0,d7
		lea	(a0),a4			;トークン列
		lea	(tmp_buf),a3

* シェル起動チェック
		moveq	#0,d6
		tst.b	(Q_sw_v,a5)
		bne	exe_file_no_shell

* シェル起動文字が含まれるか調べる
		lea	(schr_tbl-tmp_buf,a3),a1
		moveq	#0,d1			;モード
		moveq	#0,d0
		move.l	d7,d2
exe_file_shchk_f:
		eor.b	d0,d1
exe_file_shchk_loop:
		move.b	(a0)+,d0
		ble	exe_file_shchk_le
		cmpi.b	#TC_FILE,d0
		beq	exe_file_shchk_f
		cmpi.b	#TC_ESC,d0
		bne	@f
		move.b	(a0)+,d0
@@:
		tst.b	d1			;ファイル名中に現われた記号類は
		bne	exe_file_shchk_loop	;シェル起動文字と見なさない

		tst.b	(a1,d0.w)
		beq	exe_file_shchk_loop
		bra	exe_file_shell		;シェル起動文字が含まれていた
exe_file_shchk_le:
		beq	exe_file_shchk_next
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	exe_file_shchk_loop	;１バイト片仮名
		addq.l	#1,a0
		bra	exe_file_shchk_loop
exe_file_shchk_next:
		subq.l	#1,d2
		bne	exe_file_shchk_loop

* シェル起動コマンドが含まれるか調べる
		tst	(＄unix)
		bne	exe_file_no_shell

		GETMES	MES_SCMD0
		movea.l	d0,a0
exe_file_shchk2_loop:
		lea	(a0),a1
		tst.b	(a0)
		beq	exe_file_no_shell
@@:
		move.b	(a0)+,d1
		beq	@f
		cmpi.b	#';',d1
		beq	@f
		lsr.b	#5,d1
		btst	d1,#%10010000
		beq	@b
		move.b	(a0)+,d1
		bne	@b
@@:
		clr.b	-(a0)			;セミコロンを NUL に書き換える
		lea	(a4),a2
		jsr	(stricmp_a1_a2)
		seq	d0
		move.b	d1,(a0)+		;元に戻す
		tst.b	d0
		beq	exe_file_shchk2_loop
		bra	exe_file_shell		;シェル起動コマンドが含まれていた

* シェル起動が必要
exe_file_shell:
**		PR_STR	<"==== shell ====",LF>

* 環境変数 $MINTSHELL 収得
		lea	(~exe_file,a3),a1
		pea	(a1)
		clr.l	-(sp)
		pea	(str_mintshell,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	@f
		GETMES	MES_SCMDX		;未定義なら 'COMMAND.X' にする
		movea.l	d0,a0
		STRCPY	a0,a1
@@:
* シェル検索
		lea	(~exe_file,a3),a0	;コマンドライン
		lea	(~exe_args,a3),a1	;引数バッファ
		bsr	search_command
		bmi	exe_file_error

		lea	(~exe_argv0,a3),a1	;argv0 をセット
		STRCPY	a0,a1

		move.l	d7,d0			;引数の数
		lea	(a4),a0			;引数
		lea	(~exe_args+1,a3),a1	;シェルオプション
		bsr	shell_encode
		bmi	exe_file_error2

		exg	a0,a4
		move.l	d0,d7

* トークンバッファ解放
		pea	(a0)
		DOS	_MFREE
		addq.l	#4,sp

		lea	(a4),a0			;引数
		lea	(~exe_file,a3),a1	;argv0
		bra	exe_file_search_ok

* シェル起動は不要
exe_file_no_shell:
**		PR_STR	<"==== file ====",LF>

* 実行ファイル名を取り出す
		lea	(a4),a0
		lea	(a4),a1
		bsr	remove_tc
		lea	(a0),a2			;引数

		lea	(a4),a0
		STRLEN	a0,d1
		moveq	#-13,d0
		lsr.l	#7,d1			;cmpi.l #128,d1 / bcc
		bne	exe_file_error		;ファイル名が長すぎる

		lea	(~exe_file,a3),a1	;検索ファイル名をセット
		STRCPY	a0,a1
		lea	(a4),a0
		lea	(~exe_argv0,a3),a1	;argv0 をセット
		STRCPY	a0,a1

* ファイル検索
		lea	(~exe_file,a3),a0	;コマンドライン
		lea	(~exe_args,a3),a1	;引数バッファ
		bsr	search_command
		bmi	exe_file_error2

		subq.l	#1,d7			;先頭のトークンの分を差し引く
		lea	(a2),a0			;引数
		lea	(~exe_argv0,a3),a1	;argv0
exe_file_search_ok:
* 引数エンコード
  move.l d7,d0
  bsr hupair_encode
  move.l d0,d7  ;コマンドラインバッファのサイズ
  bmi exe_file_error2

  pea (a4)  ;不要になったトークンバッファを解放する
  DOS _MFREE
  addq.l #4,sp

  movea.l  a0,a4  ;コマンドラインバッファのアドレス

  cmpa.l (cmdline_buf_ptr,pc),a4
  beq @f
    move.l d7,d1
    lea (a4),a1
    bsr lift_memory_block
    lea (a1),a4
  @@:

* 実行ファイルロード
		PUSH	a3/a4
		clr.l	-(sp)
		pea	(HUPAIR_ID_SIZE,a4)
		pea	(~exe_file,a3)
		move	#LOAD,-(sp)
		move.l	a4,d7
		DOS	_EXEC
		move.l	a4,d7			;d7 = 実行アドレス
		lea	(14,sp),sp
		POP	a3/a4
		tst.l	d0
		bmi	exe_file_error2

* HUPAIR チェック
  movea.l d7,a0
  lea (2+HUPAIR_ID_SIZE,a0),a0
  cmpa.l a1,a0
  bhi @f  ;メモリブロック末尾を超えるならチェックしない
    cmpi.l #'AIR'<<8,-(a0)
    bne @f
      cmpi.l #'#HUP',-(a0)
      beq exe_file_hupair_ok  ;HUPAIR対応
  @@:
  lea (HUPAIR_ID_SIZE,a4),a0  ;HUPAIR非対応の場合、コマンドラインの長さに制限がある
  cmpi.b #$ff,(a0)+
  bcs exe_file_hupair_ok  ;255バイト未満なら実行可能

  STRLEN a0,d0  ;255のとき、実際に255バイトの場合と256バイト以上の場合があるので確認する
  lsr.l #8,d0
  beq exe_file_hupair_ok  ;255バイトなら実行可能

* HUPAIR 未対応の実行ファイルに 255 バイトを超える
* 引数を渡そうとした場合はエラーを返す
		PUSH	a3-a6			;ダミーコードを実行して
		pea	(exe_file_dummy,pc)	;ロードしたプログラムを終了させる
		move	#EXECONLY,-(sp)
		DOS	_EXEC
		addq.l	#6,sp
		POP	a3-a6
		moveq	#-41,d0
		bra	exe_file_error2
exe_file_dummy:
		DOS	_EXIT
exe_file_hupair_ok:
		bsr	execute_switch_before

* 実行開始時間記録
		tst.b	(getsec_flag)
		bne	@f
		IOCS	_ONTIME
		move.l	d0,(時間_実行前)
@@:
* ロード済みプログラムを実行
		PUSH	a4-a6
		move.l	d7,-(sp)		;実行アドレス
		move	#EXECONLY,-(sp)
		DOS	_EXEC
		addq.l	#6,sp
		POP	a4-a6

* @exitcode/@status 更新
		lea	(＠exitcode,pc),a0
		move	d0,(a0)
		move	d0,(＠status-＠exitcode,a0)

* 実行終了時間記録
		IOCS	_ONTIME
		move.l	d0,(時間_実行後)

		bsr	execute_switch_after
		bra	exe_file_end
exe_file_error2:
		lea	(~exe_argv0,a3),a0
exe_file_error:
		bsr	print_dos_error
exe_file_end:
  movea.l a4,a0
  bsr free_hupair_buffer

		POP	d0-d7/a0-a6
		rts


* シェル引数エンコード ------------------------ *
* in	d0.l	トークン数
*	a0.l	トークン列
*	a1.l	シェルオプション(/C など)
* out	d0.l	引数の数(負数ならエラーコード)
*	a0.l	バッファアドレス
*	ccr	<tst.l d0> の結果

PUT:		.macro	put_op
		subq.l	#1,d7
		bcs	sh_enc_overflow
		put_op
		.endm

shell_encode::
		PUSH	d1-d7/a1-a3
		move.l	d0,d4

		lea	(a0),a2
		bsr	malloc_all
		move.l	d0,d7			;バッファサイズ
		bmi	sh_enc_memerr
		move.l	a0,d6			;バッファアドレス

		exg	a0,a2			;a0=トークン列, a2=書き込みポインタ
		moveq	#1,d5			;引数の数

* シェルオプションを分割しながら転送する
sh_enc_shopt_loop:
		bsr	skip_blank
		move.b	(a1)+,d0
		beq	sh_enc_shopt_end
		addq.l	#1,d5
@@:
		PUT	<move.b  d0,(a2)+>
		beq	sh_enc_shopt_end
		move.b	(a1)+,d0
		cmpi.b	#TAB,d0
		beq	@f
		cmpi.b	#SPACE,d0
		bne	@b
@@:
		PUT	<clr.b  (a2)+>
		bra	sh_enc_shopt_loop
sh_enc_shopt_end:

* トークンをクォーティングし、空白で繋げながら転送する

* TC_FILE で括られた範囲の
*	「'」は「"」でクォーティングする
*	「"」は「'」でクォーティングする
*	スペース/タブはどちらかでクォーティングする
*	それ以外のシェル起動文字は「'」でクォーティングする
* それ以外の範囲の
*	「'」は「"」でクォーティングする
*	「"」は「'」でクォーティングする
*	スペース/タブはどちらかでクォーティングする
*	それ以外のシェル起動文字はクォーティングしない

		moveq	#0,d0
		move	(＄unix),d2
		moveq	#"'",d3			;前回のクォーティング
		lea	(schr_tbl),a3
sh_enc_token_loop:
		tst.b	(a0)
		beq	sh_enc_token_nul	;空文字列

		moveq	#-1,d1			;モード
sh_enc_token_f:
		not	d1
sh_enc_token_loop2:
		move.b	(a0)+,d0
		beq	sh_enc_token_next
		cmpi.b	#TC_FILE,d0
		beq	sh_enc_token_f
		cmpi.b	#TC_ESC,d0
		bne	@f
		move.b	(a0)+,d0
@@:
		cmpi.b	#TAB,d0
		beq	sh_enc_token_q		;空白は ' か " のどちらかで括る
		cmpi.b	#SPACE,d0
		beq	sh_enc_token_q		;〃
		cmpi.b	#"'",d0
		beq	sh_enc_token_qd
		cmpi.b	#'"',d0
		beq	sh_enc_token_qs
		tst	d1
		beq	sh_enc_token_put
		tst.b	(a3,d0.w)		;ファイル名内にシェル起動文字があれば
		bne	sh_enc_token_qs		;'～' でクォーティングする
sh_enc_token_put:
		PUT	<move.b  d0,(a2)+>
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	sh_enc_token_loop2
		PUT	<move.b  (a0)+,(a2)+>
		bra	sh_enc_token_loop2
sh_enc_token_qd:
		moveq	#'"',d3
		bra	sh_enc_token_q
sh_enc_token_qs:
		moveq	#"'",d3
sh_enc_token_q:
		tst	d2
		beq	sh_enc_token_put	;%unix 0 ならクォーティングしない

		PUT	<move.b  d3,(a2)+>
		PUT	<move.b  d0,(a2)+>
		PUT	<move.b  d3,(a2)+>
		bra	sh_enc_token_loop2
sh_enc_token_nul:
		tst	d2
		beq	sh_enc_token_next	;%unix 0 ならクォーティングしない

		PUT	<move.b  d3,(a2)+>
		PUT	<move.b  d3,(a2)+>
sh_enc_token_next:
		PUT	<move.b  #SPACE,(a2)+>
		subq.l	#1,d4
		bne	sh_enc_token_loop
		clr.b	(-1,a2)

		suba.l	d6,a2			;引数バッファを必要サイズに縮小する
		move.l	a2,-(sp)
		move.l	d6,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp

		movea.l	d6,a0
		move.l	d5,d0
sh_enc_end:
		POP	d1-d7/a1-a3
		rts
sh_enc_overflow:
		move.l	d6,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
sh_enc_memerr:
		moveq	#-8,d0
		bra	sh_enc_end


* HUPAIR エンコード --------------------------- *
* in	d0.l	トークン数
*	a0.l	トークン列
*	a1.l	argv0
* out	d0.l	データサイズ(負数ならエラーコード)
*	d1.l	コマンドラインの長さ
*	a0.l	バッファアドレス
*		.dc.b	'#HUPAIR',0
*		.dc.b	len			;a0+8
*		.dc.b	'arg...',0
*		.dc.b	'argv0',0
*	ccr	<tst.l d0> の結果
* トークン列の内容は破壊しない。
* バッファは free_hupair_buffer で解放すること。

PUT: .macro put_op
  subq.l #1,d7
  bcc @skip
    bsr realloc_hupair_buffer
  @skip:
  put_op
  .endm

hupair_encode::
  PUSH d3-d7/a1-a4
  move.l d0,d4  ;トークン数

  ;最初は内蔵固定バッファに書き込む
  move.l #CMDLINE_BUF_SIZE,d7
  move.l (cmdline_buf_ptr,pc),d6
  movea.l d6,a2  ;書き込みポインタ

  subq.l #HUPAIR_ID_SIZE,d7
  move.l #'#HUP',(a2)+
  move.l #'AIR'<<8,(a2)+
  subq.l #1,d7
  st (a2)+     ;コマンドラインの長さ(暫定で255)

  tst.l d4
  beq hu_enc_noarg  ;引数が一つもない場合
hu_enc_loop:
  lea (a0),a4  ;先読みするのでトークンのアドレスを保存

* クォーティング記号を判別する
		bsr	get_next_char
		beq	hu_enc_qd		;空文字列なら "" とする
hu_enc_q_loop:
		cmpi.b	#"'",d0
		beq	hu_enc_qd
		cmpi.b	#'"',d0
		beq	hu_enc_qs
		cmpi.b	#SPACE,d0
		bne	hu_enc_q_next

* 空白があれば " または ' のどちらか
@@:		bsr	get_next_char
		beq	hu_enc_qd
		cmpi.b	#"'",d0
		beq	hu_enc_qd
		cmpi.b	#'"',d0
		bne	@b
hu_enc_qs:
		moveq	#"'",d3
		bra	@f
hu_enc_qd:
		moveq	#'"',d3
@@:		PUT	<move.b  d3,(a2)+>	;クォーティング開始
		bra	@f
hu_enc_q_next:
		bsr	get_next_char
		bne	hu_enc_q_loop

		moveq	#0,d3			;クォーティング不要
@@:
* クォーティングしながら転送する
		lea	(a4),a0			;トークンの先頭
		bra	1f
hu_enc_loop2:
		cmp.b	d0,d3
		bne	@f
		PUT	<move.b  d3,(a2)+>	;クォーティング終了
		eori.b	#"'".xor.'"',d3
		PUT	<move.b  d3,(a2)+>	;クォーティング再開
@@:
		PUT	<move.b  d0,(a2)+>
1:		bsr	get_next_char
		bne	hu_enc_loop2

		tst.b	d3
		beq	@f
		PUT	<move.b  d3,(a2)+>	;クォーティング終了
@@:
hu_enc_noarg:
  PUT <move.b #SPACE,(a2)+>
  subq.l #1,d4
  bhi hu_enc_loop
  clr.b -(a2)

hu_enc_endofargs:
  movea.l d6,a3
  lea (HUPAIR_ID_SIZE+1,a3),a3  ;コマンドラインの先頭
  move.l a2,d1
  sub.l a3,d1   ;コマンドラインの長さ。返り値なので破壊しないこと
  cmpi.l #$ff,d1
  bcc @f
    move.b d1,-(a3)  ;確定したコマンドラインの長さを書き込む
  @@:
  addq.l #1,a2

  STRLEN a1,d3,+1  ;argv0+NULの長さ
  cmp.l d3,d7
  bcc @f
    bsr realloc_hupair_buffer
  @@:
  sub.l d3,d7
  bcs hu_enc_overflow
  STRCPY a1,a2  ;argv0 を末尾に付ける

  movea.l d6,a0  ;バッファ先頭。返り値なので破壊しないこと
  suba.l a0,a2  ;書き込んだサイズ

  cmpa.l (cmdline_buf_ptr,pc),a0
  beq @f
    move.l a2,-(sp)
    pea (a0)
    DOS _SETBLOCK
    addq.l #8,sp
  @@:
  move.l a2,d0  ;データサイズ
hu_enc_end:
  POP d3-d7/a1-a4
  rts

hu_enc_overflow:
  move.l d6,-(sp)
  DOS _MFREE
  addq.l #4,sp
hu_enc_memerr:
  moveq #-8,d0
  bra hu_enc_end

get_next_char:
  @@:
    move.b (a0)+,d0
    cmpi.b #TC_FILE,d0
  beq @b
  cmpi.b #TC_ESC,d0
  bne @f
    move.b (a0)+,d0
  @@:
  tst.b d0
  rts

;HUPAIRバッファを再確保する
;  成功時はd6/d7/a2が更新される。
;  エラー時は呼び出し元に戻らずエラー処理に飛ぶ。
realloc_hupair_buffer:
  PUSH d0/a0-a1
  cmp.l (cmdline_buf_ptr,pc),d6
  bne realloc_hu_overflow  ;既に_MALLOCで確保している

  suba.l d6,a2   ;書き込み済みサイズ
  movea.l d6,a1  ;転送元アドレス(memory_copy呼び出し時の引数)

  bsr malloc_all
  move.l a0,d6  ;新しいバッファ先頭アドレス
  move.l d0,d7  ;新しいバッファサイズ
  bmi realloc_hu_memerr  ;このエラーは_MFREE不要

  sub.l a2,d7
  bls realloc_hu_overflow
  subq.l #1,d7  ;PUTマクロで引いた分を新しいバッファ残量から引き直す
  ;bcs realloc_hu_overflow  ;上でblsしているので不要

  move.l a2,d0  ;内蔵固定バッファから_MALLOCで確保したバッファに複写する
  bsr memory_copy

  lea (a0),a2  ;新しい書き込みポインタ
  POP d0/a0-a1
  rts
realloc_hu_memerr:
  POP d0/a0-a1/a2  ;a2にリターンアドレスを読み捨てて、リターンせずにエラー処理に飛ぶ
  bra hu_enc_memerr
realloc_hu_overflow:
  POP d0/a0-a1/a2
  bra hu_enc_overflow


* コマンドラインバッファを解放する ------------ *
* in a0.l  バッファアドレス

free_hupair_buffer:
  cmpa.l (cmdline_buf_ptr,pc),a0
  beq @f
    move.l a0,-(sp)
    DOS _MFREE
    addq.l #4,sp
  @@:
  rts


* 制御コード削除 ------------------------------ *
* in	a0.l	文字列
*	a1.l	書き込みバッファ
* out	a0.l	NUL の次のアドレス(文字列側)
*	a1.l	〃		(バッファ側)
* break	d0

remove_tc:
@@:		move.b	(a0)+,d0
		cmpi.b	#TC_FILE,d0
		beq	@b
		cmpi.b	#TC_ESC,d0
		bne	1f
		move.b	(a0)+,d0
1:		move.b	d0,(a1)+
		beq	@f
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		move.b	(a0)+,(a1)+
		bne	@b
@@:
		rts


* DOS エラーメッセージ表示 -------------------- *
* in	d0.l	エラーコード
*	a0.l	ファイル名

print_dos_error:
		PUSH	d0-d2/a0
		move.l	d0,d2
		pea	(a0)
		DOS	_PRINT
		addq.l	#4,sp

		lea	(err_mes_tbl,pc),a0
		cmpi.l	#$ffffffb0,d2
		bcc	@f
		moveq	#0,d2
@@:
		move.b	(a0)+,d0		;メッセージ番号
		move.b	(a0)+,d1		;エラーコード
		beq	@f
		cmp.b	d1,d2
		bne	@b
@@:
		jsr	(PrintMsgCrlf)
		POP	d0-d2/a0
		rts

err_mes_tbl:
		.dc.b	MES_E_NOF,-2		;指定したファイルが見つからない
		.dc.b	MES_E_FOP,-4		;オープンしているファイルが多すぎる
		.dc.b	MES_E_NOM,-8		;実行に必要なメモリがない
		.dc.b	MES_E_FMT,-11		;実行ファイルのフォーマットが異常
		.dc.b	MES_E_NAM,-13		;ファイル名の指定に誤りがある
		.dc.b	MES_E_DRV,-15		;ドライブ指定に誤りがある
		.dc.b	MES_E_RDY,-40		;ドライブの準備が出来ていない(拡張)
		.dc.b	MES_E_ARG,-41		;HUPAIR に対応していない(拡張)
		.dc.b	MES_E_EXE,0		;その他のエラー
		.even


* 実行ファイル検索 ---------------------------- *
* in	d0.l	0 以外ならカレントディレクトリから検索しない
*	a0.l	コマンドライン/ファイル名バッファ
*	a1.l	引数バッファ
* out	d0.l	エラーコード
*		  0:.x|.r|.z
*		  1:.bat
*		-40:ドライブの準備が出来ていない(拡張)
*		その他の数値なら DOS コールのエラーコード.
* 備考:
*	DOS _EXEC 使用版.
*	拡張子 .bat/.BAT は補完しないので、省略せずに
*	記述した時だけ検索できる.

search_command::
		PUSH	d1-d4/a2
		moveq	#TAB,d2
		moveq	#SPACE,d3
		move.l	d0,d4

		lea	(a0),a2
@@:
		move.b	(a2)+,d0		;先頭の空白を飛ばす
		cmp.b	d2,d0
		beq	@b
		cmp.b	d3,d0
		beq	@b
		subq.l	#1,a2

		moveq	#0,d1
		bra	sch_cmd_scan_next
sch_cmd_scan_loop:
		cmpi.b	#'/',d0
		beq	sch_cmd_scan_found	;パスデリミタ
		cmpi.b	#'\',d0
		beq	sch_cmd_scan_found	;〃
		cmp.b	d2,d0
		beq	sch_cmd_scan_blank	;コマンド名終了
		cmp.b	d3,d0
		beq	sch_cmd_scan_blank	;〃
		cmpi.b	#':',d0
		bne	sch_cmd_scan_next
sch_cmd_scan_found:
		moveq	#1,d1
sch_cmd_scan_next:
		move.b	(a2)+,d0
		bgt	sch_cmd_scan_loop
		beq	sch_cmd_scan_nul
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	sch_cmd_scan_next
		tst.b	(a2)+
		bne	sch_cmd_scan_next
sch_cmd_scan_nul:
		subq.l	#1,a2
sch_cmd_scan_blank:
		tst	d1
		beq	sch_cmd_no_path

* ドライブ名かパスデリミタがある場合
		move.b	(a2),-(sp)
		clr.b	(a2)			;空白以降を切り離す
		jsr	(get_drive_status)
		move.b	(sp)+,(a2)
		tst.l	d0
		bmi	sch_cmd_end
		andi.b	#1<<DRV_NOTREADY+1<<DRV_INSERT+1<<DRV_ERRINS,d0
		subq.b	#1<<DRV_INSERT,d0
		beq	sch_cmd_pathchk
*sch_cmd_notready:
		moveq	#-40,d0
		bra	sch_cmd_end

* ファイル名のみの場合($path 検索)
sch_cmd_no_path:
		tst.l	d4
		bne	@f			;&which -c なら常にパッチをあてる
		moveq	#0,d1
		jsr	(dos_drvctrl_d1)
		bmi	sch_cmd_end
		andi.b	#1<<DRV_NOTREADY+1<<DRV_INSERT+1<<DRV_ERRINS,d0
		subq.b	#1<<DRV_INSERT,d0
		beq	sch_cmd_pathchk		;カレントドライブが未挿入なら
@@:		bsr	set_dos_exec_patch	;DOS _EXEC にパッチをあてる

sch_cmd_pathchk:
		clr.l	-(sp)
		pea	(a1)			;引数バッファ
		pea	(a0)			;コマンドライン
		move	#PATHCHK,-(sp)
		DOS	_EXEC
		lea	(14,sp),sp
		bsr	restore_dos_exec_patch
		tst.l	d0
		bmi	sch_cmd_end

		jsr	(to_mintslash)

		lea	(a0),a2
@@:		tst.b	(a2)+
		bne	@b
		subq.l	#.sizeof.('.bat')+1,a2
		moveq	#0,d0
		cmpa.l	a2,a0
		bcc	sch_cmd_end		;.x|.r|.z|拡張子なし
		move.b	(a2)+,-(sp)
		move	(sp)+,d1
		move.b	(a2)+,d1
		swap	d1
		move.b	(a2)+,-(sp)
		move	(sp)+,d1
		move.b	(a2)+,d1
		ori.l	#$00202020,d1
		cmpi.l	#'.bat',d1
		bne	sch_cmd_end
		moveq	#1,d0			;.bat
sch_cmd_end:
		POP	d1-d4/a2
		tst.l	d0
		rts


* DOS _EXEC カレントディレクトリ検索抑制パッチ
set_dos_exec_patch:
		PUSH	d0-d1
		TO_SUPER
		move	#$600e,d1
		cmp	($9d80),d1
		bne	@f
		DOS	_VERNUM
		cmpi	#$0302,d0
		bne	@f

		move	d1,(dos_exec_patch_flag)
		move	#$2048,($9d80)		;movea.l a0,a0
		cmpi.b	#2,(MPUTYPE)
		bcs	@f
		moveq	#3,d1			;キャッシュ破棄
		IOCS	_SYS_STAT
@@:
		TO_USER
		POP	d0-d1
		rts

* DOS _EXEC パッチ復帰
* (mint.s の prepare_exit_mint からも呼ばれる)
restore_dos_exec_patch::
		PUSH	d0-d1/a1
		lea	(dos_exec_patch_flag,pc),a1
		move	(a1),d1
		beq	@f
		clr	(a1)
		lea	($9d80),a1		;DOS _EXEC のパッチを元に戻す
		IOCS	_B_WPOKE
@@:
		POP	d0-d1/a1
		rts


dos_exec_patch_flag:
		.dc	0


* シェル起動文字テーブル作成 ------------------ *

init_schr_tbl::
		PUSH	d0-d1/a0-a1
		tst	(＄unix)
		seq	d0
		addi.b	#MES_SCHR1,d0
		jsr	(get_message)
		movea.l	d0,a0

		lea	(schr_tbl+128),a1
		moveq	#0,d0
		moveq	#128/(4*4)-1,d1
@@:
	.rept	4
		move.l	d0,-(a1)		;バッファクリア
	.endm
		dbra	d1,@b
@@:
		st	(a1,d0.w)		;フラグをセットする
		move.b	(a0)+,d0
		bgt	@b
		beq	@f
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b			;１バイト片仮名
		tst.b	(a0)+
		bne	@b
@@:
		POP	d0-d1/a0-a1
		rts


* オプションスイッチの処理(実行前) ------------ *

execute_switch_before::

* カーソル位置ファイル名保存
		jsr	(set_curfile2)

* ファンクションキー表示行
		jsr	(RestoreFnckey)
.if 1
		lea	(＄fnmd),a0
		moveq	#0,d0			;現在の表示モード
		tst	(a0)
		bne	@f
		moveq	#3,d0			;%fnmd 0
@@:
		move	(orig_fnckey_mode),d1	;変更後のモード
		tst.b	(Q_sw_f,a5)
		beq	@f
**		moveq	#3,d1			;-f 指定あり
		moveq	#2,d1
@@:
		cmp	d0,d1
		beq	exe_sw_b_skip_f		;表示モード変更なし

		jsr	(SaveCursor)
		move	d1,-(sp)
		move	#14,-(sp)		;ファンクションキー表示切り換え
		DOS	_CONCTRL
		addq.l	#4,sp

		move	(a0),-(sp)
		move	d1,(a0)
		subq	#3,(a0)			;無表示なら %fnmd 0 扱いで計算する
		jsr	(set_scr_param)
		jsr	(set_scroll_narrow_console)
		move	(sp)+,(a0)
		jsr	(set_scr_param)

		jsr	(RestoreCursor)
exe_sw_b_skip_f:
		move.b	(Q_sw_s,a5),(Q_redraw,a5)
		beq	@f			;再描画要求フラグを初期化しておく

* 全画面実行
		moveq	#31,d0
		subq	#3,d1
		bne	1f
		moveq	#32,d0
1:		move.l	d0,-(sp)
		move	#15,-(sp)
		DOS	_CONCTRL		;スクロール範囲設定(全画面)
		addq.l	#6,sp
		jsr	(ConsoleClear)
		bra	exe_sw_b_skip_s
@@:
.endif

.if 0
		tst.b	(Q_sw_f,a5)
		beq	1f
		jsr	(SaveCursor)
		jsr	(fnckey_disp_off)
		jsr	(RestoreCursor)
		bra	@f
1:
		jsr	(restore_fnckey_mode)	;mint 起動前の状態に戻す
@@:

* 全画面実行
		move.b	(Q_sw_s,a5),(Q_redraw,a5)
		beq	@f			;再描画要求フラグを初期化しておく
		moveq	#32,d0
		tst.b	(Q_sw_f,a5)
		bne	1f
		cmpi	#3,(orig_fnckey_mode)
		beq	1f
		moveq	#31,d0
1:		move.l	d0,-(sp)
		move	#15,-(sp)
		DOS	_CONCTRL		;スクロール範囲設定(全画面)
		addq.l	#6,sp
		jsr	(ConsoleClear)
		bra	exe_sw_b_skip_s
@@:
		tst.b	(Q_sw_f,a5)
		beq	@f
		lea	(＄fnmd),a0
		move	(a0),-(sp)
		beq	1f
		clr	(a0)
		jsr	(set_scr_param)
		jsr	(set_scroll_narrow_console)
1:		move	(sp)+,(a0)
		jsr	(set_scr_param)
@@:
.endif
		jsr	(ConsoleClear2)		;%cclr 0 なら画面消去

* 画面状態保存
		pea	(save_text_state,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
exe_sw_b_skip_s:

* テキストパレット
		tst.b	(Q_sw_atmark,a5)
		beq	@f
		bsr	init_text_palette
@@:

* 画面プライオリティ
		tst.b	(Q_sw_q,a5)
		beq	@f
		moveq	#T_ON+G_ON,d1
		IOCS	_VC_R2
@@:

* DOS 制御 / その他
		jsr	(fep_enable)
		jsr	(breakck_restore)
		jsr	(restore_keyinp_ex_vector)

* カーソル
		tst.b	(Q_sw_i,a5)
		bne	@f
		jsr	(CursorBlinkOn)
@@:
		rts


* テキストパレット初期化 ---------------------- *
* break	d0-d2

init_text_palette::
		moveq	#-2,d2
		moveq	#3,d1
@@:
		IOCS	_TPALET
		dbra	d1,@b
		rts


* オプションスイッチの処理(実行後) ------------ *

execute_switch_after::

* キー入力待ち
		cmpi.b	#'h',(Q_sw_h_k,a5)
		bcs	@f			;-h / -k なし
		st	(disable_clock_flag)
		beq	1f
		jsr	(dos_inpout)		;-k
		bra	2f
1:		jsr	(＆key_wait)		;-h
2:		clr.b	(disable_clock_flag)
@@:

* カーソル
**		tst.b	(Q_sw_i,a5)		;-i なしでも子プロセスがオンに
**		bne	@f			;する可能性があるので、常に消去する
		jsr	(CursorBlinkOff)
**@@:

* DOS 制御 / その他
		jsr	(hook_keyinp_ex_vector)
		jsr	(breakck_save_kill)
		jsr	(WinFontInit)
		jsr	(fep_disable)

* グラフィック
		bsr	execute_switch_g

* 画面状態検査
		jsr	(set_crt_mode_768x512)
		bne	1f
		tst.b	(Q_redraw,a5)
		bne	@f
		pea	(check_text_state,pc)
		DOS	_SUPER_JSR
		move.l	d0,(sp)+
1:		sne	(Q_redraw,a5)
@@:

* ファンクションキー表示行
		jsr	(SaveFnckey)
		jsr	(ChangeFnckey)
.if 1
		tst.b	(Q_redraw,a5)
		bne	exe_sw_a_set_fnckey

		move.l	#14<<16+$ffff,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		subq.l	#3,d0
		sne	d0
		tst	(＄fnmd)
		sne	d1
		cmp.b	d0,d1
		beq	@f			;モード変更なし

		tst.b	d1
		beq	exe_sw_a_set_fnckey	;ファンクションキーを消す

		IOCS	_B_DOWN_S		;ファンクションキーを表示する
		IOCS	_B_UP_S
exe_sw_a_set_fnckey:
		jsr	(SaveCursor)
		jsr	(reset_fnckey_mode)	;元に戻す
		jsr	(set_scr_param)
		jsr	(set_scroll_narrow_console)
		jsr	(RestoreCursor)
@@:
.endif

.if 0
		tst.b	(Q_sw_f,a5)
		beq	1f
		IOCS	_B_DOWN_S
		IOCS	_B_UP_S
		jsr	(SaveCursor)
		jsr	(fnckey_disp_on2)
		jsr	(RestoreCursor)
		bra	@f
1:
**		jsr	(get_fnckey_mode)
		jsr	(reset_fnckey_mode)	;元に戻す
@@:

* コンソール範囲
		tst.b	(Q_redraw,a5)
		bne	@f
		jsr	(set_scr_param)
		jsr	(set_scroll_narrow_console)
@@:
.endif

* 全画面実行 / 画面クリア / リロード
		moveq	#%0000_0011,d0
		and.b	(Q_sw_d,a5),d0
		tst.b	(Q_sw_l,a5)
		beq	@f
		ori.b	#%0100_0000,d0
@@:		tst.b	(Q_redraw,a5)
		beq	@f
		ori.b	#%1100_1100,d0
@@:
		jsr	(print_screen)
		jsr	(reset_current_dir)

* 実行時間・終了コード表示
		moveq	#0,d0
		move	(＄code),d0
		beq	@f
		tst	(＄cplp)
		bne	@f			;cplp 行に表示済み
		tst.b	(getsec_flag)
		bne	1f
		bsr	print_runtime
1:		bsr	print_exitcode
@@:
		rts


* -g スイッチの処理 --------------------------- *

execute_switch_g::
		move.b	(Q_sw_g,a5),d1
		beq	exe_sw_g_end0
		move.l	(＠buildin,pc),d0
		tst	d0
		bne	exe_sw_g_end0		;エラー終了した場合は起動しない
		move.l	d0,-(sp)

		cmpi.b	#'0',d1
		beq	@f
		jsr	(check_gusemd)
		bne	exe_sw_g_end		;GVRAM は使用中
@@:
		moveq	#$f,d0
		and.b	(Q_sw_g,a5),d0
		move.b	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc.b	exe_sw_g0_gvoff-@b
		.dc.b	exe_sw_g1_half16-@b
		.dc.b	exe_sw_g2_half256-@b
		.dc.b	exe_sw_g3_half-@b
		.dc.b	exe_sw_g4_gvon256-@b
		.dc.b	exe_sw_g5_gvon-@b
		.dc.b	exe_sw_g6_half64k-@b
		.dc.b	exe_sw_g7_gvon16-@b
		.dc.b	exe_sw_g8_gvon64k-@b
		.dc.b	exe_sw_g9_gvon24khz-@b

exe_sw_g0_gvoff:
		jsr	(＆gvram_off)		;-g0
		bra	exe_sw_g_end

exe_sw_g3_half:
		bsr	exe_sw_g_getcol		;-g3 (&half)
		beq	exe_sw_g1_half16
		subq	#1,d0
		beq	exe_sw_g2_half256
exe_sw_g6_half64k:
		bsr	exe_sw_sq_chk		;-g6 (&half 64K色)
		jsr	(g_half_64k_usr)
		bra	exe_sw_g_end
exe_sw_g2_half256:
		bsr	exe_sw_sq_chk		;-g2 (&half 256色)
		jsr	(g_half_256_usr)
		bra	exe_sw_g_end
exe_sw_g1_half16:
		jsr	(g_half_16_usr)		;-g1 (&half 16色)
		bra	exe_sw_g_end

exe_sw_g5_gvon:
		bsr	exe_sw_g_getcol		;-g5 (&gvon)
		beq	exe_sw_g7_gvon16
		subq	#1,d0
		beq	exe_sw_g4_gvon256
exe_sw_g8_gvon64k:
		bsr	exe_sw_g_sub		;-g8 (&gvon 64K色)
		jsr	(gvon_64k_usr)
		bra	exe_sw_g_redraw
exe_sw_g4_gvon256:
		bsr	exe_sw_g_sub		;-g4 (&gvon 256色)
		jsr	(gvon_256_usr)
		bra	exe_sw_g_redraw
exe_sw_g9_gvon24khz:
		st	(GVON24_flag)		;-g9 (&gvon 初期化なし)
exe_sw_g7_gvon16:
		bsr	exe_sw_g_sub		;-g7 (&gvon 16色)
		jsr	(gvon_16_usr)
		bra	exe_sw_g_redraw

exe_sw_g_redraw:
		st	(Q_redraw,a5)		;全画面の再描画が必要
exe_sw_g_end:
		move.l	(sp)+,(＠buildin)
exe_sw_g_end0:
		rts


* グラフィック表示色モードを収得する
* out	d0.l	モード
* break	d1
exe_sw_g_getcol:
		moveq	#-1,d1
		IOCS	_VC_R0
		andi	#3,d0
		rts

exe_sw_g_sub:
		clr.l	(graph_home)
exe_sw_sq_chk:
		jmp	(gm_check_square)
**		rts


* 実行時間表示 -------------------------------- *
* in	d0.l	最低表示時間(0 なら必ず表示する)
*
* ファイル実行後に実行時間をコンソールに表示する
* (%cplp 1 または %code 0 の場合は呼び出さないこと).
* また、全チェイン終了後に &getsec 実行時からの
* 経過時間を表示する(%cplp 1 の場合は代わりに
* print_cplp_line を呼び出すこと).

print_runtime::
		PUSH	d0-d1/a0-a1
		move.l	(時間_実行後),d1
		sub.l	(時間_実行前),d1
		bcc	@f
		addi.l	#24*60*60*100,d1
@@:
		cmp.l	d0,d1
		bcs	print_runtime_end

		lea	(sp),a1
		lea	(-12,sp),sp
		move.l	d1,d0
		moveq	#3,d1
		lea	(sp),a0
		FPACK	__IUSING
		move.l	#CR<<24+LF<<16+0,-(a1)
		move.b	-(a0),-(a1)		;小数点第2位
		move.b	-(a0),-(a1)		;      第1位
		ori	#('0'.xor.SPACE)*$0101,(a1)
		move.b	#'.',-(a1)
@@:
		moveq	#'0'.xor.SPACE,d0
		or.b	-(a0),d0
		move.b	d0,-(a1)
		cmpa.l	a0,sp
		bne	@b
		pea	(a1)
		DOS	_PRINT
		lea	(12+4,sp),sp
print_runtime_end:
		POP	d0-d1/a0-a1
		rts


* 画面状態保存 -------------------------------- *
* break	d0-d1/a0-a1

* コンソール部分は見ないように注意すること. チェック
* するのはタイトル、ボリューム、パス、ファイルリスト、
* ドライブ情報であるが、%dirh を最小(3)にした場合に
* コンソール部分にかからないように範囲を決めると、上
* から 7 行となる.
*	128*16*7/48 ≒ 298
* これにより 298 バイトごとにチェックする.

save_text_state::
		bsr	text_state_sub
		move.l	($948),(a1)+		;テキスト表示開始アドレスオフセット
		move.l	($970),(a1)+		;テキスト桁数-1/行数-1
@@:
		move.l	(a0),(a1)+
		lea	(298,a0),a0
		dbra	d1,@b
		rts

text_state_sub:
		lea	(TVRAM_P0),a0
		lea	(tmp_buf),a1
		moveq	#48-1,d1
		rts


* 画面状態検査 -------------------------------- *
* out	d0.l	!= 0 の時、テキスト破壊
* break	d1/a0-a1

check_text_state::
		bsr	text_state_sub
		move.l	($948),d0
		sub.l	(a1)+,d0
		bne	9f
		move.l	($970),d0
		sub.l	(a1)+,d0
		bne	9f
@@:
		move.l	(a0),d0
		sub.l	(a1)+,d0
		lea	(298,a0),a0
		dbne	d1,@b
9:		rts


* 終了コード表示 ------------------------------ *

* ファイル実行後に終了コードをコンソールに表示する.
* %cplp 1 または %code 0 の場合は呼び出さないこと.

print_exitcode::
		PUSH	d0/a0
		move	(＠exitcode,pc),d0
		beq	print_exitcode_end

		subq.l	#8,sp
		ext.l	d0
		lea	(sp),a0
		FPACK	__LTOS
		GETMES	MES_EXCOD
		move.l	d0,-(sp)
		DOS	_PRINT
		pea	(4,sp)
		DOS	_PRINT
		lea	(8+8,sp),sp
		jsr	(PrintCrlf)
print_exitcode_end:
		POP	d0/a0
		rts


* 内部命令 ------------------------------------ *

*************************************************
*		&debug				*
*************************************************

＆debug::
		lea	(debug_flag,pc),a0
		not.b	(a0)
		rts


*************************************************
*		&end=&return			*
*************************************************

＆end::
＆return::
		movea.l	(q_ptr,pc),a5
		st	(Q_abort,a5)
		rts


*************************************************
*		&eval				*
*************************************************

＆eval::
* 引数を空白で繋げる
		lea	(a0),a1
		move.l	d7,d1
		moveq	#SPACE,d0
		bra	1f
@@:
		tst.b	(a0)+
		bne	@b
		move.b	d0,-(a0)
1:
		subq.l	#1,d1
		bcc	@b
		clr.b	(a0)

		move.l	a0,d1
		sub.l	a1,d1
		bsr	eval_sub
eval_error:
		rts


* 行入力/&eval 下請け
* in	d1.l	strlen (a1)
*	a1.l	追加する madoka
* out	ccr	N=0:正常終了 N=1:エラー
* break	d0

eval_sub:
		PUSH	d1-d3/a1/a3-a4
		add.l	(Q_buf_size,a5),d1	;必要サイズ

		move.l	d1,d0
		bsr	malloc_from_same_side
		move.l	d0,d2
		bmi	eval_sub_end

		move.l	(Q_buf_top,a5),d3	;以前のバッファ
		move.l	d2,(Q_buf_top,a5)
		move.l	d1,(Q_buf_size,a5)

		move.l	(Q_macro,a5),d0
		beq	@f
		sub.l	d3,d0
		add.l	d2,d0
		move.l	d0,(Q_macro,a5)
@@:
		movea.l	(Q_next_ptr,a5),a4	;残りの madoka
		move.b	(a4),d0
		clr.b	(a4)

		movea.l	d3,a2			;転送元
		movea.l	d2,a3			;    先
		STRCPY	a2,a3,-1		;解釈済みの madoka を転送する

		move.b	d0,(a4)
		move.l	a3,(Q_next_ptr,a5)

		STRCPY	a1,a3,-1		;行入力の結果を繋げる

		STRCPY	a4,a3			;残りの madoka を繋げる

  move.l d3,d0
  bsr free_unfold_buffer  ;以前のバッファを解放
  moveq #0,d0
eval_sub_end:
		POP	d1-d3/a1/a3-a4
		rts


* 条件分岐命令チェック ------------------------ *
*
* 現在実行中の命令(&else/&else-if)の直前が条件分岐
* 命令(&if/&unless/&else-if)であるかどうか調べ、そ
* うでなかったらエラーメッセージを表示して内部命令
* を終了させる(呼び出し元の内部命令には帰らない).
* madoka の実行自体も強制終了させる.

else_check::
		move.l	a5,-(sp)
		movea.l	(q_ptr,pc),a5
		tst.b	(Q_if_flag,a5)
		movea.l	(sp)+,a5
		bne	else_check_end

		movea.l	(q_ptr,pc),a5
		st	(Q_abort,a5)
		move.l	(Q_funcname,a5),(sp)	;関数名
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#MES_MERR5,d0
		jmp	(PrintMsgCrlf)
else_check_end:
		rts


* ブロック記述チェック ------------------------ *
*
* 現在実行中の命令の直後にブロックが記述されているか
* どうか調べ、記述されていなかったらエラーメッセージ
* を表示して内部命令を終了させる(呼び出し元の内部命令
* には帰らない). madoka の実行自体も強制終了させる.

block_check::
		PUSH	d0/a1/a5
		movea.l	(q_ptr,pc),a5
		movea.l	(Q_next_ptr,a5),a1
		bsr	fetch_char
		cmpi.b	#'{',d0
		POP	d0/a1/a5
		beq	block_check_end

		movea.l	(q_ptr,pc),a5
		st	(Q_abort,a5)
		move.l	(Q_funcname,a5),(sp)	;関数名
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#MES_MERR4,d0
		jmp	(PrintMsgCrlf)
block_check_end:
		rts


*************************************************
*		&else				*
*************************************************

＆else::
		bsr	else_check
		bsr	block_check

		movea.l	(q_ptr,pc),a5
		movea.l	(Q_next_ptr,a5),a1
		tst.b	(Q_if_flag,a5)
		bmi	else_false		;&if 成立済み

* ブロックを実行する
*if_true:
		bsr	free_token_buf
		bsr	execute_block
		bra	@f

* ブロックを飛ばす
else_false:
		bsr	skip_block
@@:
		move.l	a1,(Q_next_ptr,a5)
		clr.b	(Q_if_next,a5)		;次は &else 不可
		rts


*************************************************
*		&else-if=&elsif			*
*************************************************

＆else_if::
＆elsif::
		bsr	else_check
		bsr	block_check

		movea.l	(q_ptr,pc),a5
		movea.l	(Q_next_ptr,a5),a1
		tst.b	(Q_if_flag,a5)
		bmi	else_if_false		;&if 成立済み

		moveq	#0,d6
		bra	if_elsif

* ブロックを飛ばす
else_if_false:
		bsr	skip_block
		move.l	a1,(Q_next_ptr,a5)
		st	(Q_if_next,a5)		;&if 成立
		rts


*************************************************
*		&unless				*
*************************************************

＆unless::
		moveq	#1,d6
		ror.l	#1,d6			;bset #IF_UNLESS,d6
		bra.s	if_unless


*************************************************
*		&if				*
*************************************************

IF_UNLESS:	.equ	31
IF_CONST:	.equ	15
IF_EXP:		.equ	14
IF_FILE:	.equ	7
IF_PAREN:	.equ	6


＆if::
		moveq	#0,d6
if_unless:
		bsr	block_check
if_elsif:
		bsr	if_exp

		movea.l	(q_ptr,pc),a5
		tst.b	(Q_abort,a5)
		bne	if_error2		;ファイル検査子のエラー
		move.l	d0,d1
		bsr	if_get_char
		bne	if_error		;引数が残っている
		move.l	d1,d0

		btst	#IF_EXP,d6
		bne	if_exist_exp

		move.l	d0,d1
		moveq	#0,d0
		move	(＠status,pc),d0
		btst	#IF_CONST,d6
		beq	if_exist_exp		;全て省略なら、@status != 0

		cmp.l	d1,d0			;定数だけなら、@status == 定数
		seq	d0
		moveq	#1,d1
		and.l	d1,d0
if_exist_exp:
		tst.l	d6
		bpl	@f
		bsr	if_cmp_d0_0		;&unless なら真偽値を逆にする
@@:
* 式の値が真かどうかを調べる
		movea.l	(Q_next_ptr,a5),a1
		tst.l	d0
		beq	if_false

* ブロックを実行する
*if_true:
		bsr	free_token_buf
		bsr	execute_block
		move.l	a1,(Q_next_ptr,a5)
		st	(Q_if_next,a5)		;&if 成立
		rts

* ブロックを飛ばす
if_false:
		bsr	skip_block
		move.l	a1,(Q_next_ptr,a5)
		move.b	#$01,(Q_if_next,a5)	;&if 不成立
		rts

if_error:
		move.l	(Q_funcname,a5),-(sp)	;関数名
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#MES_MERR6,d0
		bra	@f
if_error2:
		moveq	#MES_MERR2-1,d0
		add.b	(Q_abort,a5),d0		;&merr2 / &merr3
@@:
		st	(Q_abort,a5)
		jmp	(PrintMsgCrlf)
**		rts


* d0 と 0 を比較する
* in	d0.l	数値
* out	d0.l	0:不一致 1:一致
*	ccr	<tst.l d0> の結果
* break	d1

if_cmp_d0_0:
		tst.l	d0
		seq	d0
		moveq	#1,d1
		and.l	d1,d0
		rts


* NUL 以外の文字を収得する
* i/o	d7.l	引数の数
*	a0.l	引数のアドレス
* out	d0.l	0:引数なし それ以外:d0.b が収得した文字
*	ccrZ	1:引数なし 0:引数あり

if_get_char_next:
		subq.l	#1,d7
if_get_char::
		move.l	d7,d0
		beq	@f
		move.b	(a0)+,d0
		beq	if_get_char_next
if_exp_end:
@@:		rts


* <式> の値を計算する
if_exp::
		bsr	if_get_char
		beq.s	if_exp_end
		cmpi.b	#'!',d0
		beq	if_exp_not
		subq.l	#1,a0
		bra	if_term
**		rts
if_exp_not:
		bsr	if_term			;! <項>
		bset	#IF_EXP,d6
		bra	if_cmp_d0_0		;真偽値を逆にする
**		rts


* <項> の値を計算する
if_term::
		bsr	if_get_char
		beq	if_term_end
		subq.l	#1,a0
		bsr	if_factor
		move.l	d0,-(sp)
		bsr	if_get_char
		beq	if_term_end2
		subq.l	#1,a0			;演算子があるか調べる
		bsr	if_get_op_type
		bpl	@f
if_term_end2:
		move.l	(sp)+,d0		;演算子なし
if_term_end:
		rts
@@:
		move	d0,-(sp)		;<因子> <条件演算子> <因子>
		bsr	if_factor
		move	(sp)+,d2		;d2=演算子
		move.l	(sp)+,d1		;d1=左辺 d0=右辺

		bset	#IF_EXP,d6
		move	(@f,pc,d2.w),d2
		cmp.l	d1,d0
		jmp	(@f,pc,d2.w)
@@:
		.dc	if_term_eq-@b		;==
		.dc	if_term_ne-@b		;!=
		.dc	if_term_hi-@b		;<
		.dc	if_term_cc-@b		;<=
		.dc	if_term_cs-@b		;>
		.dc	if_term_ls-@b		;>=
if_term_eq:
		seq	d0
		bra	@f
if_term_ne:
		sne	d0
		bra	@f
if_term_hi:
		shi	d0
		bra	@f
if_term_cc:
		scc	d0
		bra	@f
if_term_cs:
		scs	d0
		bra	@f
if_term_ls:
		sls	d0
@@:
		moveq	#1,d1
		and.l	d1,d0
		rts


* <因子> の値を計算する
if_factor::
		bsr	if_get_char
		beq	if_fac_end
		cmpi.b	#'(',d0
		beq	if_fac_paren

		subq.l	#1,a0
		jsr	(atoi_a0)
		beq	if_fac_const
		bsr	if_get_atvalue
		bpl	if_fac_atvalue
		cmpi.b	#'-',(a0)
		bne	@f
		bsr	if_file_test
		bra	if_fac_file_test
@@:
		bsr	if_command
if_fac_command:
if_fac_atvalue:
if_fac_file_test:
		bset	#IF_EXP,d6		;<＠変数>、<ファイル検査>、<コマンド>
if_fac_end:
		rts
if_fac_const:
		bset	#IF_CONST,d6		;<定数>
		rts

if_fac_paren:
		clr.l	-(sp)
		bsr	if_get_char
		beq	@f
		cmpi.b	#')',d0
		beq	@f			;( )
		addq.l	#4,sp
		subq.l	#1,a0

		move.b	d6,-(sp)		;( <式> )
		bset	#IF_PAREN,d6
		bsr	if_exp
		move.b	(sp)+,d6

		move.l	d0,-(sp)
		bsr	if_get_char
		beq	@f
		cmpi.b	#')',d0
		beq	@f
		subq.l	#1,a0			;末尾に ) がない
@@:
		move.l	(sp)+,d0
		rts


* 演算子の種類を調べる
* in	a0.l	文字列
* out	a0.l	演算子の場合、演算子の次の文字
*		演算子でない場合は変わらない
*	d0.l	-2:演算子ではない
*		 0:==	2:!=	4:<	6:<=	8:>	10:>=
*	ccr	<tst.l d0> の結果

if_get_op_type::
		move.b	(a0)+,-(sp)
		move	(sp)+,d0
		move.b	(a0)+,d0
		cmpi	#'==',d0
		beq	1f
		cmpi	#'!=',d0
		beq	2f
		cmpi	#'<=',d0
		beq	6f
		cmpi	#'>=',d0
		beq	9f
		subq.l	#1,a0
		lsr	#8,d0
		cmpi.b	#'<',d0
		beq	4f
		cmpi.b	#'>',d0
		beq	8f
		subq.l	#1,a0
		moveq	#-2,d0
		rts
1:		moveq	#0,d0
		rts
2:		moveq	#2,d0
		rts
4:		moveq	#4,d0
		rts
6:		moveq	#6,d0
		rts
8:		moveq	#8,d0
		rts
9:		moveq	#10,d0
		rts


* ＠変数の値を収得する
* in	a0.l	文字列
* out	a0.l	＠変数の場合、＠変数の次の文字
*		＠変数でない場合は変わらない
*	d0.l	$0000～$ffff:＠変数の値
*		-1:＠変数ではない
*	ccr	<tst.l d0> の結果

if_get_atvalue::
		PUSH	d1-d2/a2
		moveq	#0,d2

		move	(＠status,pc),d2
		lea	(str_atstatus,pc),a1
		bsr	if_get_atval_sub
		subq	#.sizeof.('@st'),d0
		bcc	if_get_atval_found

		move	(＠exitcode,pc),d2
		lea	(str_atexitcode,pc),a1
		bsr	if_get_atval_sub
		subq	#.sizeof.('@ex'),d0
		bcc	if_get_atval_found

		move	(＠buildin,pc),d2
		lea	(str_atbuildin,pc),a1
		bsr	if_get_atval_sub
		subq	#.sizeof.('@bu'),d0
		bcc	if_get_atval_found

		moveq	#-1,d0
		bra	@f
if_get_atval_found:
		addq.l	#.sizeof.('@st'),a0
		adda.l	d0,a0
		move.l	d2,d0
@@:
		POP	d1-d2/a2
		rts

if_get_atval_sub:
		lea	(a0),a2
@@:
		tst.b	(a1)
		beq	@f
		cmpm.b	(a1)+,(a2)+
		beq	@b
		subq.l	#1,a2
@@:
		move.l	a2,d0
		sub.l	a0,d0			;一致した文字数
		rts


if_ftst_error:
		moveq	#1<<0,d0		;未対応のファイル検査子
		bra	@f
if_ftst_error2:
		moveq	#1<<1,d0		;ファイル名がない
@@:		movea.l	(q_ptr,pc),a5
		or.b	d0,(Q_abort,a5)
if_ftst_not_test:
		moveq	#-1,d0
		rts
* ファイル検査
if_file_test::
		lea	(a0),a1
		cmpi.b	#'-',(a1)+
		bne	if_ftst_not_test	;ファイル検査子ではない
		move.b	(a1)+,d0
		beq	if_ftst_error		;検査子の記述がおかしい
		tst.b	(a1)+
		bne	if_ftst_error		;〃

		lea	(file_opt_list+12,pc),a2
		moveq	#12-1,d1
@@:
		cmp.b	-(a2),d0
		dbeq	d1,@b
		bne	if_ftst_error		;未対応の検査子
@@:
		lea	(a1),a0
@@:
		subq.l	#1,d7
		beq	if_ftst_error2		;ファイル名がない
		tst.b	(a0)+
		beq	@b
		subq.l	#1,a0

* 直前に '(' があるなら、')' までをファイル名と見なす
		lea	(a0),a1			;ファイル名から特殊コードを削除する
		lea	(a0),a3
		moveq	#0,d4
		bclr	#IF_FILE,d6
if_ftst_paren_loop:
		move.b	(a0)+,d0
		beq	if_ftst_paren_end
		cmpi.b	#TC_FILE,d0
		bne	@f
		bchg	#IF_FILE,d6
		bra	if_ftst_paren_loop
@@:
		cmpi.b	#TC_ESC,d0
		beq	1f
		tst.b	d6			;btst #IF_FILE,d6
		bmi	@f
		cmpi.b	#'(',d0
		beq	if_ftst_o_paren		;'(' 発見
		cmpi.b	#')',d0
		beq	if_ftst_c_paren		;')' 発見
@@:
		move.b	d0,(a1)+
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	if_ftst_paren_loop
1:		move.b	(a0)+,(a1)+
		bra	if_ftst_paren_loop
if_ftst_o_paren:
		addq.l	#1,d4			;'(' ネスト開始
		bra	@b
if_ftst_c_paren:
		subq.l	#1,d4
		bcc	@b			;')' ネスト終了
		moveq	#0,d4
		btst	#IF_PAREN,d6
		beq	@b			;'(' なしの ')' はそのまま通す
if_ftst_paren_end:
		move.b	-(a0),d3
		clr.b	(a1)
		exg	a0,a3			;a3=次の引数

		lea	(tmp_buf),a2
		pea	(a2)
		pea	(a0)
		DOS	_NAMECK
		addq.l	#8,sp
		lea	(NAMECK_Drive,a2),a1
		STREND	a1			;パス名末尾
		tst.l	d0
		bmi	9f
		not.b	d0
		bne	8f			;ファイル名

* ディレクトリ名
		clr.b	-(a1)			;最後のパスデリミタを削除
		tst.b	(NAMECK_Path,a2)
		bne	7f

* ドライブ名のみ("d:")になった場合
		pea	(NAMECK_Path+2,a2)
		pea	(NAMECK_Drive,a2)
		clr	-(sp)			;ASSIGN_GET
		DOS	_ASSIGN
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	9f

		move.b	(MINTSLASH),(a1)+
		moveq	#1<<DIRECTORY,d0
		bra	9f
* ファイル名
8:
		move.l	a1,-(sp)
		lea	(NAMECK_Name,a2),a0
		STRCPY	a0,a1,-1
		lea	(NAMECK_Ext,a2),a0
		STRCPY	a0,a1
		movea.l	(sp)+,a1
7:
		lea	(NAMECK_Drive,a2),a0
		jsr	(to_mintslash)

		move	#-1,-(sp)
		pea	(a2)
		DOS	_CHMOD
		addq.l	#6,sp
9:
		lea	(a3),a0
		move.b	d3,-(a0)

		add	d1,d1
		move	(@f,pc,d1.w),d1
		tst.l	d0
		jmp	(@f,pc,d1.w)
@@:
		.dc	if_ftst_r-@b
		.dc	if_ftst_w-@b
		.dc	if_ftst_x-@b
		.dc	if_ftst_s-@b
		.dc	if_ftst_h-@b
		.dc	if_ftst_l-@b
		.dc	if_ftst_d-@b
		.dc	if_ftst_f-@b
		.dc	if_ftst_e-@b
		.dc	if_ftst_z-@b
		.dc	if_ftst_T-@b
		.dc	if_ftst_B-@b
file_opt_list:
		.dc.b	'rwxshldfezTB'
		.even

* -r : 読み込み可能(!DIRECTORY && !VOLUME)
if_ftst_r:
		moveq	#1<<DIRECTORY+1<<VOLUME,d1
		bra	@f

* -w : 書き込み可能(!READONLY && !SYSTEM && !DIRECTORY && !VOLUME)
if_ftst_w:
		moveq	#1<<DIRECTORY+1<<VOLUME+1<<SYSTEM+1<<READONLY,d1
@@:		tst.l	d0
		bmi	if_ftst_false
		and.b	d0,d1
		beq	if_ftst_true
		bra	if_ftst_false

* -x : 実行可能(EXEC)
if_ftst_x:
		add.b	d0,d0
		bra	@f

* -s : システム属性(SYSTEM)
if_ftst_s:
		lsr.b	#SYSTEM+1,d0
		bra	@f

* -h : 隠し属性(HIDDEN)
if_ftst_h:
		lsr.b	#HIDDEN+1,d0
		bra	@f

* -l : シンボリックリンク(LINK)
if_ftst_l:
		lsl.b	#8-LINK,d0
		bra	@f

* -d : ディレクトリ(DIRECTORY)
if_ftst_d:
		lsl.b	#8-DIRECTORY,d0
@@:
		bcc	if_ftst_false
		tst.l	d0
		bmi	if_ftst_false
		bra	if_ftst_true

* -f : 通常ファイル(ARCHIVE 以外==0)
if_ftst_f:
		moveq	#1<<ARCHIVE,d1
		cmp.l	d0,d1
		beq	if_ftst_true
		bra	if_ftst_false

* -e : ファイルが存在する(ワイルドカード対応)
if_ftst_e:
		bpl	if_ftst_true

		lea	(256,a2),a3		;tmp_buf+256
		move	#$ff,-(sp)
		pea	(a2)
		pea	(a3)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	if_ftst_false

		lea	(FILES_FileName,a3),a3
		STRCPY	a3,a1
		bra	if_ftst_true

* -z : ファイルサイズ==0(&& !DIRECTORY && !VOLUME)
if_ftst_z:
		bmi	if_ftst_false
		andi.b	#1<<DIRECTORY+1<<VOLUME,d0
		bne	if_ftst_false

		clr	-(sp)
		pea	(a2)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	if_ftst_false

		move	#SEEK_END,-(sp)		;ファイル末尾に移動
		clr.l	-(sp)
		move	d0,-(sp)
		DOS	_SEEK
		move.l	d0,d1
		DOS	_CLOSE
		addq.l	#8,sp
		tst.l	d1
		beq	if_ftst_true
		bra	if_ftst_false

* -T : テキストファイル(&& !DIRECTORY && !VOLUME)
if_ftst_T:
		moveq	#0,d1
		bra	@f

* -B : バイナリファイル(&& !DIRECTORY && !VOLUME)
if_ftst_B:
		moveq	#1,d1
@@:		tst.l	d0
		bmi	if_ftst_false
		andi.b	#1<<DIRECTORY+1<<VOLUME,d0
		bne	if_ftst_false

		clr	-(sp)
		pea	(a2)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	if_ftst_false

		lea	(1024),a1
		suba.l	a1,sp			;lea (-1024,sp),sp
		lea	(sp),a3

		move.l	a1,-(sp)		;move.l #1024,-(sp)
		pea	(a3)
		move	d0,-(sp)
		DOS	_READ
		move.l	d0,d2			;d2 = データサイズ
		DOS	_CLOSE
		lea	(10,sp),sp
		move.l	d2,d0
		bmi	@f
		exg	a0,a3
		bsr	if_ftst_is_binary
		lea	(a3),a0
@@:
		adda.l	a1,sp			;lea (1024,sp),sp
		cmp.l	d0,d1
		beq	if_ftst_true
if_ftst_false:
		moveq	#0,d0
		rts
if_ftst_true:
		jsr	(set_user_value_match_a2)
		moveq	#1,d0
		rts


* テキスト/バイナリ判別
* in	d0.l	データサイズ
*	a0.l	バッファアドレス
* out	d0.l	0:テキストファイル 1:バイナリファイル

if_ftst_is_binary::
		PUSH	d1-d3/a0
		move.l	d2,d0

		moveq	#$40+2,d0		;X 形式実行ファイルのチェック
		cmp.l	d0,d2
		bcs	@f
		cmpi	#'HU',(a0)
		bne	@f
		cmpi	#2,(2,a0)
		bls	if_is_bin_file_true
@@:
		moveq	#0,d0
		moveq	#10-1,d1
		move.l	#1<<BS+1<<TAB+1<<LF+1<<CR+1<<ESC,d3
		bra	if_is_bin_file_next
if_is_bin_file_loop:
		move.b	(a0)+,d0
		bgt	@f			;ASCII
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	if_is_bin_file_next	;一バイト片仮名

		addq.l	#1,a0			;二バイト文字
		dbra	d2,if_is_bin_file_next
		bra	if_is_bin_file_true
@@:
		subi.b	#$20,d0
		bcc	if_is_bin_file_next	;一バイト文字
		btst	d0,d3
		bne	if_is_bin_file_next	;テキストファイルに含まれる制御記号
if_is_bin_file_ctrl:
		dbra	d1,if_is_bin_file_next
if_is_bin_file_true:
		moveq	#1,d0
		bra	@f
if_is_bin_file_next:
		dbra	d2,if_is_bin_file_loop
		moveq	#0,d0
@@:		POP	d1-d3/a0
		rts


* コマンド実行
if_command::
* 直前に '(' があるなら、')' までをトークンと見なす
		lea	(a0),a1
		moveq	#0,d4
		move.l	d7,d5
if_cmd_paren_loop:
		bclr	#IF_FILE,d6
if_cmd_paren_loop2:
		move.b	(a1)+,d0
		beq	if_cmd_paren_next
		cmpi.b	#TC_FILE,d0
		bne	@f
		bchg	#IF_FILE,d6
		bra	if_cmd_paren_loop2
@@:
		cmpi.b	#TC_ESC,d0
		beq	1f
		tst.b	d6			;btst #IF_FILE,d6
		bmi	@f
		cmpi.b	#'(',d0
		beq	if_cmd_o_paren		;'(' 発見
		cmpi.b	#')',d0
		beq	if_cmd_c_paren		;')' 発見
@@:
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	if_cmd_paren_loop2
1:		addq.l	#1,a1
		bra	if_cmd_paren_loop2
if_cmd_o_paren:
		addq.l	#1,d4			;'(' ネスト開始
		bra	if_cmd_paren_loop2
if_cmd_c_paren:
		subq.l	#1,d4
		bcc	if_cmd_paren_loop2	;')' ネスト終了
		moveq	#0,d4
		btst	#IF_PAREN,d6
		beq	if_cmd_paren_loop2	;'(' なしの ')' はそのまま通す

		clr.b	-(a1)			;')' を NUL に書き換えておく
		tst.b	(-1,a1)
		beq	@f
		addq.l	#1,d7
		bra	@f
if_cmd_paren_next:
		subq.l	#1,d5
		bne	if_cmd_paren_loop
		subq.l	#1,a1
@@:
* d5 = コマンド用のトークンを除いた残りの引数の数(0～)
		sub.l	d5,d7			;トークン数(1～)
		move.l	a1,d0
		sub.l	a0,d0
		addq.l	#1,d0			;トークンバッファのサイズ

		bsr	malloc_from_same_side
		tst.l	d0
		bmi	if_cmd_memory_error

		movea.l	d0,a2
@@:		move.b	(a0)+,(a2)+		;トークンをバッファに転送
		cmpa.l	a0,a1
		bcc	@b

		movea.l	(q_ptr,pc),a5
**		move.b	(Q_if_next,a5),d1
		movea.l	(Q_funcname,a5),a2

		movea.l	d0,a0			;トークン列のアドレス
		move.l	d7,d0			;トークン数
		bsr	execute_command

		move.l	a2,(Q_funcname,a5)
**		move.b	d1,(Q_if_next,a5)

if_cmd_memory_error:
		lea	(a1),a0			;次の引数
		move.l	d5,d7
		beq	@f
		move.b	#')',(a0)		;書き換えた ')' を元に戻す
@@:
		moveq	#0,d0
		move	(＠status,pc),d0
**		tst.l	d0
		rts


* 式の仕様
*	<式> := ! <項> | <項>
*	<項> := <因子> | <因子> <条件演算子> <因子>
*	<因子> := ( <式> ) | <数>
*	<数> := <定数> | <＠変数> | <ファイル検査> | <コマンド>


*************************************************
*		&foreach			*
*************************************************

＆foreach::
		bsr	block_check

		moveq	#0,d6			;-n
		lea	(str_ul,pc),a3		;デフォルトの変数名
		suba.l	a4,a4			;単語列(NULL なら無限ループ)
foreach_arg_loop1:
		subq.l	#1,d7
		bcs	foreach_infinity	;&foreach { ... }
		move.b	(a0)+,d0
		beq	foreach_arg_loop1
		cmpi.b	#'(',d0
		beq	foreach_o_paren		;変数名省略
		cmpi.b	#'-',d0
		bne	foreach_name		;変数名指定あり
		cmpi.b	#'n',(a0)
		bne	foreach_name
		tst.b	(1,a0)
		bne	foreach_name
*foreach_opt_n:
		addq.l	#.sizeof.('-n')+1,a0	;-n : 範囲指定抑制
		moveq	#-1,d6
		bra	foreach_arg_loop1
foreach_name:
		lea	(-1,a0),a3
@@:		tst.b	(a0)+
		bne	@b
foreach_arg_loop2:
		subq.l	#1,d7
		bcs	foreach_infinity	;&foreach name { ... }
		move.b	(a0)+,d0
		beq	foreach_arg_loop2
		cmpi.b	#'(',d0
		beq	foreach_o_paren
*foreach_no_o_paren:
		subq.l	#1,a0			;先頭の括弧なし
		bra	foreach_no_c_paren	;末尾のもないものと見なす
foreach_o_paren:
		tst.b	(a0)
		bne	@f
		addq.l	#1,a0			;最初の単語が '(' だけなら飛ばす
		subq.l	#1,d7
		bcs	foreach_infinity	;&foreach ( { ... }
@@:
		lea	(a0),a2
		move.l	d7,d2
		beq	1f			;括弧を含めて、単語列が単一の引数
@@:
		tst.b	(a2)+			;最後の引数まで移動
		bne	@b
		subq.l	#1,d2
		bne	@b
1:
		cmpi.b	#')',(a2)		;最後の単語が ')' だけなら
		bne	@f			;引数ごと削除する
		tst.b	(1,a2)
		bne	@f
		subq.l	#1,d7
		bcs	foreach_infinity	;&foreach ( ) { ... }
@@:
foreach_arg_loop3:
		move.b	(a2)+,d0
		beq	foreach_no_c_paren	;末尾の括弧なし
		cmpi.b	#')',d0
		beq	foreach_c_paren
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	foreach_arg_loop3
		addq.l	#1,a2
		bra	foreach_arg_loop3
foreach_c_paren:
		tst.b	(a2)
		bne	foreach_arg_loop3
		clr.b	-(a2)			;末尾の括弧を消す
foreach_no_c_paren:
		lea	(a0),a4
foreach_infinity:

		.offset	0
~fe_next_ptr:	.ds.l	1
~fe_macro:	.ds.l	1
~fe_buf_top:	.ds.l	1
~fe_buf_size:	.ds.l	1
sizeof_fe:
		.text

		movea.l	(q_ptr,pc),a5
		move.l	(Q_buf_size,a5),-(sp)
		move.l	(Q_buf_top,a5),-(sp)
		move.l	(Q_macro,a5),-(sp)
		move.l	(Q_next_ptr,a5),-(sp)
foreach_loop:
		clr.b	d6			;範囲指定フラグ
		move.l	a4,d0
		beq	foreach_inf1
		tst	d6
		bmi	foreach_regular_word	;範囲指定禁止

* A..Z という形式か調べる
		lea	(a4),a0
		move.b	(a0)+,d0
		beq	foreach_regular_word
		lsr.b	#5,d0
		btst	d0,#%10010000
		bne	foreach_regular_word
		move.b	(a0)+,d0
		cmpi.b	#'.',d0
		bne	foreach_regular_word
		cmp.b	(a0)+,d0
		bne	foreach_regular_word
		move.b	(a0)+,d0
		beq	foreach_regular_word
		lsr.b	#5,d0
		btst	d0,#%10010000
		bne	foreach_regular_word
		tst.b	(a0)+
		bne	foreach_regular_word

* 範囲指定だった
		move.b	(a4)+,d6		;開始文字
		addq.l	#.sizeof.('..'),a4
		move.b	(a4),d5			;終了文字
foreach_loop2:
		move.b	d6,(a4)
foreach_regular_word:
		lea	(a3),a1
		lea	(a4),a2
		jsr	(set_user_value_a1_a2)	;変数を設定
foreach_inf1:

		move.l	(~fe_buf_size,sp),d0
		move.l	d0,(Q_buf_size,a5)

		bsr	malloc_from_same_side
		move.l	d0,(Q_buf_top,a5)
		bmi	foreach_end

		movea.l	d0,a2
		movea.l	(~fe_buf_top,sp),a0
		sub.l	a0,d0
		STRCPY	a0,a2			;madoka を複製
		move.l	(~fe_macro,sp),d1
		beq	@f
		add.l	d0,d1
@@:		move.l	d1,(Q_macro,a5)		;マクロ位置を更新

		movea.l	(~fe_next_ptr,sp),a1
		adda.l	d0,a1
		move.l	a1,(Q_next_ptr,a5)	;次回実行アドレスを更新

		bsr	execute_block

  move.l (Q_buf_top,a5),d0
  bsr free_unfold_buffer

		tst.b	(Q_abort,a5)
		bne	foreach_end

		tst.b	(Q_skip,a5)
		beq	@f
		sf	(Q_skip,a5)		;&continue が実行された
		bmi	foreach_end		;&break 〃
@@:
		move.l	a4,d0
		beq	foreach_inf2
		tst.b	d6
		beq	foreach_next
foreach_incdec:
		cmp.b	d6,d5
		beq	foreach_next		;範囲指定が終了した
		bhi	1f
		subq.b	#1,d6
		bra	@f
1:		addq.b	#1,d6
@@:
		move.b	d6,d0
		lsr.b	#5,d0
		btst	d0,#%10010000
		bne	foreach_incdec		;二バイト文字は通過する

		jsr	(break_check)
		beq	foreach_loop2
		bra	foreach_end
foreach_next:
		subq.l	#1,d7
		bcs	foreach_end		;単語列を全て処理した
@@:
		tst.b	(a4)+			;次の単語に移動
		bne	@b
foreach_inf2:
		jsr	(break_check)
		beq	foreach_loop
foreach_end:
		move.l	(sp)+,(Q_next_ptr,a5)
		move.l	(sp)+,(Q_macro,a5)
		move.l	(sp)+,(Q_buf_top,a5)
		move.l	(sp)+,(Q_buf_size,a5)

		movea.l	(Q_next_ptr,a5),a1
		bsr	skip_block
		move.l	a1,(Q_next_ptr,a5)
		rts


*************************************************
*		&continue=&next			*
*************************************************

＆continue::
＆next::
		movea.l	(q_ptr,pc),a5
		move.b	#$01,(Q_skip,a5)
		rts


*************************************************
*		&break=&last			*
*************************************************

＆break::
＆last::
		movea.l	(q_ptr,pc),a5
		st	(Q_skip,a5)
		rts


*************************************************
*		&prefix				*
*************************************************

＆prefix::
		move.l	d7,d0
		beq	prefix_end		;引数なし

		move	#$8000,d5
		moveq	#1,d6
		bra	prefix_next
prefix_loop:
		lea	(a0),a1
		cmpi.b	#'-',(a1)+
		bne	@f
		cmpi.b	#'n',(a1)+
		bne	@f
		tst.b	(a1)
		bne	@f
*prefix_opt_n:
		moveq	#0,d5			;-n : 画面初期化抑制
		bra	prefix_skip
@@:
		jsr	(atoi_a0)
		bne	prefix_error
		tst.b	(a0)+
		bne	prefix_error

		subq.l	#1,d0			;1～8 -> bit0～7
		moveq	#8-1,d1
		cmp.l	d1,d0
		bhi	prefix_error

		bchg	d0,(prefix_flag)	;フラグ反転
		bra	prefix_next
prefix_error:
		moveq	#0,d6
prefix_skip:
		tst.b	(a0)+
		bne	prefix_skip
prefix_next:
		subq.l	#1,d7
		bcc	prefix_loop

		or	d5,(init_sc_flag)
		move	d6,d0
prefix_end:
		jmp	(set_status)
**		rts


*************************************************
*		&set-opt			*
*************************************************

＆set_opt::
＆set_option::
		movea.l	(q_ptr,pc),a5
		subq.l	#1,d7
		bcs	clear_cmd_sw		;引数省略時はクリア
set_opt_loop:
		move.b	(a0),d0
		beq	set_opt_next
		moveq	#'-',d1
		cmpi.b	#'+',d0
		beq	set_opt_append		;先頭が '+' なら初期化しない
		cmp.b	d1,d0
		bne	set_opt_next
		bsr	clear_cmd_sw
set_opt_append:
		move.b	d1,(a0)			;'+' を '-' に書き換える
		lea	(a0),a1
		bsr	analyze_cmd_sw
set_opt_next:
		tst.b	(a0)+
		bne	set_opt_next
		subq.l	#1,d7
		bcc	set_opt_loop
		rts


*************************************************
*		&command-history		*
*************************************************

＆command_history::
		bra	call_command_history
**		rts


call_command_history:
		moveq	#-1,d0
		neg	d0			;move.l #$ffff_0001,d0
call_command_history2:
		jsr	(command_history)
		movea.l	(q_ptr,pc),a5
		beq	@f
		st	(Q_abort,a5)
@@:		rts


*************************************************
*		&command-history-menu		*
*************************************************

＆command_history_menu::
		jsr	(command_history_menu)
		moveq	#0,d7			;引数なし
		bra	call_command_history2
**		rts


* Data Section -------------------------------- *

**		.data
		.even

unfold_buf_ptr:  .dc.l unfold_buf
cmdline_buf_ptr: .dc.l cmdline_buf

subwin_rl::	SUBWIN	8,8,80,1,NULL,NULL

str_mintshell:	.dc.b	'MINTSHELL',0
str_home:	.dc.b	'HOME',0
str_nul:	.dc.b	'NUL',0
str_0:		.dc.b	'0',0
str_1:		.dc.b	'1',0
str_ul:		.dc.b	'_'
str_nulstr:	.dc.b	0

str_left:	.dc.b	'left',0
str_right:	.dc.b	'right',0
str_off:	.dc.b	'off',0
str_max:	.dc.b	'max',0
str_half:	.dc.b	'half',0

str_atexitcode:	.dc.b	'@exitcode',0
str_atbuildin:	.dc.b	'@buildin',0
str_atstatus:	.dc.b	'@status',0

str_argv0:	.dc.b	'argv0',0
str_argv:	.dc.b	'argv',0


* Block Storage Section ----------------------- *

**		.bss
		.even

q_ptr::		.ds.l	1

＠exitcode::	.ds	1
＠buildin::	.ds	1
＠status::	.ds	1

init_sc_flag::	.ds	1

debug_flag::	.ds.b	1
prefix_flag:	.ds.b	1

unfold_buf_inuse: .ds.b 1


* Block Storage Section ----------------------- *

		.bss
		.even

tmp_buf:	.ds.b	512

schr_tbl:	.ds.b	128

unfold_buf:  .ds.b UNFOLD_BUF_SIZE
cmdline_buf: .ds.b CMDLINE_BUF_SIZE


		.end

* End of File --------------------------------- *
