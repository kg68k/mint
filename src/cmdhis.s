# cmdhis.s - command history
# Copyright (C) 2003-2007 Tachibana Eriko
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

		.include	doscall.mac


* Global Symbol ------------------------------- *

* help.s
		.xref	help_menu_getarg
		.xref	help_menu
* madoka3.s
		.xref	execute_quick,free_token_buf
		.xref	open_rl_win
		.xref	CMD_SW_SIZE
* mint.s
		.xref	malloc_mode
* outside.s
		.xref	break_check1


* Constant ------------------------------------ *

MAX_LINE:	.equ	23

RL_MAX:		.equ	$ffff

CMD_HIS_ALIGN:	.equ	4


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* &command-history 下請け --------------------- *
* in	d0.hw	$0000:編集せずに実行 $ffff:編集してから実行
*	d0.lw	ヒストリ番号(1～)
*	d7.l	引数の数
*	a0.l	引数列のアドレス
* out	d0.l	0:実行した -1:キャンセル
*	ccr	<tst.l d0> の結果

command_history::
		PUSH	d1-d7/a0-a5

.ifdef PRINT_CMD_HIS
		bsr	print_cmd_his
.endif
		move.l	d0,d6			;編集モード | 現在のヒストリ番号
		tst	d0
		beq	cmd_his_error
		bsr	get_cmd_his_num
		move	d0,d5			;ヒストリ数
		beq	cmd_his_error
		cmp	d0,d6
		bhi	cmd_his_error

		move.l	#CMD_SW_SIZE+1+RL_MAX+1,-(sp)
		DOS	_MALLOC
		move.l	d0,(sp)+
		bmi	cmd_his_error

		movea.l	d0,a4
		tst.l	d6
		bpl	cmd_his_direct		;編集なし

		GETMES	MES_CHIST
		bra	cmd_his_arg_next
cmd_his_arg_loop:
		cmpi.b	#'-',(a0)
		bne	cmd_his_arg_skip
		cmpi.b	#'t',(1,a0)
		bne	cmd_his_arg_skip
*cmd_his_opt_t:
		addq.l	#2,a0			;-t"タイトル"
@@:		tst.b	(a0)+
		bne	@f
		subq.l	#1,d7
		bcc	@b
		bra	cmd_his_arg_end
@@:
		subq.l	#1,a0
		move.l	a0,d0
cmd_his_arg_skip:
		tst.b	(a0)+
		bne	cmd_his_arg_skip
cmd_his_arg_next:
		subq.l	#1,d7
		bcc	cmd_his_arg_loop
cmd_his_arg_end:
		jsr	(open_rl_win)
		move	d0,-(sp)
		move	#78,-(sp)		;ウィンドウ幅
cmd_his_loop:
		move.l	(sp),d0
		moveq	#1,d1
		moveq	#1,d2
		jsr	(WinSetCursor)

		move	d6,d0			;ヒストリをバッファに転送
		bsr	get_cmd_his
		movea.l	d0,a0
		lea	(a4),a1
		STRCPY	a0,a1

		lea	(a4),a1			;コマンドスイッチを飛ばす
@@:		cmpi.b	#TAB,(a1)+
		bne	@b

		move.l	#RL_MAX<<16,d1
		cmp	d5,d6
		beq	@f			;これ以上古いヒストリは無い
		addq	#RL_F_RD,d1
@@:		cmpi	#1,d6
		beq	@f			;これ以上新しいヒストリは無い
		addq	#RL_F_RU,d1
@@:
		move.l	(sp),d0
		jsr	(MintReadLine)
		move.l	d0,d2
		jsr	(break_check1)		;ブレークキーの状態を更新
		tst.l	d2
		ble	cmd_his_decide

		addq	#1,d6			;ROLL DOWN で古いヒストリへ移動
		subq.l	#RL_E_PREV,d2
		beq	@f
		subq	#1+1,d6			;ROLL UP で新しいヒストリへ移動
@@:		bra	cmd_his_loop

cmd_his_decide:
		move.l	(sp)+,d0
		jsr	(WinClose)
		tst.l	d2
		beq	cmd_his_exec
*cmd_his_cancel:
		pea	(a4)
		DOS	_MFREE
		addq.l	#4,sp
		bra	cmd_his_error

cmd_his_direct:
		move	d6,d0
		bsr	get_cmd_his
		movea.l	d0,a0
		lea	(a4),a1
		STRCPY	a0,a1
cmd_his_exec:
		STRLEN	a4,d0,+1
		move.l	d0,-(sp)
		pea	(a4)
		DOS	_SETBLOCK
		addq.l	#8,sp

		lea	(a4),a1
		moveq	#TAB,d1
