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

## Code shared with other Konami cartridges

This disassembly has been compared, instruction by instruction, with
every other Konami one in the series. A block counts when the same
instructions, at least six of them from a label to its `ret` or its
unconditional jump, are in both cartridges; the addresses are left
aside, because they change from one cartridge to the next. Of the
other 57, **42** have at least one block in common with this one;
these are the ones that share the most:

| Cartridge | Blocks | Instructions | For example (here = there) |
|---|---:|---:|---|
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/) | 25 | 341 | `MANEJADOR_DEMO` (0x44C9) = `atiende_el_menu` |
| [Circus Charlie](https://antxiko.github.io/CircusCharlie-disassembly/) | 21 | 276 | `MANEJADOR_DEMO` (0x44C9) = `atiende_el_menu` |
| [Cabbage Patch Kids](https://antxiko.github.io/CabbagePatchKids-disassembly/) | 17 | 210 | `LEE_TECLADO` (0x44A4) = `LEE_EL_TECLADO` |
| [Konami’s Mahjong Dojo](https://antxiko.github.io/KonamisMahjongDojo-disassembly/) | 15 | 186 | `SUMA_BONUS_7BE3` (0x7BE3) = `carga_los_canales` |
| [Comic Bakery](https://antxiko.github.io/ComicBakery-disassembly/) | 12 | 174 | `MANEJADOR_DEMO` (0x44C9) = `atiende_el_menu` |
| [Hyper Olympic 1](https://antxiko.github.io/HyperOlympic1-disassembly/) | 9 | 105 | `SUMA_BONUS_7BE3` (0x7BE3) = `MONTA_UN_CANAL` |
| [Hyper Olympic 2](https://antxiko.github.io/HyperOlympic2-disassembly/) | 9 | 105 | `SUMA_BONUS_7BE3` (0x7BE3) = `MONTA_UN_CANAL` |
| [Super Cobra](https://antxiko.github.io/SuperCobra-disassembly/) | 9 | 117 | `DESCOMPRIME_A_TERCIOS_4748` (0x4748) = `SUBE_LOGOTIPO` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/) | 7 | 88 | `LEE_TECLADO` (0x44A4) = `lee_teclado_1` |
| [Road Fighter](https://antxiko.github.io/RoadFighter-disassembly/) | 7 | 76 | `SUMA_BONUS_7C17` (0x7C17) = `enciende_o_apaga_canales` |

The whole matrix, the 58 cartridges against each other, is on
[The routines](https://antxiko.github.io/MSX-disassembly-database/THE-ROUTINES.html) in the series database, along
with the method and the program that measures it.
