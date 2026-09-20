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
await cp(path.join(root, 'site'), output, { recursive: true });
await cp(appBuild, path.join(output, 'app'), { recursive: true });
// Relative base serves the same artifact at /tap2work/app/ and /app/.
const appIndex = path.join(output, 'app/index.html');
await writeFile(appIndex, (await readFile(appIndex, 'utf8')).replace('<base href="/app/">', '<base href="./">'));
await mkdir(path.join(output, 'fonts'), { recursive: true });
await cp(path.join(root, 'app/assets/fonts'), path.join(output, 'fonts'), { recursive: true });
await cp(path.join(root, 'icon.svg'), path.join(output, 'icon.svg'));
await cp(path.join(root, 'tap2work.png'), path.join(output, 'tap2work.png'));
await cp(path.join(root, 'docs/project-state.json'), path.join(output, 'project-state.json'));
await mkdir(path.join(output, 'docs'), { recursive: true });
await cp(path.join(root, 'docs/CEO-REVIEW.md'), path.join(output, 'docs/CEO-REVIEW.md'));
await cp(path.join(root, 'docs/wiki'), path.join(output, 'docs/wiki'), { recursive: true });
await writeFile(path.join(output, '.nojekyll'), '');
// Always generate from code in a fresh temporary directory, never from .local/.
const temporary = await mkdtemp(path.join(tmpdir(), 'tap2work-public-seed-'));
try {
  const store = new OperationsStore(path.join(temporary, 'sample.json'), () => new Date('2026-09-19T09:00:00Z'));
  const dataRoot = path.join(output, 'app/review-data');
  await mkdir(dataRoot, { recursive: true });
  for (const actor of actors) {
    const sample = await store.snapshot(actor.id);
    await writeFile(path.join(dataRoot, `${actor.id}.json`), JSON.stringify(sample));
  }
} finally {
  await rm(temporary, { recursive: true, force: true });
}
console.log('Public review site built in _site/ with fresh sample data.');
