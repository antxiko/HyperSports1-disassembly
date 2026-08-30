# Open questions

What the binary does not settle on its own:

- **Which routine drives which event.** The four events share a great deal of
  code: the same figure engine, the same judge, the same scoreboard. The names
  in the listing follow what each routine does; tying every motor to one of the
  four events by name would take a play-through with 0xE052 watched.
- **The melodies are not broken down.** The sound data at the end of the ROM is
  a tone table followed by the melodies; the player is understood, but each
  tune's notes are not transcribed here.
- **Full-screen rendering.** The website draws an event's figures and tiles from
  the ROM by running the run-length decompressor (0x440D) in Python; composing a
  whole event screen would also need the name-table interpreter (0x405E) and the
  per-event layout ported.
