type UISound = HTMLAudioElement;

interface UISounds
{
    hover: UISound;
    click: UISound;
    release: UISound;
}

const sounds: UISounds =
{
    hover: new Audio( "buttonrollover.wav" ),
    click: new Audio( "buttonclick.wav" ),
    release: new Audio( "buttonclickrelease.wav" )
};

function playSound( sound: UISound ): void
{
    sound.currentTime = 0;
    sound.play().catch( () => { } );
}

export function initUISounds(): void
{
    const elements = document.querySelectorAll<HTMLElement>( "button, a[href]" );

    elements.forEach( el => {
        el.addEventListener( "mouseenter", () => {
            playSound( sounds.hover );
        } );

        el.addEventListener( "mousedown", () => {
            playSound( sounds.click );
        } );

        el.addEventListener( "mouseleave", () => {
            playSound( sounds.release );
        } );
    } );
}
