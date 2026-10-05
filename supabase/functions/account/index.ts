import {createAccountHandler} from '../../../developer/account_backend.mjs';

Deno.serve(createAccountHandler({
  url:Deno.env.get('SUPABASE_URL'),
  serviceKey:Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
  apple:{
    bundleId:'com.tap2work.tap2work',
    serviceId:Deno.env.get('APPLE_SERVICE_ID'),
    teamId:Deno.env.get('APPLE_TEAM_ID'),
    keyId:Deno.env.get('APPLE_KEY_ID'),
    privateKey:Deno.env.get('APPLE_PRIVATE_KEY'),
  },
}));
