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
    TextMenu::v1::Menu g_Sections;

    final class info_section : ScriptBaseEntity
    {
        private
            TextMenu::v1::MenuOption@ m_option;

        private
            void MenuOptionSelect( CBasePlayer@ player, const TextMenu::v1::MenuOption@ option )
            {
                if( player is null )
                    return;

                g_EntityFuncs.SetOrigin( player, self.pev.origin + player.pev.view_ofs );
                player.pev.fixangle = FixAngleMode::FAM_FORCEVIEWANGLES;
                player.pev.v_angle = player.pev.angles = self.pev.angles;

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

            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;
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
}
#endif
