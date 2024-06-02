# funcname.s - builtin function name table
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

.include mint.mac
.include func.mac

.cpu 68000

.include functbl.s

.text
.even

* 内部関数を検索する -------------------------- *
* in  a0.l 関数名(先頭の'&'のアドレス)
* out d0.l 関数の処理アドレス(見つからなかった場合は0を返す)
*     ccr  <tst.l d0> の結果

dLen1: .reg d7
aTmp1: .reg a1
aTmp2: .reg a2
aLow:  .reg a3
aMid:  .reg a4
aHigh: .reg a5
aName: .reg a6

search_builtin_func::
  PUSH dLen1/a0/aTmp1/aTmp2/aLow/aMid/aHigh/aName
  cmpi.b #'&',(a0)+
  bne sbf_not_found
  STRLEN a0,dLen1  ;引数文字列+NULの長さ('&'は含まない)-1
  beq sbf_not_found

  lea (FuncAddrTable),aLow
  lea (FuncAddrTableEnd-4-FuncAddrTable,aLow),aHigh
  lea (FuncNameList-FuncAddrTable,aLow),aName
  sbf_loop:
    move.l aLow,d0  ;(low+high)/2 -> mid
    add.l aHigh,d0  ;  アドレスの最上位ビットは0なので
    lsr.l #1,d0     ;  low+(high-low)/2 にしなくてよい
    andi #.not.3,d0
    movea.l d0,aMid

    move (aMid),d0  ;(sXXX-S)<<12+＆xxx の上位ワード
    lsr #32-(16+FUNC_NAME_BITS),d0

    lea (a0),aTmp1          ;検索する文字列
    lea (aName,d0.w),aTmp2  ;midの関数名
    move dLen1,d0
    @@:
      cmpm.b (aTmp1)+,(aTmp2)+  ;mid の文字列と比較
    dbne d0,@b
    bcc @f
      addq.l #4,aMid  ;mid より大きければ、次は mid+1 ... high から探す
      movea.l aMid,aLow
      sbf_next:
      move.l aHigh,d0
      sub.l aLow,d0
      bcc sbf_loop
        sbf_not_found:
        moveq #0,d0  ;ここで不一致だった要素が最後の1要素だった
        bra sbf_end  ;(または最後の2要素 [a(=mid),b] で mid<X だった場合)
    @@:
    beq sbf_found
      subq.l #4,aMid  ;mid より小さければ、次は low ... mid-1 から探す
      movea.l aMid,aHigh
      bra sbf_next
  sbf_found:
    move.l (aMid),d0  ;関数名が一致した
    andi.l #1<<(32-FUNC_NAME_BITS)-1,d0  ;処理アドレスのオフセットを取り出す
    addi.l #FUNC_ADDR_BASE,d0
sbf_end:
  POP dLen1/a0/aTmp1/aTmp2/aLow/aMid/aHigh/aName
  rts

* 内部関数名を取得する ------------------------ *
* in  d0.w 通し番号(0～)
* out d0.l 関数名文字列のアドレス(先頭に'&'はつかない)
*          見つからなかった場合は0を返す
*     ccr  <tst.l d0> の結果

get_builtin_func_name::
  move.l a0,-(sp)
  suba.l a0,a0
  cmpi #(FuncAddrTableEnd-FuncAddrTable)/4,d0
  bcc 9f
    lea (FuncAddrTable),a0
    lsl #2,d0
    move (a0,d0.w),d0  ;(sXXX-S)<<12+＆xxx の上位ワード
    lsr #32-(16+FUNC_NAME_BITS),d0
    lea (FuncNameList-FuncAddrTable,a0),a0
    adda d0,a0
  9:
  move.l a0,d0
  movea.l (sp)+,a0
  rts


.end
