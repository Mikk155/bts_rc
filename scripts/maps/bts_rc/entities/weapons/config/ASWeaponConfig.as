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

meta_api::json::v2::json@ g_WeaponsDefaults = null;

bool ASWeaponConfigSchema = g_MapConfig.RegisterSchemaDefinition( "ASWeaponConfig",
"""{
    "primary_maxammo":
    {
        "type": "integer"
    },
    "secondary_maxammo":
    {
        "type": "integer"
    },
    "primary_dropammo":
    {
        "type": "integer"
    },
    "secondary_dropammo":
    {
        "type": "integer"
    },
    "primary_damage":
    {
        "type": "number"
    },
    "secondary_damage":
    {
        "type": "number"
    },
    "tertiary_damage":
    {
        "type": "number"
    },
    "primary_cooldown":
    {
        "type": "number"
    },
    "secondary_cooldown":
    {
        "type": "number"
    },
    "tertiary_cooldown":
    {
        "type": "number"
    },
    "primary_trained_cooldown":
    {
        "type": "number"
    },
    "secondary_trained_cooldown":
    {
        "type": "number"
    },
    "tertiary_trained_cooldown":
    {
        "type": "number"
    },
    "max_clip":
    {
        "type": "integer"
    },
    "slot":
    {
        "type": "integer"
    },
    "position":
    {
        "type": "integer"
    },
    "weight":
    {
        "type": "integer"
    },
    "deploy_time":
    {
        "type": "number"
    },
    "primary_distance":
    {
        "type": "number"
    },
    "secondary_distance":
    {
        "type": "number"
    },
    "tertiary_distance":
    {
        "type": "number"
    },
    "subsequent_hits_deduction":
    {
        "type": "number",
        "description": "Damage multiplier applied to consecutive hits."
    },
    "primary_miss_cooldown":
    {
        "type": "number"
    },
    "primary_miss_trained_cooldown":
    {
        "type": "number"
    },
    "secondary_miss_cooldown":
    {
        "type": "number"
    },
    "secondary_miss_trained_cooldown":
    {
        "type": "number"
    },
    "reload_time":
    {
        "type": "number"
    },
    "reload_anim":
    {
        "type": "integer"
    },
    "reload_empty_anim":
    {
        "type": "integer"
    },
    "reload_sound":
    {
        "type": "string"
    }
}""" );

// Inherit from this class. override GetName and Register then call back ASWeaponConfig::Register(json)
abstract class ASWeaponConfig : IConfigurable
{
    ASWeaponConfig()
    {
        @g_WeaponsConfig.Interfaces[ this.GetName() ] = this;
    }

    // Weapon view model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    const string& get_view_model() { return String::EMPTY_STRING; }
    // Weapon player model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    const string& get_player_model() { return String::EMPTY_STRING; }
    // Weapon world model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    const string& get_world_model() { return String::EMPTY_STRING; }
    // Weapon deploy extension. automatically set in BTS_Weapon::Deploy
    const string& get_animation_extension() { return String::EMPTY_STRING; }
    // Weapon deploy bodygroup value. some models has their hands bodgroup on a different value. automatically set in BTS_Weapon::Deploy
    const uint8 get_hands_group() { return 1; }
    const uint8 get_animation_draw() { return 1; }
    const string& get_primary_ammo() { return String::EMPTY_STRING; }
    const string& get_primary_ammoentity() { return String::EMPTY_STRING; }
    const string& get_secondary_ammo() { return String::EMPTY_STRING; }
    const string& get_secondary_ammoentity() { return String::EMPTY_STRING; }
    // Weapon classname to add ItemMapping
    const string& get_remap() { return String::EMPTY_STRING; }

    private int m_view_model_index = -1;
    // Do not override. is automatic.
    const int get_view_model_index()
    {
        if( this.m_view_model_index == -1 )
            this.m_view_model_index = g_ModelFuncs.ModelIndex( this.view_model );
        return this.m_view_model_index;
    }

    // Weapon deploy time cooldown for attacking. automatically set in BTS_Weapon::Deploy
    float deploy_time = 1.0f;
    // Weapon primary max ammo capacity. automatically set in BTS_Weapon::GetItemInfo
    int primary_maxammo = WEAPON_NOCLIP;
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
    float tertiary_damage;
    // Weapon cooldown for primary attack
    float primary_cooldown = 1;
    // Weapon cooldown for primary attack for trained personal
    float primary_trained_cooldown = 1;
    // Weapon cooldown for secondary attack
    float secondary_cooldown = 1;
    // Weapon cooldown for secondary attack for trained personal
    float secondary_trained_cooldown = 1;
    // Weapon cooldown for tertiary attack
    float tertiary_cooldown = 1;
    // Weapon cooldown for tertiary attack for trained personal
    float tertiary_trained_cooldown = 1;

