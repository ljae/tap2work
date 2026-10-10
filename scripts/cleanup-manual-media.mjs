// Deploy/schedule this service-only retry alongside the media migration before
// enabling uploads. It touches only durable tombstones of deleted workspaces;
// attached/historical/orphan photos of existing workspaces are never collected.
import { cleanupDeletedWorkspaceMedia } from '../developer/manual_media_cleanup.mjs';
const url = process.env.SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_SECRET_KEY;
if (!url || !serviceKey) {
  console.error('Set SUPABASE_URL and a server-only SUPABASE_SERVICE_ROLE_KEY or SUPABASE_SECRET_KEY for the private media cleanup worker.');
  process.exitCode = 1;
} else {
  try {
    const result = await cleanupDeletedWorkspaceMedia({ url, headers: { apikey: serviceKey, ...(serviceKey.startsWith('eyJ') ? { Authorization: `Bearer ${serviceKey}` } : {}) } });
    console.log(JSON.stringify(result));
    if (result.pending) process.exitCode = 2;
  } catch {
    console.error('Private media cleanup did not finish; the durable queue must be retried.');
    process.exitCode = 1;
  }
}
