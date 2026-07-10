document.addEventListener( "DOMContentLoaded", () =>
{
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

function initSlider()
{
    const images =
    [
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/aa_bts_rc.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/a_page_logo",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_adminwing.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_brij.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_cafe.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_chem.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_class.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_doctors.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_dormsa.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_dormsb.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_firing.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_gadmin.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_gate.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_keycard.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lab.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_legal.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lobby.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lockers.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_maintpost.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_overpass.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_post.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sectorh.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sewrs.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sniper.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_toilet.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_tram1.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_vents.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_warej.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_wh1.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_wh2.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/render34.png",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot1",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot10",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot11",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot12",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot13",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot14",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot15",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot16",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot17",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot2",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot3",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot4",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot5",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot6",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot7",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot8",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot9",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Update1.jpg",
        "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Update2.jpg"
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
    document.getElementById( "schema-search" ).addEventListener( "input", (e) =>
    {
        const value = e.target.value.toLowerCase();

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

        if( currentPath )
            property.parent = currentPath;

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

    html += `</div><br>`;

    html += `<table class="schema-table">`;

    let type = prop.type;

    switch( type )
    {
        case "integer": type = `<a class="schema-property-integer" href="https://json-schema.org/understanding-json-schema/reference/numeric#integer" target="_blank">${prop.type}</a>`; break;
        case "number": type = `<a class="schema-property-number" href="https://json-schema.org/understanding-json-schema/reference/numeric#number" target="_blank">${prop.type}</a>`; break;
        case "boolean": type = `<a class="schema-property-boolean" href="https://json-schema.org/understanding-json-schema/reference/boolean" target="_blank">${prop.type}</a>`; break;
        case "object": type = `<a class="schema-property-object" href="https://json-schema.org/understanding-json-schema/reference/object" target="_blank">${prop.type}</a>`; break;
        case "string": type = `<a class="schema-property-string" href="https://json-schema.org/understanding-json-schema/reference/string" target="_blank">${prop.type}</a>`; break;
        case "array": type = `<a class="schema-property-integer" href="https://json-schema.org/understanding-json-schema/reference/array" target="_blank">${prop.type}</a>`; break;
    }

    AddRow( "Type", type );
    AddRow( "Default", JSON.stringify( prop.default ) );
    AddRow( "Minimum", prop.minimum );
    AddRow( "Maximum", prop.maximum );
    AddRow( "Min Items", prop.minItems );
    AddRow( "Max Items", prop.maxItems );
    AddRow( "Enum", prop.enum?.join( ", " ) );
    AddRow( "Path", path );

    if( prop.parent )
    {
        AddRow( "Parent", `<button class="copy-btn" onclick="ShowProperty('${prop.parent}')">${prop.parent}</button>` );
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
                        ${value}
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
