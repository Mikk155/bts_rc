import { defineConfig } from "vite";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

const serveDefaultConfig =
{
    name: "serve-default-config",
    apply: "serve",
    configureServer( server )
    {
        const localFiles: Record<string, string> =
        {
            "/__default_config.json": resolve(
                process.cwd(),
                "../../scripts/maps/bts_rc/default_config.json"
            ),
            "/__changelog.md": resolve( process.cwd(), "../../CHANGELOG.md" )
        };

        server.middlewares.use( async ( request, response, next ) =>
        {
            const filePath = localFiles[ request.url?.split( "?" )[ 0 ] ?? "" ];

            if( !filePath )
            {
                next();
                return;
            }

            try
            {
                const content = await readFile( filePath, "utf8" );

                response.setHeader(
                    "Content-Type",
                    filePath.endsWith( ".json" ) ? "application/json" : "text/markdown; charset=utf-8"
                );
                response.end( content );
            }
            catch( error )
            {
                next( error );
            }
        } );
    },
    transformIndexHtml( html )
    {
        const sourceEntry = resolve( process.cwd(), "src/main.ts" )
            .replace( /\\/g, "/" );

        return html.replace(
            '<script type="module" src="bts_rc.bundle.js"></script>',
            `<script type="module" src="/@fs/${sourceEntry}"></script>`
        );
    }
};

export default defineConfig(
{
    plugins: [ serveDefaultConfig ],
    server:
    {
        fs:
        {
            allow: [ resolve( process.cwd(), "../.." ) ]
        }
    },
    build:
    {
        lib:
        {
            entry: "src/main.ts",
            formats: [ "es" ],
            fileName: () => "bts_rc.bundle.js"
        },
        outDir: "../../docs",
        emptyOutDir: false
    }
} );
