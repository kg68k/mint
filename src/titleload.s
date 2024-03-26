# titleload.s - &title-load, &pop-text
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
		.include	sysval.def

		.include	doscall.mac
		.include	iocscall.mac
		.include	gm_internal.mac


* Global Symbol ------------------------------- *

* fileop.s
		.xref	iocs_b_keyinp
* madoka3.s
		.xref	＠buildin,＠status
* mint.s
		.xref	malloc_mode
* outside.s
		.xref	atoi_a0


* Constant ------------------------------------ *

MAG_MAX:	.equ	1024<<16+1024
MIT_MAX:	.equ	(1024-8)<<16+(512-4)

COL_MIT_4:	.equ	-2
COL_MIT_16:	.equ	-1

COL_AUTO:	.equ	0
COL_4:		.equ	1
COL_8:		.equ	2
COL_16:		.equ	3

* あまり大きな画像は表示できない
MIT_EXT_BUF0:	.equ	TVRAM_P0+128*512
MIT_EXT_BUF1:	.equ	TVRAM_P1+128*512
MIT_EXT_BUF2:	.equ	TVRAM_P2+128*512
MIT_EXT_BUF3:	.equ	TVRAM_P3+128*512


* Offset Table -------------------------------- *

**		.offsym	0,~offs_tbl
		.offset	-256*4
~work_top:
~hv_tbl_l:	.ds.l	256
~offs_tbl:	.ds	15			;ここを基点にする
~hv_tbl_h:	.ds.l	256
~flag_buf:	.ds.b	128
~palet_buf:	.ds	16
~file_name:
~file_buf_ptr:	.ds.l	1
~ext_buf_ptr:
~pos_x:		.ds	1			;~ext_buf_ptr と共用
~pos_y:		.ds	1
~max_xy:	.ds	2
~opt_flags:
~color_mode:	.ds.b	1			;0=自動 1,2,3=4/8/16 色 -2,-1=4/16 色
~black_flag:	.ds.b	1			;-b(不透明の黒)
~pos_flags:
~pos_x_flag:	.ds.b	1			;-l(表示座標指定) x 座標
~pos_y_flag:	.ds.b	1			;		  y 座標
~no_wait_flag:	.ds.b	1			;-n(キー待ちなし)
~file_mode:	.ds.b	1			;$ff:$MINTTITLE の表示中
		.even
~work_end:
sizeof_work:	.equ	~work_end-~work_top


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


*************************************************
*		$MINTTITLE 表示			*
*************************************************

tpal_save_buf:
**		.ds	16			;容量に注意！

env_minttitle:	.dc.b	'MINTTITLE',0
		.even

title_load_minttitle::
		lea	(-256,sp),sp
		lea	(sp),a0

		pea	(a0)
		clr.l	-(sp)
		pea	(env_minttitle,pc)
		DOS	_GETENV
		addq.l	#12-4,sp
		move.l	d0,(sp)+
		bmi	@f			;$MINTTITLE 未設定
* ここまでで 16.w
		moveq	#1,d0
		bsr	title_load_sub
@@:
		lea	(256,sp),sp
		rts


*************************************************
*		&title-load			*
*************************************************

＆title_load::
		moveq	#0,d0
		bsr	title_load_sub
		move	d0,(＠buildin)
		move	d0,(＠status)
		rts


* .mag/.mit 表示 ------------------------------ *
*
* in	d0.l	モード
*		d0 = 0: ＆title_load からの起動
*		d0 = 1: title_load_minttitle からの起動
* in	a0.l	(d0 = 0 の時)引数列のアドレス
*		(d0 = 1 の時)ファイル名
* out	d0.l	0:エラー 1:正常終了

title_load_sub:
		PUSH	d1-d7/a0-a5
		lea	(-sizeof_work,sp),sp
		lea	(~offs_tbl-~work_top,sp),a5
		clr.l	(~opt_flags,a5)

		move.l	d0,(~file_name,a5)
		sne	(~file_mode,a5)		;$MINTTILE 表示モード
		sne	(~no_wait_flag,a5)
		beq	@f
		move.l	a0,(~file_name,a5)
@@:
		bsr	＆pop_text

		tst.b	(~file_mode,a5)
		bne	no_arg			;引数はない
		tst.l	d7
		beq	_error			;引数なし
arg_loop:
		move.b	(a0)+,d0
		beq	arg_next
		cmpi.b	#'-',d0
		beq	option
		subq.l	#1,a0			;ファイル名
		move.l	a0,(~file_name,a5)
skip_arg:
		tst.b	(a0)+
		bne	skip_arg
		bra	arg_next
option:
		move.b	(a0)+,d0
		cmpi.b	#'b',d0
		beq	option_b
		cmpi.b	#'c',d0
		beq	option_c
		cmpi.b	#'l',d0
		beq	option_l
		cmpi.b	#'n',d0
		beq	option_n
		subi.b	#'1',d0
		bne	@f
		moveq	#COL_16,d1
		cmpi.b	#'6',(a0)+		;-16 : 強制 16 色表示
		bra	option_col0
@@:
		moveq	#COL_4,d1
		subq.b	#'4'-'1',d0		;-4 : 強制 4 色表示
		beq	option_col
		moveq	#COL_8,d1
		subq.b	#'8'-'4',d0		;-8 : 強制 8 色表示
option_col0:
		bne	_error
option_col:
		move.b	d1,(~color_mode,a5)
		bra	option_check_tail

