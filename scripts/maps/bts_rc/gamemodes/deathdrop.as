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

class ASDeathDropConfig : IConfigurableContext
{
    dictionary m_Monsters;

    const string& GetName() const override {
        return "deathdrop";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Death drop",
            "description": "Defines item drop tables for entities using $_deathdrop with a value of these list names",
            "allOf":
            [
                "IConfigurableContext"
            ],
            "additionalProperties":
            {
                "type": "array",
                "items":
                {
                    "type": "string",
                    "description": "Entity classname to spawn. Empty string means no drop chance. 'grenade' is a special name and will spawn a timed grenade."
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
            return false;

        const auto listNames = config.Keys;

        foreach( auto listName : listNames )
        {
            if( listName == "active" )
                continue;

            array<string>@ itemNames;
            auto@ listObject = config[ listName ];

            if( meta_api::json::v2::fmt::ToArray( listObject, itemNames ) )
            {
                if( g_Logger.debug.active )
                    g_Logger.debug.print( snprintf( glog, "Adding %1 drops for \"%2\"", itemNames.length(), listName ) );
                @m_Monsters[ listName ] = itemNames;
            }
            else
            {
                g_Logger.error.print( snprintf( glog, "json deathdrop->%1 is not a valid array!", listName ) );
                continue;
            }

            // Precache
            foreach( auto itemName : itemNames )
            {
                if( !itemName.IsEmpty() && itemName != "grenade" )
                    g_Game.PrecacheOther( itemName );
            }

            // Just debug
            if( g_Logger.trace.active )
            {
                dictionary count;
                foreach( auto name : itemNames )
                {
                    count[ name ] = int( count[ name ] ) + 1;
                }

                foreach( auto value, auto key : count )
                {
                    g_Logger.trace.print( snprintf( glog, "\"%1\" %2 percent of droping %3.", listName, ( 100.0f / itemNames.length() ) * int( value ), ( key.IsEmpty() ? "nothing" : key ) ) );
                }
            }
        }

        @gpDeathDrop = this;

        return true;
    }

    CBaseEntity@ Create( CBaseMonster@ monster )
    {
        if( monster is null || !FreeEdicts( 1 ) )
            return null;

        auto ckv = monster.GetCustomKeyvalues();

        auto ckv_drop = ckv.GetKeyvalue( "$_deathdrop" );

        if( !ckv_drop.Exists() )
            return null;

        string listName = ckv_drop.GetString();

        string drop;

        if( listName[0] == '#' )
        {
            drop = listName.SubString(1);
        }
        else
        {
            array<string>@ drops;

            if( listName.Find( '.' ) != String::INVALID_INDEX )
            {
                array<string>@ randomListName = listName.Split( '.' );
                listName = randomListName[ Math.RandomLong( 0, randomListName.length() -1 ) ];
            }

            if( !m_Monsters.get( listName, @drops ) )
            {
                if( g_Logger.warning.active )
                    g_Logger.warning.print( snprintf( glog, "monster \"%1\" couldn't retrieve list with name \"%2\" at %3", monster.GetClassname(), listName, monster.GetOrigin().ToString() ) );
                return null;
            }

            if( drops is null || drops.length() <= 0 )
                return null;

            drop = drops[ Math.RandomLong( 0, drops.length() - 1 ) ];
        }

        if( drop.IsEmpty() )
            return null;

        Vector origin = monster.Center(), angles;
        
        auto ckv_attachment = ckv.GetKeyvalue( "$i_deathdrop" );

        if( ckv_attachment.Exists() )
            monster.GetAttachment( ckv_attachment.GetInteger(), origin, angles );

        if( g_Logger.debug.active )
            g_Logger.debug.print( snprintf( glog, "monster \"%1\" droping %2 at %3 ", monster.GetClassname(), drop, origin.ToString() ) );

        if( drop == "grenade" )
        {
            auto timed = g_EntityFuncs.ShootTimed( monster.pev, origin, Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
            return timed;
        }

        CBaseEntity@ item = g_EntityFuncs.Create( drop, origin, angles, false, monster.edict() );

        if( item !is null )
        {
            item.pev.spawnflags |= 1024; // no more respawn
        }

        return @item;
    }
}

ASDeathDropConfig@ gpDeathDrop = null;
