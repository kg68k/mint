# rename.s - &rename-～
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

		.include	mrl.mac
		.include	mint.mac
		.include	window.mac
		.include	message.mac
		.include	sysval.def

		.include	fefunc.mac
		.include	doscall.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	copy_dir_name_a1_a2
		.xref	print_fileop_message
		.xref	print_write_protect_error
		.xref	lndrv_init,lndrv_pure_open
* mint.s
		.xref	search_cursor_file,search_mark_file
		.xref	set_status
		.xref	set_dir_name
		.xref	is_parent_directory_a4
		.xref	print_mark_information
		.xref	directory_reload,directory_reload_opp
		.xref	dos_drvctrl_d1
		.xref	AK_UP,AK_DOWN,AK_LEFT,AK_RIGHT
* outside.s
		.xref	dos_inpout
		.xref	break_check
		.xref	strcmp_a1_a2


* Constant ------------------------------------ *

EXT_MAX:	.equ	18


* Offset Table -------------------------------- *

		.offset	0
~win_no:	.ds	1
~o_datetime:
~o_date:	.ds	1
~o_time:	.ds	1
~n_datetime:
~n_date:	.ds	1
~n_time:	.ds	1
~o_attrib:	.ds.b	1
~n_attrib:	.ds.b	1
~o_filename:	.ds.b	FILENAME_MAX+1		;こっちは番兵不要
		.ds.b	1			;┐'.'(番兵)
~n_filename:	.ds.b	FILENAME_MAX+1		;┘
~n_date_buf:	.ds.b	1+(4+1)+(2+1)+(2+0)	;文字列
~n_time_buf:	.ds.b	1+(2+1)+(2+1)+(2+1)	;〃
		.even
sizeof_work:
* ここまで &rename-menu / &rename-marked-～ の両方で使用
		.even
~mark_file:	.ds.l	1			;最初のマークファイル
~cursor_file:	.ds.l	1			;カーソルファイルのアドレス
~ext_limit:	.ds.l	1			;拡張子置換のチェック用
~md_flag0:
~md_main:	.ds.b	1			;0=non 2=upper 4=capitalize 6=lower
~md_ext:	.ds.b	1			;〃
~md_readonly:	.ds.b	1			;0=non 2=on 4=off
~md_hidden:	.ds.b	1			;〃
~md_flag1:
~md_system:	.ds.b	1			;〃
~md_exec:	.ds.b	1			;〃
~md_datetime:
~md_date:	.ds.b	1			;$ff=年月日変更あり
~md_time:	.ds.b	1			;$ff=時分秒〃
~n_ext:		.ds.b	EXT_MAX+1
~c_filename:	.ds.b	FILENAME_MAX+1		;変更後のカーソル位置ファイル名
		.even
sizeof_work2:
* ここまで &rename-marked-files-or-directory だけが使用
		.text


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


*************************************************
*		&rename-menu			*
*************************************************

ren_menu_end0:
ren_mark_end0:
		moveq	#0,d0
		jmp	(set_status)
**		rts

＆rename_menu::
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_NODISK,a6),d0
		bne	ren_menu_end0

		tst	(＄oren)
		beq	@f
		movea.l	(PATH_BUF,a6),a4	;%oren 1 でマークファイルがあれば
		jsr	(search_mark_file)	;一括リネーム
		bpl	rename_marked_files_or_directory
@@:
		jsr	(search_cursor_file)
		cmpi.b	#$ff,(DIR_ATR,a4)
		beq	ren_menu_end0		;ファイル無し
		jsr	(is_parent_directory_a4)
		bne	ren_menu_end0		;".." はリネーム不可

		bsr	write_protect_check
		bne	write_protect_error	;書き込み禁止

		moveq	#MES_RENAM,d0
		bsr	ren_analyze_arg

		lea	(-sizeof_work,sp),sp
		lea	(sp),a5			;ローカルエリア先頭

		lea	(~o_filename,a5),a0	;ファイル名正規化
		lea	(DIR_NAME,a4),a1
		lea	(a0),a2
		bsr	copy_dir_name_a1_a2
		lea	(a0),a1
		lea	(~n_filename-1,a5),a2
		move.b	#'.',(a2)+		;ファイル名の直前に番兵を置く
		STRCPY	a1,a2

		bsr	get_stamp_atr		;タイムスタンプ/属性収得
		move.l	d0,(~o_datetime,a5)
		move.b	d1,(~o_attrib,a5)
		move.b	d1,(~n_attrib,a5)

		lea	(subwin_ren_menu,pc),a0
		lea	(ren_menu_str,pc),a1
		bsr	ren_print_subwin

		moveq	#1,d7
		bsr	ren_menu_print_info

		bsr	ren_color_yellow
		moveq	#0,d7
		bsr	ren_menu_print_info

		st	(~n_date_buf+1+4,a5)	;'-'/':' のかわりに $ff をセット
		st	(~n_date_buf+1+4+1+2,a5)
		st	(~n_time_buf+1+2,a5)
		st	(~n_time_buf+1+2+1+2,a5)

		moveq	#0*2,d7			;現在の位置(0*2～8*2)
*		moveq	#0,d6
*		move.b	(AK_DOWN),d6		;最初は行入力なので不要
ren_menu_loop:
		move.l	d7,d2
		lsr	#1,d2
		addq	#3,d2			;Y 座標

		move	(ren_menu_job_tbl,pc,d7.w),d0
		jsr	(ren_menu_job_tbl,pc,d0.w)
		cmpi.b	#CR,d6
		beq	ren_menu_go
		cmpi.b	#ESC,d6
		beq	ren_menu_cancel
		cmp.b	(AK_UP),d6
		beq	ren_menu_up
*		cmp.b	(AK_DOWN),d6
*		bne	ren_menu_loop
*ren_menu_down:
*		cmpi	#8*2,d7
*		beq	ren_menu_loop
		addq	#2,d7
		bra	ren_menu_loop
ren_menu_up:
*		tst	d7
*		beq	ren_menu_loop
		subq	#2,d7
		bra	ren_menu_loop

ren_menu_job_tbl:
@@:		.dc	ren_menu_fn-@b		;ファイル名変更
		.dc	ren_menu_all-@b		;大文字/小文字/キャピタライズ
		.dc	ren_menu_ext-@b		;〃 拡張子のみ
		.dc	ren_menu_ro-@b		;読み込み専用
		.dc	ren_menu_hid-@b		;隠し
		.dc	ren_menu_sys-@b		;システム
		.dc	ren_menu_exe-@b		;実行
		.dc	ren_menu_date-@b	;年月日
		.dc	ren_menu_time-@b	;時分秒

ren_menu_go:
		bsr	ren_win_close
		jsr	(ConsoleClear2)

		lea	(~n_date_buf+1,a5),a0
		bsr	ren_dateconv
		move.l	d0,(~n_datetime,a5)	;変更するタイムスタンプ

		bsr	rename_sub

		lea	(~o_filename,a5),a0
		addq.l	#1,d0
		beq	@f			;DOS _RENAME 失敗時は旧ファイル名のまま
		lea	(~n_filename,a5),a0
