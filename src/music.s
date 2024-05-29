# music.s - music driver utility
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

		.include	mint.mac
		.include	music.mac
		.include	message.mac
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac


* Global Symbol ------------------------------- *

* madoka3.s
		.xref	＠buildin,＠status
* mint.s
		.xref	scr_mdxt_line
		.xref	set_scroll_narrow_console


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*************************************************
*		&cont-music=&continue-music	*
*************************************************

＆cont_music::
＆continue_music::
*		pea	(@f,pc)
		bsr	command_music
@@:
		.dc	cont_music_mxdrv-@b
		.dc	cont_music_madrv-@b
		.dc	cont_music_mld-@b
		.dc	cont_music_mcdrv-@b
		.dc	cont_music_zmsc2-@b
		.dc	cont_music_zmsc3-@b
		.dc	cont_music_middrv-@b
		.dc	cont_music_mndrv-@b
		.dc	cont_music_rcd-@b
		.dc	cont_music_pochi-@b

cont_music_mxdrv:
		MXDRV	MXDRV_MCONT
		rts

cont_music_madrv:
		MADRV	MADRV_CONTINUE
		rts

cont_music_mld:
		moveq	#0,d1
		MLD	MLD_CONT
		rts

cont_music_mcdrv:
		bsr	get_music_status_mcdrv
		subq	#STAT_PAUSE,d0
		bne	@f
		MCDRV	MCDRV_PAUSE
@@:		rts

cont_music_zmsc2:
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMSC2	ZMSC2_M_CONT
		rts

cont_music_zmsc3:
		suba.l	a1,a1
		ZMSC3	ZMSC3_CONT
		rts

cont_music_middrv:
		MIDDRV	MIDD_RESTART
		rts

cont_music_mndrv:
		bsr	get_music_status_mndrv
		subq	#STAT_PAUSE,d0
		bne	@f
		MNDRV	MNDRV_PAUSE
@@:		rts

cont_music_rcd:
		bsr	get_music_status_rcd
		subq	#STAT_PLAY,d0
		bne	play_music_rcd
		rts

cont_music_pochi:
		POCHI	PO_CONTINUE
		rts


*************************************************
*		&fade-music-&fadeout-music	*
*************************************************

＆fade_music::
＆fadeout_music::
*		pea	(@f,pc)
		bsr	command_music
@@:
		.dc	fade_music_mxdrv-@b
		.dc	fade_music_madrv-@b
		.dc	fade_music_mld-@b
		.dc	fade_music_mcdrv-@b
		.dc	fade_music_zmsc2-@b
		.dc	fade_music_zmsc3-@b
		.dc	fade_music_middrv-@b
		.dc	fade_music_mndrv-@b
		.dc	fade_music_rcd-@b
		.dc	fade_music_pochi-@b

fade_music_mxdrv:
		moveq	#19,d1
		MXDRV	MXDRV_FADEOUT
		rts

fade_music_madrv:
		MADRV	MADRV_FADEOUT
		rts

fade_music_mld:
		MLD	MLD_F_OUT
		rts

fade_music_mcdrv:
		moveq	#10,d1
		MCDRV	MCDRV_FADEOUT
		rts

fade_music_zmsc2:
		moveq	#16,d2
		ZMSC2	ZMSC2_FADE_OUT
		rts

fade_music_zmsc3:
		lea	(fade_music_zmsc3_data,pc),a1
		ZMSC3	ZMSC3_M_FADER
		rts

fade_music_zmsc3_data:
		.dc	-1			;カレント MIDI
		.dc.b	7			;全機能有効
		.dc.b	$10,$00			;移動速度
		.dc.b	$80			;開始レベル
nul_str:	.dc.b	0			;終了レベル
		.even

fade_music_middrv:
		moveq	#0,d1
		MIDDRV	MIDD_FADEOUT
		rts

fade_music_mndrv:
		MNDRV	MNDRV_FADEOUT
		rts

fade_music_rcd:
		movea.l	(rcd_ptr,pc),a0
		move.b	#128,(RCD_FADE_CNT,a0)
		rts

fade_music_pochi:
		POCHI	PO_FADEOUT+384
		rts


*************************************************
*		&pause_music			*
*************************************************

＆pause_music::
*		pea	(@f,pc)
		bsr	command_music
