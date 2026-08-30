# Getting started

A commented disassembly of **Hyper Sports 1**, Konami's RC-715 for the MSX, a
16 KB cartridge that maps into page 1 (0x4000-0x7FFF). It reassembles into the
exact ROM, byte for byte, and every one of its 16,384 bytes is accounted for.

## The cartridge is not here

No repository ships the game. Put your own dump in the root as
`hypersports1.rom`, 16384 bytes, sha256

    440dae57676a98b5a3dd29f3e97b9c83a8cbe58a3d3f2172c6072d07e6f00754

`make comprueba` checks it.

## What each command does

    make            trace the flow, build the listing, reassemble it, run the tests
    make verify     the test that decides: reassembling has to give the ROM back
    make sanity     that not one byte is left unexplained, and no data reads as code
    make densidad   how much is commented, routine by routine
    make web        rebuild this website from the ROM and the notes

## How it is put together

The listing is not hand-edited: `tools/mkasm.py` builds it from a flow trace and
a file of notes anchored to addresses, so the comments survive a re-trace. The
tracer follows the flow from the entry points; the ones it cannot deduce on its
own -the interrupt hook and the inline jump tables- are declared in
`src/hypersports1.entries`, each with its reason.
