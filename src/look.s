# look.s - &look-file
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

*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
*┃ 										 ┃┐
*┃ 		■                 [&look-file]               ■		 ┃│
*┃ 		                                                		 ┃│
*┃ 		■            [Release version 1.5F]          ■		 ┃│
*┃ 										 ┃│
*┃ 							$Author: LEAZA/BEL/KIRAH ┃│
*┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛│
*  └───────────────────────────────────────┘
*
*			THIS is TEXT/BINARY FILE VIEWER for MINT


* Include File -------------------------------- *

		.include	mrl.mac
		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	sysval.def

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac
		.include	gm_internal.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	get_curdir_a1
* gvon.s
		.xref	_gm_internal_tgusemd
		.xref	key_token,_match_token
* madoka3.s
		.xref	＠buildin,＠status
		.xref	execute_quick_no,free_token_buf
* mint.s
		.xref	mint_start,MINTSLASH
		.xref	is_mb,is_mbhalf,ctypetable
		.xref	ChangeFnckey_lookfile,ChangeFnckey
		.xref	print_screen,clear_tvram
		.xref	dos_drvctrl_d1,dos_kflush
		.xref	to_fullpath_file
* outside.s
		.xref	＆v_bell
		.xref	get_condrv_work
		.xref	set_user_value_a1_a2
		.xref	atoi_a1
* patternmatch.s
		.xref	_fre_compile,_fre_match,_ignore_case
		.xref	_fpr,_fque,_frec_question,_fre_jmptbl,_frec_normal
		.xref	_text_end_address
* window.s
		.xref	win_tab,win_print_char
		.xref	win_draw_mb_char,win_draw_char,win_draw_half


* Constant ------------------------------------ *

USE_IOCS:	.equ	1			;ラスターコピーに IOCS を使う

KB_TBL_SIZE:	.equ	$6d

YAR_TABLE_SIZE:	.equ	88

* prefix
PREFIX_NUL:	.equ	0
PREFIX_META:	.equ	2
PREFIX_CTRLX:	.equ	4

* キーバインド番号
		.offset	0
KEY_NUL:	.ds	1
KEY_LINEUP:	.ds	1
KEY_LINEDW:	.ds	1
KEY_HLFPGUP:	.ds	1
KEY_HLFPGDW:	.ds	1
KEY_HLFRLUP:	.ds	1
KEY_HLFRLDW:	.ds	1
KEY_PAGEUP:	.ds	1
KEY_PAGEDW:	.ds	1
KEY_ROLLUP:	.ds	1
KEY_ROLLDW:	.ds	1
KEY_GOHOME:	.ds	1
KEY_GOLAST:	.ds	1
KEY_JUMP:	.ds	1
KEY_JUMP1:	.ds	1
KEY_JUMP2:	.ds	1
KEY_JUMP3:	.ds	1
KEY_JUMP4:	.ds	1
KEY_JUMP5:	.ds	1
KEY_JUMP6:	.ds	1
KEY_JUMP7:	.ds	1
KEY_JUMP8:	.ds	1
KEY_JUMP9:	.ds	1
KEY_JUMP$:	.ds	1
KEY_SCHFW:	.ds	1
KEY_SCHFWN:	.ds	1
KEY_SCHBW:	.ds	1
KEY_SCHBWN:	.ds	1
KEY_ISCHFW:	.ds	1
KEY_ISCHBW:	.ds	1
KEY_REGSCH:	.ds	1
KEY_REGSCHN:	.ds	1
KEY_REG:	.ds	1
KEY_CR:		.ds	1
KEY_TAB:	.ds	1
KEY_TABSIZE:	.ds	1
KEY_LINENUM:	.ds	1
KEY_QUIT:	.ds	1
KEY_EDIT:	.ds	1
KEY_DUMP:	.ds	1
KEY_COLOR:	.ds	1
KEY_CASE:	.ds	1
KEY_META:	.ds	1
KEY_CTRLX:	.ds	1
KEY_WRITE:	.ds	1
KEY_MARK:	.ds	1
KEY_GOTOMARK:	.ds	1
KEY_EXG:	.ds	1
KEY_CODE:	.ds	1
KEY_VERSION:	.ds	1


* BG から FG への動作要求番号
		.offset	0
REQ_NUL:	.ds	1
REQ_QUIT:	.ds	1
REQ_JUMP:	.ds	1
REQ_SCHFW:	.ds	1
REQ_SCHFWN:	.ds	1
REQ_SCHBW:	.ds	1
REQ_SCHBWN:	.ds	1
REQ_MARK:	.ds	1
REQ_GOMARK:	.ds	1
REQ_EXG:	.ds	1
REQ_WRITE:	.ds	1
REQ_CODE:	.ds	1
REQ_VERSION:	.ds	1
REQ_DUMP:	.ds	1
REQ_COLOR:	.ds	1
REQ_CASE:	.ds	1
REQ_REG:	.ds	1
REQ_CR:		.ds	1
REQ_TAB:	.ds	1
REQ_TABSIZE:	.ds	1
REQ_NUM:	.ds	1
REQ_ISCHFW:	.ds	1
REQ_ISCHBW:	.ds	1
REQ_REGSCH:	.ds	1
REQ_REGSCHN:	.ds	1
REQ_BELL:	.ds	1

* fg_stat のビット意味
COM_READY:	.equ	7			;１フレーム読込終了
COM_JUMPL:	.equ	3			;行番号ジャンプ(ライン付き)
COM_JUMP:	.equ	2			;行番号ジャンプ
COM_REQ:	.equ	1			;表処理待
COM_READ:	.equ	0			;読込中


* Macro --------------------------------------- *

GETBUFPTR:	.macro	ea,dst
		move.l	ea,dst			;何もしない
		.endm

GETLINENUM:	.macro	ea,dst
		move.l	ea,dst
		cmpi.l	#-1,dst
		beq	@skip
		andi.l	#$00ffffff,dst
@skip:
		.endm

GETCOLOR:	.macro	ea,dst
		moveq	#$7f,dst
		and.b	ea,dst
		.endm

GETMES_A1:	.macro	mesno
		moveq	#mesno,d0
		bsr	get_message_a1
		.endm


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* @look セクション解析 ------------------------ *

analyze_@look_section::
		lea	(yar_table),a1
		moveq	#YAR_TABLE_SIZE/4-1,d0
@@:
		clr.l	(a1)+
		dbra	d0,@b
		bra	lk_def_lp
lk_next_line:
		move.b	(a0)+,d0
		cmpi.b	#EOF,d0
		beq	lk_def_end
		cmpi.b	#LF,d0
		bne	lk_next_line
lk_def_lp:
		move.b	(a0)+,d0
		cmpi.b	#'r',d0
		beq	lk_reg_entry		;reg
		cmpi.b	#'b',d0
		beq	lk_def_entry		;bind
		cmpi.b	#'#',d0
		beq	lk_next_line		;#comment
		cmpi.b	#LF,d0
		beq	lk_def_lp
		cmpi.b	#CR,d0
		beq	lk_next_line
lk_def_end:
		rts

* reg
lk_reg_entry:
		bsr	skip_token_tab
		move.b	(a0)+,-(sp)
		move	(sp)+,d0
		move.b	(a0)+,d0
		cmpi	#$8197,d0
		bhi	lk_next_line
		subi	#$8140,d0
		bcs	lk_next_line
@@:
		cmpi.b	#TAB,(a0)+
		beq	@b

		lea	(yar_table),a1
		move.b	-(a0),(a1,d0.w)
		bra	lk_next_line

* bind
lk_def_entry:
		bsr	skip_token_tab		;"bind	" を飛ばす

		moveq	#PREFIX_NUL,d7
		bsr	lpeek
		cmpi.l	#'meta',d0
		beq	lk_def_meta
		cmpi.l	#'ctrl',d0
		beq	lk_def_ctrl
		cmpi.l	#'shif',d0
		bne	lk_def_no_prefix
		cmpi.b	#'t',(4,a0)
		bne	lk_def_no_prefix
		cmpi.b	#TAB,(5,a0)
		bne	lk_def_no_prefix

		subq	#1,d7			;shift
		bra	lk_def_prefix
lk_def_meta:
		cmpi.b	#TAB,(4,a0)
		bne	lk_def_no_prefix

		moveq	#PREFIX_META,d7
		bra	lk_def_meta_and_ctrl_x
lk_def_ctrl_x:
		cmpi.b	#'-',d0
		bne	lk_def_no_prefix
		cmpi.b	#'x',(5,a0)
		bne	lk_def_no_prefix
		cmpi.b	#TAB,(6,a0)
		bne	lk_def_no_prefix

		moveq	#PREFIX_CTRLX,d7
lk_def_meta_and_ctrl_x:
		bsr	skip_token_tab
		bsr	lpeek
		cmpi.l	#'ctrl',d0
		bne	lk_def_no_prefix
lk_def_ctrl:
		move.b	(4,a0),d0
		cmpi.b	#TAB,d0
		bne	lk_def_ctrl_x

		addq	#1,d7
lk_def_prefix:
		bsr	skip_token_tab
lk_def_no_prefix:
		lea	(key_token),a2
		jsr	(_match_token)
		move.l	d0,d5
		bmi	lk_next_line

		bsr	skip_token_tab		;"key	" を飛ばす
		cmpi.b	#'&',(a0)+
		beq	@f
		subq.l	#1,a0
@@:
		lea	(bind_token,pc),a2
		jsr	(_match_token)
		tst.l	d0
		bmi	lk_next_line

		lea	(keybind_normal,pc),a1
		mulu	#KB_TBL_SIZE,d7
		adda	d7,a1
		add.b	d0,d0
		move.b	d0,(a1,d5.w)
		bra	lk_next_line

skip_token_tab:
		moveq	#TAB,d0
@@:		cmp.b	(a0)+,d0
		bne	@b
@@:		cmp.b	(a0)+,d0
		beq	@b
		subq.l	#1,a0
		rts

lpeek:
		subq.l	#4,sp
		movep	(0,a0),d0
		movep	d0,(0,sp)
		movep	(1,a0),d0
		movep	d0,(1,sp)
		move.l	(sp)+,d0
		rts


*************************************************
*		&look-file			*
*************************************************

＆look_file::
		lea	(a5sp),a5
		move.l	#'LOOK',d0
		bsr	change_exec_filename

		lea	(line_num-a5sp,a5),a1
		moveq	#28,d0
		tst	(＄vfun)
		beq	@f
		moveq	#27,d0
@@:
		move.l	d0,(a1)+		;27/28
		addq.l	#1,d0
		move.l	d0,(a1)+		;28/29
		addq.l	#1,d0
		move.l	d0,(a1)+		;29/30
		addq.l	#1,d0
		move.l	d0,(a1)+		;30/31

		moveq	#$73,d0
		tst	(＄vfun)
		beq	@f
		moveq	#$6f,d0
@@:
		move	d0,(a1)+		;$6f/$73 28*4-1/29*4-1
		addq	#1,d0
		move	d0,(a1)+		;$70/$74
		addq	#1,d0
		move	d0,(a1)+		;$71/$75 29*4-3/30*4-3
		addq	#1,d0
		move	d0,(a1)+		;$72/$76 29*4-2/30*4-2
		addq	#1,d0
		move	d0,(a1)+		;$73/$77 29*4-1/30*4-1
		addq	#5,d0
		move	d0,(a1)+		;$78/$7c

* 保持されないフラグを初期化
		clr.b	(tab_size_flag-a5sp,a5)
		clr.b	(look_color_flag-a5sp,a5)
		clr.b	(bs_flag-a5sp,a5)
		clr.b	(esc_flag-a5sp,a5)
		clr.b	(write_path-a5sp,a5)

*	-4	タブ桁数を 4 にする(保存無し)
*	-8	〃	   8 にする(保存無し)
*	-E	二バイトコードを EUC で表示(保存あり)
*	-J	〃		 JIS で表示(保存あり)
*	-S	〃		 S-JIS で表示(保存あり)
*	-v	VIEW 表示で起動(保存あり)
*	-d	DUMP 表示で起動(保存あり)
*	-c	CDMP 表示で起動(保存あり)
*	-r	正規化して表示する(保存あり)
*	-w	ダンプ時の幅とデータサイズを指定(保存あり)
*	-b	バックスペースコードを除去しない(保存無し)
*	-e	エスケープコードを除去しない(保存なし、指定時は "^" 使用不可)
*	-^,-C	カラー表示で起動する(保存なし、省略時は白黒)
*	-o

		suba.l	a3,a3			;ファイル名
		bra	arg_next
arg_loop:
		move.b	(a0)+,d0
		beq	arg_next
		cmpi.b	#'-',d0
		beq	arg_option

		lea	(-1,a0),a3		;ファイル名指定あり
		bra	arg_skip
arg_option:
		move.b	(a0)+,d0
		beq	arg_next
		cmpi.b	#'4',d0
		beq	option_4_8
		cmpi.b	#'8',d0
		bne	@f
option_4_8:
		subi.b	#'0',d0			;タブ桁数 4/8
		move.b	d0,(tab_size_flag-a5sp,a5)
		bra	arg_option
@@:
		cmpi.b	#'E',d0
		bne	@f
*option_E:
		st	(kanji_code-a5sp,a5)	;EUC
		bra	arg_option
@@:
		cmpi.b	#'J',d0
		bne	@f
*option_J:
		move.b	#1,(kanji_code-a5sp,a5)	;JIS
		bra	arg_option
@@:
		cmpi.b	#'S',d0
		bne	@f
*option_S:
		clr.b	(kanji_code-a5sp,a5)	;S-JIS
		bra	arg_option
@@:
		moveq	#0,d1
		cmpi.b	#'v',d0			;view-disp
		beq	option_v_d_c
		moveq	#1,d1
		cmpi.b	#'d',d0			;dump-disp
		beq	option_v_d_c
		moveq	#2,d1
		cmpi.b	#'c',d0			;cdmp-disp
		bne	@f
option_v_d_c:
		move	d1,(look_mode-a5sp,a5)
		bra	arg_option
@@:
		cmpi.b	#'r',d0
		bne	@f
*option_r:
		st	(look_yar_flag-a5sp,a5)	;正規化表示
		bra	arg_option
@@:
		cmpi.b	#'b',d0
		bne	@f
*option_b:
		st	(bs_flag-a5sp,a5)	;not-explusion-bs
		bra	arg_option
@@:
		cmpi.b	#'e',d0
		bne	@f
*option_e:
		st	(esc_flag-a5sp,a5)	;ESC 削除
		clr.b	(look_color_flag-a5sp,a5)
		bra	arg_option
@@:
		cmpi.b	#'^',d0
		beq	option_C
		cmpi.b	#'C',d0
		bne	@f
option_C:
		clr.b	(esc_flag-a5sp,a5)	;ESC シーケンス対応(カラー表示)
		st	(look_color_flag-a5sp,a5)
		bra	arg_option
@@:
		cmpi.b	#'o',d0
		bne	@f
*option_o:
		lea	(a0),a1
		lea	(write_path-a5sp,a5),a2
		moveq	#64-1,d0
1:
		move.b	(a1)+,(a2)+
		dbeq	d0,1b
		clr.b	-(a2)
		bra	arg_skip
@@:
		cmpi.b	#'w',d0			;dump-width、length
		bne	arg_skip
*option_w:
		lea	(a0),a1
		bsr	call_atoi_a1
		bne	option_w_error
		cmpi.b	#',',(a1)+
		bne	option_w_error

		move	d0,d1
		lea	(dump_width,pc),a3
		move	d0,(a3)+		;dump_width
		beq	option_w_error
		subq	#1,d0
		move	d0,(a3)+		;dump_width_lp

		bsr	call_atoi_a1
		bne	option_w_error

		move	d0,(a3)+		;dump_size
		beq	option_w_error

		moveq	#0,d0
		move	d1,d0
		divu	(dump_size,pc),d0	;空白の数
		add	d1,d0
		add	d1,d0			;d0.w 現在x位置増分
		move	d0,(a3)+		;dump_code_x

		add	d1,d0
		cmpi	#87,d0
		bcs	arg_skip
option_w_error:
		lea	(dump_width,pc),a3
		move	#16,(a3)+		;dump_width
		move	#15,(a3)+		;dump_width_lp
		move	#1,(a3)+		;dump_size
		move	#3*16,(a3)+		;dump_code_x
arg_skip:
		tst.b	(a0)+
		bne	arg_skip
arg_next:
		subq.l	#1,d7
		bcc	arg_loop

* a3 = ファイル名
		lea	(LOOK_FILE_NAME),a1
		move.l	a3,d0			;ファイル名無指定時は
		beq	skip_copy_filename	;前回のファイルを表示する

		lea	(a1),a0
		moveq	#90-1,d0
@@:
		move.b	(a3)+,(a0)+
		dbeq	d0,@b
		clr.b	-(a0)

		pea	(a1)
		jsr	(to_fullpath_file)
		move.l	d0,(sp)+
		bmi	lookf_filename_error
skip_copy_filename:
		clr	-(sp)
		move.l	a1,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d1
		bmi	lookf_filename_error

		move	#SEEK_END,-(sp)		;ファイルサイズを収得する
		clr.l	-(sp)
		move	d1,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		move.l	d0,-(sp)
		move	d1,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		move.l	(sp)+,d0
		bmi	lookf_filename_error

		bsr	condrv_koff
		bsr	look_sub
		bsr	condrv_kon
		bsr	restore_exec_filename

		move	d0,-(sp)
		moveq	#%0000_0011,d0
		and.b	(reload_flag-a5sp,a5),d0
		ori.b	#%1100_1100,d0
		jsr	(print_screen)
		move	(sp)+,d0
		bra	@f
lookf_filename_error:
		bsr	restore_exec_filename
		moveq	#2,d0
@@:
		bsr	print_lookfile_error
		jsr	(dos_kflush)

		tst.b	(v_exec_flag)
		beq	@f
		move	#KQ_V_EXEC<<8,d0
		jsr	(free_token_buf)
		jmp	(execute_quick_no)
@@:
		rts


call_atoi_a1:
		jmp	(atoi_a1)
**		rts


print_lookfile_error:
		tst	d0
		beq	print_lookfile_no_error

		lea	(LOOK_FILE_NAME),a0
		pea	(a0)
		DOS	_PRINT
		addq.l	#4,sp
		clr.b	(a0)
		GETMES_A1  MES_VLOAD
*print_lookfile_error_print:
		pea	(a1)
		DOS	_PRINT
		addq.l	#4,sp
		jsr	(PrintCrlf)

		clr	(＠buildin)
		clr	(＠status)
print_lookfile_no_error:
		rts


* &look-file 中は実行ファイル名を変更する ----- *

* 'mint.?'の時'mintlook/data.?'に置き換える
* in	d0.l	付け足す4バイト

change_exec_filename::
		PUSH	d1/a0-a2
		bsr	get_exec_filename
		lea	(a0),a2
		STRCPY	a0,a1
		move.l	#$20202020,d1
		or.l	(a2),d1
		cmpi.l	#'mint',d1
		bne	@f

		move.l	#$20202020,d1
		and.l	(a2)+,d1
		or.l	d1,d0
		cmpi.b	#'.',(a2)+
		bne	@f
		tst.b	(a2)+
		beq	@f
		tst.b	(a2)
		bne	@f

		move	-(a2),d1		;.x
		move.l	d0,(a2)+
		move	d1,(a2)+
		clr.b	(a2)
@@:
		POP	d1/a0-a2
		rts

restore_exec_filename::
		PUSH	a0-a1
		bsr	get_exec_filename
		STRCPY	a1,a0
		POP	a0-a1
		rts

get_exec_filename:
		lea	(mint_start-PSP_SIZE+PSP_Filename),a0
		lea	(filename_save),a1
		rts


* &look-file メイン処理 ----------------------- *

* in	d0.l	ファイルサイズ
*	a1.l	ファイル名
*	a5.l	a5sp
* out	d0.l	0 = 通常終了
*		1 = メモリ不足
*		2 = 読み込みエラー
*		3 = ラスタ割り込み使用中
* 備考:
*	現在は d0.l = 2、3 は返らない.

look_sub:
		PUSH	d1-d7/a0-a6
		move.l	d0,(file_size-a5sp,a5)
		move.l	a1,(file_name-a5sp,a5)

		moveq	#1,d0
		move	d0,(＠buildin)
		move	d0,(＠status)
		move.b	d0,(look_flag)

		clr.l	(line_buf-a5sp,a5)	;行管理エリア先頭
		clr.l	(file_buf-a5sp,a5)	;ファイル先頭
		clr.l	(total_line-a5sp,a5)
		clr.l	(total_dump-a5sp,a5)
		clr.l	(total_cdmp-a5sp,a5)
		clr.l	(top_line-a5sp,a5)	;表示先頭行
		clr.l	(last_search_line-a5sp,a5)
		clr.b	(memory_devid-a5sp,a5)
		clr.b	(not_enough_mem-a5sp,a5)
		clr.b	(out_of_mem_flag-a5sp,a5)
		clr.b	(v_exec_flag-a5sp,a5)
		clr.b	(cr_flag-a5sp,a5)
		clr.b	(mb_flag-a5sp,a5)
		clr.b	(reload_flag-a5sp,a5)

		tst	(＄ivss)		;initialize-viewer-search-strings
		bne	@f

		clr.b	(search_str_buf-a5sp,a5)
		clr.b	(search_str_buf2-a5sp,a5)
@@:
		clr.b	(bg_stat-a5sp,a5)
		clr.b	(fg_stat-a5sp,a5)
		clr.b	(int_flag-a5sp,a5)	;重複割り込み[ラスター]フラグ
		clr	(search_timer-a5sp,a5)
		clr.b	(load_comp_flag-a5sp,a5)
		clr	(ras_req_count-a5sp,a5)	;残スクロールカウンタ
		clr.l	(remained_task-a5sp,a5)

		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		clr.l	(mark_line_phy-a5sp,a5)	;物理マークライン+1(1～4294967296)
		clr.l	(mark_line_log-a5sp,a5)	;論理マークライン+0(0～4294967295)
		clr.l	(top_line2-a5sp,a5)	;top_line と同じ

		clr.b	(o_l_p_flag-a5sp,a5)
		clr.b	(csr_disp_flag-a5sp,a5)
		clr.b	(search_flag-a5sp,a5)
		clr.b	(sch_next_flag-a5sp,a5)
		clr.b	(prev_mb_flag-a5sp,a5)
**		clr.b	(searched_flag-a5sp,a5)

		st	(jis_mb_not-a5sp,a5)
		st	(ksi-a5sp,a5)

		clr.l	(now_total_line-a5sp,a5)	;現在表示行数

		pea	(-1)
		DOS	_MALLOC
		move.l	d0,(sp)
		clr.b	(sp)
		DOS	_MALLOC
		moveq	#1,d6
		move.l	d0,(sp)+
		bmi	look_sub_error

		movea.l	d0,a0
		lea	(-MEM_SIZE,a0),a1	;メモリ管理ポインタ
		movea.l	(end_,a1),a0		;このメモリブロックの終わり+1
		suba.l	#$8000+MEM_SIZE,a0	;後ろから 32KB 確保
		move.l	a0,d0
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+		;メモリ管理ポインタ移動
		move.l	d0,a0
		movea.l	(prev,a0),a1
		move.l	a0,(next,a1)		;前とメモリリンクを繋げる
		move.l	(next,a0),d0
		beq	@f
		movea.l	d0,a1
		move.l	a0,(prev,a1)		;次とメモリリンクを繋げる
@@:
		move.l	(end_,a0),(line_buf_last-a5sp,a5)
		lea	(MEM_SIZE,a0),a0	;↑行管理エリア最終
		move.l	a0,(line_buf-a5sp,a5)	;←行管理エリア先頭

		moveq	#-1,d1
		IOCS	_CRTMOD
		moveq	#16,d1			;768x512
		cmp	d0,d1
		beq	@f
		IOCS	_CRTMOD
@@:
		bsr	clear_temp_raster
		tst	(＄vras)		;ビュアエントリーラスター
		beq	v_e_ras_cancel

		PUSH	d0-d4
		moveq	#64,d4
@@:
		move	#$06_04,d1		;一行目だけ残してスクロール
		moveq	#29*4,d2		;コピーラスター数
		moveq	#%0011,d3
		IOCS	_TXRASCPY
		dbra	d4,@b
		POP	d0-d4
v_e_ras_cancel:
		moveq	#0,d0			;-4 or -8 の指定があった？
		move.b	(tab_size_flag-a5sp,a5),d0
		bne	tabset

* タブ幅の選択(*.[ch] なら $ctbw、それ以外は $tabw)
		lea	(-88,sp),sp
		move	(＄tabw),d1
		pea	(sp)
		move.l	(file_name-a5sp,a5),-(sp)
		DOS	_NAMESTS
		cmpi	#'  ',(8+75+1,sp)
		bne	@f			;拡張子は二文字以上
		moveq	#$20,d0
		or.b	(8+75+0,sp),d0
		subi.b	#'c',d0
		beq	1f
		subq.b	#'h'-'c',d0
		bne	@f
1:		move	(＄ctbw),d1		;*.[ch]
@@:		lea	(8+88,sp),sp

		moveq	#4,d0
		cmp	d1,d0
		beq	tabset			;4 桁
		moveq	#8,d0			;それ以外は全て 8 桁
tabset:
		move	d0,(file_tabsize-a5sp,a5)

**		bsr	clear_fnckey
		jsr	(ChangeFnckey_lookfile)
		bsr	clear_screen
		bsr	init_window

		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		TO_SUPER
		bsr	text_palet_push
		bsr	text_palet_set
		TO_USER
@@:
		GETMES_A1  MES_VLIN0
		move	(win_no_info-a5sp,a5),d0
		moveq	#81,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		jsr	(WinPrint)

		moveq	#BLUE+EMPHASIS,d1
		moveq	#2,d2
		move.l	(line_num3-a5sp,a5),d3
		moveq	#96-1,d4
		GETMES_A1  MES_L_RED
		IOCS	_B_PUTMES

		bset	#COM_READ,(fg_stat-a5sp,a5)

		bsr	lookfile_set_interrupt

		bsr	look_file_reading	;読み込み中コール
		tst.l	d0
		bpl	look_end_loop
		moveq	#0,d6
		addq.l	#1,d0
		bne	look_end
		moveq	#2,d6
		bra	look_end
* 処理待ちループ
look_end_loop:
		cmpi.b	#2,(look_flag)
		bge	@f
		addq.b	#1,(look_flag)
@@:
		tst.b	(v_exec_flag-a5sp,a5)
		bne	look_v_exec

		bsr	follow_fnckey_disp_mode

		tst.b	(bg_stat-a5sp,a5)
		beq	look_end_loop
		cmpi.b	#REQ_QUIT,(bg_stat-a5sp,a5)
		beq	look_end_normal
		bsr	main_job
		bra	look_end_loop
look_v_exec:
		move.l	(cursor_line-a5sp,a5),d0
		tst.b	(csr_disp_flag-a5sp,a5)
		bne	@f
		move	(＄vexl),d0		;カーソル非表示なら %vexl で補正する
@@:
		add.l	(top_line-a5sp,a5),d0
		lsl.l	#3,d0			;論理行変換
		neg.l	d0
		movea.l	(line_buf_last-a5sp,a5),a0
		GETLINENUM  (-8,a0,d0.l),d0
		addq.l	#1,d0

		lea	(-12,sp),sp
		lea	(sp),a0
		FPACK	__LTOS
		lea	(sp),a2
		lea	(str_mintvline,pc),a1	;$MINTVLINE に行番号を設定する
		jsr	(set_user_value_a1_a2)
		lea	(12,sp),sp
look_end_normal:
		moveq	#0,d6			;エラーコード
look_end:
		bsr	lookfile_restore_interrupt

		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		bsr	text_palet_pop
@@:
		bsr	delete_window

		move.l	(line_buf-a5sp,a5),-(sp)
		beq	@f
		DOS	_MFREE
@@:		addq.l	#4,sp

		move.l	(file_buf-a5sp,a5),-(sp)
		beq	@f
		subq.l	#2,(sp)
		DOS	_MFREE
@@:		addq.l	#4,sp

		jsr	(ChangeFnckey)
look_sub_error:
		move.l	d6,d0
		POP	d1-d7/a0-a6
		rts


* テキストパレット設定 ------------------------ *

text_palet_set:
		st	(look_color_flag-a5sp,a5)
*		moveq	#.low._GM_INACTIVE,d1
*		jsr	(_gm_internal_tgusemd)

		moveq	#.low._GM_MASK_STATE,d1
		jsr	(_gm_internal_tgusemd)
		move	d0,(gm_mask_state-a5sp,a5)

		moveq	#.low._GM_MASK_CLEAR,d1
		jsr	(_gm_internal_tgusemd)
set_palet_sub:
		lea	(＄vcl0),a1
		lea	(TEXT_PAL+2*8),a2
		bra	@f
text_palet_push:
		lea	(TEXT_PAL+2*8),a1
		lea	(text_palet),a2
@@:
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		rts

text_palet_pop:
		TO_SUPER
		lea	(text_palet),a1
		lea	(TEXT_PAL+2*8),a2
		move.l	(a1)+,(a2)+		;パレット 8～15 復帰
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+

		moveq	#%1100,d0
		bsr	call_clear_tvram
		clr.b	(look_color_flag-a5sp,a5)

		tst	(gm_mask_state-a5sp,a5)
		beq	@f

		moveq	#.low._GM_MASK_SET,d1
		jsr	(_gm_internal_tgusemd)
@@:
		TO_USER
		rts


* インフォメーション行表示 -------------------- *

		.offset	0
~info_buf:	.ds.b	256
~info_form:	.ds.b	MESLEN_MAX+1
		.even
sizeof_info:
		.text

print_info_line:
		lea	(-sizeof_info,sp),sp
		GETMES_A1  MES_VFORM
		lea	(~info_form,sp),a2
		STRCPY	a1,a2

		lea	(~info_buf,sp),a2
		move.l	#'──',d1
		moveq	#96/4-1,d0
@@:		move.l	d1,(a2)+
		dbra	d0,@b

		move	(win_no_info-a5sp,a5),d0
		moveq	#0,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		lea	(~info_buf,sp),a1
		bsr	print_inf_buf
		moveq	#0,d1
		moveq	#0,d2
		jsr	(WinSetCursor)

		lea	(~info_form,sp),a1
		lea	(~info_buf,sp),a2
		lea	(ctypetable),a3
		moveq	#'$',d2
		moveq	#0,d3
		bra	print_inf_loop
