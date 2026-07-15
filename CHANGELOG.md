# 14/07/2026
## Scripts
- Fixed the standalone flashlight remaining active after switching or dropping it and prevented interrupted battery reloads from granting a full charge.
- Corrected M4 and suppressed M4 animation sequences for fire-mode changes, reloads, draws, firing, and idles.
- Fix panthereye pushing non-character targets. (i.e doors)

## Pages
- Fixed and improved the changelog section.

## Map
### Intro
- added jpolito voiceline for Intro dialog
- added ooleg voiceline for intro barney
- added yomustdie voicelines to scientist
- added PJC_ voiceline for Dr Keller Replacement
- added yomustdie for hologram replacement
- added new indication for hellbound button
- added four-nines music for intro and loading area
- added ryors model for the weapon display
- added otis sd with helmet model for intro
- added skip button for intro sequence
- added new geometry to help the map feel more blackmesa

### area 1
- added new geometry to tram station help the map feel more blackmesa
- added new layout for dorms lobby
- updated dorms signs
- added additional cameras for dorms
- added hecu/blops insertion point into cafeteria
- added emergency access button to maintenance shaft for cafeteria shutter
- added additional lockers to dorms personnel facilities
- added scientist telefrag scene
- added ventilation shaft between turbine research and ventilation junction
- added gear location randomiser between area 1 and 4 on higher difficulties
- added additional details to flesh out lab a little better
- added better geometry between dorms east wing and personnel facilities
- added grunt warning sound to the grounds breaching
- added scientist survivor to dorms west wing
- added corridor to library to dorms west wing
- added extension to cafeteria kitchen + shutter for kingpin protection
- added better randomiser for hazard selecton
- added button to maintenance shaft entrance to avoid npcs openning
- added better handling of the retina scanner at the tram station
- added ventilation between stairwell and ventilation junction
- added ammunition and supplies to A-105
- added ryors skins to keycards
- added timetable in dorms lobby for detail
- added better lighting to airlock
- added detailing to shelf models
- added sequence to both security doors for military to breach the door
- added new requirement for tentacle sound
- added food trays and paper to the cafeteria details
- added pots for the kitchen detailing
- added higher fps rate for steam to look more realistic
- wall signage added for better navigation

### Area 2
- expanded truckbay area 1
- expanded elevator lobby
- expanded warehouse 3
- added overhead ventilation connecting to stair well, manual doors and warehouse 1
- added additional entrance to warehouse 1
- added corridor to yard managers office
- added maintenance worker who explains about the generator and keycard
- added better generator model
- added additional detailing
- added catwalk around warehouse 1
- added better detailing to surface location
- added osprey landing sequence as a warning for military
- adjusted lighting for warehouse 1
- added ventilation shaft between corridor and elevator lobby
- fixed barnacle issue
- added additional details to warehouse junction
- added gargantua sequence
- added breakable boxes counters for more realistic breaking
- added refill crate to warehouse 1 and 2
- added gargantua event to warehouse 1 and 2
- fixed ramp issue warehouse 1
- moved m2 emplacement from warehouse 2 to 1
- fixed radio positions
- added radio dialog
- added shutter to security office at manual doors
- added dialog for scientist and barney
- fixed truck ambush truck glitching
- fixed navigation as per 5.27
- expanded stairwlel for better navigation as per 5.27
- optimisation done around the map via clipping, hull2 and skip/noclip

### area 3
- moved armoury keycard to canal
- added water access for canal
- added better generator model
- moved zapping hazaard to generator room as per water
- better navigation as per 5.27
- fixed elevator with sparks method
- added construction with custom dialog
- removed slops and replaced with stairs for better navigation as per 5.27
- added additional power cell to basement next to maintenance office
- added maintenance worker dialog explaining keycard locations
- added security office for elevator repair
- added 50/50 chance for zombie on the elevator
- added zombie dying and background shots to explain the maintenance worker death
- power generator required to activate the final bridge now
- alarm sound added for when the bridge gearbox is repaired
- moved around the crates in the acid to be more varied
- overhead crate now blocks the bridge when generator power is not activated
- removed doors for better navigation as per 5.27
- fixed catwalk width on vehicle overpass
- added security office to vehicle overpass
- added ladder with security gate similar to opposing force
- added speed changevalve for elevator, faster speed on lower dif, slower on higher dif
- maintenance worker added to vehicle overpass
- trucks moved to avoid stuck issues with npcs
- trigger master added to have better triggering methods
- added additional cover to the corridor leading to area 4
- signage added for area 3
- HECU given geometry change, elevator by security office for additional breach
- Enforcer boss fight location changed
- Blackops given additional fassn's
- Blackop Gonomes and zombies added to basement
- Sandbag and sentry positions added to basement
- Cleansuit vista fixed, acid slowly rises over time
- flare ammo moved to better location
- barnacles adjusted slightly
- better node placements for better navigation as per 5.27
- doors made wider for better navigation as per 5.27

### area 4
- signage added for better navigation
- wall signage added for better navigation
- chemical lobby adjusted slightly
- storage spawn at personnel facilities moved to chemical lobby
- storage closet added in chemical lab requiring explosives or scientist
- chemical lab warning sound added
- better node placements for better navigation as per 5.27
- additional lockers added to perosnnel facilities at both sides of area 4
- restroom overhaul
- armoury doors, room 2 - slightly changed for better navigation as per 5.27
- better detail to why the door is dented
- armoury lobby overhaul
- armoury firing range overhaul
- armoury door added with keycard reuqired on tortured
- tram failure added
- tram station has now got a power box that needs repaired to fix tram
- elevator openning changed
- added additional path between armoury doors and chemical lobby
- flamethrower or m79 added to secret locker room
- lockdown lights added to various areas along with alarm sounds
- grunt warnings added to area 4 breach
- additional military sequences added
- fixed 'override ai' sequences
- fixed breaching sequences
- added zombie gunners to higher diffiuclties in the armoury doors
- additional vent added to security office storage between area 5 vent junction and warehouse
- server room explosion adjusted
- gonome throw moved from chemical lab to another location
- gonome window jump fixed and adjusted
- sentry and turret spots adjusted
- scientist added explaining where the keycard is
- scientist added explaining the turret issue in armoury doors
- overhauled elevator
- lockdown updates sounds in area 1 and 4
- lockdown dialog given to grunts

### Area 5
- will fill this out later

### Misc
- will fill this out later

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
