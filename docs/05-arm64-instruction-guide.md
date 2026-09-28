# ARM64 Instruction Guide: Registers, Memory, and Addressing

This note explains the ARM64 instructions observed in the Mach-O disassembly.
It focuses especially on operands written inside square brackets, such as:

```asm
str w8, [sp, #0x10]
ldur w9, [x29, #-0xc]
```

In ARM64 assembly, square brackets describe a memory address calculation. They
do not mean that the register itself is memory. The CPU first calculates an
address from the register and offset, then loads from or stores to that
address.

## Registers versus memory operands

These two instructions have different effects:

```asm
mov w8, #5
str w8, [sp, #0xc]
```

The first instruction changes a register:

```text
W8 = 5
```

The second instruction changes memory:

```text
address = SP + 0xc
memory[address .. address+3] = W8
```

The notation:

```asm
[sp, #0xc]
```

means:

```text
the memory location at address SP + 0xc
```

It does not mean that `SP` contains the value stored at that location.

## ARM64 register names

### `X` and `W` views

ARM64 general-purpose registers are 64 bits wide when written as `X0` through
`X30`. The corresponding `W0` through `W30` names access the lower 32 bits:

```text
X8 = 64-bit view of register 8
W8 = lower 32-bit view of register 8
```

For many instructions that write a `W` register, the upper 32 bits of the
corresponding `X` register become zero:

```asm
mov w8, #5
```

Conceptually:

```text
W8 = 5
X8 = 0x0000000000000005
```

This zero-extension behavior is important when a 32-bit result is later used
as a 64-bit value. The exact operand-size rules should always be checked for
the specific instruction.

### Special-purpose registers

```text
SP   Stack Pointer
X29  conventional Frame Pointer, FP
X30  Link Register, LR
PC   Program Counter
WZR/XZR zero register
```

`WZR` and `XZR` always read as zero. Writes to the zero register are discarded.
For example:

```asm
stur wzr, [x29, #-0x4]
```

stores zero to memory without needing a general-purpose register containing
zero.

## Immediate move: `mov`

Observed form:

```asm
mov w8, #0x5
mov w8, #0xa
mov w8, #0xf
mov w0, #0x0
```

Effect:

```text
W8 = 5
W8 = 10
W8 = 15
W0 = 0
```

`mov` with an immediate writes a constant into a register. It does not access
memory.

The assembly spelling `mov` is an instruction alias in some cases. The
underlying encoding may be an instruction such as `MOVZ` or another
architectural form selected by the assembler.

## Add and subtract: `add` and `sub`

### Register addition

Observed form:

```asm
add w8, w8, w9
```

Effect:

```text
W8 = W8 + W9
```

For the observed program:

```text
W8 = 5
W9 = 10
W8 = 15
```

No memory is accessed by this register-to-register form.

### Add an immediate

Observed forms:

```asm
add x29, sp, #0x20
add sp, sp, #0x30
add x0, x0, #0x4cc
```

Effects:

```text
X29 = SP + 0x20
SP  = SP + 0x30
X0  = X0 + 0x4cc
```

These forms calculate register values. They do not read or write memory.

### Subtract from the stack pointer

Observed form:

```asm
sub sp, sp, #0x30
```

Effect:

```text
SP = SP - 0x30
```

This reserves stack space by moving the stack pointer downward. The
instructions in the observed function reserve 48 bytes:

```text
0x30 hexadecimal = 48 decimal
```

Changing `SP` changes which addresses later stack operands such as `[sp, #16]`
refer to. The `sub` instruction itself does not initialize the newly reserved
bytes.

## Store instructions: `str`, `stur`, and `stp`

Store instructions copy register values into memory. The width of the
register determines how many bytes are written.

```text
W register -> normally 4 bytes
X register -> normally 8 bytes
```

### `str w8, [sp, #0xc]`

Observed form:

```asm
str w8, [sp, #0xc]
```

Effect:

```text
address = SP + 0xc
memory[address .. address+3] = lower 32 bits of W8
```

Because the source register is `W8`, this writes 4 bytes.

If:

```text
SP = 0x1000
W8 = 5
```

then:

```text
address = 0x1000 + 0xc = 0x100c
memory[0x100c .. 0x100f] = 5
```

The example address is only illustrative. Actual process addresses are
runtime-dependent.

### `str w8, [sp, #0x10]`

Observed form:

```asm
str w8, [sp, #0x10]
```

