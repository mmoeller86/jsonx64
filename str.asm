	; String Utility Procedures

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_str_alloc
	public json_str_add_char

	.code

json_str_alloc PROC
	mov	rdi, 1
	mov	rsi, 1
	call	calloc
	ret
json_str_alloc ENDP

json_str_add_char PROC stri: Ptr, len: Ptr, cha: QWORD
	mov	rdi, stri
	mov	rdi, [rdi]
	mov	rcx, len
	mov	rcx, [rcx]
	inc	rcx

	mov	rsi, rcx
	push	rcx
	call	realloc
	pop	rcx
	test	rax, rax
	jz	@1

	mov	rdi, rax
	mov	al, byte ptr cha

	mov	[rdi + rcx -2], al
	mov	byte ptr [rdi + rcx -1], 0

	mov	rax, len
	mov	[rax], rcx
	mov	rcx, stri
	mov	[rcx], rdi
	clc
	ret

@1:	stc
	ret	
json_str_add_char ENDP

	END
