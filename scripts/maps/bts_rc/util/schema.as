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

namespace schema
{
    class Validator
    {
        private
            bool m_Strict = true;

        const bool get_strict() const {
            return this.m_Strict;
        }

        Validator( bool strict )
        {
            this.m_Strict = strict;
        }

        Validator() {}

        private
            uint errors = 0;

        // Return whatever the given obj is of type of the given string.
        bool is_type( btson@ obj, btson@ schema, const string&in name, btson@ defaults )
        {
            if( !schema.Contains( "type" ) )
            {
                this.errors++;
                g_Logger.error.print( "{} expected \"type\" at schema but is undefined!", { name } );
                return false;
            }

            string expectedTypeString = string( schema[ "type" ] );
            meta_api::json::Type expectedType = meta_api::json::Type::FromString( expectedTypeString );
            bool isType = false;

            if( expectedTypeString.IsEmpty() )
            {
                this.errors++;
                g_Logger.error.print( "Unexpected empty type at schema!" );
                return false;
            }

            switch( expectedType )
            {
                case meta_api::json::Type::Object:
                    isType = obj.is_object();
                break;
                case meta_api::json::Type::Array:
                    isType = obj.is_array();
                break;
                case meta_api::json::Type::String:
                    isType = obj.is_string();
                break;
                case meta_api::json::Type::Integer:
                    isType = obj.is_number_integer();
                break;
                case meta_api::json::Type::Float:
                    isType = obj.is_number();
                break;
                case meta_api::json::Type::Boolean:
                    isType = obj.is_boolean();
                break;
                case meta_api::json::Type::Null:
                    isType = obj.is_null();
                break;
                default:
                    this.errors++;
                    g_Logger.error.print( "schema unknown \"type\" {}", { expectedTypeString } );
                    if( true )
                        return false;
                break;
            }

            if( isType )
                return true;

            this.errors++;
            g_Logger.error.print( "{} Expected {} got {}", { name, expectedTypeString, meta_api::json::Type::ToString(obj.Type) } );

            if( !this.strict )
            {
                obj.Clear();
                obj.SetType( expectedType );

                if( schema.Contains( "default" ) )
                {
                    // -TODO DeepCopy
                    obj.opAssign( schema[ "default" ].Copy() );
                }
                else if( defaults !is null )
                {
                    obj.opAssign( defaults.Copy() );
                }
            }

            return false;
        }

