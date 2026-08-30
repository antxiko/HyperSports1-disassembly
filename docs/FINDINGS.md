# Findings

## The four events are written into the ROM

Their labels, at 0x6EED, read DIVING, TRAMPOLINE, HORSE and HORIZONTAL: the
gymnastics-and-diving set of Hyper Sports, in the first cartridge of the MSX
conversion. The game is played in turns, and the word QUALIFY (0x6F47) marks
passing to the next round.

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
