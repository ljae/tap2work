import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { OperationsStore, actors } from '../developer/operations.mjs';

const root = fileURLToPath(new URL('..', import.meta.url));
const output = path.join(root, '_site');
const appBuild = path.join(root, 'app/build/review-web');
// Fail before replacing output if the separate PUBLIC_REVIEW Flutter build is missing.
await readFile(path.join(appBuild, 'index.html'));
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(appBuild, output, { recursive: true });
// Keep old /app/ links useful while serving Flutter directly from the domain root.
await mkdir(path.join(output, 'app'), { recursive: true });
await writeFile(path.join(output, 'app/index.html'), `<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=/"><title>tap2work</title><script>location.replace('/'+location.search+location.hash)</script><a href="/">tap2work 열기</a></html>`);
await writeFile(path.join(output, '.nojekyll'), '');
await writeFile(path.join(output, 'CNAME'), 'tap2.work\n');
// Always generate from code in a fresh temporary directory, never from .local/.
const temporary = await mkdtemp(path.join(tmpdir(), 'tap2work-public-seed-'));
try {
  const store = new OperationsStore(path.join(temporary, 'sample.json'), () => new Date('2026-09-19T09:00:00Z'));
  const dataRoot = path.join(output, 'review-data');
  await mkdir(dataRoot, { recursive: true });
  for (const actor of actors) {
    const sample = await store.snapshot(actor.id);
    await writeFile(path.join(dataRoot, `${actor.id}.json`), JSON.stringify(sample));
  }
} finally {
  await rm(temporary, { recursive: true, force: true });
}
console.log('Public Flutter app built at _site/ root with fresh sample data.');
