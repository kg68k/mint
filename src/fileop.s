# fileop.s - file operation routines
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
		.include	sysval.def

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* cpmv.s
		.xref	＆move
* madoka3.s
		.xref	＠buildin,＠status
* mint.s
		.xref	search_cursor_file,search_mark_file
		.xref	fullpath_a1
		.xref	set_curfile2
		.xref	skip_blank_a1
		.xref	directory_rewrite
		.xref	directory_reload,directory_reload_opp
		.xref	reload_drive_info
		.xref	print_mark_information,update_periodic_display
		.xref	chdir_a1_arc,dos_drvctrl_d1
		.xref	is_parent_directory_a4,is_mb
		.xref	to_mintslash_and_add_last_slash
		.xref	MINT_TEMP,MINTSLASH
* mintarc.s
		.xref	ma_list_append
		.xref	ma_list_delete
		.xref	ma_list_write
		.xref	mintarc_extract,mintarc_dispose
		.xref	mintarc_chdir_to_arc_dir
* music.s
		.xref	human_psp
* outside.s
		.xref	set_user_value_a1_a2,unset_user_value_a1
		.xref	strcmp_a1_a2
		.xref	break_check


* Constant ------------------------------------ *

LNDRV_HEAD_SIZE:.equ	4*40


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&maketmp			*
*************************************************

＆maketmp::
		bsr	set_status_0
		lea	(maketmp_default_valname,pc),a4
		lea	(maketmp_default_filename,pc),a5
		tst.l	d7
		beq	maketmp_make

		lea	(a0),a4			;変数名
		subq.l	#2,d7
		bcs	maketmp_make
		bne	maketmp_error
@@:		tst.b	(a0)+
		bne	@b
		lea	(a0),a5			;ファイル名
		STRLEN	a0,d0
		moveq	#18+1+3,d1
		cmp.l	d1,d0
		bhi	maketmp_error

		tst.b	(a4)
		beq	maketmp_error
		tst.b	(a5)
		beq	maketmp_error
maketmp_make:
		lea	(MINT_TEMP),a0
		bsr	get_drive_status
		andi.b	#1<<DRV_PROTECT+1<<DRV_NOTREADY+1<<DRV_INSERT+1<<DRV_ERRINS,d0
		subq.b	#1<<DRV_INSERT,d0
		bne	maketmp_error

		lea	(-90,sp),sp
		lea	(sp),a1
		STRCPY	a0,a1			;パス名
		subq.l	#1,a1
		cmpa.l	a0,a1
		bne	@f
		bsr	get_curdir_a1		;$MINT_TMP 未定義ならカレントに作る
		STREND	a1
@@:		STRCPY	a5,a1			;テンポラリファイル名

		move	#1<<ARCHIVE,-(sp)
		pea	(2,sp)
		DOS	_MAKETMP
		addq.l	#6,sp
		tst.l	d0
		bmi	maketmp_error2

		move	d0,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp

		lea	(a4),a1
		lea	(sp),a2
		jsr	(set_user_value_a1_a2)
		bsr	set_status
maketmp_error2:
		lea	(90,sp),sp
maketmp_error:
		rts


maketmp_default_valname:
		.dc.b	'_',0
maketmp_default_filename:
		.dc.b	'mint0000.tmp',0
		.even


* カレントディレクトリ収得 -------------------- *
* in	a1.l	バッファ(偶数アドレスであること)

get_curdir_a1::
		move.l	#'A:\'<<8,(a1)
		DOS	_CURDRV
		add.b	d0,(a1)			;ドライブ

		pea	(3,a1)
		clr	-(sp)
		DOS	_CURDIR			;ディレクトリ名
		addq.l	#6,sp

		move.l	a0,-(sp)
		lea	(a1),a0
		jsr	(to_mintslash_and_add_last_slash)
		movea.l	(sp)+,a0
		rts


*************************************************
*		&touch				*
*************************************************

*レジスタ割り当て
*	d4.hw	-f オプションフラグ
*	d4.w	-n 〃($ffff=-n 0.w=書き込みなし $00ff=書き込みあり)
*	d5.l	設定時刻
*	d6.l	エラーコード
*	d7.l	残り引数の数

YEAR_bit:	.equ	7
MONTH_bit:	.equ	4
DATE_bit:	.equ	5
HOUR_bit:	.equ	5
MINUTE_bit:	.equ	6
SECOND_bit:	.equ	5

＆touch::
		bsr	touch_get_datetime
		bsr	set_status_0
		tst.l	d7
		beq	touch_error

		bsr	lndrv_init

		moveq	#0,d4
touch_option_loop:
		cmpi.b	#'-',(a0)
		beq	touch_option

		bsr	count_num_char		;日時の指定か調べる
		lea	(a0,d0.l),a1
		move.b	(a1)+,d1
		beq	touch_no_second
		cmpi.b	#'.',d1
		bne	touch_no_option

		PUSH	d0/a0			;秒が2桁か調べる
		lea	(a1),a0
		bsr	count_num_char
		subq.l	#2,d0
		bne	@f
		tst.b	(2,a0)
@@:		POP	d0/a0
		bne	touch_no_option
touch_no_second:
		cmpi	#8,d0
		beq	touch_mm_dd_hh_mm
		cmpi	#10,d0
		beq	touch_yy_mm_dd_hh_mm
		cmpi	#12,d0
		bne	touch_no_option
*touch_cc_yy_mm_dd_hh_mm:
		bsr	touch_stol2
		moveq	#100,d2
		mulu	d0,d2			;西暦上2桁
		bsr	touch_stol2
		add	d2,d0			;    下2桁
		subi	#1980,d0
*		cmpi	#99,d0
		cmpi	#$7f,d0			;2107 年まで可能
		bhi	touch_error
		bra	@f
touch_yy_mm_dd_hh_mm:
		bsr	touch_stol2		;西暦下2桁
		subi	#80,d0
		bcc	@f			;[19]80～[19]99
		addi	#100,d0			;[20]00～[20]79
@@:
		move.l	d0,d5
		bra	@f
touch_mm_dd_hh_mm:
		rol.l	#YEAR_bit,d5
		moveq	#%1111_111,d0
		and.l	d0,d5			;西暦だけ残す
@@:
		lsl.l	#MONTH_bit,d5

		bsr	touch_stol2		;月 1～12
		beq	touch_error
		cmpi	#12,d0
		bhi	touch_error

		or	d0,d5
		lsl.l	#DATE_bit,d5

		bsr	touch_stol2		;日 1～31
		beq	touch_error
		cmpi	#31,d0
		bhi	touch_error

		or	d0,d5
		lsl.l	#HOUR_bit,d5

		bsr	touch_stol2		;時 0～23
		cmpi	#23,d0
		bhi	touch_error

		or	d0,d5
		lsl.l	#MINUTE_bit,d5

		moveq	#59,d2
		bsr	touch_stol2		;分 0～59
		cmp	d2,d0
		bhi	touch_error

		or	d0,d5
		lsl.l	#SECOND_bit,d5

		tst.b	(a0)+			;.ss
		beq	touch_no_ss		;省略時は00秒

		bsr	touch_stol2		;秒 0～59/2
		cmp	d2,d0
		bhi	touch_error

		lsr	#1,d0
		or	d0,d5
		addq.l	#1,a0
touch_no_ss:
		bra	touch_option_end

touch_stol2:
		moveq	#$f,d0
		moveq	#$f,d1
		and.b	(a0)+,d0
		and.b	(a0)+,d1
		mulu	#10,d0
		add	d1,d0
		rts

