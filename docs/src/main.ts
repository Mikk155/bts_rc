import { initUISounds } from "./sounds.js";
import { initChangelog } from "./changelog.js";

document.addEventListener( "DOMContentLoaded", () =>
{
    // Hover sounds
    initUISounds();
    initChangelog();
} );