option_b:
		not.b	(~black_flag,a5)	;-b : 透明な黒を不透明な黒にする
		bra	option_check_tail
option_n:
		not.b	(~no_wait_flag,a5)	;-n : キー待ちなし
		bra	option_check_tail
option_c:
		move	#$01_01,(~pos_flags,a5)
		bra	option_check_tail	;-c : 中央に表示する


call_atoi_a0:
		jmp	(atoi_a0)
**		rts

option_l:
		move.b	(a0)+,d0		;-l[x][,y] : 表示座標指定
		bne	@f
		clr	(~pos_flags,a5)		;-l のみ
		bra	arg_next
@@:		cmpi.b	#',',d0
		beq	option_l_y

		subq.l	#1,a0
		st	(~pos_x_flag,a5)	;x 座標の指定あり
		jsr	call_atoi_a0
		bne	_error
		move	d0,(~pos_x,a5)
		move.b	(a0)+,d0
		beq	arg_next
		cmpi.b	#',',d0
		bne	_error
option_l_y:
		st	(~pos_y_flag,a5)	;y 座標の指定あり
		bsr	call_atoi_a0
		bne	_error
		move	d0,(~pos_y,a5)
		bra	option_check_tail

_error:		bra	error

option_check_tail:
		tst.b	(a0)+
		bne	_error			;後に何か付いてればエラー
		bra	arg_next
arg_next:
		subq.l	#1,d7
		bhi	arg_loop
no_arg:
		move.l	(~file_name,a5),d0
		beq	_error			;ファイル名無指定

		clr	-(sp)
		move.l	d0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d7
		bmi	_error			;ファイルがオープン出来ない

		move.l	d7,-(sp)
		jbsr	_filelength
		move.l	d0,(sp)+
		bmi	_error2
		move.l	d0,d5			;ファイルサイズ

		lea	(~flag_buf,a5),a0	;流用
		moveq	#32,d1			;チェックデータ＋作者名を読む
		move.l	d1,-(sp)
		pea	(a0)
		move	d7,-(sp)
		DOS	_READ
		addq.l	#10-4,sp
		cmp.l	(sp)+,d0
		bne	_error2

		move.l	#MAG_MAX,d6
		lea	(a0),a1			;画像形式の判別
		cmpi.l	#'MAKI',(a1)+
		bne	@f
		cmpi.l	#'02  ',(a1)+
		beq	skip_comment		;MAKI02
@@:		move.l	(a0),d0
		subi.l	#'HK03',d0
		subq.l	#1,d0
		bhi	_error2			;未対応の形式

		move.l	#MIT_MAX,d6
		subq.b	#1,d0			;'HK03' -> -2
		move.b	d0,(~color_mode,a5)	;'HK04' -> -1

		moveq	#4,d1			;ヘッダ直後にシーク
		clr	-(sp)
		move.l	d1,-(sp)
		move	d7,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bpl	skip_comment

_error2:	bra	error2

skip_comment:
		move.l	d6,(~max_xy,a5)
		sub.l	d1,d5
		moveq	#EOF,d1
skip_comment_loop:
		move	d7,-(sp)		;コメントを読み捨てる
		DOS	_FGETC
		addq.l	#2,sp
		tst.l	d0
		bmi	_error2
		subq.l	#1,d5
		cmp.b	d0,d1
		bne	skip_comment_loop

		move.b	(~color_mode,a5),d1
		bpl	@f

		move	d7,-(sp)		;.mit のプレーン数を調べる
		DOS	_FGETC
		addq.l	#2,sp
		neg.b	d1
		moveq	#8,d2			;COL_MIT_16 -> 4
		lsr.b	d1,d2			;COL_MIT_4  -> 2
		cmp.l	d0,d2
		bne	_error2			;プレーン数が違う
		subq.l	#1,d5
@@:
		move.l	d5,-(sp)		;ファイル読み込みバッファを確保
		moveq	#2,d0
		cmp	(malloc_mode),d0	;むー
		bne	@f
		moveq	#0,d0
@@:		move	d0,-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		move.l	d0,(~file_buf_ptr,a5)
		bmi	_error2
		movea.l	d0,a0

		move.l	d5,-(sp)		;残り全部を読み込む
		pea	(a0)
		move	d7,-(sp)
		DOS	_READ
		move.l	d0,d1
		DOS	_CLOSE
		addq.l	#10-4,sp
		cmp.l	(sp)+,d1
		bne	error3

		lea	(a0),a1
		move.b	(~color_mode,a5),d1
		bmi	color_ok		;.mit なら確定

		lea	(3,a0),a1
		move.b	(a1)+,d0		;スクリーンモード
		bmi	error3			;256 色モードは不可
		tst.b	d1
		bne	color_ok		;指定済み

		lea	(32,a0),a2		;パレット
		lsr.b	#2,d0			;8 色フラグ
		bcs	color_4or8		;絶対に 8 色以下(と見なす)

		moveq	#COL_16,d1
		lea	(3*0,a2),a3		;パレット 0～7 と 8～15 を比較する
		lea	(3*8,a2),a4
		moveq	#3*8/4-1,d0
@@:		cmpm.l	(a3)+,(a4)+
		dbne	d0,@b
		bne	color_set		;違うので 16 色
color_4or8:
		lea	(3*4,a2),a3		;パレット 0～3 と 4～7 を比較する
		moveq	#3*4/4-1,d0
@@:		cmpm.l	(a2)+,(a3)+
		dbne	d0,@b
		seq	d1			;同じなら 4 色($ff + COL_8 = COL_4)
		addq.b	#COL_8,d1		;違うなら 8 色
		.fail	.low.(COL_8+$ff).ne.COL_4
