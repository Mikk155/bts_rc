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

// Inherit from this class. override GetName and Register then call back ASWeaponConfig::Register(json)
abstract class ASMeleeWeaponConfig : ASWeaponConfig
{
    /// Melee weapon attack distance
    float primary_distance;
    float secondary_distance;
    float tertiary_distance;
    float subsequent_hits_deduction = 0.5;
    float primary_miss_cooldown;
    float secondary_miss_cooldown;
    float primary_miss_trained_cooldown;
    float secondary_miss_trained_cooldown;

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
                return ASWeaponConfig::GetCooldown( is_trained_personal, type );
            }
        }
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.primary_distance = config.ValueOrDefault( "primary_distance", this.primary_distance );
        this.secondary_distance = config.ValueOrDefault( "secondary_distance", this.secondary_distance );
        this.tertiary_distance = config.ValueOrDefault( "tertiary_distance", this.tertiary_distance );
        this.subsequent_hits_deduction = Math.min( 1.0, Math.max( 0.1, config.ValueOrDefault( "subsequent_hits_deduction", this.subsequent_hits_deduction ) ) );
        this.primary_miss_cooldown = config.ValueOrDefault( "primary_miss_cooldown", this.primary_miss_cooldown);
        this.primary_miss_trained_cooldown = config.ValueOrDefault( "primary_miss_trained_cooldown", this.primary_miss_trained_cooldown );
        this.secondary_miss_cooldown = config.ValueOrDefault( "secondary_miss_cooldown", this.secondary_miss_cooldown );
        this.secondary_miss_trained_cooldown = config.ValueOrDefault( "secondary_miss_trained_cooldown", this.secondary_miss_trained_cooldown );

        return ASWeaponConfig::Register(config);
    }
}
