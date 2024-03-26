# winf_mor1.s - mint v3 plug-in sample "winf mor1"
# Copyright (C) 2001-2006 Tachibana Eriko, mor
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

		.include	fefunc.mac
		.include	doscall.mac
		.include	iocscall.mac


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

* 常駐部先頭 ---------------------------------- *

keep_start:
start:
		bra	start2

getmes_ptr:	.ds.l	1
winf_ptr:	.ds.l	1
winf_old_main:	.ds.l	1
winf_old_free:	.ds.l	1

SYSVAL:		.macro	label,name,default_value
label:		.dc.l	name			;システム変数のアドレスに上書きされる
		.dc	default_value
		.endm

sysval_table:
		SYSVAL	＄dirc,'dirc',WHITE
		SYSVAL	＄lnkc,'lnkc',YELLOW
		SYSVAL	＄dlnc,'dlnc',WHITE
		SYSVAL	＄excl,'excl',WHITE
		SYSVAL	＄xrcl,'xrcl',WHITE
		SYSVAL	＄redc,'redc',BLUE
		SYSVAL	＄hidc,'hidc',YELLOW
		SYSVAL	＄sysc,'sysc',YELLOW
		.dc	0

MES:		.macro	label,name,default_mes
label:		.dc.b	name
		.dc.b	@tail-($-1)
		.dc.b	default_mes,0
		.even
@tail:
		.endm

mes_table:
		MES	MES_MONTH,'month','JanFebMarAprMayJunJulAugSepOctNovDec???'
		.dc.b	0

MINTSLASH:	.dc.b	'/'			;手抜き
		.even


* ファイル情報行作成 -------------------------- *
* in	d7.w	%winf
*	a1.l	バッファ(56バイト)
*	a4.l	DIR バッファ
*	a6.l	PATH バッファ
* out	d1.l	描画色
* break	d0/d2-d7/a0-a3/a5

winf_main:
		bra	make_filename_line_mor1
**		rts


* ファイル情報行を作成する(下請けその２).
* in	a1.l	バッファ(56 バイト以上必要)
* out	d1.l	描画色

make_filename_line_mor1:
		lea	(48,a1),a3		;バッファ末尾

* %winf 1	"ldshw fsize Feb16  1999 filename__________.eee@/"
*		or	     Feb16 00:00

* ファイル属性
		move.l	#'----',(a1)+
		move.b	#'-',(a1)+
		move.b	(DIR_ATR,a4),d3		;%@lad_vshr

		lsr.b	#1,d3			;%0@la_dvsh:r
		bcs	@f
		move.b	#'w',(-1,a1)
@@:
		lsr.b	#1,d3			;%00@l_advs:h
		bcc	@f
		move.b	#'h',(-2,a1)
@@:
		lsr.b	#1,d3			;%000@_ladv:s
		bcc	@f
		move.b	#'s',(-3,a1)
@@:
		lsr.b	#2,d3			;%0000_0@la:dv
		bcc	@f
		move.b	#'d',(-4,a1)
		bra	1f
@@:
		lsr.b	#1,d3			;%0000_00@l:a
		bcs	@f
		move.b	#'x',(-4,a1)
@@:
		add.b	d3,d3			;%0000_0@l0
1:
		lsr.b	#2,d3			;%0000_000@:l?
		bcc	@f
		move.b	#'l',(-5,a1)
@@:
* ファイルサイズ
		bsr	make_filename_line_fsize

* 月日
		move.b	#SPACE,(a1)+

		move.l	(MES_MONTH,pc),d0
		bpl	@f
		movea.l	(getmes_ptr,pc),a0
		jsr	(a0)
@@:		movea.l	d0,a0

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
		move.b	(a0)+,(a1)+		;月
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+

		moveq	#$1f,d0
		and	(DIR_DATE,a4),d0
		bsr	make_filename_line_2d
		move	d1,-(sp)		;日
		move.b	(sp)+,(a1)+
		move.b	d1,(a1)+

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
	.rept	18
		move.b	(a0)+,(a1)+		;ノード名
	.endm