Effect:

```text
memory[SP + 0x10 .. SP + 0x13] = W8
```

In the observed `-O0` program, this is where the calculated `result` was
stored:

```text
result -> memory[SP + 16]
```

### `str x8, [x9]`

Observed form:

```asm
mov x9, sp
str x8, [x9]
```

First:

```text
X9 = SP
```

Then:

```text
memory[X9 .. X9+7] = X8
```

Because `X8` is a 64-bit register, this store writes 8 bytes. The brackets
contain only a base register, so the offset is zero:

```text
[x9] == [x9, #0]
```

### `stur w8, [x29, #-0x8]`

Observed form:

```asm
stur w8, [x29, #-0x8]
```

Effect:

```text
address = X29 - 0x8
memory[address .. address+3] = W8
```

In the observed program:

```text
W8 = 5
memory[X29 - 8] = 5
```

This was the stack location used for `a`.

### `stur wzr, [x29, #-0x4]`

Observed form:

```asm
stur wzr, [x29, #-0x4]
```

Since `WZR` reads as zero:

```text
address = X29 - 4
memory[address .. address+3] = 0
```

This writes four zero bytes.

### `stp x29, x30, [sp, #0x20]`

Observed form:

```asm
stp x29, x30, [sp, #0x20]
```

`stp` means store pair. It writes two registers consecutively:

```text
address = SP + 0x20
memory[address .. address+7]     = X29
memory[address+8 .. address+15]  = X30
```

The instruction saves the old frame pointer and link register in the stack
frame.

For this instruction, the pair occupies 16 bytes in total. The exact stack
layout is compiler-generated, but the calling convention explains why saving
`X29` and `X30` is common in a function prologue.

## Load instructions: `ldr`, `ldur`, and `ldp`

Load instructions copy values from memory into registers.

### `ldr w8, [sp, #0x10]`

Observed form:

```asm
ldr w8, [sp, #0x10]
```

Effect:

```text
address = SP + 0x10
W8 = memory[address .. address+3]
```

This reads 4 bytes. In the observed program it reloads `result` before the
`printf` call.

### `ldur w8, [x29, #-0x8]`

Observed form:

```asm
ldur w8, [x29, #-0x8]
```

Effect:

```text
address = X29 - 0x8
W8 = memory[address .. address+3]
```

This loads the value of `a` from its observed stack location.

### `ldur w9, [x29, #-0xc]`

Observed form:

```asm
ldur w9, [x29, #-0xc]
```

Effect:

```text
address = X29 - 0xc
W9 = memory[address .. address+3]
```

This loads the value of `b`.

### `ldp x29, x30, [sp, #0x20]`

Observed form:

```asm
ldp x29, x30, [sp, #0x20]
```

Effect:

```text
address = SP + 0x20
X29 = memory[address .. address+7]
X30 = memory[address+8 .. address+15]
```

This restores the saved frame pointer and link register in the function
epilogue.

## `ldr` versus `ldur`, and `str` versus `stur`

Both pairs load or store memory, but they use different addressing encodings.

The common unsigned-offset form:

```asm
ldr w8, [sp, #0x10]
str w8, [sp, #0x10]
```

is useful for non-negative offsets with the instruction's scaled addressing
rules.

The unscaled form:

```asm
ldur w8, [x29, #-0x8]
stur w8, [x29, #-0x8]
```

supports a signed byte offset, which is useful for locations below the frame
pointer.

Both forms calculate an address and access memory. The difference is the
encoding and range/alignment rules, not the basic conceptual operation.

## Address formation: `adrp` and `add`

Observed forms:

```asm
adrp x0, 0
add  x0, x0, #0x4cc
```

The pair constructs the address of the string literal:

```text
X0 = address of "Result = %d\n"
```

`adrp` forms a page-based address. A page is normally 4096 bytes on this
platform. `add` then adds the within-page offset.

Conceptually:

```text
page_address = page selected by ADRP
X0 = page_address + 0x4cc
```

The actual relocation-aware encoding is more precise than this simplified
description. The important point is that these instructions calculate an
address in a register; they do not dereference memory.

The later `printf` implementation receives that address as its first argument
according to the ARM64 calling convention.

## Branch with link: `bl`

Observed form:

```asm
bl 0x1000004c0
```

Effect:

```text
X30 = address of the instruction after BL
PC  = branch target
```