@@:
		.dc	pause_music_mxdrv-@b
		.dc	pause_music_madrv-@b
		.dc	pause_music_mld-@b
		.dc	pause_music_mcdrv-@b
		.dc	pause_music_zmsc2-@b
		.dc	pause_music_zmsc3-@b
		.dc	pause_music_middrv-@b
		.dc	pause_music_mndrv-@b
		.dc	pause_music_rcd-@b
		.dc	pause_music_pochi-@b

pause_music_mxdrv:
		MXDRV	MXDRV_MPAUSE
		rts

pause_music_madrv:
		MADRV	MADRV_PAUSE
		rts

pause_music_mld:
		MLD	MLD_END
		rts

pause_music_mcdrv:
		bsr	get_music_status_mcdrv
		subq	#STAT_PLAY,d0
		bne	@f
		MCDRV	MCDRV_PAUSE
@@:		rts

pause_music_zmsc2:
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMSC2	ZMSC2_M_STOP
		rts

pause_music_zmsc3:
		suba.l	a1,a1
		ZMSC3	ZMSC3_STOP
		rts

pause_music_middrv:
		MIDDRV	MIDD_PLAYSTOP
		rts

pause_music_mndrv:
		bsr	get_music_status_mndrv
		subq	#STAT_PLAY,d0
		bne	@f
		MNDRV	MNDRV_PAUSE
@@:		rts

*pause_music_rcd:
*		RCD	RCD_END
*		rts

pause_music_pochi:
		POCHI	PO_PAUSE
		rts


*************************************************
*		&play-music			*
*************************************************

＆play_music::
*		pea	(@f,pc)
		bsr	command_music
@@:
		.dc	play_music_mxdrv-@b
		.dc	play_music_madrv-@b
		.dc	play_music_mld-@b
		.dc	play_music_mcdrv-@b
		.dc	play_music_zmsc2-@b
		.dc	play_music_zmsc3-@b
		.dc	play_music_middrv-@b
		.dc	play_music_mndrv-@b
		.dc	play_music_rcd-@b
		.dc	play_music_pochi-@b

play_music_mxdrv:
		MXDRV	MXDRV_MPLAY
		rts

play_music_madrv:
		MADRV	MADRV_START
		rts

play_music_mld:
		moveq	#0,d1
		MLD	MLD_PLAY
		rts

play_music_mcdrv:
		bsr	stop_music_mcdrv
		MCDRV	MCDRV_PLAY
		rts

play_music_zmsc2:
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMSC2	ZMSC2_M_PLAY
		rts

play_music_zmsc3:
		ZMSC3	ZMSC3_PLAY2
		rts

play_music_middrv:
		MIDDRV	MIDD_PLAYSTART
		rts

play_music_mndrv:
		MNDRV	MNDRV_PLAY
		rts

play_music_rcd:
		RCD	RCD_BEGIN
		rts

play_music_pochi:
		POCHI	PO_PLAY
		rts


*************************************************
*		&stop-music			*
*************************************************

＆stop_music::
*		pea	(@f,pc)
		bsr	command_music
@@:
		.dc	stop_music_mxdrv-@b
		.dc	stop_music_madrv-@b
		.dc	stop_music_mld-@b
		.dc	stop_music_mcdrv-@b
		.dc	stop_music_zmsc2-@b
		.dc	stop_music_zmsc3-@b
		.dc	stop_music_middrv-@b
		.dc	stop_music_mndrv-@b
		.dc	stop_music_rcd-@b
		.dc	stop_music_pochi-@b

stop_music_mxdrv:
		MXDRV	MXDRV_MSTOP
		rts

stop_music_madrv:
		MADRV	MADRV_STOP
		rts

stop_music_mld:
		MLD	MLD_STOP
		rts

stop_music_mcdrv:
		MCDRV	MCDRV_STOP
		rts

stop_music_zmsc2:
*		moveq	#0,d2
*		moveq	#0,d3
*		moveq	#0,d4
*		ZMSC2	ZMSC2_M_STOP

*		ZMSC2	ZMSC2_INT_STOP
*		ZMSC2	ZMSC2_INT_START

		moveq	#1,d2
		ZMSC2	ZMSC2_TOTAL
		rts

stop_music_zmsc3:
		moveq	#0,d1
		ZMSC3	ZMSC3_INIT
		rts

stop_music_middrv:
		bsr	pause_music_middrv
		MIDDRV	MIDD_WORKINIT
		rts

stop_music_mndrv:
		MNDRV	MNDRV_STOP
		rts

pause_music_rcd:
stop_music_rcd:
		RCD	RCD_END
		rts

