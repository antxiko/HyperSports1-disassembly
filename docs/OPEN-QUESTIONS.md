# Open questions

What the binary does not settle on its own:

- **The melodies are not broken down.** The sound data at the end of the ROM is
  a tone table followed by the melodies; the player is understood, but each
  tune's notes are not transcribed here.
- **The athlete's frames, one by one.** Where they live (0x53EC-0x614C), how they
  decompress and how many strips each event uses are all known, but they are not
  drawn individually on this site: DIBUJA_ATLETA lays each strip across the
  pattern table at a destination derived from the position and the state of the
  attempt, so pulling a single figure out would mean reproducing that layout.
  They can be seen assembled in the scenes.
- **Eleven strips nobody touches.** Of the 52 in the pose block, eleven are read
  by no event across the 230 measured seconds of attract mode. They may only
  show up in a real game —the attract fails no attempt and never reaches the
  later stages— or they may be dead frames. Not checked by playing.
- **What the step table at 0x6F9C is for.** Eight 16-bit values, one per rung of
  the score, which 0x6F8B adds to the coordinate at 0xE101; the first is
  negative. What the routine does is known; what the jump is for is not.
