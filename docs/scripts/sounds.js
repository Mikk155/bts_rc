const sounds = {
    hover: new Audio("./assets/buttonrollover.wav"),
    click: new Audio("./assets/buttonclick.wav"),
    release: new Audio("./assets/buttonclickrelease.wav")
};
let audioUnlocked = false;
function unlockAudio() {
    if (audioUnlocked)
        return;
    Object.values(sounds).forEach(sound => {
        sound.volume = 0;
        sound.play().catch(() => { });
        sound.pause();
        sound.currentTime = 0;
        sound.volume = 1;
    });
    audioUnlocked = true;
}
function playSound(base) {
    const sound = base.cloneNode();
    sound.play().catch(() => { });
}
export async function initUISounds() {
    window.addEventListener("pointerdown", unlockAudio, { once: true });
    document.addEventListener("mouseover", (e) => {
        const target = e.target.closest("button, a[href], .changelog-header");
        if (target)
            playSound(sounds.hover);
    });
    document.addEventListener("mousedown", (e) => {
        const target = e.target.closest("button, a[href], .changelog-header");
        if (target)
            playSound(sounds.click);
    });
    document.addEventListener("mouseup", (e) => {
        const target = e.target.closest("button, a[href], .changelog-header");
        if (target)
            playSound(sounds.release);
    });
}
