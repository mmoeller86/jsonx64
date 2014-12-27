	; JSON parser for the x64 architecture

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_init
	public json_fini
	public json_parse
	public json_parser_free

	json_parse_node_val PROTO node: Ptr JSONNode, buffer: Ptr JSONBuffer
	json_parse_node PROTO buffer: Ptr JSONBuffer
	.code

json_init PROC
	invoke	calloc, 1, sizeof JSONParser
	ret
json_init ENDP

json_fini PROC p: Ptr JSONParser
	mov	arg0, p
	call	free
	ret
json_fini ENDP

json_trim PROC buffer: Ptr JSONBuffer
@2:
	invoke	json_buffer_peek_char, buffer
	cmp	al, ' '
	jz	@1
	cmp	al, 9
	jz	@1
	cmp	al, 13
	jz	@1
	cmp	al, 10
	jz	@1

	ret

@1:	invoke	json_buffer_skip_char, buffer
	jmp	@2
json_trim ENDP

json_trim2 PROC buffer: Ptr JSONBuffer
@2:
	invoke	json_buffer_peek_char, buffer
	cmp	al, ' '
	je	@1
	cmp	al, 9
	je	@1
	ret

@1:	invoke	json_buffer_skip_char, buffer
	jmp	@2
json_trim2 ENDP

json_parse_string PROC buffer: Ptr JSONBuffer
	LOCAL buf: Ptr BYTE
	LOCAL len: QWORD
	LOCAL hex [5]: BYTE

	invoke	json_buffer_skip_char, buffer

	invoke	json_str_alloc
	mov	buf, rax
	mov	len, 1
@1:	invoke	json_buffer_read_char, buffer

	cmp	al, '"'
	je	@2

	cmp	al, '\'
	jne	@4

	; Read a unicode sequence
	invoke	json_buffer_read_char, buffer
	cmp	al, 'u'
	jne	@5

	invoke	json_buffer_read_char, buffer
	jc	@3
	mov	hex [0], al
	invoke	json_buffer_read_char, buffer
	jc	@3
	mov	hex [1], al
	invoke	json_buffer_read_char, buffer
	jc	@3
	mov	hex [2], al
	invoke	json_buffer_read_char, buffer
	jc	@3
	mov	hex [3], al
	mov	hex [4], 0

	lea	arg0, hex
	mov	arg1, 0
	mov	arg2d, 16
	call	strtoul

	cmp	eax, 256
	jl	@4

	push	rax
	invoke	json_str_add_char, addr buf, addr len, rax
	pop	rax
	shr	ax, 8
	invoke	json_str_add_char, addr buf, addr len, rax
	jmp	@1

@5:	cmp	al, 'r'
	je	@6
	cmp	al, 'n'
	je	@7
	cmp	al, 'f'
	je	@8
	cmp	al, 't'
	je	@9
	cmp	al, 'b'
	je	@10
	cmp	al, '"'
	je	@11
	cmp	al, '\'
	je	@12
	cmp	al, '/'
	je	@13
	jmp	@3

@6:	invoke	json_str_add_char, addr buf, addr len, 13
	jmp	@1

@7:	invoke	json_str_add_char, addr buf, addr len, 10
	jmp	@1

@8:	invoke	json_str_add_char, addr buf, addr len, 12
	jmp	@1

@9:	invoke	json_str_add_char, addr buf, addr len, 9
	jmp	@1

@10:	invoke	json_str_add_char, addr buf, addr len, 8
	jmp	@1

@11:	invoke	json_str_add_char, addr buf, addr len, 34
	jmp	@1

@12:	invoke	json_str_add_char, addr buf, addr len, 92
	jmp	@1

@13:	invoke	json_str_add_char, addr buf, addr len, 47
	jmp	@1

@4:	invoke	json_str_add_char, addr buf, addr len, rax
	jc	@3
	jmp	@1

@2:	mov	rax, buf
	clc
	ret

@3:	stc
	ret
