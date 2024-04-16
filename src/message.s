# message.s - message driver
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
		.include	message.mac
		.include	version.mac

		.include	doscall.mac


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even


* 指定番号のメッセージアドレスを返す ---------- *
* in	d0.b	メッセージ番号(get_message)
*	d0.w	〃	      (get_message2)
* out	d0.l	メッセージアドレス

get_message::
		andi	#$ff,d0
get_message2::
		move.l	a0,-(sp)
		lea	(mes_ptr_table),a0
		add	d0,d0
		add	d0,d0
		move.l	(a0,d0.w),d0
		bpl	get_message_end		;標準メッセージのまま

		PUSH	d1-d4/a1
		bclr	#31,d0			;念の為フラグをクリア

* 前回もしくは前々回と同じメッセージなら、
* 静的バッファに展開済のものを再利用する
		lea	(prev_mes_adr0,pc),a0
		movem.l	(a0),d1-d4
		cmp.l	d1,d0
		beq	get_message_cached	;前回と同じ
		exg	d1,d3
		exg	d2,d4
		movem.l	d1-d4,(a0)		;ポインタを交換する
		cmp.l	d1,d0
		beq	get_message_cached	;前々回と同じ

* メッセージが変更されていたら静的バッファに展開する
		move.l	d0,(a0)			;move.l d0,(prev_mes_adr0)
		movea.l	d2,a1			;movea.l (prev_buf_adr0,pc),a1

		movea.l	d0,a0
		moveq	#MESLEN_MAX-1,d4
		moveq	#$20,d3
mes_dec_loop:
		move.b	(a0)+,d1
		cmp.b	d3,d1
		bls	mes_dec_end
		cmpi.b	#'"',d1
		beq	mes_dec_quote
		cmpi.b	#"'",d1
		beq	mes_dec_quote
		move.b	d1,(a1)+
		dbra	d4,mes_dec_loop
		bra	mes_dec_end
mes_dec_quote:
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		cmp.b	d1,d0
		dbeq	d4,mes_dec_quote
		subq.l	#1,a1
		beq	mes_dec_loop		;quote 終了
		addq.l	#1,a1
mes_dec_end:
		clr.b	(a1)
get_message_cached:
		move.l	d2,d0			;move.l (prev_buf_adr0,pc),d0
		POP	d1-d4/a1
get_message_end:
		movea.l	(sp)+,a0
		rts


* ~/.mintから文字列変更定義(&mes "...")を読み込む
* in	a0.l	~/.mint読み込みバッファのアドレス
* break	d0

pickup_message_change::
		PUSH	d1-d7/a0-a6
		lea	(message_name,pc),a6
		lea	(mes_ptr_table),a5
		clr.l	(prev_mes_adr0-message_name,a6)
		clr.l	(prev_mes_adr1-message_name,a6)
		move	#MESNO_MAX-1,d7
pickup_mes_chg_loop:
		cmpi.b	#'&',(a0)
		bne	skip_line

		lea	(1,a0),a1
		move.b	(a1)+,d0
		move.b	(a1)+,d1
		move.b	(a1)+,d2
		move.b	(a1)+,d3
		move.b	(a1)+,d4
		lea	(a5),a2			;mes_ptr_table
		lea	(a6),a3
		move	d7,d5			;MESNO_MAX-1
search_mes_name_loop:
		lea	(a3),a4
		cmp.b	(a4)+,d0
		bne	pickup_mes_chg_next
		cmp.b	(a4)+,d1
		bne	pickup_mes_chg_next
		cmp.b	(a4)+,d2
		bne	pickup_mes_chg_next
		cmp.b	(a4)+,d3
		bne	pickup_mes_chg_next
		cmp.b	(a4)+,d4
		bne	pickup_mes_chg_next

		move.b	(a1)+,d0
		cmpi.b	#TAB,d0
		beq	@f
		cmpi.b	#SPACE,d0
		bne	skip_line
@@:
		move.b	(a1)+,d0
		cmpi.b	#TAB,d0
		beq	@b
		cmpi.b	#SPACE,d0
		beq	@b
		cmpi.b	#$20,d0
		bcs	skip_line

		subq.l	#1,a1
		move.l	a1,(a2)
		tas	(a2)			;最上位ビットが変更フラグ
		bra	skip_line

pickup_mes_chg_next:
		addq.l	#4,a2
		addq.l	#5,a3
		dbra	d5,search_mes_name_loop
skip_line:
		cmpi.b	#LF,(a0)+
		bne	skip_line
		cmpi.b	#EOF,(a0)
		bne	pickup_mes_chg_loop

		POP	d1-d7/a0-a6
		rts


