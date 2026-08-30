# Hyper Sports 1 (Konami, RC-715) — commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the write-up →](https://antxiko.github.io/HyperSports1-disassembly/)**
· [En castellano](README.es.md)

    make            # trace, generate the listing, reassemble it and run the tests
    make verify     # the test that decides: reassembling has to give the ROM back
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuild the website

The ROM is **not distributed here**. It goes in the root as `hypersports1.rom`,
16384 bytes, sha256

    440dae57676a98b5a3dd29f3e97b9c83a8cbe58a3d3f2172c6072d07e6f00754

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100 %) |
| traced code | 5,953 bytes, 3,177 instructions |
| identified data | 10,431 bytes in 35 named ranges |
| commented | 491 line comments, 15.5 % |
| thin routines (under 10 %) | 0 of 386 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` file holds:

| | |
|---|---|
| named labels | 387 |
| anchored comments | 479 |
| explained data ranges | 35 |

## What is in here

- `src/hypersports1.asm` — the listing; generated, not hand-edited
- `src/hypersports1.notes` — the annotations, anchored to addresses
- `src/hypersports1.entries` — the entry points, each one justified
- `docs/` — the website, in English and Spanish
- `tools/` — the tracer, the listing generator, the data walkers and the
  run-length decompressor that draws the website's pictures from the ROM

## The write-up

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | four gymnastics-and-diving events, two players |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the memory map and the screen |
| [The code](docs/THE-CODE.md) | the state machine, the two interpreters and the sound |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what can be measured, and how |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is still not settled |

See `LEGAL-NOTICE.md`.
