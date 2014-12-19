	.686p
	.model flat, stdcall
	option casemap: none

	.code

tes PROC t: Ptr BYTE
	LOCAL n: Ptr BYTE

	mov	eax, t
	mov	n, eax
	ret
tes ENDP

	END
