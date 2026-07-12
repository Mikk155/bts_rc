// Copy to clipboard the nearest .terminal class
export function copyCode(button) {
    var _a;
    const container = button.closest(".terminal");
    const codeElement = container === null || container === void 0 ? void 0 : container.querySelector("code");
    const code = (_a = codeElement === null || codeElement === void 0 ? void 0 : codeElement.textContent) !== null && _a !== void 0 ? _a : undefined;
    if (!code)
        return;
    navigator.clipboard.writeText(code).then(() => {
        const originalText = button.innerText;
        button.innerText = "✅ Copied";
        setTimeout(() => { button.innerText = originalText; }, 1500);
    }).catch(() => {
        console.warn("Clipboard write failed");
    });
}