print_inf_back:
		pea	(~info_buf,sp)
		cmpa.l	(sp)+,a2
		bls	@f
		suba.l	d4,a2			;直前の文字を消す
@@:
print_inf_loop2:
		moveq	#0,d4			;$R$S などで二重に戻らないようにする
print_inf_loop:
		move.b	(a1)+,d3
		beq	print_inf_end
		cmp.b	d2,d3
		beq	print_inf_doll		;$～ の解釈

print_inf_putchar:
		move.b	d3,(a2)+		;とりあえず1バイトコピーする
		moveq	#1,d4
		tst.b	(a3,d3.w)
		bpl	print_inf_loop		;1バイト文字
*print_inf_2byte:
		move.b	(a1)+,(a2)+		;2バイト文字
		moveq	#2,d4
		bra	print_inf_loop

print_inf_end:
		lea	(~info_buf,sp),a1
		bsr	print_inf_buf
		lea	(sizeof_info,sp),sp
		rts

print_inf_buf2:
		lea	(4+.sizeof.(a1)+~info_buf,sp),a1
print_inf_buf:
		clr.b	(a2)
		move	(win_no_info-a5sp,a5),d0
		jmp	(WinPrint)
**		rts

* $～ の解釈
print_inf_doll:
		move.b	(a1)+,d3
		cmp.b	d2,d3
		beq	print_inf_putchar	;$$ → $

		cmpi.b	#'V',d3
		bne	@f

		move.l	a1,-(sp)	
		lea	(str_ver_num,pc),a1	;$V バージョン
		bra	print_inf_copy
@@:
		cmpi.b	#'M',d3
		bne	@f

		moveq	#MES_VVIEW,d0		;$M 表示モード
		add	(look_mode-a5sp,a5),d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'C',d3
		bne	@f

		moveq	#MES_VSJIS,d0		;$C 文字コード種別
		add.b	(kanji_code-a5sp,a5),d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'S',d3
		bne	@f

		tst.b	(search_exact-a5sp,a5)	;$S EXACT
		beq	print_inf_back
		moveq	#MES_VEXAC,d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'B',d3
		bne	@f

		tst.b	(bs_flag-a5sp,a5)	;$B BS
		bne	print_inf_back
		moveq	#MES_V_BS_,d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'E',d3
		bne	@f

		tst.b	(esc_flag-a5sp,a5)	;$E ESC
		bne	print_inf_back
		moveq	#MES_V_ESC,d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'^',d3
		bne	@f

		tst.b	(look_color_flag-a5sp,a5)
		beq	print_inf_back		;$^ COLOR
		moveq	#MES_V_COL,d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'R',d3
		bne	@f

		tst.b	(look_yar_flag-a5sp,a5)	;$R REGULAR
		beq	print_inf_back
		moveq	#MES_V_REG,d0
		bra	print_inf_copymes
@@:
		cmpi.b	#'P',d3
		bne	@f

		move.l	a1,-(sp)		;$P フルパスファイル名
		movea.l	(file_name-a5sp,a5),a1
		bra	print_inf_copy
@@:
		cmpi.b	#'F',d3
		bne	@f

		move.l	a1,-(sp)		;$F ファイル名
		bsr	print_inf_getfilename
		bra	print_inf_copy
@@:
		btst	#IS_DIGIT,(a3,d3.w)
		bne	@f

		subq.l	#1,a1			;$ + 未定義文字は
		moveq	#'$',d3			;$ をそのまま表示する
		bra	print_inf_putchar
@@:
		pea	(-1,a1)			;$nn 表示桁位置指定
		bsr	print_inf_buf2
		movea.l	(sp)+,a1		;最初の数字
		bsr	call_atoi_a1

		PUSH	d1-d2
		move.l	d0,d1
		moveq	#0,d2
		move	(win_no_info-a5sp,a5),d0
		jsr	(WinSetCursor)
		POP	d1-d2
		bra	@f

print_inf_copymes:
		move.l	a1,-(sp)
		bsr	get_message_a1
print_inf_copy:
		STRCPY	a1,a2
		bsr	print_inf_buf2
		move.l	(sp)+,a1
@@:
		lea	(~info_buf,sp),a2
		bra	print_inf_loop2


print_inf_getfilename:
		movea.l	(file_name-a5sp,a5),a1
		clr.l	-(sp)			;最後に見つけた区切り記号の次のアドレス
prinf_getfn_found:
		move.l	a1,(sp)			;区切り記号を見つけた
prinf_getfn_loop:
		move.b	(a1)+,d3
		beq	prinf_getfn_end
		cmpi.b	#'/',d3
		beq	prinf_getfn_found
		cmpi.b	#'\',d3
		beq	prinf_getfn_found
		cmpi.b	#':',d3
		beq	prinf_getfn_found
		tst.b	(a3,d3.w)
		bpl	prinf_getfn_loop
		tst.b	(a1)+			;2バイト文字
		bne	prinf_getfn_loop
prinf_getfn_end:
		movea.l	(sp)+,a1		;最後に見つけた区切り記号の次のアドレス
		rts


* ファイル読み込み下請け ---------------------- *

FIRST_READ_SIZE:	.equ	$2000		;初回読み込みバイト数
SECOND_READ_SIZE:	.equ	$6000		;二回目以降読み込みバイト数

look_file_reading:
		clr	-(sp)
		move.l	(file_name-a5sp,a5),-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	l_f_l90

		move	d0,(file_handle-a5sp,a5)
		move	d0,-(sp)
		clr	-(sp)
		DOS	_IOCTRL
		addq.l	#4,sp
		tst.b	d0
		bmi	l_f_l90
						;行管理エリア先頭ポインタ最終
		movea.l	(line_buf_last-a5sp,a5),a4
		moveq	#0,d2			;論理行数(lnum-1 で格納)
		moveq	#WHITE,d3		;テキスト各行先頭カラー
		moveq	#1,d4			;ビュア内部行数
		moveq	#0,d5			;横幅カウント
		move	(file_tabsize-a5sp,a5),d6
		move	(screen_with-a5sp,a5),d7

		pea	(-1)			;最大空き領域から確保
		DOS	_MALLOC
		move.l	d0,(sp)
		clr.b	(sp)
		DOS	_MALLOC
		move.l	d0,(sp)+
		bmi	l_f_r_mem_error

		movea.l	d0,a0
		addq.l	#2,d0
		move.l	d0,(file_buf-a5sp,a5)
		move.l	d0,(file_read_end-a5sp,a5)

		pea	(FIRST_READ_SIZE+$100)	;念のため $100 余分に確保
		pea	(a0)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bmi	l_f_r_mem_error

		clr.b	(a0)+
		move.b	#EOF,(a0)+
		movea.l	a0,a2			;テキスト各行先頭アドレス
		movea.l	a0,a3			;ファイルリードアドレス

		move.l	a2,-(a4)		;最初は最初
		move.l	d2,-(a4)		;最初は１行
		move.b	d3,(a4)			;最初の色格納

		pea	(FIRST_READ_SIZE)	;最初は $2000 バイト読み込み
		bra	l_f_r2
l_f_r1:
		movea.l	(file_buf-a5sp,a5),a0
		move.l	(end_-MEM_SIZE-2,a0),d0
		sub.l	a0,d0
		pea	(SECOND_READ_SIZE+$10)	;$6000 バイト拡大
		add.l	d0,(sp)
		pea	(-2,a0)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bmi	l_f_r_mem_error

		pea	(SECOND_READ_SIZE)	;次から $6000 バイト読み込み
l_f_r2:
		move.l	a3,-(sp)
		move	(file_handle-a5sp,a5),-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
.if 0
		beq	l_f_r20			;読み込み終了
.else
* 0バイトのファイルでさまざまな不具合が発生するのを防止する暫定処理
		bne	9f
		cmpa.l	(file_buf-a5sp,a5),a3
		bne	l_f_r20
		clr.l	(a3)
		moveq	#1,d0
9:
.endif

		adda.l	d0,a3			;ファイルリードアドレス加算
		move.l	a3,(file_read_end-a5sp,a5)

		move.l	d0,d1
		divu	(dump_width,pc),d0	;読み込みバイト数÷DUMP幅
		divu	(cdmp_width,pc),d1	;読み込みバイト数÷CDMP幅
		ext.l	d0			;andi.l	#$0000ffff,d0
		ext.l	d1			;andi.l	#$0000ffff,d1

		cmpi	#1,(look_mode-a5sp,a5)
		bcs	1f
		beq	2f
		add.l	d0,(total_cdmp-a5sp,a5)	;2=CDMP
		add.l	d1,(total_line-a5sp,a5)
		bra	l_f_r3
2:
		add.l	d0,(total_line-a5sp,a5)	;1=DUMP
		add.l	d1,(total_dump-a5sp,a5)
		bra	l_f_r3
1:
		add.l	d0,(total_dump-a5sp,a5)	;0=VIEW
		add.l	d1,(total_cdmp-a5sp,a5)
l_f_r3:
		cmpa.l	a3,a2			;読み込みアドレス : 現在審査中アドレス
**		bne	l_f_r4
		bcs	l_f_r4			;ESC 処理の都合でこうしている

		move.l	d4,d0			;ビュア内部行数
		subq.l	#1,d0
		cmpi	#1,(look_mode-a5sp,a5)
		bcs	1f			;0=VIEW
		beq	2f				
		move.l	d0,(total_dump-a5sp,a5)	;2=CDMP
		bra	@f
2:
		move.l	d0,(total_cdmp-a5sp,a5)	;1=DUMP
		bra	@f
1:
		move.l	d0,(total_line-a5sp,a5)	;現在最大行格納
@@:
		tst.b	(fg_stat-a5sp,a5)
		bmi	l_f_r1			;１フレーム処理終了
		cmp.l	(line_num1-a5sp,a5),d0
		bcs	l_f_r1
		ori.b	#1<<COM_READY+1<<COM_JUMP,(fg_stat-a5sp,a5)
		bra	l_f_r1
l_f_r4:
		tst.b	(cr_flag-a5sp,a5)
		beq	@f
		moveq	#LF,d1
		cmp.b	(a2)+,d1
		beq	l_f_r10			;CR,LF
		subq.l	#1,a2
		bra	l_f_r10			;CR only
@@:
		move.b	(a2)+,d1
		cmpi.b	#$20,d1
		bcs	l_f_r10

		tst.b	(mb_flag-a5sp,a5)
		beq	@f

		clr.b	(mb_flag-a5sp,a5)
		addq	#1,d5			;全角下位
		cmp	d7,d5
**		bne	l_f_r3
		bcs	l_f_r3
		bra	l_f_r16
@@:
		moveq	#0,d0
		move.b	d1,d0
		jsr	(is_mb)
		sne	(mb_flag-a5sp,a5)

		addq	#1,d5
		cmp	d7,d5			;最大横幅数と比較
**		bne	l_f_r3
		bcs	l_f_r3			;CTRL 視覚化の都合でこうしている

		tst.b	(mb_flag-a5sp,a5)
		beq	l_f_r16
		subq.l	#1,a2			;全角上位
		bra	l_f_r16

l_f_r10:
		bsr	follow_fnckey_disp_mode
		tst.b	(bg_stat-a5sp,a5)
		beq	l_f_r10_5		;ジョブ要請チェック
		cmpi.b	#REQ_QUIT,(bg_stat-a5sp,a5)
		beq	l_f_r91			;強制終了チェック

		bsr	main_job
l_f_r10_5:
		cmpi.b	#CR,d1
		seq	(cr_flag-a5sp,a5)
		beq	l_f_r3

		cmpi.b	#LF,d1
		beq	l_f_rLF
		cmpi.b	#BS,d1
		beq	l_f_rBS
		cmpi.b	#TAB,d1
		beq	l_f_rTAB
		cmpi.b	#ESC,d1
		bne	l_f_rCTRL
		tst.b	(esc_flag-a5sp,a5)	;読み込み境界($2000/$6000)が
		bne	l_f_rCTRL		;ESC だと当然解析に失敗する

		PUSH	d1/a0
		move.l	a2,a0
		bsr	esc_analyze
		move.l	a0,a2
		POP	d1/a0
		bra	l_f_r3
l_f_rCTRL:
		addq	#1,d5
		tst	(＄vcct)		;視覚化
		beq	@f
		addq	#1,d5
@@:		cmp	d7,d5			;最大横幅数と比較
		bne	l_f_r3
		bra	l_f_r16

l_f_rTAB:
		clr	d0
		sub	d6,d0			;タブ調整
		and	d0,d5
		add	d6,d5
		cmp	d7,d5			;最大横幅数と比較
		bcs	l_f_r3
		bra	l_f_r16

l_f_rBS:
		tst.b	(bs_flag-a5sp,a5)
		bne	l_f_rCTRL		;BS を処理しない
		subq	#1,d5
.if 1
		bcc	l_f_r3
		moveq	#0,d5
.endif
		bra	l_f_r3

l_f_rLF:
		addq.l	#1,d2			;実際行数格納
l_f_r16:
		move.l	a2,-(a4)		;テキスト各行先頭アドレス格納
		move.l	d2,-(a4)		;実際行数格納
		move.b	d3,(a4)			;テキスト各行先頭カラー格納
		addq.l	#1,d4			;ビュア内部行数
		moveq	#0,d5
		move.l	d4,d0
		andi	#$0fff,d0
		bne	l_f_r3

		pea	(-1)			;行管理メモリ拡大
		DOS	_MALLOC
		move.l	d0,(sp)
		clr.b	(sp)
		DOS	_MALLOC
		move.l	d0,(sp)+
		bmi	l_f_r_ext_error

		movea.l	d0,a0
		lea	(-MEM_SIZE,a0),a1	;メモリ管理ポインタ
		movea.l	(end_,a1),a0		;このメモリブロックの終わり+1
		lea	($8000,a0),a0		;後ろから 32KB 確保
		move.l	a0,d0
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+		;メモリ管理ポインタ移動

		move.l	d0,a0
		movea.l	(prev,a0),a1
		move.l	a0,(next,a1)		;前とメモリリンクを繋げる
		move.l	(next,a0),d1
		beq	@f
		movea.l	d1,a1
		move.l	a0,(prev,a1)		;次とメモリリンクを繋げる
@@:
		addq.l	#MEM_SIZE/2,d0
		addq.l	#MEM_SIZE/2,d0
		movea.l	a0,a1
		movea.l	(next,a1),a1		次のメモリ管理ポインタ
		lea	(MEM_SIZE,a1),a1
		cmpa.l	(line_buf-a5sp,a5),a1
		bne	l_f_r_cat_error

		move.l	d0,(line_buf-a5sp,a5)
		lea	(-MEM_SIZE,a1),a1
		move.l	(end_,a1),(end_,a0)
		move.l	(next,a1),(next,a0)
		bra	l_f_r3
l_f_r_mem_error:
		st	(not_enough_mem-a5sp,a5)
		bra	@f
l_f_r_cat_error:
		move.l	d0,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
l_f_r_ext_error:
		st	(memory_devid-a5sp,a5)
@@:
		PUSH	d0-d4/a1
		GETMES_A1  MES_V_SHA
		move	(win_no_info-a5sp,a5),d0
		moveq	#0,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		jsr	(WinPrint)
		POP	d0-d4/a1

		st	(out_of_mem_flag-a5sp,a5)
		addq.l	#2,d4			;ビュア内部行数増加
		move.b	#LF,(a2)+
		addq.l	#1,d2			;実際行増加
		move.l	a2,-(a4)		;行カウント
		moveq	#-1,d0
		move.l	d0,-(a4)		;行カウント
**		move.b	d3,(a4)			;テキスト各行先頭カラー格納

		move.l	a2,d0
		sub.l	(file_buf-a5sp,a5),d0
		move.l	d0,(file_size-a5sp,a5)
		move.l	d0,d2
		subq.l	#1,d4
		bra	l_f_r21
l_f_r20:
		tst	d5			;読み込み終了
		bne	1f			;最後の一行に改行あり
		tst.b	(cr_flag-a5sp,a5)
		beq	@f
1:
		move.l	a2,-(a4)
		move.l	d2,-(a4)
**		move.b	d3,(a4)			;テキスト各行先頭カラー格納
		addq.l	#1,d4			;ビュア内部行数増加
@@:
		moveq	#-1,d0
		move.l	d0,(a4)			;行管理ポインタに EOF を書き込む
		move.l	a2,d0
		sub.l	(file_buf-a5sp,a5),d0
		move.l	d0,d2			;実際読み込みファイルサイズ
l_f_r21:
		moveq	#0,d1
		move	(cdmp_width,pc),d1
		bsr	divu32
		addq.l	#1,d0
		tst	d1
		beq	@f
		addq.l	#1,d0			;cdmp 総行数再計算
@@:
		move.l	d0,-(sp)
		move.l	d2,d0
		moveq	#0,d1
		move	(dump_width,pc),d1
		bsr	divu32
		addq.l	#1,d0
		tst	d1
		beq	@f
		addq.l	#1,d0			;dump 総行数再計算
@@:		move.l	(sp)+,d1

		moveq	#96-1,d2
@@:
		clr.b	(a2)+
		dbra	d2,@b
l_f_r22:
		cmpi	#1,(look_mode-a5sp,a5)	;終了
		bcs	1f
		beq	2f

		lea	(total_dump-a5sp,a5),a0
		move.l	d0,(total_cdmp-a5sp,a5)	;DUMP 時総行数補正
		move.l	d1,(total_line-a5sp,a5)	;CDMP 時総行数補正
		bra	@f
2:
		lea	(total_cdmp-a5sp,a5),a0
		move.l	d0,(total_line-a5sp,a5)	;DUMP 時総行数補正
		move.l	d1,(total_dump-a5sp,a5)	;CDMP 時総行数補正
		bra	@f
1:
		lea	(total_line-a5sp,a5),a0
		move.l	d0,(total_dump-a5sp,a5)	;DUMP 時総行数補正
		move.l	d1,(total_cdmp-a5sp,a5)	;CDMP 時総行数補正
@@:
		move.l	d4,(a0)			;VIEW 時総行数ストア

		cmp.l	(line_num2-a5sp,a5),d0
		bls	@f
		cmp.l	(line_num2-a5sp,a5),d1
		bls	@f
		cmp.l	(line_num2-a5sp,a5),d4
		bhi	@@f
@@:
* 一画面内に納まるファイル
		bset	#COM_JUMP,(fg_stat-a5sp,a5)	;画面再描画(EOF 対策)
@@:
		tas	(fg_stat-a5sp,a5)
		bmi	l_f_r23
		bset	#COM_JUMP,(fg_stat-a5sp,a5)
l_f_r23:
		bclr	#COM_READ,(fg_stat-a5sp,a5)
		bsr	close_input_file
		moveq	#0,d0
		rts
l_f_l90:
		moveq	#-1,d0
		rts
l_f_r91:
		bsr	close_input_file
		moveq	#-2,d0
		rts

close_input_file:
		move	(file_handle-a5sp,a5),-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		rts


* フォアグラウンドメイン処理 ------------------ *
* V-DISP 割り込み処理中では実行できない機能をここで行う.

main_job:
		PUSH	d0-d7/a0-a4
		moveq	#0,d0
		move.b	(bg_stat-a5sp,a5),d0
		move	(@f,pc,d0.w),d0
		jsr	(@f,pc,d0.w)
		clr.b	(bg_stat-a5sp,a5)
		bclr	#COM_REQ,(fg_stat-a5sp,a5)
		POP	d0-d7/a0-a4
		rts
@@:
		.dc	fg_dummy_jump-@b	;REQ_NUL
		.dc	fg_dummy_jump-@b	;REQ_QUIT
		.dc	fg_goto_line-@b		;REQ_JUMP
		.dc	fg_search_forward-@b	;REQ_SCHFW
		.dc	fg_search_f_next-@b	;REQ_SCHFWN
		.dc	fg_search_reverse-@b	;REQ_SCHBW
		.dc	fg_search_r_next-@b	;REQ_SCHBWN
		.dc	fg_mark-@b		;REQ_MARK
		.dc	fg_goto_mark-@b		;REQ_GOMARK
		.dc	fg_exg_point_mark-@b	;REQ_EXG
		.dc	fg_write_file-@b	;REQ_WRITE
		.dc	fg_change_code-@b	;REQ_CODE
		.dc	fg_print_version-@b	;REQ_VERSION
		.dc	fg_toggle_dump_mode-@b	;REQ_DUMP
		.dc	fg_toggle_color-@b	;REQ_COLOR
		.dc	fg_toggle_exact-@b	;REQ_CASE
		.dc	fg_toggle_regular-@b	;REQ_REG
		.dc	fg_toggle_cr_disp-@b	;REQ_CR
		.dc	fg_toggle_tab-@b	;REQ_TAB
		.dc	fg_toggle_tabsize-@b	;REQ_TABSIZE
		.dc	fg_toggle_line_num-@b	;REQ_NUM
		.dc	fg_is_forward-@b	;REQ_ISCHFW
		.dc	fg_is_reverse-@b	;REQ_ISCHBW
		.dc	fg_search_regexp-@b	;REQ_REGSCH
		.dc	fg_search_reg_next-@b	;REQ_REGSCHN
		.dc	fg_bell-@b		;REQ_BELL


* [FG] ダミー --------------------------------- *
fg_dummy_jump:
		rts


* [FG] バージョン表示 ------------------------- *
fg_print_version:
		bsr	bel_clr
		lea	(str_version,pc),a1
		bra	bel_sub_p2
**		rts


* [FG] 行番号ジャンプ ------------------------- *
fg_goto_line:
		GETMES_A1  MES_VLINE
		lea	(subwin_input,pc),a0
		moveq	#MES_L_NUM,d0
		moveq	#20,d1			;SUBWIN_XSIZE
		bsr	window_init
		jsr	(WinPrint)

		clr.l	-(sp)
		clr.l	-(sp)
		lea	(sp),a1
		move.b	(jump_first_num-a5sp,a5),(a1)

		moveq	#6,d0			;入力幅
		moveq	#6,d1			;バッファ容量
		bsr	look_command_edit
		bmi	fg_goto_line_end

		lea	(sp),a1
		bsr	call_atoi_a1

		moveq	#0,d1
		cmpi	#1,(look_mode-a5sp,a5)
		bcs	@f
		beq	1f
		move	(cdmp_width,pc),d1
		bra	2f
1:		move	(dump_width,pc),d1
2:		bsr	divu32			;オフセット÷ダンプ幅
		addq.l	#1,d0
@@:
		subq.l	#1,d0
		bcs	fg_goto_line_end

		tst	(look_mode-a5sp,a5)
		beq	@f
		move.l	d0,d1
		bra	m_d_j2
@@:
		move.l	(total_line-a5sp,a5),d1
		subq.l	#2,d1			;オーバーチェック

		lsl.l	#3,d1
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a0
		GETLINENUM  (-8,a0,d1.l),d1
		cmp.l	d1,d0
		bhi	fg_goto_line_end

		move.l	d0,d1
		lsl.l	#3,d1
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a1
		addq.l	#8,d1
@@:
		subq.l	#8,d1			;入力行と実一行が一致するまでループ
		GETLINENUM  (-8,a1,d1.l),d2
		cmp.l	d2,d0
		bne	@b

		neg.l	d1
		lsr.l	#3,d1			;行番号に戻す
m_d_j2:
		PUSH	d0-d7/a0-a4
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		POP	d0-d7/a0-a4

		bsr	topline_adjust
		bset	#COM_JUMP,(fg_stat-a5sp,a5)
fg_goto_line_end:
		addq.l	#8,sp
		rts


* [FG] ファイル書き出し ----------------------- *
* ou	d0.l	 0 = 成功
*		-1 = 失敗
fg_write_file:
		tst.l	(mark_line_phy-a5sp,a5)
		beq	writefile_no_mark

		bsr	input_write_filename
		bne	writefile_cancel

		lea	(write_filename-a5sp,a5),a0

		lea	(-92,sp),sp
		pea	(sp)
		pea	(a0)
		DOS	_NAMECK
		lea	(8+92,sp),sp
		addq.b	#1,d0			;$ff ならディレクトリ指定
		tst.l	d0
		bne	writefile_name_ok

* ディレクトリ名指定時は、ファイル名を入力せずに
* 確定したものと見なし、$temp/manami に書き出す.
		pea	(a0)
		clr.l	-(sp)
		pea	(str_temp,pc)		;"temp"
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	writefile_no_temp	;環境変数がなければカレント
@@:
		tst.b	(a0)+
		bne	@b
		move.b	(MINTSLASH),(-1,a0)
writefile_no_temp:
		GETMES_A1  MES_VFILE
		STRCPY	a1,a0
writefile_name_ok:
		lea	(write_filename-a5sp,a5),a1
		STRLEN	a1,d0
		move	d0,(path_len-a5sp,a5)

		moveq	#0,d1
		cmpi.b	#':',(1,a1)
		bne	@f

		moveq	#$20,d1
		or.b	(a1),d1
		subi.b	#'a'-1,d1		;ドライブ番号
@@:
		jsr	(dos_drvctrl_d1)
		btst	#DRV_INSERT,d0
		beq	writefile_notready
		btst	#DRV_PROTECT,d0
		bne	writefile_wp

		move	#1<<ARCHIVE,-(sp)
		pea	(write_filename-a5sp,a5)
		DOS	_NEWFILE
		addq.l	#6,sp
		cmpi.l	#-80,d0
		beq	writefile_same_name	;同名ファイルがある
		bra	@f
writefile_overwrite:
		move	#1<<ARCHIVE,-(sp)
		pea	(write_filename-a5sp,a5)
		DOS	_CREATE
		addq.l	#6,sp
@@:
		tst.l	d0
		bpl	writefile_open_ok

* ファイルが作成できなかった場合
		clr	-(sp)			;ROPEN
		pea	(write_filename-a5sp,a5)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	writefile_error

		move.l	d0,-(sp)
**		clr	(sp)
		DOS	_IOCTRL
		tst	d0
		smi	-(sp)			;キャラクタデバイスか？
		move	(sp)+,d1
		addq	#7,(sp)
		DOS	_IOCTRL
		tst.l	d0
		sne	d1			;出力可能か？
		addq.l	#2,sp
		DOS	_CLOSE
		addq.l	#2,sp
		not	d1
		bne	writefile_error

		move	#WOPEN,-(sp)		;キャラクタデバイスかつ出力可能なら
		pea	(write_filename-a5sp,a5)	;オープンして良い
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	writefile_error
writefile_open_ok:
		move	d0,(write_fileno-a5sp,a5)
		bsr	bel_clr
		moveq	#MES_VWRIT,d0
		bra	w_f_write

writefile_same_name:
		bsr	bel_clr
		lea	(write_filename-a5sp,a5),a1
		bsr	bel_sub_p2

		GETMES_A1  MES_VSAVE
		moveq	#5,d1			;10
		add	(path_len-a5sp,a5),d1
		bsr	bel_sub
w_f_same_loop:
		bsr	iocs_b_keyinp
		cmpi.b	#BEL,d0			;CTRL+G
		beq	writefile_cancel
		cmpi.b	#ESC,d0
		beq	writefile_cancel
		ori.b	#$20,d0
		cmpi.b	#'n',d0
		beq	writefile_cancel
		cmpi.b	#'y',d0
		beq	writefile_overwrite
		cmpi.b	#'o',d0
		beq	writefile_overwrite
		cmpi.b	#'r',d0
		beq	fg_write_file
		cmpi.b	#'a',d0
		bne	w_f_same_loop
*w_f_append:
		move	#WOPEN,-(sp)
		pea	(write_filename-a5sp,a5)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	writefile_error

		move	d0,(write_fileno-a5sp,a5)
		bsr	seek_to_end_of_file
		move	(write_fileno-a5sp,a5),-(sp)
		DOS	_FGETC
		addq.l	#2,sp
		moveq	#EOF,d1
		cmp.l	d0,d1
		bne	@f
		bsr	seek_to_end_of_file
@@:
		bsr	bel_clr
		moveq	#MES_VAPPE,d0
w_f_write:
		bsr	get_message_a1
		bsr	bel_sub_p2
		lea	(write_filename-a5sp,a5),a1
		moveq	#17,d1
		bsr	bel_sub

		move.l	(mark_line_phy-a5sp,a5),d0
		move.l	(cursor_line-a5sp,a5),d1
		add.l	(top_line-a5sp,a5),d1	;cur_line + topline
		addq.l	#1,d1
		cmp.l	d0,d1
		bhi	write_normal		;マークライン(d0) < カーソルライン(d1)
write_back:
		exg	d0,d1
write_normal:
		subq.l	#1,d0			;書き出し開始行
**		subq.l	#1,d1			;書き出し終了行+1

		cmpi	#1,(look_mode-a5sp,a5)
		bcs	3f
		beq	1f
		lea	(cdmp_width,pc),a1
		bra	2f
1:		lea	(dump_width,pc),a1
2:		bsr	mulu32x16_d0		;行数×ダンプ幅
		bsr	mulu32x16_d1		;行数×ダンプ幅
		cmp.l	(file_size-a5sp,a5),d1
		bls	@f
		move.l	(file_size-a5sp,a5),d1
@@:		movea.l	(file_buf-a5sp,a5),a2
		lea	(a2,d0.l),a3
		lea	(a2,d1.l),a4
		bra	@f			;ファイル先頭アドレス
3:
		lsl.l	#3,d0
		lsl.l	#3,d1
		neg.l	d0
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a2
		GETBUFPTR  (-4,a2,d0.l),a3
		GETBUFPTR  (-4,a2,d1.l),a4
@@:
		suba.l	a3,a4
		move.l	a4,-(sp)		;バイト数
		move.l	a3,-(sp)
		move	(write_fileno-a5sp,a5),-(sp)
		DOS	_WRITE
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	writefile_write_error

		st	(reload_flag-a5sp,a5)
		clr.l	(write_filename-a5sp,a5)
		GETMES_A1  MES_VDONE
		moveq	#20,d1			;25
		add	(path_len-a5sp,a5),d1
		bsr	bel_sub2

		bsr	close_output_file
		moveq	#0,d0
		rts

close_output_file:
		move	(write_fileno-a5sp,a5),-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		clr.b	(write_filename-a5sp,a5)
		rts

seek_to_end_of_file:
		move	#SEEK_END,-(sp)
		pea	(-1)			;offset
		move	(write_fileno-a5sp,a5),-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		rts

