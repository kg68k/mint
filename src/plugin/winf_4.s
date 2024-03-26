# winf_4.s - mint v3 plug-in sample "%winf 4"
# Copyright (C) 2001-2007 Tachibana Eriko
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
		SYSVAL	＄f_1k,'f_1k',0
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
		MES	MES_LINKD,'linkd',' <F-LNK>'
		MES	MES_DLINK,'dlink',' <D-LNK>'
		MES	MES_DIREC,'direc',' < DIR >'
		.dc.b	0
		.even


* ファイル情報行作成 -------------------------- *
* in	d7.w	%winf
*	a1.l	バッファ(56バイト)
*	a4.l	DIR バッファ
*	a6.l	PATH バッファ
* out	d1.l	描画色
* break	d0/d2-d7/a0-a3/a5

winf_main:
		bra	make_filename_line_4
**		rts


* ファイル情報行を作成する(下請けその２).
* in	a1.l	バッファ(56 バイト以上必要)
* out	d1.l	描画色

make_filename_line_4:

* %winf 4	" filename.ext__________ filesize 99-02-16 00:00 "

* ファイル名
		lea	(DIR_NAME,a4),a0
		move.b	#SPACE,(a1)+		;a0 = a1 = 奇数アドレス
		move.b	(a0)+,(a1)+
	.rept	5
		move.l	(a0)+,(a1)+
	.endm
		move.b	(a0)+,(a1)+		;1+4*5+1=22

* %winf 4 で拡張子があれば、詰めて表示する。
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
make_filename_line_0e:

* ファイルサイズ
		move.l	(DIR_SIZE,a4),d0
		lea	(a1),a0
		cmpi.l	#1024*1024,d0
		bls	mk_fn_line_byte		;1MB 以下ならそのまま表示
		cmpi.l	#999999999,d0
		bhi	mk_fn_line_mb		;10桁以上ならMバイト単位
		movea.l	(＄f_1k,pc),a2
		tst	(a2)
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

		btst	#LINK,d3
		beq	@f

		move.l	(MES_LINKD,pc),d0
		movea.l	(＄lnkc,pc),a2
		move	(a2),d1
		btst	#DIRECTORY,d3
		beq	make_filename_line_dir	;リンクファイル
		move.l	(MES_DLINK,pc),d0
		movea.l	(＄dlnc,pc),a2
		move	(a2),d1
		bra	make_filename_line_dir	;リンクディレクトリ
@@:
		btst	#DIRECTORY,d3
		beq	make_filename_line_file
		move.l	(MES_DIREC,pc),d0	;ディレクトリ
		movea.l	(＄dirc,pc),a2
		move	(a2),d1
make_filename_line_dir:
		lea	(-24,a1),a1		;filesize

		tst.l	d0
		bpl	@f			;デフォルト文字列
		movea.l	(getmes_ptr,pc),a0
		jsr	(a0)			;get_message
@@:		movea.l	d0,a0

		moveq	#8-1,d0
@@:		move.b	(a0)+,(a1)+
		dbra	d0,@b
		bra	@f

make_filename_line_file:
		movea.l	(＄excl,pc),a2
		move	(a2),d1
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
		movea.l	(＄xrcl,pc),a2
		move	(a2),d1
@@:
* この時点で d1.w には WHITE、＄lnkc、＄dlnc、＄dirc、＄xrcl
* のいずれかが入っている(＄excl の場合はここには来ない).
		lsl.b	#8-SYSTEM,d3		;%(S)_HR00_0000
		bcs	2f
		bmi	1f
		beq	make_filename_line_end

		movea.l	(＄redc,pc),a2		;READONLY
		move	(a2),d1
		rts
1:		movea.l	(＄hidc,pc),a2		;HIDDEN
		move	(a2),d1
		rts
2:		movea.l	(＄sysc,pc),a2		;SYSTEM
		move	(a2),d1
		rts

make_filename_line_white:
		moveq	#WHITE,d1
make_filename_line_end:
		rts


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

title_mes:	.dc.b	'mint v3 plug-in sample "%winf 4" version 1.01',CR,LF
		.dc.b	0

keep_mes:	.dc.b	'mint に組み込みました. &set winf 0xffff で有効になります.',CR,LF
		.dc.b	0

please_mes:	.dc.b	'error: mint v3(plug-in 対応版)から直接起動して下さい.',CR,LF
		.dc.b	0

not_support_mes:.dc.b	'error: 起動中の mint v3 は %winf plug-in に対応していません.',CR,LF
		.dc.b	0


		.end

* End of File --------------------------------- *
