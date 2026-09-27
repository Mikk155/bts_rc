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

namespace fmt
{
    /// If the json is type of Array or Object converts the values to the array type.
    /// If store is true allocate it in the json.Value and set the list handle to that array and updates the type to Handle.
    bool ToArray( btson@ jsobect, array<float>@&out list, bool strict = false, bool store = false )
    {
        if( jsobect !is null )
        {
            switch( jsobect.Type )
            {
                case meta_api::json::Type::Array:
                case meta_api::json::Type::Object:
                {
                    @list = {};
                    uint length = jsobect.Length();
                    for( uint ui = 0; ui < length; ui++ ) {
                        btson@ value = jsobect.opIndex(ui);
                        float fvalue;
                        if( value.Get( fvalue, strict ) )
                            list.insertLast( fvalue );
                    }
                    if( store )
                        jsobect.SetValue( jsobect.Value.opAssign(@list), meta_api::json::Type::Handle );
                    return true;
                }
                case meta_api::json::Type::Handle:
                {
                    array<float>@ ar = cast<array<float>@>( jsobect.Value );
                    if( ar !is null ) {
                        @list = ar;
                        return true;
                    }
                    break;
                }
            }
        }
        return false;
    }
    /// If the json is type of Array or Object converts the values to the array type.
    /// If store is true allocate it in the json.Value and set the list handle to that array and updates the type to Handle.
    bool ToArray( btson@ jsobect, array<int>@&out list, bool strict = false, bool store = false )
    {
        if( jsobect !is null )
        {
            switch( jsobect.Type )
            {
                case meta_api::json::Type::Array:
                case meta_api::json::Type::Object:
                {
                    @list = {};
                    uint length = jsobect.Length();
                    for( uint ui = 0; ui < length; ui++ ) {
                        btson@ value = jsobect.opIndex(ui);
                        int fvalue;
                        if( value.Get( fvalue, strict ) )
                            list.insertLast( fvalue );
                    }
                    if( store )
                        jsobect.SetValue( jsobect.Value.opAssign(@list), meta_api::json::Type::Handle );
                    return true;
                }
                case meta_api::json::Type::Handle:
                {
                    array<int>@ ar = cast<array<int>@>( jsobect.Value );
                    if( ar !is null ) {
                        @list = ar;
                        return true;
                    }
                    break;
                }
            }
        }
        return false;
    }
    /// If the json is type of Array or Object converts the values to the array type.
    /// If store is true allocate it in the json.Value and set the list handle to that array and updates the type to Handle.
    bool ToArray( btson@ jsobect, array<bool>@&out list, bool strict = false, bool store = false )
    {
        if( jsobect !is null )
        {
            switch( jsobect.Type )
            {
                case meta_api::json::Type::Array:
                case meta_api::json::Type::Object:
                {
                    @list = {};
                    uint length = jsobect.Length();
                    for( uint ui = 0; ui < length; ui++ ) {
                        btson@ value = jsobect.opIndex(ui);
                        bool fvalue;
                        if( value.Get( fvalue, strict ) )
                            list.insertLast( fvalue );
                    }
                    if( store )
                        jsobect.SetValue( jsobect.Value.opAssign(@list), meta_api::json::Type::Handle );
                    return true;
                }
                case meta_api::json::Type::Handle:
                {
                    array<bool>@ ar = cast<array<bool>@>( jsobect.Value );
                    if( ar !is null ) {
                        @list = ar;
                        return true;
                    }
                    break;
                }
            }
        }
        return false;
    }
    /// If the json is type of Array or Object converts the values to the array type.
    /// If store is true allocate it in the json.Value and set the list handle to that array and updates the type to Handle.
    bool ToArray( btson@ jsobect, array<string>@&out list, bool strict = false, bool store = false )
    {
        if( jsobect !is null )
        {
            switch( jsobect.Type )
            {
                case meta_api::json::Type::Array:
                case meta_api::json::Type::Object:
                {
                    @list = {};
                    uint length = jsobect.Length();
                    for( uint ui = 0; ui < length; ui++ ) {
                        btson@ value = jsobect.opIndex(ui);
                        if( strict )
                        {
                            if( value.is_string() )
                                list.insertLast( string( value ) );
                        }
                        else
                        {
                            list.insertLast( value.ToString() );
                        }
                    }

                    if( list.length() == 0 )
                        return false;

                    if( store )
                        jsobect.SetValue( jsobect.Value.opAssign(@list), meta_api::json::Type::Handle );
                    return true;
                }
                case meta_api::json::Type::Handle:
                {
                    array<string>@ ar = cast<array<string>@>( jsobect.Value );
                    if( ar !is null ) {
                        @list = ar;
                        return true;
                    }
                    break;
                }
            }
        }
        return false;
    }
} // fmt