@@:		cmp.b	-(a1),d0		;末尾の空白を削除
		beq	@b
		addq.l	#1,a1
	.rept	4
		move.b	(a0)+,(a1)+		;拡張子
	.endm
@@:		cmp.b	-(a1),d0		;末尾の空白を削除
		beq	@b
		addq.l	#1,a1

		moveq	#WHITE,d4

		move.b	(DIR_ATR,a4),d3
		move.b	d3,d2			;%@lad_vshr
* リンクなら '@' を付ける
		add.b	d2,d2			;%ladv_shr0
		bpl	@f
		move.b	#'@',(a1)+
@@:
* ディレクトリなら $MINTSLASH を付ける
		move.b	(MINTSLASH,opc),d0
		rol.b	#2,d2			;%dvsh_r0la
		bmi	@f
* 実行可能なら '*' を付ける
		moveq	#'*',d0
		ror.b	#1,d2			;%advs_hr0l
		bpl	@f
* 拡張子が .[XxRr] でも付ける
		move	(DIR_EXT,a4),d2
		andi	#$dfff,d2
		cmpi	#'X ',d2
		beq	1f
		cmpi	#'R ',d2
		bne	9f
1:		cmp.b	(DIR_EXT+2,a4),d2
		bne	9f			;".x a"
		movea.l	(＄xrcl,pc),a2
		move	(a2),d4
@@:
		move.b	d0,(a1)+
9:

* 余分なスペースを空白で埋める
		moveq	#SPACE,d0
@@:		move.b	d0,(a1)+		;取り敢えず埋めてみる
		cmp.l	a1,a3
		bcc	@b
@@:		clr.b	-(a1)			;埋めすぎたら戻す
		cmp.l	a3,a1
		bhi	@b

* 表示色
		move	d4,d1			;WHITE or ＄xrcl
		cmpi.b	#1<<ARCHIVE,d3
		beq	9f

		movea.l	(＄redc,pc),a2
		move	(a2),d1
		ror.b	#1,d3			;%r@la_dvsh
		bmi	9f
		movea.l	(＄hidc,pc),a2
		move	(a2),d1
		ror.b	#1,d3			;%hr@l_advs
		bmi	9f
		movea.l	(＄sysc,pc),a2
		move	(a2),d1
		ror.b	#1,d3			;%shr@_ladv
		bmi	9f
		ror.b	#2,d3			;%dvsh_r@la
		bpl	@f

		movea.l	(＄dirc,pc),a2
		move	(a2),d1
		ror.b	#2,d3			;%ladv_shr@
		bpl	9f			;普通のディレクトリ
		movea.l	(＄dlnc,pc),a2
		move	(a2),d1
		bra	9f			;リンク〃
@@:
		movea.l	(＄lnkc,pc),a2
		move	(a2),d1
		ror.b	#2,d3			;%ladv_shr@
		bmi	9f
		movea.l	(＄excl,pc),a2
		move	(a2),d1
		add.b	d3,d3			;%advs_hr@0
		bpl	9f
		move	d4,d1			;WHITE or ＄xrcl
9:		rts


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
		move.l	(MES_MONTH,pc),d0
		bpl	@f
		movea.l	(getmes_ptr,pc),a0
		jsr	(a0)
@@:		movea.l	d0,a0

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


* 常駐解除前処理 ------------------------------ *
* out	d0.l	mint に解放してもらうメモリブロックのアドレス

winf_free:
		PUSH	a0-a2
		movem.l	(winf_ptr,pc),a0-a2
		move.l	a1,(PLUG_IN_MAIN,a0)
		move.l	a2,(PLUG_IN_FREE,a0)

		lea	(keep_start-PSP_SIZE+MEM_SIZE,pc),a0
		move.l	a0,d0
		POP	a0-a2
		rts


keep_end:

* 常駐部末尾 ---------------------------------- *


* 非常駐部先頭 -------------------------------- *