@@:		cmp.b	(a1)+,d1
		bne	@b
		clr.b	(-1,a1)			;コマンドスイッチとコマンドラインを
		lea	(a4),a0			;分割する
		bsr	add_cmd_his
		move.b	d1,-(a1)

		moveq	#%0000_0100,d0
		lea	(a4),a1
		jsr	(free_token_buf)
		jsr	(execute_quick)

		moveq	#0,d0
cmd_his_end:
		POP	d1-d7/a0-a5
		rts
cmd_his_error:
		moveq	#-1,d0
		bra	cmd_his_end


* &command-history-menu 下請け ---------------- *
* in	d7.l	引数の数
*	a0.l	引数列のアドレス
* out	d0.hw	$0000:確定終了 $ffff:'E'/'V'
*	d0.lw	選択した行番号＝ヒストリ番号(1～)
*		d0.l = 0 ならキャンセル
*	ccr	<tst.l d0> の結果

command_history_menu::
		PUSH	d1-d7/a0-a5

* このあたりの処理は help.s (ext_help_decode_end ～)
* とほぼ同じ
		moveq	#MES_CHISM,d0
		moveq	#1,d3			;初期カーソル位置
		jsr	(help_menu_getarg)
		lea	(subwin_menu,pc),a0
		move.l	a3,(SUBWIN_TITLE,a0)

		bsr	get_cmd_his_num
		move.l	d0,d7
		beq	cmd_his_menu_error	;ヒストリ未登録

		moveq	#MAX_LINE,d0
		cmp	d7,d0
		bls	@f
		move	d7,d0
@@:		move	d0,(SUBWIN_YSIZE,a0)

		moveq	#32,d1
		sub	d0,d1
		lsr	#2,d1
		addq	#1,d1
		move	d1,(SUBWIN_Y,a0)

		move.l	d3,d0			;-l<n>
		move.l	d7,d1			;行数
		lea	(get_cmd_his2,pc),a1
		jsr	(help_menu)
		tst.l	d0
cmd_his_menu_end:
		POP	d1-d7/a0-a5
		rts
cmd_his_menu_error:
		moveq	#0,d0
		bra	cmd_his_menu_end


* コマンドヒストリ登録 ------------------------ *
* in	a0.l	スイッチ文字列
*	a1.l	コマンドライン文字列
* out	d0.l	0:登録成功 -1:失敗
*	ccr	<tst.l d0> の結果

add_cmd_his::
		PUSH	d1/a0-a5
		lea	(cmd_his_buf_adr,pc),a5
		tst.l	(a5)
		beq	add_ch_error
		cmpi.b	#'-',(a0)
		bne	add_ch_error
		tst.b	(a1)
		beq	add_ch_error

* 同一のコマンドが登録済みなら削除する
		movea.l	(a5),a2			;cmd_his_buf_adr
add_ch_loop:
		lea	(a2),a4
		lea	(a0),a3
@@:
		cmpm.b	(a3)+,(a4)+
		beq	@b
		tst.b	-(a3)
		bne	add_ch_next		;コマンドスイッチが違う
		cmpi.b	#TAB,(-1,a4)
		bne	add_ch_next		;〃
		lea	(a1),a3
@@:
		cmpm.b	(a3)+,(a4)+
		bne	add_ch_next		;コマンドラインが違う
		tst.b	(-1,a4)
		bne	@b
		bra	1f
@@:
		STRCPY	a4,a2
1:		move.b	(a4),(a2)
		bne	@b			;先頭が NUL なら終わり
		move.l	a2,(cmd_his_buf_ptr-cmd_his_buf_adr,a5)
		bra	@f
add_ch_next:
		tst.b	(a2)+
		bne	add_ch_next
		tst.b	(a2)
		bne	add_ch_loop
@@:
		STRLEN	a0,d0,+1
		STRLEN	a1,d1,+1
		add.l	d0,d1			;書き込むサイズ
		cmp.l	(cmd_his_buf_size,pc),d1
		bcc	add_ch_error		;長すぎる
add_ch_loop2:
		lea	(a5),a4
		movea.l	(a4)+,a2		;cmd_his_buf_adr
		movea.l	(a4)+,a3		;cmd_his_buf_ptr
		adda.l	(a4),a2			;cmd_his_buf_size
		adda.l	d1,a3
		cmpa.l	a3,a2
		bhi	add_ch_copy

* 十分な残り容量が無ければ先頭の項目を削除する
		movea.l	(a5),a2			;cmd_his_buf_adr
		lea	(a2),a3
@@:		tst.b	(a2)+
		bne	@b
		bra	1f
@@:
		STRCPY	a2,a3
1:		move.b	(a2),(a3)
		bne	@b			;先頭が NUL なら終わり

		move.l	a3,-(a4)		;cmd_his_buf_ptr
		bra	add_ch_loop2
