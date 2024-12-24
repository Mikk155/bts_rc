namespace precache
{
    void sound( const string&in file )
    {
        string generic;
        snprintf( general, "sound/%1", file );
        g_SoundSystem.PrecacheSound( file );
        g_Game.PrecacheGeneric( file );
    }

    void generic( const string&in file )
    {
        g_Game.PrecacheGeneric( file );
    }

    void model( const string&in file )
    {
        g_Game.PrecacheModel( file );
        g_Game.PrecacheGeneric( file );
    }
}
