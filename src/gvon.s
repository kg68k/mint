# gvon.s - &gvon, etc.
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

*──────────────────────────────────────────
*
*	This is GVON, graphic screen browser for mint.
*
*	originate by Leaza, ～1994
*	modified by Chaola, 1994
*
*	$Id: gvon.s_ 1.8 1994/07/25 09:49:52 chaola Exp $
*
*──────────────────────────────────────────


* Include File -------------------------------- *

		.include	mint.mac
		.include	message.mac
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac
		.include	gm_internal.mac


* Constant ------------------------------------ *

BITSNS:		.equ	$800

MASK_DISABLE:	.equ	%01
MASK_ENABLE:	.equ	%10

TONE_MAX:	.equ	127
TONE_NORMAL:	.equ	64
TONE_HALF:	.equ	32
TONE_MIN:	.equ	0

MODE_15KHZ_X2:	.equ	1
MODE_15KHZ_X1:	.equ	2
MODE_31KHZ_X2:	.equ	3
MODE_31KHZ_X1:	.equ	4

ZOOM_SPEED_1:	.equ	4
ZOOM_SPEED_2:	.equ	3
ZOOM_SPEED_4:	.equ	2
ZOOM_SPEED_8:	.equ	1

		.offset	0
K_NULL:		.ds	1
K_CHMD:		.ds	1
K_QZOM:		.ds	1
K_QORG:		.ds	1
K_QOFF:		.ds	1
K_MONO:		.ds	1
K_RCCW:		.ds	1
K_RCW:		.ds	1
K_HREV:		.ds	1
K_VREV:		.ds	1
K_BDEC:		.ds	1
K_BINC:		.ds	1
K_BRES:		.ds	1
K_SQU:		.ds	1
K_FREQ:		.ds	1
K_PRES:		.ds	1
K_PTOG:		.ds	1
K_ZIN:		.ds	1
K_ZOUT:		.ds	1
K_LEFT:		.ds	1
K_RIGHT:	.ds	1
K_UP:		.ds	1
K_DOWN:		.ds	1
K_T7:		.ds	1
K_T4:		.ds	1
K_T1:		.ds	1
K_T8:		.ds	1
K_T2:		.ds	1
K_T9:		.ds	1
K_T6:		.ds	1
K_T3:		.ds	1
K_EXEC:		.ds	1			;>GVON_X(マウスクリック)


* Macro --------------------------------------- *

HRL_ON:		.macro
		move.b	#%1010,(SYS_P4)
		.endm
HRL_OFF:	.macro
		move.b	#%1000,(SYS_P4)
		.endm


* Global Symbol ------------------------------- *

* look.s
		.xref	iocs_key_flush_cond_kill
* madoka3.s
		.xref	＠buildin,＠status
		.xref	execute_quick_no,free_token_buf
* mint.s
		.xref	＆clear_and_redraw,clear_tvram
* outside.s
		.xref	＆palet0_system,＆palet0_set
		.xref	atoi_a0


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* @gvon 解析 ---------------------------------- *

skip_token_tab:
		moveq	#TAB,d0
@@:		cmp.b	(a0)+,d0		;トークンを飛ばす
		bne	@b
@@:		cmp.b	(a0)+,d0		;後の TAB を飛ばす
		beq	@b
		subq.l	#1,a0
		rts

bind_entry:
		bsr	skip_token_tab		;"bind	" を飛ばす

		lea	(key_token,pc),a2
		bsr	_match_token
		move.l	d0,d5
		bmi	next_line

		bsr	skip_token_tab		;"key	" を飛ばす
		cmpi.b	#'&',(a0)+
		beq	@f
		subq.l	#1,a0
@@:
		lea	(bind_token,pc),a2
		bsr	_match_token
		tst.l	d0
		bmi	next_line

		lea	(key_table,pc),a1
		add.b	d0,d0			;先に二倍しておく
		move.b	d0,(a1,d5.w)
next_line:
		move.b	(a0)+,d0
		cmpi.b	#EOF,d0
		beq	conf_end
		cmpi.b	#LF,d0
		bne	next_line
analyze_@gvon_section::
		move.b	(a0)+,d0
		cmpi.b	#'b',d0
		beq	bind_entry
		cmpi.b	#'#',d0
		beq	next_line
		cmpi.b	#LF,d0
		beq	analyze_@gvon_section
		cmpi.b	#CR,d0
		beq	next_line
conf_end:
		rts


* トークン検索 -------------------------------- *

_match_token::
		moveq	#-1,d0
match_token_loop:
		movea.l	a0,a1
		addq.l	#1,d0
@@:
		move.b	(a2)+,d1
		beq	match_token_found
		cmp.b	(a1)+,d1
		beq	@b
@@:
		tst.b	(a2)+			;次のトークンに進める
		bne	@b
		tst.b	(a2)
		bne	match_token_loop
match_token_error:
		moveq	#-1,d0
		rts
match_token_found:
		cmpi.b	#$20,(a1)+
		bhi	match_token_error
		rts


* キー入力 ------------------------------------ *
* out	d0.w	機能番号

keyinp:
		PUSH	d1-d2/a0-a1

		IOCS	_B_KEYSNS
		tst.l	d0
		beq	keyinp_no_input
		IOCS	_B_KEYINP
		lsr	#8,d0
		cmpi	#$6c,d0
		bhi	keyinp_no_input

		move.b	d0,d1
		lea	(key_table,pc),a0
		move.b	(a0,d0.w),d0
		beq	keyinp_no_input

		lea	(auto_repeat_key_table,pc),a0
@@:		move.b	(a0)+,d2
		beq	keyinp_end
		addq.l	#1,a0
		cmp.b	d0,d2
		bne	@b

		move.b	d1,-(a0)		;リピートして良いキーのコードを保存
		bra	keyinp_end
keyinp_no_input:
		IOCS	_MS_GETDT
		tst	d0
		beq	@f

		moveq	#K_EXEC,d0
		bra	keyinp_end
@@:
		lea	(auto_repeat_key_table,pc),a0
		lea	(BITSNS),a1
		moveq	#0,d1
@@:
		move.b	(a0)+,d0
		beq	keyinp_end
		move.b	(a0)+,d1
		beq	@b
		moveq	#%111,d2
		and.b	d1,d2			;ビット位置
		lsr.b	#3,d1			;バイト位置
		btst	d2,(a1,d1.w)
		beq	@b
keyinp_end:
		POP	d1-d2/a0-a1
		rts


init_auto_repeat_key_table:
		move.l	a0,-(sp)
		lea	(auto_repeat_key_table+1,pc),a0
@@:		clr.b	(a0)+
		tst.b	(a0)+
		bne	@b
		movea.l	(sp)+,a0
		rts


auto_repeat_key_table:
.if 0
		.dc.b	K_BDEC	,0
		.dc.b	K_BINC	,0
.endif
scroll_key_table:
		.dc.b	K_LEFT	,0
		.dc.b	K_RIGHT	,0
		.dc.b	K_UP	,0
		.dc.b	K_DOWN	,0
		.dc.b	0
		.even


*************************************************
*		&gvon=&gvram-on			*
*************************************************

gvon_prepare:
		move.l	#14<<16+3,-(sp)		;ファンクションキー行非表示
		DOS	_CONCTRL
		addq.l	#4,sp
		bra	init_auto_repeat_key_table
**		rts

＆gvon::
＆gvram_on::
		bsr	check_gusemd_and_abort
		bsr	gvon_prepare

		bsr	gvon_sub
gvon_end:
		jsr	(iocs_key_flush_cond_kill)
		jmp	(＆clear_and_redraw)
**		rts

gvon_sub:
		TO_SUPER
		lea	(CRTC_R20),a0
		andi	#$07ff,(a0)			;余計なビットをマスク
		move	#$06e4,(VC_R1-CRTC_R20,a0)	;プライオリティ通常
		move	#G_ON,(VC_R2-CRTC_R20,a0)	;text off / graphic on
		clr	(TEXT_PAL-CRTC_R20,a0)		;テキスト(＄col0)透明
		HRL_OFF					;HRLクリア

		move	#ZOOM_SPEED_1,(wait_zoom)	;速度調整用

		lea	(gvon_color,pc),a1
		move	(a1),d0
		bpl	@f
		move	(VC_R0-CRTC_R20,a0),d0
@@:		andi	#3,d0
		move	d0,(a1)
		beq	gvon_16_start
		subq	#1,d0
		beq	gvon_256_start
		bra	gvon_68k_start


* 65536 色 ------------------------------------ *

* コマンドオプション -g8 からの呼び出し
gvon_64k_usr::
		bsr	gvon_prepare
		TO_SUPER
gvon_68k_start:
		bsr	call_clear_tvram
		bsr	set_gtone_64k_max_normal

		st	(HighCol)
		move	#3,(gvon_color)
		bra	gm_31kHz_等倍_pos_init


* 256 色 -------------------------------------- *

* コマンドオプション -g4 からの呼び出し
gvon_256_usr::
		bsr	gvon_prepare
		TO_SUPER
		bsr	save_paltbl
gvon_256_start:
		bsr	load_paltbl

		move	#ZOOM_SPEED_1,(wait_zoom)
		clr.l	(graph_home)
		bsr	call_clear_tvram

		clr.b	(HighCol)
		move	#1,(gvon_color)
		bra	gm_31kHz_等倍_pos_init


* 256/65536 色共通 ---------------------------- *

gm6_nop:
		DOS	_CHANGE_PR
gm6_toggle_position:
gm6_loop:
		lea	(wait_remain,pc),a0
		clr	(a0)
gm6_loop_scroll:
		bsr	keyinp
		move	(gm6_job_table,pc,d0.w),d0
		moveq	#0,d3
		moveq	#0,d4
		jmp	(gm6_job_table,pc,d0.w)
gm6_job_table:
@@:		.dc	gm6_nop-@b
		.dc	gm6_change_mode-@b
		.dc	gm6_quit_zoom-@b
		.dc	gm6_quit_orig-@b
		.dc	gm6_quit_off-@b
		.dc	gm6_mono-@b
		.dc	gm6_rotate_ccw-@b
		.dc	gm6_rotate_cw-@b
		.dc	gm6_turn_left_right-@b
		.dc	gm6_turn_up_down-@b
		.dc	gm6_tone_dec-@b
		.dc	gm6_tone_inc-@b
		.dc	gm6_tone_reset-@b
		.dc	gm6_toggle_square-@b
		.dc	gm6_toggle_freq-@b
		.dc	gm6_reset_position-@b
		.dc	gm6_toggle_position-@b
		.dc	gm6_zoom_in-@b
		.dc	gm6_zoom_out-@b
		.dc	gm6_scroll_left-@b
		.dc	gm6_scroll_right-@b
		.dc	gm6_scroll_up-@b
		.dc	gm6_scroll_down-@b
		.dc	gm6_shift7-@b
		.dc	gm6_shift4-@b
		.dc	gm6_shift1-@b
		.dc	gm6_shift8-@b
		.dc	gm6_shift2-@b
		.dc	gm6_shift9-@b
		.dc	gm6_shift6-@b
		.dc	gm6_shift3-@b
		.dc	gm6_gvon_x-@b

gm6_change_mode:
		move.b	(HighCol,pc),d0
		bne	gvon_16_start		;64K -> 16
		bra	gvon_68k_start		;256 -> 64K

gm6_quit_zoom:
		cmpi	#1,(＄gmd2)
		beq	_off_g_end		;1=非表示

		btst	#0,(mode_flag,pc)
		beq	@f
		bsr	_snap_64k_zoom_x2
@@:		tst	(＄gmd2)
		beq	on_g_end		;0=全輝度
gm6_quit_orig:
		bra	tone_down_64k_256	;2=半輝度

_off_g_end:
gm6_quit_off:
		bsr	mioff_sub
		bsr	_64k_exit_init
		bra	g_end

gm6_mono:
		move.b	(HighCol,pc),d0
		bne	@f
		bsr	gvram_to_mono_256
		bra	gm6_loop
@@:		bsr	gvram_to_mono_64k
		bra	gm6_loop

gm6_rotate_ccw:
		bsr	rotate_gvram_ccw_64k
		bra	gm6_loop
gm6_rotate_cw:
		bsr	rotate_gvram_cw_64k
		bra	gm6_loop

gm6_turn_left_right:
		bsr	turn_gvram_lr_64k
		bra	gm6_loop
gm6_turn_up_down:
		bsr	turn_gvram_ud_64k
		bra	gm6_loop

gm6_tone_dec:
		bsr	tone_64k_256_down
		bra	gm6_loop
gm6_tone_inc:
		bsr	tone_64k_256_up
		bra	gm6_loop
gm6_tone_reset:
		bsr	tone_64k_256_normal
		bra	gm6_loop

tone_64k_256_down:
		lea	(GTONE,pc),a0
		tst	(a0)
		beq	tone_64k_256_end
		subq	#1,(a0)
		bra	@f
tone_64k_256_up:
		lea	(GTONE,pc),a0
		cmpi	#TONE_MAX,(a0)
		beq	tone_64k_256_end
		addq	#1,(a0)
		bra	@f
tone_64k_256_normal:
		lea	(GTONE,pc),a0
		move	#TONE_NORMAL,(a0)
@@:
		move	(a0),d0
		move.b	(HighCol,pc),d4
		bne	set_gtone_64k

		move	d0,d4
		bra	gtone_set256
tone_64k_256_end:
		rts

gm6_toggle_square:
		lea	(sq64k,pc),a0
		not.b	(a0)
		move.b	(mode_flag,pc),d0
		cmpi.b	#MODE_15KHZ_X2,d0
		beq	gm_15kHz_2倍
		cmpi.b	#MODE_15KHZ_X1,d0
		beq	gm_15kHz_等倍
		cmpi.b	#MODE_31KHZ_X2,d0
		beq	gm_31kHz_2倍
*		cmpi.b	#MODE_31KHZ_X1,d0
		bra	gm_31kHz_等倍

gm6_toggle_freq:
		move.b	(mode_flag,pc),d0
		cmpi.b	#MODE_15KHZ_X2,d0
		beq	gm_31kHz_2倍
		cmpi.b	#MODE_15KHZ_X1,d0
		beq	gm_31kHz_等倍
		cmpi.b	#MODE_31KHZ_X2,d0
		beq	gm_15kHz_2倍
*		cmpi.b	#MODE_31KHZ_X1,d0
		bra	gm_15kHz_等倍

gm6_reset_position:
		moveq	#0,d0
		move.b	(sq64k,pc),d1
		beq	@f
		move	#384,d0
@@:		lea	(graph_home,pc),a0
		move.l	d0,(a0)
		bsr	set_graph_home
		bra	gm6_loop

gm6_zoom_in:
		move.b	(mode_flag,pc),d0
		cmpi.b	#MODE_15KHZ_X2,d0
		beq	zoom2_2倍_to_4倍
		cmpi.b	#MODE_15KHZ_X1,d0
		beq	gm_15kHz_2倍_pos_init
		cmpi.b	#MODE_31KHZ_X2,d0
		beq	zoom2_2倍_to_4倍
**		cmpi.b	#MODE_31KHZ_X1,d0
		bra	gm_31kHz_2倍_pos_init

gm6_zoom_out:
		move.b	(mode_flag,pc),d0
		cmpi.b	#MODE_15KHZ_X2,d0
		beq	gm_15kHz_等倍_pos_init
		cmpi.b	#MODE_15KHZ_X1,d0
		beq	zoom2_1倍_to_8倍
		cmpi.b	#MODE_31KHZ_X2,d0
		beq	gm_31kHz_等倍_pos_init
**		cmpi.b	#MODE_31KHZ_X1,d0
		bra	zoom2_1倍_to_8倍

gm6_scroll_left:
gm6_scroll_right:
gm6_scroll_up:
gm6_scroll_down:
		bsr	do_scroll_sub
		beq	gm6_loop
		st	-(sp)
		bra	gm6_1dot_scroll

gm6_shift7:	moveq	#-1,d3
		bra	gm6_shift4
gm6_shift4:	moveq	#-1,d4
		bra	@f
gm6_shift1:	moveq	#+1,d3
		bra	gm6_shift4
gm6_shift8:	moveq	#-1,d3
		bra	@f
gm6_shift2:	moveq	#+1,d3
		bra	@f
gm6_shift9:	moveq	#-1,d3
		bra	gm6_shift6
gm6_shift6:	moveq	#+1,d4
		bra	@f
gm6_shift3:	moveq	#+1,d3
		bra	gm6_shift6
@@:		sf	-(sp)
gm6_1dot_scroll:
		move.b	(mode_flag,pc),d0	;等倍モードはスクロールなし
		cmpi.b	#MODE_15KHZ_X1,d0
		beq	1f
		cmpi.b	#MODE_31KHZ_X1,d0
		bne	@f
1:		tst.b	(sp)+
		bra	gm6_loop
@@:
		lea	(home_y,pc),a0
		moveq	#0,d0			;y--の上端
		tst	d3
		bmi	@f
		move	#512-256,d0		;y++の下端
@@:		cmp	(a0),d0
		beq	@f			;既に端にいる
		add	d3,(a0)
@@:
		addq	#home_x-home_y,a0
		moveq	#0,d0			;x--の左端
		tst	d4
		bmi	@f
		move	#512-256,d0		;x++の右端
		move.b	(sq64k,pc),d1
		beq	@f
*		move	#512-384,d0
		lsr	#1,d0
@@:		cmp	(a0),d0
		beq	@f			;既に端にいる
		add	d4,(a0)
@@:
		tst.b	(sp)+
		beq	@f
		bsr	wait_sub
@@:		bsr	set_graph_home
		bra	gm6_loop_scroll

do_scroll_sub:
		lea	(scroll_key_table,pc),a0
		lea	(BITSNS),a1
		moveq	#0,d1

		bsr	gm6_scroll_keysns
		beq	@f
		subq	#1,d4			;left
@@:		bsr	gm6_scroll_keysns
		beq	@f
		addq	#1,d4			;right
@@:		bsr	gm6_scroll_keysns
		beq	@f
		subq	#1,d3			;up
@@:		bsr	gm6_scroll_keysns
		beq	@f
		addq	#1,d3			;down
@@:
		move	d3,d0
		or	d4,d0
		rts

gm6_scroll_keysns:
		addq.l	#1,a0
		move.b	(a0)+,d1
		beq	@f
		moveq	#%111,d2
		and.b	d1,d2			;ビット位置
		lsr.b	#3,d1			;バイト位置
		btst	d2,(a1,d1.w)
@@:		rts


gm6z8_gvon_x:	bsr	gm6z8_zoom_out_sub
gm6z4_gvon_x:	bsr	gm6z4_zoom_out_sub
		bra	@f
