# The code

## The state machine

The interrupt (0x402C) calls 0x40A6 every frame. It reads 0xE000, the **main
state**, and with it a jump through the table at 0x40C2 reaches one of the
handlers; the high byte, 0xE001, is the **sub-state**. Bit 6 of 0xE002 marks the
demo, and 0x40A6 pushes as the return address either the game handler (0x430A) or
the demo one (0x44C9) before jumping to the state handler.

## Two drawing interpreters

Nothing on screen is a stored bitmap. Two interpreters build the VRAM:

- **0x405E** copies byte by byte into the name table, with a destination word,
  a jump to a new destination (0xFE) and an end (0xFF).
- **0x440D** decompresses by runs into the pattern and colour tables: a count
  byte whose top bit tells a literal copy from a fill of one byte, and a 0x00
  that ends the block. The website's figures come from running this one in
  Python.

## Two players in one place

The event runs on the block at 0xE050. When the turn changes, 0x413E swaps that
block with the one at 0xE080 in a single 32-byte routine, so every other routine
always works on 0xE050 without caring who is playing.

## The sound

0x7C3D is the per-frame player: three eleven-byte channel records at 0xE010, each
reading its melody with a small command interpreter and writing the PSG through
the BIOS. It is the framework Konami reused across its MSX cartridges, with its
tone table and effects at the end of the ROM.
