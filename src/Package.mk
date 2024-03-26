# Makefile for mint (create archive file)
#  usage: mkdir pkgtmp; make -C pkgtmp -f ../Package.mk

SRCDIR_MK = ../../srcdir.mk
SRC_DIR = ../../src
-include $(SRCDIR_MK)

ROOT_DIR = $(SRC_DIR)/..

CP_P = cp -p
MKDIR = mkdir
STRIP = strip
U8TOSJ = u8tosj

MINT_ZIP = mint.zip

DIRS = docs emacs madoka plugin

DOCS_ = COMMIT.txt \
        FAQ.txt \
        LICENSE.txt \
        madoka.txt \
        mint.txt \
        mintenv.txt \
        mintenv_sys.txt \
        mintenv_sysres.txt \
        mintfunc.txt \
        mintmisc.txt \
        v225_to_v3.txt \
        v3_extend.txt
DOCS = $(addprefix docs/,$(DOCS_))

EMACS_ = comp_etc.zip mint_micro_emacs
EMACS = $(addprefix emacs/,$(EMACS_))

MADOKA_ = arrmenu.mis \
          atr_mark.mis \
          autoepic.mis \
          break.mis \
          digicame.mis \
          iris_cp.mis \
          makemenu.mis \
          pal_il.mis \
          pal_il2.mis \
          pal_il3.mis \
          reomenu.mis \
          script.txt \
          uniq_check.mis
MADOKA = $(addprefix madoka/,$(MADOKA_))

PLUGIN_ = exit_scr.r \
          winf_0.r \
          winf_1.r \
          winf_2.r \
          winf_3.r \
          winf_4.r \
          winf_mor1.r \
          winf_mor2.r \
          winf_ss.r
PLUGIN = $(addprefix plugin/,$(PLUGIN_))

FILES = $(DOCS) $(EMACS) $(MADOKA) $(PLUGIN) \
        CHANGELOG.txt LICENSE README.txt _mint mint.x

.PHONY: all

all: $(MINT_ZIP)

$(DIRS):
	$(MKDIR) $@

docs/FAQ.txt: $(ROOT_DIR)/docs/FAQ.md
	$(U8TOSJ) < $^ >! $@

docs/%: $(ROOT_DIR)/docs/%
	$(U8TOSJ) < $^ >! $@

emacs/%: $(ROOT_DIR)/emacs/%
	rm -f $@
	$(CP_P) $^ $@

madoka/%: $(ROOT_DIR)/madoka/%
	$(U8TOSJ) < $^ >! $@

plugin/%: ../plugin/%
	rm -f $@
	$(CP_P) $^ $@

LICENSE: $(ROOT_DIR)/LICENSE
	rm -f $@
	$(CP_P) $^ $@

%.txt: $(ROOT_DIR)/%.md
	$(U8TOSJ) < $^ >! $@

_mint: $(ROOT_DIR)/_mint
	$(U8TOSJ) < $^ >! $@

mint.x: ../mint.x
	rm -f $@
	$(CP_P) $^ $@
	$(STRIP) $@

$(MINT_ZIP): $(DIRS) $(FILES)
	rm -f $@
	zip -9 $@ $^


# EOF