gm16z8_gvon_x:	bsr	gm16z8_zoom_out_sub
gm16z4_gvon_x:	bsr	gm16z4_zoom_out_sub
@@:		bsr	clr_text_buffer
gm6_gvon_x:
gm16_gvon_x:	moveq	#0,d0
		bsr	set_crt_mode_nc
		move	#T_ON+G_ON,(VC_R2)
		TO_USER

		move	#KQ_GVON_X<<8,d0
		jsr	(free_token_buf)
		jmp	(execute_quick_no)
**		rts


* ズーム用座標チェック ------------------------ *

zoom2_check_pos:
		move	(offset_x,pc),d0
		bpl	1f
		moveq	#0,d0
		bra	@f
1:		cmp	(offset_max_x,pc),d0
		ble	@f
		move	(offset_max_x,pc),d0
@@:		move	d0,(offset_x)

		move	(offset_y,pc),d0
		bpl	1f
		moveq	#0,d0
		bra	@f
1:		cmp	(offset_max_y,pc),d0
		ble	@f
		move	(offset_max_y,pc),d0
@@:		move	d0,(offset_y)

		rts

* ズーム時 CRT モード変更 --------------------- *

zoom2_toggle_freq:
		not.b	(Hfreq_low)
		bra	zoom2_set_crt

zoom2_toggle_square:
		not.b	(sq64k)
		bra	zoom2_set_crt

zoom2_set_crt:
		moveq	#6,d0			;31kHz,256x256
		move.b	(sq64k,pc),d1
		beq	@f
		moveq	#4,d0			;31kHz,384x256
@@:
		move.b	(Hfreq_low,pc),d1
		beq	@f
		addq	#1,d0			;15kHz
@@:
		bra	set_crt_mode_nc
**		rts


* ４倍ズーム ---------------------------------- *

zoom2_2倍_to_4倍:
		bsr	_vdisp_wait
		clr	(VC_R2)
		bsr	zoom2_gram_to_text
		moveq	#64,d0
		add	(home_x,pc),d0
		andi	#511,d0
		move	d0,(offset_x)
		moveq	#64,d0
		add	(home_y,pc),d0
		andi	#511,d0
		move	d0,(offset_y)
zoom2_4倍mode:
		move.b	#4,(zoom_factor)
		move	#ZOOM_SPEED_4,(wait_zoom)
		clr.l	(graph_home)
		move	#512-512/4,(offset_max_y)
		move	#512-512/4,(offset_max_x)
		move	#256,(zoom_width)
		move	#256,(zoom_rest)
		move	#(256-2)*2,(offs_right_pl)
		move	#-(256+2)*2,(offs_right_mi)
		move	#128-1,(zoom_w2)
		move	#64,(zoom_w1)

		move.b	(sq64k,pc),d0
		beq	@f

		move	#512-768/4,(offset_max_x)
		move	#384,(zoom_width)
		move	#128,(zoom_rest)
		move	#(384-2)*2,(offs_right_pl)
		move	#-(128+2)*2,(offs_right_mi)
		move	#192-1,(zoom_w2)
		move	#96,(zoom_w1)
@@:
		bsr	zoom2_check_pos
		bsr	zoom2_4_flush_screen
		bsr	_vdisp_wait
		move	#G_ON,(VC_R2)
		moveq	#0,d3

		bsr	set_graph_home
		bra	gm6z4_loop

gm6z4_nop:
		DOS	_CHANGE_PR
gm6z4_change_mode:
gm6z4_mono:
gm6z4_rotate_ccw:
gm6z4_rotate_cw:
gm6z4_turn_left_right:
gm6z4_turn_up_down:
gm6z4_reset_position:
gm6z4_toggle_position:

gm6z4_loop:
		lea	(wait_remain,pc),a0
		clr	(a0)
gm6z4_loop_scroll:
		bsr	keyinp
		move	(gm6z4_job_table,pc,d0.w),d0
		moveq	#0,d3
		moveq	#0,d4
		jmp	(gm6z4_job_table,pc,d0.w)
gm6z4_job_table:
@@:		.dc	gm6z4_nop-@b
		.dc	gm6z4_change_mode-@b
		.dc	gm6z4_quit_zoom-@b
		.dc	gm6z4_quit_orig-@b
		.dc	gm6z4_quit_off-@b
		.dc	gm6z4_mono-@b
		.dc	gm6z4_rotate_ccw-@b
		.dc	gm6z4_rotate_cw-@b
		.dc	gm6z4_turn_left_right-@b
		.dc	gm6z4_turn_up_down-@b
		.dc	gm6z4_tone_dec-@b
		.dc	gm6z4_tone_inc-@b
		.dc	gm6z4_tone_reset-@b
		.dc	gm6z4_toggle_square-@b
		.dc	gm6z4_toggle_freq-@b
		.dc	gm6z4_reset_position-@b
		.dc	gm6z4_toggle_position-@b
		.dc	gm6z4_zoom_in-@b
		.dc	gm6z4_zoom_out-@b
		.dc	gm6z4_scroll_left-@b
		.dc	gm6z4_scroll_right-@b
		.dc	gm6z4_scroll_up-@b
		.dc	gm6z4_scroll_down-@b
		.dc	gm6z4_shift7-@b
		.dc	gm6z4_shift4-@b
		.dc	gm6z4_shift1-@b
		.dc	gm6z4_shift8-@b
		.dc	gm6z4_shift2-@b
		.dc	gm6z4_shift9-@b
		.dc	gm6z4_shift6-@b
		.dc	gm6z4_shift3-@b
		.dc	gm6z4_gvon_x-@b

gm6z4_quit_zoom:
		cmpi	#1,(＄gmd2)
		beq	zoom2_off_end

		bsr	snap_64k_zoom_x4
		cmpi	#2,(＄gmd2)
		bne	on_g_end
		bra	tone_down_64k_256
gm6z4_quit_orig:
		bsr	zoom2_text_to_gram
		bra	tone_down_64k_256
gm6z4_quit_off:
gm6z8_quit_off:
zoom2_off_end:
		bsr	zoom2_exit_pre
		bra	_off_g_end

gm6z4_tone_dec:
		bsr	tone_64k_256_down
		bra	gm6z4_loop
gm6z4_tone_inc:
		bsr	tone_64k_256_up
		bra	gm6z4_loop
gm6z4_tone_reset:
		bsr	tone_64k_256_normal
		bra	gm6z4_loop

gm6z4_toggle_square:
		bsr	zoom2_toggle_square
		bra	zoom2_4倍mode
gm6z4_toggle_freq:
		bsr	zoom2_toggle_freq
 		bra	gm6z4_loop

gm6z4_zoom_in:
		lea	(zoom_offset,pc),a0
		addi	#(128-64)/2,(a0)+	;offset_y
		addi	#(128-64)/2,(a0)+	;offset_x
		bra	zoom2_8倍mode
gm6z4_zoom_out:
		bsr	gm6z4_zoom_out_sub
		move.b	(Hfreq_low,pc),d0
		bne	gm_15kHz_2倍
		bra	gm_31kHz_2倍
gm6z4_zoom_out_sub:
		lea	(zoom_offset,pc),a0
		lea	(graph_home,pc),a1
		moveq	#-(256-128)/2,d0
		add	(a0)+,d0		;offset_y
		move	d0,(a1)+		;home_y
		moveq	#-(256-128)/2,d0
		add	(a0)+,d0		;offset_x
		move	d0,(a1)+		;home_x
		bra	zoom2_exit_pre
**		rts

gm6z4_scroll_left:
gm6z4_scroll_right:
gm6z4_scroll_up:
gm6z4_scroll_down:
		bsr	do_scroll_sub
		beq	gm6z4_loop
		st	-(sp)
		bra	gm6z4_1dot_scroll

gm6z4_shift7:	moveq	#-1,d3
		bra	gm6z4_shift4
gm6z4_shift4:	moveq	#-1,d4
		bra	@f
gm6z4_shift1:	moveq	#+1,d3
		bra	gm6z4_shift4
gm6z4_shift8:	moveq	#-1,d3
		bra	@f
gm6z4_shift2:	moveq	#+1,d3
		bra	@f
gm6z4_shift9:	moveq	#-1,d3
		bra	gm6z4_shift6
gm6z4_shift6:	moveq	#+1,d4
		bra	@f
gm6z4_shift3:	moveq	#+1,d3
		bra	gm6z4_shift6
@@:		sf	-(sp)
gm6z4_1dot_scroll:
		move	d4,-(sp)
		tst	d3
		beq	@f
		bpl	1f
		bsr	gm6z4_1dot_up
		bra	@f
1:		bsr	gm6z4_1dot_down
@@:
		tst	(sp)+
		beq	@f
		bpl	1f
		bsr	gm6z4_1dot_left
		bra	@f
1:		bsr	gm6z4_1dot_right
@@:
		tst.b	(sp)+
		beq	@f
		bsr	wait_sub
@@:		bsr	set_graph_home
		bra	gm6z4_loop_scroll

gm6z4_1dot_up:
		lea	(offset_y,pc),a0
		tst	(a0)
		beq	gm6z4_1dot_ud_end

		subq	#1,(a0)
		moveq	#-2,d0
		bsr	gm6z4_scroll_updown_sub
		movea.l	a1,a0			;上端を書き換える
		movea.l	a3,a2			;
		bra	gm6z4_1dot_ud
gm6z4_1dot_down:
		lea	(offset_y,pc),a0
		move	(offset_max_y,pc),d0
		cmp	(a0),d0
		beq	gm6z4_1dot_ud_end

		addq	#1,(a0)
		moveq	#+2,d0
		bsr	gm6z4_scroll_updown_sub
		movea.l	a1,a0
		adda.l	#512*2*127,a0		;下端を書き換える
		lea	(a3,d4.l),a2		;
gm6z4_1dot_ud:
@@:		move.l	(a0),d0
		move	(a0)+,d0
		move.l	d0,(512*2,a2)		;(x,y+1),(x+1,y+1)
		move.l	d0,(a2)+		;(x,y)	,(x+1,y)
		dbra	d6,@b

		tst	d7
		bmi	gm6z4_1dot_ud_end
		lea	(-512*2,a2),a2
@@:
		move.l	(a0),d0
		move	(a0)+,d0
		move.l	d0,(512*2,a2)
		move.l	d0,(a2)+
		dbra	d7,@b
gm6z4_1dot_ud_end:
		rts

gm6z4_1dot_left:
		lea	(offset_x,pc),a0
		tst	(a0)
		beq	gm6z4_1dot_lr_end

		subq	#1,(a0)
		moveq	#-2,d0
		bsr	gm6z4_scroll_leftright_sub
		movea.l	a1,a0			;左端を書き換える
		movea.l	a3,a2			;
		bra	gm6z4_1dot_lr
gm6z4_1dot_right:
		lea	(offset_x,pc),a0
		move	(offset_max_x,pc),d0
		cmp	(a0),d0
		beq	gm6z4_1dot_lr_end

		addq	#1,(a0)
		moveq	#+2,d0
		bsr	gm6z4_scroll_leftright_sub
		move	(offs_right_pl,pc),d5
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest
		move	(offs_right_mi,pc),d5
@@:
		move	(zoom_w2,pc),d0
		add	d0,d0
		lea	(a1,d0.w),a0		;右端を書き換える
		lea	(a3,d5.w),a2		;
gm6z4_1dot_lr:
@@:		move.l	(a0),d0
		move	(a0),d0
		move.l	d0,(512*2,a2)		;(x,Y+1),(x+1,y+1)
		move.l	d0,(a2)			;(x,y)	,(x+1,y)
		lea	(512*2,a0),a0
		lea	(512*4,a2),a2
		dbra	d6,@b

		tst	d7
		bmi	gm6z4_1dot_lr_end
		suba.l	#512*2*512,a2
@@:
		move.l	(a0),d0
		move	(a0),d0
		move.l	d0,(512*2,a2)
		move.l	d0,(a2)
		lea	(512*2,a0),a0
		lea	(512*4,a2),a2
		dbra	d7,@b
gm6z4_1dot_lr_end:
		rts

gm6z4_scroll_updown_sub:
		lea	(home_y,pc),a0
		add	d0,(a0)
		andi	#512-1,(a0)

		bsr	gm6z4_scroll_sub
		move	(zoom_w2,pc),d6
		moveq	#-1,d7
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest

		sub	(zoom_rest,pc),d0
		asr	#1,d0
		move	d0,d7
		sub	d0,d6			;d6 = zoom_w2-(x-zoom_rest)/2
		subq	#1,d7			;d7 = (x-zoom_rest)/2-1
@@:
		move.l	#512*2*(256-2),d4	;d4 = offset to bottom
		move	(home_y,pc),d0
		cmpi	#256,d0
		bls	@f			;y≦256
		subi.l	#512*2*512,d4
@@:		rts

gm6z4_scroll_leftright_sub:
		lea	(home_x,pc),a0
		add	d0,(a0)
		andi	#512-1,(a0)

		bsr	gm6z4_scroll_sub
	 	moveq	#128-1,d6		;d6 = upper regeon loop
		moveq	#-1,d7			;d7 = division flag

		move	(home_y,pc),d0
		cmpi	#256,d0
		bls	@f			;y≦256

		subi	#256,d0
		asr	#1,d0			;4倍(2dot)ズームだから1/2
		move	d0,d7
		sub	d0,d6			;d6 = (128-(y-256)/2)-1
		subq	#1,d7			;d7 = (y-256)/2-1
@@:		rts

gm6z4_scroll_sub:
		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		movea.l	a0,a1			;a1 = src. top

		move.l	(graph_home,pc),d0
		lea	(GVRAM),a0
		bsr	zoom2_adr_set
		movea.l	a0,a3			;a3 = dst. top
		rts


* ４倍ズーム拡大描画 -------------------------- *

zoom2_4_flush_screen:
		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		lea	(512*2*1,a0),a1
		lea	(GVRAM),a2
		lea	(512*2*1,a2),a3
		lea	(512*2*2,a2),a4
		lea	(512*2*3,a2),a5

		move	(zoom_width,pc),d0
		move.l	#512*2*2,d4
		sub	d0,d4
		move.l	#512*2*4,d5
		add	d0,d0
		sub	d0,d5

		moveq	#64-1,d3
zoom2_4_flush_y_loop:
		move	(zoom_w1,pc),d2
		subq	#1,d2
zoom2_4_flush_x_loop:
		move.l	(a0)+,d6
		move.l	d6,d0
		move.l	d6,d1
		swap	d1
		move	d1,d0
		move	d6,d1
		move.l	d0,(a2)+
		move.l	d1,(a2)+
		move.l	d0,(a3)+
		move.l	d1,(a3)+

		move.l	(a1)+,d6
		move.l	d6,d0
		move.l	d6,d1
		swap	d1
		move	d1,d0
		move	d6,d1
		move.l	d0,(a4)+
		move.l	d1,(a4)+
		move.l	d0,(a5)+
		move.l	d1,(a5)+
		dbra	d2,zoom2_4_flush_x_loop

		adda.l	d4,a0
		adda.l	d4,a1
		adda.l	d5,a2
		adda.l	d5,a3
		adda.l	d5,a4
		adda.l	d5,a5
		dbra	d3,zoom2_4_flush_y_loop
		rts


* ８倍ズーム ---------------------------------- *

zoom2_1倍_to_8倍:
		bsr	_vdisp_wait
		clr	(VC_R2)
		bsr	zoom2_set_crt
		bsr	zoom2_gram_to_text
zoom2_8倍mode:
		move.b	#8,(zoom_factor)
		move	#ZOOM_SPEED_8,(wait_zoom)
		clr.l	(graph_home)
		move	#512-512/8,(offset_max_y)
		move	#512-512/8,(offset_max_x)
		move	#256,(zoom_width)
		move	#256,(zoom_rest)
		move	#(256-4)*2,(offs_right_pl)
		move	#-(256+4)*2,(offs_right_mi)
		move	#64-1,(zoom_w2)
		move	#32,(zoom_w1)

		move.b	(sq64k,pc),d0
		beq	@f

		move	#512-768/8,(offset_max_x)
		move	#384,(zoom_width)
		move	#128,(zoom_rest)
		move	#(384-4)*2,(offs_right_pl)
		move	#-(128+4)*2,(offs_right_mi)
		move	#96-1,(zoom_w2)
		move	#48,(zoom_w1)
@@:
		bsr	zoom2_check_pos
		bsr	zoom2_8_flush_screen
		bsr	_vdisp_wait
		move	#G_ON,(VC_R2)
		moveq	#0,d3

		bsr	set_graph_home
		bra	gm6z8_loop

gm6z8_nop:
		DOS	_CHANGE_PR
gm6z8_change_mode:
gm6z8_mono:
gm6z8_rotate_ccw:
gm6z8_rotate_cw:
gm6z8_turn_left_right:
gm6z8_turn_up_down:
gm6z8_reset_position:
gm6z8_toggle_position:

gm6z8_loop:
		lea	(wait_remain,pc),a0
		clr	(a0)
gm6z8_loop_scroll:
		bsr	keyinp
		move	(gm6z8_job_table,pc,d0.w),d0
		moveq	#0,d3
		moveq	#0,d4
		jmp	(gm6z8_job_table,pc,d0.w)
gm6z8_job_table:
@@:		.dc	gm6z8_nop-@b
		.dc	gm6z8_change_mode-@b
		.dc	gm6z8_quit_zoom-@b
		.dc	gm6z8_quit_orig-@b
		.dc	gm6z8_quit_off-@b
		.dc	gm6z8_mono-@b
		.dc	gm6z8_rotate_ccw-@b
		.dc	gm6z8_rotate_cw-@b
		.dc	gm6z8_turn_left_right-@b
		.dc	gm6z8_turn_up_down-@b
		.dc	gm6z8_tone_dec-@b
		.dc	gm6z8_tone_inc-@b
		.dc	gm6z8_tone_reset-@b
		.dc	gm6z8_toggle_square-@b
		.dc	gm6z8_toggle_freq-@b
		.dc	gm6z8_reset_position-@b
		.dc	gm6z8_toggle_position-@b
		.dc	gm6z8_zoom_in-@b
		.dc	gm6z8_zoom_out-@b
		.dc	gm6z8_scroll_left-@b
		.dc	gm6z8_scroll_right-@b
		.dc	gm6z8_scroll_up-@b
		.dc	gm6z8_scroll_down-@b
		.dc	gm6z8_shift7-@b
		.dc	gm6z8_shift4-@b
		.dc	gm6z8_shift1-@b
		.dc	gm6z8_shift8-@b
		.dc	gm6z8_shift2-@b
		.dc	gm6z8_shift9-@b
		.dc	gm6z8_shift6-@b
		.dc	gm6z8_shift3-@b
		.dc	gm6z8_gvon_x-@b

gm6z8_quit_zoom:
		cmpi	#1,(＄gmd2)
		beq	zoom2_off_end

		bsr	snap_64k_zoom_x8
		cmpi	#2,(＄gmd2)
		bne	on_g_end
		bra	tone_down_64k_256