stop_music_pochi:
		POCHI	PO_STOP
		rts


*************************************************
*		&get-music-status		*
*************************************************

＆get_music_status::
*		pea	(@f,pc)
		bsr	command_music2
@@:
		.dc	get_music_status_mxdrv-@b
		.dc	get_music_status_madrv-@b
		.dc	get_music_status_mld-@b
		.dc	get_music_status_mcdrv-@b
		.dc	get_music_status_zmsc2-@b
		.dc	get_music_status_zmsc3-@b
		.dc	get_music_status_middrv-@b
		.dc	get_music_status_mndrv-@b
		.dc	get_music_status_rcd-@b
		.dc	get_music_status_pochi-@b

get_music_status_mxdrv:
		MXDRV	MXDRV_STATUS
		tst	d0
		beq	get_music_status_playing
		tst.b	d0
		beq	get_music_status_pause
		bra	get_music_status_stop

get_music_status_madrv:
		MADRV	MADRV_STATUS
		ror	#2,d0
		bcs	get_music_status_playing
		add	d0,d0
		bmi	get_music_status_pause
		bra	get_music_status_stop

get_music_status_mld:
		moveq	#1,d1
		MLD	MLD_G_PCCH
		tst.l	d0
		beq	get_music_status_stop
		MLD	MLD_PAUSE
		tst.b	d0
		bne	get_music_status_pause
		bra	get_music_status_playing

get_music_status_mcdrv:
		MCDRV	MCDRV_WORKADR
		movea.l	d0,a0
		moveq	#STAT_STOP,d0
		add	(INF_PLAY,a0),d0	;0=stop 1:pause 2:play
		rts

get_music_status_zmsc2:
		moveq	#0,d2
		ZMSC2	ZMSC2_M_STAT
		tst.l	d0
		bne	get_music_status_playing

* 全チャンネル停止なら、演奏終了したのか m_stop 中か調べる
		moveq	#1,d2
		ZMSC2	ZMSC2_PLAYWORK
		lea	(a0),a1			;トラックワーク先頭
		ZMSC2	ZMSC2_TRKTBL
get_music_status_zmsc2_loop:
		move.b	(a0)+,d0
		cmpi.b	#$ff,d0
		beq	get_music_status_stop

		lsl	#8,d0
		move.b	(P_NOT_EMPTY,a1,d0.w),d0
		cmpi.b	#$99,d0
		beq	@f
		cmpi.b	#$ee,d0
		bne	get_music_status_zmsc2_loop
@@:
		bra	get_music_status_pause

get_music_status_zmsc3:
		moveq	#0,d1
		movea.l	d1,a1
		ZMSC3	ZMSC3_STATUS
		tst.l	d0
		bne	get_music_status_playing

* 演奏停止状態で停止済み＆未再開なら一時停止
		ZMSC3	ZMSC3_STATWORK
		moveq	#-1,d0
		cmp.l	(PLAY_STOP_TIME,a0),d0
		beq	@f
		cmp.l	(PLAY_CONT_TIME,a0),d0
		beq	get_music_status_pause
@@:
		bra	get_music_status_stop

get_music_status_middrv:
		MIDDRV	MIDD_DRVSTATUS
		tst	d0
		beq	get_music_status_stop
		cmpi	#254,d0
		beq	get_music_status_pause
		bhi	get_music_status_stop
		bra	get_music_status_playing

get_music_status_mndrv:
		MNDRV	MNDRV_GETSTATUS
		add.l	d0,d0
		bcc	get_music_status_stop
		bmi	get_music_status_pause
		bra	get_music_status_playing

get_music_status_rcd:
		movea.l	(rcd_ptr,pc),a0
		moveq	#1,d0
		cmp.l	(RCD_ACT,a0),d0
		bne	get_music_status_stop
*		cmp.l	(RCD_STS,a0),d0
*		beq	get_music_status_pause
		bra	get_music_status_playing

get_music_status_pochi:
		POCHI	PO_LOOPCOUNT
		not.l	d0
		bne	get_music_status_playing
		bra	get_music_status_stop

get_music_status_stop:
		moveq	#STAT_STOP,d0
		rts
get_music_status_pause:
		moveq	#STAT_PAUSE,d0
		rts
get_music_status_playing:
		moveq	#STAT_PLAY,d0
		rts


* 音源ドライバ制御系共通処理 ------------------ *

