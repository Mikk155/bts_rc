/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

namespace Precache
{
    weakref<Logger> m_logger = Logger::Register( "Precache" );

    void Precache()
    {
        Server::chrono chrono;

        Logger@ logger = m_logger.get();

        // These are used by the code
        models::WXplo1 = g_Game.PrecacheModel( "sprites/WXplo1.spr" );
        models::zerogxplode = g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
        models::steam1 = g_Game.PrecacheModel( "sprites/steam1.spr" );
        models::laserbeam = g_Game.PrecacheModel( "sprites/laserbeam.spr" );
        models::shell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );
        models::saw_shell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );
        models::shotgunshell = g_Game.PrecacheModel( "models/hlclassic/shotgunshell.mdl" );
        models::xsmoke4 = g_Game.PrecacheModel( "sprites/xsmoke4.spr" );
        models::fthrow = g_Game.PrecacheModel( "sprites/bts_rc/fthrow.spr" );

        // <Precache start>
        // DO NOT ADD NEW ENTRIES HERE!
        // The code in between <Precache start/end> will get purged in release.
        // The paths defined in assets.json will be pasted here without the use of JSON.
        // Modify assets.json and then run src/main.py.
        dictionary assets;

        if( !meta_api::json::v1::Deserialize( "bts_rc/assets.json", assets ) )
        {
            if( logger !is null && logger.critical.active )
                logger.critical( "Failed read assets file! The map will crash for non-precached assets!" );
        }

        dictionary@ list;
        uint length;

        @list = cast<dictionary@>( assets[ "PrecacheModel" ] );
        length = list.getSize();
        for( uint ui = 0; ui < length; ui++ ) {
            g_Game.PrecacheModel( string( list[ string( ui ) ] ) );
        }

        @list = cast<dictionary@>( assets[ "PrecacheGeneric" ] );
        length = list.getSize();
        for( uint ui = 0; ui < length; ui++ ) {
            g_Game.PrecacheGeneric( string( list[ string( ui ) ] ) );
        }

        @list = cast<dictionary@>( assets[ "PrecacheSound" ] );
        length = list.getSize();
        for( uint ui = 0; ui < length; ui++ ) {
            g_SoundSystem.PrecacheSound( string( list[ string( ui ) ] ) );
        }
        // <Precache end>

        if( logger !is null )
        {
            chrono.Stop();

            if( logger.info.active )
                logger.info( "Map assets finished precaching in {}.{} seconds.", chrono.Seconds, chrono.Miliseconds );

            logger.shutdown();
        }
    }
}
