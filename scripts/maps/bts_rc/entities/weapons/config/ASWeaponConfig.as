// Inherit from this class. override GetName and Parse then call back ASWeaponConfig::Parse(json)
abstract class ASWeaponConfig : IConfigContext
{
    ASWeaponConfig()
    {
        @g_WeaponsConfig.Interfaces[ this.GetName() ] = this;
        ConfigContext::Register( this );
    }

    // json unique object name
    string GetName() { return String::EMPTY_STRING; }

    // Weapon view model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    const string& get_view_model() { return String::EMPTY_STRING; }
    // Weapon player model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    const string& get_player_model() { return String::EMPTY_STRING; }
    // Weapon world model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    const string& get_world_model() { return String::EMPTY_STRING; }
    // Weapon deploy extension. automatically set in BTS_Weapon::Deploy
    const string& get_animation_extension() { return String::EMPTY_STRING; }
    // Weapon deploy bodygroup value. some models has their hands bodgroup on a different value. automatically set in BTS_Weapon::Deploy
    uint8 get_hands_group() { return 1; }
    uint8 get_animation_draw() { return 1; }
    const string& get_primary_ammo() { return String::EMPTY_STRING; }
    const string& get_secondary_ammo() { return String::EMPTY_STRING; }
    // Weapon classname to add ItemMapping
    const string& get_remap() { return String::EMPTY_STRING; }

    // Precache required assets. NOTE: v, p and w models are precached automatically.
    void Precache()
    {
    }

    // Weapon deploy time cooldown for attacking. automatically set in BTS_Weapon::Deploy
    float deploy_time;
    // Weapon primary max ammo capacity. automatically set in BTS_Weapon::GetItemInfo
    int primary_maxammo;
    // Weapon primary max ammo drop. automatically set in BTS_Weapon::GetItemInfo
    int primary_dropammo = WEAPON_NOCLIP;
    // Weapon secondary max ammo capacity. automatically set in BTS_Weapon::GetItemInfo
    int secondary_maxammo = WEAPON_NOCLIP;
    // Weapon secondary max ammo drop. automatically set in BTS_Weapon::GetItemInfo
    int secondary_dropammo = WEAPON_NOCLIP;
    // Weapon primary max ammo clip capacity. automatically set in BTS_Weapon::GetItemInfo
    int max_clip = WEAPON_NOCLIP;
    // Weapon hud slot. automatically set in BTS_Weapon::GetItemInfo
    uint8 slot = 0;
    // Weapon hud position. automatically set in BTS_Weapon::GetItemInfo
    uint8 position = 0;
    // Weapon heigth. automatically set in BTS_Weapon::GetItemInfo
    uint8 weight = 0;

    // Weapon damage for primary attack
    float primary_damage;
    // Weapon damage for secondary attack
    float secondary_damage;
    // Weapon cooldown for primary attack
    float primary_cooldown;
    // Weapon cooldown for primary attack for trained personal
    float primary_trained_cooldown;
    // Weapon cooldown for secondary attack
    float secondary_cooldown;
    // Weapon cooldown for secondary attack for trained personal
    float secondary_trained_cooldown;
    // Weapon cooldown for tertriary attack
    float tertriary_cooldown;
    // Weapon cooldown for tertriary attack for trained personal
    float tertriary_trained_cooldown;

    float Get( const dictionary@&in json, const string&in keyName, float defaultValue )
    {
        float value;

        if( !json.get( keyName, value ) )
        {
            if( g_Logger.warning )
                g_Logger.warning = snprintf( glog, "Failed to get \"%1\" from context \"%2\" setting default value \"%3\"", keyName, this.GetName(), defaultValue );

            return defaultValue;
        }

        if( g_Logger.trace )
            g_Logger.trace = snprintf( glog, "Getting key \"%1\" for context \"%2\" setting value \"%3\"", keyName, this.GetName(), value );

        return value;
    }

    void ParseDefaultVariables( dictionary@ json )
    {
        this.primary_maxammo = int( this.Get( @json, "primary_maxammo", WEAPON_NOCLIP ) );
        this.secondary_maxammo = int( this.Get( @json, "secondary_maxammo", WEAPON_NOCLIP ) );

        this.primary_dropammo = int( this.Get( @json, "primary_dropammo", WEAPON_NOCLIP ) );
        this.secondary_dropammo = int( this.Get( @json, "secondary_dropammo", WEAPON_NOCLIP ) );

        this.primary_damage = this.Get( @json, "primary_damage", 1 );
        this.secondary_damage = this.Get( @json, "secondary_damage", 1 );

        this.primary_cooldown = this.Get( @json, "primary_cooldown", 1 );
        this.primary_trained_cooldown = this.Get( @json, "primary_trained_cooldown", primary_cooldown );

        this.secondary_cooldown = this.Get( @json, "secondary_cooldown", primary_cooldown );
        this.secondary_trained_cooldown = this.Get( @json, "secondary_trained_cooldown", secondary_cooldown );

        this.max_clip = int( this.Get( @json, "max_clip", WEAPON_NOCLIP ) );
        this.slot = uint( this.Get( @json, "slot", 0 ) );
        this.position = uint( this.Get( @json, "position", 0 ) );
        this.weight = uint( this.Get( @json, "weight", 10 ) );
        this.deploy_time = this.Get( @json, "deploy_time", 1.0f );
    }

    void RegisterWeapon()
    {
        string weaponName = this.GetName();

        if( !this.remap.IsEmpty() )
        {
            auto remap = ItemMapping( this.remap, weaponName );
            g_WeaponsConfig.ItemMappingList.insertLast( @remap );
        }

        g_CustomEntityFuncs.RegisterCustomEntity( weaponName, weaponName );

        g_ItemRegistry.RegisterWeapon( weaponName, "bts_rc/weapons", this.primary_ammo, this.secondary_ammo );

        string szSpriteDir; // Precache HUD text definition
        snprintf( szSpriteDir, "sprites/bts_rc/weapons/%1.txt", weaponName );
        g_Game.PrecacheGeneric( szSpriteDir );
    }
 
    void Parse( dictionary@ json )
    {
        this.Precache();

        this.ParseDefaultVariables( json );

        g_Game.PrecacheModel( this.view_model );
        g_Game.PrecacheModel( this.world_model );
        g_Game.PrecacheModel( this.player_model );

        this.RegisterWeapon();
    }
}
