import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const frontendRoot = path.resolve(__dirname, '..');
const publicRoot = path.join(frontendRoot, 'public');
const schemasRoot = path.join(frontendRoot, 'schemas', 'runtime');

function readJson(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

function fileExists(p) {
  try {
    fs.accessSync(p, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

function fail(msg) {
  console.error(`[runtime-validate] ERROR: ${msg}`);
  process.exitCode = 1;
}

function ok(msg) {
  console.log(`[runtime-validate] OK: ${msg}`);
}

function resolvePublicHref(href) {
  if (typeof href !== 'string' || !href.startsWith('/')) return null;
  return path.join(publicRoot, href.slice(1).split('/').join(path.sep));
}

function loadSchema(name) {
  const p = path.join(schemasRoot, name);
  if (!fileExists(p)) {
    fail(`Missing schema file: ${p}`);
    return null;
  }
  return readJson(p);
}

const ajv = new Ajv({ allErrors: true, strict: true, allowUnionTypes: true });

const schemas = {
  pagesManifest: loadSchema('pages.manifest.schema.json'),
  pageSpec: loadSchema('page.spec.schema.json'),
  themePacksManifest: loadSchema('theme-packs.manifest.schema.json'),
  themePack: loadSchema('theme-pack.schema.json'),
  assetsManifest: loadSchema('assets.manifest.schema.json')
};

function validateWith(schema, data, label) {
  const validate = ajv.compile(schema);
  const okv = validate(data);
  if (!okv) {
    fail(`${label} failed schema validation`);
    for (const e of validate.errors || []) {
      console.error(`  - ${e.instancePath || '(root)'} ${e.message}`);
    }
  } else {
    ok(`${label} schema valid`);
  }
}

// --- Pages ---
const pagesManifestPath = path.join(publicRoot, 'pages', 'pages.manifest.json');
if (!fileExists(pagesManifestPath)) {
  fail(`Missing: ${pagesManifestPath}`);
} else {
  const pagesManifest = readJson(pagesManifestPath);
  validateWith(schemas.pagesManifest, pagesManifest, 'pages/pages.manifest.json');

  const ids = new Set();
  const routes = new Set();

  for (const p of pagesManifest.pages || []) {
    if (ids.has(p.id)) fail(`Duplicate page id: ${p.id}`);
    ids.add(p.id);

    if (routes.has(p.route)) fail(`Duplicate route: ${p.route}`);
    routes.add(p.route);

    const specPath = resolvePublicHref(p.spec);
    if (!specPath) {
      fail(`Invalid spec href for page '${p.id}': ${p.spec}`);
      continue;
    }
    if (!fileExists(specPath)) {
      fail(`Missing page spec for '${p.id}': ${specPath}`);
      continue;
    }

    const pageSpec = readJson(specPath);
    validateWith(schemas.pageSpec, pageSpec, path.relative(publicRoot, specPath));

    if (pageSpec.id !== p.id) {
      fail(`PageSpec id mismatch: manifest '${p.id}' vs spec '${pageSpec.id}' (${specPath})`);
    }
  }
}

// --- Themes / Assets ---
const themePacksManifestPath = path.join(publicRoot, 'theme-packs.manifest.json');
const assetsManifestPath = path.join(publicRoot, 'assets.manifest.json');

let themePacksManifest = null;
let assetsManifest = null;

if (!fileExists(themePacksManifestPath)) fail(`Missing: ${themePacksManifestPath}`);
else {
  themePacksManifest = readJson(themePacksManifestPath);
  validateWith(schemas.themePacksManifest, themePacksManifest, 'theme-packs.manifest.json');
}

if (!fileExists(assetsManifestPath)) fail(`Missing: ${assetsManifestPath}`);
else {
  assetsManifest = readJson(assetsManifestPath);
  validateWith(schemas.assetsManifest, assetsManifest, 'assets.manifest.json');
}

const images = (assetsManifest && assetsManifest.images) ? assetsManifest.images : {};

for (const [id, href] of Object.entries(images)) {
  const assetPath = resolvePublicHref(href);
  if (!assetPath) {
    fail(`assets.manifest.json image path must be absolute (start with '/'): ${id} -> ${href}`);
    continue;
  }
  if (!fileExists(assetPath)) {
    console.warn(`[runtime-validate] WARN: asset missing on disk: ${id} -> ${assetPath}`);
  }
}

if (themePacksManifest && themePacksManifest.packs) {
  for (const [packId, packHref] of Object.entries(themePacksManifest.packs)) {
    const packPath = resolvePublicHref(packHref);
    if (!packPath) {
      fail(`Invalid theme pack href: ${packId} -> ${packHref}`);
      continue;
    }
    if (!fileExists(packPath)) {
      fail(`Missing theme pack file: ${packId} -> ${packPath}`);
      continue;
    }
    const pack = readJson(packPath);
    validateWith(schemas.themePack, pack, path.relative(publicRoot, packPath));
    if (pack.id !== packId) {
      fail(`Theme pack id mismatch: manifest '${packId}' vs pack '${pack.id}' (${packPath})`);
    }
    const heroBgId = pack.assets && pack.assets.heroBgId;
    if (heroBgId && !Object.prototype.hasOwnProperty.call(images, heroBgId)) {
      fail(`Theme pack '${packId}' references missing assets.images id: ${heroBgId}`);
    }
  }
}

if (process.exitCode) {
  console.error('[runtime-validate] FAILED');
  process.exit(process.exitCode);
} else {
  console.log('[runtime-validate] PASSED');
}