* アドレス表に標準メッセージを設定する -------- *

init_mes_ptr_table::
		PUSH	a0-a1
		lea	(mes_ptr_table),a0
		lea	(default_message,pc),a1
		move	#MESNO_MAX-1,d0
1:
		move.l	a1,(a0)+
2:
		tst.b	(a1)+
		bne	2b
		dbra	d0,1b
		POP	a0-a1
		rts


* メッセージ番号を返す ------------------------ *
* in	a1.l	メッセージ名(5 バイト、NUL 不要)
* out	d0.l	メッセージ番号(0～255)
*		指定されたメッセージがない場合は -1

get_message_no::
		PUSH	d7/a0/a2-a3
		lea	(message_name,pc),a0
		moveq	#0,d0			;メッセージ番号
get_mes_no_loop:
		lea	(a0),a2
		lea	(a1),a3
		moveq	#5-1,d7
@@:
		cmpm.b	(a2)+,(a3)+
		dbne	d7,@b
		beq	get_mes_no_end		;発見
*get_mes_no_next:
		addq	#1,d0
		addq.l	#5,a0
		tst.b	(a0)
		bne	get_mes_no_loop

		moveq	#-1,d0			;指定されたメッセージがない
get_mes_no_end:
		POP	d7/a0/a2-a3
		rts


* メッセージリストを表示する ------------------ *

print_message_list::
		lea	(message_name,pc),a0
		lea	(default_message,pc),a1
		movea.l	(prev_buf_adr0,pc),a6
		pea	(a6)
		move.b	#'&',(a6)+
		move.b	#TAB,(5,a6)
		move	#MESNO_MAX-1,d1
print_message_list_loop:
		lea	(a6),a5
	.rept	5
		move.b	(a0)+,(a5)+		;message id
	.endm
		addq.l	#1,a5

		moveq	#'"',d2
		lea	(a1),a3
@@:
		tst.b	(a3)			;メッセージ内に " があれば
		beq	@f			;' でクォーティングする
		cmp.b	(a3)+,d2
		bne	@b
		moveq	#"'",d2
@@:
		move.b	d2,(a5)+
		STRCPY	a1,a5			;message
		move.b	d2,(-1,a5)
		lea	(print_mes_footer,pc),a2
		STRCPY	a2,a5

		DOS	_PRINT
		dbra	d1,print_message_list_loop
**		addq.l	#4,sp

		DOS	_EXIT


* Data Section -------------------------------- *

**		.data
		.even

prev_mes_adr0:	.dc.l	0			;┐
prev_buf_adr0:	.dc.l	mes_dec_buf0		;│
prev_mes_adr1:	.dc.l	0			;│
prev_buf_adr1:	.dc.l	mes_dec_buf1		;┘


* メッセージ指定キーワード

message_name:
		.dc.b	'title','titl0','m_mes'

		.dc.b	'func0','func1','vfnc0','vfnc1','y_eng','month'
		.dc.b	'mpupo','cache','pxtmp'

		.dc.b	'dske0','dskf0','dskmo','dskid'
		.dc.b	'mwchr','schr0','schr1','scmd0','scmdx'

		.dc.b	'kwait','excod'

		.dc.b	'searc','write','writp'
