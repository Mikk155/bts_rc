/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

// Retains one reusable laser spot entity for each player slot.
namespace LaserSpot
{
    final class ASPlayerLaserSpot
    {
        private EHandle m_hEntity;
        private float m_Distance = 8192.0f;

        private CBaseEntity@ GetOrCreateEntity()
        {
            if( this.m_hEntity.IsValid() )
                return this.m_hEntity.GetEntity();

            CBaseEntity@ laser = g_EntityFuncs.CreateEntity( "info_target", null, false );

            if( laser is null )
                return null;

            laser.pev.movetype = MOVETYPE_NONE;
            laser.pev.solid = SOLID_NOT;
            laser.pev.rendermode = kRenderGlow;
            laser.pev.renderamt = 255.0f;
            laser.pev.renderfx = kRenderFxNoDissipation;
            laser.pev.effects |= EF_NODRAW;

            g_EntityFuncs.DispatchSpawn( laser.edict() );

            this.m_hEntity = EHandle( laser );

            return laser;
        }

        ASPlayerLaserSpot@ Configure( const string&in model, float scale, float distance )
        {
            this.m_Distance = Math.max( 0.0f, distance );

            CBaseEntity@ laser = this.GetOrCreateEntity();
            if( laser !is null )
            {
                g_EntityFuncs.SetModel( laser, model );
                laser.pev.scale = scale;
            }

            return @this;
        }

        void Show()
        {
            CBaseEntity@ laser = this.GetOrCreateEntity();
            if( laser !is null )
                laser.pev.effects &= ~EF_NODRAW;
        }

        void Hide()
        {
            if( !this.m_hEntity.IsValid() )
                return;

            CBaseEntity@ laser = this.m_hEntity.GetEntity();
            if( laser !is null )
                laser.pev.effects |= EF_NODRAW;
        }

        void UpdateTrace( CBasePlayer@ player )
        {
            if( player is null )
                return;

            CBaseEntity@ laser = this.GetOrCreateEntity();

            if( laser is null )
                return;

            Math.MakeVectors( player.pev.v_angle );
            Vector vecSrc = player.GetGunPosition();
            Vector vecEnd = vecSrc + ( g_Engine.v_forward * this.m_Distance );

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
            g_EntityFuncs.SetOrigin( laser, tr.vecEndPos );
        }
    }

    array<ASPlayerLaserSpot> gpLaserSpots( g_Engine.maxClients );

    ASPlayerLaserSpot@ Get( CBasePlayer@ player )
    {
        if( player is null )
            return null;

        int index = player.entindex() - 1;
        if( index < 0 || index >= int( gpLaserSpots.length() ) )
            return null;

        return @gpLaserSpots[index];
    }

    void Hide( CBasePlayer@ player )
    {
        ASPlayerLaserSpot@ laser = Get( player );
        if( laser !is null )
            laser.Hide();
    }
}
