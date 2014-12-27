	; JSON write procedures

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_write

	sprintf PROTO
	puts PROTO
	json_write_node_val PROTO buffer: Ptr JSONBuffer, node: Ptr JSONNode, ident: QWORD

	.data
d_null	db 'null', 0
str_fmt	db '%.05f', 0
d_true	db 'true', 0
d_false db 'false', 0
d_openb	db '{', 10, 0
d_closeb db '}', 10, 0
d_openbr db '[', 10, 0
d_closebr db ']', 10, 0
str_dp db ' : ', 0
ccrlf	db ',', 10, 0
crlf	db 10, 0

	.code
json_buffer_write_str PROC buffer: Ptr JSONBuffer, stri: Ptr BYTE
	mov	rax, stri
@1:	mov	cl, [rax]
	test	cl, cl
	jz	@2

	push	rax
	invoke	json_buffer_write_char, buffer, rcx
	pop	rax

	inc	rax
	jmp	@1

@2:	ret
json_buffer_write_str ENDP

json_write_node PROC buffer: Ptr JSONBuffer, node: Ptr JSONNode, ident: QWORD
	invoke	json_buffer_write_tab, buffer, ident
	invoke	json_buffer_write_char, buffer, '"'

	mov	rax, node
	invoke	json_buffer_write_str, buffer, [rax + JSONNode.nam]
	invoke	json_buffer_write_char, buffer, '"'
	lea	rax, str_dp
	invoke	json_buffer_write_str, buffer, rax
	invoke	json_write_node_val, buffer, node, ident
	ret
json_write_node ENDP

json_write_node_val PROC buffer: Ptr JSONBuffer, node: Ptr JSONNode, ident: QWORD
	LOCAL buf [20]: BYTE

	mov	rax, node
	.if [rax + JSONNode.typ] == NODE_TYPE_NULL
		invoke	json_buffer_write_tab, buffer, ident
		lea	rax, d_null
		invoke json_buffer_write_str, buffer, rax
	.elseif [rax + JSONNode.typ] == NODE_TYPE_STRING
		invoke	json_buffer_write_tab, buffer, ident
		invoke json_buffer_write_char, buffer, '"'
		mov rax, node
		invoke json_buffer_write_str, buffer, [rax + JSONNode.d_str]
		invoke json_buffer_write_char, buffer, '"'
	.elseif [rax + JSONNode.typ] == NODE_TYPE_NUMBER
		lea arg0, buf
		lea arg1, str_fmt
		movq xmm0, [rax + JSONNode.d_num]
		call sprintf

		invoke json_buffer_write_tab, buffer, ident
		invoke json_buffer_write_str, buffer, addr buf
	.elseif [rax + JSONNode.typ] == NODE_TYPE_BOOLEAN
		invoke	json_buffer_write_tab, buffer, ident
		mov	rax, node
		cmp [rax + JSONNode.d_bool], 0
		je @1

		lea rdx, d_true
		jmp @2

@1:		lea rdx, d_false
@2:		invoke json_buffer_write_str, buffer, rdx
	.elseif [rax + JSONNode.typ] == NODE_TYPE_OBJECT
		invoke	json_buffer_write_tab, buffer, ident
		lea	rax, d_openb
		invoke json_buffer_write_str, buffer, rax

		mov	rax, node
		mov r8, [rax + JSONNode.a]
		mov rcx, [rax + JSONNode.n]
		inc ident
@3:		push	r8
		push	rcx
		invoke json_write_node, buffer, [r8], ident
		pop	rcx

		cmp	rcx, 1
		jg	@5
		lea	rdx, crlf
		jmp	@6
@5:		lea	rdx, ccrlf
@6:		push	rcx
		invoke	json_buffer_write_str, buffer, rdx
		pop	rcx
		pop	r8

		add	r8, 8
		loop	@3

		dec	ident
		invoke json_buffer_write_tab, buffer, ident
		lea	rax, d_closeb
		invoke json_buffer_write_str, buffer, rax
	.else ; NODE_TYPE_ARRAY
		invoke	json_buffer_write_tab, buffer, ident
		lea	rax, d_openbr
		invoke json_buffer_write_str, buffer, rax

		mov	rax, node
		mov	rdx, [rax + JSONNode.a]
		mov	rcx, [rax + JSONNode.n]
		inc	ident
@4:		push	rdx
		push	rcx
		invoke	json_write_node_val, buffer, [rdx], ident
		pop	rcx

		cmp	rcx, 1
		jg	@7
		lea	rdx, crlf
		jmp	@8
@7:		lea	rdx, ccrlf
@8:		push	rcx
		invoke	json_buffer_write_str, buffer, rdx
		pop	rcx
		pop	rdx

		add	rdx, 8
		loop	@4

		dec	ident
		invoke json_buffer_write_tab, buffer, ident
		lea	rax, d_closebr
		invoke json_buffer_write_str, buffer, rax
	.endif

	clc
	ret
json_write_node_val ENDP

json_write PROC
	invoke json_write_node_val, arg0, arg1, 0
	ret
json_write ENDP

	END
