/*  trigger_shuffle_position - Custom entity to randomly shuffle position of a given list of entities

    Installation:-
    - Place in scripts/maps
    - Add
    map_script trigger_shuffle_position
    to your map cfg
    OR
    - Add
    #include "trigger_shuffle_position"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "trigger_shuffle_position"

    Usage:-
    Use the key "netname" to add a semlicolon seperated list of entity names you wish to have their origins shuffled around.
    If there are more than one entity for a given name (meaning there entities with duplicate names) those entities will also be included.
    The angles of the previous entity will be applied to the new entity during the shuffle, otherwise you can check flag 2 to disable this so that
    the entity's angles are kept as it was originally placed.

    If the entity has no targetname set, it will automatically trigger and shuffle the set entities.
    If the entity is triggered with "Off" use type, the entities will revert back to their original positions before being shuffled the first time.

    If you wish to simply randomise the position of one or more entities in a set number of locations, you may use some dummy entity like info_target
    in the other locations and inlcude those dummy entities in the list. This will make it appear as if the entity is placed in a random location.

- Outerbeast
*/
enum shuffleflags
{
    SF_STARTON          = 1 << 0,
    SF_PRESERVE_ANGLES  = 1 << 1,
};

bool blRegisterShufflePositon = RegisterShufflePosition();

bool RegisterShufflePosition()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_shuffle_position", "trigger_shuffle_position" );
    return g_CustomEntityFuncs.IsCustomEntity( "trigger_shuffle_position" );
}



final class trigger_shuffle_position : ScriptBaseEntity
{
    private bool blShuffledOnce;

    bool IsUnique(uint value, array<uint> a)
    {
        // Check if the value is already in the container
        for (uint i = 0; i < a.length(); ++i)
        {
            if (a[i] == value)
            {
                return false;
            }
        }
        return true;
    }


    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.effects |= EF_NODRAW;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.GetTargetname() == "" || self.pev.SpawnFlagBitSet( SF_STARTON ) )
            g_Scheduler.SetTimeout( this, "Shuffle", 1.0f, string( self.pev.netname ), string( self.pev.target ), false, self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ) );

        BaseClass.Spawn();
    }

    void Shuffle(string strEntityList, string strTarget, bool blResetPositions, bool blPreserveAngles)
    {
        CBaseEntity@ pEntity;
        array<EHandle> H_ENTITIES;
        array<Vector> VEC_POSITIONS, VEC_ANGLES;
        array<uint> RANDOM;

        if( strEntityList != "" )
        {
            array<string> STR_ENTITY_NAMES = strEntityList.Split( ";" );

            for( uint i = 0; i < STR_ENTITY_NAMES.length(); i++ )
            {
                if( STR_ENTITY_NAMES[i] == "" )
                    continue;

                while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, STR_ENTITY_NAMES[i] ) ) !is null )
                {
                    if( pEntity is null || H_ENTITIES.findByRef( EHandle( pEntity ) ) >= 0 )
                        continue;
                    if( pEntity.pev.classname != "info_target")
                    {
                        H_ENTITIES.insertLast( pEntity );
                    }
                    else if( pEntity.pev.classname == "info_target" )
                    {
                        VEC_POSITIONS.insertLast( pEntity.pev.origin );
                        VEC_ANGLES.insertLast( pEntity.pev.angles );
                    }
                    
                    if( !blShuffledOnce )
                        pEntity.pev.oldorigin = pEntity.pev.origin;
                }
            }
        }
        else if( strTarget != "" )
        {
            for( int i = g_Engine.maxClients + 1; i <= g_EngineFuncs.NumberOfEntities(); i++ )
            {
                @pEntity = g_EntityFuncs.Instance( i );

                if( pEntity is null || !pEntity.IsInWorld() || H_ENTITIES.findByRef( EHandle( pEntity ) ) >= 0 )
                    continue;

                H_ENTITIES.insertLast( pEntity );
                VEC_POSITIONS.insertLast( pEntity.pev.origin );
                VEC_ANGLES.insertLast( pEntity.pev.angles );

                if( !blShuffledOnce )
                    pEntity.pev.oldorigin = pEntity.pev.origin;
            }
        }

        if( blResetPositions )
        {
            for( uint i = 0; i < H_ENTITIES.length(); i++ )
            {
                if( !H_ENTITIES[i] )
                    continue;

                @pEntity = H_ENTITIES[i].GetEntity();

                if( pEntity is null || pEntity.pev.oldorigin == g_vecZero )
                    continue;

                if( pEntity.pev.oldorigin != pEntity.pev.origin )
                    g_EntityFuncs.SetOrigin( pEntity, pEntity.pev.oldorigin );
            }

            return;
        }
        
        
        // Unless you show me how to shuffle a set containing one item.
        if( H_ENTITIES.length() < 2 || VEC_POSITIONS.length() < 2 )
            return;
  
        for( uint i = 0; i < H_ENTITIES.length(); i++ )
        {
            if( !H_ENTITIES[i] )
                continue;

            @pEntity = H_ENTITIES[i].GetEntity();

            uint rand = 0;
            do
            {
                rand = Math.RandomLong(0,VEC_POSITIONS.length()-1);
            }while(!IsUnique(rand,RANDOM));
            
            RANDOM.insertLast(rand);
            g_EntityFuncs.SetOrigin( pEntity, VEC_POSITIONS[rand] );

            // in case method was called directly from a script object, it would be null.
            if( blPreserveAngles )
                pEntity.pev.angles = VEC_ANGLES[VEC_POSITIONS.find( pEntity.pev.origin )];
        }
        
        blShuffledOnce = true;
    }

    
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( self.pev.target != "" )
            Shuffle( "", self.pev.target, useType == USE_OFF || useType == USE_KILL, self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ));
        else
            Shuffle( self.pev.netname, "", useType == USE_OFF || useType == USE_KILL, self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ));
    }
};