touch_option:
		addq.l	#1,a0
		move.b	(a0)+,d0
		cmpi.b	#'-',d0
		beq	touch_break_option
option_next:
		cmpi.b	#'n',d0
		beq	touch_option_n
		cmpi.b	#'r',d0
		beq	touch_option_r
		cmpi.b	#'R',d0
		beq	touch_option_R
		cmpi.b	#'f',d0
		bne	touch_error
;touch_option_f:
		not.l	d4			;d4.hw=-1
touch_option_n:
		not	d4			;d4.w=-1
		move.b	(a0)+,d0
		bne	option_next
		subq.l	#1,d7
		beq	touch_error
		bra	touch_option_loop

* -R file : file がリンクでも file 自体を参照
touch_option_R:
		lea	(lndrv_link_files,pc),a1
		bra	@f

* -r file : file がリンクならリンク先を参照
touch_option_r:
		lea	(lndrv_link_files_dos,pc),a1
@@:
		bsr	touch_get_filename
		beq	touch_error

		bsr	get_drive_status
		btst	#DRV_INSERT,d0
		beq	touch_error
		btst	#DRV_NOTREADY,d0
		bne	touch_error

		lea	(-54,sp),sp
		move	#$ff,-(sp)
		pea	(a0)
		pea	(6,sp)
		jsr	(a1)			;LINK_FILES or DOS _FILES
		move.l	(10+FILES_Time,sp),d5
		lea	(10+54,sp),sp
		tst.l	d0
		bmi	touch_error

		swap	d5			;date/time の順に入れ換える
touch_option_r_skip:
		tst.b	(a0)+
		bne	touch_option_r_skip
		bra	touch_option_end	;-[rR] file の後にオプションは置けない

touch_get_filename:
		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bne	touch_get_filename
@@:		tst.b	-(a0)
		rts

touch_break_option:
		tst.b	(a0)+
		bne	touch_error
touch_option_end:
		subq.l	#1,d7
		beq	touch_error
touch_no_option:
		moveq	#0,d6
		jsr	(set_curfile2)
;メインループ
touch_loop:
		bsr	call_break_check
		bmi	touch_abort

		lea	(a0),a1
@@:		tst.b	(a1)+
		bne	@b
		move.l	a1,-(sp)
		bsr	to_mintslash

		tst	d4
		bmi	@f			;-n 指定時は一切の表示をしない

		move.l	#(WHITE+EMPHASIS)<<16+MES_TOUCH,d0
		bsr	print_fileop_message
@@:
		bsr	get_drive_status
		btst	#DRV_INSERT,d0
		beq	touch_notready
		btst	#DRV_NOTREADY,d0
		bne	touch_notready
		btst	#DRV_PROTECT,d0
		bne	touch_wp_error

		bsr	touch_write_open
		bpl	touch_open_ok
		addq.l	#5,d0
		bne	@f

		bsr	chmod_a0_get
		bmi	touch_file_error
		move.l	d0,d2
		andi.b	#1<<SYSTEM+1<<READONLY,d0
		beq	touch_dir_writable	;ディレクトリ
		bra	touch_dir_wp		;書き込み禁止ディレクトリ
@@:
		move	#1<<ARCHIVE,-(sp)
		move.l	a0,-(sp)
		DOS	_NEWFILE		;安全の為DOS _CREATEは使わない
		addq.l	#6,sp
		move.l	d0,d1
		bpl	touch_open_ok
touch_dir_wp:
		tst.l	d4
		bpl	touch_file_error

;書き込み禁止ファイルの強制処理
		bsr	chmod_a0_get
		bmi	touch_file_error
		move.l	d0,d2
touch_dir_writable:
		moveq	#1<<ARCHIVE,d0
		bsr	chmod_a0_d0
		bmi	touch_file_error

		bsr	touch_write_open
		bmi	touch_force_error

		bsr	touch_filedate_sub
		beq	touch_force_error

		move	d2,d0
		bsr	chmod_a0_d0
		bmi	touch_file_error
		bra	touch_ok
touch_force_error:
		move	d2,d0
		bsr	chmod_a0_d0

touch_file_error:
		lea	(PrintFalse),a1
		bra	@f
touch_notready:
		lea	(PrintNotReady),a1
		bra	@f
touch_wp_error:
		lea	(PrintWProtect),a1
@@:		moveq	#-1,d6
		bra	touch_next

touch_open_ok:
		bsr	touch_filedate_sub
		beq	touch_file_error
touch_ok:
		st	d4			;一度でも書き込みしたフラグ
		lea	(PrintCompleted),a1
		addq	#1,d6
touch_next:
		tst	d4
		bmi	@f			;-n指定時は一切の表示をしない
		jsr	(a1)
@@:
		movea.l	(sp)+,a0
		subq.l	#1,d7
		bne	touch_loop

		move.l	d6,d0
		ble	@f
		bsr	set_status
@@:
touch_abort:
		tst	d4
		ble	touch_end		;$ffff/$0000 ならリロード不要
*touch_reload_end:
		suba.l	a0,a0
		jsr	(directory_reload)
		jsr	(reload_drive_info)
		bra	update_opp_dirlist
touch_end:
touch_error:
		rts


* 数字の続く桁数を数える.
* in	a0.l	文字列のアドレス
* out	d0.l	桁数

count_num_char:
		PUSH	d1/a0
		moveq	#-1,d0
count_num_loop:
		addq.l	#1,d0
		moveq	#-'0',d1
		add.b	(a0)+,d1
		cmpi.b	#9,d1
		bls	count_num_loop
		POP	d1/a0
		rts

* ファイル最終更新日時を収得/設定する.
* in	d1.w	ファイルハンドル
*	d5.l	設定日時(0なら収得のみ)
* out	d0.w	0ならエラー
*	d1.l	引数のd5.l==0のとき最終更新日時

touch_filedate_sub:
		move.l	d5,-(sp)
		move	d1,-(sp)
		DOS	_FILEDATE
		move.l	d0,d1
		DOS	_CLOSE
		addq.l	#6,sp
		move.l	d1,d0
		swap	d0			;DOS _FILEDATEは返値の上位ワードが
		not	d0			;$ffffでエラー
		rts

* 書き込みモードでファイルをオープンする.
* in	a0.l	ファイル名
* out	d0.l	ファイルハンドル/エラーコード
*	d1.l	〃

touch_write_open:
		move	#WOPEN,-(sp)
		move.l	a0,-(sp)
		bsr	lndrv_pure_open		;DOS _OPEN
		addq.l	#6,sp
		move.l	d0,d1
		rts

* ファイル属性を変更する.
* in	d0.w	ファイル属性
*	a0.l	ファイル名
* out	d0.l	以前のファイル属性/エラーコード

chmod_a0_get:
		moveq	#-1,d0
chmod_a0_d0:
		move	d0,-(sp)
		move.l	a0,-(sp)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		rts

* 現在の日時を得る.
* out	d5.l	日付/時刻
* break	d0-d1

touch_get_datetime:
		DOS	_GETDATE
@@:		move	d0,d5
		swap	d5
		move	d0,d1
		DOS	_GETTIME
		move	d0,d5
		DOS	_GETDATE
		cmp	d0,d1			;日付が変わっていたらもう一回
		bne	@b
		rts


*************************************************
*		&chmod				*
*************************************************

