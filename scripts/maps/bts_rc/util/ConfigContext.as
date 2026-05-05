/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/// Interface for configuration contexts
/// Call ConfigContext::Register( this ) on your class constructor.
interface IConfigContext
{
    /// Unique name for this context
    const string& get_Name();

    /// Called at MapInit for parsing the object from the json with this class's Name
    void Parse( dictionary@ json );
}

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

    /// Called at MapInit for parsing the object from the json with this class's Name. if "active" is not false
    void Register( BTSJson@ json ) {
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
        if( g_Logger.info )
            g_Logger.info = snprintf( glog, "Registering config context \"%1\"", context.Name );

        g_ConfigContexts.insertLast( context );
    }

    void Registry( BTSJson@ json )
    {
        uint length = g_ConfigContexts.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            IConfigurable@ configurable = g_ConfigContexts[ui];
            string name = configurable.Name;

            if( g_Logger.info )
                g_Logger.info = snprintf( glog, "Parsing configuration context for \"%1\"", configurable.Name );

            BTSJson@ contextData = json.FirstOrDefault( name );

            // If not explicitly false we asume true
            configurable.m_IsActive = contextData.FirstOrDefault( "active", true );

            if( configurable.IsActive() )
            {
                configurable.Register( json.FirstOrDefault( name ) );
            }
            else if( g_Logger.warning )
            {
                g_Logger.warning = snprintf( glog, "Ignoring disabled context \"%1\"", configurable.Name );
            }

        }

        for( uint ui = 0; ui < gptest.length(); ui++ )
        {
            IConfigContext@ configurable = gptest[ui];
            string name = configurable.Name;
            configurable.Parse( cast<dictionary@>( json.data[ name ] ) );
        }
    }
array<IConfigContext@> gptest;

    void Register( IConfigContext@ context )
    {
        gptest.insertLast(context);
    }
}
