mixin class CBaseWeapon
{
#if FALSE
    CBasePlayerWeapon@ self;
#endif

    CBasePlayer@ player = null;

    // To not cast repeatedly
    CBasePlayer@ get_player()
    {
        if( player is null || player !is self.m_hPlayer.GetEntity() )
        {
            @player = cast<CBasePlayer>( self.m_hPlayer.GetEntity() );
        }
        return @player;
    }

    ////////////_---------------------------old shit delete
    // Default flags for weapons
    protected int m_flags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

    // A weapon is deployed
    protected bool bts_deploy( const string &in viewmodel, const string &in playermodel, int animation, const string &in animation_ext, int hands_group, float time = 1.0f )
    {
        return weapons::deploy( get_player(), self, viewmodel, playermodel, animation, animation_ext, hands_group, time );
    }

    protected void bts_post_attack( TraceResult &in tr )
    {
    }

    bool AddToPlayer( CBasePlayer@ player )
    {
        if( !BaseClass.AddToPlayer( player ) )
            return false;

        NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, player.edict() );
        weapon.WriteLong( g_ItemRegistry.GetIdForName( pev.classname ) );
        weapon.End();

        return true;
    }

    protected float Accuracy( float tr, float def, float trd, float defd )
    {
        auto player = get_player();

        if( util::IsTrainedPersonal( player ) )
        {
            if( ( player.pev.button & IN_DUCK ) != 0 )
            {
                return trd;
            }
            return tr;
        }
        else if( ( player.pev.button & IN_DUCK ) != 0 )
        {
            return defd;
        }
        return def;
    }
};
