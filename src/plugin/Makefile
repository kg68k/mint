# Makefile for mint version 3 plug-in

AS = has060
ASFLAGS = -w2 -i../include -sPLUG_IN
#         -s__DEBUG__

ifndef LD
LD = hlk
endif
LDFLAGS =
ifeq ($(findstring hlkx,$(LD)),hlkx)
USE_HLKX = true
else
CV = /usr/xc/bin/cv.x
endif

SRCS = winf_0.s winf_1.s winf_2.s winf_3.s winf_4.s \
       winf_mor1.s winf_mor2.s winf_ss.s \
       exit_scr.s

OBJS = $addprefix (o/$(SRCS:.s=.o))

TRASH = $(OBJS)

all: directories $(SRCS:.s=.r)

directories: o

o:
	mkdir $@

mac = ../include/mint.mac
#m = ../include/message.mac
#r = ../include/mrl.mac
#s = ../include/sysval.def
#v = ../include/version.mac
#w = ../include/window.mac

o/winf_0.o: winf_0.s $(mac)
o/winf_1.o: winf_1.s $(mac)
o/winf_2.o: winf_2.s $(mac)
o/winf_3.o: winf_3.s $(mac)
o/winf_4.o: winf_4.s $(mac)

o/winf_mor1.o: winf_mor1.s $(mac)
o/winf_mor2.o: winf_mor2.s $(mac)
o/winf_ss.o:   winf_ss.s   $(mac)

o/exit_scr.o: exit_scr.s $(mac)

%.r: o/%.o
ifdef USE_HLKX
	$(LD) $(LDFLAGS) -r -o$@ $^
else
	$(LD) $(LDFLAGS) -o$(*F).x $^
	$(CV) $(*F).x
endif

o/%.o: %.s
	$(AS) $(ASFLAGS) -o$@ $<

clean: $(OBJS)
	-rm -f $^

# EOF
