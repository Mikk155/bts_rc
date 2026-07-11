import { initUISounds } from "./sounds.js";
import { initChangelog } from "./changelog.js";

// HTML Methods
import { copyCode } from "./copyCode.js";
( window as any ).copyCode = copyCode;

document.addEventListener( "DOMContentLoaded", () =>
{
    // Hover sounds
    initUISounds();
    initChangelog();
} );