gm6z8_quit_orig:
		bsr	zoom2_text_to_gram
		bra	tone_down_64k_256

gm6z8_tone_dec:
		bsr	tone_64k_256_down
		bra	gm6z8_loop
gm6z8_tone_inc:
		bsr	tone_64k_256_up
		bra	gm6z8_loop
gm6z8_tone_reset:
		bsr	tone_64k_256_normal
		bra	gm6z8_loop

gm6z8_toggle_square:
		bsr	zoom2_toggle_square
		bra	zoom2_8倍mode
gm6z8_toggle_freq:
		bsr	zoom2_toggle_freq
		bra	gm6z8_loop

gm6z8_zoom_in:
		clr	(VC_R2)
		bsr	zoom2_exit_pre
		move.b	(Hfreq_low,pc),d0
		bne	gm_15kHz_等倍_pos_init
		bra	gm_31kHz_等倍_pos_init
gm6z8_zoom_out:
		bsr	gm6z8_zoom_out_sub
		bra	zoom2_4倍mode
gm6z8_zoom_out_sub:
		lea	(zoom_offset,pc),a0
		subi	#(128-64)/2,(a0)+
		subi	#(128-64)/2,(a0)+
		rts

gm6z8_scroll_left:
gm6z8_scroll_right:
gm6z8_scroll_up:
gm6z8_scroll_down:
		bsr	do_scroll_sub
		beq	gm6z8_loop
		st	-(sp)
		bra	gm6z8_1dot_scroll

gm6z8_shift7:	moveq	#-1,d3
		bra	gm6z8_shift4
gm6z8_shift4:	moveq	#-1,d4
		bra	@f
gm6z8_shift1:	moveq	#+1,d3
		bra	gm6z8_shift4
gm6z8_shift8:	moveq	#-1,d3
		bra	@f
gm6z8_shift2:	moveq	#+1,d3
		bra	@f
gm6z8_shift9:	moveq	#-1,d3
		bra	gm6z8_shift6
gm6z8_shift6:	moveq	#+1,d4
		bra	@f
gm6z8_shift3:	moveq	#+1,d3
		bra	gm6z8_shift6
@@:		sf	-(sp)
gm6z8_1dot_scroll:
		move	d4,-(sp)
		tst	d3
		beq	@f
		bpl	1f
		bsr	gm6z8_1dot_up
		bra	@f
1:		bsr	gm6z8_1dot_down
@@:
		tst	(sp)+
		beq	@f
		bpl	1f
		bsr	gm6z8_1dot_left
		bra	@f
1:		bsr	gm6z8_1dot_right
@@:
		tst.b	(sp)+
		beq	@f
		bsr	wait_sub
@@:		bsr	set_graph_home
		bra	gm6z8_loop_scroll

gm6z8_1dot_up:
		lea	(offset_y,pc),a0
		tst	(a0)
		beq	gm6z8_1dot_ud_end

		subq	#1,(a0)
		moveq	#-4,d0
		bsr	gm6z8_scroll_updown_sub
		movea.l	a1,a0			;上端を書き換える
		movea.l	a3,a2			;
		bra	gm6z8_1dot_ud
gm6z8_1dot_down:
		lea	(offset_y,pc),a0
		move	(offset_max_y,pc),d0
		cmp	(a0),d0
		beq	gm6z8_1dot_ud_end

		addq	#1,(a0)
		moveq	#+4,d0
		bsr	gm6z8_scroll_updown_sub
		movea.l	a1,a0
		adda.l	#512*2*63,a0		;下端を書き換える
		lea	(a3,d4.l),a2		;
gm6z8_1dot_ud:
@@:		move.l	(a0),d0
		move	(a0)+,d0
	.rept	2
		move.l	d0,(512*6,a2)		;(x,y+3),(x+1,y+3) (x+2,y+3),(x+3,y+3)
		move.l	d0,(512*4,a2)		;(x,y+2),(x+1,y+2) (x+2,y+2),(x+3,y+2)
		move.l	d0,(512*2,a2)		;(x,y+1),(x+1,y+1) (x+2,y+1),(x+3,y+1)
		move.l	d0,(a2)+		;(x,y)	,(x+1,y)   (x+2,y)  ,(x+3,y)
	.endm
		dbra	d6,@b

		tst	d7
		bmi	gm6z8_1dot_ud_end
		lea	(-512*2,a2),a2
@@:
		move.l	(a0),d0
		move	(a0)+,d0
	.rept	2
		move.l	d0,(512*6,a2)
		move.l	d0,(512*4,a2)
		move.l	d0,(512*2,a2)
		move.l	d0,(a2)+
	.endm
		dbra	d7,@b
gm6z8_1dot_ud_end:
		rts

gm6z8_1dot_left:
		lea	(offset_x,pc),a0
		tst	(a0)
		beq	gm6z8_1dot_lr_end

		subq	#1,(a0)
		moveq	#-4,d0
		bsr	gm6z8_scroll_leftright_sub
		movea.l	a1,a0			;左端を書き換える
		movea.l	a3,a2			;
		bra	gm6z8_1dot_lr
gm6z8_1dot_right:
		lea	(offset_x,pc),a0
		move	(offset_max_x,pc),d0
		cmp	(a0),d0
		beq	gm6z8_1dot_lr_end

		addq	#1,(a0)
		moveq	#+4,d0
		bsr	gm6z8_scroll_leftright_sub
		move	(offs_right_pl,pc),d5
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest
		move	(offs_right_mi,pc),d5
@@:
		move	(zoom_w2,pc),d0
		add	d0,d0
		lea	(a1,d0.w),a0		;右端を書き換える
		lea	(a3,d5.w),a2		;
gm6z8_1dot_lr:
@@:		move.l	(a0),d0
		move	(a0),d0
	.rept	2
		move.l	d0,(512*6,a2)		;(x,y+3),(x+1,y+3) (x+2,y+3),(x+3,y+3)
		move.l	d0,(512*4,a2)		;(x,y+2),(x+1,y+2) (x+2,y+2),(x+3,y+2)
		move.l	d0,(512*2,a2)		;(x,y+1),(x+1,y+1) (x+2,y+1),(x+3,y+1)
		move.l	d0,(a2)+		;(x,y)	,(x+1,y)   (x+2,y)  ,(x+3,y)
	.endm
		lea	(512*2,a0),a0
		lea	(512*8-8,a2),a2
		dbra	d6,@b

		tst	d7
		bmi	gm6z8_1dot_lr_end
		suba.l	#512*2*512,a2
@@:
		move.l	(a0),d0
		move	(a0),d0
	.rept	2
		move.l	d0,(512*6,a2)
		move.l	d0,(512*4,a2)
		move.l	d0,(512*2,a2)
		move.l	d0,(a2)+
	.endm
		lea	(512*2,a0),a0
		lea	(512*8-8,a2),a2
		dbra	d7,@b
gm6z8_1dot_lr_end:
		rts

gm6z8_scroll_updown_sub:
		lea	(home_y,pc),a0
		add	d0,(a0)
		andi	#512-1,(a0)

		bsr	gm6z8_scroll_sub
		move	(zoom_w2,pc),d6
		moveq	#-1,d7
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f

		sub	(zoom_rest,pc),d0
		asr	#2,d0
		move	d0,d7
		sub	d0,d6			;d6 = zoom_w2-(x-zoom_rest)/4
		subq	#1,d7			;d7 = (x-zoom_rest)/4-1
@@:
		move.l	#512*2*(256-4),d4	;d4 = offset to bottom
		move	(home_y,pc),d0
		cmpi	#256,d0
		bls	@f			;y≦256
		subi.l	#512*2*512,d4
@@:		rts

gm6z8_scroll_leftright_sub:
		lea	(home_x,pc),a0
		add	d0,(a0)
		andi	#512-1,(a0)

		bsr	gm6z8_scroll_sub
		move	#63,d6			;d6 = upper regeon loop
		moveq	#-1,d7			;d7 = division flag

		move	(home_y,pc),d0
		cmpi	#256,d0
		bls	@f			;y≦256

		subi	#256,d0
		asr	#2,d0			;8倍(4dot)ズームだから1/4
		move	d0,d7
		sub	d0,d6
		subq	#1,d7
@@:		rts

gm6z8_scroll_sub:
		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		movea.l	a0,a1			;a1 = src. top

		move.l	(graph_home,pc),d0
		lea	(GVRAM),a0
		bsr	zoom2_adr_set
		movea.l	a0,a3			;a3 = dst. top
		rts


* ８倍ズーム拡大描画 -------------------------- *

zoom2_8_flush_screen:
		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		lea	(GVRAM),a1
		lea	512*2*1(a1),a2
		lea	512*2*2(a1),a3
		lea	512*2*3(a1),a4

		move.l	#512*2,d3
		move	(zoom_w2,pc),d0
		addq	#1,d0
		add	d0,d0
		sub	d0,d3
		move.l	#512*2*4,d4
		sub	(zoom_width,pc),d4
		sub	(zoom_width,pc),d4

		moveq	#64-1,d2
zoom2_8_flush_y_loop:
		move	(zoom_w2,pc),d1
zoom2_8_flush_x_loop:
		move.l	(a0),d0
		move	(a0)+,d0
	.irp	an,a1,a2,a3,a4
		move.l	d0,(an)+
		move.l	d0,(an)+
	.endm
		dbra	d1,zoom2_8_flush_x_loop

		adda.l	d3,a0
		adda.l	d4,a1
		adda.l	d4,a2
		adda.l	d4,a3
		adda.l	d4,a4
		dbra	d2,zoom2_8_flush_y_loop
		rts


* ２倍ズーム拡大終了 -------------------------- *

_snap_64k_zoom_x2:
		bsr	zoom2_gram_to_text
		clr	(VC_R2)

		move.l	(graph_home,pc),d0
		move.b	(sq64k,pc),d1
		beq	@f
		addi	#64,d0			;x += 64
@@:
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		lea	(GVRAM),a2
		lea	(512*2,a2),a3

		move.l	#256*2,d4
		move.l	#512*2,d5
		move	#256-1,d3
snap_64k_x2_y_loop:
		moveq	#128-1,d2
snap_64k_x2_x_loop:
		move.l	(a0)+,d6
		move.l	d6,d0
		move.l	d6,d1
		swap	d1
		move	d1,d0
		move	d6,d1
		move.l	d0,(a2)+
		move.l	d1,(a2)+
		move.l	d0,(a3)+
		move.l	d1,(a3)+
		dbra	d2,snap_64k_x2_x_loop

		adda.l	d4,a0
		adda.l	d5,a2
		adda.l	d5,a3
		dbra	d3,snap_64k_x2_y_loop
		rts


* ４倍ズーム拡大終了 -------------------------- *

snap_64k_zoom_x4:
		bsr	zoom2_gram_to_text
		clr	(VC_R2)

		move.l	(zoom_offset,pc),d0
		move.b	(sq64k,pc),d1
		beq	@f
		addi	#32,d0
@@:
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		lea	(GVRAM),a2
		lea	(512*2,a2),a3
		lea	(512*2*2,a2),a4
		lea	(512*2*3,a2),a5

		move.l	#384*2,d4
		move.l	#512*2*3,d5

		moveq	#128-1,d3
snap_64k_x4_y_loop:
		moveq	#64-1,d2
snap_64k_x4_x_loop:
		move.l	(a0)+,d6
		move.l	d6,d0
		move.l	d6,d1
		swap	d1
		move	d1,d0
		move	d6,d1
	.irp	an,a2,a3,a4,a5
		move.l	d0,(an)+
		move.l	d0,(an)+
		move.l	d1,(an)+
		move.l	d1,(an)+
	.endm
		dbra	d2,snap_64k_x4_x_loop

		adda.l	d4,a0
		adda.l	d5,a2
		adda.l	d5,a3
		adda.l	d5,a4
		adda.l	d5,a5
		dbra	d3,snap_64k_x4_y_loop
		rts


* ８倍ズーム拡大終了 -------------------------- *

snap_64k_zoom_x8:
		bsr	zoom2_gram_to_text
		clr	(VC_R2)

		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a0
		bsr	zoom2_adr_set
		lea	(GVRAM),a2
		lea	(512*2*2,a2),a3
		lea	(512*2*4,a2),a4
		lea	(512*2*6,a2),a5

		move.l	#448*2,d4
		move.l	#512*2*7,d5

		moveq	#64-1,d3
snap_64k_x8_y_loop:
		moveq	#64-1,d2
snap_64k_x8_x_loop:
		move	(a0),d0
		swap	d0
		move	(a0)+,d0
	.irp	an,a2,a3,a4,a5
		move.l	d0,(512*2+00,an)
		move.l	d0,(512*2+04,an)
		move.l	d0,(512*2+08,an)
		move.l	d0,(512*2+12,an)
		move.l	d0,(an)+
		move.l	d0,(an)+
		move.l	d0,(an)+
		move.l	d0,(an)+
	.endm
		dbra	d2,snap_64k_x8_x_loop

		adda.l	d4,a0
		adda.l	d5,a2
		adda.l	d5,a3
		adda.l	d5,a4
		adda.l	d5,a5
		dbra	d3,snap_64k_x8_y_loop
		rts


* ズーム終了準備 ------------------------------ *

zoom2_exit_pre:
		clr	(VC_R2)
		bsr	zoom2_text_to_gram

		moveq	#6,d0
		move.b	(Hfreq_low,pc),d1
		beq	@f
		moveq	#7,d0
@@:
		bsr	set_crt_mode_nc
		bra	set_graph_home
**		rts


* ズーム下請け -------------------------------- *

zoom2_adr_set:
		moveq	#0,d1
		move	d0,d1
		add.l	d1,d1
		move.l	d0,d2
		clr	d2
		lsr.l	#6,d2			;y*1024
		add.l	d2,d1
		adda.l	d1,a0
		rts

zoom16_adr_set:
		moveq	#0,d1
		move	d0,d1
		add.l	d1,d1
		move.l	d0,d2
		clr	d2
		lsr.l	#5,d2			;y*1024
		add.l	d2,d1
		adda.l	d1,a0
		rts


* GVRAM -> TVRAM 転送 ------------------------- *

zoom2_gram_to_text:
		tas	(buffer_avail)
		bne	zoom2_gram_to_text_end	;既にTVRAMへ転送している

		moveq	#1,d1			;テキスト画面は
		moveq	#2,d2			;アプリケーションで使用
		IOCS	_TGUSEMD
		IOCS	_MS_CUROF

		clr	(CRTC_R21)
		lea	(GVRAM),a1
		lea	(TVRAM),a2
		move	#(512*512/2/8)-1,d0
@@:
	.rept	8
		move.l	(a1)+,(a2)+
	.endm
		dbra	d0,@b
zoom2_gram_to_text_end:
		rts


* TVRAM -> GVRAM 転送 ------------------------- *

zoom2_text_to_gram:
		lea	(TVRAM),a1
		lea	(GVRAM),a2
		move	#(512*512/2/8)-1,d0
@@:
	.rept	8
		move.l	(a1)+,(a2)+
	.endm
		dbra	d0,@b

		moveq	#1,d1			;テキスト画面は
		moveq	#1,d2			;システムで使用
		IOCS	_TGUSEMD
clr_text_buffer_end:
		rts


* TVRAM クリア -------------------------------- *

clr_text_buffer:
		move.b	(buffer_avail,pc),d0
		beq	clr_text_buffer_end	;TVRAMへは転送していない

		move	(gvon_crtmode,pc),d0
		move.b	(sq_kill_table,pc,d0.w),d0
		bsr	set_crt_mode_nc
call_clear_tvram:
		clr.b	(buffer_avail)
		moveq	#1,d1			;テキスト画面は
		moveq	#1,d2			;システムで使用
		IOCS	_TGUSEMD

		moveq	#%1111,d0
		jmp	(clear_tvram)
**		rts

*			0  1  2  3  4  5  6  7  8  9  A  B
sq_kill_table:	.dc.b	0, 3, 2, 3, 4, 7, 6, 7, 0, 0, 0,11
		.even


* ズーム変更時の初期化 ------------------------ *

gm_15kHz_2倍_pos_init:
		move.l	#96<<16+96,(graph_home)
gm_15kHz_2倍:
		move.b	#MODE_15KHZ_X2,(mode_flag)
		move	#ZOOM_SPEED_2,(wait_zoom)
		st	(Hfreq_low)

		clr	(offset_min_x)
		move	#272,(offset_max_y)
		move	#256,(offset_max_x)
		moveq	#7,d0			;15kHz,256×240
		move.b	(sq64k,pc),d1
		beq	@f

		move	#128,(offset_max_x)
		moveq	#5,d0			;15kHz,384×240
@@:
		bra	gm_mc_set_mode


gm_15kHz_等倍_pos_init:
		clr.l	(graph_home)
		move.b	(sq64k,pc),d0
		beq	gm_15kHz_等倍

		move.l	#0<<16+384,(graph_home)	;x=384,y=0
gm_15kHz_等倍:
		bsr	clr_text_buffer
		move.b	#MODE_15KHZ_X1,(mode_flag)
		move	#ZOOM_SPEED_1,(wait_zoom)
		st	(Hfreq_low)

		clr	(offset_min_x)
		clr	(offset_max_x)
		move	#32,(offset_max_y)
		moveq	#3,d0			;15kHz,512×480
		move.b	(sq64k,pc),d1
		beq	gm_mc_set_mode

		moveq	#1,d0			;15kHz,768×512
		bra	gm_mc_set_sq_mode


gm_31kHz_2倍_pos_init:
		move.l	#96<<16+96,(graph_home)
gm_31kHz_2倍:
		move.b	#MODE_31KHZ_X2,(mode_flag)
		move	#ZOOM_SPEED_2,(wait_zoom)
		clr.b	(Hfreq_low)

		clr	(offset_min_x)
		move	#256,(offset_max_y)
		move	#256,(offset_max_x)
		moveq	#6,d0			;31kHz,256×256
		move.b	(sq64k,pc),d1
		beq	@f

		move	#128,(offset_max_x)
		moveq	#4,d0			;31kHz,384×256
@@:
		bra	gm_mc_set_mode


gm_31kHz_等倍_pos_init:
		clr.l	(graph_home)
		move.b	(sq64k,pc),d0
		beq	gm_31kHz_等倍

		move.l	#0<<16+384,(graph_home)	;x=384,y=0
gm_31kHz_等倍:
		bsr	clr_text_buffer
		move.b	#MODE_31KHZ_X1,(mode_flag)
		move	#ZOOM_SPEED_1,(wait_zoom)
		clr.b	(Hfreq_low)

		clr	(offset_min_x)
		clr	(offset_max_x)
		clr	(offset_max_y)
		moveq	#2,d0			;31kHz,512×512
		move.b	(sq64k,pc),d1
		beq	gm_mc_set_mode

		moveq	#0,d0			;31kHz,768×512
		bra	gm_mc_set_sq_mode