command_music:
		movea.l	(sp)+,a1

		TO_SUPER
		bsr	get_music_driver_type
		bmi	command_music_error

		lea	(a1),a0
		bsr	call_music_driver_job
		TO_USER

		bsr	print_music_title
		moveq	#1,d0
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts

command_music_error:
		TO_USER
		moveq	#0,d0
		bra	set_status

command_music2:
		movea.l	(sp)+,a1

		TO_SUPER
		bsr	get_music_driver_type
		bmi	command_music_error

		lea	(a1),a0
		bsr	call_music_driver_job
		bsr	set_status
		TO_USER
		rts


* 音源ドライバ別の処理呼び出し ---------------- *
* in	d0.l	ドライバ番号
*	a0.l	処理アドレステーブル

call_music_driver_job:
		add	d0,d0
		adda	(a0,d0.w),a0
		jmp	(a0)


*************************************************
*		音楽タイトル表示		*
*************************************************

print_music_title::
		tst	(＄mdxt)
		beq	print_music_title_end2

		TO_SUPER
		lea	(-128,sp),sp
		bsr	get_music_driver_type
		bmi	print_music_title_clear

		lea	(sp),a1
		lea	(print_music_title_table,pc),a0
		bsr	call_music_driver_job
		bmi	print_music_title_clear

		move	(＄mdxc),d1
		move	(＄mbox),d2
		lea	(sp),a1
		bsr	print_music_data_title_sub
print_music_title_end:
		lea	(128,sp),sp
		TO_USER
print_music_title_end2:
		rts

print_music_data_title_sub::
		move	d2,-(sp)
		move	d1,-(sp)

		lea	(music_data_title_flag,pc),a0
		tas	(a0)
		bmi	print_music_data_title_ow

		bsr	is_mtit_2
		bcs	@f
		jsr	(SaveCursor)
		bsr	delete_topline		;%mtit 2 の時は最下行を空ける
		jsr	(RestoreCursor)
@@:
		moveq	#1,d1
		IOCS	_B_UP
		jsr	(set_scroll_narrow_console)
print_music_data_title_ow:

		move	(sp)+,d1
		bsr	b_putmes

		lea	(music_data_title_box,pc),a1
		move	(sp)+,(TXBOX_PLANE,a1)
		beq	@f
		tas	(TXBOX_PLANE,a1)	;複数プレーン同時書き込み
		lsl	#4,d3
		move	d3,(TXBOX_YSTART,a1)
		IOCS	_TXBOX
@@:
		rts

is_mtit_2:
		cmpi	#2,(＄mtit)
		rts

delete_topline:
		moveq	#0,d1
		moveq	#0,d2
		IOCS	_B_LOCATE
		moveq	#1,d1
		IOCS	_B_DEL
		rts

b_putmes:
		moveq	#0,d2
		move	(scr_mdxt_line),d3
		moveq	#96-1,d4
		IOCS	_B_PUTMES
		rts


print_music_title_clear:
		lea	(music_data_title_flag,pc),a1
		tst.b	(a1)
		beq	print_music_title_end

		clr.b	(a1)

		jsr	(set_scroll_narrow_console)
		bsr	is_mtit_2
		bcs	@f

		moveq	#BLACK,d1		;%mtit 2 の時は最終行をクリアする
		lea	(nul_str,pc),a1
		bsr	b_putmes
		bra	print_music_title_clear_end
@@:
		bsr	delete_topline		;タイトルを押し出す
		jsr	(RestoreCursor)
print_music_title_clear_end:
		bra	print_music_title_end

* タイトル収得用アドレステーブル
* in	a1.l	バッファ
* out	d0.l	0:正常終了 -1:エラー(非演奏中等)

print_music_title_table:
@@:		.dc	print_music_title_mxdrv-@b
		.dc	print_music_title_madrv-@b
		.dc	print_music_title_mld-@b
		.dc	print_music_title_mcdrv-@b
		.dc	print_music_title_zmsc2-@b
		.dc	print_music_title_zmsc3-@b
		.dc	print_music_title_middrv-@b
		.dc	print_music_title_mndrv-@b
		.dc	print_music_title_rcd-@b
		.dc	print_music_title_pochi-@b

print_music_title_mxdrv:
		moveq	#0,d1
		MXDRV	MXDRV_TITLE
		tst.l	d0
		beq	print_music_title_error
		movea.l	d0,a0
		moveq	#MES_M_MDX,d0
		bra	set_music_title

print_music_title_madrv:
		MADRV	MADRV_TITLE
		moveq	#MES_M_MAD,d0
		bra	set_music_title

