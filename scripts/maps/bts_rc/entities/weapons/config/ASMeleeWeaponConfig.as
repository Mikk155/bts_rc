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

// Inherit from this class. override get_Name and Register then call back ASWeaponConfig::Register(json)
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

    void Register( meta_api::json::v2::json@ json ) override
    {
        this.primary_distance = json.ValueOrDefault( "primary_distance", this.primary_distance );
        this.secondary_distance = json.ValueOrDefault( "secondary_distance", this.secondary_distance );
        this.tertiary_distance = json.ValueOrDefault( "tertiary_distance", this.tertiary_distance );
        this.subsequent_hits_deduction = Math.min( 1.0, Math.max( 0.1, json.ValueOrDefault( "subsequent_hits_deduction", this.subsequent_hits_deduction ) ) );
        this.primary_miss_cooldown = json.ValueOrDefault( "primary_miss_cooldown", this.primary_miss_cooldown);
        this.primary_miss_trained_cooldown = json.ValueOrDefault( "primary_miss_trained_cooldown", this.primary_miss_trained_cooldown );
        this.secondary_miss_cooldown = json.ValueOrDefault( "secondary_miss_cooldown", this.secondary_miss_cooldown );
        this.secondary_miss_trained_cooldown = json.ValueOrDefault( "secondary_miss_trained_cooldown", this.secondary_miss_trained_cooldown );

        ASWeaponConfig::Register(json);
    }
}
