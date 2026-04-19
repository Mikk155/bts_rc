namespace weapons
{

    // Play effects
    void TraceEffects( CBasePlayerWeapon@ weapon, CBasePlayer@ player, ASWeaponConfig@ config, TraceResult &in tr, Bullet bullet = Bullet::BULLET_NONE )
    {
        if( bullet != Bullet::BULLET_NONE )
        {
            g_WeaponFuncs.DecalGunshot( tr, bullet );
            g_SoundSystem.PlayHitSound( tr, ( player !is null ? player.GetGunPosition() : g_vecZero ), tr.vecEndPos, bullet );

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
                    if( player !is null )
                    {
                        player.pev.effects |= EF_MUZZLEFLASH;
                    }
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

        if( g_WeaponsConfig.blood_splash && monster.m_bloodColor != DONT_BLEED )
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

        if( g_WeaponsConfig.sparks_splash )
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
}
