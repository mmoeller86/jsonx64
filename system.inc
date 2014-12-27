ifdef ELF64
arg0	equ	<rdi>
arg0d	equ	<edi>
arg1	equ	<rsi>
arg2	equ	<rdx>
arg2d	equ	<edx>
arg3	equ	<rcx>
else
arg0	equ	<rcx>
arg0d	equ	<ecx>
arg1	equ	<rdx>
arg2	equ	<r8>
arg2d	equ	<r8d>
arg3	equ	<r9>
endif