gm_mc_set_sq_mode:
		move	#384,(offset_max_x)
		move	#384,(offset_min_x)

		bsr	set_crt_mode_nc
		bsr	_gm_auto_mask
		move	#T_ON+G_ON,(VC_R2)
		bra	@f
gm_mc_set_mode:
		bsr	set_crt_mode_nc
		move	#G_ON,(VC_R2)
@@:
		bsr	gm6_check_home
		bsr	set_graph_home
		bra	gm6_loop


gm6_check_home:
		lea	(home_y,pc),a0
		move	(a0),d0
		bpl	@f
		moveq	#0,d0
		bra	1f
@@:		cmp	(offset_max_y,pc),d0
		blt	@f
		move	(offset_max_y,pc),d0
1:		move	d0,(a0)
@@:
		addq.l	#home_x-home_y,a0
		move	(a0),d0
		cmp	(offset_min_x,pc),d0
		bge	@f
		move	(offset_min_x,pc),d0
		bra	1f
@@:		cmp	(offset_max_x,pc),d0
		blt	@f
		move	(offset_max_x,pc),d0
1:		move	d0,(a0)
@@:		rts


* 垂直帰線期間待ちウェイト -------------------- *

check_sft_ctrl_opt12:
		move.l	d1,-(sp)
		moveq	#$e,d1
		IOCS	_BITSNS
		move.l	(sp)+,d1
		andi	#$f,d0			;SHIFT | CTRL | OPT.1 | OPT.2
		rts

wait_sub:
		PUSH	d0-d2/a0
		lea	(＄gsph),a0
		bsr	check_sft_ctrl_opt12
		bne	@f
		lea	(＄gspl-＄gsph,a0),a0
@@:		move	(a0),d0
		addq	#8,d0
		mulu	(wait_zoom,pc),d0
		lea	(wait_speed,pc),a0
		move	d0,(a0)

		lea	(wait_remain,pc),a0
		move	(a0),d0
		subq	#8,d0
		bhi	@f
		add	(wait_speed,pc),d0
		bsr	_vdisp_wait
@@:
		move	d0,(a0)
		POP	d0-d2/a0
		rts

_vdisp_wait::
@@:		btst	#4,(MFP_GPIP)
		beq	@b
@@:		btst	#4,(MFP_GPIP)
		bne	@b
		rts


* 16 色 --------------------------------------- *

gvon_16_usr::
		bsr	gvon_prepare
		TO_SUPER
		bsr	save_paltbl
gvon_16_start:
		bsr	load_paltbl
		move	#ZOOM_SPEED_1,(wait_zoom)	;速度調整用
		move.b	#1,(zoom_factor)		;zoom = 1
		clr.b	(Hfreq_low)			;freq = 31kHz
		bsr	call_clear_tvram
		move.l	(graph_home,pc),(home_backup)
		bsr	set_graph_home

		lea	(GVON24_flag,pc),a0
		tst.b	(a0)
		beq	@f

		clr.b	(a0)			;-g9
		st	(Hfreq_low)
@@:
		bsr	_16_change_crt
		bra	gm16_loop

gm16_nop:
		DOS	_CHANGE_PR
gm16_toggle_square:
gm16_loop:
		lea	(wait_remain,pc),a0
		clr	(a0)
gm16_loop_scroll:
		bsr	keyinp
		move	(gm16_job_table,pc,d0.w),d0
		moveq	#0,d3
		moveq	#0,d4
		jmp	(gm16_job_table,pc,d0.w)
gm16_job_table:
@@:		.dc	gm16_nop-@b
		.dc	gvon_256_start-@b		;16 -> 256
		.dc	gm16_quit_zoom-@b
		.dc	gm16_quit_orig-@b
		.dc	gm16_quit_off-@b
		.dc	gm16_mono-@b
		.dc	gm16_rotate_ccw-@b
		.dc	gm16_rotate_cw-@b
		.dc	gm16_turn_left_right-@b
		.dc	gm16_turn_up_down-@b
		.dc	gm16_tone_dec-@b
		.dc	gm16_tone_inc-@b
		.dc	gm16_tone_reset-@b
		.dc	gm16_toggle_square-@b
		.dc	gm16_toggle_freq-@b
		.dc	gm16_reset_position-@b
		.dc	gm16_toggle_position-@b
		.dc	gm16_zoom_in-@b
		.dc	gm16_zoom_out-@b
		.dc	gm16_scroll_left-@b
		.dc	gm16_scroll_right-@b
		.dc	gm16_scroll_up-@b
		.dc	gm16_scroll_down-@b
		.dc	gm16_shift7-@b
		.dc	gm16_shift4-@b
		.dc	gm16_shift1-@b
		.dc	gm16_shift8-@b
		.dc	gm16_shift2-@b
		.dc	gm16_shift9-@b
		.dc	gm16_shift6-@b
		.dc	gm16_shift3-@b
		.dc	gm16_gvon_x-@b

gm16_quit_zoom:
		cmpi	#1,(＄gmd2)
		beq	gm16_quit_off		;1=非表示
		bsr	_16_snap_zoom
		bra	ret_end2_16
gm16_quit_orig:
		bsr	clr_text_buffer
		bra	g_half_16
gm16_quit_off:
		bsr	_16_reset_zoom
		bra	_off_g_end

gm16_mono:
		bsr	gvram_to_mono_256
		bra	gm16_loop

gm16_rotate_ccw:
		bsr	rotate_gvram_ccw_16
		bra	gm16_loop
gm16_rotate_cw:
		bsr	rotate_gvram_cw_16
		bra	gm16_loop

gm16_turn_left_right:
		bsr	turn_gvram_lr_16
		bra	gm16_loop
gm16_turn_up_down:
		bsr	turn_gvram_ud_16
		bra	gm16_loop

gm16_tone_dec:
		bsr	tone_16_down
		bra	gm16_loop
gm16_tone_inc:
		bsr	tone_16_up
		bra	gm16_loop
gm16_tone_reset:
		bsr	tone_16_normal
		bra	gm16_loop

tone_16_down:
		lea	(GTONE,pc),a0
		tst	(a0)
		beq	@f
		subq	#1,(a0)
		bra	@f
tone_16_up:
		lea	(GTONE,pc),a0
		cmpi	#TONE_MAX,(a0)
		beq	@f
		addq	#1,(a0)
		bra	@f
tone_16_normal:
		lea	(GTONE,pc),a0
		move	#TONE_NORMAL,(a0)
@@:
		move	(a0),d4
		bra	gtone_set
**		rts

gm16_toggle_freq:
		lea	(Hfreq_low,pc),a0
		not.b	(a0)
		bsr	_16_change_crt
		bra	gm16_loop

gm16_reset_position:
		moveq	#0,d0
gm16_set_xy:
		lea	(graph_home,pc),a0
		move.l	d0,(a0)
		bsr	set_graph_home
		bra	gm16_loop

gm16_toggle_position:
		move.b	(zoom_factor,pc),d0
		beq	gm16_reset_position	;768|848x1024
		move.l	#512,d0
		cmp	(home_y,pc),d0
		beq	gm16_reset_position	;(0,512)→(0,0)
		swap	d0
		bra	gm16_set_xy		;それ以外は全て→(0,512)

gm16_zoom_in:
		lea	(zoom_factor,pc),a0
		cmpi.b	#2,(a0)
		beq	zoom16_2倍_to_4倍	;384x256→x4 zoom

		bsr	gm16_get_zoom_data
		addq.b	#1,(a0)

		lea	(graph_home,pc),a0	;現在の中央が拡大後の中央に
		move	(a1),d0			;くるように補正する
		add	d0,(a0)+		;home_y
		move	(4,a1),d0
		add	d0,(a0)+		;home_x
gm16_zoom_end:
		bsr	_16_change_crt
		bsr	set_graph_home
		bra	gm16_loop

gm16_zoom_out:
		lea	(zoom_factor,pc),a0
		subq.b	#1,(a0)
		bcs	zoom16_1倍_to_8倍	;768x1024→x8 zoom

		bsr	gm16_get_zoom_data

		lea	(home_y,pc),a0		;現在の中央が縮小後の中央に
		move	(a1)+,d0		;くるように補正する
		sub	d0,(a0)
		bcc	@f
		clr	(a0)			;上にはみ出た
@@:		move	(a1)+,d0
		cmp	(a0),d0
		bcc	@f
		move	d0,(a0)			;下にはみ出た
@@:
		lea	(home_x,pc),a0
		move	(a1)+,d0
		sub	d0,(a0)
		bcc	@f
		clr	(a0)			;左にはみ出た
@@:		move	(a1)+,d0
		cmp	(a0),d0
		bcc	@f
		move	d0,(a0)			;右にはみ出た
@@:
		bra	gm16_zoom_end

gm16_get_zoom_data:
		lea	(gm16_zout0_31,pc),a1
		move.b	(zoom_factor,pc),d0
		beq	@f
		lea	(gm16_zout1_31,pc),a1
@@:		move.b	(Hfreq_low,pc),d0
		beq	@f
		addq.l	#gm16_zout0_24-gm16_zout0_31,a1
@@:		rts


* 縮小後の y 移動量(上方向)、y 最大値、x 移動量(左方向)、x 最大値
gm16_zout0_31:	.dc	(1024-512)/2,1024-1024,(768-768)/2,1024-768	;→768x1024
gm16_zout0_24:	.dc	 (848-400)/2,1024-848,(1024-640)/2,1024-1024	;→848x1024
gm16_zout1_31:	.dc	 (512-256)/2,1024-512, (768-384)/2,1024-768	;→768x512
gm16_zout1_24:	.dc	 (400-200)/2,1024-400, (640-320)/2,1024-640	;→640x400

gm16_scroll_left:
gm16_scroll_right:
gm16_scroll_up:
gm16_scroll_down:
		bsr	do_scroll_sub
		beq	gm16_loop
		st	-(sp)
		bra	gm16_1dot_scroll

gm16_shift7:	moveq	#-1,d3
		bra	gm16_shift4
gm16_shift4:	moveq	#-1,d4
		bra	@f
gm16_shift1:	moveq	#+1,d3
		bra	gm16_shift4
gm16_shift8:	moveq	#-1,d3
		bra	@f
gm16_shift2:	moveq	#+1,d3
		bra	@f
gm16_shift9:	moveq	#-1,d3
		bra	gm16_shift6
gm16_shift6:	moveq	#+1,d4
		bra	@f
gm16_shift3:	moveq	#+1,d3
		bra	gm16_shift6
@@:		sf	-(sp)
gm16_1dot_scroll:
		lea	(home_y,pc),a0
		moveq	#0,d0			;y-- の上端
		tst	d3
		bmi	@f
		lea	(gm16_ymax_31,pc),a1
		move.b	(Hfreq_low,pc),d1
		beq	1f
		lea	(gm16_ymax_24,pc),a1
1:		move	(a1)+,d0		;y++ の下端
		move.b	(zoom_factor,pc),d1
		beq	@f
		move	(a1)+,d0
		subq.b	#1,d1
		beq	@f
		move	(a1)+,d0
@@:		cmp	(a0),d0
		beq	@f			;既に端にいる
		add	d3,(a0)
@@:
		addq	#home_x-home_y,a0
		moveq	#0,d0			;x-- の左端
		tst	d4
		bmi	@f
		lea	(gm16_xmax_31,pc),a1
		move.b	(Hfreq_low,pc),d1
		beq	1f
		lea	(gm16_xmax_24,pc),a1
1:		move	(a1)+,d0		;x++ の右端
		move.b	(zoom_factor,pc),d1
		beq	@f
		move	(a1)+,d0
		subq.b	#1,d1
		beq	@f
		move	(a1)+,d0
@@:		cmp	(a0),d0
		beq	@f			;既に端にいる
		add	d4,(a0)
@@:
		tst.b	(sp)+
		beq	@f
		bsr	wait_sub
@@:		bsr	set_graph_home
		bra	gm16_loop_scroll

gm16_xmax_31:	.dc	 1024-768,1024-768,1024-384
gm16_ymax_31:	.dc	1024-1024,1024-512,1024-256
gm16_xmax_24:	.dc	1024-1024,1024-640,1024-320
gm16_ymax_24:	.dc	 1024-848,1024-400,1024-200


* 画面モード変更 ------------------------------ *

_16_change_crt:
		move.b	(zoom_factor,pc),d1
		bne	@f

		move	#ZOOM_SPEED_1,(wait_zoom)
		moveq	#11,d0
		move.b	(Hfreq_low,pc),d1
		beq	_16_cc_done
		moveq	#10,d0
		bra	_16_cc_done
@@:
		subq.b	#1,d1
		bne	@f

		move	#ZOOM_SPEED_1,(wait_zoom)
		moveq	#0,d0
		move.b	(Hfreq_low,pc),d1
		beq	_16_cc_done
		moveq	#8,d0
		bra	_16_cc_done
@@:
		move	#ZOOM_SPEED_2,(wait_zoom)
		moveq	#4,d0
		move.b	(Hfreq_low,pc),d1
		beq	_16_cc_done
		moveq	#9,d0
_16_cc_done:
		bsr	set_crt_mode16
		move	#G_ON,(VC_R2)
		rts


* パレット操作 -------------------------------- *

save_paltbl:
		lea	(GTONE_TBL),a0
		lea	(GPARH_PAL),a1
		bra	@f
load_paltbl:
		lea	(GPARH_PAL),a0
		lea	(GTONE_TBL),a1
@@:
		moveq	#256/2-1,d0
@@:
		move.l	(a1)+,(a0)+
		dbra	d0,@b
		move	#TONE_NORMAL,(GTONE)
		rts


set_gtone_auto256:
		move	(sp)+,d4
gtone_set256:
		PUSH	d0-d7/a0-a1
		move	#256-1,d0
		bra	@f
set_gtone_auto16:
		move	(sp)+,d4
gtone_set:
		PUSH	d0-d7/a0-a1
		moveq	#16-1,d0
@@:
		move	d4,(GTONE)
		moveq	#1,d6
		lea	(GTONE_TBL),a0
		lea	(GPARH_PAL),a1

		cmpi	#TONE_NORMAL,d4
		bhi	over_bright
@@:
		moveq	#0,d2
		moveq	#0,d3
		move	(a0)+,d1
		rol	#2,d1			;gggr_rrrr_bbbb_bigg
		move.b	d1,d3
		ror	#5,d1			;bbig_gggg_rrrr_rbbb
		move.b	d1,d2
		lsr	#5,d1			;0000_0bbi_gggg_grrr
		andi	#$00ff,d1
		mulu	d4,d1
		asl	#2,d1
		andi	#%11111<<(5+5+1),d1
		mulu	d4,d2
		asr	#3,d2
		and	#%11111<<(5+1),d2
		mulu	d4,d3
		asr	#8,d3
		andi	#%11111<<(1),d3
		or	d3,d1
		or	d2,d1
		or	d6,d1
		move	d1,(a1)+
		dbra	d0,@b
		bra	gtone_exit
over_bright:
		move	d4,d1
		move	#128,d4
		sub	d1,d4
@@:
		move	#$00ff,d1
		move	d1,d2
		move	d1,d3
		move	(a0)+,d5
		rol	#2,d5
		sub.b	d5,d3
		ror	#5,d5
		sub.b	d5,d2
		lsr	#5,d5
		sub.b	d5,d1
		mulu	d4,d1
		asl	#2,d1
		move	#%11111<<(5+5+1),d5
		and	d5,d1
		sub	d1,d5
		move	d5,d1
		mulu	d4,d2
		asr	#3,d2
		move	#%11111<<(5+1),d5
		and	d5,d2
		sub	d2,d5
		move	d5,d2
		mulu	d4,d3
		asr	#8,d3
		move	#%11111<<(1),d5
		and	d5,d3
		sub	d3,d5
		or	d1,d5
		or	d2,d5
		or	d6,d5
		move	d5,(a1)+
		dbra	d0,@b
gtone_exit:
		POP	d0-d7/a0-a1
		rts


* パレット設定(色数で分岐).
* in	d0.w	明度

set_gtone_auto:
		move	d0,-(sp)
		move	#3,d0
		and	(VC_R0),d0
		beq	set_gtone_auto16
		subq	#1,d0
		beq	set_gtone_auto256

		move	(sp)+,d0
		move	d0,(GTONE)
		bra	set_gtone_64k

* 64K色パレットを設定する.
* over-bright未対応(TONE_NORMAL以上は全て標準パレット)
* in	d0.w	明度(0～TONE_MAX)

set_gtone_64k:
		cmpi	#TONE_NORMAL,d0
		bcc	set_gtone_64k_max

		PUSH	d0-d2/a0
		tst	d0
		beq	set_gtone_64k_min

;sp[%11111+1] = { 0*d0/TONE_NORMAL , 1*d0/TONE_NORMAL , …
;		,30*d0/TONE_NORMAL ,31*d0/TONE_NORMAL }

		lea	(sp),a0
		lea	(-32,sp),sp
		moveq	#32-1,d2
@@:
		move	d0,d1
		mulu	d2,d1
		addi	#TONE_NORMAL>>1,d1	;四捨五入用
**		divu	#TONE_NORMAL,d1
		lsr	#6,d1
		.fail	TONE_NORMAL.ne.1<<6
		move.b	d1,-(a0)
		dbra	d2,@b

		lea	(GPARH_PAL),a0
		moveq	#0,d2
set_gtone_64k_loop:
		move	d2,d0
		lsr.b	#6,d0			;%0000_00rr
		move.b	(sp,d0.w),d0
		ror.b	#3,d0
		moveq	#%0011_1110,d1
		and.b	d2,d1
		lsr.b	#1,d1			;%000b_bbbb
		or.b	(sp,d1.w),d0
		add.b	d0,d0
		move.b	d0,(a0)+		;下位バイト(偶数:I=0)
		ori.b	#1,d0
		move.b	d0,(a0)+		;〃        (奇数:I=1)

		move	d2,d0
		lsr.b	#3,d0			;%000g_gggg
		move.b	(sp,d0.w),d0
		lsl.b	#3,d0
		moveq	#%0000_0111,d1
		and.b	d2,d1			;%0000_0rrr
		or.b	(sp,d1.w),d0
		move.b	d0,(a0)+		;上位バイト
		andi.b	#%1111_1000,d0
		or.b	(1,sp,d1.w),d0
		move.b	d0,(a0)+		;〃

		addq.b	#2,d2
		bne	set_gtone_64k_loop

		lea	(32,sp),sp
set_gtone_64k_end:
		POP	d0-d2/a0
		rts

set_gtone_64k_min:
		lea	(GPARH_PAL),a0		;全て 0
		moveq	#0,d0
		moveq	#256/2-1,d2
