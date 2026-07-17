((cssText, artDataUrl, themeConfig) => {
  const STATE_KEY = "__TRAE_DREAM_SKIN_STATE__";
  const DISABLED_KEY = "__TRAE_DREAM_SKIN_DISABLED__";
  const STYLE_ID = "trae-dream-skin-style";
  const CHROME_ID = "trae-dream-skin-chrome";
  const SHELL_ATTR = "data-trae-dream-shell";
  const THEME_ATTR = "data-trae-dream-theme";
  const VERSION = __TRAE_DREAM_SKIN_VERSION_JSON__;
  const THEME = themeConfig && typeof themeConfig === "object" ? themeConfig : {};
  const VISUAL_STYLE = /^[a-z0-9-]+$/i.test(THEME.visualStyle || "")
    ? THEME.visualStyle
    : "arcade-modern";
  const THEME_VARIABLES = [
    "--tds-bg",
    "--tds-panel",
    "--tds-panel-2",
    "--tds-accent",
    "--tds-accent-2",
    "--tds-secondary",
    "--tds-highlight",
    "--tds-text",
    "--tds-muted",
    "--tds-line",
    "--tds-name",
    "--tds-tagline",
    "--tds-quote",
  ];

  window[DISABLED_KEY] = false;

  const previous = window[STATE_KEY];
  previous?.observer?.disconnect();
  if (previous?.timer) clearInterval(previous.timer);
  if (previous?.scheduler?.timeout) clearTimeout(previous.scheduler.timeout);
  if (previous?.resizeHandler) window.removeEventListener("resize", previous.resizeHandler);
  if (previous?.mediaHandler && previous?.mediaQuery) {
    try {
      previous.mediaQuery.removeEventListener("change", previous.mediaHandler);
    } catch {}
  }
  if (previous?.artUrl) URL.revokeObjectURL(previous.artUrl);

  const artUrl = (() => {
    const comma = artDataUrl.indexOf(",");
    const mime = /^data:([^;,]+)/.exec(artDataUrl)?.[1] || "image/png";
    const binary = atob(artDataUrl.slice(comma + 1));
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index);
    }
    return URL.createObjectURL(new Blob([bytes], { type: mime }));
  })();

  const cssString = (value) => JSON.stringify(String(value ?? ""));

  const detectShellMode = () => {
    const body = document.body;
    if (body?.classList.contains("dark") || body?.classList.contains("hc-black")) return "dark";
    if (body?.classList.contains("light") || body?.classList.contains("hc-light")) return "light";
    try {
      const color = getComputedStyle(body || document.documentElement).backgroundColor;
      const channels = color.match(/[\d.]+/g)?.slice(0, 3).map(Number);
      if (channels?.length === 3) {
        const brightness = channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
        return brightness < 128 ? "dark" : "light";
      }
    } catch {}
    return window.matchMedia?.("(prefers-color-scheme: dark)")?.matches ? "dark" : "light";
  };

  const applyVariables = (root) => {
    const colors = THEME.colors || {};
    root.style.setProperty("--tds-bg", colors.background || "#dff5ff");
    root.style.setProperty("--tds-panel", colors.panel || "#fffef6");
    root.style.setProperty("--tds-panel-2", colors.panelAlt || "#fff6d7");
    root.style.setProperty("--tds-accent", colors.accent || "#e52521");
    root.style.setProperty("--tds-accent-2", colors.accentAlt || "#ff4d45");
    root.style.setProperty("--tds-secondary", colors.secondary || "#049cd8");
    root.style.setProperty("--tds-highlight", colors.highlight || "#fbd000");
    root.style.setProperty("--tds-text", colors.text || "#183153");
    root.style.setProperty("--tds-muted", colors.muted || "#56708f");
    root.style.setProperty("--tds-line", colors.line || "rgba(229, 37, 33, .28)");
    root.style.setProperty("--tds-name", cssString(THEME.name || "TRAE PORTAL"));
    root.style.setProperty("--tds-tagline", cssString(THEME.tagline || "敲下一个任务，开启今天的冒险关卡。"));
    root.style.setProperty("--tds-quote", cssString(THEME.quote || "LET'S-A GO!"));
  };

  const ensureStyle = (root) => {
    let style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      (document.head || root).appendChild(style);
    }
    if (style.dataset.traeDreamVersion !== VERSION || style.textContent !== cssText) {
      style.textContent = cssText;
      style.dataset.traeDreamVersion = VERSION;
    }
  };

  const removeMarkerClasses = (except = {}) => {
    document.querySelectorAll(".tds-sidebar").forEach((node) => {
      if (node !== except.sidebar) node.classList.remove("tds-sidebar");
    });
    document.querySelectorAll(".tds-main").forEach((node) => {
      if (node !== except.panel) node.classList.remove("tds-main", "tds-home-shell");
    });
    document.querySelectorAll(".tds-home").forEach((node) => {
      if (node !== except.home) node.classList.remove("tds-home");
    });
    document.querySelectorAll(".tds-composer").forEach((node) => {
      if (node !== except.composer) node.classList.remove("tds-composer");
    });
  };

  const findShellParts = () => {
    const appRoot = document.querySelector("#solo-lite-root");
    const visible = (node) => {
      if (!node) return false;
      const rect = node.getBoundingClientRect();
      return rect.width > 0 && rect.height > innerHeight * 0.45;
    };
    const layouts = appRoot
      ? [appRoot, ...appRoot.querySelectorAll(":scope > div, :scope > div > div")]
      : [];
    const layout = layouts.find((node) => {
      if (!visible(node) || node.children.length < 2) return false;
      const children = [...node.children].filter(visible);
      return children.length >= 2 &&
        children.some((child) => child.getBoundingClientRect().width > innerWidth * 0.45);
    });
    const layoutChildren = layout ? [...layout.children].filter(visible) : [];
    const sidebar = document.querySelector(".task-list-panel, .task-list-base") ||
      layoutChildren.find((node) => {
        const width = node.getBoundingClientRect().width;
        return width >= 160 && width <= Math.min(520, innerWidth * 0.42);
      });
    const panel = document.querySelector(".panel-container") ||
      layoutChildren.sort((a, b) =>
        b.getBoundingClientRect().width - a.getBoundingClientRect().width
      )[0];
    const composer = document.querySelector(
      ".messageInputContainer, .chat-input-v2-input-box-editable, " +
      "[data-lexical-editor='true'], [contenteditable='true'][role='textbox']"
    );
    return {
      appRoot,
      sidebar,
      panel,
      home: document.querySelector(".initial-chat-panel"),
      composer,
    };
  };

  const ensure = () => {
    if (window[DISABLED_KEY]) return;
    const root = document.documentElement;
    const { appRoot, sidebar, panel, home, composer } = findShellParts();
    if (!root || !appRoot || !sidebar || !panel || !document.body) return;

    root.classList.add("trae-dream-skin");
    root.setAttribute(SHELL_ATTR, detectShellMode());
    root.setAttribute(THEME_ATTR, VISUAL_STYLE);
    root.style.setProperty("--trae-dream-art", `url("${artUrl}")`);
    applyVariables(root);
    ensureStyle(root);

    removeMarkerClasses({ sidebar, panel, home, composer });
    sidebar.classList.add("tds-sidebar");
    panel.classList.add("tds-main");
    panel.classList.toggle("tds-home-shell", Boolean(home));
    home?.classList.add("tds-home");
    composer?.classList.add("tds-composer");

    let chrome = document.getElementById(CHROME_ID);
    if (!chrome || chrome.parentElement !== document.body) {
      chrome?.remove();
      chrome = document.createElement("div");
      chrome.id = CHROME_ID;
      chrome.setAttribute("aria-hidden", "true");
      chrome.innerHTML = `
        <div class="tds-brand">
          <span class="tds-brand-mark"><i></i></span>
          <span><b></b><small></small></span>
        </div>
        <div class="tds-status"><i></i><span></span></div>
        <div class="tds-quote"></div>
        <div class="tds-orbit"><i></i><i></i><i></i></div>
        <div class="tds-particles"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
        <div class="tds-scanline"></div>`;
      document.body.appendChild(chrome);
    }

    chrome.querySelector(".tds-brand b").textContent = THEME.name || "TRAE PORTAL";
    chrome.querySelector(".tds-brand small").textContent = THEME.brandSubtitle || "TRAE WORK · POWER-UP MODE";
    chrome.querySelector(".tds-status span").textContent = THEME.statusText || "PLAYER 1 READY";
    chrome.querySelector(".tds-quote").textContent = THEME.quote || "LET'S-A GO!";
    chrome.classList.toggle("tds-home-shell", Boolean(home));
    chrome.dataset.traeDreamShell = detectShellMode();
    chrome.dataset.traeDreamTheme = VISUAL_STYLE;

    const panelBox = panel.getBoundingClientRect();
    chrome.style.left = `${Math.round(panelBox.left)}px`;
    chrome.style.top = `${Math.round(panelBox.top)}px`;
    chrome.style.width = `${Math.round(panelBox.width)}px`;
    chrome.style.height = `${Math.round(panelBox.height)}px`;
  };

  const cleanup = () => {
    window[DISABLED_KEY] = true;
    document.documentElement?.classList.remove("trae-dream-skin");
    document.documentElement?.removeAttribute(SHELL_ATTR);
    document.documentElement?.removeAttribute(THEME_ATTR);
    document.documentElement?.style.removeProperty("--trae-dream-art");
    for (const name of THEME_VARIABLES) document.documentElement?.style.removeProperty(name);
    removeMarkerClasses();
    document.getElementById(STYLE_ID)?.remove();
    document.getElementById(CHROME_ID)?.remove();
    const state = window[STATE_KEY];
    state?.observer?.disconnect();
    if (state?.timer) clearInterval(state.timer);
    if (state?.scheduler?.timeout) clearTimeout(state.scheduler.timeout);
    if (state?.resizeHandler) window.removeEventListener("resize", state.resizeHandler);
    if (state?.mediaHandler && state?.mediaQuery) {
      try {
        state.mediaQuery.removeEventListener("change", state.mediaHandler);
      } catch {}
    }
    if (state?.artUrl) URL.revokeObjectURL(state.artUrl);
    delete window[STATE_KEY];
    return true;
  };

  const scheduler = { timeout: null };
  const scheduleEnsure = () => {
    if (scheduler.timeout) clearTimeout(scheduler.timeout);
    scheduler.timeout = setTimeout(() => {
      scheduler.timeout = null;
      ensure();
    }, 180);
  };
  const observer = new MutationObserver(scheduleEnsure);
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["class", "data-theme"],
  });
  const timer = setInterval(ensure, 4000);
  const resizeHandler = scheduleEnsure;
  window.addEventListener("resize", resizeHandler, { passive: true });

  let mediaQuery = null;
  let mediaHandler = null;
  try {
    mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    mediaHandler = scheduleEnsure;
    mediaQuery.addEventListener("change", mediaHandler);
  } catch {}

  window[STATE_KEY] = {
    ensure,
    cleanup,
    observer,
    timer,
    scheduler,
    resizeHandler,
    mediaQuery,
    mediaHandler,
    artUrl,
    version: VERSION,
    themeId: THEME.id || "custom",
    detectShellMode,
  };
  ensure();
  return {
    installed: true,
    version: VERSION,
    themeId: THEME.id || "custom",
    shell: detectShellMode(),
  };
})(
  __TRAE_DREAM_SKIN_CSS_JSON__,
  __TRAE_DREAM_SKIN_ART_JSON__,
  __TRAE_DREAM_SKIN_THEME_JSON__
)
