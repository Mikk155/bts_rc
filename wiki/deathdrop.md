# Death Drop

The death drop system allows any monster entity to drop items upon death, based on a unique per-monster key-value that targets either a specific item name or a more complex randomized list.

---

### Key Names

* `$s_deathdrop`

  * Defines a drop list name from the JSON configuration.

* `$i_deathdrop`

  * Defines the model attachment index used to spawn the item at a specific position and angle.
  * If unused, the item's position defaults to the monster's center.

---

### JSON Randomization Lists

If a monster contains:

```json
"$s_deathdrop" "medic"
```

It will drop one of the items defined under `"medic"` in the JSON:

```json
"medic":
[
    "item_bts_sprayaid",
    "item_healthkit"
],
```

Each entry in the list has an equal chance to spawn.
In this example, there are two entries, so each has a **50% chance**.

You can add new entries or modify existing ones within the `"deathdrop"` object context.

---

### Special Entry Names

In the JSON config, you can define special entity names with unique behaviors:

* `"grenade"`

  * Spawns a live hand grenade.

* `""` (empty string)

  * Represents a chance to drop nothing.

---

### Multi-List Chance

You can include multiple lists. For example:

```json
"$s_deathdrop" "zhev.medic"
```

The system will:

1. Select a random list.
2. Then select a random item from that list.

---

### Explicit Items

If the value of `$s_deathdrop` starts with `#`, it will bypass lists and spawn the specified entity directly.

Example:

```json
"$s_deathdrop" "#weapon_minigun"
```

This will spawn a minigun.

---

### ⚠️ NOTE

Using ``#`` is not compatible with ``.`` so whatever the key name starts with ``#`` that'd be the whole item name with no randomization at all.

If an entity entry is defined in the JSON, it will be **automatically precached**.

If you use `#`, make sure the entity is **already precached**.

> Weapon entities precache themselves automatically.
> This behavior may also apply to other item types depending on implementation.
