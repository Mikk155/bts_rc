// Flare Projectile (Counter-Strike 1.6's Grenade Projectile Base Modified)
// Author: KernCore, Mikk, RaptorSKA

#include "../hl_utils"

namespace FLARE_PROJ
{

string DEFAULT_PROJ_NAME 	= "proj_flare";
string BOUNCE_SOUND      	= "bts_rc/weapons/flare_bounce.wav";
string FLARE_SOUND          = "bts_rc/weapons/flare_on.wav";

class CFlare : ScriptBaseMonsterEntity
{
	private float m_flBounceTime = 0, m_flNextAttack = 0;
	private bool m_bRegisteredSound = false;
	private CScheduledFunction@ SelfFlareLightSchedule = null; // dynamic lighting schedule
	private CScheduledFunction@ SelfFlareSparkSchedule = null; // env_sparks schedule

	void FlareSelfThink()
	{
		CreateLight( Vector( self.GetOrigin().x, self.GetOrigin().y, self.GetOrigin().z + 20.0f ) ); // flare lighting start appearing after detonate
	}

	void FlareSparkSelfThink()
	{
		CreateSparks( Vector( self.GetOrigin().x, self.GetOrigin().y, self.GetOrigin().z + 0.0f ) ); // env_sparks appear on the flare
	}

	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;

		self.pev.gravity = 0.55f;
		self.pev.friction = 0.7f;
		self.pev.framerate = 1.0f;

		SetThink( ThinkFunction( this.TumbleThink ) );
		self.pev.nextthink = g_Engine.time + 2.0f;

