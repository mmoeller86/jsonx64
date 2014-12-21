AR=ar
CC=cc
JWASM=$(HOME)/JWasm211as/jwasm
JWFLAGS=-zcw -zt0 -elf64

OBJS=json.o buffer.o node.o str.o array.o
all: $(OBJS)

json.o: json.asm
	$(JWASM) $(JWFLAGS) $?

buffer.o: buffer.asm
	$(JWASM) $(JWFLAGS) $?

node.o: node.asm
	$(JWASM) $(JWFLAGS) $?

str.o: str.asm
	$(JWASM) $(JWFLAGS) $?

array.o: array.asm
	$(JWASM) $(JWFLAGS) $?

clean:
	rm -f *.o *.err