@@:
		bsr	update_dirlist
ren_menu_end:
		lea	(sizeof_work,sp),sp
		rts
ren_menu_cancel:
		bsr	ren_win_close
		bra	ren_menu_end


* 以下、行ごとの処理ルーチン ------------------ *
* in	d2.l	Y 座標
*	d6.b	前回のキー
*	a5.l	ローカルエリア
* out	d6.b	処理ルーチン脱出時のキー(CR/ESC/AK_UP/AK_DOWN)


* ファイル名変更 ------------------------------ *
* 備考:
*	一番上の行なので、d6.b = AK_UP を返さないこと.

ren_menu_fn:
		moveq	#0,d0			;d0.hw = 0
		moveq	#11+3,d1
		bsr	ren_locate

**		moveq	#0,d0
**		move	(~win_no,a5),d0
		move.l	#FILENAME_MAX<<16+RL_F_DOT+RL_F_DOWN+RL_F_RU+RL_F_RD,d1
		lea	(~n_filename,a5),a1
		jsr	(MintReadLine)

		moveq	#ESC,d6
		tst.l	d0
		bmi	ren_menu_fn_end
		moveq	#CR,d6
		tst.l	d0
		beq	ren_menu_fn_end
		move.b	(AK_DOWN),d6		;他は全部下移動
ren_menu_fn_end:
		rts


* 大文字化/小文字化/キャピタライズ ------------ *
* (ファイル名全体)

ren_menu_all_go:
		lea	(~n_filename,a5),a0
		bsr	ren_menu_ulc_conv
ren_menu_all:
		moveq	#9+3,d1
		bsr	ren_menu_ulc		;ここから開始
		cmpi.b	#CR,d6
		beq	ren_menu_all_go
		rts


* 大文字化/小文字化/キャピタライズ ------------ *
* (拡張子のみ)

ren_menu_ext_go:
		lea	(~n_filename,a5),a0
		bsr	get_last_period_a0
		bsr	ren_menu_ulc_conv
ren_menu_ext:
		moveq	#9+3,d1
		bsr	ren_menu_ulc		;ここから開始
		cmpi.b	#CR,d6
		beq	ren_menu_ext_go
		rts


* 大文字/小文字/キャピタライズ選択
* in	d1.w	X 座標(9+3)
*	d2.w	Y 座標
* out	d1.w	選択(9+3 or 9+8+3 or 9+8*2+3)
*	d3.l	9+8+3
*	d6.w	脱出時のキー

ren_menu_ulc:
		moveq	#9+8+3,d3
ren_menu_ulc_loop:
		PUSH	d1-d2
		bsr	ren_locate		;カーソル移動
		moveq	#8,d2
		bsr	ren_underline		;下線描画
		bsr	call_inpout2
		move.l	d0,d6
		bsr	ren_underline		;下線消去
		POP	d1-d2

		bsr	ren_exit_check
		beq	ren_menu_ulc_end	;終わり
		cmp.b	(AK_LEFT),d6
		beq	ren_menu_ulc_left
		cmp.b	(AK_RIGHT),d6
		beq	ren_menu_ulc_right
		cmpi.b	#SPACE,d6		;スペースは→と同じ
		bne	ren_menu_ulc_loop
ren_menu_ulc_right:
		cmp	d3,d1
		bls	@f
		moveq	#9+3,d1
		bra	ren_menu_ulc_loop	;左端にループ
@@:		addq	#8,d1
		bra	ren_menu_ulc_loop
ren_menu_ulc_left:
		cmp	d3,d1
		bcc	@f
		moveq	#9+8*2+3,d1
		bra	ren_menu_ulc_loop	;右端にループ
@@:		subq	#8,d1
		bra	ren_menu_ulc_loop
ren_menu_ulc_end:
		rts


* 大文字化/小文字化/キャピタライズ(実行)
ren_menu_ulc_conv:
		cmp	d3,d1			;cmpi #9+8+3,d1
		beq	ren_menu_lower
		bhi	ren_menu_capital
		bra	ren_menu_upper

ren_menu_upper_loop:
		andi.b	#$df,(a0)+
ren_menu_upper:
		bsr	skip_no_alphabet
		bne	ren_menu_upper_loop
		bra	ren_menu_print_fn

ren_menu_capital:
		moveq	#'.',d3
ren_menu_capital_loop:
		bsr	skip_no_alphabet
		beq	ren_menu_print_fn

		ori.b	#$20,(a0)+		;小文字化
		cmp.b	(-2,a0),d3
		bne	ren_menu_capital_loop
		andi.b	#$df,(-1,a0)		;先頭なら大文字化
		bra	ren_menu_capital_loop

ren_menu_lower_loop:
		ori.b	#$20,(a0)+
ren_menu_lower:
		bsr	skip_no_alphabet
		bne	ren_menu_lower_loop
		bra	ren_menu_print_fn

* ファイル名再表示
ren_menu_print_fn:
		PUSH	d0-d2/a1
		lea	(~n_filename,a5),a1
		moveq	#11+3,d1
		moveq	#3,d2
		bsr	ren_locate_print
		POP	d0-d2/a1
		rts


* 読み込み専用属性の変更 ---------------------- *

ren_menu_ro:
		moveq	#READONLY,d3		;ビット位置
		bra	ren_menu_atr


* 隠し属性の変更 ------------------------------ *

ren_menu_hid:
		moveq	#HIDDEN,d3		;ビット位置
		bra	ren_menu_atr


* システム属性の変更 -------------------------- *

ren_menu_sys:
		moveq	#SYSTEM,d3		;ビット位置
		bra	ren_menu_atr


* 実行属性の変更 ------------------------------ *

ren_menu_exe:
		moveq	#EXEC,d3		;ビット位置
		btst	#DIRECTORY,(~o_attrib,a5)
		bne	ren_menu_exe_end	;ディレクトリは変更出来ない
		bra	ren_menu_atr


ren_menu_atr:
		moveq	#9+3,d1
		bsr	ren_menu_atr_underline
ren_menu_atr_loop:
		bsr	call_inpout2
		move.l	d0,d6
		bsr	ren_exit_check
		beq	ren_menu_atr_end
		cmp.b	(AK_LEFT),d6
		beq	@f
		cmp.b	(AK_RIGHT),d6
		beq	@f
		cmpi.b	#SPACE,d6		;スペースは→と同じ
		bne	ren_menu_atr_loop
@@:
		lea	(str_off,pc),a1
		bchg	d3,(~n_attrib,a5)	;属性 on <-> off
		bne	@f
		addq.l	#str_on-str_off,a1
@@:
		PUSH	d1-d2
		moveq	#30+3,d1		;on/off 表示切り換え
		bsr	ren_locate_print
		POP	d1-d2
		bra	ren_menu_atr_loop
ren_menu_atr_end:
		bra	ren_menu_atr_underline
**		rts


ren_menu_atr_underline:
		PUSH	d1-d2
		bsr	ren_locate		;カーソル移動
		moveq	#15,d2
		bsr	ren_underline		;下線描画
		POP	d1-d2
