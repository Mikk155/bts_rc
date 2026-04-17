/*
    Author: Giegue
    Modified by Mikk
*/

namespace func_bts_recharger
{
    class CConfig : IConfigContext
    {
        int juice = 35;
        int recharge_time = 300;
        float speed_rate = 0.35;

        CConfig()
        {
            ConfigContext::Register( this );
        }

        string GetName()
        {
            return "wall_recharger";
        }

        void Parse( dictionary@ json )
        {
            json.get( "juice", juice );
            json.get( "recharge_time", recharge_time );
            json.get( "speed_rate", speed_rate );

            g_CustomEntityFuncs.RegisterCustomEntity( "func_bts_recharger::func_bts_recharger", "func_bts_recharger" );
            g_SoundSystem.PrecacheSound( "bts_rc/items/suitcharge1.wav" );
            g_SoundSystem.PrecacheSound( "items/suitchargeno1.wav" );
            g_SoundSystem.PrecacheSound( "items/suitchargeok1.wav" );
        }
    }

    CConfig gpConfig;

    class func_bts_recharger : ScriptBaseEntity
    {
        void Spawn()
        {
            self.pev.solid = SOLID_BSP;
            self.pev.movetype = MOVETYPE_PUSH;
            g_EntityFuncs.SetOrigin( self, self.pev.origin ); // set size and link into world
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
            g_EntityFuncs.SetModel( self, self.pev.model );
            self.pev.iuser1 = gpConfig.juice;
        }

        int ObjectCaps() {
            return ( BaseClass.ObjectCaps() | FCAP_CONTINUOUS_USE );
        }

        void Restore()
        {
            self.pev.iuser1 = gpConfig.juice;
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

            if( self.pev.iuser1 <= 0 || !util::IsHEV( player ) || player.pev.armorvalue >= player.pev.armortype )
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
                data[ "recharger_cooldown" ] = g_Engine.time + gpConfig.speed_rate;

                if( player.TakeArmor( 1, DMG_GENERIC ) )
                    self.pev.iuser1--;

                if( self.pev.iuser1 <= 0 )
                {
                    self.pev.frame = 1;
                    g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "items/suitchargeno1.wav", 1.0, ATTN_NORM );
                    g_Scheduler.SetTimeout( @this, "Restore", gpConfig.recharge_time );
                }
                else
                {
                    g_SoundSystem.EmitSound( player.edict(), CHAN_WEAPON, "bts_rc/items/suitcharge1.wav", 1.0, ATTN_NORM );
                    g_Scheduler.SetTimeout( @this, "StopSound", gpConfig.speed_rate, EHandle( player ) );
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
}
