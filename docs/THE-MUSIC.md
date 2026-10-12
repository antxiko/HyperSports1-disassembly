# The music

Everything you hear here comes from running the cartridge's own sound engine (`ACTUALIZA_SONIDO`, 0x7C3D, and the request routine at 0x7B8F, which hands it the voices; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0x93, whole, 194 frames;
- tune 0x96, whole, 314 frames;
- tune 0x99, whole, 266 frames, just as the game asks for it.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

The routine at 0x7B8F takes the number in A (the one at 0x7B89 only sounds during a game, bit 6 of 0xE002). Numbers below 0x4D are effects; 0x4D to 0x92, two voices, and from 0x93 up, three. The voices take 11 bytes each from 0xE010 and 0xE043 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the table but no routine asks for them with an `ld a`. Names carrying an address are ones the listing has not named yet.

## The tunes

**The tune at 0x63CA** (0x93)

Asked for by `MOTOR_ATLETA_63CA`; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=1ceb4dc9"></audio>

**The measured-mark tune** (0x96)

Asked for by `MIDE_MARCA_6EB7`; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=67a891a4"></audio>

**The sign tune** (0x99)

Asked for by `ESTADO_ROTULO`: un rótulo con sonido y una espera; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=0ec2742d"></audio>

**A track in the table** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=38115eeb"></audio>

**Another track in the table** (0x94)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=a696ca68"></audio>

**A third track in the table** (0x95)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=894e1c90"></audio>

**A fourth track in the table** (0x97)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_97.mp3?v=6be29686"></audio>

**A fifth track in the table** (0x98)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_98.mp3?v=02a89370"></audio>

**A sixth track in the table** (0x9A)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_9A.mp3?v=6b7f622e"></audio>

**A seventh track in the table** (0x9B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_9B.mp3?v=243f1123"></audio>
