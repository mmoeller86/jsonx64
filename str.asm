	; String Utility Procedures

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_str_alloc
	public json_str_add_char

	.code

json_str_alloc PROC
	mov	arg0, 1
	mov	arg1, 1
	call	calloc
	ret
json_str_alloc ENDP

json_str_add_char PROC stri: Ptr, len: Ptr, cha: QWORD
	mov	arg0, stri
	mov	arg0, [arg0]
	mov	rcx, len
	mov	rcx, [rcx]
	inc	rcx

	mov	arg1, rcx
	push	rcx
	call	realloc
	pop	rcx
	test	rax, rax
	jz	@1

	mov	rdx, rax
	mov	al, byte ptr cha

	mov	[rdx + rcx -2], al
	mov	byte ptr [rdx + rcx -1], 0

	mov	rax, len
	mov	[rax], rcx
	mov	rcx, stri
	mov	[rcx], rdx
	clc
	ret

@1:	stc
	ret	
json_str_add_char ENDP

	END
