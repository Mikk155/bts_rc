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

namespace test_chamber
{
    TextMenu::v1::Menu g_Sections;
    array<EHandle> g_SectionEntities;

    final class info_section : ScriptBaseEntity
    {
        private
            TextMenu::v1::MenuOption@ m_option;

        TextMenu::v1::MenuOption@ GetOption() const
        {
            return this.m_option;
        }

        private
            void MenuOptionSelect( CBasePlayer@ player, TextMenu::v1::MenuOption@ option )
            {
                if( player is null )
                    return;

                g_EntityFuncs.SetOrigin( player, self.pev.origin );
                player.pev.fixangle = FixAngleMode::FAM_FORCEVIEWANGLES;
                player.pev.v_angle = player.pev.angles = self.pev.angles;
                player.pev.velocity = g_vecZero;

                g_EntityFuncs.FireTargets( string( self.pev.target ), player, self, USE_TOGGLE, 0.0f );
            }

        private
            TextMenu::v1::MenuOptionSelect@ m_callback = @TextMenu::v1::MenuOptionSelect( this.MenuOptionSelect );

        void Spawn()
        {
            @this.m_option = g_Sections.AddOption();

            this.m_option.Text
                .Write( string( self.pev.netname ) )
                .Write( string( self.pev.message ) )
                .ResetColor();

            this.m_option.SetCallback( m_callback );

            g_SectionEntities.insertLast( EHandle( self ) );

            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.origin.z += 37;
        }

        void UpdateOnRemove()
        {
            if( m_option !is null )
            {
                array<TextMenu::v1::MenuOption@>@ options = g_Sections.Options;

                if( options !is null )
                {
                    int index = options.findByRef( this.m_option );

                    if( index >= 0 )
                    {
                        options.removeAt( index );
                    }
                }
            }
        }
    }

    void SortSections()
    {
        array<TextMenu::v1::MenuOption@> sortedOptions;
        array<int> priorities;

        for( uint ui = 0; ui < g_SectionEntities.length(); )
        {
            EHandle handle = g_SectionEntities[ui];

            if( !handle.IsValid() )
            {
                g_SectionEntities.removeAt( ui );
                continue;
            }

            CBaseEntity@ entity = handle.GetEntity();

            if( entity is null )
            {
                g_SectionEntities.removeAt( ui );
                continue;
            }

            info_section@ section = cast<info_section@>( CastToScriptClass( entity ) );

            if( section is null || section.GetOption() is null )
            {
                g_SectionEntities.removeAt( ui );
                continue;
            }

            sortedOptions.insertLast( section.GetOption() );
            priorities.insertLast( int( entity.pev.health ) );
            ui++;
        }

        for( uint ui = 0; ui < sortedOptions.length(); ui++ )
        {
            for( uint uj = 0; uj + 1 < sortedOptions.length() - ui; uj++ )
            {
                int current = priorities[uj];
                int next = priorities[uj + 1];
                bool nextBeforeCurrent = ( next != 0 && ( current == 0 || next < current ) );

                if( nextBeforeCurrent )
                {
                    int priority = priorities[uj];
                    priorities[uj] = priorities[uj + 1];
                    priorities[uj + 1] = priority;

                    TextMenu::v1::MenuOption@ option = sortedOptions[uj];
                    @sortedOptions[uj] = sortedOptions[uj + 1];
                    @sortedOptions[uj + 1] = option;
                }
            }
        }

        array<TextMenu::v1::MenuOption@>@ options = g_Sections.Options;

        for( uint ui = 0; ui < options.length(); ui++ )
        {
            if( sortedOptions.findByRef( options[ui] ) < 0 )
            {
                sortedOptions.insertLast( options[ui] );
            }
        }

        options.resize( 0 );

        for( uint ui = 0; ui < sortedOptions.length(); ui++ )
        {
            options.insertLast( sortedOptions[ui] );
        }
    }
}
