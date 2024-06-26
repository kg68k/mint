# Makefile to convert UTF-8 source files to Shift_JIS.
#   Do not use non-ASCII characters in this file.

MKDIR_P = mkdir -p
U8TOSJ = u8tosj

SRCDIR_MK = srcdir.mk
SRC_DIR = src
-include $(SRCDIR_MK)

BLD_DIR = build

SRCS = $(wildcard $(SRC_DIR)/*) $(wildcard $(SRC_DIR)/include/*) $(wildcard $(SRC_DIR)/plugin/*)
SJ_SRCS = $(subst $(SRC_DIR)/,$(BLD_DIR)/,$(SRCS))


.PHONY: all directories srcdir_mk clean

all: directories $(SJ_SRCS)

directories: $(BLD_DIR) $(BLD_DIR)/include $(BLD_DIR)/plugin

$(BLD_DIR) $(BLD_DIR)/include $(BLD_DIR)/plugin:
	$(MKDIR_P) $@

$(BLD_DIR)/include/%: $(SRC_DIR)/include/%
	$(U8TOSJ) < $^ >! $@

$(BLD_DIR)/plugin/%: $(SRC_DIR)/plugin/%
	$(U8TOSJ) < $^ >! $@

$(BLD_DIR)/%: $(SRC_DIR)/%
	$(U8TOSJ) < $^ >! $@


# Do not use $(SRCDIR_MK) as the target name to prevent automatic remaking of the makefile.
srcdir_mk:
	rm -f $(SRCDIR_MK)
	echo "SRC_DIR = $(CURDIR)/src" > $(SRCDIR_MK)


clean:
	rm -f $(SJ_SRCS)
	-rmdir $(BLD_DIR)/include $(BLD_DIR)/plugin $(BLD_DIR)

# EOF
