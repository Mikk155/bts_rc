funcdef void WeaponOverriderCallback( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character );

dictionary gpWeaponsOverride;

class WeaponOverrider
{
    private ASWeaponConfig@ m_Owner;
    const ASWeaponConfig@ get_Owner() const {
        return @this.m_Owner;
    }

    const string& get_classname() {
        return this.m_Owner.Name;
    }

    WeaponOverrider() {}

    WeaponOverrider( ASWeaponConfig@ owner )
    {
        @this.m_Owner = owner;
        @gpWeaponsOverride[ this.m_Owner.Name ] = this;
    }

    WeaponOverriderCallback@ PlayerThink;
    WeaponOverrider@ SetPlayerThink( WeaponOverriderCallback@ callback ) {
        @this.PlayerThink = callback;
        return this;
    }

    WeaponOverriderCallback@ WeaponDeploy;
    WeaponOverrider@ SetWeaponDeploy( WeaponOverriderCallback@ callback ) {
        @this.WeaponDeploy = callback;
        return this;
    }
}
