# bts_rc

### Scripts used for the Sven Co-op map "[Black-Mesa training simulation: Resonance cascade](http://scmapdb.wikidot.com/map:blackmesa-training-simulation:resonance-cascade)"

#### You are free to use, copy, modify, merge, publish, distribute and even sell copies of these codes under the following conditions:

- A link to this project should be added in your source

- Credits for the responsibles creators and contributors should be noticed in your source. These are usually on the Header of the scripts.

---

# Cvars

- ``as_command bts_rc_disable_bloodpuddles`` (value)
    - ``1``
        - Disables blood puddles entirely
    - ``0``
        - Generate blood puddles when possible. Default.

- ``as_command bts_rc_disable_player_voices`` (value)
    - ``1``
        - Disables player voices entirely
    - ``0``
        - Player does voice responses to game events. Default.

- ``as_command bts_rc_disable_sentry_laser`` (value)
    - ``1``
        - Disables sentry and turrets from having laser indicators
    - ``0``
        - Sentry and turrets have laser indicators. Default.

- ``as_command bts_rc_disable_sparks`` (value)
    - ``1``
        - Disables armored monsters from droping visual Sparks effects.
    - ``0``
        - Armored monsters drops visual Sparks effects on getting damage. Default.

- ``as_command bts_rc_disable_bloodsplash`` (value)
    - ``1``
        - Disables armored monsters from droping visual Blood effects.
    - ``0``
        - Armored monsters drops visual Blood effects on getting damage. Default.

---

### General credits:
| Contributor | Description |
|---|---|
| [AraseFiq](https://github.com/AraseFiq) | Script general and initial idea for these | features
| [Mikk155](https://github.com/Mikk155) | Various |
| [Rizulix](https://github.com/Rizulix) | Weapons, Item tracker |
| [Gaftherman](https://github.com/Gaftherman) | Item tracker, medkit |
| [KernCore](https://github.com/KernCore91) | Various code references |
| [Nero0](https://github.com/Neyami) | Various code references |
| [Solokiller](https://github.com/SamVanheer) | Help Support |
| [H²](https://github.com/h2whoa) | Help Support |
| [Zode](https://github.com/Zode) | Utility [freeedicts](scripts/maps/bts_rc/utils/main.as) |
| [Giegue](https://github.com/JulianR0) | [Motd NetworkMessage](scripts/maps/bts_rc/gamemodes/item_tracker.as), [func_recharge](scripts/maps/bts_rc/entities/func_bts_recharger.as) |
