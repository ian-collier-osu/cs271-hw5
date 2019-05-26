TITLE List Sorting    (Project05.asm)

; Author: Ian Collier
; CS 271 / Project 05                Date: 2/24/2019
; Description: Generates a list of random numbers then sorts it

INCLUDE Irvine32.inc

RAND_UPPER_LIMIT = 999
RAND_LOWER_LIMIT = 100
INPUT_UPPER_LIMIT = 200
INPUT_LOWER_LIMIT = 10
INVALID_INPUT = -1

.data

; Strings
intro1		BYTE	"Random Integer Sorting by Ian Collier",0
intro2		BYTE	"What this program does:",0
intro3		BYTE	"(1) Generates a list (of user set size) of random integers between 100 - 999.\n(2) Sorts the list in descending order.\n (3) Finds the median value.",0

getdata1	BYTE	"How big should the list be [10-200]: ",0
getdataerr1	BYTE	"Out of range.",0

spacer		BYTE	"  ",0

title1		BYTE	"The unsorted list: ",0
title2		BYTE	"The sorted list: ",0
title3		BYTE	"The median value: ",0


; Main vars
arrN		DWORD	?		; N array size from user input
arrList		DWORD	INPUT_UPPER_LIMIT	DUP(?)
tempVar		DWORD	?


.code
main PROC

	; Set random seed
	call	Randomize

	; Intro
	call	printIntro

	; Get the array size
	push	OFFSET arrN
	call	getUserData

	; Fill the array
	push	OFFSET arrList
	push	arrN
	call	fillArray

	; Print unsorted
	push	OFFSET arrList
	push	arrN
	push	OFFSET title1
	call	printArray

	; Sort
	push	OFFSET arrList
	push	arrN
	call	selectionSortArray

	; Print sorted
	push	OFFSET arrList
	push	arrN
	push	OFFSET title2
	call	printArray

	; Print median
	push	OFFSET arrList
	push	arrN
	call	printArrayMedian

	exit	; exit to operating system
main ENDP


; Prints some messages
printIntro PROC
	pushad

	; Print title of program
	mov		edx,OFFSET intro1
	call	WriteString
	call	Crlf
	call	Crlf
	; Print instructions
	mov		edx,OFFSET intro2
	call	WriteString
	call	Crlf
	mov		edx,OFFSET intro3
	call	WriteString
	call	Crlf
	call	Crlf

	popad
	ret
printIntro ENDP


; Gets user input for array size bounded by const limits
; Params: &n (Where to put input)
getUserData PROC
	push	ebp
	mov		ebp, esp		; Setup stack frame

	mov		ebx, [ebp+8]	; Get address of n into ebx

	; Loop until break
	getUserDataLoop:
		; Input prompt
		mov		edx,OFFSET getdata1
		call	WriteString
		; Get user input
		call	ReadInt
		mov		[ebx], eax		; Store input in n
		; Validate using subproc
		push	ebx				; Pass &n as param
		call	validateUserData

		; If not invalid break
		mov		eax, [ebx]
		cmp		eax, INVALID_INPUT
		jne		getUserDataDone

		; Else loop
		jmp		getUserDataLoop

	getUserDataDone:
	pop		ebp
	ret		4
getUserData ENDP

; Checks if input is valid (between upper and lower limit)
; Params: &n (Where to put input)
; Returns: n = INVALID_INPUT if invalid, otherwise doesn't change value
validateUserData PROC
	push	ebp
	mov		ebp, esp		; Setup stack frame

	mov		ebx, [ebp+8]	; Get address of n into ebx

	; If below lower limit error
	mov		eax, [ebx]
	cmp		eax, INPUT_LOWER_LIMIT
	jl		validateUserDataErr

	; Or if above upper limit error
	mov		eax, [ebx]
	cmp		eax, INPUT_UPPER_LIMIT
	jg		validateUserDataErr

	; In range, no error
	jmp		validateUserDataDone

	; Error label
	validateUserDataErr:
		mov		eax, INVALID_INPUT
		mov		[ebx], eax
		mov		edx,OFFSET getdataerr1	; Prompt
		call	WriteString
		call	Crlf

		
	validateUserDataDone:
	pop		ebp
	ret		4
validateUserData ENDP


