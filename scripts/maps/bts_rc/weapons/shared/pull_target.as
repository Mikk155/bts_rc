namespace weapons
{
    bool gpAllowMeleePull;

    /**
     *   @brief Pull target
     **/
    bool pull_target( const Vector &in source, CBaseEntity@ target )
    {
        if( !gpAllowMeleePull || target is null || !target.IsPlayer() )
            return false;

        target.pev.velocity = target.pev.velocity + ( source - target.pev.origin ).Normalize() * 120.0f;

        return true;
    }
}