color_set:
		move.b	d1,(~color_mode,a5)
color_ok:
		lea	(x_len,pc),a2
		tst.b	d1
		bpl	@f
		add.b	d1,d1
		addq.b	#COL_16-COL_MIT_16*2,d1
@@:		move.b	d1,(color_mode-x_len,a2)

		bsr	get_pos_size		;表示座標/サイズ収得
		move.l	(~max_xy,a5),d6
		cmp	d6,d4			;画像サイズの検査
		bhi	@f
		swap	d6
		cmp	d6,d3
@@:		bhi	error3

		move.b	(~pos_x_flag,a5),d0
		beq	no_pos_x_chg
		move	(~pos_x,a5),d1		;指定された座標に変更する
		tst.b	d0
		bmi	@f
		move	#768,d1
		sub	d3,d1
		lsr	#1,d1			;センタリング
@@:		andi	#.not.%0000_0111,d1
no_pos_x_chg:
		move.b	(~pos_y_flag,a5),d0
		beq	no_pos_y_chg
		move	(~pos_y,a5),d2		;指定された座標に変更する
		tst.b	d0
		bmi	@f
		move	#512,d2
		sub	d4,d2
		lsr	#1,d2			;センタリング
@@:
no_pos_y_chg:
		move	d6,d7			;表示座標の補正
		sub	d3,d6
		sub	d1,d6
		bcc	@f
		add	d6,d1			;X 座標を左にずらす
@@:		sub	d4,d7
		sub	d2,d7
		bcc	@f
		add	d7,d2			;X 座標を左にずらす
@@:
		move	d3,d5
		lsr	#3,d5
		subq	#1,d5			;d5 = ピクセル数 / 2 - 1
*		lea	(x_len,pc),a2
		movem	d3-d4/d5,(a2)

		move	d3,d6			;テキスト保存バッファを確保
		mulu	d4,d6
		move.l	d6,d0			;1dot = 4bit = 1/2byte だが、マウス
		lsr.l	#2,d0			;プレーンは保存しないので更にその半分
		move.l	d4,d7
		lsl.l	#2,d7
		add.l	d7,d0			;余分(1 ラインにつき 2*2=4 バイト必要)
		bsr	malloc
		move.l	d0,-(a2)		;text_save_buf
		bmi	error3

		tst.b	(~color_mode,a5)
		bmi	@f
		move.l	d6,d0			;展開バッファを確保
		bsr	malloc			;1dot = 1byte 必要
		move.l	d0,(~ext_buf_ptr,a5)
		bmi	error4
@@:

.ifdef CLR_BY_TXFILL
		lea	(txfill_buf,pc),a3	;IOCS _TXFILL のパラメータを設定
		moveq	#%0100,d5
		move.b	(color_mode,pc),d0
		subq.b	#COL_8,d0
		scc	(a3)+
		beq	@f
		moveq	#%1100,d5
@@:		move.b	d5,(a3)+
		movem	d1-d4,(a3)
.endif

		bsr	get_flag_adr
		bsr	conv_palette

		lea	(TVRAM_P0),a0		;左上 TVRAM アドレスを計算
		move.l	d2,d0
		lsl.l	#7,d0
		adda.l	d0,a0			;y*128
		move	d1,d0
		lsr	#3,d0
		adda	d0,a0			;x/8
		move.l	a0,(text_adr)

* .mit のデコードで TVRAM をバッファに使用しているので
* ここでスーパーバイザになる必要がある.
		TO_SUPER
		bsr	decode_to_buf		;バッファに展開する
		bsr	mfree_file_buf
		bsr	clear_graphic_mask
*		TO_SUPER
		bsr	save_tvram
		bsr	save_text_palette
		bsr	set_text_palette

		bsr	ext_to_tvram		;中間形式のデータを TVRAM に展開する

		TO_USER
		tst.b	(~color_mode,a5)
		bmi	@f
		bsr	mfree_ext_buf
@@:
		tst.b	(~no_wait_flag,a5)
		bne	skip_key_wait		;キー待ちしない

		jsr	(iocs_b_keyinp)
		bsr	＆pop_text
skip_key_wait:
		moveq	#1,d0			;正常終了
		bra	title_load_sub_end


error4:
		bsr	mfree_text_save_buf
error3:
		bsr	mfree_file_buf
		bra	@f
error2:
		move	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
		bra	@f
error:
@@:		moveq	#0,d0
title_load_sub_end:
		lea	(sizeof_work,sp),sp
		POP	d1-d7/a0-a5
		rts


*************************************************
*		&pop-text			*
*************************************************

＆pop_text::
		move.l	(text_save_buf,pc),d0
		ble	pop_text_end

		PUSH	d1-d7/a0-a5
		TO_SUPER
		bsr	restore_tvram
		bsr	restore_text_palette
		TO_USER
		bsr	draw_graphic_mask
		bsr	mfree_text_save_buf
		POP	d1-d7/a0-a5
pop_text_end:
		rts


* Subroutine ---------------------------------- *

mfree_text_save_buf:
		lea	(text_save_buf,pc),a0
		move.l	(a0),-(sp)
		clr.l	(a0)
		bra	@f
mfree_ext_buf:
		move.l	(~ext_buf_ptr,a5),-(sp)
		bra	@f
mfree_file_buf:
		move.l	(~file_buf_ptr,a5),-(sp)