; Fills array with random numbers
; Params:  &arr (Array), n (Array size)
; Preconditions: 
fillArray PROC
	push	ebp
	mov		ebp, esp		; Setup stack frame

	mov		ecx, [ebp+8]	; Get value of n into loop counter
	mov		esi, [ebp+12]	; Get address of array into esi

	; Set random range
	mov		edx, RAND_UPPER_LIMIT
	sub		edx, RAND_LOWER_LIMIT
	add		edx, 1


	fillArrayLoop:
		mov		eax, edx				; Get random number in (0, edx)
		call	RandomRange
		add		eax, RAND_LOWER_LIMIT	; Adjust to get the number in range

		mov		[esi], eax				; Store in array
		add		esi, 4
		loop	fillArrayLoop

	pop		ebp
	ret		8
fillArray ENDP

; Params: &arr (Array), n (Array len)
selectionSortArray PROC
	push	ebp
	mov		ebp, esp		; Setup stack frame

	; N = [ebp+8]
	; Array = [ebp+12]

	mov		esi, [ebp+12]

	mov		ebx, 0			; Outer loop index
	mov		ecx, 0
	selectionSortArrayLoop1:

		mov		ecx, ebx
		mov		edx, ebx		; Inner loop index = ebx + 1
		inc		edx
		selectionSortArrayLoop2:
			push	edx
			; If arr[edx] >= arr[ebx] skip
			mov		eax, 4
			mul		edx
			mov		edi, [esi+eax]	; edi = arr[edx]

			mov		eax, 4
			mul		ebx
			mov		eax, [esi+eax]	; eax = arr[ebx]

			cmp		edi, eax
			pop		edx
			jge		selectionSortArrayLoop2Skip

			; Else
			mov		ecx, edx

			selectionSortArrayLoop2Skip:
			inc		edx
			mov		eax, [ebp+8]
			cmp		edx, eax
			jl		selectionSortArrayLoop2 ; Loop while edx < N

		; Swap arr[ebx], arr[ecx]

		mov		eax, 4
		mul		ebx
		mov		eax, [esi+eax]
		push	eax					; arr[ebx] value on stack

		mov		eax, 4
		mul		ecx
		mov		eax, [esi+eax]		
		push	eax					; arr[ecx] value on stack

		mov		eax, 4
		mul		ebx
		add		eax, esi
		pop		[eax]				; pop arr[ecx] value into arr[ebx]

		mov		eax, 4
		mul		ecx
		add		eax, esi			; pop arr[ebx] value into arr[ecx]
		pop		[eax]


		inc		ebx
		mov		eax, [ebp+8]
		dec		eax
		cmp		ebx, eax
		jl		selectionSortArrayLoop1 ; Loop while ebx < N - 1
		
	pop		ebp
	ret		8
selectionSortArray ENDP



; Prints an array
; Params: &arr (Array), n (Array size), &title (String title)
printArray PROC
	push	ebp
	mov		ebp, esp		; Setup stack frame

	mov		edx, [ebp+8]	; Print title
	call	WriteString
	call	Crlf

	mov		ecx, [ebp+12]	; Get value of n into loop counter
	mov		esi, [ebp+16]	; Get address of array into esi

	printArrayLoop:
		mov		eax, [esi]
		call	WriteDec
		mov		edx, OFFSET spacer
		call	WriteString
		add		esi, 4
		loop	printArrayLoop

	call	Crlf

	pop		ebp
	ret		12
printArray ENDP

; Finds and prints the median value of an array
; Params: &arr (Array), n (Array size)
; Preconditions: Expects a sorted array
printArrayMedian PROC
	push	ebp
	mov		ebp, esp		; Setup stack frame

	mov		eax, [ebp+8]	; Get value of n into eax
	mov		esi, [ebp+12]	; Get address of array into esi

	; Print title
	mov		edx, OFFSET title3
	call	WriteString
	call	Crlf

	; eax /= 2 - Find index of n / 2
	mov		ebx, 2
	xor		edx, edx
	div		ebx

	; esi += (eax * 4) - Set esi to index
	mov		ebx, 4
	mul		ebx
	add		esi, eax

	; Print median
	mov		eax, [esi]
	call	WriteDec

	call	Crlf

	pop		ebp
	ret		8
printArrayMedian ENDP

END main
