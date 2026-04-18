final class BTS_Json
{
    private dictionary m_Data;

    private array<string> m_Required;

    dictionary@ get_Data(){
        return @this.m_Data;
    }

    BTS_Json( dictionary@ json )
    {
        this.m_Data = json;
    }

    bool get( const string&in keyName, bool&out value, bool defaultValue = false, bool required = false, dictionary@&out data = this.m_Data )
    {
        bool exists = ( data is null ? !( @data = {} ).isEmpty() : data.get( keyName, value ) );

        if( !exists )
            value = defaultValue;

#if METAMOD_DEBUG
        dictionary schema = {
            { "type", "bool" },
            { "required", required },
            { "default", defaultValue }
        }; data[ keyName ] = schema;
#endif

        return exists;
    }

    dictionary@ opIndex( const string&in keyName )
    {
        return cast<dictionary@>( this.m_Data[ keyName ] );
    }

    void GenerateSchema()
    {
#if METAMOD_DEBUG
        this.m_Data.delete( "$schema" );

        dictionary schema = {
            { "$schema", "http://json-schema.org/draft-07/schema#" },
            { "type", "object" },
            { "additionalProperties", "false" },
            { "required", this.m_Required },
            { "properties", this.m_Data }
        };

        meta_api::json::Serialize( schema, 1, "bts_rc_config_schema" );
#endif
    }

    ~BTS_Json()
    {
        this.GenerateSchema();
    }
}
