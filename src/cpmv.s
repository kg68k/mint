# cpmv.s - &copy / &move
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
		.include	dos_mvdir.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	mkdir_a0
		.xref	copy_dir_name_a1_a2
		.xref	lndrv_init
		.xref	lndrv_pure_open
		.xref	lndrv_link_files
		.xref	print_write_protect_error
* menu.s
		.xref	input_path,path_menu
		.xref	menu_select,menu_select_curclr
		.xref	decode_reg_menu
		.xref	make_def_menu_list
* mint.s
		.xref	set_status
		.xref	fullpath_a1
		.xref	update_periodic_display
		.xref	set_curfile2
		.xref	dos_drvctrl_d1
		.xref	reset_current_dir
		.xref	print_mark_information
		.xref	print_file_list,directory_rewrite
		.xref	reload_drive_info,print_drive_info
		.xref	directory_reload,directory_reload_opp
		.xref	search_cursor_file,search_mark_file
		.xref	is_parent_directory_a4
		.xref	at_copy
		.xref	MINTSLASH
* mintarc.s
		.xref	get_mintarc_dir,get_mintarc_dir_opp
		.xref	ma_list_append,ma_list_write
		.xref	mintarc_set_auto_reload_flag
		.xref	mintarc_extract,mintarc_dispose
* outside.s
		.xref	dos_inpout
		.xref	break_check
		.xref	atoi_a0,strcmp_a1_a2
* pathhis.s
		.xref	path_history_menu_sub


* Constant ------------------------------------ *

COPY_MENU_NUM:	.equ	7

* モード
CPMV_COPY:	.equ	0
CPMV_MOVE:	.equ	-1

* ディスティネーション
DEST_HIS:	.equ	0
DEST_REG:	.equ	2
DEST_DIR:	.equ	4
DEST_OPP:	.equ	6
DEST_ARC:	.equ	-1

* 同名ファイル処理
SAME_MENU:	.equ	-1
SAME_OVER:	.equ	0
SAME_UP:	.equ	1
SAME_REN:	.equ	2
SAME_NOT:	.equ	3
SAME_AUTO:	.equ	4
SAME_COMP:	.equ	5
SAME_AI:	.equ	6


* Offset Table -------------------------------- *

* ワーク追加時の注意
*	バッファクリアはしてないので、フラグ類は
*	必ず cpmv_ent などで初期化すること.

		.offset	0
~dest:		.ds.b	128
~source:	.ds.b	128
~tmp_buf:	.ds.b	128
~files_buf:	.ds.b	FILES_SIZE
~filename:	.ds.b	FILENAME_MAX+1
~opp_cur_fn:	.ds.b	FILENAME_MAX+1
		.even
~s_top:		.ds.l	1
~s_ptr:		.ds.l	1
~d_top:		.ds.l	1
~d_ptr:		.ds.l	1
~m_tmp_tail:	.ds.l	1
~buf_adr:	.ds.l	1
~buf_size:	.ds.l	1
~title:		.ds.l	1
~curfile_ptr:	.ds.l	1
~1st_mark:	.ds.l	1
~dest_mode:	.ds.b	1
~cpmv_mode:	.ds.b	1
~same_mode:	.ds.b	1
~move_by_ren:	.ds.b	1
~dos_mvdir:	.ds.b	1
~ma_to_ma:	.ds.b	1
~reload_cur:	.ds.b	1
~reload_opp:	.ds.b	1
~junk_dir:	.ds.b	1

~mes_copyf:	.ds.b	MESLEN_MAX+1
~mes_compl:	.ds.b	MESLEN_MAX+1
~mes_dfull:	.ds.b	MESLEN_MAX+1
~mes_faild:	.ds.b	MESLEN_MAX+1
~mes_mkdir:	.ds.b	MESLEN_MAX+1
~mes_mvdir:	.ds.b	MESLEN_MAX+1
~mes_skipf:	.ds.b	MESLEN_MAX+1
		.even
sizeof_work:


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&copy-to-history-menu		*
*************************************************

＆copy_to_history_menu::
		moveq	#DEST_HIS,d1
		bra	copy_ent


*************************************************
*		&move-to-history-menu		*
*************************************************

＆move_to_history_menu::
		moveq	#DEST_HIS,d1
		bra	move_ent


*************************************************
*		&copy-to-registered-path-menu	*
*************************************************

＆copy_to_registered_path_menu::
		moveq	#DEST_REG,d1
		bra	copy_ent


*************************************************
*		&move-to-registered-path-menu	*
*************************************************

＆move_to_registered_path_menu::
		moveq	#DEST_REG,d1
		bra	move_ent


*************************************************
*		&direct-copy			*
*************************************************

＆direct_copy::
		moveq	#DEST_DIR,d1
		bra	copy_ent


*************************************************
*		&direct-move			*
*************************************************

＆direct_move::
		moveq	#DEST_DIR,d1
		bra	move_ent


*************************************************
*		&copy=&cp			*
*************************************************

＆copy::
		moveq	#DEST_OPP,d1
copy_ent:
		moveq	#CPMV_COPY,d2
		bra	cpmv_ent


*************************************************
*		&move				*
*************************************************

＆move::
		moveq	#DEST_OPP,d1
move_ent:
		moveq	#CPMV_MOVE,d2
		bra	cpmv_ent


* 統一ルーチン -------------------------------- *

cpmv_ent:
		lea	(-sizeof_work,sp),sp
		lea	(sp),a5

		move.b	d1,(~dest_mode,a5)
		move.b	d2,(~cpmv_mode,a5)
		clr.l	(~buf_adr,a5)
		clr.l	(~title,a5)
		clr.b	(~dest,a5)
		clr.b	(~opp_cur_fn,a5)
		clr.b	(~junk_dir,a5)		;-j
		st	(~same_mode,a5)		;SAME_MENU
		st	(~move_by_ren,a5)

* mintarc to mintarc のチェック
		tst.b	(PATH_MARC_FLAG,a6)
		sne	d0
		movea.l	(PATH_OPP,a6),a1
		and.b	(PATH_MARC_FLAG,a1),d0
		move.b	d0,(~ma_to_ma,a5)

* ソース側パス名の作成
		lea	(PATH_DIRNAME,a6),a1
		lea	(~source,a5),a2
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f

**		move.b	#CPMV_COPY,(~cpmv_mode,a5)
		clr.b	(~cpmv_mode,a5)		;mintarc からの &move は禁止する
		jsr	(get_mintarc_dir)
		movea.l	d0,a3
		STRCPY	a3,a2
		subq.l	#1,a2
		addq.l	#.sizeof.('a:/'),a1
@@:		STRCPY	a1,a2


* ソース側の検査
		tst.b	(PATH_NODISK,a6)
		bmi	cpmv_error		;メディア未挿入

		jsr	(search_cursor_file)
		move.l	a4,(~curfile_ptr,a5)

		movea.l	(PATH_BUF,a6),a4
		jsr	(search_mark_file)
		beq	@f
		suba.l	a4,a4
@@:		move.l	a4,(~1st_mark,a5)
		bne	@f			;マークあり
		tst	(＄nmcp)
		beq	cpmv_error		;マークなし

		movea.l	(~curfile_ptr,a5),a4
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	cpmv_error		;ファイルなし
		jsr	(is_parent_directory_a4)
		bne	cpmv_error		;".." はコピー出来ない
@@:
		tst.b	(~cpmv_mode,a5)
		beq	@f

		move	(PATH_DRIVENO,a6),d1	;&move ならソース側も
		jsr	(dos_drvctrl_d1)	;ライトプロテクトの検査が必要
		btst	#DRV_PROTECT,d0
		beq	@f
		jsr	(print_write_protect_error)
		bra	cpmv_error
@@:
		bsr	analyze_argument

* 書庫への書き込みチェック
		cmpi	#1,(＄arc！)		;%arc! 0 : 確認あり
		bne	cpmv_arc_ok		;      2 : 強制書き込み

		tst.b	(~cpmv_mode,a5)
		beq	@f
		tst.b	(PATH_MARC_FLAG,a6)
		bne	cpmv_error		;ソース側が書庫
@@:
		tst.b	(~dest_mode,a5)
		bpl	cpmv_arc_ok
		movea.l	(PATH_OPP,a6),a1
		tst.b	(PATH_MARC_FLAG,a1)
		bne	cpmv_error		;ディスティネーション側が書庫
cpmv_arc_ok:

* ディスティネーション側の検査
		lea	(~dest,a5),a0
		tst.b	(~cpmv_mode,a5)
		beq	@f
		tst.b	(~junk_dir,a5)
		bne	@f			;-j
		lea	(~source,a5),a1
		lea	(a0),a2
		jsr	(strcmp_a1_a2)
		beq	cpmv_error		;同一パスへの &move は禁止
@@:
		tst.b	(a0)
		beq	@f
		moveq	#$1f,d1
		and.b	(a0),d1
@@:		beq	cpmv_error
		jsr	(dos_drvctrl_d1)
		tst.l	d0
		bmi	@f
		moveq	#1<<DRV_NOTREADY+1<<DRV_INSERT+1<<DRV_ERRINS,d1
		and	d0,d1
		subq	#1<<DRV_INSERT,d1
@@:		beq	@f
		moveq	#MES_DRERR,d0		;not ready
		jsr	(PrintMsg)
		bsr	print_crlf
		bra	cpmv_error
@@:
		btst	#DRV_PROTECT,d0
		beq	@f
		jsr	(print_write_protect_error)
		bra	cpmv_error
@@:
* ディスティネーション側ディレクトリ作成
		bsr	set_reload_mode
		jsr	(ConsoleClear2)
		cmpi.b	#DEST_OPP,(~dest_mode,a5)
		bhi	9f
		bcc	@f
		bsr	print_dest_path		;複写先パス名を表示
@@:
		bsr	make_dest_path		;複写先ディレクトリを作成
		bmi	cpmv_error
