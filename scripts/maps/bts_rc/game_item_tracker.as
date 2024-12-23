/* bts_rc Item Tracker - System to check who is carrying what item via an in-game menu
Author: Gaftherman - Rizulix
*/

void RegisterItemTracker()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CGameItemTracker", "game_item_tracker" );
}

EHandle hItemTrackerMenu;

void SetupItemTracker()
{
	array<array<string>> arrMenu = {
		{ "message", "Who has what? - " },
		{ "Area 1 - Retina component", "RETINA_COMPONENT" },
		{ "Area 1 - Override Valve 1", "VALVE_1" },
		{ "Area 1 - Override Valve 2", "VALVE_1"},
		{ "Area 3 - Gear 1", "GEAR_1" },
		{ "Area 3 - Gear 2", "GEAR_2" },
		{ "Area 3 - Gear 3", "GEAR_3" },
		{ "Area 3 - Gear", "GEAR_4" },
		{ "Area 2 - Yard managers keycard", "WAREHOUSE_YARDKEY" },
		{ "Area 1 - A-101 Dorms key 1", "DORMS_CARD_101" },
		{ "Area 1 - A-101 Dorms key 2", "DORMS_CARD_101" },
		{ "Area 1 - A-106 Dorms key 3", "DORMS_CARD_106" },
		{ "Area 1 - B-201 Dorms key 4", "DORMS_CARD_201" },
		{ "Service Elevator codes", "CODES_1" },
		{ "Maintenance Access level 2 keycard", "Blackmesa_Maintenance_Clearance_2" },
		{ "Maintenance Access level 2 keycard Alt", "Blackmesa_Maintenance_Clearance_2" },
		{ "Maintenance Access level 2 keycard X", "Blackmesa_Maintenance_Clearance_2" },
		{ "Reception key 1", "d5_officekey" },
		{ "Reception key 2", "d5_officekey" },
		{ "Doctors key", "d5_doctorkey" },
		{ "Blackmesa Security Clearance level 3", "Blackmesa_Security_Clearance_3" }
	};

	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "game_item_tracker", null, false );

	for( uint ui = 0; ui < arrMenu.length(); ui++ )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), arrMenu[ ui ][ 0 ], arrMenu[ ui ][ 1 ]);

	g_EntityFuncs.DispatchSpawn( pEntity.edict() );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @PlayerOpenTracker );

	hItemTrackerMenu = EHandle( @pEntity );
}

HookReturnCode PlayerOpenTracker( SayParameters@ pParams )
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ pArgs = pParams.GetArguments();

	if( pArgs.Arg( 0 ).ToLowercase() != "!whw" || !hItemTrackerMenu )
		return HOOK_CONTINUE;

	pParams.ShouldHide = true;
	hItemTrackerMenu.GetEntity().Use( pPlayer, pPlayer, USE_ON );
	return HOOK_CONTINUE;
}

class CItemCarriers
{
	CItemCarriers() { }
	CItemCarriers( const string& in szDisplayName, const string& in szTargetname )
	{
		m_szTargetname = szTargetname;
		m_szDisplayName = szDisplayName;
	}
	void Find( CBasePlayer@ pRequester )
	{
		string szCarriers = ";";
		for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); iPlayer++ )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
			if( pPlayer is null || !pPlayer.IsConnected() )
				continue;

			InventoryList@ pInventory = pPlayer.m_pInventory;
			while( pInventory !is null )
			{
				CItemInventory@ pInventoryItem = cast<CItemInventory@>( pInventory.hItem.GetEntity() );
				if( pInventoryItem !is null && pInventoryItem.m_szItemName == m_szTargetname )
					szCarriers += "" + pPlayer.pev.netname + ";";

				@pInventory = pInventory.pNext;
			}
		}
		szCarriers.SubString( 1 );

		if( szCarriers != "" )
			g_PlayerFuncs.SayText( pRequester, "Players carrying item '" + m_szDisplayName + "':\n" + szCarriers + "\n" );
		else
			g_PlayerFuncs.SayText( pRequester, "Nobody is carrying item '" + m_szDisplayName + "'.\n" );
	}
	string m_szTargetname;
	string m_szDisplayName;
}

class CGameItemTracker : ScriptBaseEntity
{
	//pev.iuser1 -> close_after
	//pev.iuser2 -> page
	//pev.iuser3 -> on/off menu -> 1/0
	//pev.message -> menu_title
	private array<array<string>> m_pMenuOptions;
	private CTextMenu@ m_pMenu;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "delay" )
		{
			pev.iuser1 = Math.clamp( 0, 255, atoi( szValue ) );
			return true;
		}
		else if( szKey == "health" )
		{
			pev.iuser2 = atoi( szValue );
			return true;
		}
		else if( szKey == "message" )
		{
			pev.message = atoi( szValue );
			return true;
		}
		else
		{
			if( szValue == "" )
				return false;

			m_pMenuOptions.insertLast( { szKey, szValue } );
			return true;
		}
	}

	void Spawn()
	{
		if( m_pMenuOptions.length() == 0 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		@m_pMenu = CTextMenu( TextMenuPlayerSlotCallback( this.MenuCallback ) );
		m_pMenu.SetTitle( "" + pev.message );

		for( uint i = 0; i < m_pMenuOptions.length(); i++ )
			m_pMenu.AddItem( m_pMenuOptions[ i ][ 0 ], any( @CItemCarriers( m_pMenuOptions[ i ][ 0 ], m_pMenuOptions[ i ][ 1 ] ) ) );

		m_pMenu.Register();
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( !pActivator.IsPlayer() )
			return;

		if( useType == USE_TOGGLE )
			useType = USE_TYPE( pev.iuser3 = 1 - pev.iuser3 );

		switch ( useType )
		{
			case USE_ON:
			{
				pev.iuser3 = 1;

				if( pev.SpawnFlagBitSet( 1 << 0 ) )
					m_pMenu.Open( pev.iuser1, uint( pev.iuser2 ) );
				else
					m_pMenu.Open( pev.iuser1, uint( pev.iuser2 ), cast<CBasePlayer@>( pActivator ) );

				break;
			}
			case USE_OFF:
			{
				pev.iuser3 = 0;

				if( pev.SpawnFlagBitSet( 1 << 0 ) )
					m_pMenu.Open( 1, uint( pev.iuser2 ) );
				else
					m_pMenu.Open( 1, uint( pev.iuser2 ), cast<CBasePlayer@>( pActivator ) );

				break;
			}
			case USE_KILL:
			{
				g_EntityFuncs.Remove( self );
				return;
			}
		}
	}

	void MenuCallback( CTextMenu@ pMenu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if( pItem is null )
			return;

		CItemCarriers@ pCarriers;
		pItem.m_pUserData.retrieve( @pCarriers );

		if( pCarriers !is null )
			pCarriers.Find( @pPlayer );
	}
}