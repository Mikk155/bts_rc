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

final class ASDummyMonsters : EntityOverriden, IConfigurable
{
    const string& GetName() const override
    {
        return "dummymonster";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( g_MapConfig.MapLoading )
        {
            EntityOverriden::SetThink( 1.5f );
            EntityOverriden::Register( this );
        }
        return true;
    }

    const string GetSchema() const override {
        return String::EMPTY_STRING;
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null )
            return false;

        return EntityOverriden::AddEntity( entity, monster );
    }

    int count = 0;
    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || !monster.IsAlive() || monster.pev.nextthink <= 0 )
            return EntityOverridenAction::Remove;

        if( monster.m_hEnemy.IsValid() )
            return EntityOverridenAction::None;

        monster.pev.nextthink = g_Engine.time + 1.0f;
        count++;

        return EntityOverridenAction::None;
    }

    void Think() override
    {
        g_PlayerFuncs.ClientPrintAll( HUD::HUD_PRINTNOTIFY, "Made " + count + " monsters dumb\n" );
        count = 0;
        EntityOverriden::Think();
    }
}
