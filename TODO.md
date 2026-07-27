# TO-DO List

## Please be organized when updating this file.

- Add a prefix of "``- [ ] ``" to mark a goal.
- Add a ``x`` inside it when a goal is completed "``- [x] ``"
- Link to issues if applicable.
- Each prefixed item is a goal and all the content in the next lines will be considered part of it.
- Run ``src/main.py`` to generate roadmap graph and organize completion of goals.

---
<!--CompletionBar-start-->
## Completion: ![](https://geps.dev/progress/2.564102564102564?barColor=da160b)>
<!--CompletionBar-end-->
---

- [ ] Debug command to show and select a CCharacter.
- [ ] Reimplement item mapping
- [ ] **Bad hands group**: Fix or update hands model/rig.
- [ ] flare **Bad hands group**: Fix or update hands model/rig.
- [ ] shotgun **Bad hands group**: Fix or update hands model/rig.
- [ ] uzi silencer **Bad hands group**: Fix or update hands model/rig.
- [ ] glock auto/semi **Bad hands group**: Fix or update hands model/rig.
- [ ] m16 glauncher silencer **Bad hands group**: Fix or update hands model/rig.
- [ ] m16 glauncher **Bad hands group**: Fix or update hands model/rig.
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
- [ ] **Bodygroup Hack**: Remove the two duplicate bodygroup hacks located in `ASWeaponConfig::PlayerThink` and `WeaponOverrider`.
- [ ] Flashlight/Laser shutdown on panthereye's freeze attack.
