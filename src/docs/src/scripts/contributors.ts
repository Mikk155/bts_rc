import { DEV } from "./environment.js";

interface Contributor
{
    login : string;
    avatar_url : string;
    html_url : string;
    contributions : number;
    is_credit : boolean;
}

interface ContributorsCache
{
    timestamp : number;
    data : Array<[ string, Contributor ]>;
}

export async function initContributors() : Promise<void>
{
    interface Credit
    {
        name : string;
        url : string | undefined;
    }

    async function loadCredits() : Promise<Credit[]>
    {
        try
        {
            const response : Response = await fetch( "assets/credits.json" );

            if( !response.ok )
            {
                console.warn( `credits.json returned HTTP ${response.status}` );
                return [];
            }

            const users : unknown = await response.json();

            if( !Array.isArray( users ) )
            {
                console.warn( "credits.json must contain an array" );
                return [];
            }

            return users
                .map( ( user : unknown ) : Credit | undefined =>
                {
                    if( typeof user === "string" )
                    {
                        return { name : user, url : undefined };
                    }

                    if( Array.isArray( user )
                        && typeof user[ 0 ] === "string"
                        && typeof user[ 1 ] === "string" )
                    {
                        return { name : user[ 0 ], url : user[ 1 ] };
                    }

                    return undefined;
                } )
                .filter( ( user : Credit | undefined ) : user is Credit => user !== undefined );
        }
        catch( err )
        {
            console.warn( "credits.json failed: ", err );
            return [];
        }
    }

    function githubCredit( credit : Credit ) : Contributor | undefined
    {
        if( !credit.url )
        {
            return undefined;
        }

        let url : URL;

        try
        {
            url = new URL( credit.url );
        }
        catch
        {
            return undefined;
        }

        if( url.hostname.toLowerCase() !== "github.com" )
        {
            return undefined;
        }

        const login : string | undefined = url.pathname
            .split( "/" )
            .filter( ( part : string ) => part.length > 0 )[ 0 ];

        if( !login )
        {
            return undefined;
        }

        return {
            login,
            avatar_url : `https://github.com/${login}.png?size=160`,
            html_url : `https://github.com/${login}`,
            contributions : 0,
            is_credit : true
        };
    }

    async function render( container : HTMLElement, contributors : ReadonlyMap<string, Contributor> ) : Promise<void>
    {
        container.innerHTML = "";

        const credits : Credit[] = await loadCredits();
        const profiles : HTMLDivElement = document.createElement( "div" );
        profiles.className = "contributor-profiles";
        const additionalCredits : HTMLDivElement = document.createElement( "div" );
        additionalCredits.className = "contributor-credits";
        container.appendChild( profiles );
        container.appendChild( additionalCredits );

        const mergedContributors : Map<string, Contributor> = new Map( contributors );

        for( const credit of credits )
        {
            const contributor : Contributor | undefined = githubCredit( credit );

            if( contributor && !mergedContributors.has( contributor.login.toLowerCase() ) )
            {
                mergedContributors.set( contributor.login.toLowerCase(), contributor );
            }
        }

        const ordered : Contributor[] =
            Array.from( mergedContributors.values() );

        ordered.sort( ( a : Contributor, b : Contributor ) : number =>
        {
            if( a.is_credit !== b.is_credit )
            {
                return a.is_credit ? 1 : -1;
            }

            return b.contributions - a.contributions;
        } );

        for( const user of ordered )
        {
            const el : HTMLAnchorElement = document.createElement( "a" );

            el.href = user.html_url;
            el.target = "_blank";
            el.className = "contributor";

            el.innerHTML = `
                <img src="${user.avatar_url}" />
                <div>${user.login}</div>
                <div>${user.is_credit ? "" : `${user.contributions} contributions`}</div>
            `;
            profiles.appendChild( el );
        }

        for( const credit of credits )
        {
            if( githubCredit( credit ) )
            {
                continue;
            }

            const element : HTMLLIElement = document.createElement( "li" );
            element.className = "changelog-header";
            element.innerText = credit.name;

            if( credit.url )
            {
                const url : HTMLAnchorElement = document.createElement( "a" );
                url.href = credit.url;
                url.target = "_blank";
                url.rel = "noopener noreferrer";
                url.appendChild( element );
                additionalCredits.appendChild( url );
            }
            else
            {
                additionalCredits.appendChild( element );
            }
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
            contributions : Number( ( user as any ).contributions ),
            is_credit : false
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
