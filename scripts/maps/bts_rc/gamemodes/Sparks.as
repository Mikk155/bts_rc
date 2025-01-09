/*
    Author: Sparks
*/

namespace Sparks
{
    // -TODO Ricochet sounds?
    void Sparks( Vector &in destination, const int &in color)
    {
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
                Sparks::Sparks(destination, 5);
            }
            if( group == 10 )
            {
                if( classname == "monster_zombie_soldier" )
                {
                    if( hit.vars.model == "models/bts_rc/monsters/zombie_hev.mdl" )
                    {
                        Sparks::Sparks(destination, 3);
                    }
                }
                else if( classname == "monster_alien_grunt" )
                {
                    Sparks::Sparks(destination, 0);
                }
                else if( classname == "monster_barney" )
                {
                    Sparks::Sparks(destination, 7);
                }
            }
            else if( classname == "monster_sentry" || classname == "monster_turret" || classname == "monster_miniturret" )
            {
                Sparks::Sparks(destination, 4);
            }
        }
    }
}
