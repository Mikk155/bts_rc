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

namespace test_chamber
{
void MapActivate()
{
test_chamber::SortSections();
} // MapActivate
dictionary@ gpMenuSpawnerKeyvalues;
void RegisterSpawner( const string&in name, dictionary&in keyvalues )
{
    if( gpMenuSpawnerKeyvalues is null )
        @gpMenuSpawnerKeyvalues = {};
    @gpMenuSpawnerKeyvalues[ name ] = keyvalues;
    auto entity = Entity::Create( keyvalues );
    g_EntityFuncs.Remove( entity );
}
void MapInit()
{
// ============================================================
// Custom entities
// ============================================================
CustomEntity( "trigger_logger", true, "test_chamber::trigger_logger" );
CustomEntity( "info_section", true, "test_chamber::info_section" );
CustomEntity( "entitymaker", true, "test_chamber::entitymaker" );
CustomEntity( "func_target", true, "test_chamber::func_target" );
// ============================================================
// Utility commands
// ============================================================
RegisterAllSpawners();
ASCommand(
"spawn",
"",
"Open test entity spawner menu",
function( CBasePlayer@ player, array<string>@ arguments )
{
    TextMenu::v1::Menu menu;
    menu.Text.Write( "Entity spawner" );

    array<string>@ keys = gpMenuSpawnerKeyvalues.getKeys();
    uint length = keys.length();

    for( uint ui = 0; ui < length; ui++ )
    {
        string name = keys[ui];
        dictionary@ keyvalues = cast<dictionary@>( gpMenuSpawnerKeyvalues[ name ] );

        auto@ option = menu.AddOption();
        option.Text.Write( name );
        option.SetData( keyvalues );
        option.SetCallback(
            function( CBasePlayer@ player, TextMenu::v1::MenuOption@ option )
            {
                TraceResult tr;
                Math.MakeVectors( player.pev.v_angle );
                g_Utility.TraceLine( player.GetGunPosition(), player.GetGunPosition() + ( g_Engine.v_forward * 128 ), dont_ignore_monsters, player.edict(), tr );
                option.Data[ "origin" ] = tr.vecEndPos.ToString();
                option.Data[ "angles" ] = Vector( 0, player.pev.v_angle.y, 0 ).ToString();
                auto entity = Entity::Create( option.Data );
                EntityOverriden::Register( entity, cast<CBaseMonster@>(entity) );
            }
        );
    }
    menu.Open( player, 30 );
}, true, "test"
);
}
} // MapInit
void RegisterAllSpawners()
{
dictionary kvs;
kvs = {
    { "bloodcolor", "-1" },
    { "classname", "monster_hwgrunt" },
    { "health", "500" },
    { "$i_spark_color", "4" },
    { "soundlist", "rgrunts.txt" },
    { "model", "models/bts_rc/monsters/robothwgrunt.mdl" }
}; test_chamber::RegisterSpawner( "Enforcer", kvs );
kvs = {
    { "soundlist", "rgrunts.txt" },
    { "is_player_ally", "1" },
    { "bloodcolor", "-1" },
    { "health", "100" },
    { "classname", "monster_human_grunt_ally" },
    { "$i_spark_color", "4" },
    { "model", "models/bts_rc/monsters/rgrunt_opfor.mdl" }

}; test_chamber::RegisterSpawner( "Robot", kvs );
kvs = {
    { "classname", "monster_zombie_soldier" },
    { "model", "models/bts_rc/monsters/zombie_engineer.mdl" }
}; test_chamber::RegisterSpawner( "Zombie Engineer", kvs );
kvs = {
    { "bloodcolor", "1" },
    { "classname", "monster_zombie_soldier" },
    { "$i_spark_hitgroup", "10" },
    { "$i_spark_color", "5" },
    { "soundlist", "zombie_hev.txt" },
    { "model", "models/bts_rc/monsters/zombie_hev.mdl" }
}; test_chamber::RegisterSpawner( "HEV Zombie", kvs );
} // test_chamber
