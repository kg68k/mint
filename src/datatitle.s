# datatitle.s - &data-title / &pdx-filename
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
		.include	archive.mac
		.include	message.mac
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	copy_dir_name_a1_a2
* look.s
		.xref	change_exec_filename,restore_exec_filename
* madoka3.s
		.xref	＠buildin,＠status
* mint.s
		.xref	scr_cplp_line
		.xref	search_cursor_file
		.xref	interrupt_window_print,draw_int_win_box
* mintarc.s
		.xref	zip_search_zecdr
* music.s
		.xref	print_music_title
		.xref	print_music_data_title_sub
* outside.s
		.xref	set_user_value_arg_a2,unset_user_value_arg


* Fixed Number -------------------------------- *

READ_BUF_SIZE:	.equ	256

MDC_HEAD_ID:	.equ	'MDC'<<8+EOF
MDC_TITLE:	.equ	20
MDC_ADPCM:	.equ	28

MND_HEAD_ID:	.equ	'MND'<<8+EOF
MND_HEAD_SIZE:	.equ	6
MND_TITLE:	.equ	12
MND_PCMFILE:	.equ	20

ZMD2_HEAD_ID1:	.equ	$10<<24+'Zmu'
ZMD2_HEAD_ID2:	.equ	'SiC'<<8
ZMD3_HEAD_ID1:	.equ	EOF<<24+'Zmu'
ZMD3_HEAD_ID2:	.equ	'SiC'<<8+$30
ZMD3_COMMON:	.equ	8
ZMD3_TITLE:	.equ	36

RCP_HEAD_SIZE:	.equ	32
RCP_TITLE_SIZE:	.equ	64
RCZ_TITLE:	.equ	4
RCZ_TITLE_SIZE:	.equ	64
ZDF_TITLE:	.equ	6			;MDF も同じ
ZDF_TITLE_SIZE:	.equ	64
ZDF_TITLE2:	.equ	80
ZDF_TITLE2_SIZE:.equ	32

SCM_HEAD_ID:	.equ	'SCM'<<8
SCM_TITLE:	.equ	$06
SCM_SCP0:	.equ	$e8

PO_HEAD_ID1:	.equ	'pocH'
PO_HEAD_ID2:	.equ	'i'<<24+EOF<<16
PO_PCM_FILE_A:	.equ	20
PO_PCM_FILE_B:	.equ	24
PO_TITLE:	.equ	28

MKI_TEXT:	.equ	8
MAG_TEXT:	.equ	8
*MAG_USER:	.equ	12
*MAG_COMMENT:	.equ	32
HG_ID_SIZE:	.equ	7
PI_ID_SIZE:	.equ	2
PIC_ID_SIZE:	.equ	3

MIT_HEAD_ID:	.equ	'HK03'
MIT_ID_SIZE:	.equ	4

VDT_COMMENT:	.equ	3
SVD_COMMENT:	.equ	3
XVD_TITLE:	.equ	68
XVD_REV:	.equ	136
BRC_TITLE:	.equ	44
ISPR_COMMENT:	.equ	38
WAP_TITLE:	.equ	64
DAN_COMMENT:	.equ	34

DIM_COMMENT:	.equ	194
DIM_HEADER:	.equ	171


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&pdx-filename			*
*************************************************

＆pdx_filename::
		move.l	d7,d6
		moveq	#-1,d7			;ファイルハンドル

		bsr	change_to_mintdata
		jsr	(unset_user_value_arg)

		lea	(-READ_BUF_SIZE,sp),sp
		lea	(sp),a1
		tst.l	d6
		beq	pdx_filename_error

		clr	-(sp)
		move.l	a0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d7
		bmi	pdx_filename_error

		move.l	a1,-(sp)
		move.l	a0,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bne	pdx_filename_error

		move.l	(NAMECK_Ext,sp),d1
		ori.l	#$0020_2020,d1
		lea	(ext_table,pc),a0
		lea	(pdx_filename_job_table-2,pc),a2
@@:
		move.l	(a0)+,d0
		bmi	pdx_filename_unknown_ext
		addq.l	#2,a2
		cmp.l	d0,d1
		bne	@b

		adda	(a2),a2
		jmp	(a2)

pdx_filename_unknown_ext:
		lea	(a1),a0
		bsr	clear_read_buf
		bsr	data_title_read_file
		ble	pdx_filename_error

		bsr	data_title_seek_file_top
		bmi	pdx_filename_error

		movem.l	(a1),d0-d1

		cmpi.l	#MDC_HEAD_ID,d0
		beq	pdx_filename_mdc
		cmpi.l	#MND_HEAD_ID,d0
		beq	pdx_filename_mnd

		cmpi.l	#ZMD2_HEAD_ID1,d0
		bne	@f
		move.l	d1,d2
		clr.b	d2
		cmpi.l	#ZMD2_HEAD_ID2,d2
		beq	pdx_filename_zmd2
@@:
		cmpi.l	#ZMD3_HEAD_ID1,d0
		bne	@f
		cmpi.l	#ZMD3_HEAD_ID2,d1
		beq	pdx_filename_zmd3
@@:
		move.l	d0,d2
		subi.l	#SCM_HEAD_ID,d2
		subq.l	#2,d2			;SCM2 対応
		bls	pdx_filename_scm

		cmpi.l	#PO_HEAD_ID1,d0
		bne	@f
		cmpi.l	#PO_HEAD_ID2,d1
		beq	pdx_filename_po
@@:
		bra	pdx_filename_error

pdx_filename_zms:
pdx_filename_zm3:
		bsr	pdx_filename_zms_sub
		bra	1f
pdx_filename_zmd2:
		bsr	pdx_filename_zmd2_sub
		bra	1f
pdx_filename_zmd3:
		bsr	pdx_filename_zmd3_sub
1:		move.l	#'.zpd',d1
		bra	pdx_filename_add_ext

