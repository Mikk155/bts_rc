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

/*
    Author Mikk
*/

final class ASWallRechargerConfig : IConfigurable
{
    int m_Juice;
    int m_RechargeTime;
    float m_SpeedRate;

    const string& GetName() const override
    {
        return "wall_recharger";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "HEV Charger",
            "description": "Configuration for wall-mounted HEV chargers.",
            "properties":
            {
                "juice":
                {
                    "type": "integer",
                    "minimum": 1,
                    "default": 35,
                    "description": "Maximun juice power per station."
                },
                "recharge_time":
                {
                    "type": "integer",
                    "minimum": 0,
                    "default": 300,
                    "description": "Time (In seconds) required to fully recharge. 0 means never recharge"
                },
                "speed_rate":
                {
                    "type": "number",
                    "minimum": 0.1,
                    "default": 0.35,
                    "description": "Charge transfer rate to player."
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/items/suitcharge1.wav" );
        g_SoundSystem.PrecacheSound( "items/suitchargeno1.wav" );
        g_SoundSystem.PrecacheSound( "items/suitchargeok1.wav" );
        CustomEntity( "func_bts_recharger" );

        this.m_Juice = int( config[ "juice" ] );
        this.m_RechargeTime = int( config[ "recharge_time" ] );
        this.m_SpeedRate = float( config[ "speed_rate" ] );

        return true;
    }
}

final class func_bts_recharger : ScriptBaseEntity
{
    private
        ASWallRechargerConfig@ m_Config = null;

    void Spawn()
    {
#if SERVER
        SetDebugName( self, "HEV/Hazard exclusive charger" );
#endif
        self.pev.solid = SOLID_BSP;
        self.pev.movetype = MOVETYPE_PUSH;
        g_EntityFuncs.SetOrigin( self, self.pev.origin ); // set size and link into world
        g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        g_EntityFuncs.SetModel( self, self.pev.model );

        @this.m_Config = cast<ASWallRechargerConfig@>( g_MapConfig.GetContext( "wall_recharger" ) );

        self.pev.iuser1 = this.m_Config.m_Juice;
    }

    int ObjectCaps()
    {
        return ( BaseClass.ObjectCaps() | FCAP_CONTINUOUS_USE );
    }

    void Restore()
    {
        self.pev.iuser1 = this.m_Config.m_Juice;
        self.pev.frame = 0;
        g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM );
    }

    void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        if( activator is null || !activator.IsAlive() || !activator.IsPlayer() )
            return;

        CBasePlayer@ player = cast<CBasePlayer@>( activator );

        if( player is null )
            return;

        dictionary@ data = activator.GetUserData();
        float cooldown = float( data[ "recharger_cooldown" ] );

        auto character = GetCharacter(player);

        if( self.pev.iuser1 <= 0 || character is null || ( !character.IsHazard && !character.IsHEV ) || player.pev.armorvalue >= player.pev.armortype )
        {
            if( cooldown <= g_Engine.time )
            {
                g_SoundSystem.EmitSound( player.edict(), CHAN_WEAPON, "items/suitchargeno1.wav", 1.0, ATTN_NORM );
                data[ "recharger_cooldown" ] = g_Engine.time + 0.62;
            }
            return;
        }

        if( g_Engine.time > cooldown + 1.0 )
        {
            g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM );
            data[ "recharger_cooldown" ] = g_Engine.time + 0.56;
        }
        else if( g_Engine.time > cooldown )
        {
            data[ "recharger_cooldown" ] = g_Engine.time + this.m_Config.m_SpeedRate;

            if( player.TakeArmor( 1, DMG_GENERIC ) )
                self.pev.iuser1--;

            if( self.pev.iuser1 <= 0 )
            {
                self.pev.frame = 1;
                g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "items/suitchargeno1.wav", 1.0, ATTN_NORM );

                if( this.m_Config.m_RechargeTime > 0 )
                    g_Scheduler.SetTimeout( @this, "Restore", this.m_Config.m_RechargeTime );
            }
            else
            {
                g_SoundSystem.EmitSound( player.edict(), CHAN_WEAPON, "bts_rc/items/suitcharge1.wav", 1.0, ATTN_NORM );
                g_Scheduler.SetTimeout( @this, "StopSound", this.m_Config.m_SpeedRate, EHandle( player ) );
            }
        }
    }

    void StopSound( EHandle hplayer )
    {
        auto entity = hplayer.GetEntity();

        if( entity !is null )
        {
            if( ( entity.pev.button & IN_USE ) == 0 || self.pev.iuser1 <= 0 )
                g_SoundSystem.StopSound( entity.edict(), CHAN_WEAPON, "bts_rc/items/suitcharge1.wav", true );
        }
    }
}
