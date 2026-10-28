// Generate iddiff.js from iddiff.ts: node iddiff-build.mjs
//
// Node's own type stripping replaces type syntax with spaces so that
// positions are preserved. Those runs of spaces are removed here, keeping a
// space at either end of a run when the source had one there, and lines that
// held nothing but types are dropped, so that the JavaScript reads like the
// source. Needs Node 22.13 or later.
import { stripTypeScriptTypes } from 'node:module';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const ts = readFileSync(join(here, 'iddiff.ts'), 'utf8');
const stripped = stripTypeScriptTypes(ts, { mode: 'strip' });

let js = '';
for (let i = 0; i < stripped.length; ) {
  if (stripped[i] !== ' ') {
    js += stripped[i++];
    continue;
  }
  let end = i;
  let hole = false;
  while (end < stripped.length && stripped[end] === ' ') {
    if (ts[end] !== ' ') hole = true;
    end++;
  }
  if (!hole) js += stripped.slice(i, end);
  else js += (ts[i] === ' ' ? ' ' : '') + (end - 1 > i && ts[end - 1] === ' ' ? ' ' : '');
  i = end;
}

const tsLines = ts.split('\n');
const lines = js.split('\n').filter((line, n) => line.trim() !== '' || tsLines[n].trim() === '');
js = lines.join('\n').replace(/[ \t]+$/gm, '').replace(/\n{3,}/g, '\n\n');
// The header of the JavaScript file names it and the public home of the source.
js = js
  .replace(/^\/\/ iddiff\.ts: /, '// iddiff.js: ')
  .replace('in TypeScript, for use in the browser.', 'in JavaScript, for use in the browser.')
  .replace(
    /\/\/ Exports one function[\s\S]*?LICENSE\.iddiff\.\n/,
    `// Exports one function, iddiff(), and has no dependencies. This file is
// generated from a TypeScript source, iddiff.ts, published next to the
// draft at https://jaime.win/ietf-draft-ard-initial-contact/iddiff.ts
// together with the script that generates this file. The license notices
// are in LICENSE.iddiff.
`,
  );
writeFileSync(join(here, 'iddiff.js'), js);
