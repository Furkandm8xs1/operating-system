	.build_version macos, 27, 0	sdk_version 27, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_vec_add                        ; -- Begin function vec_add
	.p2align	2
_vec_add:                               ; @vec_add
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48
	.cfi_def_cfa_offset 48
	str	s0, [sp, #24]
	str	s1, [sp, #28]
	str	s2, [sp, #32]
	str	s3, [sp, #12]
	str	s4, [sp, #16]
	str	s5, [sp, #20]
	ldr	s0, [sp, #24]
	ldr	s1, [sp, #12]
	fadd	s0, s0, s1
	str	s0, [sp, #36]
	ldr	s0, [sp, #28]
	ldr	s1, [sp, #16]
	fadd	s0, s0, s1
	str	s0, [sp, #40]
	ldr	s0, [sp, #32]
	ldr	s1, [sp, #20]
	fadd	s0, s0, s1
	str	s0, [sp, #44]
	ldr	s0, [sp, #36]
	ldr	s1, [sp, #40]
	ldr	s2, [sp, #44]
	add	sp, sp, #48
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_move                           ; -- Begin function move
	.p2align	2
_move:                                  ; @move
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	s0, [x29, #-12]
	stur	s1, [x29, #-8]
	stur	s2, [x29, #-4]
	str	x0, [sp, #24]
	ldr	x8, [sp, #24]
	str	x8, [sp]                        ; 8-byte Folded Spill
	ldr	x8, [sp, #24]
	ldr	s0, [x8, #12]
	ldr	s1, [x8, #16]
	ldr	s2, [x8, #20]
	ldur	s3, [x29, #-12]
	ldur	s4, [x29, #-8]
	ldur	s5, [x29, #-4]
	bl	_vec_add
	ldr	x9, [sp]                        ; 8-byte Folded Reload
	str	s0, [sp, #12]
	str	s1, [sp, #16]
	str	s2, [sp, #20]
	ldur	x8, [sp, #12]
	stur	x8, [x9, #12]
	ldr	w8, [sp, #20]
	str	w8, [x9, #20]
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_set_aim                        ; -- Begin function set_aim
	.p2align	2
_set_aim:                               ; @set_aim
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
	str	x0, [sp, #8]
	str	s0, [sp, #4]
	str	s1, [sp]
	ldr	s0, [sp, #4]
	ldr	x8, [sp, #8]
	str	s0, [x8, #24]
	ldr	s0, [sp]
	ldr	x8, [sp, #8]
	str	s0, [x8, #28]
	add	sp, sp, #16
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_shoot                          ; -- Begin function shoot
	.p2align	2
_shoot:                                 ; @shoot
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #32
	.cfi_def_cfa_offset 32
	str	x0, [sp, #16]
	str	x1, [sp, #8]
	ldr	x8, [sp, #16]
	ldr	w8, [x8, #44]
	subs	w8, w8, #0
	b.gt	LBB3_2
	b	LBB3_1
LBB3_1:
	str	wzr, [sp, #28]
	b	LBB3_5
LBB3_2:
	ldr	x9, [sp, #16]
	ldr	w8, [x9, #44]
	subs	w8, w8, #1
	str	w8, [x9, #44]
	ldr	x8, [sp, #16]
	ldr	w10, [x8, #40]
	ldr	x9, [sp, #8]
	ldr	w8, [x9, #8]
	subs	w8, w8, w10
	str	w8, [x9, #8]
	ldr	x8, [sp, #8]
	ldr	w8, [x8, #8]
	tbz	w8, #31, LBB3_4
	b	LBB3_3
LBB3_3:
	ldr	x8, [sp, #8]
	str	wzr, [x8, #8]
	b	LBB3_4
LBB3_4:
	mov	w8, #1                          ; =0x1
	str	w8, [sp, #28]
	b	LBB3_5
LBB3_5:
	ldr	w0, [sp, #28]
	add	sp, sp, #32
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #208
	stp	x29, x30, [sp, #192]            ; 16-byte Folded Spill
	add	x29, sp, #192
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	w8, #0                          ; =0x0
	str	w8, [sp, #68]                   ; 4-byte Folded Spill
	stur	wzr, [x29, #-4]
	sub	x0, x29, #56
	str	x0, [sp, #48]                   ; 8-byte Folded Spill
	mov	x2, #48                         ; =0x30
	str	x2, [sp, #40]                   ; 8-byte Folded Spill
	adrp	x1, l___const.main.a@PAGE
	add	x1, x1, l___const.main.a@PAGEOFF
	bl	_memcpy
	ldr	x2, [sp, #40]                   ; 8-byte Folded Reload
	add	x0, sp, #88
	str	x0, [sp, #56]                   ; 8-byte Folded Spill
	adrp	x1, l___const.main.b@PAGE
	add	x1, x1, l___const.main.b@PAGEOFF
	bl	_memcpy
	ldr	x0, [sp, #48]                   ; 8-byte Folded Reload
	adrp	x8, l___const.main.step@PAGE
	add	x8, x8, l___const.main.step@PAGEOFF
	ldr	d0, [x8]
	str	d0, [sp, #72]
	ldr	s0, [x8, #8]
	str	s0, [sp, #80]
	ldr	s0, [sp, #72]
	ldr	s1, [sp, #76]
	ldr	s2, [sp, #80]
	bl	_move
	ldr	x0, [sp, #48]                   ; 8-byte Folded Reload
	mov	w8, #1119092736                 ; =0x42b40000
	fmov	s0, w8
	movi.2d	v1, #0000000000000000
	bl	_set_aim
	ldr	x0, [sp, #48]                   ; 8-byte Folded Reload
	ldr	x1, [sp, #56]                   ; 8-byte Folded Reload
	bl	_shoot
	ldur	x10, [x29, #-56]
	ldur	s0, [x29, #-44]
	fcvt	d2, s0
	ldur	s0, [x29, #-40]
	fcvt	d1, s0
	ldur	s0, [x29, #-36]
	fcvt	d0, s0
	ldur	w8, [x29, #-12]
                                        ; kill: def $x8 killed $w8
	mov	x9, sp
	str	x10, [x9]
	str	d2, [x9, #8]
	str	d1, [x9, #16]
	str	d0, [x9, #24]
	str	x8, [x9, #32]
	adrp	x0, l_.str.4@PAGE
	add	x0, x0, l_.str.4@PAGEOFF
	bl	_printf
	ldr	x10, [sp, #88]
	ldr	w8, [sp, #96]
                                        ; kill: def $x8 killed $w8
	mov	x9, sp
	str	x10, [x9]
	str	x8, [x9, #8]
	adrp	x0, l_.str.5@PAGE
	add	x0, x0, l_.str.5@PAGEOFF
	bl	_printf
	ldr	w0, [sp, #68]                   ; 4-byte Folded Reload
	ldp	x29, x30, [sp, #192]            ; 16-byte Folded Reload
	add	sp, sp, #208
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"T"

l_.str.1:                               ; @.str.1
	.asciz	"AK47"

	.section	__DATA,__const
	.p2align	3, 0x0                          ; @__const.main.a
l___const.main.a:
	.quad	l_.str
	.long	100                             ; 0x64
	.space	12
	.space	8
	.quad	l_.str.1
	.long	30                              ; 0x1e
	.long	30                              ; 0x1e

	.section	__TEXT,__cstring,cstring_literals
l_.str.2:                               ; @.str.2
	.asciz	"CT"

l_.str.3:                               ; @.str.3
	.asciz	"M4A1"

	.section	__DATA,__const
	.p2align	3, 0x0                          ; @__const.main.b
l___const.main.b:
	.quad	l_.str.2
	.long	100                             ; 0x64
	.long	0x41200000                      ; float 10
	.long	0x00000000                      ; float 0
	.long	0x40a00000                      ; float 5
	.space	8
	.quad	l_.str.3
	.long	25                              ; 0x19
	.long	30                              ; 0x1e

	.section	__TEXT,__const
	.p2align	2, 0x0                          ; @__const.main.step
l___const.main.step:
	.long	0x3f800000                      ; float 1
	.long	0x00000000                      ; float 0
	.long	0x00000000                      ; float 0

	.section	__TEXT,__cstring,cstring_literals
l_.str.4:                               ; @.str.4
	.asciz	"%s pos=(%.1f,%.1f,%.1f) ammo=%d\n"

l_.str.5:                               ; @.str.5
	.asciz	"%s health=%d\n"

.subsections_via_symbols
