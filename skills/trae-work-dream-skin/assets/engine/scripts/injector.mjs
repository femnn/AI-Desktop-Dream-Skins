import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const SKIN_VERSION = "0.2.0";
const LOOPBACK_HOSTS = new Set(["127.0.0.1", "localhost", "[::1]"]);
const MAX_ART_BYTES = 16 * 1024 * 1024;

function parseArgs(argv) {
  const options = {
    port: 9355,
    mode: "watch",
    timeoutMs: 30000,
    screenshot: null,
    reload: false,
    themeDir: null,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--port") options.port = Number(argv[++index]);
    else if (arg === "--once") options.mode = "once";
    else if (arg === "--watch") options.mode = "watch";
    else if (arg === "--verify") options.mode = "verify";
    else if (arg === "--remove") options.mode = "remove";
    else if (arg === "--check-payload") options.mode = "check";
    else if (arg === "--timeout-ms") options.timeoutMs = Number(argv[++index]);
    else if (arg === "--screenshot") options.screenshot = path.resolve(argv[++index]);
    else if (arg === "--theme-dir") options.themeDir = path.resolve(argv[++index]);
    else if (arg === "--reload") options.reload = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!Number.isInteger(options.port) || options.port < 1024 || options.port > 65535) {
    throw new Error(`Invalid port: ${options.port}`);
  }
  if (!Number.isFinite(options.timeoutMs) || options.timeoutMs < 250 || options.timeoutMs > 120000) {
    throw new Error(`Invalid timeout: ${options.timeoutMs}`);
  }
  return options;
}

function validatedDebuggerUrl(target, port) {
  const url = new URL(target.webSocketDebuggerUrl);
  if (url.protocol !== "ws:" || !LOOPBACK_HOSTS.has(url.hostname) || Number(url.port) !== port) {
    throw new Error(`Rejected non-loopback CDP WebSocket URL: ${url.href}`);
  }
  return url.href;
}

function isExpectedRendererUrl(value) {
  try {
    const url = new URL(value);
    if (url.protocol !== "vscode-file:" || url.hostname !== "vscode-app") return false;
    const pathname = decodeURIComponent(url.pathname);
    return pathname.endsWith("/out/vs/code/electron-browser/solo/solo-lite.html");
  } catch {
    return false;
  }
}

class CdpSession {
  constructor(target, port) {
    this.target = target;
    this.ws = new WebSocket(validatedDebuggerUrl(target, port));
    this.nextId = 1;
    this.pending = new Map();
    this.listeners = new Map();
    this.closed = false;
  }

  async open() {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error("CDP WebSocket open timed out")), 5000);
      this.ws.addEventListener("open", () => {
        clearTimeout(timeout);
        resolve();
      }, { once: true });
      this.ws.addEventListener("error", () => {
        clearTimeout(timeout);
        reject(new Error("CDP WebSocket open failed"));
      }, { once: true });
    });
    this.ws.addEventListener("message", (event) => this.onMessage(event));
    this.ws.addEventListener("close", () => {
      this.closed = true;
      for (const waiter of this.pending.values()) {
        clearTimeout(waiter.timeout);
        waiter.reject(new Error("CDP socket closed"));
      }
      this.pending.clear();
    });
    await this.send("Runtime.enable");
    await this.send("Page.enable");
    return this;
  }

  onMessage(event) {
    const message = JSON.parse(String(event.data));
    if (message.id) {
      const waiter = this.pending.get(message.id);
      if (!waiter) return;
      clearTimeout(waiter.timeout);
      this.pending.delete(message.id);
      if (message.error) waiter.reject(new Error(`${message.error.message} (${message.error.code})`));
      else waiter.resolve(message.result);
      return;
    }
    for (const listener of this.listeners.get(message.method) ?? []) listener(message.params ?? {});
  }

  on(method, listener) {
    const listeners = this.listeners.get(method) ?? [];
    listeners.push(listener);
    this.listeners.set(method, listeners);
  }

  send(method, params = {}) {
    if (this.closed) return Promise.reject(new Error("CDP session is closed"));
    return new Promise((resolve, reject) => {
      const id = this.nextId++;
      const timeout = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`CDP command timed out: ${method}`));
      }, 10000);
      this.pending.set(id, { resolve, reject, timeout });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async evaluate(expression) {
    const result = await this.send("Runtime.evaluate", {
      expression,
      awaitPromise: true,
      returnByValue: true,
      userGesture: false,
    });
    if (result.exceptionDetails) {
      const detail = result.exceptionDetails.exception?.description ?? result.exceptionDetails.text;
      throw new Error(`Renderer evaluation failed: ${detail}`);
    }
    return result.result?.value;
  }

  close() {
    if (!this.closed) this.ws.close();
    this.closed = true;
  }
}

