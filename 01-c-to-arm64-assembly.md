# C to ARM64 Assembly: First Laboratory Step

This note records the first experiment in the native macOS Apple Silicon
laboratory. The goal is to observe how a small C program is translated into
ARM64 assembly without treating compiler output as universal or fixed.

## Environment

The experiment was run on an Apple Silicon Mac:

```text
uname -m
arm64
```

The compiler was Apple Clang:

```text
Apple clang version 21.0.0
```

The source file is [main.c](./main.c):

```c
#include <stdio.h>

int main(void)
{
    int a = 5;
    int b = 10;
    int result = a + b;

    printf("Result = %d\n", result);

    return 0;
}
```

## What `clang` does

`clang` is the compiler driver used in this experiment. It coordinates the
stages that transform C source code into a target artifact:

```text
main.c
  |
  v
preprocessing
  |
  v
compilation to ARM64 assembly
  |
  v
assembly into machine-code object data
  |
  v
linking with libraries
  |
  v
Mach-O executable
```

The command used here stops before the last two stages:

```bash
clang -S -O0 -g -arch arm64 main.c -o main.s
```

`clang` reads `main.c`, processes the `stdio.h` include, translates the C
program for the ARM64 target, and writes textual assembly to `main.s`.

## What the `clang` options mean

```text
-S       generate assembly and stop
-O0      disable optimization
-g       include source-level debug information
-arch    select the target architecture
-o       select the output file
```

The command used for the first experiment was:

```bash
clang -S -O0 -g -arch arm64 main.c -o main.s
```

- `-S` tells Clang not to assemble or link an executable. The result is a
  human-readable `.s` file.
- `-O0` asks the compiler to avoid optimization. This usually preserves a
  more visible relationship between source variables and generated code.
- `-g` adds DWARF debug directives. These are why the output contains entries
  such as `.loc` and a large `__DWARF` section.
- `-arch arm64` selects the Apple Silicon ARM64 target.
- `-o main.s` names the output file.

`-O0` does not mean that the compiler performs absolutely no transformation.
The compiler still has to generate valid code and may still use ordinary
calling-convention and code-generation decisions.

## What `sed` does in this experiment

The following commands were used to display only the text-section portion of
each assembly file:

```bash
sed -n '/__TEXT,__text/,/__TEXT,__cstring/p' main-O0.s
sed -n '/__TEXT,__text/,/__TEXT,__cstring/p' main-O2.s
```

`sed` is a stream editor. In this form:

- `-n` suppresses normal automatic printing.
- `/__TEXT,__text/` finds the starting line.
- `/__TEXT,__cstring/` finds the ending line.
- `p` prints the selected range.

This command does not compile, optimize, or modify the assembly. It only
filters what is printed in the terminal. The files remain unchanged.

The selected range includes the generated `main` function and stops at the
boundary before the C string-literal section. It is a viewing convenience,
not a separate compilation stage.

## Compile C to ARM64 assembly

The output can contain both executable instruction mnemonics and assembler or
debug-information directives. For example:

```asm
.section        __TEXT,__text,regular,pure_instructions
.globl  _main
_main:
```

The `__TEXT,__text` section is where the function's machine instructions will
eventually be placed in the Mach-O executable. The leading underscore in
`_main` is a macOS symbol naming convention: the C function is named `main`,
while the emitted symbol is `_main`.

## Function prologue and stack frame

The observed function prologue was:

```asm
sub     sp, sp, #48
stp     x29, x30, [sp, #32]
add     x29, sp, #32
```

### `sub sp, sp, #48`

This decreases the stack pointer:

```text
SP = SP - 48
```

The function reserves 48 bytes of stack space. The exact size and layout are
compiler decisions and should not be treated as a permanent ABI layout for
every compilation.

### `stp x29, x30, [sp, #32]`

`stp` means store pair. It stores two 64-bit registers in memory:

```text
memory[SP + 32] = X29
memory[SP + 40] = X30
```

- `X29` is conventionally used as the frame pointer (`FP`).
- `X30` is the link register (`LR`), which holds a return address.

### `add x29, sp, #32`

This establishes the frame pointer:

```text
X29 = SP + 32
```

For this specific `-O0` compilation, a simplified view of the observed stack
locations is:

```text
SP + 40   saved X30 / LR
SP + 32   saved X29 / FP
SP + 16   result
SP + 12   temporary area used for main's return value
X29 - 4   compiler-generated temporary area
X29 - 8   a
X29 - 12  b
```

These offsets are observations from this compiler output, not fixed addresses.
They may change with compiler versions, flags, source changes, or optimization.

## Translating `a = 5`

The output contained:

```asm
mov     w8, #5
stur    w8, [x29, #-8]
```

This can be read as:

```text
W8 = 5
memory[X29 - 8] = W8
```

`W8` is the lower 32-bit view of `X8`. A C `int` is normally 32 bits on this
platform. `stur` stores the value in a stack location.

For this compilation:

```text
a -> memory[X29 - 8]
```

## Translating `b = 10`

The output contained:

```asm
mov     w8, #10
stur    w8, [x29, #-12]
```

The effect is:

```text
W8 = 10
memory[X29 - 12] = W8
```

For this compilation:

```text
b -> memory[X29 - 12]
```

## Translating `result = a + b`

The observed instructions were:

```asm
ldur    w8, [x29, #-8]
ldur    w9, [x29, #-12]
add     w8, w8, w9
str     w8, [sp, #16]
```

Step by step:

```text
W8 = memory[X29 - 8]    // load a = 5
W9 = memory[X29 - 12]   // load b = 10
W8 = W8 + W9            // calculate 15
memory[SP + 16] = W8    // store result = 15
```

The observed data flow is therefore:

