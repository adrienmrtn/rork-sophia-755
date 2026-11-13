// Shared chrome for the screen recreations: status bar, home indicator, tab bar.
// Usage, at the end of <body>:
//   <script src="../kit.js"></script>
//   <script>Kit.chrome({ status: "dark", tab: "home" })</script>
// status: "dark" (black glyphs, default) | "light" (white glyphs) | false
// tab:    "home" | "explore" | "duels" | "profile" | undefined (no tab bar)
// indicator: "dark" | "light" | false (defaults to the status value)
const Kit = (() => {
  // ?device=ipad switches the page to the iPad variant (see kit.css). Kit.ipad tells a screen which one it is.
  const ipad = new URLSearchParams(location.search).get("device") === "ipad";
  if (ipad) document.documentElement.classList.add("ipad");
  // The status bar date in the page's language (French and English keep their fixed form).
  const ipadDate = () => {
    const lang = new URLSearchParams(location.search).get("lang") || "fr";
    if (lang === "fr") return "Mar. 9 janv.";
    if (lang === "en") return "Tue Jan 9";
    try { return new Date(2024, 0, 9).toLocaleDateString(lang, { weekday: "short", month: "short", day: "numeric" }); }
    catch (e) { return "Tue Jan 9"; }
  };
  const statusHTML = `
    <span class="time">9:41</span>
    <span class="right">
      <svg width="19" height="12" viewBox="0 0 19 12"><rect x="0" y="8" width="3.2" height="4" rx="1"/><rect x="5.2" y="5.5" width="3.2" height="6.5" rx="1"/><rect x="10.4" y="3" width="3.2" height="9" rx="1"/><rect x="15.6" y="0" width="3.2" height="12" rx="1"/></svg>
      <svg width="17" height="12" viewBox="0 0 17 12"><path d="M8.5 2.6c2.3 0 4.4.9 6 2.4.2.2.5.2.6 0l.9-.9c.2-.2.2-.5 0-.7A10.9 10.9 0 0 0 8.5.4C5.7.4 3.1 1.5 1 3.400c-.2.2-.2.5 0 .7l.9.9c.2.2.4.2.6 0a8.7 8.7 0 0 1 6-2.400Zm0 3.800c1.3 0 2.4.5 3.3 1.3.2.2.5.2.6 0l.9-.9c.2-.2.2-.5 0-.7a7 7 0 0 0-9.6 0c-.2.2-.2.5 0 .7l.9.9c.2.2.4.2.6 0 .9-.8 2-1.3 3.3-1.300Zm2.2 3.200c.2-.2.2-.5 0-.7a3.3 3.3 0 0 0-4.4 0c-.2.2-.2.5 0 .7l1.9 1.900c.2.2.4.2.6 0l1.9-1.900Z"/></svg>
      <svg width="27" height="13" viewBox="0 0 27 13"><rect x="0.5" y="0.5" width="23" height="12" rx="3.8" fill="none" stroke="currentColor" opacity="0.4"/><rect x="2" y="2" width="20" height="9" rx="2.5"/><path d="M25 4.500v4c.8-.3 1.5-1.1 1.5-2s-.7-1.7-1.5-2Z" opacity="0.45"/></svg>
    </span>`;

  // Hand-drawn stand-ins for the SF Symbols house / safari / trophy / person
  // (outline when idle, filled when selected, like a SwiftUI Tab).
  const icons = {
    home: {
      off: `<svg viewBox="0 0 28 28" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round"><path d="M4.5 12.8 14 4.800l9.5 8"/><path d="M6.8 11.200V22a1 1 0 0 0 1 1h3.700v-6h5v6h3.700a1 1 0 0 0 1-1V11.2"/></svg>`,
      on: `<svg viewBox="0 0 28 28" fill="currentColor"><path d="M14.7 3.900a1.1 1.1 0 0 0-1.4 0L3.6 12.100a.95.95 0 0 0 1.230 1.450l.97-.82V22c0 1.1.9 2 2 2h3.400v-5.600c0-.5.4-.9.9-.9h3.800c.5 0 .9.4.9.900V24h3.400a2 2 0 0 0 2-2v-9.270l.97.82a.95.95 0 0 0 1.230-1.450L14.7 3.900Z"/></svg>`,
    },
    explore: {
      off: `<svg viewBox="0 0 28 28" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linejoin="round"><circle cx="14" cy="14" r="10"/><path d="m17.8 10.2-2.3 5.3-5.3 2.3 2.3-5.3 5.3-2.300Z"/></svg>`,
      on: `<svg viewBox="0 0 28 28" fill="currentColor"><path fill-rule="evenodd" d="M14 3a11 11 0 1 0 0 22 11 11 0 0 0 0-22Zm4.7 6.9-2.5 5.800a1 1 0 0 1-.5.500l-5.8 2.500a.5.5 0 0 1-.6-.6l2.5-5.800a1 1 0 0 1 .5-.5l5.8-2.500a.5.5 0 0 1 .6.600ZM14 15.300a1.3 1.3 0 1 0 0-2.6 1.3 1.3 0 0 0 0 2.600Z"/></svg>`,
    },
    duels: {
      off: `<svg viewBox="0 0 28 28" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round"><path d="M9 5h10v6.500a5 5 0 0 1-10 0V5Z"/><path d="M9 7H5.500v1.500A3.5 3.5 0 0 0 9 12M19 7h3.500v1.500A3.5 3.5 0 0 1 19 12"/><path d="M14 16.500V20M10 23h8M11 20h6v3h-6z"/></svg>`,
      on: `<svg viewBox="0 0 28 28" fill="currentColor"><path d="M8 4.900c0-.5.4-.9.9-.9h10.200c.5 0 .9.4.9.900V6h2.600c.5 0 .9.4.9.900v1.600a4.5 4.5 0 0 1-3.9 4.460A6 6 0 0 1 15 16.900V19h1.600c.8 0 1.4.6 1.4 1.400V22h.6a.95.95 0 0 1 0 1.900H9.400a.95.95 0 0 1 0-1.900h.6v-1.600c0-.8.6-1.4 1.4-1.400H13v-2.100a6 6 0 0 1-4.6-3.940A4.5 4.5 0 0 1 4.5 8.500V6.900c0-.5.4-.9.9-.9H8V4.900Zm0 3H6.400v.6c0 1.1.7 2.1 1.6 2.450V7.900Zm12 3.050a2.6 2.6 0 0 0 1.6-2.450v-.6H20v3.050Z"/></svg>`,
    },
    profile: {
      off: `<svg viewBox="0 0 28 28" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><circle cx="14" cy="9.5" r="4.3"/><path d="M5.5 23c.6-4.2 4.2-6.5 8.5-6.500s7.9 2.3 8.5 6.5"/></svg>`,
      on: `<svg viewBox="0 0 28 28" fill="currentColor"><circle cx="14" cy="9.3" r="5.1"/><path d="M14 15.800c-5 0-8.9 2.7-9.5 7 -.1.7.4 1.2 1.1 1.200h16.800c.7 0 1.2-.5 1.1-1.2-.6-4.3-4.5-7-9.5-7Z"/></svg>`,
    },
  };
  const labels = { home: "Accueil", explore: "Explorer", duels: "Duels", profile: "Profil" };

  function chrome({ status = "dark", tab, indicator, tabLabels } = {}) {
    const names = Object.assign({}, labels, tabLabels || {});
    if (status) {
      const el = document.createElement("div");
      el.className = "k-status" + (status === "light" ? " light" : "");
      el.innerHTML = ipad
        ? statusHTML.replace('<span class="time">9:41</span>', `<span class="left"><span class="time">9:41</span><span class="date">${ipadDate()}</span></span>`)
        : statusHTML;
      document.body.appendChild(el);
    }
    if (tab) {
      const bar = document.createElement("div");
      bar.className = "k-tabbar";
      bar.innerHTML = ["home", "explore", "duels", "profile"].map((k) =>
        `<div class="tab${k === tab ? " on" : ""}">${icons[k][k === tab ? "on" : "off"]}<span>${names[k]}</span></div>`
      ).join("");
      document.body.appendChild(bar);
    }
    const ind = indicator === undefined ? (tab ? "dark" : status || "dark") : indicator;
    if (ind) {
      const hi = document.createElement("div");
      hi.className = "k-home-indicator" + (ind === "light" ? " light" : "");
      document.body.appendChild(hi);
    }
  }
  return { chrome, icons, ipad };
})();
