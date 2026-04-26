funcdef void WeaponOverriderCallback( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character );

dictionary gpWeaponsOverride;

class WeaponOverrider
{
    private ASWeaponConfig@ Owner;

    const string& get_classname() {
        return this.Owner.Name;
    }

    WeaponOverrider() {}

    WeaponOverrider( ASWeaponConfig@ owner )
    {
        @this.Owner = owner;
        @gpWeaponsOverride[ this.Owner.Name ] = this;
    }

    // 2.27 doesn't force pev->body through SendWeaponAnim so we do this hack in the meanwhile
    void __526FixViewModels__( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        dictionary@ data = player.GetUserData();

        int sequence;

        if( !data.get( "526_weaponsequence", sequence ) )
            sequence = -1;

        if( sequence != player.pev.weaponanim )
        {
            data[ "526_weaponsequence" ] = player.pev.weaponanim;
            Hands handsGroup = ( character !is null ? character.HandsGroup : Hands::Hevsuit );
            weapon.pev.body = g_ModelFuncs.SetBodygroup( Owner.view_model_index, weapon.pev.body, Owner.hands_group, handsGroup );
            weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body );
        }
        else if( weapon.m_flTimeWeaponIdle <= g_Engine.time )
        {
            data[ "526_weaponsequence" ] = -1;
        }
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

    WeaponOverriderCallback@ WeaponPrimaryAttack;
    WeaponOverrider@ SetWeaponPrimayAttack( WeaponOverriderCallback@ callback ) {
        @this.WeaponPrimaryAttack = callback;
        return this;
    }

    WeaponOverriderCallback@ WeaponSecondaryAttack;
    WeaponOverrider@ SetWeaponSecondaryAttack( WeaponOverriderCallback@ callback ) {
        @this.WeaponSecondaryAttack = callback;
        return this;
    }

    WeaponOverriderCallback@ WeaponTertriaryAttack;
    WeaponOverrider@ SetWeaponTertriaryAttack( WeaponOverriderCallback@ callback ) {
        @this.WeaponTertriaryAttack = callback;
        return this;
    }
}