async function listExpectedTargets(port) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 2000);
  try {
    const response = await fetch(`http://127.0.0.1:${port}/json/list`, { signal: controller.signal });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const targets = await response.json();
    return targets.filter((item) => {
      if (item.type !== "page" || !isExpectedRendererUrl(item.url) || !item.webSocketDebuggerUrl) return false;
      try {
        validatedDebuggerUrl(item, port);
        return true;
      } catch {
        return false;
      }
    });
  } finally {
    clearTimeout(timeout);
  }
}

async function probeSession(session) {
  return session.evaluate(`(() => {
    const root = document.querySelector('#solo-lite-root');
    const visible = (node) => {
      if (!node) return false;
      const rect = node.getBoundingClientRect();
      return rect.width > 0 && rect.height > innerHeight * .45;
    };
    const layouts = root
      ? [root, ...root.querySelectorAll(':scope > div, :scope > div > div')]
      : [];
    const layout = layouts.find((node) => {
      if (!visible(node) || node.children.length < 2) return false;
      const children = [...node.children].filter(visible);
      return children.length >= 2 && children.some((child) => child.getBoundingClientRect().width > innerWidth * .45);
    });
    const layoutChildren = layout ? [...layout.children].filter(visible) : [];
    const sidebar = document.querySelector('.task-list-panel, .task-list-base') ??
      layoutChildren.find((node) => {
        const width = node.getBoundingClientRect().width;
        return width >= 160 && width <= Math.min(520, innerWidth * .42);
      });
    const panel = document.querySelector('.panel-container') ??
      layoutChildren.sort((a, b) => b.getBoundingClientRect().width - a.getBoundingClientRect().width)[0];
    const composer = document.querySelector(
      '.messageInputContainer, .chat-input-v2-input-box-editable, [data-lexical-editor="true"], [contenteditable="true"][role="textbox"]'
    );
    const markers = {
      root: Boolean(root),
      sidebar: Boolean(sidebar),
      panel: Boolean(panel),
      composer: Boolean(composer),
    };
    return {
      title: document.title,
      href: location.href,
      markers,
      traeWork: markers.root && markers.sidebar && markers.panel,
    };
  })()`);
}

async function connectTarget(target, port) {
  return new CdpSession(target, port).open();
}

async function connectTraeTargets(port, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let lastError;
  while (Date.now() < deadline) {
    try {
      const targets = await listExpectedTargets(port);
      const connected = [];
      for (const target of targets) {
        let session;
        try {
          session = await connectTarget(target, port);
          const probe = await probeSession(session);
          if (probe?.traeWork) connected.push({ target, session, probe });
          else session.close();
        } catch (error) {
          session?.close();
          lastError = error;
        }
      }
      if (connected.length) return connected;
      lastError = new Error("No page matched the expected TRAE Work shell markers");
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolve) => setTimeout(resolve, 350));
  }
  throw new Error(`No verified TRAE Work renderer on 127.0.0.1:${port}: ${lastError?.message ?? "timed out"}`);
}

