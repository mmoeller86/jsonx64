	; JSON array processing procedures

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_array_add

	.code
json_array_add PROC array: Ptr, len: Ptr, el: Ptr
	mov	rdi, array
	mov	rdi, [rdi]
	mov	rcx, len
	mov	rcx, [rcx]
	inc	rcx
	mov	rsi, rcx
	shl	rsi, 3
	push	rcx
	call	realloc
	pop	rcx
	test	rax, rax
	jz	@1

	mov	rdi, rax
	mov	rax, el
	mov	[rdi + rcx*8 -8], rax

	mov	rax, array
	mov	[rax], rdi
	mov	rax, len
	mov	[rax], rcx
	clc
	ret

@1:	stc
	ret
json_array_add ENDP

	END