＆chmod::
		bsr	set_status_0
		subq.l	#1,d7
		ble	chmod_error

		moveq	#0,d6
		cmpi.b	#'-',(a0)
		bne	@f
		cmpi.b	#'f',(1,a0)
		bne	@f
		tst.b	(2,a0)
		bne	@f

		moveq	#-1,d6
		addq.l	#3,a0
		subq.l	#1,d7
		ble	chmod_error
@@:
		move.b	(a0)+,d0		;この時点で引数はあと二個以上ある
		cmpi.b	#'-',d0
		beq	chmod_minus
		cmpi.b	#'+',d0
		beq	chmod_plus
		cmpi.b	#'=',d0
		bne	chmod_error
*chmod_equal:
		bsr	chmod_get_attrib
		bmi	chmod_error

		moveq	#0,d4			;and属性
		move.b	d0,d5			;or 属性
		bra	chmod_start
chmod_minus:
		bsr	chmod_get_attrib
		bmi	chmod_error

		move.b	d0,d4
		not.b	d4			;and属性
		moveq	#0,d5
		bra	chmod_start
chmod_plus:
		bsr	chmod_get_attrib
		bmi	chmod_error

		moveq	#$ff,d4
		move.b	d0,d5			;or 属性
chmod_start:
		tst	d6
		bne	@f

		ori.b	#(1<<LINK+1<<DIRECTORY+1<<VOLUME),d4
		andi.b	#(1<<LINK+1<<DIRECTORY+1<<VOLUME).xor.$ff,d5
@@:
		moveq	#0,d6
chmod_loop:
		bsr	chmod_a0_get
		bmi	chmod_file_error

		and.b	d4,d0
		or.b	d5,d0
		bsr	chmod_a0_d0
		bmi	chmod_file_error

		addq	#1,d6
		bra	chmod_next
chmod_file_error:
		moveq	#-1,d6
chmod_next:
		tst.b	(a0)+
		bne	chmod_next
		subq.l	#1,d7
		bne	chmod_loop

		move.l	d6,d0
		ble	chmod_error

		bsr	set_status
chmod_error:
		rts

chmod_get_attrib:
		moveq	#0,d0
		move.b	(a0)+,d1
		beq	chmod_get_atr_error
chmod_get_atr_loop:
		ori.b	#$20,d1
		lea	(chmod_atr_list,pc),a1
		moveq	#7,d2
@@:
		cmp.b	(a1)+,d1
		dbeq	d2,@b
		bne	chmod_get_atr_error

		bset	d2,d0
		move.b	(a0)+,d1
		bne	chmod_get_atr_loop
		rts
chmod_get_atr_error:
		moveq	#-1,d0
		rts

chmod_atr_list:
		.dc.b	'xladvshr'
		.even


*************************************************
*		&ren=&rename			*
*************************************************

＆ren::
		bsr	set_status_0
		subq.l	#2,d7
		bne	ren_error

		lea	(a0),a1
		tst.b	(a1)+			;oldfile
		beq	ren_error
@@:		tst.b	(a1)+
		bne	@b
		tst.b	(a1)			;newfile
		beq	ren_error

		moveq	#0,d1
		cmpi.b	#':',(1,a0)
		bne	@f
		moveq	#$20,d1
		or.b	(a0),d1
		subi.b	#'a',d1
		cmpi.b	#'z'-'a',d1
		bhi	ren_error
		addq.b	#1,d1
@@:
		jsr	(dos_drvctrl_d1)
		andi.b	#%1111,d0
		cmpi.b	#1<<DRV_INSERT,d0
		bne	ren_error

		move.l	a1,-(sp)
		move.l	a0,-(sp)
		DOS	_RENAME
		addq.l	#8,sp
		tst.l	d0
		bmi	ren_error

		bsr	set_status_1
ren_error:
		rts


*************************************************
*		&file-check			*
*************************************************

＆file_check::
		lea	(set_user_value_a1_a2),a5
		bsr	set_status_0
		tst.l	d7
		beq	file_check_decarg_fail

		bsr	rm_a0_chmod_get
		bmi	file_check_decarg_fail

		lea	(-10,sp),sp
		lea	(file_check_atr_list,pc),a1
		lea	(sp),a2
file_check_make_atr_loop:
		add.b	d0,d0
		bcc	@f
		move.b	(a1),(a2)+
@@:		addq.l	#1,a1
		bne	file_check_make_atr_loop
		clr.b	(a2)

		lea	(file_check_attribute,pc),a1
		lea	(sp),a2
		jsr	(a5)
		lea	(10,sp),sp

		clr	-(sp)
		move.l	a0,-(sp)
		DOS	_OPEN			;lndrv_pure_dos_open にすべきか？
		addq.l	#6,sp
		move.l	d0,d7
		bmi	file_check_decarg_fail

		clr.l	-(sp)
		move	d7,-(sp)
		DOS	_FILEDATE
		addq.l	#6,sp
		move.l	d0,d1
		swap	d0
		not	d0
		beq	file_check_decarg_fail2	;返値の上位wordが$ffffならエラー

		lea	(-18,sp),sp
		lea	(sp),a1
		move	d1,-(sp)
		lsr.l	#5,d1
		lsr	#3,d1			;%0000_0yyy_yyyy_mmmm_000d_dddd_tttt_tfff
		lsr.l	#4,d1
		lsr	#4,d1			;%0000_0000_0yyy_yyyy_0000_mmmm_000d_dddd
		addi.l	#2<<28+1980<<16,d1
		IOCS	_DATEASC
		move.b	#SPACE,(a1)+
		move	(sp)+,d1
		swap	d1
		lsr.l	#5,d1
		lsr	#3,d1			;%0000_0ttt_ttff_ffff_000s_ssss_0000_0000
		lsr.l	#6,d1
		lsr	#2,d1			;%0000_0000_000t_tttt_00ff_ffff_000s_ssss
		add.b	d1,d1
		IOCS	_TIMEASC
		lea	(file_check_timestamp,pc),a1
		lea	(sp),a2
		jsr	(a5)
		lea	(18,sp),sp

		move	#SEEK_END,-(sp)
		clr.l	-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	file_check_decarg_fail2

		lea	(-16,sp),sp
		lea	(sp),a0
		FPACK	__LTOS
		lea	(file_check_length,pc),a1
		lea	(sp),a2
		jsr	(a5)
		lea	(16,sp),sp

		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp

		bsr	set_status_1
		bra	file_check_decarg_end

file_check_decarg_fail2:
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
file_check_decarg_fail:
		lea	(unset_user_value_a1-set_user_value_a1_a2,a5),a5
		lea	(file_check_attribute,pc),a1
		jsr	(a5)
		lea	(file_check_timestamp,pc),a1
		jsr	(a5)
		lea	(file_check_length,pc),a1
		jsr	(a5)
file_check_decarg_end:
		rts

set_status_0:
		moveq	#0,d0
		bra	set_status
set_status_1:
		moveq	#1,d0
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts

file_check_atr_list:
		.dc.b	'XLADVSHR',0
file_check_attribute:
		.dc.b	'ATTRIBUTE',0
file_check_timestamp:
		.dc.b	'TIMESTAMP',0
file_check_length:
		.dc.b	'LENGTH',0
		.even


*************************************************
*		&make-dir-and-move		*
*************************************************

＆make_dir_and_move::
		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		bmi	＆md

		jmp	(＆move)


*************************************************
*		&md=mkdir=&make-dirs		*
*************************************************

