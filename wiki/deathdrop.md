# Death Drop

The death-drop system can create an item when a monster dies. A monster's custom keyvalues choose either a list from the map configuration or one explicit entity classname.

## Monster keyvalues

| Key | Purpose |
|---|---|
| `$s_deathdrop` | Name of a list in the `deathdrop` configuration, a dot-separated choice of list names, or a direct classname prefixed with `#`. |
| `$i_deathdrop` | Optional model attachment index. When present, the drop is placed at that attachment's origin and angles; otherwise it is placed at the monster's center. |

## Choose from a configured list

The list must exist in the `deathdrop` object in `scripts/maps/store/bts_rc.json`. The default configuration provides named lists (for example, `zhev`, `zscientist`, `Marine`, and `Medic`); list names are case-sensitive and are constrained by the configuration schema.

Example monster keyvalue:

```text
"$s_deathdrop" "zhev"
```

Example configuration shape:

```json
"deathdrop": {
    "active": true,
    "zhev": [
        "",
        "ammo_9mmAR",
        "grenade"
    ]
}
```

One entry is selected at random, with equal probability per array position. Repeated entries therefore increase that entry's chance. An empty-string entry is a chance to drop nothing.

To choose between lists, separate their names with periods:

```text
"$s_deathdrop" "zhev.Medic"
```

The system first chooses one of the named lists at random, then chooses an entry from that list. This is a choice between lists, not a combined weighted pool.

The special entry `"grenade"` creates a timed hand grenade. `"flashbang"` creates a timed flashbang.

## Spawn an explicit entity

Prefix a classname with `#` to bypass the configured lists:

```text
"$s_deathdrop" "#weapon_bts_m4"
```

This creates that entity directly. A `#` value is treated as the complete classname after the prefix; it cannot be combined with dot-separated list names. Entities referenced in configured lists are precached while the map loads. Direct `#` entities do not go through that list precache step, so ensure the classname is available and precached elsewhere.
