# mint.s - Madoka INTerpreter  main source
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
		.include	version.mac

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac
		.include	twoncall.mac


* Global Symbol ------------------------------- *

* cmdhis.s
		.xref	alloc_cmd_his_buf
		.xref	get_cmd_his_size
		.xref	load_cmd_his
* cpmv.s
		.xref	＆copy,＆direct_copy,＆copy_to_registered_path_menu,＆copy_to_history_menu
		.xref	＆move,＆direct_move,＆move_to_registered_path_menu,＆move_to_history_menu
* datatitle.s
		.xref	＆data_title
		.xref	＆pdx_filename
* filecmp.s
		.xref	＆file_compare
* fileop.s
		.xref	＆chmod,＆delete,＆file_check,＆maketmp
		.xref	＆make_dir_and_move,＆md,＆ren,＆rm,＆touch
		.xref	to_mintslash
		.xref	copy_dir_name_a1_a2
		.xref	print_write_protect_error
* gvon.s
		.xref	＆gvon,＆gvram_off,＆clear_gvram,＆iocs_home,＆get_color_mode
		.xref	＆mono,＆16color_palet_set,＆64kcolor_palet_set
		.xref	＆half,＆max,＆mion,＆mioff
		.xref	＆brightness_decrement,＆brightness_increment
		.xref	＆turn_gvram_upside_down,＆turn_gvram_left_and_right
		.xref	＆rotate_gvram_ccw,＆rotate_gvram_cw
		.xref	gm_check_square,check_gusemd,_vdisp_wait
		.xref	analyze_@gvon_section,center_256_graphic
		.xref	mion_flag
* help.s
		.xref	＆ext_help,＆describe_key,describe_key_opt
* isearch.s
		.xref	＆i_search
* look.s
		.xref	＆look_file,iocs_key_flush
		.xref	analyze_@look_section,lookfile_restore_interrupt
		.xref	lookfile_static_flags
* madoka3.s
		.xref	＠exitcode,＠buildin,＠status
		.xref	＆madoka,＆debug,＆end,＆eval,＆prefix,＆set_opt
		.xref	＆foreach,＆break,＆continue
		.xref	＆if,＆unless,＆else_if,＆else
		.xref	＆command_history,＆command_history_menu
		.xref	search_command,restore_dos_exec_patch
		.xref	if_ftst_is_binary
		.xref	init_text_palette
		.xref	init_schr_tbl,init_sc_flag,debug_flag
		.xref	execute_quick_no,execute_quick,free_token_buf
		.xref	print_runtime,print_exitcode
* menu.s
		.xref	＆chdir_to_registered_path_menu
		.xref	＆exec_registered_command_menu
		.xref	＆menu,menu_sub,menu_sub_ex,menu_select
		.xref	decode_reg_menu,make_def_menu_list
* message.s
		.xref	init_mes_ptr_table,pickup_message_change
		.xref	print_message_list,get_message_no
		.xref	mes_ptr_table
* mintarc.s
		.xref	＆is_mintarc,＆uncompress
		.xref	＆lzh_selector,＆zip_selector,＆tar_selector
		.xref	get_mintarc_filename,get_mintarc_filename_opp
		.xref	get_mintarc_file_num
		.xref	get_mintarc_dir,get_mintarc_dir_opp
		.xref	marc_files,marc_nfiles,marc_files2
		.xref	quit_mintarc,quit_mintarc_all
		.xref	mintarc_extract,mintarc_dispose_ache
		.xref	mintarc_chdir_to_arc_dir
		.xref	restore_minttmp_curdir
* mrl.s
		.xref	＆input
		.xref	at_complete_list
* music.s
		.xref	＆cont_music,＆fade_music,＆pause_music,＆play_music,＆stop_music
		.xref	＆get_music_status,print_music_title
		.xref	human_psp,music_data_title_flag
* outside.s
		.xref	＆bell,＆v_bell,＆echo,＆print,＆one_ring
		.xref	＆cache_on ,＆data_cache_on ,＆instruction_cache_on
		.xref	＆cache_off,＆data_cache_off,＆instruction_cache_off
		.xref	＆equ,strcmp_a1_a2,stricmp_a1_a2
		.xref	＆execute_binary,＆getsec,getsec_flag,＆prchk
		.xref	＆iocs,＆rnd,＆set_crtc,＆trap
		.xref	＆iso9660,＆msdos
		.xref	＆key_wait,＆wait
		.xref	＆older_file,＆newer_file,＆online_switch
		.xref	＆palet0_set,＆palet0_system,＆palet0_up,＆palet0_down
		.xref	＆pushd,＆popd,＆clear_path_stack
		.xref	＆scsi_check,＆scsi_menu,＆sync
		.xref	＆set,＆setenv,＆unsetenv,＆unset,＆cal
		.xref	search_system_value
		.xref	set_user_value_a1_a2,set_user_value_arg_a2
		.xref	set_user_value_match_a2,unset_user_value_match
		.xref	＆sram_contrast,＆stop_condrv,＆stop_vdisp
		.xref	＆toggle_palet_illumination,palet_illumination
		.xref	＆twentyone_ignore_case
		.xref	＆go_screen_saver,＆toggle_screen_saver
		.xref	init_ss_timer,auto_screen_saver
		.xref	init_timer,check_timer
		.xref	atoi_a0,atoi_a1
		.xref	resume_stops
		.xref	break_check0
* pathselect.s
		.xref	＆path_history_menu,add_path_history
		.xref	path_history_buffer
* patternmatch.s
		.xref	＆exist,＆match,＆file_match
		.xref	init_i_c_option,take_i_c_option
		.xref	_fre_compile,_fre_match,_ignore_case
* phantomx.s
		.xref	PhantomX_Exists,PhantomX_GetTemperature
* rename.s
		.xref	＆rename_menu
		.xref	＆rename_marked_files_or_directory
* titleload.s
		.xref	＆title_load,＆pop_text
		.xref	title_load_minttitle
* version.s
		.xref	print_version,print_usage
		.xref	dump_function_table,type_function_table
		.xref	print_system_value_table,type_system_value_table


* Debug Macro --------------------------------- *

CHDIR_PRINT:	.macro	char
.ifdef __CHDIR_DEBUG__
		move.l	d0,-(sp)
		move	#char,-(sp)
		DOS	_PUTCHAR
		move	#TAB,(sp)
		DOS	_PUTCHAR
		move.l	(6,sp),-(sp)
		DOS	_PRINT
		addq.l	#6,sp
		jbsr	PrintCrlf
		move.l	(sp)+,d0
.endif
		.endm


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

* mint_start が実行ファイルの先頭になるように
* リンクする事！(PSPの参照に使用しているので)
mint_start::
		bra.s	mint_start2
		.dc.b	'#HUPAIR',0


* プラグイン情報
* 
plugin_rel:	.dc	$01_01			;リリース番号(2バイト)
plugin_header:	.dc.b	'MINT-V3 PLUG-IN',0	;識別子(16バイト)
plugin_val:	.dc.l	search_system_value	;システム変数取得
plugin_mesno:	.dc.l	get_message_no		;メッセージ番号取得
plugin_mes:	.dc.l	get_message		;メッセージ取得

* リスト開始
plugin_list:

*plugin_braw:	bra.w	mint_start2		;bra.s mint_start2 が
*		.dc.l	0,0			;届かなくなった時のための細工

plugin_winf:	.dc.l	'WINF',0,0		;ファイル情報行作成ルーチン
plugin_exit:	.dc.l	'EXIT',0,0		;終了時専用ルーチン

* リスト終了
plugin_end:
		.dc.l	0
		.even

mint_start2:
		lea	(stack_bottom),sp
		lea	(16,a0),a0
		suba.l	a0,a1
		move.l	a1,-(sp)
		move.l	a0,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp

		pea	(1,a2)
		bsr	GetArgCharInit
		addq.l	#4,sp

		TO_SUPER			;FLOATn.X 組み込みチェック
		move.l	#'FEfn',d1
		movea.l	(FLINE_VEC*4),a0
		cmp.l	-(a0),d1
		beq	@f
		movea.l	(PRIV_VEC*4),a0
		cmp.l	-(a0),d1
		beq	@f
		moveq	#0,d1			;組み込まれていない
@@:		TO_USER
		tst.l	d1
		beq	float_error

		lea	(path_buffer),a6
		lea	(sizeof_PATHBUF,a6),a5
		move.l	a5,(PATH_OPP,a6)	;相手側の管理バッファアドレス
		move.l	a6,(PATH_OPP,a5)	;
**		clr.b	(PATH_DIRNAME,a6)
**		clr.b	(PATH_DIRNAME,a5)
**		move	#WIN_LEFT,(PATH_WINRL,a6)
		move	#WIN_RIGHT,(PATH_WINRL,a5)
		lea	(mask_regexp_pattern-path_buffer,a6),a0
		move.l	a0,(PATH_MASK,a6)
		lea	(MASK_REGEXP_SIZE,a0),a0
		move.l	a0,(PATH_MASK,a5)

* このあたりは順番が大事なので注意.
		jbsr	getenv_slash		;定義ファイルの正規化用
		bsr	option_check
		bsr	get_malloc_mode
		bsr	make_own_env
		bsr	breakck_save_kill

		move.b	(skip_mintrc_flag,pc),-(sp)
		bne	@f
		jsr	(title_load_minttitle)
@@:
		bsr	misc_init
		jbsr	＆drive_check
		jbsr	get_fnckey_mode
		jsr	(WinFontInit)
		jsr	(gm_check_square)
		jsr	(＆16color_palet_set)
		jsr	(init_mes_ptr_table)
		jbsr	init_kq_ptr_buffer

		tst.b	(sp)+			;skip_mintrc_flag
		bne	skip_read_mintrc

		jbsr	read_mintrc
		jbsr	load_path_history
		jbsr	analyze_mintrc_sysvalue
		jbsr	analyze_mintrc_message
		jbsr	correct_system_value2
		jbsr	analyze_mintrc
skip_read_mintrc:
		jbsr	set_scr_param
		jbsr	hook_keyinp_ex_vector
		jbsr	CursorBlinkOff		;終了処理設定後に行う
		jbsr	save_system_value
		jbsr	mint_getenv		;＄unix を参照しているので
						;.mint 読み込み後に呼び出すこと
		jbsr	malloc_dirs_buf
		jsr	(init_schr_tbl)
		jsr	(alloc_cmd_his_buf)
		jbsr	load_command_history
		jbsr	SaveFnckey
		jbsr	ChangeFnckey

		bsr	save_boot_directory	;起動時のカレントディレクトリ保存

		jsr	(＆pop_text)		;$MINTTITLE の表示を消す
		jbsr	window_create		;各種ウィンドウ作成
		bsr	init_path_struct
		jsr	(print_music_title)

		move	#KQ_A_EXEC<<8,d0		;>A_EXEC の実行
		jsr	(execute_quick_no)

* mint -e ... のコマンドを実行する
		move.l	(execute_ptr,pc),d0
		beq	@f
		movea.l	d0,a0
		movea.l	d0,a1
		moveq	#%0010_0000,d0
		jsr	(execute_quick)
		bra	quit_normal
@@:
		jsr	(init_ss_timer)
		bsr	main_loop
prepare_exit_mint:
		lea	(path_buffer),a6	;一応
		jsr	(lookfile_restore_interrupt)
		jsr	(restore_dos_exec_patch)

		bsr	release_plug_in

		lea	(boot_directory),a1	;起動時のカレントディレクトリに戻す
		jbsr	dos_chgdrv_a1
		pea	(a1)
		CHDIR_PRINT	'a'
		DOS	_CHDIR
		addq.l	#4,sp

		bsr	setenv_mintpath12
		bsr	RestoreFnckey
		bsr	restore_fnckey_mode
		bsr	set_scroll_full_console
		jsr	(init_text_palette)
		jbsr	fep_enable
		bsr	restore_keyinp_ex_vector
		bsr	breakck_restore

		tst	(＄exit)
		bne	@f			;画面初期化なし

		jbsr	ConsoleClear
		moveq	#32,d1
		IOCS	_B_DEL
		moveq	#0,d1
		moveq	#0,d2
		IOCS	_B_LOCATE
		moveq	#32,d1
		IOCS	_B_DEL
		bra	1f
@@:
		moveq	#31,d1
		IOCS	_B_DOWN
1:
		jbsr	CursorBlinkOn

		DOS	_EXIT


* プラグイン終了処理 -------------------------- *

release_plug_in:
		lea	(plugin_list,opc),a5
release_plug_in_loop:
		move.l	(PLUG_IN_FREE,a5),d0
		beq	release_plug_in_next	;終了処理未登録

		move.l	d0,a0
		jsr	(a0)
		move.l	d0,-(sp)
		ble	@f
		DOS	_MFREE
@@:		addq.l	#4,sp
		bra	release_plug_in_loop	;多重組み込みの解除に対応
release_plug_in_next:
		lea	(PLUG_IN_SIZE,a5),a5
		tst.l	(PLUG_IN_TYPE,a5)
		bne	release_plug_in_loop
release_plug_in_end:
		rts


* ファンクションキー定義 ---------------------- *

* キー定義を保存する
SaveFnckey::
		moveq	#0,d0
		bra	@f
* キー定義を元に戻す
RestoreFnckey::
		move	#$0100,d0
@@:
		pea	(fnckey_save_buf)
		move	d0,-(sp)
		DOS	_FNCKEY
		addq.l	#6,sp
		rts

* &look-file 用のキー定義に変更する
ChangeFnckey_lookfile::
		PUSH	d0-d1/a0-a1
		moveq	#MES_VFNC0,d0
		moveq	#MES_VFNC1,d1
		bra	@f
* mint 用のキー定義に変更する
ChangeFnckey::
		PUSH	d0-d1/a0-a1
		moveq	#MES_FUNC0,d0
		moveq	#MES_FUNC1,d1
@@:
		lea	(-712,sp),sp
		lea	(sp),a1
		bsr	extract_fnckey_define	;F01～F10
		move	d1,d0
		bsr	extract_fnckey_define	;F11～F20

		lea	(fnckey_table,pc),a0	;その他の機能キー
		moveq	#12-1,d0
@@:		move.b	(a0)+,(a1)+
		clr.b	(a1)+
		clr.l	(a1)+
		dbra	d0,@b

		move.l	sp,-(sp)
		move	#$0100,-(sp)
		DOS	_FNCKEY
		addq.l	#6,sp

		lea	(712,sp),sp
		POP	d0-d1/a0-a1
		rts

extract_fnckey_define:
		jsr	(get_message)
		movea.l	d0,a0
		moveq	#10-1,d0
@@:
	.rept	8
		move.b	(a0)+,(a1)+		;8バイト
	.endm
	.rept	(32-8)/4
		clr.l	(a1)+
	.endm
		dbra	d0,@b
		rts

fnckey_table:
AK_ROLLUP::	.dc.b	FK_ROLLUP	;^C
AK_ROLLDOWN::	.dc.b	FK_ROLLDOWN	;^R
AK_INS::	.dc.b	FK_INS
AK_DEL::	.dc.b	FK_DEL		;^]
AK_UP::		.dc.b	FK_UP		;^E
AK_LEFT::	.dc.b	FK_LEFT		;^S
AK_RIGHT::	.dc.b	FK_RIGHT	;^D
AK_DOWN::	.dc.b	FK_DOWN		;^X
AK_CLR::	.dc.b	FK_CLR		;^L
AK_HELP::	.dc.b	FK_HELP		;^A
AK_HOME::	.dc.b	FK_HOME		;^K
AK_UNDO::	.dc.b	FK_UNDO		;^U
		.even


*************************************************
*		&endm=&nop			*
*************************************************
* テーブル削減のため &nop と共用している.

＆endm::
		rts


*************************************************
*		&reset				*
*************************************************

＆reset::
		bsr	restore_keyinp_ex_vector
		moveq	#0,d0
		trap	#10
		bra	hook_keyinp_ex_vector
**		rts


* ベクタフック -------------------------------- *

hook_keyinp_ex_vector::
		PUSH	d0-d2/a0-a2
		bsr	keyinp_ex_vector_sub
		pea	(prepare_exit_mint,pc)
		bra	@f
hook_keyinp_ex_vector_loop:
		move	(a0)+,d1		;vec no.
		move	(a0)+,d2		;offset
		tst.l	(a2,d0.w)
		beq	hook_keyinp_ex_vector_next

		pea	(-2,a0,d2.w)
@@:		move	d1,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		move.l	d0,(a1)
hook_keyinp_ex_vector_next:
		addq.l	#4,a1
		move	(a0)+,d0		;key_quick no.
		bpl	hook_keyinp_ex_vector_loop

		POP	d0-d2/a0-a2
		rts

keyinp_ex_vector_sub:
		lea	(hook_vec_table,pc),a0
		lea	(hook_vec_save),a1
		lea	(kq_buffer-hook_vec_save,a1),a2
		moveq	#.low.(_CTRLVC),d1
		rts

hook_vec_table:
		.dc	KQ_NMI*4 ,NMI_VEC   ,keyinp_ex_nmi_int-$
		.dc	KQ_POW*4 ,TRAP10_VEC,keyinp_ex_trap10_int-$
		.dc	KQ_ERR*4 ,TRAP14_VEC,keyinp_ex_trap14_int-$
		.dc	KQ_COPY*4,TRAP12_VEC,keyinp_ex_trap12_int-$
		.dc	KQ_FDD*4 ,FDCINS_VEC,keyinp_ex_fdd_int-$
		.dc	-1

* ベクタ復帰 ---------------------------------- *

restore_keyinp_ex_vector::
		PUSH	d0-d2/a0-a2
		bsr	keyinp_ex_vector_sub
		move.l	(a1),-(sp)
		bra	@f
restorekeyinp_ex_vector_loop:
		move	(a0)+,d1		;vec no.
		move	(a0)+,d2		;offset
		move.l	(a1),d0
		beq	restore_keyinp_ex_vector_next

		move.l	d0,-(sp)
@@:		move	d1,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
restore_keyinp_ex_vector_next:
		clr.l	(a1)+
		move	(a0)+,d0
		bpl	restorekeyinp_ex_vector_loop

		POP	d0-d2/a0-a2
		rts


* 拡張キー入力用割り込みフック ---------------- *

keyinp_ex_trap14_int:
		tst	d7
		bmi	keyinp_ex_trap14_int_orig
		btst	#14,d7
		bne	@f
keyinp_ex_trap14_int_orig:
*		PUSH	d0/a0			;無視が選択できないなら元の処理を呼び出す
*		lea	(iocs_b_keyinp_ex_key,pc),a0
*		move.b	#KQ_ERR,(a0)
*		POP	d0/a0
		move.l	(hook_vec_save+(1+3)*4),-(sp)
		rts
@@:
		PUSH	d0/a0
		move.b	#2,d7			;無視を選択したことにする
		moveq	#KQ_ERR,d0
		bra	@f

keyinp_ex_nmi_int:
		PUSH	d0/a0
		move.b	#%1100,(SYS_P4)		;nmi reset
		moveq	#KQ_NMI,d0
		bra	@f
keyinp_ex_trap10_int:
		PUSH	d0/a0
		moveq	#KQ_POW,d0
		bra	@f
keyinp_ex_trap12_int:
		PUSH	d0/a0
		moveq	#KQ_ERR,d0
@@:		lea	(iocs_b_keyinp_ex_key,pc),a0
		move.b	d0,(a0)
		POP	d0/a0
		rte
keyinp_ex_fdd_int:
		PUSH	d0/a0
		lea	(iocs_b_keyinp_ex_key,pc),a0
		move.b	#KQ_FDD,(a0)
		POP	d0/a0
		move.l	(hook_vec_save+(1+4)*4),-(sp)
		rts


* ディレクトリ関係の初期化 -------------------- *

* 起動時のカレントディレクトリ収得
* break	d0/a0-a1
save_boot_directory:
		DOS	_CURDRV
		addq	#1,d0
		lea	(boot_directory),a0
		bsr	get_current_path
		lea	(cur_dir_buf),a1
		STRCPY	a0,a1
		rts


* カレントディレクトリ収得
* in	d0.w	ドライブ番号(1:A 2:B ...)
*	a0.l	バッファ
* 機能:
*	指定ドライブのカレントディレクトリを "D:/path/" の形式
*	で収得する. パスデリミタは $MINTSLASH に統一される.

get_current_path:
		move.l	#('A'-1)<<24+':\'<<8,(a0)
		add.b	d0,(a0)

		pea	(.sizeof.('A:\'),a0)
		move	d0,-(sp)
		DOS	_CURDIR
		addq.l	#6,sp

		bsr	call_to_mintslash
		move.l	a0,-(sp)
@@:
		tst.b	(a0)+
		bne	@b
		clr.b	(a0)
		move.b	(MINTSLASH,opc),-(a0)	;末尾にパスデリミタを付ける
		movea.l	(sp)+,a0
		rts


* 起動時初期化 -------------------------------- *

init_path_struct:
		pea	(ReverseCursorBarBoth,pc)
		pea	(@f,pc)
@@:
		movea.l	(PATH_OPP,a6),a6

**		clr	(PATH_PAGETOP,a6)	;最上段の表示ディレクトリ位置
**		clr.b	(PATH_CURFILE,a6)	;カーソル位置ファイル名
**		clr.b	(PATH_NODISK,a6)	;取り敢えずディスク挿入状態にしておく

		bsr	regularize_initial_path
		moveq	#$20,d0
		or.b	(PATH_DIRNAME,a6),d0
		subi.b	#'a'-1,d0
		move	d0,(PATH_DRIVENO,a6)

		move	(＄srtm),d0
		cmpi	#$10,d0
		scc	(PATH_SORTREV,a6)	;+16 でリバースソート
		andi	#$0f,d0
		cmpi	#SRTM_MAX,d0
		bhi	@f
		move.b	d0,(PATH_SORT,a6)
@@:
		jbsr	restore_curfile
		bsr	chdir_routin
		bra	directory_write_routin
**		rts


* 環境変数 mintpath[12] 関係 ------------------ *

regularize_initial_path:
		lea	(PATH_DIRNAME,a6),a1
		tst.b	(a1)
		bne	regularize_initial_path_end
		tst	(＄prfl)
		bne	@f			;前回終了時のパスから起動しない

		pea	(a1)
		clr.l	-(sp)
		bsr	get_mintpath_envname	;a1="mintpath1"or"...2"
		move.l	a0,-(sp)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bpl	regularize_initial_path_end
@@:
		move.l	#'A:\'<<8,(a1)
		DOS	_CURDRV
		add.b	d0,(a1)
		pea	(3,a1)
		clr	-(sp)
		DOS	_CURDIR
		addq.l	#6,sp
regularize_initial_path_end:
**		lea	(PATH_DIRNAME,a6),a1
		jbra	fullpath_a1
**		rts

setenv_mintpath12:
		tst	(＄prfl)
		bne	@f

		bsr	setenv_mintpath		;右側で終了すると mintpath2 の方が先に
		movea.l	(PATH_OPP,a6),a6	;登録されるけど、別に害はないので無視
		bsr	setenv_mintpath
		movea.l	(PATH_OPP,a6),a6
@@:
		rts

setenv_mintpath:
		pea	(PATH_DIRNAME,a6)
		clr.l	-(sp)
		bsr	get_mintpath_envname
		move.l	a0,-(sp)
		DOS	_SETENV
		lea	(12,sp),sp
		rts

get_mintpath_envname:
		lea	(str_mintpath,pc),a0
		moveq	#'1',d0
		tst	(PATH_WINRL,a6)
		beq	@f
		moveq	#'2',d0
@@:		move.b	d0,(.sizeof.('mintpath'),a0)
		rts

str_mintpath:
		.dc.b	'mintpath',0,0
		.even


* 環境変数領域初期化 -------------------------- *

make_own_env:
		PUSH	d0-d1/a0-a1
		move	(own_env_size,pc),d0
		beq	make_own_env_end

		mulu	#1024,d0
		move.l	(mint_start-PSP_SIZE+PSP_Env,opc),d1
		ble	1f			;親は環境を持っていない

		movea.l	d1,a0
		move.l	(a0)+,d1		;親の環境変数エリアサイズ
		cmp.l	d0,d1
		bcc	@f
1:		move.l	d0,d1
@@:
		move.l	d1,-(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	make_own_env_err

		movea.l	d0,a1
		move.l	a1,(mint_start-PSP_SIZE+PSP_Env)

		move.l	d1,(a1)+		;確保した環境変数エリアのサイズ
		subq.l	#4,d1
@@:
		move.b	(a0)+,(a1)+
		subq.l	#1,d1
		bne	@b
make_own_env_end:
		POP	d0-d1/a0-a1
		rts

make_own_env_err:
		pea	(make_own_env_err_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		bra	make_own_env_end

own_env_size:	.ds	1


* 環境変数収得 -------------------------------- *

mint_getenv::
.if 0
		bsr	getenv_wordchars
		bsr	getenv_cdpath
		bsr	getenv_sysroot
		bsr	getenv_mintmes2
.endif
		bsr	getenv_slash
		bra	getenv_minttmp
**		rts

getenv_slash:
		lea	(-256,sp),sp
		moveq	#'\',d1

		move.l	sp,-(sp)
		clr.l	-(sp)
		pea	(str_mintslash,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	1f

		pea	(str_slash,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bmi	@f
1:
		cmpi	#'/'<<8,(12-4,sp)
		bne	@f
		moveq	#'/',d1
@@:
		move.b	d1,(MINTSLASH)
		lea	(256+(12-4),sp),sp
		rts

getenv_minttmp:
		lea	(MINT_TEMP),a1

		pea	(a1)
		clr.l	-(sp)
		pea	(str_minttmp,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		pea	(str_temp,pc)		;まず "temp" を調べる
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		pea	(str_TEMP,pc)		;なければ "TEMP"
		DOS	_GETENV
		move.l	d0,(sp)+
@@:
		addq.l	#12-4,sp
		bmi	1f
		jbsr	fullpath_a1
		bpl	@f
1:		clr.b	(a1)
@@:		rts


.if 0
getenv_wordchars:
		lea	(-256,sp),sp
		lea	(sp),a0

		move.l	a0,-(sp)
		clr.l	-(sp)
		pea	(str_mintwordchars,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		pea	(str_wordchars,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		clr.b	(a0)
@@:
		clr.b	(15,a0)
		.xref	 MINTWORDCHARS
		lea	(MINTWORDCHARS),a1
		STRCPY	a0,a1

		lea	(256+(12-4),sp),sp
		rts

getenv_cdpath:
		lea	(cdpath_buf),a0
		clr.b	(a0)

		move.l	a0,-(sp)
		clr.l	-(sp)
		pea	(str_mintcdpath,opc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		pea	(str_cdpath,opc)
		DOS	_GETENV
		move.l	d0,(sp)+
@@:		addq.l	#12-4,sp
		rts

getenv_sysroot:
		lea	(sysroot_buf),a1
		clr.b	(a1)

		pea	(a1)
		clr.l	-(sp)
		pea	(str_sysroot,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	1f
		jbsr	fullpath_a1
		bpl	@f
1:		clr.b	(a1)
@@:		rts

getenv_mintmes2:
		lea	(mintmes2_buf),a0
		clr.b	(a0)

		move.l	a0,-(sp)
		clr.l	-(sp)
		pea	(str_mintmes2,pc)
		DOS	_GETENV
		lea	(12,sp),sp
		rts

str_mintwordchars:
		.dc.b	'MINT'
str_wordchars:	.dc.b	    'WORDCHARS',0

		.bss
cdpath_buf:	.ds.b	256
sysroot_buf:	.ds.b	64
mintmes2_buf:	.ds.b	256
		.text
.endif


str_minttmp:	.dc.b	'MINTTMP',0
str_temp:	.dc.b	'temp',0
str_TEMP:	.dc.b	'TEMP',0
str_mintslash:	.dc.b	'MINT'
str_slash:	.dc.b	    'SLASH',0
str_mintmes2:	.dc.b	'MINTMES2',0
str_sysroot:	.dc.b	'SYSROOT',0
		.even


* メモリ確保モードの収得 ---------------------- *
* mint.x のヘッダ内のロードモードを読み込む.

get_malloc_mode:
		lea	(Buffer),a0
		lea	(a0),a2
		lea	(mint_start-PSP_SIZE+PSP_Drive,opc),a1
		STRCPY	a1,a2
		subq.l	#1,a2
		lea	(mint_start-PSP_SIZE+PSP_Filename,opc),a1
		STRCPY	a1,a2

		clr	-(sp)
		move.l	a0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d1
		bmi	get_malloc_mode_error2

		pea	(4)			;length
		move.l	a0,-(sp)		;buffer address
		move	d1,-(sp)
		DOS	_READ
		addq.l	#6,sp
		cmp.l	(sp)+,d0
		bne	get_malloc_mode_error1
		cmpi	#'HU',(a0)+
		bne	get_malloc_mode_error1

*		clr.b	(a0)			;上位バイトは必ず0のはず
		move	(a0),(malloc_mode)
get_malloc_mode_error1:
		move	d1,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
get_malloc_mode_error2:
		rts


* その他の初期化 ------------------------------ *
* MPU タイプの収得.
* Human68k の PSP アドレス収得(RCD 常駐検査用).
* (V)TwentyOne.sys フラグアドレス収得.
* break d0/a0-a1

misc_init:
		TO_SUPER

*get_mputype:
		move.b	(MPUTYPE),(MpuType)

*get_human_psp:
		move.l	(mint_start-PSP_SIZE+pare,opc),d0
@@:
		movea.l	d0,a0
		move.l	(pare,a0),d0
		bne	@b
		move.l	a0,(human_psp)

		TO_USER
*get_twon_adr:
		clr	-(sp)			;move #_TWON_GETID,-(sp)
		DOS	_TWON
		cmpi.l	#_TWON_ID,d0
		bne	@f
		addq	#_TWON_GETADR,(sp)
		DOS	_TWON
		move.l	d0,(twon_adrs)
@@:		addq.l	#2,sp

		rts


* (V)TwentyOne.sys オプションフラグ収得 ------- *

* out	d0.l	フラグ(0 なら組み込まれてない)

twon_getopt::
		move.l	(twon_adrs,pc),d0
		beq	@f			;組み込まれていない

		move	#_TWON_GETOPT,-(sp)
		DOS	_TWON
		addq.l	#2,sp
@@:		rts

twon_adrs::	.ds.l	1


* HUPAIR Decoder ------------------------------ *

GetArgChar::
		PUSH	d1/a0-a1
		moveq	#0,d0
		lea	(GetArgChar_p,pc),a0
		movea.l	(a0)+,a1
		move.b	(a0),d0
		bmi	GetArgChar_noarg
GetArgChar_quate:
		move.b	d0,d1
GetArgChar_next:
		move.b	(a1)+,d0
		beq	GetArgChar_endarg
		tst.b	d1
		bne	GetArgChar_inquate
		cmpi.b	#' ',d0
		beq	GetArgChar_separate
		cmpi.b	#"'",d0
		beq	GetArgChar_quate
		cmpi.b	#'"',d0
		beq	GetArgChar_quate
GetArgChar_end:
		move.b	d1,(a0)
		move.l	a1,-(a0)
GetArgChar_abort:
		POP	d1/a0-a1
		rts
GetArgChar_endarg:
		st	(a0)
		bra	GetArgChar_abort
GetArgChar_noarg:
		moveq	#1,d0
		ror.l	#1,d0
		bra	GetArgChar_abort

GetArgChar_inquate:
		cmp.b	d0,d1
		bne	GetArgChar_end
		clr.b	d1
		bra	GetArgChar_next

GetArgChar_separate:
		cmp.b	(a1)+,d0
		beq	GetArgChar_separate
		moveq	#0,d0
		tst.b	-(a1)
		beq	GetArgChar_endarg
		bra	GetArgChar_end

GetArgCharInit::
		PUSH	a0-a1
		movea.l	(12,sp),a1
GetArgCharInit_skip:
		cmpi.b	#' ',(a1)+
		beq	GetArgCharInit_skip
		tst.b	-(a1)
		lea	(GetArgChar_c,pc),a0
		seq	(a0)
		move.l	a1,-(a0)
		POP	a0-a1
		rts


.if 1
GetArgChar_p:	.dc.l	0
GetArgChar_c:	.dc.b	0
.else
GetArgChar_p:	.equ	GetArgCharInit
GetArgChar_c:	.equ	GetArgCharInit+4
.endif

skip_mintrc_flag:
		.ds.b	1			;-f
		.even

execute_ptr:	.ds.l	1			;-e


* オプション解析 ------------------------------ *

option_skip:
		bsr	GetArgChar
		tst.b	d0
		bne	option_skip
option_check:
		lea	(Buffer),a0
@@:
		bsr	GetArgChar
		tst.l	d0
		beq	@b
		bmi	option_check_end

		cmpi.b	#'-',d0
		bne	option_path
option_loop:
		bsr	GetArgChar
		tst.l	d0
		beq	option_check
		bmi	option_check_end

		cmpi.b	#'?',d0
		beq	option_Help
		cmpi.b	#'E',d0
		beq	option_Env

		ori.b	#$20,d0
		cmpi.b	#'s',d0
		beq	option_Source
		cmpi.b	#'e',d0
		beq	option_Execute
		cmpi.b	#'f',d0
		beq	option_Fast
		cmpi.b	#'c',d0
		beq	option_Clear

		cmpi.b	#'h',d0
		beq	option_Help
		cmpi.b	#'v',d0
		beq	option_Version

		cmpi.b	#'m',d0
		beq	option_Message
		cmpi.b	#'d',d0
		beq	option_Dump
		cmpi.b	#'t',d0
		beq	option_Type
		cmpi.b	#'p',d0
		beq	option_Print
		cmpi.b	#'l',d0
		bne	option_loop
*option_List:
		jmp	(type_system_value_table)
option_Print:
		jmp	(print_system_value_table)
option_Type:
		jmp	(type_function_table)
option_Dump:
		jmp	(dump_function_table)
option_Message:
		jmp	(print_message_list)
option_Help:
		jmp	(print_usage)
option_Version:
		jmp	(print_version)

option_Env:
		lea	(own_env_size,pc),a0
		move	#10,(a0)
		bra	option_loop
option_Clear:
		moveq	#T_ON,d1
		IOCS	_VC_R2
		bra	option_loop
option_Fast:
		lea	(skip_mintrc_flag,pc),a2
		st	(a2)
		bra	option_loop

option_Execute:
		movea.l	(GetArgChar_p,pc),a0
		move.l	a0,d0
@@:		tst.b	(a0)+
		bne	@b
		suba.l	d0,a0			;最大必要サイズ(概算)

		move.l	a0,-(sp)
		DOS	_MALLOC
		move.l	d0,(sp)+
		bpl	@f
		pea	(mem_err_mes,pc)
		bra	print_exit1
@@:
		lea	(execute_ptr,pc),a0
		st	(write_disable_flag-execute_ptr,a0)
		move.l	d0,(a0)
		movea.l	d0,a0
		bra	@f
option_Execute_loop:
		move.b	#SPACE,(-1,a0)
@@:
		bsr	GetArgChar
		move.b	d0,(a0)+
		bne	@b
		tst.l	d0
		beq	option_Execute_loop
option_check_end:
		rts

option_Source:
		bsr	GetArgChar
		tst.l	d0
		beq	option_Source
		bmi	option_check_end

		lea	(a0),a1
		move.b	d0,(a1)+
		move	#1024-1-1,d1
@@:
		bsr	GetArgChar
		move.b	d0,(a1)+
		dbeq	d1,@b
		beq	@f
option_s_error:
		pea	(rc_read_err_mes,pc)
		bra	print_exit1
@@:
		clr	-(sp)
		pea	(a0)
		jbsr	to_fullpath_file
		bmi	@f
		DOS	_OPEN
@@:		addq.l	#6,sp
		bmi	option_s_error

		move	d0,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp

		lea	(mintrc_filename),a1
		STRCPY	a0,a1
		bra	option_check

option_path:
		lea	(a0),a1
		move.b	d0,(a1)+
		move	#1024-1-1,d1
@@:
		bsr	GetArgChar
		move.b	d0,(a1)+
		dbeq	d1,@b
		bne	option_skip

		lea	(a0),a1
		jbsr	fullpath_a1
		bmi	option_path_error

		lea	(PATH_DIRNAME,a6),a0
		tst.b	(a0)
		beq	@f
		movea.l	(PATH_OPP,a6),a0
		addq.l	#PATH_DIRNAME,a0
@@:
		STRCPY	a1,a0
option_path_error:
		bra	option_check


* フルパス化 ---------------------------------- *
* in	a1.l	パス名
* out	ccr	N=0:正常終了 N=1:エラー
* 備考:
*	パスデリミタは MINTSLASH.
*	パス名の末尾には必ずパスデリミタが付く.

fullpath_a1::
		PUSH	d0/a1
		pea	(a1)
		bsr	to_fullpath_file_or_dir
		addq.l	#4,sp
		bmi	fullpath_a1_end
@@:
		tst.b	(a1)+
		bne	@b
		clr.b	(a1)
		move.b	(MINTSLASH,opc),-(a1)	;ccrN=0
**		moveq	#0,d0
fullpath_a1_end:
		POP	d0/a1
		rts


to_fullpath_file_or_dir::
		PUSH	a0-a2
		movea.l	(16,sp),a0
		lea	(a0),a2
		lea	(-NAMECK_SIZE,sp),sp
		move.l	sp,-(sp)
		move.l	a0,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bmi	to_fullpath_file_end
		bra	@f

to_fullpath_file::
		PUSH	a0-a2
		movea.l	(16,sp),a0
		lea	(a0),a2
		lea	(-NAMECK_SIZE,sp),sp
		move.l	sp,-(sp)
		move.l	a0,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bmi	to_fullpath_file_end
		bne	to_fullpath_file_error
@@:
		lea	(NAMECK_Drive,sp),a1
		STRCPY	a1,a2			;d:/dir/
		subq.l	#1,a2
		lea	(NAMECK_Name,sp),a1
		STRCPY	a1,a2			;filename
		subq.l	#1,a2
		lea	(NAMECK_Ext,sp),a1
		STRCPY	a1,a2			;.ext

		bsr	call_to_mintslash
		moveq	#0,d0
to_fullpath_file_end:
		lea	(NAMECK_SIZE,sp),sp
		POP	a0-a2
		rts
to_fullpath_file_error:
		moveq	#-1,d0
		bra	to_fullpath_file_end


* 定義ファイル読み込み ------------------------ *

;検索順
;  -s file
;  $MINTRC3
;  $MINTRC
;  $HOME/.mint
;  $HOME/_mint
;  mintの存在するパス/.mint
;  mintの存在するパス/_mint

* 下請け
mintrc_getenv:
		pea	(a0)
		clr.l	-(sp)
		pea	(a2)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		rts

* 下請け
mintrc_file_exist_check:
  PUSH a2-a3
  lea (str_dotmint,pc),a2  ;'/.mint'
  lea (a0),a3
  STRCAT a2,a3
  bsr mintrc_file_exist_check2
  bpl @f
    lea (a0),a3  ;'～/.mint'がなければ、'～/_mint'を開いてみる
    STREND a3
    move.b #'_',(-.sizeof.('.mint'),a3)
    bsr mintrc_file_exist_check3
  @@:
  POP a2-a3
  rts

mintrc_file_exist_check2:
  bsr call_to_mintslash
mintrc_file_exist_check3:
  clr -(sp)
  pea (a0)
  DOS _OPEN
  tst.l d0
  bmi @f
    move d0,(sp)
    DOS _CLOSE
    tst.l d0
  @@:
  addq.l #6,sp
  rts

* 読み込み処理開始
read_mintrc:
		lea	(mintrc_filename),a1
		tst.b	(a1)
		bne	read_mintrc2		;所在確認済み

		lea	(-256,sp),sp
		lea	(sp),a0

		lea	(str_mintrc3,pc),a2
		move.b	#'3',(6,a2)		;$MINTRC3
		bsr	mintrc_getenv
		bmi	@f
		bsr	mintrc_file_exist_check2
		bpl	mintrc_search_ok
@@:
		clr.b	(6,a2)			;$MINTRC
		bsr	mintrc_getenv
		bmi	@f
		bsr	mintrc_file_exist_check2
		bpl	mintrc_search_ok
@@:
		pea	(a0)			;$HOME/.mint
		clr.l	-(sp)
		pea	(str_home,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	@f
		bsr	mintrc_file_exist_check
		bpl	mintrc_search_ok
@@:
		lea	(mint_start-PSP_SIZE+PSP_Drive,opc),a2
		lea	(a0),a3
		STRCPY	a2,a3			;実行ファイルのパス/.mint
		bsr	mintrc_file_exist_check
		bmi	mintrc_not_found
mintrc_search_ok:
		pea	(a0)
		jbsr	to_fullpath_file
		lea	(a1),a2
		STRCPY	a0,a2
		lea	(4+256,sp),sp
read_mintrc2:
**		lea	(mintrc_filename),a1
		clr	-(sp)
		move.l	a1,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d7
		bmi	mintrc_read_error

		move	#SEEK_END,-(sp)
		clr.l	-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		move.l	d0,d6			;filesize
		clr	(6,sp)
		DOS	_SEEK			;先頭に戻す
		addq.l	#8,sp

		move.l	d6,(mintrc_size)
		addq.l	#4,d6			;LF,LF,EOF,EOF の分
		cmp.l	(mintrc_buf_size),d6
		bls	mintrc_malloc_skip
		move.l	(mintrc_buf_adr),d0
		beq	mintrc_mfree_skip

		move.l	d0,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
mintrc_mfree_skip:
		pea	(4096)			;&source 時の為に余分に確保する
		add.l	d6,(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#2,sp
		move.l	(sp)+,(mintrc_buf_size)
		move.l	d0,(mintrc_buf_adr)
		bmi	mintrc_malloc_error
mintrc_malloc_skip:
		movea.l	(mintrc_buf_adr),a0
		subq.l	#4,d6
		move.l	d6,-(sp)
		move.l	a0,-(sp)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	mintrc_read_error

		adda.l	d0,a0			;読み込んだ内容の末尾
		moveq	#LF,d0
		move.b	d0,(a0)+
		move.b	d0,(a0)+
		moveq	#EOF,d0
		move.b	d0,(a0)+
		move.b	d0,(a0)+

		clr.l	-(sp)
		move	d7,-(sp)
		DOS	_FILEDATE
		move.l	d0,(mintrc_timestamp)
		DOS	_CLOSE
		addq.l	#6,sp
		rts

str_mintrc3:	.dc.b	'MINTRC3',0
str_home:	.dc.b	'HOME',0
str_dotmint:	.dc.b	'/.mint',0
		.even


* エラー終了 ---------------------------------- *

float_error:
		pea	(float_err_mes,pc)
		bra	@f
memory_error:
		pea	(mem_err_mes,pc)
		bra	@f
mintrc_not_found:
		pea	(rc_err_mes,pc)
		bra	@f
mintrc_malloc_error:
		pea	(rc_mem_err_mes,pc)
		bra	@f
mintrc_read_error:
		pea	(rc_read_err_mes,pc)
@@:
		jsr	(＆pop_text)		;$MINTTITLE の表示を消す
		jbsr	restore_keyinp_ex_vector
		bsr	breakck_restore
print_exit1:
		DOS	_PRINT
		move	#1,(sp)
		DOS	_EXIT2


float_err_mes:
  .dc.b '浮動小数点演算パッケージが組み込まれていません。',CR,LF,0

rc_read_err_mes:
  .dc.b '定義ファイル(~/.mint)の読み込みに失敗しました。',CR,LF

rc_err_mes:
  .dc.b '定義ファイルが見つかりません。定義ファイルのフルパスを環境変数 MINTRC3 に指定するか、',CR,LF
  .dc.b 'ホームディレクトリ(環境変数 HOME)にファイル名 .mint または _mint として置いてください。',CR,LF,0

rc_mem_err_mes:
  .dc.b ' 定義ファイル(~/.mint)の読み込みに必要なメモリがありません。',CR,LF,0

make_own_env_err_mes:
mem_err_mes:
  .dc.b ' メモリが不足しています。',CR,LF,0
.even


* ブレークモード設定 -------------------------- *

breakck_restore::
		move.l	d0,-(sp)
		move	(breakck_save,pc),-(sp)
		bra.s	@f

breakck_save_kill::
		move.l	d0,-(sp)
		move	#-1,-(sp)
		DOS	_BREAKCK
		move	d0,(breakck_save)

		addq	#2+1,(sp)		;move #2,(sp)
@@:
		DOS	_BREAKCK
		addq.l	#2,sp
		move.l	(sp)+,d0
		rts

breakck_save:	.ds	1


* ~/.mint システム変数初期値定義解析 ---------- *

analyze_mintrc_sysvalue:
		move.b	(ld_phis_sys_flag),d0
		bne	analyze_mintrc_sysv_end

		moveq	#'%',d0
		bsr	system_header_search_init
		lea	(sys_val_table),a4
		lea	(sys_val_name-sys_val_table,a4),a5
		bsr	system_header_search_1st
		bne	analyze_mintrc_sysv_end
analyze_mintrc_sysv_loop:
		move.b	(a3)+,-(sp)
		move	(sp)+,d0
		move.b	(a3)+,d0
		swap	d0
		move.b	(a3)+,-(sp)
		move	(sp)+,d0
		move.b	(a3)+,d0		;変数名

		lea	(a4),a0			;変数アドレス
		lea	(a5),a1			;変数名
		subq.l	#2,a0
@@:
		move.l	(a1)+,d1
		beq	analyze_mintrc_sysv_next
		addq.l	#2,a0
		cmp.l	d0,d1
		bne	@b

		lea	(a3),a1
		jbsr	skip_blank_a1
		jsr	(atoi_a1)
		move	d0,(a0)
analyze_mintrc_sysv_next:
		bsr	system_header_search	;'%'検索
		beq	analyze_mintrc_sysv_loop
analyze_mintrc_sysv_end:
analyze_mintrc_mes_end:
		rts


* ~/.mint メッセージ文字列定義解析 ------------ *

analyze_mintrc_message:
		move.b	(ld_phis_mes_flag),d0
		bne.s	analyze_mintrc_mes_end

		movea.l	(mintrc_buf_adr),a0
		jmp	(pickup_message_change)
**		rts


* キー定義テーブル初期化 ---------------------- *

init_kq_ptr_buffer:
		lea	(kq_buffer+KQ_MAX*4),a0
		move	#KQ_MAX-1,d0
		moveq	#0,d1
@@:
		move.l	d1,-(a0)
		dbra	d0,@b
		pea	(key_quick_esc_default+1,pc)
		move.l	(sp)+,(KQ_ESC*4,a0)	;>KEYesc が未設定なら終了を割り当てる
		rts


		.dc.b	'>KEYesc'
key_quick_esc_default::
		.dc.b	' - &quit',0
		.even


* 定義ファイル解析 ---------------------------- *

analyze_mintrc:
		bsr	analyze_mintrc_kq
		bsr	analyze_mintrc_at
		bsr	analyze_mintrc_macro
		bsr	analyze_mintrc_fn
		bsr	analyze_mintrc_ext
		bra	analyze_mintrc_match
**		rts


* キー定義解析 -------------------------------- *

analyze_mintrc_kq:
		move.b	(ld_phis_keyq_flag),d0
		bne	ana_rc_kq_end

		move.l	#kq_name_list,d3
		move.l	#kq_buffer,d4
		moveq	#'>',d0
		bsr	system_header_search_init
		movea.l	d3,a4
		movea.l	d4,a5
		bsr	system_header_search_1st
		bne	ana_rc_kq_end
ana_rc_kq_loop:
		cmpi.b	#'K',(a3)
		beq	@f
		lea	(6*KQ_FUNC,a4),a4	;'K' 以外はかなり先.
		lea	(4*KQ_FUNC,a5),a5	;〃
@@:
		move.b	(a3)+,-(sp)
		move	(sp)+,d1
		move.b	(a3)+,d1		;KE
		swap	d1
		move.b	(a3)+,-(sp)
		move	(sp)+,d1
		move.b	(a3)+,d1		;KEY_
		move.b	(a3)+,-(sp)
		move	(sp)+,d2
		move.b	(a3)+,d2		;    X_
ana_rc_kq_loop2:
		cmp.l	(a4)+,d1
		bne	1f
		cmp	(a4)+,d2
		bne	2f

		movea.l	a3,a1
		jbsr	skip_blank_a1
**		cmpa.l	a3,a1
**		beq	@f
**		subq.l	#1,a1			;空白を最低一個残しておく
**@@:
		move.l	a1,(a5)
		movea.l	a1,a3
		bra	ana_rc_kq_next
1:
		addq.l	#2,a4
2:
		addq.l	#4,a5
		tst.b	(a4)
		bne	ana_rc_kq_loop2
ana_rc_kq_next:
		movea.l	d3,a4
		movea.l	d4,a5
		bsr	system_header_search	;'>'検索
		beq	ana_rc_kq_loop
ana_rc_kq_end:
		rts


* ＠セクション解析 ---------------------------- *

analyze_mintrc_at:
		lea	(at_def_list),a0
		moveq	#0,d0
		lea	(a0),a2
		bra	1f
ana_rc_at_init:
		move.l	d0,(a2)+		;ポインタ初期化
		move	d0,(a2)+		;行数初期化
1:		tst.l	(a2)+
		bgt	ana_rc_at_init

		moveq	#'@',d0
		bsr	system_header_search_init
		bsr	system_header_search_1st
		bmi	ana_rc_at_end
ana_rc_at_loop:
		move.b	(a3)+,-(sp)		;4 文字収得
		move	(sp)+,d1
		move.b	(a3)+,d1
		swap	d1
		move.b	(a3)+,-(sp)
		move	(sp)+,d1
		move.b	(a3)+,d1

		lea	(a3),a1
		bsr	next_line_a1
		beq	ana_rc_at_end		;EOF

		lea	(a0),a2			;at_def_list
* 登録メニュー以外を個別処理
		cmpi.l	#'comp',d1
		bne	@f
		move.l	a1,(at_complete_list)
		bra	ana_rc_at_next
@@:
		lea	(analyze_@gvon_section),a4
		cmpi.l	#'gvon',d1
		beq	ana_rc_at_bind
		lea	(analyze_@look_section-analyze_@gvon_section,a4),a4
		cmpi.l	#'look',d1
		bne	@f
ana_rc_at_bind:
		PUSH	a0/a3
		lea	(a1),a0			;定義先頭
		jsr	(a4)			;解析ルーチン呼び出し
		POP	a0/a3
		bra	ana_rc_at_next
* 登録メニュー
ana_rc_at_search_loop:
		addq.l	#sizeof_AT_DEF-4,a2
@@:		move.l	(a2)+,d0
		bmi	ana_rc_at_next		;無かった
		cmp.l	d0,d1
		bne	ana_rc_at_search_loop

		move.l	a1,(a2)+		;AT_DEF_PTR

		moveq	#0,d1			;定義行数を数える
ana_rc_at_count_line:
		cmpi.b	#$20,(a1)
		bhi	@f			;項目が続いている	A "..." -- xxx
		beq	ana_rc_at_blank		;複数行記述			-t yyy
		cmpi.b	#TAB,(a1)
		beq	ana_rc_at_blank		;〃
		bra	ana_rc_at_last		;定義ブロック終了
@@:
		addq	#1,d1			;項目数++
		cmpi	#MENU_MAX,d1
		beq	ana_rc_at_last
ana_rc_at_blank:
		bsr	next_line_a1
		bne	ana_rc_at_count_line
ana_rc_at_last:
		move	d1,(a2)			;AT_DEF_NUM
		bne	ana_rc_at_next
		clr.l	-(a2)			;一行もなければキャンセル
ana_rc_at_next:
		bsr	system_header_search	;'@' 検索
		beq	ana_rc_at_loop
ana_rc_at_end:
		rts


* a1 を次の行に進める.
* in	a1.l	テキストデータ
* out	a1.l	次の行(最初に見つけた LF か EOF の次のバイトを指す)
*	ccr	Z=1:EOF Z=0:データ有り
* break	d0
* 備考:
*	LF を見つけた場合、次のバイト(=a1)が EOF なら ccrZ=1 を返す.

next_line_a1::
		move.b	(a1)+,d0
		cmpi.b	#EOF,d0
		bhi	next_line_a1
		beq	next_line_a1_end
		cmpi.b	#LF,d0
		bne	next_line_a1
		cmpi.b	#EOF,(a1)
next_line_a1_end:
		rts


* マクロ定義解析 ------------------------------ *

analyze_mintrc_macro:
		lea	(macro_table),a4
		lea	(macro_table_end-macro_table,a4),a5

		moveq	#'$',d0
		bsr	system_header_search_init
		bsr	system_header_search_1st
		bne	ana_rc_mac_end
ana_rc_mac_loop:
		move.l	a3,(a4)+		;マクロ登録
		cmpa.l	a4,a5
		beq	ana_rc_mac_end		;バッファがいっぱいになった
*ana_rc_mac_next:
		bsr	system_header_search	;'$'検索
		beq	ana_rc_mac_loop
ana_rc_mac_end:
		clr.l	(a4)
		rts


* ファイル名判別定義解析 ---------------------- *

analyze_mintrc_fn:
		lea	(file_match_table),a4
		lea	(file_match_table_end-file_match_table,a4),a5

		moveq	#'!',d0
		bsr	system_header_search_init
		bsr	system_header_search_1st
		bne	ana_rc_fn_end
ana_rc_fn_loop:
		cmpi.b	#$20,(a3)
		bls	ana_rc_fn_next		;登録メニューの ! "～" は無視する

		move.l	a3,(a4)+		;ファイル名判別登録
		cmpa.l	a4,a5
		beq	ana_rc_fn_end		;バッファがいっぱいになった
ana_rc_fn_next:
		bsr	system_header_search	;'!'検索
		beq	ana_rc_fn_loop
ana_rc_fn_end:
		clr.l	(a4)
		rts


* 拡張子判別定義解析 -------------------------- *
* 最初の定義('.')だけを探す

analyze_mintrc_ext:
		moveq	#'.',d0
		bsr	system_header_search_init
		bsr	system_header_search	;'.'検索
		bne	@f

		subq.l	#1,a3			;最初に現われたピリオドのアドレス
		move.l	a3,(period_start)	;(なければ定義ファイル先頭)
@@:
		rts


* ファイル内容判別定義解析 -------------------- *

		.offset	0
neko_pat:	.ds.b	128
neko_buf:	.ds	256
sizeof_neko:
		.text

analyze_mintrc_match:
		lea	(-sizeof_neko,sp),sp
		clr.l	(_ignore_case)
		lea	(file_compare_table),a4
		lea	(file_compare_table_end-file_compare_table,a4),a5

		moveq	#'^',d0
		bsr	system_header_search_init
		bsr	system_header_search_1st
		bne	ana_rc_match_end
ana_rc_match_loop:
		* ========= オフセット格納 ==========
		movea.l	a3,a1
		move.b	(a1)+,d0
		cmpi.b	#'^',d0			;^^ バイナリファイル指定
		beq	@f
		cmpi.b	#'~',d0			;^~ テキスト〃
		beq	@f
		subq.l	#1,a1
@@:
		moveq	#0,d0
		cmpi.b	#' ',(a1)		;^ MAKI02
		bls	ana_rc_match_set_offs	;オフセット省略時は 0 にする

		jsr	(atoi_a1)		;^0 PIC
		cmp	(＄fcmp),d0
		bcs	ana_rc_match_set_offs

* オフセットが大きすぎる
		pea	(ana_rc_match_over_mes,pc)
		DOS	_PRINT

		subq.l	#1,a3
		move.l	a3,(sp)			;'^'のアドレス
@@		cmpi.b	#LF,(a3)+
		bne	@b
		move.b	(a3),d1
		clr.b	(a3)
		DOS	_PRINT			;問題の定義部分を表示
		move.b	d1,(a3)
		movea.l	(sp)+,a3
		addq.l	#1,a3

		pea	(ana_rc_match_over_mes2,pc)
		DOS	_PRINT
		addq.l	#4,sp

		DOS	_INKEY
		moveq	#0,d0
ana_rc_match_set_offs:
		move	d0,(a4)+		;オフセット

		* ==== 文字列格納(even 処理付き) ====
		jbsr	skip_blank_a1
		lea	(neko_pat,sp),a2
		moveq	#128-2,d0
		bsr	copy_regexp

		pea	(a2)			;パターン文字列
		pea	(256)			;バッファサイズ
		pea	(8+neko_buf,sp)		;コンパイルデータ格納用バッファ
		jsr	(_fre_compile)
		lea	(12,sp),sp

		lea	(neko_buf,sp),a1
@@:		move.b	(a1)+,(a4)+		;コンパイルしたデータをコピー
		bne	@b
		move.b	(a1)+,(a4)+		;最後に NUL
		bne	@b

		move	a4,d0
		lsr	#1,d0
		bcc	@f
		clr.b	(a4)+			;even
@@:
		move.l	a3,(a4)+		;'^'+1 のアドレス

		cmpa.l	a5,a4
		bhi	ana_rc_match_over	;バッファが足りなくなった

		bsr	system_header_search	;'^' 検索
		beq	ana_rc_match_loop
ana_rc_match_end:
		clr.l	(a4)+
		clr.l	(a4)+
		clr.l	(a4)+
		lea	(sizeof_neko,sp),sp
		rts

ana_rc_match_over:
		pea	(ana_rc_match_buf_over_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		bra	ana_rc_match_end


* パターンを切り出す
* in	d0.w	バッファサイズ-2
*	a1.l	パターン
*	a2.l	バッファ

copy_regexp:
		PUSH	d1/d7/a1-a2
		move	d0,d7
copy_rx_quote2:
		moveq	#0,d1
copy_rx_loop:
		move.b	(a1)+,d0
		beq	copy_rx_end
		cmp.b	d0,d1
		beq	copy_rx_quote2
		cmpi.b	#'"',d0
		beq	copy_rx_quote
		cmpi.b	#"'",d0
		bne	@f
copy_rx_quote:
		move.b	d0,d1
		bra	copy_rx_loop
@@:
		cmpi.b	#$20,d0
		bcs	copy_rx_end
		bne	@f
		tst.b	d1
		beq	copy_rx_end
@@:
		subq	#1,d7
		bcs	copy_rx_end
		move.b	d0,(a2)+
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	copy_rx_loop
		move.b	(a1)+,(a2)+
		subq	#1,d7
		bcc	copy_rx_loop
		subq.l	#2,a2
copy_rx_end:
		move.b	#'*',(a2)+
		clr.b	(a2)+
		POP	d1/d7/a1-a2
		rts


ana_rc_match_buf_over_mes:
		.dc.b	'madoka: ファイル内容判別定義用コンパイルバッファが溢れました.',CR,LF
		.dc.b	'	里衣座を増設して下さい.',CR,LF,0
ana_rc_match_over_mes:
		.dc.b	'madoka: ファイル内容判別定義のオフセットアドレスが設定値あるいは限界値を超越しています.',CR,LF
		.dc.b	'	尚、システム変数 fcmp により、',FCMP_MAX_STR,' バイトまでは拡張できます.',CR,LF
ana_rc_match_over_mes2:
		.dc.b	"===================================",CR,LF,0
**		.even


* データ形式
*	1.w	比較開始オフセット(0～)
*	?.b	コンパイル済みパターン
*	1.b	$00
*	(1.b)	現在までが奇数サイズの場合のみ、$00 を置いて偶数サイズに補正
*	1.l	定義ファイル上のアドレスへのオフセット
*
* データ終端は先頭からの 1.l が $00000000 になる.
* ただし、終端確認は オフセット 2 からの 1.w が $0000 で
* あるかどうかで行う.


* 定義ファイル内キーワード検索 ---------------- *

system_header_search_char:
		.dc.b	0
		.even

system_header_search_init:
		movea.l	(mintrc_buf_adr),a3
		move.b	d0,(system_header_search_char)
		rts

system_header_search_1st:
		PUSH	d5-d7
		move.b	(system_header_search_char,pc),d5
		moveq	#LF,d6
		moveq	#EOF,d7
		bra	system_header_search_loop
system_header_search:
		PUSH	d5-d7
		move.b	(system_header_search_char,pc),d5
		moveq	#LF,d6
		moveq	#EOF,d7
@@:
		cmp.b	(a3)+,d6		;次の行に移動
		bne	@b
system_header_search_loop:
		move.b	(a3)+,d0
		cmp.b	d5,d0
		beq	system_header_search_ok	;見つかった(equal=not minus)
		cmp.b	d6,d0
		beq	system_header_search_loop
		cmp.b	d7,d0			;↑LF だけの行だった
		bne	@b

		moveq	#-1,d0
system_header_search_ok:
		POP	d5-d7
		rts


* システム変数値の有効範囲検査 ---------------- *

correct_system_value::
		bsr	set_scr_param
correct_system_value2:
* %dirh = 3～23
		lea	(＄dirh),a0
		moveq	#DIRH_MIN,d0
		cmp	(a0),d0
		bcc	correct_dirh
		moveq	#DIRH_MAX,d0
		cmp	(a0),d0
		bcc	@f
correct_dirh:
		move	d0,(a0)
@@:
* %regw = 8～56
		lea	(＄regw-＄dirh,a0),a0
		andi	#$fffe,(a0)		;8 の倍数にする
		moveq	#8,d0
		cmp	(a0),d0
		bcc	correct_regw
		moveq	#56,d0
		cmp	(a0),d0
		bcc	@f
correct_regw:
		move	d0,(a0)
@@:
* %6502: MPU が 68000/010 の場合は 2 は指定出来ない
		lea	(＄6502-＄regw,a0),a0
		moveq	#2,d0
		cmp	(a0),d0
		bne	@f
		cmp.b	(MpuType,opc),d0
		bls	@f
		subq	#1,(a0)			;強制的に 1 にする
@@:
* %wino = $ffff,0～64
		lea	(＄wino-＄6502,a0),a0
		moveq	#64,d0
		cmp	(a0),d0
		bcc	@f
		move	#$ffff,(a0)
@@:
* %cusr = 0～3
		moveq	#2,d2
		lea	(＄cusr-＄wino,a0),a0
		cmpi	#3,(a0)
		bls	@f
		move	d2,(a0)
@@:
* %scrs = 0～4
		lea	(＄scrs-＄cusr,a0),a0
		cmpi	#4,(a0)
		bls	@f
		move	d2,(a0)
@@:
* %fcmp = 256～4096
		lea	(＄fcmp-＄scrs,a0),a0
		move	#FCMP_MIN,d0
		cmp	(a0),d0
		bcc	correct_fcmp
.if (FCMP_MIN<<4).eq.FCMP_MAX
		lsl	#4,d0
.else
		move	#FCMP_MAX,d0
.endif		
		cmp	(a0),d0
		bcc	@f
correct_fcmp:
		move	d0,(a0)
@@:
* %cbcl = 1～3(+16)
		lea	(＄cbcl-＄fcmp,a0),a0
		moveq	#$0013,d0
		and	d0,(a0)
		bne	@f
		addq	#2,(a0)			;0 なら標準色(2)にする
@@:
* %obcl = 1～3(+16)
		and	d0,(＄obcl-＄cbcl,a0)
		rts


* 各種表示の表示行位置を計算する.

set_scr_param::
		PUSH	d0-d3/a0-a1
		lea	(＄fnmd),a0
		moveq	#32,d2
		tst	(a0)
		sne	d0
		add.b	d0,d2			;行数(31～32)

		lea	(scr_cplp_line,opc),a1
		moveq	#4,d0
		add	(＄dirh-＄fnmd,a0),d0
		move	d0,(a1)+		;scr_cplp_line

		tst	(＄cplp-＄fnmd,a0)
		beq	@f
		addq	#1,d0
@@:		move	d0,(a1)+		;scr_menu_line

		move	d0,d3
		tst	(＄menu-＄fnmd,a0)
		beq	@f
		addq	#1,d0
@@:
		move	(＄mtit-＄fnmd,a0),d1
		beq	@f			;$MINTMES と同じ行
		move	d0,d3
		subq	#1,d1
		beq	@f			;その下
		move	d2,d3
		subq	#1,d3			;画面最下行
@@:		move	d3,(a1)+		;scr_mdxt_line

		move	d0,(a1)+		;scr_consol_top
		sub	d0,d2
		move	d2,(a1)+		;scr_consol_num

		POP	d0-d3/a0-a1
		rts


scr_cplp_line::	.ds	1		;カレントパス(or $MINTMES2)の表示行
scr_menu_line:	.ds	1		;$MINTMES(or &m_mes)の表示行
scr_mdxt_line::	.ds	1		;音楽/データタイトルの表示行
scr_consol_top::.ds	1		;コンソールの先頭行
scr_consol_num:	.ds	1		;コンソールの行数

* 音楽/データタイトル表示中はコンソールの範囲を調節すること.
* %mtit 0 の場合:
*	%menu 1 なら変更しない.
*	%menu 0 なら scr_consol_top += 1
*		     scr_consol_num -= 1
* %mtit 1 の場合:
*		     scr_consol_top += 1
*		     scr_consol_num -= 1
* %mtit 2 の場合:
*		     scr_consol_num -= 1


* 各種ウィンドウの確保 ------------------------ *

window_create:
		jbsr	set_crt_mode_768x512

		moveq	#0,d1			;先頭行を消去
		move.l	#(96-1)<<16+(31-1),d2
		IOCS	_B_CONSOL
		moveq	#2,d1
		IOCS	_B_ERA_ST

		bsr	print_ttl_cplp_mmes
		jbsr	fnckey_disp_on2

		movea.l	(PATH_OPP,a6),a5

;左パスウィンドウ確保
		moveq	#WIN_LEFT,d1		;X start
		moveq	#3,d2			;Y start
		moveq	#WIN_WIDTH,d3		;X len
		move	(＄dirh),d4		;Y len
		bsr	call_WinCreate
		move	d0,(PATH_WIN_FILE,a6)
		bsr	call_WinClearAll

;右パスウィンドウ確保
		moveq	#WIN_RIGHT,d1		;X start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_FILE,a5)
		bsr	call_WinClearAll

;左ドライブ情報ウィンドウ確保
		moveq	#WIN_LEFT,d1		;X start
		move	d4,d2
		addq	#3,d2			;Y start
		moveq	#1,d4			;Y len
		bsr	call_WinCreate
		move	d0,(PATH_WIN_INFO,a6)
		bsr	call_WinClearAll

;右ドライブ情報ウィンドウ確保
		moveq	#WIN_RIGHT,d1		;X start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_INFO,a5)
		bsr	call_WinClearAll

;左パス名ウィンドウ確保
		moveq	#WIN_LEFT,d1		;X start
		moveq	#2,d2			;Y start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_PATH,a6)
		bsr	call_WinClearAll

;右パス名ウィンドウ確保
		moveq	#WIN_RIGHT,d1		;X start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_PATH,a5)
		bsr	call_WinClearAll

;左ボリュームラベルウィンドウ確保
		moveq	#WIN_LEFT,d1		;X start
		moveq	#1,d2			;Y start
		moveq	#WIN_WIDTH/2,d3		;X len
		bsr	call_WinCreate
		move	d0,(PATH_WIN_VOL,a6)
		bsr	call_WinClearAll

;右ボリュームラベルウィンドウ確保
		moveq	#WIN_RIGHT,d1		;X start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_VOL,a5)
		bsr	call_WinClearAll

;左マーク情報ウィンドウ確保
		moveq	#WIN_LEFT+WIN_WIDTH/2,d1	;X start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_MARK,a6)

;右マーク情報ウィンドウ確保
		moveq	#WIN_RIGHT+WIN_WIDTH/2,d1	;X start
		bsr	call_WinCreate
		move	d0,(PATH_WIN_MARK,a5)

		bsr	create_console_win	;コンソールウィンドウ確保
		jbra	init_exec_screen
**		rts


create_console_win:
		bsr	get_console_win_pos
		bsr	call_WinCreate
		move	d0,(exec_screen_win)
		rts

call_WinCreate:
		jmp	(WinCreate)
**		rts


* コンソールウィンドウの範囲を収得する.
* 直後に完全クリアするので、タイトル表示行の有無は影響しない.

get_console_win_pos:
		moveq	#0,d1			;x start
		moveq	#96,d3			;x length
		movem	(scr_consol_top,opc),d2/d4
		rts				;y start/length


* 各種ウィンドウの再確保 ---------------------- *
* %dirh が変更された場合に呼び出される.

window_remake:
		bsr	print_ttl_cplp_mmes

		bsr	init_window_sub		;パス/ドライブ情報ウィンドウ初期化
		movea.l	(PATH_OPP,a6),a6
		bsr	init_window_sub		;〃
		movea.l	(PATH_OPP,a6),a6

;コンソールウィンドウ初期化
		move	(exec_screen_win,pc),d0
		jsr	(WinDelete)		;今までのウィンドウを削除して
		bsr	create_console_win	;新しく作る

init_exec_screen::
		move	(exec_screen_win,pc),d0
		bsr	call_WinClearAll
		jbsr	set_scroll_narrow_console
		moveq	#0,d1
		moveq	#0,d2
		IOCS	_B_LOCATE		
		rts

init_window_sub:
;パスウィンドウ初期化
		lea	(PATH_WIN_FILE,a6),a0
		move	(a0),d0
		jsr	(WinGetCursor)
		movem	d1/d2,-(sp)

		move	(PATH_WINRL,a6),d1
		moveq	#3,d2
		moveq	#WIN_WIDTH,d3
		move	(＄dirh),d4
		bsr	init_window_sub2

**		move	(PATH_WIN_FILE,a6),d0
		movem	(sp)+,d1/d2
		jsr	(WinSetCursor)

;ドライブ情報ウィンドウ初期化
		move	(PATH_WINRL,a6),d1
		move	d4,d2			;＄dirh
		addq	#3,d2
		moveq	#1,d4
		lea	(PATH_WIN_INFO,a6),a0
		bra	init_window_sub2
**		rts

init_window_sub2:
		move	(a0),d0
		jsr	(WinDelete)		;今までのウィンドウを削除して
		jsr	(WinCreate)		;新しく作る
		move	d0,(a0)
call_WinClearAll:
		jmp	(WinClearAll)
**		rts


exec_screen_win:
		.ds	1			;下部コンソールのウィンドウ番号


* テキストパレット変更 ------------------------ *

* break	d0/d1/d2

set_text_palette:
		moveq	#-2,d2
		tst	(mion_flag)
		beq	@f
		moveq	#0,d2
		move	(＄col0),d2		;&mion 時は %col0 を設定する
@@:		moveq	#0,d1
		IOCS	_TPALET

		move	(＄col1),d2
		beq	@f
		moveq	#1,d1
		IOCS	_TPALET
@@:
		move	(＄col2),d2
		beq	@f
		moveq	#2,d1
		IOCS	_TPALET
@@:
		move	(＄col3),d2
		beq	@f
		moveq	#3,d1
		IOCS	_TPALET
@@:
		rts


* 画面最上段のタイトル行描画 ------------------ *

TTLBAR_Y:		.equ	0

;v3.10まで&title(または&mpupo + &titl0)は64バイトだったが、
;空きメモリ表示の幅が足りないので62バイトに変更。
;ただし&titleのデータ形式64バイト(&titl0は48バイト)のままで、
;末尾2バイトを無視する。

;%6502 0または2の場合
TTLBAR_TITLE_X:		.equ	0		;&title
TTLBAR_TITLE_LEN:	.equ	62

;%6502 1の場合
TTLBAR_MPUPOW_X:	.equ	0		;&mpupo, &cache
TTLBAR_MPUPOW_LEN:	.equ	16
TTLBAR_TITL0_X:		.equ	16		;&titl0
TTLBAR_TITL0_LEN:	.equ	46

;空きメモリ、日時は固定
TTLBAR_FREE_X:		.equ	62		;" 10234K "
TTLBAR_FREE_LEN:	.equ	8
TTLBAR_CLOCK_X:		.equ	70
TTLBAR_CLOCK_LEN:	.equ	26


;タイトル行、cplp行、$MINTMES行を表示する
print_ttl_cplp_mmes:
		bsr	print_titlebar
		bsr	print_cplp_line
		bra	print_mintmes_line


;タイトル行の全ての部品を描画する
print_titlebar:
		bsr	print_titlebar_ttlmpu
		bsr	print_memory_free
		bra	print_clock


;タイトル行の&titleまたは&titl0+&mpupoを表示する
print_titlebar_ttlmpu:
		move.b	(write_disable_flag,opc),d0
		bne	print_titlebar_ttlmpu_end

		bsr	set_text_palette

		moveq	#TTLBAR_TITLE_X,d2
		moveq	#TTLBAR_Y,d3
		moveq	#TTLBAR_TITLE_LEN-1,d4
		moveq	#MES_TITLE,d0		;長い方
		bsr	is_ttlbar_leftbox_enabled
		bne	@f

		pea	(＆mpu_power,pc)	;%6502 1or3ならこの後にmpu-powerを表示する
		moveq	#TTLBAR_TITL0_X,d2
		moveq	#TTLBAR_TITL0_LEN-1,d4
		moveq	#MES_TITL0,d0		;短い方(mpu-power 表示あり)
@@:
		jsr	(get_message)
		movea.l	d0,a1
		move	(＄tc_1),d1
		IOCS	_B_PUTMES
print_titlebar_ttlmpu_end:
		rts


;タイトル行の左端に情報(MPU-POWER or CACHE or PhantomX)を表示するか？
is_ttlbar_leftbox_enabled:
  move (＄6502),d1
  subq #1,d1
  beq @f
    subq #3-1,d1
  @@:
  rts


* $MINTMES(or &m_mes)表示 --------------------- *

* %menu 1～2のとき、環境変数 MINTMES の内容または &m_mes を表示する。

print_mintmes_line::
		move.b	(write_disable_flag,opc),d0
		bne	print_mintmes_line_end
		move	(＄menu),d0
		beq	print_mintmes_line_end

		PUSH	d0-d5/a1
		move	d0,d5
		lea	(Buffer),a1		
		move.l	a1,-(sp)
		clr.l	-(sp)
		pea	(str_mintmes,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bpl	@f
  
		GETMES	MES_M_MES
		movea.l	d0,a1
@@:
		move	(＄tc_4),d1
		moveq	#0,d2
		move	(scr_menu_line,opc),d3
		moveq	#96-1,d4
		IOCS	_B_PUTMES

		subq	#2,d5
		bne	@f

		lea	(mintmes_txbox,pc),a1	;%menu 2 なら枠で囲う
		lsl	#4,d3
		move	d3,(TXBOX_YSTART,a1)
		IOCS	_TXBOX
@@:
		POP	d0-d5/a1
print_mintmes_line_end:
		rts

mintmes_txbox:	.dc	$8003,0,16*2,768-1,16,$ffff

str_mintmes:	.dc.b	'MINTMES',0
		.even


copy_pathname_zdrv:
		move	(＄zdrv),d0
		beq	copy_pathname_zdrv_upper
		subq	#2,d0
		beq	copy_pathname_zdrv_lower
		bhi	copy_pathname_zdrv_remove_sysroot
*copy_pathname_zdrv_mbupper:
		move.b	#.high.'Ａ',(a2)+
		moveq	#$df,d0
		and.b	(a1)+,d0
		addi.b	#.low.('Ａ'-'A'),d0
		bra	@f
copy_pathname_zdrv_upper:
		moveq	#$df,d0
		and.b	(a1)+,d0
		bra	@f
copy_pathname_zdrv_lower:
		moveq	#$20,d0
		or.b	(a1)+,d0
@@:
		move.b	d0,(a2)+
		STRCPY	a1,a2
		subq.l	#1,a2
		rts

copy_pathname_zdrv_remove_sysroot:
		PUSH	d1-d2/a0-a1
		lea	(-_SYSROOT_MAX,sp),sp
		move.l	(twon_adrs,pc),d0
		beq	c_pn_zdrv_lower_pop

		lea	(sp),a0
		move.l	a0,-(sp)
		move	#_TWON_GETSYSR,-(sp)
		DOS	_TWON
		addq.l	#6,sp

		moveq	#'/',d2
		move.b	(a0)+,d0		;ドライブ名
		move.b	(a1)+,d1		;
		eor.b	d0,d1
		beq	c_pn_zdrv_loop
		cmpi.b	#$20,d1			;大文字小文字同一視
		bne	c_pn_zdrv_lower_pop
c_pn_zdrv_loop:
		move.b	(a0)+,d0
		beq	c_pn_zdrv_remove	;SYSROOT 終了
		cmp.b	d2,d0
		bne	@f
		moveq	#'\',d0
@@:		move.b	(a1)+,d1
		cmp.b	d2,d1
		bne	@f
		moveq	#'\',d1
@@:		cmp.b	d0,d1
		beq	c_pn_zdrv_loop
c_pn_zdrv_lower_pop:
		lea	(_SYSROOT_MAX,sp),sp
		POP	d1-d2/a0-a1
		bra	copy_pathname_zdrv_lower
c_pn_zdrv_remove:
		cmp.b	(a1),d2
		beq	@f
		cmpi.b	#'\',(a1)
		bne	c_pn_zdrv_lower_pop	;パス名の方が終わってなかった
@@:
		STRCPY	a1,a2
		subq.l	#1,a2
		lea	(_SYSROOT_MAX,sp),sp
		POP	d1-d2/a0-a1
print_getsec_end:
print_cplp_line_end:
		rts


* &getsec 結果表示 ---------------------------- *

print_getsec:
		lea	(getsec_flag),a0
		tst.b	(a0)
		beq.s	print_getsec_end

		clr.b	(a0)
		IOCS	_ONTIME
		move.l	d0,(時間_実行後)

		tst	(＄cplp)
		bne	print_cplp_line
		moveq	#0,d0
		jmp	(print_runtime)
**		rts


* cplp 行表示 --------------------------------- *

print_cplp_line::
		tst	(＄cplp)
		beq.s	print_cplp_line_end
		move.b	(write_disable_flag,opc),d0
		bne.s	print_cplp_line_end

		lea	(-256,sp),sp

		pea	(sp)
		clr.l	-(sp)
		pea	(str_mintmes2,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	@f			;$MINTMES2 があればそれを表示する

		lea	(sp),a2
		move.b	#SPACE,(a2)+
		lea	(cur_dir_buf),a1
		bsr	copy_pathname_zdrv
@@:
		move	(＄tc_3),d1
		move	(＄code),d2		;X
		beq	@f
		moveq	#16,d2			;左下用に開ける
@@:
		move	(scr_cplp_line,opc),d3
		moveq	#(96-16)-1,d4		;右下用に開ける
		cmpi	#2,(＄6502)
		beq	@f
		moveq	#(96-19)-1,d4		;〃
		tst	(＄6809)
		bne	@f
		moveq	#96-1,d4
@@:
		sub	d2,d4			;左下用に開ける
		lea	(sp),a1
		IOCS	_B_PUTMES
		lea	(256,sp),sp

**		cmpi	#2,(＄6502)
**		beq	@f
		jbsr	interrupt_window_print
**@@:
		tst	(＄code)
		beq	print_cplp_line_end

* 実行時間・終了コード
		lea	(-12,sp),sp

		moveq	#YELLOW+EMPHASIS,d1
		moveq	#0,d2			;X
		move	(scr_cplp_line,opc),d3	;Y
		moveq	#.sizeof.(' X')-1,d4
		lea	(spc_x,pc),a1
		IOCS	_B_PUTMES

		moveq	#0,d0
		move	(＠exitcode),d0
		moveq	#.sizeof.('65535'),d1
		lea	(sp),a0
		FPACK	__IUSING
		move.l	#('0'.xor.SPACE)*$01010101,d0
		or.l	d0,(sp)			;ゼロ詰めにする
		moveq	#WHITE,d1
		moveq	#.sizeof.('65535')-1,d4
		lea	(sp),a1
		IOCS	_B_PUTMES

		moveq	#WHITE+EMPHASIS,d1
		moveq	#.sizeof.('/')-1,d4
		lea	(str_dotmint,pc),a1	;'/'
		IOCS	_B_PUTMES

		move.l	(時間_実行後),d0
		sub.l	(時間_実行前),d0
		bcc	@f
		addi.l	#24*60*60*100,d0
@@:
		move.l	#999999,d1
		cmp.l	d1,d0
		bls	@f
		move.l	d1,d0			;6 桁に制限
@@:
		moveq	#6,d1
		lea	(sp),a0
		FPACK	__IUSING
		subq.l	#2,a0
		move.l	(a0),d0			;$3x3x00??
		lsr.l	#8,d0			;$003x3x00
		move.l	d0,(a0)+
		clr.b	-(a0)
		moveq	#'0'.xor.SPACE,d0
@@:		or.b	d0,-(a0)		;ゼロ詰めにする
		dbra	d1,@b
		move.b	#'.',(4,a0)
		moveq	#WHITE,d1
		moveq	#8-1,d4
		lea	(sp),a1
		IOCS	_B_PUTMES		;実行時間

		lea	(code_txbox,pc),a1
		lsl	#4,d3
		move	d3,(TXBOX_YSTART,a1)
		IOCS	_TXBOX

		lea	(12,sp),sp
print_exec_time_end:
		rts


code_txbox:	.dc	$8003,0,0,8*16,16,$ffff
spc_x:		.dc.b	' X'
		.even


* 空きメモリ容量表示 -------------------------- *

print_memory_free::
		move.b	(write_disable_flag,opc),d0
		bne	print_memory_free_end

		move.l	#$00ffffff,-(sp)
		DOS	_MALLOC
		and.l	(sp),d0
		lsr.l	#8,d0
		lsr.l	#2,d0

		subq.l	#4,sp
		lea	(sp),a0
		moveq	#6,d1
		FPACK	__IUSING
		move	#'K'<<8,(6,sp)		;' 10234K',0

		move	(＄tc_1),d1
		moveq	#TTLBAR_FREE_X,d2
		moveq	#TTLBAR_Y,d3
		moveq	#TTLBAR_FREE_LEN-1,d4	;バッファ上の文字列は7桁だが
		lea	(sp),a1			;足りない1桁分は_B_PUTMESが補完して
		IOCS	_B_PUTMES		;空白が表示される
		addq.l	#8,sp
print_memory_free_end:
		rts


* スクロール範囲設定 : 全画面 ----------------- *

set_scroll_full_console::
		move.l	(execute_ptr,pc),d0
		bne	set_scroll_f_end

		pea	(0<<16+31)		;start/length
		move.l	#14<<16+$ffff,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		subq.l	#3,d0
		bne	@f
		addq.l	#1,(sp)
@@:
		move	#15,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp
set_scroll_f_end:
		rts


* スクロール範囲設定 : 一部 ------------------- *

set_scroll_narrow_console::
		PUSH	d0-d1
		move.b	(write_disable_flag,opc),d0
		bne	set_scroll_n_end

		jbsr	SaveCursor

		move.l	(scr_consol_top,opc),-(sp)
		tst.b	(music_data_title_flag)
		beq	@f			;音楽/データタイトル無し
		move	(＄mtit),d1
		bne	set_scroll_mdxt
		tst	(＄menu)		;%mtit 0 かつ %menu 1 なら、$MINTMES
		bne	@f			;と同じ行に表示するので減らない
set_scroll_mdxt:
		subq.l	#1,(sp)			;行数 -= 1
		subq	#2,d1
		bcc	@f			;最下行に表示している場合
		addq	#1,(sp)			;先頭行 += 1
@@:
		move	#15,-(sp)
		DOS	_CONCTRL		;スクロール範囲設定
		addq.l	#6,sp

		jbsr	RestoreCursor
set_scroll_n_end:
		POP	d0-d1
		rts


*************************************************
*		&drive-check			*
*************************************************

.if 0
drive_count:	.ds	1			;認識できたドライブ個数
drive_no_flags:	.ds.b	26
.endif

* 以前はドライブ数と全ドライブの論理ドライブ番号を
* バッファに書き込んでいたが、&change-drive で使わ
* なくなったので、現在は DISK2HD がどのドライブか
* だけを調べている.

＆drive_check::
		bsr	mount_check
drive_check:
		PUSH	d1-d2/a0-a1
		moveq	#26,d1			;26,25,...,2,1 と逆順に調べる
		moveq	#0,d2
.ifdef drive_count
		clr	(drive_count)
		lea	(drive_no_flags+26),a1
.endif
		TO_SUPER
drive_check_loop1:
.ifdef drive_count
		st	-(a1)			;$ff=未使用ドライブ
		jbsr	dos_drvctrl_d1_org
		tst.l	d0
		bmi	@f
		move.b	d1,(a1)			;ドライブ番号(1～26)
		addq	#1,(drive_count)	;ドライブ数++
@@:
.endif
		jbsr	dos_getdpb_org
		tst.l	d0
		bmi	@f

		movea.l	(DpbBuffer+DPB_DevHed),a0	;デバイスドライバへのポインタ
		lea	(14,a0),a0		;デバイス名
		move.l	(a0)+,-(sp)
		clr.b	(sp)
		cmpi.l	#'DIS',(sp)+		;DISK2HD ならフラグを立てる
		bne	@f
		cmpi.l	#'K2HD',(a0)+
		bne	@f
		bset	d1,d2			;このドライブは FDD
@@:
		subq	#1,d1
		bhi	drive_check_loop1

		move.l	d2,(disk2hd_flag)	;DISK2HD のデバイス
		TO_USER
		POP	d1-d2/a0-a1
		rts


* メインループ -------------------------------- *

main_loop:
		jbsr	iocs_b_keyinp_ex
		bne	main_keyinp		;キー入力あり

* キー入力なし
		bsr	check_cursor_up_down_keypush
		bsr	joyget
		bsr	update_periodic_display
		jsr	(auto_screen_saver)
		jsr	(palet_illumination)
		bsr	fnckey_disp_on
		bsr	crtc_mode_check
		bsr	media_eject_insert_check
		jsr	(describe_key_opt)

		DOS	_CHANGE_PR
		bra	main_loop

* キー入力あり
main_keyinp:
		bsr	check_cursor_up_down_keyinp

		move.l	d0,-(sp)
		jsr	(break_check0)		;ブレークキーの状態を記憶しておく
		lsl	(init_sc_flag)
		bcc	@f			;&prefix が使用されていたら
		jbsr	＆clear_exec_screen	;コンソールを消去する
@@:		move.l	(sp)+,d0

		lsl	#8,d0			;キー定義を実行
**		move.b	#%0000_0000,d0
		jsr	(execute_quick_no)

* チェイン終了後の処理
		bsr	iocs_b_keyinp_ex_only	;key flush
		bsr	dos_kflush

		jsr	(resume_stops)		;&stop-～ 系の復帰
		jsr	(mintarc_dispose_ache)
		jbsr	local_path_pop

		clr.b	(debug_flag)
		clr.b	(disable_clock_flag)
		jbsr	write_disable_pop
		jsr	(init_ss_timer)
		bsr	print_getsec
		jbsr	fep_disable
		bsr	print_memory_free
		bsr	update_periodic_display

		bra	main_loop

dos_kflush::
		move	#2,-(sp)
		DOS	_KFLUSH
		addq.l	#2,sp
		rts


* キー入力待ちループ中に実行するルーチン ------ *

* JOYSTICK による操作
joyget:
		move	(＄joys),d1
		ble	joyget_end
		lea	(joystick_cunter,pc),a0
		subq	#1,(a0)
		bcc	joyget_end

		move	#30,(a0)

		subq	#1,d1
		IOCS	_JOYGET			;ジョイスティックポートのデータを読み込む

		lsr.b	#1,d0
		bcc	＆cursor_up		;bit 0
		lsr.b	#1,d0
		bcc	＆cursor_down		;bit 1
		lsr.b	#1,d0
		bcc	＆cursor_left		;bit 2
		lsr.b	#1,d0
		bcc	＆cursor_right		;bit 3
		lsr.b	#2,d0
		bcc	＆ext_exec_or_chdir	;bit 5
		lsr.b	#1,d0
		bcc	＆mark			;bit 6
joyget_end:
media_ej_ins_chk_skip:
		rts


joystick_cunter:
		.dc	30
media_e_i_time:
		.dc.l	0


* メディアが排出/挿入されたらリロード --------- *

media_eject_insert_check:
		moveq	#0,d0
		move	(＄moct),d0
		beq.s	media_ej_ins_chk_skip

		lea	(media_e_i_time,pc),a0
		jsr	(check_timer)
		bne.s	media_ej_ins_chk_skip

* 反対側をリロードする場合 cplp 行の書き換えは不要だが、
* %cplp 0 にしてこれを省略すると左右同パスで排出した時に
* ルートに書き換わらないのであえて書き換えを許している.
**		lea	(＄cplp),a0
**		move	(a0),-(sp)
**		clr	(a0)
		movea.l	(PATH_OPP,a6),a6
		bsr	media_ej_ins_chk_sub
		movea.l	(PATH_OPP,a6),a6
**		move	(sp)+,(＄cplp)
		move	d0,d7
		bne	@f
		jbsr	ReverseCursorBarOpp
@@:
		bsr	media_ej_ins_chk_sub
		bne	@f
		jbsr	ReverseCursorBar
		tst	d7			;反対側のみリロードした場合
		bne	@f			;カレントが反対側になっているので
		jbsr	chdir_routin		;ここでカーソル側に戻す
@@:
		lea	(media_e_i_time,pc),a0
		jmp	(init_timer)
**		rts


* メディア排出挿入検査下請け
* out	d0.l	0:リロードした -1:リロードしなかった
*	ccr	<tst.l d0> の結果

media_ej_ins_chk_sub:
		bsr	is_disk2hd_drive
		beq	@f

* FDD の場合は DOS _DRVCTRL を使うと LED が点灯して
* しまうので、IOCS ワークが変化していないか見る.
		pea	(compare_fdaxsflag,opc)
		DOS	_SUPER_JSR
		move.l	d0,(sp)+
		beq	media_ej_ins_chk_sub_end
@@:
		move	(PATH_DRIVENO,a6),d1
**		jbsr	dos_drvctrl_d1_org
		jbsr	dos_drvctrl_d1
		andi.b	#1<<DRV_INSERT+1<<DRV_NOTREADY,d0
		tst.b	(PATH_NODISK,a6)
		beq	@f

		subq.b	#1<<DRV_INSERT,d0	;今まで未挿入
		beq	media_ej_ins_chk_sub_reload	;挿入された
media_ej_ins_chk_sub_end:
		moveq	#-1,d0			;リロードなし
		rts
@@:
		subq.b	#1<<DRV_INSERT,d0	;今まで挿入
		beq	media_ej_ins_chk_sub_end	;まだ挿入されている

		jsr	(quit_mintarc_all)		;排出された
media_ej_ins_chk_sub_reload:
		jbsr	directory_write_routin

		moveq	#0,d0			;リロードを行った
		rts


*************************************************
*		&clear-text			*
*************************************************

call_pop_text:
		jmp	(＆pop_text)
**		rts

＆clear_text::
		bsr	call_pop_text
*		moveq	#%0011,d0
		moveq	#%1111,d0		;&clear-and-redraw より強力に初期化する
		bsr	clear_tvram
		bra	clear_and_redraw2


*************************************************
*		&crt-write-disable		*
*************************************************

disable_write_and_clock_flag:  ;tst.wで一括テスト用
write_disable_flag:: .ds.b 1
disable_clock_flag:: .ds.b 1
.even

＆crt_write_disable::
		lea	(write_disable_flag,opc),a0
		st	(a0)
@@:		rts

write_disable_pop:
		lea	(write_disable_flag,opc),a0
		tst.b	(a0)
		beq.s	@b

		clr.b	(a0)
		bra	＆clear_and_redraw
**		rts


*************************************************
*		&clear-and-redraw		*
*************************************************

＆clear_and_redraw::
		bsr	call_pop_text
clear_and_redraw2:
		moveq	#-1,d1
		IOCS	$93			;move (VC_R2),d0
		moveq	#T_ON,d1
		or	d0,d1
		IOCS	$93			;move d1,(VC_R2)

		bsr	print_ttl_cplp_mmes
		jbsr	fnckey_disp_on2

		bsr	clear_and_redraw_sub
		bra	＆clear_exec_screen
**		rts


*************************************************
*		&clear-exec-screen		*
*************************************************

＆clear_exec_screen::
		jbsr	init_exec_screen
		jbsr	print_cplp_line
		jbsr	print_mintmes_line
		jbsr	interrupt_window_print
		jmp	(print_music_title)
**		rts


* 以下、テキストクリア系サブルーチン

clear_and_redraw_sub:
		jbsr	pr_scr_dir_opp
		jbra	pr_scr_dir_cur
**		rts


* テキスト画面クリア
* in	d0.w	対象プレーン(bit3～0)

clear_tvram::
		PUSH	d0-d3/a0-a1
		move	d0,d3			;IOCS _TXRASCPY用
		pea	(clear_tvram_clr_rasblk,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		moveq	#$00_01,d1
		move	#256,d2
		IOCS	_TXRASCPY
		POP	d0-d3/a0-a1
		rts

clear_tvram_clr_rasblk:
		lea	(CRTC_R21),a0
		lea	(TVRAM_P0),a1
		lsl	#4,d0
		ori	#$01_00,d0		;同時アクセス設定
		move	(a0),-(sp)
		move	d0,(a0)

		moveq	#0,d1
		move	#(128*4)/16-1,d0
@@:
		move.l	d1,(a1)+		;1ラスタブロックを消去
		move.l	d1,(a1)+
		move.l	d1,(a1)+
		move.l	d1,(a1)+
		dbra	d0,@b
		move	(sp)+,(a0)
		rts


*************************************************
*		&toggle-file-information-mode	*
*************************************************

＆toggle_file_information_mode::
		lea	(＄f_1k),a0
		moveq	#1,d0
		and	d0,(a0)
		eor	d0,(a0)
		bra	clear_and_redraw_sub
**		rts


* 画面描画 ------------------------------------ *
* in	d0.b	フラグ
*		bit0=1:カーソル側リロード
*		bit1=1:反対側リロード
*		bit2=1:カーソル側再表示
*		bit3=1:反対側再表示
*		bit6=1:コンソール初期化(&clear-exec-screen)
*		bit7=1:全画面表示
*		d0.b = $00 の場合は割り込みと音楽タイトルの
*		表示を更新する.
* break	d0

print_screen::
		PUSH	d1-d7/a0-a5
		move.b	d0,-(sp)
		bgt	pr_scr_skip7
		bmi	pr_scr_all

* 割り込み/音楽タイトル更新
		jbsr	interrupt_window_print
		jsr	(print_music_title)
		bra	pr_scr_end
* 全画面表示
pr_scr_all:
		ori.b	#%1100_1100,(sp)	;他の部分も表示する

		bsr	print_ttl_cplp_mmes
		jbsr	fnckey_disp_on2
pr_scr_skip7:
		btst	#6,(sp)
		beq	pr_scr_skip6

* コンソール初期化
		jbsr	＆clear_exec_screen
pr_scr_skip6:

* 左右同パスで片方がリロードなら、もう一方もリロードする
		moveq	#%11,d0
		and.b	(sp),d0
		beq	pr_scr_skip10
		subq	#%11,d0
		beq	pr_scr_skip10
		movea.l	(PATH_OPP,a6),a1
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_MARC_FLAG,a1),d0
		bne	pr_scr_skip10

		addq.l	#PATH_DIRNAME,a1
		lea	(PATH_DIRNAME,a6),a2
		jbsr	twon_getopt
		add.l	d0,d0
		bmi	1f			;+C
		jsr	(stricmp_a1_a2)
		bra	@f
1:
		jsr	(strcmp_a1_a2)
@@:		bne	pr_scr_skip10
		ori.b	#%11,(sp)		;左右同パスなら両方ともリロード
pr_scr_skip10:
		btst	#1,(sp)
		beq	pr_scr_skip1

* 反対側リロード
		jbsr	directory_write_routin_opp
		jbsr	ReverseCursorBarOpp
		bra	pr_scr_skip3
pr_scr_skip1:
		btst	#3,(sp)
		beq	pr_scr_skip3

* 反対側表示
		bsr	pr_scr_dir_opp
pr_scr_skip3:
		btst	#0,(sp)
		beq	pr_scr_skip0

* カーソル側リロード
		jbsr	directory_write_routin
		jbsr	ReverseCursorBar
		bra	pr_scr_skip2
pr_scr_skip0:
		btst	#2,(sp)
		beq	pr_scr_skip2

* カーソル側表示
		bsr	pr_scr_dir_cur
pr_scr_skip2:

pr_scr_end:
		move.b	(sp)+,d0
		POP	d1-d7/a0-a5
		rts


* ディレクトリ再描画 -------------------------- *
* break	d0-d7/a0-a5 ?

* 反対側
pr_scr_dir_opp:
		movea.l	(PATH_OPP,a6),a6
		bsr	pr_scr_dir_sub
		movea.l	(PATH_OPP,a6),a6
		jbra	ReverseCursorBarOpp
**		rts

* カーソル側
pr_scr_dir_cur:
		bsr	pr_scr_dir_sub
		jbra	ReverseCursorBar
**		rts

pr_scr_dir_sub:
		tst.b	(PATH_NODISK,a6)
		jbne	print_not_insert_disk

		jbsr	print_directory
		jbra	print_mark_information
**


* ディレクトリ表示 ---------------------------- *

print_directory::
		jbsr	print_volume_label
		bsr	print_drive_path
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinClearAll)
		jbsr	print_file_list
		jbra	print_drive_info
**		rts


* 一定時間ごとの表示更新 ---------------------- *

.offset 0
CLOCK_DATE: .ds.l 1
CLOCK_TIME: .ds.l 1
CLOCK_6502_CALS:
CLOCK_6502: .ds 1
CLOCK_CALS: .ds 1
CLOCK_9C4: .ds 1
CLOCK_FIRST: .ds.b 1
CLOCK_IS_ODD: .ds.b 1
.even
sizeof_CLOCK_VALUE:
.text

update_periodic_display::
  PUSH d0-d2/a0
  move (disable_write_and_clock_flag,opc),d0
  bne 9f
    lea (clock_value),a0
    move.l (＄6502-clock_value,a0),d0  ;move.w + swap
    move (＄cals-clock_value,a0),d0
    cmp.l (CLOCK_6502_CALS,a0),d0
    beq @f
      PUSH d3-d7/a1-a6
      bsr print_titlebar  ;レイアウトが変わる場合はタイトル行全体を再描画
      POP d3-d7/a1-a6
      bra 9f
    @@:
    bsr get_datetime
    cmp.l (CLOCK_DATE,a0),d1
    bne 5f
    cmp.l (CLOCK_TIME,a0),d2
    bne 5f
      ;前回表示からまだ1秒経っていない
      move (＄cals-clock_value,a0),d0
      subq.b #1,d0
      bcs 9f  ;%cals 0
      bhi 5f  ;%cals 2なら常に更新
        bsr cals1_blink
      bra 9f
    5:
      ;前回表示から1秒経過した(ただし初回は1秒未満の場合もある)
      bsr update_clock

      not.b (CLOCK_IS_ODD,a0)  ;毎秒更新だと頻繁すぎるように感じたので2分周して2秒ごと
      bne @f
        bsr update_phantomx_soctmp
      @@:
  9:
  POP d0-d2/a0
  rts


* 時計表示 ------------------------------------ *

print_clock:
  moveq #-1,d0
  bra @f
update_clock:
  moveq #0,d0
@@:
  PUSH d1-d7/a0-a5
  move (disable_write_and_clock_flag,opc),d1
  bne 9f
    link a6,#-32
    lea (clock_value),a0
    move.b d0,(CLOCK_FIRST,a0)

    bsr get_datetime
    movem.l d1-d2,(CLOCK_DATE,a0)
    move.l (＄6502-clock_value,a0),d0  ;move.w + swap
    move (＄cals-clock_value,a0),d0
    move.l d0,(CLOCK_6502_CALS,a0)
    lea (sp),a1
    bsr make_clock_str

    moveq #TTLBAR_CLOCK_X,d2
    moveq #TTLBAR_CLOCK_LEN-1,d4
    lea (sp),a1
    bsr putmes_clock
    unlk a6
  9:
  POP d1-d7/a0-a5
  rts

get_datetime:
  IOCS _DATEGET
  @@:
    move.l d0,d1
    IOCS _TIMEGET
    move.l d0,d2
    IOCS _DATEGET
  cmp.l d0,d1  ;_DATEGETと_TIMEGETの間に日付が変わった可能性があるので
  bne @b       ;取得し直す
  rts

putmes_clock:
  move (＄tc_1),d1
  moveq #TTLBAR_Y,d3
  IOCS _B_PUTMES
  rts


;          01234567890123456789012345
;%cals 0  "1993-12-04 Sat. 07:31:13  "
;%cals 1  "Sat Dec 04 07:31 JST 1993 "
;%cals 2  "@ex/bu/st= 1234/1234/1234 "

;in d0.w  ＄calsの値
;   d1.l  日付(BCD)
;   d2.l  時刻(BCD)
;   a0.l  clock_value
;   a1.l  文字列バッファ
make_clock_str:
  subq.b #1,d0
  beq make_clock_en      ;%cals 1
  bhi make_clock_status  ;%cals 2

;make_clock_ja:          ;%cals 0
  move d0,-(sp)
  bsr make_clock_sub
  move.b (sp)+,d0  ;%calsの上位バイト
  beq @f
    move.b d0,(.sizeof.('1993'),a1)  ;区切り記号を変更する
    move.b d0,(.sizeof.('1993-12'),a1)
  @@:
  rts


make_clock_en:
  link a6,#-32
  lea (a1),a2

  bsr get_fdmotoroff_count
  move d0,(CLOCK_9C4,a0)

  lea (sp),a1  ;仮バッファに%cals 0形式で作成してから加工する
  bsr make_clock_sub

  moveq #SPACE,d2
  lea (11,a1),a0
  bsr make_clock_cp3  ;曜日

  GETMES MES_MONTH
  movea.l d0,a0
  cmpi.b #'0',(5,a1)
  beq @f
    lea (10*3,a0),a0  ;10～12月
  @@:
  moveq #$f,d0
  and.b (6,a1),d0
  adda d0,a0
  add d0,d0
  lea (-3,a0,d0.w),a0  ;a0 += d0*3 - 3
  bsr make_clock_cp3   ;月

  move (8,a1),(a2)+  ;日
  move.b d2,(a2)+

  lea (16,a1),a0
  bsr make_clock_cp5  ;時:分

  lea (mes_jst,pc),a0
  bsr make_clock_cp3  ;JST

  lea (a1),a0
  bsr make_clock_cp4  ;西暦
  clr.b -(a2)

  unlk a6
  rts

make_clock_cp5:
  move.b (a0)+,(a2)+
make_clock_cp4:
  move.b (a0)+,(a2)+
make_clock_cp3:
  move.b (a0)+,(a2)+
  move.b (a0)+,(a2)+
  move.b (a0)+,(a2)+
  move.b d2,(a2)+  ;SPACE
  rts

get_fdmotoroff_count:
  lea ($9c4).w,a1  ;FDモーター停止タイマー 減算カウンタ
  IOCS _B_WPEEK
  rts

;秒更新から0.5秒に':'を' 'に書き換える
cals1_blink:
  move.l a1,-(sp)

  ;初回の時計描画時は「あと何ミリ秒で秒が進むか」がわからないので、
  ;タイミングによっては0.5秒経過して' 'に書き換えたのち、僅かな時間で
  ;秒が進むことがある。その場合':'がちらついて目障りに感じられる。
  ;対策として秒が進むまで' 'に書き換えない。
  ;ただし最長で約1.49秒':'が表示されたままになる。
  tst.b (CLOCK_FIRST,a0)
  bne 9f

  bsr get_fdmotoroff_count
  move (CLOCK_9C4,a0),d1
  sub d0,d1  ;経過時間(1/00sec)
  bcc @f
    addi #200,d1
  @@:
  cmpi #50,d1
  bcs 9f
    moveq #TTLBAR_CLOCK_X+.sizeof.('Sat Dec 04 07'),d2
    moveq #1-1,d4
    lea (cals1_nul,pc),a1  ;空白で上書きする
    bsr putmes_clock
  9:
  move.l (sp)+,a1
  rts

mes_jst:   .dc.b 'JST'
cals1_nul: .dc.b 0
.even


;in  d1.l  日付(BCD)
;    d2.l  時刻(BCD)
;    a1.l  文字列バッファ
;break d0-d3/a0
make_clock_sub:
  move.l a1,-(sp)

  GETMES MES_Y_ENG
  movea.l d0,a0

  IOCS _DATEBIN
  move.l d0,d1
  rol.l #4,d1  ;$yyym_mddw
  moveq #7,d0
  and d1,d0  ;曜日カウンタ
  eor d0,d1
  addq #1,d1  ;文字列形式を1('yyyy-mm-dd')にする

  lsl #2,d0
  adda d0,a0  ;曜日(4バイト単位)

  ror.l #4,d1  ;$1yyy_mmdd
  @@:
    IOCS _DATEASC
    tst.l d0
    beq @f
      move.l #1<<28+1980<<16+1<<8+1,d1  ;異常な日付をごまかす
      bra @b
  @@:
  move.b  #SPACE,(a1)+

  .rept .sizeof.('Sun.')
    move.b (a0)+,(a1)+
  .endm
  move.b #SPACE,(a1)+

  move.l d2,d1
  IOCS _TIMEBIN
  move.l d0,d1
  IOCS _TIMEASC
  ori.b #'0'.xor.SPACE,(-.sizeof.('12:00:00'),a1) ;時刻の十の位をゼロ詰めする

  movea.l (sp)+,a1
  rts


make_clock_status:
  lea (make_clock_st_str,pc),a0
  STRCPY a0,a1
  subq.l #1,a1

  lea (＠exitcode),a0
  bsr make_clock_st_sub
  bsr make_clock_st_sub
  bsr make_clock_st_sub

  clr.b -(a1)  ;末尾の'/'を消す
  rts

make_clock_st_sub:
  move (a0)+,d0
  moveq #4-1,d2
  @@:
    rol #4,d0
    moveq #$f,d1
    and.b d0,d1
    move.b (hextable,pc,d1.w),(a1)+
  dbra d2,@b
  move.b #'/',(a1)+
crtc_mode_check_end:
  rts


hextable:: .dc.b '0123456789abcdef'
make_clock_st_str: .dc.b '@ex/bu/st= ',0
.even


* 画面モード自動補正 -------------------------- *

crtc_mode_check::
		tst	(＄agmd)
		bne.s	crtc_mode_check_end

		moveq	#100,d0
		lea	(crtc_counter,pc),a0
		jsr	(check_timer)
		bne.s	crtc_mode_check_end

		bsr	set_crt_mode_768x512
		beq.s	crtc_mode_check_end

		jbra	＆clear_and_redraw
**		rts

crtc_counter:	.ds.l	1


* 画面初期化下請け
* out	d0.l	0:初期化しなかった 1:初期化した
*	ccr	<tst.l d0> の結果

set_crt_mode_768x512::
		pea	(set_crt_mode_768x512_sub,pc)
		DOS	_SUPER_JSR
		move.l	d0,(sp)+
		rts
set_crt_mode_768x512_sub:
		PUSH	d1/a0-a1
		cmpi.b	#$16,(CRTC_R20l)
		bne	set_crt_mode_init
		move.b	(CRTMOD),d0
		move.l	#1<<24+1<<20+1<<16,d1
		btst	d0,d1
		beq	set_crt_mode_init

		moveq	#0,d0
set_crt_mode_end:
		POP	d1/a0-a1
		rts
set_crt_mode_init:
		lea	(GPARH_PAL),a1
		move	(VC_R2-GPARH_PAL,a1),-(sp)
		move	(VC_R0-GPARH_PAL,a1),-(sp)
		move.b	(CRTC_R20h-GPARH_PAL,a1),-(sp)

		moveq	#256/4-1,d0
@@:		move.l	(a1)+,-(sp)		;パレットを一時退避
		move.l	(a1)+,-(sp)
		dbra	d0,@b

		move.l	#16<<16+0,-(sp)		;768x512、グラフィックなし
		DOS	_CONCTRL
		addq.l	#4,sp

		moveq	#G_ON,d0
		and	(VC_R2),d0		;画面初期化後もグラフィックがオンなら
		bne	set_crt_mode_init_end	;そのままにしておく

		lea	(sp),a0			;グラフィック周りを復帰する
		moveq	#256/4-1,d0
@@:		move.l	(a0)+,-(a1)
		move.l	(a0)+,-(a1)
		dbra	d0,@b

		move.b	(a0)+,(CRTC_R20h-GPARH_PAL,a1)
		addq.l	#1,a0
		move	(a0),(VC_R0-GPARH_PAL,a1)
		subq	#1,(a0)+		;細工…
		bne	@f			;
		jsr	(center_256_graphic)	;
@@:
		move	(VC_R2-GPARH_PAL,a1),d0
		andi	#G_HALF_ON,(a0)
		andi	#.not.G_HALF_ON,d0
		or	(a0),d0
		move	d0,(VC_R2-GPARH_PAL,a1)
set_crt_mode_init_end:
		lea	(256*2+6,sp),sp
		moveq	#1,d0
		bra	set_crt_mode_end

.if 0
set_crt_mode_768x512::
*		move.l	#16<<16+$ffff,-(sp)
*		DOS	_CONCTRL
*		addq.l	#4,sp
*		subq.l	#2,d0
*		bcc	@f

		lea	(CRTC_R20l),a1
		IOCS	_B_BPEEK
		cmpi.b	#$16,d0
		bne	@f
		moveq	#-1,d1
		IOCS	_CRTMOD
		move.l	#1<<24+1<<20+1<<16,d1
		btst	d0,d1
		bne	1f			;768x512、64K、256、16色
@@:
		lea	(VC_R2-(CRTC_R20l+1),a1),a1
		IOCS	_B_WPEEK
		andi	#G_HALF_ON,d0
		subq.l	#2,a1
		move	d0,d1			;グラフィック表示モードを保存

		move.l	#16<<16+0,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp

		IOCS	_B_WPEEK
		andi	#.not.G_HALF_ON,d0
		subq.l	#2,a1
		or	d0,d1
		IOCS	_B_WPOKE		;グラフィック表示モードを復帰

		moveq	#1,d0
		rts
1:
		moveq	#0,d0
		rts
.endif

.if 0
set_crt_mode_768x512::
		pea	(set_crt_mode_768x512_sub,pc)
		DOS	_SUPER_JSR
		move.l	d0,(sp)+
		rts
set_crt_mode_768x512_sub:
		cmpi.b	#$16,(CRTC_R20l)
		bne	set_crt_mode_init
		move.b	(CRTMOD),d0
		subi.b	#16,d0			;768x512、16色
		beq	@f
		subq.b	#20-16,d0		;〃	、256色
		beq	@f
		subq.b	#24-20,d0		;〃	、64K色
		bne	set_crt_mode_init
@@:
		moveq	#0,d0			;初期化不要
		rts
set_crt_mode_init:
		PUSH	a0-a1
		moveq	#256/2-1,d0
		lea	(GPARH_PAL),a1
@@:		move.l	(a1)+,-(sp)		;パレットを一時退避
		dbra	d0,@b

		move.l	#16<<16+0,-(sp)		;768x512、グラフィックなし
		DOS	_CONCTRL
		addq.l	#4,sp

		moveq	#G_ON,d0
		and	(VC_R2),d0		;画面初期化後もグラフィックがオンなら
		bne	set_crt_mode_init_end	;パレットはそのままにしておく

		lea	(sp),a0			;オフになっていたら退避したパレットを
		moveq	#256/2-1,d0		;書き込む(パレット破壊対策)
@@:		move.l	(a0)+,-(a1)
		dbra	d0,@b
set_crt_mode_init_end:
		lea	(256*2,sp),sp
		POP	a0-a1
		moveq	#1,d0
		rts
.endif


*************************************************
*		&cursor-up			*
*************************************************

＆cursor_up::
		lea	(cursor_up_sub,pc),a3
		bra.s	cursor_up_down


*************************************************
*		&cursor-down			*
*************************************************

＆cursor_down::
		lea	(cursor_down_sub,pc),a3
cursor_up_down:
		tst.b	(PATH_NODISK,a6)
		bmi	cursor_up_down_end	;未挿入時は正常終了とする

		jsr	(a3)			;cursor_{up,down}_sub
		beq	cursor_up_down_error

		lea	(cursor_up_down_count,pc),a0
		addq	#1,(a0)
		bne	@f
		subq	#1,(a0)			;65535
@@:		move	(＄hspd),d7
		beq	cursor_up_down_end	;高速カーソル移動未使用
		cmp	(a0),d7
		bhi	cursor_up_down_end

		add	(＄hsp！),d7
		bcc	cursor_up_down_loop
		moveq	#-1,d7			;65535
cursor_up_down_loop:
		bsr	cursor_up_down_wait
		bsr	check_cursor_up_down_keypush
		beq	cursor_up_down_end

		jsr	(a3)			;高速移動中
		beq	cursor_up_down_error

		addq	#1,(a0)
		bne	@f
		subq	#1,(a0)			;65535
@@:		cmp	(a0),d7
		bhi	cursor_up_down_loop
cursor_up_down_loop2:
		bsr	check_cursor_up_down_keypush
		beq	cursor_up_down_end

		jsr	(a3)			;超高速移動中
		bne	cursor_up_down_loop2
cursor_up_down_error:
		bra	set_status_0
**		rts
cursor_up_down_end:
		bra	set_status_1
**		rts


* カーソル移動キーの入力以外だったら、今までの移動行数を初期化.
* in	d0.b	キーコード

check_cursor_up_down_keyinp:
		move.l	a0,-(sp)
		lea	(cursor_up_down_key,pc),a0
		cmp.b	(a0),d0
		beq	@f
		move.b	d0,(a0)			;前回と違うキー
		clr	-(a0)
@@:		movea.l	(sp)+,a0
		rts

* キー入力がない場合、キーを押し続けていなければ移動行数を初期化.
* out	ccr Z	0:キーは押されている 1:キーが離された

check_cursor_up_down_keypush:
		PUSH	d0-d1/a0
		lea	(cursor_up_down_key,pc),a0
		moveq	#0,d1
		move.b	(a0),d1
		lsr	#3,d1
		IOCS	_BITSNS
		moveq	#7,d1
		and.b	(a0),d1
		btst	d1,d0
		bne	@f
*		clr.b	(a0)
		clr	-(a0)
@@:		POP	d0-d1/a0
		rts

* 高速カーソル移動用ウェイトルーチン.

cursor_up_down_wait:
		TO_SUPER
		move	(＄hspw),d0
		bra	@f
cursor_up_down_wait_loop:
		jsr	(_vdisp_wait)
@@:		dbra	d0,cursor_up_down_wait_loop
		TO_USER
		rts


cursor_up_down_count:
		.ds	1
cursor_up_down_key:
		.ds.b	1
		.even


* if (PATH_PAGETOP==0) {
*	if (cursor_y==0) return 0;
*	else cursor_y--;
* } else {
*	if (cursor_y==0) text_scroll_down(1); /* これは有り得ない筈 */
*	elseif (cursor_y==1) {
*		text_scroll_down(SCROLL_LINE); /* 通常は1 */
*		cursor += SCROLL_LINE-1;
*	} else cursor_y--;
* }

* カーソル↑移動下請け
* out	d0.l	status(0:error 1:OK)

cursor_up_sub:
		PUSH	d1-d7/a0-a5
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		tst	(PATH_PAGETOP,a6)
		bne	@f
		tst	d2
		beq	cursor_up_sub_error
cursor_up_sub_up:
		jbsr	ReverseCursorBar	;カーソル消去
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinCursorUp)
		bra	cursor_up_sub_end
@@:
		subq	#1,d2
		bhi	cursor_up_sub_up	;カーソル移動のみ

		jbsr	ReverseCursorBar	;カーソル消去
		bsr	get_filewin_scroll_line
		move	d0,d7			;d7=スクロール後のカーソル位置
		move	d0,d1
		sub	d2,d1			;d1=スクロール行数
		bra	1f
@@:		subq	#1,d1
		subq	#1,d7
1:		cmp	(PATH_PAGETOP,a6),d1
		bhi	@b

		moveq	#sizeof_DIR,d0
		mulu	(PATH_PAGETOP,a6),d0
		movea.l (PATH_BUF,a6),a4
		adda.l	d0,a4			;現在一番上に表示されているファイル

		sub	d1,(PATH_PAGETOP,a6)	;既に表示されている行をスクロール
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinScrollDown)

		move	d1,d2
		subq	#1,d2
cursor_up_sub_loop:
		lea	(-sizeof_DIR,a4),a4
		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		jsr	(WinSetCursor)
		bsr	print_filename_line
		dbra	d2,cursor_up_sub_loop

		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		move	d7,d2
		jsr	(WinSetCursor)
cursor_up_sub_end:
		bsr	print_cursor_and_linenum
		moveq	#1,d0
@@:		POP	d1-d7/a0-a5
		rts
cursor_up_sub_error:
		moveq	#0,d0
		bra	@b


* スクロールしたい行数は $scrl.
* 実際にスクロール可能な最大行数は L=PATH_FILENUM-PATH_PAGETOP-cursor_y-1.
* L==0 ならカーソル移動不可能.

* カーソル↓移動下請け
* out	d0.l	status(0:error 1:OK)

cursor_down_sub::
		PUSH	d1-d7/a0-a5
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		move	(PATH_FILENUM,a6),d1
		sub	(PATH_PAGETOP,a6),d1
		sub	d2,d1
		subq	#1,d1			;d1=スクロール可能な最大行数
		bls	cursor_down_sub_error

		jbsr	ReverseCursorBar	;カーソル消去
		move	(＄dirh),d6
		move	d6,d0
		subq	#2,d0
		cmp	d0,d2
		bcc	@f

		move	(PATH_WIN_FILE,a6),d0	;スクロールなし
		jsr	(WinCursorDown)
		bra	cursor_down_sub_end
@@:
		bsr	get_filewin_scroll_line
		cmp	d0,d1
		bls	@f
		move	d0,d1			;d1=スクロール行数
@@:
		move	d2,d7
		addq	#1,d7
		sub	d1,d7			;d7=スクロール後のカーソル位置

		moveq	#0,d0
		move	(PATH_PAGETOP,a6),d0
		add	d6,d0
		movea.l (PATH_BUF,a6),a4
		mulu	#sizeof_DIR,d0
		adda.l	d0,a4			;現在一番下に表示されている次のファイル

		add	d1,(PATH_PAGETOP,a6)	;既に表示されている行をスクロール
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinScrollUp)

		move	d7,d2
		addq	#1,d2			;描画開始行
		move	d1,d6
		subq	#1,d6
cursor_down_sub_loop:
		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		jsr	(WinSetCursor)
		bsr	print_filename_line

		addq	#1,d2
		lea	(sizeof_DIR,a4),a4
		dbra	d6,cursor_down_sub_loop

		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		move	d7,d2
		jsr	(WinSetCursor)
cursor_down_sub_end:
		bsr	print_cursor_and_linenum
		moveq	#1,d0
@@:		POP	d1-d7/a0-a5
		rts
cursor_down_sub_error:
		moveq	#0,d0
		bra	@b


* システム変数 scrl の値を正規化して返す.
* out	d0.w	$scrl

get_filewin_scroll_line:
		move	(＄scrl),d0
		beq	get_filewin_scroll_line_1
		move	d1,-(sp)
		move	(＄dirh),d1
		subq	#2,d1
		cmp	d1,d0
		bls	@f
		move	d1,d0
@@:		move	(sp)+,d1
		rts
get_filewin_scroll_line_1:
		moveq	#1,d0
window_size_error:
		rts


*************************************************
*		&window-size			*
*************************************************

＆window_size::
		bsr	set_status_0
		tst.l	d7
		beq.s	window_size_error

		jsr	(atoi_a0)
		bne	window_size_error
		tst.b	(a0)
		bne	window_size_error

		moveq	#DIRH_MIN,d1
		cmp.l	d1,d0
		bcc	@f
		move.l	d1,d0			;小さすぎたので補正
@@:
		moveq	#DIRH_MAX,d1
		cmp.l	d1,d0
		bls	@f
		move.l	d1,d0			;大きすぎたので補正
@@:
		lea	(＄dirh),a0
		cmp	(a0),d0
		beq	change_window_size_end	;現在のサイズと同じ

		move	d0,(a0)
		bra	change_window_size


*************************************************
*		&toggle-window-size		*
*************************************************

＆toggle_window_size::
		lea	(＄dirh),a0
		lea	(dirh_save,pc),a1
		move	(a0),d0
		cmp	(a1),d0
		beq	change_window_size_end

		move	(a1),(a0)		;＄dirh と dirh_save を交換
		move	d0,(a1)
change_window_size:
		bsr	winsize_cursor_revise2
		bsr	winsize_cursor_revise2
		bsr	change_winsize_sub
change_window_size_end:
		bra	set_status_1
**		rts

winsize_cursor_revise2:
		movea.l	(PATH_OPP,a6),a6
winsize_cursor_revise::
		PUSH	d0-d4
		moveq	#0,d3
		moveq	#0,d4
		move	(PATH_FILENUM,a6),d3
		move	(＄dirh),d4
		addq.l	#1,d3
		sub.l	d4,d3			;PAGETOP 最大値
		bcc	@f
		moveq	#0,d3
@@:
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		addq	#1,d2
		move	(PATH_PAGETOP,a6),d1
		cmp	d4,d2
		bcc	@f			;カーソル位置が画面外
		cmp	d1,d3
		bhi	winsize_cursor_revise_end
@@:						;空の行が見えてしまう
		subq	#1,d2
		add	d2,d1
		move	d4,d2
		lsr	#1,d2			;センタリング
		sub	d2,d1
		bcc	@f
		add	d1,d2			;PAGETOP を下げすぎたら戻す
		clr	d1
@@:
		sub	d1,d3
		bcc	@f
		sub	d3,d2
		add	d3,d1
@@:
		move	d1,(PATH_PAGETOP,a6)

* ウィンドウを拡大した場合、現在のウィンドウ範囲外に
* カーソル位置を設定することがあり、そのままだと
* WinSetCursor でエラーになるので、予めウィンドウの
* サイズを再設定しておく.
		move.l	d2,-(sp)
		move	(PATH_WINRL,a6),d1
		moveq	#3,d2
		moveq	#WIN_WIDTH,d3
**		move	(＄dirh),d4
		jsr	(WinDelete)		;今までのウィンドウを削除して
		jsr	(WinCreate)		;新しく作る
		move	d0,(PATH_WIN_FILE,a6)
		move.l	(sp)+,d2

		moveq	#0,d1
		jsr	(WinSetCursor)
winsize_cursor_revise_end:
		POP	d0-d4
		rts

change_winsize_sub:
		jbsr	set_scr_param
		jbsr	window_remake		;各種ウィンドウ作り直し
		bra	＆clear_and_redraw
**		rts


dirh_save:	.dc	DIRH_MIN


*************************************************
*		&shrink-window			*
*************************************************

＆shrink_window::
		lea	(＄dirh),a0
		cmpi	#DIRH_MIN,(a0)
		bls	set_status_0		;既に最小

		subq	#1,(a0)
		bsr	shrink_window_sub
		bsr	shrink_window_sub
		bra	shrink_grow_window

* カーソルが下から二行目にあった時は、縮小によって
* 最下行になってしまうので、それを回避するため表示
* 位置とカーソル位置を一行上に移動する.
shrink_window_sub:
		movea.l	(PATH_OPP,a6),a6
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		addq	#1,d2
		cmp	(a0),d2			;縮小後の dirh
		bcs	@f
		addq	#1,(PATH_PAGETOP,a6)
		jmp	(WinCursorUp)
@@:		rts


*************************************************
*		&grow-window			*
*************************************************

＆grow_window::
		lea	(＄dirh),a0
		cmpi	#DIRH_MAX,(a0)
		bcc	set_status_0		;既に最大

		addq	#1,(a0)
		bsr	grow_window_sub
		bsr	grow_window_sub
shrink_grow_window:
		bsr	change_winsize_sub
		bra	set_status_1
**		rts

* bottom of dir.が見えていて、上に表示されていないファイルがある場合
* 拡大すると空の行が表示されてしまうのを補正する(表示開始位置 -= 1).
* 拡大前	拡大後(誤)	拡大後(正)
*    file1	   file1	┌ file1
* ┌ file2	┌ file2	│ file2
* │ file3	│ file3	│ file3
* └ -----	│ -----	└ -----
*		└ (空行)
grow_window_sub:
		movea.l	(PATH_OPP,a6),a6
		move	(PATH_PAGETOP,a6),d0
		beq	grow_window_sub_end
		add	(a0),d0			;拡大後の dirh
		cmp	(PATH_FILENUM,a6),d0
		bls	grow_window_sub_end

		subq	#1,(PATH_PAGETOP,a6)
		move	(PATH_WIN_FILE,a6),d0
		jmp	(WinCursorDown)
grow_window_sub_end:
exchange_windows_end:
		rts


*************************************************
*		&exchange-windows		*
*************************************************

＆exchange_windows::
		movea.l	(PATH_OPP,a6),a5
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_MARC_FLAG,a5),d0
		bne.s	exchange_windows_end

		jbsr	set_curfile2
		lea	(PATH_CURFILE,a6),a1
		lea	(PATH_CURFILE,a5),a2
		moveq	#24/4-1,d0
@@:
		move.l	(a1),d1
		move.l	(a2),(a1)+
		move.l	d1,(a2)+
		dbra	d0,@b

		lea	(-64,sp),sp
		lea	(PATH_DIRNAME,a6),a1
		lea	(sp),a2
		STRCPY	a1,a2
		lea	(PATH_DIRNAME,a5),a1
		lea	(PATH_DIRNAME,a6),a2
		STRCPY	a1,a2
		lea	(sp),a1
		lea	(PATH_DIRNAME,a5),a2
		STRCPY	a1,a2
		lea	(64,sp),sp

		move	(PATH_DRIVENO,a6),d0
		move	(PATH_DRIVENO,a5),(PATH_DRIVENO,a6)
		move	d0,(PATH_DRIVENO,a5)

		bsr	exchange_windows_end_sub
		bsr	exchange_windows_end_sub
		jbra	ReverseCursorBarBoth
**		rts

exchange_windows_end_sub:
		movea.l	(PATH_OPP,a6),a6
		jbsr	chdir_routin
		jbra	directory_write_routin
**		rts


*************************************************
*		&cursor-left			*
*************************************************

＆cursor_left::
		tst	(PATH_WINRL,a6)
		bra.s	cursor_lr


*************************************************
*		&cursor-right			*
*************************************************

＆cursor_right::
		cmpi	#WIN_RIGHT,(PATH_WINRL,a6)
cursor_lr:	bne	＆cursor_opposite_window

		bsr	set_status_0
		tst	(＄lrgp)
		beq	@f

		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_DIRNAME+3,a6),d0
		bne	＆chdir_to_parent
@@:		rts


*************************************************
*		&cursor-opposite-window		*
*************************************************

＆cursor_opposite_window::
		jbsr	ReverseCursorBarBoth	;カーソル消去
		jsr	(restore_minttmp_curdir)

		movea.l	(PATH_OPP,a6),a6
		bsr	chdir_routin
		jbsr	ReverseCursorBarBoth	;カーソル描画
		bra	set_status_1
**		rts


* &cursor-rollup/rolldown 共通定義 ------------ *

~csrol_filenum:	.reg	d4
~csrol_pagetop:	.reg	d5
~csrol_win_file:.reg	d6
~csrol_dirh:	.reg	d7


*************************************************
*		&cursor-rollup			*
*************************************************

＆cursor_rollup::
		tst.b	(PATH_NODISK,a6)
		bmi	set_status_1		;未挿入時は正常終了とする

		bsr	cursor_rollupdown_init

		move	~csrol_pagetop,d3
		add	~csrol_dirh,d3
		cmp	~csrol_filenum,d3
		bls	cursor_rollup_next_page

;画面内にディレクトリ終端が表示されている.
		move	~csrol_win_file,d0
		jsr	(WinGetCursor)
		add	~csrol_pagetop,d2
		addq	#1,d2
		cmp	~csrol_filenum,d2	;カーソルが終端の直前にあればエラー
		bcc	set_status_0		;空のドライブで終端上にあっても〃

		jbsr	ReverseCursorBar	;そうでなければ終端の直前に移動
		tst	~csrol_pagetop
		beq	@f

		move	~csrol_dirh,d2
		subq	#2,d2
		bra	cursor_rollup_end
@@:
		move	~csrol_filenum,d2
		subq	#1,d2
		bra	cursor_rollup_end

cursor_rollup_next_page:
		move	~csrol_win_file,d0
		jsr	(WinGetCursor)
		move	d2,-(sp)
		bne	@f
		addq	#1,(sp)
@@:
		subq	#2,d3			;次の画面の先頭位置
		moveq	#0,d0
		move	d3,d0
		add	~csrol_dirh,d3
		subq	#1,d3			;次の画面の最終行のファイル位置
		sub	~csrol_filenum,d3
		bls	cursor_rollupdown	;一画面分スクロール出来る

		sub	d3,d0			;最終行にディレクトリ終端がくるように調整
		addq	#1,d3
		move	d3,(sp)
cursor_rollupdown:
		move	d0,(PATH_PAGETOP,a6)
		jbsr	print_file_list
		move	(sp)+,d2		;元の位置に移動
cursor_rollup_end:
		move	~csrol_win_file,d0
		moveq	#0,d1
		jsr	(WinSetCursor)
		jbsr	print_cursor_and_linenum
		bra	set_status_1
**		rts

cursor_rollupdown_init:
		move	(PATH_FILENUM,a6),~csrol_filenum
		move	(PATH_PAGETOP,a6),~csrol_pagetop
		move	(PATH_WIN_FILE,a6),~csrol_win_file
		move	(＄dirh),~csrol_dirh
		rts


*************************************************
*		&cursor-rolldown		*
*************************************************

＆cursor_rolldown::
		tst.b	(PATH_NODISK,a6)
		bmi	set_status_1		;未挿入時は正常終了とする

		bsr	cursor_rollupdown_init

		move	~csrol_win_file,d0
		jsr	(WinGetCursor)
		tst	~csrol_pagetop
		bne	@f

;ディレクトリ先頭が表示されている.
		tst	d2
		beq	set_status_0		;既にカーソルが先頭にある

		jbsr	ReverseCursorBar
		moveq	#0,d2
		bra	cursor_rollup_end
@@:
		move	d2,-(sp)

		moveq	#0,d0
		move	~csrol_pagetop,d0
		addq	#2,d0
		sub	~csrol_dirh,d0
		bcc	cursor_rollupdown	;一画面分スクロール出来る

		move	~csrol_pagetop,(sp)
		moveq	#0,d0
		bra	cursor_rollupdown


*************************************************
*		&ext-exec			*
*************************************************

＆ext_exec::
		tst.l	d7
		beq	＆ext_exec_or_chdir

		STRLEN	a0,d0
		beq	set_status_0
		lsr.l	#8,d0
		bne	set_status_0		;引数が長すぎる

		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		moveq	#%101,d0		;マークファイルを展開する
		jsr	(mintarc_extract)
@@:
		lea	(-256,sp),sp
		lea	(sp),a1
		lea	(Buffer),a2
@@:		move.b	(a0)+,d0
		move.b	d0,(a1)+		;STRCPY a0,a1
		move.b	d0,(a2)+		;STRCPY a0,a2
		bne	@b
		move.l	sp,d6			;&ext-exec モード
		bsr	ext_exec_or_chdir_exec
		lea	(256,sp),sp
ext_exec_or_chdir_end:
		rts


*************************************************
*		&exec-j-special-entry		*
*************************************************

＆exec_j_special_entry::
		moveq	#-1,d6			;&exec-j モード
		bra.s	ext_exec_or_chdir


*************************************************
*		&ext-exec-or-chdir		*
*************************************************

＆ext_exec_or_chdir::
		moveq	#0,d6
ext_exec_or_chdir:
		tst.b	(PATH_NODISK,a6)
		bmi.s	ext_exec_or_chdir_end

		jbsr	search_cursor_file
		cmpi.b	#-1,(DIR_ATR,a4)
		beq.s	ext_exec_or_chdir_end

		lea	(DIR_NAME,a4),a1
		lea	(Buffer),a2
		btst	#DIRECTORY,(DIR_ATR,a4)
		beq	ext_exec_or_chdir_file

*ext_exec_or_chdir_dir:
		bsr	is_parent_directory_a4
		bne	＆chdir_to_parent

		lea	(PATH_DIRNAME,a6),a0	;カーソル位置のディレクトリに移動
		move.l	a2,-(sp)
		STRCPY	a0,a2
		subq.l	#1,a2
		jsr	(copy_dir_name_a1_a2)
@@:		tst.b	(a2)+
		bne	@b
		clr.b	(a2)
		move.b	(MINTSLASH,opc),-(a2)
		movea.l	(sp)+,a1

		clr.b	(PATH_CURFILE,a6)
		jbsr	chdir_a1_arc
		bne	@f

		bsr	chdir_error
		moveq	#0,d0
@@:		bra	set_status
**		rts


chdir_error:
		moveq	#MES_CDERR,d0
		jbra	PrintMsgCrlf
**		rts


ext_exec_or_chdir_file:
		jsr	(copy_dir_name_a1_a2)

		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		moveq	#%111,d0		;カーソルファイル/マークファイルを展開する
		jsr	(mintarc_extract)	;(反対側も展開した方が良い?)
@@:
		bra	ext_exec_or_chdir_exec


* &ext-exec(-or-chdir)共通処理 ---------------- *
* in	Buffer	ファイル名
*	d6.l	0  = &ext-exec-or-chdir
*		-1 = &exec-j-special-entry
*		それ以外 = &ext-exec(ファイル名)
* 備考:
*	マークファイルを展開しておくこと.
*	&ext-exec-or-chdir の場合はカーソル位置
*	ファイルも展開しておくこと.

ext_exec_or_chdir_exec:
		tst.l	(mintrc_buf_adr)
		beq	ext_exec_or_chdir_exec_end

		moveq	#$00,d0			;exec モード
		bsr	search_file_define
		move.l	a1,d0
		bne	@f

		move.l	(kq_buffer+KQ_NO_DEF*4),d0
		beq	ext_exec_or_chdir_exec_end
		movea.l	d0,a1			;>NO_DEF を実行する
		bra	1f
@@:
**		cmpi.b	#$20,(a1)+
**		bhi	@b
**		subq.l	#1,a1
1:
		moveq	#%0000_1000,d0
		and	d6,d0			;&exec-j
		tst.l	d6
		ble	@f
		moveq	#%0001_0000,d0		;&ext-exec
		movea.l	d6,a0
@@:
		clr.b	(into_marc_flag)
		jsr	(execute_quick)

		tst.l	d6
		bgt	ext_exec_or_chdir_exec_end	;&ext-exec

		cmpi	#1,(＄fumd)
		bcs	ext_exec_or_chdir_exec_end	;%fumd 0
		beq	@f				;%fumd 1
		move.b	(into_marc_flag,pc),d0
@@:		beq	cursor_down_sub			;%fumd 2 かつ mintarc 突入でない
ext_exec_or_chdir_exec_end:
		rts


into_marc_flag::.ds.b	1
		.even


* ファイル判別定義の検索 ---------------------- *
* in	d0.l	モード($00=exec $01=help)
*	Buffer	ファイル名
* out	a1.l	定義アドレス(0 ならエラー)

search_file_define::
		move.l	a0,-(sp)
		move.b	d0,(help_flag)		;($00=&ext-exec* $01:&ext-help)
		tst	(＄exmd)
		beq	1f

* 拡張子→内容判別判別の順
		bsr	search_filename_ext_define
		bne	search_file_define_found
		bsr	search_file_match_define
		bra	@f
1:
* 内容判別→拡張子判別の順
		bsr	search_file_match_define
		bne	search_file_define_found
		bsr	search_filename_ext_define
@@:		bne	search_file_define_found

		move.b	(help_flag,pc),d0
		beq	search_file_define_end	;exec モード

		move.l	(kq_buffer+KQ_NO_DEF*4),d0
		beq	search_file_define_end

		movea.l	d0,a1
		moveq	#'>',d0
@@:		cmp.b	-(a1),d0		;行頭の '>' を返す
		bne	@b
search_file_define_found:
search_file_define_end:
		move.l	a1,d0
		movea.l	(sp)+,a0
		rts


* ファイル内容判別 ---------------------------- *

search_file_match_define:
		PUSH	d0-d7/a2-a5
		moveq	#-1,d7			;0:text 1:binary -1:無指定
		pea	(file_match_buffer)

		lea	(file_compare_table),a3
		tst	(2,a3)
		beq	s_f_m_error		;"^" 指定が一個もない

		lea	(Buffer),a1
		movea.l	(sp),a2			;バッファアドレス
		bsr	file_match_read
		tst.l	d0
		bmi	s_f_m_error

		clr.l	(_ignore_case)

* コンペアスタートオフセット(ワード固定),比較用パターン(可変長),0,RCアドレス(LONG)
s_f_m_loop:
		lea	(file_match_buffer),a2
		adda	(a3)+,a2

		move.l	a2,-(sp)		;string
		move.l	a3,-(sp)		;buffer
		jsr	(_fre_match)
		addq.l	#8,sp

		move.l	d0,-(sp)
@@:
		tst.b	(a3)+			;コンパイルしたデータを飛ばす
		bne	@b
		tst.b	(a3)
		bne	@b
		move	a3,d0
		lsr	#1,d0
		bcc	@f
		addq.l	#1,a3			;even
@@:		move.l	(a3)+,a1		;定義ファイルの該当行のアドレスを得る

		tst.l	(sp)+
		beq	s_f_m_diff		;不一致

		moveq	#1,d1
		cmpi.b	#'^',(a1)
		beq	@f
		cmpi.b	#'~',(a1)
		bne	s_f_m_found		;バイナリ/テキストは無指定なので確定
		moveq	#0,d1
@@:
		tst	d7
		bpl	@f			;バイナリ/テキスト判別済み
		lea	(a2),a0
		move.l	d2,d0
		jsr	(if_ftst_is_binary)
		move	d0,d7
@@:		cmp	d1,d7
		beq	s_f_m_found		;ファイルの種類も一致
s_f_m_diff:
		tst	(2,a3)
		bne	s_f_m_loop		;まだパターンが残っている
s_f_m_error:
		suba.l	a1,a1
		bra	s_f_m_end
s_f_m_found:
		subq.l	#1,a1			;行頭の '^' を返す
		move.b	(help_flag,pc),d0
		bne	s_f_m_end		;&ext-help モード
@@:
		jbsr	next_line_a1		;&ext-exec モード
		beq	s_f_m_error
		cmpi.b	#'^',(a1)
		beq	@b
		cmp.b	#'.',(a1)
		bne	s_f_m_end

		lea	(Buffer+256),a0		;拡張子判別の記述を飛ばす
		bsr	cut_ext_pattern
		bmi	s_f_m_error		;記述がおかしい

		bsr	skip_ext_def_tail
s_f_m_end:
		move.l	a1,d0			;NULL なら未指定
		addq.l	#4,sp
		POP	d0-d7/a2-a5
		rts


* ファイル内容判別用にファイルを読み込む
* in	a1.l	ファイル名
*	a2.l	バッファ(file_match_buffer)
* out	d0.l	0:正常終了 -1:エラー
*	ccr	<tst.l d0> の結果
* 備考:
*	ファイルサイズが 0 バイトの場合はエラーを返す.

file_match_read::
		PUSH	d1-d3/a2

		clr	-(sp)
		pea	(a1)			;ファイル名
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d1
		bmi	file_match_read_error

		moveq	#0,d2
		move	(＄fcmp),d2		;読み込み容量
		move.l	d2,-(sp)
		pea	(a2)			;バッファ
		move	d1,-(sp)
		DOS	_READ
		move.l	d0,d3			;実際に読み込んだサイズ
		DOS	_CLOSE
		addq.l	#10-4,sp
		move.l	d3,(sp)+
		ble	file_match_read_error

		adda.l	d3,a2
		addq	#8,d2
		sub	d3,d2			;足りないサイズ

		move	a2,d0
		lsr	#1,d0
		bcc	@f
		clr.b	(a2)+			;ロングワード境界に合わせる
@@:		lsr	#1,d0
		bcc	@f
		clr	(a2)+			;〃
@@:
		moveq	#0,d0
		lsr	#3,d2			;端数の処理は適当
@@:
		move.l	d0,(a2)+		;足りない分をクリア
		move.l	d0,(a2)+
		dbra	d2,@b

		moveq	#0,d0
@@:
		POP	d1-d3/a2
		rts
file_match_read_error:
		moveq	#-1,d0
		bra	@b


* ファイル名/拡張子判別 ----------------------- *

* in	Buffer	ファイル名
* out	d0.l	a1.l と同じ
*	a1.l	定義位置(0 なら見つからなかった)
*	ccr	<tst.l d0> の結果
* 備考:
*	判別は常にファイル名(!filename)、拡張子(.ext)の順で行われる.
*	返値の a1.l は、&ext-exec 系から呼び出された場合はクイック
*	定義の先頭('-')を指し、&ext-help から呼び出された場合は
*	パターンの先頭を指す('!'、'.'、'>').

search_filename_ext_define:
		PUSH	d1-d7/a2-a5
		lea	(Buffer),a5		;ファイル名
		lea	(256,a5),a4		;バッファ
		lea	(1024*10,a5),a0
		move.l	a0,d6			;末尾

		moveq	#1,d0
		move.l	d0,(_ignore_case)	;常に大文字小文字同一視

		tst.b	(a5)
		beq	@f
		cmpi.b	#':',(1,a5)
		bne	@f
		addq.l	#2,a5			;"d:" を飛ばす
@@:
		lea	(a5),a0
		bsr	search_last_slash
		bmi	@f
		lea	(a1),a5			;ファイル名を取り出す
@@:
;ファイル名判別
search_filename_define:
		lea	(file_match_table),a3
search_fn_def_loop:
		move.l	(a3)+,d7
		beq	search_ext_define

		lea	(a4),a0
		movea.l	d7,a1
		bsr	cut_filename_pattern
		bmi	search_fn_def_loop	;記述がおかしい

		move.l	a1,d4
		move.l	a0,d5
		move.l	d6,d0
		sub.l	d5,d0
		bls	search_fn_def_loop
		lsr.l	#1,d0			;バッファサイズ

		pea	(a4)			;pattern
		move.l	d0,-(sp)		;buffer size(.w)
		move.l	d5,-(sp)		;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bne	search_fn_def_loop	;コンパイルエラー

		pea	(a5)			;filename
		move.l	d5,-(sp)		;buffer
		jsr	(_fre_match)
		addq.l	#8,sp
		tst.l	d0
		beq	search_fn_def_loop	;不一致

search_fn_ext_def_found:
		movea.l	d7,a1			;見つかった
		subq.l	#1,a1			;行頭の '!'、'>' を返す
		move.b	(help_flag,pc),d0
		bne	search_fn_ext_def_end	;&ext-help モード

		movea.l	d4,a1			;&ext-exec モード
		bsr	skip_ext_def_tail
search_fn_ext_def_end:
		move.l	a1,d0
		POP	d1-d7/a2-a5
		rts


skip_ext_def_tail:
		cmpi.b	#LF,(a1)
		beq	@f
		cmpi.b	#CR,(a1)
		bne	skip_connect_line
@@:
		bsr	next_line_a1
		bra	skip_connect_line
**		rts


;拡張子判別
search_ext_define:
		lea	(a5),a0
search_ext_def_ext_clr:
		moveq	#0,d1
		move.b	(a0)+,d0		;先頭の '.' は拡張子ではない(.mint など)
		beq	search_ext_def_ext_end
search_ext_def_ext_loop:
.if 0
		cmpi.b	#':',d0
		beq	search_ext_def_ext_clr	;今までの '.' は拡張子ではなかった
		cmpi.b	#'/',d0
		beq	search_ext_def_ext_clr
		cmpi.b	#'\',d0
		beq	search_ext_def_ext_clr
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@f
		tst.b	(a0)+			;二バイト文字の下位バイト
		beq	search_ext_def_ext_end
.endif
@@:
		move.b	(a0)+,d0
		beq	search_ext_def_ext_end
		cmpi.b	#'.',d0
		bne	search_ext_def_ext_loop

		move.l	a0,d1			;拡張子(と思われる '.')を発見した
		bra	@b
search_ext_def_ext_end:
		tst.l	d1
		bne	search_ext_def_ext_found

* 拡張子がなくて、実行属性が立っているファイルの場合
* >EXEATR が定義されていればそれを返す.
* 定義されていない場合は ".x" という拡張子があるものと
* 見なして検索する.
		move	#1<<EXEC,-(sp)
		pea	(Buffer)		;a5 ではダメ("d:" を飛ばしているので)
		pea	(a4)
		DOS	_FILES			;DOS _CHMOD ではダメ
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	search_ext_def_error
		tst.b	(FILES_FileAtr,a4)
		bpl	search_ext_def_error

		lea	(period_x,pc),a5
		move.l	(kq_buffer+KQ_EXEATR*4),d0
		beq	search_ext_def_ext_found2

		movea.l	d0,a1			;>EXEATR の定義を返す
		move.b	(help_flag,pc),d0
		beq	search_fn_ext_def_end	;exec モード

		moveq	#'>',d0
@@:		cmp.b	-(a1),d0		;行頭の '>' を返す
		bne	@b
		bra	search_fn_ext_def_end

search_ext_def_ext_found:
		movea.l	d1,a5			;'.' なしの拡張子
search_ext_def_ext_found2:
		move.l	(period_start,pc),d0
		movea.l	d0,a1
		beq	search_fn_ext_def_end
search_ext_def_loop:
		move.b	(a1)+,d0
		cmpi.b	#LF,d0
		beq	search_ext_def_loop
		cmpi.b	#'.',d0
		bne	search_ext_def_next
		cmpi.b	#$20,(a1)		;@exec の . "..." なら飛ばす
		bls	search_ext_def_next

		move.l	a1,d7
		lea	(a4),a0
		bsr	cut_ext_pattern
		bmi	search_ext_def_next2	;記述がおかしい

		move.l	a1,d4
		move.l	a0,d5
		move.l	d6,d0
		sub.l	d5,d0
		bls	search_ext_def_next2
		lsr.l	#1,d0			;バッファサイズ

		pea	(a4)			;pattern
		move.l	d0,-(sp)		;buffer size(.w)
		move.l	d5,-(sp)		;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bne	search_ext_def_next2	;コンパイルエラー

		pea	(a5)			;filename
		move.l	d5,-(sp)		;buffer
		jsr	(_fre_match)
		addq.l	#8,sp
		tst.l	d0
		bne	search_fn_ext_def_found	;一致
search_ext_def_next2:
		movea.l	d7,a1
search_ext_def_next:
		jbsr	next_line_a1
		bne	search_ext_def_loop
search_ext_def_error:
		suba.l	a1,a1			;見つからなかった
		bra	search_fn_ext_def_end


* 拡張子判別の直後の行結合を処理する
* in	a1.l	文字列
* out	a1.l	〃(0 ならエラー)

skip_connect_line::
		jbsr	skip_blank_a1
		cmpi.b	#'\',(a1)
		bne	@f
		cmpi.b	#$20,(1,a1)
		bhi	@f
		jbsr	next_line_a1
		bne	skip_connect_line
		suba.l	a1,a1
@@:		rts


* 空白文字を飛ばす
* i/o	a1.l	文字列
skip_blank_loop:
		addq.l	#1,a1
skip_blank_a1::
		cmpi.b	#TAB,(a1)
		beq	skip_blank_loop
		cmpi.b	#SPACE,(a1)
		beq	skip_blank_loop
		rts


* ファイル名パターンを切り出す
* in	a0.l	バッファ
*	a1.l	パターン文字列
* out	d0.l	0:正常終了 1:エラー
*	a0.l	バッファ末尾(偶数アドレス)
*	a1.l	パターン直後
*	ccr	<tst.l d0> の結果
* 備考:
*	tabcomplete.s からも使用されている.

cut_filename_pattern::
		PUSH	d1/a2
		moveq	#0,d1			;quote フラグ
		lea	(a0),a2
		bra	cut_fn_pat_start
cut_fn_pat_loop2:
		move.b	(a1)+,d0
cut_fn_pat_loop3:
		cmpi.b	#TAB,d0
		beq	cut_fn_pat_blank
		cmpi.b	#$20,d0
		beq	cut_fn_pat_blank
		bcs	cut_fn_pat_end
		cmpi.b	#'"',d0
		beq	cut_fn_pat_quote
		cmpi.b	#"'",d0
		beq	cut_fn_pat_quote

		move.b	d0,(a0)+		;普通の文字
		bra	cut_fn_pat_loop2
cut_fn_pat_quote:
		tst.b	d1
		beq	@f			;クオート開始
		moveq	#0,d0			;	 終了
@@:		move.b	d0,d1			
		bra	cut_fn_pat_loop2
cut_fn_pat_blank:
		move.b	#'|',(a0)+
cut_fn_pat_start:
@@:		move.b	(a1)+,d0		;空白を飛ばす
		cmpi.b	#SPACE,d0
		beq	@b
		cmpi.b	#TAB,d0
		beq	@b
		cmpi.b	#'\',d0
		beq	@f			;!"foo" \
		tst.b	d1
		bne	cut_fn_pat_loop3	;!"-foo"
		cmpi.b	#'-',d0
		bne	cut_fn_pat_loop3	;!"foo" -d1- bar
@@:
		subq.l	#1,a0			;最後の '|' を取り消す
cut_fn_pat_end:
		subq.l	#1,a1
		cmpa.l	a0,a2
		beq	cut_fn_pat_error	;記述がおかしい

		clr.b	(a0)+
		move.l	a0,d0
		lsr	#1,d0
		bcc	@f
		clr.b	(a0)+
@@:
		moveq	#0,d0
@@:		POP	d1/a2
		rts
cut_fn_pat_error:
		moveq	#-1,d0
		bra	@b


* 拡張子パターンを切り出す
* in	a0.l	バッファ
*	a1.l	パターン文字列
* out	d0.l	0:正常終了 1:エラー
*	a1.l	パターン直後
*	a0.l	バッファ末尾(偶数アドレス)
*	ccr	<tst.l d0> の結果

cut_ext_pattern:
		move.l	a2,-(sp)
		lea	(a0),a2
cut_ext_pat_loop2:
		move.b	(a1)+,d0
		cmpi.b	#TAB,d0
		beq	cut_ext_pat_blank
		cmpi.b	#$20,d0
		beq	cut_ext_pat_blank
		bcs	cut_ext_pat_end

		move.b	d0,(a0)+		;普通の文字
		bra	cut_ext_pat_loop2
cut_ext_pat_blank:
		move.b	#'|',(a0)+
@@:
		move.b	(a1)+,d0		;空白を飛ばす
		cmpi.b	#SPACE,d0
		beq	@b
		cmpi.b	#TAB,d0
		beq	@b
		cmpi.b	#'.',d0
		beq	cut_ext_pat_loop2	;次の拡張子

		subq.l	#1,a0			;最後の '|' を取り消す
cut_ext_pat_end:
		subq.l	#1,a1
		cmpa.l	a0,a2
		beq	cut_ext_pat_error	;記述がおかしい

		clr.b	(a0)+
		move.l	a0,d0
		lsr	#1,d0
		bcc	@f
		clr.b	(a0)+
@@:
		moveq	#0,d0
@@:		movea.l	(sp)+,a2
		rts
cut_ext_pat_error:
		moveq	#-1,d0
		bra	@b


* 行頭の判別定義記述部分を飛ばす -------------- *

* in	a1.l	文字列(行頭)
* out	a1.l	コマンド文字列
* break	d0
* 仕様:
*	'^' = ファイル内容判別 -> その行を飛ばす.
*	'!' = ファイル名判別 -> パターンを飛ばす.
*	'.' = 拡張子判別 -> パターンを飛ばす.
*	'>' = キー定義 -> >?????? を飛ばす.

skip_define_word_nl:
		moveq	#LF,d0
		cmp.b	(a1)+,d0
		bne	skip_define_word_nl
skip_define_word::
		move.b	(a1)+,d0
		cmpi.b	#'^',d0
		beq	skip_define_word_nl
		cmpi.b	#'!',d0
		beq	skip_define_word_fn
		cmpi.b	#'.',d0
		beq	skip_define_word_ext
		cmpi.b	#'>',d0
		beq	skip_define_word_kq

		subq.l	#1,a1
		rts
skip_define_word_fn:
		move.l	a0,-(sp)
		lea	(Buffer),a0
		bsr	cut_filename_pattern
		bra	@f
skip_define_word_ext:
		move.l	a0,-(sp)
		lea	(Buffer),a0
		bsr	cut_ext_pattern
@@:		movea.l	(sp)+,a0
		rts
skip_define_word_kq:
		addq.l	#.sizeof.('>NO_DEF')-1,a1
		rts


period_start:	.dc.l	0
period_x:	.dc.b	'x',0
help_flag:	.dc.b	0
		.even


*************************************************
*		&goto-cursor			*
*************************************************

＆goto_cursor::
		moveq	#0,d0
		tst.b	(PATH_NODISK,a6)
		bmi	goto_cursor_end
		tst.l	d7
		beq	goto_cursor_end

		jsr	(atoi_a0)
		moveq	#0,d1
		move	(PATH_FILENUM,a6),d1
		cmp.l	d1,d0
		bls	@f
		move.l	d1,d0			;大きすぎたので補正
@@:		tst.l	d0
		beq	@f
		subq.l	#1,d0			;0 始まりに修正
@@:
		bsr	goto_cursor_sub
		moveq	#1,d0
goto_cursor_end:
		bra	set_status
**		rts


* カーソル位置変更(番号指定)
* in	d0.l	位置(0 <= d0.l < PATH_FILENUM)
* break	d0

goto_cursor_sub2:
		PUSH	d1-d7/a0-a5
		moveq	#1,d5
		bra	@f
goto_cursor_sub::
		PUSH	d1-d7/a0-a5
		moveq	#0,d5
@@:
		move.l	d0,d7
		move	(＄dirh),d6
		move	(PATH_WIN_FILE,a6),d0
		tst	d5
		bne	@f

		jbsr	ReverseCursorBar

* 目的の位置が現在の表示画面内にあれば、カーソルを移動する
		move.l	d7,d2
		move	(PATH_PAGETOP,a6),d1
		beq	goto_cursor_sub_top	;バッファ先頭は最上行に行ける
		sub	d1,d2
		bls	@f			;表示画面より上側
goto_cursor_sub_top:
		move	d6,d1
		subq	#1,d1
		cmp	d1,d2
		bcc	@f			;表示画面より下側

		moveq	#0,d1
		jsr	(WinSetCursor)
		bra	goto_cursor_sub_end
@@:
* 表示画面内になければセンタリングして表示
		move	d6,d2
		lsr	#1,d2			;中央の Y 座標
		sub	d2,d7			;最上行の位置
		bcc	@f
1:
		add	d7,d2			;バッファ先頭より上を表示しないように補正
		sub	d7,d7
		bra	goto_cursor_sub_disp
@@:
		add	d7,d6
		sub	(PATH_FILENUM,a6),d6
		bls	goto_cursor_sub_disp

		subq	#1,d6
		add	d6,d2			;バッファ末尾より下を表示しないように補正
		sub	d6,d7
		bcs	1b
goto_cursor_sub_disp:
		moveq	#0,d1
		jsr	(WinSetCursor)
		move	d7,(PATH_PAGETOP,a6)
		bsr	print_file_list
goto_cursor_sub_end:
		tst	d5
		bne	@f
		bsr	print_cursor_and_linenum
@@:
		POP	d1-d7/a0-a5
		rts


*************************************************
*		&cursor-to-home			*
*************************************************

＆cursor_to_home::
		bsr	cursor_to_home_sub
		bra	set_status
**		rts

* カーソルをディレクトリ最上段に移動する.
* out	d0.l	0:エラー(既に最上段にあった)
*		1:正常終了
* 備考:
*	メディア未挿入の場合は正常終了(d0.l=1)が返る.

cursor_to_home_sub::
		PUSH	d1-d7/a0-a5
		tst.b	(PATH_NODISK,a6)
		bmi	cursor_to_home_sub_end	;未挿入時は正常終了
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		or	(PATH_PAGETOP,a6),d2
		beq	cursor_to_home_sub_error

.if 1
		moveq	#0,d0
		bsr	goto_cursor_sub
.else
		clr	(PATH_PAGETOP,a6)
		jbsr	print_file_list

		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		jbsr	print_cursor_and_linenum
.endif
cursor_to_home_sub_end:
		moveq	#1,d0
@@:		POP	d1-d7/a0-a5
		rts
cursor_to_home_sub_error:
		moveq	#0,d0
		bra	@b


* カーソルを描画して、行番号を表示する.
print_cursor_and_linenum:
		jbsr	ReverseCursorBar

* 行番号を表示する.
* ドライブ情報のメディア種別の欄に上書きするので、
* %finf 及び %inf? の設定も参照している.
print_cursor_linenum:
		PUSH	d0-d2/a1
		move.b	(write_disable_flag,opc),d2
		bne	print_csr_lnum_end
		tst	(＄gyou)
		bne	print_csr_lnum_end	;行番号の表示なし
* %finf / infX は見ない(%gyou 1 なら常に行数表示)
*		jbsr	get_drive_info_mode
*		beq	print_csr_lnum_end	;ドライブ情報行の表示なし

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		moveq	#1,d0
		add	d2,d0
		add	(PATH_PAGETOP,a6),d0	;行番号

		subq	#8,sp
		moveq	#4,d1			;4 桁
		lea	(sp),a0
		FPACK	__IUSING

		move	(PATH_WIN_INFO,a6),d0
		moveq	#41,d1			;X
		moveq	#0,d2			;Y
		jsr	(WinSetCursor)
		lea	(sp),a1
		jsr	(WinPrint)
		addq	#8,sp
print_csr_lnum_end:
		POP	d0-d2/a1
		rts


*************************************************
*		&cursor-to-bottom		*
*************************************************

＆cursor_to_bottom::
		bsr	cursor_to_bottom_sub
		bra	set_status
**		rts

* カーソルをディレクトリ最下段に移動する.
* out	d0.l	0:エラー(既に最下段にあった)
*		1:正常終了
* 備考:
*	メディア未挿入の場合は正常終了(d0.l=1)が返る.

cursor_to_bottom_sub:
		PUSH	d1-d7/a0-a5
		tst.b	(PATH_NODISK,a6)
		bmi	cursor_to_bottom_sub_end
		tst	(PATH_FILENUM,a6)
		beq	cursor_to_bottom_sub_error
		jbsr	search_cursor_file
		cmpi.b	#-1,(DIR_ATR+sizeof_DIR,a4)
		beq	cursor_to_bottom_sub_error

.if 1
		moveq	#0,d0
		move	(PATH_FILENUM,a6),d0
		subq	#1,d0
		bsr	goto_cursor_sub
.else
		move	(PATH_FILENUM,a6),d0
		addq	#1,d0
		sub	(＄dirh),d0
		bhi	@f
		moveq	#0,d0			;先頭ページ内に末尾も表示される
@@:
		move	d0,(PATH_PAGETOP,a6)	;d0=filenum-dirh+1
		jbsr	print_file_list

		move	(PATH_WIN_FILE,a6),d0
		moveq	#0,d1
		move	(PATH_FILENUM,a6),d2
		sub	(PATH_PAGETOP,a6),d2
		subq	#1,d2
		jsr	(WinSetCursor)
		jbsr	print_cursor_and_linenum
.endif
cursor_to_bottom_sub_end:
		moveq	#1,d0
@@:		POP	d1-d7/a0-a5
		rts
cursor_to_bottom_sub_error:
		moveq	#0,d0
		bra	@b


*************************************************
*		&mark=&mark-forward		*
*************************************************

＆mark::
		moveq	#'|',d1
		bsr	mask_decode_argument
		bne	mark_regexp		;マッチしたファイルをマーク

* 引数なしならカーソル位置ファイルのマークを反転
		moveq	#1,d0
		tst.b	(PATH_NODISK,a6)
		bmi	mark_forward_end	;メディア未挿入時は正常終了

		bsr	mark_sub		;マークして
		bsr	cursor_down_sub		;カーソルダウン
mark_forward_end:
		bra	set_status
**		rts

mark_regexp:
		bsr	get_dir_buf_a4_d7

		moveq	#0,d7			;処理したファイル数
		tst.b	(PATH_NODISK,a6)
		bmi	mark_regexp_end

		lea	(Buffer),a3
		pea	(a0)			;pattern
		pea	(1000/2).w		;size
		pea	(24,a3)			;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	mark_regexp_next

		bsr	print_regexp_compile_error
		bra	mark_regexp_end
mark_regexp_loop:
*		lea	(DIR_NAME,a4),a1
		lea	(a3),a2
		jsr	(copy_dir_name_a1_a2)

		pea	(a3)			;string
		pea	(24,a3)			;buffer
		jsr	(_fre_match)
		addq.l	#8,sp
		tst.l	d0
		beq	@f

		bchg	#MARK,(DIR_ATR,a4)	;マッチしたらマーク反転
		addq	#1,d7
@@:
		lea	(sizeof_DIR,a4),a4
mark_regexp_next:
		lea	(DIR_ATR,a4),a1
		cmpi.b	#-1,(a1)+
		bne	mark_regexp_loop

		tst	d7
		beq	mark_regexp_end
		move.b	(write_disable_flag,opc),d0
		bne	mark_regexp_end

		jbsr	print_file_list
		move.l	d7,-(sp)
		jbsr	ReverseCursorBar
		jbsr	print_mark_information
		move.l	(sp)+,d7
mark_regexp_end:
		move.l	d7,d0
		bra	set_status
**		rts


*************************************************
*		&mark-upper			*
*************************************************

＆mark_upper::
		tst.b	(PATH_NODISK,a6)
		bmi	mark_upper_end
		jbsr	search_cursor_file
		cmpa.l	(PATH_BUF,a6),a4
		beq	mark_upper_end		;既に最上段
		lea	(-sizeof_DIR,a4),a4
		bsr	is_parent_directory_a4
		bne	mark_upper_end		;".." はマーク出来ない

		bchg	#MARK,(DIR_ATR,a4)	;マーク反転

		move.b	(write_disable_flag,opc),d0
		bne	mark_upper_end

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		subq	#1,d2			;y--
		jsr	(WinSetCursor)
		jsr	(WinReverseLine)
		addq	#1,d2			;y++
		jsr	(WinSetCursor)
		jbra	print_mark_information
mark_upper_end:
		rts


*************************************************
*		&mark-reverse			*
*************************************************

＆mark_reverse::
		moveq	#1,d0
		tst.b	(PATH_NODISK,a6)
		bmi	set_status		;メディア未挿入時は正常終了

		bsr	cursor_up_sub		;カーソルアップして
		bsr	set_status
		bra	mark_sub		;マーク
**		rts


* カーソル位置のファイルのマークを反転する.
* out	d0.l	0:error 1:OK

mark_sub::
		PUSH	d1-d7/a0-a5
		jbsr	search_cursor_file
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	mark_sub_error
		bsr	is_parent_directory_a4
		bne	mark_sub_error		;".." はマーク不可
@@:
		bchg	#MARK,(DIR_ATR,a4)	;マーク反転

		move.b	(write_disable_flag,opc),d0
		bne	mark_sub_end

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinReverseLine)
		jbsr	print_mark_information
mark_sub_end:
		moveq	#1,d0
@@:		POP	d1-d7/a0-a5
		rts
mark_sub_error:
		moveq	#0,d0
		bra	@b


* a4 の指すバッファが ".."(親ディレクトリ)であるか調べる.
* in	a4.l	ディレクトリバッファ
*	a6.l	パスバッファ
* out	d0.l	  0:".." ではない それ以外:".."
*	ccr	Z=1:".." ではない      Z=0:".."

is_parent_directory_a4::
		cmpa.l	(PATH_BUF,a6),a4
		bne	@f
		moveq	#0,d0
.if 0
		move.b	(PATH_DIRNAME+3,a6),d0
		or.b	(PATH_MARC_FLAG,a6),d0
.else
		move.b	(PATH_DOTDOT,a6),d0
.endif
		rts
@@:		moveq	#0,d0
		rts


*************************************************
*		&mark-all			*
*************************************************

＆mark_all::
		bsr	mark_all_sub
mark_all_job:
		bset	d5,(DIR_ATR,a4)
		bne	@f			;既にマークされていた
		moveq	#1,d6
@@:
		lea	(sizeof_DIR,a4),a4
		dbra	d7,mark_all_job
		rts


*************************************************
*		&mark-all-files			*
*************************************************

＆mark_all_files::
		bsr	mark_all_sub
mark_all_files_job:
		moveq	#1<<MARK+1<<DIRECTORY,d0
		and.b	(DIR_ATR,a4),d0
		bne	@f			;マーク済みかディレクトリは無視
		bset	d5,(DIR_ATR,a4)
		moveq	#1,d6
@@:
		lea	(sizeof_DIR,a4),a4
		dbra	d7,mark_all_files_job
		rts


*************************************************
*		&reverse-all-marks		*
*************************************************

＆reverse_all_marks::
		bsr	mark_all_sub
reverse_all_marks_job:
		bchg	d5,(DIR_ATR,a4)		;マーク反転
		lea	(sizeof_DIR,a4),a4
		dbra	d7,reverse_all_marks_job
		moveq	#1,d6			;画面再描画は絶対必要
		rts


*************************************************
*		&reverse-all-file-marks		*
*************************************************

＆reverse_all_file_marks::
		bsr	mark_all_sub
rev_all_file_marks_job:
		btst	d4,(DIR_ATR,a4)
		bne	@f			;ディレクトリは無視
		bchg	d5,(DIR_ATR,a4)		;マーク反転
		moveq	#1,d6
@@:
		lea	(sizeof_DIR,a4),a4
		dbra	d7,rev_all_file_marks_job
		rts


*************************************************
*		&clear-mark			*
*************************************************

＆clear_mark::
		bsr	mark_all_sub
clear_mark_job:
		tst.b	(DIR_ATR,a4)
		bpl	@f
		bchg	d5,(DIR_ATR,a4)		;マーク消去
		moveq	#1,d6
@@:
		lea	(sizeof_DIR,a4),a4
		dbra	d7,clear_mark_job
mark_all_end:
		rts


* オールマーク系処理
* in	(sp).l	メイン処理のアドレス

mark_all_sub:
		movea.l	(sp)+,a0		;メイン処理

		tst.b	(PATH_NODISK,a6)
		bmi.s	mark_all_end
		bsr	get_dir_buf_a4_d7
		subq	#1,d7
		bcs.s	mark_all_end

		moveq	#DIRECTORY,d4
		moveq	#MARK,d5
		moveq	#0,d6
		jsr	(a0)			;メイン処理呼び出し

		move.b	(write_disable_flag,opc),d0
		bne.s	mark_all_end
		tst	d6
		beq.s	mark_all_end

		jbsr	print_file_list
		jbsr	ReverseCursorBar
		jbra	print_mark_information
**		rts


*************************************************
*		&is-mark			*
*************************************************

＆is_mark::
		movea.l	(PATH_BUF,a6),a4
		tst.l	d7
		beq	is_mark_no_arg

		jsr	(atoi_a0)
		move.l	d0,d2
		subq.l	#1,d2			;0<=d0<$ENTRIES or d0=-1
		moveq	#0,d1
		move	(PATH_FILENUM,a6),d1
		moveq	#0,d0
		cmp.l	d1,d2
		bcc	is_mark_end		;数値が範囲外

		mulu	#sizeof_DIR,d2
		adda.l	d2,a4
		move.b	(DIR_ATR,a4),d1
		bpl	is_mark_end		;マーク無し
		not.b	d1
		beq	is_mark_end		;メディア無し
		bra	@f			;マーク有り
is_mark_no_arg:
		jbsr	search_mark_file
@@:		addq.l	#1,d0			;d0.l=1
is_mark_end:
		bra	set_status
**		rts


search_mark_file_next:
		lea	(sizeof_DIR,a4),a4
search_mark_file::
		move.b	(DIR_ATR,a4),d0		;マーク無しファイル
		bpl	search_mark_file_next
		not.b	d0
		beq	@f
		moveq	#0,d0			;マーク有り
		rts
@@:		moveq	#-1,d0			;マーク無し
		rts


* 返値と ccr は search_mark_file と同じ
search_mark_and_clr::
		bsr	search_mark_file
		bmi	@f
		bclr	#7,(DIR_ATR,a4)
@@:		tst	d0
		rts


* ファイル位置収得 ---------------------------- *

search_cursor_file::
		movea.l	(PATH_BUF,a6),a4
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	search_cursor_file_end

		PUSH	d0-d2
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinGetCursor)
		add	(PATH_PAGETOP,a6),d2	;最上段の表示ディレクトリ位置
		mulu	#sizeof_DIR,d2
		adda.l	d2,a4
		POP	d0-d2
search_cursor_file_end:
		rts


* カレントディレクトリ変更 -------------------- *

* $OLDPWD の変更に二段階のバッファを使用している.
* バッファが一つだけだと
*	$PWD -> $OLDPWD
*	PATH_DIRNAME 書き換え
*	chdir_routin 呼び出し
* という三段階の手順が必要だが、この方法だと
* 最初の行が省略できる.

chdir_routin::
		move.l	a2,-(sp)
		lea	(next_oldpwd),a1	;今までのカレントを $OLDPWD にセットする
		lea	(oldpwd_buf-next_oldpwd,a1),a2
		STRCPY	a1,a2

		lea	(PATH_DIRNAME,a6),a1
		jbsr	dos_chgdrv_a1
		lea	(a1),a0
		jbsr	to_mintslash_and_add_last_slash

		lea	(PATH_DIRNAME,a6),a1	;変更後のディレクトリを次回
		lea	(next_oldpwd),a2	;呼び出し時に $OLDPWD にセットする
		STRCPY	a1,a2

		tst.b	(PATH_MARC_FLAG,a6)
		bne	chdir_in_mintarc	;mintarc 内では移動/追加しない

;このあたりの処理、再考の必要あり
**@@:
		moveq	#0,d1
		jbsr	dos_drvctrl_d1
		btst	#DRV_INSERT,d0
		beq	chdir_routin_end	;メディア未挿入
		btst	#DRV_NOTREADY,d0
**		bne	@b			;not ready ならもう一度
		bne	chdir_routin_end	;オートイジェクトされないドライブ対策

		pea	(PATH_DIRNAME,a6)
		CHDIR_PRINT	'b'
		DOS	_CHDIR
		move.l	d0,(sp)+
		bpl	@f

		bsr	chdir_error
		bra	chdir_routin_end
@@:
		move	(PATH_WINRL,a6),d0
		lea	(PATH_DIRNAME,a6),a1
		jsr	(add_path_history)
		lea	(cur_dir_buf),a2	;フルパスのディレクトリ名
		STRCPY	a1,a2
		bra	@f

* 最後に展開されたファイルの存在するディレクトリ以外の
* ファイルのロードに失敗しないように、いろいろ補正する.
chdir_in_mintarc:
		jsr	(get_mintarc_dir)
		move.l	d0,-(sp)
		CHDIR_PRINT	'c'
		DOS	_CHDIR
		addq.l	#4,sp

		jsr	(mintarc_chdir_to_arc_dir)
@@:
		bsr	print_cplp_line
chdir_routin_end:
		movea.l	(sp)+,a2
		rts


* DOS _CHGDRV を発行する
* in	a1.l	ドライブ名("d:...")
dos_chgdrv_a1::
		move.l	d0,-(sp)
		moveq	#$20,d0
		or.b	(a1),d0
		subi.b	#'a',d0
		move	d0,-(sp)
		DOS	_CHGDRV
		addq.l	#2,sp
		move.l	(sp)+,d0
		rts


* パスデリミタ変換＋末尾に付加
to_mintslash_and_add_last_slash::
		bsr	call_to_mintslash
@@:
		tst.b	(a0)+
		bne	@b
		clr.b	(a0)
		move.b	(MINTSLASH,opc),-(a0)
		rts


* ディレクトリ表示関係 ------------------------ *


* ディレクトリ再読み込み＆表示
* in	a0.l	カーソル位置ファイル名(ASCIIZ 形式)
*		0 ならそのまま
* 備考:
*	カーソル表示あり.

directory_reload::
		PUSH	d0-d7/a0-a5
		move.l	a0,d0
		beq	@f
*		tst.b	(a0)
*		beq	@f
		lea	(PATH_CURFILE,a6),a1
		STRCPY	a0,a1			;カーソル位置ファイル名保存
@@:
		bsr	directory_reload1
		bsr	directory_reload2
		jbsr	ReverseCursorBar
		jbsr	print_drive_info
		POP	d0-d7/a0-a5
directory_rewrite_end:
		rts

* ディレクトリ再読み込み＆表示(反対側)
* カーソル表示なし
directory_reload_opp::
		PUSH	d0-d7/a0-a5
		movea.l	(PATH_OPP,a6),a6
		bsr	directory_reload1
		bsr	directory_reload2

		jbsr	reload_drive_info	;print_drive_info は駄目
		movea.l	(PATH_OPP,a6),a6
		POP	d0-d7/a0-a5
		rts

directory_reload1:
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinClearAll)
		moveq	#0,d1
		moveq	#0,d2
		jmp	(WinSetCursor)
**		rts

directory_reload2:
		jbsr	load_directory
		jbsr	gather_directory_top

		tst.b	(PATH_SORT,a6)
		beq	dir_reload2_no_sort
		jbsr	sort_directory		;ソート有り
		bra	@f
dir_reload2_no_sort:
		tst.b	(PATH_SORTREV,a6)	;ソート無し
		beq	@f
		jbsr	reverse_directory	;ソート無しリバース
@@:
		jbsr	cursor_to_curfile
		jbra	print_mark_information
**		rts


directory_rewrite::
		move.b	(write_disable_flag,opc),d0
		bne.s	directory_rewrite_end

		bsr	directory_reload1
		jbsr	cursor_to_curfile
		jbsr	ReverseCursorBar
		jbsr	print_mark_information
		jbra	reload_drive_info	;print_drive_info は駄目
**		rts


directory_write_routin_opp::
		movea.l	(PATH_OPP,a6),a6
		bsr	directory_write_routin
		movea.l	(PATH_OPP,a6),a6
@@:		rts


directory_write_routin::
		move.b	(write_disable_flag,opc),d0
		bne.s	@b
**@@:
		move	(PATH_DRIVENO,a6),d1
		bsr	dos_drvctrl_d1
		btst	#DRV_INSERT,d0
		beq	directory_write_nodisk	;メディア未挿入
		btst	#DRV_NOTREADY,d0
**		bne	@b			;not ready ならもう一度
		bne	directory_write_nodisk	;オートイジェクトされないドライブ対策

		bsr	is_disk2hd_drive
		beq	directory_write_go	;ハードディスクはチェック不要

* FDD の場合は「無効なメディア」帯攻撃をくらいやすいので
* エラー処理をフックしてディスクを読んでみる.
		move.l	a6,-(sp)		;無効メディアチェック
		move.l	sp,(stack_pointer)

		pea	(err_job,pc)
		move	#TRAP14_VEC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		move.l	d0,(old_err_job)

		pea	(floppy_eject,pc)
		move	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		move.l	d0,(old_err_abort)

		move.l	#$0001_0001,-(sp)	;読み込み位置/長さ
		move	(PATH_DRIVENO,a6),-(sp)
		pea	(Buffer)
		DOS	_DISKRED
		lea	(10,sp),sp

		move.l	(old_err_abort,pc),-(sp)
		move	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp

		move.l	(old_err_job,pc),-(sp)
		move	#TRAP14_VEC,-(sp)
		DOS	_INTVCS
		lea	(6+4,sp),sp		;+4 は push した a6 の分
* 帯びらなければ正常なメディア

directory_write_go:
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f
		bsr	chdir_dirname
		bpl	@f
		tst.b	(PATH_NODISK,a6)
		beq	@f

* メディアが挿入された時の表示で、元のディレクトリに
* 移動できなければルートに移動する
		clr.b	(PATH_DIRNAME+.sizeof.('a:/'),a6)
		bsr	chdir_dirname
@@:
		clr.b	(PATH_NODISK,a6)

		lea	(Buffer),a0		;クラスタ当りのバイト数収得
		move.l	a0,-(sp)
		clr	-(sp)
		DOS	_GETDPB
		addq.l	#6,sp
		moveq	#0,d0
		move.b	(DPB_CluSector,a0),d0
		addq	#1,d0
		mulu	(DPB_SecByte,a0),d0
		beq	@f
		subq.l	#1,d0			;クラスタ当りのバイト数-1
@@:		move.l	d0,(PATH_CLUSTER,a6)

		bsr	chdir_current_path_buf
		bsr	directory_reload1
		bsr	directory_reload2
		bsr	print_drive_path
		bsr	get_and_print_volume_label
		jbsr	reload_drive_info
directory_write_last:
		bsr	is_disk2hd_drive
		beq	@f
		pea	(save_fdaxsflag,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
@@:		rts

save_fdaxsflag:
		PUSH	a0-a1
		lea	(FDAXSFLAG),a0
		lea	(fdaxsflag,pc),a1
		move.l	(a0)+,(a1)+		;現在の状態を保存
		move.l	(a0)+,(a1)+
		POP	a0-a1
		rts

compare_fdaxsflag:
		PUSH	a0-a1
		lea	(FDAXSFLAG),a0
		lea	(fdaxsflag,pc),a1
		moveq	#0,d0
		cmpm.l	(a0)+,(a1)+
		bne	@f
		cmpm.l	(a0)+,(a1)+
@@:		sne	d0
		POP	a0-a1
		rts


* 指定したドライブが FDD か調べる
*	ドライブ番号による指定なので、仮想ディレクトリに
*	割り当てられたドライブを調べられない。
is_disk2hd_drive:
		PUSH	d0-d1
		move.l	(disk2hd_flag,pc),d0
		move	(PATH_DRIVENO,a6),d1
		btst	d1,d0
		POP	d0-d1
		rts


fdaxsflag:	.ds	4
disk2hd_flag:	.ds.l	1			;ビット=1:FDD

stack_pointer:	.ds.l	1
old_err_job:	.ds.l	1
old_err_abort:	.ds.l	1


* メディアアクセスでエラーが発生した場合
floppy_eject:
		move.l	(old_err_abort,pc),-(sp)
		move	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp

		move.l	(old_err_job,pc),-(sp)
		move	#TRAP14_VEC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp

		movea.l (stack_pointer,pc),sp
		move.l	(sp)+,a6

		move	(PATH_DRIVENO,a6),d1
		addi	#$0300,d1
		bsr	dos_drvctrl_d1		;排出許可
		subi	#$0300-$0100,d1
		bsr	dos_drvctrl_d1		;排出

directory_write_nodisk:
		bsr	print_not_insert_disk
		bra	directory_write_last	;フラグ初期化

err_job:
		cmpi	#$301f,d7
		beq	@f
		IOCS	_ABORTJOB
		rte
@@:		move	#1,d7			;NMI なら無視して再実行
		rte


* メディア未挿入時の処理 ---------------------- *

print_not_insert_disk:
		move.l	#1024-1,(PATH_CLUSTER,a6)

* 仮想ディレクトリの参照先がメディア未挿入でもルートに移動しない
*		clr.b	(PATH_DIRNAME+.sizeof.('a:/'),a6)

* 仮想ドライブで参照先がメディア未挿入だと
* 白帯が表示されてしまうので、移動しない
*		bsr	chdir_dirname		;カレントディレクトリをルートに移動

		lea	(cur_dir_buf),a1
		jbsr	dos_chgdrv_a1		;ドライブを元に戻す
		moveq	#$20,d0
		or.b	(a1),d0
		moveq	#$20,d1
		or.b	(PATH_DIRNAME,a6),d1
		cmp.b	d0,d1
		bne	@f

* cur_dir_buf と PATH_DIRNAME の指すドライブが
* 同じだった場合、cur_dir_buf もルートに書き換える.
		addq.l	#3,a1
		tst.b	(a1)
		beq	@f
		clr.b	(a1)
		bsr	print_cplp_line
@@:
		move	(PATH_WIN_VOL,a6),d0
		jsr	(WinClearAll)
		move	(PATH_WIN_INFO,a6),d0
		jsr	(WinClearAll)

		bsr	set_nodisk_media_type	;仮想ディレクトリ非対応
		bsr	print_drive_path

		move.b	(DpbBuffer+DPB_MediaByte),d0
		bsr	get_nodisk_message	;仮想ディレクトリ非対応
		jsr	(get_message)
		movea.l	d0,a1

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinClearAll)
		moveq	#0,d1
		move	(＄dirh),d2
		lsr	#1,d2
		jsr	(WinSetCursor)
		moveq	#BLUE,d1
		jsr	(WinSetColor)
		jsr	(WinPrint)
		moveq	#WHITE,d1
		jsr	(WinSetColor)

		st	(PATH_NODISK,a6)
		movea.l	(PATH_BUF,a6),a4
		bra	ld_set_end_of_pathbuf
**		rts


set_nodisk_media_type:
		move.l	a1,-(sp)
		move	(PATH_DRIVENO,a6),d1
		jbsr	dos_getdpb_cd
		bpl	@f
		clr.b	(DPB_MediaByte,a1)
@@:		movea.l	(sp)+,a1
		rts


* メディアバイトからディスク未挿入のメッセージ番号を取得する
* in	d0.b	メディアバイト
* out	d0.b	メッセージ番号(上位バイト破壊)

get_nodisk_message:
		cmpi.b	#$e0,d0
		bcc	@f
		st	d0			;とりあえず未定義のメディアバイト
@@:		ext	d0
		move.b	(get_nodisk_mes_table_end,pc,d0.w),d0
		rts

*get_nodisk_mes_table:
		.dc.b	MES_NODSK		;$e0 2DDx(2DD/10)
		.dc.b	MES_NO_DR		;$e1
		.dc.b	MES_NO_DR		;$e2
		.dc.b	MES_NO_DR		;$e3
		.dc.b	MES_NO_DR		;$e4
		.dc.b	MES_NODSK		;$e5 1D/9
		.dc.b	MES_NODSK		;$e6 2D/9
		.dc.b	MES_NODSK		;$e7 1D/8
		.dc.b	MES_NODSK		;$e8 2D/8
		.dc.b	MES_NODSK		;$e9 2HQx(2HQ16)
		.dc.b	MES_NODSK		;$ea 2HT
		.dc.b	MES_NODSK		;$eb 2HS
		.dc.b	MES_NODSK		;$ec 2HDE
		.dc.b	MES_NO_DR		;$ed
		.dc.b	MES_NODSK		;$ee 1DD/9
		.dc.b	MES_NODSK		;$ef 1DD/8
		.dc.b	MES_NO_DR		;$f0 DMF
		.dc.b	MES_NO_DR		;$f1
		.dc.b	MES_NO_DR		;$f2
		.dc.b	MES_NO_DR		;$f3 WindrvXM
		.dc.b	MES_NO_DR		;$f4 DAT / NFS
		.dc.b	MES_NO_CD		;$f5 CD-ROM
		.dc.b	MES_NO_MO		;$f6 MO
		.dc.b	MES_NO_DR		;$f7 SCSI-HD
		.dc.b	MES_NO_DR		;$f8 SASI-HD
		.dc.b	MES_NO_RD		;$f9 RAMDISK
		.dc.b	MES_NODSK		;$fa 2HQ
		.dc.b	MES_NODSK		;$fb 2DD/8
		.dc.b	MES_NODSK		;$fc 2DD/9
		.dc.b	MES_NODSK		;$fd 2HC
		.dc.b	MES_NODSK		;$fe 2HD
		.dc.b	MES_NO_DR		;$ff / $00～$df
get_nodisk_mes_table_end:
		.even


* カーソル位置補正 ---------------------------- *
* カーソルを、PATH_CURFILE に保存しておいた
* ファイルの位置に移動する.

cursor_to_curfile:
		PUSH	d0-d1/a0-a5
		lea	(-24,sp),sp
		lea	(PATH_CURFILE,a6),a0
		tst.b	(a0)
		beq	csr_to_curfile_error

		moveq	#sizeof_DIR,d1
		lea	(copy_dir_name_a1_a2),a3
		lea	(strcmp_a1_a2),a5
		movea.l (PATH_BUF,a6),a4
		bra	@f
csr_to_curfile_loop:
		adda.l	d1,a4			;lea (sizeof_DIR,a4),a4
@@:
		lea	(DIR_ATR,a4),a1
		cmpi.b	#-1,(a1)+
		beq	csr_to_curfile_error

**		lea	(DIR_NAME,a4),a1
		lea	(sp),a2
		jsr	(a3)			;copy_dir_name_a1_a2
		lea	(a0),a1
		jsr	(a5)			;strcmp_a1_a2
		bne	csr_to_curfile_loop

		move.l	a4,d0
		sub.l	(PATH_BUF,a6),d0
		divu	#sizeof_DIR,d0
**		andi.l	#$ffff,d0
		bra	@f
csr_to_curfile_error:
		moveq	#0,d0
@@:		bsr	goto_cursor_sub2

		lea	(24,sp),sp
		POP	d0-d1/a0-a5
		rts


* カレントディレクトリ設定 -------------------- *
* out	d0.l	DOS _CHDIR の返値

chdir_dirname:
		PUSH	d0/a1
		lea	(PATH_DIRNAME,a6),a1
		bra	@f
chdir_current_path_buf:
		PUSH	d0/a1
		lea	(cur_dir_buf),a1
@@:
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f

		jbsr	dos_chgdrv_a1
		move.l	a1,-(sp)
		CHDIR_PRINT	'd'
		DOS	_CHDIR
		move.l	d0,(sp)+
@@:
		POP	d0/a1
		rts


* ディレクトリ読み込み ------------------------ *

DOS_ARC_FILES:	.macro
		.local	dos_files,files_end
		tst.b	(PATH_MARC_FLAG,a6)
		beq	dos_files
		jsr	(marc_files)
		bra	files_end
dos_files:	DOS	_FILES
files_end:
		.endm

DOS_ARC_NFILES:	.macro
		.local	dos_nfiles,nfiles_end
		tst.b	(PATH_MARC_FLAG,a6)
		beq	dos_files
		jsr	(marc_nfiles)
		bra	nfiles_end
dos_files:	DOS	_NFILES
nfiles_end:
		.endm

LD_REGEXP_SIZE:	.equ	MASK_REGEXP_SIZE*4

		.offset	0
~ld_use_h:	.ds.l	1
~ld_use_l:	.ds.l	1
~ld_regexp_ptr:	.ds.l	1			;0ならマスクなし
~ld_regexp_buf:	.ds.b	LD_REGEXP_SIZE		;regexp compile buffer
~ld_files_buf:	.ds.b	FILES_SIZE
~ld_path:	.ds.b	64+24
		.even
sizeof_ld:
		.text


load_directory::
		lea	(-sizeof_ld,sp),sp
		lea	(sp),a5
		clr.l	(~ld_use_h,a5)
		clr.l	(~ld_use_l,a5)

		movea.l (PATH_BUF,a6),a4
		clr	(PATH_FILENUM,a6)

		clr.b	(PATH_DOTDOT,a6)
		move.b	(PATH_DIRNAME+3,a6),d0
		or.b	(PATH_MARC_FLAG,a6),d0
		beq	@f
		tst	(＄dotn)
		bmi	@f			;".." は登録しない

		move.b	#1<<DIRECTORY,(~ld_files_buf+FILES_FileAtr,a5)
		move.l	#'..'<<16,(~ld_files_buf+FILES_FileName,a5)
		bsr	ld_add_file_entry
		st	(PATH_DOTDOT,a6)
@@:
		lea	(PATH_DIRNAME,a6),a1
		lea	(~ld_path,a5),a2	;検索名称バッファ
		STRCPY	a1,a2
		subq.l	#1,a2
		move.l	a2,d5			;d:/foo/[*].*
		lea	(wildcard_all,pc),a1
		STRCPY	a1,a2

		move	#$ff.xor.(1<<VOLUME),-(sp)
		pea	(~ld_path,a5)
		pea	(~ld_files_buf,a5)
		DOS_ARC_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	ld_end

		lea	(~ld_regexp_buf,a5),a0
		bsr	ld_compile_mask_pattern
		move.l	a0,(~ld_regexp_ptr,a5)

* 今のところループ内で d6-d7 未使用
ld_next:
		bsr	ld_is_pare_or_cur_dir
		beq	ld_skip
		btst	#VOLUME,(~ld_files_buf+FILES_FileAtr,a5)
		bne	ld_skip

		bsr	ld_add_filesize_total	;表示しないファイルでもサイズは加算する

		bsr	ld_is_secret_file
		beq	ld_skip

		btst	#LINK,(~ld_files_buf+FILES_FileAtr,a5)
		beq	@f
		bsr	ld_chmod_link_file
@@:
		btst	#DIRECTORY,(~ld_files_buf+FILES_FileAtr,a5)
		bne	@f			;ディレクトリは常に表示する
		move.l	(~ld_regexp_ptr,a5),d0
		beq	@f			;マスクなし

;マスク指定時は一致するか調べる
		pea	(~ld_files_buf+FILES_FileName,a5)	;string
		move.l	d0,-(sp)		;compiled pattern
		jsr	(_fre_match)
		addq.l	#8,sp
		tst.l	d0
		beq	ld_skip			;マスクパターンに一致しなかった
@@:
		bsr	ld_add_file_entry
ld_skip:
		pea	(~ld_files_buf,a5)
		DOS_ARC_NFILES
		move.l	d0,(sp)+
		bpl	ld_next

		move	(PATH_FILENUM,a6),d0
		cmp	(file_entry_max,pc),d0
		bne	ld_end

		jbsr	SetColor2		;ファイル数が%dirsより多い
		moveq	#MES_DIRSL,d0		;(ぎりぎりでも表示してしまう^^;)
		tst	(PATH_WINRL,a6)
		beq	@f
		moveq	#MES_DIRSR,d0
@@:		jbsr	PrintMsgCrlf
		jbsr	SetColor3
ld_end:
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f
		move.l	(~ld_use_h,a5),d0
		move.l	(~ld_use_l,a5),d1
		bsr	set_path_use_byte	;合計容量を文字列にしてセット
@@:
		lea	(sizeof_ld,sp),sp

ld_set_end_of_pathbuf:
**		st	(DIR_ATR,a4)
		move.l	#$ff<<24+':NO',(a4)+	;ダミーのファイル名をセット
		move.l	#'DISK',(a4)+		;ちゃんとセットしてないけど
		move	#':'<<8,(a4)+		;多分問題ない筈
		rts

ld_is_pare_or_cur_dir:
		move	(~ld_files_buf+FILES_FileName,a5),d0
		cmpi	#'.'<<8,d0
		beq	@f
		cmpi	#'..',d0
		bne	@f
		tst.b	(~ld_files_buf+FILES_FileName+2,a5)
@@:		rts

ld_chmod_link_file:
		lea	(~ld_files_buf+FILES_FileName,a5),a1
		movea.l	d5,a2
		STRCPY	a1,a2

		lea	(-FILES_SIZE,sp),sp
		move	#1<<DIRECTORY,-(sp)
		pea	(~ld_path,a5)		;d:/foo/linkname
		pea	(6,sp)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	ld_chmod_link_file_end

		bset	#DIRECTORY,(~ld_files_buf+FILES_FileAtr,a5)
ld_chmod_link_file_end:
		lea	(FILES_SIZE,sp),sp
		rts

ld_is_secret_file:
		move.b	(~ld_files_buf+FILES_FileAtr,a5),d0
		btst	#HIDDEN,d0
		beq	@f
		tst	(＄hidn)
		beq	9f
@@:
		btst	#SYSTEM,d0
		beq	@f
		tst	(＄sysn)
		beq	9f
@@:
		cmpi.b	#'.',(~ld_files_buf+FILES_FileName,a5)
		bne	9f
		tst.b	(＄dotn+1)
9:		rts

ld_add_file_entry:
		move	(PATH_FILENUM,a6),d0
		cmp	(file_entry_max,pc),d0
		beq	ld_add_file_entry_skip

		move.b	(~ld_files_buf+FILES_FileAtr,a5),d0
		bpl	ld_add_file_entry_noexec
.if 0
		andi.b	#.low..not.(1<<EXEC+1<<ARCHIVE),d0
.else
		bclr	#EXEC,d0
		btst	#DIRECTORY,d0
		bne	@f
		bclr	#ARCHIVE,d0		;実行属性はアーカイブ属性オフで表す
.endif
		bra	@f
ld_add_file_entry_noexec:
		btst	#DIRECTORY,d0
		bne	@f			;実行属性のないファイルは
		bset	#ARCHIVE,d0		;常にアーカイブ属性をセットする
@@:
		move.b	d0,(a4)+		;DIR_ATR
		lea	(~ld_files_buf+FILES_FileName,a5),a1
		lea	(DIR_NAME-1,a4),a2
		bsr	set_dir_name		;DIR_NAME/PERIOD/EXT/NUL
		lea	(DIR_TIME-1,a4),a4
		move.l	(~ld_files_buf+FILES_Time,a5),(a4)+	;DIR_TIME/DATE
		move.l	(~ld_files_buf+FILES_FileSize,a5),(a4)+	;DIR_SIZE
		move	(PATH_FILENUM,a6),(a4)+			;DIR_SERNO
		clr	(a4)+					;DIR_RESERVED

		addq	#1,(PATH_FILENUM,a6)
ld_add_file_entry_skip:
		rts

ld_add_filesize_total:
		btst	#DIRECTORY,(~ld_files_buf+FILES_FileAtr,a5)
		bne	9f

		move.l	(~ld_files_buf+FILES_FileSize,a5),d0
		move.l	(PATH_CLUSTER,a6),d1
		beq	@f
		or.l	d1,d0
		addq.l	#1,d0			;クラスタ単位に切り上げる
		bcc	@f
		addq.l	#1,(~ld_use_h,a5)	;$1_0000_0000になってしまった
@@:
		add.l	d0,(~ld_use_l,a5)
		bcc	9f
		addq.l	#1,(~ld_use_h,a5)	;繰り上がり
9:		rts


* マスクパターンをコンパイルする
* in	a0.l	バッファアドレス
* out	a0.l	〃(0 ならコンパイルエラー)

ld_compile_mask_pattern:
		PUSH	d1-d2/a1-a3
		lea	(a0),a3			;buffer
		lea	(-MASK_REGEXP_SIZE,sp),sp
		lea	(sp),a1

		movea.l	(PATH_MASK,a6),a0
		move.l	(a0)+,(_ignore_case)
		tst.b	(a0)
		beq	ld_compile_mask_pattern_no_mask

		moveq	#SPACE,d1
ld_compile_mask_pat_cploop:
		move.b	(a0)+,d0		;"foo bar"→"foo|bar"
		cmp.b	d0,d1
		bne	ld_compile_mask_pat_cpchar

		move.b	#'|',(a1)+
@@:
		move.b	(a0)+,d0
		cmp.b	d0,d1
		beq	@b
ld_compile_mask_pat_cpchar:
		move.b	d0,(a1)+
		bne	ld_compile_mask_pat_cploop
ld_compile_mask_pat_cpend:
		move.l	sp,-(sp)		;pattern
		pea	(LD_REGEXP_SIZE/2)	;size
		pea	(a3)			;buffer
		jsr	(_fre_compile)
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		beq	ld_compile_mask_pattern_ok

		bsr	print_regexp_compile_error
ld_compile_mask_pattern_no_mask:
		suba.l	a3,a3
ld_compile_mask_pattern_ok:
		lea	(MASK_REGEXP_SIZE,sp),sp
		movea.l	a3,a0
		POP	d1-d2/a1-a3
		rts

print_regexp_compile_error::
		move.l	d0,-(sp)		;返値がNULLでなければエラーメッセージ
		DOS	_PRINT
		addq.l	#4,sp
		jbra	PrintCrlf
**		rts

file_entry_max:
		.dc	0


* DIR_NAME～DIR_EXT にファイル名を格納する.
* in	a1.l	ファイル名
*	a2.l	バッファ(DIR_NAME)
* break	d0-d1/a0-a2

set_dir_name::
		move.b	(a1)+,(a2)+
		lea	(a1),a0
		moveq	#'.',d1
s_d_n_loop:
		move.b	(a0)+,d0
		beq	s_d_n_no_ext
		cmp.b	d1,d0
		bne	s_d_n_loop
		pea	(18,a1)
		cmp.l	(sp)+,a0
		bcc	s_d_n_ext		;ノード名が 18 文字なら残りは拡張子

		move.b	(0,a0),d0		;本当に拡張子か調べる
		beq	s_d_n_no_ext
		cmp.b	d1,d0
		beq	s_d_n_loop
		move.b	(1,a0),d0
		beq	s_d_n_ext
		cmp.b	d1,d0
		beq	s_d_n_loop
		move.b	(2,a0),d0
		beq	s_d_n_ext
		cmp.b	d1,d0
		beq	s_d_n_loop
		tst.b	(3,a0)
		bne	s_d_n_loop
s_d_n_ext:
		move.l	a0,d0
		sub.l	a1,d0
		moveq	#18,d1
		sub	d0,d1			;空白の個数
		subq	#2,d0
		bcs	1f
@@:
		move.b	(a1)+,(a2)+
		dbra	d0,@b
1:
		moveq	#SPACE,d0
		subq	#1,d1
		bcs	1f
@@:
		move.b	d0,(a2)+
		dbra	d1,@b
1:
		move.b	(a1)+,(a2)+		;'.'
		moveq	#3-1,d1
		bra	@f
s_d_n_no_ext:
		moveq	#18+3-1,d1
@@:
		move.b	(a1)+,(a2)+
		dbeq	d1,@b
		bne	s_d_n_end
		subq.l	#1,a2
		moveq	#SPACE,d0
@@:
		move.b	d0,(a2)+
		dbra	d1,@b
s_d_n_end:
		clr.b	(a2)			;DIR_NUL
		rts


* パスのファイル使用容量をセットする ---------- *
* in	d0:d1	ファイルの合計容量(ディレクトリの場合)
*		書庫内全データの圧縮時サイズ(mintarcの場合)
*	a6.l	パスバッファ

* PATH_USE_UNIT	単位(0=K or 'M'/'G'/'T'/'P')
* PATH_USE_XPOS	表示位置 10(6桁)～15(1桁)
* PATH_USE_STR	文字列 '1'～'999999'/'999.99'

set_path_use_byte::
		PUSH	d0-d1/d3/d6-d7/a0
		move.l	d0,d6
		move.l	d1,d7

		move.l	#999999,d3
		lea	(PATH_USE_STR,a6),a0
		bsr	set_path_use_sub
		addi	#DRV_INF_USE,d1		;右寄せの表示位置
		move.b	d3,(PATH_USE_UNIT,a6)	
		move.b	d1,(PATH_USE_XPOS,a6)

		POP	d0-d1/d3/d6-d7/a0
		rts

* 下請け
* in	d3.l	キロバイトで表示する場合の上限値(999,999 or 9,999,999)
*	d6:d7	バイト数
*	a0.l	バッファ
* out	d1.w	-桁数(-1～-7)
*	d3.b	単位(0=K or 'M'/'G'/'T'/'P')

set_path_use_sub:
		move.l	a0,d1

		jbsr	lsr10_d6d7		;まずキロバイト単位にする
		tst.l	d6
		bne	@f
		cmp.l	d3,d7			;なるべく今までと同じ表示にするため、
		bls	set_path_use_sub_kb	;999999K or 9999999K まではキロバイトにする
@@:
;999.99M 999.99G 999.99T 999.99P
;メガ／ギガ／テラ／ペタバイトへの変換を行う
;小数部はあとで表示に使うので、ここでは1024倍した値にする
@@:
		move.l	#'PTGM',d3
1:
		tst.l	d6
		bne	@f
		cmpi.l	#1000*1024,d7
		bcs	9f
@@:
		bsr	lsr10_d6d7		;次の単位に換算
		lsr.l	#8,d3			;次の単位記号
		bra	1b
9:
;この時点で d6=0 d7<1000*1024

;M/G/T/P バイト表示は整数3桁＋小数2桁
		move.l	d7,d0
		moveq	#10,d2
		andi	#1024-1,d7		;端数

		lsr.l	d2,d0			;÷1024
		FPACK	__LTOS

		mulu	#100,d7
		lsr.l	d2,d7			;÷1024
		divu	#10,d7
		move.b	#'.',(a0)+
		addi.l	#'0'<<16+'0',d7
		move.b	d7,(a0)+
		swap	d7
		move.b	d7,(a0)+
		clr.b	(a0)
		bra	set_path_use_sub_end
set_path_use_sub_kb:
		move.l	d7,d0
		FPACK	__LTOS
		moveq	#0,d3			;K
set_path_use_sub_end:
		sub.l	a0,d1			;-桁数
		rts


* パスの空き容量と比率をセットする ------------ *
* in	d0:d1	ディスクの空き容量(ディレクトリの場合)
*		書庫内全データの展開時サイズ(mintarcの場合)
*	d2:d3	ディスクの総容量(ディレクトリの場合)
*		書庫内全データの圧縮時サイズ(mintarcの場合)
*	a6.l	パスバッファ

* PATH_FREE_UNIT	単位(0=K or 'M'/'G'/'T'/'P')
* PATH_FREE_XPOS	表示位置 21(7桁)～27(1桁)
* PATH_FREE_STR		文字列 '1'～'9999999'/'999.99'
* PATH_FRE_RATIO	比率 ' 1'～'99'/'100'

set_path_free_byte_ratio::
		PUSH	d0-d3/d5-d7/a0
		move.l	d0,d6
		move.l	d1,d7

;まず比率 {d0:d1 ÷ d2:d3} × 100(%) を計算
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		exg	d0,d2			;mintarcの場合は逆になる
		exg	d1,d3
@@:
		move.l	d0,d5
		or.l	d2,d5
		beq	@f

		move	d0,d1			;64bit値を16bit右シフト
		move	d2,d3
		clr	d0
		clr	d2
		swap	d1
		swap	d3
		swap	d0
		swap	d2
		bra	@b
@@:
		moveq	#1,d0			;この時点で d0、d2 == 0
		swap	d0			;$0001_0000
		bra	1f
@@:
		lsr.l	#4,d1			;32bit値を4bit右シフト
		lsr.l	#4,d3
1:		cmp.l	d0,d3
		bcc	@b

		tst	d3
		bne	@f
		moveq	#1,d3			;0除算回避
@@:		cmp	d3,d1
		bls	@f
		move	d3,d1			;空き容量の方が大きい(異常な数値)
@@:
		moveq	#100,d0
		mulu	d1,d0
		divu	d3,d0
		ext.l	d0

		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		tst	(＄arcr)
		bne	@f

		subi	#100,d0			;圧縮率の意味を逆にする
		neg	d0
@@:
		moveq	#2,d1			;100%の時は3桁になる
		lea	(PATH_FRE_RATIO,a6),a0
		FPACK	__IUSING

;空き容量を文字列化
		move.l	#9999999,d3
		lea	(PATH_FRE_STR,a6),a0
		bsr	set_path_use_sub
		addi	#DRV_INF_FREE,d1	;右寄せの表示位置
		move.b	d3,(PATH_FRE_UNIT,a6)	
		move.b	d1,(PATH_FRE_XPOS,a6)

		POP	d0-d3/d5-d7/a0
		rts


* ディレクトリを先頭に集める ------------------ *
* load_directory で dir/file 別々に検索する方法もあるが、
* ルーチンが独立していた方が良さそうなので、後からソート.

gather_directory_top::
		tst.b	(PATH_SORT,a6)
		bne	gather_directory_top_end
		tst	(＄sort)
		bne	gather_directory_top_end

		bsr	get_dir_buf_a4_d7
		subq	#1,d7
		bls	gather_directory_top_end
		moveq	#DIRECTORY,d5
		bra	@f
gather_dir_skip_dir_loop:
		lea	(sizeof_DIR,a4),a4
@@:		btst	d5,(DIR_ATR,a4)
		dbeq	d7,gather_dir_skip_dir_loop
		bne	gather_directory_top_end
;a4=file
;d7=エントリ数-1
		moveq	#sizeof_DIR,d0
		mulu	d7,d0
		beq	gather_directory_top_end
		lea	(a4,d0.l),a0
		bra	@f
gather_dir_skip_file_loop:
		lea	(-sizeof_DIR,a0),a0
@@:		btst	d5,(DIR_ATR,a0)
		dbne	d7,gather_dir_skip_file_loop
		beq	gather_directory_top_end

;この時点で a4=file ... dir となっている
		moveq	#sizeof_DIR,d0		;dbcc用カウンタだから1少ないけど
		mulu	d7,d0			;最低1個はdirなので足りる
		beq	gather_directory_top_end
		move.l	d0,-(sp)		;ファイル待避用バッファを確保
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	gather_directory_top_end

		movea.l	d0,a0
		lea	(a0),a1			;a1=file write
		lea	(a4),a2			;a2=dir write
		moveq	#-1,d6			;ファイル数-1
gather_dir_loop1:
		btst	d5,(DIR_ATR,a4)
		bne	gather_dir_dir
*gather_dir_file:
	.rept	sizeof_DIR/4
		move.l	(a4)+,(a1)+		;ファイルを待避
	.endm
		addq	#1,d6
		dbra	d7,gather_dir_loop1
*		bra	@f			;ファイルで終わる事はないので不要

gather_dir_dir:
	.rept	sizeof_DIR/4
		move.l	(a4)+,(a2)+		;ディレクトリを前に詰める
	.endm
		dbra	d7,gather_dir_loop1
*@@:
		lea	(a0),a1			;a1=file read
gather_dir_loop2:
	.rept	sizeof_DIR/4
		move.l	(a1)+,(a2)+		;ファイルを後に並べる
	.endm
		dbra	d6,gather_dir_loop2

		move.l	a0,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
gather_directory_top_end:
		rts

* ディレクトリバッファのアドレス/エントリ数を得る.
* ただし、先頭が ".." ならそれは飛ばす.
* out	d7.w	残りエントリ数
*	a4.l	ディレクトリバッファ

get_dir_buf_a4_d7::
		movea.l	(PATH_BUF,a6),a4
		move	(PATH_FILENUM,a6),d7
.if 0
		move.b	(PATH_DIRNAME+3,a6),d0
		or.b	(PATH_MARC_FLAG,a6),d0
.else
		tst.b	(PATH_DOTDOT,a6)
.endif
		beq	@f
		subq	#1,d7
		lea	(sizeof_DIR,a4),a4
@@:		rts


*************************************************
*		&toggle-drive-information	*
*************************************************

＆toggle_drive_information::
		move	(PATH_DRIVENO,a6),d0	;A=1, B=2...
		add	d0,d0
		lea	(＄infA-2),a0
		adda	d0,a0
		moveq	#1,d0
		and	d0,(a0)
		eor	d0,(a0)

		bra	reload_drive_info2	;面倒なので両方とも再表示
**		rts


* 左右ウィンドウが同じドライブか調べる
* in	a6.l	パスバッファ
* out	d0.w	カーソル側ウィンドウのドライブ番号(PATH_DRIVENO)
*	ccr	Z=1:同じドライブ Z=0:違うドライブ
* 備考:
*	現在未使用.
.if 0
is_same_drive:
		move	(PATH_DRIVENO,a6),d0
		movea.l	(PATH_OPP,a6),a6
		cmp	(PATH_DRIVENO,a6),d0
		movea.l	(PATH_OPP,a6),a6
		rts
.endif


*************************************************
*		&information			*
*************************************************

＆information::
		lea	(＄finf),a0
		addq	#1,(a0)
		cmpi	#2,(a0)
		bls	reload_drive_info2
		clr	(a0)			;0 -> 1 -> 2 -> 0...
reload_drive_info2:
		movea.l	(PATH_OPP,a6),a6
		bsr	reload_drive_info
		movea.l	(PATH_OPP,a6),a6
		bra	reload_drive_info
**		rts


* ドライブ情報(空き容量)を調べて、表示する.
* 空き容量が変化した可能性がある場合はここを呼び出さなければならない.
* それ以外は直接 print_drive_info を呼んでよい.

reload_drive_info::
		tst.b	(PATH_MARC_FLAG,a6)
		bne	reload_drive_info_end
		jbsr	get_drive_info_mode
		beq	reload_drive_info_end

		PUSH	d1-d7/a0-a6
		lea	(-64,sp),sp
		lea	(sp),a2
		bsr	mount_prepare
rel_drv_info_loop:
		lea	(sp),a2			;カレントディレクトリ
		jbsr	mount_compare
		bne	rel_drv_info_next

		bsr	mount_unset
		bmi	rel_drv_info_error

		pea	(dskfree_buf,pc)
		move	d7,-(sp)
		DOS	_DSKFRE
		addq.l	#6,sp
		bsr	mount_restore
		bra	rel_drv_info_set
rel_drv_info_error:
		clr.b	(a1)			;仮想ディレクトリではなかった
rel_drv_info_next:
		lea	(64,a1),a1
		addq.b	#1,d7
		cmpi.b	#26+1,d7
		bne	rel_drv_info_loop

		bsr	chdir_dirname
		pea	(dskfree_buf,pc)
		clr	-(sp)
		DOS	_DSKFRE
		addq.l	#6,sp
		bsr	chdir_current_path_buf
rel_drv_info_set:
		lea	(64,sp),sp
		POP	d1-d7/a0-a6

		movem	(dskfree_buf,pc),d0-d3
		mulu	d2,d3			;クラスタ当りのバイト数

		move	d1,d2
		mulu	d3,d1			;d1.l = バイト数×総クラスタ数(下位word)
		swap	d3
		mulu	d3,d2			;d0.l = バイト数×総クラスタ数(上位word)
		move.l	d1,-(sp)
		clr.l	-(sp)
		add.l	d2,(2,sp)
		bcc	@f
		addq	#1,(sp)			;sp～ 総バイト数
@@:
		move	d0,d2
		mulu	d3,d0			;d1.l = バイト数×空きクラスタ数(上位word)
		swap	d3
		mulu	d3,d2			;d0.l = バイト数×空きクラスタ数(下位word)
		move.l	d2,-(sp)
		clr.l	-(sp)
		add.l	d0,(2,sp)
		bcc	@f
		addq	#1,(sp)			;sp～ 空きバイト数
@@:
		movem.l	(sp)+,d0-d1/d2-d3	;空き容量・比率を文字列にしてセット
		bsr	set_path_free_byte_ratio
reload_drive_info_end:
		bra	print_drive_info
**		rts

dskfree_buf:	.ds	4


* ドライブ情報を表示するか調べる.
* out	ccr	Z=1:表示しない Z=0:表示する

get_drive_info_mode:
		PUSH	d0/a0
		cmpi.b	#-1,(PATH_NODISK,a6)	;tst.b/bmi は駄目(ccrZ を返すので)
		beq	@f			;メディア未挿入なら無表示
		tst	(＄finf)
		beq	@f			;全ドライブ無表示
		move	(PATH_DRIVENO,a6),d0
		add	d0,d0
		lea	(＄infA),a0
		cmpi	#1,(-2,a0,d0.w)		;%inf? 1 ならそのドライブは無表示
@@:
		POP	d0/a0
		rts


* ドライブ情報を表示する ---------------------- *
* 初回は reload_drive_info を呼び出してバッファに
* 情報をセットしておくこと.

		.offset	0
		.dc.b	'     '
DRV_INF_FILE:	.dc.b	'Files      '
DRV_INF_USE:	.dc.b	'KBuse       '
DRV_INF_FREE:	.dc.b	'KB('
DRV_INF_RATIO:	.dc.b	'  %)Free ['
DRV_INF_TYPE:	.dc.b	'    ]'
		.text


print_drive_info::
		PUSH	d7/a5
		move.b	(write_disable_flag,opc),d0
		bne	print_drive_info_end

		move	(PATH_WIN_INFO,a6),d7
		lea	(TempBuffer),a5
**		lea	(DpbBuffer),a5

		move	d7,d0
		jsr	(WinClearAll)

		bsr	get_drive_info_mode
		beq	print_drive_info_end

		moveq	#0,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		move	(＄dicl),d1
		jsr	(WinSetColor)

;テンプレートの表示
		moveq	#MES_INFO2,d0
		cmpi	#2,(＄finf)
		beq	@f			;%finf 2 なら device type のみ

		moveq	#MES_INFOM,d0		;ファイル数/使用容量も表示する
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		moveq	#MES_MINFO,d0		;mintarc
@@:
		jsr	(get_message)
		movea.l	d0,a1

		move.b	(PATH_USE_UNIT,a6),d0
		or.b	(PATH_FRE_UNIT,a6),d0
		beq	@f

		lea	(a5),a0			;単位書き換え
		STRCPY	a1,a0
		bsr	print_drive_info_change_unit
		lea	(a5),a1
@@:
		move	d7,d0
		jsr	(WinPrint)

;デバイスタイプの表示
		moveq	#WHITE,d3
		moveq	#2,d2
		tst.b	(PATH_MARC_FLAG,a6)
		bne	print_drive_info_dskid	;dskid[2]=mintarc

		move	(PATH_DRIVENO,a6),d0
		bsr	get_assign_mode
		moveq	#1,d2
		moveq	#VIRDRV,d1
		cmp.l	d0,d1
		beq	print_drive_info_dskid	;dskid[1]=仮想ドライブ

		move	(PATH_DRIVENO,a6),d1
		bsr	dos_drvctrl_d1
		btst	#DRV_PROTECT,d0
		beq	@f
		moveq	#YELLOW,d3		;write protect時は色を変える
@@:
		jbsr	dos_getdpb_cd
		bmi	print_drive_info_other	;エラーにはならない筈だけど念の為

		moveq	#0,d2
		move.b	(DPB_MediaByte,a1),d2
		cmpi.b	#MB_MO,d2
		bne	@f
		tst	(＄dtmo)
		beq	@f			;%dtmo 0 なら単に[ MO ]表示

* MO ディスクのフォーマット別表示
		GETMES	MES_DSKMO
		movea.l	d0,a0
		bsr	get_mo_disk_type
		adda.l	d0,a0
		bra	print_drive_info_set
@@:
		moveq	#MES_DSKF0,d0
		addi.b	#$10,d2
		bcs	print_drive_info_get	;$f0～$ff
		moveq	#MES_DSKE0,d0
		addi.b	#$10,d2
		bcs	print_drive_info_get	;$e0～$ef

print_drive_info_other:
		moveq	#0,d2			;dskid[0]=それ以外
print_drive_info_dskid:
		moveq	#MES_DSKID,d0
print_drive_info_get:
		jsr	(get_message)
		movea.l	d0,a0
		lsl	#2,d2
		adda	d2,a0
print_drive_info_set:
		subq.l	#6,sp
		lea	(sp),a1
	.rept	4
		move.b	(a0)+,(a1)+		;id-name 4byte
	.endm
		clr.b	(a1)

		move	d7,d0
		moveq	#DRV_INF_TYPE,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		move	d3,d1
		jsr	(WinSetColor)
		lea	(sp),a1
		jsr	(WinPrint)
		addq.l	#6,sp

		cmpi	#2,(＄finf)		;%finf 2 なら
		beq	print_drive_info_end	;device type を表示したら終わり

;ファイル数の表示
		moveq	#0,d0
		move	(PATH_FILENUM,a6),d0
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		jsr	(get_mintarc_file_num)
@@:
		lea	(a5),a0
		FPACK	__LTOS
		suba.l	a5,a0			;桁数

		move	d7,d0
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		moveq	#DRV_INF_FILE,d1
		sub	a0,d1			;表示位置
		moveq	#0,d2
		jsr	(WinSetCursor)
		lea	(a5),a1
		jsr	(WinPrint)

;使用容量の表示
		move	d7,d0
		moveq	#0,d1
		move.b	(PATH_USE_XPOS,a6),d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		lea	(PATH_USE_STR,a6),a1
		jsr	(WinPrint)

;空き容量の表示
		move	d7,d0
		move.b	(PATH_FRE_XPOS,a6),d1
		jsr	(WinSetCursor)
		lea	(PATH_FRE_STR,a6),a1
		jsr	(WinPrint)

;空き容量の比率の表示
		move	d7,d0
		moveq	#DRV_INF_RATIO,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		lea	(PATH_FRE_RATIO,a6),a1
		jsr	(WinPrint)

print_drive_info_end:
		POP	d7/a5
		rts


* MO ディスクのフォーマット判別
* in	a1.l	DPB
* out	d0.l	0:Human68k
*		4:IBM
*		8:セミIBM

get_mo_disk_type:
		cmpi.b	#$80,(DPB_SecShift,a1)
		bcs	get_mo_disk_type_h68k	;最上位ビット=0:Human68k フォーマット
		beq	get_mo_disk_type_ibm	;最上位ビット=1:IBM フォーマット
		cmpi	#FAT16_CLUSTER_MAX/2,(DPB_FatMax,a1)
		bcc	get_mo_disk_type_ibm
*get_mo_disk_type_semi_ibm:			;クラスタ数が上限の半分以下なのに、
		moveq	#8,d0			;クラスタあたりのセクタ数を大きく
		rts				;していれば、セミIBMフォーマット
get_mo_disk_type_ibm:
		moveq	#4,d0
		rts
get_mo_disk_type_h68k:
		moveq	#0,d0
		rts


* 使用容量・空き容量の単位がキロバイト以外なら書き換える
* in	a5.l	バッファ
* break	d0/a0-a1

print_drive_info_change_unit:
		moveq	#0,d0

		lea	(PATH_FRE_UNIT,a6),a0	;単位
		lea	(DRV_INF_FREE,a5),a1	;元の文字
		bsr	@f

		.fail	DRV_INF_FREE<DRV_INF_USE
		lea	(PATH_USE_UNIT,a6),a0
		lea	(DRV_INF_USE,a5),a1
@@:
		tst.b	(a0)
		beq	9f
		move.b	(a1),d0
		move.b	(a0),(a1)+		;[MGTP] に書き換える

		jbsr	get_ctype		;元の文字が
		bpl	9f			;1バイト文字
**		btst	#IS_MBHALF,d0
		add.b	d0,d0
		bmi	@f
;2バイト文字
		move.b	#'B',(a1)		;'Ｋ' -> 'MB'
9:		rts

;2バイト半角文字
@@:		move.b	(a1)+,(-2,a1)		;下位バイトを消す
		bne	@b
		rts


* 指定ドライブのマウント状態を調べる ---------- *
* in	d0.b	ドライブ番号(1=a: 2=b: ... 26=z:)
* out	d0.l	$40:実ドライブ $50:仮想ドライブ $60:仮想ディレクトリ
*		$00:未使用ドライブ その他:エラー

get_assign_mode:
		move.l	#('A'-1)<<24+':'<<16,-(sp)
		add.b	d0,(sp)

		lea	(-64,sp),sp
		move.l	sp,-(sp)
		pea	(64+4,sp)
		clr	-(sp)			;ASSIGN_GET
		DOS	_ASSIGN

		lea	(10+64+4,sp),sp
print_drive_path_end:
		rts


* ドライブパス名表示 -------------------------- *
* 画面三行目にパス名＋パスマスクを表示する.

print_drive_path:
		move.b	(write_disable_flag,opc),d0
		bne.s	print_drive_path_end

		lea	(-(64+MASK_REGEXP_SIZE),sp),sp
		lea	(PATH_DIRNAME,a6),a1
		lea	(sp),a2
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f

		bsr	copy_pathname_zdrv	;通常ディレクトリ d:/dir/mask.*
		bra	add_path_mask
@@:
		tst	(＄vocl)		;%vocl 0x800? なら書庫ファイル名は
		bmi	@f			;二行目に表示するので、三行目には不要
		tst.b	(.sizeof.('a:/'),a1)
		beq	print_dp_marc_root
@@:
		addq.l	#.sizeof.('a:'),a1	;書庫内サブディレクトリ /dir/mask.*
		STRCPY	a1,a2			;
		subq.l	#1,a2
		bra	add_path_mask
print_dp_marc_root:
		jsr	(get_mintarc_filename)	;書庫内ルート d:/dir/arc.zip/mask.*
		movea.l	d0,a1
		bsr	copy_pathname_zdrv
		move.b	(MINTSLASH,opc),(a2)+
		bra	add_path_mask

add_path_mask:
		movea.l	(PATH_MASK,a6),a1
		addq.l	#4,a1
		move.b	#'*',(a2)+
		move.b	(a1),(a2)
		beq	add_path_mask_all	;未設定なら"*"

		subq.l	#1,a2			;設定されていればそれを表示
		STRCPY	a1,a2
add_path_mask_all:
		move	(PATH_WIN_PATH,a6),d0
		jsr	(WinClearAll)
		moveq	#2,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		move	(＄cpcl),d1
		jsr	(WinSetColor)
		lea	(sp),a1
		jsr	(WinPrint)
		lea	(64+MASK_REGEXP_SIZE,sp),sp
		rts


MINTSLASH::	.dc.b	'\',0
		.even


* ファイルリスト表示 -------------------------- *

* PATH_WIN_FILE で示されるウィンドウの各行に、
* ファイル情報を表示する(一画面分).

print_file_list::
		move.b	(write_disable_flag,opc),d0
		bne	print_file_list_skip

		PUSH	d1-d7/a0-a5
		moveq	#sizeof_DIR,d0
		mulu	(PATH_PAGETOP,a6),d0
		movea.l	(PATH_BUF,a6),a4
		adda.l	d0,a4			;先頭行のファイル

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinSaveCursor)
		moveq	#WHITE,d1
		jsr	(WinSetColor)

		moveq	#0,d1			;X
		moveq	#0,d2			;Y
		move	(＄dirh),d3		;max
print_file_list_loop:
**		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinSetCursor)
		bsr	print_filename_line2

		cmpi.b	#-1,(DIR_ATR,a4)
		beq	print_file_list_end

		lea	(sizeof_DIR,a4),a4
		addq	#1,d2			;Y++
		cmp	d2,d3
		bhi	print_file_list_loop
print_file_list_end:
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinRestoreCursor)
		POP	d1-d7/a0-a5
print_file_list_skip:
		rts


* ファイルウィンドウに、ファイル情報を一行表示する(下請けその１).
* in	a4.l	ディレクトリバッファ
* out	d0.w	PATH_WIN_FILE
* break	a1.l
* 備考:
*	～2 の方は、あらかじめ描画色を WHITE にしておくこと.

print_filename_line:
		PUSH	d1-d3/d7
		move	(PATH_WIN_FILE,a6),d0
		moveq	#WHITE,d1
		jsr	(WinSetColor)
		bra	@f
print_filename_line2:
		PUSH	d1-d3/d7
@@:
		cmpi.b	#-1,(DIR_ATR,a4)
		beq	print_fn_l_bottom	;最下段
		bsr	is_parent_directory_a4
		bne	print_fn_l_top		;親ディレクトリ ".."
* 通常行
		lea	(-(48+8),sp),sp
		lea	(sp),a1
		bsr	make_filename_line

		move	d1,d2
		subq	#WHITE,d2
		beq	@f
		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinSetColor)
		jsr	(WinClearLine)		;白以外で描画する時は消去する
@@:
		move	(PATH_WIN_FILE,a6),d0
		lea	(sp),a1
		jsr	(WinPrint)
		tst.b	(DIR_ATR,a4)
		bpl	@f
		jsr	(WinReverseLine)	;マーク行
@@:
		tst	d2
		beq	@f
		moveq	#WHITE,d1		;一応戻しておく
		jsr	(WinSetColor)
@@:
		lea	(48+8,sp),sp
print_fn_l_end:
		POP	d1-d3/d7
		rts

print_fn_l_bottom:
		moveq	#MES_EODIR,d0
		tst.b	(PATH_MARC_FLAG,a6)
		beq	print_fn_l_sp
		moveq	#MES_MBDIR,d0
		bra	print_fn_l_sp
print_fn_l_top:
		moveq	#MES_PADIR,d0		;親ディレクトリ ".."
		tst.b	(PATH_MARC_FLAG,a6)
		beq	print_fn_l_sp
		moveq	#MES_MPDIR,d0
print_fn_l_sp:
		jsr	(get_message)
		movea.l	d0,a1

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinPrint)
		bra	print_fn_l_end


* ファイル情報行を作成する(下請けその２).
* in	a1.l	バッファ(56 バイト以上必要)
* out	d1.l	描画色

make_filename_line:
		move	(＄winf),d7
		beq	make_filename_line_0
		bmi	make_filename_line_mi
		subq	#2,d7
		bls	make_filename_line_1_2
make_filename_line_0:
make_filename_line_3:
make_filename_line_4:

* %winf 0	" filename__________.ext filesize 99-02-16 00:00 "	(d7=0)
* %winf 3	" filename_________.jpeg filesize 99-02-16 00:00 "	(d7=1)
* %winf 4	" filename.ext__________ filesize 99-02-16 00:00 "	(d7=2)

* ファイル名
		lea	(DIR_NAME,a4),a0
		move.b	#SPACE,(a1)+		;a0 = a1 = 奇数アドレス
		move.b	(a0)+,(a1)+
	.rept	(22-1-1)/4
		move.l	(a0)+,(a1)+
	.endm
		move.b	(a0)+,(a1)+		;1+4*5+1=22

		subq	#1,d7
		bcs	make_filename_line_0e	;%winf 0
		beq	make_filename_line_3ext	;%winf 3

* %winf 4 で拡張子があれば、詰めて表示する。
*make_filename_line_4ext:
		.fail	(DIR_PERIOD-1).and.1
		cmpi	#' .',(DIR_PERIOD-1,a4)
		bne	make_filename_line_0e	;拡張子なし or 主ファイル名が18バイト

		subq.l	#4,a1			;拡張子先頭('.')

		lea	(-1,a1),a0		;-1はなくても平気だがループが1回増える
		moveq	#SPACE,d0
@@:		cmp.b	-(a0),d0
		beq	@b
		addq.l	#1,a0

	.rept	4
		move.b	(a1),(a0)+		;拡張子を前に詰める
		move.b	d0,(a1)+		;元の場所をスペースで埋める
	.endm
		bra	make_filename_line_0e

* %winf 3 で 3 バイト以下の拡張子がなければ、長い拡張子を
* 右寄せで表示する。
make_filename_line_3ext:
		lea	(-4,a1),a0		;a0 = 拡張子先頭('.'or' ')
		moveq	#SPACE,d0
		cmp.b	(a0),d0
		bne	make_filename_line_0e	;拡張子あり
		lea	(-18+1,a0),a2
* filename__________.ext
* filename.jpeg_________
*  ^a2		    ^a0	^a1
* filename_________.jpeg
@@:
		cmpa.l	a0,a2
		bcc	make_filename_line_0e	;念の為…
		cmp.b	-(a0),d0		;末尾の空白を飛ばす
		beq	@b
		addq.l	#1,a0
		lea	(a0),a3
		moveq	#'.',d1
.if 1
		cmp.b	(-1,a0),d1
		beq	make_filename_line_0e	;末尾がピリオドなら拡張子なしと見なす
.endif
@@:
		cmpa.l	a0,a2
		bcc	make_filename_line_0e	;拡張子なし
		cmp.b	-(a0),d1		;最後のピリオドを探す
		bne	@b

		move.l	a3,d1
		sub.l	a0,d1			;拡張子の長さ
		lea	(a1),a0
		subq	#1,d1
@@:		move.b	-(a3),-(a0)		;拡張子を右寄せ
		move.b	d0,(a3)			;コピー元は空白で埋める
		dbra	d1,@b

* これ以降は %winf 0/3/4 で共通
make_filename_line_0e:

* ファイルサイズ
		move.l	(DIR_SIZE,a4),d0
		lea	(a1),a0
		cmpi.l	#1024*1024,d0
		bls	mk_fn_line_byte		;1MB 以下ならそのまま表示
		cmpi.l	#999999999,d0
		bhi	mk_fn_line_mb		;10桁以上ならMバイト単位
		tst	(＄f_1k)
		beq	mk_fn_line_byte		;1MB～9桁で %f_1k 0 ならそのまま表示
mk_fn_line_mb:
		move.l	#1024-1,d2		;〃	    %f_1k 1 ならMバイト単位
		moveq	#10,d3
		add.l	d2,d0			;端数切り上げ
		bcc	@f
		move.l	#4096<<10,d0		;オーバーフロー対策
		bra	1f
@@:		lsr.l	d3,d0			;÷1024
1:		and	d0,d2			;小数部を取っておく
		lsr.l	d3,d0			;÷1024
		moveq	#5,d1			;5 桁
		FPACK	__IUSING
		addq.l	#5,a1
		move.l	#'.00M',(a1)+
		mulu	#100,d2
		lsr.l	d3,d2			;÷1024
		divu	#10,d2
		add.b	d2,(-3,a1)
		swap	d2
		add.b	d2,(-2,a1)
		bra	9f
mk_fn_line_byte:
		moveq	#9,d1			;9 桁
		FPACK	__IUSING
		lea	(a0),a1
9:		move.b	#SPACE,(a1)+

* 年-月-日
		moveq	#0,d0
		move.b	(DIR_DATE,a4),d0
		lsr.b	#1,d0
		addi	#80,d0			;d0 = 80～207(1980～2107)
		moveq	#100,d1
@@:		cmp	d1,d0
		bcs	@f
		sub	d1,d0			;下二桁を取り出す
		bra	@b
@@:		bsr	make_filename_line_2d
		move	d1,-(sp)
		move.b	(sp)+,(a1)+		;年
		move.b	d1,(a1)+		;
		moveq	#'-',d2
		move.b	d2,(a1)+

		move	(DIR_DATE,a4),d3
		move	d3,d0
		lsr	#5,d0
		andi	#$f,d0
		bsr	make_filename_line_2d
		move	d1,(a1)+		;月
		move.b	d2,(a1)+

		moveq	#$1f,d0
		and	d3,d0
		bsr	make_filename_line_2d
		move	d1,-(sp)
		move.b	(sp)+,(a1)+		;日
		move.b	d1,(a1)+		;
		move.b	#SPACE,(A1)+

* 時:分
		bsr	make_filename_line_hm
*		move.b	#SPACE,(a1)+
		clr.b	(a1)

* 表示色
		move.b	(DIR_ATR,a4),d3
		cmpi	#1<<ARCHIVE,d3
		beq	make_filename_line_white

		lea	(＄dirc),a2
		btst	#LINK,d3
		beq	@f

		moveq	#MES_LINKD,d0
		move	(＄lnkc-＄dirc,a2),d1
		btst	#DIRECTORY,d3
		beq	make_filename_line_dir	;リンクファイル
		moveq	#MES_DLINK,d0
		move	(＄dlnc-＄dirc,a2),d1
		bra	make_filename_line_dir	;リンクディレクトリ
@@:
		btst	#DIRECTORY,d3
		beq	make_filename_line_file
		moveq	#MES_DIREC,d0		;ディレクトリ
		move	(a2),d1
make_filename_line_dir:
		lea	(-24,a1),a1		;filesize
		jsr	(get_message)
		movea.l	d0,a0

		moveq	#8-1,d0
@@:		move.b	(a0)+,(a1)+
		dbra	d0,@b
		bra	@f

make_filename_line_file:
		move	(＄excl-＄dirc,a2),d1
		btst	#ARCHIVE,d3
		beq	make_filename_line_end	;実行可能

		moveq	#WHITE,d1
		move	(DIR_EXT,a4),d0
		andi	#$dfff,d0
		cmpi	#'X ',d0
		beq	1f
		cmpi	#'R ',d0
		bne	@f
1:		cmp.b	(DIR_EXT+2,a4),d0
		bne	@f
		move	(＄xrcl-＄dirc,a2),d1
@@:
* この時点で d1.w には WHITE、＄lnkc、＄dlnc、＄dirc、＄xrcl
* のいずれかが入っている(＄excl の場合はここには来ない).
		lsl.b	#8-SYSTEM,d3		;%(S)_HR00_0000
		bcs	2f
		bmi	1f
		beq	make_filename_line_end

		move	(＄redc-＄dirc,a2),d1	;READONLY
		rts
1:		move	(＄hidc-＄dirc,a2),d1	;HIDDEN
		rts
2:		move	(＄sysc-＄dirc,a2),d1	;SYSTEM
		rts

make_filename_line_white:
		moveq	#WHITE,d1
make_filename_line_end:
		rts


* ARCHIVE only		->	無設定(3)	*end*
* LINK
*	&&  DIRECTORY	->	＄dlnc	ファイルサイズ=< D-LNK >
*	&& !DIRECTORY	->	＄lnkc	ファイルサイズ=< F-LNK >
* DIRECTORY		->	＄dirc	ファイルサイズ=<  DIR  >
* !DIRECTORY
*	&& !ARCHIVE	->	＄excl		*end*
*	&& ARCHIVE && 拡張子が .[XxRr]
*			->	＄xrcl
* SYSTEM		->	＄sysc		*end*
* HIDDEN		->	＄hidc		*end*
* READONLY		->	＄redc		*end*


make_filename_line_1_2:
		lea	(48,a1),a3		;バッファ末尾
		beq	make_filename_line_2

*make_filename_line_1:

* %winf 1	" lashwx fsize Feb 16  1999 filename__________.e "
*		or	       Feb 16 00:00

* ファイル属性
		move.l	#' ---',(a1)+
		move.l	#'--- ',(a1)+
		move.b	(DIR_ATR,a4),d3		;%@lad_vshr

		lsr.b	#1,d3			;%0@la_dvsh:r
		bcs	@f
		move.b	#'w',(-3,a1)
@@:
		lsr.b	#1,d3			;%00@l_advs:h
		bcc	@f
		move.b	#'h',(-4,a1)
@@:
		lsr.b	#1,d3			;%000@_ladv:s
		bcc	@f
		move.b	#'s',(-5,a1)
@@:
		lsr.b	#2,d3			;%0000_0@la:d
		bcc	@f
		move.b	#'d',(-7,a1)
		lsr.b	#1,d3			;%0000_00@l:a
.if 1
		bcc	1f
		move.b	#'a',(-6,a1)
.endif
		bra	1f
@@:
		move.b	#'a',(-6,a1)
		lsr.b	#1,d3			;%0000_00@l:a
		bcs	1f
		move.b	#'x',(-2,a1)
1:
		lsr.b	#1,d3			;%0000_000x:l
		bcc	@f
		move.b	#'l',(-7,a1)
@@:
* ファイルサイズ
		subq.l	#1,a1
		bsr	make_filename_line_fsize

* 月日
		bsr	make_filename_line_md
		move.b	#SPACE,(a1)+

* 西暦 or 時:分
		DOS	_GETDATE
		move	(DIR_DATE,a4),d1
		eor	d1,d0
		andi	#$7f<<9,d0
		beq	1f			;同じ年
		bsr	make_filename_line_y4	;西暦を四桁で表示
		bra	@f
1:		bsr	make_filename_line_hm	;時:分
@@:

* ファイル名
make_filename_line_filename:
		lea	(DIR_NAME,a4),a0	;a0 = a1 = 奇数アドレス
		moveq	#SPACE,d0
		move.b	(a0)+,(a1)+
	.rept	4
		move.l	(a0)+,(a1)+		;ノード名
	.endm
		move.b	(a0)+,(a1)+
@@:		cmp.b	-(a1),d0		;末尾の空白を削除
		beq	@b
		addq.l	#1,a1
	.rept	4
		move.b	(a0)+,(a1)+		;拡張子
	.endm
@@:		cmp.b	-(a1),d0		;末尾の空白を削除
		beq	@b
		addq.l	#1,a1

		lea	(＄dirc),a2
		moveq	#WHITE,d4

		move.b	(DIR_ATR,a4),d3
		move.b	d3,d2
* リンクなら '@' を付ける
		moveq	#'@',d0
		rol.b	#1,d2			;%ladv_shr@
		bmi	@f
* ディレクトリなら $MINTSLASH を付ける
		move.b	(MINTSLASH,opc),d0
		rol.b	#2,d2			;%dvsh_r@la
		bmi	@f
* 実行可能なら '*' を付ける
		moveq	#'*',d0
		lsr.b	#1,d2			;%0dvs_hr@l:a
		bcc	@f
* 拡張子が .[XxRr] でも付ける
		move	(DIR_EXT,a4),d2
		andi	#$dfff,d2
		cmpi	#'X ',d2
		beq	1f
		cmpi	#'R ',d2
		bne	9f
1:		cmp.b	(DIR_EXT+2,a4),d2
		bne	9f			;".x a"
		move	(＄xrcl-＄dirc,a2),d4
@@:
		move.b	d0,(a1)+		;@*/ を付ける
9:

* 余分なスペースを空白で埋める
		moveq	#SPACE,d0
@@:		move.b	d0,(a1)+		;取り敢えず埋めてみる
		cmp.l	a1,a3
		bcc	@b
@@:		clr.b	-(a1)			;埋めすぎたら戻す
		cmp.l	a3,a1
		bhi	@b
		move.b	d0,-(a1)		;左端は必ず空白

* 表示色
		move	d4,d1			;WHITE or ＄xrcl
		cmpi.b	#1<<ARCHIVE,d3
		beq	9f

		move	(＄redc-＄dirc,a2),d1
		ror.b	#1,d3			;%r@la_dvsh
		bmi	9f
		move	(＄hidc-＄dirc,a2),d1
		ror.b	#1,d3			;%hr@l_advs
		bmi	9f
		move	(＄sysc-＄dirc,a2),d1
		ror.b	#1,d3			;%shr@_ladv
		bmi	9f
		ror.b	#2,d3			;%dvsh_r@la
		bpl	@f

		move	(a2),d1
		ror.b	#2,d3			;%ladv_shr@
		bpl	9f			;普通のディレクトリ
		move	(＄dlnc-＄dirc,a2),d1
		bra	9f			;リンク〃
@@:
		move	(＄lnkc-＄dirc,a2),d1
		ror.b	#2,d3			;%ladv_shr@
		bmi	9f
		move	(＄excl-＄dirc,a2),d1
		add.b	d3,d3			;%advs_hr@0
		bpl	9f
		move	d4,d1			;WHITE or ＄xrcl
9:		rts


make_filename_line_2:

* %winf 2	" attribt f_size   1999 filename__________.ext   "
*		or		 Feb 16
*		or		  00:00

* ファイル属性
		move.l	#' ---',(a1)+
		move.l	#'-r--',(a1)+
		move.b	(DIR_ATR,a4),d3		;%xlad_vshr

		lsr.b	#1,d3			;%0xla_dvsh:r
		bcs	@f
		move.b	#'w',(-2,a1)
@@:
		lsr.b	#1,d3			;%00xl_advs:h
		bcc	@f
		move.b	#'h',(-4,a1)
@@:
		lsr.b	#1,d3			;%000x_ladv:s
		bcc	@f
		move.b	#'s',(-3,a1)
@@:
		lsr.b	#2,d3			;%0000_0xla:d
		bcc	@f
		move.b	#'d',(-7,a1)
		lsr.b	#1,d3			;%0000_00xl:a
.if 1
		bcc	1f
		move.b	#'a',(-6,a1)
.endif
		bra	1f
@@:
		move.b	#'a',(-6,a1)
		lsr.b	#1,d3			;%0000_00xl:a
		bcs	1f
		move.b	#'x',(-1,a1)
1:
		lsr.b	#1,d3			;%0000_000x:l
		bcc	@f
		move.b	#'l',(-7,a1)
@@:		move.b	#SPACE,(a1)+

* ファイルサイズ
		bsr	make_filename_line_fsize

* 西暦 or 月日 or 時:分
		moveq	#SPACE,d2
		move.b	d2,(a1)+
		move.b	d2,(a1)+
		DOS	_GETDATE
		move	(DIR_DATE,a4),d1
		eor	d1,d0
		beq	1f			;年月日が同じ
		cmpi	#$01ff,d0
		bls	2f			;月または日付が違う

		bsr	make_filename_line_y4	;西暦を四桁で表示
		bra	@f
2:
		subq.l	#2,a1
		bsr	make_filename_line_md	;月/日を表示
		move.b	d2,(a1)+
		bra	@f
1:
		bsr	make_filename_line_hm	;時:分を表示
@@:
		bra	make_filename_line_filename


* in	d0.w	数値
* out	d1.w	二桁の数字
make_filename_line_2d:
		move	#'00'+10<<8,d1
		subi	#10,d0
		bcs	@f
1:		addq	#1,d1			;十の位++
		subi	#10,d0
		bcc	1b
@@:
		rol	#8,d1
		add	d0,d1
		rts

* in	a1.l	バッファ
* out	a1.l	+= 6
make_filename_line_hm:
		move	(DIR_TIME,a4),d2
		move	d2,d0
		rol	#5,d0
		andi	#$1f,d0
		bsr	make_filename_line_2d
		move	d1,-(sp)
		move.b	(sp)+,(a1)+		;時
		move.b	d1,(a1)+		;
		move.b	#':',(a1)+

		move	d2,d0
		lsr	#5,d0
		andi	#$3f,d0
		bsr	make_filename_line_2d
		move	d1,-(sp)
		move.b	(sp)+,(a1)+		;分
		move.b	d1,(a1)+		;
		move.b	#SPACE,(a1)+
		rts

* in	a1.l	バッファ
* out	a1.l	+= 7
make_filename_line_md:
		GETMES	MES_MONTH
		movea.l	d0,a0

		move	(DIR_DATE,a4),d0
		lsr	#5,d0
		andi	#$f,d0
		subq	#1,d0
		cmpi	#12-1,d0
		bls	@f
		moveq	#12,d0			;不正な月
@@:
		adda	d0,a0
		add	d0,d0
		adda	d0,a0			;a0 += d0*3
		moveq	#SPACE,d1
		move.b	d1,(a1)+
		move.b	(a0)+,(a1)+		;月
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	d1,(a1)+

		moveq	#$1f,d0
		and	(DIR_DATE,a4),d0
		bsr	make_filename_line_2d
		move	d1,(a1)+		
		rts

* in	a1.l	バッファ
* out	a1.l	+= 6
make_filename_line_y4:
		move.b	#SPACE,(a1)+
		moveq	#0,d0
		move.b	(DIR_DATE,a4),d0
		lsr.b	#1,d0
		addi	#1980,d0
		moveq	#4,d1
		exg	a0,a1
		FPACK	__IUSING
		exg	a0,a1
		move.b	#SPACE,(a1)+
		rts

* in	a1.l	バッファ
* out	a1.l	+= 6
* break	d0-d4
make_filename_line_fsize:
		move.l	(DIR_SIZE,a4),d0
		lea	(a1),a0
		cmpi.l	#999999,d0
		bhi	@f

		moveq	#6,d1			;バイト単位で表示
		FPACK	__IUSING
		addq.l	#6,a1
		rts
@@:
		moveq	#10,d3			;K/M/G 単位で表示
		move.l	#'GMK',d4
		bra	@f
make_filename_line_fsize_loop:
		lsr.l	#8,d4
		tst	d2
		beq	@f
		addq.l	#1,d0			;端数切り上げ
@@:
		move	d0,d2			;端数
		lsr.l	d3,d0			;÷1024
		cmpi.l	#999,d0
		bhi	make_filename_line_fsize_loop

		moveq	#3,d1			;整数部 3 桁
		FPACK	__IUSING
		addq.l	#3,a1
		move.b	#'.',(a1)+
		andi	#1024-1,d2
		mulu	d3,d2
		lsr.l	d3,d2			;÷1024
		addi.b	#'0',d2
		move.b	d2,(a1)+		;小数点第一位
		move.b	d4,(a1)+		;K/M/G
		rts


* プラグインを呼び出してファイル情報行を作成する

make_filename_line_mi:
		move.l	(plugin_winf+PLUG_IN_MAIN,opc),d0
		bne	@f

		moveq	#0,d7
		bra	make_filename_line_0	;プラグイン未登録時は %winf 0
@@:

* in	d7.w	%winf
*	a1.l	バッファ(56バイト)
*	a4.l	DIR バッファ
*	a6.l	PATH バッファ
* out	d1.l	描画色
* break	d0/d2-d7/a0-a3/a5
		movea.l	d0,a0
		jmp	(a0)
**		rts


* ボリュームラベル収得/表示 ------------------- *

get_and_print_volume_label:
		lea	(-FILES_SIZE,sp),sp
		clr.b	(PATH_VOLUME,a6)
		tst.b	(PATH_NODISK,a6)
		bne	get_volume_label_end

		lea	(sp),a1
		bsr	files_volume_label
		bpl	get_volume_label_exist

		move	(PATH_DRIVENO,a6),d1
		jbsr	dos_getdpb_cd
		bmi	@f
		cmpi.b	#MB_CDROM,(DPB_MediaByte,a1)
		bne	@f

		moveq	#MES_CDROM,d0		;ボリュームラベルなし CD-ROM
		bra	get_volume_label_message
@@:
		moveq	#MES_NOVOL,d0		;CD-ROM 以外でボリュームラベルなし
get_volume_label_message:
		jsr	(get_message)
		movea.l	d0,a1
		bra	get_volume_label_set

get_volume_label_exist:
		bsr	remove_volume_label_period
get_volume_label_set:
		lea	(PATH_VOLUME,a6),a2
		STRCPY	a1,a2
get_volume_label_end:
		lea	(FILES_SIZE,sp),sp
		bra	print_volume_label
**		rts


* ボリュームラベル表示 ------------------------ *
* 画面二行目にボリュームラベルを表示する.
* mintarc 内では &arcvl を表示する.
* %vocl 0x800? の場合は書庫ファイル名を表示する.

PRINT_VOL_BUF:	.equ	PATHNAME_MAX+FILENAME_MAX+1+4	;全角の分も加算

print_volume_label:
		move.b	(write_disable_flag,opc),d0
		bne.s	print_volume_label_end

		lea	(PATH_VOLUME,a6),a1
		tst.b	(PATH_MARC_FLAG,a6)
		beq	print_volume_label_sub	;生のボリュームラベル
		tst	(＄vocl)
		bpl	print_vl_arcvl		;"Mintarc Virtual Dir."

		lea	(-PRINT_VOL_BUF,sp),sp
		jsr	(get_mintarc_filename)
		movea.l	d0,a1
		lea	(sp),a2
		bsr	copy_pathname_zdrv	;とりあえずフルパスで用意

		lea	(sp),a1
		STRLEN	a1,d0
		cmpi	#WIN_WIDTH/2-2,d0
		bls	@f			;フルパスで表示

		lea	(sp),a0
		bsr	search_last_slash	;長すぎたらファイル名のみ
@@:
		bsr	print_volume_label_sub
		lea	(PRINT_VOL_BUF,sp),sp
print_volume_label_end:
		rts

print_vl_arcvl:
		GETMES	MES_ARCVL
		movea.l	d0,a1
		bra	print_volume_label_sub
**		rts

print_volume_label_sub:
		move	(PATH_WIN_VOL,a6),d0
		jsr	(WinClearAll)
		moveq	#1,d1
		moveq	#0,d2
		jsr	(WinSetCursor)
		move	(＄vocl),d1
		andi	#$7fff,d1
		jsr	(WinSetColor)
		jmp	(WinPrint)
**		rts


* カレントドライブのボリュームラベルを収得する.
* in	a1.l	files buffer
* out	a1.l	files buffer->filename
* break	a2.l

files_volume_label:
		lea	(get_volname_wild,pc),a2
		move.b	(PATH_DIRNAME,a6),(a2)
		move	#1<<VOLUME,-(sp)
		move.l	a2,-(sp)		;filename
		move.l	a1,-(sp)		;buffer
		DOS	_FILES
		lea	(FILES_FileName,a1),a1
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		rts


* ボリュームラベルのピリオドを削除する.
* in	a1.l	filename

remove_volume_label_period:
		tst	(＄volp)
		beq	remove_volume_label_period_end

		PUSH	a0/a2
		lea	(-NAMECK_SIZE,sp),sp
		move.l	sp,-(sp)
		move.l	a1,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bmi	@f
		cmpi.b	#'.',(NAMECK_Ext,sp)
		bne	@f

		lea	(a1),a2
		lea	(NAMECK_Name,sp),a0
		STRCPY	a0,a2
		subq.l	#1,a2
		lea	(NAMECK_Ext+1,sp),a0
		STRCPY	a0,a2
@@:
		lea	(NAMECK_SIZE,sp),sp
		POP	a0/a2
remove_volume_label_period_end:
		rts


*************************************************
*	&set-opposite-window-to-current		*
*************************************************

＆set_opposite_window_to_current::
		movea.l	(PATH_OPP,a6),a6
		bsr	chdir_to_opp_win_sub
		movea.l	(PATH_OPP,a6),a6
		rts


*************************************************
*		&chdir-to-opposite-window	*
*************************************************

＆chdir_to_opposite_window::
		bsr	chdir_to_opp_win_sub
		jbra	ReverseCursorBar
**		rts


chdir_to_opp_win_sub:
		jsr	(quit_mintarc_all)

		movea.l	(PATH_OPP,a6),a5
		tst.b	(PATH_MARC_FLAG,a5)
		bne	@f

		jbsr	save_drv_curfile
		move	(PATH_DRIVENO,a5),(PATH_DRIVENO,a6)
		lea	(PATH_DIRNAME,a5),a1
		lea	(PATH_DIRNAME,a6),a2
		STRCPY	a1,a2
		bra	1f
@@:
		jsr	(get_mintarc_filename_opp)
		movea.l	d0,a0
		moveq	#$1f,d0
		and.b	(a0),d0
		move	d0,(PATH_DRIVENO,a6)

		bsr	search_last_slash
		move.b	(a1),-(sp)		;書庫のあるディレクトリへ移動
		clr.b	(a1)
		lea	(PATH_DIRNAME,a6),a2
		STRCPY	a0,a2
		move.b	(sp)+,(a1)
1:
		jbsr	chdir_routin
		jbra	directory_write_routin
**		rts


* 指定文字列中最後の '/' または '\' を検索する.
* in	a0.l	文字列
* out	d0.l	0:found -1:not found
*	a1.l	見つけた '/' または '\' のアドレス＋1
*	ccr	<tst.l d0> の結果
* 備考:
*	fileop.s の同名ルーチン(未使用)とは少し違う.

search_last_slash:
		move.l	a0,-(sp)
search_last_slash_found:
		lea	(a0),a1
search_last_slash_loop:
		move.b	(a0)+,d0
		beq	search_last_slash_end
		cmpi.b	#'/',d0
		beq	search_last_slash_found
		cmpi.b	#'\',d0
		beq	search_last_slash_found
		lsr.b	#5,d0
		btst	d0,#%10010000
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


*************************************************
*		&drive-decrement		*
*************************************************

＆drive_decrement::
		bsr	drive_decinc
*drive_decrement_sub:
		subq	#1,d1
		bne	@f
		moveq	#'Z'-'A'+1,d1
@@:		rts


*************************************************
*		&drive-increment		*
*************************************************

＆drive_increment::
		bsr	drive_decinc
*drive_increment_sub:
		addq	#1,d1
		cmpi	#'Z'-'A'+1,d1
		bls	@f
		moveq	#1,d1
@@:		rts


drive_decinc:
		movea.l	(sp)+,a0		;ドライブ dec/inc ルーチン
		move	(PATH_DRIVENO,a6),d1
drive_decinc_loop:
		jsr	(a0)			;前 or 次のドライブ
		cmp	(PATH_DRIVENO,a6),d1
		beq	set_status_0		;ひと回りしてしまった

		move.b	d1,d0
		bsr	get_assign_mode
*		tst.l	d0
*		ble	drive_decinc_loop
		moveq	#READRV,d2
		cmp.l	d0,d2
		beq	@f
		moveq	#VIRDRV,d2
		cmp.l	d0,d2
		bne	drive_decinc_loop
@@:
		move	d1,d0
		bsr	change_drive_sub
		bra	set_status
**		rts


* ドライブ変更下請け
* in	d0.w	ドライブ番号(1=A: ～ 26=Z:)
* out	d0.l	0:エラー 1:正常終了

change_drive_sub:
		PUSH	d1-d2
		move	d0,d1
		bsr	get_assign_mode
*		tst.l	d0
*		ble	change_drive_sub_error
		moveq	#READRV,d2
		cmp.l	d0,d2
		beq	@f
		moveq	#VIRDRV,d2
		cmp.l	d0,d2
		bne	change_drive_sub_error
@@:
		jsr	(quit_mintarc_all)
		jbsr	save_drv_curfile

		move	d1,(PATH_DRIVENO,a6)
		move	d1,d0
		lea	(PATH_DIRNAME,a6),a0
		bsr	get_current_path

		bsr	restore_curfile
		bsr	chdir_and_rewrite
		moveq	#1,d0
change_drive_sub_end:
		POP	d1-d2
		rts
change_drive_sub_error:
		moveq	#0,d0
		bra	change_drive_sub_end


*************************************************
*	&change-drive=&change-drive-menu	*
*************************************************

＆change_drive::
		GETMES	MES_DRIVE
		move.l	d0,a1
		move.b	(PATH_DIRNAME,a6),d5	;-d<d> 省略時はカレントドライブ
		moveq	#0,d6			;-s
		bra	chg_drv_arg_next
chg_drv_arg_loop:
		move.b	(a0)+,d0
		beq	chg_drv_arg_next
		cmpi.b	#'-',d0
		bne	change_drive_direct	;ドライブ名指定あり
*chg_drv_arg_option:
		move.b	(a0)+,d0
		beq	chg_drv_arg_next
		cmpi.b	#'d',d0
		beq	chg_drv_option_d
		cmpi.b	#'s',d0
		beq	chg_drv_option_s
		cmpi.b	#'t',d0
		bne	chg_drv_error
*chg_drv_option_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	chg_drv_error		;引数がない
@@:
		lea	(-1,a0),a1
		bra	chg_drv_arg_skip
chg_drv_option_s:
		moveq	#-1,d6			;-s : 選択のみ
		tst.b	(a0)+
		bne	chg_drv_error
		bra	chg_drv_arg_next
chg_drv_option_d:
* 引数(ドライブ名)の厳しいチェックは行わない.
* これにより、-d_ などと指定することで
* 初期カーソル位置を 0(無表示)にすることが出来る.
		move.b	(a0)+,d5		;-d<d> : 初期カーソル位置(ドライブ名)
		beq	chg_drv_arg_next
chg_drv_arg_skip:
		tst.b	(a0)+
		bne	chg_drv_arg_skip
chg_drv_arg_next:
		subq.l	#1,d7
		bcc	chg_drv_arg_loop

* ドライブ名指定がなければメニューモード
*change_drive_menu:
		move.b	d5,d6			;d6.hw = -s / d6.b = -d<d>

* サブウィンドウのパラメータを設定
* _Y、_YSIZE はリスト作成後に決定する
		lea	(Buffer+256),a0		;SUBWIN 構造体
		clr.l	(SUBWIN_MES,a0)
		move.l	a1,(SUBWIN_TITLE,a0)

		move	(PATH_WINRL,a6),d0
		addq	#6,d0
		move	d0,(SUBWIN_X,a0)

		moveq	#18,d0
		move	(＄drvv),d4
		beq	@f
		moveq	#18+1+21,d0		;ボリュームラベルも表示する
@@:		move	d0,(SUBWIN_XSIZE,a0)

		clr	(SUBWIN_YSIZE,a0)

* ドライブリストを作成する
		lea	(sizeof_SUBWIN,a0),a2	;選択肢リスト
		lea	(26*4,a2),a3		;文字列バッファ

		andi.b	#$df,d6
		subi.b	#'A'-1,d6		;カーソルを置くドライブ番号
		moveq	#0,d7			;初期カーソル位置

		moveq	#1,d1			;ドライブ番号(1～26)
chg_drv_loop:
		move.l	a3,(a2)			;文字列のアドレスをリストに仮登録
		move.b	#'A'-1,(a3)

		move	d1,d0
		bsr	get_assign_mode
		moveq	#READRV,d2
		cmp.l	d0,d2
		beq	chg_drv_readrv		;実ドライブ
		moveq	#VIRDRV,d2
		cmp.l	d0,d2
		bne	chg_drv_next		;未使用ドライブ
*chg_drv_virdrv:
		add.b	d1,(a3)+		;ショートカットキー

		GETMES	MES_IDRIV		;仮想ドライブ
		movea.l	d0,a1
		STRCPY	a1,a3

		tst	d4
		beq	chg_drv_exist		;%drvv 0 : ボリュームラベル表示なし

		move.b	#'│'>>8,(-1,a3)
		move.b	#'│'.and.$ff,(a3)+

		move.l	#'@:'<<16,-(sp)		;仮想ドライブなら割り当て先を表示
		add.b	d1,(sp)
		pea	(a3)
		pea	(4,sp)
		clr	-(sp)			;ASSIGN_GET
		DOS	_ASSIGN
		lea	(10+4,sp),sp

		exg	a0,a3
		bsr	call_to_mintslash
		exg	a0,a3
@@:		tst.b	(a3)+
		bne	@b
		move.b	(MINTSLASH),(-1,a3)	;末尾にパスデリミタをつける
		clr.b	(a3)+
		bra	chg_drv_exist

chg_drv_readrv:
		jbsr	dos_getdpb_cd
		bmi	chg_drv_next

		lea	(a1),a5
		move.b	(DPB_MediaByte,a5),d5

		add.b	d1,(a3)+		;ショートカットキー

* CD-ROM ドライブと MO ドライブはデバイスヘッダ内にある
* デバイス名ではなく、&drvcd/&drvmo で指定した文字列を表示する。
		moveq	#MES_DRVCD,d0		;'CD-ROM1'
		cmpi.b	#MB_CDROM,d5
		beq	chg_drv_cdmo
		moveq	#MES_DRVMO,d0		;'   MO  '
		cmpi.b	#MB_MO,d5
		bne	chg_drv_other
chg_drv_cdmo:
		jsr	(get_message)
		bra	@f

* それ以外のドライブはデバイスヘッダ内からコピー
chg_drv_other:
		moveq	#14+1,d0
		add.l	(DPB_DevHed,a5),d0	;デバイス名
@@:
		movea.l	d0,a1
		moveq	#SPACE,d2
		moveq	#7-1,d3
chg_drv_devname_loop:
		IOCS	_B_BPEEK		;デバイス名
		cmp.b	d2,d0
		bcc	@f
		moveq	#SPACE,d0
@@:		move.b	d0,(a3)+
		dbra	d3,chg_drv_devname_loop

		move.b	d2,(a3)+
		move.b	d2,(a3)+

		moveq	#'0',d3
		moveq	#0,d0
		move.b	(DPB_UnitNo,a5),d0
		divu	#10,d0
		beq	@f
		add.b	d3,d0
		move.b	d0,(-1,a3)		;十の位
@@:
		swap	d0
		add.b	d3,d0
		move.b	d0,(a3)+		;一の位
		clr.b	(a3)+

		tst	d4
		beq	chg_drv_exist		;%drvv 0 : ボリュームラベル表示なし

		move.b	d2,(-1,a3)
		move.b	#'│'>>8,(a3)+
		move.b	#'│'.and.$ff,(a3)+

		bsr	dos_drvctrl_d1_org	;仮想ドライブではないので _org でよい
		btst	#DRV_INSERT,d0
		beq	chg_drv_notready	;メディア未挿入
		btst	#DRV_NOTREADY,d0
		bne	chg_drv_notready	;準備が出来ていない
* DOS _DRVCTRL の返値の bit3-2 は、メディア挿入時のみ有効。
* たいていの未挿入で NOTREADY==1 INSERT==0 を返すが、
* NOTREADY==0 INSERT==0 を返すドライバもあるので注意。

*chg_drv_volume:
		lea	(get_volname_wild,pc),a1
		moveq	#'A'-1,d0
		add.b	d1,d0
		move.b	d0,(a1)

		move	#1<<VOLUME,-(sp)
		move.l	a1,-(sp)
		lea	(-256,a0),a1		;Buffer
		move.l	a1,-(sp)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	chg_drv_novol

		lea	(FILES_FileName,a1),a1
		bsr	remove_volume_label_period
		bra	chg_drv_vol_cp

* ボリュームラベルがなければ &novol で指定した文字列を表示する。
* ただし、CD-ROM ドライブだけは &cdrom にする。
chg_drv_novol:
		moveq	#MES_NOVOL,d0
		cmpi.b	#MB_CDROM,d5
		bne	@f
		moveq	#MES_CDROM,d0
		bra	@f

* ドライブの準備が出来ていなければメディアバイトに応じた
* メッセージを表示する。
chg_drv_notready:
		move.b	d5,d0
		bsr	get_nodisk_message
		addq.b	#MES_NDISK-MES_NODSK,d0
		.fail	(MES_NDISK-MES_NODSK).ne.(MES_NONDR-MES_NO_DR)
@@:
		jsr	(get_message)
		movea.l	d0,a1
chg_drv_vol_cp:
		STRCPY	a1,a3

* 残りのリスト登録処理
chg_drv_exist:
		addq.l	#4,a2			;リストに登録
		addq	#1,(SUBWIN_YSIZE,a0)
		cmp.b	d1,d6
		bne	chg_drv_next
		move	(SUBWIN_YSIZE,a0),d7	;このドライブが初期カーソル位置
chg_drv_next:
		addq	#1,d1
		cmpi	#26,d1
		bls	chg_drv_loop

		move	(SUBWIN_YSIZE,a0),d0
		beq	chg_drv_error		;ドライブが一つも認識できなかった

		moveq	#29,d1
		sub	d0,d1			;最大 Y 座標
		move	(＄dz_y),d0
		cmp	d1,d0
		bls	@f
		move	d1,d0
@@:		move	d0,(SUBWIN_Y,a0)

		lea	(sizeof_SUBWIN,a0),a1	;選択肢リスト
		move.l	d7,d0			;初期カーソル位置
		jsr	(menu_sub)
		beq	chg_drv_error

		swap	d0			;d0.w = ショートカットキー

		clr	-(sp)			;$_ に設定する
		move.b	d0,(sp)
		lea	(sp),a2
		jsr	(set_user_value_arg_a2)
		move.b	(sp)+,d1
		tst.l	d6
		bmi	chg_drv_end		;-s 指定時は選択のみ

		moveq	#$1f,d0
		and.b	d1,d0
chg_drv_exec:
		bsr	change_drive_sub
chg_drv_end:
		bra	set_status
**		rts


change_drive_direct:
		moveq	#$20,d0
		or.b	-(a0),d0
		cmpi	#'z',d0
		bhi	chg_drv_error		;ドライブ名指定エラー
		subi	#'a'-1,d0
		bhi	chg_drv_exec
chg_drv_error:
		bra	set_status_0
**		rts


call_to_mintslash:
		jmp	(to_mintslash)
**		rts


* ドライブ制御 -------------------------------- *
* in	d1.hb	コマンド
*	d1.b	ドライブ番号
* out	d0.l	エラーコード

dos_drvctrl_d1_org:
		move	d1,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		rts


* 仮想ディレクトリ対応版
*	TODO: そもそもドライブ番号ではなく目的のパス名で指定すべき

dos_drvctrl_d1::
		PUSH	d1-d7/a0-a6
		lea	(-64,sp),sp
		lea	(sp),a2
		bsr	mount_prepare
drvctrl_loop:
		lea	(sp),a2			;カレントディレクトリ
		bsr	mount_compare
		bne	drvctrl_next

		bsr	mount_unset
		bmi	drvctrl_error

		move	d7,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		bsr	mount_restore
		bra	drvctrl_end
drvctrl_error:
		clr.b	(a1)			;仮想ディレクトリではなかった
drvctrl_next:
		lea	(64,a1),a1
		addq.b	#1,d7
		cmpi.b	#26+1,d7
		bne	drvctrl_loop

		move	d1,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
drvctrl_end:
		lea	(64,sp),sp
		POP	d1-d7/a0-a6
		rts


* ドライブパラメータブロック収得 -------------- *
* in	d1.w	ドライブ番号
* out	d0.l	エラーコード
*	a1.l	DPB バッファ
*	ccr	<tst.l d0> の結果
*
* 計測技研の CD-ROM ドライバの仕様を補正する。

dos_getdpb_cd:
		lea	(DpbBuffer),a1
		pea	(a1)
		move	d1,-(sp)
		DOS	_GETDPB
		addq.l	#6,sp
.ifndef NO_KG_CDROM
		cmpi.l	#-14,d0
		bne	@f
		move.b	#MB_CDROM,(DPB_MediaByte,a1)
		moveq	#0,d0
@@:
.endif
		tst.l	d0
		rts


* ドライブパラメータブロック収得 -------------- *
* in	d1.w	ドライブ番号
* out	d0.l	エラーコード

dos_getdpb_org:
		pea	(DpbBuffer)
		move	d1,-(sp)
		DOS	_GETDPB
		addq.l	#6,sp
		rts

* 仮想ディレクトリ対応版
dos_getdpb:
		PUSH	d1-d7/a0-a6
		bsr	get_real_drive_no	;仮想ドライブなら割り当て先を見る

		lea	(-64,sp),sp
		lea	(sp),a2
		bsr	mount_prepare
getdpb_loop:
		lea	(sp),a2			;カレントディレクトリ
		bsr	mount_compare
		bne	getdpb_next

		bsr	mount_unset
		bmi	getdpb_error

		move	d7,d1
		bsr	dos_getdpb_org
		bsr	mount_restore
		bra	getdpb_end
getdpb_error:
		clr.b	(a1)			;仮想ディレクトリではなかった
getdpb_next:
		lea	(64,a1),a1
		addq.b	#1,d7
		cmpi.b	#26+1,d7
		bne	getdpb_loop

		bsr	dos_getdpb_org
getdpb_end:
		lea	(64,sp),sp
		POP	d1-d7/a0-a6
		rts


get_real_drive_no:
		move.l	#('A'-1)<<24+':'<<16,-(sp)
		add.b	d1,(sp)
		lea	(-64,sp),sp
		move.l	sp,-(sp)
		pea	(64+4,sp)
		move	#ASSIGN_GET,-(sp)
		DOS	_ASSIGN
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	@f
		cmpi	#VIRDRV,d0
		bne	@f			;仮想ドライブではない

		moveq	#$1f,d1
		and.b	(sp),d1		;ドライブ番号
@@:
		lea	(64+4,sp),sp
		rts


* mount 関係の準備
* in	d1.hb	DOS _DRVCTRL のモード番号
*	a2.l	作業用バッファのアドレス
* out	d7.hb	DOS _DRVCTRL のモード番号
*	d7.b	1
*	a1.l	mount_buf

mount_prepare:
		move.l	a2,-(sp)
		lea	(PATH_DIRNAME,a6),a1
		STRCPY	a1,a2
		clr.b	(-2,a2)
		move.l	(sp)+,a2

		lea	(mount_buf),a1
		move	d1,d7
		move.b	#1,d7
		rts

* 仮想ディレクトリ解除
mount_unset:
		move.l	#('A'-1)<<24+':'<<16,-(sp)
		add.b	d7,(sp)
		pea	(sp)
		move	#ASSIGN_UNSET,-(sp)
		DOS	_ASSIGN
		addq.l	#6,sp
		move.l	d0,(sp)+
		rts

* 解除した仮想ディレクトリを元に戻す
mount_restore:
		move.l	d0,-(sp)

		move.l	#('A'-1)<<24+':'<<16,-(sp)
		add.b	d7,(sp)	

		move	#VIRDIR,-(sp)
		moveq	#64,d0
		mulu	d7,d0
		addi.l	#mount_buf-64,d0
		move.l	d0,-(sp)		;ディレクトリ名
		pea	(6,sp)			;ドライブ名
		move	#ASSIGN_SET,-(sp)
		DOS	_ASSIGN
		lea	(4+12,sp),sp

		move.l	(sp)+,d0
		rts

* 仮想ディレクトリ検査
mount_compare::
		PUSH	d1/d5-d7/a1-a2
		tst.b	(a1)
		beq	mount_cmp_ne

		moveq	#'A',d5
		moveq	#'Z',d6
		moveq	#'/',d7
mount_cmp_loop:
		move.b	(a1)+,d0
		beq	mount_cmp_end
		move.b	(a2)+,d1
		cmp.b	d0,d1
		beq	mount_cmp_loop
	.irp	dn,d0,d1
		cmp.b	d7,dn
		bne	@f
		moveq	#'\',dn
@@:
		cmp.b	d5,dn
		bcs	@f
		cmp.b	d6,dn
		bhi	@f
		ori.b	#$20,dn			;小文字化
@@:
	.endm
		cmp.b	d0,d1
		bne	mount_cmp_end

		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	mount_cmp_loop

		cmpm.b	(a1)+,(a2)+
		beq	mount_cmp_loop
mount_cmp_ne:
		moveq	#-1,d0
mount_cmp_end:
		POP	d1/d5-d7/a1-a2
		rts


*************************************************
*		&mask=&mask-regexp		*
*************************************************

＆mask::
		moveq	#SPACE,d1
		bsr	mask_decode_argument
		beq	mask_menu
		cmpi.l	#MASK_REGEXP_SIZE-4,d0
		bcc	mask_error		;正規表現が長すぎる

		movea.l	(PATH_MASK,a6),a1
		move.l	(_ignore_case),(a1)+
		STRCPY	a0,a1
mask_reload_end:
		movea.l	(PATH_MASK,a6),a1
		addq.l	#4,a1
		cmpi	#'*'<<8,(a1)
		bne	@f
		clr.b	(a1)			;"*" -> ""
@@:
		jbsr	restore_curfile
		jbsr	directory_write_routin
		jbsr	ReverseCursorBar
		bra	set_status_1
**		rts
mask_error:
		bra	set_status_0
**		rts

mask_menu:
		lea	(subwin_mask_menu,pc),a0
		move.l	a1,d0
		bne	@f
		GETMES	MES_CWILD
@@:		move.l	d0,(SUBWIN_TITLE,a0)
		moveq	#22,d0
		add	(PATH_WINRL,a6),d0
		move	d0,(SUBWIN_X,a0)

		lea	(at_wild),a1
		jsr	(decode_reg_menu)
		move	d0,(SUBWIN_YSIZE,a0)
		beq	mask_error

		move.l	d1,d0			;初期カーソル位置
		jsr	(menu_sub)
		beq	mask_error

		lsl	#2,d0
		movea.l	(-4,a2,d0.w),a1		;パターン
		bsr	mask_i_c_option
		bne	mask_menu_no_option

		cmpi.b	#$20,(a1)
		bcs	mask_error		;-i/-c だけの選択肢は不可
		cmpi.b	#'#',(a1)
		beq	mask_error		;〃
mask_menu_no_option:
		moveq	#0,d5
		lea	(-MASK_REGEXP_SIZE,sp),sp
		lea	(sp),a2
		cmpi.b	#'!',(a1)
		bne	mask_menu_no_input

		moveq	#-1,d5			;input mode
		addq.l	#1,a1
		jbsr	skip_blank_a1

		cmpi.b	#$20,(a1)		;@wild ... ! -iなどだったら以後の文字列を
		bcs	@f			;初期値にする(本当は$<で展開したい.
		cmpi.b	#'#',(a1)
		bne	mask_menu_input_str
@@:
		movea.l	(PATH_MASK,a6),a1	;'!' の後に何もなければ
		addq.l	#4,a1			;現在のパスマスクを初期値にする
		STRCPY	a1,a2
		bra	1f
mask_menu_no_input:
mask_menu_input_str:
		moveq	#MASK_REGEXP_SIZE-2,d1
		cmpi.b	#'"',(a1)+
		seq	d2
		beq	mask_menu_copy_loop
		subq.l	#1,a1
mask_menu_copy_loop:
		move.b	(a1)+,d0
		tst.b	d2
		beq	@f
		cmpi.b	#'"',d0
		beq	mask_menu_copy_end
@@:		cmpi.b	#$20,d0
		bcs	mask_menu_copy_end
		move.b	d0,(a2)+
		dbra	d1,mask_menu_copy_loop
		bra	mask_input_error
mask_menu_copy_end:
		clr.b	(a2)

		tst	d5
		beq	mask_menu_no_input2
1:
		lea	(subwin_mask_input,pc),a0
		moveq	#MES_IWILD,d0
		bsr	set_subwin_title
		jsr	(WinOpen)
		move	d0,d7
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

**		moveq	#0,d0
**		move	d7,d0
		moveq	#70,d1
		swap	d1
		lea	(sp),a1
		jsr	(MintReadLine)
		exg	d0,d7
		jsr	(WinClose)

		tst.l	d7
		bmi	mask_input_error
mask_menu_no_input2:
		lea	(sp),a1
		bsr	mask_i_c_option
		cmpi.b	#$20,(a1)
		bcs	mask_input_error	;-i/-c だけの入力は不可
mask_input_no_option:
		movea.l	(PATH_MASK,a6),a2
		move.l	(_ignore_case),(a2)+
		STRCPY	a1,a2

		lea	(MASK_REGEXP_SIZE,sp),sp
		bra	mask_reload_end
mask_input_error:
		lea	(MASK_REGEXP_SIZE,sp),sp
		bra	mask_error


* 行入力/メニュー選択肢先頭の -i/-c オプションを解釈する
* in	a1.l	文字列
* out	a1.l	先頭が -i/-c オプションなら、次の単語
*	ccrZ	1:-i/-c オプション 0:それ以外
* break	d0

mask_i_c_option:
		jbsr	skip_blank_a1

		cmpi.b	#'-',(a1)+
		bne	mask_ic_opt_end
		moveq	#1,d0
		cmpi.b	#'i',(a1)
		beq	@f
		moveq	#'c',d0
		sub.b	(a1),d0
		bne	mask_ic_opt_end
@@:
		addq.l	#1,a1
		cmpi.b	#TAB,(a1)
		beq	@f
		cmpi.b	#SPACE,(a1)
		bne	mask_ic_opt_end2
@@:
		move.l	d0,(_ignore_case)
		jbsr	skip_blank_a1
		moveq	#0,d0			;ccrZ=1
		rts
mask_ic_opt_end2:
		subq.l	#1,a1
mask_ic_opt_end:
		subq.l	#1,a1
		rts


subwin_mask_menu:
		SUBWIN	8,2,24,1,NULL,NULL
subwin_mask_input:
		SUBWIN	11,8,72,1,NULL,NULL


* &mask/&mark の引数を解釈する.
* in	d1.b	正規表現のデリミタ(SPACE or '|')
*	d7.l	引数の数(decode_argument_a0 の返値)
*	a0.l	引数バッファのアドレス(〃)
* out	d0.l	正規表現のバイト数(末尾の NUL を含むサイズ)
*	d1.l	初期カーソル位置(-l オプション)
*	a0.l	正規表現のアドレス
*	a1.l	タイトル文字列(-t オプション)
*	ccr	<tst.l d0> の結果
* 備考:
*	d1.b = SPACE の時、-l、-t オプションを解釈する.

mask_decode_argument:
		PUSH	d5/d7/a2-a3
		jsr	(init_i_c_option)
		moveq	#1,d5			;-l
		suba.l	a1,a1			;-t
		bra	mask_dec_arg_next
mask_dec_arg_opt_loop:
		jsr	(take_i_c_option)
		beq	mask_dec_arg_next
		move.b	(a0)+,d0
		beq	mask_dec_arg_next
		cmpi.b	#'-',d0
		bne	mask_dec_arg_pat
		cmpi.b	#SPACE,d1
		bne	mask_dec_arg_pat
		cmpi.b	#'l',(a0)
		beq	mask_dec_arg_opt_l
		cmpi.b	#'t',(a0)
		bne	mask_dec_arg_pat
*mask_dec_arg_opt_t:
		lea	(1,a0),a2		;-t"タイトル"
		move.l	d7,d0
@@:		tst.b	(a2)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
		move.l	d0,d7
		bra	mask_dec_arg_pat
@@:
		lea	(-1,a2),a0
		lea	(a0),a1
		bra	mask_dec_arg_skip
mask_dec_arg_opt_l:
		move.l	a0,-(sp)		;-l<n> : 初期カーソル位置指定
		addq.l	#1,a0
		jsr	(atoi_a0)
		bne	@f
		tst.b	(a0)
@@:		movea.l	(sp)+,a0
		bne	mask_dec_arg_pat
		move.l	d0,d5
mask_dec_arg_skip:
		tst.b	(a0)+
		bne	mask_dec_arg_skip
mask_dec_arg_next:
		subq.l	#1,d7
		bcc	mask_dec_arg_opt_loop
		moveq	#0,d0			;パターンなし
		bra	mask_dec_arg_end

mask_dec_arg_pat:
		subq.l	#1,a0			;パターン指定あり

		lea	(a0),a2			;読み込みポインタ
		lea	(a0),a3			;書き込み〃
mask_dec_arg_loop:
		bsr	mask_dec_arg_is_or
		bne	1f
@@:
		bsr	mask_dec_arg_is_or	;連続する空白は一つにする
		beq	@b
		subq.l	#1,a2
		move.b	d1,(a3)+		;or で繋げる
		bra	mask_dec_arg_loop
1:
		move.b	d0,(a3)+
		bne	mask_dec_arg_loop
		move.b	d1,(-1,a3)		;各引数同士を or で繋げる
		subq.l	#1,d7
		bcc	mask_dec_arg_loop

		move.l	a3,d0
		clr.b	-(a3)			;最後の or を潰す
		sub.l	a0,d0			;strlen(regexp)
mask_dec_arg_end:
		move.l	d5,d1			;-l
		tst.l	d0
		POP	d5/d7/a2-a3
		rts

mask_dec_arg_is_or:
		move.b	(a2)+,d0
		cmpi.b	#SPACE,d0
		beq	@f
		cmpi.b	#'|',d0
@@:		rts


set_subwin_title:
		jsr	(get_message)
		move.l	d0,(SUBWIN_TITLE,a0)
		rts


*************************************************
*		&get-volume-name		*
*************************************************

＆get_volume_name::
		lea	(underline,pc),a1	;変数名
		lea	(get_volname_wild,pc),a2
		DOS	_CURDRV
		addi.b	#'A',d0
		move.b	d0,(a2)			;ドライブ名

		bra	get_vol_name_arg_next
get_vol_name_arg_loop:
		tst.b	(a0)
		beq	get_vol_name_arg_skip
		cmpi.b	#':',(1,a0)
		beq	get_vol_name_drv
		lea	(a0),a1			;変数名の指定
		bra	get_vol_name_arg_skip
get_vol_name_drv:
		move.b	(a0)+,(a2)		;d: ドライブ名の指定
get_vol_name_arg_skip:
		tst.b	(a0)+
		bne	get_vol_name_arg_skip
get_vol_name_arg_next:
		subq.l	#1,d7
		bcc	get_vol_name_arg_loop

		lea	(-FILES_SIZE,sp),sp
		move	#1<<VOLUME,-(sp)
		pea	(a2)			;d:\*.*
		pea	(6,sp)
		DOS	_FILES
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	get_vol_name_error

		lea	(FILES_FileName,sp),a2
		jsr	(set_user_value_a1_a2)
get_vol_name_end:
		lea	(FILES_SIZE,sp),sp
		bra	set_status
**		rts
get_vol_name_error:
		moveq	#0,d0
		bra	get_vol_name_end


get_volname_wild:
		.dc.b	'A:\'
wildcard_all:	.dc.b	'*.*',0

underline:	.dc.b	'_',0
		.even


*************************************************
*		&edit-volume-name		*
*************************************************

		.offset	0
		.ds.b	4			;d:/の分
~voled_inpbuf:	.ds.b	22+1
		.even
~voled_files:	.ds.b	FILES_SIZE
VOLED_WORK_SIZE:
		.text

＆edit_volume_name::
		lea	(-VOLED_WORK_SIZE,sp),sp
		tst.b	(PATH_NODISK,a6)
		bmi	edit_volume_name_end

		move	(PATH_DRIVENO,a6),d1
		bsr	dos_drvctrl_d1
		btst	#DRV_PROTECT,d0
		beq	@f
		jsr	(print_write_protect_error)
		bra	edit_volume_name_end
@@:
		GETMES	MES_VOLUM
		movea.l	d0,a1
		bra	edit_vol_arg_next
edit_vol_arg_loop:
		cmpi.b	#'-',(a0)
		bne	edit_vol_arg_skip
		cmpi.b	#'t',(1,a0)
		bne	edit_vol_arg_skip
*edit_vol_option_t:
		addq.l	#2,a0			;-t"タイトル"
@@:		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	edit_volume_name_end	;引数がない
@@:
		lea	(-1,a0),a1
edit_vol_arg_skip:
		tst.b	(a0)+
		bne	edit_vol_arg_skip
edit_vol_arg_next:
		subq.l	#1,d7
		bcc	edit_vol_arg_loop

		lea	(subwin_edit_vol,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		move.l	d0,d7

		lea	(~voled_files,sp),a1
		bsr	files_volume_label
		lea	(~voled_inpbuf,sp),a2
		bpl	@f
		clr.b	(a1)
@@:		STRCPY	a1,a2

		lea	(~voled_inpbuf,sp),a1
		bsr	remove_volume_label_period

		move.l	d7,d0
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

**		moveq	#0,d0
**		move	d7,d0
		moveq	#22,d1
		tst	(＄volp)
		beq	@f
		moveq	#21,d1
@@:		swap	d1
		jsr	(MintReadLine)
		exg	d0,d7
		jsr	(WinClose)

		tst.l	d7
		bmi	edit_volume_name_abort

		bsr	edit_volume_name_add_period

		lea	(~voled_files+FILES_FileName,sp),a2
		tst.b	(a2)
		bne	@f
		tst.b	(a1)
		bne	edit_volume_name_create
		bra	edit_volume_name_abort
@@:
		tst.b	(a1)
		bne	edit_volume_name_rename
		bra	edit_volume_name_delete

edit_volume_name_delete:
		bsr	edit_volume_name_add_root_dir_a2
		clr	-(sp)
		move.l	a2,-(sp)
		DOS	_CHMOD
		DOS	_DELETE
		addq.l	#6,sp
		bra	edit_volume_name_end

edit_volume_name_create:
		bsr	edit_volume_name_add_root_dir_a1
		move	#1<<VOLUME,-(sp)
		move.l	a1,-(sp)
		DOS	_CREATE
		move	d0,(sp)
		DOS	_CLOSE
		addq.l	#6,sp
		bra	edit_volume_name_end

edit_volume_name_rename:
		bsr	edit_volume_name_add_root_dir_a1
		bsr	edit_volume_name_add_root_dir_a2
		move.l	a1,-(sp)		;new
		move.l	a2,-(sp)		;old
		DOS	_RENAME
		addq.l	#8,sp
		bra	edit_volume_name_end

edit_volume_name_end:
		bsr	get_and_print_volume_label
		movea.l	(PATH_OPP,a6),a6
		bsr	get_and_print_volume_label
		movea.l	(PATH_OPP,a6),a6
edit_volume_name_abort:
		lea	(VOLED_WORK_SIZE,sp),sp
		rts

edit_volume_name_add_root_dir_a1:
		move.b	#'\',-(a1)
		move.b	#':',-(a1)
		move.b	(PATH_DIRNAME,a6),-(a1)
		rts
edit_volume_name_add_root_dir_a2:
		move.b	#'\',-(a2)
		move.b	#':',-(a2)
		move.b	(PATH_DIRNAME,a6),-(a2)
		rts

edit_volume_name_add_period:
		tst	(＄volp)
		beq	edit_volume_name_add_period_end

		lea	(22,a1),a0
		moveq	#4-1,d0
@@:
		move.b	-(a0),(1,a0)
		dbra	d0,@b
		move.b	#'.',(a0)
edit_volume_name_add_period_end:
		rts


subwin_edit_vol:
		SUBWIN	30,9,36,1,NULL,NULL


*************************************************
*		&edit-env-variable		*
*************************************************

＆edit_env_variable::
		GETMES	MES_STENV
		movea.l	d0,a1
		bra	edit_env_arg_next
edit_env_arg_loop:
		cmpi.b	#'-',(a0)
		bne	edit_env_arg_skip
		cmpi.b	#'t',(1,a0)
		bne	edit_env_arg_skip
*edit_env_option_t:
		addq.l	#2,a0			;-t"タイトル"
@@:		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
		rts				;引数がない
@@:
		lea	(-1,a0),a1
edit_env_arg_skip:
		tst.b	(a0)+
		bne	edit_env_arg_skip
edit_env_arg_next:
		subq.l	#1,d7
		bcc	edit_env_arg_loop

		lea	(Buffer),a5
		clr.b	(a5)

		lea	(subwin_edit_env,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		jsr	(WinOpen)
		moveq	#62,d7			;ウィンドウ幅
		swap	d7
		move	d0,d7
edit_env_loop:
		move.l	d7,d0
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

		move.l	#255<<16,d1
		lea	(a5),a1
		jsr	(MintReadLine)
		tst.l	d0
		bmi	edit_env_abort		;キャンセル
		tst.b	(a1)+
		beq	edit_env_abort		;空文字列

		moveq	#'=',d1
@@:
		move.b	(a1)+,d0
		beq	edit_env_no_equ		;変数名だけ入力された
		cmp.b	d1,d0
		bne	@b
*edit_env_set:
		pea	(a1)			;'=' の次
		clr.b	-(a1)
		clr.l	-(sp)
		pea	(a5)			;変数名
		DOS	_SETENV
		lea	(12,sp),sp
		jbsr	mint_getenv
edit_env_abort:
		move	d7,d0
		jmp	(WinClose)
**		rts

edit_env_no_equ:
		pea	(a1)			;NUL の次
		clr.l	-(sp)
		pea	(a5)			;変数名
		DOS	_GETENV
		move.b	d1,-(a1)		;'='
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bpl	edit_env_loop		;変数の値を補完して繰り返す

		clr.b	(1,a1)
		bra	edit_env_loop		;'=' だけ補完


subwin_edit_env:
		SUBWIN	16,9,64,1,NULL,NULL


* カーソルバー反転 ---------------------------- *

* 両方反転
ReverseCursorBarBoth::
		bsr	ReverseCursorBar
		bra	ReverseCursorBarOpp
**		rts

* 反対側反転
ReverseCursorBarOpp::
		movea.l	(PATH_OPP,a6),a6
		bsr	@f
		movea.l	(PATH_OPP,a6),a6
		rts
@@:
		PUSH	d0-d1
		move	(＄obcl),d1
		bra.s	@f

* カーソル側反転
ReverseCursorBar::
		PUSH	d0-d1
		move	(＄cbcl),d1
@@:
		move.b	(write_disable_flag,pc),d0
		bne	@f

		move	(PATH_WIN_FILE,a6),d0
		jsr	(WinUnderLine)
@@:
		POP	d0-d1
		rts


* ステータス表示系 ---------------------------- *

* "write protect" を表示する.
PrintWProtect::
		bsr	SetColor2
		moveq	#MES_WPERR,d0
		bra.s	@f

* "not ready" を表示する.
PrintNotReady::
		bsr	SetColor2
		moveq	#MES_NREDY,d0
		bra.s	@f

* "false" を表示する.
PrintFalse::
		bsr	SetColor2
		moveq	#MES_FAILD,d0
		bra.s	@f

* "skip" を表示する.
PrintSkip::
		bsr	SetColor3
		moveq	#MES_SKIPF,d0
		bra.s	@f

* "completed" を表示する.
PrintCompleted::
		bsr	SetColor3
		moveq	#MES_COMPL,d0
@@:
		bsr	PrintMsgCrlf
		bra	SetColor3
**		rts


* 指定した番号のメッセージと復帰改行を表示する.
PrintMsgCrlf::
		bsr	PrintMsg
		bra	PrintCrlf
**		rts


* 復帰改行を出力する.
PrintCrlf::
		pea	(crlf_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		rts


* 指定した番号のメッセージを表示する.
PrintMsg::
		jsr	(get_message)
		move.l	d0,-(sp)
		DOS	_PRINT
		addq.l	#4,sp
		rts


* コンソール制御系 ---------------------------- *

* 表示色を黄色強調に変更する.
SetColor2_emp::
		move.l	d0,-(sp)
		move	#YELLOW+EMPHASIS,-(sp)
		bra.s	@f

* 表示色を黄色に変更する.
SetColor2::
		move.l	d0,-(sp)
		move	#YELLOW,-(sp)
		bra.s	@f

* 表示色を白強調に変更する.
SetColor3_emp::
		move.l	d0,-(sp)
		move	#WHITE+EMPHASIS,-(sp)
		bra.s	@f

* 表示色を白に変更する.
SetColor3::
		move.l	d0,-(sp)
		move	#WHITE,-(sp)
@@:
		move	#2,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		move.l	(sp)+,d0
		rts


* コンソールのカーソルを消去する(点滅オフ).
CursorBlinkOff::
		move.l	d0,-(sp)
		move	#18,-(sp)
		bra.s	@f

* コンソールのカーソルを表示する(点滅オン).
CursorBlinkOn::
		move.l	d0,-(sp)
		move	#17,-(sp)
@@:
		DOS	_CONCTRL
		addq.l	#2,sp
		move.l	(sp)+,d0
ConsoleClear_end:
		rts


* %cclr 0 の時、コンソールを初期化する.
ConsoleClear2::
		tst	(＄cclr)
		bne.s	ConsoleClear_end

* コンソールを初期化する.
ConsoleClear::
		PUSH	d0-d1
		moveq	#2,d1
		IOCS	_B_CLR_ST
		POP	d0-d1
		rts


* コンソールのカーソル位置を退避する.
SaveCursor::
		PUSH	d0-d1
		moveq	#-1,d1
		IOCS	_B_LOCATE
		move.l	d0,(CursorPosition)
		POP	d0-d1
		rts


* コンソールのカーソル位置を復帰する.
RestoreCursor::
		PUSH	d0-d2
		movem	(CursorPosition,pc),d1/d2
		IOCS	_B_LOCATE
		POP	d0-d2
		rts


CursorPosition::
		.ds.l	1


* ファンクションキー制御 ---------------------- *

* 起動前の表示モードを収得する.
get_fnckey_mode::
		move.l	#14<<16+$ffff,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		move	d0,(orig_fnckey_mode)
		rts


* 起動前の表示モードに戻す.
restore_fnckey_mode::
		move.l	d0,-(sp)
		st	(restore_fnckey_flag)
		move	(orig_fnckey_mode,pc),-(sp)
		move	#14,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		move.l	(sp)+,d0
		rts


* 起動前の表示モードに戻していた場合、ファンクションキーを
* 表示する(%fnmd 0 の時は消去する).
reset_fnckey_mode::
		move.b	(restore_fnckey_flag,pc),d0
		beq	fnckey_mode_end		;戻してない

		clr.b	(restore_fnckey_flag)

* ファンクションキーを表示する(%fnmd 0 の時は消去する).
* look.s からも呼ばれる.
fnckey_disp_on2::
		tst	(＄fnmd)
		beq	fnckey_disp_off

		IOCS	_B_SFTSNS
		andi	#1,d0			;SHIFT キー
		bra.s	@f


* ファンクションキーを表示する.
* SHIFT キーの押し下げ状態によって表示を切り換える.
fnckey_disp_on:
		tst	(＄fnmd)
		beq	fnckey_mode_end

		IOCS	_B_SFTSNS
		andi	#1,d0			;SHIFT キー
		cmp	(fnckey_disp_mode,pc),d0
		beq	fnckey_mode_end
@@:
		move	d0,(fnckey_disp_mode)

		move	d0,-(sp)
		move	#14,-(sp)		;ファンクションキー表示切り換え
		DOS	_CONCTRL
		addq.l	#4,sp
fnckey_mode_end:
		rts


* ファンクションキーを消去する.
fnckey_disp_off::
		move.l	#14<<16+3,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		rts


orig_fnckey_mode::
		.ds	1
fnckey_disp_mode:
		.ds	1
restore_fnckey_flag:
		.ds.b	1

crlf_mes:	.dc.b	CR,LF,0
		.even


* FEP 制御 ------------------------------------ *

* FEP を閉じ、ロックする.
fep_disable::
		clr.l	-(sp)			;解除
		pea	(1)
		DOS	_KNJCTRL
		addq.l	#8,sp
		clr.l	-(sp)			;固定
		bra	@f

* FEP のロックを解除する.
fep_enable::
		pea	(1)			;固定解除
@@:		pea	(7)
		DOS	_KNJCTRL
		addq.l	#8,sp
		rts


*************************************************
*		&eject				*
*************************************************

＆eject::
		moveq	#0,d4			;-q
		moveq	#0,d5			;ドライブ指定あり
		moveq	#0,d6
		bra	eject_arg_next
eject_arg_loop:
		move.b	(a0)+,d0
		beq	eject_arg_next
		cmpi.b	#'-',d0
		bne	eject_arg
*eject_option:
		move.b	(a0)+,d0
		beq	eject_arg_next
		cmpi.b	#'q',d0
		bne	eject_arg_skip
		moveq	#-1,d4			;-q : 無表示モード
		bra	eject_arg_skip
eject_arg:
		cmpi.b	#':',(a0)
		subq.l	#1,a0
		bne	eject_device_name
		tst.b	(2,a0)
		bne	eject_drive_name_error

		moveq	#$20,d0			;"d:"
		or.b	(a0),d0
		cmpi.b	#'z',d0
		bhi	eject_drive_name_error
		subi.b	#'a'-1,d0
		bls	eject_drive_name_error
		moveq	#1,d5			;ドライブ指定あり
		bra	@f
eject_device_name:
		moveq	#1,d5			;〃
		bsr	device_name_to_drive_no
		bmi	eject_drive_name_error
@@:
		bsr	eject_sub
		add.l	d0,d6
eject_arg_skip:
		tst.b	(a0)+
		bne	eject_arg_skip
eject_arg_next:
		subq.l	#1,d7
		bcc	eject_arg_loop
		tst	d5
		bne	@f

		move	(PATH_DRIVENO,a6),d0	;ドライブ省略時はカレントを排出
		bsr	eject_sub
		add.l	d0,d6
@@:
		move.l	d6,d0
eject_end:
		bra	set_status
**		rts


* ドライブ名またはメディア名が不正
eject_drive_name_error:
		tst	d4
		bne	eject_arg_skip		;-q 指定時は何も表示しない

		pea	(eject_drive_name_err_mes1,pc)
		DOS	_PRINT
		move.l	a0,(sp)
		DOS	_PRINT
		pea	(eject_drive_name_err_mes2,pc)
		DOS	_PRINT
		addq.l	#8,sp
		bra	eject_arg_skip


* 指定ドライブのメディアを排出する
* in	d0.w	ドライブ番号(1～26)
* out	d0.l	0:エラー 1:正常終了
* 備考:
*	メディア未挿入の場合は正常終了を返す.

eject_sub:
		PUSH	d1/d7/a0
		move	d0,d7

		move.l	#('A'-1)<<24+':'<<16,-(sp)
		add.b	d7,(sp)
		lea	(-64,sp),sp
		move.l	sp,-(sp)
		pea	(64+4,sp)
		clr	-(sp)			;ASSIGN_GET
		DOS	_ASSIGN
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		lea	(64+4,sp),sp
		bmi	eject_drive_error	;未使用ドライブ
		moveq	#READRV,d1
		cmp.l	d0,d1
		bne	eject_drive_error	;仮想 dir/drive だった

		moveq	#-1,d0
		bsr	eject_mintarc_abort
		movea.l	(PATH_OPP,a6),a6
		moveq	#1,d0
		bsr	eject_mintarc_abort
		bne	@f
		jbsr	ReverseCursorBar	;反対側はカーソル描画を訂正する
@@:		movea.l	(PATH_OPP,a6),a6
		tst	d0
		bne	@f
		jbsr	ReverseCursorBarOpp	;〃
@@:
		jsr	(＆sync)		;何故か排出時にバッファの書き戻しが
						;行われないので、自前でフラッシュする.
		move	d7,-(sp)
		addq.b	#3,(sp)			;MD=3:排出許可
		DOS	_DRVCTRL
		subq.b	#3-1,(sp)		;MD=1:排出
		DOS	_DRVCTRL
		clr.b	(sp)			;MD=0:状態検査
		DOS	_DRVCTRL
		addq.l	#2,sp
		btst	#DRV_INSERT,d0
		beq	@f

		pea	(PATH_DIRNAME,a6)
		CHDIR_PRINT	'e'
		DOS	_CHDIR
		addq.l	#4,sp
@@:
		moveq	#1,d0			;正常終了
eject_drive_end:
		POP	d1/d7/a0
		rts
eject_drive_error:
		moveq	#0,d0
		bra	eject_drive_end

eject_mintarc_abort:
		cmp	(PATH_DRIVENO,a6),d7
		bne	@f
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		jsr	(quit_mintarc)
		lsr	#1,d0
@@:
		rts


* メディア名/ユニット番号からドライブ番号を収得する
* in	a0.l	メディア名/ユニット番号
* out	d0.l	ドライブ番号(1=A: 2=B: … 26=Z:、-1 ならエラー)
*	ccr	<tst.l d0>

device_name_to_drive_no:
		PUSH	d1-d7/a0-a6
		lea	(-26*2,sp),sp
		lea	(medianame_table,pc),a1
device_name_loop:
		move.b	(a1)+,d4		;media byte
		lea	(a0),a2
		lea	(a1),a3
device_name_compare_loop:
		cmpm.b	(a2)+,(a3)+		;メディア名を比較
		beq	1f
@@:
		tst.b	(a1)+
		bne	@b
		tst.b	d4
		bne	device_name_loop
		bra	device_name_error	;見つからなかった
1:
		tst.b	(a3)
		bne	device_name_compare_loop

		lea	(a2),a1
		jsr	(atoi_a1)		;d4.b=media byte
		move.l	d0,d5			;d5.l=unit no.

		lea	(sp),a2
		bsr	eject_get_drive_list

		moveq	#0,d0
		moveq	#26-1,d7
device_name_search_drive_loop:
		move	(a2)+,d0		;論理ドライブ番号/メディアバイト
		tst.b	d0
		beq	device_name_search_drive_skip
		cmp.b	d0,d4
		beq	@f			;同じメディアバイト
		tst.b	d4
		bne	device_name_search_drive_skip
		subi.b	#$e0,d0
		bcs	device_name_search_drive_skip
i:=0
	.irp	mb,MB_2DD10,MB_1D9,MB_2D9,MB_1D8,MB_2D8,MB_2HT,MB_2HS,MB_2HDE,MB_1DD9,MB_1DD8,MB_2HQ,MB_2DD8,MB_2DD9,MB_2HC,MB_2HD
		i:=i+1<<(mb-$e0)
	.endm
		move.l	#i,d1
		btst	d0,d1
		beq	device_name_search_drive_skip	;fdではない
@@:
		subq.l	#1,d5
		bcc	device_name_search_drive_skip

		lsr	#8,d0			;目的のユニットを見つけた
		bra	device_name_end

device_name_search_drive_skip:
		dbra	d7,device_name_search_drive_loop
device_name_error:
		moveq	#-1,d0
device_name_end:
		lea	(26*2,sp),sp
		POP	d1-d7/a0-a6
		tst.l	d0
		rts


* 物理ドライブ番号順にメディアバイトとユニット番号を調べる.
* in	a2.l	バッファ(2byte*26)
*		offset	size
*		0	1.b	論理ドライブ番号(1～26)
*		1	1.b	ユニット番号
* OS ワークを参照したくないので、現在は論理ドライブ番号順にしている.
* むしろこの方が良いかもしれない.

eject_get_drive_list:
		PUSH	d0-d7/a0-a6
		moveq	#26/2-1,d0
@@:
		clr.l	(a2)+
		dbra	d0,@b
		lea	(-26*2,a2),a2

		lea	(-64,sp),sp
		lea	(sp),a6			;割り当て収得バッファ
		move.l	#'A:'<<16,-(sp)
		lea	(sp),a5			;対象ドライブ
		moveq	#1,d7

eject_get_drive_list_loop:
		move.l	a6,-(sp)
		move.l	a5,-(sp)
		clr	-(sp)			;ASSIGN_GET
		DOS	_ASSIGN
		addq.l	#10-4,sp
		move.l	d0,(sp)+
		bmi	eject_get_drive_list_next
		moveq	#VIRDRV,d1
		cmp.l	d0,d1
		beq	eject_get_drive_list_next

		move.l	d0,d6			;解除前のモード
		moveq	#READRV,d1
		cmp.l	d0,d1
		beq	@f
		moveq	#VIRDIR,d1
		cmp.l	d0,d1
		bne	eject_get_drive_list_next

		move.l	a5,-(sp)		;仮想ディレクトリなら一時的に解除しておく
		move	#ASSIGN_UNSET,-(sp)
		DOS	_ASSIGN
		addq.l	#6,sp
		tst.l	d0
		bmi	eject_get_drive_list_next
@@:
		move	d7,d1
		jbsr	dos_getdpb_cd
		bmi	@f
.if 0
		moveq	#0,d0
		move.l	a1,-(sp)
		lea	(DriveTable-1),a1
		adda	d7,a1
		IOCS	_B_BPEEK		;物理ドライブ番号(0～25)
		movea.l	(sp)+,a1
.else
		move	d7,d0			;論理ドライブ順で済ます
.endif
		add	d0,d0
		move.b	d7,(0,a2,d0.w)
		move.b	(DPB_MediaByte,a1),(1,a2,d0.w)
@@:
		moveq	#VIRDIR,d0
		cmp.l	d0,d6
		bne	eject_get_drive_list_next

		move	d6,-(sp)
		move.l	a6,-(sp)
		move.l	a5,-(sp)
		move	#ASSIGN_SET,-(sp)
		DOS	_ASSIGN
		lea	(12,sp),sp
eject_get_drive_list_next:
		addq	#1,d7
		addq.b	#1,(a5)
		cmpi.b	#'Z',(a5)
		bls	eject_get_drive_list_loop

		lea	(4+64,sp),sp
		POP	d0-d7/a0-a6
		rts

medianame_table:
		.dc.b	MB_DAT,		'dat',0
		.dc.b	MB_CDROM,	'cd',0
		.dc.b	MB_MO,		'mo',0
		.dc.b	MB_SCSIHD,	'hd',0
		.dc.b	MB_SASIHD,	'sasi',0
		.dc.b	MB_RAMDISK,	'ram',0
		.dc.b	0,		'fd',0

eject_drive_name_err_mes1:
		.dc.b	'&eject: ドライブ指定が不正です(',0
eject_drive_name_err_mes2:
		.dc.b	').',CR,LF,0
		.even


*************************************************
*		&quit				*
*************************************************

＆quit::
		GETMES	MES_EXITC
		movea.l	d0,a1
		moveq	#1,d6			;初期カーソル位置
		bra	quit_arg_next
quit_arg_loop:
		cmpi.b	#'-',(a0)+
		bne	quit_arg_skip
		move.b	(a0)+,d0
		beq	quit_arg_next
		cmpi.b	#'t',d0
		beq	quit_opt_t
		cmpi.b	#'l',d0
		bne	quit_arg_skip
*quit_opt_l:
		jsr	(atoi_a0)		;-l<n> : 初期カーソル位置の指定
		bne	quit_arg_skip
		tst.b	(a0)+
		bne	quit_arg_skip
		move	d0,d6
		bra	quit_arg_skip
quit_opt_t:
@@:		tst.b	(a0)+			;-t"タイトル"
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	quit_arg_end
@@:
		lea	(-1,a0),a1
quit_arg_skip:
		tst.b	(a0)+
		bne	quit_arg_skip
quit_arg_next:
		subq.l	#1,d7
		bcc	quit_arg_loop
quit_arg_end:
		lea	(subwin_quit,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		bsr	quit_make_menu		;選択肢を作る

		move	d6,d0
		jsr	(menu_sub)
		beq	quit_cancel

		subq	#2,d0
		bcs	quit_end		;Q
		lea	(a6),a1
		beq	@f			;1
		movea.l	(PATH_OPP,a6),a1	;2
@@:		addq.l	#PATH_DIRNAME,a1
		lea	(boot_directory),a2
		STRCPY	a1,a2			;終了パスを書き換える
quit_end:
		bra	quit_normal

quit_make_menu:
		lea	(Buffer+4*3),a1		;選択肢リストのバッファ
		lea	(a1),a2			;本文のバッファ

		moveq	#'2',d0
		movea.l	(PATH_OPP,a6),a3
		addq.l	#PATH_DIRNAME,a3
		bsr	quit_copy_path

		moveq	#'1',d0
		lea	(PATH_DIRNAME,a6),a3
		bsr	quit_copy_path

		moveq	#'Q',d0
		lea	(boot_directory),a3
		bra	quit_copy_path
**		rts

quit_copy_path:
		move.l	a2,-(a1)		;文字列のアドレス

		move.b	d0,(a2)+		;ショートカットキー
		STRCPY	a3,a2			;本文
quit_cancel:
		rts


subwin_quit:
		SUBWIN	14,8,68,3,NULL,NULL


*************************************************
*		&quick-exit			*
*************************************************

＆quick_exit::
@@:		subq.l	#1,d7
		bcs	quick_exit_end		;無指定
		tst.b	(a0)+
		beq	@b
		subq.l	#1,a0			;終了パス

		lea	(Buffer),a1
		lea	(a1),a2
		STRCPY	a0,a2
		jbsr	fullpath_a1
		bmi	quick_exit_end

		lea	(boot_directory),a2
		STRCPY	a1,a2
quick_exit_end:
		bra	quit_normal


* 終了する
quit_normal:
		move	#KQ_EXIT_Q<<8,d0
		jsr	(execute_quick_no)
		move	#KQ_EXIT_2<<8,d0
		jsr	(execute_quick_no)

		jbsr	＆save_path_history

		jsr	(quit_mintarc_all)
		movea.l	(PATH_OPP,a6),a6
		jsr	(quit_mintarc_all)
		movea.l	(PATH_OPP,a6),a6

* どこから呼ばれているか分からないので、
* 直接終了ルーチンに飛んでしまう.
		jmp	(prepare_exit_mint)
**		rts


* 低水準キー入力 ------------------------------ *

* 擬似キーコードからの入力も返す IOCS _B_KEYINP 拡張版
* out	d0.l	scan code

iocs_b_keyinp_ex::
		bsr	iocs_b_keyinp_ex_only
		tst.l	d0
		bne	@f

		IOCS	_B_KEYSNS
		tst.l	d0
		beq	@f

		IOCS	_B_KEYINP
		lsr	#8,d0
		tst.b	d0
		bpl	@f
		moveq	#0,d0		;ctrl releaseが返っちゃうので
@@:		rts

iocs_b_keyinp_ex_only:
		move.l	a0,-(sp)
		lea	(iocs_b_keyinp_ex_key,pc),a0
		moveq	#0,d0
		move.b	(a0),d0
		clr.b	(a0)
		movea.l	(sp)+,a0
		rts


* 単純リバース(sort_directory の下請け) ------- *
* in	d0.l	エントリ数
*	a0.l	バッファ先頭

sort_dir_reverse:
		PUSH	d0-d2/a0-a1
		moveq	#sizeof_DIR,d1
		mulu	d0,d1
		lea	(-sizeof_DIR,a0,d1.l),a1
		lsr.l	#1,d0
		moveq	#-sizeof_DIR*2,d2
		bra	1f
sort_dir_rev_loop:
	.rept	sizeof_DIR/4
		move.l	(a0),d1			;exg.l (a0)+,(a1)+
		move.l	(a1),(a0)+
		move.l	d1,(a1)+
	.endm
		adda.l	d2,a1
1:		dbra	d0,sort_dir_rev_loop
		POP	d0-d2/a0-a1
		rts


* ディレクトリリバース ------------------------ *
* バッファを逆転させる. ディレクトリを上に集めていた場合は、
* ディレクトリとファイルを別々に扱う.

reverse_directory:
		PUSH	d0-d7/a0-a6
		jbsr	get_dir_buf_a4_d7
		lea	(a4),a0
		moveq	#0,d0
		move	d7,d0
		subq	#1,d7
		bls	rev_dir_end

		cmpi	#1,(＄sort)
		bcs	@f			;%sort 0 = ディレクトリを上に集める
		beq	rev_dir_sort1		;      1 = 集めない
		tst.b	(PATH_SORT,a6)		;      2 = ソート時のみ集める
		beq	rev_dir_sort1		;ソートしてないので集めていない
@@:
		lea	(a0),a1
		moveq	#DIRECTORY,d1
		moveq	#sizeof_DIR,d2
		move	d0,d3
		subq	#1,d3
@@:
		btst	d1,(DIR_ATR,a1)		;先頭にあるディレクトリエントリを数える
		adda.l	d2,a1
		dbeq	d3,@b
		bne	@f
		suba.l	d2,a1
@@:
		move.l	d0,d1
		move.l	a1,d0
		sub.l	a0,d0
		divu	#sizeof_DIR,d0		;ディレクトリ数
**		andi.l	#$ffff,d0
		sub.l	d0,d1			;残り(ファイル数)
		bsr	sort_dir_reverse	;まずディレクトリだけリバース

		lea	(a1),a0			;次にファイルだけリバース
		move.l	d1,d0
rev_dir_sort1:
		bsr	sort_dir_reverse
rev_dir_end:
		POP	d0-d7/a0-a6
		rts


* ディレクトリソート -------------------------- *
* 引数/返値なし
* リバースモードはエントリ比較時に同時に処理する.

sort_table:
		.dc	       no_sort-$
		.dc	 filename_sort-$
		.dc	timestamp_sort-$
		.dc	      ext_sort-$
		.dc	     size_sort-$

sort_directory:
		PUSH	d0-d7/a0-a6
		jbsr	get_dir_buf_a4_d7
		lea	(a4),a0
		moveq	#0,d0
		move	d7,d0
		subq	#1,d7
		bls	sort_directory_end

		lea	(sort_reverse_flag,pc),a4
		move.b	(PATH_SORTREV,a6),(a4)
		move	(＄srtr),d6
		eor.b	d6,(a4)

		moveq	#0,d1
		move.b	(PATH_SORT,a6),d1
		add	d1,d1
		lea	(sort_table,pc,d1.w),a4
		adda	(a4),a4			;比較ルーチン

		lea	(ctypetable,pc),a5

;ヒープソート開始
		move.l	d0,d7
		move.l	d0,d1
		lsr.l	#1,d1
sort_dir_loop1:
		move.l	d1,-(sp)
		bsr	sort_make_heaptree	;ヒープ(二分木)を作成
		move.l	(sp)+,d1
		subq.l	#1,d1
		bne	sort_dir_loop1
		bra	@f
sort_dir_loop2:
		bsr	sort_make_heaptree	;ヒープを作り直す
@@:
		moveq	#1,d1
		move.l	d7,d2
		bsr	sort_sort_sort		;先頭要素を最後に持っていく
		subq.l	#1,d7
		bne	sort_dir_loop2
;ヒープソート終了

sort_directory_end:
		POP	d0-d7/a0-a6
		rts

;ヒープ作成開始
sort_make_heaptree:
		move.l	d7,d4
		bra	@f
sort_mk_loop:
		bsr	sort_sort_sort		;[d1] と [d1*2+1]or[d1*2] を交換
		move.l	d2,d1
@@:
		move.l	d1,d2
		add.l	d2,d2
		cmp.l	d4,d2
		beq	@f			;この節点からの枝は1本だけ
		bhi	sort_mk_end

		move.l	d2,d3
		addq.l	#1,d3
		exg.l	d1,d3
		bsr	sort_mk_sub		;[d1*2+1] と [d1*2] の要素を比較
		exg.l	d1,d3
		tst.l	d0
		bmi	@f
		move.l	d3,d2			;[d1*2+1] か [d1*2] のどちらか大きい方
@@:
		bsr	sort_mk_sub		;[d1] と [d1*2+1]or[d1*2] の要素を比較
		tst.l	d0
		bmi	sort_mk_loop
sort_mk_end:
		rts
;ヒープ作成終了

sort_mk_sub:
		PUSH	d1-d4/a0-a1
		moveq	#sizeof_DIR,d0
		mulu	d0,d2
		mulu	d0,d1
		lea	(-sizeof_DIR,a0,d2.l),a1
		lea	(-sizeof_DIR,a0,d1.l),a0

		cmpi	#1,(＄sort)
		beq	@f

		moveq	#1<<DIRECTORY,d0
		moveq	#1<<DIRECTORY,d1
		and.b	(a1),d0
		and.b	(a0),d1
		sub.l	d1,d0
		bne	1f
@@:
		jsr	(a4)
1:
		POP	d1-d4/a0-a1
		rts


sort_sort_sort:
		PUSH	a0-a1
		moveq	#sizeof_DIR,d0
		mulu	d2,d0
		lea	(-sizeof_DIR,a0,d0.l),a1
		moveq	#sizeof_DIR,d0
		mulu	d1,d0
		lea	(-sizeof_DIR,a0,d0.l),a0
	.rept	sizeof_DIR/4
		move.l	(a0),d0			;exg.l (a0)+,(a1)+
		move.l	(a1),(a0)+
		move.l	d0,(a1)+
	.endm
		POP	a0-a1
		rts


;ソート無し
no_sort:
**		move	(DIR_SERNO,a0),d0
**		sub	(DIR_SERNO,a1),d0
**		swap	d0
		move.l	(DIR_SERNO,a0),d0
		sub.l	(DIR_SERNO,a1),d0	;必ず not equal になる

		btst	#0,(sort_reverse_flag,pc)
		beq	@f
		neg.l	d0
@@:		rts


;ファイル名ソート
filename_sort:
		addq.l	#DIR_NAME,a0
		addq.l	#DIR_NAME,a1
		moveq	#0,d0
		moveq	#0,d1
		tst	(＄srtc)
		bne	filename_sort_exact_loop
filename_sort_loop:
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		beq	filename_sort_exact	;同じなら大文字小文字区別で比較し直す
		tst.b	(a5,d0.w)
		bmi	filename_sort_mb
		tst.b	(a5,d1.w)
		bmi	filename_sort_diff	;1byte 文字 <-> 2byte 文字

		tst	d6
		bpl	@f			;数字もそのまま比較

		btst	#IS_DIGIT,(a5,d0.w)	;数値認識ソート(不完全)
		beq	@f
		btst	#IS_DIGIT,(a5,d1.w)
		beq	@f
		bsr	count_digit_figure
		bne	filename_sort_digit_diff
@@:
		cmp.b	d0,d1
		beq	filename_sort_loop

		btst	#IS_LOWER,(a5,d0.w)
		beq	@f
		andi.b	#$df,d0			;大文字化
@@:
		btst	#IS_LOWER,(a5,d1.w)
		beq	@f
		andi.b	#$df,d1			;〃
@@:
		cmp.b	d0,d1
		beq	filename_sort_loop
filename_sort_diff:
		sub.l	d1,d0
filename_sort_digit_diff:
		btst	#0,(sort_reverse_flag,pc)
		beq	@f
		neg.l	d0
@@:
filename_sort_error:
		rts

filename_sort_mb:
		tst.b	(a5,d1.w)
		bpl	filename_sort_diff	;2byte 文字 <-> 1byte 文字
		cmp.b	d0,d1
		bne	filename_sort_diff

		move.b	(a0)+,d0
		move.b	(a1)+,d1
		cmp.b	d0,d1
		beq	filename_sort_loop
		bra	filename_sort_diff

filename_sort_exact:
		lea	(DIR_NAME-(DIR_NUL+1),a0),a0
		lea	(DIR_NAME-(DIR_NUL+1),a1),a1
filename_sort_exact_loop:
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		beq	filename_sort_error	;完全に同じファイル名だった

		tst	d6
		bpl	@f			;数字もそのまま比較

		btst	#IS_DIGIT,(a5,d0.w)	;数値認識ソート(不完全)
		beq	@f
		btst	#IS_DIGIT,(a5,d1.w)
		beq	@f
		bsr	count_digit_figure
		bne	filename_sort_digit_diff
@@:
		cmp.b	d0,d1
		beq	filename_sort_exact_loop
		bra	filename_sort_diff

count_digit_figure:
		PUSH	d0-d2/a0-a1
		moveq	#1,d2
		cmpi.b	#'0',d0
		bne	@f
.if 1
		cmp.b	d0,d1			;00 0A 01 を 00 01 0A の順にソートする修正
		beq	count_digit_figure_equal_end
.endif
1:		move.b	(a0)+,d0
		cmpi.b	#'0',d0
		beq	1b
@@:
		cmpi.b	#'0',d1
		bne	@f
1:		move.b	(a1)+,d1
		cmpi.b	#'0',d1
		beq	1b
*@@:
		bra	@f
count_digit_figure_loop:
		addq	#1,d2
		move.b	(a0)+,d0
		move.b	(a1)+,d1
@@:		btst	#IS_DIGIT,(a5,d0.w)
		beq	@f
		btst	#IS_DIGIT,(a5,d1.w)
		bne	count_digit_figure_loop

		POP	d0-d2/a0-a1		;[a0] の方が大きい
		moveq	#1,d0
		rts
@@:
		btst	#IS_DIGIT,(a5,d1.w)
		beq	@f			;桁数同じ

		POP	d0-d2/a0-a1		;[a1] の方が大きい
		moveq	#-1,d0
		rts
@@:
		suba	d2,a0
		suba	d2,a1
		subq	#2,d2
count_digit_figure_loop2:
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		sub.l	d1,d0
		dbne	d2,count_digit_figure_loop2
		beq	count_digit_figure_equal_end
		move.l	d0,(sp)			;ccr セット＆返値の d0.l 書き換え
count_digit_figure_equal_end:
		POP	d0-d2/a0-a1
		rts


;最終更新時刻ソート
timestamp_sort:
		move.l	(DIR_TIME,a0),d0	;DIR_TIME / DIR_DATE
		move.l	(DIR_TIME,a1),d1
		swap	d0
		swap	d1
		sub.l	d1,d0
		beq	ext_sort
*timestamp_sort_diff:
		btst	#1,(sort_reverse_flag,pc)
		beq	@f
		neg.l	d0
@@:		rts


;拡張子ソート
ext_sort:
		lea	(DIR_PERIOD,a0),a0
		lea	(DIR_PERIOD,a1),a1
		moveq	#0,d0
		moveq	#0,d1
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		cmp.b	d0,d1
		bne	ext_sort_diff		;拡張子あり <-> なし
		tst	(＄srtc)
		bne	ext_sort_exact_loop
		moveq	#0,d2			;拡張子比較中
ext_sort_loop:
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		bne	@f
		tas	d2
		bne	ext_sort_exact		;主ファイル名も比較した

		lea	(DIR_NAME-(DIR_NUL+1),a0),a0
		lea	(DIR_NAME-(DIR_NUL+1),a1),a1
		move.b	(a0)+,d0		;拡張子が同じなら主ファイル名を比較する
		move.b	(a1)+,d1
@@:
		tst.b	(a5,d0.w)
		bmi	ext_sort_mb
		tst.b	(a5,d1.w)
		bmi	ext_sort_diff		;1byte 文字 <-> 2byte 文字

		tst	d6
		bpl	@f			;数字もそのまま比較

		btst	#IS_DIGIT,(a5,d0.w)	;数値認識ソート(不完全)
		beq	@f
		btst	#IS_DIGIT,(a5,d1.w)
		beq	@f
		bsr	count_digit_figure
		bne	ext_sort_digit_diff
@@:
		cmp.b	d0,d1
		beq	ext_sort_loop

		btst	#IS_LOWER,(a5,d0.w)
		beq	@f
		andi.b	#$df,d0			;大文字化
@@:
		btst	#IS_LOWER,(a5,d1.w)
		beq	@f
		andi.b	#$df,d1			;〃
@@:
		cmp.b	d0,d1
		beq	ext_sort_loop
ext_sort_diff:
		sub.l	d1,d0
ext_sort_digit_diff:
		btst	#2,(sort_reverse_flag,pc)
		beq	@f
		neg.l	d0
@@:
ext_sort_error:
		rts

ext_sort_mb:
		tst.b	(a5,d1.w)
		bpl	ext_sort_diff		;2byte 文字 <-> 1byte 文字
		cmp.b	d0,d1
		bne	ext_sort_diff

		move.b	(a0)+,d0
		move.b	(a1)+,d1
		cmp.b	d0,d1
		beq	ext_sort_loop
		bra	ext_sort_diff

ext_sort_exact:
		subq.l	#(DIR_NUL+1)-DIR_EXT,a0
		subq.l	#(DIR_NUL+1)-DIR_EXT,a1
		moveq	#0,d2			;拡張子比較中
ext_sort_exact_loop:
		move.b	(a0)+,d0
		move.b	(a1)+,d1
		bne	@f
		tas	d2
		bne	ext_sort_error		;主ファイル名も比較した

		lea	(DIR_NAME-(DIR_NUL+1),a0),a0
		lea	(DIR_NAME-(DIR_NUL+1),a1),a1
		move.b	(a0)+,d0		;拡張子が同じなら主ファイル名を比較する
		move.b	(a1)+,d1
@@:
		tst	d6
		bpl	@f			;数字もそのまま比較

		btst	#IS_DIGIT,(a5,d0.w)	;数値認識ソート(不完全)
		beq	@f
		btst	#IS_DIGIT,(a5,d1.w)
		beq	@f
		bsr	count_digit_figure
		bne	ext_sort_digit_diff
@@:
		cmp.b	d0,d1
		beq	ext_sort_exact_loop
		bra	ext_sort_diff

;ファイルサイズソート
size_sort:
		move.l	(DIR_SIZE,a0),d0
		sub.l	(DIR_SIZE,a1),d0
		beq	ext_sort

		btst	#3,(sort_reverse_flag,pc)
		beq	@f
		neg.l	d0
@@:		rts


*************************************************
*		&sort=&sort-menu		*
*************************************************

* ソートモードが違う
*	-> sort_directory
* ソートモードが同じでリバースモード切り換え
*	-> reverse_directory
* ソートモードが同じでリバースモードも同じ
*	-> no-op

SORT_MENU_NUM:	.equ	6

＆sort::
		bsr	set_curfile

		GETMES	MES_SORTM
		movea.l	d0,a1
		bra	sort_arg_next
sort_arg_loop:
		move.b	(a0)+,d0
		beq	sort_arg_next
		cmpi.b	#'-',d0
		bne	sort_error
		move.b	(a0)+,d0
		beq	sort_arg_next
		cmpi.b	#'t',d0
		beq	sort_option_t
		tst.b	(a0)+
		beq	sort_direct		;他はソートモード指定
		bra	sort_error
sort_option_t:
@@:		tst.b	(a0)+			;-t"タイトル" / -t
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	sort_direct		;後に何も付いてなければ Timestamp ソート
@@:
		lea	(-1,a0),a1		;文字列があればタイトル指定
sort_arg_skip:
		tst.b	(a0)+
		bne	sort_arg_skip
sort_arg_next:
		subq.l	#1,d7
		bcc	sort_arg_loop

* メニューモード
*sort_menu:
		lea	(win_sort_menu,pc),a0
		move.l	a1,(SUBWIN_TITLE,a0)
		moveq	#30,d0
		add	(PATH_WINRL,a6),d0
		move	d0,(SUBWIN_X,a0)

		lea	(at_sort),a1
		jsr	(decode_reg_menu)
		subq.l	#SORT_MENU_NUM,d0
		beq	@f

		lea	(sort_menu_default,pc),a1
		jsr	(make_def_menu_list)	;@sort がない時は標準メニュー
@@:
		moveq	#1,d0
		lea	(sort_menu_job,pc),a2
		jsr	(menu_sub_ex)
		beq	sort_error

		swap	d0			;ショートカットキー
		ori.b	#$20,d0			;小文字にしておく

* ソートモードのオプション指定あり
sort_direct:
		move.b	(PATH_SORT,a6),d3
		move.b	(PATH_SORTREV,a6),d4

		cmpi.b	#'Z',d0
		sls	d2			;大文字ならリバースモード

		andi	#$df,d0
		lea	(sort_option_list_end,pc),a0
		cmp.b	-(a0),d0		;'R'
		beq	sort_r

		moveq	#4,d1
@@:		cmp.b	-(a0),d0		;ソート番号に変換
		dbeq	d1,@b
		beq	@f
sort_error:
		bra	set_status_0
**		rts
sort_r:
		move.b	d3,d1
		move.b	d4,d2
		not.b	d2			;リバースモードのみ切り換え
@@:
		move.b	d1,(PATH_SORT,a6)	;ソートモード更新
		move.b	d2,(PATH_SORTREV,a6)

		jbsr	get_dir_buf_a4_d7
		subq	#1,d7
		bls	sort_skip		;エントリが１個以下なら何もしなくてよい

		cmp.b	d1,d3
		bne	sort_exec
*sort_same_mode:				;モードは無変更
		cmp.b	d2,d4
		beq	sort_skip		;リバースモードも無変更

		bsr	reverse_directory
		bra	sort_exec_end
sort_exec:
		bsr	sort_directory
sort_exec_end:
		bsr	cursor_to_curfile
		jbsr	ReverseCursorBar
sort_skip:
		bra	set_status_1
**		rts


* menu_sub_ex から呼び出されるサブルーチン
sort_menu_job:
		PUSH	d0-d3/a1
		lea	(sort_blue_box,pc),a1
		move	(win_sort_menu+SUBWIN_X,pc),d0
		addq	#3,d0
		lsl	#3,d0
		move	d0,(TXBOX_XSTART,a1)	;X 座標を計算

		moveq	#0,d2
		move.b	(PATH_SORT,a6),d2
		move.b	(sort_option_list,pc,d2.w),d2

		moveq	#SORT_MENU_NUM,d1
sort_menu_job_loop:
		moveq	#$df,d0
		and.b	(4*5+4,sp,d1.w),d0
		cmp.b	d2,d0
		beq	sort_menu_job_rev
		cmpi.b	#'R',d0
		bne	sort_menu_job_next
		tst.b	(PATH_SORTREV,a6)
		beq	sort_menu_job_next
sort_menu_job_rev:
		move	d1,d0			;現在のソートモードの行を青くする
		add	(win_sort_menu+SUBWIN_Y,pc),d0
		lsl	#4,d0
		move	d0,(TXBOX_YSTART,a1)	;Y 座標を計算
		IOCS	_TXFILL
sort_menu_job_next:
		subq	#1,d1
		bne	sort_menu_job_loop
		POP	d0-d3/a1
		rts


win_sort_menu:
		SUBWIN	0,2,16,6,NULL,NULL
sort_blue_box:
		.dc	1,0,0,(16-5)*8,16,0

sort_option_list:
		.dc.b	'NFTEL','R'
sort_option_list_end:

sort_menu_default:
		.dc.b	'F','Filename',0
		.dc.b	'T','Timestamp',0
		.dc.b	'E','Extension',0
		.dc.b	'L','Length',0
		.dc.b	'R','Reverse',0
		.dc.b	'N','No   sort',0
		.dc.b	0


iocs_b_keyinp_ex_key:
		.ds.b	1
sort_reverse_flag:
		.ds.b	1
MpuType::	.ds.b	1
local_path_flag:.ds.b	1
		.even


*************************************************
*		&toggle-power-window		*
*************************************************

＆toggle_power_window::
		lea	(＄6502),a0
		lea	(_6502_save,pc),a1
		tst	(a0)
		bne	toggle_power_window_off

		move	(a1),(a0)
		bne	@f
		addq	#1,(a0)			;両方とも 0 なら 1 にする
@@:
		bra	toggle_pow_win_end
toggle_power_window_off:
		move	(a0),(a1)
		clr	(a0)
toggle_pow_win_end:
		jbra	print_titlebar_ttlmpu
**		rts


_6502_save:	.ds	1


*************************************************
*		&mpu-power=&cpu-power		*
*************************************************

MPUPOW_HEAD_LEN:	.equ	.sizeof.(' MPU-POW:')
MPUPOW_NUM_LEN:		.equ	.sizeof.('000.0')
MPUPOW_FOOT_LEN:	.equ	.sizeof.('% ')
.offset	0
MPUPOW_HEAD_X:		.ds.b	MPUPOW_HEAD_LEN
MPUPOW_NUM_X:		.ds.b	MPUPOW_NUM_LEN
MPUPOW_FOOT_X:		.ds.b	MPUPOW_FOOT_LEN
.text

MPUCACHE_HEAD_LEN:	.equ	.sizeof.(' ')
MPUCACHE_DC_LEN:	.equ	.sizeof.('DATAC')
MPUCACHE_SLASH_LEN:	.equ	.sizeof.('/')
MPUCACHE_IC_LEN:	.equ	.sizeof.('INSTRUCT')
MPUCACHE_FOOT_LEN:	.equ	.sizeof.(' ')
.offset	0
MPUCACHE_HEAD_X:	.ds.b	MPUCACHE_HEAD_LEN
MPUCACHE_DC_X:		.ds.b	MPUCACHE_DC_LEN
MPUCACHE_SLASH_X:	.ds.b	MPUCACHE_SLASH_LEN
MPUCACHE_IC_X:		.ds.b	MPUCACHE_IC_LEN
MPUCACHE_FOOT_X:	.ds.b	MPUCACHE_FOOT_LEN
.text

PXTMP_HEAD_LEN:		.equ	.sizeof.(' PhantomX')
PXTMP_NUM_LEN:		.equ	.sizeof.(':--.--')
PXTMP_FOOT_LEN:		.equ	.sizeof.(' ')
.offset	0
PXTMP_HEAD_X:		.ds.b	PXTMP_HEAD_LEN
PXTMP_NUM_X:		.ds.b	PXTMP_NUM_LEN
PXTMP_FOOT_X:		.ds.b	PXTMP_FOOT_LEN
.text


mpu_wait:
		move	sr,-(sp)
		ori	#$700,sr
@@:
		cmpi.b	#56,(MFP_TCDR)
		bne	@b
		move	#5000,d0
@@:
		subq	#1,d0
		bne	@b
		moveq	#0,d0
		move.b	(MFP_TCDR),d0
		neg.b	d0

* 高速エミュレータ環境用の数値補正
* 10MHz未満の実機環境でも有り得るが、このアルゴリズムでは
* 遅すぎる場合に正確な値を測定できないので無視する。
		cmpi.b	#-56,d0
		bcs	@f
		subi	#200,d0
		cmpi	#15,d0
		bcc	@f
		moveq	#15,d0			;1000%以上にならないようにする
@@:
		move	(sp)+,sr
		rts

＆mpu_power::
  move (＄6502),d0
  subq #1,d0
  beq mpu_power_1
  subq #2,d0
  bcs mpu_power_2
  beq mpu_power_3
  rts

;%6502 1 ... MPU-POWERまたはMPUキャッシュ表示
mpu_power_1:
		move.b	(MpuType,pc),d0
		subq.b	#2,d0
		bcc	mpu_power_030
* 68000～68010
		pea	(mpu_wait,pc)		;計測ルーチン
		DOS	_SUPER_JSR
		addq.l	#4,sp
		FPACK	__LTOF			;signed int to float(d0.l)
		move.l	d0,d1

**		move.l	#14300,d0
**		FPACK	__LTOF
		move.l	#$465f7000,d0
		FPACK	__FDIV			;14300/tcdr

		subq.l	#8,sp			;バッファ

		moveq	#3,d2			;整数部の桁数
		moveq	#1,d3			;小数部〃
		moveq	#0,d4			;属性
		lea	(sp),a0
		FPACK	__FUSING

		GETMES	MES_MPUPO		;" MPU-POW:000.0% "
		movea.l	d0,a0

		lea	(a0),a1
		moveq	#BLUE+EMPHASIS,d1
		moveq	#MPUPOW_HEAD_X,d2
		moveq	#MPUPOW_HEAD_LEN-1,d4
		bsr	putmes_mpuinfo

		lea	(sp),a1			;"000.0"
		moveq	#WHITE,d1
		moveq	#MPUPOW_NUM_X,d2
		moveq	#MPUPOW_NUM_LEN-1,d4
		bsr	putmes_mpuinfo

		lea	(MPUPOW_FOOT_X,a0),a1	;"% "
		moveq	#WHITE,d1
		moveq	#MPUPOW_FOOT_X,d2
		moveq	#MPUPOW_FOOT_LEN-1,d4
		bsr	putmes_mpuinfo

		addq.l	#8,sp
		bra	mpu_power_box
**		rts

putmes_mpuinfo:
		moveq	#TTLBAR_Y,d3
		cmpi	#2,(＄6502)
		bne	@f
		addi	#96-TTLBAR_MPUPOW_LEN,d2
		move	(scr_cplp_line,opc),d3
@@:
		IOCS	_B_PUTMES
mpu_power_2_end:
		rts

;%6502 2 ... cplp行にMPUキャッシュ表示
mpu_power_2:
  move.b (MpuType,pc),d0
  subq.b #2,d0
  bcs mpu_power_2_end  ;68000/010なら表示しない
    tst (＄cplp)
    beq mpu_power_2_end
  @@:
  bra mpu_power_030

;68020～68060のMPUキャッシュ表示(タイトル行左端またはcplp行右端)
mpu_power_030:
		GETMES	MES_CACHE
		movea.l	d0,a0			;" DATAC/INSTRUCT "

		lea	(a0),a1
		moveq	#WHITE,d1
		moveq	#TTLBAR_MPUPOW_X,d2
		moveq	#TTLBAR_MPUPOW_LEN-1,d4
		bsr	putmes_mpuinfo

		moveq	#1,d1
		IOCS	_SYS_STAT
		move	d0,d7
		lsr	#1,d7
		bcc	@f

		lea	(MPUCACHE_IC_X,a0),a1	;"INSTRUCT"
		move	(＄intc),d1
		moveq	#MPUCACHE_IC_X,d2
		moveq	#MPUCACHE_IC_LEN-1,d4
		bsr	putmes_mpuinfo
@@:
		lsr	#1,d7
		bcc	@f

		lea	(MPUCACHE_DC_X,a0),a1	;"DATAC"
		move	(＄datc),d1
		moveq	#MPUCACHE_DC_X,d2
		moveq	#MPUCACHE_DC_LEN-1,d4
		bsr	putmes_mpuinfo
@@:
		jbra	mpu_power_box
**		rts

mpu_power_box:
		lea	(mpu_power_txbox,pc),a1
		moveq	#0,d3
		cmpi	#2,(＄6502)
		bne	@f			;左上

		move	#768-TTLBAR_MPUPOW_LEN*8-1,d3	;cplp 行の右端
		swap	d3
		move	(scr_cplp_line,opc),d3
		lsl	#4,d3
@@:
		move.l	d3,(TXBOX_XSTART,a1)
		IOCS	_TXBOX
update_pxsoctmp_end:
		rts


.ifdef PHANTOMX_TEST
PhantomX_GetTempTest:
  moveq #0,d0
  move ($9cc).w,d0
  lsl #2,d0
  rts
.endif

update_phantomx_soctmp:
  cmpi #3,(＄6502)
  bne.s update_pxsoctmp_end
  move.b (is_phantomx_exists,pc),d0
  beq update_pxsoctmp_end  ;PhantomXなしの場合は再描画しない

  bra mpu_power_3

;%6502 3 ... PhantomX Soc温度表示
mpu_power_3:
  PUSH d1-d4/a0-a1

  GETMES MES_PXTMP  ;' PhantomX:--.-- '
  movea.l d0,a0

  lea (a0),a1
  moveq #BLUE+EMPHASIS,d1
  moveq #PXTMP_HEAD_X,d2
  moveq #PXTMP_HEAD_LEN-1,d4
  bsr putmes_mpuinfo

  subq.l #8,sp
  lea (PXTMP_NUM_X,a0),a1
  lea (is_phantomx_exists,pc),a0
  move.b (a0),d0
  bgt mpu_power_3_px     ;PhantomXあり
  beq mpu_power_3_print  ;なし
    ;初回呼び出し時にPhantomXが装着されているか調べる
    jsr (PhantomX_Exists)  ;d0=0:なし 1:あり
.ifdef PHANTOMX_TEST
    moveq #1,d0
.endif
    move.b d0,(a0)  ;以後は装着検査を省略するために結果を保存
    beq mpu_power_3_print

  mpu_power_3_px:
.ifdef PHANTOMX_TEST
    pea (PhantomX_GetTempTest)
.else
    pea (PhantomX_GetTemperature)
.endif
    DOS _SUPER_JSR
    addq.l #4,sp

    lea (hextable,pc),a2  ;SoC温度を文字列化する
    lea (sp),a0
    bsr pxtmp_tohex2    ;':??' 整数部2桁
    bsr pxtmp_tohex2    ;'.??' 小数部2桁
    move.b (a1)+,(a0)+  ;' '
    clr.b (a0)
    subq.l #.sizeof.('??.?? '),a0
    cmpi.b #'0',(a0)
    bne @f
      move.b #' ',(a0)  ;整数部の十の位をゼロサプレスする
    @@:
    lea (sp),a1
  mpu_power_3_print:
  moveq #WHITE,d1
  moveq #PXTMP_NUM_X,d2
  moveq #PXTMP_NUM_LEN+PXTMP_FOOT_LEN-1,d4
  bsr putmes_mpuinfo
  addq.l #8,sp

  bsr mpu_power_box
  POP d1-d4/a0-a1
  rts

pxtmp_tohex2:
  move.b (a1)+,(a0)+
  addq.l #2,a1  ;'00'を飛ばす
  pea (@f,pc)  ;2桁分繰り返す
@@:
  rol #4,d0
  moveq #$f,d1
  and d0,d1
  move.b (a2,d1.w),(a0)+
  rts

mpu_power_txbox: .dc $8003,0,0,TTLBAR_MPUPOW_LEN*8,16,$ffff

is_phantomx_exists: .dc.b -1
.even


*************************************************
*		&toggle-interrupt-window	*
*************************************************

＆toggle_interrupt_window::
		lea	(＄6809),a0		;右下割り込み表示窓オンライントグル
		moveq	#1,d0
		and	d0,(a0)
		eor	d0,(a0)
		bra	print_cplp_line


*************************************************
*		割り込み表示窓の描画		*
*************************************************

*    01234567890123456
* [SS RAS/OPM/TMD/VDI ]

interrupt_window_print::
		PUSH	d1-d4/d6-d7/a1
		move.b	(write_disable_flag,opc),d0
		bne	int_win_print_end
		tst	(＄cplp)
		beq	int_win_print_end

		cmpi	#2,(＄6502)
		bne	@f
		bsr	mpu_power_030		;キャッシュ状態表示中
		bra	int_win_print_end
@@:
		move	(＄6809),d6
		beq	int_win_print_end

		moveq	#WHITE,d1
		moveq	#96-(17-4),d2		;桁位置
		move	(scr_cplp_line,opc),d3	;行位置
		moveq	#(17-4)-1,d4
		lea	(int_win_frame,pc),a1
		IOCS	_B_PUTMES

		moveq	#96-19,d2
		bsr	int_win_ss
		subq	#1,d2
		bsr	int_win_ras
		bsr	int_win_opm
		bsr	int_win_tmd
		bsr	int_win_vdi

		bsr	draw_ss_win_box
		bsr	draw_int_win_box
int_win_print_end:
		POP	d1-d4/d6-d7/a1
		rts

int_win_ss:
		moveq	#0,d7
		move	(＄down),d7		;0 以外ならセーバ機能オン
		lea	(int_win_ss_mes,pc),a1
		bra	int_win_putmes

int_win_ras:
		moveq	#0,d1
		lea	(int_win_rte,pc),a1
		IOCS	_CRTCRAS
		move.l	d0,d7
		bne	@f

		suba.l	a1,a1
		IOCS	_CRTCRAS
@@:
		lea	(int_win_ras_mes,pc),a1
		bra	int_win_putmes

int_win_opm:
		lea	(int_win_rte,pc),a1
		IOCS	_OPMINTST
		move.l	d0,d7
		bne	@f

		suba.l	a1,a1
		IOCS	_OPMINTST
@@:
		lea	(int_win_opm_mes,pc),a1
		bra	int_win_putmes

int_win_tmd:
		move	#0,d1
		lea	(int_win_rte,pc),a1
		IOCS	_TIMERDST
		move.l	d0,d7
		bne	@f

		suba.l	a1,a1
		IOCS	_TIMERDST
@@:
		lea	(int_win_tmd_mes,pc),a1
		bra	int_win_putmes

int_win_vdi:
		moveq	#$00_01,d1
		lea	(int_win_rte,pc),a1
		IOCS	_VDISPST
		move.l	d0,d7
		bne	@f

		suba.l	a1,a1
		IOCS	_VDISPST
@@:
		lea	(int_win_vdi_mes,pc),a1
		bra	int_win_putmes

int_win_putmes:
		moveq	#WHITE,d1
		tst.l	d7
		beq	@f
		move	d6,d1			;＄6809
@@:
		moveq	#3-1,d4
		IOCS	_B_PUTMES
		addq	#1,d2
		rts

int_win_rte:
		rte

draw_ss_win_box:
		lea	(ss_win_txbox,pc),a1
		bra	@f
draw_int_win_box::
		lea	(int_win_txbox,pc),a1
@@:		move	d3,d0
		lsl	#4,d0
		move	d0,(TXBOX_YSTART,a1)
		IOCS	_TXBOX
		rts


ss_win_txbox:	.dc	$8003,768-8*19-1,0,8*2+2, 16,$ffff
int_win_txbox:	.dc	$8003,768-8*17,  0,8*17-1,16,$ffff

		   ;' RAS/OPM/TMD/VDI '
int_win_frame:	.dc.b	'/   /   /',0

int_win_ss_mes:	.dc.b	'SS',0
int_win_ras_mes:.dc.b	'RAS',0
int_win_opm_mes:.dc.b	'OPM',0
int_win_tmd_mes:.dc.b	'TMD',0
int_win_vdi_mes:.dc.b	'VDI',0
		.even


* 文字種検査 ---------------------------------- *

is_mb::
		btst	#IS_MB,(ctypetable,pc,d0.w)
		rts				;tst.b が使えない…
is_mbhalf::
		btst	#IS_MBHALF,(ctypetable,pc,d0.w)
		rts
is_lower::
		btst	#IS_LOWER,(ctypetable,pc,d0.w)
		rts
is_upper::
		btst	#IS_UPPER,(ctypetable,pc,d0.w)
		rts
is_alpha::
		btst	#IS_ALPHA,(ctypetable,pc,d0.w)
		rts
is_xdigt::
		btst	#IS_XDIGT,(ctypetable,pc,d0.w)
		rts
get_ctype::
		move.b	(ctypetable,pc,d0.w),d0
		rts


ctypetable::
		.dcb.b	32,%00000000	;$00-$1f:制御記号
		.dcb.b	16,%00000000	;$20-$2f:記号(' '～'/')
		.dcb.b	10,%00000011	;$30-$39:数字('0'-'9')
		.dcb.b	 7,%00000000	;$3a-$40:記号(':'-'@')
		.dcb.b	 6,%00001110	;$41-$46:英字('A'-'F')
		.dcb.b	20,%00001100	;$47-$5a:英字('G'-'Z')
		.dcb.b	 6,%00000000	;$5b-$60:記号('['-'`')
		.dcb.b	 6,%00010110	;$61-$66:英字('a'-'f')
		.dcb.b	20,%00010100	;$67-$7a:英字('g'-'z')
		.dcb.b	 5,%00000000	;$7b-$7f:記号('{'-DEL)
		.dcb.b	 1,%11000000	;$80	:半角平仮名
		.dcb.b	31,%10000000	;$81-$9f:全角
		.dcb.b	64,%00000000	;$a0-$df:半角片仮名
		.dcb.b	16,%10000000	;$e0-$ef:全角
		.dcb.b	16,%11000000	;$f0-$ff:半角平仮名


* マーク情報表示 ------------------------------ *

;012345678901234567890123
;____Dir____File_______K
;____Dir____File___x.xxM

print_mark_information::
		PUSH	d0-d7/a0-a5
		move.b	(write_disable_flag,opc),d0
		bne	print_mark_info_end
		tst.b	(PATH_NODISK,a6)
		bne	print_mark_info_clear

		moveq	#0,d3			;クラスタ単位に切り上げ用
		move.l	(PATH_CLUSTER,a6),d2
		beq	@f
		moveq	#1,d3
@@:
		moveq	#0,d4			;dir
		moveq	#0,d5			;file
		moveq	#0,d6			;total size 上位桁
		moveq	#0,d7			;〃	    下位桁

		movea.l	(PATH_BUF,a6),a0
		bra	print_mark_info_start
print_mark_info_file::
		addq	#1,d5

		move.l	(DIR_SIZE,a0),d0
		or.l	d2,d0
		add.l	d3,d0			;クラスタ単位に切り上げる
		bcc	@f
		addq.l	#1,d6			;$1_0000_0000になってしまった
@@:
		add.l	d0,d7
		bcc	@f
		addq.l	#1,d6			;繰り上がり
@@:
print_mark_info_loop:
		lea	(sizeof_DIR,a0),a0
print_mark_info_start:
		move.b	(DIR_ATR,a0),d0
		bpl	print_mark_info_loop
		btst	#DIRECTORY,d0
		beq	print_mark_info_file

		addq	#1,d4
		not.b	d0
		bne	print_mark_info_loop

		subq	#1,d4			;バッファ末尾(番兵)で足し過ぎた分を戻す
		move	d4,d0
		or	d5,d0
		beq	print_mark_info_clear	;マークなし

		addi.l	#1024-1,d7		;1KB 単位に切り上げる
		bcc	@f
		addq.l	#1,d6			;繰り上がり
@@:
		bsr	lsr10_d6d7		;キロバイトに換算
		moveq	#'K',d3

;この時点で d6:d7 はキロバイトの値、d3='K'

		tst.l	d6
		bne	@f			;
		cmpi.l	#9999999,d7
		bhi	@f			;8桁以上なら必ず M/G バイトに換算
;7桁以下
		tst	(＄f_1k)
		beq	print_mark_info_kb1	;%f_1k 0 ならキロバイトで表示
		cmpi.l	#1024,d7
		bcs	print_mark_info_kb1	;%f_1k 1 でも1GB未満ならキロバイトで表示
@@:
;メガ／ギガ／テラ／ペタバイトへの変換を行う
;小数部はあとで表示に使うので、ここでは1024倍した値にする
		move.l	#'PTGM',d3
1:
		tst.l	d6
		bne	@f
		cmpi.l	#1024*1024,d7
		bcs	9f
@@:
		bsr	lsr10_d6d7		;次の単位に換算
		lsr.l	#8,d3			;次の単位記号
		bra	1b
9:
;この時点で d6=0 d7<1024*1024

print_mark_info_kb1:
		lea	(-24,sp),sp
		GETMES	MES_MARKI
		movea.l	d0,a0
		lea	(sp),a1
		moveq	#23-1,d0
@@:
		move.b	(a0)+,(a1)+
		dbra	d0,@b
		clr.b	(a1)
		move.b	d3,-(a1)		;[KMGTP]

		moveq	#0,d1
		bsr	print_mark_info_locate
		move	(＄macl),d1
		jsr	(WinSetColor)
		lea	(sp),a1
		jsr	(WinPrint)
		moveq	#WHITE,d1
		jsr	(WinSetColor)

		move.l	d4,d0			;dir
		moveq	#0,d1
		lea	(sp),a0
		bsr	print_mark_info_dir_file

		move.l	d5,d0			;file
		moveq	#7,d1
		lea	(sp),a0
		bsr	print_mark_info_dir_file

		moveq	#15,d1
		bsr	print_mark_info_locate
		lea	(sp),a0
		lea	(sp),a1
		cmpi.b	#'K',d3
		beq	print_mark_info_kb2	;キロバイト表示は整数で最大7桁

;M/G/T/P バイト表示は整数4桁＋小数2桁
		move	#1024-1,d2
		moveq	#10,d3
		and	d7,d2			;端数

		lsr.l	d3,d7			;÷1024
		moveq	#4,d1			;整数部 4 桁
		move.l	d7,d0
		FPACK	__IUSING

		move.l	#'.00'<<8+0,(a0)	;必ず偶数アドレス
		mulu	#100,d2
		lsr.l	d3,d2			;÷1024
		divu	#10,d2
		add.b	d2,(1,a0)
		swap	d2
		add.b	d2,(2,a0)
		bra	@f
print_mark_info_kb2:
		moveq	#7,d1			;K 単位
		move.l	d7,d0
		FPACK	__IUSING
@@:
		move	(PATH_WIN_MARK,a6),d0
		jsr	(WinPrint)
		lea	(24,sp),sp
print_mark_info_end:
		POP	d0-d7/a0-a5
		rts

print_mark_info_clear:
		move	(PATH_WIN_MARK,a6),d0
		jsr	(WinClearAll)
		bra	print_mark_info_end

print_mark_info_locate:
		move	(PATH_WIN_MARK,a6),d0
		moveq	#0,d2
		jmp	(WinSetCursor)
**		rts

print_mark_info_dir_file:
		move.l	d0,-(sp)
		bsr	print_mark_info_locate
		move.l	(sp)+,d0

		move.l	#9999,d1
		cmp.l	d1,d0
		bls	@f
		move.l	d1,d0
@@:
		lea	(a0),a1
		moveq	#4,d1
		FPACK	__IUSING

		move	(PATH_WIN_MARK,a6),d0
		jmp	(WinPrint)
**		rts


* 64ビットの値を10ビットだけ論理右シフトする
* in	d6:d7	64ビットの数値
* break	d0

;AAAA_BBBB_CCCC_DDDD_EEEE_FFFF_GGGG_HHHH:aaaa_bbbb_cccc_dddd_eeee_ffff_gggg_hhhh
;0000_0000_00AA_AABB_BBCC_CCDD_DDEE_EEFF:FFGG_GGHH_HHaa_aabb_bbcc_ccdd_ddee_eeff

lsr10_d6d7:
		move	#.not.(%1<<10-1),d0
		and	d0,d7
		not	d0
		and	d6,d0			;下位.lに押し出す分
		or	d0,d7
		moveq	#10,d0
		lsr.l	d0,d6			;上位.lをシフト
		ror.l	d0,d7			;下位.lをシフト & 押し出された分を入れる
		rts


* 内部関数を検索する -------------------------- *
* in	a0.l	関数名(先頭の '&' のアドレス)
* out	d0.l	関数の処理アドレス(見つからなかった場合は 0 を返す)
*	ccr	<tst.l d0> の結果

search_builtin_func::
		PUSH	d1/a0-a3
		cmpi.b	#'&',(a0)+
		bne	search_builtin_func_error
		STRLEN	a0,d2
		beq	search_builtin_func_error

		moveq	#1,d1
		lea	(func_name_list),a1
		lea	(func_adr_list-func_name_list,a1),a2
search_builtin_func_loop:
		cmp.b	(a1,d2.l),d1		;文字列長が違う
		bcs	search_builtin_func_next

		lea	(a0),a3
search_builtin_func_loop2:
		move.b	(a1)+,d0
		cmp.b	d0,d1
		bcs	@f

		tst.b	(a3)+			;テーブル側終わり
		beq	search_builtin_func_found
		tst.b	d0
		beq	search_builtin_func_next2
		bra	search_builtin_func_loop
@@:
		cmp.b	(a3)+,d0
		beq	search_builtin_func_loop2
search_builtin_func_next:
		cmp.b	(a1)+,d1		;文字列を飛ばす
		bcs	search_builtin_func_next
		beq	search_builtin_func_loop
search_builtin_func_next2:
		addq.l	#4,a2			;次の命令
		tst.b	(a1)
		bne	search_builtin_func_loop
search_builtin_func_error:
		moveq	#0,d0
search_builtin_func_end:
		POP	d1/a0-a3
		rts

search_builtin_func_found:
		move.l	(a2),d0			;見つかった
		add.l	a2,d0
		bra	search_builtin_func_end


*************************************************
*		&which				*
*************************************************

＆which::
		moveq	#0,d5			;-1=カレントディレクトリ検索抑制
		moveq	#0,d6			;-1=表示抑制
		suba.l	a2,a2			;コマンド名
		bra	which_arg_next
which_arg_loop:
		move.b	(a0)+,d0
		beq	which_arg_next
		cmpi.b	#'-',d0
		bne	which_name
which_option:
		move.b	(a0)+,d0
		beq	which_arg_next
		cmpi.b	#'c',d0
		beq	which_option_c
		cmpi.b	#'n',d0
		bne	which_error
*which_option_n:
		moveq	#-1,d6			;-n : 表示抑制
		bra	which_option
which_option_c:
		moveq	#-1,d5			;-c : カレント検索抑制
		bra	which_option
which_name:
		lea	(-1,a0),a2		;コマンド名の指定
which_arg_skip:
		tst.b	(a0)+
		bne	which_arg_skip
which_arg_next:
		subq.l	#1,d7
		bcc	which_arg_loop
		move.l	a2,d0
		beq	which_error		;コマンド名が指定されなかった

		move.l	a2,d0
		bsr	which_print
		moveq	#MES_WHIC0,d0
		bsr	which_print_msg		;「～ は、」

		lea	(a2),a0
		bsr	search_builtin_func
		beq	which_not_builtin

		moveq	#MES_WHIC2,d0
		bra	which_found		;「mint 組み込み関数です.」

which_not_builtin:
		lea	(Buffer),a2
		lea	(a2),a1
		STRCPY	a0,a1
		lea	(-256,sp),sp
		lea	(a2),a0
		lea	(sp),a1			;ダミーバッファ
		move.l	d5,d0
		bsr	search_command
		lea	(256,sp),sp
		tst.l	d0
		bmi	which_not_command

		move.l	a2,d0
		bsr	which_print
		moveq	#MES_WHIC1,d0		;「～ です.」
which_found:
		bsr	which_print_msg
		bsr	which_print_crlf
		jsr	(set_user_value_match_a2)
		bra	which_end

which_not_command:
		moveq	#MES_WHIC3,d0
		bsr	which_print_msg		;「…感知するところではありません.」
		bsr	which_print_crlf
which_error:
		jsr	(unset_user_value_match)
		moveq	#0,d0
which_end:
		bra	set_status
**		rts


which_print_msg:
		jsr	(get_message)
which_print:
		tst	d6
		bmi	@f
		move.l	d0,-(sp)
		DOS	_PRINT
		addq.l	#4,sp
@@:		rts

which_print_crlf:
		tst	d6
		bmi.s	@b
		jbra	PrintCrlf
**		rts


*************************************************
*		&get-media-byte			*
*************************************************

＆get_media_byte::
		tst.l	d7
		beq	get_media_byte_current	;ドライブ省略時はカレント

		moveq	#$20,d1
		or.b	(a0),d1
		subi.b	#'a',d1
		cmpi.b	#'z'-'a',d1
		bhi	get_media_byte_current

		addq	#1,d1
		bra	@f
get_media_byte_current:
		move	(PATH_DRIVENO,a6),d1
@@:
		lea	(DpbBuffer+DPB_MediaByte),a0
		clr.b	(a0)
		jbsr	dos_getdpb
		moveq	#0,d0
		move.b	(a0),d0
		bra	set_status
**		rts


* @status/@buildin 設定 ----------------------- *

set_status_0:
		moveq	#0,d0
		bra.s	set_status
set_status_1:
		moveq	#1,d0
set_status::
		move	d0,(＠status)
		move	d0,(＠buildin)
		rts


*************************************************
*		&cd=&chdir			*
*************************************************

＆cd::
		lea	(a0),a4
cd_arg_loop:
		tst.b	(a0)
		bne	@f
		addq.l	#1,a0
		subq.l	#1,d7
		bcc	cd_arg_loop
		lea	(a4),a0
@@:
		lea	(Buffer+1024),a1

		move.b	(a0),d0
		beq	cd_home			;&cd
		cmpi.b	#'/',d0
		beq	cd_root			;&cd /foo
		cmpi.b	#'\',d0
		beq	cd_root			;&cd \foo

		lsl	#8,d0
		move.b	(1,a0),d0
		cmpi	#'-'<<8,d0
		beq	cd_oldpwd		;&cd -
		cmpi.b	#':',d0
		beq	cd_drive		;&cd a:...
		cmpi	#'..',d0
		bne	@f
		tst.b	(2,a0)
		beq	＆chdir_to_parent	;&cd ..
@@:
		lea	(PATH_DIRNAME,a6),a2	;まず $PWD/foo を試す
		lea	(a1),a3
		STRCPY	a2,a3
		bsr	cd_cat_path
		bmi	cd_cdpath
		beq	@f
		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f

		jsr	(quit_mintarc)		;mintarc 脱出
		bra	cd_end
@@:
		bsr	chdir_a1_arc
		bne	cd_end
		bra	cd_cdpath
cd_root:
cd_drive:
		lea	(a1),a2
		STRCPY	a0,a2			;バッファに単純コピー
		jbsr	fullpath_a1
		bmi	cd_cdpath
		bsr	chdir_a1
		bne	cd_end
cd_cdpath:
* $MINTCDPATH, $CDPATH
		lea	(a4),a0			;引数
		lea	(-1024,a1),a2		;バッファ

		move.l	a2,-(sp)
		clr.l	-(sp)
		pea	(str_mintcdpath,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
		bpl	@f

		pea	(str_cdpath,pc)
		DOS	_GETENV
		move.l	d0,(sp)+
@@:		addq.l	#12-4,sp
		bmi	cd_error
cd_cdpath_loop:
		move.b	(a2)+,d0
		beq	cd_error		;$(MINT)CDPATH からも見つからない
		cmpi.b	#';',d0
		beq	cd_cdpath_loop
		cmpi.b	#',',d0
		beq	cd_cdpath_loop

		lea	(a1),a3
@@:
		move.b	d0,(a3)+
		move.b	(a2)+,d0
		beq	@f
		cmpi.b	#';',d0
		beq	@f
		cmpi.b	#',',d0
		bne	@b
@@:
		subq.l	#1,a2
		clr.b	(a3)

		bsr	cd_cat_path
		bmi	cd_cdpath_loop
		bsr	chdir_a1
		beq	cd_cdpath_loop
		bra	cd_end
cd_oldpwd:
		lea	(oldpwd_buf),a1
		tst.b	(a1)
		bne	cd_no_cdpath
cd_error:
		bra	set_status_0
cd_home:
		pea	(a1)
		clr.l	-(sp)
		pea	(str_home,opc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	cd_error
cd_no_cdpath:
		bsr	chdir_a1
cd_end:
		bra	set_status
**		rts


str_mintcdpath:	.dc.b	'MINT'
str_cdpath:	.dc.b	    'CDPATH',0
		.even


* ディレクトリ名の連結、正規化
* in	a0.l	ディレクトリ名
*	a1.l	バッファ(パス名)
* out	d0.l	0:通常 1:mintarc 脱出 -1:エラー
*	ccr	<tst.l d0> の結果

cd_cat_path:
		PUSH	d5-d7/a0-a3
		moveq	#'.',d5
		moveq	#'/',d6
		moveq	#0,d7

		lea	(a0),a2
		bsr	to_slash_a0

		jbsr	fullpath_a1		;バッファに書き込まれている
		bmi	cd_cat_path_error	;パス名をフルパス化
		lea	(a1),a0
		bsr	to_slash_a0

		lea	(a1),a3
cd_cat_path_loop:
		move.b	(a2)+,d0
		beq	cd_cat_path_end
		cmp.b	d6,d0
		beq	cd_cat_path_loop	;/
		cmp.b	d5,d0
		bne	cd_cat_path_dir		;a
		move.b	(a2)+,d0
		beq	cd_cat_path_end		;.
		cmp.b	d6,d0
		beq	cd_cat_path_loop	;./
		cmp.b	d5,d0
		bne	cd_cat_path_dir2	;.a
		move.b	(a2)+,d0
		beq	@f			;..
		cmp.b	d6,d0
		bne	cd_cat_path_dir3	;..a
@@:
		move.b	d0,-(sp)
		lea	(a3),a0			;../
		jbsr	search_last_slash
		bmi	1f
		clr.b	-(a1)
		bra	@f
1:		moveq	#1,d7			;mintarc 脱出
@@:
		tst.b	(sp)+
		bne	cd_cat_path_loop
		bra	cd_cat_path_end
cd_cat_path_dir3:
		subq.l	#1,a2
cd_cat_path_dir2:
		subq.l	#1,a2
cd_cat_path_dir:
		subq.l	#1,a2

		lea	(a3),a0
@@:		tst.b	(a0)+
		bne	@b
		move.b	d6,(-1,a0)
@@:
		move.b	(a2)+,d0
		beq	@f
		cmp.b	d6,d0
		beq	1f
		move.b	d0,(a0)+
		lsr.b	#5,d0
		btst	d0,#%10010000
		beq	@b			;一バイト文字
		move.b	(a2)+,(a0)+		;二バイト文字の下位バイト
		bne	@b
		subq.l	#2,a0
		bra	@f
1:
		clr.b	(a0)
		bra	cd_cat_path_loop
@@:
		clr.b	(a0)
cd_cat_path_end:
		lea	(a3),a0
		jbsr	to_mintslash_and_add_last_slash

		move.l	d7,d0
@@:
		POP	d5-d7/a0-a3
		rts
cd_cat_path_error:
		moveq	#-1,d0
		bra	@b


* 文字列中の '\' を '/' に統一する.
* '\'、'/' が連続していた場合は一つだけにする.
* 最後の文字が '/'、'\' であった場合は削除する.
* in	a0.l	文字列

to_slash_a0:
		move.l	a1,-(sp)
		lea	(MINTSLASH),a1
		move.b	(a1),-(sp)
		move.b	#'/',(a1)
		jsr	(to_mintslash)
		move.b	(sp)+,(a1)
		movea.l	(sp)+,a1
		rts


* ディレクトリ移動(mintarc 対応)
* in	a1.l	ディレクトリ名(フルパス)
* out	d0.l	0:失敗 1:成功
*	ccr	<tst.l d0> の結果

chdir_a1_arc::
		tst.b	(PATH_MARC_FLAG,a6)
		beq	chdir_a1

		PUSH	a0-a2
		tst.b	(3,a1)
		beq	chdir_a1_arc_go

		lea	(-(64+FILES_SIZE),sp),sp
		lea	(a1),a0
		lea	(sp),a2
		STRCPY	a0,a2
		clr.b	(-2,a2)			;末尾のパスデリミタを削除

		move	#1<<DIRECTORY,-(sp)
		pea	(2,sp)
		pea	(2+4+64,sp)
		jsr	(marc_files2)
		lea	(10+64+FILES_SIZE,sp),sp
		tst.l	d0
		bmi	chdir_a1_arc_error
chdir_a1_arc_go:
		clr.b	(PATH_CURFILE,a6)
		lea	(PATH_DIRNAME,a6),a0
		STRCPY	a1,a0

		bsr	chdir_and_rewrite
		moveq	#1,d0
@@:
		POP	a0-a2
		rts
chdir_a1_arc_error:
		moveq	#0,d0
		bra	@b


* ディレクトリ移動
* in	a1.l	ディレクトリ名(フルパス)
* out	d0.l	0:失敗 1:成功
*	ccr	<tst.l d0> の結果

chdir_a1::
		PUSH	d1/d7/a0-a2
		moveq	#$1f,d7
		and.b	(a1),d7			;ドライブ番号

		move	d7,d1
		jbsr	dos_drvctrl_d1
		tst.l	d0
		bmi	chdir_a1_error		;不正なドライブ

		tst.b	(3,a1)
		beq	chdir_a1_root		;ルートは常に存在する

		andi.b	#1<<DRV_NOTREADY+1<<DRV_INSERT+1<<DRV_ERRINS,d0
		subq.b	#1<<DRV_INSERT,d0
		bne	chdir_a1_error		;メディア未挿入
chdir_a1_root:
		pea	(a1)
		CHDIR_PRINT	'f'
		DOS	_CHDIR
		move.l	d0,(sp)+
		bmi	chdir_a1_error

		tst.b	(PATH_MARC_FLAG,a6)
		beq	@f
		jsr	(quit_mintarc_all)
@@:
		cmp	(PATH_DRIVENO,a6),d7
		beq	@f
		jbsr	save_drv_curfile
		move	d7,(PATH_DRIVENO,a6)
@@:
		clr.b	(PATH_CURFILE,a6)
		lea	(PATH_DIRNAME,a6),a0
		STRCPY	a1,a0

		bsr	chdir_and_rewrite
		moveq	#1,d0
@@:
		POP	d1/d7/a0-a2
		rts
chdir_a1_error:
		moveq	#0,d0
		bra.s	@b


chdir_and_rewrite:
		PUSH	d1-d7/a0-a5
		bsr	chdir_routin
		bsr	directory_write_routin
		jbsr	ReverseCursorBar
		POP	d1-d7/a0-a5
		rts


*************************************************
*	&chdir-to-parent=&cursor-to-parent	*
*************************************************

＆chdir_to_parent::
		lea	(PATH_DIRNAME,a6),a0
		tst.b	(3,a0)
		bne	@f			;サブディレクトリあり
		tst.b	(PATH_MARC_FLAG,a6)
		beq	chdir_to_parent_error	;既にルートディレクトリだった

		jsr	(quit_mintarc)
		bra	chdir_to_parent_end
@@:
		lea	(a0),a1
@@:
		tst.b	(a1)+
		bne	@b
		clr.b	(-2,a1)			;末尾の '/' を削除
		jbsr	search_last_slash
		bmi	chdir_to_parent_error	;念の為…
		lea	(a1),a0
		lea	(PATH_CURFILE,a6),a2
		STRCPY	a0,a2

		clr.b	(a1)			;最後のディレクトリ名を削除

		bsr	chdir_and_rewrite
chdir_to_parent_end:
		moveq	#1,d0
@@:		bra	set_status
**		rts
chdir_to_parent_error:
		moveq	#0,d0
		bra	@b


*************************************************
*		&cdjp				*
*************************************************

＆cdjp::
		lea	(a0),a5
		move.l	d7,d6
cdjp_arg_loop:
		tst.b	(a0)
		bne	@f
		addq.l	#1,a0
		subq.l	#1,d7
		bcc	cdjp_arg_loop
cdjp_error:
		lea	(a5),a0
		move.l	d6,d7
		bra	＆cd
@@:
		lea	(Buffer),a1
		lea	(a1),a2
@@:
		move.b	(a0)+,d5		;デバイス名を切り出す
		cmpi.b	#':',d5
		beq	@f
		move.b	d5,(a2)+
		bne	@b
@@:
		clr.b	(a2)
		lea	(a0),a2

		lea	(a1),a0
		bsr	device_name_to_drive_no
		bmi	cdjp_error

		lea	(a1),a0
		move	#('A'-1)<<8+':',(a0)
		add.b	d0,(a0)
		addq.l	#2,a0
		move.b	d5,(a0)			;clr.b (a1) / tst.b d5
		beq	@f

		STRCPY	a2,a0
@@:
		bsr	chdir_a1
		bra	set_status
**		rts


*************************************************
*		&set-current-to-opposite	*
*************************************************

＆set_current_to_opposite::
		moveq	#0,d7			;チェイン終了後もそのまま
		bra.s	@f


*************************************************
*		&exchange-current		*
*************************************************

＆exchange_current::
		moveq	#-1,d7			;チェイン終了後にカレントを戻す
@@:
		movea.l	(PATH_OPP,a6),a1
		tst.b	(PATH_MARC_FLAG,a1)
		addq.l	#PATH_DIRNAME,a1
		beq	@f
		jsr	(get_mintarc_dir_opp)
		movea.l	d0,a1
@@:
		bra	local_path_a1


*************************************************
*		&local-path			*
*************************************************

* 備考:
*	失敗した時はなるべく元の状態を変化させない
*	ようにしてある. 書き換える時はエラー処理に
*	留意すること.

＆local_path::
@@:		subq.l	#1,d7
		bcs	local_path_error
		tst.b	(a0)+
		beq	@b
		subq.l	#1,a0			;移動先パス名

		lea	(Buffer),a1
		lea	(a1),a2
		STRCPY	a0,a2
		jbsr	fullpath_a1
		bmi	local_path_error

		moveq	#-1,d7			;チェイン終了後にカレントを戻す
local_path_a1:
		moveq	#$1f,d1
		and.b	(a1),d1			;ドライブ番号
		jbsr	dos_drvctrl_d1
		andi.b	#1<<DRV_INSERT+1<<DRV_NOTREADY+1<<DRV_ERRINS,d0
		subq.b	#1<<DRV_INSERT,d0
		beq	@f
		tst.b	(3,a1)			;"d:/"
		bne	local_path_error	;ルートなら未挿入でも移動可
@@:
		pea	(a1)
		CHDIR_PRINT	'g'
		DOS	_CHDIR
		move.l	d0,(sp)+
		bmi	local_path_error

		bsr	dos_chgdrv_a1		;以下の処理は必ず成功する

		lea	(cur_dir_buf),a0
		STRCPY	a1,a0

		lea	(local_path_flag,opc),a0
		move.b	d7,(a0)			;フラグセット

		bra	print_cplp_line
local_path_error:
		rts


* &local-path / &exchange-current 復帰 -------- *

local_path_pop:
		PUSH	d1-d7/a0-a5
		lea	(local_path_flag,opc),a0
		tst.b	(a0)
		beq	local_path_pop_end

		clr.b	(a0)
		tst.b	(PATH_MARC_FLAG,a6)
		bne	@f

		lea	(PATH_DIRNAME,a6),a0
		lea	(cur_dir_buf),a1
		STRCPY	a0,a1
		jbsr	chdir_current_path_buf
@@:
		move.b	(write_disable_flag,opc),d0
		bne	local_path_pop_end	;直後に再描画するので更新不要

		bsr	print_cplp_line
local_path_pop_end:
		POP	d1-d7/a0-a5
		rts


* mintarc からのカレントディレクトリ制御 ------ *

* カレントディレクトリ変更
* in	a1.l	パス名

set_current_dir::
		PUSH	d1-d7/a0-a5
		lea	(cur_dir_buf),a2
		STRCPY	a1,a2
		bsr	reset_current_dir
		bsr	print_cplp_line
		POP	d1-d7/a0-a5
		rts

* カレントディレクトリ設定

reset_current_dir::
		PUSH	d1-d7/a0-a5
		lea	(cur_dir_buf),a1
		lea	(a1),a0
		jbsr	to_mintslash_and_add_last_slash

		moveq	#$1f,d1
		and.b	(a1),d1			;ドライブ番号
		jbsr	dos_drvctrl_d1
		andi.b	#1<<DRV_INSERT+1<<DRV_NOTREADY+1<<DRV_ERRINS,d0
		subq.b	#1<<DRV_INSERT,d0
		bne	@f

		pea	(a1)
		CHDIR_PRINT	'h'
		DOS	_CHDIR			;通常は成功する
		addq.l	#4,sp
@@:
		bsr	dos_chgdrv_a1
		POP	d1-d7/a0-a5
		rts


*************************************************
*		&source				*
*************************************************

＆source::
		PUSH	d0-d7/a0-a6
		bsr	set_status_0
		move.b	(skip_mintrc_flag,opc),d0
		bne	source_skip

		clr	-(sp)
		pea	(mintrc_filename)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	source_skip

		clr.l	-(sp)
		move	d0,-(sp)
		DOS	_FILEDATE
		move.l	d0,d1
		DOS	_CLOSE
		addq.l	#6,sp

		tst.l	d7
		beq	source_auto
		cmpi	#'-f',(a0)+
		bne	source_auto
		tst.b	(a0)
		beq	source_force
source_auto:
		cmp.l	(mintrc_timestamp),d1
		beq	source_skip		;タイムスタンプが同じなら読み込まない
source_force:
		jsr	(gm_check_square)
		jbsr	read_mintrc
.if 0
		jbsr	＆load_path_history
.else
		jsr	(init_mes_ptr_table)
		jbsr	init_kq_ptr_buffer
		clr.l	(load_phis_flags)
.endif
		jbsr	analyze_mintrc_sysvalue
		jbsr	analyze_mintrc_message
		jbsr	correct_system_value
		jbsr	restore_keyinp_ex_vector	;'>...'解析前に解放
		jbsr	analyze_mintrc

		jbsr	hook_keyinp_ex_vector
		jbsr	save_system_value
		jbsr	mint_getenv
		jbsr	ChangeFnckey
		jbsr	window_remake		;各種ウィンドウ作り直し
.if 0
		jbsr	＆clear_and_redraw
.else
		move.l	a6,-(sp)
		lea	(path_buffer),a6
		move.b	(PATH_MARC_FLAG,a6),d0
		or.b	(PATH_MARC_FLAG+sizeof_PATHBUF,a6),d0
		bne	@f
		jbsr	malloc_dirs_buf
@@:		movea.l	(sp)+,a6

		moveq	#%1100_1111,d0
		jbsr	print_screen
.endif
		jsr	(init_schr_tbl)
		jsr	(alloc_cmd_his_buf)

		bsr	set_status_1
source_skip:
		POP	d0-d7/a0-a6
		rts


save_system_value:
		lea	(sys_val_table),a1
		lea	(sys_val_save),a2
		move	#(sys_val_table_end-sys_val_table)/2-1,d0
@@:
		move	(a1)+,(a2)+
		dbra	d0,@b
		rts


* ディレクトリバッファを確保する.
* in	a6.l	path_buffer
* 備考:
*	バッファが確保できない場合はエラー終了する.

malloc_dirs_buf:
		PUSH	d0-d2/a0
		moveq	#0,d1
		move	(＄dirs),d1
		move	#128,d0
		cmp	d0,d1
		bcc	@f
		move	d0,d1
@@:		move	d1,(file_entry_max)

		addq.l	#2,d1			;一番上と下の分
		mulu	#sizeof_DIR*2,d1
		move.l	(PATH_BUF,a6),d2
		beq	@f			;初回

		move.l	d1,-(sp)
		move.l	d2,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bpl	malloc_dirs_buf_set

		move.l	d2,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
@@:
		move.l	d1,-(sp)
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		move.l	d0,d2
		bmi	memory_error
malloc_dirs_buf_set:
		move.l	d2,(PATH_BUF,a6)	;左バッファ
		lsr.l	#1,d1
		add.l	d1,d2
		movea.l	(PATH_OPP,a6),a0
		move.l	d2,(PATH_BUF,a0)	;右バッファ
		POP	d0-d2/a0
		rts


* 仮想ディレクトリ関係 ------------------------ *

* 仮想ディレクトリの割り当て状態を調べ、
* mount_buf～ に書き込む.

mount_check:
		PUSH	d1-d2/d7/a1
		moveq	#VIRDIR,d1
		lea	(mount_buf),a1

		move.l	#'A:'<<16,-(sp)
		move.l	sp,-(sp)
		move.l	(sp),-(sp)		;ドライブ名
		clr	-(sp)			;ASSIGN_GET

		moveq	#26-1,d7
mount_check_loop:
		move.l	a1,(6,sp)		;バッファ
		DOS	_ASSIGN
		cmp.l	d0,d1
		beq	mount_check_next
		clr.b	(a1)			;仮想ディレクトリ以外はクリアしておく
mount_check_next:
		lea	(64,a1),a1
		addq.b	#1,(10,sp)		;ドライブ名++
		dbra	d7,mount_check_loop

		lea	(14,sp),sp
		POP	d1-d2/d7/a1
		rts


*************************************************
*		&un-mount			*
*************************************************

＆un_mount::
		bsr	mount_check
		lea	(mount_buf),a1

		move.l	#'A:'<<16,-(sp)
		pea	(sp)
		move	#ASSIGN_UNSET,-(sp)

		moveq	#26-1,d7
un_mount_loop:
		tst.b	(a1)
		beq	un_mount_next

		DOS	_ASSIGN			;仮想ディレクトリを解除
un_mount_next:
		lea	(64,a1),a1
		addq.b	#1,(6,sp)		;ドライブ名++
		dbra	d7,un_mount_loop

		lea	(10,sp),sp
		jbra	drive_check
**		rts


*************************************************
*		&un-mount			*
*************************************************

＆re_mount::
* 既に &un-mount で仮想ディレクトリが解除されている状態なので、
* 割り当て前に mount_check を呼び出してはいけない.
		lea	(mount_buf),a1

		move.l	#'A:'<<16,-(sp)
		move	#VIRDIR,-(sp)
		subq.l	#4,sp
		pea	(6,sp)			;ドライブ名
		move	#ASSIGN_SET,-(sp)

		moveq	#26-1,d7
re_mount_loop:
		tst.b	(a1)
		beq	re_mount_next

		move.l	a1,(6,sp)		;バッファ
		DOS	_ASSIGN			;仮想ディレクトリを割り当てる
re_mount_next:
		lea	(64,a1),a1
		addq.b	#1,(12,sp)		;ドライブ名++
		dbra	d7,re_mount_loop

		lea	(16,sp),sp
		jbra	＆drive_check
**		rts


*************************************************
*		&is-mount			*
*************************************************

＆is_mount::
		moveq	#'Z'-('A'-1),d1
is_mount_loop:
		move	d1,d0
		bsr	get_assign_mode
		moveq	#VIRDIR,d2
		cmp.l	d0,d2
		beq	set_status_1		;仮想ディレクトリ
		subq	#1,d1
		bne	is_mount_loop

		bra	set_status_0
**		rts


*************************************************
*		&reload				*
*************************************************

＆reload::
		bsr	set_curfile2

		moveq	#%0000_0001,d0
		tst.l	d7
		beq	reload_end		;省略時は -d1

		cmpi.b	#'-',(a0)+
		beq	@f
		subq.l	#1,a0
@@:
		cmpi.b	#'d',(a0)+
		beq	@f
		subq.l	#1,a0
@@:
		cmpi.b	#'1',(a0)
		beq	reload_end		;-d1
		moveq	#%0000_0010,d0
		cmpi.b	#'2',(a0)
		beq	reload_end		;-d2

		moveq	#%0000_0011,d0		;それ以外(-d3 -all)は両方
reload_end:
		jbra	print_screen
**		rts


* カーソル位置ファイル名 ---------------------- *

* 左右ウィンドウ処理版.
set_curfile2::
		bsr	@f
@@:		movea.l	(PATH_OPP,a6),a6
		bra	set_curfile
**		rts

* カーソル位置ファイル名を設定する.
set_curfile::
		PUSH	d0/a1-a2/a4
		lea	(PATH_CURFILE,a6),a2
		clr.b	(a2)
		tst.b	(PATH_NODISK,a6)
		bne	@f

		jbsr	search_cursor_file
		lea	(DIR_NAME,a4),a1
		jsr	(copy_dir_name_a1_a2)
@@:
		POP	d0/a1-a2/a4
		rts


* 左右ウィンドウ処理版.
save_drv_curfile2:
		bsr	@f
@@:		movea.l	(PATH_OPP,a6),a6
		bra	save_drv_curfile
**		rts

* カーソル位置ファイル名をドライブ別バッファに保存する.
save_drv_curfile:
		PUSH	d0/a1-a2
		bsr	set_curfile
		lea	(PATH_CURFILE,a6),a1
		bsr	get_drv_curfile_buf
		movea.l	d0,a2
		bra	@f

* ドライブ別バッファからカーソル位置ファイル名を取り出す.
restore_curfile:
		PUSH	d0/a1-a2
		bsr	get_drv_curfile_buf
		movea.l	d0,a1
		lea	(PATH_CURFILE,a6),a2
@@:
		STRCPY	a1,a2
		POP	d0/a1-a2
		rts

get_drv_curfile_buf:
		moveq	#24,d0
		mulu	(PATH_DRIVENO,a6),d0
		addi.l	#drv_curfile_buf-24,d0
		rts


* ヒストリファイル処理 ------------------------ *


*PHIS_DEBUG:=1

PRINT_PHIS_DEBUG_MES:	.macro	mes
.ifdef PHIS_DEBUG
		pea	(@mes)
		DOS	_PRINT
		addq.l	#4,sp
		.data
@mes:		.dc.b	mes,CR,LF,0
		.even
		.text
.endif
		.endm


* ヒストリファイル構造
* top:
*	.dc.b	'minthis-3.10',CR,LF,EOF,0	;ヘッダ/バージョン
*
* ブロック開始:
* block_start1:
*	.dc.w	ID				;このブロックの種別/バージョン(0 なら終了)
*	.dc.l	block_end1-block_data1		;このブロックのサイズ
* block_data1:
*	.ds.b	BLOCK_SIZE			;ブロックの内容
* block_end1:
* ブロック終了:
*	～任意の数だけブロックの繰り返し～
*	.dc.w	$0000				;ブロック列終了

* 変更時の注意点
*	・各ブロックのサイズ、構造等を変更した場合は ID の数字を大きくする。
*	・minthis-3.10 でファイル構造を変更し、ID の数値を巻き戻している。
*	・転送を高速化するためになるべくロングワード単位のデータにする。


HIS_HEAD_LEN:	.equ	16
*	ヘッダ/バージョン('minthis 3.10',CR,LF,EOF,0 = 16.b)


HIS_INFO_ID:	.equ	'#0'
HIS_INFO_LEN:	.equ	4+4
*	~/.mintrc ファイルサイズ/タイムスタンプ
*	必ず先頭に出力すること。

HIS_PATH_ID:	.equ	'P0'
HIS_PATH_LEN:	.equ	PATH_HIS_BUF_SIZE*PATH_HIS_BUF_NUM*2
*	パスヒストリ(64.b×26個×左右 = 3328.b)

HIS_FILE_ID:	.equ	'F0'
HIS_FILE_LEN:	.equ	24*26
*	ドライブ別カーソルファイル名(24.b×26個 = 624.b)

HIS_LOOK_ID:	.equ	'L0'
HIS_LOOK_LEN:	.equ	LOOKFILE_STATIC_FLAGS_SIZE
*	&look-file 保存フラグ(1.w+4.b+1.w = 8.b)

HIS_SYS_ID:	.equ	'S0'
HIS_SYS_LEN:	.equ	(sys_val_table_end+2-sys_val_table).and.$fffffffc
*	~/.mintrc で指定されたシステム変数の値

HIS_KEYQ_ID:	.equ	'K0'
HIS_KEYQ_LEN:	.equ	4*KQ_MAX
*	~/.mintrc で指定されたキー定義のアドレス(1.l×139個 = 556.b)

HIS_MES_ID:	.equ	'M1'
HIS_MES_LEN:	.equ	4*MESNO_MAX
*	~/.mintrc で指定された変更可能文字列アドレス(1.l×311個 = 1244.b)
*	~/.mintrc で定義されなかった場合は mint 内蔵文字列のアドレスが入る

HIS_CHIS_ID:	.equ	'C0'
*	コマンドヒストリ
*	1.l	サイズ(4バイト単位)
*	???.b	コマンドヒストリの内容
* 履歴に登録されているものしか書き出さないので、毎回サイズが異なる(0～65536.b)

* 終了マーク
*	どうせ読み込み時にファイル末尾になれば終了するので
*	ファイル書き出し回数を減らすために終了マークは省略する。
.if 0
HIS_END_OF_BLOCK_ID:	.equ	$0000
.endif


*************************************************
*		&save-path-history		*
*************************************************

＆save_path_history::
		bsr	get_path_history_filename
		bmi	save_phis_erorr
		btst	#DRV_PROTECT,d0
		bne	save_phis_erorr

		lea	(a0),a4			;ファイル名

		move	#1<<ARCHIVE,-(sp)
		pea	(a4)
		DOS	_CREATE
		addq.l	#6,sp
		move.l	d0,d7
		bmi	save_phis_erorr

		lea	(256,a4),a3		;バッファ先頭
		lea	(a3),a2			;書き込みポインタ


* ヘッダ/バージョン
		lea	(minthis_header,pc),a1
	.rept	HIS_HEAD_LEN/4
		move.l	(a1)+,(a2)+
	.endm


* ~/.mintrc のファイルサイズ・タイムスタンプ
		moveq	#HIS_INFO_LEN,d0
		move	#HIS_INFO_ID,(a2)+
		move.l	d0,(a2)+

		lea	(mintrc_size),a1
		move.l	(a1)+,(a2)+		;mintrc_size
		move.l	(a1)+,(a2)+		;mintrc_timestamp


* パスヒストリ
		move	#HIS_PATH_ID,(a2)+
		move.l	#HIS_PATH_LEN,(a2)+

		lea	(path_history_buffer),a1
		move	#HIS_PATH_LEN/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b


* ドライブ別カーソルファイル名
		move	#HIS_FILE_ID,(a2)+
		move.l	#HIS_FILE_LEN,(a2)+

		jbsr	save_drv_curfile2
		lea	(drv_curfile_buf),a1
		move	#HIS_FILE_LEN/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b


* &look-file 保存フラグ
		moveq	#HIS_LOOK_LEN,d0
		move	#HIS_LOOK_ID,(a2)+
		move.l	d0,(a2)+

		lea	(lookfile_static_flags),a1
	.rept	HIS_LOOK_LEN/4
		move.l	(a1)+,(a2)+
	.endm


* システム変数
		move	#HIS_SYS_ID,(a2)+
		move.l	#HIS_SYS_LEN,(a2)+

		lea	(sys_val_save),a1
		move	#HIS_SYS_LEN/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b


* 変更可能文字列
*	0～正数 = ~/.mintrc で定義なし
*	負数	= ~/.mintrc で定義あり(bit31-0 がファイル先頭からのオフセット)
		move	#HIS_MES_ID,(a2)+
		move.l	#HIS_MES_LEN,(a2)+

		lea	(mes_ptr_table),a1
		move.l	(mintrc_buf_adr),d2
		move	#MESNO_MAX-1,d0
save_phis_mes_loop:
		move.l	(a1)+,d1
		bpl	save_phis_mes_set	;未定義
		sub.l	d2,d1			;ファイル先頭からのオフセット & bit31=1
save_phis_mes_set:
		move.l	d1,(a2)+
		dbra	d0,save_phis_mes_loop


* キー定義
*	0    = ~/.mintrc で定義なし
*	負数 = ~/.mintrc で定義あり(bit31-0 がファイル先頭からのオフセット)
		move	#HIS_KEYQ_ID,(a2)+
		move.l	#HIS_KEYQ_LEN,(a2)+

		lea	(kq_buffer),a1
		lea	(4*KQ_ESC,a1),a0
		move.l	(a0),-(sp)		;>KEYesc 未定義時のデフォルト設定を隠蔽
		cmpi.l	#key_quick_esc_default,(a0)
		bne	@f
		clr.l	(a0)			;ループの間だけ 0 にしておく
@@:
**		move.l	(mintrc_buf_adr),d2
		bset	#31,d2
		move	#KQ_MAX-1,d0
save_phis_keyq_loop:
		move.l	(a1)+,d1
		beq	save_phis_keyq_set	;未定義

		sub.l	d2,d1			;ファイル先頭からのオフセット & bit31=1
save_phis_keyq_set:
		move.l	d1,(a2)+
		dbra	d0,save_phis_keyq_loop
		move.l	(sp)+,(a0)		;>KEYesc を元に戻す


* コマンドヒストリ(サイズ)
		jsr	(get_cmd_his_size)
		move.l	d0,d1
		beq	@f			;空なら出力しない

		move	#HIS_CHIS_ID,(a2)+
		move.l	d1,(a2)+		;データサイズ
		bsr	save_phis_write
		bne	save_phis_diskfull
@@:

* 終了マーク
.ifdef HIS_END_OF_BLOCK_ID
		move	#HIS_END_OF_BLOCK_ID,(a2)+
.endif

		bsr	save_phis_flush
save_phis_diskfull:
		sne	d1

		move	d7,-(sp)
		DOS	_CLOSE
**		addq.l	#2,sp

		move.b	d1,(sp)+
		beq	set_status_1		;書き込み成功

* ディスクフルなら作成したファイルを削除
		pea	(a4)
		DOS	_DELETE
		addq.l	#4,sp
save_phis_erorr:
		bra	set_status_0
**		rts


* 不定長データ書き出し
* in	d1.l	データサイズ(d1.l > 0)
*	a0.l	データアドレス
* out	a2.l	バッファ先頭
*	ccrZ	1:成功 0:失敗

save_phis_write:
		bsr	save_phis_flush		;バッファに溜っている分を書き出す
		bne	@f

		move.l	d1,-(sp)
		pea	(a0)
		move	d7,-(sp)
		DOS	_WRITE
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
@@:
		rts


* データ書き出し
* out	a2.l	バッファ先頭
*	ccrZ	1:成功 0:失敗

save_phis_flush:
		move.l	a2,d0
		sub.l	a3,d0			;データサイズ
		beq	@f

		move.l	d0,-(sp)		;バッファに溜っている分を書き出す
		pea	(a3)
		move	d7,-(sp)
		DOS	_WRITE
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		lea	(a3),a2
@@:
		rts


*************************************************
*		&load-path-history		*
*************************************************

＆load_path_history::
		jsr	(init_mes_ptr_table)
		jbsr	init_kq_ptr_buffer
		bsr	load_path_history
		bsr	set_status
		bra	load_command_history
**		rts


* コマンドヒストリ読み込み -------------------- *

load_command_history:
  movem.l (cmd_his_size),d0/a0  ;cmd_his_size/cmd_his_adr
  jsr (load_cmd_his)
  bra load_phis_free


* ヒストリ読み込みバッファ解放 ---------------- *

load_phis_free:
  lea (cmd_his_memblk),a0
  move.l (a0),-(sp)
  ble @f
    DOS _MFREE
  @@:
  addq.l #4,sp

  clr.l (a0)+  ;cmd_his_memblk
  clr.l (a0)+  ;cmd_his_size
  clr.l (a0)+  ;cmd_his_adr
  rts


* ヒストリ読み込み ---------------------------- *
* out	d0.l	エラーコード
*	バッファを確保して $MINTHIS ファイルを読み込む。
*	内容を解釈した後にバッファを解放すること
*	(通常は load_command_history から解放される)

load_path_history:
		bsr	load_phis_free
		lea	(load_phis_flags),a3
		clr.l	(a3)

		bsr	get_path_history_filename
		bmi	load_phis_error

		PRINT_PHIS_DEBUG_MES	'<<load_path_history>>'
		lea	(a0),a4			;ファイル名

		clr	-(sp)
		pea	(a4)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d7
		bmi	load_phis_error

* ファイルサイズを調べる
		PRINT_PHIS_DEBUG_MES	'ファイルサイズ調査'
		move	#SEEK_END,-(sp)
		clr.l	-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		move.l	d0,d6			;ファイルサイズ
		clr	(6,sp)			;SEEK_SET
		DOS	_SEEK
		addq.l	#8,sp
		or.l	d6,d0
		bmi	load_phis_error2	;念の為

* 読み込みバッファを確保する
		PRINT_PHIS_DEBUG_MES	'メモリ確保'
		move.l	d6,-(sp)
		move	#MALLOC_HIGH,-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		move.l	d0,(cmd_his_memblk-load_phis_flags,a3)
		bmi	load_phis_error2

		movea.l	d0,a5			;バッファ先頭
		movea.l	d0,a4			;参照位置

* ファイルを読み込む
		PRINT_PHIS_DEBUG_MES	'ファイル読み込み'
		move.l	d6,-(sp)
		pea	(a5)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		bne	load_phis_error3

* ヘッダ/バージョン検査
		PRINT_PHIS_DEBUG_MES	'ヘッダ/バージョン検査'
		moveq	#HIS_HEAD_LEN,d0
		sub.l	d0,d6
		bcs	load_phis_error3	;ファイルが小さすぎる

		lea	(minthis_header,pc),a0
		moveq	#HIS_HEAD_LEN/4-1,d0
@@:
		cmpm.l	(a0)+,(a4)+
		dbne	d0,@b
		bne	load_phis_error3	;ヘッダ/バージョン違い

* d6.l	残りデータサイズ
* a4.l	参照位置
		bsr	load_phis_close

* ~/.mint が更新(編集)されているか
* $00=~/.mintrc 更新あり $ff=なし(前回と同一内容)
		moveq	#0,d7


* 各ブロックごとに処理
		PRINT_PHIS_DEBUG_MES	'ブロック解釈ループ開始'
load_phis_loop:
		subq.l	#2+4,d6
		bcs	load_phis_file_end	;これ以上データがない

		move	(a4)+,d1
		beq	load_phis_file_end	;HIS_END_OF_BLOCK_ID

		move.l	(a4)+,d5		;このブロックのサイズ
		sub.l	d5,d6
		bcs	load_phis_file_end	;サイズ異常

		bsr	load_phis_id
load_phis_next:
		adda.l	d5,a4
		bra	load_phis_loop
* 全ブロック終了
load_phis_file_end:
		PRINT_PHIS_DEBUG_MES	'全ブロック終了'
		moveq	#1,d0
		rts

load_phis_error3:
		bsr	load_phis_free
load_phis_error2:
load_phis_close:
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
load_phis_error:
		moveq	#0,d0
		rts


* ID ごとに解釈する
load_phis_id:
		move.l	d5,d0			;作業用
		movea.l	a4,a1			;

		cmpi	#HIS_INFO_ID,d1
		beq	load_phis_id_info
		cmpi	#HIS_PATH_ID,d1
		beq	load_phis_id_path
		cmpi	#HIS_FILE_ID,d1
		beq	load_phis_id_file
		cmpi	#HIS_LOOK_ID,d1
		beq	load_phis_id_look
		cmpi	#HIS_SYS_ID,d1
		beq	load_phis_id_sys
		cmpi	#HIS_MES_ID,d1
		beq	load_phis_id_mes
		cmpi	#HIS_KEYQ_ID,d1
		beq	load_phis_id_keyq
		cmpi	#HIS_CHIS_ID,d1
		beq	load_phis_id_chis


* 未知の種類の ID またはバージョン
		PRINT_PHIS_DEBUG_MES	'未知の種類の ID またはバージョン'
		rts


* ~/.mintrc のファイルサイズ・タイムスタンプ
load_phis_id_info:
		PRINT_PHIS_DEBUG_MES	'ファイルサイズ・タイムスタンプ'
		lea	(mintrc_size-load_phis_flags,a3),a2
		cmpm.l	(a1)+,(a2)+
		seq	d0
		cmpm.l	(a1)+,(a2)+
		seq	d7
		and.b	d0,d7			;d7=$ff: 前回と同じ ~/.mintrc
		rts


* パスヒストリ
load_phis_id_path:
		PRINT_PHIS_DEBUG_MES	'パスヒストリ: ファイル内の値を採用'
		lea	(path_history_buffer-load_phis_flags,a3),a2
		move	#HIS_PATH_LEN/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b
		rts


* ドライブ別カーソルファイル名
load_phis_id_file:
		PRINT_PHIS_DEBUG_MES	'ドライブ別カーソルファイル名: ファイル内の値を採用'
		lea	(drv_curfile_buf-load_phis_flags,a3),a2
		move	#HIS_FILE_LEN/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b
		rts


* &look-file 保存フラグ
load_phis_id_look:
		PRINT_PHIS_DEBUG_MES	'&look-file 保存フラグ: ファイル内の値を採用'
		lea	(lookfile_static_flags-load_phis_flags,a3),a2
	.rept	HIS_LOOK_LEN/4
		move.l	(a1)+,(a2)+
	.endm
		rts


* システム変数
load_phis_id_sys:
		PRINT_PHIS_DEBUG_MES	'システム変数'
		tst.b	d7
		beq	9f

		PRINT_PHIS_DEBUG_MES	'システム変数: ファイル内の値を採用'
		st	(ld_phis_sys_flag-load_phis_flags,a3)

		lea	(sys_val_table-load_phis_flags,a3),a2
		move	#HIS_SYS_LEN/4-1,d0
@@:		move.l	(a1)+,(a2)+
		dbra	d0,@b
9:		rts


* キー定義
load_phis_id_keyq:
		PRINT_PHIS_DEBUG_MES	'キー定義'
		tst.b	d7
		beq	9f

		PRINT_PHIS_DEBUG_MES	'キー定義: ファイル内の値を採用'
		st	(ld_phis_keyq_flag-load_phis_flags,a3)

		lea	(kq_buffer-load_phis_flags,a3),a2
		lea	(4*KQ_ESC,a1),a0
		move.l	(mintrc_buf_adr-load_phis_flags,a3),d2
		bset	#31,d2
		move	#HIS_KEYQ_LEN/4-1,d0
ld_phis_keyq_loop:
		move.l	(a1)+,d1
		beq	ld_phis_keyq_set	;未定義

		add.l	d2,d1			;~/.mintrc 内のアドレスにする
ld_phis_keyq_set:
		move.l	d1,(a2)+
		dbra	d0,ld_phis_keyq_loop
		tst.l	(a0)
		bne	9f			;>KEYesc 未定義ならデフォルト設定にする
		move.l	#key_quick_esc_default,(a0)
9:		rts


* 変更可能文字列
load_phis_id_mes:
		PRINT_PHIS_DEBUG_MES	'変更可能文字列'
		tst.b	d7
		beq	9f

		PRINT_PHIS_DEBUG_MES	'変更可能文字列: ファイル内の値を採用'
		st	(ld_phis_mes_flag-load_phis_flags,a3)

		lea	(mes_ptr_table-load_phis_flags,a3),a2
		move.l	(mintrc_buf_adr-load_phis_flags,a3),d2
		move	#HIS_MES_LEN/4-1,d0
ld_phis_mes_loop:
		move.l	(a1)+,d1
		bpl	ld_phis_mes_next	;未定義

		add.l	d2,d1			;~/.mintrc 内のアドレス & bit31=1 にする
		move.l	d1,(a2)
ld_phis_mes_next:
		addq.l	#4,a2
		dbra	d0,ld_phis_mes_loop
9:		rts


* コマンドヒストリ
*	今は、読み込んだバッファ上のアドレスを記録するだけ。
*	あとで load_command_history を呼び出し、
*	読み込みバッファからコマンドヒストリに転送する。
load_phis_id_chis:
		PRINT_PHIS_DEBUG_MES	'コマンドヒストリ: ファイル内の値を採用'
		movem.l	d5/a1,(cmd_his_size-load_phis_flags,a3)	;cmd_his_size/cmd_his_adr
		rts



* ヒストリファイル名を収得する ---------------- *
* out	d0.l	ドライブの状態(-1 ならエラー)
*	a0.l	ファイル名
*	ccr	正常終了時は Z=1、N=0
*		エラー時は Z=0、N=1
* 備考:
*	ファイル名バッファとして Buffer を使う.

get_path_history_filename:
		lea	(Buffer),a0

		lea	(str_minthis3,pc),a1
		move.b	#'3',(7,a1)			;まず $MINTHIS3
		pea	(a0)
		clr.l	-(sp)
		pea	(a1)
		DOS	_GETENV
		tst.l	d0
		bpl	@f
		clr.b	(7,a1)				;なければ $MINTHIS
		DOS	_GETENV
@@:
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	@f

		move.l	a0,-(sp)
		jbsr	to_fullpath_file
		addq.l	#4,sp

		moveq	#$1f,d1
		and.b	(a0),d1
		jbsr	dos_drvctrl_d1_org	;subst に対応できない...
		moveq	#1<<DRV_NOTREADY+1<<DRV_INSERT+1<<DRV_ERRINS,d1
		and.b	d0,d1
		subq.b	#1<<DRV_INSERT,d1
		bne	@f

		cmp.b	d0,d0			;return Zero
		rts
@@:
		moveq	#-1,d0
		rts


minthis_header:	.dc.b	'minthis/',minthis_ver,CR,LF,EOF,0

str_minthis3:	.dc.b	'MINTHIS3',0
		.even


* Data Section -------------------------------- *

		.data
		.even


* '@' セクションのメニュー定義 ---------------- *
* @comp、@gvon、@look は特別扱いしている.

AT_DEF:		.macro	name
		.dc.l	name
		.ds.b	sizeof_AT_DEF-4		;AT_DEF_PTR, AT_DEF_NUM
		.endm

at_def_list:
at_copy::	AT_DEF	'copy'
at_sort:	AT_DEF	'sort'
at_wild:	AT_DEF	'wild'
at_exec::
	.irp	name,'exec','exe2','exe3','exe4','exe5','exe6','exe7','exe8'
		AT_DEF	name
	.endm
	.irp	name,'exe9','ex10','ex11','ex12','ex13','ex14','ex15','ex16'
		AT_DEF	name
	.endm
at_jump::
	.irp	name,'jump','jmp2','jmp3','jmp4','jmp5','jmp6','jmp7','jmp8'
		AT_DEF	name
	.endm
	.irp	name,'jmp9','jm10','jm11','jm12','jm13','jm14','jm15','jm16'
		AT_DEF	name
	.endm
		.dc	-1
		.even


* システム変数値 ------------------------------ *

sys_val_table::
* ============ 0-9 ============ *
＄6502::	.dc	0
＄6809::	.dc	6
* ============= a ============= *
＄ache::	.dc	0
＄achr::	.dc	0
＄adds::	.dc	1
＄agmd::	.dc	0
＄arc！::	.dc	0
＄arcr::	.dc	0
＄arcw::	.dc	0
* ============= b ============= *
* ============= c ============= *
＄cals::	.dc	1
＄case::	.dc	0
＄cbcl::	.dc	YELLOW
＄cclr::	.dc	0
＄code::	.dc	1
＄col0::	.dc	0	;%00000_00000_00000_0
＄col1::	.dc	$d6b4	;%11010_11010_11010_0
＄col2::	.dc	$bcfe	;%10111_10011_11111_0
＄col3::	.dc	$ffff	;%11111_11111_11111_1
＄cont::	.dc	6
＄cpcl::	.dc	BLUE
＄cplp::	.dc	0
＄crt！::	.dc	3600
＄ctbw::	.dc	4
＄curm::	.dc	0
＄cusr::	.dc	YELLOW
* ============= d ============= *
＄datc::	.dc	YELLOW+EMPHASIS
＄dbox::	.dc	0
＄del！::	.dc	0
＄dicl::	.dc	BLUE
＄dirc::	.dc	WHITE
＄dirh::	.dc	17
＄dirs::	.dc	1024
＄dlnc::	.dc	WHITE
＄dnum::	.dc	BLUE
＄dotn::	.dc	1
＄down::	.dc	0
＄drvv::	.dc	0
＄dtmo::	.dc	0
＄dttl::	.dc	1
＄dz_y::	.dc	3
* ============= e ============= *
＄esc！::	.dc	0
＄excl::	.dc	WHITE
＄exit::	.dc	0
＄exmd::	.dc	0
* ============= f ============= *
＄f_1k::	.dc	0
＄fcmp::	.dc	512
＄finf::	.dc	1
＄fnmd::	.dc	1
＄fumd::	.dc	1
＄fuzy::	.dc	4
* ============= g ============= *
＄gmd2::	.dc	2
＄grm！::	.dc	0
＄gsph::	.dc	32
＄gspl::	.dc	8
＄gton::	.dc	0xffff
＄gyou::	.dc	0
* ============= h ============= *
＄hidc::	.dc	YELLOW
＄hidn::	.dc	1
＄his2::	.dc	0
＄hisc::	.dc	'0'
＄hist::	.dc	4*1024
＄hsp！::	.dc	20
＄hspd::	.dc	8
＄hspw::	.dc	0
＄huge::	.dc	0
* ============= i ============= *
＄infA::	.dc	0
＄infB::	.dc	0
＄infC::	.dc	0
＄infD::	.dc	0
＄infE::	.dc	0
＄infF::	.dc	0
＄infG::	.dc	0
＄infH::	.dc	0
＄infI::	.dc	0
＄infJ::	.dc	0
＄infK::	.dc	0
＄infL::	.dc	0
＄infM::	.dc	0
＄infN::	.dc	0
＄infO::	.dc	0
＄infP::	.dc	0
＄infQ::	.dc	0
＄infR::	.dc	0
＄infS::	.dc	0
＄infT::	.dc	0
＄infU::	.dc	0
＄infV::	.dc	0
＄infW::	.dc	0
＄infX::	.dc	0
＄infY::	.dc	0
＄infZ::	.dc	0
＄intc::	.dc	BLUE+EMPHASIS
＄ivss::	.dc	0
* ============= j ============= *
＄joys::	.dc	0
* ============= k ============= *
＄kpal::	.dc	0
＄kpc1::	.dc	$0020	;%00000_00000_10000_0
＄kpc2::	.dc	$0028	;%00000_00000_10100_0
＄kpd1::	.dc	$fdb6	;%11111_10110_11011_0
＄kpd2::	.dc	$ab66	;%10101_01101_10011_0
＄kps1::	.dc	$0040	;%00000_00001_00000_0
＄kps2::	.dc	$0002	;%00000_00000_00001_0
＄kpu1::	.dc	$fff6	;%11111_11111_11011_0
＄kpu2::	.dc	$ab7e	;%10101_01101_11111_0
＄kz_x::	.dc	8
＄kz_y::	.dc	8
* ============= l ============= *
＄lnkc::	.dc	YELLOW
＄lnum::	.dc	BLUE
＄lrgp::	.dc	1
＄lzhw::	.dc	0
* ============= m ============= *
＄macl::	.dc	BLUE
＄mbox::	.dc	0
＄mdmd::	.dc	1
＄mdxc::	.dc	BLUE+EMPHASIS+REVERSE
＄mdxt::	.dc	1
＄menu::	.dc	1
＄mesl::	.dc	-1
＄moct::	.dc	10
＄mtit::	.dc	2
＄mutc::	.dc	WHITE+EMPHASIS+REVERSE
* ============= n ============= *
＄nmcp::	.dc	1
* ============= o ============= *
＄obcl::	.dc	0
＄opt！::	.dc	0
＄oren::	.dc	1
* ============= p ============= *
＄pdxc::	.dc	BLUE+EMPHASIS
＄prfl::	.dc	0
* ============= q ============= *
* ============= r ============= *
＄rcdk::	.dc	0
＄redc::	.dc	BLUE
＄regw::	.dc	32
* ============= s ============= *
＄same::	.dc	1
＄scrl::	.dc	1
＄scrs::	.dc	4
＄sort::	.dc	0
＄sp_y::	.dc	0
＄spmd::	.dc	1
＄sqms::	.dc	0
＄srtc::	.dc	0
＄srtm::	.dc	3
＄srtr::	.dc	0
＄sysc::	.dc	YELLOW
＄sysn::	.dc	1
* ============= t ============= *
＄tabc::	.dc	1
＄tabw::	.dc	8
＄tarw::	.dc	0
＄tc_1::	.dc	YELLOW+EMPHASIS+REVERSE
＄tc_3::	.dc	WHITE+EMPHASIS+REVERSE
＄tc_4::	.dc	WHITE+EMPHASIS
＄tplt::	.dc	0
* ============= u ============= *
＄unix::	.dc	0
* ============= v ============= *
＄vbar::	.dc	BLUE
＄vccp::	.dc	0
＄vcct::	.dc	0
＄vcl0::	.dc	$0001	;%00000_00000_00000_1
＄vcl1::	.dc	$ffff	;%11111_11111_11111_1
＄vcl2::	.dc	$0701	;%00000_11100_00000_1
＄vcl3::	.dc	$f83f	;%11111_00000_11111_1
＄vcl4::	.dc	$f801	;%11111_00000_00000_1
＄vcl5::	.dc	$07ff	;%00000_11111_11111_1
＄vcl6::	.dc	$ffc1	;%11111_11111_00000_1
＄vcl7::	.dc	$003f	;%00000_00000_11111_1
＄vcol::	.dc	BLUE
＄veof::	.dc	1
＄vexl::	.dc	0
＄vfst::	.dc	1
＄vfun::	.dc	0
＄vocl::	.dc	3
＄volp::	.dc	0
＄vras::	.dc	0
＄vret::	.dc	1
＄vsec::	.dc	BLACK
＄vssc::	.dc	BLUE+1<<WCOL_REV
* ============= w ============= *
＄wcl1::	.dc	$210c	;%00100_00100_00110_0
＄wind::	.dc	1
＄winf::	.dc	0
＄winn::	.dc	0
＄wino::	.dc	-1
* ============= x ============= *
＄xrcl::	.dc	WHITE
* ============= y ============= *
* ============= z ============= *
＄zdrv::	.dc	0
＄zipw::	.dc	0
＄zmst::	.dc	32
* ============================= *
sys_val_table_end::
		.dc	0			;ロングワード単位で転送できるように緩衝材


* システム変数名 ------------------------------ *

		.even
sys_val_name::
		.dc.l	'6502'
		.dc.l	'6809'
		.dc.l	'ache'
		.dc.l	'achr'
		.dc.l	'adds'
		.dc.l	'agmd'
		.dc.l	'arc!'
		.dc.l	'arcr'
		.dc.l	'arcw'
		.dc.l	'cals'
		.dc.l	'case'
		.dc.l	'cbcl'
		.dc.l	'cclr'
		.dc.l	'code'
		.dc.l	'col0'
		.dc.l	'col1'
		.dc.l	'col2'
		.dc.l	'col3'
		.dc.l	'cont'
		.dc.l	'cpcl'
		.dc.l	'cplp'
		.dc.l	'crt!'
		.dc.l	'ctbw'
		.dc.l	'curm'
		.dc.l	'cusr'
		.dc.l	'datc'
		.dc.l	'dbox'
		.dc.l	'del!'
		.dc.l	'dicl'
		.dc.l	'dirc'
		.dc.l	'dirh'
		.dc.l	'dirs'
		.dc.l	'dlnc'
		.dc.l	'dnum'
		.dc.l	'dotn'
		.dc.l	'down'
		.dc.l	'drvv'
		.dc.l	'dtmo'
		.dc.l	'dttl'
		.dc.l	'dz_y'
		.dc.l	'esc!'
		.dc.l	'excl'
		.dc.l	'exit'
		.dc.l	'exmd'
		.dc.l	'f_1k'
		.dc.l	'fcmp'
		.dc.l	'finf'
		.dc.l	'fnmd'
		.dc.l	'fumd'
		.dc.l	'fuzy'
		.dc.l	'gmd2'
		.dc.l	'grm!'
		.dc.l	'gsph'
		.dc.l	'gspl'
		.dc.l	'gton'
		.dc.l	'gyou'
		.dc.l	'hidc'
		.dc.l	'hidn'
		.dc.l	'his2'
		.dc.l	'hisc'
		.dc.l	'hist'
		.dc.l	'hsp!'
		.dc.l	'hspd'
		.dc.l	'hspw'
		.dc.l	'huge'
		.dc.l	'infA'
		.dc.l	'infB'
		.dc.l	'infC'
		.dc.l	'infD'
		.dc.l	'infE'
		.dc.l	'infF'
		.dc.l	'infG'
		.dc.l	'infH'
		.dc.l	'infI'
		.dc.l	'infJ'
		.dc.l	'infK'
		.dc.l	'infL'
		.dc.l	'infM'
		.dc.l	'infN'
		.dc.l	'infO'
		.dc.l	'infP'
		.dc.l	'infQ'
		.dc.l	'infR'
		.dc.l	'infS'
		.dc.l	'infT'
		.dc.l	'infU'
		.dc.l	'infV'
		.dc.l	'infW'
		.dc.l	'infX'
		.dc.l	'infY'
		.dc.l	'infZ'
		.dc.l	'intc'
		.dc.l	'ivss'
		.dc.l	'joys'
		.dc.l	'kpal'
		.dc.l	'kpc1'
		.dc.l	'kpc2'
		.dc.l	'kpd1'
		.dc.l	'kpd2'
		.dc.l	'kps1'
		.dc.l	'kps2'
		.dc.l	'kpu1'
		.dc.l	'kpu2'
		.dc.l	'kz_x'
		.dc.l	'kz_y'
		.dc.l	'lnkc'
		.dc.l	'lnum'
		.dc.l	'lrgp'
		.dc.l	'lzhw'
		.dc.l	'macl'
		.dc.l	'mbox'
		.dc.l	'mdmd'
		.dc.l	'mdxc'
		.dc.l	'mdxt'
		.dc.l	'menu'
		.dc.l	'mesl'
		.dc.l	'moct'
		.dc.l	'mtit'
		.dc.l	'mutc'
		.dc.l	'nmcp'
		.dc.l	'obcl'
		.dc.l	'opt!'
		.dc.l	'oren'
		.dc.l	'pdxc'
		.dc.l	'prfl'
		.dc.l	'rcdk'
		.dc.l	'redc'
		.dc.l	'regw'
		.dc.l	'same'
		.dc.l	'scrl'
		.dc.l	'scrs'
		.dc.l	'sort'
		.dc.l	'sp_y'
		.dc.l	'spmd'
		.dc.l	'sqms'
		.dc.l	'srtc'
		.dc.l	'srtm'
		.dc.l	'srtr'
		.dc.l	'sysc'
		.dc.l	'sysn'
		.dc.l	'tabc'
		.dc.l	'tabw'
		.dc.l	'tarw'
		.dc.l	'tc_1'
		.dc.l	'tc_3'
		.dc.l	'tc_4'
		.dc.l	'tplt'
		.dc.l	'unix'
		.dc.l	'vbar'
		.dc.l	'vccp'
		.dc.l	'vcct'
		.dc.l	'vcl0'
		.dc.l	'vcl1'
		.dc.l	'vcl2'
		.dc.l	'vcl3'
		.dc.l	'vcl4'
		.dc.l	'vcl5'
		.dc.l	'vcl6'
		.dc.l	'vcl7'
		.dc.l	'vcol'
		.dc.l	'veof'
		.dc.l	'vexl'
		.dc.l	'vfst'
		.dc.l	'vfun'
		.dc.l	'vocl'
		.dc.l	'volp'
		.dc.l	'vras'
		.dc.l	'vret'
		.dc.l	'vsec'
		.dc.l	'vssc'
		.dc.l	'wcl1'
		.dc.l	'wind'
		.dc.l	'winf'
		.dc.l	'winn'
		.dc.l	'wino'
		.dc.l	'xrcl'
		.dc.l	'zdrv'
		.dc.l	'zipw'
		.dc.l	'zmst'
*sys_val_name_end:
		.dc.l	0


* キークイック指定子 -------------------------- *

kq_name_list:
	.dc.b	'KEYnul','KEYesc','KEY_1_','KEY_2_','KEY_3_','KEY_4_','KEY_5_','KEY_6_'
	.dc.b	'KEY_7_','KEY_8_','KEY_9_','KEY_0_','KEY_-_','KEY_^_','KEY_\_','KEY_bs'
	.dc.b	'KEYtab','KEY_Q_','KEY_W_','KEY_E_','KEY_R_','KEY_T_','KEY_Y_','KEY_U_'
	.dc.b	'KEY_I_','KEY_O_','KEY_P_','KEY_@_','KEY_[_','KEYret','KEY_A_','KEY_S_'
	.dc.b	'KEY_D_','KEY_F_','KEY_G_','KEY_H_','KEY_J_','KEY_K_','KEY_L_','KEY_;_'
	.dc.b	'KEY_:_','KEY_]_','KEY_Z_','KEY_X_','KEY_C_','KEY_V_','KEY_B_','KEY_N_'
	.dc.b	'KEY_M_','KEY_,_','KEY_._','KEY_/_','KEY___','KEY_ _','KEYhom','KEYdel'
	.dc.b	'KEYrup','KEYrdn','KEYund','KEY_lt','KEY_up','KEY_rt','KEY_dn','KEYclr'
	.dc.b	'KEY_t/','KEY_t*','KEY_t-','KEY_t7','KEY_t8','KEY_t9','KEY_t+','KEY_t4'
	.dc.b	'KEY_t5','KEY_t6','KEY_t=','KEY_t1','KEY_t2','KEY_t3','KEY_te','KEY_t0'
	.dc.b	'KEY_t,','KEY_t.','KEYkig','KEYtou','KEYhel'
	.dc.b						    ,'KEYxf1','KEYxf2','KEYxf3'
	.dc.b	'KEYxf4','KEYxf5','KEYkan','KEYrom','KEYcod','KEYcap','KEYins','KEYhir'
	.dc.b	'KEYzen','KEYbre','KEYcop'
	.dc.b				   'FUNC01','FUNC02','FUNC03','FUNC04','FUNC05'
	.dc.b	'FUNC06','FUNC07','FUNC08','FUNC09','FUNC10'
	.dc.b						     'KEYnmi','KEYpow','KEYerr'
	.dc.b	'KEYsft','KEYctr','KEYop1','KEYop2'
	.dc.b					    'KEYfdd'

	.dc.b	'EXEATR','NO_DEF','NO_MAP','A_EXEC','EXIT_Q','EXIT_2'
	.dc.b	'HELP_E','T_DOWN','V_EXEC','GVON_X'

	.dc.b	'LZHS_X','ZIPS_X','TARS_X'
	.dc.b	'LZHS_D','ZIPS_D','TARS_D'
	.dc.b	'LZHS_A','ZIPS_A','TARS_A'
	.dc.b	'LZHS_Q','ZIPS_Q','TARS_Q'

	.dc.b	0,0,0,0,0,0
	.even


* 内部関数の処理アドレス表 -------------------- *

		.even
func_adr_list:
		.dc.l	＆break-$
		.dc.l	＆if-$
		.dc.l	＆unless-$
		.dc.l	＆else-$
		.dc.l	＆else_if-$
		.dc.l	＆endm-$
		.dc.l	＆eval-$
		.dc.l	＆foreach-$
		.dc.l	＆continue-$
		.dc.l	＆prefix-$
		.dc.l	＆quick_exit-$
		.dc.l	＆quit-$
		.dc.l	＆end-$
		.dc.l	＆set_opt-$
		.dc.l	＆source-$
		.dc.l	＆madoka-$

		.dc.l	＆edit_env_variable-$
		.dc.l	＆set-$
		.dc.l	＆setenv-$
		.dc.l	＆unset-$
		.dc.l	＆unsetenv-$
		.dc.l	＆cal-$

		.dc.l	＆cursor_left-$
		.dc.l	＆cursor_right-$
		.dc.l	＆cursor_up-$
		.dc.l	＆cursor_down-$
		.dc.l	＆cursor_rollup-$
		.dc.l	＆cursor_rolldown-$
		.dc.l	＆cursor_to_home-$
		.dc.l	＆cursor_to_bottom-$
		.dc.l	＆cursor_opposite_window-$
		.dc.l	＆goto_cursor-$

		.dc.l	＆exec_j_special_entry-$
		.dc.l	＆ext_exec-$
		.dc.l	＆ext_exec_or_chdir-$
		.dc.l	＆which-$

		.dc.l	＆cd-$
		.dc.l	＆cdjp-$
		.dc.l	＆chdir_to_opposite_window-$
		.dc.l	＆chdir_to_parent-$
		.dc.l	＆exchange_current-$
		.dc.l	＆local_path-$
		.dc.l	＆set_current_to_opposite-$
		.dc.l	＆set_opposite_window_to_current-$

		.dc.l	＆command_history-$
		.dc.l	＆command_history_menu-$
		.dc.l	＆path_history_menu-$
		.dc.l	＆save_path_history-$
		.dc.l	＆load_path_history-$

		.dc.l	＆chdir_to_registered_path_menu-$
		.dc.l	＆exec_registered_command_menu-$

		.dc.l	＆copy_to_history_menu-$
		.dc.l	＆move_to_history_menu-$
		.dc.l	＆copy_to_registered_path_menu-$
		.dc.l	＆move_to_registered_path_menu-$
		.dc.l	＆direct_copy-$
		.dc.l	＆direct_move-$
		.dc.l	＆copy-$
		.dc.l	＆move-$

		.dc.l	＆i_search-$
		.dc.l	＆mask-$
		.dc.l	＆sort-$

		.dc.l	＆clear_mark-$
		.dc.l	＆is_mark-$
		.dc.l	＆mark-$
		.dc.l	＆mark_reverse-$
		.dc.l	＆mark_upper-$
		.dc.l	＆mark_all_files-$
		.dc.l	＆mark_all-$
		.dc.l	＆reverse_all_file_marks-$
		.dc.l	＆reverse_all_marks-$

		.dc.l	＆exchange_windows-$
		.dc.l	＆grow_window-$
		.dc.l	＆shrink_window-$
		.dc.l	＆window_size-$

		.dc.l	＆clear_and_redraw-$
		.dc.l	＆clear_exec_screen-$
		.dc.l	＆clear_text-$
		.dc.l	＆crt_write_disable-$
		.dc.l	＆pop_text-$

		.dc.l	＆change_drive-$
		.dc.l	＆drive_increment-$
		.dc.l	＆drive_decrement-$
		.dc.l	＆drive_check-$
		.dc.l	＆get_volume_name-$
		.dc.l	＆edit_volume_name-$
		.dc.l	＆eject-$
		.dc.l	＆get_media_byte-$
		.dc.l	＆information-$
		.dc.l	＆is_mount-$
		.dc.l	＆re_mount-$
		.dc.l	＆un_mount-$
		.dc.l	＆reload-$
		.dc.l	＆scsi_check-$
		.dc.l	＆scsi_menu-$
		.dc.l	＆sync-$

		.dc.l	＆maketmp-$
		.dc.l	＆touch-$
		.dc.l	＆chmod-$
		.dc.l	＆ren-$
		.dc.l	＆file_check-$
		.dc.l	＆make_dir_and_move-$
		.dc.l	＆md-$
		.dc.l	＆delete-$
		.dc.l	＆rm-$

		.dc.l	＆rename_menu-$
		.dc.l	＆rename_marked_files_or_directory-$

		.dc.l	＆toggle_drive_information-$
		.dc.l	＆toggle_file_information_mode-$
		.dc.l	＆toggle_interrupt_window-$
		.dc.l	＆toggle_palet_illumination-$
		.dc.l	＆toggle_power_window-$
		.dc.l	＆toggle_screen_saver-$
		.dc.l	＆toggle_window_size-$

		.dc.l	＆echo-$
		.dc.l	＆getsec-$
		.dc.l	＆key_wait-$
		.dc.l	＆print-$
		.dc.l	＆input-$

		.dc.l	＆mpu_power-$
		.dc.l	＆file_compare-$
		.dc.l	＆prchk-$
		.dc.l	＆look_file-$
		.dc.l	＆menu-$
		.dc.l	＆online_switch-$
		.dc.l	＆wait-$
		.dc.l	＆title_load-$

		.dc.l	＆cont_music-$
		.dc.l	＆fade_music-$
		.dc.l	＆pause_music-$
		.dc.l	＆play_music-$
		.dc.l	＆stop_music-$
		.dc.l	＆get_music_status-$
		.dc.l	＆data_title-$
		.dc.l	＆pdx_filename-$

		.dc.l	＆brightness_decrement-$
		.dc.l	＆brightness_increment-$
		.dc.l	＆16color_palet_set-$
		.dc.l	＆64kcolor_palet_set-$
		.dc.l	＆clear_gvram-$
		.dc.l	＆get_color_mode-$
		.dc.l	＆gvon-$
		.dc.l	＆gvram_off-$
		.dc.l	＆mion-$
		.dc.l	＆mioff-$
		.dc.l	＆mono-$
		.dc.l	＆iocs_home-$
		.dc.l	＆rotate_gvram_ccw-$
		.dc.l	＆rotate_gvram_cw-$
		.dc.l	＆half-$
		.dc.l	＆max-$
		.dc.l	＆turn_gvram_left_and_right-$
		.dc.l	＆turn_gvram_upside_down-$

		.dc.l	＆go_screen_saver-$
		.dc.l	＆palet0_set-$
		.dc.l	＆palet0_system-$
		.dc.l	＆palet0_up-$
		.dc.l	＆palet0_down-$

		.dc.l	＆bell-$
		.dc.l	＆v_bell-$
		.dc.l	＆iocs-$
		.dc.l	＆trap-$
		.dc.l	＆execute_binary-$
		.dc.l	＆reset-$
		.dc.l	＆rnd-$
		.dc.l	＆sram_contrast-$
		.dc.l	＆stop_condrv-$
		.dc.l	＆stop_vdisp-$
		.dc.l	＆twentyone_ignore_case-$
		.dc.l	＆set_crtc-$

		.dc.l	＆exist-$
		.dc.l	＆is_mintarc-$
		.dc.l	＆lzh_selector-$
		.dc.l	＆zip_selector-$
		.dc.l	＆tar_selector-$
		.dc.l	＆uncompress-$

		.dc.l	＆file_match-$
		.dc.l	＆match-$
		.dc.l	＆equ-$

		.dc.l	＆iso9660-$
		.dc.l	＆msdos-$
		.dc.l	＆newer_file-$
		.dc.l	＆older_file-$

		.dc.l	＆pushd-$
		.dc.l	＆popd-$
		.dc.l	＆clear_path_stack-$

		.dc.l	＆data_cache_on-$
		.dc.l	＆data_cache_off-$
		.dc.l	＆instruction_cache_on-$
		.dc.l	＆instruction_cache_off-$
		.dc.l	＆cache_on-$
		.dc.l	＆cache_off-$

		.dc.l	＆ext_help-$
		.dc.l	＆describe_key-$

		.dc.l	＆one_ring-$
		.dc.l	＆debug-$
		.dc.l	0


* 内部関数の名前表 ---------------------------- *

func_name_list::
**			'1234567890123456789012345678901234567890'	;40文字制限
		.dc.b	'break',1,'last',0
		.dc.b	'if',0
		.dc.b	'unless',0
		.dc.b	'else',0
		.dc.b	'else-if',1,'elsif',0
		.dc.b	'endm',1,'nop',0
		.dc.b	'eval',0
		.dc.b	'foreach',0
		.dc.b	'next',1,'continue',0
		.dc.b	'prefix',0
		.dc.b	'quick-exit',0
		.dc.b	'quit',0
		.dc.b	'end',1,'return',0
		.dc.b	'set-opt',1,'set-option',0
		.dc.b	'source',0
		.dc.b	'madoka',0

		.dc.b	'edit-env-variable',0
		.dc.b	'set',0
		.dc.b	'setenv',0
		.dc.b	'unset',0
		.dc.b	'unsetenv',0
		.dc.b	'cal',0

		.dc.b	'cursor-left',0
		.dc.b	'cursor-right',0
		.dc.b	'cursor-up',0
		.dc.b	'cursor-down',0
		.dc.b	'cursor-rollup',0
		.dc.b	'cursor-rolldown',0
		.dc.b	'cursor-to-home',0
		.dc.b	'cursor-to-bottom',0
		.dc.b	'cursor-opposite-window',0
		.dc.b	'goto-cursor',0

		.dc.b	'exec-j-special-entry',0
		.dc.b	'ext-exec',0
		.dc.b	'ext-exec-or-chdir',0
		.dc.b	'which',0

		.dc.b	'cd',1,'chdir',0
		.dc.b	'cdjp',0
		.dc.b	'chdir-to-opposite-window',0
		.dc.b	'chdir-to-parent',1,'cursor-to-parent',0
		.dc.b	'exchange-current',0
		.dc.b	'local-path',0
		.dc.b	'set-current-to-opposite',0
		.dc.b	'set-opposite-window-to-current',0

		.dc.b	'command-history',0
		.dc.b	'command-history-menu',0
		.dc.b	'path-history-menu',0
		.dc.b	'save-path-history',0
		.dc.b	'load-path-history',0

		.dc.b	'chdir-to-registered-path-menu',0
		.dc.b	'exec-registered-command-menu',0

		.dc.b	'copy-to-history-menu',0
		.dc.b	'move-to-history-menu',0
		.dc.b	'copy-to-registered-path-menu',0
		.dc.b	'move-to-registered-path-menu',0
		.dc.b	'direct-copy',0
		.dc.b	'direct-move',0
		.dc.b	'copy',1,'cp',0
		.dc.b	'move',0

		.dc.b	'i-search',1,'incremental-search',0
		.dc.b	'mask',1,'mask-regexp',0
		.dc.b	'sort',1,'sort-menu',0

		.dc.b	'clear-mark',0
		.dc.b	'is-mark',0
		.dc.b	'mark',1,'mark-forward',0
		.dc.b	'mark-reverse',0
		.dc.b	'mark-upper',0
		.dc.b	'mark-all-files',0
		.dc.b	'mark-all',0
		.dc.b	'reverse-all-file-marks',0
		.dc.b	'reverse-all-marks',0

		.dc.b	'exchange-windows',0
		.dc.b	'grow-window',0
		.dc.b	'shrink-window',0
		.dc.b	'window-size',0

		.dc.b	'clear-and-redraw',0
		.dc.b	'clear-exec-screen',0
		.dc.b	'clear-text',0
		.dc.b	'crt-write-disable',0
		.dc.b	'pop-text',0

		.dc.b	'change-drive',1,'change-drive-menu',0
		.dc.b	'drive-increment',0
		.dc.b	'drive-decrement',0
		.dc.b	'drive-check',0
		.dc.b	'get-volume-name',0
		.dc.b	'edit-volume-name',0
		.dc.b	'eject',0
		.dc.b	'get-media-byte',0
		.dc.b	'information',0
		.dc.b	'is-mount',0
		.dc.b	're-mount',0
		.dc.b	'un-mount',0
		.dc.b	'reload',0
		.dc.b	'scsi-check',0
		.dc.b	'scsi-menu',0
		.dc.b	'sync',0

		.dc.b	'maketmp',0
		.dc.b	'touch',0
		.dc.b	'chmod',0
		.dc.b	'ren',1,'rename',0
		.dc.b	'file-check',0
		.dc.b	'make-dir-and-move',0
		.dc.b	'md',1,'mkdir',1,'make-dirs',0
		.dc.b	'delete',0
		.dc.b	'rm',1,'del',0

		.dc.b	'rename-menu',0
		.dc.b	'rename-marked-files-or-directory',0

		.dc.b	'toggle-drive-information',0
		.dc.b	'toggle-file-information-mode',0
		.dc.b	'toggle-interrupt-window',0
		.dc.b	'toggle-palet-illumination',0
		.dc.b	'toggle-power-window',0
		.dc.b	'toggle-screen-saver',0
		.dc.b	'toggle-window-size',0

		.dc.b	'echo',0
		.dc.b	'getsec',0
		.dc.b	'key-wait',0
		.dc.b	'print',1,'ask-yn',0
		.dc.b	'input',1,'readline',0

		.dc.b	'mpu-power',1,'cpu-power',0
		.dc.b	'file-compare',0
		.dc.b	'prchk',1,'keep-check',0
		.dc.b	'look-file',0
		.dc.b	'menu',0
		.dc.b	'online-switch',0
		.dc.b	'wait',1,'sleep',0
		.dc.b	'title-load',0

		.dc.b	'cont-music',1,'continue-music',0
		.dc.b	'fade-music',1,'fadeout-music',0
		.dc.b	'pause-music',0
		.dc.b	'play-music',0
		.dc.b	'stop-music',0
		.dc.b	'get-music-status',0
		.dc.b	'data-title',0
		.dc.b	'pdx-filename',0

		.dc.b	'brightness-decrement',1,'16color-brightness-decrement',0
		.dc.b	'brightness-increment',1,'16color-brightness-increment',0
		.dc.b	'16color-palet-set',0
		.dc.b	'64kcolor-palet-set',0
		.dc.b	'clear-gvram',0
		.dc.b	'get-color-mode',0
		.dc.b	'gvon',1,'gvram-on',0
		.dc.b	'gvram-off',0
		.dc.b	'mion',1,'gvram-text-blend-on',0
		.dc.b	'mioff',1,'gvram-text-blend-off',0
		.dc.b	'mono',1,'gvram-to-monochrome',0
		.dc.b	'iocs-home',0
		.dc.b	'rotate-gvram-ccw',0
		.dc.b	'rotate-gvram-cw',0
		.dc.b	'half',1,'set-brightness-to-half',0
		.dc.b	'max',1,'set-brightness-to-max',0
		.dc.b	'turn-gvram-left-and-right',0
		.dc.b	'turn-gvram-upside-down',0

		.dc.b	'go-screen-saver',0
		.dc.b	'palet0-set',0
		.dc.b	'palet0-system',0
		.dc.b	'palet0-up',0
		.dc.b	'palet0-down',0

		.dc.b	'bell',1,'beep',0
		.dc.b	'v-bell',1,'visual-bell',0
		.dc.b	'iocs',0
		.dc.b	'trap',0
		.dc.b	'execute-binary',0
		.dc.b	'reset',0
		.dc.b	'rnd',0
		.dc.b	'sram-contrast',0
		.dc.b	'stop-condrv',0
		.dc.b	'stop-vdisp',0
		.dc.b	'twentyone-ignore-case',0
		.dc.b	'set-crtc',0

		.dc.b	'exist',1,'arc-exist',0
		.dc.b	'is-mintarc',0
		.dc.b	'lzh-selector',0
		.dc.b	'zip-selector',0
		.dc.b	'tar-selector',0
		.dc.b	'uncompress',0

		.dc.b	'file-match',0
		.dc.b	'match',0
		.dc.b	'equ',1,'strcmp',0

		.dc.b	'iso9660',0
		.dc.b	'msdos',0
		.dc.b	'newer-file',0
		.dc.b	'older-file',0

		.dc.b	'pushd',0
		.dc.b	'popd',0
		.dc.b	'clear-path-stack',0

		.dc.b	'data-cache-on',0
		.dc.b	'data-cache-off',0
		.dc.b	'instruction-cache-on',0
		.dc.b	'instruction-cache-off',0
		.dc.b	'cache-on',0
		.dc.b	'cache-off',0

		.dc.b	'ext-help',0
		.dc.b	'describe-key',0

		.dc.b	'one-ring',0
		.dc.b	'debug',0
**			'1234567890123456789012345678901234567890'	;40 文字制限
*func_name_list_end:
		.dc.b	0,0,0,0
		.even


* Block Storage Section ----------------------- *

			.bss
			.even

kq_buffer::		.ds.l	KQ_MAX

hook_vec_save:		.ds.l	1		;_CTRLVC 用
			.ds.l	5

fnckey_save_buf:	.ds.b	712		;起動時のキー定義保存

path_buffer:		.ds.b	sizeof_PATHBUF	;left
			.ds.b	sizeof_PATHBUF	;right

mask_regexp_pattern:	.ds.b	MASK_REGEXP_SIZE	;left
			.ds.b	MASK_REGEXP_SIZE	;right

macro_table::		.ds.l	256
macro_table_end:	.ds.l	1
file_match_table:	.ds.l	256
file_match_table_end:	.ds.l	1

file_match_buffer::	.ds.b	FCMP_MAX+16

file_compare_table:	.ds.b	1024*4+256	;結構余分にいる…
file_compare_table_end:	.ds.b	256

drv_curfile_buf:	.ds.b	HIS_FILE_LEN
mount_buf:		.ds.b	64*26

時間_実行前::		.ds.l	1
時間_実行後::		.ds.l	1
malloc_mode::		.ds	1

MINT_TEMP::		.ds.b	66
oldpwd_buf::		.ds.b	66
next_oldpwd:		.ds.b	66
boot_directory:		.ds.b	66
cur_dir_buf::		.ds.b	66

			.even
mintrc_filename::	.ds.b	90		;定義ファイル名
mintrc_buf_adr::	.ds.l	1		;バッファ先頭アドレス
mintrc_buf_size:	.ds.l	1		;バッファサイズ
mintrc_size:		.ds.l	1		;ファイルサイズ
mintrc_timestamp:	.ds.l	1		;タイムスタンプ

load_phis_flags:
ld_phis_sys_flag:  .ds.b 1  ;システム変数を $MINTHIS から読み込んだか
ld_phis_keyq_flag: .ds.b 1  ;キー定義〃
ld_phis_mes_flag:  .ds.b 1  ;変更可能文字列〃
                   .ds.b 1  ;4 byte パディング
.even
cmd_his_memblk: .ds.l 1
cmd_his_size:   .ds.l 1
cmd_his_adr:    .ds.l 1

clock_value: .ds.b sizeof_CLOCK_VALUE

* TempBuffer == DpbBuffer にしておくこと.
TempBuffer:
DpbBuffer:		.ds.b	DPB_SIZE

			.even
Buffer::		.ds.b	1024*10
			.ds.b	8


* Stack Section ------------------------------- *

		.stack
		.even

* システム変数保存バッファ(ヒストリ書き出し用)
sys_val_save:
**		.ds.b	sys_val_table_end-sys_val_table


* スタック
		.ds.b	 2*1024
stack_top::	.ds.b	14*1024
stack_bottom:


		.end	mint_start

* End of File --------------------------------- *
