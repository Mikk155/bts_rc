interface IBTSConfigurable
{
    // Schema validation
    dictionary@ ConfigSchema() const;

    // Json config label name.
    const string ConfigLabel() const;

    // Called first at MapInit with the json object at the root containing this.ConfigLabel() as key.
    // Can be called again runtime.
    // Return false if no config matched.
    bool ConfigParse( btson@ json );
}
