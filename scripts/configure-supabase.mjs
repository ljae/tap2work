// Run with node --env-file=.env. Never print tokens or database connection strings.
import { readFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
const { SUPABASE_ACCESS_TOKEN: token, SUPABASE_PROJECT_REF: ref } = process.env;
if (!token || !ref) throw new Error('Set SUPABASE_ACCESS_TOKEN and SUPABASE_PROJECT_REF in .env');
const query = await readFile(new URL('../supabase/migrations/20260924030000_workspace_backend.sql', import.meta.url), 'utf8');
const response = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
  method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ query }),
});
if (!response.ok) { console.error('Migration failed, HTTP', response.status); process.exit(1); }
console.log('Workspace migration applied.');
const result = spawnSync('supabase', ['functions', 'deploy', 'operations', '--project-ref', ref, '--use-api'], { env: process.env, stdio: 'inherit' });
process.exitCode = result.status ?? 1;
