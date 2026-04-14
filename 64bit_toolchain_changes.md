# 64-bit Toolchain Migration Guide
## Assembler (cc2kla.py) and LCC Backend (klacpu.md)

This document covers every change needed in the assembler post-processor and the LCC
compiler backend to support the 64-bit CPU. It assumes the CPU hardware changes described
in the architecture plan: 16 × 64-bit registers, 32-bit byte-addressed memory, 64-bit
memory bus, 256-bit cache lines. The instruction encoding format (opcode nibbles, register
nibbles) is **unchanged**.

---

## Part 1 — Assembler Post-Processor (cc2kla.py)

### 1.1 Startup Stack Pointer Initialisation — No Change

The system has 128 MiB of physical memory (addresses `0x000_0000`–`0x7FF_FFFF`).
The stack starting address stays at `0xFFFFF` — no change needed here:
```python
# Unchanged
result.append("SETR P 0xFFFFF")
```

### 1.2 Negative Immediate Conversion

`fix_negative_immediates()` currently masks to 32-bit:
```python
# Old
return "0x{:X}".format(val & 0xFFFFFFFF)
```

With 64-bit registers, a value like `-1` must become the 64-bit unsigned equivalent:
```python
# New
return "0x{:X}".format(val & 0xFFFFFFFFFFFFFFFF)
```

### 1.3 Bitwise NOT (XORV mask)

The compiler backend emits `XORV Rx 0xFFFFFFFF` for bitwise NOT (`~x`). This is wrong
for 64-bit registers — it only flips the lower 32 bits.

In `transform_asm()`, add a fixup pass (or handle it in the backend instead — see §2.5):
```python
# Add to transform_asm fixup section
if 'XORV' in stripped and '0xFFFFFFFF' in stripped and '0xFFFFFFFFFFFFFFFF' not in stripped:
    stripped = stripped.replace('0xFFFFFFFF', 'NOTR_FIXUP')
    # Signal that backend should emit NOTR instead — see §2.5
```

**Preferred fix:** change the backend (§2.5) to emit `NOTR` directly. Then no assembler
fixup is needed.

### 1.4 TXR Output Width

The startup prints the return value of `main` with `TXR M`. This will now output
16 hex characters (64-bit) instead of 8. If your test expected-output files compare
against 8-char hex strings like `0000002A`, update them to 16-char: `000000000000002A`.

Alternatively, update `build.sh` / `run_tests.sh` to trim to the lower 8 chars for
backward compatibility during the transition.

### 1.5 jump_ops List

No changes needed. All branch and call mnemonics are unchanged.

### 1.6 BSS Buffer Size Units

The `#NAME SIZE` directive reserves SIZE words in the assembler. With 64-bit words, the
same `SIZE` now represents twice the byte capacity. If your assembler treats SIZE as a
byte count, everything stays the same. If it treats SIZE as a word count, note that each
word is now 8 bytes instead of 4 when calculating buffer sizes passed from C (e.g.
`sizeof(array)` via `.comm`).

Clarify with your assembler implementation which unit it uses, and update the `space()`
call in the backend accordingly (see §2.10).

---

## Part 2 — LCC Backend (src/klacpu.md)

### 2.1 Type Model Decision

The current backend uses a flat model: every C type is 1 machine word (CHAR_BIT = 32).
For the 64-bit CPU the analogous approach is:

**Option A — Keep flat model, word = 64 bits (recommended for minimal change)**
- `sizeof(char) = sizeof(int) = sizeof(long long) = sizeof(void*) = 1` (one 64-bit word)
- `CHAR_BIT = 64`
- All loads/stores use the single native word size (MEMSET64/MEMGET64)
- Pointer arithmetic: `p+1` always advances by one 64-bit word (8 bytes in hardware)
- Pros: almost no change to code generation logic
- Cons: `char` arrays waste 7 bytes per element; `int` and `long long` are indistinguishable

**Option B — Proper C sizes (larger change, more standards-conformant)**
- `char`/`unsigned char`: size=1 byte → use MEMSET8/MEMGET8
- `short`: size=2 bytes → use MEMSET16/MEMGET16
- `int`/`unsigned`: size=4 bytes → use MEMSET32/MEMGET32
- `long`/`long long`: size=8 bytes → use MEMSET64/MEMGET64
- `void*`: size=4 bytes (32-bit address space)
- Pointer arithmetic requires multiplying by `sizeof(*p)` (lcc handles this automatically
  once the sizes in the interface record are set correctly)