async function loadTheme(themeDir) {
  const defaultAssetsRoot = path.join(root, "assets");
  let assetsRoot = defaultAssetsRoot;
  if (themeDir) {
    try {
      await fs.access(path.join(themeDir, "theme.json"));
      assetsRoot = themeDir;
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }

  const configPath = path.join(assetsRoot, "theme.json");
  const raw = JSON.parse(await fs.readFile(configPath, "utf8"));
  if (raw.schemaVersion !== 1 || typeof raw.image !== "string" || !raw.image) {
    throw new Error(`${configPath} has an unsupported schema or image field`);
  }
  if (path.basename(raw.image) !== raw.image) {
    throw new Error("Theme image must stay inside its theme directory");
  }

  const text = (value, fallback, max) => typeof value === "string" && value.trim()
    ? value.trim().slice(0, max)
    : fallback;
  const color = (value, fallback) => {
    if (typeof value !== "string") return fallback;
    const normalized = value.trim();
    return /^#[0-9a-f]{6}$/i.test(normalized) || /^rgba?\([0-9., %]+\)$/i.test(normalized)
      ? normalized
      : fallback;
  };
  const visualStyle = text(raw.visualStyle, "arcade-modern", 80);
  const theme = {
    schemaVersion: 1,
    id: text(raw.id, "custom", 80),
    name: text(raw.name, "TRAE PORTAL", 80),
    visualStyle: /^[a-z0-9-]+$/i.test(visualStyle) ? visualStyle : "arcade-modern",
    brandSubtitle: text(raw.brandSubtitle, "TRAE WORK · POWER-UP MODE", 80),
    tagline: text(raw.tagline, "敲下一个任务，开启今天的冒险关卡。", 160),
    statusText: text(raw.statusText, "PLAYER 1 READY", 80),
    quote: text(raw.quote, "LET'S-A GO!", 80),
    image: raw.image,
    colors: {
      background: color(raw.colors?.background, "#dff5ff"),
      panel: color(raw.colors?.panel, "#fffef6"),
      panelAlt: color(raw.colors?.panelAlt, "#fff6d7"),
      accent: color(raw.colors?.accent, "#e52521"),
      accentAlt: color(raw.colors?.accentAlt, "#ff4d45"),
      secondary: color(raw.colors?.secondary, "#049cd8"),
      highlight: color(raw.colors?.highlight, "#fbd000"),
      text: color(raw.colors?.text, "#183153"),
      muted: color(raw.colors?.muted, "#56708f"),
      line: color(raw.colors?.line, "rgba(229, 37, 33, .28)"),
    },
  };

  const imagePath = path.join(assetsRoot, theme.image);
  const imageStat = await fs.stat(imagePath);
  if (!imageStat.isFile() || imageStat.size < 1 || imageStat.size > MAX_ART_BYTES) {
    throw new Error(`Theme image must be a non-empty file no larger than ${MAX_ART_BYTES} bytes`);
  }
  const extension = path.extname(theme.image).toLowerCase();
  if (![".png", ".jpg", ".jpeg", ".webp"].includes(extension)) {
    throw new Error(`Unsupported theme image format: ${extension || "missing"}`);
  }
  return { imagePath, theme };
}

async function loadPayload(themeDir) {
  const [css, template, loaded] = await Promise.all([
    fs.readFile(path.join(root, "assets", "dream-skin.css"), "utf8"),
    fs.readFile(path.join(root, "assets", "renderer-inject.js"), "utf8"),
    loadTheme(themeDir),
  ]);
  const art = await fs.readFile(loaded.imagePath);
  const extension = path.extname(loaded.imagePath).toLowerCase();
  const mime = extension === ".jpg" || extension === ".jpeg"
    ? "image/jpeg"
    : extension === ".webp"
      ? "image/webp"
      : "image/png";
  const artDataUrl = `data:${mime};base64,${art.toString("base64")}`;
  const payload = template
    .replace("__TRAE_DREAM_SKIN_CSS_JSON__", JSON.stringify(css))
    .replace("__TRAE_DREAM_SKIN_ART_JSON__", JSON.stringify(artDataUrl))
    .replace("__TRAE_DREAM_SKIN_THEME_JSON__", JSON.stringify(loaded.theme))
    .replace("__TRAE_DREAM_SKIN_VERSION_JSON__", JSON.stringify(SKIN_VERSION));
  return {
    imageBytes: art.length,
    payload,
    theme: loaded.theme,
  };
}

async function applyToSession(session, payload) {
  return session.evaluate(payload);
}

async function removeFromSession(session) {
  return session.evaluate(`(() => {
    window.__TRAE_DREAM_SKIN_DISABLED__ = true;
    const state = window.__TRAE_DREAM_SKIN_STATE__;
    if (state?.cleanup) return state.cleanup();
    document.documentElement?.classList.remove('trae-dream-skin');
    document.documentElement?.removeAttribute('data-trae-dream-shell');
    document.documentElement?.removeAttribute('data-trae-dream-theme');
    document.documentElement?.style.removeProperty('--trae-dream-art');
    document.getElementById('trae-dream-skin-style')?.remove();
    document.getElementById('trae-dream-skin-chrome')?.remove();
    delete window.__TRAE_DREAM_SKIN_STATE__;
    return true;
  })()`);
}

async function verifyRemovedSession(session) {
  return session.evaluate(`(() =>
    !document.documentElement.classList.contains('trae-dream-skin') &&
    !document.getElementById('trae-dream-skin-style') &&
    !document.getElementById('trae-dream-skin-chrome') &&
    !window.__TRAE_DREAM_SKIN_STATE__
  )()`);
}

async function verifySession(session) {
  return session.evaluate(`(() => {
    const box = (node) => {
      if (!node) return null;
      const rect = node.getBoundingClientRect();
      const style = getComputedStyle(node);
      return {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        visible: rect.width > 0 && rect.height > 0 &&
          style.display !== 'none' && style.visibility !== 'hidden',
        pointerEvents: style.pointerEvents,
      };
    };
    const root = document.querySelector('#solo-lite-root');
    const visible = (node) => {
      if (!node) return false;
      const rect = node.getBoundingClientRect();
      return rect.width > 0 && rect.height > innerHeight * .45;
    };
    const layouts = root
      ? [root, ...root.querySelectorAll(':scope > div, :scope > div > div')]
      : [];
    const layout = layouts.find((node) => {
      if (!visible(node) || node.children.length < 2) return false;
      const children = [...node.children].filter(visible);
      return children.length >= 2 && children.some((child) => child.getBoundingClientRect().width > innerWidth * .45);
    });
    const layoutChildren = layout ? [...layout.children].filter(visible) : [];
    const sidebar = document.querySelector('.task-list-panel, .task-list-base') ??
      layoutChildren.find((node) => {
        const width = node.getBoundingClientRect().width;
        return width >= 160 && width <= Math.min(520, innerWidth * .42);
      });
    const panel = document.querySelector('.panel-container') ??
      layoutChildren.sort((a, b) => b.getBoundingClientRect().width - a.getBoundingClientRect().width)[0];
    const composer = document.querySelector(
      '.messageInputContainer, .chat-input-v2-input-box-editable, [data-lexical-editor="true"], [contenteditable="true"][role="textbox"]'
    );
    const home = document.querySelector('.initial-chat-panel');
    const chrome = document.getElementById('trae-dream-skin-chrome');
    const style = document.getElementById('trae-dream-skin-style');
    const result = {
      installed: document.documentElement.classList.contains('trae-dream-skin'),
      version: window.__TRAE_DREAM_SKIN_STATE__?.version ?? null,
      visualStyle: document.documentElement.getAttribute('data-trae-dream-theme'),
      stylePresent: Boolean(style),
      chromePresent: Boolean(chrome),
      chromePointerEvents: getComputedStyle(chrome || document.body).pointerEvents,
      root: box(root),
      sidebar: box(sidebar),
      panel: box(panel),
      composer: box(composer),
      home: box(home),
      nativeButtons: root?.querySelectorAll('button').length ?? 0,
      viewport: { width: innerWidth, height: innerHeight },
      documentOverflow: {
        x: document.documentElement.scrollWidth > document.documentElement.clientWidth,
        y: document.documentElement.scrollHeight > document.documentElement.clientHeight,
      },
    };
    result.pass = Boolean(
      result.installed &&
      result.version === ${JSON.stringify(SKIN_VERSION)} &&
      result.stylePresent &&
      result.chromePresent &&
      result.chromePointerEvents === 'none' &&
      result.root?.visible &&
      result.sidebar?.visible &&
      result.panel?.visible &&
      result.composer?.visible &&
      result.composer.pointerEvents !== 'none' &&
      result.nativeButtons >= 3 &&
      !result.documentOverflow.x
    );
    return result;
  })()`);
}

async function waitForVerifiedSession(session, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let lastResult;
  while (Date.now() < deadline) {
    lastResult = await verifySession(session);
    if (lastResult.pass) return lastResult;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  return lastResult;
}

async function capture(session, outputPath) {
  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await session.send("Input.dispatchKeyEvent", {
    type: "keyDown",
    key: "Escape",
    code: "Escape",
    windowsVirtualKeyCode: 27,
  });
  await session.send("Input.dispatchKeyEvent", {
    type: "keyUp",
    key: "Escape",
    code: "Escape",
    windowsVirtualKeyCode: 27,
  });
  const viewport = await session.evaluate("({ width: innerWidth, height: innerHeight })");
  await session.send("Input.dispatchMouseEvent", {
    type: "mouseMoved",
    x: Math.round(viewport.width * 0.72),
    y: Math.round(viewport.height * 0.78),
    button: "none",
  });
  await new Promise((resolve) => setTimeout(resolve, 300));
  const result = await session.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: false,
  });
  await fs.writeFile(outputPath, Buffer.from(result.data, "base64"));
}

