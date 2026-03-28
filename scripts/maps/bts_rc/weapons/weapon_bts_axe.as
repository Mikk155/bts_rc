/*
 *   Emergency Fire Axe
 *   Rewrited by Rizulix for bts_rc (january 2025)
 *   Rewrited by mikk 27/3/26
 */

namespace weapons
{
    namespace weapon_bts_axe
    {
        enum ANIM
        {
            IDLE1 = 0,
            DRAW,
            HOLSTER,
            ATTACK1HIT,
            ATTACK1MISS,
            ATTACK2MISS,
            ATTACK2HIT,
            ATTACK3MISS,
            ATTACK3HIT,
            IDLE2,
            IDLE3,
            SHOVE,
            SHOVE_ALT,
            SHOVE_MISS,
            SHOVE_MISS_ALT
        };

        class weapon_bts_axe : ScriptBasePlayerWeaponEntity, CBaseWeapon
        {
            int m_iSwing = 0;
            bool m_IsSecondary = false;

            bool Deploy()
            {
                return deploy( get_player(), self, "models/bts_rc/weapons/v_axe.mdl", "models/bts_rc/weapons/p_axe.mdl", ANIM::DRAW, "crowbar", 1 );
            }

            void Spawn()
            {
                g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_axe.mdl" );
                self.FallInit();
            }

            bool GetItemInfo( ItemInfo& out info )
            {
                info.iMaxAmmo1 = -1;
                info.iAmmo1Drop = WEAPON_NOCLIP;
                info.iMaxAmmo2 = -1;
                info.iAmmo2Drop = -1;
                info.iMaxClip = WEAPON_NOCLIP;
                info.iSlot = 0;
                info.iPosition = 9;
                info.iId = g_ItemRegistry.GetIdForName( pev.classname );
                info.iFlags = gpDefaultFlags;
                info.iWeight = 10;
                return true;
            }

            void Holster( int skiplocal = 0 )
            {
                SetThink( null );
                BaseClass.Holster( skiplocal );
            }

            void PrimaryAttack()
            {
                m_IsSecondary = false;
                Attack();
            }

            void Attack()
            {
                if( !Swing( true ) )
                {
                    SetThink( ThinkFunction( this.SwingAgain ) );
                    pev.nextthink = g_Engine.time + 0.1f;
                }
            }

            void SwingAgain()
            {
                Swing( false );
            }

            void SecondaryAttack()
            {
                m_IsSecondary = true;
                Attack();
            }

            void WeaponIdle()
            {
                if( g_Engine.time > self.m_flTimeWeaponIdle )
                {
                    switch( Math.RandomLong( 0, 2 ) )
                    {
                        case 0:
                            self.SendWeaponAnim( ANIM::IDLE1, 0, pev.body );
                            break;
                        case 1:
                            self.SendWeaponAnim( ANIM::IDLE2, 0, pev.body );
                            break;
                        case 2:
                            self.SendWeaponAnim( ANIM::IDLE3, 0, pev.body );
                            break;
                    }

                    self.m_flTimeWeaponIdle = g_Engine.time + 5.5f;
                }
            }

            bool Swing( bool fFirst )
            {
                auto player = get_player();

                bool fDidHit = false;

                TraceResult tr;

                Math.MakeVectors( player.pev.v_angle );

                Vector vecSrc = player.GetGunPosition();
                Vector vecEnd = vecSrc + g_Engine.v_forward * 45.0f;

                g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );

                bool is_trained_personal = g_PlayerClass.is_trained_personal( player );

