## In-game `env_credits`

The game uses a separate file:
`scripts/maps/bts_rc/credits.json`
The scripted entity is implemented in
`scripts/maps/bts_rc/entities/env_credits.as`

Place an `env_credits` point entity in the map and trigger it. On activation,
the entity reads `bts_rc/credits.json` through the AngelScript JSON V1 parser,
creates the caption queue, and displays the captions using Sven Co-op HUD
messages. The entity is registered as a custom entity and is available in the
map FGD.

### Top-level settings

```json
{
    "fadetime": 2.0,
    "target": "targetname",
    "delay": 2.0,
    "captions": []
}
```

- `fadetime` is used as the initial delay before the first caption starts. The
  entity also uses it for the initial fade timing.
- `target` is the targetname fired after the initial delay.
- `delay` is the delay used when firing that top-level target.
- `captions` is the ordered list of messages to display.

The AngelScript JSON V1 parser requires values that are read as floats to be
written with a decimal point (`2.0`, not `2`). This is especially important
for timing, position, and scrolling values.

### Caption entries

Each item in `captions` can contain:

| Property | Type | Description |
|---|---|---|
| `message` | string | Text shown to players. Use `\n` for line breaks. |
| `scroll` | boolean | Selects scrolling mode. `false` uses a normal HUD caption. |
| `x`, `y` | float | HUD position for non-scrolling captions. `-1.0` centers the value. |
| `fadeintime` | float | Fade-in duration for non-scrolling captions. |
| `fadeouttime` | float | Fade-out duration for non-scrolling captions. |
| `holdtime` | float | Time a non-scrolling caption remains visible. |
| `fxtime` | float | HUD effect timing for non-scrolling captions. |
| `effect` | integer | HUD text effect for non-scrolling captions. |
| `rgb` | `[r, g, b]` | Primary text color. |
| `rgb2` | `[r, g, b]` | Secondary text color for non-scrolling captions. |
| `scroll_rate` | float | Vertical movement per update for scrolling captions. |
| `scroll_think` | float | Update interval for scrolling captions. |
| `target` | string | Entity targetname fired when this caption starts. |
| `delay` | float | Delay before firing `target`. |

### Inherited caption values

Caption settings are persistent. A value remains active for later captions
until that property is explicitly redefined. This allows a sequence to specify
common color or scrolling settings once.

The following values are cleared for each new caption instead of being
inherited:

- `message`
- `target`
- `delay`

For scrolling captions, position and timing values are updated dynamically by
the entity. Define `scroll: false` again to return to normal HUD captions.

Scrolling captions use up to four HUD channels. When a scrolling caption moves
far enough upward, the entity starts the next caption, allowing several
captions to be visible at once. A normal caption waits for its fade-in, hold,
and fade-out sequence before the next caption starts.
