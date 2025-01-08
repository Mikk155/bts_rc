/*
    Author: Sparks
*/

namespace Sparks
{
    // -TODO Ricochet sounds?
    void Sparks( Vector &in destination )
    {
        NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m.WriteByte( TE_STREAK_SPLASH );
            m.WriteCoord( destination.x );
            m.WriteCoord( destination.y );
            m.WriteCoord( destination.z );
            m.WriteCoord( g_Engine.v_forward.x );
            m.WriteCoord( g_Engine.v_forward.y );
            m.WriteCoord( g_Engine.v_forward.z );
            m.WriteByte( 6 ); // Color
            m.WriteShort( 2 ); // Count
            m.WriteShort( 128 ); // Base speed
            m.WriteShort( 100 ); // Random velocity
        m.End();

        g_Utility.Sparks( destination );
    }

    void Sparks(edict_t@ hit, const int &in group, Vector &in destination )
    {
        if( g_EntityFuncs.IsValidEntity( hit ) && freeedicts( 2 ) )
        {
            const string classname = hit.vars.classname;

            if( classname == "monster_zombie_soldier" )
            {
                if( hit.vars.model == "models/bts_rc/monsters/zombie_hev.mdl" && group == 10 )
                {
                    Sparks::Sparks(destination);
                }
            }
            else if( classname == "monster_alien_grunt" || classname == "monster_barney" )
            {
                if( group == 10 )
                {
                    Sparks::Sparks(destination);
                }
            }
            else if( classname == "monster_sentry" || classname == "monster_turret" || classname == "monster_miniturret" )
            {
                Sparks::Sparks(destination);
            }
        }
    }
}
