# From ARM64 Assembly to a Mach-O Executable

This note records the next laboratory step: compiling the C program into a
native macOS executable and examining its Mach-O structure with `file` and
`otool`.

## Build the executable

The executable was created with:

```bash
clang -g -O0 -arch arm64 main.c -o main
```

Unlike `clang -S`, this command does not stop at textual assembly. Clang
assembles the ARM64 instructions, links the program with the required macOS
libraries, and produces the executable file `main`.

The high-level pipeline is now:

```text
main.c
  |
  v
ARM64 assembly
  |
  v
ARM64 machine-code object data
  |
  v
Mach-O executable: main
```

## Run the executable

The program was run with:

```bash
./main
```

Observed output:

```text
Result = 15
```

This confirms that the executable can be launched natively on the current
Apple Silicon macOS system and that its observable result is correct.

## Identify the file format

The command:

```bash
file main
```

produced:

```text
main: Mach-O 64-bit executable arm64
```

This tells us:

- `Mach-O`: the native executable/object-file format used by macOS.
- `64-bit`: the executable uses 64-bit addresses and related structures.
- `executable`: this is a runnable program, not only an object file.
- `arm64`: the machine-code target is ARM64, matching Apple Silicon.

## Mach-O header

The command:

```bash
otool -hv main
```

produced:

```text
MH_MAGIC_64    ARM64        ALL  0x00     EXECUTE    17       1056   NOUNDEFS DYLDLINK TWOLEVEL PIE
```

The observed header fields were:

```text
magic       MH_MAGIC_64
cputype     ARM64
cpusubtype  ALL
filetype    EXECUTE
ncmds       17
sizeofcmds  1056
flags       NOUNDEFS DYLDLINK TWOLEVEL PIE
```

### `magic`

`MH_MAGIC_64` identifies a 64-bit Mach-O file using the expected byte order.

### `cputype` and `cpusubtype`

The executable targets the ARM64 CPU family. The observed subtype was `ALL`,
meaning that the executable is not restricted to a more specific subtype in
this header output.

### `filetype`

`EXECUTE` identifies this file as a runnable executable image.

### `ncmds` and `sizeofcmds`

The file contains 17 load commands. Together, their command data occupies
1056 bytes.

Load commands tell the macOS loader how to map the file, where its entry point
is, which dynamic libraries it needs, and where related metadata is located.

### Header flags

The observed flags include:

- `NOUNDEFS`: the final image does not contain unresolved ordinary undefined
  symbols that must remain unresolved at static link completion.
- `DYLDLINK`: the image participates in dynamic linking.
- `TWOLEVEL`: symbol lookup uses the two-level namespace model.
- `PIE`: the executable is position-independent and can be relocated by the
  system's address-space layout randomization mechanisms.

The `PIE` flag is one reason that a virtual address observed during one run
should not be treated as a permanent address for every run.

## Load commands and segments

The command:

```bash
otool -l main
```

showed the following important segments and sections.

### `__PAGEZERO`

Observed values:

```text
segname __PAGEZERO
vmaddr  0x0000000000000000
vmsize  0x0000000100000000
filesize 0
```

`__PAGEZERO` occupies the lowest virtual-address range but has no file
contents and no memory permissions. It acts as an unmapped guard region.

Its purpose is to make accesses through a null or very-low pointer fail rather
than accidentally accessing ordinary program data.

This is virtual address space reservation, not physical RAM containing a
gigantic zero-filled file region.

### `__TEXT`

Observed values:

```text
segname  __TEXT
vmaddr   0x0000000100000000
vmsize   0x0000000000004000
fileoff  0
filesize 16384
maxprot  0x00000005
initprot 0x00000005
nsects   4
```

`__TEXT` contains read-only executable content. The protection value
`0x5` represents read plus execute permissions in this output.

The segment contains four sections:

```text
__text
__stubs
__cstring
__unwind_info
```

#### `__TEXT,__text`

Observed values:

```text
sectname __text
addr     0x0000000100000460
size     0x60
offset   1120
align    2^2 (4)
```

This is the section containing the program's native ARM64 instruction bytes.
The section's file offset is 1120 bytes, and its size is 96 bytes.

The `entryoff` reported later is also 1120:

```text
entryoff 1120
```

This indicates that the executable entry point begins at the file offset of
the `__text` section for this small program. The loader still interprets this
relative to the Mach-O image and its mapped address; it is not a permanent
process virtual address.

#### `__TEXT,__stubs`

Observed values:

```text
sectname __stubs
addr     0x00000001000004c0
size     0x0c
offset   1216
```

The stub section contains small linker-generated code sequences used to reach
external functions through dynamic linking. The call to `_printf` can
involve this linking machinery rather than embedding the complete library
implementation inside `main`.

#### `__TEXT,__cstring`

Observed values:

```text
sectname __cstring
addr     0x00000001000004cc
size     0x0d
offset   1228
```

This section contains null-terminated C string literals. In this program it
contains:

```text
"Result = %d\n"
```

The size is 13 bytes, including the terminating null byte.

