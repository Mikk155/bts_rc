/* 
* Emergency Fire Axe
*/
namespace HL_AXE
{

enum axe_e
{
	AXE_IDLE = 0,
	AXE_DRAW,
	AXE_HOLSTER,
	AXE_ATTACK1HIT,
	AXE_ATTACK1MISS,
	AXE_ATTACK2MISS,
	AXE_ATTACK2HIT,
	AXE_ATTACK3MISS,
	AXE_ATTACK3HIT
};

array<string> HEV =
{
	"bts_helmet"
};

const string V_MODEL = "models/bts_rc/weapons/v_axe.mdl";

class weapon_bts_axe : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer = null;
	
	int m_iSwing;
	TraceResult m_trHit;
	dictionary g_Models = 
	{
    	{ "bts_barney", 0 }, { "bts_otis", 0 },
	{ "bts_barney2", 0 }, { "bts_barney3", 0 },
    	{ "bts_scientist", 1 }, { "bts_scientist2", 1 },
	{ "bts_scientist3", 3 }, { "bts_scientist4", 1 },
	{ "bts_scientist5", 1 }, { "bts_scientist6", 1 },
    	{ "bts_construction", 2 }, { "bts_helmet", 4 }
	};

	int GetBodygroup()
	{
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

    	switch( int(g_Models[ modelName ]) )
    	{
        	case 0:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 0 );
            	break;
        	case 1:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 1 );
            	break;
        	case 2:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 2 );
            	break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 3 );
            	break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 4 );
            	break;
    	}

    return m_iCurBodyConfig;
}
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_axe.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/bts_rc/weapons/v_axe.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_axe.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_axe.mdl" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit2.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_miss1.wav" );

	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 8;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if ( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
		
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();
		
		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_axe.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_axe.mdl" ), AXE_DRAW, "crowbar", 0, GetBodygroup() );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = "";
		
		SetThink( null );
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}


	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
				case 0:
					self.SendWeaponAnim( AXE_ATTACK1MISS, 0, GetBodygroup() ); break;
				case 1:
					self.SendWeaponAnim( AXE_ATTACK2MISS, 0, GetBodygroup() ); break;
				case 2:
					self.SendWeaponAnim( AXE_ATTACK3MISS, 0, GetBodygroup() ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0:
				self.SendWeaponAnim( AXE_ATTACK1HIT, 0, GetBodygroup() ); break;
			case 1:
				self.SendWeaponAnim( AXE_ATTACK2HIT, 0, GetBodygroup() ); break;
			case 2:
				self.SendWeaponAnim( AXE_ATTACK3HIT, 0, GetBodygroup() ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = 20;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

            // for monsters or breakable entity smacking speed function
			if( pEntity !is null )
			{
				// difference in model for nextprimaryattack
				string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

				if ( HEV.find(modelName) >= 0 )
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				}
				else
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25
				}

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod3.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				// difference in model for nextprimaryattack
				string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

				if ( HEV.find(modelName) >= 0 )
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				}
				else
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25
				}
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
}

string GetAxeName()
{
	return "weapon_bts_axe";
}

void RegisterAxe()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_AXE::weapon_bts_axe", GetAxeName() );
	g_ItemRegistry.RegisterWeapon( GetAxeName(), "bts_rc/weapons" );
}

}
