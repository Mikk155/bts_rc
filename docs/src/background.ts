// Initialize background image slider
export function initSlider() : void
{
    // Images taken up from scmapdb
    const images : string[] =
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

    let index : number = 0;

    const slides = document.querySelectorAll<HTMLElement>( ".bg-slide" );

    if( !slides || slides.length < 2 )
        return;

    slides[0]!.style.backgroundImage = `url(${ images[0] })`;
    slides[1]!.style.backgroundImage = `url(${ images[1] })`;

    function nextSlide() : void
    {
        const current : number = index % 2;
        const next : number = ( index + 1 ) % 2;

        const image : string = images[ ( index + 1 ) % images.length ] ?? "";

        const nextSlide = slides[next];

        if( nextSlide )
        {
            nextSlide.style.backgroundImage = `url(${ image })`;
            nextSlide.classList.add( "active" );
            slides[ current ]!.classList.remove( "active" );
        }

        index++;
    }

    setInterval( nextSlide, 10000 );
}