pdx_filename_mdc:
		bsr	pdx_filename_mdc_sub
		bra	@f
pdx_filename_mnd:
		bsr	pdx_filename_mnd_sub
		bra	@f
pdx_filename_scm:
		bsr	pdx_filename_scm_sub
		bra	@f
pdx_filename_po:
		bsr	pdx_filename_po_sub
		bra	@f
pdx_filename_kdd:
		bsr	pdx_filename_kdd_sub
		bra	@f

pdx_filename_mdx:
pdx_filename_mdr:
pdx_filename_mdz:
		bsr	pdx_filename_mdxrz_sub
		move.l	#'.pdx',d1
pdx_filename_add_ext:
		lea	(sp),a1
		bsr	pdx_filename_add_ext_sub
@@:
		tst	d0
		beq	pdx_filename_error
		tst.b	(sp)
		beq	pdx_filename_error

		bsr	set_status
		lea	(sp),a2
		jsr	(set_user_value_arg_a2)
pdx_filename_end:
		move	d7,(sp)
		bmi	@f
		DOS	_CLOSE
@@:
		lea	(READ_BUF_SIZE,sp),sp

		bra	restore_to_mint
**		rts

pdx_filename_error:
		bsr	set_status_0
		bra	pdx_filename_end


* 音楽データ種類別処理 ------------------------ *
* in	d7.w	ファイルハンドル
*	a1.l	バッファ(256bytes)
* out	d0.w	エラーコード(0:error 1～:ok)
* a0/a1を破壊しない事！

pdx_filename_kdd_sub:
pdx_filename_mdxrz_sub:
		move.l	a1,-(sp)
@@:
		bsr	data_title_fgetc	;タイトルを飛ばす
		bmi	pdx_filename_mdxrz_error
		cmpi.b	#EOF,d0
		bne	@b
pdx_filename_mdc_getstr:
pdx_filename_mnd_getstr:
pdx_filename_zmd3_getstr:
		move	#READ_BUF_SIZE-1,d1
@@:
		bsr	data_title_fgetc
		bmi	pdx_filename_mdxrz_error
		move.b	d0,(a1)+
		dbeq	d1,@b
		beq	@f
pdx_filename_mdxrz_error:
pdx_filename_mdc_error:
pdx_filename_mnd_error:
		movea.l	(sp)+,a1
		clr.b	(a1)
		moveq	#0,d0
		rts
@@:
		movea.l	(sp)+,a1
		moveq	#1,d0
		rts

pdx_filename_mnd_sub:
		move.l	a1,-(sp)
		cmpi	#MND_PCMFILE+4,(MND_HEAD_SIZE,a1)
		bcs	pdx_filename_mnd_error

		move.l	(MND_PCMFILE,a1),d0
		beq	pdx_filename_mnd_error
		bsr	data_title_seek_file		
		bmi	pdx_filename_mnd_error

		bsr	data_title_fgetc	;ファイル数(1.w)
		move.l	d0,-(sp)
		bsr	data_title_fgetc
		or.l	(sp)+,d0
		bgt	pdx_filename_mnd_getstr
		bra	pdx_filename_mnd_error

pdx_filename_mdc_sub:
		move.l	a1,-(sp)
		move.l	(MDC_ADPCM,a1),d0
		bra	@f

pdx_filename_scm_sub:
		move.l	a1,-(sp)
		moveq	#0,d0
		move	(SCM_SCP0,a1),d0
		bra	@f

pdx_filename_po_sub:
		move.l	a1,-(sp)
		move.l	(PO_PCM_FILE_A,a1),d0
		bne	@f
		move.l	(PO_PCM_FILE_B,a1),d0
@@:
		beq	pdx_filename_mdc_error
		bsr	data_title_seek_file
		bpl	pdx_filename_mdc_getstr
		bra	pdx_filename_mdc_error

pdx_filename_zms_sub:
		PUSH	a0-a1
		lea	(a1),a0
		move	(＄zmst),d6
		subq	#1,d6
		bcs	pdx_filename_zms_error
pdx_filename_zms_loop:
		bsr	data_title_fgets
		bmi	pdx_filename_zms_error
		cmpi.b	#'.',(a1)
		bne	pdx_filename_zms_next

		ori.l	#$202020,(a1)
		cmpi.l	#'.zpd',(a1)+
		beq	pdx_filename_zms_found

		cmpi	#17+2,d0		;strlen(".adpcm_block_data=X")
		bcs	pdx_filename_zms_next

		moveq	#17-4-1,d0
@@:
*		move.b	(a1)+,d1
*		subi.b	#'A',d1
*		cmpi.b	#'Z'-'A',d1
		cmpi.b	#'Z',(a1)+
		bhi	1f
		ori.b	#$20,(-1,a1)
1:		dbra	d0,@b

		lea	(-16,a1),a1
		lea	(adpcm_block_data_str,pc),a2
		moveq	#16-1,d0
@@:
		cmpm.b	(a1)+,(a2)+
		dbne	d0,@b
		beq	pdx_filename_zms_found
pdx_filename_zms_next:
		dbra	d6,pdx_filename_zms_loop
		bra	pdx_filename_zms_error

pdx_filename_zms_found:
@@:		bsr	is_tab_or_space		;'='の左の空白
		beq	@b
		cmpi.b	#'=',d0
		bne	pdx_filename_zms_no_equal
@@:		bsr	is_tab_or_space		;'='の右〃
		beq	@b
pdx_filename_zms_no_equal:
		move.b	d0,-(a1)		;subq.l #1,a1 / tst.b d0
		beq	pdx_filename_zms_next
@@:
		bsr	is_tab_or_space		;空白以降は削除
		beq	@f
		move.b	d0,(a0)+		;ファイル名をバッファ先頭に移動
		bne	@b
@@:		clr.b	(a0)

		moveq	#1,d0
