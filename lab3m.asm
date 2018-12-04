SAVE_STATE MACRO
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
ENDM

LOAD_STATE MACRO
	POP	DX
	POP	CX
	POP	BX
	POP	AX
ENDM

PUTCHAR	MACRO CHAR
	MOV	AL, CHAR
	INT	29H
ENDM

PUTSTR MACRO STR
	MOV	AH, 09H
	LEA	DX, STR
	INT	21H
ENDM

PUTENDL MACRO
	PUTCHAR	0DH
	PUTCHAR	0AH
ENDM

GETCHAR MACRO
	MOV	AH, 08H
	INT	21H
ENDM

GETSTR MACRO BUFF
	LEA	DX, BUFF
	MOV	AH, 0AH
	INT	21H
	PUTENDL
ENDM

SYS_SOLVE MACRO	X
	SAVE_STATE
	XOR	AX, AX
	MOV	AX, X
	MOV 	BL, IS_NEG
	CMP 	BL, 1
	JNE	CHECK_1
	JMP	THIRD_COND
CHECK_1:
	CMP	AX, 0
	JNE	CHECK_2
	JMP	THIRD_COND
CHECK_2:
	CMP	AX, 5
	JG	FIRST_COND
	JMP	SECOND_COND
FIRST_COND:
	MUL 	AX
	JNO	FIRST_CONTINUE_1
	JMP	SOLVE_ERR
FIRST_CONTINUE_1:
	XOR	BX, BX
	MOV	BL, 35
	MUL	BX
	JNO	FIRST_CONTINUE_2
	JMP	SOLVE_ERR
FIRST_CONTINUE_2:
	SUB	AX, 15
	CMP	DX, 0
	JNE	DX_WRITE
	JMP	SOLVE_CONTINUE
DX_WRITE:
	MOV	NUM, DX
	ITOA
SOLVE_CONTINUE:
	MOV	NUM, AX
	ITOA
	JMP	SOLVE_END
SECOND_COND:
	XOR	BX, BX
	MOV	BX, X
	XOR	AX, AX
	MOV	AX, 10
	XOR	DX, DX
	DIV	BX
	MOV	NUM, AX
	MOV	REST, DX
	FP_OUT
	JMP	SOLVE_END
THIRD_COND:
	MOV	DX, AX
	MOV	AX, 215
	SUB	AX, DX
	JO	SOLVE_ERR
	MOV	NUM, AX
	ITOA
	JMP	SOLVE_END
SOLVE_ERR:
	PUTSTR	ERR_OF_MSG
SOLVE_END:
	LOAD_STATE
ENDM

ITOA MACRO
	LOCAL	MAIN_LOOP, POS, END_LOOP
	SAVE_STATE
	MOV 	BX, NUM
	OR	BX, BX
	JNS	POS
	PUTCHAR '-'
	NEG	BX
POS:
	MOV	AX, BX
	XOR	CX, CX
	MOV	BX, 10
MAIN_LOOP:
	XOR	DX, DX
	DIV	BX
	ADD	DL, '0'
	PUSH	DX
	INC	CX
	TEST	AX, AX
	JNZ 	MAIN_LOOP
END_LOOP:
	POP 	AX
	INT 	29H
	LOOP 	END_LOOP
	LOAD_STATE
ENDM

FP_OUT MACRO
	LOCAL	MAIN_LOOP, FP_END
	SAVE_STATE
	ITOA
	CMP	REST, 0
	JE	FP_END
	PUTCHAR	2EH
	MOV	CL, ACC
	MOV	TMP, BX
	MOV	AX, REST
	XOR 	BX, BX
	MOV	BX, 10
MAIN_LOOP:
	XOR 	DX, DX
	MUL	BX
	DIV	TMP
	MOV	NUM, AX
	MOV	AX, DX
	ITOA
	LOOP	MAIN_LOOP
FP_END:
	LOAD_STATE
ENDM

STSEG SEGMENT PARA STACK "STACK"
	DB 64 DUP ("STACK")
STSEG ENDS

DSEG SEGMENT PARA PUBLIC "DATA"
	INPUT_MSG 	DB "Enter number:$"
	ERR_INV_MSG 	DB "Number is invalid.$"
	ERR_OF_MSG 	DB "Number is too big.$"
	BUFF 		DB 7, ?, 7 DUP ('?')
	NUM 		DW 0
	REST 		DW 0
	TMP 		DW 0
	ACC 		DB 5
	IS_NEG 		DB 0H
	IS_ERR 		DB 0H
DSEG ENDS

CSEG SEGMENT PARA PUBLIC "CODE"
	ASSUME CS: CSEG, DS: DSEG, SS: STSEG

	ATOI PROC NEAR
		SAVE_STATE
		LEA 	DI, BUFF + 2
		MOV 	CL, [DI]
		CMP 	CL, '-'
		JE 	ATOI_NEG
		CMP 	CL, '+'
		JE 	ATOI_POS
		
		ATOI_INIT:
		XOR 	BX, BX
		MOV	BX, 10
		XOR	AX, AX

	ATOI_LOOP:
		XOR 	CX, CX
		MOV	CL, [DI]
		CMP	CL, 0DH
		JE 	ATOI_END
		CMP	CL, 30H
		JB	ATOI_ERR_INV
		CMP	CL, 39H
		JA	ATOI_ERR_INV
		SUB	CL, 30H
		MUL	BX
		JC	ATOI_ERR_OF
		ADD	AX, CX
		JC 	ATOI_ERR_OF
		INC	DI
		JMP	ATOI_LOOP

	ATOI_NEG:
		PUSH 	AX
		MOV	AL, 1
		MOV	IS_NEG, AL
		POP	AX
		INC 	DI
		JMP	ATOI_INIT

	ATOI_POS:
		PUSH 	AX
		MOV	AL, 0
		MOV	IS_NEG, AL
		POP	AX
		INC	DI
		JMP	ATOI_INIT

	ATOI_ERR_INV:
		MOV	AL, 1
		MOV	IS_ERR, AL
		PUTSTR 	ERR_INV_MSG
		PUTENDL
		JMP	ATOI_QUIT

	ATOI_ERR_OF:
		MOV	AL, 1
		MOV	IS_ERR, AL
		PUTSTR 	ERR_OF_MSG
		PUTENDL
		JMP	ATOI_QUIT

	ATOI_END:
		CMP	AX, 32768
		JA	ATOI_ERR_OF
		MOV	CL, IS_NEG
		CMP	CL, 1
		JNZ	ATOI_QUIT
		NEG	AX

	ATOI_QUIT:
		MOV	NUM, AX
		LOAD_STATE
		RET	
	ATOI ENDP

	MAIN PROC FAR
		PUSH	DS
		XOR 	AX, AX
		PUSH 	AX
		MOV 	AX, DSEG
		MOV	DS, AX

		PUTSTR 	INPUT_MSG
		PUTENDL
		
		GETSTR 	BUFF

		CALL 	ATOI
		CMP	IS_ERR, 1
		JNE	MAIN_CONTINUE
		JMP	MAIN_END
	MAIN_CONTINUE:
		SYS_SOLVE	NUM
		
	MAIN_END:
		GETCHAR
		RET
	MAIN ENDP
CSEG ENDS

END MAIN