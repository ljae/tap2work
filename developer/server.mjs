import http from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomBytes } from 'node:crypto';
import { ProjectStore, StoreError } from './store.mjs';
import { OperationsStore } from './operations.mjs';

const directory = fileURLToPath(new URL('.', import.meta.url));
const root = path.resolve(directory, '..');
const mime = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png', '.wasm': 'application/wasm', '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.bin': 'application/octet-stream' };

function json(res, status, body) { res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(body)); }
async function body(req, limit = 65536) {
  if (!req.headers['content-type']?.startsWith('application/json')) throw new StoreError('JSON 형식으로 보내 주세요.', 415);
  const chunks = []; let length = 0;
  for await (const chunk of req) {
    length += chunk.length;
    if (length > limit) throw new StoreError('한 번에 저장할 수 있는 크기를 초과했어요.', 413);
    chunks.push(chunk);
  }
  let parsed;
  try { parsed = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { throw new StoreError('JSON 내용을 읽지 못했어요.'); }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw new StoreError('올바른 객체 형식이 필요해요.');
  return parsed;
}
// Shared demo mode: `DEMO_PUBLIC_ORIGIN` lists browser origins (e.g. http://tap2.work) allowed to call
// the operations demo API through a tunnel. Only /api/operations is reachable from non-local hosts;
// the console pages and the project decision APIs stay loopback-only. Demo actors remain impersonable.
export const publicOriginsFromEnv = value => (value || '').split(',').map(item => item.trim().replace(/\/$/, '')).filter(Boolean);
export function createConsoleServer({ stateFile = path.join(root, 'docs/project-state.json'), appRoot = path.join(root, 'app/build/web'), operationsFile = path.join(root, '.local/operations-demo.json'), operationsClock, publicOrigins = publicOriginsFromEnv(process.env.DEMO_PUBLIC_ORIGIN) } = {}) {
  const store = new ProjectStore(stateFile);
  const operations = new OperationsStore(operationsFile, operationsClock);
  const token = randomBytes(32).toString('hex');
  return http.createServer(async (req, res) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    try {
      const host = req.headers.host || '';
      const local = /^(localhost|127\.0\.0\.1)(:\d+)?$/.test(host);
      const url = new URL(req.url, `http://${host}`);
      const route = decodeURIComponent(url.pathname);
      const origin = req.headers.origin;
      const sharedOrigin = route === '/api/operations' && origin && publicOrigins.includes(origin);
      if (sharedOrigin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Vary', 'Origin');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'content-type, x-demo-actor, x-demo-token');
        res.setHeader('Access-Control-Max-Age', '600');
        if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
      }
      if (!local && !(route === '/api/operations' && publicOrigins.length)) throw new StoreError('로컬 주소로 접속해 주세요.', 403);
      if (route.startsWith('/api/')) {
        if (route === '/api/operations' && req.method === 'GET') {
          return json(res, 200, { ...await operations.snapshot(req.headers['x-demo-actor'] || 'owner'), demoToken: token });
        }
        if (route === '/api/operations' && req.method === 'POST') {
          if ((origin && origin !== `http://${host}` && !sharedOrigin) || req.headers['x-demo-token'] !== token) throw new StoreError('매장 화면을 새로고침해 주세요.', 403);
          return json(res, 200, { ...await operations.mutate(req.headers['x-demo-actor'], await body(req, 2 * 1024 * 1024)), demoToken: token });
        }
        if (req.method === 'GET' && route === '/api/session') return json(res, 200, { token });
        if (req.method === 'GET' && route === '/api/project') return json(res, 200, await store.read());
        if (req.method === 'GET' && route === '/api/preview') {
          const built = await stat(path.join(appRoot, 'index.html')).catch(() => null);
          return json(res, 200, { ready: Boolean(built), builtAt: built?.mtime.toISOString() || null });
        }
        if (!['POST', 'PATCH'].includes(req.method)) throw new StoreError('지원하지 않는 요청입니다.', 405);
        if (req.headers.origin !== `http://${host}` || req.headers['x-tab2work-token'] !== token) throw new StoreError('개발자 화면에서 다시 시도해 주세요.', 403);
        const input = await body(req);
        const match = route.match(/^\/api\/decisions\/(D-\d+)$/);
        if (req.method === 'PATCH' && match) return json(res, 200, await store.updateDecision(match[1], input));
        if (req.method === 'POST' && route === '/api/decisions') return json(res, 201, await store.addDecision(input));
        if (req.method === 'POST' && route === '/api/history') return json(res, 201, await store.addHistory(input));
        throw new StoreError('요청한 기능을 찾지 못했습니다.', 404);
      }
      if (!['GET', 'HEAD'].includes(req.method)) throw new StoreError('지원하지 않는 요청입니다.', 405);
      if (route === '/app') { res.writeHead(302, { Location: '/app/' }); res.end(); return; }
      let filename;
      if (route.startsWith('/app/')) {
        const relative = route.slice(5) || 'index.html';
        filename = path.resolve(appRoot, relative);
        if (!filename.startsWith(path.resolve(appRoot) + path.sep)) throw new StoreError('잘못된 경로입니다.', 400);
      } else if (route === '/tap2work.png') {
        filename = path.join(root, 'tap2work.png');
      } else if (route.startsWith('/reference/')) {
        const documents = { 'decisions': 'docs/DECISIONS.md', 'product': 'PRODUCT.md', 'research': 'RESEARCH.md', 'readme': 'README.md', 'checklists': 'docs/wiki/CHECKLISTS.md' };
        const document = documents[route.slice(11)];
        if (!document) throw new StoreError('문서를 찾지 못했습니다.', 404);
        const text = await readFile(path.join(root, document), 'utf8');
        res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-cache' }); res.end(req.method === 'HEAD' ? '' : text); return;
      } else {
        const assets = { '/': 'index.html', '/dashboard.js': 'dashboard.js', '/styles.css': 'styles.css' };
        if (!assets[route]) throw new StoreError('페이지를 찾지 못했습니다.', 404);
        filename = path.join(directory, assets[route]);
      }
      const content = await readFile(filename);
      res.writeHead(200, { 'Content-Type': mime[path.extname(filename)] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
      res.end(req.method === 'HEAD' ? '' : content);
    } catch (error) {
      if (error.code === 'ENOENT') return json(res, 404, { error: '파일이 없습니다. Flutter 미리보기는 npm run build:app 실행 후 사용할 수 있어요.' });
      json(res, error.status || 500, { error: error instanceof StoreError ? error.message : '처리하지 못했어요. 파일은 유지되며 서버 로그를 확인해 주세요.' });
      if (!(error instanceof StoreError)) console.error(error);
    }
  });
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.DEV_CONSOLE_PORT || 3100);
  const server = createConsoleServer();
  server.on('error', error => { console.error(`개발자 웹을 열지 못했습니다: ${error.message}`); process.exitCode = 1; });
  const shared = publicOriginsFromEnv(process.env.DEMO_PUBLIC_ORIGIN);
  server.listen(port, '127.0.0.1', () => console.log(`tap2work 개발자 웹: http://localhost:${port}\n기준 파일: docs/project-state.json\nFlutter 미리보기: http://localhost:${port}/app/${shared.length ? `\n공유 데모 API 허용 출처: ${shared.join(', ')} · 터널을 열고 공개 앱에 ?api=<터널 주소>를 붙여 접속하세요` : ''}`));
}
