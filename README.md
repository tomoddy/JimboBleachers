# Jimbo Bleachers

A Balatro mod that stacks your Jokers into rows once you have more than 10.

<img src="assets/2x/modicon.png" width="48" align="center"> 

## How it works

- Up to 10 Jokers: normal single row.
- 11 or more: Jokers split into `ceil(jokers / 10)` rows, spread evenly with any extra on the top rows.

| Jokers | Rows | Layout | Card size |
|-------:|-----:|--------|----------:|
| 11 | 2 | 6 + 5 | 1/2 |
| 20 | 2 | 10 + 10 | 1/2 |
| 21 | 3 | 7 + 7 + 7 | 1/3 |
| 25 | 3 | 9 + 8 + 8 | 1/3 |

- Jokers trigger in reading order: top row left to right, then the next row down. This is the game's normal order, so scoring is unchanged.
- Drag a Joker into another row to move it there in the order.
- Rows are based on Jokers held, not Joker slots.

## Install

Requires [Steamodded](https://github.com/Steamodded/smods) (1.0.0 beta or later).

Copy the `JimboBleachers` folder into `%AppData%\Balatro\Mods` and restart the game.

## Testing

With [DebugPlus](https://github.com/WilsontheWolf/DebugPlus), open the console with `/` during a run:

```
eval for i = 1, 12 do SMODS.add_card({ set = "Joker" }) end   -- add 12 random Jokers
eval G.jokers:change_size(20)                                    -- add 20 Joker slots
```
