//Half-Life Weapon Base Code (Modified)
//Authors: Rizulix, Giegue, KernCore, Nero0

array<int> g_tracerCount( 33 );

edict_t@ ENT( const entvars_t@ pev )
{
	return pev.pContainingEntity;
}

mixin class HLWeaponUtils
{
		protected int m_iShotsFired = 0;
		protected bool m_fDropped;
		CBasePlayerItem@ DropItem() //drops the item
		{
			m_fDropped = true;
			return self;
		}
		private int SaveSecAmmo, ReloadedSecAmmo;
		protected float m_reloadTimer = 0, m_useTimer = 0;
		protected bool canReload;
		protected int m_iCurBodyConfig = 0;

		float WeaponTimeBase()
		{
			return g_Engine.time;
		}

		void GetDefaultShellInfo( Vector& out vecShellVelocity, Vector& out vecShellOrigin, float forwardScale, float upScale, float rightScale )
		{
			Vector forward, right, up;
			g_EngineFuncs.AngleVectors( m_pPlayer.pev.angles, forward, right, up );

			const float fR = Math.RandomFloat( 50.0, 70.0 );
			const float fU = Math.RandomFloat( 100.0, 150.0 );

			vecShellVelocity = m_pPlayer.pev.velocity + right * fR + up * fU + forward * 25.0;
			vecShellOrigin = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + up * upScale + forward * forwardScale + right * rightScale;
		}

		//Lost the addition of DMG_ALWAYSGIB to DMG_BULLET if iDamage > 16 and some cases for iBulletType
		void FireBulletsPlayer( uint cShots, Vector vecSrc, Vector vecDirShooting, Vector vecSpread, float flDistance, int iBulletType, int iTracerFreq )
		{
			TraceResult tr;
			float x, y;

			g_WeaponFuncs.ClearMultiDamage();

			for( uint iShot = 1; iShot <= cShots; iShot++ )
			{
				//Use player's random seed.
				//get circular gaussian spread
				x = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + iShot, -0.5, 0.5 ) + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + ( 1 + iShot ), -0.5, 0.5 );
				y = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + ( 2 + iShot ), -0.5, 0.5 ) + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + ( 3 + iShot ), -0.5, 0.5 );
				//There's a notable diference with g_Utility.GetCircularGaussianSpread( x, y)?

				Vector vecDir = vecDirShooting + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
				Vector vecEnd = vecSrc + vecDir * flDistance;

				g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

				if( iTracerFreq != 0 && ( g_tracerCount[ m_pPlayer.entindex() ]++ % iTracerFreq ) == 0 )
				{
					//YOINKED from:
					//https://github.com/KernCore91/-SC-Insurgency-Weapons-Project/blob/master/scripts/maps/ins2/base.as#L691-L692
					Vector vecAttachOrigin, vecAttachAngles;
					g_EngineFuncs.GetAttachment( m_pPlayer.edict(), 0, vecAttachOrigin, vecAttachAngles );

					Vector vecTracerSrc = vecAttachOrigin + g_Engine.v_forward * 64.0;

					NetworkMessage message( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc );
						message.WriteByte( TE_TRACER );
						message.WriteCoord( vecTracerSrc.x );
						message.WriteCoord( vecTracerSrc.y );
						message.WriteCoord( vecTracerSrc.z );
						message.WriteCoord( tr.vecEndPos.x );
						message.WriteCoord( tr.vecEndPos.y );
						message.WriteCoord( tr.vecEndPos.z );
					message.End();
				}

				//do damage, paint decals
				if( tr.flFraction < 1.0 )
				{
					if( tr.pHit !is null )
					{
						CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

						if( pHit !is null )
						{
							switch ( iBulletType )
							{
							case BULLET_PLAYER_357:
								pHit.TraceAttack( m_pPlayer.pev, g_EngineFuncs.CVarGetFloat('sk_plr_357_bullet'), vecEnd, tr, DMG_BULLET | DMG_NEVERGIB );
								break;

							case BULLET_PLAYER_EAGLE:
								//SC:66% of the magnum, OF:85% of the magnum; based on skillopfor.cfg
								pHit.TraceAttack( m_pPlayer.pev, g_EngineFuncs.CVarGetFloat('sk_plr_357_bullet') * 0.85, vecEnd, tr, DMG_BULLET | DMG_NEVERGIB );
								break;

							case BULLET_PLAYER_SAW:
								pHit.TraceAttack( m_pPlayer.pev, g_EngineFuncs.CVarGetFloat('sk_556_bullet'), vecEnd, tr, DMG_BULLET | DMG_NEVERGIB );
								break;

							case BULLET_PLAYER_SNIPER:
								pHit.TraceAttack( m_pPlayer.pev, g_EngineFuncs.CVarGetFloat('sk_plr_762_bullet'), vecEnd, tr, DMG_BULLET | DMG_NEVERGIB );
								break;
							}
						}

						g_SoundSystem.PlayHitSound( tr, vecSrc, vecEnd, iBulletType );

						if( pHit is null || pHit.IsBSPModel() )
							g_WeaponFuncs.DecalGunshot( tr, iBulletType );
					}
				}
				//make bullet trails
				g_Utility.BubbleTrail( vecSrc, tr.vecEndPos, int( ( flDistance * tr.flFraction ) / 64.0 ) );
			}
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
		}

		bool CommonAddToPlayer( CBasePlayer@ pPlayer ) //adds a weapon to the player
		{
			if( !BaseClass.AddToPlayer( pPlayer ) )
				return false;

			NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				weapon.WriteShort( g_ItemRegistry.GetIdForName( self.pev.classname ) );
			weapon.End();
			return true;
		}

		void CommonSpawn( const string worldModel, const int GiveDefaultAmmo ) //things that are commonly executed in spawn
		{
			m_iShotsFired = 0;
			g_EntityFuncs.SetModel( self, self.GetW_Model( worldModel ) );
			self.m_iDefaultAmmo = GiveDefaultAmmo;
			self.pev.scale = 1.4;

			self.FallInit();
		}

		bool CheckButton() //returns which key the player is pressing (that might interrupt the reload)
		{
			return m_pPlayer.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1) != 0;
		}

		bool Deploy( string vModel, string pModel, int iAnim, string pAnim, int iBodygroup, float flDeployTime ) //deploys the weapon
		{
			m_fDropped = false;
			self.DefaultDeploy( self.GetV_Model( vModel ), self.GetP_Model( pModel ), iAnim, pAnim, 0, iBodygroup );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + flDeployTime;
			return true;
		}

		void CommonHolster() //things that plays on holster
		{
			self.m_fInReload = false;
			SetThink( null );

			m_iShotsFired = 0;
			m_pPlayer.pev.fuser4 = 0;
		}

		void CreateMuzzleflash( string szSprite, float flForward, float flRight, float flUp, float flScale, float flRenderamt, float flFramerate, float flRotation = 0.0, int iRenderMode = kRenderTransAdd )
		{
			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			CSprite@ pMuzzle = g_EntityFuncs.CreateSprite( szSprite, m_pPlayer.GetGunPosition() + g_Engine.v_forward * flForward + g_Engine.v_right * flRight + g_Engine.v_up * flUp, true );
			@pMuzzle.pev.owner = m_pPlayer.edict();
			pMuzzle.SetScale( flScale );
			pMuzzle.SetTransparency( iRenderMode, 255, 255, 255, int( flRenderamt ), kRenderFxNone );

			if( flRotation > 0.0 )
			{
				pMuzzle.KeyValue( "vp_type", "VP_TYPE::VP_ORIENTATED" );
				pMuzzle.pev.angles = Vector( 0.0, 0.0, flRotation );
			}

			pMuzzle.AnimateAndDie( flFramerate );
		}

		void get_position( float flForward, float flRight, float flUp, Vector &out vecOut )
		{
			Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

			vecOrigin = m_pPlayer.pev.origin;
			vecUp = m_pPlayer.pev.view_ofs; //GetGunPosition() ??
			vecOrigin = vecOrigin + vecUp;

			vecAngle = m_pPlayer.pev.v_angle; //if normal entity: use pev.angles

			g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

			vecOut = vecOrigin + vecForward * flForward + vecRight * flRight + vecUp * flUp;
	}

}

mixin class FlareWeaponExplode
{
	void DestroyThink() //destroys the item
	{
		SetThink( null );
		self.DestroyItem();
		//g_Game.AlertMessage( at_console, "Item Destroyed.\n" );
	}
}