pdx_filename_zms_end:
		POP	a0-a1
		rts
pdx_filename_zms_error:
		clr.b	(a0)
		moveq	#0,d0
		bra	pdx_filename_zms_end

pdx_filename_zmd2_sub:
		exg	a0,a1
		moveq	#0,d6
		moveq	#8,d0			;ファイルポインタ
pdx_filename_zmd2_loop:
		add.l	d0,d6
pdx_filename_zmd2_loop2:
pdx_zmd2_0x7e:
		bsr	data_title_seek_file_d6
		bmi	pdx_filename_zmd2_error

		addq.l	#1,d6
		bsr	data_title_fgetc	;共通コマンドの種類
		bmi	pdx_filename_zmd2_error

		lea	(zmd2_table,pc),a2
		moveq	#-2,d2
@@:
		addq	#2,d2
		move.b	(a2)+,d1
		beq	pdx_filename_zmd2_error	;知らない共通コマンドだった
		cmp.b	d0,d1
		bne	@b
@@:
		lea	(pdx_zmd2_job_table,pc),a2
		adda	(a2,d2.w),a2
		jmp	(a2)

pdx_zmd2_0x04:
pdx_zmd2_0x1b:
		moveq	#57-1,d0
		bra	pdx_filename_zmd2_loop
pdx_zmd2_0x05:
		moveq	#3-1,d0
		bra	pdx_filename_zmd2_loop
pdx_zmd2_0x15:
		moveq	#2-1,d0
		bra	pdx_filename_zmd2_loop
pdx_zmd2_0x18:
		moveq	#2,d0
		bsr	data_title_read_file2
		bne	pdx_filename_zmd2_error
		moveq	#0,d0
		move	(a0),d0
		bra	pdx_filename_zmd2_loop
pdx_zmd2_0x40:
		moveq	#24,d0
		bsr	data_title_read_file2
		bne	pdx_filename_zmd2_error
		moveq	#24,d0
		tst.b	(20,a0)
		beq	pdx_filename_zmd2_loop

		moveq	#21,d0
		add.l	d0,d6
		bsr	data_title_seek_file_d6
		bmi	pdx_filename_zmd2_error
pdx_zmd2_0x60:
pdx_zmd2_0x61:
pdx_zmd2_0x62:
pdx_zmd2_0x7f:
@@:		addq.l	#1,d6
		bsr	data_title_fgetc	;ファイル名をとばす
		bmi	pdx_filename_zmd2_error
		bne	@b
		bra	pdx_filename_zmd2_loop2
pdx_zmd2_0x42:
		moveq	#6-1,d0
		bra	pdx_filename_zmd2_loop
pdx_zmd2_0x4a:
		moveq	#6,d0
		addq.l	#6,d6
		bsr	data_title_read_file2
		bne	pdx_filename_zmd2_error

		moveq	#0,d0
		move	(a0),d0
		bra	pdx_filename_zmd2_loop

pdx_zmd2_0x63:
		bsr	data_title_read_file
		ble	pdx_filename_zmd2_error

		exg	a0,a1
		moveq	#1,d0
		rts
pdx_filename_zmd2_error:
		exg	a0,a1
		clr.b	(a1)
		moveq	#0,d0
		rts
		
pdx_zmd2_job_table:
@@:		.dc	pdx_zmd2_0x04-@b
		.dc	pdx_zmd2_0x05-@b
		.dc	pdx_zmd2_0x15-@b
		.dc	pdx_zmd2_0x18-@b
		.dc	pdx_zmd2_0x1b-@b
		.dc	pdx_zmd2_0x40-@b
		.dc	pdx_zmd2_0x42-@b
		.dc	pdx_zmd2_0x4a-@b
		.dc	pdx_zmd2_0x60-@b
		.dc	pdx_zmd2_0x61-@b
		.dc	pdx_zmd2_0x62-@b
		.dc	pdx_zmd2_0x63-@b
		.dc	pdx_zmd2_0x7e-@b
		.dc	pdx_zmd2_0x7f-@b

pdx_filename_zmd3_sub_dttl:
		move.l	a1,-(sp)
		move.l	d1,d0
		bra	@f
pdx_filename_zmd3_sub:
		move.l	a1,-(sp)
		move.l	(ZMD3_COMMON,a0),d0
@@:		beq	pdx_filename_zmd3_error
		addq.l	#ZMD3_COMMON,d0
		addq.l	#4,d0
		bsr	data_title_seek_file
		bmi	pdx_filename_zmd3_error
pdx_filename_zmd3_loop:
		bsr	data_title_fgetc
		bmi	pdx_filename_zmd3_error
		beq	pdx_filename_zmd3_00init
		cmpi.b	#$28,d0
		beq	pdx_filename_zmd3_28zpd
		subi.b	#$40,d0
		beq	pdx_filename_zmd3_40comment
		subq.b	#$44-$40,d0
		beq	pdx_filename_zmd3_44print
		subq.b	#$48-$44,d0		;dummy
		beq	pdx_filename_zmd3_loop
pdx_filename_zmd3_error:
		movea.l	(sp)+,a1
		clr.b	(a1)
		moveq	#0,d0
		rts

pdx_filename_zmd3_00init:
		bsr	data_title_fgetc
		bmi	pdx_filename_zmd3_error
		bra	pdx_filename_zmd3_loop

pdx_filename_zmd3_40comment:
pdx_filename_zmd3_44print:
@@:		bsr	data_title_fgetc
		bmi	pdx_filename_zmd3_error
		bne	@b
		bra	pdx_filename_zmd3_loop

pdx_filename_zmd3_28zpd:
		bsr	data_title_fgetc
		bmi	pdx_filename_zmd3_error
		subq.b	#2,d0
		bls	pdx_filename_zmd3_error

		move	#SEEK_CUR,-(sp)		;今読んだ分を戻す
		pea	(-1)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	pdx_filename_zmd3_error
		bra	pdx_filename_zmd3_getstr