@@:		move.l	d0,(a0)+
		dbra	d2,@b
		bra	set_gtone_64k_end

set_gtone_64k_max_normal:
		move	#TONE_NORMAL,(GTONE)
set_gtone_64k_max:
		PUSH	d0-d2/a0		;普通のパレット
		lea	(GPARH_PAL),a0
		move.l	#$0001_0001,d0
		move.l	#$0202_0202,d1
		moveq	#256/2-1,d2
@@:		move.l	d0,(a0)+
		add.l	d1,d0
		dbra	d2,@b
		bra	set_gtone_64k_end


* GVRAM メモリ配置モード変更 ------------------ *

set_access_mode_64k:
		move.b	#3,(CRTC_R20h)
		rts

set_access_mode_16:
		move.b	#4,(CRTC_R20h)
		rts


* 16 色ズーム --------------------------------- *

zoom16_toggle_freq:
		not.b	(Hfreq_low)		;24k <-> 31k
zoom16_set_crt:
		moveq	#4,d0			;31kHz,384×256
		move.b	(Hfreq_low,pc),d1
		beq	@f
		moveq	#9,d0			;24kHz,320×200
@@:
		bra	set_crt_mode16
**		rts


* ４倍ズーム ---------------------------------- *

zoom16_2倍_to_4倍:
		clr	(VC_R2)
		bsr	set_access_mode_64k
		bsr	zoom2_gram_to_text
		bsr	set_access_mode_16
		moveq	#96,d0
		add	(home_x,pc),d0
		andi	#1023,d0
		move	d0,(offset_x)
		moveq	#64,d0
		add	(home_y,pc),d0
		andi	#1023,d0
		move	d0,(offset_y)
zoom16_4倍mode:
		move.b	#4,(zoom_factor)
		move	#ZOOM_SPEED_4,(wait_zoom)
		clr.l	(graph_home)
		move	#1024-512/4,(offset_max_y)
		move	#1024-768/4,(offset_max_x)
		move	#384,(zoom_width)
		move	#1024-384,(zoom_rest)
		move	#(384-2)*2,(offs_right_pl)
		move	#(384-2)*2-1024*2,(offs_right_mi)
		move	#192,(zoom_w1)
		move	#192-1,(zoom_w2)

		bsr	zoom2_check_pos
		bsr	zoom16_4_flush_screen
		move	#G_ON,(VC_R2)
		bra	gm16z4_loop

gm16z4_nop:
		DOS	_CHANGE_PR
gm16z4_change_mode:
gm16z4_mono:
gm16z4_rotate_ccw:
gm16z4_rotate_cw:
gm16z4_turn_left_right:
gm16z4_turn_up_down:
gm16z4_toggle_square:
gm16z4_reset_position:
gm16z4_toggle_position:

gm16z4_loop:
		lea	(wait_remain,pc),a0
		clr	(a0)
gm16z4_loop_scroll:
		bsr	keyinp
		move	(gm16z4_job_table,pc,d0.w),d0
		moveq	#0,d3
		moveq	#0,d4
		jmp	(gm16z4_job_table,pc,d0.w)
gm16z4_job_table:
@@:		.dc	gm16z4_nop-@b
		.dc	gm16z4_change_mode-@b
		.dc	gm16z4_quit_zoom-@b
		.dc	gm16z4_quit_orig-@b
		.dc	gm16z4_quit_off-@b
		.dc	gm16z4_mono-@b
		.dc	gm16z4_rotate_ccw-@b
		.dc	gm16z4_rotate_cw-@b
		.dc	gm16z4_turn_left_right-@b
		.dc	gm16z4_turn_up_down-@b
		.dc	gm16z4_tone_dec-@b
		.dc	gm16z4_tone_inc-@b
		.dc	gm16z4_tone_reset-@b
		.dc	gm16z4_toggle_square-@b
		.dc	gm16z4_toggle_freq-@b
		.dc	gm16z4_reset_position-@b
		.dc	gm16z4_toggle_position-@b
		.dc	gm16z4_zoom_in-@b
		.dc	gm16z4_zoom_out-@b
		.dc	gm16z4_scroll_left-@b
		.dc	gm16z4_scroll_right-@b
		.dc	gm16z4_scroll_up-@b
		.dc	gm16z4_scroll_down-@b
		.dc	gm16z4_shift7-@b
		.dc	gm16z4_shift4-@b
		.dc	gm16z4_shift1-@b
		.dc	gm16z4_shift8-@b
		.dc	gm16z4_shift2-@b
		.dc	gm16z4_shift9-@b
		.dc	gm16z4_shift6-@b
		.dc	gm16z4_shift3-@b
		.dc	gm16z4_gvon_x-@b

gm16z4_quit_zoom:
		cmpi	#1,(＄gmd2)
		beq	zoom16_off_end
		bsr	_16_snap_zoom
		bra	ret_end2_16
gm16z4_quit_orig:
		bsr	zoom16_exit_pre
		bsr	clr_text_buffer
		move.l	(home_backup,pc),(graph_home)
		bsr	set_graph_home16
		bra	g_half_16
gm16z4_quit_off:
gm16z8_quit_off:
zoom16_off_end:
		bsr	zoom16_exit_pre
		move.l	(home_backup,pc),(graph_home)
		bsr	set_graph_home16
		bra	_off_g_end

gm16z4_tone_dec:
		bsr	tone_16_down
		bra	gm16z4_loop
gm16z4_tone_inc:
		bsr	tone_16_up
		bra	gm16z4_loop
gm16z4_tone_reset:
		bsr	tone_16_normal
		bra	gm16z4_loop

gm16z4_toggle_freq:
		bsr	zoom16_toggle_freq
		bra	gm16z4_loop

gm16z4_zoom_in:
		lea	(zoom_offset,pc),a0
		addi	#(128-64)/2,(a0)+	;offset_y
		addi	#(192-96)/2,(a0)+	;offset_x
		bra	zoom16_8倍mode
gm16z4_zoom_out:
		move.b	#2,(zoom_factor)
		bsr	gm16z4_zoom_out_sub
		bsr	_16_change_crt
		bsr	set_graph_home
		bra	gm16_loop
gm16z4_zoom_out_sub:
		lea	(zoom_offset,pc),a0
		lea	(graph_home,pc),a1
		moveq	#-(256-128)/2,d0
		add	(a0)+,d0		;offset_y
		move	d0,(a1)+		;home_y
		moveq	#-(384-192)/2,d0
		add	(a0)+,d0		;offset_x
		move	d0,(a1)+		;home_x
		bra	zoom16_exit_pre
**		rts

gm16z4_scroll_left:
gm16z4_scroll_right:
gm16z4_scroll_up:
gm16z4_scroll_down:
		bsr	do_scroll_sub
		beq	gm16z4_loop
		st	-(sp)
		bra	gm16z4_1dot_scroll

gm16z4_shift7:	moveq	#-1,d3
		bra	gm16z4_shift4
gm16z4_shift4:	moveq	#-1,d4
		bra	@f
gm16z4_shift1:	moveq	#+1,d3
		bra	gm16z4_shift4
gm16z4_shift8:	moveq	#-1,d3
		bra	@f
gm16z4_shift2:	moveq	#+1,d3
		bra	@f
gm16z4_shift9:	moveq	#-1,d3
		bra	gm16z4_shift6
gm16z4_shift6:	moveq	#+1,d4
		bra	@f
gm16z4_shift3:	moveq	#+1,d3
		bra	gm16z4_shift6
@@:		sf	-(sp)
gm16z4_1dot_scroll:
		move	d4,-(sp)
		tst	d3
		beq	@f
		bpl	1f
		bsr	gm16z4_1dot_up
		bra	@f
1:		bsr	gm16z4_1dot_down
@@:
		tst	(sp)+
		beq	@f
		bpl	1f
		bsr	gm16z4_1dot_left
		bra	@f
1:		bsr	gm16z4_1dot_right
@@:
		tst.b	(sp)+
		beq	@f
		bsr	wait_sub
@@:		bsr	set_graph_home16
		bra	gm16z4_loop_scroll

gm16z4_1dot_up:
		lea	(offset_y,pc),a0
		tst	(a0)
		beq	gm16z4_1dot_ud_end

		subq	#1,(a0)
		moveq	#-2,d0
		bsr	gm16z4_scroll_updown_sub
		movea.l	a2,a3			;上端を書き換える
		bra	gm16z4_1dot_ud
gm16z4_1dot_down:
		lea	(offset_y,pc),a0
		move	(offset_max_y,pc),d0
		cmp	(a0),d0
		beq	gm16z4_1dot_ud_end

		addq	#1,(a0)
		moveq	#+2,d0
		bsr	gm16z4_scroll_updown_sub
		lea	(a2,d5.l),a3		;下端を書き換える
		addi	#128-1,d3
gm16z4_1dot_ud:
@@:		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
		move.l	d4,(1024*2,a3)		;(x,y+1),(x+1,y+1)
		move.l	d4,(a3)+		;(x,y)	,(x+1,y)
		addq	#1,d2			;x++
		dbra	d6,@b

		tst	d7
		bmi	gm16z4_1dot_ud_end
		lea	(-1024*2,a3),a3
@@:
		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
		move.l	d4,(1024*2,a3)		;(x,y+1),(x+1,y+1)
		move.l	d4,(a3)+		;(x,y)	,(x+1,y)
		addq	#1,d2			;x++
		dbra	d7,@b
gm16z4_1dot_ud_end:
		rts

gm16z4_1dot_left:
		lea	(offset_x,pc),a0
		tst	(a0)
		beq	gm16z4_1dot_lr_end

		subq	#1,(a0)
		moveq	#-2,d0
		bsr	gm16z4_scroll_leftright_sub
		movea.l	a2,a3			;左端を書き換える
		bra	gm16z4_1dot_lr
gm16z4_1dot_right:
		lea	(offset_x,pc),a0
		move	(offset_max_x,pc),d0
		cmp	(a0),d0
		beq	gm16z4_1dot_lr_end

		addq	#1,(a0)
		moveq	#+2,d0
		bsr	gm16z4_scroll_leftright_sub
		move	(offs_right_pl,pc),d1
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest
		move	(offs_right_mi,pc),d1
@@:
		lea	(a2,d1.w),a3		;右端を書き換える
		add	(zoom_w2,pc),d2
gm16z4_1dot_lr:
@@:		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
		move.l	d4,(1024*2,a3)		;(x,y+1),(x+1,y+1)
		move.l	d4,(a3)			;(x,y)	,(x+1,y)
		addq	#1,d3			;y++
		lea	(1024*2*2,a3),a3
		dbra	d6,@b

		tst	d7
		bmi	gm16z4_1dot_lr_end
		suba.l	#1024*2*1024,a3
@@:
		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
		move.l	d4,(1024*2,a3)		;(x,y+1),(x+1,y+1)
		move.l	d4,(a3)			;(x,y)	,(x+1,y)
		addq	#1,d3			;y++
		lea	(1024*2*2,a3),a3
		dbra	d7,@b
gm16z4_1dot_lr_end:
		rts

gm16z4_scroll_updown_sub:
		lea	(home_y,pc),a0
		add	d0,(a0)
		andi	#1024-1,(a0)

		bsr	gm16z4_scroll_sub
		move	(zoom_w2,pc),d6
		moveq	#-1,d7
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest

		sub	(zoom_rest,pc),d0
		asr	#1,d0
		move	d0,d7
		sub	d0,d6			;d6 = zoom_w2-(x-zoom_rest)/2
		subq	#1,d7			;d7 = (x-zoom_rest)/2-1
@@:
		move.l	#1024*2*(256-2),d5	;d5 = offset to bottom
		move	(home_y,pc),d0
		cmpi	#1024-256,d0
		bls	@f
		subi.l	#1024*2*1024,d5
@@:		rts

gm16z4_scroll_leftright_sub:
		lea	(home_x,pc),a0
		add	d0,(a0)
		andi	#1024-1,(a0)

		bsr	gm16z4_scroll_sub
	 	moveq	#128-1,d6		;d6 = upper regeon loop
		moveq	#-1,d7			;d7 = division flag

		move	(home_y,pc),d0
		cmpi	#1024-256,d0
		bls	@f			;y≦768

		subi	#1024-256,d0
		asr	#1,d0			;4倍(2dot)ズームだから1/2
		move	d0,d7
		sub	d0,d6			;d6 = (128-(y-768)/2)-1
		subq	#1,d7			;d7 = (y-768)/2-1
@@:		rts

gm16z4_scroll_sub:
		lea	(TVRAM),a1		;a1 = src. top

		move.l	(graph_home,pc),d0
		lea	(GVRAM),a0
		bsr	zoom16_adr_set
		movea.l	a0,a2			;a2 = dst. top

		moveq	#0,d2
		moveq	#0,d3
		move	(offset_x,pc),d2
		move	(offset_y,pc),d3
		rts


* 16 色ズーム下請け --------------------------- *

* TVRAM に退避したデータから１ドット分の色データを取り出す
* in	d0.l	x
*	d1.l	y
*	a1.l	退避バッファ(TVRAM)のアドレス
* out	d4.l	パレットコード(上位/下位ワードに同じ値)
* break	d0/d1

.if 1
zoom16_get_color:
		bclr	#9,d1
		bne	zoom16_get_color_yh
*zoom16_get_color_yl:
		swap	d1
		lsr.l	#6,d1			;(y&511)*1024
		add	d0,d0
		bclr	#9+1,d0			;(x&511)*2
		bne	zoom16_get_color_yl_xh
;zoom16_get_color_yl_xl:
		add	d0,d1
		move	(a1,d1.l),d0		;$000f
		move	d0,d4
		swap	d4
		move	d0,d4			;14+4+4+4=26clk
		rts
zoom16_get_color_yl_xh:
		add	d0,d1
		move	(a1,d1.l),d0		;$00f0
		lsr	#4,d0
		move	d0,d4
		swap	d4
		move	d0,d4			;14+14+4+4+4=40clk
		rts
zoom16_get_color_yh:
		swap	d1
		lsr.l	#6,d1			;(y&511)*1024
		add	d0,d0
		bclr	#9+1,d0			;(x&511)*2
		bne	zoom16_get_color_yh_xh
;zoom16_get_color_yh_xl:
		add	d0,d1
		move.b	(a1,d1.l),d0		;$0f00
		move	d0,d4
		swap	d4
		move	d0,d4			;14+4+4+4=26clk
		rts
zoom16_get_color_yh_xh:
		add	d0,d1
		move.b	(a1,d1.l),d0		;$f000
		lsr	#4,d0
		move	d0,d4
		swap	d4
		move	d0,d4			;14+14+4+4+4=40clk
		rts
.else
zoom16_get_color:
		moveq	#0,d4
		bclr	#9,d0
		beq	@f
		moveq	#4,d4			;x=512～1023
@@:
		bclr	#9,d1
		beq	@f
		addq	#8,d4			;y=512～1023
@@:
		swap	d1
		lsr.l	#6,d1			;y*=1024
		add	d0,d0			;x*=2
		add	d0,d1
		move	(a1,d1.l),d0
		lsr	d4,d0
		move	d0,d4
		swap	d4
		move	d0,d4
		rts
.endif


* ４倍ズーム拡大描画 -------------------------- *

zoom16_4_flush_screen:
		lea	(TVRAM),a1
		lea	(GVRAM),a2
		lea	(1024*2,a2),a3

		move.l	#1024*2*2,d5
		sub	(zoom_width,pc),d5
		sub	(zoom_width,pc),d5

		moveq	#0,d7
		move	(offset_y,pc),d7

		moveq	#128-1,d3
zoom16_4_flush_y_loop:
		moveq	#0,d6
		move	(offset_x,pc),d6
		move	(zoom_w2,pc),d2
zoom16_4_flush_x_loop:
		move.l	d6,d0			;d0 = X座標
		move.l	d7,d1			;d1 = Y座標
		bsr	zoom16_get_color
		addq	#1,d6
		move.l	d4,(a2)+
		move.l	d4,(a3)+
		dbra	d2,zoom16_4_flush_x_loop

		addq	#1,d7
		adda.l	d5,a2
		adda.l	d5,a3
		dbra	d3,zoom16_4_flush_y_loop

		bra	set_graph_home16
**		rts

* ８倍ズーム ---------------------------------- *

zoom16_1倍_to_8倍:
		clr	(VC_R2)
		bsr	set_access_mode_64k
		bsr	zoom2_gram_to_text
		bsr	set_access_mode_16
		bsr	zoom16_set_crt
zoom16_8倍mode:
		move.b	#8,(zoom_factor)
		move	#ZOOM_SPEED_8,(wait_zoom)
		clr.l	(graph_home)
		move	#1024-512/8,(offset_max_y)
		move	#1024-768/8,(offset_max_x)
		move	#384,(zoom_width)
		move	#1024-384,(zoom_rest)
		move	#(384-4)*2,(offs_right_pl)
		move	#-1024*2+(384-4)*2,(offs_right_mi)
		move	#96,(zoom_w1)
		move	#96-1,(zoom_w2)

		bsr	zoom2_check_pos
		bsr	zoom16_8_flush_screen
		move	#G_ON,(VC_R2)
		bra	gm16z8_loop

gm16z8_nop:
		DOS	_CHANGE_PR
gm16z8_change_mode:
gm16z8_mono:
gm16z8_rotate_ccw:
gm16z8_rotate_cw:
gm16z8_turn_left_right:
gm16z8_turn_up_down:
gm16z8_toggle_square:
gm16z8_reset_position:
gm16z8_toggle_position:

gm16z8_loop:
		lea	(wait_remain,pc),a0
		clr	(a0)
gm16z8_loop_scroll:
		bsr	keyinp
		move	(gm16z8_job_table,pc,d0.w),d0
		moveq	#0,d3
		moveq	#0,d4
		jmp	(gm16z8_job_table,pc,d0.w)
gm16z8_job_table:
@@:		.dc	gm16z8_nop-@b
		.dc	gm16z8_change_mode-@b
		.dc	gm16z8_quit_zoom-@b
		.dc	gm16z8_quit_orig-@b
		.dc	gm16z8_quit_off-@b
		.dc	gm16z8_mono-@b
		.dc	gm16z8_rotate_ccw-@b
		.dc	gm16z8_rotate_cw-@b
		.dc	gm16z8_turn_left_right-@b
		.dc	gm16z8_turn_up_down-@b
		.dc	gm16z8_tone_dec-@b
		.dc	gm16z8_tone_inc-@b
		.dc	gm16z8_tone_reset-@b
		.dc	gm16z8_toggle_square-@b
		.dc	gm16z8_toggle_freq-@b
		.dc	gm16z8_reset_position-@b
		.dc	gm16z8_toggle_position-@b
		.dc	gm16z8_zoom_in-@b
		.dc	gm16z8_zoom_out-@b
		.dc	gm16z8_scroll_left-@b
		.dc	gm16z8_scroll_right-@b
		.dc	gm16z8_scroll_up-@b
		.dc	gm16z8_scroll_down-@b
		.dc	gm16z8_shift7-@b
		.dc	gm16z8_shift4-@b
		.dc	gm16z8_shift1-@b
		.dc	gm16z8_shift8-@b
		.dc	gm16z8_shift2-@b
		.dc	gm16z8_shift9-@b
		.dc	gm16z8_shift6-@b
		.dc	gm16z8_shift3-@b
		.dc	gm16z8_gvon_x-@b