9:
* パス名末尾を求めておく
		lea	(~source,a5),a0
		STREND	a0
		move.l	a0,(~s_top,a5)
		move.l	a0,(~s_ptr,a5)
		lea	(~dest,a5),a0
		STREND	a0
		move.l	a0,(~d_top,a5)
		move.l	a0,(~d_ptr,a5)

* ディスティネーション側 mintarc 前処理
		tst.b	(~dest_mode,a5)
		bpl	@f

		movea.l	(PATH_OPP,a6),a6
		moveq	#-1,d0			;reload を抑制する
		jsr	(mintarc_dispose)
		st	(~reload_opp,a5)

.if 0
		lea	(PATH_DIRNAME+.sizeof.('a:/'),a6),a0
		.xref	 extract_a0
		jsr	(extract_a0)		;カレントディレクトリを展開する
.else
		moveq	#%001,d0
		jsr	(mintarc_extract)
.endif
		movea.l	(PATH_OPP,a6),a6
		jsr	(reset_current_dir)

		lea	(~dest,a5),a0		;展開できたか調べる
		bsr	make_dest_path_files
		bmi	cpmv_error
@@:
* ソース側 mintarc 前処理
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		moveq	#%011,d0		;カーソルファイル展開
		tst.l	(~1st_mark,a5)
		beq	1f
		moveq	#%101,d0		;マークファイル展開
1:		jsr	(mintarc_extract)
@@:
		jsr	(set_curfile2)
		jsr	(lndrv_init)
		bsr	dos_mvdir_init
		bsr	get_mes

		move.l	(~1st_mark,a5),d0
		bne	cpmv_mark
*cpmv_curfile:
		move.l	(~curfile_ptr,a5),a4
		bsr	cpmv_a4
		bra	cpmv_loop_end
cpmv_mark:
		movea.l	d0,a4
@@:
		bsr	cpmv_a4
		bmi	cpmv_loop_end
		jsr	(search_mark_file)
		beq	@b
cpmv_loop_end:
		bsr	mfree_buf
		jsr	(SetColor3)

* コピーしたファイルを書庫に書き込む
		tst.b	(~dest_mode,a5)
		bpl	@f

		movea.l	(PATH_OPP,a6),a6
		jsr	(ma_list_write)
		movea.l	(PATH_OPP,a6),a6
@@:
		move.b	(~reload_opp,a5),d0
		beq	cpmv_reload_opp_end
		bmi	cpmv_reload_opp

		movea.l	(PATH_OPP,a6),a6
		bsr	reload_dinfo
		movea.l	(PATH_OPP,a6),a6
		bra	cpmv_reload_opp_end
cpmv_reload_opp:
		lea	(~opp_cur_fn,a5),a0
		tst.b	(a0)
		beq	@f
		movea.l	(PATH_OPP,a6),a1
		lea	(PATH_CURFILE,a1),a1
		STRCPY	a0,a1
@@:		jsr	(directory_reload_opp)
		jsr	(ReverseCursorBarOpp)
cpmv_reload_opp_end:

		move.b	(~reload_cur,a5),d0
		beq	cpmv_reload_cur_end
		bmi	cpmv_reload_cur
		lsr.b	#1,d0
		bcc	@f
		tst.b	(~cpmv_mode,a5)
		beq	cpmv_reload_cur_cp

		movea.l	(~curfile_ptr,a5),a1
		addq.l	#DIR_NAME,a1
		lea	(PATH_CURFILE,a6),a2
		jsr	(copy_dir_name_a1_a2)

		jsr	(directory_rewrite)
		bra	cpmv_reload_cur_end
cpmv_reload_cur_cp:
		jsr	(print_mark_information)
		move	(PATH_WIN_FILE,a6),d0	;マークが消えたので表示更新
		jsr	(WinClearAll)
		jsr	(print_file_list)
		jsr	(ReverseCursorBar)
@@:
		btst	#6,(~reload_cur,a5)
		beq	cpmv_reload_cur_end
@@:
		bsr	reload_dinfo
		bra	cpmv_reload_cur_end
cpmv_reload_cur:
		suba.l	a0,a0
		jsr	(directory_reload)
		bra	@b			;イマイチ
cpmv_reload_cur_end:

*cpmv_success:
		moveq	#1,d0
cpmv_end:
		lea	(sizeof_work,sp),sp
		jmp	(set_status)
**		rts
cpmv_error:
		moveq	#0,d0
		bra.s	cpmv_end


reload_dinfo:
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f
		jmp	(reload_drive_info)
**		rts
@@:		jmp	(print_drive_info)
**		rts


* コピー下請け(最上位版) ---------------------- *
* in	a4.l	ファイルエントリ
* out	a4.l	次のファイルエントリ
*	d0.l	-1:中断 0:失敗 1:成功
*	ccr	<tst.l d0> の結果
* break	d1-d7/a0-a3

cpmv_a4::
		lea	(~filename,a5),a0
		lea	(DIR_NAME,a4),a1
		lea	(a0),a2
		jsr	(copy_dir_name_a1_a2)

		move.l	a4,-(sp)
		bsr	cpmv_sub
		movea.l	(sp)+,a4
**		ble	cpmv_a4_error
		ble	@f			;コピーしなくてもカーソル位置を更新

		bclr	#MARK,(DIR_ATR,a4)
		beq	@f
		ori.b	#1,(~reload_cur,a5)	;マークを消去したら再表示する
@@:
		cmpi.b	#DEST_OPP,(~dest_mode,a5)
		bcs	@f

		movea.l	(~d_ptr,a5),a0		;反対側ウィンドウのカーソル位置を
		lea	(~opp_cur_fn,a5),a1	;更新する
		STRCPY	a0,a1
@@:
		tst.b	(~cpmv_mode,a5)
		bne	cpmv_a4_move
cpmv_a4_end:
		tst.l	d0
cpmv_a4_error:
		lea	(sizeof_DIR,a4),a4
		rts

* &move が成功したらバッファからエントリを削除する
* fileop.s の delete_sub_a4 と同じ
cpmv_a4_move:
		tst.l	d0
		ble	cpmv_a4_error

		ori.b	#1,(~reload_cur,a5)	;マーク無し &move 時も再描画が必要

		cmpa.l	(~curfile_ptr,a5),a4
		bne	cpmv_a4_skip_csr_down

		lea	(sizeof_DIR,a4),a0	;カーソル位置のファイルを移動したら
		cmpi.b	#-1,(DIR_ATR,a0)	;カーソルを一つ下に移動する
		bne	@f

		cmpa.l	(PATH_BUF,a6),a4
		beq	cpmv_a4_skip_csr_down

		lea	(-sizeof_DIR,a4),a0	;カーソルが最下段にあった場合は
@@:		move.l	a0,(~curfile_ptr,a5)	;一つ上に移動する
cpmv_a4_skip_csr_down:
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

		cmpa.l	(~curfile_ptr,a5),a4
		bcc	@f

		moveq	#sizeof_DIR,d0		;カーソルを一つ上に移動する
		sub.l	d0,(~curfile_ptr,a5)
@@:
		moveq	#1,d0
		rts


* コピー下請け(再帰版) ------------------------ *
* in	a0.l	ファイル名
* out	d0.l	-1:中断 0:失敗 1:成功
*	ccr	<tst.l d0> の結果
* break	d1-d7/a0-a4

cpmv_sub::
		lea	(-FILES_SIZE,sp),sp
		jsr	(break_check)
		bmi	cpmv_sub_end

		moveq	#-1,d5			;桁数
		moveq	#-1,d6			;ファイルハンドル read
		moveq	#-1,d7			;		  write

		lea	(a0),a1
		movea.l	(~s_ptr,a5),a2
		STRCPY	a0,a2
		movea.l	(~d_ptr,a5),a2
		STRCPY	a1,a2

		move	#$ff,-(sp)
		pea	(~source,a5)
		pea	(6,sp)
		jsr	(lndrv_link_files)	;DOS _FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bpl	@f
		bsr	print_cpmv_mes
		bra	cpmv_sub_error
@@:
		moveq	#0,d4
		move.b	(FILES_FileAtr,sp),d4
		btst	#DIRECTORY,d4
		bne	cpmv_sub_dir

* ファイル
		bsr	print_cpmv_mes
cpmv_sub_file_retry:
		move.b	(~cpmv_mode,a5),d0
		and.b	(~move_by_ren,a5),d0
		beq	cpmv_sub_file_copy

*cpmv_sub_file_move:
		pea	(~dest,a5)		;DOS _RENAME で移動できるか試す
		pea	(~source,a5)
		DOS	_RENAME
		addq.l	#8,sp
		tst.l	d0
		bpl	cpmv_sub_complete	;移動できた

		moveq	#-15,d1			;『ドライブ指定に誤りがある』
		cmp.l	d1,d0
		beq	cpmv_sub_file_copy2	;copy & delete で移動する

		moveq	#-19,d1			;『指定のファイルは書き込みできない』
		cmp.l	d1,d0
		beq	cpmv_sub_file_move2

		moveq	#-22,d1			;『ファイルがあるのでリネームできない』
		cmp.l	d1,d0
		bne	cpmv_sub_error

* 同名のファイルかディレクトリが既に存在する
		bsr	cpmv_menu
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	cpmv_sub_skip-@b
		.dc	cpmv_sub_file_retry-@b
		.dc	cpmv_sub_complete2-@b
		.dc	cpmv_sub_cancel-@b
		.dc	cpmv_sub_error-@b

cpmv_sub_file_move2:
		move	#1<<ARCHIVE,-(sp)	;移動可能な属性に変更する
		pea	(~source,a5)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		bmi	@f

		pea	(~dest,a5)
		pea	(~source,a5)
		DOS	_RENAME
		addq.l	#8,sp
		tst.l	d0
		bmi	@f

		move	d4,-(sp)		;元の属性に戻す
		pea	(~dest,a5)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		bpl	cpmv_sub_complete
@@:		bra	cpmv_sub_error

cpmv_sub_file_copy2:
		clr.b	(~move_by_ren,a5)	;以後は DOS _RENAME を試さない