* 拡張子補完 ---------------------------------- *
* in	d1.l	拡張子('.pdx')
*	a1.l	バッファ(256bytes)

pdx_filename_add_ext_sub:
		tst.b	(a1)
		beq	pdx_filename_add_ext_skip

		move	d0,-(sp)
		lea	(-NAMECK_SIZE,sp),sp
		move.l	sp,-(sp)
		move.l	a1,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bne	pdx_filename_add_ext_end
		tst.b	(NAMECK_Ext,sp)
		bne	pdx_filename_add_ext_end

@@:		tst.b	(a1)+
		bne	@b
		subq.l	#1,a1
		move.l	d1,(sp)
		move.b	(0,sp),(a1)+
		move.b	(1,sp),(a1)+
		move.b	(2,sp),(a1)+
		move.b	(3,sp),(a1)+
		clr.b	(a1)
pdx_filename_add_ext_end:
		lea	(NAMECK_SIZE,sp),sp
		move	(sp)+,d0
pdx_filename_add_ext_skip:
		rts


* 汎用サブルーチン ---------------------------- *

set_status_0:
		moveq	#0,d0
		bra	set_status
set_status_1:
		moveq	#1,d0
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts


change_to_mintdata:
		move.l	#'DATA',d0
		jmp	(change_exec_filename)
*		rts

restore_to_mint:
		jmp	(restore_exec_filename)
*		rts


*************************************************
*		&data-title			*
*************************************************

		.offset	0
~title_buf:	.ds.b	READ_BUF_SIZE
~pdxname_buf:	.ds.b	READ_BUF_SIZE
sizeof_DATA_TITLE_BUF:
		.text

clear_read_buf:
		PUSH	d0-d1/a0
		moveq	#READ_BUF_SIZE/4/4-1,d0
		moveq	#0,d1
@@:
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		dbra	d0,@b
		POP	d0-d1/a0
data_title_dttl_0:
		rts


＆data_title::
		tst	(＄dttl)
		beq.s	data_title_dttl_0

		bsr	change_to_mintdata

		lea	(-sizeof_DATA_TITLE_BUF,sp),sp
		tst.l	d7
		bne	@f			;ファイル指定あり
*data_title_curfile:
		jsr	(search_cursor_file)	;カーソル位置ファイル
*		jsr	(is_parent_dir_a4)
*		bne	data_title_error
*		cmpi.b	#-1,(DIR_ATR,a4)
*		beq	data_title_error
		btst	#DIRECTORY,(DIR_ATR,a4)
		bne	data_title_error

		lea	(~title_buf,sp),a0	;filename
		lea	(DIR_NAME,a4),a1
		lea	(a0),a2
		jsr	(copy_dir_name_a1_a2)
@@:
		pea	(READ_BUF_SIZE-NAMECK_SIZE,sp)
		move.l	a0,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bne	data_title_error

		move.l	(READ_BUF_SIZE-NAMECK_SIZE+NAMECK_Ext,sp),d1
		ori.l	#$0020_2020,d1		;'.???'or'.?? '

		cmpi	#2,(＄dttl)
		bne	skip_ext_check
		tst.l	d1
		beq	data_title_error

		lea	(ext_table_all,pc),a1
@@:
		move.l	(a1)+,d0		;%dttl 2なら対応データの拡張子を持つ
		bmi	data_title_error	;ファイル以外は無視する
		cmp.l	d0,d1
		bne	@b
skip_ext_check:
		clr	-(sp)
		move.l	a0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d7
		bmi	data_title_error

		lea	(~pdxname_buf,sp),a0
		bsr	clear_read_buf

		lea	(~title_buf,sp),a0
		bsr	clear_read_buf
		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	data_title_seek_file_top
		bmi	data_title_error_close

;ヘッダで判別できないデータファイルは拡張子で振り分ける.
		tst.l	d1
		beq	data_title_unknown_ext

		lea	(ext_table,pc),a1
		lea	(ext_job_table-2,pc),a2
@@:
		move.l	(a1)+,d0
		bmi	data_title_unknown_ext
		addq.l	#2,a2
		cmp.l	d0,d1
		bne	@b

		adda	(a2),a2
		jmp	(a2)

;ファイル先頭の識別子で振り分ける.
data_title_unknown_ext:
		movem.l	(a0),d0-d1

;音楽データ
		cmpi.l	#MDC_HEAD_ID,d0
		beq	data_title_mdc
		cmpi.l	#MND_HEAD_ID,d0
		beq	data_title_mnd

		cmpi.l	#ZMD2_HEAD_ID1,d0
		bne	@f
		move.l	d1,d2
		clr.b	d2
		cmpi.l	#ZMD2_HEAD_ID2,d2
		beq	data_title_zmd2
@@:
		cmpi.l	#ZMD3_HEAD_ID1,d0
		bne	@f
		cmpi.l	#ZMD3_HEAD_ID2,d1
		beq	data_title_zmd3
@@:
		cmpi.l	#'MThd',d0
		beq	data_title_mid		;.mid/.smf

		cmpi.l	#'RCM-',d0
		bne	@f
		cmpi.l	#'PC98',d1
		bne	@f
		cmpi.l	#'V2.0',(8,a0)
		beq	data_title_rcp
@@:
		move.l	d0,d2
		subi.l	#SCM_HEAD_ID,d2
		subq.l	#2,d2			;SCM2 対応
		bls	data_title_scm

		cmpi.l	#PO_HEAD_ID1,d0
		bne	@f
		cmpi.l	#PO_HEAD_ID2,d1
		beq	data_title_po
@@:
		move.l	d0,d2
		subi.l	#'RCZ'<<8,d2
		subq.l	#2,d2
		bls	data_title_rcz

		cmpi	#CR<<8+LF,(4,a0)
		bne	@f
		cmpi.l	#'MDF0',d0
		beq	data_title_mdf
		cmpi.l	#'ZDF0',d0
		beq	data_title_zdf
