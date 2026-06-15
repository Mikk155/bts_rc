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

class item_bts_clsuit : BTS_Item
{
    const string& get_m_Model() override {
        return "models/w_hazmat.mdl";
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( !IsValid( other ) )
            return false;

        CBasePlayer@ player = cast<CBasePlayer@>( other );

        auto character = GetCharacter(player);

        if( player is null || character is null || character.IsHEV || character.IsHazard )
            return false;

        SetClass( player, Classification::Hazard );

        player.pev.armorvalue = player.pev.armortype;

        PickupObject( player, "suit_empty" );

        return true;
    }
}