add_ch_copy:
		suba.l	d1,a3
		STRCPY	a0,a3
		move.b	#TAB,(-1,a3)
		STRCPY	a1,a3
		clr.b	(a3)

		move.l	a3,-(a4)		;cmd_his_buf_ptr
		moveq	#0,d0
add_ch_end:
		POP	d1/a0-a5
		rts
add_ch_error:
		moveq	#-1,d0
		bra	add_ch_end


* コマンドヒストリを返す ---------------------- *
* in	d0.w	ヒストリ番号(1～)
* out	d0.l	ヒストリ文字列のアドレス
* 備考:
*	コマンドスイッチを飛ばしたアドレスを返す.

get_cmd_his2::
		move.l	a0,-(sp)
		bsr	get_cmd_his
		movea.l	d0,a0
@@:
		cmpi.b	#TAB,(a0)+
		bne	@b
		move.l	a0,d0
		movea.l	(sp)+,a0
		rts


* コマンドヒストリを返す ---------------------- *
* in	d0.w	ヒストリ番号(1～)
* out	d0.l	ヒストリ文字列のアドレス

get_cmd_his::
		PUSH	d1/a0
		move	d0,d1
		bsr	get_cmd_his_num
		movea.l	(cmd_his_buf_adr,pc),a0
		sub	d1,d0
		beq	get_cmd_his_end
@@:
		tst.b	(a0)+
		bne	@b
		subq	#1,d0
		bne	@b
get_cmd_his_end:
		move.l	a0,d0
		POP	d1/a0
		rts


* コマンドヒストリ登録数を返す ---------------- *
* out	d0.l	登録数(0 なら未登録)
*		(1～d0.l のヒストリが有効、最大 65535)
*	ccr	<tst.l d0> の結果

get_cmd_his_num::
		move.l	a0,-(sp)
		move.l	(cmd_his_buf_adr,pc),d0
		beq	9f
		movea.l	d0,a0
		moveq	#0,d0
		bra	1f
@@:
		tst.b	(a0)+			;ヒストリの数を数える
		bne	@b
		addq.l	#1,d0
1:		tst.b	(a0)
		bne	@b
9:
		movea.l	(sp)+,a0
		rts


* コマンドヒストリが登録されているか調べる ---- *
* out	d0.b	0:なし '-':あり / 上位ワード～バイトは不定
*	ccr	<tst.b d0> の結果

is_exist_cmd_his::
		move.l	(cmd_his_buf_adr,pc),d0
		beq	@f

		move.l	a0,-(sp)
		movea.l	d0,a0
		move.b	(a0),d0
		movea.l	(sp)+,a0
@@:		rts


* バッファ確保 -------------------------------- *

alloc_cmd_his_buf::
		PUSH	d0-d2/a0-a1/a5
		lea	(cmd_his_buf_adr,pc),a5
		moveq	#0,d1
		move	(＄hist),d1		;バッファ容量
		bne	@f

* バッファを確保しない
		move.l	(a5),d2			;以前のバッファ
		clr.l	(a5)+			;cmd_his_buf_adr
		clr.l	(a5)+			;cmd_his_buf_ptr
		clr.l	(a5)+			;cmd_his_buf_size
		bra	alloc_chb_free
@@:
		subq.l	#1,d1
		ori	#CMD_HIS_ALIGN-1,d1
		addq.l	#1,d1			;4バイト単位に切り上げる

		cmp.l	(cmd_his_buf_size,pc),d1
		beq	alloc_chb_end		;サイズ変更なし

* サイズ増加時は _SETBLOCK でメモリブロックを拡大する方法もあるが、
* 以下の理由により常に新しいメモリブロックを確保する。
*	- 処理が複雑になる。
*	- 拡大できなかった時は _MALLOC2 で確保し直す必要がある。
*	- そもそも %hist の値は頻繁に変更したりしない。

		move.l	d1,-(sp)		;新しいバッファを確保する
		move	(malloc_mode),-(sp)
		DOS	_MALLOC2
		addq.l	#6,sp
		tst.l	d0
		bmi	alloc_chb_end

		movea.l	d0,a0			;新しいバッファを初期化する
		clr	(a0)

		move.l	(a5),d2			;以前のバッファ
		move.l	a0,(a5)+		;cmd_his_buf_adr
		move.l	a0,(a5)+		;cmd_his_buf_ptr
		move.l	d1,(a5)+		;cmd_his_buf_size

* 以前のバッファに登録されているヒストリを
* 順次新しいバッファに登録する
		tst.l	d2
		ble	alloc_chb_end		;alloc_chb_free も飛ばせる

		movea.l	d2,a1
		bsr	add_cmd_his_list
alloc_chb_free:
		move.l	d2,-(sp)		;以前のバッファを解放する
		ble	@f
		DOS	_MFREE
@@:		addq.l	#4,sp
alloc_chb_end:
		POP	d0-d2/a0-a1/a5
		rts