@@:

;画像データ
		cmpi.l	#'MAKI',d0
		bne	not_maki
		cmpi.l	#'01A ',d1
		beq	@f
		cmpi.l	#'01B ',d1
@@:		beq	data_title_mki
		cmpi.l	#'02  ',d1
		beq	data_title_mag
not_maki:
		cmpi	#'HG',(a0)
		bne	@f
		cmpi.b	#'.',d0
		bne	@f
		move.l	d1,d2
		lsr.l	#8,d2
		cmpi	#CR<<8+LF,d2
		beq	data_title_hg
@@:
		cmpi	#'Pi',(a0)
		beq	data_title_pi

		move.l	d0,d2
		clr.b	d2
		cmpi.l	#'PIC'<<8,d2
		beq	data_title_pic

		move.l	d0,d2
		subi.l	#MIT_HEAD_ID,d2
		beq	@f
		subq.l	#1,d2			;'HK04'
@@:		beq	data_title_mit

;動画データ
		move.l	d0,d2
		clr.b	d2
		cmpi.l	#'SiV'<<8,d2
		beq	data_title_vdt

		cmpi.l	#'SjV'<<8,d2
		beq	@f
		cmpi.l	#'SIV'<<8,d2
@@:		beq	data_title_svd

		cmpi.l	#'XVDF',d0
		bne	@f
		cmpi	#2,(XVD_REV,a0)
		beq	data_title_xvd
@@:
		cmpi.l	#'BRC'<<8,d0
		beq	data_title_brc

		cmpi.l	#'ISPR',d0
		bne	@f
		move.l	d1,d2
		swap	d2
		cmpi	#'-V',d2
		beq	data_title_ispr
@@:
		cmpi.l	#'Wapi',d0
		beq	data_title_wap

		cmpi.l	#'DAND',d0
		bne	@f
		cmpi	#'AT',(4,a0)
		beq	data_title_dan
@@:

;その他のデータ
		lea	(DIM_HEADER-1,a0),a1
		move.l	(a1)+,-(sp)
		clr.b	(sp)
		cmpi.l	#'DIF',(sp)+
		bne	@f
		cmpi.l	#'C HE',(a1)+
		bne	@f
		cmpi.l	#'ADER',(a1)+
		bne	@f
		cmpi.l	#'  '<<16+$0000,(a1)+
		beq	data_title_dim
@@:
		cmpi.l	#LOCAL_HDR_SIG,d0	;sfxまで対応すると
		beq	data_title_zip		;重くなってしまうので無視

*data_title_unknown_data:
		bra	data_title_error_close


* 終了処理/エラー処理
data_title_error_close:
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
data_title_error:
		jsr	(print_music_title)
		jsr	(interrupt_window_print)
		moveq	#0,d0
		bra	@f
data_title_end:
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		moveq	#1,d0
@@:
		bsr	set_status
		lea	(sizeof_DATA_TITLE_BUF,sp),sp
		bra	restore_to_mint
**		rts


* 音楽データ種類別処理 ------------------------ *

data_title_mdx:
		moveq	#MES_D_MDX,d0
		bra	@f
data_title_mdr:
		moveq	#MES_D_MDR,d0
		bra	@f
data_title_mdz:
		moveq	#MES_D_MDZ,d0
		bra	@f
@@:
		lea	(~pdxname_buf,sp),a1
		move.l	d0,-(sp)
		bsr	pdx_filename_mdxrz_sub
		move.l	(sp)+,d0
		bra	data_title_set_header

data_title_mdc:
		lea	(~pdxname_buf,sp),a1
		move.l	(MDC_ADPCM,a0),(MDC_ADPCM,a1)

		move.l	(MDC_TITLE,a0),d0
		bsr	data_title_seek_file
		bmi	data_title_error_close

		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	pdx_filename_mdc_sub

		moveq	#MES_D_MDC,d0
		bra	data_title_set_header

data_title_mnd:
		lea	(~pdxname_buf,sp),a1
		move	(MND_HEAD_SIZE,a0),(MND_HEAD_SIZE,a1)
		move.l	(MND_PCMFILE,a0),(MND_PCMFILE,a1)

		move.l	(MND_TITLE,a0),d0
		bsr	data_title_seek_file
		bmi	data_title_error_close

		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	pdx_filename_mnd_sub

		moveq	#MES_D_MND,d0
		bra	data_title_set_header

data_title_seek_file_d6:
		move.l	d6,d0
		bra	data_title_seek_file
data_title_seek_file_top:
		moveq	#0,d0
data_title_seek_file:
		clr	-(sp)			;SEEK_SET
		move.l	d0,-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		rts

data_title_zms:
data_title_zm3:
		move	(＄zmst),d6
data_title_zms_next:
		dbra	d6,data_title_zms_loop
		bra	data_title_error_close
data_title_zms_loop:
		bsr	data_title_fgets
		bmi	data_title_error_close
		subq	#8,d0			;8=strlen(".COMMENT")
		bcs	data_title_zms_next

		move.l	(a1)+,d0
		ori.l	#$0020_2020,d0
		cmpi.l	#'.com',d0
		bne	data_title_zms_next
		move.l	(a1)+,d0
		ori.l	#$2020_2020,d0
		cmpi.l	#'ment',d0
		bne	data_title_zms_next
@@:
		bsr	is_tab_or_space
		beq	@b
*		subq.l	#1,a1
*		tst.b	d0
		move.b	d0,-(a1)
		beq	data_title_error_close
		cmpi.b	#'{',d0
		bne	@f

		bsr	data_title_fgets
		bmi	data_title_error_close
