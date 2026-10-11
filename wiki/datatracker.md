# Data Tracker
Data tracker allows server operators to track player data for their own purposes.

This feature is disabled by default but you can enable it in the json config.
```json
{
    "data_tracker":
    {
        "active": true
    }
}
```

When the context is active the map will generate a json file at ``scripts/maps/store/bts_rc_datatracker.json`` whenever the map is finished.

The JSON object is formed with the player's Steam ID as key and contains a object with the next formats:

| Key name | Type | Example | Description
|---|---|---|--|
| classify | string | Security | name of classification |
| classify_index | int | 0 | classification index |
| model | string | bts_barney | name of model used |
| points | integer | 150 | points / frags. |
| deaths | integer | 3 | deaths. |
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
    "BOT":
    {
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