The format string is data, not an instruction. The ARM64 code obtains its
address using:

```asm
adrp    x0, l_.str@PAGE
add     x0, x0, l_.str@PAGEOFF
```

#### `__TEXT,__unwind_info`

Observed values:

```text
sectname __unwind_info
addr     0x00000001000004dc
size     0x58
offset   1244
```

This section contains compact information used for stack unwinding and related
runtime/debugging operations.

### `__DATA_CONST`

Observed values:

```text
segname  __DATA_CONST
vmaddr   0x0000000100004000
vmsize   0x0000000000004000
fileoff  16384
filesize 16384
maxprot  0x00000003
initprot 0x00000003
nsects   1
```

The protection value `0x3` represents read plus write permissions in this
output. This segment contains:

```text
__got
```

The `__got` section is the Global Offset Table. It supports access to
addresses that can be resolved or adjusted during dynamic linking.

### `__LINKEDIT`

Observed values:

```text
segname  __LINKEDIT
vmaddr   0x0000000100008000
vmsize   0x0000000000004000
fileoff  32768
filesize 920
maxprot  0x00000001
initprot 0x00000001
nsects   0
```

This segment contains linker and loader metadata rather than ordinary program
instructions or C local variables. The output places several load-command data
records here, including chained fixups, exports, symbol-table data, and code
signature data.

## Important non-segment load commands

### `LC_DYLD_CHAINED_FIXUPS`

```text
dataoff  32768
datasize 96
```

This describes chained pointer-fixup information used by the dynamic loader.

### `LC_DYLD_EXPORTS_TRIE`

```text
dataoff  32864
datasize 48
```

This stores exported-symbol information in a compact trie representation.

### `LC_SYMTAB`

```text
symoff  32920
nsyms   12
stroff  33120
strsize 152
```

This points to the symbol table and its associated string table.

### `LC_LOAD_DYLINKER`

```text
name /usr/lib/dyld
```

`dyld` is Apple's dynamic loader. It helps load the executable, resolve
dynamic-library dependencies, apply required fixups, and prepare the process
before control reaches the program's entry point.

### `LC_BUILD_VERSION`

```text
platform 1
minos    27.0
sdk      27.0
```

This records the platform and the minimum macOS/SDK version information used
for this build.

### `LC_MAIN`

```text
entryoff 1120
stacksize 0
```

`LC_MAIN` describes the executable's entry offset. The observed offset is the
same file offset as the beginning of `__TEXT,__text`:

```text
__text offset = 1120
entryoff     = 1120
```

The entry point is not necessarily the C `main` function. The system starts
through the executable's runtime entry machinery, which eventually prepares
the process and calls `main`.

### `LC_LOAD_DYLIB`

```text
name /usr/lib/libSystem.B.dylib
```

The executable declares a dependency on Apple's `libSystem.B.dylib`. This
library umbrella participates in providing standard C and system-level
functionality, including the path used by `printf`.

The complete implementation of `printf` is not copied into this small
executable. Dynamic linking connects the executable to the system library.

### `LC_CODE_SIGNATURE`

```text
dataoff  33280
datasize 408
```

This points to the code-signature data associated with the executable.

## Assembly versus Mach-O contents

The relationship between the earlier assembly and this executable is:

```text
ARM64 assembly mnemonic
        |
        v
ARM64 instruction encoding
        |
        v
__TEXT,__text section in Mach-O
```

For example, the assembly instruction:

```asm
add     w8, w8, w9
```

is not stored in the executable as the text `add w8, w8, w9`. It is encoded
as a fixed-width ARM64 machine instruction inside `__TEXT,__text`.

The assembly label:

```asm
_main:
```

identifies a symbol and location during assembly and linking. The executable
contains the resulting instruction bytes and symbol/linker metadata.

The format string is kept separately in `__TEXT,__cstring`, and the code
references its address. Code and read-only string data are therefore related
but are not the same bytes or section.

## Does macOS load the entire file into RAM?

Not in the simple sense of copying the whole file into one contiguous RAM
buffer.

macOS maps segments of the Mach-O image into the process's virtual address
space. The mapping is described by load commands and is backed by the
executable file where appropriate. Virtual-memory pages can be loaded or
faulted in as needed.

This distinction is important:

```text
file offset
    !=
process virtual address
    !=
physical RAM address
```

The output's addresses such as:

```text
__TEXT vmaddr 0x0000000100000000
__text addr   0x0000000100000460
```

describe the image's virtual-address layout before considering runtime
relocation effects. Because this executable is PIE, ASLR can change the
runtime mapping location.

## Current mental model

At this stage the experiment can be represented as:

```text
C source
   |
   v
Clang
   |
   v
ARM64 assembly
   |
   v
ARM64 machine-code bytes
   |
   v
Mach-O file
   |
   v
macOS loader and dyld
   |
   v
process virtual-memory mappings
```

The next laboratory step is to disassemble the actual `__TEXT,__text` bytes
and compare the executable's instruction addresses with the earlier
`main-O0.s` output.
