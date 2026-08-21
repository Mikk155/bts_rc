# TO-DO List

This file contains the list of to-do in the project.

---

<!-- Python will insert the completion bar by finding the next comments.-->
## Completion Progress
<!--CompletionBar-start-->
> ![](https://geps.dev/progress/98.75?barColor=10da0b)
<!--CompletionBar-end-->

---

# Updating the file

> ## Please be organized when updating this file.
> - Add a prefix of "``- [ ] ``" to mark a goal.
> - Add a ``x`` inside it when a goal is completed "``- [x] ``"
> - Link to issues if applicable.
> - Each prefixed item is a goal and all the content in the next lines (If applicable) must go using the prefix "``    > ``" for example:
>   ```
>   - [x] Add new CCharacter "bts_scientist7"
>       > because of...
>   ```
> - Run ``src/main.py`` to generate roadmap graph and organize completion of goals.
---


---

# Completed
<!-- Python will move the completed goals from above to here.--->
<!--CompletedGoals-start-->
- [x] move to src/precaches.json models in the map that has the targetname "PRECACHE" and notify raptor.
- [x] Reimplement the whole hev fvox updates for hev characters (Update ASBullet::DeduceAmmo).
- [x] Add "active" checks to all loggers that may not have it.
- [x] Implement ASBullet to all fire arms.
- [x] Fix loggers with only one item in the array formating the message with an additional ``}`` not removed from the message.
- [x] Replace ASBullet's g_Engine.trace_* to g_Utility's GetGlobalTrace.
- [x] RegisterCommand rename class to ASCommand and create a method for RegisterCommand.
- [x] CommandContext should print help for specific commands in the argument 1 if it's a section i.e "bts_rc weapon" should print all commands in the weapon section.
- [x] Maybe reuse weapon melee distance configs into ASBullet
- [x] weapon json variable int[2] for default ammo min/max on spawn (clip ammo check)
- [x] weapon json variable int[2] for default secondary ammo min/max on spawn
- [x] replace all FireBullet( & FireBullets( to ASBullet pattern
- [x] Remove all ``g_EngineFuncs.ModelIndex`` where applicable.
- [x] Split weapons from the Firearms directory to new or existent folders like pistols/, rifles/
- [x] Optimize & simplify monster_zombie_parasite
- [x] Optimize & simplify monster_zombie_gunner
- [x] Merge in player_voices into CCharacter [#37](https://github.com/Mikk155/bts_rc/issues/37)
- [x] Debug command to show and select a CCharacter.
- [x] Create a IThrowable interface that enforces to set various variables and a Throw(IThrowable@) method for handling all the logic using the ASWeaponConfig defined variables with the IThrowable interface.
- [x] **Flare / Flare Gun**: Fix projectile world model (currently invisible or stuck inside the world geometry).
- [x] **Glock Auto/Semi**: Fix bad bodygroups (`glockf17`).
- [x] **Uzi**: Add secondary attack to shoot a single bullet per click.
- [x] **Uzi Silencer**: Review or implement behavior.
- [x] **M16 & M16 with Grenade Launcher**: Fix secondary attack hold not playing the grenade loading animation.
- [x] **M16 & M16 with Grenade Launcher**: Fix semi-to-full auto accuracy (make full-auto accuracy significantly worse).
- [x] **M16 & M16 with Grenade Launcher**: Merge standard and silenced versions into a single class or use inheritance.
- [x] **M16 Grenade Launcher Silencer**: Review or implement behavior.
- [x] **SAW**: Fix bodygroup not updating after reload (they remain empty).
- [x] **SAW**: Fix paused animation (missing the bullet-feeding animation from the original SAW).
- [x] **Flamethrower**:  Fix bad view offset.
- [x] **Flamethrower**:  Implement a class to set monsters on fire. [#87](https://github.com/Mikk155/bts_rc/issues/87)
- [x] **Sniper Rifle**: Assign a different view model when using zoom. [#72](https://github.com/Mikk155/bts_rc/issues/72), [#87](https://github.com/Mikk155/bts_rc/issues/87)
- [x] **Grenade**: Implement grenade roll as a secondary attack.
- [x] **Crossbow**: Remove zoom after firing.
- [x] **Crossbow**: Hide the view model when aiming down sights (ADS).
- [x] **Iron Sights**: Implement to improve accuracy across weapons.
- [x] **Grenade Launcher Iron Sight**: Add a drop trajectory/probability preview view.
- [x] **357**: Implement laser spot.
- [x] **357**: Disable firing while reloading.
- [x] **Flashlight Weapon**: Fix ammo sprite bug (it has no primary ammo, but the sprite bugs out); change secondary ammo to primary using `BaseClass` calls.
- [x] **Firearms**: Use a "miss" cooldown when there is no ammo.
- [x] Restore the laser after reload finishes if it was active before.
- [x] Make the laser activate automatically after the deploy phase finishes.
- [x] **SetThink Weapons**: Purge old weapon thinks and transition to `BTS_Weapon` schedule callbacks.
- [x] Flashlight/Laser shutdown on panthereye's freeze attack.
- [x] Relocate the play sound of ``"bts_rc/fvox/ammowarning.wav"`` in low ammo grenade launcher to a composition namespace [#80](https://github.com/Mikk155/bts_rc/issues/80)
- [x] Expose to JSON weapons rate of fire
- [x] Expose to JSON melee weapon list of monsters that can be pushed (additional to headcrabs)
- [x] make item tracking optional
- [x] add a command registry entry to test changing classification (Maybe CTextMenu?)
- [x] make medkit to not automatically recharge, only using health stations [#97](https://github.com/Mikk155/bts_rc/issues/97)
- [x] move player characters to default config
- [x] Expose to JSON remaining weapons accuracy cone
- [x] Optimize & simplify monster_parasite
- [x] Optimize & simplify monster_snapbug
- [x] Optimize & simplify scientists.as
- [x] Optimize & simplify monster_zombie_grenadier
- [x] Optimize item_tracker (Maybe Re-Implement partially the branch prototype view)
- [x] remove file name prefix to item_bts*
- [x] Make a helper for dynamic ammo returning default value if dynamic ammo is nullptr
- [x] Move ascurl version checker code to a single file to use the preprocessor in the ``#include`` directive only.
- [x] Fix all angelscript warnings
- [x] Expose to JSON weapons accuracy cone
- [x] "*Hardcode*" deathdrop list names in schema as only what the map uses would work.
- [x] Move blood sprites from trace attacks to mikk/folder for reuse
- [x] **Shotgun / Shotgun SD**: Fix bad bodygroups (`shotgunsd`).
- [x] **Bad hands group**: Fix or update hands model/rig.
- [x] flare **Bad hands group**: Fix or update hands model/rig.
- [x] shotgun **Bad hands group**: Fix or update hands model/rig.
- [x] uzi silencer **Bad hands group**: Fix or update hands model/rig.
- [x] glock auto/semi **Bad hands group**: Fix or update hands model/rig.
- [x] m16 glauncher silencer **Bad hands group**: Fix or update hands model/rig.
- [x] m16 glauncher **Bad hands group**: Fix or update hands model/rig.
- [x] **Bodygroup Hack**: Remove the two duplicate bodygroup hacks located in `ASWeaponConfig::PlayerThink` and `WeaponOverrider`.
- [x] Remove weapon_bts_ prefix from angelscript files
- [x] move repeated precache calls into precaches.json and maybe have a python check to find precaches in the scripts based if they exists in precaches.json to warn the user to remove their added calls as these assets are always precached.
- [x] Reimplement item mapping

---
