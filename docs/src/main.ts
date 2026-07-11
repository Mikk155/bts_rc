import { initUISounds } from "./sounds.js";
import { initChangelog } from "./changelog.js";
import { initSlider } from "./background.js";

// HTML Methods
import { copyCode } from "./copyCode.js";
( window as any ).copyCode = copyCode;

document.addEventListener( "DOMContentLoaded", () =>
{
    // Hover sounds
    initSlider();
    initUISounds();
    initChangelog();
} );