＆md::
		bsr	set_status_0
		tst.l	d7
		beq	md_input

		bsr	md_sub
		move.l	d6,d0
		ble	@f
		bsr	set_status
@@:
md_reload_end:
		suba.l	a0,a0
		jsr	(directory_reload)
		jsr	(reload_drive_info)
		bra	update_opp_dirlist
md_input_cancel:
		rts

md_input:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		cmpi	#1,(＄arc！)
		beq	md_input_cancel
@@:
		move	(PATH_DRIVENO,a6),d1
		jsr	(dos_drvctrl_d1)
		btst	#DRV_PROTECT,d0
		bne	print_write_protect_error

		lea	(subwin_md_input,pc),a0
		moveq	#MES_INPMD,d0
		bsr	call_sub_window_print
		bsr	call_subwin_locate_1_1

		move	(win_no,pc),d2
		lea	(-(256+64),sp),sp
		lea	(sp),a1
		clr.b	(a1)
		moveq	#70,d0			;ウィンドウ幅
		swap	d0
		move	d2,d0
		move.l	#255<<16+RL_F_DIR,d1
		jsr	(MintReadLine)
		exg	d0,d2
		jsr	(WinClose)
		tst.l	d2
		bmi	md_input_end

		bsr	md_split_argument
		move.l	d0,d7
		beq	md_input_end

		bsr	md_sub

		lea	(sp),a0
		move.b	(a0),d0
		bsr	is_slash
		beq	@f			;絶対パスならそのまま
		cmpi.b	#':',(1,a0)
		beq	@f			;〃

		lea	(sp),a2			;移動先パス名を作成する
		lea	(-256,sp),sp
		lea	(sp),a1
		STRCPY	a0,a1
		lea	(PATH_DIRNAME,a6),a0
		STRCPY	a0,a2
		subq.l	#1,a2
		lea	(sp),a0
		STRCPY	a0,a2
		lea	(256,sp),sp
@@:
		lea	(sp),a1
		jsr	(fullpath_a1)

		move.l	d6,d0
		ble	@f			;一回でも失敗したら 0 を返す
		bsr	set_status
		subq.l	#1,d6
		bne	@f
		tst	(＄mdmd)
		beq	@f

		bsr	update_opp_dirlist	;先に反対側をリロード
		lea	(sp),a1
		jsr	(chdir_a1_arc)
md_input_end:
		lea	(256+64,sp),sp
		rts
@@:
		bsr	md_reload_end
		bra	md_input_end

* &md 下請け
md_sub:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f

.if 0
		move.l	a0,-(sp)
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a0
		.xref	 extract_a0
		jsr	(extract_a0)
		movea.l	(sp)+,a0
.else
		moveq	#%001,d0
		jsr	(mintarc_extract)
.endif
		jsr	(mintarc_chdir_to_arc_dir)
@@:
		moveq	#0,d6
md_sub_loop:
		lea	(a0),a1
@@:		tst.b	(a1)+
		bne	@b
		move.l	a1,-(sp)

		move.l	a0,-(sp)
		cmpi.b	#'/',(a0)		;先頭が / \ なら (V)TwentyOne.sys の
		beq	1f			;+r +y に対応するため to_mintslash
		cmpi.b	#'\',(a0)		;の変換を抑制する
		bne	@f
1:		addq.l	#1,a0
@@:		bsr	to_mintslash
		movea.l	(sp)+,a0

		bsr	mkdir_a0
		or.l	d0,d6
		tst.l	d0
		bmi	@f

		addq	#1,d6
		bsr	md_sub_mintarc
@@:
		movea.l	(sp)+,a0
		move.b	(abort_flag,pc),d0
		bne	@f
		subq.l	#1,d7
		bne	md_sub_loop
@@:
		jsr	(set_curfile2)
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		jsr	(ma_list_write)
@@:		rts

* mintarc 対応処理
md_sub_mintarc:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	md_sub_ma_end
		cmpi.b	#'/',(a0)		;mintarc 外に作成したディレクトリは無視
		beq	md_sub_ma_end
		cmpi.b	#'\',(a0)
		beq	md_sub_ma_end
		cmpi.b	#':',(1,a0)
		beq	md_sub_ma_end

		PUSH	d0/a0-a2
		lea	(-128,sp),sp
		lea	(sp),a2
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a1
		STRCPY	a1,a2
		subq.l	#1,a2
		STRCPY	a0,a2

		moveq	#-1,d0			;mintarc 用のリストに登録
		lea	(sp),a0
		lea	(md_sub_ma_end,pc),a1	;ダミー
		jsr	(ma_list_append)
		lea	(128,sp),sp
		POP	d0/a0-a2
md_sub_ma_end:
		rts


* 文字列を空白で分割する
* in	a1.l	文字列
* out	a0.l	in a1.l と同じ
*	d0.l	単語数

md_split_argument:
		lea	(a1),a0
		PUSH	d7/a0-a1
		moveq	#0,d7
md_split_arg_loop:
		jsr	(skip_blank_a1)
		move.b	(a1),(a0)
		beq	md_split_arg_end

		addq.l	#1,d7
@@:
		move.b	(a1)+,d0
**		cmpi.b	#TAB,d0			;行入力の結果だから省略可
**		beq	md_split_arg_blank
		cmpi.b	#SPACE,d0
		beq	md_split_arg_blank

		move.b	d0,(a0)+
		beq	md_split_arg_end
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		move.b	(a1)+,(a0)+
		bra	@b
md_split_arg_blank:
		clr.b	(a0)+
		bra	md_split_arg_loop
md_split_arg_end:
		move.l	d7,d0
		POP	d7/a0-a1
		rts


subwin_md_input:
		SUBWIN	12,8,72,1,NULL,NULL


* ディレクトリ作成
* in	a0.l	ディレクトリ名
* out	d0.l	0:正常終了 -1:エラー
*	ccr	<tst.l d0> の結果

mkdir_a0::
		PUSH	d1-d7/a0-a6
		bsr	get_drive_status
		btst	#DRV_INSERT,d0
		beq	mkdir_a0_notready
		btst	#DRV_NOTREADY,d0
		bne	mkdir_a0_notready
		btst	#DRV_PROTECT,d0
		bne	mkdir_a0_wp_error

		lea	(a0),a1
		move.b	(a1)+,d0
		beq	mkdir_a0_root_error	;一応...
		bsr	is_slash
		bne	@f
		tst.b	(a1)
		bne	mkdir_a0_loop		;"/foo"
		bra	mkdir_a0_root_error	;"/"
@@:
		cmpi.b	#':',(a1)+
		beq	@f
		subq.l	#2,a1
		bra	mkdir_a0_loop		;"foo"
@@:
		move.b	(a1)+,d0
		bsr	is_slash
		beq	mkdir_a0_loop		;"d:/foo"
		subq.l	#1,a1			;"d:foo"
mkdir_a0_loop:
		bsr	call_break_check
		bmi	mkdir_a0_break

		lea	(a1),a2
mkdir_a0_skip_cur_pare_dir:
		lea	(a2),a1
		moveq	#'.',d0
		cmp.b	(a2)+,d0
		bne	mkdir_a0_search_slash_loop
		cmp.b	(a2)+,d0
		beq	@f
		subq.l	#1,a2
@@:		move.b	(a2)+,d0
		beq	mkdir_a0_root_error	;"*/.","*/.."
		bsr	is_slash
		beq	mkdir_a0_skip_cur_pare_dir

