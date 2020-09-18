Q               := @
CC              := gcc -std=gnu99
SRCS            := $(wildcard *.c)
OBJS_32         := $(SRCS:.c=.o32)
OBJS_64         := $(SRCS:.c=.o64)
TARGET_32       := emucd_32
TARGET_64       := emucd_64
CFLAGS_32       := -m32 -I./include
CFLAGS_64       := -m64 -I./include
LDFLAGS_32      := lib_emuc2_32.a -m32 -lm -lpthread
LDFLAGS_64      := lib_emuc2_64.a -m64 -lm -lpthread
LBITS           := $(shell getconf LONG_BIT)

.PHONY: all both clean

ifeq ($(LBITS),64)
    all: .depend64 $(TARGET_64)
else
    all: .depend32 $(TARGET_32)
endif

both: .depend $(TARGET_32) $(TARGET_64)

%.o32: %.c Makefile
	$(Q)echo "  Compiling '$<' ..."
	$(Q)$(CC) $(CFLAGS_32) -o $@ -c $<

%.o64: %.c Makefile
	$(Q)echo "  Compiling '$<' ..."
	$(Q)$(CC) $(CFLAGS_64) -o $@ -c $<

$(TARGET_32): $(OBJS_32)
	$(Q)echo "  $(COLOR_G)Building '$@' VER=$(AP_VER)... $(COLOR_W)"
	$(Q)$(CC) -o $@ $(OBJS_32) $(LDFLAGS_32)
	$(Q)cp $(TARGET_32) ../

$(TARGET_64): $(OBJS_64)
	$(Q)echo "  $(COLOR_G)Building '$@' VER=$(AP_VER)... $(COLOR_W)"
	$(Q)$(CC) -o $@ $(OBJS_64) $(LDFLAGS_64)
	$(Q)cp $(TARGET_64) ../

clean:
	$(Q)rm -f .depend *~ *.bak *.res *.o32 *.o64
	$(Q)echo "  Cleaning '$(TARGET_32)' ..."
	$(Q)rm -f $(TARGET_32) ../$(TARGET_32)
	$(Q)echo "  Cleaning '$(TARGET_64)' ..."
	$(Q)rm -f $(TARGET_64) ../$(TARGET_64)

.depend:
	$(Q)echo "  Generating '$@' ..."
	$(Q)$(CC) $(CFLAGS_32) -M *.c > $@
	$(Q)$(CC) $(CFLAGS_64) -M *.c > $@

.depend32:
	$(Q)echo "  Generating '$@' ..."
	$(Q)$(CC) $(CFLAGS_32) -M *.c > $@

.depend64:
	$(Q)echo "  Generating '$@' ..."
	$(Q)$(CC) $(CFLAGS_64) -M *.c > $@


ifeq (.depend, $(wildcard .depend))
	include .depend
endif

ifeq (.depend32, $(wildcard .depend32))
	include .depend32
endif

ifeq (.depend64, $(wildcard .depend64))
	include .depend64
endif