cpmv_sub_file_copy:
		move	d4,-(sp)
		pea	(~dest,a5)
		DOS	_NEWFILE
		addq.l	#6,sp
		move.l	d0,d7
		bpl	cpmv_sub_file_dest_ok
		moveq	#-23,d0
		cmp.l	d0,d7
		beq	cpmv_sub_diskfull
		moveq	#-80,d0
		cmp.l	d0,d7
		bne	cpmv_sub_error

* 同名のファイルかディレクトリが既に存在する
		bsr	cpmv_menu
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	cpmv_sub_skip-@b
		.dc	cpmv_sub_file_retry-@b
		.dc	cpmv_sub_complete2-@b
		.dc	cpmv_sub_cancel-@b
		.dc	cpmv_sub_error-@b

cpmv_sub_file_dest_ok:
		lea	(~source,a5),a0
		bsr	pure_open
		move.l	d0,d6
		bmi	cpmv_sub_error

		move	d6,d0
		bsr	get_filesize
		bmi	cpmv_sub_error
		beq	cpmv_sub_file_comp

		move.l	d0,a2			;ファイルサイズ
		move.l	d0,d4			;残りバイト数

		bsr	malloc_buf
		move.l	d0,d3			;バッファサイズ
		lea	(a0),a3			;バッファアドレス
cpmv_sub_file_rw_loop:
		jsr	(update_periodic_display)
		jsr	(break_check)
		bmi	cpmv_sub_cancel

		cmp.l	d4,d3
		bls	@f
		move.l	d4,d3			;今回読み込みサイズ
@@:
		move.l	d3,-(sp)
		pea	(a3)
		move	d6,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		bne	cpmv_sub_error

		jsr	(break_check)
		bmi	cpmv_sub_cancel

		move.l	d3,-(sp)
		pea	(a3)
		move	d7,-(sp)
		DOS	_WRITE
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	cpmv_sub_error
		cmp.l	d0,d3
		bne	cpmv_sub_diskfull

		sub.l	d3,d4
		beq	cpmv_sub_file_comp
* 経過表示
		bsr	cpmv_sub_backspace2
		tst.l	d5
		bpl	cpmv_sub_file_2nd
* 初回のみ準備を行う
		moveq	#0,d5
		move.l	a2,d0
		move.l	#1024*1024-1,d2
		cmp.l	d2,d0
		bls	@f
		tst	(＄f_1k)
		beq	@f

		add.l	d2,d0
		moveq	#20,d2
		lsr.l	d2,d0			;÷(1024*1024)
		moveq	#'M',d5
@@:
		swap	d5
		lea	(~tmp_buf,a5),a1
		lea	(a1),a0
		FPACK	__LTOS
		sub.l	a1,a0
		move	a0,d5			;桁数
cpmv_sub_file_2nd:
		lea	(~tmp_buf,a5),a0
		pea	(a0)
		move	#'  ',(a0)+

		moveq	#0,d1
		move	d5,d1			;桁数
		move.l	a2,d0
		sub.l	d4,d0			;処理済みバイト数
		swap	d5
		moveq	#20,d2
		tst.b	d5
		beq	@f
		lsr.l	d2,d0			;÷(1024*1024)
@@:		FPACK	__IUSING
		move.l	a2,d0			;ファイルサイズ
		tst.b	d5
		beq	@f
		move.b	d5,(a0)+		;'M'
		addi.l	#1024*1024-1,d0
		lsr.l	d2,d0			;÷(1024*1024)
@@:		move.b	#'/',(a0)+

		FPACK	__LTOS
		tst.b	d5
		beq	@f
		move.b	d5,(a0)+		;'M'
		clr.b	(a0)
@@:		swap	d5

		DOS	_PRINT
		addq.l	#4,sp
		bra	cpmv_sub_file_rw_loop
cpmv_sub_file_comp:
		move	d6,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp

		move.l	(FILES_Time,sp),d0
		swap	d0
		move.l	d0,-(sp)		;Date|Time
		move	d7,-(sp)
		DOS	_FILEDATE
		DOS	_CLOSE
		addq.l	#6,sp

		bsr	cpmv_sub_backspace

		tst.b	(~cpmv_mode,a5)
		beq	@f
		tst.b	(~move_by_ren,a5)	;念の為チェック
		bne	@f
		lea	(~source,a5),a0
		bsr	del_a0
@@:
cpmv_sub_complete:
		bsr	cpmv_sub_append
@@:
		lea	(~mes_compl,a5),a0
		bsr	print_a0_crlf
		moveq	#1,d0
		bra	cpmv_sub_end
cpmv_sub_complete2:
		bsr	cpmv_sub_append2
		bra	@b

* 書庫に書き込むファイル名をリストに登録
cpmv_sub_append2:
		PUSH	d0/a0-a1
		moveq	#0,d0			;削除しない
		bra	@f
cpmv_sub_append:
		PUSH	d0/a0-a1
		moveq	#-1,d0
@@:
		tst.b	(~dest_mode,a5)
		bpl	@f
		movea.l	(~d_top,a5),a0
		cmpa.l	(~d_ptr,a5),a0
		bne	@f			;再帰中は登録しない

		movea.l	(~m_tmp_tail,a5),a0
		lea	(mfree_buf,pc),a1
		jsr	(ma_list_append)
@@:
		POP	d0/a0-a1
		rts


* ディレクトリ
cpmv_sub_dir:
		tst.b	(~junk_dir,a5)
		bne	cpmv_sub_dir_exist	;-j

		lea	(~dest,a5),a0
**!!		lea	(~d_ptr,a5),a0
		bsr	append_slash
		bsr	make_dest_path_files
		sf	-(a1)			;同名ディレクトリが既にあれば
		beq	cpmv_sub_dir_exist	;表示を省略して続行

		move.b	(~cpmv_mode,a5),d0
		and.b	(~move_by_ren,a5),d0
		beq	cpmv_sub_dir_make
		tst.b	(~dos_mvdir,a5)
		beq	cpmv_sub_dir_make

		move	#$ff,-(sp)
		pea	(~dest,a5)
		pea	(~files_buf,a5)
		jsr	(lndrv_link_files)	;DOS _FILES
		lea	(10,sp),sp

		move.b	(FILES_SchDrv,sp),d1
		cmp.b	(~files_buf+FILES_SchDrv,a5),d1
		bne	cpmv_sub_dir_make2	;違うドライブなら mkdir & delete

		move.l	d0,-(sp)
		bsr	print_mvdir_mes
		tst.l	(sp)+
		bmi	cpmv_sub_dir_move

* 同名のファイルが既に存在する
cpmv_sub_mvdir_retry:
		bsr	cpmv_menu
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	cpmv_sub_skip-@b
		.dc	cpmv_sub_mvdir_retry2-@b
		.dc	cpmv_sub_complete2-@b
		.dc	cpmv_sub_cancel-@b
		.dc	cpmv_sub_error-@b

cpmv_sub_mvdir_retry2:
		move	#$ff,-(sp)
		pea	(~dest,a5)
		pea	(~files_buf,a5)
		jsr	(lndrv_link_files)	;DOS _FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bpl	cpmv_sub_mvdir_retry
cpmv_sub_dir_move:
		pea	(~dest,a5)
		pea	(~source,a5)
		move	#_MVDIR_MOVE,-(sp)
		DOS	_MVDIR
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bpl	cpmv_sub_complete
		bra	cpmv_sub_error

cpmv_sub_dir_make2:
		clr.b	(~move_by_ren,a5)
cpmv_sub_dir_make:
		bsr	print_mkdir_mes
cpmv_sub_dir_retry:
		pea	(a0)
		DOS	_MKDIR
		move.l	d0,(sp)+
		beq	cpmv_sub_dir_new
		moveq	#-20,d1
		cmp.l	d1,d0
		bne	cpmv_sub_error

* 同名のファイルが既に存在する
		bsr	cpmv_menu
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	cpmv_sub_skip-@b
		.dc	cpmv_sub_dir_retry-@b
		.dc	cpmv_sub_complete2-@b
		.dc	cpmv_sub_cancel-@b
		.dc	cpmv_sub_error-@b

* ディレクトリのタイムスタンプ/属性変更
cpmv_sub_dir_new:
		move	#1<<ARCHIVE,-(sp)	;アーカイブ属性に変更
		pea	(a0)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		bmi	cpmv_sub_dir_err1

		move	#1,-(sp)		;書き込みオープン
		pea	(a0)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d1
		bmi	cpmv_sub_dir_err2

		move.l	(FILES_Time,sp),d0
		swap	d0
		move.l	d0,-(sp)		;Date|Time
		move	d1,-(sp)
		DOS	_FILEDATE
		DOS	_CLOSE
		addq.l	#6,sp
cpmv_sub_dir_err2:
		move	d4,-(sp)		;コピー元ディレクトリと同じ
		pea	(a0)			;属性に変更する
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		bmi	cpmv_sub_error
cpmv_sub_dir_err1:
		lea	(~mes_compl,a5),a0
		bsr	print_a0_crlf
		bsr	cpmv_sub_append
		bra	@f
cpmv_sub_dir_exist:
		bsr	cpmv_sub_append2
@@:
* 再帰処理
		move.b	(~move_by_ren,a5),-(sp)
		move.l	(~s_ptr,a5),-(sp)
		move.l	(~d_ptr,a5),-(sp)
		move	#1,-(sp)		;返値
LOCAL_SIZE:	.equ	(2+4+4+2)

		st	(~move_by_ren,a5)

		tst.b	(~junk_dir,a5)
		bne	@f			;-j
		lea	(~dest,a5),a0
**!!		lea	(~d_ptr,a5),a0
		bsr	append_slash
		move.l	a1,(~d_ptr,a5)
@@:
		lea	(~source,a5),a0
**!!		lea	(~s_ptr,a5),a0
		bsr	append_slash
		move.l	a1,(~s_ptr,a5)		;a1 はすぐ下で使うので破壊しないこと

.ifdef NO_LNDRV_BUG
		move	#$01_ff,-(sp)
.else
		lea	(files_wild,pc),a0
		STRCPY	a0,a1
		move	#$00_ff,-(sp)
