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

abstract class BTS_LaserSpot : BTS_FireWeapon
{
    private ASWeaponLaserConfig@ m_LaserConfig;

    ASWeaponLaserConfig@ get_LaserConfig()
    {
        if( this.m_LaserConfig is null )
            @this.m_LaserConfig = cast<ASWeaponLaserConfig@>( this.config );
        return this.m_LaserConfig;
    }

    float Accuracy( float tr, float def, float trd, float defd ) override
    {
        float cone = BTS_FireWeapon::Accuracy( tr, def, trd, defd );

        if( self.pev.iuser1 == 0 )
        {
            cone *= this.LaserConfig.laser_accuracy;
        }

        return cone;
    }

    void SetCooldown( bool is_trained_personal, AttackType type ) override
    {
        float cooldown = this.config.GetCooldown( is_trained_personal, type );

        if( self.pev.iuser1 != 0 )
        {
            cooldown *= this.LaserConfig.laser_cooldown;
        }

        weapons::SetCooldown( self, this.owner, cooldown );
    }

    void UpdateOnRemove() override
    {
        CBaseEntity@ laser = LaserSpot::Entity( this.owner );

        if( laser !is null )
        {
            laser.pev.effects |= EF_NODRAW;
        }

        BTS_FireWeapon::UpdateOnRemove();
    }
}
