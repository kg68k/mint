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

* mint.s
		.xref	func_name_list
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


* mint -d による内部命令表示 ------------------ *
* (データ形式)

dump_function_table::
		moveq	#1,d7
		lea	(func_name_list),a5
		bsr	lea_Buffer_a6
dump_loop:
		lea	(a6),a1
		lea	(dump_header,pc),a0
dump_cont:
		bsr	strcpy
@@:
		move.b	(a5)+,d0
		cmp.b	d7,d0
		beq	dump_equal
		move.b	d0,(a1)+
		bne	@b

		lea	(dump_footer,pc),a0
		bsr	print_line
		bne	dump_loop

		DOS	_EXIT
dump_equal:
		lea	(dump_equsign,pc),a0
		bra	dump_cont

strcpy:
		move.b	(a0)+,(a1)+
		bne	strcpy
		subq.l	#1,a1
		rts

print_line_crlf:
		lea	(type_footer,pc),a0
print_line:
		subq.l	#1,a1
		bsr	strcpy

		move.l	a6,-(sp)
		DOS	_PRINT
		addq.l	#4,sp

		tst.b	(a5)
		rts


* mint -t による内部命令表示 ------------------ *
* (テキスト形式)

type_function_table::
		moveq	#1,d7
		lea	(func_name_list),a5
		bsr	lea_Buffer_a6
type_loop:
		lea	(a6),a1
@@:
		move.b	(a5)+,d0
		cmp.b	d7,d0
		beq	type_equal
		move.b	d0,(a1)+
		bne	@b

		bsr	print_line_crlf
		bne	type_loop

		DOS	_EXIT
type_equal:
		move.b	#'=',(a1)+
		bra	@b


* mint -p によるシステム変数表示 -------------- *
* (定義ファイル形式、標準値あり)

print_system_value_table::
		bsr	get_sys_val_name
		lea	(sys_val_table-sys_val_name,a5),a4
		addq.l	#1,a6
print_loop:
		lea	(a6),a0
		move.b	#'%',(a0)+
		move.l	(a5)+,(a0)+
		move.b	#TAB,(a0)+

		moveq	#0,d0
		move	(a4)+,d0
		FPACK	__LTOS
		lea	(1,a0),a1

		bsr	print_line_crlf
		bne	print_loop

		DOS	_EXIT

get_sys_val_name:
		lea	(sys_val_name),a5
lea_Buffer_a6:
		lea	(Buffer),a6
		rts


* mint -l によるシステム変数表示 -------------- *
* (テキスト形式、標準値なし)

type_system_value_table::
		bsr	get_sys_val_name
list_loop:
		lea	(a6),a1
		move.l	(a5)+,(a1)+
		clr.b	(a1)+

		bsr	print_line_crlf
		bne	list_loop

		DOS	_EXIT


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

dump_header:	.dc.b	"	.dc.b	'",0
dump_footer:	.dc.b	"',0"
type_footer:	.dc.b	CR,LF,0
dump_equsign:	.dc.b	"',1,'",0
		.even


		.end

* End of File --------------------------------- *
