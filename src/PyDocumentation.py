import os;
import json;
import pathlib;
from main import *

class PyDocumentation:

    def Build() -> bool:

        def loadSchemaObject() -> dict:
            schemaPath: str = os.path.join( gpWorkspace, "scripts", "maps", "bts_rc", "schema.json" );
            with open( os.path.join( gpWorkspace, "scripts", "maps", "bts_rc", "schema.json" ), "r", encoding="utf-8" ) as file:
                return json.load( file );
            print( "Error: Couldn't open {}".format( schemaPath ) );
            sys.exit(1);

        # supports only internal refs (#/$defs/...)
        def resolveSchemaRef( schema: dict, ref: str ) -> dict:
            refNormalized: str = ref.strip( "#/" );
            refParts: list[str] = refNormalized.split( "/" );
            node: dict = schema
            for p in refParts:
                node = node[p];
            return node;

        def buildRow( name: str, fullname: str, prop: dict, is_pattern: Optional[bool] = False )-> dict:
            return {
                "name": name,
                "fullname": fullname,
                "type": prop.get( "type", "object" ),
                "description": prop.get( "description", gpEmptyString ),
                "default": prop.get( "default", gpEmptyString ),
                "pattern": is_pattern
            };

        def extractSchemaProperties( schema, root, path: Optional[str] = gpEmptyString ):

            rows: list[dict] = [];

            props: dict = schema.get( "properties", { } );

            if "additionalProperties" in schema:
                additionalProperties: dict = schema.get( "additionalProperties" );
                props[ "additionalProperties" ] = additionalProperties;

            for name, prop in props.items():

                objType: str = prop.get( "type" );

                formatedName = name;

                if name == "additionalProperties":
                    formatedName = f"<span class=\"prop-separator\">[</span>{objType}<span class=\"prop-separator\">]</span>";

                if path:
                    full_path = f"<span class=\"prop-object\">{path}</span><span class=\"prop-separator\">-></span>{formatedName}";
                else:
                    full_path = formatedName;

                rows.append( buildRow( name, full_path, prop ) );

                # recursion
                if objType == "object":
                    rows += extractSchemaProperties( prop, root, full_path );

                if "$ref" in prop:
                    ref_obj: dict = resolveSchemaRef( root, prop[ "$ref" ] );
                    rows += extractSchemaProperties( ref_obj, root, full_path );

            return rows;

        def generateHTML( rows ):
            html: list[str] = [];

            html.append("""
<table class="schema-table">
<thead>
<tr>
    <th>Name</th>
    <th>Type</th>
    <th>Description</th>
</tr>
</thead>
<tbody>
""" );

            for r in rows:
                html.append(f"""
<tr class="schema-row" data-description="{r['description']}">
    <td>
        <span class="prop-name" data-copy="{r['name']}">
            {r['fullname']}
        </span>
    </td>
    <td>{r['type']}</td>
    <td>{r['description']}</td>
</tr>
""" );

            html.append("</tbody></table>")

            return "\n".join(html)

        schema = loadSchemaObject();

        rows = extractSchemaProperties( schema, schema )
        html = generateHTML(rows)

        documentationPath: str = os.path.join( gpWorkspace, "docs", "configuration.html" );

        documentationFile = pathlib.Path( documentationPath );

        documentationFile.write_text( html, encoding="utf-8" );

        print( "Generated {}".format( documentationPath ) );

        return True;