async function runOneShot(options) {
  const connected = await connectTraeTargets(options.port, options.timeoutMs);
  const loaded = (options.mode === "once" || options.reload)
    ? await loadPayload(options.themeDir)
    : null;
  const results = [];
  let screenshotCaptured = false;

  for (const { target, session, probe } of connected) {
    try {
      if (options.mode === "remove") await removeFromSession(session);
      else if (options.mode === "once") await applyToSession(session, loaded.payload);

      if (options.reload) {
        await session.send("Page.reload", { ignoreCache: true });
        await new Promise((resolve) => setTimeout(resolve, 1800));
        if (options.mode !== "remove") await applyToSession(session, loaded.payload);
      }

      const result = options.mode === "remove"
        ? await verifyRemovedSession(session)
        : await waitForVerifiedSession(session, options.timeoutMs);
      results.push({
        targetId: target.id,
        title: target.title,
        url: target.url,
        probe,
        result,
      });

      if (options.screenshot && !screenshotCaptured) {
        await capture(session, options.screenshot);
        screenshotCaptured = true;
      }
    } finally {
      session.close();
    }
  }

  console.log(JSON.stringify({
    mode: options.mode,
    version: SKIN_VERSION,
    port: options.port,
    targets: results,
  }, null, 2));
  const failed = results.length === 0 || results.some((item) =>
    options.mode === "remove" ? item.result !== true : !item.result?.pass
  );
  if (failed) process.exitCode = 2;
}

