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
    LoadLanguageCodeBlocks();
} );

async function LoadLanguageCodeBlocks()
{
    const link = document.createElement( "link" );
    link.rel = "stylesheet";
    link.href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css";
    document.head.appendChild(link);

    const script = document.createElement( "script" );
    script.src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js";

    script.onload = () =>
    {
        hljs.highlightAll();
    };

    document.head.appendChild( script );
}

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

function downloadSchema()
{
    fetch( 'schema.json' )
    .then( response => {
        if( !response.ok )
            throw new Error( 'Failed to download schema.' );
        return response.blob();
    } )
    .then( blob => {
        const urlBlob = window.URL.createObjectURL( blob );
        const a = document.createElement( 'a' );
        a.style.display = 'none';
        a.href = urlBlob;
        a.download = 'schema.json'; 
        document.body.appendChild( a );
        a.click();
        window.URL.revokeObjectURL( urlBlob );
        document.body.removeChild( a );
    } )
    .catch( error => console.error( 'Error:', error ) );
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

let gpRootSchema = null;

const gpPropertyIndex = {};

async function loadSchemaDocs()
{
    document.getElementById( "schema-search" ).addEventListener( "input", () =>
    {
        const value = this.value.toLowerCase();

        const nodes = document.querySelectorAll( ".schema-tree-node" );

        for( const node of nodes )
        {
            const visible = node.textContent.toLowerCase().includes( value );
            node.style.display = visible ? "" : "none";
        }
    } );

    const response = await fetch( "./schema.json" );

    gpRootSchema = await response.json();

    BuildIndex();
    BuildTree();
}

function DeepClone( obj )
{
    return structuredClone( obj );
}

function ResolveRef( ref )
{
    if( !ref.startsWith( "#/" ) )
        return null;

    const parts = ref.substring( 2 ).split( "/" );

    let current = gpRootSchema;

    for( const part of parts )
    {
        current = current[ part ];
    }

    return current;
}

function MergeSchemas( base, extra )
{
    const result = DeepClone( base );

    for( const key in extra )
    {
        if( key === "properties" )
        {
            result.properties ??= {};

            for( const propName in extra.properties )
            {
                result.properties[ propName ] = extra.properties[ propName ];
            }
        }
        else if( key === "required" )
        {
            result.required = [
                ...( result.required || [] ),
                ...( extra.required || [] )
            ];
        }
        else if( key === "allOf" )
        {
            continue;
        }
        else
        {
            result[ key ] = extra[ key ];
        }
    }

    return result;
}

function ResolveSchema( schema, inheritedFrom = null )
{
    let resolved = DeepClone( schema );

    resolved.__inheritedFrom = inheritedFrom;

    if( resolved.allOf )
    {
        for( const entry of resolved.allOf )
        {
            if( entry.$ref )
            {
                const refSchema = ResolveRef( entry.$ref );
                const refName = entry.$ref.split( "/" ).pop();
                const resolvedRef = ResolveSchema( refSchema, refName );
                resolved = MergeSchemas( resolvedRef, resolved );
            }
        }
    }

    delete resolved.allOf;

    return resolved;
}

function BuildIndex()
{
    const root = ResolveSchema( gpRootSchema );
    TraverseSchema( root, "" );
}

function TraverseSchema( schema, currentPath )
{
    if( !schema.properties )
        return;

    for( const key in schema.properties )
    {
        let property = schema.properties[ key ];

        property = ResolveSchema( property );

        const path = currentPath ? `${currentPath}.${key}` : key;

        gpPropertyIndex[ path ] = property;

        if( property.type === "object" )
        {
            TraverseSchema( property, path );
        }

        if( property.additionalProperties )
        {
            const dynamicPath = `${path}.<dynamic_key>`;

            gpPropertyIndex[ dynamicPath ] =
            {
                ...property.additionalProperties,
                __dynamic: true,
                __parent: path
            };
        }
    }
}

function BuildTree()
{
    const tree = document.getElementById( "schema-tree" );

    tree.innerHTML = "";

    const paths = Object.keys( gpPropertyIndex ).sort();

    for( const path of paths )
    {
        const prop = gpPropertyIndex[ path ];

        const div = document.createElement( "div" );

        div.className = `schema-tree-node schema-property-${prop.type}`;

        div.textContent = path;

        div.onclick = () =>
        {
            ShowProperty( path );
        };

        tree.appendChild( div );
    }
}

function ShowProperty( path )
{
    const prop = gpPropertyIndex[ path ];

    const content = document.getElementById( "schema-content" );

    let html = `<h1 class="schema-h1">${ prop.title ? prop.title : path }</h1>`;

    html += `<div>`;

    html += Badge( prop.type || "unknown" );

    if( prop.__dynamic )
    {
        html += Badge( "dynamic", "schema-dynamic" );
    }

    if( prop.__inheritedFrom )
    {
        html += Badge( `inherits ${prop.__inheritedFrom}`, "schema-inherited" );
    }

    html += `</div><br>`;

    html += `<table class="schema-table">`;

    AddRow( "Type", prop.type );
    AddRow( "Default", JSON.stringify( prop.default ) );
    AddRow( "Minimum", prop.minimum );
    AddRow( "Maximum", prop.maximum );
    AddRow( "Min Items", prop.minItems );
    AddRow( "Max Items", prop.maxItems );
    AddRow( "Pattern", prop.pattern );
    AddRow( "Enum", prop.enum?.join( ", " ) );
    AddRow( "Path", path );
    AddRow( "Unevaluated Properties", prop.unevaluatedProperties );

    if( prop.additionalProperties )
    {
        AddRow( "Dynamic Properties", JSON.stringify( prop.additionalProperties, null, 4 ) );
    }

    if( prop.properties )
    {
        AddRow( "Children", Object.keys( prop.properties ).join( ", " ) );
    }

    if( prop.items )
    {
        AddRow( "Array Item Type", prop.items.type );
    }

    let description = "";

    if( prop.description )
        description = `<br><h1 class="schema-h1">Description</h1>${prop.description}<br><br>`;

    html += `</table class="schema-table"><br>${description}<h2>Raw Schema</h2><pre class="terminal-header"><code class="language-json">${EscapeHtml( JSON.stringify( prop, null, 4 ) )}</code></pre>`;

    content.innerHTML = html;

    function AddRow( name, value )
    {
        if( value === undefined || value === null )
            return;

        html += `
            <tr>
                <td class="schema-td">${name}</td>
                <td class="schema-td">
                    <code>
                        ${EscapeHtml( String( value ) )}
                    </code>
                </td>
            </tr>
        `;
    }

    hljs.highlightAll();
}

function Badge( text, className = "" )
{
    return `
        <span class="schema-badge ${className}">
            ${text}
        </span>
    `;
}

function EscapeHtml( text )
{
    return text
        .replaceAll( "&", "&amp;" )
        .replaceAll( "<", "&lt;" )
        .replaceAll( ">", "&gt;" );
}
