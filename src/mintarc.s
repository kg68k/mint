# mintarc.s - mintarc
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

*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
*┃ 										 ┃┐
*┃ 		■         [Mintarc Virtural Directory]       ■		 ┃│
*┃ 		                                                		 ┃│
*┃ 		■            [Release version 0.99]          ■		 ┃│
*┃ 										 ┃│
*┃ 							Idea & Original	by Leaza ┃│
*┃ 							Programmed	by KIRAH ┃│
*┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛│
*  └───────────────────────────────────────┘
*
*		THIS is ARCHIVE OPERATION PROGRAM for MINT ver 2.00 ayu ??
*				K.KIRAH 1994～1995


* Include File -------------------------------- *

		.include	mint.mac
		.include	window.mac
		.include	archive.mac
		.include	message.mac
		.include	func.mac
		.include	sysval.def

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac


* Global Sybmol ------------------------------- *

* cpmv.s
		.xref	is_exist_dir
		.xref	del_a0
* fileop.s
		.xref	to_mintslash
		.xref	get_curdir_a1
		.xref	print_write_protect_error
		.xref	check_yes_or_no,ask_window_sub
* madoka3.s
		.xref	＠buildin,＠status
		.xref	execute_quick_no
* mint.s
		.xref	print_screen,print_cplp_line
		.xref	directory_write_routin
		.xref	search_cursor_file,search_mark_file
		.xref	set_current_dir,reset_current_dir
		.xref	is_parent_directory_a4
		.xref	dos_drvctrl_d1
		.xref	to_fullpath_file
		.xref	set_path_use_byte,set_path_free_byte_ratio
		.xref	winsize_cursor_revise
		.xref	cur_dir_buf,MINT_TEMP,MINTSLASH
		.xref	ctypetable,malloc_mode,into_marc_flag
* outside.s
		.xref	print_sub
		.xref	resume_stops,stop_flags
* patternmatch.s
		.xref	init_i_c_option,take_i_c_option
		.xref	_fre_compile,_fre_match,_ignore_case


* Fixed Number -------------------------------- *

ARC_FILE_MAX:	.equ	1024

END_OF_OFB:	.equ	-1
END_OF_NFB:	.equ	-1

END_OF_AFL:	.equ	LINK			;mintarc 内ではリンク使用不可

sizeof_WIN_BUF:	.equ	8+2
*sizeof_WIN_BUF:.equ	sizeof_WIND


* Offset Table -------------------------------- *

;書庫内ファイルリスト(MARC_[N]FILES の為の情報などを保持)
;archive_file_list_buffer
		.offset	0
AFL_DIRNAME:	.ds.b	48
AFL_FILENAME:	.ds.b	22+1
AFL_ATR:	.ds.b	1			;bit 6=end of buf
AFL_SIZE:	.ds.l	1
AFL_TIME_DATE:	.ds.l	1			;time/date
AFL_BUF_SIZE:
		.fail	$.ne.80


;new/old_files_buffer
		.offset	0
OFB_FLAG:					;bit0=1;展開要求
NFB_FLAG:	.ds.b	1			;bit7=1:dir 1.w=-1:end of buffer
OFB_FULLPATH:
NFB_FULLPATH:	.ds.b	64
		.even
OFB_FILES:
NFB_FILES:	.ds.b	FILES_SIZE
OFB_SIZE:
NFB_SIZE:
		.fail	$.ne.(66+54)


;mintarc_buffer
		.offset	0
MA_AFL_PTR:	.ds.l	1
MA_WIN_BUF:	.ds.b	sizeof_WIN_BUF
MA_PREV_PTR:	.ds.l	1
MA_ARC_FILE:	.ds.b	PATHNAME_MAX+FILENAME_MAX+1
MA_DIR_FLAG:	.ds.b	1
MA_TMP_DIR:	.ds.b	91
MA_PATH_BUF:	.ds.b	sizeof_PATHBUF
MA_REAL_SIZEh:	.ds.l	1			;展開後サイズ合計 上位
MA_REAL_SIZEl:	.ds.l	1			;〃		  下位
MA_ARC_SIZEh:	.ds.l	1			;圧縮時サイズ合計 上位
MA_ARC_SIZEl:	.ds.l	1			;〃		  下位
MA_FILE_NUM:	.ds	1			;ファイル数
MA_OFB_PTR:	.ds.l	1			;old_files_buffer
MA_NFB_PTR:	.ds.l	1			;new_files_buffer
MA_CURDIR:	.ds.b	64			;カレントディレクトリ保存
MA_ARC_TYPE:	.ds.b	1			;$00=lzh $ff=zip $01=tar
MA_EXT_FLAG:	.ds.b	1			;展開済みフラグ
MA_RELOAD:	.ds.b	1
		.even
sizeof_MA:


* Macro --------------------------------------- *

_NEXT_BUF:		.macro	ar
			lea	(AFL_BUF_SIZE,ar),ar
			.endm
_PREV_BUF:		.macro	ar
			lea	(-AFL_BUF_SIZE,ar),ar
			.endm
_BUF_CLR:		.macro
			bsr	clear_afl_buffer
			.endm
_DIR_FLG_ON:		.macro	ar
			bset	#DIRECTORY,(AFL_ATR,ar)
			.endm
_IS_DIR:		.macro	ar
			btst	#DIRECTORY,(AFL_ATR,ar)
			.endm
_END_OF_BUF_FLG_OFF:	.macro	ar
			bclr	#END_OF_AFL,(AFL_ATR,ar)
			.endm
_END_OF_BUF_FLG_ON:	.macro	ar
			bset	#END_OF_AFL,(AFL_ATR,ar)
			.endm
_IS_END_OF_BUF:		.macro	ar
			btst	#END_OF_AFL,(AFL_ATR,ar)
			.endm
_IS_EXECD:		.macro	ar
*			btst	#EXEC,(AFL_ATR,ar)
			tst.b	(AFL_ATR,ar)
			.endm
_EXECD_FLG_ON:		.macro	ar
*			bset	#EXEC,(AFL_ATR,ar)
			tas	(AFL_ATR,ar)
			.endm
_IS_READONLY:		.macro	ar
			btst	#READONLY,(AFL_ATR,ar)
			.endm
_READONLY_FLG_ON:	.macro	ar
			bset	#READONLY,(AFL_ATR,ar)
			.endm


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


*************************************************
*		&is-mintarc			*
*************************************************

＆is_mintarc::
		movea.l	(PATH_OPP,a6),a1
		tst.l	d7
		beq	is_mintarc_current
		cmpi.b	#'-',(a0)+
		bne	is_mintarc_current
		cmpi.b	#'o',(a0)
		beq	is_mintarc_opp
		cmpi.b	#'l',(a0)
		beq	is_mintarc_left
		cmpi.b	#'r',(a0)
		beq	is_mintarc_right
		cmpi.b	#'b',(a0)
		beq	is_mintarc_both
		cmpi.b	#'w',(a0)
		beq	is_mintarc_either
is_mintarc_current:
		move.b	(PATH_MARC_FLAG,a6),d0
		bra	is_mintarc_end
is_mintarc_left:
		tst	(PATH_WINRL,a6)
		bra	@f
is_mintarc_right:
		tst	(PATH_WINRL,a1)
@@:		beq	is_mintarc_current
is_mintarc_opp:
		move.b	(PATH_MARC_FLAG,a1),d0
		bra	is_mintarc_end
is_mintarc_both:
		move.b	(PATH_MARC_FLAG,a6),d0
		and.b	(PATH_MARC_FLAG,a1),d0
		bra	is_mintarc_end
is_mintarc_either:
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_MARC_FLAG,a1),d0
is_mintarc_end:
		tst.b	d0
		beq	set_status_0
		bra	set_status_1


*************************************************
*		&uncompress			*
*************************************************

＆uncompress::
		bsr	set_status_0
		jsr	(init_i_c_option)

		lea	(-512,sp),sp
		tst.b	(PATH_MARC_FLAG,a6)
		beq	uncomp_error

		suba.l	a3,a3			;-o path
uncomp_arg_next:
		subq.l	#1,d7
		bcs	uncomp_error		;パターン指定なし

		jsr	(take_i_c_option)
		beq	uncomp_arg_next
		move.b	(a0)+,d0
		beq	uncomp_arg_next
		cmpi.b	#'-',d0
		bne	uncomp_pattern
		cmpi.b	#'o',(a0)+
		bne	uncomp_error		;不正なオプション
uncomp_opt_o:
		lea	(a0),a3			;-o path
		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	uncomp_opt_o
		bra	uncomp_error
@@:		tst.b	(a0)+
		bne	@b
		bra	uncomp_arg_next

uncomp_pattern:
		subq.l	#1,a0			;パターン指定あり

		lea	(a0),a1
		lea	(a0),a2
uncomp_cat_arg_loop:
		move.b	(a1)+,d0
		cmpi.b	#SPACE,d0
		bne	@f
1:		cmp.b	(a1)+,d0
		beq	1b
		subq.l	#1,a0			;連続する空白は一つにする
		moveq	#'|',d0
@@:
		move.b	d0,(a2)+
		bne	uncomp_cat_arg_loop
		move.b	#'|',(-1,a2)
		subq.l	#1,d7
		bcc	uncomp_cat_arg_loop
		clr.b	-(a2)

		move.l	d6,(_ignore_case)
		move.l	sp,d6

		move.l	a0,-(sp)		;pattern
		pea	(512/2)			;size
		move.l	d6,-(sp)		;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bne	uncomp_error		;返値が NULL でなければエラーメッセージ

		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	uncomp_error
		movea.l	d0,a4
		movea.l	(MA_AFL_PTR,a0),a5

		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a0
		bsr	extract_a0_sub		;カレントディレクトリを展開する
		move.l	(ma_list_num,pc),-(sp)

		move.l	a3,d7
		sne	d7			;-o 指定時は展開済みファイルも展開する
		lea	(-92,sp),sp
uncomp_mark_loop:
		_NEXT_BUF a5

		lea	(AFL_DIRNAME,a5),a0
		lea	(sp),a1
		tst.b	(a0)
		beq	@f
		STRCPY	a0,a1,-1
@@:		lea	(AFL_FILENAME,a5),a0
		STRCPY	a0,a1

		lea	(sp),a1
		cmpi.b	#'/',(a1)+
		beq	@f
		subq.l	#1,a1
		cmpi	#'./',(a1)+
		beq	@f
		subq.l	#2,a1
@@:
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a0
uncomp_cmp_loop:
		move.b	(a0)+,d1		;PATH_DIRNAME と同じ部分を
		beq	@f			;AFL_{DIR+FILE}NAME から取り除く
		move.b	(a1)+,d0
		cmp.b	d0,d1
		beq	uncomp_cmp_loop
		cmpi.b	#'/',d0
		bne	uncomp_mark_next
		cmpi.b	#'\',d1
		bne	uncomp_mark_next
		bra	uncomp_cmp_loop
@@:
		pea	(a1)			;残り部分とパターンマッチを行う
		move.l	d6,-(sp)
		jsr	(_fre_match)
		addq.l	#8,sp
		tst.l	d0
		beq	uncomp_mark_next

		moveq	#0,d0
		_IS_DIR a5
		beq	@f
		lea	(a4),a1
		bsr	set_ofb_flag		;展開フラグをセットする
@@:
		tst.b	d7
		bne	1f			;-o 指定時は必ず展開する
		tst.b	(OFB_FILES+FILES_FileName,a4)
		beq	1f
		tst.l	d0
		beq	uncomp_mark_next	;既に展開済み && 下層も展開済み
		bra	2f			;下層のみ展開する
1:
		bset	#0,(OFB_FLAG,a4)
2:
		lea	(sp),a0
		jsr	(to_mintslash)
		_IS_DIR a5
		beq	@f
		bsr	append_extract_suffix
@@:
		moveq	#0,d0
		lea	(uncomp_rts,pc),a1
		bsr	ma_list_append
uncomp_mark_next:
		lea	(OFB_SIZE,a4),a4
		_IS_END_OF_BUF a5
		beq	uncomp_mark_loop

		lea	(92,sp),sp
		move.l	(sp)+,d0		;extract_a0_sub での展開数
		cmp.l	(ma_list_num,pc),d0
		bne	@f			;展開ファイルあり

		bsr	clear_ofb_flag
		bra	uncomp_error		;uncompress_skip
@@:
		move.l	a3,d0
		beq	uncomp_to_minttmp

		bsr	get_virdrv_name
		bmi	uncomp_assign_error

		lea	(a3),a0
		bsr	set_virdrv_a0
		bra	@f
uncomp_to_minttmp:
		bsr	assign_virdrv
@@:		bmi	uncomp_assign_error

		lea	(virdrv_buf,pc),a1
		bsr	local_path_a1

		move.l	a3,-(sp)

		bsr	ma_list_setblock
		moveq	#KQ_LZHS_X,d0
		bsr	call_mintarc_quick_r

		tst.l	(sp)+
		beq	uncomp_to_minttmp2
		bsr	clear_ofb_flag
		bra	@f
uncomp_to_minttmp2:
		bsr	local_path_minttmp
		bsr	dos_files_ofb
		bsr	set_extract_flag
@@:
		bsr	mintarc_chdir_to_arc_dir
		bsr	unassign_virdrv
*uncompress_skip:
		bsr	set_status_1
uncomp_error:
		bsr	ma_list_free
		lea	(512,sp),sp
uncomp_rts:
		rts

uncomp_assign_error:
		bsr	assign_virdrv_error
		bra	uncomp_error


* 展開時サフィックス付加
* in	a0.l	ディレクトリ名

append_extract_suffix:
		PUSH	d0/a0-a1
		STREND	a0
		move.b	(MINTSLASH),(a0)+

		bsr	get_arc_type
		beq	2f
		bmi	1f
		move	(＄tarw),d0
		bra	@f
1:		move	(＄zipw),d0
		bra	@f
2:		move	(＄lzhw),d0
@@:		subq	#1,d0
		bhi	append_extract_suffix_end	;"/"
		bcs	@f				;"/*"
		bsr	append_extract_suffix_sub	;"/*.*"
		move.b	#'.',(a0)+
@@:		bsr	append_extract_suffix_sub
append_extract_suffix_end:
		clr.b	(a0)
		POP	d0/a0-a1
		rts

append_extract_suffix_sub:
		tst	(＄arcw)
		beq	@f
		moveq	#'\',d0
		move.b	d0,(a0)+
		cmpi	#2,(＄unix)
		bcs	@f
		move.b	d0,(a0)+
@@:		move.b	#'*',(a0)+
		rts


* 指定ファイル展開 ---------------------------- *
* in	a0.l	ファイル名
* 現在未使用

.if 0
extract_a0::
		PUSH	d0-d7/a0-a5
		bsr	extract_a0_sub
		move.l	(ma_list_num,pc),d0
		beq	ext_a0_end

		bsr	assign_virdrv
		bmi	ext_a0_error

		lea	(virdrv_buf,pc),a1
		bsr	local_path_a1

		bsr	ma_list_setblock
		moveq	#KQ_LZHS_X,d0
		bsr	call_mintarc_quick_r

		bsr	local_path_minttmp
		bsr	dos_files_ofb
		bsr	set_extract_flag
		bsr	mintarc_chdir_to_arc_dir
		bsr	unassign_virdrv
ext_a0_error:
		bsr	ma_list_free
ext_a0_end:
		POP	d0-d7/a0-a5
		rts
.endif