ren_menu_exe_end:
		rts


* 年月日の変更 -------------------------------- *

ren_menu_date:
		lea	(~n_date_buf+1+2,a5),a0	;_1999-04-03_
		moveq	#0,d5			;   ^
		bra	ren_edit_datetime
**		rts


* 時分秒の変更 -------------------------------- *
* 備考:
*	一番下の行なので、d6.b = AK_DOWN を返さないこと.

ren_menu_time:
		lea	(~n_time_buf+1,a5),a0	;_12:00:00_
		move.b	(AK_DOWN),d5		; ^
		bra	ren_edit_datetime
**		rts


* ファイルの情報を全て表示する ---------------- *
* in	d7.l	0:エディット欄 1:初期設定欄
*	a5.l	ローカルエリア
* 備考:
*	呼び出し前に表示色を設定しておくこと.

ren_menu_print_info:
		PUSH	d0-d7/a0-a1

		lea	(~n_filename,a5),a1
		moveq	#3,d2
		sub	d7,d2
		moveq	#11+3,d1
		bsr	ren_locate_print	;ファイル名

		move.b	(~o_attrib,a5),d5
		moveq	#1<<DIRECTORY,d6
		and.b	d5,d6

		moveq	#30+3,d3
		tst	d7
		beq	@f
		moveq	#25+3,d3
@@:		moveq	#6-1,d2
		bsr	ren_menu_loc_pr2	;属性表示 Read only
		bsr	ren_menu_loc_pr2	;〃 Hidden
		bsr	ren_menu_loc_pr2	;〃 System

		lsr.b	#4,d5			;%xlad_vshr>>3>>4=%x
		bsr	ren_menu_print_info_on_off
		tst.b	d6
		beq	@f
		lea	(str_dir,pc),a1
@@:		bsr	ren_menu_loc_pr2_	;〃 Execution/Directory

		bsr	ren_datestr		;タイムスタンプを文字列に変換

		lea	(~n_date_buf+1,a5),a1
		moveq	#23+3-3,d3
		tst	d7
		beq	@f
		moveq	#10+3-3,d3
@@:		moveq	#10,d2
		bsr	ren_menu_loc_pr3	;年
		addq	#2,d3
		bsr	ren_menu_loc_pr3	;月
		bsr	ren_menu_loc_pr3	;日

*		lea	(~n_time_buf+1,a5),a1
		moveq	#25+3-3,d3
		tst	d7
		beq	@f
		moveq	#12+3-3,d3
@@:		moveq	#11,d2
		bsr	ren_menu_loc_pr3	;時
		bsr	ren_menu_loc_pr3	;分
		bsr	ren_menu_loc_pr3	;秒

		POP	d0-d7/a0-a1
		rts


ren_menu_print_info_on_off:
		lea	(str_off,pc),a1
		lsr.b	#1,d5
		bcc	@f
		addq.l	#str_on-str_off,a1
@@:		rts

ren_menu_loc_pr2:
		bsr	ren_menu_print_info_on_off
ren_menu_loc_pr2_:
		move.l	d3,d1
		addq	#1,d2
		bra	ren_locate_print
**		rts

ren_menu_loc_pr3:
		addq	#3,d3
		move.l	d3,d1
		bra	ren_locate_print
**		rts


*************************************************
*	&rename-marked-files-or-directory	*
*************************************************

＆rename_marked_files_or_directory::
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_NODISK,a6),d0
		bne	ren_mark_end0

		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		bmi	ren_mark_end0		;マーク無し
rename_marked_files_or_directory:

* ".." はマーク出来ないのでチェック不要

		bsr	write_protect_check
		bne	write_protect_error	;書き込み禁止

		moveq	#MES_ARENA,d0
		bsr	ren_analyze_arg

		lea	(-sizeof_work2,sp),sp
		lea	(sp),a5			;ローカルエリア先頭

		clr.l	(~md_flag0,a5)
		clr.l	(~md_flag1,a5)
		clr.b	(~n_ext,a5)
		move.b	#'.',(~n_filename-1,a5)	;ファイル名の直前に番兵を置く

		lea	(~o_filename,a5),a0	;ファイル名正規化
		lea	(DIR_NAME,a4),a1
		lea	(a0),a2
		bsr	copy_dir_name_a1_a2

		bsr	get_stamp_atr		;タイムスタンプ収得
		move.l	d0,(~o_datetime,a5)
		bsr	ren_datestr		;タイムスタンプを文字列に変換

		move.l	a4,(~mark_file,a5)

		lea	(subwin_ren_mark,pc),a0
		lea	(ren_mark_str,pc),a1
		bsr	ren_print_subwin

		bsr	ren_color_yellow

* 初期状態は全て "-------"
		lea	(ren_mark_x_tbl,pc),a0
		moveq	#2,d2			;Y
		moveq	#0,d1
		move.b	(a0)+,d1		;X
@@:
		lea	(str_bar10+10-33,pc),a1
		adda	d1,a1
		addq	#3,d1
		bsr	ren_locate_print
		addq	#1,d2
		move.b	(a0)+,d1		;X
		bne	@b

		moveq	#0*2,d7			;現在の位置(0*2～8*2)
*		moveq	#0,d6
*		move.b	(AK_DOWN),d6
ren_mark_loop:
		bsr	ren_mark_underline	;下線描画
		move.l	d7,d2
		lsr	#1,d2
		addq	#2,d2			;Y
		move	(ren_mark_job_tbl,pc,d7.w),d0
		jsr	(ren_mark_job_tbl,pc,d0.w)
		bsr	ren_mark_underline	;下線消去

		cmpi.b	#CR,d6
		beq	ren_mark_go
		cmpi.b	#ESC,d6
		beq	ren_mark_end
		cmp.b	(AK_UP),d6
		beq	ren_mark_up
*		cmp.b	(AK_DOWN),d6
*		bne	ren_mark_loop
*ren_mark_down:
		addq	#2,d7
		cmpi	#8*2,d7
		bls	ren_mark_loop
		moveq	#0*2,d7			;一番下で↓なら一番上に移動する
		bra	ren_mark_loop
ren_mark_up:
		subq	#2,d7
		bcc	ren_mark_loop
		moveq	#8*2,d7			;一番上で↑なら一番下に移動する
		bra	ren_mark_loop

ren_mark_job_tbl:
@@:		.dc	ren_mark_main-@b	;主ノード名
		.dc	ren_mark_ext-@b		;拡張子
		.dc	ren_mark_ro-@b		;読み込み専用
		.dc	ren_mark_hid-@b		;隠し
		.dc	ren_mark_sys-@b		;システム
		.dc	ren_mark_exe-@b		;実行
		.dc	ren_mark_date-@b	;年月日
		.dc	ren_mark_time-@b	;時分秒
		.dc	ren_mark_ext2-@b	;拡張子置換

