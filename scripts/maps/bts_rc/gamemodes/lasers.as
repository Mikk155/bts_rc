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

class TurretsLasers : EntityOverriden
{
    const string& get_Name() {
        return "turret_lasers";
    }

    void Parse( dictionary@ json ) override
    {
        EntityOverriden::Parse( json );

        if( this.active )
        {
            g_Game.PrecacheModel( "sprites/glow01.spr" );
        }
    }

    void AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        string classname = entity.GetClassname();

        if( classname == "monster_sentry" || classname == "monster_turret" || classname == "monster_miniturret" )
            EntityOverriden::AddEntity( index, entity, ckv, monster );
    }

    CSprite@ sprite( Vector &in VecPos )
    {
        NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m.WriteByte( TE_DLIGHT );
            m.WriteCoord( VecPos.x );
            m.WriteCoord( VecPos.y );
            m.WriteCoord( VecPos.z );
            m.WriteByte( 8 );   // radius
            m.WriteByte( 100 ); // R
            m.WriteByte( 0 );   // G
            m.WriteByte( 0 );   // B
            m.WriteByte( 1 );   // life in 0.1's
            m.WriteByte( 1 );   // decay in 0.1's
        m.End();

        CSprite@ spr = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", VecPos, true );

        if( spr !is null )
        {
            spr.AnimateAndDie( 10.0f );
            return @spr;
        }
        return null;
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || !monster.IsAlive() )
            return EntityOverridenAction::Remove;

        if( monster.pev.sequence == 0 || !monster.m_hEnemy.IsValid() )
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

        // Offset of 10 units bellow the eye position
        g_Utility.TraceLine( VecStart, monster.m_hEnemy.GetEntity().EyePosition() - Vector( 0, 0, 10 ), dont_ignore_monsters, monster.edict(), tr );

        CSprite@ spr_1 = sprite( VecStart );
        if( spr_1 !is null )
        {
            spr_1.pev.rendermode = kRenderGlow;          // Glow
            spr_1.pev.renderamt = 255;                   // Amt of glow
            spr_1.pev.rendercolor = Vector( 255, 0, 0 ); // Color of glow
        }

        CSprite@ spr_2 = sprite( tr.vecEndPos );
        if( spr_2 !is null )
        {
            spr_2.pev.rendermode = kRenderTransAdd;      // Additive
            spr_2.pev.renderamt = 80;                    // Amt of target's sprite
            spr_2.pev.rendercolor = Vector( 255, 0, 0 ); // Color of target's sprite
        }

        NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m.WriteByte( TE_BEAMPOINTS );
            m.WriteCoord( VecStart.x );
            m.WriteCoord( VecStart.y );
            m.WriteCoord( VecStart.z );
            m.WriteCoord( tr.vecEndPos.x );
            m.WriteCoord( tr.vecEndPos.y );
            m.WriteCoord( tr.vecEndPos.z );
            m.WriteShort( models::laserbeam );
            m.WriteByte( 0 );   // starting frame
            m.WriteByte( 0 );   // frame rate in 0.1's
            m.WriteByte( 1 );   // life in 0.1's
            m.WriteByte( 1 );   // line width in 0.1's
            m.WriteByte( 0 );   // noise amplitude in 0.01's
            m.WriteByte( 255 ); // R
            m.WriteByte( 0 );   // G
            m.WriteByte( 0 );   // B
            m.WriteByte( 255 ); // brightness
            m.WriteByte( 0 );   // scrol speed in 0.1's
        m.End();

        return EntityOverridenAction::None;
    }

    bool ShouldThink() override {
        return ( EntityOverriden::ShouldThink() && FreeEdicts( 5 ) ); // 2 sprites 3 temporary entity
    }
}

TurretsLasers gpTurretsLasers;
