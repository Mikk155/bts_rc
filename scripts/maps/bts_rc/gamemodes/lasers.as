/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
    Author: Mikk
*/

final class TurretsLasers : EntityOverriden
{
    RGBA color;

    const string& get_Name() override
    {
        return "turret_lasers";
    }

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( this.IsActive() )
        {
            this.interval = Math.max( 0.01f, json.ValueOrDefault( "interval", 0.1f ) );

            this.color = RGBA(
                Math.min( 255, Math.max( 0, json.ValueOrDefault( "red", 255 ) ) ),
                Math.min( 255, Math.max( 0, json.ValueOrDefault( "green", 0 ) ) ),
                Math.min( 255, Math.max( 0, json.ValueOrDefault( "blue", 0 ) ) ),
                Math.min( 255, Math.max( 0, json.ValueOrDefault( "blue", 150 ) ) )
             );

            g_Game.PrecacheModel( "sprites/glow01.spr" );
        }

        EntityOverriden::Register( json );
    }

    void AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        string classname = entity.GetClassname();

        if( classname == "monster_sentry" || classname == "monster_turret" || classname == "monster_miniturret" )
        {
            monster.pev.armortype = Math.RandomLong( 0, 20 );
            monster.pev.armorvalue = Math.RandomLong( 0, 1 );
            EntityOverriden::AddEntity( index, entity, ckv, monster );
        }
    }

    protected CSprite@ sprite( Vector &in VecPos )
    {
        CSprite@ spr = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", VecPos, true );

        if( spr !is null )
        {
            spr.AnimateAndDie( 1 / this.interval );
            spr.pev.rendercolor.x = this.color.r;
            spr.pev.rendercolor.y = this.color.g;
            spr.pev.rendercolor.z = this.color.b;
            return @spr;
        }

        return null;
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || !monster.IsAlive() )
            return EntityOverridenAction::Remove;

        CBaseEntity@ enemy;

        if( monster.pev.sequence == 0 || !monster.m_hEnemy.IsValid() || ( @enemy = monster.m_hEnemy.GetEntity() ) is null )
            return EntityOverridenAction::None;

        TraceResult tr;
        Vector VecStart;
        Vector VecAngles;

        string classname = entity.GetClassname();

        if( "monster_sentry" == classname )
            monster.GetBonePosition( 5, VecStart, VecAngles );
        else if( "monster_turret" == classname )
            monster.GetBonePosition( 9, VecStart, VecAngles );
        else if( "monster_miniturret" == classname )
            monster.GetBonePosition( 3, VecStart, VecAngles );

        if( int(monster.pev.armorvalue) == 1 )
        {
            monster.pev.armortype -= 1;

            if( monster.pev.armortype <= 0 )
                monster.pev.armorvalue = 0;
        }
        else
        {
            monster.pev.armortype += 1;

            if( monster.pev.armortype >= 20 )
            {
                monster.pev.armorvalue = 1;
            }
        }

        // Offset of 10 units bellow the eye position
        g_Utility.TraceLine( VecStart, enemy.EyePosition() - Vector( Math.RandomFloat(0, 1), Math.RandomFloat(0, 1), monster.pev.armortype ), dont_ignore_monsters, monster.edict(), tr );

        CSprite@ spr;

        // Glow
        if( ( @spr = sprite( VecStart ) ) !is null )
        {
            spr.pev.rendermode = kRenderGlow;
            spr.pev.renderamt = this.color.a;
        }

        if( ( @spr = sprite( tr.vecEndPos ) ) !is null )
        {
            spr.pev.rendermode = kRenderTransAdd;
            spr.pev.renderamt = this.color.a / 2;

            if( enemy.IsPlayer() && ( enemy.pev.origin - tr.vecEndPos ).Length() < 64 )
            {
                auto playerClass = util::GetClass(enemy);

                // Dont modulate night vision
                if( playerClass != Classification::HEV || int( enemy.GetUserData()[ "helmet_nv_state" ] ) == 0 )
                {
                    g_PlayerFuncs.ScreenFade( enemy, spr.pev.rendercolor, 0.1f, this.interval + 0.1f, this.color.a, FFADE_MODULATE | FFADE_IN );   
                }
            }
        }

        int clientInterval = int( this.interval / 0.1f );

        if( classname == "monster_turret" )
        {
            NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( VecStart.x );
                m.WriteCoord( VecStart.y );
                m.WriteCoord( VecStart.z );
                m.WriteByte( 8 );   // radius
                m.WriteByte( this.color.r );
                m.WriteByte( this.color.g );
                m.WriteByte( this.color.b );
                m.WriteByte( clientInterval );
                m.WriteByte( 1 );
            m.End();
        }
        {
            NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( tr.vecEndPos.x );
                m.WriteCoord( tr.vecEndPos.y );
                m.WriteCoord( tr.vecEndPos.z );
                m.WriteByte( 8 );
                m.WriteByte( this.color.r );
                m.WriteByte( this.color.g );
                m.WriteByte( this.color.b );
                m.WriteByte( clientInterval );
                m.WriteByte( 1 );
            m.End();
        }
        {
            NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                m.WriteByte( TE_BEAMPOINTS );
                m.WriteCoord( VecStart.x );
                m.WriteCoord( VecStart.y );
                m.WriteCoord( VecStart.z );
                m.WriteCoord( tr.vecEndPos.x );
                m.WriteCoord( tr.vecEndPos.y );
                m.WriteCoord( tr.vecEndPos.z );
                m.WriteShort( models::laserbeam );
                m.WriteByte( 0 );
                m.WriteByte( 1 );
                m.WriteByte( clientInterval );
                m.WriteByte( 1 );
                m.WriteByte( 0 );
                m.WriteByte( this.color.r );
                m.WriteByte( this.color.g );
                m.WriteByte( this.color.b );
                m.WriteByte( this.color.a );
                m.WriteByte( 0 );
            m.End();
        }

        return EntityOverridenAction::None;
    }

    bool ShouldThink() override {
        return ( EntityOverriden::ShouldThink() && FreeEdicts( 6 ) ); // 2 sprites 3-4 temporary entity
    }
}

TurretsLasers gpTurretsLasers;
