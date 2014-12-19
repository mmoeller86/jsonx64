
	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_buffer_init_mem
	public json_buffer_init_file
	public json_buffer_read_char
	public json_buffer_peek_char
	public json_buffer_skip_char

	puts PROTO
	read PROTO
	close PROTO

	.code

json_buffer_init_mem PROC
	push	rdi
	push	rsi
	mov	rdi, 1
	mov	rsi, sizeof JSONBuffer
	call	calloc
	pop	rsi
	pop	rdi

	test rax, rax
	jz @1

	mov	[rax + JSONBuffer.typ], TYPE_MEM
	mov	[rax + JSONBuffer.mem], rdi
	mov	[rax + JSONBuffer.msize], rsi
	mov	[rax + JSONBuffer.last_char], -1
@1:	ret
json_buffer_init_mem ENDP

json_buffer_init_file PROC
	push	rdi
	mov	rdi, 1
	mov	rsi, sizeof JSONBuffer
	call	calloc
	pop	rdi
	
	test rax, rax
	jz @1

	mov	[rax + JSONBuffer.typ], TYPE_FILE
	mov	[rax + JSONBuffer.file], rdi
	mov	[rax + JSONBuffer.last_char], -1
@1:	ret
json_buffer_init_file ENDP

json_buffer_init_fd PROC
	push	rdi
	mov	rdi, 1
	mov	rsi, sizeof JSONBuffer
	call	calloc
	pop	rdi
	
	test rax, rax
	jz @1

	mov	[rax + JSONBuffer.typ], TYPE_FD
	mov	[rax + JSONBuffer.fd], edi
	mov	[rax + JSONBuffer.last_char], -1
@1:	ret
json_buffer_init_fd ENDP

json_buffer_free PROC
	push	rdi
	.if [rdi + JSONBuffer.typ] == TYPE_MEM
		mov	rdi, [rdi + JSONBuffer.mem]
		call	free
	.elseif [rdi + JSONBuffer.typ] == TYPE_FILE
		mov	rdi, [rdi + JSONBuffer.file]
		call fclose
	.else
		mov	edi, [rdi + JSONBuffer.fd]
		call	close
	.endif
	pop	rdi

	call	free
	ret
json_buffer_free ENDP

	.data
msg_read_char	db 'read-char', 0
msg_peek_char	db 'peek-char', 0

	.code
json_buffer_read_char PROC p: Ptr JSONBuffer
	LOCAL cha: BYTE

	mov	rdi, offset msg_read_char
	call	puts

	mov	rax, p
	cmp	[rax + JSONBuffer.last_char], -1
	je	@3

	mov	rdi, [rax + JSONBuffer.last_char]
	mov	[rax + JSONBuffer.last_char], -1
	mov	rax, rdi
	jmp	@4

@3:
	.if [rax + JSONBuffer.typ] == TYPE_MEM
		mov rdi, [rax + JSONBuffer.msize]
		.if rdi == [rax + JSONBuffer.mpos]
			mov rax, -1
		@1:	stc
			ret
		.endif

		mov	rdi, [rax + JSONBuffer.mem]
		add	rdi, [rax + JSONBuffer.mpos]
		inc	[rax + JSONBuffer.mpos]
		movsx	rax, byte ptr [rdi]
	.elseif [rax + JSONBuffer.typ] == TYPE_FILE
		mov	rdi, [rax + JSONBuffer.file]
		call	fgetc
		cmp eax, -1
		je @1
	.else
		mov	edi, [rax + JSONBuffer.fd]
		lea	rsi, cha
		mov	rdx, 1
		call	read
		cmp	eax, 0
		jl	@1

		movsx	rax, cha
	.endif

@2:	mov	rdi, p
	mov	[rdi + JSONBuffer.last_char], -1
@4:	clc
	ret
json_buffer_read_char ENDP

json_buffer_peek_char PROC p: Ptr JSONBuffer
	LOCAL cha: BYTE

	mov	rdi, offset msg_peek_char
	call	puts

	mov	rax, p
	cmp	[rax + JSONBuffer.last_char], -1
	je	@2

	mov	rax, [rax +JSONBuffer.last_char]
	jmp	@4

@2:
	.if [rax + JSONBuffer.typ] == TYPE_MEM
		mov rdi, [rax + JSONBuffer.msize]
		.if rdi == [rax + JSONBuffer.mpos]
			mov rax, -1
		@1:	stc
			ret
		.endif

		mov	rdi, [rax + JSONBuffer.mem]
		add	rdi, [rax + JSONBuffer.mpos]
		inc	[rax + JSONBuffer.mpos]
		movsx	rax, byte ptr [rdi]
	.elseif [rax + JSONBuffer.typ] == TYPE_FILE
		mov	rdi, [rax + JSONBuffer.file]
		call	fgetc
		cmp eax, -1
		je @1
	.else
		mov	edi, [rax + JSONBuffer.fd]
		lea	rsi, cha
		mov	rdx, 1
		call	read

		movsx	rax, cha
	.endif

@3:	mov	rdi, p
	mov	[rdi + JSONBuffer.last_char], 0
	mov	byte ptr [rdi + JSONBuffer.last_char], al
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
		mov	rdi, [rax + JSONBuffer.file]
		mov	rsi, 1
		mov	edx, SEEK_CUR
		call fseek
	.else
		mov	edi, [rax + JSONBuffer.fd]
		lea	rsi, cha
		mov	rdx, 1
		call	read
	.endif

	mov	rdi, p
	mov	[rdi + JSONBuffer.last_char], -1
@2:	clc
	ret
json_buffer_skip_char ENDP

	END
