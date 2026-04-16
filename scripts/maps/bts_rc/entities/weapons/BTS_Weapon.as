enum AttackType
{
    Primary = 0,
    Secondary,
    Tertriary
};

// Base class for all weapons
class BTS_Weapon : ScriptBasePlayerWeaponEntity
{
    CBaseWeaponConfig@ get_DefaultConfig() {
        return @gpDefaultWeaponData;
    }

    CBasePlayer@ m_owner = null;

    /// Get the player owning this weapon
    CBasePlayer@ get_owner()
    {
        if( m_owner is null || m_owner !is self.m_hPlayer.GetEntity() )
        {
            @m_owner = cast<CBasePlayer>( self.m_hPlayer.GetEntity() );
        }

        return @m_owner;
    }

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, this.DefaultConfig.world_model );
        self.FallInit();
    }

    bool Deploy()
    {
        auto config = this.DefaultConfig;
        auto player = this.owner;

        player.pev.viewmodel = config.view_model;
        player.pev.weaponmodel = config.player_model;

        player.set_m_szAnimExtension( config.animation_extension );

        auto character = GetCharacter(player);
        Hands handGroup = ( character !is null ? character.HandsGroup : Hands::Gray );

        // Set the correct bodygroup for character hands in the given hands_group, most of the weapons has it in the bodygroup 1s
        self.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( config.view_model ), self.pev.body, config.hands_group, handGroup );

        self.SendWeaponAnim( config.animation_draw, 0, self.pev.body );

        player.m_flNextAttack = config.deploy_time;
        float globalized_deploy = config.deploy_time + g_Engine.time;

        if( self.m_flNextPrimaryAttack < globalized_deploy )
            self.m_flNextPrimaryAttack = globalized_deploy;

        if( self.m_flTimeWeaponIdle < globalized_deploy )
            self.m_flTimeWeaponIdle = globalized_deploy;

        if( self.m_flNextSecondaryAttack < globalized_deploy )
            self.m_flNextSecondaryAttack = globalized_deploy;

        return true;
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        auto config = this.DefaultConfig;

        info.iMaxAmmo1 = config.iMaxAmmo1;
        info.iAmmo1Drop = config.iAmmo1Drop;
        info.iMaxAmmo2 = config.iMaxAmmo2;
        info.iAmmo2Drop = config.iAmmo2Drop;
        info.iMaxClip = config.iMaxClip;
        info.iSlot = config.iSlot;
        info.iPosition = config.iPosition;
        info.iId = g_ItemRegistry.GetIdForName( self.pev.classname );
        info.iFlags = gpDefaultWeaponFlags;

        return true;
    }

    // Called on weapon idle. return the next call time
    float Idle()
    {
        return 60.0f;
    }

    void WeaponIdle()
    {
        if( self.m_flTimeWeaponIdle < g_Engine.time )
        {
            self.m_flTimeWeaponIdle = Idle();
        }
    }

    bool AddToPlayer( CBasePlayer@ player )
    {
        if( !BaseClass.AddToPlayer( player ) )
            return false;

        NetworkMessage msg( MSG_ONE, NetworkMessages::WeapPickup, player.edict() );
            msg.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
        msg.End();

        return true;
    }

    protected array<CScheduledFunction@> __Callbacks__;

    // Use g_Scheduler.SetTimeout as value and the resulting callback object will be stored in the weapon base and cleared if the weapon is removed or holstered
    void StartSchedule( CScheduledFunction@ value )
    {
        __Callbacks__.insertLast( @value );
    }

    void ClearTimerList()
    {
        uint length = __Callbacks__.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            auto callback = __Callbacks__[ui];

            if( callback !is null )
            {
                g_Scheduler.RemoveTimer( @callback );
            }
        }

        __Callbacks__.resize(0);
    }

    void UpdateOnRemove()
    {
        ClearTimerList();
        BaseClass.UpdateOnRemove();
    }

    void Holster( int skiplocal = 0 )
    {
        ClearTimerList();
        BaseClass.Holster( skiplocal );
    }

    float GetCooldown( bool is_trained_personal, AttackType type )
    {
        switch( type )
        {
            case AttackType::Primary:
                return ( is_trained_personal ? this.DefaultConfig.PrimaryTrainedCooldown : this.DefaultConfig.PrimaryCooldown );
            case AttackType::Secondary:
            {
                return ( is_trained_personal ? this.DefaultConfig.SecondaryTrainedCooldown : this.DefaultConfig.SecondaryCooldown );
            }
            case AttackType::Tertriary:
            default:
            {
                return ( is_trained_personal ? this.DefaultConfig.TertriaryTrainedCooldown : this.DefaultConfig.TertriaryCooldown );
            }
        }
    }

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, AttackType type )
    {
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack =
            g_Engine.time + this.GetCooldown( is_trained_personal, type );

        if( self.m_flTimeWeaponIdle < self.m_flNextPrimaryAttack )
            self.m_flTimeWeaponIdle= self.m_flNextPrimaryAttack;
    }

    // Play the given animation for this weapon. if player_attack_animation is true (by default) it makes the player animation to PLAYER_ATTACK1
    void PlayAnim( uint8 animation, bool player_attack_animation = true )
    {
        self.SendWeaponAnim( animation, 0, pev.body );

        if( player_attack_animation )
            this.owner.SetAnimation( PLAYER_ANIM::PLAYER_ATTACK1 );
    }

    // Force a sequence type animation on the player
    void ForcePlayerAnim( int iStandSequence, int iDuckSequence )
    {
        int iGaitSequence;

        auto player = this.owner;

        switch( player.m_Activity )
        {
            case ACT_HOVER:
            case ACT_SWIM:
            case ACT_HOP:
            case ACT_LEAP:
            case ACT_DIESIMPLE:
                break;
            default:
                iGaitSequence = player.pev.gaitsequence;
                player.m_Activity = ACT_RELOAD;
                player.pev.sequence = ( ( player.pev.flags & FL_DUCKING ) != 0 ) ? iDuckSequence : iStandSequence;
                player.pev.gaitsequence = iGaitSequence;
                player.pev.frame = 0.0f;
                player.ResetSequenceInfo();
                break;
        }
    }

    // Play effects
    void TraceEffects( TraceResult &in tr, Bullet bullet = Bullet::BULLET_NONE )
    {
        auto player = this.owner;

        if( bullet != Bullet::BULLET_NONE )
        {
            g_WeaponFuncs.DecalGunshot( tr, bullet );
            g_SoundSystem.PlayHitSound( tr, player.GetGunPosition(), tr.vecEndPos, bullet );

            switch( bullet )
            {
                case Bullet::BULLET_PLAYER_9MM:
                case Bullet::BULLET_PLAYER_MP5:
                case Bullet::BULLET_PLAYER_SAW:
                case Bullet::BULLET_PLAYER_SNIPER:
                case Bullet::BULLET_PLAYER_357:
                case Bullet::BULLET_PLAYER_EAGLE:
                case Bullet::BULLET_PLAYER_BUCKSHOT:
                {
                    player.pev.effects |= EF_MUZZLEFLASH;
                    break;
                }
                case Bullet::BULLET_PLAYER_CROWBAR:
                case Bullet::BULLET_NONE:
                default:
                    break;
            }
        }

        CBaseEntity@ hit = null;
        CBaseMonster@ monster = null;

        if( !freeedicts( 5 )
        || !g_EntityFuncs.IsValidEntity( tr.pHit )
        || ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) is null
        || !hit.IsMonster()
        || ( @monster = cast<CBaseMonster@>(hit) ) is null )
            return;

        if( weapons::gpTraceBlood && monster.m_bloodColor != DONT_BLEED )
        {
            CSprite@ spr = null;

            if( monster.m_bloodColor == BLOOD_COLOR_RED )
            {
                switch( Math.RandomLong( 0, 2 ) )
                {
                    case 0: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/hblood_1.spr", tr.vecEndPos, true ); break;
                    case 1: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/hblood_2.spr", tr.vecEndPos, true ); break;
                    case 2: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/hblood_3.spr", tr.vecEndPos, true ); break;
                }
            }
            else if( monster.m_bloodColor == BLOOD_COLOR_GREEN || monster.m_bloodColor == BLOOD_COLOR_YELLOW )
            {
                switch( Math.RandomLong( 0, 4 ) )
                {
                    case 0: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_1.spr", tr.vecEndPos, true ); break;
                    case 1: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_2.spr", tr.vecEndPos, true ); break;
                    case 2: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_3.spr", tr.vecEndPos, true ); break;
                    case 3: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_4.spr", tr.vecEndPos, true ); break;
                    case 4: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_5.spr", tr.vecEndPos, true ); break;
                }
            }

            if( spr !is null )
            {
                spr.AnimateAndDie( 60.0f );
                spr.pev.scale = Math.RandomFloat( 0.05, 0.25 );
            }
        }

        if( weapons::gpTraceSparks )
        {
            bool should_sparks = true;

            int sparks_color = -1;

            string classname = monster.GetClassname();
            string model = string( monster.pev.model );

            if( "monster_robogrunt" == classname )
            {
                sparks_color = 5;
            }
            else if( "monster_sentry" == classname || "monster_turret" == classname || "monster_miniturret" == classname )
            {
                sparks_color = 4;
            }
            else if( tr.iHitgroup == 10 )
            {
                if( "monster_alien_grunt" == classname )
                {
                    sparks_color = 0;
                }
                else if( "models/bts_rc/monsters/zombie_hev.mdl" == model || "models/bts_rc/monsters/gonome_hev.mdl" == model || "models/bts_rc/monsters/zombie_hev2.mdl" == model )
                {
                    sparks_color = 7;
                }
            }

            if( sparks_color != -1 )
            {
                switch( Math.RandomLong( 0, 4 ) )
                {
                    case 0: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric1.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 1: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric2.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 2: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric3.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 3: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric4.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 4: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric5.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                }

                NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                    m.WriteByte( TE_STREAK_SPLASH );
                    m.WriteCoord( tr.vecEndPos.x );
                    m.WriteCoord( tr.vecEndPos.y );
                    m.WriteCoord( tr.vecEndPos.z );
                    m.WriteCoord( 0 );
                    m.WriteCoord( 0 );
                    m.WriteCoord( g_Engine.v_forward.z );
                    m.WriteByte( sparks_color ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/images/engine_palette_2.png
                    m.WriteShort( 30 );          // Count
                    m.WriteShort( 128 );         // Base speed
                    m.WriteShort( 100 );         // Random velocity
                m.End();

                NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                    m2.WriteByte( TE_DLIGHT );
                    m2.WriteCoord( tr.vecEndPos.x );
                    m2.WriteCoord( tr.vecEndPos.y );
                    m2.WriteCoord( tr.vecEndPos.z );
                    m2.WriteByte( 5 );   // radius
                    m2.WriteByte( 150 ); // R
                    m2.WriteByte( 100 ); // G
                    m2.WriteByte( 0 );   // B
                    m2.WriteByte( 1 );   // life in 0.1's
                    m2.WriteByte( 1 );   // decay in 0.1's
                m2.End();

                g_Utility.Sparks( tr.vecEndPos );
                g_Utility.Ricochet( tr.vecEndPos, Math.RandomFloat( 0.5, 1.5 ) );
            }
        }
    }

    protected uint8 __last_random__ = 0;

    // Get a random number between 0 and max. if RandomUint was called before the result will be stored in __last_random__ to avoid repeating the same number in a row
    uint8 RandomUint( uint8 max )
    {
        if( max == 0 )
        {
            if( g_Logger.critical )
                g_Logger.critical = snprintf( glog, "RandomUint called with an argument of zero!" );
            return 0;
        }

        uint8 rand;

        do{ rand = Math.RandomLong( 0, max ); }
        while( rand == this.__last_random__ );

        this.__last_random__ = rand;

        return rand;
    }

    // Play the given sound uses EmitSoundDyn at the weapon location
    void PlaySound( const string&in soundName, float volume = 1.0f, int pitch = PITCH_NORM, float attenuation = ATTN_NORM )
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), SOUND_CHANNEL::CHAN_WEAPON, soundName, volume, attenuation, 0, pitch );
    }

    // weapon attack
    void Attack( CBasePlayer@ player, AttackType type )
    {
    }

    // Return whatever this is a solid entity or worldspawn
    bool IsBrush( CBaseEntity@ hit )
    {
        return true;
    }

    // Return whatever this is a flesh body
    bool IsFlesh( CBaseEntity@ hit )
    {
        return ( hit !is null && hit.pev.takedamage > DAMAGE_NO && ( hit.IsMonster() || hit.IsPlayer() ) && hit.Classify() != CLASS_MACHINE );
    }

    private void __Attack__( AttackType type )
    {
        Attack( this.owner, type );
    }

    void PrimaryAttack()
    {
        __Attack__( AttackType::Primary );
    }

    void SecondaryAttack()
    {
        __Attack__( AttackType::Secondary );
    }
}
