# Player Data Tracker

The data tracker records a small set of player and run statistics. It is disabled by default in the supplied configuration.

Enable it in `scripts/maps/store/bts_rc.json`:

```json
{
    "data_tracker": {
        "active": true
    }
}
```

At the end of the simulation, the tracker writes `scripts/maps/store/bts_rc_datatracker.json`. The top-level object is keyed by the player's Steam ID; bots use the key `"BOT"`.

| Field | Type | Meaning |
|---|---|---|
| `name` | string | Player name when the run ends. |
| `model` | string | Character model name, such as `bts_barney`. |
| `classify` | string | Character classification name. |
| `classify_index` | integer | Numeric classification value. |
| `points` | integer | Player frags/points at the end of the run. |
| `deaths` | integer | Player death count at the end of the run. |
| `joined_at` | integer | Unix timestamp recorded when the player first selects a class. |
| `ended_at` | integer | Unix timestamp recorded when the tracker processes the run's ending. |
| `difficulty` | integer | Difficulty value: Story Mode `0`, Relaxed `1`, Medium `2`, Punished `3`, Tortured Standard `4`, or Tortured Legacy `5`. |
| `hellbound` | boolean | Whether Hellbound mode was enabled for the run. |

Example:

```json
{
    "STEAM_0:1:123456": {
        "joined_at": 1791225472,
        "classify_index": 4,
        "points": 1,
        "name": "mikk",
        "model": "bts_cleansuit",
        "ended_at": 1791225600,
        "classify": "Hazard",
        "difficulty": 0,
        "hellbound": 0,
        "deaths": 0
    },
    "BOT": {
        "joined_at": 1791225472,
        "classify_index": 1,
        "points": -1,
        "name": "Sniper",
        "model": "bts_scientist6",
        "ended_at": 1791225600,
        "classify": "Scientist",
        "difficulty": 0,
        "hellbound": 0,
        "deaths": 1
    }
}
```

> Note if you're not going to use a json library mind you the final result is not that pretty, it is a single line without any spaces. i.e
> ```json
> {"STEAM_0:0:202010794":{"joined_at":1791225472,"classify_index":4,"points":1,"name":"mikk","model":"bts_cleansuit","ended_at":1791225600,"classify":"Hazard","difficulty":0,"hellbound":0,"deaths":0},"BOT":{"joined_at":1791225472,"classify_index":1,"points":-1,"name":"Sniper","model":"bts_scientist6","ended_at":1791225600,"classify":"Scientist","difficulty":0,"hellbound":0,"deaths":1}}
> ```


Players who join after the simulation has started may not have a tracker record; they are skipped when the run is written,
