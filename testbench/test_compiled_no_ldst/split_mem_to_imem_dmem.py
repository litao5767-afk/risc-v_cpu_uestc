#!/usr/bin/env python3
"""
Parse a memory .mem/.verilog file with @address byte tokens and emit
- imem (words from 0x0000 .. 0x1FFF)
- dmem (words from 0x2000 .. 0x2FFF)
Skip the tohost/fromhost region at 0x3000 and above.

Outputs:
  rv32ui-p-ld_st_imem.hex  (one 8-hex word per line, little-endian assembled)
  rv32ui-p-ld_st_dmem.hex

Run from repository root.
"""
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
mem_file = root / 'rv32ui-p-ld_st.mem'
verilog_file = root / 'rv32ui-p-ld_st.verilog'
# Prefer a non-empty .mem file; if it's missing or empty, fall back to .verilog
if mem_file.exists() and mem_file.stat().st_size > 0:
    src = mem_file
elif verilog_file.exists():
    src = verilog_file
else:
    print('ERROR: cannot find rv32ui-p-ld_st.mem or rv32ui-p-ld_st.verilog in', root)
    sys.exit(1)

# read and parse
mem = {}  # addr -> byte (0-255)
with src.open('r') as f:
    lines = [l.strip() for l in f.readlines() if l.strip()]

has_at = any(l.startswith('@') for l in lines)
if has_at:
    addr = None
    for line in lines:
        if line.startswith('@'):
            a = line[1:].split()[0]
            addr = int(a, 16)
            continue
        if addr is None:
            continue
        toks = line.split()
        for t in toks:
            try:
                b = int(t, 16) & 0xFF
            except Exception:
                continue
            mem[addr] = b
            addr += 1
else:
    # likely a .mem with one 32-bit word hex per line (or bytes). Parse sequentially
    addr = 0
    import re
    word_re = re.compile(r'^[0-9a-fA-F]{8}$')
    byte_re = re.compile(r'^[0-9a-fA-F]{2}$')
    for line in lines:
        toks = line.split()
        if not toks:
            continue
        t = toks[0]
        if word_re.match(t):
            # 32-bit word, little-endian bytes
            w = int(t, 16)
            b0 = w & 0xFF
            b1 = (w >> 8) & 0xFF
            b2 = (w >> 16) & 0xFF
            b3 = (w >> 24) & 0xFF
            mem[addr + 0] = b0
            mem[addr + 1] = b1
            mem[addr + 2] = b2
            mem[addr + 3] = b3
            addr += 4
            continue
        # if first token is a byte token, parse all tokens as bytes
        parsed_any = False
        for tok in toks:
            if byte_re.match(tok):
                mem[addr] = int(tok,16)
                addr += 1
                parsed_any = True
            else:
                # ignore weird tokens
                pass
        if not parsed_any:
            # try to parse as longer hex string (multiple bytes)
            s = ''.join(toks)
            if len(s) % 2 == 0:
                for i in range(0, len(s), 2):
                    mem[addr] = int(s[i:i+2],16)
                    addr += 1

# helpers
def dump_words(outpath, base, size_bytes):
    words = []
    for i in range(0, size_bytes, 4):
        a = base + i
        b0 = mem.get(a+0, 0)
        b1 = mem.get(a+1, 0)
        b2 = mem.get(a+2, 0)
        b3 = mem.get(a+3, 0)
        word = (b3<<24) | (b2<<16) | (b1<<8) | b0
        words.append(word)
    with open(outpath, 'w') as fo:
        for w in words:
            fo.write('{:08x}\n'.format(w))
    return len(words)

# determine ranges
IMEM_BASE = 0x0000
DMEM_BASE = 0x2000
TOHOST_BASE = 0x3000
IMEM_BYTES = DMEM_BASE - IMEM_BASE
DMEM_BYTES = TOHOST_BASE - DMEM_BASE

out_imem = root / 'rv32ui-p-ld_st_imem.hex'
out_dmem = root / 'rv32ui-p-ld_st_dmem.hex'

printed = []
print('Parsing', src)
print('Found {} bytes defined (min addr {:x}, max addr {:x})'.format(len(mem), min(mem.keys()) if mem else 0, max(mem.keys()) if mem else 0))

n_imem = dump_words(out_imem, IMEM_BASE, IMEM_BYTES)
n_dmem = dump_words(out_dmem, DMEM_BASE, DMEM_BYTES)

print('Wrote', out_imem, 'words=', n_imem)
print('Wrote', out_dmem, 'words=', n_dmem)
print('Skipped tohost/fromhost region starting at 0x{:x}'.format(TOHOST_BASE))
print('Done')
