	; JSONNode procedures

	.model flat, stdcall
	option casemap: none

	include json.inc

	public json_node_alloc
	public json_node_free

	.code
json_node_alloc PROC
	mov	rdi, 1
	mov	rsi, sizeof JSONNode
	call	calloc
	ret
json_node_alloc ENDP

json_node_free PROC node: Ptr JSONNode
	LOCAL array: Ptr Ptr JSONNode

	ret
	mov rax, node
	mov array, 0
	.if [rax + JSONNode.d_str] != 0
		mov	rdi, [rax + JSONNode.d_str]
		call	free
	.elseif [rax + JSONNode.a] != 0
		mov rax, [rax + JSONNode.a]
		mov array, rax
	.endif

	.if array != 0
		mov rax, node
		mov rcx, [rax + JSONNode.n]
		mov rax, array
@1:
		push	rax
		push	rcx
		invoke json_node_free, [rax]
		pop	rcx
		pop	rax

		add rax, 8
		loop @1
	.endif

	mov	rdi, node
	call	free
	ret
json_node_free ENDP

json_node_set_name PROC node: Ptr JSONNode, nam: Ptr BYTE
	mov rax, node
	mov rdi, nam
	mov [rax + JSONNode.nam], rdi
	ret
json_node_set_name ENDP

	END
