AS = /usr/bin/nasm
LD = /usr/bin/gcc

ASFLAGS = -g -f elf64
LDFLAGS = -no-pie -static

SRCS = lab.s
OBJS = $(SRCS:.s=.o)

EXE = lab

all: $(SRCS) $(EXE)

clean:
	rm -rf $(EXE) $(OBJS)

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -lm -o $@

.s.o:
	$(AS) $(ASFLAGS) $< -o $@
