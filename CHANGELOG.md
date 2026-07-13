
# 12/7/2026
- The website was updated to replace JavaScript scripts with TypeScript scripts for ease of use and maintenance.
- Updated & re-organization of various documentation structures.
- Added github wiki section in the project workspace for ease of use including a workflow to automate upload of wikipedia.
- Updated various instructions and general documentation to be more clear and concise.

# 6/7/2026
- Integrated all remaining firearms, heavy weapons, utility weapons, and projectile entities into the new config-driven architecture (`ASWeaponConfig`, `BTS_Weapon`, `BTS_FireWeapon`).
- Customized M249 SAW belt lengths, Crossbow zoom HUD layouts, and Hand Grenade throwing velocity ranges.
- Swapped projectile trace beams, lights, and smokes for M79 rockets, hand flares, and flamethrower fire from map-wide broadcasts (`MSG_BROADCAST`) to Potentially Visible Set broadcasts (`MSG_PVS`).

# 5/7/2026
- Ported weapon_bts_broom and weapon_bts_spanner to the new melee entity system.
- Ported weapon_bts_beretta to the new firearms entity system (BTS_FireWeapon / ASWeaponConfig).

# 30/6/2026
- Added various player models (Requires download from MEGA)

# 27/6/2026
- Rewrited panthereye with optimizations and expose multiple settings to json

# 23/5/2026
- Rewrited robogrunt soldier, robogrunt boss, engineer zombie and engineer grunt (Sentry spawner) to our new EntityOverriden system which brings strong optimizations.

# 15/6/2026
- Add github wiki
- Add documentation for the DeathDrop system

# 13/6/2026
- Fixed snark monsters spawning bouncy/floating blood puddles when killed.
- Configured a smaller custom blood puddle size for snark monsters.

# 9/6/2026
- Optimized death drop system.

# 26/5/2026
- Removed weapon_shockrifle from being equipable.
- Added a dynamic ammo system rather than randomization on pickup it will be based on the player count.

# 17/5/2026
- Updated logging system to use less cpu so it can be keept for release version.
- Updated json system to a more safe, stable and reliable system.
- Moved multiple hardcoded variables of various structures into json configuration.

# 6/5/2026
- Lowercase many asset files to prevent issues on Linux servers

# 5/5/2026
- Updated various structures to have default values in case json fails
- Headcrabs now are always detached even if they're dead
- Radiation damage will be reflected on the health for players not wearing a HEV/Hazard suit
- Hazard suit starts always at max armor
- Hazard suit always deduct 3 of armor every time is hit
- Hazard suit can now use wall chargers (fixed issue)
- Flashlight and night vision is locked while busy (reload, attack etc)

# 3/5/2026
- Added .clang.format support and global formater (Disabled for now due to lack of features)
- Moved laser sentry code to an optimized structure
- Added many custom monster updates by Nero
- Refactored and optimized many hook structures
- Allow admins to use impulse 101 regardless sv_cheats

# 27/4/2026
- Added weapon_bts_pipewrench (custom due to sk_plr_wrench not working.)
- Fixed flashlight being able to be toggled when busy (attack, reload etc)

# 26/4/2026
- Using weapons will now emit audible sounds to monsters. they can hear you!
- Added weapon_medkit replacement
- Added weapon_crowbar replacement
- Added env_commentary entity for developer commentary
- Fixed multiple null pointer issues
- Optimized multiple structures

# 17/4/2026
- Set up this website.

# 16/4/2026
- Reworked melee weapons