@@:		DOS	_MFREE
		addq.l	#4,sp
		rts

malloc:
		move.l	d0,-(sp)
		move	(malloc_mode),-(sp)
		bne	@f
		tst.b	(~file_mode,a5)
		beq	@f
		addq	#2,(sp)			;メモリ分断対策
@@:		DOS	_MALLOC2
		addq.l	#6,sp
		rts


* パレットデータを X680x0 形式に変換する.
* in	a1.l	パレットデータ
* out	a1.l	+= パレットサイズ
* 備考:
* .mit の場合は最初から X680x0 形式になっているので、
* -b オプションの処理のみ行う.

conv_palette:
		PUSH	d0-d1/d6-d7/a0
		lea	(~palet_buf,a5),a0
		moveq	#16-1,d0
		moveq	#1,d6
		and.b	(~black_flag,a5),d6	;-b 指定時は d6=1
		move.b	(~color_mode,a5),d7
		bmi	conv_pal_mit		;.mit 表示モード
conv_pal_loop:
		move.b	(a1)+,d1
		lsl	#5,d1			;%xx_xxxG_GGGG_ggg0_0000
		move.b	(a1)+,d1
		lsl.l	#5,d1			;%GG_GGGR_RRRR_rrr0_0000
		move.b	(a1)+,d1
		lsr.l	#3,d1			;%0GGG_GGRR_RRRB_BBBB
		add	d1,d1
		bne	@f
		move	d6,d1			;-b 指定時は $0001 にする
@@:		move	d1,(a0)+		;%GGGG_GRRR_RRBB_BBB0
		dbra	d0,conv_pal_loop
conv_pal_end:
		POP	d0-d1/d6-d7/a0
		rts

conv_pal_mit:
		addq.b	#-COL_MIT_16,d7
		beq	conv_pal_mit_loop	;16 色
		moveq	#4-1,d0			;4 色
conv_pal_mit_loop:
		move	(a1)+,d1
		bne	@f
		move	d6,d1			;-b 指定時は $0001 にする
@@:		move	d1,(a0)+
		dbra	d0,conv_pal_mit_loop
		bra	conv_pal_end


* 変換済みパレットデータを設定する.
set_text_palette:
		PUSH	d0-d2/a0-a3
		tst	(＄tplt)		;この変数は意味あるのか？
		bne	set_text_pal_end

		lea	(TEXT_PAL),a0
		lea	(~palet_buf,a5),a1
		moveq	#0,d0
		move.b	(color_mode,pc),d0
		move.b	(text_pal_tbl-COL_4,pc,d0.w),d0
		lea	(8*2,a0),a2		;後で使う
		lea	(a1),a3			;
		move	d0,d2			;
@@:
		move.l	(a1)+,(a0)+
		dbra	d0,@b

		cmpi	#16/2-1,d2
		beq	set_text_pal_end	;16 色
		moveq	#.low._GM_MASK_STATE,d1
		bsr	gm_tgusemd
		bne	set_text_pal_end	;GM 未常駐
		tst.l	d0
		beq	set_text_pal_end	;マスクなし

* 4/8 色でマスクがかかっている場合は、パレット
* 0～3/7 と同じ色をパレット 8～11/15 にも設定する
		tst	(a3)			;パレット 0 の内容が $0000 なら
		bne	@f			;マスクの色 $0001 に置き換える
		addq	#1,(a3)
@@:
		move.l	(a3)+,(a2)+
		dbra	d2,@b
set_text_pal_end:
		POP	d0-d2/a0-a3
		rts

text_pal_tbl:	.dc.b	4/2-1,8/2-1,16/2-1
gm_flag:	.ds.b	1			;隙間を有効活用:-)
		.even


* テキストパレットを保存/復帰する.
save_text_palette:
		PUSH	d0/a0-a1
		moveq	#0,d0
		bra	@f
restore_text_palette:
		PUSH	d0/a0-a1
		moveq	#1,d0
@@:
		lea	(TEXT_PAL),a0
		lea	(tpal_save_buf,pc),a1
		tst	d0
		beq	@f			;save
		exg	a0,a1			;restore
@@:
		moveq	#16/2-1,d0
@@:		move.l	(a0)+,(a1)+
		dbra	d0,@b
		POP	d0/a0-a1
		rts


* ヘッダから表示座標を得る
* in	a1.l	データアドレス
* out	d1.l	x0
*	d2.l	y0
*	d3.l	x size
*	d4.l	y size
*	a1.l	+= 8
* break	d0
* 備考:
*	.mag の x0/x1 はそれぞれ 8 ドット単位に切り捨て/切り上げ
*	られ、その値から x size が計算される.
*	.mit の x size は 8 ドット単位に切り上げられる.

get_pos_size:
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		move	(a1)+,d1		;x0
		move	(a1)+,d2		;y0
		move	(a1)+,d3		;x size
		move	(a1)+,d4		;y size
		tst.b	(~color_mode,a5)
		bmi	get_pos_size_mit

		ror	#8,d1
		ror	#8,d2
		ror	#8,d3			;x1
		ror	#8,d4			;y1
		moveq	#%0000_0111,d0
		or	d0,d3			;x1 |= 7
		not	d0
		and	d0,d1			;x0 &= ~7
		sub	d1,d3
		addq	#1,d3			;d3 = X 長さ
		sub	d2,d4
		addq	#1,d4			;d4 = Y 長さ
		rts
get_pos_size_mit:
		subq	#1,d3
		ori	#7,d3
		addq	#1,d3
		rts


