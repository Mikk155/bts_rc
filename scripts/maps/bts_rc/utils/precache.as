namespace precache
{
    void sound( const string file )
    {
        string generic;
        snprintf( generic, "sound/%1", file );
        g_SoundSystem.PrecacheSound( file );
        g_Game.PrecacheGeneric( generic );
    }

    void generic( const string file )
    {
        g_Game.PrecacheGeneric( file );
    }

    void model( const string file )
    {
        g_Game.PrecacheModel( file );
        g_Game.PrecacheGeneric( file );
    }
}