**		.dc.b	'huarg'

		.dc.b	'padir','eodir'
		.dc.b	'nodsk','no_mo','no_rd','no_cd','no_dr'
		.dc.b	'ndisk','nonmo','nonrd','noncd','nondr'
		.dc.b	'idriv','drvcd','drvmo'
		.dc.b	'cdrom','novol','infom','info2','marki'
		.dc.b	'direc','linkd','dlink'

		.dc.b	'cpdes','copyf','movef','killf','renaf','renad','touch'
		.dc.b	'mkdir','mvdir','dkill'
		.dc.b	'rento','compl','skipf','faild','dfull','wperr','nredy'

		.dc.b	'cderr','rderr','drerr','dirsl','dirsr','g_use','stack'

		.dc.b	'merr0','merr1','merr2','merr3','merr4','merr5','merr6'

		.dc.b	'e_nof','e_fop','e_nom','e_fmt','e_nam','e_drv'
		.dc.b	'e_rdy','e_arg','e_exe'

		.dc.b	'renam','arena','switc','cwild','exitc','phist','phisl'
		.dc.b	'phisr','ijump','icopy','imove','icomd','chist','chism'
		.dc.b	'drive','iwild','volum','stenv','f_ser','dierr','samef'
		.dc.b	'inpmd','sortm','fcomp','print','input'

		.dc.b	'menut','menue','menu1','menu2'

		.dc.b	'scsic','scsie','scsix','scsin','scsim','scsii','scsid'

		.dc.b	'ismis','isinc','isclr','isign','iscon'

		.dc.b	'del??','ddel2','delyn','kyous','kyou2','newdi'

		.dc.b	'helpm','nodef','desct','descp'

		.dc.b	'arcvl','marce','mpdir','mbdir','minfo','marcw','marc2'
		.dc.b	'marcd','marcf','marcm','noarc','marcs','marcr','mtmpe'
		.dc.b	'marcb','ma_e0','ma_e1'

		.dc.b	'vform','l_red','l_end','l_sch','l_eof','l_oom'
		.dc.b	'l_str','l_fil','l_num'
		.dc.b	'vlin0','vmark','vview','vdump','vcdmp','veucj','vsjis'
		.dc.b	'v_jis','vexac','v_bs_','v_esc','v_col','v_reg','v_sha'
		.dc.b	'vline','vfile','vwrit','vsave','vappe','vdone','vnodi'
		.dc.b	'vprot','vfner','vnoma','vschf','vschb','vschr','vhunt'
		.dc.b	'vnotf','vload','vmeme','vmemc'

		.dc.b	'fcmp0','fcmp1','fcmp2','fcmp3','fcmp4'
		.dc.b	'fcmp5','fcmp6','fcmp7','fcmp8','fcmp9'
		.dc.b	'fcmpa','fcmpb','fcmpc','fcmpd','fcmpe'

		.dc.b	'fcsiz','fctim','fcszt'

		.dc.b	'whic0','whic1','whic2','whic3'

		.dc.b	'm_mdx','m_mad','m_mld','m_mcd','m_zmu','m_zm3'
		.dc.b	'm_mid','m_mnd','m_rcd','m_poc'

		.dc.b	'd_mdx','d_mdr','d_mdz','d_mdc','d_zms','d_zmd','d_mid'
		.dc.b	'd_mnd','d_rcp','d_po_','d_scm','d_rcz','d_mdf','d_zdf'
		.dc.b	'd_kdd','d_mki','d_mag','d_hg_','d_pi_','d_pic','d_mit'
		.dc.b	'd_vdt','d_xvd','d_svd','d_brc','d_isd','d_isy','d_ism'
		.dc.b	'd_isz','d_wap','d_dan','d_dim','d_zip'

		.dc.b	'exec1','exec2','exec3','exec4','exec5','exec6','exec7','exec8'
		.dc.b	'exec9','exe10','exe11','exe12','exe13','exe14','exe15','exe16'
		.dc.b	'jump1','jump2','jump3','jump4','jump5','jump6','jump7','jump8'
		.dc.b	'jump9','jum10','jum11','jum12','jum13','jum14','jum15','jum16'
		.dc.b	'cpmv1','cpmv2','cpmv3','cpmv4','cpmv5','cpmv6','cpmv7','cpmv8'
		.dc.b	'cpmv9','cpm10','cpm11','cpm12','cpm13','cpm14','cpm15','cpm16'

		.dc.b	0
		.even


* 標準メッセージ

default_message:
;&title
		.dcb.b	1-.sizeof.(mint_version)&1,' '
		.dc.b	' ─ mint version ',mint_version,' for X680x0 '
	.rept (33-.sizeof.(mint_version))/2
		.dc.b	'─'
	.endm
		.dc.b	'  ',0
;&titl0
		.dcb.b	.sizeof.(mint_version)&1,' '
		.dc.b	' ─ mint version ',mint_version,' '
	.rept (28-.sizeof.(mint_version))/2
		.dc.b	'─'
	.endm
		.dc.b	'  ',0

;&m_mes
		.dc.b	' ────────────────────'
		.dc.b	' madokaInside '
		.dc.b	'──────────────────── ',0

;&func0
		.dc.b	'   f0   ','   f1   ','   f2   ','   f3   ','   f4   '
		.dc.b	'   f5   ','   f6   ','   f7   ','   f8   ','   f9   ',0
;&func1
		.dc.b	'   F0   ','   F1   ','   F2   ','   F3   ','   F4   '
		.dc.b	'   F5   ','   F6   ','   F7   ','   F8   ','   F9   ',0
;&vfnc0
		.dc.b	' FileTop',' FileEnd',' LineJmp','FwSearch',' Fw-Next'
		.dc.b	'  Mark  ','  Write ','  Exit  ','BwSearch',' Bw-Next',0