* フラグ A/B、ピクセルのアドレスを得る
* in	a0.l	ヘッダ先頭アドレス
*	a1.l	データアドレス
* out	a1.l	+= 20
*	a2.l	フラグ A のアドレス
*	a3.l	フラグ B 〃
*	a4.l	ピクセル 〃
* break	d0
* 備考:
*	終了時に a1 はパレットデータを指す.
*	.mit 表示時には a2.l = a1.l(パレットのアドレス)を返す.

get_flag_adr:
		lea	(a1),a2			;パレット
		tst.b	(~color_mode,a5)
		bmi	get_flag_adr_end	;.mit なら終わり

		bsr	get_intel_long
		lea	(a0,d0.l),a2		;フラグ A
		bsr	get_intel_long
		lea	(a0,d0.l),a3		;フラグ B
		addq.l	#4,a1			;〃 サイズ
		bsr	get_intel_long
		lea	(a0,d0.l),a4		;ピクセル
		bra	get_intel_long		;〃 サイズ読み捨て

get_intel_long:
		move.l	(a1)+,d0
		ror	#8,d0
		swap	d0
		ror	#8,d0
get_flag_adr_end:
		rts


* int filelength (int fileno);
* ファイルポインタは先頭に移動する.

_filelength::
		move.l	d1,-(sp)
		move	#2,-(sp)
		clr.l	-(sp)
		move	(14+2,sp),-(sp)
		DOS	_SEEK
		move.l	d0,d1			;末尾位置
		clr	(6,sp)
		DOS	_SEEK			;先頭に戻す
		addq.l	#8,sp
		move.l	d1,d0
		move.l	(sp)+,d1
		rts


* テキスト保存/復帰 --------------------------- *

* 高速化の為、ワード単位で転送している.
* 範囲が左右に 1 バイトずつ広がることがあるため、
* バッファは 1 ラインにつき、2 バイト×二プレーン
* 分で 4 バイトの余分が必要.


* テキスト保存
save_tvram:
		PUSH	d0-d7/a0-a6
		bsr	save_restore_tvram
save_tvram_loop:
		move	(a0)+,(a4)+		;１ライン保存ルーチン
		move	(a1)+,(a4)+
		dbra	d4,save_tvram_loop
		rts


* テキスト復帰
restore_tvram:
		PUSH	d0-d7/a0-a6
.ifdef CLR_BY_TXFILL
		lea	(txfill_buf,pc),a1
		tst.b	(a1)
		beq	@f
		IOCS	_TXFILL			;マウスプレーンをクリアする
@@:
.else
		move.b	(color_mode,pc),d0
		subq.b	#COL_8,d0
		bhi	restore_tvram_16
		beq	restore_tvram_8
*restore_tvram_4:
.endif
		bsr	save_restore_tvram
restore_tvram_4_loop:
		move	(a4)+,(a0)+		;１ライン復帰ルーチン
		move	(a4)+,(a1)+
		dbra	d4,restore_tvram_4_loop
		rts

.ifndef CLR_BY_TXFILL
restore_tvram_8:
		bsr	save_restore_tvram
restore_tvram_8_loop:
		move	(a4)+,(a0)+		;１ライン復帰ルーチン
		move	(a4)+,(a1)+
		move	d3,(a2)+		;マウスプレーンをクリア
		dbra	d4,restore_tvram_8_loop
		rts

restore_tvram_16:
		bsr	save_restore_tvram
restore_tvram_16_loop:
		move	(a4)+,(a0)+		;１ライン復帰ルーチン
		move	(a4)+,(a1)+
		move	d3,(a2)+		;マウスプレーンをクリア
		move	d3,(a3)+
		dbra	d4,restore_tvram_16_loop
		adda.l	d5,a3
		rts
.endif


save_restore_tvram:
		movea.l	(sp)+,a5		;ライン転送ルーチンのアドレス

		move	(y_len,pc),d7
		subq	#1,d7			;Y loop count
		move	(x_byte,pc),d6		;X loop count

		move.l	(text_adr,pc),d0
		bclr	#0,d0			;左端を偶数アドレスにする
		beq	@f
		addq	#1,d6
@@:		lsr	#1,d6			;ワード単位のループ回数

		movea.l	d0,a0
		moveq	#(TVRAM_P1-TVRAM_P0)>>16,d0
		swap	d0			;$20000
		lea	(a0,d0.l),a1
		lea	(a1,d0.l),a2
		lea	(a2,d0.l),a3
		movea.l	(text_save_buf,pc),a4

		moveq	#128-2,d5
		sub	d6,d5			;次のライン先頭へのオフセット
		sub	d6,d5
		moveq	#0,d3
@@:
		move	d6,d4
		jsr	(a5)			;１ライン転送
		adda.l	d5,a0			;次のラインへ
		adda.l	d5,a1
		adda.l	d5,a2
*		adda.l	d5,a3			;restore_tvram_16 に移動
		dbra	d7,@b

		POP	d0-d7/a0-a6
		rts


* Graphic Mask 制御 --------------------------- *

clear_graphic_mask:
		PUSH	d0-d1/a0
		bsr	tst_clr_gm_flag

		move.b	(color_mode,pc),d0
		subq.b	#COL_16,d0
		bne	clear_gm_end		;4/8 色表示なら消さないでいい

		moveq	#.low._GM_MASK_STATE,d1
		bsr	gm_tgusemd
		bne	clear_gm_end		;GM 未常駐
		tst.l	d0
		beq	clear_gm_end		;マスクなし

		st	(a0)
		moveq	#.low._GM_MASK_CLEAR,d1
		bsr	gm_tgusemd		;マスク消去
