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

#if SERVER
namespace test_chamber
{
    array<func_section@> gpSectionList;

    class func_section : ScriptBaseEntity
    {
        HUDTextParams m_HUDParams;

        void Spawn()
        {
            self.pev.solid = SOLID_TRIGGER;
            self.pev.movetype = MOVETYPE_NONE;
            g_EntityFuncs.SetModel( self, string( self.pev.model ) );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );

            this.m_HUDParams.x = -1;
            this.m_HUDParams.effect = 0;
            this.m_HUDParams.r1 = 255;
            this.m_HUDParams.g1 = 100;
            this.m_HUDParams.b1 = 100;
            this.m_HUDParams.a1 = 0;
            this.m_HUDParams.r2 = 255;
            this.m_HUDParams.g2 = 100;
            this.m_HUDParams.b2 = 100;
            this.m_HUDParams.a2 = 0;
            this.m_HUDParams.fadeinTime = 0;
            this.m_HUDParams.fadeoutTime = 0.25;
            this.m_HUDParams.fxTime = 0;
            this.m_HUDParams.holdTime = 2;
            this.m_HUDParams.channel = 3;
            this.m_HUDParams.y = 0.90;

            gpSectionList.insertLast( this );
        }

        void UpdateOnRemove()
        {
            int found = gpSectionList.findByRef( this );

            if( found >= 0 )
                gpSectionList.removeAt( found );
        }

        CBaseEntity@ get_Entity()
        {
            return @self;
        }

        void Touch( CBaseEntity@ pOther )
        {
            if( pOther is null || !pOther.IsPlayer() )
                return;

            CBasePlayer@ player;

            while( MultiTouch( self, player ) )
            {
                dictionary@ data = player.GetUserData();

                if( g_Engine.time > float( data[ "section" ] ) )
                {
                    data[ "section" ] = g_Engine.time + 0.3f;
                    const int length = gpSectionList.length();
                    int current = gpSectionList.findByRef( this );

                    g_PlayerFuncs.PrintKeyBindingString( player, "prev: +use | next: +reload\n" );

                    if( ( player.pev.button & IN_USE ) != 0 )
                    {
                        current--;
                        if( current < 0 )
                            current = length - 1;
                    }
                    else if( ( player.pev.button & IN_RELOAD ) != 0 )
                    {
                        current++;
                        if( current >= length )
                            current = 0;
                    }

                    func_section@ section = gpSectionList[current];

                    if( self !is section.Entity )
                    {
                        g_EntityFuncs.SetOrigin( player, section.Entity.pev.origin );
                        player.pev.angles.y = section.Entity.pev.angles.y;
                        player.pev.fixangle = FixAngleMode::FAM_FORCEVIEWANGLES;
                    }

                    g_PlayerFuncs.HudMessage( player, section.m_HUDParams, string( section.Entity.pev.message ) );
                }
            }
        }
    }
}
#endif