**This document covers both, with Option A as the primary path.**

---

### 2.2 Interface Record (`klacpuIR`)

#### Option A — flat 64-bit word model

Change the comment and `CHAR_BIT`-related documentation only. The interface sizes stay at
`1, 1` but now mean "1 × 64-bit machine word":
```c
// Old comment
/* 32-bit word-addressed CPU, 16 GPRs (A-P), no FP hardware.
 * All C types are 32 bits (CHAR_BIT=32). */

// New comment
/* 64-bit word-addressed CPU, 16 GPRs (A-P), no FP hardware.
 * All C types are 64 bits (CHAR_BIT=64). */
```

The `klacpuIR` struct values are **unchanged** for Option A.

#### Option B — proper C sizes

```c
// Old
Interface klacpuIR = {
    1, 1, 0,  /* char:      size=1, align=1 */
    1, 1, 0,  /* short:     size=1, align=1 */
    1, 1, 0,  /* int:       size=1, align=1 */
    1, 1, 0,  /* long:      size=1, align=1 */
    1, 1, 0,  /* longlong:  size=1, align=1 */
    ...
    1, 1, 0,  /* T*:        size=1, align=1 */
    ...

// New
Interface klacpuIR = {
    1, 1, 0,  /* char:      size=1,  align=1  (1 byte) */
    2, 2, 0,  /* short:     size=2,  align=2  (2 bytes) */
    4, 4, 0,  /* int:       size=4,  align=4  (4 bytes) */
    8, 8, 0,  /* long:      size=8,  align=8  (8 bytes) */
    8, 8, 0,  /* longlong:  size=8,  align=8  (8 bytes) */
    4, 4, 1,  /* float:     size=4,  align=4, outofline=1 */
    8, 8, 1,  /* double:    size=8,  align=8, outofline=1 */
    8, 8, 1,  /* longdouble: same */
    4, 4, 0,  /* T*:        size=4,  align=4  (32-bit pointer) */
    0, 1, 0,  /* struct:    size=0,  align=1 */
    1,        /* little_endian = 1 (byte-addressed, little-endian convention) */
```

With Option B, lcc's type system drives the correct instruction selection automatically
via the `%term` suffixes — you must add `I2`, `I4`, `I8`, `U2`, `U4`, `U8`, `P4` term
variants and corresponding rules (see §2.8).

---

### 2.3 Register Names and Allocation

**No changes needed.** Registers remain A–P (R0–R15). The bitmasks, `ireg[]` array, and
`progbeg()` are unchanged:
```c
/* Unchanged */
static char *rnames[] = {"A","B","C","D","E","F","G","H",
                          "I","J","K","L","M","N","O","P"};
```

---

### 2.4 Constant Shifts — `rc5` → `rc6`

The `rc5` non-terminal limits constant shift amounts to 0–31. With 64-bit registers,
shifts of 0–63 are valid:

```
# Old
rc5: CNSTI1  "%a"  range(a, 0, 31)
rc5: CNSTU1  "%a"  range(a, 0, 31)

reg: LSHI1(reg,rc5)  "COPY %c %0\nSHLV %c %1\n"  2
reg: LSHU1(reg,rc5)  "COPY %c %0\nSHLV %c %1\n"  2
reg: RSHI1(reg,rc5)  "COPY %c %0\nSHRAV %c %1\n" 2
reg: RSHU1(reg,rc5)  "COPY %c %0\nSHRV %c %1\n"  2
```

```
# New
rc6: CNSTI1  "%a"  range(a, 0, 63)
rc6: CNSTU1  "%a"  range(a, 0, 63)

reg: LSHI1(reg,rc6)  "COPY %c %0\nSHLV %c %1\n"  2
reg: LSHU1(reg,rc6)  "COPY %c %0\nSHLV %c %1\n"  2
reg: RSHI1(reg,rc6)  "COPY %c %0\nSHRAV %c %1\n" 2
reg: RSHU1(reg,rc6)  "COPY %c %0\nSHRV %c %1\n"  2
```