clear_gm_end:
		POP	d0-d1/a0
		rts


draw_graphic_mask:
		PUSH	d0-d1/a0
		bsr	tst_clr_gm_flag
		beq	draw_gm_end

		moveq	#.low._GM_GRAPHIC_MODE_STATE,d1
		bsr	gm_tgusemd
		bne	draw_gm_end		;GM 未常駐
		tst.l	d0
		beq	draw_gm_end		;64K 色モードではない

		moveq	#.low._GM_MASK_SET,d1
		bsr	gm_tgusemd		;マスク描画
draw_gm_end:
		POP	d0-d1/a0
		rts


tst_clr_gm_flag:
		lea	(gm_flag,pc),a0
		tst.b	(a0)
		sf	(a0)
		rts


gm_tgusemd:
		swap	d1
		move	#_GM_INTERNAL_MODE,d1
		swap	d1
		IOCS	_TGUSEMD
		subi	#_GM_INTERNAL_MODE,d0
		rts


* 圧縮データ -> 展開バッファルーチン ---------- *

* in	a1.l	画像データ(.mit の時)
*	a2.l	フラグ A のアドレス(以下、.mag の時)
*	a3.l	フラグ B 〃
*	a4.l	ピクセル 〃
decode_to_buf:
		move.b	(~color_mode,a5),d0
		bmi	decode_to_buf_mit

* .mag デコード
		lea	(offs_idx,pc),a0	;コピー元への差を計算する
		lea	(~offs_tbl,a5),a1
		moveq	#15-1,d1
@@:
		move	d3,d0
		mulu	(a0)+,d0
		add	(a0)+,d0
		move	d0,(a1)+
		dbra	d1,@b

		lea	(~flag_buf,a5),a1	;フラグ展開バッファを初期化
		moveq	#0,d0
		moveq	#128/(4*4)-1,d1
@@:		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		dbra	d1,@b

*		  +---- プレーン 2 X+0 のドット
*		  |+--- 〃	   X+1 〃
*		  ||+-- 〃	   X+2 〃
*		  |||+- 〃	   X+3 〃
*		  ||||		      ++++- プレーン 0
* %0000_aaaa_0000_bbbb_0000_cccc_0000_dddd
*	||||		    ++++- プレーン 1
*	|||+- プレーン 3 X+3 のドット
*	||+-- 〃	 X+2 〃
*	|+--- 〃	 X+1 〃
*	+---- 〃	 X+0 〃
*
*		  +---- プレーン 2 X+4 のドット
*		  |+--- 〃	   X+5 〃
*		  ||+-- 〃	   X+6 〃
*		  |||+- 〃	   X+7 〃
*		  ||||		      ++++- プレーン 0
* %0000_eeee_0000_ffff_0000_gggg_0000_hhhh
*	||||		    ++++- プレーン 1
*	|||+- プレーン 3 X+7 のドット
*	||+-- 〃	 X+6 〃
*	|+--- 〃	 X+5 〃
*	+---- 〃	 X+4 〃
*
* データの X サイズは必ず 8 の倍数なので、abcd と efgh も
* 必ず対になる(右端が abcd で終わることがない).

* %abcd_efgh_ijkl_mnop
* ↓
* %0000_aeim_0000_bfjn_0000_cgko_0000_dhlp
		move.l	a2,d6			;save a2
		lea	(~hv_tbl_l,a5),a0	;水平型→垂直型変換表を作る
		lea	(~hv_tbl_h,a5),a1
		lea	(hv_tbl_seed,pc),a2
		moveq	#1,d4
		ror.l	#7,d4			;move.l #$0200_0000,d4
		moveq	#$100/4-1,d7
make_hv_tbl_loop:
		move.l	(a2)+,d0
		move.l	d0,d1
		or.l	d4,d1
		move.l	d0,d2
		move.l	d1,d3
		lsl.l	#2,d2
		lsl.l	#2,d3

		move.l	d1,(128*4,a0)
		move.l	d0,(a0)+
		addq.b	#1,d1
		addq.b	#1,d0
		move.l	d1,(128*4,a0)
		move.l	d0,(a0)+

		move.l	d3,(128*4,a1)
		move.l	d2,(a1)+
		addq.b	#1<<2,d3
		addq.b	#1<<2,d2
		move.l	d3,(128*4,a1)
		move.l	d2,(a1)+
		dbra	d7,make_hv_tbl_loop
		movea.l	d6,a2			;restore a2

* 画像展開
* d3 = Y loop count
* d4 = X loop count
* d5 = 〃(初期値)
* d6 = 参照中のフラグ A(16bit)
* d7 = d6 のカウンタ(15～0)
* a0 = 画像展開バッファ
* a1 = フラグ展開バッファ
* a2 = フラグ A
* a3 = フラグ B
* a4 = ピクセル
* a5 = オフセット表

LITERAL:	.macro
		moveq	#0,d2
		move.b	(a4)+,d2		;上位バイト
		add	d2,d2
		add	d2,d2			;$0000～$03fc
		move.l	(~hv_tbl_h,a5,d2.w),d0
		moveq	#-1,d2
		move.b	(a4)+,d2		;下位バイト
		add	d2,d2
		add	d2,d2			;$fc00～$fffc
		or.l	(0,a5,d2.w),d0		;~hv_tbl_l を省略している
		move.l	d0,(a0)+
		.endm

