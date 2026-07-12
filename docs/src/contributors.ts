interface Contributor 
{
    login: string;
    avatar_url: string;
    html_url: string;
    contributions: number;
}

export async function fetchContributors(): Promise<void>
{
    function render( container: HTMLElement, contributors: Map<string, Contributor> )
    {
        container.innerHTML = "";

        let ordered: Array<Contributor> = Array.from( contributors.values() );
        ordered.sort( ( a: Contributor, b: Contributor ) => b.contributions - a.contributions );

        ordered.forEach( ( user: Contributor ) =>
        {
            const el: HTMLAnchorElement = document.createElement( "a" );

            el.href = user.html_url;
            el.target = "_blank";
            el.className = "contributor";

            el.innerHTML = `
                <img src="${user.avatar_url}" />
                <div>${user.login}</div>
                <div>${user.contributions} contributions</div>
            `;

            container.appendChild( el );
        } );
    }

    function loadFromCache( forceLoad: boolean = false ): boolean
    {
        const cached = localStorage.getItem( "contributors_cache" );

        if( !cached )
            return false;

        const parsed = JSON.parse( cached );

        if( !parsed )
            return false;

        if( forceLoad || Date.now() - parsed.timestamp < ( 1000 * 60 * 5 ) )
        {
            render( document.getElementById( "contributor_list" )!, new Map( parsed.data ) );
            return true;
        }
        return false;
    }

    if( loadFromCache() )
        return;

    const contributors = new Map<string, Contributor>();

    const res = await fetch( `https://api.github.com/repos/Mikk155/bts_rc/contributors` );

    if( !res.ok )
    {
        console.error( "HTTP Error:", res.status );
        loadFromCache(true);
        return;
    }

    const data = await res.json();

    if( !Array.isArray( data ) )
    {
        console.error( "Invalid response: ", data );
        loadFromCache(true);
        return;
    }

    for( const user of data )
    {
        contributors.set( user.login.toLowerCase(), user );
    }

    localStorage.setItem( "contributors_cache", JSON.stringify( { timestamp: Date.now(), data: Array.from( contributors.entries() ) } ));

    render( document.getElementById( "contributor_list" )!, contributors );
}