;&vfnc1
		.dc.b	'        ','        ','        ','BwSearch',' Bw-Next'
		.dc.b	'        ','        ','        ','        ','        ',0
;&y_eng
		.dc.b	'Sun.Mon.Tue.Wed.Thu.Fri.Sat.',0
;&month
		.dc.b	'JanFebMarAprMayJunJulAugSepOctNovDec???',0
;&mpupo
		.dc.b	' MPU-POW:000.0% ',0
;&cache
		.dc.b	' DATAC/INSTRUCT ',0
;&pxtmp
		.dc.b	' PhantomX:--.-- ',0

;&dske0
		.dc.b	'2DDx'	;$e0		;'2DDa'
		.dc.b	' ﾟ-ﾟ'	;$e1
		.dc.b	' ﾟ-ﾟ'	;$e2
		.dc.b	' ﾟ-ﾟ'	;$e3
		.dc.b	' ﾟ-ﾟ'	;$e4
		.dc.b	'1D/9'	;$e5
		.dc.b	'2D/9'	;$e6
		.dc.b	'1D/8'	;$e7
		.dc.b	'2D/8'	;$e8
		.dc.b	'2HQx'	;$e9
		.dc.b	'2HT.'	;$ea
		.dc.b	'2HS.'	;$eb
		.dc.b	'2HDE'	;$ec
		.dc.b	' ﾟ-ﾟ'	;$ed
		.dc.b	'1DD9'	;$ee
		.dc.b	'1DD8'	;$ef
		.dc.b	0
;&dskf0
		.dc.b	'DMF.'	;$f0(2HQ/2ED?)
		.dc.b	'XM6.'	;$f1		;(2HC?)
		.dc.b	'XM6.'	;$f2
		.dc.b	'XM6.'	;$f3
		.dc.b	'NFS.'	;$f4		;'DAT.'
		.dc.b	'CD-R'	;$f5		;'CDRM'
		.dc.b	' MO '	;$f6
		.dc.b	'SCSI'	;$f7
		.dc.b	'SASI'	;$f8
		.dc.b	'RAMD'	;$f9
		.dc.b	'2HQ.'	;$fa
		.dc.b	'2DD8'	;$fb
		.dc.b	'2DD9'	;$fc
		.dc.b	'2HC.'	;$fd
		.dc.b	'2HD.'	;$fe
		.dc.b	' ﾟ-ﾟ'	;$ff(2D/8?)
		.dc.b	0
;&dskmo
		.dc.b	'H68K'	;Human68k
		.dc.b	'IBM '	;IBM
		.dc.b	'sIBM'	;Semi IBM
		.dc.b	0
;&dskid
		.dc.b	' ﾟ-ﾟ'	;$00～$df
		.dc.b	'SUBS'	;仮想ドライブ
		.dc.b	'MARC'	;mintarc
		.dc.b	0
;&mwchr
		.dc.b	'*?_-.[]~=',0
;&schr0
		.dc.b	'<>|',0
;&schr1
		.dc.b	'$&(*;<>?[`{|~',0
;&scmd0
		.dc.b	'break;cd;chdir;cls;copy;date;del;dir;md;memfree;mkdir;'
		.dc.b	'ren;rename;rd;rmdir;screen;time;type;ver;verify;vol'
		.dc.b	0
;&scmdx
		.dc.b	'COMMAND.X',0

;&kwait
		.dc.b	'please hit any key!',0
;&excod
		.dc.b	'Exit ',0

;&searc
		.dc.b	' string  :',0
;&write
		.dc.b	' device write protected. any key to return. ',0
;&writp
		.dc.b	' release write protection. if you can.',0
;&huarg
**		.dc.b	' huge argument ',0

;&padir
		.dc.b	' ── .. ─────────────────── ',0
;&eodir
		.dc.b	' ─────────────────────── ',0
;&nodsk
		.dc.b	' ───────   FD NOT READY   ─────── ',0
;&no_mo
		.dc.b	' ───────   MO NOT READY   ─────── ',0
;&no_rd
		.dc.b	' ──────  RAM-DISK NOT READY  ────── ',0
;&no_cd
		.dc.b	' ──────   CD-ROM NOT READY   ────── ',0
;&no_dr
		.dc.b	' ──────   DRIVE  NOT READY   ────── ',0
;&ndisk
		.dc.b	'── FD Not Ready ──',0
;&nonmo
		.dc.b	'── MO Not Ready ──',0
;&nonrd
		.dc.b	'── RAM Not Ready ─-',0
;&noncd
		.dc.b	'── CD Not Ready ──',0
;&nondr
		.dc.b	'─ Drive  Not Ready ─',0
