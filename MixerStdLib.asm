section .text

global _start

jmp _start

;--------------------------------------------------------------
FuncIn:       jmp In

FuncOut       jmp Out

FuncHlt       jmp Hlt
;--------------------------------------------------------------



;---------------------------------------------------------------------------
;Entry: number in stdin
;Exit:  double number on top of stack
;Destr: rax, r8, rbx, rsi, r9, rdi, rdx, xmm0, xmm1
;---------------------------------------------------------------------------
In:

	xor rax, rax ; reading number as string
	xor rdi, rdi
	mov rdx, 64

	mov rsi, rsp
	sub rsi, 64

	syscall

	call StringToDouble

	pop r8

	sub rsp, 8
	movsd qword [rsp], xmm0

	push r8

	ret


;---------------------------------------------------------------------------
;Entry: rax - string's lenght
;       rsi - number pointer
;Exit:  double number in xmm0
;Destr: rax, r8, rbx, rsi, r9, rdi, rdx, xmm0, xmm1
;---------------------------------------------------------------------------

StringToDouble:

	mov rdi, rax ;len
	mov rcx, rax ;counter 

	xor rax, rax ;mantice
	xor r9, r9   ;integer len
	xor rbx, rbx ;exponent
	xor rdx, rdx ;current digit

	xor r8, r8   ;IsMinus


	ConvertNext:

		mov dl, byte [rsi]

		cmp dl, '-'
		je HandleMinus

		cmp dl, '.'
		je HandleDot

		sub dl, '0'  ;HandleDigit
		imul rax, 10
		add rax, rdx

		inc r9

	ConvertLoop:

		inc rsi

		loop ConvertNext
		jmp ConvertDone

	HandleMinus:

		mov r8, 1
		jmp ConvertLoop

	HandleDot:

		mov rbx, rdi
		sub rbx, r9

		dec rbx

		cmp r8, 1
		jne ConvertLoop

		dec rbx
		jmp ConvertLoop

	ConvertDone:

		cmp r8, 1
		jne NoMinus
		not rax
		inc rax

	NoMinus:

		mov rcx, rbx
		mov rbx, 1

		cmp rcx, 0
		je ZeroExponent

		mov rbx, 1

		PowLoop:

			imul rbx, 10
			loop PowLoop

	ZeroExponent:

		cvtsi2sd xmm0, rax
		cvtsi2sd xmm1, rbx

		divsd xmm0, xmm1

		ret


;---------------------------------------------------------------------------
;Entry: number on top of stack (but before the return address)
;Exit:  number in stdout
;Destr: rax, r8, rbx, rsi, r9, rdi, rdx, st0, st1
;---------------------------------------------------------------------------
Out:

	xor rax, rax
	xor r9, r9

	pop r8 ;return address

	mov rsi, rsp
	sub rsi, 32

	finit

	fstcw word [rsi]
	mov ax, word [rsi]
	or eax, 110000000000B ; setting rounding control to truncate
	mov word [rsi], ax
	fldcw word [rsi]

	fld qword [rsp]
	fist dword [rsi]
	mov eax, dword [rsi]

	mov    ebx, eax       ; check for minus
    and    ebx, 0x80000000
    cmp    ebx, 0

    mov r9, rax

    je IntSkipHandleMinus

    mov byte [rsi], '-'
    call PrintChar

    mov rax, r9

    not eax
    inc eax

	IntSkipHandleMinus:

	call PrintInt

	finit

	mov rax, r9
	mov dword [rsi], eax
	fld qword [rsp]
	fild dword [rsi]
	fsub
	fstp dword [rsi]

	finit
	fld dword[rsi]

	mov dword [rsi], 100000 ;precision
	fild dword [rsi]
	fmul
	fistp dword [rsi]
	mov eax, dword [rsi]

	mov    ebx, eax       ; check for minus
    and    ebx, 0x80000000
    cmp    ebx, 0

    je DecSkipHandleMinus

    not eax
    inc eax

	DecSkipHandleMinus:

	cmp eax, 0
	je SkipDecHandle

	mov r9, rax
	mov byte [rsi], '.'
	call PrintChar
	mov rax, r9

	call PrintInt

	SkipDecHandle:

	push r8

	ret


;---------------------------------------------------------------------------
;Entry: number in eax
;Exit:  number in stdout
;Destr: rsi, r14, rcx
;---------------------------------------------------------------------------
PrintInt:
	
	mov rsi, rsp
	sub rsi, 64
	xor rcx, rcx

	mov r14, 10

	WritingLoop:

		xor rdx, rdx

		div r14

		add dl, '0'
		mov [rsi], dl

		inc rsi
		inc rcx

		cmp eax, 0
		jne WritingLoop
		dec rsi

	PrintLoop:

		call PrintChar
		dec rsi
		loop PrintLoop

	ret


PrintChar:

	push rcx

    mov rax, 1
    mov rdx, 1
    mov rdi, 1

    syscall

    mov byte [rsi], 0

	pop rcx

    ret 


Hlt:

	mov             rax, 3Ch
    xor             rdi, rdi
    syscall	


_start:
	 
	call FuncIn
	call FuncOut
	call FuncHlt