COPY:		.macro	dn
		move	(~offs_tbl-2,a5,dn.w),d2
		move.l	(a0,d2.w),(a0)+
		.endm

		movea.l	(~ext_buf_ptr,a5),a0
		moveq	#0,d7

		move	(y_len,pc),d3
		subq	#1,d3			;Y loop count
		move	(x_byte,pc),d4		;X loop count
y_loop:
		lea	(~flag_buf,a5),a1
		move	d5,d4
x_loop:
		dbra	d7,@f
		moveq	#15,d7			;フラグ A を 1.w 読む
		move	(a2)+,d6
@@:
		add	d6,d6
		bcc	@f
		move.b	(a3)+,d0
		eor.b	d0,(a1)			;フラグ B との xor をとる
@@:		move.b	(a1)+,d0
		moveq	#$0f,d1
		and.b	d0,d1			;%0000_rrrr
		lsr.b	#4,d0			;%0000_llll
		bne	left_copy
*left_literal:
		LITERAL				;左側リテラル
		add	d1,d1
		bne	right_copy
right_literal:
		LITERAL				;右側リテラル
		dbra	d4,x_loop
		bra	y_next
left_copy:
		ext	d0			;上位バイトをクリア
		add	d0,d0
		COPY	d0			;左側コピー
		add	d1,d1
		beq	right_literal
right_copy:
		COPY	d1			;右側コピー
		dbra	d4,x_loop
y_next:
		dbra	d3,y_loop
decode_to_buf_mit_end:
		rts


* .mit デコード
decode_to_buf_mit:
		lea	(MIT_EXT_BUF0),a2
		move.b	d0,-(sp)
		bsr	decode_mit		;プレーン 0/1 デコード
		addq.b	#-COL_MIT_16,(sp)+
		bne.s	decode_to_buf_mit_end

		lea	(MIT_EXT_BUF2),a2
		bra	decode_mit		;プレーン 2/3 デコード
**		rts

decode_mit:
		lea	(a2),a3
		adda.l	#MIT_EXT_BUF1-MIT_EXT_BUF0,a3
		moveq	#128*4/(4*4)-1,d0
		moveq	#0,d1
@@:
		.rept	4
		move.l	d1,(a2)+		;手前の 4 ラインをクリア
		move.l	d1,(a3)+
		.endm
		dbra	d0,@b

		movem	(x_len,pc),d5/d6/d7
		subq	#1,d6			;d6 = Y loop count
		subq	#1,d5
		lsr	#5,d5
		addq	#1,d5			;d5 = フラグサイズ = (x_len-1)/32+1
		moveq	#128-1-1,d4
		sub	d7,d4			;d4 = 次のラインまでのオフセット-1
decode_mit_y_loop:
		move	d7,d3			;d7 = X loop count
		move.b	(a1)+,d0
		bmi	decode_mit_ext		;圧縮あり
@@:
		move.b	(a1)+,(a2)+		;1 ラインベタ格納
		move.b	(a1)+,(a3)+
		dbra	d3,@b
		bra	decode_mit_y_next

decode_mit_ext:
		add.b	d0,d0
		bpl	decode_mit_flag
*decode_mit_copy:
		lea	(-128,a2),a0
		lea	(-128,a3),a4
@@:
		move.b	(a0)+,(a2)+		;1 ライン上からコピー
		move.b	(a4)+,(a3)+
		dbra	d3,@b
		bra	decode_mit_y_next

decode_mit_flag:
		lea	(a1),a0			;a0 = フラグ格納アドレス
		adda	d5,a1			;a1 = リテラル格納アドレス
		bra	decode_mit_flag_start
decode_mit_flag_loop:
		dbra	d1,@f
decode_mit_flag_start:
		move.b	(a0)+,d0		;フラグ収得
		rol.b	#1,d0			;%Lxxx_xxxH
		moveq	#4-1,d1
@@:
		rol.b	#2,d0			;%xxxx_xHLx
		moveq	#%0110,d2
		and.b	d0,d2
		beq	decode_mit_literal

		move	(mit_offs_tbl-2,pc,d2.w),d2
		move.b	(a2,d2.w),(a2)+		;コピー
		move.b	(a3,d2.w),(a3)+
		dbra	d3,decode_mit_flag_loop
		bra	decode_mit_y_next

mit_offs_tbl:	.dc	-128,-1,-128*4

decode_mit_literal:
		move.b	(a1)+,(a2)+		;リテラル
		move.b	(a1)+,(a3)+
		dbra	d3,decode_mit_flag_loop

decode_mit_y_next:
		adda	d4,a2
		adda	d4,a3
		sf	(a2)+			;次のラインの為に
		sf	(a3)+			;(-1,y) に相当する画素をクリア
		dbra	d6,decode_mit_y_loop
		rts


* 展開バッファ -> TVRAM 転送ルーチン ---------- *

ext_to_tvram:
		movea.l	(text_adr,pc),a0
		moveq	#0,d0
		move.b	(~color_mode,a5),d0
		bmi	ext_to_tvram_mit

* .mag 転送
		move.l	a6,-(sp)		;レジスタが足りない…

		add	d0,d0
		lea	(ext_job_tbl,pc),a6
		adda	(-COL_4*2,a6,d0.w),a6	;ライン展開ルーチンのアドレス

		moveq	#(TVRAM_P1-TVRAM_P0)>>16,d0
		swap	d0			;$20000
		lea	(a0,d0.l),a1
		lea	(a1,d0.l),a2
		lea	(a2,d0.l),a3
		movea.l	(~ext_buf_ptr,a5),a4

		move	(y_len,pc),d6
		subq	#1,d6			;Y loop count
		move	(x_byte,pc),d7		;X loop count

		moveq	#128-1,d5
		sub	d7,d5			;次のライン先頭へのオフセット