;&idriv
		.dc.b	'SUBST DRV  ',0
;&drvcd
		.dc.b	'CD-ROM1',0
;&drvmo
		.dc.b	'   MO  ',0
;&cdrom
		.dc.b	'CD-ROM Virtual Drive',0
;&novol
		.dc.b	'no volume name',0
;&infom
		.dc.b	'     Files      KBuse       KB(  %)Free [    ]',0
;&info2
		.dc.b	'                            Device Type [    ]',0
;&marki
		.dc.b	'    Dir    File       K',0
;&direc
		.dc.b	' < DIR >',0
;&linkd
		.dc.b	' <F-LNK>',0
;&dlink
		.dc.b	' <D-LNK>',0

;&cpdes
		.dc.b	' destination : ',0
;&copyf
		.dc.b	' copy   file : ',0
;&movef
		.dc.b	' move   file : ',0
;&killf
		.dc.b	' remove file : ',0
;&renaf
		.dc.b	' rename file : ',0
;&renad
		.dc.b	' rename  dir : ',0
;&touch
		.dc.b	' touch       : ',0
;&mkdir
		.dc.b	' make    dir : ',0
;&mvdir
		.dc.b	' move    dir : ',0
;&dkill
		.dc.b	' remove  dir : ',0
;&rento
		.dc.b	TAB,'->',TAB,0
;&compl
		.dc.b	TAB,' ･････ completed.',0
;&skipf
		.dc.b	TAB,' ･････ skip.',0
;&faild
		.dc.b	TAB,' ･････ error failed!',0
;&dfull
		.dc.b	TAB,' ･････ error! (disk full)',0
;&wperr
		.dc.b	TAB,' ･････ error! (write protect)',0
;&nredy
		.dc.b	TAB,' ･････ error! (not ready)',0

;&cderr
		.dc.b	' change directory error!',0
;&rderr
		.dc.b	' directory remove error!',0
;&drerr
		.dc.b	' drive not ready!',0
;&dirsl
		.dc.b	' too many files! (left window)',0
;&dirsr
		.dc.b	' too many files! (right window)',0
;&g_use
		.dc.b	' GVRAM has been used!',0
;&stack
		.dc.b	' stack overflow!',0

;&merr0
		.dc.b	"最上位ブロックにブロック終端記号 '}' があります.",0
;&merr1
		.dc.b	"ブロック終端記号 '}' がありません.",0
;&merr2
		.dc.b	'未対応のファイル検査子です.',0
;&merr3
		.dc.b	'ファイル検査子の直後にファイル名がありません.',0
;&merr4
		.dc.b	' の直後にブロック "{ ... }" がありません.',0
;&merr5
		.dc.b	' の直前に &if/&unless/&else-if がありません.',0
;&merr6
		.dc.b	' の式が正しくありません.',0

;&e_nof
		.dc.b	' : not found.',0
;&e_fop
		.dc.b	' : too many open files.',0
;&e_nom
		.dc.b	' : no enough memory.',0
;&e_fmt
		.dc.b	' : exec format error.',0
;&e_nam
		.dc.b	' : invalid filename.',0
;&e_drv
		.dc.b	' : invalid drive.',0
;&e_rdy
		.dc.b	' : drive not ready.',0
;&e_arg
		.dc.b	' : too huge argument.',0
;&e_exe
		.dc.b	' : exec error.',0

;&renam
		.dc.b	' edit file information ',0
;&arena
		.dc.b	' edit marked file information ',0
;&switc
		.dc.b	' control panel       space,↑,↓←,→/RET/ESC ',0
;&cwild
		.dc.b	' wild card(s) ',0
;&exitc
		.dc.b	' exit path selector ',0
;&phist
		.dc.b	' path history selector ',0
;&phisl
		.dc.b	' path history selector (left) ',0
;&phisr
		.dc.b	' path history selector (right) ',0
;&ijump
		.dc.b	' input jump path ',0
;&icopy
		.dc.b	' input copy path ',0
;&imove
		.dc.b	' input move path ',0
;&icomd
		.dc.b	' edit operands ',0
;&chist
		.dc.b	' command history ',0
;&chism
		.dc.b	' command history menu ',0
;&drive
		.dc.b	' drive menu ',0
;&iwild
		.dc.b	' input path mask ',0
;&volum
		.dc.b	' change volume name ',0
;&stenv
		.dc.b	' set environment variable ',0
;&f_ser
		.dc.b	' incremental-search ',0
;&dierr
		.dc.b	' destination path not exist ',0
;&samef
		.dc.b	' duplicate file name exist ',0
