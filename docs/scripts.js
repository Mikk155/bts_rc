const sounds = {
    hover: new Audio( "buttonrollover.wav" ),
    click: new Audio( "buttonclick.wav" ),
    release: new Audio( "buttonclickrelease.wav" )
};

function playSound( sound )
{
    sound.currentTime = 0;
    sound.play().catch( () => {} );
}

document.addEventListener( "DOMContentLoaded", () =>
{
    initUISounds();
    initSlider();
    loadChangelog();
    loadSchemaDocs();
} );

function initUISounds()
{
    const elements = document.querySelectorAll( "button, a[href]" );

    elements.forEach( el =>
    {
        el.addEventListener( "mouseenter", () =>
        {
            playSound( sounds.hover );
        } );

        el.addEventListener( "mousedown", () =>
        {
            playSound( sounds.click );
        } );

        el.addEventListener( "mouseleave", () =>
        {
            playSound( sounds.release );
        } );

/*
        el.addEventListener( "mouseleave", () =>
        {
            playSound( sounds.hover );
        } );
*/
    } );
}

function initSlider()
{
    const images =
    [
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/aa_bts_rc.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/a_page_logo",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_adminwing.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_brij.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_cafe.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_chem.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_class.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_doctors.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_dormsa.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_dormsb.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_firing.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_gadmin.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_gate.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_keycard.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lab.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_legal.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lobby.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lockers.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_maintpost.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_overpass.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_post.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sectorh.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sewrs.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sniper.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_toilet.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_tram1.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_vents.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_warej.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_wh1.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_wh2.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/render34.png",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot1",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot10",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot11",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot12",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot13",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot14",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot15",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot16",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot17",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot2",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot3",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot4",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot5",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot6",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot7",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot8",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot9",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Update1.jpg",
        "http://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Update2.jpg"
    ];

    let index = 0;

    const slides = document.querySelectorAll( ".bg-slide" );

    if( slides.length < 2 )
    {
        console.warn( "Slider necesita al menos 2 .bg-slide" );
        return;
    }

    slides[ 0 ].style.backgroundImage = `url(${ images[ 0 ] })`;
    slides[ 1 ].style.backgroundImage = `url(${ images[ 1 ] })`;

    function nextSlide()
    {
        const current = index % 2;
        const next = ( index + 1 ) % 2;

        const image = images[ ( index + 1 ) % images.length ];

        slides[ next ].style.backgroundImage = `url(${ image })`;

        slides[ next ].classList.add( "active" );
        slides[ current ].classList.remove( "active" );

        index++;
    }

    setInterval( nextSlide, 10000 ); // 10 seconds
}

function playMap()
{
    window.open(
        "https://scmapdb.wikidot.com/map:blackmesa-training-simulation:resonance-cascade",
        "_blank"
    );
}

async function loadChangelog()
{
    const res = await fetch( "./changelog.md" );
    const markdown = await res.text();

    document.getElementById( "changelog" ).innerHTML = parseMarkdown( markdown );

    attachToggleEvents();
}

function parseMarkdown( md )
{
    const lines = md.split( "\n" );
    let html = "";

    let currentContent = "";
    let currentTitle = "";

    function flushBlock()
    {
        if( !currentTitle )
            return;

        html += `
        <div class="changelog-item">
            <div class="changelog-header">${currentTitle}</div>
            <div class="changelog-content">
                ${currentContent}
            </div>
        </div>
        `;

        currentContent = "";
    }

    for( let line of lines )
    {

        if( line.startsWith( "# " ) )
        {
            flushBlock();
            currentTitle = line.substring(2);
            continue;
        }

        if( line.startsWith( "- " ) )
        {
            currentContent += `<li>${inlineParse( line.substring(2) )}</li>`;
            continue;
        }

        if( line.trim() !== "" )
        {
            currentContent += `<p>${inlineParse( line )}</p>`;
        }
    }

    flushBlock();

    return html;
}

function inlineParse( text )
{
    text = text.replace( /\*\*(.*?)\*\*/g, "<b>$1</b>" );
    text = text.replace( /`(.*?)`/g, "<code>$1</code>" );
    return text;
}

function attachToggleEvents()
{
    document.querySelectorAll( ".changelog-header" ).forEach( header => {
        header.addEventListener( "click", () => {
            const content = header.nextElementSibling;
            content.classList.toggle( "open" );
        } );
    } );
}

function copyCode( button )
{
    const code = button.closest( ".terminal" ).querySelector( "code" ).innerText;

    navigator.clipboard.writeText( code ).then( () => {
        button.innerText = "✅ Copied";
        setTimeout(() => { button.innerText = "Copy"; }, 1500 );
    } );
}

async function loadSchemaDocs()
{
    const res = await fetch( "configuration.html" );
    const html = await res.text();

    const container = document.getElementById( "schema-container" );
    container.innerHTML = html;

    setupInteractions();
}

function setupInteractions()
{
/*
    document.querySelectorAll( ".schema-row" ).forEach(row =>
    {
        row.addEventListener( "mouseenter", e =>
        {
            const desc = row.dataset.description;

            if( !desc )
                return;

            const tooltip = document.createElement( "div" );
            tooltip.className = "tooltip";
            tooltip.innerText = desc;

            document.body.appendChild( tooltip );

            row._tooltip = tooltip;
        } );

        row.addEventListener( "mouseleave", () =>
        {
            if( row._tooltip )
            {
                row._tooltip.remove();
            }
        } );
    } );
*/

    document.querySelectorAll( ".prop-name" ).forEach( el =>
    {
        el.addEventListener( "click", () =>
        {
            navigator.clipboard.writeText( el.dataset.copy );
        } );
    } );
}
