
	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_buffer_init_mem
	public json_buffer_init_file
	public json_buffer_init_fd
	public json_buffer_read_char
	public json_buffer_peek_char
	public json_buffer_skip_char

	read PROTO
	close PROTO
	fputc PROTO
	write PROTO

	.code

json_buffer_init_mem PROC
	push	arg0
	push	arg1
	mov	arg0, 1
	mov	arg1, sizeof JSONBuffer
	call	calloc
	pop	arg1
	pop	arg0

	test rax, rax
	jz @1

	mov	[rax + JSONBuffer.typ], TYPE_MEM
	mov	[rax + JSONBuffer.mem], arg0
	mov	[rax + JSONBuffer.msize], arg1
	mov	[rax + JSONBuffer.last_char], -1
@1:	ret
json_buffer_init_mem ENDP

json_buffer_init_file PROC
	push	arg0
	mov	arg0, 1
	mov	arg1, sizeof JSONBuffer
	call	calloc
	pop	arg0
	
	test rax, rax
	jz @1

	mov	[rax + JSONBuffer.typ], TYPE_FILE
	mov	[rax + JSONBuffer.file], arg0
	mov	[rax + JSONBuffer.last_char], -1
@1:	ret
json_buffer_init_file ENDP

json_buffer_init_fd PROC
	push	arg0
	mov	arg0, 1
	mov	arg1, sizeof JSONBuffer
	call	calloc
	pop	arg0
	
	test rax, rax
	jz @1

	mov	[rax + JSONBuffer.typ], TYPE_FD
	mov	[rax + JSONBuffer.fd], arg0d
	mov	[rax + JSONBuffer.last_char], -1
@1:	ret
json_buffer_init_fd ENDP

json_buffer_free PROC
	push	arg0
	.if [arg0 + JSONBuffer.typ] == TYPE_MEM
		mov	arg0, [arg0 + JSONBuffer.mem]
		call	free
	.elseif [arg0 + JSONBuffer.typ] == TYPE_FILE
		mov	arg0, [arg0 + JSONBuffer.file]
		call fclose
	.else
		mov	arg0d, [arg0 + JSONBuffer.fd]
		call	close
	.endif

	pop	arg0
	call	free
	ret
json_buffer_free ENDP

json_buffer_read_char PROC p: Ptr JSONBuffer
	LOCAL cha: BYTE

	mov	rax, p
	cmp	[rax + JSONBuffer.last_char], -1
	je	@3

	mov	rdx, [rax + JSONBuffer.last_char]
	mov	[rax + JSONBuffer.last_char], -1
	mov	rax, rdx
	jmp	@4

@3:
	.if [rax + JSONBuffer.typ] == TYPE_MEM
		mov rdx, [rax + JSONBuffer.msize]
		.if rdx == [rax + JSONBuffer.mpos]
			mov rax, -1
		@1:	stc
			ret
		.endif

		mov	rdx, [rax + JSONBuffer.mem]
		add	rdx, [rax + JSONBuffer.mpos]
		inc	[rax + JSONBuffer.mpos]
		movsx	rax, byte ptr [rdx]
	.elseif [rax + JSONBuffer.typ] == TYPE_FILE
		mov	arg0, [rax + JSONBuffer.file]
		call	fgetc
		cmp eax, -1
		je @1
	.else
		mov	arg0d, [rax + JSONBuffer.fd]
		lea	arg1, cha
		mov	arg2, 1
		call	read
		cmp	eax, 0
		jl	@1

		movsx	rax, cha
	.endif

@2:	mov	rdx, p
	mov	[rdx + JSONBuffer.last_char], -1
@4:	clc
	ret
json_buffer_read_char ENDP

json_buffer_peek_char PROC p: Ptr JSONBuffer
	LOCAL cha: BYTE

	mov	rax, p
	cmp	[rax + JSONBuffer.last_char], -1
	je	@2

	mov	rax, [rax +JSONBuffer.last_char]
	jmp	@4

@2:
	.if [rax + JSONBuffer.typ] == TYPE_MEM
		mov rdx, [rax + JSONBuffer.msize]
		.if rdx == [rax + JSONBuffer.mpos]
			mov rax, -1
		@1:	stc
			ret
		.endif

		mov	rdx, [rax + JSONBuffer.mem]
		add	rdx, [rax + JSONBuffer.mpos]
		inc	[rax + JSONBuffer.mpos]
		movsx	rax, byte ptr [rdx]
	.elseif [rax + JSONBuffer.typ] == TYPE_FILE
		mov	arg0, [rax + JSONBuffer.file]
		call	fgetc
		cmp eax, -1
		je @1
	.else
		mov	arg0d, [rax + JSONBuffer.fd]
		lea	arg1, cha
		mov	arg2, 1
		call	read

		movsx	rax, cha
	.endif

@3:	mov	rdx, p
	mov	[rdx + JSONBuffer.last_char], 0
	mov	byte ptr [rdx + JSONBuffer.last_char], al
@4:	clc
	ret
json_buffer_peek_char ENDP

json_buffer_skip_char PROC p: Ptr JSONBuffer
	LOCAL cha: BYTE

	mov	rax, p
	cmp	[rax + JSONBuffer.last_char], -1
	je	@1

	mov	[rax + JSONBuffer.last_char], -1
	jmp	@2

@1:
	.if [rax + JSONBuffer.typ] == TYPE_MEM
		inc	[rax + JSONBuffer.mpos]
	.elseif [rax + JSONBuffer.typ] == TYPE_FILE
		mov	arg0, [rax + JSONBuffer.file]
		mov	arg1, 1
		mov	arg2d, SEEK_CUR
		call fseek
	.else
		mov	arg0d, [rax + JSONBuffer.fd]
		lea	arg1, cha
		mov	arg2, 1
		call	read
	.endif

	mov	rdx, p
	mov	[rdx + JSONBuffer.last_char], -1
@2:	clc
	ret
json_buffer_skip_char ENDP

json_buffer_write_char PROC buffer: Ptr JSONBuffer, cha: QWORD
	mov	rax, buffer
	.if [rax + JSONBuffer.typ] == TYPE_MEM
		mov	arg0, [rax + JSONBuffer.mem]
		inc	[rax + JSONBuffer.msize]
		mov	arg1, [rax + JSONBuffer.msize]
		call	realloc
		test	rax, rax
		jz	@1

		mov	rdx, rax
		mov	rax, buffer
		mov	rcx, [rax + JSONBuffer.msize]
		mov	al, byte ptr [cha]
		mov	[rdx + rcx -2], al
		mov	byte ptr [rdx + rcx -1], 0

		mov	rax, buffer
		mov	[rax + JSONBuffer.mem], rdx
		jmp	@2
	.elseif [rax + JSONBuffer.typ] == TYPE_FILE
		mov	arg0d, dword ptr [cha]
		mov	arg1, [rax + JSONBuffer.file]
		call	fputc
		cmp	eax, -1
		je	@1
		jmp	@2
	.else
		mov	arg0d, [rax + JSONBuffer.fd]
		lea	arg1, cha
		mov	arg2, 1
		call	write
		cmp	eax, 1
		jl	@1
		jmp	@2
	.endif

@1:	stc
	ret

@2:	clc
	ret
json_buffer_write_char ENDP

json_buffer_write_tab PROC buffer: Ptr JSONBuffer, n: QWORD
@1:	cmp	n, 0
	je	@2

	invoke	json_buffer_write_char, buffer, 9
	dec	n
	jmp	@1

@2:	ret
json_buffer_write_tab ENDP

	END
