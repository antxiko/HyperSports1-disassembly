# The game

Hyper Sports 1 is the gymnastics-and-diving half of Konami's Hyper Sports,
converted to the MSX. It has **four events**, and the order they are played in
comes from the four-pointer table at 0x6F00, which 0x6E38 indexes with
`0xE052 and 3`:

| `0xE052 and 3` | event | label script |
|---|---|---|
| 0 | DIVING (springboard) | 0x6F08 |
| 1 | LONG HORSE | 0x6F1E |
| 2 | TRAMPOLINE | 0x6F11 |
| 3 | HORIZONTAL BAR | 0x6F2B |

The texts, on the other hand, sit back to back from 0x6F08 in a different order:
DIVING, TRAMPOLINE, LONG HORSE, HORIZONTAL BAR. Anyone reading the texts instead
of the table gets **the second and the third swapped**.

0xE052 is not reset between rounds: it keeps climbing, and the event comes from
its two low bits, so the fifth is DIVING again with `STAGE` gone up.

## The four screens

These five images are not screenshots. The drawings —patterns and colours— come
from the ROM, decompressed with the same format the Z80 runs at 0x440D; the tile
map and the sprites come from the MSX's VRAM, because **an event's screen is
stored nowhere in the cartridge**: DIBUJA_MARCO (0x4816) only uploads the
drawings, and the map is composed by the engine as it runs.

Before drawing anything, `tools/escenas.py` checks what it pulls from the ROM
against that VRAM. Across the five scenes: **0 differing bytes**.

![DIVING, the springboard](imagenes/prueba_palanca.png)

![DIVING, entering the water](imagenes/prueba_palanca_agua.png)

![LONG HORSE, the run-up](imagenes/prueba_potro.png)

![TRAMPOLINE, the bounce](imagenes/prueba_trampolin.png)

![HORIZONTAL BAR, the swing](imagenes/prueba_barra.png)

Of the four, only TRAMPOLINE has a `TIME` readout: its label script (0x4560) is
the only one that writes that word, and it is dumped for that event alone.

## Taking turns

Two players play in turn. The state of the current attempt lives at 0xE050 for
player 1 and at 0xE080 for player 2; when the turn changes, 0x413E swaps the two
blocks whole, so the rest of the code never has to know whose go it is. The word
QUALIFY, drawn from the label at 0x6F45, marks passing to the next round.

## An attempt

Each event is a run-up or a wind-up, a jump or a routine, and a judged result.
The athlete's figure is assembled from tiles and sprites and uploaded each frame;
the judge (0x7859) scores the attempt and decides whether it qualifies, and a
bonus (0x7ABE) is added at the end.

## The athlete's frames

The athlete's drawings are 3,425 bytes —a fifth of the cartridge— in the block
from 0x53EC to 0x614C, cut into **52 strips**. The general decompressor never
touches them: DIBUJA_ATLETA reads them with one of its own (0x69FE), in which the
top bit means the opposite, and which pushes the bytes to the VDP port without
going through the BIOS.

Measuring in openMSX which addresses each event reads over the whole attract
sequence —679,198 reads in 230 emulated seconds— gives the split:

| event | strips touched |
|---|---|
| DIVING | 20 |
| LONG HORSE | 30 |
| TRAMPOLINE | 13 |
| HORIZONTAL BAR | 30 |

Nine strips are used by all four events, seven belong to HORIZONTAL BAR alone,
three to DIVING alone, and eleven are touched by nobody in the attract mode.

## The swimsuit

Every one of the 45 poses has at least four sprite entries, and in the eighteen
the pool uses the first four are the athlete: the red shirt and the white boots
in the first two, the two yellows —torso and legs— in the next two. On the MSX1
the lowest-numbered sprite is drawn on top, so wherever those poses appear in
another event the shirt and the boots show.

In DIVING, and only there, 0x63E8 swaps the two pairs after the buffer is built
—INTERCAMBIA moves eight bytes between 0xE0D0 and 0xE0D8— and pins the pattern
numbers back to 8, 12, 0 and 4, so each entry keeps its drawing but changes
plane: the two yellows come to the front and cover the red and the white. Same
script, same drawings, and the athlete dives in a swimsuit. The eighteen poses
the pool uses —0 to 17— all go through it; the fifth and sixth entries, when a
pose has them, are left where they were. theNestruo saw it playing and asked
for it in issue #2.

The emulator confirms it: in the VRAM dump of the pool at 29.5 s the athlete
is pose 17 with six entries, and sprites 10 to 13 read yellow (pattern 8),
yellow (12), red (0), white (4) — the swapped order. Drawing the athlete from
that dump and from the ROM with the swap applied gives the same pixels; the
other three dumps with an athlete on screen (horse, trampoline, bar) match the
ROM without the swap. A test keeps it that way.