Also update the variable-shift loops in `emit2()` — the loop logic is correct but the
loop can now run up to 63 iterations instead of 31.

---

### 2.5 Bitwise NOT — `XORV 0xFFFFFFFF` → `NOTR`

```c
// Old
case BCOM+I: case BCOM+U: {
    int src0 = getregnum(p->kids[0]);
    if (dst != src0)
        print("COPY %s %s\n", ireg[dst]->x.name, ireg[src0]->x.name);
    print("XORV %s 0xFFFFFFFF\n", ireg[dst]->x.name);  // WRONG for 64-bit
    break;
}
```

```c
// New — use the dedicated NOT instruction
case BCOM+I: case BCOM+U: {
    int src0 = getregnum(p->kids[0]);
    if (dst != src0)
        print("COPY %s %s\n", ireg[dst]->x.name, ireg[src0]->x.name);
    print("NOTR %s\n", ireg[dst]->x.name);
    break;
}
```

`XORV` only accepts a 32-bit immediate, so it cannot flip all 64 bits. `NOTR` is the
correct single-instruction solution and is already in the ISA.

---

### 2.6 Memory Load/Store Instructions

The renaming from the CPU plan affects what instructions the backend emits:

| Old instruction | New instruction | Operation |
|---|---|---|
| `MEMSETRR Rs Ra` | `MEMSET64 Rs Ra` | Store full 64-bit register to mem[Ra] |
| `MEMREADRR Rd Ra` | `MEMGET64 Rd Ra` | Load full 64-bit word from mem[Ra] into Rd |
| `MEMSETR Rx Val` | `MEMSETR Rx Val` | Store from value to address (unchanged name) |
| `MEMREADR Rd Val` | `MEMREADR Rd Val` | Load from address to register (unchanged name) |
| `STIDX Rs Ra off` | `STIDX64 Rs Ra off` | Indexed store — full 64-bit |
| `LDIDX Rd Ra off` | `LDIDX64 Rd Ra off` | Indexed load — full 64-bit |

Update every occurrence in `emit2()` and the gram rules:

```
# Old
reg: INDIRI1(reg)     "MEMREADRR %c %0\n"  1
stmt: ASGNI1(reg,reg) "MEMSETRR %1 %0\n"   1

# New
reg: INDIRI1(reg)     "MEMGET64 %c %0\n"   1
stmt: ASGNI1(reg,reg) "MEMSET64 %1 %0\n"   1
```

In `emit2()`:
```c
// Old prologue
print("MEMSETRR O P\n");   /* mem[SP] = FP */
print("MEMREADRR O P\n");  /* FP = mem[SP] */

// New prologue
print("MEMSET64 O P\n");   /* mem[SP] = FP (64-bit save) */
print("MEMGET64 O P\n");   /* FP = mem[SP] (64-bit restore) */
```

```c
// Old callee-saved spill/restore
print("STIDX %s O %s\n", ...);   /* Old indexed store */
print("LDIDX %s O %s\n", ...);   /* Old indexed load  */

// New
print("STIDX64 %s O %s\n", ...);
print("LDIDX64 %s O %s\n", ...);
```

Also update `blkfetch()` and `blkstore()`:
```c
// Old
static void blkfetch(int size, int off, int reg, int tmp) {
    assert(size == 1);
    print("LDIDX %s %s %d\n", ireg[tmp]->x.name, ireg[reg]->x.name, off);
}
static void blkstore(int size, int off, int reg, int tmp) {
    assert(size == 1);
    print("STIDX %s %s %d\n", ireg[tmp]->x.name, ireg[reg]->x.name, off);
}

// New
static void blkfetch(int size, int off, int reg, int tmp) {
    assert(size == 1);
    print("LDIDX64 %s %s %d\n", ireg[tmp]->x.name, ireg[reg]->x.name, off);
}
static void blkstore(int size, int off, int reg, int tmp) {
    assert(size == 1);
    print("STIDX64 %s %s %d\n", ireg[tmp]->x.name, ireg[reg]->x.name, off);
}
```

---

### 2.7 Stack Frame Layout and SP Arithmetic

Both tools are already byte-addressed. The current 32-bit frame convention is:

- One slot = 4 bytes (one 32-bit register)
- `MEMSETRR O P` saves FP (4 bytes) at `mem[SP]`
- `DECR P` moves SP down 4 bytes (one slot)
- `MINUSV P framesize_actual` allocates `framesize_actual` × 4 bytes
- `STIDX Rx O -(slot+1)` stores to slot at byte offset `-(slot+1)*4` from FP
- `INCR P` moves SP up 4 bytes on epilogue

For 64-bit, each slot doubles to **8 bytes** (one 64-bit register). Every place that
currently moves or indexes by 4 bytes must move or index by 8 bytes instead.

**Prologue — FP save and frame allocation:**
```c
// Old (32-bit, 4 bytes/slot)
print("MEMSETRR O P\n");               /* mem[SP] = FP (32-bit) */
print("DECR P\n");                      /* SP -= 4               */
print("COPY O P\n");                    /* FP = SP               */
if (framesize_actual > 0)
    print("MINUSV P %s\n", imm(framesize_actual));   /* SP -= N*4 */

// New (64-bit, 8 bytes/slot)
print("MEMSET64 O P\n");               /* mem[SP] = FP (64-bit) */
print("MINUSV P 8\n");                 /* SP -= 8               */
print("COPY O P\n");                   /* FP = SP               */
if (framesize_actual > 0)
    print("MINUSV P %s\n", imm(framesize_actual * 8));  /* SP -= N*8 */
```

**Callee-saved register spills (in `function()`):**
```c
// Old
print("STIDX %s O %s\n",  ireg[i]->x.name, imm(-(maxoffset + slot + 1)));
print("LDIDX %s O %s\n",  ireg[i]->x.name, imm(-(maxoffset + slot + 1)));

// New
print("STIDX64 %s O %s\n", ireg[i]->x.name, imm((-(maxoffset + slot + 1)) * 8));
print("LDIDX64 %s O %s\n", ireg[i]->x.name, imm((-(maxoffset + slot + 1)) * 8));
```

**Register argument saves (in `function()`):**
```c
// Old
print("STIDX %s O %s\n", ireg[i]->x.name, imm(-(p->x.offset + 1)));

// New
print("STIDX64 %s O %s\n", ireg[i]->x.name, imm((-(p->x.offset + 1)) * 8));
```

**Epilogue — FP restore:**
```c
// Old (32-bit)
print("COPY P O\n");
print("INCR P\n");                     /* SP += 4 */
print("MEMREADRR O P\n");             /* FP = mem[SP] (32-bit load) */

// New (64-bit)
print("COPY P O\n");
print("ADDV P 8\n");                  /* SP += 8 */
print("MEMGET64 O P\n");             /* FP = mem[SP] (64-bit load) */
```

**Frame-relative address computation (in `emit2()`):**
```c
// ADDRF+P — parameter address (params above FP, positive side)
// Old
print("COPY %s O\nADDV %s %s\n", ..., imm(off + framesize_actual + 1));
// New
print("COPY %s O\nADDV %s %s\n", ..., imm((off + framesize_actual + 1) * 8));

// ADDRL+P — local variable address (locals below FP, negative side)
// Old
print("COPY %s O\nMINUSV %s %s\n", ..., imm(off + 1));
// New
print("COPY %s O\nMINUSV %s %s\n", ..., imm((off + 1) * 8));
```

**Stack argument stores (ARG+I handler in `emit2()`):**
```c
// Old
print("STIDX %s P %d\n", ireg[src]->x.name, stkoff);

// New
print("STIDX64 %s P %d\n", ireg[src]->x.name, stkoff * 8);
```

**`doarg()` — outgoing stack argument slot size:**
```c
// Old — each arg slot is 1 unit (4 bytes)
p->syms[2] = intconst(mkactual(1, p->syms[0]->u.c.v.i));

// New — each arg slot is 1 unit but now 8 bytes; size must reflect that
p->syms[2] = intconst(mkactual(8, p->syms[0]->u.c.v.i));
```

In summary: `framesize_actual` stays as a **slot count**; multiply by **8** whenever
converting to a byte offset. The `STIDX`/`LDIDX` and `MEMSETRR`/`MEMREADRR`
instruction names also change as described in §2.6.