mkdir_a0_search_slash_loop:
		moveq	#0,d0
		move.b	(a1)+,d0
		beq	@f
		bsr	is_slash
		beq	@f
		jsr	(is_mb)
		beq	mkdir_a0_search_slash_loop
		tst.b	(a1)+
		bne	mkdir_a0_search_slash_loop
@@:
		move.b	-(a1),-(sp)		;slash保存
		clr.b	(a1)

		move.l	a0,-(sp)
		DOS	_MKDIR
		move.l	d0,(sp)+
		bmi	@f

		bsr	print_mkdir_message
		jsr	(PrintCompleted)
		bra	mkdir_a0_next
@@:
		moveq	#-20,d1
		cmp.l	d0,d1
		bne	mkdir_a0_error
mkdir_a0_next:
		move.b	(sp)+,(a1)+		;slash復帰
		bne	mkdir_a0_loop

		moveq	#0,d0
mkdir_a0_end:
		POP	d1-d7/a0-a6
		rts

mkdir_a0_error:
		bsr	print_mkdir_message
		jsr	(PrintFalse)
		move.b	(sp)+,(a1)+		;slash復帰
		bra	@f
mkdir_a0_notready:
		bsr	print_mkdir_message
		jsr	(PrintNotReady)
		bra	@f
mkdir_a0_wp_error:
		bsr	print_mkdir_message
		jsr	(PrintWProtect)
		bra	@f
mkdir_a0_root_error:
mkdir_a0_break:
@@:		moveq	#-1,d0
		bra	mkdir_a0_end


print_mkdir_message:
		move.l	#(YELLOW+EMPHASIS)<<16+MES_MKDIR,d0
		bra	print_fileop_message
*		rts

* 操作メッセージ及びファイル/ディレクトリ名を表示する
* in	d0.hw	操作メッセージ表示色
*	d0.w	メッセージ番号
*	a0.l	ファイル/ディレクトリ名

print_fileop_message::
		move	d0,-(sp)
		swap	d0
		bsr	set_color
		move	(sp)+,d0		;message no.
		jsr	(PrintMsg)
		moveq	#WHITE,d0
		bsr	set_color
		move.l	a0,-(sp)		;file/dirname
		DOS	_PRINT
		addq.l	#4,sp
		rts

set_color:
		move	d0,-(sp)
		move	#2,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		rts

is_curdir:
		move.b	(a0),d0
		beq	@f
		lsl	#8,d0
		move.b	(1,a0),d0
		cmpi	#'.'<<8,d0
		beq	@f
		cmpi	#'..',d0
		bne	@f
		tst.b	(2,a0)
@@:		rts


* ドライブステータスを調べる.
* in	a0.l	ドライブ名
* out	d0.l	ステータス
* break	d1

get_drive_status::
		moveq	#$1f,d1
		and.b	(a0),d1			;手抜き
		beq	get_drive_status_2
		cmpi.b	#':',(1,a0)
		beq	get_drive_status_2

		lea	(-NAMECK_SIZE,sp),sp	;"d:"形式でなければフルパス化して調べる
		move.l	sp,-(sp)
		move.l	a0,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		moveq	#0,d1
		tst.l	d0
		bmi	@f
		moveq	#$1f,d1
		and.b	(NAMECK_Drive,sp),d1	;手抜き
@@:		lea	(NAMECK_SIZE,sp),sp
get_drive_status_2:
		jmp	(dos_drvctrl_d1)
**		rts


update_opp_dirlist:
		movea.l	(PATH_OPP,a6),a2
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_MARC_FLAG,a2),d0
		bne	update_opp_info

		lea	(PATH_DIRNAME,a6),a1
		addq.l	#PATH_DIRNAME,a2
		jsr	(strcmp_a1_a2)
		bne	update_opp_info

		jsr	(directory_reload_opp)
		jmp	(ReverseCursorBarOpp)
**		rts
update_opp_info:
		move	(PATH_DRIVENO,a6),d0
		movea.l	(PATH_OPP,a6),a6
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f
		cmp	(PATH_DRIVENO,a6),d0
		bne	@f
		jsr	(reload_drive_info)
@@:
		movea.l	(PATH_OPP,a6),a6
		rts


* 指定文字列中の'/'または'\'を$MINTSLASHに統一する.
* '/'または'\'が連続していた場合は一つだけにする.
* 最後の文字が'/'または'\'であった場合は削除する.
* in	a0.l	文字列

to_mintslash::
		PUSH	a0-a1
		lea	(a0),a1
		moveq	#0,d0
		bra	to_mintslash_start
to_mintslash_loop:
		move.b	d0,(a1)+
to_mintslash_start:
		move.b	(a0)+,d0
		beq	to_mintslash_end
		bsr	is_slash
		bne	to_mintslash_skip
@@:
		move.b	(a0)+,d0
		beq	to_mintslash_end
		bsr	is_slash
		beq	@b

		move.b	(MINTSLASH),(a1)+	;連続するスラッシュは一つに纏める
to_mintslash_skip:
		jsr	(is_mb)
		beq	to_mintslash_loop
		move.b	d0,(a1)+
		move.b	(a0)+,d0
		bne	to_mintslash_loop
to_mintslash_end:
		clr.b	(a1)
		POP	a0-a1
		rts

is_slash:
		cmpi.b	#'/',d0
		beq	@f
		cmpi.b	#'\',d0
@@:		rts

* 指定文字列中最後の'/'または'\'を検索する.(未使用)
* 但し、先頭の文字は無視する.
* in	a0.l	文字列
* out	d0.l	0:found -1:not found
*	a1.l	見つけた'/'または'\'のアドレス

		.if	0
search_last_slash:
		move.l	a0,-(sp)
		lea	(a0),a1
		moveq	#0,d0
		bra	search_last_slash_loop
search_last_slash_found:
		lea	(-1,a0),a1
search_last_slash_loop:
		move.b	(a0)+,d0
		beq	search_last_slash_end
		bsr	is_slash
		beq	search_last_slash_found
		jsr	(is_mb)
		beq	search_last_slash_loop
		tst.b	(a0)+
		bne	search_last_slash_loop
search_last_slash_end:
		movea.l	(sp)+,a0
		cmpa.l	a0,a1
		beq	@f
		moveq	#0,d0
		rts
@@:		moveq	#-1,d0
		rts
		.endif


*************************************************
*		&delete				*
*************************************************

＆delete::
		tst.b	(PATH_NODISK,a6)
		bmi	delete_end
		tst	(PATH_FILENUM,a6)
		beq	delete_end

		move	(PATH_DRIVENO,a6),d1
		jsr	(dos_drvctrl_d1)
		btst	#DRV_PROTECT,d0
		bne	print_write_protect_error

		lea	(rm_work,pc),a1
		clr.b	(rm_a0_quiet_flag-rm_work,a1)
		tst	(＄del！)
		sne	(rm_a0_force_flag-rm_work,a1)
		st	(rm_a0_ask_flag-rm_work,a1)

		jsr	(search_cursor_file)
		move.l	a4,(rm_curfile_ptr)

		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		bpl	@f

		tst	(＄nmcp)		;マークファイルなし
		beq	delete_end
		movea.l	(rm_curfile_ptr,pc),a4
		jsr	(is_parent_directory_a4)
		bne	delete_end

		suba.l	a4,a4
@@:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		cmpi	#1,(＄arc！)
		beq	delete_end		;%arc! 1 = 書き込み不許可
		bhi	delete_no_ask		;%arc! 2 = 確認なし許可