.endif
		pea	(~source,a5)
		pea	(LOCAL_SIZE+6,sp)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	cpmv_sub_dir_empty
cpmv_sub_dir_loop:
		lea	(LOCAL_SIZE+FILES_FileName,sp),a0
		cmpi	#'.'<<8,(a0)
		beq	cpmv_sub_dir_next
		cmpi	#'..',(a0)
		bne	@f
		tst.b	(2,a0)
		beq	cpmv_sub_dir_next
@@:
		bsr	cpmv_sub		;ディレクトリ再帰
		bmi	cpmv_sub_dir_cancel
		and	d0,(sp)			;一度でもエラーなら 0 を返す
cpmv_sub_dir_next:
		pea	(LOCAL_SIZE,sp)
		DOS	_NFILES
		move.l	d0,(sp)+
		bpl	cpmv_sub_dir_loop
cpmv_sub_dir_empty:
		bsr	cpmv_sub_dir_clr
		move	(sp),d0
		and.b	(~cpmv_mode,a5),d0
		beq	@f

* ディレクトリ削除
		pea	(~source,a5)		;とりあえず試してみる
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	@f

		moveq	#-19,d1			;『指定のファイルは書き込みできない』
		cmp.l	d1,d0
		bne	cpmv_sub_dir_del_error

		move	#1<<DIRECTORY,-(sp)	;削除可能な属性に変更する
		pea	(~source,a5)
		DOS	_CHMOD
		addq.l	#6,sp
		move.l	d0,d1
		bmi	cpmv_sub_dir_del_error

		pea	(~source,a5)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	@f

		move	d1,-(sp)		;一応属性を戻しておく
		pea	(~source,a5)
		DOS	_CHMOD
		addq.l	#6,sp
cpmv_sub_dir_del_error:
		clr	(sp)			;削除失敗
@@:		bra	cpmv_sub_dir_end
cpmv_sub_dir_clr:
		movea.l	(~s_ptr,a5),a0		;パスデリミタを消す
		clr.b	-(a0)
		tst.b	(~junk_dir,a5)
		bne	@f			;-j
		movea.l	(~d_ptr,a5),a0
		clr.b	-(a0)
@@:		rts
cpmv_sub_dir_cancel:
		move	d0,(sp)
		bsr	cpmv_sub_dir_clr
cpmv_sub_dir_end:
		move	(sp)+,d0
		move.l	(sp)+,(~d_ptr,a5)
		move.l	(sp)+,(~s_ptr,a5)
		move.b	(sp)+,(~move_by_ren,a5)
		ext.l	d0
		bra	cpmv_sub_end

cpmv_sub_end:
		lea	(FILES_SIZE,sp),sp
		tst.l	d0
		rts


* エラー処理
cpmv_sub_cancel:
		bsr	cpmv_sub_backspace
**		jsr	(SetColor3)
		lea	(~mes_skipf,a5),a0
		moveq	#-1,d0			;中断
		bra	cpmv_sub_errjob
cpmv_sub_diskfull:
		bsr	cpmv_sub_backspace
		jsr	(SetColor2)
		lea	(~mes_dfull,a5),a0
		bra	@f
cpmv_sub_skip:
		bsr	cpmv_sub_backspace
**		jsr	(SetColor3)
		lea	(~mes_skipf,a5),a0
		bra	@f
cpmv_sub_error:
		bsr	cpmv_sub_backspace
		jsr	(SetColor2)
		lea	(~mes_faild,a5),a0
@@:
		moveq	#0,d0			;エラーだが続行
cpmv_sub_errjob:
		move.l	d0,-(sp)

		tst.l	d6
		bmi	@f
		move	d6,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
@@:
		tst.l	d7
		bmi	@f
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		move.l	a0,-(sp)
		lea	(~dest,a5),a0
		bsr	del_a0
		movea.l	(sp)+,a0
@@:
		bsr	print_a0_crlf

		move.l	(sp)+,d0
		bra	cpmv_sub_end


* パスデリミタを付加する ---------------------- *
* in	a0.l	パス名
* out	a1.l	パス名末尾

append_slash:
		lea	(a0),a1
		STREND	a1
		move.b	(MINTSLASH),(a1)+
		clr.b	(a1)
		rts


* ファイルをオープンする ---------------------- *
* in	a0.l	ファイル名
* out	d0.l	ファイルハンドル

pure_open:
		clr	-(sp)
		pea	(a0)
		jsr	(lndrv_pure_open)	;DOS _OPEN
		addq.l	#6,sp
		rts


* 経過表示を消去する -------------------------- *
* in	d5.l	フラグ/桁数
* break	d0/a0

cpmv_sub_backspace:
		tst.l	d5
		bmi	cpmv_sub_bs_end

		bsr	cpmv_sub_bs_sub2
		moveq	#SPACE,d0
		bsr	cpmv_sub_bs_sub
		bra	cpmv_sub_bs_sub2
cpmv_sub_bs_sub2:
		moveq	#BS,d0
cpmv_sub_bs_sub:
		lea	(~tmp_buf,a5),a0
		pea	(a0)
@@:
		move.b	d0,(a0)+
		tst.b	(a0)
		bne	@b
		DOS	_PRINT
		addq.l	#4,sp
		rts

cpmv_sub_backspace2:
		tst.l	d5
		bpl	cpmv_sub_bs_sub2
cpmv_sub_bs_end:
		rts


* 同名ファイル処理の選択 ---------------------- *
* out	d0.l	0:スキップ
*		2:実行
*		4:スキップ実行(mintarc to mintarc)
*		6:キャンセル
*		8:エラー
*	ccr	<tst.l d0> の結果

cpmv_menu:
		PUSH	d1-d7/a0-a4
		lea	(4*12+4,sp),a3		;ソース側 _FILES バッファ
		lea	(~files_buf,a5),a4	;ディスト側
		moveq	#0,d6			;フラグ類 | -sX
		moveq	#-1,d7			;ウィンドウ番号

		movea.l	(~d_ptr,a5),a0		;ディスト側ファイル名を
		lea	(~filename,a5),a1	;行入力用のバッファに転送しておく
		STRCPY	a0,a1

		move	#$ff,-(sp)
		pea	(~dest,a5)
		pea	(a4)
		jsr	(lndrv_link_files)	;DOS _FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bpl	@f
		moveq	#8,d0
		bra	cpmv_menu_end
@@:
		bsr	cpmv_menu_fat_chk	;同一ファイルか調べる
		tst.b	(~ma_to_ma,a5)
		beq	@f
		tst.l	d6
		bpl	@f
		moveq	#4,d0			;mintarc to mintarc で同一ファイル
		bra	cpmv_menu_end
@@:
		move.b	(~same_mode,a5),d6
		bmi	cpmv_menu_open

		btst	d6,#1<<SAME_REN+1<<SAME_COMP
		bne	cpmv_menu_open2		;ウィンドウ上で Rename/Compare 実行

* ウィンドウをオープンせずに実行
		move	d6,d1
		bsr	cpmv_menu_dir_chk
		bne	cpmv_menu_open
		tst.l	d6			;同一ファイルの場合
		bpl	@f
		btst	d1,#1<<SAME_OVER+1<<SAME_UP+1<<SAME_AI
		bne	cpmv_menu_skip		;Overwrite/Update/AI はスキップにする
@@:
		add	d1,d1			;各処理に分岐
		move	(@f,pc,d1.w),d1
		jmp	(@f,pc,d1.w)
@@:
		.dc	cpmv_menu_s_over-@b
		.dc	cpmv_menu_s_up-@b
		.dc	cpmv_menu_skip-@b
		.dc	cpmv_menu_s_not-@b
		.dc	cpmv_menu_s_auto-@b
		.dc	cpmv_menu_skip-@b
		.dc	cpmv_menu_s_ai-@b

* Update
cpmv_menu_s_up:
		bsr	cpmv_menu_ts_chk
		bls	cpmv_menu_skip		;ソースの方が古いか同じ
* Overwrite
cpmv_menu_s_over:
		lea	(~dest,a5),a0
		bsr	del_a0
		bmi	cpmv_menu_skip
		bra	cpmv_menu_retry

* AI Copy
cpmv_menu_s_ai:
		bsr	cpmv_menu_ai_chk
		subq.l	#SAME_NOT,d0
		bcs	cpmv_menu_s_over
		beq	cpmv_menu_s_not
* Automatic '_'
cpmv_menu_s_auto:
		bsr	cpmv_menu_aren
		bmi	cpmv_menu_skip
		bra	cpmv_menu_retry

cpmv_menu_open:
		st	d6
cpmv_menu_open2:
		lea	(at_copy),a1
		jsr	(decode_reg_menu)
		subq.l	#COPY_MENU_NUM,d0
		beq	@f

		lea	(copy_menu_default,pc),a1
		jsr	(make_def_menu_list)	;@copy がない時は標準メニュー
@@:
		move.l	a1,d5			;選択肢リストのアドレス

		lea	(subwin_menu,pc),a0
		move.l	(~title,a5),d0
		bne	@f
		GETMES	MES_SAMEF
@@:		move.l	d0,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		move.l	d0,d7

* メニューの選択肢を表示する
		movea.l	d5,a2			;選択肢リストのアドレス
		moveq	#COPY_MENU_NUM-1,d3
		moveq	#1,d2			;Y
cpmv_menu_print_loop:
		moveq	#1,d1			;X
		jsr	(WinSetCursor)
		moveq	#YELLOW,d1
		jsr	(WinSetColor)

		movea.l	(a2)+,a1		;選択肢
		cmpi.b	#'_',(a1)
		bne	@f
		move.b	#SPACE,(a1)		;'_' を ' ' に置き換える
@@:
**		moveq	#0,d1
		move.b	(a1)+,d1		;ショートカットキー
		jsr	(WinPutChar)

		moveq	#1+1+2,d1		;空白二個分
		jsr	(WinSetCursor)
		bsr	win_set_color3
		jsr	(WinPrint)

		addq	#1,d2			;Y++
		dbra	d3,cpmv_menu_print_loop

