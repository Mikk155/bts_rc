import { defineConfig } from "vite";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

const serveDefaultConfig =
{
    name: "serve-default-config",
    configureServer( server )
    {
        server.middlewares.use( async ( request, response, next ) =>
        {
            if( request.url?.split( "?" )[ 0 ] !== "/__default_config.json" )
            {
                next();
                return;
            }

            try
            {
                const configPath = resolve(
                    process.cwd(),
                    "../../scripts/maps/bts_rc/default_config.json"
                );
                const config = await readFile( configPath, "utf8" );

                response.setHeader( "Content-Type", "application/json" );
                response.end( config );
            }
            catch( error )
            {
                next( error );
            }
        } );
    }
};

export default defineConfig(
{
    plugins: [ serveDefaultConfig ],
    build:
    {
        lib:
        {
            entry: "src/main.ts",
            formats: [ "es" ],
            fileName: () => "main.js"
        },
        outDir: "../../docs",
        emptyOutDir: false
    }
} );