@@:
		bsr	delete_ask_yes_or_no
		bne	delete_end
delete_no_ask:
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		moveq	#-1,d0			;reload 抑制
		jsr	(mintarc_dispose)
@@:
		move.l	a4,d0
		bne	delete_mark_file
*delete_cursor_file:
		movea.l	(rm_curfile_ptr,pc),a4
		bsr	delete_sub_a4
		bra	delete_reload_end

delete_mark_file:
		bsr	delete_sub_a4
		move.b	(abort_flag,pc),d0
		bne	delete_reload_end
		jsr	(search_mark_file)
		bpl	delete_mark_file
delete_reload_end:
		jsr	(set_curfile2)		;反対側だけでいい
		bsr	reset_cursor_position

		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		jsr	(ma_list_delete)
@@:
		jsr	(directory_rewrite)
		bra	update_opp_dirlist
delete_end:
		rts


reset_cursor_position:
		movea.l	(rm_curfile_ptr,pc),a1
		addq.l	#DIR_NAME,a1
		lea	(PATH_CURFILE,a6),a2
		bra	copy_dir_name_a1_a2
*		rts


delete_sub_a4:
		lea	(-128,sp),sp
		tst.b	(PATH_MARC_FLAG,a6)
		beq	delete_sub_a4_real

* 書庫内削除
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a1
		lea	(sp),a2
		STRCPY	a1,a2
		subq.l	#1,a2
		lea	(DIR_NAME,a4),a1
		bsr	copy_dir_name_a1_a2
		btst	#DIRECTORY,(DIR_ATR,a4)
		beq	@f
1:		tst.b	(a2)+			;ディレクトリは末尾に
		bne	1b			;パスデリミタを付ける
		subq.l	#1,a2
		move.b	(MINTSLASH),(a2)+
		clr.b	(a2)
@@:
		moveq	#0,d0
		lea	(sp),a0
		lea	(delete_sub_a4_rts,pc),a1
		jsr	(ma_list_append)

		btst	#DIRECTORY,(DIR_ATR,a4)
		beq	@f
		btst	#LINK,(DIR_ATR,a4)
		bne	@f
		move.b	#'*',(a2)+		;ディレクトリは dir/* という
		clr.b	(a2)			;ファイル名も指定する
		jsr	(ma_list_append)
		bra	@f
delete_sub_a4_real:
		lea	(DIR_NAME,a4),a1
		lea	(sp),a2
		bsr	copy_dir_name_a1_a2

		lea	(sp),a0
		bsr	rm_a0
		bmi	delete_sub_a4_error
@@:
		cmpa.l	(rm_curfile_ptr,pc),a4
		bne	delete_sub_a4_skip_cursor_move

		lea	(sizeof_DIR,a4),a0	;カーソル位置のファイルを削除したら、
		cmpi.b	#-1,(DIR_ATR,a0)	;カーソルを一つ下のファイルに移動する.
		bne	@f

		cmpa.l	(PATH_BUF,a6),a4
		beq	delete_sub_a4_skip_cursor_move

		lea	(-sizeof_DIR,a4),a0	;カーソルが最下段にあった場合は
@@:						;一つ上に移動する.
		move.l	a0,(rm_curfile_ptr)
delete_sub_a4_skip_cursor_move:
		subq	#1,(PATH_FILENUM,a6)

		lea	(sizeof_DIR,a4),a0	;ディレクトリバッファから
		lea	(a4),a1			;削除したエントリを取り除く
@@:
		move.b	(DIR_ATR,a0),d0
		.rept	sizeof_DIR/4
		move.l	(a0)+,(a1)+
		.endm
		not.b	d0
		bne	@b			バッファ末尾をコピーするまで繰り返す

		lea	(rm_curfile_ptr,pc),a0
		cmpa.l	(a0),a4
		bcc	@f

		moveq	#sizeof_DIR,d0
		sub.l	d0,(a0)
		bra	@f
delete_sub_a4_error:
		lea	(sizeof_DIR,a4),a4
@@:
		lea	(128,sp),sp
delete_sub_a4_rts:
		rts


delete_ask_yes_or_no::
		cmpi	#2,(＄del！)
		beq	delete_ask_yes_or_no_end	;最初の問い合せすら行わない

		lea	(subwin_delete,pc),a0
		moveq	#MES_DEL??,d0
		bsr	call_sub_window_print
		GETMES	MES_DELYN
		movea.l	d0,a1
		bsr	call_subwin_locate_1_1
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		bsr	call_win_print
		bsr	call_keyinp_winclr
		bra	check_yes_or_no
delete_ask_yes_or_no_end:
		rts

@@:		IOCS	_B_KEYINP		;まずキーバッファをフラッシュ
iocs_b_keyinp::
		IOCS	_B_KEYSNS
		tst.l	d0
		bne	@b
iocs_b_keyinp_loop:
		DOS	_CHANGE_PR		;時計を更新しながらキー入力を待つ
		jsr	(update_periodic_display)
		IOCS	_B_KEYSNS
		tst.l	d0
		beq	iocs_b_keyinp_loop
		IOCS	_B_KEYINP
		cmpi	#$5500,d0
		bcc	iocs_b_keyinp_loop
		rts


subwin_delete:
		SUBWIN	28,8,38,1,NULL,NULL


* ファイル名コピー ---------------------------- *
* DIR_NAME からのファイル名を a1 から a2 にコピーする.
* 空白は無視する.
* in	a1.l	DIR_NAME
*	a2.l	バッファ

copy_dir_name_a1_a2::
		PUSH	d0-d1/a0-a3
		lea	(18,a1),a0
		lea	(a0),a3
		moveq	#SPACE,d1
		moveq	#18-1,d0
@@:
		cmp.b	-(a0),d1		;ノード名末尾の空白を取り除く
		dbne	d0,@b
		beq	copy_dir_name_ext	;念の為…
@@:
		move.b	(a1)+,(a2)+		;ノード名コピー
		dbra	d0,@b
copy_dir_name_ext:
	.rept	4
		move.b	(a3)+,(a2)+		;拡張子コピー
	.endm
@@:
		cmp.b	-(a2),d1		;拡張子末尾の空白を取り除く
		beq	@b
		clr.b	(1,a2)
		POP	d0-d1/a0-a3
		rts


*************************************************
*		&rm=&del			*
*************************************************

＆rm::
		tst.l	d7
		beq	rm_no_arg

		lea	(rm_work,pc),a1
		st	(rm_a0_quiet_flag-rm_work,a1)
		st	(rm_a0_force_flag-rm_work,a1)
		lea	(-128,sp),sp
rm_next:
		STRLEN	a0,d0
		moveq	#128-1,d1
		cmp.l	d1,d0
		bcc	@f			;引数が長すぎたら中断

		lea	(sp),a1
		STRCPY	a0,a1
		move.l	a0,a1
		lea	(sp),a0
		bsr	to_mintslash
		bsr	rm_a0
		movea.l	a1,a0
		move.b	(abort_flag,pc),d0
		bne	@f
		subq.l	#1,d7
		bne	rm_next
@@:
		lea	(128,sp),sp
rm_no_arg:
		rts


call_break_check:
		jsr	(break_check)
		smi	(abort_flag)
		rts

* ファイル削除
* ディレクトリが指定された場合は再帰的に削除する.
* in	a0.l	ファイル名

