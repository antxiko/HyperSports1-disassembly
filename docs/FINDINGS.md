# Findings

## The order of the events is in the table, not in the texts

The four labels sit back to back in the ROM from 0x6F08 in the order DIVING,
TRAMPOLINE, LONG HORSE, HORIZONTAL BAR. **That is not the order they are played
in.** What picks is the four-pointer table at 0x6F00, which 0x6E38 indexes with
`0xE052 and 3`, and that table reorders them: 0 DIVING, 1 LONG HORSE,
2 TRAMPOLINE, 3 HORIZONTAL BAR. Reading the texts instead of the table swaps
**the second and the third** — which is exactly what this site said until it was
checked in the emulator, reading the name table as text while the attract mode
plays all four.

## The scoreboard font is not in the cartridge

The scoreboard writes letters and digits as tile numbers in plain ASCII, and the
game does not draw those tiles: 0x43BF takes the `CGTBL` pointer at 0x0004 —the
character table of the **MSX ROM**—, skips 0x180 bytes to start at `'0'` and
uploads 48 characters to VRAM, across the three thirds. The cartridge supplies
only **six** of its own, through two compressed scripts: tiles 0x3A and 0x3B —the
source of the dash in `1P-000000`— and 0x5C to 0x5F.

Checked: the BIOS font plus those touch-ups gives the 384 bytes present in VRAM,
in all three thirds, without a single difference.

## The crowd claps with two scripts, and one is the tail of the other

The stands are animated by alternating two consecutive cartridge scripts, 0x4976
and 0x498E, over VRAM 0x2158. The first is not a separate block: it is **the tail
of the common stream** that 0x4891 decompresses when setting up any event, and
which is also dumped on its own to animate. 431 dumps in the first 60 seconds,
measured with a breakpoint at 0x440D.

That accounts for the only difference that shows up when checking the ROM's
drawings against VRAM: the dump catches one of the two frames, and not always
the same one in all three thirds — the game only animates the third where the
stands are visible.

## An event's screen is stored nowhere

DIBUJA_MARCO (0x4816) uploads the event's drawings to VRAM: four blocks from its
list plus two common ones, each dumped into the three thirds. But **nobody writes
the tile map in one go**: the event's engine composes it as it runs, tile by tile
—1,692 writes to the name table in the first 22 seconds, all of them through the
script interpreter at 0x405E—. Reproducing the screen would mean reproducing the
game, so this site's scenes carry the ROM's drawings and the MSX's VRAM map,
checked byte for byte.

And the block lists at 0x4861 **overlap on purpose**: event 0's starts at 0x4861
and event 2's at 0x4869, so the four events share entries two by two.

## The athlete's frames are a fifth of the cartridge

3,425 bytes, from 0x53EC to 0x614C, in 52 strips. The general decompressor never
touches them: DIBUJA_ATLETA reads them with one of its own (0x69FE) in which **the
top bit means the opposite** —set copies literals, clear repeats—, and which
pushes the bytes to the VDP port without going through the BIOS.

What proves the format is read right is not that the strips land on the end of
the block: starting at any byte they land there too. What proves it is the
measurement. A read watchpoint over the whole range records, besides the address,
**the PC that read it**: 0x69FE reads the counts, 0x6A09 the literals and 0x6A12
the byte to repeat. Of the 3,425 bytes, the MSX read 2,912 during the attract
sequence, and the role of all 2,912 matches the one the split assigns. Zero
discrepancies.

## The whole game is one interrupt

INIT falls into a dead `jr` at 0x40A4 and never returns. Every frame the
interrupt reads the state at 0xE000 and jumps through the handler table at
0x40C2; inside each handler the sub-state at 0xE001 drives the phases.

## Two different drawing interpreters

The cartridge stores scripts, not screens. 0x405E copies bytes into the name
table with destination jumps; 0x440D decompresses by runs into the pattern
table. Both write to VRAM through the same relocated `out (c),a` core at 0x4010.

## Two players sharing one state block

The current attempt runs on 0xE050. On a change of turn, 0x413E swaps the whole
block with 0xE080, so the rest of the code is written once and never has to ask
whose turn it is.

## It shares the sound player, and has no hidden mark

The three-channel sound player at 0x7C3D is the same framework Konami reused
across its MSX cartridges. And unlike some of the house's cartridges, this one
carries no hidden mark at the end of the ROM: the format Manuel Pazos
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) documented -the title in
katakana closed by a 0xAA- is not there. The last bytes are sound-player data.
