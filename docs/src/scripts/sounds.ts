type UISound = HTMLAudioElement;

interface UISounds
{
    hover: UISound;
    click: UISound;
    release: UISound;
}

const sounds: UISounds =
{
    hover: new Audio( "./assets/buttonrollover.wav" ),
    click: new Audio( "./assets/buttonclick.wav" ),
    release: new Audio( "./assets/buttonclickrelease.wav" )
};

function playSound( sound: UISound ): void
{
    sound.currentTime = 0;
    sound.play().catch( () => { } );
}

export async function initUISounds(): Promise<void>
{
    function addPlaySounds( element: HTMLElement ): void
    {
        element.addEventListener( "mouseenter", () => { playSound( sounds.hover ) } );
        element.addEventListener( "mousedown", () => { playSound( sounds.click ) } );
        element.addEventListener( "mouseleave", () => { playSound( sounds.release ) } );
    }

    document.querySelectorAll<HTMLElement>( "button" ).forEach( addPlaySounds );
    document.querySelectorAll<HTMLElement>( "a[href]" ).forEach( addPlaySounds );
    document.querySelectorAll<HTMLElement>( ".changelog-header" ).forEach( addPlaySounds );
}
