/* 
 * HECU Standard M249 SAW Light Machine Gun
 * Author: Rizulix
*/

#include '../hl_utils'

namespace CM249
{

enum m249_e
{
  SLOWIDLE = 0,
  IDLE2,
  RELOAD_START,
  RELOAD_END,
  HOLSTER,
  DRAW,
  SHOOT1,
  SHOOT2,
  SHOOT3
};

array<string> HEV =
{
  "bts_helmet"
};

// Weapon information
const int MAX_CARRY    = 150;
const int MAX_CLIP     = 100;
const int MAX_DROP     = Math.RandomLong( 25, 30); //23
const int DEFAULT_GIVE = Math.RandomLong( 19, 100 );
const int WEIGHT       = 20;

const string MODEL_AMMO = "models/w_saw_clip.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_saw.mdl";

// Spread thing
const CCVar@ g_M249WideSpread = CCVar('m249_wide_spread', 0, '', ConCommandFlag::AdminOnly); // as_command m249_wide_spread
// Knockback thing
const CCVar@ g_M249Knockback = CCVar('m249_knockback', 1, '', ConCommandFlag::AdminOnly); // as_command m249_knockback

class weapon_bts_saw : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
  private CBasePlayer@ m_pPlayer
  {
    get const { return cast<CBasePlayer>(self.m_hPlayer.GetEntity()); }
    set       { self.m_hPlayer = EHandle(@value); }
  }
  private float m_flNextAnimTime;
  private float m_flReloadStart;
  private bool m_bAlternatingEject = false;
  private bool m_bReloading;
  private int m_iShell;
  private int m_iLink;
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
    Precache();
    g_EntityFuncs.SetModel(self, self.GetW_Model('models/bts_rc/weapons/w_saw.mdl'));
    self.m_iDefaultAmmo = DEFAULT_GIVE;
    self.FallInit();
  }

  void Precache()
  {
    self.PrecacheCustomModels();
    g_Game.PrecacheModel('models/bts_rc/weapons/v_saw.mdl');
    g_Game.PrecacheModel('models/bts_rc/weapons/w_saw.mdl');
    g_Game.PrecacheModel('models/bts_rc/weapons/p_saw.mdl');
    g_Game.PrecacheModel(MODEL_AMMO);

    m_iShell = g_Game.PrecacheModel('models/bts_rc/weapons/saw_shell.mdl');
    m_iLink = g_Game.PrecacheModel('models/saw_link.mdl');

    g_SoundSystem.PrecacheSound('hlclassic/weapons/saw_reload.wav'); // default viewmodel; sequence: 2; frame: 1; event 5004
    g_SoundSystem.PrecacheSound('hlclassic/weapons/saw_reload2.wav'); // default viewmodel; sequence: 3; frame: 0; event 5004
    g_SoundSystem.PrecacheSound('bts_rc/weapons/gun_fire4.wav');
    g_SoundSystem.PrecacheSound('hlclassic/weapons/357_cock1.wav');

    g_Game.PrecacheGeneric('sound/hlclassic/weapons/saw_reload.wav');
    g_Game.PrecacheGeneric('sound/hlclassic/weapons/saw_reload2.wav');

    g_Game.PrecacheGeneric('sprites/bts_rc/weapons/' + pev.classname + '.txt');
  }

  bool GetItemInfo(ItemInfo& out info)
  {
    info.iMaxAmmo1 = MAX_CARRY;
    info.iMaxAmmo2 = -1;
    info.iAmmo1Drop = MAX_CLIP;
    info.iAmmo2Drop = -1;
    info.iMaxClip = MAX_CLIP;
    info.iFlags = 0;
    info.iSlot = 5;
    info.iPosition = 4;
    info.iId = g_ItemRegistry.GetIdForName(pev.classname);
    info.iWeight = WEIGHT;

    return true;
  }

  bool AddToPlayer(CBasePlayer@ pPlayer)
  {
    if(!BaseClass.AddToPlayer(pPlayer))
      return false;

    NetworkMessage message(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
      message.WriteLong(g_ItemRegistry.GetIdForName(pev.classname));
    message.End();

    return true;
  }

  bool PlayEmptySound()
  {
    if (self.m_bPlayEmptySound)
    {
      g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, 'hlclassic/weapons/357_cock1.wav', 0.8, ATTN_NORM, 0, PITCH_NORM);
      self.m_bPlayEmptySound = false;
      return false;
    }
    return false;
  }

  bool Deploy()
  {
    bool bResult = self.DefaultDeploy(self.GetV_Model('models/bts_rc/weapons/v_saw.mdl'), self.GetP_Model('models/bts_rc/weapons/p_saw.mdl'), DRAW, 'saw', 0, GetBodygroup());
    self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
    return bResult;
  }

  void Holster(int skiplocal = 0)
  {
    SetThink(null);

    m_bReloading = false;
    self.m_fInReload = false;

    BaseClass.Holster(skiplocal);
  }

  void PrimaryAttack()
  {
    if (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD)
    {
      self.PlayEmptySound();
      self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
      return;
    }

    if (self.m_iClip <= 0)
    {
      if (!self.m_fInReload)
      {
        self.PlayEmptySound();
        self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
      }
      return;
    }

    --self.m_iClip;

    pev.body = RecalculateBody(self.m_iClip);

    m_bAlternatingEject = !m_bAlternatingEject;

    m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
    m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

    m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

    m_flNextAnimTime = WeaponTimeBase() + 0.2;

    m_pPlayer.SetAnimation(PLAYER_ATTACK1);

    Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

    Vector vecSrc   = m_pPlayer.GetGunPosition();
    Vector vecAiming = m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

    Vector vecSpread;

    if (g_M249WideSpread.GetBool())
    {
      if (m_pPlayer.pev.button & IN_DUCK != 0)
      {
        vecSpread = VECTOR_CONE_3DEGREES;
      }
      else if (m_pPlayer.pev.button & (IN_MOVERIGHT | IN_MOVELEFT | IN_FORWARD | IN_BACK) != 0)
      {
        vecSpread = VECTOR_CONE_15DEGREES;
      }
      else
      {
        vecSpread = VECTOR_CONE_6DEGREES;
      }
    }
    else
    {
      if (m_pPlayer.pev.button & IN_DUCK != 0)
      {
        vecSpread = VECTOR_CONE_2DEGREES;
      }
      else if (m_pPlayer.pev.button & (IN_MOVERIGHT | IN_MOVELEFT | IN_FORWARD | IN_BACK) != 0)
      {
        vecSpread = VECTOR_CONE_10DEGREES;
      }
      else
      {
        vecSpread = VECTOR_CONE_4DEGREES;
      }
    }

    //FireBulletsPlayer(1, vecSrc, vecAiming, vecSpread, 8192.0, BULLET_PLAYER_SAW, 2);
    self.FireBullets( 1, vecSrc, vecAiming, vecSpread, 8192, BULLET_PLAYER_SAW, 2, 0, m_pPlayer.pev );

    pev.effects |= EF_MUZZLEFLASH;

    self.SendWeaponAnim(Math.RandomLong(0, 2) + SHOOT1, 0, GetBodygroup());

    // difference in model for nextprimaryattack
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

		if ( HEV.find(modelName) >= 0 )
    {
      m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0f, 2.0f);
      m_pPlayer.pev.punchangle.y = Math.RandomFloat(-1.0f, 1.0f);

      self.m_flNextPrimaryAttack = g_Engine.time + 0.099f;
      self.m_flTimeWeaponIdle = g_Engine.time + 0.2f;

      if (g_M249Knockback.GetBool())
      {
        Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

        const Vector vecVelocity = m_pPlayer.pev.velocity;
        const float flZVel = m_pPlayer.pev.velocity.z;

        Vector vecInvPushDir = g_Engine.v_forward * 35.0;
        float flNewZVel = g_EngineFuncs.CVarGetFloat('sv_maxspeed');

        if (vecInvPushDir.z >= 10.0)
          flNewZVel = vecInvPushDir.z;

        // Yeah... no deathmatch knockback
        m_pPlayer.pev.velocity = m_pPlayer.pev.velocity - vecInvPushDir;
        m_pPlayer.pev.velocity.z = flZVel;
    }
    }
    else
    {
      m_pPlayer.pev.punchangle.x = Math.RandomFloat(-10.0, 2.0);
      m_pPlayer.pev.punchangle.y = Math.RandomFloat(-2.0, 1.0);

      self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;
      self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2;

      if (g_M249Knockback.GetBool())
      {
        Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

        const Vector vecVelocity = m_pPlayer.pev.velocity;
        const float flZVel = m_pPlayer.pev.velocity.z;

        Vector vecInvPushDir = g_Engine.v_forward * 60.0;
        float flNewZVel = g_EngineFuncs.CVarGetFloat('sv_maxspeed');

        if (vecInvPushDir.z >= 10.0)
          flNewZVel = vecInvPushDir.z;

        // Yeah... no deathmatch knockback
        m_pPlayer.pev.velocity = m_pPlayer.pev.velocity - vecInvPushDir;
        m_pPlayer.pev.velocity.z = flZVel;
    }
    }
    
    Vector ShellVelocity, ShellOrigin;
    // GetDefaultShellInfo(ShellVelocity, ShellOrigin, -28.0, 24.0, 4.0);
    GetDefaultShellInfo(ShellVelocity, ShellOrigin, 14.0, -10.0, 8.0);
    g_EntityFuncs.EjectBrass(ShellOrigin, ShellVelocity, m_pPlayer.pev.angles.y, m_bAlternatingEject ? m_iLink : m_iShell, TE_BOUNCE_SHELL);

    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, 'bts_rc/weapons/gun_fire4.wav', VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15));

    if (self.m_iClip <= 0 && m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
      m_pPlayer.SetSuitUpdate('!HEV_AMO0', false, 0);
  }

  void Reload()
  {
    if (self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
      return;

    if (self.DefaultReload(MAX_CLIP, RELOAD_START, 1.0, GetBodygroup()))
    {
      m_bReloading = true;

      self.m_flNextPrimaryAttack = WeaponTimeBase() + 3.78;
      self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.78;

      m_flReloadStart = g_Engine.time;
    }

    BaseClass.Reload();
  }

  void ItemPostFrame()
  {
    // Speed up player reload anim
    if (m_bReloading && g_Engine.time < m_flReloadStart + 3.78)
      m_pPlayer.pev.framerate = 2.15;

    BaseClass.ItemPostFrame();
  }

  void WeaponIdle()
  {
    self.ResetEmptySound();

    m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

    if (m_bReloading && g_Engine.time >= m_flReloadStart + 1.33)
    {
      m_bReloading = false;

      pev.body = 0;
      self.SendWeaponAnim(RELOAD_END, 0, GetBodygroup());
    }

    if (self.m_flTimeWeaponIdle <= WeaponTimeBase())
    {
      int iAnim;
      const float flNextIdle = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0, 1.0);
      if (flNextIdle <= 0.95)
      {
        iAnim = SLOWIDLE;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0;
      }
      else
      {
        iAnim = IDLE2;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 6.16;
      }

      self.SendWeaponAnim(iAnim, 0, GetBodygroup());
    }
  }

  private int RecalculateBody(int iClip)
  {
    if (iClip == 0)
    {
      return 8;
    }
    else if (iClip >= 0 && iClip <= 7)
    {
      return 9 - iClip;
    }
    else
    {
      return 0;
    }
  }
}

class ammo_bts_saw : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 1.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "556", MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

class ammo_bts_dsaw : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 1.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = MAX_DROP;

		if( pOther.GiveAmmo( iGive, "556", MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetName()
{
  return 'weapon_bts_saw';
}

string GetAmmoName()
{
  return 'ammo_bts_saw';
}

string GetM249DAmmoName()
{
  return 'ammo_bts_dsaw';
}

void Register()
{
  g_CustomEntityFuncs.RegisterCustomEntity('CM249::weapon_bts_saw', GetName());
  g_CustomEntityFuncs.RegisterCustomEntity('CM249::ammo_bts_saw', GetAmmoName() );
  g_CustomEntityFuncs.RegisterCustomEntity('CM249::ammo_bts_dsaw', GetM249DAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "556", "", GetAmmoName() );
}

}
