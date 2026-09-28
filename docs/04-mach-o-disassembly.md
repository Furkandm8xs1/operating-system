# Disassembling the Mach-O `__TEXT,__text` Section

This note records the next laboratory step: reading the actual ARM64
instructions stored in the Mach-O executable and comparing them with the
earlier textual assembly output.

## Commands used

The executable was disassembled with:

```bash
otool -tvV main
```

The embedded string section was inspected with:

```bash
otool -s __TEXT __cstring main
```

The executable was built from the same source with:

```bash
clang -g -O0 -arch arm64 main.c -o main
```

## The actual `__TEXT,__text` disassembly

The executable contains this instruction sequence:

```text
0000000100000460  sub  sp, sp, #0x30
0000000100000464  stp  x29, x30, [sp, #0x20]
0000000100000468  add  x29, sp, #0x20
000000010000046c  mov  w8, #0x0
0000000100000470  str  w8, [sp, #0xc]
0000000100000474  stur wzr, [x29, #-0x4]
0000000100000478  mov  w8, #0x5
000000010000047c  stur w8, [x29, #-0x8]
0000000100000480  mov  w8, #0xa
0000000100000484  stur w8, [x29, #-0xc]
0000000100000488  ldur w8, [x29, #-0x8]
000000010000048c  ldur w9, [x29, #-0xc]
0000000100000490  add  w8, w8, w9
0000000100000494  str  w8, [sp, #0x10]
0000000100000498  ldr  w8, [sp, #0x10]
000000010000049c  mov  x9, sp
00000001000004a0  str  x8, [x9]
00000001000004a4  adrp x0, 0
00000001000004a8  add  x0, x0, #0x4cc
00000001000004ac  bl   0x1000004c0
00000001000004b0  ldr  w0, [sp, #0xc]
00000001000004b4  ldp  x29, x30, [sp, #0x20]
00000001000004b8  add  sp, sp, #0x30
00000001000004bc  ret
```

The first address, `0x100000460`, matches the `__TEXT,__text` address reported
by `otool -l`. Each normal ARM64 instruction advances the address by four
bytes. This is because A64 instructions have a fixed width of 32 bits.

## Comparing assembly source with the executable

The earlier `main-O0.s` contained:

```asm
sub     sp, sp, #48
stp     x29, x30, [sp, #32]
add     x29, sp, #32
```

The executable shows the same instructions using hexadecimal immediates:

```text
sub sp, sp, #0x30       // 0x30 = 48
stp x29, x30, [sp, #0x20] // 0x20 = 32
add x29, sp, #0x20
```

This demonstrates that assembly syntax can show an immediate as decimal or
hexadecimal without changing the instruction's meaning.

The source assembly:

```asm
mov     w8, #5
stur    w8, [x29, #-8]
mov     w8, #10
stur    w8, [x29, #-12]
```

appears in the executable as:

```text
mov  w8, #0x5
stur w8, [x29, #-0x8]
mov  w8, #0xa
stur w8, [x29, #-0xc]
```

The `-O0` source-to-instruction relationship is therefore visible in the
actual executable, not only in the intermediate `.s` file.

## Instruction-by-instruction data flow

### Stack-frame setup

```text
0x100000460  sub sp, sp, #0x30
0x100000464  stp x29, x30, [sp, #0x20]
0x100000468  add x29, sp, #0x20
```

The function reserves 48 bytes, saves the old frame pointer and link register,
and establishes the frame pointer.

### Local values

```text
0x100000478  mov  w8, #0x5
0x10000047c  stur w8, [x29, #-0x8]

0x100000480  mov  w8, #0xa
0x100000484  stur w8, [x29, #-0xc]
```

For this exact build:

```text
a = 5  -> memory[X29 - 8]
b = 10 -> memory[X29 - 12]
```

### Addition