@@:
		lea	(a1),a0

		bsr	data_title_seek_file_top
		lea	(~pdxname_buf,sp),a1
		bsr	pdx_filename_zms_sub

		moveq	#MES_D_ZMS,d0
		bra	data_title_set_header

data_title_fgets:
		lea	(a0),a1
		move	#(READ_BUF_SIZE-4)<<8,(a1)+
		move	d7,-(sp)
		move.l	a0,-(sp)
		DOS	_FGETS
		addq.l	#6,sp
		tst.l	d0
		rts

is_tab_or_space:
		move.b	(a1)+,d0
		cmpi.b	#TAB,d0
		beq	@f
		cmpi.b	#SPACE,d0
@@:		rts

data_title_zmd2:
		moveq	#0,d6
		moveq	#8,d0			;ファイルポインタ
data_title_zmd2_loop:
		add.l	d0,d6
data_title_zmd2_loop2:
zmd2_0x7e:
		bsr	data_title_seek_file_d6
		bmi	data_title_error_close

		addq.l	#1,d6
		bsr	data_title_fgetc	;共通コマンドの種類
		bmi	data_title_error_close

		lea	(zmd2_table,pc),a2
		moveq	#-2,d2
@@:
		addq	#2,d2
		move.b	(a2)+,d1
		beq	data_title_error_close	;知らない共通コマンドだった
		cmp.b	d0,d1
		bne	@b
@@:
		lea	(zmd2_job_table,pc),a2
		adda	(a2,d2.w),a2
		jmp	(a2)

zmd2_0x04:
zmd2_0x1b:
		moveq	#57-1,d0
		bra	data_title_zmd2_loop
zmd2_0x05:
		moveq	#3-1,d0
		bra	data_title_zmd2_loop
zmd2_0x15:
		moveq	#2-1,d0
		bra	data_title_zmd2_loop
zmd2_0x18:
		moveq	#2,d0
		bsr	data_title_read_file2
		bne	data_title_error_close
		moveq	#0,d0
		move	(a0),d0
		bra	data_title_zmd2_loop
zmd2_0x40:
		moveq	#24,d0
		bsr	data_title_read_file2
		bne	data_title_error_close
		moveq	#24,d0
		tst.b	(20,a0)
		beq	data_title_zmd2_loop

		moveq	#21,d0
		add.l	d0,d6
		bsr	data_title_seek_file_d6
		bmi	data_title_error_close
zmd2_0x60:
zmd2_0x61:
zmd2_0x62:
zmd2_0x63:
@@:		addq.l	#1,d6
		bsr	data_title_fgetc	;ファイル名をとばす
		bmi	data_title_error_close
		bne	@b
		bra	data_title_zmd2_loop2
zmd2_0x42:
		moveq	#6-1,d0
		bra	data_title_zmd2_loop
zmd2_0x4a:
		moveq	#6,d0
		addq.l	#6,d6
		bsr	data_title_read_file2
		bne	data_title_error_close

		moveq	#0,d0
		move	(a0),d0
		bra	data_title_zmd2_loop

zmd2_0x7f:
		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	data_title_seek_file_top
		lea	(~pdxname_buf,sp),a1
		bsr	pdx_filename_zmd2_sub

		moveq	#MES_D_ZMD,d0
		bra	data_title_set_header

data_title_read_file:
		pea	(READ_BUF_SIZE-1)
		move.l	a0,-(sp)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		ble	@f
		sf	(a0,d0.l)
@@:		rts

data_title_read_file2:
		move.l	d0,-(sp)
		move.l	a0,-(sp)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		rts

zmd2_table:
		.dc.b	$04
		.dc.b	$05
		.dc.b	$15
		.dc.b	$18
		.dc.b	$1b
		.dc.b	$40
		.dc.b	$42
		.dc.b	$4a
		.dc.b	$60
		.dc.b	$61
		.dc.b	$62
		.dc.b	$63
		.dc.b	$7e
		.dc.b	$7f
		.dc.b	0			;$ffは調べなくてよい
		.even

zmd2_job_table:
@@:		.dc	zmd2_0x04-@b
		.dc	zmd2_0x05-@b
		.dc	zmd2_0x15-@b
		.dc	zmd2_0x18-@b
		.dc	zmd2_0x1b-@b
		.dc	zmd2_0x40-@b
		.dc	zmd2_0x42-@b
		.dc	zmd2_0x4a-@b
		.dc	zmd2_0x60-@b
		.dc	zmd2_0x61-@b
		.dc	zmd2_0x62-@b
		.dc	zmd2_0x63-@b
		.dc	zmd2_0x7e-@b
		.dc	zmd2_0x7f-@b

data_title_fgetc:
		move	d7,-(sp)
		DOS	_FGETC
		addq.l	#2,sp
		tst.l	d0
		rts

data_title_zmd3:
		move.l	(ZMD3_TITLE,a0),d1
		beq	data_title_error_close

		moveq	#ZMD3_TITLE+4,d0
		add.l	d1,d0
		bsr	data_title_seek_file
		bmi	data_title_error_close

		move.l	(ZMD3_COMMON,a0),d1	;タイトルで破壊しちゃうので

		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	data_title_seek_file_top
		lea	(~pdxname_buf,sp),a1
		bsr	pdx_filename_zmd3_sub_dttl

		moveq	#MES_D_ZMD,d0
		bra	data_title_set_header

data_title_mid:
		moveq	#$17,d0			;真面目にやっても大変な割に
		bsr	data_title_seek_file	;報われないような気がするので
		bmi	data_title_error_close	;mint ver2.25と同じ手抜き処理.
@@:
		bsr	data_title_fgetc
		bmi	data_title_error_close
*		cmpi.b	#$ff,d0
		not.b	d0
		bne	@b
		bsr	data_title_fgetc
		bmi	data_title_error_close
		cmpi.b	#$07,d0
		bhi	@b

		bsr	data_title_fgetc
		bmi	data_title_error_close
		bsr	data_title_read_file2
		bne	data_title_error_close
		clr.b	(a0,d0.l)

		moveq	#MES_D_MID,d0
		bra	data_title_set_header