ren_mark_underline:
		move.l	d7,d2
		lsr	#1,d2
		lea	(ren_mark_x_tbl,pc),a0
		adda.l	d2,a0
		addq	#2,d2			;Y
		moveq	#16,d1			;X
		bsr	ren_locate		
		cmpi	#8*2,d7
		beq	ren_mark_ul_end		;拡張子置換は下線なし
		moveq	#15,d2
		sub.b	(a0),d2
		neg.b	d2
		bra	ren_underline		;下線描画
ren_mark_ul_end:
		rts


ren_mark_go:
		bsr	ren_win_close
		jsr	(ConsoleClear2)

		lea	(~n_date_buf+1,a5),a0
		bsr	ren_dateconv
		move.l	d0,(~n_datetime,a5)	;変更するタイムスタンプ
		move.l	d0,(~o_datetime,a5)

		lea	(~n_ext,a5),a0
		STRLEN	a0,d0
		lea	(~n_filename+FILENAME_MAX-1,a5),a0
		suba.l	d0,a0			;旧ファイル名の拡張子位置が a0 より
		move.l	a0,(~ext_limit,a5)	;前なら置換可能

		jsr	(search_cursor_file)
		move.l	a4,(~cursor_file,a5)
		lea	(DIR_NAME,a4),a1
		lea	(~c_filename,a5),a2
		bsr	copy_dir_name_a1_a2

		move.l	(~mark_file,a5),a4
ren_mark_loop2:
		lea	(~o_filename,a5),a0	;ファイル名正規化
		lea	(DIR_NAME,a4),a1
		lea	(a0),a2
		bsr	copy_dir_name_a1_a2
		lea	(a0),a1
		lea	(~n_filename,a5),a2
		STRCPY	a1,a2

		bsr	ren_mark_ulc_exec	;ファイル名変更
		bsr	ren_mark_ext_exec	;拡張子置換

		bsr	get_stamp_atr		;タイムスタンプ/属性収得
		move.l	d0,(~o_datetime,a5)
		move.b	d1,(~o_attrib,a5)

		tst.b	(~md_time,a5)
		bne	@f
		move	d0,(~n_time,a5)		;時分秒の変更なし
@@:
		tst.b	(~md_date,a5)
		bne	@f
		swap	d0
		move	d0,(~n_date,a5)		;年月日の変更なし
@@:

REN_MARK_ATR:	.macro	flag,bit
		move.b	(flag,a5),d2
		beq	@skip			;変更なし
		moveq	#bit,d0
		bset	d0,d1			;とりあえず on にしてみる
		subq.b	#2,d2
		beq	@skip
		bclr	d0,d1			;やっぱり off だった
@skip:
		.endm

		REN_MARK_ATR	~md_readonly,READONLY
		REN_MARK_ATR	~md_hidden,HIDDEN
		REN_MARK_ATR	~md_system,SYSTEM
		btst	#DIRECTORY,d1
		bne	@f			;ディレクトリの実行属性は変更出来ない
		REN_MARK_ATR	~md_exec,EXEC
@@:
		move.b	d1,(~n_attrib,a5)

		bsr	rename_sub

		cmpa.l	(~cursor_file,a5),a4
		bne	@f
		addq.l	#1,d0
		beq	@f
		lea	(~n_filename,a5),a0	;カーソル位置ファイル名を更新
		lea	(~c_filename,a5),a1
		STRCPY	a0,a1
@@:
		jsr	(break_check)
		bmi	ren_mark_loop2_end
		lea	(sizeof_DIR,a4),a4
		jsr	(search_mark_file)
		beq	ren_mark_loop2
ren_mark_loop2_end:
		lea	(~c_filename,a5),a0
		bsr	update_dirlist
@@:
		lea	(sizeof_work2,sp),sp
		rts
ren_mark_end:
		bsr	ren_win_close
		bra	@b


* 以下、行ごとの処理ルーチン ------------------ *
* in	d2.l	Y 座標
*	d6.b	前回のキー
*	a5.l	ローカルエリア
* out	d6.b	処理ルーチン脱出時のキー(CR/ESC/AK_UP/AK_DOWN)

* 主ノード名変更 ------------------------------ *
* (大文字化/小文字化/キャピタライズ)
* 備考:
*	d6.b = AK_UP を返してもよい.

ren_mark_main:
		lea	(~md_main,a5),a0
ren_mark_main_loop:
		bsr	ren_mark_ulc
*		cmp.b	(AK_UP),d6
*		beq	ren_mark_main_loop	;↑を無視する
ren_mark_ulc_end:
		rts


* 拡張子変更 ---------------------------------- *
* (大文字化/小文字化/キャピタライズ)

ren_mark_ext:
		lea	(~md_ext,a5),a0
		bra	ren_mark_ulc

ren_mark_ulc:
		bsr	call_inpout2
		move.l	d0,d6
		bsr	ren_exit_check
		beq.s	ren_mark_ulc_end
		cmp.b	(AK_LEFT),d6
		beq	ren_mark_ulc_l
		cmp.b	(AK_RIGHT),d6
		beq	ren_mark_ulc_r
		cmpi.b	#SPACE,d6		;スペースは→と同じ
		bne	ren_mark_ulc
ren_mark_ulc_r:
		addq.b	#2,(a0)
		cmpi.b	#6,(a0)
		bls	@f
		clr.b	(a0)
		bra	@f
ren_mark_ulc_l:
		subq.b	#2,(a0)
		bcc	@f
		addq.b	#2+6,(a0)
@@:
		moveq	#0,d0			;変更モードの表示を更新
		move.b	(a0),d0
		lea	(@f,pc,d0.w),a1
		adda	(a1),a1
		moveq	#26+3,d1
		bsr	ren_locate_print
		bra	ren_mark_ulc
@@:
		.dc	str_bar7-$
		.dc	str_upper-$
		.dc	str_capital-$
		.dc	str_lower-$


* 読み込み専用属性の変更 ---------------------- *

ren_mark_ro:
		lea	(~md_readonly,a5),a0
		bra	ren_mark_atr


* 隠し属性の変更 ------------------------------ *

ren_mark_hid:
		lea	(~md_hidden,a5),a0
		bra	ren_mark_atr


* システム属性の変更 -------------------------- *

ren_mark_sys:
		lea	(~md_system,a5),a0
		bra	ren_mark_atr


* 実行属性の変更 ------------------------------ *

ren_mark_exe:
		lea	(~md_exec,a5),a0
		bra	ren_mark_atr


ren_mark_atr:
		bsr	call_inpout2
		move.l	d0,d6
		bsr	ren_exit_check
		beq	ren_mark_atr_end
		cmp.b	(AK_LEFT),d6
		beq	ren_mark_atr_l
		cmp.b	(AK_RIGHT),d6
		beq	ren_mark_atr_r
		cmpi.b	#SPACE,d6		;スペースは→と同じ
		bne	ren_mark_atr
ren_mark_atr_r:
		addq.b	#2,(a0)
		cmpi.b	#4,(a0)
		bls	@f
		clr.b	(a0)
		bra	@f
ren_mark_atr_l:
		subq.b	#2,(a0)
		bcc	@f
		addq.b	#2+4,(a0)
