AR=ar
CC=cc
JWASM=$(HOME)/JWasm211as/jwasm
JWFLAGS=-zcw -zt0 -elf64

OBJS=json.o buffer.o node.o str.o array.o
all: libjsonx64.a test

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

libjsonx64.a: $(OBJS)
	rm -f $@
	$(AR) rc $@ $(OBJS)

test: libjsonx64.a test.o
	$(CC) -o $@ test.o libjsonx64.a

clean:
	rm -f test libjsonx64.a *.o *.err
