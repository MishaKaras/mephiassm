AS = /usr/bin/nasm
CC = /usr/bin/gcc

CCFLAGS = -c -O0 -Wall -Wextra
ASFLAGS = -f elf64
LDFLAGS = -static -z noexecstack

SRCS = main.c image.c imageasm.s
HEAD = image.h stb_image.h stb_image_write.h
OBJS = main.o image.o imageasm.o

EXE = lab

all: $(SRCS) $(EXE)

clean:
	rm -rf $(EXE) $(OBJS)

$(OBJS): $(HEAD)

$(EXE): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -lm -lc -o $@

.c.o:
	$(CC) $(CCFLAGS) $< -o $@

.s.o:
	$(AS) $(ASFLAGS) $< -o $@