gm16z8_quit_zoom:
		cmpi	#1,(＄gmd2)
		beq	zoom16_off_end
		bsr	_16_snap_zoom
		bra	ret_end2_16
gm16z8_quit_orig:
		bsr	zoom16_exit_pre
		bsr	clr_text_buffer
		move.l	(home_backup,pc),(graph_home)
		bsr	set_graph_home16
		bra	g_half_16

gm16z8_tone_dec:
		bsr	tone_16_down
		bra	gm16z8_loop
gm16z8_tone_inc:
		bsr	tone_16_up
		bra	gm16z8_loop
gm16z8_tone_reset:
		bsr	tone_16_normal
		bra	gm16z8_loop

gm16z8_toggle_freq:
		bsr	zoom16_toggle_freq
 		bra	gm16z8_loop

gm16z8_zoom_in:
		bsr	zoom16_exit_pre
		move.b	#1,(zoom_factor)
		bsr	_16_change_crt
		move.l	(home_backup,pc),(graph_home)
		bsr	set_graph_home
		bra	gm16_loop
gm16z8_zoom_out:
		bsr	gm16z8_zoom_out_sub
		bra	zoom16_4倍mode
gm16z8_zoom_out_sub:
		lea	(zoom_offset,pc),a0
		subi	#(128-64)/2,(a0)+	;offset_y
		subi	#(192-96)/2,(a0)+	;offset_x
		rts

gm16z8_scroll_left:
gm16z8_scroll_right:
gm16z8_scroll_up:
gm16z8_scroll_down:
		bsr	do_scroll_sub
		beq	gm16z8_loop
		st	-(sp)
		bra	gm16z8_1dot_scroll

gm16z8_shift7:	moveq	#-1,d3
		bra	gm16z8_shift4
gm16z8_shift4:	moveq	#-1,d4
		bra	@f
gm16z8_shift1:	moveq	#+1,d3
		bra	gm16z8_shift4
gm16z8_shift8:	moveq	#-1,d3
		bra	@f
gm16z8_shift2:	moveq	#+1,d3
		bra	@f
gm16z8_shift9:	moveq	#-1,d3
		bra	gm16z8_shift6
gm16z8_shift6:	moveq	#+1,d4
		bra	@f
gm16z8_shift3:	moveq	#+1,d3
		bra	gm16z8_shift6
@@:		sf	-(sp)
gm16z8_1dot_scroll:
		move	d4,-(sp)
		tst	d3
		beq	@f
		bpl	1f
		bsr	gm16z8_1dot_up
		bra	@f
1:		bsr	gm16z8_1dot_down
@@:
		tst	(sp)+
		beq	@f
		bpl	1f
		bsr	gm16z8_1dot_left
		bra	@f
1:		bsr	gm16z8_1dot_right
@@:
		tst.b	(sp)+
		beq	@f
		bsr	wait_sub
@@:		bsr	set_graph_home16
		bra	gm16z8_loop_scroll

gm16z8_1dot_up:
		lea	(offset_y,pc),a0
		tst	(a0)
		beq	gm16z8_1dot_ud_end

		subq	#1,(a0)
		moveq	#-4,d0
		bsr	gm16z8_scroll_updown_sub
		movea.l	a2,a3			;上端を書き換える
		bra	gm16z8_1dot_ud
gm16z8_1dot_down:
		lea	(offset_y,pc),a0
		move	(offset_max_y,pc),d0
		cmp	(a0),d0
		beq	gm16z8_1dot_ud_end

		addq	#1,(a0)
		moveq	#+4,d0
		bsr	gm16z8_scroll_updown_sub
		lea	(a2,d5.l),a3		;下端を書き換える
		addi	#63,d3
gm16z8_1dot_ud:
@@:		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
	.rept	2
		move.l	d4,(1024*6,a3)		;(x,y+3),(x+1,y+3) (x+2,y+3),(x+3,y+3)
		move.l	d4,(1024*4,a3)		;(x,y+2),(x+1,y+2) (x+2,y+2),(x+3,y+2)
		move.l	d4,(1024*2,a3)		;(x,y+1),(x+1,y+1) (x+2,y+1),(x+3,y+1)
		move.l	d4,(a3)+		;(x,y)	,(x+1,y)   (x+2,y)  ,(x+3,y)
	.endm
		addq	#1,d2			;x++
		dbra	d6,@b

		tst	d7
		bmi	gm16z8_1dot_ud_end
		lea	(-1024*2,a3),a3
@@:
		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
	.rept	2
		move.l	d4,(1024*6,a3)
		move.l	d4,(1024*4,a3)
		move.l	d4,(1024*2,a3)
		move.l	d4,(a3)+
	.endm
		addq	#1,d2			;x++
		dbra	d7,@b
gm16z8_1dot_ud_end:
		rts

gm16z8_1dot_left:
		lea	(offset_x,pc),a0
		tst	(a0)
		beq	gm16z8_1dot_lr_end

		subq	#1,(a0)
		moveq	#-4,d0
		bsr	gm16z8_scroll_leftright_sub
		movea.l	a2,a3			;左端を書き換える
		bra	gm16z8_1dot_lr
gm16z8_1dot_right:
		lea	(offset_x,pc),a0
		move	(offset_max_x,pc),d0
		cmp	(a0),d0
		beq	gm16z8_1dot_lr_end

		addq	#1,(a0)
		moveq	#+4,d0
		bsr	gm16z8_scroll_leftright_sub
		move	(offs_right_pl,pc),d1
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest
		move	(offs_right_mi,pc),d1
@@:
		lea	(a2,d1.w),a3		;右端を書き換える
		add	(zoom_w2,pc),d2
gm16z8_1dot_lr:
@@:		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
	.rept	2
		move.l	d4,(1024*6,a3)		;(x,y+3),(x+1,y+3) (x+2,y+3),(x+3,y+3)
		move.l	d4,(1024*4,a3)		;(x,y+2),(x+1,y+2) (x+2,y+2),(x+3,y+2)
		move.l	d4,(1024*2,a3)		;(x,y+1),(x+1,y+1) (x+2,y+1),(x+3,y+1)
		move.l	d4,(a3)+		;(x,y)	,(x+1,y)   (x+2,y)  ,(x+3,y)
	.endm
		addq	#1,d3			;y++
		lea	(1024*8-8,a3),a3
		dbra	d6,@b

		tst	d7
		bmi	gm16z8_1dot_lr_end
		suba.l	#1024*2*1024,a3
@@:
		move.l	d2,d0
		move.l	d3,d1
		bsr	zoom16_get_color
	.rept	2
		move.l	d4,(1024*6,a3)
		move.l	d4,(1024*4,a3)
		move.l	d4,(1024*2,a3)
		move.l	d4,(a3)+
	.endm
		addq	#1,d3			;y++
		lea	(1024*8-8,a3),a3
		dbra	d7,@b
gm16z8_1dot_lr_end:
		rts

gm16z8_scroll_updown_sub:
		lea	(home_y,pc),a0
		add	d0,(a0)
		andi	#1024-1,(a0)

		bsr	gm16z8_scroll_sub
		move	(zoom_w2,pc),d6
		moveq	#-1,d7
		move	(home_x,pc),d0
		cmp	(zoom_rest,pc),d0
		bls	@f			;x≦zoom_rest

		sub	(zoom_rest,pc),d0
		asr	#2,d0
		move	d0,d7
		sub	d0,d6			;d6 = zoom_w2-(x-zoom_rest)/4
		subq	#1,d7			;d7 = (x-zoom_rest)/4-1
@@:
		move.l	#1024*2*(256-4),d5	;d5 = offset to bottom
		move	(home_y,pc),d0
		cmpi	#1024-256,d0
		bls	@f
		subi.l	#1024*2*1024,d5
@@:		rts

gm16z8_scroll_leftright_sub:
		lea	(home_x,pc),a0
		add	d0,(a0)
		andi	#1024-1,(a0)

		bsr	gm16z8_scroll_sub
	 	moveq	#64-1,d6		;d6 = upper regeon loop
		moveq	#-1,d7			;d7 = division flag

		move	(home_y,pc),d0
		cmpi	#1024-256,d0
		bls	@f			;y≦768

		subi	#1024-256,d0
		asr	#2,d0			;8倍(4dot)ズームだから1/4
		move	d0,d7
		sub	d0,d6			;d6 = (64-(y-768)/4)-1
		subq	#1,d7			;d7 = (y-768)/4-1
@@:		rts

gm16z8_scroll_sub:
		lea	(TVRAM),a1		;a1 = src. top

		move.l	(graph_home,pc),d0
		lea	(GVRAM),a0
		bsr	zoom16_adr_set
		movea.l	a0,a2			;a2 = dst. top

		moveq	#0,d2
		moveq	#0,d3
		move	(offset_x,pc),d2
		move	(offset_y,pc),d3
		rts


* ８倍ズーム拡大描画 -------------------------- *

zoom16_8_flush_screen:
		lea	(TVRAM),a1
		lea	(GVRAM),a2
		lea	(1024*2,a2),a3
		lea	(1024*2*2,a2),a4
		lea	(1024*2*3,a2),a5

		move.l	#1024*2*4,d5
		sub	(zoom_width,pc),d5
		sub	(zoom_width,pc),d5

		moveq	#0,d7
		move	(offset_y,pc),d7

		moveq	#64-1,d3
zoom16_8_flush_y_loop:
		moveq	#0,d6
		move	(offset_x,pc),d6
		move	(zoom_w2,pc),d2
zoom16_8_flush_x_loop:
		move.l	d6,d0			;d0 = X座標
		move.l	d7,d1			;d1 = Y座標
		bsr	zoom16_get_color
		addq	#1,d6
	.irp	an,a2,a3,a4,a5
		move.l	d4,(an)+
		move.l	d4,(an)+
	.endm
		dbra	d2,zoom16_8_flush_x_loop

		addq	#1,d7
		adda.l	d5,a2
		adda.l	d5,a3
		adda.l	d5,a4
		adda.l	d5,a5
		dbra	d3,zoom16_8_flush_y_loop

		bra	set_graph_home16
**		rts


* ズーム拡大終了 ------------------------------ *

_16_snap_zoom:
		cmpi.b	#2,(zoom_factor)
		bne	@f
		bsr	snap_16_zoom_x2
		bra	_16_snap_end
@@:
		cmpi.b	#4,(zoom_factor)
		bne	@f
		bsr	_snap_16_zoom_x4
		bra	_16_snap_end
@@:
		cmpi.b	#8,(zoom_factor)
		bne	_16_reset_zoom
		bsr	_snap_16_zoom_x8
_16_snap_end:
		move.b	#1,(zoom_factor)
		clr.b	(Hfreq_low)
		bsr	_16_change_crt
		clr.l	(graph_home)
		bra	set_graph_home
**		rts
@@:

_16_reset_zoom:
		cmpi.b	#1,(zoom_factor)
		beq	@f
		move.b	#1,(zoom_factor)
		bsr	_16_change_crt
		move.l	(home_backup,pc),(graph_home)
		bsr	set_graph_home
@@:		rts


* ２倍ズーム拡大終了 -------------------------- *

snap_16_zoom_x2:
		lea	(TVRAM),a1
		lea	(GVRAM),a2

		moveq	#0,d0
		moveq	#0,d1
		move	(home_x,pc),d0
		move	(home_y,pc),d1

		move.l	d0,d2
		move.l	d1,d3
		swap	d3
		asr.l	#5,d3
		add.l	d2,d2
		add.l	d2,d3
		adda.l	d3,a2

		move	#256,d6
		move	#1024,d7
		sub	d1,d7
		sub	d7,d6
		bgt	@f
		move	#256,d7
@@:
		subq	#1,d7			;upper region loop
		subq	#1,d6			;lower region loop

		move	#384,d4
		move	#1024,d5
		sub	d0,d5
		sub	d5,d4
		bgt	@f
		move	#384,d5
@@:
		subq	#1,d5			;left region loop
		subq	#1,d4			;right region loop
snap_16_x2_g2t_y_loop1:
		move	d5,d3
@@:
		move	(a2)+,d0
		move.b	d0,(a1)+
		dbra	d3,@b
		tst	d4
		bmi	@@f
		lea	(-2048,a2),a2
		move	d4,d3
@@:
		move	(a2)+,d0
		move.b	d0,(a1)+
		dbra	d3,@b
		lea	(2048,a2),a2
@@:
		lea	(1280,a2),a2
		dbra	d7,snap_16_x2_g2t_y_loop1
		tst	d6
		bmi	snap_16_x2_t2g

		suba.l	#1024*2*1024,a2
snap_16_x2_g2t_y_loop2:
		move	d5,d3
@@:
		move	(a2)+,d0
		move.b	d0,(a1)+
		dbra	d3,@b
		tst	d4
		bmi	@@f
		lea	(-2048,a2),a2
		move	d4,d3
@@:
		move	(a2)+,d0
		move.b	d0,(a1)+
		dbra	d3,@b
		lea	(2048,a2),a2
@@:		lea	(1280,a2),a2
		dbra	d6,snap_16_x2_g2t_y_loop2
snap_16_x2_t2g:
		clr	(VC_R2)
		lea	(TVRAM),a1
		lea	(GVRAM),a2
		lea	(1024*2,a2),a3
		move.l	#(1024*2-768)*2,d5

		move	#256-1,d3
snap_16_x2_t2g_y_loop:
		move	#384-1,d2
snap_16_x2_t2g_x_loop:
		move.b	(a1)+,d0
		move	d0,(a2)+
		move	d0,(a3)+
		move	d0,(a2)+
		move	d0,(a3)+
		dbra	d2,snap_16_x2_t2g_x_loop

		adda.l	d5,a2
		adda.l	d5,a3
		dbra	d3,snap_16_x2_t2g_y_loop

		bra	call_clear_tvram
**		rts


* ４倍ズーム拡大終了 -------------------------- *

_snap_16_zoom_x4:
		bsr	set_access_mode_64k
		bsr	zoom2_gram_to_text
		bsr	set_access_mode_16
		clr	(VC_R2)

		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a1
		lea	(GVRAM),a2
		lea	(1024*2,a2),a3
		lea	(1024*2*2,a2),a4
		lea	(1024*2*3,a2),a5

		move.l	#(1024*4-768)*2,d5
		moveq	#0,d7
		move	(offset_y,pc),d7

		move	#128-1,d3
snap_16_x4_y_loop:
		moveq	#0,d6
		move	(offset_x,pc),d6
		move	#192-1,d2
snap_16_x4_x_loop:
		move.l	d6,d0			;d0 = X座標
		move.l	d7,d1			;d1 = Y座標
		bsr	zoom16_get_color
		addq	#1,d6
	.irp	an,a2,a3,a4,a5
			move.l	d4,(an)+
			move.l	d4,(an)+
	.endm
		dbra	d2,snap_16_x4_x_loop

		addq	#1,d7
		adda.l	d5,a2
		adda.l	d5,a3
		adda.l	d5,a4
		adda.l	d5,a5
		dbra	d3,snap_16_x4_y_loop
		rts


* ８倍ズーム拡大終了 -------------------------- *

_snap_16_zoom_x8:
		bsr	set_access_mode_64k
		bsr	zoom2_gram_to_text
		bsr	set_access_mode_16
		clr	(VC_R2)

		move.l	(zoom_offset,pc),d0
		lea	(TVRAM),a1
		lea	(GVRAM),a2
		lea	(1024*2*2,a2),a3
		lea	(1024*2*4,a2),a4
		lea	(1024*2*6,a2),a5

		move.l	#(1024*8-768)*2,d5
		moveq	#0,d7
		move	(offset_y,pc),d7

		move	#64-1,d3
snap_16_x8_y_loop:
		moveq	#0,d6
		move	(offset_x,pc),d6
		move	#96-1,d2
snap_16_x8_x_loop:
		move.l	d6,d0			;d0 = X座標
		move.l	d7,d1			;d1 = Y座標
		bsr	zoom16_get_color
		addq	#1,d6
	.irp	an,a2,a3,a4,a5
		move.l	d4,(1024*2,an)
		move.l	d4,(1024*2+4,an)
		move.l	d4,(1024*2+8,an)
		move.l	d4,(1024*2+12,an)
		move.l	d4,(an)+
		move.l	d4,(an)+
		move.l	d4,(an)+
		move.l	d4,(an)+
	.endm
		dbra	d2,snap_16_x8_x_loop

		addq	#1,d7
		adda.l	d5,a2
		adda.l	d5,a3
		adda.l	d5,a4
		adda.l	d5,a5
		dbra	d3,snap_16_x8_y_loop
		rts


* ズーム終了準備 ------------------------------ *

zoom16_exit_pre:
		clr	(VC_R2)
		bsr	set_access_mode_64k
		bsr	zoom2_text_to_gram

		moveq	#6,d0
		move.b	(Hfreq_low,pc),d1
		beq	@f
		moveq	#10,d0
@@:		bsr	set_crt_mode16

		bra	set_graph_home16
**		rts


* 終了処理 ------------------------------------ *

_64k_exit_init:
		clr	(VC_R2)
		bsr	clr_text_buffer
		clr	-(sp)
		move	#16,-(sp)
		DOS	_CONCTRL		;768x512、グラフィックなし
		addq.l	#4,sp
		rts


* グラフィック表示終了 ------------------------ *

on_g_end:
		bsr	_64k_exit_init
		move	#T_ON+G_ON,(VC_R2)
		moveq	#3,d1			;512×512、65536 色
		bra	g_on_g_end


tone_down_64k_256:
		move.b	(HighCol,pc),d0
		bne	g_half_64k
		bra	g_half_256

g_half_256_usr::
		TO_SUPER
		bsr	save_paltbl
		move	#TONE_NORMAL,(GTONE)
		clr.l	(graph_home)
		bra.s	@f
g_half_256:
		bsr	_64k_exit_init
@@:
		move	(＄gton),d4
		cmpi	#TONE_MAX,d4
		bls	@f
		move	(GTONE,pc),d4
		lsr	#1,d4			;現在の半分にする
@@:
		bsr	gtone_set256
		moveq	#1,d1			;512×512、256 色
		bra	g_on_g_end

g_half_64k_usr::
		TO_SUPER
		bra.s	@f