* インフォメーション枠を表示する
		moveq	#MES_FCMPA,d4
		moveq	#5-1,d3
		moveq	#9,d2			;Y
@@:
		moveq	#1,d1			;X
		jsr	(WinSetCursor)
		move	d4,d0
		jsr	(get_message)
		movea.l	d0,a1
		move	d7,d0
		jsr	(WinPrint)

		addq	#1,d2			;Y++
		addq	#1,d4			;message++
		dbra	d3,@b

* インフォメーションを表示する
		bsr	cpmv_menu_9
		bsr	cpmv_menu_10
		bsr	cpmv_menu_11

* Y=12 [ソース側ファイル名]
		movea.l	(~s_ptr,a5),a1
		moveq	#12,d2
		bsr	cpmv_menu_info2

* Y=13 [ディスティネーション側ファイル名]
		moveq	#YELLOW,d1
		jsr	(WinSetColor)
		movea.l	(~d_ptr,a5),a1
		moveq	#13,d2
		bsr	cpmv_menu_info2

* -sR -s_ ならメニュー選択を省略
		move.b	d6,d0
		bmi	cpmv_menu_loop

		subq.b	#SAME_REN,d0
		beq	cpmv_menu_ren
		bra	cpmv_menu_comp

* メニュー選択
cpmv_menu_loop:
		move	d7,d0
		move	(＄same),d1
		addq	#1,d1			;1～7
		moveq	#COPY_MENU_NUM,d2
		jsr	(menu_select)
		subq	#1,d1			;0～6

		PUSH	d0-d1
		IOCS	_B_SFTSNS		;先に SHIFT の状態を調べておく
		move.b	d0,d3
		move	d7,d0
		jsr	(WinGetCursor)
		tst	d2
		beq	@f
		jsr	(menu_select_curclr)	;カーソルを消去する
@@:		POP	d0-d1

		cmpi.b	#CR,d0
		beq	cpmv_menu_cr

* ショートカットキーから行番号を得る
		movea.l	d5,a2
		moveq	#0,d1
		bsr	cpmv_menu_upper
@@:
		move.l	(a2)+,a1		;選択肢
		cmp.b	(a1),d0
		beq	cpmv_menu_cr		;見つかった
		addq	#1,d1
		cmpi	#COPY_MENU_NUM,d1
		bcs	@b
		bra	cpmv_menu_cancel	;見つからなかった
cpmv_menu_upper:
		cmpi.b	#SPACE,d0
		beq	@f
		andi.b	#$df,d0			;大文字化
@@:		rts

* 行番号からショートカットキーを得る
cpmv_menu_cr:
		movea.l	d5,a2
		move	d1,d0
		lsl	#2,d0
		movea.l	(a2,d0.w),a1
		move.b	(a1),d0			;ショートカットキー
		bsr	cpmv_menu_upper

* 次回の初期カーソル位置を変更する
		cmpi.b	#SPACE,d0
		beq	@f		;Compare なら変更しない
		move	d1,(＄same)
@@:
* ショートカットキーからモード番号を得る
		lea	(same_char_list+SAME_AI+1,pc),a1
		moveq	#SAME_AI,d1
@@:
		cmp.b	-(a1),d0
		dbeq	d1,@b
		bne	cpmv_menu_cancel

* SHIFT が押されていれば -sX に設定する
		lsr.b	#1,d3
		bcc	@f
		move.b	d1,(~same_mode,a5)
@@:
* 実行可能な選択か調べる
		bsr	cpmv_menu_dir_chk
		bne	cpmv_menu_loop
		tst.l	d6			;同一ファイルの場合
		bpl	@f
		btst	d1,#1<<SAME_OVER+1<<SAME_UP+1<<SAME_AI
		bne	cpmv_menu_skip		;Overwrite/Update/AI はスキップにする
		cmpi	#SAME_COMP,d1
		beq	cpmv_menu_loop		;Compare は無視
@@:
		add	d1,d1			;各処理に分岐
		move	(@f,pc,d1.w),d1
		jmp	(@f,pc,d1.w)
@@:
		.dc	cpmv_menu_over-@b
		.dc	cpmv_menu_up-@b
		.dc	cpmv_menu_ren-@b
		.dc	cpmv_menu_not-@b
		.dc	cpmv_menu_auto-@b
		.dc	cpmv_menu_comp-@b
		.dc	cpmv_menu_ai-@b

* Update
cpmv_menu_up:
		bsr	cpmv_menu_ts_chk
		bls	cpmv_menu_skip		;ソースの方が古いか同じ
* Overwrite
cpmv_menu_over:
		lea	(~dest,a5),a0
		bsr	del_a0
		bmi	cpmv_menu_loop
		bra	cpmv_menu_retry

* AI Copy
cpmv_menu_ai:
		bsr	cpmv_menu_ai_chk
		subq.l	#SAME_NOT,d0
		bcs	cpmv_menu_over
		beq	cpmv_menu_not
* Automatic '_'
cpmv_menu_auto:
		bsr	cpmv_menu_aren
		bmi	cpmv_menu_loop
		bra	cpmv_menu_retry

* Rename
cpmv_menu_ren:
		move.l	d7,d0
		moveq	#19,d1
		moveq	#13,d2
		jsr	(WinSetCursor)
		moveq	#YELLOW,d1
		jsr	(WinSetColor)

		move.l	#FILENAME_MAX<<16+RL_F_DOT,d1
		lea	(~filename,a5),a1	;初期カーソル位置は拡張子の上
		jsr	(MintReadLine)
		move.l	d0,-(sp)
		bsr	win_set_color3
		tst.l	(sp)+
		bmi	cpmv_menu_loop

		lea	(~filename,a5),a0	;ディスト側ファイル名を更新
		movea.l	(~d_ptr,a5),a1
		STRCPY	a0,a1

* 変更したファイル名と同じものがないことを確認する
		move	#$ff,-(sp)
		pea	(~dest,a5)
		pea	(a4)
		jsr	(lndrv_link_files)	;DOS _FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	cpmv_menu_retry

		bsr	cpmv_menu_fat_chk	;同一ファイルか調べる
		bsr	cpmv_menu_9
		bsr	cpmv_menu_10
		bsr	cpmv_menu_11
		bra	cpmv_menu_loop

* Compare
cpmv_menu_comp:
		bset	#30,d6
		bne	cpmv_menu_loop		;比較済み
		bsr	cpmv_menu_fcmp
		bmi	cpmv_menu_loop

		moveq	#MES_FCMP9,d0
		btst	#29,d6
		beq	@f
		moveq	#MES_FCMP8,d0
@@:		bsr	cpmv_menu_9_
		bra	cpmv_menu_loop

* Not Copy
cpmv_menu_s_not:
cpmv_menu_not:
		bra	cpmv_menu_skip

cpmv_menu_skip:
		moveq	#0,d0
		bra	cpmv_menu_end
cpmv_menu_retry:
		moveq	#2,d0
		bra	cpmv_menu_end
cpmv_menu_cancel:
		moveq	#6,d0
cpmv_menu_end:
		exg	d0,d7
		tst.l	d0
		bmi	@f
		jsr	(WinClose)
@@:
		move.l	d7,d0
		POP	d1-d7/a0-a4
		rts


* 同一ファイルか調べる
* out	d6.l	bit31=1:同一
cpmv_menu_fat_chk:
		lea	(FILES_SchAtr,a3),a0
		lea	(FILES_SchAtr,a4),a1
		moveq	#0,d6
		cmpm.b	(a0)+,(a1)+		;SchAtr
**		bne	@f
		cmpm.b	(a0)+,(a1)+		;SchDrv
		bne	@f
		cmpm.l	(a0)+,(a1)+		;SchSec
		bne	@f
		cmpm.l	(a0)+,(a1)+		;SchRest|SchOffs
		bne	@f
		bset	#31,d6
@@:		rts

* タイムスタンプを比較する
* out	d0.l	d0.l < 0 : ソース側の方が古い
*		d0.l = 0 : 同じ日付
*		d0.l > 0 : ソース側の方が新しい
*	ccr	<sub.l d1,d0> の結果
* break	d1
cpmv_menu_ts_chk:
		move.l	(FILES_Time,a4),d1
		move.l	(FILES_Time,a3),d0
		swap	d1
		swap	d0
		sub.l	d1,d0
		rts

* 指定した同名ファイル処理モードが可能か調べる
* in	d1.w	処理モード(SAME_xxx)
* out	ccrZ	0:可能 1:不可能
* break	d0

cpmv_menu_dir_chk:
		move.b	(FILES_FileAtr,a3),d0	;どちらかがディレクトリなら
		or.b	(FILES_FileAtr,a4),d0	;SAME_OVER、SAME_UP、SAME_COMP は不可
		btst	#DIRECTORY,d0
		beq	@f
		btst	d1,#1<<SAME_OVER+1<<SAME_UP+1<<SAME_COMP
cpmv_menu_9_end:
@@:		rts


* Y=9 [比較] -> &fcmp6 &fcmp7 &fcmp8 &fcmp9 (空白)
cpmv_menu_9:
		moveq	#MES_FCMP6,d0
		tst.l	d6
		bmi	cpmv_menu_9_		;同一ファイル

		lea	(FILES_Time,a3),a0
		lea	(FILES_Time,a4),a1
		cmpm.l	(a0)+,(a1)+		;Time|Date
		bne.s	cpmv_menu_9_end
		cmpm.l	(a0)+,(a1)+		;FileSize
		bne.s	cpmv_menu_9_end

		moveq	#MES_FCMP7,d0		;サイズ/タイムスタンプ一致
cpmv_menu_9_:
		exg	d0,d7
		moveq	#BLUE,d1
		jsr	(WinSetColor)
		exg	d0,d7

		moveq	#9,d2
		bsr	cpmv_menu_info
win_set_color3:
		move	d7,d0
		moveq	#WHITE,d1
		jmp	(WinSetColor)
**		rts