    // Melee weapon properties
    float primary_distance;
    float secondary_distance;
    float tertiary_distance;
    float subsequent_hits_deduction = 0.5;
    float primary_miss_cooldown;
    float secondary_miss_cooldown;
    float primary_miss_trained_cooldown;
    float secondary_miss_trained_cooldown;

    // Reload properties
    float reload_time = 1.5f;
    int reload_anim = 0;
    int reload_empty_anim = 0;
    string reload_sound = "";

    float GetCooldown( bool is_trained_personal, AttackType type )
    {
        return GetCooldown( is_trained_personal, type, false );
    }

    float GetCooldown( bool is_trained_personal, AttackType type, bool miss )
    {
        switch( type )
        {
            case AttackType::Primary:
            {
                if( is_trained_personal )
                    return ( miss ? this.primary_miss_trained_cooldown : this.primary_cooldown );
                return ( miss ? this.primary_miss_cooldown : this.primary_cooldown );
            }
            case AttackType::Secondary:
            {
                if( is_trained_personal )
                    return ( miss ? this.secondary_miss_trained_cooldown : this.secondary_trained_cooldown );
                return ( miss ? this.secondary_miss_cooldown : this.secondary_cooldown );
            }
            case AttackType::Tertiary:
            default:
            {
                return ( is_trained_personal ? this.tertiary_trained_cooldown : this.tertiary_cooldown );
            }
        }
    }

    // Whatever this is a custom weapon
    const bool IsCustomWeapon()
    {
        return true;
    }

    void RegisterWeapon()
    {
        if( !this.remap.IsEmpty() )
        {
            auto remap = ItemMapping( this.remap, this.GetName() );
            g_WeaponsConfig.ItemMappingList.insertLast( @remap );
        }

        if( this.IsCustomWeapon() )
        {
            g_CustomEntityFuncs.RegisterCustomEntity( this.GetName(), this.GetName() );

            // Register primary ammo if any and is not already registered
            if( !this.primary_ammoentity.IsEmpty() && !g_CustomEntityFuncs.IsCustomEntity( this.primary_ammoentity ) )
                CustomEntity( this.primary_ammoentity );

            // Register secondary ammo if any and is not already registered
            if( !this.secondary_ammoentity.IsEmpty() && !g_CustomEntityFuncs.IsCustomEntity( this.secondary_ammoentity ) )
                CustomEntity( this.secondary_ammoentity );

            g_ItemRegistry.RegisterWeapon( this.GetName(), "bts_rc/weapons", this.primary_ammo, this.secondary_ammo, this.primary_ammoentity, this.secondary_ammoentity );

            string szSpriteDir; // Precache HUD text definition
            snprintf( szSpriteDir, "sprites/bts_rc/weapons/%1.txt", this.GetName() );
            g_Game.PrecacheGeneric( szSpriteDir );
        }
    }
 
    // Precache required assets
    void Precache()
    {
        g_Game.PrecacheModel( this.view_model );
        g_Game.PrecacheModel( this.player_model );

        if( !this.world_model.IsEmpty() )
            g_Game.PrecacheModel( this.world_model );
    }

