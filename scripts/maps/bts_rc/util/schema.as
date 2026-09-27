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
        bool is_type( btson@ obj, btson@ schema, const string&in name )
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
                    obj.opAssign( schema[ "default" ] );
            }

            return false;
        }

        private bool Validate( btson@ obj, btson@ schema, const string&in name )
        {
            if( !this.is_type( obj, schema, name ) && this.strict )
                return false;

            switch( obj.Type )
            {
                case meta_api::json::Type::Object:
                case meta_api::json::Type::Array:
                {
                    btson@ schemaProperties = schema.ValueOrDefault( ( obj.is_object() ? "properties" : "items" ) ).Copy();

                    array<string> additionalProperties(0);

                    // Array specific validations
                    if( obj.is_array() )
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
                    else
                    {
                        bool hasAdditionalProperties = schema.Contains( "additionalProperties" );

                        // Whatever non-defined properties in schema are allowed in obj
                        if( schema.ValueOrDefault( "unevaluatedProperties", true ) == false )
                        {
                            uint length = obj.Length();

                            for( uint ui = 0; ui < length; ui++ )
                            {
                                btson@ pair = obj[ui];

                                if( !schemaProperties.Contains( pair.Name ) )
                                {
                                    if( hasAdditionalProperties )
                                    {
                                        additionalProperties.insertLast( pair.Name );
                                        continue;
                                    }

                                    this.errors++;
                                    g_Logger.error.print( "{} got unevaluated property \"{}\" which is not allowed!", { name, pair.Name } );
                                    if( this.strict )
                                        return false;
                                }
                            }
                        }

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

                    btson@ additionalPropertiesSchema = schema[ "additionalProperties" ];
                    uint additionalPropertiesLength = additionalProperties.length();
                    for( uint ui = 0; ui < additionalPropertiesLength; ui++ )
                    {
                        schemaProperties.Set( additionalProperties[ui], additionalPropertiesSchema.Copy() );
                    }

                    // validate all properties
                    uint length = schemaProperties.Length();

                    for( uint ui = 0; ui < length; ui++ )
                    {
                        btson@ pair = schemaProperties[ui];

                        btson@ childObj = obj[ pair.Name ];

                        if( childObj is null )
                        {
                            if( !this.strict )
                            {
                                if( pair.Contains( "default" ) )
                                {
                                    // -TODO DeepCopy
                                    @childObj = pair[ "default" ].Copy();
                                    obj.Set( pair.Name, childObj );
                                }
                            }

                            if( childObj is null )
                                continue;
                        }

                        string childName;
                        snprintf( childName, "%1->%2", name, pair.Name );

                        bool result = this.Validate( childObj, pair, childName );

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

        bool Validate( btson@ obj, btson@ schema )
        {
            return this.Validate( obj, schema, "<root>" );
        }
    }

    /// Validate obj against schema
    /// strict: if true the method will return false right away stoping the validation.
    /// Otherwise the validation will keep going removing invalid values, attempting to set defaults if provided by the schema.
    bool Validate( btson@ obj, btson@ schema, bool strict = false )
    {
        Validator validator( strict );
        return validator.Validate( obj, schema );
    }

    /// Validate obj against schema
    /// strict: if true the method will return false right away stoping the validation.
    /// Otherwise the validation will keep going removing invalid values, attempting to set defaults if provided by the schema.
    bool Validate( btson@ obj, const string&in schema, bool strict = false )
    {
        btson@ schemaObject;
        return Deserialize( schema, schemaObject ) && Validate( obj, schemaObject, strict );
    }
} // schema