```text
0x100000488  ldur w8, [x29, #-0x8]
0x10000048c  ldur w9, [x29, #-0xc]
0x100000490  add  w8, w8, w9
0x100000494  str  w8, [sp, #0x10]
```

The runtime data flow is:

```text
W8 = 5
W9 = 10
W8 = W8 + W9
memory[SP + 16] = 15
```

### Preparing and calling `printf`

```text
0x100000498  ldr  w8, [sp, #0x10]
0x10000049c  mov  x9, sp
0x1000004a0  str  x8, [x9]
0x1000004a4  adrp x0, 0
0x1000004a8  add  x0, x0, #0x4cc
0x1000004ac  bl   0x1000004c0
```

The `adrp` and `add` pair constructs the address of the format string in
`X0`. The `bl` instruction branches to the symbol stub for `_printf`.

The disassembler identifies the target as:

```text
symbol stub for: _printf
```

This is important: the small executable does not contain the full
implementation of `printf`. The call goes through dynamic-linking machinery
that ultimately connects the program to the system library.

### Function return

```text
0x1000004b0  ldr  w0, [sp, #0xc]
0x1000004b4  ldp  x29, x30, [sp, #0x20]
0x1000004b8  add  sp, sp, #0x30
0x1000004bc  ret
```

The return value is loaded into `W0`, the saved frame state is restored, the
stack frame is released, and control returns through the restored link
register.

## Instruction bytes are not assembly text

Using `xcrun llvm-objdump`, the same instructions can be shown with their
four-byte ARM64 encodings:

```text
ff c3 00 d1    sub sp, sp, #0x30
fd 7b 02 a9    stp x29, x30, [sp, #0x20]
fd 83 00 91    add x29, sp, #0x20
08 00 80 52    mov w8, #0x0
e8 0f 00 b9    str w8, [sp, #0xc]
bf c3 1f b8    stur wzr, [x29, #-0x4]
a8 00 80 52    mov w8, #0x5
a8 83 1f b8    stur w8, [x29, #-0x8]
48 01 80 52    mov w8, #0xa
a8 43 1f b8    stur w8, [x29, #-0xc]
48 01 09 0b    add w8, w8, w9
c0 03 5f d6    ret
```

The exact byte listing contains every instruction, including the load and
store operations. The important distinction is:

```text
assembly source       add w8, w8, w9
machine-code bytes    08 01 09 0b
```

The bytes are what the CPU instruction-fetch machinery reads. The mnemonic is
a disassembler's human-readable interpretation of those bytes.

## The string literal in `__TEXT,__cstring`

The command:

```bash
otool -s __TEXT __cstring main
```

reported:

```text
00000001000004cc  75736552 3d20746c 0a642520 00
```

The bytes decode as the ASCII string:

```text
Result = %d\n\0
```

The address `0x1000004cc` matches the address formed by:

```text
adrp x0, ...
add  x0, x0, #0x4cc
```

The code and string are therefore separate objects in the Mach-O image:

```text
__TEXT,__text    ARM64 instructions
__TEXT,__cstring read-only string data
```

## What `otool` is showing us

The `otool -tvV` output is a disassembly of the file's machine-code bytes.
It shows:

- the section name;
- symbol labels such as `_main`;
- virtual addresses;
- decoded ARM64 instruction mnemonics;
- external-call targets such as the `_printf` stub.

It does not show the CPU's internal micro-operations, pipeline stages,
speculation, cache hits, or physical transistor activity. It shows the
architectural instruction stream represented in the executable.

## Current mental model

The observed chain is now:

```text
C source
   |
   v
Clang compiler
   |
   v
main-O0.s
   |
   v
ARM64 instruction encoding
   |
   v
Mach-O __TEXT,__text
   |
   v
otool disassembly
   |
   v
human-readable ARM64 instructions
```

The next step is to launch this executable under LLDB, stop at `main`, and
observe the architectural registers and stack while executing these exact
instructions one at a time.
