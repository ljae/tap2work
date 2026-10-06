// Deploy only the application API. Schema migrations are a separate operation.
// Keep the access token in the environment; never put it in arguments or logs.
import { spawnSync } from 'node:child_process';

const ref = process.env.SUPABASE_PROJECT_REF;
if (!ref || !/^[a-z0-9]+$/.test(ref) || !process.env.SUPABASE_ACCESS_TOKEN) {
  console.error('Set SUPABASE_PROJECT_REF and SUPABASE_ACCESS_TOKEN in .env before deployment.');
  process.exit(1);
}

const result = spawnSync('supabase', [
  'functions', 'deploy', 'operations', '--project-ref', ref, '--use-api',
], { env: process.env, stdio: 'inherit' });
if (result.error) console.error('Could not start Supabase CLI:', result.error.code);
process.exitCode = result.status ?? 1;
