import { cp, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
const assets = path.join(root, 'app/assets/branding');
await mkdir(assets, { recursive: true });
// Copy the current brand artwork verbatim into the Flutter bundle.
await cp(path.join(root, 'tap2work.png'), path.join(assets, 'tap2work.png'));