* ヒストリ列を順次登録する -------------------- *
* in	a1.l	ヒストリ列
* break	a0-a1/d1
*	a1 に現在のバッファ内のヒストリは指定しないこと。
*	a1 の内容は破壊される。

add_cmd_his_list:
		moveq	#TAB,d1
		bra	add_chl_start
add_chl_loop:
		lea	(a1),a0			;a0 = コマンドスイッチ
@@:
		cmp.b	(a1)+,d1		;コマンドスイッチを飛ばす
		bne	@b
		clr.b	(-1,a1)			;a1 = コマンドライン
		bsr	add_cmd_his
@@:
		tst.b	(a1)+
		bne	@b
add_chl_start:
		tst.b	(a1)
		bne	add_chl_loop
		rts


* ヒストリデータサイズ/アドレス取得 ----------- *
* out	d0.l	データサイズ(0 ならヒストリなし)
*	a0.l	データアドレス(d0=0 の時は不定)

get_cmd_his_size::
		move.l	(cmd_his_buf_ptr,pc),d0
		sub.l	(cmd_his_buf_adr,pc),d0
		beq	get_cmd_his_size_end	;バッファなしor空

		movea.l	(cmd_his_buf_ptr,pc),a0	;...,$00,'-d',TAB,'ls',$00,[$00],??

* $MINTHIS 書き出しの都合上、データを4バイト単位に切り上げる
@@:
		clr.b	(a0)+			;最初の一回で ...'ls',$00,$00,[??]
		move	a0,d0
		lsl.b	#8-2,d0			;andi.b #CMD_HIS_ALIGN-1,d0
		bne	@b

		move.l	a0,d0
		movea.l	(cmd_his_buf_adr,pc),a0
		sub.l	a0,d0
get_cmd_his_size_end:
		rts


* ヒストリ読み込み ---------------------------- *
* in	d0.l	サイズ(0 ならヒストリなし、d0 < $10000)
*	a0.l	データアドレス(〃)
* break	d0/a0
*	データサイズが確保しているバッファ以下ならそのまま転送する。
*	データがバッファより大きければ一つずつ追加して残る分だけ入れる。

load_cmd_his::
		PUSH	d7/a1-a2
		move.l	d0,d7
		beq	load_cmd_his_end	;データなし
		andi	#CMD_HIS_ALIGN-1,d0
		bne	load_cmd_his_end	;4バイト単位でない(データ異常)

		lea	(cmd_his_buf_adr,pc),a2
		tst.l	(a2)
		beq	load_cmd_his_end	;バッファなし

		cmp.l	(cmd_his_buf_size,pc),d7
		bls	load_cmd_his_copy	;バッファサイズ以下ならそのままコピー

* バッファよりデータの方が大きい場合は順次バッファに登録する
		lea	(a0),a1
		bsr	add_cmd_his_list
		bra	load_cmd_his_end

* データをそのままバッファにコピーする
load_cmd_his_copy:
		lsr.l	#2,d7			;ロングワード単位にする
		moveq	#8-1,d0
		and	d7,d0			;8.l未満の端数
		lsr	#3,d7			;÷8
		add	d0,d0
		neg	d0
		movea.l	(a2)+,a1		;cmd_his_buf_adr
		jmp	(@f,pc,d0.w)
load_cmd_his_loop:
	.rept	8
		move.l	(a0)+,(a1)+
	.endm
@@:		dbra	d7,load_cmd_his_loop

* 4バイト単位に切り上げた分の末尾の詰め物を取り除く
@@:
		tst.b	-(a1)
		beq	@b
		addq.l	#2,a1			;...,$00,'-d',TAB,'ls',$00,[$00]

		move.l	a1,(a2)			;cmd_his_buf_ptr
load_cmd_his_end:
		POP	d7/a1-a2
		rts


* コマンドヒストリ表示 ------------------------ *

.ifdef PRINT_CMD_HIS
print_cmd_his:
		PUSH	d0/a0
		move.l	(cmd_his_buf_adr,pc),d0
		beq	print_cmd_his_end
		movea.l	d0,a0
		bra	1f
print_cmd_his_loop:
		pea	(a0)
		DOS	_PRINT
		addq.l	#4,sp
		jsr	(PrintCrlf)
@@:
		tst.b	(a0)+
		bne	@b
1:		tst.b	(a0)
		bne	print_cmd_his_loop
print_cmd_his_end:
		POP	d0/a0
		rts
.endif


* Data Section -------------------------------- *

**		.data
		.even

subwin_menu:	SUBWIN	8,6,80,0,NULL,NULL


* Block Storage Section ----------------------- *

**		.bss
		.even

cmd_his_buf_adr:
		.ds.l	1
cmd_his_buf_ptr:
		.ds.l	1
cmd_his_buf_size:
		.ds.l	1


		.end

* End of File --------------------------------- *
