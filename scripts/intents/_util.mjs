#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

export function arg(name, def = undefined) {
  const i = process.argv.indexOf(name);
  if (i >= 0 && process.argv[i + 1]) return process.argv[i + 1];
  return def;
}

export function flag(name) {
  return process.argv.includes(name);
}

export function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

export function writeJson(filePath, obj) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(obj, null, 2));
}

export function nowId(prefix = '') {
  const t = new Date().toISOString().replace(/[:.]/g, '-');
  return prefix ? `${prefix}-${t}` : t;
}

export function splitCsv(val) {
  if (!val) return [];
  return val.split(',').map(s => s.trim()).filter(Boolean);
}