* Y=10 [ファイルサイズ] -> &fcmp3 &fcmp5 &fcmp2
cpmv_menu_10:
		moveq	#10,d2
		lea	(cpmv_menu_10_tbl,pc),a1
		move.l	(FILES_FileSize,a3),d0
		sub.l	(FILES_FileSize,a4),d0
		bra	@f

* Y=11 [タイムスタンプ] -> &fcmp1 &fcmp4 &fcmp0
cpmv_menu_11:
		moveq	#11,d2
		lea	(cpmv_menu_11_tbl,pc),a1
		bsr	cpmv_menu_ts_chk
@@:
		bhi	1f
		beq	2f
		addq.l	#1,a1
2:		addq.l	#1,a1
1:
		move.b	(a1),d0
		bra	cpmv_menu_info
**		rts

cpmv_menu_info:
		jsr	(get_message)
		movea.l	d0,a1
cpmv_menu_info2:
		moveq	#19,d1
		move	d7,d0
		jsr	(WinSetCursor)
		jmp	(WinPrint)
**		rts


cpmv_menu_10_tbl:
		.dc.b	MES_FCMP3,MES_FCMP5,MES_FCMP2
cpmv_menu_11_tbl:
		.dc.b	MES_FCMP1,MES_FCMP4,MES_FCMP0
		.even


* Automatic '_' ファイル名変更 ---------------- *
* out	d0.l	0:正常終了 -2:エラー
*	ccr	<tst.l d0> の結果

cpmv_menu_aren:
		PUSH	d1-d7/a0-a4
		lea	(~dest,a5),a3
		lea	(~tmp_buf,a5),a4
		move.l	(~d_ptr,a5),d6
		move.l	d6,d7
		sub.l	a3,d7
		add.l	a4,d7			;~tmp_buf における ~d_ptr の位置

		movea.l	d6,a0
@@:		tst.b	(a0)+
		bne	@b
		move.l	a0,d0
		sub.l	d6,d0			;ファイル名の長さ+1

		moveq	#FILENAME_MAX,d4
		sub.l	d0,d4			;残りバイト数-1
		bcs	cpmv_menu_aren_error

		lea	(a3),a0
		lea	(a4),a1
		STRCPY	a0,a1

* '_' を挿入するアドレスを得る
		moveq	#'.',d1
		movea.l	d7,a2
		cmp.b	(a2)+,d1
		beq	@f			;先頭の '.' は無視
		subq.l	#1,a2
@@:
		move.b	(a2)+,d0
		beq	@f
		cmp.b	d1,d0
		beq	@f			;'.' 発見
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		addq.l	#1,a2
		bra	@b
@@:
		subq.l	#1,a2
		move.l	a2,d5
		sub.l	a4,d5
		add.l	a3,d5			;~dest における '.' の次の位置
cpmv_menu_aren_loop:
		move.b	#'_',(a2)+
		movea.l	d5,a0
		lea	(a2),a1
		STRCPY	a0,a1			;残りの部分を繋ぐ

		move	#$ff,-(sp)
		pea	(a4)
		pea	(~files_buf,a5)
		jsr	(lndrv_link_files)	;DOS _FILES
		lea	(10,sp),sp
		addq.l	#2,d0			;$fffffffe になるまで繰り返す
		dbeq	d4,cpmv_menu_aren_loop
		bne	cpmv_menu_aren_error

		movea.l	d7,a0			;~tmp_buf から ~dest に
		movea.l	d6,a1			;ファイル名を転送する
		STRCPY	a0,a1
		moveq	#0,d0
@@:
		POP	d1-d7/a0-a4
		rts
cpmv_menu_aren_error:
		moveq	#-2,d0
		bra	@b


* AI 判定 ------------------------------------- *
* out	d0.l	処理モード(SAME_OVER/NOT/AUTO)
*	ccr	<tst.l d0> の結果

cpmv_menu_ai_chk:

* 1) タイムスタンプが同じ		-> Not Copy
		bsr	cpmv_menu_ts_chk
		beq	cpmv_menu_ai_chk_not
		bls	@f

* 2) ソースの方が新しい && サイズが同じ	-> Overwrite
		move.l	(FILES_FileSize,a4),d0
		cmp.l	(FILES_FileSize,a3),d0
		beq	cpmv_menu_ai_chk_over
@@:
* 3) 内容が違う				-> Automatic '_'
		bset	#30,d6
		bne	@f			;比較済み
		bsr	cpmv_menu_fcmp
		btst	#30,d6
		beq	cpmv_menu_ai_chk_auto	;中断/エラーなら安全のため Automatic '_'
@@:
		btst	#29,d6
		bne	@f
cpmv_menu_ai_chk_auto:
		moveq	#SAME_AUTO,d0
		rts
@@:
* 4) 内容が同じ && ソースの方が新しい	-> Overwrite
		bsr	cpmv_menu_ts_chk
		bls	cpmv_menu_ai_chk_not
cpmv_menu_ai_chk_over:
		moveq	#SAME_OVER,d0
		rts

* 5) 内容が同じ && ソースの方が古い	-> Not Copy
cpmv_menu_ai_chk_not:
		moveq	#SAME_NOT,d0
		rts


* ファイル内容比較 ---------------------------- *
* out	d0.l	0:正常終了 -1:エラー
*	ccr	<tst.l d0> の結果
* 備考:
*	ファイル内容が一致した場合、d6.l の bit29 を %1 にする.

cpmv_menu_fcmp:
		PUSH	d1-d5/d7/a0-a4
		moveq	#-1,d5
		moveq	#-1,d7

		move.b	(FILES_FileAtr,a3),d0	;どちらかがディレクトリなら
		or.b	(FILES_FileAtr,a4),d0	;エラー
		btst	#DIRECTORY,d0
		bne	cpmv_menu_fcmp_error

		lea	(~dest,a5),a0
		bsr	pure_open
		move.l	d0,d5
		bmi	cpmv_menu_fcmp_error
		bsr	get_filesize
		bmi	cpmv_menu_fcmp_error
		move.l	d0,d3
		sne	d1

		lea	(~source,a5),a0
		bsr	pure_open
		move.l	d0,d7
		bmi	cpmv_menu_fcmp_error
		bsr	get_filesize
		bmi	cpmv_menu_fcmp_error
		sne	d2
		cmp.b	d1,d2			;片方だけが 0 バイトなら
		bne	cpmv_menu_fcmp_end	;不一致と見なす
		or.b	d1,d2
		beq	cpmv_menu_fcmp_eq	;両方とも 0 なら一致と見なす

		cmp.l	d0,d3
		bls	@f
		move.l	d0,d3			;残りバイト数
@@:
cpmv_menu_fcmp_loop:
		lea	(Buffer+8*1024),a0
		lea	(1024,a0),a1

		move.l	#1024,d2
		cmp.l	d3,d2
		bls	@f
		move.l	d3,d2			;今回読み込みサイズ
@@:
		move	d5,d0
		bsr	cpmv_menu_fcmp_sub
		exg	a0,a1
		move	d7,d0
		bsr	cpmv_menu_fcmp_sub

		move	d2,d0
		subq	#1,d0
@@:
		cmpm.b	(a0)+,(a1)+
		dbne	d0,@b
		bne	cpmv_menu_fcmp_end	;内容が不一致

		sub.l	d2,d3
		beq	cpmv_menu_fcmp_eq	;最後まで比較した

		move	#$ff,-(sp)
		DOS	_INPOUT
		move	d0,(sp)+
		beq	cpmv_menu_fcmp_loop
cpmv_menu_fcmp_error:
		bclr	#30,d6			;実行済みフラグをクリアする
		moveq	#-1,d4
		bra	@f
cpmv_menu_fcmp_eq:
		bset	#29,d6			;内容一致フラグを立てる
cpmv_menu_fcmp_end:
		moveq	#0,d4
@@:
		tst.l	d5
		bmi	@f
		move	d5,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
@@:
		tst.l	d7
		bmi	@f
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
@@:
		move.l	d4,d0
		POP	d1-d5/d7/a0-a4
		rts

cpmv_menu_fcmp_sub:
		move.l	d2,-(sp)
		pea	(a0)
		move	d0,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		rts


* メッセージ表示 ------------------------------ *

print_mvdir_mes:
		jsr	(SetColor2_emp)
		pea	(~mes_mvdir,a5)
		bra	@f
print_mkdir_mes:
		jsr	(SetColor2_emp)
		pea	(~mes_mkdir,a5)
		bra	@f
print_cpmv_mes:
		jsr	(SetColor3_emp)
		pea	(~mes_copyf,a5)
@@:		DOS	_PRINT
		jsr	(SetColor3)
		move.l	(~s_top,a5),-(sp)
		DOS	_PRINT
		addq.l	#8,sp
		rts

print_a0_crlf:
		pea	(a0)
		DOS	_PRINT
		addq.l	#4,sp
print_crlf:
		jmp	(PrintCrlf)
**		rts


* メッセージ収得(デコード) -------------------- *

get_mes:
		moveq	#MES_COPYF,d0
		tst.b	(~cpmv_mode,a5)
		beq	@f
		moveq	#MES_MOVEF,d0
@@:		lea	(~mes_copyf,a5),a1
		bsr	get_mes_sub

		moveq	#MES_COMPL,d0
		lea	(~mes_compl,a5),a1
		bsr	get_mes_sub

		moveq	#MES_DFULL,d0
		lea	(~mes_dfull,a5),a1
		bsr	get_mes_sub

		moveq	#MES_FAILD,d0
		lea	(~mes_faild,a5),a1
		bsr	get_mes_sub

		moveq	#MES_MKDIR,d0
		lea	(~mes_mkdir,a5),a1
		bsr	get_mes_sub

		moveq	#MES_MVDIR,d0
		lea	(~mes_mvdir,a5),a1
		bsr	get_mes_sub

		moveq	#MES_SKIPF,d0
		lea	(~mes_skipf,a5),a1
		bra	get_mes_sub
**		rts

get_mes_sub:
		jsr	(get_message)
		movea.l	d0,a0
		STRCPY	a0,a1
		rts


* 入出力バッファ管理 -------------------------- *