data_title_rcp:
		lea	(RCP_HEAD_SIZE,a0),a0
		clr.b	(RCP_TITLE_SIZE,a0)

		moveq	#MES_D_RCP,d0
		bra	data_title_set_header

data_title_scm:
		lea	(~pdxname_buf,sp),a1
		move	(SCM_SCP0,a0),(SCM_SCP0,a1)

		moveq	#0,d0
		move	(SCM_TITLE,a0),d0
		beq	data_title_error_close
		bsr	data_title_seek_file
		bmi	data_title_error_close
		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	pdx_filename_scm_sub

		moveq	#MES_D_SCM,d0
		bra	data_title_set_header

data_title_po:
		lea	(~pdxname_buf,sp),a1
		move.l	(PO_PCM_FILE_A,a0),(PO_PCM_FILE_A,a1)
		move.l	(PO_PCM_FILE_B,a0),(PO_PCM_FILE_B,a1)

		move.l	(PO_TITLE,a0),d0
		beq	data_title_error_close
		bsr	data_title_seek_file
		bmi	data_title_error_close
		bsr	data_title_read_file
		ble	data_title_error_close

		bsr	pdx_filename_po_sub

		moveq	#MES_D_PO_,d0
		bra	data_title_set_header

data_title_kdd:
		lea	(~pdxname_buf,sp),a1
		bsr	pdx_filename_kdd_sub

		moveq	#MES_D_KDD,d0
		bra	data_title_set_header

data_title_rcz:
		addq.l	#RCZ_TITLE,a0
		clr.b	(RCZ_TITLE_SIZE,a0)

		moveq	#MES_D_RCZ,d0
		bra	data_title_set_header

data_title_mdf:
		moveq	#MES_D_MDF,d0
		bra	@f

data_title_zdf:
		moveq	#MES_D_ZDF,d0
@@:
		lea	(ZDF_TITLE2,a0),a2
		addq.l	#ZDF_TITLE,a0
		lea	(ZDF_TITLE_SIZE,a0),a3
		moveq	#ZDF_TITLE2_SIZE-1,d1
@@:
		move.b	(a2)+,(a3)+		;タイトル２を１の末尾に結合
		dbra	d1,@b
		bra	data_title_set_header


* 画像データ種類別処理 ------------------------ *

data_title_mki:
		moveq	#MES_D_MKI,d0
		bra	@f
		addq.l	#MKI_TEXT,a0
		bra	data_title_set_header

data_title_mag:
		moveq	#MES_D_MAG,d0
@@:
*		lea	(MAG_USER,a0),a0
*		lea	(MAG_COMMENT,a0),a0
		addq.l	#MAG_TEXT,a0		;セーバ名以降を表示
		.fail	MKI_TEXT.ne.MAG_TEXT
		bra	data_title_set_header

data_title_hg:
		addq.l	#HG_ID_SIZE,a0
		moveq	#MES_D_HG_,d0
		bra	data_title_set_header

data_title_pi:
		addq.l	#PI_ID_SIZE,a0
		moveq	#MES_D_PI_,d0
		bra	data_title_set_header

data_title_pic:
		addq.l	#PIC_ID_SIZE,a0
		moveq	#MES_D_PIC,d0
		bra	data_title_set_header

data_title_mit:
		addq.l	#MIT_ID_SIZE,a0
		moveq	#MES_D_MIT,d0
		bra	data_title_set_header


* 動画データ種類別処理 ------------------------ *

data_title_vdt:
		addq.l	#VDT_COMMENT,a0
		moveq	#MES_D_VDT,d0
		bra	data_title_set_header

data_title_svd:
		addq.l	#SVD_COMMENT,a0
		moveq	#MES_D_SVD,d0
		bra	data_title_set_header

data_title_xvd:
		lea	(XVD_TITLE,a0),a0
		moveq	#MES_D_XVD,d0
		bra	data_title_set_header

data_title_brc:
		lea	(BRC_TITLE,a0),a0
		moveq	#MES_D_BRC,d0
		bra	data_title_set_header

data_title_ispr:
		movep	(6,a0),d1
		lea	(ISPR_COMMENT,a0),a0
		cmpi	#'CM',(a0)+
		bne	data_title_error_close

		moveq	#MES_D_ISY,d0
		cmpi	#'35',d1
		beq	@f
		moveq	#MES_D_ISM,d0
		cmpi	#'40',d1
		beq	@f
		moveq	#MES_D_ISZ,d0
		cmpi	#'45',d1
		beq	@f
		moveq	#MES_D_ISD,d0
@@:		bra	data_title_set_header

data_title_wap:
		lea	(WAP_TITLE,a0),a0
		moveq	#MES_D_WAP,d0
		bra	data_title_set_header

data_title_dan:
		move.l	(DAN_COMMENT,a0),d0
		beq	data_title_error_close
		bsr	data_title_seek_file
		bmi	data_title_error_close

		bsr	data_title_read_file
		bmi	data_title_error_close

		moveq	#MES_D_DAN,d0
		bra	data_title_set_header


* その他のデータ種類別処理 -------------------- *

data_title_dim:
		lea	(DIM_COMMENT,a0),a0
		moveq	#MES_D_DIM,d0
		bra	data_title_set_header

data_title_zip:
		lea	(a0),a2

		lea	(Buffer),a4		;1KB 以上必要なのでスタックでは危険
		jsr	(zip_search_zecdr)
		tst.l	d6
		bmi	data_title_error_close

		moveq	#0,d1
		lea	(ZECDR_zipfile_comment_length,a0),a0
		move.b	(a0)+,-(sp)
		move.b	(a0)+,-(sp)
		move	(sp)+,d1
		move.b	(sp)+,d1
		tst	d1			;コメント長
		beq	data_title_error_close
		cmpi	#READ_BUF_SIZE-1,d1
		bls	@f
		move	#READ_BUF_SIZE-1,d1
