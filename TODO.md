# TO-DO List

This file contains the list of to-do in the project.

---

<!-- Python will insert the completion bar by finding the next comments.-->
## Completion Progress
<!--CompletionBar-start-->
> ![](https://geps.dev/progress/21.311475409836063?barColor=da630b)
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

- [ ] Remove all ``g_EngineFuncs.ModelIndex`` where applicable.
- [ ] Split weapons from the Firearms directory to new or existent folders like pistols/, rifles/
- [ ] Fix all angelscript warnings
- [ ] Optimize & simplify monster_parasite
- [ ] Optimize & simplify monster_snapbug
- [ ] Optimize & simplify monster_zombie_parasite
- [ ] Optimize & simplify scientists.as
- [ ] Optimize & simplify monster_zombie_gunner
- [ ] Optimize & simplify monster_zombie_grenadier
- [ ] Optimize item_tracker (Maybe Re-Implement partially the branch prototype view)
- [ ] Merge in player_voices into CCharacter [#37](https://github.com/Mikk155/bts_rc/issues/37)
- [ ] "*Hardcode*" deathdrop list names in schema as only what the map uses would work.
- [ ] Debug command to show and select a CCharacter.
- [ ] Move blood sprites from trace attacks to mikk/folder for reuse
- [ ] Move ascurl version checker code to a single file to use the preprocessor in the ``#include`` directive only.
- [ ] Create a IThrowable interface that enforces to set various variables and a Throw(IThrowable@) method for handling all the logic using the ASWeaponConfig defined variables with the IThrowable interface.
- [ ] **Flare / Flare Gun**: Fix projectile world model (currently invisible or stuck inside the world geometry).
- [ ] **Shotgun / Shotgun SD**: Fix bad bodygroups (`shotgunsd`).
- [ ] **Glock Auto/Semi**: Fix bad bodygroups (`glockf17`).
- [ ] **Uzi**: Add secondary attack to shoot a single bullet per click.
- [ ] **Uzi Silencer**: Review or implement behavior.
- [ ] **M16 & M16 with Grenade Launcher**: Fix secondary attack hold not playing the grenade loading animation.
- [ ] **M16 & M16 with Grenade Launcher**: Fix semi-to-full auto accuracy (make full-auto accuracy significantly worse).
- [ ] **M16 & M16 with Grenade Launcher**: Merge standard and silenced versions into a single class or use inheritance.
- [ ] **M16 Grenade Launcher Silencer**: Review or implement behavior.
- [ ] **SAW**: Fix bodygroup not updating after reload (they remain empty).
- [ ] **SAW**: Fix paused animation (missing the bullet-feeding animation from the original SAW).
- [ ] **Flamethrower**:  Fix bad view offset.
- [ ] **Flamethrower**:  Implement a class to set monsters on fire. [#87](https://github.com/Mikk155/bts_rc/issues/87)
- [ ] **Sniper Rifle**: Assign a different view model when using zoom. [#72](https://github.com/Mikk155/bts_rc/issues/72), [#87](https://github.com/Mikk155/bts_rc/issues/87)
- [ ] **Grenade**: Implement grenade roll as a secondary attack.
- [ ] **Crossbow**: Remove zoom after firing.
- [ ] **Crossbow**: Hide the view model when aiming down sights (ADS).
- [ ] **Iron Sights**: Implement to improve accuracy across weapons.
- [ ] **Grenade Launcher Iron Sight**: Add a drop trajectory/probability preview view.
- [ ] **357**: Implement laser spot.
- [ ] **357**: Disable firing while reloading.
- [ ] **Flashlight Weapon**: Fix ammo sprite bug (it has no primary ammo, but the sprite bugs out); change secondary ammo to primary using `BaseClass` calls.
- [ ] **Firearms**: Use a "miss" cooldown when there is no ammo.
- [ ] Restore the laser after reload finishes if it was active before.
- [ ] Make the laser activate automatically after the deploy phase finishes.
- [ ] **SetThink Weapons**: Purge old weapon thinks and transition to `BTS_Weapon` schedule callbacks.
- [ ] Flashlight/Laser shutdown on panthereye's freeze attack.
- [ ] Relocate the play sound of ``"bts_rc/fvox/ammowarning.wav"`` in low ammo grenade launcher to a composition namespace [#80](https://github.com/Mikk155/bts_rc/issues/80)
- [ ] Expose to JSON weapons rate of fire
- [ ] Expose to JSON weapons accuracy cone
- [ ] Expose to JSON melee weapon list of monsters that can be pushed (additional to headcrabs)

---

# Completed
<!-- Python will move the completed goals from above to here.--->
<!--CompletedGoals-start-->
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
