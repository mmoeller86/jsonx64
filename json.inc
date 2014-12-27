	include system.inc

	JSONParser STRUC
	JSONParser ENDS


TYPE_MEM	equ	0
TYPE_FILE	equ	1
TYPE_FD		equ	2
	JSONBuffer STRUC
		typ	dd ?
		mem	dq ?
		msize	dq ?
		mpos	dq ?
		last_char dq ?

		file	dq ?
		fd	dd ?
	JSONBuffer ENDS

NODE_TYPE_NUMBER		equ	0
NODE_TYPE_STRING		equ	1
NODE_TYPE_BOOLEAN		equ	2
NODE_TYPE_OBJECT		equ	3
NODE_TYPE_ARRAY			equ	4
NODE_TYPE_NULL			equ	5

	JSONNode STRUC
		typ	dd	?
		d_num	dq	?
		d_str	dq	?
		d_bool dd	?

		nam	dq ?
		
		n	dq	?
		a	dq	?
	JSONNode ENDS

	calloc PROTO n: QWORD, m: QWORD
	free PROTO p: Ptr
	realloc PROTO p: Ptr, siz: QWORD
	fgetc PROTO fd: Ptr
	fseek PROTO fd: Ptr, pos: QWORD, whence: QWORD
	fclose PROTO fd: Ptr
	strcasecmp PROTO s0: Ptr BYTE, s1 : Ptr BYTE
	strtod PROTO stri: Ptr BYTE, ende: Ptr Ptr BYTE
	strtoul PROTO stri: Ptr BYTE, ende: Ptr Ptr BYTE

SEEK_SET	equ 0
SEEK_CUR	equ 1
SEEK_END	equ 2

	; Buffer Procedures
	json_buffer_init_mem PROTO
	json_buffer_init_fd PROTO
	json_buffer_read_char PROTO buffer: Ptr JSONBuffer
	json_buffer_peek_char PROTO buffer: Ptr JSONBuffer
	json_buffer_skip_char PROTO buffer: Ptr JSONBuffer
	json_buffer_write_char PROTO buffer: Ptr JSONBuffer, cha: QWORD
	json_buffer_write_str PROTO buffer: Ptr JSONBuffer, stri: Ptr BYTE
	json_buffer_write_tab PROTO buffer: Ptr JSONBuffer, n: QWORD

	; Node Procedures
	json_node_alloc PROTO
	json_node_free PROTO node: Ptr JSONNode
	json_node_set_name PROTO node: Ptr JSONNode, nam: Ptr BYTE

	; String Procedures
	json_str_alloc PROTO
	json_str_add_char PROTO stri: Ptr, len: Ptr, cha: QWORD

	; Array Procedures
	json_array_add PROTO array: Ptr, len: Ptr, el: Ptr