* 下請け
* in	a0.l	ファイル名
extract_a0_sub:
		PUSH	d0-d7/a0-a5
		tst.b	(a0)
		beq	ext_a0_sub_end

		bsr	get_ma_buf
		movea.l	d0,a5
		move.l	(MA_OFB_PTR,a5),d0
		beq	ext_a0_sub_end
		movea.l	d0,a4
		movea.l	(MA_AFL_PTR,a5),a5

		lea	(a0),a2			;展開するファイル名
		lea	(-80,sp),sp
ext_a0_sub_loop:
		_NEXT_BUF a5

		tst.b	(OFB_FILES+FILES_FileName,a4)
		bne	ext_a0_sub_next		;展開済み

		lea	(AFL_DIRNAME,a5),a0
		lea	(sp),a1
		tst.b	(a0)
		beq	@f
		STRCPY	a0,a1,-1
@@:		lea	(AFL_FILENAME,a5),a0
		STRCPY	a0,a1

		lea	(sp),a1
		cmpi.b	#'/',(a1)+
		beq	@f
		subq.l	#1,a1
		cmpi	#'./',(a1)+
		beq	@f
		subq.l	#2,a1
@@:
		lea	(a2),a0
ext_a0_sub_cmp_loop:
		move.b	(a0)+,d1
		move.b	(a1)+,d0
		beq	@f
		cmp.b	d0,d1
		beq	ext_a0_sub_cmp_loop
		cmpi.b	#'/',d0
		bne	ext_a0_sub_next
		cmpi.b	#'\',d1
		bne	ext_a0_sub_next
		bra	ext_a0_sub_cmp_loop
@@:
		tst.b	d1
		beq	@f			;同一ファイル
		cmpi.b	#'/',d1
		beq	@f			;親ディレクトリ
		cmpi.b	#'\',d1
		bne	ext_a0_sub_next
@@:
		lea	(sp),a0
		jsr	(to_mintslash)
		ori.b	#1<<0,(OFB_FLAG,a4)
		bpl	ext_a0_sub_file

		lea	(sp),a1			;ディレクトリならパスデリミタをつける
@@:		tst.b	(a1)+
		bne	@b
		clr.b	(a1)
		move.b	(MINTSLASH),-(a1)
ext_a0_sub_file:
		moveq	#0,d0
		lea	(ext_a0_sub_rts,pc),a1
		bsr	ma_list_append
ext_a0_sub_next:
		lea	(OFB_SIZE,a4),a4
		_IS_END_OF_BUF a5
		beq	ext_a0_sub_loop

		lea	(80,sp),sp
ext_a0_sub_end:
		POP	d0-d7/a0-a5
ext_a0_sub_rts:	rts


* 書庫名収得 ---------------------------------- *
* in	a6.l	PATH buffer
* out	d0.l	書庫名

get_mintarc_filename_opp::
		moveq	#WIN_RIGHT,d0
		bra	1f
get_mintarc_filename::
		moveq	#WIN_LEFT,d0
1:		cmp	(PATH_WINRL,a6),d0
		beq	@f
		move.l	#ma_buf_r+MA_ARC_FILE,d0
		rts
@@:		move.l	#ma_buf_l+MA_ARC_FILE,d0
		rts


* 書庫展開時サイズ収得 ------------------------ *
* in	a6.l	PATH buffer
* out	d0:d1	バイト数

get_mintarc_orig_size::
		tst	(PATH_WINRL,a6)
		beq	@f
		movem.l	(ma_buf_r+MA_REAL_SIZEh),d0-d1
		rts
@@:		movem.l	(ma_buf_l+MA_REAL_SIZEh),d0-d1
		rts


* 書庫圧縮時サイズ収得 ------------------------ *
* in	a6.l	PATH buffer
* out	d0:d1	バイト数

get_mintarc_comp_size::
		tst	(PATH_WINRL,a6)
		beq	@f
		movem.l	(ma_buf_r+MA_ARC_SIZEh),d0-d1
		rts
@@:		movem.l	(ma_buf_l+MA_ARC_SIZEh),d0-d1
		rts


* 書庫内ファイル数収得 ------------------------ *
* in	a6.l	PATH buffer
* out	d0.l	エントリ数

get_mintarc_file_num::
		moveq	#0,d0
		tst	(PATH_WINRL,a6)
		beq	@f
		move	(ma_buf_r+MA_FILE_NUM),d0
		rts
@@:		move	(ma_buf_l+MA_FILE_NUM),d0
		rts


* 書庫種別収得 -------------------------------- *
* in	a6.l	PATH buffer
* out	ccr	tst.b ($00=lzh $ff=zip $01=tar)

get_arc_type:
		tst	(PATH_WINRL,a6)
		beq	@f
		tst.b	(ma_buf_r+MA_ARC_TYPE)
		rts
@@:		tst.b	(ma_buf_l+MA_ARC_TYPE)
		rts


* テンポラリディレクトリ収得 ------------------ *
* in	a6.l	PATH buffer
* out	d0.l	ディレクトリ名のアドレス

get_mintarc_dir_opp::
		moveq	#WIN_RIGHT,d0
		bra	1f
get_mintarc_dir::
		moveq	#WIN_LEFT,d0
1:		cmp	(PATH_WINRL,a6),d0
		beq	@f
		move.l	#ma_buf_r+MA_TMP_DIR,d0
		rts
@@:		move.l	#ma_buf_l+MA_TMP_DIR,d0
		rts


* 管理構造体収得 ------------------------------ *
* in	a6.l	PATH buffer

* out	d0.l	構造体のディレクトリ
get_ma_buf:
		tst	(PATH_WINRL,a6)
		beq	@f
		move.l	#ma_buf_r,d0
		rts
@@:		move.l	#ma_buf_l,d0
		rts

* out	a0.l	構造体のディレクトリ
get_ma_buf_a0:
		lea	(ma_buf_l),a0
		tst	(PATH_WINRL,a6)
		beq	@f
		lea	(sizeof_MA,a0),a0
@@:		rts


*************************************************
*		&tar-selector			*
*************************************************

＆tar_selector::
		moveq	#1,d5			;not equal
		bra.s	arc_selector


*************************************************
*		&zip-selector			*
*************************************************

＆zip_selector::
		moveq	#-1,d5			;minus
		bra.s	arc_selector


*************************************************
*		&lzh-selector			*
*************************************************

＆lzh_selector::
		moveq	#0,d5			;equal
arc_selector:
		cmpi.b	#$ff,(PATH_MARC_FLAG,a6)
		beq	@f			;これ以上再帰できない
		tst.l	d7
@@:		beq	set_status_0
		bsr	minttmp_check
		bmi	set_status_0

		lea	(Buffer),a2
		move.l	a2,-(sp)
		STRCPY	a0,a2
		jsr	(to_fullpath_file)
		move.l	d0,(sp)+
		bmi	filename_error

		bsr	get_ma_buf
		movea.l	d0,a5
		tst.b	(PATH_MARC_FLAG,a6)
		beq	arc_sel_1st		;初回
*arc_sel_reent:
		bsr	save_ma_buf
		bmi	memory_error

		clr.l	(MA_OFB_PTR,a5)
		clr.l	(MA_NFB_PTR,a5)
		bra	@f
arc_sel_1st:
		bsr	save_ma_curdir
		bsr	get_curdir_buffer
		lea	(cur_dir_buf),a2
		STRCPY	a2,a1
@@:
		bsr	save_path_buf
		bsr	save_file_win

		move.l	#AFL_BUF_SIZE*ARC_FILE_MAX,-(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	memory_error
		move.l	d0,(MA_AFL_PTR,a5)

		bsr	get_mintarc_filename
		movea.l	d0,a2
		move.l	a2,-(sp)
		lea	(Buffer),a1
		STRCPY	a1,a2
		movea.l	(sp)+,a2

		addq.b	#1,(PATH_MARC_FLAG,a6)
		move.b	d5,(MA_ARC_TYPE,a5)
		clr.b	(MA_RELOAD,a5)

		lea	(PATH_DIRNAME,a6),a1
		move	(a2),(a1)+
		move.b	(MINTSLASH),(a1)+
		clr.b	(a1)

		bsr	make_mintarc_dir
		bsr	local_path_minttmp
		jsr	(print_cplp_line)

		bsr	clear_extract_flag
		bsr	analyze_archive
		tst.l	d0
		beq	quit_mintarc_err

		bsr	malloc_path_buf
		bmi	memory_error

		bsr	malloc_ofb_nfb
		bsr	make_ofb_nfb_from_afl
		bsr	set_arc_use_byte

		clr.b	(PATH_CURFILE,a6)
		jsr	(directory_write_routin)
		jsr	(ReverseCursorBar)

		st	(into_marc_flag)
		bra	set_status_1
**		rts


set_status_1:
		moveq	#1,d0
		bra	@f
set_status_0:
		moveq	#0,d0
@@:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts

memory_error:
		moveq	#MES_MARCM,d0
		bra	@f
filename_error:
		moveq	#MES_MARCF,d0		;ファイル操作エラーと同じ
@@:
		bsr	call_print_sub
		bsr	del_mintarc_dir
		bra	quit_mintarc_err2
**		rts


get_curdir_buffer:
		bsr	get_ma_buf
		movea.l	d0,a1
		lea	(MA_CURDIR,a1),a1
		rts


* $MINTTMP チェック --------------------------- *
* out	d0.l	負数ならエラー
*	ccr	<tst.l d0> の結果

minttmp_check:
		PUSH	a0-a1
		lea	(-(90+FILES_SIZE),sp),sp
		lea	(MINT_TEMP),a0
		lea	(sp),a1
		STRCPY	a0,a1
		tst.b	(sp)
		bne	@f
		lea	(sp),a1
		jsr	(get_curdir_a1)		;$MINT_TMP 未定義ならカレントに作る
@@:
		moveq	#90,d0
		add.l	sp,d0			;DOS _FILES バッファ
		lea	(sp),a0
		jsr	(is_exist_dir)
		beq	minttmp_check_end
*minttmp_not_found:
		moveq	#MES_MTMPE,d0
		jsr	(PrintMsg)
		move.l	a0,(sp)
		DOS	_PRINT
		jsr	(PrintCrlf)
		moveq	#-1,d0
minttmp_check_end:
		lea	(90+FILES_SIZE,sp),sp
		POP	a0-a1
		rts


* テンポラリディレクトリ作成/削除 ------------- *

make_mintarc_dir:
		PUSH	d0/d6-d7/a0-a2
		bsr	get_mintarc_dir
		move.l	d0,a1
		st	(MA_DIR_FLAG-MA_TMP_DIR,a1)

		lea	(MINT_TEMP),a0
		lea	(a1),a2
		STRCPY	a0,a2
		tst.b	(a1)
		bne	@f
		jsr	(get_curdir_a1)		;$MINT_TMP 未定義ならカレントに作る
@@:
		lea	(a1),a2
		STREND	a2
		moveq	#-20,d6			;『指定のディレクトリは既に存在する』
		moveq	#0,d7			;現在の番号
make_ma_dir_loop:
		lea	(a2),a0			;サブディレクトリ名を作成
		move.l	d7,d0
		FPACK	__LTOS
		pea	(a1)
		DOS	_MKDIR
		move.b	(MINTSLASH),(a0)+
		clr.b	(a0)
		move.l	d0,(sp)+
		bpl	make_ma_dir_end

		cmp.l	d6,d0
		bne	make_ma_dir_error
		addq	#1,d7
		bcc	make_ma_dir_loop	;既にあれば次の番号で試す
make_ma_dir_error:
		clr.b	(a2)
		clr.b	-(a1)			;サブディレクトリ削除失敗
make_ma_dir_end:
		POP	d0/d6-d7/a0-a2
		rts


del_mintarc_dir:
		PUSH	d0/a1
		bsr	get_mintarc_dir
		move.l	d0,a1
		tst.b	-(a1)			;MA_DIR_FLAG
		beq	del_mintarc_dir_end
@@:
		tst.b	(a1)+
		bne	@b
		clr.b	(-2,a1)			;パスデリミタを削除

		move.l	d0,-(sp)
		DOS	_RMDIR
		addq.l	#4,sp
del_mintarc_dir_end:
		POP	d0/a1
		rts


* ディレクトリバッファ確保 -------------------- *