---

### 2.8 Large Constants — `SETR` vs `SETR64`

`SETR Rx imm` accepts a 32-bit immediate. For 64-bit code this is sufficient for most
address constants (pointers are 32-bit) and small integer literals, but 64-bit integer
constants with set bits above bit 31 require `SETR64`.

Add a helper alongside `imm()`:
```c
/* Emit the correct load-immediate sequence for a 64-bit value. */
static void emit_setr64(int dst, unsigned long long v) {
    if (v <= 0xFFFFFFFFULL) {
        /* Fits in 32 bits — single SETR is sufficient */
        print("SETR %s 0x%X\n", ireg[dst]->x.name, (unsigned)v);
    } else {
        /* Requires 64-bit load: SETR64 Rx lo32 hi32 */
        print("SETR64 %s 0x%X 0x%X\n",
              ireg[dst]->x.name,
              (unsigned)(v & 0xFFFFFFFF),
              (unsigned)(v >> 32));
    }
}
```

In `defconst()`, handle 64-bit (Option B `long long`) constants:
```c
// Old
case I:
    print(".word 0x%x\n", (unsigned)(v.i));
    break;

// New — emit two consecutive 32-bit words for a 64-bit value
// (or a single .quad directive if your assembler supports it)
case I:
    if (IR->longlong->size == 8) {
        /* 64-bit: low word first (little-endian), or as two .word */
        print(".word 0x%x\n", (unsigned)(v.i & 0xFFFFFFFF));
        print(".word 0x%x\n", (unsigned)((unsigned long long)v.i >> 32));
    } else {
        print(".word 0x%x\n", (unsigned)(v.i));
    }
    break;
```

For Option A (flat 64-bit words), `SETR` handles all pointer and small-integer constants
unchanged. The `emit_setr64` helper is only needed if you actually generate 64-bit
literal loads in codegen.

---

### 2.9 `imm()` Helper for Negative Values

The `imm()` function formats frame offsets as decimal. Negative offsets flow into
`STIDX64 / LDIDX64` and `ADDV / MINUSV`. The assembler post-processor converts negative
decimals to 64-bit hex (see §1.2). No change needed in `imm()` itself, but ensure the
assembler handles the resulting 64-bit hex value correctly.

---

### 2.10 Data Definition — `.word` and `.space`

`defstring()` emits one `.word` per character. With Option A (CHAR_BIT=64) strings still
work the same way — one 64-bit word per character, wasting the upper bytes. If you later
move to Option B (byte-granular), switch to `.byte` directives.

`space()` emits `.space N` where N is a word count. Document clearly that N is now in
64-bit words. Update the assembler to interpret `.space N` as `N * 8` bytes.

---

### 2.11 Option B — Additional Grammar Rules for Sub-word Types

If you implement Option B (proper C sizes), add grammar rules for the new lcc type
suffixes. lcc uses the size as part of the type suffix: `I1`=byte, `I2`=short, `I4`=int,
`I8`=longlong, `P4`=pointer.

Key new rules needed:
```
# Byte loads/stores (char)
reg:  INDIRI1(reg)     "MEMGET8 %c %0\n"    1   /* zero-extend byte → 64 */
stmt: ASGNI1(reg,reg)  "MEMSET8 %1 %0\n"    1

# Halfword loads/stores (short)  
reg:  INDIRI2(reg)     "MEMGET16 %c %0\n"   1   /* zero-extend halfword → 64 */
stmt: ASGNI2(reg,reg)  "MEMSET16 %1 %0\n"   1

# Word loads/stores (int — 32-bit)
reg:  INDIRI4(reg)     "MEMGET32 %c %0\n"   1   /* zero-extend word → 64 */
stmt: ASGNI4(reg,reg)  "MEMSET32 %1 %0\n"   1

# Doubleword loads/stores (long long / long — 64-bit)
reg:  INDIRI8(reg)     "MEMGET64 %c %0\n"   1
stmt: ASGNI8(reg,reg)  "MEMSET64 %1 %0\n"   1

# Pointer loads/stores (32-bit address in 64-bit register)
reg:  INDIRP4(reg)     "MEMGET32 %c %0\n"   1   /* load 32-bit addr, zero-extend */
stmt: ASGNP4(reg,reg)  "MEMSET32 %1 %0\n"   1   /* store lower 32 bits */
```

