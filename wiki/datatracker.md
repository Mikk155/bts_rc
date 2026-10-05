The JSON object is formed with the player's Steam ID as key and contains a object with the next formats:

| Key name | Type | Example | Description
|---|---|---|--|
| classify | string | Security | name of classification |
| classify_index | int | 0 | classification index |
| model | string | bts_barney | name of model used |
| points | integer | 150 | points / frags. |
| name | string | Mikk155 | player name / netname |
| ended_at | integer | 1791159025 | time stamp in unix form when the player selected a class |
| joined_at | integer | 1791159025 | time stamp in unix form when the map ended |
| difficulty | integer | 3 | map difficulty, "Story mode" being zero and so on. |
| hellbound | boolean | false | map "hellbound" mode selected? |

Example:
```json
{
    "STEAM_0:0:202010794":
    {
        "classify_index": 3,
        "joined_at": 1791159296,
        "classify": "HEV",
        "name": "mikk",
        "model": "bts_helmet",
        "points": 0,
        "difficulty": 0,
        "hellbound": 0,
        "ended_at": 1791159296
    }
}
```
