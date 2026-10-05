import { createPublicLoginHandler } from '../../../developer/public_login.mjs';
Deno.serve(createPublicLoginHandler({
  url: Deno.env.get('SUPABASE_URL'),
  serviceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
  email: Deno.env.get('TAP2WORK_PUBLIC_LOGIN_EMAIL'),
  // Personal Apple/Google accounts replace the temporary shared entry.
  enabled: false,
}));