ext_y_loop:
		move	d7,d4
		jsr	(a6)			;1 ライン展開
		adda	d5,a0
		adda	d5,a1
		adda	d5,a2
**		adda	d5,a3			;ext_16 に移動
		dbra	d6,ext_y_loop

		movea.l	(sp)+,a6
		rts

ext_job_tbl:
		.dc	ext_4-ext_job_tbl
		.dc	ext_8-ext_job_tbl
		.dc	ext_16-ext_job_tbl

ext_4:
		move.l	(a4)+,d0		;左側 4dot
		lsl	#4,d0
		or.l	(a4)+,d0		;右側 4dot
		move.b	d0,(a0)+		;$xx_xx_11_00
		move	d0,-(sp)
		move.b	(sp)+,(a1)+		;	  $11
		dbra	d4,ext_4
		rts

ext_8:
		move.l	(a4)+,d0		;左側 4dot
		lsl.l	#4,d0
		or.l	(a4)+,d0		;右側 4dot
		move.b	d0,(a0)+		;$xx_22_11_00
		move	d0,-(sp)
		move.b	(sp)+,(a1)+		;	  $11
		swap	d0
		move.b	d0,(a2)+		;$11_00_xx_22
		dbra	d4,ext_8
		rts

ext_16:
		move.l	(a4)+,d0		;左側 4dot
		lsl.l	#4,d0
		or.l	(a4)+,d0		;右側 4dot
		move.b	d0,(a0)+		;$33_22_11_00
		swap	d0
		move.b	d0,(a2)+		;$11_00_33_22
		rol.l	#8,d0
		move.b	d0,(a1)+		;$00_33_22_11
		swap	d0
		move.b	d0,(a3)+		;$22_11_00_33
		dbra	d4,ext_16
		adda	d5,a3
ext_to_tvram_mit_end:
		rts


* .mit 転送
ext_to_tvram_mit:
		move.b	d0,-(sp)

		move.l	a0,-(sp)
		moveq	#0,d0
		bsr	ext_mit			;プレーン 0/1 転送
		movea.l	(sp)+,a0

		addq.b	#-COL_MIT_16,(sp)+
		bne.s	ext_to_tvram_mit_end

		moveq	#(TVRAM_P2-TVRAM_P0)>>16,d0
		swap	d0
		bra	ext_mit			;プレーン 2/3 転送
**		rts

ext_mit:
		adda.l	d0,a0
		lea	(MIT_EXT_BUF0+128*4),a2
		adda.l	d0,a2
		moveq	#(TVRAM_P1-TVRAM_P0)>>16,d0
		swap	d0
		lea	(a0,d0.l),a1
		lea	(a2,d0.l),a3

		movem	(y_len,pc),d6/d7
		moveq	#128-1,d5
		sub	d7,d5			;d5 = 次のラインまでのオフセット
		subq	#1,d6			;d6 = Y loop count
ext_mit_y_loop:
		move	d7,d4			;d7 = X loop count
ext_mit_x_loop:
		move.b	(a2)+,(a0)+
		move.b	(a3)+,(a1)+
		dbra	d4,ext_mit_x_loop
		adda	d5,a0
		adda	d5,a1
		adda	d5,a2
		adda	d5,a3
		dbra	d6,ext_mit_y_loop
		rts


* Data  Section ------------------------------- *

*		.data
		.even

.ifdef CLR_BY_TXFILL
txfill_buf:	.dc	0			;プレーン
		.dc	0,0,0,0			;範囲
		.dc	0			;ラインスタイル
.endif

* (Y,X*4)
* 動的に確保するバッファに展開するので、Y 方向の倍率は
* X 方向のサイズによって決まる(最大 -16*1024=-$4000).

offs_idx:
*		.dc	  0, 0*4		;0
		.dc	  0,-1*4		;1
		.dc	  0,-2*4		;2
		.dc	  0,-4*4		;3
		.dc	 -1, 0*4		;4
		.dc	 -1,-1*4		;5
		.dc	 -2, 0*4		;6
		.dc	 -2,-1*4		;7
		.dc	 -2,-2*4		;8
		.dc	 -4, 0*4		;9
		.dc	 -4,-1*4		;10
		.dc	 -4,-2*4		;11
		.dc	 -8, 0*4		;12
		.dc	 -8,-1*4		;13
		.dc	 -8,-2*4		;14
		.dc	-16, 0*4		;15

hv_tbl_seed:
i:=0
	.rept	$100/4
		h:=(i&$10)>>3+(i&$20)<<(9-5)+(i&$40)<<(17-6)+(i&$80)<<(25-7)
		l:=(i&$01)<<0+(i&$02)<<(8-1)+(i&$04)<<(16-2)+(i&$08)<<(24-3)
		.dc.l	h+l
i:=i+2
	.endm


* Block Storage Section ----------------------- *

*		.bss
		.even

text_adr:	.ds.l	1
text_save_buf:	.ds.l	1
x_len:		.ds	1
y_len:		.ds	1
x_byte:		.ds	1
*gm_flag:	.ds.b	1			;text_pal_tbl の下に移動
color_mode:	.ds.b	1			;1,2,3=4/8/16 色


		.end

* End of File --------------------------------- *
