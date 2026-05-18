namespace json_v2_tests
{
    bool g_CommandRegistered = false;
    uint g_Passed = 0;
    uint g_Failed = 0;

    CClientCommand g_DirectCommand( "jsonv2_test", "run json v2 parser sanity checks", function( const CCommand@ args )
    {
        CBasePlayer@ player = g_ConCommandSystem.GetCurrentPlayer();

        if( player is null )
            return;

        json_v2_tests::Run( player );
    } );

    void PrintServerLine( const string&in message )
    {
        g_Game.AlertMessage( at_console, "%1\n", message );
    }

    void PrintLine( CBasePlayer@ player, const string&in message )
    {
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, message + "\n" );
    }

    void Expect( CBasePlayer@ player, const string&in name, bool condition )
    {
        if( condition )
        {
            g_Passed++;
            PrintLine( player, "[json v2 test] PASS: " + name );
            return;
        }

        g_Failed++;
        PrintLine( player, "[json v2 test] FAIL: " + name );
    }

    void ExpectServer( const string&in name, bool condition )
    {
        if( condition )
        {
            g_Passed++;
            PrintServerLine( "[json v2 test] PASS: " + name );
            return;
        }

        g_Failed++;
        PrintServerLine( "[json v2 test] FAIL: " + name );
    }

    meta_api::json::v2::json@ DeserializeCase( CBasePlayer@ player, const string&in name, const string&in source, bool expected )
    {
        meta_api::json::v2::json@ obj;
        bool result = meta_api::json::v2::Deserialize( source, obj );

        Expect( player, name, result == expected );

        if( result )
            return obj;

        return null;
    }

    meta_api::json::v2::json@ DeserializeServerCase( const string&in name, const string&in source, bool expected )
    {
        meta_api::json::v2::json@ obj;
        bool result = meta_api::json::v2::Deserialize( source, obj );

        ExpectServer( name, result == expected );

        if( result )
            return obj;

        return null;
    }

    void Run( CBasePlayer@ player )
    {
        g_Passed = 0;
        g_Failed = 0;

        PrintLine( player, "[json v2 test] Running sanity checks..." );

        meta_api::json::v2::json@ obj = DeserializeCase(
            player,
            "valid object with comments and nested values",
            "{// comment\n\"null\":null,\"bool\":true,\"int\":1,\"float\":1.5,\"string\":\"text\",\"object\":{\"value\":2},\"array\":[\"x\",true,2,3.5,{\"key\":\"value\"}]}",
            true
        );

        if( obj !is null )
        {
            bool boolValue = false;
            int intValue = 0;
            float floatValue = 0.0f;
            string stringValue;

            Expect( player, "strict bool read", obj.Get( "bool", boolValue ) && boolValue );
            Expect( player, "strict integer read", obj.Get( "int", intValue ) && intValue == 1 );
            Expect( player, "strict float read", obj.Get( "float", floatValue ) && floatValue == 1.5f );
            Expect( player, "strict string read", obj.Get( "string", stringValue ) && stringValue == "text" );
            Expect( player, "null key exists", obj.Contains( "null" ) );

            meta_api::json::v2::json@ nullValue = obj.First( "null" );
            Expect( player, "null value keeps null type", nullValue !is null && nullValue.is_null );

            bool rejectedBool = false;
            Expect( player, "strict bool rejects integer", !obj.Get( "int", rejectedBool ) );
            Expect( player, "non-strict bool converts integer", obj.Get( "int", rejectedBool, false ) && rejectedBool );

            int defaultValue = obj.FirstOrDefault( "missing_integer", 42, true );
            int storedDefault = 0;
            Expect( player, "FirstOrDefault returns missing default", defaultValue == 42 );
            Expect( player, "FirstOrDefault stores missing default", obj.Get( "missing_integer", storedDefault ) && storedDefault == 42 );

            meta_api::json::v2::json@ objectValue = obj.First( "object" );
            Expect( player, "object node keeps key name", objectValue !is null && objectValue.Name == "object" );
            Expect( player, "nested object value read", objectValue !is null && int( objectValue.First( "value" ) ) == 2 );

            meta_api::json::v2::json@ pushResult = obj.push_back( "something" );
            Expect( player, "push_back on object returns null", pushResult is null );

            meta_api::json::v2::json@ arrayValue = obj.First( "array" );
            Expect( player, "array node has expected length", arrayValue !is null && arrayValue.is_array && arrayValue.Length() == 5 );

            if( arrayValue !is null )
            {
                Expect( player, "array push_back appends value", arrayValue.push_back( "something" ) !is null && arrayValue.Length() == 6 && string( arrayValue[5] ) == "something" );

                meta_api::json::v2::json@ nestedObjectInArray = arrayValue[4];
                Expect( player, "nested object in array keeps key name", nestedObjectInArray !is null && nestedObjectInArray.Name == "4" );
                Expect( player, "nested object in array value read", nestedObjectInArray !is null && string( nestedObjectInArray.First( "key" ) ) == "value" );
                Expect( player, "array opIndex rejects out of range", arrayValue[32] is null );
            }

            string serialized = meta_api::json::v2::Serialize( 1, obj );
            Expect( player, "Serialize returns object text", serialized.Length() > 2 );
        }

        meta_api::json::v2::json@ rootArray = DeserializeCase( player, "valid root array", "[\"string\",1]", true );

        if( rootArray !is null )
        {
            Expect( player, "root array has expected length", rootArray.is_array && rootArray.Length() == 2 );
            Expect( player, "root array string read", string( rootArray[0] ) == "string" );
            Expect( player, "root array integer read", int( rootArray[1] ) == 1 );
        }

        DeserializeCase( player, "reject invalid literal", "{\"value\":tru}", false );
        DeserializeCase( player, "reject missing comma in array", "[1 2]", false );
        DeserializeCase( player, "reject trailing comma in object", "{\"value\":1,}", false );
        DeserializeCase( player, "reject trailing comma in array", "[1,]", false );
        DeserializeCase( player, "reject unterminated object", "{\"value\":1", false );
        DeserializeCase( player, "reject broken nested object", "{\"array\":[1,{\"value\":2]}", false );
        DeserializeCase( player, "reject trailing root data", "{\"value\":1} true", false );

        string summary;
        snprintf( summary, "[json v2 test] Finished. Passed: %1 Failed: %2", g_Passed, g_Failed );
        PrintLine( player, summary );
    }

    void RunServer()
    {
        g_Passed = 0;
        g_Failed = 0;

        PrintServerLine( "[json v2 test] Running sanity checks..." );

        meta_api::json::v2::json@ obj = DeserializeServerCase(
            "valid object with comments and nested values",
            "{// comment\n\"null\":null,\"bool\":true,\"int\":1,\"float\":1.5,\"string\":\"text\",\"object\":{\"value\":2},\"array\":[\"x\",true,2,3.5,{\"key\":\"value\"}]}",
            true
        );

        if( obj !is null )
        {
            bool boolValue = false;
            int intValue = 0;
            float floatValue = 0.0f;
            string stringValue;

            ExpectServer( "strict bool read", obj.Get( "bool", boolValue ) && boolValue );
            ExpectServer( "strict integer read", obj.Get( "int", intValue ) && intValue == 1 );
            ExpectServer( "strict float read", obj.Get( "float", floatValue ) && floatValue == 1.5f );
            ExpectServer( "strict string read", obj.Get( "string", stringValue ) && stringValue == "text" );
            ExpectServer( "null key exists", obj.Contains( "null" ) );

            meta_api::json::v2::json@ nullValue = obj.First( "null" );
            ExpectServer( "null value keeps null type", nullValue !is null && nullValue.is_null );

            bool rejectedBool = false;
            ExpectServer( "strict bool rejects integer", !obj.Get( "int", rejectedBool ) );
            ExpectServer( "non-strict bool converts integer", obj.Get( "int", rejectedBool, false ) && rejectedBool );

            int defaultValue = obj.FirstOrDefault( "missing_integer", 42, true );
            int storedDefault = 0;
            ExpectServer( "FirstOrDefault returns missing default", defaultValue == 42 );
            ExpectServer( "FirstOrDefault stores missing default", obj.Get( "missing_integer", storedDefault ) && storedDefault == 42 );

            meta_api::json::v2::json@ objectValue = obj.First( "object" );
            ExpectServer( "object node keeps key name", objectValue !is null && objectValue.Name == "object" );
            ExpectServer( "nested object value read", objectValue !is null && int( objectValue.First( "value" ) ) == 2 );

            meta_api::json::v2::json@ pushResult = obj.push_back( "something" );
            ExpectServer( "push_back on object returns null", pushResult is null );

            meta_api::json::v2::json@ arrayValue = obj.First( "array" );
            ExpectServer( "array node has expected length", arrayValue !is null && arrayValue.is_array && arrayValue.Length() == 5 );

            if( arrayValue !is null )
            {
                ExpectServer( "array push_back appends value", arrayValue.push_back( "something" ) !is null && arrayValue.Length() == 6 && string( arrayValue[5] ) == "something" );

                meta_api::json::v2::json@ nestedObjectInArray = arrayValue[4];
                ExpectServer( "nested object in array keeps key name", nestedObjectInArray !is null && nestedObjectInArray.Name == "4" );
                ExpectServer( "nested object in array value read", nestedObjectInArray !is null && string( nestedObjectInArray.First( "key" ) ) == "value" );
                ExpectServer( "array opIndex rejects out of range", arrayValue[32] is null );
            }

            string serialized = meta_api::json::v2::Serialize( 1, obj );
            ExpectServer( "Serialize returns object text", serialized.Length() > 2 );
        }

        meta_api::json::v2::json@ rootArray = DeserializeServerCase( "valid root array", "[\"string\",1]", true );

        if( rootArray !is null )
        {
            ExpectServer( "root array has expected length", rootArray.is_array && rootArray.Length() == 2 );
            ExpectServer( "root array string read", string( rootArray[0] ) == "string" );
            ExpectServer( "root array integer read", int( rootArray[1] ) == 1 );
        }

        DeserializeServerCase( "reject invalid literal", "{\"value\":tru}", false );
        DeserializeServerCase( "reject missing comma in array", "[1 2]", false );
        DeserializeServerCase( "reject trailing comma in object", "{\"value\":1,}", false );
        DeserializeServerCase( "reject trailing comma in array", "[1,]", false );
        DeserializeServerCase( "reject unterminated object", "{\"value\":1", false );
        DeserializeServerCase( "reject broken nested object", "{\"array\":[1,{\"value\":2]}", false );
        DeserializeServerCase( "reject trailing root data", "{\"value\":1} true", false );

        string summary;
        snprintf( summary, "[json v2 test] Finished. Passed: %1 Failed: %2", g_Passed, g_Failed );
        PrintServerLine( summary );
    }

    void RegisterJsonV2TestCommand()
    {
        if( g_CommandRegistered )
            return;

        g_CommandRegistered = true;
    }
}
