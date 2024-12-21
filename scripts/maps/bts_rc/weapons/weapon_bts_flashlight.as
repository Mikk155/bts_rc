// Flashlight/Torchlight
// Original Code: Mikk
// Models: Valve Software, Gearbox Software, dydwk747, ruMpel (Battery model)
// Sprites: Patofan05
// Thanks Mikk for scripting full support

namespace BTS_FLASHLIGHT
{

enum BTSFlashlightAnimation
{
	IDLE = 0,
	DRAW,
	HOLSTER,
	ATTACK1HIT,
	ATTACK1MISS,
	ATTACK2MISS,
	ATTACK2HIT,
	ATTACK3MISS,
	ATTACK3HIT,
	IDLE2,
	IDLE3
};

const int MAX_AMMO = 60;														// max flashlight battery amount
const int DEFAULT_GIVE = 10;													// default ammo given to the player when first acquired flashlight
const bool g_bShowFlashlightToAll = true;										// flashlight light can be seen by other players
const float LIGHT_DISTANCE = 3072.0f;											// how far the light could shine from player position
const string MODEL_AMMO  = "models/bts_rc/furniture/w_flashlightbattery.mdl"; 	// ammo/battery model
const int DRAIN_RATE = 880;														// rate of flashlight drain
const int MAX_GIVE   = 5;														// default ammo given to the player when pickup flashlight's battery

const string V_MODEL = "models/bts_rc/weapons/v_flashlight.mdl";

class weapon_bts_flashlight : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	// State of the flashlight
	bool m_bIsFlashlightOn;

	private TraceResult tr;
	private float m_flNextFlashlightTime;
	private int m_iNextDainTime;
	private CBasePlayer@ m_pPlayer;
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

	void ItemPreFrame()
	{
		if( g_Engine.time > m_flNextFlashlightTime )
		{
			if( m_bIsFlashlightOn )
			{
				g_Utility.TraceLine( m_pPlayer.GetGunPosition(), m_pPlayer.GetGunPosition() + g_Engine.v_forward * LIGHT_DISTANCE, dont_ignore_monsters, m_pPlayer.edict(), tr );

				if( g_bShowFlashlightToAll )
				{
					NetworkMessage flon( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
						flon.WriteByte( TE_DLIGHT );
						flon.WriteCoord( tr.vecEndPos.x );
						flon.WriteCoord( tr.vecEndPos.y );
						flon.WriteCoord( tr.vecEndPos.z );
						flon.WriteByte( 9 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 1 );
						flon.WriteByte( 1 );
					flon.End();
				}
				else
				{
					NetworkMessage flon( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
						flon.WriteByte( TE_DLIGHT );
						flon.WriteCoord( tr.vecEndPos.x );
						flon.WriteCoord( tr.vecEndPos.y );
						flon.WriteCoord( tr.vecEndPos.z );
						flon.WriteByte( 9 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 1 );
						flon.WriteByte( 1 );
					flon.End();
				}

				if( m_iNextDainTime > DRAIN_RATE )
				{
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
					m_iNextDainTime = 0;
				}
				else
					m_iNextDainTime++;

				if( !HasBattery() )
					m_bIsFlashlightOn = false;
			}

			m_flNextFlashlightTime = g_Engine.time + 0.0125f; //torchlight's dynamic light flickering per seconds (originally 0.1)
		}

		BaseClass.ItemPreFrame();
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel(self, "models/bts_rc/weapons/w_flashlight.mdl");
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		self.m_flCustomDmg	= self.pev.dmg;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_flashlight.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_flashlight.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_flashlight.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
		
		g_SoundSystem.PrecacheSound( "bts_rc/items/flashlight1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/items/battery_pickup1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/flashlight_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/flashlight_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/flashlight_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/flashlight_miss1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/flashlight_hit1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/flashlight_hit2.wav" );

		g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/" + pev.classname + ".txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = MAX_AMMO;
		info.iMaxAmmo2 = -1;
        info.iAmmo1Drop = MAX_GIVE;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 4;
		info.iPosition = 4;
		info.iWeight = 10;
		info.iFlags = ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		return true;
	}

	bool AddToPlayer(CBasePlayer@ pPlayer)
	{
		if ( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		@m_pPlayer = pPlayer;
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
		message.WriteLong( self.m_iId );
		message.End();
		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/flashlight1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	bool Deploy()
	{
		m_bIsFlashlightOn = false;
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_flashlight.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_flashlight.mdl" ), DRAW, "hive", 0, GetBodygroup());
	}

	bool HasBattery()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0  )
		{
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return false;
		}
		return true;
	}

	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}

		self.m_flNextPrimaryAttack = g_Engine.time + 0.375f;
	}

	void SecondaryAttack()
	{
		if( !HasBattery() )
			return;

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/flashlight1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		self.SendWeaponAnim( IDLE2, 0, GetBodygroup() );

		m_bIsFlashlightOn = !m_bIsFlashlightOn;

		self.m_flNextPrimaryAttack = g_Engine.time + 0.3f;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.3f;
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
					self.SendWeaponAnim( ATTACK1MISS, 0, GetBodygroup() ); break;
				case 1:
					self.SendWeaponAnim( ATTACK2MISS, 0, GetBodygroup() ); break;
				case 2:
					self.SendWeaponAnim( ATTACK3MISS, 0, GetBodygroup() ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

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
				self.SendWeaponAnim( ATTACK1HIT, 0, GetBodygroup() ); break;
			case 1:
				self.SendWeaponAnim( ATTACK2HIT, 0, GetBodygroup() ); break;
			case 2:
				self.SendWeaponAnim( ATTACK3HIT, 0, GetBodygroup() ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = 7;
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
				self.m_flNextPrimaryAttack = g_Engine.time + 0.3; //0.25

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
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod3.wav", 1, ATTN_NORM ); break;
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
				
				self.m_flNextPrimaryAttack = g_Engine.time + 0.3; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
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

    void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 3 ) )
		{
		case 0:	
			iAnim = IDLE3;	
			break;
		
		case 1:
			iAnim = IDLE2;
			break;
			
		default:
			iAnim = IDLE;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  6, 8 );// how long till we do this again.
	}
}

class ammo_bts_battery : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 0.75; //1.0

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = MAX_GIVE;

		if( pOther.GiveAmmo( iGive, "flashlightbattery", MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/items/battery_pickup1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetFlashlightName()
{
	return "weapon_bts_flashlight";
}

string GetFlashlightAmmoName()
{
    return "ammo_bts_battery";
}

void RegisterBTSFlashlight()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::weapon_bts_flashlight", GetFlashlightName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::ammo_bts_battery", GetFlashlightAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetFlashlightName(), "bts_rc/weapons", "flashlightbattery", "", GetFlashlightAmmoName() );
}

}
// End namespace BTS_FLASHLIGHT
// if you wanna use this as a sample, go ahead and make sure credit the rightful owner.
// whoever tryna steal this original work and claimed it to be their own is a fucktard.