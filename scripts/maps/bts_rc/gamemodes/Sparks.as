/*
    Author: Sparks
*/

namespace Sparks
{
    array<string>@ ricochets = {
        "weapons/ric1.wav",
        "weapons/ric2.wav",
        "weapons/ric3.wav",
        "weapons/ric4.wav",
        "weapons/ric5.wav"
    };

    void Sparks( edict_t@ hit, Vector &in destination, const int &in color)
    {
        if( g_EntityFuncs.IsValidEntity( hit ) )
            g_SoundSystem.EmitSoundDyn( hit, CHAN_AUTO, ricochets[ Math.RandomLong( 0, ricochets.length() - 1 ) ], 1.0, ATTN_NONE, 0, PITCH_NORM );

        NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m.WriteByte( TE_STREAK_SPLASH );
            m.WriteCoord( destination.x );
            m.WriteCoord( destination.y );
            m.WriteCoord( destination.z );
            m.WriteCoord( g_Engine.v_forward.x );
            m.WriteCoord( g_Engine.v_forward.y );
            m.WriteCoord( g_Engine.v_forward.z );
            m.WriteByte( color ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/images/engine_palette_2.png
            m.WriteShort( 15 ); // Count
            m.WriteShort( 128 ); // Base speed
            m.WriteShort( 100 ); // Random velocity
        m.End();

        NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m2.WriteByte( TE_DLIGHT );
            m2.WriteCoord( destination.x );
            m2.WriteCoord( destination.y );
            m2.WriteCoord( destination.z );
            m2.WriteByte( 5 ); // radius
            m2.WriteByte( 150 ); // R
            m2.WriteByte( 100 ); // G
            m2.WriteByte( 0 ); // B
            m2.WriteByte( 1 ); // life in 0.1's
            m2.WriteByte( 1 ); // decay in 0.1's
        m2.End();

        g_Utility.Sparks( destination );
    }

    void Sparks(edict_t@ hit, const int &in group, Vector &in destination )
    {
        if( g_EntityFuncs.IsValidEntity( hit ) && freeedicts( 17 ) )
        {
            const string classname = hit.vars.classname;

            if( classname == "monster_robogrunt" )
            {
                Sparks::Sparks(hit, destination, 5);
            }
            if( group == 10 )
            {
                if( classname == "monster_zombie_soldier" )
                {
                    if( hit.vars.model == "models/bts_rc/monsters/zombie_hev.mdl" )
                    {
                        Sparks::Sparks(hit, destination, 7);
                    }
                }
                else if( classname == "monster_alien_grunt" )
                {
                    Sparks::Sparks(hit, destination, 0);
                }
            }
            else if( classname == "monster_sentry" || classname == "monster_turret" || classname == "monster_miniturret" )
            {
                Sparks::Sparks(hit, destination, 4);
            }
        }
    }
}
