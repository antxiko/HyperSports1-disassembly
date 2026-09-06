# In the emulator

The listing and every number on this site come from the binary and are
reproducible with `make`. Nothing here was measured by eye.

## Running it

    openmsx -machine Philips_VG_8020 -cart hypersports1.rom

An MSX1 machine is enough; the cartridge maps into page 1 and drives everything
from the frame interrupt.

## What can be measured

To confirm a state or a timing, put a breakpoint and watch the RAM the notes
name: 0xE000 is the main state, 0xE052 the event, 0xE054 the attempts left. The
per-frame cost of a routine is the difference of `machine_info time` between a
breakpoint at its entry and one at its `ret`, times 3579545 for Z80 cycles.

Output paths in any Tcl script must be Windows paths, never `/tmp`.

## The two scripts in this repository

`make vram` runs both. Neither needs anyone to play: the attract mode plays all
four events on its own from power-on, and it is **deterministic** —two
independent runs give byte-identical dumps.

- `tools/omsx_escenas.tcl` waits for each scene's recorded second and dumps the
  16 KB of VRAM, plus the 384 bytes of the BIOS font that 0x43BF copies. That is
  where the five `.vram` files in `src/vram` come from: the tile map behind this
  site's images.
- `tools/omsx_posturas.tcl` puts a read watchpoint over the athlete's frame block
  and records, per event, which addresses are read and **from which PC**. That
  gives the strips each event uses and checks the format: 679,198 reads in 230
  emulated seconds, with 11,463 passes through 0x0038 as a control.

## What does NOT work: screenshots

openMSX's `screenshot` **lags behind the Tcl script**, and does not match the
VRAM read of the same instant. Checked twice, and with the machine paused too:
asking for the trampoline scene produced the previous event's screen, and asking
for the horizontal bar produced the start-up logo. VRAM, read synchronously with
`debug read_block`, is from the instant asked for, and that is why this site's
images are drawn from it and from the ROM, never from a capture.
