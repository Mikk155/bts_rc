funcdef void PlayerThinkOverride( CBasePlayer@ player, CBasePlayerWeapon@ weapon );

dictionary gpWeaponsOverride;

// Use this interface to override vanilla weapons. Register with: @gpWeaponsOverride[ this.GetName() ] = this;
class WeaponOverrider
{
    private string m_Classname;
    const string& get_classname() {
        return this.m_Classname;
    }

    WeaponOverrider() {}

    WeaponOverrider( const string&in Classname )
    {
        this.m_Classname = Classname;
        @gpWeaponsOverride[ this.m_Classname ] = this;
    }

    PlayerThinkOverride@ PlayerThink;
}
