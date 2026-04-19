/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

// Inherit from this class. override GetName and Parse then call back ASWeaponConfig::Parse(json)
abstract class ASMeleeWeaponConfig : ASWeaponConfig
{
    /// Melee weapon attack distance
    float primary_distance;
    float secondary_distance;
    float tertriary_distance;
    float subsequent_hits_deduction;
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
            case AttackType::Tertriary:
            default:
            {
                return ASWeaponConfig::GetCooldown( is_trained_personal, type );
            }
        }
    }

    void Parse( dictionary@ json ) override
    {
        this.primary_distance = this.Get( @json, "primary_distance", 10 );
        this.secondary_distance = this.Get( @json, "secondary_distance", primary_distance );
        this.tertriary_distance = this.Get( @json, "tertriary_distance", primary_distance );
        this.subsequent_hits_deduction = this.Get( @json, "subsequent_hits_deduction", 0.5 ); // -TODO Unimplemented yet
        this.primary_miss_cooldown = this.Get( @json, "primary_miss_cooldown", 1.5 );
        this.primary_miss_trained_cooldown = this.Get( @json, "primary_miss_trained_cooldown", primary_miss_cooldown );
        this.secondary_miss_cooldown = this.Get( @json, "secondary_miss_cooldown", primary_miss_cooldown );
        this.secondary_miss_trained_cooldown = this.Get( @json, "secondary_miss_trained_cooldown", secondary_miss_cooldown );

        ASWeaponConfig::Parse(json);
    }

    void ParseDefaultVariables( dictionary@ json ) override
    {
        ASWeaponConfig::ParseDefaultVariables(json);
    }

    void RegisterWeapon() override
    {
        ASWeaponConfig::RegisterWeapon();
    }

    void Precache() override
    {
        ASWeaponConfig::Precache();
    }
}