start2:
		pea	(title_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp

* 親プロセスが mint v3 であるか調べる
		movea.l	(pare,a0),a0		;親のメモリ管理ポインタ
		movea.l	(pare,a0),a1		;更にその親
		IOCS	_B_LPEEK
		tst.l	d0
		beq	parent_is_not_mintv3	;Human68k から直接起動された

		lea	(PSP_SIZE,a0),a5	;プラグイン情報のアドレス

* 識別子(16バイト)を比較
		lea	(PLUG_IN_ID,a5),a0
	.irp	id,'MINT','-V3 ','PLUG','-IN'<<8+0
		cmpi.l	#id,(a0)+
		bne	parent_is_not_mintv3
	.endm

* システム変数のアドレスを取得する
		movea.l	(PLUG_IN_VAL,a5),a2
		lea	(sysval_table,pc),a0

		clr	-(sp)
		clr.l	-(sp)
		lea	(sp),a1			;変数名のアドレス
get_sysvalptr_loop:
		move.l	(a0),(a1)
		jsr	(a2)			;search_system_value
		move.l	d0,(a0)+		;変数のアドレス
		bne	get_sysvalptr_next

* 変数が存在しない
		move.l	a0,(-4,a0)		;自前のデフォルト値を使う
get_sysvalptr_next:
		addq.l	#2,a0			;デフォルト値を飛ばす
		tst	(a0)
		bne	get_sysvalptr_loop
		addq.l	#6,sp

* メッセージ番号を収得する
		movea.l	(PLUG_IN_MESNO,a5),a2
		lea	(mes_table,pc),a1
get_mesno_loop:
		jsr	(a2)
		not	d0
		not.l	d0			;上位ワードを反転
		move.l	d0,(a1)+		;メッセージ番号
		bmi	get_mesno_next

* メッセージが存在しない
		move.l	a1,-(a1)		;自前のデフォルト文字列を使う
		addq.l	#1,(a1)+
get_mesno_next:
		clr.b	(a1)
		adda	(a1),a1
		tst.b	(a1)
		bne	get_mesno_loop

* get_message のアドレスを取得する
		lea	(getmes_ptr,pc),a2
		move.l	(PLUG_IN_MES,a5),(a2)

* ここまでの要素は固定. 以降、'WINF' がどこに
* あるかは、mint v3 のバージョンによって異なる.

* WINF エントリを探す
		lea	(PLUG_IN_LIST-PLUG_IN_SIZE,a5),a0
		move.l	#'WINF',d1
search_loop:
		lea	(PLUG_IN_SIZE,a0),a0	;次のエントリ
		move.l	(PLUG_IN_TYPE,a0),d0
		beq	not_supported		;見つからなかった
		cmp.l	d0,d1
		bne	search_loop

* 念の為
		clr.l	-(sp)
		DOS	_SUPER
		addq.l	#4,sp

* 処理アドレスを書き込む
		lea	(winf_ptr,pc),a2
		move.l	a0,(a2)+

		move.l	(PLUG_IN_MAIN,a0),(a2)+	;winf_old_main
		lea	(winf_main,pc),a1
		move.l	a1,(PLUG_IN_MAIN,a0)

		move.l	(PLUG_IN_FREE,a0),(a2)	;winf_old_free
		lea	(winf_free,pc),a1
		move.l	a1,(PLUG_IN_FREE,a0)

* 常駐終了する
		pea	(keep_mes,pc)
		DOS	_PRINT

		clr	-(sp)
		pea	(keep_end-keep_start).w
		DOS	_KEEPPR


parent_is_not_mintv3:
		pea	(please_mes,pc)
		bra	@f
not_supported:
		pea	(not_support_mes,pc)
@@:
		DOS	_PRINT
		move	#1,(sp)
		DOS	_EXIT2


* Data Section -------------------------------- *

**		.data
		.even

title_mes:	.dc.b	'mint v3 plug-in sample "winf mor1" version 1.01',CR,LF
		.dc.b	0

keep_mes:	.dc.b	'mint に組み込みました. &set winf 0xffff で有効になります.',CR,LF
		.dc.b	0

please_mes:	.dc.b	'error: mint v3(plug-in 対応版)から直接起動して下さい.',CR,LF
		.dc.b	0

not_support_mes:.dc.b	'error: 起動中の mint v3 は %winf plug-in に対応していません.',CR,LF
		.dc.b	0


		.end

* End of File --------------------------------- *
