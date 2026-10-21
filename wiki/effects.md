# Monster Impact Effects

These custom keyvalues control visual effects associated with monsters. Add them to a monster entity or to a `monster_*` squadmaker, whose keyvalues are passed to its spawned monsters.

## `$i_spark_color`

Sets the color index used for sparks when a player weapon hits the monster. Valid values are `0` through `11`, corresponding to the first 12 colors in [Engine Color Palette #2](https://raw.githubusercontent.com/wiki/baso88/SC_AngelScript/images/engine_palette_2.png). The `weapons.sparks_splash` option must be enabled; it is enabled in the default configuration.

![Engine Color Palette #2](https://raw.githubusercontent.com/wiki/baso88/SC_AngelScript/images/engine_palette_2.png)

Optionally set `$i_spark_hitgroup` to limit the override to one hitgroup. If omitted, the color applies to any hitgroup.

```text
"$i_spark_color" "5"
"$i_spark_hitgroup" "10"
```

## `$i_bloodcolor`

Sets the palette index for the custom blood effect sent when a player weapon hits the monster. Values from `0` through `255` are accepted and refer to [Engine Color Palette #1](https://raw.githubusercontent.com/wiki/baso88/SC_AngelScript/images/engine_palette_1.png).

![Engine Color Palette #1](https://raw.githubusercontent.com/wiki/baso88/SC_AngelScript/images/engine_palette_1.png)

```text
"$i_bloodcolor" "194"
```

The map FGD describes this key as disabling vanilla blood. The script sends a custom blood message when the monster is hit; it does not change the monster's configured blood color or the separately configured blood-splash sprites.

## `$i_puddleskin`

Selects the skin index of the custom `models/bts_rc/monsters/bloodpuddle.mdl` model used for blood puddles created when a monster dies. It is a model skin index, **not** an index in either engine color palette above. The script applies the supplied integer directly to the puddle model; for example, the Robo Grunt uses skin `3`. A monster with green/yellow blood defaults to puddle skin `1` unless `$i_puddleskin` overrides it.

There is no blood-puddle skin reference image in this wiki or the editor definitions. Check the model's available skins in your model viewer when choosing an index.

```text
"$i_puddleskin" "3"
```
