import { createMediaCleanupHandler } from '../../../developer/manual_media_cleanup_backend.mjs';

Deno.serve(createMediaCleanupHandler({
  url: Deno.env.get('SUPABASE_URL'),
  serviceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
  cleanupSecret: Deno.env.get('TAP2WORK_MEDIA_CLEANUP_SECRET'),
}));