g_half_64k:
		bsr	_64k_exit_init
@@:
		move	(＄gton),d0		;set_gtone_64k で使うので必ず d0
		cmpi	#TONE_MAX,d0
		bls	@f
		tst	(＄spmd)
		beq	real_tone_down

		moveq	#0,d0
		moveq	#3,d1
		bsr	set_crt_mode
		bsr	center_64k_graphic_gm

		move	#G_HALF_ON+T_ON,(VC_R2)
		bra	g_end
@@:
		bsr	set_gtone_64k
		bra	_65536_on_g_end
real_tone_down:
		bsr	g_tone_down
_65536_on_g_end:
		moveq	#3,d1			;512×512、65536 色
g_on_g_end:
		moveq	#0,d0
		bsr	set_crt_mode
		bsr	center_64k_graphic_gm
		move	#T_ON+G_ON,(VC_R2)
		bra	g_end


ret_end2_16:
		bsr	clr_text_buffer
		move	#T_ON+G_ON,(VC_R2)
		cmpi	#2,(＄gmd2)
		beq	g_half_16
		bra	g_end


g_half_16_usr::
		TO_SUPER
		bsr	save_paltbl
		move	#TONE_NORMAL,(GTONE)
		clr.l	(graph_home)
g_half_16:
		move	#4,(gvon_color)
		move	(＄gton),d4
		cmpi	#TONE_MAX,d4
		bls	@f
		move	(GTONE,pc),d4
		lsr	#1,d4			;現在の半分にする
@@:
		bsr	gtone_set

		move	(gvon_crtmode,pc),d0
		beq	@f
		moveq	#0,d0			;31kHz,768×512
		bsr	set_crt_mode16
		clr.l	(graph_home)
		bsr	set_graph_home16
@@:
		move	#T_ON+G_ON,(VC_R2)
g_end:
		HRL_OFF

		lea	(mion_flag,pc),a0	;実行前に &mion 状態だったら
		lsl	(a0)			;フラグを初期化してから
		bcc	@f			;&mion 呼び出し
		bsr	mion_sub
@@:
		TO_USER
		rts


* 65536 色 GVRAM 書き換え半輝度 --------------- *

MASK:	.equ	%11110_11110_11110_0

g_tone_down:
		PUSH	d0-d7/a0
		lea	(GVRAM),a0
		move.l	#MASK<<16+MASK,d7
		move	#(512*512)/(6*2)-1,d0
@@:
	.irp	reg,d1,d2,d3,d4,d5,d6
		move.l	(a0)+,reg
		and.l	d7,reg
		lsr.l	#1,reg
	.endm
		movem.l	d1-d6,(-4*6,a0)
		dbra	d0,@b
	.rept	2
		move.l	(a0),d1			;残りの端数を処理する
		and.l	d7,d1
		lsr.l	#1,d1
		move.l	d1,(a0)+
	.endm
		POP	d0-d7/a0
		rts


*************************************************
*		&clear-gvram			*
*************************************************

＆clear_gvram::
		bsr	check_gusemd_and_abort
		moveq	#T_ON,d1
		IOCS	_VC_R2			;move #T_ON,($e82600)
		moveq	#0,d1
		moveq	#0,d2
		IOCS	_TGUSEMD
		IOCS	_G_CLR_ON
		bra	＆gvram_off


*************************************************
*		&gvram-off			*
*************************************************

＆gvram_off::
		bsr	mioff
		moveq	#T_ON,d1
		IOCS	_VC_R2			;move #T_ON,($e82600)
		moveq	#.low._GM_MASK_CLEAR,d1
		bra	_gm_internal_tgusemd
**		rts


*************************************************
*		&get-color-mode			*
*************************************************

＆get_color_mode::
		lea	(VC_R2),a1
		IOCS	_B_WPEEK
		andi	#G_ON,d0
		beq	get_color_mode_end	;表示オフ = 0

		lea	(VC_R0-(VC_R2+2),a1),a1
		IOCS	_B_WPEEK
		andi	#3,d0
		beq	set_status_1		;16色 = 1
		subq	#1,d0
		beq	get_color_mode_256
*get_color_mode_64k
		moveq	#6,d0			;64K色 = 6
		bra	get_color_mode_end
get_color_mode_256:
		moveq	#2,d0			;256色 = 2
get_color_mode_end:
		bra	set_status
**		rts


*************************************************
*		&iocs-home			*
*************************************************

call_atoi_a0:
		jmp	(atoi_a0)
**		rts

＆iocs_home::
		moveq	#0,d1
		subq.l	#1,d7
		bcs	iocs_home_error

		bsr	call_atoi_a0		;X 座標
		bne	iocs_home_error
		move	d0,d1

		cmpi.b	#',',(a0)+
		bne	iocs_home_error

		bsr	call_atoi_a0		;Y 座標
		bne	iocs_home_error
		swap	d1
		move	d0,d1
		swap	d1
iocs_home_error:
		move.l	d1,(graph_home)
		bra	set_graph_home
**		rts


* 表示座標設定 -------------------------------- *

set_graph_home:
		PUSH	d0-d3
		moveq	#3,d1
		bra.s	@f
set_graph_home16:
		PUSH	d0-d3
		moveq	#0,d1
@@:
		move	(home_x,pc),d2
		move	(home_y,pc),d3
set_graph_home_loop:
		IOCS	_SCROLL			;表示座標を設定
		dbra	d1,set_graph_home_loop
		POP	d0-d3
		rts


*************************************************
*		&rotate-gvram-ccw		*
*************************************************

＆rotate_gvram_ccw::
		bsr	check_gusemd_and_abort
		TO_SUPER
		moveq	#3,d0
		and	(VC_R0),d0
		beq	@f

		bsr	rotate_gvram_ccw_64k
		bra	1f
@@:
		bsr	rotate_gvram_ccw_16
1:
		TO_USER
		rts

rotate_gvram_ccw_64k:
		PUSH	d0-d7/a0-a6
		move.l	#GVRAM,d0			;左上
		move.l	#GVRAM+512*2*511,d1		;左下
		move.l	#GVRAM+512*2*511+511*2,d2	;右下
		move.l	#GVRAM+511*2+2,d3		;右上
		move	#512*2,d4

		move	#512-1,d7
rotate_gvram_ccw_64k_loop:
		movea.l	d0,a0
		movea.l	d1,a1
		movea.l	d2,a2
		movea.l	d3,a3

		subq	#1,d7
		move	d7,d6
@@:
		move	(a0),d5			;左上
		move	-(a3),(a0)		;| 右上 -> 左上
		move	(a2),(a3)		;| 右下 -> 右上
		move	(a1),(a2)		;| 左下 -> 右下
		move	d5,(a1)+		;+-------> 左下
		adda	d4,a0
		suba	d4,a2
		dbra	d6,@b

		addi.l	#512*2+2,d0		;++y ++x
		addi.l	#-512*2+2,d1		;--y ++x
		addi.l	#-512*2-2,d2		;--y --x
		addi.l	#512*2-2,d3		;++y --x
		dbra	d7,rotate_gvram_ccw_64k_loop

		POP	d0-d7/a0-a6
		rts

rotate_gvram_ccw_16:
		PUSH	d0-d7/a0-a6

		move	(home_x,pc),d0
		move	(home_y,pc),d1
		addi	#128,d0
		andi	#256,d0
		addi	#256,d1
		andi	#512,d1
		move	d0,d2
		move	d1,d3
		move	d1,d4
		asr	#1,d3
		move	d3,d1
		sub	d2,d3
		add	d3,d3
		addi	#512,d4
		add	d3,d4
		andi	#512,d4
		move	d4,(home_y)
		add	d0,d1
		andi	#511,d1
		add	d1,d0
		andi	#256,d0
		move	d0,(home_x)
		bsr	set_graph_home

		move.l	#GVRAM,d0			;左上
		move.l	#GVRAM+1024*2*1023,d1		;左下
		move.l	#GVRAM+1024*2*1023+1023*2,d2	;右下
		move.l	#GVRAM+1023*2+2,d3		;右上
		move	#1024*2,d4

		move	#1024-1,d7
rotate_gvram_ccw_16_loop:
		movea.l	d0,a0
		movea.l	d1,a1
		movea.l	d2,a2
		movea.l	d3,a3

		subq	#1,d7
		move	d7,d6
@@:
		move	(a0),d5			;左上
		move	-(a3),(a0)		;| 右上 -> 左上
		move	(a2),(a3)		;| 右下 -> 右上
		move	(a1),(a2)		;| 左下 -> 右下
		move	d5,(a1)+		;+-------> 左下
		adda	d4,a0
		suba	d4,a2
		dbra	d6,@b

		addi.l	#1024*2+2,d0		;++y ++x
		addi.l	#-1024*2+2,d1		;--y ++x
		addi.l	#-1024*2-2,d2		;--y --x
		addi.l	#1024*2-2,d3		;++y --x
		dbra	d7,rotate_gvram_ccw_16_loop

		POP	d0-d7/a0-a6
		rts


*************************************************
*		&rotate-gvram-cw		*
*************************************************

＆rotate_gvram_cw::
		bsr	check_gusemd_and_abort
		TO_SUPER
		moveq	#3,d0
		and	(VC_R0),d0
		beq	@f

		bsr	rotate_gvram_cw_64k
		bra	1f
@@:
		bsr	rotate_gvram_cw_16
1:
		TO_USER
		rts

rotate_gvram_cw_64k:
		PUSH	d0-d7/a0-a6
		move.l	#GVRAM,d0			;左上
		move.l	#GVRAM+512*2*511,d1		;左下
		move.l	#GVRAM+512*2*511+511*2+2,d2	;右下
		move.l	#GVRAM+511*2,d3			;右上
		move	#512*2,d4

		move	#512-1,d7
rotate_gvram_cw_64k_loop:
		movea.l	d0,a0
		movea.l	d1,a1
		movea.l	d2,a2
		movea.l	d3,a3

		subq	#1,d7
		move	d7,d6
@@:
		move	(a0),d5			;左上
		move	(a1),(a0)+		;| 左下 -> 左上
		move	-(a2),(a1)		;| 右下 -> 左下
		move	(a3),(a2)		;| 右上 -> 右下
		move	d5,(a3)			;+-------> 右上
		suba	d4,a1
		adda	d4,a3
		dbra	d6,@b

		addi.l	#512*2+2,d0		;++y ++x
		addi.l	#-512*2+2,d1		;--y ++x
		addi.l	#-512*2-2,d2		;--y --x
		addi.l	#512*2-2,d3		;++y --x
		dbra	d7,rotate_gvram_cw_64k_loop

		POP	d0-d7/a0-a6
		rts

rotate_gvram_cw_16:
		PUSH	d0-d7/a0-a6

		move	(home_y,pc),d0
		move	(home_x,pc),d1
		addi	#256,d0
		andi	#512,d0
		asr	#1,d0
		addi	#128,d1
		andi	#256,d1
		add	d1,d1
		move	d0,d2
		move	d1,d3
		move	d1,d4
		asr	#1,d3
		move	d3,d1
		sub	d2,d3
		add	d3,d3
		addi	#512,d4
		add	d3,d4
		andi	#512,d4
		asr	#1,d4
		move	d4,(home_x)
		add	d0,d1
		andi	#511,d1
		add	d1,d0
		andi	#256,d0
		add	d0,d0
		move	d0,(home_y)
		bsr	set_graph_home

		move.l	#GVRAM,d0			;左上
		move.l	#GVRAM+1024*2*1023,d1		;左下
		move.l	#GVRAM+1024*2*1023+1023*2+2,d2	;右下
		move.l	#GVRAM+1023*2,d3		;右上
		move	#1024*2,d4

		move	#1024-1,d7
rotate_gvram_cw_16_loop:
		movea.l	d0,a0
		movea.l	d1,a1
		movea.l	d2,a2
		movea.l	d3,a3

		subq	#1,d7
		move	d7,d6
@@:
		move	(a0),d5			;左上
		move	(a1),(a0)+		;| 左下 -> 左上
		move	-(a2),(a1)		;| 右下 -> 左下
		move	(a3),(a2)		;| 右上 -> 右下
		move	d5,(a3)			;+-------> 右上
		suba	d4,a1
		adda	d4,a3
		dbra	d6,@b

		addi.l	#1024*2+2,d0		;++y ++x
		addi.l	#-1024*2+2,d1		;--y ++x
		addi.l	#-1024*2-2,d2		;--y --x
		addi.l	#1024*2-2,d3		;++y --x
		dbra	d7,rotate_gvram_cw_16_loop

		POP	d0-d7/a0-a6
		rts


*************************************************
*		&turn-gvram-left-and-right	*
*************************************************

＆turn_gvram_left_and_right::
		bsr	check_gusemd_and_abort
		TO_SUPER
		moveq	#3,d0
		and	(VC_R0),d0
		beq	@f

		bsr	turn_gvram_lr_64k
		bra	1f
@@:
		bsr	turn_gvram_lr_16
1:
		TO_USER
		rts

turn_gvram_lr_16:
		bsr	g_off
		bsr	turn_gvram_lr_64k
		bsr	set_access_mode_16
		moveq	#0,d0
		move	(home_x,pc),d0
		divu	#3,d0
		addi	#768,d0
		andi	#1023,d0
		move	d0,(home_x)
		bsr	set_graph_home
		bra	g_on
**		rts

turn_gvram_lr_64k:
		PUSH	d0-d7/a0-a6
		bsr	set_access_mode_64k
		lea	(GVRAM),a0		;左上
		lea	(512*2,a0),a1		;右上
		move	#$200,d4
		move	#$600,d5

		move	#512-1,d7
turn_gvram_lr_64k_loop_y:
		moveq	#512/32/2-1,d6
turn_gvram_lr_64k_loop_x:
	.rept	32
		move	(a0),d0
		move	-(a1),(a0)+
		move	d0,(a1)
	.endm
		dbra	d6,turn_gvram_lr_64k_loop_x
		adda	d4,a0
		adda	d5,a1
		dbra	d7,turn_gvram_lr_64k_loop_y

		POP	d0-d7/a0-a6
		rts


* グラフィック画面表示オフ
g_off:
.if 0
		move	(mion_flag,pc),d0
		bne	@f
.endif
		bsr	_vdisp_wait
		andi	#.not.G_ON,(VC_R2)
@@:		rts

* グラフィック画面表示オン
g_on:
.if 0
		move	(mion_flag,pc),d0
		bne	@f
.endif
		bsr	_vdisp_wait
		ori	#G_ON,(VC_R2)
@@:		rts


*************************************************
*		&turn-gvram-upside-down		*
*************************************************

＆turn_gvram_upside_down::
		bsr	check_gusemd_and_abort
		TO_SUPER
		moveq	#3,d0
		and	(VC_R0),d0
		beq	@f

		bsr	turn_gvram_ud_64k
		bra	1f
@@:
		bsr	turn_gvram_ud_16
1:
		TO_USER
		rts

turn_gvram_ud_16:
		bsr	g_off
		bsr	turn_gvram_ud_64k
		bsr	set_access_mode_16
		bra	g_on
**		rts

turn_gvram_ud_64k:
		PUSH	d0-d7/a0-a6
		bsr	set_access_mode_64k
		lea	(GVRAM),a0		;左上
		lea	(GVRAM+512*2*511),a1	;左下
		move	#-512*2*2,d5

		move	#512/2-1,d7
turn_gvram_ud_64k_loop_y:
		move	#512/32/2-1,d6
turn_gvram_ud_64k_loop_x:
	.rept	32
		move.l	(a0),d0
		move.l	(a1),(a0)+
		move.l	d0,(a1)+
	.endm
		dbra	d6,turn_gvram_ud_64k_loop_x
		adda	d5,a1
		dbra	d7,turn_gvram_ud_64k_loop_y

		POP	d0-d7/a0-a6
		rts


*************************************************
*		&mono=&gvram-to-monochrome	*
*************************************************

＆mono::
＆gvram_to_monochrome::
		bsr	check_gusemd_and_abort
		TO_SUPER
		moveq	#3,d0
		and	(VC_R0),d0
		subq	#3,d0
		bne	@f

		bsr	gvram_to_mono_64k
		bra	1f
@@:
		bsr	gvram_to_mono_256
1:
		TO_USER
		rts

gvram_to_mono_256:
		lea	(GPARH_PAL),a0
		lea	(mono_palet,pc),a2
		lea	(i_table,pc),a4
		move	#256-1,d7
@@:
		bsr	mono_one_color
		addq.l	#2,a0
		dbra	d7,@b
		bra	save_paltbl
**		rts

gvram_to_mono_64k:
		lea	(GVRAM),a0
		lea	(mono_palet,pc),a2
		lea	(i_table,pc),a4
		lea	(a0),a1

		moveq	#8-1,d7
mono_loop1:
		moveq	#8-1,d6
mono_loop2:
		moveq	#64-1,d5
mono_loop3:
		moveq	#64-1,d4
mono_loop4:
		bsr	mono_one_color
		lea	(2*8,a0),a0
		dbra	d4,mono_loop4

		lea	(1024*7,a0),a0
		dbra	d5,mono_loop3

		addq.l	#2,a1
		lea	(a1),a0
		dbra	d6,mono_loop2

		lea	(1024-16,a1),a1
		movea.l	a1,a0
		dbra	d7,mono_loop1
		rts

mono_one_color:
		move	(a0),d0
		lsr	#1,d0
		moveq	#$1f,d1
		and	d0,d1
		move.b	(a4,d1.w),d3

		lsr	#5,d0
		moveq	#$1f,d1
		and	d0,d1
		add.b	(32,a4,d1.w),d3

		lsr	#5,d0
		add.b	(64,a4,d0.w),d3

		lsr	#2,d3
		andi	#31*2,d3
		move	(a2,d3.w),(a0)
		rts


*************************************************
*		&16color-palet-set		*
*************************************************

＆16color_palet_set::
		moveq	#.low._GM_KEEP_PALETTE_GET,d1
		bsr	_gm_internal_tgusemd
		bne	c16_palet_set_end	;gm 未常駐
		tst	d0
		beq	c16_palet_set_end	;常駐パレット無効

		lea	(GTONE_TBL),a0
		moveq	#16/2-1,d0
@@:		move.l	(a1)+,(a0)+		;常駐パレットから読み出す
		dbra	d0,@b
c16_palet_set_end:
		rts


*************************************************
*		&64kcolor-palet-set		*
*************************************************