get_message_a1:
		jsr	(get_message)
		movea.l	d0,a1
		rts

writefile_write_error:
		moveq	#MES_DFULL,d0
		bra	@f
writefile_notready:
		moveq	#MES_VNODI,d0
		bra	@f
writefile_wp:
		moveq	#MES_VPROT,d0
		bra	@f
writefile_error:
		moveq	#MES_VFNER,d0
@@:
		bsr	get_message_a1
		bsr	bel_clr
		bsr	bel_sub2_p2
		bra	@f
writefile_cancel:
		bsr	bel_clr
@@:
		bsr	close_output_file
		bra	@f
writefile_no_mark:
		bsr	bel_clr
		GETMES_A1  MES_VNOMA
		bsr	bel_sub2_p2
		clr.b	(write_filename-a5sp,a5)
@@:
		moveq	#-1,d0
		rts

bel_sub_p2:
		moveq	#2,d1
bel_sub:
		moveq	#0,d2
		move	(win_no_message-a5sp,a5),d0
		jsr	(WinSetCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)

		pea	(look_print,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		rts

bel_sub2_p2:
		moveq	#2,d1
bel_sub2:
		moveq	#0,d2
		move	(win_no_message-a5sp,a5),d0
		jsr	(WinSetCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		jsr	(WinPrint)
		move	#120,(search_timer-a5sp,a5)
		rts


* [FG] EXACT モード切り換え ------------------- *
fg_toggle_exact:
		bsr	bel_clr
		lea	(str_tgl_exact,pc),a1
		bsr	bel_sub2_p2

		not.b	(search_exact-a5sp,a5)
		lea	(search_str_buf-a5sp,a5),a1
		bsr	bm_comp
		bra	print_info_line
**		rts


* [FG] カラー表示モード切り換え --------------- *
fg_toggle_color:
		tst.b	(esc_flag-a5sp,a5)
		bne	fg_toggle_color_end
		tst.b	(look_color_flag-a5sp,a5)
		beq	@f

		bsr	text_palet_pop
		bsr	print_info_line
		move	(win_no_main-a5sp,a5),d0
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		bra	redraw_page
@@:
		pea	(text_palet_set,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		bsr	print_info_line
		bra	redraw_page
fg_toggle_color_end:
		rts


* [FG] ダンプ表示モード変更 ------------------- *
fg_toggle_dump_mode:
		bsr	delete_window

		move.l	(total_line-a5sp,a5),-(sp)	;最大 VIEW ライン数
		move.l	(total_dump-a5sp,a5),-(sp)	;最大 DUMP ライン数
		move.l	(total_cdmp-a5sp,a5),-(sp)	;最大 CDMP ライン数
		move.l	(sp)+,(total_dump-a5sp,a5)
		move.l	(sp)+,(total_line-a5sp,a5)
		move.l	(sp)+,(total_cdmp-a5sp,a5)

		move.l	(top_line-a5sp,a5),d0
		tst.b	(csr_disp_flag-a5sp,a5)
		beq	@f
		add.l	(cursor_line-a5sp,a5),d0
@@:
		move	(look_mode-a5sp,a5),d1	;VIEW -> DUMP -> CDMP -> VIEW...
		addq	#1,d1
		cmpi	#3,d1
		bne	@f
		moveq	#0,d1
@@:
		move	d1,(look_mode-a5sp,a5)
		subq	#1,d1
		bcs	to_view
		beq	to_dump
*to_cdmp:
		bsr	dump_to_cdmp		;DUMP -> CDMP
		move.l	d0,(top_line-a5sp,a5)
		move.l	d0,(top_line2-a5sp,a5)
		move.l	d0,d1
		bsr	topline_adjust

		move.l	(mark_line_phy-a5sp,a5),d0
		bsr	dump_to_cdmp
		move.l	d0,(mark_line_phy-a5sp,a5)

		move.l	(mark_line_log-a5sp,a5),d0
		bsr	dump_to_cdmp
		bra	@f
to_dump:
		bsr	view_to_dump		;VIEW -> DUMP
		move.l	d0,(top_line-a5sp,a5)
		move.l	d0,(top_line2-a5sp,a5)
		move.l	d0,d1
		bsr	topline_adjust

		move.l	(mark_line_phy-a5sp,a5),d0
		bsr	view_to_dump
		move.l	d0,(mark_line_phy-a5sp,a5)

		move.l	(mark_line_log-a5sp,a5),d0
		bsr	view_to_dump
		bra	@f
to_view:
		bsr	cdmp_to_view		;CDMP -> VIEW
		move.l	d0,(top_line-a5sp,a5)
		move.l	d0,(top_line2-a5sp,a5)
		move.l	d0,d1
		bsr	topline_adjust

		move.l	(mark_line_phy-a5sp,a5),d0
		bsr	cdmp_to_view
		move.l	d0,(mark_line_phy-a5sp,a5)

		move.l	(mark_line_log-a5sp,a5),d0
		bsr	cdmp_to_view
@@:
		move.l	d0,(mark_line_log-a5sp,a5)
		pea	(str_tgl_dump,pc)
		bra	reset_screen_mode
**		rts

reset_screen_mode:
		bsr	init_window

		clr.b	(csr_disp_flag-a5sp,a5)
		bsr	bel_clr
		movea.l	(sp)+,a1
		bsr	bel_sub2_p2
		bra	redraw_page

* in	d0.l	VIEW 物理行
* out	d0.l	DUMP 行
view_to_dump
		move.l	a0,-(sp)
		lsl.l	#3,d0
		neg.l	d0
		movea.l	(line_buf_last-a5sp,a5),a0
		GETBUFPTR  (-4,a0,d0.l),d0	;表示行テキスト先頭
		move.l	(file_buf-a5sp,a5),d1	;テキスト先頭アドレス
		sub.l	d1,d0
		moveq	#0,d1
		move	(dump_width,pc),d1
		bsr	divu32			;オフセット÷ダンプ幅
		movea.l	(sp)+,a0
		rts

* in	d0.l	DUMP 物理行
* out	d0.l	CDMP 行
dump_to_cdmp:
		move.l	a1,-(sp)
		lea	(dump_width,pc),a1
		bsr	mulu32x16_d0		;行数×ダンプ幅
		moveq	#0,d1
		move	(cdmp_width,pc),d1
		bsr	divu32			;オフセット÷ダンプ幅
		movea.l	(sp)+,a1
		rts

* in	d0.l	VIEW 物理行
* out	d0.l	DUMP 行
cdmp_to_view:
		PUSH	d1-d2/a1
		lea	(cdmp_width,pc),a1
		bsr	mulu32x16_d0		;行数×ダンプ幅
		movea.l	(file_buf-a5sp,a5),a1	;ファイル先頭アドレス
		add.l	a1,d0			;現在表示中テキストアドレス
		movea.l	(line_buf_last-a5sp,a5),a1
		moveq	#-1,d1
@@:
		addq.l	#1,d1			;VIEW 物理行を求める
		GETBUFPTR  -(a1),d2
		cmp.l	d2,d0
		subq.l	#4,a1
		bhi	@b

		move.l	d1,d0
		POP	d1-d2/a1
		rts


* [FG] 行番号表示切り換え --------------------- *
fg_toggle_line_num:
		bsr	delete_window

		lea	(＄lnum),a0		;VIEW
		lea	(lnum_save-a5sp,a5),a1
		tst	(look_mode-a5sp,a5)
		beq	@f
		lea	(＄dnum-＄lnum,a0),a0	;DUMP/CDMP
		addq.l	#dnum_save-lnum_save,a1
@@:
		move	(a1),d0
		move	(a0),(a1)
		beq	@f
		moveq	#0,d0			;on -> off
		bra	1f
@@:
		tst	d0
		bne	1f			;off -> on(pop)
		moveq	#1,d0			;off -> on(最初から off なら blue にする)
1:
		move	d0,(a0)

		pea	(str_tgl_lnum,pc)
		bra	reset_screen_mode
**		rts


* [FG] タブ表示切り換え ----------------------- *
fg_toggle_tab:
		bsr	bel_clr
		lea	(str_tgl_tab,pc),a1
		bsr	bel_sub2_p2

		eori	#1,(＄tabc)
		bra	redraw_page


* [FG] タブサイズ切り換え --------------------- *
fg_toggle_tabsize:
		bsr	bel_clr
		lea	(str_tgl_tab_sz,pc),a1
		bsr	bel_sub2_p2

		eori	#4.xor.8,(file_tabsize-a5sp,a5)
		bsr	set_tabsize		;タブサイズ変更
		bra	redraw_page


* [FG] 正規化モード切り換え ------------------- *
fg_toggle_regular:
		bsr	bel_clr
		lea	(str_tgl_reg,pc),a1
		bsr	bel_sub2_p2

		not.b	(look_yar_flag-a5sp,a5)
		bsr	print_info_line
		bra	redraw_page


* [FG] 改行表示切り換え ----------------------- *
fg_toggle_cr_disp:
		bsr	bel_clr
		lea	(str_tgl_cr,pc),a1
		bsr	bel_sub2_p2

		eori	#1,(＄vret)
		bra	redraw_page
**		rts

redraw_page:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
call_one_page_print:
		pea	(one_page_print,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		rts


* [FG] 文字コード切り換え --------------------- *
fg_change_code:
		bsr	bel_clr
		lea	(str_tgl_code,pc),a1
		bsr	bel_sub2_p2

		tst.b	(kanji_code-a5sp,a5)
		bmi	euc_to_jis
		subq.b	#1,(kanji_code-a5sp,a5)	;SJIS($00)-> EUC($ff)
		bra	@f			; JIS($01)->SJIS($00)
euc_to_jis:
		addq.b	#2,(kanji_code-a5sp,a5)	; EUC($ff)-> JIS($01)
@@:
		st	(ksi-a5sp,a5)
		st	(jis_mb_not-a5sp,a5)
		bsr	print_info_line
		bra	redraw_page
**		rts


* [FG] カーソル位置マーク --------------------- *
fg_mark:
		GETMES_A1  MES_VMARK

		move.l	(top_line-a5sp,a5),d0
		move.l	d0,(top_line2-a5sp,a5)
		add.l	(cursor_line-a5sp,a5),d0
		addq.l	#1,d0
		move.l	d0,(mark_line_phy-a5sp,a5)
		subq.l	#1,d0
		tst	(look_mode-a5sp,a5)
		bne	@f

		lsl.l	#3,d0
		neg.l	d0
		movea.l	(line_buf_last-a5sp,a5),a0
		GETLINENUM  (-8,a0,d0.l),d0
@@:
		addq.l	#1,d0
		move.l	d0,(mark_line_log-a5sp,a5)

		lea	(-(12+2),sp),sp
		lea	(sp),a0
		moveq	#12-1,d1
@@
		move.b	(a1)+,(a0)+
		dbra	d1,@b
		clr	(a0)
		subq.l	#1,a0			;')'
@@:
		divu	#10,d0
		swap	d0
		addi	#'0',d0
		move.b	d0,-(a0)
		clr	d0
		swap	d0
		bne	@b

		bsr	bel_clr
		lea	(sp),a1
		bsr	bel_sub_p2
		lea	(12+2,sp),sp

		bsr	call_one_page_print
		tst.b	(csr_disp_flag-a5sp,a5)
		bne	draw_cursor
		rts


* [FG] マーク位置に移動 ----------------------- *
fg_goto_mark:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)

		move.l	(top_line2-a5sp,a5),(top_line-a5sp,a5)
		bsr	call_one_page_print

		bsr	bel_clr
		lea	(str_goto_mark,pc),a1
		bra	bel_sub2_p2
**		rts


* [FG] マーク/カーソル位置交換 ---------------- *
fg_exg_point_mark:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)

		move.l	(top_line-a5sp,a5),-(sp)
		move.l	(top_line2-a5sp,a5),(top_line-a5sp,a5)
		bsr	call_one_page_print
		move.l	(sp)+,(top_line2-a5sp,a5)

		bsr	bel_clr
		lea	(str_exg_p_m,pc),a1
		bra	bel_sub2_p2
**		rts


* 文字列検索 ---------------------------------- *
* in	d0.b	プロンプトのメッセージ番号

new_search_common:
		bsr	get_message_a1
		move.l	a1,-(sp)
		lea	(subwin_input,pc),a0
		moveq	#MES_L_STR,d0
		moveq	#82,d1
		bsr	window_init
		movea.l	(sp)+,a1
		STRLEN	a1,d1
		jsr	(WinPrint)

		tst	(＄ivss)
		bne	@f
		clr.b	(search_str_buf-a5sp,a5)
@@:
		tst.b	(search_type-a5sp,a5)
		bne	1f
		tst.b	(kanji_code-a5sp,a5)
		bpl	@f
1:
		lea	(search_str_buf2-a5sp,a5),a1
		lea	(search_str_buf-a5sp,a5),a2
		STRCPY	a1,a2
@@:
		moveq	#82-2,d0
		sub	d1,d0
		bgt	@f
		moveq	#80,d0
@@:		moveq	#80,d1
		lea	(search_str_buf-a5sp,a5),a1
		bsr	look_command_edit
		bmi	new_search_common_abort

		lea	(search_str_buf-a5sp,a5),a1
		lea	(search_str_buf2-a5sp,a5),a2
		move.b	(a1)+,(a2)+
		beq	new_search_common_abort
		STRCPY	a1,a2

		tst.b	(kanji_code-a5sp,a5)
		bpl	new_search_common_end

		lea	(search_str_buf-a5sp,a5),a0
		bsr	sjis2euc
new_search_common_end:
		moveq	#0,d0
		rts
new_search_common_abort:
		moveq	#-1,d0
		rts


* [FG] ↓方向検索 ----------------------------- *
fg_search_forward:
		moveq	#MES_VSCHF,d0
		bsr	new_search_common
		bne.s	9f

		lea	(search_str_buf-a5sp,a5),a1
		bsr	bm_comp
		move.l	(top_line-a5sp,a5),d1	;最初は画面の先頭
		move.l	d1,(last_search_line-a5sp,a5)
		bsr	search_forward_sub
		sne	(sch_next_flag-a5sp,a5)
		st	(searched_flag-a5sp,a5)
9:
		rts


* [FG] ↓方向次検索 --------------------------- *
fg_search_f_next:
		tst.b	(searched_flag-a5sp,a5)
		beq.s	9b

		move.l	(top_line-a5sp,a5),(last_search_line-a5sp,a5)
		tst.b	(sch_next_flag-a5sp,a5)
		beq	@f

		clr.b	(sch_next_flag-a5sp,a5)	;前回検索失敗
		moveq	#0,d1
		bra	2f
@@:
		move.l	(top_line-a5sp,a5),d1
		tst.b	(csr_disp_flag-a5sp,a5)
		beq	1f
		add.l	(cursor_line-a5sp,a5),d1
1:		addq.l	#1,d1
2:
		tst.b	(search_type-a5sp,a5)
		beq	3f
		bsr	search_regexp_sub
		bra	4f
3:		bsr	search_forward_sub
4:		beq.s	9b

		move.l	(last_search_line-a5sp,a5),(top_line-a5sp,a5)
		bra	fg_search_not_found


* [FG] ↑方向検索 ----------------------------- *
fg_search_reverse:
		moveq	#MES_VSCHB,d0
		bsr	new_search_common
		bne.s	9f

		lea	(search_str_buf-a5sp,a5),a1
		bsr	bm_comp
		move.l	(top_line-a5sp,a5),d1
		add.l	(line_num1-a5sp,a5),d1
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		cmp.l	d0,d1
		bls	@f
		move.l	d0,d1
@@:
		move.l	d1,(last_search_line-a5sp,a5)
		bsr	search_reverse_sub
		sne	(sch_next_flag-a5sp,a5)
		st	(searched_flag-a5sp,a5)
9:
		rts


* [FG] ↑方向次検索 --------------------------- *
fg_search_r_next:
		tst.b	(searched_flag-a5sp,a5)
		beq	9b
		tst.b	(search_type-a5sp,a5)
		bne	9b			;正規化逆検索は出来ない
		tst.b	(sch_next_flag-a5sp,a5)
		beq	@f

		clr.b	(sch_next_flag-a5sp,a5)	;前回検索失敗
		move.l	(total_line-a5sp,a5),d1
		subq.l	#1,d1
		bra	1f
@@:
		move.l	(top_line-a5sp,a5),d1
		tst.b	(csr_disp_flag-a5sp,a5)
		bne	2f
		add.l	(line_num2-a5sp,a5),d1
		move.l	(total_line-a5sp,a5),d0
		subq.l	#1,d0
		cmp.l	d0,d1
		bls	1f
		move.l	d0,d1
		bra	1f
2:		add.l	(cursor_line-a5sp,a5),d1
1:		subq.l	#1,d1
		bpl	@f			;[TOF] 検索を回避
		tst.b	(sch_next_flag-a5sp,a5)
		beq	fg_search_not_found

		move.l	(total_line-a5sp,a5),d1
		subq.l	#2,d1
@@:
		bsr	search_reverse_sub
		beq	9b
fg_search_not_found:
		st	(sch_next_flag-a5sp,a5)
		bra	fg_bell


* [FG] 警告音出力 ----------------------------- *
fg_bell:
		jmp	(＆v_bell)
**		rts


* [FG] ↓方向正規表現(次)検索 ----------------- *
fg_search_regexp:
fg_search_reg_next:
		moveq	#MES_VSCHR,d0
		bsr	new_search_common
		bne.s	9f

		move.b	(search_str_buf-a5sp,a5),(search_header-a5sp,a5)

		move.l	(top_line-a5sp,a5),d1	;最初は画面の先頭
		move.l	d1,(last_search_line-a5sp,a5)
		st	(search_type-a5sp,a5)
		bsr	search_regexp_sub
		sne	(sch_next_flag-a5sp,a5)
		st	(searched_flag-a5sp,a5)
9:
		rts

swap_fpr_fque:
		move	(_fpr),-(sp)
		move	(_fque),(_fpr)
		move	(sp)+,(_fque)
		rts

* ↓方向正規表現検索下請け
search_regexp_sub:
		move.l	d1,d5
		bsr	line_to_address_d1_to_a4_d4
		move.l	(file_size-a5sp,a5),d0
		add.l	(file_buf-a5sp,a5),d0
		move.l	d0,(_text_end_address)	;検索最終メモリ

		move.b	(search_header-a5sp,a5),(search_str_buf-a5sp,a5)

		moveq	#1,d1
		ror.l	#1,d1			;bit31=1
		move.b	(search_exact-a5sp,a5),d1
		addq.b	#1,d1
		move.l	d1,(_ignore_case)

		link	a6,#-512
		pea	(-512,a6)
		move.l	(sp)+,d3

		bsr	swap_fpr_fque		;_fre_compile の . と ? を入れ換える

		pea	(search_str_buf-a5sp,a5)
		pea	(256)			;512.b
		move.l	d3,-(sp)
		jsr	(_fre_compile)
		bsr	swap_fpr_fque		;元に戻す
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	@f

		movea.l	d0,a1
		bsr	bel_clr
		bsr	bel_sub2_p2
		bra	regexp_compile_error
@@:
		bsr	print_now_hunting

		move.l	a4,-(sp)		;string
		move.l	d3,-(sp)		;buffer
		jsr	(_fre_match)
		addq.l	#8,sp
		tst.l	d0
		beq	not_match

		moveq	#0,d0			;検索成功
		tst	(look_mode-a5sp,a5)
		beq	6f

		move.l	a1,d0
		sub.l	(file_buf-a5sp,a5),d0
		moveq	#0,d1
		cmpi	#1,(look_mode-a5sp,a5)
		beq	1f
		move	(cdmp_width,pc),d1
		bra	2f
1:		move	(dump_width,pc),d1
2:		bsr	divu32			;オフセット÷ダンプ幅
		move.l	d0,d1
		bra	3f
6:
		move.l	d5,d1			;検索先頭ライン
		addq.l	#1,d1
		move.l	a1,d2
		lsl.l	#3,d1
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a2
		lea	(a2,d1.l),a2
		move.l	d5,d1
@@:
		addq.l	#1,d1
		GETBUFPTR  -(a2),d0
		cmp.l	d0,d2
		subq.l	#4,a2
		bcc	@b
		subq	#1,d1
3:
		cmp.l	(total_line-a5sp,a5),d1
		bcc	not_match

		move.l	d1,(last_search_line-a5sp,a5)
		moveq	#12,d0			;確定サーチライン
		sub.l	d0,d1
		bpl	@f
		moveq	#0,d1
@@:
		bsr	topline_adjust
		bset	#COM_JUMPL,(fg_stat-a5sp,a5)
		bsr	print_find_string	;↑ライン付き描画命令
		moveq	#0,d0
		bra	@f
not_match:
		bsr	print_not_find_string
regexp_compile_error:
		moveq	#1,d0
@@:
		unlk	a6
		sne	(sch_next_flag-a5sp,a5)
		st	(searched_flag-a5sp,a5)
		sf	(search_str_buf-a5sp,a5)
**		tst.l	d0
		rts


line_to_address_d1_to_a4_d4:
		cmpi	#1,(look_mode-a5sp,a5)
		bcs	@f
		lea	(dump_width,pc),a1
		beq	1f
		addq.l	#cdmp_width-dump_width,a1
1:		bsr	mulu32x16_d1		;行数×ダンプ幅
		movea.l	(file_buf-a5sp,a5),a1
		lea	(a1,d1.l),a4
		rts
@@:
		lsl.l	#3,d1
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a1
		GETBUFPTR  (-4,a1,d1.l),a4
		rts


* ↓方向検索下請け
* in	d1.l	検索開始行番号
* out	d0.l	 0 = 検索成功
*		-1 = 検索失敗

search_forward_sub:
		clr.b	(search_type-a5sp,a5)
		bsr	print_now_hunting

		move.l	d1,d5
		bsr	line_to_address_d1_to_a4_d4
		movea.l	a4,a1
		move.l	(file_size-a5sp,a5),d4
		add.l	(file_buf-a5sp,a5),d4	;検索最終メモリ
f_s1:
		PUSH	a5-a6
		movea.l	a4,a5			;テキスト先頭
		movea.l	d4,a6			;テキスト末尾
		bsr	bm_forward		;in:a5/a6 out:a1/ccr
		POP	a5-a6
		bne	f_s20
f_s10:
		st	(searched_flag-a5sp,a5)	;完全一致
		tst	(look_mode-a5sp,a5)
		beq	6f

		move.l	a1,d0
		sub.l	(file_buf-a5sp,a5),d0
		moveq	#0,d1
		cmpi	#1,(look_mode-a5sp,a5)
		beq	1f
		move	(cdmp_width,pc),d1
		bra	2f
1:		move	(dump_width,pc),d1
2:		bsr	divu32			;オフセット÷ダンプ幅
		move.l	d0,d1
		bra	3f
6:
		move.l	d5,d1			;検索先頭ライン
		addq.l	#1,d1
		move.l	a1,d2
		lsl.l	#3,d1
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a2
		lea	(a2,d1.l),a2
		move.l	d5,d1
f_s11:
		addq.l	#1,d1
		GETBUFPTR  -(a2),d0
		cmp.l	d0,d2
		subq.l	#4,a2
		bcc	f_s11
		subq	#1,d1
3:
		cmp.l	(total_line-a5sp,a5),d1
		bcc	f_s20

		move.l	d1,(last_search_line-a5sp,a5)
		sub.l	#12,d1			;確定サーチライン
		bpl	@f
		moveq	#0,d1
@@:
		bsr	topline_adjust
		bset	#COM_JUMPL,(fg_stat-a5sp,a5)
		bsr	print_find_string	;ライン付き描画命令
		moveq	#0,d0
		rts
f_s20:
		bsr	print_not_find_string	;完全不一致
		moveq	#-1,d0
		rts


* ↑方向検索下請け
* in	d1.l	検索開始行番号
* out	d0.l	 0 = 検索成功
*		-1 = 検索失敗

search_reverse_sub:
		bsr	print_now_hunting
		tst.b	(search_str_buf-a5sp,a5)
		beq	b_s98

		addq.l	#1,d1
		move.l	d1,d5			;検索先頭ライン
		bsr	line_to_address_d1_to_a4_d4
		movea.l	a4,a1
		move.l	(file_buf-a5sp,a5),d4	;ファイル先頭
b_s1:
		PUSH	a5-a6
		movea.l	a4,a6
		movea.l	d4,a5
		bsr	bm_reverse
		POP	a5-a6
		bne	f_s20
b_s10:
		st	(searched_flag-a5sp,a5)	;完全一致
		tst	(look_mode-a5sp,a5)
		beq	6f

		move.l	a1,d0
		sub.l	(file_buf-a5sp,a5),d0
		moveq	#0,d1
		cmpi	#1,(look_mode-a5sp,a5)
		beq	1f
		move	(cdmp_width,pc),d1
		bra	2f
1:		move	(dump_width,pc),d1
2:		bsr	divu32			;オフセット÷ダンプ幅
		move.l	d0,d1
		bra	3f
6:
		move.l	d5,d1			;検索開始ライン
		move.l	a1,d2
		lsl.l	#3,d1
		neg.l	d1
		movea.l	(line_buf_last-a5sp,a5),a2
		lea	(4,a2,d1.l),a2		;検索開始行管理エリア
		move.l	d5,d1
b_s11:
		subq.l	#1,d1
		GETBUFPTR  (a2)+,d0
		cmp.l	d0,d2
		addq.l	#4,a2
		bcs	b_s11
3:
		move.l	d1,(last_search_line-a5sp,a5)
		sub.l	#12,d1			;確定サーチライン
		bpl	@f
		moveq	#0,d1
@@:
		bsr	topline_adjust
		bset	#COM_JUMPL,(fg_stat-a5sp,a5)
		bsr	print_find_string	;ライン付き描画命令
		moveq	#0,d0
		rts
b_s20:
		bsr	print_not_find_string
b_s98:
		moveq	#-1,d0
		rts


* d1.w で指定した top_line が total_line より溢れていたら修正する
* in	d1.w	現在の top_line
* out	d0.w	top_line = 修正後 top_line

topline_adjust:
		move.l	d1,d0
		add.l	(line_num2-a5sp,a5),d1
		cmp.l	(total_line-a5sp,a5),d1
		bcs	@f
		move.l	(total_line-a5sp,a5),d0
		sub.l	(line_num2-a5sp,a5),d0
		bpl	@f
		moveq	#0,d0
@@:
		move.l	d0,(top_line-a5sp,a5)
		rts


* [FG] ↓方向遂次検索 ------------------------- *
fg_is_forward:
.if 0
		bsr	bel_clr
		lea	(str_is_f,pc),a1
		bsr	bel_sub_p2
.endif
		rts

* [FG] ↑方向遂次検索 ------------------------- *
fg_is_reverse:
.if 0
*		bsr	bel_clr
*		lea	(str_is_r,pc),a1
*		bsr	bel_sub_p2
.endif
		rts


* BM 法検索用テーブル作成 --------------------- *

* 検索文字列からテーブルを生成する
* in	a1.l	検索文字列
* out	d1.l	文字列長
* 参考:
*	Oh!X 1993 March p60

bm_comp_f:
		PUSH	d0/d2-d4/a0-a3
		lea	(bm_patlen),a0		;ワーク先頭
		lea	(bm_pat),a2		;反転パターン
		moveq	#0,d0
		moveq	#0,d2
		moveq	#0,d3			;jis flag(未使用)
		move.b	(search_exact),d4	;ignore case(0)/case(-1)
		move	#255,d1
		move	d1,d0
		tst.b	d4			;case flag
		beq	cp_icase
@@:
		move.b	(a1)+,(a2)+		;case
		dbeq	d1,@b
		bra	cp_end
cp_icase:
		lea	(ctypetable),a3		;ignore case
cplp_i:
		move.b	(a1)+,d2
		tst.b	(a3,d2.w)
		bpl	cpnjis
		move.b	d2,(a2)+		;二バイト文字
		move.b	(a1)+,(a2)+		;
		subq	#2,d1
		bpl	cplp_i
		bra	toolng
cpnjis:
		btst	#IS_UPPER,(a3,d2.w)
		beq	@f
		ori.b	#$20,d2			;小文字化
@@:		move.b	d2,(a2)+
		dbeq	d1,cplp_i
cp_end:
		bne	toolng

		sub	d1,d0			;検索文字列長
		move	d0,d1
		subq	#1,d1			;検索文字列長-1
		move	d1,(a0)+		;検索文字列長-1 を bm_patlen に格納
		bmi	cretn			;検索文字列長が 0

		move	#255,d1			;bm_table を検索文字列長で埋める
@@:		move.b	d0,(a0)+
		dbra	d1,@b

		movea.l	a0,a1			;検索文字列
		movea.l	a0,a2
		lea	(bm_table),a0
		moveq	#0,d1			;make table
		subq	#1,d0			;検索文字列長-1
		tst.b	d4			;区別フラグ
		beq	mktbl_icase
mk_case_tbl:
		move.b	(a2)+,d1		;make cased table
		move.b	d0,(a0,d1.w)
		dbra	d0,mk_case_tbl
		bra	revlp
mktbl_icase:
		move.b	(a2)+,d1		;make ignor cased table
		tst.b	(a3,d1.w)
		bpl	mktbl_iank
mktbl_ijis:
		move.b	d0,0(a0,d1.w)
		subq	#1,d0
**		bmi	revlp			;あり得ない
		move.b	(a2)+,d1
* 下位バイトは半角と同扱い、hitmiss は後で除去
**		bra	comcpy
mktbl_iank:
		btst	#IS_ALPHA,(a3,d1.w)
		beq	comcpy
		ori.b	#$20,d1			;小文字化
		move.b	d0,(-$20,a0,d1.w)
comcpy:
		move.b	d0,(a0,d1.w)
		dbra	d0,mktbl_icase
revlp:
		move.b	-(a2),d1		;後の処理に備えて
		move.b	(a1),(a2)		;検索文字列を反転しておく
		move.b	d1,(a1)+
		cmpa.l	a2,a1
		bcs	revlp

		move	-(a0),d1		;文字列長を取り出す
		addq	#1,d1
cretn:
		POP	d0/d2-d4/a0-a3
		rts
toolng:
		moveq	#-1,d0
		bra	cretn


bm_comp::
		bsr	bm_comp_f
		bra	bm_comp_r
**		rts


bm_comp_r:
		PUSH	d0/d2-d4/a0-a3
		lea	(bm_patlen_r),a0	;ワーク先頭
		lea	(bm_pat_r),a2		;パターン
		moveq	#0,d0
		moveq	#0,d2
		moveq	#0,d3			;jis flag(未使用)
		move.b	(search_exact),d4	;ignore case(0)/case(-1)
		move	#255,d1
		move	d1,d0
		tst.b	d4			;case flag
		beq	cp_icase_r
@@:
		move.b	(a1)+,(a2)+		;case
		dbeq	d1,@b
		bra	cp_end_r
cp_icase_r:
		lea	(ctypetable),a3		;ignore case
cplp_i_r:
		move.b	(a1)+,d2
		tst.b	(a3,d2.w)
		bpl	cpnjis_r
		move.b	d2,(a2)+		;二バイト文字
		move.b	(a1)+,(a2)+		;
		subq	#2,d1
		bpl	cplp_i_r
		bra	toolng_r
cpnjis_r:
		btst	#IS_UPPER,(a3,d2.w)
		beq	@f
		ori.b	#$20,d2			;小文字化
@@:		move.b	d2,(a2)+
		dbeq	d1,cplp_i_r
cp_end_r:
		bne	toolng_r

		sub	d1,d0			;検索文字列長
		move	d0,d1
		subq	#1,d1			;検索文字列長-1
		move	d1,(a0)+		;bm_patlen に格納
		bmi	cretn_r			;検索文字列長が 0

		move	#255,d1			;bm_table を検索文字列長で埋める
@@:
		move.b	d0,(a0)+
		dbra	d1,@b

		movea.l	a0,a1			;検索文字列
		subq	#1,a2
		lea	(bm_table_r),a0
		moveq	#0,d1			;make table
		subq	#1,d0			;検索文字列長-1
		tst.b	d4
		beq	mktbl_icase_r
mk_case_tbl_r:
		move.b	-(a2),d1		;make cased table
		move.b	d0,(a0,d1.w)
		dbra	d0,mk_case_tbl_r
		bra	revlp_r
mktbl_icase_r:
		move.b	-(a2),d1		;make ignore cased table
		exg	a2,a1
		bsr	is_mbtrail_a1
		exg	a2,a1
		bcc	mktbl_iank_r
mktbl_ijis_r:
		btst.b	#IS_ALPHA,(a3,d1.w)
		beq	@f
		ori.b	#$20,d1			;小文字化
		move.b	d0,(-$20,a0,d1.w)
@@:		move.b	d0,(a0,d1.w)
		subq	#1,d0
**		bmi	revlp			;あり得ない
		move.b	-(a2),d1
		bra	comcpy_r
mktbl_iank_r:
		btst.b	#2,(a3,d1.w)
		beq	comcpy_r
		ori.b	#$20,d1			;小文字化
		move.b	d0,(-$20,a0,d1.w)
comcpy_r:	move.b	d0,(a0,d1.w)
		dbra	d0,mktbl_icase_r
revlp_r:
		move	-(a0),d1		;文字列長を取り出す
		addq	#1,d1
cretn_r:
		POP	d0/d2-d4/a0-a3
		rts
toolng_r:
		moveq	#-1,d0
		bra	cretn


* BM 法後方検索 ------------------------------- *
* in	a5.l	テキスト先頭
*	a6.l	テキスト末尾
* out	a1.l	発見した文字列アドレス
*	ccr	N=0:発見 N=1:未発見

bm_forward::
		PUSH	d0-d3/a2-a5
		lea	(bm_patlen),a1		;ワーク先頭
		lea	(bm_pat+1),a2		;検索文字列末尾の１文字手前
		move	(a1)+,d1		;検索文字列の長-1
		bmi	nmatch			;検索文字列長が 0

		adda	d1,a5			;検索文字列末尾との重ね位置
		subq	#1,d1			;検索文字列長-1 の dbra カウンタ

		moveq	#0,d0			;検索文字列末尾文字と一致する文字を探す
		moveq	#0,d3
		bra	next0
loop0:
		move.b	(a5),d0			;入力文字
		move.b	(a1,d0.w),d0		;対応する移動量
		beq	break0			;それが 0 なら検索文字列末尾の文字
		adda	d0,a5			;ポインタを移動量分進める
next0:
		cmpa.l	a6,a5			;末尾を越えるまで繰り返す
		bcs	loop0
		bra	nmatch			;検索文字列は見つからなかった
break0:
		movea.l	a5,a3			;a5 = 検索文字列末尾との一致位置
		movea.l	a2,a4			;a4 = 検索文字列末尾の１文字手前
		move	d1,d2			;dbra カウンタ
		bmi	zchk			;検索文字列長が 1 だった
loop1:
		move.b	-(a3),d0		;検索文字列末尾から照合
		move.b	(a4)+,d3
		move.b	(a1,d0.w),d0
		move.b	(a1,d3.w),d3
		cmp.b	d0,d3
		dbne	d2,loop1
		beq	zchk			;全文字一致した

		adda	d0,a3			;その分ポインタを進める
		exg.l	a3,a5
		cmpa.l	a5,a3
		bcs	next0
		lea	(2,a3),a5		;後退したら 2 バイト進める
		cmpa.l	a6,a5			;末尾を越えるまで繰り返す
		bcs	loop0
nmatch:
		moveq	#-1,d0			;照合失敗
		POP	d0-d3/a2-a5
		rts

zchk:
		exg	a3,a1
		bsr	is_mbtrail_a1
		bcc	@f
		exg	a3,a1
		bra	loop1
@@:
		PUSH	a1-a3
		lea	(ctypetable),a3
		lea	(bm_pat_r),a2
@@:
		move.b	(a2)+,d0
		beq	@f
		move.b	(a1)+,d3
		tst.b	(a3,d0.w)
		bpl	@b
**		cmp.b	d0,d3			;全角上位は比較の必要なし
**		beq	@b
		cmpm.b	(a1)+,(a2)+
		beq	@b
@@:
		POP	a1-a3
		beq	qretn
		exg	a3,a1
		bra	loop1
qretn:
		moveq	#0,d0
		POP	d0-d3/a2-a5
		rts


* BM 法後方検索 ------------------------------- *
* in	a5.l	テキスト先頭
*	a6.l	テキスト末尾
* out	a1.l	発見した文字列アドレス
*	ccr	N=0:発見 N=1:未発見

bm_reverse::
		PUSH	d0-d3/a2-a5
		lea	(bm_patlen_r),a1	;ワーク先頭
		lea	(bm_pat_r+1),a2		;検索文字列末尾の１文字手前
		move	(a1)+,d1		;検索文字列の長－１
		bmi	nmatch_b		;検索文字列長が 0

		suba	d1,a6			;検索文字列末尾との重ね位置
		subq	#1,a6
		subq	#1,d1			;検索文字列長-1 の dbra カウンタ

		moveq	#0,d0			;検索文字列先頭文字と一致する文字を探す
		moveq	#0,d3
		bra	next0_b
loop0_b:
		move.b	(a6),d0			;入力文字
		move.b	(a1,d0.w),d0		;対応する移動量
		beq	break0_b		;それが 0 なら検索文字列末尾の文字
		suba	d0,a6			;ポインタを移動量分進める
next0_b:
		cmpa.l	a6,a5			;先頭を越えるまで繰り返す
		bcs	loop0_b
		bra	nmatch_b		;検索文字列は見つからなかった
break0_b:
		movea.l	a6,a3			;a5 = 検索文字列先頭との一致位置
		movea.l	a2,a4			;a4 = 検索文字列先頭の１文字手前
		move	d1,d2			;dbra カウンタ
		bmi	zchk_b			;検索文字列長が 1 だった
		addq.l	#1,a3
loop1_b:
		move.b	(a3)+,d0		;検索文字列先頭から照合
		move.b	(a4)+,d3
		move.b	(a1,d0.w),d0
		move.b	(a1,d3.w),d3
		cmp.b	d0,d3
		dbne	d2,loop1_b
@@:		beq	zchk_b			;全文字一致した

		subq.l	#1,a3
		suba	d0,a3			;その分ポインタを戻す
		exg.l	a3,a6
		cmpa.l	a3,a6
		bcs	next0_b
		lea	-2(a3),a6		;前進したら 2 バイト戻る
		cmpa.l	a6,a5			;先頭を越えるまで繰り返す
		bcs	loop0_b
nmatch_b:
		moveq	#-1,d0			;照合失敗
		POP	d0-d3/a2-a5
		rts

zchk_b:
		exg	a6,a1
		bsr	is_mbtrail_a1
		bcc	@f
		exg	a6,a1
		bra	loop1_b
@@:
		PUSH	a1-a3
		lea	(ctypetable),a3
		lea	(bm_pat_r),a2
@@:
		move.b	(a2)+,d0
		beq	@f
		move.b	(a1)+,d3
		tst.b	(a3,d0.w)
		bpl	@b
**		cmp.b	d0,d3			;全角上位は比較の必要なし
**		beq	@b
		cmpm.b	(a1)+,(a2)+
		beq	@b
@@:
		POP	a1-a3
		beq	qretn
		exg	a6,a1
		bra	loop1_b


* 行入力用ウィンドウ描画 ---------------------- *

window_init:
		PUSH	d1-d2/a1
		move	d1,(SUBWIN_XSIZE,a0)
		bsr	get_message_a1
		move.l	a1,(SUBWIN_TITLE,a0)

		lea	(＄wind),a1
		move	(a1),(wind_save-a5sp,a5)
		tst.b	(look_color_flag-a5sp,a5)
		beq	window_init_no_col

		clr	(a1)			;カラー表示の時は %wind 0 にする

		move	(SUBWIN_Y,a0),d1
		lsl	#8,d1
		lsl	#2,d1			;Y *= 4
		move.b	#$ef-(3*4-1),d1
		moveq	#3*4,d2
		moveq	#$0f,d3
		movem	d1-d3,(txrascpy_regs-a5sp,a5)
		IOCS	_TXRASCPY		;プレーン 2/3 保存

		lea	(txfill_buf,pc),a1
		movem.l	(SUBWIN_X,a0),d0-d1	;X/Y 座標、X/Y サイズ
		addq	#2,d1			;Ysize += 2;
		lsl.l	#3,d0			;X *= 8
		lsl.l	#3,d1
		add	d0,d0			;Y *= 16
		add	d1,d1
		movem.l	d0-d1,(TXBOX_XSTART,a1)
		IOCS	_TXFILL			;プレーン 2/3 クリア
window_init_no_col:
		POP	d1-d2/a1

		jsr	(WinOpen)
		move	d0,(win_no_input-a5sp,a5)
		moveq	#1,d1
		moveq	#1,d2
		jmp	(WinSetCursor)
**		rts


* 書き出しファイル名入力 ---------------------- *

input_write_filename:
		lea	(subwin_input,pc),a0
		moveq	#MES_L_FIL,d0
		moveq	#82,d1
		bsr	window_init

		lea	(write_path-a5sp,a5),a1
		lea	(write_filename-a5sp,a5),a2
		tst.b	(a1)
		beq	input_write_fn_curdir
		STRCPY	a1,a2
		bra	@f
input_write_fn_curdir:
		lea	(a2),a1
		jsr	(get_curdir_a1)		;-o 未指定時はカレントディレクトリ
@@:
		moveq	#80,d0
		moveq	#80,d1
		lea	(write_filename-a5sp,a5),a1
		bsr	look_command_edit
		bmi	input_write_filename_abort

		moveq	#SPACE,d0
		lea	(write_filename-a5sp,a5),a1
		lea	(a1),a2
@@:
		cmp.b	(a1)+,d0		;先頭の空白を飛ばす
		beq	@b
		subq.l	#1,a1
@@:
		move.b	(a1)+,(a2)+
		beq	@f
		cmp.b	(a1),d0
		bne	@b
		clr.b	(a2)			;空白があればそれ以降は無視する
@@:
		moveq	#0,d0
		rts
input_write_filename_abort:
		moveq	#-1,d0
		rts


* 行入力 -------------------------------------- *
* in	d0.w	ウィンドウ幅
*	d1.w	最大入力バイト数
*	a1.l	バッファアドレス
* out	ccr	Z=1,N=0:確定 Z=0,N=1:取消
* break	d0-d2

look_command_edit:
		bsr	iocs_key_flush_cond_kill

		swap	d0
		swap	d1
		move	(win_no_input-a5sp,a5),d0
		move	#RL_F_QUIET,d1
		jsr	(MintReadLine)
		move.l	d0,-(sp)

		move	(win_no_input-a5sp,a5),d0
		jsr	(WinClose)
.if 1
		move	(wind_save-a5sp,a5),(＄wind)
		tst.b	(look_color_flag-a5sp,a5)
		beq	look_cmd_edit_no_col

		movem	(txrascpy_regs-a5sp,a5),d1-d3
		ror	#8,d1
		IOCS	_TXRASCPY		;プレーン 2/3 復帰
look_cmd_edit_no_col:
.else
		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		pea	(set_palet_sub,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
@@:
.endif
		bsr	init_keyflags
		tst.l	(sp)+
		rts


* メッセージ表示 ------------------------------ *

print_now_hunting:
		PUSH	d0-d2/a1
		bsr	bel_clr
		tst.b	(search_str_buf-a5sp,a5)
		beq	p_f_s1
		moveq	#MES_VHUNT,d0
		bra	@f
print_find_string:
		PUSH	d0-d2/a1
		bsr	bel_clr
		tst.b	(search_str_buf-a5sp,a5)
		beq	p_f_s1

		moveq	#MES_L_SCH,d0
@@:
		bsr	get_message_a1
		bsr	bel_sub2_p2
		lea	(search_str_buf-a5sp,a5),a1
		tst.b	(kanji_code-a5sp,a5)
		bpl	@f
		lea	(search_str_buf2-a5sp,a5),a1
@@:
		jsr	(WinPrint)
p_f_s1:
		clr	(search_timer-a5sp,a5)
		POP	d0-d2/a1
		rts

print_not_find_string:
		bsr	bel_clr
		GETMES_A1  MES_VNOTF
		bra	bel_sub2_p2
**		rts
.if 0
print_break_search_string:
		bsr	bel_clr
		lea	(str_break,pc),a1
		bra	bel_sub2_p2
**		rts
.endif

bel_clr:
		move	(win_no_message-a5sp,a5),d0
		jmp	(WinClearAll)
**		rts


* 割り込み処理 -------------------------------- *

* fg_stat
*	bit 0	読込中
*	bit 1	表処理待
*	bit 2	行番号ジャンプ
*	bit 3	行番号ジャンプライン付き
*	bit 7	１フレーム読込終了
* a0:未使用
* a1:汎用
* a2:未使用
* a3:未使用
* a4:int_flag

look_interpt_entry:
		PUSH	d0-d7/a0-a6
		lea	(a5sp),a5
		andi.b	#%00111111,(MFP_IMRA)
		lea	(int_flag-a5sp,a5),a4
		tst.b	(a4)			;多重割り込みチェック
		bne	look_interrupt_end_2

		move.b	#1,(a4)

		lea	(4*(8+7),sp),a1		;ステータスレジスタ
		move.l	a1,(int_sr_ptr-a5sp,a5)
l_i_e0:
		move.b	(fg_stat-a5sp,a5),d5
		btst	#COM_REQ,d5
		bne	look_interrupt_end_1

		move	(ras_req_count-a5sp,a5),d1
		beq	@f

		bsr	rest_scroll		;残スクロール処理
		bra	look_interrupt_end
@@:
		btst	#2,d5			;ダイレクト処理
		beq	@f

		bsr	during_interrupt_check	;割り込み中処理
		tst.b	(over_interrupt-a5sp,a5)
		bne	look_interrupt_end

		bsr	one_page_print
		bclr	#COM_JUMP,(fg_stat-a5sp,a5)
		bra	look_interrupt_end
@@:
		btst	#3,d5			;ダイレクト表示ライン付き
		beq	l_i_e10

		bsr	during_interrupt_check	;割り込み中チェック
		tst.b	(over_interrupt-a5sp,a5)
		bne	look_interrupt_end

		bsr	set_flag_clr_cursor
		bsr	one_page_print

		move.l	(last_search_line-a5sp,a5),d2
		sub.l	(top_line-a5sp,a5),d2
		move.l	d2,(cursor_line-a5sp,a5)
		st	(search_flag-a5sp,a5)
		move.b	#1,(csr_disp_flag-a5sp,a5)

		move	(win_no_main-a5sp,a5),d0
		moveq	#0,d1
		jsr	(WinSetCursor)
		bsr	call_WinUnderLine

		bclr	#COM_JUMPL,(fg_stat-a5sp,a5)
		bra	look_interrupt_end
l_i_e10:
		tst.b	d5			;キー入力
		bpl	look_interrupt_end

		bsr	look_cursor_bitsns
		btst	#4,d0
		beq	@f
		bsr	look_key_up
		bra	look_interrupt_end
@@:
		btst	#6,d0
		beq	@f
		bsr	look_key_down
		bra	look_interrupt_end
@@:
		btst	#3,d0
		beq	@f
		bsr	look_key_left
		bra	look_interrupt_end
@@:
		btst	#5,d0
		beq	@f
		bsr	look_key_right
		bra	look_interrupt_end
@@:
		bsr	during_interrupt_check
		move.l	(remained_task-a5sp,a5),d0
		beq	@f
		movea.l	d0,a1
		clr.l	(remained_task-a5sp,a5)
		bra	1f
@@:
		bsr	input_keybind
		lea	(bg_job_table,pc),a1	;キー入力別処理
		adda	(a1,d0.w),a1
1:		jsr	(a1)

look_interrupt_end:
		tst	(search_timer-a5sp,a5)
		beq	look_interrupt_end_0	;メッセージ消去タイマー処理
		subq	#1,(search_timer-a5sp,a5)
		bne	look_interrupt_end_0

		bsr	during_interrupt_check
		tst.b	(over_interrupt-a5sp,a5)
		bne	look_interrupt_end_0

		bsr	message_screen_clear

* ここで Meta、Ctrl-x の表示
		move.b	(searched_flag-a5sp,a5),d0	;サーチ文字列表示
		and.b	(search_str_buf-a5sp,a5),d0
		beq	look_interrupt_end_0

		GETMES_A1  MES_L_SCH
		move	(win_no_message-a5sp,a5),d0
		moveq	#2,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		bsr	look_print
		lea	(search_str_buf-a5sp,a5),a1
		tst.b	(kanji_code-a5sp,a5)
		bpl	@f
		lea	(search_str_buf2-a5sp,a5),a1
@@:		bsr	look_print

look_interrupt_end_0:
		tst.b	(load_comp_flag-a5sp,a5)
		bne	look_interrupt_end_1
		btst	#COM_READ,d5		;fg_stat
		bne	look_interrupt_end_1

		bsr	message_screen_clear

		moveq	#MES_VMEME,d0
		tst.b	(not_enough_mem-a5sp,a5)
		bne	@f
		moveq	#MES_VMEMC,d0
		tst.b	(memory_devid-a5sp,a5)
		bne	@f
		moveq	#MES_L_END,d0		;読み込み終了(済み)メッセージ
@@:		bsr	get_message_a1

		move	(win_no_message-a5sp,a5),d0
		moveq	#2,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		bsr	look_print
		move	#120,(search_timer-a5sp,a5)
		st	(load_comp_flag-a5sp,a5)

look_interrupt_end_1:
		ori	#$0700,sr		;割り込み復帰処理
		lea	(int_flag-a5sp,a5),a4
		tst.b	(over_interrupt-a5sp,a5)
		bne	@f			;多重割り込み
		cmpi.b	#$02,(a4)
		bne	@f
		move.b	#$01,(a4)
		bra	l_i_e0
@@:
		clr.b	(a4)
		ori.b	#%11000000,(MFP_IMRA)
		POP	d0-d7/a0-a6
		rte

* 既に割り込み中だったら、最初の割り込み処理が
* 終わった時にもう一度割り込みがかかった時と
* 同じ処理を行う(為のフラグを立てて帰る).

look_interrupt_end_2:
		move.b	#$02,(a4)		;int_flag
		ori.b	#%11000000,(MFP_IMRA)
		POP	d0-d7/a0-a6
		rte


* キー入力ごとの処理アドレス表
bg_job_table:
@@:		.dc	bg_no_input_key-@b	;KEY_NUL
		.dc	one_line_up-@b		;KEY_LINEUP
		.dc	bg_one_line_down-@b	;KEY_LINEDW
		.dc	half_page_up-@b		;KEY_HLFPGUP
		.dc	bg_half_page_down-@b	;KEY_HLFPGDW
		.dc	half_page_roll_up-@b	;KEY_HLFRLUP
		.dc	bg_half_page_rd-@b	;KEY_HLFRLDW
		.dc	bg_one_page_up-@b	;KEY_PAGEUP
		.dc	bg_one_page_down-@b	;KEY_PAGEDW
		.dc	bg_one_page_ru-@b	;KEY_ROLLUP
		.dc	bg_one_page_rd-@b	;KEY_ROLLDW
		.dc	go_home_position-@b	;KEY_GOHOME
		.dc	go_last_position-@b	;KEY_GOLAST
		.dc	bg_goto_line-@b		;KEY_JUMP
		.dc	bg_goto_line1-@b	;KEY_JUMP1
		.dc	bg_goto_line2-@b	;KEY_JUMP2
		.dc	bg_goto_line3-@b	;KEY_JUMP3
		.dc	bg_goto_line4-@b	;KEY_JUMP4
		.dc	bg_goto_line5-@b	;KEY_JUMP5
		.dc	bg_goto_line6-@b	;KEY_JUMP6
		.dc	bg_goto_line7-@b	;KEY_JUMP7
		.dc	bg_goto_line8-@b	;KEY_JUMP8
		.dc	bg_goto_line9-@b	;KEY_JUMP9
		.dc	bg_goto_line$-@b	;KEY_JUMP$
		.dc	forward_search-@b	;KEY_SCHFW
		.dc	next_forward_search-@b	;KEY_SCHFWN
		.dc	back_search-@b		;KEY_SCHBW
		.dc	next_back_search-@b	;KEY_SCHBWN
		.dc	look_i_forward-@b	;KEY_ISCHFW
		.dc	look_i_backward-@b	;KEY_ISCHBW
		.dc	f_search_regexp-@b	;KEY_REGSCH
		.dc	n_search_regexp-@b	;KEY_REGSCHN
		.dc	look_toggle_reg-@b	;KEY_REG
		.dc	bg_toggle_cr_disp-@b	;KEY_CR
		.dc	bg_toggle_tab-@b	;KEY_TAB
		.dc	bg_toggle_tab_size-@b	;KEY_TABSIZE
		.dc	bg_toggle_line_num-@b	;KEY_LINENUM
		.dc	bg_quit_look-@b		;KEY_QUIT
		.dc	bg_edit-@b		;KEY_EDIT
		.dc	toggle_dump_mode-@b	;KEY_DUMP
		.dc	toggle_color_mode-@b	;KEY_COLOR
		.dc	toggle_search-@b	;KEY_CASE
		.dc	bg_meta-@b		;KEY_META
		.dc	bg_ctrl_x-@b		;KEY_CTRLX
		.dc	look_mark_write-@b	;KEY_WRITE
		.dc	look_mark-@b		;KEY_MARK
		.dc	bg_goto_mark-@b		;KEY_GOTOMARK
		.dc	bg_exg_point_mark-@b	;KEY_EXG
		.dc	change_code-@b		;KEY_CODE
		.dc	bg_print_version-@b	;KEY_VERSION


* 残スクロール処理 ---------------------------- *

rest_scroll:
		subq	#1,d1
		move	d1,(ras_req_count-a5sp,a5)
		move	(ras_req_kind-a5sp,a5),d0
		beq	r_s0			;ラスター１ラインダウン
		cmpi	#1,d0
		beq	r_s1			;ラスター１ラインアップ
		cmpi	#2,d0
		beq	r_s4			;ラスター２ラインアップ
		cmpi	#3,d0
		beq	r_s5			;ラスター２ラインダウン
		cmpi	#4,d0
		beq	r_s6			;ラスター４＊Ｎラインダウン
		cmpi	#5,d0
		beq	r_s7			;ラスター４＊Ｎラインアップ
		bra	r_s_end

* ラスター１ラインダウン
r_s0:
		PUSH	d0-d3
		bsr	raster_1_down
		POP	d0-d3
		tst	d1
		bne	r_s_end

		bsr	during_interrupt_check
		move.l	(ras_req_print_line-a5sp,a5),d0
		move.l	(line_num1-a5sp,a5),d1
		bsr	one_line_print
		bra	r_s_end

* ラスター１ラインアップ
r_s1:
		PUSH	d0-d2
		bsr	raster_1_up
		POP	d0-d2
		tst	d1
		bne	r_s_end

		bsr	during_interrupt_check
		move.l	(ras_req_print_line-a5sp,a5),d0
		moveq	#0,d1
		bsr	one_line_print
		bra	r_s_end

* ラスター２ラインアップ
r_s4:
		PUSH	d0-d3
		bsr	raster_2_down
		POP	d0-d3
		tst	d1
		bne	r_s_end

		bsr	during_interrupt_check
		move.l	(ras_req_print_line-a5sp,a5),d0
		move.l	(line_num1-a5sp,a5),d1
		bsr	one_line_print
		bra	r_s_end

* ラスター２ラインダウン
r_s5:
		PUSH	d0-d2
		bsr	raster_2_up
		POP	d0-d2
		tst	d1
		bne	r_s_end

		bsr	during_interrupt_check
		move.l	(ras_req_print_line-a5sp,a5),d0
		moveq	#0,d1
		bsr	one_line_print
		bra	r_s_end

* ラスター４＊Ｎラインダウン
r_s6:
		moveq	#$02,d6
r_s6_1:
		bsr	end_of_file_check
		bls	r_s6_exit

		bsr	raster_4_down
		addq.l	#1,(top_line-a5sp,a5)
		cmpi	#2,d6
		bne	@f
		bsr	during_interrupt_check
@@:
		move.l	d2,d0
		move.l	(line_num1-a5sp,a5),d1
		bsr	one_line_print
		tst.b	(over_interrupt-a5sp,a5)
		bne	r_s_end			;割り込み中なら中止
		tst	d6
		beq	r_s_end
		subq	#1,d6
		move	(ras_req_count-a5sp,a5),d1
		beq	r_s_end
		subq	#1,d1
		move	d1,(ras_req_count-a5sp,a5)
		bra	r_s6_1
r_s6_exit:
		clr	(ras_req_count-a5sp,a5)
		bra	r_s_end

* ラスター４＊Ｎラインアップ
r_s7:
		moveq	#$02,d6
r_s7_1:
		move.l	(top_line-a5sp,a5),d2
		beq	r_s7_3

		bsr	raster_4_up
		subq.l	#1,d2
		move.l	d2,(top_line-a5sp,a5)
		cmpi.l	#2,d6
		bne	@f
		bsr	during_interrupt_check
@@:
		move.l	d2,d0
		moveq	#0,d1
		bsr	one_line_print
		tst.b	(over_interrupt-a5sp,a5)
		bne	r_s_end
		tst	d6
		beq	r_s_end

		subq	#1,d6
		move	(ras_req_count-a5sp,a5),d1
		beq	r_s_end

		subq	#1,d1
		move	d1,(ras_req_count-a5sp,a5)
		bra	r_s7_1
r_s7_3:
		clr	(ras_req_count-a5sp,a5)
r_s_end:
		tst	(ras_req_count-a5sp,a5)
		beq	print_line_number
		rts


end_of_file_check:
		move.l	(total_line-a5sp,a5),d1
		move.l	(top_line-a5sp,a5),d2
		add.l	(line_num2-a5sp,a5),d2
		cmp.l	d2,d1			;ファイルの最後まで表示しているか
		rts


* 割り込み内 → キー処理 ---------------------- *

look_key_right:
		IOCS	_B_SFTSNS
		andi	#%1010,d0		;OPT.2 | CTRL
		bne	l_k_cursor_down

		bsr	set_flag_clr_cursor
		clr.b	(search_flag-a5sp,a5)

		bsr	end_of_file_check	;d2 = 現在行
		bls	l_k_r2

		move.l	(line_num-a5sp,a5),(cursor_line-a5sp,a5)
		move	#2,(viewer_flag-a5sp,a5)
		cmpi	#2,(＄vfst)
		bge	r_s6

		moveq	#$0e,d1
		IOCS	_BITSNS
		lsr.b	#1,d0
		bcs	l_k_r1			;shift + →
		tst	(＄vfst)
		bne	l_k_r1s

		PUSH	d0-d3
		bsr	raster_1_down
		move	(raster4-a5sp,a5),d1	;クリアするラスタ位置
		moveq	#0,d2			;クリアするライン数÷４-1
		bsr	clear_raster
		POP	d0-d3

		move	#3,(ras_req_count-a5sp,a5)
		clr	(ras_req_kind-a5sp,a5)
		move.l	d2,(ras_req_print_line-a5sp,a5)
		addq.l	#1,(top_line-a5sp,a5)
		rts
l_k_r1:
		tst	(＄vfst)		;シフトキーが押されている時
		bne	r_s6
l_k_r1s:
		PUSH	d0-d3
		bsr	raster_2_down
		move	(raster3-a5sp,a5),d1	;クリアするラスタ位置
		moveq	#1,d2			;クリアするライン数÷４
		bsr	clear_raster
		POP	d0-d3

		move	#1,(ras_req_count-a5sp,a5)
		move	#2,(ras_req_kind-a5sp,a5)
		move.l	d2,(ras_req_print_line-a5sp,a5)
		addq.l	#1,(top_line-a5sp,a5)
		rts
l_k_r2:
		move.l	(total_line-a5sp,a5),d0	;'d'と同じルーチン
		subq.l	#2,d0
		move.l	(line_num-a5sp,a5),d1
		cmp.l	d0,d1			;総行数：１画面行数
		bls	@f
		move.l	d0,d1
@@:
		move.l	d1,(cursor_line-a5sp,a5)
		move	#2,(viewer_flag-a5sp,a5)
		rts

l_k_cursor_down:
		tst.b	(search_flag-a5sp,a5)
		bne	@f
		cmpi	#1,(viewer_flag-a5sp,a5)
		beq	cursor_to_top
		cmpi	#2,(viewer_flag-a5sp,a5)
		beq	cursor_to_bottom
@@:
		clr.b	(search_flag-a5sp,a5)
		clr	(viewer_flag-a5sp,a5)

		move.l	(cursor_line-a5sp,a5),d2
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		cmp.l	d0,d2
		beq	@f
		addq.l	#1,d2
		cmp.l	(line_num1-a5sp,a5),d2
		beq	@f
		move.l	d2,(cursor_line-a5sp,a5)
		move.b	#1,(csr_disp_flag-a5sp,a5)

		bsr	draw_cursor_down
		bra	print_line_number
**		rts
@@:
		bsr	set_flag_clr_cursor
		bsr	oneline_down
		move	#2,(viewer_flag-a5sp,a5)
		bra	print_line_number
**		rts


* 割り込み内 ← キー処理 ---------------------- *

look_key_left:
		IOCS	_B_SFTSNS
		andi	#%1010,d0		;OPT.2 | CTRL
		bne	l_k_cursor_up

		bsr	set_flag_clr_cursor
		clr.b	(search_flag-a5sp,a5)
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		move.l	(top_line-a5sp,a5),d2
		beq	l_k_l2
		cmpi	#2,(＄vfst)
		bge	r_s7

		moveq	#$0e,d1
		IOCS	_BITSNS
		lsr.b	#1,d0
		bcs	l_k_l1			;shift + ←
		tst	(＄vfst)
		bne	l_k_l1f

		PUSH	d0-d3
		bsr	raster_1_up
		moveq	#0,d1			;クリアするラスタ位置
		moveq	#0,d2			;クリアするライン数÷４-1
		bsr	clear_raster
		POP	d0-d3

		move	#3,(ras_req_count-a5sp,a5)
		move	#1,(ras_req_kind-a5sp,a5)
		subq.l	#1,d2
		move.l	d2,(ras_req_print_line-a5sp,a5)
		move.l	d2,(top_line-a5sp,a5)
		rts
l_k_l1:
		tst	(＄vfst)
		bne	r_s7
l_k_l1f:
		PUSH	d0-d3
		bsr	raster_2_up
		moveq	#0,d1			;クリアするラスタ位置
		moveq	#1,d2			;クリアするライン数÷４-1
		bsr	clear_raster
		POP	d0-d3

		move	#1,(ras_req_count-a5sp,a5)
		move	#3,(ras_req_kind-a5sp,a5)
		subq.l	#1,d2
		move.l	d2,(ras_req_print_line-a5sp,a5)
		move.l	d2,(top_line-a5sp,a5)
l_k_l2:
		rts

l_k_cursor_up:
		tst.b	(search_flag-a5sp,a5)
		bne	@f
		cmpi	#1,(viewer_flag-a5sp,a5)
		beq	cursor_to_top
		cmpi	#2,(viewer_flag-a5sp,a5)
		beq	cursor_to_bottom
@@:
		clr.b	(search_flag-a5sp,a5)
		clr	(viewer_flag-a5sp,a5)

		move.l	(cursor_line-a5sp,a5),d2
		subq.l	#1,d2
		bmi	@f
		move.l	d2,(cursor_line-a5sp,a5)
		move.b	#1,(csr_disp_flag-a5sp,a5)

		bsr	draw_cursor_up
		bra	print_line_number
**		rts
@@:
		bsr	set_flag_clr_cursor
		bsr	oneline_up
		move	#1,(viewer_flag-a5sp,a5)
		bra	print_line_number
**		rts


* 割り込み内 ↑ キー処理 ---------------------- *

look_key_up:
		move	(＄scrs),d6
l_k_u1:
		IOCS	_B_SFTSNS
		andi	#%1010,d0		;OPT.2 | CTRL
		bne	look_key_up_ctrl

		bsr	set_flag_clr_cursor
		clr.b	(search_flag-a5sp,a5)
		clr.l	(cursor_line-a5sp,a5)
l_k_u2:
		move	#1,(viewer_flag-a5sp,a5)
		move.l	(top_line-a5sp,a5),d2
		beq	l_k_u3

		bsr	raster_4_up
		subq.l	#1,d2
		move.l	d2,(top_line-a5sp,a5)
		cmp	(＄scrs),d6
		bne	@f
		bsr	during_interrupt_check
@@:
		move.l	d2,d0
		moveq	#0,d1
		bsr	one_line_print
		tst.b	(over_interrupt-a5sp,a5)
		dbne	d6,l_k_u1		;割り込み中なら中止
l_k_u3:
		bra	print_line_number
**		rts

look_key_up_ctrl:
		tst.b	(search_flag-a5sp,a5)
		bne	@f
		cmpi	#1,(viewer_flag-a5sp,a5)
		beq	cursor_to_top
		cmpi	#2,(viewer_flag-a5sp,a5)
		beq	cursor_to_bottom
@@:
		clr.b	(search_flag-a5sp,a5)
		clr	(viewer_flag-a5sp,a5)

		move.l	(cursor_line-a5sp,a5),d2
		subq.l	#1,d2
		bmi	@f
		move.l	d2,(cursor_line-a5sp,a5)
		move.b	#1,(csr_disp_flag-a5sp,a5)

		bsr	draw_cursor_up
		bra	print_line_number
**		rts
@@:
		bsr	set_flag_clr_cursor
		bra	l_k_u2


* 割り込み内 ↓ キー処理 ---------------------- *

look_key_down:
		move	(＄scrs),d6
l_k_d1:
		IOCS	_B_SFTSNS
		andi	#%1010,d0		;OPT.2 | CTRL
		bne	look_key_down_ctrl

		bsr	set_flag_clr_cursor
		clr.b	(search_flag-a5sp,a5)
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		move.l	(line_num-a5sp,a5),d1
		cmp.l	d0,d1			;総行数：１画面行数
		bls	@f
		move.l	d0,d1
@@:		move.l	d1,(cursor_line-a5sp,a5)
l_k_d2:
		move	#2,(viewer_flag-a5sp,a5)
		bsr	end_of_file_check
		bls	l_k_d3

		bsr	raster_4_down
		addq.l	#1,(top_line-a5sp,a5)
		cmp	(＄scrs),d6
		bne	@f
		bsr	during_interrupt_check	;割り込み中割り込みチェック
@@:
		move.l	d2,d0
		move.l	(line_num1-a5sp,a5),d1
		bsr	one_line_print
		tst.b	(over_interrupt-a5sp,a5)
		dbne	d6,l_k_d1
l_k_d3:
		bra	print_line_number
**		rts

look_key_down_ctrl:
		tst.b	(search_flag-a5sp,a5)
		bne	@f
		cmpi	#1,(viewer_flag-a5sp,a5)
		beq	cursor_to_top
		cmpi	#2,(viewer_flag-a5sp,a5)
		beq	cursor_to_bottom
@@:
		clr.b	(search_flag-a5sp,a5)
		clr	(viewer_flag-a5sp,a5)

		move.l	(cursor_line-a5sp,a5),d2
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		cmp.l	d0,d2
		beq	@f

		addq.l	#1,d2
		cmp.l	(line_num1-a5sp,a5),d2
		beq	@f

		move.l	d2,(cursor_line-a5sp,a5)
		move.b	#1,(csr_disp_flag-a5sp,a5)
		bsr	draw_cursor_down
		bra	print_line_number
**		rts
@@:
		bsr	set_flag_clr_cursor
		bra	l_k_d2


* 割り込み中割り込みチェック ------------------ *
* break	d0/a0

during_interrupt_check:
		st	(over_interrupt-a5sp,a5)
		movea.l	(int_sr_ptr-a5sp,a5),a0
		moveq	#$07,d0
		and.b	(a0),d0
		bne	@f

		moveq	#$18,d0
		and.b	(MFP_IERA),d0
		cmpi.b	#$18,d0
		bne	@f
		moveq	#$18,d0
		and.b	(MFP_IMRA),d0
		cmpi.b	#$18,d0
		bne	@f

		clr.b	(over_interrupt-a5sp,a5)
		andi	#$f8ff,sr
@@:
		rts


* カーソル制御 -------------------------------- *

cursor_to_top:
		clr.l	(cursor_line-a5sp,a5)
cursor_to_bottom:
		clr	(viewer_flag-a5sp,a5)
		bsr	draw_cursor
		bra	print_line_number
**		rts

draw_cursor:
		move.l	(cursor_line-a5sp,a5),d2
		bra	@f
draw_cursor_down:
		bsr	@f
		sub	#1,d2
		bra	@f
draw_cursor_up:
		bsr	@f
		addq	#1,d2
@@:
		move	(win_no_main-a5sp,a5),d0
		moveq	#2,d1
		jsr	(WinSetCursor)
		move.b	#1,(csr_disp_flag-a5sp,a5)
call_WinUnderLine:
		move	(＄cbcl),d1
		jmp	(WinUnderLine)
**		rts


set_flag_clr_cursor:
		clr.b	(search_flag-a5sp,a5)
		tst.b	(csr_disp_flag-a5sp,a5)
		beq	@f
		bsr	draw_cursor
		clr.b	(csr_disp_flag-a5sp,a5)
@@:		rts


* [BG] １ページ後進(スムース) ----------------- *
bg_one_page_down:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)

		IOCS	_B_SFTSNS
		btst	#1,d0			;CTRL
		bne	go_home_position
		tst.b	(over_interrupt-a5sp,a5)
		bne	o_p_d3

		move.l	(top_line-a5sp,a5),d2
		sub.l	(line_num1-a5sp,a5),d2
		bpl	@f
		moveq	#0,d2
@@:
		cmp.l	(top_line-a5sp,a5),d2
		beq	o_p_d2
		move.l	d2,(top_line-a5sp,a5)
		bra	one_page_print
o_p_d3:
		pea	(bg_one_page_down,pc)
		move.l	(sp)+,(remained_task-a5sp,a5)
o_p_d2:
		rts


* [BG] １ページ前進(スムース) ----------------- *
bg_one_page_up:
		bsr	set_flag_clr_cursor
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		move.l	(line_num-a5sp,a5),d1
		cmp.l	d0,d1			;総行数：28
		bls	@f
		move.l	d0,d1
@@:
		move.l	d1,(cursor_line-a5sp,a5)
		move	#2,(viewer_flag-a5sp,a5)

		IOCS	_B_SFTSNS
		btst	#1,d0			;CTRL
		bne	go_last_position
		tst.b	(over_interrupt-a5sp,a5)
		bne	o_p_u3

		move.l	(top_line-a5sp,a5),d2
		add.l	(line_num1-a5sp,a5),d2
		move.l	d2,d1
		add.l	(line_num2-a5sp,a5),d1
		cmp.l	(total_line-a5sp,a5),d1
		bcs	@f

		move.l	(total_line-a5sp,a5),d2
		sub.l	(line_num2-a5sp,a5),d2
		bpl	@f
		moveq	#0,d2
@@:
		cmp.l	(top_line-a5sp,a5),d2
		beq	o_p_u2

		move.l	d2,(top_line-a5sp,a5)
		bra	one_page_print
o_p_u3:
		pea	(bg_one_page_up,pc)
		move.l	(sp)+,(remained_task-a5sp,a5)
o_p_u2:
		rts


* [BG] 半ページ後進 --------------------------- *
bg_half_page_down:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		tst.b	(over_interrupt-a5sp,a5)
		beq	@f

		pea	(bg_half_page_down,pc)
		move.l	(sp)+,(remained_task-a5sp,a5)
half_page_down_end:
		rts
@@:
		moveq	#-15,d2
		add.l	(top_line-a5sp,a5),d2
		bpl	@f
		moveq	#0,d2
@@:
		cmp.l	(top_line-a5sp,a5),d2
		beq	half_page_down_end

		move.l	d2,(top_line-a5sp,a5)
		bra	one_page_print


* [BG] 半ページ前進 --------------------------- *
half_page_up:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		tst.b	(over_interrupt-a5sp,a5)
		beq	@f

		pea	(half_page_up,pc)
		move.l	(sp)+,(remained_task-a5sp,a5)
half_page_up_end:
		rts
@@:
		moveq	#15,d2
		add.l	(top_line-a5sp,a5),d2
		move.l	d2,d1
		add.l	(line_num2-a5sp,a5),d1
		cmp.l	(total_line-a5sp,a5),d1
		bcs	@f

		move.l	(total_line-a5sp,a5),d2
		sub.l	(line_num2-a5sp,a5),d2
		bpl	@f
		moveq	#0,d2
@@:
		cmp.l	(top_line-a5sp,a5),d2
		beq	half_page_up_end

		move.l	d2,(top_line-a5sp,a5)
		bra	one_page_print


* [BG] １ページ後進 --------------------------- *
bg_one_page_rd:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		move.l	(line_num1-a5sp,a5),d1
		move	#5,(ras_req_kind-a5sp,a5)
		bra	rest_scroll
**		rts

* [BG] １ページ前進 --------------------------- *
bg_one_page_ru:
		bsr	set_flag_clr_cursor
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		move.l	(line_num-a5sp,a5),d1
		cmp.l	d0,d1			;総行数：１画面行数
		bls	@f
		move.l	d0,d1
@@:
		move.l	d1,(cursor_line-a5sp,a5)
		move	#2,(viewer_flag-a5sp,a5)
		move.l	(line_num1-a5sp,a5),d1
		move	#4,(ras_req_kind-a5sp,a5)
		bra	rest_scroll
**		rts


* [BG] 半ページ後進(スムース) ----------------- *
bg_half_page_rd:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)
		moveq	#14,d1
		move	#5,(ras_req_kind-a5sp,a5)
		bra	rest_scroll
**		rts


* [BG] 半ページ前進(スムース) ----------------- *
half_page_roll_up:
		bsr	set_flag_clr_cursor
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		move.l	(line_num-a5sp,a5),d1
		cmp.l	d0,d1			;総行数：１画面行数
		bls	@f
		move.l	d0,d1
@@:
		move.l	d1,(cursor_line-a5sp,a5)
		move	#2,(viewer_flag-a5sp,a5)
		moveq	#14,d1
		move	#4,(ras_req_kind-a5sp,a5)
		bra	rest_scroll
**		rts


* [BG] 一行後進 ------------------------------- *
bg_one_line_down:
		bsr	set_flag_clr_cursor
		move.l	(line_num-a5sp,a5),(cursor_line-a5sp,a5)
oneline_down:
		move	#2,(viewer_flag-a5sp,a5)
		moveq	#1,d1
		move	d1,(ras_req_count-a5sp,a5)
		move	#4,(ras_req_kind-a5sp,a5)
		rts


* [BG] 一行前進 ------------------------------- *
one_line_up:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
oneline_up:
		move	#1,(viewer_flag-a5sp,a5)
		moveq	#1,d1
		move	d1,(ras_req_count-a5sp,a5)
		move	#5,(ras_req_kind-a5sp,a5)
		rts


* [BG] ファイル先頭に移動 --------------------- *
go_home_position:
		bsr	set_flag_clr_cursor
		clr.l	(cursor_line-a5sp,a5)
		move	#1,(viewer_flag-a5sp,a5)

		tst.b	(over_interrupt-a5sp,a5)
		bne	g_h_p2
		tst.l	(top_line-a5sp,a5)
		beq	@f
		clr.l	(top_line-a5sp,a5)
		bsr	one_page_print
@@:
		move.l	(top_line-a5sp,a5),d1
		subq.l	#1,d1
		move.l	d1,(last_search_line-a5sp,a5)
		rts
g_h_p2:
		pea	(go_home_position,pc)
		move.l	(sp)+,(remained_task-a5sp,a5)
		rts


* [BG] ファイル末尾に移動 --------------------- *
go_last_position:
		bsr	set_flag_clr_cursor
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		bcc	@f
		moveq	#0,d0
@@:
		move.l	(line_num-a5sp,a5),d1
		cmp.l	d0,d1			;総行数：１画面行数
		bls	@f
		move.l	d0,d1
@@:
		move.l	d1,(cursor_line-a5sp,a5)
		move	#2,(viewer_flag-a5sp,a5)
		tst.b	(over_interrupt-a5sp,a5)
		bne	g_l_p3

		move.l	(total_line-a5sp,a5),d0
		sub.l	(line_num2-a5sp,a5),d0
		bpl	@f
		moveq	#0,d0
@@:
		cmp.l	(top_line-a5sp,a5),d0
		beq	@f
		move.l	d0,(top_line-a5sp,a5)
		bsr	one_page_print
@@:
		move.l	(top_line-a5sp,a5),d1	;サーチラインは最後に
		add.l	(line_num1-a5sp,a5),d1
		move.l	(total_line-a5sp,a5),d0
		subq.l	#2,d0
		cmp.l	d0,d1
		bls	@f
		move.l	d0,d1
@@:
		addq.l	#1,d1
		move.l	d1,(last_search_line-a5sp,a5)
		rts
g_l_p3:
		pea	(go_last_position,pc)
		move.l	(sp)+,(remained_task-a5sp,a5)
		rts

* [BG] 終了 ----------------------------------- *
bg_quit_look:
		move.b	#REQ_QUIT,(bg_stat-a5sp,a5)
		rts


* [BG] エディタ起動 --------------------------- *
bg_edit:
		st	(v_exec_flag-a5sp,a5)
		rts


* [BG] バージョン表示起動 --------------------- *
bg_print_version:
		move.b	#REQ_VERSION,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts


* [BG] 行番号指定カーソル移動 ----------------- *
bg_goto_line:	moveq	#0,d0
		bra	@f
bg_goto_line1:	moveq	#'1',d0
		bra	@f
bg_goto_line2:	moveq	#'2',d0
		bra	@f
bg_goto_line3:	moveq	#'3',d0
		bra	@f
bg_goto_line4:	moveq	#'4',d0
		bra	@f
bg_goto_line5:	moveq	#'5',d0
		bra	@f
bg_goto_line6:	moveq	#'6',d0
		bra	@f
bg_goto_line7:	moveq	#'7',d0
		bra	@f
bg_goto_line8:	moveq	#'8',d0
		bra	@f
bg_goto_line9:	moveq	#'9',d0
		bra	@f
bg_goto_line$:	moveq	#'$',d0
@@:
		move.b	d0,(jump_first_num-a5sp,a5)
		move.b	#REQ_JUMP,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts


* [BG] マーク関係 ----------------------------- *
look_mark:
		move.b	#REQ_MARK,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
bg_goto_mark:
		move.b	#REQ_GOMARK,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
bg_exg_point_mark:
		move.b	#REQ_EXG,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts


* [BG] ファイル書き出し ----------------------- *
look_mark_write:
		move.b	#REQ_WRITE,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts


* [BG] 検索関係 ------------------------------- *
forward_search:
		move.b	#REQ_SCHFW,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
next_forward_search:
		move.b	#REQ_SCHFWN,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
back_search:
		move.b	#REQ_SCHBW,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
next_back_search:
		move.b	#REQ_SCHBWN,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
look_i_forward:
		move.b	#REQ_ISCHFW,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
look_i_backward:
		move.b	#REQ_ISCHBW,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
f_search_regexp:
		move.b	#REQ_REGSCH,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
n_search_regexp:
		move.b	#REQ_REGSCHN,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts


* [BG] メタキー ------------------------------- *
bg_meta:
		tst	(＄esc！)
		beq	bg_quit_look
		move	#PREFIX_META,(prefix-a5sp,a5)
		rts


* [BG] CTRL+X --------------------------------- *
bg_ctrl_x:
		move	#PREFIX_CTRLX,(prefix-a5sp,a5)
		rts


* [BG] 動作モード変更関係 --------------------- *
change_code:
		move.b	#REQ_CODE,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
toggle_dump_mode:
		move.b	#REQ_DUMP,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
toggle_color_mode:
		move.b	#REQ_COLOR,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
toggle_search:
		move.b	#REQ_CASE,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
look_toggle_reg:
		move.b	#REQ_REG,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
bg_toggle_cr_disp:
		move.b	#REQ_CR,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
bg_toggle_tab:
		move.b	#REQ_TAB,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
bg_toggle_tab_size:
		move.b	#REQ_TABSIZE,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts
bg_toggle_line_num:
		move.b	#REQ_NUM,(bg_stat-a5sp,a5)
		bset	#COM_REQ,(fg_stat-a5sp,a5)
		rts


* １ページ表示 -------------------------------- *

one_page_print:
		move.l	(total_line-a5sp,a5),d2
		move.l	(top_line-a5sp,a5),d0
		subq.l	#1,d2
		move.l	(line_num1-a5sp,a5),d1
		cmp.l	d1,d2
		bls	@f
		move.l	d1,d2
@@:
		moveq	#0,d1			;表示位置
@@:
		PUSH	d0-d3
		add	d1,d1
		add	d1,d1
		moveq	#16/4-1,d2		;クリアするライン数
		bsr	clear_raster
		POP	d0-d3

		bsr	one_line_print
		addq.l	#1,d0			;ラインナンバー
		addq	#1,d1			;表示位置
		dbra	d2,@b

		bra	print_line_number
**		rts


* １行表示 ------------------------------------ *
* in	d0.l	行番号
*	d1.l	表示位置
* break	a0-a1

one_line_print:
		PUSH	d0-d4
		move.l	d0,d3
		move.l	d1,d4
		cmpi	#1,(look_mode-a5sp,a5)
		bcs	o_view
		beq	o_dump
*o_cdmp:
		btst	#COM_READ,(fg_stat-a5sp,a5)
		bne	@f			;読み込み中は EOF 表示なし
		addq.l	#1,d3
		cmp.l	(total_line-a5sp,a5),d3
		beq	o_l_p_eof
		subq.l	#1,d3
@@:
		lea	(cdmp_width,pc),a1
		tst	(＄dnum)
		bra	1f
o_dump:
		btst	#COM_READ,(fg_stat-a5sp,a5)
		bne	@f
		addq.l	#1,d3
		cmp.l	(total_line-a5sp,a5),d3
		beq	o_l_p_eof
		subq.l	#1,d3
@@:
		lea	(dump_width,pc),a1
		tst	(＄dnum)
1:		beq	o_l_p10

		lea	(-12,sp),sp
		bsr	mulu32x16_d0		;行数×ダンプ幅
		lea	(sp),a1
		bsr	hex_to_str
		clr.b	(a1)
		lea	(8-5,sp),a1		;5 桁
		bra	o_l_p_lnum
o_view:
		lsl.l	#3,d0			;論理行変換
		neg.l	d0
		movea.l	(line_buf_last-a5sp,a5),a0
**		GETLINENUM  (-8,a0,d0.l),d0
		move.l	(-8,a0,d0.l),d0
		bmi	o_l_p_eof

		tst	(＄lnum)
		beq	o_l_p10

		lea	(-12,sp),sp
		andi.l	#$00ffffff,d0
		addq.l	#1,d0
		moveq	#5,d1			;5 桁
		lea	(sp),a0
		FPACK	__IUSING
		lea	(sp),a1
o_l_p_lnum:
		move	(win_no_lnum-a5sp,a5),d0
		moveq	#0,d1
		move	d4,d2
		jsr	(WinSetCursor)

		move.l	(mark_line_phy-a5sp,a5),d2
		beq	@f			;マークなし
		subq.l	#1,d2
		cmp.l	d2,d3
		bne	@f			;マーク行ではない

		bsr	get_lnum_or_dnum
		move	d1,-(sp)
		bchg	#WCOL_REV,d1		;マーク行の行数は反転表示
		jsr	(WinSetColor)
		bsr	look_print
		move	(sp)+,d1
		jsr	(WinSetColor)
		bra	1f
@@:
		bsr	look_print
1:
		lea	(font_bar,pc),a1
		move	(＄vbar),d2
		bsr	draw_half

		lea	(12,sp),sp
o_l_p10:
		move	(win_no_main-a5sp,a5),d0
		moveq	#0,d1
		move	d4,d2
		jsr	(WinSetCursor)

		cmpi	#1,(look_mode-a5sp,a5)
		bcs	3f
		beq	1f
		lea	(cdmp_width,pc),a1	;行数×ダンプ幅
		bra	2f
1:		lea	(dump_width,pc),a1	;行数×ダンプ幅
2:		bsr	mulu32x16_d3
		movea.l	(file_buf-a5sp,a5),a2	;ファイル先頭アドレス
		lea	(a2,d3.l),a1		;表示行テキスト先頭
		movea.l	(line_buf_last-a5sp,a5),a2
		bra	c_l_p11
3:
		lsl.l	#3,d3			;ラインナンバー(破壊禁止)
		neg.l	d3
		movea.l	(line_buf_last-a5sp,a5),a2
		GETBUFPTR  (-4,a2,d3.l),a1	;表示行テキスト先頭
		tst.b	(look_color_flag-a5sp,a5)
		beq	c_l_p11

**		GETCOLOR  (-4,a2,d3.l),d1
		GETCOLOR  (-8,a2,d3.l),d1
		jsr	(WinSetColor)
c_l_p11:
		PUSH	d0/a3
		jsr	(WinGetPtr)
		movea.l	d0,a4
		tst.b	(WIND_MB_FLAG,a4)
		bne	@f

		move.b	(WIND_MB_HIGH,a4),d1	;多分いらない
		st	(WIND_MB_FLAG,a4)
		addq.l	#1,a1
@@:
		POP	d0/a3
		tst	(look_mode-a5sp,a5)
		beq	@f

		bsr	look_dump
		bra	c_l_p30
@@:
		st	(o_l_p_flag-a5sp,a5)
		bsr	look_print
		clr.b	(o_l_p_flag-a5sp,a5)

		tst	(＄vret)
		beq	c_l_p30

		subq.l	#8,d3			;次の行から一歩前に
		GETBUFPTR  (-4,a2,d3.l),a1	;行って CRLF があるか見る
		move.b	-(a1),d1
		cmpi.b	#LF,d1
		beq	@f
		cmpi.b	#CR,d1
		bne	c_l_p30
@@:
		lea	(font_cr,pc),a1		;改行マーク表示
		moveq	#YELLOW,d2
		bsr	draw_half
c_l_p30:
		POP	d0-d4
		rts

o_l_p_eof:
		move	(win_no_main-a5sp,a5),d0
		moveq	#0,d1
		move	d4,d2
		jsr	(WinSetCursor)

		tst	(＄veof)
		beq	veof_end

		move	d0,-(sp)
		moveq	#MES_L_EOF,d0
		tst.b	(out_of_mem_flag-a5sp,a5)
		beq	@f
		st	($24,a4)
		moveq	#MES_L_OOM,d0		;メモリ分断
@@:
		bsr	get_message_a1
		move	(sp)+,d0
		moveq	#BLUE,d1
		jsr	(WinSetColor)
		bsr	look_print
		moveq	#WHITE,d1
		jsr	(WinSetColor)
veof_end:
		POP	d0-d4
		rts


draw_half:
		PUSH	d0-d5/a0-a4
		movea.l	a1,a2
		jsr	(WinGetPtr)
		movea.l	d0,a4

		lsl	#4,d2
		andi	#$00f0,d2
		ori	#$0103,d2
		move	d2,(CRTC_R21)

		move	(WIND_CUR_X,a4),d3
		move	(WIND_XSIZE,a4),d4
		movea.l	(WIND_CUR_ADR,a4),a1
		cmp	d3,d4
		bhi	@f

		suba.l	d3,a1			;改行する
		moveq	#0,d3
		addq	#1,(WIND_CUR_Y,a4)
		lea	($800,a1),a1
@@:
		jsr	(win_draw_half)
		addq.l	#1,d3
		move.l	a1,(WIND_CUR_ADR,a4)
		move	d3,(WIND_CUR_X,a4)
		move	#$0033,(CRTC_R21)
		POP	d0-d5/a0-a4
		rts


* [BG] キー入力なし --------------------------- *
bg_no_input_key:
		move.l	(total_line-a5sp,a5),d0
		cmp.l	(now_total_line-a5sp,a5),d0
		bne	print_line_number
		rts


* 現在行番号表示 ------------------------------ *

print_line_number:
		lea	(-16,sp),sp
		move.l	(cursor_line-a5sp,a5),d0
		add.l	(top_line-a5sp,a5),d0
		tst	(look_mode-a5sp,a5)
		bne	@f

		lsl.l	#3,d0
		neg.l	d0
		movea.l	(line_buf_last-a5sp,a5),a0
		GETLINENUM  (-8,a0,d0.l),d0
@@:
		addq.l	#1,d0			;論理行
		moveq	#6,d1			;6 桁
		lea	(sp),a0
		FPACK	__IUSING
		move.b	#'/',(a0)+

		move.l	(total_line-a5sp,a5),d0	;最大ラインナンバー
		tst	(look_mode-a5sp,a5)
		bne	@f
		subq.l	#1,d0
		cmp.l	(now_total_line-a5sp,a5),d0
		beq	@f

		subq.l	#1,d0
		lsl.l	#3,d0
		neg.l	d0
		movea.l	(line_buf_last-a5sp,a5),a1
		GETLINENUM  (-8,a1,d0.l),d0	;現在最大論理行
		addq.l	#1,d0
@@:		move.l	d0,(now_total_line-a5sp,a5)

**		moveq	#6,d1			;6 桁
		FPACK	__IUSING

		move	(win_no_info-a5sp,a5),d0
		moveq	#81,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		lea	(sp),a1
		bsr	look_print

		lea	(16,sp),sp
		rts


* ラスタコピー -------------------------------- *
* in	d0.w	次ラスタへの差分
*	d1.w	転送元 | 転送先
*	d2.w	コピーラスター数-1
* 備考:
*	スーパバイザモード、割り込み禁止状態で
*	呼び出すこと.

txrascpy:
.ifdef USE_IOCS				
		addq	#1,d2
		moveq	#$03,d3
		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		moveq	#$0f,d3
@@:
		tst	d0
		bpl	@f
		ori	#$ff00,d3
@@:
		move.l	a0,-(sp)		;IOCS _TXRASCPY
		movea.l	($400+_TXRASCPY*4),a0
		jsr	(a0)
		movea.l	(sp)+,a0
		rts
.else
		PUSH	a0-a3
		lea	(MFP_GPIP),a0
		lea	(CRTC_R22-MFP_GPIP,a0),a1
		lea	(CRTC_ACT-MFP_GPIP,a0),a2
		lea	(CRTC_R21-MFP_GPIP,a0),a3
		move	(a3),-(sp)
		moveq	#$08,d3			;ラスターコピー開始命令
*		move	sr,d7
*		move	d7,d6
*		ori	#$0700,d6		;割り込み禁止データ
*		andi	#$f5ff,d7		;割り込み許可データ
		move	#$103,(a3)		;ラスタコピープレーン設定
*		subq	#1,d2
*		bmi	rascpy_exit
rascpy_up_first:				;最初の一本をコピー
*		move	d6,sr			;DI
		move	d1,(a1)			;コピー先・コピー元設定
@@:		tst.b	(a0)			;  ┌────┐↓  ┌
		bpl	@b			;─┘        └──┘
		move	d3,(a2)			;ラスタコピー開始
		add	d0,d1
		subq	#1,d2
		bmi	rascpy_up_end
rascpy_up_lp:
@@:		tst.b	(a0)			;↑┌────┐    ┌
		bmi	@b			;─┘        └──┘
@@:		tst.b	(a0)			;  ┌────┐↓  ┌
		bpl	@b			;─┘ rascpy └──┘
		move	d1,(a1)
		add	d0,d1
		dbra	d2,rascpy_up_lp
rascpy_up_end:
@@:		tst.b	(a0)			;↑┌────┐    ┌
		bmi	@b			;─┘        └──┘
@@:		tst.b	(a0)			;  ┌────┐↓  ┌
		bpl	@b			;─┘ rascpy └──┘
		clr	(a2)			;ラスタコピー停止
		move	(sp)+,(a3)
		POP	a0-a3
		rts
.endif


* テンポラリ用ラスタのクリア ------------------ *

clear_temp_raster:
		TO_SUPER
		move	(CRTC_R21),-(sp)
		move	#$1f0,(CRTC_R21)
		lea	(TVRAM_P0+38*16*$80),a0	;38[行目]×16[dot1行]×$80[1行byte数]
		move	#($80*36/4)-1,d0
@@:
		clr.l	(a0)+
		dbra	d0,@b
		move	(sp)+,(CRTC_R21)
		TO_USER
		rts


* ラスタコピーによる各種処理 ------------------ *

message_screen_clear:
		PUSH	d0-d3
		move	(raster5-a5sp,a5),d1
		moveq	#16/4-1,d2		;クリアするライン数
		bsr	clear_raster
		POP	d0-d3
		rts

* 画面クリア
* in	d1.b	クリアするラスタ位置
*	d2.w = クリアするライン数÷４-1
clear_raster:
		ori	#$9800,d1
		moveq	#$0001,d0
		bra	txrascpy
**		rts

raster_1_down:
		move	#$0100,d1
		move	(raster3-a5sp,a5),d2
		moveq	#$03,d3
		move	#$0101,d0
		bra	txrascpy
**		rts

raster_2_down:
		move	#$0200,d1
		move	(raster2-a5sp,a5),d2
		moveq	#$03,d3
		move	#$0101,d0
		bra	txrascpy
**		rts

raster_4_down:
		PUSH	d0-d3
		move	#$0400,d1
		move	(raster0-a5sp,a5),d2
		moveq	#$03,d3
		move	#$0101,d0
		bsr	txrascpy
		move	(raster1-a5sp,a5),d1	;クリアするラスタ位置
		moveq	#3,d2			;クリアするライン数÷４
		bsr	clear_raster
		POP	d0-d3
		rts

raster_1_up:
		moveq	#0,d0
		move	(raster4-a5sp,a5),d1
		moveq	#1,d2
		bra	tx_scroll_down_smooth
**		rts

raster_2_up:
		moveq	#0,d0
		move	(raster4-a5sp,a5),d1
		moveq	#2,d2
		bra	tx_scroll_down_smooth
*		rts

raster_4_up:
		PUSH	d0-d3
		moveq	#0,d0
		move	(raster4-a5sp,a5),d1
		moveq	#4,d2
		bsr	tx_scroll_down_smooth
		moveq	#0,d1			;クリアするラスタ位置
		moveq	#$03,d2			;クリアするライン数÷４-1
		bsr	clear_raster
		POP	d0-d3
		rts


* 下方向スムーススクロール -------------------- *
* in	d0	先頭ラスタセット番号
*	d1	最終ラスタセット番号
*	d2	スクロールラスタ数
* 備考:
*	スクロール領域を２分割することによって
*	画面の乱れを抑制している.

ESC_D1:		.equ	-4*1			;中央ラスタブロック待避
RESTORE_D1:	.equ	-4*2			;中央ラスタブロック復帰
UPR_REG_D1:	.equ	-4*3			;上位領域転送
UPR_REG_D2:	.equ	-4*4			;(〃)ラスタ数
LOW_REG_D1:	.equ	-4*5			;下位領域転送
LOW_REG_D2:	.equ	-4*6			;(〃)ラスタ数

tx_scroll_down_smooth:
		link	a6,#-32
		PUSH	d3-d5

		move	d0,d5
		add	d1,d5
		asr	#1,d5			;upr_btm_ras
		move	d5,d3
		sub	d0,d3			;upr_rasnum
		sub	d2,d3
		addq	#1,d3
		move	d3,(UPR_REG_D2,a6)

		move	d5,d3
		sub	d2,d3
		move	d5,d4
		asl	#8,d3
		or	d3,d4
		move	d4,(UPR_REG_D1,a6)

		move	d5,d3
		asl	#8,d3
		ori	#39*4+4,d3
		move	d3,(ESC_D1,a6)

		move	d5,d4
		add	d2,d4
		move	#(39*4+4)*256,d3
		or	d4,d3
		move	d3,(RESTORE_D1,a6)

		addq	#1,d5			;lwr_top_ras
		move	d1,d3
		sub	d5,d3
		move	d3,(LOW_REG_D2,a6)

		move	d1,d3
		sub	d2,d3
		asl	#8,d3
		or	d1,d3
		move	d3,(LOW_REG_D1,a6)

		move	d2,d5
		move	#$ff03,d3		;コピープレーン

		move	(ESC_D1,a6),d1		;中央ラスタ退避
		move	d5,d2
		move	#-$0101,d0
		bsr	txrascpy
		move	(UPR_REG_D1,a6),d1	;上位領域転送
		move	(UPR_REG_D2,a6),d2
		bsr	txrascpy
		move	(LOW_REG_D1,a6),d1	;下位領域転送
		move	(LOW_REG_D2,a6),d2
		bsr	txrascpy
		move	(RESTORE_D1,a6),d1	;中央ラスタ復帰
		move	d5,d2
		bsr	txrascpy

		POP	d3-d5
		unlk	a6
		rts


* ダンプ時一行表示 ---------------------------- *
* in	d0.w	ウィンドウ番号
*	a1.l	ダンプ表示テキスト
* out	d1.w	表示後の桁位置

* レジスタ使用状況
*	a0.l	ダンプ表示テキスト
*	a1.l	書き込みテキストアドレス(a1 以外不可)
*	a2.l	汎用
*	a3.l	win_print_char
*	a4.l	ウィンドウ管理構造体(a4 以外不可)

look_dump:
		PUSH	d0/d2-d3/d5/a0/a2-a4
		movea.l	a1,a0
		jsr	(WinGetPtr)
		movea.l	d0,a4

		moveq	#$f,d0
		and	(WIND_COLOR,a4),d0
		lsl	#4,d0
		or	#$0103,d0
		move	d0,(CRTC_R21)

		move	(WIND_CUR_X,a4),d3
		move	(WIND_XSIZE,a4),d4
		movea.l	(WIND_CUR_ADR,a4),a1	;書き込みテキストアドレス(破壊禁止)

		move	(dump_width_lp,pc),d2	;ループカウンタ(ダンプ幅)
		move	(dump_size,pc),d5

		lea	(win_print_char),a3	;破壊禁止

		cmpi	#1,(look_mode-a5sp,a5)
		beq	l_d_d_loop		;DUMP

		moveq	#0,d5			;CDMP
		move	(cdmp_width,pc),d7
		subq	#1,d7
		bsr	look_dump_char
l_d_end:
		move.l	a1,(WIND_CUR_ADR,a4)
		move	d3,(WIND_CUR_X,a4)
		move	#$0033,(CRTC_R21)
		move	d5,d1
		POP	d0/d2-d3/d5/a0/a2-a4
		rts

hex2asc_tbl:
		.dc.b	'0123456789ABCDEF'
		.even

l_d_d_bufover:
		addq.l	#1,a0
		moveq	#SPACE,d1
		jsr	(a3)
		jsr	(a3)
		bra	1f
l_d_d_loop:
		cmpa.l	(file_read_end-a5sp,a5),a0
		bcc	l_d_d_bufover

		moveq	#0,d1
		move.b	(a0),d1
		lsr.b	#4,d1			;上位４ビット
		move.b	(hex2asc_tbl,pc,d1.w),d1
		jsr	(a3)

		moveq	#$0f,d1
		and.b	(a0)+,d1		;下位４ビット
		move.b	(hex2asc_tbl,pc,d1.w),d1
		jsr	(a3)
1:
		subq	#1,d5
		bne	@f

		moveq	#SPACE,d1
		jsr	(a3)
		move	(dump_size,pc),d5
@@:
		dbra	d2,l_d_d_loop

		moveq	#0,d5
		move	(dump_code_x,pc),d5	;現在桁位置増分

		moveq	#SPACE,d1
		jsr	(a3)
		moveq	#SPACE,d1
		jsr	(a3)

		move	(dump_width,pc),d1
		neg	d1
		lea	(a0,d1.w),a0
		move	(dump_width_lp,pc),d7
		bsr	look_dump_char
		bra	l_d_end


* 文字のダンプ表示
* in	d7.w	ダンプ幅-1
*	a0.l	表示するテキスト
look_dump_char:
		exg	a0,a1
		bsr	is_mbtrail_a1
		exg	a0,a1
		bcc	@f

		move.l	a1,-(sp)
		move.b	(-1,a0),d1		;途切れ漢字を表示(上位バイト)
		jsr	(a3)
		move.b	(a0)+,d1		;下位バイト
		jsr	(a3)
		movea.l	(sp)+,a1

		bsr	draw_text_mesh		;左半分に網目を入れる
		addq.l	#2,a1
		clr.b	(prev_mb_flag-a5sp,a5)
		move	d7,d2
		subq	#1,d2
		bra	l_d_c_loop
@@:
		bsr	draw_text_mesh		;左端に網目を入れる
		addq.l	#1,a1
		move	d7,d2
l_d_c_loop:
		moveq	#SPACE,d1
		cmpa.l	(file_read_end-a5sp,a5),a0
		bcc	@f

		moveq	#0,d1
		move.b	(a0)+,d1
		tst.b	(prev_mb_flag-a5sp,a5)
		bne	l_d_c_mb

		lea	(ctypetable),a2
		tst.b	(a2,d1.w)		;前が漢字上位コードでない
		smi	(prev_mb_flag-a5sp,a5)
		bmi	@f			;漢字上位

		cmpi.b	#$20,d1
		bcc	@f
		tst	(＄vccp)
		beq	1f
		cmpi.b	#TAB,d1
		beq	1f
		cmpi.b	#LF,d1
		beq	1f
		cmpi.b	#CR,d1
		bne	@f
1:
		moveq	#'.',d1
@@:
		move.l	d2,-(sp)
		jsr	(a3)
		move.l	(sp)+,d2
		dbra	d2,l_d_c_loop
		bra	l_d_c_end
l_d_c_mb:
		clr.b	(prev_mb_flag-a5sp,a5)	;前が漢字上位コード
		move.l	d2,-(sp)
		move.l	a1,-(sp)
		jsr	(a3)
		movea.l	(sp)+,a1
		addq.l	#2,a1
		move.l	(sp)+,d2
		dbra	d2,l_d_c_loop
l_d_c_end:
		tst.b	(prev_mb_flag-a5sp,a5)
		beq	@f

		clr.b	(prev_mb_flag-a5sp,a5)
		cmpa.l	(file_read_end-a5sp,a5),a0
		bcc	@f

		move.b	(a0)+,d1		;片割れ表示エリアに片割れ表示
		move.l	a1,-(sp)
		jsr	(a3)
		movea.l	(sp)+,a1
		addq.l	#1,a1
@@:
		add	d7,d5
		addq	#2+2+1,d5		;現在桁位置増分(spc*2,half*2+dumpwidth+1)
		bra	draw_text_mesh
**		rts


* 網目模様を上書きする.
draw_text_mesh:
		moveq	#%01010101,d0
	.irp	line,1,5,9,13
		or.b	d0,(line*128,a1)
	.endm
		moveq	#%00101010,d0
	.irp	line,3,7,11,15
		or.b	d0,(line*128,a1)
	.endm
		rts


* サブルーチン -------------------------------- *

* (a1).b が二バイト文字の下位バイトでないか調べる
* in	a1.l	文字列
* out	ccr	C=1:下位バイト C=0:違う
is_mbtrail_a1:
		PUSH	d1-d2/a0-a1
		lea	(ctypetable),a0
		moveq	#0,d1
		moveq	#-1,d2
@@:
		addq	#1,d2
		move.b	-(a1),d1
		tst.b	(a0,d1.w)
		bmi	@b

		lsr	#1,d2
		POP	d1-d2/a0-a1
		rts


* 数値を 16 進数文字列に変換する.
* in	d0.l	数値
*	a1.l	バッファ
* out	a1.l	+= 8
* break	d0.l

hex_to_str:
		PUSH	d1-d2/a2
		lea	(hex2asc_tbl,pc),a2
		moveq	#8-1,d2
@@:
		rol.l	#4,d0
		moveq	#$f,d1
		and.b	d0,d1
		move.b	(a2,d1.w),(a1)+
		dbra	d2,@b
		POP	d1-d2/a2
		rts


* 乗除算ルーチン ------------------------------ *

* d0.l×d1.l → d0.l
.if 0
mulu32:
		PUSH	d1-d3
		cmp.l	d1,d0
		bcc	@f			;d1.l≦d0.l
		exg	d0,d1
@@:
		swap	d0
		move	d0,d2
		beq	mulu32_ww		;d1.l≦d0.l≦65535

		swap	d0
		swap	d1
		tst	d1
		beq	mulu32_lw		;d1.l≦65535≦d0.l

		move	d0,d3			;32bit×32bit
		mulu	d1,d3
		swap	d1
		mulu	d1,d0
		mulu	d1,d2

		swap	d0
		add	d2,d0
		add	d3,d0
		swap	d0
		POP	d1-d3
		rts
mulu32_ww:
		swap	d0			;16bit×16bit
		mulu	d1,d0
		POP	d1-d3
		rts
mulu32_lw:
		swap	d1			;32bit×16bit
		mulu	d1,d0
		mulu	d1,d2
		swap	d0
		add	d2,d0
		swap	d0
		POP	d1-d3
		rts
.endif

* d0.l÷d1.l → d0.l … d1.l
divu32:
		tst.l	d1
		beq	divu32_error

		PUSH	d2-d3
		moveq	#0,d2
		moveq	#32-1,d3
divu32_loop:
		add.l	d0,d0
		addx.l	d2,d2
		cmp.l	d1,d2
		bcs	@f
		addq.b	#1,d0
		sub.l	d1,d2
@@:
		dbra	d3,divu32_loop
		move.l	d2,d1			;余り
		POP	d2-d3
divu32_error:
		rts


* d0.l×(a1).w → d0.l
mulu32x16_d0:
		move.l	d2,-(sp)
		move.l	d0,d2
		swap	d2
		mulu	(a1),d0
		mulu	(a1),d2
		swap	d0
		add	d2,d0
		swap	d0
		move.l	(sp)+,d2
		rts

* d1.l×(a1).w → d1.l
mulu32x16_d1:
		exg	d1,d0
		bsr	mulu32x16_d0
		exg	d1,d0
		rts

* d3.l×(a1).w → d3.l
mulu32x16_d3:
		exg	d3,d0
		bsr	mulu32x16_d0
		exg	d3,d0
		rts


* 文字列表示下請け ---------------------------- *
* in	a1.l	文字列

look_print:
		PUSH	d0/d2-d6/a0/a2-a4
		movea.l	a1,a0
		jsr	(WinGetPtr)
		movea.l	d0,a4

		moveq	#$f,d0
		and	(WIND_COLOR,a4),d0
		lsl	#4,d0
		or	#$0103,d0
		move	d0,(CRTC_R21)

		move	(WIND_CUR_X,a4),d3
		move	(WIND_XSIZE,a4),d4
		movea.l	(WIND_CUR_ADR,a4),a1

		moveq	#0,d5
		moveq	#0,d6
		move.b	(search_str_buf-a5sp,a5),d6
		tst.b	(search_exact-a5sp,a5)
		bne	l_p_loop

		lea	(ctypetable),a3
		btst.b	#IS_UPPER,(a3,d6.w)
		beq	l_p_loop
		ori.b	#$20,d6
l_p_loop:
		cmp	d4,d3
		bcc	l_p_end

		moveq	#0,d1
		cmp.b	(kanji_code-a5sp,a5),d1
		bge	l_p_sjis		;0(sjis),-1(euc)

l_p_jis:
		move.b	(a0)+,d1
		cmpi.b	#ESC,d1
		bne	l_p_jis_not_esc
		cmpi.b	#'$',(a0)
		beq	1f
		cmpi.b	#'&',(a0)
		bne	@f
1:
		addq.l	#2,a0
		clr.b	(jis_mb_not-a5sp,a5)	;ESC,[$&],[B@] = 二バイト文字
		st	(ksi-a5sp,a5)
		bra	l_p_jis
@@:
		cmpi.b	#'(',(a0)
		bne	@f
		addq.l	#1,a0
		cmpi.b	#'I',(a0)+
		beq	l_p_jis_so		;ESC,(,I = かな

*		st	(jis_mb_not-a5sp,a5)	;ESC,(,[JB] = 一バイト文字
*		bra	l_p_jis
		bra	l_p_jis_si
@@:
		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		bsr	esc_analyze_and_set_color
		bra	l_p_jis
@@:
		tst.b	(esc_flag-a5sp,a5)	;ESC 削除
		bne	l_p_char1

		bsr	esc_skip		;ESC 無視
		bra	l_p_jis
l_p_jis_not_esc:
		cmpi.b	#SO,d1
		bne	@f
l_p_jis_so:
		clr.b	(ksi-a5sp,a5)		;Shift Out
		bra	l_p_jis
@@:
		cmpi.b	#SI,d1
		bne	l_p_char1
l_p_jis_si:
		st	(ksi-a5sp,a5)		;Shift In
		st	(jis_mb_not-a5sp,a5)
		bra	l_p_jis

l_p_sjis:
		move.b	(a0)+,d1
		cmpi.b	#ESC,d1
		bne	l_p_sjis_not_esc
		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		bsr	esc_analyze_and_set_color
		bra	l_p_sjis
@@:
		tst.b	(esc_flag-a5sp,a5)
		bne	l_p_sjis_not_ctrl
		bsr	esc_skip
		bra	l_p_sjis
l_p_sjis_not_esc:
		cmpi.b	#BS,d1
		bne	l_p_sjis_not_ctrl
		tst.b	(bs_flag-a5sp,a5)
		bne	l_p_sjis_not_ctrl
.if 1
		tst	d3
		beq	l_p_loop
.endif
		subq.l	#1,a1			;テキストアドレス-1
		subq	#1,d3			;文字数カウンタ-1
		cmpi.b	#BS,(a0)
		bne	bs_not_zen

		subq.l	#1,a1			;'Ａ'+BS+[BS]+'Ａ'
		subq	#1,d3
		addq.l	#1,a0
		move.b	(-3,a0),d1
		cmpi.b	#'_',d1			;_[_]+BS+BS+'Ａ'
		bne	bs_not_zunder
		cmpi.b	#'_',(-4,a0)		;[_]_+BS+BS+'Ａ'
		bne	bs_not_zunder
		cmpi.b	#'_',(a0)		;'__'+BS+BS+[_]_+BS+BS+'Ａ'
		bne	@f
		cmpi.b	#'_',(1,a0)		;'__'+BS+BS+_[_]+BS+BS+'Ａ'
		bne	l_p_loop

		addq.l	#4,a0			;下線＋点滅(未実装)
		ori	#1<<WCOL_UL,(WIND_COLOR,a4)
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
@@:
		cmpi.b	#BS,(2,a0)		;'__'+BS+BS+'Ａ'+[BS]+BS+'Ａ'
		bne	bs_zunder
		cmpi.b	#BS,(3,a0)		;'__'+BS+BS+'Ａ'+BS+[BS]+'Ａ'
		bne	l_p_loop

		addq.l	#4,a0			;下線＋強調
		ori	#1<<WCOL_UL+1<<WCOL_EM,(WIND_COLOR,a4)
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
bs_zunder:
		ori	#1<<WCOL_UL,(a4)	;下線
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
bs_not_zunder:
		cmp.b	(1,a0),d1		;[Ａ]+BS+BS+[Ａ]
		bne	l_p_loop
		move.b	(-4,a0),d1
		cmp.b	(a0),d1			;[Ａ]+BS+BS+[Ａ]
		bne	l_p_loop
		cmpi.b	#BS,(2,a0)		;'Ａ'+BS+BS+'Ａ'+[BS]+BS+'Ａ'
		bne	@f
		cmpi.b	#BS,(3,a0)
		bne	l_p_loop

		addq.l	#4,a0			;強調反転
		ori	#1<<WCOL_REV+1<<WCOL_EM,(a4)
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
@@:
		ori	#1<<WCOL_EM,(a4)	;強調
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
bs_not_zen:
		move.b	(-2,a0),d1
		cmpi.b	#'_',d1			;[_]+BS+'A'
		bne	bs_not_under

		cmpi.b	#'_',(a0)		;'_'+BS+[_]+BS+'A'
		bne	@f
		cmpi.b	#BS,(1,a0)		;'_'+BS+'_'[BS]'A'
		bne	bs_under

		addq.l	#2,a0			;下線＋点滅(未実装)
		ori	#1<<WCOL_UL,(a4)
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
@@:
		cmpi.b	#BS,(1,a0)		;'_'+BS+'A'[BS]'A'
		bne	bs_under

		addq.l	#2,a0			;下線＋強調
		ori	#1<<WCOL_UL+1<<WCOL_EM,(a4)
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
bs_under:
		ori	#1<<WCOL_UL,(a4)	;下線
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
bs_not_under:
		cmp.b	(a0),d1			;[A]+BS+[A]
		bne	l_p_loop
		cmpi.b	#BS,(1,a0)
		beq	@f

		ori	#1<<WCOL_EM,(a4)	;強調
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop
@@:
		addq.l	#2,a0			;強調反転
		ori	#1<<WCOL_REV+1<<WCOL_EM,(a4) 
		st	(bs_extend_flag-a5sp,a5)
		bra	l_p_loop

l_p_sjis_not_ctrl:
		tst.b	(look_yar_flag-a5sp,a5)
		beq	l_p_char1
		cmpi.b	#$81,d1
		beq	l_p_81xx
		cmpi.b	#$82,d1
		bne	l_p_char

		move.b	(a0),d1
		cmpi.b	#.low.'０',d1
		bcs	l_p_82xx_cancel		;'０' 未満
		cmpi.b	#.low.'ａ',d1
		bcs	@f			;'ａ' 未満
		cmpi.b	#.low.'ｚ',d1
		bhi	l_p_82xx_cancel		;'ｚ' より大きい

		addi.b	#'a'-.low.'ａ',d1	;小文字を一バイト文字に変換する
		addq.l	#1,a0			
		bra	l_p_char
@@:
		addi.b	#'0'-.low.'０',d1	;数字、大文字を一バイト文字に変換する
		addq.l	#1,a0
		bra	l_p_char
l_p_82xx_cancel:
		move.b	#$82,d1
		bra	l_p_char
l_p_81xx:
		move.b	(a0),d1
		cmpi.b	#$98,d1
		bcc	@f			;0x8198 以上
		subi.b	#$40,d1
		bcs	@f			;0x8140 未満
		move.b	(yar_table-a5sp,a5,d1.w),d1
		beq	@f			;代替文字が未定義
		addq.l	#1,a0
		bra	l_p_char
@@:
		move.b	#$81,d1
l_p_char:
		move	d1,d0
		jsr	(is_mb)
		beq	l_p_char1

		tst.b	(o_l_p_flag-a5sp,a5)
		beq	@f
		tst.b	(kanji_code-a5sp,a5)
		bpl	@f
		bsr	print_euc
		bra	1f
@@:
		jsr	(win_print_char)
1:
		addq.l	#1,d5
		moveq	#0,d1
		move.b	(a0)+,d1

		tst.b	(bs_extend_flag-a5sp,a5)
		beq	l_p_char1
		clr.b	(bs_extend_flag-a5sp,a5)
		andi	#.not.WCOL_MASK,(WIND_COLOR,a4)
l_p_char1:
		tst.l	d1
		bne	@f
		tst.b	(o_l_p_flag-a5sp,a5)	;one_line_print 以外から
		beq	l_p_end			;呼ばれた場合は終わり
		moveq	#SPACE,d1		;VIEW 時は $00 は空白へ変換
		bra	l_p_cha1_2
@@:
		cmpi.b	#$20,d1
		bcc	l_p_cha1_2
		cmpi.b	#CR,d1
		bne	@f
		cmpi.b	#LF,(a0)
		bne	l_p_end			;CR 改行

		addq.l	#1,a0			;CR/LF は LF を飛ばして終わり
		bra	l_p_end
@@:
		cmpi.b	#LF,d1
		beq	l_p_end			;LF 改行
		cmpi.b	#TAB,d1
		bne	@f

		tst	(＄tabc)
		beq	l_p_tabc0
		bsr	draw_tab		;可視タブ描画
		bra	l_p_loop
l_p_tabc0:
		jsr	(win_tab)		;桁位置移動のみ
		add	d1,d5
		bra	l_p_loop
@@:
		tst	(＄vcct)
		beq	l_p_cha1_2		;そのまま表示

		move	(CRTC_R21),-(sp)	;^X の形式で表示
		move	#$0123,(CRTC_R21)
		move	d1,d0
		moveq	#'^',d1
		jsr	(win_print_char)
		moveq	#$40,d1			;'@'
		add.b	d0,d1
		jsr	(win_print_char)
		move	(sp)+,(CRTC_R21)
		bra	l_p_loop
l_p_cha1_2:
		tst.b	(o_l_p_flag-a5sp,a5)
		beq	1f			;one_line_print 以外からの呼び出し

		tst.b	(WIND_MB_FLAG,a4)
		beq	2f
		move	d1,d0
		tst.b	(search_exact-a5sp,a5)
		bne	@f
		lea	(ctypetable),a2
		btst	#IS_UPPER,(a2,d0.w)
		beq	@f
		ori.b	#$20,d0
@@:		cmp.b	d0,d6
		bne	2f
		bsr	search_emphasis
		bra	@f
2:
		tst.b	(kanji_code-a5sp,a5)
		beq	1f			;S-JIS
		bpl	2f			;JIS
		bsr	print_euc		;EUC
		bra	@f
2:
		bsr	print_jis
		bra	@f
1:
		jsr	(win_print_char)
@@:
		tst.b	(WIND_MB_FLAG,a4)
		beq	@f
		tst.b	(bs_extend_flag-a5sp,a5)
		beq	@f
		clr.b	(bs_extend_flag-a5sp,a5)
		andi	#.not.WCOL_MASK,(WIND_COLOR,a4)
@@:
		addq.l	#1,d5
		bra	l_p_loop
l_p_end:
		move.l	a1,(WIND_CUR_ADR,a4)
		move	d3,(WIND_CUR_X,a4)
		move	#$0033,(CRTC_R21)
		movea.l	a0,a1
		move	d5,d1
		POP	d0/d2-d6/a0/a2-a4
		rts


* タブ描画
draw_tab:
		PUSH	d1-d2/d4/a3
		lea	(CRTC_R21),a3
		move	(a3),d2
		move	#$0113,(a3)

		lea	(font_tab_arrow,pc),a2
		jsr	(win_draw_half)

		move	d3,d1
		and	(WIND_TABCNEG,a4),d3
		add	(WIND_TABC,a4),d3
		move	d3,d4
		sub	d1,d4
		add	d4,d5
		subq	#2,d4
		bmi	draw_tab_skip
@@:
		lea	(font_tab_dot,pc),a2
		jsr	(win_draw_half)
		dbra	d4,@b
draw_tab_skip:
		move	d2,(a3)
		POP	d1-d2/d4/a3
		rts


* ESC シーケンス解析
* in	a0.l	ESC の次のアドレス
esc_analyze_and_set_color:
		PUSH	d0/d3/a1
		move	(win_no_main-a5sp,a5),d0
		jsr	(WinGetPtr)
		movea.l	d0,a1
		move	(WIND_COLOR,a1),d3
		bsr	esc_analyze
		move	d3,(WIND_COLOR,a1)
		andi	#$f,d3
		lsl	#4,d3
		or	#$0103,d3
		move	d3,(CRTC_R21)
		POP	d0/d3/a1
		rts

* in	a0.l	ESC の次のアドレス
*	d3.w	現在の表示属性
* out	a0.l	ESC シーケンスを飛ばしたアドレス
*	d3.w	解釈後の表示属性
esc_color_init:
		moveq	#WHITE,d3
		rts
esc_analyze:
		move.b	(a0)+,d0
		cmpi.b	#'[',d0
		bne	esc_analyze_not_col
		move.b	(a0)+,d0
		beq	ea_end
		cmpi.b	#'m',d0
		beq	esc_color_init		;^[[m

		subq.l	#1,a0
		move.l	a0,-(sp)
@@:
		move.b	(a0)+,d0
		cmpi.b	#'0',d0
		bcs	@f
		cmpi.b	#'9',d0
		bls	@b			;0～9 以外を探す
@@:
		cmpi.b	#'C',d0
		bne	@f
		addq.l	#4,sp			;^[[<n>C
		bra	ea_ret
@@:
		movea.l	(sp)+,a0		;それ以外は多分 ^[[<n>m
esc_next:
		move.b	(a0)+,d0
		cmpi.b	#'0',d0			;^[[0…
		bne	@f
		moveq	#WHITE,d3
		bra	esc_chain
@@:
		cmpi.b	#'7',d0			;^[[7…
		bne	@f
		ori.b	#1<<WCOL_REV,d3
		bra	esc_chain
@@:
		cmpi.b	#'8',d0			;^[[8…
		bne	@f
**		moveq	#WCOL_BLACK,d3
		move	(＄vsec),d3
		bra	esc_chain
@@:
		cmpi.b	#'4',d0			;^[[4x…
		bne	@f
		cmpi.b	#'0',(a0)
		bcs	1f
		cmpi.b	#'9',(a0)
		bhi	1f

		andi.b	#WCOL_MASK,d3
		ori.b	#1<<WCOL_REV,d3
		bra	esc_col_scan
1:
		ori.b	#1<<WCOL_UL,d3
		bra	esc_chain
@@:
		cmpi.b	#'1',d0			;^[[1x…
		bne	@f
		cmpi.b	#'0',(a0)
		bcs	1f
		cmpi.b	#'9',(a0)
		bhi	1f

		moveq	#BLACK,d3
		bra	esc_col_scan1
1:
		ori.b	#1<<WCOL_EM,d3
		bra	esc_chain
@@:
		cmpi.b	#'2',d0			;^[[2x…
		bne	@f
		cmpi.b	#'0',(a0)
		bcs	1f
		cmpi.b	#'9',(a0)
		bhi	1f

		moveq	#BLACK,d3
		bra	esc_col_scan2
1:
**		ori.b	#1<<WCOL_EM,d3
		bra	esc_chain
@@:
		cmpi.b	#'5',d0			;^[[5…
		bne	@f
**		ori.b	#1<<0,d3		;未実装
		bra	esc_chain
@@:
		cmpi.b	#'3',d0			;^[[3x…
		bne	ea_end

		andi.b	#WCOL_MASK,d3
esc_col_scan:
		move.b	(a0)+,d0
		cmpi.b	#'0',d0
		beq	esc_black
		cmpi.b	#'1',d0
		beq	esc_red
		cmpi.b	#'2',d0
		beq	esc_green
		cmpi.b	#'3',d0
		beq	esc_yellow
		cmpi.b	#'4',d0
		beq	esc_blue
		cmpi.b	#'5',d0
		beq	esc_purple
		cmpi.b	#'6',d0
		beq	esc_lightblue
		cmpi.b	#'7',d0
		beq	esc_white

		cmpi.b	#'8',d0			;&look-file 独自 ESC
		beq	esc_x68_ext1
		cmpi.b	#'9',d0
		beq	esc_x68_ext2
esc_col_err:
		move.b	(a0)+,d0
		cmpi.b	#'0',d0
		bcs	@f
		cmpi.b	#'9',d0
		bls	esc_col_err
@@:
		subq.l	#1,a0
esc_chain:
		move.b	(a0)+,d0
		beq	ea_end
		cmpi.b	#'m',d0
		beq	ea_ret
		cmpi.b	#';',d0
		beq	esc_next
ea_end:
		subq.l	#1,a0
ea_ret:
		rts

esc_analyze_not_col:
		cmpi.b	#'$',d0
		beq	@f
		cmpi.b	#'&',d0
		beq	@f
		cmpi.b	#'(',d0
		beq	@f
		subq.l	#1,a0
		rts
@@:
		addq.l	#1,a0			;ESC,[$&],[B@] = 二バイト文字
		rts

esc_col_scan2:
		move.b	(a0)+,d0
		cmpi.b	#'0',d0
		beq	esc_green
		cmpi.b	#'1',d0
		beq	esc_yellow
		cmpi.b	#'2',d0
		beq	esc_lightblue
		cmpi.b	#'3',d0
		beq	esc_white
		bra	esc_col_err
esc_col_scan1:
		move.b	(a0)+,d0
		cmpi.b	#'6',d0
		beq	esc_secret
		cmpi.b	#'7',d0
		beq	esc_red
		cmpi.b	#'8',d0
		beq	esc_blue
		cmpi.b	#'9',d0
		beq	esc_purple
		bra	esc_col_err
esc_secret:
**		ori.b	#WCOL_BLACK,d3
		move	(＄vsec),d3
		bra	esc_chain
esc_black:	ori.b	#WCOL_BLACK,d3
		bra	esc_chain
esc_red:	ori.b	#WCOL_RED,d3
		bra	esc_chain
esc_green:	ori.b	#WCOL_GREEN,d3
		bra	esc_chain
esc_yellow:	ori.b	#WCOL_YELLOW,d3
		bra	esc_chain
esc_blue:	ori.b	#WCOL_BLUE,d3
		bra	esc_chain
esc_purple:	ori.b	#WCOL_PURPLE,d3
		bra	esc_chain
esc_lightblue:	ori.b	#WCOL_LBLUE,d3
		bra	esc_chain
esc_white:	ori.b	#WHITE,d3
		bra	esc_chain
esc_x68_ext1:	ori.b	#BLUE,d3		;&look-file 独自 ESC
		bra	esc_chain
esc_x68_ext2:	ori.b	#YELLOW,d3
		bra	esc_chain
esc_skip:
		move.b	(a0)+,d1
		beq	se_end
		cmpi.b	#'[',d1
		bne	se_end
		move.b	(a0)+,d1
		beq	se_end
		cmpi.b	#'m',d1
		beq	se_ret
esc_skip_num:
		move.b	(a0)+,d1
		beq	se_end
		cmpi.b	#'0',d1
		bcs	@f
		cmpi.b	#'9',d1
		bls	esc_skip_num
@@:
		cmpi.b	#'C',d1
		beq	se_ret
		cmpi.b	#';',d1
		beq	esc_skip_num
		cmpi.b	#'m',d1
		beq	se_ret
se_end:
		subq.l	#1,a0
se_ret:
		rts


* 検索文字列の強調表示 ------------------------ *

search_emphasis:
		PUSH	d0/d6/a2-a3/a5
		move.l	a5,-(sp)
		movea.l	a0,a2
		lea	(search_str_buf-a5sp+1,a5),a3
		tst.b	(search_exact-a5sp,a5)
		beq	search_emp_ignore_case
@@:
		cmpm.b	(a2)+,(a3)+
		beq	@b
search_emp_loop:
		tst.b	-(a3)
		bne	search_emp_normal

		movea.l	(sp)+,a5

		move	(CRTC_R21),-(sp)
		move	(WIND_COLOR,a4),-(sp)
		move	(＄vssc),d6
		move	d6,(WIND_COLOR,a4)
		andi	#$000f,d6
		lsl	#4,d6
		or	#$0103,d6
		move	d6,(CRTC_R21)

		move	(bm_patlen_r),d6
		bsr	search_emp_sub
		subq	#1,d6
		bmi	search_emp_end
@@:
		move.b	(a0)+,d1
		bsr	search_emp_sub
		subq	#1,d6
		bpl	@b
search_emp_end:
		move	(sp)+,(WIND_COLOR,a4)
		move	(sp)+,(CRTC_R21)
		POP	d0/d6/a2-a3/a5
		rts

search_emp_ignore_case:
		moveq	#0,d0
		lea	(ctypetable),a5
		tst.b	(a5,d1.w)
		bpl	search_emp_i_loop
		cmpm.b	(a2)+,(a3)+		;二バイト文字の下位バイトを比較
		bne	search_emp_loop
search_emp_i_loop:
		move.b	(a2)+,d0
		move.b	(a3)+,d6
		tst.b	(a5,d1.w)
		bpl	@f
		cmp.b	d0,d6
		bne	search_emp_loop
		cmpm.b	(a2)+,(a3)+
		bne	search_emp_loop
		bra	search_emp_i_loop
@@:
		btst	#IS_UPPER,(a5,d0.w)
		beq	@f
		ori.b	#$20,d0
@@:		btst	#IS_UPPER,(a5,d6.w)
		beq	@f
		ori.b	#$20,d6
@@:		cmp.b	d0,d6
		bne	search_emp_loop
		bra	search_emp_i_loop
search_emp_normal:
		movea.l	(sp)+,a5
		bsr	search_emp_sub
		POP	d0/d6/a2-a3/a5
		rts

search_emp_sub:
		tst.b	(kanji_code-a5sp,a5)
		bmi	@f
		bne	print_jis
		jmp	(win_print_char)
@@:
		move.l	a0,-(sp)
		bsr	print_euc
		move.l	a0,d0
		sub.l	(sp)+,d0
		sub	d0,d6
		rts


* JIS コード文字表示 -------------------------- *

print_jis:
		cmpi.b	#$20,d1
		bcs	p_j_ctrl
		beq	@f			;SPACE
		tst.b	(ksi-a5sp,a5)
		bne	1f
		tas	d1			;ori.b #$80,d1
		bra	@f
1:
		tst.b	(jis_mb_not-a5sp,a5)
		beq	p_j_mb			;二バイト文字
@@:
		jsr	(win_draw_char)
		addq.l	#1,d3
		rts
p_j_mb:
		move.l	d0,-(sp)
		move	d4,d0
		subq	#1,d0
		cmp	d3,d0
		bls	p_j_no_width		;全角表示幅が残っていない

		move.b	(a0)+,d0
		cmpi.b	#EOF,d0
		beq	p_j_end

		move.b	d1,-(sp)
		move	(sp)+,d1
		move.b	d0,d1
		IOCS	_JISSFT
		moveq	#0,d1
		move	d0,d1
		move.l	(sp)+,d0

		jmp	(win_draw_mb_char)
**		rts


* EUC コード文字表示 -------------------------- *

print_euc:
		tst.b	d1
		bmi	p_e_mb
		cmpi.b	#$20,d1
		bcc	euc_hankaku
p_j_ctrl:
		move	(CRTC_R21),-(sp)
		move	#$0123,(CRTC_R21)
		jsr	(win_draw_char)
		move	(sp)+,(CRTC_R21)

		st	(WIND_MB_FLAG,a4)
		addq.l	#1,d3
		rts
p_e_mb:
		cmpi.b	#$8e,d1
		beq	p_e_kana

		move.l	d0,-(sp)
		move	d4,d0
		subq	#1,d0
		cmp	d3,d0
		bhi	@f
p_j_no_width:
		addq.l	#1,d3			;全角表示幅が残っていない
		clr.b	(WIND_MB_FLAG,a4)
p_j_end:
p_e_end:	move.l	(sp)+,d0
		rts
@@:
		move.b	(a0)+,d0
		cmpi.b	#EOF,d0
		beq	p_e_end

		move.b	d1,-(sp)
		move	(sp)+,d1
		move.b	d0,d1
		andi	#$7f7f,d1
		IOCS	_JISSFT
		moveq	#0,d1
		move	d0,d1
		move.l	(sp)+,d0

		jmp	(win_draw_mb_char)
**		rts

p_e_kana:
		move.b	(a0)+,d1
		st	(WIND_MB_FLAG,a4)
euc_hankaku:
		jsr	(win_draw_char)
		addq.l	#1,d3
		rts


* S-JIS 文字列を EUC に変換する --------------- *
* in	a0.l	文字列

sjis2euc:
		PUSH	d0-d1/a0-a2
		lea	(-128,sp),sp
		lea	(a0),a1
		lea	(sp),a2
		moveq	#128-2,d0
@@:
		move.b	(a1)+,(a2)+		;変換結果を上書きする為
		dbeq	d0,@b			;元の文字列を一時バッファに転送する
		clr.b	(a2)

		lea	(sp),a1
		bra	sjis2euc_start
sjis2euc_loop:
		move.b	d0,(a0)+
sjis2euc_start:
		move.b	(a1)+,d0
		bgt	sjis2euc_loop		;$01～$7f
		beq	sjis2euc_end
		cmpi.b	#$a1,d0			;｡
		bcs	sjis2euc_mb
		cmpi.b	#$df,d0			;ﾟ
		bhi	sjis2euc_mb

		move.b	#$8e,(a0)+		;半角片仮名
		bra	sjis2euc_loop
sjis2euc_mb:
		move.b	d0,-(sp)
		move	(sp)+,d1
		move.b	(a1)+,d1
		IOCS	_SFTJIS
		ori	#$8080,d1
		move	d1,-(sp)
		move.b	(sp)+,(a0)+
		move.b	d1,(a0)+
		bra	sjis2euc_start
sjis2euc_end:
		move.b	d0,(a0)
		lea	(128,sp),sp
		POP	d0-d1/a0-a2
		rts


* 割り込み設定/解除 --------------------------- *

lookfile_set_interrupt:
		bsr	set_vdisp_int
		bsr	set_keyinp_int
		bra	hook_iocs_skeyset
*		rts

lookfile_restore_interrupt::
		move.l	a5,-(sp)
		lea	(a5sp),a5
		bsr	restore_iocs_skeyset
		bsr	restore_keyinp_int
		bsr	restore_vdisp_int
		bsr	condrv_kon
		movea.l	(sp)+,a5
		rts


* V-DISP 割り込み設定
set_vdisp_int:
		PUSH	a0-a1
		TO_SUPER

		move.l	(VDISP_VEC*4),(vdisp_vec_save-a5sp,a5)
		lea	(look_interpt_entry,pc),a0
		move.l	a0,(VDISP_VEC*4)

		lea	(MFP_IERB),a0
		lea	(MFP_IMRB-MFP_IERB,a0),a1
		move.b	(a0),(mfp_ierb_save-a5sp,a5)
		move.b	(a1),(mfp_imrb_save-a5sp,a5)
		moveq	#$40,d0
		or.b	d0,(a0)
		or.b	d0,(a1)

		TO_USER
		POP	a0-a1
		rts

* V-DISP 割り込み解除
restore_vdisp_int:
		PUSH	d1/a0-a1
		TO_SUPER
		move.l	(vdisp_vec_save-a5sp,a5),d1
		beq	restore_vdisp_int_skip

		lea	(MFP_IERB),a0
		lea	(MFP_IMRB-MFP_IERB,a0),a1
		moveq	#6,d0
		btst	d0,(mfp_ierb_save-a5sp,a5)
		bne	@f
		bclr	d0,(a0)
@@:		btst	d0,(mfp_imrb_save-a5sp,a5)
		bne	@f
		bclr	d0,(a1)
@@:
		move.l	d1,(VDISP_VEC*4)
		clr.l	(vdisp_vec_save-a5sp,a5)
restore_vdisp_int_skip:
		TO_USER
		POP	d1/a0-a1
		rts


* MFP キー入力割り込み設定
set_keyinp_int:
		bsr	init_keyflags
		pea	(key_interrupt_entrance,pc)
		move	#KEYINP_VEC,-(sp)
		DOS	_INTVCS
		move.l	d0,(keyinp_vec_save-a5sp,a5)
		addq.l	#6,sp
		rts

* MFP キー入力割り込み解除
restore_keyinp_int:
		move.l	(keyinp_vec_save-a5sp,a5),d0
		beq	@f
		move.l	d0,-(sp)
		move	#KEYINP_VEC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		clr.l	(keyinp_vec_save-a5sp,a5)
@@:		rts


* IOCS _SKEYSET フック設定
hook_iocs_skeyset:
		pea	(iocs_skeyset_hook,pc)
		move	#$100+_SKEYSET,-(sp)
		DOS	_INTVCS
		move.l	d0,(skey_vec_save-a5sp,a5)
		addq.l	#6,sp
		rts

* IOCS _SKEYSET フック解除
restore_iocs_skeyset:
		move.l	(skey_vec_save-a5sp,a5),d0
		beq	@f
		move.l	d0,-(sp)
		move	#$100+_SKEYSET,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		clr.l	(skey_vec_save-a5sp,a5)
@@:		rts


* キー入力関係 -------------------------------- *

* キーシリアル入力割り込み処理
key_interrupt_entrance:
		move.b	(MFP_UDR),(keycode)
		move.l	(keyinp_vec_save),-(sp)
		rts

* IOCS _SKEYSET フック処理
iocs_skeyset_hook:
		move.b	d1,(keycode)
		move.l	(skey_vec_save),-(sp)
		rts


* 割り込みで保存したキーを取り出す.
input_keybind:
		move.b	(keycode-a5sp,a5),d0
		beq	input_keybind_noinp
		cmpi.b	#KB_TBL_SIZE,d0
		bcc	input_keybind_noinp

		move.l	a0,-(sp)
		move	(prefix-a5sp,a5),d0
		bne	@f
		btst	d0,($80e)		;SHIFT は prefix なしの時のみ有効
		beq	@f
		moveq	#-1,d0
		bra	1f
@@:
		move.b	($80e),-(sp)
		andi.b	#%1010,(sp)+		;OPT.2 | CTRL
		beq	1f
		addq	#1,d0
1:
		mulu	#KB_TBL_SIZE,d0
		lea	(keybind_normal,pc),a0
		adda	d0,a0			;prefix/ctrl/shift 別のバインド表

		moveq	#0,d0
		move.b	(keycode-a5sp,a5),d0
		move.b	(a0,d0.w),d0		;割り当てられた機能番号

		movea.l	(sp)+,a0
init_keyflags:
		clr.b	(keycode-a5sp,a5)
		clr	(prefix-a5sp,a5)
		rts
input_keybind_noinp:
		clr.b	(keycode-a5sp,a5)
		moveq	#0,d0
		rts

* カーソルキー入力
look_cursor_bitsns:
		PUSH	d1-d2
		moveq	#$0e,d1
		IOCS	_BITSNS
		andi.b	#%1010,d0		;CTRL/OPT.2 が押されていなければ無視
		beq	look_cursor_bitsns_normal

		IOCS	_ONTIME
		move.l	d0,d2

		moveq	#$07,d1
		IOCS	_BITSNS
		moveq	#%0111_1000,d1
		and.b	d0,d1
		cmp.b	(last_csr_key-a5sp,a5),d1
		bne	@f			;カーソルキー状態が変わった

		cmp.l	(csr_rept_wait-a5sp,a5),d2
		bcc	look_cursor_bitsns_end	;キーリピート中
		moveq	#0,d0
		bra	look_cursor_bitsns_end
@@:
		move.b	d1,(last_csr_key-a5sp,a5)
		moveq	#20,d1			;200ms 後にリピート開始
		add.l	d1,d2
		move.l	d2,(csr_rept_wait-a5sp,a5)
		bra	look_cursor_bitsns_end
look_cursor_bitsns_normal:
		moveq	#$07,d1
		IOCS	_BITSNS
look_cursor_bitsns_end:
		POP	d1-d2
		rts


* condrv(em).sys のバッファが開かないようにしてから
* キーバッファを消去する.
iocs_key_flush_cond_kill::
		PUSH	d0-d1/a1
		bsr	get_condrv_keyflag
		beq	@f			;condrv(em).sys あり

		bsr	iocs_key_flush		;condrv(em).sys なし
		bra	9f
@@:
		IOCS	_B_BPEEK
		move.b	d0,-(sp)		;save
		moveq	#-1,d1			;koff
		subq.l	#1,a1
		IOCS	_B_BPOKE
		bsr	iocs_key_flush
		move.b	(sp)+,d1		;restore
		subq.l	#1,a1
		IOCS	_B_BPOKE
9:
		POP	d0-d1/a1
		rts

iocs_key_flush_loop:
		IOCS	_B_KEYINP
iocs_key_flush::
		IOCS	_B_KEYSNS
		tst.l	d0
		bne	iocs_key_flush_loop
		rts

* キーバッファを消去してから一文字入力
iocs_b_keyinp:
		bsr	iocs_key_flush_cond_kill
@@:
		IOCS	_B_KEYINP
		tst.l	d0
		beq	@b
		rts


* condrv(em).sys 制御 ------------------------- *

* キー操作フラグアドレス収得
get_condrv_keyflag:
		jsr	(get_condrv_work)
		lea	(-17,a1),a1
		rts

* condrv(em).sys オープン禁止
condrv_koff:
		PUSH	d0/a0-a1
		bsr	get_condrv_keyflag
		bne	@f

		IOCS	_B_BPEEK		;フラグ収得
		move.b	d0,(cond_key_flag-a5sp,a5)
		moveq	#-1,d1			;koff
		subq.l	#1,a1
		IOCS	_B_BPOKE
@@:
		POP	d0/a0-a1
		rts

* condrv(em).sys オープン許可
condrv_kon:
		PUSH	d0/a0-a1
		bsr	get_condrv_keyflag
		bne	@f
		move.b	(cond_key_flag-a5sp,a5),d1
		bne	@f
		clr.b	(cond_key_flag-a5sp,a5)
		IOCS	_B_BPOKE		;フラグ設定
@@:
		POP	d0/a0-a1
		rts


* ウィンドウ設定 ------------------------------ *

init_window:
		bsr	init_win_main
		bsr	init_win_lnum
		bsr	init_win_mes
		bsr	init_win_info
		bsr	set_tabsize
		bra	print_info_line
**		rts

init_win_main:
		moveq	#96,d3			;X length
		bsr	get_lnum_or_dnum
		beq	@f
		moveq	#90,d3			;行数表示ありの場合
@@:
		move	d3,(screen_with-a5sp,a5)
		moveq	#96,d1
		sub	d3,d1			;X start
		moveq	#0,d2			;Y start
		moveq	#31,d4			;Y length
		jsr	(WinCreate)		;メインスクリーン表示管理領域設定
		move	d0,(win_no_main-a5sp,a5)
		rts

get_lnum_or_dnum:
		tst	(look_mode-a5sp,a5)
		bne	@f
		move	(＄lnum),d1
		rts
@@:
		move	(＄dnum),d1
@@:		rts

init_win_lnum:
		bsr	get_lnum_or_dnum
		beq.s	@b

		moveq	#0,d1			;X start
		moveq	#0,d2			;Y start
		moveq	#6,d3			;X length
		move.l	(line_num1-a5sp,a5),d4	;Y length
		jsr	(WinCreate)		;行番号表示管理領域設定
		move	d0,(win_no_lnum-a5sp,a5)

		bsr	get_lnum_or_dnum
		jmp	(WinSetColor)
**		rts

init_win_mes:
		moveq	#0,d1
		move.l	(line_num3-a5sp,a5),d2
		moveq	#96,d3
		moveq	#1,d4
		jsr	(WinCreate)		;メッセージ表示管理領域
		move	d0,(win_no_message-a5sp,a5)
		rts

init_win_info:
		moveq	#0,d1
		move.l	(line_num2-a5sp,a5),d2
		moveq	#96,d3
		moveq	#1,d4
		jsr	(WinCreate)		;インフォメーション表示管理領域
		move	d0,(win_no_info-a5sp,a5)
		move	(＄vcol),d1
		jmp	(WinSetColor)
**		rts

set_tabsize:
		move	(win_no_main-a5sp,a5),d0
		move	(file_tabsize-a5sp,a5),d1
		jmp	(WinSetTabsize)
**		rts


* ウィンドウ削除 ------------------------------ *

call_WinDelete:
		jmp	(WinDelete)
**		rts

call_clear_tvram:
		jmp	(clear_tvram)
**		rts

delete_window:
		move	(win_no_main-a5sp,a5),d0
		bsr	call_WinDelete
		move	(win_no_message-a5sp,a5),d0
		bsr	call_WinDelete
		move	(win_no_info-a5sp,a5),d0
		bsr	call_WinDelete
		bsr	get_lnum_or_dnum
		beq	clear_screen
		move	(win_no_lnum-a5sp,a5),d0
		bsr	call_WinDelete
clear_screen:
		moveq	#%0011,d0
		tst.b	(look_color_flag-a5sp,a5)
		beq	@f
		moveq	#%1111,d0
@@:		bsr	call_clear_tvram
		bra	init_fnckey_disp_mode
**		rts


* ファンクションキー表示切り換え -------------- *

init_fnckey_disp_mode:
		st	(fnckey_disp_mode-a5sp,a5)
		tst	(＄vfun)
		bne	@f
clear_fnckey:
		moveq	#3,d0			;%vfun 0 なら表示しない
		bra	1f

follow_fnckey_disp_mode:
		tst	(＄vfun)
		beq	follow_fnckey_disp_mode_end
@@:
		IOCS	_B_SFTSNS
		andi	#1,d0			;shift
		cmp	(fnckey_disp_mode-a5sp,a5),d0
		beq	follow_fnckey_disp_mode_end

		move	d0,(fnckey_disp_mode-a5sp,a5)
1:
		move	d0,-(sp)
		move	#14,-(sp)		;ファンクションキー表示切り換え
		DOS	_CONCTRL
		addq.l	#4,sp
follow_fnckey_disp_mode_end:
		rts


* Data Section -------------------------------- *

**		.data
		.even

subwin_input:	SUBWIN	8,24,0,1,NULL,NULL

txfill_buf:	.dc	$800c,0,0,0,0,$0000

dump_width:	.dc	16			;ダンプ幅
dump_width_lp:	.dc	15			;データ長
dump_size:	.dc	1			;キャラクタ表示Ｘ座標
dump_code_x:	.dc	3*16
cdmp_width:	.dc	80

str_temp:	.dc.b	'temp',0
str_mintvline:	.dc.b	'MINTVLINE',0

str_version:	.dc.b	'&look-file version 1.6 by BEL/季羅/Eriko.',0
str_ver_num:	.dc.b	'1.6',0

.if 0
str_break:	.dc.b	' break strings search',0
str_is_f:	.dc.b	'I-search:',0
str_is_r:	.ds.b	'I-search reverse:',0
.endif

str_tgl_exact:	.dc.b	'&toggle-search-pattern',0
str_tgl_dump:	.dc.b	'&toggle-dump-mode',0
str_tgl_lnum:	.dc.b	'&toggle-linenum-disp',0
str_tgl_tab:	.dc.b	'&toggle-tab-disp',0
str_tgl_tab_sz:	.dc.b	'&toggle-tab-size',0
str_tgl_reg:	.dc.b	'&toggle-regular',0
str_tgl_cr:	.dc.b	'&toggle-cr-disp',0
str_tgl_code:	.dc.b	'&change-code',0
str_exg_p_m:	.dc.b	'&exchange-point-and-mark',0
str_goto_mark:	.dc.b	'&goto-mark',0


* フォントパターン ---------------------------- *

		.even
font_bar:
		.dcb.b	16,%00010000

font_cr:
		.dc.b	%00000000		;%00000000
		.dc.b	%00000000		;%00000000
		.dc.b	%00000000		;%00000000
		.dc.b	%00000000		;%00000000
		.dc.b	%00000000		;%00000000
		.dc.b	%00000000		;%01111110
		.dc.b	%00111100		;%01000010
		.dc.b	%00100100		;%01000100
		.dc.b	%00100100		;%01000100
		.dc.b	%00100111		;%01001000
		.dc.b	%00100010		;%01001000
		.dc.b	%00100100		;%01010000
		.dc.b	%00101000		;%01010000
		.dc.b	%00110000		;%01100000
		.dc.b	%00100000		;%00000000
		.dc.b	%00000000		;%00000000

font_tab_arrow:
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00110000
		.dc.b	%00101000
		.dc.b	%00110000
*		.dc.b	%00000000
*		.dc.b	%00000000
*		.dc.b	%00000000
*		.dc.b	%00000000
*		.dc.b	%00000000
*		.dc.b	%00000000
*		.dc.b	%00000000

font_tab_dot:
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00010000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000
		.dc.b	%00000000


* キーバインド表 ------------------------------ *
* shift は prefix なしの時のみ有効

keybind_shift:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_NUL			;$01(ESC)
		.dc.b	KEY_NUL			;$02(1)
		.dc.b	KEY_NUL			;$03(2)
		.dc.b	KEY_NUL			;$04(3)
		.dc.b	KEY_JUMP$		;$05(4)
		.dc.b	KEY_NUL			;$06(5)
		.dc.b	KEY_NUL			;$07(6)
		.dc.b	KEY_NUL			;$08(7)
		.dc.b	KEY_NUL			;$09(8)
		.dc.b	KEY_NUL			;$0a(9)
		.dc.b	KEY_NUL			;$0b(0)
		.dc.b	KEY_NUL			;$0c(-)
		.dc.b	KEY_NUL			;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_NUL			;$10(TAB)
		.dc.b	KEY_NUL			;$11(Q)
		.dc.b	KEY_NUL			;$12(W)
		.dc.b	KEY_NUL			;$13(E)
		.dc.b	KEY_NUL			;$14(R)
		.dc.b	KEY_NUL			;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_HLFPGDW		;$17(U)
		.dc.b	KEY_NUL			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_NUL			;$1c([)
		.dc.b	KEY_EDIT		;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_REGSCH		;$1f(S)
		.dc.b	KEY_HLFPGUP		;$20(D)
		.dc.b	KEY_NUL			;$21(F)
		.dc.b	KEY_GOLAST		;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_NUL			;$24(J)
		.dc.b	KEY_NUL			;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_NUL			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_NUL			;$2b(X)
		.dc.b	KEY_NUL			;$2c(C)
		.dc.b	KEY_NUL			;$2d(V)
		.dc.b	KEY_NUL			;$2e(B)
		.dc.b	KEY_SCHBWN		;$2f(N)
		.dc.b	KEY_NUL			;$30(M)
		.dc.b	KEY_GOHOME		;$31(,)
		.dc.b	KEY_GOLAST		;$32(.)
		.dc.b	KEY_SCHBW		;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_NUL			;$35(SPACE)
		.dc.b	KEY_NUL			;$36(HOME)
		.dc.b	KEY_NUL			;$37(DEL)
		.dc.b	KEY_NUL			;$38(ROLL UP)
		.dc.b	KEY_NUL			;$39(ROLL DOWN)
		.dc.b	KEY_NUL			;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_NUL			;$42(t-)
		.dc.b	KEY_NUL			;$43(t7)
		.dc.b	KEY_NUL			;$44(t8)
		.dc.b	KEY_NUL			;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_NUL			;$47(t4)
		.dc.b	KEY_NUL			;$48(t5)
		.dc.b	KEY_NUL			;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_NUL			;$4b(t1)
		.dc.b	KEY_NUL			;$4c(t2)
		.dc.b	KEY_NUL			;$4d(t3)
		.dc.b	KEY_NUL			;$4e(ENTER)
		.dc.b	KEY_NUL			;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_NUL			;$63(F0)
		.dc.b	KEY_NUL			;$64(F1)
		.dc.b	KEY_NUL			;$65(F2)
		.dc.b	KEY_SCHBW		;$66(F3)
		.dc.b	KEY_SCHBWN		;$67(F4)
		.dc.b	KEY_NUL			;$68(F5)
		.dc.b	KEY_NUL			;$69(F6)
		.dc.b	KEY_NUL			;$6a(F7)
		.dc.b	KEY_NUL			;$6b(F8)
		.dc.b	KEY_NUL			;$6c(F9)

keybind_normal:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_META		;$01(ESC)
		.dc.b	KEY_JUMP1		;$02(1)
		.dc.b	KEY_JUMP2		;$03(2)
		.dc.b	KEY_JUMP3		;$04(3)
		.dc.b	KEY_JUMP4		;$05(4)
		.dc.b	KEY_JUMP5		;$06(5)
		.dc.b	KEY_JUMP6		;$07(6)
		.dc.b	KEY_JUMP7		;$08(7)
		.dc.b	KEY_JUMP8		;$09(8)
		.dc.b	KEY_JUMP9		;$0a(9)
		.dc.b	KEY_JUMP		;$0b(0)
		.dc.b	KEY_DUMP		;$0c(-)
		.dc.b	KEY_COLOR		;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_TAB			;$10(TAB)
		.dc.b	KEY_QUIT		;$11(Q)
		.dc.b	KEY_NUL			;$12(W)
		.dc.b	KEY_EDIT		;$13(E)
		.dc.b	KEY_REG			;$14(R)
		.dc.b	KEY_TABSIZE		;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_HLFRLDW		;$17(U)
		.dc.b	KEY_NUL			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_NUL			;$1c([)
		.dc.b	KEY_QUIT		;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_CASE		;$1f(S)
		.dc.b	KEY_HLFRLUP		;$20(D)
		.dc.b	KEY_ROLLUP		;$21(F)
		.dc.b	KEY_GOHOME		;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_LINEDW		;$24(J)
		.dc.b	KEY_LINEUP		;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_NUL			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_NUL			;$2b(X)
		.dc.b	KEY_CODE		;$2c(C)
		.dc.b	KEY_EDIT		;$2d(V)
		.dc.b	KEY_ROLLDW		;$2e(B)
		.dc.b	KEY_SCHFWN		;$2f(N)
		.dc.b	KEY_NUL			;$30(M)
		.dc.b	KEY_NUL			;$31(,)
		.dc.b	KEY_NUL			;$32(.)
		.dc.b	KEY_SCHFW		;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_ROLLUP		;$35(SPACE)
		.dc.b	KEY_GOHOME		;$36(HOME)
		.dc.b	KEY_GOLAST		;$37(DEL)
		.dc.b	KEY_PAGEUP		;$38(ROLL UP)
		.dc.b	KEY_PAGEDW		;$39(ROLL DOWN)
		.dc.b	KEY_QUIT		;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_DUMP		;$42(t-)
		.dc.b	KEY_JUMP7		;$43(t7)
		.dc.b	KEY_JUMP8		;$44(t8)
		.dc.b	KEY_JUMP9		;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_JUMP4		;$47(t4)
		.dc.b	KEY_JUMP5		;$48(t5)
		.dc.b	KEY_JUMP6		;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_JUMP1		;$4b(t1)
		.dc.b	KEY_JUMP2		;$4c(t2)
		.dc.b	KEY_JUMP3		;$4d(t3)
		.dc.b	KEY_QUIT		;$4e(ENTER)
		.dc.b	KEY_JUMP		;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_GOHOME		;$63(F0)
		.dc.b	KEY_GOLAST		;$64(F1)
		.dc.b	KEY_JUMP		;$65(F2)
		.dc.b	KEY_SCHFW		;$66(F3)
		.dc.b	KEY_SCHFWN		;$67(F4)
		.dc.b	KEY_MARK		;$68(F5)
		.dc.b	KEY_WRITE		;$69(F6)
		.dc.b	KEY_QUIT		;$6a(F7)
		.dc.b	KEY_SCHBW		;$6b(F8)
		.dc.b	KEY_SCHBWN		;$6c(F9)

keybind_ctrl:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_NUL			;$01(ESC)
		.dc.b	KEY_NUL			;$02(1)
		.dc.b	KEY_NUL			;$03(2)
		.dc.b	KEY_NUL			;$04(3)
		.dc.b	KEY_NUL			;$05(4)
		.dc.b	KEY_NUL			;$06(5)
		.dc.b	KEY_NUL			;$07(6)
		.dc.b	KEY_NUL			;$08(7)
		.dc.b	KEY_NUL			;$09(8)
		.dc.b	KEY_NUL			;$0a(9)
		.dc.b	KEY_NUL			;$0b(0)
		.dc.b	KEY_NUL			;$0c(-)
		.dc.b	KEY_NUL			;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_NUL			;$10(TAB)
		.dc.b	KEY_NUL			;$11(Q)
		.dc.b	KEY_WRITE		;$12(W)
		.dc.b	KEY_NUL			;$13(E)
		.dc.b	KEY_SCHBW		;$14(R)
		.dc.b	KEY_NUL			;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_NUL			;$17(U)
		.dc.b	KEY_TAB			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_META		;$1c([)
		.dc.b	KEY_NUL			;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_SCHFW		;$1f(S)
		.dc.b	KEY_QUIT		;$20(D)
		.dc.b	KEY_NUL			;$21(F)
		.dc.b	KEY_NUL			;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_NUL			;$24(J)
		.dc.b	KEY_NUL			;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_NUL			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_CTRLX		;$2b(X)
		.dc.b	KEY_NUL			;$2c(C)
		.dc.b	KEY_NUL			;$2d(V)
		.dc.b	KEY_NUL			;$2e(B)
		.dc.b	KEY_NUL			;$2f(N)
		.dc.b	KEY_NUL			;$30(M)
		.dc.b	KEY_NUL			;$31(,)
		.dc.b	KEY_NUL			;$32(.)
		.dc.b	KEY_NUL			;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_MARK		;$35(SPACE)
		.dc.b	KEY_NUL			;$36(HOME)
		.dc.b	KEY_NUL			;$37(DEL)
		.dc.b	KEY_GOLAST		;$38(ROLL UP)
		.dc.b	KEY_GOHOME		;$39(ROLL DOWN)
		.dc.b	KEY_NUL			;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_NUL			;$42(t-)
		.dc.b	KEY_NUL			;$43(t7)
		.dc.b	KEY_NUL			;$44(t8)
		.dc.b	KEY_NUL			;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_NUL			;$47(t4)
		.dc.b	KEY_NUL			;$48(t5)
		.dc.b	KEY_NUL			;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_NUL			;$4b(t1)
		.dc.b	KEY_NUL			;$4c(t2)
		.dc.b	KEY_NUL			;$4d(t3)
		.dc.b	KEY_NUL			;$4e(ENTER)
		.dc.b	KEY_NUL			;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_NUL			;$63(F0)
		.dc.b	KEY_NUL			;$64(F1)
		.dc.b	KEY_NUL			;$65(F2)
		.dc.b	KEY_NUL			;$66(F3)
		.dc.b	KEY_NUL			;$67(F4)
		.dc.b	KEY_NUL			;$68(F5)
		.dc.b	KEY_NUL			;$69(F6)
		.dc.b	KEY_NUL			;$6a(F7)
		.dc.b	KEY_NUL			;$6b(F8)
		.dc.b	KEY_NUL			;$6c(F9)

keybind_meta_normal:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_QUIT		;$01(ESC)
		.dc.b	KEY_NUL			;$02(1)
		.dc.b	KEY_NUL			;$03(2)
		.dc.b	KEY_NUL			;$04(3)
		.dc.b	KEY_NUL			;$05(4)
		.dc.b	KEY_NUL			;$06(5)
		.dc.b	KEY_NUL			;$07(6)
		.dc.b	KEY_NUL			;$08(7)
		.dc.b	KEY_NUL			;$09(8)
		.dc.b	KEY_NUL			;$0a(9)
		.dc.b	KEY_NUL			;$0b(0)
		.dc.b	KEY_LINENUM		;$0c(-)
		.dc.b	KEY_NUL			;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_NUL			;$10(TAB)
		.dc.b	KEY_QUIT		;$11(Q)
		.dc.b	KEY_WRITE		;$12(W)
		.dc.b	KEY_NUL			;$13(E)
		.dc.b	KEY_NUL			;$14(R)
		.dc.b	KEY_NUL			;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_NUL			;$17(U)
		.dc.b	KEY_NUL			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_NUL			;$1c([)
		.dc.b	KEY_NUL			;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_NUL			;$1f(S)
		.dc.b	KEY_NUL			;$20(D)
		.dc.b	KEY_NUL			;$21(F)
		.dc.b	KEY_NUL			;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_NUL			;$24(J)
		.dc.b	KEY_NUL			;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_CR			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_NUL			;$2b(X)
		.dc.b	KEY_NUL			;$2c(C)
		.dc.b	KEY_NUL			;$2d(V)
		.dc.b	KEY_NUL			;$2e(B)
		.dc.b	KEY_NUL			;$2f(N)
		.dc.b	KEY_CR			;$30(M)
		.dc.b	KEY_NUL			;$31(,)
		.dc.b	KEY_MARK		;$32(.)
		.dc.b	KEY_NUL			;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_MARK		;$35(SPACE)
		.dc.b	KEY_NUL			;$36(HOME)
		.dc.b	KEY_NUL			;$37(DEL)
		.dc.b	KEY_NUL			;$38(ROLL UP)
		.dc.b	KEY_NUL			;$39(ROLL DOWN)
		.dc.b	KEY_NUL			;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_NUL			;$42(t-)
		.dc.b	KEY_NUL			;$43(t7)
		.dc.b	KEY_NUL			;$44(t8)
		.dc.b	KEY_NUL			;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_NUL			;$47(t4)
		.dc.b	KEY_NUL			;$48(t5)
		.dc.b	KEY_NUL			;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_NUL			;$4b(t1)
		.dc.b	KEY_NUL			;$4c(t2)
		.dc.b	KEY_NUL			;$4d(t3)
		.dc.b	KEY_NUL			;$4e(ENTER)
		.dc.b	KEY_NUL			;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_NUL			;$63(F0)
		.dc.b	KEY_NUL			;$64(F1)
		.dc.b	KEY_NUL			;$65(F2)
		.dc.b	KEY_NUL			;$66(F3)
		.dc.b	KEY_NUL			;$67(F4)
		.dc.b	KEY_NUL			;$68(F5)
		.dc.b	KEY_NUL			;$69(F6)
		.dc.b	KEY_NUL			;$6a(F7)
		.dc.b	KEY_NUL			;$6b(F8)
		.dc.b	KEY_NUL			;$6c(F9)

keybind_meta_ctrl:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_NUL			;$01(ESC)
		.dc.b	KEY_NUL			;$02(1)
		.dc.b	KEY_NUL			;$03(2)
		.dc.b	KEY_NUL			;$04(3)
		.dc.b	KEY_NUL			;$05(4)
		.dc.b	KEY_NUL			;$06(5)
		.dc.b	KEY_NUL			;$07(6)
		.dc.b	KEY_NUL			;$08(7)
		.dc.b	KEY_NUL			;$09(8)
		.dc.b	KEY_NUL			;$0a(9)
		.dc.b	KEY_NUL			;$0b(0)
		.dc.b	KEY_NUL			;$0c(-)
		.dc.b	KEY_NUL			;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_NUL			;$10(TAB)
		.dc.b	KEY_NUL			;$11(Q)
		.dc.b	KEY_NUL			;$12(W)
		.dc.b	KEY_NUL			;$13(E)
		.dc.b	KEY_NUL			;$14(R)
		.dc.b	KEY_NUL			;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_NUL			;$17(U)
		.dc.b	KEY_NUL			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_NUL			;$1c([)
		.dc.b	KEY_NUL			;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_NUL			;$1f(S)
		.dc.b	KEY_NUL			;$20(D)
		.dc.b	KEY_NUL			;$21(F)
		.dc.b	KEY_GOTOMARK		;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_NUL			;$24(J)
		.dc.b	KEY_NUL			;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_NUL			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_NUL			;$2b(X)
		.dc.b	KEY_NUL			;$2c(C)
		.dc.b	KEY_VERSION		;$2d(V)
		.dc.b	KEY_NUL			;$2e(B)
		.dc.b	KEY_NUL			;$2f(N)
		.dc.b	KEY_NUL			;$30(M)
		.dc.b	KEY_NUL			;$31(,)
		.dc.b	KEY_NUL			;$32(.)
		.dc.b	KEY_NUL			;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_NUL			;$35(SPACE)
		.dc.b	KEY_NUL			;$36(HOME)
		.dc.b	KEY_NUL			;$37(DEL)
		.dc.b	KEY_NUL			;$38(ROLL UP)
		.dc.b	KEY_NUL			;$39(ROLL DOWN)
		.dc.b	KEY_NUL			;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_NUL			;$42(t-)
		.dc.b	KEY_NUL			;$43(t7)
		.dc.b	KEY_NUL			;$44(t8)
		.dc.b	KEY_NUL			;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_NUL			;$47(t4)
		.dc.b	KEY_NUL			;$48(t5)
		.dc.b	KEY_NUL			;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_NUL			;$4b(t1)
		.dc.b	KEY_NUL			;$4c(t2)
		.dc.b	KEY_NUL			;$4d(t3)
		.dc.b	KEY_NUL			;$4e(ENTER)
		.dc.b	KEY_NUL			;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_NUL			;$63(F0)
		.dc.b	KEY_NUL			;$64(F1)
		.dc.b	KEY_NUL			;$65(F2)
		.dc.b	KEY_NUL			;$66(F3)
		.dc.b	KEY_NUL			;$67(F4)
		.dc.b	KEY_NUL			;$68(F5)
		.dc.b	KEY_NUL			;$69(F6)
		.dc.b	KEY_NUL			;$6a(F7)
		.dc.b	KEY_NUL			;$6b(F8)
		.dc.b	KEY_NUL			;$6c(F9)

keybind_ctrlx_normal:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_NUL			;$01(ESC)
		.dc.b	KEY_NUL			;$02(1)
		.dc.b	KEY_NUL			;$03(2)
		.dc.b	KEY_NUL			;$04(3)
		.dc.b	KEY_NUL			;$05(4)
		.dc.b	KEY_NUL			;$06(5)
		.dc.b	KEY_NUL			;$07(6)
		.dc.b	KEY_NUL			;$08(7)
		.dc.b	KEY_NUL			;$09(8)
		.dc.b	KEY_NUL			;$0a(9)
		.dc.b	KEY_NUL			;$0b(0)
		.dc.b	KEY_NUL			;$0c(-)
		.dc.b	KEY_NUL			;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_NUL			;$10(TAB)
		.dc.b	KEY_NUL			;$11(Q)
		.dc.b	KEY_NUL			;$12(W)
		.dc.b	KEY_NUL			;$13(E)
		.dc.b	KEY_NUL			;$14(R)
		.dc.b	KEY_NUL			;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_NUL			;$17(U)
		.dc.b	KEY_NUL			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_NUL			;$1c([)
		.dc.b	KEY_NUL			;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_NUL			;$1f(S)
		.dc.b	KEY_NUL			;$20(D)
		.dc.b	KEY_NUL			;$21(F)
		.dc.b	KEY_NUL			;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_NUL			;$24(J)
		.dc.b	KEY_NUL			;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_NUL			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_NUL			;$2b(X)
		.dc.b	KEY_NUL			;$2c(C)
		.dc.b	KEY_NUL			;$2d(V)
		.dc.b	KEY_NUL			;$2e(B)
		.dc.b	KEY_NUL			;$2f(N)
		.dc.b	KEY_NUL			;$30(M)
		.dc.b	KEY_NUL			;$31(,)
		.dc.b	KEY_NUL			;$32(.)
		.dc.b	KEY_NUL			;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_NUL			;$35(SPACE)
		.dc.b	KEY_NUL			;$36(HOME)
		.dc.b	KEY_NUL			;$37(DEL)
		.dc.b	KEY_NUL			;$38(ROLL UP)
		.dc.b	KEY_NUL			;$39(ROLL DOWN)
		.dc.b	KEY_NUL			;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_NUL			;$42(t-)
		.dc.b	KEY_NUL			;$43(t7)
		.dc.b	KEY_NUL			;$44(t8)
		.dc.b	KEY_NUL			;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_NUL			;$47(t4)
		.dc.b	KEY_NUL			;$48(t5)
		.dc.b	KEY_NUL			;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_NUL			;$4b(t1)
		.dc.b	KEY_NUL			;$4c(t2)
		.dc.b	KEY_NUL			;$4d(t3)
		.dc.b	KEY_NUL			;$4e(ENTER)
		.dc.b	KEY_NUL			;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_NUL			;$63(F0)
		.dc.b	KEY_NUL			;$64(F1)
		.dc.b	KEY_NUL			;$65(F2)
		.dc.b	KEY_NUL			;$66(F3)
		.dc.b	KEY_NUL			;$67(F4)
		.dc.b	KEY_NUL			;$68(F5)
		.dc.b	KEY_NUL			;$69(F6)
		.dc.b	KEY_NUL			;$6a(F7)
		.dc.b	KEY_NUL			;$6b(F8)
		.dc.b	KEY_NUL			;$6c(F9)

keybind_ctrlx_ctrl:
		.dc.b	KEY_NUL			;$00
		.dc.b	KEY_NUL			;$01(ESC)
		.dc.b	KEY_NUL			;$02(1)
		.dc.b	KEY_NUL			;$03(2)
		.dc.b	KEY_NUL			;$04(3)
		.dc.b	KEY_NUL			;$05(4)
		.dc.b	KEY_NUL			;$06(5)
		.dc.b	KEY_NUL			;$07(6)
		.dc.b	KEY_NUL			;$08(7)
		.dc.b	KEY_NUL			;$09(8)
		.dc.b	KEY_NUL			;$0a(9)
		.dc.b	KEY_NUL			;$0b(0)
		.dc.b	KEY_NUL			;$0c(-)
		.dc.b	KEY_NUL			;$0d(^)
		.dc.b	KEY_NUL			;$0e(\)
		.dc.b	KEY_NUL			;$0f(BS)
		.dc.b	KEY_NUL			;$10(TAB)
		.dc.b	KEY_NUL			;$11(Q)
		.dc.b	KEY_NUL			;$12(W)
		.dc.b	KEY_NUL			;$13(E)
		.dc.b	KEY_NUL			;$14(R)
		.dc.b	KEY_NUL			;$15(T)
		.dc.b	KEY_NUL			;$16(Y)
		.dc.b	KEY_NUL			;$17(U)
		.dc.b	KEY_NUL			;$18(I)
		.dc.b	KEY_NUL			;$19(O)
		.dc.b	KEY_NUL			;$1a(P)
		.dc.b	KEY_NUL			;$1b(@)
		.dc.b	KEY_NUL			;$1c([)
		.dc.b	KEY_NUL			;$1d(CR)
		.dc.b	KEY_NUL			;$1e(A)
		.dc.b	KEY_NUL			;$1f(S)
		.dc.b	KEY_NUL			;$20(D)
		.dc.b	KEY_NUL			;$21(F)
		.dc.b	KEY_JUMP		;$22(G)
		.dc.b	KEY_NUL			;$23(H)
		.dc.b	KEY_NUL			;$24(J)
		.dc.b	KEY_NUL			;$25(K)
		.dc.b	KEY_NUL			;$26(L)
		.dc.b	KEY_NUL			;$27(;)
		.dc.b	KEY_NUL			;$28(:)
		.dc.b	KEY_NUL			;$29(])
		.dc.b	KEY_NUL			;$2a(Z)
		.dc.b	KEY_EXG			;$2b(X)
		.dc.b	KEY_QUIT		;$2c(C)
		.dc.b	KEY_NUL			;$2d(V)
		.dc.b	KEY_NUL			;$2e(B)
		.dc.b	KEY_NUL			;$2f(N)
		.dc.b	KEY_NUL			;$30(M)
		.dc.b	KEY_NUL			;$31(,)
		.dc.b	KEY_NUL			;$32(.)
		.dc.b	KEY_NUL			;$33(/)
		.dc.b	KEY_NUL			;$34(_)
		.dc.b	KEY_NUL			;$35(SPACE)
		.dc.b	KEY_NUL			;$36(HOME)
		.dc.b	KEY_NUL			;$37(DEL)
		.dc.b	KEY_NUL			;$38(ROLL UP)
		.dc.b	KEY_NUL			;$39(ROLL DOWN)
		.dc.b	KEY_NUL			;$3a(UNDO)
		.dc.b	KEY_NUL			;$3b(←)
		.dc.b	KEY_NUL			;$3c(↑)
		.dc.b	KEY_NUL			;$3d(→)
		.dc.b	KEY_NUL			;$3e(↓)
		.dc.b	KEY_NUL			;$3f(CLR)
		.dc.b	KEY_NUL			;$40(t/)
		.dc.b	KEY_NUL			;$41(t*)
		.dc.b	KEY_NUL			;$42(t-)
		.dc.b	KEY_NUL			;$43(t7)
		.dc.b	KEY_NUL			;$44(t8)
		.dc.b	KEY_NUL			;$45(t9)
		.dc.b	KEY_NUL			;$46(t+)
		.dc.b	KEY_NUL			;$47(t4)
		.dc.b	KEY_NUL			;$48(t5)
		.dc.b	KEY_NUL			;$49(t6)
		.dc.b	KEY_NUL			;$4a(t=)
		.dc.b	KEY_NUL			;$4b(t1)
		.dc.b	KEY_NUL			;$4c(t2)
		.dc.b	KEY_NUL			;$4d(t3)
		.dc.b	KEY_NUL			;$4e(ENTER)
		.dc.b	KEY_NUL			;$4f(t0)
		.dc.b	KEY_NUL			;$50(t,)
		.dc.b	KEY_NUL			;$51(t.)
		.dc.b	KEY_NUL			;$52(記号入力)
		.dc.b	KEY_NUL			;$53(登録)
		.dc.b	KEY_NUL			;$54(HELP)
		.dc.b	KEY_NUL			;$55(XF1)
		.dc.b	KEY_NUL			;$56(XF2)
		.dc.b	KEY_NUL			;$57(XF3)
		.dc.b	KEY_NUL			;$58(XF4)
		.dc.b	KEY_NUL			;$59(XF5)
		.dc.b	KEY_NUL			;$5a(かな)
		.dc.b	KEY_NUL			;$5b(ﾛｰﾏ字)
		.dc.b	KEY_NUL			;$5c(ｺｰﾄﾞ入力)
		.dc.b	KEY_NUL			;$5d(CAPS)
		.dc.b	KEY_NUL			;$5e(INS)
		.dc.b	KEY_NUL			;$5f(ひらがな)
		.dc.b	KEY_NUL			;$60(全角)
		.dc.b	KEY_NUL			;$61(BREAK)
		.dc.b	KEY_NUL			;$62(COPY)
		.dc.b	KEY_NUL			;$63(F0)
		.dc.b	KEY_NUL			;$64(F1)
		.dc.b	KEY_NUL			;$65(F2)
		.dc.b	KEY_NUL			;$66(F3)
		.dc.b	KEY_NUL			;$67(F4)
		.dc.b	KEY_NUL			;$68(F5)
		.dc.b	KEY_NUL			;$69(F6)
		.dc.b	KEY_NUL			;$6a(F7)
		.dc.b	KEY_NUL			;$6b(F8)
		.dc.b	KEY_NUL			;$6c(F9)


* キーバインドのユーザ定義用 ------------------ *

bind_token:
		.dc.b	'nop',0
		.dc.b	'one-line-up',0
		.dc.b	'one-line-down',0
		.dc.b	'half-page-up',0
		.dc.b	'half-page-down',0
		.dc.b	'half-page-roll-up',0
		.dc.b	'half-page-roll-down',0
		.dc.b	'one-page-up',0
		.dc.b	'one-page-down',0
		.dc.b	'one-page-roll-up',0
		.dc.b	'one-page-roll-down',0
		.dc.b	'go-home-position',0
		.dc.b	'go-last-position',0
		.dc.b	'line-jump',0
		.dc.b	'line-jump1',0
		.dc.b	'line-jump2',0
		.dc.b	'line-jump3',0
		.dc.b	'line-jump4',0
		.dc.b	'line-jump5',0
		.dc.b	'line-jump6',0
		.dc.b	'line-jump7',0
		.dc.b	'line-jump8',0
		.dc.b	'line-jump9',0
		.dc.b	'line-jump$',0
		.dc.b	'search-forward',0
		.dc.b	'search-forward-next',0
		.dc.b	'search-backward',0
		.dc.b	'search-backward-next',0
		.dc.b	'isearch-forward',0
		.dc.b	'isearch-backward',0
		.dc.b	'search-regexp',0
		.dc.b	'search-regexp-next',0
		.dc.b	'toggle-regular',0
		.dc.b	'toggle-cr-disp',0
		.dc.b	'toggle-tab-disp',0
		.dc.b	'toggle-tab-size',0
		.dc.b	'toggle-linenum-disp',0
		.dc.b	'quit',0
		.dc.b	'editor-tag-jump',0
		.dc.b	'change-dump-mode',0
		.dc.b	'toggle-color-mode',0
		.dc.b	'toggle-exact',0
		.dc.b	'meta',0
		.dc.b	'ctrl-x',0
		.dc.b	'm-write',0
		.dc.b	'mark',0
		.dc.b	'goto-mark',0
		.dc.b	'exchange-point-and-mark',0
		.dc.b	'change-kanji-code',0
		.dc.b	'print-version',0
		.dc.b	0


* Block Storage Section ----------------------- *

		.bss
		.even

LOOK_FILE_NAME::.ds.b	90

bm_patlen:	.ds	1			;パターン長-1
bm_table:	.ds.b	256			;移動量テーブル
bm_pat:		.ds.b	256			;反転パターン

bm_patlen_r:	.ds	1			;パターン長-1
bm_table_r:	.ds.b	256			;移動量テーブル
bm_pat_r:	.ds.b	256			;パターン

yar_table:	.ds.b	YAR_TABLE_SIZE

a5sp:
total_line:	.ds.l	1			;総行数+2
total_dump:	.ds.l	1			;総行数+2
total_cdmp:	.ds.l	1			;総行数+2
top_line:	.ds.l	1			;現在表示中左上行数
cursor_line:	.ds.l	1			;画面上でのカーソル位置(0～28/29)

line_num:	.ds.l	1			;１画面の行数	27/28
line_num1:	.ds.l	1			;〃 +1		28/29
line_num2:	.ds.l	1			;〃 +2		29/30
line_num3:	.ds.l	1			;〃 +3		30/31
raster0:	.ds	1			;$6f/$73 28*4-1/29*4-1
raster1:	.ds	1			;$70/$74
raster2:	.ds	1			;$71/$75 29*4-3/30*4-3
raster3:	.ds	1			;$72/$76 29*4-2/30*4-2
raster4:	.ds	1			;$73/$77 29*4-1/30*4-1
raster5:	.ds	1			;$78/$7c

ras_req_print_line:
		.ds.l	1
ras_req_count:	.ds	1
ras_req_kind:	.ds	1

win_no_main:	.ds	1			;本文表示ウィンドウ
win_no_lnum:	.ds	1			;行番号
win_no_message:	.ds	1			;メッセージ
win_no_info:	.ds	1			;インフォメーション行
win_no_input:	.ds	1			;行入力

int_sr_ptr:	.ds.l	1
remained_task:	.ds.l	1
now_total_line:	.ds.l	1			;現在行表示での総行数
last_search_line:
		.ds.l	1
search_timer:	.ds	1

line_buf_last:	.ds.l	1
line_buf:	.ds.l	1
file_buf:	.ds.l	1
file_read_end:	.ds.l	1

file_size:	.ds.l	1
file_name:	.ds.l	1
file_handle:	.ds	1
file_tabsize:	.ds	1
screen_with:	.ds	1
path_len:	.ds	1

mark_line_log:	.ds.l	1
top_line2:	.ds.l	1
viewer_flag:	.ds	1

mark_line_phy:	.ds.l	1
write_fileno	.ds	1

lnum_save:	.ds	1
dnum_save:	.ds	1

text_palet:	.ds	8			;テキストパレット退避バッファ
gm_mask_state:	.ds	1
fnckey_disp_mode:
		.ds	1

wind_save:	.ds	1			;＄wind 保存用
txrascpy_regs:	.ds	3			;d1-d3

write_path:	.ds.b	64
write_filename:	.ds.b	128
filename_save:	.ds.b	22+1

int_flag:	.ds.b	1

search_type:	.ds.b	1
search_header:	.ds.b	1
search_str_buf:	.ds.b	128
search_str_buf2:.ds.b	128

		.even
csr_rept_wait:	.ds.l	1			;CTRL/OPT.2＋カーソル用
last_csr_key:	.ds.b	1

look_flag:	.ds.b	1
jump_first_num:	.ds.b	1
fg_stat:	.ds.b	1			;fg -> bg ステータス
bg_stat:	.ds.b	1			;bg -> fg ステータス
memory_devid:	.ds.b	1
not_enough_mem:	.ds.b	1
over_interrupt:	.ds.b	1
load_comp_flag:	.ds.b	1
reload_flag:	.ds.b	1

		.even
prefix:		.ds	1			;0=なし 2=Meta 4=C-x
keycode:	.ds.b	1

prev_mb_flag:	.ds.b	1
o_l_p_flag:	.ds.b	1
csr_disp_flag:	.ds.b	1
search_flag:	.ds.b	1			;不明
sch_next_flag:	.ds.b	1
searched_flag:	.ds.b	1

tab_size_flag:	.ds.b	1

		.even
lookfile_static_flags::
look_mode::	.ds	1			;0=VIEW 1=DUMP 2=CDMP
look_yar_flag:	.ds.b	1			;-r = 全角文字の半角化表示	(保存有り)
look_color_flag:.ds.b	1			;-^,-C = カラー表示		(保存有り)
kanji_code:	.ds.b	1			;0=SJIS 1=JIS $ff=EUC		(保存有り)
search_exact:	.ds.b	1			;検索時の大文字小文字区別	(保存有り)
		.ds	1			;予約
		.even
*		.fail	($-lookfile_static_flags).ne.LOOKFILE_STATIC_FLAGS_SIZE

jis_mb_not:	.ds.b	1
ksi:		.ds.b	1
cr_flag:	.ds.b	1
mb_flag:	.ds.b	1

bs_flag:	.ds.b	1			;-b = BS を処理するか？(保存無し)
esc_flag:	.ds.b	1			;-e = ESC を処理するか？(保存無し)
out_of_mem_flag:.ds.b	1
bs_extend_flag:	.ds.b	1			;BS の特殊表示から復帰するか？
v_exec_flag:	.ds.b	1

mfp_ierb_save:	.ds.b	1
mfp_imrb_save:	.ds.b	1
cond_key_flag:	.ds.b	1

		.even
vdisp_vec_save:	.ds.l	1
keyinp_vec_save:.ds.l	1
skey_vec_save:	.ds.l	1


		.end

* End of File --------------------------------- *