print_music_title_mld:
		moveq	#0,d1
		MLD	MLD_NAME_ADR
		tst.l	d0
		beq	print_music_title_error
		movea.l	d0,a0
		moveq	#MES_M_MLD,d0
		bra	set_music_title

print_music_title_mcdrv:
		MCDRV	MCDRV_TITLE
		movea.l	d0,a0
		moveq	#MES_M_MCD,d0
		bra	set_music_title

print_music_title_zmsc2:
		ZMSC2	ZMSC2_COMMENT
		moveq	#MES_M_ZMU,d0
		bra	set_music_title

print_music_title_zmsc3:
		ZMSC3	ZMSC3_COMMENT
		tst.l	d0
		bmi	print_music_title_error
		moveq	#MES_M_ZM3,d0
		bra	set_music_title

print_music_title_middrv:
		move.l	a1,-(sp)
		MIDDRV	MIDD_GETTITLE
		lea	(1,a1),a0
		move.l	(sp)+,a1
		moveq	#MES_M_MID,d0
		bra	set_music_title

print_music_title_mndrv:
		move.l	a1,-(sp)
		MNDRV	MNDRV_GETTITLE
		move.l	(sp)+,a1
		tst.l	d0
		beq	print_music_title_error
		movea.l	d0,a0
		moveq	#MES_M_MND,d0
		bra	set_music_title

print_music_title_rcd:
		movea.l	(rcd_ptr,pc),a0
		cmpi.b	#1,(RCD_DATA_VALID,a0)
		bne	print_music_title_error
		movea.l	(RCD_DATA_ADR,a0),a0
		lea	($20,a0),a0
		moveq	#MES_M_RCD,d0

		tst.b	(a0)
		beq	print_music_title_error

		bsr	set_music_title_header_sub
		bne	set_music_title_end

		moveq	#64-1,d0
		cmp	d0,d7
		bls	set_music_title_loop
		moveq	#64-1,d7
		bra	set_music_title_loop

print_music_title_pochi:
		POCHI	PO_GET_BUF
		movea.l	d0,a0
		move.l	(POCHI_TITLE,a0),d0
		beq	print_music_title_error
		adda.l	d0,a0
		moveq	#MES_M_POC,d0
		bra	set_music_title

print_music_title_error:
		moveq	#-1,d0
		rts

* タイトル表示共通処理 ------------------------ *

set_music_title:
		tst.b	(a0)
		beq	print_music_title_error

		bsr	set_music_title_header_sub
		bne	set_music_title_end
