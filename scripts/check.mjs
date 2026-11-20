#!/usr/bin/env node
// Verificació de Pujobaixo: sintaxi + sistema de disseny.
//   node scripts/check.mjs                  → valida (el fa servir el hook pre-commit)
//   node scripts/check.mjs --fix            → a més, copia index.html a 404.html
//   node scripts/check.mjs --update-baseline → desa el deute actual com a nou límit
// Els tokens es llegeixen de l':root d'index.html (--pj-* i --lp-*): són la font de veritat.
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const BASELINE = join(ROOT, 'scripts', 'design-baseline.json');
const args = new Set(process.argv.slice(2));
const errors = [], notes = [];
const html = readFileSync(join(ROOT, 'index.html'), 'utf8');

// ── 1. 404.html ha de ser idèntic a index.html (GitHub Pages el serveix per a rutes profundes)
const f404 = join(ROOT, '404.html');
if (readFileSync(f404, 'utf8') !== html) {
  if (args.has('--fix')) { writeFileSync(f404, html); notes.push('404.html sincronitzat amb index.html'); }
  else errors.push('404.html no és idèntic a index.html → node scripts/check.mjs --fix');
}

// ── 2. CSS: comentaris i claus equilibrats (un /* sense tancar anul·la regles en silenci)
for (const m of html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)) {
  const css = m[1], line = html.slice(0, m.index).split('\n').length;
  const o = (css.match(/\/\*/g) || []).length, c = (css.match(/\*\//g) || []).length;
  if (o !== c) errors.push(`<style> (línia ${line}): ${o} "/*" i ${c} "*/" — hi ha un comentari sense tancar`);
  const noCom = css.replace(/\/\*[\s\S]*?\*\//g, '');
  const bo = (noCom.match(/\{/g) || []).length, bc = (noCom.match(/\}/g) || []).length;
  if (bo !== bc) errors.push(`<style> (línia ${line}): ${bo} "{" i ${bc} "}"`);
}

// ── 3. Plantilles: <sc-if>/<sc-for> equilibrats
for (const t of ['sc-if', 'sc-for']) {
  const o = (html.match(new RegExp(`<${t}[\\s>]`, 'g')) || []).length;
  const c = (html.match(new RegExp(`</${t}>`, 'g')) || []).length;
  if (o !== c) errors.push(`<${t}>: ${o} oberts i ${c} tancats`);
}

// ── 4. JS inline: node --check
const js = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map((m) => m[1]).join('\n;\n');
const tmp = join(mkdtempSync(join(tmpdir(), 'pj-')), 'inline.js');
writeFileSync(tmp, js);
const r = spawnSync(process.execPath, ['--check', tmp], { encoding: 'utf8' });
if (r.status !== 0) errors.push('JS inline no passa node --check:\n' + (r.stderr || '').split('\n').slice(0, 6).join('\n'));

// ── 5. Sistema de disseny: deute amb trinquet (no pot créixer)
const px = (v) => parseFloat(v);
const tokens = (re) => new Set([...html.matchAll(re)].map((m) => m[1]));
const norm = (h) => { h = h.toUpperCase(); return h.length === 4 ? '#' + [...h.slice(1)].map((c) => c + c).join('') : h; };
const palette = new Set([...tokens(/--(?:pj|lp)-[a-z0-9-]+:\s*(#[0-9a-fA-F]{3,6})\b/g)].map(norm));
const radii = new Set([...tokens(/--(?:pj|lp)-radius-[a-z-]+:\s*([\d.]+)px/g)].map(px));
const fonts = new Set([...tokens(/--pj-fs-[a-z0-9-]+:\s*([\d.]+)px/g)].map(px));
const isGrid = (n) => n === 0 || n === 1 || n === 2 || n === 4 || n % 8 === 0; // regla del 8 (+4; 1-2px per a ajustos òptics)

// no compten com a ús: el bloc :root (definicions) ni les il·lustracions de la landing (.lp-iso), que són art, no interfície
const body = html.replace(/:root\s*\{[\s\S]*?\}/g, '').replace(/<svg\b[^>]*\blp-iso\b[^>]*>[\s\S]*?<\/svg>/g, '');
const tally = (pairs) => pairs.reduce((a, k) => ((a[k] = (a[k] || 0) + 1), a), {});
const offHex = tally([...body.matchAll(/#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b/g)].map((m) => norm(m[0])).filter((h) => !palette.has(h)));
// la landing té el seu sistema tipogràfic (--lp-*, mides editorials): l'escala --pj-fs-* és només de l'app
const appBody = body.split('\n').filter((l) => !/\blp-/.test(l)).join('\n');
const offFont = tally([...appBody.matchAll(/font-size:\s*([\d.]+)px/g)].map((m) => px(m[1])).filter((v) => !fonts.has(v)).map((v) => v + 'px'));
const offRadius = tally([...body.matchAll(/border-radius:\s*([\d.]+)px/g)].map((m) => px(m[1])).filter((v) => !radii.has(v)).map((v) => v + 'px'));
const offSpace = tally([...body.matchAll(/(?:padding|margin|gap)(?:-[a-z]+)?:\s*([^;"}]+)/g)]
  .flatMap((m) => [...m[1].matchAll(/(-?[\d.]+)px/g)].map((x) => Math.abs(px(x[1]))))
  .filter((v) => !isGrid(v)).map((v) => v + 'px'));

const current = { colorsFueraDePaleta: offHex, fontSizesFueraDeEscala: offFont, radiosFueraDeEscala: offRadius, espaciadoFueraDeRejilla: offSpace };
const total = (o) => Object.values(o).reduce((a, b) => a + b, 0);

if (args.has('--update-baseline')) {
  writeFileSync(BASELINE, JSON.stringify(current, null, 2) + '\n');
  notes.push('design-baseline.json actualitzat');
} else {
  let base = {};
  try { base = JSON.parse(readFileSync(BASELINE, 'utf8')); } catch { errors.push('Falta scripts/design-baseline.json → node scripts/check.mjs --update-baseline'); }
  for (const [k, cur] of Object.entries(current)) {
    const b = base[k] || {};
    const nous = Object.entries(cur).filter(([v, n]) => n > (b[v] || 0)).map(([v, n]) => `${v} (+${n - (b[v] || 0)})`);
    if (nous.length) errors.push(`${k}: valors nous fora del sistema → ${nous.join(', ')}. Fes servir un token (--pj-*) o, si és una decisió, afegeix-lo al sistema i documenta-ho.`);
    else if (total(cur) < total(b)) notes.push(`${k}: ${total(b)} → ${total(cur)}. Bé! Executa --update-baseline per fixar la millora.`);
  }
  notes.push('Deute de disseny: ' + Object.entries(current).map(([k, v]) => `${k} ${total(v)}`).join(' · '));
}

for (const n of notes) console.log('· ' + n);
if (errors.length) { console.error('\n✗ check fallat:\n' + errors.map((e) => '  - ' + e).join('\n')); process.exit(1); }
console.log('✓ check correcte');
