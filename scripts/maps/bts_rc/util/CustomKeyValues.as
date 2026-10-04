class CustomKeyValues
{
    private
        string m_KeyName;

    const string& get_Key() const property final
    {
        return this.m_KeyName;
    }

    const Entvartype get_Type() const property final
    {
        char type = this.Key[1];
        if( type == 'i' )
            return Entvartype::VAR_INTEGER;
        if( type == 'f' )
            return Entvartype::VAR_FLOAT;
        if( type == 's' )
            return Entvartype::VAR_STRING;
        if( type == 'v' )
            return Entvartype::VAR_VECTOR;
        return Entvartype::VAR_INVALID;
    }

    bool CopyOver( CustomKeyvalues@ pFrom, CBaseEntity@ pTo ) const
    {
        if( pFrom is null || pTo is null )
            return false;

        CustomKeyvalue kv = pFrom.GetKeyvalue( this.Key );

        if( kv.Exists() )
        {
            switch( this.Type )
            {
                case Entvartype::VAR_INTEGER:
                {
                    g_EntityFuncs.DispatchKeyValue( pTo.edict(), this.Key, string( kv.GetInteger() ) );
                    return true;
                }
                case Entvartype::VAR_FLOAT:
                {
                    g_EntityFuncs.DispatchKeyValue( pTo.edict(), this.Key, string( kv.GetFloat() ) );
                    return true;
                }
                case Entvartype::VAR_STRING:
                {
                    g_EntityFuncs.DispatchKeyValue( pTo.edict(), this.Key, kv.GetString() );
                    return true;
                }
                case Entvartype::VAR_VECTOR:
                {
                    g_EntityFuncs.DispatchKeyValue( pTo.edict(), this.Key, kv.GetVector().ToString() );
                    return true;
                }
            }
        }
        return false;
    }

    bool CopyOver( CBaseEntity@ pFrom, CBaseEntity@ pTo ) const
    {
        return ( pFrom !is null && pTo !is null && this.CopyOver( pFrom.GetCustomKeyvalues(), pTo ) );
    }

    CustomKeyValues() {}
    CustomKeyValues( const string &in keyName )
    {
        this.m_KeyName = keyName;
    }
}

namespace CustomKeyValues
{
    array<const CustomKeyValues@> __KeyValues__;

    const array<const CustomKeyValues@>@ GetCustomKeyvalues()
    {
        return @__KeyValues__;
    }

    void Register( const string&in keyName )
    {
        if( g_Logger.info.active )
        {
            g_Logger.info.print( "Registering custom keyvalue \"{}\" to copy over from squadmakers", { keyName } );
        }

        CustomKeyValues ckv( keyName );
        __KeyValues__.insertLast( @ckv );
    }
}
