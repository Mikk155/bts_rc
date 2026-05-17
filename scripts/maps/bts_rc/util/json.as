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

final class BTSJson
{
    string m_name;

    const string& get_Name() {
        return this.m_name;
    }

    dictionary data;

    BTSJson@ FirstOrDefault( const string&in keyName )
    {
        dictionary jsonData;
        if( this.data.get( keyName, jsonData ) )
            return BTSJson( jsonData, keyName );
        return BTSJson( {}, keyName );
    }

    bool FirstOrDefault( const string&in keyName, bool defaultValue )
    {
        bool value;
        if( this.data.get( keyName, value ) )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( snprintf( glog, "[JSON] Got \"%1\" with value %2", keyName, ( value ? "true" : "false" ) ) );
            if( g_Logger.warning.active && value == defaultValue )
                g_Logger.warning.print( snprintf( glog, "[JSON] Got \"%1\" with the same value as the code! (%2) remove to save memory.", keyName, ( value ? "true" : "false" ) ) );
            return value;
        }
        return defaultValue;
    }

    float FirstOrDefault( const string&in keyName, float defaultValue )
    {
        float value;
        if( this.data.get( keyName, value ) )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( snprintf( glog, "[JSON] Got \"%1\" with value %2", keyName, value ) );
            if( g_Logger.warning.active && value == defaultValue )
                g_Logger.warning.print( snprintf( glog, "[JSON] Got \"%1\" with the same value as the code! (%2) remove to save memory.", keyName, value ) );
            return value;
        }
        return defaultValue;
    }

    int FirstOrDefault( const string&in keyName, int defaultValue )
    {
        int value;
        if( this.data.get( keyName, value ) )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( snprintf( glog, "[JSON] Got \"%1\" with value %2", keyName, value ) );
            if( g_Logger.warning.active && value == defaultValue )
                g_Logger.warning.print( snprintf( glog, "[JSON] Got \"%1\" with the same value as the code! (%2) remove to save memory.", keyName, value ) );
            return value;
        }
        return defaultValue;
    }

    string FirstOrDefault( const string&in keyName, const string&in defaultValue )
    {
        string value;
        if( this.data.get( keyName, value ) )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( snprintf( glog, "[JSON] Got \"%1\" with value %2", keyName, value ) );
            if( g_Logger.warning.active && value == defaultValue )
                g_Logger.warning.print( snprintf( glog, "[JSON] Got \"%1\" with the same value as the code! (%2) remove to save memory.", keyName, value ) );
            return value;
        }
        return defaultValue;
    }

    BTSJson() { }

    BTSJson( dictionary&in jsonData, const string&in name )
    {
        this.data = jsonData;
        this.m_name = name;
    }

    ~BTSJson()
    {
        this.data.clear();
    }
}