@@:
		moveq	#0,d0			;変更モードの表示を更新
		move.b	(a0),d0
		lea	(@f,pc,d0.w),a1
		adda	(a1),a1
		moveq	#28+3,d1
		bsr	ren_locate_print
		bra	ren_mark_atr
@@:
		.dc	str_bar5-$
		.dc	str_on5-$
		.dc	str_off5-$

ren_mark_atr_end:
ren_mark_date_end:
ren_mark_time_end:
		rts


* 年月日の変更 -------------------------------- *

ren_mark_date:
		bsr	call_inpout2
		move.l	d0,d6
ren_mark_date_key:
		bsr	ren_exit_check
		beq.s	ren_mark_date_end
		cmp.b	(AK_LEFT),d6
		beq	ren_mark_date_cancel
		cmp.b	(AK_RIGHT),d6
		bne	ren_mark_date
*ren_mark_date_edit:
		st	(~md_date,a5)

		moveq	#23+3,d1
		lea	(str_hyphen,pc),a0
		lea	(~n_date_buf+1,a5),a1
		bsr	ren_mark_print_date_time

		st	(~n_date_buf+1+4,a5)
		st	(~n_date_buf+1+4+1+2,a5)

		lea	(~n_date_buf+1+2,a5),a0	;_1999-04-03_
		moveq	#-1,d5			;   ^
		not	d5
		bsr	ren_edit_datetime

		clr.b	(~n_date_buf+1+4,a5)
		clr.b	(~n_date_buf+1+4+1+2,a5)

		cmp.b	(AK_LEFT),d6
		beq	ren_mark_date
		bra	ren_mark_date_key

ren_mark_date_cancel:
		clr.b	(~md_date,a5)

		moveq	#0,d3
		bsr	ren_mark_clr_date_time
		bra	ren_mark_date


* 時分秒の変更 -------------------------------- *

ren_mark_time:
		bsr	call_inpout2
		move.l	d0,d6
ren_mark_time_key:
		bsr	ren_exit_check
		beq.s	ren_mark_time_end
		cmp.b	(AK_LEFT),d6
		beq	ren_mark_time_cancel
		cmp.b	(AK_RIGHT),d6
		bne	ren_mark_time
*ren_mark_time_edit:
		st	(~md_time,a5)

		moveq	#25+3,d1
		lea	(str_colon,pc),a0
		lea	(~n_time_buf+1,a5),a1
		bsr	ren_mark_print_date_time

		st	(~n_time_buf+1+2,a5)
		st	(~n_time_buf+1+2+1+2,a5)

		lea	(~n_time_buf+1,a5),a0	;_12:00:00_
		moveq	#-1,d5			; ^
		not	d5
		bsr	ren_edit_datetime

		clr.b	(~n_time_buf+1+2,a5)
		clr.b	(~n_time_buf+1+2+1+2,a5)

		cmp.b	(AK_LEFT),d6
		beq	ren_mark_time
		bra	ren_mark_time_key

ren_mark_time_cancel:
		clr.b	(~md_time,a5)

		moveq	#2,d3
		bsr	ren_mark_clr_date_time
		bra	ren_mark_time


ren_mark_print_date_time:
		bsr	ren_locate_print	;年 / 時
		bsr	@f
		bsr	ren_print		;月 / 分
		bsr	@f
		bra	ren_print		;日 / 秒
**		rts
@@:
		bsr	ren_color_white
		exg	a0,a1
		bsr	ren_print		;'-' / ':'
		subq.l	#2,a1
		exg	a0,a1
		bra	ren_color_yellow
**		rts

ren_mark_clr_date_time:
		bsr	ren_color_white
		moveq	#23+3,d1
		add	d3,d1
		lea	(str_spc10,pc),a1
		adda.l	d3,a1
		move.l	d1,-(sp)
		bsr	ren_locate_print	;白の '-'/':' を消してから
		bsr	ren_color_yellow
		move.l	(sp)+,d1
		lea	(str_bar10,pc),a1
		adda.l	d3,a1
		bra	ren_locate_print	;'--------' を表示
**		rts


* 拡張子の置換 -------------------------------- *
* 備考:
*	d6.b = AK_DOWN を返してもよい.

ren_mark_ext2:
		moveq	#0,d0			;d0.hw = 0
		moveq	#15+3,d1
		bsr	ren_locate

**		moveq	#0,d0
**		move	(~win_no,a5),d0
		move.l	#EXT_MAX<<16+RL_F_UP+RL_F_DOWN,d1
		lea	(~n_ext,a5),a1
		jsr	(MintReadLine)

		move.b	(AK_DOWN),-(sp)
		move.b	(AK_UP),(1,sp)
		move	#ESC<<8+CR,-(sp)
		move.b	(1,sp,d0.l),d6
		addq.l	#4,sp
		rts
**		move.b	(@f+1,pc,d0.l),d6
**		rts
**@@:		.dc.b	ESC,CR,FK_DOWN,FK_UP


* 大文字化/小文字化/キャピタライズの実行 ------ *
* break	d0-d3/a0-a1

ren_mark_ulc_exec:
		move.b	(~md_main,a5),d1
		cmp.b	(~md_ext,a5),d1
		lea	(~n_filename,a5),a0
		beq	ren_mark_ulc_conv	;ファイル名全体を変更

		lea	(a0),a1
		bsr	get_last_period_a0
		exg	a0,a1			;a1 = 拡張子
		move.b	(a1),d2
		clr.b	(a1)
		bsr	ren_mark_ulc_conv	;主ファイル名を変更
		move.b	d2,(a1)
		lea	(a1),a0
		move.b	(~md_ext,a5),d1
		bra	ren_mark_ulc_conv	;拡張子を変更
**		rts

* in	d1.b	モード(0=non 2=upper 4=capitalize 6=lower)
*	a0.l	文字列のアドレス
* break	d0-d1/d3/a0

ren_mark_ulc_conv:
		tst.b	d1
		beq	ren_mark_ulc_conv_end
		subq.b	#4,d1
		bhi	ren_mark_lower
		beq	ren_mark_capital
		bra	ren_mark_upper

ren_mark_upper_loop:
		andi.b	#$df,(a0)+
ren_mark_upper:
		bsr	skip_no_alphabet
		bne	ren_mark_upper_loop
ren_mark_ulc_conv_end:
		rts

ren_mark_lower_loop:
		ori.b	#$20,(a0)+
ren_mark_lower:
		bsr	skip_no_alphabet
		bne	ren_mark_lower_loop
		rts

ren_mark_capital:
		moveq	#'.',d3
ren_mark_capital_loop:
		bsr	skip_no_alphabet
		beq	ren_mark_ulc_conv_end

		ori.b	#$20,(a0)+		;小文字化
		cmp.b	(-2,a0),d3
		bne	ren_mark_capital_loop
		andi.b	#$df,(-1,a0)		;先頭なら大文字化
		bra	ren_mark_capital_loop


* 拡張子置換の実行 ---------------------------- *
* break	d0/a0-a1

