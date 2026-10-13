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
    ASCommand@ func_target_command = null;

    final class func_target : ScriptBaseEntity
    {
        private
            HUDTextParams m_HUDParams;

        void Spawn()
        {
            if( func_target_command is null )
            {
                @func_target_command = RegisterCommand(
                    "target speed",
                    "<float for think rate>",
                    "Set speed of firing range targets",
                    function( CBasePlayer@ player, array<string>@ arguments )
                    {
                        float speed = ( arguments !is null && arguments.length() > 0 ? Math.clamp( 0.01f, 1.0f, atof( arguments[0] ) ) : 0 );

                        g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Set targets speed to " + speed + "\n" );

                        CBaseEntity@ entity = null;

                        while( (@entity = g_EntityFuncs.FindEntityByClassname( entity, "func_target" ) ) !is null )
                        {
                            entity.pev.armortype = speed;
                        }
                    }, true, "test"
                );
            }

            self.pev.solid = SOLID_BSP;
            self.pev.movetype = MOVETYPE_PUSHSTEP;

            g_EntityFuncs.SetModel( self, string( self.pev.model ) );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );

            self.pev.takedamage = DAMAGE_YES;
            self.pev.health = self.pev.max_health = 999;

            this.m_HUDParams.x = -1;
            this.m_HUDParams.effect = 0;
            this.m_HUDParams.r1 = RGBA_SVENCOOP.r;
            this.m_HUDParams.g1 = RGBA_SVENCOOP.g;
            this.m_HUDParams.b1 = RGBA_SVENCOOP.b;
            this.m_HUDParams.a1 = 0;
            this.m_HUDParams.r2 = RGBA_SVENCOOP.r;
            this.m_HUDParams.g2 = RGBA_SVENCOOP.g;
            this.m_HUDParams.b2 = RGBA_SVENCOOP.b;
            this.m_HUDParams.a2 = 0;
            this.m_HUDParams.fadeinTime = 0;
            this.m_HUDParams.fadeoutTime = 0.25;
            this.m_HUDParams.fxTime = 0;
            this.m_HUDParams.holdTime = 2;
            this.m_HUDParams.channel = 3;
            this.m_HUDParams.y = 0.80;

            self.pev.nextthink = g_Engine.time + 1.0f;
            self.pev.armortype = 0.1f;
            SetThink( ThinkFunction( this.Think ) );

            if( self.pev.owner is null )
            {
                Vector vecPos = self.pev.origin;
                vecPos.z += 100;
                CBaseEntity@ moving = g_EntityFuncs.Create( self.GetClassname(), vecPos, self.pev.angles, true, self.edict() );
                moving.pev.model = self.pev.model;
                moving.pev.message = self.pev.message;
                g_EntityFuncs.DispatchSpawn( moving.edict() );
                @moving.pev.owner = self.edict();
            }
        }

        void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType )
        {
            CBaseEntity@ attacker;
            CBasePlayer@ player;

            if( pevAttacker is null || ( @attacker = g_EntityFuncs.Instance( pevAttacker ) ) is null )
                return;

            if( ( @player = cast<CBasePlayer@>( attacker ) ) is null )
                return;

            string message;
            snprintf( message, "%1 at %2 units distance.\n", string( self.pev.message ), int( ( self.pev.origin - player.pev.origin ).Length() ) );
            g_PlayerFuncs.HudMessage( player, m_HUDParams, message );
            BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
        }

        private
            bool m_Direction;

        void Think()
        {
            if( self.pev.owner !is null )
            {
                if( m_Direction )
                {
                    if( self.pev.origin.y <= self.pev.owner.vars.origin.y - 60.0f )
                    {
                        m_Direction = false;
                    }
                    self.pev.origin.y -= 5.0f;
                    self.pev.velocity.y = 200;
                }
                else
                {
                    if( self.pev.origin.y >= self.pev.owner.vars.origin.y + 60.0f )
                    {
                        m_Direction = true;
                    }
                    self.pev.origin.y += 5.0f;
                    self.pev.velocity.y = 200;
                }
                g_EntityFuncs.SetOrigin( self, self.pev.origin );
            }

            if( g_Engine.time > self.pev.armorvalue )
            {
                self.pev.rendermode = RenderModes::kRenderNormal;
                self.pev.rendercolor.y = 0;
            }

            self.pev.nextthink = g_Engine.time + self.pev.armortype;
        }

        int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
        {
            self.pev.rendermode = RenderModes::kRenderTransColor;
            self.pev.renderamt = 120;
            self.pev.rendercolor.y = 255;
            self.pev.health = self.pev.max_health;
            self.pev.armorvalue = g_Engine.time + 1.0;
            return 0;
        }
    }
}