;&inpmd
		.dc.b	' make directory ',0
;&sortm
		.dc.b	' sorting ',0
;&fcomp
		.dc.b	' file compare ',0
;&print
		.dc.b	' information ',0
;&input
		.dc.b	'please input user value',0	;都合により両端の空白は不要

;&menut
		.dc.b	' menu ',0
;&menue
		.dc.b	' menu error ',0
;&menu1
		.dc.b	' 文法違反です ',0
;&menu2
		.dc.b	' 項目数が多すぎます ',0

;&scsic
		.dc.b	' SCSI device ',0
;&scsie
		.dc.b	' SPC not found.',0
;&scsix
		.dc.b	'X680x0     HAYAKAWA-ELECTRIC',0
;&scsin
		.dc.b	'device not found',0
;&scsim
		.dc.b	' SCSI menu ',0
;&scsii
		.dc.b	'SHARP   X680x0(initiator)',0
;&scsid			;0123456701234567890123456789
*		.dc.b	' (device is not connected.)',0
		.dc.b	'  ------------------------',0

;&ismis
		.dc.b	'missmatch: input backspace',0
;&isinc
		.dc.b	' incomplete input         ',0
;&isclr
		.dc.b	'                          ',0
;&isign
		.dc.b	'  match  : ignore case     [^m]',0
;&iscon
		.dc.b	'  match  : conscious case  [^m]',0

;&del??
		.dc.b	' file & directory delete ',0
;&ddel2
		.dc.b	' file exist in the directory ',0
;&delyn
		.dc.b	' delete files and directories [y]/n',0
;&kyous
		.dc.b	' attribute protection ',0
;&kyou2
		.dc.b	' attribute protection. permission denied ([y]/else)',0
;&newdi
		.dc.b	' create new directory [y]/n',0

;&helpm
		.dc.b	' help ',0
;&nodef
		.dc.b	' can not found ">NO_DEF"',0
;&desct
		.dc.b	' mint key bind help ',0
;&descp
		.dc.b	' please hit target key.',0

;&arcvl
		.dc.b	'Mintarc Virtual Dir.',0
;&marce
		.dc.b	' mintarc error ',0
;&mpdir
		.dc.b	' ── .. ─────────────────── ',0
;&mbdir
		.dc.b	' ─────────────────────── ',0
;&minfo
		.dc.b	'     Entry      KBarc       KB(  %)Ratio[    ]',0
;&marcw
		.dc.b	' extracted file is modified ',0
;&marc2
		.dc.b	' Do you want to update archive file ?  ([Y]/else)',0
;&marcd
		.dc.b	' archive file is protected by attribute ',0
;&marcf
		.dc.b	' アーカイブファイルの操作に失敗しました！',0
;&marcm
		.dc.b	' メモリが確保できません！',0
;&noarc
		.dc.b	' このアーカイブには対応していません！',0
;&marcs
		.dc.b	' 仮想ドライブ割付エラー！',0
;&marcr
		.dc.b	' 仮想ドライブ解除エラー！',0
;&mtmpe
		.dc.b	'環境変数 MINTTMP の示すディレクトリが存在しません … ',0
;&marcb
		.dc.b	'mintarc: メモリ不足のため _FILES バッファを確保できません',0
;&ma_e0
		.dc.b	'mintarc: system error #1 (BUG): '
		.dc.b	'指定ファイルが OLD_FILES_BUF から見つかりません',0
;&ma_e1
		.dc.b	'mintarc: system error #2 (BUG): '
		.dc.b	'_FILES バッファは既に確保されています',0

;&vform
		.dc.b	'─ νmadoka($M) $19 $F $44* $C $S $B $E $^ $R *',0
;&l_red
		.dc.b	' now reading...',0
;&l_end
		.dc.b	' ready',0
;&l_sch
		.dc.b	' search : ',0
;&l_eof
		.dc.b	'[EOF]',0
;&l_oom
		.dc.b	'[Out of Memory]',0
;&l_str
		.dc.b	' input string ',0
;&l_fil
		.dc.b	' input filename ',0
;&l_num
		.dc.b	' input number ',0
;&vlin0
		.dc.b	'     0/     0',0
;&vmark
		.dc.b	'Mark (     )',0
;&vview
		.dc.b	'VIEW',0
;&vdump
		.dc.b	'DUMP',0
;&vcdmp
		.dc.b	'CDMP',0
;&veucj
		.dc.b	'EUC-JPN',0
;&vsjis
		.dc.b	'S-JIS',0
;&v_jis
		.dc.b	'JIS',0
;&vexac
		.dc.b	'EXACT',0