Sign-extension on load (for signed `char`, `short`, `int` to 64-bit):
```
# Signed byte load — load then sign-extend
reg: INDIRI1(reg)  "MEMGET8 %c %0\nSEXTB %c\n"   2

# Signed halfword load
reg: INDIRI2(reg)  "MEMGET16 %c %0\nSEXTH %c\n"  2

# Signed word load
reg: INDIRI4(reg)  "MEMGET32 %c %0\nSEXTW %c\n"  2
```

Note: `SEXTB` and `SEXTH` already exist in the ISA (they now extend to 64 bits). `SEXTW`
is a new instruction added in the 64-bit plan.

---

## Part 3 — Build Pipeline (build.sh / cc2kla.py)

### 3.1 Stack Pointer in `build.sh` — No Change

The system has 128 MiB of physical memory. The stack initialisation in `build.sh`
and `uart_stubs.kla` stays at `SETR P 0xFFFFF` — no change needed.

### 3.2 TXR Width in Test Scripts

`run_tests.sh` likely compares `TXR M` output (hex register value). Update expected
outputs from 8-char to 16-char hex strings, or add a mask/trim step in the comparison:
```bash
# Old expected
expected="0000002A"

# New expected (64-bit output)
expected="000000000000002A"

# Or: strip upper zeroes for backward compatibility
actual=$(uart_output | sed 's/^0*//')
```

### 3.3 `libc.c` — No ABI Changes Required (Option A)

With Option A (flat 64-bit word model), `sizeof` all types remains 1, pointer arithmetic
is unchanged, and `libc.c` functions (`strlen`, `memcpy`, `memset` etc.) work as-is.
All existing test programs (the 10/10 test suite) should continue to pass after
recompilation.

With Option B, `libc.c` must be substantially rewritten for correct byte-granular string
and memory operations.

---

## Summary of Changes

### cc2kla.py

| Location | Old | New |
|---|---|---|
| SP init | `SETR P 0xFFFFF` | **unchanged** (128 MiB system) |
| Negative imm mask | `val & 0xFFFFFFFF` | `val & 0xFFFFFFFFFFFFFFFF` |
| BCOM fixup | `XORV Rx 0xFFFFFFFF` | handled in backend (§2.5) — no assembler fixup needed |
| Shift range comment | max 31 | max 63 |

### klacpu.md

| Location | Old | New |
|---|---|---|
| Backend comment | CHAR_BIT=32 | CHAR_BIT=64 |
| `BCOM` case | `XORV %s 0xFFFFFFFF` | `NOTR %s` |
| `rc5` shift range | `range(a, 0, 31)` | `range(a, 0, 63)` (rename to `rc6`) |
| `INDIRI1` gram rule | `MEMREADRR` | `MEMGET64` |
| `ASGNI1` gram rule | `MEMSETRR` | `MEMSET64` |
| FP save in prologue | `MEMSETRR O P` / `DECR P` | `MEMSET64 O P` / `MINUSV P 8` |
| FP restore in epilogue | `COPY P O` / `INCR P` / `MEMREADRR O P` | `COPY P O` / `ADDV P 8` / `MEMGET64 O P` |
| Frame allocation | `MINUSV P N` | `MINUSV P N*8` |
| Callee-saved spill | `STIDX Rx O -(slot+1)` | `STIDX64 Rx O -(slot+1)*8` |
| Callee-saved restore | `LDIDX Rx O -(slot+1)` | `LDIDX64 Rx O -(slot+1)*8` |
| Reg arg save | `STIDX Rx O -(off+1)` | `STIDX64 Rx O -(off+1)*8` |
| FP-relative addr (param) | `off + framesize_actual + 1` | `(off + framesize_actual + 1) * 8` |
| FP-relative addr (local) | `off + 1` | `(off + 1) * 8` |
| Stack arg slot size | `mkactual(1, ...)` | `mkactual(8, ...)` |
| Block copy fetch | `LDIDX` | `LDIDX64` |
| Block copy store | `STIDX` | `STIDX64` |
| `klacpuIR` sizes (Option B only) | all `1,1` | type-appropriate sizes |
