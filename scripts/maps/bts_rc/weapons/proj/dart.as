
namespace DART
{

class CDart : ScriptBaseEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetSize( pev, g_vecZero, g_vecZero );

        pev.movetype = MOVETYPE_FLY;
        pev.solid   = SOLID_BBOX;
        pev.gravity = 0.5f;
        pev.dmg = 1.0f;

        // RGBA(160, 32, 240)
        NetworkMessage msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            msg.WriteByte( TE_BEAMFOLLOW );
            msg.WriteShort( self.entindex() );
            msg.WriteShort( models::laserbeam );
            msg.WriteByte( 2 ); // life
            msg.WriteByte( 1 ); // width
            msg.WriteByte( 160 ); // r
            msg.WriteByte( 32 ); // g
            msg.WriteByte( 240 ); // b
            msg.WriteByte( 100 ); // brightness
        msg.End();

        SetThink( ThinkFunction( this.BubbleThink ) );
        pev.nextthink = g_Engine.time + 0.2f;
        SetTouch( TouchFunction( this.DartTouch ) );
    }

    int Classify()
    {
        return CLASS_NONE;
    }

    void DartTouch( CBaseEntity@ pOther )
    {
        if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        SetTouch( null );
        SetThink( null );

        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            TraceResult tr = g_Utility.GetGlobalTrace();

            entvars_t@ pevOwner = pev;
            if( pev.owner !is null )
                @pevOwner = pev.owner.vars;

            g_WeaponFuncs.ClearMultiDamage();

            if( pOther.IsPlayer() )
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NEVERGIB );
            else
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BULLET | DMG_NEVERGIB );

            g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

            g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "weapons/xbow_hitbod1.wav", 1.0f, ATTN_NORM );

            pev.velocity = g_vecZero;

            self.Killed( pev, GIB_NEVER );
        }
        else
        {
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "weapons/xbow_hit1.wav", Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 7 ) );

            SetThink( ThinkFunction( this.SUB_Remove ) );
            pev.nextthink = g_Engine.time;

            if( pOther.pev.ClassNameIs("worldspawn") )
            {
                Vector vecDir = pev.velocity.Normalize();
                g_EntityFuncs.SetOrigin( self, pev.origin - vecDir ); //Pull out of the wall a bit
                pev.angles = Math.VecToAngles( vecDir );
                pev.solid = SOLID_NOT;
                pev.movetype = MOVETYPE_FLY;
                pev.velocity = g_vecZero;
                pev.avelocity.z = 0.0f;
                pev.angles.z = float( Math.RandomLong( 0, 360 ) );
                pev.nextthink = g_Engine.time + 10.0f;

                TraceResult tr = g_Utility.GetGlobalTrace();
                g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
            }

            if( g_EngineFuncs.PointContents( pev.origin ) != CONTENTS_WATER )
                g_Utility.Sparks( pev.origin );
        }
    }

    void BubbleThink()
    {
        pev.nextthink = g_Engine.time + 0.1f;

        if( pev.waterlevel == WATERLEVEL_DRY )
            return;

        g_Utility.BubbleTrail( pev.origin - pev.velocity * 0.1f, pev.origin, 1 );
    }

    void SUB_Remove()
    {
        self.SUB_Remove();
    }
}

CDart@ Shoot( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, const string& in szModel )
{
    CDart@ pDart = cast<CDart>( CastToScriptClass( g_EntityFuncs.CreateEntity( "gun_dart" ) ) );
    if( pDart is null )
        return null;

    g_EntityFuncs.SetModel( pDart.self, szModel );
    g_EntityFuncs.SetOrigin( pDart.self, vecStart );
    g_EntityFuncs.DispatchSpawn( pDart.self.edict() );

    pDart.pev.velocity = vecVelocity;
    pDart.pev.angles = Math.VecToAngles( pDart.pev.velocity );

    pDart.pev.dmg = flDmg;
    @pDart.pev.owner = pevOwner.pContainingEntity;

    return pDart;
}
}