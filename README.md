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

---

# Developer mode

These scripts does use of preproccesors for testing purposes
```C#
#if DEVELOP
    CLogger@ m_Logger = CLogger( "Randomizer" );
#endif

void myfn()
{
    ...

    #if DEVELOP
        m_Logger.debug( "{}: \"{}\" Swap position to {}", { name, ent_name, pRandomizer.GetOrigin().ToString() } );
    #endif
}
```

Sadly in AngelScript We can not define them.
```C#
#define DEVELOP
```
This doesn't work.

So to enable [loggers](scripts/maps/bts_rc/utils/Logger.as) and other features find all "``#if DEVELOP``" in the project with Visual studio code (or any IDE) and replace to "``#if SERVER``"

---

### General credits:
| Contributor | Description |
|---|---|
| [AraseFiq](https://github.com/AraseFiq) | Script general and initial idea for these | features
| [Mikk155](https://github.com/Mikk155) | Various |
| [Rizulix](https://github.com/Rizulix) | Weapons, Item tracker |
| [Gaftherman](https://github.com/Gaftherman) | Item tracker |
| [KernCore](https://github.com/KernCore91) | Various code references |
| [Nero0](https://github.com/Neyami) | Various code references |
| [Solokiller](https://github.com/SamVanheer) | Help Support |
| [H²](https://github.com/h2whoa) | Help Support |
| [Zode](https://github.com/Zode) | Utility [freeedicts](scripts/maps/bts_rc/utils/main.as) |
| Adambean | [Objetive indicator](scripts/maps/bts_rc/objective_indicator.as) |
| Hezus | [Objetive indicator](scripts/maps/bts_rc/objective_indicator.as) |
| GeckoN | [Objetive indicator](scripts/maps/bts_rc/objective_indicator.as) |