malloc_path_buf:
		bsr	get_path_buf_size
		move.l	d1,-(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	@f
		move.l	d0,(PATH_BUF,a6)
@@:		rts


setblock_path_buf:
		bsr	get_path_buf_size
		movea.l	(PATH_BUF,a6),a0
		move.l	(end_-MEM_SIZE,a0),d0	;memory block末尾
		sub.l	a0,d0			;block size
		cmp.l	d1,d0
		bcc	@f			;以前の方が大きかったらそのまま

		move.l	d1,-(sp)
		move.l	a0,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bpl	@f			;拡大できた

		bsr	malloc_path_buf		;出来なければ新規に確保
		bmi	@f
		move.l	a0,d0			;元のブロックを解放
		bra	mfree_d0
@@:		rts


* out	d1.l	必要なバッファサイズ
get_path_buf_size:
		bsr	get_mintarc_file_num
		move	d0,d1
		addq	#4,d1
		mulu	#sizeof_DIR,d1
		rts


* 終了処理 ------------------------------------ *

* 実ドライブまで抜ける
quit_mintarc_all::
		PUSH	d0-d7/a0-a6		;再描画不要
		moveq	#-1,d0
		bra.s	@f
* 一階層抜ける
quit_mintarc::
		PUSH	d0-d7/a0-a6
		moveq	#0,d0
@@:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		bsr	quit_mintarc_sub
@@:
		POP	d0-d7/a0-a6
		rts

quit_mintarc_sub:
		move.b	d0,-(sp)		;全終了フラグ
quit_mintarc_loop:
		moveq	#-1,d0			;リロード抑制
		bsr	mintarc_dispose		;消し残しがある場合ここで消す

		moveq	#KQ_LZHS_Q,d0
		bsr	call_mintarc_quick_r

		move.l	(PATH_BUF,a6),d0	;普通の終了
		bsr	mfree_d0
		bsr	mfree_ofb_nfb
		bra	@f
quit_mintarc_err:
		clr.b	-(sp)			;フラグ
@@:
		bsr	get_ma_buf_a0
		move.l	(MA_AFL_PTR,a0),d0
		bsr	mfree_d0

		bsr	restore_path_buf
		bsr	restore_file_win

		subq.b	#1,(PATH_MARC_FLAG,a6)
		beq	quit_mintarc_1st	;最後の階層
*quit_mintarc_reent:
		bsr	get_ma_buf_a0
		movea.l	(MA_PREV_PTR,a0),a0
		pea	(MA_TMP_DIR,a0)		;親 mintarc のディレクトリに移動する
		DOS	_CHDIR
		addq.l	#4,sp
		bsr	del_mintarc_dir

		bsr	restore_ma_buf
		tst.b	(sp)
		bne	quit_mintarc_loop	;mintarc を完全に抜けるまで繰り返す
		bra	@f
quit_mintarc_1st:
		bsr	restore_ma_curdir
		bsr	get_curdir_buffer
		jsr	(set_current_dir)
		bsr	del_mintarc_dir
@@:
		tst.b	(sp)+
		bne	rewrite_skip

		bsr	get_ma_buf_a0
		moveq	#%0000_0001,d0		;カーソル側リロード
		and.b	(MA_RELOAD,a0),d0
		addq.b	#%0000_0100,d0		;カーソル側再表示
		jsr	(print_screen)
quit_mintarc_err2:
		tst	(＄fumd)
		beq	rewrite_skip
		jsr	(＆cursor_down)
rewrite_skip:
		bra	set_status_0
**		rts


* 自動リロード設定 ---------------------------- *

* 最上位の mintarc 実行時の実ディレクトリに
* 対して書き込みを行った場合、mintarc 終了時に
* リロードするようにフラグを立てる.
* 完全ではない.

* in	a0.l	書き込み先パス名
mintarc_set_auto_reload_flag::
		PUSH	d0/a1-a2/a5
		bsr	@f
		bsr	@f
		POP	d0/a1-a2/a5
		rts
@@:
		movea.l	(PATH_OPP,a6),a6
		tst.b	(PATH_MARC_FLAG,a6)
		beq	9f

		bsr	get_ma_buf
		movea.l	d0,a5
		bra	1f
@@:
		movea.l	d0,a5
1:		move.l	(MA_PREV_PTR,a5),d0
		bne	@b

		lea	(MA_PATH_BUF+PATH_DIRNAME,a5),a1
		lea	(a0),a2
@@:
		cmpm.b	(a1)+,(a2)+
		bne	9f
		tst.b	(-1,a1)
		bne	@b

		st	(MA_RELOAD,a5)
9:		rts


* 擬似 DOS _FILES/_NFILES ルーチン ------------ *

		.offset	0
		.ds.b	.sizeof.(d1-d7/a0-a6)	;待避レジスタ
		.ds.l	1			;戻り番地
~files_buffer:	.ds.l	1
~files_file:	.ds.l	1
~files_atr:	.ds	1
		.text

marc_files::
		PUSH	d1-d7/a0-a6
		movea.l	(~files_buffer,sp),a4
		move.b	(~files_atr+1,sp),(FILES_SchAtr,a4)

		bsr	marc_files_getptr
		bra	marc_files_loop

marc_nfiles::
		PUSH	d1-d7/a0-a6
		movea.l	(~files_buffer,sp),a4
		movea.l	(FILES_SchSec,a4),a5	;NOW FILE PTR

marc_files_loop:
		_IS_END_OF_BUF a5
		bne	marc_files_error

		_NEXT_BUF a5
		moveq	#.not.(1<<END_OF_AFL),d0
		and.b	(AFL_ATR,a5),d0
		bne	@f
		moveq	#1<<ARCHIVE,d0
@@:		and.b	(FILES_SchAtr,a4),d0
		beq	marc_files_loop

		lea	(AFL_DIRNAME,a5),a1
		cmpi.b	#'/',(a1)+
		beq	@f
		subq.l	#1,a1
		cmpi	#'./',(a1)+
		beq	@f
		subq.l	#2,a1
@@:
		lea	(PATH_DIRNAME+3,a6),a2
marc_files_dircmp_loop:
		move.b	(a1)+,d0
		move.b	(a2)+,d1
		cmp.b	d0,d1
		beq	@f
		cmpi.b	#'/',d0			;'/' は下位バイトにならないから
		bne	marc_files_loop		;マルチバイト文字の考慮は不要
		cmpi.b	#'\',d1
		bne	marc_files_loop
*		bra	marc_files_dircmp_loop
@@:
		tst.b	d0
		bne	marc_files_dircmp_loop
marc_files_set:
		move.l	a5,(FILES_SchSec,a4)

		moveq	#.not.(1<<END_OF_AFL+1<<ARCHIVE),d0
		and.b	(AFL_ATR,a5),d0
		btst	#DIRECTORY,d0
		bne	@f
		bset	#ARCHIVE,d0
@@:		move.b	d0,(FILES_FileAtr,a4)

		move.l	(AFL_TIME_DATE,a5),(FILES_Time,a4)
		move.l	(AFL_SIZE,a5),(FILES_FileSize,a4)

		lea	(AFL_FILENAME,a5),a1
		lea	(FILES_FileName,a4),a2
		STRCPY	a1,a2

		moveq	#0,d0
@@:		POP	d1-d7/a0-a6
		rts
marc_files_error:
		moveq	#-1,d0
		bra	@b

marc_files_getptr:
		bsr	get_ma_buf
		movea.l	d0,a5
		movea.l	(MA_AFL_PTR,a5),a5
		rts


* フルパスのファイル名指定版(ワイルドカード不可)
marc_files2::
		PUSH	d1-d7/a0-a6
		movea.l	(~files_buffer,sp),a4
		move.b	(~files_atr+1,sp),(FILES_SchAtr,a4)

		movea.l	(~files_file,sp),a0
**		addq.l	#3,a0			;なくても平気
marc_files2_fn_slash:
		move.l	a0,d1
marc_files2_fn_loop:
		move.b	(a0)+,d0
		beq	marc_files2_fn_end
		cmpi.b	#'/',d0
		beq	marc_files2_fn_slash
		cmpi.b	#'\',d0
		beq	marc_files2_fn_slash
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	marc_files2_fn_loop
		tst.b	(a0)+
		bne	marc_files2_fn_loop
marc_files2_fn_end:
		movea.l	d1,a3			;ファイル名

		bsr	marc_files_getptr
marc_files2_loop:
		_IS_END_OF_BUF a5
		bne	marc_files_error

		_NEXT_BUF a5
		moveq	#.not.(1<<END_OF_AFL),d0
		and.b	(AFL_ATR,a5),d0
		bne	@f
		moveq	#1<<ARCHIVE,d0
@@:		and.b	(FILES_SchAtr,a4),d0
		beq	marc_files2_loop

		lea	(AFL_DIRNAME,a5),a1
		cmpi.b	#'/',(a1)+
		beq	@f
		subq.l	#1,a1
		cmpi	#'./',(a1)+
		beq	@f
		subq.l	#2,a1
@@:
		movea.l	(~files_file,sp),a2
		addq.l	#3,a2
marc_files2_dircmp_loop:
		move.b	(a1)+,d0		;ディレクトリ名比較
		beq	@f
		move.b	(a2)+,d1
		cmp.b	d0,d1
		beq	marc_files2_dircmp_loop
		cmpi.b	#'/',d0			;'/' は下位バイトにならないから
		bne	marc_files2_loop	;マルチバイト文字の考慮は不要
		cmpi.b	#'\',d1
		bne	marc_files2_loop
		bra	marc_files2_dircmp_loop
@@:
		cmpa.l	a2,a3
		bne	marc_files2_loop	;ディレクトリが違う

		lea	(AFL_FILENAME,a5),a1
@@:
		cmpm.b	(a1)+,(a2)+		;ファイル名比較
		bne	marc_files2_loop
		tst.b	(-1,a1)
		bne	@b
		bra	marc_files_set


* 仮想ドライブ関係 ---------------------------- *

* 仮想ドライブ解除
unassign_virdrv::
		bsr	unset_virdrv
		bmi	unassign_virdrv_error
		rts

* 仮想ドライブ設定
assign_virdrv:
		bsr	get_virdrv_name
		bmi	assign_virdrv_error
		bsr	set_virdrv_minttmp
		bmi	assign_virdrv_error
		rts

* 仮想ドライブ設定エラー
assign_virdrv_error:
		moveq	#MES_MARCS,d0
		bsr	call_print_sub
		moveq	#-1,d0
		rts

* 仮想ドライブ解除エラー
unassign_virdrv_error:
		lea	(-256,sp),sp
		GETMES	MES_MARCR
		movea.l	d0,a0
		lea	(sp),a1
		STRCPY	a0,a1,-1
		lea	(unassign_error_drive_mes,pc),a0
		move	(virdrv_buf,pc),(2,a0)
		STRCPY	a0,a1
		lea	(sp),a0
		bsr	call_print_sub2
		lea	(256,sp),sp
		moveq	#-1,d0
		rts

unassign_error_drive_mes:
		.dc.b	' (A:) ',0
		.even


* 未使用ドライブを得る ------------------------ *
* out	d0.l	エラーコード
*	ccr	<tst.l d0> の結果
*	virdrv_buf	仮想ドライブ名(A:\)

get_virdrv_name:
		PUSH	d7/a0
		lea	(-128,sp),sp
		lea	(virdrv_buf,pc),a0
		move.l	#'Z:'<<16,(a0)
		moveq	#'Z'-'A',d7
get_virdrv_name_loop:
		pea	(sp)			;バッファ
		pea	(a0)			;ドライブ名
		clr	-(sp)			;ASSIGN_GET
		DOS	_ASSIGN
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		beq	@f			;未使用のドライブを見つけた
		subq.b	#1,(a0)
		dbra	d7,get_virdrv_name_loop
		moveq	#-1,d0
@@:
		lea	(128,sp),sp
		move.b	#'\',(2,a0)
		POP	d7/a0
		tst.l	d0
		rts


* 仮想ドライブを設定する ---------------------- *
* out	d0.l	エラーコード
*	ccr	<tst.l d0> の結果

set_virdrv_minttmp:
		move.l	a0,-(sp)
		bsr	get_mintarc_dir
		movea.l	d0,a0
		bsr	set_virdrv_a0
		movea.l	(sp)+,a0
		rts


* 仮想ドライブ設定下請け ---------------------- *
* in	a0.l	パス名
* out	d0.l	エラーコード
*	ccr	<tst.l d0> の結果

set_virdrv_a0:
		bsr	set_unset_virdrv
*set_virdrv_sub:
		move	#VIRDRV,-(sp)
		pea	(a0)
		pea	(a1)
		move	#ASSIGN_SET,-(sp)
		DOS	_ASSIGN
		lea	(12,sp),sp
		rts


* 仮想ドライブを解除する ---------------------- *
* out	d0.l	エラーコード
*	ccr	<tst.l d0> の結果

unset_virdrv:
		bsr	set_unset_virdrv
*unset_virdrv_sub:
		pea	(a1)
		move	#ASSIGN_UNSET,-(sp)
		DOS	_ASSIGN
		addq.l	#6,sp
		rts


* 仮想ドライブ設定/解除下請け ----------------- *
* in	virdrv_buf	ドライブ名(A:\)
* out	d0.l	エラーコード
*	ccr	<tst.l d0> の結果

set_unset_virdrv:
		move.l	(sp)+,d0		;処理アドレス
		PUSH	a1-a2
		lea	(virdrv_buf,pc),a1
		movea.l	d0,a2
		clr	(2,a1)
		jsr	(a2)
		move	#'\'<<8,(2,a1)
		POP	a1-a2
		tst.l	d0
		rts


virdrv_buf:	.ds.b	.sizeof.('A:\')+1	;仮想ドライブ名
		.even


* パス管理バッファ保存/復帰 ------------------- *

save_path_buf:
		PUSH	d0/a0/a6
		bsr	get_ma_buf_a0
		lea	(MA_PATH_BUF,a0),a0
		moveq	#sizeof_PATHBUF/4-1,d0
@@:
		move.l	(a6)+,(a0)+
		dbra	d0,@b
		POP	d0/a0/a6
		rts

restore_path_buf:
		PUSH	d0/a0-a2/a5-a6
		bsr	get_ma_buf_a0
		lea	(MA_PATH_BUF,a0),a0

		lea	(PATH_DIRNAME,a0),a2
		lea	(PATH_DIRNAME,a6),a5
		moveq	#64/4-1,d0
@@:		move.l	(a2)+,(a5)+
		dbra	d0,@b

		move	(PATH_FILENUM,a0),(PATH_FILENUM,a6)
		move	(PATH_PAGETOP,a0),(PATH_PAGETOP,a6)
		move.b	(PATH_DOTDOT,a0),(PATH_DOTDOT,a6)
		move.b	(PATH_SORTREV,a0),(PATH_SORTREV,a6)
		move.b	(PATH_SORT,a0),(PATH_SORT,a6)

		move.l	(PATH_CLUSTER,a0),(PATH_CLUSTER,a6)

		lea	(PATH_USE_FRE,a0),a2
		lea	(PATH_USE_FRE,a6),a5
		moveq	#(PATH_USE_FRE_END-PATH_USE_FRE)-1,d0
@@:		move.b	(a2)+,(a5)+
		dbra	d0,@b

		lea	(PATH_CURFILE,a0),a2
		lea	(PATH_CURFILE,a6),a5
		moveq	#24/4-1,d0
@@:		move.l	(a2)+,(a5)+
		dbra	d0,@b

		move.l	(PATH_OPP,a0),(PATH_OPP,a6)
		move.l	(PATH_BUF,a0),(PATH_BUF,a6)

		lea	(PATH_DIRNAME,a6),a1
		bsr	local_path_a1
		POP	d0/a0-a2/a5-a6
		rts


* ウィンドウ管理構造体保存/復帰 --------------- *

save_file_win:
		bsr	save_file_win_sub
.if sizeof_WIN_BUF.eq.(8+2)
		move.l	(WIND_CUR_X,a1),(a2)+
		move.l	(WIND_CUR_ADR,a1),(a2)+
		move	(＄dirh),(a2)+
.else
		moveq	#sizeof_WIND/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b
.endif
		rts

restore_file_win:
		bsr	save_file_win_sub
.if sizeof_WIN_BUF.eq.(8+2)
		move.l	(a2)+,(WIND_CUR_X,a1)
		move.l	(a2)+,(WIND_CUR_ADR,a1)
		move	(a2)+,d0
		cmp	(＄dirh),d0
		beq	@f
		jsr	(winsize_cursor_revise)	;&toggle-window-size 対策
@@:
.else
		moveq	#sizeof_WIND/4-1,d0
@@:		move.l	(a2)+,(a1)+
		dbra	d0,@b
.endif
		rts

save_file_win_sub:
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetPtr)
		movea.l	d0,a1

		bsr	get_ma_buf
		movea.l	d0,a2
		lea	(MA_WIN_BUF,a2),a2
		rts


* mintarc バッファ保存/復帰 ------------------- *

* 各待避バッファには確保したレベルのデータを、
* その子供の mintarc への移行時に待避する.
* 簡単な流れ
* mintarc 一回目
*	アーカイブ解析
*	バッファ確保->確保アドレス設定
* mintarc 二回目
*	ワーク待避->待避アドレス設定
*	アーカイブ解析
*	バッファ確保->確保アドレス設定
* mintarc 終了
*	待避アドレス->ワーク復帰
*	バッファ解放
* mintarc 終了
*	バッファ解放

* out	ccr	N=1:メモリ確保エラー
save_ma_buf:
		pea	(sizeof_MA).w
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	9f

		bsr	get_ma_buf_a0
		move	#sizeof_MA/2-1,d1
		move.l	d0,-(sp)
		movea.l	d0,a1
@@:
		move	(a0)+,(a1)+
		dbra	d1,@b			;↓待避してからアドレス記録
		move.l	(sp)+,(MA_PREV_PTR-sizeof_MA,a0)
9:		rts

restore_ma_buf:
		bsr	get_ma_buf_a0
		move	#sizeof_MA/2-1,d1
		movea.l	(MA_PREV_PTR,a0),a1
		pea	(a1)
@@:
		move	(a1)+,(a0)+
		dbra	d1,@b
		DOS	_MFREE
		addq.l	#4,sp
		rts


* $MINTTMP カレントディレクトリ制御 ----------- *

* テンポラリディレクトリを作成するドライブの
* カレントディレクトリを保存する.
save_ma_curdir:
		PUSH	d0/a0
		moveq	#$1f,d0
		and.b	(MINT_TEMP),d0
		bne	@f			;ドライブ番号(1～26)
		DOS	_CURDRV
		addq	#1,d0
@@:
		bsr	get_ma_cudir
		move.l	#('A'-1)<<24+':\'<<8,(a0)
		add.b	d0,(a0)

		pea	(3,a0)
		move	d0,-(sp)
		DOS	_CURDIR
		addq.l	#6,sp
		POP	d0/a0
@@:		rts

restore_minttmp_curdir::
		tst.b	(PATH_MARC_FLAG,a6)
		beq.s	@b

* テンポラリディレクトリを作成するドライブの
* カレントディレクトリを元に戻す.
restore_ma_curdir:
		PUSH	d0/a0
		bsr	get_ma_cudir
		pea	(a0)
		DOS	_CHDIR
		addq.l	#4,sp
		POP	d0/a0
		rts

get_ma_cudir:
		lea	(ma_curdir_l),a0
		tst	(PATH_WINRL,a6)
		beq	@f
		lea	(ma_curdir_r-ma_curdir_l,a0),a0
@@:		rts


* 展開ディレクトリマーク -------------------- *
* new_files_buffer からディレクトリを検索し、
* 展開されていた場合はフラグをセットする.

mark_nfb_dir:
		PUSH	d0/a0
		bsr	get_ma_buf_a0
		move.l	(MA_NFB_PTR,a0),d0
		beq	mark_nfb_dir_end
		movea.l	d0,a0
mark_nfb_dir_loop:
		tst.b	(NFB_FLAG,a0)
		beq	@f			;ファイル
		st	(NFB_FILES+FILES_FileName,a0)
@@:
		lea	(NFB_SIZE,a0),a0
		cmpi	#END_OF_NFB,(NFB_FLAG,a0)
		bne	mark_nfb_dir_loop
mark_nfb_dir_end:
		POP	d0/a0
		rts


* 展開ファイルマーク -------------------------- *
* 展開済みのファイルを削除し、フラグをクリアする.

delete_nfb_file:
		PUSH	d0/a0-a1
		bsr	get_ma_buf_a0
		move.l	(MA_NFB_PTR,a0),d0
		beq	del_nfb_file_end

		movea.l	d0,a0
del_nfb_file_loop:
		tst.b	(NFB_FLAG,a0)
		bne	del_nfb_file_next	;ディレクトリ
		tst.b	(NFB_FILES+FILES_FileName,a0)
		beq	del_nfb_file_next	;展開していない

		lea	(NFB_FULLPATH,a0),a1
		cmpi.b	#'/',(a1)
		bne	@f
		addq.l	#1,a1			;skip root '/'
@@:
		move	#1<<ARCHIVE,-(sp)
		pea	(a1)
		DOS	_DELETE
		tst.l	d0
		bpl	@f
		DOS	_CHMOD
		DOS	_DELETE
@@:		addq.l	#6,sp

		clr.b	(NFB_FILES+FILES_FileName,a0)
del_nfb_file_next:
		lea	(NFB_SIZE,a0),a0
		cmpi	#END_OF_NFB,(NFB_FLAG,a0)
		bne	del_nfb_file_loop
del_nfb_file_end:
		POP	d0/a0-a1
		rts


* 展開ディレクトリマーク ---------------------- *
* 展開済みのディレクトリを削除し、フラグをクリアする.

delete_nfb_dir:
		PUSH	d0-d2/d5/a0-a4
		bsr	get_ma_buf_a0
		move.l	(MA_NFB_PTR,a0),d0
		beq	@f

		movea.l	d0,a0
		moveq	#END_OF_NFB,d1
		moveq	#'/',d5
		bsr	del_nfb_dir_sub
@@:
		POP	d0-d2/d5/a0-a4
		rts

* in	a0.l	MA_NFB_PTR
del_nfb_dir_sub:
del_nfb_dir_loop:
		tst.b	(NFB_FLAG,a0)
		beq	del_nfb_dir_next	;ファイル
		tst.b	(NFB_FILES+FILES_FileName,a0)
		beq	del_nfb_dir_next	;展開していない

		bsr	search_nfb_subdir
		bne	@f

		move.l	a0,-(sp)		;サブディレクトリを再帰する
		movea.l	a1,a0
		bsr	del_nfb_dir_sub
		movea.l	(sp)+,a0
@@:
		lea	(NFB_FULLPATH,a0),a1
		cmp.b	(a1),d5
		bne	@f
		addq.l	#1,a1			;skip root '/'
@@:
		move.l	a1,-(sp)
		DOS	_RMDIR
		addq.l	#4,sp
		clr.b	(NFB_FILES+FILES_FileName,a0)
del_nfb_dir_next:
		lea	(NFB_SIZE,a0),a0
		cmp	(NFB_FLAG,a0),d1
		bne	del_nfb_dir_loop
		rts


* in	a0.l	ディレクトリ名
* out	a1.l	サブディレクトリ名
*	ccr	Z=1:検索成功 Z=0:検索失敗

search_nfb_subdir:
		move.l	a0,-(sp)
		lea	(a0),a3
		bra	sch_nfb_subdir_next
sch_nfb_subdir_loop:
		tst.b	(NFB_FLAG,a3)
		beq	sch_nfb_subdir_next	;ファイル
		tst.b	(NFB_FILES+FILES_FileName,a3)
		beq	sch_nfb_subdir_next	;展開していない

		movea.l	a0,a2
		movea.l	a3,a4
@@:
		move.b	(a2)+,d0
		beq	sch_nfb_subdir_found
		move.b	(a4)+,d2
		cmp.b	d0,d2
		beq	@b
sch_nfb_subdir_next:
		lea	(NFB_SIZE,a3),a3
		cmp	(NFB_FLAG,a3),d1
		bne	sch_nfb_subdir_loop

		moveq	#-1,d0
sch_nfb_subdir_found:
		movea.l	a3,a1
		movea.l	(sp)+,a0
		rts


* 更新ファイルチェック ------------------------ *
* out	d0.l	更新されたファイル数
*	ccr	<tst.l d0> の結果
* old/new_files_buffer を比較し、更新されていなければ
* フラグをクリアする. ディレクトリは比較しない.
* 書庫への書き込み確認時に表示する為、更新された
* ファイル名を ma_list に追加する.

compare_ofb_nfb:
		PUSH	d0-d1/a0-a4
		moveq	#-1,d1
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	cmp_ofb_nfb_end

		movea.l	d0,a1
		movea.l	(MA_NFB_PTR,a0),a2
cmp_ofb_nfb_loop:
		tst.b	(OFB_FILES+FILES_FileName,a1)
		beq	cmp_ofb_nfb_clr		;_FILES していない＝展開していない
		tst.b	(OFB_FLAG,a1)
		bmi	cmp_ofb_nfb_clr		;ディレクトリは比較しない

		lea	(OFB_FILES,a1),a3
		lea	(NFB_FILES,a2),a4
		moveq	#FILES_SIZE/2-1,d0
@@:		cmpm	(a3)+,(a4)+
		dbne	d0,@b
		beq	cmp_ofb_nfb_clr		;更新されていない

		move.l	a1,-(sp)		;更新されていた
		moveq	#0,d0
		lea	(NFB_FULLPATH,a2),a0	;あまり意味はない
		lea	(cmp_ofb_nfb_rts,pc),a1
		bsr	ma_list_append
		movea.l	(sp)+,a1
		bra	cmp_ofb_nfb_next
cmp_ofb_nfb_clr:
		clr.b	(OFB_FILES+FILES_FileName,a1)
cmp_ofb_nfb_next:
		lea	(OFB_SIZE,a1),a1
		lea	(NFB_SIZE,a2),a2
		cmp	(OFB_FLAG,a1),d1
		bne	cmp_ofb_nfb_loop
cmp_ofb_nfb_end:
		move.l	(ma_list_num,pc),d0
		POP	d0-d1/a0-a4
cmp_ofb_nfb_rts:
		rts


* ファイル展開要求フラグ初期化 ---------------- *
* old_files_buffer のファイル展開要求フラグをクリアする.

clear_ofb_flag:
		PUSH	d0/d6-d7/a0
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	clr_ofb_flag_end

		movea.l	d0,a0
		moveq	#.not.(1<<0),d0		;展開要求フラグ
		moveq	#OFB_SIZE,d6
		moveq	#END_OF_OFB,d7
clr_ofb_flag_loop:
		and.b	d0,(OFB_FLAG,a0)
		adda.l	d6,a0
		cmp	(OFB_FLAG,a0),d7
		bne	clr_ofb_flag_loop
clr_ofb_flag_end:
		POP	d0/d6-d7/a0
		rts


* 終了前ファイル情報収得 ---------------------- *
* new_files_buffer に DOS _FILES でファイル情報
* を収得する.

dos_files_nfb:
		PUSH	d0/a1-a2
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	dos_files_nfb_end

		movea.l	d0,a1
		movea.l	(MA_NFB_PTR,a0),a2
dos_files_nfb_loop:
		tst.b	(OFB_FILES+FILES_FileName,a1)
		beq	dos_files_nfb_next	;_FILES していない＝展開していない
		tst.b	(OFB_FLAG,a1)
		beq	@f
		st	(OFB_FILES+FILES_FileName,a2)
		bra	dos_files_nfb_next	;ディレクトリはフラグだけ立てておく
@@:
		move	#$00ff,-(sp)
		pea	(NFB_FULLPATH,a1)
		cmpi.b	#'/',(NFB_FULLPATH,a1)
		bne	@f
		addq.l	#1,(sp)			;skip root '/'
@@:
		pea	(NFB_FILES,a2)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bpl	dos_files_nfb_next

		clr.b	(OFB_FILES+FILES_FileName,a1)
		clr.b	(NFB_FILES+FILES_FileName,a2)
dos_files_nfb_next:
		lea	(OFB_SIZE,a1),a1
		lea	(NFB_SIZE,a2),a2
		cmpi	#END_OF_OFB,(OFB_FLAG,a1)
		bne	dos_files_nfb_loop
dos_files_nfb_end:
		POP	d0/a1-a2
		rts


* 展開後ファイル情報収得 ---------------------- *
* old_files_buffer に DOS _FILES でファイル情報
* を収得する.

dos_files_ofb:
		move.l	a0,-(sp)
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	dos_files_ofb_end

		movea.l	d0,a0
dos_files_ofb_loop:
		bclr	#0,(OFB_FLAG,a0)
		beq	dos_files_ofb_next

		move	#$00ff,-(sp)
		pea	(OFB_FULLPATH,a0)
		cmpi.b	#'/',(OFB_FULLPATH,a0)
		bne	@f
		addq.l	#1,(sp)		;skip root '/'
@@:
		pea	(OFB_FILES,a0)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bpl	dos_files_ofb_next

		clr.b	(OFB_FILES+FILES_FileName,a0)
dos_files_ofb_next:
		lea	(OFB_SIZE,a0),a0
		cmpi	#END_OF_OFB,(OFB_FLAG,a0)
		bne	dos_files_ofb_loop
dos_files_ofb_end:
		movea.l	(sp)+,a0
		rts


* ディレクトリ内ファイル検索 ------------------ *
* 指定ディレクトリ内にあるエントリを検索する.
* in	a1.l	ディレクトリ名
*	a2.l	old_files_buffer
* out	a2.l	old_files_buffer 内の検索したエントリ
*	ccr	Z=1:検索失敗
*		Z=0:検索成功(ファイル)
*		N=1:検索成功(ディレクトリ)

search_ofb_entry:
		PUSH	d0-d1/a0/a3
sch_ofb_ent_loop:
		lea	(OFB_FULLPATH,a1),a0
		lea	(OFB_FULLPATH,a2),a3
@@:
		move.b	(a0)+,d0
		beq	sch_ofb_ent_found
		cmp.b	(a3)+,d0
		beq	@b
sch_ofb_ent_next:
		lea	(OFB_SIZE,a2),a2	;ファイル名が違う
		cmpi	#END_OF_OFB,(OFB_FLAG,a2)
		bne	sch_ofb_ent_loop

		moveq	#0,d0			;検索失敗
		bra	sch_ofb_ent_end
sch_ofb_ent_found:
		cmpi.b	#'/',(a3)
		bne	sch_ofb_ent_next

		tst.b	(OFB_FLAG,a2)		;見つかった
		beq	@f
		moveq	#-1,d0			;ディレクトリ
		bra	sch_ofb_ent_end
@@:
		moveq	#1,d0			;ファイル
sch_ofb_ent_end:
		POP	d0-d1/a0/a3
		rts


* 再帰的に展開フラグをセットする -------------- *
* in	d7.b	$00=展開モード(展開済みファイルを無視する)
*		$ff=削除モード(展開済みでもフラグをセット)
*	a1.l	old_files_buffer
* out	d0.l	展開ファイル数
*	ccr	<tst.l d0> の結果

set_ofb_flag:
		PUSH	d4/a0/a2
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	set_ofb_flag_end

		movea.l	d0,a2
		moveq	#0,d4
set_ofb_flag_loop:
		bsr	search_ofb_entry
		beq	set_ofb_flag_end2
		bpl	@f

		move.l	a1,-(sp)
		movea.l	a2,a1
		bsr	set_ofb_flag		;展開フラグをセットする
		movea.l	(sp)+,a1
		add.l	d0,d4
**		bra	set_ofb_flag_next
		bra	set_ofb_flag_set	;ディレクトリも展開する
@@:
		tst.b	d7
		bne	set_ofb_flag_set
		tst.b	(OFB_FILES+FILES_FileName,a2)
		bne	set_ofb_flag_next	;展開済みなら無視して良い
set_ofb_flag_set:
		addq.l	#1,d4			;要展開ファイル数
		bset	#0,(OFB_FLAG,a2)
set_ofb_flag_next:
		lea	(OFB_SIZE,a2),a2
		cmpi	#END_OF_OFB,(OFB_FLAG,a2)
		bne	set_ofb_flag_loop
set_ofb_flag_end2:
		move.l	d4,d0
set_ofb_flag_end:
		POP	d4/a0/a2
		rts


* ファイルエントリ検索 ------------------------ *
* in	a4.l	検索するファイル
* out	a1.l	発見したファイル(old_files_buffer 内)
*	ccr	Z=0:検索成功 Z=1:検索失敗

search_ofb_file:
		PUSH	d0-d2/d6-d7/a0/a2-a5
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	sch_ofb_file_error

		movea.l	d0,a1
		moveq	#-1,d1
		moveq	#0,d2
		moveq	#SPACE,d6
		moveq	#'\',d7
		addq.l	#DIR_NAME,a4
		lea	(ctypetable),a5
sch_ofb_file_loop:
		lea	(PATH_DIRNAME+.sizeof.('A:/'),a6),a2
		lea	(OFB_FULLPATH,a1),a0
		cmpi.b	#'/',(a0)+
		beq	@f
		subq.l	#1,a0
		move.b	(a0)+,-(sp)
		move	(sp)+,d0
		move.b	(a0)+,d0
		cmpi	#'./',d0
		beq	@f
		subq.l	#2,a0
@@:
sch_ofb_file_loop2:
		move.b	(a2)+,d2
		beq	sch_ofb_file_dirend	;ディレクトリ終了
		cmp.b	d7,d2
		bne	@f
		moveq	#'/',d2
@@:
		move.b	(a0)+,d0
		cmp.b	d0,d2
		bne	sch_ofb_file_next
		tst.b	(a5,d2.w)
		bpl	sch_ofb_file_loop2
		cmpm.b	(a0)+,(a2)+		;二バイト文字
		beq	sch_ofb_file_loop2
sch_ofb_file_next:
		lea	(OFB_SIZE,a1),a1
		cmpi	#END_OF_OFB,(OFB_FLAG,a1)
		bne	sch_ofb_file_loop
sch_ofb_file_error:
		moveq	#MES_MA_E0,d0
		jsr	(PrintMsgCrlf)
		moveq	#0,d0
		bra	sch_ofb_file_end

sch_ofb_file_dirend:
		movea.l	a4,a3
@@:
		move.b	(a3)+,d2
		cmp.b	d6,d2
		beq	@b			;空白は無視する
		cmp.b	(a0)+,d2
		bne	sch_ofb_file_next
		tst.b	d2
		bne	@b

		moveq	#1,d0
sch_ofb_file_end:
		POP	d0-d2/d6-d7/a0/a2-a5
		rts


* ファイルリスト作成 -------------------------- *
* AFL から OFB/NFB を作成する

make_ofb_nfb_from_afl:
		PUSH	a0-a5
		bsr	get_ma_buf_a0
		move.l	(MA_OFB_PTR,a0),d0
		beq	make_onfb_error

		movea.l	d0,a2
		movea.l	(MA_NFB_PTR,a0),a4
		movea.l	(MA_AFL_PTR,a0),a5	;書庫解析で作ったリスト
		moveq	#0,d7
make_onfb_loop:
		movea.l	a2,a1
		movea.l	a4,a3
		_IS_END_OF_BUF a5
		bne	make_onfb_end

		PUSH	a1/a3
		lea	(OFB_FILES,a1),a1
		lea	(NFB_FILES,a3),a3
		moveq	#FILES_SIZE/2-1,d0
@@:
		move	d7,(a1)+		;バッファクリア
		move	d7,(a3)+
		dbra	d0,@b
		POP	a1/a3

		_NEXT_BUF a5
		lea	(AFL_DIRNAME,a5),a0
		moveq	#1<<DIRECTORY,d0
		and.b	(AFL_ATR,a5),d0
		lsl.b	#7-DIRECTORY,d0		;$80 / $00
@@:
		move.b	d0,(a1)+		;ディレクトリ名
		move.b	d0,(a3)+
		move.b	(a0)+,d0
		bne	@b
		lea	(AFL_FILENAME,a5),a0
@@:
		move.b	(a0)+,d0		;ファイル名
		move.b	d0,(a1)+
		move.b	d0,(a3)+
		bne	@b

		lea	(OFB_SIZE,a2),a2
		lea	(NFB_SIZE,a4),a4
		bra	make_onfb_loop
make_onfb_end:
		moveq	#END_OF_OFB,d0
		move	d0,(OFB_FLAG,a2)
		move	d0,(NFB_FLAG,a4)
make_onfb_error:
		POP	a0-a5
		rts


* OFB/NFB バッファ確保 ------------------------ *

malloc_ofb_nfb:
		bsr	get_ma_buf_a0
		moveq	#OFB_SIZE,d4
		mulu	(MA_FILE_NUM,a0),d4

		lea	(MA_OFB_PTR,a0),a1
		bsr	malloc_onfb_sub
		lea	(MA_NFB_PTR,a0),a1
		bra	malloc_onfb_sub
**		rts

malloc_onfb_sub:
		moveq	#MES_MA_E1,d0
		tst.l	(a1)
		bgt	malloc_onfb_sub_error	;確保済み(念の為…)
		tst.l	d4
		beq	malloc_onfb_sub_end	;確保不要

		move.l	d4,-(sp)
		moveq	#4+OFB_SIZE,d0		;保険
		add.l	d0,(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		move.l	d0,(a1)
		bpl	malloc_onfb_sub_end

		moveq	#MES_MARCB,d0		;メモリ不足
malloc_onfb_sub_error:
		jmp	(PrintMsgCrlf)
malloc_onfb_sub_end:
		rts


* OFB/NFB バッファ解放 ------------------------ *

mfree_ofb_nfb:
		bsr	get_ma_buf_a0
		lea	(MA_OFB_PTR,a0),a1
		bsr	mfree_onfb_sub
		lea	(MA_NFB_PTR,a0),a1
		bra	mfree_onfb_sub
**		rts

mfree_onfb_sub:
		move.l	(a1),-(sp)
		ble	@f
		clr.l	(a1)
		DOS	_MFREE
@@:		addq.l	#4,sp
		rts


* ファイル展開 -------------------------------- *
* in	d0.b	フラグ
*		bit0=1:$C 展開
*		bit1=1:$F 〃
*		bit2=1:$M 〃

mintarc_extract::
		PUSH	d0-d7/a0-a6
		move.b	d0,d7
**		beq	ma_ext_end

		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a0
		bsr	extract_a0_sub		;カレントディレクトリを展開する
		lsr.b	#1,d7
		beq	ma_ext_mark_skip

		lsr.b	#1,d7
		bcc	ma_ext_file_skip

		jsr	(search_cursor_file)
		jsr	(is_parent_directory_a4)
		bne	ma_ext_file_skip	;".." は展開しない

		bsr	ma_ext_sub
ma_ext_file_skip:
		lsr.b	#1,d7
		bcc	ma_ext_mark_skip

		movea.l	(PATH_BUF,a6),a4
		bra	@f
ma_ext_mark_loop:
		bsr	ma_ext_sub
		lea	(sizeof_DIR,a4),a4
@@:
		jsr	(search_mark_file)
		beq	ma_ext_mark_loop
ma_ext_mark_skip:
		move.l	(ma_list_num,pc),d0
		beq	ma_ext_end		;展開すべきファイルがない

		bsr	assign_virdrv
		bmi	ma_ext_error

		lea	(-64,sp),sp
		lea	(cur_dir_buf),a1
		lea	(sp),a2
		STRCPY	a1,a2

		lea	(virdrv_buf,pc),a1	;MINTTEMPのsubstドライブ
		bsr	local_path_a1

		bsr	ma_list_setblock
		moveq	#KQ_LZHS_X,d0
		bsr	call_mintarc_quick_r

		bsr	local_path_minttmp
		bsr	dos_files_ofb
		bsr	set_extract_flag
		bsr	unassign_virdrv
		lea	(sp),a1
		bsr	local_path_a1
		lea	(64,sp),sp
ma_ext_error:
		bsr	ma_list_free
ma_ext_end:
		POP	d0-d7/a0-a6
		rts


ma_ext_sub:
		bsr	search_ofb_file
		beq	ma_ext_sub_end

		moveq	#0,d0
		move.b	(OFB_FLAG,a1),d1
		bpl	@f
		bsr	set_ofb_flag		;展開フラグをセットする
@@:
		tst.b	(OFB_FILES+FILES_FileName,a1)
		beq	1f
		tst.l	d0
		beq	ma_ext_sub_end		;既に展開済み && 下層も展開済み
		bra	@f			;下層のみ展開する
1:
		bset	#0,(OFB_FLAG,a1)
@@:
		lea	(-92,sp),sp
		lea	(OFB_FULLPATH,a1),a0
		lea	(sp),a1
		STRCPY	a0,a1
		lea	(sp),a0
		jsr	(to_mintslash)
		tst.b	d1
		bpl	@f
		bsr	append_extract_suffix
@@:
		moveq	#0,d0
		lea	(ma_ext_sub_end,pc),a1
		bsr	ma_list_append
		lea	(92,sp),sp
ma_ext_sub_end:
		rts


* 展開済みフラグ操作 -------------------------- *

* 展開済みフラグをセットする
set_extract_flag:
		bsr	get_ma_buf_a0
		st	(MA_EXT_FLAG,a0)
		rts

* 展開済みフラグをテスト後、クリアする
clear_extract_flag:
		bsr	get_ma_buf_a0
		tst.b	(MA_EXT_FLAG,a0)
		sf	(MA_EXT_FLAG,a0)
		rts


* mintarc quick 実行 -------------------------- *

* 書き込みモード
*	追加: >LZHS_A >TARS_A >TARS_A
*	削除: >LZHS_D >TARS_D >ZIPS_D
call_mintarc_quick_w:
		move.l	d0,-(sp)
		move	(arc_file_atr,pc),d0
		bmi	@f			;属性変更は不要
		moveq	#1<<ARCHIVE,d0
		bsr	change_arc_file_atr	;書き込み可能な属性に変更する
@@:		move.l	(sp)+,d0

		bsr	call_mintarc_quick_r

		move	(arc_file_atr,pc),d0
		bmi	@f
		bsr	change_arc_file_atr	;属性を元に戻す
@@:
		move.l	a0,-(sp)
		bsr	get_ma_buf_a0
		st	(MA_RELOAD,a0)
		movea.l	(sp)+,a0
		rts


* 読み込みモード
*	展開: >LZHS_X >TARS_X >ZIPS_X
*	終了: >LZHS_Q >TARS_Q >ZIPS_Q
call_mintarc_quick_r:
		bra	call_mintarc_quick
**		rts


* フラグセットなし(通常の定義と同等)
*	現在は ～_w、～_r からのみ呼ばれる.
call_mintarc_quick:
		bsr	get_arc_type
		beq	@f
		bmi	1f
		addq.l	#KQ_TARS_X-KQ_LZHS_X,d0
		bra	@f
1:		addq.l	#KQ_ZIPS_X-KQ_LZHS_X,d0
@@:
		move.l	(stop_flags),-(sp)
		clr.l	(stop_flags)		;&stop-～ 系の初期化

		lsl	#8,d0
		addq.b	#%0000_0001,d0
		jsr	(execute_quick_no)

		jsr	(resume_stops)		;&stop-～ 系の復帰
		move.l	(sp)+,(stop_flags)
		rts


* ファイル名リスト管理 ------------------------ *

MA_LIST_SIZE:	.equ	1024*8

* リストにファイル名を追加する
* in	d0.b	削除フラグ($ff:削除する $00:削除しない)
*	a0.l	ファイル名
*	a1.l	メモリ解放処理のアドレス

ma_list_append::
		PUSH	d0-d1/a0-a2
		move.b	d0,d1
		move.l	(ma_list_ptr,pc),d0
		bgt	@f			;確保済み
		bmi	ma_list_append_error	;確保失敗済み

		jsr	(a1)
		pea	(MA_LIST_SIZE)		;バッファを確保する
		DOS	_MALLOC
		lea	(ma_list_rest,pc),a2
		move.l	(sp)+,(a2)		;ma_list_rest
		move.l	d0,-(a2)		;ma_list_ptr
		move.l	d0,-(a2)		;ma_list_adr
		bmi	ma_list_append_error
@@:
		STRLEN	a0,d0,+1+1		;文字列長＋NUL＋フラグ
		lea	(ma_list_rest,pc),a2
		sub.l	d0,(a2)			;ma_list_rest
		bcc	ma_list_append_copy

		jsr	(a1)
		addi.l	#MA_LIST_SIZE,(a2)	;拡大後の残りサイズ
		add.l	(a2),d0
		add.l	-(a2),d0		;ma_list_ptr
		sub.l	-(a2),d0		;ma_list_adr
		move.l	d0,-(sp)		;拡大後サイズ
		move.l	(a2)+,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bpl	@f
		move.l	d0,(a2)			;ma_list_ptr
		bra	ma_list_append_error
@@:
		addq.l	#ma_list_rest-ma_list_ptr,a2
ma_list_append_copy:
		movea.l	-(a2),a1		;ma_list_ptr
		move.b	d1,(a1)+		;フラグ
		STRCPY	a0,a1			;ファイル名
		move.l	a1,(a2)
		addq.l	#1,(ma_list_num-ma_list_ptr,a2)
ma_list_append_error:
		POP	d0-d1/a0-a2
		rts


* リストで指定したファイルを書庫から削除する
ma_list_delete::
**		bsr	ma_list_lift
		bsr	ma_list_setblock
		bsr	mintarc_delete
		bra	ma_list_free
**		rts

* リストで指定したファイルを書庫に書き込む
ma_list_write::
**		bsr	ma_list_lift
		bsr	ma_list_setblock
		bsr	mintarc_write
		bra	ma_list_free
**		rts


* リスト用バッファを解放する
ma_list_free:
		PUSH	d0/a0
		lea	(ma_list_adr,pc),a0
		move.l	(a0),-(sp)
		ble	@f
		DOS	_MFREE
@@:		addq.l	#4,sp
	.rept	4
		clr.l	(a0)+
	.endm
		POP	d0/a0
		rts


* リスト用バッファのサイズを切り詰める
ma_list_setblock:
		PUSH	d0-d1/a1
		lea	(ma_list_adr,pc),a0
		move.l	(a0)+,d1		;ma_list_adr
		ble	@f
		move.l	(a0)+,d0		;ma_list_ptr
		clr.l	(a0)			;ma_list_rest

		sub.l	d1,d0
		move.l	d0,-(sp)
		move.l	d1,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
@@:
		POP	d0-d1/a0
		rts


.if 0
* リスト用バッファを高位メモリに移動する
ma_list_lift:
		PUSH	d0-d2/a0-a1
		lea	(ma_list_adr,pc),a0
		move.l	(a0)+,d0		;ma_list_adr
		beq	ma_list_lift_end

		movea.l	d0,a1
		move.l	(a0),d1			;ma_list_ptr
		sub.l	a1,d1
		move.l	d1,-(sp)
		move	#2,-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bpl	@f

		bsr	ma_list_free		;上位から確保不能なら破棄する
		bra	ma_list_lift_end
@@:
		move.l	d0,(a0)+		;ma_list_ptr
		clr.l	(a0)			;ma_list_rest
		add.l	d1,-(a0)		;ma_list_ptr
		move.l	d0,-(a0)		;ma_list_adr

		pea	(a1)
		movea.l	d0,a0
		moveq	#$f,d2
		and	d1,d2			;端数
		lsr.l	#4,d1
		bra	1f
@@:
	.rept	4
		move.l	(a1)+,(a0)+
	.endm
1:		dbra	d1,@b
		clr	d1
		subq.l	#1,d1
		bcc	@b
		bra	1f
@@:
		move.b	(a1)+,(a0)+
1:		dbra	d2,@b

		DOS	_MFREE			;もとのバッファを解放
		addq.l	#4,sp
ma_list_lift_end:
		POP	d0-d2/a0-a1
		rts

* リストの内容を表示する(デバッグ用)
ma_list_print:
		PUSH	d0-d1/a0
		pea	(ma_list_print_mes,pc)
		DOS	_PRINT
		move.l	(ma_list_num,pc),d1
		beq	ma_list_print_end
		movea.l	(ma_list_adr,pc),a0
ma_list_print_loop:
		addq.l	#1,a0			;フラグを飛ばす
		move	#SPACE,(sp)
		DOS	_PUTCHAR
		move.l	a0,(sp)
		DOS	_PRINT
@@:		tst.b	(a0)+
		bne	@b
		subq.l	#1,d1
		bne	ma_list_print_loop
ma_list_print_end:
		addq.l	#4,sp
		bsr	print_crlf
		POP	d0-d1/a0
		rts

ma_list_print_mes:
		.dc.b	'ma_list =',0
		.even
.endif

ma_list_adr::	.ds.l	1
ma_list_ptr:	.ds.l	1
ma_list_rest:	.ds.l	1
ma_list_num::	.ds.l	1


* cpmv/mkdir 書き込みルーチン ----------------- *

mintarc_write:
		PUSH	d0-d7/a0-a6
		move.l	(ma_list_num,pc),d0
		beq	ma_write_end

		moveq	#0,d0
		bsr	check_arc_file_atr
		bmi	ma_write_end

		bsr	assign_virdrv
		bmi	ma_write_end

		lea	(virdrv_buf,pc),a1
		bsr	local_path_a1

		moveq	#KQ_LZHS_A,d0
		bsr	call_mintarc_quick_w

		bsr	local_path_minttmp
		bsr	unassign_virdrv

		bsr	reload_archive

		bsr	local_path_minttmp
		lea	(-128,sp),sp
		movea.l	(ma_list_adr,pc),a1
		move.l	(ma_list_num,pc),d7
ma_write_del_loop:
		tst.b	(a1)+			;フラグ
		beq	@f			;削除しない
		lea	(sp),a0
		STRCPY	a1,a0
		lea	(sp),a0
		jsr	(del_a0)
		bra	1f
@@:
		tst.b	(a1)+
		bne	@b
1:		subq.l	#1,d7
		bne	ma_write_del_loop
		lea	(128,sp),sp

		bsr	mintarc_chdir_to_arc_dir
ma_write_end:
		POP	d0-d7/a0-a6
		rts


* &delete 削除ルーチン ------------------------ *

mintarc_delete:
		PUSH	d0-d7/a0-a6
		move.l	(ma_list_num,pc),d0
		beq	ma_del_end

		moveq	#-1,d0
		bsr	check_arc_file_atr
		bmi	ma_del_end

		moveq	#KQ_LZHS_D,d0
		bsr	call_mintarc_quick_w

		bsr	reload_archive
ma_del_end:
		POP	d0-d7/a0-a6
		rts


reload_archive:
		bsr	analyze_archive
		bsr	setblock_path_buf
		bsr	mfree_ofb_nfb
		bsr	malloc_ofb_nfb
		bsr	make_ofb_nfb_from_afl
		bra	set_arc_use_byte
**		rts


* 書庫の合計圧縮サイズをセットする ------------ *

set_arc_use_byte:
		bsr	get_mintarc_comp_size
		jsr	(set_path_use_byte)
		move.l	d0,d2
		move.l	d1,d3
		bsr	get_mintarc_orig_size
		jsr	(set_path_free_byte_ratio)
**		rts


* 展開ファイル削除処理 ------------------------ *

mintarc_dispose_ache::
		tst	(＄ache)
		bne	ma_dispose_ache_end

		movea.l	(PATH_OPP,a6),a6	;%ache 0: 展開ファイルを削除
		moveq	#0,d0
		bsr	mintarc_dispose
		movea.l	(PATH_OPP,a6),a6
		bmi	@f
		jsr	(ReverseCursorBarOpp)
@@:
		moveq	#0,d0
		bsr	mintarc_dispose
		bmi	@f
		jsr	(ReverseCursorBar)
@@:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		bsr	local_path_minttmp	;$MINTTMP に移動
* %ache 0 の時も mintarc_chdir_to_arc_dir を
* 呼び出して、cur_dir_buf に書庫内ディレクトリ
* をセットしておく必要がある.
ma_dispose_ache_end:
		tst.b	(PATH_MARC_FLAG,a6)
		bne	mintarc_chdir_to_arc_dir
@@:		rts


* in	d0.b	$00:リロードする $ff:しない
* out	ccr	リロードした場合 Z=1、N=0
*		それ以外の場合	 Z=0、N=1

mintarc_dispose::
		st	-(sp)
		tst.b	(PATH_MARC_FLAG,a6)
		beq	ma_dispose_end
		bsr	clear_extract_flag
		beq	ma_dispose_end

		move.b	d0,(sp)
		bsr	local_path_minttmp

		bsr	dos_files_nfb		;事後比較
		bsr	compare_ofb_nfb
		beq	ma_dispose_delete	;改変されてないなら削除して終わり

		bsr	check_writeback
		beq	ma_dispose_write
		tst	(＄achr)		;書き戻さない場合でも、%achr 1なら
		bne	ma_dispose_delete	;改変されたファイルを削除する
ma_dispose_end2:
		bsr	ma_list_free
		st	(sp)
		bra	ma_dispose_end
ma_dispose_write:
		bsr	mintarc_writeback
		bne	ma_dispose_end2
		bra	@f
ma_dispose_delete:
		st	(sp)			;reload 不要
@@:
		bsr	ma_list_free
		bsr	mark_nfb_dir		;事後削除
		bsr	delete_nfb_file
		bsr	delete_nfb_dir
		tst.b	(sp)
		bne	ma_dispose_end

		bsr	reload_archive
		jsr	(directory_write_routin)
ma_dispose_end:
		tst.b	(sp)+
		rts


* 書庫ファイルへの書き戻し検査
*	展開後に変更されたファイルを書庫に書き戻して
*	よいか確認する.
* out	d0.l	0:実行 -1:中止
*	ccr	<tst.l d0> の結果

check_writeback:
		PUSH	d1-d7/a0-a5
		cmpi	#1,(＄arc！)
		beq	check_wb_no
		bhi	check_wb_yes

* [] 内に表示する文字列を用意する
		lea	(-(72-5+1),sp),sp
		movea.l	(ma_list_adr,pc),a0
		lea	(sp),a1
		moveq	#72-5-1,d1
		move.l	(ma_list_num,pc),d2
1:
		addq.l	#1,a0			;フラグを飛ばす
2:		move.b	(a0)+,d0
		beq	5f
		move.b	d0,(a1)+
		subq	#1,d1
		bcs	9f
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	2b
		subq	#1,d1
		bcs	8f
		move.b	(a0)+,(a1)+
		bne	2b
		subq.l	#1,a1
		bra	8f
5:
		subq.l	#1,d2
		beq	9f
		move.b	#SPACE,(a1)+
		dbra	d1,1b			;次のファイル
8:		subq.l	#1,a1
9:		clr.b	(a1)

		lea	(subwin_ask,pc),a0
		lea	(sp),a1
		move.l	#MES_MARCW<<16+MES_MARC2,d0
		jsr	(ask_window_sub)
		lea	(72-5+1,sp),sp
		jsr	(check_yes_or_no)
		bne	check_wb_no
check_wb_yes:
		move	(PATH_DRIVENO,a6),d1
		jsr	(dos_drvctrl_d1)
		btst	#DRV_PROTECT,d0
		beq	check_wb_yes2

		jsr	(print_write_protect_error)
check_wb_no:
		moveq	#-1,d0
		bra	check_wb_end
check_wb_yes2:
		moveq	#0,d0
check_wb_end:
		POP	d1-d7/a0-a5
		rts


* 展開ファイルが変更されていた場合の書き戻し
* out	d0.l	0:正常終了 -1:エラー
*	ccr	<tst.l d0> の結果

mintarc_writeback:
		moveq	#0,d0
		bsr	check_arc_file_atr
		bmi	mintarc_writeback_end

		bsr	assign_virdrv
		bmi	mintarc_writeback_end

		lea	(virdrv_buf,pc),a1	;MINTTEMP の subst ドライブ
		bsr	local_path_a1

		moveq	#KQ_LZHS_A,d0
		bsr	call_mintarc_quick_w

		bsr	local_path_minttmp
		bsr	unassign_virdrv
		moveq	#0,d0
mintarc_writeback_end:
		rts


* テンポラリディレクトリに移動 ---------------- *

* テンポラリディレクトリ＋書庫内ディレクトリに移動する.
* ディレクトリを展開していない場合は失敗する.
mintarc_chdir_to_arc_dir::
		PUSH	a1-a2
		lea	(cur_dir_buf),a2
		bsr	get_mintarc_dir
		movea.l	d0,a1
		STRCPY	a1,a2,-1
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a1
		STRCPY	a1,a2
		bra	@f

* テンポラリディレクトリ($MINTTMP/n)に移動する.
* ここは必ず成功する.
local_path_minttmp::
		bsr	get_mintarc_dir
		move.l	d0,a1
local_path_a1:
		PUSH	a1-a2
		lea	(cur_dir_buf),a2
		STRCPY	a1,a2
@@:
		POP	a1-a2
		jmp	(reset_current_dir)
**		rts


* 書庫ファイルの属性関係の処理 ---------------- *

* 書庫ファイルの属性を収得する
* out	d0.l	ファイル属性(負数ならエラーコード)
*	ccr	<tst.l d0> の結果

get_arc_file_atr:
		moveq	#-1,d0
		bra	change_arc_file_atr

* 書庫ファイルの属性を変更する
* in	d0.w	ファイル属性
* out	d0.l	エラーコード
*	ccr	<tst.l d0> の結果

change_arc_file_atr:
		move	d0,-(sp)
		bsr	get_mintarc_filename
		move.l	d0,-(sp)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		rts


* 書庫ファイルの属性検査
*	書庫ファイルの属性を調べ、書き込み不可能な
*	属性なら実行してよいか確認する
* in	d0.l	0:追加モード 1:削除モード(&delete)
* out	d0.l	0:実行 -1:中止
*	ccr	<tst.l d0> の結果

check_arc_file_atr:
		PUSH	d1-d7/a0-a5
		lea	(arc_file_atr,pc),a5
		st	(a5)
		move	d0,d1
		bsr	get_arc_file_atr
		bmi	chk_arc_file_atr_end

		move	d0,d7
		moveq	#1<<SYSTEM+1<<READONLY,d0
		and.b	d7,d0
		beq	chk_arc_file_atr_end	;書き込み可能

		tst	d1
		beq	@f
		tst	(＄del！)
		bne	chk_arc_file_atr_force	;問い合せなしで強制削除
@@:
		lea	(subwin_ask,pc),a0
		bsr	get_mintarc_filename
		movea.l	d0,a1
		move.l	#MES_MARCD<<16+MES_KYOU2,d0
		jsr	(ask_window_sub)
		jsr	(check_yes_or_no)
		beq	chk_arc_file_atr_force

		moveq	#-1,d0
		bra	@f
chk_arc_file_atr_force:
		move	d7,(a5)			;属性を保存しておく
chk_arc_file_atr_end:
		moveq	#0,d0
@@:		POP	d1-d7/a0-a5
		rts


arc_file_atr:	.ds	1


* AFL バッファ初期化 -------------------------- *

clear_afl_buffer:
		PUSH	d0/a5
		moveq	#AFL_BUF_SIZE/4-1,d0
@@:
		clr.l	(a5)+
		dbra	d0,@b
		POP	d0/a5
		_END_OF_BUF_FLG_ON a5
		rts
		.fail	AFL_BUF_SIZE.and.%11


* 書庫解析 ------------------------------------ *

analyze_archive:
		bsr	get_ma_buf
		movea.l	d0,a5
		clr.l	(MA_REAL_SIZEh,a5)
		clr.l	(MA_REAL_SIZEl,a5)
		clr.l	(MA_ARC_SIZEh,a5)
		clr.l	(MA_ARC_SIZEl,a5)
		clr	(MA_FILE_NUM,a5)
		move.b	(MA_ARC_TYPE,a5),-(sp)

		lea	(MA_AFL_PTR,a5),a5
		move.l	#AFL_BUF_SIZE*ARC_FILE_MAX,-(sp)
		move.l	(a5),-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bpl	@f		;拡大成功

		move.l	#AFL_BUF_SIZE*ARC_FILE_MAX,-(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	@f			;確保失敗(危険…)

		move.l	(a5),-(sp)		;旧バッファ解放
		move.l	d0,(a5)
		DOS	_MFREE
		addq.l	#4,sp
@@:		movea.l	(a5),a5

		_BUF_CLR
		_END_OF_BUF_FLG_OFF a5		;構造上先頭に空バッファが必要
		_NEXT_BUF a5
		_BUF_CLR

		bsr	open_arc_file
		bpl	@f
		tst.b	(sp)+			;新規書庫
		bra	ana_arc_new
@@:
		bsr	arc_dir_dummy_date_make
		lea	(Buffer),a4
		tst.b	(sp)+
		beq	analyze_lzh		;$00 = lzh
		bmi	analyze_zip		;$ff = zip
		bra	analyze_tar		;$01 = tar

ana_arc_zip_end:
		bsr	mfree_zcdfh_buf
ana_arc_end:
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
ana_arc_new:
		_PREV_BUF a5			;常に空バッファを作ってるのでそれを戻す
		_END_OF_BUF_FLG_ON a5
		_NEXT_BUF a5

		bsr	get_ma_buf_a0
		suba.l	(MA_AFL_PTR,a0),a5	;必要サイズ
		move.l	a5,-(sp)
		move.l	(MA_AFL_PTR,a0),-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp

		bra	set_status_1

open_arc_file:
		clr	-(sp)			;ROPEN
		bsr	get_mintarc_filename
		move.l	d0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d7			;d7 = ファイルハンドル(破壊禁止)
		rts

arc_dir_dummy_date_make:
		clr.l	-(sp)
		move	d0,-(sp)
		DOS	_FILEDATE
		addq.l	#6,sp
		swap	d0
		move.l	d0,(dir_dummy_date)
		rts

mfree_zcdfh_buf:
		move.l	(zip_cdfh_buf_ptr,pc),d0
mfree_d0:
		move.l	d0,-(sp)
		DOS	_MFREE
		move.l	d0,(sp)+
		rts


zip_cdfh_buf_ptr:
		.ds.l	1
dir_dummy_date:
		.ds.l	1


* TAR 解析ルーチン ---------------------------- *

analyze_tar::
		clr	(a4)+			;ファイル名切り出しの為
tar_loop:
		pea	(TAR_BLOCK_SIZE)	;ヘッダ512バイトを読み込む
		move.l	a4,-(sp)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		beq	@f
		bcs	ana_arc_end
		bra	ana_file_error
@@:
		tst.b	(a4)
		beq	ana_arc_end

.ifdef __CHECK_USTAR_MARK__
		cmpi.b	#'u',(TAR_USTAR_MARK,a4)
		bne	@f
		cmpi.l	#'star',(TAR_USTAR_MARK+1,a4)
@@:		bne	ana_arc_end
.endif
		lea	(TAR_CHECKSUM,a4),a0
		bsr	get_oct_number
		move.l	#$20202020,d1
		move.l	d1,(a0)+
		move.l	d1,(a0)+

		lea	(a4),a0			;チェックサムを計算する
		moveq	#0,d1
		moveq	#TAR_BLOCK_SIZE/4-1,d2
@@:		add.b	(a0)+,d1
		add.b	(a0)+,d1
		add.b	(a0)+,d1
		add.b	(a0)+,d1
		dbra	d2,@b
		cmp.b	d0,d1
		bne	ana_arc_end

* ヘッダ検査通過
		lea	(TAR_TIME,a4),a0
		bsr	get_oct_number
		bsr	utc2dostime
		move.l	d0,(AFL_TIME_DATE,a5)

		lea	(TAR_FILESIZE,a4),a0
		bsr	get_oct_number
		move.l	d0,(AFL_SIZE,a5)
		bsr	add_info_real_size_sum

		addi.l	#(TAR_BLOCK_SIZE-1),d0	;ブロックサイズに切り上げ
		andi	#.not.(TAR_BLOCK_SIZE-1),d0
		move.l	d0,d6

		addi.l	#TAR_BLOCK_SIZE,d0
		bsr	add_info_arc_size_sum

		moveq	#1<<ARCHIVE,d1
		lea	(TAR_ATTRIB,a4),a0
		bsr	get_oct_number
		btst	#6,d0
		beq	@f
		tas	d1			;bset #EXEC,d1
@@:		tst.b	d0
		bmi	@f
		addq.b	#1<<READONLY,d1
@@:		move.b	d1,(AFL_ATR,a5)

		lea	(TAR_FILENAME,a4),a1
		lea	(a1),a0
		bsr	space_to_underline
@@:
		tst.b	(a1)+
		bne	@b
		subq.l	#2,a1
		cmpi.b	#'/',(a1)+
		bne	@f

		subq.l	#1,a1
		eori.b	#1<<DIRECTORY+1<<ARCHIVE,(AFL_ATR,a5)
@@:
		moveq	#-1,d0
tar_fnchk_loop:
		addq	#1,d0
		move.b	-(a1),d1
		beq	tar_file_only

		cmpi.b	#'/',d1			;一個前の '/' へ移動
		bne	tar_fnchk_loop
*tar_dir_file:
		move	d0,-(sp)
		lea	(a1),a2
		bsr	copy_dirname		;dir/dir[/]filename.ext
		move	(sp)+,d0		;d0 = name length
tar_file_only:
		move.l	a1,-(sp)
		addq.l	#1,a1			;a1 = filename 先頭
		bsr	copy_filename		;d0 = 文字数 a1 = filename 先頭
		bmi	tar_ignore_entry

		bsr	inc_info_entrys_sum

		_END_OF_BUF_FLG_OFF a5
		_NEXT_BUF a5
		_BUF_CLR
		movea.l	(sp)+,a2
		bsr	regist_directory
		bra	@f
tar_ignore_entry:
		movea.l	(sp)+,a2
		_BUF_CLR
@@:
		move	#SEEK_CUR,-(sp)
		move.l	d6,-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	ana_file_error
		bra	tar_loop


* 八進数文字列の数値変換
* in	a0.l	文字列のアドレス
* out	d0.l	数値

get_oct_number:
		PUSH	d1/a0
@@:		cmpi.b	#SPACE,(a0)+
		beq	@b
		subq.l	#1,a0

		moveq	#0,d0
		bra	get_oct_number_start
get_oct_number_loop:
		lsl.l	#3,d0
		or.b	d1,d0
get_oct_number_start:
		move.b	(a0)+,d1
		subi.b	#'0',d1
		cmpi.b	#8,d1
		bcs	get_oct_number_loop
		POP	d1/a0
		rts

* 文字列中の制御記号及び半角スペースをアンダーラインに変換する.
* in	a0.l	文字列のアドレス
* break	d0/a0

space_to_underline_loop:
		cmpi.b	#$20,d0
		bhi	space_to_underline
		move.b	#'_',(-1,a0)
space_to_underline:
		move.b	(a0)+,d0
		bne	space_to_underline_loop
		rts


* エントリ登録関係 ---------------------------- *

inc_info_entrys_sum:
		tst	(PATH_WINRL,a6)
		beq	@f
		addq	#1,(ma_buf_r+MA_FILE_NUM)
		rts
@@:		addq	#1,(ma_buf_l+MA_FILE_NUM)
		rts

add_info_real_size_sum:
		move.l	a0,-(sp)
		bsr	get_ma_buf_a0

		add.l	d0,(MA_REAL_SIZEl,a0)
		bcc	@f
		addq.l	#1,(MA_REAL_SIZEh,a0)
@@:
		movea.l	(sp)+,a0
		rts

add_info_arc_size_sum:
		move.l	a0,-(sp)
		bsr	get_ma_buf_a0

		add.l	d0,(MA_ARC_SIZEl,a0)
		bcc	@f
		addq.l	#1,(MA_ARC_SIZEh,a0)
@@:
		movea.l	(sp)+,a0
		rts


* ZIP 解析ルーチン ---------------------------- *

analyze_zip::
		bsr	zip_search_zecdr
		tst.l	d6
		bpl	@f

		addq.l	#1,d6
		beq	ana_file_error
		bra	ana_unknown_arc
@@:
* preamble 付き書庫に対応する為、ECDR との位置関係
* を利用して CD の開始位置を求める.
		lea	(ZECDR_size_central_directory,a0),a0
		bsr	lpeek_intel
		sub.l	d0,d6			;d0=pos(central directory の位置)
		exg	d0,d6			;d6=size

		clr	-(sp)
		move.l	d0,-(sp)
		move	d7,-(sp)
		DOS	_SEEK			;central directory まで移動する
		addq.l	#8,sp
		tst.l	d0
		bmi	ana_file_error

		move.l	d6,-(sp)
		addq.l	#1,(sp)
		DOS	_MALLOC
		move.l	d0,(sp)+
		bmi	ana_memory_error
		move.l	d0,a4
		move.l	d0,(zip_cdfh_buf_ptr)

		move.l	d6,-(sp)
		move.l	a4,-(sp)
		move	d7,-(sp)
		DOS	_READ			;central directory を読み込む
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		beq	@f
		bcs	ana_arc_zip_end
		bsr	mfree_zcdfh_buf
		bra	ana_unknown_arc
@@:
		clr.b	(a4,d0.l)
zip_loop:
		lea	(a4),a0
		bsr	lpeek
		cmpi.l	#CENTRAL_HDR_SIG,d0	;"PK\x01\x02"
		bne	ana_arc_zip_end

		bsr	inc_info_entrys_sum

* タイムスタンプ収得
		lea	(ZCDFH_last_mod_file_time,a4),a0
		bsr	lpeek_intel
		swap	d0
		move.l	d0,(AFL_TIME_DATE,a5)

* 圧縮後サイズ収得
		lea	(ZCDFH_csize,a4),a0
		bsr	lpeek_intel
		bsr	add_info_arc_size_sum

* 展開時サイズ収得
		lea	(ZCDFH_ucsize,a4),a0
		bsr	lpeek_intel
		move.l	d0,(AFL_SIZE,a5)
		bsr	add_info_real_size_sum

* ファイル属性収得
.if 0
		moveq	#.low..not.(1<<EXEC+1<<LINK),d0
		and.b	(ZCDFH_external_file_attributes,a4),d0
		btst	#6,(ZCDFH_external_file_attributes+2,a4)
		beq	@f
		bset	#EXEC,d0
.else
		move.b	(ZCDFH_external_file_attributes,a4),d0
		bne	@f
		btst	#6,(ZCDFH_external_file_attributes+2,a4)
		beq	@f
		moveq	#1<<EXEC,d0
.endif
@@:		move.b	d0,(AFL_ATR,a5)
		_END_OF_BUF_FLG_ON a5

* ファイル名長収得
		lea	(ZCDFH_filename_length,a4),a0
		bsr	wpeek_intel
		lea	(ZCDFH_SIZE,a4,d0.w),a1	;ファイル名末尾

		clr.b	(ZCDFH_SIZE-1,a4)	;filename の直前をクリア
		move.b	(a1),-(sp)
		clr.b	(a1)
		lea	(ZCDFH_SIZE,a4),a0
		bsr	space_to_underline
		move.b	(sp)+,(a1)

		lea	(ZCDFH_extra_field_length,a4),a0
		bsr	wpeek_intel
		lea	(a1,d0.l),a4
		addq.l	#ZCDFH_file_comment_length-ZCDFH_extra_field_length,a0
		bsr	wpeek_intel
		adda.l	d0,a4			;次のヘッダ

		cmpi.b	#'/',(-1,a1)
		bne	@f
		subq.l	#1,a1			;filename 末尾が '/' ならディレクトリ
		_DIR_FLG_ON a5
@@:
		moveq	#-1,d0
zip_fnchk_loop:
		addq	#1,d0
		move.b	-(a1),d1
		beq	zip_file_only

		cmpi.b	#'/',d1			;一個前の '/' へ移動
		bne	zip_fnchk_loop
*zip_dir_file:
		move	d0,-(sp)
		lea	(a1),a2
		bsr	copy_dirname		;dir/dir[/]filename.ext
		move	(sp)+,d0		;d0 = name length
zip_file_only:
		move.l	a1,-(sp)
		addq.l	#1,a1			;a1 = filename 先頭
		bsr	copy_filename		;d0 = 文字数 a1 = filename 先頭
		bmi	zip_ignore_entry

		_END_OF_BUF_FLG_OFF a5
		_NEXT_BUF a5
		_BUF_CLR
		movea.l	(sp)+,a2
		bsr	regist_directory
		bra	zip_loop
zip_ignore_entry:
		movea.l	(sp)+,a2
		_BUF_CLR
		bra	zip_loop


* END CENTRAL DIRECTORY RECORD を検索する ----- *
* in	d7.w	ファイルハンドル
*	a4.l	バッファ
* out	d6.l	ECDR のファイル位置
*		-1:ファイル操作エラー
*		-2:未対応アーカイブ
*	a0.l	バッファ上に読み込んだ ECDR のアドレス
* break	d0.l

zip_search_zecdr::
		PUSH	d1/d4-d5
		bsr	get_file_size
		move.l	d0,d6
		bmi	zip_search_zecdr_fileop_error
		subi.l	#ZECDR_SIZE-1,d6
		bls	zip_search_zecdr_illegal_arc

		move.l	d6,d4
		subi.l	#66000,d4		;これより手前には有り得ない
		move.l	#1024,d5		;end central directory record を検索する
zip_search_zecdr_loop:
		cmp.l	d5,d6
		bcc	@f
		move.l	d6,d5			;残り 1024(+record)バイト以下
@@:		sub.l	d5,d6

		clr	-(sp)			;SEEK_SET
		move.l	d6,-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	zip_search_zecdr_fileop_error

		pea	(ZECDR_SIZE-1)
		add.l	d5,(sp)
		move.l	a4,-(sp)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		bne	zip_search_zecdr_fileop_error

		lea	(-(ZECDR_SIZE-1),a4,d0.l),a0
		move.l	a0,d1
		sub.l	a4,d1			;検索バイト数
		subq	#1,d1
@@:
		cmpi.b	#'P',-(a0)
		dbeq	d1,@b
		bne	@f
		bsr	lpeek
		cmpi.l	#END_CENTRAL_SIG,d0	;"PK\x05\x06"
		dbeq	d1,@b
		beq	zip_search_zecdr_found
@@:
		cmp.l	d4,d6
		blt	zip_search_zecdr_illegal_arc
		tst.l	d6
		bne	zip_search_zecdr_loop
zip_search_zecdr_illegal_arc:
		moveq	#-2,d6
		bra	@f
zip_search_zecdr_fileop_error:
		moveq	#-1,d6
		bra	@f
zip_search_zecdr_found:
		add.l	a0,d6
		sub.l	a4,d6			;ECDR の位置
@@:
		POP	d1/d4-d5
		rts

get_file_size:
		move	#SEEK_END,-(sp)
		clr.l	-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		rts


* データ単純読み込み系 ------------------------ *

* 1word 読み込み(little-endian)
* in	a0.l	アドレス
* out	d0.l	データ
wpeek_intel:
		moveq	#0,d0
		move.b	(1,a0),-(sp)
		move	(sp)+,d0
		move.b	(a0),d0
		rts

* 1longword 読み込み(big-endian)
* in	a0.l	アドレス
* out	d0.l	データ
lpeek:
		move.b	(a0)+,-(sp)
		move	(sp)+,d0
		move.b	(a0)+,d0
		swap	d0
		move.b	(a0)+,-(sp)
		move	(sp)+,d0
		move.b	(a0)+,d0
		subq.l	#4,a0
		rts

* 1longword 読み込み(little-endian)
* in	a0.l	アドレス
* out	d0.l	データ
lpeek_intel:
		addq.l	#4,a0
		move.b	-(a0),-(sp)
		move	(sp)+,d0
		move.b	-(a0),d0
		swap	d0
		move.b	-(a0),-(sp)
		move	(sp)+,d0
		move.b	-(a0),d0
		rts


* LZH 解析ルーチン ---------------------------- *

LZH_WORK_SIZE:	.equ	22
		.offset	-LZH_WORK_SIZE
~lzh_filename:	.ds.l	1
~lzh_pathname:	.ds.l	1
~lzh_packed:	.ds.l	1
~lzh_original:	.ds.l	1
~lzh_headersize:.ds	1
~lzh_dirnlen:	.ds	1
~lzh_filenlen:	.ds	1
		.fail	$.ne.0
		.text

analyze_lzh::
		lea	(LZH_WORK_SIZE,a4),a4
		moveq	#0,d1
lzh_search_header_loop:
		pea	(1024+6)		;最後の 1.b からの 7.b がヘッダかも
		move.l	a4,-(sp)		;しれないので、6.b 多く読み込む
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	ana_file_error

		subq	#6+1,d0
		bcs	ana_unknown_arc
		lea	(2,a4),a0
lzh_search_header_next:
		cmpi.b	#'-',(a0)+
		bne	@f
		cmpi.b	#'l',(0,a0)
		bne	@f
		cmpi.b	#'h',(1,a0)		;-lh?-
		beq	1f
		cmpi.b	#'z',(1,a0)		;-lz?-
		bne	@f
1:		cmpi.b	#'-',(3,a0)
		beq	found_lzh_header
@@:
		addq.l	#1,d1
		dbra	d0,lzh_search_header_next

		bsr	fseek_to_d1		;6.b 多く読み込んだ分を戻す
		bmi	ana_file_error
		bra	lzh_search_header_loop

fseek_to_d1:
		clr	-(sp)
		move.l	d1,-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		rts

found_lzh_header:
		bsr	fseek_to_d1		;ヘッダ位置にシークする
		bmi	ana_file_error
lzh_loop:
		moveq	#21,d1
		move.l	d1,-(sp)		;ヘッダから 21.b 読み込む
		move.l	a4,-(sp)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	ana_file_error
		cmp.l	d1,d0
		bne	ana_arc_end

		moveq	#0,d0
		move.b	(LH0_header_size,a4),d0
		beq	ana_arc_end
		addq	#2,d0
		move	d0,(~lzh_headersize,a4)

		lea	(LH0_packed_size,a4),a0
		bsr	lpeek_intel
		move.l	d0,(~lzh_packed,a4)
		addq.l	#LH0_original_size-LH0_packed_size,a0
		bsr	lpeek_intel
		move.l	d0,(~lzh_original,a4)

		clr	(~lzh_dirnlen,a4)

		move.b	(LH0_attribute,a4),d0
		move.b	(LH0_header_level,a4),d6
		bne	@f
* レベル 0 かつ DIRECTORY かつオリジナルサイズが 0 でなければ
* ファイルに変更する.
		btst	#DIRECTORY,d0
		beq	@f
		tst.l	(~lzh_original,a4)
		beq	@f
		bclr	#DIRECTORY,d0
		bset	#ARCHIVE,d0
@@:
		bsr	lzh_set_attribute

		cmpi.b	#2,d6			;header level
		bcs	lzh_level_01
		beq	lzh_level_2

		cmpi.b	#EOF,(LH0_header_size,a4)
		beq	ana_arc_end
		bra	ana_unknown_arc
lzh_level_01:
		moveq	#0,d0
		move	(~lzh_headersize,a4),d0
		sub.l	d1,d0			;-21
		bls	ana_arc_end

		move.l	d0,-(sp)		;ヘッダの残りを読み込む
		pea	(a4,d1.l)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		beq	@f
		bcs	ana_arc_end
		bra	ana_file_error
@@:
		bsr	lzh_check_method_id
		beq	@f
		cmpi.b	#EOF,(a4)
		beq	ana_arc_end
		bra	ana_unknown_arc
@@:
		moveq	#0,d0
		move.b	(LH0_name_length,a4),d0
		move	d0,(~lzh_filenlen,a4)

		lea	(LH0_pathname,a4),a0
		move.l	a0,(~lzh_filename,a4)
		move.l	a0,(~lzh_pathname,a4)

		lea	(LH0_time,a4),a0
		bsr	lpeek_intel
		swap	d0
		move.l	d0,(AFL_TIME_DATE,a5)

		move	(~lzh_headersize,a4),d0
		sub	(~lzh_filenlen,a4),d0
		cmpi	#24,d0
		bcs	@f
		tst.b	d6
		bne	lzh_level_1		;header level 1 でかつ ext-header がある
@@:
* pathname 中の '\'、'/'、$ff を '/' に変換して
* dirnameとfilenameに分割する.
		movea.l	(~lzh_pathname,a4),a0
		move	(~lzh_filenlen,a4),d0
		clr.b	(-1,a0)
		clr.b	(a0,d0.w)

		bsr	space_to_underline
		movea.l	(~lzh_pathname,a4),a0
		bsr	lzh_convdelim
		move.l	a1,(~lzh_filename,a4)
		bra	lzh_header_end

* 拡張ヘッダ処理
lzh_level_1:
		moveq	#0,d0
		move.b	(LH0_header_size,a4),d0
		lea	(a4,d0.w),a0
		moveq	#0,d1
		bra	lzh_l1_exhed
lzh_l1_exhed_loop:
		move.l	d1,-(sp)
		pea	(2,a0)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	ana_file_error
		cmp.l	d0,d1
		bne	ana_unknown_arc

		bsr	lzh_extheader
		adda.l	d1,a0
lzh_l1_exhed:
		bsr	wpeek_intel
		move	d0,d1
		bne	lzh_l1_exhed_loop

		addq.l	#2,a0
		suba.l	a4,a0
		moveq	#0,d0
		move	(~lzh_headersize,a4),d0
		add.l	(~lzh_packed,a4),d0
		sub.l	a0,d0			;真のヘッダサイズを引いた残りが
		move.l	d0,(~lzh_packed,a4)	;圧縮後サイズ
		bra	lzh_header_end_0

lzh_level_2:
		lea	(LH2_total_header_size,a4),a0
		bsr	wpeek_intel
		sub.l	d1,d0			;-21
		bls	ana_arc_end

		move.l	d0,-(sp)		;ヘッダの残りを読み込む
		pea	(21,a4)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		beq	@f
		bcs	ana_arc_end
		bra	ana_file_error
@@:
		bsr	lzh_check_method_id
		bne	ana_unknown_arc

		lea	(LH2_unix_time,a4),a0
		bsr	lzh_set_datetime

		lea	(LH2_next_header_size,a4),a0
		moveq	#0,d1
		bra	lzh_l2_exhed
lzh_l2_exhed_loop:
		bsr	lzh_extheader
		adda.l	d1,a0
lzh_l2_exhed:
		bsr	wpeek_intel
		move	d0,d1
		bne	lzh_l2_exhed_loop

lzh_header_end_0:
		moveq	#0,d0
		move	(~lzh_headersize,a4),d0
		lea	(a4,d0.l),a1
		clr.b	(a1)+
		move.l	a1,-(sp)		;dir+file バッファ

		movea.l	(~lzh_pathname,a4),a0
		move	(~lzh_dirnlen,a4),d0
		bra	1f
@@:
		move.b	(a0)+,(a1)+
1:		dbra	d0,@b
		movea.l	(~lzh_filename,a4),a0
		move	(~lzh_filenlen,a4),d0
		bra	1f
@@:
		move.b	(a0)+,(a1)+
1:		dbra	d0,@b
		clr.b	(a1)

		movea.l	(sp),a0
		bsr	space_to_underline

		movea.l	(sp)+,a0
		move.l	a0,(~lzh_pathname,a4)
		bsr	lzh_convdelim
		move.l	a1,(~lzh_filename,a4)
lzh_header_end:
		move.l	(~lzh_packed,a4),d0
		bsr	add_info_arc_size_sum
		move.l	(~lzh_original,a4),d0
		move.l	d0,(AFL_SIZE,a5)
		bsr	add_info_real_size_sum

		movea.l	(~lzh_filename,a4),a0
		STRLEN	a0,d0
		cmpi.b	#'/',(-1,a0,d0.w)
		bne	@f
		subq	#1,d0
		_DIR_FLG_ON a5
@@:
		bsr	copy_filename
		bmi	lzh_ignore_entry

		bsr	inc_info_entrys_sum

		movea.l	(~lzh_filename,a4),a2
		cmpa.l	(~lzh_pathname,a4),a2
		beq	lzh_without_dir

		clr.b	(a2)
		subq.l	#1,a2
		bsr	copy_dirname
		_END_OF_BUF_FLG_OFF a5
		_NEXT_BUF a5
		_BUF_CLR
		bsr	regist_directory
		bra	@f
lzh_without_dir:
		_END_OF_BUF_FLG_OFF a5
		_NEXT_BUF a5
lzh_ignore_entry:
		_BUF_CLR
@@:
		move	#SEEK_CUR,-(sp)
		move.l	(~lzh_packed,a4),-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	ana_file_error
		bra	lzh_loop


lzh_convdelim:
		moveq	#0,d0
		movea.l	a0,a1
		bra	lzh_convdelim_loop
lzh_convdelim_slash:
		move.b	#'/',(-1,a0)
		tst.b	(a0)
		beq	lzh_convdelim_end
		movea.l	a0,a1
lzh_convdelim_loop:
		move.b	(a0)+,d0
		beq	lzh_convdelim_end
		cmpi.b	#'/',d0
		beq	lzh_convdelim_slash
		cmpi.b	#'\',d0
		beq	lzh_convdelim_slash
		cmpi.b	#$ff,d0
		beq	lzh_convdelim_slash
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	lzh_convdelim_loop
		tst.b	(a0)+
		bne	lzh_convdelim_loop
lzh_convdelim_end:
		rts


lzh_extheader:
		PUSH	d0-d1/a0
		addq.l	#2,a0
		move.b	(a0)+,d0
		cmpi.b	#$40,d0
		beq	lzh_exhed_0x40
		cmpi.b	#$54,d0
		beq	lzh_exhed_0x54
		subq.b	#1,d0
		beq	lzh_exhed_0x01
		subq.b	#1,d0
		beq	lzh_exhed_0x02
lzh_extheader_end:
		POP	d0-d1/a0
		rts

lzh_exhed_0x01:
		move.l	a0,(~lzh_filename,a4)
		subq	#3,d1
		move	d1,(~lzh_filenlen,a4)
		bra	lzh_extheader_end

lzh_exhed_0x02:
		move.l	a0,(~lzh_pathname,a4)
		subq	#3,d1
		move	d1,(~lzh_dirnlen,a4)
		bra	lzh_extheader_end
	
lzh_exhed_0x40:
		move.b	(a0),d0
		bsr	lzh_set_attribute
		bra	lzh_extheader_end

lzh_set_attribute:
*		andi.b	#$ff.xor.(1<<LINK),d0
		move.b	d0,(AFL_ATR,a5)
		_END_OF_BUF_FLG_ON a5
		rts

lzh_exhed_0x54:
		bsr	lzh_set_datetime
		bra	lzh_extheader_end

lzh_set_datetime:
		bsr	lpeek_intel
		bsr	utc2dostime
		move.l	d0,(AFL_TIME_DATE,a5)
		rts

lzh_check_method_id:
		lea	(LH0_method_id,a4),a0
		cmpi.b	#'-',(a0)+
		bne	@f
		cmpi.b	#'l',(a0)+
		bne	@f
		cmpi.b	#'h',(a0)+
		beq	1f
		cmpi.b	#'z',(-1,a0)
		bne	@f
1:		cmpi.b	#'-',(1,a0)
@@:		rts


* 書庫解析中エラー処理 ------------------------ *

* メモリ不足
ana_memory_error:
		moveq	#MES_MARCM,d0
		bra	@f
* ファイル操作エラー
ana_file_error:
		moveq	#MES_MARCF,d0
		bra	@f
* 未対応書庫
ana_unknown_arc:
		moveq	#MES_NOARC,d0
@@:
		bsr	call_print_sub

		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		bra	set_status_0
**		rts

call_print_sub2:
		PUSH	d1-d7/a1-a6
		bra	@f
call_print_sub:
		PUSH	d1-d7/a1-a6
		jsr	(get_message)
		movea.l	d0,a0
@@:
		moveq	#MES_MARCE,d0
		moveq	#0,d6
		moveq	#1,d7
		suba.l	a1,a1
		jsr	(print_sub)
		POP	d1-d7/a1-a6
		rts


* 書庫解析/リスト登録下請け ------------------- *

* パス名中のディレクトリを登録する
regist_directory:
		tst.b	(a2)
		bne	@f
		rts
reg_dir_loop:
		cmpi.b	#'/',d0
		bne	@f
		bsr	reg_dir_found
@@:
		move.b	-(a2),d0
		bne	reg_dir_loop
		cmpi.b	#'/',(1,a2)
		bne	reg_dir_found
		rts

* バッファに同じディレクトリが存在しなかったら作る
* a2 = ' \abde\efgh[\]ijkl\ '
reg_dir_found:
		bsr	get_ma_buf
		movea.l	d0,a3
		movea.l	(MA_AFL_PTR,a3),a3
reg_dir_loop2:
		_IS_DIR a3
		beq	reg_dir_next

		lea	(1,a2),a0		;a0 = ' \abde\efgh\[i]jkl\ '
		lea	(AFL_FILENAME,a3),a1	;a1 = 'dirname\'
@@:
		move.b	(a0)+,d0
		cmpi.b	#'/',d0
		beq	reg_dir_compare
		cmp.b	(a1)+,d0
		beq	@b
reg_dir_next:
		_NEXT_BUF a3
		_IS_END_OF_BUF a3
		beq	reg_dir_loop2

		_DIR_FLG_ON a5
		bsr	copy_dirname
		bsr	copy_dirname2
		move.l	(dir_dummy_date,pc),(AFL_TIME_DATE,a5)

		_END_OF_BUF_FLG_OFF a5
		_NEXT_BUF a5
		_BUF_CLR
		rts
reg_dir_compare:
		tst.b	(a1)
		bne	reg_dir_next

		movea.l	a2,a0			;'aaa/bbb[/]dir'
		tst.b	(a0)
		bne	@f

		tst.b	(AFL_DIRNAME,a3)
		bne	reg_dir_next
		rts
@@:
		tst.b	-(a0)
		bne	@b
		addq.l	#1,a0
		lea	(AFL_DIRNAME,a3),a1
@@:
		cmpm.b	(a0)+,(a1)+
		bne	reg_dir_next
		cmpa.l	a0,a2
		bcc	@b
		tst.b	(a1)
		bne	reg_dir_next
		rts


* パス名コピー -------------------------------- *

* a2 = ' \abde\efgh[\]ijkl\ ' の状態で呼ぶと
*      ' [\abde\efgh\]ijkl\ ' を AFL_DIRNAME に複写する.

copy_dirname:
		tst.b	(a2)
		beq	copy_dirname_skip

		move.l	a2,d2
@@:		tst.b	-(a2)
		bne	@b
		addq.l	#1,a2			;dirname 先頭

		move.l	d2,d0
		sub.l	a2,d0
		cmpi	#48,d0
		bcc	copy_dirname_skip

	        lea     (AFL_DIRNAME,a5),a3
copy_dirname_loop:
		move.b	(a2)+,(a3)+
		cmp.l	a2,d2
		bcc	copy_dirname_loop

		movea.l	d2,a2
copy_dirname_skip:
		rts


* パス名コピーその２ -------------------------- *

* a2 = ' \abde[\]efgh\ijkl\ 'の状態で呼ぶと
*      ' \abde\[efgh\]ijkl\ 'をAFL_FILENAMEに複写する

copy_dirname2:
		bsr	inc_info_entrys_sum
		move.l	a2,d2
		addq.l	#1,a2			;a2 = ' \abde\[e]fgh\ijkl\ '
		lea	(AFL_FILENAME,a5),a3
		bra	@f
copy_dirname2_loop:
		move.b	d0,(a3)+
@@:
		move.b	(a2)+,d0
		cmpi.b	#'/',d0
		bne	copy_dirname2_loop

		clr.b	(a3)
		movea.l	d2,a2
		rts


* ファイル名コピー ---------------------------- *
* in	d0.l	ファイル文字数
*	a1.l	ファイル文字先頭

* 現在は長すぎるファイル名を無視しているが、いずれ
* (V)TwentyOne.sys の VFAT と同じ処理を行うようにしたい
* (展開ツールが対応しないと無意味だが).

copy_filename:
		cmpi	#18,d0
		bls	@f
		cmpi	#18+1+3,d0
		bhi	copy_fn_error
		cmpi.b	#'.',(-2,a1,d0.w)
		beq	@f
		cmpi.b	#'.',(-3,a1,d0.w)
		beq	@f
		cmpi.b	#'.',(-4,a1,d0.w)
		beq	@f
copy_fn_error:
		moveq	#-1,d0
		rts
@@:
		subq	#1,d0
		bmi	copy_fn_error

		move.l	a2,-(sp)
		lea	(AFL_FILENAME,a5),a2
copy_fn_loop:
		move.b	(a1)+,(a2)+
		dbra	d0,copy_fn_loop

		movea.l	(sp)+,a2
		moveq	#0,d0
		rts


* タイムスタンプ変換 -------------------------- *
* in	d0.l	UTC
* out	d0.l	DOS 形式の時刻

TZ:		.equ	-9			;JST-9

utc2dostime:
		PUSH	d1/d7/a0

* 地域時間に変換する
		subi.l	#TZ*60*60,d0

* 日数と秒数に分離する
		divu	#(24*60*60)/2,d0	;半日
		move.l	d0,d1
		clr	d1
		swap	d1
		lsr	#1,d0
		bcc	@f
		add.l	#(24*60*60)/2,d1	;秒数
@@:		ext.l	d0			;日数

* 時分秒を変換
		divu	#60*60,d1		;秒 | 時
		move	d1,d7
		clr	d1
		lsl	#6,d7			;%0000_0ttt_tt00_0000
		swap	d1
		divu	#60,d1			;秒 | 分
		or	d1,d7			;%0000_0ttt_ttff_ffff
		lsl	#5,d7			;%tttt_tfff_fff0_0000
		swap	d1
		lsr	#1,d1
		or	d1,d7			;%tttt_tfff_fffs_ssss
		swap	d7

* 年月日を変換
		add	#365,d0
		divu	#365*4+1,d0
		lsl	#2,d0			;年数(4 の倍数)
		move	#1970-1980-1+3,d7
		add	d0,d7
		clr	d0
		swap	d0
		divu	#365,d0			;日数(0 ～ 364) | 年数(0 ～ 3<4>)
		lea	(days_table,pc),a0
		move	#31<<8+28,(a0)
		subq	#3,d0
		bcs	@f			;平年
		beq	1f			;閏年
		move.l	#365<<16+.loww.(3-3),d0	;閏年の 12 月 31 日
1:		addq	#1,(a0)			;2 月は一日多い
@@:		add	d0,d7
		lsl	#4,d7			;%????_?yyy_yyyy_0000
		clr	d0
		swap	d0			;日数(0 ～ 365)
		moveq	#0,d1
@@:
		move.b	(a0)+,d1
		addq	#1,d7			;++月
		sub	d1,d0
		bcc	@b
		add	d1,d0
		lsl	#5,d7			;%yyyy_yyym_mmm0_0000
		addq	#1,d0
		or	d0,d7			;%yyyy_yyym_mmmd_dddd

		move.l	d7,d0
		POP	d1/d7/a0
		rts

days_table:	.dc.b	31,28,31,30,31,30,31,31,30,31,30,31
		.even

#	%yyyy_yyym_mmmd_dddd_tttt_tfff_fffs_ssss
#	bit 31～25	年-1980(0～127)
#	bit 24～21	月  (1～12 月)
#	bit 20～16	日  (1～31 日)
#	bit 15～11	時  (0～23 時)
#	bit 10～ 5	分  (0～59 分)
#	bit  4～ 0	秒/2(0～29 秒)


* Data Section -------------------------------- *

**		.data
		.even

subwin_ask:	SUBWIN	12,8,72,2,NULL,NULL


* Block Storage Section ----------------------- *

		.bss
		.even

ma_curdir_l:	.ds.b	70
ma_curdir_r:	.ds.b	70

* mintarc 管理構造体
ma_buf_l:	.ds.b	sizeof_MA		;┐
ma_buf_r:	.ds.b	sizeof_MA		;┘


		.end

* End of File --------------------------------- *
