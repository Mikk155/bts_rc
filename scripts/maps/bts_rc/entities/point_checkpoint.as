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

const bool Reg_point_checkpoint = CustomEntity( "point_checkpoint", true );

final class point_checkpoint : ScriptBaseAnimating
{
    uint m_state = 0;
    CSprite@ m_sprite;
    int m_iNextPlayerToRevive = 1;

    // When we started a respawn
    float m_flRespawnStartTime;

    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_TRIGGER;

        self.pev.framerate = 1.0f;

        g_EntityFuncs.SetModel( self, "models/bts_rc/furniture/lambda.mdl" );

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        g_EntityFuncs.SetSize( self.pev, Vector( -64, -64, -36 ), Vector( 64, 64, 36 ) );

        self.pev.sequence = 0;
        self.pev.frame = 0;
        self.ResetSequenceInfo();

        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void Touch( CBaseEntity@ pOther )
    {
        if( !pOther.IsPlayer() || self.pev.solid == SOLID_NOT )
            return;

        CBasePlayer@ player;

        while( MultiTouch( self, player ) )
        {
            g_PlayerFuncs.PrintKeyBindingString( player, "Press the USE key +use to activate\n" );

            if( ( pOther.pev.button & IN_USE ) != 0 )
            {
                self.pev.solid = SOLID_NOT;

                string message;
                snprintf( message, "Player %1 reached a checkpoint.\n", string( pOther.pev.netname ) );
                g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, message );

                g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "bts_rc/music/bts_rc_checkpoint.ogg", 1.0f, ATTN_NONE );

                self.pev.rendermode = kRenderTransTexture;
                self.pev.renderamt = 255;

                this.m_state++;

                g_EntityFuncs.FireTargets( string( self.pev.target ), self, pOther, USE_TOGGLE );
                break;
            }
        }
    }

    void Think()
    {
        self.pev.nextthink = g_Engine.time + 0.1;

        switch( this.m_state )
        {
            case 0:
            {
                self.StudioFrameAdvance();
                break;
            }
            case 1:
            {
                if( self.pev.renderamt > 0 )
                {
                    self.StudioFrameAdvance();

                    self.pev.renderamt -= 30;

                    if( self.pev.renderamt < 0 )
                        self.pev.renderamt = 0;

                    break;
                }

                this.m_state++;
                self.pev.nextthink = g_Engine.time + 3.0f;
                m_flRespawnStartTime = g_Engine.time;
                self.pev.effects |= EF_NODRAW;
                break;
            }
            case 2:
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "debris/beamstart7.wav", 1.0f, ATTN_NORM );
                @m_sprite = g_EntityFuncs.CreateSprite( "sprites/exit1.spr", self.pev.origin, true, 10 );
                m_sprite.TurnOn();
                m_sprite.pev.rendermode = kRenderTransAdd;
                m_sprite.pev.renderamt = 128;
                this.m_state++;
                break;
            }
            case 3:
            {
                CBasePlayer@ player;

                for( ; m_iNextPlayerToRevive <= g_Engine.maxClients; ++m_iNextPlayerToRevive )
                {
                    @player = g_PlayerFuncs.FindPlayerByIndex( m_iNextPlayerToRevive );

                    // Only respawn if the player died before this checkpoint was activated
                    // Prevents exploitation
                    if( player !is null && !player.IsAlive() && player.m_fDeadTime < m_flRespawnStartTime )
                    {
                        // Revive player and move to this checkpoint
                        player.GetObserver().RemoveDeadBody();
                        player.SetOrigin( self.pev.origin );
                        player.Revive(); // -TODO Pass self here if 5.27 brings it.

                        if( util::GetClass(player) == Classification::Unset )
                            SetRandomClass( player, { Classification::Security, Classification::Scientist, Classification::Maintenance, Classification::Operative } );

                        if( !player.HasWeapons() )
                            EquipPlayer( player );

                        string classifyName;
                        switch( util::GetClass( player ) )
                        {
                            case Classification::Security: classifyName = "Security";
                            case Classification::Scientist: classifyName = "Scientist";
                            case Classification::Maintenance: classifyName = "Maintenance";
                            case Classification::Operative: classifyName = "Operative";
                        }
                        string message;
                        snprintf( message, "Player %1 entered the simulation as %2.\n", string( player.pev.netname ), classifyName );
                        g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, message );

                        // Congratulations, and celebrations, YOU'RE ALIVE!
                        g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "debris/beamstart4.wav", 1.0f, ATTN_NORM );

                        ++m_iNextPlayerToRevive; // Make sure to increment this to avoid unneeded loop
                        break;
                    }
                }

                // All players have been checked, close portal after 5 seconds.
                if( m_iNextPlayerToRevive > g_Engine.maxClients )
                {
                    this.m_state++;
                    self.pev.nextthink = g_Engine.time + 5.0f;
                }
                // Another player could require reviving
                else
                {
                    // Longer intervals while less players. range of 0.3 for 32 players, 4.8 for 2 players
                    self.pev.nextthink = g_Engine.time + ( 9.6f / float( g_PlayerFuncs.GetNumPlayers() ) );
                }
                break;
            }
            case 4:
            {
                this.m_state++;
                g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "ambience/port_suckout1.wav", 1.0f, ATTN_NORM );
                self.pev.nextthink = g_Engine.time + 3.0f;
                break;
            }
            case 5:
            {
                g_EntityFuncs.Remove( m_sprite );
                SetThink( null );
                self.pev.flags |= FL_KILLME;
                break;
            }
        }
    }
}
