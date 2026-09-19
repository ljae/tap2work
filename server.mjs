import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('.', import.meta.url));
const port = Number(process.env.PORT || 3000);
const files = new Set(['index.html', 'styles.css', 'app.js', 'icon.svg', 'manifest.webmanifest', 'sw.js']);
const mime = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.svg': 'image/svg+xml', '.webmanifest': 'application/manifest+json' };
http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    const name = url.pathname === '/' ? 'index.html' : decodeURIComponent(url.pathname).slice(1);
    if (!files.has(name)) { res.writeHead(404); res.end('Not found'); return; }
    const body = await readFile(path.join(root, name));
    res.writeHead(200, { 'Content-Type': `${mime[path.extname(name)] || 'application/octet-stream'}; charset=utf-8`, 'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff' });
    res.end(body);
  } catch { res.writeHead(500); res.end('Unable to load this page'); }
}).listen(port, '0.0.0.0', () => console.log(`tap2work is ready at http://localhost:${port}`));