* バッファ確保
* out	d0.l	バッファサイズ
*	a0.l	バッファアドレス
malloc_buf:
		move.l	(~buf_adr,a5),d0
		bgt	malloc_buf_end
		bmi	malloc_buf_error

		pea	(-1)
		DOS	_MALLOC
		move.l	d0,(sp)
		andi	#$00ff,(sp)
		beq	@f
		andi.l	#$fffff000,(sp)		;十分大きければ 4KB 単位にする
@@:		DOS	_MALLOC
		move.l	(sp)+,(~buf_size,a5)
		move.l	d0,(~buf_adr,a5)
		bmi	malloc_buf_error
malloc_buf_end:
		movea.l	d0,a0
		move.l	(~buf_size,a5),d0
		rts
malloc_buf_error:
		lea	(~files_buf,a5),a0
		moveq	#FILES_SIZE,d0
		rts

* バッファ解放
mfree_buf:
		move.l	d0,-(sp)
		move.l	(~buf_adr,a5),-(sp)
		ble	@f
		clr.l	(~buf_adr,a5)
		DOS	_MFREE
@@:		addq.l	#4,sp
		move.l	(sp)+,d0
		rts


* ファイルサイズ収得 -------------------------- *
* in	d0.w	ファイルハンドル
* out	d0.l	ファイルサイズ(負数ならエラー)
*	ccr	<tst.l d0> の結果

get_filesize::
		subq.l	#4,sp
		move	#SEEK_END,-(sp)
		clr.l	-(sp)
		move	d0,-(sp)
		DOS	_SEEK
		move.l	d0,(8,sp)
		clr	(6,sp)			;SEEK_SET
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	@f
		move.l	(sp),d0
@@:		addq.l	#4,sp
		rts


* パス名表示 ---------------------------------- *

print_dest_path:
**		jsr	(SetColor3_emp)
		GETMES	MES_CPDES
		move.l	d0,-(sp)
		DOS	_PRINT
		pea	(~dest,a5)
		DOS	_PRINT
		addq.l	#8,sp
		bsr	print_crlf
		jmp	(SetColor3)
**		rts


* 複写先ディレクトリ作成 ---------------------- *
* out	d0.l	0:正常終了 -1:エラー
* break	d1-d2/a0-a1

make_dest_path:
		lea	(~dest,a5),a0
		bsr	make_dest_path_files
		beq	make_dest_path_end	;ディレクトリ有り

		GETMES	MES_NEWDI
		movea.l	d0,a1
		lea	(subwin_mkdir,pc),a0	;無ければ確認してから作成
**		move.l	(~title,a5),d0
**		bne	@f
		GETMES	MES_DIERR
@@:		move.l	d0,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)
		jsr	(WinPrint)
		move	d0,d1
		jsr	(dos_inpout)
		exg	d0,d1
		jsr	(WinClose)

		cmpi.b	#CR,d1
		beq	make_dest_path_make
		tst	(＄sp_y)
		beq	@f
		cmpi.b	#SPACE,d1
		beq	make_dest_path_make
@@:		moveq	#-1,d0
		andi.b	#$df,d1
		cmpi.b	#'Y',d1
		bne	make_dest_path_end
make_dest_path_make:
		lea	(~dest,a5),a0
		lea	(a0),a1
		STREND	a1
		move.b	-(a1),d1
		clr.b	(a1)
		jsr	(mkdir_a0)
		move.b	d1,(a1)
make_dest_path_end:
		tst.l	d0
		rts


* ディレクトリが存在するか調べる
* in	a0.l	ディレクトリ名
* out	d0.l	0:存在する -1:存在しない
*	ccr	<tst.l d0> の結果

make_dest_path_files:
		pea	(~files_buf,a5)
		move.l	(sp)+,d0
		bra	is_exist_dir
**		rts


* ディレクトリ存在検査 ------------------------ *
* in	d0.l	DOS _FILES バッファ
*	a0.l	ディレクトリ名
* out	d0.l	0:存在する -1:存在しない
*	ccr	<tst.l d0> の結果

is_exist_dir::
.ifdef NO_LNDRV_BUG
		move	#$01_ff,-(sp)
		pea	(a0)
.else
		move.l	a1,-(sp)
		move	#$00_ff,-(sp)
		pea	(a0)
		lea	(a0),a1
		STREND	a1
		lea	(files_wild,pc),a0
		STRCPY	a0,a1
		movea.l	(sp),a0
.endif
		move.l	d0,-(sp)		;バッファ
		DOS	_FILES
		addq.l	#10-4,sp
		clr.l	(sp)
		tst.l	d0
		bpl	@f			;ディレクトリ有り
		addq.l	#2,d0
		beq	@f			;$fffffffe でもディレクトリ有り
		subq.l	#1,(sp)
@@:		move.l	(sp)+,d0
.ifndef NO_LNDRV_BUG
		sf	(-(.sizeof.('*.*')+1),a1)
		movea.l	(sp)+,a1
.endif
		rts


* リロード処理を設定 -------------------------- *

* +$00 : 無処理
* +$01 : 再表示(カーソル側のみ、cpmv_a4 でセット)
* +$40 : ドライブ情報リロード
* +$80 : リロード(+$01 より優先)

set_reload_mode:
		lea	(~dest,a5),a2

		tst.b	(PATH_MARC_FLAG,a6)
		bne	set_reload_mode_cur0

		moveq	#$80+$40,d7
		lea	(PATH_DIRNAME,a6),a1
		jsr	(strcmp_a1_a2)
		beq	set_reload_mode_cur	;同一パス
		bsr	s_r_m_md_check
		bne	set_reload_mode_cur	;カレントにディレクトリ作成

		moveq	#$40,d7
		tst.b	(~cpmv_mode,a5)
		bne	set_reload_mode_cur	;&move
		bsr	s_r_m_drive_check
		beq	set_reload_mode_cur	;同一ドライブ
set_reload_mode_cur0:
		moveq	#0,d7
set_reload_mode_cur:
		move.b	d7,(~reload_cur,a5)

		movea.l	(PATH_OPP,a6),a6
		move.b	(PATH_NODISK,a6),d0
		or.b	(PATH_MARC_FLAG,a6),d0
		bne	set_reload_mode_opp0

		moveq	#$80+$40,d7
		cmpi.b	#DEST_OPP,(~dest_mode,a5)
		bcc	set_reload_mode_opp	;DEST_OPP/ARC
		lea	(PATH_DIRNAME,a6),a1
		jsr	(strcmp_a1_a2)
		beq	set_reload_mode_opp	;同一パス
		bsr	s_r_m_md_check
		bne	set_reload_mode_opp	;カレントにディレクトリ作成

		moveq	#$40,d7
		bsr	s_r_m_drive_check
		beq	set_reload_mode_opp	;同一ドライブ
set_reload_mode_opp0:
		moveq	#0,d7
set_reload_mode_opp:
		move.b	d7,(~reload_opp,a5)
		movea.l	(PATH_OPP,a6),a6

		lea	(~dest,a5),a0
		jmp	(mintarc_set_auto_reload_flag)
**		rts


* 同じドライブか調べる
s_r_m_drive_check:
		moveq	#$20,d0
		or.b	(a1),d0
		moveq	#$20,d1
		or.b	(a2),d1
		cmp.b	d0,d1
		rts

* 表示中のパスにディレクトリを作成するか調べる
* in	a1.l	パス名
* out	d0.l	0:No -1:Yes
*	ccr	<tst.l d0> の結果

s_r_m_md_check:
		PUSH	d1/a0-a2
		lea	(~dest,a5),a0
		lea	(~tmp_buf,a5),a2
		bra	1f
@@:
		tst.b	(-1,a1)
		beq	s_r_m_md_check_no	;カレント＝既存
1:		move.b	(a0)+,(a2)
		cmpm.b	(a1)+,(a2)+
		beq	@b
		tst.b	-(a1)
		bne	s_r_m_md_check_no	;別ディレクトリ
@@:
		move.b	(a0)+,d0
		move.b	d0,(a2)+
		cmpi.b	#'/',d0
		beq	@f
		cmpi.b	#'\',d0
		beq	@f
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		move.b	(a0)+,(a2)+
		bra	@b
@@:
		clr.b	(a2)
		lea	(~tmp_buf,a5),a0
		bsr	make_dest_path_files
@@:
		POP	d1/a0-a2
		rts
s_r_m_md_check_no:
		moveq	#0,d0
		bra.s	@b


* DOS _MVDIR チェック ------------------------- *
* break	d0

dos_mvdir_init:
		clr	-(sp)			;_MVDIR_GETID
		DOS	_MVDIR
		addq.l	#2,sp
		cmpi.l	#_MVDIR_ID,d0
		seq	(~dos_mvdir,a5)
		rts


* 引数解釈 ------------------------------------ *
* in	d7.l	引数の数
*	a0.l	引数列のアドレス
* 備考:
*	Buffer を破壊する.

analyze_argument:
		PUSH	d0-d7/a0-a4
		move.l	d7,d4			;path_menu/input_path 用に保存
		lea	(a0),a4

		move	(PATH_WINRL,a6),d5
		swap	d5
		move	#1,d5			;-o | -l<n>
		moveq	#0,d6			;<n>
		bra	ana_arg_next
ana_arg_loop:
		move.b	(a0)+,d0
		beq	ana_arg_next
		cmpi.b	#'-',d0
		beq	ana_arg_option

		subq.l	#1,a0
		cmpi.b	#DEST_REG,(~dest_mode,a5)
		bne	ana_arg_path
*ana_arg_n:
		jsr	(atoi_a0)		;<n> : メニュー番号
		bne	ana_arg_skip
		tst.b	(a0)+
		bne	ana_arg_skip

		subq.l	#1,d0			;0～15
		moveq	#REG_WIN_NUM-1,d1
		cmp.l	d1,d0
		bhi	ana_arg_next		;番号が大きすぎる

		move.l	d0,d6
		bra	ana_arg_next