                if( tr.flFraction >= 1.0f )
                {
                    if( fFirst )
                    {
                        // miss
                        switch( ( m_iSwing++ ) % 3 )
                        {
                            case 0:
                                self.SendWeaponAnim( ( m_IsSecondary ? ANIM::SHOVE_MISS : ANIM::ATTACK1MISS ), 0, pev.body );
                                break;
                            case 1:
                                self.SendWeaponAnim( ( m_IsSecondary ? ANIM::SHOVE_MISS_ALT : ANIM::ATTACK2MISS ), 0, pev.body );
                                break;
                            case 2:
                                self.SendWeaponAnim( ( m_IsSecondary ? ANIM::SHOVE_MISS : ANIM::ATTACK3MISS ), 0, pev.body );
                                break;
                        }

                        self.m_flNextPrimaryAttack = g_Engine.time + ( is_trained_personal ? 0.90f : 1.25f );
                        self.m_flNextSecondaryAttack = g_Engine.time + ( is_trained_personal ? 1.0f : 1.35f );
                        self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                        // play wiff or swish sound
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_miss1.wav", 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

                        // player "shoot" animation
                        player.SetAnimation( PLAYER_ATTACK1 );
                    }
                }
                else
                {
                    if( tr.flFraction >= 1.0f )
                    {
                        g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, player.edict(), tr );

                        if( tr.flFraction < 1.0f )
                        {
                            // Calculate the point of intersection of the line (or hull) and the object we hit
                            // This is and approximation of the "best" intersection
                            CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

                            if( pHit is null || pHit.IsBSPModel() )
                            {
                                g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, player.edict() );
                            }

                            vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
                        }
                    }

                    // hit
                    fDidHit = true;

                    switch( ( ( m_iSwing++ ) % 2 ) + 1 )
                    {
                        case 0:
                            self.SendWeaponAnim( ( m_IsSecondary ? ANIM::SHOVE : ANIM::ATTACK1HIT ), 0, pev.body );
                            break;
                        case 1:
                            self.SendWeaponAnim( ( m_IsSecondary ? ANIM::SHOVE_ALT : ANIM::ATTACK2HIT ), 0, pev.body );
                            break;
                        case 2:
                            self.SendWeaponAnim( ( m_IsSecondary ? ANIM::SHOVE : ANIM::ATTACK3HIT ), 0, pev.body );
                            break;
                    }

                    if( m_IsSecondary )
                        self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + ( is_trained_personal ? 0.25f : 0.5f );
                    else
                        self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + ( is_trained_personal ? 0.4f : 0.8f );

                    self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                    // player "shoot" animation
                    player.SetAnimation( PLAYER_ATTACK1 );

                    // play thwack, smack, or dong sound
                    float flVol = 1.0f;
                    bool fHitWorld = true;

                    CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

                    if( pEntity !is null )
                    {
                        g_WeaponFuncs.ClearMultiDamage();

                        // subsequent swings do 50% damage
                        float subsequent = ( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time ) ? 1.0 : 0.5f;
                        pEntity.TraceAttack( player.pev, ( m_IsSecondary ? 14.0f : 20.0f ) * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );

                        g_WeaponFuncs.ApplyMultiDamage( player.pev, player.pev );

                        int classify = pEntity.Classify();

                        if( classify != CLASS_NONE && classify != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
                        {
                            pull_target( player.pev.origin, pEntity );

                            // play thwack or smack sound
                            switch( Math.RandomLong( 0, 2 ) )
                            {
                                case 0:
                                    g_SoundSystem.EmitSound( player.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod3.wav", 1.0f, ATTN_NORM );
                                    break;
                                case 1:
                                    g_SoundSystem.EmitSound( player.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod2.wav", 1.0f, ATTN_NORM );
                                    break;
                                case 2:
                                    g_SoundSystem.EmitSound( player.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod1.wav", 1.0f, ATTN_NORM );
                                    break;
                            }

                            player.m_iWeaponVolume = 128;

                            if( !pEntity.IsAlive() )
                                return true;
                            else
                                flVol = 0.1f;

                            fHitWorld = false;
                        }
                    }

                    if( fHitWorld )
                    {
                        g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2.0f, BULLET_PLAYER_CROWBAR );

                        int pitch = ( m_IsSecondary ? 93 : 98 ) + Math.RandomLong( 0, 3 );

                        // also play crowbar strike
                        switch( Math.RandomLong( 0, 1 ) )
                        {
                            case 0:
                                g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hit2.wav", 1.0f, ATTN_NORM, 0, pitch );
                                break;
                            case 1:
                                g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hit1.wav", 1.0f, ATTN_NORM, 0, pitch );
                                break;
                        }
                    }

                    trace_effect( tr, Bullet::BULLET_PLAYER_CROWBAR, 0.2f );

                    player.m_iWeaponVolume = int( flVol * 512 );
                }
                return fDidHit;
            }
        }
    }
}
