# The cartridge

16 KB in page 1 (0x4000-0x7FFF), with no bank switching. The "AB" header declares
only **INIT** (0x4077).

## What INIT does

INIT sets interrupt mode 1, writes a `jp` into the H.KEYI hook (0xFD9A) pointing
at **0x402C**, puts the stack at 0xE400, clears the work RAM 0xE000-0xE3FF, and
then falls into a `jr` to itself at 0x40A4. From that point on the main program
does nothing: the interrupt, once per frame, runs the whole game.

## The screen

SCREEN 2. The cartridge does not store whole screens: it stores scripts. The name
table is filled by the interpreter at 0x405E, and the pattern and colour tables
by the run-length decompressor at 0x440D.

## The RAM map

Everything the game touches lives from 0xE000 up, under the stack at 0xE400:

- **0xE000** main state, the index into the handler table at 0x40C2
- **0xE001** sub-state, split inside each handler
- **0xE002** mode flags: bit 6 is the demo, bit 7 the scoreboard
- **0xE005** the interrupt reentrancy guard
- **0xE050-0xE06F** player 1's event state; **0xE080-0xE09F** player 2's
- **0xE052** the current event; **0xE054** the attempts left
- **0xE010-0xE03A** the three sound channels, eleven bytes each
- **0xE100..** the actors and sprites of the current event
