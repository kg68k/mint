# exit_scr.s - mint v3 plug-in sample "exit screen-init"
# Copyright (C) 2001-2006 Tachibana Eriko
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

exit_ptr:	.ds.l	1
exit_old_main:	.ds.l	1
exit_old_free:	.ds.l	1


* ダミー -------------------------------------- *

exit_main:
		rts


* 常駐解除前処理 ------------------------------ *
* out	d0.l	mint に解放してもらうメモリブロックのアドレス

exit_free:
		PUSH	a0-a2
		bsr	init_screen

		movem.l	(exit_ptr,pc),a0-a2
		move.l	a1,(PLUG_IN_MAIN,a0)
		move.l	a2,(PLUG_IN_FREE,a0)

		lea	(keep_start-PSP_SIZE+MEM_SIZE,pc),a0
		move.l	a0,d0
		POP	a0-a2
		rts


* 画面初期化 ---------------------------------- *
* break	d0/a1

init_screen:
		lea	(VC_R2),a1
		IOCS	_B_WPEEK
		btst	#5,d0
		beq	do_init			;テキスト画面表示オフなら初期化する

		move.l	#16<<16+$ffff,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		subq.l	#1,d0
		bls	@f			;768x512 なら何もしない
do_init:
		move.l	#16<<16+0,-(sp)		;768x512 G-off
		DOS	_CONCTRL
		addq.l	#4,sp
@@:
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

* 以降、'EXIT' がどこにあるかは、mint v3 のバージョンによって異なる.

* EXIT エントリを探す
		lea	(PLUG_IN_LIST-PLUG_IN_SIZE,a5),a0
		move.l	#'EXIT',d1
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
		lea	(exit_ptr,pc),a2
		move.l	a0,(a2)+

		move.l	(PLUG_IN_MAIN,a0),(a2)+	;exit_old_main
		lea	(exit_main,pc),a1
		move.l	a1,(PLUG_IN_MAIN,a0)

		move.l	(PLUG_IN_FREE,a0),(a2)	;exit_old_free
		lea	(exit_free,pc),a1
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

title_mes:	.dc.b	'mint v3 plug-in sample "exit screen-init" version 1.01',CR,LF
		.dc.b	0

keep_mes:	.dc.b	'mint に組み込みました. 終了時に自動的に呼び出されます.',CR,LF
		.dc.b	0

please_mes:	.dc.b	'error: mint v3(plug-in 対応版)から直接起動して下さい.',CR,LF
		.dc.b	0

not_support_mes:.dc.b	'error: 起動中の mint v3 は EXIT plug-in に対応していません.',CR,LF
		.dc.b	0


		.end

* End of File --------------------------------- *