ren_mark_ext_exec:
		lea	(~n_ext,a5),a1
		tst.b	(a1)
		beq	ren_mark_ext_end

		lea	(~n_filename,a5),a0
		bsr	get_last_period_a0
		cmpi.b	#$20,(a1)
		bls	ren_mark_ext_delete

		cmpa.l	(~ext_limit,a5),a0
		bhi	ren_mark_ext_end	;新しい拡張子が長すぎて置換できない

		move.b	#'.',(a0)+		;置換
		STRCPY	a1,a0
ren_mark_ext_end:
		rts
ren_mark_ext_delete:
		clr.b	(a0)			;拡張子削除
		rts


* リネーム本体 -------------------------------- *
* in	a5.l	ローカルエリア
* out	d0.l	 0:正常終了
*		-1:DOS _RENAME でエラーが発生した
*		-2:それ以外のエラーが発生した

rename_sub::
		PUSH	d1-d7/a0-a4
		moveq	#0,d3			;負数=DOS _RENAME でエラー
		moveq	#0,d4			;負数=エラー有り
		lea	(~o_filename,a5),a1
		lea	(~n_filename,a5),a2

		move.l	#(WHITE+EMPHASIS)<<16+MES_RENAF,d0
		btst	#DIRECTORY,(~o_attrib,a5)
		beq	@f
		addq	#MES_RENAD-MES_RENAF,d0
@@:		lea	(a1),a0
		jsr	(print_fileop_message)

		jsr	(strcmp_a1_a2)
		sne	d6			;d6=$ff:_RENAME 必要
		beq	@f
.if 0
		GETMES	MES_RENTO
		move.l	d0,-(sp)
		DOS	_PRINT
		pea	(a2)
		DOS	_PRINT
		addq.l	#8,sp
.else
		move.l	#WHITE<<16+MES_RENTO,d0
		lea	(a2),a0			;ファイル名を変更する場合は
		jsr	(print_fileop_message)	;" -> " と新ファイル名も表示
.endif
@@:

* タイムスタンプを変更するには DOS _OPEN で書き込みオープンを
* 行うが、システム属性・読み込み専用属性が設定されているファイル
* や、ディレクトリ・ボリュームラベルはエラーになるので、ここで
* 強制的に普通のファイルにする.
		moveq	#1<<SYSTEM+1<<READONLY+1<<DIRECTORY+1<<VOLUME,d1
		move.l	(~n_datetime,a5),d7
		cmp.l	(~o_datetime,a5),d7
		sne	d5			;d5=$ff:_FILEDATE 必要
		bne	@f

* ファイル名を変更するには DOS _RENAME を使うが、システム属性・
* 読み込み専用属性が設定されているファイルはエラーになるので、
* ここで強制的に属性を取り除く.
		moveq	#1<<SYSTEM+1<<READONLY,d1
		tst.b	d6
		beq	rename_sub_skip_chmod
@@:
		move.b	d1,d0
		and.b	(~o_attrib,a5),d0
		beq	rename_sub_skip_chmod	;ファイル属性は問題なし

* ここで一時的に変更する属性を、目的の属性をベースにして設定
* すると、「読み込み専用ファイルのタイムスタンプを変更して
* 隠しファイルにする」といったケースで DOS _CHMOD を一度だけ
* で済ますことが出来る.
		not.b	d1
		and.b	(~n_attrib,a5),d1
**		ori.b	#1<<ARCHIVE,d1		;なくても平気

		move	d1,-(sp)
		pea	(a1)			;~o_filename
		DOS	_CHMOD
		addq.l	#6,sp
		or.l	d0,d4
		tst.l	d0
		bmi	@f
		move.b	d1,(~o_attrib,a5)
@@:
rename_sub_skip_chmod:
		tst.b	d6
		beq	@f
		pea	(a2)			;~n_filename
		pea	(a1)			;~o_filename
		DOS	_RENAME			;ファイル名変更
		addq.l	#8,sp
		or.l	d0,d4
		or.l	d0,d3
**		tst.l	d0			;直前まで d3=0 なので省略可能
		bmi	@f
		lea	(a2),a1			;バッファ上のファイル名を書き換える
		lea	(DIR_NAME,a4),a2
		jsr	(set_dir_name)
		lea	(~n_filename,a5),a1
@@:
* a1 = 対象ファイル名
* (通常は ~n_filename、_RENAME 失敗時は ~o_filename)
		tst.b	d5
		beq	@f
		move	#WOPEN,-(sp)
		pea	(a1)			;~n_filename
		jsr	(lndrv_pure_open)	;DOS _OPEN
		addq.l	#6,sp
		or.l	d0,d4
		tst.l	d0
		bmi	@f
		move.l	d7,-(sp)
		move	d0,-(sp)
		DOS	_FILEDATE		;タイムスタンプ変更
		or.l	d0,d4
		DOS	_CLOSE
		addq.l	#6,sp
@@:
		moveq	#0,d1
		move.b	(~n_attrib,a5),d1
		cmp.b	(~o_attrib,a5),d1
		beq	@f
		move	d1,-(sp)		;最後に目的のファイル属性に変更する
		pea	(a1)
		DOS	_CHMOD
		addq.l	#6,sp
		or.l	d0,d4
@@:
		or.l	d3,d4
		bmi	rename_sub_error

		jsr	(PrintCompleted)
		moveq	#0,d0
rename_sub_end:
		POP	d1-d7/a0-a4
		rts

rename_sub_error:
		jsr	(PrintFalse)
		moveq	#-1,d0
		tst.l	d3
		bmi	rename_sub_end		;DOS _RENAME でエラー
		moveq	#-2,d0
		bra	rename_sub_end		;その他のエラー


* タイムスタンプ/属性収得 --------------------- *

* ファイル(or ディレクトリ)のタイムスタンプと属性を調べる.
* in	a0.l	ファイル名
*	a4.l	ディレクトリバッファ
* out	d0.l	タイムスタンプ(DOS _FILEDATE 形式)
*	d1.b	ファイル属性

.ifndef GET_STAMP_ATR_BY_DOS_CALL
get_stamp_atr:
		moveq	#$7f,d1
		and.b	(DIR_ATR,a4),d1
		bset	#ARCHIVE,d1
		bne	@f
		tas	d1			;アーカイブがオフなら実行可能
@@:
		btst	#DIRECTORY,d1
		beq	@f
		andi.b	#$ff.eor.(1<<EXEC+1<<ARCHIVE),d1
		btst	#LINK,d1
		beq	@f			;リンクディレクトリはファイル扱い
		eori.b	#1<<ARCHIVE+1<<DIRECTORY,d1
@@:
		move.l	(DIR_TIME,a4),d0
		swap	d0
		rts

.else
get_stamp_atr:
		lea	(-54,sp),sp
		move	#$ff,-(sp)
		pea	(a0)
		pea	(6,sp)
		.xref	 lndrv_link_files
		jsr	(lndrv_link_files)	;DOS _FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	@f

		move.l	(FILES_Time,sp),d0
		swap	d0
		moveq	#0,d1
		move.b	(FILES_FileAtr,sp),d1
		bra	get_stamp_atr_end