async function runWatch(options) {
  const { payload } = await loadPayload(options.themeDir);
  const sessions = new Map();
  const rejected = new Set();
  let stopping = false;
  const stop = () => { stopping = true; };
  process.on("SIGINT", stop);
  process.on("SIGTERM", stop);

  while (!stopping) {
    let targets = [];
    try {
      targets = await listExpectedTargets(options.port);
    } catch (error) {
      console.error(`[trae-dream-skin] ${new Date().toISOString()} ${error.message}`);
      await new Promise((resolve) => setTimeout(resolve, 1000));
      continue;
    }

    const activeIds = new Set(targets.map((target) => target.id));
    for (const [id, session] of sessions) {
      if (!activeIds.has(id) || session.closed) {
        session.close();
        sessions.delete(id);
      }
    }

    for (const target of targets) {
      if (sessions.has(target.id)) continue;
      let session;
      try {
        session = await connectTarget(target, options.port);
        const probe = await probeSession(session);
        if (!probe?.traeWork) {
          session.close();
          if (!rejected.has(target.id)) {
            console.error(`[trae-dream-skin] rejected unverified renderer ${target.id}`);
            rejected.add(target.id);
          }
          continue;
        }
        rejected.delete(target.id);
        session.on("Page.loadEventFired", () => {
          setTimeout(() => applyToSession(session, payload).catch((error) => {
            console.error(`[trae-dream-skin] reinject failed: ${error.message}`);
          }), 300);
        });
        await applyToSession(session, payload);
        sessions.set(target.id, session);
        console.log(`[trae-dream-skin] injected verified TRAE Work target ${target.id}`);
      } catch (error) {
        session?.close();
        console.error(`[trae-dream-skin] inject failed for ${target.id}: ${error.message}`);
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 900));
  }

  for (const session of sessions.values()) session.close();
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.mode === "check") {
    const loaded = await loadPayload(options.themeDir);
    console.log(JSON.stringify({
      pass: true,
      version: SKIN_VERSION,
      themeId: loaded.theme.id,
      themeName: loaded.theme.name,
      visualStyle: loaded.theme.visualStyle,
      imageBytes: loaded.imageBytes,
      payloadBytes: Buffer.byteLength(loaded.payload),
    }, null, 2));
  } else if (options.mode === "watch") {
    await runWatch(options);
  } else {
    await runOneShot(options);
  }
} catch (error) {
  console.error(`[trae-dream-skin] ${error.stack || error.message}`);
  process.exitCode = 1;
}