```text
stack value a -> W8
stack value b -> W9
W8 + W9       -> W8
W8             -> stack value result
```

The compiler keeps these local variables in memory in this unoptimized build.
That is useful for learning and debugging, but it is not a requirement of the
C language or of ARM64.

## Calling `printf`

The relevant output was:

```asm
ldr     w8, [sp, #16]
mov     x9, sp
str     x8, [x9]
adrp    x0, l_.str@PAGE
add     x0, x0, l_.str@PAGEOFF
bl      _printf
```

The first instruction loads the calculated result:

```text
W8 = memory[SP + 16]
```

The pair below obtains the address of the format string:

```asm
adrp    x0, l_.str@PAGE
add     x0, x0, l_.str@PAGEOFF
```

Together, these instructions place the address of:

```text
"Result = %d\n"
```

in `X0`.

The call itself is:

```asm
bl      _printf
```

`bl` means branch with link. It branches to `_printf` and records a return
address in `X30`/`LR`. Conceptually:

```text
main
  -> bl _printf
       -> printf implementation
  <- return through the link-register mechanism
```

This is the beginning of a longer chain. `printf` is a user-space library
function; it may call other library routines and eventually use operating
system services to write output. We will inspect that chain in a later
laboratory step.

## Function epilogue and return value

The observed epilogue was:

```asm
ldr     w0, [sp, #12]
ldp     x29, x30, [sp, #32]
add     sp, sp, #48
ret
```

The operations are:

1. Load the integer return value into `W0`.
2. Restore the saved frame pointer and link register.
3. Release the 48-byte stack frame.
4. Return using the address held by the restored link register.

The C statement:

```c
return 0;
```

is represented here by loading the return value into `W0`. Under the ARM64
calling convention, integer return values are normally passed in `W0` or `X0`.

## Comparing `-O0` and `-O2`

Two assembly files were generated:

```bash
clang -S -O0 -g -arch arm64 main.c -o main-O0.s
clang -S -O2 -g -arch arm64 main.c -o main-O2.s
```

The text-section portions were then displayed with:

```bash
sed -n '/__TEXT,__text/,/__TEXT,__cstring/p' main-O0.s
sed -n '/__TEXT,__text/,/__TEXT,__cstring/p' main-O2.s
```

### Observed `-O0` behavior

The unoptimized output reserved 48 bytes:

```asm
sub     sp, sp, #48
stp     x29, x30, [sp, #32]
add     x29, sp, #32
```

It stored the local values in stack locations:

```asm
mov     w8, #5
stur    w8, [x29, #-8]

mov     w8, #10
stur    w8, [x29, #-12]

ldur    w8, [x29, #-8]
ldur    w9, [x29, #-12]
add     w8, w8, w9
str     w8, [sp, #16]
```

This makes the source variables easier to associate with memory operations:

```text
a      -> stack location [X29 - 8]
b      -> stack location [X29 - 12]
result -> stack location [SP + 16]
```

These locations are specific to this compiler output.

### Observed `-O2` behavior

The optimized output reserved only 32 bytes:

```asm
sub     sp, sp, #32
stp     x29, x30, [sp, #16]
add     x29, sp, #16
```

The debug annotations state:

```asm
;DEBUG_VALUE: main:a <- 5
;DEBUG_VALUE: main:b <- 10
;DEBUG_VALUE: main:result <- 15
```

The key instruction is:

```asm
mov     w8, #15
```

The compiler evaluated the constant expression during compilation:

```text
5 + 10 -> 15
```

Therefore, the optimized output no longer needs separate runtime instructions
to load `a`, load `b`, add them, and store a separate `result` variable.

The result is passed through the call area:

```asm
str     x8, [sp]
adrp    x0, l_.str@PAGE
add     x0, x0, l_.str@PAGEOFF
bl      _printf
```

The return value is then created directly:

```asm
mov     w0, #0
```

### What disappeared at `-O2`

Compared with the observed `-O0` output, the optimized output removed the
runtime stack operations corresponding to:

```text
a = 5
b = 10
load a
load b
a + b
store result
```

This does not mean that the C source was ignored. It means the compiler found
an equivalent implementation for the observable behavior of this program:

```text
print "Result = 15"
return 0
```

At the C level, `a`, `b`, and `result` are named variables. At the machine-code
level, an optimizer may represent their values as constants, registers,
temporary stack values, or no distinct runtime object at all.

### Why `-O0` is useful for learning

`-O0` generally produces more instructions and more memory traffic. That can
make stepping through source lines and inspecting variables easier. It is
therefore useful for this introductory laboratory.

`-O2` is closer to a performance-oriented build. It may:

- fold constant expressions;
- remove unnecessary stores and loads;
- keep values in registers;
- combine or reorder operations;
- make source-level stepping appear non-linear;
- make some variables unavailable to the debugger.

The optimized debug annotations are hints for the debugger, not evidence that
each variable still exists as an independent memory location.

## What has been observed so far

At this stage, the translation is:

```text
C source
  |
  v
ARM64 assembly mnemonics
```

For example:

```text
a = 5          -> mov/stur
b = 10         -> mov/stur
result = a+b   -> ldur/ldur/add/str
printf(...)    -> address setup + bl _printf
return 0       -> value in W0 + ret
```

This is not yet the raw machine-code encoding. Assembly such as:

```asm
add w8, w8, w9
```

is a human-readable representation. The CPU executes the corresponding
ARM64 instruction encoding stored in the executable. The next stages will
create a Mach-O executable and inspect its disassembly and instruction bytes.

## Important observation

The register names and stack offsets above come from the actual `-O0 -g`
compiler output observed on this machine. They must not be copied as universal
facts. A different compiler version, optimization level, debug setting, target,
or source layout can produce different register allocation and stack layout.
