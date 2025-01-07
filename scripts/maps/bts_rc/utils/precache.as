namespace precache
{
    void sound( const string file )
    {
        string generic;
        snprintf( generic, "sound/%1", file );
        g_SoundSystem.PrecacheSound( file );
        g_Game.PrecacheGeneric( generic );
    }

    void sounds( const array<string> files )
    {
        for( uint ui = 0; ui < files.length(); ui++ )
        {
            precache::sound( files[ui] );
        }
    }
}
