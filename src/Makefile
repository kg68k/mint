# Makefile for mint

AS	= has060
ASFLAGS	= -w2 -i./include
#	  -s__DEBUG__
#	  -sNO_KG_CDROM		# 計測技研の CD-ROM ドライバに対応しない(定義不要)
#	  -sNO_LNDRV_BUG	# 不具合のある lndrv に対応しない(定義不要)

ifndef LD
LD	= hlk
endif
LDFLAGS	=
#	  -po/mint.map
#	  -x

CC	= gcc2
CFLAGS	= -Wall -Werror -W -O2

MKDIR	= mkdir

PROG	= mint.x
OBJS	= o/mint.o o/madoka3.o o/funcname.o o/cmdhis.o o/mintarc.o o/window.o \
	  o/cpmv.o o/fileop.o o/filecmp.o o/isearch.o o/rename.o o/menu.o o/help.o \
	  o/outside.o o/pathhis.o o/gvon.o o/look.o o/message.o o/music.o \
	  o/datatitle.o o/titleload.o o/patternmatch.o o/mrl.o o/rl.o \
	  o/phantomx.o o/version.o

TRASH	= $(OBJS) o/mint.map o/mkfunctbl.x

PKGTMP = pkgtmp

.PHONY: all directories archive

all: directories $(PROG)

directories: o

o $(PKGTMP):
	$(MKDIR) $@

$(PROG): $(OBJS)
	$(LD) $(LDFLAGS) -o$@ $^


mac = include/mint.mac
f = include/func.mac
m = include/message.mac
r = include/mrl.mac
s = include/sysval.def
v = include/version.mac
w = include/window.mac

#o/%.o :: %.s $(mac) $m $s $w $v
#	$(AS) $(ASFLAGS) -o$@ $<

o/mint.o:	mint.s		$(mac) $m $v $w $r $f
o/madoka3.o:	madoka3.s	$(mac) $m $s $w $r $f
o/funcname.o:	funcname.s	$(mac)             $f functbl.s
o/cmdhis.o:	cmdhis.s	$(mac) $m $s $w $r
o/mintarc.o:	mintarc.s	$(mac) $m $s $w    $f
o/window.o:	window.s	$(mac)	  $s $w
o/cpmv.o:	cpmv.s		$(mac) $m $s $w $r include/dos_mvdir.mac
o/fileop.o:	fileop.s	$(mac) $m $s $w $r
o/filecmp.o:	filecmp.s	$(mac) $m $s $w
o/isearch.o:	isearch.s	$(mac) $m $s $w    $f
o/rename.o:	rename.s	$(mac) $m $s $w $r
o/menu.o:	menu.s		$(mac) $m $s $w $r
o/help.o:	help.s		$(mac) $m $s $w
o/titleload.o:	titleload.s	$(mac)
o/outside.o:	outside.s	$(mac) $m $s $w    $f
o/gvon.o:	gvon.s		$(mac) $m $s
o/look.o:	look.s		$(mac) $m $s $w $r $f
o/message.o:	message.s	$(mac) $m $v
o/music.o:	music.s		$(mac) $m $s
o/datatitle.o:	datatitle.s	$(mac) $m $s
o/pathhis.o:	pathhis.s	$(mac) $m $s $w
o/patternmatch.o:patternmatch.s	$(mac)	  $s
o/mrl.o:	mrl.s		$(mac) $m $s $w $r $f include/rl.mac
o/rl.o:		rl.s		$(mac)		      include/rl.mac
o/phantomx.o:	phantomx.s
o/version.o:	version.s	$(mac)	  $v

o/mkfunctbl.x: mkfunctbl.c
	$(CC) $(CFLAGS) -o $@ $^

functbl.s: o/mkfunctbl.x $f
	rm -f $@
	o/mkfunctbl.x < $f > $@

o/%.o: %.s
	$(AS) $(ASFLAGS) -o$@ $<

clean: $(TRASH)
	-rm -f $(TRASH)

archive: $(PKGTMP) $(PROG)
	make -C $(PKGTMP) -f ../Package.mk


# EOF
