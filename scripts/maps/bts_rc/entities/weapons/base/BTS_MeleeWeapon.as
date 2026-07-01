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

abstract class BTS_MeleeWeapon : BTS_Weapon
{
    ASMeleeWeaponConfig@ get_configMelee()
    {
        return cast<ASMeleeWeaponConfig@>( this.config );
    }

    // Amount of swings in a raw
    int m_iSwing = 0;

    bool m_IsSecondary = false;

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, bool miss, AttackType type )
    {
        weapons::SetCooldown( self, this.owner, configMelee.GetCooldown( is_trained_personal, type, miss ) );
    }

    // Hit ahead. return whatever it was a hit or a miss. automatically damages the target with config data
    bool Hit( TraceResult&out tr, AttackType type, CBaseEntity@&out hit, bool Shove = false )
    {
        return weapons::Hit( self, this.owner, tr, type, hit, configMelee, Shove );
    }
}