ana_arg_option:
		move.b	(a0)+,d0
		beq	ana_arg_next
		cmpi.b	#'t',d0
		beq	ana_arg_opt_t
		cmpi.b	#'s',d0
		beq	ana_arg_opt_s
		cmpi.b	#'l',d0
		beq	ana_arg_opt_l
		cmpi.b	#'o',d0
		beq	ana_arg_opt_o
		cmpi.b	#'j',d0
		beq	ana_arg_opt_j
		cmpi.b	#'d',d0
		bne	ana_arg_skip
ana_arg_opt_d:
		tst.b	(a0)+			;-d(estination) <path> : パス名指定
		bne	ana_arg_opt_d
@@:
		subq.l	#1,d7
		bcs	ana_arg_no_more		;引数がない
		tst.b	(a0)+
		beq	@b
		subq.l	#1,a0
ana_arg_path:
		lea	(Buffer),a1		;<path> : パス名指定
		lea	(a1),a2
		STRCPY	a0,a2
		jsr	(fullpath_a1)
**		bmi	ana_arg_next
		bsr	ana_arg_append_slash

		lea	(~dest,a5),a2
		STRCPY	a1,a2
		move.b	#DEST_DIR,(~dest_mode,a5)
		bra	ana_arg_next
ana_arg_opt_j:
		st	(~junk_dir,a5)		;-j : ディレクトリ名削除
		bra	ana_arg_skip
ana_arg_opt_l:
		jsr	(atoi_a0)		;-l<n> : 初期カーソル行
		bne	ana_arg_skip
		tst.b	(a0)+
		bne	ana_arg_skip

		move	d0,d5
		bra	ana_arg_next
ana_arg_opt_o:
		eori.l	#(WIN_LEFT.xor.WIN_RIGHT)<<16,d5
		bra	ana_arg_skip		;-o : パスヒストリ反対側モード
ana_arg_opt_s:
		move.b	(a0),d0			;-sX : 同名コピーモード
		cmpi.b	#'_',d0
		bcs	@f
		beq	1f
		addi.b	#('A'-'a')-(' '-'_'),d0	;a-z -> A-Z
1:		addi.b	#' '-'_',d0		;_ -> SPACE
@@:
		lea	(same_char_list+SAME_AI+1,pc),a1
		moveq	#SAME_AI,d1
@@:
		cmp.b	-(a1),d0
		dbeq	d1,@b
		move.b	d1,(~same_mode,a5)
		bra	ana_arg_skip
ana_arg_opt_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	ana_arg_no_more		;引数がない
@@:
		subq.l	#1,a0
		move.l	a0,(~title,a5)
ana_arg_skip:
		tst.b	(a0)+
		bne	ana_arg_skip
ana_arg_next:
		subq.l	#1,d7
		bcc	ana_arg_loop
ana_arg_no_more:
		lea	(~dest,a5),a2
		tst.b	(a2)
		bne	ana_arg_end		;パス指定済み

		moveq	#MES_ICOPY,d1
		tst.b	(~cpmv_mode,a5)
		beq	@f
		moveq	#MES_IMOVE,d1
@@:
		moveq	#0,d0
		move.b	(~dest_mode,a5),d0
		move	(@f,pc,d0.w),d0
		jmp	(@f,pc,d0.w)
@@:
		.dc	ana_arg_his-@b
		.dc	ana_arg_reg-@b
		.dc	ana_arg_dir-@b
		.dc	ana_arg_opp-@b
ana_arg_his:
		move.l	d5,d0			;-o | -l<n>
		movea.l	(~title,a5),a0		;-t"title"
		jsr	(path_history_menu_sub)
		tst.l	d0
		bmi	ana_arg_end

		STRCPY	a0,a2
		bra	ana_arg_end
ana_arg_reg:
		move	#MES2_CPMV1,d0
		lea	(path_menu),a1
		bra	ana_arg_menu
ana_arg_dir:
		move	d1,d0
		lea	(input_path),a1
ana_arg_menu:
		move.l	d4,d7
		lea	(a4),a0
		jsr	(a1)
		beq	ana_arg_end

		movea.l	d0,a0
		lea	(Buffer),a1
		lea	(a1),a3
		STRCPY	a0,a3
		jsr	(fullpath_a1)
**		bmi	ana_arg_end
		bsr	ana_arg_append_slash

		STRCPY	a1,a2
		bra	ana_arg_end
ana_arg_opp:
		movea.l	(PATH_OPP,a6),a1
		tst.b	(PATH_NODISK,a1)
		bmi	ana_arg_end

		tst.b	(PATH_MARC_FLAG,a1)
		addq.l	#PATH_DIRNAME,a1
		bne	@f
		STRCPY	a1,a2
		bra	ana_arg_end
@@:
**		move.b	#DEST_ARC,(~dest_mode,a5)
		st	(~dest_mode,a5)		;書庫にコピー

		jsr	(get_mintarc_dir_opp)
		movea.l	d0,a0
		STRCPY	a0,a2
		subq.l	#1,a2
		move.l	a2,(~m_tmp_tail,a5)
		addq.l	#.sizeof.('a:/'),a1
		STRCPY	a1,a2
		lea	(~dest,a5),a1
		jsr	(fullpath_a1)
		bpl	ana_arg_end
		clr.b	(a1)
ana_arg_end:
		POP	d0-d7/a0-a4
		rts


* パス名指定エラー時の小細工
ana_arg_append_slash:
		PUSH	d0-d1/a0-a1
		bpl	9f
		clr.b	(128-8,a1)
		lea	(a1),a0
		sf	d1
@@:
		move.b	(a1)+,d0
		beq	8f
		cmpi.b	#'/',d0
		beq	1f
		cmpi.b	#'\',d0
1:		seq	d1
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b
		tst.b	(a1)+
		bne	@b
		clr.b	(-2,a1)
8:
		tst.b	d1
		bne	9f
		bsr	append_slash
9:
		POP	d0-d1/a0-a1
		rts


* ファイル強制削除 ---------------------------- *
* ディレクトリが指定された場合は再帰的に削除する.
* in	a0.l	ファイル名
* out	d0.l	0:正常終了 -1:エラー
* 備考:
*	a0.l の直後を破壊する.
*	処理内容は fileop.s の rm_a0 とほぼ同じ.
*	(表示/確認/中断処理が省略されている)

del_a0::
		PUSH	d6/a0-a2/a5
		lea	(a0),a1
		tst.b	(a1)+
		beq	1f
		cmpi.b	#':',(a1)+
		bne	@f
		tst.b	(a1)
1:		beq	del_a0_error		;"d:" は削除不可能
@@:
		pea	(a0)
		DOS	_DELETE
		move.l	d0,(sp)+
		bpl	del_a0_end		;普通のファイル

		bsr	del_a0_chmod_get
		bmi	del_a0_error
		btst	#DIRECTORY,d0
		beq	del_a0_file

		pea	(a0)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	del_a0_end		;空ディレクトリ

		lea	(-FILES_SIZE,sp),sp
		lea	(a0),a1
@@:		tst.b	(a1)+
		bne	@b
		move.b	#'\',(-1,a1)
		clr.b	(a1)
		lea	(a1),a5

		moveq	#0,d6
.ifdef NO_LNDRV_BUG
		move	#$01_ff,-(sp)
.else
		lea	(files_wild,pc),a2
		STRCPY	a2,a1
		move	#$00_ff,-(sp)
.endif
		pea	(a0)
		pea	(6,sp)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	del_a0_files_end
del_a0_files_loop:
		lea	(FILES_FileName,sp),a2
		cmpi	#'.'<<8,(a2)
		beq	del_a0_files_next
		cmpi	#'..',(a2)
		bne	@f
		tst.b	(2,a2)
		beq	del_a0_files_next
@@:
		lea	(a5),a1
		STRCPY	a2,a1
		bsr	del_a0
		or.l	d0,d6
del_a0_files_next:
		pea	(sp)
		DOS	_NFILES
		move.l	d0,(sp)+
		bpl	del_a0_files_loop
del_a0_files_end:
		lea	(FILES_SIZE,sp),sp
		clr.b	-(a5)
		tst.l	d6			;下層エントリに削除失敗したものがあれば
		bmi	del_a0_error		;注目ディレクトリは削除できない

		pea	(a0)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	del_a0_end

		moveq	#1<<DIRECTORY,d0
		bsr	del_a0_chmod
		bmi	del_a0_error

		pea	(a0)
		DOS	_RMDIR
		move.l	d0,(sp)+
		bpl	del_a0_end
		bra	del_a0_error
del_a0_file:
		moveq	#1<<ARCHIVE,d0
		bsr	del_a0_chmod
		bmi	del_a0_error

		pea	(a0)
		DOS	_DELETE
		move.l	d0,(sp)+
		bpl	del_a0_end
del_a0_error:
		moveq	#-1,d0
		bra	@f
del_a0_end:
		moveq	#0,d0
@@:		POP	d6/a0-a2/a5
		rts

del_a0_chmod_get:
		moveq	#-1,d0
del_a0_chmod:
		move	d0,-(sp)
		move.l	a0,-(sp)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0
		rts


* Data Section -------------------------------- *

**		.data
		.even

subwin_mkdir:
		SUBWIN	16,9,62,1,NULL,NULL
subwin_menu:
		SUBWIN	26,5,44,13,NULL,NULL
txfill_buf:
		.dc	$8003,(26+19)*8,(5+13)*16,FILENAME_MAX*8,16,-1

same_char_list:
		.dc.b	'OURNA C'
copy_menu_default:
		.dc.b	'O',' Force  over write + shift continuous',0
		.dc.b	'U',' Update                    〃',0
		.dc.b	'R',' Rename copy               〃',0
		.dc.b	'N',' Not    copy               〃',0
		.dc.b	'A',' Automatic[_] copy         〃',0
		.dc.b	' ',' 1KB  file compare         〃',0
		.dc.b	'C',' AI copy version 2         〃',0
		.dc.b	0

.ifndef NO_LNDRV_BUG
files_wild:
		.dc.b	'*.*',0
.endif


		.end

* End of File --------------------------------- *
