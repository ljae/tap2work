import { createHmac, timingSafeEqual } from 'node:crypto';
import { cleanupDeletedWorkspaceMedia } from './manual_media_cleanup.mjs';

// Cron-only endpoint. The dedicated secret cannot authorize any other API, and
// authenticated users / anon keys cannot choose a workspace or object prefix.
export function createMediaCleanupHandler({ url, serviceKey, cleanupSecret, fetcher = fetch, cleanup = cleanupDeletedWorkspaceMedia, clock = Date.now }) {
  const configured = Boolean(url && serviceKey && typeof cleanupSecret === 'string' && /^[A-Za-z0-9_-]{43,256}$/.test(cleanupSecret));
  const headers = { apikey: serviceKey, ...(serviceKey?.startsWith('eyJ') ? { Authorization: `Bearer ${serviceKey}` } : {}) };
  return async request => {
    const reply = (status, body) => Response.json(body, { status, headers: { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' } });
    if (request.method !== 'POST') return reply(405, { error: 'POST required' });
    if (!configured) return reply(503, { error: 'Cleanup is not configured' });
    // pg_net may expose queued request headers to database roles. Transmit a
    // short-lived MAC, never the long-lived Vault secret itself.
    const match = /^Bearer ([0-9]{10,12})\.([a-f0-9]{64})$/.exec(request.headers.get('authorization') ?? '');
    if (!match) return reply(401, { error: 'Cleanup authentication required' });
    const timestamp = Number(match[1]), age = Math.floor(clock() / 1000) - timestamp;
    if (age < -30 || age > 300) return reply(401, { error: 'Cleanup authentication required' });
    const expected = new TextEncoder().encode(createHmac('sha256', cleanupSecret).update(`tap2work-manual-media-cleanup:${match[1]}`).digest('hex'));
    const actual = new TextEncoder().encode(match[2]);
    if (!timingSafeEqual(actual, expected)) return reply(401, { error: 'Cleanup authentication required' });
    if (request.headers.has('origin') || new URL(request.url).search) return reply(400, { error: 'Cleanup does not accept browser or query parameters' });
    if (request.headers.get('content-type')?.split(';')[0].trim() !== 'application/json') return reply(415, { error: 'JSON required' });
    // Stream-bound the request before decoding; the only supported body is {}.
    const reader = request.body?.getReader();
    const chunks = [];
    let size = 0;
    try {
      if (reader) for (;;) {
        const { value, done } = await reader.read();
        if (done) break;
        size += value.length;
        if (size > 1024) { await reader.cancel(); return reply(413, { error: 'Cleanup request too large' }); }
        chunks.push(value);
      }
    } catch { return reply(400, { error: 'Invalid cleanup request' }); }
    finally { reader?.releaseLock(); }
    try {
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
      const input = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
      if (!input || Array.isArray(input) || typeof input !== 'object' || Object.keys(input).length) return reply(400, { error: 'Cleanup request must be an empty object' });
    } catch { return reply(400, { error: 'Invalid cleanup request' }); }
    try {
      // Leave room inside the Edge wall-clock limit and pg_net's HTTP timeout.
      const result = await cleanup({ url, headers, fetcher, deadline: Date.now() + 45000 });
      return reply(200, result);
    } catch { return reply(503, { error: 'Cleanup failed; durable jobs remain queued' }); }
  };
}
