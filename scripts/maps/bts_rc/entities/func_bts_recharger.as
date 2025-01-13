/*
    Author: Giegue
    Modified by Mikk
*/

namespace func_bts_recharger
{
    int register = LINK_ENTITY_TO_CLASS( "func_bts_recharger", "func_bts_recharger" );

    class func_bts_recharger : ScriptBaseEntity
    {
        float m_flNextCharge; 
        int m_iReactivate; // DeathMatch Delay until reactvated
        int m_iJuice = 30;
        int CustomRechargeTime = -1;
        int m_iOn; // 0 = off, 1 = startup, 2 = going
        float m_flSoundTime;
        string_t fire_on_empty;
        string_t fire_on_refilled;
        
        void Spawn()
        {
            Precache();
            
            self.pev.solid = SOLID_BSP;
            self.pev.movetype = MOVETYPE_PUSH;
            
            g_EntityFuncs.SetOrigin( self, self.pev.origin ); // set size and link into world
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
            g_EntityFuncs.SetModel( self, self.pev.model );
            
            self.pev.frame = 0; 
        }
        
        bool KeyValue( const string& in szKeyName, const string& in szValue )
        {
            if( "CustomJuice" == szKeyName )
            {
                m_iJuice = atoi( szValue );
            }
            else if( "CustomRechargeTime" == szKeyName )
            {
                CustomRechargeTime = atoi( szValue );
            }
            else if( "TriggerOnEmpty" == szKeyName )
            {
                fire_on_empty = string_t(szValue);
            }
            else if( "TriggerOnRecharged" == szKeyName )
            {
                fire_on_refilled = string_t(szValue);
            }
            else
            {
                return BaseClass.KeyValue( szKeyName, szValue );
            }
            return true;
        }

        void Precache()
        {
            g_SoundSystem.PrecacheSound( "items/suitcharge1.wav" );
            g_SoundSystem.PrecacheSound( "items/suitchargeno1.wav" );
            g_SoundSystem.PrecacheSound( "items/suitchargeok1.wav" );
        }
        
        int ObjectCaps()
        {
            return ( BaseClass.ObjectCaps() | FCAP_CONTINUOUS_USE ) & ~FCAP_ACROSS_TRANSITION;
        }
        
        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
        {
            // Make sure that we have a caller
            if ( pActivator is null )
                return;
            // if it's not a player, ignore
            if ( !pActivator.IsPlayer() )
                return;
            
            // if there is no juice left, turn it off
            if ( m_iJuice <= 0 )
            {
                self.pev.frame = 1;         
                Off();
            }
            
            // if there is no juice left, make the deny noise
            if ( m_iJuice <= 0 )
            {
                if ( m_flSoundTime <= g_Engine.time )
                {
                    m_flSoundTime = g_Engine.time + 0.62;
                    g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeno1.wav", 1.0, ATTN_NORM );
                }
                return;
            }
            
            self.pev.nextthink = self.pev.ltime + 0.25;
            SetThink( ThinkFunction( Off ) );

            // Time to recharge yet?
            
            if ( m_flNextCharge >= g_Engine.time )
                return;
            
            // Play the on sound or the looping charging sound
            if ( m_iOn == 0 )
            {
                m_iOn++;
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM );
                m_flSoundTime = 0.56 + g_Engine.time;
            }
            if ( m_iOn == 1 && m_flSoundTime <= g_Engine.time )
            {
                m_iOn++;
                g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "items/suitcharge1.wav", 1.0, ATTN_NORM );
            }
            
            
            // charge the player
            if ( pActivator.TakeArmor( 1, DMG_GENERIC ) )
            {
                m_iJuice--;
            }
            
            // govern the rate of charge
            m_flNextCharge = g_Engine.time + 0.1;
        }
        
        void Recharge()
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM );
            m_iJuice = 30;
            self.pev.frame = 0;         
            SetThink( ThinkFunction( dummythink ) );
        }
        
        void Off()
        {
            // Stop looping sound.
            if ( m_iOn > 1 )
                g_SoundSystem.StopSound( self.edict(), CHAN_STATIC, "items/suitcharge1.wav" );
            
            m_iOn = 0;
            
            if ( m_iJuice == 0 && ( m_iReactivate = 30 ) > 0 )
            {
                self.pev.nextthink = self.pev.ltime + m_iReactivate;
                SetThink( ThinkFunction( Recharge ) );
            }
            else
                SetThink( ThinkFunction( dummythink ) );
        }
        
        void dummythink()
        {
            // Dummy
        }
    }
}