		g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );
	}

	void Precache()
	{
		//Models

		//Sounds
        g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flare_bounce.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flare_on.wav' );
	}

	void BounceTouch( CBaseEntity@ pOther )
	{
		// don't hit the guy that launched this flare
		if( @pOther.edict() == @self.pev.owner )
			return;

		// Only do damage if we're moving fairly fast
		if( m_flNextAttack < g_Engine.time && self.pev.velocity.Length() > 100 )
		{
			entvars_t@ pevOwner = @self.pev.owner.vars;
			if( pevOwner !is null )
			{
				TraceResult tr = g_Utility.GetGlobalTrace();
				g_WeaponFuncs.ClearMultiDamage();
				pOther.TraceAttack( pevOwner, 1, g_Engine.v_forward, tr, DMG_CLUB );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner );
			}
			m_flNextAttack = g_Engine.time + 1.0; // debounce
		}

		/*if( pOther.pev.ClassNameIs( "func_breakable" ) && pOther.pev.rendermode != kRenderNormal )
		{
			self.pev.velocity = self.pev.velocity * -2.0f;
			return;
		}*/

		Vector vecTestVelocity;
		// this is my heuristic for modulating the grenade velocity because grenades dropped purely vertical
		// or thrown very far tend to slow down too quickly for me to always catch just by testing velocity.
		// trimming the Z velocity a bit seems to help quite a bit.
		vecTestVelocity = self.pev.velocity;
		vecTestVelocity.z *= 0.7f;

		if( m_bRegisteredSound == false && vecTestVelocity.Length() <= 60.0f )
		{
			// grenade is moving really slow. It's probably very close to where it will ultimately stop moving.
			// go ahead and emit the danger sound.

			// register a radius louder than the explosion, so we make sure everyone gets out of the way
			GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, self.pev.origin, int(self.pev.dmg / 0.5), 0.3, self );
			//CSoundEnt::InsertSound ( bits_SOUND_DANGER, pev->origin, pev->dmg / 0.5, 0.3, this );
			m_bRegisteredSound = true;
		}

		if( self.pev.flags & FL_ONGROUND != 0 )
		{
			self.pev.velocity = self.pev.velocity * 0.8f;
			self.pev.sequence = 1;//Math.RandomLong( 1, 3 );
		}
		else
		{
			BounceSounds();
			self.pev.flags |= EF_NOINTERP;
		}

		self.pev.framerate = self.pev.velocity.Length() / 200.0f;

		if( self.pev.framerate > 1 )
			self.pev.framerate = 1.0f;
		else if( self.pev.framerate < 0.5f )
			self.pev.framerate = 0;
	}

	void BounceSounds()
	{
		if( g_Engine.time < m_flBounceTime )
			return;

		m_flBounceTime = g_Engine.time + Math.RandomFloat( 0.2, 0.3 );

		if( g_Utility.GetGlobalTrace().flFraction < 1.0 )
		{
			if( g_Utility.GetGlobalTrace().pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( g_Utility.GetGlobalTrace().pHit );
				if( pHit.IsBSPModel() )
				{
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, BOUNCE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				}
			}
		}
	}

    // Flare dropping/bouncing on the floor
	void TumbleThink()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		self.StudioFrameAdvance();
		self.pev.nextthink = g_Engine.time + 0.1;

		if( self.pev.dmgtime <= g_Engine.time )
		{
			SetThink( ThinkFunction( this.Detonate ) );
		}


		if( self.pev.waterlevel != WATERLEVEL_DRY )
		{
			self.pev.velocity = self.pev.velocity * 0.5;
			self.pev.framerate = 0.2;

			self.pev.angles = Math.VecToAngles( self.pev.velocity );
		}
	}

	void CreateLight( Vector& in origin )
	{
		NetworkMessage flare(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		        flare.WriteByte( TE_DLIGHT ); // temp entity you want to implement
				flare.WriteCoord( origin.x ); // vector x
				flare.WriteCoord( origin.y ); // vector y
				flare.WriteCoord( origin.z ); // vector z
				flare.WriteByte( 18 ); // Radius
				flare.WriteByte( int(255) ); // R
				flare.WriteByte( int(21) ); // G
				flare.WriteByte( int(18) ); // B
				flare.WriteByte( 1 ); // Life
				flare.WriteByte( 1 ); // Decay
			flare.End();
	}

	void CreateSparks( Vector& in origin )
	{
		NetworkMessage flarespark(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		        flarespark.WriteByte( TE_SPARKS );
				flarespark.WriteCoord( origin.x );
				flarespark.WriteCoord( origin.y );
				flarespark.WriteCoord( origin.z );
			flarespark.End();
	}

	void Detonate()
	{
		//self.pev.flags &= ~EF_BRIGHTLIGHT;
	    CreateLight( Vector( self.GetOrigin().x, self.GetOrigin().y, self.GetOrigin().z + 20.0f ) ); // Dynamic lighting implemented around the flare entity

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, FLARE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); // Flare sound play when detonate

		@SelfFlareLightSchedule = @g_Scheduler.SetInterval( @this, "FlareSelfThink", 0.0125f, 3300.0f ); // How much time the flare will last long

		@SelfFlareSparkSchedule = @g_Scheduler.SetInterval( @this, "FlareSparkSelfThink", 0.099, 590.0f ); // How long the env_sparks appear on the flare
	}


	void Killed( int skiplocal = 0 )
	{
		Detonate();
	}
}

CFlare@ TossGrenade( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity, float flTime, float flDmg, string sModel, const string& in szName = DEFAULT_PROJ_NAME )
{
	CBaseEntity@ cbeFlare = g_EntityFuncs.CreateEntity( szName );
	CFlare@ Flare = cast<CFlare@>( CastToScriptClass( cbeFlare ) );

	g_EntityFuncs.SetOrigin( Flare.self, vecStart );
	g_EntityFuncs.SetModel( Flare.self, sModel );
	g_EntityFuncs.DispatchSpawn( Flare.self.edict() );

	Flare.pev.velocity = vecVelocity;
	Flare.pev.angles = Math.VecToAngles( Flare.pev.velocity );
	@Flare.pev.owner = ENT( pevOwner );

	Flare.pev.dmg = flDmg;
	Flare.pev.sequence = Math.RandomLong( 3, 6 );

	Flare.SetTouch( TouchFunction( Flare.BounceTouch ) );

	if( flTime < 0.1 )
	{
		Flare.pev.nextthink = g_Engine.time;
		Flare.pev.velocity = g_vecZero;
	}
	Flare.pev.dmgtime = g_Engine.time + flTime;

	return Flare;
}

void Register( const string& in szName = DEFAULT_PROJ_NAME )
{
	if( g_CustomEntityFuncs.IsCustomEntity( szName ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "FLARE_PROJ::CFlare", szName );
	g_Game.PrecacheOther( szName );
}

}