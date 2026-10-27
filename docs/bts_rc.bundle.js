//#region \0rolldown/runtime.js
var e = Object.create, t = Object.defineProperty, n = Object.getOwnPropertyDescriptor, r = Object.getOwnPropertyNames, i = Object.getPrototypeOf, a = Object.prototype.hasOwnProperty, o = (e, t, n) => () => {
	if (n) throw n[0];
	try {
		return e && (t = e(e = 0)), t;
	} catch (e) {
		throw n = [e], e;
	}
}, s = (e, t) => () => (t || (e((t = { exports: {} }).exports, t), e = null), t.exports), c = (e, n) => {
	let r = {};
	for (var i in e) t(r, i, {
		get: e[i],
		enumerable: !0
	});
	return n || t(r, Symbol.toStringTag, { value: "Module" }), r;
}, l = (e, i, o, s) => {
	if (i && typeof i == "object" || typeof i == "function") for (var c = r(i), l = 0, u = c.length, d; l < u; l++) d = c[l], !a.call(e, d) && d !== o && t(e, d, {
		get: ((e) => i[e]).bind(null, d),
		enumerable: !(s = n(i, d)) || s.enumerable
	});
	return e;
}, u = (n, r, a) => (a = n == null ? {} : e(i(n)), l(r || !n || !n.__esModule ? t(a, "default", {
	value: n,
	enumerable: !0
}) : a, n)), d = (e) => a.call(e, "module.exports") ? e["module.exports"] : l(t({}, "__esModule", { value: !0 }), e);
//#endregion
//#region src/scripts/copyCode.ts
function f(e) {
	let t = e.closest(".terminal");
	if (!t) return;
	let n = t.querySelector("code");
	if (!(n instanceof HTMLElement)) return;
	let r = n.textContent ?? "";
	r.trim() !== "" && navigator.clipboard.writeText(r).then(() => {
		let t = e.innerText;
		e.innerText = "✅ Copied", window.setTimeout(() => {
			e.innerText = t;
		}, 1500);
	}).catch(() => {
		console.warn("Clipboard write failed");
	});
}
//#endregion
//#region src/scripts/sounds.ts
var p = {
	hover: new Audio("./assets/buttonrollover.wav"),
	click: new Audio("./assets/buttonclick.wav"),
	release: new Audio("./assets/buttonclickrelease.wav")
}, m = !1;
function h() {
	m ||= (Object.values(p).forEach((e) => {
		e.volume = 0, e.play().catch(() => {}), e.pause(), e.currentTime = 0, e.volume = 1;
	}), !0);
}
function g(e) {
	e.cloneNode().play().catch(() => {});
}
async function _() {
	window.addEventListener("pointerdown", h, { once: !0 }), document.addEventListener("mouseover", (e) => {
		e.target.closest("button, a[href], .changelog-header") && g(p.hover);
	}), document.addEventListener("mousedown", (e) => {
		e.target.closest("button, a[href], .changelog-header") && g(p.click);
	}), document.addEventListener("mouseup", (e) => {
		e.target.closest("button, a[href], .changelog-header") && g(p.release);
	});
}
//#endregion
//#region src/scripts/changelog.ts
async function v() {
	let e = document.getElementById("changelog");
	if (!e) {
		console.warn("Changelog container not found");
		return;
	}
	let t = e, n;
	try {
		n = $ ? await fetch("/__changelog.md") : await fetch("https://raw.githubusercontent.com/Mikk155/bts_rc/main/CHANGELOG.md");
	} catch (t) {
		console.error("Fetch failed:", t), e.innerHTML = "Failed to fetch changelog";
		return;
	}
	if (!n.ok) {
		console.error(`Could not fetch changelog (${n.status}).`), e.textContent = "Failed to fetch changelog";
		return;
	}
	e.innerHTML = "";
	let r = (await n.text()).replace(/\r/g, "").replace(/\*\*(.*?)\*\*/g, "<b>$1</b>").replace(/``(.*?)``/g, "<code class=\"terminal\">$1</code>").replace(/`(.*?)`/g, "<code>$1</code>").split("\n");
	function i() {
		let e = window.location.hash.slice(1), n = document.getElementById(e);
		if (!n || !t.contains(n)) return;
		let r = n.querySelector(".changelog-header"), i = n.querySelector(".changelog-content");
		!r || !i || (i.classList.add("open"), r.setAttribute("aria-expanded", "true"), n.scrollIntoView({
			behavior: "smooth",
			block: "start"
		}));
	}
	function a(e) {
		let t = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(e);
		if (!t) return;
		let n = Number(t[1]), r = Number(t[2]), i = Number(t[3]), a = new Date(i, r - 1, n);
		if (!(a.getFullYear() !== i || a.getMonth() !== r - 1 || a.getDate() !== n)) return `changelog_${i}-${String(r).padStart(2, "0")}-${String(n).padStart(2, "0")}`;
	}
	function o(e, t, n) {
		if (e === "") return;
		let r = document.createElement("div");
		r.className = "changelog-item";
		let i = a(e), o = i ?? `changelog_section_${n.querySelectorAll(".changelog-item").length + 1}`;
		i && (r.id = i);
		let s = document.createElement("button");
		s.type = "button", s.className = "changelog-header", s.innerText = e, s.setAttribute("aria-expanded", "false"), s.setAttribute("aria-controls", `${o}-content`);
		let c = document.createElement("div");
		c.id = `${o}-content`, c.className = "changelog-content", s.addEventListener("click", () => {
			let e = !c.classList.contains("open");
			c.classList.toggle("open", e), s.setAttribute("aria-expanded", String(e)), i && window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}#${i}`);
		});
		let l = null;
		for (let e of t) {
			if (e instanceof HTMLLIElement) {
				l ||= document.createElement("ul"), l.appendChild(e);
				continue;
			} else l && c.appendChild(l), l = null;
			c.appendChild(e);
		}
		l && c.appendChild(l), r.appendChild(s), r.appendChild(c), n.appendChild(r);
	}
	let s = [], c = "";
	{
		let t = document.createElement("a");
		t.href = "https://github.com/Mikk155/bts_rc/blob/main/CHANGELOG.md", t.target = "_blanc", t.innerText = "Full changelog in Markdown.", t.className = "changelog-header", t.style.display = "block", t.style.width = "max-content", t.style.margin = "0 auto", t.style.textAlign = "center", e.appendChild(t), e.appendChild(document.createElement("br"));
	}
	for (let t of r) {
		if (t.startsWith("# ")) {
			o(c, s, e), c = t.substring(2), s = [];
			continue;
		}
		if (t.startsWith("- ")) {
			let e = document.createElement("li");
			e.innerHTML = t.substring(2), s.push(e);
			continue;
		}
		if (t.startsWith("## ")) {
			let e = document.createElement("h2");
			e.innerHTML = t.substring(3), s.push(e);
			continue;
		}
		if (t.startsWith("### ")) {
			let e = document.createElement("h3");
			e.innerHTML = t.substring(4), s.push(e);
			continue;
		}
		if (t.trim() === "") continue;
		let n = document.createElement("p");
		t[0] == " " || t[0] == "	" ? n.innerHTML = `<pre>${t}</pre>` : n.innerHTML = t, s.push(n);
	}
	o(c, s, e), window.addEventListener("hashchange", i), i();
}
//#endregion
//#region src/scripts/background.ts
async function y() {
	let e = /* @__PURE__ */ "https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/aa_bts_rc.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/a_page_logo,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_adminwing.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_brij.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_cafe.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_chem.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_class.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_doctors.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_dormsa.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_dormsb.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_firing.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_gadmin.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_gate.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_keycard.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lab.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_legal.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lobby.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_lockers.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_maintpost.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_overpass.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_post.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sectorh.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sewrs.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_sniper.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_toilet.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_tram1.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_vents.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_warej.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_wh1.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/bts_rc_wh2.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/render34.png,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot1,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot10,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot11,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot12,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot13,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot14,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot15,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot16,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot17,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot2,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot3,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot4,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot5,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot6,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot7,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot8,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Screenshot9,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Update1.jpg,https://scmapdb.wdfiles.com/local--files/map:blackmesa-training-simulation:resonance-cascade/Update2.jpg".split(","), t = 0, n = document.querySelectorAll(".bg-slide");
	if (n.length < 2) return console.warn("Slider requires at least 2 elements"), -1;
	let r = n[0], i = n[1];
	r.style.backgroundImage = `url(${e[0]})`, i.style.backgroundImage = `url(${e[1]})`;
	function a() {
		let r = t % 2, i = (t + 1) % 2, a = (t + 1) % e.length, o = e[a], s = n[i];
		s && (s.style.backgroundImage = `url(${o})`, s.classList.add("active"), n[r].classList.remove("active")), t++;
	}
	return window.setInterval(a, 1e4);
}
//#endregion
//#region src/scripts/contributors.ts
async function b() {
	async function e(e, t) {
		e.innerHTML = "";
		let n = Array.from(t.values());
		n.sort((e, t) => t.contributions - e.contributions);
		let r = 0;
		for (let t of n) {
			let n = document.createElement("a");
			n.href = t.html_url, n.target = "_blank", n.className = "contributor", n.innerHTML = `
                <img src="${t.avatar_url}" />
                <div>${t.login}</div>
                <div>${t.contributions} contributions</div>
            `, r++, e.appendChild(n);
		}
		for (; r % 5 != 0;) e.appendChild(document.createElement("a")), r++;
		try {
			let t = await fetch("assets/credits.json");
			if (t.ok) {
				let n = await t.json();
				if (Array.isArray(n)) for (let t of n) {
					let n = document.createElement("li");
					if (n.className = "changelog-header", Array.isArray(t)) {
						n.innerText = t[0];
						let r = document.createElement("a");
						r.href = t[1], r.target = "_blanc", r.appendChild(n), e.appendChild(r);
					} else n.innerText = t, e.appendChild(n);
				}
			}
		} catch (e) {
			console.warn("credits.json failed: ", e);
		}
	}
	async function t(t = !1) {
		let n = localStorage.getItem("contributors_cache");
		if (!n) return !1;
		let r;
		try {
			r = JSON.parse(n);
		} catch {
			return !1;
		}
		if (!r || !Array.isArray(r.data)) return !1;
		let i = document.getElementById("contributor_list");
		if (!i) return !1;
		let a = Date.now() - r.timestamp < 1e3 * 60 * 5;
		return t || a ? (await e(i, new Map(r.data)), !0) : !1;
	}
	if (await t($)) return;
	let n = /* @__PURE__ */ new Map(), r;
	try {
		r = await fetch("https://api.github.com/repos/Mikk155/bts_rc/contributors");
	} catch (e) {
		console.error("Fetch failed: ", e), await t(!0);
		return;
	}
	if (!r.ok) {
		console.error("HTTP Error:", r.status), await t(!0);
		return;
	}
	let i = await r.json();
	if (!Array.isArray(i)) {
		console.error("Invalid response: ", i), await t(!0);
		return;
	}
	for (let e of i) {
		if (typeof e != "object" || !e || !("login" in e)) continue;
		let t = {
			login: String(e.login),
			avatar_url: String(e.avatar_url),
			html_url: String(e.html_url),
			contributions: Number(e.contributions)
		};
		n.set(t.login.toLowerCase(), t);
	}
	localStorage.setItem("contributors_cache", JSON.stringify({
		timestamp: Date.now(),
		data: Array.from(n.entries())
	}));
	let a = document.getElementById("contributor_list");
	if (!a) {
		console.warn("Container not found");
		return;
	}
	await e(a, n);
}
//#endregion
//#region src/scripts/lastRelease.ts
async function x() {
	let e = "last_release";
	function t(e) {
		let t = document.getElementById("release-notice"), n = document.createElement("div");
		n.className = "release-popup", n.innerHTML = `
            🚀 New version <strong>${e}</strong>
            <button class="close">✖</button>
        `, n.addEventListener("click", (t) => {
			if (t.target.classList.contains("close")) {
				n.remove();
				return;
			}
			window.open(`https://github.com/Mikk155/bts_rc/releases/tag/${e}`, "_blank");
		}), t.appendChild(n);
	}
	function n() {
		let t = localStorage.getItem(e);
		if (!t) return null;
		try {
			return JSON.parse(t);
		} catch {
			return null;
		}
	}
	function r(t) {
		let n = {
			timestamp: Date.now(),
			last_seen: t
		};
		localStorage.setItem(e, JSON.stringify(n));
	}
	let i = n();
	if (i && Date.now() - i.timestamp < 3e5 || $) return;
	let a = null;
	try {
		let e = await fetch("https://api.github.com/repos/Mikk155/bts_rc/tags");
		if (!e.ok) throw Error(`HTTP ${e.status}`);
		let t = await e.json();
		if (!Array.isArray(t) || t.length === 0) throw Error("Invalid response");
		a = t[0].name;
	} catch (e) {
		console.error("Release fetch failed:", e);
		return;
	}
	a && (!i || i.last_seen !== a) && (t(a), r(a));
}
//#endregion
//#region src/scripts/languages.ts
async function S() {
	if (window.hljs) {
		window.hljs.highlightAll();
		return;
	}
	let e = document.createElement("link");
	e.rel = "stylesheet", e.href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css", document.head.appendChild(e);
	let t = document.createElement("script");
	t.src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js", t.onload = () => {
		window.hljs ? window.hljs.highlightAll() : console.warn("hljs not available after load");
	}, t.onerror = () => {
		console.error("Failed to load highlight.js");
	}, document.head.appendChild(t);
}
//#endregion
//#region node_modules/ajv/dist/compile/codegen/code.js
var C = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.regexpCode = e.getEsmExportName = e.getProperty = e.safeStringify = e.stringify = e.strConcat = e.addCodeArg = e.str = e._ = e.nil = e._Code = e.Name = e.IDENTIFIER = e._CodeOrName = void 0;
	var t = class {};
	e._CodeOrName = t, e.IDENTIFIER = /^[a-z$_][a-z$_0-9]*$/i;
	var n = class extends t {
		constructor(t) {
			if (super(), !e.IDENTIFIER.test(t)) throw Error("CodeGen: name must be a valid identifier");
			this.str = t;
		}
		toString() {
			return this.str;
		}
		emptyStr() {
			return !1;
		}
		get names() {
			return { [this.str]: 1 };
		}
	};
	e.Name = n;
	var r = class extends t {
		constructor(e) {
			super(), this._items = typeof e == "string" ? [e] : e;
		}
		toString() {
			return this.str;
		}
		emptyStr() {
			if (this._items.length > 1) return !1;
			let e = this._items[0];
			return e === "" || e === "\"\"";
		}
		get str() {
			return this._str ??= this._items.reduce((e, t) => `${e}${t}`, "");
		}
		get names() {
			return this._names ??= this._items.reduce((e, t) => (t instanceof n && (e[t.str] = (e[t.str] || 0) + 1), e), {});
		}
	};
	e._Code = r, e.nil = new r("");
	function i(e, ...t) {
		let n = [e[0]], i = 0;
		for (; i < t.length;) s(n, t[i]), n.push(e[++i]);
		return new r(n);
	}
	e._ = i;
	var a = new r("+");
	function o(e, ...t) {
		let n = [p(e[0])], i = 0;
		for (; i < t.length;) n.push(a), s(n, t[i]), n.push(a, p(e[++i]));
		return c(n), new r(n);
	}
	e.str = o;
	function s(e, t) {
		t instanceof r ? e.push(...t._items) : t instanceof n ? e.push(t) : e.push(d(t));
	}
	e.addCodeArg = s;
	function c(e) {
		let t = 1;
		for (; t < e.length - 1;) {
			if (e[t] === a) {
				let n = l(e[t - 1], e[t + 1]);
				if (n !== void 0) {
					e.splice(t - 1, 3, n);
					continue;
				}
				e[t++] = "+";
			}
			t++;
		}
	}
	function l(e, t) {
		if (t === "\"\"") return e;
		if (e === "\"\"") return t;
		if (typeof e == "string") return t instanceof n || e[e.length - 1] !== "\"" ? void 0 : typeof t == "string" ? t[0] === "\"" ? e.slice(0, -1) + t.slice(1) : void 0 : `${e.slice(0, -1)}${t}"`;
		if (typeof t == "string" && t[0] === "\"" && !(e instanceof n)) return `"${e}${t.slice(1)}`;
	}
	function u(e, t) {
		return t.emptyStr() ? e : e.emptyStr() ? t : o`${e}${t}`;
	}
	e.strConcat = u;
	function d(e) {
		return typeof e == "number" || typeof e == "boolean" || e === null ? e : p(Array.isArray(e) ? e.join(",") : e);
	}
	function f(e) {
		return new r(p(e));
	}
	e.stringify = f;
	function p(e) {
		return JSON.stringify(e).replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
	}
	e.safeStringify = p;
	function m(t) {
		return typeof t == "string" && e.IDENTIFIER.test(t) ? new r(`.${t}`) : i`[${t}]`;
	}
	e.getProperty = m;
	function h(t) {
		if (typeof t == "string" && e.IDENTIFIER.test(t)) return new r(`${t}`);
		throw Error(`CodeGen: invalid export name: ${t}, use explicit $id name mapping`);
	}
	e.getEsmExportName = h;
	function g(e) {
		return new r(e.toString());
	}
	e.regexpCode = g;
})), w = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.ValueScope = e.ValueScopeName = e.Scope = e.varKinds = e.UsedValueState = void 0;
	var t = C(), n = class extends Error {
		constructor(e) {
			super(`CodeGen: "code" for ${e} not defined`), this.value = e.value;
		}
	}, r;
	(function(e) {
		e[e.Started = 0] = "Started", e[e.Completed = 1] = "Completed";
	})(r || (e.UsedValueState = r = {})), e.varKinds = {
		const: new t.Name("const"),
		let: new t.Name("let"),
		var: new t.Name("var")
	};
	var i = class {
		constructor({ prefixes: e, parent: t } = {}) {
			this._names = {}, this._prefixes = e, this._parent = t;
		}
		toName(e) {
			return e instanceof t.Name ? e : this.name(e);
		}
		name(e) {
			return new t.Name(this._newName(e));
		}
		_newName(e) {
			let t = this._names[e] || this._nameGroup(e);
			return `${e}${t.index++}`;
		}
		_nameGroup(e) {
			if ((this._parent?._prefixes)?.has(e) || this._prefixes && !this._prefixes.has(e)) throw Error(`CodeGen: prefix "${e}" is not allowed in this scope`);
			return this._names[e] = {
				prefix: e,
				index: 0
			};
		}
	};
	e.Scope = i;
	var a = class extends t.Name {
		constructor(e, t) {
			super(t), this.prefix = e;
		}
		setValue(e, { property: n, itemIndex: r }) {
			this.value = e, this.scopePath = (0, t._)`.${new t.Name(n)}[${r}]`;
		}
	};
	e.ValueScopeName = a;
	var o = (0, t._)`\n`;
	e.ValueScope = class extends i {
		constructor(e) {
			super(e), this._values = {}, this._scope = e.scope, this.opts = {
				...e,
				_n: e.lines ? o : t.nil
			};
		}
		get() {
			return this._scope;
		}
		name(e) {
			return new a(e, this._newName(e));
		}
		value(e, t) {
			if (t.ref === void 0) throw Error("CodeGen: ref must be passed in value");
			let n = this.toName(e), { prefix: r } = n, i = t.key ?? t.ref, a = this._values[r];
			if (a) {
				let e = a.get(i);
				if (e) return e;
			} else a = this._values[r] = /* @__PURE__ */ new Map();
			a.set(i, n);
			let o = this._scope[r] || (this._scope[r] = []), s = o.length;
			return o[s] = t.ref, n.setValue(t, {
				property: r,
				itemIndex: s
			}), n;
		}
		getValue(e, t) {
			let n = this._values[e];
			if (n) return n.get(t);
		}
		scopeRefs(e, n = this._values) {
			return this._reduceValues(n, (n) => {
				if (n.scopePath === void 0) throw Error(`CodeGen: name "${n}" has no value`);
				return (0, t._)`${e}${n.scopePath}`;
			});
		}
		scopeCode(e = this._values, t, n) {
			return this._reduceValues(e, (e) => {
				if (e.value === void 0) throw Error(`CodeGen: name "${e}" has no value`);
				return e.value.code;
			}, t, n);
		}
		_reduceValues(i, a, o = {}, s) {
			let c = t.nil;
			for (let l in i) {
				let u = i[l];
				if (!u) continue;
				let d = o[l] = o[l] || /* @__PURE__ */ new Map();
				u.forEach((i) => {
					if (d.has(i)) return;
					d.set(i, r.Started);
					let o = a(i);
					if (o) {
						let n = this.opts.es5 ? e.varKinds.var : e.varKinds.const;
						c = (0, t._)`${c}${n} ${i} = ${o};${this.opts._n}`;
					} else if (o = s?.(i)) c = (0, t._)`${c}${o}${this.opts._n}`;
					else throw new n(i);
					d.set(i, r.Completed);
				});
			}
			return c;
		}
	};
})), T = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.or = e.and = e.not = e.CodeGen = e.operators = e.varKinds = e.ValueScopeName = e.ValueScope = e.Scope = e.Name = e.regexpCode = e.stringify = e.getProperty = e.nil = e.strConcat = e.str = e._ = void 0;
	var t = C(), n = w(), r = C();
	Object.defineProperty(e, "_", {
		enumerable: !0,
		get: function() {
			return r._;
		}
	}), Object.defineProperty(e, "str", {
		enumerable: !0,
		get: function() {
			return r.str;
		}
	}), Object.defineProperty(e, "strConcat", {
		enumerable: !0,
		get: function() {
			return r.strConcat;
		}
	}), Object.defineProperty(e, "nil", {
		enumerable: !0,
		get: function() {
			return r.nil;
		}
	}), Object.defineProperty(e, "getProperty", {
		enumerable: !0,
		get: function() {
			return r.getProperty;
		}
	}), Object.defineProperty(e, "stringify", {
		enumerable: !0,
		get: function() {
			return r.stringify;
		}
	}), Object.defineProperty(e, "regexpCode", {
		enumerable: !0,
		get: function() {
			return r.regexpCode;
		}
	}), Object.defineProperty(e, "Name", {
		enumerable: !0,
		get: function() {
			return r.Name;
		}
	});
	var i = w();
	Object.defineProperty(e, "Scope", {
		enumerable: !0,
		get: function() {
			return i.Scope;
		}
	}), Object.defineProperty(e, "ValueScope", {
		enumerable: !0,
		get: function() {
			return i.ValueScope;
		}
	}), Object.defineProperty(e, "ValueScopeName", {
		enumerable: !0,
		get: function() {
			return i.ValueScopeName;
		}
	}), Object.defineProperty(e, "varKinds", {
		enumerable: !0,
		get: function() {
			return i.varKinds;
		}
	}), e.operators = {
		GT: new t._Code(">"),
		GTE: new t._Code(">="),
		LT: new t._Code("<"),
		LTE: new t._Code("<="),
		EQ: new t._Code("==="),
		NEQ: new t._Code("!=="),
		NOT: new t._Code("!"),
		OR: new t._Code("||"),
		AND: new t._Code("&&"),
		ADD: new t._Code("+")
	};
	var a = class {
		optimizeNodes() {
			return this;
		}
		optimizeNames(e, t) {
			return this;
		}
	}, o = class extends a {
		constructor(e, t, n) {
			super(), this.varKind = e, this.name = t, this.rhs = n;
		}
		render({ es5: e, _n: t }) {
			let r = e ? n.varKinds.var : this.varKind, i = this.rhs === void 0 ? "" : ` = ${this.rhs}`;
			return `${r} ${this.name}${i};` + t;
		}
		optimizeNames(e, t) {
			if (e[this.name.str]) return this.rhs &&= j(this.rhs, e, t), this;
		}
		get names() {
			return this.rhs instanceof t._CodeOrName ? this.rhs.names : {};
		}
	}, s = class extends a {
		constructor(e, t, n) {
			super(), this.lhs = e, this.rhs = t, this.sideEffects = n;
		}
		render({ _n: e }) {
			return `${this.lhs} = ${this.rhs};` + e;
		}
		optimizeNames(e, n) {
			if (!(this.lhs instanceof t.Name && !e[this.lhs.str] && !this.sideEffects)) return this.rhs = j(this.rhs, e, n), this;
		}
		get names() {
			return A(this.lhs instanceof t.Name ? {} : { ...this.lhs.names }, this.rhs);
		}
	}, c = class extends s {
		constructor(e, t, n, r) {
			super(e, n, r), this.op = t;
		}
		render({ _n: e }) {
			return `${this.lhs} ${this.op}= ${this.rhs};` + e;
		}
	}, l = class extends a {
		constructor(e) {
			super(), this.label = e, this.names = {};
		}
		render({ _n: e }) {
			return `${this.label}:` + e;
		}
	}, u = class extends a {
		constructor(e) {
			super(), this.label = e, this.names = {};
		}
		render({ _n: e }) {
			return `break${this.label ? ` ${this.label}` : ""};` + e;
		}
	}, d = class extends a {
		constructor(e) {
			super(), this.error = e;
		}
		render({ _n: e }) {
			return `throw ${this.error};` + e;
		}
		get names() {
			return this.error.names;
		}
	}, f = class extends a {
		constructor(e) {
			super(), this.code = e;
		}
		render({ _n: e }) {
			return `${this.code};` + e;
		}
		optimizeNodes() {
			return `${this.code}` ? this : void 0;
		}
		optimizeNames(e, t) {
			return this.code = j(this.code, e, t), this;
		}
		get names() {
			return this.code instanceof t._CodeOrName ? this.code.names : {};
		}
	}, p = class extends a {
		constructor(e = []) {
			super(), this.nodes = e;
		}
		render(e) {
			return this.nodes.reduce((t, n) => t + n.render(e), "");
		}
		optimizeNodes() {
			let { nodes: e } = this, t = e.length;
			for (; t--;) {
				let n = e[t].optimizeNodes();
				Array.isArray(n) ? e.splice(t, 1, ...n) : n ? e[t] = n : e.splice(t, 1);
			}
			return e.length > 0 ? this : void 0;
		}
		optimizeNames(e, t) {
			let { nodes: n } = this, r = n.length;
			for (; r--;) {
				let i = n[r];
				i.optimizeNames(e, t) || (M(e, i.names), n.splice(r, 1));
			}
			return n.length > 0 ? this : void 0;
		}
		get names() {
			return this.nodes.reduce((e, t) => k(e, t.names), {});
		}
	}, m = class extends p {
		render(e) {
			return "{" + e._n + super.render(e) + "}" + e._n;
		}
	}, h = class extends p {}, g = class extends m {};
	g.kind = "else";
	var _ = class e extends m {
		constructor(e, t) {
			super(t), this.condition = e;
		}
		render(e) {
			let t = `if(${this.condition})` + super.render(e);
			return this.else && (t += "else " + this.else.render(e)), t;
		}
		optimizeNodes() {
			super.optimizeNodes();
			let t = this.condition;
			if (t === !0) return this.nodes;
			let n = this.else;
			if (n) {
				let e = n.optimizeNodes();
				n = this.else = Array.isArray(e) ? new g(e) : e;
			}
			if (n) return t === !1 ? n instanceof e ? n : n.nodes : this.nodes.length ? this : new e(N(t), n instanceof e ? [n] : n.nodes);
			if (!(t === !1 || !this.nodes.length)) return this;
		}
		optimizeNames(e, t) {
			if (this.else = this.else?.optimizeNames(e, t), super.optimizeNames(e, t) || this.else) return this.condition = j(this.condition, e, t), this;
		}
		get names() {
			let e = super.names;
			return A(e, this.condition), this.else && k(e, this.else.names), e;
		}
	};
	_.kind = "if";
	var v = class extends m {};
	v.kind = "for";
	var y = class extends v {
		constructor(e) {
			super(), this.iteration = e;
		}
		render(e) {
			return `for(${this.iteration})` + super.render(e);
		}
		optimizeNames(e, t) {
			if (super.optimizeNames(e, t)) return this.iteration = j(this.iteration, e, t), this;
		}
		get names() {
			return k(super.names, this.iteration.names);
		}
	}, b = class extends v {
		constructor(e, t, n, r) {
			super(), this.varKind = e, this.name = t, this.from = n, this.to = r;
		}
		render(e) {
			let t = e.es5 ? n.varKinds.var : this.varKind, { name: r, from: i, to: a } = this;
			return `for(${t} ${r}=${i}; ${r}<${a}; ${r}++)` + super.render(e);
		}
		get names() {
			return A(A(super.names, this.from), this.to);
		}
	}, x = class extends v {
		constructor(e, t, n, r) {
			super(), this.loop = e, this.varKind = t, this.name = n, this.iterable = r;
		}
		render(e) {
			return `for(${this.varKind} ${this.name} ${this.loop} ${this.iterable})` + super.render(e);
		}
		optimizeNames(e, t) {
			if (super.optimizeNames(e, t)) return this.iterable = j(this.iterable, e, t), this;
		}
		get names() {
			return k(super.names, this.iterable.names);
		}
	}, S = class extends m {
		constructor(e, t, n) {
			super(), this.name = e, this.args = t, this.async = n;
		}
		render(e) {
			return `${this.async ? "async " : ""}function ${this.name}(${this.args})` + super.render(e);
		}
	};
	S.kind = "func";
	var T = class extends p {
		render(e) {
			return "return " + super.render(e);
		}
	};
	T.kind = "return";
	var E = class extends m {
		render(e) {
			let t = "try" + super.render(e);
			return this.catch && (t += this.catch.render(e)), this.finally && (t += this.finally.render(e)), t;
		}
		optimizeNodes() {
			var e, t;
			return super.optimizeNodes(), (e = this.catch) == null || e.optimizeNodes(), (t = this.finally) == null || t.optimizeNodes(), this;
		}
		optimizeNames(e, t) {
			var n, r;
			return super.optimizeNames(e, t), (n = this.catch) == null || n.optimizeNames(e, t), (r = this.finally) == null || r.optimizeNames(e, t), this;
		}
		get names() {
			let e = super.names;
			return this.catch && k(e, this.catch.names), this.finally && k(e, this.finally.names), e;
		}
	}, D = class extends m {
		constructor(e) {
			super(), this.error = e;
		}
		render(e) {
			return `catch(${this.error})` + super.render(e);
		}
	};
	D.kind = "catch";
	var O = class extends m {
		render(e) {
			return "finally" + super.render(e);
		}
	};
	O.kind = "finally", e.CodeGen = class {
		constructor(e, t = {}) {
			this._values = {}, this._blockStarts = [], this._constants = {}, this.opts = {
				...t,
				_n: t.lines ? "\n" : ""
			}, this._extScope = e, this._scope = new n.Scope({ parent: e }), this._nodes = [new h()];
		}
		toString() {
			return this._root.render(this.opts);
		}
		name(e) {
			return this._scope.name(e);
		}
		scopeName(e) {
			return this._extScope.name(e);
		}
		scopeValue(e, t) {
			let n = this._extScope.value(e, t);
			return (this._values[n.prefix] || (this._values[n.prefix] = /* @__PURE__ */ new Set())).add(n), n;
		}
		getScopeValue(e, t) {
			return this._extScope.getValue(e, t);
		}
		scopeRefs(e) {
			return this._extScope.scopeRefs(e, this._values);
		}
		scopeCode() {
			return this._extScope.scopeCode(this._values);
		}
		_def(e, t, n, r) {
			let i = this._scope.toName(t);
			return n !== void 0 && r && (this._constants[i.str] = n), this._leafNode(new o(e, i, n)), i;
		}
		const(e, t, r) {
			return this._def(n.varKinds.const, e, t, r);
		}
		let(e, t, r) {
			return this._def(n.varKinds.let, e, t, r);
		}
		var(e, t, r) {
			return this._def(n.varKinds.var, e, t, r);
		}
		assign(e, t, n) {
			return this._leafNode(new s(e, t, n));
		}
		add(t, n) {
			return this._leafNode(new c(t, e.operators.ADD, n));
		}
		code(e) {
			return typeof e == "function" ? e() : e !== t.nil && this._leafNode(new f(e)), this;
		}
		object(...e) {
			let n = ["{"];
			for (let [r, i] of e) n.length > 1 && n.push(","), n.push(r), (r !== i || this.opts.es5) && (n.push(":"), (0, t.addCodeArg)(n, i));
			return n.push("}"), new t._Code(n);
		}
		if(e, t, n) {
			if (this._blockNode(new _(e)), t && n) this.code(t).else().code(n).endIf();
			else if (t) this.code(t).endIf();
			else if (n) throw Error("CodeGen: \"else\" body without \"then\" body");
			return this;
		}
		elseIf(e) {
			return this._elseNode(new _(e));
		}
		else() {
			return this._elseNode(new g());
		}
		endIf() {
			return this._endBlockNode(_, g);
		}
		_for(e, t) {
			return this._blockNode(e), t && this.code(t).endFor(), this;
		}
		for(e, t) {
			return this._for(new y(e), t);
		}
		forRange(e, t, r, i, a = this.opts.es5 ? n.varKinds.var : n.varKinds.let) {
			let o = this._scope.toName(e);
			return this._for(new b(a, o, t, r), () => i(o));
		}
		forOf(e, r, i, a = n.varKinds.const) {
			let o = this._scope.toName(e);
			if (this.opts.es5) {
				let e = r instanceof t.Name ? r : this.var("_arr", r);
				return this.forRange("_i", 0, (0, t._)`${e}.length`, (n) => {
					this.var(o, (0, t._)`${e}[${n}]`), i(o);
				});
			}
			return this._for(new x("of", a, o, r), () => i(o));
		}
		forIn(e, r, i, a = this.opts.es5 ? n.varKinds.var : n.varKinds.const) {
			if (this.opts.ownProperties) return this.forOf(e, (0, t._)`Object.keys(${r})`, i);
			let o = this._scope.toName(e);
			return this._for(new x("in", a, o, r), () => i(o));
		}
		endFor() {
			return this._endBlockNode(v);
		}
		label(e) {
			return this._leafNode(new l(e));
		}
		break(e) {
			return this._leafNode(new u(e));
		}
		return(e) {
			let t = new T();
			if (this._blockNode(t), this.code(e), t.nodes.length !== 1) throw Error("CodeGen: \"return\" should have one node");
			return this._endBlockNode(T);
		}
		try(e, t, n) {
			if (!t && !n) throw Error("CodeGen: \"try\" without \"catch\" and \"finally\"");
			let r = new E();
			if (this._blockNode(r), this.code(e), t) {
				let e = this.name("e");
				this._currNode = r.catch = new D(e), t(e);
			}
			return n && (this._currNode = r.finally = new O(), this.code(n)), this._endBlockNode(D, O);
		}
		throw(e) {
			return this._leafNode(new d(e));
		}
		block(e, t) {
			return this._blockStarts.push(this._nodes.length), e && this.code(e).endBlock(t), this;
		}
		endBlock(e) {
			let t = this._blockStarts.pop();
			if (t === void 0) throw Error("CodeGen: not in self-balancing block");
			let n = this._nodes.length - t;
			if (n < 0 || e !== void 0 && n !== e) throw Error(`CodeGen: wrong number of nodes: ${n} vs ${e} expected`);
			return this._nodes.length = t, this;
		}
		func(e, n = t.nil, r, i) {
			return this._blockNode(new S(e, n, r)), i && this.code(i).endFunc(), this;
		}
		endFunc() {
			return this._endBlockNode(S);
		}
		optimize(e = 1) {
			for (; e-- > 0;) this._root.optimizeNodes(), this._root.optimizeNames(this._root.names, this._constants);
		}
		_leafNode(e) {
			return this._currNode.nodes.push(e), this;
		}
		_blockNode(e) {
			this._currNode.nodes.push(e), this._nodes.push(e);
		}
		_endBlockNode(e, t) {
			let n = this._currNode;
			if (n instanceof e || t && n instanceof t) return this._nodes.pop(), this;
			throw Error(`CodeGen: not in block "${t ? `${e.kind}/${t.kind}` : e.kind}"`);
		}
		_elseNode(e) {
			let t = this._currNode;
			if (!(t instanceof _)) throw Error("CodeGen: \"else\" without \"if\"");
			return this._currNode = t.else = e, this;
		}
		get _root() {
			return this._nodes[0];
		}
		get _currNode() {
			let e = this._nodes;
			return e[e.length - 1];
		}
		set _currNode(e) {
			let t = this._nodes;
			t[t.length - 1] = e;
		}
	};
	function k(e, t) {
		for (let n in t) e[n] = (e[n] || 0) + (t[n] || 0);
		return e;
	}
	function A(e, n) {
		return n instanceof t._CodeOrName ? k(e, n.names) : e;
	}
	function j(e, n, r) {
		if (e instanceof t.Name) return i(e);
		if (!a(e)) return e;
		return new t._Code(e._items.reduce((e, n) => (n instanceof t.Name && (n = i(n)), n instanceof t._Code ? e.push(...n._items) : e.push(n), e), []));
		function i(e) {
			let t = r[e.str];
			return t === void 0 || n[e.str] !== 1 ? e : (delete n[e.str], t);
		}
		function a(e) {
			return e instanceof t._Code && e._items.some((e) => e instanceof t.Name && n[e.str] === 1 && r[e.str] !== void 0);
		}
	}
	function M(e, t) {
		for (let n in t) e[n] = (e[n] || 0) - (t[n] || 0);
	}
	function N(e) {
		return typeof e == "boolean" || typeof e == "number" || e === null ? !e : (0, t._)`!${z(e)}`;
	}
	e.not = N;
	var P = R(e.operators.AND);
	function F(...e) {
		return e.reduce(P);
	}
	e.and = F;
	var I = R(e.operators.OR);
	function L(...e) {
		return e.reduce(I);
	}
	e.or = L;
	function R(e) {
		return (n, r) => n === t.nil ? r : r === t.nil ? n : (0, t._)`${z(n)} ${e} ${z(r)}`;
	}
	function z(e) {
		return e instanceof t.Name ? e : (0, t._)`(${e})`;
	}
})), E = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.checkStrictMode = e.getErrorPath = e.Type = e.useFunc = e.setEvaluated = e.evaluatedPropsToName = e.mergeEvaluated = e.eachItem = e.unescapeJsonPointer = e.escapeJsonPointer = e.escapeFragment = e.unescapeFragment = e.schemaRefOrVal = e.schemaHasRulesButRef = e.schemaHasRules = e.checkUnknownRules = e.alwaysValidSchema = e.toHash = void 0;
	var t = T(), n = C();
	function r(e) {
		let t = {};
		for (let n of e) t[n] = !0;
		return t;
	}
	e.toHash = r;
	function i(e, t) {
		return typeof t == "boolean" ? t : Object.keys(t).length === 0 ? !0 : (a(e, t), !o(t, e.self.RULES.all));
	}
	e.alwaysValidSchema = i;
	function a(e, t = e.schema) {
		let { opts: n, self: r } = e;
		if (!n.strictSchema || typeof t == "boolean") return;
		let i = r.RULES.keywords;
		for (let n in t) i[n] || x(e, `unknown keyword: "${n}"`);
	}
	e.checkUnknownRules = a;
	function o(e, t) {
		if (typeof e == "boolean") return !e;
		for (let n in e) if (t[n]) return !0;
		return !1;
	}
	e.schemaHasRules = o;
	function s(e, t) {
		if (typeof e == "boolean") return !e;
		for (let n in e) if (n !== "$ref" && t.all[n]) return !0;
		return !1;
	}
	e.schemaHasRulesButRef = s;
	function c({ topSchemaRef: e, schemaPath: n }, r, i, a) {
		if (!a) {
			if (typeof r == "number" || typeof r == "boolean") return r;
			if (typeof r == "string") return (0, t._)`${r}`;
		}
		return (0, t._)`${e}${n}${(0, t.getProperty)(i)}`;
	}
	e.schemaRefOrVal = c;
	function l(e) {
		return f(decodeURIComponent(e));
	}
	e.unescapeFragment = l;
	function u(e) {
		return encodeURIComponent(d(e));
	}
	e.escapeFragment = u;
	function d(e) {
		return typeof e == "number" ? `${e}` : e.replace(/~/g, "~0").replace(/\//g, "~1");
	}
	e.escapeJsonPointer = d;
	function f(e) {
		return e.replace(/~1/g, "/").replace(/~0/g, "~");
	}
	e.unescapeJsonPointer = f;
	function p(e, t) {
		if (Array.isArray(e)) for (let n of e) t(n);
		else t(e);
	}
	e.eachItem = p;
	function m({ mergeNames: e, mergeToName: n, mergeValues: r, resultToName: i }) {
		return (a, o, s, c) => {
			let l = s === void 0 ? o : s instanceof t.Name ? (o instanceof t.Name ? e(a, o, s) : n(a, o, s), s) : o instanceof t.Name ? (n(a, s, o), o) : r(o, s);
			return c === t.Name && !(l instanceof t.Name) ? i(a, l) : l;
		};
	}
	e.mergeEvaluated = {
		props: m({
			mergeNames: (e, n, r) => e.if((0, t._)`${r} !== true && ${n} !== undefined`, () => {
				e.if((0, t._)`${n} === true`, () => e.assign(r, !0), () => e.assign(r, (0, t._)`${r} || {}`).code((0, t._)`Object.assign(${r}, ${n})`));
			}),
			mergeToName: (e, n, r) => e.if((0, t._)`${r} !== true`, () => {
				n === !0 ? e.assign(r, !0) : (e.assign(r, (0, t._)`${r} || {}`), g(e, r, n));
			}),
			mergeValues: (e, t) => e === !0 || {
				...e,
				...t
			},
			resultToName: h
		}),
		items: m({
			mergeNames: (e, n, r) => e.if((0, t._)`${r} !== true && ${n} !== undefined`, () => e.assign(r, (0, t._)`${n} === true ? true : ${r} > ${n} ? ${r} : ${n}`)),
			mergeToName: (e, n, r) => e.if((0, t._)`${r} !== true`, () => e.assign(r, n === !0 || (0, t._)`${r} > ${n} ? ${r} : ${n}`)),
			mergeValues: (e, t) => e === !0 || Math.max(e, t),
			resultToName: (e, t) => e.var("items", t)
		})
	};
	function h(e, n) {
		if (n === !0) return e.var("props", !0);
		let r = e.var("props", (0, t._)`{}`);
		return n !== void 0 && g(e, r, n), r;
	}
	e.evaluatedPropsToName = h;
	function g(e, n, r) {
		Object.keys(r).forEach((r) => e.assign((0, t._)`${n}${(0, t.getProperty)(r)}`, !0));
	}
	e.setEvaluated = g;
	var _ = {};
	function v(e, t) {
		return e.scopeValue("func", {
			ref: t,
			code: _[t.code] || (_[t.code] = new n._Code(t.code))
		});
	}
	e.useFunc = v;
	var y;
	(function(e) {
		e[e.Num = 0] = "Num", e[e.Str = 1] = "Str";
	})(y || (e.Type = y = {}));
	function b(e, n, r) {
		if (e instanceof t.Name) {
			let i = n === y.Num;
			return r ? i ? (0, t._)`"[" + ${e} + "]"` : (0, t._)`"['" + ${e} + "']"` : i ? (0, t._)`"/" + ${e}` : (0, t._)`"/" + ${e}.replace(/~/g, "~0").replace(/\\//g, "~1")`;
		}
		return r ? (0, t.getProperty)(e).toString() : "/" + d(e);
	}
	e.getErrorPath = b;
	function x(e, t, n = e.opts.strictSchema) {
		if (n) {
			if (t = `strict mode: ${t}`, n === !0) throw Error(t);
			e.self.logger.warn(t);
		}
	}
	e.checkStrictMode = x;
})), D = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T();
	e.default = {
		data: new t.Name("data"),
		valCxt: new t.Name("valCxt"),
		instancePath: new t.Name("instancePath"),
		parentData: new t.Name("parentData"),
		parentDataProperty: new t.Name("parentDataProperty"),
		rootData: new t.Name("rootData"),
		dynamicAnchors: new t.Name("dynamicAnchors"),
		vErrors: new t.Name("vErrors"),
		errors: new t.Name("errors"),
		this: new t.Name("this"),
		self: new t.Name("self"),
		scope: new t.Name("scope"),
		json: new t.Name("json"),
		jsonPos: new t.Name("jsonPos"),
		jsonLen: new t.Name("jsonLen"),
		jsonPart: new t.Name("jsonPart")
	};
})), O = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.extendErrors = e.resetErrorsCount = e.reportExtraError = e.reportError = e.keyword$DataError = e.keywordError = void 0;
	var t = T(), n = E(), r = D();
	e.keywordError = { message: ({ keyword: e }) => (0, t.str)`must pass "${e}" keyword validation` }, e.keyword$DataError = { message: ({ keyword: e, schemaType: n }) => n ? (0, t.str)`"${e}" keyword must be ${n} ($data)` : (0, t.str)`"${e}" keyword is invalid ($data)` };
	function i(n, r = e.keywordError, i, a) {
		let { it: o } = n, { gen: s, compositeRule: u, allErrors: f } = o, p = d(n, r, i);
		a ?? (u || f) ? c(s, p) : l(o, (0, t._)`[${p}]`);
	}
	e.reportError = i;
	function a(t, n = e.keywordError, i) {
		let { it: a } = t, { gen: o, compositeRule: s, allErrors: u } = a;
		c(o, d(t, n, i)), s || u || l(a, r.default.vErrors);
	}
	e.reportExtraError = a;
	function o(e, n) {
		e.assign(r.default.errors, n), e.if((0, t._)`${r.default.vErrors} !== null`, () => e.if(n, () => e.assign((0, t._)`${r.default.vErrors}.length`, n), () => e.assign(r.default.vErrors, null)));
	}
	e.resetErrorsCount = o;
	function s({ gen: e, keyword: n, schemaValue: i, data: a, errsCount: o, it: s }) {
		/* istanbul ignore if */
		if (o === void 0) throw Error("ajv implementation error");
		let c = e.name("err");
		e.forRange("i", o, r.default.errors, (o) => {
			e.const(c, (0, t._)`${r.default.vErrors}[${o}]`), e.if((0, t._)`${c}.instancePath === undefined`, () => e.assign((0, t._)`${c}.instancePath`, (0, t.strConcat)(r.default.instancePath, s.errorPath))), e.assign((0, t._)`${c}.schemaPath`, (0, t.str)`${s.errSchemaPath}/${n}`), s.opts.verbose && (e.assign((0, t._)`${c}.schema`, i), e.assign((0, t._)`${c}.data`, a));
		});
	}
	e.extendErrors = s;
	function c(e, n) {
		let i = e.const("err", n);
		e.if((0, t._)`${r.default.vErrors} === null`, () => e.assign(r.default.vErrors, (0, t._)`[${i}]`), (0, t._)`${r.default.vErrors}.push(${i})`), e.code((0, t._)`${r.default.errors}++`);
	}
	function l(e, n) {
		let { gen: r, validateName: i, schemaEnv: a } = e;
		a.$async ? r.throw((0, t._)`new ${e.ValidationError}(${n})`) : (r.assign((0, t._)`${i}.errors`, n), r.return(!1));
	}
	var u = {
		keyword: new t.Name("keyword"),
		schemaPath: new t.Name("schemaPath"),
		params: new t.Name("params"),
		propertyName: new t.Name("propertyName"),
		message: new t.Name("message"),
		schema: new t.Name("schema"),
		parentSchema: new t.Name("parentSchema")
	};
	function d(e, n, r) {
		let { createErrors: i } = e.it;
		return i === !1 ? (0, t._)`{}` : f(e, n, r);
	}
	function f(e, t, n = {}) {
		let { gen: r, it: i } = e, a = [p(i, n), m(e, n)];
		return h(e, t, a), r.object(...a);
	}
	function p({ errorPath: e }, { instancePath: i }) {
		let a = i ? (0, t.str)`${e}${(0, n.getErrorPath)(i, n.Type.Str)}` : e;
		return [r.default.instancePath, (0, t.strConcat)(r.default.instancePath, a)];
	}
	function m({ keyword: e, it: { errSchemaPath: r } }, { schemaPath: i, parentSchema: a }) {
		let o = a ? r : (0, t.str)`${r}/${e}`;
		return i && (o = (0, t.str)`${o}${(0, n.getErrorPath)(i, n.Type.Str)}`), [u.schemaPath, o];
	}
	function h(e, { params: n, message: i }, a) {
		let { keyword: o, data: s, schemaValue: c, it: l } = e, { opts: d, propertyName: f, topSchemaRef: p, schemaPath: m } = l;
		a.push([u.keyword, o], [u.params, typeof n == "function" ? n(e) : n || (0, t._)`{}`]), d.messages && a.push([u.message, typeof i == "function" ? i(e) : i]), d.verbose && a.push([u.schema, c], [u.parentSchema, (0, t._)`${p}${m}`], [r.default.data, s]), f && a.push([u.propertyName, f]);
	}
})), k = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.boolOrEmptySchema = e.topBoolOrEmptySchema = void 0;
	var t = O(), n = T(), r = D(), i = { message: "boolean schema is false" };
	function a(e) {
		let { gen: t, schema: i, validateName: a } = e;
		i === !1 ? s(e, !1) : typeof i == "object" && i.$async === !0 ? t.return(r.default.data) : (t.assign((0, n._)`${a}.errors`, null), t.return(!0));
	}
	e.topBoolOrEmptySchema = a;
	function o(e, t) {
		let { gen: n, schema: r } = e;
		r === !1 ? (n.var(t, !1), s(e)) : n.var(t, !0);
	}
	e.boolOrEmptySchema = o;
	function s(e, n) {
		let { gen: r, data: a } = e, o = {
			gen: r,
			keyword: "false schema",
			data: a,
			schema: !1,
			schemaCode: !1,
			schemaValue: !1,
			params: {},
			it: e
		};
		(0, t.reportError)(o, i, void 0, n);
	}
})), A = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.getRules = e.isJSONType = void 0;
	var t = /* @__PURE__ */ new Set([
		"string",
		"number",
		"integer",
		"boolean",
		"null",
		"object",
		"array"
	]);
	function n(e) {
		return typeof e == "string" && t.has(e);
	}
	e.isJSONType = n;
	function r() {
		let e = {
			number: {
				type: "number",
				rules: []
			},
			string: {
				type: "string",
				rules: []
			},
			array: {
				type: "array",
				rules: []
			},
			object: {
				type: "object",
				rules: []
			}
		};
		return {
			types: {
				...e,
				integer: !0,
				boolean: !0,
				null: !0
			},
			rules: [
				{ rules: [] },
				e.number,
				e.string,
				e.array,
				e.object
			],
			post: { rules: [] },
			all: {},
			keywords: {}
		};
	}
	e.getRules = r;
})), j = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.shouldUseRule = e.shouldUseGroup = e.schemaHasRulesForType = void 0;
	function t({ schema: e, self: t }, r) {
		let i = t.RULES.types[r];
		return i && i !== !0 && n(e, i);
	}
	e.schemaHasRulesForType = t;
	function n(e, t) {
		return t.rules.some((t) => r(e, t));
	}
	e.shouldUseGroup = n;
	function r(e, t) {
		return e[t.keyword] !== void 0 || t.definition.implements?.some((t) => e[t] !== void 0);
	}
	e.shouldUseRule = r;
})), M = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.reportTypeError = e.checkDataTypes = e.checkDataType = e.coerceAndCheckDataType = e.getJSONTypes = e.getSchemaTypes = e.DataType = void 0;
	var t = A(), n = j(), r = O(), i = T(), a = E(), o;
	(function(e) {
		e[e.Correct = 0] = "Correct", e[e.Wrong = 1] = "Wrong";
	})(o || (e.DataType = o = {}));
	function s(e) {
		let t = c(e.type);
		if (t.includes("null")) {
			if (e.nullable === !1) throw Error("type: null contradicts nullable: false");
		} else {
			if (!t.length && e.nullable !== void 0) throw Error("\"nullable\" cannot be used without \"type\"");
			e.nullable === !0 && t.push("null");
		}
		return t;
	}
	e.getSchemaTypes = s;
	function c(e) {
		let n = Array.isArray(e) ? e : e ? [e] : [];
		if (n.every(t.isJSONType)) return n;
		throw Error("type must be JSONType or JSONType[]: " + n.join(","));
	}
	e.getJSONTypes = c;
	function l(e, t) {
		let { gen: r, data: i, opts: a } = e, s = d(t, a.coerceTypes), c = t.length > 0 && !(s.length === 0 && t.length === 1 && (0, n.schemaHasRulesForType)(e, t[0]));
		if (c) {
			let n = h(t, i, a.strictNumbers, o.Wrong);
			r.if(n, () => {
				s.length ? f(e, t, s) : _(e);
			});
		}
		return c;
	}
	e.coerceAndCheckDataType = l;
	var u = /* @__PURE__ */ new Set([
		"string",
		"number",
		"integer",
		"boolean",
		"null"
	]);
	function d(e, t) {
		return t ? e.filter((e) => u.has(e) || t === "array" && e === "array") : [];
	}
	function f(e, t, n) {
		let { gen: r, data: a, opts: o } = e, s = r.let("dataType", (0, i._)`typeof ${a}`), c = r.let("coerced", (0, i._)`undefined`);
		o.coerceTypes === "array" && r.if((0, i._)`${s} == 'object' && Array.isArray(${a}) && ${a}.length == 1`, () => r.assign(a, (0, i._)`${a}[0]`).assign(s, (0, i._)`typeof ${a}`).if(h(t, a, o.strictNumbers), () => r.assign(c, a))), r.if((0, i._)`${c} !== undefined`);
		for (let e of n) (u.has(e) || e === "array" && o.coerceTypes === "array") && l(e);
		r.else(), _(e), r.endIf(), r.if((0, i._)`${c} !== undefined`, () => {
			r.assign(a, c), p(e, c);
		});
		function l(e) {
			switch (e) {
				case "string":
					r.elseIf((0, i._)`${s} == "number" || ${s} == "boolean"`).assign(c, (0, i._)`"" + ${a}`).elseIf((0, i._)`${a} === null`).assign(c, (0, i._)`""`);
					return;
				case "number":
					r.elseIf((0, i._)`${s} == "boolean" || ${a} === null
              || (${s} == "string" && ${a} && ${a} == +${a})`).assign(c, (0, i._)`+${a}`);
					return;
				case "integer":
					r.elseIf((0, i._)`${s} === "boolean" || ${a} === null
              || (${s} === "string" && ${a} && ${a} == +${a} && !(${a} % 1))`).assign(c, (0, i._)`+${a}`);
					return;
				case "boolean":
					r.elseIf((0, i._)`${a} === "false" || ${a} === 0 || ${a} === null`).assign(c, !1).elseIf((0, i._)`${a} === "true" || ${a} === 1`).assign(c, !0);
					return;
				case "null":
					r.elseIf((0, i._)`${a} === "" || ${a} === 0 || ${a} === false`), r.assign(c, null);
					return;
				case "array": r.elseIf((0, i._)`${s} === "string" || ${s} === "number"
              || ${s} === "boolean" || ${a} === null`).assign(c, (0, i._)`[${a}]`);
			}
		}
	}
	function p({ gen: e, parentData: t, parentDataProperty: n }, r) {
		e.if((0, i._)`${t} !== undefined`, () => e.assign((0, i._)`${t}[${n}]`, r));
	}
	function m(e, t, n, r = o.Correct) {
		let a = r === o.Correct ? i.operators.EQ : i.operators.NEQ, s;
		switch (e) {
			case "null": return (0, i._)`${t} ${a} null`;
			case "array":
				s = (0, i._)`Array.isArray(${t})`;
				break;
			case "object":
				s = (0, i._)`${t} && typeof ${t} == "object" && !Array.isArray(${t})`;
				break;
			case "integer":
				s = c((0, i._)`!(${t} % 1) && !isNaN(${t})`);
				break;
			case "number":
				s = c();
				break;
			default: return (0, i._)`typeof ${t} ${a} ${e}`;
		}
		return r === o.Correct ? s : (0, i.not)(s);
		function c(e = i.nil) {
			return (0, i.and)((0, i._)`typeof ${t} == "number"`, e, n ? (0, i._)`isFinite(${t})` : i.nil);
		}
	}
	e.checkDataType = m;
	function h(e, t, n, r) {
		if (e.length === 1) return m(e[0], t, n, r);
		let o, s = (0, a.toHash)(e);
		if (s.array && s.object) {
			let e = (0, i._)`typeof ${t} != "object"`;
			o = s.null ? e : (0, i._)`!${t} || ${e}`, delete s.null, delete s.array, delete s.object;
		} else o = i.nil;
		s.number && delete s.integer;
		for (let e in s) o = (0, i.and)(o, m(e, t, n, r));
		return o;
	}
	e.checkDataTypes = h;
	var g = {
		message: ({ schema: e }) => `must be ${e}`,
		params: ({ schema: e, schemaValue: t }) => typeof e == "string" ? (0, i._)`{type: ${e}}` : (0, i._)`{type: ${t}}`
	};
	function _(e) {
		let t = v(e);
		(0, r.reportError)(t, g);
	}
	e.reportTypeError = _;
	function v(e) {
		let { gen: t, data: n, schema: r } = e, i = (0, a.schemaRefOrVal)(e, r, "type");
		return {
			gen: t,
			keyword: "type",
			data: n,
			schema: r.type,
			schemaCode: i,
			schemaValue: i,
			parentSchema: r,
			params: {},
			it: e
		};
	}
})), N = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.assignDefaults = void 0;
	var t = T(), n = E();
	function r(e, t) {
		let { properties: n, items: r } = e.schema;
		if (t === "object" && n) for (let t in n) i(e, t, n[t].default);
		else t === "array" && Array.isArray(r) && r.forEach((t, n) => i(e, n, t.default));
	}
	e.assignDefaults = r;
	function i(e, r, i) {
		let { gen: a, compositeRule: o, data: s, opts: c } = e;
		if (i === void 0) return;
		let l = (0, t._)`${s}${(0, t.getProperty)(r)}`;
		if (o) {
			(0, n.checkStrictMode)(e, `default is ignored for: ${l}`);
			return;
		}
		let u = (0, t._)`${l} === undefined`;
		c.useDefaults === "empty" && (u = (0, t._)`${u} || ${l} === null || ${l} === ""`), a.if(u, (0, t._)`${l} = ${(0, t.stringify)(i)}`);
	}
})), P = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.validateUnion = e.validateArray = e.usePattern = e.callValidateCode = e.schemaProperties = e.allSchemaProperties = e.noPropertyInData = e.propertyInData = e.isOwnProperty = e.hasPropFunc = e.reportMissingProp = e.checkMissingProp = e.checkReportMissingProp = void 0;
	var t = T(), n = E(), r = D(), i = E();
	function a(e, n) {
		let { gen: r, data: i, it: a } = e;
		r.if(d(r, i, n, a.opts.ownProperties), () => {
			e.setParams({ missingProperty: (0, t._)`${n}` }, !0), e.error();
		});
	}
	e.checkReportMissingProp = a;
	function o({ gen: e, data: n, it: { opts: r } }, i, a) {
		return (0, t.or)(...i.map((i) => (0, t.and)(d(e, n, i, r.ownProperties), (0, t._)`${a} = ${i}`)));
	}
	e.checkMissingProp = o;
	function s(e, t) {
		e.setParams({ missingProperty: t }, !0), e.error();
	}
	e.reportMissingProp = s;
	function c(e) {
		return e.scopeValue("func", {
			ref: Object.prototype.hasOwnProperty,
			code: (0, t._)`Object.prototype.hasOwnProperty`
		});
	}
	e.hasPropFunc = c;
	function l(e, n, r) {
		return (0, t._)`${c(e)}.call(${n}, ${r})`;
	}
	e.isOwnProperty = l;
	function u(e, n, r, i) {
		let a = (0, t._)`${n}${(0, t.getProperty)(r)} !== undefined`;
		return i ? (0, t._)`${a} && ${l(e, n, r)}` : a;
	}
	e.propertyInData = u;
	function d(e, n, r, i) {
		let a = (0, t._)`${n}${(0, t.getProperty)(r)} === undefined`;
		return i ? (0, t.or)(a, (0, t.not)(l(e, n, r))) : a;
	}
	e.noPropertyInData = d;
	function f(e) {
		return e ? Object.keys(e).filter((e) => e !== "__proto__") : [];
	}
	e.allSchemaProperties = f;
	function p(e, t) {
		return f(t).filter((r) => !(0, n.alwaysValidSchema)(e, t[r]));
	}
	e.schemaProperties = p;
	function m({ schemaCode: e, data: n, it: { gen: i, topSchemaRef: a, schemaPath: o, errorPath: s }, it: c }, l, u, d) {
		let f = d ? (0, t._)`${e}, ${n}, ${a}${o}` : n, p = [
			[r.default.instancePath, (0, t.strConcat)(r.default.instancePath, s)],
			[r.default.parentData, c.parentData],
			[r.default.parentDataProperty, c.parentDataProperty],
			[r.default.rootData, r.default.rootData]
		];
		c.opts.dynamicRef && p.push([r.default.dynamicAnchors, r.default.dynamicAnchors]);
		let m = (0, t._)`${f}, ${i.object(...p)}`;
		return u === t.nil ? (0, t._)`${l}(${m})` : (0, t._)`${l}.call(${u}, ${m})`;
	}
	e.callValidateCode = m;
	var h = (0, t._)`new RegExp`;
	function g({ gen: e, it: { opts: n } }, r) {
		let a = n.unicodeRegExp ? "u" : "", { regExp: o } = n.code, s = o(r, a);
		return e.scopeValue("pattern", {
			key: s.toString(),
			ref: s,
			code: (0, t._)`${o.code === "new RegExp" ? h : (0, i.useFunc)(e, o)}(${r}, ${a})`
		});
	}
	e.usePattern = g;
	function _(e) {
		let { gen: r, data: i, keyword: a, it: o } = e, s = r.name("valid");
		if (o.allErrors) {
			let e = r.let("valid", !0);
			return c(() => r.assign(e, !1)), e;
		}
		return r.var(s, !0), c(() => r.break()), s;
		function c(o) {
			let c = r.const("len", (0, t._)`${i}.length`);
			r.forRange("i", 0, c, (i) => {
				e.subschema({
					keyword: a,
					dataProp: i,
					dataPropType: n.Type.Num
				}, s), r.if((0, t.not)(s), o);
			});
		}
	}
	e.validateArray = _;
	function v(e) {
		let { gen: r, schema: i, keyword: a, it: o } = e;
		/* istanbul ignore if */
		if (!Array.isArray(i)) throw Error("ajv implementation error");
		if (i.some((e) => (0, n.alwaysValidSchema)(o, e)) && !o.opts.unevaluated) return;
		let s = r.let("valid", !1), c = r.name("_valid");
		r.block(() => i.forEach((n, i) => {
			let o = e.subschema({
				keyword: a,
				schemaProp: i,
				compositeRule: !0
			}, c);
			r.assign(s, (0, t._)`${s} || ${c}`), e.mergeValidEvaluated(o, c) || r.if((0, t.not)(s));
		})), e.result(s, () => e.reset(), () => e.error(!0));
	}
	e.validateUnion = v;
})), F = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.validateKeywordUsage = e.validSchemaType = e.funcKeywordCode = e.macroKeywordCode = void 0;
	var t = T(), n = D(), r = P(), i = O();
	function a(e, n) {
		let { gen: r, keyword: i, schema: a, parentSchema: o, it: s } = e, c = n.macro.call(s.self, a, o, s), l = u(r, i, c);
		s.opts.validateSchema !== !1 && s.self.validateSchema(c, !0);
		let d = r.name("valid");
		e.subschema({
			schema: c,
			schemaPath: t.nil,
			errSchemaPath: `${s.errSchemaPath}/${i}`,
			topSchemaRef: l,
			compositeRule: !0
		}, d), e.pass(d, () => e.error(!0));
	}
	e.macroKeywordCode = a;
	function o(e, i) {
		let { gen: a, keyword: o, schema: d, parentSchema: f, $data: p, it: m } = e;
		l(m, i);
		let h = u(a, o, !p && i.compile ? i.compile.call(m.self, d, f, m) : i.validate), g = a.let("valid");
		e.block$data(g, _), e.ok(i.valid ?? g);
		function _() {
			if (i.errors === !1) b(), i.modifying && s(e), x(() => e.error());
			else {
				let t = i.async ? v() : y();
				i.modifying && s(e), x(() => c(e, t));
			}
		}
		function v() {
			let e = a.let("ruleErrs", null);
			return a.try(() => b((0, t._)`await `), (n) => a.assign(g, !1).if((0, t._)`${n} instanceof ${m.ValidationError}`, () => a.assign(e, (0, t._)`${n}.errors`), () => a.throw(n))), e;
		}
		function y() {
			let e = (0, t._)`${h}.errors`;
			return a.assign(e, null), b(t.nil), e;
		}
		function b(o = i.async ? (0, t._)`await ` : t.nil) {
			let s = m.opts.passContext ? n.default.this : n.default.self, c = !("compile" in i && !p || i.schema === !1);
			a.assign(g, (0, t._)`${o}${(0, r.callValidateCode)(e, h, s, c)}`, i.modifying);
		}
		function x(e) {
			a.if((0, t.not)(i.valid ?? g), e);
		}
	}
	e.funcKeywordCode = o;
	function s(e) {
		let { gen: n, data: r, it: i } = e;
		n.if(i.parentData, () => n.assign(r, (0, t._)`${i.parentData}[${i.parentDataProperty}]`));
	}
	function c(e, r) {
		let { gen: a } = e;
		a.if((0, t._)`Array.isArray(${r})`, () => {
			a.assign(n.default.vErrors, (0, t._)`${n.default.vErrors} === null ? ${r} : ${n.default.vErrors}.concat(${r})`).assign(n.default.errors, (0, t._)`${n.default.vErrors}.length`), (0, i.extendErrors)(e);
		}, () => e.error());
	}
	function l({ schemaEnv: e }, t) {
		if (t.async && !e.$async) throw Error("async keyword in sync schema");
	}
	function u(e, n, r) {
		if (r === void 0) throw Error(`keyword "${n}" failed to compile`);
		return e.scopeValue("keyword", typeof r == "function" ? { ref: r } : {
			ref: r,
			code: (0, t.stringify)(r)
		});
	}
	function d(e, t, n = !1) {
		return !t.length || t.some((t) => t === "array" ? Array.isArray(e) : t === "object" ? e && typeof e == "object" && !Array.isArray(e) : typeof e == t || n && e === void 0);
	}
	e.validSchemaType = d;
	function f({ schema: e, opts: t, self: n, errSchemaPath: r }, i, a) {
		/* istanbul ignore if */
		if (Array.isArray(i.keyword) ? !i.keyword.includes(a) : i.keyword !== a) throw Error("ajv implementation error");
		let o = i.dependencies;
		if (o?.some((t) => !Object.prototype.hasOwnProperty.call(e, t))) throw Error(`parent schema must have dependencies of ${a}: ${o.join(",")}`);
		if (i.validateSchema && !i.validateSchema(e[a])) {
			let e = `keyword "${a}" value is invalid at path "${r}": ` + n.errorsText(i.validateSchema.errors);
			if (t.validateSchema === "log") n.logger.error(e);
			else throw Error(e);
		}
	}
	e.validateKeywordUsage = f;
})), I = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.extendSubschemaMode = e.extendSubschemaData = e.getSubschema = void 0;
	var t = T(), n = E();
	function r(e, { keyword: r, schemaProp: i, schema: a, schemaPath: o, errSchemaPath: s, topSchemaRef: c }) {
		if (r !== void 0 && a !== void 0) throw Error("both \"keyword\" and \"schema\" passed, only one allowed");
		if (r !== void 0) {
			let a = e.schema[r];
			return i === void 0 ? {
				schema: a,
				schemaPath: (0, t._)`${e.schemaPath}${(0, t.getProperty)(r)}`,
				errSchemaPath: `${e.errSchemaPath}/${r}`
			} : {
				schema: a[i],
				schemaPath: (0, t._)`${e.schemaPath}${(0, t.getProperty)(r)}${(0, t.getProperty)(i)}`,
				errSchemaPath: `${e.errSchemaPath}/${r}/${(0, n.escapeFragment)(i)}`
			};
		}
		if (a !== void 0) {
			if (o === void 0 || s === void 0 || c === void 0) throw Error("\"schemaPath\", \"errSchemaPath\" and \"topSchemaRef\" are required with \"schema\"");
			return {
				schema: a,
				schemaPath: o,
				topSchemaRef: c,
				errSchemaPath: s
			};
		}
		throw Error("either \"keyword\" or \"schema\" must be passed");
	}
	e.getSubschema = r;
	function i(e, r, { dataProp: i, dataPropType: a, data: o, dataTypes: s, propertyName: c }) {
		if (o !== void 0 && i !== void 0) throw Error("both \"data\" and \"dataProp\" passed, only one allowed");
		let { gen: l } = r;
		if (i !== void 0) {
			let { errorPath: o, dataPathArr: s, opts: c } = r;
			u(l.let("data", (0, t._)`${r.data}${(0, t.getProperty)(i)}`, !0)), e.errorPath = (0, t.str)`${o}${(0, n.getErrorPath)(i, a, c.jsPropertySyntax)}`, e.parentDataProperty = (0, t._)`${i}`, e.dataPathArr = [...s, e.parentDataProperty];
		}
		o !== void 0 && (u(o instanceof t.Name ? o : l.let("data", o, !0)), c !== void 0 && (e.propertyName = c)), s && (e.dataTypes = s);
		function u(t) {
			e.data = t, e.dataLevel = r.dataLevel + 1, e.dataTypes = [], r.definedProperties = /* @__PURE__ */ new Set(), e.parentData = r.data, e.dataNames = [...r.dataNames, t];
		}
	}
	e.extendSubschemaData = i;
	function a(e, { jtdDiscriminator: t, jtdMetadata: n, compositeRule: r, createErrors: i, allErrors: a }) {
		r !== void 0 && (e.compositeRule = r), i !== void 0 && (e.createErrors = i), a !== void 0 && (e.allErrors = a), e.jtdDiscriminator = t, e.jtdMetadata = n;
	}
	e.extendSubschemaMode = a;
})), L = /* @__PURE__ */ s(((e, t) => {
	t.exports = function e(t, n) {
		if (t === n) return !0;
		if (t && n && typeof t == "object" && typeof n == "object") {
			if (t.constructor !== n.constructor) return !1;
			var r, i, a;
			if (Array.isArray(t)) {
				if (r = t.length, r != n.length) return !1;
				for (i = r; i-- !== 0;) if (!e(t[i], n[i])) return !1;
				return !0;
			}
			if (t.constructor === RegExp) return t.source === n.source && t.flags === n.flags;
			if (t.valueOf !== Object.prototype.valueOf) return t.valueOf() === n.valueOf();
			if (t.toString !== Object.prototype.toString) return t.toString() === n.toString();
			if (a = Object.keys(t), r = a.length, r !== Object.keys(n).length) return !1;
			for (i = r; i-- !== 0;) if (!Object.prototype.hasOwnProperty.call(n, a[i])) return !1;
			for (i = r; i-- !== 0;) {
				var o = a[i];
				if (!e(t[o], n[o])) return !1;
			}
			return !0;
		}
		return t !== t && n !== n;
	};
})), R = /* @__PURE__ */ s(((e, t) => {
	var n = t.exports = function(e, t, n) {
		typeof t == "function" && (n = t, t = {}), n = t.cb || n;
		var i = typeof n == "function" ? n : n.pre || function() {}, a = n.post || function() {};
		r(t, i, a, e, "", e);
	};
	n.keywords = {
		additionalItems: !0,
		items: !0,
		contains: !0,
		additionalProperties: !0,
		propertyNames: !0,
		not: !0,
		if: !0,
		then: !0,
		else: !0
	}, n.arrayKeywords = {
		items: !0,
		allOf: !0,
		anyOf: !0,
		oneOf: !0
	}, n.propsKeywords = {
		$defs: !0,
		definitions: !0,
		properties: !0,
		patternProperties: !0,
		dependencies: !0
	}, n.skipKeywords = {
		default: !0,
		enum: !0,
		const: !0,
		required: !0,
		maximum: !0,
		minimum: !0,
		exclusiveMaximum: !0,
		exclusiveMinimum: !0,
		multipleOf: !0,
		maxLength: !0,
		minLength: !0,
		pattern: !0,
		format: !0,
		maxItems: !0,
		minItems: !0,
		uniqueItems: !0,
		maxProperties: !0,
		minProperties: !0
	};
	function r(e, t, a, o, s, c, l, u, d, f) {
		if (o && typeof o == "object" && !Array.isArray(o)) {
			for (var p in t(o, s, c, l, u, d, f), o) {
				var m = o[p];
				if (Array.isArray(m)) {
					if (p in n.arrayKeywords) for (var h = 0; h < m.length; h++) r(e, t, a, m[h], s + "/" + p + "/" + h, c, s, p, o, h);
				} else if (p in n.propsKeywords) {
					if (m && typeof m == "object") for (var g in m) r(e, t, a, m[g], s + "/" + p + "/" + i(g), c, s, p, o, g);
				} else (p in n.keywords || e.allKeys && !(p in n.skipKeywords)) && r(e, t, a, m, s + "/" + p, c, s, p, o);
			}
			a(o, s, c, l, u, d, f);
		}
	}
	function i(e) {
		return e.replace(/~/g, "~0").replace(/\//g, "~1");
	}
})), z = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.getSchemaRefs = e.resolveUrl = e.normalizeId = e._getFullPath = e.getFullPath = e.inlineRef = void 0;
	var t = E(), n = L(), r = R(), i = /* @__PURE__ */ new Set([
		"type",
		"format",
		"pattern",
		"maxLength",
		"minLength",
		"maxProperties",
		"minProperties",
		"maxItems",
		"minItems",
		"maximum",
		"minimum",
		"uniqueItems",
		"multipleOf",
		"required",
		"enum",
		"const"
	]);
	function a(e, t = !0) {
		return typeof e == "boolean" ? !0 : t === !0 ? !s(e) : t ? c(e) <= t : !1;
	}
	e.inlineRef = a;
	var o = /* @__PURE__ */ new Set([
		"$ref",
		"$recursiveRef",
		"$recursiveAnchor",
		"$dynamicRef",
		"$dynamicAnchor"
	]);
	function s(e) {
		for (let t in e) {
			if (o.has(t)) return !0;
			let n = e[t];
			if (Array.isArray(n) && n.some(s) || typeof n == "object" && s(n)) return !0;
		}
		return !1;
	}
	function c(e) {
		let n = 0;
		for (let r in e) if (r === "$ref" || (n++, !i.has(r) && (typeof e[r] == "object" && (0, t.eachItem)(e[r], (e) => n += c(e)), n === Infinity))) return Infinity;
		return n;
	}
	function l(e, t = "", n) {
		return n !== !1 && (t = f(t)), u(e, e.parse(t));
	}
	e.getFullPath = l;
	function u(e, t) {
		return e.serialize(t).split("#")[0] + "#";
	}
	e._getFullPath = u;
	var d = /#\/?$/;
	function f(e) {
		return e ? e.replace(d, "") : "";
	}
	e.normalizeId = f;
	function p(e, t, n) {
		return n = f(n), e.resolve(t, n);
	}
	e.resolveUrl = p;
	var m = /^[a-z_][-a-z0-9._]*$/i;
	function h(e, t) {
		if (typeof e == "boolean") return {};
		let { schemaId: i, uriResolver: a } = this.opts, o = f(e[i] || t), s = { "": o }, c = l(a, o, !1), u = {}, d = /* @__PURE__ */ new Set();
		return r(e, { allKeys: !0 }, (e, t, n, r) => {
			if (r === void 0) return;
			let a = c + t, o = s[r];
			typeof e[i] == "string" && (o = l.call(this, e[i])), g.call(this, e.$anchor), g.call(this, e.$dynamicAnchor), s[t] = o;
			function l(t) {
				let n = this.opts.uriResolver.resolve;
				if (t = f(o ? n(o, t) : t), d.has(t)) throw h(t);
				d.add(t);
				let r = this.refs[t];
				return typeof r == "string" && (r = this.refs[r]), typeof r == "object" ? p(e, r.schema, t) : t !== f(a) && (t[0] === "#" ? (p(e, u[t], t), u[t] = e) : this.refs[t] = a), t;
			}
			function g(e) {
				if (typeof e == "string") {
					if (!m.test(e)) throw Error(`invalid anchor "${e}"`);
					l.call(this, `#${e}`);
				}
			}
		}), u;
		function p(e, t, r) {
			if (t !== void 0 && !n(e, t)) throw h(r);
		}
		function h(e) {
			return /* @__PURE__ */ Error(`reference "${e}" resolves to more than one schema`);
		}
	}
	e.getSchemaRefs = h;
})), B = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.getData = e.KeywordCxt = e.validateFunctionCode = void 0;
	var t = k(), n = M(), r = j(), i = M(), a = N(), o = F(), s = I(), c = T(), l = D(), u = z(), d = E(), f = O();
	function p(e) {
		if (S(e) && (w(e), x(e))) {
			_(e);
			return;
		}
		m(e, () => (0, t.topBoolOrEmptySchema)(e));
	}
	e.validateFunctionCode = p;
	function m({ gen: e, validateName: t, schema: n, schemaEnv: r, opts: i }, a) {
		i.code.es5 ? e.func(t, (0, c._)`${l.default.data}, ${l.default.valCxt}`, r.$async, () => {
			e.code((0, c._)`"use strict"; ${y(n, i)}`), g(e, i), e.code(a);
		}) : e.func(t, (0, c._)`${l.default.data}, ${h(i)}`, r.$async, () => e.code(y(n, i)).code(a));
	}
	function h(e) {
		return (0, c._)`{${l.default.instancePath}="", ${l.default.parentData}, ${l.default.parentDataProperty}, ${l.default.rootData}=${l.default.data}${e.dynamicRef ? (0, c._)`, ${l.default.dynamicAnchors}={}` : c.nil}}={}`;
	}
	function g(e, t) {
		e.if(l.default.valCxt, () => {
			e.var(l.default.instancePath, (0, c._)`${l.default.valCxt}.${l.default.instancePath}`), e.var(l.default.parentData, (0, c._)`${l.default.valCxt}.${l.default.parentData}`), e.var(l.default.parentDataProperty, (0, c._)`${l.default.valCxt}.${l.default.parentDataProperty}`), e.var(l.default.rootData, (0, c._)`${l.default.valCxt}.${l.default.rootData}`), t.dynamicRef && e.var(l.default.dynamicAnchors, (0, c._)`${l.default.valCxt}.${l.default.dynamicAnchors}`);
		}, () => {
			e.var(l.default.instancePath, (0, c._)`""`), e.var(l.default.parentData, (0, c._)`undefined`), e.var(l.default.parentDataProperty, (0, c._)`undefined`), e.var(l.default.rootData, l.default.data), t.dynamicRef && e.var(l.default.dynamicAnchors, (0, c._)`{}`);
		});
	}
	function _(e) {
		let { schema: t, opts: n, gen: r } = e;
		m(e, () => {
			n.$comment && t.$comment && V(e), L(e), r.let(l.default.vErrors, null), r.let(l.default.errors, 0), n.unevaluated && v(e), A(e), H(e);
		});
	}
	function v(e) {
		let { gen: t, validateName: n } = e;
		e.evaluated = t.const("evaluated", (0, c._)`${n}.evaluated`), t.if((0, c._)`${e.evaluated}.dynamicProps`, () => t.assign((0, c._)`${e.evaluated}.props`, (0, c._)`undefined`)), t.if((0, c._)`${e.evaluated}.dynamicItems`, () => t.assign((0, c._)`${e.evaluated}.items`, (0, c._)`undefined`));
	}
	function y(e, t) {
		let n = typeof e == "object" && e[t.schemaId];
		return n && (t.code.source || t.code.process) ? (0, c._)`/*# sourceURL=${n} */` : c.nil;
	}
	function b(e, n) {
		if (S(e) && (w(e), x(e))) {
			C(e, n);
			return;
		}
		(0, t.boolOrEmptySchema)(e, n);
	}
	function x({ schema: e, self: t }) {
		if (typeof e == "boolean") return !e;
		for (let n in e) if (t.RULES.all[n]) return !0;
		return !1;
	}
	function S(e) {
		return typeof e.schema != "boolean";
	}
	function C(e, t) {
		let { schema: n, gen: r, opts: i } = e;
		i.$comment && n.$comment && V(e), R(e), B(e);
		let a = r.const("_errs", l.default.errors);
		A(e, a), r.var(t, (0, c._)`${a} === ${l.default.errors}`);
	}
	function w(e) {
		(0, d.checkUnknownRules)(e), P(e);
	}
	function A(e, t) {
		if (e.opts.jtd) return ee(e, [], !1, t);
		let r = (0, n.getSchemaTypes)(e.schema);
		ee(e, r, !(0, n.coerceAndCheckDataType)(e, r), t);
	}
	function P(e) {
		let { schema: t, errSchemaPath: n, opts: r, self: i } = e;
		t.$ref && r.ignoreKeywordsWithRef && (0, d.schemaHasRulesButRef)(t, i.RULES) && i.logger.warn(`$ref: keywords ignored in schema at path "${n}"`);
	}
	function L(e) {
		let { schema: t, opts: n } = e;
		t.default !== void 0 && n.useDefaults && n.strictSchema && (0, d.checkStrictMode)(e, "default is ignored in the schema root");
	}
	function R(e) {
		let t = e.schema[e.opts.schemaId];
		t && (e.baseId = (0, u.resolveUrl)(e.opts.uriResolver, e.baseId, t));
	}
	function B(e) {
		if (e.schema.$async && !e.schemaEnv.$async) throw Error("async schema in sync schema");
	}
	function V({ gen: e, schemaEnv: t, schema: n, errSchemaPath: r, opts: i }) {
		let a = n.$comment;
		if (i.$comment === !0) e.code((0, c._)`${l.default.self}.logger.log(${a})`);
		else if (typeof i.$comment == "function") {
			let n = (0, c.str)`${r}/$comment`, i = e.scopeValue("root", { ref: t.root });
			e.code((0, c._)`${l.default.self}.opts.$comment(${a}, ${n}, ${i}.schema)`);
		}
	}
	function H(e) {
		let { gen: t, schemaEnv: n, validateName: r, ValidationError: i, opts: a } = e;
		n.$async ? t.if((0, c._)`${l.default.errors} === 0`, () => t.return(l.default.data), () => t.throw((0, c._)`new ${i}(${l.default.vErrors})`)) : (t.assign((0, c._)`${r}.errors`, l.default.vErrors), a.unevaluated && U(e), t.return((0, c._)`${l.default.errors} === 0`));
	}
	function U({ gen: e, evaluated: t, props: n, items: r }) {
		n instanceof c.Name && e.assign((0, c._)`${t}.props`, n), r instanceof c.Name && e.assign((0, c._)`${t}.items`, r);
	}
	function ee(e, t, n, a) {
		let { gen: o, schema: s, data: u, allErrors: f, opts: p, self: m } = e, { RULES: h } = m;
		if (s.$ref && (p.ignoreKeywordsWithRef || !(0, d.schemaHasRulesButRef)(s, h))) {
			o.block(() => ie(e, "$ref", h.all.$ref.definition));
			return;
		}
		p.jtd || G(e, t), o.block(() => {
			for (let e of h.rules) g(e);
			g(h.post);
		});
		function g(d) {
			(0, r.shouldUseGroup)(s, d) && (d.type ? (o.if((0, i.checkDataType)(d.type, u, p.strictNumbers)), W(e, d), t.length === 1 && t[0] === d.type && n && (o.else(), (0, i.reportTypeError)(e)), o.endIf()) : W(e, d), f || o.if((0, c._)`${l.default.errors} === ${a || 0}`));
		}
	}
	function W(e, t) {
		let { gen: n, schema: i, opts: { useDefaults: o } } = e;
		o && (0, a.assignDefaults)(e, t.type), n.block(() => {
			for (let n of t.rules) (0, r.shouldUseRule)(i, n) && ie(e, n.keyword, n.definition, t.type);
		});
	}
	function G(e, t) {
		e.schemaEnv.meta || !e.opts.strictTypes || (K(e, t), e.opts.allowUnionTypes || q(e, t), J(e, e.dataTypes));
	}
	function K(e, t) {
		if (t.length) {
			if (!e.dataTypes.length) {
				e.dataTypes = t;
				return;
			}
			t.forEach((t) => {
				ne(e.dataTypes, t) || Y(e, `type "${t}" not allowed by context "${e.dataTypes.join(",")}"`);
			}), re(e, t);
		}
	}
	function q(e, t) {
		t.length > 1 && !(t.length === 2 && t.includes("null")) && Y(e, "use allowUnionTypes to allow union type keyword");
	}
	function J(e, t) {
		let n = e.self.RULES.all;
		for (let i in n) {
			let a = n[i];
			if (typeof a == "object" && (0, r.shouldUseRule)(e.schema, a)) {
				let { type: n } = a.definition;
				n.length && !n.some((e) => te(t, e)) && Y(e, `missing type "${n.join(",")}" for keyword "${i}"`);
			}
		}
	}
	function te(e, t) {
		return e.includes(t) || t === "number" && e.includes("integer");
	}
	function ne(e, t) {
		return e.includes(t) || t === "integer" && e.includes("number");
	}
	function re(e, t) {
		let n = [];
		for (let r of e.dataTypes) ne(t, r) ? n.push(r) : t.includes("integer") && r === "number" && n.push("integer");
		e.dataTypes = n;
	}
	function Y(e, t) {
		let n = e.schemaEnv.baseId + e.errSchemaPath;
		t += ` at "${n}" (strictTypes)`, (0, d.checkStrictMode)(e, t, e.opts.strictTypes);
	}
	var X = class {
		constructor(e, t, n) {
			if ((0, o.validateKeywordUsage)(e, t, n), this.gen = e.gen, this.allErrors = e.allErrors, this.keyword = n, this.data = e.data, this.schema = e.schema[n], this.$data = t.$data && e.opts.$data && this.schema && this.schema.$data, this.schemaValue = (0, d.schemaRefOrVal)(e, this.schema, n, this.$data), this.schemaType = t.schemaType, this.parentSchema = e.schema, this.params = {}, this.it = e, this.def = t, this.$data) this.schemaCode = e.gen.const("vSchema", Z(this.$data, e));
			else if (this.schemaCode = this.schemaValue, !(0, o.validSchemaType)(this.schema, t.schemaType, t.allowUndefined)) throw Error(`${n} value must be ${JSON.stringify(t.schemaType)}`);
			("code" in t ? t.trackErrors : t.errors !== !1) && (this.errsCount = e.gen.const("_errs", l.default.errors));
		}
		result(e, t, n) {
			this.failResult((0, c.not)(e), t, n);
		}
		failResult(e, t, n) {
			this.gen.if(e), n ? n() : this.error(), t ? (this.gen.else(), t(), this.allErrors && this.gen.endIf()) : this.allErrors ? this.gen.endIf() : this.gen.else();
		}
		pass(e, t) {
			this.failResult((0, c.not)(e), void 0, t);
		}
		fail(e) {
			if (e === void 0) {
				this.error(), this.allErrors || this.gen.if(!1);
				return;
			}
			this.gen.if(e), this.error(), this.allErrors ? this.gen.endIf() : this.gen.else();
		}
		fail$data(e) {
			if (!this.$data) return this.fail(e);
			let { schemaCode: t } = this;
			this.fail((0, c._)`${t} !== undefined && (${(0, c.or)(this.invalid$data(), e)})`);
		}
		error(e, t, n) {
			if (t) {
				this.setParams(t), this._error(e, n), this.setParams({});
				return;
			}
			this._error(e, n);
		}
		_error(e, t) {
			(e ? f.reportExtraError : f.reportError)(this, this.def.error, t);
		}
		$dataError() {
			(0, f.reportError)(this, this.def.$dataError || f.keyword$DataError);
		}
		reset() {
			if (this.errsCount === void 0) throw Error("add \"trackErrors\" to keyword definition");
			(0, f.resetErrorsCount)(this.gen, this.errsCount);
		}
		ok(e) {
			this.allErrors || this.gen.if(e);
		}
		setParams(e, t) {
			t ? Object.assign(this.params, e) : this.params = e;
		}
		block$data(e, t, n = c.nil) {
			this.gen.block(() => {
				this.check$data(e, n), t();
			});
		}
		check$data(e = c.nil, t = c.nil) {
			if (!this.$data) return;
			let { gen: n, schemaCode: r, schemaType: i, def: a } = this;
			n.if((0, c.or)((0, c._)`${r} === undefined`, t)), e !== c.nil && n.assign(e, !0), (i.length || a.validateSchema) && (n.elseIf(this.invalid$data()), this.$dataError(), e !== c.nil && n.assign(e, !1)), n.else();
		}
		invalid$data() {
			let { gen: e, schemaCode: t, schemaType: n, def: r, it: a } = this;
			return (0, c.or)(o(), s());
			function o() {
				if (n.length) {
					/* istanbul ignore if */
					if (!(t instanceof c.Name)) throw Error("ajv implementation error");
					let e = Array.isArray(n) ? n : [n];
					return (0, c._)`${(0, i.checkDataTypes)(e, t, a.opts.strictNumbers, i.DataType.Wrong)}`;
				}
				return c.nil;
			}
			function s() {
				if (r.validateSchema) {
					let n = e.scopeValue("validate$data", { ref: r.validateSchema });
					return (0, c._)`!${n}(${t})`;
				}
				return c.nil;
			}
		}
		subschema(e, t) {
			let n = (0, s.getSubschema)(this.it, e);
			(0, s.extendSubschemaData)(n, this.it, e), (0, s.extendSubschemaMode)(n, e);
			let r = {
				...this.it,
				...n,
				items: void 0,
				props: void 0
			};
			return b(r, t), r;
		}
		mergeEvaluated(e, t) {
			let { it: n, gen: r } = this;
			n.opts.unevaluated && (n.props !== !0 && e.props !== void 0 && (n.props = d.mergeEvaluated.props(r, e.props, n.props, t)), n.items !== !0 && e.items !== void 0 && (n.items = d.mergeEvaluated.items(r, e.items, n.items, t)));
		}
		mergeValidEvaluated(e, t) {
			let { it: n, gen: r } = this;
			if (n.opts.unevaluated && (n.props !== !0 || n.items !== !0)) return r.if(t, () => this.mergeEvaluated(e, c.Name)), !0;
		}
	};
	e.KeywordCxt = X;
	function ie(e, t, n, r) {
		let i = new X(e, n, t);
		"code" in n ? n.code(i, r) : i.$data && n.validate ? (0, o.funcKeywordCode)(i, n) : "macro" in n ? (0, o.macroKeywordCode)(i, n) : (n.compile || n.validate) && (0, o.funcKeywordCode)(i, n);
	}
	var ae = /^\/(?:[^~]|~0|~1)*$/, oe = /^([0-9]+)(#|\/(?:[^~]|~0|~1)*)?$/;
	function Z(e, { dataLevel: t, dataNames: n, dataPathArr: r }) {
		let i, a;
		if (e === "") return l.default.rootData;
		if (e[0] === "/") {
			if (!ae.test(e)) throw Error(`Invalid JSON-pointer: ${e}`);
			i = e, a = l.default.rootData;
		} else {
			let o = oe.exec(e);
			if (!o) throw Error(`Invalid JSON-pointer: ${e}`);
			let s = +o[1];
			if (i = o[2], i === "#") {
				if (s >= t) throw Error(u("property/index", s));
				return r[t - s];
			}
			if (s > t) throw Error(u("data", s));
			if (a = n[t - s], !i) return a;
		}
		let o = a, s = i.split("/");
		for (let e of s) e && (a = (0, c._)`${a}${(0, c.getProperty)((0, d.unescapeJsonPointer)(e))}`, o = (0, c._)`${o} && ${a}`);
		return o;
		function u(e, n) {
			return `Cannot access ${e} ${n} levels up, current level is ${t}`;
		}
	}
	e.getData = Z;
})), V = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.default = class extends Error {
		constructor(e) {
			super("validation failed"), this.errors = e, this.ajv = this.validation = !0;
		}
	};
})), H = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = z();
	e.default = class extends Error {
		constructor(e, n, r, i) {
			super(i || `can't resolve reference ${r} from id ${n}`), this.missingRef = (0, t.resolveUrl)(e, n, r), this.missingSchema = (0, t.normalizeId)((0, t.getFullPath)(e, this.missingRef));
		}
	};
})), U = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.resolveSchema = e.getCompilingSchema = e.resolveRef = e.compileSchema = e.SchemaEnv = void 0;
	var t = T(), n = V(), r = D(), i = z(), a = E(), o = B(), s = class {
		constructor(e) {
			this.refs = {}, this.dynamicAnchors = {};
			let t;
			typeof e.schema == "object" && (t = e.schema), this.schema = e.schema, this.schemaId = e.schemaId, this.root = e.root || this, this.baseId = e.baseId ?? (0, i.normalizeId)(t?.[e.schemaId || "$id"]), this.schemaPath = e.schemaPath, this.localRefs = e.localRefs, this.meta = e.meta, this.$async = t?.$async, this.refs = {};
		}
	};
	e.SchemaEnv = s;
	function c(e) {
		let a = d.call(this, e);
		if (a) return a;
		let s = (0, i.getFullPath)(this.opts.uriResolver, e.root.baseId), { es5: c, lines: l } = this.opts.code, { ownProperties: u } = this.opts, f = new t.CodeGen(this.scope, {
			es5: c,
			lines: l,
			ownProperties: u
		}), p;
		e.$async && (p = f.scopeValue("Error", {
			ref: n.default,
			code: (0, t._)`require("ajv/dist/runtime/validation_error").default`
		}));
		let m = f.scopeName("validate");
		e.validateName = m;
		let h = {
			gen: f,
			allErrors: this.opts.allErrors,
			data: r.default.data,
			parentData: r.default.parentData,
			parentDataProperty: r.default.parentDataProperty,
			dataNames: [r.default.data],
			dataPathArr: [t.nil],
			dataLevel: 0,
			dataTypes: [],
			definedProperties: /* @__PURE__ */ new Set(),
			topSchemaRef: f.scopeValue("schema", this.opts.code.source === !0 ? {
				ref: e.schema,
				code: (0, t.stringify)(e.schema)
			} : { ref: e.schema }),
			validateName: m,
			ValidationError: p,
			schema: e.schema,
			schemaEnv: e,
			rootId: s,
			baseId: e.baseId || s,
			schemaPath: t.nil,
			errSchemaPath: e.schemaPath || (this.opts.jtd ? "" : "#"),
			errorPath: (0, t._)`""`,
			opts: this.opts,
			self: this
		}, g;
		try {
			this._compilations.add(e), (0, o.validateFunctionCode)(h), f.optimize(this.opts.code.optimize);
			let n = f.toString();
			g = `${f.scopeRefs(r.default.scope)}return ${n}`, this.opts.code.process && (g = this.opts.code.process(g, e));
			let i = Function(`${r.default.self}`, `${r.default.scope}`, g)(this, this.scope.get());
			if (this.scope.value(m, { ref: i }), i.errors = null, i.schema = e.schema, i.schemaEnv = e, e.$async && (i.$async = !0), this.opts.code.source === !0 && (i.source = {
				validateName: m,
				validateCode: n,
				scopeValues: f._values
			}), this.opts.unevaluated) {
				let { props: e, items: n } = h;
				i.evaluated = {
					props: e instanceof t.Name ? void 0 : e,
					items: n instanceof t.Name ? void 0 : n,
					dynamicProps: e instanceof t.Name,
					dynamicItems: n instanceof t.Name
				}, i.source && (i.source.evaluated = (0, t.stringify)(i.evaluated));
			}
			return e.validate = i, e;
		} catch (t) {
			throw delete e.validate, delete e.validateName, g && this.logger.error("Error compiling schema, function code:", g), t;
		} finally {
			this._compilations.delete(e);
		}
	}
	e.compileSchema = c;
	function l(e, t, n) {
		n = (0, i.resolveUrl)(this.opts.uriResolver, t, n);
		let r = e.refs[n];
		if (r) return r;
		let a = p.call(this, e, n);
		if (a === void 0) {
			let r = e.localRefs?.[n], { schemaId: i } = this.opts;
			r && (a = new s({
				schema: r,
				schemaId: i,
				root: e,
				baseId: t
			}));
		}
		if (a !== void 0) return e.refs[n] = u.call(this, a);
	}
	e.resolveRef = l;
	function u(e) {
		return (0, i.inlineRef)(e.schema, this.opts.inlineRefs) ? e.schema : e.validate ? e : c.call(this, e);
	}
	function d(e) {
		for (let t of this._compilations) if (f(t, e)) return t;
	}
	e.getCompilingSchema = d;
	function f(e, t) {
		return e.schema === t.schema && e.root === t.root && e.baseId === t.baseId;
	}
	function p(e, t) {
		let n;
		for (; typeof (n = this.refs[t]) == "string";) t = n;
		return n || this.schemas[t] || m.call(this, e, t);
	}
	function m(e, t) {
		let n = this.opts.uriResolver.parse(t), r = (0, i._getFullPath)(this.opts.uriResolver, n), a = (0, i.getFullPath)(this.opts.uriResolver, e.baseId, void 0);
		if (Object.keys(e.schema).length > 0 && r === a) return g.call(this, n, e);
		let o = (0, i.normalizeId)(r), l = this.refs[o] || this.schemas[o];
		if (typeof l == "string") {
			let t = m.call(this, e, l);
			return typeof t?.schema == "object" ? g.call(this, n, t) : void 0;
		}
		if (typeof l?.schema == "object") {
			if (l.validate || c.call(this, l), o === (0, i.normalizeId)(t)) {
				let { schema: t } = l, { schemaId: n } = this.opts, r = t[n];
				return r && (a = (0, i.resolveUrl)(this.opts.uriResolver, a, r)), new s({
					schema: t,
					schemaId: n,
					root: e,
					baseId: a
				});
			}
			return g.call(this, n, l);
		}
	}
	e.resolveSchema = m;
	var h = /* @__PURE__ */ new Set([
		"properties",
		"patternProperties",
		"enum",
		"dependencies",
		"definitions"
	]);
	function g(e, { baseId: t, schema: n, root: r }) {
		if (e.fragment?.[0] !== "/") return;
		for (let r of e.fragment.slice(1).split("/")) {
			if (typeof n == "boolean") return;
			let e = n[(0, a.unescapeFragment)(r)];
			if (e === void 0) return;
			n = e;
			let o = typeof n == "object" && n[this.opts.schemaId];
			!h.has(r) && o && (t = (0, i.resolveUrl)(this.opts.uriResolver, t, o));
		}
		let o;
		if (typeof n != "boolean" && n.$ref && !(0, a.schemaHasRulesButRef)(n, this.RULES)) {
			let e = (0, i.resolveUrl)(this.opts.uriResolver, t, n.$ref);
			o = m.call(this, r, e);
		}
		let { schemaId: c } = this.opts;
		if (o ||= new s({
			schema: n,
			schemaId: c,
			root: r,
			baseId: t
		}), o.schema !== o.root.schema) return o;
	}
})), ee = /* @__PURE__ */ c({
	$id: () => W,
	additionalProperties: () => !1,
	default: () => te,
	description: () => G,
	properties: () => J,
	required: () => q,
	type: () => K
}), W, G, K, q, J, te, ne = o((() => {
	W = "https://raw.githubusercontent.com/ajv-validator/ajv/master/lib/refs/data.json#", G = "Meta-schema for $data reference (JSON AnySchema extension proposal)", K = "object", q = ["$data"], J = { $data: {
		type: "string",
		anyOf: [{ format: "relative-json-pointer" }, { format: "json-pointer" }]
	} }, te = {
		$id: W,
		description: G,
		type: K,
		required: q,
		properties: J,
		additionalProperties: !1
	};
})), re = /* @__PURE__ */ s(((e, t) => {
	var n = RegExp.prototype.test.bind(/^[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}$/iu), r = RegExp.prototype.test.bind(/^(?:(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]\d|\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]\d|\d)$/u), i = RegExp.prototype.test.bind(/^\d*$/u), a = RegExp.prototype.test.bind(/^[\da-f]{2}$/iu), o = RegExp.prototype.test.bind(/^[\da-z\-._~]$/iu), s = RegExp.prototype.test.bind(/^[A-Za-z0-9\-._~!$&'()*+,;=:@/]$/u), c = RegExp.prototype.test.bind(/^[A-Za-z0-9\-._~!$&'()*+,;=:@/?]$/u), l = RegExp.prototype.test.bind(/^[A-Za-z0-9\-._~!$&'()*+,;=:]$/u), u = Array(256);
	{
		let e = "0123456789ABCDEF";
		for (let t = 0; t < 256; t++) u[t] = "%" + e[t >> 4] + e[t & 15];
	}
	function d(e) {
		return e < 2048 ? u[192 | e >> 6] + u[128 | e & 63] : e < 65536 ? u[224 | e >> 12] + u[128 | e >> 6 & 63] + u[128 | e & 63] : u[240 | e >> 18] + u[128 | e >> 12 & 63] + u[128 | e >> 6 & 63] + u[128 | e & 63];
	}
	function f(e) {
		let t = "", n = 0, r = 0;
		for (r = 0; r < e.length; r++) if (n = e[r].charCodeAt(0), n !== 48) {
			if (!(n >= 48 && n <= 57 || n >= 65 && n <= 70 || n >= 97 && n <= 102)) return "";
			t += e[r];
			break;
		}
		for (r += 1; r < e.length; r++) {
			if (n = e[r].charCodeAt(0), !(n >= 48 && n <= 57 || n >= 65 && n <= 70 || n >= 97 && n <= 102)) return "";
			t += e[r];
		}
		return t;
	}
	var p = RegExp.prototype.test.bind(/^[\dA-Fa-f]{1,4}$/), m = RegExp.prototype.test.bind(/^[vV][\dA-Fa-f]+\.[A-Za-z\d\-._~!$&'()*+,;=:]+$/), h = RegExp.prototype.test.bind(/^[A-Za-z\d\-._~]$/), g = RegExp.prototype.test.bind(/[^!"$&'()*+,\-.;=_`a-z{}~]/u);
	function _(e) {
		if (e.length === 0) return !1;
		for (let t = 0; t < e.length; t++) if (!h(e[t])) {
			if (e[t] === "%" && t + 2 < e.length && a(e.slice(t + 1, t + 3))) {
				t += 2;
				continue;
			}
			return !1;
		}
		return !0;
	}
	function v(e) {
		let t = -1, n = 0, r = -1, i = 0;
		for (let a = 0; a < e.length; a++) e[a] === "0" ? (r === -1 && (r = a), i++, i > n && (n = i, t = r)) : (r = -1, i = 0);
		if (n < 2) return e.join(":");
		let a = e.slice(0, t).join(":"), o = e.slice(t + n).join(":");
		return a + "::" + o;
	}
	function y(e) {
		let t = e.indexOf("::");
		if (t !== -1 && e.indexOf("::", t + 1) !== -1) return;
		let n = t === -1 ? e.split(":") : e.slice(0, t).split(":"), i = t === -1 ? [] : e.slice(t + 2).split(":");
		t !== -1 && (n.length === 1 && n[0] === "" && (n.length = 0), i.length === 1 && i[0] === "" && (i.length = 0));
		let a = n.concat(i), o = 0;
		for (let e = 0; e < a.length; e++) {
			let n = a[e];
			if (n === "") return;
			if (n.indexOf(".") !== -1) {
				if (e !== a.length - 1 || t !== -1 && i.length === 0 || !r(n)) return;
				o += 2;
				continue;
			}
			if (!p(n)) return;
			a[e] = parseInt(n, 16).toString(16), o++;
		}
		if (t === -1) return o === 8 ? v(a) : void 0;
		if (o >= 8) return;
		let s = a.slice(0, n.length);
		for (let e = o; e < 8; e++) s.push("0");
		for (let e = n.length; e < a.length; e++) s.push(a[e]);
		return v(s);
	}
	function b(e) {
		let t = e[0] === "[" && e[e.length - 1] === "]";
		if ((e[0] === "[" || e[e.length - 1] === "]") && !t) return {
			host: e,
			isIPV6: !1,
			error: !0
		};
		let n = t ? e.slice(1, -1) : e;
		if (t && m(n)) return n = n.toLowerCase(), {
			host: `[${n}]`,
			escapedHost: n,
			isIPV6: !1,
			isIPVFuture: !0
		};
		if (x(n, ":") < 2) return {
			host: e,
			isIPV6: !1,
			error: t
		};
		let r = "", i = n.indexOf("%");
		if (i !== -1) {
			let t = n.slice(i, i + 3).toLowerCase() === "%25" ? 3 : 1;
			if (r = n.slice(i + t), !_(r)) return {
				host: e,
				isIPV6: !1,
				error: !0
			};
			n = n.slice(0, i);
		}
		let a = y(n);
		return a === void 0 ? {
			host: e,
			isIPV6: !1,
			error: !0
		} : {
			host: a + (r ? "%" + r : ""),
			escapedHost: a + (r ? "%25" + r : ""),
			isIPV6: !0
		};
	}
	function x(e, t) {
		let n = 0;
		for (let r = 0; r < e.length; r++) e[r] === t && n++;
		return n;
	}
	function S(e) {
		let t = e, n = [], r = -1, i = 0;
		for (; i = t.length;) {
			if (i === 1) {
				if (t === ".") break;
				if (t === "/") {
					n.push("/");
					break;
				} else {
					n.push(t);
					break;
				}
			} else if (i === 2) {
				if (t[0] === ".") {
					if (t[1] === ".") break;
					if (t[1] === "/") {
						t = t.slice(2);
						continue;
					}
				} else if (t[0] === "/" && (t[1] === "." || t[1] === "/")) {
					n.push("/");
					break;
				}
			} else if (i === 3 && t === "/..") {
				n.length !== 0 && n.pop(), n.push("/");
				break;
			}
			if (t[0] === ".") {
				if (t[1] === ".") {
					if (t[2] === "/") {
						t = t.slice(3);
						continue;
					}
				} else if (t[1] === "/") {
					t = t.slice(2);
					continue;
				}
			} else if (t[0] === "/" && t[1] === ".") {
				if (t[2] === "/") {
					t = t.slice(2);
					continue;
				} else if (t[2] === "." && t[3] === "/") {
					t = t.slice(3), n.length !== 0 && n.pop();
					continue;
				}
			}
			if ((r = t.indexOf("/", 1)) === -1) {
				n.push(t);
				break;
			} else n.push(t.slice(0, r)), t = t.slice(r);
		}
		return n.join("");
	}
	function C(e) {
		if (e === "" || e[0] === "/") return S(e);
		let t = e.split("/"), n = t.length - 1, r = [], i = !1;
		for (let e = 0; e <= n; e++) {
			let a = t[e];
			a === "." || a === ".." ? (a === ".." && (r.length !== 0 && r[r.length - 1] !== ".." ? r.pop() : r.push("..")), i = e === n) : r.push(a);
		}
		return i && r[r.length - 1] !== ".." && r.push(""), (r.length === 0 || r[0] === "" || r[0].includes(":")) && r.unshift("."), r.join("/");
	}
	var w = {
		"@": "%40",
		"/": "%2F",
		"?": "%3F",
		"#": "%23",
		":": "%3A"
	}, T = /[@/?#:]/g, E = /[@/?#]/g;
	function D(e, t) {
		let n = t ? E : T;
		return n.lastIndex = 0, e.replace(n, (e) => w[e]);
	}
	function O(e, t = !1) {
		if (e.indexOf("%") === -1) return e;
		let n = "";
		for (let r = 0; r < e.length; r++) {
			if (e[r] === "%" && r + 2 < e.length) {
				let i = e.slice(r + 1, r + 3);
				if (a(i)) {
					let e = i.toUpperCase(), a = String.fromCharCode(parseInt(e, 16));
					t && o(a) ? n += a : n += "%" + e, r += 2;
					continue;
				}
			}
			n += e[r];
		}
		return n;
	}
	function k(e) {
		let t = "";
		for (let n = 0; n < e.length; n++) {
			let r = e[n];
			if (r === "%" && n + 2 < e.length) {
				let r = e.slice(n + 1, n + 3);
				if (a(r)) {
					let e = r.toUpperCase(), i = String.fromCharCode(parseInt(e, 16));
					i !== "." && o(i) ? t += i : t += "%" + e, n += 2;
					continue;
				}
			}
			if (s(r)) t += r;
			else {
				let i = e.charCodeAt(n);
				if (i < 128) t += F(i) ? r : u[i];
				else if (i < 55296 || i > 57343) t += d(i);
				else if (i <= 56319 && n + 1 < e.length) {
					let r = e.charCodeAt(n + 1);
					r >= 56320 && r <= 57343 ? (t += d(65536 + (i - 55296 << 10) + (r - 56320)), n++) : t += d(65533);
				} else t += d(65533);
			}
		}
		return t;
	}
	function A(e, t = !1) {
		let n = "", r = t && e[0] !== "/";
		for (let t = 0; t < e.length; t++) {
			let i = e[t];
			if (i === "%" && t + 2 < e.length) {
				let r = e.slice(t + 1, t + 3);
				if (a(r)) {
					n += "%" + r.toUpperCase(), t += 2;
					continue;
				}
			}
			if (i === "/" && (r = !1), s(i) && (i !== ":" || !r)) n += i;
			else {
				let r = e.charCodeAt(t);
				if (r < 128) n += u[r];
				else if (r < 55296 || r > 57343) n += d(r);
				else if (r <= 56319 && t + 1 < e.length) {
					let i = e.charCodeAt(t + 1);
					i >= 56320 && i <= 57343 ? (n += d(65536 + (r - 55296 << 10) + (i - 56320)), t++) : n += d(65533);
				} else n += d(65533);
			}
		}
		return n;
	}
	function j(e, t) {
		let n = "";
		for (let r = 0; r < e.length; r++) {
			let i = e[r];
			if (i === "%" && r + 2 < e.length) {
				let t = e.slice(r + 1, r + 3);
				if (a(t)) {
					n += "%" + t.toUpperCase(), r += 2;
					continue;
				}
			}
			if (t(i)) n += i;
			else {
				let t = e.charCodeAt(r);
				if (t < 128) n += u[t];
				else if (t < 55296 || t > 57343) n += d(t);
				else if (t <= 56319 && r + 1 < e.length) {
					let i = e.charCodeAt(r + 1);
					i >= 56320 && i <= 57343 ? (n += d(65536 + (t - 55296 << 10) + (i - 56320)), r++) : n += d(65533);
				} else n += d(65533);
			}
		}
		return n;
	}
	function M(e) {
		return j(e, l);
	}
	function N(e) {
		return j(e, c);
	}
	function P(e) {
		return j(e, c);
	}
	function F(e) {
		return e >= 48 && e <= 57 || e >= 65 && e <= 90 || e >= 97 && e <= 122 || e === 42 || e === 43 || e === 45 || e === 46 || e === 47 || e === 64 || e === 95;
	}
	function I(e) {
		let t = "";
		for (let n = 0; n < e.length; n++) {
			let r = e[n];
			if (r === "%" && n + 2 < e.length) {
				let r = e.slice(n + 1, n + 3);
				if (a(r)) {
					let e = r.toUpperCase(), i = String.fromCharCode(parseInt(e, 16));
					o(i) ? t += i : t += "%" + e, n += 2;
					continue;
				}
			}
			if (c(r)) t += r;
			else {
				let i = e.charCodeAt(n);
				if (i < 128) t += F(i) ? r : u[i];
				else if (i < 55296 || i > 57343) t += d(i);
				else if (i <= 56319 && n + 1 < e.length) {
					let r = e.charCodeAt(n + 1);
					r >= 56320 && r <= 57343 ? (t += d(65536 + (i - 55296 << 10) + (r - 56320)), n++) : t += d(65533);
				} else t += d(65533);
			}
		}
		return t;
	}
	function L(e) {
		let t = "";
		for (let n = 0; n < e.length; n++) {
			if (e[n] === "%" && n + 2 < e.length) {
				let r = e.slice(n + 1, n + 3);
				if (a(r)) {
					t += "%" + r.toUpperCase(), n += 2;
					continue;
				}
			}
			t += escape(e[n]);
		}
		return t;
	}
	function R(e) {
		let t = [];
		if (e.userinfo !== void 0 && (t.push(M(e.userinfo)), t.push("@")), e.host !== void 0) {
			let n = e.host;
			if (!r(n)) {
				let e = b(n);
				e.isIPV6 !== !0 && e.isIPVFuture !== !0 && (n = O(n, !0), e = b(n)), n = e.isIPV6 === !0 || e.isIPVFuture === !0 ? `[${e.escapedHost}]` : D(n, !1);
			}
			t.push(n);
		}
		if (typeof e.port == "number" || typeof e.port == "string") {
			let n = String(e.port);
			if (!i(n)) throw TypeError("URI port is malformed.");
			t.push(":"), t.push(n);
		}
		return t.length ? t.join("") : void 0;
	}
	t.exports = {
		nonSimpleDomain: g,
		recomposeAuthority: R,
		reescapeHostDelimiters: D,
		normalizePercentEncoding: O,
		normalizePathEncoding: k,
		serializePathEncoding: A,
		normalizeQueryFragmentEncoding: I,
		encodeUserinfo: M,
		encodeQuery: N,
		encodeFragment: P,
		escapePreservingEscapes: L,
		removeDotSegments: S,
		removeDotSegmentsRelative: C,
		isIPv4: r,
		isUUID: n,
		normalizeIPv6: b,
		stringArrayToHexStripped: f
	};
})), Y = /* @__PURE__ */ s(((e, t) => {
	var { isUUID: n } = re(), r = /^([\da-z][\d\-a-z]{0,31}):((?:[\w!$'()*+,\-./:;=@]|%[\da-f]{2})+)$/iu, i = [
		"http",
		"https",
		"ws",
		"wss",
		"urn",
		"urn:uuid"
	];
	function a(e) {
		return i.indexOf(e) !== -1;
	}
	function o(e) {
		return e.secure === !0 ? !0 : e.secure === !1 ? !1 : e.scheme ? e.scheme.length === 3 && (e.scheme[0] === "w" || e.scheme[0] === "W") && (e.scheme[1] === "s" || e.scheme[1] === "S") && (e.scheme[2] === "s" || e.scheme[2] === "S") : !1;
	}
	function s(e) {
		return e.host || (e.error = e.error || "HTTP URIs must have a host."), e;
	}
	function c(e) {
		let t = String(e.scheme).toLowerCase() === "https";
		return (e.port === (t ? 443 : 80) || e.port === "") && (e.port = void 0), e.path ||= "/", e;
	}
	function l(e) {
		return e.secure = o(e), e.resourceName = (e.path || "/") + (e.query ? "?" + e.query : ""), e.path = void 0, e.query = void 0, e;
	}
	function u(e) {
		if ((e.port === (o(e) ? 443 : 80) || e.port === "") && (e.port = void 0), typeof e.secure == "boolean" && (e.scheme = e.secure ? "wss" : "ws", e.secure = void 0), e.resourceName) {
			let t = e.resourceName.indexOf("?"), n = t === -1 ? e.resourceName : e.resourceName.slice(0, t);
			e.path = n && n !== "/" ? n : void 0, e.query = t === -1 ? void 0 : e.resourceName.slice(t + 1), e.resourceName = void 0;
		}
		return e.fragment = void 0, e;
	}
	function d(e, t) {
		if (!e.path) return e.error = "URN can not be parsed", e;
		let n = e.path.match(r);
		if (n && n[0] === e.path) {
			let r = t.scheme || e.scheme || "urn";
			e.nid = n[1].toLowerCase(), e.nss = n[2];
			let i = y(`${r}:${t.nid || e.nid}`);
			e.path = void 0, i && (e = i.parse(e, t));
		} else e.error = e.error || "URN can not be parsed.";
		return e;
	}
	function f(e, t) {
		if (e.nid === void 0) throw Error("URN without nid cannot be serialized");
		let n = t.scheme || e.scheme || "urn", r = e.nid.toLowerCase(), i = y(`${n}:${t.nid || r}`);
		i && (e = i.serialize(e, t));
		let a = e, o = e.nss;
		return a.path = `${r || t.nid}:${o}`, t.skipEscape = !0, a;
	}
	function p(e, t) {
		let r = e;
		return r.uuid = r.nss, r.nss = void 0, !t.tolerant && (!r.uuid || !n(r.uuid)) && (r.error = r.error || "UUID is not valid."), r;
	}
	function m(e) {
		let t = e;
		return t.nss = (e.uuid || "").toLowerCase(), t;
	}
	var h = {
		scheme: "http",
		domainHost: !0,
		parse: s,
		serialize: c
	}, g = {
		scheme: "https",
		domainHost: h.domainHost,
		parse: s,
		serialize: c
	}, _ = {
		scheme: "ws",
		domainHost: !0,
		parse: l,
		serialize: u
	}, v = {
		http: h,
		https: g,
		ws: _,
		wss: {
			scheme: "wss",
			domainHost: _.domainHost,
			parse: _.parse,
			serialize: _.serialize
		},
		urn: {
			scheme: "urn",
			parse: d,
			serialize: f,
			skipNormalize: !0
		},
		"urn:uuid": {
			scheme: "urn:uuid",
			parse: p,
			serialize: m,
			skipNormalize: !0
		}
	};
	Object.setPrototypeOf(v, null);
	function y(e) {
		return e && (v[e] || v[e.toLowerCase()]) || void 0;
	}
	t.exports = {
		wsIsSecure: o,
		SCHEMES: v,
		isValidSchemeName: a,
		getSchemeHandler: y
	};
})), X = /* @__PURE__ */ s(((e, t) => {
	var { normalizeIPv6: n, removeDotSegments: r, removeDotSegmentsRelative: i, recomposeAuthority: a, normalizePercentEncoding: o, normalizePathEncoding: s, serializePathEncoding: c, normalizeQueryFragmentEncoding: l, encodeQuery: u, encodeFragment: d, reescapeHostDelimiters: f, isIPv4: p, nonSimpleDomain: m } = re(), { SCHEMES: h, getSchemeHandler: g } = Y(), _ = /^[A-Za-z][A-Za-z0-9+.-]*$/u, v = "URI scheme is malformed.", y = "URI host is malformed.", b = /[\0-\x20"#/:<>?@[\\\]^`{|}\x7F]/u;
	function x(e) {
		let t = String(e);
		if (!_.test(t)) throw TypeError(v);
		return t;
	}
	function S(e, t) {
		return typeof e == "string" ? e = z(e, t) : typeof e == "object" && (e = R(E(e, t), t)), e;
	}
	function C(e, t, r) {
		let i = r ? Object.assign({ scheme: "null" }, r) : { scheme: "null" }, { parsed: a, malformedAuthorityOrPort: o, malformedPercentEncoding: s, malformedSchemeSpecific: c, malformedHost: l, malformedScheme: u } = L(e, i), { parsed: d, malformedAuthorityOrPort: f, malformedPercentEncoding: m, malformedSchemeSpecific: h, malformedHost: _, malformedScheme: v } = L(t, i);
		if (o || f || s || m || c || h || l || _ || u || v) throw Error(a.error || d.error || "URI is malformed.");
		let b = w(a, d, i, !0), x = g(r && r.scheme || b.scheme), S = b.host, C = S !== void 0 && S !== "" && (p(S) || n(S).isIPV6);
		if (F(b, r || {}, x, C)) throw Error(y);
		P(b, r || {}, x, C);
		let T = S && S.indexOf("%") !== -1 && !/\P{ASCII}/u.test(S);
		if (b.error && !T) throw Error(b.error);
		return i.skipEscape = !0, E(b, i);
	}
	function w(e, t, n, a) {
		let o = {};
		if (a || (e = R(E(e, n), n), t = R(E(t, n), n)), n ||= {}, !n.tolerant && t.scheme) o.scheme = t.scheme, o.userinfo = t.userinfo, o.host = t.host, o.port = t.port, o.path = r(t.path || ""), o.query = t.query;
		else {
			if (t.userinfo !== void 0 || t.host !== void 0 || t.port !== void 0) o.userinfo = t.userinfo, o.host = t.host, o.port = t.port, o.path = r(t.path || ""), o.query = t.query;
			else {
				if (!t.path) o.path = e.path, t.query === void 0 ? o.query = e.query : o.query = t.query;
				else {
					if (t.path[0] === "/") o.path = r(t.path);
					else {
						let n = e.userinfo !== void 0 || e.host !== void 0 || e.port !== void 0;
						n && !e.path ? o.path = "/" + t.path : e.path ? o.path = e.path.slice(0, e.path.lastIndexOf("/") + 1) + t.path : o.path = t.path, o.path = e.scheme === void 0 && !n && o.path[0] !== "/" ? i(o.path) : r(o.path);
					}
					o.query = t.query;
				}
				o.userinfo = e.userinfo, o.host = e.host, o.port = e.port;
			}
			o.scheme = e.scheme;
		}
		return o.fragment = t.fragment, o;
	}
	function T(e, t, n) {
		let r = V(e, n), i = V(t, n);
		return r !== void 0 && i !== void 0 && r === i;
	}
	function E(e, t) {
		let n = {
			host: e.host,
			scheme: e.scheme,
			userinfo: e.userinfo,
			port: e.port,
			path: e.path,
			query: e.query,
			nid: e.nid,
			nss: e.nss,
			uuid: e.uuid,
			fragment: e.fragment,
			reference: e.reference,
			resourceName: e.resourceName,
			secure: e.secure,
			error: ""
		}, s = Object.assign({}, t), l = [];
		n.scheme &&= x(n.scheme);
		let f = g(s.scheme || n.scheme);
		f && f.serialize && f.serialize(n, s);
		let p = n.userinfo !== void 0 || n.host !== void 0 || n.port !== void 0, m = (n.scheme === void 0 || s.reference === "suffix") && !p, h = !s.skipEscape && m;
		n.path !== void 0 && (s.skipEscape ? n.path = o(n.path) : n.path = c(n.path, h)), s.reference !== "suffix" && n.scheme && (n.scheme = x(n.scheme), l.push(n.scheme, ":"));
		let _ = a(n);
		if (_ !== void 0 && (s.reference !== "suffix" && l.push("//"), l.push(_), n.path && n.path[0] !== "/" && l.push("/")), n.path !== void 0) {
			let e = n.path;
			!s.absolutePath && (!f || !f.absolutePath) && (e = m && e[0] !== "/" ? i(e) : r(e)), m && (e = c(e, !0)), _ === void 0 && e[0] === "/" && e[1] === "/" && (e = "/%2F" + e.slice(2)), l.push(e);
		}
		return n.query !== void 0 && l.push("?", u(n.query)), n.fragment !== void 0 && l.push("#", d(n.fragment)), l.join("");
	}
	var D = /^(?:([^#/:?]+):)?(?:\/\/((?:([^#/?@]*)@)?(\[[^#/?\]]+\]|[^#/:?]*)(?::(\d*))?))?([^#?]*)(?:\?([^#]*))?(?:#((?:.|[\n\r])*))?/u, O = /^(?:[^#/:?]+:)?\/\/([^/?#]*)/, k = /^(?:[^#/:?]+:)?([/\\\t\n\r]*)/;
	function A(e, t) {
		if (t[2] !== void 0 && e.path && e.path[0] !== "/") return "URI path must start with \"/\" when authority is present.";
		if (typeof e.port == "number" && (e.port < 0 || e.port > 65535)) return "URI port is malformed.";
	}
	function j(e) {
		if (e === void 0) return !1;
		let t = e.indexOf("%");
		for (; t !== -1;) {
			if (t + 2 >= e.length || !/^[\da-f]{2}$/iu.test(e.slice(t + 1, t + 3))) return !0;
			t = e.indexOf("%", t + 3);
		}
		return !1;
	}
	function M(e) {
		return e[0] === "[" && e[e.length - 1] === "]";
	}
	function N(e) {
		let t = e[4];
		return j(e[3]) || t !== void 0 && !M(t) && j(t) || j(e[6]) || j(e[7]) || j(e[8]);
	}
	function P(e, t, n, r) {
		if (F(e, t, n, r)) return e.error = e.error || y, !0;
		if (!t.unicodeSupport && (!n || !n.unicodeSupport) && e.host && !M(e.host) && (t.domainHost || n && n.domainHost) && r === !1 && m(e.host)) {
			let t;
			try {
				t = new URL("http://" + e.host);
			} catch (t) {
				return e.error = e.error || "Host's domain name can not be converted to ASCII: " + t, !0;
			}
			if (!I(t)) return e.error = e.error || y, !0;
			e.host = t.hostname;
		}
		return !1;
	}
	function F(e, t, n, r) {
		return !!(e.host && r === !1 && !M(e.host) && (t.domainHost || n && n.domainHost) && b.test(e.host));
	}
	function I(e) {
		return e.username === "" && e.password === "" && e.port === "" && e.pathname === "/" && e.search === "" && e.hash === "" && e.hostname !== "";
	}
	function L(e, t) {
		let r = Object.assign({}, t), i = {
			scheme: void 0,
			userinfo: void 0,
			host: "",
			port: void 0,
			path: "",
			query: void 0,
			fragment: void 0
		}, a = !1, c = !1, u = !1, d = !1, m = !1, b = !1, x = !1;
		r.reference === "suffix" && (e = r.scheme ? r.scheme + ":" + e : "//" + e);
		let S = e.match(O);
		S !== null && S[1].indexOf("\\") !== -1 && (i.error = "URI authority must not contain a literal backslash.", a = !0);
		let C = e.match(k);
		if (C !== null) {
			let e = C[1], t = e.replace(/[\t\n\r]/g, "");
			t.length >= 2 && (t.slice(0, 2) === "//" ? e.length !== t.length && (i.error = i.error || "URI authority introducer must not contain whitespace.", a = !0) : (i.error = i.error || "URI authority must not contain a literal backslash.", a = !0));
		}
		let w = e.match(D);
		if (w) {
			i.scheme = w[1], i.userinfo = w[3], i.host = w[4], i.port = parseInt(w[5], 10), i.path = w[6] || "", i.query = w[7], i.fragment = w[8], i.scheme !== void 0 && (_.test(i.scheme) ? i.scheme = i.scheme.toLowerCase() : (i.error = i.error || v, b = !0)), c = N(w), c && (i.error = i.error || "URI contains malformed percent-encoding."), isNaN(i.port) && (i.port = w[5]);
			let t = A(i, w);
			if (t !== void 0 && (i.error = i.error || t, a = !0), i.host) if (p(i.host) === !1) {
				let e = M(i.host), t = i.host.indexOf("[") !== -1 || i.host.indexOf("]") !== -1, r = n(i.host);
				x = r.isIPV6 || r.isIPVFuture === !0, m = t && (!e || r.error === !0), i.host = x ? r.host : r.host.toLowerCase(), m && (i.error = i.error || y, a = !0);
			} else x = !0;
			i.scheme === void 0 && i.userinfo === void 0 && i.host === void 0 && i.port === void 0 && i.query === void 0 && !i.path ? i.reference = "same-document" : i.scheme === void 0 ? i.reference = "relative" : i.fragment === void 0 ? i.reference = "absolute" : i.reference = "uri", r.reference && r.reference !== "suffix" && r.reference !== i.reference && (i.error = i.error || "URI is not a " + r.reference + " reference.");
			let S = g(r.scheme || i.scheme);
			if (m || (d = P(i, r, S, x)), e.indexOf("%") !== -1 && i.host !== void 0 && !m) {
				let e = x ? i.host : o(i.host, !0);
				x || (e = o(e.toLowerCase())), i.host = x || r.scheme !== "null" ? f(e, x) : e;
			}
			(!S || S && !S.skipNormalize) && (i.path &&= s(i.path), i.query &&= l(i.query), i.fragment &&= l(i.fragment)), S && S.parse && (S.parse(i, r), S === h.urn && i.nid === void 0 && (u = !0));
		} else i.error = i.error || "URI can not be parsed.";
		return {
			parsed: i,
			malformedAuthorityOrPort: a,
			malformedPercentEncoding: c,
			malformedSchemeSpecific: u,
			malformedHost: d,
			malformedScheme: b
		};
	}
	function R(e, t) {
		return L(e, t).parsed;
	}
	function z(e, t) {
		return B(e, t).normalized;
	}
	function B(e, t) {
		let { parsed: n, malformedAuthorityOrPort: r, malformedPercentEncoding: i, malformedSchemeSpecific: a, malformedHost: o, malformedScheme: s } = L(e, t);
		return {
			normalized: r || i || a || o || s ? e : E(n, t),
			malformedAuthorityOrPort: r,
			malformedPercentEncoding: i,
			malformedSchemeSpecific: a,
			malformedHost: o,
			malformedScheme: s
		};
	}
	function V(e, t) {
		if (typeof e != "string" && typeof e != "object") return;
		let n;
		try {
			n = typeof e == "string" ? e : E(e, t);
		} catch {
			return;
		}
		let { normalized: r, malformedAuthorityOrPort: i, malformedPercentEncoding: a, malformedSchemeSpecific: o, malformedHost: s, malformedScheme: c } = B(n, t);
		return i || a || o || s || c ? void 0 : r;
	}
	var H = {
		SCHEMES: h,
		normalize: S,
		resolve: C,
		resolveComponent: w,
		equal: T,
		serialize: E,
		parse: R
	};
	t.exports = H, t.exports.default = H, t.exports.fastUri = H;
})), ie = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = X();
	t.code = "require(\"ajv/dist/runtime/uri\").default", e.default = t;
})), ae = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.CodeGen = e.Name = e.nil = e.stringify = e.str = e._ = e.KeywordCxt = void 0;
	var t = B();
	Object.defineProperty(e, "KeywordCxt", {
		enumerable: !0,
		get: function() {
			return t.KeywordCxt;
		}
	});
	var n = T();
	Object.defineProperty(e, "_", {
		enumerable: !0,
		get: function() {
			return n._;
		}
	}), Object.defineProperty(e, "str", {
		enumerable: !0,
		get: function() {
			return n.str;
		}
	}), Object.defineProperty(e, "stringify", {
		enumerable: !0,
		get: function() {
			return n.stringify;
		}
	}), Object.defineProperty(e, "nil", {
		enumerable: !0,
		get: function() {
			return n.nil;
		}
	}), Object.defineProperty(e, "Name", {
		enumerable: !0,
		get: function() {
			return n.Name;
		}
	}), Object.defineProperty(e, "CodeGen", {
		enumerable: !0,
		get: function() {
			return n.CodeGen;
		}
	});
	var r = V(), i = H(), a = A(), o = U(), s = T(), c = z(), l = M(), u = E(), f = (ne(), d(ee).default), p = ie(), m = (e, t) => new RegExp(e, t);
	m.code = "new RegExp";
	var h = [
		"removeAdditional",
		"useDefaults",
		"coerceTypes"
	], g = /* @__PURE__ */ new Set([
		"validate",
		"serialize",
		"parse",
		"wrapper",
		"root",
		"schema",
		"keyword",
		"pattern",
		"formats",
		"validate$data",
		"func",
		"obj",
		"Error"
	]), _ = {
		errorDataPath: "",
		format: "`validateFormats: false` can be used instead.",
		nullable: "\"nullable\" keyword is supported by default.",
		jsonPointers: "Deprecated jsPropertySyntax can be used instead.",
		extendRefs: "Deprecated ignoreKeywordsWithRef can be used instead.",
		missingRefs: "Pass empty schema with $id that should be ignored to ajv.addSchema.",
		processCode: "Use option `code: {process: (code, schemaEnv: object) => string}`",
		sourceCode: "Use option `code: {source: true}`",
		strictDefaults: "It is default now, see option `strict`.",
		strictKeywords: "It is default now, see option `strict`.",
		uniqueItems: "\"uniqueItems\" keyword is always validated.",
		unknownFormats: "Disable strict mode or pass `true` to `ajv.addFormat` (or `formats` option).",
		cache: "Map is used as cache, schema object as key.",
		serialize: "Map is used as cache, schema object as key.",
		ajvErrors: "It is default now."
	}, v = {
		ignoreKeywordsWithRef: "",
		jsPropertySyntax: "",
		unicode: "\"minLength\"/\"maxLength\" account for unicode characters by default."
	}, y = 200;
	function b(e) {
		let t = e.strict, n = e.code?.optimize, r = n === !0 || n === void 0 ? 1 : n || 0, i = e.code?.regExp ?? m, a = e.uriResolver ?? p.default;
		return {
			strictSchema: e.strictSchema ?? t ?? !0,
			strictNumbers: e.strictNumbers ?? t ?? !0,
			strictTypes: e.strictTypes ?? t ?? "log",
			strictTuples: e.strictTuples ?? t ?? "log",
			strictRequired: e.strictRequired ?? t ?? !1,
			code: e.code ? {
				...e.code,
				optimize: r,
				regExp: i
			} : {
				optimize: r,
				regExp: i
			},
			loopRequired: e.loopRequired ?? y,
			loopEnum: e.loopEnum ?? y,
			meta: e.meta ?? !0,
			messages: e.messages ?? !0,
			inlineRefs: e.inlineRefs ?? !0,
			schemaId: e.schemaId ?? "$id",
			addUsedSchema: e.addUsedSchema ?? !0,
			validateSchema: e.validateSchema ?? !0,
			validateFormats: e.validateFormats ?? !0,
			unicodeRegExp: e.unicodeRegExp ?? !0,
			int32range: e.int32range ?? !0,
			uriResolver: a
		};
	}
	var x = class {
		constructor(e = {}) {
			this.schemas = {}, this.refs = {}, this.formats = Object.create(null), this._compilations = /* @__PURE__ */ new Set(), this._loading = {}, this._cache = /* @__PURE__ */ new Map(), e = this.opts = {
				...e,
				...b(e)
			};
			let { es5: t, lines: n } = this.opts.code;
			this.scope = new s.ValueScope({
				scope: {},
				prefixes: g,
				es5: t,
				lines: n
			}), this.logger = N(e.logger);
			let r = e.validateFormats;
			e.validateFormats = !1, this.RULES = (0, a.getRules)(), S.call(this, _, e, "NOT SUPPORTED"), S.call(this, v, e, "DEPRECATED", "warn"), this._metaOpts = k.call(this), e.formats && D.call(this), this._addVocabularies(), this._addDefaultMetaSchema(), e.keywords && O.call(this, e.keywords), typeof e.meta == "object" && this.addMetaSchema(e.meta), w.call(this), e.validateFormats = r;
		}
		_addVocabularies() {
			this.addKeyword("$async");
		}
		_addDefaultMetaSchema() {
			let { $data: e, meta: t, schemaId: n } = this.opts, r = f;
			n === "id" && (r = { ...f }, r.id = r.$id, delete r.$id), t && e && this.addMetaSchema(r, r[n], !1);
		}
		defaultMeta() {
			let { meta: e, schemaId: t } = this.opts;
			return this.opts.defaultMeta = typeof e == "object" ? e[t] || e : void 0;
		}
		validate(e, t) {
			let n;
			if (typeof e == "string") {
				if (n = this.getSchema(e), !n) throw Error(`no schema with key or ref "${e}"`);
			} else n = this.compile(e);
			let r = n(t);
			return "$async" in n || (this.errors = n.errors), r;
		}
		compile(e, t) {
			let n = this._addSchema(e, t);
			return n.validate || this._compileSchemaEnv(n);
		}
		compileAsync(e, t) {
			if (typeof this.opts.loadSchema != "function") throw Error("options.loadSchema should be a function");
			let { loadSchema: n } = this.opts;
			return r.call(this, e, t);
			async function r(e, t) {
				await a.call(this, e.$schema);
				let n = this._addSchema(e, t);
				return n.validate || o.call(this, n);
			}
			async function a(e) {
				e && !this.getSchema(e) && await r.call(this, { $ref: e }, !0);
			}
			async function o(e) {
				try {
					return this._compileSchemaEnv(e);
				} catch (t) {
					if (!(t instanceof i.default)) throw t;
					return s.call(this, t), await c.call(this, t.missingSchema), o.call(this, e);
				}
			}
			function s({ missingSchema: e, missingRef: t }) {
				if (this.refs[e]) throw Error(`AnySchema ${e} is loaded but ${t} cannot be resolved`);
			}
			async function c(e) {
				let n = await l.call(this, e);
				this.refs[e] || await a.call(this, n.$schema), this.refs[e] || this.addSchema(n, e, t);
			}
			async function l(e) {
				let t = this._loading[e];
				if (t) return t;
				try {
					return await (this._loading[e] = n(e));
				} finally {
					delete this._loading[e];
				}
			}
		}
		addSchema(e, t, n, r = this.opts.validateSchema) {
			if (Array.isArray(e)) {
				for (let t of e) this.addSchema(t, void 0, n, r);
				return this;
			}
			let i;
			if (typeof e == "object") {
				let { schemaId: t } = this.opts;
				if (i = e[t], i !== void 0 && typeof i != "string") throw Error(`schema ${t} must be string`);
			}
			return t = (0, c.normalizeId)(t || i), this._checkUnique(t), this.schemas[t] = this._addSchema(e, n, t, r, !0), this;
		}
		addMetaSchema(e, t, n = this.opts.validateSchema) {
			return this.addSchema(e, t, !0, n), this;
		}
		validateSchema(e, t) {
			if (typeof e == "boolean") return !0;
			let n;
			if (n = e.$schema, n !== void 0 && typeof n != "string") throw Error("$schema must be a string");
			if (n = n || this.opts.defaultMeta || this.defaultMeta(), !n) return this.logger.warn("meta-schema not available"), this.errors = null, !0;
			let r = this.validate(n, e);
			if (!r && t) {
				let e = "schema is invalid: " + this.errorsText();
				if (this.opts.validateSchema === "log") this.logger.error(e);
				else throw Error(e);
			}
			return r;
		}
		getSchema(e) {
			let t;
			for (; typeof (t = C.call(this, e)) == "string";) e = t;
			if (t === void 0) {
				let { schemaId: n } = this.opts, r = new o.SchemaEnv({
					schema: {},
					schemaId: n
				});
				if (t = o.resolveSchema.call(this, r, e), !t) return;
				this.refs[e] = t;
			}
			return t.validate || this._compileSchemaEnv(t);
		}
		removeSchema(e) {
			if (e instanceof RegExp) return this._removeAllSchemas(this.schemas, e), this._removeAllSchemas(this.refs, e), this;
			switch (typeof e) {
				case "undefined": return this._removeAllSchemas(this.schemas), this._removeAllSchemas(this.refs), this._cache.clear(), this;
				case "string": {
					let t = C.call(this, e);
					return typeof t == "object" && this._cache.delete(t.schema), delete this.schemas[e], delete this.refs[e], this;
				}
				case "object": {
					let t = e;
					this._cache.delete(t);
					let n = e[this.opts.schemaId];
					return n && (n = (0, c.normalizeId)(n), delete this.schemas[n], delete this.refs[n]), this;
				}
				default: throw Error("ajv.removeSchema: invalid parameter");
			}
		}
		addVocabulary(e) {
			for (let t of e) this.addKeyword(t);
			return this;
		}
		addKeyword(e, t) {
			let n;
			if (typeof e == "string") n = e, typeof t == "object" && (this.logger.warn("these parameters are deprecated, see docs for addKeyword"), t.keyword = n);
			else if (typeof e == "object" && t === void 0) {
				if (t = e, n = t.keyword, Array.isArray(n) && !n.length) throw Error("addKeywords: keyword must be string or non-empty array");
			} else throw Error("invalid addKeywords parameters");
			if (F.call(this, n, t), !t) return (0, u.eachItem)(n, (e) => I.call(this, e)), this;
			R.call(this, t);
			let r = {
				...t,
				type: (0, l.getJSONTypes)(t.type),
				schemaType: (0, l.getJSONTypes)(t.schemaType)
			};
			return (0, u.eachItem)(n, r.type.length === 0 ? (e) => I.call(this, e, r) : (e) => r.type.forEach((t) => I.call(this, e, r, t))), this;
		}
		getKeyword(e) {
			let t = this.RULES.all[e];
			return typeof t == "object" ? t.definition : !!t;
		}
		removeKeyword(e) {
			let { RULES: t } = this;
			delete t.keywords[e], delete t.all[e];
			for (let n of t.rules) {
				let t = n.rules.findIndex((t) => t.keyword === e);
				t >= 0 && n.rules.splice(t, 1);
			}
			return this;
		}
		addFormat(e, t) {
			return typeof t == "string" && (t = new RegExp(t)), this.formats[e] = t, this;
		}
		errorsText(e = this.errors, { separator: t = ", ", dataVar: n = "data" } = {}) {
			return !e || e.length === 0 ? "No errors" : e.map((e) => `${n}${e.instancePath} ${e.message}`).reduce((e, n) => e + t + n);
		}
		$dataMetaSchema(e, t) {
			let n = this.RULES.all;
			e = JSON.parse(JSON.stringify(e));
			for (let r of t) {
				let t = r.split("/").slice(1), i = e;
				for (let e of t) i = i[e];
				for (let e in n) {
					let t = n[e];
					if (typeof t != "object") continue;
					let { $data: r } = t.definition, a = i[e];
					r && a && (i[e] = G(a));
				}
			}
			return e;
		}
		_removeAllSchemas(e, t) {
			for (let n in e) {
				let r = e[n];
				(!t || t.test(n)) && (typeof r == "string" ? delete e[n] : r && !r.meta && (this._cache.delete(r.schema), delete e[n]));
			}
		}
		_addSchema(e, t, n, r = this.opts.validateSchema, i = this.opts.addUsedSchema) {
			let a, { schemaId: s } = this.opts;
			if (typeof e == "object") a = e[s];
			else if (this.opts.jtd) throw Error("schema must be object");
			else if (typeof e != "boolean") throw Error("schema must be object or boolean");
			let l = this._cache.get(e);
			if (l !== void 0) return l;
			n = (0, c.normalizeId)(a || n);
			let u = c.getSchemaRefs.call(this, e, n);
			return l = new o.SchemaEnv({
				schema: e,
				schemaId: s,
				meta: t,
				baseId: n,
				localRefs: u
			}), this._cache.set(l.schema, l), i && !n.startsWith("#") && (n && this._checkUnique(n), this.refs[n] = l), r && this.validateSchema(e, !0), l;
		}
		_checkUnique(e) {
			if (this.schemas[e] || this.refs[e]) throw Error(`schema with key or id "${e}" already exists`);
		}
		_compileSchemaEnv(e) {
			/* istanbul ignore if */
			if (e.meta ? this._compileMetaSchema(e) : o.compileSchema.call(this, e), !e.validate) throw Error("ajv implementation error");
			return e.validate;
		}
		_compileMetaSchema(e) {
			let t = this.opts;
			this.opts = this._metaOpts;
			try {
				o.compileSchema.call(this, e);
			} finally {
				this.opts = t;
			}
		}
	};
	x.ValidationError = r.default, x.MissingRefError = i.default, e.default = x;
	function S(e, t, n, r = "error") {
		for (let i in e) {
			let a = i;
			a in t && this.logger[r](`${n}: option ${i}. ${e[a]}`);
		}
	}
	function C(e) {
		return e = (0, c.normalizeId)(e), this.schemas[e] || this.refs[e];
	}
	function w() {
		let e = this.opts.schemas;
		if (e) if (Array.isArray(e)) this.addSchema(e);
		else for (let t in e) this.addSchema(e[t], t);
	}
	function D() {
		for (let e in this.opts.formats) {
			let t = this.opts.formats[e];
			t && this.addFormat(e, t);
		}
	}
	function O(e) {
		if (Array.isArray(e)) {
			this.addVocabulary(e);
			return;
		}
		this.logger.warn("keywords option as map is deprecated, pass array");
		for (let t in e) {
			let n = e[t];
			n.keyword ||= t, this.addKeyword(n);
		}
	}
	function k() {
		let e = { ...this.opts };
		for (let t of h) delete e[t];
		return e;
	}
	var j = {
		log() {},
		warn() {},
		error() {}
	};
	function N(e) {
		if (e === !1) return j;
		if (e === void 0) return console;
		if (e.log && e.warn && e.error) return e;
		throw Error("logger must implement log, warn and error methods");
	}
	var P = /^[a-z_$][a-z0-9_$:-]*$/i;
	function F(e, t) {
		let { RULES: n } = this;
		if ((0, u.eachItem)(e, (e) => {
			if (n.keywords[e]) throw Error(`Keyword ${e} is already defined`);
			if (!P.test(e)) throw Error(`Keyword ${e} has invalid name`);
		}), t && t.$data && !("code" in t || "validate" in t)) throw Error("$data keyword must have \"code\" or \"validate\" function");
	}
	function I(e, t, n) {
		var r;
		let i = t?.post;
		if (n && i) throw Error("keyword with \"post\" flag cannot have \"type\"");
		let { RULES: a } = this, o = i ? a.post : a.rules.find(({ type: e }) => e === n);
		if (o || (o = {
			type: n,
			rules: []
		}, a.rules.push(o)), a.keywords[e] = !0, !t) return;
		let s = {
			keyword: e,
			definition: {
				...t,
				type: (0, l.getJSONTypes)(t.type),
				schemaType: (0, l.getJSONTypes)(t.schemaType)
			}
		};
		t.before ? L.call(this, o, s, t.before) : o.rules.push(s), a.all[e] = s, (r = t.implements) == null || r.forEach((e) => this.addKeyword(e));
	}
	function L(e, t, n) {
		let r = e.rules.findIndex((e) => e.keyword === n);
		r >= 0 ? e.rules.splice(r, 0, t) : (e.rules.push(t), this.logger.warn(`rule ${n} is not defined`));
	}
	function R(e) {
		let { metaSchema: t } = e;
		t !== void 0 && (e.$data && this.opts.$data && (t = G(t)), e.validateSchema = this.compile(t, !0));
	}
	var W = { $ref: "https://raw.githubusercontent.com/ajv-validator/ajv/master/lib/refs/data.json#" };
	function G(e) {
		return { anyOf: [e, W] };
	}
})), oe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.default = {
		keyword: "id",
		code() {
			throw Error("NOT SUPPORTED: keyword \"id\", use \"$id\" for schema ID");
		}
	};
})), Z = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.callRef = e.getValidate = void 0;
	var t = H(), n = P(), r = T(), i = D(), a = U(), o = E(), s = {
		keyword: "$ref",
		schemaType: "string",
		code(e) {
			let { gen: n, schema: i, it: o } = e, { baseId: s, schemaEnv: u, validateName: d, opts: f, self: p } = o, { root: m } = u;
			if ((i === "#" || i === "#/") && s === m.baseId) return g();
			let h = a.resolveRef.call(p, m, s, i);
			if (h === void 0) throw new t.default(o.opts.uriResolver, s, i);
			if (h instanceof a.SchemaEnv) return _(h);
			return v(h);
			function g() {
				if (u === m) return l(e, d, u, u.$async);
				let t = n.scopeValue("root", { ref: m });
				return l(e, (0, r._)`${t}.validate`, m, m.$async);
			}
			function _(t) {
				l(e, c(e, t), t, t.$async);
			}
			function v(t) {
				let a = n.scopeValue("schema", f.code.source === !0 ? {
					ref: t,
					code: (0, r.stringify)(t)
				} : { ref: t }), o = n.name("valid"), s = e.subschema({
					schema: t,
					dataTypes: [],
					schemaPath: r.nil,
					topSchemaRef: a,
					errSchemaPath: i
				}, o);
				e.mergeEvaluated(s), e.ok(o);
			}
		}
	};
	function c(e, t) {
		let { gen: n } = e;
		return t.validate ? n.scopeValue("validate", { ref: t.validate }) : (0, r._)`${n.scopeValue("wrapper", { ref: t })}.validate`;
	}
	e.getValidate = c;
	function l(e, t, a, s) {
		let { gen: c, it: l } = e, { allErrors: u, schemaEnv: d, opts: f } = l, p = f.passContext ? i.default.this : r.nil;
		s ? m() : h();
		function m() {
			if (!d.$async) throw Error("async schema referenced by sync schema");
			let i = c.let("valid");
			c.try(() => {
				c.code((0, r._)`await ${(0, n.callValidateCode)(e, t, p)}`), _(t), u || c.assign(i, !0);
			}, (e) => {
				c.if((0, r._)`!(${e} instanceof ${l.ValidationError})`, () => c.throw(e)), g(e), u || c.assign(i, !1);
			}), e.ok(i);
		}
		function h() {
			e.result((0, n.callValidateCode)(e, t, p), () => _(t), () => g(t));
		}
		function g(e) {
			let t = (0, r._)`${e}.errors`;
			c.assign(i.default.vErrors, (0, r._)`${i.default.vErrors} === null ? ${t} : ${i.default.vErrors}.concat(${t})`), c.assign(i.default.errors, (0, r._)`${i.default.vErrors}.length`);
		}
		function _(e) {
			if (!l.opts.unevaluated) return;
			let t = a?.validate?.evaluated;
			if (l.props !== !0) if (t && !t.dynamicProps) t.props !== void 0 && (l.props = o.mergeEvaluated.props(c, t.props, l.props));
			else {
				let t = c.var("props", (0, r._)`${e}.evaluated.props`);
				l.props = o.mergeEvaluated.props(c, t, l.props, r.Name);
			}
			if (l.items !== !0) if (t && !t.dynamicItems) t.items !== void 0 && (l.items = o.mergeEvaluated.items(c, t.items, l.items));
			else {
				let t = c.var("items", (0, r._)`${e}.evaluated.items`);
				l.items = o.mergeEvaluated.items(c, t, l.items, r.Name);
			}
		}
	}
	e.callRef = l, e.default = s;
})), se = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = oe(), n = Z();
	e.default = [
		"$schema",
		"$id",
		"$defs",
		"$vocabulary",
		{ keyword: "$comment" },
		"definitions",
		t.default,
		n.default
	];
})), ce = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = t.operators, r = {
		maximum: {
			okStr: "<=",
			ok: n.LTE,
			fail: n.GT
		},
		minimum: {
			okStr: ">=",
			ok: n.GTE,
			fail: n.LT
		},
		exclusiveMaximum: {
			okStr: "<",
			ok: n.LT,
			fail: n.GTE
		},
		exclusiveMinimum: {
			okStr: ">",
			ok: n.GT,
			fail: n.LTE
		}
	};
	e.default = {
		keyword: Object.keys(r),
		type: "number",
		schemaType: "number",
		$data: !0,
		error: {
			message: ({ keyword: e, schemaCode: n }) => (0, t.str)`must be ${r[e].okStr} ${n}`,
			params: ({ keyword: e, schemaCode: n }) => (0, t._)`{comparison: ${r[e].okStr}, limit: ${n}}`
		},
		code(e) {
			let { keyword: n, data: i, schemaCode: a } = e;
			e.fail$data((0, t._)`${i} ${r[n].fail} ${a} || isNaN(${i})`);
		}
	};
})), le = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T();
	e.default = {
		keyword: "multipleOf",
		type: "number",
		schemaType: "number",
		$data: !0,
		error: {
			message: ({ schemaCode: e }) => (0, t.str)`must be multiple of ${e}`,
			params: ({ schemaCode: e }) => (0, t._)`{multipleOf: ${e}}`
		},
		code(e) {
			let { gen: n, data: r, schemaCode: i, it: a } = e, o = a.opts.multipleOfPrecision, s = n.let("res"), c = o ? (0, t._)`Math.abs(Math.round(${s}) - ${s}) > 1e-${o}` : (0, t._)`${s} !== parseInt(${s})`;
			e.fail$data((0, t._)`(${i} === 0 || (${s} = ${r}/${i}, ${c}))`);
		}
	};
})), ue = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	function t(e) {
		let t = e.length, n = 0, r = 0, i;
		for (; r < t;) n++, i = e.charCodeAt(r++), i >= 55296 && i <= 56319 && r < t && (i = e.charCodeAt(r), (i & 64512) == 56320 && r++);
		return n;
	}
	e.default = t, t.code = "require(\"ajv/dist/runtime/ucs2length\").default";
})), de = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E(), r = ue();
	e.default = {
		keyword: ["maxLength", "minLength"],
		type: "string",
		schemaType: "number",
		$data: !0,
		error: {
			message({ keyword: e, schemaCode: n }) {
				let r = e === "maxLength" ? "more" : "fewer";
				return (0, t.str)`must NOT have ${r} than ${n} characters`;
			},
			params: ({ schemaCode: e }) => (0, t._)`{limit: ${e}}`
		},
		code(e) {
			let { keyword: i, data: a, schemaCode: o, it: s } = e, c = i === "maxLength" ? t.operators.GT : t.operators.LT, l = s.opts.unicode === !1 ? (0, t._)`${a}.length` : (0, t._)`${(0, n.useFunc)(e.gen, r.default)}(${a})`;
			e.fail$data((0, t._)`${l} ${c} ${o}`);
		}
	};
})), fe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = P(), n = E(), r = T();
	e.default = {
		keyword: "pattern",
		type: "string",
		schemaType: "string",
		$data: !0,
		error: {
			message: ({ schemaCode: e }) => (0, r.str)`must match pattern "${e}"`,
			params: ({ schemaCode: e }) => (0, r._)`{pattern: ${e}}`
		},
		code(e) {
			let { gen: i, data: a, $data: o, schema: s, schemaCode: c, it: l } = e, u = l.opts.unicodeRegExp ? "u" : "";
			if (o) {
				let { regExp: t } = l.opts.code, o = t.code === "new RegExp" ? (0, r._)`new RegExp` : (0, n.useFunc)(i, t), s = i.let("valid");
				i.try(() => i.assign(s, (0, r._)`${o}(${c}, ${u}).test(${a})`), () => i.assign(s, !1)), e.fail$data((0, r._)`!${s}`);
			} else {
				let n = (0, t.usePattern)(e, s);
				e.fail$data((0, r._)`!${n}.test(${a})`);
			}
		}
	};
})), pe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T();
	e.default = {
		keyword: ["maxProperties", "minProperties"],
		type: "object",
		schemaType: "number",
		$data: !0,
		error: {
			message({ keyword: e, schemaCode: n }) {
				let r = e === "maxProperties" ? "more" : "fewer";
				return (0, t.str)`must NOT have ${r} than ${n} properties`;
			},
			params: ({ schemaCode: e }) => (0, t._)`{limit: ${e}}`
		},
		code(e) {
			let { keyword: n, data: r, schemaCode: i } = e, a = n === "maxProperties" ? t.operators.GT : t.operators.LT;
			e.fail$data((0, t._)`Object.keys(${r}).length ${a} ${i}`);
		}
	};
})), me = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = P(), n = T(), r = E();
	e.default = {
		keyword: "required",
		type: "object",
		schemaType: "array",
		$data: !0,
		error: {
			message: ({ params: { missingProperty: e } }) => (0, n.str)`must have required property '${e}'`,
			params: ({ params: { missingProperty: e } }) => (0, n._)`{missingProperty: ${e}}`
		},
		code(e) {
			let { gen: i, schema: a, schemaCode: o, data: s, $data: c, it: l } = e, { opts: u } = l;
			if (!c && a.length === 0) return;
			let d = a.length >= u.loopRequired;
			if (l.allErrors ? f() : p(), u.strictRequired) {
				let t = e.parentSchema.properties, { definedProperties: n } = e.it;
				for (let e of a) if (t?.[e] === void 0 && !n.has(e)) {
					let t = `required property "${e}" is not defined at "${l.schemaEnv.baseId + l.errSchemaPath}" (strictRequired)`;
					(0, r.checkStrictMode)(l, t, l.opts.strictRequired);
				}
			}
			function f() {
				if (d || c) e.block$data(n.nil, m);
				else for (let n of a) (0, t.checkReportMissingProp)(e, n);
			}
			function p() {
				let n = i.let("missing");
				if (d || c) {
					let t = i.let("valid", !0);
					e.block$data(t, () => h(n, t)), e.ok(t);
				} else i.if((0, t.checkMissingProp)(e, a, n)), (0, t.reportMissingProp)(e, n), i.else();
			}
			function m() {
				i.forOf("prop", o, (n) => {
					e.setParams({ missingProperty: n }), i.if((0, t.noPropertyInData)(i, s, n, u.ownProperties), () => e.error());
				});
			}
			function h(r, a) {
				e.setParams({ missingProperty: r }), i.forOf(r, o, () => {
					i.assign(a, (0, t.propertyInData)(i, s, r, u.ownProperties)), i.if((0, n.not)(a), () => {
						e.error(), i.break();
					});
				}, n.nil);
			}
		}
	};
})), he = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T();
	e.default = {
		keyword: ["maxItems", "minItems"],
		type: "array",
		schemaType: "number",
		$data: !0,
		error: {
			message({ keyword: e, schemaCode: n }) {
				let r = e === "maxItems" ? "more" : "fewer";
				return (0, t.str)`must NOT have ${r} than ${n} items`;
			},
			params: ({ schemaCode: e }) => (0, t._)`{limit: ${e}}`
		},
		code(e) {
			let { keyword: n, data: r, schemaCode: i } = e, a = n === "maxItems" ? t.operators.GT : t.operators.LT;
			e.fail$data((0, t._)`${r}.length ${a} ${i}`);
		}
	};
})), ge = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = L();
	t.code = "require(\"ajv/dist/runtime/equal\").default", e.default = t;
})), _e = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = M(), n = T(), r = E(), i = ge();
	e.default = {
		keyword: "uniqueItems",
		type: "array",
		schemaType: "boolean",
		$data: !0,
		error: {
			message: ({ params: { i: e, j: t } }) => (0, n.str)`must NOT have duplicate items (items ## ${t} and ${e} are identical)`,
			params: ({ params: { i: e, j: t } }) => (0, n._)`{i: ${e}, j: ${t}}`
		},
		code(e) {
			let { gen: a, data: o, $data: s, schema: c, parentSchema: l, schemaCode: u, it: d } = e;
			if (!s && !c) return;
			let f = a.let("valid"), p = l.items ? (0, t.getSchemaTypes)(l.items) : [];
			e.block$data(f, m, (0, n._)`${u} === false`), e.ok(f);
			function m() {
				let t = a.let("i", (0, n._)`${o}.length`), r = a.let("j");
				e.setParams({
					i: t,
					j: r
				}), a.assign(f, !0), a.if((0, n._)`${t} > 1`, () => (h() ? g : _)(t, r));
			}
			function h() {
				return p.length > 0 && !p.some((e) => e === "object" || e === "array");
			}
			function g(r, i) {
				let s = a.name("item"), c = (0, t.checkDataTypes)(p, s, d.opts.strictNumbers, t.DataType.Wrong), l = a.const("indices", (0, n._)`{}`);
				a.for((0, n._)`;${r}--;`, () => {
					a.let(s, (0, n._)`${o}[${r}]`), a.if(c, (0, n._)`continue`), p.length > 1 && a.if((0, n._)`typeof ${s} == "string"`, (0, n._)`${s} += "_"`), a.if((0, n._)`typeof ${l}[${s}] == "number"`, () => {
						a.assign(i, (0, n._)`${l}[${s}]`), e.error(), a.assign(f, !1).break();
					}).code((0, n._)`${l}[${s}] = ${r}`);
				});
			}
			function _(t, s) {
				let c = (0, r.useFunc)(a, i.default), l = a.name("outer");
				a.label(l).for((0, n._)`;${t}--;`, () => a.for((0, n._)`${s} = ${t}; ${s}--;`, () => a.if((0, n._)`${c}(${o}[${t}], ${o}[${s}])`, () => {
					e.error(), a.assign(f, !1).break(l);
				})));
			}
		}
	};
})), ve = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E(), r = ge();
	e.default = {
		keyword: "const",
		$data: !0,
		error: {
			message: "must be equal to constant",
			params: ({ schemaCode: e }) => (0, t._)`{allowedValue: ${e}}`
		},
		code(e) {
			let { gen: i, data: a, $data: o, schemaCode: s, schema: c } = e;
			o || c && typeof c == "object" ? e.fail$data((0, t._)`!${(0, n.useFunc)(i, r.default)}(${a}, ${s})`) : e.fail((0, t._)`${c} !== ${a}`);
		}
	};
})), ye = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E(), r = ge();
	e.default = {
		keyword: "enum",
		schemaType: "array",
		$data: !0,
		error: {
			message: "must be equal to one of the allowed values",
			params: ({ schemaCode: e }) => (0, t._)`{allowedValues: ${e}}`
		},
		code(e) {
			let { gen: i, data: a, $data: o, schema: s, schemaCode: c, it: l } = e;
			if (!o && s.length === 0) throw Error("enum must have non-empty array");
			let u = s.length >= l.opts.loopEnum, d, f = () => d ??= (0, n.useFunc)(i, r.default), p;
			if (u || o) p = i.let("valid"), e.block$data(p, m);
			else {
				/* istanbul ignore if */
				if (!Array.isArray(s)) throw Error("ajv implementation error");
				let e = i.const("vSchema", c);
				p = (0, t.or)(...s.map((t, n) => h(e, n)));
			}
			e.pass(p);
			function m() {
				i.assign(p, !1), i.forOf("v", c, (e) => i.if((0, t._)`${f()}(${a}, ${e})`, () => i.assign(p, !0).break()));
			}
			function h(e, n) {
				let r = s[n];
				return typeof r == "object" && r ? (0, t._)`${f()}(${a}, ${e}[${n}])` : (0, t._)`${a} === ${r}`;
			}
		}
	};
})), be = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = ce(), n = le(), r = de(), i = fe(), a = pe(), o = me(), s = he(), c = _e(), l = ve(), u = ye();
	e.default = [
		t.default,
		n.default,
		r.default,
		i.default,
		a.default,
		o.default,
		s.default,
		c.default,
		{
			keyword: "type",
			schemaType: ["string", "array"]
		},
		{
			keyword: "nullable",
			schemaType: "boolean"
		},
		l.default,
		u.default
	];
})), xe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.validateAdditionalItems = void 0;
	var t = T(), n = E(), r = {
		keyword: "additionalItems",
		type: "array",
		schemaType: ["boolean", "object"],
		before: "uniqueItems",
		error: {
			message: ({ params: { len: e } }) => (0, t.str)`must NOT have more than ${e} items`,
			params: ({ params: { len: e } }) => (0, t._)`{limit: ${e}}`
		},
		code(e) {
			let { parentSchema: t, it: r } = e, { items: a } = t;
			if (!Array.isArray(a)) {
				(0, n.checkStrictMode)(r, "\"additionalItems\" is ignored when \"items\" is not an array of schemas");
				return;
			}
			i(e, a);
		}
	};
	function i(e, r) {
		let { gen: i, schema: a, data: o, keyword: s, it: c } = e;
		c.items = !0;
		let l = i.const("len", (0, t._)`${o}.length`);
		if (a === !1) e.setParams({ len: r.length }), e.pass((0, t._)`${l} <= ${r.length}`);
		else if (typeof a == "object" && !(0, n.alwaysValidSchema)(c, a)) {
			let n = i.var("valid", (0, t._)`${l} <= ${r.length}`);
			i.if((0, t.not)(n), () => u(n)), e.ok(n);
		}
		function u(a) {
			i.forRange("i", r.length, l, (r) => {
				e.subschema({
					keyword: s,
					dataProp: r,
					dataPropType: n.Type.Num
				}, a), c.allErrors || i.if((0, t.not)(a), () => i.break());
			});
		}
	}
	e.validateAdditionalItems = i, e.default = r;
})), Se = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.validateTuple = void 0;
	var t = T(), n = E(), r = P(), i = {
		keyword: "items",
		type: "array",
		schemaType: [
			"object",
			"array",
			"boolean"
		],
		before: "uniqueItems",
		code(e) {
			let { schema: t, it: i } = e;
			if (Array.isArray(t)) return a(e, "additionalItems", t);
			i.items = !0, !(0, n.alwaysValidSchema)(i, t) && e.ok((0, r.validateArray)(e));
		}
	};
	function a(e, r, i = e.schema) {
		let { gen: a, parentSchema: o, data: s, keyword: c, it: l } = e;
		f(o), l.opts.unevaluated && i.length && l.items !== !0 && (l.items = n.mergeEvaluated.items(a, i.length, l.items));
		let u = a.name("valid"), d = a.const("len", (0, t._)`${s}.length`);
		i.forEach((r, i) => {
			(0, n.alwaysValidSchema)(l, r) || (a.if((0, t._)`${d} > ${i}`, () => e.subschema({
				keyword: c,
				schemaProp: i,
				dataProp: i
			}, u)), e.ok(u));
		});
		function f(e) {
			let { opts: t, errSchemaPath: a } = l, o = i.length, s = o === e.minItems && (o === e.maxItems || e[r] === !1);
			if (t.strictTuples && !s) {
				let e = `"${c}" is ${o}-tuple, but minItems or maxItems/${r} are not specified or different at path "${a}"`;
				(0, n.checkStrictMode)(l, e, t.strictTuples);
			}
		}
	}
	e.validateTuple = a, e.default = i;
})), Ce = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = Se();
	e.default = {
		keyword: "prefixItems",
		type: "array",
		schemaType: ["array"],
		before: "uniqueItems",
		code: (e) => (0, t.validateTuple)(e, "items")
	};
})), we = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E(), r = P(), i = xe();
	e.default = {
		keyword: "items",
		type: "array",
		schemaType: ["object", "boolean"],
		before: "uniqueItems",
		error: {
			message: ({ params: { len: e } }) => (0, t.str)`must NOT have more than ${e} items`,
			params: ({ params: { len: e } }) => (0, t._)`{limit: ${e}}`
		},
		code(e) {
			let { schema: t, parentSchema: a, it: o } = e, { prefixItems: s } = a;
			o.items = !0, !(0, n.alwaysValidSchema)(o, t) && (s ? (0, i.validateAdditionalItems)(e, s) : e.ok((0, r.validateArray)(e)));
		}
	};
})), Te = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E();
	e.default = {
		keyword: "contains",
		type: "array",
		schemaType: ["object", "boolean"],
		before: "uniqueItems",
		trackErrors: !0,
		error: {
			message: ({ params: { min: e, max: n } }) => n === void 0 ? (0, t.str)`must contain at least ${e} valid item(s)` : (0, t.str)`must contain at least ${e} and no more than ${n} valid item(s)`,
			params: ({ params: { min: e, max: n } }) => n === void 0 ? (0, t._)`{minContains: ${e}}` : (0, t._)`{minContains: ${e}, maxContains: ${n}}`
		},
		code(e) {
			let { gen: r, schema: i, parentSchema: a, data: o, it: s } = e, c, l, { minContains: u, maxContains: d } = a;
			s.opts.next ? (c = u === void 0 ? 1 : u, l = d) : c = 1;
			let f = r.const("len", (0, t._)`${o}.length`);
			if (e.setParams({
				min: c,
				max: l
			}), l === void 0 && c === 0) {
				(0, n.checkStrictMode)(s, "\"minContains\" == 0 without \"maxContains\": \"contains\" keyword ignored");
				return;
			}
			if (l !== void 0 && c > l) {
				(0, n.checkStrictMode)(s, "\"minContains\" > \"maxContains\" is always invalid"), e.fail();
				return;
			}
			if ((0, n.alwaysValidSchema)(s, i)) {
				let n = (0, t._)`${f} >= ${c}`;
				l !== void 0 && (n = (0, t._)`${n} && ${f} <= ${l}`), e.pass(n);
				return;
			}
			s.items = !0;
			let p = r.name("valid");
			l === void 0 && c === 1 ? h(p, () => r.if(p, () => r.break())) : c === 0 ? (r.let(p, !0), l !== void 0 && r.if((0, t._)`${o}.length > 0`, m)) : (r.let(p, !1), m()), e.result(p, () => e.reset());
			function m() {
				let e = r.name("_valid"), t = r.let("count", 0);
				h(e, () => r.if(e, () => g(t)));
			}
			function h(t, i) {
				r.forRange("i", 0, f, (r) => {
					e.subschema({
						keyword: "contains",
						dataProp: r,
						dataPropType: n.Type.Num,
						compositeRule: !0
					}, t), i();
				});
			}
			function g(e) {
				r.code((0, t._)`${e}++`), l === void 0 ? r.if((0, t._)`${e} >= ${c}`, () => r.assign(p, !0).break()) : (r.if((0, t._)`${e} > ${l}`, () => r.assign(p, !1).break()), c === 1 ? r.assign(p, !0) : r.if((0, t._)`${e} >= ${c}`, () => r.assign(p, !0)));
			}
		}
	};
})), Ee = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.validateSchemaDeps = e.validatePropertyDeps = e.error = void 0;
	var t = T(), n = E(), r = P();
	e.error = {
		message: ({ params: { property: e, depsCount: n, deps: r } }) => {
			let i = n === 1 ? "property" : "properties";
			return (0, t.str)`must have ${i} ${r} when property ${e} is present`;
		},
		params: ({ params: { property: e, depsCount: n, deps: r, missingProperty: i } }) => (0, t._)`{property: ${e},
    missingProperty: ${i},
    depsCount: ${n},
    deps: ${r}}`
	};
	var i = {
		keyword: "dependencies",
		type: "object",
		schemaType: "object",
		error: e.error,
		code(e) {
			let [t, n] = a(e);
			o(e, t), s(e, n);
		}
	};
	function a({ schema: e }) {
		let t = {}, n = {};
		for (let r in e) {
			if (r === "__proto__") continue;
			let i = Array.isArray(e[r]) ? t : n;
			i[r] = e[r];
		}
		return [t, n];
	}
	function o(e, n = e.schema) {
		let { gen: i, data: a, it: o } = e;
		if (Object.keys(n).length === 0) return;
		let s = i.let("missing");
		for (let c in n) {
			let l = n[c];
			if (l.length === 0) continue;
			let u = (0, r.propertyInData)(i, a, c, o.opts.ownProperties);
			e.setParams({
				property: c,
				depsCount: l.length,
				deps: l.join(", ")
			}), o.allErrors ? i.if(u, () => {
				for (let t of l) (0, r.checkReportMissingProp)(e, t);
			}) : (i.if((0, t._)`${u} && (${(0, r.checkMissingProp)(e, l, s)})`), (0, r.reportMissingProp)(e, s), i.else());
		}
	}
	e.validatePropertyDeps = o;
	function s(e, t = e.schema) {
		let { gen: i, data: a, keyword: o, it: s } = e, c = i.name("valid");
		for (let l in t) (0, n.alwaysValidSchema)(s, t[l]) || (i.if((0, r.propertyInData)(i, a, l, s.opts.ownProperties), () => {
			let t = e.subschema({
				keyword: o,
				schemaProp: l
			}, c);
			e.mergeValidEvaluated(t, c);
		}, () => i.var(c, !0)), e.ok(c));
	}
	e.validateSchemaDeps = s, e.default = i;
})), De = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E();
	e.default = {
		keyword: "propertyNames",
		type: "object",
		schemaType: ["object", "boolean"],
		error: {
			message: "property name must be valid",
			params: ({ params: e }) => (0, t._)`{propertyName: ${e.propertyName}}`
		},
		code(e) {
			let { gen: r, schema: i, data: a, it: o } = e;
			if ((0, n.alwaysValidSchema)(o, i)) return;
			let s = r.name("valid");
			r.forIn("key", a, (n) => {
				e.setParams({ propertyName: n }), e.subschema({
					keyword: "propertyNames",
					data: n,
					dataTypes: ["string"],
					propertyName: n,
					compositeRule: !0
				}, s), r.if((0, t.not)(s), () => {
					e.error(!0), o.allErrors || r.break();
				});
			}), e.ok(s);
		}
	};
})), Oe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = P(), n = T(), r = D(), i = E();
	e.default = {
		keyword: "additionalProperties",
		type: ["object"],
		schemaType: ["boolean", "object"],
		allowUndefined: !0,
		trackErrors: !0,
		error: {
			message: "must NOT have additional properties",
			params: ({ params: e }) => (0, n._)`{additionalProperty: ${e.additionalProperty}}`
		},
		code(e) {
			let { gen: a, schema: o, parentSchema: s, data: c, errsCount: l, it: u } = e;
			/* istanbul ignore if */
			if (!l) throw Error("ajv implementation error");
			let { allErrors: d, opts: f } = u;
			if (u.props = !0, f.removeAdditional !== "all" && (0, i.alwaysValidSchema)(u, o)) return;
			let p = (0, t.allSchemaProperties)(s.properties), m = (0, t.allSchemaProperties)(s.patternProperties);
			h(), e.ok((0, n._)`${l} === ${r.default.errors}`);
			function h() {
				a.forIn("key", c, (e) => {
					!p.length && !m.length ? v(e) : a.if(g(e), () => v(e));
				});
			}
			function g(r) {
				let o;
				if (p.length > 8) {
					let e = (0, i.schemaRefOrVal)(u, s.properties, "properties");
					o = (0, t.isOwnProperty)(a, e, r);
				} else o = p.length ? (0, n.or)(...p.map((e) => (0, n._)`${r} === ${e}`)) : n.nil;
				return m.length && (o = (0, n.or)(o, ...m.map((i) => (0, n._)`${(0, t.usePattern)(e, i)}.test(${r})`))), (0, n.not)(o);
			}
			function _(e) {
				a.code((0, n._)`delete ${c}[${e}]`);
			}
			function v(t) {
				if (f.removeAdditional === "all" || f.removeAdditional && o === !1) {
					_(t);
					return;
				}
				if (o === !1) {
					e.setParams({ additionalProperty: t }), e.error(), d || a.break();
					return;
				}
				if (typeof o == "object" && !(0, i.alwaysValidSchema)(u, o)) {
					let r = a.name("valid");
					f.removeAdditional === "failing" ? (y(t, r, !1), a.if((0, n.not)(r), () => {
						e.reset(), _(t);
					})) : (y(t, r), d || a.if((0, n.not)(r), () => a.break()));
				}
			}
			function y(t, n, r) {
				let a = {
					keyword: "additionalProperties",
					dataProp: t,
					dataPropType: i.Type.Str
				};
				r === !1 && Object.assign(a, {
					compositeRule: !0,
					createErrors: !1,
					allErrors: !1
				}), e.subschema(a, n);
			}
		}
	};
})), ke = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = B(), n = P(), r = E(), i = Oe();
	e.default = {
		keyword: "properties",
		type: "object",
		schemaType: "object",
		code(e) {
			let { gen: a, schema: o, parentSchema: s, data: c, it: l } = e;
			l.opts.removeAdditional === "all" && s.additionalProperties === void 0 && i.default.code(new t.KeywordCxt(l, i.default, "additionalProperties"));
			let u = (0, n.allSchemaProperties)(o);
			for (let e of u) l.definedProperties.add(e);
			l.opts.unevaluated && u.length && l.props !== !0 && (l.props = r.mergeEvaluated.props(a, (0, r.toHash)(u), l.props));
			let d = u.filter((e) => !(0, r.alwaysValidSchema)(l, o[e]));
			if (d.length === 0) return;
			let f = a.name("valid");
			for (let t of d) p(t) ? m(t) : (a.if((0, n.propertyInData)(a, c, t, l.opts.ownProperties)), m(t), l.allErrors || a.else().var(f, !0), a.endIf()), e.it.definedProperties.add(t), e.ok(f);
			function p(e) {
				return l.opts.useDefaults && !l.compositeRule && o[e].default !== void 0;
			}
			function m(t) {
				e.subschema({
					keyword: "properties",
					schemaProp: t,
					dataProp: t
				}, f);
			}
		}
	};
})), Ae = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = P(), n = T(), r = E(), i = E();
	e.default = {
		keyword: "patternProperties",
		type: "object",
		schemaType: "object",
		code(e) {
			let { gen: a, schema: o, data: s, parentSchema: c, it: l } = e, { opts: u } = l, d = (0, t.allSchemaProperties)(o), f = d.filter((e) => (0, r.alwaysValidSchema)(l, o[e]));
			if (d.length === 0 || f.length === d.length && (!l.opts.unevaluated || l.props === !0)) return;
			let p = u.strictSchema && !u.allowMatchingProperties && c.properties, m = a.name("valid");
			l.props !== !0 && !(l.props instanceof n.Name) && (l.props = (0, i.evaluatedPropsToName)(a, l.props));
			let { props: h } = l;
			g();
			function g() {
				for (let e of d) p && _(e), l.allErrors ? v(e) : (a.var(m, !0), v(e), a.if(m));
			}
			function _(e) {
				for (let t in p) new RegExp(e).test(t) && (0, r.checkStrictMode)(l, `property ${t} matches pattern ${e} (use allowMatchingProperties)`);
			}
			function v(r) {
				a.forIn("key", s, (o) => {
					a.if((0, n._)`${(0, t.usePattern)(e, r)}.test(${o})`, () => {
						let t = f.includes(r);
						t || e.subschema({
							keyword: "patternProperties",
							schemaProp: r,
							dataProp: o,
							dataPropType: i.Type.Str
						}, m), l.opts.unevaluated && h !== !0 ? a.assign((0, n._)`${h}[${o}]`, !0) : !t && !l.allErrors && a.if((0, n.not)(m), () => a.break());
					});
				});
			}
		}
	};
})), je = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = E();
	e.default = {
		keyword: "not",
		schemaType: ["object", "boolean"],
		trackErrors: !0,
		code(e) {
			let { gen: n, schema: r, it: i } = e;
			if ((0, t.alwaysValidSchema)(i, r)) {
				e.fail();
				return;
			}
			let a = n.name("valid");
			e.subschema({
				keyword: "not",
				compositeRule: !0,
				createErrors: !1,
				allErrors: !1
			}, a), e.failResult(a, () => e.reset(), () => e.error());
		},
		error: { message: "must NOT be valid" }
	};
})), Me = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.default = {
		keyword: "anyOf",
		schemaType: "array",
		trackErrors: !0,
		code: P().validateUnion,
		error: { message: "must match a schema in anyOf" }
	};
})), Ne = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E();
	e.default = {
		keyword: "oneOf",
		schemaType: "array",
		trackErrors: !0,
		error: {
			message: "must match exactly one schema in oneOf",
			params: ({ params: e }) => (0, t._)`{passingSchemas: ${e.passing}}`
		},
		code(e) {
			let { gen: r, schema: i, parentSchema: a, it: o } = e;
			/* istanbul ignore if */
			if (!Array.isArray(i)) throw Error("ajv implementation error");
			if (o.opts.discriminator && a.discriminator) return;
			let s = i, c = r.let("valid", !1), l = r.let("passing", null), u = r.name("_valid");
			e.setParams({ passing: l }), r.block(d), e.result(c, () => e.reset(), () => e.error(!0));
			function d() {
				s.forEach((i, a) => {
					let s;
					(0, n.alwaysValidSchema)(o, i) ? r.var(u, !0) : s = e.subschema({
						keyword: "oneOf",
						schemaProp: a,
						compositeRule: !0
					}, u), a > 0 && r.if((0, t._)`${u} && ${c}`).assign(c, !1).assign(l, (0, t._)`[${l}, ${a}]`).else(), r.if(u, () => {
						r.assign(c, !0), r.assign(l, a), s && e.mergeEvaluated(s, t.Name);
					});
				});
			}
		}
	};
})), Pe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = E();
	e.default = {
		keyword: "allOf",
		schemaType: "array",
		code(e) {
			let { gen: n, schema: r, it: i } = e;
			/* istanbul ignore if */
			if (!Array.isArray(r)) throw Error("ajv implementation error");
			let a = n.name("valid");
			r.forEach((n, r) => {
				if ((0, t.alwaysValidSchema)(i, n)) return;
				let o = e.subschema({
					keyword: "allOf",
					schemaProp: r
				}, a);
				e.ok(a), e.mergeEvaluated(o);
			});
		}
	};
})), Fe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E(), r = {
		keyword: "if",
		schemaType: ["object", "boolean"],
		trackErrors: !0,
		error: {
			message: ({ params: e }) => (0, t.str)`must match "${e.ifClause}" schema`,
			params: ({ params: e }) => (0, t._)`{failingKeyword: ${e.ifClause}}`
		},
		code(e) {
			let { gen: r, parentSchema: a, it: o } = e;
			a.then === void 0 && a.else === void 0 && (0, n.checkStrictMode)(o, "\"if\" without \"then\" and \"else\" is ignored");
			let s = i(o, "then"), c = i(o, "else");
			if (!s && !c) return;
			let l = r.let("valid", !0), u = r.name("_valid");
			if (d(), e.reset(), s && c) {
				let t = r.let("ifClause");
				e.setParams({ ifClause: t }), r.if(u, f("then", t), f("else", t));
			} else s ? r.if(u, f("then")) : r.if((0, t.not)(u), f("else"));
			e.pass(l, () => e.error(!0));
			function d() {
				let t = e.subschema({
					keyword: "if",
					compositeRule: !0,
					createErrors: !1,
					allErrors: !1
				}, u);
				e.mergeEvaluated(t);
			}
			function f(n, i) {
				return () => {
					let a = e.subschema({ keyword: n }, u);
					r.assign(l, u), e.mergeValidEvaluated(a, l), i ? r.assign(i, (0, t._)`${n}`) : e.setParams({ ifClause: n });
				};
			}
		}
	};
	function i(e, t) {
		let r = e.schema[t];
		return r !== void 0 && !(0, n.alwaysValidSchema)(e, r);
	}
	e.default = r;
})), Ie = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = E();
	e.default = {
		keyword: ["then", "else"],
		schemaType: ["object", "boolean"],
		code({ keyword: e, parentSchema: n, it: r }) {
			n.if === void 0 && (0, t.checkStrictMode)(r, `"${e}" without "if" is ignored`);
		}
	};
})), Le = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = xe(), n = Ce(), r = Se(), i = we(), a = Te(), o = Ee(), s = De(), c = Oe(), l = ke(), u = Ae(), d = je(), f = Me(), p = Ne(), m = Pe(), h = Fe(), g = Ie();
	function _(e = !1) {
		let _ = [
			d.default,
			f.default,
			p.default,
			m.default,
			h.default,
			g.default,
			s.default,
			c.default,
			o.default,
			l.default,
			u.default
		];
		return e ? _.push(n.default, i.default) : _.push(t.default, r.default), _.push(a.default), _;
	}
	e.default = _;
})), Re = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.dynamicAnchor = void 0;
	var t = T(), n = D(), r = U(), i = Z(), a = {
		keyword: "$dynamicAnchor",
		schemaType: "string",
		code: (e) => o(e, e.schema)
	};
	function o(e, r) {
		let { gen: i, it: a } = e;
		a.schemaEnv.root.dynamicAnchors[r] = !0;
		let o = (0, t._)`${n.default.dynamicAnchors}${(0, t.getProperty)(r)}`, c = a.errSchemaPath === "#" ? a.validateName : s(e);
		i.if((0, t._)`!${o}`, () => i.assign(o, c));
	}
	e.dynamicAnchor = o;
	function s(e) {
		let { schemaEnv: t, schema: n, self: a } = e.it, { root: o, baseId: s, localRefs: c, meta: l } = t.root, { schemaId: u } = a.opts, d = new r.SchemaEnv({
			schema: n,
			schemaId: u,
			root: o,
			baseId: s,
			localRefs: c,
			meta: l
		});
		return r.compileSchema.call(a, d), (0, i.getValidate)(e, d);
	}
	e.default = a;
})), ze = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.dynamicRef = void 0;
	var t = T(), n = D(), r = Z(), i = {
		keyword: "$dynamicRef",
		schemaType: "string",
		code: (e) => a(e, e.schema)
	};
	function a(e, i) {
		let { gen: a, keyword: o, it: s } = e;
		if (i[0] !== "#") throw Error(`"${o}" only supports hash fragment reference`);
		let c = i.slice(1);
		if (s.allErrors) l();
		else {
			let t = a.let("valid", !1);
			l(t), e.ok(t);
		}
		function l(e) {
			if (s.schemaEnv.root.dynamicAnchors[c]) {
				let r = a.let("_v", (0, t._)`${n.default.dynamicAnchors}${(0, t.getProperty)(c)}`);
				a.if(r, u(r, e), u(s.validateName, e));
			} else u(s.validateName, e)();
		}
		function u(t, n) {
			return n ? () => a.block(() => {
				(0, r.callRef)(e, t), a.let(n, !0);
			}) : () => (0, r.callRef)(e, t);
		}
	}
	e.dynamicRef = a, e.default = i;
})), Be = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = Re(), n = E();
	e.default = {
		keyword: "$recursiveAnchor",
		schemaType: "boolean",
		code(e) {
			e.schema ? (0, t.dynamicAnchor)(e, "") : (0, n.checkStrictMode)(e.it, "$recursiveAnchor: false is ignored");
		}
	};
})), Ve = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = ze();
	e.default = {
		keyword: "$recursiveRef",
		schemaType: "string",
		code: (e) => (0, t.dynamicRef)(e, e.schema)
	};
})), He = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = Re(), n = ze(), r = Be(), i = Ve();
	e.default = [
		t.default,
		n.default,
		r.default,
		i.default
	];
})), Ue = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = Ee();
	e.default = {
		keyword: "dependentRequired",
		type: "object",
		schemaType: "object",
		error: t.error,
		code: (e) => (0, t.validatePropertyDeps)(e)
	};
})), We = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = Ee();
	e.default = {
		keyword: "dependentSchemas",
		type: "object",
		schemaType: "object",
		code: (e) => (0, t.validateSchemaDeps)(e)
	};
})), Ge = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = E();
	e.default = {
		keyword: ["maxContains", "minContains"],
		type: "array",
		schemaType: "number",
		code({ keyword: e, parentSchema: n, it: r }) {
			n.contains === void 0 && (0, t.checkStrictMode)(r, `"${e}" without "contains" is ignored`);
		}
	};
})), Ke = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = Ue(), n = We(), r = Ge();
	e.default = [
		t.default,
		n.default,
		r.default
	];
})), qe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E(), r = D();
	e.default = {
		keyword: "unevaluatedProperties",
		type: "object",
		schemaType: ["boolean", "object"],
		trackErrors: !0,
		error: {
			message: "must NOT have unevaluated properties",
			params: ({ params: e }) => (0, t._)`{unevaluatedProperty: ${e.unevaluatedProperty}}`
		},
		code(e) {
			let { gen: i, schema: a, data: o, errsCount: s, it: c } = e;
			/* istanbul ignore if */
			if (!s) throw Error("ajv implementation error");
			let { allErrors: l, props: u } = c;
			u instanceof t.Name ? i.if((0, t._)`${u} !== true`, () => i.forIn("key", o, (e) => i.if(f(u, e), () => d(e)))) : u !== !0 && i.forIn("key", o, (e) => u === void 0 ? d(e) : i.if(p(u, e), () => d(e))), c.props = !0, e.ok((0, t._)`${s} === ${r.default.errors}`);
			function d(r) {
				if (a === !1) {
					e.setParams({ unevaluatedProperty: r }), e.error(), l || i.break();
					return;
				}
				if (!(0, n.alwaysValidSchema)(c, a)) {
					let a = i.name("valid");
					e.subschema({
						keyword: "unevaluatedProperties",
						dataProp: r,
						dataPropType: n.Type.Str
					}, a), l || i.if((0, t.not)(a), () => i.break());
				}
			}
			function f(e, n) {
				return (0, t._)`!${e} || !${e}[${n}]`;
			}
			function p(e, n) {
				let r = [];
				for (let i in e) e[i] === !0 && r.push((0, t._)`${n} !== ${i}`);
				return (0, t.and)(...r);
			}
		}
	};
})), Je = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = E();
	e.default = {
		keyword: "unevaluatedItems",
		type: "array",
		schemaType: ["boolean", "object"],
		error: {
			message: ({ params: { len: e } }) => (0, t.str)`must NOT have more than ${e} items`,
			params: ({ params: { len: e } }) => (0, t._)`{limit: ${e}}`
		},
		code(e) {
			let { gen: r, schema: i, data: a, it: o } = e, s = o.items || 0;
			if (s === !0) return;
			let c = r.const("len", (0, t._)`${a}.length`);
			if (i === !1) e.setParams({ len: s }), e.fail((0, t._)`${c} > ${s}`);
			else if (typeof i == "object" && !(0, n.alwaysValidSchema)(o, i)) {
				let n = r.var("valid", (0, t._)`${c} <= ${s}`);
				r.if((0, t.not)(n), () => l(n, s)), e.ok(n);
			}
			o.items = !0;
			function l(i, a) {
				r.forRange("i", a, c, (a) => {
					e.subschema({
						keyword: "unevaluatedItems",
						dataProp: a,
						dataPropType: n.Type.Num
					}, i), o.allErrors || r.if((0, t.not)(i), () => r.break());
				});
			}
		}
	};
})), Ye = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = qe(), n = Je();
	e.default = [t.default, n.default];
})), Xe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T();
	e.default = {
		keyword: "format",
		type: ["number", "string"],
		schemaType: "string",
		$data: !0,
		error: {
			message: ({ schemaCode: e }) => (0, t.str)`must match format "${e}"`,
			params: ({ schemaCode: e }) => (0, t._)`{format: ${e}}`
		},
		code(e, n) {
			let { gen: r, data: i, $data: a, schema: o, schemaCode: s, it: c } = e, { opts: l, errSchemaPath: u, schemaEnv: d, self: f } = c;
			if (!l.validateFormats) return;
			a ? p() : m();
			function p() {
				let a = r.scopeValue("formats", {
					ref: f.formats,
					code: l.code.formats
				}), o = r.const("fDef", (0, t._)`${a}[${s}]`), c = r.let("fType"), u = r.let("format");
				r.if((0, t._)`typeof ${o} == "object" && !(${o} instanceof RegExp)`, () => r.assign(c, (0, t._)`${o}.type || "string"`).assign(u, (0, t._)`${o}.validate`), () => r.assign(c, (0, t._)`"string"`).assign(u, o)), e.fail$data((0, t.or)(p(), m()));
				function p() {
					return l.strictSchema === !1 ? t.nil : (0, t._)`${s} && !${u}`;
				}
				function m() {
					let e = d.$async ? (0, t._)`(${o}.async ? await ${u}(${i}) : ${u}(${i}))` : (0, t._)`${u}(${i})`, r = (0, t._)`(typeof ${u} == "function" ? ${e} : ${u}.test(${i}))`;
					return (0, t._)`${u} && ${u} !== true && ${c} === ${n} && !${r}`;
				}
			}
			function m() {
				let a = f.formats[o];
				if (!a) {
					m();
					return;
				}
				if (a === !0) return;
				let [s, c, p] = h(a);
				s === n && e.pass(g());
				function m() {
					if (l.strictSchema === !1) {
						f.logger.warn(e());
						return;
					}
					throw Error(e());
					function e() {
						return `unknown format "${o}" ignored in schema at path "${u}"`;
					}
				}
				function h(e) {
					let n = e instanceof RegExp ? (0, t.regexpCode)(e) : l.code.formats ? (0, t._)`${l.code.formats}${(0, t.getProperty)(o)}` : void 0, i = r.scopeValue("formats", {
						key: o,
						ref: e,
						code: n
					});
					return typeof e == "object" && !(e instanceof RegExp) ? [
						e.type || "string",
						e.validate,
						(0, t._)`${i}.validate`
					] : [
						"string",
						e,
						i
					];
				}
				function g() {
					if (typeof a == "object" && !(a instanceof RegExp) && a.async) {
						if (!d.$async) throw Error("async format in sync schema");
						return (0, t._)`await ${p}(${i})`;
					}
					return typeof c == "function" ? (0, t._)`${p}(${i})` : (0, t._)`${p}.test(${i})`;
				}
			}
		}
	};
})), Ze = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.default = [Xe().default];
})), Qe = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.contentVocabulary = e.metadataVocabulary = void 0, e.metadataVocabulary = [
		"title",
		"description",
		"default",
		"deprecated",
		"readOnly",
		"writeOnly",
		"examples"
	], e.contentVocabulary = [
		"contentMediaType",
		"contentEncoding",
		"contentSchema"
	];
})), $e = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = se(), n = be(), r = Le(), i = He(), a = Ke(), o = Ye(), s = Ze(), c = Qe();
	e.default = [
		i.default,
		t.default,
		n.default,
		(0, r.default)(!0),
		s.default,
		c.metadataVocabulary,
		c.contentVocabulary,
		a.default,
		o.default
	];
})), et = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.DiscrError = void 0;
	var t;
	(function(e) {
		e.Tag = "tag", e.Mapping = "mapping";
	})(t || (e.DiscrError = t = {}));
})), tt = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = T(), n = et(), r = U(), i = H(), a = E();
	e.default = {
		keyword: "discriminator",
		type: "object",
		schemaType: "object",
		error: {
			message: ({ params: { discrError: e, tagName: t } }) => e === n.DiscrError.Tag ? `tag "${t}" must be string` : `value of tag "${t}" must be in oneOf`,
			params: ({ params: { discrError: e, tag: n, tagName: r } }) => (0, t._)`{error: ${e}, tag: ${r}, tagValue: ${n}}`
		},
		code(e) {
			let { gen: o, data: s, schema: c, parentSchema: l, it: u } = e, { oneOf: d } = l;
			if (!u.opts.discriminator) throw Error("discriminator: requires discriminator option");
			let f = c.propertyName;
			if (typeof f != "string") throw Error("discriminator: requires propertyName");
			if (c.mapping) throw Error("discriminator: mapping is not supported");
			if (!d) throw Error("discriminator: requires oneOf keyword");
			let p = o.let("valid", !1), m = o.const("tag", (0, t._)`${s}${(0, t.getProperty)(f)}`);
			o.if((0, t._)`typeof ${m} == "string"`, () => h(), () => e.error(!1, {
				discrError: n.DiscrError.Tag,
				tag: m,
				tagName: f
			})), e.ok(p);
			function h() {
				let r = _();
				o.if(!1);
				for (let e in r) o.elseIf((0, t._)`${m} === ${e}`), o.assign(p, g(r[e]));
				o.else(), e.error(!1, {
					discrError: n.DiscrError.Mapping,
					tag: m,
					tagName: f
				}), o.endIf();
			}
			function g(n) {
				let r = o.name("valid"), i = e.subschema({
					keyword: "oneOf",
					schemaProp: n
				}, r);
				return e.mergeEvaluated(i, t.Name), r;
			}
			function _() {
				let e = {}, t = o(l), n = !0;
				for (let e = 0; e < d.length; e++) {
					let c = d[e];
					if (c?.$ref && !(0, a.schemaHasRulesButRef)(c, u.self.RULES)) {
						let e = c.$ref;
						if (c = r.resolveRef.call(u.self, u.schemaEnv.root, u.baseId, e), c instanceof r.SchemaEnv && (c = c.schema), c === void 0) throw new i.default(u.opts.uriResolver, u.baseId, e);
					}
					let l = c?.properties?.[f];
					if (typeof l != "object") throw Error(`discriminator: oneOf subschemas (or referenced schemas) must have "properties/${f}"`);
					n &&= t || o(c), s(l, e);
				}
				if (!n) throw Error(`discriminator: "${f}" must be required`);
				return e;
				function o({ required: e }) {
					return Array.isArray(e) && e.includes(f);
				}
				function s(e, t) {
					if (e.const) c(e.const, t);
					else if (e.enum) for (let n of e.enum) c(n, t);
					else throw Error(`discriminator: "properties/${f}" must have "const" or "enum"`);
				}
				function c(t, n) {
					if (typeof t != "string" || t in e) throw Error(`discriminator: "${f}" values must be unique strings`);
					e[t] = n;
				}
			}
		}
	};
})), nt = /* @__PURE__ */ c({
	$comment: () => ut,
	$dynamicAnchor: () => ot,
	$id: () => it,
	$schema: () => rt,
	$vocabulary: () => at,
	allOf: () => ct,
	default: () => ft,
	properties: () => dt,
	title: () => st,
	type: () => lt
}), rt, it, at, ot, st, ct, lt, ut, dt, ft, pt = o((() => {
	rt = "https://json-schema.org/draft/2020-12/schema", it = "https://json-schema.org/draft/2020-12/schema", at = {
		"https://json-schema.org/draft/2020-12/vocab/core": !0,
		"https://json-schema.org/draft/2020-12/vocab/applicator": !0,
		"https://json-schema.org/draft/2020-12/vocab/unevaluated": !0,
		"https://json-schema.org/draft/2020-12/vocab/validation": !0,
		"https://json-schema.org/draft/2020-12/vocab/meta-data": !0,
		"https://json-schema.org/draft/2020-12/vocab/format-annotation": !0,
		"https://json-schema.org/draft/2020-12/vocab/content": !0
	}, ot = "meta", st = "Core and Validation specifications meta-schema", ct = [
		{ $ref: "meta/core" },
		{ $ref: "meta/applicator" },
		{ $ref: "meta/unevaluated" },
		{ $ref: "meta/validation" },
		{ $ref: "meta/meta-data" },
		{ $ref: "meta/format-annotation" },
		{ $ref: "meta/content" }
	], lt = ["object", "boolean"], ut = "This meta-schema also defines keywords that have appeared in previous drafts in order to prevent incompatible extensions as they remain in common use.", dt = {
		definitions: {
			$comment: "\"definitions\" has been replaced by \"$defs\".",
			type: "object",
			additionalProperties: { $dynamicRef: "#meta" },
			deprecated: !0,
			default: {}
		},
		dependencies: {
			$comment: "\"dependencies\" has been split and replaced by \"dependentSchemas\" and \"dependentRequired\" in order to serve their differing semantics.",
			type: "object",
			additionalProperties: { anyOf: [{ $dynamicRef: "#meta" }, { $ref: "meta/validation#/$defs/stringArray" }] },
			deprecated: !0,
			default: {}
		},
		$recursiveAnchor: {
			$comment: "\"$recursiveAnchor\" has been replaced by \"$dynamicAnchor\".",
			$ref: "meta/core#/$defs/anchorString",
			deprecated: !0
		},
		$recursiveRef: {
			$comment: "\"$recursiveRef\" has been replaced by \"$dynamicRef\".",
			$ref: "meta/core#/$defs/uriReferenceString",
			deprecated: !0
		}
	}, ft = {
		$schema: rt,
		$id: it,
		$vocabulary: at,
		$dynamicAnchor: ot,
		title: st,
		allOf: ct,
		type: lt,
		$comment: ut,
		properties: dt
	};
})), mt = /* @__PURE__ */ c({
	$defs: () => St,
	$dynamicAnchor: () => vt,
	$id: () => gt,
	$schema: () => ht,
	$vocabulary: () => _t,
	default: () => Ct,
	properties: () => xt,
	title: () => yt,
	type: () => bt
}), ht, gt, _t, vt, yt, bt, xt, St, Ct, wt = o((() => {
	ht = "https://json-schema.org/draft/2020-12/schema", gt = "https://json-schema.org/draft/2020-12/meta/applicator", _t = { "https://json-schema.org/draft/2020-12/vocab/applicator": !0 }, vt = "meta", yt = "Applicator vocabulary meta-schema", bt = ["object", "boolean"], xt = {
		prefixItems: { $ref: "#/$defs/schemaArray" },
		items: { $dynamicRef: "#meta" },
		contains: { $dynamicRef: "#meta" },
		additionalProperties: { $dynamicRef: "#meta" },
		properties: {
			type: "object",
			additionalProperties: { $dynamicRef: "#meta" },
			default: {}
		},
		patternProperties: {
			type: "object",
			additionalProperties: { $dynamicRef: "#meta" },
			propertyNames: { format: "regex" },
			default: {}
		},
		dependentSchemas: {
			type: "object",
			additionalProperties: { $dynamicRef: "#meta" },
			default: {}
		},
		propertyNames: { $dynamicRef: "#meta" },
		if: { $dynamicRef: "#meta" },
		then: { $dynamicRef: "#meta" },
		else: { $dynamicRef: "#meta" },
		allOf: { $ref: "#/$defs/schemaArray" },
		anyOf: { $ref: "#/$defs/schemaArray" },
		oneOf: { $ref: "#/$defs/schemaArray" },
		not: { $dynamicRef: "#meta" }
	}, St = { schemaArray: {
		type: "array",
		minItems: 1,
		items: { $dynamicRef: "#meta" }
	} }, Ct = {
		$schema: ht,
		$id: gt,
		$vocabulary: _t,
		$dynamicAnchor: vt,
		title: yt,
		type: bt,
		properties: xt,
		$defs: St
	};
})), Tt = /* @__PURE__ */ c({
	$dynamicAnchor: () => kt,
	$id: () => Dt,
	$schema: () => Et,
	$vocabulary: () => Ot,
	default: () => Nt,
	properties: () => Mt,
	title: () => At,
	type: () => jt
}), Et, Dt, Ot, kt, At, jt, Mt, Nt, Pt = o((() => {
	Et = "https://json-schema.org/draft/2020-12/schema", Dt = "https://json-schema.org/draft/2020-12/meta/unevaluated", Ot = { "https://json-schema.org/draft/2020-12/vocab/unevaluated": !0 }, kt = "meta", At = "Unevaluated applicator vocabulary meta-schema", jt = ["object", "boolean"], Mt = {
		unevaluatedItems: { $dynamicRef: "#meta" },
		unevaluatedProperties: { $dynamicRef: "#meta" }
	}, Nt = {
		$schema: Et,
		$id: Dt,
		$vocabulary: Ot,
		$dynamicAnchor: kt,
		title: At,
		type: jt,
		properties: Mt
	};
})), Ft = /* @__PURE__ */ c({
	$dynamicAnchor: () => zt,
	$id: () => Lt,
	$schema: () => It,
	$vocabulary: () => Rt,
	default: () => Ut,
	properties: () => Ht,
	title: () => Bt,
	type: () => Vt
}), It, Lt, Rt, zt, Bt, Vt, Ht, Ut, Wt = o((() => {
	It = "https://json-schema.org/draft/2020-12/schema", Lt = "https://json-schema.org/draft/2020-12/meta/content", Rt = { "https://json-schema.org/draft/2020-12/vocab/content": !0 }, zt = "meta", Bt = "Content vocabulary meta-schema", Vt = ["object", "boolean"], Ht = {
		contentEncoding: { type: "string" },
		contentMediaType: { type: "string" },
		contentSchema: { $dynamicRef: "#meta" }
	}, Ut = {
		$schema: It,
		$id: Lt,
		$vocabulary: Rt,
		$dynamicAnchor: zt,
		title: Bt,
		type: Vt,
		properties: Ht
	};
})), Gt = /* @__PURE__ */ c({
	$defs: () => $t,
	$dynamicAnchor: () => Yt,
	$id: () => qt,
	$schema: () => Kt,
	$vocabulary: () => Jt,
	default: () => en,
	properties: () => Qt,
	title: () => Xt,
	type: () => Zt
}), Kt, qt, Jt, Yt, Xt, Zt, Qt, $t, en, tn = o((() => {
	Kt = "https://json-schema.org/draft/2020-12/schema", qt = "https://json-schema.org/draft/2020-12/meta/core", Jt = { "https://json-schema.org/draft/2020-12/vocab/core": !0 }, Yt = "meta", Xt = "Core vocabulary meta-schema", Zt = ["object", "boolean"], Qt = {
		$id: {
			$ref: "#/$defs/uriReferenceString",
			$comment: "Non-empty fragments not allowed.",
			pattern: "^[^#]*#?$"
		},
		$schema: { $ref: "#/$defs/uriString" },
		$ref: { $ref: "#/$defs/uriReferenceString" },
		$anchor: { $ref: "#/$defs/anchorString" },
		$dynamicRef: { $ref: "#/$defs/uriReferenceString" },
		$dynamicAnchor: { $ref: "#/$defs/anchorString" },
		$vocabulary: {
			type: "object",
			propertyNames: { $ref: "#/$defs/uriString" },
			additionalProperties: { type: "boolean" }
		},
		$comment: { type: "string" },
		$defs: {
			type: "object",
			additionalProperties: { $dynamicRef: "#meta" }
		}
	}, $t = {
		anchorString: {
			type: "string",
			pattern: "^[A-Za-z_][-A-Za-z0-9._]*$"
		},
		uriString: {
			type: "string",
			format: "uri"
		},
		uriReferenceString: {
			type: "string",
			format: "uri-reference"
		}
	}, en = {
		$schema: Kt,
		$id: qt,
		$vocabulary: Jt,
		$dynamicAnchor: Yt,
		title: Xt,
		type: Zt,
		properties: Qt,
		$defs: $t
	};
})), nn = /* @__PURE__ */ c({
	$dynamicAnchor: () => sn,
	$id: () => an,
	$schema: () => rn,
	$vocabulary: () => on,
	default: () => dn,
	properties: () => un,
	title: () => cn,
	type: () => ln
}), rn, an, on, sn, cn, ln, un, dn, fn = o((() => {
	rn = "https://json-schema.org/draft/2020-12/schema", an = "https://json-schema.org/draft/2020-12/meta/format-annotation", on = { "https://json-schema.org/draft/2020-12/vocab/format-annotation": !0 }, sn = "meta", cn = "Format vocabulary meta-schema for annotation results", ln = ["object", "boolean"], un = { format: { type: "string" } }, dn = {
		$schema: rn,
		$id: an,
		$vocabulary: on,
		$dynamicAnchor: sn,
		title: cn,
		type: ln,
		properties: un
	};
})), pn = /* @__PURE__ */ c({
	$dynamicAnchor: () => gn,
	$id: () => hn,
	$schema: () => mn,
	$vocabulary: () => Q,
	default: () => bn,
	properties: () => yn,
	title: () => _n,
	type: () => vn
}), mn, hn, Q, gn, _n, vn, yn, bn, xn = o((() => {
	mn = "https://json-schema.org/draft/2020-12/schema", hn = "https://json-schema.org/draft/2020-12/meta/meta-data", Q = { "https://json-schema.org/draft/2020-12/vocab/meta-data": !0 }, gn = "meta", _n = "Meta-data vocabulary meta-schema", vn = ["object", "boolean"], yn = {
		title: { type: "string" },
		description: { type: "string" },
		default: !0,
		deprecated: {
			type: "boolean",
			default: !1
		},
		readOnly: {
			type: "boolean",
			default: !1
		},
		writeOnly: {
			type: "boolean",
			default: !1
		},
		examples: {
			type: "array",
			items: !0
		}
	}, bn = {
		$schema: mn,
		$id: hn,
		$vocabulary: Q,
		$dynamicAnchor: gn,
		title: _n,
		type: vn,
		properties: yn
	};
})), Sn = /* @__PURE__ */ c({
	$defs: () => An,
	$dynamicAnchor: () => En,
	$id: () => wn,
	$schema: () => Cn,
	$vocabulary: () => Tn,
	default: () => jn,
	properties: () => kn,
	title: () => Dn,
	type: () => On
}), Cn, wn, Tn, En, Dn, On, kn, An, jn, Mn = o((() => {
	Cn = "https://json-schema.org/draft/2020-12/schema", wn = "https://json-schema.org/draft/2020-12/meta/validation", Tn = { "https://json-schema.org/draft/2020-12/vocab/validation": !0 }, En = "meta", Dn = "Validation vocabulary meta-schema", On = ["object", "boolean"], kn = {
		type: { anyOf: [{ $ref: "#/$defs/simpleTypes" }, {
			type: "array",
			items: { $ref: "#/$defs/simpleTypes" },
			minItems: 1,
			uniqueItems: !0
		}] },
		const: !0,
		enum: {
			type: "array",
			items: !0
		},
		multipleOf: {
			type: "number",
			exclusiveMinimum: 0
		},
		maximum: { type: "number" },
		exclusiveMaximum: { type: "number" },
		minimum: { type: "number" },
		exclusiveMinimum: { type: "number" },
		maxLength: { $ref: "#/$defs/nonNegativeInteger" },
		minLength: { $ref: "#/$defs/nonNegativeIntegerDefault0" },
		pattern: {
			type: "string",
			format: "regex"
		},
		maxItems: { $ref: "#/$defs/nonNegativeInteger" },
		minItems: { $ref: "#/$defs/nonNegativeIntegerDefault0" },
		uniqueItems: {
			type: "boolean",
			default: !1
		},
		maxContains: { $ref: "#/$defs/nonNegativeInteger" },
		minContains: {
			$ref: "#/$defs/nonNegativeInteger",
			default: 1
		},
		maxProperties: { $ref: "#/$defs/nonNegativeInteger" },
		minProperties: { $ref: "#/$defs/nonNegativeIntegerDefault0" },
		required: { $ref: "#/$defs/stringArray" },
		dependentRequired: {
			type: "object",
			additionalProperties: { $ref: "#/$defs/stringArray" }
		}
	}, An = {
		nonNegativeInteger: {
			type: "integer",
			minimum: 0
		},
		nonNegativeIntegerDefault0: {
			$ref: "#/$defs/nonNegativeInteger",
			default: 0
		},
		simpleTypes: { enum: [
			"array",
			"boolean",
			"integer",
			"null",
			"number",
			"object",
			"string"
		] },
		stringArray: {
			type: "array",
			items: { type: "string" },
			uniqueItems: !0,
			default: []
		}
	}, jn = {
		$schema: Cn,
		$id: wn,
		$vocabulary: Tn,
		$dynamicAnchor: En,
		title: Dn,
		type: On,
		properties: kn,
		$defs: An
	};
})), Nn = /* @__PURE__ */ s(((e) => {
	Object.defineProperty(e, "__esModule", { value: !0 });
	var t = (pt(), d(nt).default), n = (wt(), d(mt).default), r = (Pt(), d(Tt).default), i = (Wt(), d(Ft).default), a = (tn(), d(Gt).default), o = (fn(), d(nn).default), s = (xn(), d(pn).default), c = (Mn(), d(Sn).default), l = ["/properties"];
	function u(e) {
		return [
			t,
			n,
			r,
			i,
			a,
			u(this, o),
			s,
			u(this, c)
		].forEach((e) => this.addMetaSchema(e, void 0, !1)), this;
		function u(t, n) {
			return e ? t.$dataMetaSchema(n, l) : n;
		}
	}
	e.default = u;
})), Pn = new (/* @__PURE__ */ u((/* @__PURE__ */ s(((e, t) => {
	Object.defineProperty(e, "__esModule", { value: !0 }), e.MissingRefError = e.ValidationError = e.CodeGen = e.Name = e.nil = e.stringify = e.str = e._ = e.KeywordCxt = e.Ajv2020 = void 0;
	var n = ae(), r = $e(), i = tt(), a = Nn(), o = "https://json-schema.org/draft/2020-12/schema", s = class extends n.default {
		constructor(e = {}) {
			super({
				...e,
				dynamicRef: !0,
				next: !0,
				unevaluated: !0
			});
		}
		_addVocabularies() {
			super._addVocabularies(), r.default.forEach((e) => this.addVocabulary(e)), this.opts.discriminator && this.addKeyword(i.default);
		}
		_addDefaultMetaSchema() {
			super._addDefaultMetaSchema();
			let { $data: e, meta: t } = this.opts;
			t && (a.default.call(this, e), this.refs["http://json-schema.org/schema"] = o);
		}
		defaultMeta() {
			return this.opts.defaultMeta = super.defaultMeta() || (this.getSchema(o) ? o : void 0);
		}
	};
	e.Ajv2020 = s, t.exports = e = s, t.exports.Ajv2020 = s, Object.defineProperty(e, "__esModule", { value: !0 }), e.default = s;
	var c = B();
	Object.defineProperty(e, "KeywordCxt", {
		enumerable: !0,
		get: function() {
			return c.KeywordCxt;
		}
	});
	var l = T();
	Object.defineProperty(e, "_", {
		enumerable: !0,
		get: function() {
			return l._;
		}
	}), Object.defineProperty(e, "str", {
		enumerable: !0,
		get: function() {
			return l.str;
		}
	}), Object.defineProperty(e, "stringify", {
		enumerable: !0,
		get: function() {
			return l.stringify;
		}
	}), Object.defineProperty(e, "nil", {
		enumerable: !0,
		get: function() {
			return l.nil;
		}
	}), Object.defineProperty(e, "Name", {
		enumerable: !0,
		get: function() {
			return l.Name;
		}
	}), Object.defineProperty(e, "CodeGen", {
		enumerable: !0,
		get: function() {
			return l.CodeGen;
		}
	});
	var u = V();
	Object.defineProperty(e, "ValidationError", {
		enumerable: !0,
		get: function() {
			return u.default;
		}
	});
	var d = H();
	Object.defineProperty(e, "MissingRefError", {
		enumerable: !0,
		get: function() {
			return d.default;
		}
	});
})))(), 1)).default({ allErrors: !0 }), Fn;
async function In() {
	let e = document.getElementById("config-sections"), t = document.getElementById("config-section-select"), n = document.getElementById("config-add-section"), r = document.getElementById("config-output"), i = document.getElementById("config-status"), a = document.getElementById("config-validate"), o = document.getElementById("config-download");
	if (!(e instanceof HTMLElement) || !(t instanceof HTMLSelectElement) || !(n instanceof HTMLButtonElement) || !(r instanceof HTMLTextAreaElement) || !(i instanceof HTMLElement) || !(a instanceof HTMLButtonElement) || !(o instanceof HTMLButtonElement)) {
		console.error("Configuration generator markup is incomplete.");
		return;
	}
	let s = r, c = i;
	try {
		let [r, i] = await Promise.all([fetch("./schema.json"), Ln()]);
		if (!r.ok) throw Error(`Could not load json schema (${r.status}).`);
		let l = await r.json(), u = Pn.compile(l), d = /* @__PURE__ */ new Map(), f = l.properties ?? {};
		t.replaceChildren();
		let p = document.createElement("option");
		p.value = "", p.textContent = "Select a section...", t.appendChild(p);
		for (let [e, n] of Object.entries(f)) {
			if (e === "$schema" || !Rn(i[e]) || zn(n) !== "object") continue;
			let r = document.createElement("option");
			r.value = e, r.textContent = n.title ? `${e} (${n.title})` : e, t.appendChild(r);
		}
		function m() {
			try {
				let e = JSON.parse(s.value);
				if (!u(e)) {
					let e = (u.errors ?? []).map((e) => `${e.instancePath || "/"}: ${e.message ?? "Invalid value"}`);
					return c.textContent = `Invalid configuration:\n${e.join("\n")}`, c.className = "config-status config-invalid", !1;
				}
				return c.textContent = "Valid configuration.", c.className = "config-status config-valid", !0;
			} catch (e) {
				let t = e instanceof Error ? e.message : String(e);
				return c.textContent = `Invalid JSON: ${t}`, c.className = "config-status config-invalid", !1;
			}
		}
		function h() {
			let e = {};
			for (let t of d.keys()) e[t] = i[t];
			s.value = JSON.stringify(e, null, 4), m();
		}
		n.addEventListener("click", () => {
			let n = t.value, r = f[n];
			if (!r || !Rn(i[n]) || d.has(n)) return;
			let a = document.createElement("div");
			a.className = "config-section";
			let o = document.createElement("h3");
			o.textContent = r.title ? `${r.title} (${n})` : n;
			let s = document.createElement("button");
			s.type = "button", s.className = "config-button", s.style.padding = "6px 10px", s.textContent = "Remove", s.setAttribute("aria-label", `Remove section ${n}`), s.addEventListener("click", () => {
				a.remove(), d.delete(n), h();
			});
			let c = document.createElement("div");
			if (c.className = "config-section-header", c.append(o, s), a.appendChild(c), r.description) {
				let e = document.createElement("p");
				e.className = "config-description", e.textContent = r.description, a.appendChild(e);
			}
			let l = document.createElement("p");
			l.className = "config-description", l.textContent = "Using all values from default_config.json.", a.appendChild(l), d.set(n, a), e.appendChild(a), t.value = "", h();
		}), s.addEventListener("input", m), a.addEventListener("click", m), o.addEventListener("click", () => {
			if (!m()) return;
			let e = new Blob([s.value], { type: "application/json" }), t = URL.createObjectURL(e), n = document.createElement("a");
			n.href = t, n.download = "bts_rc.json", document.body.appendChild(n), n.click(), n.remove(), window.setTimeout(() => URL.revokeObjectURL(t), 0);
		}), m();
	} catch (e) {
		c.textContent = `Could not initialize configuration generator: ${e instanceof Error ? e.message : String(e)}`, c.className = "config-status config-invalid", console.error("Configuration generator initialization error:", e);
	}
}
function Ln() {
	return Fn ||= fetch($ ? "/__default_config.json" : "https://raw.githubusercontent.com/Mikk155/bts_rc/main/scripts/maps/bts_rc/default_config.json").then(async (e) => {
		if (!e.ok) throw Error(`Could not load default configuration (${e.status}).`);
		let t = await e.json();
		if (!Rn(t)) throw Error("Default configuration must be a JSON object.");
		return t;
	}), Fn;
}
function Rn(e) {
	return typeof e == "object" && !!e && !Array.isArray(e);
}
function zn(e) {
	if (typeof e.type == "string") return e.type;
	if (Array.isArray(e.type)) return e.type.find((e) => e !== "null");
}
//#endregion
//#region src/main.ts
var $ = window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1";
window.copyCode = f, document.addEventListener("DOMContentLoaded", async () => {
	try {
		y(), In(), await b(), await x(), await v();
	} catch (e) {
		console.error("Initialization error: ", e);
	}
	await S(), _();
});
//#endregion
export { $ as DEV };