    // https://github.com/anjo76/angelscript/issues/68
    const string& GetName() const override
    {
        g_Logger.critical.print( "Unnamed ASWeaponConfig instance! Make sure to override the GetName method." );
        array<int> arr(0); arr[1]; // Stop the module somehow since no "throw" exists x[
        return String::EMPTY_STRING;
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon config",
            "description": "weapon-related gameplay modifiers.",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.primary_maxammo = config.ValueOrDefault( "primary_maxammo", this.primary_maxammo );

        this.secondary_maxammo = config.ValueOrDefault( "secondary_maxammo", this.secondary_maxammo );

        this.primary_dropammo = config.ValueOrDefault( "primary_dropammo", this.primary_dropammo );
        this.secondary_dropammo = config.ValueOrDefault( "secondary_dropammo", this.secondary_dropammo );

        this.primary_damage = config.ValueOrDefault( "primary_damage", this.primary_damage );
        this.secondary_damage = config.ValueOrDefault( "secondary_damage", this.secondary_damage );
        this.tertiary_damage = config.ValueOrDefault( "tertiary_damage", this.tertiary_damage );

        this.primary_cooldown = config.ValueOrDefault( "primary_cooldown", this.primary_cooldown );
        this.primary_trained_cooldown = config.ValueOrDefault( "primary_trained_cooldown", this.primary_trained_cooldown );

        this.secondary_cooldown = config.ValueOrDefault( "secondary_cooldown", this.secondary_cooldown );
        this.secondary_trained_cooldown = config.ValueOrDefault( "secondary_trained_cooldown", this.secondary_trained_cooldown );

        this.tertiary_cooldown = config.ValueOrDefault( "tertiary_cooldown", this.tertiary_cooldown );
        this.tertiary_trained_cooldown = config.ValueOrDefault( "tertiary_trained_cooldown", this.tertiary_trained_cooldown );

        this.max_clip = config.ValueOrDefault( "max_clip", this.max_clip );
        this.slot = config.ValueOrDefault( "slot", this.slot );
        this.position = config.ValueOrDefault( "position", this.position );
        this.weight = config.ValueOrDefault( "weight", this.weight );
        this.deploy_time = config.ValueOrDefault( "deploy_time", this.deploy_time );

        // Melee properties
        this.primary_distance = config.ValueOrDefault( "primary_distance", this.primary_distance );
        this.secondary_distance = config.ValueOrDefault( "secondary_distance", this.secondary_distance );
        this.tertiary_distance = config.ValueOrDefault( "tertiary_distance", this.tertiary_distance );

        // -TODO Should maybe schema this and some more other variables.
        this.subsequent_hits_deduction = config.ValueOrDefault( "subsequent_hits_deduction", this.subsequent_hits_deduction );
        this.subsequent_hits_deduction = Math.min( 1.0, Math.max( 0.1, this.subsequent_hits_deduction ) );

        this.primary_miss_cooldown = config.ValueOrDefault( "primary_miss_cooldown", this.primary_miss_cooldown );
        this.primary_miss_trained_cooldown = config.ValueOrDefault( "primary_miss_trained_cooldown", this.primary_miss_trained_cooldown );
        this.secondary_miss_cooldown = config.ValueOrDefault( "secondary_miss_cooldown", this.secondary_miss_cooldown );
        this.secondary_miss_trained_cooldown = config.ValueOrDefault( "secondary_miss_trained_cooldown", this.secondary_miss_trained_cooldown );

        // Reload properties
        this.reload_time = config.ValueOrDefault( "reload_time", this.reload_time );
        this.reload_anim = config.ValueOrDefault( "reload_anim", this.reload_anim );
        this.reload_empty_anim = config.ValueOrDefault( "reload_empty_anim", this.reload_empty_anim );
        this.reload_sound = config.ValueOrDefault( "reload_sound", this.reload_sound );

        this.Precache();
        this.RegisterWeapon();

        return true;
    }

    // Called when the weapon is deployed. this is too late!
    void WeaponDeploy( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) { }
    // Called just before WeaponDeploy at this class
    void WeaponHolster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) { }
    // Pre call of PrimaryAttack
    void WeaponPrimaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) { }
    // Pre call of SecondaryAttack
    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) { }
    // Pre call of TertiaryAttack
    void WeaponTertiaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) { }
    // Called when the player uses the flashlight. this is not called if the player is a HEV and has suit power.
    void WeaponFlashlight( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        if( player.pev.impulse == 0 )
            return; // Avoid looping

        // If the current active weapon doesn't has a usable flashlight then do a loadout check
        if( ( weapon.pszAmmo2() != "bts_battery" && weapon.pszAmmo1() != "bts_battery" ) || !Flashlight::HasAnyReserve( player, weapon ) )
        {
            @weapon = null;

            for( uint ui = 0; ui < MAX_ITEM_TYPES; ui++ )
            {
                CBasePlayerItem@ item = player.m_rgpPlayerItems(ui);

                while( item !is null )
                {
                    @weapon = cast<CBasePlayerWeapon@>(item);

                    if( weapon !is null && ( weapon.pszAmmo2() == "bts_battery" || weapon.pszAmmo1() == "bts_battery" ) && Flashlight::HasAnyReserve( player, weapon ) )
                    {
                        player.SelectItem( weapon.pev.classname );
                        weapon.Deploy();
                        ui = MAX_ITEM_TYPES; // Break for loop
                        break;
                    }

                    @weapon = null;
                    @item = cast<CBasePlayerWeapon@>( item.m_hNextItem.GetEntity() );
                }
            }
        }

        if( weapon !is null )
        {
            player.pev.impulse = 0;
            ASWeaponConfig@ weaponConfig = cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ weapon.pev.classname ] );
            weaponConfig.WeaponFlashlight( player, weapon, character );
        }
    }

    // PlayerThink call after Weapon's deploy and attack methods of this class has been called
    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        // 2.27 doesn't force pev->body through SendWeaponAnim so we do this hack in the meanwhile
        if( gpGameVersion == 526 && !this.IsCustomWeapon() )
        {
            dictionary@ data = player.GetUserData();

            int sequence;

            if( !data.get( "526_weaponsequence", sequence ) )
                sequence = -1;

            if( sequence != player.pev.weaponanim )
            {
                data[ "526_weaponsequence" ] = player.pev.weaponanim;
                Hands handsGroup = ( character !is null ? character.HandsGroup : Hands::Hevsuit );
                weapon.pev.body = g_ModelFuncs.SetBodygroup( this.view_model_index, weapon.pev.body, this.hands_group, handsGroup );
                weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body );
            }
            else if( weapon.m_flTimeWeaponIdle <= g_Engine.time )
            {
                data[ "526_weaponsequence" ] = -1;
            }
        }
    }
}
