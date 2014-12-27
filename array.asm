	; JSON array processing procedures

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_array_add

	.code
json_array_add PROC array: Ptr, len: Ptr, el: Ptr
	mov	arg0, array
	mov	arg0, [arg0]
	mov	rcx, len
	mov	rcx, [rcx]
	inc	rcx
	mov	arg1, rcx
	shl	arg1, 3
	push	rcx
	call	realloc
	pop	rcx
	test	rax, rax
	jz	@1

	mov	rdx, rax
	mov	rax, el
	mov	[rdx + rcx*8 -8], rax

	mov	rax, array
	mov	[rax], rdx
	mov	rax, len
	mov	[rax], rcx
	clc
	ret

@1:	stc
	ret
json_array_add ENDP

	END