@@:
		moveq	#ZECDR_SIZE,d0
		add.l	d6,d0
		bsr	data_title_seek_file
		bmi	data_title_error_close

		lea	(a2),a0
		move.l	d1,d0
		bsr	data_title_read_file2
		bmi	data_title_error_close
		clr.b	(a0,d0.l)
@@:
		move.b	(a0)+,d0
		beq	data_title_error_close
		cmpi.b	#CR,d0
		beq	@b
		cmpi.b	#LF,d0
		beq	@b
		subq.l	#1,a0

		moveq	#MES_D_ZIP,d0
		bra	data_title_set_header


* 共通処理 ------------------------------------ *
* in	d0.w	タイトルヘッダのメッセージ番号
*	a0.l	データタイトル
*	a1.l	.pdx/.zpd/音楽データファイル名

data_title_set_header:
		move	d0,d1
		move.b	(a0),d0
		beq	data_title_error_close
		bsr	is_eof_or_cr_or_lf
		beq	data_title_error_close

		move	#MESD_TOP,d0
		add	d1,d0
		lea	(-128,sp),sp
		jsr	(get_message2)
		move.l	d0,a1
		lea	(sp),a2
		moveq	#96-1,d1
@@:
		move.b	(a1)+,(a2)+
		dbeq	d1,@b
		bne	data_title_set_header_end
		subq.l	#1,a2
		addq	#1,d1
data_title_set_header_loop:
		move.b	(a0)+,d0
		beq	data_title_set_header_end
		cmpi.b	#$20,d0
		bcc	data_title_set_header_copy
		bsr	is_eof_or_cr_or_lf
		beq	data_title_set_header_end
		cmpi.b	#ESC,d0
		bne	data_title_set_header_ctrl
		cmpi.b	#'[',(a0)
		bne	data_title_set_header_ctrl

		lea	(a0),a1			;^[[...m
		addq.l	#1,a0
data_title_set_header_esc_loop:
		move.b	(a0)+,d0		;ESCシーケンスを削除する
		cmpi.b	#'m',d0
		beq	data_title_set_header_loop
		cmpi.b	#';',d0
		beq	data_title_set_header_esc_loop
		subi.b	#'0',d0
		cmpi.b	#9,d0
		bls	data_title_set_header_esc_loop
		lea	(a1),a0			;^[[...m以外は削除しない
data_title_set_header_ctrl:
		moveq	#SPACE,d0
data_title_set_header_copy:
		move.b	d0,(a2)+
		dbra	d1,data_title_set_header_loop
data_title_set_header_end:
		clr.b	(a2)

		move	(＄mutc),d1
		move	(＄dbox),d2
		lea	(sp),a1
		jsr	(print_music_data_title_sub)
		lea	(128,sp),sp

		lea	(~pdxname_buf,sp),a1
		tst	(＄cplp)
		beq	@f
		tst	(＄6809)
		beq	@f
		tst.b	(a1)
		beq	print_pdx_filename_int

		move	(＄pdxc),d1
		moveq	#96-(17-1),d2
		move	(scr_cplp_line),d3
		moveq	#(17-1)-1,d4
		IOCS	_B_PUTMES

		jsr	(draw_int_win_box)
		bra	@f
print_pdx_filename_int:
		jsr	(interrupt_window_print)
@@:
		bra	data_title_end

is_eof_or_cr_or_lf:
		cmpi.b	#EOF,d0
		beq	@f
		cmpi.b	#CR,d0
		beq	@f
		cmpi.b	#LF,d0
@@:		rts


* Data  Section ------------------------------- *

*		.data
		.even

* ext_table に拡張子追加した場合は、同じ順番で
* ext_job_table と pdx_filename_job_table にも
* 処理ルーチンを追加すること.

ext_table_all:
		.dc.l	'.mdc'
		.dc.l	'.mnd'
		.dc.l	'.zmd'
		.dc.l	'.mid'
		.dc.l	'.smf'
		.dc.l	'.rcp'
		.dc.l	'.r36'
		.dc.l	'.scm'
		.dc.l	'.po '
		.dc.l	'.rcz'
		.dc.l	'.mdf'
		.dc.l	'.zdf'
		.dc.l	'.mki'
		.dc.l	'.mag'
		.dc.l	'.hg '
		.dc.l	'.pi '
		.dc.l	'.pic'
		.dc.l	'.mit'
		.dc.l	'.tft'
		.dc.l	'.vdt'
		.dc.l	'.v16'
		.dc.l	'.xvd'
		.dc.l	'.svd'
		.dc.l	'.brc'
		.dc.l	'.isd'
		.dc.l	'.iss'
		.dc.l	'.wap'
		.dc.l	'.dan'
		.dc.l	'.dim'
		.dc.l	'.zip'
ext_table:
		.dc.l	'.mdx'
		.dc.l	'.mdr'
		.dc.l	'.mdz'
		.dc.l	'.zms'
		.dc.l	'.zm3'
		.dc.l	'.kdd'
		.dc	-1

ext_job_table:
		.dc	data_title_mdx-$
		.dc	data_title_mdr-$
		.dc	data_title_mdz-$
		.dc	data_title_zms-$
		.dc	data_title_zm3-$
		.dc	data_title_kdd-$

pdx_filename_job_table:
		.dc	pdx_filename_mdx-$
		.dc	pdx_filename_mdr-$
		.dc	pdx_filename_mdz-$
		.dc	pdx_filename_zms-$
		.dc	pdx_filename_zm3-$
		.dc	pdx_filename_kdd-$

adpcm_block_data_str:
		.dc.b	'adpcm_block_data',0


		.end

* End of File --------------------------------- *
