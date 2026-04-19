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

namespace ConfigContext
{
    /// List containing all the registered IConfigContext instances for registration.
    array<IConfigContext@> g_ConfigContexts;

    void Register( IConfigContext@ context )
    {
        g_ConfigContexts.insertLast( context );

        if( g_Logger.info )
            g_Logger.info = snprintf( glog, "Registering config context \"%1\"", context.Name );
    }

    void MapInit( dictionary@ data )
    {
        uint length = g_ConfigContexts.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            auto context = g_ConfigContexts[ui];
            string name = context.Name;

            if( data.exists( name ) )
            {
                if( g_Logger.info )
                    g_Logger.info = snprintf( glog, "Parsing configuration context for \"%1\"", context.Name );

                context.Parse( cast<dictionary@>( data[ name ] ) );
            }
            else
            {
                if( g_Logger.critical )
                    g_Logger.critical = snprintf( glog, "Failed to find context \"%1\" in config.json", context.Name );
            }
        }
    }
}
