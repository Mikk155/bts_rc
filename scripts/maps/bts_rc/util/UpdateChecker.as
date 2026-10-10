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

void UpdateChecker()
{
#if METAMOD_PLUGIN_ASCURL
    // Tell server ops there's a new update
    int requestID = g_EngineFuncs.CreateHTTPRequest( "https://api.github.com/repos/Mikk155/bts_rc/releases/latest", true, 0, 5000, 10000 );
    g_EngineFuncs.AppendHTTPRequestHeader(requestID, "User-Agent: sven-coop" );
    g_EngineFuncs.AppendHTTPRequestHeader(requestID, "Accept: application/vnd.github+json" );
    g_EngineFuncs.SetHTTPRequestCallback( requestID, function( int reqid )
    {
        int response_code = 0;
        string response_string;
        g_EngineFuncs.GetHTTPResponse( reqid, response_code, void, response_string );

        if( response_code >= 200 )
        {
            dictionary response_json;
            if( meta_api::json::v1::Deserialize( response_string, response_json ) )
            {
                string tagName;

                if( response_json.get( "tag_name", tagName ) )
                {
                    const SemanticVersion@ latestVersion = SemVer( tagName, true );

                    if( latestVersion > g_ScriptsVersion )
                    {
                        g_EngineFuncs.ServerPrint( "Map scripts got a newer version released!\n" );
                        g_EngineFuncs.ServerPrint( "https://github.com/Mikk155/bts_rc/releases/tag/" + latestVersion.ToString() + "\n" );
                    }
                }
            }
            g_EngineFuncs.DestroyHTTPRequest(reqid);
        }
    } );
    g_EngineFuncs.SendHTTPRequest( requestID );
#endif
}
