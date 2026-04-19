funcdef void WeaponOverriderCallback( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character );

dictionary gpWeaponsOverride;

class WeaponOverrider
{
    private ASWeaponConfig@ m_Owner;
    const ASWeaponConfig@ get_Owner() const {
        return @this.m_Owner;
    }

    private string m_Classname;
    const string& get_classname() {
        return this.m_Owner.Name;
    }

    WeaponOverrider() {}

    WeaponOverrider( ASWeaponConfig@ owner )
    {
        @this.m_Owner = owner;
        @gpWeaponsOverride[ this.m_Classname ] = this;
    }

    private WeaponOverriderCallback@ m_PlayerThink;
    WeaponOverriderCallback@ get_PlayerThink() {
        return @this.m_PlayerThink;
    }

    WeaponOverrider@ SetPlayerThink( WeaponOverriderCallback@ callback ) {
        @this.m_PlayerThink = callback;
        return this;
    }
}