@@:
		move.l	d2,-(sp)
		move	#-1,-(sp)
		pea	(a0)
		DOS	_CHMOD
		moveq	#1<<ARCHIVE,d1		;ダミーの属性
		tst.l	d0
		bmi	@f
		move.b	d0,d1
@@:
		clr	(4,sp)			;ROPEN
		jsr	(lndrv_pure_open)	;DOS _OPEN
		tst.l	d0
		bmi	get_stamp_atr_error
		clr.l	(sp)			;clr.l (2,sp)
		move	d0,(sp)
		DOS	_FILEDATE
		move.l	d0,d2
		DOS	_CLOSE
		tst.l	d2
		bpl	@f
get_stamp_atr_error:
		moveq	#0,d2			;ダミーのタイムスタンプ
@@:
		addq.l	#6,sp
		move.l	d2,d0
		move.l	(sp)+,d2
get_stamp_atr_end:
		lea	(54,sp),sp
		rts
.endif


* Subroutine ---------------------------------- *

* 'A'～'Z'、'a'～'z' 以外の文字を飛ばす
* in	a0.l	文字列のアドレス
* out	a0.l	上記文字を飛ばした後のアドレス
*		一文字もなければ末尾の NUL を指す
* break	d0

skip_no_alphabet:
		move.b	(a0)+,d0
		ble	@f
		ori.b	#$20,d0
		cmpi.b	#'a',d0
		bcs	skip_no_alphabet	;制御記号/記号/数字
		cmpi.b	#'z',d0
		bls	skip_no_alphabet_end	;A-Za-z
		bra	skip_no_alphabet	;記号
@@:
		beq	skip_no_alphabet_end	;終わり
		cmpi.b	#$a0,d0
		bcs	@f
		cmpi.b	#$e0,d0
		bcs	skip_no_alphabet	;片仮名
@@:		move.b	(a0)+,d0
		bne	skip_no_alphabet
skip_no_alphabet_end:
		move.b	-(a0),d0
		rts


* ウィンドウ表示関係

ren_locate_print:
		bsr	ren_locate
ren_print:
		jmp	(WinPrint)
**		rts

ren_locate:
		move	(~win_no,a5),d0
		jmp	(WinSetCursor)
**		rts

ren_color_white:
		moveq	#WHITE,d1
		bra	@f
ren_color_yellow:
		moveq	#YELLOW,d1
@@:
		move	(~win_no,a5),d0
		jmp	(WinSetColor)
**		rts

ren_underline:
		move	(~win_no,a5),d0
		moveq	#YELLOW,d1
		jmp	(WinUnderLine2)
**		rts

ren_reverse_char:
		move	(~win_no,a5),d0
		jmp	(WinReverseChar)
**		rts


* キー入力関係

call_inpout2:
		jmp	(dos_inpout)
**		rts

ren_exit_check:
		cmpi.b	#CR,d6
		beq	@f
		cmpi.b	#ESC,d6
		beq	@f
		cmp.b	(AK_UP),d6
		beq	@f
		cmp.b	(AK_DOWN),d6
@@:		rts


* タイムスタンプの編集
* in	d5.b	無視するキー(通常は 0 にする)
*	d5.hw	-1 ならバッファ左端での←で終了する
*	a0.l	編集バッファのアドレス
*	a5.l	ローカルエリア
* out	d6.l	終了時のキー
* break	d0/d1/a0

ren_edit_datetime:
		moveq	#25+3,d1
ren_edit_dt_loop:
		bsr	ren_locate
		bsr	ren_reverse_char	;カーソル位置反転
		bsr	call_inpout2
		move.l	d0,d6
		bsr	ren_reverse_char	;反転を戻す

		cmp.b	d5,d6			;&rename-menu で時分秒の編集時は
		beq	ren_edit_dt_loop	;↓を無視する
		bsr	ren_exit_check
		beq	ren_edit_dt_end
		cmp.b	(AK_LEFT),d6
		beq	ren_edit_dt_left
		cmp.b	(AK_RIGHT),d6
		beq	ren_edit_dt_right
		cmpi.b	#'0',d6
		bcs	ren_edit_dt_loop
		cmpi.b	#'9',d6
		bhi	ren_edit_dt_loop

		move.b	d6,(a0)
		move.l	d1,-(sp)
		move	d6,d1
		move	(~win_no,a5),d0
		jsr	(WinPutChar)
		move.l	(sp)+,d1
ren_edit_dt_right:
		tst.b	(1,a0)
		beq	ren_edit_dt_loop	;末尾
		bpl	@f
		addq	#1,d1			;'-'/':' を飛ばす
		addq.l	#1,a0
@@:
		addq	#1,d1			;次の文字
		addq.l	#1,a0
		bra	ren_edit_dt_loop
ren_edit_dt_left:
		subq	#1,d1			;前の文字
		tst.b	-(a0)
		bne	@f
		tst.l	d5
		bmi	ren_edit_dt_end		;&rename-marked-～ なら終了
		bra	@b			;先頭だったので戻す
@@:
		bpl	ren_edit_dt_loop
		subq	#1,d1
		subq.l	#1,a0			;'-'/':' を飛ばす
		bra	ren_edit_dt_loop
ren_edit_dt_end:
		rts


* タイムスタンプの数値→文字列変換
* in	a5.l	ローカルエリア
* break	d0/d2/a0

ren_datestr:
		lea	(~n_date_buf,a5),a0	;タイムスタンプを文字列に変換
		clr.b	(a0)+
		move	(~o_date,a5),d2
		rol	#7,d2
		moveq	#$7f,d0
		and	d2,d0
		addi	#1980,d0
		FPACK	__LTOS			;西暦四桁
		clr.b	(a0)+
		rol	#4,d2
		moveq	#$f,d0			;月二桁
		bsr	ren_datestr_dec2
		rol	#5,d2
		moveq	#$1f,d0			;日〃
		bsr	ren_datestr_dec2

		lea	(~n_time_buf,a5),a0	;タイムスタンプを文字列に変換
		clr.b	(a0)+
		move	(~o_time,a5),d2
		rol	#5,d2
		moveq	#$1f,d0			;時二桁
		bsr	ren_datestr_dec2
		rol	#6,d2
		moveq	#$3f,d0			;分〃
		bsr	ren_datestr_dec2
		rol	#5+1,d2
		moveq	#$1f<<1,d0		;秒〃
		bra	ren_datestr_dec2
**		rts

ren_datestr_dec2:
		and	d2,d0
		divu	#10,d0
		addi.l	#'0'<<16+'0',d0
		move.b	d0,(a0)+
		swap	d0
		move.b	d0,(a0)+
		clr.b	(a0)+
		rts


* 日時の文字列→数値変換
* in	a0.l	文字列形式の年月日/時分秒
*		.dc.b	'1999',$ff,'04',$ff,'05',0
*		.dc.b	  '03',$ff,'40',$ff,'50',0
* out	d0.l	数値形式(DOS _FILEDATE 形式)のタイムスタンプ

