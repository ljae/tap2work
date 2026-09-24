import { createCloudHandler } from '../../../developer/supabase_backend.mjs';

Deno.serve(createCloudHandler({
  url: Deno.env.get('SUPABASE_URL'),
  serviceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
  origins: (Deno.env.get('TAP2WORK_ORIGINS') ?? 'https://tap2.work,https://www.tap2.work,http://localhost:3180,http://127.0.0.1:3180').split(','),
}));