set_music_title_loop:
		move.b	(a0)+,d0
		beq	set_music_title_end
		cmpi.b	#$20,d0
		bcc	set_music_title_copy
		bsr	is_eof_or_cr_or_lf
		beq	set_music_title_end
		cmpi.b	#ESC,d0
		bne	set_music_title_ctrl
		cmpi.b	#'[',(a0)
		bne	set_music_title_ctrl

		lea	(a0),a2			;^[[...m
		addq.l	#1,a0
set_music_title_esc_loop:
		move.b	(a0)+,d0		;ESCシーケンスを削除する
		cmpi.b	#'m',d0
		beq	set_music_title_loop
		cmpi.b	#';',d0
		beq	set_music_title_esc_loop
		subi.b	#'0',d0
		cmpi.b	#9,d0
		bls	set_music_title_esc_loop
		lea	(a2),a0			;^[[...m以外は削除しない
set_music_title_ctrl:
		moveq	#SPACE,d0
set_music_title_copy:
		move.b	d0,(a1)+
		dbra	d7,set_music_title_loop
set_music_title_end:
		clr.b	(a1)
		moveq	#0,d0
		rts

is_eof_or_cr_or_lf:
		cmpi.b	#EOF,d0
		beq	@f
		cmpi.b	#CR,d0
		beq	@f
		cmpi.b	#LF,d0
@@:		rts

set_music_title_header_sub:
		move.l	a0,-(sp)
		jsr	(get_message)
		movea.l	d0,a0
		moveq	#96-1,d7
@@:
		move.b	(a0)+,(a1)+		;[ ドライバ種別 ]
		dbeq	d7,@b
		subq.l	#1,a1
		movea.l	(sp)+,a0
		rts


* 音源ドライバの常駐検査 ---------------------- *
* out	d0.l	 0:mxdrv
*		 1:madrv
*		 2:mld
*		 3:mcdrv
*		 4:zmusic v2
*		 5:zmusic v3
*		 6:middrv
*		 7:mndrv
*		 8:rcd
*		 9:pochi
*		-1:error
* break	a0.l

get_music_driver_type:
		movea.l	(TRAP4_VEC*4),a0
		cmpi.l	#'v206',-(a0)
		bne	@f
		cmpi.l	#'mxdr',-(a0)
		bne	@f

		moveq	#TYPE_MXDRV,d0
		rts
@@:
		movea.l	(TRAP4_VEC*4),a0
		subq.l	#4,a0
		cmpi.l	#'RV3*',-(a0)
		bne	@f
		cmpi.l	#'*MAD',-(a0)
		bne	@f

		moveq	#TYPE_MADRV,d0
		rts
@@:
		movea.l	(TRAP4_VEC*4),a0
		subq.l	#4+2,a0
		cmpi.l	#"MIDI",-(a0)
		bne	@f
		cmpi.l	#"Rie'",-(a0)
		bne	@f

		moveq	#TYPE_MLD,d0
		rts
@@:
		movea.l	(TRAP4_VEC*4),a0
		subq.l	#4,a0
		cmpi.l	#'RV0-',-(a0)
		bne	@f
		cmpi.l	#'-MCD',-(a0)
		bne	@f

		moveq	#TYPE_MCDRV,d0
		rts
@@:
		movea.l	(TRAP3_VEC*4),a0
		subq.l	#8,a0
		cmpi.l	#'ZmuS',(a0)+
		bne	@f
		cmpi	#'iC',(a0)+
		bne	@f
		cmpi	#$3000,(a0)
		bcc	1f

		moveq	#TYPE_ZMSC2,d0
		rts
1:		moveq	#TYPE_ZMSC3,d0
		rts
@@:
		movea.l	(TRAP3_VEC*4),a0
		cmpi.l	#'MIDD',-(a0)
		bne	@f

		moveq	#TYPE_MIDDRV,d0
		rts
@@:
		movea.l	(TRAP4_VEC*4),a0
		cmpi.l	#'rv-'<<8,-(a0)
		bne	@f
		cmpi.l	#'-mnd',-(a0)
		bne	@f
		cmpi.l	#$0127_0000,-(a0)
		bcs	@f

		moveq	#TYPE_MNDRV,d0
		rts
@@:
		moveq	#1<<0,d0
		and	(＄rcdk),d0		;bit0
		bne	@f
		bsr	keepchk_rcd
		bne	@f

		moveq	#TYPE_RCD,d0
		rts
@@:
		movea.l	(TRAP0_VEC*4),a0
		addq.l	#4,a0
		cmpi.l	#'pdm'<<8,(a0)+
		bne	@f
		tst.l	(a0)+
		bne	@f

		moveq	#TYPE_POCHI,d0
		rts
@@:
		moveq	#-1,d0
		rts

* RCD 常駐検査

keepchk_rcd:
		move.l	a1,-(sp)
		move.l	(human_psp,pc),d0
keepchk_rcd_loop:
		movea.l	d0,a0
		cmpi.b	#MEM_KEEP,(pare,a0)
		bne	keepchk_rcd_next

		lea	(PSP_SIZE+RCD_HEAD_SIZE,a0),a1
		cmpa.l	(end_,a0),a1
		bhi	keepchk_rcd_next

		lea	(PSP_SIZE,a0),a1
		cmpi.l	#'RCD ',(RCD_TITLE,a1)
		bne	keepchk_rcd_next
		cmpi.l	#$12345678,(RCD_STAYMARK,a1)
		bne	keepchk_rcd_next
		cmpi.b	#'3',(RCD_VERSION,a1)
		bhi	keepchk_rcd_error

		lea	(rcd_ptr,pc),a0
		move.l	a1,(a0)
		movea.l	(sp)+,a1
		moveq	#0,d0
		rts
keepchk_rcd_next:
		move.l	(next,a0),d0
		bne	keepchk_rcd_loop
keepchk_rcd_error:
		movea.l	(sp)+,a1
		moveq	#-1,d0
		rts


* Data Section -------------------------------- *

*		.data
		.even

music_data_title_box:
		.dc	0,0,16*2,768-1,16,$ffff


* Block Storage Section ----------------------- *

*		.bss
		.even

human_psp::	.ds.l	1
rcd_ptr:	.ds.l	1

music_data_title_flag::
		.ds.b	1


		.end

* End of File --------------------------------- *