＆64kcolor_palet_set::
		pea	(set_gtone_64k_max_normal,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		rts


*************************************************
*		&brightness-decrement		*
*************************************************

＆brightness_decrement::
＆16color_brightness_decrement::
		moveq	#TONE_MIN,d1		;限界値
		moveq	#-1,d2			;変動量
		bra.s	brightness_dec_inc


*************************************************
*		&brightness-increment		*
*************************************************

＆brightness_increment::
＆16color_brightness_increment::
		moveq	#TONE_MAX,d1
		moveq	#+1,d2
brightness_dec_inc:
		move	(GTONE,pc),d0
		cmp	d1,d0
		beq	set_status_0		;これ以上変えられない

		add	d2,d0
		pea	(set_gtone_auto,pc)
		DOS	_SUPER_JSR
		addq.l	#4,sp
		bra	set_status_1
**		rts


*************************************************
*		&half=&set-brightness-to-half	*
*************************************************

＆half::
＆set_brightness_to_half::
		bsr	half_max
*half_job:
		beq	half_64k
*half_16_256:
		moveq	#TONE_HALF,d4
		bsr	gtone_set256
		moveq	#T_ON+G_ON,d0
		rts
half_64k:
		bsr	half_max_64k_sub
		move	#G_HALF_ON+T_ON,d0
		rts


*************************************************
*		&max=&set-brightness-to-max	*
*************************************************

＆max::
＆set_brightness_to_max::
		bsr	half_max
*max_job:
		beq	max_64k
*max_16_256:
		bsr	load_paltbl
		bra	max_job_end
max_64k:
		bsr	set_gtone_64k_max_normal
		bsr	half_max_64k_sub
max_job_end:
		moveq	#T_ON+G_ON,d0
		rts


half_max_64k_sub:
		bclr	#3,(CRTC_R20h)		;斜線嵐防止
		bra	center_64k_graphic_gm
**		rts


half_max:
		movea.l	(sp)+,a0		;メイン処理
		TO_SUPER
.if 0
		moveq	#G_ON,d0
		and	(VC_R2),d0
		beq	half_max_end		;グラフィック無表示なら何もしない
.endif
		bsr	mioff_sub

		bsr	is_graphic_64k
		jsr	(a0)
		move	d0,(VC_R2)
half_max_end:
		TO_USER
		bra	＆palet0_system
**		rts


*************************************************
*		&mion=&gvram-text-blend-on	*
*************************************************

＆mion::
＆gvram_text_blend_on::
		pea	(set_status,pc)
		bra	mion
**		rts


* &mion 下請け
* out	d0.l	1:正常終了 0:エラー(既に &mion 中だった)
*	ccr	<tst.l d0> の結果
*	mion_sub は必ずスーパバイザモードで呼び出すこと.

mion:
		bsr	mion_mioff
mion_sub:
		PUSH	d1-d7/a0-a6
		lea	(mion_flag,pc),a0
		tas	(a0)
		bne	mion_sub_error		;既に &mion 中ならエラー

		bsr	＆palet0_set
		bsr	is_graphic_64k_vw
		beq	mion_sub_64k
*mion_sub_16_256:
		moveq	#TONE_NORMAL,d4
		bsr	gtone_set256
		bra	@f
mion_sub_64k:
		bsr	set_gtone_64k_max_normal
		bsr	center_64k_graphic
@@:
		bclr	#3,(CRTC_R20h)		;斜線嵐防止
		move	#$24e4,(VC_R1)		;GR(G3>G2>G1>G0)>TX>SP
		move	#G_HALF_ON+S_ON+T_ON,(VC_R2)

		moveq	#1,d0
mion_sub_end:
		POP	d1-d7/a0-a6
		rts
mion_sub_error:
		moveq	#0,d0
		bra	mion_sub_end


mion_mioff:
		DOS	_SUPER_JSR
		addq.l	#4,sp
		rts


*************************************************
*		&mioff=&gvram-text-blend-off	*
*************************************************

＆mioff::
＆gvram_text_blend_off::
		pea	(set_status,pc)
		bra	mioff
**		rts


* &mioff 下請け
* out	d0.l	1:正常終了 0:エラー(&mion 中ではなかった)
*	ccr	<tst.l d0> の結果
* 注意:
*	mioff_sub は必ずスーパバイザモードで呼び出すこと.

mioff:
		bsr	mion_mioff
mioff_sub:
		PUSH	d1-d7/a0-a6
		lea	(mion_flag,pc),a0
		lsl	(a0)
		bcc	mioff_sub_error		;&mion 中でないならエラー

		bsr	＆palet0_system
		bsr	is_graphic_64k_vw
		bne	@f			;16/256 色は VC 操作のみ
*mioff_sub_64k:
		bsr	set_gtone_64k_max_normal
		bsr	center_64k_graphic_gm
@@:
		move	#$06e4,(VC_R1)			;SP>TX>GR(G3>G2>G1>G0)
		move	#G_HALF_ON+T_ON,(VC_R2)

		moveq	#1,d0
mioff_sub_end:
		POP	d1-d7/a0-a6
		rts
mioff_sub_error:
		moveq	#0,d0
		bra	mioff_sub_end


* Subroutine ---------------------------------- *

is_graphic_64k_vw:
		bsr	_vdisp_wait
is_graphic_64k:
		moveq	#3,d0
		and	(VC_R0),d0
		subq	#3,d0
		rts


center_256_graphic::
center_64k_graphic:
		move.l	#0<<16+384,(graph_home)
		bra	set_graph_home
**		rts

center_64k_graphic_gm:
		bsr	center_64k_graphic
		bra	_gm_mask_request
**		rts


_gm_mask_request:
		move.l	d1,-(sp)
		moveq	#.low._GM_AUTO_STATE,d1
		bsr	_gm_internal_tgusemd
		bne	@f			;gm 未常駐
		subq	#MASK_ENABLE,d0
		bne	@f			;オートマスク禁止

		moveq	#.low._GM_MASK_SET,d1
		bsr	_gm_internal_tgusemd
@@:
		move.l	(sp)+,d1
		rts


_gm_auto_mask:
		PUSH	d1-d2
		moveq	#G_ON,d2

		moveq	#.low._GM_AUTO_STATE,d1
		bsr	_gm_internal_tgusemd
		bne	gm_auto_mask_end	;gm 未常駐

		subq	#MASK_ENABLE,d0
		beq	gm_auto_mask_enable	;オートマスク許可
		tst	(＄sqms)
		beq	gm_auto_mask_end

		moveq	#.low._GM_AUTO_ENABLE,d1
		bsr	_gm_internal_tgusemd	;%sqms 1 なら強制的にマスクする
		moveq	#.low._GM_MASK_SET,d1
		bsr	_gm_internal_tgusemd
		moveq	#.low._GM_AUTO_DISABLE,d1
		bra	@f
gm_auto_mask_enable:
		moveq	#.low._GM_MASK_SET,d1
@@:		bsr	_gm_internal_tgusemd

		moveq	#T_ON+G_ON,d2
gm_auto_mask_end:
		move	d2,(VC_R2)
		POP	d1-d2
		rts


_gm_internal_tgusemd::
		swap	d1
		move	#_GM_INTERNAL_MODE,d1
		swap	d1
		IOCS	_TGUSEMD
		subi	#_GM_INTERNAL_MODE,d0
		bne	@f
		swap	d0
		cmp	d0,d0			;ccrZ=1
@@:
		rts


* GVRAM 使用可能検査 -------------------------- *

check_gusemd_and_abort:
		bsr	check_gusemd
		beq	set_status_1		;GVRAM 使用可能

		addq.l	#4,sp			;使用中なら呼び出し元の親に直接戻る

		moveq	#MES_G_USE,d0
		jsr	(PrintMsgCrlf)
set_status_0:
		moveq	#0,d0
		bra	set_status
set_status_1:
		moveq	#1,d0
set_status:
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts


* GVRAM の使用状況を調べる
* out	d0.l	 0:使用可能(占有されていない)
*		-1:使用不可能(占有されている)
*	ccr	<tst.l d0> の結果

check_gusemd::
		PUSH	d1-d2
		tst	(＄grm！)
		bne	check_gusemd_ok		;強制的に使用する

		move.l	#_GM_INTERNAL_MODE<<16+0,d1
		moveq	#-1,d2			;使用状況の収得
		IOCS	_TGUSEMD
		subq.b	#1,d0
		subq.b	#2,d0
		bcc	check_gusemd_ok		;未使用

		moveq	#-1,d0			;使用中だった
		bra	@f
check_gusemd_ok:
		moveq	#0,d0
@@:
		POP	d1-d2
		rts


* スクエアモード収得 -------------------------- *

gm_check_square::
		PUSH	d0/a0
		TO_SUPER
		lea	(CRTC_R20),a0
		cmpi.b	#3,(a0)+
		bne	@f			;64K 色モードでなければ変更しない

		cmpi.b	#$16,(a0)
		lea	(sq64k,pc),a0
		seq	(a0)			;768x512 ならスクエアモード
@@:
		TO_USER
		POP	d0/a0
		rts


* CRT モード変更 ------------------------------ *
* in	d0.w	モード番号
*	d1.w	メモリアクセスモード(負で前回の変更値)

set_crt_mode16:
		moveq	#4,d1
		bra	set_crt_mode
set_crt_mode_nc:
		moveq	#-1,d1
set_crt_mode:
		PUSH	a0-a1
		move	d0,(gvon_crtmode)
		tst	d1
		bpl	@f
		move	(gvon_color,pc),d1
@@:		move	d1,(gvon_color)

		mulu	#(9+1+1)*2,d0
		lea	(crtc_settings,pc,d0.w),a0
		lea	(CRTC),a1
		bsr	_vdisp_wait
		move	#9-1,d0
@@:
		move	(a0)+,(a1)+		;CRTC R00～R08
		dbra	d0,@b

		move	d1,(VC_R0)

		move	(a0)+,d0
		lsl	#8,d1
		or	d1,d0
		move	d0,(CRTC_R20)
		tst	(a0)
		beq	@f
		HRL_ON
		bra	set_crt_mode_end
@@:
		HRL_OFF
set_crt_mode_end:
		POP	a0-a1
		rts


crtc_settings:
*		Httl HSed HDst HDed Vttl VSed VDst VDed Hadj MODE  HRL
	.dc	137,  14,  28, 124, 567,   5,  40, 552,  27,  $16,  0	;0 31kHz,768×512
	.dc	137,  14,  24, 120, 259,   2,  16, 256,  44,  $19,  1	;1 15kHz,768×512
	.dc	 91,   9,  17,  81, 567,   5,  40, 552,  27,  $15,  0	;2 31kHz,512×512
	.dc	 75,   3,   5,  69, 259,   2,  16, 256,  44,  $05,  0	;3 15kHz,512×512
	.dc	 67,   6,  12,  60, 567,   5,  40, 552,  27,  $11,  1	;4 31kHz,384×256
	.dc	 67,   6,   9,  57, 259,   2,  16, 256,  36,  $14,  1	;5 15kHz,384×256
	.dc	 45,   4,   6,  38, 567,   5,  40, 552,  27,  $10,  0	;6 31kHz,256×256
	.dc	 37,   1,   0,  32, 259,   2,  16, 256,  36,  $00,  0	;7 15kHz,256×256
	.dc	115,   8,  20, 100, 464,   7,  40, 440,  27,  $15,  0	;8 24kHz,640×400
	.dc	 56,   7,  10,  50, 464,   7,  40, 440,  27,  $10,  0	;9 24kHz,320×200
	.dc	179,  12,  29, 157, 464,   8,  33, 457,  27,  $1e,  0	;a 24kHz,1024×848
	.dc	137,  14,  28, 124, 567,   5,  40, 552,  27,  $1e,  0	;b 31kHz,768×1024


* Data Section -------------------------------- *

*		.data
		.even

mono_palet:	.dc	$0200,$0a02,$1244,$1a86,$2288,$2aca,$330c,$3b4e
		.dc	$4350,$4b92,$53d4,$5c16,$6418,$6c5a,$749c,$7cde
		.dc	$84e0,$8d22,$9564,$9d66,$a5a8,$adea,$b62c,$be2e
		.dc	$c670,$ceb2,$d6f4,$def6,$e738,$ef7a,$f7bc,$fffe

i_table:
* Blue
		.dc.b	 0,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14
		.dc.b	14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
* Red
		.dc.b	 0,  2,  4,  7,  9, 12, 14, 17, 19, 22, 24, 26, 29, 31, 34, 36
		.dc.b	39, 41, 44, 46, 49, 51, 53, 56, 58, 61, 63, 66, 68, 71, 73, 76
* Greed
		.dc.b	 0,  4,  9, 14, 19, 24, 29, 33, 38, 43, 48, 53, 58, 62, 67, 72
		.dc.b	77, 82, 87, 91, 96,101,106,111,116,120,125,130,135,140,145,150

		.even
gvon_color:	.dc	-1
sq64k::		.dc.b	-1
buffer_avail:	.dc.b	0


* キーバインド関係 ---------------------------- *

bind_token:
		.dc.b	'nop',0
		.dc.b	'change-mode',0
		.dc.b	'quit-with-zoomed',0
		.dc.b	'quit-with-original',0
		.dc.b	'quit-with-gvram-off',0
		.dc.b   'monochrome',0
		.dc.b	'rotate-ccw',0
		.dc.b	'rotate-cw',0
		.dc.b	'turn-left-and-right',0
		.dc.b	'turn-upside-down',0
		.dc.b	'brightness-decrement',0
		.dc.b	'brightness-increment',0
		.dc.b	'brightness-reset',0
		.dc.b	'toggle-square',0
		.dc.b	'toggle-frequency',0
		.dc.b	'reset-position',0
		.dc.b	'toggle-position',0
		.dc.b	'zoom-in',0
		.dc.b	'zoom-out',0
		.dc.b	'scroll-left',0
		.dc.b	'scroll-right',0
		.dc.b	'scroll-up',0
		.dc.b	'scroll-down',0
		.dc.b	'shift-left-up',0
		.dc.b	'shift-left',0
		.dc.b	'shift-left-down',0
		.dc.b	'shift-up',0
		.dc.b	'shift-down',0
		.dc.b	'shift-right-up',0
		.dc.b	'shift-right',0
		.dc.b	'shift-right-down',0
		.dc.b	0

key_token::
	.dc.b	'DUMY',0,'ESC' ,0,'_1'  ,0,'_2'  ,0,'_3'  ,0,'_4'  ,0,'_5'  ,0,'_6',0
	.dc.b	'_7'  ,0,'_8'  ,0,'_9'  ,0,'_0'  ,0,'_-'  ,0,'_^'  ,0,'_\'  ,0,'BS',0
	.dc.b	'TAB' ,0,'_Q'  ,0,'_W'  ,0,'_E'  ,0,'_R'  ,0,'_T'  ,0,'_Y'  ,0,'_U',0
	.dc.b	'_I'  ,0,'_O'  ,0,'_P'  ,0,'_@'  ,0,'_['  ,0,'RET' ,0,'_A'  ,0,'_S',0
	.dc.b	'_D'  ,0,'_F'  ,0,'_G'  ,0,'_H'  ,0,'_J'  ,0,'_K'  ,0,'_L'  ,0,'_;',0
	.dc.b	'_:'  ,0,'_]'  ,0,'_Z'  ,0,'_X'  ,0,'_C'  ,0,'_V'  ,0,'_B'  ,0,'_N',0
	.dc.b	'_M'  ,0,'_,'  ,0,'_.'  ,0,'_/'  ,0,'__'  ,0,'SPC' ,0,'HOME',0,'DEL',0
	.dc.b	'RUP' ,0,'RDOWN',0,'UNDO',0,'←' ,0,'↑'  ,0,'→'  ,0,'↓'  ,0,'CLR',0
	.dc.b	't/'  ,0,'t*'  ,0,'t-'  ,0,'t7'  ,0,'t8'  ,0,'t9'  ,0,'t+'  ,0,'t4',0
	.dc.b	't5'  ,0,'t6'  ,0,'t='  ,0,'t1'  ,0,'t2'  ,0,'t3'  ,0,'ENT' ,0,'t0',0
	.dc.b	't,'  ,0,'t.'  ,0,'記号',0,'登録',0,'HELP',0,'XF1' ,0,'XF2' ,0,'XF3',0
	.dc.b	'XF4' ,0,'XF5' ,0,'かな',0,'ﾛｰﾏ' ,0,'ｺｰﾄﾞ',0,'CAPS',0,'INS' ,0,'ひら',0
	.dc.b	'全角',0,'BREAK',0,'COPY',0,'F0' ,0,'F1'  ,0,'F2'  ,0,'F3'  ,0,'F4',0
	.dc.b	'F5'  ,0,'F6'  ,0,'F7'  ,0,'F8'  ,0,'F9'  ,0,0

key_table:
	.dc.b	K_NULL,	K_QOFF,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL	;$0
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL	;$1
	.dc.b	K_NULL,	K_QORG,	K_NULL,	K_NULL,	K_RCW,	K_NULL,	K_NULL,	K_NULL	;$2
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_QZOM,	K_NULL,	K_SQU	;$3
	.dc.b	K_NULL,	K_NULL,	K_CHMD,	K_HREV,	K_NULL,	K_NULL,	K_RCCW,	K_NULL	;$4
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_VREV,	K_NULL,	K_NULL	;$5
	.dc.b	K_MONO,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_QORG,	K_PRES,	K_NULL	;$6
	.dc.b	K_ZOUT,	K_ZIN,	K_FREQ,	K_LEFT,	K_UP,	K_RIGHT,K_DOWN,	K_PTOG	;$7
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_T7,	K_T8,	K_T9,	K_NULL,	K_T4	;$8
	.dc.b	K_NULL,	K_T6,	K_NULL,	K_T1,	K_T2,	K_T3,	K_QORG,	K_NULL	;$9
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_BDEC,	K_BINC,	K_BRES	;$a
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL	;$b
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL	;$c
	.dc.b	K_NULL,	K_NULL,	K_NULL,	K_NULL,	K_NULL				;$d


* Block Storage Section ----------------------- *

*		.bss
		.even

graph_home::
home_y:		.ds	1
home_x:		.ds	1
home_backup:	.ds.l	1

zoom_offset:
offset_y:	.ds	1
offset_x:	.ds	1

offset_max_x:	.ds	1
offset_min_x:	.ds	1
offset_max_y:	.ds	1

zoom_width:	.ds	1
zoom_rest:	.ds	1
zoom_w1:	.ds	1
zoom_w2:	.ds	1
offs_right_pl:	.ds	1
offs_right_mi:	.ds	1

GTONE::		.ds	1

wait_speed:	.ds	1
wait_remain:	.ds	1
wait_zoom:	.ds	1
gvon_crtmode:	.ds	1

mion_flag::	.ds	1			;bit15=1:&mion

HighCol:	.ds.b	1
Hfreq_low:	.ds.b	1
mode_flag:	.ds.b	1
zoom_factor:	.ds.b	1
GVON24_flag::	.ds.b	1


* 以下は本当の BSS ---------------------------- *

		.bss
		.even

GTONE_TBL:	.ds	256


		.end

* End of File --------------------------------- *
