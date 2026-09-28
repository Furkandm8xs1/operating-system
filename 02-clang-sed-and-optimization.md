# Clang, Sed, and ARM64 Optimization Comparison

This note contains the second part of the laboratory: what `clang` and `sed`
do, followed by a comparison of the real `-O0` and `-O2` ARM64 assembly
outputs generated from `main.c`.

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

The command used for the first experiment stops before assembling and linking:

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

## Generate both optimization levels

The two assembly files were generated with:

```bash
clang -S -O0 -g -arch arm64 main.c -o main-O0.s
clang -S -O2 -g -arch arm64 main.c -o main-O2.s
```

The text-section portions were then displayed with:

```bash
sed -n '/__TEXT,__text/,/__TEXT,__cstring/p' main-O0.s
sed -n '/__TEXT,__text/,/__TEXT,__cstring/p' main-O2.s
```

## Observed `-O0` behavior

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

## Observed `-O2` behavior

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

## What disappeared at `-O2`

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

## Why `-O0` is useful for learning

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

## Main lesson

The C source, assembly text, and runtime machine state are different
abstraction levels:

```text
C variables
    |
    v
compiler representation
    |
    v
ARM64 instructions
    |
    v
runtime registers and memory
```

With `-O0`, the relationship between these levels is often easier to observe.
With `-O2`, the compiler is free to preserve behavior while changing or
removing intermediate representations that are not externally observable.

The register names, stack offsets, and instruction sequence documented here
come from the actual assembly output observed on this machine. They may change
with the compiler version, target settings, optimization level, debug options,
or source code.