        private bool Validate( btson@ obj, btson@ schema, const string&in name, btson@ defaults )
        {
            if( !this.is_type( obj, schema, name, defaults ) && this.strict )
                return false;

            switch( obj.Type )
            {
                case meta_api::json::Type::Object:
                case meta_api::json::Type::Array:
                {
                    bool is_array = obj.is_array();

                    btson@ schemaProperties = schema.ValueOrDefault( "properties" ).Copy();

                    // Array specific validations
                    if( is_array )
                    {
                        uint uiTemp;

                        if( schema.Get( "minItems", uiTemp ) && obj.Length() < uiTemp )
                        {
                            this.errors++;
                            g_Logger.error.print( "{} array has less items than minimum expected {} or more. got {}", { name, uiTemp, obj.Length() } );
                            if( this.strict )
                                return false;
                        }

                        if( schema.Get( "maxItems", uiTemp ) && obj.Length() > uiTemp )
                        {
                            this.errors++;
                            g_Logger.error.print( "{} array has more items than maximum expected {} or less. got {}", { name, uiTemp, obj.Length() } );
                            if( this.strict )
                                return false;
                        }
                    }

                    // Validate over additional properties and if they're allowed.
                    if( obj.Length() > schemaProperties.Length() )
                    {
                        btson@ additionalPropertiesSchema = schema[ "additionalProperties" ];
                        bool isArrayAdditionalProperties = ( additionalPropertiesSchema !is null && string( additionalPropertiesSchema[ "type" ] ) == "array" );
                        bool hasAdditionalProperties = ( additionalPropertiesSchema !is null );
                        bool allowUnevaluatedProperties = schema.ValueOrDefault( "unevaluatedProperties", true );

                        const array<string>@ keys = obj.Keys;
                        uint length = obj.Length();

                        for( uint ui = 0; ui < length; ui++ )
                        {
                            string key = keys[ui];
                            btson@ value = obj[key];

                            if( isArrayAdditionalProperties )
                            {
                                schemaProperties.Set( key, additionalPropertiesSchema.Copy() );
                                continue;
                            }
                            else if( !schemaProperties.Contains( key ) )
                            {
                                if( hasAdditionalProperties )
                                {
                                    if( additionalPropertiesSchema.Contains( key ) )
                                    {
                                        schemaProperties.Set( key, additionalPropertiesSchema[ key ].Copy() );
                                        continue;
                                    }
                                }
                            }

                            if( allowUnevaluatedProperties )
                                continue;

                            this.errors++;
                            g_Logger.error.print( "{} got unevaluated property \"{}\" ({}) which is not allowed!", { name, key, meta_api::json::Type::ToString(value.Type) } );
                            if( this.strict )
                                return false;

                            --length;
                            obj.Remove( ui );
                            --ui;
                        }
                    }

                    if( !is_array )
                    {
                        // Whatever required properties in schema are defined in obj
                        if( schema.Contains( "required" ) )
                        {
                            btson@ required = schema.ValueOrDefault( "required" );

                            uint length = required.Length();

                            for( uint ui = 0; ui < length; ui++ )
                            {
                                string key = string( required[ui] );

                                if( !obj.Contains( key ) )
                                {
                                    this.errors++;
                                    g_Logger.error.print( "{} missing required key \"{}\"", { name, key } );
                                    if( this.strict )
                                        return false;
                                }
                            }
                        }
                    }

                    // validate all properties
                    const array<string>@ keys = schemaProperties.Keys;
                    uint length = schemaProperties.Length();

                    for( uint ui = 0; ui < length; ui++ )
                    {
                        string key = keys[ui];
                        btson@ value = schemaProperties[key];

                        btson@ childObj = obj[key];
                        btson@ defaultChild = ( defaults !is null ? defaults[ key ] : null );

                        if( childObj is null )
                        {
                            if( value.Contains( "default" ) )
                            {
                                // -TODO DeepCopy
                                @childObj = value[ "default" ].Copy();
                                obj.Set( key, childObj );
                            }
                            else if( defaultChild !is null )
                            {
                                // -TODO DeepCopy
                                @childObj = defaultChild.Copy();
                                obj.Set( key, childObj );
                            }

                            if( childObj is null )
                                continue;
                        }

                        string childName;
                        snprintf( childName, "%1->%2", name, key );

                        bool result = this.Validate( childObj, value, childName, defaultChild );

                        if( this.strict && result == false )
                            return false;
                    }

                    break;
                }
                case meta_api::json::Type::Integer:
                case meta_api::json::Type::Float:
                {
                    float fTemp;
                    float fValue;

                    if( schema.Get( "minimum", fTemp, false ) && obj.Get( fValue, false ) && fValue < fTemp )
                    {
                        obj.opAssign(fTemp);
                        this.errors++;
                        g_Logger.error.print( "{} value is lesser than minimum expected {} or more. got {}", { name, fTemp, fValue } );
                        if( this.strict )
                            return false;
                    }

                    if( schema.Get( "maximum", fTemp, false ) && obj.Get( fValue, false ) && fValue > fTemp )
                    {
                        obj.opAssign(fTemp);
                        this.errors++;
                        g_Logger.error.print( "{} value is higher than maximum expected {} or less. got {}", { name, fTemp, fValue } );
                        if( this.strict )
                            return false;
                    }
                    break;
                }
            }

            return ( this.errors == 0 );
        }

        bool Validate( btson@ obj, btson@ schema, btson@ defaults )
        {
            return this.Validate( obj, schema, "<root>", defaults );
        }
    }

    /// Validate obj against schema
    /// strict: if true the method will return false right away stoping the validation.
    /// Otherwise the validation will keep going removing invalid values, attempting to set defaults if provided by the schema.
    bool Validate( btson@ obj, btson@ schema, bool strict = false, btson@ defaults = null )
    {
        Validator validator( strict );
        return validator.Validate( obj, schema, defaults );
    }

    /// Validate obj against schema
    /// strict: if true the method will return false right away stoping the validation.
    /// Otherwise the validation will keep going removing invalid values, attempting to set defaults if provided by the schema.
    bool Validate( btson@ obj, const string&in schema, bool strict = false, btson@ defaults = null )
    {
        btson@ schemaObject;
        return Deserialize( schema, schemaObject ) && Validate( obj, schemaObject, strict, defaults );
    }
} // schema
