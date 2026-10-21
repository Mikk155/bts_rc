
/*
*   Author: Mikk
*   Original Code: Gaftherman
*   Original Idea: EdgarBarney (Trinity Rendering)
*/

final class BTSBloodPuddle : BTSRegistry, IBTSConfigurable
{
    private
        float[] m_DefaultSize = { 1.5f, 2.5f };

    private
        dictionary m_CustomSizes;

    private
        bool m_persistent;

    BTSBloodPuddle()
    {
        bts_BloodPuddle.opHndlAssign(this);
    }

    const string& GetName() const override
    {
        return "Blood Puddle";
    }

    const string ConfigLabel() const override
    {
        return "bloodpuddle";
    }

    dictionary@ ConfigSchema() const override
    {
        return
        {
            { "type", "object" },
            { "unevaluatedProperties", false },
            { "title", this.GetName() },
            { "description", "Controls blood puddle behavior and appearance." },
            { "properties", {
                { "active", "Should monsters generate blood puddle effects on dying?" },
                { "persistent", {
                    { "type", "boolean" },
                    { "description", "If true: puddles remain indefinitely until the map is about at 100 free entity slots. Otherwise they fade out as soon as the monster owner disappears." }
                } },
                { "default_size", {
                    { "type", "array" },
                    { "minItems", 2 },
                    { "maxItems", 2 },
                    { "items",
                    {
                        { "minimum", 0.1f },
                        { "type", "number" }
                    } },
                    { "description", "Random size range for puddles (min }, max)." }
                } },
                { "custom_size", {
                    { "type", "object" },
                    { "additionalProperties", {
                        { "type", "array" },
                        { "minItems", 2 },
                        { "maxItems", 2 },
                        { "items", {
                            { "minimum", 0.1f },
                            { "type", "number" }
                        } },
                        { "prefixItems", {
                            { "0", { "description", "Minimun scale size for randomization" } } },
                            { "1", { "description", "Maximun scale size for randomization" } } }
                        }
                    } },
                    { "description", "Per-monster custom puddle size overrides." }
                } }
            }
        };
    }

    bool ConfigParse( btson@ json ) override
    {
        if( !bool( json[ "active" ] ) )
        {
            this.Shutdown();
            return false;
        }

        return false;
    }

    void MapInit() override
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "env_bloodpuddle", "env_bloodpuddle" );
        g_Game.PrecacheModel( "models/mikk155/misc/bloodpuddle.mdl" );
    }
}

weakref<BTSBloodPuddle> bts_BloodPuddle;