ren_dateconv:
		PUSH	d1-d2/a0-a1
		FPACK	__STOL
		subi	#1980,d0
		moveq	#$7f,d1
		and	d0,d1			;年

		lea	(ren_dateconv_tbl,pc),a1
ren_dateconv_loop:
		addq.l	#1,a0
		FPACK	__STOL
		move.b	(a1)+,d2
		bpl	@f
		lsr	#1,d0			;秒は二で割る
		not.b	d2
@@:		and.b	d2,d0
@@:
		add.l	d1,d1
		lsr.b	#1,d2
		bne	@b
		or.b	d0,d1			;月/日 時/分/秒
		tst.b	(a1)
		bne	ren_dateconv_loop

		move.l	d1,d0
		POP	d1-d2/a0-a1
		rts

ren_dateconv_tbl:
		.dc.b	$f,$1f,$1f,$3f,.not.$1f
		.dc.b	0
		.even


* ファイル名の拡張子のアドレスを得る.
* in	a0.l	ファイル名
* out	d0.l	拡張子のアドレス(0 なら拡張子なし)
*	a0.l	拡張子のアドレス
*		拡張子がない場合は文字列の末尾(NUL)
*	ccrZ	<tst.l d0> の結果

get_last_period_a0:
		moveq	#0,d0
		cmpi.b	#'.',(a0)
		bne	@f
		addq.l	#1,a0			;先頭の '.' は拡張子ではない
@@:
		tst.b	(a0)
		beq	@f
		cmpi.b	#'.',(a0)+
		bne	@b
		move.l	a0,d0
		subq.l	#1,d0			;拡張子あり
		bra	@b
@@:
		tst.l	d0
		beq	@f			;拡張子なし(a0 は NUL を指す)
		movea.l	d0,a0
@@:		rts


* ライトプロテクト関係

write_protect_check:
		move	(PATH_DRIVENO,a6),d1
		jsr	(dos_drvctrl_d1)
		btst	#DRV_PROTECT,d0
update_dirlist_end:
		rts

write_protect_error:
		jmp	(print_write_protect_error)
**		rts


* ディレクトリ再表示
* in	a0.l	カーソル位置ファイル名
* 備考:
*	fileop.s の update_opp_dirlist とは違い、
*	反対側ウィンドウが違うパスの時は何も呼び出さない.

update_dirlist:
		jsr	(directory_reload)
		jsr	(print_mark_information)

		lea	(PATH_DIRNAME,a6),a1
		movea.l	(PATH_OPP,a6),a2
		addq.l	#PATH_DIRNAME,a2
		jsr	(strcmp_a1_a2)
		bne.s	update_dirlist_end

		jsr	(directory_reload_opp)
		jsr	(ReverseCursorBarOpp)
		jmp	(print_mark_information)
**		rts


* サブウィンドウ表示 -------------------------- *

* in	d7.l	タイトルのアドレス
*	a0.l	サブウィンドウ構造体のアドレス
*	a1.l	ウィンドウ内に表示する文字列のアドレス(ASCIIZ の並び)
*	a5.l	ローカルエリア
* break	d0-d2/a1

ren_print_subwin:
		move.l	d7,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		move	d0,(~win_no,a5)

* ウィンドウの中身を表示する
		moveq	#2,d2			;Y
@@:
		moveq	#3,d1			;X
		bsr	ren_locate_print
		addq	#1,d2
		tst.b	(a1)
		bne	@b
		rts

* サブウィンドウ消去 -------------------------- *

ren_win_close:
		move	(~win_no,a5),d0
		jmp	(WinClose)
**		rts


* 引数解析 ------------------------------------ *

* 引数を解析する
* in	d0.l	サブウィンドウ標準タイトルのメッセージ番号
*	d7.l	引数の数
* out	d7.l	サブウィンドウのタイトル
* break	d0/a0-a1
* 備考:
*	引数バッファを確保する.
*	lndrv_init を呼び出す.

ren_analyze_arg:
		jsr	(lndrv_init)
		jsr	(get_message)

		exg	d0,d7
		bra	ren_ana_arg_next
ren_ana_arg_loop:
		lea	(a0),a1
		cmpi.b	#'-',(a1)+
		bne	ren_ana_arg_skip
		cmpi.b	#'t',(a1)+
		bne	ren_ana_arg_skip
*ren_ana_arg_option_t:
@@:		tst.b	(a1)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d0
		bcc	@b
		bra	ren_ana_arg_end		;文字列がない
@@:		lea	(-1,a1),a0
		move.l	a0,d7
ren_ana_arg_skip:
		tst.b	(a0)+
		bne	ren_ana_arg_skip
ren_ana_arg_next:
		subq.l	#1,d0
		bcc	ren_ana_arg_loop
ren_ana_arg_end:
		moveq	#1,d0
		jmp	(set_status)
**		rts


* Data  Section ------------------------------- *

*		.data
		.even

subwin_ren_menu:
		SUBWIN	28,6,40,11,NULL,NULL

subwin_ren_mark:
		SUBWIN	28,6,40,10,NULL,NULL

ren_menu_str:
		.dc.b	'File name',0
		.dc.b	'          [                      ]',0
		.dc.b	'Main&Ext. upper   lower   capital',0
		.dc.b	'Extension upper   lower   capital',0
		.dc.b	'Attribute Read only          [   ]',0
		.dc.b	'          Hidden             [   ]',0
		.dc.b	'          System             [   ]',0
		.dc.b	'          Execution          [   ]',0
		.dc.b	'Date          -  -    [    -  -  ]',0
		.dc.b	'Time          :  :      [  :  :  ]',0
		.dc.b	0

ren_mark_str:		;012345678901234567890123456789012
		.dc.b	' File name :  Main       [       ]',0
		.dc.b	'              Extension  [       ]',0
		.dc.b	' Attribute :  Readonly     [     ]',0
		.dc.b	'              Hidden       [     ]',0
		.dc.b	'              System       [     ]',0
		.dc.b	'              Execution    [     ]',0
		.dc.b	' Stamp     :  Date    [          ]',0
		.dc.b	'              Time      [        ]',0
		.dc.b	' Extension :  [                  ]',0
		.dc.b	0

* 上で定義しているウィンドウ内文字列の [] のなかの左端桁位置.
ren_mark_x_tbl:	.dc.b	26,26,28,28,28,28,23,25,0

str_off:	.dc.b	'off',0
str_on:		.dc.b	'on ',0
str_dir:	.dc.b	'dir',0

str_on5:	.dc.b	' on  ',0
str_off5:	.dc.b	' off ',0

str_upper:	.dc.b	' upper ',0
str_capital:	.dc.b	'capital',0
str_lower:	.dc.b	' lower ',0

str_spc10:	.dc.b	'          ',0
str_bar10:	.dc.b	'----------',0
str_bar8:	.equ	str_bar10+2
str_bar7:	.equ	str_bar10+3
str_bar5:	.equ	str_bar10+5

str_hyphen:	.equ	str_bar10+9
str_colon:	.dc.b	':',0

		.even


* Block Storage Section ----------------------- *

*		.bss
		.even


		.end

* End of File --------------------------------- *
