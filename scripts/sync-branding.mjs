import { cp, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
const assets = path.join(root, 'app/assets/branding');
await mkdir(assets, { recursive: true });
// Copy the user-selected artwork verbatim; do not crop or redraw it.
await cp(path.join(root, 'tap2work.png'), path.join(assets, 'tap2work.png'));
