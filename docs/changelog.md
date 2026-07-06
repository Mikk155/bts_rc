# Changelog

## [4.1.0] - 2026-07-06
### Added
- Integrated all remaining firearms, heavy weapons, utility weapons, and projectile entities into the new config-driven architecture (`ASWeaponConfig`, `BTS_Weapon`, `BTS_FireWeapon`).
- Customized M249 SAW belt lengths, Crossbow zoom HUD layouts, and Hand Grenade throwing velocity ranges.

### Optimized
- Swapped projectile trace beams, lights, and smokes for M79 rockets, hand flares, and flamethrower fire from map-wide broadcasts (`MSG_BROADCAST`) to Potentially Visible Set broadcasts (`MSG_PVS`).

### Removed
- Fully decoupled and disabled the old `bts_rc_weapons/` legacy scripts.
