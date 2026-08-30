# The game

Hyper Sports 1 is the gymnastics-and-diving half of Konami's Hyper Sports,
converted to the MSX. It has **four events**, and their labels are written into
the ROM at 0x6EED: DIVING, TRAMPOLINE, HORSE (the long horse) and HORIZONTAL
(the horizontal bar).

## Taking turns

Two players play in turn. The state of the current attempt lives at 0xE050 for
player 1 and at 0xE080 for player 2; when the turn changes, 0x413E swaps the two
blocks whole, so the rest of the code never has to know whose go it is. The word
QUALIFY, drawn from the label at 0x6F47, marks passing to the next round.

## An attempt

Each event is a run-up or a wind-up, a jump or a routine, and a judged result.
The athlete's figure is assembled from tiles and sprites and uploaded each frame;
the judge (0x7859) scores the attempt and decides whether it qualifies, and a
bonus (0x7ABE) is added at the end.
