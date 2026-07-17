import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const [mode, ...args] = process.argv.slice(2);

function valueFor(name, fallback = "") {
  const index = args.indexOf(`--${name}`);
  if (index < 0) return fallback;
  const value = args[index + 1];
  if (!value || value.startsWith("--")) throw new Error(`Missing value for --${name}`);
  return value;
}

function validateHex(value, name) {
  if (!/^#[0-9a-f]{6}$/i.test(value)) throw new Error(`${name} must be a six-digit hex color.`);
  return value.toLowerCase();
}

function hexToRgba(hex, alpha) {
  const value = Number.parseInt(hex.slice(1), 16);
  return `rgba(${value >> 16}, ${(value >> 8) & 255}, ${value & 255}, ${alpha})`;
}

async function atomicWrite(file, value) {
  await fs.mkdir(path.dirname(file), { recursive: true, mode: 0o700 });
  const temporary = `${file}.${process.pid}.tmp`;
  try {
    await fs.writeFile(temporary, value, { mode: 0o600 });
    await fs.rename(temporary, file);
    await fs.chmod(file, 0o600);
  } finally {
    await fs.rm(temporary, { force: true }).catch(() => {});
  }
}

async function replaceDirectory(target, populate) {
  const staging = `${target}.${process.pid}.tmp`;
  const previous = `${target}.${process.pid}.previous`;
  await fs.rm(staging, { recursive: true, force: true });
  await fs.rm(previous, { recursive: true, force: true });
  await fs.mkdir(path.dirname(target), { recursive: true, mode: 0o700 });
  await fs.mkdir(staging, { recursive: true, mode: 0o700 });
  await populate(staging);

  let movedPrevious = false;
  try {
    await fs.rename(target, previous);
    movedPrevious = true;
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }

  try {
    await fs.rename(staging, target);
  } catch (error) {
    if (movedPrevious) await fs.rename(previous, target).catch(() => {});
    throw error;
  }
  await fs.rm(previous, { recursive: true, force: true });
}

const outputDir = path.resolve(valueFor("output-dir", path.join(root, "assets")));
const themePath = path.join(outputDir, "theme.json");

if (mode === "reset-demo") {
  if (outputDir === path.join(root, "assets")) {
    throw new Error("Refusing to delete bundled demo assets; pass a user --output-dir.");
  }
  await fs.rm(outputDir, { recursive: true, force: true });
  console.log("Restored the bundled TRAE portal demo preset.");
  process.exit(0);
}

if (mode === "preset") {
  if (outputDir === path.join(root, "assets")) {
    throw new Error("Refusing to overwrite bundled assets; pass a user --output-dir.");
  }
  const preset = valueFor("preset");
  if (!/^[a-z0-9-]+$/i.test(preset)) {
    throw new Error("preset must contain only letters, numbers, and hyphens.");
  }
  const presetDir = path.join(root, "presets", preset);
  const presetThemePath = path.join(presetDir, "theme.json");
  const presetTheme = JSON.parse(await fs.readFile(presetThemePath, "utf8"));
  const image = path.basename(String(presetTheme.image || ""));
  if (!/\.(?:png|jpe?g|webp)$/i.test(image)) {
    throw new Error(`Preset ${preset} has an invalid image filename.`);
  }
  const imagePath = path.join(presetDir, image);
  const imageStat = await fs.stat(imagePath);
  if (!imageStat.isFile() || imageStat.size < 1 || imageStat.size > 16 * 1024 * 1024) {
    throw new Error(`Preset ${preset} image must be non-empty and no larger than 16 MB.`);
  }

  await replaceDirectory(outputDir, async (staging) => {
    const stagedImage = path.join(staging, image);
    await fs.copyFile(imagePath, stagedImage);
    await fs.chmod(stagedImage, 0o600);
    await atomicWrite(path.join(staging, "theme.json"), `${JSON.stringify(presetTheme, null, 2)}\n`);
  });
  console.log(`Applied bundled preset “${presetTheme.name || preset}”.`);
  process.exit(0);
}

if (mode !== "custom") {
  throw new Error(
    "Usage: write-theme.mjs custom [options] | " +
    "preset --preset <name> --output-dir <dir> | reset-demo --output-dir <dir>"
  );
}

const image = path.basename(valueFor("image", "background.jpg"));
if (!/\.(?:png|jpe?g|webp)$/i.test(image)) {
  throw new Error("image must be a PNG, JPEG, or WebP filename.");
}
const imagePath = path.join(outputDir, image);
const imageStat = await fs.stat(imagePath);
if (!imageStat.isFile() || imageStat.size < 1 || imageStat.size > 16 * 1024 * 1024) {
  throw new Error("The prepared theme image must be non-empty and no larger than 16 MB.");
}

const name = valueFor("name", "我的 TRAE 主题").trim().slice(0, 80);
const tagline = valueFor("tagline", "敲下一个任务，让灵感开始流动。").trim().slice(0, 160);
const quote = valueFor("quote", "MAKE SOMETHING WONDERFUL").trim().slice(0, 80);
const accent = validateHex(valueFor("accent", "#e25563"), "accent");
const secondary = validateHex(valueFor("secondary", "#36b8c8"), "secondary");
const highlight = validateHex(valueFor("highlight", "#f3c96a"), "highlight");

const custom = {
  schemaVersion: 1,
  id: `custom-${Date.now()}`,
  name: name || "我的 TRAE 主题",
  visualStyle: "arcade-modern",
  brandSubtitle: "TRAE WORK · DREAM MODE",
  tagline: tagline || "敲下一个任务，让灵感开始流动。",
  statusText: "DREAM SKIN · READY",
  quote: quote || "MAKE SOMETHING WONDERFUL",
  image,
  colors: {
    background: "#dff5ff",
    panel: "#fffef6",
    panelAlt: "#fff6d7",
    accent,
    accentAlt: accent,
    secondary,
    highlight,
    text: "#183153",
    muted: "#56708f",
    line: hexToRgba(accent, 0.28),
  },
};

await atomicWrite(themePath, `${JSON.stringify(custom, null, 2)}\n`);
console.log(`Saved custom theme “${custom.name}”.`);
