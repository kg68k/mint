# mint.s - Madoka INTerpreter  PhantomX
# Copyright (C) 2024 TcbnErik
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


.include doscall.mac

PHANTOMX_EA8000_REG:  .equ $ea8000
PHANTOMX_EA8002_DATA: .equ $ea8002

PHANTOMX_TEMPERATURE: .equ $00f0


.cpu 68000
.text

DosBusErrWord::
  move #2,-(sp)
  move.l sp,-(sp)
  move.l a0,-(sp)
  DOS _BUS_ERR
  move.l d0,(sp)
  moveq #0,d0
  move (8,sp),d0
  tst.l (sp)+
  addq.l #10-4,sp
  rts


;PhantomXが装着されているか調べる。
;out d0/ccr
PhantomX_Exists::
  move.l a0,-(sp)
  lea (PHANTOMX_EA8000_REG),a0
  bsr DosBusErrWord
  bne @f
    moveq #1,d0
    bra 9f
  @@:
  moveq #0,d0
9:
  movea.l (sp)+,a0
  rts


;Raspberry Pi SOCの温度を取得する。
;  PhantomXの装着を確認しておくこと。
;  スーパーバイザモードで呼び出すこと。
;out d0.l ... 温度(BCD 4桁、上位ワードは $0000)
PhantomX_GetTemperature::
  moveq #.notb.PHANTOMX_TEMPERATURE,d0
  not.b d0
  bra getData


getData:
  move sr,-(sp)
  ori #$0700,sr
  move d0,(PHANTOMX_EA8000_REG)
  move (PHANTOMX_EA8002_DATA),d0
  move (sp)+,sr
  rts


.end
