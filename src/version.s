# version.s - version, etc.
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
		.include	version.mac

		.include	fefunc.mac
		.include	doscall.mac


* Global Symbol ------------------------------- *

* funcname.s
		.xref	get_builtin_func_name
* mint.s
		.xref	sys_val_table,sys_val_name


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* mint -V によるバージョン表示 ---------------- *

print_version::
		bsr	print_mint_version
		DOS	_EXIT

print_mint_version:
		pea	(version_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		rts


* mint -h による使用法表示 -------------------- *

print_usage::
		bsr	print_mint_version

		pea	(usage_mes,pc)
		DOS	_PRINT
		pea	(staff_mes,pc)
		DOS	_PRINT
		addq.l	#8,sp
		DOS	_EXIT


* mint -d/-t による内部命令表示 --------------- *
* in d0.b 出力形式 'd':データ形式(-d) 't':テキスト形式(-t)

dump_function_table::
  lea (dump_header,pc),a3
  lea (dump_footer,pc),a4
  cmpi.b #'d',d0
  beq @f
    addq.l #type_header-dump_header,a3
    addq.l #type_footer-dump_footer,a4
  @@:
  bsr dump_data

;mint -d/-t 出力データ作成ルーチン
  moveq #0,d7  ;内部関数の通し番号
  bra 1f
  @@:
    lea (a3),a1  ;ヘッダ
    STRCPY a1,a0,-1
    movea.l d0,a1  ;関数名
    STRCPY a1,a0,-1
    lea (a4),a1  ;フッタ
    STRCPY a1,a0,-1

    addq #1,d7
  1:
  move d7,d0
  jsr (get_builtin_func_name)
  bne @b
  rts


;出力データ作成ルーチンを呼び出して出力し、プログラムを終了する
;in (sp).l 出力データ作成ルーチン(コールバック)のアドレス

;出力データ作成ルーチンの仕様
;in  a0.l バッファアドレス
;    a5.l システム変数名リスト(sys_val_name)
;    a6.l バッファアドレス(破壊しないこと)
;out a0.l データ末尾
;呼び出し時にa1.lは破壊されている。それ以外のレジスタは引き継がれる。

dump_data:
  lea (sys_val_name),a5
  lea (Buffer),a6
  lea (a6),a0

  movea.l (sp)+,a1
  jsr (a1)  ;出力データ作成ルーチンを呼び出す

  suba.l a6,a0
  move.l a0,-(sp)  ;バッファに書き込んだバイト数
  pea (a6)         ;バッファ先頭
  move #1,-(sp)    ;STDOUT
  DOS _WRITE
  DOS _EXIT


* mint -p によるシステム変数表示 -------------- *
* (定義ファイル形式、標準値あり)

print_system_value_table::
  bsr dump_data

;mint -p 出力データ作成ルーチン
  lea (sys_val_table-sys_val_name,a5),a4
  @@:
    move.b #'%',(a0)+
    .rept 4
      move.b (a5)+,(a0)+  ;変数名4文字
    .endm
    move.b #TAB,(a0)+

    moveq #0,d0
    move (a4)+,d0  ;変数の標準値
    FPACK __LTOS

    move.b #CR,(a0)+
    move.b #LF,(a0)+
  tst.b (a5)
  bne @b
  rts


* mint -l によるシステム変数表示 -------------- *
* (テキスト形式、標準値なし)

type_system_value_table::
  bsr dump_data

;mint -l 出力データ作成ルーチン
  @@:
    move.l (a5)+,(a0)+  ;変数名4文字
    move.b #CR,(a0)+
    move.b #LF,(a0)+
  tst.b (a5)
  bne @b
  rts


* Data Section -------------------------------- *

*		.data
		.even

version_mes:
		.dc.b	' Madoka INTerpreter version ',mint_version,CR,LF
		.dc.b	'  Thule/ippoh/TEAM NAIL/AKT/K.kirah/Chaola/BEL./Leaza/TcbnErik.',CR,LF
		.dc.b	0

usage_mes:
		.dc.b	CR,LF
		.dc.b	' -E : 自前の環境を持つ.',CR,LF
		.dc.b	' -V : バージョンを表示する.',CR,LF
		.dc.b	' -f : 定義ファイルを解析せずに高速に起動する(-e との併用が一般的).',CR,LF
		.dc.b	' -c : グラフィック画面を非表示にして起動する.',CR,LF
		.dc.b	' -t : 内部関数リストを表示する.',CR,LF
		.dc.b	' -d : 内部関数リストを表示する(.data 形式).',CR,LF
		.dc.b	' -l : システム変数リストを表示する.',CR,LF
		.dc.b	' -p : システム変数リストを表示する(定義ファイル形式).',CR,LF
		.dc.b	' -m : 置換可能文字列の一覧を表示する.',CR,LF
**		.dc.b	' -h : オプションを表示する',CR,LF
		.dc.b	' -e madoka … : mint を shell として引数を実行する',CR,LF
		.dc.b	' -s filename  : ファイルを定義ファイルとみなす',CR,LF
		.dc.b	0

staff_mes:
		.dc.b	CR,LF
		.dc.b	' VF.X Version1.00  to 1.00a  1989    Thule.             | Thanks    (object codes)'	,CR,LF
		.dc.b	' TF.X Version1.10  to 1.20c  1990    Thule.             | ──────────────',CR,LF
		.dc.b	' TF.X Version1.21i to 1.581i 1992    ippoh.             | Nenetto : Umihito Kusama'	,CR,LF
		.dc.b	' TF.X Version1.20l to 1.69   1992    Leaza.AKT          | AKT     : Hideyuki Akutsu'	,CR,LF
		.dc.b	' STF  Version1.70            1993    Leaza(TEAM NAIL)   | CHAOLA  : Youzou Hayashi'	,CR,LF
		.dc.b	' STF  Version2.00            1993    Leaza              | KIRAH   : Ippei Itoh'	,CR,LF
		.dc.b	' Madoka INTerpreter 1        1993.12 Presented By Leaza | BEL     : Tatsuya Tsuyuzaki'	,CR,LF
		.dc.b	' Madoka INTerpreter 2        1995.2  Presented By Leaza | Larse   : Shimaki Matubara'	,CR,LF
		.dc.b	' Madoka INTerpreter 3 and 4  2024    TcbnErik',CR,LF
		.dc.b	0

dump_header:	.dc.b	".dc.b '"
type_header:	.dc.b	0
dump_footer:	.dc.b	"',0"
type_footer:	.dc.b	CR,LF,0
	 	.even


		.end

* End of File --------------------------------- *
