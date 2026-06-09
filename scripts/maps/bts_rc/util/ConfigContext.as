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

/// Interface for configuration contexts
abstract class IConfigurable
{
    IConfigurable()
    {
        ConfigContext::Register( this );
    }

    /// Unique name for this context
    const string& get_Name() {
        return String::EMPTY_STRING;
    }

    /// Called at MapInit for parsing the object from the json with this class's Name. See this.IsActive() to register your stuff
    void Register( meta_api::json::v2::json@ json ) {
    }

    bool m_IsActive;

    /// Whatever the context is active or not
    const bool IsActive() {
        return this.m_IsActive;
    }
}

/// List containing all the registered IConfigurable instances for registration.
array<IConfigurable@> g_ConfigContexts;

namespace ConfigContext
{
    void Register( IConfigurable@ context )
    {
        if( g_Logger.info.active )
            g_Logger.info.print( snprintf( glog, "Registering config context \"%1\"", context.Name ) );

        g_ConfigContexts.insertLast( context );
    }

    void Registry( meta_api::json::v2::json@ json, Server::chrono@ chrono )
    {
        uint length = g_ConfigContexts.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            IConfigurable@ configurable = g_ConfigContexts[ui];
            string name = configurable.Name;

            meta_api::json::v2::json@ contextData = json.ValueOrDefault(name);

            if( !contextData.is_object() || contextData.Length() <= 0 )
                g_Logger.warning.print( snprintf( glog, "Couldn't retrieve object \"%1\" from json. using defaults...", name ) );

            // If not explicitly false we asume true
            configurable.m_IsActive = contextData.ValueOrDefault( "active", true );

            if( g_Logger.info.active )
                g_Logger.info.print( snprintf( glog, "Parsing configuration context for \"%1\" with state %2", configurable.Name, ( configurable.IsActive() ? "Active" : "Disabled" ) ) );

            configurable.Register( json.ValueOrDefault( name ) );
        }
        
        if( g_Logger.info.active )
        {
            chrono.Stop();
            g_Logger.info.print( snprintf( glog, "Configured all config contexts. %1:%2 seconds elapsed since the map started.", chrono.Seconds, chrono.Miliseconds ) );
        }
    }
}
