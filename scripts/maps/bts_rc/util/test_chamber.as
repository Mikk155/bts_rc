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
};
test_chamber::RegisterSpawner( "Enforcer", kvs );
} // test_chamber