rm_a0::
		PUSH	d1-d7/a0-a6
		bsr	call_break_check
		bmi	rm_a0_end

		cmpi.b	#':',(1,a0)
		bne	@f
		tst.b	(2,a0)
		beq	rm_a0_root		;"d:"は削除不可能
@@:
		bsr	is_curdir
		beq	rm_a0_skip

		moveq	#MES_KILLF,d7
		move	(recurse_flag,pc),d0
		bne	@f			;再帰中のWriteProtect検査は飛ばす

		bsr	get_drive_status
		btst	#DRV_INSERT,d0
		beq	rm_a0_notready
		btst	#DRV_NOTREADY,d0
		bne	rm_a0_notready
		btst	#DRV_PROTECT,d0
		bne	rm_a0_wp_error
@@:
		move.l	a0,-(sp)
		DOS	_DELETE
		move.l	d0,(sp)+
		bpl	rm_a0_ok		;普通のファイル

		bsr	rm_a0_chmod_get
		bmi	rm_a0_error
		btst	#DIRECTORY,d0
		bne	rm_a0_dir

*		move.b	(rm_a0_force_flag,pc),d0
*		beq	rm_a0_error		;削除不可能な属性のファイル
		bsr	rm_a0_ask_yes_or_no_file
		bne	rm_a0_skip_error

		moveq	#1<<ARCHIVE,d0
		bsr	rm_a0_chmod
		bmi	rm_a0_error

		move.l	a0,-(sp)
		DOS	_DELETE
		move.l	d0,(sp)+
		bpl	rm_a0_ok
		bra	rm_a0_error
rm_a0_dir:
		moveq	#MES_DKILL,d7
		move.l	a0,-(sp)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	rm_a0_ok		;空ディレクトリ

		lea	(-FILES_SIZE,sp),sp

		lea	(a0),a1
@@:
		tst.b	(a1)+
		bne	@b
		move.b	(MINTSLASH),(-1,a1)
		clr.b	(a1)
		lea	(a1),a5

		move	(recurse_flag,pc),d0	;再帰中の中身ありディレクトリは、既に
		bne	@f			;削除確認を取っているので削除してよい
		bsr	rm_a0_ask_yes_or_no_dir
		beq	@f

		clr.b	-(a5)
		lea	(FILES_SIZE,sp),sp
		bra	rm_a0_skip_error
@@:
		moveq	#0,d6
.ifdef NO_LNDRV_BUG
		lea	(sp),a1
		move	#$01_ff,-(sp)
.else
		lea	(files_wild,pc),a2
		STRCPY	a2,a1			;"foo" + "/" + "*.*"
		lea	(sp),a1
		move	#$00_ff,-(sp)
.endif
		move.l	a0,-(sp)
		move.l	a1,-(sp)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	rm_a0_files_end
rm_a0_files_loop:
		bsr	call_break_check
		bmi	rm_a0_abort

		lea	(FILES_FileName,sp),a2
		cmpi	#'.'<<8,(a2)
		beq	rm_a0_files_next
		cmpi	#'..',(a2)
		bne	@f
		tst.b	(2,a2)
		beq	rm_a0_files_next
@@:
		lea	(a5),a3
		STRCPY	a2,a3

		lea	(recurse_flag,pc),a2
		addq	#1,(a2)
		bsr	rm_a0
		or.l	d0,d6
		subq	#1,(a2)

		move.b	(abort_flag,pc),d1
		bne	rm_a0_abort
rm_a0_files_next:
		move.l	sp,-(sp)
		DOS	_NFILES
		move.l	d0,(sp)+
		bpl	rm_a0_files_loop
rm_a0_files_end:
		clr.b	-(a5)
		lea	(FILES_SIZE,sp),sp

		tst.l	d6			;下層エントリに削除失敗したものがあれば
		bmi	rm_a0_skip_error	;注目ディレクトリは削除できない

		move.l	a0,-(sp)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	rm_a0_ok

* 下層にエントリがある為削除できないディレクトリと
* 書き込み不可能な属性のディレクトリの削除確認は上で同時に行う.
*		move.b	(rm_a0_force_flag,pc),d0
*		beq	rm_a0_error		;削除不可能な属性のディレクトリ

		moveq	#1<<DIRECTORY,d0
		bsr	rm_a0_chmod
		bmi	rm_a0_error

		move.l	a0,-(sp)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bmi	rm_a0_error
rm_a0_ok:
		move.b	(rm_a0_quiet_flag,pc),d0
		bne	1f
		bsr	print_rm_message
		jsr	(PrintCompleted)
1:
rm_a0_skip:
		moveq	#0,d0
rm_a0_end:
		POP	d1-d7/a0-a6
		rts

rm_a0_error:
		move.b	(rm_a0_quiet_flag,pc),d0
		bne	1f
		bsr	print_rm_message
		jsr	(PrintFalse)
1:		bra	@f
rm_a0_skip_error:
		move.b	(rm_a0_quiet_flag,pc),d0
		bne	1f
		bsr	print_rm_message
		jsr	(PrintSkip)
1:		bra	@f
rm_a0_notready:
		move.b	(rm_a0_quiet_flag,pc),d0
		bne	1f
		bsr	print_rm_message
		jsr	(PrintNotReady)
1:		bra	@f
rm_a0_wp_error:
		move.b	(rm_a0_quiet_flag,pc),d0
		bne	1f
		bsr	print_rm_message
		jsr	(PrintWProtect)
1:		bra	@f
rm_a0_abort:
		clr.b	-(a5)
		lea	(FILES_SIZE,sp),sp
		bra	@f
rm_a0_root:
@@:		moveq	#-1,d0
		bra	rm_a0_end

print_rm_message:
		moveq	#YELLOW+EMPHASIS,d0
		swap	d0
		move	d7,d0
		bra	print_fileop_message
*		rts

rm_a0_chmod_get:
		moveq	#-1,d0
rm_a0_chmod:
		move	d0,-(sp)
		move.l	a0,-(sp)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		rts


rm_a0_ask_yn_yes:
		moveq	#0,d0
		rts
rm_a0_ask_yn_no:
		moveq	#1,d0
		rts

rm_a0_ask_yes_or_no_dir:
		moveq	#-1,d0
		bra	@f
rm_a0_ask_yes_or_no_file:
		moveq	#0,d0
@@:
		move.b	(rm_a0_force_flag,pc),d0
		bne	rm_a0_ask_yn_yes
		move.b	(rm_a0_ask_flag,pc),d0
		beq	rm_a0_ask_yn_no
		tst	(＄del！)
		bne	rm_a0_ask_yn_yes

		PUSH	d1-d7/a0-a6
		lea	(a0),a1			;[]内に表示する文字列
		lea	(subwin_rm_a0_ask_yn,pc),a0
		move.l	d0,d1
		move.l	#MES_KYOUS<<16+MES_KYOU2,d0
		tst.l	d1
		bpl	@f
		move	#MES_DDEL2,d0
@@:		bsr	ask_window_sub

		move.b	d0,-(sp)
		bsr	call_break_check

		IOCS	_B_SFTSNS		;SHIFTが押されていたら
		lsr.b	#1,d0			;以後は強制削除or無視
		lea	(rm_work,pc),a0
		scs	(rm_a0_force_flag-rm_work,a0)
		scc	(rm_a0_ask_flag-rm_work,a0)
		move.b	(sp)+,d0

		POP	d1-d7/a0-a6
		bra	check_yes_or_no
*		rts

check_yes_or_no::
		cmpi.b	#CR,d0
		beq	@f
		tst	(＄sp_y)
		beq	1f
		cmpi.b	#SPACE,d0
		beq	@f