json_parse_string ENDP

json_parse_str PROC node: Ptr JSONNode, buffer: Ptr JSONBuffer
	invoke json_parse_string, buffer
	jc	@1

	mov	rdx, node
	mov	[rdx + JSONNode.d_str], rax
	mov	[rdx + JSONNode.typ], NODE_TYPE_STRING
	clc
@1:	ret
json_parse_str ENDP

	.data
b_true	db 'true', 0
b_false	db 'false', 0 

	.code
json_parse_boolean PROC node: Ptr JSONNode, stri: Ptr BYTE
	mov	arg0, stri
	mov	arg1, offset b_true
	call	strcasecmp
	.if eax == 0
		mov	rdx, node
		mov	[rdx + JSONNode.d_bool], 1
		mov	[rdx + JSONNode.typ], NODE_TYPE_BOOLEAN
		jmp	@2
	.endif

	mov	arg0, stri
	mov	arg1, offset b_false
	call	strcasecmp
	.if eax == 0
		mov	rdx, node
		mov	[rdx + JSONNode.d_bool], 0
		mov	[rdx + JSONNode.typ], NODE_TYPE_BOOLEAN
		jmp	@2
	.endif

@1:	stc
	ret

@2:	mov	arg0, stri
	call	free
	clc
	ret
json_parse_boolean ENDP

json_parse_num PROC node: Ptr JSONNode, stri: Ptr BYTE
	LOCAL ende: QWORD

	mov	arg0, stri
	lea	arg1, ende
	call	strtod

	mov	rax, stri
	.if rax == ende
		stc
		ret
	.endif

	mov	r8, node
	movq	[r8 + JSONNode.d_num], xmm0
	mov	[r8 + JSONNode.typ], NODE_TYPE_NUMBER
	clc
	ret
json_parse_num ENDP

json_parse_object PROC node: Ptr JSONNode, buffer: Ptr JSONBuffer
	LOCAL	array: Ptr
	LOCAL	n: QWORD
	LOCAL	nod: Ptr

	invoke	json_buffer_skip_char, buffer

	mov	array, 0
	mov	n, 0
@1:	invoke	json_trim, buffer
	invoke	json_buffer_peek_char, buffer
	cmp	al, '}'
	je	@3

	invoke	json_parse_node, buffer
	jc	@4

	mov	nod, rax

	invoke	json_array_add, addr array, addr n, nod
	invoke	json_trim2, buffer
	invoke	json_buffer_read_char, buffer
	cmp	al, ','
	jne	@3
	jmp	@1

@2:	mov	rax, node
	mov	rdx, array
	mov	[rax + JSONNode.a], rdx
	mov	rdx, n
	mov	[rax + JSONNode.n], rdx
	mov	[rax + JSONNode.typ], NODE_TYPE_OBJECT
	clc
	ret

@3:	invoke	json_trim, buffer
	invoke	json_buffer_read_char, buffer
	cmp	al, '}'
	jne	@4
	jmp	@2

@4:	stc
	ret
json_parse_object ENDP

json_parse_array PROC node: Ptr JSONNode, buffer: Ptr JSONBuffer
	LOCAL	array: Ptr
	LOCAL	n: QWORD
	LOCAL	nod: Ptr

	invoke	json_buffer_skip_char, buffer

	mov	array, 0
	mov	n, 0
@1:	invoke	json_trim, buffer
	invoke	json_buffer_peek_char, buffer
	cmp	al, ']'
	je	@3

	invoke	json_node_alloc
	mov	nod, rax
	invoke	json_parse_node_val, nod, buffer
	jc	@3

	mov	nod, rax

	invoke	json_array_add, addr array, addr n, nod
	invoke	json_trim2, buffer
	invoke	json_buffer_read_char, buffer
	cmp	al, ','
	jne	@3
	jmp	@1