;&v_bs_
		.dc.b	'BS',0
;&v_esc
		.dc.b	'ESC',0
;&v_col
		.dc.b	'COLOR',0
;&v_reg
		.dc.b	'REGULAR',0
;&v_sha
		.dc.b	'#',0
;&vline
		.dc.b	'Line ?:',0
;&vfile
		.dc.b	'manami',0
;&vwrit
		.dc.b	'Now Writing -> ',0
;&vsave
		.dc.b	'replace? [y]es [a]pp. [r]en.',0
;&vappe
		.dc.b	'Appending   -> ',0
;&vdone
		.dc.b	'...done',0
;&vnodi
		.dc.b	'Device Not Ready',0
;&vprot
		.dc.b	'Write Error [Write Protect]',0
;&vfner
		.dc.b	'File open error',0
;&vnoma
		.dc.b	'Non Mark.',0
;&vschf
		.dc.b	'FwSearch:',0
;&vschb
		.dc.b	'BwSearch:',0
;&vschr
		.dc.b	'search regexp:',0
;&vhunt
		.dc.b	'now hunting string … ',0
;&vnotf
		.dc.b	' not found',0
;&vload
		.dc.b	' load error.',0
;&vmeme
		.dc.b	'memory exhausted.',0
;&vmemc
		.dc.b	'memory block connection failed.',0

;&fcmp0
		.dc.b	'NEWer than this file.',0
;&fcmp1
		.dc.b	'OLDer than this file.',0
;&fcmp2
		.dc.b	'BIGger than this one.',0
;&fcmp3
		.dc.b	'LESS  than this file.',0
;&fcmp4
		.dc.b	'same  time  stamped. ',0
;&fcmp5
		.dc.b	'      same  size.    ',0
;&fcmp6
		.dc.b	'      FAT  match.    ',0
;&fcmp7
		.dc.b	' the    same    file ',0
;&fcmp8
		.dc.b	' 1KB compare / match ',0
;&fcmp9
		.dc.b	' 1KB cmp / miss match',0
;&fcmpa
		.dc.b	' Information.  : [                      ]',0
;&fcmpb
		.dc.b	' File    size  : [                      ]',0
;&fcmpc
		.dc.b	' Time   stamp  : [                      ]',0
;&fcmpd
		.dc.b	' File    name  : [                      ]',0
;&fcmpe
		.dc.b	' Compare name  : [                      ]',0

;&fcsiz
		.dc.b	' size missmatch : ',0
;&fctim
		.dc.b	' timestamp missmatch : ',0
;&fcszt
		.dc.b	' size & timestamp missmatch : ',0

;&whic0
		.dc.b	' は、',0
;&whic1
		.dc.b	' です.',0
;&whic2
		.dc.b	'mint 組み込み関数です.',0
;&whic3
		.dc.b	'きまぐれ･まどかさん の感知するところではありません.',0

;&m_mdx
		.dc.b	' [ MXDRV ] ',0
;&m_mad
		.dc.b	' [ MADRV ] ',0
;&m_mld
		.dc.b	' [ MLD ] ',0
;&m_mcd
		.dc.b	' [ MCDRV ] ',0
;&m_zmu
		.dc.b	' [ Z-MUSIC ] ',0
;&m_zm3
		.dc.b	' [ ZMSC3 ] ',0
;&m_mid
		.dc.b	' [ MIDDRV ] ',0
;&m_mnd
		.dc.b	' [ MNDRV ] ',0
;&m_rcd
		.dc.b	' [ RCD ] ',0
;&m_poc
		.dc.b	' [ POCHI ] ',0

;&d_mdx
		.dc.b	' (MDX) ',0
;&d_mdr
		.dc.b	' (MDR) ',0
;&d_mdz
		.dc.b	' (MDZ) ',0
;&d_mdc
		.dc.b	' (MDC) ',0
;&d_zms
		.dc.b	' (ZMS) ',0
;&d_zmd
		.dc.b	' (ZMD) ',0
;&d_mid
		.dc.b	' (MID) ',0
;&d_mnd
		.dc.b	' (MND) ',0
;&d_rcp
		.dc.b	' (RCP) ',0
;&d_po_
		.dc.b	' (PO) ',0
;&d_scm
		.dc.b	' (SCM) ',0
;&d_rcz
		.dc.b	' (RCZ) ',0
;&d_mdf
		.dc.b	' (MDF) ',0
;&d_zdf
		.dc.b	' (ZDF) ',0
;&d_kdd
		.dc.b	' (KDD) ',0
;&d_mki
		.dc.b	' (MKI) ',0
