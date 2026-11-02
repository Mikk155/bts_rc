const navigationLinks : NodeListOf<HTMLAnchorElement> =
    document.querySelectorAll( ".site-nav a[href^='#']" );

const navigationSections : HTMLElement[] = Array.from( navigationLinks )
    .map( ( link : HTMLAnchorElement ) =>
    {
        const target = document.querySelector<HTMLElement>( link.hash );
        return target;
    } )
    .filter( ( target : HTMLElement | null ) : target is HTMLElement => target !== null );

if( navigationLinks.length > 0 && navigationSections.length > 0 )
{
    const updateActiveLink = () : void =>
    {
        const offset = window.scrollY + 140;
        let activeSection : HTMLElement | undefined;

        for( const section of navigationSections )
        {
            if( section.offsetTop <= offset )
            {
                activeSection = section;
            }
        }

        navigationLinks.forEach( ( link : HTMLAnchorElement ) =>
        {
            link.classList.toggle(
                "active",
                activeSection?.id === link.hash.slice( 1 )
            );
        } );
    };

    window.addEventListener( "scroll", updateActiveLink, { passive: true } );
    window.addEventListener( "hashchange", updateActiveLink );
    updateActiveLink();
}