@2:	mov	rax, node
	mov	rdx, array
	mov	[rax + JSONNode.a], rdx
	mov	rdx, n
	mov	[rax + JSONNode.n], rdx
	mov	[rax + JSONNode.typ], NODE_TYPE_ARRAY
	clc
	ret

@3:	invoke	json_trim, buffer
	invoke	json_buffer_read_char, buffer
	cmp	al, ']'
	jne	@4
	jmp	@2

@4:	stc
	ret
json_parse_array ENDP

json_parse_node PROC buffer: Ptr JSONBuffer
	LOCAL nam: Ptr BYTE
	LOCAL node: Ptr JSONNode

	invoke	json_parse_string, buffer
	jc	@1

	mov	nam, rax

	invoke	json_trim2, buffer
	invoke	json_buffer_peek_char, buffer
	cmp	al, ':'
	jnz	@1

	invoke	json_buffer_skip_char, buffer

	invoke	json_node_alloc
	mov	node, rax
	invoke	json_node_set_name, node, nam
	
	invoke	json_parse_node_val, node, buffer
	jc	@1
	
	mov	rax, node
	clc
	ret

@1:	sub	rax, rax
	stc
	ret
json_parse_node ENDP

json_get_str PROC buffer: Ptr JSONBuffer
	LOCAL buf: Ptr BYTE
	LOCAL len: QWORD

	mov	buf, 0
	mov	len, 1
@1:
	invoke	json_buffer_peek_char, buffer
	cmp	al, ' '
	je	@2
	cmp	al, 9
	je	@2
	cmp	al, ','
	je	@2
	cmp	al, 13
	je	@2
	cmp	al, 10
	je	@2

	push	rax
	inc	len
	mov	arg0, buf
	mov	arg1, len
	call	realloc

	mov	buf, rax
	pop	rax
	mov	rdx, buf
	mov	r8, len
	mov	[rdx + r8 -2], al
	mov	byte ptr [rdx + r8 -1], 0

	invoke	json_buffer_skip_char, buffer
	jmp	@1

@2:	mov	rax, buf
	clc
	ret
json_get_str ENDP

	.data
d_null		db 'null', 0

	.code
json_parse_null PROC node: Ptr JSONNode, stri: Ptr BYTE
	mov	arg0, stri
	mov	arg1, offset d_null
	call	strcasecmp
	test	eax, eax
	jnz	@1

	mov	rax, node
	mov	[rax + JSONNode.typ], NODE_TYPE_NULL

	mov	arg0, stri
	call	free
	clc
	ret

@1:	stc
	ret
json_parse_null ENDP

json_parse_node_val PROC node: Ptr JSONNode, buffer: Ptr JSONBuffer
	LOCAL stri: Ptr BYTE

	invoke	json_trim, buffer
	invoke	json_buffer_peek_char, buffer
	cmp	al, '{'		; Object
	je	@1
	cmp	al, '['		; Array
	je	@2
	cmp	al, '"'		; Name/Value Pair
	je	@3

	; Number or Boolean
@5:	invoke	json_get_str, buffer
	mov	stri, rax

	invoke	json_parse_boolean, node, stri
	jnc	@7

	invoke	json_parse_num, node, stri
	jnc	@7

	invoke	json_parse_null, node, stri
	jnc	@7
	jmp	@4

@1:	invoke	json_parse_object, node, buffer
	jc	@4
	jmp	@7

@2:	invoke	json_parse_array, node, buffer
	jc	@4
	jmp	@7

@3:	invoke	json_parse_str, node, buffer
	jc	@4
	jmp	@7

@4:	sub	rax, rax
@6:	ret

@7:
	mov	rax, node
	ret
json_parse_node_val ENDP

json_parse PROC
	LOCAL	buffer: Ptr

	mov	buffer, arg0
	invoke	json_node_alloc
	test	rax, rax
	jz	@1

	invoke	json_parse_node_val, rax, buffer
@1:	ret
json_parse ENDP

json_parser_free PROC
	invoke	json_node_free, arg0
	ret
json_parser_free ENDP

	END