;&d_mag
		.dc.b	' (MAG) ',0
;&d_hg_
		.dc.b	' (HG) ',0
;&d_pi_
		.dc.b	' (PI) ',0
;&d_pic
		.dc.b	' (PIC) ',0
;&d_mit
		.dc.b	' (MIT) ',0
;&d_vdt
		.dc.b	' (VDT) ',0
;&d_xvd
		.dc.b	' (XVD) ',0
;&d_svd
		.dc.b	' (SVD) ',0
;&d_brc
		.dc.b	' (BRC) ',0
;&d_isd
		.dc.b	' (ISD) ',0
;&d_isy
		.dc.b	' (ISD) ',0
;&d_ism
		.dc.b	' (ISD) ',0
;&d_isz
		.dc.b	' (ISD) ',0
;&d_wap
		.dc.b	' (WAP) ',0
;&d_dan
		.dc.b	' (DAN) ',0
;&d_dim
		.dc.b	' (DIM) ',0
;&d_zip
		.dc.b	' (ZIP) ',0

;&exec1
		.dc.b	' exec menu-01 ',0
;&exec2
		.dc.b	' exec menu-02 ',0
;&exec3
		.dc.b	' exec menu-03 ',0
;&exec4
		.dc.b	' exec menu-04 ',0
;&exec5
		.dc.b	' exec menu-05 ',0
;&exec6
		.dc.b	' exec menu-06 ',0
;&exec7
		.dc.b	' exec menu-07 ',0
;&exec8
		.dc.b	' exec menu-08 ',0
;&exec9
		.dc.b	' exec menu-09 ',0
;&exe10
		.dc.b	' exec menu-10 ',0
;&exe11
		.dc.b	' exec menu-11 ',0
;&exe12
		.dc.b	' exec menu-12 ',0
;&exe13
		.dc.b	' exec menu-13 ',0
;&exe14
		.dc.b	' exec menu-14 ',0
;&exe15
		.dc.b	' exec menu-15 ',0
;&exe16
		.dc.b	' exec menu-16 ',0
;&jump1
		.dc.b	' path jump menu-01 ',0
;&jump2
		.dc.b	' path jump menu-02 ',0
;&jump3
		.dc.b	' path jump menu-03 ',0
;&jump4
		.dc.b	' path jump menu-04 ',0
;&jump5
		.dc.b	' path jump menu-05 ',0
;&jump6
		.dc.b	' path jump menu-06 ',0
;&jump7
		.dc.b	' path jump menu-07 ',0
;&jump8
		.dc.b	' path jump menu-08 ',0
;&jump9
		.dc.b	' path jump menu-09 ',0
;&jum10
		.dc.b	' path jump menu-10 ',0
;&jum11
		.dc.b	' path jump menu-11 ',0
;&jum12
		.dc.b	' path jump menu-12 ',0
;&jum13
		.dc.b	' path jump menu-13 ',0
;&jum14
		.dc.b	' path jump menu-14 ',0
;&jum15
		.dc.b	' path jump menu-15 ',0
;&jum16
		.dc.b	' path jump menu-16 ',0
;&cpmv1
		.dc.b	' path copy menu-01 ',0
;&cpmv2
		.dc.b	' path copy menu-02 ',0
;&cpmv3
		.dc.b	' path copy menu-03 ',0
;&cpmv4
		.dc.b	' path copy menu-04 ',0
;&cpmv5
		.dc.b	' path copy menu-05 ',0
;&cpmv6
		.dc.b	' path copy menu-06 ',0
;&cpmv7
		.dc.b	' path copy menu-07 ',0
;&cpmv8
		.dc.b	' path copy menu-08 ',0
;&cpmv9
		.dc.b	' path copy menu-09 ',0
;&cpm10
		.dc.b	' path copy menu-10 ',0
;&cpm11
		.dc.b	' path copy menu-11 ',0
;&cpm12
		.dc.b	' path copy menu-12 ',0
;&cpm13
		.dc.b	' path copy menu-13 ',0
;&cpm14
		.dc.b	' path copy menu-14 ',0
;&cpm15
		.dc.b	' path copy menu-15 ',0
;&cpm16
		.dc.b	' path copy menu-16 ',0

print_mes_footer:
		.dc.b	CR,LF,0


* Block Storage Section ----------------------- *

		.bss
		.even

mes_ptr_table::	.ds.l	MESNO_MAX

mes_dec_buf0:	.ds.b	MESLEN_MAX+1
mes_dec_buf1:	.ds.b	MESLEN_MAX+1


		.end

* End of File --------------------------------- *
