import { DEV } from "../main.js";

interface Contributor
{
    login : string;
    avatar_url : string;
    html_url : string;
    contributions : number;
}

interface ContributorsCache
{
    timestamp : number;
    data : Array<[ string, Contributor ]>;
}

export async function initContributors() : Promise<void>
{
    async function render( container : HTMLElement, contributors : ReadonlyMap<string, Contributor> ) : Promise<void>
    {
        container.innerHTML = "";

        const ordered : Contributor[] =
            Array.from( contributors.values() );

        ordered.sort( ( a : Contributor, b : Contributor ) : number =>
        {
            return b.contributions - a.contributions;
        } );

        let slots: number = 0;

        for( const user of ordered )
        {
            const el : HTMLAnchorElement = document.createElement( "a" );

            el.href = user.html_url;
            el.target = "_blank";
            el.className = "contributor";

            el.innerHTML = `
                <img src="${user.avatar_url}" />
                <div>${user.login}</div>
                <div>${user.contributions} contributions</div>
            `;
            slots++;

            container.appendChild( el );
        }

        // Inject dummy elements to account for GIT contributors being in 5 columns
        while( ( slots % 5 ) != 0 )
        {
            container.appendChild( document.createElement( "a" ) );
            slots++;
        }

        // credits.json
        try
        {
            const response : Response = await fetch( "assets/credits.json" );

            if( response.ok )
            {
                const users : unknown = await response.json();

                if( Array.isArray( users ) )
                {
                    for( const user of users )
                    {
                        if( typeof user !== "string" )
                            continue;

                        const element : HTMLLIElement = document.createElement( "li" );
                        element.className = "changelog-header";

                        element.innerText = user;
                        container.appendChild( element );
                    }
                }
            }
        }
        catch( err )
        {
            console.warn( "credits.json failed: ", err );
        }
    }

    async function loadFromCache( forceLoad : boolean = false ) : Promise<boolean>
    {
        const cached : string | null = localStorage.getItem( "contributors_cache" );

        if( !cached )
        {
            return false;
        }

        let parsed : ContributorsCache;

        try
        {
            parsed = JSON.parse( cached );
        }
        catch
        {
            return false;
        }

        if( !parsed || !Array.isArray( parsed.data ) )
        {
            return false;
        }

        const container : HTMLElement | null = document.getElementById( "contributor_list" );

        if( !container )
        {
            return false;
        }

        const isFresh : boolean = Date.now() - parsed.timestamp < ( 1000 * 60 * 5 );

        if( forceLoad || isFresh )
        {
            const map : Map<string, Contributor> = new Map( parsed.data );
            await render( container, map );
            return true;
        }

        return false;
    }

    if( await loadFromCache( DEV ) )
    {
        return;
    }

    const contributors : Map<string, Contributor> = new Map();

    let res : Response;

    try
    {
        res = await fetch( "https://api.github.com/repos/Mikk155/bts_rc/contributors" );
    }
    catch( err )
    {
        console.error( "Fetch failed: ", err );
        await loadFromCache( true );
        return;
    }

    if( !res.ok )
    {
        console.error( "HTTP Error:", res.status );
        await loadFromCache( true );
        return;
    }

    const data : unknown = await res.json();

    if( !Array.isArray( data ) )
    {
        console.error( "Invalid response: ", data );
        await loadFromCache( true );
        return;
    }

    for( const user of data )
    {
        if( typeof user !== "object" || user === null || !( "login" in user ) )
        {
            continue;
        }

        const contributor : Contributor =
        {
            login : String( ( user as any ).login ),
            avatar_url : String( ( user as any ).avatar_url ),
            html_url : String( ( user as any ).html_url ),
            contributions : Number( ( user as any ).contributions )
        };

        contributors.set(
            contributor.login.toLowerCase(),
            contributor
        );
    }

    localStorage.setItem( "contributors_cache",
        JSON.stringify(
        {
            timestamp : Date.now(),
            data : Array.from( contributors.entries() )
        } )
    );

    const container : HTMLElement | null = document.getElementById( "contributor_list" );

    if( !container )
    {
        console.warn( "Container not found" );
        return;
    }

    await render( container, contributors );
}
