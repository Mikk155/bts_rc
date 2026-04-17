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
}