1:		andi.b	#$df,d0
		cmpi.b	#'Y',d0
@@:		rts

subwin_rm_a0_ask_yn:
		SUBWIN	12,8,72,2,NULL,NULL


* サブウィンドウを表示し、キー入力してからウィンドウを消去する.
* in	d0.hw	タイトル文字列のメッセージ番号
*	d0.w	二行目に表示する文字列のメッセージ番号
*	a0.l	struct subwin
*	a1.l	[ ] 内に表示する文字列のアドレス
* out	d0.w	入力文字
* break	a1.l

ask_window_sub::
		move	d0,-(sp)
		swap	d0
		move.l	a1,-(sp)
		bsr	call_sub_window_print
		movea.l	(sp)+,a1
		move	(sp)+,d0
		jsr	(get_message)
		move.l	d0,-(sp)

		bsr	call_subwin_locate_1_1
		move.l	a1,-(sp)
		lea	(ask_window_sub_lbracket,pc),a1
		bsr	call_win_print
		movea.l	(sp)+,a1
		bsr	call_win_print
		lea	(ask_window_sub_rbracket,pc),a1
		bsr	call_win_print

		moveq	#2,d2
		bsr	call_subwin_locate_1_x
		movea.l	(sp)+,a1
		bsr	call_win_print

		bra	call_keyinp_winclr
*		rts

call_keyinp_winclr:
		bsr	iocs_b_keyinp

		move.l	d0,-(sp)
		move	(win_no,pc),d0
		jsr	(WinClose)
		move.l	(sp)+,d0
		rts

call_sub_window_print:
		jsr	(get_message)
		move.l	d0,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		move	d0,(win_no)
		rts

call_subwin_locate_1_1:
		move	(win_no,pc),d0
		moveq	#1,d2
call_subwin_locate_1_x:
		moveq	#1,d1
		jmp	(WinSetCursor)
*		rts

call_win_print:
		jmp	(WinPrint)
*		rts


win_no:		.ds	1

ask_window_sub_lbracket:
		.dc.b	' [ ',0
ask_window_sub_rbracket:
		.dc.b	' ]',0
		.even


* メディア書き込み禁止時の処理 ---------------- *

print_write_protect_error::
		bsr	set_status_0
		lea	(subwin_write_p,pc),a0
		moveq	#MES_WRITE,d0
		bsr	call_sub_window_print
		GETMES	MES_WRITP
		movea.l	d0,a1
		bsr	call_subwin_locate_1_1
		bsr	call_win_print
		bra	call_keyinp_winclr
*		rts

subwin_write_p:
		SUBWIN	8,9,72,1,NULL,NULL


* lndrv (Symbolic link driver) ---------------- *
* 以下のサブルーチンはユーザモードで呼び出すこと.

* lndrv が常駐しているか調べて、ポインタをセットする.
* lndrv_pure_open、lndrv_link_files を使う前に呼び出すこと.

lndrv_init::
		PUSH	d0/a0-a2
		lea	(pure_open_ptr,pc),a2
		clr.l	(a2)+			;pure_open_ptr
		clr.l	(a2)+			;link_files_ptr
		moveq	#1<<1,d0
		and	(＄rcdk),d0
		bne	lndrv_init_end

		TO_SUPER
		move.l	(human_psp),d0
lndrv_init_loop:
		movea.l	d0,a0
		cmpi.b	#MEM_KEEP,(pare,a0)
		bne	lndrv_init_next

		lea	(PSP_SIZE+LNDRV_HEAD_SIZE,a0),a1
		cmpa.l	(end_,a0),a1
		bhi	lndrv_init_next

		lea	(PSP_SIZE,a0),a1
		cmpi.l	#'LNDR',(a1)+
		bne	lndrv_init_next
		cmpi.b	#'V',(a1)
		bne	lndrv_init_next
		cmpi.l	#'V126',(a1)
		bcs	lndrv_init_next

		move.l	(4*17-4,a1),-(a2)	;link_files_ptr
		move.l	(4*3-4,a1),-(a2)	;pure_open_ptr
		bra	lndrv_init_end2
lndrv_init_next:
		move.l	(next,a0),d0
		bne	lndrv_init_loop
lndrv_init_end2:
		TO_USER
lndrv_init_end:
		POP	d0/a0-a2
		rts


* 指定したファイルをオープンする
* in	(4,sp).l	ファイル名
*	(8,sp).w	アクセスモード
* out	d0.l	ファイルハンドル(負数ならエラーコード)
* 備考:
*	ファイルがリンクファイルの場合、リンク先
*	ではなくリンクファイル自体をオープンする.
*	DOS _OPEN の代わりに使う.
*	lndrv を認識していない時は DOS _OPEN を呼び出す.

lndrv_pure_open::
		move.l	(pure_open_ptr,pc),d0
		beq	lndrv_pure_open_dos

		PUSH	d1-d7/a0-a6
		lea	(14*4+4,sp),a6		;引数のアドレス
		move.l	d0,-(sp)
		DOS	_SUPER_JSR		;DOS _OPEN の元のベクタを呼び出す
		addq.l	#4,sp
		POP	d1-d7/a0-a6
		rts
lndrv_pure_open_dos::
		move	(8,sp),-(sp)
		move.l	(4+2,sp),-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		rts


* リンクファイルの情報を得る
* in	(4,sp).l	バッファアドレス
*	(8,sp).l	ファイル名
*	(12,sp).w	検索する属性
* out	d0.l	エラーコード
* 備考:
*	ファイルがリンクファイルの場合、リンク先
*	ではなくリンクファイル自体の情報を収得する.
*	DOS _FILES の代わりに使う.
*	lndrv を認識していない時は DOS _FILES を呼び出す.

lndrv_link_files::
		move.l	(link_files_ptr,pc),d0
		beq	lndrv_link_files_dos

		move.l	a0,-(sp)
		movea.l	d0,a0
		TO_SUPER			;sp -= 4
		move	(8+12,sp),-(sp)
		move.l	(8+8+2,sp),-(sp)
		move.l	(8+4+6,sp),-(sp)
		jsr	(a0)			;LINK_FILES を呼び出す
		lea	(10,sp),sp		
		movea.l	d0,a0			;エラーコード
		TO_USER
		move.l	a0,d0
		movea.l	(sp)+,a0
		rts
lndrv_link_files_dos::
		move	(12,sp),-(sp)
		move.l	(8+2,sp),-(sp)
		move.l	(4+6,sp),-(sp)
		DOS	_FILES
		lea	(10,sp),sp
		rts


* Data Section -------------------------------- *

*		.data
		.even

.ifndef NO_LNDRV_BUG
files_wild:
		.dc.b	'*.*',0
.endif


* Block Storage Section ----------------------- *

*		.bss
		.even

rm_curfile_ptr:	.ds.l	1

pure_open_ptr:	.ds.l	1
link_files_ptr:	.ds.l	1

recurse_flag:	.ds	1
abort_flag:	.ds.b	1

rm_work:
rm_a0_quiet_flag::
		.ds.b	1
rm_a0_force_flag::
		.ds.b	1
rm_a0_ask_flag::
		.ds.b	1

* rm_a0_force_flag = $ff なら強制削除
*		   = $00 で、かつ
* rm_a0_ask_flag   = $ff なら問い合せをして削除
*		   = $00 なら削除しない


		.end

* End of File --------------------------------- *