`BL` means Branch with Link. It is used for function calls. The target in this
executable is identified as the symbol stub for `_printf`.

`BL` changes control flow and the link register. It does not itself read or
write the function's ordinary data memory.

The called function eventually returns using the link-register mechanism,
usually through:

```asm
ret
```

## Return: `ret`

Observed form:

```asm
ret
```

Conceptually:

```text
PC = X30
```

The exact architectural behavior includes instruction alignment and control
flow details, but the useful mental model is that `RET` returns to the address
held in the link register.

In the function epilogue, `X30` is restored before `ret`:

```asm
ldp x29, x30, [sp, #0x20]
add sp, sp, #0x30
ret
```

## Addressing modes with brackets

The observed instructions use the base-plus-offset form:

```asm
[x29, #-0x8]
[sp, #0x10]
```

The general effect is:

```text
effective_address = base_register + offset
```

The memory access then uses that effective address.

### Base only

```asm
ldr w0, [x1]
```

Means:

```text
address = X1
W0 = memory[address .. address+3]
```

### Positive offset

```asm
str w0, [sp, #0x10]
```

Means:

```text
address = SP + 16
store 4 bytes from W0
```

### Negative offset

```asm
ldur w0, [x29, #-0x8]
```

Means:

```text
address = X29 - 8
load 4 bytes into W0
```

### Pre-indexed addressing

A general ARM64 form is:

```asm
ldr w0, [x1, #8]!
```

Conceptually:

```text
X1 = X1 + 8
W0 = memory[X1 .. X1+3]
```

The exclamation mark means write-back: the base register is updated before
the memory access.

### Post-indexed addressing

Another general form is:

```asm
ldr w0, [x1], #8
```

Conceptually:

```text
W0 = memory[X1 .. X1+3]
X1 = X1 + 8
```

The memory access uses the old base address, and the base register is updated
afterward.

The observed `main` disassembly used ordinary base-plus-offset operands, not
these write-back forms.

## Stack alignment and memory safety

The stack pointer is subject to ABI alignment requirements. The compiler
chooses stack sizes and offsets so that calls such as `bl _printf` satisfy the
platform's calling convention.

An operand such as:

```asm
[sp, #0x10]
```

does not prove that the address is valid by itself. It is valid only because
the surrounding function prologue, stack ownership, ABI rules, and runtime
state establish the relevant stack frame.

Similarly, an address calculation is not the same thing as a physical RAM
address:

```text
ARM64 effective address
        |
        v
process virtual address
        |
        v
virtual-memory translation
        |
        v
physical memory or another backing source
```

The debugger can observe architectural addresses and memory contents, but
this does not directly expose every physical cache or RAM operation.

## Summary table

| Instruction | Main effect | Memory access |
|---|---|---|
| `mov w8, #5` | Write an immediate to `W8` | No |
| `add w8, w8, w9` | Add two registers | No |
| `add x0, x0, #imm` | Add an immediate to a register | No |
| `sub sp, sp, #imm` | Move the stack pointer | No direct access |
| `str w8, [sp, #off]` | Store 4 bytes | Yes, at `SP + off` |
| `str x8, [x9]` | Store 8 bytes | Yes, at `X9` |
| `stur w8, [x29, #-off]` | Store 4 bytes | Yes, at `X29 - off` |
| `stp x29, x30, [sp, #off]` | Store two registers | Yes, 16 bytes total |
| `ldr w8, [sp, #off]` | Load 4 bytes | Yes, at `SP + off` |
| `ldur w8, [x29, #-off]` | Load 4 bytes | Yes, at `X29 - off` |
| `ldp x29, x30, [sp, #off]` | Load two registers | Yes, 16 bytes total |
| `adrp x0, label` | Form a page-based address | No dereference |
| `bl target` | Call and save return address | No ordinary data access |
| `ret` | Return through `X30` | No ordinary data access |

## Important distinction

The expression:

```asm
[x29, #-0x8]
```

means an effective memory address:

```text
X29 - 8
```

The instruction determines what happens at that address:

```asm
ldr  w8, [x29, #-0x8]   // read 4 bytes
str  w8, [x29, #-0x8]   // write 4 bytes
ldur w8, [x29, #-0x8]   // read using unscaled signed offset
stur w8, [x29, #-0x8]   // write using unscaled signed offset
```

The brackets describe *where* the operation occurs. The instruction mnemonic
and register width describe *what* is read or written.
